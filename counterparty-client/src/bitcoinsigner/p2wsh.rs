use bitcoin::blockdata::witness::Witness;
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::SecretKey;
use bitcoin::sighash::SighashCache;
use bitcoin::{PublicKey, ScriptBuf, Transaction, TxOut};

use super::common::{
    create_and_verify_ecdsa_signature, create_empty_script_sig, is_pubkey_in_script,
};
use super::types::{InputSigner, Result, UTXOType, UTXO};
use crate::wallet::WalletError;

/// Adds a signature to a single-key P2WSH input.
///
/// The witness stack is `[<sig>, (<pubkey>)?, <witnessScript>]`. The public key
/// is pushed only when the witness script does not already carry it: a
/// P2PKH-style script (`OP_DUP OP_HASH160 <hash> OP_EQUALVERIFY OP_CHECKSIG`)
/// commits to the *hash*, so the pubkey must be supplied on the stack; a
/// pay-to-pubkey script (`<pubkey> OP_CHECKSIG`) already contains it and needs
/// only the signature. Multisig (which needs the `OP_CHECKMULTISIG` dummy
/// element and N signatures) is still unsupported; the wallet never generates
/// P2WSH addresses itself, so this path is only reachable via `sign --utxos`
/// with a caller-supplied witness script.
fn add_signature(
    input: &mut PsbtInput,
    signature: Vec<u8>,
    pubkey: Vec<u8>,
    pubkey_in_script: bool,
    witness_script: &ScriptBuf,
) -> Result<()> {
    // Create the witness stack
    let mut witness = Witness::new();

    // Add signature
    witness.push(signature);

    // Add the public key only when the script consumes it (P2PKH-style).
    if !pubkey_in_script {
        witness.push(pubkey);
    }

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
        _all_prevouts: &[TxOut],
        secret_key: &SecretKey,
        public_key: &PublicKey,
        utxo: &UTXO,
    ) -> Result<()> {
        // Get the witness script
        let witness_script = utxo.witness_script.as_ref().ok_or_else(|| {
            WalletError::BitcoinError("Missing witness script for P2WSH input".to_string())
        })?;

        // Whether the script embeds the raw public key (pay-to-pubkey) or only
        // its hash (P2PKH-style) decides whether the witness must also carry it.
        let pubkey_in_script = is_pubkey_in_script(witness_script, public_key);

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
        add_signature(
            input,
            signature,
            public_key.to_bytes(),
            pubkey_in_script,
            witness_script,
        )
    }
}
