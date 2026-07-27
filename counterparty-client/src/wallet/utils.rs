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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn config_network_maps_to_bitcoin_network() {
        assert_eq!(
            to_bitcoin_network(config::Network::Mainnet),
            Network::Bitcoin
        );
        assert_eq!(to_bitcoin_network(config::Network::Signet), Network::Signet);
        assert_eq!(
            to_bitcoin_network(config::Network::Testnet4),
            Network::Testnet
        );
        assert_eq!(
            to_bitcoin_network(config::Network::Regtest),
            Network::Regtest
        );
    }

    #[test]
    fn bitcoin_network_maps_to_string() {
        assert_eq!(network_to_string(Network::Bitcoin), "mainnet");
        assert_eq!(network_to_string(Network::Signet), "signet");
        assert_eq!(network_to_string(Network::Testnet), "testnet4");
        assert_eq!(network_to_string(Network::Regtest), "regtest");
    }

    #[test]
    fn roundtrip_config_network_through_both_conversions() {
        for (cfg, expected) in [
            (config::Network::Mainnet, "mainnet"),
            (config::Network::Signet, "signet"),
            (config::Network::Testnet4, "testnet4"),
            (config::Network::Regtest, "regtest"),
        ] {
            assert_eq!(network_to_string(to_bitcoin_network(cfg)), expected);
        }
    }
}
