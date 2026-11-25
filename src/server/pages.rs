//! Every page of the site, written with active (through Paquets' prelude).

use paquets::prelude::*;

use super::Site;
use crate::data::*;
use crate::i18n::{Lang, T3, number};
use crate::icons::{icon, logo};
use crate::islands;
use crate::routes::{Page as PageKind, Route, base, link};

/// What a request needs to render a page.
pub struct Ctx<'a> {
    pub site: &'a Site,
    pub route: Route,
    /// Absolute origin of the site (with the base path), for canonical and Open Graph
    /// URLs, e.g. `https://maxlestage.github.io/MAILZEN`.
    pub origin: String,
}

impl Ctx<'_> {
    fn lang(&self) -> Lang {
        self.route.lang
    }

    /// The text of the page's language.
    fn t(&self, text: &T3) -> &'static str {
        self.route.lang.t(text)
    }

    /// A section of the home page of the current language.
    fn home(&self, anchor: &str) -> String {
        let home = Route::new(self.lang(), PageKind::Home).href();
        if anchor.is_empty() {
            home
        } else {
            format!("{home}#{anchor}")
        }
    }

    fn page(&self, page: PageKind) -> String {
        Route::new(self.lang(), page).href()
    }
}

// ----- Small pieces -------------------------------------------------------------------

/// A button-like link that leans towards the pointer.
fn btn(href: impl Into<String>, class: &str) -> Element {
    a().class("btn")
        .class(class.to_owned())
        .href(href.into())
        .attr("data-magnetic", "")
}

fn external(link: Element) -> Element {
    link.attr("target", "_blank").attr("rel", "noopener")
}

/// Each word rises in turn when the element is revealed.
fn words(text: &str) -> Element {
    let mut root = span().class("words");
    for (i, word) in text.split(' ').enumerate() {
        if i > 0 {
            root = root.text(" ");
        }
        root = root.child(
            span()
                .class("w")
                .style(format!("--i:{i}"))
                .child(span().text(word.to_owned())),
        );
    }
    root
}

/// Each letter rises in turn (the hero title).
fn letters(text: &str, offset: usize) -> Element {
    let mut root = span()
        .class("letters")
        .attr("aria-label", text.to_owned())
        .attr("role", "text");
    let mut index = offset;
    for (w, word) in text.split(' ').enumerate() {
        if w > 0 {
            root = root.text(" ");
            index += 1;
        }
        let mut group = span().class("letters__word").attr("aria-hidden", "true");
        for c in word.chars() {
            group = group.child(
                span()
                    .class("ch")
                    .style(format!("--i:{index}"))
                    .text(c.to_string()),
            );
            index += 1;
        }
        root = root.child(group);
    }
    root
}

/// The heading of a section: a number, a label, a title and a lead.
fn head(num: &str, label: &str, title: &str, lead: Option<&str>) -> Element {
    let mut header = header()
        .class("head")
        .attr("data-reveal", "")
        .child(
            p().class("eyebrow")
                .child(span().class("eyebrow__num").text(num.to_owned()))
                .child(span().text(label.to_owned())),
        )
        .child(h2().class("head__title").child(words(title)));
    if let Some(lead) = lead {
        header = header.child(p().class("head__lead").text(lead.to_owned()));
    }
    header
}

fn section_(id: &str, class: &str) -> Element {
    section()
        .id(id.to_owned())
        .class("section")
        .class(class.to_owned())
}

fn container() -> Element {
    div().class("container")
}

fn chip(text: &str) -> Element {
    span().class("chip").text(text.to_owned())
}

/// A list of chips that appear one after the other.
fn chips(ctx: &Ctx<'_>, items: &[T3], class: &str) -> Element {
    div()
        .class("chips")
        .class(class.to_owned())
        .attr("data-reveal", "")
        .children(
            items
                .iter()
                .enumerate()
                .map(|(i, t)| chip(ctx.t(t)).style(format!("--i:{i}"))),
        )
}

/// A list of checked items.
fn checks(ctx: &Ctx<'_>, items: &[T3]) -> Element {
    ul().class("checks")
        .attr("data-reveal", "")
        .children(items.iter().enumerate().map(|(i, t)| {
            li().style(format!("--i:{i}"))
                .child(icon("check"))
                .child(span().text(ctx.t(t)))
        }))
}

fn icon_box(name: &str) -> Element {
    span().class("icon-box").child(icon(name))
}

fn lang_switch(ctx: &Ctx<'_>) -> Element {
    let index = Lang::ALL.iter().position(|&l| l == ctx.lang()).unwrap_or(0);
    div()
        .class("lang")
        .attr("role", "group")
        .attr(
            "aria-label",
            ctx.t(&[
                "Choisir la langue",
                "Choose the language",
                "Elegir el idioma",
            ]),
        )
        .style(format!("--idx:{index}"))
        .child(span().class("lang__pill").attr("aria-hidden", "true"))
        .children(Lang::ALL.map(|l| {
            let route = if ctx.route.page == PageKind::NotFound {
                Route::new(l, PageKind::Home)
            } else {
                ctx.route.with_lang(l)
            };
            let link = a()
                .class("lang__btn")
                .href(route.href())
                .attr("hreflang", l.code())
                .attr("lang", l.code())
                .attr("title", l.name())
                .text(l.code().to_uppercase());
            if l == ctx.lang() {
                link.class("is-active").attr("aria-current", "true")
            } else {
                link
            }
        }))
}

// ----- Layout ---------------------------------------------------------------------------

const META_TITLE: T3 = [
    "MailZen — Le gardien intelligent de vos emails",
    "MailZen — The smart guardian of your emails",
    "MailZen — El guardián inteligente de tus correos",
];

const META_DESCRIPTION: T3 = [
    "Avant de cliquer, vérifiez. MailZen analyse les emails, liens, pièces jointes, captures et QR codes, explique les risques et vous accompagne face aux arnaques.",
    "Before you click, check. MailZen analyzes emails, links, attachments, screenshots and QR codes, explains the risks and helps you through scams.",
    "Antes de hacer clic, verifica. MailZen analiza correos, enlaces, adjuntos, capturas y códigos QR, explica los riesgos y te acompaña frente a las estafas.",
];

/// The page around `content`: head tags, navigation, footer, cursor, preloader.
fn layout(ctx: &Ctx<'_>, title: &str, description: &str, content: Element, intro: bool) -> Page {
    let lang = ctx.lang();
    let route = ctx.route;
    let mut seo = Seo::new()
        .site_name(BRAND)
        .base_url(ctx.origin.clone())
        .image("/assets/og-image.png")
        .meta_property("og:image:width", "1200")
        .meta_property("og:image:height", "630")
        .meta_property("og:image:alt", ctx.t(&META_TITLE))
        .og_type("website")
        .locale(lang.locale())
        .meta_name("author", AUTHOR);
    if route.page == PageKind::NotFound {
        seo = seo.noindex(true);
    } else {
        seo = seo.canonical(route.path());
        for l in Lang::ALL {
            seo = seo.alternate(l.code(), route.with_lang(l).path());
        }
        seo = seo.alternate("x-default", route.with_lang(Lang::Fr).path());
    }
    let head = format!(
        r##"<meta name="color-scheme" content="dark"/><link rel="icon" href="{}" type="image/svg+xml"/><link rel="apple-touch-icon" href="{}"/><meta name="apple-mobile-web-app-capable" content="yes"/><meta name="apple-mobile-web-app-status-bar-style" content="black-translucent"/><meta name="apple-mobile-web-app-title" content="MailZen"/><meta name="format-detection" content="telephone=no"/>"##,
        link("/assets/logo.svg"),
        link("/icons/apple-touch-icon.png"),
    );
    let mut root = div()
        .class("site")
        .attr("data-base", base())
        .child(a().class("skip").href("#main").text(ctx.t(&[
            "Aller au contenu",
            "Skip to content",
            "Ir al contenido",
        ])))
        .child(div().class("progress").attr("aria-hidden", "true"))
        .child(
            div()
                .class("aurora")
                .attr("aria-hidden", "true")
                .child(span().class("aurora__a"))
                .child(span().class("aurora__b"))
                .child(span().class("aurora__c")),
        );
    if intro {
        root = root.class("site--intro").child(loader(ctx));
    }
    root = root
        .child(cursor())
        .child(navbar(ctx))
        .child(menu(ctx))
        .child(content.id("main"))
        .child(site_footer(ctx));
    Page::new(title)
        .lang(lang.code())
        .description(description)
        .seo(seo)
        .plain()
        .stylesheet(format!("{}?v={}", link("/site.css"), ctx.site.css_version))
        .head(head)
        .view_transitions()
        .prefetch(Prefetch::Hover)
        .body(root)
}

fn loader(ctx: &Ctx<'_>) -> Element {
    div()
        .class("loader")
        .attr("aria-hidden", "true")
        .child(
            div()
                .class("loader__inner")
                .child(
                    div()
                        .class("loader__mark")
                        .child(span().class("loader__ring"))
                        .child(span().class("loader__ring loader__ring--2"))
                        .child(logo("loader"))
                        .child(span().class("loader__scan")),
                )
                .child(
                    div().class("loader__word").children(
                        "MAILZEN"
                            .chars()
                            .enumerate()
                            .map(|(i, c)| span().style(format!("--i:{i}")).text(c.to_string())),
                    ),
                )
                .child(div().class("loader__bar").child(span()))
                .child(
                    div()
                        .class("loader__label")
                        .text(ctx.t(&[
                            "Analyse de sécurité",
                            "Security analysis",
                            "Análisis de seguridad",
                        ]))
                        .child(
                            span()
                                .class("loader__dots")
                                .child(i().text("."))
                                .child(i().text("."))
                                .child(i().text(".")),
                        ),
                )
                .child(div().class("loader__percent").text("0%")),
        )
        .child(div().class("loader__curtain"))
}

fn cursor() -> Element {
    div()
        .class("cursor")
        .attr("aria-hidden", "true")
        .child(div().class("cursor__dot"))
        .child(div().class("cursor__ring").child(span()))
}

/// The sections of the navigation: (anchor, label).
const NAV: [(&str, T3); 7] = [
    ("modules", ["Modules", "Modules", "Módulos"]),
    ("demo", ["Démo", "Demo", "Demo"]),
    ("report", ["Rapport", "Report", "Informe"]),
    ("zenai", ["ZenAI", "ZenAI", "ZenAI"]),
    ("sos", ["SOS Cyber", "SOS Cyber", "SOS Cyber"]),
    ("privacy", ["Confidentialité", "Privacy", "Privacidad"]),
    ("pricing", ["Tarifs", "Pricing", "Precios"]),
];

fn brand(ctx: &Ctx<'_>, id: &str) -> Element {
    a().class("brand")
        .href(ctx.home(""))
        .attr("aria-label", "MailZen")
        .child(logo(id))
        .child(
            span()
                .class("brand__name")
                .text("Mail")
                .child(strong().text("Zen")),
        )
}

fn navbar(ctx: &Ctx<'_>) -> Element {
    header().id("nav").class("nav").child(
        div()
            .class("nav__inner")
            .child(brand(ctx, "nav"))
            .child(
                nav()
                    .class("nav__links")
                    .attr("aria-label", ctx.t(&["Sections", "Sections", "Secciones"]))
                    .children(NAV.iter().map(|(id, label)| {
                        a().href(ctx.home(id)).attr("data-spy", *id).child(
                            span()
                                .class("roll")
                                .attr("data-text", ctx.t(label))
                                .child(span().text(ctx.t(label))),
                        )
                    })),
            )
            .child(
                div()
                    .class("nav__end")
                    .child(lang_switch(ctx))
                    .child(
                        a().class("nav__mail")
                            .href(ctx.home("connect"))
                            .attr(
                                "aria-label",
                                ctx.t(&[
                                    "Connecter ma boîte mail",
                                    "Connect my mailbox",
                                    "Conectar mi buzón",
                                ]),
                            )
                            .attr("data-cursor", ctx.t(&["Mail", "Mail", "Correo"]))
                            .child(icon("mail"))
                            .child(span().class("nav__mail-label").text(ctx.t(&[
                                "Connexion",
                                "Sign in",
                                "Conectar",
                            ]))),
                    )
                    .child(
                        btn(ctx.home("demo"), "btn--primary btn--sm nav__cta")
                            .child(icon("radar"))
                            .child(span().text(ctx.t(&["Essayer", "Try it", "Probar"]))),
                    )
                    .child(
                        button()
                            .class("burger")
                            .attr("type", "button")
                            .attr("data-toggle-menu", "")
                            .attr("aria-expanded", "false")
                            .attr("aria-controls", "menu")
                            .attr("aria-label", ctx.t(&["Menu", "Menu", "Menú"]))
                            .child(span())
                            .child(span())
                            .child(span()),
                    ),
            ),
    )
}

