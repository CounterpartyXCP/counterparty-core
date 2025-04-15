use dirs::{cache_dir, data_dir};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;

// Define supported Bitcoin networks
#[derive(Debug, Deserialize, Serialize, Clone, Copy, PartialEq, Eq, Hash)]
#[serde(rename_all = "lowercase")]
pub enum Network {
    Mainnet,
    Testnet4,
    Regtest,
}

// Default implementation for Network
impl Default for Network {
    fn default() -> Self {
        Network::Mainnet // Default network is Mainnet
    }
}

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

    // Active network, defaults to Mainnet
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

        // Use mainnet values for the root config (backward compatibility)
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
    fn create_mainnet_config(app_cache: &PathBuf, app_data: &PathBuf) -> NetworkConfig {
        NetworkConfig {
            api_url: "http://34.86.57.66:4001/".to_string(),
            endpoints_url: "http://34.86.57.66:4001/v2/routes".to_string(),
            cache_file: app_cache.join("mainnet/counterparty-endpoints.json"),
            data_dir: app_data.join("mainnet"),
        }
    }

    // Create testnet4 configuration
    fn create_testnet4_config(app_cache: &PathBuf, app_data: &PathBuf) -> NetworkConfig {
        NetworkConfig {
            api_url: "http://34.48.64.145:44001/".to_string(),
            endpoints_url: "http://34.48.64.145:44001/v2/routes".to_string(),
            cache_file: app_cache.join("testnet4/counterparty-endpoints.json"),
            data_dir: app_data.join("testnet4"),
        }
    }

    // Create regtest configuration
    fn create_regtest_config(app_cache: &PathBuf, app_data: &PathBuf) -> NetworkConfig {
        NetworkConfig {
            api_url: "http://localhost:24000/".to_string(),
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
