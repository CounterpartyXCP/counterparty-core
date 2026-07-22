//! Secure key operations service
//!
//! This module provides a service to securely handle private key operations
//! without exposing the keys in memory for longer than necessary.

use bitcoin::secp256k1::{Secp256k1, SecretKey};
use bitcoin::{Network, PrivateKey, PublicKey};
use secrecy::{ExposeSecret, SecretString};
use std::str::FromStr;

use super::types::{Result, WalletError};

/// Service for secure key operations
pub struct KeyService;

impl KeyService {
    /// Perform signing operations without exposing the private key
    pub fn sign_with_key<F, R>(
        private_key_str: &SecretString,
        network: Network,
        operation: F,
    ) -> Result<R>
    where
        F: FnOnce(&SecretKey, &PublicKey) -> Result<R>,
    {
        // Parse the private key inside this controlled scope
        let mut private_key = PrivateKey::from_str(private_key_str.expose_secret())
            .map_err(|e| WalletError::BitcoinError(format!("Invalid private key: {:?}", e)))?;

        // Re-key to the target network. This only affects WIF encoding, not the
        // secret bytes or the derived public key.
        let mut pk = PrivateKey {
            compressed: private_key.compressed,
            network: network.into(),
            inner: private_key.inner,
        };

        // `PrivateKey::inner` is already a secp256k1 `SecretKey`; use it directly
        // rather than round-tripping through a raw byte buffer.
        let mut secret_key = pk.inner;

        // Get the public key
        let secp = Secp256k1::new();
        let public_key = PublicKey::from_private_key(&secp, &pk);

        // Perform the actual operation, then best-effort wipe *every* stack copy
        // of the secret we made. secp256k1's `SecretKey` is `Copy` and not
        // zeroize-on-drop, so each binding must be erased explicitly (the
        // base58-decode temporaries inside `from_str` remain unreachable here).
        let result = operation(&secret_key, &public_key);
        secret_key.non_secure_erase();
        pk.inner.non_secure_erase();
        private_key.inner.non_secure_erase();

        result
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use bitcoin::secp256k1::{Message, Secp256k1};
    use bitcoin::PrivateKey;

    // Build a deterministic WIF for a fixed 32-byte secret plus its expected
    // compressed public key string.
    fn fixed_wif(network: Network) -> (String, String) {
        let secp = Secp256k1::new();
        let sk = SecretKey::from_slice(&[0x11u8; 32]).unwrap();
        let pk = PrivateKey::new(sk, network);
        let public = PublicKey::from_private_key(&secp, &pk);
        (pk.to_wif(), public.to_string())
    }

    #[test]
    fn sign_with_key_exposes_matching_public_key() {
        let (wif, expected_pub) = fixed_wif(Network::Bitcoin);
        let secret = SecretString::from(wif);

        let got =
            KeyService::sign_with_key(&secret, Network::Bitcoin, |_sk, pk| Ok(pk.to_string()))
                .unwrap();

        assert_eq!(got, expected_pub);
    }

    #[test]
    fn sign_with_key_can_sign_and_verify() {
        let (wif, _) = fixed_wif(Network::Bitcoin);
        let secret = SecretString::from(wif);
        let secp = Secp256k1::new();
        let msg = Message::from_digest_slice(&[7u8; 32]).unwrap();

        let verified = KeyService::sign_with_key(&secret, Network::Bitcoin, |sk, pk| {
            let sig = secp.sign_ecdsa(&msg, sk);
            Ok(secp.verify_ecdsa(&msg, &sig, &pk.inner).is_ok())
        })
        .unwrap();

        assert!(verified);
    }

    #[test]
    fn sign_with_key_rejects_invalid_wif() {
        let secret = SecretString::from("this-is-not-a-wif".to_string());
        let result: Result<()> =
            KeyService::sign_with_key(&secret, Network::Bitcoin, |_sk, _pk| Ok(()));
        assert!(result.is_err());
    }
}
