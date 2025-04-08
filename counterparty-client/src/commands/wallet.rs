use anyhow::{Context, Result};
use clap::{Arg, ArgAction, ArgMatches, Command};
use serde_json;
use std::path::PathBuf;
use std::collections::HashMap;
use std::sync::Mutex;
use lazy_static::lazy_static;

// Import BitcoinWallet from src/wallet.rs
use crate::wallet::BitcoinWallet;
use crate::config::{self, ApiEndpoint, Network, AppConfig};
use crate::commands::api;

// Global static mapping between internal argument IDs and their original names
lazy_static! {
    static ref ID_ARG_MAP: Mutex<HashMap<String, String>> = Mutex::new(HashMap::new());
    static ref LONG_ARG_MAP: Mutex<HashMap<String, String>> = Mutex::new(HashMap::new());
}

// Builds the wallet command with its subcommands
pub fn build_command() -> Command {
    let command = Command::new("wallet").about("Manage your Counterparty wallet");
    
    // Default subcommands (statically defined)
    let mut command_with_subcommands = command
        .subcommand(build_addaddress_command())
        .subcommand(build_showaddress_command())
        .subcommand(build_addresses_command());
    
    // We'll add broadcast commands dynamically during runtime initialization
    // (This happens in main.rs when app.get_matches() is called)
    
    command_with_subcommands
}

// Build broadcast commands based on compose API endpoints
pub fn add_broadcast_commands(cmd: Command, endpoints: &HashMap<String, ApiEndpoint>) -> Command {
    let mut wallet_cmd = cmd;
    
    // Filter endpoints for compose_* functions
    let compose_commands: Vec<(String, &ApiEndpoint)> = endpoints
        .iter()
        .filter(|(_, endpoint)| endpoint.function.starts_with("compose_"))
        .map(|(_, endpoint)| (endpoint.function.clone(), endpoint))
        .collect();
    
    // Sort commands by name for consistent ordering
    let mut sorted_commands = compose_commands;
    sorted_commands.sort_by(|a, b| a.0.cmp(&b.0));
    
    // Add each broadcast command
    for (func_name, endpoint) in sorted_commands {
        // Convert compose_X to broadcast_X
        let broadcast_name = func_name.replace("compose_", "broadcast_");
        let static_broadcast_name: &'static str = Box::leak(broadcast_name.into_boxed_str());
        
        // Create description for broadcast command
        let description = format!("Compose, sign and broadcast a {}", 
            &endpoint.description.replace("Composes a ", ""));
        let static_description: &'static str = Box::leak(description.into_boxed_str());
        
        // Create the command
        let mut cmd = Command::new(static_broadcast_name).about(static_description);
        
        // Add arguments, skipping any duplicates
        let mut used_long_names = std::collections::HashSet::new();
        
        for (idx, arg) in endpoint.args.iter().enumerate() {
            // Skip this argument if the long name is already used
            if used_long_names.contains(&arg.name) {
                continue;
            }
            
            // Mark this argument name as used
            used_long_names.insert(arg.name.clone());
            
            // Create unique internal ID
            let internal_id = format!("__broadcast_{}_arg_{}", static_broadcast_name, idx);
            let static_internal_id: &'static str = Box::leak(internal_id.into_boxed_str());
            
            // Use original argument name as long flag
            let static_long_flag: &'static str = Box::leak(arg.name.clone().into_boxed_str());
            
            // Store mapping for later
            let id_map_key = format!("{}:{}", static_broadcast_name, static_internal_id);
            ID_ARG_MAP.lock().unwrap().insert(id_map_key, arg.name.clone());
            
            let static_help: &'static str = Box::leak(
                arg.description
                    .as_deref()
                    .unwrap_or("")
                    .to_string()
                    .into_boxed_str(),
            );

            let mut cmd_arg = Arg::new(static_internal_id)
                .long(static_long_flag)
                .help(static_help);

            if arg.required {
                cmd_arg = cmd_arg.required(true);
            }

            if arg.arg_type == "bool" {
                cmd_arg = cmd_arg.action(ArgAction::SetTrue);
            } else {
                cmd_arg = cmd_arg.value_name("VALUE");
            }

            cmd = cmd.arg(cmd_arg);
        }
        
        wallet_cmd = wallet_cmd.subcommand(cmd);
    }
    
    wallet_cmd
}

// Build the addaddress subcommand
fn build_addaddress_command() -> Command {
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
        )
}

// Build the showaddress subcommand
fn build_showaddress_command() -> Command {
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
        )
}

