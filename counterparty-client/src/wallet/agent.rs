//! Password agent for secure in-memory password management.
//!
//! This module provides a background process that:
//! - Securely stores wallet passwords in memory only (never on disk)
//! - Communicates through an encrypted local socket
//! - Automatically expires after a configurable period of inactivity
//! - Prevents the need for storing passwords in plaintext files

use std::io::{Read, Write};
use std::os::unix::net::{UnixListener, UnixStream};
use std::path::{Path, PathBuf};
use std::process::{Child, Command, Stdio};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::thread;
use std::time::{Duration, Instant};
use std::fs;

use chacha20poly1305::{ChaCha20Poly1305, Key, Nonce};
use chacha20poly1305::aead::Aead;
use chacha20poly1305::KeyInit; // Import KeyInit trait for new() method
use rand::{Rng, thread_rng};
use argon2::password_hash::SaltString;
use argon2::{Argon2, Algorithm, Version, Params, PasswordHasher};
use serde::{Deserialize, Serialize};
use sha2::Digest;
use sha2::Sha256;
use hex;

use super::types::{Result, WalletError};
use super::utils::get_network_dir;
use crate::config;

// Default timeout after which the agent will automatically exit
const DEFAULT_TIMEOUT_SECS: u64 = 600; // 10 minutes
const SOCKET_NAME: &str = "password_agent.sock";
const NONCE_FILE: &str = "nonce.bin";
const SALT_FILE: &str = "key_salt.bin";
const KEY_INFO_FILE: &str = "key_info.bin";

// Key derivation parameters
const ARGON2_MEMORY_COST: u32 = 65536; // 64 MB
const ARGON2_TIME_COST: u32 = 10;
const ARGON2_PARALLELISM: u32 = 4;

/// Protocol messages for agent communication
#[derive(Serialize, Deserialize)]
enum AgentMessage {
    StorePassword(String),
    GetPassword,
    Ping,
    Shutdown,
}

/// Protocol responses from the agent
#[derive(Serialize, Deserialize)]
enum AgentResponse {
    Success,
    Password(String),
    Error(String),
    Pong,
}

/// Handles password caching and secure storage
pub struct PasswordAgent {
    network: config::Network,
    base_dir: PathBuf,
    socket_path: PathBuf,
    nonce_path: PathBuf,
    salt_path: PathBuf,
    key_info_path: PathBuf,
    agent_process: Option<Child>,
}

impl PasswordAgent {
    /// Create a new PasswordAgent instance
    ///
    /// # Arguments
    ///
    /// * `base_dir` - Directory where socket and nonce files will be stored
    /// * `network` - Bitcoin network (used to create separate agents for different networks)
    ///
    /// # Returns
    ///
    /// * `Result<PasswordAgent>` - New agent instance or error
    pub fn new<P: AsRef<Path>>(base_dir: P, network: config::Network) -> Result<Self> {
        let base_dir = base_dir.as_ref().to_path_buf();
        let network_dir = get_network_dir(&base_dir, network);

        // Create the network directory if it doesn't exist
        fs::create_dir_all(&network_dir)?;

        let socket_path = network_dir.join(SOCKET_NAME);
        let nonce_path = network_dir.join(NONCE_FILE);
        let salt_path = network_dir.join(SALT_FILE);
        let key_info_path = network_dir.join(KEY_INFO_FILE);

        Ok(PasswordAgent {
            network,
            base_dir,
            socket_path,
            nonce_path,
            salt_path,
            key_info_path,
            agent_process: None,
        })
    }

    /// Check if the agent is running and responsive
    ///
    /// # Returns
    ///
    /// * `bool` - True if the agent is running and responsive
    pub fn is_running(&self) -> bool {
        // First, check if the socket file exists
        if !self.socket_path.exists() {
            return false;
        }

        // Try to connect and send a ping
        match UnixStream::connect(&self.socket_path) {
            Ok(mut stream) => {
                // Modified to handle errors without using ? operator
                let message = match self.encrypt_message(&AgentMessage::Ping) {
                    Ok(msg) => msg,
                    Err(_) => return false,
                };
                
                if stream.write_all(&message).is_err() {
                    return false;
                }
                
                let mut response = vec![0; 1024];
                if stream.read(&mut response).is_err() {
                    return false;
                }
                
                // If we get any response, the agent is running
                true
            }
            Err(_) => {
                // Socket exists but we couldn't connect; it might be stale
                // Try to remove the stale socket file
                let _ = fs::remove_file(&self.socket_path);
                false
            }
        }
    }

