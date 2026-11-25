//! Every page answers in every language, with its islands, its PWA links and its
//! alternates; unknown addresses get the "not found" page.

use std::sync::Arc;

use mailzen_site::i18n::Lang;
use mailzen_site::routes::Route;
use mailzen_site::server::{Site, app};

#[tokio::test]
async fn every_route_answers() {
    let site = Arc::new(Site::load(false, Some("https://example.org".into())));
    let mut app = app(site);
    app.security(None);
    let client = app.test().await;

    for route in Route::all() {
        let res = client.get(&route.path()).await;
        assert_eq!(res.status(), 200, "{}", route.path());
        let html = res.text();
        assert!(
            html.contains(&format!("<html lang=\"{}\"", route.lang.code())),
            "{}",
            route.path()
        );
        assert!(
            html.contains("data-island=\"top\""),
            "{}: the footer island",
            route.path()
        );
        assert!(html.contains("manifest.webmanifest"), "{}", route.path());
        assert!(html.contains("hreflang=\"es\""), "{}", route.path());
    }
    for lang in Lang::ALL {
        let html = client.get(&format!("/{}/", lang.code())).await.text();
        for island in ["scan", "connect", "sos", "quiz", "pricing"] {
            assert!(
                html.contains(&format!("data-island=\"{island}\"")),
                "{island}"
            );
        }
        for id in [
            "modules", "demo", "report", "zenai", "sos", "privacy", "pricing", "faq",
        ] {
            assert!(
                html.contains(&format!("id=\"{id}\"")),
                "#{id} in {}",
                lang.code()
            );
        }
    }

    assert_eq!(client.get("/fr/nope/").await.status(), 404);
    assert_eq!(client.get("/de/").await.status(), 404);
    assert_eq!(client.get("/fr").await.status(), 301);
    let root = client
        .get("/")
        .header("accept-language", "es-ES,es;q=0.9")
        .await;
    assert!(root.status().is_redirection());
    for path in [
        "/sitemap.xml",
        "/robots.txt",
        "/manifest.webmanifest",
        "/fr/manifest.webmanifest",
        "/sw.js",
        "/site.css",
        "/icons/icon-192.png",
    ] {
        assert_eq!(client.get(path).await.status(), 200, "{path}");
    }
    let manifest = client.get("/es/manifest.webmanifest").await.text();
    assert!(manifest.contains("\"/es/\"") && manifest.contains("icon-maskable-512.png"));
}
