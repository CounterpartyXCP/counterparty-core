// These lints fire on intentional, domain-driven code: `UTXO`/`UTXOList` are the
// established Bitcoin acronyms, and a few signer/compose helpers carry many
// arguments or a rich return tuple by design.
#![allow(clippy::upper_case_acronyms)]
#![allow(clippy::too_many_arguments)]
#![allow(clippy::type_complexity)]

use anyhow::{anyhow, Context, Result};
use clap::{Arg, ArgAction, Command};
use std::fs;
use std::path::Path;
use std::path::PathBuf;

use std::env;
use std::io::Write;
use termcolor::{Color, ColorChoice, ColorSpec, StandardStream, WriteColor};

// Add clap_complete for shell completion
use clap_complete::{generate, Shell};
use std::fs::File;
use std::io;

// `tokio` is the async runtime the `xcp`/`counterparty-client` binaries start
// via `#[tokio::main]`; the library's async fns run on it but never name it
// directly, so mark the dependency as used for `unused_crate_dependencies`.
use tokio as _;

pub mod bitcoinsigner;
pub mod commands;
pub mod config;
pub mod helpers;
pub mod wallet;

use crate::commands::api;
use crate::commands::wallet as wallet_commands;
use crate::config::{AppConfig, Network};

// Get the binary name used to execute the program
fn get_binary_name() -> String {
    std::env::args()
        .next()
        .map(|path| {
            Path::new(&path)
                .file_name()
                .and_then(|name| name.to_str())
                .unwrap_or("counterparty-client")
                .to_string()
        })
        .unwrap_or_else(|| "counterparty-client".to_string())
}

// Generate default config path
fn get_default_config_path() -> PathBuf {
    dirs::data_dir()
        .unwrap_or_else(|| PathBuf::from(".data"))
        .join("counterparty-client")
        .join("config.toml")
}

