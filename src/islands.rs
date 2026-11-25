//! The interactive parts of the site. Each island renders on the server like any view
//! and, compiled to WebAssembly, hydrates in the browser from the same code.

use paquets::prelude::*;

use crate::data::{PLANS, QUIZ, SAMPLES, SCENARIOS};
use crate::engine::{self, Report};
use crate::i18n::{Lang, T3};
use crate::icons::icon;

fn lang(props: &str) -> Lang {
    Lang::parse(props).unwrap_or(Lang::Fr)
}

/// Every island, registered under the name used by [`island`].
pub const ISLANDS: [(&str, paquets::active::IslandFn); 6] = [
    ("scan", scan),
    ("connect", connect),
    ("sos", sos),
    ("quiz", quiz),
    ("pricing", pricing),
    ("top", top),
];

/// Calls `f` after `ms` milliseconds in the browser; nothing on the server.
fn after(ms: i32, f: impl FnOnce() + 'static) {
    #[cfg(target_arch = "wasm32")]
    crate::client::later(ms, f);
    #[cfg(not(target_arch = "wasm32"))]
    let _ = (ms, f);
}

// ----- The scan demo -----------------------------------------------------------------------

/// The phases of the demo: 0 waiting, 1 to 5 the steps of a scan, 6 the report.
const DONE: u8 = 6;

const STEP_LABELS: [T3; 5] = [
    [
        "Import du message",
        "Importing the message",
        "Importando el mensaje",
    ],
    [
        "Extraction : expéditeur, liens, fichiers",
        "Extracting: sender, links, files",
        "Extrayendo: remitente, enlaces, archivos",
    ],
    [
        "Détection des menaces",
        "Detecting threats",
        "Detectando amenazas",
    ],
    [
        "Analyse du contexte et de la manipulation",
        "Analyzing context and manipulation",
        "Analizando contexto y manipulación",
    ],
    [
        "Rédaction du rapport",
        "Writing the report",
        "Redactando el informe",
    ],
];

