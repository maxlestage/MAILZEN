//! The server: a `paquets::App` with the pages in three languages, the sitemap, the PWA
//! (manifest and offline service worker). Static files come from `public/` and the
//! browser bundle from `pkg/` (both found by Paquets in the current directory).

pub mod export;
pub mod pages;

use std::io;
use std::path::{Path, PathBuf};
use std::sync::Arc;

use paquets::prelude::*;

use crate::i18n::{Lang, pick_lang};
use crate::routes::{self, Page as PageKind, Route, base, link};

pub struct Site {
    /// The public address, with the base path (`SITE_URL`); `None`: taken from each
    /// request.
    pub site_url: Option<String>,
    /// The running server; `false` for the static export.
    pub live: bool,
    /// Short hash of `public/site.css`, for `?v=` in its link.
    pub css_version: String,
}

/// The folder of the site: `SITE_DIR` when it has `public/`, else the current directory
/// when it has `public/`, else the crate folder.
pub fn site_dir() -> PathBuf {
    if let Some(dir) = std::env::var_os("SITE_DIR")
        .map(PathBuf::from)
        .filter(|dir| dir.join("public").is_dir())
    {
        return dir;
    }
    if Path::new("public").is_dir() {
        return PathBuf::from(".");
    }
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
}

/// FNV-1a, enough to tell versions of a file apart.
pub fn version(bytes: &[u8]) -> String {
    let h = bytes.iter().fold(0xcbf2_9ce4_8422_2325_u64, |h, b| {
        (h ^ u64::from(*b)).wrapping_mul(0x0100_0000_01b3)
    });
    format!("{h:016x}")[..10].to_owned()
}

impl Site {
    /// Reads the stylesheet. Call [`routes::set_base`] before.
    pub fn load(live: bool, site_url: Option<String>) -> Site {
        let path = site_dir().join("public/site.css");
        let css = std::fs::read(&path).unwrap_or_else(|e| {
            eprintln!("warning: {} unreadable ({e})", path.display());
            Vec::new()
        });
        Site {
            site_url: site_url
                .map(|u| u.trim().trim_end_matches('/').to_owned())
                .filter(|u| !u.is_empty())
                .map(|u| {
                    if u.ends_with(base()) {
                        u
                    } else {
                        format!("{u}{}", base())
                    }
                }),
            live,
            css_version: version(&css),
        }
    }

    /// The public address of the site, with the base path.
    fn origin(&self, req: &Request) -> String {
        if let Some(url) = &self.site_url {
            return url.clone();
        }
        let header = |name: &str| {
            req.header(name)
                .map(|v| v.split(',').next().unwrap_or("").trim().to_owned())
        };
        let host = header("x-forwarded-host")
            .or_else(|| header("host"))
            .unwrap_or_else(|| "localhost".into());
        if host.is_empty()
            || !host
                .chars()
                .all(|c| c.is_ascii_alphanumeric() || matches!(c, '.' | '-' | ':'))
        {
            return format!("http://localhost{}", base());
        }
        let proto = if header("x-forwarded-proto").as_deref() == Some("https") {
            "https"
        } else {
            "http"
        };
        format!("{proto}://{host}{}", base())
    }
}

/// `/`: the home page of the preferred language of the browser.
fn root(req: &Request) -> Response {
    let lang = pick_lang(req.header("accept-language").unwrap_or(""));
    Redirect::to(link(&format!("/{}/", lang.code())))
        .into_response()
        .header("vary", "Accept-Language")
        .header("cache-control", "no-cache")
}

/// A page of the site: `/{lang}/`, `/{lang}/privacy/`, `/{lang}/legal/`.
fn page(site: &Site, req: &Request) -> Response {
    let path = req.path();
    let Some(route) = Route::parse(path) else {
        return not_found(site, req);
    };
    if route.page == PageKind::NotFound {
        return not_found(site, req);
    }
    if !path.ends_with('/') {
        let query = req
            .uri()
            .query()
            .map(|q| format!("?{q}"))
            .unwrap_or_default();
        return Redirect::permanent(format!("{}/{query}", link(path))).into_response();
    }
    let ctx = pages::Ctx {
        site,
        route,
        origin: site.origin(req),
    };
    pages::render(&ctx)
        .into_response()
        .header("cache-control", "no-cache")
}

