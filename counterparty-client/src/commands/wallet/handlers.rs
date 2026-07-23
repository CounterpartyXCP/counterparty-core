use anyhow::{anyhow, Result};
use clap::ArgMatches;
use zeroize::Zeroizing;

use std::collections::HashMap;
use std::io::{self, IsTerminal, Write};

use crate::commands::api;
use crate::config::AppConfig;

use crate::helpers;
use crate::wallet::BitcoinWallet;

/// Handle the new_address subcommand - generates a new random address
pub fn handle_new_address(wallet: &mut BitcoinWallet, sub_matches: &ArgMatches) -> Result<()> {
    // Extract parameters
    let label = sub_matches.get_one::<String>("label").map(|s| s.as_str());
    let address_type = sub_matches
        .get_one::<String>("address_type")
        .map(|s| s.as_str());

    // Call the wallet function with no private key or mnemonic (for random generation)
    let (address, mnemonic) = wallet
        .add_address(None, None, None, label, address_type)
        .map_err(|e| anyhow!("Failed to generate new address: {}", e))?;

    helpers::print_success("New address generated successfully:", Some(&address));

    // Surface the seed phrase ONCE so the user can back it up. The wallet stores
    // only the derived key (exportable via `export_address`); this mnemonic is
    // not persisted anywhere and cannot be shown again.
    if let Some(phrase) = mnemonic {
        helpers::print_warning(
            "Write down this recovery phrase now — it is shown only once and is NOT stored:",
            None,
        );
        println!("{}", phrase.as_str());
    }
    Ok(())
}

/// A private key (WIF) or mnemonic to import, held in a [`Zeroizing`] buffer so
/// our owned copy is wiped from memory when dropped rather than lingering on the
/// heap. (A value supplied via a plain `--private-key`/`--mnemonic` flag still
/// also lives in clap's `ArgMatches` for the process lifetime and in the shell
/// history / process list — prefer the `@<file>` form or the no-echo prompt.)
type Secret = Zeroizing<String>;

/// Handle the import_address subcommand - imports an existing key
pub fn handle_import_address(wallet: &mut BitcoinWallet, sub_matches: &ArgMatches) -> Result<()> {
    // Extract parameters. The secret flags support the safe `@<file>` form; wrap
    // our copy in `Zeroizing` so it is scrubbed on drop.
    let flag_private_key = sub_matches
        .get_one::<String>("private_key")
        .map(|s| Zeroizing::new(s.clone()));
    let flag_mnemonic = sub_matches
        .get_one::<String>("mnemonic")
        .map(|s| Zeroizing::new(s.clone()));
    let path = sub_matches.get_one::<String>("path").map(|s| s.as_str());
    let label = sub_matches.get_one::<String>("label").map(|s| s.as_str());
    let address_type = sub_matches
        .get_one::<String>("address_type")
        .map(|s| s.as_str());

    // Resolve the secret. When neither flag is supplied, prompt without echo
    // (interactive sessions only) so the private key / mnemonic never lands in
    // the shell history or process list — the safest way to import.
    let (private_key, mnemonic) =
        resolve_import_secret(flag_private_key, flag_mnemonic, io::stdin().is_terminal())?;

    // Call the wallet function (imported keys never return a mnemonic). The
    // secrets stay in their `Zeroizing` buffers until dropped at end of scope.
    let (address, _) = wallet
        .add_address(
            private_key.as_ref().map(|s| s.as_str()),
            mnemonic.as_ref().map(|s| s.as_str()),
            path,
            label,
            address_type,
        )
        .map_err(|e| anyhow!("Failed to import address: {}", e))?;

    helpers::print_success("Address imported successfully:", Some(&address));
    Ok(())
}

/// Decide which secret to import: the supplied flags (which support `@<file>`)
/// if present, otherwise prompt without echo — but only when `interactive`. In a
/// non-interactive context (a script, a pipe) prompting would hang, so return a
/// clear error instead. `interactive` is threaded in (rather than read here) so
/// this is unit-testable without depending on the ambient terminal.
fn resolve_import_secret(
    flag_private_key: Option<Secret>,
    flag_mnemonic: Option<Secret>,
    interactive: bool,
) -> Result<(Option<Secret>, Option<Secret>)> {
    match (flag_private_key, flag_mnemonic) {
        (None, None) => {
            if interactive {
                prompt_import_secret()
            } else {
                Err(anyhow!(
                    "Provide --private-key or --mnemonic (use the @<file> form to keep the \
                     secret out of your shell history), or run interactively to be prompted."
                ))
            }
        }
        (pk, mn) => Ok((pk, mn)),
    }
}

