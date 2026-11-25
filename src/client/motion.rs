//! Page motion that CSS cannot do alone: the preloader, scroll reveals, the progress bar,
//! the navigation that hides, parallax, counters, the typing headline, the menu, the
//! scroll-spy, ripples, the cursor, magnetic buttons, tilted cards and spotlights.
//! Everything degrades to a static page.

use std::cell::Cell;
use std::rc::Rc;

use wasm_bindgen::JsCast;
use wasm_bindgen::prelude::*;
use web_sys::{
    Element, HtmlElement, IntersectionObserver, IntersectionObserverEntry, IntersectionObserverInit,
};

use super::{all, document, later, matches, on, on_passive, reduced_motion, request_frame, window};
use crate::i18n::{Lang, number};

pub fn init() {
    let root: HtmlElement = document().document_element().unwrap().unchecked_into();
    intro(&root);
    reveals();
    // Only now may the CSS hide what is not revealed yet: what is already on screen was
    // marked just above, so nothing blinks.
    let _ = root.class_list().add_1("hydrated");
    scroll_state();
    counters();
    menu(&root);
    scroll_spy();
    typing();
    ripples();
    spotlights();
    if matches("(hover: hover) and (pointer: fine)") && !reduced_motion() {
        let _ = root.class_list().add_1("has-cursor");
        cursor();
        magnetic();
        tilt();
        hero_mouse();
    }
}

fn observe(
    selector: &str,
    options: &IntersectionObserverInit,
    f: impl Fn(&IntersectionObserverEntry, &IntersectionObserver) + 'static,
) {
    let callback = Closure::<dyn Fn(js_sys::Array, IntersectionObserver)>::new(
        move |entries: js_sys::Array, io: IntersectionObserver| {
            for entry in entries.iter() {
                if let Ok(entry) = entry.dyn_into::<IntersectionObserverEntry>() {
                    f(&entry, &io);
                }
            }
        },
    );
    if let Ok(io) =
        IntersectionObserver::new_with_options(callback.as_ref().unchecked_ref(), options)
    {
        for el in all(selector) {
            io.observe(&el);
        }
    }
    callback.forget();
}

pub fn viewport_height() -> f64 {
    window()
        .inner_height()
        .ok()
        .and_then(|h| h.as_f64())
        .unwrap_or(800.0)
}

fn set(el: &HtmlElement, name: &str, value: &str) {
    let _ = el.style().set_property(name, value);
}

/// The preloader plays once per browser session; a tap skips it.
fn intro(root: &HtmlElement) {
    if all(".loader").is_empty() {
        return;
    }
    let storage = window().session_storage().ok().flatten();
    let seen = storage
        .as_ref()
        .and_then(|s| s.get_item("mailzen-intro").ok().flatten())
        .is_some();
    if seen || reduced_motion() {
        let _ = root.class_list().add_1("intro-seen");
    } else if let Some(storage) = storage {
        let _ = storage.set_item("mailzen-intro", "1");
    }
    for loader in all(".loader") {
        let root = root.clone();
        on(&loader, "click", move |_: web_sys::Event| {
            let _ = root.class_list().add_1("intro-seen");
        });
    }
    // The percentage of the loader counts up with its bar.
    if let Some(percent) = all(".loader__percent").into_iter().next() {
        let mut start = None;
        request_frame(move |now| {
            let t0 = *start.get_or_insert(now);
            let p = ((now - t0) / 1900.0).min(1.0);
            let eased = 1.0 - (1.0 - p).powi(3);
            percent.set_text_content(Some(&format!("{:.0}%", eased * 100.0)));
            p < 1.0
        });
    }
}

