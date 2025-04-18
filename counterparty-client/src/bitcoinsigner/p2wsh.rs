use bitcoin::amount::Amount;
use bitcoin::blockdata::witness::Witness;
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::{Message, Secp256k1, SecretKey};
use bitcoin::sighash::{EcdsaSighashType, SighashCache};
use bitcoin::{PublicKey, ScriptBuf, Transaction};

use super::types::{Result, UTXO};
use super::utils::{create_empty_script_sig, create_message_from_hash, encode_ecdsa_signature, get_ecdsa_sighash_type};
use crate::wallet::WalletError;

/// Computes the signature hash for P2WSH inputs
fn compute_sighash(
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    witness_script: &ScriptBuf,
    amount: u64,
    sighash_type: EcdsaSighashType,
) -> Result<[u8; 32]> {
    let amount = Amount::from_sat(amount);
    let sighash = sighash_cache
        .p2wsh_signature_hash(input_index, witness_script, amount, sighash_type)
        .map_err(|e| {
            WalletError::BitcoinError(format!("Failed to compute signature hash: {}", e))
        })?;
    
    // Convert sighash to [u8; 32]
    let mut bytes = [0u8; 32];
    let hash_bytes: &[u8] = sighash.as_ref();
    bytes.copy_from_slice(&hash_bytes[0..32]);
    Ok(bytes)
}

/// Adds a signature to a P2WSH input
fn add_signature(
    input: &mut PsbtInput,
    signature: Vec<u8>,
    pubkey: Vec<u8>,
    witness_script: &ScriptBuf,
) -> Result<()> {
    // Create the witness stack
    let mut witness = Witness::new();
    
    // First item is empty for multisig (OP_CHECKMULTISIG bug workaround)
    // Uncomment if needed for multisig scripts
    // witness.push(&[]);
    
    // Add signature
    witness.push(signature);
    
    // Add public key
    witness.push(pubkey);
    
    // Add the witness script
    witness.push(witness_script.as_bytes());
    
    // Set the witness data
    input.final_script_witness = Some(witness);
    
    // Set empty script_sig (required for SegWit)
    input.final_script_sig = Some(create_empty_script_sig());
    
    Ok(())
}

/// Checks if a public key is used in a witness script
fn is_pubkey_in_witness_script(
    witness_script: &ScriptBuf,
    public_key: &PublicKey,
) -> Result<bool> {
    // Convert the public key to serialized format
    let pubkey_bytes = public_key.to_bytes();
    
    // Parse the script into instructions
    let mut iter = witness_script.instructions_minimal();
    
    // Iterate through all elements in the script
    while let Some(result) = iter.next() {
        // Only process successfully parsed instructions
        if let Ok(instruction) = result {
            if let bitcoin::blockdata::script::Instruction::PushBytes(bytes) = instruction {
                // Check if this pushed data is a public key
                if bytes.len() == pubkey_bytes.len() && bytes.as_bytes() == pubkey_bytes.as_slice() {
                    return Ok(true);
                }
            }
        }
    }
    
    Ok(false)
}

/// Signs a P2WSH input
pub fn sign_psbt_input(
    sighash_cache: &mut SighashCache<&Transaction>,
    input: &mut PsbtInput,
    input_index: usize,
    secret_key: &SecretKey,
    public_key: &PublicKey,
    utxo: &UTXO,
) -> Result<()> {
    // Get the witness script
    let witness_script = utxo.witness_script.as_ref().ok_or_else(|| {
        WalletError::BitcoinError("Missing witness script for P2WSH input".to_string())
    })?;
    
    // Check if the public key is in the witness script
    if !is_pubkey_in_witness_script(witness_script, public_key)? {
        return Err(WalletError::BitcoinError(
            "Public key not found in witness script".to_string(),
        ));
    }
    
    // Define sighash type
    let sighash_type = get_ecdsa_sighash_type(input);
    
    // Compute the sighash
    let sighash = compute_sighash(
        sighash_cache,
        input_index,
        witness_script,
        utxo.amount,
        sighash_type,
    )?;
    
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
    
    // Add the signature to the input
    add_signature(input, sig_bytes, public_key.to_bytes(), witness_script)?;
    
    Ok(())
}
