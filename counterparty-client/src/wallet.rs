// Bitcoin Wallet Module
// A simple module to manage Bitcoin addresses, keys and mnemonics.
// This module uses Cocoon for encryption and Bitcoin libraries for key management.

use std::collections::HashMap;
use std::fs::{self, File};
use std::io::{Read, Write};
use std::path::{Path, PathBuf};
use std::str::FromStr;

use bip39::Mnemonic;
use bitcoin::amount::Amount;
use bitcoin::bip32::{DerivationPath, Xpriv};
use bitcoin::key::CompressedPublicKey;
use bitcoin::secp256k1::Secp256k1;
use bitcoin::ScriptBuf;
use bitcoin::{Address, Network, PrivateKey, PublicKey};
use cocoon::Cocoon;
use rand::distributions::Alphanumeric;
use rand::{thread_rng, Rng};
use serde::{Deserialize, Serialize};
use serde_json::{self, json, Value};
use thiserror::Error;

use bitcoin::blockdata::script::{Builder, PushBytesBuf};
use bitcoin::blockdata::transaction::TxOut;
use bitcoin::consensus::{deserialize, serialize};
use bitcoin::psbt::Psbt;
use bitcoin::secp256k1::Message;
use bitcoin::sighash::{EcdsaSighashType, SighashCache};
use bitcoin::TapSighashType;
use bitcoin::Transaction;

// Error types that can occur in wallet operations
#[derive(Error, Debug)]
pub enum WalletError {
    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),

    #[error("JSON error: {0}")]
    JsonError(#[from] serde_json::Error),

    #[error("Encryption error: {0}")]
    CocoonError(String),

    #[error("Bitcoin error: {0}")]
    BitcoinError(String),

    #[error("BIP39 error: {0}")]
    Bip39Error(String),

    #[error("Address not found: {0}")]
    AddressNotFound(String),
}

// Type alias for our result type
type Result<T> = std::result::Result<T, WalletError>;

// Structure to hold wallet address information
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct AddressInfo {
    pub public_key: String,
    pub private_key: String,
    pub mnemonic: Option<String>,
    pub path: Option<String>,
    pub label: String,
    pub address_type: String, // Ajout du type d'adresse (p2pkh, p2wpkh/bech32)
}

// Main wallet structure
#[derive(Debug)]
pub struct BitcoinWallet {
    wallet_file: PathBuf,
    password: String,
    addresses: HashMap<String, AddressInfo>,
}

impl BitcoinWallet {
    /// Initialize a new Bitcoin wallet
    ///
    /// This creates a new wallet or loads an existing one from the specified data directory.
    /// If the wallet doesn't exist, it generates a random password and stores it in a .cookie file.
    ///
    /// # Arguments
    ///
    /// * `data_dir` - Directory where wallet data will be stored
    ///
    /// # Returns
    ///
    /// * `Result<BitcoinWallet>` - New wallet instance or error
    pub fn init<P: AsRef<Path>>(data_dir: P) -> Result<Self> {
        let data_dir = data_dir.as_ref().to_path_buf();

        // Create the data directory if it doesn't exist
        fs::create_dir_all(&data_dir)?;

        let wallet_file = data_dir.join("wallet.db");
        let cookie_file = data_dir.join(".cookie");

        // Get or create password
        let password = if cookie_file.exists() {
            // Read existing password from cookie file
            let mut password_buf = String::new();
            File::open(&cookie_file)?.read_to_string(&mut password_buf)?;
            password_buf
        } else {
            // Generate new random password
            let new_password: String = thread_rng()
                .sample_iter(&Alphanumeric)
                .take(32)
                .map(char::from)
                .collect();

            // Write password to cookie file
            let mut file = File::create(&cookie_file)?;
            file.write_all(new_password.as_bytes())?;

            new_password
        };

        // Initialize or load addresses
        let addresses = if wallet_file.exists() {
            // Vérifier si le fichier de préfixe existe
            let prefix_file = wallet_file.with_extension("prefix");
            if !prefix_file.exists() {
                return Err(WalletError::BitcoinError(
                    "Prefix file not found".to_string(),
                ));
            }

            // Lire le préfixe et les données chiffrées
            let prefix = fs::read(&prefix_file)?;
            let mut encrypted_data = fs::read(&wallet_file)?;

            // Créer un nouveau Cocoon et déchiffrer
            let cocoon = Cocoon::new(password.as_bytes());
            cocoon.decrypt(&mut encrypted_data, &prefix).map_err(|e| {
                WalletError::CocoonError(format!("Failed to decrypt wallet: {:?}", e))
            })?;

            // Convertir en chaîne UTF-8 et parser le JSON
            let json_data = String::from_utf8(encrypted_data).map_err(|_| {
                WalletError::BitcoinError("Invalid UTF-8 in wallet file".to_string())
            })?;

            serde_json::from_str(&json_data)?
        } else {
            HashMap::new()
        };

        Ok(BitcoinWallet {
            wallet_file,
            password,
            addresses,
        })
    }

