//! Key generation and management functionality for Bitcoin wallets.
//!
//! This module handles:
//! - Generation of keys from private keys, mnemonics, or randomly
//! - Derivation of key pairs from seeds
//! - Creation of Bitcoin addresses

use bip39::Mnemonic;
use bitcoin::bip32::{DerivationPath, Xpriv};
use bitcoin::key::{CompressedPublicKey, XOnlyPublicKey};
use bitcoin::secp256k1::{All, Secp256k1};
use bitcoin::{Address, Network, PrivateKey, PublicKey};
use rand::{thread_rng, Rng};
use std::str::FromStr;

use super::types::{Result, WalletError};

/// Structure to hold generated key data
#[derive(Debug)]
pub struct KeyData {
    pub private_key: PrivateKey,
    pub public_key: PublicKey,
}

/// Generate key data from an existing private key
pub fn generate_keys_from_private_key(
    pk_str: &str,
    network: Network,
    secp: &Secp256k1<All>,
) -> Result<KeyData> {
    let pk = PrivateKey::from_str(pk_str)
        .map_err(|e| WalletError::BitcoinError(format!("Invalid private key: {}", e)))?;

    // Create a new private key with the correct network
    let pk = PrivateKey {
        compressed: pk.compressed,
        network: network.into(),
        inner: pk.inner,
    };

    let public_key = PublicKey::from_private_key(secp, &pk);

    Ok(KeyData {
        private_key: pk,
        public_key,
    })
}

/// Generate key data from a mnemonic phrase
pub fn generate_keys_from_mnemonic(
    mnemonic_str: &str,
    path_str: Option<&str>,
    addr_type: &str,
    network: Network,
    secp: &Secp256k1<All>,
) -> Result<KeyData> {
    let mnemonic = Mnemonic::parse_normalized(mnemonic_str)
        .map_err(|e| WalletError::Bip39Error(format!("Invalid mnemonic: {}", e)))?;

    let seed = mnemonic.to_seed("");

    // Determine derivation path based on address type
    let derivation_path = get_derivation_path(path_str, addr_type, network);

    let (private_key, public_key) = derive_key_pair(&seed, derivation_path, network, secp)?;

    Ok(KeyData {
        private_key,
        public_key,
    })
}

/// Generate new random key data
pub fn generate_new_keys(
    addr_type: &str,
    network: Network,
    secp: &Secp256k1<All>,
) -> Result<KeyData> {
    let mut entropy = [0u8; 16];
    thread_rng().fill(&mut entropy);

    let mnemonic = Mnemonic::from_entropy(&entropy)
        .map_err(|e| WalletError::Bip39Error(format!("Failed to generate mnemonic: {}", e)))?;

    let seed = mnemonic.to_seed("");

    // Determine derivation path based on address type
    let derivation_path = get_derivation_path(None, addr_type, network);

    let (private_key, public_key) = derive_key_pair(&seed, derivation_path, network, secp)?;

    Ok(KeyData {
        private_key,
        public_key,
    })
}

/// Get the appropriate derivation path based on address type
fn get_derivation_path<'a>(path: Option<&'a str>, addr_type: &'a str, network: Network) -> &'a str {
    match path {
        Some(p) => p,
        None => {
            if addr_type == "taproot" {
                // BIP86 for taproot
                if network == Network::Testnet {
                    // Testnet BIP86 path
                    "m/86'/1'/0'/0/0"
                } else {
                    // Mainnet BIP86 path
                    "m/86'/0'/0'/0/0"
                }
            } else if addr_type == "bech32" {
                // BIP84 for native Bech32/SegWit
                if network == Network::Testnet {
                    // Testnet BIP84 path
                    "m/84'/1'/0'/0/0"
                } else {
                    // Mainnet BIP84 path
                    "m/84'/0'/0'/0/0"
                }
            } else {
                if network == Network::Testnet {
                    // Testnet BIP44 path
                    "m/44'/1'/0'/0/0"
                } else {
                    // Mainnet BIP44 path
                    "m/44'/0'/0'/0/0"
                }
            }
        }
    }
}

