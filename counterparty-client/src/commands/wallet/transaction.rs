use anyhow::{anyhow, Context, Result};
use clap::ArgMatches;
use std::collections::HashMap;
use std::io::{self, Write};
use std::str::FromStr;

use rust_decimal::prelude::ToPrimitive;
use rust_decimal::Decimal;
use termcolor::{Color, ColorChoice, ColorSpec, StandardStream, WriteColor};

use crate::bitcoinsigner;
use crate::commands::api;
use crate::commands::api::{ApiEndpoint, ApiEndpointArg};
use crate::commands::wallet::args;
use crate::config::AppConfig;
use crate::helpers;
use crate::wallet::BitcoinWallet;

/// Information needed for reveal transaction
struct RevealTransactionInfo<'a> {
    signed_tx: &'a str,
}

/// Absolute ceiling on the miner fee the client will sign without complaint
/// (0.01 BTC). A composed transfer is a small transaction, so a fee above this
/// signals either a server bug or a hostile server inflating/burning BTC to
/// fees. The fee is derived from the server-reported input values; for legacy
/// (P2PKH) inputs those amounts are not committed by the signature, so this
/// bound is a safety net, not a guarantee — prefer segwit/taproot addresses.
const MAX_REASONABLE_FEE_SAT: u64 = 1_000_000;

/// Absolute ceiling (0.01 BTC) on the value of the commit's first output
/// (`commit:0`) — the envelope a taproot data reveal spends. The reveal is
/// composed AND signed by the server and broadcast verbatim (its outputs are
/// never independently verified), so the value of the single output it spends is
/// all that bounds how much it can pay away. A legitimate reveal needs only
/// enough to cover its own miner fee, far below this; a larger `commit:0` is a
/// server bug or a siphon attempt. Defense-in-depth behind the human review
/// (commit/reveal are `Unverified`, so `--yes` cannot skip that review).
const MAX_REVEAL_ENVELOPE_SAT: u64 = 1_000_000;

/// Refuse to sign a transaction whose miner fee exceeds [`MAX_REASONABLE_FEE_SAT`],
/// and report whether that fee could be **conclusively** bounded.
///
/// The fee is derived from the *server-reported* input values. Two ways that can
/// be gamed are surfaced instead of silently trusted, and both mean the cap is
/// not a guarantee — so the transaction may still be broadcast (after review),
/// but `--yes` must not auto-confirm it (the caller enforces this):
///
/// * a legacy (P2PKH) input's amount is not committed by its signature (BIP143
///   covers segwit only), so a server can under-report it to hide an inflated
///   real fee — a warning is printed when such an input is present;
/// * if the reported inputs are not greater than the outputs the fee cannot be
///   computed at all (`calculate_transaction_fee` returns `None`), which is
///   exactly the shape of an under-reporting server — warn loudly rather than
///   passing the cap silently (the previous fail-*open* behaviour).
///
/// Returns `Err` when the fee is computable and over the cap (a hard refusal),
/// `Ok(true)` when the fee is computable, within the cap, and every input's
/// amount is signature-committed, and `Ok(false)` when the fee could not be
/// conclusively bounded (either case above).
fn ensure_fee_within_limit(raw_tx_hex: &str, utxo_list: &bitcoinsigner::UTXOList) -> Result<bool> {
    let tx_bytes =
        hex::decode(raw_tx_hex).map_err(|e| anyhow!("Failed to decode transaction hex: {}", e))?;
    let tx: bitcoin::Transaction = bitcoin::consensus::deserialize(&tx_bytes)
        .map_err(|e| anyhow!("Failed to parse transaction: {}", e))?;

    let mut fee_conclusive = true;

    match calculate_transaction_fee(&tx, utxo_list) {
        Some(fee) if fee > MAX_REASONABLE_FEE_SAT => {
            return Err(anyhow!(
                "SECURITY: the composed transaction pays a miner fee of {} sats ({:.8} BTC), above \
                 the client's {} sat safety limit. Refusing to sign. If this is intentional, use the \
                 expert `api compose_*` path.",
                fee,
                fee as f64 / 100_000_000.0,
                MAX_REASONABLE_FEE_SAT
            ));
        }
        Some(_) => {}
        None => {
            fee_conclusive = false;
            helpers::print_warning(
                "\u{26A0} Could not verify the miner fee: the server-reported input values are not \
                 greater than the outputs, so the fee safety limit could not be enforced.",
                Some("Check the fee shown in the summary below before confirming."),
            );
        }
    }

    if utxo_list
        .as_ref()
        .iter()
        .any(|u| u.get_type() == bitcoinsigner::UTXOType::P2PKH)
    {
        fee_conclusive = false;
        helpers::print_warning(
            "\u{26A0} This transaction spends a legacy (P2PKH) input whose amount the signature does \
             not commit to, so the miner-fee safety limit cannot be guaranteed for it.",
            Some("Prefer segwit/taproot addresses; verify the fee in the summary below."),
        );
    }

    Ok(fee_conclusive)
}

/// Find the corresponding compose endpoint for a transaction command.
///
/// If the endpoint declares no `address`/`source` parameter (a UTXO-sourced
/// compose such as `detach`/`movetoutxo`, whose source is a `<utxo>` path
/// segment), a synthetic required `--address` is added so the CLI can learn which
/// wallet key must sign. The returned `bool` reports whether that injection
/// happened: an injected `address` is a **local-only** hint (used to pick the
/// signing key) and must NOT be forwarded to the compose API — those endpoints
/// take no `address` argument, so sending one would be a stray query parameter
/// the server may reject or ignore.
fn find_compose_endpoint<'a>(
    endpoints: &'a HashMap<String, ApiEndpoint>,
    transaction_name: &str,
) -> Result<(&'a String, ApiEndpoint, bool)> {
    // Convert transaction name to compose_X to find the matching endpoint
    let compose_name = format!("compose_{}", transaction_name);

    // Find matching endpoint for the compose function
    let (path, endpoint) = api::find_matching_endpoint(endpoints, &compose_name)?;

    // Check if the endpoint already has an address or source parameter
    let has_address = endpoint
        .args
        .iter()
        .any(|arg| arg.name == "address" || arg.name == "source");

    if has_address {
        // If it already has an address parameter, just return it (not injected).
        Ok((path, endpoint.clone(), false))
    } else {
        // Otherwise, create a modified endpoint with an address parameter
        let mut modified_endpoint = endpoint.clone();

        // Create a new address argument
        let address_arg = ApiEndpointArg {
            name: "address".to_string(),
            required: true,
            arg_type: "string".to_string(),
            description: Some("Wallet address that owns the source UTXO and signs the transaction (used locally to select the signing key; not sent to the server)".to_string()),
            default: None,
            members: None,
        };

        // Add the address parameter to the endpoint's arguments
        modified_endpoint.args.push(address_arg);

        // Return the modified endpoint, flagged as address-injected.
        Ok((path, modified_endpoint, true))
    }
}

/// Extract parameters from command line arguments
fn extract_parameters_from_matches(
    endpoint: &ApiEndpoint,
    transaction_name: &str,
    sub_matches: &ArgMatches,
) -> HashMap<String, String> {
    let mut params = HashMap::new();
    let id_map = args::id_arg_map();

    for arg in &endpoint.args {
        extract_parameter_for_arg(arg, transaction_name, sub_matches, &id_map, &mut params);
    }

    // Always add verbose=true
    params.insert("verbose".to_string(), "true".to_string());

    params
}

/// Extract a specific parameter for an argument
fn extract_parameter_for_arg(
    arg: &ApiEndpointArg,
    transaction_name: &str,
    sub_matches: &ArgMatches,
    id_map: &HashMap<String, String>,
    params: &mut HashMap<String, String>,
) {
    // Try to find the argument by iterating through the id_map
    for (key, original_name) in id_map.iter() {
        if key.starts_with(&format!("{}:", transaction_name)) && original_name == &arg.name {
            // Extract the internal ID from the key
            let internal_id = key.split(':').nth(1).unwrap_or("");

            if let Some(value) = sub_matches.get_one::<String>(internal_id) {
                params.insert(arg.name.clone(), value.clone());
                return;
            }
        }
    }

    // For debugging
    if arg.required {
        helpers::print_warning("Required argument not found in matches:", Some(&arg.name));
    }
}

/// Get blockchain explorer URL based on network and transaction ID
fn get_explorer_url(network: crate::config::Network, tx_id: &str) -> String {
    match network {
        crate::config::Network::Mainnet => format!("https://mempool.space/tx/{}", tx_id),
        crate::config::Network::Signet => format!("https://mempool.space/signet/tx/{}", tx_id),
        crate::config::Network::Testnet4 => format!("https://mempool.space/testnet4/tx/{}", tx_id),
        crate::config::Network::Regtest => format!("Transaction ID: {}", tx_id), // No explorer for regtest
    }
}

/// Determine the script type from a ScriptBuf
fn get_script_type(script: &bitcoin::ScriptBuf) -> &'static str {
    // Check for common script patterns
    if script.is_p2pkh() {
        "P2PKH"
    } else if script.is_p2sh() {
        "P2SH"
    } else if script.is_p2wpkh() {
        "P2WPKH"
    } else if script.is_p2wsh() {
        "P2WSH"
    } else if script.is_p2tr() {
        "P2TR"
    } else if script.is_op_return() {
        "OP_RETURN"
    } else {
        "UNKNOWN"
    }
}

/// The stream for human-facing transaction output: stdout normally, but stderr
/// (uncoloured) in `--json` mode so machine-readable stdout stays clean.
fn summary_stream() -> StandardStream {
    if helpers::json_output() {
        StandardStream::stderr(ColorChoice::Never)
    } else {
        StandardStream::stdout(ColorChoice::Always)
    }
}

/// Parse a signed transaction and display inputs, outputs, and fees
/// Shows addresses instead of raw scripts and decodes OP_RETURN data
fn display_transaction_summary(
    signed_tx: &str,
    utxo_list: &bitcoinsigner::UTXOList,
    network: crate::config::Network,
) -> Result<()> {
    // Decode the transaction from hex
    let tx_bytes =
        hex::decode(signed_tx).map_err(|e| anyhow!("Failed to decode transaction hex: {}", e))?;

    // Parse the transaction
    let tx: bitcoin::Transaction = bitcoin::consensus::deserialize(&tx_bytes)
        .map_err(|e| anyhow!("Failed to parse transaction: {}", e))?;

    // Get the transaction ID (hash)
    let txid = tx.compute_txid().to_string();

    // Get counts
    let input_count = tx.input.len();
    let output_count = tx.output.len();

    // Human-facing summary: keep stdout clean for `--json` by routing it to
    // stderr (uncoloured) in JSON mode, exactly like `helpers::print_*`.
    let mut stdout = summary_stream();

    // Define colors (without bold)
    let mut title_color = ColorSpec::new();
    title_color.set_fg(Some(Color::Green));

    let mut subtitle_color = ColorSpec::new();
    subtitle_color.set_fg(Some(Color::Cyan));

    let mut text_color = ColorSpec::new();
    text_color.set_fg(Some(Color::White));

    // Display title in green
    let _ = stdout.set_color(&title_color);
    let _ = writeln!(stdout, "Transaction details:");
    let _ = stdout.reset();

    // Display txid
    let _ = stdout.set_color(&subtitle_color);
    let _ = write!(stdout, "txid: ");
    let _ = stdout.set_color(&text_color);
    let _ = writeln!(stdout, "{}", txid);
    let _ = stdout.reset();

    // Display inputs with count in cyan
    let _ = stdout.set_color(&subtitle_color);
    let _ = writeln!(stdout, "Inputs ({}):", input_count);
    let _ = stdout.reset();

    // List inputs with addresses and amounts
    // We'll assume UTXOs are in the same order as inputs, which is common
    for (idx, input) in tx.input.iter().enumerate() {
        let _ = stdout.set_color(&text_color);
        let txid = input.previous_output.txid.to_string();
        let vout = input.previous_output.vout;

        // Get the UTXO if available at this index
        if let Some(utxo) = utxo_list.get(idx) {
            // Get amount in BTC
            let amount_btc = utxo.amount as f64 / 100_000_000.0;

            // Try to get address from the UTXO
            let address = if let Some(source_addr) = &utxo.source_address {
                // Use source_address if available
                source_addr.clone()
            } else {
                // Otherwise try to convert script_pubkey to address
                script_to_address(&utxo.script_pubkey, network)
                    .unwrap_or_else(|| "[Unable to derive address]".to_string())
            };

            let _ = writeln!(
                stdout,
                "{:.8} BTC, {} ({}:{})",
                amount_btc, address, txid, vout
            );
        } else {
            // Fallback if no UTXO info is available for this input
            let _ = writeln!(stdout, "{}:{}", txid, vout);
        }
    }

    // Display outputs with count in cyan
    let _ = stdout.set_color(&subtitle_color);
    let _ = writeln!(stdout, "Outputs ({}):", output_count);
    let _ = stdout.reset();

    // List outputs
    for output in &tx.output {
        let _ = stdout.set_color(&text_color);
        // Convert satoshis to BTC
        let value_btc = output.value.to_sat() as f64 / 100_000_000.0;

        // Get script type
        let script_type = get_script_type(&output.script_pubkey);

        // Handle output display based on script type
        if output.script_pubkey.is_op_return() {
            // For OP_RETURN, display the decoded data directly
            let decoded_data = extract_op_return_data(&output.script_pubkey);
            let _ = writeln!(stdout, "{:.8} BTC, OP_RETURN {}", value_btc, decoded_data);
        } else {
            // For other scripts, try to convert to address
            let address = script_to_address(&output.script_pubkey, network)
                .unwrap_or_else(|| output.script_pubkey.to_string());

            let _ = writeln!(
                stdout,
                "{:.8} BTC, {} ({})",
                value_btc, address, script_type
            );
        }
    }

    // Calculate and display transaction fee if possible
    if let Some(fee) = calculate_transaction_fee(&tx, utxo_list) {
        let fee_btc = fee as f64 / 100_000_000.0;
        let _ = stdout.set_color(&subtitle_color);
        let _ = write!(stdout, "Fee: ");
        let _ = stdout.set_color(&text_color);
        let _ = writeln!(stdout, "{:.8} BTC", fee_btc);
        let _ = stdout.reset();
    }

    let _ = writeln!(stdout);

    // Reset color at the end
    let _ = stdout.reset();

    Ok(())
}

