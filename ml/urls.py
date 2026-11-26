"""The links of the link model: the URLs of phishing-dataset (urls.json) and generated links
like those of real emails, official ones (receipts, tracking, newsletters) and fake ones."""
import json, random

from corpus import WORDS, TLDS, SHORT

# The official domains listed in MailZenKit (Brands.swift), and other common senders of
# legitimate emails.
OFFICIAL = ["paypal.com", "amazon.com", "amazon.fr", "amazon.es", "amazon.de", "amazon.co.uk", "apple.com", "icloud.com",
            "microsoft.com", "live.com", "outlook.com", "office.com", "google.com", "google.fr", "google.es", "gmail.com",
            "youtube.com", "netflix.com", "facebook.com", "meta.com", "instagram.com", "whatsapp.com", "dhl.com", "dhl.de",
            "dhl.fr", "ups.com", "fedex.com", "chronopost.fr", "laposte.fr", "colissimo.fr", "laposte.net", "correos.es",
            "ameli.fr", "impots.gouv.fr", "caf.fr", "service-public.fr", "edf.fr", "orange.fr", "sfr.fr", "free.fr",
            "agenciatributaria.gob.es", "irs.gov", "linkedin.com", "spotify.com", "disneyplus.com", "leboncoin.fr",
            "sncf-connect.com", "doctolib.fr", "fnac.com", "cdiscount.com", "zalando.fr", "ikea.com", "decathlon.fr",
            "booking.com", "airbnb.fr", "uber.com", "blablacar.fr", "github.com", "dropbox.com", "zoom.us", "slack.com",
            "notion.so", "canva.com", "elcorteingles.es", "renfe.com", "mercadona.es", "bbva.es", "santander.es",
            "caixabank.es", "credit-agricole.fr", "societegenerale.fr", "bnpparibas.com", "lcl.fr", "boursorama.com",
            "hsbc.co.uk", "barclays.co.uk", "chase.com", "gov.uk", "nhs.uk", "royalmail.com", "evri.com", "seur.com",
            "lemonde.fr", "elpais.com", "bbc.co.uk", "wikipedia.org", "mozilla.org", "francetravail.fr", "ants.gouv.fr"]
SUBS = ["", "", "", "www.", "account.", "mail.", "help.", "support.", "click.", "email.", "news.", "m.", "fr.", "es."]
PATHS = ["", "/", "/account", "/orders", "/gp/your-account/order-history", "/fr/aide", "/es/ayuda", "/help/article/12",
         "/track?id={n}", "/suivi/{n}", "/en/support", "/settings/security", "/legal/privacy", "/unsubscribe?u={h}",
         "/newsletter/{n}", "/watch?v={h}", "/receipt/{h}", "/fr/particulier", "/mon-espace", "/login", "/signin",
         "/products/{n}", "/blog/2026/{n}-news", "/invoice/{n}.pdf", "/r/{h}", "/ls/click?upn={h}"]
LOOK = ["secure", "verify", "login", "account", "update", "support", "service", "client", "suivi", "colis",
        "pago", "cuenta", "alerte", "check", "auth", "info", "online", "portal", "help", "web", "billing", "refund",
        "track", "delivery", "parcel", "tax", "remboursement", "confirm", "unlock", "wallet"]


def rand(rng, alphabet, n):
    return "".join(rng.choice(alphabet) for _ in range(n))


def good(rng):
    d = rng.choice(OFFICIAL)
    if "." not in d:
        d += rng.choice([".com", ".fr"])
    path = rng.choice(PATHS).replace("{n}", str(rng.randint(10, 999999))).replace("{h}", rand(rng, "abcdef0123456789", rng.randint(6, 30)))
    return rng.choice(["https://", "https://", "http://", ""]) + rng.choice(SUBS) + d + path


