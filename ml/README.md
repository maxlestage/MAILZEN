# Les modèles de MailZen

```sh
pip install -r requirements.txt
./fetch.sh data            # les jeux de données publics
python3 train.py --data data
```

`train.py` entraîne les trois modèles, les écrit (compressés sur 8 bits) dans
`apps/ios/MailZenKit/Sources/MailZenKit/Resources/`, génère les tests dorés Swift
(`ModelGoldenTests.swift`) et la fiche des modèles avec l'évaluation : [MODEL_CARD.md](MODEL_CARD.md).

| Fichier | Rôle |
|---|---|
| `features.py` | les caractéristiques, reproduites à l'identique en Swift (`Models.swift`) |
| `corpus.py`, `corpus_more.py` | le corpus généré, en français, anglais et espagnol |
| `intents.py` | les questions posées à ZenAI |
| `train.py` | l'entraînement, l'évaluation et l'export |
