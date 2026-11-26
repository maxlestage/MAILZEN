"""The generated corpus of MailZen: scams of every family of the specification and
legitimate messages that look like them, in French, English and Spanish. Each template
has an id, so that whole templates can be kept apart for the evaluation."""
import random

CATEGORIES = ["bank", "delivery", "government", "business", "investment", "romance",
              "blackmail", "tech_support", "prize", "account"]

F = {
    "bank": {"fr": ["Société Générale", "BNP Paribas", "LCL", "Caisse d'Épargne", "Crédit Mutuel", "La Banque Postale", "votre banque"],
             "en": ["Chase", "Barclays", "HSBC", "Lloyds Bank", "Wells Fargo", "your bank"],
             "es": ["BBVA", "Santander", "CaixaBank", "Bankinter", "Sabadell", "su banco"]},
    "carrier": {"fr": ["Colissimo", "Chronopost", "La Poste", "DHL", "UPS", "Mondial Relay"],
                "en": ["Royal Mail", "DHL", "UPS", "FedEx", "USPS", "Evri"],
                "es": ["Correos", "SEUR", "DHL", "UPS", "MRW", "GLS"]},
    "gov": {"fr": ["Impots.gouv", "Ameli", "la CAF", "l'ANTS", "l'Assurance Maladie", "la DGFiP"],
            "en": ["HMRC", "the IRS", "the DVLA", "Social Security", "the Tax Office"],
            "es": ["la Agencia Tributaria", "la Seguridad Social", "la DGT", "Hacienda"]},
    "service": {"all": ["Netflix", "Apple", "Microsoft", "Amazon", "PayPal", "Google", "Instagram", "Spotify", "Disney+", "iCloud"]},
    "name": {"fr": ["Julie", "Thomas", "Sophie", "Nicolas", "Camille", "Lucas", "Marie", "Hugo"],
             "en": ["Emma", "James", "Olivia", "Daniel", "Sarah", "Michael", "Laura", "David"],
             "es": ["Lucía", "Javier", "Carmen", "Pablo", "Elena", "Diego", "Marta", "Sergio"]},
    "deadline": {"fr": ["24 heures", "48 heures", "ce soir minuit", "aujourd'hui", "2 heures"],
                 "en": ["24 hours", "48 hours", "midnight tonight", "today", "2 hours"],
                 "es": ["24 horas", "48 horas", "esta noche", "hoy", "2 horas"]},
    "company": {"all": ["Dupont SAS", "Martin & Fils", "Nova Conseil", "Atlas Logistics", "Iberia Tech", "Green Energy Ltd"]},
}
WORDS = ["secure", "verify", "login", "account", "update", "support", "service", "client", "suivi", "colis",
         "pago", "cuenta", "alerte", "check", "auth", "info", "online", "portal", "help", "web"]
TLDS = [".com", ".net", ".info", ".xyz", ".top", ".online", ".site", ".live", ".click", ".fr", ".es", ".co"]
SHORT = ["bit.ly", "tinyurl.com", "cutt.ly", "t.ly", "is.gd", "rebrand.ly"]
OFFICIAL = {"Netflix": "netflix.com", "Apple": "apple.com", "Microsoft": "microsoft.com", "Amazon": "amazon.fr",
            "PayPal": "paypal.com", "Google": "google.com", "Instagram": "instagram.com", "Spotify": "spotify.com",
            "Disney+": "disneyplus.com", "iCloud": "icloud.com", "Colissimo": "laposte.fr", "La Poste": "laposte.fr",
            "Chronopost": "chronopost.fr", "DHL": "dhl.com", "UPS": "ups.com", "Correos": "correos.es", "FedEx": "fedex.com"}


def pick(rng, key, lang):
    d = F[key]
    return rng.choice(d.get(lang) or d["all"])


def lookalike(rng, brand):
    b = "".join(c for c in brand.lower() if c.isalnum()) or "secure"
    tricks = [lambda s: s.replace("l", "I", 1), lambda s: s.replace("o", "0", 1), lambda s: s.replace("m", "rn", 1),
              lambda s: s + "-" + rng.choice(WORDS), lambda s: rng.choice(WORDS) + "-" + s, lambda s: s]
    return rng.choice(tricks)(b)


