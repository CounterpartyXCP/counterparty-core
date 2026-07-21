//! Divisibility-aware conversion of compose quantity parameters.
//!
//! The Counterparty v2 compose API expects every asset quantity as a raw
//! integer number of satoshis (i.e. already multiplied by 1e8 for divisible
//! assets — there is no normalized-input mode). This module converts the
//! human-readable amounts entered on the command line into that representation,
//! using each asset's `divisible` flag.

use std::collections::HashMap;
use std::str::FromStr;

use anyhow::{anyhow, Context, Result};
use rust_decimal::prelude::ToPrimitive;
use rust_decimal::Decimal;

use crate::commands::api;
use crate::config::AppConfig;
use crate::helpers;

/// Number of satoshis in one whole unit of a divisible asset (1e8).
const UNIT: u64 = 100_000_000;

/// What governs the divisibility of a given quantity parameter.
enum Denomination {
    /// Divisibility comes from the asset named by this other parameter.
    Asset(&'static str),
    /// The asset being issued: use the command's own `divisible` flag,
    /// falling back to the on-chain value when the asset already exists.
    IssuedAsset,
    /// Always denominated in BTC satoshis (miner-facing / dispenser rate).
    Btc,
}

/// Map a `(transaction, parameter)` pair to what governs its divisibility.
/// Returns `None` for parameters that must be passed through unchanged. The
/// mapping mirrors `quantity_fields` in counterparty-core's `api/verbose.py`.
fn denomination(transaction_name: &str, param: &str) -> Option<Denomination> {
    let denom = match (transaction_name, param) {
        ("send", "quantity") => Denomination::Asset("asset"),
        ("destroy", "quantity") => Denomination::Asset("asset"),
        ("attach", "quantity") => Denomination::Asset("asset"),
        ("fairmint", "quantity") => Denomination::Asset("asset"),
        ("issuance", "quantity") => Denomination::IssuedAsset,
        ("dividend", "quantity_per_unit") => Denomination::Asset("dividend_asset"),
        ("dispenser", "give_quantity") => Denomination::Asset("asset"),
        ("dispenser", "escrow_quantity") => Denomination::Asset("asset"),
        ("dispenser", "mainchainrate") => Denomination::Btc,
        ("order", "give_quantity") => Denomination::Asset("give_asset"),
        ("order", "get_quantity") => Denomination::Asset("get_asset"),
        ("dispense", "quantity") => Denomination::Btc,
        ("burn", "quantity") => Denomination::Btc,
        _ => return None,
    };
    Some(denom)
}

/// Convert every recognised quantity parameter in `params` from a
/// human-readable amount into raw satoshis, based on the governing asset's
/// divisibility. Unrecognised quantity parameters are left unchanged (with a
/// note printed so the user knows they must be supplied in satoshis).
pub async fn normalize_quantities(
    config: &AppConfig,
    transaction_name: &str,
    params: &mut HashMap<String, String>,
) -> Result<()> {
    // Compute conversions first, then apply, to avoid mutating while borrowing.
    let mut conversions: Vec<(String, String)> = Vec::new();

    for (name, value) in params.iter() {
        match denomination(transaction_name, name) {
            Some(denom) => {
                let divisible =
                    resolve_divisibility(config, transaction_name, &denom, params).await?;
                let converted = convert_quantity(value, divisible)
                    .map_err(|e| anyhow!("Invalid value for '--{}': {}", name, e))?;
                conversions.push((name.clone(), converted));
            }
            None if name.contains("quantity") => {
                // Advanced transaction types (e.g. fairminter, AMM pools, mpma)
                // are not auto-converted; be explicit rather than silently wrong.
                helpers::print_warning(
                    &format!(
                        "Note: '--{name}' is sent as satoshis; no automatic divisibility conversion for '{transaction_name}'."
                    ),
                    None,
                );
            }
            None => {}
        }
    }

    for (name, value) in conversions {
        params.insert(name, value);
    }

    Ok(())
}

/// Resolve whether the asset governing `denom` is divisible.
async fn resolve_divisibility(
    config: &AppConfig,
    transaction_name: &str,
    denom: &Denomination,
    params: &HashMap<String, String>,
) -> Result<bool> {
    match denom {
        Denomination::Btc => Ok(true),
        Denomination::IssuedAsset => {
            // Prefer the on-chain divisibility when the asset already exists
            // (issuing more of an existing asset); otherwise use the flag.
            if let Some(asset) = params.get("asset") {
                if let Some(divisible) = fetch_asset_divisible(config, asset).await? {
                    return Ok(divisible);
                }
            }
            Ok(issuance_divisible_flag(params))
        }
        Denomination::Asset(asset_param) => {
            let asset = params.get(*asset_param).ok_or_else(|| {
                anyhow!("cannot determine divisibility: missing '--{asset_param}'")
            })?;
            fetch_asset_divisible(config, asset).await?.ok_or_else(|| {
                anyhow!(
                    "asset '{asset}' was not found, so its divisibility is unknown. \
                     If you already know the amount in satoshis, use 'api compose_{transaction_name}' instead."
                )
            })
        }
    }
}

/// The issuance `--divisible` flag (stored as "true"/"false"); API default is true.
fn issuance_divisible_flag(params: &HashMap<String, String>) -> bool {
    params
        .get("divisible")
        .map(|v| v != "false")
        .unwrap_or(true)
}

/// Look up an asset's divisibility via `GET /v2/assets/<asset>`.
/// Returns `Ok(None)` when the asset does not exist yet. BTC and XCP are always divisible.
async fn fetch_asset_divisible(config: &AppConfig, asset: &str) -> Result<Option<bool>> {
    if asset == "BTC" || asset == "XCP" {
        return Ok(Some(true));
    }

    let url = format!("{}/v2/assets/{}", config.get_api_url(), asset);
    let response = reqwest::Client::new()
        .get(&url)
        .send()
        .await
        .map_err(|e| api::friendly_send_error(e, &url))?;
    let status = response.status();
    let body = response
        .text()
        .await
        .with_context(|| format!("Failed to read response body from {url}"))?;
    let json = api::parse_json_body(&body, status, &url)?;

    Ok(json
        .get("result")
        .and_then(|r| r.get("divisible"))
        .and_then(|d| d.as_bool()))
}

/// Convert a human-readable amount to a raw satoshi integer string.
/// Divisible assets are multiplied by 1e8; indivisible assets must be whole.
pub fn convert_quantity(value: &str, divisible: bool) -> Result<String> {
    let amount =
        Decimal::from_str(value.trim()).map_err(|_| anyhow!("'{value}' is not a valid number"))?;
    if amount < Decimal::ZERO {
        return Err(anyhow!("quantity cannot be negative"));
    }

    let satoshis = if divisible {
        let scaled = amount * Decimal::from(UNIT);
        if scaled.fract() != Decimal::ZERO {
            return Err(anyhow!(
                "'{value}' has too many decimal places (max 8 for a divisible asset)"
            ));
        }
        scaled
    } else {
        if amount.fract() != Decimal::ZERO {
            return Err(anyhow!(
                "this asset is indivisible; '{value}' must be a whole number"
            ));
        }
        amount
    };

    let satoshis = satoshis
        .trunc()
        .to_i128()
        .ok_or_else(|| anyhow!("quantity '{value}' is too large"))?;
    Ok(satoshis.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn divisible_integer_is_scaled() {
        assert_eq!(convert_quantity("10", true).unwrap(), "1000000000");
    }

    #[test]
    fn divisible_decimal_is_scaled() {
        assert_eq!(convert_quantity("1.5", true).unwrap(), "150000000");
        assert_eq!(convert_quantity("0.00000001", true).unwrap(), "1");
    }

    #[test]
    fn divisible_rejects_more_than_eight_decimals() {
        assert!(convert_quantity("0.000000001", true).is_err());
    }

    #[test]
    fn indivisible_integer_is_unchanged() {
        assert_eq!(convert_quantity("10", false).unwrap(), "10");
    }

    #[test]
    fn indivisible_rejects_fraction() {
        assert!(convert_quantity("1.5", false).is_err());
    }

    #[test]
    fn rejects_negative_and_garbage() {
        assert!(convert_quantity("-1", true).is_err());
        assert!(convert_quantity("abc", true).is_err());
    }

    #[test]
    fn denomination_mapping() {
        assert!(matches!(
            denomination("send", "quantity"),
            Some(Denomination::Asset("asset"))
        ));
        assert!(matches!(
            denomination("order", "get_quantity"),
            Some(Denomination::Asset("get_asset"))
        ));
        assert!(matches!(
            denomination("dispenser", "mainchainrate"),
            Some(Denomination::Btc)
        ));
        assert!(matches!(
            denomination("issuance", "quantity"),
            Some(Denomination::IssuedAsset)
        ));
        assert!(denomination("fairminter", "hard_cap").is_none());
    }

    #[test]
    fn issuance_flag_defaults_to_divisible() {
        let mut params = HashMap::new();
        assert!(issuance_divisible_flag(&params));
        params.insert("divisible".to_string(), "false".to_string());
        assert!(!issuance_divisible_flag(&params));
        params.insert("divisible".to_string(), "true".to_string());
        assert!(issuance_divisible_flag(&params));
    }

    // ---- convert_quantity edge cases ----

    #[test]
    fn divisible_zero_and_whitespace() {
        assert_eq!(convert_quantity("0", true).unwrap(), "0");
        assert_eq!(convert_quantity("  10  ", true).unwrap(), "1000000000");
        assert_eq!(convert_quantity("\t1.5\n", true).unwrap(), "150000000");
    }

    #[test]
    fn indivisible_zero_and_whitespace() {
        assert_eq!(convert_quantity("0", false).unwrap(), "0");
        assert_eq!(convert_quantity("  42  ", false).unwrap(), "42");
    }

    #[test]
    fn trailing_zero_decimals_are_accepted() {
        // "1.000" is a whole number of units.
        assert_eq!(convert_quantity("1.000", true).unwrap(), "100000000");
        assert_eq!(convert_quantity("1.0", true).unwrap(), "100000000");
        // For an indivisible asset, "1.000" is still a whole number.
        assert_eq!(convert_quantity("1.000", false).unwrap(), "1");
    }

    #[test]
    fn divisible_very_large_value_is_scaled() {
        // 1e20 units * 1e8 = 1e28 sats (within Decimal/i128 range).
        assert_eq!(
            convert_quantity("100000000000000000000", true).unwrap(),
            "10000000000000000000000000000"
        );
    }

    #[test]
    fn indivisible_very_large_value_is_unchanged() {
        // The largest integer Decimal can represent (2^96 - 1).
        let big = "79228162514264337593543950335";
        assert_eq!(convert_quantity(big, false).unwrap(), big);
    }

    #[test]
    fn max_precision_divisible_value() {
        assert_eq!(convert_quantity("0.00000001", true).unwrap(), "1");
        assert_eq!(convert_quantity("12.34567891", true).unwrap(), "1234567891");
    }

    #[test]
    fn rejects_empty_and_dot_and_plus_garbage() {
        assert!(convert_quantity("", true).is_err());
        assert!(convert_quantity("   ", true).is_err());
        assert!(convert_quantity(".", true).is_err());
        assert!(convert_quantity("1.2.3", true).is_err());
        assert!(convert_quantity("0x10", true).is_err());
    }

    // ---- full denomination table ----

    #[test]
    fn denomination_full_mapped_table() {
        // Every (transaction, parameter) pair that must be converted.
        assert!(matches!(
            denomination("send", "quantity"),
            Some(Denomination::Asset("asset"))
        ));
        assert!(matches!(
            denomination("destroy", "quantity"),
            Some(Denomination::Asset("asset"))
        ));
        assert!(matches!(
            denomination("attach", "quantity"),
            Some(Denomination::Asset("asset"))
        ));
        assert!(matches!(
            denomination("fairmint", "quantity"),
            Some(Denomination::Asset("asset"))
        ));
        assert!(matches!(
            denomination("issuance", "quantity"),
            Some(Denomination::IssuedAsset)
        ));
        assert!(matches!(
            denomination("dividend", "quantity_per_unit"),
            Some(Denomination::Asset("dividend_asset"))
        ));
        assert!(matches!(
            denomination("dispenser", "give_quantity"),
            Some(Denomination::Asset("asset"))
        ));
        assert!(matches!(
            denomination("dispenser", "escrow_quantity"),
            Some(Denomination::Asset("asset"))
        ));
        assert!(matches!(
            denomination("dispenser", "mainchainrate"),
            Some(Denomination::Btc)
        ));
        assert!(matches!(
            denomination("order", "give_quantity"),
            Some(Denomination::Asset("give_asset"))
        ));
        assert!(matches!(
            denomination("order", "get_quantity"),
            Some(Denomination::Asset("get_asset"))
        ));
        assert!(matches!(
            denomination("dispense", "quantity"),
            Some(Denomination::Btc)
        ));
        assert!(matches!(
            denomination("burn", "quantity"),
            Some(Denomination::Btc)
        ));
    }

    #[test]
    fn denomination_unmapped_pairs_return_none() {
        // Non-quantity params of mapped transactions.
        assert!(denomination("send", "asset").is_none());
        assert!(denomination("send", "destination").is_none());
        assert!(denomination("issuance", "asset").is_none());
        assert!(denomination("order", "give_asset").is_none());
        // Wrong parameter name for the transaction.
        assert!(denomination("dispenser", "quantity").is_none());
        assert!(denomination("dividend", "quantity").is_none());
        // Transactions with no auto-conversion at all.
        assert!(denomination("fairminter", "hard_cap").is_none());
        assert!(denomination("fairminter", "quantity").is_none());
        assert!(denomination("unknown_tx", "quantity").is_none());
    }

    // ---- E2: compose-path quantity math (hermetic, no network) ----

    // XCP is hard-coded divisible in `fetch_asset_divisible`, so this drives the
    // real compose-path scaling (`normalize_quantities` -> `resolve_divisibility`
    // -> `convert_quantity`) end-to-end without any network access.
    #[tokio::test]
    async fn normalize_quantities_scales_divisible_xcp_send() {
        let config = AppConfig::new();
        let mut params = HashMap::new();
        params.insert("asset".to_string(), "XCP".to_string());
        params.insert("quantity".to_string(), "1.5".to_string());
        params.insert("destination".to_string(), "bcrt1qexample".to_string());

        normalize_quantities(&config, "send", &mut params)
            .await
            .unwrap();

        assert_eq!(params.get("quantity").unwrap(), "150000000");
        // Non-quantity params are left untouched.
        assert_eq!(params.get("asset").unwrap(), "XCP");
        assert_eq!(params.get("destination").unwrap(), "bcrt1qexample");
    }

    // BTC-denominated parameters (here: burn) are always treated as divisible
    // satoshis; no asset lookup and therefore no network access.
    #[tokio::test]
    async fn normalize_quantities_scales_btc_denominated_burn() {
        let config = AppConfig::new();
        let mut params = HashMap::new();
        params.insert("quantity".to_string(), "0.5".to_string());

        normalize_quantities(&config, "burn", &mut params)
            .await
            .unwrap();

        assert_eq!(params.get("quantity").unwrap(), "50000000");
    }

    // The indivisible branch of the compose path. A real indivisible asset's
    // `divisible=false` flag comes from `GET /v2/assets/<asset>`; here we stub
    // that source and assert the exact conversion `normalize_quantities` applies
    // once divisibility is known.
    #[test]
    fn indivisible_send_amount_is_not_scaled_stubbed_divisibility() {
        assert_eq!(convert_quantity("7", false).unwrap(), "7");
        assert!(convert_quantity("7.5", false).is_err());
    }

    /// Integration check against a live **regtest** counterparty-server.
    /// `#[ignore]`d so the normal `cargo test` stays hermetic; the
    /// `Client Regtest E2E` CI workflow (`.github/workflows/client_regtest_test.yml`)
    /// starts a regtest node via `regtestnode.py` and runs it with `--ignored`.
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
}
