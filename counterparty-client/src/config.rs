use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;
use dirs::{cache_dir, data_dir};

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
        Network::Mainnet // Default network from config.toml
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
    // Create a new AppConfig with hardcoded default values from config.toml
    pub fn new() -> Self {
        let mut network_configs = HashMap::new();
        
        // Get user cache directory
        let cache_base = cache_dir().unwrap_or_else(|| PathBuf::from(".cache"));
        let app_cache = cache_base.join("counterparty-client");
        
        // Get user data directory
        let data_base = data_dir().unwrap_or_else(|| PathBuf::from(".data"));
        let app_data = data_base.join("counterparty-client");
        
        // Define mainnet config
        let mainnet_config = NetworkConfig {
            api_url: "http://34.86.57.66:4001/".to_string(),
            endpoints_url: "http://34.86.57.66:4001/v2/routes".to_string(),
            cache_file: app_cache.join("mainnet/counterparty-endpoints.json"),
            data_dir: app_data.join("mainnet"),
        };
        
        // Add mainnet config to the network configs
        network_configs.insert(Network::Mainnet, mainnet_config.clone());
        
        // Add testnet4 config from config.toml
        network_configs.insert(Network::Testnet4, NetworkConfig {
            api_url: "https://testnet4.counterparty.io:44000/".to_string(),
            endpoints_url: "https://testnet4.counterparty.io:44000/v2/routes".to_string(),
            cache_file: app_cache.join("testnet4/counterparty-endpoints.json"),
            data_dir: app_data.join("testnet4"),
        });
        
        // Add regtest config from config.toml
        network_configs.insert(Network::Regtest, NetworkConfig {
            api_url: "http://localhost:24000/".to_string(),
            endpoints_url: "http://localhost:24000/v2/routes".to_string(),
            cache_file: app_cache.join("regtest/counterparty-endpoints.json"),
            data_dir: app_data.join("regtest"),
        });
        
        // Use the mainnet values for the root config for backward compatibility
        AppConfig {
            api_url: mainnet_config.api_url.clone(),
            endpoints_url: mainnet_config.endpoints_url.clone(),
            cache_file: mainnet_config.cache_file.clone(),
            data_dir: mainnet_config.data_dir.clone(),
            network_configs,
            network: Network::Mainnet, // Default from config.toml
        }
    }

    // Get the active network config, falling back to default values if not specified
    pub fn get_active_network_config(&self) -> NetworkConfig {
        if let Some(config) = self.network_configs.get(&self.network) {
            return config.clone();
        }

        // Fallback to default values
        NetworkConfig {
            api_url: self.api_url.clone(),
            endpoints_url: self.endpoints_url.clone(),
            cache_file: self.cache_file.clone(),
            data_dir: self.data_dir.clone(),
        }
    }

    // Set the active network
    pub fn set_network(&mut self, network: Network) {
        self.network = network;
    }

    // Get current network's API URL
    pub fn get_api_url(&self) -> String {
        let config = self.get_active_network_config();
        config.api_url
    }

    // Get current network's endpoints URL
    pub fn get_endpoints_url(&self) -> String {
        let config = self.get_active_network_config();
        config.endpoints_url
    }

    // Get current network's cache file
    pub fn get_cache_file(&self) -> PathBuf {
        let config = self.get_active_network_config();
        config.cache_file
    }
    
    // Get current network's data directory
    pub fn get_data_dir(&self) -> PathBuf {
        let config = self.get_active_network_config();
        config.data_dir
    }
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct ApiEndpoint {
    pub function: String,
    pub description: String,
    pub args: Vec<ApiEndpointArg>,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct ApiEndpointArg {
    pub name: String,
    #[serde(default)]
    pub required: bool,
    #[serde(rename = "type")]
    pub arg_type: String,
    #[serde(default)]
    pub description: Option<String>,
    #[serde(default)]
    pub default: Option<serde_json::Value>,
    #[serde(default)]
    pub members: Option<Vec<serde_json::Value>>,
}