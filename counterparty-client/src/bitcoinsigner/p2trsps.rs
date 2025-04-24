use bitcoin::amount::Amount;
use bitcoin::blockdata::transaction::TxOut;
use bitcoin::blockdata::witness::Witness;
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::{Keypair, Secp256k1, SecretKey};
use bitcoin::sighash::{Prevouts, SighashCache};
use bitcoin::taproot::{LeafVersion, TapLeafHash, TapNodeHash, TaprootBuilder, TaprootSpendInfo};
use bitcoin::{PublicKey, ScriptBuf, Transaction, XOnlyPublicKey};

use super::common::{
    create_empty_script_sig, create_message_from_hash, get_tap_sighash_type, get_xonly_pubkey,
};
use super::types::{Result, UTXO};
use crate::wallet::WalletError;

/// Control block for script path spending
pub struct TaprootControlBlock {
    pub leaf_version: LeafVersion,
    pub parity: bool,
    pub internal_key: XOnlyPublicKey,
    pub merkle_proof: Vec<TapNodeHash>,
}

impl TaprootControlBlock {
    /// Create a new control block
    pub fn new(internal_key: XOnlyPublicKey, parity: bool, merkle_proof: Vec<TapNodeHash>) -> Self {
        Self {
            leaf_version: LeafVersion::TapScript,
            parity,
            internal_key,
            merkle_proof,
        }
    }

    /// Serialize the control block to bytes
    pub fn serialize(&self) -> Vec<u8> {
        let mut bytes = Vec::new();

        // Control byte: leaf version (0xc0) + parity bit
        let control_byte = self.leaf_version.to_consensus() | if self.parity { 1 } else { 0 };
        bytes.push(control_byte);

        // Internal key (32 bytes)
        bytes.extend_from_slice(&self.internal_key.serialize());

        // Merkle proof elements (if any)
        for node in &self.merkle_proof {
            bytes.extend_from_slice(node.as_ref());
        }

        bytes
    }
}

/// Generate a TapLeafHash from a script
fn taproot_leaf_hash(script: &ScriptBuf) -> TapLeafHash {
    TapLeafHash::from_script(script, LeafVersion::TapScript)
}

/// Create a basic TaprootBuilder with a single script
fn create_taproot_builder(script: &ScriptBuf) -> TaprootBuilder {
    TaprootBuilder::new()
        .add_leaf(0, script.clone())
        .expect("Valid leaf addition")
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

/// Create control block for script path spending
fn create_control_block(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    internal_key: &XOnlyPublicKey,
    leaf_script: &ScriptBuf,
) -> Result<TaprootControlBlock> {
    // Get the Taproot spend info which contains path information
    let spend_info = generate_spend_info(secp, internal_key, leaf_script)?;

    // Try to create a control block for this script
    let script_ver = (leaf_script.clone(), LeafVersion::TapScript);
    let control_block = spend_info
        .control_block(&script_ver)
        .ok_or_else(|| WalletError::BitcoinError("Failed to create control block".to_string()))?;

    // Extract merkle proof
    let merkle_proof: Vec<TapNodeHash> = match &control_block.merkle_branch {
        branch if !branch.is_empty() => branch.iter().cloned().collect(),
        _ => Vec::new(),
    };

    // Get parity from the spend info
    let parity = spend_info.output_key_parity() == bitcoin::key::Parity::Odd;

    Ok(TaprootControlBlock::new(
        *internal_key,
        parity,
        merkle_proof,
    ))
}

/// Compute signature for script path spending
fn compute_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    input: &PsbtInput,
    leaf_script: &ScriptBuf,
    secret_key: &SecretKey,
) -> Result<Vec<u8>> {
    // Get the sighash type
    let sighash_type = get_tap_sighash_type(input);

    // Get witness UTXO
    let witness_utxo = input.witness_utxo.as_ref().ok_or_else(|| {
        WalletError::BitcoinError(format!(
            "Missing witness UTXO for Taproot input at index {}",
            input_index
        ))
    })?;

    // Get the leaf hash
    let leaf_hash = taproot_leaf_hash(leaf_script);

    // Create Prevouts for the sighash calculation
    let utxos = [witness_utxo.clone()];
    let prevouts = Prevouts::All(&utxos);

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
    let mut sighash_bytes = [0u8; 32];
    let hash_bytes: &[u8] = sighash.as_ref();
    sighash_bytes.copy_from_slice(&hash_bytes[0..32]);
    let message = create_message_from_hash(&sighash_bytes)?;

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

fn add_witness(
    input: &mut PsbtInput,
    signature: Vec<u8>,
    leaf_script: &ScriptBuf,
    control_block: &TaprootControlBlock,
) -> Result<()> {
    // Create witness manually without using Witness::push
    // which can add unwanted length prefixes

    // Build witness directly as a series of elements
    let mut witness_elements = Vec::new();

    // Element 1: Signature
    witness_elements.push(signature);

    // Element 2: Script
    witness_elements.push(leaf_script.as_bytes().to_vec());

    // Element 3: Control block
    witness_elements.push(control_block.serialize());

    // Create witness from elements
    let witness = Witness::from_slice(&witness_elements);

    // Set witness data
    input.final_script_witness = Some(witness);

    // Set empty script_sig (required for SegWit)
    input.final_script_sig = Some(create_empty_script_sig());

    Ok(())
}

/// Signs a P2TR script path spending input
pub fn sign_psbt_input(
    sighash_cache: &mut SighashCache<&Transaction>,
    input: &mut PsbtInput,
    input_index: usize,
    secret_key: &SecretKey,
    public_key: &PublicKey,
    utxo: &UTXO,
) -> Result<()> {
    // Create a secp256k1 context
    let secp = bitcoin::key::Secp256k1::new();

    // Get XOnly pubkey from the source public key
    let xonly_pubkey = get_xonly_pubkey(public_key)?;

    // Get leaf script
    let leaf_script = utxo.leaf_script.as_ref().ok_or_else(|| {
        WalletError::BitcoinError("Missing leaf script for P2TR script path spending".to_string())
    })?;

    // Use the script_pubkey from the UTXO
    input.witness_utxo = Some(TxOut {
        value: Amount::from_sat(utxo.amount),
        script_pubkey: utxo.script_pubkey.clone(),
    });

    // Create control block for witness data
    let control_block = create_control_block(&secp, &xonly_pubkey, leaf_script)?;

    // Compute signature
    let signature = compute_signature(
        &secp,
        sighash_cache,
        input_index,
        input,
        leaf_script,
        secret_key,
    )?;

    // Add witness data
    add_witness(input, signature, leaf_script, &control_block)?;

    Ok(())
}
