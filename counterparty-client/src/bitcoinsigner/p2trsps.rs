use bitcoin::blockdata::witness::Witness;
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::{Keypair, Secp256k1, SecretKey};
use bitcoin::sighash::{Prevouts, SighashCache};
use bitcoin::taproot::{ControlBlock, LeafVersion, TapLeafHash, TaprootBuilder, TaprootSpendInfo};
use bitcoin::{PublicKey, ScriptBuf, Transaction, TxOut, XOnlyPublicKey};

use super::common::{
    create_empty_script_sig, create_message_from_tap_sighash, get_tap_sighash_type,
    get_xonly_pubkey,
};
use super::types::{InputSigner, Result, UTXO};
use crate::wallet::WalletError;

/// Generate a TapLeafHash from a script
fn taproot_leaf_hash(script: &ScriptBuf) -> TapLeafHash {
    TapLeafHash::from_script(script, LeafVersion::TapScript)
}

/// Create a single-leaf TaprootBuilder for the given script.
fn create_taproot_builder(script: &ScriptBuf) -> TaprootBuilder {
    // Adding one leaf at depth 0 to a fresh builder cannot fail.
    TaprootBuilder::new()
        .add_leaf(0, script.clone())
        .expect("adding a single depth-0 leaf never fails")
}

/// Generate Taproot spending information
fn generate_spend_info(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    internal_key: &XOnlyPublicKey,
    script: &ScriptBuf,
) -> Result<TaprootSpendInfo> {
    let builder = create_taproot_builder(script);

    builder.finalize(secp, *internal_key).map_err(|e| {
        WalletError::BitcoinError(format!("Failed to create Taproot spend info: {:?}", e))
    })
}

/// Create the control block for script-path spending.
///
/// The `bitcoin` crate derives the parity, internal key and merkle branch and
/// serialises them in consensus order, so there is no need to assemble the
/// control block by hand (the previous hand-rolled version was untested for
/// multi-leaf trees).
fn create_control_block(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    internal_key: &XOnlyPublicKey,
    leaf_script: &ScriptBuf,
) -> Result<ControlBlock> {
    let spend_info = generate_spend_info(secp, internal_key, leaf_script)?;

    let script_ver = (leaf_script.clone(), LeafVersion::TapScript);
    spend_info
        .control_block(&script_ver)
        .ok_or_else(|| WalletError::BitcoinError("Failed to create control block".to_string()))
}

/// Compute signature for script path spending
fn compute_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    input: &PsbtInput,
    all_prevouts: &[TxOut],
    leaf_script: &ScriptBuf,
    secret_key: &SecretKey,
) -> Result<Vec<u8>> {
    // Get the sighash type
    let sighash_type = get_tap_sighash_type(input);

    // Get the leaf hash
    let leaf_hash = taproot_leaf_hash(leaf_script);

    // A BIP341 script-spend sighash commits to the prevouts of *every* input, so
    // the full set is required — using only this input's prevout produces a
    // `PrevoutsSizeError` for any transaction with more than one input.
    let prevouts = Prevouts::All(all_prevouts);

    // Compute the sighash
    let sighash = sighash_cache
        .taproot_script_spend_signature_hash(input_index, &prevouts, leaf_hash, sighash_type)
        .map_err(|e| {
            WalletError::BitcoinError(format!(
                "Failed to compute Taproot script path signature hash: {}",
                e
            ))
        })?;

    // Convert sighash to bytes and create message
    let message = create_message_from_tap_sighash(sighash)?;

    // Create a keypair from the secret key
    let keypair = Keypair::from_secret_key(secp, secret_key);

    // Sign with Schnorr (no tweaking for script path)
    let schnorr_sig = secp.sign_schnorr_no_aux_rand(&message, &keypair);

    // Add sighash type to the signature
    let signature = bitcoin::taproot::Signature {
        signature: schnorr_sig,
        sighash_type,
    }
    .serialize();

    // Verify signature locally
    let xonly_pubkey = XOnlyPublicKey::from_keypair(&keypair).0;
    if secp
        .verify_schnorr(&schnorr_sig, &message, &xonly_pubkey)
        .is_err()
    {
        return Err(WalletError::BitcoinError(
            "Generated Schnorr signature failed verification".to_string(),
        ));
    }

    Ok(signature.to_vec())
}

/// Add the script-path witness stack: `<signature> <script> <control block>`.
fn add_witness(
    input: &mut PsbtInput,
    signature: Vec<u8>,
    leaf_script: &ScriptBuf,
    control_block: &ControlBlock,
) -> Result<()> {
    let witness_elements = [
        signature,
        leaf_script.as_bytes().to_vec(),
        control_block.serialize(),
    ];
    input.final_script_witness = Some(Witness::from_slice(&witness_elements));

    // Set empty script_sig (required for SegWit)
    input.final_script_sig = Some(create_empty_script_sig());

    Ok(())
}

/// Implementation of InputSigner for P2TR script path spending
pub struct P2TRSPSSigner;

impl InputSigner for P2TRSPSSigner {
    fn sign_input(
        sighash_cache: &mut SighashCache<&Transaction>,
        input: &mut PsbtInput,
        input_index: usize,
        all_prevouts: &[TxOut],
        secret_key: &SecretKey,
        public_key: &PublicKey,
        utxo: &UTXO,
    ) -> Result<()> {
        // Use the shared secp256k1 context
        let secp = super::common::secp();

        // Get XOnly pubkey from the source public key
        let xonly_pubkey = get_xonly_pubkey(public_key)?;

        // Get leaf script
        let leaf_script = utxo.leaf_script.as_ref().ok_or_else(|| {
            WalletError::BitcoinError(
                "Missing leaf script for P2TR script path spending".to_string(),
            )
        })?;

        // Create control block for witness data
        let control_block = create_control_block(secp, &xonly_pubkey, leaf_script)?;

        // Compute signature
        let signature = compute_signature(
            secp,
            sighash_cache,
            input_index,
            input,
            all_prevouts,
            leaf_script,
            secret_key,
        )?;

        // Add witness data
        add_witness(input, signature, leaf_script, &control_block)
    }
}
