use bitcoin::blockdata::script::{Builder, PushBytesBuf};
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::{Keypair, Message, Secp256k1, SecretKey};
use bitcoin::sighash::{EcdsaSighashType, SighashCache, TapSighashType};
use bitcoin::PublicKey;
use bitcoin::ScriptBuf;
use bitcoin::Transaction;
use std::str::FromStr;

use crate::signer::types::{AddressType, Result};
use crate::signer::utils::{
    create_empty_script_sig, create_message_from_hash, create_witness_with_sig_and_pubkey,
    get_xonly_pubkey, standardize_address_type,
};
use crate::signer::verification::{
    encode_ecdsa_signature, verify_ecdsa_signature, verify_schnorr_signature,
};
use crate::wallet::WalletError;

/// Signs a message with ECDSA and verifies the signature
pub fn sign_and_verify_ecdsa(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    message: &Message,
    secret_key: &SecretKey,
    public_key: &PublicKey,
    sighash_type: EcdsaSighashType,
) -> Result<Vec<u8>> {
    // Sign with ECDSA
    let signature = secp.sign_ecdsa(message, secret_key);

    // Verify the signature
    verify_ecdsa_signature(secp, message, &signature, public_key)?;

    // Encode with sighash type
    Ok(encode_ecdsa_signature(&signature, sighash_type))
}

/// Compute Taproot (P2TR) signature
pub fn compute_p2tr_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    input: &PsbtInput,
    secret_key: &SecretKey,
    public_key: &PublicKey,
) -> Result<Vec<u8>> {
    // For Taproot, use the appropriate sighash algorithm from input or default to All
    let sighash_type = match input.sighash_type {
        Some(s) => s.taproot_hash_ty().unwrap_or(TapSighashType::All),
        None => TapSighashType::All,
    };

    // Get witness UTXO safely with error handling
    let witness_utxo = input.witness_utxo.as_ref().ok_or_else(|| {
        WalletError::BitcoinError(format!(
            "Missing witness UTXO for Taproot input at index {}",
            input_index
        ))
    })?;

    // Create the Prevouts structure
    let prevouts = bitcoin::sighash::Prevouts::One(input_index, witness_utxo);

    let sighash = sighash_cache
        .taproot_key_spend_signature_hash(input_index, &prevouts, sighash_type)
        .map_err(|e| {
            WalletError::BitcoinError(format!("Failed to compute Taproot signature hash: {}", e))
        })?;

    // Create a message from the sighash
    let message = create_message_from_hash(&sighash[..])?;

    // Convert SecretKey to Keypair
    let keypair = Keypair::from_secret_key(&secp, &secret_key);
    let schnorr_sig = secp.sign_schnorr_no_aux_rand(&message, &keypair);
    let mut sig_bytes = schnorr_sig.as_ref().to_vec();

    // Add sighash byte for Taproot if not ALL
    if sighash_type != TapSighashType::All {
        sig_bytes.push(sighash_type as u8);
    }

    // Verify the signature
    let xonly_pubkey = get_xonly_pubkey(public_key)?;
    verify_schnorr_signature(secp, &message, &schnorr_sig, &xonly_pubkey)?;

    Ok(sig_bytes)
}

/// Compute SegWit (P2WPKH/P2SH-P2WPKH) signature
pub fn compute_segwit_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    input: &PsbtInput,
    script_pubkey: &ScriptBuf,
    secret_key: &SecretKey,
    public_key: &PublicKey,
) -> Result<Vec<u8>> {
    // For SegWit, use the correct method for segwit signatures
    let sighash_type = EcdsaSighashType::All;

    // Get witness UTXO safely with error handling
    let witness_utxo = input.witness_utxo.as_ref().ok_or_else(|| {
        WalletError::BitcoinError(format!(
            "Missing witness UTXO for SegWit input at index {}",
            input_index
        ))
    })?;

    let sighash = sighash_cache
        .p2wpkh_signature_hash(
            input_index,
            &script_pubkey,
            witness_utxo.value,
            sighash_type,
        )
        .map_err(|e| {
            WalletError::BitcoinError(format!("Failed to compute SegWit signature hash: {}", e))
        })?;

    // Create a message from the sighash and sign it
    let message = create_message_from_hash(&sighash[..])?;
    sign_and_verify_ecdsa(secp, &message, secret_key, public_key, sighash_type)
}

