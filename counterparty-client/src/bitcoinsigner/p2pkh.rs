use bitcoin::blockdata::script::Builder;
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::{Message, Secp256k1, SecretKey};
use bitcoin::sighash::{EcdsaSighashType, SighashCache};
use bitcoin::{PublicKey, Transaction};

use super::types::{Result, UTXO};
use super::utils::{create_message_from_hash, encode_ecdsa_signature, to_push_bytes};
use crate::wallet::WalletError;

/// Computes the signature hash for P2PKH inputs
fn compute_sighash(
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    script_pubkey: &bitcoin::ScriptBuf,
    sighash_type: EcdsaSighashType,
) -> Result<[u8; 32]> {
    let sighash = sighash_cache
        .legacy_signature_hash(input_index, script_pubkey, sighash_type as u32)
        .map_err(|e| {
            WalletError::BitcoinError(format!("Failed to compute signature hash: {}", e))
        })?;
    
    // Convert sighash to [u8; 32]
    let mut bytes = [0u8; 32];
    let hash_bytes: &[u8] = sighash.as_ref();
    bytes.copy_from_slice(&hash_bytes[0..32]);
    Ok(bytes)
}

/// Signs a message with ECDSA and returns the signature bytes
fn sign_message_ecdsa(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    message: &Message,
    secret_key: &SecretKey,
    sighash_type: EcdsaSighashType,
) -> Result<Vec<u8>> {
    let signature = secp.sign_ecdsa(message, secret_key);
    
    // Verify signature (by checking it matches public key)
    let public_key = PublicKey::from_private_key(secp, 
        &bitcoin::PrivateKey { 
            inner: *secret_key, 
            compressed: true, 
            network: bitcoin::Network::Bitcoin.into() 
        });
    
    if secp.verify_ecdsa(message, &signature, &public_key.inner).is_err() {
        return Err(WalletError::BitcoinError(
            "Generated signature failed verification".to_string(),
        ));
    }
    
    // Encode the signature with sighash type
    Ok(encode_ecdsa_signature(&signature, sighash_type))
}

/// Adds a signature to a P2PKH input
fn add_signature(
    input: &mut PsbtInput,
    signature: Vec<u8>,
    pubkey: Vec<u8>,
) -> Result<()> {
    let sig_push_bytes = to_push_bytes(&signature)?;
    let pubkey_push_bytes = to_push_bytes(&pubkey)?;

    let script_sig = Builder::new()
        .push_slice(&sig_push_bytes)
        .push_slice(&pubkey_push_bytes)
        .into_script();

    input.final_script_sig = Some(script_sig);
    Ok(())
}

/// Signs a P2PKH input
pub fn sign_psbt_input(
    sighash_cache: &mut SighashCache<&Transaction>,
    input: &mut PsbtInput,
    input_index: usize,
    secret_key: &SecretKey,
    public_key: &PublicKey,
    utxo: &UTXO,
) -> Result<()> {
    // Get the script pubkey
    let script_pubkey = &utxo.script_pubkey;
    
    // Define sighash type
    let sighash_type = EcdsaSighashType::All;
    
    // Compute the sighash
    let sighash = compute_sighash(
        sighash_cache,
        input_index,
        script_pubkey,
        sighash_type,
    )?;
    
    // Create a message from the sighash
    let message = create_message_from_hash(&sighash)?;
    
    // Create a secp256k1 context
    let secp = Secp256k1::new();
    
    // Sign the message
    let signature = sign_message_ecdsa(&secp, &message, secret_key, sighash_type)?;
    
    // Add the signature to the input
    add_signature(input, signature, public_key.to_bytes())?;
    
    Ok(())
}
