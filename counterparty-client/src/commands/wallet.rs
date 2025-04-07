use anyhow::{Context, Result};
use clap::{Arg, ArgAction, ArgMatches, Command};
use serde_json;
use std::path::PathBuf;

// Import BitcoinWallet from src/wallet.rs
use crate::wallet::BitcoinWallet;

// Builds the wallet command with its subcommands
pub fn build_command() -> Command {
    Command::new("wallet")
        .about("Manage your Counterparty wallet")
        .subcommand(
            Command::new("addaddress")
                .about("Generate or import a new Bitcoin address")
                .arg(
                    Arg::new("private_key")
                        .long("private-key")
                        .help("Existing private key to import")
                        .value_name("PRIVATE_KEY"),
                )
                .arg(
                    Arg::new("mnemonic")
                        .long("mnemonic")
                        .help("BIP39 mnemonic phrase")
                        .value_name("MNEMONIC"),
                )
                .arg(
                    Arg::new("path")
                        .long("path")
                        .help("Derivation path (default: m/84'/0'/0'/0/0 for bech32)")
                        .value_name("PATH"),
                )
                .arg(
                    Arg::new("label")
                        .long("label")
                        .help("A label for the address")
                        .value_name("LABEL"),
                )
                .arg(
                    Arg::new("address_type")
                        .long("address-type")
                        .help("Type of address to generate (bech32 or p2pkh, default: bech32)")
                        .value_name("TYPE")
                        .value_parser(["bech32", "p2pkh"])
                        .default_value("bech32"),
                ),
        )
        .subcommand(
            Command::new("showaddress")
                .about("Show details for a specific address")
                .arg(
                    Arg::new("address")
                        .long("address")
                        .help("The blockchain address to show")
                        .required(true)
                        .value_name("ADDRESS"),
                )
                .arg(
                    Arg::new("private_key")
                        .long("private-key")
                        .help("Show private key and other sensitive information")
                        .action(ArgAction::SetTrue),
                ),
        )
        .subcommand(
            Command::new("addresses")
                .about("List all addresses in the wallet")
                .arg(
                    Arg::new("verbose")
                        .long("verbose")
                        .help("Show detailed information")
                        .action(ArgAction::SetTrue),
                ),
        )
}

// Get the wallet data directory
fn get_wallet_data_dir() -> PathBuf {
    // Try to get from environment variable first
    if let Ok(dir) = std::env::var("COUNTERPARTY_WALLET_DIR") {
        return PathBuf::from(dir);
    }

    // Otherwise use a default path in the user's home directory
    let home = std::env::var("HOME")
        .or_else(|_| std::env::var("USERPROFILE"))
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("."));

    home.join(".counterparty").join("wallet")
}

// Executes a wallet command
pub fn execute_command(matches: &ArgMatches) -> Result<()> {
    let data_dir = get_wallet_data_dir();

    // Ensure the directory exists
    std::fs::create_dir_all(&data_dir).context("Failed to create wallet directory")?;

    let mut wallet = BitcoinWallet::init(&data_dir).context("Failed to initialize wallet")?;

    match matches.subcommand() {
        Some(("addaddress", sub_matches)) => {
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

            // Call the wallet function with the new address_type parameter
            let address = wallet
                .add_address(private_key, mnemonic, path, label, address_type)
                .map_err(|e| anyhow::anyhow!("Failed to add address: {}", e))?;

            println!("Address added successfully: {}", address);
        }
        Some(("showaddress", sub_matches)) => {
            let address = sub_matches.get_one::<String>("address").unwrap();
            let show_private_key = Some(sub_matches.get_flag("private_key"));

            let details = wallet
                .show_address(address, show_private_key)
                .map_err(|e| anyhow::anyhow!("Failed to show address details: {}", e))?;

            println!("{}", serde_json::to_string_pretty(&details)?);
        }
        Some(("addresses", _)) => {
            let addresses = wallet
                .list_addresses()
                .map_err(|e| anyhow::anyhow!("Failed to list addresses: {}", e))?;

            println!("{}", serde_json::to_string_pretty(&addresses)?);
        }
        _ => {
            // No subcommand provided, display help
            let mut wallet_cmd = build_command();
            wallet_cmd.print_help()?;
            println!();
        }
    }

    Ok(())
}
