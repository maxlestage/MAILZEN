"""Trains the three on-device models of MailZen and writes them, compressed to 8 bits, into
MailZenKit, with the golden tests that check the Swift code computes the same thing, and
the model card with the evaluation.

    python3 train.py --data <folder of fetch.sh>

Models: `scam` (is it a scam, logistic), `category` (which family of scam), `intent` (what is
asked to ZenAI). All use the hashed features of features.py."""
import argparse, csv, json, math, random, struct, sys, hashlib
from collections import Counter, defaultdict
from pathlib import Path

import numpy as np
from scipy.sparse import csr_matrix
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score

import corpus, intents
from features import DIM, features

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "apps/ios/MailZenKit/Sources/MailZenKit/Resources"
TESTS = ROOT / "apps/ios/MailZenKit/Tests/MailZenKitTests/ModelGoldenTests.swift"
CARD = ROOT / "ml/MODEL_CARD.md"


def matrix(texts):
    rows, cols, vals = [], [], []
    for i, t in enumerate(texts):
        f = features(t)
        v = 1.0 / math.sqrt(len(f)) if f else 0.0
        rows += [i] * len(f); cols += f; vals += [v] * len(f)
    return csr_matrix((vals, (rows, cols)), shape=(len(texts), DIM), dtype=np.float32)


def load_real(data):
    csv.field_size_limit(10**9)
    out = []
    for r in csv.DictReader(open(data / "junk.csv", encoding="utf-8", errors="replace")):
        out.append((r["text"][:3000], int(r["is_spam"]), "junk"))
    for r in json.load(open(data / "texts.json")):
        out.append((r["text"][:3000], int(r["label"]), "phishing"))
    for line in open(data / "sms/SMSSpamCollection", encoding="utf-8"):
        label, text = line.rstrip("\n").split("\t", 1)
        out.append((text, 1 if label == "spam" else 0, "sms"))
    seen, unique = set(), []
    for t, y, s in out:
        h = hashlib.sha1(t.strip().lower().encode()).hexdigest()
        if h not in seen and t.strip():
            seen.add(h); unique.append((t, y, s))
    return unique


class Quantized:
    """A linear model with int8 weights, as stored in a .mzm file."""

    def __init__(self, classes, coef, intercept):
        self.classes = classes
        self.scale = float(np.abs(coef).max() / 127.0)
        self.q = np.clip(np.round(coef / self.scale), -127, 127).astype(np.int8)
        self.bias = intercept.astype(np.float32)

    def scores(self, text):
        f = features(text)
        if not f:
            s = self.bias.astype(np.float64)
        else:
            s = self.bias.astype(np.float64) + self.scale * self.q[:, f].astype(np.float64).sum(axis=1) / math.sqrt(len(f))
        if len(self.classes) == 1:
            return np.array([1.0 / (1.0 + math.exp(-s[0]))])
        e = np.exp(s - s.max())
        return e / e.sum()

    def write(self, path):
        keep = np.where(np.any(self.q != 0, axis=0))[0]
        k = len(self.classes)
        names = "\n".join(self.classes).encode("utf-8")
        with open(path, "wb") as f:
            f.write(b"MZM1")
            f.write(struct.pack("<IHI", DIM, k, len(names)))
            f.write(names)
            f.write(struct.pack("<f", self.scale))
            f.write(struct.pack("<" + "f" * k, *self.bias.tolist()))
            f.write(struct.pack("<I", len(keep)))
            for j in keep:
                f.write(struct.pack("<I", int(j)))
                f.write(self.q[:, j].tobytes())
        return len(keep), path.stat().st_size


