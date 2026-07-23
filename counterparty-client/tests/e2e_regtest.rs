//! End-to-end **regtest** test driving the real `xcp` binary through a full
//! fund → compose → sign → broadcast → accept cycle.
//!
//! Unlike the counterparty-core Python regtest harness — which signs with
//! Bitcoin Core's own wallet (`signrawtransactionwithwallet`) — this test signs
//! with **the client's own signer** (`bitcoinsigner`). That is the whole point:
//! it confronts the Rust signer with real bitcoind consensus rules and real
//! Counterparty parsing, exercising exactly what a user runs on the command
//! line (`xcp wallet transaction ...`), keys and all.
//!
//! It is a **black-box** test: it spawns the compiled `xcp` binary
//! (`CARGO_BIN_EXE_xcp`) with an isolated wallet, an `XCP_WALLET_PASSWORD` for a
//! non-interactive password, and `--yes` to skip the broadcast confirmation. It
//! never calls the client's library functions directly.
//!
//! ## What it does
//!   1. Imports a known private key into a fresh, isolated `xcp` wallet
//!      (created non-interactively via `XCP_WALLET_PASSWORD`).
//!   2. Funds that address with two independent UTXOs from Bitcoin Core's
//!      regtest wallet (`sendtoaddress` + `generatetoaddress`).
//!   3. `xcp wallet transaction burn` — compose (API) + sign (local signer) +
//!      broadcast (`POST /v2/bitcoin/transactions`) — so the address gains XCP.
//!   4. `xcp wallet transaction send` — sends 1 satoshi of XCP to a second
//!      address.
//!   5. Asserts, over the live v2 API, that the destination was credited with
//!      exactly the XCP that was sent — the "accept" the composed-and-signed
//!      transaction produced once parsed into the ledger.
//!
//! The composes supply their inputs explicitly via `--inputs_set` (as the
//! Python transaction-chaining test does), so the Counterparty server does not
//! need an Electrs address index to look up the imported address's UTXOs. This
//! keeps the CI job hermetic (bitcoind only) and avoids Electrs flakiness, while
//! still exercising the real binary's compose/sign/broadcast path.
//!
//! ## Requirements to run
//!   * a live regtest `counterparty-server` reachable at `http://localhost:24000`
//!     and its `bitcoind` reachable via `bitcoin-cli` (rpc/rpc on the regtest
//!     default port) with the `xcpwallet` funded — exactly the environment the
//!     `counterpartycore/test/integrations/regtest/regtestnode.py` harness
//!     brings up. `bitcoin-cli` must be on `PATH`.
//!
//! ## Run with
//! ```sh
//! cargo test --manifest-path counterparty-client/Cargo.toml \
//!     --test e2e_regtest -- --ignored full_fund_compose_sign_broadcast_accept_regtest
//! ```
//! It is `#[ignore]`d so a plain `cargo test` (no regtest node) skips it.

// This black-box test drives the compiled binary and touches only a handful of
// the crate's dependencies; the crate-wide `-W unused_crate_dependencies`
// (`.cargo/config.toml`) would otherwise flag the rest, exactly as the thin
// `src/bin/*.rs` wrappers suppress it.
#![allow(unused_crate_dependencies)]

use std::path::Path;
use std::process::Output;
use std::time::Duration;

const API_BASE: &str = "http://localhost:24000";
/// A ≥12-char password (the client's new-wallet minimum) supplied to `xcp` via
/// the environment so the wallet is created and unlocked without a prompt.
const WALLET_PASSWORD: &str = "regtest-e2e-passphrase";

/// Path to the freshly-built `xcp` binary, provided by Cargo for integration
/// tests.
fn xcp_bin() -> &'static str {
    env!("CARGO_BIN_EXE_xcp")
}

/// Run `xcp <args>` against an isolated wallet/config rooted at `home`, with a
/// non-interactive password. `HOME` covers macOS's `dirs` locations; the
/// `XDG_*` vars cover Linux — so neither the developer's real wallet nor their
/// keyring is ever touched.
fn run_xcp(home: &Path, args: &[&str]) -> Output {
    std::process::Command::new(xcp_bin())
        .args(args)
        .env("HOME", home)
        .env("XDG_DATA_HOME", home.join("data"))
        .env("XDG_CONFIG_HOME", home.join("config"))
        .env("XDG_CACHE_HOME", home.join("cache"))
        .env("XCP_WALLET_PASSWORD", WALLET_PASSWORD)
        .output()
        .expect("failed to spawn xcp")
}

