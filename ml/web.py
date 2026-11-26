"""The models of the website demo: the app's models (Resources/*.mzm) pruned to their
strongest weights, so that the browser downloads little, written into public/assets/models,
with the golden tests that check the Rust code (src/models.rs) computes the same thing.

    python3 web.py --data <folder of fetch.sh>     (train.py runs it at the end)
"""
import argparse, json, math, random, struct, zlib
from pathlib import Path

import numpy as np

from features import DIM, features
from url_features import url_features, normalize as url_normalize, split as url_split

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "apps/ios/MailZenKit/Sources/MailZenKit/Resources"
WEB = ROOT / "public/assets/models"
TESTS = ROOT / "tests/model_golden.rs"
KEEP = {"scam": 40000, "category": 6000, "url": 50000}


class Mzm:
    def __init__(self, path, featurize):
        b = Path(path).read_bytes()
        assert b[:4] == b"MZM1"
        dim, k, nl = struct.unpack_from("<IHI", b, 4)
        o = 14
        self.classes = b[o:o + nl].decode().split("\n"); o += nl
        (self.scale,) = struct.unpack_from("<f", b, o); o += 4
        self.bias = np.array(struct.unpack_from("<" + "f" * k, b, o), dtype=np.float32); o += 4 * k
        (n,) = struct.unpack_from("<I", b, o); o += 4
        self.idx = np.zeros(n, dtype=np.uint32); self.w = np.zeros((n, k), dtype=np.int8)
        for i in range(n):
            self.idx[i] = struct.unpack_from("<I", b, o)[0]; o += 4
            self.w[i] = np.frombuffer(b, dtype=np.int8, count=k, offset=o); o += k
        self.featurize = featurize
        self._index()

    def _index(self):
        self.pos = {int(j): i for i, j in enumerate(self.idx)}

    def prune(self, keep):
        strength = np.abs(self.w.astype(np.int32)).max(axis=1)
        order = np.sort(np.argsort(-strength, kind="stable")[:keep])
        self.idx, self.w = self.idx[order], self.w[order]
        self._index()
        return self

    def scores(self, text):
        f = self.featurize(text)
        s = self.bias.astype(np.float64).copy()
        if f:
            acc = np.zeros(len(self.classes), dtype=np.int64)
            for j in f:
                i = self.pos.get(j)
                if i is not None:
                    acc += self.w[i]
            s = s + self.scale * acc / math.sqrt(len(f))
        if len(self.classes) == 1:
            return np.array([1 / (1 + math.exp(-s[0]))])
        e = np.exp(s - s.max())
        return e / e.sum()

    def write(self, path):
        names = "\n".join(self.classes).encode()
        k = len(self.classes)
        with open(path, "wb") as f:
            f.write(b"MZM1" + struct.pack("<IHI", DIM, k, len(names)) + names)
            f.write(struct.pack("<f", self.scale) + struct.pack("<" + "f" * k, *self.bias.tolist()))
            f.write(struct.pack("<I", len(self.idx)))
            for j, row in zip(self.idx, self.w):
                f.write(struct.pack("<I", int(j)) + row.tobytes())
        return path.stat().st_size


def metrics(y, p, th):
    y = np.array(y); pr = np.array(p) >= th
    tp = int((pr & (y == 1)).sum()); fp = int((pr & (y == 0)).sum())
    return {"recall": tp / max((y == 1).sum(), 1), "false_positive_rate": fp / max((y == 0).sum(), 1)}


