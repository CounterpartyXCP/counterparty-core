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
use std::io;
use std::fs::File;

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
fn get_completion_path(shell: Shell) -> Option<PathBuf> {
    let home = dirs::home_dir()?;
    
    match shell {
        Shell::Bash => {
            // Check if ~/.bashrc exists
            let bashrc = home.join(".bashrc");
            if bashrc.exists() {
                Some(home.join(".bash_completion"))
            } else {
                None
            }
        },
        Shell::Zsh => {
            // Common zsh completion directory
            let zsh_comp_dir = home.join(".zsh/completions");
            if zsh_comp_dir.exists() || fs::create_dir_all(&zsh_comp_dir).is_ok() {
                Some(zsh_comp_dir.join("_counterparty-client"))
            } else {
                None
            }
        },
        Shell::Fish => {
            // Fish completion directory
            let fish_comp_dir = home.join(".config/fish/completions");
            if fish_comp_dir.exists() || fs::create_dir_all(&fish_comp_dir).is_ok() {
                Some(fish_comp_dir.join("counterparty-client.fish"))
            } else {
                None
            }
        },
        Shell::PowerShell => {
            // PowerShell doesn't have a standard location, so we'll create it in the home directory
            Some(home.join("counterparty-client.ps1"))
        },
        Shell::Elvish => {
            // Elvish completion path
            let elvish_comp_dir = home.join(".elvish/lib");
            if elvish_comp_dir.exists() || fs::create_dir_all(&elvish_comp_dir).is_ok() {
                Some(elvish_comp_dir.join("counterparty-client.elv"))
            } else {
                None
            }
        },
        _ => None,
    }
}

// Get the instruction for adding completion to shell config
fn get_shell_config_instruction(shell: Shell, path: &Path) -> String {
    match shell {
        Shell::Bash => {
            format!("Add the following line to your ~/.bashrc or ~/.bash_profile:\n  source \"{}\"", path.display())
        },
        Shell::Zsh => {
            "Make sure that the following is present in your ~/.zshrc:\n  \
             fpath=(~/.zsh/completions $fpath)\n  \
             autoload -U compinit\n  \
             compinit".to_string()
        },
        Shell::Fish => {
            "Fish will automatically load completions from ~/.config/fish/completions/".to_string()
        },
        Shell::PowerShell => {
            format!("Add the following line to your PowerShell profile (run `echo $PROFILE` to locate it):\n  \
                    . \"{}\"", path.display())
        },
        Shell::Elvish => {
            format!("Add the following line to your ~/.elvish/rc.elv:\n  use \"{}\"", path.display())
        },
        _ => "Completion script generated.".to_string(),
    }
}

// Install completion script for a given shell
fn install_completion_script(app: &mut Command, shell: Shell) -> Result<()> {
    let path = get_completion_path(shell)
        .ok_or_else(|| anyhow!("Could not determine completion path for {:?}", shell))?;
    
    // Create parent directory if it doesn't exist
    if let Some(parent) = path.parent() {
        if !parent.exists() {
            fs::create_dir_all(parent)?;
        }
    }
    
    // Generate completion script
    let mut file = File::create(&path)?;
    generate(shell, app, "counterparty-client", &mut file);
    
    // Get additional instructions
    let instructions = get_shell_config_instruction(shell, &path);
    
    helpers::print_success(
        &format!("Completion script installed to {}", path.display()),
        Some(&instructions)
    );
    
    Ok(())
}

