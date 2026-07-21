use anyhow::{anyhow, Context, Result};
use clap::ArgMatches;
use reqwest::{Client, StatusCode};
use serde_json::Value;
use std::collections::HashMap;

use crate::api::commands::{build_api_path, build_request_parameters, find_matching_endpoint};
use crate::api::endpoints::load_or_fetch_endpoints;
use crate::config::AppConfig;
use crate::helpers;

// ---- Command Execution ----

// Executes the API command
pub async fn execute_command(config: &AppConfig, matches: &ArgMatches) -> Result<()> {
    // Load endpoints from cache or API
    let endpoints = load_or_fetch_endpoints(config).await?;

    // Get the subcommand and its matches
    if let Some((cmd_name, cmd_matches)) = matches.subcommand() {
        execute_api_command(config, &endpoints, cmd_name, cmd_matches).await?;
    } else {
        helpers::print_error(
            "Please specify an API command. Use 'api --help' to see available commands.",
            None,
        );
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

    let spinner = helpers::print_loading(format!("Loading {}", &full_url).as_str());

    // Make the API request
    let client = Client::new();
    let response = send_api_request(&client, &full_url, params).await;

    spinner.stop();

    let response = response?;
    let status = response.status();

    // Read the body as text first so a non-JSON error page yields a helpful
    // message instead of an opaque "expected value at line 1 column 1".
    let body = response
        .text()
        .await
        .with_context(|| format!("Failed to read response body from {}", full_url))?;

    let result = parse_json_body(&body, status, &full_url)?;

    if !status.is_success() {
        helpers::print_error("API request failed with status:", Some(&status.to_string()));
    }

    Ok(result)
}

// Sends an API request, mapping connection/timeout failures to actionable messages.
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
        .map_err(|e| friendly_send_error(e, url))
}

/// Turn a reqwest send failure into a user-friendly, actionable error.
pub fn friendly_send_error(e: reqwest::Error, url: &str) -> anyhow::Error {
    if e.is_connect() {
        anyhow!(
            "Cannot connect to the Counterparty API at {url}. \
             Is the server running and reachable? Check the endpoint in your config or the --mainnet/--signet/--testnet4/--regtest flag."
        )
    } else if e.is_timeout() {
        anyhow!("The request to {url} timed out. The server may be overloaded or unreachable.")
    } else {
        anyhow::Error::new(e).context(format!("Failed to send API request to {url}"))
    }
}

/// Turn an API `error` payload into an actionable error. Currently special-cases
/// the composer's "Insufficient funds for the target amount: <have> < <need>"
/// (both in satoshis of BTC) so the user gets a clear funding message rather than
/// a raw internal string.
pub fn friendly_api_error(error: &Value) -> anyhow::Error {
    let message = match error {
        Value::String(s) => s.clone(),
        other => other.to_string(),
    };

    if let Some((have, need)) = parse_insufficient_funds(&message) {
        return anyhow!(
            "Insufficient BTC to fund this transaction: the source address has {have} satoshis \
             but {need} satoshis are required (including the miner fee). \
             Send more BTC to the address and try again."
        );
    }

    anyhow!("API error: {message}")
}

/// Parse "Insufficient funds for the target amount: <have> < <need>" into
/// (have, need) satoshi amounts. Returns None if the message doesn't match.
fn parse_insufficient_funds(message: &str) -> Option<(u64, u64)> {
    let rest = message.strip_prefix("Insufficient funds for the target amount:")?;
    let (have, need) = rest.split_once('<')?;
    let have = have.trim().parse::<u64>().ok()?;
    let need = need.trim().parse::<u64>().ok()?;
    Some((have, need))
}

/// Parse a response body as JSON, returning a helpful error when the body is
/// not JSON (e.g. an HTML error page, a proxy 502, or an empty body).
pub fn parse_json_body(body: &str, status: StatusCode, url: &str) -> Result<Value> {
    serde_json::from_str::<Value>(body).map_err(|e| {
        let trimmed = body.trim();
        let snippet = if trimmed.is_empty() {
            "<empty response body>".to_string()
        } else {
            let short: String = trimmed.chars().take(200).collect();
            if short.chars().count() < trimmed.chars().count() {
                format!("{short}…")
            } else {
                short
            }
        };
        anyhow!(
            "The Counterparty API at {url} returned a non-JSON response (HTTP {status}): {snippet} \
             (parse error: {e})"
        )
    })
}
