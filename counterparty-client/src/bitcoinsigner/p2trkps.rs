use bitcoin::blockdata::witness::Witness;
use bitcoin::key::{Keypair, TapTweak};
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::{Secp256k1, SecretKey};
use bitcoin::sighash::{Prevouts, SighashCache};
use bitcoin::{PublicKey, Transaction};

use super::common::{create_empty_script_sig, create_message_from_hash, get_tap_sighash_type};
use super::types::{Result, UTXO};
use crate::wallet::WalletError;

/// Compute signature for key path spending
fn compute_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    input: &PsbtInput,
    secret_key: &SecretKey,
) -> Result<Vec<u8>> {
    println!("Computing signature for Taproot key path spending...");
    // Get the sighash type
    let sighash_type = get_tap_sighash_type(input);

    // Get witness UTXO
    let witness_utxo = input.witness_utxo.as_ref().ok_or_else(|| {
        WalletError::BitcoinError(format!(
            "Missing witness UTXO for Taproot input at index {}",
            input_index
        ))
    })?;

    // Create Prevouts for the sighash calculation
    let utxos = [witness_utxo.clone()];
    let prevouts = Prevouts::All(&utxos);

    // Compute the sighash
    let sighash = sighash_cache
        .taproot_key_spend_signature_hash(input_index, &prevouts, sighash_type)
        .map_err(|e| {
            WalletError::BitcoinError(format!("Failed to compute Taproot signature hash: {}", e))
        })?;

    // Create a message from the sighash
    let mut sighash_bytes = [0u8; 32];
    let hash_bytes: &[u8] = sighash.as_ref();
    sighash_bytes.copy_from_slice(&hash_bytes[0..32]);
    let message = create_message_from_hash(&sighash_bytes)?;

    // Create a keypair from the secret key
    let keypair = Keypair::from_secret_key(secp, secret_key);
    let merkle_root = None;
    let tweaked_keypair = keypair.tap_tweak(secp, merkle_root);

    // Sign with Schnorr
    let schnorr_sig = secp.sign_schnorr_no_aux_rand(&message, &tweaked_keypair.to_inner());

    // Add sighash type 
    let taproot_signature = bitcoin::taproot::Signature {
        signature: schnorr_sig,
        sighash_type,
    }.serialize();

    // Verify signature
    let (xonly_pubkey, _) = tweaked_keypair.public_parts();
    if secp.verify_schnorr(&schnorr_sig, &message, &xonly_pubkey.to_inner()).is_err() {
        return Err(WalletError::BitcoinError(
            "Generated Schnorr signature failed verification".to_string(),
        ));
    }

    Ok(taproot_signature.to_vec())
}

/// Add key path spending witness
fn add_witness(
    input: &mut PsbtInput,
    signature: Vec<u8>,
) -> Result<()> {
    let mut witness = Witness::new();
    witness.push(signature);
    
    // Set witness data
    input.final_script_witness = Some(witness);
    
    // Set empty script_sig (required for SegWit)
    input.final_script_sig = Some(create_empty_script_sig());
    
    Ok(())
}

/// Signs a P2TR key path spending input
pub fn sign_psbt_input(
    sighash_cache: &mut SighashCache<&Transaction>,
    input: &mut PsbtInput,
    input_index: usize,
    secret_key: &SecretKey,
    _public_key: &PublicKey,
    _utxo: &UTXO,
) -> Result<()> {
    // Create a secp256k1 context
    let secp = Secp256k1::new();
    
    // Compute signature for key path spending
    let signature = compute_signature(
        &secp,
        sighash_cache,
        input_index,
        input,
        secret_key,
    )?;
    
    // Add witness data
    add_witness(input, signature)?;
    
    Ok(())
}
