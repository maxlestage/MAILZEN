//! The presentation website of MailZen, written in Rust with Paquets: the texts, routes,
//! islands and demo engine shared by the server and the browser, the server (native) and
//! the browser bundle (wasm32).

pub mod data;
pub mod engine;
pub mod i18n;
pub mod icons;
pub mod islands;
pub mod routes;

#[cfg(not(target_arch = "wasm32"))]
pub mod server;

#[cfg(target_arch = "wasm32")]
mod client;
