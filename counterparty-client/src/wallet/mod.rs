//! Bitcoin wallet module for managing keys, addresses, and transactions.
//!
//! This module provides functionality for:
//! - Key generation and management
//! - Address creation and management
//! - Wallet storage with encryption
//! - Transaction signing
//!
//! Initialize a wallet with [`BitcoinWallet::init`], then add addresses with
//! `add_address` (which returns the address plus, for freshly generated keys,
//! the BIP39 mnemonic to back up) and list them with `list_addresses`.

// Private module structure - not exposed to users
mod key_service;
mod keys;
mod operations;
mod password;
mod storage;
mod types;
mod utils;

// Re-export the main public API
pub use key_service::KeyService;
pub use operations::BitcoinWallet;
pub use storage::WalletStorage;
pub use types::{AddressInfo, WalletError};