def bad_url(rng, brand="secure"):
    kind = rng.random()
    if kind < 0.15:
        return "https://" + rng.choice(SHORT) + "/" + "".join(rng.choice("abcdefghijkmnpqrstuvwxyz0123456789") for _ in range(6))
    if kind < 0.25:
        return "http://" + ".".join(str(rng.randint(10, 220)) for _ in range(4)) + "/" + rng.choice(WORDS)
    host = lookalike(rng, brand) + "-" + rng.choice(WORDS) + rng.choice(TLDS)
    if rng.random() < 0.3:
        host = rng.choice(WORDS) + "." + host
    scheme = "http://" if rng.random() < 0.3 else "https://"
    return scheme + host + "/" + rng.choice(WORDS) + rng.choice(["", "?id=" + str(rng.randint(1000, 99999)), "/confirm", ".php"])


def good_url(rng, brand):
    return "https://www." + OFFICIAL.get(brand, "example.org") + "/" + rng.choice(["", "account", "fr/help", "orders", "aide", "es"])


def amount(rng, lang, low=1, high=900):
    v = rng.choice([rng.randint(low, high), round(rng.uniform(low, high), 2)])
    if lang == "en":
        return f"${v:,.2f}" if isinstance(v, float) else f"${v}"
    s = f"{v:.2f}".replace(".", ",") if isinstance(v, float) else str(v)
    return s + " €"


def fill(rng, text, lang):
    brand = pick(rng, "service", lang)
    carrier = pick(rng, "carrier", lang)
    values = {
        "bank": pick(rng, "bank", lang), "carrier": carrier, "gov": pick(rng, "gov", lang), "service": brand,
        "name": pick(rng, "name", lang), "deadline": pick(rng, "deadline", lang), "company": pick(rng, "company", lang),
        "amount": amount(rng, lang), "small": amount(rng, lang, 1, 4), "big": amount(rng, lang, 2000, 90000),
        "code": str(rng.randint(100000, 999999)), "ref": rng.choice(["FR", "ES", "UK", "CP"]) + str(rng.randint(10**8, 10**9)),
        "url": bad_url(rng, brand), "curl": bad_url(rng, carrier), "burl": bad_url(rng, "banque"),
        "gurl": good_url(rng, brand), "gcurl": good_url(rng, carrier), "date": f"{rng.randint(1, 28)}/{rng.randint(1, 12)}",
        "hour": f"{rng.randint(8, 18)}h{rng.choice(['00', '15', '30', '45'])}", "pct": str(rng.choice([12, 18, 25, 40, 300])),
    }
    out = text
    for k, v in values.items():
        out = out.replace("{" + k + "}", v)
    return out


