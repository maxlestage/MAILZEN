//! `mailzen-site export <dir>`: the whole site as static files, for GitHub Pages or any
//! static host. Every page comes from the server itself, through Paquets' in-memory test
//! client (`app.test()`), so both are identical.
//!
//! What a static host cannot do is replaced: `/` and `404.html` pick the language in the
//! browser instead of a redirection by `Accept-Language`, and every language has its "not
//! found" page.

use std::io;
use std::path::{Path, PathBuf};
use std::sync::Arc;

use super::{Site, app, pages, site_dir};
use crate::i18n::Lang;
use crate::routes::{Route, base, set_base};

/// The address used for canonical and Open Graph URLs when `SITE_URL` is not set.
fn default_site_url(base: &str) -> String {
    if base.is_empty() {
        "http://localhost:3000".to_owned()
    } else {
        format!("https://maxlestage.github.io{base}")
    }
}

/// Writes the site into `out`, links behind `base` (`""` or `/MAILZEN`), absolute URLs
/// (canonical, sitemap, Open Graph) on `site_url`. Returns the number of files written.
pub async fn export(out: &Path, base_path: &str, site_url: Option<String>) -> io::Result<usize> {
    set_base(base_path);
    let base = base();
    let out = std::path::absolute(out)?;
    // Paquets finds `pkg/` (the browser bundle) in the current directory.
    let dir = std::path::absolute(site_dir())?;
    std::env::set_current_dir(&dir)?;
    if !dir.join("pkg").is_dir() {
        eprintln!("warning: pkg/ is missing: the pages will not be interactive (see README.md)");
    }
    let site_url = site_url
        .filter(|u| !u.trim().is_empty())
        .unwrap_or_else(|| default_site_url(base));
    let site = Arc::new(Site::load(false, Some(site_url)));
    let mut app = app(site.clone());
    // Static files have no server to protect, and the export asks for every page at once.
    app.security(None);
    let client = app.test().await;

    let mut written = 0;
    let mut write = |path: &str, bytes: &[u8]| -> io::Result<()> {
        let file = out.join(path.trim_start_matches('/'));
        if let Some(parent) = file.parent() {
            std::fs::create_dir_all(parent)?;
        }
        std::fs::write(file, bytes)?;
        written += 1;
        Ok(())
    };
    let get = |path: String, expected: u16| {
        let client = &client;
        async move {
            let res = client.get(&path).await;
            if res.status().as_u16() != expected {
                return Err(io::Error::other(format!(
                    "GET {path}: {} instead of {expected}",
                    res.status()
                )));
            }
            Ok(res.text())
        }
    };

    for route in Route::all() {
        let html = get(route.path(), 200).await?;
        write(
            &format!("{}index.html", route.path()),
            with_base(&html, base).as_bytes(),
        )?;
    }
    // The root and the unknown addresses: the page picks the language itself.
    let origin = site.site_url.clone().unwrap_or_default();
    for (file, target) in [("index.html", ""), ("404.html", "404/")] {
        let html = pages::language_picker(&site, &origin, target).render();
        write(file, with_base(&html, base).as_bytes())?;
    }
    for lang in Lang::ALL {
        let missing = get(format!("/{}/404/", lang.code()), 404).await?;
        write(
            &format!("/{}/404/index.html", lang.code()),
            with_base(&missing, base).as_bytes(),
        )?;
    }
    // The PWA: the manifests and the service worker list absolute URLs.
    let mut pwa_files = vec!["/manifest.webmanifest".to_owned(), "/sw.js".to_owned()];
    pwa_files.extend(
        Lang::ALL
            .iter()
            .map(|l| format!("/{}/manifest.webmanifest", l.code())),
    );
    for file in pwa_files {
        let body = get(file.clone(), 200).await?;
        write(&file, with_base_everywhere(&body, base).as_bytes())?;
    }
    for file in ["/sitemap.xml", "/robots.txt"] {
        let body = get(file.to_owned(), 200).await?;
        write(file, body.as_bytes())?;
    }
    for folder in ["public", "pkg"] {
        let root = dir.join(folder);
        let prefix = if folder == "pkg" { "pkg/" } else { "" };
        for file in files(&root) {
            let relative = file.strip_prefix(&root).map_err(io::Error::other)?;
            let url = format!("{prefix}{}", relative.to_string_lossy().replace('\\', "/"));
            // wasm-bindgen's own files, not needed to run the bundle.
            if url.ends_with(".gitignore") || url.ends_with("package.json") {
                continue;
            }
            write(&url, &std::fs::read(&file)?)?;
        }
    }
    // Files are served as they are: no Jekyll processing on GitHub Pages.
    write(".nojekyll", b"")?;
    Ok(written)
}

/// The URLs that Paquets writes itself (the islands loader, the manifest, the service
/// worker) do not know the base path: they get it here. The links of the site already
/// have it.
pub fn with_base(html: &str, base: &str) -> String {
    if base.is_empty() {
        return html.to_owned();
    }
    let mut out = html
        .replace("\"/pkg/", &format!("\"{base}/pkg/"))
        .replace(
            "\"/manifest.webmanifest\"",
            &format!("\"{base}/manifest.webmanifest\""),
        )
        .replace("\"/sw.js\"", &format!("\"{base}/sw.js\""));
    for lang in Lang::ALL {
        let code = lang.code();
        out = out.replace(
            &format!("\"/{code}/manifest.webmanifest\""),
            &format!("\"{base}/{code}/manifest.webmanifest\""),
        );
    }
    out
}

/// Every absolute URL of a JSON or JavaScript file (`"/…"`) behind `base`.
pub fn with_base_everywhere(text: &str, base: &str) -> String {
    if base.is_empty() {
        return text.to_owned();
    }
    text.replace("\"/", &format!("\"{base}/"))
}

/// Every file under `dir`, recursively.
fn files(dir: &Path) -> Vec<PathBuf> {
    let mut found = Vec::new();
    let Ok(entries) = std::fs::read_dir(dir) else {
        return found;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() {
            found.extend(files(&path));
        } else {
            found.push(path);
        }
    }
    found.sort();
    found
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn prefixes_what_paquets_writes() {
        let html = r#"<link rel="manifest" href="/fr/manifest.webmanifest"/><script type="module">import init from "/pkg/a.js";init({module_or_path:"/pkg/a_bg.wasm"});</script>"#;
        let out = with_base(html, "/MAILZEN");
        assert_eq!(out.matches("\"/MAILZEN/pkg/").count(), 2);
        assert!(out.contains("\"/MAILZEN/fr/manifest.webmanifest\""));
        assert_eq!(with_base(html, ""), html);
        assert_eq!(
            default_site_url("/MAILZEN"),
            "https://maxlestage.github.io/MAILZEN"
        );
    }
}
