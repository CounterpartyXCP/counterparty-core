//! Wallet operations module.
//!
//! This module handles high-level operations on the wallet:
//! - Adding addresses
//! - Viewing addresses
//! - Listing all addresses
//! - Signing transactions

use bitcoin::secp256k1::Secp256k1;
use bitcoin::Network;
use serde_json::{self, json, Value};
use std::path::Path;
use std::collections::HashMap;

use super::keys::{self, create_bitcoin_address};
use super::storage::WalletStorage;
use super::types::{AddressInfo, AddressMap, Result, WalletError};
use super::utils::{network_to_string, to_bitcoin_network};
use crate::config;
use crate::bitcoinsigner;

/// Main wallet structure for Bitcoin operations
pub struct BitcoinWallet {
    storage: WalletStorage,
    addresses: AddressMap,
    network: Network, // Bitcoin network type
}


pub fn sign_transaction(
    addresses: &HashMap<String, AddressInfo>,
    raw_tx_hex: &str,
    utxos: Vec<(&str, u64)>,
    network: Network,
    envelope_script: Option<&str>,
    source_address: Option<&str>,
) -> Result<String> {
    // Convert legacy utxos format to UTXOList
    let mut utxo_list = bitcoinsigner::UTXOList::new();
    
    for (i, (script_hex, amount)) in utxos.iter().enumerate() {
        // Decode the script from hex
        let script_pubkey = bitcoinsigner::utils::decode_script(script_hex)?;
        
        // Create a basic UTXO
        let mut utxo = bitcoinsigner::UTXO::new(*amount, script_pubkey);
        
        // For the first input, if this is a Taproot reveal transaction
        if i == 0 && envelope_script.is_some() && source_address.is_some() {
            // Get the leaf script from the envelope script
            let leaf_script = bitcoinsigner::utils::decode_script(envelope_script.unwrap())?;
            
            // Set the source address
            utxo.leaf_script = Some(leaf_script);
            utxo.source_address = Some(source_address.unwrap().to_string());
        }
        
        // Add the UTXO to the list
        utxo_list.add(utxo);
    }
    
    // Call the new implementation with the converted parameters
    bitcoinsigner::sign_transaction(addresses, raw_tx_hex, &utxo_list, network)
}

impl BitcoinWallet {
    /// Initialize a new Bitcoin wallet
    ///
    /// This creates a new wallet or loads an existing one from the specified data directory.
    ///
    /// # Arguments
    ///
    /// * `data_dir` - Directory where wallet data will be stored
    /// * `network` - Bitcoin network to use (mainnet, testnet, regtest)
    ///
    /// # Returns
    ///
    /// * `Result<BitcoinWallet>` - New wallet instance or error
    pub fn init<P: AsRef<Path>>(data_dir: P, network: config::Network) -> Result<Self> {
        let (storage, addresses) = WalletStorage::init(data_dir, network)?;

        // Convert config::Network to bitcoin::Network using utility function
        let bitcoin_network = to_bitcoin_network(network);

        Ok(BitcoinWallet {
            storage,
            addresses,
            network: bitcoin_network,
        })
    }

    /// Add a new address to the wallet
    ///
    /// # Arguments
    ///
    /// * `private_key` - Optional private key as string
    /// * `mnemonic` - Optional mnemonic phrase
    /// * `path` - Optional derivation path
    /// * `label` - Optional label for the address
    /// * `address_type` - Optional address type ("bech32", "p2pkh", or "taproot")
    ///
    /// # Returns
    ///
    /// * `Result<String>` - The Bitcoin address created or error
    pub fn add_address(
        &mut self,
        private_key: Option<&str>,
        mnemonic: Option<&str>,
        path: Option<&str>,
        label: Option<&str>,
        address_type: Option<&str>,
    ) -> Result<String> {
        let secp = Secp256k1::new();

        // Determine address type (bech32/p2wpkh by default)
        let addr_type = match address_type {
            Some("p2pkh") => "p2pkh",
            Some("taproot") => "taproot", // Support for taproot addresses
            _ => "bech32", // By default, we use bech32
        };

        // Generate keys based on provided parameters
        let key_data = match (private_key, mnemonic) {
            (Some(pk_str), _) => keys::generate_keys_from_private_key(pk_str, self.network, &secp)?,
            (None, Some(mnemonic_str)) => keys::generate_keys_from_mnemonic(
                mnemonic_str,
                path,
                addr_type,
                self.network,
                &secp,
            )?,
            (None, None) => keys::generate_new_keys(addr_type, self.network, &secp)?,
        };

        // Generate Bitcoin address
        let address = create_bitcoin_address(&key_data.public_key, addr_type, self.network)?;
        let address_str = address.to_string();

        // Create the label
        let final_label = match label {
            Some(l) => l.to_string(),
            None => format!("address{}", self.addresses.len() + 1),
        };

        // Store the address information
        let address_info = AddressInfo {
            public_key: key_data.public_key.to_string(),
            private_key: key_data.private_key.to_string(),
            mnemonic: key_data.mnemonic,
            path: key_data.path,
            label: final_label,
            address_type: addr_type.to_string(),
        };

        self.addresses.insert(address_str.clone(), address_info);
        self.storage.save(&self.addresses)?;

        Ok(address_str)
    }

