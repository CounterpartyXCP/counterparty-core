use clap::{Arg, Command};
use std::collections::{HashMap, HashSet};

use crate::commands::api::{ApiEndpoint, ApiEndpointArg};
use crate::commands::wallet::args::ID_ARG_MAP;
use crate::commands::wallet::commands;

/// Filter and sort compose endpoints
fn filter_compose_endpoints(
    endpoints: &HashMap<String, ApiEndpoint>,
) -> Vec<(String, &ApiEndpoint)> {
    // Filter endpoints for compose_* functions
    let mut compose_commands: Vec<(String, &ApiEndpoint)> = endpoints
        .iter()
        .filter(|(_, endpoint)| endpoint.function.starts_with("compose_"))
        .map(|(_, endpoint)| (endpoint.function.clone(), endpoint))
        .collect();

    // Sort commands by name for consistent ordering
    compose_commands.sort_by(|a, b| a.0.cmp(&b.0));

    compose_commands
}

/// Create a transaction command from a compose endpoint
fn create_transaction_command(func_name: &str, endpoint: &ApiEndpoint) -> (String, Command) {
    // Extract transaction name (without compose_ prefix)
    let tx_name = func_name.replace("compose_", "");
    let static_tx_name: &'static str = Box::leak(tx_name.into_boxed_str());

    // Create description for transaction command
    let description = format!(
        "Send a {}",
        &endpoint.description.replace("Composes a ", "")
    );
    let static_description: &'static str = Box::leak(description.into_boxed_str());

    // Create the command
    let cmd = Command::new(static_tx_name).about(static_description);

    (static_tx_name.to_string(), cmd)
}

/// Add a single argument to a command
fn add_argument_to_command(
    cmd: Command,
    arg: &ApiEndpointArg,
    idx: usize,
    command_name: &str,
    used_long_names: &mut HashSet<String>,
) -> Command {
    // Skip this argument if the long name is already used
    if used_long_names.contains(&arg.name) {
        return cmd;
    }

    // Mark this argument name as used
    used_long_names.insert(arg.name.clone());

    // Create unique internal ID
    let internal_id = format!("__transaction_{}_arg_{}_{}", command_name, idx, &arg.name);
    let static_internal_id: &'static str = Box::leak(internal_id.into_boxed_str());

    // Use original argument name as long flag
    let static_long_flag: &'static str = Box::leak(arg.name.clone().into_boxed_str());

    // Store mapping for later
    let id_map_key = format!("{}:{}", command_name, static_internal_id);
    ID_ARG_MAP
        .lock()
        .unwrap()
        .insert(id_map_key, arg.name.clone());

    let static_help: &'static str = Box::leak(
        arg.description
            .as_deref()
            .unwrap_or("")
            .to_string()
            .into_boxed_str(),
    );

    let mut cmd_arg = Arg::new(static_internal_id)
        .long(static_long_flag)
        .help(static_help);

    if arg.required {
        cmd_arg = cmd_arg.required(true);
    }

    if arg.arg_type == "bool" {
        // Modified to accept values for boolean arguments
        cmd_arg = cmd_arg
            //.action(ArgAction::Set)  // Explicitly set to accept values
            .value_name("BOOL")
            .value_parser(|s: &str| -> std::result::Result<String, String> {
                let lower = s.to_lowercase();
                match lower.as_str() {
                    "true" | "1" => Ok("true".to_string()),
                    "false" | "0" => Ok("false".to_string()),
                    _ => Err(format!(
                        "Invalid boolean value: {}. Use true/false or 1/0",
                        s
                    )),
                }
            });
    } else {
        cmd_arg = cmd_arg.value_name("VALUE");
    }

    cmd.arg(cmd_arg)
}

/// Add send_transaction command to the wallet command based on compose API endpoints
pub fn add_broadcast_commands(cmd: Command, endpoints: &HashMap<String, ApiEndpoint>) -> Command {
    let mut wallet_cmd = cmd;

    // Create the parent send_transaction command
    let mut send_transaction_cmd = commands::build_send_transaction_command();

    // Get filtered and sorted compose endpoints
    let sorted_commands = filter_compose_endpoints(endpoints);

    // Add each transaction command as a subcommand of send_transaction
    for (func_name, endpoint) in sorted_commands {
        let (tx_name, mut tx_cmd) = create_transaction_command(&func_name, endpoint);

        // Add arguments, skipping any duplicates
        let mut used_long_names = HashSet::new();

        for (idx, arg) in endpoint.args.iter().enumerate() {
            tx_cmd = add_argument_to_command(tx_cmd, arg, idx, &tx_name, &mut used_long_names);
        }

        let has_address = endpoint.args.iter().any(|arg| arg.name == "address");

        // Check if address parameter exists already
        // Add address argument if needed
        if !has_address {
            // Create an argument id for address that matches the pattern used in extract_parameter_for_arg
            let idx = endpoint.args.len();
            let internal_id = format!("__transaction_{}_arg_{}_address", tx_name, idx);
            let static_internal_id: &'static str = Box::leak(internal_id.into_boxed_str());
            
            // Register the ID in the map - CRUCIAL for parameter extraction
            let id_map_key = format!("{}:{}", tx_name, static_internal_id);
            ID_ARG_MAP
                .lock()
                .unwrap()
                .insert(id_map_key, "address".to_string());
            
            // Add the address argument to the command
            tx_cmd = tx_cmd.arg(
                Arg::new(static_internal_id)
                    .long("address")
                    .help("Destination address for the transaction")
                    .required(true)
                    .value_name("VALUE")
            );
        }

        send_transaction_cmd = send_transaction_cmd.subcommand(tx_cmd);
    }

    // Add send_transaction to wallet command
    wallet_cmd = wallet_cmd.subcommand(send_transaction_cmd);

    wallet_cmd
}
