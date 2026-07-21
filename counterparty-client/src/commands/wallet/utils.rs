use anyhow::{Context, Result};

use crate::config;
use crate::wallet::{BitcoinWallet, WalletStorage};

/// Initialize the wallet with the specified network
pub fn init_wallet(config: &config::AppConfig) -> Result<BitcoinWallet> {
    let data_dir = config.get_data_dir();

    // Ensure the directory exists
    std::fs::create_dir_all(&data_dir).context("Failed to create wallet directory")?;

    // Initialize wallet with the specified network
    BitcoinWallet::init(&data_dir, config.network).context("Failed to initialize wallet")
}

/// Clear the wallet's stored password WITHOUT loading (or decrypting) the
/// wallet. `disconnect` must always work — even if the keyring somehow holds a
/// stale password — so it deliberately bypasses `init_wallet`.
pub fn disconnect_wallet(config: &config::AppConfig) -> Result<()> {
    let data_dir = config.get_data_dir();
    WalletStorage::clear_password_for(&data_dir, config.network)
        .context("Failed to clear wallet password")
}
