use anyhow::{anyhow, Result};
use clap::ArgMatches;

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
pub fn handle_list_addresses(wallet: &BitcoinWallet, sub_matches: &ArgMatches) -> Result<()> {
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