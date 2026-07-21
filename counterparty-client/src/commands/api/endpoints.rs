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
    let client = super::execution::http_client();
    let endpoints_url = config.get_endpoints_url();

    let response_json = fetch_json_response(&client, &endpoints_url).await?;
    parse_endpoints_from_response(response_json)
}

// Fetches and parses a JSON response from a URL
async fn fetch_json_response(client: &Client, url: &str) -> Result<Value> {
    let response = client
        .get(url)
        .send()
        .await
        .map_err(|e| super::execution::friendly_send_error(e, url))?;
    let status = response.status();
    let body = response
        .text()
        .await
        .with_context(|| format!("Failed to read response body from {}", url))?;
    super::execution::parse_json_body(&body, status, url)
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::Network;
    use serde_json::json;

    /// A config whose Regtest network points its endpoints URL at `server` and
    /// its endpoint cache at a fresh file inside `dir`.
    fn config_for(server: &mockito::ServerGuard, dir: &Path) -> AppConfig {
        let mut config = AppConfig::new();
        config.set_network(Network::Regtest);
        let nc = config.network_configs.get_mut(&Network::Regtest).unwrap();
        nc.api_url = server.url();
        nc.endpoints_url = format!("{}/v2/routes", server.url());
        nc.cache_file = dir.join("endpoints.json");
        config
    }

    /// The `{ "result": { ... } }` body the routes endpoint returns.
    fn routes_body() -> serde_json::Value {
        json!({
            "result": {
                "/v2/blocks/<int:block_index>": {
                    "function": "get_block",
                    "description": "Gets a block",
                    "args": [ {"name": "block_index", "type": "integer"} ]
                },
                "/v2/addresses/<address>/compose/send": {
                    "function": "compose_send",
                    "description": "Composes a send",
                    "args": [ {"name": "address", "type": "string"} ]
                }
            }
        })
    }

    #[test]
    fn parse_endpoints_from_response_reads_result_field() {
        let parsed = parse_endpoints_from_response(routes_body()).unwrap();
        assert_eq!(parsed.len(), 2);
        assert_eq!(parsed["/v2/blocks/<int:block_index>"].function, "get_block");
    }

    #[test]
    fn parse_endpoints_from_response_errors_without_result() {
        let err = parse_endpoints_from_response(json!({"nope": 1})).unwrap_err();
        assert!(err.to_string().contains("result"), "got: {err}");
    }

    #[test]
    fn cache_endpoints_then_load_roundtrips() {
        let dir = tempfile::tempdir().unwrap();
        let mut config = AppConfig::new();
        config.set_network(Network::Regtest);
        // Nested path exercises `ensure_cache_directory`'s create_dir_all.
        config
            .network_configs
            .get_mut(&Network::Regtest)
            .unwrap()
            .cache_file = dir.path().join("nested/deeper/endpoints.json");

        let endpoints = parse_endpoints_from_response(routes_body()).unwrap();
        cache_endpoints(&config, &endpoints).unwrap();
        assert!(config.get_cache_file().exists());

        let loaded = load_cached_api_endpoints(&config).unwrap();
        assert_eq!(loaded.len(), 2);
        assert_eq!(
            loaded["/v2/addresses/<address>/compose/send"].function,
            "compose_send"
        );
    }

    #[test]
    fn load_cached_api_endpoints_errors_when_missing() {
        let dir = tempfile::tempdir().unwrap();
        let mut config = AppConfig::new();
        config.set_network(Network::Regtest);
        config
            .network_configs
            .get_mut(&Network::Regtest)
            .unwrap()
            .cache_file = dir.path().join("absent.json");
        assert!(load_cached_api_endpoints(&config).is_err());
    }

    #[tokio::test]
    async fn fetch_api_endpoints_hits_network_and_writes_cache() {
        let dir = tempfile::tempdir().unwrap();
        let mut server = mockito::Server::new_async().await;
        let m = server
            .mock("GET", "/v2/routes")
            .with_status(200)
            .with_header("content-type", "application/json")
            .with_body(routes_body().to_string())
            .create_async()
            .await;

        let config = config_for(&server, dir.path());
        let endpoints = fetch_api_endpoints(&config).await.unwrap();
        m.assert_async().await;

        assert_eq!(endpoints.len(), 2);
        // The fetch also populates the on-disk cache.
        assert!(config.get_cache_file().exists());
    }

    #[tokio::test]
    async fn load_or_fetch_prefers_existing_cache_over_network() {
        let dir = tempfile::tempdir().unwrap();
        let mut server = mockito::Server::new_async().await;
        // If the network were hit, this mock would record a request. It must NOT.
        let m = server
            .mock("GET", "/v2/routes")
            .with_status(200)
            .with_body(routes_body().to_string())
            .expect(0)
            .create_async()
            .await;

        let config = config_for(&server, dir.path());
        // Seed the cache first.
        let endpoints = parse_endpoints_from_response(routes_body()).unwrap();
        cache_endpoints(&config, &endpoints).unwrap();

        let loaded = load_or_fetch_endpoints(&config).await.unwrap();
        assert_eq!(loaded.len(), 2);
        m.assert_async().await;
    }

    #[tokio::test]
    async fn load_or_fetch_falls_back_to_network_on_corrupt_cache() {
        let dir = tempfile::tempdir().unwrap();
        let mut server = mockito::Server::new_async().await;
        let m = server
            .mock("GET", "/v2/routes")
            .with_status(200)
            .with_body(routes_body().to_string())
            .create_async()
            .await;

        let config = config_for(&server, dir.path());
        // Write garbage to the cache file so parsing it fails.
        fs::create_dir_all(config.get_cache_file().parent().unwrap()).unwrap();
        fs::write(config.get_cache_file(), b"not json").unwrap();

        let loaded = load_or_fetch_endpoints(&config).await.unwrap();
        assert_eq!(loaded.len(), 2);
        m.assert_async().await;
    }

    #[tokio::test]
    async fn update_cache_writes_endpoints_file() {
        let dir = tempfile::tempdir().unwrap();
        let mut server = mockito::Server::new_async().await;
        let _m = server
            .mock("GET", "/v2/routes")
            .with_status(200)
            .with_body(routes_body().to_string())
            .create_async()
            .await;

        let config = config_for(&server, dir.path());
        update_cache(&config).await.unwrap();
        assert!(config.get_cache_file().exists());
    }
}
