use anyhow::Result;
use clap::{Arg, ArgMatches, Command};
use std::collections::HashMap;
use std::collections::HashSet;

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

    for endpoint in endpoints.values() {
        functions.insert(endpoint.function.clone(), endpoint.clone());
    }

    functions
}

// Adds a subcommand to the API command
fn add_subcommand(cmd: Command, func_name: String, endpoint: ApiEndpoint) -> Command {
    let static_func_name: &'static str = Box::leak(func_name.into_boxed_str());
    let static_description: &'static str = Box::leak(endpoint.description.into_boxed_str());

    let mut subcmd = Command::new(static_func_name).about(static_description);

    // Create a set to track used long names to avoid conflicts
    let mut used_long_names = HashSet::new();

    // Add arguments for this endpoint
    for (idx, arg) in endpoint.args.iter().enumerate() {
        subcmd = add_command_argument(subcmd, arg, idx, static_func_name, &mut used_long_names);
    }

    cmd.subcommand(subcmd)
}

// Adds an argument to a command with unique internal ID to prevent name conflicts
fn add_command_argument(
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
    let internal_id = format!("__api_{}_arg_{}_{}", command_name, idx, &arg.name);
    let static_internal_id: &'static str = Box::leak(internal_id.into_boxed_str());

    // Use original argument name as long flag
    let static_long_flag: &'static str = Box::leak(arg.name.clone().into_boxed_str());

    // Store mapping for later retrieval
    let id_map_key = format!("{}:{}", command_name, static_internal_id);
    crate::commands::wallet::args::ID_ARG_MAP
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
        cmd_arg = cmd_arg.value_name("BOOL").value_parser(
            |s: &str| -> std::result::Result<String, String> {
                let lower = s.to_lowercase();
                match lower.as_str() {
                    "true" | "1" => Ok("true".to_string()),
                    "false" | "0" => Ok("false".to_string()),
                    _ => Err(format!(
                        "Invalid boolean value: {}. Use true/false or 1/0",
                        s
                    )),
                }
            },
        );
    } else {
        cmd_arg = cmd_arg.value_name("VALUE");
    }

    cmd.arg(cmd_arg)
}

// Finds a matching endpoint for the given command.
//
// A function can be served under several routes (e.g. `/addresses/<address>`
// and `/addresses/<address>/options`). `HashMap` iteration order is randomized,
// so we sort deterministically and prefer the most "base" route: fewest path
// segments first, then shortest, then lexicographic. This keeps behavior stable
// across runs instead of silently returning a different route each time.
pub fn find_matching_endpoint<'a>(
    endpoints: &'a HashMap<String, ApiEndpoint>,
    command: &str,
) -> Result<(&'a String, &'a ApiEndpoint)> {
    let mut matching_endpoints: Vec<(&String, &ApiEndpoint)> = endpoints
        .iter()
        .filter(|(_, e)| e.function == command)
        .collect();

    if matching_endpoints.is_empty() {
        anyhow::bail!("Unknown command: {}", command);
    }

    matching_endpoints.sort_by(|(a, _), (b, _)| {
        let segments = |p: &str| p.split('/').filter(|s| !s.is_empty()).count();
        segments(a)
            .cmp(&segments(b))
            .then(a.len().cmp(&b.len()))
            .then(a.as_str().cmp(b.as_str()))
    });

    Ok(matching_endpoints[0])
}

// Builds request parameters from command arguments
pub fn build_request_parameters(
    endpoint: &ApiEndpoint,
    matches: &ArgMatches,
) -> HashMap<String, String> {
    let mut params = HashMap::new();
    let id_map = crate::commands::wallet::args::ID_ARG_MAP.lock().unwrap();

    for arg in &endpoint.args {
        // Try to find the argument by iterating through the id_map
        for (key, original_name) in id_map.iter() {
            if key.starts_with(&format!("{}:", &endpoint.function)) && original_name == &arg.name {
                // Extract the internal ID from the key
                let internal_id = key.split(':').nth(1).unwrap_or("");

                if let Some(value) = matches.get_one::<String>(internal_id) {
                    params.insert(arg.name.clone(), value.clone());
                    break; // Once we find a matching value, break out of the loop
                }
            }
        }
    }

    params
}

// Builds the API path with path parameters substituted, removing those
// parameters from `params` so they are not *also* sent as duplicate query
// parameters.
pub fn build_api_path(
    path: &str,
    endpoint: &ApiEndpoint,
    params: &mut HashMap<String, String>,
) -> String {
    let mut api_path = path.to_string();

    for arg in &endpoint.args {
        if let Some(value) = params.get(&arg.name).cloned() {
            let int_placeholder = format!("<int:{}>", arg.name);
            let simple_placeholder = format!("<{}>", arg.name);

            if api_path.contains(&int_placeholder) {
                api_path = api_path.replace(&int_placeholder, &value);
                params.remove(&arg.name);
            } else if api_path.contains(&simple_placeholder) {
                api_path = api_path.replace(&simple_placeholder, &value);
                params.remove(&arg.name);
            }
        }
    }

    api_path
}

#[cfg(test)]
mod tests {
    use super::*;

    fn arg(name: &str) -> ApiEndpointArg {
        ApiEndpointArg {
            name: name.to_string(),
            required: false,
            arg_type: "string".to_string(),
            description: None,
            default: None,
            members: None,
        }
    }

    fn endpoint(function: &str, args: &[&str]) -> ApiEndpoint {
        ApiEndpoint {
            function: function.to_string(),
            description: String::new(),
            args: args.iter().map(|a| arg(a)).collect(),
        }
    }

    #[test]
    fn build_api_path_substitutes_and_strips_path_params() {
        let ep = endpoint("get_block", &["block_index", "verbose"]);
        let mut params = HashMap::from([
            ("block_index".to_string(), "100000".to_string()),
            ("verbose".to_string(), "true".to_string()),
        ]);
        let path = build_api_path("/v2/blocks/<int:block_index>", &ep, &mut params);
        assert_eq!(path, "/v2/blocks/100000");
        // The path param must be removed so it isn't duplicated in the query.
        assert!(!params.contains_key("block_index"));
        assert_eq!(params.get("verbose").map(String::as_str), Some("true"));
    }

    #[test]
    fn build_api_path_handles_plain_placeholder() {
        let ep = endpoint("get_asset_info", &["asset"]);
        let mut params = HashMap::from([("asset".to_string(), "XCP".to_string())]);
        let path = build_api_path("/v2/assets/<asset>", &ep, &mut params);
        assert_eq!(path, "/v2/assets/XCP");
        assert!(params.is_empty());
    }

    #[test]
    fn find_matching_endpoint_is_deterministic_and_prefers_base_route() {
        let mut endpoints = HashMap::new();
        endpoints.insert(
            "/v2/addresses/<address>/options".to_string(),
            endpoint("get_address", &["address"]),
        );
        endpoints.insert(
            "/v2/addresses/<address>".to_string(),
            endpoint("get_address", &["address"]),
        );
        // Whatever the HashMap order, we always get the base route.
        for _ in 0..10 {
            let (path, _) = find_matching_endpoint(&endpoints, "get_address").unwrap();
            assert_eq!(path, "/v2/addresses/<address>");
        }
    }

    #[test]
    fn find_matching_endpoint_errors_on_unknown() {
        let endpoints: HashMap<String, ApiEndpoint> = HashMap::new();
        assert!(find_matching_endpoint(&endpoints, "nope").is_err());
    }
}