/// Paste a message (or pick an example), analyze it in the browser, read the report.
pub fn scan(props: &str) -> Node {
    let lang = lang(props);
    let t = move |text: &T3| lang.t(text);
    let sample = use_state(0usize);
    let text = use_state(t(&SAMPLES[0].text).to_owned());
    let phase = use_state(0u8);
    let run = use_state(0u32);
    let report = use_state(None::<Report>);

    let start = move || {
        let id = run.get() + 1;
        run.set(id);
        report.set(Some(engine::analyze(&text.get())));
        phase.set(1);
        for step in 2..=DONE {
            after(i32::from(step - 1) * 620, move || {
                if run.get() == id {
                    phase.set(step);
                }
            });
        }
        #[cfg(not(target_arch = "wasm32"))]
        phase.set(DONE);
    };

    let tabs = div()
        .class("scan__samples")
        .attr("role", "group")
        .attr("aria-label", t(&["Exemples", "Examples", "Ejemplos"]))
        .children(SAMPLES.iter().enumerate().map(|(i, s)| {
            Node::from(
                button()
                    .class("chip chip--button")
                    .attr("type", "button")
                    .class_if("is-active", move || sample.get() == i)
                    .attr_dyn("aria-pressed", move || (sample.get() == i).to_string())
                    .on_click(move |_| {
                        sample.set(i);
                        text.set(lang.t(&SAMPLES[i].text).to_owned());
                        run.update(|r| *r += 1);
                        phase.set(0);
                        report.set(None);
                    })
                    .text(t(&s.label)),
            )
        }));

    let editor = div()
        .class("scan__editor")
        .class_if("is-scanning", move || (1..DONE).contains(&phase.get()))
        .child(
            div()
                .class("scan__bar")
                .child(span().class("dot dot--r"))
                .child(span().class("dot dot--y"))
                .child(span().class("dot dot--g"))
                .child(span().class("scan__file").text("message.eml")),
        )
        .child(
            textarea()
                .class("scan__text")
                .attr("rows", "10")
                .attr("spellcheck", "false")
                .attr(
                    "aria-label",
                    t(&["Message à analyser", "Message to analyze", "Mensaje que analizar"]),
                )
                .bind_value(text),
        )
        .child(div().class("scan__beam").attr("aria-hidden", "true"))
        .child(
            div()
                .class("scan__actions")
                .child(
                    button()
                        .class("btn btn--primary")
                        .attr("type", "button")
                        .on_click(move |_| start())
                        .child(icon("radar"))
                        .child(span().text(t(&["Analyser", "Analyze", "Analizar"]))),
                )
                .child(
                    button()
                        .class("btn btn--ghost")
                        .attr("type", "button")
                        .on_click(move |_| {
                            text.set(String::new());
                            run.update(|r| *r += 1);
                            phase.set(0);
                            report.set(None);
                        })
                        .child(icon("x"))
                        .child(span().text(t(&["Effacer", "Clear", "Borrar"]))),
                ),
        )
        .child(p().class("scan__note").child(icon("lock")).text(t(&[
            "Démo pédagogique : l’analyse tourne dans votre navigateur (Rust compilé en WebAssembly). Rien n’est envoyé.",
            "Educational demo: the analysis runs in your browser (Rust compiled to WebAssembly). Nothing is sent.",
            "Demo educativa: el análisis se ejecuta en tu navegador (Rust compilado a WebAssembly). No se envía nada.",
        ])));

    let output = div()
        .class("scan__out")
        .attr("aria-live", "polite")
        .children_dyn(move || {
            let p = phase.get();
            if p == 0 {
                return vec![
                    div()
                        .class("scan__idle")
                        .child(div().class("pulse-ring").child(icon("shield")))
                        .child(p_text(t(&[
                            "Choisissez un exemple ou collez un message, puis lancez l’analyse.",
                            "Pick an example or paste a message, then run the analysis.",
                            "Elige un ejemplo o pega un mensaje y lanza el análisis.",
                        ])))
                        .into(),
                ];
            }
            if p < DONE {
                return vec![
                    ol().class("scan__steps")
                        .children(STEP_LABELS.iter().enumerate().map(|(i, label)| {
                            let n = i as u8 + 1;
                            let state = if n < p {
                                "is-done"
                            } else if n == p {
                                "is-now"
                            } else {
                                "is-next"
                            };
                            Node::from(
                                li().class(state)
                                    .child(span().class("scan__tick").child(icon(if n < p {
                                        "check"
                                    } else {
                                        "radar"
                                    })))
                                    .child(span().text(t(label))),
                            )
                        }))
                        .into(),
                ];
            }
            match report.get() {
                Some(r) => vec![report_view(lang, &r).into()],
                None => Vec::new(),
            }
        });

    div()
        .class("scan")
        .child(tabs)
        .child(div().class("scan__grid").child(editor).child(output))
        .into()
}

fn p_text(text: &str) -> Element {
    p().text(text.to_owned())
}

