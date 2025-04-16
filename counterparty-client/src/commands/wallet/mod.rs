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

    match matches.subcommand() {
        Some(("new_address", sub_matches)) => {
            handlers::handle_new_address(&mut wallet, sub_matches)
        }
        Some(("import_address", sub_matches)) => {
            handlers::handle_import_address(&mut wallet, sub_matches)
        }
        Some(("export_address", sub_matches)) => {
            handlers::handle_export_address(&wallet, sub_matches)
        }
        Some(("list_addresses", sub_matches)) => {
            handlers::handle_list_addresses(&wallet, sub_matches)
        }
        Some(("send_transaction", send_tx_matches)) => {
            // Process send_transaction subcommands
            match send_tx_matches.subcommand() {
                Some((tx_name, sub_matches)) => {
                    transaction::handle_broadcast_command(
                        config,
                        endpoints,
                        tx_name,
                        sub_matches,
                        &wallet,
                    )
                    .await
                }
                _ => {
                    // No transaction type provided, display send_transaction help
                    let mut send_tx_cmd = commands::build_send_transaction_command();
                    send_tx_cmd.print_help()?;
                    println!();
                    Ok(())
                }
            }
        }
        Some(("change_password", sub_matches)) => {
            handlers::handle_change_password(&mut wallet, sub_matches)
        }
        Some(("disconnect", sub_matches)) => handlers::handle_disconnect(&mut wallet, sub_matches),

        _ => {
            // No subcommand provided, display help
            let mut wallet_cmd = commands::build_command();
            wallet_cmd.print_help()?;
            println!();
            Ok(())
        }
    }
}