    /// Start the password agent as a background process
    ///
    /// # Arguments
    ///
    /// * `timeout_secs` - Optional timeout in seconds (defaults to 10 minutes)
    ///
    /// # Returns
    ///
    /// * `Result<()>` - Success or error
    pub fn start(&mut self, timeout_secs: Option<u64>) -> Result<()> {
        // Generate a new nonce for this session and save it
        self.generate_and_save_nonce()?;
        
        // Generate key derivation salt if it doesn't exist
        self.ensure_key_derivation_salt()?;

        // If the agent is already running, don't start another one
        if self.is_running() {
            println!("Password agent is already running.");
            return Ok(());
        }

        // Make sure socket path directory exists
        if let Some(parent) = self.socket_path.parent() {
            fs::create_dir_all(parent)?;
        }

        // Remove stale socket file if it exists
        if self.socket_path.exists() {
            fs::remove_file(&self.socket_path)?;
        }

        // Get the path to the current executable
        let exe_path = std::env::current_exe()?;
        println!("Starting password agent using executable: {:?}", exe_path);
        
        // Start the agent as a separate process
        // FIXED: Pass base_dir to ensure correct key derivation
        let child = Command::new(exe_path)
            .arg("run-password-agent") // Custom command-line flag to run in agent mode
            .arg("--socket").arg(&self.socket_path)
            .arg("--network").arg(format!("{:?}", self.network))
            .arg("--timeout").arg(format!("{}", timeout_secs.unwrap_or(DEFAULT_TIMEOUT_SECS)))
            .arg("--nonce").arg(&self.nonce_path)
            .arg("--salt").arg(&self.salt_path)
            .arg("--key-info").arg(&self.key_info_path)
            .arg("--base-dir").arg(self.base_dir.to_string_lossy().to_string())
            .stdin(Stdio::null())
            .stdout(Stdio::piped())  // Capture stdout for debugging
            .stderr(Stdio::piped())  // Capture stderr for debugging
            .spawn()?;

        self.agent_process = Some(child);

        // Give the agent more time to initialize
        thread::sleep(Duration::from_millis(500));
        
        // Verify the agent is running
        let max_retries = 3;
        let mut is_running = false;
        
        for i in 0..max_retries {
            if self.is_running() {
                is_running = true;
                break;
            }
            println!("Waiting for agent to start (attempt {}/{})", i+1, max_retries);
            thread::sleep(Duration::from_millis(300));
        }
        
        if !is_running {
            if let Some(mut child) = self.agent_process.take() {
                // Try to get error output from child process
                if let Some(mut stderr) = child.stderr.take() {
                    let mut error_output = String::new();
                    if stderr.read_to_string(&mut error_output).is_ok() && !error_output.is_empty() {
                        eprintln!("Agent error: {}", error_output);
                    }
                }
                
                // Kill the process if it's still running
                let _ = child.kill();
            }
            
            return Err(WalletError::BitcoinError("Failed to start password agent - check permissions or socket path".to_string()));
        }

        println!("Password agent started successfully.");
        Ok(())
    }

    /// Generate cryptographic nonce for securing communication and save it
    fn generate_and_save_nonce(&self) -> Result<()> {
        let mut nonce = [0u8; 12]; // ChaCha20Poly1305 uses 12-byte nonces
        thread_rng().fill(&mut nonce);
        
        fs::write(&self.nonce_path, &nonce)?;
        Ok(())
    }