/// Compute P2WSH signature
pub fn compute_p2wsh_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    input: &PsbtInput,
    script_pubkey: &ScriptBuf,
    secret_key: &SecretKey,
    public_key: &PublicKey,
) -> Result<Vec<u8>> {
    // For P2WSH, use the correct method for segwit signatures
    let sighash_type = match input.sighash_type {
        Some(s) => s.ecdsa_hash_ty().unwrap_or(EcdsaSighashType::All),
        None => EcdsaSighashType::All,
    };

    // Get witness UTXO safely with error handling
    let witness_utxo = input.witness_utxo.as_ref().ok_or_else(|| {
        WalletError::BitcoinError(format!(
            "Missing witness UTXO for P2WSH input at index {}",
            input_index
        ))
    })?;

    let sighash = sighash_cache
        .p2wsh_signature_hash(input_index, script_pubkey, witness_utxo.value, sighash_type)
        .map_err(|e| {
            WalletError::BitcoinError(format!("Failed to compute P2WSH signature hash: {}", e))
        })?;

    // Create a message from the sighash and sign it
    let message = create_message_from_hash(&sighash[..])?;
    sign_and_verify_ecdsa(secp, &message, secret_key, public_key, sighash_type)
}

/// Compute Legacy (P2PKH) signature
pub fn compute_legacy_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    script_pubkey: &ScriptBuf,
    secret_key: &SecretKey,
    public_key: &PublicKey,
) -> Result<Vec<u8>> {
    // For legacy, use legacy_signature_hash
    let sighash_type = EcdsaSighashType::All;

    let sighash = sighash_cache
        .legacy_signature_hash(input_index, &script_pubkey, sighash_type as u32)
        .map_err(|e| {
            WalletError::BitcoinError(format!("Failed to compute legacy signature hash: {}", e))
        })?;

    // Create a message from the sighash and sign it
    let message = create_message_from_hash(&sighash[..])?;
    sign_and_verify_ecdsa(secp, &message, secret_key, public_key, sighash_type)
}

/// Compute signature for an input based on its address type
pub fn compute_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    input: &PsbtInput,
    script_pubkey: &ScriptBuf,
    secret_key: &SecretKey,
    public_key: &PublicKey,
    address_type: &str,
) -> Result<Vec<u8>> {
    let addr_type = AddressType::from_str(standardize_address_type(address_type))
        .expect("AddressType::from_str never returns an error");

    match addr_type {
        AddressType::P2TR => compute_p2tr_signature(
            secp,
            sighash_cache,
            input_index,
            input,
            secret_key,
            public_key,
        ),

        AddressType::P2WPKH | AddressType::P2SHP2WPKH => compute_segwit_signature(
            secp,
            sighash_cache,
            input_index,
            input,
            script_pubkey,
            secret_key,
            public_key,
        ),

        AddressType::P2WSH => compute_p2wsh_signature(
            secp,
            sighash_cache,
            input_index,
            input,
            script_pubkey,
            secret_key,
            public_key,
        ),

        _ => compute_legacy_signature(
            secp,
            sighash_cache,
            input_index,
            script_pubkey,
            secret_key,
            public_key,
        ),
    }
}

/// Add signature to P2WPKH input
pub fn add_p2wpkh_signature(
    input: &mut PsbtInput,
    signature_bytes: Vec<u8>,
    pubkey_bytes: Vec<u8>,
) -> Result<()> {
    input.final_script_witness = Some(create_witness_with_sig_and_pubkey(
        signature_bytes,
        pubkey_bytes,
    ));
    input.final_script_sig = Some(create_empty_script_sig());
    Ok(())
}

/// Add signature to P2PKH input
pub fn add_p2pkh_signature(
    input: &mut PsbtInput,
    signature_bytes: Vec<u8>,
    pubkey_bytes: Vec<u8>,
) -> Result<()> {
    let sig_push_bytes = PushBytesBuf::try_from(signature_bytes).map_err(|e| {
        WalletError::BitcoinError(format!(
            "Failed to convert signature to PushBytesBuf: {:?}",
            e
        ))
    })?;

    let pubkey_push_bytes = PushBytesBuf::try_from(pubkey_bytes).map_err(|e| {
        WalletError::BitcoinError(format!("Failed to convert pubkey to PushBytesBuf: {:?}", e))
    })?;

    let script_sig = Builder::new()
        .push_slice(&sig_push_bytes[..])
        .push_slice(&pubkey_push_bytes[..])
        .into_script();

    input.final_script_sig = Some(script_sig);
    Ok(())
}