/// Calculate the transaction fee by comparing input and output amounts
fn calculate_transaction_fee(
    tx: &bitcoin::Transaction,
    utxo_list: &bitcoinsigner::UTXOList,
) -> Option<u64> {
    // Sum with checked arithmetic: the input amounts are server-reported, so an
    // absurd value must yield "uncomputable" (None) — never an overflow panic
    // (release builds enable `overflow-checks`) or a silent wrap that could hide a
    // real inflated fee under the cap.
    let total_input = utxo_list
        .as_ref()
        .iter()
        .try_fold(0u64, |acc, utxo| acc.checked_add(utxo.amount))?;
    let total_output = tx
        .output
        .iter()
        .try_fold(0u64, |acc, output| acc.checked_add(output.value.to_sat()))?;

    // Fee = inputs - outputs; outputs > inputs means the reported inputs are
    // inconsistent, so the fee is uncomputable (`checked_sub` -> None).
    total_input.checked_sub(total_output)
}

/// Extract raw bytes from OP_RETURN data
fn extract_op_return_data(script: &bitcoin::ScriptBuf) -> String {
    if !script.is_op_return() {
        return "<not an OP_RETURN>".to_string();
    }

    // Walk the script: OP_RETURN (0x6a) then a push whose header depends on the
    // data length. For <= 75 bytes the opcode IS the length; OP_PUSHDATA1 (0x4c)
    // is followed by a 1-byte length. Anything larger doesn't occur in
    // Counterparty OP_RETURNs.
    let raw = script.as_bytes();
    if raw.len() < 2 {
        return "<no data>".to_string();
    }
    let data = match raw[1] {
        0x4c if raw.len() >= 3 => &raw[3..], // OP_PUSHDATA1 <len> <data>
        op if op <= 75 => &raw[2..],         // direct push <data>
        _ => &raw[2..],
    };

    // Hex-encode rather than rendering the raw bytes as text. The OP_RETURN
    // payload is server-controlled (and, for Counterparty, RC4-obfuscated random
    // bytes), so a text rendering could smuggle ANSI/terminal escape sequences
    // into the pre-broadcast summary and rewrite what the user reviews.
    hex::encode(data)
}

/// Convert a script to a Bitcoin address based on the network
fn script_to_address(
    script: &bitcoin::ScriptBuf,
    network: crate::config::Network,
) -> Option<String> {
    // Convert network to Bitcoin network
    let bitcoin_network = match network {
        crate::config::Network::Mainnet => bitcoin::Network::Bitcoin,
        crate::config::Network::Signet => bitcoin::Network::Signet,
        crate::config::Network::Testnet4 => bitcoin::Network::Testnet,
        crate::config::Network::Regtest => bitcoin::Network::Regtest,
    };

    // Try to create address from script
    bitcoin::Address::from_script(script, bitcoin_network)
        .map(|addr| addr.to_string())
        .ok()
}

/// Ask for user confirmation before broadcasting
fn confirm_broadcast() -> Result<bool> {
    // Prompt on the human stream (stderr in --json mode) so stdout stays clean.
    let mut stdout = summary_stream();

    // Define green bold color
    let mut prompt_color = ColorSpec::new();
    prompt_color.set_fg(Some(Color::Green)).set_bold(true);

    // Display prompt in green bold
    let _ = stdout.set_color(&prompt_color);
    let _ = write!(stdout, "Confirm broadcast (y/N): ");
    let _ = stdout.reset();

    // Flush to ensure prompt is displayed before waiting for input
    stdout.flush()?;

    // Get user input
    let mut input = String::new();
    io::stdin().read_line(&mut input)?;

    let input = input.trim().to_lowercase();
    Ok(input == "y" || input == "yes")
}

/// Broadcast a signed transaction to the network
async fn broadcast_transaction(config: &AppConfig, signed_tx: &str) -> Result<String> {
    let client = api::http_client(config.require_https())?;
    let api_url = config.get_api_url();

    // Broadcast endpoint. The signed hex goes in the POST body only (not the
    // query string) so a large multi-input transaction can't overflow the URL.
    let broadcast_url = format!("{}/v2/bitcoin/transactions", api_url);

    // Create URL-encoded form data
    let params = [("signedhex", signed_tx)];

    // Send POST request with URL-encoded form
    let response = client
        .post(&broadcast_url)
        .form(&params)
        .send()
        .await
        .map_err(|e| api::friendly_send_error(e, &broadcast_url))?;

    // Parse the response (as text first so a non-JSON body is reported clearly)
    let status = response.status();
    let body = response
        .text()
        .await
        .with_context(|| format!("Failed to read response body from {}", broadcast_url))?;
    let result = api::parse_json_body(&body, status, &broadcast_url)?;

    // Extract transaction ID from the response
    if let Some(tx_id) = result.get("result").and_then(|r| r.as_str()) {
        Ok(tx_id.to_string())
    } else if let Some(error) = result.get("error") {
        Err(api::friendly_api_error(error))
    } else {
        Err(anyhow!("Unexpected response format"))
    }
}

/// Get address and public key from parameters and wallet
fn get_address_and_public_key(
    params: &HashMap<String, String>,
    wallet: &BitcoinWallet,
) -> Result<String> {
    // Try to find the address parameter (commonly named 'source' or 'address')
    let address = params
        .get("source")
        .or_else(|| params.get("address"))
        .ok_or_else(|| anyhow!("Address parameter not found"))?
        .clone();

    // Verify that the address exists in the wallet and get its details
    let addr_details = wallet
        .show_address(&address)
        .map_err(|_| anyhow!("Address {} not found in wallet", address))?;

    // Extract the public key from the address details
    let public_key = addr_details
        .get("public_key")
        .and_then(|v| v.as_str())
        .ok_or_else(|| anyhow!("Public key not found for address {}", address))?;

    Ok(public_key.to_string())
}

/// Call the compose API and return the result
async fn call_compose_api(
    config: &AppConfig,
    path: &str,
    endpoint: &ApiEndpoint,
    params: &mut HashMap<String, String>,
) -> Result<serde_json::Value> {
    // Call API and get the result. `build_api_path` strips any path parameters
    // from `params` so they are not also sent as duplicate query parameters.
    let api_path = api::build_api_path(path, endpoint, params);
    let result = api::perform_api_request(config, &api_path, params).await?;

    // Check if we have a 'result' field in the response
    if let Some(api_result) = result.get("result") {
        Ok(api_result.clone())
    } else if let Some(error) = result.get("error") {
        // Handle API error with an actionable message (e.g. insufficient BTC)
        Err(api::friendly_api_error(error))
    } else {
        // Generic error if neither 'result' nor 'error' is present
        Err(anyhow!("Unexpected API response format"))
    }
}

/// Extract transaction details from API result
fn extract_transaction_details(
    api_result: &serde_json::Value,
) -> Result<(
    &str,
    Vec<(&str, u64)>,
    Option<&str>,
    Option<serde_json::Value>,
)> {
    // Extract required fields from result
    let raw_tx_hex = api_result
        .get("rawtransaction")
        .and_then(|v| v.as_str())
        .ok_or_else(|| anyhow!("Missing rawtransaction in API response"))?;

    // Error (rather than silently drop with `filter_map`) on any non-conforming
    // element: dropping a malformed entry from each array could leave them the
    // same length but misaligned, producing a wrong UTXO set for signing.
    let inputs_values = api_result
        .get("inputs_values")
        .and_then(|v| v.as_array())
        .ok_or_else(|| anyhow!("Missing inputs_values in API response"))?
        .iter()
        .map(|v| {
            v.as_u64()
                .ok_or_else(|| anyhow!("inputs_values contains a non-integer value"))
        })
        .collect::<Result<Vec<_>>>()?;

    let lock_scripts = api_result
        .get("lock_scripts")
        .and_then(|v| v.as_array())
        .ok_or_else(|| anyhow!("Missing lock_scripts in API response"))?
        .iter()
        .map(|v| {
            v.as_str()
                .ok_or_else(|| anyhow!("lock_scripts contains a non-string value"))
        })
        .collect::<Result<Vec<_>>>()?;

    // Check that inputs_values and lock_scripts have the same length
    if inputs_values.len() != lock_scripts.len() {
        return Err(anyhow!(
            "inputs_values and lock_scripts have different lengths"
        ));
    }

    // Extract transaction name - optional field
    let name = api_result.get("name").and_then(|v| v.as_str());

    // Extract transaction parameters - optional field, with asset_info removed
    let params = if let Some(params_value) = api_result.get("params") {
        if let Some(params_obj) = params_value.as_object() {
            // Create a filtered copy of the params
            let mut filtered_params = params_obj.clone();

            // Remove asset_info field if it exists
            filtered_params.remove("asset_info");

            // Convert back to Value and store
            Some(serde_json::Value::Object(filtered_params))
        } else {
            // If not an object, keep as is
            Some(params_value.clone())
        }
    } else {
        None
    };

    // Construct utxos vector
    let utxos = lock_scripts
        .iter()
        .zip(inputs_values.iter())
        .map(|(script, value)| (*script, *value))
        .collect::<Vec<_>>();

    Ok((raw_tx_hex, utxos, name, params))
}

/// Extract reveal transaction information if present.
///
/// For commit/reveal (taproot-envelope) composes the server returns an already
/// signed reveal transaction, which is broadcast verbatim. Its fund exposure is
/// bounded: the reveal can only spend the commit's first output — a dust amount
/// the user already reviewed and signed for in the commit transaction — so it
/// cannot move any other UTXO. The commit itself still goes through the normal
/// verification, summary and confirmation gate above.
fn extract_reveal_transaction_info(
    api_result: &serde_json::Value,
) -> Option<RevealTransactionInfo<'_>> {
    let signed_reveal_tx = api_result.get("signed_reveal_rawtransaction")?.as_str()?;

    Some(RevealTransactionInfo {
        signed_tx: signed_reveal_tx,
    })
}

/// Decode a hex-encoded script
fn decode_script(script_hex: &str) -> Result<bitcoin::ScriptBuf> {
    let script_bytes = hex::decode(script_hex).map_err(|e| anyhow!("Invalid script hex: {}", e))?;

    Ok(bitcoin::ScriptBuf::from_bytes(script_bytes))
}

/// Build UTXOList for main transaction from raw utxos data
fn build_utxo_list(utxos: Vec<(&str, u64)>) -> Result<bitcoinsigner::UTXOList> {
    // Create a new UTXOList
    let mut utxo_list = bitcoinsigner::UTXOList::new();

    // Process each UTXO
    for (script_hex, amount) in utxos.iter() {
        // Decode the script from hex
        let script_pubkey = decode_script(script_hex)?;

        // Create a basic UTXO
        let utxo = bitcoinsigner::UTXO::new(*amount, script_pubkey);

        // Add the UTXO to the list
        utxo_list.add(utxo);
    }

    Ok(utxo_list)
}

