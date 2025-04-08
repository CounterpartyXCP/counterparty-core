// keys.rs - Module for managing Bitcoin keys and their derivations

use bip39::Mnemonic;
use bitcoin::bip32::{DerivationPath, Xpriv};
use bitcoin::key::CompressedPublicKey;
use bitcoin::secp256k1::{All, Secp256k1};
use bitcoin::{Address, Network, PrivateKey, PublicKey};
use rand::{thread_rng, Rng};
use std::str::FromStr;

use crate::wallet::WalletError;

// Type alias for our result type
type Result<T> = std::result::Result<T, WalletError>;

// Structure to hold generated key data
#[derive(Debug)]
pub struct KeyData {
    pub private_key: PrivateKey,
    pub public_key: PublicKey,
    pub mnemonic: Option<String>,
    pub path: Option<String>,
}

// Generate key data from an existing private key
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
        mnemonic: None,
        path: None,
    })
}

// Generate key data from a mnemonic phrase
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
    let derivation_path = get_derivation_path(path_str, addr_type);

    let (private_key, public_key) = derive_key_pair(&seed, derivation_path, network, secp)?;

    Ok(KeyData {
        private_key,
        public_key,
        mnemonic: Some(mnemonic_str.to_string()),
        path: Some(derivation_path.to_string()),
    })
}

// Generate new random key data
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
    let derivation_path = get_derivation_path(None, addr_type);

    let (private_key, public_key) = derive_key_pair(&seed, derivation_path, network, secp)?;

    Ok(KeyData {
        private_key,
        public_key,
        mnemonic: Some(mnemonic.to_string()),
        path: Some(derivation_path.to_string()),
    })
}

// Get the appropriate derivation path based on address type
pub fn get_derivation_path<'a>(path: Option<&'a str>, addr_type: &'a str) -> &'a str {
    match path {
        Some(p) => p,
        None => {
            if addr_type == "bech32" {
                // BIP84 for native Bech32/SegWit
                "m/84'/0'/0'/0/0"
            } else {
                // BIP44 for P2PKH
                "m/44'/0'/0'/0/0"
            }
        }
    }
}

// Derive a key pair from a seed using the specified derivation path
pub fn derive_key_pair(
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

// Create a Bitcoin address from a public key based on the address type
pub fn create_bitcoin_address(
    pub_key: &PublicKey,
    addr_type: &str,
    network: Network,
) -> Result<Address> {
    if addr_type == "bech32" {
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
