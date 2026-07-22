use dirs::{cache_dir, data_dir};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::{Path, PathBuf};

/// A Bitcoin network the client can target. The default is [`Network::Mainnet`].
#[derive(Debug, Deserialize, Serialize, Clone, Copy, PartialEq, Eq, Hash)]
#[serde(rename_all = "lowercase")]
#[derive(Default)]
pub enum Network {
    /// Bitcoin mainnet.
    #[default]
    Mainnet,
    /// Signet.
    Signet,
    /// Testnet4.
    Testnet4,
    /// Local regtest.
    Regtest,
}

/// Per-network endpoints and on-disk locations.
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct NetworkConfig {
    /// Base Counterparty API URL (e.g. `https://api.counterparty.io:4000`).
    pub api_url: String,
    /// URL of the API's route manifest (`<api_url>/v2/routes`).
    pub endpoints_url: String,
    /// Path of the cached endpoint manifest for this network.
    pub cache_file: PathBuf,
    /// Per-network data directory (holds the encrypted wallet).
    pub data_dir: PathBuf,
}

/// The client's full configuration: per-network endpoints plus the active
/// network. Serialized to `config.toml` on first run.
#[derive(Debug, Deserialize, Serialize)]
pub struct AppConfig {
    /// Fallback API URL used when the active network has no entry.
    #[serde(default)]
    pub api_url: String,
    /// Fallback endpoints URL used when the active network has no entry.
    #[serde(default)]
    pub endpoints_url: String,
    /// Fallback endpoint-cache path.
    #[serde(default)]
    pub cache_file: PathBuf,
    /// Fallback data directory.
    #[serde(default)]
    pub data_dir: PathBuf,

    /// Endpoints/paths for each supported network.
    #[serde(default)]
    pub network_configs: HashMap<Network, NetworkConfig>,

    /// The active network. Defaults to [`Network::Mainnet`].
    #[serde(default)]
    pub network: Network,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self::new()
    }
}

// Implement methods for AppConfig
impl AppConfig {
    /// Build a config with the built-in per-network defaults; the active network
    /// is mainnet.
    pub fn new() -> Self {
        // Get application directories
        let (app_cache, app_data) = Self::get_app_directories();

        // Create network configurations
        let mut network_configs = HashMap::new();

        // Add mainnet config
        let mainnet_config = Self::create_mainnet_config(&app_cache, &app_data);
        network_configs.insert(Network::Mainnet, mainnet_config.clone());

        // Add signet config
        network_configs.insert(
            Network::Signet,
            Self::create_signet_config(&app_cache, &app_data),
        );

        // Add testnet4 config
        network_configs.insert(
            Network::Testnet4,
            Self::create_testnet4_config(&app_cache, &app_data),
        );

        // Add regtest config
        network_configs.insert(
            Network::Regtest,
            Self::create_regtest_config(&app_cache, &app_data),
        );

        // Use mainnet values for the root config (default network)
        AppConfig {
            api_url: mainnet_config.api_url.clone(),
            endpoints_url: mainnet_config.endpoints_url.clone(),
            cache_file: mainnet_config.cache_file.clone(),
            data_dir: mainnet_config.data_dir.clone(),
            network_configs,
            network: Network::Mainnet,
        }
    }

    // Get the application's cache and data directories
    fn get_app_directories() -> (PathBuf, PathBuf) {
        // Get user cache directory
        let cache_base = cache_dir().unwrap_or_else(|| PathBuf::from(".cache"));
        let app_cache = cache_base.join("counterparty-client");

        // Get user data directory
        let data_base = data_dir().unwrap_or_else(|| PathBuf::from(".data"));
        let app_data = data_base.join("counterparty-client");

        (app_cache, app_data)
    }

    // Create mainnet configuration
    fn create_mainnet_config(app_cache: &Path, app_data: &Path) -> NetworkConfig {
        NetworkConfig {
            api_url: "https://api.counterparty.io:4000".to_string(),
            endpoints_url: "https://api.counterparty.io:4000/v2/routes".to_string(),
            cache_file: app_cache.join("mainnet/counterparty-endpoints.json"),
            data_dir: app_data.join("mainnet"),
        }
    }

    // Create signet configuration
    fn create_signet_config(app_cache: &Path, app_data: &Path) -> NetworkConfig {
        NetworkConfig {
            api_url: "https://signet.counterparty.io:34000".to_string(),
            endpoints_url: "https://signet.counterparty.io:34000/v2/routes".to_string(),
            cache_file: app_cache.join("signet/counterparty-endpoints.json"),
            data_dir: app_data.join("signet"),
        }
    }