/// The "not found" page, in the language of the URL or of the browser.
fn not_found(site: &Site, req: &Request) -> Response {
    let lang = Route::parse(req.path()).map_or_else(
        || pick_lang(req.header("accept-language").unwrap_or("")),
        |r| r.lang,
    );
    let ctx = pages::Ctx {
        site,
        route: Route::new(lang, PageKind::NotFound),
        origin: site.origin(req),
    };
    pages::not_found(&ctx).into_response()
}

fn sitemap(site: &Site, req: &Request) -> Response {
    let origin = site.origin(req);
    let mut xml = String::from(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\" xmlns:xhtml=\"http://www.w3.org/1999/xhtml\">\n",
    );
    for route in Route::all() {
        xml.push_str(&format!("<url><loc>{origin}{}</loc>", route.path()));
        for lang in Lang::ALL {
            xml.push_str(&format!(
                r#"<xhtml:link rel="alternate" hreflang="{}" href="{origin}{}"/>"#,
                lang.code(),
                route.with_lang(lang).path()
            ));
        }
        xml.push_str(&format!(
            r#"<xhtml:link rel="alternate" hreflang="x-default" href="{origin}{}"/></url>"#,
            route.with_lang(Lang::Fr).path()
        ));
        xml.push('\n');
    }
    xml.push_str("</urlset>\n");
    Response::new()
        .header("content-type", "application/xml; charset=utf-8")
        .send(xml)
}

fn robots(site: &Site, req: &Request) -> Response {
    let origin = site.origin(req);
    Response::new()
        .header("content-type", "text/plain; charset=utf-8")
        .send(format!(
            "User-agent: *\nAllow: /\n\nSitemap: {origin}/sitemap.xml\n"
        ))
}

/// Routes a handler that only needs the site and the request.
fn route(app: &mut App, path: &str, site: &Arc<Site>, handler: fn(&Site, &Request) -> Response) {
    let site = site.clone();
    app.get(path, move |req: Request| {
        let site = site.clone();
        async move { handler(&site, &req) }
    });
}

/// The web app manifest: MailZen installs on phones and computers and opens offline.
pub fn pwa() -> Pwa {
    Pwa::new("MailZen")
        .short_name("MailZen")
        .description("Before you click, check. The smart guardian of your emails.")
        .start_url("/{lang}/")
        .theme_color("#060b1a")
        .background_color("#060b1a")
        .categories(["security", "utilities", "productivity"])
        .icon("/icons/icon-192.png", "192x192", "image/png")
        .icon("/icons/icon-512.png", "512x512", "image/png")
        .maskable_icon("/icons/icon-maskable-512.png", "512x512", "image/png")
}

/// The application, ready to run or to test.
pub fn app(site: Arc<Site>) -> App {
    let mut app = App::new();
    app.get("/", |req: Request| async move { root(&req) });
    route(&mut app, "/sitemap.xml", &site, sitemap);
    route(&mut app, "/robots.txt", &site, robots);
    for path in ["/:lang", "/:lang/:page"] {
        route(&mut app, path, &site, page);
    }
    app.pwa(pwa());
    let fallback = site.clone();
    app.fallback(move |req: Request| {
        let site = fallback.clone();
        async move { not_found(&site, &req) }
    });
    app
}

/// `cargo run`: the server, on `PORT` (Heroku) or 3000.
pub fn run() -> io::Result<()> {
    routes::set_base(&std::env::var("BASE_PATH").unwrap_or_default());
    // Paquets serves `public/` and `pkg/` from the current directory.
    let dir = site_dir();
    if dir != Path::new(".") {
        std::env::set_current_dir(&dir)?;
    }
    let site = Arc::new(Site::load(true, std::env::var("SITE_URL").ok()));
    app(site).run()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn versions_change_with_the_content() {
        assert_eq!(version(b"a").len(), 10);
        assert_ne!(version(b"a"), version(b"b"));
    }
}