/// `[data-reveal]` elements animate in when they scroll into view.
fn reveals() {
    let height = viewport_height();
    for el in all("[data-reveal]") {
        let rect = el.get_bounding_client_rect();
        if rect.top() < height * 0.92 && rect.bottom() > 0.0 {
            let _ = el.class_list().add_1("in");
        }
    }
    let options = IntersectionObserverInit::new();
    options.set_threshold(&JsValue::from_f64(0.0));
    options.set_root_margin("0px 0px -8% 0px");
    observe("[data-reveal]:not(.in)", &options, |entry, io| {
        if entry.is_intersecting() {
            let target = entry.target();
            let _ = target.class_list().add_1("in");
            io.unobserve(&target);
        }
    });
    // Safety net for browsers that miss an intersection (Safari on iOS during momentum
    // scrolling): every scroll reveals what is already on screen.
    let ticking = Rc::new(Cell::new(false));
    on_passive(&window(), "scroll", move |_: web_sys::Event| {
        if ticking.replace(true) {
            return;
        }
        let ticking = ticking.clone();
        request_frame(move |_| {
            ticking.set(false);
            let height = viewport_height();
            for el in all("[data-reveal]:not(.in)") {
                let rect = el.get_bounding_client_rect();
                if rect.top() < height && rect.bottom() > 0.0 {
                    let _ = el.class_list().add_1("in");
                }
            }
            false
        });
    });
}

/// The progress bar, the navigation, parallax, and the progress of the timelines
/// (`[data-progress]`, `--p` from 0 to 1) and of the hero (`--scroll`).
fn scroll_state() {
    let root: HtmlElement = document().document_element().unwrap().unchecked_into();
    let progress = all(".progress");
    let nav = all("#nav");
    let timelines = all("[data-progress]");
    let hero = all(".hero");
    let still = reduced_motion();
    let parallax: Vec<(HtmlElement, f64)> = if still {
        Vec::new()
    } else {
        all("[data-speed]")
            .into_iter()
            .map(|el| {
                let speed = el
                    .get_attribute("data-speed")
                    .and_then(|s| s.parse().ok())
                    .unwrap_or(0.0);
                (el, speed)
            })
            .collect()
    };
    let last = Rc::new(Cell::new(0.0f64));
    let update = move || {
        let y = window().scroll_y().unwrap_or(0.0);
        let height = viewport_height();
        let max = (f64::from(root.scroll_height()) - height).max(1.0);
        let page = (y / max).clamp(0.0, 1.0);
        set(&root, "--page", &format!("{page:.4}"));
        for bar in &progress {
            set(bar, "transform", &format!("scaleX({page:.4})"));
        }
        let menu_open = root.class_list().contains("menu-open");
        for nav in &nav {
            let list = nav.class_list();
            let _ = list.toggle_with_force("nav--scrolled", y > 24.0);
            if y > last.get() + 2.0 && y > 480.0 && !menu_open {
                let _ = list.add_1("nav--hidden");
            } else if y < last.get() - 2.0 {
                let _ = list.remove_1("nav--hidden");
            }
        }
        last.set(y);
        for (el, speed) in &parallax {
            let rect = el.get_bounding_client_rect();
            let center = rect.top() + rect.height() / 2.0 - height / 2.0;
            set(
                el,
                "transform",
                &format!("translate3d(0,{:.1}px,0)", -center * speed),
            );
        }
        for el in &timelines {
            let rect = el.get_bounding_client_rect();
            let p = ((height * 0.65 - rect.top()) / rect.height().max(1.0)).clamp(0.0, 1.0);
            set(el, "--p", &format!("{p:.4}"));
        }
        if !still {
            for el in &hero {
                set(
                    el,
                    "--scroll",
                    &format!("{:.4}", (y / height).clamp(0.0, 1.0)),
                );
            }
        }
    };
    update();
    let update = Rc::new(update);
    let ticking = Rc::new(Cell::new(false));
    for event in ["scroll", "resize"] {
        let (update, ticking) = (update.clone(), ticking.clone());
        on_passive(&window(), event, move |_: web_sys::Event| {
            if ticking.replace(true) {
                return;
            }
            let (update, ticking) = (update.clone(), ticking.clone());
            request_frame(move |_| {
                ticking.set(false);
                update();
                false
            });
        });
    }
}

