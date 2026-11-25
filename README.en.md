<div align="center">

# 🛡️ MailZen

**The smart guardian of your emails. Before you click, check.**

[Français](README.md) · **English** · [Español](README.es.md)

[Website (GitHub Pages)](https://maxlestage.github.io/MAILZEN/en/) · [Deploy to Heroku](https://heroku.com/deploy?template=https://github.com/maxlestage/MAILZEN)

</div>

---

MailZen is a digital protection app (iOS in Swift / SwiftUI, Android in Kotlin /
Compose, a shared analysis engine in Rust) that helps everyone recognize, understand and
avoid malicious emails, phishing, dangerous links, suspicious attachments and scams.

This repository holds **the presentation website**, written **only in Rust** with the
[Paquets](https://github.com/maxlestage/Paquets) framework: server-rendered pages,
interactive islands and 2D animations compiled to WebAssembly, mobile first with no
horizontal scrolling, in French, English and Spanish, installable as a PWA, with no
cookies and no trackers.

- **Auto-merge**: every push runs the [CI](.github/workflows/ci.yml); when it is green,
  the branch is merged into `master`, then GitHub Pages and Heroku are deployed.
- **GitHub Pages** (once): *Settings → Pages → Source: GitHub Actions*.
- **Heroku** (emk/rust buildpack, heroku-26 stack): [Deploy to Heroku](https://heroku.com/deploy?template=https://github.com/maxlestage/MAILZEN),
  or add the `HEROKU_API_KEY` secret and the `HEROKU_APP_NAME` variable to deploy every merge.

```sh
./build-wasm.sh && cargo run --release   # http://localhost:3000
```

© 2026 Maxime Nathan Lestage, all rights reserved. See [LICENSE](LICENSE).
