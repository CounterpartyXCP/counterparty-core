use anyhow::Result;
use clap::{ArgMatches, Command};
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

/// Order two routes serving the same function so the most "base" one wins:
/// fewest path segments, then shortest, then lexicographic. Shared by the
/// CLI-build-time dedup and the execution-time [`find_matching_endpoint`] so
/// both always pick the *same* route for a function.
fn route_preference(a: &str, b: &str) -> std::cmp::Ordering {
    let segments = |p: &str| p.split('/').filter(|s| !s.is_empty()).count();
    segments(a)
        .cmp(&segments(b))
        .then(a.len().cmp(&b.len()))
        .then(a.cmp(b))
}

// Creates a deduplicated map of function names to endpoints.
//
// A function can be served under several routes with *different* argument sets
// (e.g. one route in `ROUTE_CATEGORIES_WITHOUT_VERBOSE` omits `verbose`). The
// CLI arguments for a function are built from whichever route wins here, so it
// must pick the same base route the request is later executed against
// (`find_matching_endpoint`) — otherwise which flags exist for a command would
// flip run-to-run with `HashMap` iteration order.
fn deduplicate_endpoint_functions(
    endpoints: &HashMap<String, ApiEndpoint>,
) -> HashMap<String, ApiEndpoint> {
    let mut chosen: HashMap<String, (&String, &ApiEndpoint)> = HashMap::new();

    for (path, endpoint) in endpoints {
        chosen
            .entry(endpoint.function.clone())
            .and_modify(|(best_path, best_ep)| {
                if route_preference(path, best_path) == std::cmp::Ordering::Less {
                    *best_path = path;
                    *best_ep = endpoint;
                }
            })
            .or_insert((path, endpoint));
    }

    chosen
        .into_iter()
        .map(|(func, (_, endpoint))| (func, endpoint.clone()))
        .collect()
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

/// Render a JSON scalar (string/number/bool) as the string form the API
/// expects, or `None` for null / composite values (which have no CLI default).
pub(crate) fn json_scalar_to_string(value: &serde_json::Value) -> Option<String> {
    match value {
        serde_json::Value::String(s) => Some(s.clone()),
        serde_json::Value::Number(n) => Some(n.to_string()),
        serde_json::Value::Bool(b) => Some(b.to_string()),
        _ => None,
    }
}

/// The comma-separated allowed values for an enum-style argument (`members`),
/// or `None` when the argument has no enumerated members.
pub(crate) fn enum_choices(arg: &ApiEndpointArg) -> Option<String> {
    let members = arg.members.as_ref()?;
    let rendered: Vec<String> = members.iter().filter_map(json_scalar_to_string).collect();
    if rendered.is_empty() {
        None
    } else {
        Some(rendered.join(", "))
    }
}

/// Append `note` to a help string in parentheses, e.g. `... (default: true)`.
pub(crate) fn push_help_note(help: &mut String, note: &str) {
    if help.is_empty() {
        help.push_str(note);
    } else {
        help.push_str(" (");
        help.push_str(note);
        help.push(')');
    }
}

// Adds an argument to a command with a unique internal ID to prevent name
// conflicts, delegating to the shared builder in `wallet::args` (which also
// applies the reserved-name / malformed-name guard).
fn add_command_argument(
    cmd: Command,
    arg: &ApiEndpointArg,
    idx: usize,
    command_name: &str,
    used_long_names: &mut HashSet<String>,
) -> Command {
    let internal_id = format!("__api_{}_arg_{}_{}", command_name, idx, arg.name);
    crate::commands::wallet::args::add_manifest_argument(
        cmd,
        arg,
        internal_id,
        command_name,
        used_long_names,
    )
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

    matching_endpoints.sort_by(|(a, _), (b, _)| route_preference(a, b));

    Ok(matching_endpoints[0])
}

// Builds request parameters from command arguments
pub fn build_request_parameters(
    endpoint: &ApiEndpoint,
    matches: &ArgMatches,
) -> HashMap<String, String> {
    let mut params = HashMap::new();
    let id_map = crate::commands::wallet::args::id_arg_map();

    for arg in &endpoint.args {
        // Try to find the argument by iterating through the id_map
        for (key, original_name) in id_map.iter() {
            if key.starts_with(&format!("{}:", endpoint.function)) && original_name == &arg.name {
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

/// Characters percent-encoded when substituting a value into a URL *path*
/// segment. Real asset names / addresses / hashes are already safe, but a stray
/// `/`, `?`, `#` or `%` in an odd value would otherwise corrupt the path or spill
/// into the query. `<`, `>` and `:` are encoded too so an encoded value can never
/// re-form a `<name>` or `<int:name>` placeholder token and corrupt a *later*
/// substitution pass in [`build_api_path`]. `.`, `-`, `_` (used in subasset
/// longnames) are left intact.
const PATH_SEGMENT: &percent_encoding::AsciiSet = &percent_encoding::CONTROLS
    .add(b'/')
    .add(b'?')
    .add(b'#')
    .add(b'%')
    .add(b' ')
    .add(b'&')
    .add(b'<')
    .add(b'>')
    .add(b':');

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
            let encoded = percent_encoding::utf8_percent_encode(&value, PATH_SEGMENT).to_string();
            let int_placeholder = format!("<int:{}>", arg.name);
            let simple_placeholder = format!("<{}>", arg.name);

            if api_path.contains(&int_placeholder) {
                api_path = api_path.replace(&int_placeholder, &encoded);
                params.remove(&arg.name);
            } else if api_path.contains(&simple_placeholder) {
                api_path = api_path.replace(&simple_placeholder, &encoded);
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

    #[test]
    fn add_subcommand_skips_a_manifest_arg_colliding_with_a_global_flag() {
        // A hostile/corrupted manifest naming an arg `json` (a global flag) must
        // not reach clap, or building the command tree would conflict and brick
        // every invocation. The colliding arg is dropped; the safe one stays.
        let ep = endpoint("compose_send", &["json", "asset"]);
        let cmd = add_subcommand(Command::new("api"), "compose_send".to_string(), ep);
        let sub = cmd
            .get_subcommands()
            .find(|c| c.get_name() == "compose_send")
            .expect("subcommand built");
        let longs: Vec<&str> = sub.get_arguments().filter_map(|a| a.get_long()).collect();
        assert!(
            !longs.contains(&"json"),
            "reserved flag must be skipped: {longs:?}"
        );
        assert!(longs.contains(&"asset"), "valid arg must remain: {longs:?}");
    }

    #[test]
    fn deduplicate_endpoint_functions_collapses_routes_by_function() {
        let mut endpoints = HashMap::new();
        endpoints.insert(
            "/v2/addresses/<address>".to_string(),
            endpoint("get_address", &["address"]),
        );
        endpoints.insert(
            "/v2/addresses/<address>/options".to_string(),
            endpoint("get_address", &["address"]),
        );
        endpoints.insert(
            "/v2/blocks/<int:block_index>".to_string(),
            endpoint("get_block", &["block_index"]),
        );

        let deduped = deduplicate_endpoint_functions(&endpoints);
        // Two distinct functions, despite three routes.
        assert_eq!(deduped.len(), 2);
        assert!(deduped.contains_key("get_address"));
        assert!(deduped.contains_key("get_block"));
    }

    #[test]
    fn deduplicate_endpoint_functions_picks_the_same_base_route_as_execution() {
        // The same function under two routes with *different* arg sets: the base
        // (fewest-segment) route wins the CLI-build here, matching the route
        // `find_matching_endpoint` resolves at execution time — so which flags a
        // command exposes no longer flips with HashMap iteration order. Repeated
        // to shake out any residual order-dependence.
        for _ in 0..20 {
            let mut endpoints = HashMap::new();
            endpoints.insert(
                "/v2/transactions/<tx_hash>/info".to_string(),
                endpoint("info_by_tx_hash", &["tx_hash", "verbose"]),
            );
            endpoints.insert(
                "/v2/bitcoin/transactions/<tx_hash>/info".to_string(),
                endpoint("info_by_tx_hash", &["tx_hash"]),
            );

            let deduped = deduplicate_endpoint_functions(&endpoints);
            let built = &deduped["info_by_tx_hash"];
            let (exec_path, _) = find_matching_endpoint(&endpoints, "info_by_tx_hash").unwrap();
            // The CLI-build route and the execution route agree, and it is the
            // one that carries `verbose`.
            assert_eq!(exec_path, "/v2/transactions/<tx_hash>/info");
            assert!(built.args.iter().any(|a| a.name == "verbose"));
        }
    }

    #[test]
    fn group_endpoints_orders_compose_then_get_then_other_each_sorted() {
        let mut endpoints = HashMap::new();
        endpoints.insert("/a".to_string(), endpoint("get_block", &[]));
        endpoints.insert("/b".to_string(), endpoint("compose_send", &[]));
        endpoints.insert("/c".to_string(), endpoint("unpack", &[]));
        endpoints.insert("/d".to_string(), endpoint("compose_issuance", &[]));
        endpoints.insert("/e".to_string(), endpoint("get_asset", &[]));

        let grouped = group_endpoints_by_type(&endpoints);
        let order: Vec<&str> = grouped.iter().map(|(n, _)| n.as_str()).collect();
        // compose_* (sorted), then get_* (sorted), then other.
        assert_eq!(
            order,
            vec![
                "compose_issuance",
                "compose_send",
                "get_asset",
                "get_block",
                "unpack"
            ]
        );
    }

    #[test]
    fn build_command_creates_api_root_with_all_functions() {
        let mut endpoints = HashMap::new();
        endpoints.insert(
            "/a".to_string(),
            endpoint("compose_send", &["address", "asset"]),
        );
        endpoints.insert("/b".to_string(), endpoint("get_block", &["block_index"]));

        let cmd = build_command(&endpoints);
        assert_eq!(cmd.get_name(), "api");
        let names: Vec<String> = cmd
            .get_subcommands()
            .map(|c| c.get_name().to_string())
            .collect();
        assert!(names.contains(&"compose_send".to_string()));
        assert!(names.contains(&"get_block".to_string()));
    }

    #[test]
    fn build_request_parameters_reads_values_via_id_map() {
        // Build the real command tree (this registers the ID_ARG_MAP entries),
        // then parse and extract parameters the way execution.rs does.
        //
        // `build_request_parameters` scans the *process-global* ID_ARG_MAP for
        // every entry whose key is prefixed by this endpoint's function, and
        // calls `matches.get_one` on each internal id it finds. To keep the test
        // hermetic against other tests that also register `compose_*`/`get_*`
        // functions into that shared map, use a function name unique to this
        // test so only its own (fully-defined) arg ids are ever looked up.
        let ep = endpoint("compose_uniqbrp", &["asset", "quantity"]);
        let mut endpoints = HashMap::new();
        endpoints.insert(
            "/v2/addresses/<address>/compose/uniqbrp".to_string(),
            ep.clone(),
        );

        let cmd = build_command(&endpoints);
        let matches = cmd
            .try_get_matches_from([
                "api",
                "compose_uniqbrp",
                "--asset",
                "XCP",
                "--quantity",
                "100",
            ])
            .unwrap();
        let (_, sub) = matches.subcommand().unwrap();

        let params = build_request_parameters(&ep, sub);
        assert_eq!(params.get("asset").map(String::as_str), Some("XCP"));
        assert_eq!(params.get("quantity").map(String::as_str), Some("100"));
    }

    #[test]
    fn add_command_argument_bool_parser_normalises_and_rejects() {
        let mut used = HashSet::new();
        let cmd = Command::new("get_x");
        let cmd = add_command_argument(
            cmd,
            &ApiEndpointArg {
                name: "verbose".to_string(),
                required: false,
                arg_type: "bool".to_string(),
                description: None,
                default: None,
                members: None,
            },
            0,
            "get_x",
            &mut used,
        );
        // "0" normalises to "false"; "nope" is rejected.
        let ok = cmd
            .clone()
            .try_get_matches_from(["get_x", "--verbose", "0"])
            .unwrap();
        let id = "__api_get_x_arg_0_verbose";
        assert_eq!(ok.get_one::<String>(id).map(String::as_str), Some("false"));
        assert!(cmd
            .clone()
            .try_get_matches_from(["get_x", "--verbose", "nope"])
            .is_err());
    }
}
