use anyhow::{Context, Result};
use clap::{Arg, ArgAction, Command};
use std::path::PathBuf;
use std::fs;
use std::path::Path;

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

// Function to process file references
fn process_file_reference(value: &str) -> Result<String> {
    if value.starts_with('@') {
        let path = &value[1..]; // Remove @ prefix
        if !Path::new(path).exists() {
            return Err(anyhow::anyhow!("File not found: {}", path));
        }
        
        // Read file content
        let content = fs::read(path)
            .context(format!("Failed to read file: {}", path))?;
        
        // Try to interpret as UTF-8 text, fall back to hex for binary
        match String::from_utf8(content.clone()) {
            Ok(text) => Ok(text),
            Err(_) => Ok(hex::encode(content)), // Convert binary to hex
        }
    } else {
        // Not a file reference, return as is
        Ok(value.to_string())
    }
}

// Value parser for file references
fn file_reference_parser(arg: &str) -> std::result::Result<String, String> {
    match process_file_reference(arg) {
        Ok(value) => Ok(value),
        Err(e) => Err(e.to_string()),
    }
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

// Recursive function to add file reference support to all targeted arguments
fn add_file_ref_support_recursive(cmd: Command) -> Command {
    // These argument names will support file references
    let target_args = ["private-key", "mnemonic", "description", "text"];
    
    // Function to process a command's arguments
    fn process_command_args(mut cmd: Command, target_args: &[&str]) -> Command {
        // Collect all argument IDs to avoid consumption
        let arg_ids: Vec<String> = cmd.get_arguments()
            .map(|arg| arg.get_id().to_string())
            .collect();
        
        // Apply custom parser to specified arguments
        for arg_id in arg_ids {
            // Check if this argument matches one of the target names
            if target_args.iter().any(|&target| arg_id == target) {
                cmd = cmd.mut_arg(&arg_id, |arg| {
                    arg.value_parser(file_reference_parser)
                });
            }
        }
        
        // Collect subcommand names
        let subcmd_names: Vec<String> = cmd.get_subcommands()
            .map(|subcmd| subcmd.get_name().to_string())
            .collect();
        
        // Process each subcommand recursively
        for subcmd_name in subcmd_names {
            cmd = cmd.mut_subcommand(subcmd_name, |subcmd| {
                process_command_args(subcmd, target_args)
            });
        }
        
        cmd
    }
    
    // Apply recursive process to the command
    process_command_args(cmd, &target_args)
}

#[tokio::main]
async fn main() -> Result<()> {
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
    
    // Add file reference support
    // This step traverses the ENTIRE command tree and adds file reference support to specified arguments
    app = add_file_ref_support_recursive(app);

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