    // Create testnet4 configuration
    fn create_testnet4_config(app_cache: &Path, app_data: &Path) -> NetworkConfig {
        NetworkConfig {
            api_url: "https://testnet4.counterparty.io:44000".to_string(),
            endpoints_url: "https://testnet4.counterparty.io:44000/v2/routes".to_string(),
            cache_file: app_cache.join("testnet4/counterparty-endpoints.json"),
            data_dir: app_data.join("testnet4"),
        }
    }

    // Create regtest configuration
    fn create_regtest_config(app_cache: &Path, app_data: &Path) -> NetworkConfig {
        NetworkConfig {
            api_url: "http://localhost:24000".to_string(),
            endpoints_url: "http://localhost:24000/v2/routes".to_string(),
            cache_file: app_cache.join("regtest/counterparty-endpoints.json"),
            data_dir: app_data.join("regtest"),
        }
    }

    /// Overlay non-empty values (and every network entry) from a parsed config
    /// file onto `self`, adopting the file's active network.
    pub fn merge_from(&mut self, file_config: AppConfig) {
        // Update root-level configurations if they are non-empty
        if !file_config.api_url.is_empty() {
            self.api_url = file_config.api_url;
        }
        if !file_config.endpoints_url.is_empty() {
            self.endpoints_url = file_config.endpoints_url;
        }
        if file_config.cache_file != PathBuf::new() {
            self.cache_file = file_config.cache_file;
        }
        if file_config.data_dir != PathBuf::new() {
            self.data_dir = file_config.data_dir;
        }

        // Merge network configurations
        for (network, net_config) in file_config.network_configs {
            self.network_configs.insert(network, net_config);
        }

        // Use the network specified in the configuration file
        self.network = file_config.network;
    }

    /// Load configuration from `config_path`, creating it with defaults on first
    /// run, and merge it into `self`.
    ///
    /// A config file that exists but cannot be read or parsed is a hard error:
    /// silently falling back to the built-in (mainnet) defaults could send a
    /// signed transaction to the wrong network.
    pub fn load_from_file(&mut self, config_path: &PathBuf) -> anyhow::Result<()> {
        use anyhow::Context;
        use std::fs;
        use std::io::Write;
        use toml;

        // Check if config file exists, create it if it doesn't
        if !config_path.exists() {
            // Create parent directories if they don't exist
            if let Some(parent) = config_path.parent() {
                fs::create_dir_all(parent)?;
            }

            // Persist the *default* active network, not whatever `--mainnet`/
            // `--signet`/... flag was passed on this first run: the flag still
            // takes effect for this invocation, but a one-off flag must not
            // silently become the stored default for later bare commands.
            let selected_network = self.network;
            self.network = Network::default();
            let config_toml = toml::to_string(self).context("Failed to serialize config to TOML");
            self.network = selected_network;
            let config_toml = config_toml?;

            // Write to the file
            let mut file = fs::File::create(config_path)?;
            file.write_all(config_toml.as_bytes())?;

            return Ok(());
        }

        // Load configuration from the specified file. Read/parse failures are
        // surfaced rather than swallowed: a malformed config must never quietly
        // revert to the mainnet defaults for a tool that signs and broadcasts.
        let contents = fs::read_to_string(config_path)
            .with_context(|| format!("Failed to read config file {}", config_path.display()))?;
        let file_config: AppConfig = toml::from_str(&contents).with_context(|| {
            format!(
                "Config file {} is not valid TOML — fix it or pass --config-file",
                config_path.display()
            )
        })?;
        self.merge_from(file_config);

        Ok(())
    }

    /// The [`NetworkConfig`] for the active network, or the root fallback values
    /// when the active network has no dedicated entry.
    pub fn get_active_network_config(&self) -> NetworkConfig {
        self.network_configs
            .get(&self.network)
            .cloned()
            .unwrap_or_else(|| {
                // Fallback to default values
                NetworkConfig {
                    api_url: self.api_url.clone(),
                    endpoints_url: self.endpoints_url.clone(),
                    cache_file: self.cache_file.clone(),
                    data_dir: self.data_dir.clone(),
                }
            })
    }

    /// Set the active network.
    pub fn set_network(&mut self, network: Network) {
        self.network = network;
    }

    /// The active network's base API URL.
    pub fn get_api_url(&self) -> String {
        self.get_active_network_config().api_url
    }

    /// Whether the active network must use TLS. Every public network requires
    /// `https://`; only local regtest is exempt (it talks to `localhost`). Used
    /// to build an `https_only` HTTP client and to hard-fail a cleartext API URL
    /// before any request is sent.
    pub fn require_https(&self) -> bool {
        self.network != Network::Regtest
    }

