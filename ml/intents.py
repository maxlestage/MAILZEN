"""The questions people ask ZenAI, in French, English and Spanish, by intent."""
import random
import unicodedata

INTENTS = {
 "why": {
  "fr": ["pourquoi ce mail est-il suspect", "pourquoi c'est dangereux", "c'est une arnaque ?", "est-ce que c'est du phishing", "qu'est-ce qui cloche dans ce message",
         "explique-moi le résultat", "pourquoi ce score", "c'est fiable ce mail", "ce message est-il dangereux", "c'est un vrai mail ou un faux", "pourquoi tu dis que c'est suspect", "c'est grave ?"],
  "en": ["why is this email suspicious", "why is it dangerous", "is this a scam", "is this phishing", "what's wrong with this message",
         "explain the result", "why this score", "is this email legit", "is this message dangerous", "is it real or fake", "why do you say it's suspicious", "is it bad?"],
  "es": ["por qué este correo es sospechoso", "por qué es peligroso", "es una estafa", "es phishing", "qué tiene de raro este mensaje",
         "explícame el resultado", "por qué esta puntuación", "es fiable este correo", "este mensaje es peligroso", "es real o falso", "por qué dices que es sospechoso", "es grave?"]},
 "sender": {
  "fr": ["qui est réellement l'expéditeur", "qui m'a envoyé ce mail", "l'adresse est-elle la bonne", "c'est vraiment ma banque qui écrit", "d'où vient ce message", "l'expéditeur est-il fiable", "c'est le vrai paypal ?", "à qui appartient cette adresse"],
  "en": ["who is the real sender", "who sent me this email", "is the address right", "is it really my bank writing", "where does this message come from", "is the sender trustworthy", "is it the real paypal?", "who owns this address"],
  "es": ["quién es realmente el remitente", "quién me ha enviado este correo", "la dirección es la correcta", "es de verdad mi banco", "de dónde viene este mensaje", "el remitente es fiable", "es el paypal de verdad?", "de quién es esta dirección"]},
 "link": {
  "fr": ["est-ce que le lien est dangereux", "je peux cliquer sur le lien", "ce site est-il sûr", "où mène ce lien", "l'url est-elle fiable", "le lien est-il un piège", "puis-je ouvrir le lien"],
  "en": ["is the link dangerous", "can I click the link", "is this website safe", "where does this link go", "is the url safe", "is the link a trap", "may I open the link"],
  "es": ["el enlace es peligroso", "puedo hacer clic en el enlace", "esta web es segura", "a dónde lleva este enlace", "la url es fiable", "el enlace es una trampa", "puedo abrir el enlace"]},
 "file": {
  "fr": ["est-ce que je peux ouvrir le fichier", "la pièce jointe est-elle dangereuse", "ce pdf est-il sûr", "puis-je télécharger le document", "le fichier contient-il un virus", "j'ouvre la facture jointe ?"],
  "en": ["can I open the file", "is the attachment dangerous", "is this pdf safe", "can I download the document", "does the file contain a virus", "should I open the attached invoice?"],
  "es": ["puedo abrir el archivo", "el adjunto es peligroso", "este pdf es seguro", "puedo descargar el documento", "el archivo tiene un virus", "abro la factura adjunta?"]},
 "reply": {
  "fr": ["est-ce que je dois répondre", "je peux répondre à ce mail", "faut-il répondre", "que répondre", "je réponds ou pas"],
  "en": ["should I reply", "can I answer this email", "do I need to respond", "what should I reply", "do I answer or not"],
  "es": ["debo responder", "puedo contestar este correo", "hay que responder", "qué respondo", "respondo o no"]},
 "verify": {
  "fr": ["comment vérifier l'entreprise", "comment contacter le vrai service", "quel est le site officiel", "comment être sûr que c'est vrai", "comment joindre ma banque", "c'est quoi le vrai numéro"],
  "en": ["how do I check the company", "how do I contact the real service", "what is the official website", "how can I be sure it's real", "how do I reach my bank", "what's the real phone number"],
  "es": ["cómo verifico la empresa", "cómo contacto con el servicio real", "cuál es la web oficial", "cómo estar seguro de que es real", "cómo contacto con mi banco", "cuál es el número de verdad"]},
 "clicked": {
  "fr": ["que faire si j'ai cliqué", "j'ai cliqué sur le lien", "j'ai ouvert le lien, c'est grave", "oups j'ai cliqué", "j'ai déjà cliqué que faire", "j'ai visité le site"],
  "en": ["what if I clicked", "I clicked the link", "I opened the link, is it bad", "oops I clicked", "I already clicked what now", "I visited the site"],
  "es": ["qué hago si hice clic", "hice clic en el enlace", "abrí el enlace, es grave", "ups hice clic", "ya hice clic qué hago", "visité la web"]},
 "password": {
  "fr": ["que faire si j'ai donné mon mot de passe", "j'ai saisi mon mot de passe", "j'ai tapé mes identifiants sur le site", "ils ont mon mot de passe", "j'ai donné mon code"],
  "en": ["what if I gave my password", "I entered my password", "I typed my login on the site", "they have my password", "I gave my code"],
  "es": ["qué hago si di mi contraseña", "introduje mi contraseña", "escribí mis credenciales en la web", "tienen mi contraseña", "di mi código"]},
 "report": {
  "fr": ["comment signaler ce mail", "où signaler une arnaque", "je veux porter plainte", "comment dénoncer ce message", "à qui le signaler"],
  "en": ["how do I report this email", "where can I report a scam", "I want to file a complaint", "how do I report this message", "who should I report it to"],
  "es": ["cómo denuncio este correo", "dónde denunciar una estafa", "quiero poner una denuncia", "cómo reporto este mensaje", "a quién se lo digo"]},
 "money": {
  "fr": ["est-ce que je peux récupérer mon argent", "j'ai payé, que faire", "j'ai fait un virement", "ils m'ont pris de l'argent", "comment me faire rembourser", "j'ai donné ma carte bancaire"],
  "en": ["can I get my money back", "I paid, what now", "I made a transfer", "they took my money", "how do I get a refund", "I gave my card details"],
  "es": ["puedo recuperar mi dinero", "he pagado, qué hago", "hice una transferencia", "me han quitado dinero", "cómo me devuelven el dinero", "di mi tarjeta"]},
 "summary": {
  "fr": ["résume", "en bref", "bonjour", "salut", "aide", "que peux-tu faire", "merci", "ok"],
  "en": ["summarize", "in short", "hello", "hi", "help", "what can you do", "thanks", "ok"],
  "es": ["resume", "en resumen", "hola", "buenas", "ayuda", "qué puedes hacer", "gracias", "vale"]},
}