/// Like [`run_xcp`], but writes `stdin_input` to the child's stdin. `run_xcp`
/// uses `Command::output()`, which gives the child an empty stdin (immediate
/// EOF), so the broadcast confirmation prompt reads EOF and aborts. That is
/// correct for the `burn` step: its transaction type is not one the client can
/// independently verify, so `--yes` deliberately does *not* auto-confirm it
/// (a hostile server could otherwise slip an unverifiable transaction past
/// unattended automation). The E2E confirms it the way a human would — by
/// answering `y` at the prompt.
fn run_xcp_with_stdin(home: &Path, args: &[&str], stdin_input: &str) -> Output {
    use std::io::Write;
    use std::process::Stdio;
    let mut child = std::process::Command::new(xcp_bin())
        .args(args)
        .env("HOME", home)
        .env("XDG_DATA_HOME", home.join("data"))
        .env("XDG_CONFIG_HOME", home.join("config"))
        .env("XDG_CACHE_HOME", home.join("cache"))
        .env("XCP_WALLET_PASSWORD", WALLET_PASSWORD)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .expect("failed to spawn xcp");
    child
        .stdin
        .take()
        .expect("child stdin is piped")
        .write_all(stdin_input.as_bytes())
        .expect("failed to write to xcp stdin");
    child.wait_with_output().expect("failed to wait for xcp")
}

/// Assert an `xcp` invocation succeeded, dumping both streams on failure so a CI
/// log shows exactly why (compose error, sign error, broadcast rejection, …).
fn assert_xcp_ok(out: &Output, what: &str) {
    assert!(
        out.status.success(),
        "`xcp {what}` failed (exit {:?})\n--- stdout ---\n{}\n--- stderr ---\n{}",
        out.status.code(),
        String::from_utf8_lossy(&out.stdout),
        String::from_utf8_lossy(&out.stderr),
    );
}

/// Run `bitcoin-cli -regtest ... <args>` and return trimmed stdout.
fn bitcoin_cli(args: &[&str]) -> String {
    let out = std::process::Command::new("bitcoin-cli")
        .args([
            "-regtest",
            "-rpcuser=rpc",
            "-rpcpassword=rpc",
            "-rpcconnect=localhost",
        ])
        .args(args)
        .output()
        .expect("failed to spawn bitcoin-cli (is it on PATH?)");
    assert!(
        out.status.success(),
        "`bitcoin-cli {args:?}` failed: {}",
        String::from_utf8_lossy(&out.stderr),
    );
    String::from_utf8_lossy(&out.stdout).trim().to_string()
}

/// `bitcoin-cli` bound to the harness's `xcpwallet` (the funded regtest wallet).
fn bitcoin_wallet(args: &[&str]) -> String {
    let mut full = vec!["-rpcwallet=xcpwallet"];
    full.extend_from_slice(args);
    bitcoin_cli(&full)
}

/// Mine `n` blocks to `address`, advancing the chain and confirming pending txs.
fn mine(n: u32, address: &str) {
    bitcoin_wallet(&["generatetoaddress", &n.to_string(), address]);
}

/// The vout of `txid` whose scriptPubKey hex equals `spk_hex`. Compared by
/// script (never by the float-parsed BTC value) so it is exact.
fn vout_paying(txid: &str, spk_hex: &str) -> u32 {
    let raw = bitcoin_cli(&["getrawtransaction", txid, "true"]);
    let tx: serde_json::Value = serde_json::from_str(&raw).expect("decode getrawtransaction json");
    for out in tx["vout"].as_array().expect("vout array") {
        if out["scriptPubKey"]["hex"].as_str() == Some(spk_hex) {
            return out["n"].as_u64().expect("vout n") as u32;
        }
    }
    panic!("no vout paying scriptPubKey {spk_hex} in tx {txid}: {raw}");
}

