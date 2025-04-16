use anyhow::{Context, Result};
use clap::{Arg, ArgAction, Command};
use std::fs;
use std::path::Path;
use std::path::PathBuf;

use std::env;
use std::io::Write;
use termcolor::{Color, ColorChoice, ColorSpec, StandardStream, WriteColor};

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
        let content = fs::read(path).context(format!("Failed to read file: {}", path))?;

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
        .disable_help_subcommand(true)
        .arg(
            Arg::new("config-file")
                .long("config-file")
                .help("Path to configuration file")
                .value_parser(clap::value_parser!(PathBuf))
                .global(true)
                .display_order(999999),
        )
        .arg(
            Arg::new("testnet4")
                .long("testnet4")
                .help("Use Testnet4 network")
                .action(ArgAction::SetTrue)
                .global(true)
                .conflicts_with("regtest")
                .display_order(999999),
        )
        .arg(
            Arg::new("regtest")
                .long("regtest")
                .help("Use Regtest network")
                .action(ArgAction::SetTrue)
                .global(true)
                .conflicts_with("testnet4")
                .display_order(999999),
        )
}

// Pre-process arguments for file references
fn pre_process_args() -> Result<()> {
    // Get command line arguments
    let args: Vec<String> = std::env::args().collect();

    // Identify arguments that might be file references and their values
    for i in 1..args.len() {
        if i < args.len() - 1
            && args[i].starts_with("--")
            && (args[i].contains("text")
                || args[i].contains("description")
                || args[i].contains("private-key")
                || args[i].contains("mnemonic"))
        {
            let arg_value = &args[i + 1];

            if arg_value.starts_with('@') {
                // Process the file reference
                let _ = process_file_reference(arg_value);
            }
        }
    }

    Ok(())
}

// Function to determine if an argument should have file reference support
fn should_support_file_reference(arg_id: &str) -> bool {
    // Check if the argument ID contains any of these keywords
    arg_id.contains("text")
        || arg_id.contains("description")
        || arg_id.contains("private-key")
        || arg_id.contains("mnemonic")
}

// Recursive function to add file reference support to all matching arguments
fn add_file_ref_support_recursive(cmd: Command) -> Command {
    // Function to process a command's arguments
    fn process_command_args(mut cmd: Command) -> Command {
        // Collect all arguments to avoid consumption
        let args: Vec<_> = cmd.get_arguments().cloned().collect();

        // Apply custom parser to matching arguments
        for arg in args {
            let arg_id = arg.get_id().to_string();

            // Check if this argument should support file references
            if should_support_file_reference(&arg_id) {
                cmd = cmd.mut_arg(&arg_id, |arg| arg.value_parser(file_reference_parser));
            }
        }

        // Collect subcommand names to avoid consumption
        let subcmds: Vec<_> = cmd.get_subcommands().cloned().collect();

        // Process each subcommand recursively
        for subcmd in subcmds {
            let subcmd_name = subcmd.get_name().to_string();
            cmd = cmd.mut_subcommand(&subcmd_name, |s| process_command_args(s.to_owned()));
        }

        cmd
    }

    // Apply recursive process to the command
    process_command_args(cmd)
}

