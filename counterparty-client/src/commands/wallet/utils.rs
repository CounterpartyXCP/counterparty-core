use anyhow::{Context, Result};
use std::path::PathBuf;

use crate::config;
use crate::wallet::BitcoinWallet;

/// Initialize the wallet with the specified network
pub fn init_wallet(data_dir: &PathBuf, network: config::Network) -> Result<BitcoinWallet> {
    // Ensure the directory exists
    std::fs::create_dir_all(data_dir).context("Failed to create wallet directory")?;

    // Initialize wallet with the specified network
    BitcoinWallet::init(data_dir, network).context("Failed to initialize wallet")
}