/// A regtest P2WPKH key/address derived deterministically from a one-byte seed,
/// returning `(WIF, address, scriptPubKey_hex)`. The address matches what
/// `xcp wallet import_address --private-key <WIF>` derives for the default
/// `bech32` type (`Address::p2wpkh` over the same compressed key).
fn regtest_p2wpkh(seed: u8) -> (String, String, String) {
    let secp = bitcoin::secp256k1::Secp256k1::new();
    let sk = bitcoin::secp256k1::SecretKey::from_slice(&[seed; 32]).expect("valid secret key");
    let pk = bitcoin::PrivateKey::new(sk, bitcoin::Network::Regtest);
    let public = bitcoin::PublicKey::from_private_key(&secp, &pk);
    let cpk = bitcoin::CompressedPublicKey::from_slice(&public.to_bytes()).expect("compressed pk");
    let addr = bitcoin::Address::p2wpkh(&cpk, bitcoin::Network::Regtest);
    let spk_hex = hex::encode(addr.script_pubkey().as_bytes());
    (pk.to_wif(), addr.to_string(), spk_hex)
}

/// GET `/v2/<path>` and parse the JSON body.
async fn api_get(client: &reqwest::Client, path: &str) -> serde_json::Value {
    let url = format!("{API_BASE}/v2/{path}");
    let body = client
        .get(&url)
        .send()
        .await
        .unwrap_or_else(|e| panic!("GET {url} failed: {e}"))
        .text()
        .await
        .unwrap_or_else(|e| panic!("reading body of {url} failed: {e}"));
    serde_json::from_str(&body).unwrap_or_else(|e| panic!("non-JSON body from {url}: {e}\n{body}"))
}

/// The `quantity` of the first entry of a `/balances/<asset>` response, or 0
/// when the address holds none of the asset.
fn first_balance_quantity(balances: &serde_json::Value) -> i64 {
    balances
        .get("result")
        .and_then(|r| r.as_array())
        .and_then(|a| a.first())
        .and_then(|e| e.get("quantity"))
        .and_then(|q| q.as_i64())
        .unwrap_or(0)
}

/// The current bitcoind block height.
fn chain_height() -> i64 {
    bitcoin_cli(&["getblockcount"])
        .parse()
        .expect("parse getblockcount output")
}

/// Wait until the Counterparty server is ready and has parsed up to at least
/// `target` (a concrete bitcoind height).
///
/// Waiting on an explicit height — rather than `counterparty_height >=
/// backend_height` — avoids a race right after mining, when the server can still
/// report the *pre-mine* backend height and so look "caught up" before it has
/// parsed the block we just mined. Mirrors the Python harness's
/// `wait_for_counterparty_server`, which waits for `counterparty_height >=
/// target_block`.
async fn wait_for_height(client: &reqwest::Client, target: i64) {
    for _ in 0..180 {
        let v = api_get(client, "").await;
        if let Some(r) = v.get("result") {
            let ready = r
                .get("server_ready")
                .and_then(|b| b.as_bool())
                .unwrap_or(false);
            let cp = r
                .get("counterparty_height")
                .and_then(|n| n.as_i64())
                .unwrap_or(-1);
            if ready && cp >= target {
                return;
            }
        }
        tokio::time::sleep(Duration::from_secs(1)).await;
    }
    panic!("counterparty-server did not reach height {target} within the timeout");
}

/// Mine `n` blocks to `address`, then block until the Counterparty server has
/// parsed up to the new tip — so the just-mined transactions' ledger effects
/// (burns, sends) are queryable over the API.
async fn mine_and_sync(client: &reqwest::Client, n: u32, address: &str) {
    mine(n, address);
    wait_for_height(client, chain_height()).await;
}

