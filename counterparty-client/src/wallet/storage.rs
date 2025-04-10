//! Wallet storage functionality.
//!
//! This module handles:
//! - Loading and saving wallet data
//! - Encryption and decryption of wallet files
//! - Managing wallet file paths
//! - Secure password management via the password agent

use std::fs;
use std::io::{self, Write};
use std::path::{Path, PathBuf};

use cocoon::Cocoon;
use serde_json;

use super::agent::PasswordAgent;
use super::types::{AddressMap, Result, WalletError};
use super::utils::get_network_dir;
use crate::config;

/// Handles wallet storage operations
pub struct WalletStorage {
    wallet_file: PathBuf,
    password_agent: PasswordAgent,
}

impl WalletStorage {
    /// Initialize wallet storage
    ///
    /// This creates a new wallet storage or loads an existing one from the specified data directory.
    /// The system automatically manages password storage using an in-memory agent that is started
    /// transparently when needed.
    ///
    /// # Arguments
    ///
    /// * `data_dir` - Directory where wallet data will be stored
    /// * `network` - Bitcoin network to use (mainnet, testnet, regtest)
    ///
    /// # Returns
    ///
    /// * `Result<(WalletStorage, AddressMap)>` - Storage instance and loaded addresses, or error
    pub fn init<P: AsRef<Path>>(
        data_dir: P,
        network: config::Network,
    ) -> Result<(Self, AddressMap)> {
        let data_dir = data_dir.as_ref().to_path_buf();

        // Create network-specific subdirectory using utility function
        let network_dir = get_network_dir(&data_dir, network);

        // Create the data directory if it doesn't exist
        fs::create_dir_all(&network_dir)?;

        let wallet_file = network_dir.join("wallet.db");
        
        // Create password agent
        let mut password_agent = PasswordAgent::new(&data_dir, network)?;
        
        // Initialize password agent (10 minute timeout by default)
        // Added debugging to see if agent initialization completes successfully
        println!("Starting password agent...");
        match password_agent.start(None) {
            Ok(_) => println!("Password agent started successfully"),
            Err(e) => {
                eprintln!("Failed to start password agent: {:?}", e);
                return Err(e);
            }
        }
        
        let wallet_exists = wallet_file.exists();
        println!("Wallet exists: {}", wallet_exists);
        
        // Get or set password
        let password = if wallet_exists {
            // Try to get the password from the agent
            match password_agent.get_password() {
                Ok(pw) => {
                    println!("Retrieved password from agent");
                    pw
                },
                Err(e) => {
                    // Agent doesn't have the password, prompt the user
                    println!("Need to prompt for password: {:?}", e);
                    let pw = prompt_password("Enter wallet password: ")?;
                    // Store password in agent for future use
                    if let Err(e) = password_agent.store_password(&pw) {
                        eprintln!("Warning: Failed to store password in agent: {:?}", e);
                    } else {
                        println!("Password stored in agent");
                    }
                    pw
                }
            }
        } else {
            // New wallet, prompt for a new password and confirmation
            println!("Creating new wallet, prompting for password");
            let pw = prompt_new_password()?;
            // Store password in agent for future use
            if let Err(e) = password_agent.store_password(&pw) {
                eprintln!("Warning: Failed to store password in agent: {:?}", e);
            } else {
                println!("New password stored in agent");
            }
            pw
        };

        // Initialize or load addresses
        let addresses = if wallet_exists {
            println!("Loading wallet addresses from file");
            Self::load_addresses(&wallet_file, &password)?
        } else {
            println!("Initializing new address map");
            AddressMap::new()
        };

        let storage = WalletStorage {
            wallet_file,
            password_agent,
        };

        Ok((storage, addresses))
    }

    /// Load addresses from encrypted wallet file
    fn load_addresses(wallet_file: &Path, password: &str) -> Result<AddressMap> {
        // Check if prefix file exists
        let prefix_file = wallet_file.with_extension("prefix");
        if !prefix_file.exists() {
            return Err(WalletError::BitcoinError(
                "Prefix file not found".to_string(),
            ));
        }

        // Read prefix and encrypted data
        let prefix = fs::read(&prefix_file)?;
        let mut encrypted_data = fs::read(wallet_file)?;

        // Create a new Cocoon and decrypt
        let cocoon = Cocoon::new(password.as_bytes());
        cocoon
            .decrypt(&mut encrypted_data, &prefix)
            .map_err(|e| WalletError::CocoonError(format!("Failed to decrypt wallet: {:?}", e)))?;

        // Convert to UTF-8 string and parse JSON
        let json_data = String::from_utf8(encrypted_data)
            .map_err(|_| WalletError::BitcoinError("Invalid UTF-8 in wallet file".to_string()))?;

        Ok(serde_json::from_str(&json_data)?)
    }

    /// Saves the wallet addresses to the encrypted file
    ///
    /// # Arguments
    ///
    /// * `addresses` - Address map to save
    ///
    /// # Returns
    ///
    /// * `Result<()>` - Success or error
    pub fn save(&self, addresses: &AddressMap) -> Result<()> {
        // Get the password from the agent
        println!("Attempting to get password from agent");
        let password = self.password_agent.get_password()?;
        println!("Successfully retrieved password from agent");
        
        let json_data = serde_json::to_string(addresses)?;
        let mut cocoon = Cocoon::new(password.as_bytes());

        // Convert data to mutable vector
        let mut data = json_data.into_bytes();

        // Encrypt data in place and get the prefix
        let prefix = cocoon
            .encrypt(&mut data)
            .map_err(|e| WalletError::CocoonError(format!("Failed to encrypt wallet: {:?}", e)))?;

        // Save encrypted data
        fs::write(&self.wallet_file, &data)?;

        // Save prefix in a separate file
        let prefix_file = self.wallet_file.with_extension("prefix");
        fs::write(&prefix_file, prefix)?;

        println!("Wallet data saved successfully");
        Ok(())
    }
    
    /// Change the wallet password
    ///
    /// # Arguments
    ///
    /// * `addresses` - Current address map (needed to re-encrypt the wallet)
    ///
    /// # Returns
    ///
    /// * `Result<()>` - Success or error
    pub fn change_password(&self, addresses: &AddressMap) -> Result<()> {
        // Prompt for new password
        let new_password = prompt_new_password()?;
        
        // Update the password in the agent
        self.password_agent.store_password(&new_password)?;
        
        // Re-encrypt and save the wallet with the new password
        self.save(addresses)
    }
}

/// Prompt the user for a password
fn prompt_password(prompt: &str) -> Result<String> {
    // Print prompt
    print!("{}", prompt);
    io::stdout().flush()?;
    
    // Read password without echoing
    let password = rpassword::read_password()
        .map_err(|e| WalletError::IoError(io::Error::new(io::ErrorKind::Other, e)))?;
    
    if password.is_empty() {
        return Err(WalletError::BitcoinError("Password cannot be empty".to_string()));
    }
    
    Ok(password)
}

/// Prompt for a new password with confirmation
fn prompt_new_password() -> Result<String> {
    let password = prompt_password("Enter new wallet password: ")?;
    let confirmation = prompt_password("Confirm wallet password: ")?;
    
    if password != confirmation {
        return Err(WalletError::BitcoinError("Passwords do not match".to_string()));
    }
    
    Ok(password)
}