    /// Ensure that a salt for key derivation exists, creating one if needed
    fn ensure_key_derivation_salt(&self) -> Result<()> {
        if !self.salt_path.exists() {
            // Generate a cryptographically secure salt
            let mut salt = [0u8; 32];
            thread_rng().fill(&mut salt);
            
            fs::write(&self.salt_path, &salt)?;
        }
        
        // Make sure the key info file exists
        if !self.key_info_path.exists() {
            // Generate a unique key info (can be public)
            let mut key_info = [0u8; 8];
            thread_rng().fill(&mut key_info);
            
            fs::write(&self.key_info_path, &key_info)?;
        }
        
        Ok(())
    }

    /// Read the nonce used for encrypting communication with the agent
    fn read_nonce(&self) -> Result<[u8; 12]> {
        let nonce_data = fs::read(&self.nonce_path)?;
        if nonce_data.len() != 12 {
            return Err(WalletError::BitcoinError("Invalid nonce length".to_string()));
        }
        
        let mut nonce = [0u8; 12];
        nonce.copy_from_slice(&nonce_data);
        Ok(nonce)
    }
    
    /// Read the salt used for key derivation
    fn read_salt(&self) -> Result<Vec<u8>> {
        if !self.salt_path.exists() {
            return Err(WalletError::BitcoinError("Salt file not found".to_string()));
        }
        
        Ok(fs::read(&self.salt_path)?)
    }
    
    /// Read the key info used for key derivation
    fn read_key_info(&self) -> Result<Vec<u8>> {
        if !self.key_info_path.exists() {
            return Err(WalletError::BitcoinError("Key info file not found".to_string()));
        }
        
        Ok(fs::read(&self.key_info_path)?)
    }

    /// Derive an encryption key using Argon2id
    fn derive_encryption_key(&self) -> Result<[u8; 32]> {
        // Read the salt and key info
        let salt = self.read_salt()?;
        let key_info = self.read_key_info()?;
        
        // Create a unique input for key derivation
        // This is a combination of network, directory path and key_info
        // The key_info changes only if the salt is regenerated
        let network_string = format!("{:?}", self.network);
        let base_dir_string = self.base_dir.to_string_lossy();
        let input_data = format!("{}:{}:{}", 
            network_string, 
            base_dir_string,
            hex::encode(&key_info)
        );
        
        // Create a salt string from our binary salt
        let salt_str = hex::encode(&salt);
        let salt = SaltString::from_b64(&salt_str)
            .map_err(|e| WalletError::BitcoinError(format!("Invalid salt: {:?}", e)))?;
        
        // Configure Argon2id with high-security parameters
        let params = Params::new(
            ARGON2_MEMORY_COST, 
            ARGON2_TIME_COST, 
            ARGON2_PARALLELISM, 
            None
        ).map_err(|e| WalletError::BitcoinError(format!("Invalid Argon2 parameters: {:?}", e)))?;
        
        // Create Argon2id instance
        let argon2 = Argon2::new(
            Algorithm::Argon2id, 
            Version::V0x13, 
            params
        );
        
        // Hash the password using Argon2id
        let hash = argon2.hash_password(input_data.as_bytes(), &salt)
            .map_err(|e| WalletError::BitcoinError(format!("Argon2 error: {:?}", e)))?;
        
        // Extract the hash value directly as bytes - use binding to extend lifetime
        let binding = hash.hash.unwrap();
        let hash_bytes = binding.as_bytes();
        
        // Create a SHA-256 hash of the Argon2 output to get a 32-byte key
        let mut hasher = Sha256::new();
        hasher.update(hash_bytes);
        let result = hasher.finalize();
        
        // Convert to fixed-size array
        let mut key = [0u8; 32];
        key.copy_from_slice(&result);
        
        Ok(key)
    }

    /// Encrypt a message to send to the agent
    fn encrypt_message(&self, message: &AgentMessage) -> Result<Vec<u8>> {
        // Derive a secure encryption key
        let key_material = self.derive_encryption_key()?;
        
        let key = Key::from_slice(&key_material);
        let cipher = ChaCha20Poly1305::new(key);
        
        // Read the nonce
        let nonce_bytes = self.read_nonce()?;
        let nonce = Nonce::from_slice(&nonce_bytes);
        
        // Serialize and encrypt the message
        let serialized = serde_json::to_vec(message)
            .map_err(|e| WalletError::JsonError(e))?;
            
        cipher.encrypt(nonce, serialized.as_ref())
            .map_err(|e| WalletError::BitcoinError(format!("Encryption error: {:?}", e)))
    }