// Build the completion command with detailed help
fn build_completion_command() -> Command {
    let long_about = "\
Generate shell completion scripts for counterparty-client commands.

USAGE EXAMPLES:
  # Generate and display completions for your current shell (detected automatically)
  counterparty-client completion

  # Install completions for your current shell (detected automatically)
  counterparty-client completion --install

  # Generate completions for a specific shell (bash, zsh, fish, powershell, elvish)
  counterparty-client completion bash

MANUAL INSTALLATION:
  # Bash
  counterparty-client completion bash > ~/.bash_completion
  # Add to your ~/.bashrc: source ~/.bash_completion

  # Zsh
  mkdir -p ~/.zsh/completions
  counterparty-client completion zsh > ~/.zsh/completions/_counterparty-client
  # Add to your ~/.zshrc:
  # fpath=(~/.zsh/completions $fpath)
  # autoload -U compinit
  # compinit

  # Fish
  counterparty-client completion fish > ~/.config/fish/completions/counterparty-client.fish

  # PowerShell
  counterparty-client completion powershell > ~/counterparty-client.ps1
  # Add to your profile: . ~/counterparty-client.ps1
";

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

// Function to add label resolution support to address and destination parameters
fn add_label_resolution_recursive(cmd: Command, wallet: &wallet::BitcoinWallet) -> Command {
    // Function to process a command's arguments
    fn process_command_args(mut cmd: Command, wallet: &wallet::BitcoinWallet) -> Command {
        // Collect all arguments to avoid consumption
        let args: Vec<_> = cmd.get_arguments().cloned().collect();

        // Apply custom parser to address/destination arguments
        for arg in args {
            
            let arg_id = arg.get_id().to_string();
            
            // Check if this argument is for address or destination
            if arg_id.ends_with("address") || arg_id.ends_with("destination") {
                // Create a custom value parser that checks for label resolution
                // We need to do the lookup now and create a new parser that doesn't capture wallet
                let addresses = wallet
                    .list_addresses()
                    .unwrap_or_default()
                    .into_iter()
                    .filter_map(|addr_value| {
                        if let (Some(addr), Some(label)) = (
                            addr_value.get("address").and_then(|a| a.as_str()),
                            addr_value.get("label").and_then(|l| l.as_str()),
                        ) {
                            Some((label.to_string(), addr.to_string()))
                        } else {
                            None
                        }
                    })
                    .collect::<std::collections::HashMap<String, String>>();
                
                // Create a Send + Sync parser that doesn't capture wallet
                let parser = move |s: &str| -> std::result::Result<String, String> {
                    if let Some(address) = addresses.get(s) {
                        Ok(address.clone())
                    } else {
                        Ok(s.to_string())
                    }
                };
                
                cmd = cmd.mut_arg(&arg_id, |a| a.value_parser(parser));
            }
        }

        // Collect subcommand names to avoid consumption
        let subcmds: Vec<_> = cmd.get_subcommands().cloned().collect();

        // Process each subcommand recursively
        for subcmd in subcmds {
            let subcmd_name = subcmd.get_name().to_string();
            cmd = cmd.mut_subcommand(&subcmd_name, |s| process_command_args(s.to_owned(), wallet));
        }

        cmd
    }

    // Apply recursive process to the command
    process_command_args(cmd, wallet)
}

// Function to add quantity resolution support to convert floating-point BTC values to integer satoshi values
fn add_quantity_resolution_recursive(cmd: Command) -> Command {
    // Function to process a command's arguments recursively
    fn process_command_args(mut cmd: Command) -> Command {
        // Collect all arguments to avoid consumption during iteration
        let args: Vec<_> = cmd.get_arguments().cloned().collect();

        // Apply custom parser to quantity arguments
        for arg in args {
            let arg_id = arg.get_id().to_string();
            
            // Check if this argument is for quantity (ends with "quantity")
            if arg_id.ends_with("quantity") {
                // Create a custom value parser for quantity conversion
                let parser = move |s: &str| -> std::result::Result<String, String> {
                    // Check if the input contains a decimal point (indicating a float)
                    if s.contains('.') {
                        match s.parse::<f64>() {
                            Ok(value) => {
                                // Convert from BTC to satoshi (multiply by 10^8)
                                let satoshi = (value * 100_000_000.0).round() as i64;
                                Ok(satoshi.to_string())
                            },
                            Err(_) => {
                                // Not a valid floating-point number, return as is
                                Ok(s.to_string())
                            }
                        }
                    } else {
                        // No decimal point, return as is (already in satoshi format)
                        Ok(s.to_string())
                    }
                };
                
                // Apply the custom parser to this argument
                cmd = cmd.mut_arg(&arg_id, |a| a.value_parser(parser));
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
fn header_message(config: &AppConfig, command_name: &str, config_path: &Path) {
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

    // Step 7: Initialize wallet (moved earlier in the process)
    let mut wallet = wallet_commands::utils::init_wallet(&config)?;

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

    // Step 9: Add quantity resolution support (convert BTC to satoshi for float values)
    app = add_quantity_resolution_recursive(app);

    // Step 10: Add label resolution support for address/destination parameters
    app = add_label_resolution_recursive(app, &wallet);

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
            api::execute_command(&config, sub_matches).await?;
        }
        Some(("wallet", sub_matches)) => {
            let cmd_name = sub_matches.subcommand_name().unwrap_or("wallet");
            header_message(&config, &format!(" Wallet {} ", cmd_name), &config_file_path);
            wallet_commands::execute_command(&config, sub_matches, &endpoints, &mut wallet).await?;
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
                    Some("counterparty-client completion [bash|zsh|fish|powershell|elvish]")
                );
                return Ok(());
            };
            
            if install {
                // Install mode - save to appropriate location
                install_completion_script(&mut app.clone(), shell)?;
            } else {
                // Just output to stdout
                generate(shell, &mut app.clone(), "counterparty-client", &mut io::stdout());
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