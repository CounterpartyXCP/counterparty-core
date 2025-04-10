use anyhow::Result;
use clap::{Arg, ArgAction, Command};
use std::path::PathBuf;

mod commands;
mod config;
mod helpers;
mod signer;
mod wallet;

use crate::commands::api;
use crate::commands::wallet as wallet_commands;
use crate::config::{AppConfig, Network};

// Generate default config path
fn get_default_config_path() -> PathBuf {
    dirs::data_dir()
        .unwrap_or_else(|| PathBuf::from(".data"))
        .join("counterparty-client")
        .join("config.toml")
}

// Add common CLI arguments shared between preliminary and final CLI parsers
fn add_common_cli_args(command: Command) -> Command {
    command
        .arg(
            Arg::new("config-file")
                .long("config-file")
                .help("Path to configuration file")
                .value_parser(clap::value_parser!(PathBuf))
                .global(true),
        )
        .arg(
            Arg::new("testnet4")
                .long("testnet4")
                .help("Use Testnet4 network")
                .action(ArgAction::SetTrue)
                .global(true)
                .conflicts_with("regtest"),
        )
        .arg(
            Arg::new("regtest")
                .long("regtest")
                .help("Use Regtest network")
                .action(ArgAction::SetTrue)
                .global(true)
                .conflicts_with("testnet4"),
        )
}

// Apply network settings from command line arguments
fn apply_network_overrides(config: &mut AppConfig, matches: &clap::ArgMatches) {
    if matches.get_flag("testnet4") {
        config.set_network(Network::Testnet4);
    } else if matches.get_flag("regtest") {
        config.set_network(Network::Regtest);
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    // Internal support for password agent
    // This code runs only when the application is launched 
    // by the wallet module to start the agent as a background process
    let args: Vec<String> = std::env::args().collect();
    
    if args.len() > 1 && args[1] == "run-password-agent" {
        // Extract parameters for the agent
        let mut socket_path = None;
        let mut timeout_secs = None;
        let mut nonce_path = None;
        let mut salt_path = None;
        let mut key_info_path = None;
        let mut network = None;        // FIXED: Added network parameter
        let mut base_dir = None;       // FIXED: Added base_dir parameter
        
        // Parse arguments
        for i in 2..args.len() {
            if i + 1 < args.len() {
                match args[i].as_str() {
                    "--socket" => socket_path = Some(args[i + 1].clone()),
                    "--timeout" => {
                        timeout_secs = Some(args[i + 1].parse::<u64>().unwrap_or(600))
                    },
                    "--nonce" => nonce_path = Some(args[i + 1].clone()),
                    "--salt" => salt_path = Some(args[i + 1].clone()),
                    "--key-info" => key_info_path = Some(args[i + 1].clone()),
                    "--network" => {
                        // Parse network from string representation
                        let network_str = &args[i + 1];
                        network = match network_str.as_str() {
                            "Mainnet" => Some(Network::Mainnet),
                            "Testnet4" => Some(Network::Testnet4),
                            "Regtest" => Some(Network::Regtest),
                            _ => {
                                eprintln!("Unknown network type: {}", network_str);
                                None
                            },
                        };
                    },
                    "--base-dir" => base_dir = Some(args[i + 1].clone()),
                    _ => {},
                }
            }
        }
        
        // FIXED: Check for missing parameters before using them in pattern matching
        let missing_params = socket_path.is_none() || nonce_path.is_none() || 
                             salt_path.is_none() || key_info_path.is_none() || 
                             network.is_none() || base_dir.is_none();
        
        if missing_params {
            eprintln!("Missing parameters for password agent");
            if socket_path.is_none() { eprintln!("Missing: --socket"); }
            if nonce_path.is_none() { eprintln!("Missing: --nonce"); }
            if salt_path.is_none() { eprintln!("Missing: --salt"); }
            if key_info_path.is_none() { eprintln!("Missing: --key-info"); }
            if network.is_none() { eprintln!("Missing or invalid: --network"); }
            if base_dir.is_none() { eprintln!("Missing: --base-dir"); }
            std::process::exit(1);
        }
        
        // Now we know all parameters exist, we can safely unwrap them
        let socket = socket_path.unwrap();
        let nonce = nonce_path.unwrap();
        let salt = salt_path.unwrap();
        let key_info = key_info_path.unwrap();
        let net = network.unwrap();
        let dir = base_dir.unwrap();
        
        // Run the agent and exit
        match wallet::run_agent(
            socket,
            timeout_secs.unwrap_or(600),
            nonce,
            salt,
            key_info,
            net,
            dir
        ) {
            Ok(_) => std::process::exit(0),
            Err(e) => {
                eprintln!("Error running password agent: {:?}", e);
                std::process::exit(1);
            }
        }
    }

    // Normal application flow starts here

    // Step 1: Create preliminary CLI app to parse config-file and network arguments
    let preliminary_cli =
        add_common_cli_args(Command::new("counterparty-client")).ignore_errors(true);

    let matches = preliminary_cli.get_matches();

    // Step 2: Get config file path from arguments or use default
    let config_file_path = matches
        .get_one::<PathBuf>("config-file")
        .cloned()
        .unwrap_or_else(get_default_config_path);

    // Step 3: Create default configuration and apply initial network overrides
    let mut config = AppConfig::new();
    apply_network_overrides(&mut config, &matches);

    // Step 4: Load configuration from file and merge with defaults
    config.load_from_file(&config_file_path)?;

    // Step 5: Apply network overrides again (command line takes precedence)
    apply_network_overrides(&mut config, &matches);

    // Step 6: Load endpoints after configuration is loaded
    let endpoints = api::load_or_fetch_endpoints(&config).await?;

    // Step 7: Build final CLI app with all top-level commands
    let mut app = add_common_cli_args(
        Command::new("counterparty-client")
            .version("0.1.0")
            .about("A command-line client for the Counterparty API and wallet"),
    )
    .arg(
        Arg::new("update-cache")
            .long("update-cache")
            .help("Update the API endpoints cache")
            .action(ArgAction::SetTrue),
    )
    .subcommand(api::build_command(&endpoints));

    // Add wallet command with broadcast subcommands dynamically added
    let wallet_cmd = wallet_commands::build_command();
    let wallet_cmd_with_broadcast = wallet_commands::add_broadcast_commands(wallet_cmd, &endpoints);
    app = app.subcommand(wallet_cmd_with_broadcast);

    // Step 8: Parse final command line arguments with the complete command structure
    let final_matches = app.clone().get_matches();

    // Step 9: Handle special update-cache flag
    if final_matches.get_flag("update-cache") {
        api::update_cache(&config).await?;
        helpers::print_success("Cache updated successfully.", None);
        return Ok(());
    }

    // Step 10: Execute the requested subcommand
    match final_matches.subcommand() {
        Some(("api", sub_matches)) => {
            api::execute_command(&config, sub_matches).await?;
        }
        Some(("wallet", sub_matches)) => {
            wallet_commands::execute_command(&config, sub_matches, &endpoints).await?;
        }
        _ => {
            // No subcommand provided, print help
            app.print_help()?;
            println!();
        }
    }

    Ok(())
}