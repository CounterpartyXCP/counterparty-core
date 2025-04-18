use bitcoin::amount::Amount;
use bitcoin::blockdata::script::Builder;
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::{Message, Secp256k1, SecretKey};
use bitcoin::sighash::{EcdsaSighashType, SighashCache};
use bitcoin::{PublicKey, ScriptBuf, Transaction};

use super::types::{Result, UTXO};
use super::utils::{create_message_from_hash, encode_ecdsa_signature, get_compressed_pubkey, to_push_bytes};
use crate::wallet::WalletError;

/// Computes the signature hash for P2SH-P2WPKH inputs
fn compute_p2wpkh_sighash(
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    script_pubkey: &ScriptBuf,
    amount: u64,
    sighash_type: EcdsaSighashType,
) -> Result<[u8; 32]> {
    let amount = Amount::from_sat(amount);
    let sighash = sighash_cache
        .p2wpkh_signature_hash(input_index, script_pubkey, amount, sighash_type)
        .map_err(|e| {
            WalletError::BitcoinError(format!("Failed to compute signature hash: {}", e))
        })?;
    
    // Convert sighash to [u8; 32]
    let mut bytes = [0u8; 32];
    let hash_bytes: &[u8] = sighash.as_ref();
    bytes.copy_from_slice(&hash_bytes[0..32]);
    Ok(bytes)
}

/// Computes the signature hash for regular P2SH inputs
fn compute_legacy_sighash(
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    redeem_script: &ScriptBuf,
    sighash_type: EcdsaSighashType,
) -> Result<[u8; 32]> {
    let sighash = sighash_cache
        .legacy_signature_hash(input_index, redeem_script, sighash_type as u32)
        .map_err(|e| {
            WalletError::BitcoinError(format!("Failed to compute signature hash: {}", e))
        })?;
    
    // Convert sighash to [u8; 32]
    let mut bytes = [0u8; 32];
    let hash_bytes: &[u8] = sighash.as_ref();
    bytes.copy_from_slice(&hash_bytes[0..32]);
    Ok(bytes)
}

/// Adds a signature to a P2SH-P2WPKH input
fn add_p2wpkh_signature(
    input: &mut PsbtInput,
    signature: Vec<u8>,
    pubkey: Vec<u8>,
) -> Result<()> {
    // Create the redeem script (P2WPKH)
    let public_key = PublicKey::from_slice(&pubkey)
        .map_err(|e| WalletError::BitcoinError(format!("Invalid public key: {}", e)))?;
    
    let compressed_pubkey = get_compressed_pubkey(&public_key)?;
    let pubkey_hash = compressed_pubkey.wpubkey_hash();
    let redeem_script = ScriptBuf::new_p2wpkh(&pubkey_hash);
    
    // Create a script_sig that pushes the redeem script
    let redeem_script_bytes = to_push_bytes(&redeem_script.to_bytes())?;
    let script_sig = Builder::new()
        .push_slice(&redeem_script_bytes)
        .into_script();
    
    // Set the script_sig
    input.final_script_sig = Some(script_sig);
    
    // Set the witness stack
    let mut witness = bitcoin::blockdata::witness::Witness::new();
    witness.push(signature);
    witness.push(pubkey);
    input.final_script_witness = Some(witness);
    
    Ok(())
}

/// Adds a signature to a regular P2SH input
fn add_legacy_signature(
    input: &mut PsbtInput,
    signature: Vec<u8>,
    pubkey: Vec<u8>,
    redeem_script: &ScriptBuf,
) -> Result<()> {
    // Create a script_sig that pushes the signature, public key, and redeem script
    let sig_push_bytes = to_push_bytes(&signature)?;
    let pubkey_push_bytes = to_push_bytes(&pubkey)?;
    let redeem_script_push_bytes = to_push_bytes(&redeem_script.to_bytes())?;
    
    let script_sig = Builder::new()
        .push_slice(&sig_push_bytes)
        .push_slice(&pubkey_push_bytes)
        .push_slice(&redeem_script_push_bytes)
        .into_script();
    
    // Set the script_sig
    input.final_script_sig = Some(script_sig);
    
    Ok(())
}

/// Signs a P2SH input (handles both regular P2SH and P2SH-P2WPKH)
pub fn sign_psbt_input(
    sighash_cache: &mut SighashCache<&Transaction>,
    input: &mut PsbtInput,
    input_index: usize,
    secret_key: &SecretKey,
    public_key: &PublicKey,
    utxo: &UTXO,
) -> Result<()> {
    // Get the redeem script
    let redeem_script = utxo.redeem_script.as_ref().ok_or_else(|| {
        WalletError::BitcoinError("Missing redeem script for P2SH input".to_string())
    })?;
    
    // Determine if this is P2SH-P2WPKH
    let is_p2sh_p2wpkh = redeem_script.is_p2wpkh();
    
    // Define sighash type
    let sighash_type = EcdsaSighashType::All;
    
    // Compute the sighash based on the type
    let sighash = if is_p2sh_p2wpkh {
        compute_p2wpkh_sighash(
            sighash_cache,
            input_index,
            redeem_script,
            utxo.amount,
            sighash_type,
        )?
    } else {
        compute_legacy_sighash(
            sighash_cache,
            input_index,
            redeem_script,
            sighash_type,
        )?
    };
    
    // Create a message from the sighash
    let message = create_message_from_hash(&sighash)?;
    
    // Create a secp256k1 context
    let secp = Secp256k1::new();
    
    // Sign the message
    let signature = secp.sign_ecdsa(&message, secret_key);
    
    // Verify signature
    if secp.verify_ecdsa(&message, &signature, &public_key.inner).is_err() {
        return Err(WalletError::BitcoinError(
            "Generated signature failed verification".to_string(),
        ));
    }
    
    // Encode the signature
    let sig_bytes = encode_ecdsa_signature(&signature, sighash_type);
    
    // Add the signature to the input based on the type
    if is_p2sh_p2wpkh {
        add_p2wpkh_signature(input, sig_bytes, public_key.to_bytes())?;
    } else {
        add_legacy_signature(input, sig_bytes, public_key.to_bytes(), redeem_script)?;
    }
    
    Ok(())
}