// Function to process file references
fn process_file_reference(value: &str) -> Result<String> {
    if let Some(path) = value.strip_prefix('@') {
        // Remove @ prefix

        if !Path::new(path).exists() {
            return Err(anyhow::anyhow!("File not found: {}", path));
        }

        // Read file content
        let content = fs::read(path).context(format!("Failed to read file: {}", path))?;

        // Try to interpret as UTF-8 text, fall back to hex for binary
        match String::from_utf8(content.clone()) {
            Ok(text) => Ok(text.trim().to_string()),
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

// Detect the current shell
fn detect_shell() -> Option<Shell> {
    if let Ok(shell_path) = env::var("SHELL") {
        // Unix-like systems
        if shell_path.contains("bash") {
            return Some(Shell::Bash);
        } else if shell_path.contains("zsh") {
            return Some(Shell::Zsh);
        } else if shell_path.contains("fish") {
            return Some(Shell::Fish);
        }
    }

    // Check for PowerShell on Windows
    #[cfg(windows)]
    {
        if let Ok(pspid) = env::var("POWERSHELL_PROCESS_ID") {
            if !pspid.is_empty() {
                return Some(Shell::PowerShell);
            }
        }
    }

    None
}

// Get the default completion path for a shell
fn get_completion_path(shell: Shell, binary_name: &str) -> Option<PathBuf> {
    let home = dirs::home_dir()?;

    match shell {
        Shell::Bash => {
            // Check if ~/.bashrc exists
            let bashrc = home.join(".bashrc");
            if bashrc.exists() {
                // Include binary name in the file path for bash
                Some(home.join(format!(".{}_bash_completion", binary_name)))
            } else {
                None
            }
        }
        Shell::Zsh => {
            // Common zsh completion directory
            let zsh_comp_dir = home.join(".zsh/completions");
            if zsh_comp_dir.exists() || fs::create_dir_all(&zsh_comp_dir).is_ok() {
                Some(zsh_comp_dir.join(format!("_{}", binary_name)))
            } else {
                None
            }
        }
        Shell::Fish => {
            // Fish completion directory
            let fish_comp_dir = home.join(".config/fish/completions");
            if fish_comp_dir.exists() || fs::create_dir_all(&fish_comp_dir).is_ok() {
                Some(fish_comp_dir.join(format!("{}.fish", binary_name)))
            } else {
                None
            }
        }
        Shell::PowerShell => {
            // PowerShell doesn't have a standard location, so we'll create it in the home directory
            Some(home.join(format!("{}.ps1", binary_name)))
        }
        Shell::Elvish => {
            // Elvish completion path
            let elvish_comp_dir = home.join(".elvish/lib");
            if elvish_comp_dir.exists() || fs::create_dir_all(&elvish_comp_dir).is_ok() {
                Some(elvish_comp_dir.join(format!("{}.elv", binary_name)))
            } else {
                None
            }
        }
        _ => None,
    }
}

// Get the instruction for adding completion to shell config
fn get_shell_config_instruction(shell: Shell, path: &Path) -> String {
    match shell {
        Shell::Bash => {
            format!(
                "Add the following line to your ~/.bashrc or ~/.bash_profile:\n  source \"{}\"",
                path.display()
            )
        }
        Shell::Zsh => "Make sure that the following is present in your ~/.zshrc:\n  \
             fpath=(~/.zsh/completions $fpath)\n  \
             autoload -U compinit\n  \
             compinit"
            .to_string(),
        Shell::Fish => {
            "Fish will automatically load completions from ~/.config/fish/completions/".to_string()
        }
        Shell::PowerShell => {
            format!("Add the following line to your PowerShell profile (run `echo $PROFILE` to locate it):\n  \
                    . \"{}\"", path.display())
        }
        Shell::Elvish => {
            format!(
                "Add the following line to your ~/.elvish/rc.elv:\n  use \"{}\"",
                path.display()
            )
        }
        _ => "Completion script generated.".to_string(),
    }
}

// Install completion script for a given shell
fn install_completion_script(app: &mut Command, shell: Shell) -> Result<()> {
    let binary_name = get_binary_name();
    let path = get_completion_path(shell, &binary_name)
        .ok_or_else(|| anyhow!("Could not determine completion path for {:?}", shell))?;

    // Create parent directory if it doesn't exist
    if let Some(parent) = path.parent() {
        if !parent.exists() {
            fs::create_dir_all(parent)?;
        }
    }

    // Generate completion script
    let mut file = File::create(&path)?;
    generate(shell, app, &binary_name, &mut file);

    // Get additional instructions
    let instructions = get_shell_config_instruction(shell, &path);

    helpers::print_success(
        &format!("Completion script installed to {}", path.display()),
        Some(&instructions),
    );

    Ok(())
}

// Build the completion command with detailed help
fn build_completion_command() -> Command {
    let binary_name = get_binary_name();
    let long_about = format!(
        "\
Generate shell completion scripts for {} commands.

USAGE EXAMPLES:
  # Generate and display completions for your current shell (detected automatically)
  {} completion

  # Install completions for your current shell (detected automatically)
  {} completion --install

  # Generate completions for a specific shell (bash, zsh, fish, powershell, elvish)
  {} completion bash

MANUAL INSTALLATION:
  # Bash
  {} completion bash > ~/.{}_bash_completion
  # Add to your ~/.bashrc: source ~/.{}_bash_completion

  # Zsh
  mkdir -p ~/.zsh/completions
  {} completion zsh > ~/.zsh/completions/_{} 
  # Add to your ~/.zshrc:
  # fpath=(~/.zsh/completions $fpath)
  # autoload -U compinit
  # compinit

  # Fish
  {} completion fish > ~/.config/fish/completions/{}.fish

  # PowerShell
  {} completion powershell > ~/{}.ps1
  # Add to your profile: . ~/{}.ps1
",
        binary_name,
        binary_name,
        binary_name,
        binary_name,
        binary_name,
        binary_name,
        binary_name,
        binary_name,
        binary_name,
        binary_name,
        binary_name,
        binary_name,
        binary_name,
        binary_name
    );

    Command::new("completion")
        .about("Generate shell completion scripts")
        .long_about(long_about)
        .arg(
            Arg::new("shell")
                .help("The shell to generate completions for (if not specified, attempts to detect current shell)")
                .value_parser(["bash", "zsh", "fish", "powershell", "elvish"])
                .value_name("SHELL"),
        )
        .arg(
            Arg::new("install")
                .long("install")
                .short('i')
                .help("Install completions for current shell (or specified shell)")
                .action(ArgAction::SetTrue),
        )
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
            Arg::new("mainnet")
                .long("mainnet")
                .help("Use mainnet network")
                .action(ArgAction::SetTrue)
                .global(true)
                .conflicts_with("regtest")
                .conflicts_with("testnet4")
                .conflicts_with("signet")
                .display_order(999999),
        )
        .arg(
            Arg::new("signet")
                .long("signet")
                .help("Use Signet network")
                .action(ArgAction::SetTrue)
                .global(true)
                .conflicts_with("regtest")
                .conflicts_with("testnet4")
                .conflicts_with("mainnet")
                .display_order(999999),
        )
        .arg(
            Arg::new("testnet4")
                .long("testnet4")
                .help("Use Testnet4 network")
                .action(ArgAction::SetTrue)
                .global(true)
                .conflicts_with("regtest")
                .conflicts_with("mainnet")
                .conflicts_with("signet")
                .display_order(999999),
        )
        .arg(
            Arg::new("regtest")
                .long("regtest")
                .help("Use Regtest network")
                .action(ArgAction::SetTrue)
                .global(true)
                .conflicts_with("testnet4")
                .conflicts_with("mainnet")
                .conflicts_with("signet")
                .display_order(999999),
        )
}

// Function to determine if an argument should have file reference support
fn should_support_file_reference(arg_id: &str) -> bool {
    // Check if the argument ID contains any of these keywords
    arg_id.contains("text")
        || arg_id.contains("description")
        || arg_id.contains("private_key")
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

// Function to add label resolution support to address/source/destination
// parameters. The wallet's label→address map is read once and shared across the
// whole command tree.
fn add_label_resolution_recursive(cmd: Command, wallet: &wallet::BitcoinWallet) -> Command {
    let labels: std::collections::HashMap<String, String> = wallet
        .list_addresses()
        .unwrap_or_default()
        .into_iter()
        .filter_map(|addr_value| {
            match (
                addr_value.get("address").and_then(|a| a.as_str()),
                addr_value.get("label").and_then(|l| l.as_str()),
            ) {
                (Some(addr), Some(label)) => Some((label.to_string(), addr.to_string())),
                _ => None,
            }
        })
        .collect();
    let labels = std::sync::Arc::new(labels);

    fn process_command_args(
        mut cmd: Command,
        labels: &std::sync::Arc<std::collections::HashMap<String, String>>,
    ) -> Command {
        let args: Vec<_> = cmd.get_arguments().cloned().collect();

        for arg in args {
            let arg_id = arg.get_id().to_string();

            // Resolve labels for address / source / destination parameters.
            if arg_id.ends_with("address")
                || arg_id.ends_with("source")
                || arg_id.ends_with("destination")
            {
                let labels = std::sync::Arc::clone(labels);
                let parser = move |s: &str| -> std::result::Result<String, String> {
                    Ok(labels.get(s).cloned().unwrap_or_else(|| s.to_string()))
                };
                cmd = cmd.mut_arg(&arg_id, |a| a.value_parser(parser));
            }
        }

        let subcmds: Vec<_> = cmd.get_subcommands().cloned().collect();
        for subcmd in subcmds {
            let subcmd_name = subcmd.get_name().to_string();
            cmd = cmd.mut_subcommand(&subcmd_name, |s| process_command_args(s.to_owned(), labels));
        }

        cmd
    }

    process_command_args(cmd, &labels)
}

// Display header information message before executing commands
fn header_message(config: &AppConfig, command_name: &str, config_path: &Path) {
    // Get active network configuration
    let network_config = config.get_active_network_config();

    // Get app version from Cargo.toml
    let version = env!("CARGO_PKG_VERSION");

    // Format network name with proper capitalization
    let network_name = match config.network {
        Network::Mainnet => "Mainnet",
        Network::Signet => "Signet",
        Network::Testnet4 => "Testnet4",
        Network::Regtest => "Regtest",
    };

    // Wallet path for the current network (already network-specific).
    let wallet_path = config.get_data_dir();

    // Create a line of dashes framing the command name. `saturating_sub` guards
    // against a command name longer than the line (server-provided names can be
    // long), which would otherwise underflow and panic/OOM.
    let line_length: usize = 50;
    let cmd_len = command_name.len();
    let total_dashes = line_length.saturating_sub(cmd_len);
    let dashes_prefix = "-".repeat(total_dashes / 2);
    let dashes_suffix = "-".repeat(total_dashes - total_dashes / 2);
    let separator = format!("{}{}{}", dashes_prefix, command_name, dashes_suffix);

    // Print the header with just two colors
    let mut stdout = StandardStream::stdout(ColorChoice::Always);

    // Define colors for keys and values
    let mut key_color = ColorSpec::new();
    key_color.set_fg(Some(Color::Cyan)).set_bold(true);

    let mut value_color = ColorSpec::new();
    value_color.set_fg(Some(Color::White));

    // Configuration file path
    let _ = stdout.set_color(&key_color);
    let _ = write!(stdout, "Config: ");
    let _ = stdout.set_color(&value_color);
    let _ = writeln!(stdout, "{}", config_path.display());

    // API URL
    let _ = stdout.set_color(&key_color);
    let _ = write!(stdout, "API: ");
    let _ = stdout.set_color(&value_color);
    let _ = writeln!(stdout, "{}", network_config.api_url);

    // Wallet path
    let _ = stdout.set_color(&key_color);
    let _ = write!(stdout, "Wallet DB: ");
    let _ = stdout.set_color(&value_color);
    let _ = writeln!(stdout, "{}/", wallet_path.display());

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

/// Detect the top-level subcommand (e.g. "wallet", "api", "completion") from the
/// raw arguments, skipping global flags and the `--config-file <path>` value.
/// Used to decide whether the wallet must be initialised (and its password
/// requested) before parsing — only `wallet` commands need it.
fn detect_subcommand() -> Option<String> {
    positional_args().into_iter().next()
}

/// Detect the wallet action (the token after `wallet`, e.g. `disconnect`).
fn detect_wallet_action() -> Option<String> {
    let positional = positional_args();
    if positional.first().map(String::as_str) == Some("wallet") {
        positional.into_iter().nth(1)
    } else {
        None
    }
}

/// The network selected by a `--mainnet`/`--signet`/`--testnet4`/`--regtest`
/// flag, if any (clap enforces they are mutually exclusive).
fn network_from_args(args: &[String]) -> Option<Network> {
    if args.iter().any(|a| a == "--mainnet") {
        Some(Network::Mainnet)
    } else if args.iter().any(|a| a == "--signet") {
        Some(Network::Signet)
    } else if args.iter().any(|a| a == "--testnet4") {
        Some(Network::Testnet4)
    } else if args.iter().any(|a| a == "--regtest") {
        Some(Network::Regtest)
    } else {
        None
    }
}

/// The positional (non-flag) arguments, skipping the `--config-file <path>`
/// value token. The `--config-file=path` form is a single token starting with
/// `-` and is skipped as a flag.
fn positional_args() -> Vec<String> {
    let mut positional = Vec::new();
    let mut args = std::env::args().skip(1);
    while let Some(arg) = args.next() {
        if arg == "--config-file" {
            args.next();
            continue;
        }
        if arg.starts_with('-') {
            continue;
        }
        positional.push(arg);
    }
    positional
}

/// Run the command-line client: parse arguments, load config and endpoints,
/// and dispatch to the API or wallet subcommands. The thin `xcp` and
/// `counterparty-client` binaries just call this.
pub async fn run() -> Result<()> {
    // Fast path: `--version`/`-V` must never require config, network access or a
    // wallet password. Handle it before any of the heavy setup below.
    if std::env::args().any(|a| a == "--version" || a == "-V") {
        println!("{} {}", get_binary_name(), env!("CARGO_PKG_VERSION"));
        return Ok(());
    }

    // Step 1: Build the full CLI app first
    let binary_name = get_binary_name();
    // Create a string slice with static lifetime to use with clap
    let bin_name: &'static str = Box::leak(binary_name.clone().into_boxed_str());
    let mut app = add_common_cli_args(
        Command::new(bin_name)
            .version(env!("CARGO_PKG_VERSION"))
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

    // Accept both `--config-file <path>` and `--config-file=<path>`.
    let config_file_path = temp_args
        .iter()
        .enumerate()
        .find_map(|(i, a)| {
            if let Some(eq) = a.strip_prefix("--config-file=") {
                Some(PathBuf::from(eq))
            } else if a == "--config-file" {
                temp_args.get(i + 1).map(PathBuf::from)
            } else {
                None
            }
        })
        .unwrap_or(default_config_path);

    // Apply the network from the command line (before loading the file so the
    // right network section is selected)...
    if let Some(network) = network_from_args(&temp_args) {
        config.set_network(network);
    }

    // Step 5: Load configuration from file and merge with defaults
    config.load_from_file(&config_file_path)?;

    // ...and again after loading, so the command line always takes precedence.
    if let Some(network) = network_from_args(&temp_args) {
        config.set_network(network);
    }

    // Step 6: Load endpoints
    let endpoints = api::load_or_fetch_endpoints(&config).await?;

    // Step 7: Initialize the wallet only for commands that need it. `api`,
    // `completion`, bare `--help` and `--update-cache` must never prompt for a
    // wallet password or create a wallet as a side effect. `wallet disconnect`
    // is also excluded: it only clears the stored password and must work even
    // when the wallet can't be decrypted, so it never triggers a full init.
    let is_disconnect = matches!(detect_subcommand().as_deref(), Some("wallet"))
        && detect_wallet_action().as_deref() == Some("disconnect");
    let needs_wallet = matches!(detect_subcommand().as_deref(), Some("wallet")) && !is_disconnect;
    let mut wallet: Option<crate::wallet::BitcoinWallet> = if needs_wallet {
        Some(wallet_commands::utils::init_wallet(&config)?)
    } else {
        None
    };

    // Now add subcommands after we have loaded endpoints
    app = app.subcommand(api::build_command(&endpoints));

    // Add wallet command with broadcast subcommands dynamically added
    let wallet_cmd = wallet_commands::build_command();
    let wallet_cmd_with_broadcast = wallet_commands::add_broadcast_commands(wallet_cmd, &endpoints);
    app = app.subcommand(wallet_cmd_with_broadcast);

    // Add completion command
    app = app.subcommand(build_completion_command());

    // Step 8: Add file reference support
    app = add_file_ref_support_recursive(app);

    // Step 9: Add label resolution support for address/destination parameters,
    // but only when a wallet is loaded (labels are a wallet feature).
    // (Quantity → satoshi conversion is done per-asset in the compose path,
    // based on each asset's divisibility; see wallet::quantity.)
    if let Some(wallet) = &wallet {
        app = add_label_resolution_recursive(app, wallet);
    }

    // Step 11: Parse final command line arguments with the complete command structure
    let final_matches = app.clone().get_matches();

    // Step 12: Handle special update-cache flag
    if final_matches.get_flag("update-cache") {
        api::update_cache(&config).await?;
        helpers::print_success("Cache updated successfully.", None);
        return Ok(());
    }

    // Step 13: Execute the requested subcommand
    match final_matches.subcommand() {
        Some(("api", sub_matches)) => {
            let cmd_name = sub_matches.subcommand_name().unwrap_or("api");
            header_message(&config, &format!(" API {} ", cmd_name), &config_file_path);
            api::execute_command(&config, &endpoints, sub_matches).await?;
        }
        Some(("wallet", sub_matches)) => {
            let cmd_name = sub_matches.subcommand_name().unwrap_or("wallet");
            header_message(
                &config,
                &format!(" Wallet {} ", cmd_name),
                &config_file_path,
            );
            // `disconnect` never loads the wallet: just clear the stored password.
            if sub_matches.subcommand_name() == Some("disconnect") {
                wallet_commands::utils::disconnect_wallet(&config)?;
                helpers::print_success("Wallet disconnected successfully", None);
            } else {
                // Safety net: if arg detection missed this (it should not), the
                // wallet has not been initialised yet — do it now.
                if wallet.is_none() {
                    wallet = Some(wallet_commands::utils::init_wallet(&config)?);
                }
                let wallet = wallet
                    .as_mut()
                    .expect("wallet initialised for wallet command");
                wallet_commands::execute_command(&config, sub_matches, &endpoints, wallet).await?;
            }
        }
        Some(("completion", sub_matches)) => {
            // Handle completion command - no header message needed
            let install = sub_matches.get_flag("install");

            // Determine which shell to use - either specified by user or detected
            let shell = if let Some(shell_name) = sub_matches.get_one::<String>("shell") {
                match shell_name.as_str() {
                    "bash" => Shell::Bash,
                    "zsh" => Shell::Zsh,
                    "fish" => Shell::Fish,
                    "powershell" => Shell::PowerShell,
                    "elvish" => Shell::Elvish,
                    _ => {
                        helpers::print_error("Unsupported shell", Some(shell_name));
                        return Ok(());
                    }
                }
            } else if let Some(detected) = detect_shell() {
                detected
            } else {
                helpers::print_error(
                    "Could not detect your shell. Please specify a shell explicitly:",
                    Some(&format!(
                        "{} completion [bash|zsh|fish|powershell|elvish]",
                        binary_name
                    )),
                );
                return Ok(());
            };

            if install {
                // Install mode - save to appropriate location
                install_completion_script(&mut app.clone(), shell)?;
            } else {
                // Just output to stdout
                generate(shell, &mut app.clone(), &binary_name, &mut io::stdout());
            }
        }
        _ => {
            // No subcommand provided, print help
            app.print_help()?;
            println!();
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn network_from_args_maps_each_flag() {
        let s = |v: &str| v.to_string();
        assert_eq!(network_from_args(&[s("--mainnet")]), Some(Network::Mainnet));
        assert_eq!(network_from_args(&[s("--signet")]), Some(Network::Signet));
        assert_eq!(
            network_from_args(&[s("--testnet4")]),
            Some(Network::Testnet4)
        );
        assert_eq!(network_from_args(&[s("--regtest")]), Some(Network::Regtest));
        // No network flag among unrelated args.
        assert_eq!(network_from_args(&[s("wallet"), s("list_addresses")]), None);
    }

    #[test]
    fn should_support_file_reference_matches_secret_bearing_args() {
        assert!(should_support_file_reference("private_key"));
        assert!(should_support_file_reference("mnemonic"));
        assert!(should_support_file_reference(
            "__transaction_broadcast_arg_0_text"
        ));
        assert!(should_support_file_reference("description"));
        assert!(!should_support_file_reference("address"));
        assert!(!should_support_file_reference("quantity"));
    }

    #[test]
    fn get_shell_config_instruction_is_non_empty_per_shell() {
        let path = Path::new("/tmp/completions/xcp");
        for shell in [Shell::Bash, Shell::Zsh, Shell::Fish, Shell::PowerShell] {
            assert!(!get_shell_config_instruction(shell, path).is_empty());
        }
    }

    #[test]
    fn process_file_reference_passes_through_non_references() {
        // A value without the `@` prefix is returned unchanged.
        assert_eq!(
            process_file_reference("plain-value").unwrap(),
            "plain-value"
        );
    }

    #[test]
    fn process_file_reference_reads_and_trims_file_contents() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("secret.txt");
        std::fs::write(&path, "  abc123\n").unwrap();
        let value = format!("@{}", path.display());
        assert_eq!(process_file_reference(&value).unwrap(), "abc123");
    }

    #[test]
    fn process_file_reference_errors_on_missing_file() {
        let err = process_file_reference("@/no/such/file/xcp-test").unwrap_err();
        assert!(err.to_string().contains("File not found"), "got: {err}");
    }
}
