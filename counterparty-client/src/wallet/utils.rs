//! Utility functions for wallet operations.

use crate::config;
use bitcoin::Network;

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
