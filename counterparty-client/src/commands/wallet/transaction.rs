use anyhow::{anyhow, Context, Result};
use clap::ArgMatches;
use std::collections::HashMap;
use std::io::{self, Write};

use termcolor::{Color, ColorChoice, ColorSpec, StandardStream, WriteColor};

use crate::commands::api;
use crate::commands::api::{ApiEndpoint, ApiEndpointArg};
use crate::commands::wallet::args::ID_ARG_MAP;
use crate::config::AppConfig;
use crate::helpers;
use crate::wallet::BitcoinWallet;
use crate::bitcoinsigner;

/// Information needed for reveal transaction
struct RevealTransactionInfo<'a> {
    raw_tx: &'a str,
    envelope_script: &'a str,
}

/// Find the corresponding compose endpoint for a transaction command
fn find_compose_endpoint<'a>(
    endpoints: &'a HashMap<String, ApiEndpoint>,
    transaction_name: &str,
) -> Result<(&'a String, &'a ApiEndpoint)> {
    // Convert transaction name to compose_X to find the matching endpoint
    let compose_name = format!("compose_{}", transaction_name);

    // Find matching endpoint for the compose function
    api::find_matching_endpoint(endpoints, &compose_name)
}

/// Extract parameters from command line arguments
fn extract_parameters_from_matches(
    endpoint: &ApiEndpoint,
    transaction_name: &str,
    sub_matches: &ArgMatches,
) -> HashMap<String, String> {
    let mut params = HashMap::new();
    let id_map = ID_ARG_MAP.lock().unwrap();

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
        helpers::print_warning(
            "Warning: Required argument '{}' not found in matches",
            Some(&arg.name),
        );
    }
}

/// Get blockchain explorer URL based on network and transaction ID
fn get_explorer_url(network: crate::config::Network, tx_id: &str) -> String {
    match network {
        crate::config::Network::Mainnet => format!("https://mempool.space/tx/{}", tx_id),
        crate::config::Network::Testnet4 => format!("https://mempool.space/testnet4/tx/{}", tx_id),
        crate::config::Network::Regtest => format!("Transaction ID: {}", tx_id), // No explorer for regtest
    }
}