// Display header information message before executing commands
fn header_message(config: &AppConfig, command_name: &str) {
    // Get active network configuration
    let network_config = config.get_active_network_config();

    // Get wallet path based on current network
    let wallet_path = config.get_data_dir().join("wallet.json");

    // Get app version from Cargo.toml
    let version = env!("CARGO_PKG_VERSION");

    // Format network name with proper capitalization
    let network_name = match config.network {
        Network::Mainnet => "Mainnet",
        Network::Testnet4 => "Testnet4",
        Network::Regtest => "Regtest",
    };

    // Create a line of dashes with command name
    let line_length = 50;
    let cmd_len = command_name.len();
    let dashes_prefix = "-".repeat((line_length - cmd_len) / 2);
    let dashes_suffix = "-".repeat(line_length - cmd_len - dashes_prefix.len());
    let separator = format!("{}{}{}", dashes_prefix, command_name, dashes_suffix);

    // Print the header with just two colors
    let mut stdout = StandardStream::stdout(ColorChoice::Always);

    // Define colors for keys and values
    let mut key_color = ColorSpec::new();
    key_color.set_fg(Some(Color::Cyan)).set_bold(true);

    let mut value_color = ColorSpec::new();
    value_color.set_fg(Some(Color::White));

    // API URL
    let _ = stdout.set_color(&key_color);
    let _ = write!(stdout, "API: ");
    let _ = stdout.set_color(&value_color);
    let _ = writeln!(stdout, "{}", network_config.api_url);

    // Wallet path
    let _ = stdout.set_color(&key_color);
    let _ = write!(stdout, "Wallet: ");
    let _ = stdout.set_color(&value_color);
    let _ = writeln!(stdout, "{}", wallet_path.display());

    // Network
    let _ = stdout.set_color(&key_color);
    let _ = write!(stdout, "Network: ");
    let _ = stdout.set_color(&value_color);
    let _ = writeln!(stdout, "{}", network_name);

    // Version
    let _ = stdout.set_color(&key_color);
    let _ = write!(stdout, "Version: ");
    let _ = stdout.set_color(&value_color);
    let _ = writeln!(stdout, "{}", version);

    // Separator line
    let _ = stdout.set_color(&key_color);
    let _ = writeln!(stdout, "{}\n", separator);

    // Reset color
    let _ = stdout.reset();
}

#[tokio::main]
async fn main() -> Result<()> {
    // Pre-process arguments for file references
    pre_process_args()?;

    // Step 1: Build the full CLI app first
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
    );

    // Step 2: Create default configuration before parsing
    let mut config = AppConfig::new();

    // Step 3: Get the default config path (will be overridden if specified in args)
    let default_config_path = get_default_config_path();

    // Step 4: Parse just the config-file and network args using a temporary parser
    // This parser only looks for these specific args and ignores everything else
    let temp_args = std::env::args().collect::<Vec<_>>();

    let config_file_path = if let Some(pos) = temp_args.iter().position(|a| a == "--config-file") {
        if pos + 1 < temp_args.len() {
            PathBuf::from(&temp_args[pos + 1])
        } else {
            default_config_path.clone()
        }
    } else {
        default_config_path
    };

    // Apply network settings from command line
    if temp_args.contains(&"--testnet4".to_string()) {
        config.set_network(Network::Testnet4);
    } else if temp_args.contains(&"--regtest".to_string()) {
        config.set_network(Network::Regtest);
    }

    // Step 5: Load configuration from file and merge with defaults
    config.load_from_file(&config_file_path)?;

    // Apply network settings again (command line takes precedence)
    if temp_args.contains(&"--testnet4".to_string()) {
        config.set_network(Network::Testnet4);
    } else if temp_args.contains(&"--regtest".to_string()) {
        config.set_network(Network::Regtest);
    }

    // Step 6: Load endpoints
    let endpoints = api::load_or_fetch_endpoints(&config).await?;

    // Now add subcommands after we have loaded endpoints
    app = app.subcommand(api::build_command(&endpoints));

    // Add wallet command with broadcast subcommands dynamically added
    let wallet_cmd = wallet_commands::build_command();
    let wallet_cmd_with_broadcast = wallet_commands::add_broadcast_commands(wallet_cmd, &endpoints);
    app = app.subcommand(wallet_cmd_with_broadcast);

    // Step 7: Add file reference support
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
            let cmd_name = sub_matches.subcommand_name().unwrap_or("api");
            header_message(&config, &format!(" API {} ", cmd_name));
            api::execute_command(&config, sub_matches).await?;
        }
        Some(("wallet", sub_matches)) => {
            let cmd_name = sub_matches.subcommand_name().unwrap_or("wallet");
            header_message(&config, &format!(" Wallet {} ", cmd_name));
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