    /// Decrypt a response from the agent
    fn decrypt_response(&self, encrypted: &[u8]) -> Result<AgentResponse> {
        // Derive a secure encryption key (same as for encryption)
        let key_material = self.derive_encryption_key()?;
        
        let key = Key::from_slice(&key_material);
        let cipher = ChaCha20Poly1305::new(key);
        
        // Read the nonce
        let nonce_bytes = self.read_nonce()?;
        let nonce = Nonce::from_slice(&nonce_bytes);
        
        // Decrypt and deserialize the response
        let decrypted = cipher.decrypt(nonce, encrypted)
            .map_err(|e| WalletError::BitcoinError(format!("Decryption error: {:?}", e)))?;
            
        serde_json::from_slice(&decrypted)
            .map_err(|e| WalletError::JsonError(e))
    }

    /// Store a password in the agent
    ///
    /// # Arguments
    ///
    /// * `password` - Password to store
    ///
    /// # Returns
    ///
    /// * `Result<()>` - Success or error
    pub fn store_password(&self, password: &str) -> Result<()> {
        if !self.is_running() {
            return Err(WalletError::BitcoinError("Password agent not running".to_string()));
        }
        
        let mut stream = UnixStream::connect(&self.socket_path)?;
        
        // Send the store password message
        let message = self.encrypt_message(&AgentMessage::StorePassword(password.to_string()))?;
        stream.write_all(&message)?;
        
        // Read the response
        let mut response = vec![0; 1024];
        let bytes_read = stream.read(&mut response)?;
        response.truncate(bytes_read);
        
        match self.decrypt_response(&response)? {
            AgentResponse::Success => Ok(()),
            AgentResponse::Error(err) => Err(WalletError::BitcoinError(err)),
            _ => Err(WalletError::BitcoinError("Unexpected response from agent".to_string())),
        }
    }

    /// Retrieve a password from the agent
    ///
    /// # Returns
    ///
    /// * `Result<String>` - Password or error
    pub fn get_password(&self) -> Result<String> {
        if !self.is_running() {
            return Err(WalletError::BitcoinError("Password agent not running".to_string()));
        }
        
        let mut stream = UnixStream::connect(&self.socket_path)?;
        
        // Send the get password message
        let message = self.encrypt_message(&AgentMessage::GetPassword)?;
        stream.write_all(&message)?;
        
        // Read the response
        let mut response = vec![0; 1024];
        let bytes_read = stream.read(&mut response)?;
        response.truncate(bytes_read);
        
        match self.decrypt_response(&response)? {
            AgentResponse::Password(password) => Ok(password),
            AgentResponse::Error(err) => Err(WalletError::BitcoinError(err)),
            _ => Err(WalletError::BitcoinError("Unexpected response from agent".to_string())),
        }
    }

    /// Shutdown the password agent
    ///
    /// # Returns
    ///
    /// * `Result<()>` - Success or error
    pub fn shutdown(&mut self) -> Result<()> {
        if !self.is_running() {
            return Ok(());
        }
        
        // Try to send a shutdown message to the agent
        let mut stream = match UnixStream::connect(&self.socket_path) {
            Ok(s) => s,
            Err(_) => return Ok(()),
        };
        
        let message = self.encrypt_message(&AgentMessage::Shutdown)?;
        let _ = stream.write_all(&message);
        
        // If we have a process handle, try to wait for it to exit
        if let Some(child) = &mut self.agent_process {
            let _ = child.wait();
            self.agent_process = None;
        }
        
        // Clean up socket and nonce files (but keep salt and key info)
        let _ = fs::remove_file(&self.socket_path);
        let _ = fs::remove_file(&self.nonce_path);
        
        Ok(())
    }
}