    /// The active network's endpoint-manifest URL.
    pub fn get_endpoints_url(&self) -> String {
        self.get_active_network_config().endpoints_url
    }

    /// The active network's endpoint-cache path.
    pub fn get_cache_file(&self) -> PathBuf {
        self.get_active_network_config().cache_file
    }

    /// The active network's data directory.
    pub fn get_data_dir(&self) -> PathBuf {
        self.get_active_network_config().data_dir
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // All four networks are populated by `new()` with the expected HTTPS
    // host-root api_url and `<api_url>/v2/routes` endpoints_url.
    #[test]
    fn new_populates_all_networks() {
        let cfg = AppConfig::new();

        for net in [
            Network::Mainnet,
            Network::Signet,
            Network::Testnet4,
            Network::Regtest,
        ] {
            assert!(
                cfg.network_configs.contains_key(&net),
                "missing network config for {net:?}"
            );
        }

        let m = &cfg.network_configs[&Network::Mainnet];
        assert_eq!(m.api_url, "https://api.counterparty.io:4000");
        assert_eq!(
            m.endpoints_url,
            "https://api.counterparty.io:4000/v2/routes"
        );

        let s = &cfg.network_configs[&Network::Signet];
        assert_eq!(s.api_url, "https://signet.counterparty.io:34000");
        assert_eq!(
            s.endpoints_url,
            "https://signet.counterparty.io:34000/v2/routes"
        );

        let t = &cfg.network_configs[&Network::Testnet4];
        assert_eq!(t.api_url, "https://testnet4.counterparty.io:44000");
        assert_eq!(
            t.endpoints_url,
            "https://testnet4.counterparty.io:44000/v2/routes"
        );

        let r = &cfg.network_configs[&Network::Regtest];
        assert_eq!(r.api_url, "http://localhost:24000");
        assert_eq!(r.endpoints_url, "http://localhost:24000/v2/routes");
    }

    // Each network's endpoints_url is exactly its api_url plus `/v2/routes`.
    #[test]
    fn endpoints_url_is_api_url_plus_v2_routes() {
        let cfg = AppConfig::new();
        for net in [
            Network::Mainnet,
            Network::Signet,
            Network::Testnet4,
            Network::Regtest,
        ] {
            let nc = &cfg.network_configs[&net];
            assert_eq!(nc.endpoints_url, format!("{}/v2/routes", nc.api_url));
        }
    }

    // Default network is Mainnet and the root config mirrors the mainnet config.
    #[test]
    fn default_network_is_mainnet_and_root_mirrors_mainnet() {
        assert_eq!(Network::default(), Network::Mainnet);

        let cfg = AppConfig::new();
        assert_eq!(cfg.network, Network::Mainnet);

        let mainnet = &cfg.network_configs[&Network::Mainnet];
        assert_eq!(cfg.api_url, mainnet.api_url);
        assert_eq!(cfg.endpoints_url, mainnet.endpoints_url);
        assert_eq!(cfg.cache_file, mainnet.cache_file);
        assert_eq!(cfg.data_dir, mainnet.data_dir);
    }

    // `get_api_url`/`get_endpoints_url` follow `set_network`.
    #[test]
    fn get_api_url_switches_per_network() {
        let mut cfg = AppConfig::new();
        assert_eq!(cfg.get_api_url(), "https://api.counterparty.io:4000");

        cfg.set_network(Network::Signet);
        assert_eq!(cfg.get_api_url(), "https://signet.counterparty.io:34000");
        assert_eq!(
            cfg.get_endpoints_url(),
            "https://signet.counterparty.io:34000/v2/routes"
        );

        cfg.set_network(Network::Testnet4);
        assert_eq!(cfg.get_api_url(), "https://testnet4.counterparty.io:44000");

        cfg.set_network(Network::Regtest);
        assert_eq!(cfg.get_api_url(), "http://localhost:24000");
    }

    // `merge_from` overrides only non-empty root fields; `network` is always
    // taken from the incoming (file) config.
    #[test]
    fn merge_from_overrides_only_non_empty_fields() {
        let mut base = AppConfig::new();
        let original_endpoints = base.endpoints_url.clone();
        let original_data_dir = base.data_dir.clone();

        let partial = AppConfig {
            api_url: "https://custom.example:5000".to_string(),
            endpoints_url: String::new(),
            cache_file: PathBuf::new(),
            data_dir: PathBuf::new(),
            network_configs: HashMap::new(),
            network: Network::Regtest,
        };
        base.merge_from(partial);

        // Non-empty api_url overrides.
        assert_eq!(base.api_url, "https://custom.example:5000");
        // Empty fields do NOT override.
        assert_eq!(base.endpoints_url, original_endpoints);
        assert_eq!(base.data_dir, original_data_dir);
        // `network` is taken from the incoming config unconditionally.
        assert_eq!(base.network, Network::Regtest);
        // Empty incoming network_configs leaves the existing ones in place.
        assert_eq!(base.network_configs.len(), 4);
    }

    // `merge_from` inserts/overrides per-network configs supplied by the file.
    #[test]
    fn merge_from_inserts_network_configs() {
        let mut base = AppConfig::new();
        let mut incoming_networks = HashMap::new();
        incoming_networks.insert(
            Network::Regtest,
            NetworkConfig {
                api_url: "http://127.0.0.1:9999".to_string(),
                endpoints_url: "http://127.0.0.1:9999/v2/routes".to_string(),
                cache_file: PathBuf::from("/tmp/cache.json"),
                data_dir: PathBuf::from("/tmp/data"),
            },
        );
        let partial = AppConfig {
            api_url: String::new(),
            endpoints_url: String::new(),
            cache_file: PathBuf::new(),
            data_dir: PathBuf::new(),
            network_configs: incoming_networks,
            network: Network::Regtest,
        };
        base.merge_from(partial);

        assert_eq!(base.get_api_url(), "http://127.0.0.1:9999");
        // The three untouched networks keep their defaults.
        assert_eq!(
            base.network_configs[&Network::Mainnet].api_url,
            "https://api.counterparty.io:4000"
        );
    }

    // `load_from_file` on a missing path writes a TOML file that round-trips
    // back through `try_deserialize` to an equivalent config. Uses a tempdir so
    // the user's real config directory is never touched.
    #[test]
    fn load_from_file_writes_and_roundtrips_toml() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("nested/config.toml");

        let mut cfg = AppConfig::new();
        assert!(!path.exists());
        cfg.load_from_file(&path).unwrap();
        assert!(
            path.exists(),
            "load_from_file should create the config file when missing"
        );

        // Read the written TOML back the same way the app does on start-up.
        let contents = std::fs::read_to_string(&path).unwrap();
        let parsed: AppConfig = toml::from_str(&contents).unwrap();

        assert_eq!(parsed.network, cfg.network);
        assert_eq!(parsed.api_url, cfg.api_url);
        assert_eq!(parsed.endpoints_url, cfg.endpoints_url);

        for net in [
            Network::Mainnet,
            Network::Signet,
            Network::Testnet4,
            Network::Regtest,
        ] {
            let a = &cfg.network_configs[&net];
            let b = parsed
                .network_configs
                .get(&net)
                .unwrap_or_else(|| panic!("network {net:?} missing after round-trip"));
            assert_eq!(a.api_url, b.api_url);
            assert_eq!(a.endpoints_url, b.endpoints_url);
        }
    }