// Build the addresses subcommand
fn build_addresses_command() -> Command {
    Command::new("addresses")
        .about("List all addresses in the wallet")
        .arg(
            Arg::new("verbose")
                .long("verbose")
                .help("Show detailed information")
                .action(ArgAction::SetTrue),
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

// Get network name as string
fn get_network_name(network: config::Network) -> &'static str {
    match network {
        config::Network::Mainnet => "mainnet",
        config::Network::Testnet4 => "testnet4",
        config::Network::Regtest => "regtest",
    }
}

// Initialize the wallet
fn init_wallet(data_dir: &PathBuf, network: config::Network) -> Result<BitcoinWallet> {
    // Ensure the directory exists
    std::fs::create_dir_all(data_dir).context("Failed to create wallet directory")?;
    
    // Initialize wallet with the specified network
    BitcoinWallet::init(data_dir, network).context("Failed to initialize wallet")
}

// Handle the addaddress subcommand
fn handle_addaddress(wallet: &mut BitcoinWallet, sub_matches: &ArgMatches) -> Result<()> {
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

    // Call the wallet function with the address_type parameter
    let address = wallet
        .add_address(private_key, mnemonic, path, label, address_type)
        .map_err(|e| anyhow::anyhow!("Failed to add address: {}", e))?;

    println!("Address added successfully: {}", address);
    Ok(())
}

// Handle the showaddress subcommand
fn handle_showaddress(wallet: &BitcoinWallet, sub_matches: &ArgMatches) -> Result<()> {
    let address = sub_matches.get_one::<String>("address").unwrap();
    let show_private_key = Some(sub_matches.get_flag("private_key"));

    let details = wallet
        .show_address(address, show_private_key)
        .map_err(|e| anyhow::anyhow!("Failed to show address details: {}", e))?;

    println!("{}", serde_json::to_string_pretty(&details)?);
    Ok(())
}

// Handle the addresses subcommand
fn handle_addresses(wallet: &BitcoinWallet, _sub_matches: &ArgMatches) -> Result<()> {
    let addresses = wallet
        .list_addresses()
        .map_err(|e| anyhow::anyhow!("Failed to list addresses: {}", e))?;

    println!("{}", serde_json::to_string_pretty(&addresses)?);
    Ok(())
}

// Handle broadcast commands by calling the corresponding compose API function
async fn handle_broadcast_command(
    config: &AppConfig,
    endpoints: &HashMap<String, ApiEndpoint>,
    command_name: &str,
    sub_matches: &ArgMatches
) -> Result<()> {
    // Convert broadcast_X to compose_X to find the matching endpoint
    let compose_name = command_name.replace("broadcast_", "compose_");
    
    // Find matching endpoint for the compose function
    let (path, endpoint) = api::find_matching_endpoint(endpoints, &compose_name)?;
    
    // We'll build our parameters by looking at all possible arguments in the matches
    let mut params = HashMap::new();
    
    // For each argument in the endpoint, look up the corresponding value from matches
    let id_map = ID_ARG_MAP.lock().unwrap();
    
    // Debug for argument matching
    let mut debug_args = vec![];
    
    for arg in &endpoint.args {
        // Try to find the argument by iterating through the id_map
        // and looking for entries with this command_name and argument name
        let mut found = false;
        
        for (key, original_name) in id_map.iter() {
            if key.starts_with(&format!("{}:", command_name)) && original_name == &arg.name {
                // Extract the internal ID from the key
                let internal_id = key.split(':').nth(1).unwrap_or("");
                
                debug_args.push(format!("Trying ID: {} for arg {}", internal_id, arg.name));
                
                if arg.arg_type == "bool" {
                    if sub_matches.get_flag(internal_id) {
                        params.insert(arg.name.clone(), "true".to_string());
                        found = true;
                        break;
                    }
                } else if let Some(value) = sub_matches.get_one::<String>(internal_id) {
                    params.insert(arg.name.clone(), value.clone());
                    found = true;
                    break;
                }
            }
        }
        
        // For debugging
        if !found && arg.required {
            eprintln!("Warning: Required argument '{}' not found in matches", arg.name);
        }
    }
    
    // Construct API path with parameters
    let api_path = api::build_api_path(path, endpoint, &params);
    
    // Call the API endpoint and get the result
    let result = api::perform_api_request(config, &api_path, &params).await?;
    
    // For now, just print the result (will be extended in the future)
    println!("{}", serde_json::to_string_pretty(&result)?);
    
    Ok(())
}

// Executes a wallet command
pub async fn execute_command(
    config: &AppConfig, 
    matches: &ArgMatches, 
    endpoints: &HashMap<String, ApiEndpoint>
) -> Result<()> {
    let data_dir = get_wallet_data_dir();
    let mut wallet = init_wallet(&data_dir, config.network)?;

    // Print current network information
    let network_name = get_network_name(config.network);
    println!("Using network: {}", network_name);

    match matches.subcommand() {
        Some(("addaddress", sub_matches)) => handle_addaddress(&mut wallet, sub_matches),
        Some(("showaddress", sub_matches)) => handle_showaddress(&wallet, sub_matches),
        Some(("addresses", sub_matches)) => handle_addresses(&wallet, sub_matches),
        Some((cmd_name, sub_matches)) if cmd_name.starts_with("broadcast_") => {
            // Handle broadcast commands asynchronously
            handle_broadcast_command(config, endpoints, cmd_name, sub_matches).await
        }
        _ => {
            // No subcommand provided, display help
            let mut wallet_cmd = build_command();
            wallet_cmd.print_help()?;
            println!();
            Ok(())
        }
    }
}