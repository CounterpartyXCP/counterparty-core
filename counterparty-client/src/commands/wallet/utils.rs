use anyhow::{Context, Result};
use std::path::PathBuf;

use crate::config;
use crate::wallet::BitcoinWallet;

/// Get the wallet data directory
pub fn get_wallet_data_dir() -> PathBuf {
    // Try to get from environment variable first
    if let Ok(dir) = std::env::var("COUNTERPARTY_WALLET_DIR") {
        return PathBuf::from(dir);
    }
    
    // Otherwise use a default path in the user's home directory
    let home = std::env::var("HOME")
        .or_else(|_| std::env::var("USERPROFILE"))
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("."));
    
    home.join(".counterparty").join("wallet")
}

/// Get network name as string
pub fn get_network_name(network: config::Network) -> &'static str {
    match network {
        config::Network::Mainnet => "mainnet",
        config::Network::Testnet4 => "testnet4",
        config::Network::Regtest => "regtest",
    }
}

/// Initialize the wallet with the specified network
pub fn init_wallet(data_dir: &PathBuf, network: config::Network) -> Result<BitcoinWallet> {
    // Ensure the directory exists
    std::fs::create_dir_all(data_dir).context("Failed to create wallet directory")?;
    
    // Initialize wallet with the specified network
    BitcoinWallet::init(data_dir, network).context("Failed to initialize wallet")
}