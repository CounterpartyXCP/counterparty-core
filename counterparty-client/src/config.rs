use dirs::{cache_dir, data_dir};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::{Path, PathBuf};

// Define supported Bitcoin networks
#[derive(Debug, Deserialize, Serialize, Clone, Copy, PartialEq, Eq, Hash)]
#[serde(rename_all = "lowercase")]
#[derive(Default)]
pub enum Network {
    #[default]
    Mainnet,
    Signet,
    Testnet4,
    Regtest,
}

// Default implementation for Network

// Network-specific configuration
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct NetworkConfig {
    pub api_url: String,
    pub endpoints_url: String,
    pub cache_file: PathBuf,
    pub data_dir: PathBuf,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct AppConfig {
    // Default values for backward compatibility
    #[serde(default)]
    pub api_url: String,
    #[serde(default)]
    pub endpoints_url: String,
    #[serde(default)]
    pub cache_file: PathBuf,
    #[serde(default)]
    pub data_dir: PathBuf,

    // Network-specific configurations
    #[serde(default)]
    pub network_configs: HashMap<Network, NetworkConfig>,

    // Active network, defaults to Mainnet (see Network::default)
    #[serde(default)]
    pub network: Network,
}

// Implement methods for AppConfig
impl AppConfig {
    // Create a new AppConfig with default values
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

    // Merge values from another configuration into this one
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

    // Load configuration from file and merge with current config
    pub fn load_from_file(&mut self, config_path: &PathBuf) -> anyhow::Result<()> {
        use ::config::{Config, File};
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

            // Serialize the configuration to TOML
            let config_toml =
                toml::to_string(self).context("Failed to serialize config to TOML")?;

            // Write to the file
            let mut file = fs::File::create(config_path)?;
            file.write_all(config_toml.as_bytes())?;

            return Ok(());
        }

        // Load configuration from the specified file
        let settings_builder = Config::builder().add_source(File::from(config_path.clone()));

        // If configuration can be loaded, update our AppConfig instance
        if let Ok(settings) = settings_builder.build() {
            if let Ok(file_config) = settings.try_deserialize::<AppConfig>() {
                // Update configuration with values from the file
                self.merge_from(file_config);
            }
        }

        Ok(())
    }

    // Get the active network config, falling back to default values if not specified
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

    // Set the active network
    pub fn set_network(&mut self, network: Network) {
        self.network = network;
    }

    // Get current network's API URL
    pub fn get_api_url(&self) -> String {
        self.get_active_network_config().api_url
    }

    // Get current network's endpoints URL
    pub fn get_endpoints_url(&self) -> String {
        self.get_active_network_config().endpoints_url
    }

    // Get current network's cache file
    pub fn get_cache_file(&self) -> PathBuf {
        self.get_active_network_config().cache_file
    }

    // Get current network's data directory
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
        use ::config::{Config, File};
        let settings = Config::builder()
            .add_source(File::from(path.clone()))
            .build()
            .unwrap();
        let parsed: AppConfig = settings.try_deserialize().unwrap();

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
}
