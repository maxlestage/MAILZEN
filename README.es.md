<div align="center">

# 🛡️ MailZen

**El guardián inteligente de tus correos. Antes de hacer clic, verifica.**

[Français](README.md) · [English](README.en.md) · **Español**

[Sitio web (GitHub Pages)](https://maxlestage.github.io/MAILZEN/es/) · [Desplegar en Heroku](https://heroku.com/deploy?template=https://github.com/maxlestage/MAILZEN)

</div>

---

MailZen es una app de protección digital (iOS en Swift / SwiftUI, Android en Kotlin /
Compose, un motor de análisis común en Rust) que ayuda a todos a reconocer, entender y
evitar correos maliciosos, phishing, enlaces peligrosos, adjuntos sospechosos y estafas.

Este repositorio contiene **el sitio de presentación**, escrito **solo en Rust** con el
framework [Paquets](https://github.com/maxlestage/Paquets): páginas renderizadas en el
servidor, islas interactivas y animaciones 2D compiladas a WebAssembly, pensado primero
para el móvil y sin desplazamiento horizontal, en francés, inglés y español, instalable
como PWA, sin cookies ni rastreadores.

- **Fusión automática**: cada push lanza la [CI](.github/workflows/ci.yml); cuando está
  en verde, la rama se fusiona en `master` y se despliegan GitHub Pages y Heroku.
- **GitHub Pages** (una vez): *Settings → Pages → Source: GitHub Actions*.
- **Heroku** (buildpack emk/rust, pila heroku-26): [Desplegar en Heroku](https://heroku.com/deploy?template=https://github.com/maxlestage/MAILZEN),
  o añade el secreto `HEROKU_API_KEY` y la variable `HEROKU_APP_NAME` para desplegar cada fusión.

```sh
./build-wasm.sh && cargo run --release   # http://localhost:3000
```

© 2026 Maxime Nathan Lestage, todos los derechos reservados. Ver [LICENSE](LICENSE).
