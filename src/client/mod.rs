//! The browser bundle: hydrates the islands, starts the page motion and the 2D canvases.

pub mod canvas;
pub mod motion;

use std::cell::RefCell;
use std::rc::Rc;

use wasm_bindgen::JsCast;
use wasm_bindgen::prelude::*;

#[wasm_bindgen(start)]
pub fn start() {
    // Links of a site published under a sub-path (GitHub Pages: `/MAILZEN`).
    if let Some(base) = document()
        .query_selector("[data-base]")
        .ok()
        .flatten()
        .and_then(|el| el.get_attribute("data-base"))
    {
        crate::routes::set_base(&base);
    }
    paquets::hydrate(&crate::islands::ISLANDS);
    motion::init();
    canvas::init();
}

pub fn window() -> web_sys::Window {
    web_sys::window().expect("window")
}

pub fn document() -> web_sys::Document {
    window().document().expect("document")
}

pub fn reduced_motion() -> bool {
    matches("(prefers-reduced-motion: reduce)")
}

pub fn matches(query: &str) -> bool {
    window()
        .match_media(query)
        .ok()
        .flatten()
        .is_some_and(|m| m.matches())
}

/// Adds an event listener for the page's lifetime.
pub fn on<E: JsCast + 'static>(
    target: &web_sys::EventTarget,
    event: &str,
    f: impl FnMut(E) + 'static,
) {
    let mut f = f;
    let closure =
        Closure::<dyn FnMut(web_sys::Event)>::new(move |e: web_sys::Event| f(e.unchecked_into()));
    let _ = target.add_event_listener_with_callback(event, closure.as_ref().unchecked_ref());
    closure.forget();
}

/// Like [`on`], with `{ passive: true }` (scroll and pointer listeners).
pub fn on_passive<E: JsCast + 'static>(
    target: &web_sys::EventTarget,
    event: &str,
    f: impl FnMut(E) + 'static,
) {
    let mut f = f;
    let closure =
        Closure::<dyn FnMut(web_sys::Event)>::new(move |e: web_sys::Event| f(e.unchecked_into()));
    let options = web_sys::AddEventListenerOptions::new();
    options.set_passive(true);
    let _ = target.add_event_listener_with_callback_and_add_event_listener_options(
        event,
        closure.as_ref().unchecked_ref(),
        &options,
    );
    closure.forget();
}

type FrameCallback = Closure<dyn FnMut(f64)>;

/// Calls `f(timestamp)` on every animation frame while it returns `true`.
pub fn request_frame(f: impl FnMut(f64) -> bool + 'static) {
    let f = Rc::new(RefCell::new(f));
    let slot: Rc<RefCell<Option<FrameCallback>>> = Rc::new(RefCell::new(None));
    let again = slot.clone();
    *slot.borrow_mut() = Some(Closure::new(move |now: f64| {
        if (f.borrow_mut())(now) {
            if let Some(cb) = again.borrow().as_ref() {
                let _ = window().request_animation_frame(cb.as_ref().unchecked_ref());
            }
        } else {
            again.borrow_mut().take();
        }
    }));
    if let Some(cb) = slot.borrow().as_ref() {
        let _ = window().request_animation_frame(cb.as_ref().unchecked_ref());
    }
}

/// Every element matching `selector`.
pub fn all(selector: &str) -> Vec<web_sys::HtmlElement> {
    let Ok(list) = document().query_selector_all(selector) else {
        return Vec::new();
    };
    (0..list.length())
        .filter_map(|i| list.item(i)?.dyn_into().ok())
        .collect()
}

/// Calls `f` once after `ms` milliseconds.
pub fn later(ms: i32, f: impl FnOnce() + 'static) {
    let f = Closure::once_into_js(f);
    let _ = window().set_timeout_with_callback_and_timeout_and_arguments_0(f.unchecked_ref(), ms);
}

/// Back to the top of the page (smoothly, through the CSS `scroll-behavior`).
pub fn scroll_to_top() {
    window().scroll_to_with_x_and_y(0.0, 0.0);
}

thread_local! {
    static MODELS: RefCell<Option<Rc<crate::models::Models>>> = const { RefCell::new(None) };
}

/// The trained models of the demo, downloaded on the first analysis (about 500 KB), then
/// kept for the page's lifetime. `f` gets `None` when they cannot be loaded (offline): the
/// analysis then uses the rules alone.
pub fn with_models(f: impl FnOnce(Option<Rc<crate::models::Models>>) + 'static) {
    if let Some(m) = MODELS.with(|m| m.borrow().clone()) {
        f(Some(m));
        return;
    }
    wasm_bindgen_futures::spawn_local(async move {
        let mut files = Vec::new();
        for name in crate::models::FILES {
            files.push(
                fetch_bytes(&format!(
                    "{}/assets/models/{name}.mzm",
                    crate::routes::base()
                ))
                .await,
            );
        }
        let models = match files.as_slice() {
            [Some(s), Some(c), Some(u)] => crate::models::Models::parse(s, c, u).map(Rc::new),
            _ => None,
        };
        if let Some(m) = &models {
            MODELS.with(|slot| *slot.borrow_mut() = Some(m.clone()));
        }
        f(models);
    });
}

async fn fetch_bytes(url: &str) -> Option<Vec<u8>> {
    let response: web_sys::Response =
        wasm_bindgen_futures::JsFuture::from(window().fetch_with_str(url))
            .await
            .ok()?
            .dyn_into()
            .ok()?;
    if !response.ok() {
        return None;
    }
    let buffer = wasm_bindgen_futures::JsFuture::from(response.array_buffer().ok()?)
        .await
        .ok()?;
    Some(js_sys::Uint8Array::new(&buffer).to_vec())
}