/// Numbers count up when they come into view (`data-count`, `data-suffix`).
fn counters() {
    let lang = document()
        .document_element()
        .and_then(|h| h.get_attribute("lang"))
        .and_then(|l| Lang::parse(&l))
        .unwrap_or(Lang::Fr);
    let options = IntersectionObserverInit::new();
    options.set_threshold(&JsValue::from_f64(0.4));
    observe("[data-count]", &options, move |entry, io| {
        if !entry.is_intersecting() {
            return;
        }
        let el: HtmlElement = entry.target().unchecked_into();
        io.unobserve(&el);
        let data = el.dataset();
        let target: f64 = data
            .get("count")
            .and_then(|v| v.parse().ok())
            .unwrap_or(0.0);
        let prefix = data.get("prefix").unwrap_or_default();
        let suffix = data.get("suffix").unwrap_or_default();
        let render = move |v: f64| format!("{prefix}{}{suffix}", number(lang, v.round() as u64));
        if reduced_motion() {
            el.set_text_content(Some(&render(target)));
            return;
        }
        let mut start = None;
        request_frame(move |now| {
            let t0 = *start.get_or_insert(now);
            let p = ((now - t0) / 1600.0).min(1.0);
            let eased = if p >= 1.0 {
                1.0
            } else {
                1.0 - 2f64.powf(-10.0 * p)
            };
            el.set_text_content(Some(&render(target * eased)));
            p < 1.0
        });
    });
}

/// The mobile menu: its button, its links, Escape.
fn menu(root: &HtmlElement) {
    for button in all("[data-toggle-menu]") {
        let (root, target) = (root.clone(), button.clone());
        on(&button, "click", move |_: web_sys::Event| {
            let open = root.class_list().toggle("menu-open").unwrap_or(false);
            let _ = target.set_attribute("aria-expanded", if open { "true" } else { "false" });
        });
    }
    let close = |root: &HtmlElement| {
        let _ = root.class_list().remove_1("menu-open");
        for button in all("[data-toggle-menu]") {
            let _ = button.set_attribute("aria-expanded", "false");
        }
    };
    for el in all(".menu a, .menu__scrim") {
        let root = root.clone();
        on(&el, "click", move |_: web_sys::Event| close(&root));
    }
    let root = root.clone();
    on(&window(), "keydown", move |e: web_sys::KeyboardEvent| {
        if e.key() == "Escape" {
            close(&root);
        }
    });
}

/// The navigation highlights the section being read.
fn scroll_spy() {
    let links = all(".nav__links a[data-spy]");
    if links.is_empty() {
        return;
    }
    let options = IntersectionObserverInit::new();
    options.set_root_margin("-45% 0px -50% 0px");
    observe("main section[id]", &options, move |entry, _| {
        if !entry.is_intersecting() {
            return;
        }
        let id = entry.target().id();
        for link in &links {
            let active = link.get_attribute("data-spy").as_deref() == Some(id.as_str());
            let _ = link.class_list().toggle_with_force("is-active", active);
        }
    });
}

/// `[data-words="a|b|c"]`: the words are typed, erased, and typed again in turn.
fn typing() {
    for el in all("[data-words]") {
        let words: Vec<String> = el
            .get_attribute("data-words")
            .unwrap_or_default()
            .split('|')
            .map(str::to_owned)
            .filter(|w| !w.is_empty())
            .collect();
        if words.len() < 2 || reduced_motion() {
            continue;
        }
        let state = Rc::new(Cell::new((0usize, words[0].chars().count(), false)));
        let mut last = 0.0f64;
        request_frame(move |now| {
            let (word, shown, erasing) = state.get();
            let chars: Vec<char> = words[word].chars().collect();
            let wait = if !erasing && shown == chars.len() {
                1800.0
            } else if erasing {
                35.0
            } else {
                70.0
            };
            if now - last < wait {
                return true;
            }
            last = now;
            let next = if erasing {
                if shown == 0 {
                    ((word + 1) % words.len(), 0, false)
                } else {
                    (word, shown - 1, true)
                }
            } else if shown == chars.len() {
                (word, shown, true)
            } else {
                (word, shown + 1, false)
            };
            state.set(next);
            let text: String = words[next.0].chars().take(next.1).collect();
            el.set_text_content(Some(&text));
            true
        });
    }
}

