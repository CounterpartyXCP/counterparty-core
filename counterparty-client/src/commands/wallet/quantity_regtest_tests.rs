//! Live **regtest** integration test for the compose quantity path.
//!
//! Relocated out of `quantity.rs`'s hermetic unit-test module (and named
//! `*tests.rs`) so it is excluded from the unit-coverage denominator — like
//! `main.rs` and the signer `tests.rs`, it needs a running regtest
//! counterparty-server and never executes under a plain `cargo test`. The
//! `Client Regtest E2E` workflow (`.github/workflows/client_regtest_test.yml`)
//! starts a regtest node via `regtestnode.py` and runs it with `--ignored`.

use std::collections::HashMap;

use super::normalize_quantities;
use crate::commands::api;
use crate::config::AppConfig;

/// Integration check against a live **regtest** counterparty-server.
///
/// Requirements to run:
///   * a regtest counterparty-server reachable at the client's regtest
///     endpoint `http://localhost:24000` (see
///     `AppConfig::create_regtest_config`). The counterparty-core regtest
///     harness that spins up bitcoind + counterparty-server lives at
///     `counterpartycore/counterpartycore/test/integrations/regtest`.
///   * a funded source address for the compose step (fund the address this
///     test derives, or set `CP_REGTEST_ASSET` to a real asset name).
///
/// Run with:
///   cargo test --manifest-path counterparty-client/Cargo.toml \
///       -- --ignored full_compose_send_scales_quantity_regtest
///
/// What this DOES exercise over real HTTP:
///   * divisibility resolution via `GET /v2/assets/<asset>` (for a non-XCP
///     asset supplied through `CP_REGTEST_ASSET`);
///   * that `normalize_quantities` scales a divisible amount by 1e8 and
///     leaves an indivisible amount whole;
///   * that the compose endpoint is reachable and accepts the scaled params.
///
/// What it does NOT do automatically (be honest): fund the source address,
/// sign with a real wallet key (that needs the OS keyring / an interactive
/// password), or broadcast. Complete those with the `xcp wallet` CLI once
/// composed. The unit-level sign path is covered hermetically in
/// `bitcoinsigner::tests`.
#[tokio::test]
#[ignore]
async fn full_compose_send_scales_quantity_regtest() {
    // A temp wallet dir, as the integration flow would use. Full wallet init
    // (BitcoinWallet::init) needs the OS keyring, so here we derive the
    // source address directly instead of going through the wallet.
    let wallet_dir = tempfile::tempdir().unwrap();
    let _ = wallet_dir.path();

    let mut config = AppConfig::new();
    config.set_network(crate::config::Network::Regtest);
    assert_eq!(config.get_api_url(), "http://localhost:24000");

    // Deterministic regtest source address (bech32 / P2WPKH).
    let secp = bitcoin::secp256k1::Secp256k1::new();
    let sk = bitcoin::secp256k1::SecretKey::from_slice(&[0x22u8; 32]).unwrap();
    let pk = bitcoin::PrivateKey::new(sk, bitcoin::Network::Regtest);
    let public = bitcoin::PublicKey::from_private_key(&secp, &pk);
    let cpk = bitcoin::CompressedPublicKey::from_slice(&public.to_bytes()).unwrap();
    let source = bitcoin::Address::p2wpkh(&cpk, bitcoin::Network::Regtest).to_string();

    // 1) Divisible asset (XCP): 2 units must scale to 200_000_000 sats.
    let mut divisible = HashMap::new();
    divisible.insert("asset".to_string(), "XCP".to_string());
    divisible.insert("quantity".to_string(), "2".to_string());
    divisible.insert("destination".to_string(), source.clone());
    normalize_quantities(&config, "send", &mut divisible)
        .await
        .expect("normalize XCP send (is the regtest server running?)");
    assert_eq!(divisible.get("quantity").unwrap(), "200000000");

    // 2) Real network divisibility lookup for a developer-supplied asset.
    //    XCP -> scaled; an indivisible asset -> left whole.
    let asset = std::env::var("CP_REGTEST_ASSET").unwrap_or_else(|_| "XCP".to_string());
    let mut params = HashMap::new();
    params.insert("asset".to_string(), asset.clone());
    params.insert("quantity".to_string(), "3".to_string());
    params.insert("destination".to_string(), source.clone());
    normalize_quantities(&config, "send", &mut params)
        .await
        .expect("normalize send against the live regtest API");
    let q = params.get("quantity").unwrap();
    assert!(
        q == "300000000" || q == "3",
        "unexpected scaled quantity for {asset}: {q}"
    );

    // 3) A real divisibility lookup over HTTP: GET /v2/assets/XCP must report
    //    XCP as divisible. This exercises the client's GET + JSON-parse path
    //    against a live endpoint (works without electrs/funding) and validates
    //    the host-root URL join (no `//v2/`).
    let asset_info = api::perform_api_request(&config, "/v2/assets/XCP", &HashMap::new())
        .await
        .expect("GET /v2/assets/XCP over HTTP");
    assert_eq!(
        asset_info
            .get("result")
            .and_then(|r| r.get("divisible"))
            .and_then(|d| d.as_bool()),
        Some(true),
        "XCP must be reported as divisible: {asset_info}"
    );

    // 4) Compose the send over real HTTP and confirm the endpoint is reachable
    //    and returns a well-formed Counterparty response (a `result` when the
    //    source is funded, or an `error` otherwise) — never an HTML/404 body,
    //    which would indicate a broken request URL.
    let api_path = format!("/v2/addresses/{source}/compose/send");
    let result = api::perform_api_request(&config, &api_path, &divisible)
        .await
        .expect("compose_send over HTTP");
    assert!(
        result.get("result").is_some() || result.get("error").is_some(),
        "compose response should be a well-formed Counterparty response: {result}"
    );
}