fn menu(ctx: &Ctx<'_>) -> Element {
    div()
        .id("menu")
        .class("menu")
        .child(div().class("menu__scrim"))
        .child(
            nav()
                .class("menu__panel")
                .attr("aria-label", ctx.t(&["Menu", "Menu", "Menú"]))
                .children(NAV.iter().enumerate().map(|(i, (id, label))| {
                    a().href(ctx.home(id))
                        .style(format!("--i:{i}"))
                        .child(span().class("menu__num").text(format!("0{}", i + 1)))
                        .child(span().text(ctx.t(label)))
                        .child(icon("arrow"))
                }))
                .child(
                    div().class("menu__foot").child(lang_switch(ctx)).child(
                        btn(ctx.home("demo"), "btn--primary")
                            .child(icon("radar"))
                            .child(span().text(ctx.t(&[
                                "Essayer la démo",
                                "Try the demo",
                                "Probar la demo",
                            ]))),
                    ),
                ),
        )
}

// ----- Footer ---------------------------------------------------------------------------

/// A column of the footer: a title and its links (label, href, external).
fn footer_col(title: &str, links: Vec<(&str, String, bool)>) -> Element {
    div()
        .class("footer__col")
        .child(h3().class("footer__title").text(title.to_owned()))
        .child(ul().children(links.into_iter().map(|(label, href, ext)| {
            let link = a().href(href).child(
                span()
                    .class("roll")
                    .attr("data-text", label.to_owned())
                    .child(span().text(label.to_owned())),
            );
            li().child(if ext {
                external(link.child(icon("external")))
            } else {
                link
            })
        })))
}

fn store_badges(ctx: &Ctx<'_>) -> Element {
    let soon = ctx.t(&["Bientôt sur", "Coming soon on", "Próximamente en"]);
    div()
        .class("stores")
        .child(
            span()
                .class("store")
                .attr("data-tilt", "10")
                .child(icon("apple"))
                .child(
                    span()
                        .class("store__text")
                        .child(small().text(soon))
                        .child(strong().text("App Store")),
                ),
        )
        .child(
            span()
                .class("store")
                .attr("data-tilt", "10")
                .child(icon("android"))
                .child(
                    span()
                        .class("store__text")
                        .child(small().text(soon))
                        .child(strong().text("Google Play")),
                ),
        )
}

fn site_footer(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    let h = |a: &str| ctx.home(a);
    let product = footer_col(
        t(&["Protection", "Protection", "Protección"]),
        MODULES.iter().map(|m| (m.name, h(m.id), false)).collect(),
    );
    let discover = footer_col(
        t(&["Découvrir", "Discover", "Descubrir"]),
        vec![
            (
                t(&["Comment ça marche", "How it works", "Cómo funciona"]),
                h("how"),
                false,
            ),
            (
                t(&["Démo interactive", "Interactive demo", "Demo interactiva"]),
                h("demo"),
                false,
            ),
            (
                t(&["Le rapport", "The report", "El informe"]),
                h("report"),
                false,
            ),
            (
                t(&["Manipulation", "Manipulation", "Manipulación"]),
                h("manipulation"),
                false,
            ),
            (t(&["Arnaques", "Scams", "Estafas"]), h("scams"), false),
            (t(&["ZenLearn", "ZenLearn", "ZenLearn"]), h("learn"), false),
            (t(&["Tarifs", "Pricing", "Precios"]), h("pricing"), false),
            (t(&["FAQ", "FAQ", "FAQ"]), h("faq"), false),
        ],
    );
    let trust = footer_col(
        t(&["Confiance", "Trust", "Confianza"]),
        vec![
            (
                t(&[
                    "Confidentialité de l’app",
                    "App privacy",
                    "Privacidad de la app",
                ]),
                h("privacy"),
                false,
            ),
            (
                t(&["Architecture", "Architecture", "Arquitectura"]),
                h("architecture"),
                false,
            ),
            (
                t(&["iOS et Android", "iOS and Android", "iOS y Android"]),
                h("platforms"),
                false,
            ),
            (
                t(&["Feuille de route", "Roadmap", "Hoja de ruta"]),
                h("roadmap"),
                false,
            ),
            (
                t(&["Écosystème", "Ecosystem", "Ecosistema"]),
                h("ecosystem"),
                false,
            ),
            (
                t(&["Tableau de bord", "Dashboard", "Panel"]),
                h("radar"),
                false,
            ),
        ],
    );
    let help = footer_col(
        t(&[
            "Aide aux victimes (France)",
            "Victim support (France)",
            "Ayuda a víctimas (Francia)",
        ]),
        vec![
            (
                "Cybermalveillance.gouv.fr",
                "https://www.cybermalveillance.gouv.fr/".into(),
                true,
            ),
            ("17Cyber", "https://www.17cyber.gouv.fr/".into(), true),
            (
                "Pharos",
                "https://www.internet-signalement.gouv.fr/".into(),
                true,
            ),
            ("Signal Spam", "https://www.signal-spam.fr/".into(), true),
            (
                t(&[
                    "SMS frauduleux : 33700",
                    "Scam SMS: 33700",
                    "SMS fraudulento: 33700",
                ]),
                "https://www.33700.fr/".into(),
                true,
            ),
        ],
    );
    let legal = footer_col(
        t(&["Légal", "Legal", "Legal"]),
        vec![
            (
                t(&["Mentions légales", "Legal notice", "Aviso legal"]),
                ctx.page(PageKind::Legal),
                false,
            ),
            (
                t(&[
                    "Confidentialité du site",
                    "Site privacy",
                    "Privacidad del sitio",
                ]),
                ctx.page(PageKind::Privacy),
                false,
            ),
            (
                t(&["Licence", "License", "Licencia"]),
                format!("{REPO}/blob/master/LICENSE"),
                true,
            ),
            (
                t(&["Code source", "Source code", "Código fuente"]),
                REPO.into(),
                true,
            ),
        ],
    );
    let promises: [(&str, T3); 4] = [
        (
            "lock",
            [
                "Zéro cookie, zéro traceur",
                "No cookies, no trackers",
                "Sin cookies ni rastreadores",
            ],
        ),
        (
            "install",
            [
                "Installable (PWA), hors ligne",
                "Installable (PWA), offline",
                "Instalable (PWA), sin conexión",
            ],
        ),
        (
            "cog",
            [
                "100 % Rust · Paquets · WebAssembly",
                "100% Rust · Paquets · WebAssembly",
                "100 % Rust · Paquets · WebAssembly",
            ],
        ),
        (
            "globe",
            [
                "Français · English · Español",
                "Français · English · Español",
                "Français · English · Español",
            ],
        ),
    ];
    footer()
        .class("footer")
        .child(div().class("footer__beam").attr("aria-hidden", "true").child(span().class("footer__line")).child(span().class("footer__comet")).child(span().class("footer__halo")))
        .child(
            container()
                .child(
                    div()
                        .class("footer__top")
                        .attr("data-reveal", "")
                        .child(
                            div()
                                .class("footer__brand")
                                .child(brand(ctx, "footer"))
                                .child(p().class("footer__tagline").text(t(&[
                                    "Avant de cliquer, vérifiez.",
                                    "Before you click, check.",
                                    "Antes de hacer clic, verifica.",
                                ])))
                                .child(p().class("footer__mission").text(t(&[
                                    "Notre mission : aider chacun à identifier les dangers numériques avant qu’ils ne deviennent des problèmes.",
                                    "Our mission: help everyone spot digital dangers before they become problems.",
                                    "Nuestra misión: ayudar a todos a identificar los peligros digitales antes de que se conviertan en problemas.",
                                ])))
                                .child(store_badges(ctx)),
                        )
                        .child(
                            div()
                                .class("footer__sos")
                                .attr("data-spot", "")
                                .child(icon_box("lifebuoy"))
                                .child(strong().text(t(&[
                                    "Déjà cliqué ?",
                                    "Already clicked?",
                                    "¿Ya hiciste clic?",
                                ])))
                                .child(p().text(t(&[
                                    "Pas de panique. SOS Cyber vous guide pas à pas, sans jugement.",
                                    "Don’t panic. SOS Cyber guides you step by step, without judgment.",
                                    "Que no cunda el pánico. SOS Cyber te guía paso a paso, sin juzgar.",
                                ])))
                                .child(
                                    btn(h("sos"), "btn--danger btn--sm")
                                        .child(span().text(t(&["Ouvrir SOS Cyber", "Open SOS Cyber", "Abrir SOS Cyber"])))
                                        .child(icon("arrow")),
                                ),
                        ),
                )
                .child(
                    div()
                        .class("footer__cols")
                        .attr("data-reveal", "")
                        .child(product)
                        .child(discover)
                        .child(trust)
                        .child(help)
                        .child(legal),
                )
                .child(
                    ul().class("footer__promises").attr("data-reveal", "").children(
                        promises.iter().enumerate().map(|(i, (ic, text))| {
                            li().style(format!("--i:{i}")).child(icon(ic)).child(span().text(t(text)))
                        }),
                    ),
                )
                .child(
                    div()
                        .class("footer__word")
                        .attr("aria-hidden", "true")
                        .text("MailZen"),
                )
                .child(
                    div()
                        .class("footer__bottom")
                        .child(
                            div()
                                .class("footer__legal")
                                .child(p().text(format!(
                                    "© 2026 {BRAND} · {}",
                                    t(&["Tous droits réservés.", "All rights reserved.", "Todos los derechos reservados."])
                                )))
                                .child(p().class("footer__note").text(t(&[
                                    "MailZen est en cours de développement : les écrans, chiffres et prix présentés sont illustratifs. Les marques citées appartiennent à leurs propriétaires ; les exemples utilisent des domaines fictifs (.example).",
                                    "MailZen is in development: the screens, figures and prices shown are illustrative. The brands mentioned belong to their owners; the examples use fictional domains (.example).",
                                    "MailZen está en desarrollo: las pantallas, cifras y precios mostrados son ilustrativos. Las marcas citadas pertenecen a sus propietarios; los ejemplos usan dominios ficticios (.example).",
                                ]))),
                        )
                        .child(
                            div()
                                .class("footer__actions")
                                .child(lang_switch(ctx))
                                .child(island("top", ctx.lang().code(), islands::top)),
                        ),
                ),
        )
}

// ----- Home -------------------------------------------------------------------------------

pub fn home(ctx: &Ctx<'_>) -> Page {
    let content = main()
        .class("home")
        .child(hero(ctx))
        .child(marquee(ctx))
        .child(modules(ctx))
        .child(how(ctx))
        .child(demo(ctx))
        .child(connect(ctx))
        .child(report(ctx))
        .child(sender(ctx))
        .child(links(ctx))
        .child(files(ctx))
        .child(screens(ctx))
        .child(zenai(ctx))
        .child(manipulation(ctx))
        .child(scams(ctx))
        .child(sos(ctx))
        .child(ecosystem(ctx))
        .child(radar(ctx))
        .child(learn(ctx))
        .child(privacy(ctx))
        .child(architecture(ctx))
        .child(platforms(ctx))
        .child(roadmap(ctx))
        .child(pricing(ctx))
        .child(faq(ctx))
        .child(cta(ctx));
    let page = layout(
        ctx,
        ctx.t(&META_TITLE),
        ctx.t(&META_DESCRIPTION),
        content,
        true,
    );
    let json_ld = format!(
        r#"<script type="application/ld+json">{{"@context":"https://schema.org","@type":"SoftwareApplication","name":"MailZen","applicationCategory":"SecurityApplication","operatingSystem":"iOS, Android","description":{},"inLanguage":"{}","offers":{{"@type":"Offer","price":"0","priceCurrency":"EUR"}}}}</script>"#,
        json_string(ctx.t(&META_DESCRIPTION)),
        ctx.lang().code()
    );
    page.head(json_ld)
}

fn json_string(s: &str) -> String {
    let mut out = String::from("\"");
    for c in s.chars() {
        match c {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '<' => out.push_str("\\u003c"),
            '\n' => out.push_str("\\n"),
            c => out.push(c),
        }
    }
    out.push('"');
    out
}