    // A second `load_from_file` call on an existing file merges its values back
    // in (round-trips through the real merge path, not just the writer).
    #[test]
    fn load_from_file_existing_merges_values() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("config.toml");

        // First call writes the default (mainnet) config.
        let mut writer = AppConfig::new();
        writer.load_from_file(&path).unwrap();

        // A fresh config that starts on Regtest should be pulled back to the
        // network stored in the file (Mainnet) after loading it.
        let mut loader = AppConfig::new();
        loader.set_network(Network::Regtest);
        loader.load_from_file(&path).unwrap();
        assert_eq!(loader.network, Network::Mainnet);
    }

    // A one-off `--signet` flag on first run applies to that invocation but must
    // NOT be baked into the persisted config as the new default network.
    #[test]
    fn load_from_file_first_run_persists_default_network_not_flag() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("config.toml");

        let mut cfg = AppConfig::new();
        cfg.set_network(Network::Signet);
        cfg.load_from_file(&path).unwrap();

        // The flag still applies to this run...
        assert_eq!(cfg.network, Network::Signet);
        // ...but the file stores the default (mainnet), so later bare commands
        // don't silently inherit the one-off flag.
        let written: AppConfig = toml::from_str(&std::fs::read_to_string(&path).unwrap()).unwrap();
        assert_eq!(written.network, Network::Mainnet);
    }

    // A config file that exists but is not valid TOML is a hard error, never a
    // silent fall-back to the mainnet defaults.
    #[test]
    fn load_from_file_malformed_toml_is_an_error() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("config.toml");
        std::fs::write(&path, "this = is = not valid = toml ][").unwrap();

        let mut cfg = AppConfig::new();
        let err = cfg.load_from_file(&path).unwrap_err();
        assert!(
            err.to_string().contains("not valid TOML"),
            "expected a TOML parse error, got: {err}"
        );
    }
}
