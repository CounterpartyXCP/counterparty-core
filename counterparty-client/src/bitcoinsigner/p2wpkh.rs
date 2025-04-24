use bitcoin::blockdata::witness::Witness;
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::SecretKey;
use bitcoin::sighash::SighashCache;
use bitcoin::{PublicKey, Transaction};

use super::common::{
    create_and_verify_ecdsa_signature, create_empty_script_sig, get_ecdsa_sighash_type,
};
use super::types::{InputSigner, Result, UTXOType, UTXO};

/// Adds a signature to a P2WPKH input
fn add_p2wpkh_signature(input: &mut PsbtInput, signature: Vec<u8>, pubkey: Vec<u8>) -> Result<()> {
    // Create a witness stack with the signature and public key
    let mut witness = Witness::new();
    witness.push(signature);
    witness.push(pubkey);

    // Set the witness data
    input.final_script_witness = Some(witness);

    // Set empty script_sig (required for SegWit)
    input.final_script_sig = Some(create_empty_script_sig());

    Ok(())
}

/// Implementation of InputSigner for P2WPKH
pub struct P2WPKHSigner;

impl InputSigner for P2WPKHSigner {
    fn sign_input(
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

        // Create and verify the signature
        let signature = create_and_verify_ecdsa_signature(
            sighash_cache,
            input_index,
            script_pubkey,
            Some(amount), // Amount is required for SegWit inputs
            UTXOType::P2WPKH,
            secret_key,
            public_key,
            sighash_type,
        )?;

        // Add the signature to the input
        add_p2wpkh_signature(input, signature, public_key.to_bytes())
    }
}
