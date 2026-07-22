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
    let description = format!("Send a {}", endpoint.description.replace("Composes a ", ""));
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
    let internal_id = format!("__transaction_{}_arg_{}_{}", command_name, idx, arg.name);
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

        // A compose endpoint that already exposes the funding address does so as
        // `address` or `source`; match both so we never inject a duplicate
        // `--address` (mirrors `find_compose_endpoint` in `transaction.rs`).
        let has_address = endpoint
            .args
            .iter()
            .any(|arg| arg.name == "address" || arg.name == "source");

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
                    .help("Source address that funds and signs the transaction")
                    .required(true)
                    .value_name("VALUE"),
            );
        }

        send_transaction_cmd = send_transaction_cmd.subcommand(tx_cmd);
    }

    // Add send_transaction to wallet command
    wallet_cmd = wallet_cmd.subcommand(send_transaction_cmd);

    wallet_cmd
}

#[cfg(test)]
mod tests {
    use super::*;
    use clap::Command;

    fn arg(name: &str, arg_type: &str) -> ApiEndpointArg {
        ApiEndpointArg {
            name: name.to_string(),
            required: false,
            arg_type: arg_type.to_string(),
            description: Some(format!("the {name}")),
            default: None,
            members: None,
        }
    }

    fn endpoint(function: &str, description: &str, args: Vec<ApiEndpointArg>) -> ApiEndpoint {
        ApiEndpoint {
            function: function.to_string(),
            description: description.to_string(),
            args,
        }
    }

    fn long_flags(cmd: &Command) -> Vec<String> {
        cmd.get_arguments()
            .filter_map(|a| a.get_long().map(|s| s.to_string()))
            .collect()
    }

    fn find_sub<'a>(cmd: &'a Command, name: &str) -> &'a Command {
        cmd.get_subcommands()
            .find(|c| c.get_name() == name)
            .unwrap_or_else(|| panic!("missing subcommand {name}"))
    }

    #[test]
    fn filter_compose_endpoints_keeps_only_compose_sorted() {
        let mut endpoints = HashMap::new();
        endpoints.insert(
            "/v2/addresses/<address>/compose/send".to_string(),
            endpoint("compose_send", "Composes a send", vec![]),
        );
        endpoints.insert(
            "/v2/blocks/<int:block_index>".to_string(),
            endpoint("get_block", "Gets a block", vec![]),
        );
        endpoints.insert(
            "/v2/addresses/<address>/compose/issuance".to_string(),
            endpoint("compose_issuance", "Composes an issuance", vec![]),
        );

        let filtered = filter_compose_endpoints(&endpoints);
        let names: Vec<&str> = filtered.iter().map(|(n, _)| n.as_str()).collect();
        // Only compose_* survive, and they are sorted lexicographically.
        assert_eq!(names, vec!["compose_issuance", "compose_send"]);
    }

    #[test]
    fn create_transaction_command_strips_prefix_and_rewrites_description() {
        let ep = endpoint("compose_send", "Composes a send transaction", vec![]);
        let (name, cmd) = create_transaction_command("compose_send", &ep);
        assert_eq!(name, "send");
        assert_eq!(cmd.get_name(), "send");
        // "Composes a " is rewritten to "Send a ".
        let about = cmd.get_about().unwrap().to_string();
        assert_eq!(about, "Send a send transaction");
    }

    #[test]
    fn add_argument_to_command_dedups_repeated_names() {
        let mut used = HashSet::new();
        let cmd = Command::new("send");
        let cmd = add_argument_to_command(cmd, &arg("asset", "string"), 0, "send", &mut used);
        // A second arg with the same long name is skipped.
        let cmd = add_argument_to_command(cmd, &arg("asset", "string"), 1, "send", &mut used);
        assert_eq!(long_flags(&cmd).iter().filter(|f| *f == "asset").count(), 1);
    }

    #[test]
    fn add_argument_to_command_bool_accepts_true_false_variants() {
        let mut used = HashSet::new();
        let cmd = Command::new("x").arg(clap::Arg::new("dummy").long("dummy"));
        let cmd = add_argument_to_command(
            cmd,
            &arg("allow_unconfirmed_inputs", "bool"),
            0,
            "x",
            &mut used,
        );
        // The bool value_parser normalises 1/0 to true/false and rejects garbage.
        assert!(cmd
            .clone()
            .try_get_matches_from(["x", "--allow_unconfirmed_inputs", "1"])
            .is_ok());
        assert!(cmd
            .clone()
            .try_get_matches_from(["x", "--allow_unconfirmed_inputs", "maybe"])
            .is_err());
    }

    #[test]
    fn add_broadcast_commands_builds_transaction_tree_and_injects_address() {
        let mut endpoints = HashMap::new();
        endpoints.insert(
            "/v2/addresses/<address>/compose/send".to_string(),
            endpoint(
                "compose_send",
                "Composes a send",
                vec![
                    arg("address", "string"),
                    arg("asset", "string"),
                    arg("quantity", "string"),
                ],
            ),
        );
        endpoints.insert(
            "/v2/compose/burn".to_string(),
            // No `address` arg -> the builder must inject one.
            endpoint(
                "compose_burn",
                "Composes a burn",
                vec![arg("quantity", "string")],
            ),
        );

        let wallet = add_broadcast_commands(Command::new("wallet"), &endpoints);
        let tx = find_sub(&wallet, "transaction");

        let send = find_sub(tx, "send");
        let burn = find_sub(tx, "burn");

        // send already declares address; it must appear exactly once.
        let send_flags = long_flags(send);
        assert_eq!(send_flags.iter().filter(|f| *f == "address").count(), 1);
        assert!(send_flags.contains(&"asset".to_string()));

        // burn had no address arg; the builder injects a required --address.
        assert!(long_flags(burn).contains(&"address".to_string()));
    }
}
