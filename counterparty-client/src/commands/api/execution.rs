use anyhow::{Context, Result};
use clap::ArgMatches;
use reqwest::Client;
use serde_json::Value;
use std::collections::HashMap;

use crate::config::AppConfig;
use crate::helpers;
use crate::api::endpoints::load_or_fetch_endpoints;
use crate::api::commands::{find_matching_endpoint, build_request_parameters, build_api_path};

// ---- Command Execution ----

// Executes the API command
pub async fn execute_command(config: &AppConfig, matches: &ArgMatches) -> Result<()> {
    // Load endpoints from cache or API
    let endpoints = load_or_fetch_endpoints(config).await?;

    // Get the subcommand and its matches
    if let Some((cmd_name, cmd_matches)) = matches.subcommand() {
        execute_api_command(config, &endpoints, cmd_name, cmd_matches).await?;
    } else {
        println!("Please specify an API command. Use 'api --help' to see available commands.");
    }

    Ok(())
}

// Executes a specific API command
async fn execute_api_command(
    config: &AppConfig,
    endpoints: &HashMap<String, crate::api::models::ApiEndpoint>,
    command: &str,
    matches: &ArgMatches,
) -> Result<()> {
    // Find matching endpoint
    let (path, endpoint) = find_matching_endpoint(endpoints, command)?;

    // Build parameters for the API request
    let params = build_request_parameters(endpoint, matches);

    // Construct API path with parameters
    let api_path = build_api_path(path, endpoint, &params);

    // Execute API request
    let result = perform_api_request(config, &api_path, &params).await?;

    // Output result
    helpers::print_colored_json(&result)?;

    Ok(())
}

// Performs the API request and returns the result
pub async fn perform_api_request(
    config: &AppConfig,
    api_path: &str,
    params: &HashMap<String, String>,
) -> Result<Value> {
    // Get active network API URL
    let api_url = config.get_api_url();
    let full_url = format!("{}{}", api_url, api_path);
    
    // Make the API request
    let client = Client::new();
    let response = send_api_request(&client, &full_url, params).await?;

    let status = response.status();
    let result: Value = response
        .json()
        .await
        .context("Failed to parse API response")?;

    if !status.is_success() {
        eprintln!("API request failed with status: {}", status);
    }

    Ok(result)
}

// Sends an API request
async fn send_api_request(
    client: &Client,
    url: &str,
    params: &HashMap<String, String>,
) -> Result<reqwest::Response> {
    client
        .get(url)
        .query(params)
        .send()
        .await
        .context("Failed to send API request")
}