/// Prompt (without echo) for a private key or mnemonic to import. A value with
/// whitespace is treated as a BIP39 mnemonic; a single token as a WIF private
/// key. Returns `(private_key, mnemonic)` for `add_address`, each in a
/// [`Zeroizing`] buffer.
fn prompt_import_secret() -> Result<(Option<Secret>, Option<Secret>)> {
    helpers::print_warning(
        "Enter a private key (WIF) or a BIP39 mnemonic phrase. Input is hidden.",
        None,
    );
    print!("Secret: ");
    io::stdout().flush().ok();

    // `rpassword` returns a plain `String`; move it straight into a `Zeroizing`
    // buffer and trim in place so the untrimmed copy is scrubbed too.
    let secret = Zeroizing::new(
        rpassword::read_password()
            .map_err(|e| anyhow!("Failed to read secret: {}", e))?
            .trim()
            .to_string(),
    );

    if secret.is_empty() {
        return Err(anyhow!("No secret entered"));
    }

    // A BIP39 mnemonic is multiple space-separated words; a WIF is a single token.
    if secret.split_whitespace().count() > 1 {
        Ok((None, Some(secret)))
    } else {
        Ok((Some(secret), None))
    }
}

/// Handle the export_address subcommand
pub fn handle_export_address(wallet: &BitcoinWallet, sub_matches: &ArgMatches) -> Result<()> {
    let address = sub_matches.get_one::<String>("address").unwrap();

    // Exporting reveals the private key in clear text, so confirm first unless
    // the user explicitly opted in with --yes.
    if !sub_matches.get_flag("yes") && !confirm_reveal_private_key(address)? {
        helpers::print_error("Export cancelled", None);
        return Ok(());
    }

    let mut details = wallet
        .show_address(address)
        .map_err(|e| anyhow!("Failed to export address details: {}", e))?;

    // Hold the revealed WIF in a Zeroizing buffer and fold it into the output
    // only at the last moment before printing, so the plaintext key is not kept
    // in a long-lived, un-zeroized value any longer than the reveal requires.
    // (Exporting inherently prints the WIF; the on-screen output is plaintext by
    // design.)
    let wif = wallet
        .export_wif(address)
        .map_err(|e| anyhow!("Failed to export private key: {}", e))?;
    details["private_key"] = serde_json::Value::String(wif.to_string());

    helpers::print_colored_json(&details)?;
    Ok(())
}

/// Prompt the user before revealing an address's private key. Returns true only
/// on an explicit yes.
fn confirm_reveal_private_key(address: &str) -> Result<bool> {
    helpers::print_warning(
        "This will print the PRIVATE KEY for this address in clear text.",
        None,
    );
    print!("Reveal the private key for {}? (y/N): ", address);
    io::stdout().flush().ok();

    let mut input = String::new();
    io::stdin().read_line(&mut input)?;
    let input = input.trim().to_lowercase();
    Ok(input == "y" || input == "yes")
}

/// Handle the list_addresses subcommand
pub fn handle_list_addresses(wallet: &BitcoinWallet) -> Result<()> {
    let addresses = wallet
        .list_addresses()
        .map_err(|e| anyhow!("Failed to list addresses: {}", e))?;

    helpers::print_colored_json_list(&addresses)?;
    Ok(())
}

/// Handle the change_password subcommand
pub fn handle_change_password(wallet: &mut BitcoinWallet, _sub_matches: &ArgMatches) -> Result<()> {
    // Call the wallet function to change the password
    wallet
        .change_password()
        .map_err(|e| anyhow!("Failed to change password: {}", e))?;

    helpers::print_success("Password changed successfully", None);
    Ok(())
}

/// Handle the disconnect subcommand
pub fn handle_disconnect(wallet: &mut BitcoinWallet, _sub_matches: &ArgMatches) -> Result<()> {
    // Call the wallet function to clear the password
    wallet
        .disconnect()
        .map_err(|e| anyhow!("Failed to disconnect wallet: {}", e))?;

    helpers::print_success("Wallet disconnected successfully", None);
    Ok(())
}

