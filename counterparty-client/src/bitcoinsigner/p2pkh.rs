use bitcoin::blockdata::script::Builder;
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::SecretKey;
use bitcoin::sighash::SighashCache;
use bitcoin::{PublicKey, Transaction};

use super::common::{create_and_verify_ecdsa_signature, to_push_bytes};
use super::types::{InputSigner, Result, UTXOType, UTXO};

/// Adds a signature to a P2PKH input
fn add_p2pkh_signature(input: &mut PsbtInput, signature: Vec<u8>, pubkey: Vec<u8>) -> Result<()> {
    let sig_push_bytes = to_push_bytes(&signature)?;
    let pubkey_push_bytes = to_push_bytes(&pubkey)?;

    let script_sig = Builder::new()
        .push_slice(&sig_push_bytes)
        .push_slice(&pubkey_push_bytes)
        .into_script();

    input.final_script_sig = Some(script_sig);
    Ok(())
}

/// Implementation of InputSigner for P2PKH
pub struct P2PKHSigner;

impl InputSigner for P2PKHSigner {
    fn sign_input(
        sighash_cache: &mut SighashCache<&Transaction>,
        input: &mut PsbtInput,
        input_index: usize,
        secret_key: &SecretKey,
        public_key: &PublicKey,
        utxo: &UTXO,
    ) -> Result<()> {
        // Create and verify the signature
        let signature = create_and_verify_ecdsa_signature(
            sighash_cache,
            input_index,
            &utxo.script_pubkey,
            None, // Amount not needed for P2PKH
            UTXOType::P2PKH,
            secret_key,
            public_key,
            input,
        )?;

        // Add the signature to the input
        add_p2pkh_signature(input, signature, public_key.to_bytes())
    }
}
