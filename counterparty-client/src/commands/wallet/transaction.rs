use anyhow::{anyhow, Context, Result};
use clap::ArgMatches;
use std::collections::HashMap;

use crate::commands::api;
use crate::commands::wallet::args::ID_ARG_MAP;
use crate::config::{ApiEndpoint, ApiEndpointArg, AppConfig};
use crate::wallet::BitcoinWallet;

/// Information needed for reveal transaction
struct RevealTransactionInfo<'a> {
    raw_tx: &'a str,
    envelope_script: &'a str,
}

/// Find the corresponding compose endpoint for a broadcast command
fn find_compose_endpoint<'a>(
    endpoints: &'a HashMap<String, ApiEndpoint>,
    command_name: &str,
) -> Result<(&'a String, &'a ApiEndpoint)> {
    // Convert broadcast_X to compose_X to find the matching endpoint
    let compose_name = command_name.replace("broadcast_", "compose_");
    
    // Find matching endpoint for the compose function
    api::find_matching_endpoint(endpoints, &compose_name)
}

/// Extract parameters from command line arguments
fn extract_parameters_from_matches(
    endpoint: &ApiEndpoint,
    command_name: &str,
    sub_matches: &ArgMatches,
) -> HashMap<String, String> {
    let mut params = HashMap::new();
    let id_map = ID_ARG_MAP.lock().unwrap();
    
    for arg in &endpoint.args {
        extract_parameter_for_arg(arg, command_name, sub_matches, &id_map, &mut params);
    }
    
    // Always add verbose=true
    params.insert("verbose".to_string(), "true".to_string());
    
    params
}