def export(data, sample=3000):
    import corpus, train, urls
    WEB.mkdir(parents=True, exist_ok=True)
    rng = random.Random(42)
    real = train.load_real(data); rng.shuffle(real)
    real_test = real[int(len(real) * 0.85):]
    sub = random.Random(1).sample(real_test, min(sample, len(real_test)))
    ureal = urls.load(data / "urls.json")
    dom = lambda u: ".".join(url_split(url_normalize(u))[0].split(".")[-2:])
    utest = [r for r in ureal if zlib.crc32(dom(r[0]).encode()) % 100 < 15]
    usub = random.Random(2).sample(utest, min(sample * 2, len(utest)))
    report = {}
    models = {}
    for name, featurize in (("scam", features), ("category", features), ("url", url_features)):
        full = Mzm(APP / f"{name}.mzm", featurize)
        lite = Mzm(APP / f"{name}.mzm", featurize).prune(KEEP[name])
        size = lite.write(WEB / f"{name}.mzm")
        models[name] = lite
        entry = {"weights": len(lite.idx), "kilobytes": size // 1024}
        if name == "scam":
            for th in (0.5, 0.9):
                entry[f"app@{th}"] = metrics([y for _, y, _ in sub], [full.scores(t)[0] for t, _, _ in sub], th)
                entry[f"web@{th}"] = metrics([y for _, y, _ in sub], [lite.scores(t)[0] for t, _, _ in sub], th)
        if name == "url":
            for th in (0.5, 0.95):
                entry[f"app@{th}"] = metrics([y for _, y in usub], [full.scores(u)[0] for u, _ in usub], th)
                entry[f"web@{th}"] = metrics([y for _, y in usub], [lite.scores(u)[0] for u, _ in usub], th)
        if name == "category":
            rows = [r for r in corpus.generate(per_template=3) if r[1] == 1]
            same = sum(int(np.argmax(full.scores(r[4]))) == int(np.argmax(lite.scores(r[4]))) for r in rows)
            entry["agreement with the app"] = same / len(rows)
        report[name] = entry
    golden(models)
    card(report)
    return report


def card(report):
    """The section of the model card about the models of the site."""
    path = ROOT / "ml/MODEL_CARD.md"
    text = path.read_text()
    start, end = "<!-- web -->", "<!-- /web -->"
    if start in text:
        text = text[:text.index(start)] + text[text.index(end) + len(end):].lstrip("\n")
    s, u = report["scam"], report["url"]
    section = f"""{start}
## Les modèles du site

La démo du site utilise les modèles de l'app réduits à leurs poids les plus forts ([`web.py`](web.py)),
téléchargés par le navigateur seulement quand un visiteur lance une analyse, et exécutés en Rust
compilé en WebAssembly (`src/models.rs`, vérifié par `tests/model_golden.rs`).

| Modèle | Poids gardés | Taille | App | Site |
|---|---|---|---|---|
| `scam` (seuil 0,9) | {s['weights']} | {s['kilobytes']} Ko | rappel {s['app@0.9']['recall']:.3f}, faux positifs {s['app@0.9']['false_positive_rate']:.4f} | rappel {s['web@0.9']['recall']:.3f}, faux positifs {s['web@0.9']['false_positive_rate']:.4f} |
| `url` (seuil 0,95) | {u['weights']} | {u['kilobytes']} Ko | rappel {u['app@0.95']['recall']:.3f}, faux positifs {u['app@0.95']['false_positive_rate']:.4f} | rappel {u['web@0.95']['recall']:.3f}, faux positifs {u['web@0.95']['false_positive_rate']:.4f} |
| `category` | {report['category']['weights']} | {report['category']['kilobytes']} Ko | — | même famille que l'app pour {report['category']['agreement with the app']:.1%} des messages générés |
{end}
"""
    text = text.replace("## Limites", section + "\n## Limites", 1)
    path.write_text(text)


GOLDEN_TEXTS = [
    "Colissimo : votre colis est en attente, frais de 1,99 € à régler : https://bit.ly/c0lis",
    "Rappel : votre rendez-vous chez le dentiste est le 12/3 à 14h30.",
    "Your Netflix account will be suspended within 24 hours. Confirm your payment: http://netfIix-secure.xyz/login",
    "Su paquete está retenido en aduanas. Pague 2,99 € aquí: https://correos-envio.top/pago",
    "J'ai piraté votre ordinateur. Envoyez 900 € en Bitcoin sous 48 heures.",
    "ÉTÉ 2026 : Àçcéntués, chiffres 0123456789 et ponctuation… — fin.",
    "",
]
GOLDEN_URLS = ["https://www.paypal.com/fr/signin", "http://paypaI-secure.xyz/login.php?id=4&amp;x=1", "user@185.23.4.9:8080/a",
               "HTTPS://Colissimo-Suivi.top/Paiement/", "www.impots.gouv.fr/accueil#top", "https://bit.ly/3xYz9", "https://exämple.fr/ça",
               "https://sub.domain.example.co.uk/path/to/file.html?q=1", "", "https://"]


def golden(models):
    lit = lambda s: json.dumps(s, ensure_ascii=False)
    lines = ["//! Generated by ml/web.py: the Rust models of the demo must compute what the Python ones compute.", "",
             "use mailzen_site::models::{LinearModel, text_features, url_features};", "",
             "fn load(name: &str) -> LinearModel {",
             "    let path = format!(",
             "        \"{}/public/assets/models/{name}.mzm\",",
             "        env!(\"CARGO_MANIFEST_DIR\")",
             "    );",
             "    LinearModel::parse(&std::fs::read(path).expect(\"model file\")).expect(\"valid model\")",
             "}", "", "fn close(a: f64, b: f64) -> bool {", "    (a - b).abs() < 1e-4", "}", "",
             "#[test]", "#[rustfmt::skip]", "fn the_text_models_match_the_training() {",
             "    let scam = load(\"scam\");", "    let category = load(\"category\");"]
    for t in GOLDEN_TEXTS:
        s = models["scam"].scores(t)[0]; c = models["category"].scores(t)
        lines.append(f"    assert!(close(scam.probabilities(&text_features({lit(t)}))[0], {s:.6f}), {lit(t)});")
        lines.append(f"    let c = category.best(&text_features({lit(t)}));")
        lines.append(f"    assert!(c.0 == \"{models['category'].classes[int(np.argmax(c))]}\" && close(c.1, {c.max():.6f}), {lit(t)});")
    lines += ["}", "", "#[test]", "#[rustfmt::skip]", "fn the_link_model_matches_the_training() {", "    let url = load(\"url\");"]
    for u in GOLDEN_URLS:
        lines.append(f"    assert!(close(url.probabilities(&url_features({lit(u)}))[0], {models['url'].scores(u)[0]:.6f}), {lit(u)});")
    lines += ["}", ""]
    TESTS.write_text("\n".join(lines))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", type=Path, required=True)
    print(json.dumps(export(ap.parse_args().data), indent=1))