/// A ripple grows from the point where a button is pressed.
fn ripples() {
    if reduced_motion() {
        return;
    }
    on(&document(), "pointerdown", |e: web_sys::PointerEvent| {
        let Some(button) = e
            .target()
            .and_then(|t| t.dyn_into::<Element>().ok())
            .and_then(|t| {
                t.closest(".btn, .chip--button, .sos__choice")
                    .ok()
                    .flatten()
            })
        else {
            return;
        };
        let Ok(ripple) = document().create_element("span") else {
            return;
        };
        let rect = button.get_bounding_client_rect();
        let size = rect.width().max(rect.height()) * 2.2;
        let ripple: HtmlElement = ripple.unchecked_into();
        ripple.set_class_name("ripple");
        set(&ripple, "width", &format!("{size:.0}px"));
        set(&ripple, "height", &format!("{size:.0}px"));
        set(
            &ripple,
            "left",
            &format!(
                "{:.0}px",
                f64::from(e.client_x()) - rect.left() - size / 2.0
            ),
        );
        set(
            &ripple,
            "top",
            &format!("{:.0}px", f64::from(e.client_y()) - rect.top() - size / 2.0),
        );
        let _ = button.append_child(&ripple);
        later(700, move || ripple.remove());
    });
}

/// `[data-spot]` cards light up under the finger or the pointer.
fn spotlights() {
    for el in all("[data-spot]") {
        let target = el.clone();
        on_passive(&el, "pointermove", move |e: web_sys::PointerEvent| {
            let r = target.get_bounding_client_rect();
            set(
                &target,
                "--mx",
                &format!("{:.1}px", f64::from(e.client_x()) - r.left()),
            );
            set(
                &target,
                "--my",
                &format!("{:.1}px", f64::from(e.client_y()) - r.top()),
            );
        });
    }
}

/// A dot follows the pointer, a ring catches up with it and grows over links.
fn cursor() {
    let (Some(dot), Some(ring)) = (
        all(".cursor__dot").into_iter().next(),
        all(".cursor__ring").into_iter().next(),
    ) else {
        return;
    };
    let target = Rc::new(Cell::new((-100.0f64, -100.0f64)));
    {
        let (target, dot, ring) = (target.clone(), dot.clone(), ring.clone());
        on_passive(&window(), "pointermove", move |e: web_sys::PointerEvent| {
            let (x, y) = (f64::from(e.client_x()), f64::from(e.client_y()));
            target.set((x, y));
            set(&dot, "transform", &format!("translate3d({x}px,{y}px,0)"));
            let hovered = e
                .target()
                .and_then(|t| t.dyn_into::<Element>().ok())
                .and_then(|t| {
                    t.closest("a, button, textarea, summary, [data-cursor]")
                        .ok()
                        .flatten()
                });
            let label = hovered
                .as_ref()
                .and_then(|el| el.get_attribute("data-cursor"))
                .unwrap_or_default();
            let list = ring.class_list();
            let _ = list.toggle_with_force("cursor__ring--hover", hovered.is_some());
            let _ = list.toggle_with_force("cursor__ring--label", !label.is_empty());
            if let Some(span) = ring.query_selector("span").ok().flatten()
                && span.text_content().unwrap_or_default() != label
            {
                span.set_text_content(Some(&label));
            }
        });
    }
    for (event, down) in [("pointerdown", true), ("pointerup", false)] {
        let ring = ring.clone();
        on(&window(), event, move |_: web_sys::Event| {
            let _ = ring
                .class_list()
                .toggle_with_force("cursor__ring--down", down);
        });
    }
    let mut pos = (-100.0f64, -100.0f64);
    request_frame(move |_| {
        let (tx, ty) = target.get();
        if (tx - pos.0).abs() > 0.1 || (ty - pos.1).abs() > 0.1 {
            pos.0 += (tx - pos.0) * 0.18;
            pos.1 += (ty - pos.1) * 0.18;
            set(
                &ring,
                "transform",
                &format!("translate3d({:.1}px,{:.1}px,0)", pos.0, pos.1),
            );
        }
        true
    });
}