/// Extract the first output's script and value from a raw transaction
fn extract_first_output_info(raw_tx_hex: &str) -> Result<(String, u64)> {
    // Decode the transaction from hex
    let tx_bytes =
        hex::decode(raw_tx_hex).map_err(|e| anyhow!("Failed to decode transaction hex: {}", e))?;

    // Parse the transaction
    let tx: bitcoin::Transaction = bitcoin::consensus::deserialize(&tx_bytes)
        .map_err(|e| anyhow!("Failed to parse transaction: {}", e))?;

    // Check if the transaction has any outputs
    if tx.output.is_empty() {
        return Err(anyhow!("Transaction has no outputs"));
    }

    // Get the first output
    let first_output = &tx.output[0];

    // Get the script_pubkey as hex
    let script_hex = hex::encode(first_output.script_pubkey.as_bytes());

    // Get the value in satoshis
    let value = first_output.value.to_sat();

    Ok((script_hex, value))
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

/// Parse a signed transaction and display inputs, outputs, and fees
fn display_transaction_summary(signed_tx: &str) -> Result<()> {
    // Decode the transaction from hex
    let tx_bytes =
        hex::decode(signed_tx).map_err(|e| anyhow!("Failed to decode transaction hex: {}", e))?;

    // Parse the transaction
    let tx: bitcoin::Transaction = bitcoin::consensus::deserialize(&tx_bytes)
        .map_err(|e| anyhow!("Failed to parse transaction: {}", e))?;

    // Get counts
    let input_count = tx.input.len();
    let output_count = tx.output.len();

    // Create colored output stream
    let mut stdout = StandardStream::stdout(ColorChoice::Always);

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

    // Display inputs with count in cyan
    let _ = stdout.set_color(&subtitle_color);
    let _ = writeln!(stdout, "Inputs ({}):", input_count);
    let _ = stdout.reset();

    // List inputs
    for input in &tx.input {
        let _ = stdout.set_color(&text_color);
        let txid = input.previous_output.txid.to_string();
        let vout = input.previous_output.vout;
        let _ = writeln!(stdout, "{}:{}", txid, vout);
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

        // Get script in string format
        let script_display = output.script_pubkey.to_string();

        let _ = writeln!(
            stdout,
            "{:.8} BTC, {} ({})",
            value_btc, script_type, script_display
        );
    }

    let _ = writeln!(stdout, "");

    // Reset color at the end
    let _ = stdout.reset();

    Ok(())
}

/// Ask for user confirmation before broadcasting
fn confirm_broadcast() -> Result<bool> {
    // Create colored output stream
    let mut stdout = StandardStream::stdout(ColorChoice::Always);

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
    let client = reqwest::Client::new();
    let api_url = config.get_api_url();

    // Prepare the URL for transaction broadcast
    let broadcast_url = format!(
        "{}/v2/bitcoin/transactions?signedhex={}",
        api_url, signed_tx
    );

    // Create URL-encoded form data
    let params = [("signedhex", signed_tx)];

    // Send POST request with URL-encoded form
    let response = client
        .post(&broadcast_url)
        .form(&params)
        .send()
        .await
        .context("Failed to broadcast transaction")?;

    // Parse the response
    let result: serde_json::Value = response
        .json()
        .await
        .context("Failed to parse API response")?;

    // Extract transaction ID from the response
    if let Some(tx_id) = result.get("result").and_then(|r| r.as_str()) {
        Ok(tx_id.to_string())
    } else if let Some(error) = result.get("error") {
        Err(anyhow!("Broadcast failed: {}", error))
    } else {
        Err(anyhow!("Unexpected response format"))
    }
}

/// Get address and public key from parameters and wallet
fn get_address_and_public_key(
    params: &HashMap<String, String>,
    wallet: &BitcoinWallet,
) -> Result<(String, String)> {
    // Try to find the address parameter (commonly named 'source' or 'address')
    let address = params
        .get("source")
        .or_else(|| params.get("address"))
        .ok_or_else(|| anyhow!("Address parameter not found"))?
        .clone();

    // Verify that the address exists in the wallet and get its details
    let addr_details = wallet
        .show_address(&address, None)
        .map_err(|_| anyhow!("Address {} not found in wallet", address))?;

    // Extract the public key from the address details
    let public_key = addr_details
        .get("public_key")
        .and_then(|v| v.as_str())
        .ok_or_else(|| anyhow!("Public key not found for address {}", address))?;

    Ok((address, public_key.to_string()))
}

/// Call the compose API and return the result
async fn call_compose_api(
    config: &AppConfig,
    path: &String,
    endpoint: &ApiEndpoint,
    params: &HashMap<String, String>,
) -> Result<serde_json::Value> {
    // Call API and get the result
    let api_path = api::build_api_path(path, endpoint, params);
    let result = api::perform_api_request(config, &api_path, params).await?;

    // Check if we have a 'result' field in the response
    if let Some(api_result) = result.get("result") {
        Ok(api_result.clone())
    } else if let Some(error) = result.get("error") {
        // Handle API error
        Err(anyhow!("API error: {}", error))
    } else {
        // Generic error if neither 'result' nor 'error' is present
        Err(anyhow!("Unexpected API response format"))
    }
}

//// Extract transaction details from API result
fn extract_transaction_details(api_result: &serde_json::Value) -> Result<(&str, Vec<(&str, u64)>, Option<&str>, Option<serde_json::Value>)> {
    // Extract required fields from result
    let raw_tx_hex = api_result
        .get("rawtransaction")
        .and_then(|v| v.as_str())
        .ok_or_else(|| anyhow!("Missing rawtransaction in API response"))?;

    let inputs_values = api_result
        .get("inputs_values")
        .and_then(|v| v.as_array())
        .ok_or_else(|| anyhow!("Missing inputs_values in API response"))?
        .iter()
        .filter_map(|v| v.as_u64())
        .collect::<Vec<_>>();

    let lock_scripts = api_result
        .get("lock_scripts")
        .and_then(|v| v.as_array())
        .ok_or_else(|| anyhow!("Missing lock_scripts in API response"))?
        .iter()
        .filter_map(|v| v.as_str())
        .collect::<Vec<_>>();

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

/// Extract reveal transaction information if present
fn extract_reveal_transaction_info(
    api_result: &serde_json::Value,
) -> Option<RevealTransactionInfo> {
    let reveal_raw_tx = api_result.get("reveal_rawtransaction")?.as_str()?;
    let envelope_script = api_result.get("envelope_script")?.as_str()?;

    Some(RevealTransactionInfo {
        raw_tx: reveal_raw_tx,
        envelope_script,
    })
}

/// Decode a hex-encoded script
fn decode_script(script_hex: &str) -> Result<bitcoin::ScriptBuf> {
    let script_bytes = hex::decode(script_hex)
        .map_err(|e| anyhow!("Invalid script hex: {}", e))?;

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

/// Build UTXOList for reveal transaction
fn build_reveal_utxo_list(
    script_hex: &str, 
    amount: u64, 
    envelope_script: &str, 
    source_address: &str
) -> Result<bitcoinsigner::UTXOList> {
    // Create a new UTXOList
    let mut utxo_list = bitcoinsigner::UTXOList::new();
    
    // Decode the script from hex
    let script_pubkey = decode_script(script_hex)?;
    
    // Decode the envelope script
    let leaf_script = decode_script(envelope_script)?;
    
    // Create a UTXO with the additional fields for a Taproot reveal transaction
    let mut utxo = bitcoinsigner::UTXO::new(amount, script_pubkey);
    utxo.leaf_script = Some(leaf_script);
    utxo.source_address = Some(source_address.to_string());
    
    // Add the UTXO to the list
    utxo_list.add(utxo);
    
    Ok(utxo_list)
}

/// Handle reveal transaction signing using sign_transaction2
fn handle_reveal_transaction(
    reveal_info: RevealTransactionInfo,
    signed_tx: &str,
    wallet: &BitcoinWallet,
    address: &str,
) -> Result<String> {
    // Extract the first output's script and value from the signed transaction
    let (output_script, output_value) = extract_first_output_info(signed_tx)?;

    // Build the UTXOList for the reveal transaction
    let reveal_utxo_list = build_reveal_utxo_list(
        &output_script,
        output_value,
        reveal_info.envelope_script,
        address
    )?;

    // Sign the reveal transaction using sign_transaction2
    let signed_reveal_tx = wallet
        .sign_transaction(reveal_info.raw_tx, &reveal_utxo_list)
        .map_err(|e| anyhow!("Failed to sign reveal transaction: {}", e))?;

    Ok(signed_reveal_tx)
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
    if let Some(_) = signed_reveal_tx {
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

/// Handle transaction command by calling the corresponding compose API function
pub async fn handle_broadcast_command(
    config: &AppConfig,
    endpoints: &HashMap<String, ApiEndpoint>,
    transaction_name: &str,
    sub_matches: &ArgMatches,
    wallet: &BitcoinWallet,
) -> Result<()> {
    // Find the corresponding compose endpoint
    let (path, endpoint) = find_compose_endpoint(endpoints, transaction_name)?;

    // Extract parameters from command line arguments
    let mut params = extract_parameters_from_matches(endpoint, transaction_name, sub_matches);

    // Get address and public key
    let (address, public_key) = get_address_and_public_key(&params, wallet)?;
    params.insert("multisig_pubkey".to_string(), public_key.to_string());

    // Call API and get the composed transaction
    let api_result = call_compose_api(config, path, endpoint, &params).await?;

    // Extract transaction details from the result
    let (raw_tx_hex, utxos, tx_name, tx_params) = extract_transaction_details(&api_result)?;

    // Display transaction name and parameters before signing
    if tx_name.is_some() || tx_params.is_some() {
        // Create JSON structure with available information
        let mut display_data = serde_json::Map::new();
        
        if let Some(name) = tx_name {
            display_data.insert("name".to_string(), serde_json::Value::String(name.to_string()));
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

    // Sign the transaction using sign_transaction2
    let signed_tx = wallet
        .sign_transaction(raw_tx_hex, &utxo_list)
        .map_err(|e| anyhow!("Failed to sign transaction: {}", e))?;

    // Variable to store signed reveal transaction if needed
    let mut signed_reveal_tx = None;

    // Handle reveal transaction if present
    if let Some(reveal_tx_info) = extract_reveal_transaction_info(&api_result) {
        helpers::print_success("Commit transaction signed:", None);
        println!("{}\n", &signed_tx);

        // Display transaction summary
        display_transaction_summary(&signed_tx)?;

        let reveal_tx = handle_reveal_transaction(reveal_tx_info, &signed_tx, wallet, &address)?;
        signed_reveal_tx = Some(reveal_tx);

        helpers::print_success("Reveal transaction signed:", None);
        println!("{}\n", &signed_reveal_tx.as_ref().unwrap());

        // Display transaction summary
        display_transaction_summary(signed_reveal_tx.as_ref().unwrap())?;
    } else {
        helpers::print_success("Transaction signed:", None);
        println!("{}\n", &signed_tx);
        // Display transaction summary
        display_transaction_summary(&signed_tx)?;
    }

    // Ask for confirmation before broadcasting
    if !confirm_broadcast()? {
        helpers::print_error("Transaction aborted", None);
        return Ok(());
    }

    // Broadcast the transaction(s)
    broadcast_transactions(config, &signed_tx, signed_reveal_tx.as_deref()).await
}