fn hero(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    let typed: T3 = [
        "un email|un lien|une pièce jointe|un QR code|une capture|un SMS",
        "an email|a link|an attachment|a QR code|a screenshot|a text message",
        "un correo|un enlace|un adjunto|un código QR|una captura|un SMS",
    ];
    let first = t(&typed).split('|').next().unwrap_or("");
    let badges: [(&str, &str); 4] = [
        ("apple", "iOS"),
        ("android", "Android"),
        ("lock", "Privacy first"),
        (
            "spark",
            t(&[
                "Intelligence artificielle",
                "Artificial intelligence",
                "Inteligencia artificial",
            ]),
        ),
    ];
    let floats: [(&str, &str, T3, T3); 3] = [
        (
            "danger",
            "alert",
            [
                "Phishing détecté",
                "Phishing detected",
                "Phishing detectado",
            ],
            [
                "92/100 · Danger élevé",
                "92/100 · High danger",
                "92/100 · Peligro elevado",
            ],
        ),
        (
            "safe",
            "check",
            ["Lien vérifié", "Link verified", "Enlace verificado"],
            ["Domaine officiel", "Official domain", "Dominio oficial"],
        ),
        (
            "caution",
            "file",
            ["Facture_2026.pdf", "Invoice_2026.pdf", "Factura_2026.pdf"],
            [
                "Liens externes suspects",
                "Suspicious external links",
                "Enlaces externos sospechosos",
            ],
        ),
    ];
    section()
        .id("top")
        .class("hero")
        .attr("tabindex", "-1")
        .child(
            div()
                .class("hero__bg")
                .attr("aria-hidden", "true")
                .child(span().class("hero__grid"))
                .child(span().class("blob blob--1").attr("data-speed", "0.12"))
                .child(span().class("blob blob--2").attr("data-speed", "-0.08"))
                .child(span().class("blob blob--3").attr("data-speed", "0.05")),
        )
        .child(
            container().class("hero__inner").child(
                div()
                    .class("hero__copy")
                    .child(
                        p().class("pill")
                            .child(span().class("pill__dot"))
                            .text(t(&["Avant de cliquer, vérifiez.", "Before you click, check.", "Antes de hacer clic, verifica."])),
                    )
                    .child(h1().class("hero__title").child(letters(
                        t(&["Le gardien intelligent", "The smart guardian", "El guardián inteligente"]),
                        0,
                    )).child(span().class("hero__title-2").child(letters(
                        t(&["de vos emails", "of your emails", "de tus correos"]),
                        22,
                    ))))
                    .child(
                        p().class("hero__typed")
                            .text(t(&["Un doute sur ", "Unsure about ", "¿Dudas sobre "]))
                            .child(
                                span()
                                    .class("typed")
                                    .attr("data-words", t(&typed))
                                    .text(first),
                            )
                            .child(span().class("caret").attr("aria-hidden", "true"))
                            .text(t(&[" ?", "?", "?"])),
                    )
                    .child(p().class("hero__lead").text(t(&[
                        "MailZen vous aide à lever le doute. Bien plus qu’un détecteur de spam : un assistant de sécurité qui analyse, explique, prévient et vous accompagne face aux emails, liens, documents et arnaques.",
                        "MailZen helps you clear it up. Much more than a spam filter: a security assistant that analyzes, explains, prevents and supports you against emails, links, documents and scams.",
                        "MailZen te ayuda a salir de dudas. Mucho más que un filtro de spam: un asistente de seguridad que analiza, explica, previene y te acompaña frente a correos, enlaces, documentos y estafas.",
                    ])))
                    .child(
                        div()
                            .class("hero__ctas")
                            .child(
                                btn(ctx.home("demo"), "btn--primary btn--lg")
                                    .attr("data-cursor", t(&["Scan", "Scan", "Escanear"]))
                                    .child(icon("radar"))
                                    .child(span().text(t(&["Analyser un email", "Analyze an email", "Analizar un correo"]))),
                            )
                            .child(
                                btn(ctx.home("modules"), "btn--ghost btn--lg")
                                    .child(span().text(t(&["Découvrir", "Discover", "Descubrir"])))
                                    .child(icon("arrow")),
                            ),
                    )
                    .child(ul().class("hero__badges").children(badges.iter().enumerate().map(
                        |(i, (ic, label))| {
                            li().style(format!("--i:{i}")).child(icon(ic)).child(span().text(*label))
                        },
                    ))),
            )
            .child(
                div()
                    .class("hero__visual")
                    .attr("aria-hidden", "true")
                    .child(
                        div()
                            .class("radar")
                            .child(canvas().class("radar__canvas").attr("data-radar", ""))
                            .child(span().class("radar__halo"))
                            .child(span().class("radar__core").child(logo("hero")))
                            .child(span().class("radar__orbit radar__orbit--1").child(span().child(icon("mail"))))
                            .child(span().class("radar__orbit radar__orbit--2").child(span().child(icon("link"))))
                            .child(span().class("radar__orbit radar__orbit--3").child(span().child(icon("qr")))),
                    )
                    .children(floats.iter().enumerate().map(|(i, (kind, ic, title, sub))| {
                        div()
                            .class("float")
                            .class(format!("float--{} float--{}", i + 1, kind))
                            .child(span().class("float__icon").child(icon(ic)))
                            .child(
                                span()
                                    .class("float__text")
                                    .child(strong().text(t(title)))
                                    .child(small().text(t(sub))),
                            )
                    })),
            ),
        )
        .child(
            a().class("hero__scroll")
                .href(ctx.home("modules"))
                .attr("aria-label", t(&["Défiler", "Scroll", "Desplazarse"]))
                .child(span()),
        )
}

fn marquee(ctx: &Ctx<'_>) -> Element {
    let row = |items: &[T3], reverse: bool| {
        let track = |hidden: bool| {
            let mut list = div()
                .class("marquee__track")
                .children(items.iter().map(|s| {
                    span()
                        .class("marquee__item")
                        .child(icon("shield"))
                        .child(span().text(ctx.t(s)))
                }));
            if hidden {
                list = list.attr("aria-hidden", "true");
            }
            list
        };
        div()
            .class(if reverse {
                "marquee__row marquee__row--rev"
            } else {
                "marquee__row"
            })
            .child(track(false))
            .child(track(true))
    };
    div()
        .class("marquee")
        .attr(
            "aria-label",
            ctx.t(&[
                "Menaces détectées",
                "Threats detected",
                "Amenazas detectadas",
            ]),
        )
        .child(row(&SCAMS[..20], false))
        .child(row(&SCAMS[19..], true))
}

fn modules(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    let goals: [T3; 9] = [
        [
            "Détecter les emails malveillants",
            "Detect malicious emails",
            "Detectar correos maliciosos",
        ],
        [
            "Identifier les usurpations",
            "Identify impersonation",
            "Identificar suplantaciones",
        ],
        [
            "Analyser liens, domaines et fichiers",
            "Analyze links, domains and files",
            "Analizar enlaces, dominios y archivos",
        ],
        [
            "Comprendre la manipulation",
            "Understand manipulation",
            "Entender la manipulación",
        ],
        [
            "Expliquer pourquoi c’est suspect",
            "Explain why it is suspicious",
            "Explicar por qué es sospechoso",
        ],
        [
            "Accompagner les victimes",
            "Support victims",
            "Acompañar a las víctimas",
        ],
        [
            "Prévenir avant l’incident",
            "Prevent before the incident",
            "Prevenir antes del incidente",
        ],
        [
            "Protéger la vie privée",
            "Protect privacy",
            "Proteger la privacidad",
        ],
        [
            "Former à reconnaître les arnaques",
            "Teach how to spot scams",
            "Enseñar a reconocer estafas",
        ],
    ];
    let stats: [(u64, &str, T3); 4] = [
        (
            7,
            "",
            [
                "modules de protection",
                "protection modules",
                "módulos de protección",
            ],
        ),
        (
            39,
            "",
            [
                "types d’arnaques référencés",
                "scam types covered",
                "tipos de estafa cubiertos",
            ],
        ),
        (
            12,
            "",
            [
                "techniques de manipulation",
                "manipulation techniques",
                "técnicas de manipulación",
            ],
        ),
        (
            0,
            "",
            [
                "compte requis pour scanner",
                "account needed to scan",
                "cuentas necesarias para escanear",
            ],
        ),
    ];
    section_("modules", "modules")
        .child(
            container()
                .child(head(
                    "01",
                    t(&["Présentation", "Overview", "Presentación"]),
                    t(&[
                        "Un véritable assistant de sécurité numérique",
                        "A real digital security assistant",
                        "Un verdadero asistente de seguridad digital",
                    ]),
                    Some(t(&[
                        "Pour tous : particuliers, seniors, étudiants, familles, professionnels. L’objectif n’est pas de faire peur, mais de rendre la cybersécurité compréhensible, accessible et utile au quotidien.",
                        "For everyone: individuals, seniors, students, families, professionals. The goal is not to scare you, but to make cybersecurity understandable, accessible and useful every day.",
                        "Para todos: particulares, mayores, estudiantes, familias, profesionales. El objetivo no es asustar, sino hacer la ciberseguridad comprensible, accesible y útil cada día.",
                    ])),
                ))
                .child(div().class("stats").attr("data-reveal", "").children(stats.iter().enumerate().map(
                    |(i, (n, suffix, label))| {
                        div()
                            .class("stat")
                            .style(format!("--i:{i}"))
                            .child(
                                strong()
                                    .class("stat__num")
                                    .attr("data-count", n.to_string())
                                    .attr("data-suffix", *suffix)
                                    .text(number(ctx.lang(), *n)),
                            )
                            .child(span().text(t(label)))
                    },
                )))
                .child(div().class("cards cards--modules").children(MODULES.iter().enumerate().map(
                    |(i, m)| {
                        a().class("card card--module")
                            .href(ctx.home(m.id))
                            .attr("data-reveal", "")
                            .attr("data-tilt", "8")
                            .attr("data-spot", "")
                            .style(format!("--i:{i}"))
                            .child(
                                div()
                                    .class("card__top")
                                    .child(icon_box(m.icon))
                                    .child(span().class("tag").text(t(&m.tag))),
                            )
                            .child(h3().text(m.name))
                            .child(p().text(t(&m.text)))
                            .child(
                                span()
                                    .class("card__more")
                                    .text(t(&["En savoir plus", "Learn more", "Saber más"]))
                                    .child(icon("arrow")),
                            )
                    },
                )))
                .child(
                    div()
                        .class("goals")
                        .attr("data-reveal", "")
                        .child(h3().class("goals__title").text(t(&[
                            "Les objectifs de MailZen",
                            "What MailZen sets out to do",
                            "Los objetivos de MailZen",
                        ])))
                        .child(checks(ctx, &goals)),
                ),
        )
}

fn how(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    section_("how", "how")
        .child(
            container()
                .child(head(
                    "02",
                    "Mail Scanner",
                    t(&["Comment fonctionne un scan ?", "How does a scan work?", "¿Cómo funciona un análisis?"]),
                    Some(t(&[
                        "Le cœur de l’application. Soumettez un message sans créer de compte : MailZen l’analyse en quelques secondes.",
                        "The heart of the app. Submit a message without an account: MailZen analyzes it in seconds.",
                        "El corazón de la app. Envía un mensaje sin crear cuenta: MailZen lo analiza en segundos.",
                    ])),
                ))
                .child(
                    ol().class("steps")
                        .attr("data-progress", "")
                        .child(span().class("steps__line").attr("aria-hidden", "true").child(span()))
                        .children(STEPS.iter().enumerate().map(|(i, s)| {
                            li().class("step")
                                .attr("data-reveal", "")
                                .style(format!("--i:{i}"))
                                .child(span().class("step__num").text(format!("{}", i + 1)))
                                .child(
                                    div()
                                        .class("step__body")
                                        .child(icon_box(s.icon))
                                        .child(h3().text(t(&s.title)))
                                        .child(p().text(t(&s.text))),
                                )
                        })),
                )
                .child(
                    div()
                        .class("imports")
                        .attr("data-reveal", "")
                        .child(h3().class("mini-title").text(t(&[
                            "10 façons d’importer",
                            "10 ways to import",
                            "10 formas de importar",
                        ])))
                        .child(chips(ctx, &IMPORTS, "chips--center")),
                ),
        )
}

fn demo(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    section_("demo", "demo").child(
        container()
            .child(head(
                "03",
                t(&["Démo interactive", "Interactive demo", "Demo interactiva"]),
                t(&["Essayez une analyse, ici et maintenant", "Try an analysis, right here", "Prueba un análisis aquí mismo"]),
                Some(t(&[
                    "Choisissez un exemple ou collez votre propre message. Un moteur de règles en Rust, compilé en WebAssembly, l’analyse dans votre navigateur.",
                    "Pick an example or paste your own message. A rules engine written in Rust and compiled to WebAssembly analyzes it in your browser.",
                    "Elige un ejemplo o pega tu propio mensaje. Un motor de reglas en Rust, compilado a WebAssembly, lo analiza en tu navegador.",
                ])),
            ))
            .child(
                div()
                    .class("demo__frame")
                    .attr("data-reveal", "")
                    .child(island("scan", ctx.lang().code(), islands::scan)),
            ),
    )
}

fn connect(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    section_("connect", "connect").child(
        container()
            .child(head(
                "04",
                t(&["Connexion", "Sign in", "Conexión"]),
                t(&[
                    "Connectez votre boîte mail",
                    "Connect your mailbox",
                    "Conecta tu buzón de correo",
                ]),
                Some(t(&[
                    "Gmail, Outlook, iCloud Mail, Yahoo ou n’importe quelle boîte IMAP : MailZen se connecte par une intégration autorisée, en lecture seule, et analyse vos emails sur votre appareil.",
                    "Gmail, Outlook, iCloud Mail, Yahoo or any IMAP mailbox: MailZen connects through an authorized integration, read-only, and analyzes your emails on your device.",
                    "Gmail, Outlook, iCloud Mail, Yahoo o cualquier buzón IMAP: MailZen se conecta mediante una integración autorizada, en modo solo lectura, y analiza tus correos en tu dispositivo.",
                ])),
            ))
            .child(
                div()
                    .class("connect__frame")
                    .attr("data-reveal", "")
                    .child(island("connect", ctx.lang().code(), islands::connect)),
            ),
    )
}

