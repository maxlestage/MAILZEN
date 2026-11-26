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

import corpus, intents, urls
from features import DIM, features
from url_features import url_features, normalize as url_normalize, split as url_split

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "apps/ios/MailZenKit/Sources/MailZenKit/Resources"
TESTS = ROOT / "apps/ios/MailZenKit/Tests/MailZenKitTests/ModelGoldenTests.swift"
CARD = ROOT / "ml/MODEL_CARD.md"


def matrix(texts, featurize=features):
    rows, cols, vals = [], [], []
    for i, t in enumerate(texts):
        f = featurize(t)
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

    def __init__(self, classes, coef, intercept, featurize=features):
        self.classes = classes
        self.featurize = featurize
        self.scale = float(np.abs(coef).max() / 127.0)
        self.q = np.clip(np.round(coef / self.scale), -127, 127).astype(np.int8)
        self.bias = intercept.astype(np.float32)

    def scores(self, text):
        f = self.featurize(text)
        if not f:
            s = self.bias.astype(np.float64)
        else:
            s = self.bias.astype(np.float64) + self.scale * self.q[:, f].astype(np.float64).sum(axis=1) / math.sqrt(len(f))
        if len(self.classes) == 1:
            return np.array([1.0 / (1.0 + math.exp(-s[0]))])
        e = np.exp(s - s.max())
        return e / e.sum()

    def matrix_scores(self, X):
        """The probabilities of a binary model for the rows of a feature matrix."""
        z = X @ (self.scale * self.q.astype(np.float64)).T + self.bias.astype(np.float64)
        return 1.0 / (1.0 + np.exp(-np.asarray(z)[:, 0]))

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