/// Run the password agent process
///
/// This function is intended to be called by the application when it's started
/// with a special command-line flag (e.g., `run-password-agent`).
///
/// # Arguments
///
/// * `socket_path` - Path to the Unix socket for communication
/// * `timeout_secs` - Timeout in seconds after which the agent will exit
/// * `nonce_path` - Path to the file containing the encryption nonce
/// * `salt_path` - Path to the file containing the salt for key derivation
/// * `key_info_path` - Path to the file containing additional key derivation data
/// * `network` - Bitcoin network type (mainnet, testnet, regtest)
/// * `base_dir` - Base directory path as a string
///
/// # Returns
///
/// * `Result<()>` - Success or error
#[allow(dead_code)]
pub fn run_agent<P: AsRef<Path>>(
    socket_path: P, 
    timeout_secs: u64, 
    nonce_path: P,
    salt_path: P,
    key_info_path: P,
    network: config::Network,  // FIXED: Added network parameter
    base_dir: String          // FIXED: Added base_dir parameter
) -> Result<()> {
    let socket_path = socket_path.as_ref().to_path_buf();
    let nonce_path = nonce_path.as_ref().to_path_buf();
    let salt_path = salt_path.as_ref().to_path_buf();
    let key_info_path = key_info_path.as_ref().to_path_buf();
    let base_dir_path = PathBuf::from(base_dir);  // Convert string to PathBuf
    
    // Clean up any existing socket file
    if socket_path.exists() {
        fs::remove_file(&socket_path)?;
    }
    
    // Create the socket
    let listener = UnixListener::bind(&socket_path)?;
    
    // Set up timeout tracking - Now thread-safe with Arc<Mutex<>>
    let last_activity = Arc::new(parking_lot::Mutex::new(Instant::now()));
    let last_activity_clone = last_activity.clone();  // Clone for thread
    let password = Arc::new(parking_lot::Mutex::new(String::new()));
    
    // Flag to signal when to shut down
    let shutdown = Arc::new(AtomicBool::new(false));
    let shutdown_clone = shutdown.clone();
    
    // Set up a timeout thread with proper thread synchronization
    let timeout_thread = thread::spawn(move || {
        while !shutdown_clone.load(Ordering::SeqCst) {
            thread::sleep(Duration::from_secs(1));
            
            // Access the shared last_activity variable safely through the mutex
            let activity_lock = last_activity_clone.lock();
            let elapsed = Instant::now().duration_since(*activity_lock);
            if elapsed.as_secs() > timeout_secs {
                println!("Timeout reached, shutting down agent");
                shutdown_clone.store(true, Ordering::SeqCst);
                break;
            }
        }
    });
    
    // Read the nonce for encryption/decryption
    let nonce_data = fs::read(&nonce_path)?;
    if nonce_data.len() != 12 {
        return Err(WalletError::BitcoinError("Invalid nonce length".to_string()));
    }
    
    let mut nonce = [0u8; 12];
    nonce.copy_from_slice(&nonce_data);
    
    // Read the salt and key info for secure key derivation
    let salt = fs::read(&salt_path)?;
    let key_info = fs::read(&key_info_path)?;
    
    // FIXED: Use the exact same key derivation logic as the client side
    // Create a unique input for key derivation matching what the client uses
    let network_string = format!("{:?}", network);
    let base_dir_string = base_dir_path.to_string_lossy();
    let input_data = format!("{}:{}:{}", 
        network_string, 
        base_dir_string,
        hex::encode(&key_info)
    );
    
    println!("Agent initialized with network: {:?}", network);
    
    // Create a salt string from our binary salt
    let salt_str = hex::encode(&salt);
    let salt_string = SaltString::from_b64(&salt_str)
        .map_err(|e| WalletError::BitcoinError(format!("Invalid salt: {:?}", e)))?;
    
    // Configure Argon2id for key derivation
    let params = Params::new(
        ARGON2_MEMORY_COST, 
        ARGON2_TIME_COST, 
        ARGON2_PARALLELISM, 
        None
    ).map_err(|e| WalletError::BitcoinError(format!("Invalid Argon2 parameters: {:?}", e)))?;
    
    // Create Argon2id instance
    let argon2 = Argon2::new(
        Algorithm::Argon2id, 
        Version::V0x13, 
        params
    );
    
    // Hash the password using Argon2id
    let hash = argon2.hash_password(input_data.as_bytes(), &salt_string)
        .map_err(|e| WalletError::BitcoinError(format!("Argon2 error: {:?}", e)))?;
    
    // Extract the hash value directly as bytes - use binding to extend lifetime
    let binding = hash.hash.unwrap();
    let hash_bytes = binding.as_bytes();
    
    // Create a SHA-256 hash of the Argon2 output to get a 32-byte key
    let mut hasher = Sha256::new();
    hasher.update(hash_bytes);
    let result = hasher.finalize();
    
    let mut key_material = [0u8; 32];
    key_material.copy_from_slice(&result);
    
    let key = Key::from_slice(&key_material);
    let cipher = ChaCha20Poly1305::new(key);
    
    println!("Agent successfully initialized, listening for connections");
    
    // Main listener loop
    for stream in listener.incoming() {
        if shutdown.load(Ordering::SeqCst) {
            println!("Shutdown signal detected, exiting");
            break;
        }
        
        // Update last activity time with proper thread safety
        {
            let mut activity = last_activity.lock();
            *activity = Instant::now();
        }
        
        let stream = match stream {
            Ok(s) => s,
            Err(e) => {
                eprintln!("Error accepting connection: {:?}", e);
                continue;
            }
        };
        
        println!("Handling new connection");
        
        // Handle the connection
        if let Err(e) = handle_connection(
            stream,
            &cipher,
            &nonce,
            &password,
            &shutdown,
        ) {
            eprintln!("Error handling connection: {:?}", e);
        }
    }
    
    // Cleanup
    println!("Agent shutting down, cleaning up");
    timeout_thread.join().unwrap();
    if socket_path.exists() {
        fs::remove_file(&socket_path)?;
    }
    
    Ok(())
}

