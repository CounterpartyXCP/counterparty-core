use anyhow::{anyhow, Result};
use clap::ArgMatches;

use std::collections::HashMap;

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
    let address = wallet
        .add_address(None, None, None, label, address_type)
        .map_err(|e| anyhow!("Failed to generate new address: {}", e))?;

    helpers::print_success("New address generated successfully:", Some(&address));
    Ok(())
}

/// Handle the import_address subcommand - imports an existing key
pub fn handle_import_address(wallet: &mut BitcoinWallet, sub_matches: &ArgMatches) -> Result<()> {
    // Extract parameters
    let private_key = sub_matches
        .get_one::<String>("private_key")
        .map(|s| s.as_str());
    let mnemonic = sub_matches
        .get_one::<String>("mnemonic")
        .map(|s| s.as_str());
    let path = sub_matches.get_one::<String>("path").map(|s| s.as_str());
    let label = sub_matches.get_one::<String>("label").map(|s| s.as_str());
    let address_type = sub_matches
        .get_one::<String>("address_type")
        .map(|s| s.as_str());

    // Validate that either private key or mnemonic is provided
    if private_key.is_none() && mnemonic.is_none() {
        return Err(anyhow!("Either --private-key or --mnemonic must be provided"));
    }

    // Call the wallet function
    let address = wallet
        .add_address(private_key, mnemonic, path, label, address_type)
        .map_err(|e| anyhow!("Failed to import address: {}", e))?;

    helpers::print_success("Address imported successfully:", Some(&address));
    Ok(())
}

/// Handle the export_address subcommand
pub fn handle_export_address(wallet: &BitcoinWallet, sub_matches: &ArgMatches) -> Result<()> {
    let address = sub_matches.get_one::<String>("address").unwrap();
    
    // Always show private key (set show_private_key to Some(true))
    let show_private_key = Some(true);

    let details = wallet
        .show_address(address, show_private_key)
        .map_err(|e| anyhow!("Failed to export address details: {}", e))?;

    helpers::print_colored_json(&details)?;
    Ok(())
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
pub async fn handle_address_balances(
    config: &AppConfig, 
    sub_matches: &ArgMatches,
) -> Result<()> {
    // Extract address from arguments
    let address = sub_matches.get_one::<String>("address").unwrap();
    
    // First, get Bitcoin balance from UTXOs
    let btc_api_path = format!("/v2/bitcoin/addresses/{}/utxos", address);
    let btc_result = api::perform_api_request(config, &btc_api_path, &HashMap::new()).await?;
    
    // Calculate total BTC balance
    let mut btc_balance: u64 = 0;
    if let Some(utxos) = btc_result.get("result").and_then(|r| r.as_array()) {
        for utxo in utxos {
            if let Some(value) = utxo.get("value").and_then(|v| v.as_u64()) {
                btc_balance += value;
            }
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
            btc_entry.insert("asset".to_string(), serde_json::Value::String("BTC".to_string()));
            
            // Convert to floating point and divide by 10^8
            let btc_amount = (btc_balance as f64) / 100_000_000.0;
            
            // Format as string with 8 decimal places to ensure consistent display
            let btc_amount_str = format!("{:.8}", btc_amount);
            
            // Insert as string value
            btc_entry.insert("quantity".to_string(), serde_json::Value::String(btc_amount_str));
            
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
                    if let Some(asset_info) = balance_obj.get("asset_info").and_then(|ai| ai.as_object()) {
                        if let Some(divisible) = asset_info.get("divisible") {
                            cleaned_balance.insert("divisible".to_string(), divisible.clone());
                        }
                    }
                    
                    // Get quantity from the quantity_normalized field at root level
                    if let Some(quantity_normalized) = balance_obj.get("quantity_normalized") {
                        // Utilisons la valeur telle qu'elle est dans le JSON original
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
            combined_result.insert("BTC".to_string(), serde_json::Value::Number(serde_json::Number::from(btc_balance)));
            combined_result.insert("tokens".to_string(), balances.clone());
            helpers::print_colored_json(&serde_json::Value::Object(combined_result))?;
        }
    } else if let Some(error) = cp_result.get("error") {
        helpers::print_error("API error:", Some(&error.to_string()));
    } else {
        helpers::print_error("Unexpected API response format", None);
    }
    
    Ok(())
}