/// Broadcast transactions (both main and reveal if present)
async fn broadcast_transactions(
    config: &AppConfig,
    signed_tx: &str,
    signed_reveal_tx: Option<&str>,
) -> Result<()> {
    // Broadcast the main transaction
    let tx_id = broadcast_transaction(config, signed_tx).await?;

    // Create and display explorer URL for the main transaction
    let explorer_url = get_explorer_url(config.network, &tx_id);
    if signed_reveal_tx.is_some() {
        helpers::print_success("Commit transaction broadcasted:", Some(&explorer_url));
    } else {
        helpers::print_success("Transaction broadcasted:", Some(&explorer_url));
    }

    // If we have a reveal transaction, broadcast it too
    if let Some(reveal_tx) = signed_reveal_tx {
        let reveal_tx_id = broadcast_transaction(config, reveal_tx).await?;

        // Create and display explorer URL for the reveal transaction
        let reveal_explorer_url = get_explorer_url(config.network, &reveal_tx_id);
        helpers::print_success(
            "Reveal transaction broadcasted:",
            Some(&reveal_explorer_url),
        );
    }

    Ok(())
}

/// Build UTXOList for reveal transaction from the commit transaction
/// The reveal transaction spends the first output of the commit transaction
fn build_reveal_utxo_list(commit_tx_hex: &str) -> Result<bitcoinsigner::UTXOList> {
    // Decode the commit transaction from hex
    let tx_bytes = hex::decode(commit_tx_hex)
        .map_err(|e| anyhow!("Failed to decode commit transaction hex: {}", e))?;

    // Parse the transaction
    let commit_tx: bitcoin::Transaction = bitcoin::consensus::deserialize(&tx_bytes)
        .map_err(|e| anyhow!("Failed to parse commit transaction: {}", e))?;

    // Ensure the transaction has at least one output
    if commit_tx.output.is_empty() {
        return Err(anyhow!("Commit transaction has no outputs"));
    }

    // Get the first output - this is what the reveal transaction will spend
    let first_output = &commit_tx.output[0];

    // Extract the amount in satoshis
    let amount = first_output.value.to_sat();

    // Extract the script_pubkey
    let script_pubkey = first_output.script_pubkey.clone();

    // Create a new UTXOList
    let mut utxo_list = bitcoinsigner::UTXOList::new();

    // Create a UTXO for the first output
    let utxo = bitcoinsigner::UTXO::new(amount, script_pubkey);

    // Add the UTXO to the list
    utxo_list.add(utxo);

    Ok(utxo_list)
}

/// Verify a server-supplied, pre-signed reveal transaction spends **only** the
/// commit transaction's first output (`commit_txid:0`) — the envelope the user
/// just reviewed and signed for — **and** that that output's value is within the
/// [`MAX_REVEAL_ENVELOPE_SAT`] limit. The reveal is broadcast verbatim and its
/// outputs are never checked, so both the outpoint *and* the value it spends
/// bound its exposure: a hostile server can neither return a "reveal" that spends
/// some other wallet UTXO nor have the user fund an oversized envelope for it to
/// siphon. `signed_commit_hex` is the
/// locally-signed commit; its txid is final for segwit/taproot funding inputs
/// (whose witness is excluded from the txid), and a legacy-funded commit whose
/// txid changed on signing correctly fails this check (its pre-signed reveal
/// would be invalid on-chain anyway).
fn ensure_reveal_spends_commit_first_output(
    signed_commit_hex: &str,
    reveal_hex: &str,
) -> Result<()> {
    let commit_bytes = hex::decode(signed_commit_hex)
        .map_err(|e| anyhow!("Failed to decode commit transaction hex: {}", e))?;
    let commit: bitcoin::Transaction = bitcoin::consensus::deserialize(&commit_bytes)
        .map_err(|e| anyhow!("Failed to parse commit transaction: {}", e))?;
    let commit_txid = commit.compute_txid();

    let reveal_bytes = hex::decode(reveal_hex)
        .map_err(|e| anyhow!("Failed to decode reveal transaction hex: {}", e))?;
    let reveal: bitcoin::Transaction = bitcoin::consensus::deserialize(&reveal_bytes)
        .map_err(|e| anyhow!("Failed to parse reveal transaction: {}", e))?;

    let expected = bitcoin::OutPoint::new(commit_txid, 0);
    let ok = reveal.input.len() == 1 && reveal.input[0].previous_output == expected;
    if !ok {
        return Err(anyhow!(
            "SECURITY: the server-supplied reveal transaction does not spend only the commit's \
             first output ({expected}). Refusing to broadcast it. The API server may be \
             malfunctioning or malicious."
        ));
    }

    // Bound the envelope value: the reveal spends `commit:0` verbatim and its
    // outputs are never verified, so `commit:0`'s value caps how much a hostile
    // reveal could pay away. A legitimate data reveal needs only its own fee.
    let envelope_value = commit.output.first().map(|o| o.value.to_sat()).unwrap_or(0);
    if envelope_value > MAX_REVEAL_ENVELOPE_SAT {
        return Err(anyhow!(
            "SECURITY: the commit's first output is {envelope_value} sats, above the \
             {MAX_REVEAL_ENVELOPE_SAT}-sat reveal-envelope limit. The server-signed reveal spends \
             this output verbatim, so refusing to broadcast it. The API server may be \
             malfunctioning or malicious."
        ));
    }
    Ok(())
}

/// Handle transaction command by calling the corresponding compose API function
pub async fn handle_transaction_command(
    config: &AppConfig,
    endpoints: &HashMap<String, ApiEndpoint>,
    transaction_name: &str,
    sub_matches: &ArgMatches,
    wallet: &BitcoinWallet,
) -> Result<()> {
    // Find the corresponding compose endpoint
    let (path, endpoint, address_injected) = find_compose_endpoint(endpoints, transaction_name)?;

    // Extract parameters from command line arguments
    let mut params = extract_parameters_from_matches(&endpoint, transaction_name, sub_matches);

    // Resolve any wallet *label* passed for an address-bearing field into the
    // underlying address, before both the trust-anchor snapshot and the compose
    // call, so e.g. `--destination savings` is verified and composed against the
    // real address. A value that is already an address — or an external
    // destination not in the wallet — passes through unchanged.
    for key in ["address", "source", "destination"] {
        if let Some(value) = params.get(key).cloned() {
            let resolved = wallet.resolve_label_or_address(&value);
            if resolved != value {
                params.insert(key.to_string(), resolved);
            }
        }
    }

    // Snapshot the user's own inputs (human-readable, before satoshi
    // normalization and before internal fields like `multisig_pubkey` are added)
    // so the confirmation can show what *they* requested — a trust anchor
    // independent of the server's (untrusted) echo of the composed transaction.
    let requested_params: std::collections::BTreeMap<String, String> =
        params.clone().into_iter().collect();

    // Convert human-readable quantities to raw satoshis based on each asset's
    // divisibility (the compose API expects satoshi integers).
    super::quantity::normalize_quantities(config, transaction_name, &mut params).await?;

    // Get address and public key
    let public_key = get_address_and_public_key(&params, wallet)?;
    params.insert("multisig_pubkey".to_string(), public_key.to_string());

    // A synthetic `--address` (injected for a UTXO-sourced compose like
    // detach/movetoutxo) is only a local hint for choosing the signing key; the
    // endpoint declares no `address` argument, so drop it now that the signing
    // key is resolved rather than forwarding it as a stray query parameter.
    if address_injected {
        params.remove("address");
    }

    // Call API and get the composed transaction
    let api_result = call_compose_api(config, path, &endpoint, &mut params).await?;

    // Extract transaction details from the result
    let (raw_tx_hex, utxos, tx_name, tx_params) = extract_transaction_details(&api_result)?;

    // H1: independently verify that the transaction the server composed actually
    // encodes what the user requested (asset / quantity / destination), before
    // signing or broadcasting anything. Aborts on a proven mismatch; warns
    // loudly when the type/encoding cannot be independently verified.
    let verify_outcome = verify_composed_transaction_or_abort(
        config,
        transaction_name,
        &requested_params,
        &params,
        raw_tx_hex,
    )?;

    // Show the client's own request first as a trust anchor: the "Transaction:"
    // block below echoes the *server's* view of the composed transaction, which
    // a hostile or buggy server could misreport.
    if !requested_params.is_empty() {
        helpers::print_success("Requested (your inputs):", None);
        if let Ok(requested_json) = serde_json::to_value(&requested_params) {
            let _ = helpers::print_colored_json(&requested_json);
        }
        println!();
    }

    // Display transaction name and parameters before signing
    if tx_name.is_some() || tx_params.is_some() {
        // Create JSON structure with available information
        let mut display_data = serde_json::Map::new();

        if let Some(name) = tx_name {
            display_data.insert(
                "name".to_string(),
                serde_json::Value::String(name.to_string()),
            );
        }

        if let Some(params_value) = tx_params {
            display_data.insert("params".to_string(), params_value.clone());
        }

        if !display_data.is_empty() {
            helpers::print_success("Transaction:", None);
            let _ = helpers::print_colored_json(&serde_json::Value::Object(display_data));
            println!();
        }
    }

    // Build the UTXOList for the main transaction
    let utxo_list = build_utxo_list(utxos)?;

    // H2: reject an absurd miner fee before signing (defense against a server
    // that inflates the fee or burns the user's BTC to fees). `fee_conclusive`
    // is false when the cap could not be guaranteed (uncomputable fee or a legacy
    // input) — the transaction may still be broadcast after review, but `--yes`
    // must not auto-confirm it.
    let fee_conclusive = ensure_fee_within_limit(raw_tx_hex, &utxo_list)?;

    // Sign the transaction using sign_transaction2
    let signed_tx = wallet
        .sign_transaction(raw_tx_hex, &utxo_list)
        .map_err(|e| anyhow!("Failed to sign transaction: {}", e))?;

    // Variable to store signed reveal transaction if needed
    let mut signed_reveal_tx = None;

    // Handle reveal transaction if present. Only the decoded, human-readable
    // summary is shown here — the raw signed hex itself is withheld until after
    // the user confirms below (see the note there).
    if let Some(reveal_tx_info) = extract_reveal_transaction_info(&api_result) {
        let reveal_hex = reveal_tx_info.signed_tx;

        // The reveal is composed AND signed by the server and broadcast verbatim.
        // Its exposure is only bounded if it spends nothing but the commit's first
        // output (the dust envelope the user just reviewed and signed for), so
        // assert exactly that before trusting it — otherwise a hostile server
        // could hand back a "reveal" that spends some other wallet UTXO.
        ensure_reveal_spends_commit_first_output(&signed_tx, reveal_hex)?;

        helpers::print_success("Commit transaction summary:", None);
        display_transaction_summary(&signed_tx, &utxo_list, config.network)?;

        signed_reveal_tx = Some(reveal_hex.to_string());

        helpers::print_success("Reveal transaction summary:", None);
        let reveal_utxo_list = build_reveal_utxo_list(&signed_tx)?;
        display_transaction_summary(reveal_hex, &reveal_utxo_list, config.network)?;
    } else {
        helpers::print_success("Transaction summary:", None);
        display_transaction_summary(&signed_tx, &utxo_list, config.network)?;
    }

    // Ask for confirmation before broadcasting. `--yes` auto-confirms for
    // automation / CI, but ONLY for a transaction the client could fully verify
    // (see `VerifyOutcome::may_auto_confirm`). A type it cannot decode, an asset
    // it could not check offline, or a quantity whose 1e8 decimal scale rests on
    // the server's divisibility answer is vouched for (in part) by the server and
    // must never be broadcast without a human looking at the outputs — `--yes` is
    // deliberately overridden here so a hostile server cannot slip an asset swap,
    // a 1e8 over-send, or a siphon output past unattended automation.
    let yes = sub_matches.get_flag("yes");
    let skip_confirm = yes && verify_outcome.may_auto_confirm() && fee_conclusive;
    if !skip_confirm {
        if yes {
            helpers::print_warning(
                "\u{26A0} --yes does not auto-confirm a transaction this client could not fully verify.",
                Some(
                    "Review the inputs and outputs above and confirm manually (or use the expert \
                     `api compose_*` path). In a non-interactive session this aborts safely.",
                ),
            );
        }
        if !confirm_broadcast()? {
            helpers::print_error("Transaction aborted", None);
            return Ok(());
        }
    }

    // Only now — after the broadcast has been confirmed — reveal the signed
    // hex(es). A signed transaction is a valid, immediately-broadcastable
    // bearer instrument; printing it before confirmation would mean declining
    // the prompt does not prevent it from having already been exposed via
    // terminal scrollback, session logging, or CI log capture.
    helpers::print_success("Transaction signed:", None);
    println!("{}\n", signed_tx);
    if let Some(reveal_hex) = signed_reveal_tx.as_deref() {
        helpers::print_success("Reveal transaction signed:", None);
        println!("{}\n", reveal_hex);
    }

    // Broadcast the transaction(s)
    broadcast_transactions(config, &signed_tx, signed_reveal_tx.as_deref()).await
}