/// The report of the demo.
fn report_view(lang: Lang, r: &Report) -> Element {
    let t = |text: &T3| lang.t(text);
    let verdict = r.verdict;
    let technical: Vec<_> = r
        .signals
        .iter()
        .filter(|s| !s.rule.is_manipulation())
        .collect();
    let manipulation: Vec<_> = r
        .signals
        .iter()
        .filter(|s| s.rule.is_manipulation())
        .collect();
    let mut card = div()
        .class("report")
        .class(format!("verdict--{}", verdict.class()))
        .child(
            div()
                .class("report__head")
                .child(
                    div()
                        .class("gauge")
                        .style(format!("--score:{}", r.score))
                        .attr("role", "img")
                        .attr("aria-label", format!("{}/100", r.score))
                        .child(strong().text(r.score.to_string()))
                        .child(small().text("/100")),
                )
                .child(
                    div()
                        .class("report__verdict")
                        .child(span().class("verdict-badge").text(t(verdict.title())))
                        .child(p().class("report__confidence").text(format!(
                            "{} : {}",
                            t(&["Niveau de confiance", "Confidence", "Confianza"]),
                            t(r.confidence_label())
                        )))
                        .child(p().class("report__count").text(format!(
                            "{} {}",
                            r.signals.len(),
                            t(&[
                                "indicateurs détectés",
                                "indicators detected",
                                "indicadores detectados"
                            ])
                        ))),
                ),
        );
    if !technical.is_empty() {
        card = card.child(h4().text(t(&[
            "Signaux techniques",
            "Technical signals",
            "Señales técnicas",
        ])));
        card = card.child(
            ul().class("signals")
                .children(technical.iter().enumerate().map(|(i, s)| {
                    Node::from(
                        li().style(format!("--i:{i}"))
                            .child(
                                span()
                                    .class("signals__family")
                                    .text(t(s.rule.family().label())),
                            )
                            .child(strong().text(t(s.rule.title())))
                            .child(code().text(s.evidence.clone())),
                    )
                })),
        );
    }
    if !manipulation.is_empty() {
        card = card.child(h4().text(t(&[
            "Techniques de manipulation",
            "Manipulation techniques",
            "Técnicas de manipulación",
        ])));
        card = card.child(
            div()
                .class("chips")
                .children(manipulation.iter().enumerate().map(|(i, s)| {
                    Node::from(
                        span()
                            .class("chip chip--warn")
                            .style(format!("--i:{i}"))
                            .attr("title", format!("« {} »", s.evidence))
                            .text(t(s.rule.title())),
                    )
                })),
        );
    }
    if !r.links.is_empty() {
        card = card.child(h4().text(t(&[
            "Liens analysés",
            "Links analyzed",
            "Enlaces analizados",
        ])));
        card = card.child(ul().class("links").children(r.links.iter().map(|l| {
            Node::from(
                li().class(if l.risky { "is-risky" } else { "is-ok" })
                    .child(icon(if l.risky { "alert" } else { "check" }))
                    .child(code().text(l.host.clone())),
            )
        })));
    }
    card.child(
        div()
            .class("report__advice")
            .child(icon("shield"))
            .child(p().text(t(verdict.advice()))),
    )
}

// ----- Mailbox connection ----------------------------------------------------------------

/// The mailboxes MailZen will connect to: (name, how, CSS modifier).
pub const PROVIDERS: [(&str, T3, &str); 5] = [
    (
        "Gmail",
        [
            "Connexion Google (OAuth)",
            "Google sign-in (OAuth)",
            "Inicio de sesión de Google (OAuth)",
        ],
        "gmail",
    ),
    (
        "Outlook",
        [
            "Connexion Microsoft (OAuth)",
            "Microsoft sign-in (OAuth)",
            "Inicio de sesión de Microsoft (OAuth)",
        ],
        "outlook",
    ),
    (
        "iCloud Mail",
        [
            "Mot de passe d’app Apple",
            "Apple app-specific password",
            "Contraseña de app de Apple",
        ],
        "icloud",
    ),
    (
        "Yahoo Mail",
        [
            "Connexion Yahoo (OAuth)",
            "Yahoo sign-in (OAuth)",
            "Inicio de sesión de Yahoo (OAuth)",
        ],
        "yahoo",
    ),
    (
        "IMAP",
        [
            "Toute autre boîte mail",
            "Any other mailbox",
            "Cualquier otro buzón",
        ],
        "imap",
    ),
];

