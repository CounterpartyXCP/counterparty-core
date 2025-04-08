use ::config::{Config, File};
use anyhow::{Context, Result};
use clap::{Arg, ArgAction, Command};

// Make sure to add the following to Cargo.toml:
// [dependencies]
// lazy_static = "1.4.0"

mod commands;
mod config;
mod wallet;
mod signer;
mod keys;

use crate::commands::api;
use crate::commands::wallet as wallet_commands;
use crate::config::{AppConfig, Network};


#[tokio::main]
async fn main() -> Result<()> {
    // Load configuration
    let settings = Config::builder()
        .add_source(File::with_name("config").required(false))
        .add_source(File::with_name("config.toml").required(false))
        .add_source(File::with_name("config.json").required(false))
        .build()
        .context("Failed to load configuration")?;

    // Parse the configuration
    let mut config: AppConfig = settings
        .try_deserialize()
        .context("Failed to parse configuration")?;

    // Load endpoints during startup to build the complete command structure
    let endpoints = api::load_or_fetch_endpoints(&config).await?;

    // Define network arguments that apply to all commands
    let testnet_arg = Arg::new("testnet4")
        .long("testnet4")
        .help("Use Testnet4 network")
        .action(ArgAction::SetTrue)
        .global(true) // Make this argument available to all subcommands
        .conflicts_with("regtest");
        
    let regtest_arg = Arg::new("regtest")
        .long("regtest")
        .help("Use Regtest network")
        .action(ArgAction::SetTrue)
        .global(true) // Make this argument available to all subcommands
        .conflicts_with("testnet4");

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
        .arg(testnet_arg)
        .arg(regtest_arg)
        .subcommand(api::build_command(&endpoints));
        
    // Add wallet command with broadcast subcommands dynamically added
    let wallet_cmd = wallet_commands::build_command();
    let wallet_cmd_with_broadcast = wallet_commands::add_broadcast_commands(wallet_cmd, &endpoints);
    app = app.subcommand(wallet_cmd_with_broadcast);

    // Parse command line arguments - clone app so we can use it later
    let matches = app.clone().get_matches();

    // Set network based on command line flags
    if matches.get_flag("testnet4") {
        config.set_network(Network::Testnet4);
    } else if matches.get_flag("regtest") {
        config.set_network(Network::Regtest);
    }

    // Handle update-cache flag
    if matches.get_flag("update-cache") {
        println!("Updating API endpoints cache...");
        api::update_cache(&config).await?;
        println!("Cache updated successfully.");
        return Ok(());
    }

    // Execute the requested subcommand
    match matches.subcommand() {
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