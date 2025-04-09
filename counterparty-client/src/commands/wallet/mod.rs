// Declare submodules
mod args;
mod broadcast;
mod commands;
mod handlers;
mod transaction;
mod utils;

// Re-export public functions and types
pub use broadcast::add_broadcast_commands;
pub use commands::build_command;

use anyhow::Result;
use clap::ArgMatches;
use std::collections::HashMap;

use crate::commands::api::ApiEndpoint;
use crate::config::AppConfig;

/// Executes a wallet command
pub async fn execute_command(
    config: &AppConfig,
    matches: &ArgMatches,
    endpoints: &HashMap<String, ApiEndpoint>,
) -> Result<()> {
    let data_dir = config.get_data_dir();
    let mut wallet = utils::init_wallet(&data_dir, config.network)?;

    // Print current network information
    let network_name = utils::get_network_name(config.network);
    println!("Using network: {}", network_name);

    match matches.subcommand() {
        Some(("add_address", sub_matches)) => {
            handlers::handle_add_address(&mut wallet, sub_matches)
        }
        Some(("show_address", sub_matches)) => handlers::handle_show_address(&wallet, sub_matches),
        Some(("list_addresses", sub_matches)) => {
            handlers::handle_list_addresses(&wallet, sub_matches)
        }
        Some((cmd_name, sub_matches)) if cmd_name.starts_with("broadcast_") => {
            // Handle broadcast commands asynchronously
            transaction::handle_broadcast_command(config, endpoints, cmd_name, sub_matches, &wallet)
                .await
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
