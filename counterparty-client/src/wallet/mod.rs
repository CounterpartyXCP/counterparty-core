//! Bitcoin wallet module for managing keys, addresses, and transactions.
//!
//! This module provides functionality for:
//! - Key generation and management
//! - Address creation and management
//! - Wallet storage with encryption
//! - Transaction signing
//!
//! # Examples
//!
//! ```
//! use wallet::BitcoinWallet;
//! use config::Network;
//!
//! // Initialize a wallet with a data directory and network
//! let mut wallet = BitcoinWallet::init("./data", Network::Mainnet).unwrap();
//!
//! // Add a new address
//! let address = wallet.add_address(None, None, None, Some("My Address"), Some("bech32")).unwrap();
//! println!("New address: {}", address);
//!
//! // List addresses
//! let addresses = wallet.list_addresses().unwrap();
//! for addr_info in addresses {
//!     println!("{}: {}", addr_info["label"], addr_info["address"]);
//! }
//! ```

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
pub use types::{AddressInfo, WalletError};
