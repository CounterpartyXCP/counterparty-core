use anyhow::{Context, Result};
use reqwest::Client;
use serde_json::Value;
use std::collections::HashMap;
use std::fs;
use std::path::Path;

use crate::api::models::ApiEndpoint;
use crate::config::AppConfig;

// ---- API Endpoint Management ----

// Fetches endpoint definitions from the API
pub async fn fetch_api_endpoints(config: &AppConfig) -> Result<HashMap<String, ApiEndpoint>> {
    let endpoints = fetch_endpoints_from_api(config).await?;
    cache_endpoints(config, &endpoints)?;
    Ok(endpoints)
}

// Retrieves endpoints from the API
async fn fetch_endpoints_from_api(config: &AppConfig) -> Result<HashMap<String, ApiEndpoint>> {
    let client = Client::new();
    let endpoints_url = config.get_endpoints_url();

    let response_json = fetch_json_response(&client, &endpoints_url).await?;
    parse_endpoints_from_response(response_json)
}

// Fetches and parses a JSON response from a URL
async fn fetch_json_response(client: &Client, url: &str) -> Result<Value> {
    client
        .get(url)
        .send()
        .await
        .context("Failed to fetch API endpoints")?
        .json()
        .await
        .context("Failed to parse API response")
}

// Parses endpoints from a JSON response
fn parse_endpoints_from_response(response: Value) -> Result<HashMap<String, ApiEndpoint>> {
    let endpoints_value = response
        .get("result")
        .context("Response missing 'result' field")?;

    serde_json::from_value(endpoints_value.clone())
        .context("Failed to parse API endpoints from result field")
}

// Saves endpoints to cache file
fn cache_endpoints(config: &AppConfig, endpoints: &HashMap<String, ApiEndpoint>) -> Result<()> {
    let cache_file = config.get_cache_file();
    ensure_cache_directory(&cache_file)?;

    fs::write(&cache_file, serde_json::to_string_pretty(&endpoints)?)
        .context("Failed to cache API endpoints")
}

// Ensures cache directory exists
fn ensure_cache_directory(cache_file: &Path) -> Result<()> {
    if let Some(parent) = cache_file.parent() {
        fs::create_dir_all(parent).context("Failed to create cache directory")?;
    }
    Ok(())
}

// Loads endpoints from cache
pub fn load_cached_api_endpoints(config: &AppConfig) -> Result<HashMap<String, ApiEndpoint>> {
    let cache_file = config.get_cache_file();
    let cache = fs::read_to_string(&cache_file).context("Failed to read cache file")?;

    serde_json::from_str(&cache).context("Failed to parse cached API endpoints")
}

// Externally accessible function to update the cache
pub async fn update_cache(config: &AppConfig) -> Result<()> {
    fetch_api_endpoints(config).await?;
    Ok(())
}

// Loads endpoints from cache or fetches them if needed
pub async fn load_or_fetch_endpoints(config: &AppConfig) -> Result<HashMap<String, ApiEndpoint>> {
    let cache_file = config.get_cache_file();

    if cache_file.exists() {
        match load_cached_api_endpoints(config) {
            Ok(endpoints) => Ok(endpoints),
            Err(_) => fetch_api_endpoints(config).await,
        }
    } else {
        fetch_api_endpoints(config).await
    }
}