/// How confidently the client independently verified the composed transaction.
/// Drives both the on-screen banner and whether `--yes` may skip the human
/// confirmation before broadcasting.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum VerifyOutcome {
    /// Every independently-checkable field matched (asset, quantity, destination,
    /// BTC routing) against a client-side trust anchor. `--yes` may auto-confirm.
    Verified,
    /// Matched, and the only field taken on trust is the *decimal scale* of the
    /// quantity (the server's reported divisibility for the asset). The asset,
    /// destination and BTC routing were all independently checked, but the
    /// quantity's **magnitude** still rests on the server: a lying `divisible`
    /// flag scales the amount by 1e8 and would still "match" (both sides use the
    /// same server-reported divisibility). Because that decimal scale *is* value,
    /// `--yes` MUST NOT skip the human review for this outcome — the user has to
    /// confirm the amount is what they intended.
    PartiallyVerified,
    /// Destination, quantity and BTC routing matched, but the *asset* could not be
    /// resolved offline (a sub-asset longname or non-standard name), so it was not
    /// independently checked. A hostile server could have composed a *different*
    /// asset the source holds to the correct destination and quantity, so `--yes`
    /// MUST NOT skip the human review for this outcome.
    AssetUnverified,
    /// The transaction type or encoding is outside the client's independent
    /// decoder; only the server vouches for its contents. `--yes` MUST NOT skip
    /// the human review for this outcome.
    Unverified,
}

impl VerifyOutcome {
    /// Whether `--yes` may skip the human confirmation before broadcasting. ONLY
    /// a fully [`Verified`](Self::Verified) transaction qualifies. Every other
    /// outcome leaves at least one value-bearing aspect on the server's word — an
    /// unchecked asset ([`AssetUnverified`](Self::AssetUnverified)); the quantity's
    /// server-reported decimal scale, a 1e8 magnitude the client cannot check
    /// offline ([`PartiallyVerified`](Self::PartiallyVerified)); or an undecodable
    /// type ([`Unverified`](Self::Unverified)) — so a human must look at the
    /// outputs, and a hostile server cannot slip an asset swap, a 1e8 over-send, or
    /// a siphon output past unattended automation.
    fn may_auto_confirm(self) -> bool {
        matches!(self, Self::Verified)
    }
}

/// Independently verify a server-composed transaction against the user's request
/// (closes review finding H1). The composed Counterparty payload — asset,
/// quantity and destination — is decoded straight from the transaction (see
/// [`crate::counterparty`]) and compared with what the user typed.
///
/// * **Match** — print a short confirmation and continue.
/// * **Mismatch** — return an error so nothing is signed or broadcast. This is
///   the protection against a malicious/compromised/MITM'd server.
/// * **Unverifiable** — the transaction type or encoding is outside the client's
///   independent decoder; warn prominently and continue, so the normal broadcast
///   confirmation still gates it (and `--yes` remains an explicit opt-in to trust
///   the server for that transaction).
fn verify_composed_transaction_or_abort(
    config: &AppConfig,
    tx_type: &str,
    requested_params: &std::collections::BTreeMap<String, String>,
    normalized_params: &HashMap<String, String>,
    raw_tx_hex: &str,
) -> Result<VerifyOutcome> {
    use crate::counterparty::{self, Verification};

    let network = match config.network {
        crate::config::Network::Mainnet => bitcoin::Network::Bitcoin,
        crate::config::Network::Signet => bitcoin::Network::Signet,
        crate::config::Network::Testnet4 => bitcoin::Network::Testnet,
        crate::config::Network::Regtest => bitcoin::Network::Regtest,
    };

    let asset_requested = requested_params.get("asset");
    // Resolved offline from the asset name, so a lying server cannot spoof it.
    let asset_id = asset_requested.and_then(|a| counterparty::asset_id_for_name(a));
    // The user asked for an asset the client cannot resolve offline (a sub-asset
    // longname or a non-standard name) — the asset field then goes unchecked, so
    // we must not claim a full match below.
    let asset_unchecked = asset_requested.is_some() && asset_id.is_none();

    let intent = counterparty::Intent {
        asset_id,
        // The quantity already converted to base units in the compose path.
        quantity: normalized_params
            .get("quantity")
            .and_then(|q| q.parse::<u64>().ok()),
        // The destination the user requested (labels already resolved to addresses).
        destination: requested_params.get("destination").cloned(),
        // The source address that funds/signs, so we can confirm the change
        // returns to it rather than being siphoned (labels already resolved).
        source: requested_params
            .get("source")
            .or_else(|| requested_params.get("address"))
            .cloned(),
        // The requested `sweep` flags, so a server cannot silently flip
        // FLAG_OWNERSHIP on. Not a quantity, so it is read from the raw inputs.
        flags: requested_params.get("flags").and_then(|f| f.parse().ok()),
    };

    // For a non-BTC/XCP asset, the ×1e8 scale applied to `--quantity` came from
    // the server's reported divisibility (`quantity::resolve_divisibility`), and
    // the verifier compares two identically-scaled numbers — so a lying
    // divisibility flag would still "match". When a quantity was checked for such
    // an asset, its *magnitude* was taken on trust and the banner must say so.
    let quantity_scale_trusted = intent.quantity.is_some()
        && matches!(asset_requested.map(String::as_str), Some(a) if a != "BTC" && a != "XCP");

    match counterparty::verify_composed_transaction(raw_tx_hex, tx_type, &intent, network) {
        Verification::Match if asset_unchecked => {
            // Destination, quantity and BTC routing matched, but the asset name
            // could not be resolved offline, so it was not independently checked.
            helpers::print_warning(
                "\u{26A0} Partially verified: destination, quantity and BTC change match your request.",
                Some(&format!(
                    "The asset '{}' could not be resolved offline (sub-asset or non-standard name), \
                     so it was NOT independently checked. Confirm the asset yourself before continuing.",
                    asset_requested.map(String::as_str).unwrap_or("?"),
                )),
            );
            Ok(VerifyOutcome::AssetUnverified)
        }
        Verification::Match if quantity_scale_trusted => {
            // Asset, destination and BTC routing matched, but the decimal scale of
            // the quantity rests on the server's divisibility answer for this
            // asset — surface that rather than claim an unqualified match.
            helpers::print_warning(
                "\u{26A0} Partially verified: asset, destination and BTC change match your request.",
                Some(&format!(
                    "The decimal scale of the quantity was taken from the server's reported \
                     divisibility for '{}', which this client cannot verify offline. Confirm the \
                     amount below is what you intended before continuing.",
                    asset_requested.map(String::as_str).unwrap_or("?"),
                )),
            );
            Ok(VerifyOutcome::PartiallyVerified)
        }
        Verification::Match => {
            helpers::print_success(
                "\u{2713} Verified: the composed transaction matches your request.",
                None,
            );
            Ok(VerifyOutcome::Verified)
        }
        Verification::Mismatch {
            field,
            requested,
            composed,
        } => Err(anyhow!(
            "SECURITY: the server-composed transaction does not match your request.\n  \
             field:     {field}\n  \
             you asked: {requested}\n  \
             composed:  {composed}\n\
             Refusing to sign or broadcast. The API server may be malfunctioning or malicious — \
             do not retry against the same server without investigating."
        )),
        // A command whose type the client *can* independently verify, yet whose
        // composed form it could not decode, is refused (fail closed) — a
        // verifiable `send`/`sweep` that comes back undecodable is exactly the
        // shape a hostile server would use to escape the payload check. `--yes`
        // does not override this.
        Verification::Unverifiable { reason } if counterparty::is_verifiable_type(tx_type) => {
            Err(anyhow!(
                "SECURITY: could not independently verify this '{tx_type}' transaction ({reason}). \
                 Refusing to sign or broadcast a verifiable transaction type the client cannot decode. \
                 The API server may be malfunctioning or malicious."
            ))
        }
        Verification::Unverifiable { reason } => {
            helpers::print_warning(
                "\u{26A0} Could not independently verify this transaction.",
                Some(&format!(
                    "{reason}. You are trusting the API server for its contents; \
                     review the details below before confirming."
                )),
            );
            Ok(VerifyOutcome::Unverified)
        }
    }
}

/// Handle sign command by parsing UTXOs and signing the transaction
pub async fn handle_sign_command(
    config: &AppConfig,
    sub_matches: &ArgMatches,
    wallet: &BitcoinWallet,
) -> Result<()> {
    // `wallet sign` is the expert escape hatch: unlike `wallet transaction
    // <type>`, it performs NO independent verification of what it signs — it
    // signs exactly the raw transaction handed to it. Say so, so a user pasting a
    // `compose_*` result here knows the fund-safety net is off.
    helpers::print_warning(
        "wallet sign does not independently verify this transaction; it signs exactly the \
         raw transaction you provide.",
        Some("Use `wallet transaction <type>` to compose, verify and sign in one step."),
    );

    // Get raw transaction hex from arguments
    let raw_tx_hex = sub_matches
        .get_one::<String>("rawtransaction")
        .ok_or_else(|| anyhow!("Missing raw transaction"))?;

    // Get UTXOs - either from command line parameter or API
    let utxo_list = if let Some(utxos_json) = sub_matches.get_one::<String>("utxos") {
        // Parse UTXOs from JSON
        parse_utxos_from_json(utxos_json)?
    } else {
        // Fetch UTXOs from API
        get_utxos_from_api(config, raw_tx_hex).await?
    };

    // Sign the transaction
    let signed_tx = wallet
        .sign_transaction(raw_tx_hex, &utxo_list)
        .map_err(|e| anyhow!("Failed to sign transaction: {}", e))?;

    // Display the signed transaction
    helpers::print_success("Transaction signed successfully:", None);
    println!("{}", signed_tx);

    // Display transaction summary
    display_transaction_summary(&signed_tx, &utxo_list, config.network)?;

    Ok(())
}

/// Parse UTXOs from a JSON string into a UTXOList
fn parse_utxos_from_json(utxos_json: &str) -> Result<bitcoinsigner::UTXOList> {
    // Parse the JSON string
    let utxos_value: serde_json::Value =
        serde_json::from_str(utxos_json).map_err(|e| anyhow!("Invalid UTXOs JSON: {}", e))?;

    // Ensure it's an array
    let utxos_array = utxos_value
        .as_array()
        .ok_or_else(|| anyhow!("UTXOs must be a JSON array"))?;

    // Create a new UTXOList
    let mut utxo_list = bitcoinsigner::UTXOList::new();

    // Process each UTXO
    for (idx, utxo_value) in utxos_array.iter().enumerate() {
        let utxo_obj = utxo_value
            .as_object()
            .ok_or_else(|| anyhow!("UTXO {} is not a valid JSON object", idx))?;

        // Extract required fields
        let script_pubkey_hex = utxo_obj
            .get("scriptPubKey")
            .and_then(|v| v.as_str())
            .ok_or_else(|| anyhow!("UTXO {} missing scriptPubKey field", idx))?;

        let amount = utxo_obj
            .get("amount")
            .and_then(|v| v.as_u64())
            .ok_or_else(|| anyhow!("UTXO {} missing amount field or invalid amount", idx))?;

        // Decode script_pubkey
        let script_pubkey_bytes = hex::decode(script_pubkey_hex)
            .map_err(|e| anyhow!("Invalid scriptPubKey hex for UTXO {}: {}", idx, e))?;

        let script_pubkey = bitcoin::ScriptBuf::from_bytes(script_pubkey_bytes);

        // Create UTXO
        let mut utxo = bitcoinsigner::UTXO::new(amount, script_pubkey);

        // Add optional redeem script if present
        if let Some(redeem_script_val) = utxo_obj.get("redeemScript") {
            if let Some(redeem_script_hex) = redeem_script_val.as_str() {
                let redeem_script_bytes = hex::decode(redeem_script_hex)
                    .map_err(|e| anyhow!("Invalid redeemScript hex for UTXO {}: {}", idx, e))?;

                utxo.redeem_script = Some(bitcoin::ScriptBuf::from_bytes(redeem_script_bytes));
            }
        }

        // Add optional witness script if present
        if let Some(witness_script_val) = utxo_obj.get("witnessScript") {
            if let Some(witness_script_hex) = witness_script_val.as_str() {
                let witness_script_bytes = hex::decode(witness_script_hex)
                    .map_err(|e| anyhow!("Invalid witnessScript hex for UTXO {}: {}", idx, e))?;

                utxo.witness_script = Some(bitcoin::ScriptBuf::from_bytes(witness_script_bytes));
            }
        }

        // Add optional leaf script if present (for P2TR script path spending)
        if let Some(leaf_script_val) = utxo_obj.get("leafScript") {
            if let Some(leaf_script_hex) = leaf_script_val.as_str() {
                let leaf_script_bytes = hex::decode(leaf_script_hex)
                    .map_err(|e| anyhow!("Invalid leafScript hex for UTXO {}: {}", idx, e))?;

                utxo.leaf_script = Some(bitcoin::ScriptBuf::from_bytes(leaf_script_bytes));
            }
        }

        // Add optional source address if present
        if let Some(source_address_val) = utxo_obj.get("sourceAddress") {
            if let Some(source_address) = source_address_val.as_str() {
                utxo.source_address = Some(source_address.to_string());
            }
        }

        // Add UTXO to the list
        utxo_list.add(utxo);
    }

    Ok(utxo_list)
}

