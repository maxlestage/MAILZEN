#!/usr/bin/env bash
# Builds the browser bundle (islands, animations, 2D canvases) into pkg/, with the
# wasm-bindgen version of Cargo.lock: a prebuilt binary, or compiled if it cannot be
# downloaded. Used by the CI, GitHub Pages and Heroku (heroku-build.sh).
set -euo pipefail
cd "$(dirname "$0")"
target="${CARGO_TARGET_DIR:-target}"
rustup target add wasm32-unknown-unknown >/dev/null 2>&1 || true
cargo build --lib --target wasm32-unknown-unknown --profile wasm-release

version=$(grep -A1 '^name = "wasm-bindgen"$' Cargo.lock | sed -n 's/^version = "\(.*\)"$/\1/p')
bin="$target/wasm-bindgen-$version"
if [ ! -x "$bin/wasm-bindgen" ]; then
  mkdir -p "$bin"
  curl -sSfL "https://github.com/wasm-bindgen/wasm-bindgen/releases/download/${version}/wasm-bindgen-${version}-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz --strip-components=1 -C "$bin" \
    || cargo install wasm-bindgen-cli --version "$version" --locked --root "$bin" --bin wasm-bindgen
  [ -x "$bin/wasm-bindgen" ] || mv "$bin/bin/wasm-bindgen" "$bin/"
fi
"$bin/wasm-bindgen" --target web --no-typescript --remove-name-section --remove-producers-section \
  --out-dir pkg "$target/wasm32-unknown-unknown/wasm-release/mailzen_site.wasm"
echo "       pkg/ ready ($(du -h pkg/mailzen_site_bg.wasm | cut -f1) of WebAssembly)"
