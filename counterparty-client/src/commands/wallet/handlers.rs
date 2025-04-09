use anyhow::{anyhow, Result};
use clap::ArgMatches;

use crate::wallet::BitcoinWallet;
use crate::helpers;

/// Handle the addaddress subcommand
pub fn handle_add_address(wallet: &mut BitcoinWallet, sub_matches: &ArgMatches) -> Result<()> {
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

    // Call the wallet function
    let address = wallet
        .add_address(private_key, mnemonic, path, label, address_type)
        .map_err(|e| anyhow!("Failed to add address: {}", e))?;

    helpers::print_success("Address added successfully:", Some(&address));
    Ok(())
}

/// Handle the showaddress subcommand
pub fn handle_show_address(wallet: &BitcoinWallet, sub_matches: &ArgMatches) -> Result<()> {
    let address = sub_matches.get_one::<String>("address").unwrap();
    let show_private_key = Some(sub_matches.get_flag("private_key"));

    let details = wallet
        .show_address(address, show_private_key)
        .map_err(|e| anyhow!("Failed to show address details: {}", e))?;

    helpers::print_colored_json(&details)?;
    Ok(())
}

/// Handle the addresses subcommand
pub fn handle_list_addresses(wallet: &BitcoinWallet, _sub_matches: &ArgMatches) -> Result<()> {
    let addresses = wallet
        .list_addresses()
        .map_err(|e| anyhow!("Failed to list addresses: {}", e))?;

    helpers::print_colored_json_list(&addresses)?;
    Ok(())
}