/// Buttons lean towards the pointer (`data-magnetic`).
fn magnetic() {
    for el in all("[data-magnetic]") {
        let target = el.clone();
        on(&el, "pointermove", move |e: web_sys::PointerEvent| {
            let r = target.get_bounding_client_rect();
            let x = f64::from(e.client_x()) - r.left() - r.width() / 2.0;
            let y = f64::from(e.client_y()) - r.top() - r.height() / 2.0;
            set(&target, "--mx", &format!("{:.1}px", x * 0.25));
            set(&target, "--my", &format!("{:.1}px", y * 0.3));
        });
        let target = el.clone();
        on(&el, "pointerleave", move |_: web_sys::Event| {
            set(&target, "--mx", "0px");
            set(&target, "--my", "0px");
        });
    }
}

/// Cards lean towards the pointer (`data-tilt`, in degrees).
fn tilt() {
    for el in all("[data-tilt]") {
        let max: f64 = el
            .get_attribute("data-tilt")
            .and_then(|v| v.parse().ok())
            .unwrap_or(8.0);
        let target = el.clone();
        on(&el, "pointermove", move |e: web_sys::PointerEvent| {
            let r = target.get_bounding_client_rect();
            let x = (f64::from(e.client_x()) - r.left()) / r.width().max(1.0);
            let y = (f64::from(e.client_y()) - r.top()) / r.height().max(1.0);
            set(&target, "--ry", &format!("{:.2}deg", (x - 0.5) * max));
            set(&target, "--rx", &format!("{:.2}deg", (0.5 - y) * max));
        });
        let target = el.clone();
        on(&el, "pointerleave", move |_: web_sys::Event| {
            set(&target, "--rx", "0deg");
            set(&target, "--ry", "0deg");
        });
    }
}

/// The hero follows the mouse, with some inertia (`--hx`, `--hy`).
fn hero_mouse() {
    let Some(hero) = all(".hero").into_iter().next() else {
        return;
    };
    let mouse = Rc::new(Cell::new((0.0f64, 0.0f64)));
    let running = Rc::new(Cell::new(false));
    let eased = Rc::new(Cell::new((0.0f64, 0.0f64)));
    on_passive(&window(), "pointermove", move |e: web_sys::PointerEvent| {
        let width = window()
            .inner_width()
            .ok()
            .and_then(|w| w.as_f64())
            .unwrap_or(1.0);
        mouse.set((
            f64::from(e.client_x()) / width.max(1.0) - 0.5,
            f64::from(e.client_y()) / viewport_height().max(1.0) - 0.5,
        ));
        if running.replace(true) {
            return;
        }
        let (hero, mouse, running, eased) =
            (hero.clone(), mouse.clone(), running.clone(), eased.clone());
        request_frame(move |_| {
            let (mx, my) = mouse.get();
            let (ex, ey) = eased.get();
            let next = (ex + (mx - ex) * 0.07, ey + (my - ey) * 0.07);
            eased.set(next);
            set(&hero, "--hx", &format!("{:.4}", next.0));
            set(&hero, "--hy", &format!("{:.4}", next.1));
            let moving = (mx - next.0).abs() > 0.001 || (my - next.1).abs() > 0.001;
            running.set(moving);
            moving
        });
    });
}
