use bitcoin::blockdata::witness::Witness;
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::SecretKey;
use bitcoin::sighash::SighashCache;
use bitcoin::{PublicKey, ScriptBuf, Transaction};

use super::common::{create_and_verify_ecdsa_signature, create_empty_script_sig};
use super::types::{InputSigner, Result, UTXOType, UTXO};
use crate::wallet::WalletError;

/// Checks if a public key is used in a witness script
fn is_pubkey_in_witness_script(witness_script: &ScriptBuf, public_key: &PublicKey) -> Result<bool> {
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
                if bytes.len() == pubkey_bytes.len() && bytes.as_bytes() == pubkey_bytes.as_slice()
                {
                    return Ok(true);
                }
            }
        }
    }

    Ok(false)
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

/// Implementation of InputSigner for P2WSH
pub struct P2WSHSigner;

impl InputSigner for P2WSHSigner {
    fn sign_input(
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

        // Create and verify the signature
        let signature = create_and_verify_ecdsa_signature(
            sighash_cache,
            input_index,
            witness_script,
            Some(utxo.amount), // Amount is required for SegWit inputs
            UTXOType::P2WSH,
            secret_key,
            public_key,
            input,
        )?;

        // Add the signature to the input
        add_signature(input, signature, public_key.to_bytes(), witness_script)
    }
}
