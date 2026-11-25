//! The URLs of the site: `/{lang}/`, `/{lang}/privacy/`, `/{lang}/legal/`, behind an
//! optional base path (`/MAILZEN` when the site is published on GitHub Pages).

use std::sync::OnceLock;

pub use crate::i18n::Lang;

static BASE: OnceLock<String> = OnceLock::new();

/// Sets the base path once, before anything is rendered: `""` (the default) or
/// `/MAILZEN`. The server takes it from `BASE_PATH`, the browser from `data-base`.
pub fn set_base(base: &str) {
    let _ = BASE.set(normalize_base(base));
}

/// `""`, or `/something` without a trailing slash.
pub fn normalize_base(base: &str) -> String {
    let base = base.trim().trim_end_matches('/');
    match base {
        "" => String::new(),
        b if b.starts_with('/') => b.to_owned(),
        b => format!("/{b}"),
    }
}

/// The base path, without trailing slash (empty by default).
pub fn base() -> &'static str {
    BASE.get().map_or("", String::as_str)
}

/// A link to `path` (which starts with `/`), behind the base path.
pub fn link(path: &str) -> String {
    format!("{}{path}", base())
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Page {
    Home,
    Privacy,
    Legal,
    NotFound,
}

impl Page {
    /// The pages that exist in every language.
    pub const ALL: [Page; 3] = [Page::Home, Page::Privacy, Page::Legal];
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Route {
    pub lang: Lang,
    pub page: Page,
}

impl Route {
    pub fn new(lang: Lang, page: Page) -> Route {
        Route { lang, page }
    }

    /// The route of a path (without the base path); `None` when it does not start with
    /// a language.
    pub fn parse(path: &str) -> Option<Route> {
        let parts: Vec<&str> = path.split('/').filter(|p| !p.is_empty()).collect();
        let lang = Lang::parse(parts.first()?)?;
        let page = match parts[1..] {
            [] => Page::Home,
            ["privacy"] => Page::Privacy,
            ["legal"] => Page::Legal,
            _ => Page::NotFound,
        };
        Some(Route { lang, page })
    }

    /// The path of the page, without the base path.
    pub fn path(&self) -> String {
        let l = self.lang.code();
        match self.page {
            Page::Home => format!("/{l}/"),
            Page::Privacy => format!("/{l}/privacy/"),
            Page::Legal => format!("/{l}/legal/"),
            Page::NotFound => format!("/{l}/404/"),
        }
    }

    /// A link to the page, behind the base path.
    pub fn href(&self) -> String {
        link(&self.path())
    }

    /// The same page in another language.
    pub fn with_lang(&self, lang: Lang) -> Route {
        Route { lang, ..*self }
    }

    /// Every page of the site, in every language (what the static export writes).
    pub fn all() -> Vec<Route> {
        Lang::ALL
            .into_iter()
            .flat_map(|lang| Page::ALL.map(|page| Route::new(lang, page)))
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_and_builds_urls() {
        let privacy = Route::parse("/fr/privacy/").unwrap();
        assert_eq!(privacy, Route::new(Lang::Fr, Page::Privacy));
        assert_eq!(privacy.with_lang(Lang::Es).path(), "/es/privacy/");
        assert_eq!(Route::parse("/en").unwrap().page, Page::Home);
        assert_eq!(Route::parse("/es/legal").unwrap().page, Page::Legal);
        assert_eq!(Route::parse("/en/nope/").unwrap().page, Page::NotFound);
        assert_eq!(Route::parse("/de/"), None);
        assert_eq!(Route::parse("/"), None);
    }

    #[test]
    fn lists_every_page_once() {
        let mut paths: Vec<String> = Route::all().iter().map(Route::path).collect();
        assert_eq!(paths.len(), 9);
        paths.sort();
        paths.dedup();
        assert_eq!(paths.len(), 9);
    }

    #[test]
    fn normalizes_the_base_path() {
        assert_eq!(normalize_base(""), "");
        assert_eq!(normalize_base("/"), "");
        assert_eq!(normalize_base("MAILZEN/"), "/MAILZEN");
        assert_eq!(link("/fr/"), "/fr/");
    }
}
