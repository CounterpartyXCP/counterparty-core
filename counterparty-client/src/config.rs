use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::collections::HashMap;

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
        Network::Mainnet
    }
}

// Network-specific configuration
#[derive(Debug, Deserialize, Clone)]
pub struct NetworkConfig {
    pub api_url: String,
    pub endpoints_url: String,
    pub cache_file: PathBuf,
}

#[derive(Debug, Deserialize)]
pub struct AppConfig {
    // Default values for backward compatibility
    #[serde(default)]
    pub api_url: String,
    #[serde(default)]
    pub endpoints_url: String,
    #[serde(default)]
    pub cache_file: PathBuf,
    
    // Network-specific configurations
    #[serde(default)]
    pub network_configs: HashMap<Network, NetworkConfig>,
    
    // Active network, defaults to Mainnet
    #[serde(default)]
    pub network: Network,
}

// Implement methods for AppConfig
impl AppConfig {
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