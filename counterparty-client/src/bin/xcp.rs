//! `xcp` — the short binary name for the Counterparty client.
//!
//! All logic lives in the `counterparty_client` library so the two identical
//! binaries (`xcp` and `counterparty-client`) share one implementation and the
//! unit tests build (and run) only once.

// This thin wrapper only touches `counterparty_client`, `tokio` and `anyhow`;
// the package's many other deps are used by the library, not here.
#![allow(unused_crate_dependencies)]

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    counterparty_client::run().await
}
