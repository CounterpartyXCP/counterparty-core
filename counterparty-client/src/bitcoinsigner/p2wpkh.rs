use bitcoin::amount::Amount;
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::{Message, Secp256k1, SecretKey};
use bitcoin::sighash::{EcdsaSighashType, SighashCache};
use bitcoin::{PublicKey, Transaction};

use super::types::{Result, UTXO};
use super::utils::{create_empty_script_sig, create_message_from_hash, create_witness_stack, 
                   encode_ecdsa_signature, get_ecdsa_sighash_type};
use crate::wallet::WalletError;

/// Computes the signature hash for P2WPKH inputs
fn compute_sighash(
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    script_pubkey: &bitcoin::ScriptBuf,
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

/// Signs a P2WPKH input
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
    let amount = utxo.amount;
    
    // Define sighash type
    let sighash_type = get_ecdsa_sighash_type(input);
    
    // Compute the sighash
    let sighash = compute_sighash(
        sighash_cache,
        input_index,
        script_pubkey,
        amount,
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
    
    // Create the witness data
    let witness = create_witness_stack(sig_bytes, public_key.to_bytes());
    input.final_script_witness = Some(witness);
    
    // Set empty script_sig (required for SegWit)
    input.final_script_sig = Some(create_empty_script_sig());
    
    Ok(())
}