    /// Saves the wallet to the encrypted file
    fn save(&self) -> Result<()> {
        let json_data = serde_json::to_string(&self.addresses)?;
        let mut cocoon = Cocoon::new(self.password.as_bytes());

        // Convertir les données en vecteur mutable
        let mut data = json_data.into_bytes();

        // Chiffrer les données en place et obtenir le préfixe
        let prefix = cocoon
            .encrypt(&mut data)
            .map_err(|e| WalletError::CocoonError(format!("Failed to encrypt wallet: {:?}", e)))?;

        // Sauvegarder les données chiffrées
        fs::write(&self.wallet_file, &data)?;

        // Sauvegarder le préfixe dans un fichier séparé
        let prefix_file = self.wallet_file.with_extension("prefix");
        fs::write(&prefix_file, prefix)?;

        Ok(())
    }

    /// Add a new address to the wallet
    ///
    /// # Arguments
    ///
    /// * `private_key` - Optional private key as string
    /// * `mnemonic` - Optional mnemonic phrase
    /// * `path` - Optional derivation path
    /// * `label` - Optional label for the address
    /// * `address_type` - Optional address type ("bech32" or "p2pkh")
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
            _ => "bech32", // par défaut, on utilise bech32
        };

        // Generate keys based on provided parameters
        let (secret_key, pub_key, final_mnemonic, final_path) = if let Some(pk_str) = private_key {
            // Use provided private key
            let pk = PrivateKey::from_str(pk_str)
                .map_err(|e| WalletError::BitcoinError(format!("Invalid private key: {}", e)))?;

            let public_key = PublicKey::from_private_key(&secp, &pk);
            (pk, public_key, None, None)
        } else if let Some(mnemonic_str) = mnemonic {
            // Use provided mnemonic
            let mnemonic = Mnemonic::parse_normalized(mnemonic_str)
                .map_err(|e| WalletError::Bip39Error(format!("Invalid mnemonic: {}", e)))?;

            let seed = mnemonic.to_seed("");
            // Utiliser le chemin de dérivation spécifique à l'adresse type
            let derivation_path = match path {
                Some(p) => p,
                None => {
                    if addr_type == "bech32" {
                        // BIP84 pour Bech32/SegWit natif
                        "m/84'/0'/0'/0/0"
                    } else {
                        // BIP44 pour P2PKH
                        "m/44'/0'/0'/0/0"
                    }
                }
            };

            let path = DerivationPath::from_str(derivation_path).map_err(|e| {
                WalletError::BitcoinError(format!("Invalid derivation path: {}", e))
            })?;

            let master_key = Xpriv::new_master(Network::Bitcoin, &seed).map_err(|e| {
                WalletError::BitcoinError(format!("Failed to generate master key: {}", e))
            })?;

            let derived_key = master_key.derive_priv(&secp, &path).map_err(|e| {
                WalletError::BitcoinError(format!("Failed to derive private key: {}", e))
            })?;

            let private_key = PrivateKey {
                compressed: true,
                network: Network::Bitcoin.into(),
                inner: derived_key.to_priv().inner,
            };

            let public_key = PublicKey::from_private_key(&secp, &private_key);

            (
                private_key,
                public_key,
                Some(mnemonic_str.to_string()),
                Some(derivation_path.to_string()),
            )
        } else {
            // Generate new mnemonic and keys
            let mut entropy = [0u8; 16];
            thread_rng().fill(&mut entropy);

            let mnemonic = Mnemonic::from_entropy(&entropy).map_err(|e| {
                WalletError::Bip39Error(format!("Failed to generate mnemonic: {}", e))
            })?;

            let seed = mnemonic.to_seed("");

            // Utiliser le chemin de dérivation approprié en fonction du type d'adresse
            let derivation_path = if addr_type == "bech32" {
                // BIP84 pour Bech32/SegWit natif
                "m/84'/0'/0'/0/0"
            } else {
                // BIP44 pour P2PKH
                "m/44'/0'/0'/0/0"
            };

            let path = DerivationPath::from_str(derivation_path).map_err(|e| {
                WalletError::BitcoinError(format!("Invalid derivation path: {}", e))
            })?;

            let master_key = Xpriv::new_master(Network::Bitcoin, &seed).map_err(|e| {
                WalletError::BitcoinError(format!("Failed to generate master key: {}", e))
            })?;

            let derived_key = master_key.derive_priv(&secp, &path).map_err(|e| {
                WalletError::BitcoinError(format!("Failed to derive private key: {}", e))
            })?;

            let private_key = PrivateKey {
                compressed: true,
                network: Network::Bitcoin.into(),
                inner: derived_key.to_priv().inner,
            };

            let public_key = PublicKey::from_private_key(&secp, &private_key);

            (
                private_key,
                public_key,
                Some(mnemonic.to_string()),
                Some(derivation_path.to_string()),
            )
        };

        // Générer l'adresse Bitcoin selon le type d'adresse demandé
        let address = if addr_type == "bech32" {
            // Créer une adresse Bech32 (P2WPKH)
            // Créer un CompressedPublicKey directement à partir des données brutes
            let compressed_pubkey =
                CompressedPublicKey::from_slice(&pub_key.to_bytes()).map_err(|e| {
                    WalletError::BitcoinError(format!(
                        "Failed to create compressed public key: {}",
                        e
                    ))
                })?;

            // Remarque: p2wpkh ne renvoie plus un Result mais directement une Address
            Address::p2wpkh(&compressed_pubkey, Network::Bitcoin)
        } else {
            // Créer une adresse P2PKH traditionnelle
            Address::p2pkh(&pub_key, Network::Bitcoin)
        };

        let address_str = address.to_string();

        // Create the label
        let final_label = match label {
            Some(l) => l.to_string(),
            None => format!("Address {}", self.addresses.len() + 1),
        };

        // Store the address information
        let address_info = AddressInfo {
            public_key: pub_key.to_string(),
            private_key: secret_key.to_string(),
            mnemonic: final_mnemonic,
            path: final_path,
            label: final_label,
            address_type: addr_type.to_string(), // Stocker le type d'adresse
        };

        self.addresses.insert(address_str.clone(), address_info);
        self.save()?;

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
        // Parse the raw transaction
        let tx_bytes = match hex::decode(raw_tx_hex) {
            Ok(bytes) => bytes,
            Err(e) => {
                return Err(WalletError::BitcoinError(format!(
                    "Invalid transaction hex: {}",
                    e
                )))
            }
        };

        let tx: Transaction = match deserialize(&tx_bytes) {
            Ok(tx) => tx,
            Err(e) => {
                return Err(WalletError::BitcoinError(format!(
                    "Invalid transaction format: {}",
                    e
                )))
            }
        };

        // Validate input count
        if tx.input.len() != utxos.len() {
            return Err(WalletError::BitcoinError(format!(
                "Number of UTXOs ({}) does not match number of inputs ({})",
                utxos.len(),
                tx.input.len()
            )));
        }

        // Create secp256k1 context for signing
        let secp = Secp256k1::new();

        // Create a PSBT from the transaction
        let mut psbt = match Psbt::from_unsigned_tx(tx) {
            Ok(psbt) => psbt,
            Err(e) => {
                return Err(WalletError::BitcoinError(format!(
                    "Failed to create PSBT: {}",
                    e
                )))
            }
        };

        // Add UTXOs to the PSBT inputs
        for (i, (script_hex, amount)) in utxos.iter().enumerate() {
            let script_bytes = match hex::decode(script_hex) {
                Ok(bytes) => bytes,
                Err(e) => {
                    return Err(WalletError::BitcoinError(format!(
                        "Invalid script_pubkey hex at index {}: {}",
                        i, e
                    )))
                }
            };

            let script = ScriptBuf::from_bytes(script_bytes);

            if let Some(input) = psbt.inputs.get_mut(i) {
                // Add witness UTXO with correct amount
                input.witness_utxo = Some(TxOut {
                    value: Amount::from_sat(*amount),
                    script_pubkey: script.clone(),
                });

                // Set sighash type to ALL
                input.sighash_type = Some(TapSighashType::All.into());
            }
        }

        // Track which inputs were signed
        let mut signed_inputs = vec![false; psbt.inputs.len()];

        // Create a SighashCache for computing signature hashes
        let sighash_cache = SighashCache::new(&psbt.unsigned_tx);

        // Try to sign with each key in our wallet
        for (addr_str, info) in &self.addresses {
            let private_key = match PrivateKey::from_str(&info.private_key) {
                Ok(pk) => pk,
                Err(e) => {
                    eprintln!("Invalid private key for {}: {:?}", addr_str, e);
                    continue;
                }
            };

            // Create secret key from the private key
            let secret_key = match bitcoin::secp256k1::SecretKey::from_slice(&private_key.inner[..])
            {
                Ok(sk) => sk,
                Err(e) => {
                    eprintln!("Failed to create secret key for {}: {:?}", addr_str, e);
                    continue;
                }
            };

            // Get the public key
            let public_key = PublicKey::from_private_key(&secp, &private_key);

            // Sign each input one by one
            for i in 0..psbt.inputs.len() {
                if signed_inputs[i] {
                    continue; // Skip already signed inputs
                }

                if let Some(input) = psbt.inputs.get_mut(i) {
                    if let Some(utxo) = &input.witness_utxo {
                        let script_pubkey = &utxo.script_pubkey;

                        // Determine if this key can sign this input
                        let can_sign = match info.address_type.as_str() {
                            "bech32" => {
                                // Check if the script matches a P2WPKH for this key
                                let compressed_pubkey =
                                    bitcoin::key::CompressedPublicKey::from_slice(
                                        &public_key.to_bytes(),
                                    )
                                    .map_err(|e| {
                                        WalletError::BitcoinError(format!(
                                            "Invalid public key: {}",
                                            e
                                        ))
                                    })?;
                                let expected_script =
                                    Address::p2wpkh(&compressed_pubkey, Network::Bitcoin)
                                        .script_pubkey();
                                script_pubkey == &expected_script
                            }
                            "p2pkh" => {
                                // Check if the script matches a P2PKH for this key
                                let expected_script =
                                    Address::p2pkh(&public_key, Network::Bitcoin).script_pubkey();
                                script_pubkey == &expected_script
                            }
                            _ => false,
                        };

                        if can_sign {
                            // Get sighash type
                            let sighash_type = EcdsaSighashType::All;

                            // For P2WPKH, we need to use a P2PKH script for the signature hash
                            let signing_script = if info.address_type == "bech32" {
                                let compressed_pubkey =
                                    bitcoin::key::CompressedPublicKey::from_slice(
                                        &public_key.to_bytes(),
                                    )
                                    .map_err(|e| {
                                        WalletError::BitcoinError(format!(
                                            "Invalid public key: {}",
                                            e
                                        ))
                                    })?;
                                let pubkey_hash = compressed_pubkey.pubkey_hash();
                                ScriptBuf::new_p2pkh(&pubkey_hash)
                            } else {
                                script_pubkey.clone()
                            };

                            // Compute signature hash using legacy method (works for both P2PKH and segwit)
                            let sighash = sighash_cache
                                .legacy_signature_hash(i, &signing_script, sighash_type.to_u32())
                                .map_err(|e| {
                                    WalletError::BitcoinError(format!(
                                        "Failed to compute signature hash: {}",
                                        e
                                    ))
                                })?;

                            // Create a message from the sighash
                            let message =
                                Message::from_digest_slice(&sighash[..]).map_err(|e| {
                                    WalletError::BitcoinError(format!(
                                        "Failed to create message: {}",
                                        e
                                    ))
                                })?;

                            // Sign the message
                            let signature = secp.sign_ecdsa(&message, &secret_key);

                            // Serialize the signature and add sighash type
                            let mut signature_bytes = signature.serialize_der().to_vec();
                            signature_bytes.push(sighash_type as u8);

                            // Convert to PushBytesBuf for script building
                            let sig_push_bytes = PushBytesBuf::try_from(signature_bytes.clone())
                                .map_err(|e| {
                                    WalletError::BitcoinError(format!(
                                        "Failed to convert signature to PushBytesBuf: {:?}",
                                        e
                                    ))
                                })?;

                            let pubkey_bytes = public_key.to_bytes();
                            let pubkey_push_bytes = PushBytesBuf::try_from(pubkey_bytes.clone())
                                .map_err(|e| {
                                    WalletError::BitcoinError(format!(
                                        "Failed to convert pubkey to PushBytesBuf: {:?}",
                                        e
                                    ))
                                })?;

                            // Add the signature to the input
                            if info.address_type == "bech32" {
                                // For P2WPKH, set witness data
                                let mut witness = bitcoin::blockdata::witness::Witness::new();
                                // Here we use the original byte vectors which implement AsRef<[u8]>
                                witness.push(signature_bytes);
                                witness.push(pubkey_bytes);
                                input.final_script_witness = Some(witness);

                                // Empty script_sig for segwit
                                input.final_script_sig = Some(ScriptBuf::new());
                            } else {
                                // For P2PKH, create scriptSig: <signature> <pubkey>
                                let script_sig = Builder::new()
                                    .push_slice(&sig_push_bytes[..])
                                    .push_slice(&pubkey_push_bytes[..])
                                    .into_script();

                                input.final_script_sig = Some(script_sig);
                            }

                            signed_inputs[i] = true;
                        }
                    }
                }
            }
        }

        // Handle P2PK inputs separately (if needed)
        for (i, input) in psbt.inputs.iter_mut().enumerate() {
            if signed_inputs[i] {
                continue; // Skip already signed inputs
            }

            if let Some(witness_utxo) = &input.witness_utxo {
                let script = &witness_utxo.script_pubkey;

                // Check if it's a P2PK script
                if let Some(pubkey_bytes) = self.extract_p2pk_pubkey(script) {
                    if let Ok(pubkey) = PublicKey::from_slice(pubkey_bytes) {
                        // Find matching private key
                        for (_, info) in &self.addresses {
                            let private_key = match PrivateKey::from_str(&info.private_key) {
                                Ok(pk) => pk,
                                Err(_) => continue,
                            };

                            let key_pubkey = PublicKey::from_private_key(&secp, &private_key);

                            if key_pubkey == pubkey {
                                // Found matching key for P2PK input
                                let secret_key = match bitcoin::secp256k1::SecretKey::from_slice(
                                    &private_key.inner[..],
                                ) {
                                    Ok(sk) => sk,
                                    Err(_) => continue,
                                };

                                // Get sighash type
                                let sighash_type = EcdsaSighashType::All;

                                // Compute signature hash
                                let sighash = sighash_cache
                                    .legacy_signature_hash(i, script, sighash_type.to_u32())
                                    .map_err(|e| {
                                        WalletError::BitcoinError(format!(
                                            "Failed to compute P2PK signature hash: {}",
                                            e
                                        ))
                                    })?;

                                // Create message from sighash
                                let message =
                                    Message::from_digest_slice(&sighash[..]).map_err(|e| {
                                        WalletError::BitcoinError(format!(
                                            "Failed to create message: {}",
                                            e
                                        ))
                                    })?;

                                // Sign message
                                let signature = secp.sign_ecdsa(&message, &secret_key);

                                // Serialize signature and add sighash type
                                let mut sig_bytes = signature.serialize_der().to_vec();
                                sig_bytes.push(sighash_type as u8);

                                // Convert to PushBytesBuf
                                let sig_push_bytes =
                                    PushBytesBuf::try_from(sig_bytes).map_err(|e| {
                                        WalletError::BitcoinError(format!(
                                            "Failed to convert signature to PushBytesBuf: {:?}",
                                            e
                                        ))
                                    })?;

                                // Create P2PK scriptSig: <signature>
                                let script_sig =
                                    Builder::new().push_slice(&sig_push_bytes[..]).into_script();

                                input.final_script_sig = Some(script_sig);

                                signed_inputs[i] = true;
                                break;
                            }
                        }
                    }
                }
            }
        }

        // Check if any inputs were signed
        if !signed_inputs.iter().any(|&signed| signed) {
            return Err(WalletError::BitcoinError(
                "No inputs could be signed with keys in this wallet".to_string(),
            ));
        }

        // Check for unsigned inputs
        let unsigned_indices: Vec<usize> = signed_inputs
            .iter()
            .enumerate()
            .filter(|(_, &signed)| !signed)
            .map(|(i, _)| i)
            .collect();

        if !unsigned_indices.is_empty() {
            eprintln!(
                "Warning: Could not sign inputs at indices: {:?}",
                unsigned_indices
            );
        }

        // Extract finalized transaction
        let finalized_tx = match psbt.extract_tx() {
            Ok(tx) => tx,
            Err(e) => {
                return Err(WalletError::BitcoinError(format!(
                    "Failed to extract transaction: {:?}",
                    e
                )))
            }
        };

        // Serialize to hex
        let signed_tx_bytes = serialize(&finalized_tx);
        let signed_tx_hex = hex::encode(signed_tx_bytes);

        Ok(signed_tx_hex)
    }

    /// Extract public key from P2PK script
    fn extract_p2pk_pubkey<'a>(&self, script: &'a ScriptBuf) -> Option<&'a [u8]> {
        use bitcoin::blockdata::opcodes::all;

        let bytes = script.as_bytes();

        // Check for P2PK format
        if bytes.len() >= 2 && bytes[bytes.len() - 1] == all::OP_CHECKSIG.to_u8() {
            if bytes[0] == 0x21 && bytes.len() == 35 {
                // Compressed key (33 bytes)
                return Some(&bytes[1..34]);
            } else if bytes[0] == 0x41 && bytes.len() == 67 {
                // Uncompressed key (65 bytes)
                return Some(&bytes[1..66]);
            }
        }

        None
    }
}