# (category or "legit:<kind>", lang, template). Scam templates first.
T = {
"bank": {
 "fr": ["{bank} : une opération de {amount} a été bloquée. Si vous n'êtes pas à l'origine de ce paiement, annulez-le immédiatement : {burl}",
        "Alerte sécurité {bank}. Votre carte bancaire est suspendue suite à une activité inhabituelle. Réactivez-la sous {deadline} : {burl}",
        "Cher client, votre accès à l'espace {bank} expire. Mettez à jour vos informations et votre mot de passe ici : {burl}",
        "{bank} : un remboursement de {amount} vous attend. Confirmez vos coordonnées bancaires pour le recevoir : {burl}",
        "Votre conseiller {bank} : nous avons détecté une fraude sur votre compte. Communiquez-nous le code reçu par SMS pour sécuriser vos fonds.",
        "Dernier rappel : validez votre nouveau dispositif d'authentification {bank} avant {deadline}, sinon votre compte sera bloqué. {burl}",
        "Un virement de {big} est en attente de validation sur votre compte {bank}. Pour l'annuler, connectez-vous : {burl}"],
 "en": ["{bank}: a payment of {amount} has been blocked. If this wasn't you, cancel it immediately: {burl}",
        "{bank} security alert. Your card has been suspended after unusual activity. Reactivate it within {deadline}: {burl}",
        "Dear customer, your {bank} online access is expiring. Update your details and password here: {burl}",
        "{bank}: a refund of {amount} is waiting for you. Confirm your bank details to receive it: {burl}",
        "This is your {bank} fraud team: we detected suspicious activity. Reply with the code you just received by SMS to secure your funds.",
        "Final reminder: verify your new {bank} security device within {deadline} or your account will be locked. {burl}",
        "A transfer of {big} is pending on your {bank} account. To cancel it, sign in now: {burl}"],
 "es": ["{bank}: se ha bloqueado un pago de {amount}. Si no ha sido usted, anúlelo inmediatamente: {burl}",
        "Alerta de seguridad de {bank}. Su tarjeta ha sido suspendida por actividad inusual. Reactívela en {deadline}: {burl}",
        "Estimado cliente, su acceso a la banca online de {bank} caduca. Actualice sus datos y su contraseña aquí: {burl}",
        "{bank}: tiene un reembolso de {amount} pendiente. Confirme sus datos bancarios para recibirlo: {burl}",
        "Le escribe el departamento de fraude de {bank}: hemos detectado actividad sospechosa. Indíquenos el código que ha recibido por SMS.",
        "Último aviso: verifique su nuevo dispositivo de seguridad de {bank} antes de {deadline} o su cuenta quedará bloqueada. {burl}",
        "Hay una transferencia de {big} pendiente en su cuenta de {bank}. Para cancelarla, acceda ahora: {burl}"]},
"delivery": {
 "fr": ["{carrier} : votre colis {ref} est en attente. Des frais de livraison de {small} restent à régler : {curl}",
        "Votre colis n'a pas pu être livré faute d'adresse complète. Reprogrammez la livraison sous {deadline} : {curl}",
        "{carrier} : frais de douane de {small} à payer avant {deadline}, sinon le colis sera renvoyé à l'expéditeur. {curl}",
        "Bonjour, un colis à votre nom est bloqué au centre de tri. Confirmez vos informations : {curl}",
        "Avis de passage {carrier} : nous sommes passés à {hour}. Choisissez un nouveau créneau en réglant {small} : {curl}"],
 "en": ["{carrier}: your parcel {ref} is on hold. A delivery fee of {small} is due: {curl}",
        "We could not deliver your package because the address is incomplete. Reschedule within {deadline}: {curl}",
        "{carrier}: customs fees of {small} must be paid within {deadline} or the parcel will be returned. {curl}",
        "Hi, a package in your name is held at our sorting centre. Confirm your details: {curl}",
        "{carrier} missed delivery: we came by at {hour}. Pick a new slot by paying {small}: {curl}"],
 "es": ["{carrier}: su paquete {ref} está retenido. Quedan {small} de gastos de envío por pagar: {curl}",
        "No pudimos entregar su paquete porque la dirección está incompleta. Reprograme la entrega en {deadline}: {curl}",
        "{carrier}: debe pagar {small} de aduana antes de {deadline} o el paquete será devuelto. {curl}",
        "Hola, un paquete a su nombre está bloqueado en el centro de clasificación. Confirme sus datos: {curl}",
        "Aviso de {carrier}: pasamos a las {hour}. Elija una nueva franja pagando {small}: {curl}"]},
"government": {
 "fr": ["{gov} : vous bénéficiez d'un remboursement de {amount}. Complétez le formulaire avant {deadline} : {url}",
        "Avis d'imposition : une régularisation de {amount} est due. Évitez la majoration en payant sous {deadline} : {url}",
        "Votre carte Vitale expire. Commandez la nouvelle avant {deadline} pour garder vos remboursements : {url}",
        "{gov} : votre dossier est incomplet, vos aides seront suspendues. Mettez-le à jour ici : {url}",
        "Amende impayée de {small} pour excès de vitesse. Réglez-la aujourd'hui pour éviter des poursuites : {url}"],
 "en": ["{gov}: you are eligible for a tax refund of {amount}. Complete the form within {deadline}: {url}",
        "Tax notice: an outstanding balance of {amount} is due. Avoid penalties by paying within {deadline}: {url}",
        "Your health card is expiring. Order the new one within {deadline} to keep your coverage: {url}",
        "{gov}: your file is incomplete and your benefits will be suspended. Update it here: {url}",
        "Unpaid speeding fine of {small}. Pay today to avoid legal action: {url}"],
 "es": ["{gov}: tiene derecho a una devolución de {amount}. Complete el formulario antes de {deadline}: {url}",
        "Aviso tributario: tiene una deuda pendiente de {amount}. Evite el recargo pagando en {deadline}: {url}",
        "Su tarjeta sanitaria caduca. Solicite la nueva antes de {deadline} para mantener su cobertura: {url}",
        "{gov}: su expediente está incompleto y sus ayudas serán suspendidas. Actualícelo aquí: {url}",
        "Multa impagada de {small} por exceso de velocidad. Páguela hoy para evitar acciones legales: {url}"]},
"business": {
 "fr": ["Bonjour, je suis en réunion et injoignable. J'ai besoin que tu effectues un virement urgent de {big} pour un dossier confidentiel. N'en parle à personne.",
        "Suite à un changement de banque, merci d'utiliser notre nouveau RIB pour le règlement de la facture en pièce jointe. {company}",
        "Facture impayée n°{ref} de {big}. Merci de procéder au paiement aujourd'hui pour éviter la suspension de nos services.",
        "Le directeur financier demande que tu achètes des cartes cadeaux pour {amount} pour un client. Envoie-moi les codes par email, c'est urgent.",
        "Offre d'emploi : travaillez depuis chez vous et gagnez {amount} par jour. Il suffit de recevoir des virements et de les transférer."],
 "en": ["Hi, I'm in a meeting and can't talk. I need you to make an urgent wire transfer of {big} for a confidential deal. Don't tell anyone.",
        "Following a change of bank, please use our new account details to pay the attached invoice. {company}",
        "Unpaid invoice #{ref} for {big}. Please pay today to avoid suspension of our services.",
        "The CFO needs you to buy gift cards for {amount} for a client. Send me the codes by email, it's urgent.",
        "Job offer: work from home and earn {amount} a day. You just receive transfers and forward them."],
 "es": ["Hola, estoy en una reunión y no puedo hablar. Necesito que hagas una transferencia urgente de {big} para una operación confidencial. No se lo cuentes a nadie.",
        "Tras un cambio de banco, utilice nuestra nueva cuenta para pagar la factura adjunta. {company}",
        "Factura impagada n.º {ref} de {big}. Por favor, pague hoy para evitar la suspensión de nuestros servicios.",
        "El director financiero necesita que compres tarjetas regalo por {amount} para un cliente. Envíame los códigos por correo, es urgente.",
        "Oferta de empleo: trabaja desde casa y gana {amount} al día. Solo tienes que recibir transferencias y reenviarlas."]},
"investment": {
 "fr": ["Doublez votre capital en 30 jours grâce à notre robot de trading crypto. Rendement garanti de {pct} % : {url}",
        "Exclusif : investissez dans le Bitcoin avant la hausse. Nos clients ont gagné {big} ce mois-ci. Inscription : {url}",
        "Placement sans risque à {pct} % par mois, places limitées. Un conseiller vous rappelle si vous laissez votre numéro : {url}",
        "Vos gains de {big} sont disponibles. Payez les frais de déblocage de {amount} pour retirer vos fonds."],
 "en": ["Double your money in 30 days with our crypto trading bot. Guaranteed {pct}% return: {url}",
        "Exclusive: invest in Bitcoin before the surge. Our clients made {big} this month. Sign up: {url}",
        "Risk-free investment at {pct}% a month, limited spots. An advisor will call you back: {url}",
        "Your earnings of {big} are available. Pay the unlocking fee of {amount} to withdraw your funds."],
 "es": ["Duplique su dinero en 30 días con nuestro robot de trading cripto. Rentabilidad garantizada del {pct} %: {url}",
        "Exclusivo: invierta en Bitcoin antes de la subida. Nuestros clientes ganaron {big} este mes. Regístrese: {url}",
        "Inversión sin riesgo al {pct} % mensual, plazas limitadas. Un asesor le llamará: {url}",
        "Sus ganancias de {big} están disponibles. Pague la comisión de desbloqueo de {amount} para retirar sus fondos."]},
"romance": {
 "fr": ["Mon amour, je suis bloqué à l'étranger et je ne peux pas accéder à mon argent. Peux-tu m'envoyer {amount} par Western Union ? Je te rembourserai dès mon retour.",
        "Bonjour, je m'appelle {name}, militaire en mission. Ton profil m'a touché. J'ai besoin d'un petit service pour payer mon billet d'avion.",
        "Je pense à toi tout le temps. Mon fils est à l'hôpital et je dois payer {amount} aujourd'hui, tu es la seule personne en qui j'ai confiance."],
 "en": ["My love, I'm stuck abroad and can't access my money. Can you send me {amount} via Western Union? I'll pay you back when I'm home.",
        "Hello, my name is {name}, I'm a soldier on a mission. Your profile touched me. I need a small favour to pay for my plane ticket.",
        "I think about you all the time. My son is in hospital and I must pay {amount} today, you are the only person I trust."],
 "es": ["Mi amor, estoy atrapado en el extranjero y no puedo acceder a mi dinero. ¿Puedes enviarme {amount} por Western Union? Te lo devolveré al volver.",
        "Hola, me llamo {name}, soy militar en misión. Tu perfil me ha conmovido. Necesito un pequeño favor para pagar mi billete de avión.",
        "Pienso en ti todo el tiempo. Mi hijo está en el hospital y debo pagar {amount} hoy, eres la única persona en quien confío."]},
"blackmail": {
 "fr": ["J'ai piraté votre ordinateur et filmé votre écran avec votre webcam. Envoyez {big} en Bitcoin sous {deadline} ou j'envoie la vidéo à tous vos contacts.",
        "Je connais votre mot de passe. J'ai des enregistrements compromettants. Payez {amount} en crypto, sinon tout sera publié.",
        "Ceci est mon dernier avertissement. Vous avez {deadline} pour transférer {amount} sur ce portefeuille Bitcoin."],
 "en": ["I hacked your computer and recorded you through your webcam. Send {big} in Bitcoin within {deadline} or I'll send the video to all your contacts.",
        "I know your password. I have compromising recordings. Pay {amount} in crypto or everything will be published.",
        "This is my last warning. You have {deadline} to transfer {amount} to this Bitcoin wallet."],
 "es": ["He hackeado tu ordenador y te he grabado con tu webcam. Envía {big} en Bitcoin en {deadline} o mandaré el vídeo a todos tus contactos.",
        "Conozco tu contraseña. Tengo grabaciones comprometedoras. Paga {amount} en cripto o todo será publicado.",
        "Este es mi último aviso. Tienes {deadline} para transferir {amount} a esta cartera de Bitcoin."]},
"tech_support": {
 "fr": ["ALERTE : votre ordinateur est infecté par 5 virus. Appelez immédiatement le support Microsoft au 09 00 00 00 00 pour éviter la perte de vos données.",
        "Votre abonnement antivirus expire aujourd'hui. Renouvelez-le maintenant pour {amount} : {url}",
        "Support technique {service} : votre appareil a été compromis. Installez notre outil de réparation : {url}"],
 "en": ["WARNING: your computer is infected with 5 viruses. Call Microsoft support now at 1-800-000-0000 to avoid losing your data.",
        "Your antivirus subscription expires today. Renew it now for {amount}: {url}",
        "{service} technical support: your device has been compromised. Install our repair tool: {url}"],
 "es": ["ALERTA: su ordenador está infectado con 5 virus. Llame ahora al soporte de Microsoft al 900 000 000 para no perder sus datos.",
        "Su suscripción antivirus caduca hoy. Renuévela ahora por {amount}: {url}",
        "Soporte técnico de {service}: su dispositivo ha sido comprometido. Instale nuestra herramienta de reparación: {url}"]},
"prize": {
 "fr": ["Félicitations ! Vous avez gagné un iPhone 16. Réglez seulement {small} de frais d'envoi pour le recevoir : {url}",
        "Vous êtes notre 1 000 000e visiteur ! Réclamez votre carte cadeau de {amount} avant {deadline} : {url}",
        "Tirage au sort : votre numéro a été sélectionné pour un gain de {big}. Confirmez votre identité : {url}"],
 "en": ["Congratulations! You won an iPhone 16. Just pay {small} shipping to receive it: {url}",
        "You are our 1,000,000th visitor! Claim your {amount} gift card within {deadline}: {url}",
        "Prize draw: your number was selected for a {big} prize. Confirm your identity: {url}"],
 "es": ["¡Enhorabuena! Ha ganado un iPhone 16. Pague solo {small} de envío para recibirlo: {url}",
        "¡Es nuestro visitante 1.000.000! Reclame su tarjeta regalo de {amount} antes de {deadline}: {url}",
        "Sorteo: su número ha sido seleccionado para un premio de {big}. Confirme su identidad: {url}"]},
"account": {
 "fr": ["{service} : votre compte sera suspendu sous {deadline}. Confirmez votre identité et votre moyen de paiement : {url}",
        "Nous n'avons pas pu traiter votre paiement {service}. Mettez à jour votre carte pour continuer à profiter du service : {url}",
        "Connexion inhabituelle à votre compte {service} depuis un nouvel appareil. Si ce n'est pas vous, sécurisez votre compte : {url}",
        "Votre stockage {service} est plein, vos photos seront supprimées. Augmentez votre espace pour {small} : {url}",
        "Votre mot de passe {service} expire aujourd'hui. Conservez-le en cliquant ici : {url}"],
 "en": ["{service}: your account will be suspended within {deadline}. Confirm your identity and payment method: {url}",
        "We couldn't process your {service} payment. Update your card to keep enjoying the service: {url}",
        "Unusual sign-in to your {service} account from a new device. If this wasn't you, secure your account: {url}",
        "Your {service} storage is full, your photos will be deleted. Upgrade for {small}: {url}",
        "Your {service} password expires today. Keep it by clicking here: {url}"],
 "es": ["{service}: su cuenta será suspendida en {deadline}. Confirme su identidad y su forma de pago: {url}",
        "No pudimos procesar su pago de {service}. Actualice su tarjeta para seguir disfrutando del servicio: {url}",
        "Inicio de sesión inusual en su cuenta de {service} desde un nuevo dispositivo. Si no fue usted, proteja su cuenta: {url}",
        "Su almacenamiento de {service} está lleno, sus fotos se eliminarán. Amplíe su espacio por {small}: {url}",
        "Su contraseña de {service} caduca hoy. Consérvela haciendo clic aquí: {url}"]},
}

