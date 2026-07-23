use bitcoin::blockdata::witness::Witness;
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::{Keypair, Secp256k1, SecretKey};
use bitcoin::sighash::{Prevouts, SighashCache};
use bitcoin::taproot::{ControlBlock, LeafVersion, TapLeafHash, TaprootBuilder, TaprootSpendInfo};
use bitcoin::{PublicKey, ScriptBuf, Transaction, TxOut, XOnlyPublicKey};

use super::common::{
    create_empty_script_sig, create_message_from_tap_sighash, get_tap_sighash_type,
    get_xonly_pubkey, sign_and_verify_schnorr,
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

/// Generate Taproot spending information for a single-leaf tree with
/// `internal_key` as the internal key.
///
/// This is the only tree shape the client supports: one script leaf, internal
/// key equal to the signer's key. `sign_input` verifies the resulting output key
/// matches the prevout before using it, so a UTXO built from any other tree
/// (multiple leaves, a different internal key) is rejected rather than signed
/// into an unspendable input.
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

    // Create a keypair from the secret key (script-path signs with the untweaked
    // key — the tweak lives in the control block, not the signature).
    let keypair = Keypair::from_secret_key(secp, secret_key);
    let xonly_pubkey = XOnlyPublicKey::from_keypair(&keypair).0;

    // Sign (with aux-rand) against the untweaked internal key, verify, and wipe
    // the keypair — all in the shared helper.
    sign_and_verify_schnorr(secp, &message, keypair, &xonly_pubkey, sighash_type)
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
        let leaf_script = utxo
            .leaf_script
            .as_ref()
            .ok_or(WalletError::MissingScript("leaf"))?;

        // The client signs only the single-key tapscript `<signer_xonly>
        // OP_CHECKSIG`. The output-key reconstruction below proves the *address*
        // commits to this leaf and internal key, but NOT that the leaf's CHECKSIG
        // actually verifies against the signing key — a leaf pushing a *different*
        // key would still reconstruct the output, yet the signature (made with the
        // signing key) would be rejected by that CHECKSIG on-chain, yielding an
        // unspendable input. Validate the leaf shape explicitly before signing.
        let expected_leaf = bitcoin::script::Builder::new()
            .push_slice(xonly_pubkey.serialize())
            .push_opcode(bitcoin::opcodes::all::OP_CHECKSIG)
            .into_script();
        if *leaf_script != expected_leaf {
            return Err(WalletError::UnsupportedScript(
                "taproot script-path leaf is not the supported `<signer_key> OP_CHECKSIG` \
                 single-key tapscript"
                    .to_string(),
            ));
        }

        // Reconstruct the single-leaf taproot tree once, and derive both the
        // control block and the committed output key from it.
        let spend_info = generate_spend_info(secp, &xonly_pubkey, leaf_script)?;

        // Verify the reconstructed output key matches the prevout. If it does
        // not, the UTXO was built from a tree this client cannot reproduce
        // (multiple leaves, or a different internal key), so signing would emit
        // an invalid control block; reject it explicitly.
        let expected_spk = ScriptBuf::new_p2tr_tweaked(spend_info.output_key());
        if expected_spk != utxo.script_pubkey {
            return Err(WalletError::UnsupportedScript(
                "leaf script and internal key do not reconstruct this taproot output; only \
                 single-leaf script trees with the internal key equal to the signer key are \
                 supported"
                    .to_string(),
            ));
        }

        // Control block for the witness data.
        let control_block = spend_info
            .control_block(&(leaf_script.clone(), LeafVersion::TapScript))
            .ok_or_else(|| {
                WalletError::BitcoinError("Failed to create control block".to_string())
            })?;

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