def write_anchors():
    """Reference messages shipped with the app: when the app learns from the user's
    corrections on the device (PersonalModel), it must keep answering the same on these."""
    rows = corpus.generate(seed=3, per_template=1)
    texts = [r[4] for r in rows]
    (OUT / "anchors.json").write_text(json.dumps(texts, ensure_ascii=False, separators=(",", ":")))
    return len(texts)


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
    ap.add_argument("--feedback", type=Path, action="append", default=[],
                    help="corrections exported by the app (Settings, Trained models): JSON lines {text, label, category?}")
    args = ap.parse_args()
    feedback = []
    for path in args.feedback:
        for line in open(path, encoding="utf-8"):
            if line.strip():
                r = json.loads(line)
                feedback.append((r["text"][:3000], int(r["label"]), r.get("category")))
    print(f"feedback: {len(feedback)} corrections")
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
    texts = [t for t, _, _ in real_train] + [r[4] for r in synth_train] + [t for t, _, _ in feedback]
    labels = [y for _, y, _ in real_train] + [r[1] for r in synth_train] + [y for _, y, _ in feedback]
    weights = [1.0] * len(real_train) + [4.0] * len(synth_train) + [8.0] * len(feedback)
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
    metrics["scam_danger"] = binary_metrics([y for _, y, _ in real_test], evaluate(qscam, [t for t, _, _ in real_test]), 0.98)
    for lang in ("fr", "en", "es"):
        rows = [r for r in synth_test if r[3] == lang]
        operating[f"generated ({lang})"] = binary_metrics([r[1] for r in rows], evaluate(qscam, [r[4] for r in rows]), 0.9)
    metrics["scam_operating"] = operating
    print(json.dumps(metrics, indent=1))

    # ----- Category model -----
    # Five folds over whole templates (a template and its translations are kept apart
    # together), then the model is trained on every template.
    cats = corpus.CATEGORIES
    crows = [r for r in synth if r[1] == 1]
    cX = matrix([r[4] for r in crows]); cy = np.array([cats.index(r[2]) for r in crows])
    cfold = np.array([int(r[0].split("/")[2]) % 5 for r in crows])
    per = defaultdict(list); accs = []
    for k in range(5):
        m = LogisticRegression(C=16.0, max_iter=3000).fit(cX[cfold != k], cy[cfold != k])
        p = m.predict(cX[cfold == k]); accs.append(float((p == cy[cfold == k]).mean()))
        for a, b in zip(cy[cfold == k], p):
            per[cats[a]].append(a == b)
    fb = [(t, c) for t, y, c in feedback if y == 1 and c in cats]
    cm = LogisticRegression(C=16.0, max_iter=3000)
    cm.fit(matrix([r[4] for r in crows] + [t for t, _ in fb]), list(cy) + [cats.index(c) for _, c in fb],
           sample_weight=[1.0] * len(crows) + [8.0] * len(fb))
    qcat = Quantized(cats, cm.coef_, cm.intercept_)
    metrics["category"] = {"accuracy, unseen templates": float(np.mean(accs)), "n": len(crows),
                           "templates": len({r[0] for r in crows}),
                           "per family": {k: float(np.mean(v)) for k, v in sorted(per.items())}}

    # ----- Intent model -----
    # Four folds over phrasings (a phrasing and its translations together).
    names = list(intents.merged())
    irows = intents.generate()
    iX = matrix([r[3] for r in irows]); iy = np.array([names.index(r[1]) for r in irows])
    ifold = np.array([int(r[0].rsplit("/", 1)[1]) % 4 for r in irows])
    # ZenAI takes a topic as understood when the model gives it 45 % or more and it is not
    # "other" (a question outside the known topics); otherwise it answers from every fact.
    other = names.index("other")
    iaccs, understood, right, caught = [], [], [], []
    for k in range(4):
        m = LogisticRegression(C=32.0, max_iter=3000).fit(iX[ifold != k], iy[ifold != k])
        P = m.predict_proba(iX[ifold == k]); pred = P.argmax(axis=1); truth = iy[ifold == k]
        iaccs.append(float((pred == truth).mean()))
        und = (P.max(axis=1) >= 0.45) & (pred != other)
        understood += list(und[truth != other]); right += list((pred == truth)[(truth != other) & und])
        caught += list(~und[truth == other])
    im = LogisticRegression(C=32.0, max_iter=3000).fit(iX, iy)
    qint = Quantized(names, im.coef_, im.intercept_)
    metrics["intent"] = {"accuracy, unseen phrasings": float(np.mean(iaccs)), "n": len(irows), "intents": len(names) - 1,
                         "understood": float(np.mean(understood)), "right when understood": float(np.mean(right)),
                         "other questions recognized": float(np.mean(caught))}
    print(json.dumps({k: v for k, v in metrics.items() if k != "scam"}, indent=1))

    # ----- Link model -----
    # The URLs of phishing-dataset, kept apart by registrable domain (one in seven
    # domains for the test), plus generated links like those of emails.
    def domain(u):
        labels = url_split(url_normalize(u))[0].split(".")
        return ".".join(labels[-2:])
    import zlib
    ureal = urls.load(args.data / "urls.json")
    utest_dom = lambda u: zlib.crc32(domain(u).encode()) % 100 < 15
    utrain = [r for r in ureal if not utest_dom(r[0])]; utest = [r for r in ureal if utest_dom(r[0])]
    usyn = urls.generate(); rng.shuffle(usyn)
    ucut = int(len(usyn) * 0.8); usyn_train, usyn_test = usyn[:ucut], usyn[ucut:]
    uX = matrix([u for u, _ in utrain] + [u for u, _ in usyn_train], url_features)
    um = LogisticRegression(C=4.0, solver="liblinear", max_iter=200)
    um.fit(uX, [y for _, y in utrain] + [y for _, y in usyn_train], sample_weight=[1.0] * len(utrain) + [3.0] * len(usyn_train))
    del uX
    qurl = Quantized(["phishing"], um.coef_, um.intercept_, url_features)
    def uprob(rows):
        return list(qurl.matrix_scores(matrix([u for u, _ in rows], url_features)))
    metrics["url"] = {}
    for th in (0.5, 0.95):
        metrics["url"][f"real, unseen domains, threshold {th}"] = binary_metrics([y for _, y in utest], uprob(utest), th)
        metrics["url"][f"generated email links, threshold {th}"] = binary_metrics([y for _, y in usyn_test], uprob(usyn_test), th)
    print(json.dumps(metrics["url"], indent=1))

    # ----- Export -----
    sizes = {}
    for name, model in (("scam", qscam), ("category", qcat), ("intent", qint), ("url", qurl)):
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
    golden_urls = ["https://www.paypal.com/fr/signin", "http://paypaI-secure.xyz/login.php?id=4&amp;x=1", "user@185.23.4.9:8080/a",
                   "HTTPS://Colissimo-Suivi.top/Paiement/", "www.impots.gouv.fr/accueil#top", "https://bit.ly/3xYz9", "https://exämple.fr/ça",
                   "https://sub.domain.example.co.uk/path/to/file.html?q=1", "", "https://"]
    lines += ["    }", "", "    @Test func theLinkModelMatchesTheTraining() throws {", "        let models = try #require(Models.shared)"]
    for u in golden_urls:
        lit = json.dumps(u, ensure_ascii=False)
        lines.append(f"        #expect(abs(models.linkProbability({lit}) - {qurl.scores(u)[0]:.6f}) < 1e-4, {lit})")
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

    anchors = write_anchors()
    print("anchors", anchors)

    # ----- Manifest, read by the app (Settings, Trained models) -----
    import datetime
    manifest = {
        "version": datetime.date.today().isoformat(),
        "scam": {"accuracy": metrics["scam"]["real (English emails and SMS, held out)"]["accuracy"],
                 "auc": metrics["scam"]["real (English emails and SMS, held out)"]["roc_auc"],
                 "falsePositives09": metrics["scam_operating"]["real (held out)"]["false_positive_rate"],
                 "recall09": metrics["scam_operating"]["real (held out)"]["recall"],
                 "messages": len(real) + len(synth), "weights": sizes["scam"][0]},
        "category": {"accuracy": metrics["category"]["accuracy, unseen templates"], "families": len(cats), "weights": sizes["category"][0]},
        "intent": {"accuracy": metrics["intent"]["right when understood"], "intents": len(names) - 1, "weights": sizes["intent"][0]},
        "url": {"auc": metrics["url"]["real, unseen domains, threshold 0.5"]["roc_auc"],
                "falsePositives095": metrics["url"]["real, unseen domains, threshold 0.95"]["false_positive_rate"],
                "recall095": metrics["url"]["real, unseen domains, threshold 0.95"]["recall"],
                "links": len(ureal) + len(usyn), "weights": sizes["url"][0]},
        "feedback": len(feedback),
    }
    (OUT / "models.json").write_text(json.dumps(manifest, indent=1) + "\n")

    # ----- Model card -----
    def table(m):
        rows = ["| Jeu d'évaluation | n | Exactitude | Précision | Rappel | F1 | Faux positifs | AUC |", "|---|---|---|---|---|---|---|---|"]
        for k, v in m.items():
            rows.append(f"| {k} | {v['n']} | {v['accuracy']:.3f} | {v['precision']:.3f} | {v['recall']:.3f} | {v['f1']:.3f} | {v['false_positive_rate']:.3f} | {v.get('roc_auc', float('nan')):.3f} |")
        return "\n".join(rows)
    kb = lambda n: sizes[n][1] // 1024
    card = f"""# Les modèles de MailZen

Quatre modèles linéaires (régression logistique), entraînés par [`train.py`](train.py) et exécutés
**sur l'appareil**, sans serveur : rien de ce que vous analysez ne quitte l'iPhone. Version
{manifest['version']}.

| Modèle | Rôle | Classes | Poids gardés | Taille |
|---|---|---|---|---|
| `scam` | probabilité qu'un message soit une arnaque, un phishing ou un spam | 1 (logistique) | {sizes['scam'][0]} | {kb('scam')} Ko |
| `category` | famille d'arnaque | {len(cats)} | {sizes['category'][0]} | {kb('category')} Ko |
| `intent` | question posée à ZenAI | {len(names)} ({len(names) - 1} sujets et « autre question ») | {sizes['intent'][0]} | {kb('intent')} Ko |
| `url` | probabilité qu'un lien mène à du phishing | 1 (logistique) | {sizes['url'][0]} | {kb('url')} Ko |

## Caractéristiques

- Textes : mots, paires de mots et trigrammes de caractères des mots, hachés (FNV-1a, 2^18) :
  [`features.py`](features.py).
- Liens : n-grammes de caractères de l'hôte et du chemin, étiquettes du domaine, extension, forme
  (longueur, points, tirets, chiffres, adresse IP, `@`, port…) : [`url_features.py`](url_features.py).

Les deux sont reproduits à l'identique en Swift (`Models.swift`) et vérifiés par des tests dorés.
Les poids sont compressés sur 8 bits ; les mesures ci-dessous sont celles des modèles compressés.

## Données

- **all-scam-spam** (Apache-2.0, FredZhang7) : emails de spam et légitimes, surtout en anglais ;
- **phishing-dataset** (Apache-2.0, ealvaradob), parties `texts` (emails et SMS) et `urls`
  ({len(ureal)} liens, sûrs ou de phishing) ;
- **SMS Spam Collection** (CC BY 4.0, UCI) ;
- un **corpus généré** ([`corpus.py`](corpus.py), [`corpus_families.py`](corpus_families.py)) en
  français, anglais et espagnol : {len(corpus.templates())} modèles de messages (10 familles d'arnaques et
  10 sortes de messages légitimes qui leur ressemblent), remplis de marques, montants, délais et
  liens variés ; [`urls.py`](urls.py) pour des liens comme ceux des emails (officiels, petits sites,
  imitations) ; [`intents.py`](intents.py) et [`intents_more.py`](intents_more.py) pour ZenAI ;
- les **corrections des utilisateurs** exportées par l'app (`--feedback`) : {len(feedback)} pour cette version.

Les données réelles sont presque toutes en anglais : en français et en espagnol, les modèles
reposent sur le corpus généré. Les évaluations du corpus généré portent sur des **modèles de
messages entiers jamais vus à l'entraînement**, mais elles restent plus faciles que la réalité.

## Évaluation

### `scam`

Seuil 0,5. Données réelles : {len(real)} messages après dédoublonnage, 15 % gardés pour le test.

{table(metrics['scam'])}

Au seuil de **0,9**, celui où l'app ajoute le signal « ressemble à des arnaques connues » et où,
en mode autonome, le modèle classe seul le message « Suspect » :

{table(metrics['scam_operating'])}

Au seuil de **0,98**, celui où, en mode autonome, le modèle classe seul le message « Danger élevé » :

{table({"real (held out)": metrics['scam_danger']})}

### `category`

Validation croisée en 5 parts sur {metrics['category']['templates']} modèles de messages entiers (un modèle et ses
traductions restent ensemble) : exactitude **{metrics['category']['accuracy, unseen templates']:.3f}**.

{chr(10).join(f"- {k} : {v:.2f}" for k, v in metrics['category']['per family'].items())}

### `intent`

Validation croisée en 4 parts sur des formulations jamais vues ({len(names) - 1} sujets et la classe
« autre question »). ZenAI tient un sujet pour compris quand le modèle lui donne au moins 45 % et
que ce n'est pas « autre question » :

- questions des sujets connus tenues pour comprises : **{metrics['intent']['understood']:.3f}** ;
- bon sujet quand la question est tenue pour comprise : **{metrics['intent']['right when understood']:.3f}** ;
- questions hors des sujets connus reconnues comme telles : **{metrics['intent']['other questions recognized']:.3f}** ;
- exactitude brute sur les {len(names)} classes : {metrics['intent']['accuracy, unseen phrasings']:.3f}.

Quand la question n'est pas comprise, ZenAI essaie des mots-clés, puis répond à partir de tous
les faits de l'analyse (reformulés par Apple Intelligence quand l'iPhone l'a).

### `url`

Liens réels gardés à part **par domaine** (aucun domaine du test n'est vu à l'entraînement) et liens
générés. L'app n'utilise ce modèle qu'au seuil de **0,95**, et jamais pour un domaine officiel vérifié.

{table(metrics['url'])}

## Apprentissage sur l'appareil

Chaque correction de l'utilisateur (« MailZen s'est trompé ? ») réentraîne sur l'iPhone, en Swift
(`PersonalModel.swift`), une couche personnelle ajoutée au modèle `scam` : une régression
logistique sur les seules caractéristiques des messages corrigés, retenue par {anchors} messages de
référence (`anchors.json`) dont les réponses ne doivent pas bouger. Le message corrigé est
mémorisé tel quel ; ceux qui lui ressemblent changent de score. Rien ne quitte l'appareil.

## Autonomie et limites

- En mode autonome (par défaut), le modèle `scam` décide seul quand il est sûr : au moins
  « Suspect » dès 0,9 et « Danger élevé » dès 0,98, même si aucune règle ne s'est déclenchée
  (faux positifs mesurés ci-dessus). En dessous, il n'ajoute rien : les règles décident.
- Il ne se prononce jamais contre un message dont tous les liens mènent à des domaines officiels
  vérifiés, et ce que l'utilisateur a appris à MailZen n'abaisse jamais un score en présence
  d'une usurpation ou d'une pièce jointe dangereuse.
- Un modèle statistique se trompe : les mesures de cette fiche disent à quelle fréquence. Les
  données réelles sont en anglais ; le français et l'espagnol reposent sur le corpus généré.
- Le modèle des liens ne voit que l'adresse : ni la page, ni sa réputation en temps réel. Les
  petits sites inconnus et les liens de suivi des newsletters sont ses faux positifs les plus
  fréquents ; il ne signale donc qu'à partir de 0,95.
- Les arnaques évoluent : l'apprentissage sur l'appareil suit l'utilisateur ; le modèle de base
  doit être réentraîné régulièrement (`--feedback`).
"""
    CARD.write_text(card)
    print("written", OUT, TESTS, CARD)

    # ----- The models of the website demo -----
    import web
    print(json.dumps(web.export(args.data), indent=1))


if __name__ == "__main__":
    main()
