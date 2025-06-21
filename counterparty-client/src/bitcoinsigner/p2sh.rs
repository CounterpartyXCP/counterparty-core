use bitcoin::blockdata::script::Builder;
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::SecretKey;
use bitcoin::sighash::SighashCache;
use bitcoin::{PublicKey, ScriptBuf, Transaction};

use super::common::{create_and_verify_ecdsa_signature, get_compressed_pubkey, to_push_bytes};
use super::types::{InputSigner, Result, UTXOType, UTXO};
use crate::wallet::WalletError;

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

/// Adds a signature to a P2SH-P2WPKH input
fn add_p2sh_p2wpkh_signature(
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

/// Implementation of InputSigner for P2SH
pub struct P2SHSigner;

impl InputSigner for P2SHSigner {
    fn sign_input(
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
        let amount = if is_p2sh_p2wpkh {
            Some(utxo.amount)
        } else {
            None
        };

        // Create and verify the signature
        let signature = create_and_verify_ecdsa_signature(
            sighash_cache,
            input_index,
            redeem_script,
            amount,
            UTXOType::P2SH,
            secret_key,
            public_key,
            input,
        )?;

        // Add the signature to the input based on the type
        if is_p2sh_p2wpkh {
            add_p2sh_p2wpkh_signature(input, signature, public_key.to_bytes())
        } else {
            add_legacy_signature(input, signature, public_key.to_bytes(), redeem_script)
        }
    }
}
