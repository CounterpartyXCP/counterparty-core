//! Utility functions for wallet operations.

use crate::config;
use bitcoin::Network;
use std::path::{Path, PathBuf};

/// Convert from app configuration Network to Bitcoin library Network
pub fn to_bitcoin_network(network: config::Network) -> Network {
    match network {
        config::Network::Mainnet => Network::Bitcoin,
        config::Network::Signet => Network::Signet,
        config::Network::Testnet4 => Network::Testnet,
        config::Network::Regtest => Network::Regtest,
    }
}

/// Convert from Bitcoin library Network to string representation
pub fn network_to_string(network: Network) -> &'static str {
    match network {
        Network::Bitcoin => "mainnet",
        Network::Signet => "signet",
        Network::Testnet => "testnet4",
        Network::Regtest => "regtest",
        _ => "unknown",
    }
}

/// Get the network-specific subdirectory path
pub fn get_network_dir(base_dir: &Path, network: config::Network) -> PathBuf {
    match network {
        config::Network::Mainnet => base_dir.join("mainnet"),
        config::Network::Signet => base_dir.join("signet"),
        config::Network::Testnet4 => base_dir.join("testnet4"),
        config::Network::Regtest => base_dir.join("regtest"),
    }
}
