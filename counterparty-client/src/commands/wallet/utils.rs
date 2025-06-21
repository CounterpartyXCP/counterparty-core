use anyhow::{Context, Result};

use crate::config;
use crate::wallet::BitcoinWallet;

/// Initialize the wallet with the specified network
pub fn init_wallet(config: &config::AppConfig) -> Result<BitcoinWallet> {
    let data_dir = config.get_data_dir();

    // Ensure the directory exists
    std::fs::create_dir_all(&data_dir).context("Failed to create wallet directory")?;

    // Initialize wallet with the specified network
    BitcoinWallet::init(&data_dir, config.network).context("Failed to initialize wallet")
}