/// A gauge drawn by CSS (`--score`), animated when revealed.
fn gauge(score: u32, class: &str) -> Element {
    div()
        .class("gauge")
        .class(class.to_owned())
        .style(format!("--score:{score}"))
        .child(
            strong()
                .attr("data-count", score.to_string())
                .text(score.to_string()),
        )
        .child(small().text("/100"))
}

fn report(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    let indicators: [T3; 4] = [
        ["Domaine suspect", "Suspicious domain", "Dominio sospechoso"],
        ["Lien trompeur", "Misleading link", "Enlace engañoso"],
        ["Pression temporelle", "Time pressure", "Presión de tiempo"],
        [
            "Demande d’informations sensibles",
            "Request for sensitive information",
            "Petición de datos sensibles",
        ],
    ];
    let meters = [12, 34, 58, 92];
    section_("report", "report").child(
        container()
            .child(head(
                "05",
                t(&["Le rapport de sécurité", "The security report", "El informe de seguridad"]),
                t(&["Extrêmement détaillé, simple à comprendre", "Extremely detailed, easy to understand", "Muy detallado, fácil de entender"]),
                None,
            ))
            .child(
                div()
                    .class("split")
                    .child(
                        article()
                            .class("report-card verdict--danger")
                            .attr("data-reveal", "")
                            .attr("data-tilt", "5")
                            .child(
                                div()
                                    .class("report-card__head")
                                    .child(gauge(92, "gauge--lg"))
                                    .child(
                                        div()
                                            .child(span().class("verdict-badge").text(t(&["EMAIL À RISQUE", "RISKY EMAIL", "CORREO DE RIESGO"])))
                                            .child(p().class("report-card__level").text(t(&["Suspicion très élevée", "Very high suspicion", "Sospecha muy alta"]))),
                                    ),
                            )
                            .child(p().class("report-card__text").text(t(&[
                                "Ce message présente plusieurs caractéristiques d’une tentative de phishing.",
                                "This message shows several characteristics of a phishing attempt.",
                                "Este mensaje presenta varias características de un intento de phishing.",
                            ])))
                            .child(p().class("mini-title").text(t(&["4 indicateurs principaux", "4 main indicators", "4 indicadores principales"])))
                            .child(ul().class("indicators").children(indicators.iter().enumerate().map(|(i, x)| {
                                li().style(format!("--i:{i}")).child(icon("alert")).child(span().text(t(x)))
                            }))),
                    )
                    .child(
                        div()
                            .class("report__side")
                            .child(
                                div()
                                    .class("verdicts")
                                    .attr("data-reveal", "")
                                    .children(VERDICTS.iter().zip(meters).enumerate().map(
                                        |(i, ((class, title, text), meter))| {
                                            div()
                                                .class("verdict")
                                                .class(format!("verdict--{class}"))
                                                .style(format!("--i:{i};--m:{meter}"))
                                                .child(span().class("verdict__dot"))
                                                .child(strong().text(t(title)))
                                                .child(p().text(t(text)))
                                                .child(span().class("verdict__meter").child(span()))
                                        },
                                    )),
                            )
                            .child(p().class("note").attr("data-reveal", "").child(icon("help")).text(t(&[
                                "Le score de danger et le niveau de confiance sont distincts : un email peut être potentiellement dangereux sans que l’analyse soit assez fiable pour l’affirmer.",
                                "The danger score and the confidence level are separate: an email can be potentially dangerous without the analysis being reliable enough to say so.",
                                "La puntuación de peligro y el nivel de confianza son distintos: un correo puede ser potencialmente peligroso sin que el análisis sea lo bastante fiable para afirmarlo.",
                            ]))),
                    ),
            )
            .child(
                div()
                    .class("report-items")
                    .attr("data-reveal", "")
                    .child(h3().class("mini-title").text(t(&[
                        "Le rapport détaillé comporte",
                        "The detailed report includes",
                        "El informe detallado incluye",
                    ])))
                    .child(chips(ctx, &REPORT_ITEMS, "chips--center")),
            )
            .child(
                div()
                    .class("beyond")
                    .attr("data-reveal", "")
                    .child(h3().class("mini-title").text(t(&[
                        "Plus qu’une note",
                        "More than a score",
                        "Más que una nota",
                    ])))
                    .child(checks(ctx, &[
                        ["Les preuves et les signaux détectés", "Evidence and detected signals", "Pruebas y señales detectadas"],
                        ["Les signaux absents", "Missing signals", "Señales ausentes"],
                        ["Les éléments non analysés", "Items not analyzed", "Elementos no analizados"],
                        ["Les limitations", "Limitations", "Limitaciones"],
                        ["Les sources consultées", "Sources consulted", "Fuentes consultadas"],
                        ["La date de vérification", "Date of the check", "Fecha de verificación"],
                    ])),
            ),
    )
}

fn sender(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    let row = |label: &T3, value: Element| {
        div()
            .class("idcard__row")
            .child(span().class("idcard__label").text(t(label)))
            .child(value)
    };
    section_("sender", "sender").child(
        container()
            .child(head(
                "06",
                "Sender Intelligence",
                t(&["Qui vous écrit vraiment ?", "Who is really writing to you?", "¿Quién te escribe realmente?"]),
                Some(t(&[
                    "MailZen examine l’identité réelle de l’expéditeur et détecte les incohérences, jusqu’au caractère près.",
                    "MailZen examines the sender’s real identity and spots inconsistencies, down to a single character.",
                    "MailZen examina la identidad real del remitente y detecta las incoherencias, hasta el último carácter.",
                ])),
            ))
            .child(
                div()
                    .class("split")
                    .child(
                        article()
                            .class("idcard")
                            .attr("data-reveal", "")
                            .child(span().class("idcard__beam").attr("aria-hidden", "true"))
                            .child(row(
                                &["Nom affiché", "Display name", "Nombre mostrado"],
                                strong().text(t(&["Service Client PayPal", "PayPal Customer Service", "Atención al cliente PayPal"])),
                            ))
                            .child(row(
                                &["Adresse réelle", "Real address", "Dirección real"],
                                code().text("service@paypa")
                                    .child(mark().class("glyph").text("I"))
                                    .text("-account-check.example"),
                            ))
                            .child(row(
                                &["Analyse", "Analysis", "Análisis"],
                                p().text(t(&[
                                    "Le domaine ne correspond pas au domaine attendu. Un caractère visuellement ressemblant est utilisé : un « I » majuscule à la place du « l ».",
                                    "The domain does not match the expected one. A visually similar character is used: a capital “I” instead of an “l”.",
                                    "El dominio no coincide con el esperado. Se usa un carácter visualmente parecido: una «I» mayúscula en lugar de la «l».",
                                ])),
                            ))
                            .child(row(
                                &["Verdict", "Verdict", "Veredicto"],
                                span().class("verdict-badge verdict-badge--danger").text(t(&[
                                    "Imitation potentielle",
                                    "Potential impersonation",
                                    "Posible suplantación",
                                ])),
                            )),
                    )
                    .child(
                        div()
                            .class("stack")
                            .child(h3().class("mini-title").attr("data-reveal", "").text(t(&["Informations analysées", "What is analyzed", "Información analizada"])))
                            .child(chips(ctx, &SENDER_CHECKS, ""))
                            .child(h3().class("mini-title").attr("data-reveal", "").text(t(&[
                                "Comparaison avec les marques connues",
                                "Comparison with known brands",
                                "Comparación con marcas conocidas",
                            ])))
                            .child(chips(ctx, &BRAND_KINDS, "chips--soft"))
                            .child(p().class("note").attr("data-reveal", "").child(icon("shield")).text(t(&[
                                "Aucune usurpation n’est déclarée sur la seule base du nom affiché : la comparaison repose sur des preuves, des domaines officiels vérifiés et des indicateurs techniques.",
                                "No impersonation is declared on the display name alone: the comparison relies on evidence, verified official domains and technical indicators.",
                                "Nunca se declara una suplantación solo por el nombre mostrado: la comparación se basa en pruebas, dominios oficiales verificados e indicadores técnicos.",
                            ]))),
                    ),
            ),
    )
}

fn links(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    let parts: [(&str, &str, T3); 4] = [
        ("scheme", "https://", ["protocole", "scheme", "protocolo"]),
        (
            "sub",
            "account-verification-secure",
            ["leurre", "decoy", "señuelo"],
        ),
        (
            "domain",
            ".example",
            ["domaine réel", "real domain", "dominio real"],
        ),
        ("path", "/login?id=88213", ["chemin", "path", "ruta"]),
    ];
    let signals: [T3; 3] = [
        ["Domaine atypique", "Unusual domain", "Dominio atípico"],
        [
            "Motif de vérification de compte",
            "Account verification pattern",
            "Patrón de verificación de cuenta",
        ],
        [
            "Pression temporelle dans le message",
            "Time pressure in the message",
            "Presión de tiempo en el mensaje",
        ],
    ];
    section_("links", "links-section").child(
        container()
            .child(head(
                "07",
                "Link Guard",
                t(&["Chaque lien, décortiqué", "Every link, taken apart", "Cada enlace, al detalle"]),
                Some(t(&[
                    "Link Guard extrait et analyse tous les liens, sans jamais ouvrir une page dangereuse sur votre appareil.",
                    "Link Guard extracts and analyzes every link, without ever opening a dangerous page on your device.",
                    "Link Guard extrae y analiza todos los enlaces sin abrir nunca una página peligrosa en tu dispositivo.",
                ])),
            ))
            .child(
                article()
                    .class("url-card")
                    .attr("data-reveal", "")
                    .child(p().class("mini-title").text(t(&["URL analysée", "URL analyzed", "URL analizada"])))
                    .child(div().class("url").children(parts.iter().enumerate().map(|(i, (class, text, label))| {
                        span()
                            .class("url__part")
                            .class(format!("url__part--{class}"))
                            .style(format!("--i:{i}"))
                            .child(code().text(*text))
                            .child(small().text(t(label)))
                    })))
                    .child(
                        div()
                            .class("url-card__grid")
                            .child(
                                div()
                                    .child(p().class("mini-title").text(t(&["Domaines annoncés et réels", "Announced and real domains", "Dominios anunciados y reales"])))
                                    .child(p().text(t(&[
                                        "Le domaine ne correspond pas à l’organisme revendiqué dans le message.",
                                        "The domain does not match the organization claimed in the message.",
                                        "El dominio no corresponde al organismo que dice ser el mensaje.",
                                    ]))),
                            )
                            .child(
                                div()
                                    .child(p().class("mini-title").text(t(&["Signaux", "Signals", "Señales"])))
                                    .child(ul().class("indicators").children(signals.iter().enumerate().map(|(i, x)| {
                                        li().style(format!("--i:{i}")).child(icon("alert")).child(span().text(t(x)))
                                    }))),
                            ),
                    )
                    .child(
                        div()
                            .class("advice")
                            .child(icon("shield"))
                            .child(p().child(strong().text(t(&["Recommandation : ", "Recommendation: ", "Recomendación: "]))).text(t(&[
                                "ne pas ouvrir le lien. Accéder directement au service officiel.",
                                "do not open the link. Go directly to the official service.",
                                "no abrir el enlace. Ir directamente al servicio oficial.",
                            ]))),
                    ),
            )
            .child(
                div()
                    .class("split split--top")
                    .child(
                        div()
                            .child(h3().class("mini-title").attr("data-reveal", "").text(t(&["Ce que vérifie Link Guard", "What Link Guard checks", "Lo que verifica Link Guard"])))
                            .child(chips(ctx, &LINK_CHECKS, "")),
                    )
                    .child(
                        div()
                            .class("sandbox")
                            .attr("data-reveal", "")
                            .child(
                                p().class("sandbox__title")
                                    .child(icon("lock"))
                                    .text(t(&["Analyse approfondie en environnement isolé", "Deep analysis in an isolated environment", "Análisis profundo en un entorno aislado"])),
                            )
                            .child(chips(ctx, &SANDBOX, "chips--soft")),
                    ),
            ),
    )
}

