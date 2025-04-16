use anyhow::Result;
use clap::{Arg, ArgMatches, Command};
use std::collections::HashMap;

use crate::api::models::{ApiEndpoint, ApiEndpointArg};

// ---- Command Building ----

// Builds the API command structure with all subcommands
pub fn build_command(endpoints: &HashMap<String, ApiEndpoint>) -> Command {
    let mut api_cmd = Command::new("api").about("Interact with the Counterparty API");

    let grouped_endpoints = group_endpoints_by_type(endpoints);

    for (func_name, endpoint) in grouped_endpoints {
        api_cmd = add_subcommand(api_cmd, func_name, endpoint);
    }

    api_cmd
}

// Groups endpoints by their type (compose, get, other)
fn group_endpoints_by_type(endpoints: &HashMap<String, ApiEndpoint>) -> Vec<(String, ApiEndpoint)> {
    let mut compose_commands = Vec::new();
    let mut get_commands = Vec::new();
    let mut other_commands = Vec::new();

    // Create a deduplicated map of functions
    let functions = deduplicate_endpoint_functions(endpoints);

    // Sort functions into groups
    for (func_name, endpoint) in functions {
        if func_name.starts_with("compose_") {
            compose_commands.push((func_name, endpoint));
        } else if func_name.starts_with("get_") {
            get_commands.push((func_name, endpoint));
        } else {
            other_commands.push((func_name, endpoint));
        }
    }

    // Sort each group and combine
    compose_commands.sort_by(|a, b| a.0.cmp(&b.0));
    get_commands.sort_by(|a, b| a.0.cmp(&b.0));
    other_commands.sort_by(|a, b| a.0.cmp(&b.0));

    let mut all_commands = Vec::new();
    all_commands.extend(compose_commands);
    all_commands.extend(get_commands);
    all_commands.extend(other_commands);

    all_commands
}

// Creates a deduplicated map of function names to endpoints
fn deduplicate_endpoint_functions(
    endpoints: &HashMap<String, ApiEndpoint>,
) -> HashMap<String, ApiEndpoint> {
    let mut functions = HashMap::new();

    for (_path, endpoint) in endpoints {
        functions.insert(endpoint.function.clone(), endpoint.clone());
    }

    functions
}

// Adds a subcommand to the API command
fn add_subcommand(cmd: Command, func_name: String, endpoint: ApiEndpoint) -> Command {
    let static_func_name: &'static str = Box::leak(func_name.into_boxed_str());
    let static_description: &'static str = Box::leak(endpoint.description.into_boxed_str());

    let mut subcmd = Command::new(static_func_name).about(static_description);

    // Add arguments for this endpoint
    for arg in &endpoint.args {
        subcmd = add_command_argument(subcmd, arg);
    }

    cmd.subcommand(subcmd)
}

// Adds an argument to a command
fn add_command_argument(cmd: Command, arg: &ApiEndpointArg) -> Command {
    let static_arg_name: &'static str = Box::leak(arg.name.clone().into_boxed_str());
    let static_help: &'static str = Box::leak(
        arg.description
            .as_deref()
            .unwrap_or("")
            .to_string()
            .into_boxed_str(),
    );

    let mut cmd_arg = Arg::new(static_arg_name)
        .long(static_arg_name)
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

// Adds a parameter from a command match
fn add_parameter_from_match(
    params: &mut HashMap<String, String>,
    arg: &ApiEndpointArg,
    static_arg_names: &HashMap<String, &'static str>,
    matches: &ArgMatches,
) {
    let static_arg_name = static_arg_names.get(&arg.name).unwrap();

    if let Some(value) = matches.get_one::<String>(static_arg_name) {
        params.insert(arg.name.clone(), value.clone());
    }
}

// Finds a matching endpoint for the given command
pub fn find_matching_endpoint<'a>(
    endpoints: &'a HashMap<String, ApiEndpoint>,
    command: &str,
) -> Result<(&'a String, &'a ApiEndpoint)> {
    // Find all endpoints that match this command (could be multiple paths with same function)
    let matching_endpoints: Vec<(&String, &ApiEndpoint)> = endpoints
        .iter()
        .filter(|(_, e)| e.function == command)
        .collect();

    if matching_endpoints.is_empty() {
        anyhow::bail!("Unknown command: {}", command);
    }

    // Use the first matching endpoint for simplicity
    Ok(matching_endpoints[0])
}

// Builds request parameters from command arguments
pub fn build_request_parameters(
    endpoint: &ApiEndpoint,
    matches: &ArgMatches,
) -> HashMap<String, String> {
    let mut params = HashMap::new();
    let static_arg_names = create_static_arg_names(&endpoint.args);

    for arg in &endpoint.args {
        add_parameter_from_match(&mut params, arg, &static_arg_names, matches);
    }

    params
}

// Creates a map of argument names to static references
fn create_static_arg_names(args: &[ApiEndpointArg]) -> HashMap<String, &'static str> {
    let mut static_arg_names = HashMap::new();

    for arg in args {
        let static_name: &'static str = Box::leak(arg.name.clone().into_boxed_str());
        static_arg_names.insert(arg.name.clone(), static_name);
    }

    static_arg_names
}

// Builds the API path with path parameters replaced
pub fn build_api_path(
    path: &str,
    endpoint: &ApiEndpoint,
    params: &HashMap<String, String>,
) -> String {
    let mut api_path = path.to_string();
    let mut updated_params = params.clone(); // Clone params for tracking replacements

    for arg in &endpoint.args {
        if let Some(value) = params.get(&arg.name) {
            replace_placeholder_in_path(&mut api_path, &arg.name, value, &mut updated_params);
        }
    }

    api_path
}

// Replaces a placeholder in the API path
fn replace_placeholder_in_path(
    api_path: &mut String,
    arg_name: &str,
    value: &str,
    updated_params: &mut HashMap<String, String>, // For tracking replacements
) {
    let int_placeholder = format!("<int:{}>", arg_name);
    let simple_placeholder = format!("<{}>", arg_name);

    if api_path.contains(&int_placeholder) {
        *api_path = api_path.replace(&int_placeholder, value);
        updated_params.remove(arg_name); // Remove from params since used in path
    } else if api_path.contains(&simple_placeholder) {
        *api_path = api_path.replace(&simple_placeholder, value);
        updated_params.remove(arg_name); // Remove from params since used in path
    }
}
