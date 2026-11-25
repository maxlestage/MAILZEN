#!/usr/bin/env bash
# Builds the server and the browser bundle: run on Heroku by RustConfig once the
# emk/rust buildpack has installed Rust. Works by hand too: ./heroku-build.sh
# The Procfile starts target/release/mailzen-site.
set -euo pipefail
cd "$(dirname "$0")"
# On Heroku, Cargo builds into the buildpack's cache (CARGO_TARGET_DIR).
target="${CARGO_TARGET_DIR:-target}"

echo "-----> Building the server"
cargo build --release --bin mailzen-site
mkdir -p target/release
if [ "$target" != target ]; then
  cp "$target/release/mailzen-site" target/release/
fi
echo "       target/release/mailzen-site ready"

echo "-----> Building the islands and animations (WebAssembly)"
./build-wasm.sh