fn files(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    let indicators: [T3; 3] = [
        [
            "Contient des liens externes",
            "Contains external links",
            "Contiene enlaces externos",
        ],
        [
            "Présence d’une URL suspecte",
            "A suspicious URL is present",
            "Hay una URL sospechosa",
        ],
        [
            "Associé à un email qui joue sur l’urgence",
            "Attached to an email that plays on urgency",
            "Asociado a un correo que juega con la urgencia",
        ],
    ];
    section_("files", "files").child(
        container()
            .child(head(
                "08",
                "Attachment Guard",
                t(&["Les pièces jointes, passées au crible", "Attachments, screened", "Los adjuntos, examinados"]),
                Some(t(&[
                    "Type réel, signatures, macros, scripts, archives imbriquées : Attachment Guard repère ce qu’un nom de fichier peut cacher.",
                    "Real type, signatures, macros, scripts, nested archives: Attachment Guard spots what a file name can hide.",
                    "Tipo real, firmas, macros, scripts, archivos anidados: Attachment Guard detecta lo que un nombre de archivo puede ocultar.",
                ])),
            ))
            .child(
                div()
                    .class("split")
                    .child(
                        article()
                            .class("file-card")
                            .attr("data-reveal", "")
                            .attr("data-tilt", "6")
                            .child(
                                div()
                                    .class("file-card__doc")
                                    .child(span().class("file-card__fold"))
                                    .child(span().class("file-card__ext").text("PDF"))
                                    .child(span().class("file-card__lines").child(i()).child(i()).child(i()).child(i()))
                                    .child(span().class("file-card__scan")),
                            )
                            .child(
                                div()
                                    .class("file-card__info")
                                    .child(strong().text(t(&["Facture_2026.pdf", "Invoice_2026.pdf", "Factura_2026.pdf"])))
                                    .child(small().text(t(&["Fichier analysé", "File analyzed", "Archivo analizado"])))
                                    .child(span().class("verdict-badge verdict-badge--suspicious").text(t(&["Fichier suspect", "Suspicious file", "Archivo sospechoso"])))
                                    .child(ul().class("indicators").children(indicators.iter().enumerate().map(|(i, x)| {
                                        li().style(format!("--i:{i}")).child(icon("alert")).child(span().text(t(x)))
                                    })))
                                    .child(p().class("file-card__advice").child(icon("shield")).text(t(&[
                                        "Ne pas ouvrir ce document avant vérification.",
                                        "Do not open this document before checking it.",
                                        "No abrir este documento antes de verificarlo.",
                                    ]))),
                            ),
                    )
                    .child(
                        div()
                            .class("formats")
                            .attr("data-reveal", "")
                            .children(FORMATS.iter().enumerate().map(|(i, (ext, text))| {
                                div()
                                    .class("format")
                                    .style(format!("--i:{i}"))
                                    .attr("data-spot", "")
                                    .child(strong().text(*ext))
                                    .child(small().text(t(text)))
                            })),
                    ),
            )
            .child(h3().class("mini-title mini-title--center").attr("data-reveal", "").text(t(&["Les vérifications", "The checks", "Las verificaciones"])))
            .child(chips(ctx, &FILE_CHECKS, "chips--center"))
            .child(p().class("note note--center").attr("data-reveal", "").child(icon("help")).text(t(&[
                "MailZen ne prétend pas détecter tous les malwares par la seule analyse statique : réputation et sandbox viendront en complément, avec votre consentement.",
                "MailZen does not claim to detect all malware through static analysis alone: reputation and sandboxing will complement it, with your consent.",
                "MailZen no pretende detectar todo el malware solo con análisis estático: la reputación y el sandbox lo complementarán, con tu consentimiento.",
            ]))),
    )
}

/// A QR code drawn with CSS cells, from a fixed pattern.
fn qr_code() -> Element {
    const SIZE: usize = 21;
    let finder = |x: usize, y: usize| {
        let inside = |ox: usize, oy: usize| {
            x >= ox && x < ox + 7 && y >= oy && y < oy + 7 && {
                let (dx, dy) = (x - ox, y - oy);
                let ring = dx == 0 || dx == 6 || dy == 0 || dy == 6;
                let core = (2..=4).contains(&dx) && (2..=4).contains(&dy);
                ring || core
            }
        };
        inside(0, 0) || inside(SIZE - 7, 0) || inside(0, SIZE - 7)
    };
    let reserved = |x: usize, y: usize| {
        (x < 8 && y < 8) || (x >= SIZE - 8 && y < 8) || (x < 8 && y >= SIZE - 8)
    };
    let mut cells = Vec::new();
    let mut seed: u32 = 0x5eed_1234;
    for y in 0..SIZE {
        for x in 0..SIZE {
            seed = seed.wrapping_mul(1_103_515_245).wrapping_add(12_345);
            let on = if reserved(x, y) {
                finder(x, y)
            } else {
                (seed >> 16) & 1 == 1
            };
            cells.push(span().class(if on { "on" } else { "off" }));
        }
    }
    div()
        .class("qr")
        .attr("aria-hidden", "true")
        .children(cells)
        .child(span().class("qr__laser"))
}

fn screens(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    section_("screens", "screens").child(
        container()
            .child(head(
                "09",
                "ScreenScan & QR Guard",
                t(&["Une capture, un QR code : c’est analysé", "A screenshot, a QR code: analyzed", "Una captura, un código QR: analizado"]),
                Some(t(&[
                    "Prenez une capture d’un email, d’un SMS ou d’une notification : MailZen lit le texte, reconstruit le contexte et signale ce qui cloche.",
                    "Take a screenshot of an email, a text or a notification: MailZen reads the text, rebuilds the context and flags what is wrong.",
                    "Haz una captura de un correo, un SMS o una notificación: MailZen lee el texto, reconstruye el contexto y señala lo que falla.",
                ])),
            ))
            .child(
                div()
                    .class("split")
                    .child(
                        div()
                            .class("phone")
                            .attr("data-reveal", "")
                            .attr("aria-hidden", "true")
                            .child(span().class("phone__notch"))
                            .child(
                                div()
                                    .class("phone__screen")
                                    .child(p().class("sms__from").text(t(&["Livraison", "Delivery", "Envíos"])))
                                    .child(
                                        div()
                                            .class("sms")
                                            .child(span().text(t(&["Votre colis est bloqué. Frais de ", "Your parcel is on hold. Fee of ", "Tu paquete está retenido. Tasa de "])))
                                            .child(mark().class("ocr ocr--1").text(t(&["1,99 €", "$1.99", "1,99 €"])))
                                            .child(span().text(t(&[" à régler ici : ", " to pay here: ", " a pagar aquí: "])))
                                            .child(mark().class("ocr ocr--2").text("bit.ly/c0lis"))
                                            .child(span().text(t(&[" ou appelez le ", " or call ", " o llama al "])))
                                            .child(mark().class("ocr ocr--3").text("+33 9 00 00 00 00")),
                                    )
                                    .child(span().class("phone__ocr")),
                            )
                            .child(
                                div()
                                    .class("phone__result")
                                    .child(icon("alert"))
                                    .child(span().text(t(&["3 signaux trouvés", "3 signals found", "3 señales encontradas"]))),
                            ),
                    )
                    .child(
                        div()
                            .class("stack")
                            .child(
                                div()
                                    .class("cta-card")
                                    .attr("data-reveal", "")
                                    .attr("data-spot", "")
                                    .child(icon_box("camera"))
                                    .child(div().child(strong().text(t(&["Analyser une capture", "Analyze a screenshot", "Analizar una captura"]))).child(p().text(t(&[
                                        "Identifiez les signaux suspects sur une image.",
                                        "Spot the suspicious signals in an image.",
                                        "Identifica las señales sospechosas en una imagen.",
                                    ])))),
                            )
                            .child(h3().class("mini-title").attr("data-reveal", "").text(t(&["Types de captures", "Kinds of screenshots", "Tipos de capturas"])))
                            .child(chips(ctx, &SCREEN_TYPES, ""))
                            .child(
                                div()
                                    .class("qr-card")
                                    .attr("data-reveal", "")
                                    .child(qr_code())
                                    .child(
                                        div()
                                            .class("qr-card__text")
                                            .child(strong().text("QR Guard"))
                                            .child(p().text(t(&[
                                                "La destination s’affiche avant toute ouverture. Jamais d’ouverture automatique.",
                                                "The destination shows before anything opens. Never opened automatically.",
                                                "El destino se muestra antes de abrir nada. Nunca se abre automáticamente.",
                                            ])))
                                            .child(code().class("qr-card__dest").text("https://bit.ly/c0lis → ?"))
                                            .child(chips(ctx, &QR_PLACES, "chips--soft chips--small")),
                                    ),
                            ),
                    ),
            ),
    )
}

fn zenai(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    section_("zenai", "zenai").child(
        container()
            .child(head(
                "10",
                "ZenAI",
                t(&["Un assistant qui explique, sans jamais inventer", "An assistant that explains, never invents", "Un asistente que explica, sin inventar nunca"]),
                Some(t(&[
                    "Pas un simple chatbot : ZenAI est relié aux résultats du moteur de détection et aux indicateurs trouvés.",
                    "Not just a chatbot: ZenAI is connected to the detection engine’s results and the indicators it found.",
                    "No es un simple chatbot: ZenAI está conectado a los resultados del motor de detección y a los indicadores encontrados.",
                ])),
            ))
            .child(
                div()
                    .class("split")
                    .child(
                        div()
                            .class("chat")
                            .attr("data-reveal", "")
                            .child(
                                div()
                                    .class("chat__head")
                                    .child(span().class("chat__avatar").child(icon("spark")))
                                    .child(div().child(strong().text("ZenAI")).child(small().child(span().class("pill__dot")).text(t(&["En ligne", "Online", "En línea"])))),
                            )
                            .child(div().class("chat__body").children(CHAT.iter().enumerate().map(|(i, (user, text))| {
                                div()
                                    .class(if *user { "bubble bubble--me" } else { "bubble" })
                                    .style(format!("--i:{i}"))
                                    .text(t(text))
                            })).child(div().class("bubble bubble--typing").style("--i:5").child(i()).child(i()).child(i()))),
                    )
                    .child(
                        div()
                            .class("stack")
                            .child(h3().class("mini-title").attr("data-reveal", "").text(t(&["Questions suggérées", "Suggested questions", "Preguntas sugeridas"])))
                            .child(chips(ctx, &ZENAI_QUESTIONS, "chips--questions"))
                            .child(h3().class("mini-title").attr("data-reveal", "").text(t(&["Ce qu’il sait faire", "What it can do", "Lo que sabe hacer"])))
                            .child(chips(ctx, &ZENAI_CAN, "chips--soft chips--small")),
                    ),
            )
            .child(
                div()
                    .class("rules")
                    .attr("data-reveal", "")
                    .child(
                        p().class("rules__title")
                            .child(icon("shield"))
                            .text(t(&["La sécurité de l’assistant", "The assistant’s safety", "La seguridad del asistente"])),
                    )
                    .child(checks(ctx, &ZENAI_RULES)),
            ),
    )
}

fn manipulation(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    let meters: [(T3, T3, u32); 4] = [
        (
            ["Urgence", "Urgency", "Urgencia"],
            ["Détectée", "Detected", "Detectada"],
            95,
        ),
        (
            ["Menace", "Threat", "Amenaza"],
            ["Détectée", "Detected", "Detectada"],
            88,
        ),
        (
            ["Demande de données", "Data request", "Petición de datos"],
            ["Détectée", "Detected", "Detectada"],
            92,
        ),
        (
            ["Autorité imitée", "Imitated authority", "Autoridad imitada"],
            ["Possible", "Possible", "Posible"],
            55,
        ),
    ];
    section_("manipulation", "manipulation").child(
        container()
            .child(head(
                "11",
                "Social Engineering Detector",
                t(&["Démasquer la manipulation", "Unmasking manipulation", "Desenmascarar la manipulación"]),
                Some(t(&[
                    "MailZen analyse la manière dont un message tente d’influencer votre comportement, en plus du risque technique.",
                    "MailZen analyzes how a message tries to influence your behavior, on top of the technical risk.",
                    "MailZen analiza cómo un mensaje intenta influir en tu comportamiento, además del riesgo técnico.",
                ])),
            ))
            .child(
                div()
                    .class("split")
                    .child(div().class("techniques").children(TECHNIQUES.iter().enumerate().map(
                        |(i, (ic, name, example))| {
                            article()
                                .class("technique")
                                .attr("data-reveal", "")
                                .attr("data-spot", "")
                                .style(format!("--i:{}", i % 4))
                                .child(icon_box(ic))
                                .child(strong().text(t(name)))
                                .child(q().text(t(example)))
                        },
                    )))
                    .child(
                        article()
                            .class("index-card")
                            .attr("data-reveal", "")
                            .child(p().class("mini-title").text(t(&["Indice de manipulation", "Manipulation index", "Índice de manipulación"])))
                            .child(p().class("index-card__level").text(t(&["Élevé", "High", "Alto"])))
                            .child(p().class("index-card__text").text(t(&[
                                "Le message utilise plusieurs techniques destinées à accélérer votre décision.",
                                "The message uses several techniques designed to rush your decision.",
                                "El mensaje usa varias técnicas para precipitar tu decisión.",
                            ])))
                            .child(ul().class("meters").children(meters.iter().enumerate().map(|(i, (name, state, value))| {
                                li().style(format!("--i:{i};--m:{value}"))
                                    .child(span().class("meters__name").text(t(name)))
                                    .child(span().class("meters__state").text(t(state)))
                                    .child(span().class("meters__bar").child(span()))
                            }))),
                    ),
            ),
    )
}

