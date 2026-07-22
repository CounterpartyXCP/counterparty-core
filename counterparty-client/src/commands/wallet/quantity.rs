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

/// Divisibility-sensitive compose parameter names, mirroring the keys of
/// `quantity_fields` in counterparty-core's `api/verbose.py`. This is only a
/// safety net: any parameter listed here that `denomination` does *not* map for
/// the current transaction still triggers the "sent as satoshis" warning, so a
/// divisibility-governed value can never be silently passed through unconverted.
const KNOWN_QUANTITY_FIELDS: &[&str] = &[
    "quantity",
    "give_quantity",
    "get_quantity",
    "escrow_quantity",
    "dispense_quantity",
    "quantity_per_unit",
    "supply",
    "price",
    "hard_cap",
    "soft_cap",
    "quantity_by_price",
    "max_mint_per_tx",
    "max_mint_per_address",
    "premint_quantity",
    "pool_quantity",
    "give_price",
    "get_price",
    "quantity_a",
    "quantity_b",
    "reserve_a",
    "reserve_b",
    "mainchainrate",
    "satoshirate",
    "fee_required",
    "fee_provided",
    // `lot_price`/`lot_size` are the current canonical fairminter parameter
    // names (formerly `price`/`quantity_by_price`; the server still accepts
    // both). `lot_price` already matches the `price` root below, but is listed
    // explicitly for defense in depth; `lot_size` matches no root at all, so
    // without this entry it would be sent as raw satoshis with no warning.
    "lot_price",
    "lot_size",
    "wager_quantity",
    "counterwager_quantity",
    "min_quantity_a",
    "min_quantity_b",
    "min_lp_quantity",
    // Not a root match (no "value" in AMOUNT_ROOTS): the satoshi value of the
    // UTXO an `attach`/`movetoutxo` targets is otherwise silently unconverted
    // with no warning at all.
    "utxo_value",
];

