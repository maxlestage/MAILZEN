# Les modèles de MailZen

Quatre modèles linéaires (régression logistique), entraînés par [`train.py`](train.py) et exécutés
**sur l'appareil**, sans serveur : rien de ce que vous analysez ne quitte l'iPhone. Version
2026-11-26.

| Modèle | Rôle | Classes | Poids gardés | Taille |
|---|---|---|---|---|
| `scam` | probabilité qu'un message soit une arnaque, un phishing ou un spam | 1 (logistique) | 162685 | 794 Ko |
| `category` | famille d'arnaque | 10 | 13193 | 180 Ko |
| `intent` | question posée à ZenAI | 14 (13 sujets et « autre question ») | 8324 | 146 Ko |
| `url` | probabilité qu'un lien mène à du phishing | 1 (logistique) | 238101 | 1162 Ko |

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
  (821399 liens, sûrs ou de phishing) ;
- **SMS Spam Collection** (CC BY 4.0, UCI) ;
- un **corpus généré** ([`corpus.py`](corpus.py), [`corpus_families.py`](corpus_families.py)) en
  français, anglais et espagnol : 513 modèles de messages (10 familles d'arnaques et
  10 sortes de messages légitimes qui leur ressemblent), remplis de marques, montants, délais et
  liens variés ; [`urls.py`](urls.py) pour des liens comme ceux des emails (officiels, petits sites,
  imitations) ; [`intents.py`](intents.py) et [`intents_more.py`](intents_more.py) pour ZenAI ;
- les **corrections des utilisateurs** exportées par l'app (`--feedback`) : 0 pour cette version.

Les données réelles sont presque toutes en anglais : en français et en espagnol, les modèles
reposent sur le corpus généré. Les évaluations du corpus généré portent sur des **modèles de
messages entiers jamais vus à l'entraînement**, mais elles restent plus faciles que la réalité.

## Évaluation

### `scam`

Seuil 0,5. Données réelles : 60570 messages après dédoublonnage, 15 % gardés pour le test.

| Jeu d'évaluation | n | Exactitude | Précision | Rappel | F1 | Faux positifs | AUC |
|---|---|---|---|---|---|---|---|
| real (English emails and SMS, held out) | 9086 | 0.983 | 0.982 | 0.976 | 0.979 | 0.012 | 0.998 |
| generated, unseen templates (fr) | 1100 | 1.000 | 1.000 | 1.000 | 1.000 | 0.000 | 1.000 |
| generated, unseen templates (en) | 1100 | 0.938 | 0.956 | 0.963 | 0.960 | 0.142 | 0.992 |
| generated, unseen templates (es) | 1100 | 0.959 | 0.949 | 1.000 | 0.974 | 0.173 | 1.000 |

Au seuil de **0,9**, celui où l'app ajoute le signal « ressemble à des arnaques connues » et où,
en mode autonome, le modèle classe seul le message « Suspect » :

| Jeu d'évaluation | n | Exactitude | Précision | Rappel | F1 | Faux positifs | AUC |
|---|---|---|---|---|---|---|---|
| real (held out) | 9086 | 0.963 | 0.997 | 0.912 | 0.953 | 0.002 | 0.998 |
| generated (fr) | 1100 | 0.995 | 1.000 | 0.993 | 0.996 | 0.000 | 1.000 |
| generated (en) | 1100 | 0.935 | 1.000 | 0.915 | 0.956 | 0.000 | 0.992 |
| generated (es) | 1100 | 0.999 | 1.000 | 0.999 | 0.999 | 0.000 | 1.000 |

Au seuil de **0,98**, celui où, en mode autonome, le modèle classe seul le message « Danger élevé » :

| Jeu d'évaluation | n | Exactitude | Précision | Rappel | F1 | Faux positifs | AUC |
|---|---|---|---|---|---|---|---|
| real (held out) | 9086 | 0.912 | 0.999 | 0.784 | 0.878 | 0.001 | 0.998 |

### `category`

Validation croisée en 5 parts sur 372 modèles de messages entiers (un modèle et ses
traductions restent ensemble) : exactitude **0.812**.

- account : 0.89
- bank : 0.87
- blackmail : 0.75
- business : 0.89
- delivery : 0.87
- government : 0.70
- investment : 0.64
- prize : 0.67
- romance : 1.00
- tech_support : 0.74

### `intent`

Validation croisée en 4 parts sur des formulations jamais vues (13 sujets et la classe
« autre question »). ZenAI tient un sujet pour compris quand le modèle lui donne au moins 45 % et
que ce n'est pas « autre question » :

- questions des sujets connus tenues pour comprises : **0.678** ;
- bon sujet quand la question est tenue pour comprise : **0.777** ;
- questions hors des sujets connus reconnues comme telles : **0.744** ;
- exactitude brute sur les 14 classes : 0.585.

Quand la question n'est pas comprise, ZenAI essaie des mots-clés, puis répond à partir de tous
les faits de l'analyse (reformulés par Apple Intelligence quand l'iPhone l'a).

### `url`

Liens réels gardés à part **par domaine** (aucun domaine du test n'est vu à l'entraînement) et liens
générés. L'app n'utilise ce modèle qu'au seuil de **0,95**, et jamais pour un domaine officiel vérifié.

| Jeu d'évaluation | n | Exactitude | Précision | Rappel | F1 | Faux positifs | AUC |
|---|---|---|---|---|---|---|---|
| real, unseen domains, threshold 0.5 | 129499 | 0.944 | 0.948 | 0.953 | 0.951 | 0.068 | 0.987 |
| generated email links, threshold 0.5 | 10000 | 0.999 | 1.000 | 0.998 | 0.999 | 0.000 | 1.000 |
| real, unseen domains, threshold 0.95 | 129499 | 0.780 | 0.996 | 0.614 | 0.759 | 0.003 | 0.987 |
| generated email links, threshold 0.95 | 10000 | 0.983 | 1.000 | 0.957 | 0.978 | 0.000 | 1.000 |

<!-- web -->
## Les modèles du site

La démo du site utilise **les mêmes modèles que l'app, entiers** ([`web.py`](web.py)) : le
navigateur les télécharge quand un visiteur lance une analyse et les exécute en Rust compilé en
WebAssembly (`src/models.rs`, vérifié par `tests/model_golden.rs`). Mêmes seuils, même autonomie.

| Modèle | Poids | Taille |
|---|---|---|
| `scam` | 162685 | 794 Ko |
| `url` | 238101 | 1162 Ko |
| `category` | 13193 | 180 Ko |
<!-- /web -->

## Apprentissage sur l'appareil

Chaque correction de l'utilisateur (« MailZen s'est trompé ? ») réentraîne sur l'iPhone, en Swift
(`PersonalModel.swift`), une couche personnelle ajoutée au modèle `scam` : une régression
logistique sur les seules caractéristiques des messages corrigés, retenue par 513 messages de
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
