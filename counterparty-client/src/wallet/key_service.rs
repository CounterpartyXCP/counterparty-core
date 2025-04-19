//! Secure key operations service
//!
//! This module provides a service to securely handle private key operations
//! without exposing the keys in memory for longer than necessary.

use bitcoin::secp256k1::{Secp256k1, SecretKey};
use bitcoin::{Network, PrivateKey, PublicKey};
use secrecy::{Secret, ExposeSecret};
use std::str::FromStr;
use zeroize::Zeroize;

use super::types::{Result, WalletError};

/// Service for secure key operations
pub struct KeyService;

impl KeyService {
    /// Perform signing operations without exposing the private key
    pub fn sign_with_key<F, R>(
        private_key_str: &Secret<String>, 
        network: Network, 
        operation: F
    ) -> Result<R> 
    where 
        F: FnOnce(&SecretKey, &PublicKey) -> Result<R>,
    {
        // Parse the private key inside this controlled scope
        let private_key = PrivateKey::from_str(private_key_str.expose_secret())
            .map_err(|e| WalletError::BitcoinError(format!("Invalid private key: {:?}", e)))?;
        
        // Create a new private key with the correct network
        let pk = PrivateKey {
            compressed: private_key.compressed,
            network: network.into(),
            inner: private_key.inner,
        };
        
        // Convert to rust-bitcoin's SecretKey
        let mut secret_bytes = [0u8; 32];
        secret_bytes.copy_from_slice(&pk.inner[..]);
        let secret_key = SecretKey::from_slice(&secret_bytes)
            .map_err(|e| WalletError::BitcoinError(format!("Invalid secret key: {}", e)))?;

        // Get the public key
        let secp = Secp256k1::new();
        let public_key = PublicKey::from_private_key(&secp, &pk);
        
        // Perform the actual operation
        let result = operation(&secret_key, &public_key)?;
        
        // Clean up secret key material
        secret_bytes.zeroize();
        
        Ok(result)
    }

    /// Get a public key from a private key without exposing it
    pub fn get_public_key(
        private_key_str: &Secret<String>, 
        network: Network
    ) -> Result<PublicKey> {
        let private_key = PrivateKey::from_str(private_key_str.expose_secret())
            .map_err(|e| WalletError::BitcoinError(format!("Invalid private key: {:?}", e)))?;
        
        // Create a new private key with the correct network
        let pk = PrivateKey {
            compressed: private_key.compressed,
            network: network.into(),
            inner: private_key.inner,
        };
        
        // Get the public key
        let secp = Secp256k1::new();
        let public_key = PublicKey::from_private_key(&secp, &pk);
        
        Ok(public_key)
    }
}
