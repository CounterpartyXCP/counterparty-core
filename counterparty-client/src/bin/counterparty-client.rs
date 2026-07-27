//! `counterparty-client` — the long binary name for the Counterparty client.
//!
//! Identical to `xcp`; both are thin wrappers over the `counterparty_client`
//! library's `run()` entry point.

// This thin wrapper only touches `counterparty_client`, `tokio` and `anyhow`;
// the package's many other deps are used by the library, not here.
#![allow(unused_crate_dependencies)]

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    counterparty_client::run().await
}
