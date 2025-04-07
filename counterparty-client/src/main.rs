use ::config::{Config, File};
use anyhow::{Context, Result};
use clap::{Arg, ArgAction, Command};

mod commands;
mod config;
mod wallet;
mod signer;
mod keys;

use crate::commands::api;
use crate::commands::wallet as wallet_commands;
use crate::config::AppConfig;


#[tokio::main]
async fn main() -> Result<()> {
    // Load configuration
    let settings = Config::builder()
        .add_source(File::with_name("config").required(false))
        .add_source(File::with_name("config.toml").required(false))
        .add_source(File::with_name("config.json").required(false))
        .build()
        .context("Failed to load configuration")?;

    let config: AppConfig = settings
        .try_deserialize()
        .context("Failed to parse configuration")?;

    // Load endpoints during startup to build the complete command structure
    let endpoints = api::load_or_fetch_endpoints(&config).await?;

    // Build main CLI app with all top-level commands (including dynamic API subcommands)
    let app = Command::new("counterparty-client")
        .version("0.1.0")
        .about("A command-line client for the Counterparty API and wallet")
        .arg(
            Arg::new("update-cache")
                .long("update-cache")
                .help("Update the API endpoints cache")
                .action(ArgAction::SetTrue),
        )
        .subcommand(api::build_command(&endpoints))
        .subcommand(wallet_commands::build_command());

    // Parse command line arguments
    let matches = app.get_matches();

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
            wallet_commands::execute_command(sub_matches)?;
        }
        _ => {
            // No subcommand provided, print help
            let mut app = Command::new("counterparty-client")
                .version("0.1.0")
                .about("A command-line client for the Counterparty API and wallet")
                .subcommand(api::build_command(&endpoints))
                .subcommand(wallet_commands::build_command());
            app.print_help()?;
            println!();
        }
    }

    Ok(())
}