/// Whether a parameter name looks like a divisibility-governed amount, used only
/// for the safety-net warning on parameters the divisibility map does not
/// explicitly cover. Kept deliberately broad (amount-like roots *plus* the
/// explicit [`KNOWN_QUANTITY_FIELDS`] list) so that if counterparty-core adds a
/// new quantity field before this client's map catches up, the value is flagged
/// as "sent as satoshis" rather than silently passed through unconverted.
///
/// The roots are chosen not to match known *non*-amount parameters (`asset`,
/// `address`, `value`, `fee_fraction`, `text`, …).
fn looks_like_amount(name: &str) -> bool {
    const AMOUNT_ROOTS: &[&str] = &["quantity", "amount", "supply", "reserve", "cap", "price"];
    AMOUNT_ROOTS.iter().any(|root| name.contains(root)) || KNOWN_QUANTITY_FIELDS.contains(&name)
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
        // Order match fee is paid in BTC (always divisible).
        ("order", "fee_required") => Denomination::Btc,
        ("dispense", "quantity") => Denomination::Btc,
        ("burn", "quantity") => Denomination::Btc,
        // Fairminter: every cap/mint quantity is denominated in the fairminted
        // asset (divisibility from `--divisible`, or the on-chain value when the
        // asset already exists). `price`/`lot_price` is the XCP paid per
        // `quantity_by_price`/`lot_size` units, and XCP is always divisible.
        ("fairminter", "hard_cap") => Denomination::IssuedAsset,
        ("fairminter", "soft_cap") => Denomination::IssuedAsset,
        ("fairminter", "premint_quantity") => Denomination::IssuedAsset,
        ("fairminter", "max_mint_per_tx") => Denomination::IssuedAsset,
        ("fairminter", "max_mint_per_address") => Denomination::IssuedAsset,
        ("fairminter", "quantity_by_price") => Denomination::IssuedAsset,
        ("fairminter", "pool_quantity") => Denomination::IssuedAsset,
        ("fairminter", "price") => Denomination::Btc,
        // `lot_price`/`lot_size` are the current canonical names for
        // `price`/`quantity_by_price` (the server accepts either); without
        // these, a fairminter composed via `--lot_size` would send a raw,
        // unconverted quantity — off by a factor of 1e8 for a divisible asset.
        ("fairminter", "lot_price") => Denomination::Btc,
        ("fairminter", "lot_size") => Denomination::IssuedAsset,
        // A bet's wager/counterwager are always denominated in XCP.
        ("bet", "wager_quantity") => Denomination::Btc,
        ("bet", "counterwager_quantity") => Denomination::Btc,
        // AMM pool deposit quantities are denominated in the two paired assets.
        ("pooldeposit", "quantity_a") => Denomination::Asset("asset_a"),
        ("pooldeposit", "quantity_b") => Denomination::Asset("asset_b"),
        // Pool withdrawal's minimum-received slippage bounds are denominated in
        // the same two assets (the `quantity` of LP tokens burned is left
        // unmapped: LP-token divisibility isn't derivable from asset_a/asset_b).
        ("poolwithdraw", "min_quantity_a") => Denomination::Asset("asset_a"),
        ("poolwithdraw", "min_quantity_b") => Denomination::Asset("asset_b"),
        // The UTXO's own BTC value (attach/movetoutxo) is a satoshi amount like
        // any other BTC-denominated field, not governed by `asset`'s divisibility.
        ("attach", "utxo_value") => Denomination::Btc,
        ("movetoutxo", "utxo_value") => Denomination::Btc,
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
    // Memoize each distinct asset's divisibility for the lifetime of this call,
    // so a transaction with several quantity fields governed by the same asset
    // (e.g. a fairminter's several caps, or a dispenser's give/escrow quantity)
    // issues at most one `GET /v2/assets/<asset>` per distinct asset instead of
    // one per field.
    let mut divisibility_cache: HashMap<String, bool> = HashMap::new();

    for (name, value) in params.iter() {
        match denomination(transaction_name, name) {
            Some(denom) => {
                let divisible = resolve_divisibility(
                    config,
                    transaction_name,
                    &denom,
                    params,
                    &mut divisibility_cache,
                )
                .await?;
                let converted = convert_quantity(value, divisible)
                    .map_err(|e| anyhow!("Invalid value for '--{}': {}", name, e))?;
                conversions.push((name.clone(), converted));
            }
            None if looks_like_amount(name) => {
                // A divisibility-sensitive parameter we do not auto-convert for
                // this transaction (e.g. an as-yet-unmapped AMM/mpma field): warn
                // rather than silently treat the human amount as satoshis.
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

/// Resolve whether the asset governing `denom` is divisible, memoizing the
/// result per asset name in `cache` (see [`normalize_quantities`]).
async fn resolve_divisibility(
    config: &AppConfig,
    transaction_name: &str,
    denom: &Denomination,
    params: &HashMap<String, String>,
    cache: &mut HashMap<String, bool>,
) -> Result<bool> {
    match denom {
        Denomination::Btc => Ok(true),
        Denomination::IssuedAsset => {
            // Prefer the on-chain divisibility when the asset already exists
            // (issuing more of an existing asset); otherwise use the flag.
            if let Some(asset) = params.get("asset") {
                if let Some(&divisible) = cache.get(asset) {
                    return Ok(divisible);
                }
                if let Some(divisible) = fetch_asset_divisible(config, asset).await? {
                    cache.insert(asset.clone(), divisible);
                    return Ok(divisible);
                }
            }
            Ok(issuance_divisible_flag(params))
        }
        Denomination::Asset(asset_param) => {
            let asset = params.get(*asset_param).ok_or_else(|| {
                anyhow!("cannot determine divisibility: missing '--{asset_param}'")
            })?;
            if let Some(&divisible) = cache.get(asset) {
                return Ok(divisible);
            }
            let divisible = fetch_asset_divisible(config, asset).await?.ok_or_else(|| {
                anyhow!(
                    "asset '{asset}' was not found, so its divisibility is unknown. \
                     If you already know the amount in satoshis, use 'api compose_{transaction_name}' instead."
                )
            })?;
            cache.insert(asset.clone(), divisible);
            Ok(divisible)
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
    let response = api::http_client(config.require_https())?
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
        // `checked_mul` (not `*`) because `rust_decimal`'s `Mul` panics on
        // overflow, and the product can exceed `Decimal::MAX` for very large
        // user-supplied amounts.
        let scaled = amount
            .checked_mul(Decimal::from(UNIT))
            .ok_or_else(|| anyhow!("quantity '{value}' is too large"))?;
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

    // Counterparty quantities are unsigned 64-bit satoshi integers. Reject
    // anything that does not fit: besides being invalid for the API, a value
    // above u64::MAX would make the independent verifier silently skip the
    // quantity check (its `parse::<u64>()` returns None).
    let satoshis = satoshis.trunc().to_u64().ok_or_else(|| {
        anyhow!("quantity '{value}' is out of range (must fit in a u64 of satoshis)")
    })?;
    Ok(satoshis.to_string())
}

// The live regtest integration test lives in a `*tests.rs` file so it is
// excluded from unit coverage (it needs a running counterparty-server and only
// runs under `--ignored`); see `quantity_regtest_tests.rs`.
#[cfg(test)]
#[path = "quantity_regtest_tests.rs"]
mod quantity_regtest_tests;

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
    fn rejects_amount_above_u64_max() {
        // 2e11 units * 1e8 = 2e19 sats, above u64::MAX (~1.84e19): must error, not
        // truncate (a truncated value would make the verifier skip the check).
        assert!(convert_quantity("200000000000", true).is_err());
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
        // Fairminter caps are denominated in the fairminted asset; `price` is XCP.
        assert!(matches!(
            denomination("fairminter", "hard_cap"),
            Some(Denomination::IssuedAsset)
        ));
        assert!(matches!(
            denomination("fairminter", "price"),
            Some(Denomination::Btc)
        ));
        assert!(matches!(
            denomination("order", "fee_required"),
            Some(Denomination::Btc)
        ));
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
    fn divisible_large_but_in_range_value_is_scaled() {
        // Largest whole-unit divisible amount whose satoshi value still fits u64:
        // 184_467_440_737 * 1e8 = 18_446_744_073_700_000_000 < u64::MAX.
        assert_eq!(
            convert_quantity("184467440737", true).unwrap(),
            "18446744073700000000"
        );
    }

    #[test]
    fn divisible_overflow_is_a_clean_error_not_a_panic() {
        // 1e21 parses as a Decimal (< Decimal::MAX ~7.9e28) but 1e21 * 1e8 = 1e29
        // overflows. This must return an error, never panic (`rust_decimal`'s `*`
        // aborts on overflow; the code uses `checked_mul`).
        let err = convert_quantity("1000000000000000000000", true).unwrap_err();
        assert!(
            err.to_string().contains("too large"),
            "expected a 'too large' error, got: {err}"
        );
    }

    #[test]
    fn indivisible_max_u64_is_unchanged_and_beyond_is_rejected() {
        // Counterparty quantities are u64: u64::MAX passes unchanged...
        let max = "18446744073709551615";
        assert_eq!(convert_quantity(max, false).unwrap(), max);
        // ...and anything above it is rejected (never truncated/wrapped).
        assert!(convert_quantity("18446744073709551616", false).is_err());
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
    fn denomination_covers_lot_price_lot_size_bet_pool_and_attach() {
        // Regression: `lot_price`/`lot_size` are the fairminter's current
        // canonical parameter names (the server still accepts the deprecated
        // `price`/`quantity_by_price` aliases too) and must convert exactly like
        // their aliases.
        assert!(matches!(
            denomination("fairminter", "lot_price"),
            Some(Denomination::Btc)
        ));
        assert!(matches!(
            denomination("fairminter", "lot_size"),
            Some(Denomination::IssuedAsset)
        ));
        assert!(matches!(
            denomination("bet", "wager_quantity"),
            Some(Denomination::Btc)
        ));
        assert!(matches!(
            denomination("bet", "counterwager_quantity"),
            Some(Denomination::Btc)
        ));
        assert!(matches!(
            denomination("pooldeposit", "quantity_a"),
            Some(Denomination::Asset("asset_a"))
        ));
        assert!(matches!(
            denomination("pooldeposit", "quantity_b"),
            Some(Denomination::Asset("asset_b"))
        ));
        assert!(matches!(
            denomination("poolwithdraw", "min_quantity_a"),
            Some(Denomination::Asset("asset_a"))
        ));
        assert!(matches!(
            denomination("poolwithdraw", "min_quantity_b"),
            Some(Denomination::Asset("asset_b"))
        ));
        assert!(matches!(
            denomination("attach", "utxo_value"),
            Some(Denomination::Btc)
        ));
        assert!(matches!(
            denomination("movetoutxo", "utxo_value"),
            Some(Denomination::Btc)
        ));
    }

    #[tokio::test]
    async fn normalize_quantities_fairminter_lot_size_scales_like_quantity_by_price() {
        // HIGH-severity regression: before `lot_size` was mapped, this field
        // matched no denomination and no safety-net root, so it was sent as a
        // raw (unconverted) integer — a silent 1e8x error for a divisible asset.
        let mut server = mockito::Server::new_async().await;
        let _m = server
            .mock("GET", "/v2/assets/LOTTOKEN")
            .with_status(200)
            .with_body(r#"{"result":null}"#)
            .create_async()
            .await;
        let config = config_for(&server);
        let mut params = HashMap::new();
        params.insert("asset".to_string(), "LOTTOKEN".to_string());
        params.insert("lot_size".to_string(), "5".to_string());
        params.insert("lot_price".to_string(), "0.5".to_string());

        normalize_quantities(&config, "fairminter", &mut params)
            .await
            .unwrap();

        assert_eq!(params.get("lot_size").unwrap(), "500000000");
        assert_eq!(params.get("lot_price").unwrap(), "50000000");
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
        // Non-quantity fairminter params (block heights, description) and the
        // fairmint-only `quantity` name are not mapped for fairminter.
        assert!(denomination("fairminter", "start_block").is_none());
        assert!(denomination("fairminter", "quantity").is_none());
        assert!(denomination("unknown_tx", "quantity").is_none());
    }

    #[test]
    fn known_quantity_fields_guard_catches_unmapped_fairminter_and_amm() {
        // These divisibility-sensitive fields are not mapped by `denomination`
        // for every transaction, so the safety-net set must list them to force a
        // warning instead of a silent satoshi pass-through.
        for field in ["hard_cap", "soft_cap", "price", "reserve_a", "quantity_a"] {
            assert!(
                KNOWN_QUANTITY_FIELDS.contains(&field),
                "'{field}' must be in the quantity-field guard"
            );
        }
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

    // ---- network-backed divisibility resolution (hermetic via mockito) ----

    fn config_for(server: &mockito::ServerGuard) -> AppConfig {
        let mut config = AppConfig::new();
        config.set_network(crate::config::Network::Regtest);
        let nc = config
            .network_configs
            .get_mut(&crate::config::Network::Regtest)
            .unwrap();
        nc.api_url = server.url();
        nc.endpoints_url = format!("{}/v2/routes", server.url());
        config
    }

    #[tokio::test]
    async fn fetch_asset_divisible_shortcuts_btc_and_xcp_without_network() {
        // BTC and XCP are hard-coded divisible; no server is contacted.
        let config = AppConfig::new();
        assert_eq!(
            fetch_asset_divisible(&config, "BTC").await.unwrap(),
            Some(true)
        );
        assert_eq!(
            fetch_asset_divisible(&config, "XCP").await.unwrap(),
            Some(true)
        );
    }

    #[tokio::test]
    async fn fetch_asset_divisible_reads_flag_from_api() {
        let mut server = mockito::Server::new_async().await;
        let _m = server
            .mock("GET", "/v2/assets/RARE")
            .with_status(200)
            .with_body(r#"{"result":{"asset":"RARE","divisible":false}}"#)
            .create_async()
            .await;
        let config = config_for(&server);
        assert_eq!(
            fetch_asset_divisible(&config, "RARE").await.unwrap(),
            Some(false)
        );
    }

    #[tokio::test]
    async fn fetch_asset_divisible_returns_none_when_asset_absent() {
        let mut server = mockito::Server::new_async().await;
        let _m = server
            .mock("GET", "/v2/assets/GHOST")
            .with_status(200)
            .with_body(r#"{"result":null}"#)
            .create_async()
            .await;
        let config = config_for(&server);
        assert_eq!(fetch_asset_divisible(&config, "GHOST").await.unwrap(), None);
    }

    #[tokio::test]
    async fn normalize_quantities_scales_divisible_api_asset() {
        let mut server = mockito::Server::new_async().await;
        let _m = server
            .mock("GET", "/v2/assets/PEPECASH")
            .with_status(200)
            .with_body(r#"{"result":{"divisible":true}}"#)
            .create_async()
            .await;
        let config = config_for(&server);
        let mut params = HashMap::new();
        params.insert("asset".to_string(), "PEPECASH".to_string());
        params.insert("quantity".to_string(), "2".to_string());
        normalize_quantities(&config, "send", &mut params)
            .await
            .unwrap();
        assert_eq!(params.get("quantity").unwrap(), "200000000");
    }

    #[tokio::test]
    async fn normalize_quantities_leaves_indivisible_api_asset_whole() {
        let mut server = mockito::Server::new_async().await;
        let _m = server
            .mock("GET", "/v2/assets/RAREPEPE")
            .with_status(200)
            .with_body(r#"{"result":{"divisible":false}}"#)
            .create_async()
            .await;
        let config = config_for(&server);
        let mut params = HashMap::new();
        params.insert("asset".to_string(), "RAREPEPE".to_string());
        params.insert("quantity".to_string(), "5".to_string());
        normalize_quantities(&config, "send", &mut params)
            .await
            .unwrap();
        assert_eq!(params.get("quantity").unwrap(), "5");
    }

    #[tokio::test]
    async fn normalize_quantities_errors_when_asset_unknown() {
        let mut server = mockito::Server::new_async().await;
        let _m = server
            .mock("GET", "/v2/assets/NOPE")
            .with_status(200)
            .with_body(r#"{"result":null}"#)
            .create_async()
            .await;
        let config = config_for(&server);
        let mut params = HashMap::new();
        params.insert("asset".to_string(), "NOPE".to_string());
        params.insert("quantity".to_string(), "1".to_string());
        let err = normalize_quantities(&config, "send", &mut params)
            .await
            .unwrap_err();
        assert!(err.to_string().contains("not found"), "got: {err}");
    }

    #[tokio::test]
    async fn normalize_quantities_issuance_prefers_onchain_divisibility() {
        // Reissuing an existing indivisible asset: the on-chain divisibility
        // (false) overrides the issuance `--divisible` default (true).
        let mut server = mockito::Server::new_async().await;
        let _m = server
            .mock("GET", "/v2/assets/EXISTING")
            .with_status(200)
            .with_body(r#"{"result":{"divisible":false}}"#)
            .create_async()
            .await;
        let config = config_for(&server);
        let mut params = HashMap::new();
        params.insert("asset".to_string(), "EXISTING".to_string());
        params.insert("quantity".to_string(), "7".to_string());
        normalize_quantities(&config, "issuance", &mut params)
            .await
            .unwrap();
        assert_eq!(params.get("quantity").unwrap(), "7");
    }

    #[tokio::test]
    async fn normalize_quantities_fetches_divisibility_once_per_distinct_asset() {
        // Three quantity fields governed by the same asset must issue exactly
        // one `GET /v2/assets/<asset>`, not three — `mockito`'s `.expect(1)` +
        // `.assert_async()` fails the test otherwise.
        let mut server = mockito::Server::new_async().await;
        let m = server
            .mock("GET", "/v2/assets/MEMOTOKEN")
            .with_status(200)
            .with_body(r#"{"result":{"divisible":true}}"#)
            .expect(1)
            .create_async()
            .await;
        let config = config_for(&server);
        let mut params = HashMap::new();
        params.insert("asset".to_string(), "MEMOTOKEN".to_string());
        params.insert("hard_cap".to_string(), "10".to_string());
        params.insert("soft_cap".to_string(), "5".to_string());
        params.insert("premint_quantity".to_string(), "1".to_string());

        normalize_quantities(&config, "fairminter", &mut params)
            .await
            .unwrap();

        assert_eq!(params.get("hard_cap").unwrap(), "1000000000");
        assert_eq!(params.get("soft_cap").unwrap(), "500000000");
        assert_eq!(params.get("premint_quantity").unwrap(), "100000000");
        m.assert_async().await;
    }

    #[tokio::test]
    async fn normalize_quantities_fairminter_scales_new_divisible_asset() {
        // A brand-new fairminter asset (absent on-chain) takes divisibility from
        // the `--divisible` default (true), so its caps are scaled by 1e8. This is
        // the HIGH-severity regression: these fields used to be sent as satoshis
        // with no conversion and no warning.
        let mut server = mockito::Server::new_async().await;
        let _m = server
            .mock("GET", "/v2/assets/NEWTOKEN")
            .with_status(200)
            .with_body(r#"{"result":null}"#)
            .create_async()
            .await;
        let config = config_for(&server);
        let mut params = HashMap::new();
        params.insert("asset".to_string(), "NEWTOKEN".to_string());
        params.insert("hard_cap".to_string(), "1000".to_string());
        params.insert("soft_cap".to_string(), "500".to_string());
        // `price` is XCP (always divisible), converted independently of the asset.
        params.insert("price".to_string(), "0.5".to_string());

        normalize_quantities(&config, "fairminter", &mut params)
            .await
            .unwrap();

        assert_eq!(params.get("hard_cap").unwrap(), "100000000000");
        assert_eq!(params.get("soft_cap").unwrap(), "50000000000");
        assert_eq!(params.get("price").unwrap(), "50000000");
    }

    #[tokio::test]
    async fn normalize_quantities_fairminter_existing_indivisible_asset_keeps_caps_whole() {
        // Fairminting more of an existing indivisible asset: the on-chain
        // divisibility (false) governs the caps, so they stay whole.
        let mut server = mockito::Server::new_async().await;
        let _m = server
            .mock("GET", "/v2/assets/HARDTOKEN")
            .with_status(200)
            .with_body(r#"{"result":{"divisible":false}}"#)
            .create_async()
            .await;
        let config = config_for(&server);
        let mut params = HashMap::new();
        params.insert("asset".to_string(), "HARDTOKEN".to_string());
        params.insert("hard_cap".to_string(), "1000".to_string());
        params.insert("max_mint_per_tx".to_string(), "10".to_string());

        normalize_quantities(&config, "fairminter", &mut params)
            .await
            .unwrap();

        assert_eq!(params.get("hard_cap").unwrap(), "1000");
        assert_eq!(params.get("max_mint_per_tx").unwrap(), "10");
    }

    #[tokio::test]
    async fn normalize_quantities_warns_and_passes_through_unmapped_quantity() {
        // A `*quantity*` param on a transaction with no denomination mapping is
        // passed through unchanged (with a warning), never silently scaled.
        let config = AppConfig::new();
        let mut params = HashMap::new();
        params.insert("quantity".to_string(), "123".to_string());
        normalize_quantities(&config, "mpma", &mut params)
            .await
            .unwrap();
        assert_eq!(params.get("quantity").unwrap(), "123");
    }
}
