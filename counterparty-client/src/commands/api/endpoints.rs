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
    let client = super::execution::http_client(config.require_https())?;
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

    let mut endpoints: HashMap<String, ApiEndpoint> =
        serde_json::from_value(endpoints_value.clone())
            .context("Failed to parse API endpoints from result field")?;

    sanitize_endpoint_paths(&mut endpoints);

    Ok(endpoints)
}

/// Drop any route whose path key is not a rooted path (starts with `/`) or that
/// smuggles a scheme/authority (`://`).
///
/// Route keys are appended verbatim to the configured API base URL
/// (`format!("{api_url}{path}")`), so an unrooted key such as
/// `@evil.example/v2/.../compose/send` would parse `api.counterparty.io:4000` as
/// *userinfo* and send the request to `evil.example` (over its own valid TLS
/// cert, satisfying `https_only`). Host selection must always come from config,
/// never from the manifest — and this must hold whether the manifest arrived
/// over the network *or* from the on-disk cache (which is user-writable and thus
/// an attacker-influenced input), so both paths call this.
fn sanitize_endpoint_paths(endpoints: &mut HashMap<String, ApiEndpoint>) {
    let before = endpoints.len();
    endpoints.retain(|path, _| path.starts_with('/') && !path.contains("://"));
    let dropped = before - endpoints.len();
    if dropped > 0 {
        crate::helpers::print_warning(
            &format!(
                "Ignored {dropped} API route(s) with an unexpected path (not starting with '/') in the endpoint manifest."
            ),
            None,
        );
    }
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

    let mut endpoints: HashMap<String, ApiEndpoint> =
        serde_json::from_str(&cache).context("Failed to parse cached API endpoints")?;
    // The cache file is user-writable on disk, so it is an attacker-influenced
    // input. Apply the same path validation the network fetch does, so a
    // poisoned cache entry cannot redirect a request to an attacker host.
    sanitize_endpoint_paths(&mut endpoints);
    Ok(endpoints)
}

// Externally accessible function to update the cache
pub async fn update_cache(config: &AppConfig) -> Result<()> {
    fetch_api_endpoints(config).await?;
    Ok(())
}

/// How long a cached endpoint manifest is considered fresh before a refresh is
/// attempted. Endpoints change rarely, so a day balances staleness against
/// per-startup network calls; `xcp --update-cache` forces an immediate refresh.
const CACHE_TTL: std::time::Duration = std::time::Duration::from_secs(24 * 60 * 60);

/// Whether the cache file's age is within [`CACHE_TTL`]. A missing file, an
/// unreadable mtime, or a clock that moved backwards all count as *not* fresh so
/// the endpoints are refreshed.
fn cache_is_fresh(cache_file: &Path) -> bool {
    let Ok(meta) = fs::metadata(cache_file) else {
        return false;
    };
    let Ok(mtime) = meta.modified() else {
        return false;
    };
    matches!(mtime.elapsed(), Ok(age) if age < CACHE_TTL)
}

// Loads endpoints from cache or fetches them if needed
pub async fn load_or_fetch_endpoints(config: &AppConfig) -> Result<HashMap<String, ApiEndpoint>> {
    let cache_file = config.get_cache_file();

    // Fresh cache: use it, refreshing only if it fails to parse.
    if cache_file.exists() && cache_is_fresh(&cache_file) {
        match load_cached_api_endpoints(config) {
            Ok(endpoints) => return Ok(endpoints),
            Err(_) => return fetch_api_endpoints(config).await,
        }
    }

    // Missing or stale cache: refresh from the API, but fall back to the stale
    // cache when the network is unavailable so the client still works offline.
    match fetch_api_endpoints(config).await {
        Ok(endpoints) => Ok(endpoints),
        Err(fetch_err) => {
            if cache_file.exists() {
                if let Ok(endpoints) = load_cached_api_endpoints(config) {
                    eprintln!(
                        "Note: could not refresh API endpoints ({fetch_err}); using the cached copy."
                    );
                    return Ok(endpoints);
                }
            }
            Err(fetch_err)
        }
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
    fn parse_endpoints_drops_non_rooted_or_scheme_paths() {
        // Route keys are appended to the config base URL, so a poisoned manifest
        // path that is not a rooted `/…` path (or that carries a `://` scheme)
        // must be dropped rather than used to target a surprising URL.
        let body = json!({
            "result": {
                "/v2/blocks": {"function": "get_blocks", "description": "", "args": []},
                "http://evil.example/x": {"function": "evil", "description": "", "args": []},
                "no-leading-slash": {"function": "bad", "description": "", "args": []},
            }
        });
        let parsed = parse_endpoints_from_response(body).unwrap();
        assert!(parsed.contains_key("/v2/blocks"));
        assert!(!parsed.contains_key("http://evil.example/x"));
        assert!(!parsed.contains_key("no-leading-slash"));
        assert_eq!(parsed.len(), 1);
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
    fn load_cached_api_endpoints_drops_poisoned_routes() {
        // A cache file is user-writable on disk. A poisoned entry whose key is
        // not a rooted path (here the `@evil…` userinfo trick) must be dropped on
        // load, exactly as the network-fetch path does — otherwise it could
        // redirect a compose request to an attacker host.
        let dir = tempfile::tempdir().unwrap();
        let mut config = AppConfig::new();
        config.set_network(Network::Regtest);
        config
            .network_configs
            .get_mut(&Network::Regtest)
            .unwrap()
            .cache_file = dir.path().join("endpoints.json");

        let poisoned = json!({
            "/v2/addresses/<address>/compose/send": {
                "function": "compose_send", "description": "", "args": []
            },
            "@evil.example/v2/addresses/<address>/compose/send": {
                "function": "compose_send", "description": "", "args": []
            }
        });
        fs::write(config.get_cache_file(), poisoned.to_string()).unwrap();

        let loaded = load_cached_api_endpoints(&config).unwrap();
        assert!(loaded.contains_key("/v2/addresses/<address>/compose/send"));
        assert!(!loaded.contains_key("@evil.example/v2/addresses/<address>/compose/send"));
        assert_eq!(loaded.len(), 1);
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

    #[test]
    fn cache_is_fresh_for_new_file_and_stale_for_missing() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("endpoints.json");
        fs::write(&path, "{}").unwrap();
        // A file just written is within the TTL.
        assert!(cache_is_fresh(&path));
        // A missing file is never fresh (forces a refresh).
        assert!(!cache_is_fresh(&dir.path().join("absent.json")));
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