LEGIT = {
"newsletter": {
 "fr": ["La lettre de la médiathèque : découvrez le programme des ateliers de {date}, lecture, numérique et jeux. À bientôt !",
        "Notre newsletter du mois : nouveautés, conseils jardinage et recette de saison. Pour vous désabonner, rendez-vous dans vos préférences.",
        "{company} vous souhaite de bonnes fêtes et vous présente ses nouveautés de l'année."],
 "en": ["The library newsletter: discover the workshop schedule for {date}, reading, digital skills and games. See you soon!",
        "Our monthly newsletter: new arrivals, gardening tips and a seasonal recipe. To unsubscribe, visit your preferences.",
        "{company} wishes you happy holidays and presents this year's news."],
 "es": ["El boletín de la biblioteca: descubra el programa de talleres de {date}, lectura, competencias digitales y juegos. ¡Hasta pronto!",
        "Nuestro boletín del mes: novedades, consejos de jardinería y una receta de temporada. Para darse de baja, visite sus preferencias.",
        "{company} le desea felices fiestas y le presenta las novedades del año."]},
"receipt": {
 "fr": ["Merci pour votre commande n°{ref}. Montant : {amount}. Vous recevrez un email dès l'expédition. Suivez-la dans votre espace client : {gurl}",
        "Votre reçu {service} : abonnement mensuel de {small} prélevé le {date}. Aucune action n'est nécessaire.",
        "Confirmation de réservation : table pour 4 personnes le {date} à {hour}. À bientôt !"],
 "en": ["Thank you for your order #{ref}. Total: {amount}. We'll email you when it ships. Track it in your account: {gurl}",
        "Your {service} receipt: monthly subscription of {small} charged on {date}. No action needed.",
        "Booking confirmed: table for 4 on {date} at {hour}. See you soon!"],
 "es": ["Gracias por su pedido n.º {ref}. Importe: {amount}. Le avisaremos por correo cuando se envíe. Sígalo en su cuenta: {gurl}",
        "Su recibo de {service}: suscripción mensual de {small} cargada el {date}. No es necesario hacer nada.",
        "Reserva confirmada: mesa para 4 el {date} a las {hour}. ¡Hasta pronto!"]},
"appointment": {
 "fr": ["Rappel : votre rendez-vous chez le dentiste est fixé au {date} à {hour}. En cas d'empêchement, merci de prévenir le cabinet.",
        "Bonjour, la réunion de parents d'élèves aura lieu le {date} à {hour} dans la salle polyvalente.",
        "Votre contrôle technique est prévu le {date} à {hour}. Pensez à apporter la carte grise."],
 "en": ["Reminder: your dentist appointment is on {date} at {hour}. If you can't make it, please let the practice know.",
        "Hello, the parent-teacher meeting will take place on {date} at {hour} in the main hall.",
        "Your car inspection is scheduled for {date} at {hour}. Remember to bring your registration document."],
 "es": ["Recordatorio: su cita con el dentista es el {date} a las {hour}. Si no puede acudir, avise a la consulta.",
        "Hola, la reunión de padres será el {date} a las {hour} en el salón de actos.",
        "Su ITV está prevista el {date} a las {hour}. Recuerde llevar el permiso de circulación."]},
"personal": {
 "fr": ["Coucou ! On se retrouve samedi pour le déjeuner ? Dis-moi si {hour} te va. Bisous, {name}",
        "Salut, je t'envoie les photos des vacances ce soir. Tu as bien reçu le colis pour l'anniversaire de maman ?",
        "Merci encore pour hier soir, c'était super. On remet ça bientôt !"],
 "en": ["Hey! Lunch on Saturday? Let me know if {hour} works for you. Love, {name}",
        "Hi, I'll send you the holiday photos tonight. Did you get the parcel for mum's birthday?",
        "Thanks again for last night, it was great. Let's do it again soon!"],
 "es": ["¡Hola! ¿Comemos el sábado? Dime si a las {hour} te va bien. Besos, {name}",
        "Hola, te mando las fotos de las vacaciones esta noche. ¿Recibiste el paquete para el cumpleaños de mamá?",
        "Gracias otra vez por lo de anoche, fue genial. ¡Repetimos pronto!"]},
"work": {
 "fr": ["Bonjour à tous, vous trouverez ci-joint le compte rendu de la réunion de lundi. N'hésitez pas à me faire part de vos remarques. {name}",
        "Le point d'équipe est déplacé à jeudi {hour}. L'ordre du jour reste le même.",
        "Bonjour {name}, peux-tu relire la présentation avant vendredi ? Merci !"],
 "en": ["Hi all, please find attached the minutes of Monday's meeting. Feel free to send me your comments. {name}",
        "The team meeting is moved to Thursday {hour}. The agenda stays the same.",
        "Hi {name}, could you review the slides before Friday? Thanks!"],
 "es": ["Hola a todos, adjunto el acta de la reunión del lunes. No duden en enviarme sus comentarios. {name}",
        "La reunión de equipo se traslada al jueves a las {hour}. El orden del día no cambia.",
        "Hola {name}, ¿puedes revisar la presentación antes del viernes? ¡Gracias!"]},
"notification": {
 "fr": ["{service} : une nouvelle connexion a été détectée. Si c'est vous, aucune action n'est nécessaire. Sinon, ouvrez l'application officielle et changez votre mot de passe.",
        "Votre relevé de compte de {date} est disponible dans votre espace client {bank}.",
        "Votre déclaration a bien été enregistrée. Vous pouvez la consulter dans votre espace personnel sur le site officiel."],
 "en": ["{service}: a new sign-in was detected. If it was you, no action is needed. Otherwise, open the official app and change your password.",
        "Your statement for {date} is available in your {bank} online banking.",
        "Your return has been filed. You can view it in your personal space on the official website."],
 "es": ["{service}: se ha detectado un nuevo inicio de sesión. Si fue usted, no tiene que hacer nada. Si no, abra la app oficial y cambie su contraseña.",
        "Su extracto de {date} está disponible en su banca online de {bank}.",
        "Su declaración se ha registrado correctamente. Puede consultarla en su área personal de la web oficial."]},
"otp": {
 "fr": ["Votre code de vérification est {code}. Il expire dans 10 minutes. Ne le communiquez à personne, même à nos conseillers.",
        "{service} : {code} est votre code de connexion."],
 "en": ["Your verification code is {code}. It expires in 10 minutes. Never share it with anyone, not even our staff.",
        "{service}: {code} is your sign-in code."],
 "es": ["Su código de verificación es {code}. Caduca en 10 minutos. No lo comparta con nadie, ni siquiera con nuestro personal.",
        "{service}: {code} es su código de acceso."]},
"delivery_legit": {
 "fr": ["{carrier} : votre colis {ref} a été livré dans votre boîte aux lettres le {date}. Merci de votre confiance.",
        "Votre colis {ref} sera livré demain entre {hour} et 18h. Suivez-le sur {gcurl}"],
 "en": ["{carrier}: your parcel {ref} was delivered to your mailbox on {date}. Thank you.",
        "Your parcel {ref} will be delivered tomorrow between {hour} and 6pm. Track it at {gcurl}"],
 "es": ["{carrier}: su paquete {ref} se entregó en su buzón el {date}. Gracias por su confianza.",
        "Su paquete {ref} se entregará mañana entre las {hour} y las 18h. Sígalo en {gcurl}"]},
"invoice_legit": {
 "fr": ["Votre facture d'électricité de {date} est disponible : {amount}, prélevée automatiquement le 15. Retrouvez-la dans votre espace client.",
        "Bonjour, voici la facture n°{ref} pour la prestation du mois dernier, payable à 30 jours par virement sur le RIB habituel. Cordialement, {company}"],
 "en": ["Your electricity bill for {date} is available: {amount}, debited automatically on the 15th. Find it in your account.",
        "Hello, please find invoice #{ref} for last month's work, payable within 30 days to the usual account. Best regards, {company}"],
 "es": ["Su factura de luz de {date} está disponible: {amount}, se cargará automáticamente el día 15. Consúltela en su área de cliente.",
        "Hola, adjunto la factura n.º {ref} del servicio del mes pasado, pagadera a 30 días por transferencia a la cuenta habitual. Saludos, {company}"]},
"social": {
 "fr": ["{name} a commenté votre photo : « Magnifique ! »", "Vous avez 3 nouvelles notifications et 1 invitation à un évènement."],
 "en": ["{name} commented on your photo: “Beautiful!”", "You have 3 new notifications and 1 event invitation."],
 "es": ["{name} ha comentado tu foto: «¡Preciosa!»", "Tienes 3 notificaciones nuevas y 1 invitación a un evento."]},
}

