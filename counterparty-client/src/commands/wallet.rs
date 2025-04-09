use anyhow::{Context, Result};
use clap::{Arg, ArgAction, ArgMatches, Command};
use lazy_static::lazy_static;
use serde_json;
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Mutex;

// Import BitcoinWallet from src/wallet.rs
use crate::commands::api;
use crate::config::{self, ApiEndpoint, ApiEndpointArg, AppConfig};
use crate::wallet::BitcoinWallet;

// Global static mapping between internal argument IDs and their original names
lazy_static! {
    static ref ID_ARG_MAP: Mutex<HashMap<String, String>> = Mutex::new(HashMap::new());
    static ref LONG_ARG_MAP: Mutex<HashMap<String, String>> = Mutex::new(HashMap::new());
}

// Builds the wallet command with its subcommands
pub fn build_command() -> Command {
    let command = Command::new("wallet").about("Manage your Counterparty wallet");

    // Default subcommands (statically defined)
    let command_with_subcommands = command
        .subcommand(build_addaddress_command())
        .subcommand(build_showaddress_command())
        .subcommand(build_addresses_command());

    // We'll add broadcast commands dynamically during runtime initialization
    // (This happens in main.rs when app.get_matches() is called)

    command_with_subcommands
}

// Filter and sort compose endpoints
fn filter_compose_endpoints(
    endpoints: &HashMap<String, ApiEndpoint>,
) -> Vec<(String, &ApiEndpoint)> {
    // Filter endpoints for compose_* functions
    let compose_commands: Vec<(String, &ApiEndpoint)> = endpoints
        .iter()
        .filter(|(_, endpoint)| endpoint.function.starts_with("compose_"))
        .map(|(_, endpoint)| (endpoint.function.clone(), endpoint))
        .collect();

    // Sort commands by name for consistent ordering
    let mut sorted_commands = compose_commands;
    sorted_commands.sort_by(|a, b| a.0.cmp(&b.0));

    sorted_commands
}

// Create a broadcast command from a compose endpoint
fn create_broadcast_command(func_name: &str, endpoint: &ApiEndpoint) -> (String, Command) {
    // Convert compose_X to broadcast_X
    let broadcast_name = func_name.replace("compose_", "broadcast_");
    let static_broadcast_name: &'static str = Box::leak(broadcast_name.into_boxed_str());

    // Create description for broadcast command
    let description = format!(
        "Compose, sign and broadcast a {}",
        &endpoint.description.replace("Composes a ", "")
    );
    let static_description: &'static str = Box::leak(description.into_boxed_str());

    // Create the command
    let cmd = Command::new(static_broadcast_name).about(static_description);

    (static_broadcast_name.to_string(), cmd)
}

// Add an argument to a command
fn add_argument_to_command(
    cmd: Command,
    arg: &ApiEndpointArg,
    idx: usize,
    command_name: &str,
    used_long_names: &mut std::collections::HashSet<String>,
) -> Command {
    // Skip this argument if the long name is already used
    if used_long_names.contains(&arg.name) {
        return cmd;
    }

    // Mark this argument name as used
    used_long_names.insert(arg.name.clone());

    // Create unique internal ID
    let internal_id = format!("__broadcast_{}_arg_{}", command_name, idx);
    let static_internal_id: &'static str = Box::leak(internal_id.into_boxed_str());

    // Use original argument name as long flag
    let static_long_flag: &'static str = Box::leak(arg.name.clone().into_boxed_str());

    // Store mapping for later
    let id_map_key = format!("{}:{}", command_name, static_internal_id);
    ID_ARG_MAP
        .lock()
        .unwrap()
        .insert(id_map_key, arg.name.clone());

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

    cmd.arg(cmd_arg)
}

