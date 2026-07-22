use bitcoin::blockdata::witness::Witness;
use bitcoin::key::TapTweak;
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::{Keypair, Secp256k1, SecretKey};
use bitcoin::sighash::{Prevouts, SighashCache};
use bitcoin::{PublicKey, ScriptBuf, Transaction, TxOut};

use super::common::{
    create_empty_script_sig, create_message_from_tap_sighash, get_tap_sighash_type,
    get_xonly_pubkey,
};
use super::types::{InputSigner, Result, UTXO};
use crate::wallet::WalletError;

/// Guard: this key-path signer always tweaks with an empty merkle root (BIP86,
/// which is how every taproot address the wallet generates is built). Verify
/// that the wallet key plus an empty script tree actually reconstructs the
/// prevout's taproot output key. If it doesn't, the output commits to a script
/// tree (non-empty merkle root) and cannot be key-path-spent with this tweak —
/// signing anyway would silently produce an invalid signature, so reject it
/// explicitly instead.
fn ensure_keypath_output_matches(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    public_key: &PublicKey,
    script_pubkey: &ScriptBuf,
) -> Result<()> {
    let internal_key = get_xonly_pubkey(public_key)?;
    let expected = ScriptBuf::new_p2tr(secp, internal_key, None);
    if &expected != script_pubkey {
        return Err(WalletError::UnsupportedScript(
            "taproot output does not correspond to this wallet key with an empty script tree; \
             key-path spending an output that commits to a script tree is not supported"
                .to_string(),
        ));
    }
    Ok(())
}

/// Compute signature for key path spending
fn compute_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    input: &PsbtInput,
    all_prevouts: &[TxOut],
    secret_key: &SecretKey,
) -> Result<Vec<u8>> {
    // Get the sighash type
    let sighash_type = get_tap_sighash_type(input);

    // A BIP341 key-spend sighash commits to the prevouts of *every* input, so
    // the full set is required — using only this input's prevout produces a
    // `PrevoutsSizeError` for any transaction with more than one input.
    let prevouts = Prevouts::All(all_prevouts);

    // Compute the sighash
    let sighash = sighash_cache
        .taproot_key_spend_signature_hash(input_index, &prevouts, sighash_type)
        .map_err(|e| {
            WalletError::BitcoinError(format!("Failed to compute Taproot signature hash: {}", e))
        })?;

    // Create a message from the sighash
    let message = create_message_from_tap_sighash(sighash)?;

    // Create a keypair from the secret key and apply the BIP341 key-path tweak
    // (empty merkle root, matching `ensure_keypath_output_matches`).
    let keypair = Keypair::from_secret_key(secp, secret_key);
    let tweaked_keypair = keypair.tap_tweak(secp, None);
    let mut signing_keypair = tweaked_keypair.to_keypair();

    // Sign with Schnorr
    let schnorr_sig = secp.sign_schnorr_no_aux_rand(&message, &signing_keypair);

    // Verify the signature against the tweaked output key before returning.
    let (output_key, _) = tweaked_keypair.public_parts();
    let verified = secp
        .verify_schnorr(&schnorr_sig, &message, &output_key.to_x_only_public_key())
        .is_ok();

    // Best-effort wipe of the local secret copy. secp256k1's `Keypair` is `Copy`
    // and not zeroize-on-drop, so this only clears the stack copies we hold here;
    // transient copies made inside signing are out of reach.
    signing_keypair.non_secure_erase();

    if !verified {
        return Err(WalletError::SignatureVerificationFailed);
    }

    // Add sighash type
    let taproot_signature = bitcoin::taproot::Signature {
        signature: schnorr_sig,
        sighash_type,
    }
    .serialize();

    Ok(taproot_signature.to_vec())
}

/// Add key path spending witness
fn add_witness(input: &mut PsbtInput, signature: Vec<u8>) -> Result<()> {
    let mut witness = Witness::new();
    witness.push(signature);

    // Set witness data
    input.final_script_witness = Some(witness);

    // Set empty script_sig (required for SegWit)
    input.final_script_sig = Some(create_empty_script_sig());

    Ok(())
}

/// Implementation of InputSigner for P2TR key path spending
pub struct P2TRKPSSigner;

impl InputSigner for P2TRKPSSigner {
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

        // Reject outputs this key-path tweak cannot spend before signing.
        ensure_keypath_output_matches(secp, public_key, &utxo.script_pubkey)?;

        // Compute signature for key path spending
        let signature = compute_signature(
            secp,
            sighash_cache,
            input_index,
            input,
            all_prevouts,
            secret_key,
        )?;

        // Add witness data
        add_witness(input, signature)
    }
}