const CONNECT_STEPS: [T3; 4] = [
    [
        "Choix du compte",
        "Choosing the account",
        "Elección de la cuenta",
    ],
    [
        "Autorisation en lecture seule",
        "Read-only authorization",
        "Autorización de solo lectura",
    ],
    [
        "Aucun mot de passe enregistré par MailZen",
        "No password stored by MailZen",
        "MailZen no guarda ninguna contraseña",
    ],
    [
        "Analyse des nouveaux emails sur l’appareil",
        "New emails analyzed on the device",
        "Análisis de los correos nuevos en el dispositivo",
    ],
];

/// "Connect your mailbox": pick a provider, watch the connection flow. The real
/// connection comes with the app; the site reads nothing.
pub fn connect(props: &str) -> Node {
    let lang = lang(props);
    let t = move |text: &T3| lang.t(text);
    let chosen = use_state(None::<usize>);
    let step = use_state(0u8);
    let run = use_state(0u32);
    let pick = move |i: usize| {
        let id = run.get() + 1;
        run.set(id);
        chosen.set(Some(i));
        step.set(1);
        for s in 2..=5u8 {
            after(i32::from(s - 1) * 700, move || {
                if run.get() == id {
                    step.set(s);
                }
            });
        }
        #[cfg(not(target_arch = "wasm32"))]
        step.set(5);
    };
    div()
        .class("connect")
        .children_dyn(move || {
            let Some(index) = chosen.get() else {
                return vec![
                    div()
                        .class("providers")
                        .children(PROVIDERS.iter().enumerate().map(|(i, (name, how, class))| {
                            Node::from(
                                button()
                                    .class("provider")
                                    .class(format!("provider--{class}"))
                                    .attr("type", "button")
                                    .style(format!("--i:{i}"))
                                    .on_click(move |_| pick(i))
                                    .child(span().class("provider__logo").child(icon("mail")))
                                    .child(
                                        span()
                                            .class("provider__text")
                                            .child(strong().text(*name))
                                            .child(small().text(t(how))),
                                    )
                                    .child(icon("arrow")),
                            )
                        }))
                        .into(),
                    ul().class("connect__promises")
                        .children(
                            [
                                ("eye", ["Lecture seule", "Read-only", "Solo lectura"]),
                                ("key", ["Jamais votre mot de passe", "Never your password", "Nunca tu contraseña"]),
                                ("phone", ["Analyse sur l’appareil", "Analysis on the device", "Análisis en el dispositivo"]),
                                ("x", ["Déconnexion en un geste", "Disconnect in one tap", "Desconexión con un toque"]),
                            ]
                            .into_iter()
                            .map(|(ic, label)| {
                                Node::from(li().child(icon(ic)).child(span().text(lang.t(&label))))
                            }),
                        )
                        .into(),
                ];
            };
            let (name, _, class) = PROVIDERS[index];
            let now = step.get();
            let mut card = div()
                .class("connect__card")
                .class(format!("provider--{class}"))
                .child(
                    div()
                        .class("connect__head")
                        .child(span().class("provider__logo").child(icon("mail")))
                        .child(span().class("connect__link").attr("aria-hidden", "true").child(i()).child(i()).child(i()))
                        .child(span().class("connect__shield").child(icon("shield")))
                        .child(strong().text(format!("{name} → MailZen"))),
                )
                .child(ol().class("scan__steps connect__steps").children(
                    CONNECT_STEPS.iter().enumerate().map(|(k, label)| {
                        let n = k as u8 + 1;
                        let state = if n < now {
                            "is-done"
                        } else if n == now {
                            "is-now"
                        } else {
                            "is-next"
                        };
                        Node::from(
                            li().class(state)
                                .child(span().class("scan__tick").child(icon(if n < now { "check" } else { "radar" })))
                                .child(span().text(t(label))),
                        )
                    }),
                ));
            if now >= 5 {
                card = card.child(
                    div()
                        .class("connect__done")
                        .child(p().child(strong().text(t(&[
                            "Le parcours est prêt.",
                            "The flow is ready.",
                            "El recorrido está listo.",
                        ]))).text(t(&[
                            " La connexion directe à votre boîte arrive avec l’app MailZen pour iOS et Android. Ce site ne lit aucun email : en attendant, analysez un message dans la démo.",
                            " Direct connection to your mailbox comes with the MailZen app for iOS and Android. This site reads no email: meanwhile, analyze a message in the demo.",
                            " La conexión directa a tu buzón llega con la app MailZen para iOS y Android. Este sitio no lee ningún correo: mientras tanto, analiza un mensaje en la demo.",
                        ])))
                        .child(
                            div()
                                .class("connect__actions")
                                .child(
                                    a().class("btn btn--primary")
                                        .href("#demo")
                                        .child(icon("radar"))
                                        .child(span().text(t(&["Analyser un email", "Analyze an email", "Analizar un correo"]))),
                                )
                                .child(
                                    a().class("btn btn--ghost")
                                        .href("message://")
                                        .child(icon("mail"))
                                        .child(span().text(t(&["Ouvrir l’app Mail", "Open the Mail app", "Abrir la app Mail"]))),
                                )
                                .child(
                                    button()
                                        .class("btn btn--ghost")
                                        .attr("type", "button")
                                        .on_click(move |_| {
                                            run.update(|r| *r += 1);
                                            chosen.set(None);
                                            step.set(0);
                                        })
                                        .child(icon("reply"))
                                        .child(span().text(t(&["Autre compte", "Another account", "Otra cuenta"]))),
                                ),
                        ),
                );
            }
            vec![card.into()]
        })
        .into()
}

