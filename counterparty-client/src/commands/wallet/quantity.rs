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
}