fn scams(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    section_("scams", "scams").child(
        container()
            .child(head(
                "12",
                "Scam Intelligence",
                t(&[
                    "Toutes les familles d’arnaques",
                    "Every family of scams",
                    "Todas las familias de estafas",
                ]),
                Some(t(&[
                    "Une bibliothèque de fraudes tenue à jour, pour reconnaître chaque scénario.",
                    "An up-to-date library of frauds, to recognize every scenario.",
                    "Una biblioteca de fraudes actualizada para reconocer cada escenario.",
                ])),
            ))
            .child(
                div()
                    .class("cards cards--3")
                    .children(CATEGORIES.iter().enumerate().map(|(i, c)| {
                        article()
                            .class("card card--category")
                            .attr("data-reveal", "")
                            .attr("data-tilt", "7")
                            .attr("data-spot", "")
                            .style(format!("--i:{}", i % 3))
                            .child(icon_box(c.icon))
                            .child(h3().text(t(&c.title)))
                            .child(p().text(t(&c.text)))
                    })),
            )
            .child(
                div()
                    .class("library")
                    .attr("data-reveal", "")
                    .child(h3().class("mini-title mini-title--center").text(t(&[
                        "La bibliothèque de fraude",
                        "The fraud library",
                        "La biblioteca de fraudes",
                    ])))
                    .child(
                        div()
                            .class("library__cloud")
                            .children(SCAMS.iter().enumerate().map(|(i, s)| {
                                span()
                                    .class("chip chip--cloud")
                                    .style(format!("--i:{i};--d:{}", (i * 37) % 11))
                                    .text(t(s))
                            })),
                    ),
            ),
    )
}

fn sos(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    section_("sos", "sos-section").child(
        container()
            .child(head(
                "13",
                "SOS Cyber",
                t(&["J’ai déjà cliqué. Et maintenant ?", "I already clicked. Now what?", "Ya hice clic. ¿Y ahora?"]),
                Some(t(&[
                    "MailZen n’abandonne pas les utilisateurs qui ont fait une erreur. Choisissez ce qui s’est passé : les étapes s’adaptent.",
                    "MailZen does not abandon users who made a mistake. Choose what happened: the steps adapt.",
                    "MailZen no abandona a quien se equivocó. Elige lo que pasó: los pasos se adaptan.",
                ])),
            ))
            .child(
                div()
                    .class("sos__frame")
                    .attr("data-reveal", "")
                    .child(island("sos", ctx.lang().code(), islands::sos)),
            )
            .child(
                p().class("note note--center")
                    .attr("data-reveal", "")
                    .child(icon("help"))
                    .text(t(&[
                        "En France, MailZen orientera vers les ressources officielles d’assistance et de signalement, notamment ",
                        "In France, MailZen will point you to official support and reporting services, including ",
                        "En Francia, MailZen te orientará hacia los recursos oficiales de ayuda y denuncia, en especial ",
                    ]))
                    .child(external(a().href("https://www.cybermalveillance.gouv.fr/").text("Cybermalveillance.gouv.fr")))
                    .text(t(&[
                        ", votre banque et les autorités compétentes.",
                        ", your bank and the relevant authorities.",
                        ", tu banco y las autoridades competentes.",
                    ])),
            ),
    )
}

fn ecosystem(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    section_("ecosystem", "ecosystem").child(
        container()
            .child(head(
                "14",
                t(&["Écosystème", "Ecosystem", "Ecosistema"]),
                t(&["Répondre, vérifier, protéger, apprendre", "Reply, verify, protect, learn", "Responder, verificar, proteger, aprender"]),
                None,
            ))
            .child(div().class("cards cards--2").children(ECOSYSTEM.iter().enumerate().map(|(i, f)| {
                article()
                    .class("card card--feature")
                    .attr("data-reveal", "")
                    .attr("data-spot", "")
                    .style(format!("--i:{}", i % 2))
                    .child(div().class("card__top").child(icon_box(f.icon)).child(h3().text(f.name)))
                    .child(p().text(t(&f.text)))
                    .child(ul().class("mini-checks").children(f.points.iter().map(|pt| {
                        li().child(icon("check")).child(span().text(t(pt)))
                    })))
            })))
            .child(
                div()
                    .class("notif")
                    .attr("data-reveal", "")
                    .child(span().class("notif__icon").child(icon("family")))
                    .child(
                        div()
                            .child(strong().text("FamilyZen"))
                            .child(p().text(t(&[
                                "Un email suspect a été analysé. Le résultat indique plusieurs risques. La personne a choisi de partager cette analyse avec vous.",
                                "A suspicious email was analyzed. The result shows several risks. The person chose to share this analysis with you.",
                                "Se ha analizado un correo sospechoso. El resultado indica varios riesgos. La persona ha decidido compartir este análisis contigo.",
                            ]))),
                    )
                    .child(small().class("notif__time").text(t(&["maintenant", "now", "ahora"]))),
            ),
    )
}

fn radar(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    let bars = [38, 52, 44, 70, 58, 86, 64, 92, 74, 60, 80, 96];
    let feed: [(&str, T3, T3); 3] = [
        (
            "danger",
            [
                "Faux remboursement bancaire",
                "Fake bank refund",
                "Falso reembolso bancario",
            ],
            ["Danger élevé", "High danger", "Peligro elevado"],
        ),
        (
            "caution",
            [
                "Lien raccourci dans un SMS",
                "Short link in a text",
                "Enlace acortado en un SMS",
            ],
            ["Vigilance", "Caution", "Precaución"],
        ),
        (
            "safe",
            [
                "Newsletter de la mairie",
                "City hall newsletter",
                "Boletín del ayuntamiento",
            ],
            [
                "Aucun risque notable",
                "No notable risk",
                "Ningún riesgo notable",
            ],
        ),
    ];
    section_("radar", "radar-section").child(
        container()
            .child(head(
                "15",
                "MailZen Radar",
                t(&["Votre protection, d’un coup d’œil", "Your protection at a glance", "Tu protección de un vistazo"]),
                Some(t(&[
                    "Le tableau de bord, centre de l’application : dernières analyses, alertes, conseils et tendances.",
                    "The dashboard, the heart of the app: latest analyses, alerts, tips and trends.",
                    "El panel, centro de la app: últimos análisis, alertas, consejos y tendencias.",
                ])),
            ))
            .child(
                article()
                    .class("dash")
                    .attr("data-reveal", "")
                    .child(
                        div()
                            .class("dash__head")
                            .child(div().child(small().text(t(&["Votre protection", "Your protection", "Tu protección"]))).child(strong().child(span().class("pill__dot")).text(t(&["Protection active", "Protection on", "Protección activa"]))))
                            .child(span().class("dash__shield").child(icon("shield"))),
                    )
                    .child(div().class("dash__stats").children(RADAR.iter().enumerate().map(|(i, (label, n, ic))| {
                        div()
                            .class("dash__stat")
                            .style(format!("--i:{i}"))
                            .child(icon(ic))
                            .child(strong().attr("data-count", n.to_string()).text(number(ctx.lang(), *n)))
                            .child(small().text(t(label)))
                    })))
                    .child(
                        div()
                            .class("dash__row")
                            .child(
                                div()
                                    .class("dash__chart")
                                    .child(small().text(t(&["Analyses par semaine", "Analyses per week", "Análisis por semana"])))
                                    .child(div().class("bars").children(bars.iter().enumerate().map(|(i, h)| {
                                        span().style(format!("--i:{i};--h:{h}"))
                                    }))),
                            )
                            .child(
                                ul().class("dash__feed").children(feed.iter().enumerate().map(|(i, (class, title, verdict))| {
                                    li().style(format!("--i:{i}"))
                                        .child(span().class(format!("dot dot--{class}")))
                                        .child(span().class("dash__feed-title").text(t(title)))
                                        .child(small().text(t(verdict)))
                                })),
                            ),
                    )
                    .child(p().class("dash__note").text(t(&[
                        "Exemple de données fictives pour illustrer l’interface.",
                        "Fictional sample data, to illustrate the interface.",
                        "Datos ficticios de ejemplo para ilustrar la interfaz.",
                    ]))),
            )
            .child(
                div()
                    .class("history")
                    .attr("data-reveal", "")
                    .child(h3().class("mini-title mini-title--center").text(t(&["Historique des analyses", "Analysis history", "Historial de análisis"])))
                    .child(chips(ctx, &[
                        ["Recherche", "Search", "Búsqueda"],
                        ["Filtres", "Filters", "Filtros"],
                        ["Tri", "Sorting", "Orden"],
                        ["Favoris", "Favorites", "Favoritos"],
                        ["Suppression", "Deletion", "Eliminación"],
                        ["Export", "Export", "Exportación"],
                        ["Comparaison", "Comparison", "Comparación"],
                        ["Données protégées", "Protected data", "Datos protegidos"],
                    ], "chips--center")),
            ),
    )
}

fn learn(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    section_("learn", "learn").child(
        container()
            .child(head(
                "16",
                "ZenLearn",
                t(&["Vrai ou faux lien ? À vous de jouer", "Real or fake link? Your turn", "¿Enlace real o falso? Te toca"]),
                Some(t(&[
                    "Une vraie section éducative : cours, mini-jeux, quiz quotidien, badges et niveaux. Testez-vous sur six liens.",
                    "A real learning section: lessons, mini-games, a daily quiz, badges and levels. Test yourself on six links.",
                    "Una verdadera sección educativa: lecciones, minijuegos, quiz diario, insignias y niveles. Ponte a prueba con seis enlaces.",
                ])),
            ))
            .child(
                div()
                    .class("split")
                    .child(
                        div()
                            .class("quiz__frame")
                            .attr("data-reveal", "")
                            .child(island("quiz", ctx.lang().code(), islands::quiz)),
                    )
                    .child(
                        div()
                            .class("stack")
                            .child(h3().class("mini-title").attr("data-reveal", "").text(t(&["Les cours", "The lessons", "Las lecciones"])))
                            .child(chips(ctx, &LEARN_TOPICS, "chips--soft")),
                    ),
            ),
    )
}

fn privacy(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    section_("privacy", "privacy").child(
        container()
            .child(head(
                "17",
                "PrivacyZen",
                t(&["La confidentialité avant tout", "Privacy first", "La privacidad ante todo"]),
                Some(t(&[
                    "MailZen privilégie les analyses locales, minimise la collecte et vous laisse le contrôle de vos informations.",
                    "MailZen favors local analysis, minimizes collection and leaves you in control of your information.",
                    "MailZen prioriza el análisis local, minimiza la recogida de datos y te deja el control de tu información.",
                ])),
            ))
            .child(div().class("modes").children(MODES.iter().enumerate().map(|(i, (class, ic, name, text))| {
                article()
                    .class("mode")
                    .class(format!("mode--{class}"))
                    .attr("data-reveal", "")
                    .attr("data-tilt", "8")
                    .style(format!("--i:{i}"))
                    .child(span().class("mode__orb").child(icon(ic)))
                    .child(h3().text(t(name)))
                    .child(p().text(t(text)))
            })))
            .child(
                div()
                    .class("vault")
                    .attr("data-reveal", "")
                    .child(div().class("vault__lock").attr("aria-hidden", "true").child(span().class("vault__ring")).child(span().class("vault__ring vault__ring--2")).child(icon("lock")))
                    .child(checks(ctx, &PRIVACY)),
            ),
    )
}

