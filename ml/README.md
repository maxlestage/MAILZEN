# Les modèles de MailZen

```sh
pip install -r requirements.txt
./fetch.sh data                                     # les jeux de données publics
python3 train.py --data data                        # entraînement, évaluation, export
python3 train.py --data data --feedback mailzen-corrections.jsonl   # avec les corrections de l'app
```

`train.py` entraîne les quatre modèles, les écrit (compressés sur 8 bits) dans
`apps/ios/MailZenKit/Sources/MailZenKit/Resources/` avec `models.json` (les mesures, affichées dans
l'app : Réglages › Intelligence sur l'appareil), génère les tests dorés Swift
(`ModelGoldenTests.swift`) et la fiche des modèles : [MODEL_CARD.md](MODEL_CARD.md).

| Fichier | Rôle |
|---|---|
| `features.py` | les caractéristiques des textes, reproduites à l'identique en Swift (`Models.swift`) |
| `url_features.py` | les caractéristiques des liens, reproduites elles aussi (`URLFeaturizer`) |
| `corpus.py`, `corpus_more.py`, `corpus_families.py` | le corpus généré, en français, anglais et espagnol |
| `urls.py` | les liens : jeu public et liens générés comme ceux des emails |
| `intents.py`, `intents_more.py` | les questions posées à ZenAI |
| `train.py` | l'entraînement, l'évaluation et l'export |

## Les corrections

Dans l'app, « MailZen s'est trompé ? » en bas d'un rapport enregistre une correction (arnaque ou
légitime, famille d'arnaque) sur l'iPhone. Réglages › Intelligence sur l'appareil › Exporter
produit `mailzen-corrections.jsonl` (une ligne `{"text", "label", "category"}` par correction),
que `--feedback` ajoute à l'entraînement avec un poids élevé. Ces fichiers contiennent le texte de
vrais messages : ils ne doivent jamais être versés dans le dépôt.