/// Add signature to P2SH-P2WPKH input
pub fn add_p2sh_p2wpkh_signature(
    input: &mut PsbtInput,
    signature_bytes: Vec<u8>,
    pubkey_bytes: Vec<u8>,
) -> Result<()> {
    // 1. Create redeem script (P2WPKH)
    let compressed_pubkey = bitcoin::key::CompressedPublicKey::from_slice(&pubkey_bytes)
        .map_err(|e| WalletError::BitcoinError(format!("Invalid public key: {}", e)))?;

    // Use wpubkey_hash for P2WPKH
    let pubkey_hash = compressed_pubkey.wpubkey_hash();
    let redeem_script = ScriptBuf::new_p2wpkh(&pubkey_hash);

    // 2. Set script_sig to push redeem script
    let redeem_script_bytes = PushBytesBuf::try_from(redeem_script.to_bytes()).map_err(|e| {
        WalletError::BitcoinError(format!(
            "Failed to convert redeem script to PushBytesBuf: {:?}",
            e
        ))
    })?;

    let script_sig = Builder::new()
        .push_slice(&redeem_script_bytes[..])
        .into_script();

    input.final_script_sig = Some(script_sig);

    // 3. Set witness data (same as P2WPKH)
    input.final_script_witness = Some(create_witness_with_sig_and_pubkey(
        signature_bytes,
        pubkey_bytes,
    ));

    Ok(())
}

/// Add signature to P2TR input
pub fn add_p2tr_signature(input: &mut PsbtInput, signature_bytes: Vec<u8>) -> Result<()> {
    let mut witness = bitcoin::blockdata::witness::Witness::new();
    witness.push(signature_bytes);
    input.final_script_witness = Some(witness);

    // Empty script_sig for segwit
    input.final_script_sig = Some(create_empty_script_sig());

    Ok(())
}

/// Add signature to P2WSH input
pub fn add_p2wsh_signature(
    input: &mut PsbtInput,
    signature_bytes: Vec<u8>,
    pubkey_bytes: Vec<u8>,
    witness_script: &ScriptBuf,
) -> Result<()> {
    let mut witness = bitcoin::blockdata::witness::Witness::new();

    // Add signature
    witness.push(signature_bytes);

    // Add public key
    witness.push(pubkey_bytes);

    // Add the witness script
    witness.push(witness_script.as_bytes());

    input.final_script_witness = Some(witness);

    // Empty script_sig for segwit
    input.final_script_sig = Some(create_empty_script_sig());

    Ok(())
}

/// Add signature to PSBT input based on address type
pub fn add_signature_to_input(
    input: &mut PsbtInput,
    signature_bytes: Vec<u8>,
    pubkey_bytes: Vec<u8>,
    address_type: &str,
    witness_script: Option<&ScriptBuf>,
) -> Result<()> {
    let addr_type = AddressType::from_str(standardize_address_type(address_type))
        .expect("AddressType::from_str never returns an error");

    match addr_type {
        AddressType::P2WPKH => add_p2wpkh_signature(input, signature_bytes, pubkey_bytes),

        AddressType::P2PKH => add_p2pkh_signature(input, signature_bytes, pubkey_bytes),

        AddressType::P2SHP2WPKH => add_p2sh_p2wpkh_signature(input, signature_bytes, pubkey_bytes),

        AddressType::P2TR => add_p2tr_signature(input, signature_bytes),

        AddressType::P2WSH => {
            if let Some(script) = witness_script {
                add_p2wsh_signature(input, signature_bytes, pubkey_bytes, script)
            } else {
                Err(WalletError::BitcoinError(
                    "Missing witness script for P2WSH".to_string(),
                ))
            }
        }

        AddressType::Unknown => Err(WalletError::BitcoinError(format!(
            "Unsupported address type: {}",
            address_type
        ))),
    }
}