// ----- SOS Cyber ---------------------------------------------------------------------------

/// "What happened?": a scenario, then its steps.
pub fn sos(props: &str) -> Node {
    let lang = lang(props);
    let chosen = use_state(0usize);
    div()
        .class("sos")
        .child(
            div()
                .class("sos__choices")
                .attr("role", "group")
                .attr(
                    "aria-label",
                    lang.t(&["Que s’est-il passé ?", "What happened?", "¿Qué ha pasado?"]),
                )
                .children(SCENARIOS.iter().enumerate().map(|(i, s)| {
                    Node::from(
                        button()
                            .class("sos__choice")
                            .attr("type", "button")
                            .class_if("is-active", move || chosen.get() == i)
                            .attr_dyn("aria-pressed", move || (chosen.get() == i).to_string())
                            .on_click(move |_| chosen.set(i))
                            .child(icon(s.icon))
                            .child(span().text(lang.t(&s.title))),
                    )
                })),
        )
        .child(div().class("sos__plan").children_dyn(move || {
            let s = &SCENARIOS[chosen.get()];
            vec![
                div()
                    .class("sos__card")
                    .child(
                        p().class("sos__title")
                            .child(icon(s.icon))
                            .text(lang.t(&s.title)),
                    )
                    .child(
                        ol().class("sos__steps")
                            .children(s.steps.iter().enumerate().map(|(i, step)| {
                                Node::from(
                                    li().style(format!("--i:{i}"))
                                        .child(span().class("sos__num").text((i + 1).to_string()))
                                        .child(span().text(lang.t(step))),
                                )
                            })),
                    )
                    .into(),
            ]
        }))
        .into()
}

// ----- ZenLearn quiz -----------------------------------------------------------------------