/// Extract a specific parameter for an argument
fn extract_parameter_for_arg(
    arg: &ApiEndpointArg,
    command_name: &str,
    sub_matches: &ArgMatches,
    id_map: &HashMap<String, String>,
    params: &mut HashMap<String, String>,
) {
    // Try to find the argument by iterating through the id_map
    for (key, original_name) in id_map.iter() {
        if key.starts_with(&format!("{}:", command_name)) && original_name == &arg.name {
            // Extract the internal ID from the key
            let internal_id = key.split(':').nth(1).unwrap_or("");
            
            if arg.arg_type == "bool" {
                if sub_matches.get_flag(internal_id) {
                    params.insert(arg.name.clone(), "true".to_string());
                    return;
                }
            } else if let Some(value) = sub_matches.get_one::<String>(internal_id) {
                params.insert(arg.name.clone(), value.clone());
                return;
            }
        }
    }
    
    // For debugging
    if arg.required {
        eprintln!(
            "Warning: Required argument '{}' not found in matches",
            arg.name
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
    let tx_bytes = hex::decode(raw_tx_hex)
        .map_err(|e| anyhow!("Failed to decode transaction hex: {}", e))?;
    
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
        // Print the compose result
        println!(
            "Composed transaction: {}",
            serde_json::to_string_pretty(api_result)?
        );
        Ok(api_result.clone())
    } else if let Some(error) = result.get("error") {
        // Handle API error
        Err(anyhow!("API error: {}", error))
    } else {
        // Generic error if neither 'result' nor 'error' is present
        Err(anyhow!("Unexpected API response format"))
    }
}

/// Extract transaction details from API result
fn extract_transaction_details(
    api_result: &serde_json::Value,
) -> Result<(&str, Vec<(&str, u64)>)> {
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
    
    // Construct utxos vector
    let utxos = lock_scripts
        .iter()
        .zip(inputs_values.iter())
        .map(|(script, value)| (*script, *value))
        .collect::<Vec<_>>();
    
    Ok((raw_tx_hex, utxos))
}

/// Extract reveal transaction information if present
fn extract_reveal_transaction_info(api_result: &serde_json::Value) -> Option<RevealTransactionInfo> {
    let reveal_raw_tx = api_result.get("reveal_rawtransaction")?.as_str()?;
    let envelope_script = api_result.get("envelope_script")?.as_str()?;
    
    Some(RevealTransactionInfo {
        raw_tx: reveal_raw_tx,
        envelope_script,
    })
}

/// Handle reveal transaction signing
/// Returns the signed reveal transaction hex
fn handle_reveal_transaction(
    reveal_info: RevealTransactionInfo,
    signed_tx: &str,
    wallet: &BitcoinWallet,
    address: &str,
) -> Result<String> {
    println!("Found Taproot reveal transaction, processing...");
    
    // Extract the first output's script and value from the signed transaction
    let (output_script, output_value) = extract_first_output_info(signed_tx)?;
    
    println!(
        "Using output script: {} and value: {} satoshis for reveal transaction",
        output_script, output_value
    );
    
    // Create UTXOs vector for the reveal transaction
    let reveal_utxos = vec![(output_script.as_str(), output_value)];
    
    // Sign the reveal transaction with taproot reveal parameters
    let signed_reveal_tx = wallet
        .sign_reveal_transaction(
            reveal_info.raw_tx,
            reveal_utxos,
            Some(reveal_info.envelope_script),
            Some(address),
        )
        .map_err(|e| anyhow!("Failed to sign reveal transaction: {}", e))?;
    
    println!("Signed reveal transaction: {}", signed_reveal_tx);
    
    Ok(signed_reveal_tx)
}

/// Broadcast transactions (both main and reveal if present)
async fn broadcast_transactions(
    config: &AppConfig,
    signed_tx: &str,
    signed_reveal_tx: Option<&str>,
) -> Result<()> {
    // Broadcast the main transaction
    println!("Broadcasting main transaction...");
    let tx_id = broadcast_transaction(config, signed_tx).await?;
    
    // Create and display explorer URL for the main transaction
    let explorer_url = get_explorer_url(config.network, &tx_id);
    println!("Main transaction broadcast successfully!");
    println!("Transaction ID: {}", tx_id);
    println!("Explorer URL: {}", explorer_url);
    
    // If we have a reveal transaction, broadcast it too
    if let Some(reveal_tx) = signed_reveal_tx {
        println!("Broadcasting reveal transaction...");
        let reveal_tx_id = broadcast_transaction(config, reveal_tx).await?;
        
        // Create and display explorer URL for the reveal transaction
        let reveal_explorer_url = get_explorer_url(config.network, &reveal_tx_id);
        println!("Reveal transaction broadcast successfully!");
        println!("Reveal Transaction ID: {}", reveal_tx_id);
        println!("Reveal Explorer URL: {}", reveal_explorer_url);
    }
    
    Ok(())
}

/// Handle broadcast command by calling the corresponding compose API function
pub async fn handle_broadcast_command(
    config: &AppConfig,
    endpoints: &HashMap<String, ApiEndpoint>,
    command_name: &str,
    sub_matches: &ArgMatches,
    wallet: &BitcoinWallet,
) -> Result<()> {
    // Find the corresponding compose endpoint
    let (path, endpoint) = find_compose_endpoint(endpoints, command_name)?;
    
    // Extract parameters from command line arguments
    let mut params = extract_parameters_from_matches(endpoint, command_name, sub_matches);
    
    // Get address and public key
    let (address, public_key) = get_address_and_public_key(&params, wallet)?;
    params.insert("multisig_pubkey".to_string(), public_key.to_string());
    println!("Using public key for multisig: {}", public_key);
    
    // Call API and get the composed transaction
    let api_result = call_compose_api(config, path, endpoint, &params).await?;
    
    // Extract transaction details from the result
    let (raw_tx_hex, utxos) = extract_transaction_details(&api_result)?;
    
    // Sign the transaction
    let signed_tx = wallet
        .sign_transaction(raw_tx_hex, utxos)
        .map_err(|e| anyhow!("Failed to sign transaction: {}", e))?;
    
    println!("Signed transaction: {}", signed_tx);
    
    // Variable to store signed reveal transaction if needed
    let mut signed_reveal_tx = None;
    
    // Handle reveal transaction if present
    if let Some(reveal_tx_info) = extract_reveal_transaction_info(&api_result) {
        let reveal_tx = handle_reveal_transaction(reveal_tx_info, &signed_tx, wallet, &address)?;
        signed_reveal_tx = Some(reveal_tx);
    }
    //return Ok(());
    
    // Broadcast the transaction(s)
    broadcast_transactions(
        config,
        &signed_tx,
        signed_reveal_tx.as_deref()
    ).await
}