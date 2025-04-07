use anyhow::{Context, Result};
use clap::{Arg, ArgAction, ArgMatches, Command};
use reqwest::Client;
use serde_json::Value;
use std::collections::HashMap;
use std::fs;

use crate::config::{ApiEndpoint, AppConfig};

// Fetches endpoint definitions from the API
pub async fn fetch_api_endpoints(config: &AppConfig) -> Result<HashMap<String, ApiEndpoint>> {
    let client = Client::new();
    let endpoints_response = client
        .get(&config.endpoints_url)
        .send()
        .await
        .context("Failed to fetch API endpoints")?;

    // Parse the response, which has a "result" field containing the actual endpoints
    let response_json: Value = endpoints_response
        .json()
        .await
        .context("Failed to parse API response")?;

    // Extract the "result" field
    let endpoints_value = response_json
        .get("result")
        .context("Response missing 'result' field")?;

    // Deserialize the endpoints from the result field
    let endpoints: HashMap<String, ApiEndpoint> =
        serde_json::from_value(endpoints_value.clone())
            .context("Failed to parse API endpoints from result field")?;

    // Cache the endpoints for future use
    if let Some(parent) = config.cache_file.parent() {
        fs::create_dir_all(parent).context("Failed to create cache directory")?;
    }

    fs::write(
        &config.cache_file,
        serde_json::to_string_pretty(&endpoints)?,
    )
    .context("Failed to cache API endpoints")?;

    Ok(endpoints)
}

// Loads endpoints from cache
pub fn load_cached_api_endpoints(config: &AppConfig) -> Result<HashMap<String, ApiEndpoint>> {
    let cache = fs::read_to_string(&config.cache_file).context("Failed to read cache file")?;
    let endpoints: HashMap<String, ApiEndpoint> =
        serde_json::from_str(&cache).context("Failed to parse cached API endpoints")?;
    Ok(endpoints)
}

// Externally accessible function to update the cache
pub async fn update_cache(config: &AppConfig) -> Result<()> {
    fetch_api_endpoints(config).await?;
    Ok(())
}

// Loads endpoints from cache or fetches them if needed
pub async fn load_or_fetch_endpoints(config: &AppConfig) -> Result<HashMap<String, ApiEndpoint>> {
    if config.cache_file.exists() {
        match load_cached_api_endpoints(config) {
            Ok(endpoints) => Ok(endpoints),
            Err(_) => fetch_api_endpoints(config).await,
        }
    } else {
        fetch_api_endpoints(config).await
    }
}

// Builds the API command structure with all subcommands
pub fn build_command(endpoints: &HashMap<String, ApiEndpoint>) -> Command {
    let mut api_cmd = Command::new("api").about("Interact with the Counterparty API");

    // Collect and sort unique function names to avoid duplicate subcommands
    let mut compose_commands = Vec::new();
    let mut get_commands = Vec::new();
    let mut other_commands = Vec::new();

    let mut functions = HashMap::new();
    for (_path, endpoint) in endpoints {
        functions.insert(endpoint.function.clone(), endpoint.clone());
    }

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

    compose_commands.sort_by(|a, b| a.0.cmp(&b.0));
    get_commands.sort_by(|a, b| a.0.cmp(&b.0));
    other_commands.sort_by(|a, b| a.0.cmp(&b.0));

    // Concatenate all commands into a single list
    let mut all_commands = Vec::new();
    all_commands.extend(compose_commands);
    all_commands.extend(get_commands);
    all_commands.extend(other_commands);

    // Process all commands in a single loop
    for (func_name, endpoint) in all_commands {
        let static_func_name: &str = Box::leak(func_name.clone().into_boxed_str());
        let static_description: &str = Box::leak(endpoint.description.clone().into_boxed_str());

        let mut cmd = Command::new(static_func_name).about(static_description);

        // Add arguments for this endpoint
        for arg in &endpoint.args {
            let static_arg_name: &str = Box::leak(arg.name.clone().into_boxed_str());
            let static_help: &str = Box::leak(
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
                cmd_arg = cmd_arg.action(ArgAction::SetTrue);
            } else {
                cmd_arg = cmd_arg.value_name("VALUE");
            }

            cmd = cmd.arg(cmd_arg);
        }

        api_cmd = api_cmd.subcommand(cmd);
    }

    api_cmd
}

// Executes a specific API command
async fn execute_api_command(
    config: &AppConfig,
    endpoints: &HashMap<String, ApiEndpoint>,
    command: &str,
    matches: &ArgMatches,
) -> Result<()> {
    // Find all endpoints that match this command (could be multiple paths with same function)
    let matching_endpoints: Vec<(&String, &ApiEndpoint)> = endpoints
        .iter()
        .filter(|(_, e)| e.function == command)
        .collect();

    if matching_endpoints.is_empty() {
        anyhow::bail!("Unknown command: {}", command);
    }

    // Use the first matching endpoint for simplicity
    let (path, endpoint) = matching_endpoints[0];

    // Build query parameters
    let mut params = HashMap::new();

    // Create a HashMap to store static references to argument names
    let mut static_arg_names = HashMap::new();
    for arg in &endpoint.args {
        let static_name: &str = Box::leak(arg.name.clone().into_boxed_str());
        static_arg_names.insert(arg.name.clone(), static_name);
    }

    for arg in &endpoint.args {
        let static_arg_name = static_arg_names.get(&arg.name).unwrap();

        if arg.arg_type == "bool" {
            if matches.get_flag(static_arg_name) {
                params.insert(arg.name.clone(), "true".to_string());
            }
        } else if let Some(value) = matches.get_one::<String>(static_arg_name) {
            params.insert(arg.name.clone(), value.clone());
        }
    }

    // Construct API path, replacing path parameters
    let mut api_path = path.clone();

    // Try both placeholder formats in the path: <int:name> and <name>
    for arg in &endpoint.args {
        let int_placeholder = format!("<int:{}>", arg.name);
        let simple_placeholder = format!("<{}>", arg.name);

        if let Some(value) = params.get(&arg.name) {
            if api_path.contains(&int_placeholder) {
                api_path = api_path.replace(&int_placeholder, value);
                params.remove(&arg.name);
            } else if api_path.contains(&simple_placeholder) {
                api_path = api_path.replace(&simple_placeholder, value);
                params.remove(&arg.name);
            }
        }
    }

    // Make the API request
    let client = Client::new();
    let response = client
        .get(format!("{}{}", config.api_url, api_path))
        .query(&params)
        .send()
        .await
        .context("Failed to send API request")?;

    let status = response.status();
    let result: Value = response
        .json()
        .await
        .context("Failed to parse API response")?;

    println!("{}", serde_json::to_string_pretty(&result)?);

    if !status.is_success() {
        eprintln!("API request failed with status: {}", status);
    }

    Ok(())
}

// Executes the API command
pub async fn execute_command(config: &AppConfig, matches: &ArgMatches) -> Result<()> {
    // Load endpoints from cache or API
    let endpoints = load_or_fetch_endpoints(config).await?;

    // Get the subcommand and its matches
    if let Some((cmd_name, cmd_matches)) = matches.subcommand() {
        execute_api_command(config, &endpoints, cmd_name, cmd_matches).await?;
    } else {
        // No subcommand provided, print API command help
        println!("Please specify an API command. Use 'api --help' to see available commands.");
    }

    Ok(())
}