/// Handle an incoming connection to the agent
#[allow(dead_code)]
fn handle_connection(
    mut stream: UnixStream,
    cipher: &ChaCha20Poly1305,
    nonce: &[u8],
    password: &Arc<parking_lot::Mutex<String>>,
    shutdown: &Arc<AtomicBool>,
) -> Result<()> {
    let nonce = Nonce::from_slice(nonce);
    let mut buffer = [0; 1024];
    
    // Read the encrypted message
    let bytes_read = stream.read(&mut buffer)?;
    if bytes_read == 0 {
        return Ok(());
    }
    
    // Decrypt the message
    let decrypted = match cipher.decrypt(nonce, &buffer[..bytes_read]) {
        Ok(d) => d,
        Err(e) => {
            eprintln!("Decryption error: {:?}", e);
            return Err(WalletError::BitcoinError("Decryption error".to_string()));
        }
    };
    
    // Parse the message
    let message: AgentMessage = match serde_json::from_slice(&decrypted) {
        Ok(m) => m,
        Err(e) => {
            eprintln!("Invalid message format: {:?}", e);
            return Err(WalletError::BitcoinError("Invalid message format".to_string()));
        }
    };
    
    // Process the message and prepare response
    let response = match message {
        AgentMessage::StorePassword(pw) => {
            println!("Storing password");
            let mut password_lock = password.lock();
            *password_lock = pw;
            AgentResponse::Success
        },
        AgentMessage::GetPassword => {
            println!("Password requested");
            let password_lock = password.lock();
            if password_lock.is_empty() {
                AgentResponse::Error("No password stored".to_string())
            } else {
                AgentResponse::Password(password_lock.clone())
            }
        },
        AgentMessage::Ping => {
            println!("Ping received");
            AgentResponse::Pong
        },
        AgentMessage::Shutdown => {
            println!("Shutdown requested");
            shutdown.store(true, Ordering::SeqCst);
            AgentResponse::Success
        },
    };
    
    // Serialize and encrypt the response
    let serialized = serde_json::to_vec(&response)?;
    let encrypted = cipher.encrypt(nonce, serialized.as_ref())
        .map_err(|e| WalletError::BitcoinError(format!("Encryption error: {:?}", e)))?;
    
    // Send the response
    stream.write_all(&encrypted)?;
    
    Ok(())
}

impl Drop for PasswordAgent {
    fn drop(&mut self) {
        // Attempt to shut down the agent when the PasswordAgent is dropped
        let _ = self.shutdown();
    }
}