/// "Real or fake link?": six questions, a score and a badge.
pub fn quiz(props: &str) -> Node {
    let lang = lang(props);
    let t = move |text: &T3| lang.t(text);
    let index = use_state(0usize);
    let answer = use_state(None::<bool>);
    let score = use_state(0usize);
    let answer_with = move |real: bool| {
        if answer.get().is_some() {
            return;
        }
        let right = QUIZ[index.get()].1 == real;
        if right {
            score.update(|s| *s += 1);
        }
        answer.set(Some(right));
    };
    div()
        .class("quiz")
        .children_dyn(move || {
            let i = index.get();
            if i >= QUIZ.len() {
                let s = score.get();
                let badge = match s {
                    6 => t(&["Gardien zen", "Zen guardian", "Guardián zen"]),
                    4 | 5 => t(&["Œil de lynx", "Eagle eye", "Ojo de lince"]),
                    _ => t(&[
                        "Apprenti vigilant",
                        "Vigilant apprentice",
                        "Aprendiz atento",
                    ]),
                };
                return vec![
                    div()
                        .class("quiz__end")
                        .child(div().class("quiz__badge").child(icon("badge")))
                        .child(p().class("quiz__score").text(format!("{s}/{}", QUIZ.len())))
                        .child(p().class("quiz__badge-name").text(badge))
                        .child(
                            button()
                                .class("btn btn--ghost")
                                .attr("type", "button")
                                .on_click(move |_| {
                                    index.set(0);
                                    score.set(0);
                                    answer.set(None);
                                })
                                .child(icon("arrow"))
                                .child(span().text(t(&[
                                    "Rejouer",
                                    "Play again",
                                    "Jugar otra vez",
                                ]))),
                        )
                        .into(),
                ];
            }
            let (url, real, why) = &QUIZ[i];
            let state = answer.get();
            let mut card = div()
                .class("quiz__card")
                .child(
                    div()
                        .class("quiz__progress")
                        .style(format!("--p:{}", i as f64 / QUIZ.len() as f64))
                        .child(span()),
                )
                .child(p().class("quiz__count").text(format!(
                    "{} {}/{}",
                    t(&["Question", "Question", "Pregunta"]),
                    i + 1,
                    QUIZ.len()
                )))
                .child(p().class("quiz__q").text(t(&[
                    "Ce lien est-il authentique ?",
                    "Is this link genuine?",
                    "¿Este enlace es auténtico?",
                ])))
                .child(code().class("quiz__url").text(*url))
                .child(
                    div()
                        .class("quiz__buttons")
                        .child(
                            button()
                                .class("btn btn--safe")
                                .attr("type", "button")
                                .bool_attr("disabled", move || answer.get().is_some())
                                .on_click(move |_| answer_with(true))
                                .child(icon("check"))
                                .child(span().text(t(&["Vrai lien", "Real link", "Enlace real"]))),
                        )
                        .child(
                            button()
                                .class("btn btn--danger")
                                .attr("type", "button")
                                .bool_attr("disabled", move || answer.get().is_some())
                                .on_click(move |_| answer_with(false))
                                .child(icon("x"))
                                .child(span().text(t(&["Faux lien", "Fake link", "Enlace falso"]))),
                        ),
                );
            if let Some(right) = state {
                card = card.child(
                    div()
                        .class(if right {
                            "quiz__why is-right"
                        } else {
                            "quiz__why is-wrong"
                        })
                        .child(strong().text(if right {
                            t(&["Bien vu !", "Well spotted!", "¡Bien visto!"])
                        } else {
                            t(&["Pas tout à fait.", "Not quite.", "No exactamente."])
                        }))
                        .child(span().text(format!(
                            " {} {}",
                            if *real {
                                t(&["C’est le vrai.", "It is the real one.", "Es el auténtico."])
                            } else {
                                t(&["C’est un piège.", "It is a trap.", "Es una trampa."])
                            },
                            t(why)
                        )))
                        .child(
                            button()
                                .class("btn btn--primary btn--sm")
                                .attr("type", "button")
                                .on_click(move |_| {
                                    answer.set(None);
                                    index.update(|i| *i += 1);
                                })
                                .child(span().text(t(&["Suivant", "Next", "Siguiente"])))
                                .child(icon("arrow")),
                        ),
                );
            }
            vec![card.into()]
        })
        .into()
}

// ----- Pricing -----------------------------------------------------------------------------