// Build broadcast commands based on compose API endpoints
pub fn add_broadcast_commands(cmd: Command, endpoints: &HashMap<String, ApiEndpoint>) -> Command {
    let mut wallet_cmd = cmd;

    // Get filtered and sorted compose endpoints
    let sorted_commands = filter_compose_endpoints(endpoints);

    // Add each broadcast command
    for (func_name, endpoint) in sorted_commands {
        let (broadcast_name, mut broadcast_cmd) = create_broadcast_command(&func_name, endpoint);

        // Add arguments, skipping any duplicates
        let mut used_long_names = std::collections::HashSet::new();

        for (idx, arg) in endpoint.args.iter().enumerate() {
            broadcast_cmd = add_argument_to_command(
                broadcast_cmd,
                arg,
                idx,
                &broadcast_name,
                &mut used_long_names,
            );
        }

        wallet_cmd = wallet_cmd.subcommand(broadcast_cmd);
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

// Find the corresponding compose endpoint for a broadcast command
fn find_compose_endpoint<'a>(
    endpoints: &'a HashMap<String, ApiEndpoint>,
    command_name: &str,
) -> Result<(&'a String, &'a ApiEndpoint)> {
    // Convert broadcast_X to compose_X to find the matching endpoint
    let compose_name = command_name.replace("broadcast_", "compose_");

    // Find matching endpoint for the compose function
    api::find_matching_endpoint(endpoints, &compose_name)
}

// Extract parameters from command line arguments
fn extract_parameters_from_matches(
    endpoint: &ApiEndpoint,
    command_name: &str,
    sub_matches: &ArgMatches,
) -> HashMap<String, String> {
    let mut params = HashMap::new();

    // For each argument in the endpoint, look up the corresponding value from matches
    let id_map = ID_ARG_MAP.lock().unwrap();

    for arg in &endpoint.args {
        // Try to find the argument by iterating through the id_map
        // and looking for entries with this command_name and argument name
        let mut found = false;

        for (key, original_name) in id_map.iter() {
            if key.starts_with(&format!("{}:", command_name)) && original_name == &arg.name {
                // Extract the internal ID from the key
                let internal_id = key.split(':').nth(1).unwrap_or("");

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
            eprintln!(
                "Warning: Required argument '{}' not found in matches",
                arg.name
            );
        }
    }

    // Always add verbose=true
    params.insert("verbose".to_string(), "true".to_string());

    params
}

// New function to broadcast a signed transaction
async fn broadcast_transaction(config: &AppConfig, signed_tx: &str) -> Result<String> {
    let client = reqwest::Client::new();
    let api_url = config.get_api_url();
    
    // Prepare the URL for transaction broadcast
    // NOTE: Including signedhex in both URL and POST body due to an API bug
    // TODO: Remove the URL parameter once the API bug is fixed
    let broadcast_url = format!("{}/v2/bitcoin/transactions?signedhex={}", api_url, signed_tx);
    
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
        Err(anyhow::anyhow!("Broadcast failed: {}", error))
    } else {
        Err(anyhow::anyhow!("Unexpected response format"))
    }
}

// Function to get the blockchain explorer URL
fn get_explorer_url(network: config::Network, tx_id: &str) -> String {
    match network {
        config::Network::Mainnet => format!("https://mempool.space/tx/{}", tx_id),
        config::Network::Testnet4 => format!("https://mempool.space/testnet4/tx/{}", tx_id),
        config::Network::Regtest => format!("Transaction ID: {}", tx_id), // No explorer for regtest
    }
}

// New function to extract the first output's script and value from a raw transaction
fn extract_first_output_info(raw_tx_hex: &str) -> Result<(String, u64)> {
    // Decode the transaction from hex
    let tx_bytes = hex::decode(raw_tx_hex)
        .map_err(|e| anyhow::anyhow!("Failed to decode transaction hex: {}", e))?;
    
    // Parse the transaction
    let tx: bitcoin::Transaction = bitcoin::consensus::deserialize(&tx_bytes)
        .map_err(|e| anyhow::anyhow!("Failed to parse transaction: {}", e))?;
    
    // Check if the transaction has any outputs
    if tx.output.is_empty() {
        return Err(anyhow::anyhow!("Transaction has no outputs"));
    }
    
    // Get the first output
    let first_output = &tx.output[0];
    
    // Get the script_pubkey as hex
    let script_hex = hex::encode(first_output.script_pubkey.as_bytes());
    
    // Get the value in satoshis
    let value = first_output.value.to_sat();
    
    Ok((script_hex, value))
}

// Handle broadcast commands by calling the corresponding compose API function
async fn handle_broadcast_command(
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

    // Try to find the address parameter (commonly named 'source' or 'address')
    let address = params
        .get("source")
        .or_else(|| params.get("address"))
        .ok_or_else(|| anyhow::anyhow!("Address parameter not found"))?
        .clone();

    // Verify that the address exists in the wallet and get its details
    let addr_details = wallet
        .show_address(&address, None)
        .map_err(|_| anyhow::anyhow!("Address {} not found in wallet", address))?;

    // Extract the public key from the address details
    let public_key = addr_details
        .get("public_key")
        .and_then(|v| v.as_str())
        .ok_or_else(|| anyhow::anyhow!("Public key not found for address {}", address))?;

    // Add the public key as a multisig_pubkey parameter
    params.insert("multisig_pubkey".to_string(), public_key.to_string());
    
    // Log that we're using the public key
    println!("Using public key for multisig: {}", public_key);

    // Call API and get the result
    let api_path = api::build_api_path(path, endpoint, &params);
    let result = api::perform_api_request(config, &api_path, &params).await?;
    
    // Check if we have a 'result' field in the response
    let api_result = if let Some(api_result) = result.get("result") {
        // Print the compose result
        println!(
            "Composed transaction: {}",
            serde_json::to_string_pretty(&api_result)?
        );
        api_result
    } else if let Some(error) = result.get("error") {
        // Handle API error
        return Err(anyhow::anyhow!("API error: {}", error));
    } else {
        // Generic error if neither 'result' nor 'error' is present
        return Err(anyhow::anyhow!("Unexpected API response format"));
    };

    // Extract required fields from result
    let raw_tx_hex = api_result
        .get("rawtransaction")
        .and_then(|v| v.as_str())
        .ok_or_else(|| anyhow::anyhow!("Missing rawtransaction in API response"))?;

    let inputs_values = api_result
        .get("inputs_values")
        .and_then(|v| v.as_array())
        .ok_or_else(|| anyhow::anyhow!("Missing inputs_values in API response"))?
        .iter()
        .filter_map(|v| v.as_u64())
        .collect::<Vec<_>>();

    let lock_scripts = api_result
        .get("lock_scripts")
        .and_then(|v| v.as_array())
        .ok_or_else(|| anyhow::anyhow!("Missing lock_scripts in API response"))?
        .iter()
        .filter_map(|v| v.as_str())
        .collect::<Vec<_>>();

    // Check that inputs_values and lock_scripts have the same length
    if inputs_values.len() != lock_scripts.len() {
        return Err(anyhow::anyhow!(
            "inputs_values and lock_scripts have different lengths"
        ));
    }

    // Construct utxos vector
    let utxos = lock_scripts
        .iter()
        .zip(inputs_values.iter())
        .map(|(script, value)| (*script, *value))
        .collect::<Vec<_>>();

    // Sign the transaction
    let signed_tx = wallet
        .sign_transaction(raw_tx_hex, utxos)
        .map_err(|e| anyhow::anyhow!("Failed to sign transaction: {}", e))?;

    // Print the signed transaction
    println!("Signed transaction: {}", signed_tx);

    // Variable to store signed reveal transaction if needed
    let mut signed_reveal_tx = String::new();
    
    // Check if there's a reveal transaction to handle
    if let Some(reveal_raw_tx) = api_result.get("reveal_rawtransaction").and_then(|v| v.as_str()) {
        println!("Found Taproot reveal transaction, processing...");
        
        // Get the envelope script
        let envelope_script = api_result
            .get("envelope_script")
            .and_then(|v| v.as_str())
            .ok_or_else(|| anyhow::anyhow!("Missing envelope_script in API response"))?;
        
        // Extract the first output's script and value from the signed transaction
        let (output_script, output_value) = extract_first_output_info(&signed_tx)
            .map_err(|e| anyhow::anyhow!("Failed to extract output info from transaction: {}", e))?;
        
        println!("Using output script: {} and value: {} satoshis for reveal transaction", 
                 output_script, output_value);
        
        // Create UTXOs vector for the reveal transaction
        let reveal_utxos = vec![(output_script.as_str(), output_value)];
        
        // Sign the reveal transaction with taproot reveal parameters
        signed_reveal_tx = wallet
            .sign_transaction_with_taproot_reveal(
                reveal_raw_tx,
                reveal_utxos,
                Some(envelope_script),
                Some(&address)
            )
            .map_err(|e| anyhow::anyhow!("Failed to sign reveal transaction: {}", e))?;
        
        println!("Signed reveal transaction: {}", signed_reveal_tx);
    }

    return Ok(());

    // Check if we have a reveal transaction that needs to be broadcast
    if let Some(_) = api_result.get("reveal_rawtransaction").and_then(|v| v.as_str()) {
        // Broadcast the first transaction
        println!("Broadcasting main transaction...");
        let tx_id = broadcast_transaction(config, &signed_tx).await?;
        
        // Create and display explorer URL for the first transaction
        let explorer_url = get_explorer_url(config.network, &tx_id);
        println!("Main transaction broadcast successfully!");
        println!("Transaction ID: {}", tx_id);
        println!("Explorer URL: {}", explorer_url);
        
        // We already have the signed reveal transaction from above, now broadcast it
        println!("Broadcasting reveal transaction...");
        let reveal_tx_id = broadcast_transaction(config, &signed_reveal_tx).await?;
        
        // Create and display explorer URL for the reveal transaction
        let reveal_explorer_url = get_explorer_url(config.network, &reveal_tx_id);
        println!("Reveal transaction broadcast successfully!");
        println!("Reveal Transaction ID: {}", reveal_tx_id);
        println!("Reveal Explorer URL: {}", reveal_explorer_url);
    } else {
        // Only one transaction to broadcast
        println!("Broadcasting transaction...");
        let tx_id = broadcast_transaction(config, &signed_tx).await?;
        
        // Create and display explorer URL
        let explorer_url = get_explorer_url(config.network, &tx_id);
        println!("Transaction broadcast successfully!");
        println!("Transaction ID: {}", tx_id);
        println!("Explorer URL: {}", explorer_url);
    }

    Ok(())
}

// Executes a wallet command
pub async fn execute_command(
    config: &AppConfig,
    matches: &ArgMatches,
    endpoints: &HashMap<String, ApiEndpoint>,
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
            handle_broadcast_command(config, endpoints, cmd_name, sub_matches, &wallet).await
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
