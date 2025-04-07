// Bitcoin Wallet Module
// A simple module to manage Bitcoin addresses, keys and mnemonics.
// This module uses Cocoon for encryption and Bitcoin libraries for key management.

use std::collections::HashMap;
use std::fs::{self, File};
use std::io::{Read, Write};
use std::path::{Path, PathBuf};
use std::str::FromStr;

use bitcoin::secp256k1::Secp256k1;
use bitcoin::bip32::{DerivationPath, ExtendedPrivKey};
use bitcoin::{Address, Network, PublicKey, PrivateKey};
use bip39::Mnemonic;
use cocoon::Cocoon;
use rand::{thread_rng, Rng};
use rand::distributions::Alphanumeric;
use serde::{Serialize, Deserialize};
use serde_json::{self, json, Value};
use thiserror::Error;


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
                return Err(WalletError::BitcoinError("Prefix file not found".to_string()));
            }
            
            // Lire le préfixe et les données chiffrées
            let prefix = fs::read(&prefix_file)?;
            let mut encrypted_data = fs::read(&wallet_file)?;
            
            // Créer un nouveau Cocoon et déchiffrer
            let cocoon = Cocoon::new(password.as_bytes());
            cocoon.decrypt(&mut encrypted_data, &prefix)
                .map_err(|e| WalletError::CocoonError(format!("Failed to decrypt wallet: {:?}", e)))?;
            
            // Convertir en chaîne UTF-8 et parser le JSON
            let json_data = String::from_utf8(encrypted_data)
                .map_err(|_| WalletError::BitcoinError("Invalid UTF-8 in wallet file".to_string()))?;
            
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
        let prefix = cocoon.encrypt(&mut data)
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
                None => if addr_type == "bech32" {
                    // BIP84 pour Bech32/SegWit natif
                    "m/84'/0'/0'/0/0"
                } else {
                    // BIP44 pour P2PKH
                    "m/44'/0'/0'/0/0"
                }
            };
            
            let path = DerivationPath::from_str(derivation_path)
                .map_err(|e| WalletError::BitcoinError(format!("Invalid derivation path: {}", e)))?;
            
            let master_key = ExtendedPrivKey::new_master(Network::Bitcoin, &seed)
                .map_err(|e| WalletError::BitcoinError(format!("Failed to generate master key: {}", e)))?;
            
            let derived_key = master_key.derive_priv(&secp, &path)
                .map_err(|e| WalletError::BitcoinError(format!("Failed to derive private key: {}", e)))?;
            
            let private_key = PrivateKey {
                compressed: true,
                network: Network::Bitcoin,
                inner: derived_key.private_key,
            };
            
            let public_key = PublicKey::from_private_key(&secp, &private_key);
            
            (private_key, public_key, Some(mnemonic_str.to_string()), Some(derivation_path.to_string()))
        } else {
            // Generate new mnemonic and keys
            let mut entropy = [0u8; 16];
            thread_rng().fill(&mut entropy);
            
            let mnemonic = Mnemonic::from_entropy(&entropy)
                .map_err(|e| WalletError::Bip39Error(format!("Failed to generate mnemonic: {}", e)))?;
                
            let seed = mnemonic.to_seed("");
            
            // Utiliser le chemin de dérivation approprié en fonction du type d'adresse
            let derivation_path = if addr_type == "bech32" {
                // BIP84 pour Bech32/SegWit natif
                "m/84'/0'/0'/0/0"
            } else {
                // BIP44 pour P2PKH
                "m/44'/0'/0'/0/0"
            };
            
            let path = DerivationPath::from_str(derivation_path)
                .map_err(|e| WalletError::BitcoinError(format!("Invalid derivation path: {}", e)))?;
            
            let master_key = ExtendedPrivKey::new_master(Network::Bitcoin, &seed)
                .map_err(|e| WalletError::BitcoinError(format!("Failed to generate master key: {}", e)))?;
            
            let derived_key = master_key.derive_priv(&secp, &path)
                .map_err(|e| WalletError::BitcoinError(format!("Failed to derive private key: {}", e)))?;
            
            let private_key = PrivateKey {
                compressed: true,
                network: Network::Bitcoin,
                inner: derived_key.private_key,
            };
            
            let public_key = PublicKey::from_private_key(&secp, &private_key);
            
            (private_key, public_key, Some(mnemonic.to_string()), Some(derivation_path.to_string()))
        };
        
        // Générer l'adresse Bitcoin selon le type d'adresse demandé
        let address = if addr_type == "bech32" {
            // Créer une adresse Bech32 (P2WPKH)
            Address::p2wpkh(&pub_key, Network::Bitcoin)
                .map_err(|e| WalletError::BitcoinError(format!("Failed to create bech32 address: {}", e)))?
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
        let address_info = self.addresses.get(address)
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
}