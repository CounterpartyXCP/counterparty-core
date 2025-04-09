use ::config::{Config, File};
use anyhow::{Context, Result};
use clap::{Arg, ArgAction, Command};
use std::path::PathBuf;
// New imports needed for config file operations
use std::fs;
use std::io::Write;
use toml;

mod commands;
mod config;
mod signer;
mod wallet;
mod helpers;

use crate::commands::api;
use crate::commands::wallet as wallet_commands;
use crate::config::{AppConfig, Network};

// Function to initialize the configuration file with default values
fn initialize_config_file(config_path: &PathBuf, config: &AppConfig) -> Result<()> {
    // Create parent directories if they don't exist
    if let Some(parent) = config_path.parent() {
        fs::create_dir_all(parent)?;
    }

    // Serialize the configuration to TOML
    let config_toml = toml::to_string(config).context("Failed to serialize config to TOML")?;

    // Write to the file
    let mut file = fs::File::create(config_path)?;
    file.write_all(config_toml.as_bytes())?;
    
    println!("Created default configuration file at: {}", config_path.display());
    
    Ok(())
}

// Generate default config path
fn get_default_config_path() -> PathBuf {
    dirs::data_dir()
        .unwrap_or_else(|| PathBuf::from(".data"))
        .join("counterparty-client")
        .join("config.toml")
}

#[tokio::main]
async fn main() -> Result<()> {
    // Create the default configuration
    let config = AppConfig::new();
    
    // Get default config path
    let default_config_path = get_default_config_path();
    
    // Check if the configuration file exists at the default location, create it if not
    if !default_config_path.exists() {
        initialize_config_file(&default_config_path, &config)?;
    }
    // First, parse just the --config-file argument
    let matches = Command::new("counterparty-client")
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
        .ignore_errors(true)
        .get_matches();

    // Get config file path from arguments or use default
    let config_file_path = matches
        .get_one::<PathBuf>("config-file")
        .cloned()
        .unwrap_or_else(get_default_config_path);

    // Create the default configuration
    let mut config = AppConfig::new();

    // Set network based on command line flags
    if matches.get_flag("testnet4") {
        config.set_network(Network::Testnet4);
    } else if matches.get_flag("regtest") {
        config.set_network(Network::Regtest);
    }

    // Check if the configuration file exists, otherwise create it
    if !config_file_path.exists() {
        initialize_config_file(&config_file_path, &config)?;
    }

    // Load configuration from the specified file
    let settings_builder = Config::builder()
        .add_source(File::from(config_file_path.clone()));

    // If configuration can be loaded, update our AppConfig instance
    if let Ok(settings) = settings_builder.build() {
        if let Ok(file_config) = settings.try_deserialize::<AppConfig>() {
            // Update configuration with values from the file
            if !file_config.api_url.is_empty() {
                config.api_url = file_config.api_url;
            }
            if !file_config.endpoints_url.is_empty() {
                config.endpoints_url = file_config.endpoints_url;
            }
            if file_config.cache_file != PathBuf::new() {
                config.cache_file = file_config.cache_file;
            }
            if file_config.data_dir != PathBuf::new() {
                config.data_dir = file_config.data_dir;
            }
            
            // Merge network configurations
            for (network, net_config) in file_config.network_configs {
                config.network_configs.insert(network, net_config);
            }
            
            // Use the network specified in the configuration file
            config.network = file_config.network;
        }
    }

    // Apply network overrides from command line flags
    if matches.get_flag("testnet4") {
        config.set_network(Network::Testnet4);
    } else if matches.get_flag("regtest") {
        config.set_network(Network::Regtest);
    }

    // Load endpoints after configuration is loaded
    let endpoints = api::load_or_fetch_endpoints(&config).await?;

    // Build main CLI app with all top-level commands
    let mut app = Command::new("counterparty-client")
        .version("0.1.0")
        .about("A command-line client for the Counterparty API and wallet")
        .arg(
            Arg::new("update-cache")
                .long("update-cache")
                .help("Update the API endpoints cache")
                .action(ArgAction::SetTrue),
        )
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
        .subcommand(api::build_command(&endpoints));

    // Add wallet command with broadcast subcommands dynamically added
    let wallet_cmd = wallet_commands::build_command();
    let wallet_cmd_with_broadcast = wallet_commands::add_broadcast_commands(wallet_cmd, &endpoints);
    app = app.subcommand(wallet_cmd_with_broadcast);

    // Parse command line arguments again with the complete command structure
    let final_matches = app.clone().get_matches();

    // Handle update-cache flag
    if final_matches.get_flag("update-cache") {
        println!("Updating API endpoints cache...");
        api::update_cache(&config).await?;
        println!("Cache updated successfully.");
        return Ok(());
    }

    // Execute the requested subcommand
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