/// Fetch UTXOs information from the API for a given transaction
async fn get_utxos_from_api(
    config: &AppConfig,
    raw_tx_hex: &str,
) -> Result<bitcoinsigner::UTXOList> {
    // Decode the transaction from hex
    let tx_bytes =
        hex::decode(raw_tx_hex).map_err(|e| anyhow!("Failed to decode transaction hex: {}", e))?;

    // Parse the transaction
    let tx: bitcoin::Transaction = bitcoin::consensus::deserialize(&tx_bytes)
        .map_err(|e| anyhow!("Failed to parse transaction: {}", e))?;

    // Get the inputs from the transaction
    let inputs = &tx.input;

    // Create a new UTXO list
    let mut utxo_list = bitcoinsigner::UTXOList::new();

    // For each input, fetch the transaction info from the API
    for input in inputs {
        let txid = input.previous_output.txid.to_string();
        let vout = input.previous_output.vout;

        // Fetch transaction info from API
        let api_path = format!("/v2/bitcoin/transactions/{}", txid);
        let result = api::perform_api_request(config, &api_path, &HashMap::new()).await?;

        // Extract the UTXO information
        if let Some(tx_result) = result.get("result") {
            if let Some(vouts) = tx_result.get("vout").and_then(|v| v.as_array()) {
                // Find the specific vout we need
                let output = vouts
                    .iter()
                    .find(|output| output.get("n").and_then(|n| n.as_u64()) == Some(vout as u64))
                    .ok_or_else(|| anyhow!("Vout {} not found in transaction {}", vout, txid))?;

                // Extract the BTC amount as an exact decimal (never via f64,
                // which the signer's sighash then commits to). A JSON number's
                // string form parses losslessly; a string value is also accepted.
                let amount_value = output.get("value").ok_or_else(|| {
                    anyhow!("Missing or invalid amount for input {}:{}", txid, vout)
                })?;
                let amount_btc = match amount_value {
                    serde_json::Value::String(s) => Decimal::from_str(s.trim()),
                    serde_json::Value::Number(n) => Decimal::from_str(&n.to_string()),
                    _ => return Err(anyhow!("Invalid amount type for input {}:{}", txid, vout)),
                }
                .map_err(|_| anyhow!("Invalid amount for input {}:{}", txid, vout))?;

                // Convert to satoshis (multiply by 10^8)
                let amount = amount_btc
                    .checked_mul(Decimal::from(100_000_000))
                    .and_then(|d| d.to_u64())
                    .ok_or_else(|| anyhow!("Amount out of range for input {}:{}", txid, vout))?;

                // Extract scriptPubKey
                let script_pubkey_obj = output
                    .get("scriptPubKey")
                    .and_then(|s| s.as_object())
                    .ok_or_else(|| anyhow!("Missing scriptPubKey for input {}:{}", txid, vout))?;

                let script_pubkey_hex = script_pubkey_obj
                    .get("hex")
                    .and_then(|h| h.as_str())
                    .ok_or_else(|| {
                        anyhow!("Missing scriptPubKey hex for input {}:{}", txid, vout)
                    })?;

                // Decode script_pubkey
                let script_pubkey_bytes = hex::decode(script_pubkey_hex).map_err(|e| {
                    anyhow!(
                        "Invalid scriptPubKey hex for input {}:{}: {}",
                        txid,
                        vout,
                        e
                    )
                })?;

                let script_pubkey = bitcoin::ScriptBuf::from_bytes(script_pubkey_bytes);

                // The API prevout carries only the scriptPubKey, which is not
                // enough to sign P2SH/P2WSH inputs (they also need the
                // redeem/witness script). Fail with an actionable message rather
                // than a later generic "could not sign inputs" error.
                if script_pubkey.is_p2sh() || script_pubkey.is_p2wsh() {
                    return Err(anyhow!(
                        "Input {}:{} is a P2SH/P2WSH output; signing it needs its redeem/witness \
                         script, which the API prevout does not provide. Re-run with \
                         `--utxos <json>` supplying them.",
                        txid,
                        vout
                    ));
                }

                // Create UTXO
                let utxo = bitcoinsigner::UTXO::new(amount, script_pubkey);

                // Add to the list
                utxo_list.add(utxo);
            } else {
                return Err(anyhow!("Missing vout data for transaction {}", txid));
            }
        } else if let Some(error) = result.get("error") {
            return Err(anyhow!(
                "API error fetching transaction {}: {}",
                txid,
                error
            ));
        } else {
            return Err(anyhow!(
                "Unexpected API response format for transaction {}",
                txid
            ));
        }
    }

    Ok(utxo_list)
}