fn architecture(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    let stack: [(T3, &str); 10] = [
        (["iOS", "iOS", "iOS"], "Swift + SwiftUI"),
        (
            ["Android", "Android", "Android"],
            "Kotlin + Jetpack Compose",
        ),
        (["Cœur", "Core", "Núcleo"], "Rust"),
        (["OCR iOS", "iOS OCR", "OCR iOS"], "Vision"),
        (["OCR Android", "Android OCR", "OCR Android"], "ML Kit"),
        (["Base locale", "Local database", "Base local"], "SQLite"),
        (["Backend", "Backend", "Backend"], "Rust"),
        (["API", "API", "API"], "REST"),
        (["CI/CD", "CI/CD", "CI/CD"], "GitHub Actions"),
        (
            ["Distribution", "Distribution", "Distribución"],
            "App Store + Google Play",
        ),
    ];
    section_("architecture", "architecture").child(
        container()
            .child(head(
                "18",
                t(&["Architecture", "Architecture", "Arquitectura"]),
                t(&["Un moteur Rust commun, des apps natives", "One Rust engine, native apps", "Un motor Rust común, apps nativas"]),
                Some(t(&[
                    "Le moteur de décision est indépendant de l’IA : règles déterministes, réputation, indicateurs techniques et modèles de classification.",
                    "The decision engine does not depend on AI: deterministic rules, reputation, technical indicators and classification models.",
                    "El motor de decisión no depende de la IA: reglas deterministas, reputación, indicadores técnicos y modelos de clasificación.",
                ])),
            ))
            .child(
                div()
                    .class("arch")
                    .attr("data-reveal", "")
                    .child(
                        div()
                            .class("arch__apps")
                            .child(div().class("arch__box arch__box--ios").child(icon("apple")).child(strong().text("iOS — SwiftUI")).child(small().text(t(&["Interface, partage, OCR, intégrations Apple", "UI, sharing, OCR, Apple integrations", "Interfaz, compartir, OCR, integraciones Apple"]))))
                            .child(div().class("arch__box arch__box--android").child(icon("android")).child(strong().text("Android — Kotlin / Compose")).child(small().text(t(&["Interface, partage, OCR, intégrations Android", "UI, sharing, OCR, Android integrations", "Interfaz, compartir, OCR, integraciones Android"])))),
                    )
                    .child(div().class("arch__link").attr("aria-hidden", "true").child(span()).child(span()))
                    .child(
                        div()
                            .class("arch__core")
                            .child(p().class("arch__core-title").child(icon("cog")).text(t(&["MailZen Core — Rust", "MailZen Core — Rust", "MailZen Core — Rust"])))
                            .child(small().text(t(&["Moteur d’analyse commun", "Shared analysis engine", "Motor de análisis común"])))
                            .child(div().class("arch__engines").children(CORE.iter().enumerate().map(|(i, (name, text))| {
                                div().class("arch__engine").style(format!("--i:{i}")).child(strong().text(*name)).child(small().text(t(text)))
                            }))),
                    )
                    .child(div().class("arch__link").attr("aria-hidden", "true").child(span()).child(span()))
                    .child(div().class("arch__box arch__box--services").child(icon("cloud")).child(strong().text(t(&["Services complémentaires", "Additional services", "Servicios complementarios"]))).child(small().text(t(&["API, réputation, sandbox, intelligence externe", "API, reputation, sandbox, external intelligence", "API, reputación, sandbox, inteligencia externa"])))),
            )
            .child(
                dl().class("stack-list")
                    .attr("data-reveal", "")
                    .children(stack.iter().enumerate().map(|(i, (label, value))| {
                        div().style(format!("--i:{i}")).child(dt().text(t(label))).child(dd().text(*value))
                    })),
            )
            .child(p().class("note note--center").attr("data-reveal", "").child(icon("help")).text(t(&[
                "Sources de renseignement à évaluer, jamais comme unique source de vérité : Google Safe Browsing, VirusTotal, URLhaus, PhishTank, CERT et CSIRT, réputation DNS et de domaines.",
                "Intelligence sources to evaluate, never as the only source of truth: Google Safe Browsing, VirusTotal, URLhaus, PhishTank, CERTs and CSIRTs, DNS and domain reputation.",
                "Fuentes de inteligencia por evaluar, nunca como única fuente de verdad: Google Safe Browsing, VirusTotal, URLhaus, PhishTank, CERT y CSIRT, reputación DNS y de dominios.",
            ]))),
    )
}

fn platforms(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    let cell = |v: u8| {
        let (class, ic, label): (&str, &str, T3) = match v {
            1 => ("yes", "check", ["Oui", "Yes", "Sí"]),
            2 => (
                "via",
                "link",
                [
                    "Via intégration autorisée",
                    "Via an authorized integration",
                    "Mediante integración autorizada",
                ],
            ),
            _ => ("no", "x", ["Non", "No", "No"]),
        };
        span()
            .class("cap")
            .class(format!("cap--{class}"))
            .attr("title", t(&label))
            .child(icon(ic))
            .child(span().class("cap__label").text(t(&label)))
    };
    section_("platforms", "platforms").child(
        container()
            .child(head(
                "19",
                t(&[
                    "Contraintes réelles",
                    "Real constraints",
                    "Limitaciones reales",
                ]),
                t(&[
                    "Conçu pour ce qu’iOS et Android permettent vraiment",
                    "Built for what iOS and Android really allow",
                    "Pensado para lo que iOS y Android permiten de verdad",
                ]),
                None,
            ))
            .child(
                div()
                    .class("caps")
                    .attr("data-reveal", "")
                    .attr("role", "table")
                    .child(
                        div()
                            .class("caps__row caps__row--head")
                            .attr("role", "row")
                            .child(span().attr("role", "columnheader").text(t(&[
                                "Fonctionnalité",
                                "Feature",
                                "Función",
                            ])))
                            .child(
                                span()
                                    .attr("role", "columnheader")
                                    .child(icon("apple"))
                                    .text("iOS"),
                            )
                            .child(
                                span()
                                    .attr("role", "columnheader")
                                    .child(icon("android"))
                                    .text("Android"),
                            ),
                    )
                    .children(
                        PLATFORMS
                            .iter()
                            .enumerate()
                            .map(|(i, (name, ios, android))| {
                                div()
                                    .class("caps__row")
                                    .attr("role", "row")
                                    .style(format!("--i:{i}"))
                                    .child(span().attr("role", "cell").text(t(name)))
                                    .child(span().attr("role", "cell").child(cell(*ios)))
                                    .child(span().attr("role", "cell").child(cell(*android)))
                            }),
                    ),
            )
            .child(
                div()
                    .class("more")
                    .attr("data-reveal", "")
                    .child(h3().class("mini-title mini-title--center").text(t(&[
                        "Et bien plus à venir",
                        "And much more to come",
                        "Y mucho más por venir",
                    ])))
                    .child(div().class("more__grid").children(
                        MORE_MODULES.iter().enumerate().map(|(i, (name, text))| {
                            div()
                                .class("more__item")
                                .style(format!("--i:{i}"))
                                .attr("data-spot", "")
                                .child(strong().text(*name))
                                .child(small().text(t(text)))
                        }),
                    )),
            ),
    )
}

fn roadmap(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    section_("roadmap", "roadmap").child(
        container()
            .child(head(
                "20",
                t(&["Feuille de route", "Roadmap", "Hoja de ruta"]),
                t(&[
                    "Neuf étapes, un moteur testable dès le début",
                    "Nine stages, an engine testable from day one",
                    "Nueve etapas, un motor comprobable desde el principio",
                ]),
                None,
            ))
            .child(
                ol().class("timeline")
                    .attr("data-progress", "")
                    .child(
                        span()
                            .class("timeline__line")
                            .attr("aria-hidden", "true")
                            .child(span()),
                    )
                    .children(ROADMAP.iter().enumerate().map(|(i, phase)| {
                        li().class("phase")
                            .attr("data-reveal", "")
                            .style(format!("--i:{}", i % 2))
                            .child(span().class("phase__dot").text(format!("{}", i + 1)))
                            .child(
                                div()
                                    .class("phase__card")
                                    .attr("data-spot", "")
                                    .child(small().text(format!(
                                        "{} {} · {}",
                                        t(&["Phase", "Phase", "Fase"]),
                                        i + 1,
                                        t(&phase.name)
                                    )))
                                    .child(h3().text(phase.title))
                                    .child(
                                        ul().children(
                                            phase.items.iter().map(|it| li().text(t(it))),
                                        ),
                                    ),
                            )
                    })),
            ),
    )
}

fn pricing(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    section_("pricing", "pricing-section").child(
        container()
            .child(head(
                "21",
                t(&["Tarifs", "Pricing", "Precios"]),
                t(&["Freemium, sans publicité intrusive", "Freemium, without intrusive ads", "Freemium, sin publicidad intrusiva"]),
                None,
            ))
            .child(div().attr("data-reveal", "").child(island("pricing", ctx.lang().code(), islands::pricing)))
            .child(p().class("note note--center").attr("data-reveal", "").child(icon("help")).text(t(&[
                "Prix indicatifs, à valider : les coûts des services d’analyse et des API seront mesurés avant de fixer les limites des abonnements.",
                "Indicative prices, to be confirmed: the costs of analysis services and APIs will be measured before setting the subscription limits.",
                "Precios orientativos, por confirmar: los costes de los servicios de análisis y de las API se medirán antes de fijar los límites de las suscripciones.",
            ]))),
    )
}

fn faq(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    section_("faq", "faq").child(
        container()
            .child(head(
                "22",
                "FAQ",
                t(&["Vos questions", "Your questions", "Tus preguntas"]),
                None,
            ))
            .child(
                div()
                    .class("faq__list")
                    .children(FAQ.iter().enumerate().map(|(i, (q, a))| {
                        details()
                            .class("faq__item")
                            .attr("data-reveal", "")
                            .style(format!("--i:{}", i % 4))
                            .child(
                                summary()
                                    .child(span().text(t(q)))
                                    .child(span().class("faq__plus").attr("aria-hidden", "true")),
                            )
                            .child(div().class("faq__answer").child(p().text(t(a))))
                    })),
            ),
    )
}

fn cta(ctx: &Ctx<'_>) -> Element {
    let t = |x: &T3| ctx.t(x);
    section_("cta", "cta").child(
        div()
            .class("cta__box")
            .child(canvas().class("cta__canvas").attr("data-net", "").attr("aria-hidden", "true"))
            .child(
                container()
                    .class("cta__inner")
                    .attr("data-reveal", "")
                    .child(span().class("cta__logo").child(logo("cta")))
                    .child(h2().class("cta__title").child(words(t(&["Avant de cliquer, vérifiez.", "Before you click, check.", "Antes de hacer clic, verifica."]))))
                    .child(p().class("cta__text").text(t(&[
                        "MailZen ne se contente pas de signaler un message suspect : il explique pourquoi, identifie la manipulation, recommande des actions concrètes et vous accompagne si vous avez déjà été exposé.",
                        "MailZen does not just flag a suspicious message: it explains why, identifies the manipulation, recommends concrete actions and supports you if you were already exposed.",
                        "MailZen no se limita a señalar un mensaje sospechoso: explica por qué, identifica la manipulación, recomienda acciones concretas y te acompaña si ya te has expuesto.",
                    ])))
                    .child(store_badges(ctx))
                    .child(
                        div()
                            .class("hero__ctas")
                            .child(btn(ctx.home("demo"), "btn--primary btn--lg").child(icon("radar")).child(span().text(t(&["Essayer la démo", "Try the demo", "Probar la demo"]))))
                            .child(external(btn(REPO, "btn--ghost btn--lg")).child(icon("github")).child(span().text(t(&["Suivre le projet", "Follow the project", "Seguir el proyecto"])))),
                    ),
            ),
    )
}

// ----- Text pages -------------------------------------------------------------------------

/// A page of text: a title, a lead and sections (title, paragraphs).
fn text_page(ctx: &Ctx<'_>, title: &str, lead: &str, sections: &[(T3, &[T3])]) -> Page {
    let t = |x: &T3| ctx.t(x);
    let content = main().class("doc").child(
        container()
            .child(
                header()
                    .class("doc__head")
                    .attr("data-reveal", "")
                    .child(
                        a().class("doc__back")
                            .href(ctx.home(""))
                            .child(icon("home"))
                            .child(span().text(t(&["Accueil", "Home", "Inicio"]))),
                    )
                    .child(h1().class("doc__title").child(words(title)))
                    .child(p().class("doc__lead").text(lead.to_owned())),
            )
            .child(
                div()
                    .class("doc__body")
                    .children(
                        sections
                            .iter()
                            .enumerate()
                            .map(|(i, (heading, paragraphs))| {
                                section()
                                    .class("doc__section")
                                    .attr("data-reveal", "")
                                    .child(
                                        h2().child(
                                            span().class("doc__num").text(format!("{:02}", i + 1)),
                                        )
                                        .text(t(heading)),
                                    )
                                    .children(paragraphs.iter().map(|p_| p().text(t(p_))))
                            }),
                    ),
            ),
    );
    layout(ctx, &format!("{title} — {BRAND}"), lead, content, false)
}

