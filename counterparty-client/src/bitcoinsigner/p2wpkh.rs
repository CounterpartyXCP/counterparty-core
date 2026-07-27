use bitcoin::blockdata::witness::Witness;
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::SecretKey;
use bitcoin::sighash::SighashCache;
use bitcoin::{PublicKey, Transaction, TxOut};

use super::common::{
    create_and_verify_ecdsa_signature, create_empty_script_sig, get_compressed_pubkey,
};
use super::types::{InputSigner, Result, UTXOType, UTXO};

/// Adds a signature to a P2WPKH input.
///
/// `pubkey` must be the 33-byte compressed serialization: a SegWit v0
/// scriptPubKey commits to `hash160(compressed_pubkey)`, so pushing an
/// uncompressed key would fail script verification (wrong hash) and is a BIP141
/// `WITNESS_PUBKEYTYPE` violation. The caller passes the compressed form.
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
        _all_prevouts: &[TxOut],
        secret_key: &SecretKey,
        public_key: &PublicKey,
        utxo: &UTXO,
    ) -> Result<()> {
        // Create and verify the signature
        let signature = create_and_verify_ecdsa_signature(
            sighash_cache,
            input_index,
            &utxo.script_pubkey,
            Some(utxo.amount), // Amount is required for SegWit inputs
            UTXOType::P2WPKH,
            secret_key,
            public_key,
            input,
        )?;

        // Push the compressed key: the SegWit v0 scriptPubKey commits to
        // hash160(compressed), so an uncompressed key (from an imported legacy
        // WIF) would otherwise produce an unspendable, non-standard witness.
        let compressed_pubkey = get_compressed_pubkey(public_key)?.to_bytes().to_vec();
        add_p2wpkh_signature(input, signature, compressed_pubkey)
    }
}