/// Handle the address_balances subcommand - retrieves balances for a specific address from the API
pub async fn handle_address_balances(config: &AppConfig, sub_matches: &ArgMatches) -> Result<()> {
    // Extract address from arguments
    let address = sub_matches.get_one::<String>("address").unwrap();

    // First, get Bitcoin balance from UTXOs
    let btc_api_path = format!("/v2/bitcoin/addresses/{}/utxos", address);
    let btc_result = api::perform_api_request(config, &btc_api_path, &HashMap::new()).await?;

    // Calculate total BTC balance. Error (rather than silently skip) on a UTXO
    // whose `value` is missing or not an integer number of satoshis, so a format
    // change can never quietly undercount the balance; guard the sum against
    // overflow (release builds do not check arithmetic overflow).
    let mut btc_balance: u64 = 0;
    if let Some(utxos) = btc_result.get("result").and_then(|r| r.as_array()) {
        for utxo in utxos {
            let value = utxo.get("value").and_then(|v| v.as_u64()).ok_or_else(|| {
                anyhow!("a UTXO 'value' from the API is missing or not an integer of satoshis")
            })?;
            btc_balance = btc_balance
                .checked_add(value)
                .ok_or_else(|| anyhow!("BTC balance sum overflowed u64"))?;
        }
    }

    // Now get Counterparty token balances with verbose=true parameter
    let cp_api_path = format!("/v2/addresses/{}/balances", address);

    // Create a HashMap for query parameters
    let mut query_params = HashMap::new();
    query_params.insert("verbose".to_string(), "true".to_string());

    let cp_result = api::perform_api_request(config, &cp_api_path, &query_params).await?;

    // Process and display combined results
    if let Some(balances) = cp_result.get("result") {
        if let Some(balances_array) = balances.as_array() {
            // Create a new array for the cleaned balances
            let mut cleaned_balances = Vec::new();

            // Add BTC balance entry at the beginning, converting satoshis to BTC (divide by 10^8)
            let mut btc_entry = serde_json::Map::new();
            btc_entry.insert(
                "asset".to_string(),
                serde_json::Value::String("BTC".to_string()),
            );

            // Convert to floating point and divide by 10^8
            let btc_amount = (btc_balance as f64) / 100_000_000.0;

            // Format as string with 8 decimal places to ensure consistent display
            let btc_amount_str = format!("{:.8}", btc_amount);

            // Insert as string value
            btc_entry.insert(
                "quantity".to_string(),
                serde_json::Value::String(btc_amount_str),
            );

            // Add divisible flag for BTC
            btc_entry.insert("divisible".to_string(), serde_json::Value::Bool(true));

            cleaned_balances.push(serde_json::Value::Object(btc_entry));

            // Process Counterparty token balances with the new structure
            for balance in balances_array {
                if let Some(balance_obj) = balance.as_object() {
                    // Create a new object for this balance entry
                    let mut cleaned_balance = serde_json::Map::new();

                    // Add asset field
                    if let Some(asset) = balance_obj.get("asset") {
                        cleaned_balance.insert("asset".to_string(), asset.clone());
                    }

                    // Add longname field only if not null
                    if let Some(asset_longname) = balance_obj.get("asset_longname") {
                        if !asset_longname.is_null() {
                            cleaned_balance.insert("longname".to_string(), asset_longname.clone());
                        }
                    }

                    // Add divisible field from asset_info
                    if let Some(asset_info) =
                        balance_obj.get("asset_info").and_then(|ai| ai.as_object())
                    {
                        if let Some(divisible) = asset_info.get("divisible") {
                            cleaned_balance.insert("divisible".to_string(), divisible.clone());
                        }
                    }

                    // Get quantity from the quantity_normalized field at root level
                    if let Some(quantity_normalized) = balance_obj.get("quantity_normalized") {
                        // Use the value exactly as it appears in the original JSON
                        cleaned_balance.insert("quantity".to_string(), quantity_normalized.clone());
                    }

                    // Add the cleaned balance to our array
                    if cleaned_balance.contains_key("asset") {
                        cleaned_balances.push(serde_json::Value::Object(cleaned_balance));
                    }
                }
            }

            // Convert to Value and display
            let cleaned_result = serde_json::Value::Array(cleaned_balances);
            helpers::print_colored_json(&cleaned_result)?;
        } else {
            // If not an array, just display as-is plus BTC balance
            let mut combined_result = serde_json::Map::new();
            combined_result.insert(
                "BTC".to_string(),
                serde_json::Value::Number(serde_json::Number::from(btc_balance)),
            );
            combined_result.insert("tokens".to_string(), balances.clone());
            helpers::print_colored_json(&serde_json::Value::Object(combined_result))?;
        }
    } else if let Some(error) = cp_result.get("error") {
        // Surface as a returned error (non-zero exit), matching
        // `execute_api_command`'s convention, instead of printing and
        // returning `Ok` — otherwise a script checking `$?` after
        // `wallet address_balances` cannot detect a failed lookup.
        return Err(anyhow!("API error: {}", error));
    } else {
        return Err(anyhow!("Unexpected API response format"));
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::Network;
    use clap::{Arg, ArgAction, Command};

    fn wallet() -> (BitcoinWallet, tempfile::TempDir) {
        let dir = tempfile::tempdir().unwrap();
        (
            BitcoinWallet::new_for_test(dir.path(), Network::Regtest),
            dir,
        )
    }

    fn config_for(server: &mockito::ServerGuard) -> AppConfig {
        let mut config = AppConfig::new();
        config.set_network(Network::Regtest);
        let nc = config.network_configs.get_mut(&Network::Regtest).unwrap();
        nc.api_url = server.url();
        nc.endpoints_url = format!("{}/v2/routes", server.url());
        config
    }

    fn regtest_wif(seed: u8) -> String {
        let sk = bitcoin::secp256k1::SecretKey::from_slice(&[seed; 32]).unwrap();
        bitcoin::PrivateKey::new(sk, bitcoin::Network::Regtest).to_wif()
    }

    // ---- new_address ----

    fn new_address_cmd() -> Command {
        Command::new("new_address")
            .arg(Arg::new("label").long("label"))
            .arg(Arg::new("address_type").long("address-type"))
    }

    #[test]
    fn handle_new_address_with_flags_generates_and_stores() {
        let (mut w, _dir) = wallet();
        let m = new_address_cmd()
            .try_get_matches_from([
                "new_address",
                "--label",
                "cold",
                "--address-type",
                "taproot",
            ])
            .unwrap();
        handle_new_address(&mut w, &m).unwrap();
        let list = w.list_addresses().unwrap();
        assert_eq!(list.len(), 1);
        assert_eq!(list[0]["label"], "cold");
    }

    #[test]
    fn handle_new_address_without_flags_uses_defaults() {
        let (mut w, _dir) = wallet();
        let m = new_address_cmd()
            .try_get_matches_from(["new_address"])
            .unwrap();
        handle_new_address(&mut w, &m).unwrap();
        assert_eq!(w.list_addresses().unwrap().len(), 1);
    }

    // ---- import_address ----

    fn import_cmd() -> Command {
        Command::new("import_address")
            .arg(Arg::new("private_key").long("private-key"))
            .arg(Arg::new("mnemonic").long("mnemonic"))
            .arg(Arg::new("path").long("path"))
            .arg(Arg::new("label").long("label"))
            .arg(Arg::new("address_type").long("address-type"))
    }

    #[test]
    fn resolve_import_secret_non_interactive_requires_a_flag() {
        // Non-interactive + no flags => a clear error (never a hanging prompt).
        let err = resolve_import_secret(None, None, false).unwrap_err();
        assert!(err.to_string().contains("private-key"), "got: {err}");
    }

    #[test]
    fn resolve_import_secret_passes_flags_through() {
        // A supplied flag is returned as-is and never triggers a prompt (so this
        // is safe to run even with `interactive = true`).
        let (pk, mn) =
            resolve_import_secret(Some(Zeroizing::new("cWifValue".to_string())), None, true)
                .unwrap();
        assert_eq!(pk.as_ref().map(|s| s.as_str()), Some("cWifValue"));
        assert!(mn.is_none());

        let (pk2, mn2) = resolve_import_secret(
            None,
            Some(Zeroizing::new("word word word".to_string())),
            true,
        )
        .unwrap();
        assert!(pk2.is_none());
        assert_eq!(mn2.as_ref().map(|s| s.as_str()), Some("word word word"));
    }

    #[test]
    fn handle_import_address_with_private_key_stores_it() {
        let (mut w, _dir) = wallet();
        let wif = regtest_wif(9);
        let m = import_cmd()
            .try_get_matches_from(["import_address", "--private-key", &wif, "--label", "imp"])
            .unwrap();
        handle_import_address(&mut w, &m).unwrap();
        assert_eq!(w.list_addresses().unwrap().len(), 1);
    }

    // ---- export_address ----

    fn export_cmd() -> Command {
        Command::new("export_address")
            .arg(Arg::new("address").long("address"))
            .arg(Arg::new("yes").long("yes").action(ArgAction::SetTrue))
    }

    #[test]
    fn handle_export_address_with_yes_reveals_details() {
        let (mut w, _dir) = wallet();
        let (addr, _) = w.add_address(None, None, None, None, None).unwrap();
        let m = export_cmd()
            .try_get_matches_from(["export_address", "--address", &addr, "--yes"])
            .unwrap();
        handle_export_address(&w, &m).unwrap();
    }

    #[test]
    fn handle_export_address_unknown_address_errors() {
        let (w, _dir) = wallet();
        let m = export_cmd()
            .try_get_matches_from(["export_address", "--address", "bcrt1qmissing", "--yes"])
            .unwrap();
        assert!(handle_export_address(&w, &m).is_err());
    }

    // ---- list_addresses ----

    #[test]
    fn handle_list_addresses_runs() {
        let (mut w, _dir) = wallet();
        w.add_address(None, None, None, None, None).unwrap();
        handle_list_addresses(&w).unwrap();
    }

    // ---- address_balances (async, hermetic via mockito) ----

    fn balances_cmd(addr: &str) -> ArgMatches {
        Command::new("address_balances")
            .arg(Arg::new("address").long("address"))
            .try_get_matches_from(["address_balances", "--address", addr])
            .unwrap()
    }

    #[tokio::test]
    async fn handle_address_balances_combines_btc_and_token_array() {
        let mut server = mockito::Server::new_async().await;
        let addr = "bcrt1qbal";
        let _utxos = server
            .mock(
                "GET",
                format!("/v2/bitcoin/addresses/{addr}/utxos").as_str(),
            )
            .with_status(200)
            .with_body(r#"{"result":[{"value":100000000},{"value":50000000}]}"#)
            .create_async()
            .await;
        let _bal = server
            .mock("GET", format!("/v2/addresses/{addr}/balances").as_str())
            .match_query(mockito::Matcher::Any)
            .with_status(200)
            .with_body(
                r#"{"result":[{"asset":"XCP","asset_longname":null,"asset_info":{"divisible":true},"quantity_normalized":"1.5"}]}"#,
            )
            .create_async()
            .await;

        let config = config_for(&server);
        handle_address_balances(&config, &balances_cmd(addr))
            .await
            .unwrap();
    }

    #[tokio::test]
    async fn handle_address_balances_reports_api_error() {
        let mut server = mockito::Server::new_async().await;
        let addr = "bcrt1qerr";
        let _utxos = server
            .mock(
                "GET",
                format!("/v2/bitcoin/addresses/{addr}/utxos").as_str(),
            )
            .with_body(r#"{"result":[]}"#)
            .create_async()
            .await;
        let _bal = server
            .mock("GET", format!("/v2/addresses/{addr}/balances").as_str())
            .match_query(mockito::Matcher::Any)
            .with_body(r#"{"error":"boom"}"#)
            .create_async()
            .await;

        let config = config_for(&server);
        // The handler surfaces the API error as a returned `Err` (non-zero
        // exit), not a silent `Ok`.
        assert!(handle_address_balances(&config, &balances_cmd(addr))
            .await
            .is_err());
    }

    #[tokio::test]
    async fn handle_address_balances_handles_non_array_result() {
        let mut server = mockito::Server::new_async().await;
        let addr = "bcrt1qobj";
        let _utxos = server
            .mock(
                "GET",
                format!("/v2/bitcoin/addresses/{addr}/utxos").as_str(),
            )
            .with_body(r#"{"result":[{"value":42}]}"#)
            .create_async()
            .await;
        let _bal = server
            .mock("GET", format!("/v2/addresses/{addr}/balances").as_str())
            .match_query(mockito::Matcher::Any)
            .with_body(r#"{"result":{"XCP":"1"}}"#)
            .create_async()
            .await;

        let config = config_for(&server);
        handle_address_balances(&config, &balances_cmd(addr))
            .await
            .unwrap();
    }
}