    /// Show details of a specific address
    ///
    /// # Arguments
    ///
    /// * `address` - The Bitcoin address to show
    /// * `show_private_key` - Whether to include private key and mnemonic in output
    ///
    /// # Returns
    ///
    /// * `Result<Value>` - JSON object with address details or error
    pub fn show_address(&self, address: &str, show_private_key: Option<bool>) -> Result<Value> {
        let show_private_key = show_private_key.unwrap_or(false);
        let address_info = self
            .addresses
            .get(address)
            .ok_or_else(|| WalletError::AddressNotFound(address.to_string()))?;

        let mut result = json!({
            "address": address,
            "public_key": address_info.public_key,
            "label": address_info.label,
            "address_type": address_info.address_type,
            "network": network_to_string(self.network),
        });

        if show_private_key {
            result["private_key"] = json!(address_info.private_key);
            if let Some(ref mnemonic) = address_info.mnemonic {
                result["mnemonic"] = json!(mnemonic);
            }
            if let Some(ref path) = address_info.path {
                result["path"] = json!(path);
            }
        }

        Ok(result)
    }

    /// List all addresses in the wallet
    ///
    /// # Returns
    ///
    /// * `Result<Vec<Value>>` - List of addresses with labels or error
    pub fn list_addresses(&self) -> Result<Vec<Value>> {
        let mut result = Vec::new();

        for (address, info) in &self.addresses {
            result.push(json!({
                "address": address,
                "label": info.label,
                "address_type": info.address_type,
                "network": network_to_string(self.network),
            }));
        }

        Ok(result)
    }

    /// Sign a raw Bitcoin transaction
    ///
    /// This method signs an unsigned transaction with private keys from the wallet.
    /// It supports P2PKH and P2WPKH (bech32) inputs.
    ///
    /// # Arguments
    ///
    /// * `raw_tx_hex` - Unsigned transaction in hexadecimal format
    /// * `utxos` - Vector of (script_pubkey_hex, amount_in_satoshis) pairs for each input
    ///
    /// # Returns
    ///
    /// * `Result<String>` - Signed transaction in hexadecimal format or error
    pub fn sign_transaction(&self, raw_tx_hex: &str, utxos: Vec<(&str, u64)>) -> Result<String> {
        //signer::sign_transaction(&self.addresses, raw_tx_hex, utxos, self.network)
        sign_transaction(
            &self.addresses,
            raw_tx_hex,
            utxos,
            self.network,
            None,
            None,
        )
    }

    /// Sign a reveal transaction (used in certain Bitcoin protocols)
    ///
    /// # Arguments
    ///
    /// * `raw_tx_hex` - Unsigned transaction in hexadecimal format
    /// * `utxos` - Vector of (script_pubkey_hex, amount_in_satoshis) pairs for each input
    /// * `envelope_script` - Optional envelope script
    /// * `source_address` - Optional source address
    ///
    /// # Returns
    ///
    /// * `Result<String>` - Signed transaction in hexadecimal format or error
    pub fn sign_reveal_transaction(
        &self,
        raw_tx_hex: &str,
        utxos: Vec<(&str, u64)>,
        envelope_script: Option<&str>,
        source_address: Option<&str>,
    ) -> Result<String> {
        //signer::sign_reveal_transaction(
        sign_transaction(
            &self.addresses,
            raw_tx_hex,
            utxos,
            self.network,
            envelope_script,
            source_address,
        )
    }

    /// Change the wallet encryption password
    ///
    /// This method changes the password used to encrypt the wallet database.
    /// It will prompt for the current password and then for a new password.
    ///
    /// # Returns
    ///
    /// * `Result<()>` - Success or error
    pub fn change_password(&mut self) -> Result<()> {
        self.storage.change_password(&self.addresses)
    }

    /// Disconnect the wallet by clearing the password
    ///
    /// This method removes the wallet password from the system keyring
    /// and from the in-memory cache, effectively "disconnecting" the wallet.
    ///
    /// # Returns
    ///
    /// * `Result<()>` - Success or error
    pub fn disconnect(&mut self) -> Result<()> {
        self.storage.clear_password()
    }
}