pub fn privacy_page(ctx: &Ctx<'_>) -> Page {
    let sections: &[(T3, &[T3])] = &[
        (
            [
                "Ce site ne vous suit pas",
                "This site does not track you",
                "Este sitio no te sigue",
            ],
            &[
                [
                    "Aucun cookie, aucun outil de mesure d’audience, aucune publicité, aucun pixel de suivi, aucune police ou ressource chargée depuis un service tiers.",
                    "No cookies, no analytics, no advertising, no tracking pixel, no font or resource loaded from a third-party service.",
                    "Sin cookies, sin analítica, sin publicidad, sin píxeles de seguimiento, sin fuentes ni recursos cargados desde servicios de terceros.",
                ],
                [
                    "Chaque page envoie une politique de sécurité du contenu (CSP) stricte qui n’autorise que son propre code.",
                    "Every page sends a strict Content Security Policy (CSP) that only allows its own code.",
                    "Cada página envía una política de seguridad de contenido (CSP) estricta que solo permite su propio código.",
                ],
            ],
        ),
        (
            [
                "La démo reste dans votre navigateur",
                "The demo stays in your browser",
                "La demo se queda en tu navegador",
            ],
            &[[
                "Le texte collé dans la démo est analysé localement par du code Rust compilé en WebAssembly. Il n’est ni envoyé, ni enregistré.",
                "The text pasted into the demo is analyzed locally by Rust code compiled to WebAssembly. It is neither sent nor stored.",
                "El texto pegado en la demo se analiza localmente con código Rust compilado a WebAssembly. No se envía ni se guarda.",
            ]],
        ),
        (
            [
                "Ce qui est stocké sur votre appareil",
                "What is stored on your device",
                "Lo que se guarda en tu dispositivo",
            ],
            &[[
                "Un indicateur de session pour ne jouer l’animation d’accueil qu’une fois, et le cache du service worker qui permet de consulter le site hors ligne. Vous pouvez les effacer à tout moment depuis les réglages de votre navigateur.",
                "A session flag so that the opening animation plays only once, and the service worker cache that lets you read the site offline. You can clear them at any time from your browser settings.",
                "Un indicador de sesión para que la animación de bienvenida solo se reproduzca una vez y la caché del service worker que permite consultar el sitio sin conexión. Puedes borrarlos cuando quieras desde los ajustes del navegador.",
            ]],
        ),
        (
            ["Hébergement", "Hosting", "Alojamiento"],
            &[[
                "Le site est servi par GitHub Pages et Heroku, qui peuvent conserver des journaux techniques (adresse IP, date, page demandée) pour assurer la sécurité de leurs services, selon leurs propres politiques.",
                "The site is served by GitHub Pages and Heroku, which may keep technical logs (IP address, date, page requested) to secure their services, under their own policies.",
                "El sitio lo sirven GitHub Pages y Heroku, que pueden conservar registros técnicos (dirección IP, fecha, página solicitada) para proteger sus servicios, según sus propias políticas.",
            ]],
        ),
        (
            ["L’application MailZen", "The MailZen app", "La app MailZen"],
            &[[
                "L’application suivra les mêmes principes : analyse locale prioritaire, pas de compte obligatoire, pas de stockage cloud par défaut des emails, consentement explicite pour toute analyse externe, aucune revente de données et aucune publicité basée sur le contenu de vos emails.",
                "The app will follow the same principles: local analysis first, no mandatory account, no cloud storage of emails by default, explicit consent for any external analysis, no data resale and no advertising based on the content of your emails.",
                "La app seguirá los mismos principios: análisis local prioritario, sin cuenta obligatoria, sin almacenamiento de correos en la nube por defecto, consentimiento explícito para cualquier análisis externo, sin reventa de datos y sin publicidad basada en el contenido de tus correos.",
            ]],
        ),
        (
            ["Vos droits", "Your rights", "Tus derechos"],
            &[[
                "Conformément au RGPD, vous disposez d’un droit d’accès, de rectification et d’effacement. Ce site ne collectant aucune donnée personnelle, il n’y a rien à vous restituer ; pour toute question, ouvrez une discussion sur le dépôt GitHub du projet. Vous pouvez aussi saisir la CNIL.",
                "Under the GDPR, you have the right of access, rectification and erasure. As this site collects no personal data, there is nothing to return; for any question, open a discussion on the project’s GitHub repository. You can also contact the CNIL.",
                "Según el RGPD, tienes derecho de acceso, rectificación y supresión. Como este sitio no recoge datos personales, no hay nada que devolverte; para cualquier pregunta, abre una conversación en el repositorio de GitHub del proyecto. También puedes acudir a la CNIL.",
            ]],
        ),
    ];
    text_page(
        ctx,
        ctx.t(&["Confidentialité du site", "Site privacy", "Privacidad del sitio"]),
        ctx.t(&[
            "Un site sur la protection de vos données se doit d’être exemplaire. Voici, simplement, ce qu’il fait et ne fait pas.",
            "A website about protecting your data has to set the example. Here, simply, is what it does and does not do.",
            "Un sitio sobre la protección de tus datos debe dar ejemplo. Esto es, sencillamente, lo que hace y lo que no.",
        ]),
        sections,
    )
}

pub fn legal_page(ctx: &Ctx<'_>) -> Page {
    let sections: &[(T3, &[T3])] = &[
        (
            ["Éditeur", "Publisher", "Editor"],
            &[[
                "Ce site est édité par Maxime Nathan Lestage, créateur du projet MailZen. Contact : via les discussions et tickets du dépôt GitHub maxlestage/MAILZEN.",
                "This site is published by Maxime Nathan Lestage, creator of the MailZen project. Contact: through the discussions and issues of the GitHub repository maxlestage/MAILZEN.",
                "Este sitio lo edita Maxime Nathan Lestage, creador del proyecto MailZen. Contacto: a través de las conversaciones e incidencias del repositorio de GitHub maxlestage/MAILZEN.",
            ]],
        ),
        (
            ["Hébergeurs", "Hosts", "Alojamiento"],
            &[
                [
                    "GitHub Pages — GitHub, Inc., 88 Colin P. Kelly Jr. Street, San Francisco, CA 94107, États-Unis.",
                    "GitHub Pages — GitHub, Inc., 88 Colin P. Kelly Jr. Street, San Francisco, CA 94107, United States.",
                    "GitHub Pages — GitHub, Inc., 88 Colin P. Kelly Jr. Street, San Francisco, CA 94107, Estados Unidos.",
                ],
                [
                    "Heroku — Salesforce, Inc., 415 Mission Street, San Francisco, CA 94105, États-Unis.",
                    "Heroku — Salesforce, Inc., 415 Mission Street, San Francisco, CA 94105, United States.",
                    "Heroku — Salesforce, Inc., 415 Mission Street, San Francisco, CA 94105, Estados Unidos.",
                ],
            ],
        ),
        (
            ["Statut du projet", "Project status", "Estado del proyecto"],
            &[[
                "MailZen est en cours de conception et de développement. Les écrans, chiffres, tableaux de bord et prix présentés sont illustratifs et peuvent évoluer. La démo est pédagogique et ne remplace ni le moteur d’analyse complet, ni l’avis d’un professionnel.",
                "MailZen is being designed and developed. The screens, figures, dashboards and prices shown are illustrative and may change. The demo is educational and replaces neither the full analysis engine nor professional advice.",
                "MailZen está en fase de diseño y desarrollo. Las pantallas, cifras, paneles y precios mostrados son ilustrativos y pueden cambiar. La demo es educativa y no sustituye al motor de análisis completo ni al consejo de un profesional.",
            ]],
        ),
        (
            [
                "Propriété intellectuelle",
                "Intellectual property",
                "Propiedad intelectual",
            ],
            &[
                [
                    "Les textes, le logo, le design et le code de ce site sont protégés. Toute reproduction sans autorisation est interdite, sauf mention contraire de la licence du dépôt.",
                    "The texts, logo, design and code of this site are protected. Any reproduction without permission is forbidden, unless the repository’s license says otherwise.",
                    "Los textos, el logotipo, el diseño y el código de este sitio están protegidos. Se prohíbe cualquier reproducción sin autorización, salvo que la licencia del repositorio diga lo contrario.",
                ],
                [
                    "Les marques citées (PayPal, Amazon, Apple, Google…) appartiennent à leurs propriétaires et ne servent qu’à illustrer des tentatives d’usurpation ; les exemples utilisent des domaines fictifs réservés (.example).",
                    "The brands mentioned (PayPal, Amazon, Apple, Google…) belong to their owners and only illustrate impersonation attempts; the examples use reserved fictional domains (.example).",
                    "Las marcas citadas (PayPal, Amazon, Apple, Google…) pertenecen a sus propietarios y solo ilustran intentos de suplantación; los ejemplos usan dominios ficticios reservados (.example).",
                ],
            ],
        ),
        (
            ["Crédits", "Credits", "Créditos"],
            &[[
                "Site écrit entièrement en Rust avec le framework Paquets : pages rendues par le serveur, îlots interactifs et animations compilés en WebAssembly.",
                "Site written entirely in Rust with the Paquets framework: server-rendered pages, interactive islands and animations compiled to WebAssembly.",
                "Sitio escrito íntegramente en Rust con el framework Paquets: páginas renderizadas en el servidor, islas interactivas y animaciones compiladas a WebAssembly.",
            ]],
        ),
    ];
    text_page(
        ctx,
        ctx.t(&["Mentions légales", "Legal notice", "Aviso legal"]),
        ctx.t(&[
            "Les informations légales du site de présentation de MailZen.",
            "The legal information of the MailZen presentation website.",
            "La información legal del sitio de presentación de MailZen.",
        ]),
        sections,
    )
}

pub fn not_found(ctx: &Ctx<'_>) -> Page {
    let t = |x: &T3| ctx.t(x);
    let content = main()
        .class("nf")
        .child(
            container()
                .class("nf__inner")
                .child(div().class("nf__code").attr("aria-hidden", "true").text("404"))
                .child(span().class("nf__shield").child(logo("nf")))
                .child(h1().class("nf__title").child(words(t(&["Cette page s’est volatilisée", "This page has vanished", "Esta página se ha esfumado"]))))
                .child(p().class("nf__text").text(t(&[
                    "Le lien est peut-être incorrect… Un bon réflexe : vérifier une adresse avant de la suivre.",
                    "The link may be wrong… A good habit: check an address before following it.",
                    "Puede que el enlace sea incorrecto… Un buen hábito: comprobar una dirección antes de seguirla.",
                ])))
                .child(
                    div().class("hero__ctas").child(
                        btn(ctx.home(""), "btn--primary btn--lg")
                            .child(icon("home"))
                            .child(span().text(t(&["Retour à l’accueil", "Back home", "Volver al inicio"]))),
                    ),
                ),
        );
    layout(
        ctx,
        &format!("404 — {BRAND}"),
        t(&[
            "Page introuvable.",
            "Page not found.",
            "Página no encontrada.",
        ]),
        content,
        false,
    )
    .status(404)
}

/// A JavaScript string literal that cannot close the `<script>` element.
fn js_string(s: &str) -> String {
    json_string(s)
}

/// The script of the pages a static host serves without knowing the visitor's language:
/// goes to `/{lang}/{target}` for the language of the address, else the browser's, else
/// French. Without JavaScript, a `<meta>` sends to French.
fn language_redirect(target: &str) -> String {
    let codes: Vec<String> = Lang::ALL.iter().map(|l| js_string(l.code())).collect();
    format!(
        concat!(
            "<script>(function(){{var b={base},L=[{codes}],c=null;",
            "var s=location.pathname.slice(b.length).split('/').filter(Boolean)[0];",
            "if(L.indexOf(s)>=0)c=s;",
            "var l=navigator.languages||[navigator.language||''];",
            "for(var i=0;i<l.length&&!c;i++){{var x=String(l[i]).slice(0,2).toLowerCase();",
            "if(L.indexOf(x)>=0)c=x}}",
            "location.replace(b+'/'+(c||'fr')+'/'+{target}+location.search+location.hash)}})()</script>",
            r#"<noscript><meta http-equiv="refresh" content="0; url={fallback}"/></noscript>"#,
        ),
        base = js_string(base()),
        codes = codes.join(","),
        target = js_string(target),
        fallback = link(&format!("/fr/{target}")),
    )
}

/// The page a static host serves at the root (`target` empty) and for an unknown address
/// (`target` = `404/`): it goes to the visitor's language by itself and links every
/// language for the others.
pub fn language_picker(site: &Site, origin: &str, target: &str) -> Page {
    let ctx = Ctx {
        site,
        route: Route::new(Lang::Fr, PageKind::NotFound),
        origin: origin.to_owned(),
    };
    let content = main().class("nf").child(
        container()
            .class("nf__inner")
            .child(span().class("nf__shield").child(logo("pick")))
            .child(h1().class("nf__title").text("MailZen"))
            .child(
                p().class("nf__text")
                    .text("Choisissez votre langue · Choose your language · Elige tu idioma"),
            )
            .child(div().class("hero__ctas").children(Lang::ALL.map(|l| {
                btn(
                    link(&format!("/{}/{target}", l.code())),
                    "btn--ghost btn--lg",
                )
                .attr("hreflang", l.code())
                .attr("lang", l.code())
                .child(span().text(l.name()))
                .child(icon("arrow"))
            }))),
    );
    layout(&ctx, "MailZen", ctx.t(&META_DESCRIPTION), content, false)
        .head(language_redirect(target))
}

/// The page of a route.
pub fn render(ctx: &Ctx<'_>) -> Page {
    match ctx.route.page {
        PageKind::Home => home(ctx),
        PageKind::Privacy => privacy_page(ctx),
        PageKind::Legal => legal_page(ctx),
        PageKind::NotFound => not_found(ctx),
    }
}
