# Les modèles de MailZen

Trois modèles linéaires (régression logistique), entraînés par [`train.py`](train.py) et exécutés
**sur l'appareil**, sans serveur : rien de ce que vous analysez ne quitte l'iPhone.

| Modèle | Rôle | Classes | Poids gardés | Taille |
|---|---|---|---|---|
| `scam` | probabilité qu'un message soit une arnaque, un phishing ou un spam | 1 (logistique) | 163649 | 799 Ko |
| `category` | famille d'arnaque | 10 | 9522 | 130 Ko |
| `intent` | question posée à ZenAI | 11 | 4263 | 62 Ko |

## Caractéristiques

Mots, paires de mots et trigrammes de caractères des mots, hachés (FNV-1a, 2^18) : voir
[`features.py`](features.py), reproduit à l'identique en Swift et vérifié par des tests dorés.
Les poids sont compressés sur 8 bits ; les mesures ci-dessous sont celles des modèles compressés.

## Données

- **all-scam-spam** (Apache-2.0, FredZhang7) : emails de spam et légitimes, surtout en anglais ;
- **phishing-dataset** (Apache-2.0, ealvaradob), partie `texts` : emails et SMS de phishing ;
- **SMS Spam Collection** (CC BY 4.0, UCI) ;
- un **corpus généré** ([`corpus.py`](corpus.py)) en français, anglais et espagnol : 369 modèles
  de messages (10 familles d'arnaques et 10 sortes de messages légitimes qui leur ressemblent),
  remplis de marques, montants, délais et liens variés ; et [`intents.py`](intents.py) pour ZenAI.

Les données réelles sont presque toutes en anglais : en français et en espagnol, les modèles
reposent sur le corpus généré. Les évaluations du corpus généré portent sur des **modèles de
messages entiers jamais vus à l'entraînement**, mais elles restent plus faciles que la réalité.

## Évaluation

Seuil 0,5 sauf mention. Données réelles : 60570 messages après dédoublonnage, 15 % gardés pour le test.

### `scam`

| Jeu d'évaluation | n | Exactitude | Précision | Rappel | F1 | Faux positifs | AUC |
|---|---|---|---|---|---|---|---|
| real (English emails and SMS, held out) | 9086 | 0.983 | 0.983 | 0.976 | 0.980 | 0.011 | 0.998 |
| generated, unseen templates (fr) | 660 | 1.000 | 1.000 | 1.000 | 1.000 | 0.000 | 1.000 |
| generated, unseen templates (en) | 660 | 0.839 | 0.891 | 0.838 | 0.863 | 0.158 | 0.968 |
| generated, unseen templates (es) | 660 | 0.942 | 0.913 | 1.000 | 0.955 | 0.146 | 0.999 |

Au seuil de **0,9**, celui où l'app ajoute le signal « ressemble à des arnaques connues » :

| Jeu d'évaluation | n | Exactitude | Précision | Rappel | F1 | Faux positifs | AUC |
|---|---|---|---|---|---|---|---|
| real (held out) | 9086 | 0.964 | 0.998 | 0.913 | 0.954 | 0.001 | 0.998 |
| generated (fr) | 660 | 0.888 | 1.000 | 0.815 | 0.898 | 0.000 | 1.000 |
| generated (en) | 660 | 0.839 | 1.000 | 0.735 | 0.847 | 0.000 | 0.968 |
| generated (es) | 660 | 0.967 | 1.000 | 0.945 | 0.972 | 0.000 | 0.999 |

### `category`

Exactitude sur des modèles de messages jamais vus : **0.618** (n = 1200).

- account : 0.23
- bank : 0.93
- blackmail : 0.39
- business : 0.33
- delivery : 0.66
- government : 0.53
- prize : 0.53
- romance : 0.67
- tech_support : 1.00

### `intent`

Exactitude sur des formulations jamais vues : **0.708** (n = 504).

## Limites

- Un modèle statistique se trompe : il ne décide jamais seul. Le verdict de MailZen reste celui du
  moteur de règles ; le modèle ajoute un signal (« ressemble à des arnaques connues ») et la
  famille d'arnaque, que ZenAI explique avec son niveau de confiance.
- Il ne voit que le texte : ni la réputation des liens, ni le contenu des pièces jointes
  (c'est le rôle d'Attachment Guard et de Link Guard).
- Les arnaques évoluent : le modèle doit être réentraîné régulièrement avec de nouveaux exemples.