#[tokio::test]
#[ignore]
async fn full_fund_compose_sign_broadcast_accept_regtest() {
    let client = reqwest::Client::new();
    let home = tempfile::tempdir().expect("temp wallet home");

    wait_for_height(&client, chain_height()).await;

    // A wallet address to mine coinbase rewards to (Bitcoin Core's own wallet).
    let mining_addr = bitcoin_wallet(&["getnewaddress"]);

    // Source address `a` (imported into the xcp wallet, signs everything) and a
    // destination `b` (external — we only assert its credited balance).
    let (a_wif, a_addr, a_spk) = regtest_p2wpkh(0x11);
    let (_b_wif, b_addr, _b_spk) = regtest_p2wpkh(0x42);

    // 1) Import `a` into a fresh, isolated wallet. This first `xcp` invocation
    //    also *creates* the wallet, non-interactively, from XCP_WALLET_PASSWORD.
    let out = run_xcp(
        home.path(),
        &[
            "--regtest",
            "wallet",
            "import_address",
            "--private-key",
            &a_wif,
            "--label",
            "e2e-src",
        ],
    );
    assert_xcp_ok(&out, "import_address");

    // 2) Fund `a` with two independent UTXOs of known, exact value: one to burn,
    //    one to pay the send's fee. Knowing each UTXO's value exactly lets us
    //    build `inputs_set` without an on-chain (float) value lookup.
    let burn_fund_txid = bitcoin_wallet(&["sendtoaddress", &a_addr, "1.0"]); // 1.00000000 BTC
    let send_fund_txid = bitcoin_wallet(&["sendtoaddress", &a_addr, "0.01"]); // 0.01000000 BTC
    mine_and_sync(&client, 1, &mining_addr).await;

    let burn_inputs = format!(
        "{burn_fund_txid}:{}:100000000:{a_spk}",
        vout_paying(&burn_fund_txid, &a_spk)
    );
    let send_inputs = format!(
        "{send_fund_txid}:{}:1000000:{a_spk}",
        vout_paying(&send_fund_txid, &a_spk)
    );

    // 3) Burn 0.5 BTC from `a`: compose over the API, sign locally with the
    //    client's own signer, broadcast, and confirm. `a` gains XCP. `burn` is not
    //    a client-verifiable type, so `--yes` would not auto-confirm it; confirm at
    //    the prompt via stdin instead (see `run_xcp_with_stdin`).
    let out = run_xcp_with_stdin(
        home.path(),
        &[
            "--regtest",
            "wallet",
            "transaction",
            "burn",
            "--address",
            &a_addr,
            "--quantity",
            "0.5", // human-readable BTC -> 50_000_000 sats
            "--inputs_set",
            &burn_inputs,
            "--exact_fee",
            "10000",
            "--validate",
            "false",
            "--disable_utxo_locks",
            "true",
        ],
        "y\n",
    );
    assert_xcp_ok(&out, "transaction burn");
    mine_and_sync(&client, 1, &mining_addr).await;

    // The burn must have credited `a` with XCP.
    let a_balances = api_get(&client, &format!("addresses/{a_addr}/balances/XCP")).await;
    let a_xcp = first_balance_quantity(&a_balances);
    assert!(
        a_xcp > 0,
        "source address should hold XCP after burning, got {a_xcp}: {a_balances}"
    );

    // 4) Send 1 satoshi of XCP from `a` to `b`: a second real compose → sign →
    //    broadcast through the `xcp` binary. 1 sat is safely below `a`'s balance
    //    regardless of the regtest burn rate.
    let out = run_xcp(
        home.path(),
        &[
            "--regtest",
            "wallet",
            "transaction",
            "send",
            "--address",
            &a_addr,
            "--destination",
            &b_addr,
            "--asset",
            "XCP",
            "--quantity",
            "0.00000001", // human-readable XCP -> 1 sat
            "--inputs_set",
            &send_inputs,
            "--exact_fee",
            "10000",
            "--validate",
            "false",
            "--disable_utxo_locks",
            "true",
            "--yes",
        ],
    );
    assert_xcp_ok(&out, "transaction send");
    mine_and_sync(&client, 1, &mining_addr).await;

    // 5) Accept: the ledger credited `b` with exactly the 1 sat of XCP we sent —
    //    end-to-end proof the composed, locally-signed, broadcast transaction was
    //    valid to both bitcoind and Counterparty.
    let b_balances = api_get(&client, &format!("addresses/{b_addr}/balances/XCP")).await;
    let b_xcp = first_balance_quantity(&b_balances);
    assert_eq!(
        b_xcp, 1,
        "destination should have received exactly 1 sat of XCP: {b_balances}"
    );
}