/// Derive a key pair from a seed using the specified derivation path
fn derive_key_pair(
    seed: &[u8],
    derivation_path: &str,
    network: Network,
    secp: &Secp256k1<All>,
) -> Result<(PrivateKey, PublicKey)> {
    let path = DerivationPath::from_str(derivation_path)
        .map_err(|e| WalletError::BitcoinError(format!("Invalid derivation path: {}", e)))?;

    let master_key = Xpriv::new_master(network, seed)
        .map_err(|e| WalletError::BitcoinError(format!("Failed to generate master key: {}", e)))?;

    let derived_key = master_key
        .derive_priv(secp, &path)
        .map_err(|e| WalletError::BitcoinError(format!("Failed to derive private key: {}", e)))?;

    let private_key = PrivateKey {
        compressed: true,
        network: network.into(),
        inner: derived_key.to_priv().inner,
    };

    let public_key = PublicKey::from_private_key(secp, &private_key);

    Ok((private_key, public_key))
}

/// Create a Bitcoin address from a public key based on the address type
pub fn create_bitcoin_address(
    pub_key: &PublicKey,
    addr_type: &str,
    network: Network,
) -> Result<Address> {
    if addr_type == "taproot" {
        // Create a taproot address (P2TR)
        // Convert PublicKey to XOnlyPublicKey (taking the x coordinate only)
        let pub_key_bytes = pub_key.to_bytes();
        let x_only_pubkey = XOnlyPublicKey::from_slice(&pub_key_bytes[1..33]).map_err(|e| {
            WalletError::BitcoinError(format!("Failed to create x-only public key: {}", e))
        })?;

        // Create a P2TR address with the key and no script tree (None)
        Ok(Address::p2tr(
            &Secp256k1::new(),
            x_only_pubkey,
            None,
            network,
        ))
    } else if addr_type == "bech32" {
        // Create a Bech32 address (P2WPKH)
        let compressed_pubkey =
            CompressedPublicKey::from_slice(&pub_key.to_bytes()).map_err(|e| {
                WalletError::BitcoinError(format!("Failed to create compressed public key: {}", e))
            })?;

        Ok(Address::p2wpkh(&compressed_pubkey, network))
    } else {
        // Create a traditional P2PKH address
        Ok(Address::p2pkh(pub_key, network))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use bitcoin::secp256k1::Secp256k1;
    use bitcoin::Network;

    // The canonical BIP39 test mnemonic. Combined with the default BIP84/BIP86/
    // BIP44 paths it yields the well-known reference addresses asserted below.
    const MNEMONIC: &str = "abandon abandon abandon abandon abandon abandon \
         abandon abandon abandon abandon abandon about";

    #[test]
    fn mnemonic_derivation_is_deterministic() {
        let secp = Secp256k1::new();
        let a =
            generate_keys_from_mnemonic(MNEMONIC, None, "bech32", Network::Bitcoin, &secp).unwrap();
        let b =
            generate_keys_from_mnemonic(MNEMONIC, None, "bech32", Network::Bitcoin, &secp).unwrap();

        assert_eq!(a.public_key.to_string(), b.public_key.to_string());
        assert_eq!(a.private_key.to_string(), b.private_key.to_string());

        let addr_a = create_bitcoin_address(&a.public_key, "bech32", Network::Bitcoin).unwrap();
        let addr_b = create_bitcoin_address(&b.public_key, "bech32", Network::Bitcoin).unwrap();
        assert_eq!(addr_a.to_string(), addr_b.to_string());
    }

    // Known BIP84 first receive address for the reference mnemonic (m/84'/0'/0'/0/0).
    #[test]
    fn bech32_matches_bip84_reference_vector() {
        let secp = Secp256k1::new();
        let k =
            generate_keys_from_mnemonic(MNEMONIC, None, "bech32", Network::Bitcoin, &secp).unwrap();
        let addr = create_bitcoin_address(&k.public_key, "bech32", Network::Bitcoin).unwrap();
        assert_eq!(
            addr.to_string(),
            "bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu"
        );
    }

    // Known BIP86 first receive address for the reference mnemonic (m/86'/0'/0'/0/0).
    #[test]
    fn taproot_matches_bip86_reference_vector() {
        let secp = Secp256k1::new();
        let k = generate_keys_from_mnemonic(MNEMONIC, None, "taproot", Network::Bitcoin, &secp)
            .unwrap();
        let addr = create_bitcoin_address(&k.public_key, "taproot", Network::Bitcoin).unwrap();
        assert_eq!(
            addr.to_string(),
            "bc1p5cyxnuxmeuwuvkwfem96lqzszd02n6xdcjrs20cac6yqjjwudpxqkedrcr"
        );
    }

    // Each address type produces the right human-readable prefix on mainnet vs
    // regtest.
    #[test]
    fn address_prefixes_per_type_and_network() {
        let secp = Secp256k1::new();
        let k =
            generate_keys_from_mnemonic(MNEMONIC, None, "bech32", Network::Bitcoin, &secp).unwrap();

        // bech32 / P2WPKH
        assert!(
            create_bitcoin_address(&k.public_key, "bech32", Network::Bitcoin)
                .unwrap()
                .to_string()
                .starts_with("bc1q")
        );
        assert!(
            create_bitcoin_address(&k.public_key, "bech32", Network::Regtest)
                .unwrap()
                .to_string()
                .starts_with("bcrt1q")
        );

        // p2pkh
        assert!(
            create_bitcoin_address(&k.public_key, "p2pkh", Network::Bitcoin)
                .unwrap()
                .to_string()
                .starts_with('1')
        );
        let regtest_p2pkh = create_bitcoin_address(&k.public_key, "p2pkh", Network::Regtest)
            .unwrap()
            .to_string();
        assert!(regtest_p2pkh.starts_with('m') || regtest_p2pkh.starts_with('n'));

        // taproot / P2TR
        assert!(
            create_bitcoin_address(&k.public_key, "taproot", Network::Bitcoin)
                .unwrap()
                .to_string()
                .starts_with("bc1p")
        );
        assert!(
            create_bitcoin_address(&k.public_key, "taproot", Network::Regtest)
                .unwrap()
                .to_string()
                .starts_with("bcrt1p")
        );
    }

    // An explicit derivation path overrides the address-type default.
    #[test]
    fn explicit_derivation_path_is_used() {
        let secp = Secp256k1::new();
        let default_path =
            generate_keys_from_mnemonic(MNEMONIC, None, "bech32", Network::Bitcoin, &secp).unwrap();
        let explicit = generate_keys_from_mnemonic(
            MNEMONIC,
            Some("m/84'/0'/0'/0/1"),
            "bech32",
            Network::Bitcoin,
            &secp,
        )
        .unwrap();
        // A different index must yield a different key.
        assert_ne!(
            default_path.public_key.to_string(),
            explicit.public_key.to_string()
        );
    }

    #[test]
    fn invalid_mnemonic_is_rejected() {
        let secp = Secp256k1::new();
        let err = generate_keys_from_mnemonic(
            "not a valid mnemonic phrase at all",
            None,
            "bech32",
            Network::Bitcoin,
            &secp,
        );
        assert!(err.is_err());
    }

    #[test]
    fn generate_new_keys_yields_valid_address() {
        let secp = Secp256k1::new();
        let k = generate_new_keys("bech32", Network::Regtest, &secp).unwrap();
        let addr = create_bitcoin_address(&k.public_key, "bech32", Network::Regtest).unwrap();
        assert!(addr.to_string().starts_with("bcrt1q"));
    }
}