HEADER = {
    "fr": ["De : {sender}\nObjet : {subject}\n\n", ""],
    "en": ["From: {sender}\nSubject: {subject}\n\n", ""],
    "es": ["De: {sender}\nAsunto: {subject}\n\n", ""],
}


def merged():
    from corpus_more import MORE_SCAMS, MORE_LEGIT, EXTRA_SCAMS
    t = {c: {l: list(v) for l, v in langs.items()} for c, langs in T.items()}
    for c, langs in list(MORE_SCAMS.items()) + list(EXTRA_SCAMS.items()):
        for l, v in langs.items():
            t[c][l] = t[c][l] + v
    g = {k: {l: list(v) for l, v in langs.items()} for k, langs in LEGIT.items()}
    for k, langs in MORE_LEGIT.items():
        for l, v in langs.items():
            g[k][l] = g[k][l] + v
    return t, g


def templates():
    """Every template: (id, label, category, lang, text)."""
    T, LEGIT = merged()
    out = []
    for cat, langs in T.items():
        for lang, texts in langs.items():
            for i, t in enumerate(texts):
                out.append((f"{cat}/{lang}/{i}", 1, cat, lang, t))
    for kind, langs in LEGIT.items():
        for lang, texts in langs.items():
            for i, t in enumerate(texts):
                out.append((f"legit-{kind}/{lang}/{i}", 0, "legit", lang, t))
    return out


def render(rng, label, lang, text):
    body = fill(rng, text, lang)
    if rng.random() < 0.45:
        sender = (lookalike(rng, "service") + "@" + rng.choice(WORDS) + rng.choice(TLDS)) if label else \
                 (pick(rng, "name", lang).lower() + "@" + rng.choice(["gmail.com", "orange.fr", "outlook.com", "example.org"]))
        subject = body.split(".")[0][:60]
        head = rng.choice(HEADER[lang]).replace("{sender}", sender).replace("{subject}", subject)
        body = head + body
    if rng.random() < 0.15:
        body = body.upper() if label and rng.random() < 0.3 else body
    return body


def generate(seed=7, per_template=40):
    rng = random.Random(seed)
    rows = []
    for tid, label, cat, lang, text in templates():
        n = per_template if label else int(per_template * 1.3)
        for _ in range(n):
            rows.append((tid, label, cat, lang, render(rng, label, lang, text)))
    return rows