SMALL = ["boulangerie", "garage", "mairie", "pharmacie", "cabinet", "atelier", "jardin", "maison", "ecole", "club",
         "asso", "restaurant", "cafe", "hotel", "camping", "fleurs", "photo", "musique", "theatre", "cinema", "bio",
         "ferme", "vins", "immo", "avocat", "dentiste", "kine", "yoga", "danse", "sport", "velo", "auto", "plomberie",
         "electricite", "menuiserie", "librairie", "bakery", "studio", "design", "family", "church", "school", "farm",
         "panaderia", "taller", "tienda", "casa", "clinica", "escuela", "abogados", "peluqueria", "bodega", "lyon",
         "paris", "nantes", "lille", "bordeaux", "toulouse", "madrid", "sevilla", "valencia", "london", "bristol",
         "durand", "martin", "garcia", "lopez", "smith", "bernard", "petit", "moreau", "dubois", "ruiz"]


def small(rng):
    words = rng.sample(SMALL, rng.choice([1, 2, 2, 3]))
    host = rng.choice(["-", ""]).join(words) + rng.choice([".fr", ".fr", ".com", ".es", ".org", ".net", ".eu", ".co.uk", ".be", ".ch"])
    path = rng.choice(["", "", "/", "/contact", "/actualites", "/horaires", "/menu", "/fr/accueil", "/blog/{n}", "/galerie",
                       "/es/contacto", "/about", "/agenda/2026", "/inscription", "/tarifs"]).replace("{n}", str(rng.randint(1, 300)))
    return rng.choice(["https://", "https://www.", "http://", "www.", ""]) + host + path


def bad(rng):
    brand = rng.choice(["paypal", "amazon", "apple", "netflix", "microsoft", "ameli", "impots", "laposte", "colissimo",
                        "chronopost", "dhl", "correos", "bbva", "santander", "caixa", "hacienda", "irs", "hmrc", "chase",
                        "office365", "outlook", "icloud", "orange", "sfr", "caf", "antai", "ups", "fedex", "dpd", "vinted"])
    tricks = [lambda s: s.replace("l", "1", 1), lambda s: s.replace("o", "0", 1), lambda s: s.replace("m", "rn", 1),
              lambda s: s.replace("a", "4", 1), lambda s: s + rng.choice(["-", ""]) + rng.choice(LOOK),
              lambda s: rng.choice(LOOK) + rng.choice(["-", ""]) + s, lambda s: s + "-" + rng.choice(LOOK) + "-" + rng.choice(LOOK)]
    kind = rng.random()
    if kind < 0.1:
        return "https://" + rng.choice(SHORT) + "/" + rand(rng, "abcdefghijkmnpqrstuvwxyzABCDEFGH0123456789", 6)
    if kind < 0.18:
        return "http://" + ".".join(str(rng.randint(10, 250)) for _ in range(4)) + rng.choice(["", ":8080"]) + "/" + rng.choice(LOOK) + rng.choice(["", ".php", "/index.html"])
    host = rng.choice(tricks)(brand) + rng.choice(TLDS + [".shop", ".icu", ".buzz", ".support", ".help", ".app", ".cfd", ".sbs"])
    if rng.random() < 0.35:
        host = rng.choice([brand + ".", "www.", rng.choice(LOOK) + ".", brand + ".com."]) + host
    if rng.random() < 0.15:
        host = rand(rng, "abcdefghijklmnopqrstuvwxyz0123456789", rng.randint(8, 14)) + "." + rng.choice(["web.app", "pages.dev", "netlify.app", "vercel.app", "firebaseapp.com", "azurewebsites.net", "github.io", "weebly.com", "wixsite.com"])
    path = rng.choice(["", "/" + rng.choice(LOOK), "/" + rng.choice(LOOK) + "/" + rng.choice(LOOK) + ".php", "/?id=" + str(rng.randint(1000, 99999)),
                       "/" + brand + "/" + rng.choice(LOOK) + "/index.html", "/" + rand(rng, "abcdef0123456789", 12) + "/" + rng.choice(LOOK)])
    return rng.choice(["https://", "https://", "http://", ""]) + host + path


def generate(seed=5, n=20000):
    rng = random.Random(seed)
    return [(good(rng), 0) for _ in range(n)] + [(small(rng), 0) for _ in range(n // 2)] + [(bad(rng), 1) for _ in range(n)]


def load(path):
    rows = json.load(open(path))
    seen, out = set(), []
    for r in rows:
        u = r["text"].strip()
        if u and u not in seen:
            seen.add(u); out.append((u, int(r["label"])))
    return out