/// Handle broadcast command to send a signed transaction to the network
pub async fn handle_broadcast_command(config: &AppConfig, sub_matches: &ArgMatches) -> Result<()> {
    // Like `wallet sign`, this expert command performs NO independent
    // verification: it broadcasts exactly the signed transaction handed to it.
    helpers::print_warning(
        "wallet broadcast does not independently verify this transaction; it broadcasts exactly \
         the signed transaction you provide.",
        Some("Use `wallet transaction <type>` to compose, verify, sign and broadcast in one step."),
    );

    // Get raw transaction hex from arguments
    let signed_tx_hex = sub_matches
        .get_one::<String>("rawtransaction")
        .ok_or_else(|| anyhow!("Missing raw transaction"))?;

    // The summary is best-effort: fetching prevouts needs the API/indexer to
    // resolve every input, which can fail for otherwise-broadcastable txs (e.g.
    // an unconfirmed parent). Never block a valid broadcast on it.
    match get_utxos_from_api(config, signed_tx_hex).await {
        Ok(utxo_list) => {
            if let Err(e) = display_transaction_summary(signed_tx_hex, &utxo_list, config.network) {
                helpers::print_warning(
                    "Could not render transaction summary:",
                    Some(&e.to_string()),
                );
            }
        }
        Err(e) => {
            helpers::print_warning(
                "Could not fetch inputs to preview the transaction (broadcasting anyway):",
                Some(&e.to_string()),
            );
        }
    }

    // Ask for confirmation before broadcasting, unless `--yes` was given (for
    // automation / CI / headless use).
    let skip_confirm = sub_matches.get_flag("yes");
    if !skip_confirm && !confirm_broadcast()? {
        helpers::print_error("Transaction broadcast aborted", None);
        return Ok(());
    }

    // Broadcast the transaction
    let tx_id = broadcast_transaction(config, signed_tx_hex).await?;

    // Create and display explorer URL for the transaction
    let explorer_url = get_explorer_url(config.network, &tx_id);
    helpers::print_success("Transaction broadcasted:", Some(&explorer_url));

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::{AppConfig, Network};
    use serde_json::json;

    // ---- test helpers ----

    /// A regtest bech32 (P2WPKH) address + its script_pubkey, derived from a
    /// fixed secret so the value is deterministic.
    fn p2wpkh_addr_and_script(seed: u8) -> (String, bitcoin::ScriptBuf) {
        let secp = bitcoin::secp256k1::Secp256k1::new();
        let sk = bitcoin::secp256k1::SecretKey::from_slice(&[seed; 32]).unwrap();
        let pk = bitcoin::PrivateKey::new(sk, bitcoin::Network::Regtest);
        let public = bitcoin::PublicKey::from_private_key(&secp, &pk);
        let cpk = bitcoin::CompressedPublicKey::from_slice(&public.to_bytes()).unwrap();
        let addr = bitcoin::Address::p2wpkh(&cpk, bitcoin::Network::Regtest);
        (addr.to_string(), addr.script_pubkey())
    }

    fn p2pkh_script(seed: u8) -> bitcoin::ScriptBuf {
        let secp = bitcoin::secp256k1::Secp256k1::new();
        let sk = bitcoin::secp256k1::SecretKey::from_slice(&[seed; 32]).unwrap();
        let pk = bitcoin::PrivateKey::new(sk, bitcoin::Network::Regtest);
        let public = bitcoin::PublicKey::from_private_key(&secp, &pk);
        bitcoin::Address::p2pkh(public, bitcoin::Network::Regtest).script_pubkey()
    }

    /// An OP_RETURN script carrying `data` (short push form).
    fn op_return_script(data: &[u8]) -> bitcoin::ScriptBuf {
        let mut raw = vec![0x6a, data.len() as u8];
        raw.extend_from_slice(data);
        bitcoin::ScriptBuf::from_bytes(raw)
    }

    /// Build a raw transaction hex with the given outputs and a single dummy input.
    fn raw_tx_hex(outputs: Vec<bitcoin::TxOut>) -> String {
        use bitcoin::hashes::Hash;
        let tx = bitcoin::Transaction {
            version: bitcoin::transaction::Version::TWO,
            lock_time: bitcoin::absolute::LockTime::ZERO,
            input: vec![bitcoin::TxIn {
                previous_output: bitcoin::OutPoint {
                    txid: bitcoin::Txid::all_zeros(),
                    vout: 0,
                },
                script_sig: bitcoin::ScriptBuf::new(),
                sequence: bitcoin::Sequence::MAX,
                witness: bitcoin::Witness::new(),
            }],
            output: outputs,
        };
        bitcoin::consensus::encode::serialize_hex(&tx)
    }

    fn config_for(server: &mockito::ServerGuard) -> AppConfig {
        let mut config = AppConfig::new();
        config.set_network(Network::Regtest);
        let nc = config.network_configs.get_mut(&Network::Regtest).unwrap();
        nc.api_url = server.url();
        nc.endpoints_url = format!("{}/v2/routes", server.url());
        config
    }

    // ---- get_explorer_url ----

    #[test]
    fn explorer_url_per_network() {
        assert_eq!(
            get_explorer_url(Network::Mainnet, "abc"),
            "https://mempool.space/tx/abc"
        );
        assert_eq!(
            get_explorer_url(Network::Signet, "abc"),
            "https://mempool.space/signet/tx/abc"
        );
        assert_eq!(
            get_explorer_url(Network::Testnet4, "abc"),
            "https://mempool.space/testnet4/tx/abc"
        );
        assert_eq!(
            get_explorer_url(Network::Regtest, "abc"),
            "Transaction ID: abc"
        );
    }

    // ---- get_script_type ----

    #[test]
    fn script_type_detection() {
        let (_, wpkh) = p2wpkh_addr_and_script(1);
        assert_eq!(get_script_type(&wpkh), "P2WPKH");
        assert_eq!(get_script_type(&p2pkh_script(2)), "P2PKH");
        assert_eq!(get_script_type(&op_return_script(b"CNTRPRTY")), "OP_RETURN");
        // An arbitrary non-standard script is UNKNOWN.
        assert_eq!(
            get_script_type(&bitcoin::ScriptBuf::from_bytes(vec![0x51])),
            "UNKNOWN"
        );
    }

    // ---- extract_op_return_data ----

    #[test]
    fn op_return_data_extraction() {
        // Data is hex-encoded (never rendered as text) to avoid smuggling
        // terminal escape sequences from server-controlled OP_RETURN bytes.
        assert_eq!(
            extract_op_return_data(&op_return_script(b"hello")),
            hex::encode(b"hello")
        );
        // Not an OP_RETURN.
        assert_eq!(
            extract_op_return_data(&p2pkh_script(3)),
            "<not an OP_RETURN>"
        );
        // Bare OP_RETURN with no push.
        assert_eq!(
            extract_op_return_data(&bitcoin::ScriptBuf::from_bytes(vec![0x6a])),
            "<no data>"
        );
        // OP_PUSHDATA1 form: 0x6a 0x4c <len> <data>.
        let mut raw = vec![0x6a, 0x4c, 0x03];
        raw.extend_from_slice(b"abc");
        assert_eq!(
            extract_op_return_data(&bitcoin::ScriptBuf::from_bytes(raw)),
            hex::encode(b"abc")
        );
    }

    // ---- script_to_address ----

    #[test]
    fn script_to_address_roundtrips_and_none_on_unknown() {
        let (addr, wpkh) = p2wpkh_addr_and_script(4);
        assert_eq!(script_to_address(&wpkh, Network::Regtest), Some(addr));
        // A bare/non-standard script has no address.
        assert_eq!(
            script_to_address(
                &bitcoin::ScriptBuf::from_bytes(vec![0x51]),
                Network::Regtest
            ),
            None
        );
    }

    // ---- calculate_transaction_fee ----

    #[test]
    fn fee_is_inputs_minus_outputs_or_none() {
        let (_, spk) = p2wpkh_addr_and_script(5);
        let tx_hex = raw_tx_hex(vec![bitcoin::TxOut {
            value: bitcoin::Amount::from_sat(900),
            script_pubkey: spk.clone(),
        }]);
        let tx_bytes = hex::decode(&tx_hex).unwrap();
        let tx: bitcoin::Transaction = bitcoin::consensus::deserialize(&tx_bytes).unwrap();

        let mut list = bitcoinsigner::UTXOList::new();
        list.add(bitcoinsigner::UTXO::new(1000, spk.clone()));
        assert_eq!(calculate_transaction_fee(&tx, &list), Some(100));

        // Outputs > inputs -> None.
        let mut small = bitcoinsigner::UTXOList::new();
        small.add(bitcoinsigner::UTXO::new(500, spk));
        assert_eq!(calculate_transaction_fee(&tx, &small), None);
    }

    // ---- ensure_fee_within_limit (the anti-fee-theft cap) ----

    #[test]
    fn ensure_fee_within_limit_refuses_above_cap_allows_at_and_below() {
        let (_, spk) = p2wpkh_addr_and_script(5);
        // Single output of 900 sats; fee = reported input value - 900.
        let tx_hex = raw_tx_hex(vec![bitcoin::TxOut {
            value: bitcoin::Amount::from_sat(900),
            script_pubkey: spk.clone(),
        }]);

        let utxos = |input_value: u64| {
            let mut list = bitcoinsigner::UTXOList::new();
            list.add(bitcoinsigner::UTXO::new(input_value, spk.clone()));
            list
        };

        // Fee one sat above the cap -> refuse.
        assert!(
            ensure_fee_within_limit(&tx_hex, &utxos(900 + MAX_REASONABLE_FEE_SAT + 1)).is_err()
        );
        // Fee exactly at the cap (segwit input) -> allowed AND conclusive.
        assert!(ensure_fee_within_limit(&tx_hex, &utxos(900 + MAX_REASONABLE_FEE_SAT)).unwrap());
        // A normal small fee -> allowed and conclusive.
        assert!(ensure_fee_within_limit(&tx_hex, &utxos(1000)).unwrap());
        // Reported inputs <= outputs: the fee is uncomputable. This must not fail
        // *open* silently — it warns, returns Ok, but reports the fee as NOT
        // conclusive so the caller refuses to `--yes`-auto-confirm it.
        assert!(!ensure_fee_within_limit(&tx_hex, &utxos(500)).unwrap());
    }

    #[test]
    fn ensure_fee_within_limit_flags_legacy_input_as_inconclusive() {
        // A P2PKH input's amount is not committed by its signature, so the cap
        // cannot be guaranteed: the transaction is still allowed (Ok, not Err —
        // the human can review), but the fee is reported as NOT conclusive so
        // `--yes` will not auto-confirm it.
        let spk = p2pkh_script(6);
        let tx_hex = raw_tx_hex(vec![bitcoin::TxOut {
            value: bitcoin::Amount::from_sat(900),
            script_pubkey: spk.clone(),
        }]);
        let mut list = bitcoinsigner::UTXOList::new();
        list.add(bitcoinsigner::UTXO::new(1200, spk));
        assert!(!ensure_fee_within_limit(&tx_hex, &list).unwrap());
    }

    // ---- ensure_reveal_spends_commit_first_output ----

    #[test]
    fn reveal_must_spend_only_the_commit_first_output() {
        use bitcoin::hashes::Hash as _;
        let (_, spk) = p2wpkh_addr_and_script(9);

        // A commit transaction; its txid is deterministic from its contents.
        let commit = bitcoin::Transaction {
            version: bitcoin::transaction::Version::TWO,
            lock_time: bitcoin::absolute::LockTime::ZERO,
            input: vec![bitcoin::TxIn {
                previous_output: bitcoin::OutPoint {
                    txid: bitcoin::Txid::all_zeros(),
                    vout: 3,
                },
                script_sig: bitcoin::ScriptBuf::new(),
                sequence: bitcoin::Sequence::MAX,
                witness: bitcoin::Witness::new(),
            }],
            output: vec![bitcoin::TxOut {
                value: bitcoin::Amount::from_sat(1000),
                script_pubkey: spk.clone(),
            }],
        };
        let commit_hex = hex::encode(bitcoin::consensus::serialize(&commit));
        let commit_txid = commit.compute_txid();

        let reveal_spending = |inputs: Vec<bitcoin::OutPoint>| {
            let tx = bitcoin::Transaction {
                version: bitcoin::transaction::Version::TWO,
                lock_time: bitcoin::absolute::LockTime::ZERO,
                input: inputs
                    .into_iter()
                    .map(|previous_output| bitcoin::TxIn {
                        previous_output,
                        script_sig: bitcoin::ScriptBuf::new(),
                        sequence: bitcoin::Sequence::MAX,
                        witness: bitcoin::Witness::new(),
                    })
                    .collect(),
                output: vec![bitcoin::TxOut {
                    value: bitcoin::Amount::from_sat(500),
                    script_pubkey: spk.clone(),
                }],
            };
            hex::encode(bitcoin::consensus::serialize(&tx))
        };

        // Spends exactly commit:0 -> accepted.
        let good = reveal_spending(vec![bitcoin::OutPoint::new(commit_txid, 0)]);
        assert!(ensure_reveal_spends_commit_first_output(&commit_hex, &good).is_ok());

        // Wrong vout (commit:1) -> refused.
        let wrong_vout = reveal_spending(vec![bitcoin::OutPoint::new(commit_txid, 1)]);
        assert!(ensure_reveal_spends_commit_first_output(&commit_hex, &wrong_vout).is_err());

        // A different txid entirely -> refused.
        let elsewhere =
            reveal_spending(vec![bitcoin::OutPoint::new(bitcoin::Txid::all_zeros(), 0)]);
        assert!(ensure_reveal_spends_commit_first_output(&commit_hex, &elsewhere).is_err());

        // Spends commit:0 PLUS another UTXO -> refused (would siphon the extra input).
        let extra = reveal_spending(vec![
            bitcoin::OutPoint::new(commit_txid, 0),
            bitcoin::OutPoint::new(bitcoin::Txid::all_zeros(), 7),
        ]);
        assert!(ensure_reveal_spends_commit_first_output(&commit_hex, &extra).is_err());
    }

    #[test]
    fn reveal_with_an_oversized_commit_envelope_is_refused() {
        use bitcoin::hashes::Hash as _;
        let (_, spk) = p2wpkh_addr_and_script(9);

        // A commit whose first output is funded far above the envelope limit. The
        // server-signed reveal spends it verbatim, so a large `commit:0` is how a
        // hostile server would siphon the user's funded value — refuse it even
        // though the reveal correctly spends only commit:0.
        let commit = bitcoin::Transaction {
            version: bitcoin::transaction::Version::TWO,
            lock_time: bitcoin::absolute::LockTime::ZERO,
            input: vec![bitcoin::TxIn {
                previous_output: bitcoin::OutPoint {
                    txid: bitcoin::Txid::all_zeros(),
                    vout: 3,
                },
                script_sig: bitcoin::ScriptBuf::new(),
                sequence: bitcoin::Sequence::MAX,
                witness: bitcoin::Witness::new(),
            }],
            output: vec![bitcoin::TxOut {
                value: bitcoin::Amount::from_sat(MAX_REVEAL_ENVELOPE_SAT + 1),
                script_pubkey: spk.clone(),
            }],
        };
        let commit_hex = hex::encode(bitcoin::consensus::serialize(&commit));
        let commit_txid = commit.compute_txid();

        let reveal = bitcoin::Transaction {
            version: bitcoin::transaction::Version::TWO,
            lock_time: bitcoin::absolute::LockTime::ZERO,
            input: vec![bitcoin::TxIn {
                previous_output: bitcoin::OutPoint::new(commit_txid, 0),
                script_sig: bitcoin::ScriptBuf::new(),
                sequence: bitcoin::Sequence::MAX,
                witness: bitcoin::Witness::new(),
            }],
            output: vec![bitcoin::TxOut {
                value: bitcoin::Amount::from_sat(500),
                script_pubkey: spk,
            }],
        };
        let reveal_hex = hex::encode(bitcoin::consensus::serialize(&reveal));
        assert!(ensure_reveal_spends_commit_first_output(&commit_hex, &reveal_hex).is_err());
    }

    // ---- decode_script / build_utxo_list ----

    #[test]
    fn decode_script_ok_and_err() {
        assert!(decode_script("51").is_ok());
        assert!(decode_script("zz").is_err());
    }

    #[test]
    fn build_utxo_list_ok_and_bad_hex() {
        let (_, spk) = p2wpkh_addr_and_script(6);
        let hexs = hex::encode(spk.as_bytes());
        let list = build_utxo_list(vec![(hexs.as_str(), 1234)]).unwrap();
        assert_eq!(list.len(), 1);
        assert_eq!(list.get(0).unwrap().amount, 1234);

        assert!(build_utxo_list(vec![("zz", 1)]).is_err());
    }

    // ---- build_reveal_utxo_list ----

    #[test]
    fn build_reveal_utxo_list_uses_first_output() {
        let (_, spk) = p2wpkh_addr_and_script(7);
        let commit_hex = raw_tx_hex(vec![
            bitcoin::TxOut {
                value: bitcoin::Amount::from_sat(4321),
                script_pubkey: spk.clone(),
            },
            bitcoin::TxOut {
                value: bitcoin::Amount::from_sat(1),
                script_pubkey: spk,
            },
        ]);
        let list = build_reveal_utxo_list(&commit_hex).unwrap();
        assert_eq!(list.len(), 1);
        assert_eq!(list.get(0).unwrap().amount, 4321);

        // Bad hex and no-output cases are errors.
        assert!(build_reveal_utxo_list("zz").is_err());
        let no_out = raw_tx_hex(vec![]);
        assert!(build_reveal_utxo_list(&no_out).is_err());
    }

    // ---- parse_utxos_from_json ----

    #[test]
    fn parse_utxos_from_json_full_and_errors() {
        let (_, spk) = p2wpkh_addr_and_script(8);
        let spk_hex = hex::encode(spk.as_bytes());
        let good = format!(
            r#"[{{"scriptPubKey":"{spk_hex}","amount":5000,"redeemScript":"51","witnessScript":"52","leafScript":"53","sourceAddress":"bcrt1qexample"}}]"#
        );
        let list = parse_utxos_from_json(&good).unwrap();
        assert_eq!(list.len(), 1);
        let u = list.get(0).unwrap();
        assert_eq!(u.amount, 5000);
        assert!(u.redeem_script.is_some());
        assert!(u.witness_script.is_some());
        assert!(u.leaf_script.is_some());
        assert_eq!(u.source_address.as_deref(), Some("bcrt1qexample"));

        // Not an array.
        assert!(parse_utxos_from_json("{}").is_err());
        // Not valid JSON.
        assert!(parse_utxos_from_json("not json").is_err());
        // Element not an object.
        assert!(parse_utxos_from_json("[1]").is_err());
        // Missing scriptPubKey.
        assert!(parse_utxos_from_json(r#"[{"amount":1}]"#).is_err());
        // Missing amount.
        assert!(parse_utxos_from_json(r#"[{"scriptPubKey":"51"}]"#).is_err());
        // Bad scriptPubKey hex.
        assert!(parse_utxos_from_json(r#"[{"scriptPubKey":"zz","amount":1}]"#).is_err());
    }

    // ---- extract_transaction_details ----

    #[test]
    fn extract_transaction_details_full() {
        let result = json!({
            "rawtransaction": "deadbeef",
            "inputs_values": [1000, 2000],
            "lock_scripts": ["51", "52"],
            "name": "send",
            "params": {"asset": "XCP", "asset_info": {"divisible": true}, "quantity": 5}
        });
        let (raw, utxos, name, params) = extract_transaction_details(&result).unwrap();
        assert_eq!(raw, "deadbeef");
        assert_eq!(utxos, vec![("51", 1000u64), ("52", 2000u64)]);
        assert_eq!(name, Some("send"));
        let params = params.unwrap();
        // asset_info is stripped, other params kept.
        assert!(params.get("asset_info").is_none());
        assert_eq!(params.get("asset").unwrap(), "XCP");
    }

    #[test]
    fn extract_transaction_details_errors() {
        // Missing rawtransaction.
        assert!(extract_transaction_details(&json!({
            "inputs_values": [1], "lock_scripts": ["51"]
        }))
        .is_err());
        // Missing inputs_values.
        assert!(extract_transaction_details(&json!({
            "rawtransaction": "aa", "lock_scripts": ["51"]
        }))
        .is_err());
        // Missing lock_scripts.
        assert!(extract_transaction_details(&json!({
            "rawtransaction": "aa", "inputs_values": [1]
        }))
        .is_err());
        // Mismatched lengths.
        assert!(extract_transaction_details(&json!({
            "rawtransaction": "aa", "inputs_values": [1, 2], "lock_scripts": ["51"]
        }))
        .is_err());
        // A non-integer inputs_values element is an error, not a silent drop
        // (which could leave the two arrays length-matched but misaligned).
        assert!(extract_transaction_details(&json!({
            "rawtransaction": "aa", "inputs_values": [1, "oops"], "lock_scripts": ["51", "52"]
        }))
        .is_err());
        // A non-string lock_scripts element is likewise an error.
        assert!(extract_transaction_details(&json!({
            "rawtransaction": "aa", "inputs_values": [1, 2], "lock_scripts": ["51", 52]
        }))
        .is_err());
    }

    #[test]
    fn extract_transaction_details_optional_fields_absent() {
        let result = json!({
            "rawtransaction": "aa",
            "inputs_values": [1],
            "lock_scripts": ["51"]
        });
        let (_, _, name, params) = extract_transaction_details(&result).unwrap();
        assert_eq!(name, None);
        assert!(params.is_none());
    }

    // ---- extract_reveal_transaction_info ----

    #[test]
    fn reveal_info_present_and_absent() {
        let with = json!({"signed_reveal_rawtransaction": "cafe"});
        assert_eq!(
            extract_reveal_transaction_info(&with).unwrap().signed_tx,
            "cafe"
        );
        let without = json!({"rawtransaction": "aa"});
        assert!(extract_reveal_transaction_info(&without).is_none());
    }

    // ---- find_compose_endpoint ----

    fn endpoint_with_args(function: &str, args: &[&str]) -> ApiEndpoint {
        ApiEndpoint {
            function: function.to_string(),
            description: String::new(),
            args: args
                .iter()
                .map(|a| ApiEndpointArg {
                    name: a.to_string(),
                    required: false,
                    arg_type: "string".to_string(),
                    description: None,
                    default: None,
                    members: None,
                })
                .collect(),
        }
    }

    #[test]
    fn find_compose_endpoint_adds_address_when_missing() {
        let mut endpoints = HashMap::new();
        endpoints.insert(
            "/v2/addresses/<address>/compose/burn".to_string(),
            endpoint_with_args("compose_burn", &["quantity"]),
        );
        let (_, ep, injected) = find_compose_endpoint(&endpoints, "burn").unwrap();
        assert!(ep.args.iter().any(|a| a.name == "address"));
        assert!(injected, "a missing address must be flagged as injected");
    }

    #[test]
    fn find_compose_endpoint_keeps_existing_source() {
        let mut endpoints = HashMap::new();
        endpoints.insert(
            "/v2/addresses/<address>/compose/send".to_string(),
            endpoint_with_args("compose_send", &["source", "quantity"]),
        );
        let (_, ep, injected) = find_compose_endpoint(&endpoints, "send").unwrap();
        // No extra address arg added (source already present), so not injected.
        assert_eq!(ep.args.iter().filter(|a| a.name == "address").count(), 0);
        assert!(
            !injected,
            "an existing source must not be flagged as injected"
        );
    }

    #[test]
    fn find_compose_endpoint_unknown_errs() {
        let endpoints: HashMap<String, ApiEndpoint> = HashMap::new();
        assert!(find_compose_endpoint(&endpoints, "nope").is_err());
    }

    // ---- extract_parameters_from_matches ----

    #[test]
    fn extract_parameters_from_matches_reads_registered_args() {
        use clap::{Arg, Command};
        let tx_name = "cov_extract_params_tx";
        let internal_id: &'static str = "__transaction_cov_extract_params_tx_arg_0_quantity";
        args::id_arg_map().insert(format!("{tx_name}:{internal_id}"), "quantity".to_string());

        let ep = endpoint_with_args("compose_send", &["quantity"]);
        let cmd = Command::new(tx_name).arg(Arg::new(internal_id).long("quantity"));
        let matches = cmd.get_matches_from(vec![tx_name, "--quantity", "42"]);

        let params = extract_parameters_from_matches(&ep, tx_name, &matches);
        assert_eq!(params.get("quantity").map(String::as_str), Some("42"));
        // verbose is always added.
        assert_eq!(params.get("verbose").map(String::as_str), Some("true"));
    }

    // ---- display_transaction_summary (smoke: must not error) ----

    #[test]
    fn display_transaction_summary_renders() {
        let (_, spk) = p2wpkh_addr_and_script(9);
        let tx_hex = raw_tx_hex(vec![
            bitcoin::TxOut {
                value: bitcoin::Amount::from_sat(800),
                script_pubkey: spk.clone(),
            },
            bitcoin::TxOut {
                value: bitcoin::Amount::from_sat(0),
                script_pubkey: op_return_script(b"CNTRPRTY0"),
            },
        ]);
        let mut list = bitcoinsigner::UTXOList::new();
        let mut u = bitcoinsigner::UTXO::new(1000, spk);
        u.source_address = Some("bcrt1qsource".to_string());
        list.add(u);
        assert!(display_transaction_summary(&tx_hex, &list, Network::Regtest).is_ok());
    }

    // ---- async HTTP paths via mockito ----

    #[tokio::test]
    async fn broadcast_transaction_success_error_and_unexpected() {
        let mut server = mockito::Server::new_async().await;

        let ok = server
            .mock("POST", "/v2/bitcoin/transactions")
            .with_status(200)
            .with_body(r#"{"result":"txid-123"}"#)
            .create_async()
            .await;
        let config = config_for(&server);
        assert_eq!(
            broadcast_transaction(&config, "aabb").await.unwrap(),
            "txid-123"
        );
        ok.assert_async().await;

        // Error payload -> Err.
        let mut server2 = mockito::Server::new_async().await;
        server2
            .mock("POST", "/v2/bitcoin/transactions")
            .with_status(400)
            .with_body(r#"{"error":"bad tx"}"#)
            .create_async()
            .await;
        let config2 = config_for(&server2);
        assert!(broadcast_transaction(&config2, "aabb").await.is_err());

        // Neither result nor error -> Err.
        let mut server3 = mockito::Server::new_async().await;
        server3
            .mock("POST", "/v2/bitcoin/transactions")
            .with_status(200)
            .with_body(r#"{"other":1}"#)
            .create_async()
            .await;
        let config3 = config_for(&server3);
        assert!(broadcast_transaction(&config3, "aabb").await.is_err());
    }

    #[tokio::test]
    async fn call_compose_api_result_error_unexpected() {
        let ep = endpoint_with_args("compose_send", &[]);

        let mut server = mockito::Server::new_async().await;
        server
            .mock("GET", mockito::Matcher::Any)
            .with_status(200)
            .with_body(r#"{"result":{"rawtransaction":"aa"}}"#)
            .create_async()
            .await;
        let config = config_for(&server);
        let mut params = HashMap::new();
        let out = call_compose_api(&config, "/v2/compose", &ep, &mut params)
            .await
            .unwrap();
        assert_eq!(out.get("rawtransaction").unwrap(), "aa");

        let mut server2 = mockito::Server::new_async().await;
        server2
            .mock("GET", mockito::Matcher::Any)
            .with_status(400)
            .with_body(r#"{"error":"nope"}"#)
            .create_async()
            .await;
        let config2 = config_for(&server2);
        let mut p2 = HashMap::new();
        assert!(call_compose_api(&config2, "/v2/compose", &ep, &mut p2)
            .await
            .is_err());
    }

    #[tokio::test]
    async fn get_utxos_from_api_builds_list() {
        // A tx spending outpoint <zeros>:0 -> the API returns that prevout's vout 0.
        let (_, spk) = p2wpkh_addr_and_script(10);
        let spk_hex = hex::encode(spk.as_bytes());
        let tx_hex = raw_tx_hex(vec![bitcoin::TxOut {
            value: bitcoin::Amount::from_sat(1),
            script_pubkey: spk,
        }]);

        let mut server = mockito::Server::new_async().await;
        let body = format!(
            r#"{{"result":{{"vout":[{{"n":0,"value":0.0001,"scriptPubKey":{{"hex":"{spk_hex}"}}}}]}}}}"#
        );
        server
            .mock("GET", mockito::Matcher::Any)
            .with_status(200)
            .with_body(body)
            .create_async()
            .await;
        let config = config_for(&server);

        let list = get_utxos_from_api(&config, &tx_hex).await.unwrap();
        assert_eq!(list.len(), 1);
        // 0.0001 BTC == 10_000 sats.
        assert_eq!(list.get(0).unwrap().amount, 10_000);
    }

    #[tokio::test]
    async fn get_utxos_from_api_reports_api_error() {
        let (_, spk) = p2wpkh_addr_and_script(11);
        let tx_hex = raw_tx_hex(vec![bitcoin::TxOut {
            value: bitcoin::Amount::from_sat(1),
            script_pubkey: spk,
        }]);
        let mut server = mockito::Server::new_async().await;
        server
            .mock("GET", mockito::Matcher::Any)
            .with_status(200)
            .with_body(r#"{"error":"not found"}"#)
            .create_async()
            .await;
        let config = config_for(&server);
        assert!(get_utxos_from_api(&config, &tx_hex).await.is_err());
    }

    // ---- get_address_and_public_key ----

    #[test]
    fn get_address_and_public_key_prefers_source_then_address() {
        let dir = tempfile::tempdir().unwrap();
        let mut w = BitcoinWallet::new_for_test(dir.path(), Network::Regtest);
        let (addr, _) = w.add_address(None, None, None, None, None).unwrap();

        let mut via_source = HashMap::new();
        via_source.insert("source".to_string(), addr.clone());
        assert!(!get_address_and_public_key(&via_source, &w)
            .unwrap()
            .is_empty());

        let mut via_address = HashMap::new();
        via_address.insert("address".to_string(), addr);
        assert!(!get_address_and_public_key(&via_address, &w)
            .unwrap()
            .is_empty());
    }

    #[test]
    fn get_address_and_public_key_errors_on_missing_or_unknown() {
        let dir = tempfile::tempdir().unwrap();
        let w = BitcoinWallet::new_for_test(dir.path(), Network::Regtest);

        // No address parameter at all.
        assert!(get_address_and_public_key(&HashMap::new(), &w).is_err());

        // Present, but not a wallet address.
        let mut params = HashMap::new();
        params.insert("source".to_string(), "bcrt1qnotinwallet".to_string());
        assert!(get_address_and_public_key(&params, &w).is_err());
    }

    // ---- broadcast_transactions (mockito POST) ----

    #[tokio::test]
    async fn broadcast_transactions_single_and_with_reveal() {
        let mut server = mockito::Server::new_async().await;
        server
            .mock("POST", "/v2/bitcoin/transactions")
            .with_status(200)
            .with_body(r#"{"result":"txid-abc"}"#)
            .create_async()
            .await;
        let config = config_for(&server);

        // Single transaction, then commit + reveal (two broadcasts).
        broadcast_transactions(&config, "deadbeef", None)
            .await
            .unwrap();
        broadcast_transactions(&config, "deadbeef", Some("cafebabe"))
            .await
            .unwrap();
    }

    // ---- handle_sign_command ----

    fn sign_matches(raw: &str, utxos: Option<&str>) -> ArgMatches {
        let cmd = clap::Command::new("sign")
            .arg(clap::Arg::new("rawtransaction").long("rawtransaction"))
            .arg(clap::Arg::new("utxos").long("utxos"));
        let mut argv = vec![
            "sign".to_string(),
            "--rawtransaction".to_string(),
            raw.to_string(),
        ];
        if let Some(u) = utxos {
            argv.push("--utxos".to_string());
            argv.push(u.to_string());
        }
        cmd.try_get_matches_from(argv).unwrap()
    }

    #[tokio::test]
    async fn handle_sign_command_signs_p2wpkh_with_provided_utxos() {
        // A wallet holding the P2WPKH key for seed 0x11, signing a tx that spends
        // that key's output. UTXOs are supplied inline, so there is no network.
        let dir = tempfile::tempdir().unwrap();
        let mut w = BitcoinWallet::new_for_test(dir.path(), Network::Regtest);
        let sk = bitcoin::secp256k1::SecretKey::from_slice(&[0x11u8; 32]).unwrap();
        let wif = bitcoin::PrivateKey::new(sk, bitcoin::Network::Regtest).to_wif();
        let (addr, _) = w.add_address(Some(&wif), None, None, None, None).unwrap();

        let (_, spk) = p2wpkh_addr_and_script(0x11);
        let spk_hex = hex::encode(spk.as_bytes());
        let raw = raw_tx_hex(vec![bitcoin::TxOut {
            value: bitcoin::Amount::from_sat(99_000),
            script_pubkey: bitcoin::ScriptBuf::new_op_return([]),
        }]);
        let utxos =
            format!(r#"[{{"scriptPubKey":"{spk_hex}","amount":100000,"sourceAddress":"{addr}"}}]"#);

        let mut config = AppConfig::new();
        config.set_network(Network::Regtest);
        handle_sign_command(&config, &sign_matches(&raw, Some(&utxos)), &w)
            .await
            .unwrap();
    }

    #[tokio::test]
    async fn handle_sign_command_errors_when_signing_key_absent() {
        let dir = tempfile::tempdir().unwrap();
        let w = BitcoinWallet::new_for_test(dir.path(), Network::Regtest);
        let (_, spk) = p2wpkh_addr_and_script(0x22);
        let spk_hex = hex::encode(spk.as_bytes());
        let raw = raw_tx_hex(vec![bitcoin::TxOut {
            value: bitcoin::Amount::from_sat(1),
            script_pubkey: bitcoin::ScriptBuf::new_op_return([]),
        }]);
        let utxos = format!(r#"[{{"scriptPubKey":"{spk_hex}","amount":100000}}]"#);
        let config = AppConfig::new();
        assert!(
            handle_sign_command(&config, &sign_matches(&raw, Some(&utxos)), &w)
                .await
                .is_err()
        );
    }

    // ---- handle_broadcast_command (aborts at the stdin confirm under `cargo test`) ----

    fn broadcast_matches(raw: &str) -> ArgMatches {
        clap::Command::new("broadcast")
            .arg(clap::Arg::new("rawtransaction").long("rawtransaction"))
            // Mirror the real command's `--yes` flag so `handle_broadcast_command`
            // can read it; omitting it here would panic on `get_flag("yes")`.
            .arg(
                clap::Arg::new("yes")
                    .long("yes")
                    .short('y')
                    .action(clap::ArgAction::SetTrue),
            )
            .try_get_matches_from(["broadcast", "--rawtransaction", raw])
            .unwrap()
    }

    #[tokio::test]
    async fn handle_broadcast_command_previews_then_aborts_at_confirm() {
        // The single input's prevout resolves, so the summary preview runs; then
        // `confirm_broadcast` reads EOF (no TTY under test) -> aborts -> Ok.
        let (_, spk) = p2wpkh_addr_and_script(7);
        let spk_hex = hex::encode(spk.as_bytes());
        let raw = raw_tx_hex(vec![bitcoin::TxOut {
            value: bitcoin::Amount::from_sat(50_000),
            script_pubkey: spk,
        }]);
        let mut server = mockito::Server::new_async().await;
        server
            .mock("GET", mockito::Matcher::Any)
            .with_status(200)
            .with_body(format!(
                r#"{{"result":{{"vout":[{{"n":0,"value":0.001,"scriptPubKey":{{"hex":"{spk_hex}"}}}}]}}}}"#
            ))
            .create_async()
            .await;
        let config = config_for(&server);
        handle_broadcast_command(&config, &broadcast_matches(&raw))
            .await
            .unwrap();
    }

    #[tokio::test]
    async fn handle_broadcast_command_warns_when_inputs_unresolvable() {
        // Invalid tx hex -> input preview fails -> warning branch -> abort -> Ok.
        let config = AppConfig::new();
        handle_broadcast_command(&config, &broadcast_matches("not-hex"))
            .await
            .unwrap();
    }

    // ---- H1: verify_composed_transaction_or_abort ----

    fn wpkh_address(seed: u8) -> bitcoin::Address {
        let wp = bitcoin::WitnessProgram::new(bitcoin::WitnessVersion::V0, &[seed; 20]).unwrap();
        bitcoin::Address::from_witness_program(wp, bitcoin::Network::Regtest)
    }

    fn regtest_config() -> AppConfig {
        let mut config = AppConfig::new();
        config.set_network(crate::config::Network::Regtest);
        config
    }

    fn intent_params(
        asset: &str,
        destination: &str,
        quantity: &str,
    ) -> (
        std::collections::BTreeMap<String, String>,
        HashMap<String, String>,
    ) {
        let requested = [
            ("asset".to_string(), asset.to_string()),
            ("destination".to_string(), destination.to_string()),
            // The real compose path always supplies the funding source, and the
            // BTC-flow check fails closed without it. These fixtures use txs with
            // no BTC outputs (or none at all), so any source verifies.
            ("address".to_string(), wpkh_address(0x33).to_string()),
        ]
        .into_iter()
        .collect();
        let normalized = [("quantity".to_string(), quantity.to_string())]
            .into_iter()
            .collect();
        (requested, normalized)
    }

    #[test]
    fn verify_or_abort_refuses_a_swapped_destination() {
        // The server composed an enhanced_send to `attacker` while the user asked
        // for `victim`: the flow must refuse (Err) so nothing is broadcast.
        let victim = wpkh_address(0x11);
        let attacker = wpkh_address(0x22);
        let raw =
            crate::counterparty::build_test_enhanced_send_tx_hex([0x11; 32], 1, 2500, &attacker);
        let (requested, normalized) = intent_params("XCP", &victim.to_string(), "2500");

        let err = verify_composed_transaction_or_abort(
            &regtest_config(),
            "enhanced_send",
            &requested,
            &normalized,
            &raw,
        )
        .unwrap_err();
        assert!(err.to_string().contains("SECURITY"), "got: {err}");
    }

    #[test]
    fn verify_or_abort_accepts_a_matching_transaction() {
        let dest = wpkh_address(0x11);
        let raw = crate::counterparty::build_test_enhanced_send_tx_hex([0x11; 32], 1, 2500, &dest);
        let (requested, normalized) = intent_params("XCP", &dest.to_string(), "2500");

        // XCP is hard-coded divisible, so the quantity scale is not server-trusted
        // here -> a full Verified, not PartiallyVerified.
        assert_eq!(
            verify_composed_transaction_or_abort(
                &regtest_config(),
                "enhanced_send",
                &requested,
                &normalized,
                &raw,
            )
            .unwrap(),
            VerifyOutcome::Verified
        );
    }

    #[test]
    fn verify_or_abort_allows_but_warns_on_unverifiable_type() {
        // A non-transfer command cannot be independently verified -> Ok (warn),
        // so the normal broadcast confirmation still gates it. This outcome must
        // never allow `--yes` to skip that confirmation (see the call site).
        let dest = wpkh_address(0x11);
        let raw = crate::counterparty::build_test_enhanced_send_tx_hex([0x11; 32], 1, 2500, &dest);
        let (requested, normalized) = intent_params("XCP", &dest.to_string(), "2500");

        assert_eq!(
            verify_composed_transaction_or_abort(
                &regtest_config(),
                "issuance",
                &requested,
                &normalized,
                &raw,
            )
            .unwrap(),
            VerifyOutcome::Unverified
        );
    }

    #[test]
    fn verify_or_abort_partially_verified_when_quantity_scale_is_server_sourced() {
        // H1: for any asset other than BTC/XCP, the ×1e8 scale applied to
        // `--quantity` came from the server's own divisibility answer
        // (`quantity::resolve_divisibility`), so a lying divisibility flag would
        // still "match" here. The banner must say "partially", not "Verified".
        // "FOOBAR" resolves offline to asset id 66051301 (golden value asserted in
        // `counterparty::tests::asset_id_resolves_specials_numeric_and_base26`), so
        // this exercises the quantity-scale branch specifically, not the
        // asset-name-unresolvable one (that name always resolves).
        let dest = wpkh_address(0x11);
        let raw = crate::counterparty::build_test_enhanced_send_tx_hex(
            [0x11; 32], 66_051_301, 2500, &dest,
        );
        let (requested, normalized) = intent_params("FOOBAR", &dest.to_string(), "2500");

        assert_eq!(
            verify_composed_transaction_or_abort(
                &regtest_config(),
                "enhanced_send",
                &requested,
                &normalized,
                &raw,
            )
            .unwrap(),
            VerifyOutcome::PartiallyVerified
        );
    }

    #[test]
    fn verify_or_abort_fails_closed_on_unverifiable_verifiable_type() {
        // M1: a `send` whose composed form the client cannot decode (here a tx
        // with no Counterparty OP_RETURN) must be refused (Err), not warned —
        // even the fail-open under `--yes` is closed.
        let (_, spk) = p2wpkh_addr_and_script(9);
        let raw = raw_tx_hex(vec![bitcoin::TxOut {
            value: bitcoin::Amount::from_sat(50_000),
            script_pubkey: spk,
        }]);
        let dest = wpkh_address(0x11);
        let (requested, normalized) = intent_params("XCP", &dest.to_string(), "2500");

        let err = verify_composed_transaction_or_abort(
            &regtest_config(),
            "send",
            &requested,
            &normalized,
            &raw,
        )
        .unwrap_err();
        assert!(err.to_string().contains("SECURITY"), "got: {err}");
    }

    #[test]
    fn verify_or_abort_asset_unverified_when_asset_name_unresolvable() {
        // M2 + B3: a sub-asset send — destination/quantity/BTC match but the asset
        // name cannot be resolved offline, so the asset went unchecked. The flow
        // returns Ok (partial) without ever claiming a full "Verified", AND the
        // outcome must NOT be `--yes`-auto-confirmable: a hostile server could
        // otherwise compose a *different* asset the source holds to the correct
        // destination/quantity and slip it past unattended automation.
        let dest = wpkh_address(0x11);
        let raw = crate::counterparty::build_test_enhanced_send_tx_hex([0x11; 32], 5, 2500, &dest);
        let (requested, normalized) = intent_params("PARENT.child", &dest.to_string(), "2500");

        let outcome = verify_composed_transaction_or_abort(
            &regtest_config(),
            "enhanced_send",
            &requested,
            &normalized,
            &raw,
        )
        .unwrap();
        assert_eq!(outcome, VerifyOutcome::AssetUnverified);
        assert!(
            !outcome.may_auto_confirm(),
            "an unchecked asset must never auto-confirm under --yes"
        );
    }

    #[test]
    fn only_fully_verified_may_auto_confirm() {
        // B3: the load-bearing rule for the `--yes` gate. ONLY a full match may
        // skip the human confirmation. Every partial outcome leaves a value-bearing
        // aspect on the server's word — an unchecked asset, the quantity's
        // server-reported decimal scale (a possible 1e8 magnitude error), or an
        // undecodable type — so all must be reviewed.
        assert!(VerifyOutcome::Verified.may_auto_confirm());
        assert!(!VerifyOutcome::PartiallyVerified.may_auto_confirm());
        assert!(!VerifyOutcome::AssetUnverified.may_auto_confirm());
        assert!(!VerifyOutcome::Unverified.may_auto_confirm());
    }
}
