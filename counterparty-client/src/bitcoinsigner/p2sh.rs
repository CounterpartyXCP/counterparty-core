use bitcoin::blockdata::script::Builder;
use bitcoin::blockdata::witness::Witness;
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::SecretKey;
use bitcoin::sighash::SighashCache;
use bitcoin::{PublicKey, ScriptBuf, Transaction, TxOut};

use super::common::{
    create_and_verify_ecdsa_signature, get_compressed_pubkey, is_pubkey_in_script, to_push_bytes,
};
use super::types::{InputSigner, Result, UTXOType, UTXO};
use crate::wallet::WalletError;

/// Adds a signature to a regular (non-SegWit) P2SH input.
///
/// The scriptSig is `<sig> (<pubkey>)? <redeemScript>`. The public key is pushed
/// only when the redeem script does not already embed it: a P2PKH-style redeem
/// script (`OP_DUP OP_HASH160 <hash> OP_EQUALVERIFY OP_CHECKSIG`) commits to the
/// hash and needs the key on the stack, whereas a bare `<pubkey> OP_CHECKSIG`
/// already carries it. The wallet never generates legacy-P2SH addresses itself,
/// so this path is only reachable via `sign --utxos` with a caller-supplied
/// redeem script.
fn add_legacy_signature(
    input: &mut PsbtInput,
    signature: Vec<u8>,
    pubkey: Vec<u8>,
    pubkey_in_script: bool,
    redeem_script: &ScriptBuf,
) -> Result<()> {
    let sig_push_bytes = to_push_bytes(&signature)?;
    let redeem_script_push_bytes = to_push_bytes(&redeem_script.to_bytes())?;

    let mut builder = Builder::new().push_slice(&sig_push_bytes);
    if !pubkey_in_script {
        let pubkey_push_bytes = to_push_bytes(&pubkey)?;
        builder = builder.push_slice(&pubkey_push_bytes);
    }
    let script_sig = builder.push_slice(&redeem_script_push_bytes).into_script();

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
    let mut witness = Witness::new();
    witness.push(signature);
    witness.push(pubkey);
    input.final_script_witness = Some(witness);

    Ok(())
}

/// Signs a P2SH-P2WSH input (nested SegWit v0 script hash).
///
/// The sighash is the BIP143 P2WSH sighash over the inner witness script; the
/// scriptSig pushes the redeem script (the P2WSH witness program) and the
/// signature lives in the witness stack, script-aware like native P2WSH.
fn sign_p2sh_p2wsh(
    sighash_cache: &mut SighashCache<&Transaction>,
    input: &mut PsbtInput,
    input_index: usize,
    secret_key: &SecretKey,
    public_key: &PublicKey,
    utxo: &UTXO,
    witness_script: &ScriptBuf,
) -> Result<()> {
    let signature = create_and_verify_ecdsa_signature(
        sighash_cache,
        input_index,
        witness_script,
        Some(utxo.amount),
        UTXOType::P2WSH,
        secret_key,
        public_key,
        input,
    )?;

    // scriptSig pushes the redeem script = the P2WSH witness program.
    let redeem = ScriptBuf::new_p2wsh(&witness_script.wscript_hash());
    let redeem_push = to_push_bytes(&redeem.to_bytes())?;
    input.final_script_sig = Some(Builder::new().push_slice(&redeem_push).into_script());

    // Witness stack: <sig> (<pubkey>)? <witnessScript>.
    let mut witness = Witness::new();
    witness.push(signature);
    if !is_pubkey_in_script(witness_script, public_key) {
        witness.push(public_key.to_bytes());
    }
    witness.push(witness_script.as_bytes());
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
        _all_prevouts: &[TxOut],
        secret_key: &SecretKey,
        public_key: &PublicKey,
        utxo: &UTXO,
    ) -> Result<()> {
        // A witness script signals a nested P2SH-P2WSH input.
        if let Some(witness_script) = utxo.witness_script.as_ref() {
            return sign_p2sh_p2wsh(
                sighash_cache,
                input,
                input_index,
                secret_key,
                public_key,
                utxo,
                witness_script,
            );
        }

        // Otherwise a redeem script is required.
        let redeem_script = utxo.redeem_script.as_ref().ok_or_else(|| {
            WalletError::BitcoinError("Missing redeem script for P2SH input".to_string())
        })?;

        if redeem_script.is_p2wpkh() {
            // P2SH-P2WPKH: BIP143 sighash, redeem script in scriptSig, sig+pubkey
            // in the witness.
            let signature = create_and_verify_ecdsa_signature(
                sighash_cache,
                input_index,
                redeem_script,
                Some(utxo.amount),
                UTXOType::P2SH,
                secret_key,
                public_key,
                input,
            )?;
            add_p2sh_p2wpkh_signature(input, signature, public_key.to_bytes())
        } else {
            // Legacy P2SH: legacy sighash and an all-in-scriptSig spend.
            let signature = create_and_verify_ecdsa_signature(
                sighash_cache,
                input_index,
                redeem_script,
                None,
                UTXOType::P2SH,
                secret_key,
                public_key,
                input,
            )?;
            let pubkey_in_script = is_pubkey_in_script(redeem_script, public_key);
            add_legacy_signature(
                input,
                signature,
                public_key.to_bytes(),
                pubkey_in_script,
                redeem_script,
            )
        }
    }
}
