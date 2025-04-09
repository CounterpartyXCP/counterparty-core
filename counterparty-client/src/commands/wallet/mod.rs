// Declare submodules
mod args;
mod commands;
mod broadcast;
mod utils;
mod handlers;
mod transaction;

// Re-export public functions and types
pub use commands::build_command;
pub use broadcast::add_broadcast_commands;

use anyhow::Result;
use clap::ArgMatches;
use std::collections::HashMap;

use crate::config::{ApiEndpoint, AppConfig};

/// Executes a wallet command
pub async fn execute_command(
    config: &AppConfig,
    matches: &ArgMatches,
    endpoints: &HashMap<String, ApiEndpoint>,
) -> Result<()> {
    let data_dir = utils::get_wallet_data_dir();
    let mut wallet = utils::init_wallet(&data_dir, config.network)?;
    
    // Print current network information
    let network_name = utils::get_network_name(config.network);
    println!("Using network: {}", network_name);
    
    match matches.subcommand() {
        Some(("addaddress", sub_matches)) => handlers::handle_addaddress(&mut wallet, sub_matches),
        Some(("showaddress", sub_matches)) => handlers::handle_showaddress(&wallet, sub_matches),
        Some(("addresses", sub_matches)) => handlers::handle_addresses(&wallet, sub_matches),
        Some((cmd_name, sub_matches)) if cmd_name.starts_with("broadcast_") => {
            // Handle broadcast commands asynchronously
            transaction::handle_broadcast_command(config, endpoints, cmd_name, sub_matches, &wallet).await
        }
        _ => {
            // No subcommand provided, display help
            let mut wallet_cmd = commands::build_command();
            wallet_cmd.print_help()?;
            println!();
            Ok(())
        }
    }
}