/// The four plans, with a monthly / yearly switch.
pub fn pricing(props: &str) -> Node {
    let lang = lang(props);
    let t = move |text: &T3| lang.t(text);
    let yearly = use_state(false);
    div()
        .class("pricing")
        .child(
            div()
                .class("switch")
                .class_if("is-yearly", move || yearly.get())
                .attr("role", "group")
                .child(span().class("switch__pill").attr("aria-hidden", "true"))
                .child(
                    button()
                        .attr("type", "button")
                        .attr_dyn("aria-pressed", move || (!yearly.get()).to_string())
                        .on_click(move |_| yearly.set(false))
                        .text(t(&["Mensuel", "Monthly", "Mensual"])),
                )
                .child(
                    button()
                        .attr("type", "button")
                        .attr_dyn("aria-pressed", move || yearly.get().to_string())
                        .on_click(move |_| yearly.set(true))
                        .text(t(&["Annuel", "Yearly", "Anual"]))
                        .child(span().class("switch__save").text("-33 %")),
                ),
        )
        .child(
            div()
                .class("plans")
                .children(PLANS.iter().enumerate().map(|(i, plan)| {
                    let mut card = article()
                        .class("plan")
                        .style(format!("--i:{i}"))
                        .attr("data-tilt", "6")
                        .child(span().class("plan__name").text(plan.name))
                        .child(span().class("plan__tag").text(t(&plan.tag)));
                    if plan.featured {
                        card = card.class("plan--featured").child(
                            span().class("plan__ribbon").text(t(&[
                                "Recommandé",
                                "Recommended",
                                "Recomendado",
                            ])),
                        );
                    }
                    let price = match plan.price {
                        Some((month, year)) => p().class("plan__price").text_dyn(move || {
                            lang.t(if yearly.get() { &year } else { &month }).to_owned()
                        }),
                        None => p().class("plan__price").text(t(&[
                            "Sur devis",
                            "On quote",
                            "Bajo presupuesto",
                        ])),
                    };
                    Node::from(
                        card.child(price)
                            .child(ul().children(plan.points.iter().map(|pt| {
                                Node::from(li().child(icon("check")).child(span().text(t(pt))))
                            }))),
                    )
                })),
        )
        .into()
}

// ----- Back to top -------------------------------------------------------------------------

/// The footer's "back to top" button, with the reading progress around it.
pub fn top(props: &str) -> Node {
    let lang = lang(props);
    button()
        .class("to-top")
        .attr("type", "button")
        .attr(
            "aria-label",
            lang.t(&["Revenir en haut", "Back to top", "Volver arriba"]),
        )
        .attr("data-cursor", lang.t(&["Haut", "Top", "Arriba"]))
        .on_click(|_| {
            #[cfg(target_arch = "wasm32")]
            crate::client::scroll_to_top();
        })
        .child(span().class("to-top__ring").attr("aria-hidden", "true"))
        .child(icon("up"))
        .into()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_island_renders_on_the_server_in_every_language() {
        for lang in Lang::ALL {
            for (name, island_fn) in ISLANDS {
                let html = island(name, lang.code(), island_fn).render();
                assert!(html.contains(&format!("data-island=\"{name}\"")));
            }
        }
    }

    #[test]
    fn the_connection_lists_every_provider() {
        let html = island("connect", "fr", connect).render();
        for (name, _, _) in PROVIDERS {
            assert!(html.contains(name), "{name}");
        }
    }

    #[test]
    fn the_scan_demo_shows_its_first_sample() {
        let html = island("scan", "en", scan).render();
        assert!(html.contains("paypaI-account-check.example"));
        assert!(html.contains("Analyze"));
    }

    #[test]
    fn the_report_names_its_verdict() {
        let report = engine::analyze(Lang::Fr.t(&SAMPLES[0].text));
        let html = Node::from(report_view(Lang::Fr, &report)).render();
        assert!(html.contains("Danger élevé"));
        assert!(html.contains("verdict--danger"));
    }
}