def binary_metrics(y, p, threshold=0.5):
    y = np.array(y); p = np.array(p); pred = p >= threshold
    tp = int(((pred == 1) & (y == 1)).sum()); fp = int(((pred == 1) & (y == 0)).sum())
    fn = int(((pred == 0) & (y == 1)).sum()); tn = int(((pred == 0) & (y == 0)).sum())
    prec = tp / max(tp + fp, 1); rec = tp / max(tp + fn, 1)
    m = {"n": len(y), "accuracy": (tp + tn) / max(len(y), 1), "precision": prec, "recall": rec,
         "f1": 2 * prec * rec / max(prec + rec, 1e-9), "false_positive_rate": fp / max(fp + tn, 1)}
    if len(set(y.tolist())) == 2:
        m["roc_auc"] = roc_auc_score(y, p)
    return m


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", type=Path, required=True)
    args = ap.parse_args()
    rng = random.Random(42)
    OUT.mkdir(parents=True, exist_ok=True)

    # ----- Corpus -----
    real = load_real(args.data)
    rng.shuffle(real)
    cut = int(len(real) * 0.85)
    real_train, real_test = real[:cut], real[cut:]
    synth = corpus.generate()
    def held(tid):
        # Whole templates kept apart: one scam template in five, and one legitimate
        # template of half of the legitimate kinds, in each language.
        family, _, index = tid.split("/")
        i = int(index)
        if family.startswith("legit-"):
            return family[6:] in ("newsletter", "appointment", "work", "otp", "delivery_legit") and i == 1
        return i % 5 == 4
    synth_train = [r for r in synth if not held(r[0])]
    synth_test = [r for r in synth if held(r[0])]
    print(f"real {len(real)} ({Counter(y for _, y, _ in real)}), synthetic {len(synth)}: train {len(synth_train)}, test {len(synth_test)}")

    # ----- Scam model -----
    texts = [t for t, _, _ in real_train] + [r[4] for r in synth_train]
    labels = [y for _, y, _ in real_train] + [r[1] for r in synth_train]
    weights = [1.0] * len(real_train) + [4.0] * len(synth_train)
    X = matrix(texts)
    best = None
    vi = list(range(len(texts))); rng.shuffle(vi); val, tr = vi[: len(vi) // 8], vi[len(vi) // 8 :]
    for C in (2.0, 8.0, 32.0):
        m = LogisticRegression(C=C, solver="liblinear", max_iter=200)
        m.fit(X[tr], np.array(labels)[tr], sample_weight=np.array(weights)[tr])
        auc = roc_auc_score(np.array(labels)[val], m.predict_proba(X[val])[:, 1])
        print(f"  scam C={C}: validation AUC {auc:.4f}")
        if best is None or auc > best[0]:
            best = (auc, C)
    scam = LogisticRegression(C=best[1], solver="liblinear", max_iter=300)
    scam.fit(X, labels, sample_weight=weights)
    qscam = Quantized(["scam"], scam.coef_, scam.intercept_)

    def evaluate(model, rows):
        return [model.scores(t)[0] for t in rows]
    metrics = {"scam": {}}
    metrics["scam"]["real (English emails and SMS, held out)"] = binary_metrics([y for _, y, _ in real_test], evaluate(qscam, [t for t, _, _ in real_test]))
    for lang in ("fr", "en", "es"):
        rows = [r for r in synth_test if r[3] == lang]
        metrics["scam"][f"generated, unseen templates ({lang})"] = binary_metrics([r[1] for r in rows], evaluate(qscam, [r[4] for r in rows]))
    operating = {}
    operating["real (held out)"] = binary_metrics([y for _, y, _ in real_test], evaluate(qscam, [t for t, _, _ in real_test]), 0.9)
    for lang in ("fr", "en", "es"):
        rows = [r for r in synth_test if r[3] == lang]
        operating[f"generated ({lang})"] = binary_metrics([r[1] for r in rows], evaluate(qscam, [r[4] for r in rows]), 0.9)
    metrics["scam_operating"] = operating
    site = [s.text for s in []]
    print(json.dumps(metrics, indent=1))

    # ----- Category model -----
    cats = corpus.CATEGORIES
    ctrain = [r for r in synth_train if r[1] == 1]
    ctest = [r for r in synth_test if r[1] == 1]
    cm = LogisticRegression(C=32.0, max_iter=3000)
    cm.fit(matrix([r[4] for r in ctrain]), [cats.index(r[2]) for r in ctrain])
    qcat = Quantized(cats, cm.coef_, cm.intercept_)
    correct = sum(int(np.argmax(qcat.scores(r[4]))) == cats.index(r[2]) for r in ctest)
    per = defaultdict(lambda: [0, 0])
    for r in ctest:
        per[r[2]][1] += 1; per[r[2]][0] += int(np.argmax(qcat.scores(r[4]))) == cats.index(r[2])
    metrics["category"] = {"accuracy, unseen templates": correct / len(ctest), "n": len(ctest),
                           "per family": {k: v[0] / v[1] for k, v in sorted(per.items())}}

    # ----- Intent model -----
    names = list(intents.merged())
    irows = intents.generate()
    iheld = lambda tid: int(tid.rsplit("/", 1)[1]) % 4 == 3
    itrain = [r for r in irows if not iheld(r[0])]
    itest = [r for r in irows if iheld(r[0])]
    im = LogisticRegression(C=32.0, max_iter=3000)
    im.fit(matrix([r[3] for r in itrain]), [names.index(r[1]) for r in itrain])
    qint = Quantized(names, im.coef_, im.intercept_)
    icorrect = sum(int(np.argmax(qint.scores(r[3]))) == names.index(r[1]) for r in itest)
    metrics["intent"] = {"accuracy, unseen phrasings": icorrect / len(itest), "n": len(itest)}
    print(json.dumps({k: v for k, v in metrics.items() if k != "scam"}, indent=1))

    # ----- Export -----
    sizes = {}
    for name, model in (("scam", qscam), ("category", qcat), ("intent", qint)):
        sizes[name] = model.write(OUT / f"{name}.mzm")
    print("sizes", sizes)

    golden_texts = [
        "Colissimo : votre colis est en attente, frais de 1,99 € à régler : https://bit.ly/c0lis",
        "Rappel : votre rendez-vous chez le dentiste est le 12/3 à 14h30.",
        "Your Netflix account will be suspended within 24 hours. Confirm your payment: http://netfIix-secure.xyz/login",
        "Hi Emma, lunch on Saturday at noon?",
        "Su paquete está retenido en aduanas. Pague 2,99 € aquí: https://correos-envio.top/pago",
        "Hola Pablo, ¿puedes revisar la presentación antes del viernes?",
        "J'ai piraté votre ordinateur. Envoyez 900 € en Bitcoin sous 48 heures.",
        "ÉTÉ 2026 : Àçcéntués, chiffres 0123456789 et ponctuation… — fin.",
        "",
        "pourquoi ce mail est-il suspect ?",
        "I clicked the link, what now?",
        "¿Puedo recuperar mi dinero?",
    ]
    lines = ["// Generated by ml/train.py: the Swift models must compute what the Python ones compute.", "",
             "import Foundation", "import Testing", "@testable import MailZenKit", "",
             "@Suite struct ModelGoldenTests {", "    @Test func theModelsMatchTheTraining() throws {"]
    for t in golden_texts:
        lit = json.dumps(t, ensure_ascii=False)
        s = qscam.scores(t)[0]
        c = qcat.scores(t); i = qint.scores(t)
        lines.append(f"        try check({lit}, scam: {s:.6f}, category: \"{cats[int(np.argmax(c))]}\", categoryP: {c.max():.6f}, intent: \"{names[int(np.argmax(i))]}\", intentP: {i.max():.6f})")
    lines += ["    }", "",
              "    func check(_ text: String, scam: Double, category: String, categoryP: Double, intent: String, intentP: Double) throws {",
              "        let models = try #require(Models.shared)",
              "        #expect(abs(models.scamProbability(text) - scam) < 1e-4, \"scam: \\(text)\")",
              "        let c = models.category(text)",
              "        #expect(c.label == category && abs(c.probability - categoryP) < 1e-4, \"category: \\(text)\")",
              "        let i = models.intent(text)",
              "        #expect(i.label == intent && abs(i.probability - intentP) < 1e-4, \"intent: \\(text)\")",
              "    }", "}", ""]
    TESTS.write_text("\n".join(lines))

    # ----- Model card -----
    def table(m):
        rows = ["| Jeu d'évaluation | n | Exactitude | Précision | Rappel | F1 | Faux positifs | AUC |", "|---|---|---|---|---|---|---|---|"]
        for k, v in m.items():
            rows.append(f"| {k} | {v['n']} | {v['accuracy']:.3f} | {v['precision']:.3f} | {v['recall']:.3f} | {v['f1']:.3f} | {v['false_positive_rate']:.3f} | {v.get('roc_auc', float('nan')):.3f} |")
        return "\n".join(rows)
    card = f"""# Les modèles de MailZen

Trois modèles linéaires (régression logistique), entraînés par [`train.py`](train.py) et exécutés
**sur l'appareil**, sans serveur : rien de ce que vous analysez ne quitte l'iPhone.

| Modèle | Rôle | Classes | Poids gardés | Taille |
|---|---|---|---|---|
| `scam` | probabilité qu'un message soit une arnaque, un phishing ou un spam | 1 (logistique) | {sizes['scam'][0]} | {sizes['scam'][1] // 1024} Ko |
| `category` | famille d'arnaque | {len(cats)} | {sizes['category'][0]} | {sizes['category'][1] // 1024} Ko |
| `intent` | question posée à ZenAI | {len(names)} | {sizes['intent'][0]} | {sizes['intent'][1] // 1024} Ko |

## Caractéristiques

Mots, paires de mots et trigrammes de caractères des mots, hachés (FNV-1a, 2^18) : voir
[`features.py`](features.py), reproduit à l'identique en Swift et vérifié par des tests dorés.
Les poids sont compressés sur 8 bits ; les mesures ci-dessous sont celles des modèles compressés.

## Données

- **all-scam-spam** (Apache-2.0, FredZhang7) : emails de spam et légitimes, surtout en anglais ;
- **phishing-dataset** (Apache-2.0, ealvaradob), partie `texts` : emails et SMS de phishing ;
- **SMS Spam Collection** (CC BY 4.0, UCI) ;
- un **corpus généré** ([`corpus.py`](corpus.py)) en français, anglais et espagnol : {len(corpus.templates())} modèles
  de messages (10 familles d'arnaques et 10 sortes de messages légitimes qui leur ressemblent),
  remplis de marques, montants, délais et liens variés ; et [`intents.py`](intents.py) pour ZenAI.

Les données réelles sont presque toutes en anglais : en français et en espagnol, les modèles
reposent sur le corpus généré. Les évaluations du corpus généré portent sur des **modèles de
messages entiers jamais vus à l'entraînement**, mais elles restent plus faciles que la réalité.

## Évaluation

Seuil 0,5 sauf mention. Données réelles : {len(real)} messages après dédoublonnage, 15 % gardés pour le test.

### `scam`

{table(metrics['scam'])}

Au seuil de **0,9**, celui où l'app ajoute le signal « ressemble à des arnaques connues » :

{table(metrics['scam_operating'])}

### `category`

Exactitude sur des modèles de messages jamais vus : **{metrics['category']['accuracy, unseen templates']:.3f}** (n = {metrics['category']['n']}).

{chr(10).join(f"- {k} : {v:.2f}" for k, v in metrics['category']['per family'].items())}

### `intent`

Exactitude sur des formulations jamais vues : **{metrics['intent']['accuracy, unseen phrasings']:.3f}** (n = {metrics['intent']['n']}).

## Limites

- Un modèle statistique se trompe : il ne décide jamais seul. Le verdict de MailZen reste celui du
  moteur de règles ; le modèle ajoute un signal (« ressemble à des arnaques connues ») et la
  famille d'arnaque, que ZenAI explique avec son niveau de confiance.
- Il ne voit que le texte : ni la réputation des liens, ni le contenu des pièces jointes
  (c'est le rôle d'Attachment Guard et de Link Guard).
- Les arnaques évoluent : le modèle doit être réentraîné régulièrement avec de nouveaux exemples.
"""
    CARD.write_text(card)
    print("written", OUT, TESTS, CARD)


if __name__ == "__main__":
    main()