PREFIX = {"fr": ["", "", "dis-moi ", "zenai ", "s'il te plaît ", "au fait "], "en": ["", "", "tell me ", "zenai ", "please ", "so "],
          "es": ["", "", "dime ", "zenai ", "por favor ", "oye "]}


def strip_accents(s):
    return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")


def merged():
    from corpus_more import MORE_INTENTS
    out = {k: {l: list(v) for l, v in langs.items()} for k, langs in INTENTS.items()}
    for k, langs in MORE_INTENTS.items():
        for l, v in langs.items():
            out[k][l] += v
    return out


def typo(rng, s):
    if len(s) < 6:
        return s
    i = rng.randrange(1, len(s) - 1)
    return s[:i] + s[i + 1:] if rng.random() < 0.5 else s[:i] + s[i + 1] + s[i] + s[i + 2:]


def generate(seed=11, copies=6):
    rng = random.Random(seed)
    rows = []
    for intent, langs in merged().items():
        for lang, phrases in langs.items():
            for i, p in enumerate(phrases):
                for _ in range(copies):
                    q = rng.choice(PREFIX[lang]) + p
                    if rng.random() < 0.3:
                        q = strip_accents(q)
                    if rng.random() < 0.2:
                        q = typo(rng, q)
                    if rng.random() < 0.5:
                        q = q[0].upper() + q[1:]
                    q += rng.choice(["", " ?", "?", " ?!", "."])
                    rows.append((f"{intent}/{lang}/{i}", intent, lang, q))
    return rows
