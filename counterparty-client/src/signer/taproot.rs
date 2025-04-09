use bitcoin::secp256k1::{Secp256k1, SecretKey, Keypair};
use bitcoin::ScriptBuf;
use bitcoin::{Address, Network};
use bitcoin::blockdata::witness::Witness;
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::sighash::{SighashCache, TapSighashType};
use bitcoin::taproot::{LeafVersion, TapLeafHash, TapNodeHash, TaprootBuilder, TaprootSpendInfo};
use bitcoin::Transaction;
use bitcoin::XOnlyPublicKey;

use crate::signer::types::Result;
use crate::signer::utils::{create_message_from_hash, create_empty_script_sig, get_xonly_pubkey};
use crate::signer::verification::verify_schnorr_signature;
use crate::wallet::WalletError;

/// Structure to hold Taproot control block data
pub struct TaprootControlBlock {
    /// The leaf version of the executed script
    pub leaf_version: LeafVersion,
    /// Indicates if the output key's y-coordinate is odd
    pub parity: bool,
    /// The internal key (source public key)
    pub internal_key: XOnlyPublicKey,
    /// Merkle proof for the script path
    pub merkle_proof: Vec<TapNodeHash>,
}

impl TaprootControlBlock {
    /// Create a control block for a Taproot script path spend
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
            // Safely convert TapNodeHash to bytes
            bytes.extend_from_slice(node.as_ref());
        }

        bytes
    }
}

/// Generate a TapLeafHash from a script
pub fn taproot_leaf_hash(script: &ScriptBuf) -> TapLeafHash {
    TapLeafHash::from_script(script, LeafVersion::TapScript)
}

/// Create a basic TaprootBuilder with a single script
pub fn create_taproot_builder(script: &ScriptBuf) -> TaprootBuilder {
    TaprootBuilder::new()
        .add_leaf(0, script.clone())
        .expect("Valid leaf addition")
}

/// Generate Taproot spending information with the provided internal key and script
pub fn generate_taproot_spend_info(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    internal_key: &XOnlyPublicKey,
    script: &ScriptBuf,
) -> Result<TaprootSpendInfo> {
    let builder = create_taproot_builder(script);

    builder.finalize(secp, *internal_key).map_err(|e| {
        WalletError::BitcoinError(format!("Failed to create Taproot spend info: {:?}", e))
    })
}

/// Create control block for a Taproot script path spend
pub fn create_taproot_control_block(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    internal_key: &XOnlyPublicKey,
    envelope_script: &ScriptBuf,
) -> Result<TaprootControlBlock> {
    // Get the Taproot spend info which contains path information
    let spend_info = generate_taproot_spend_info(secp, internal_key, envelope_script)?;

    // Try to create a control block for this script
    let script_ver = (envelope_script.clone(), LeafVersion::TapScript);
    let control_block = spend_info
        .control_block(&script_ver)
        .ok_or_else(|| WalletError::BitcoinError("Failed to create control block".to_string()))?;

    // Extract merkle proof
    let merkle_proof: Vec<TapNodeHash> = match &control_block.merkle_branch {
        branch if !branch.is_empty() => branch.iter().cloned().collect(),
        _ => Vec::new(), // Fallback to empty vector if field access doesn't work
    };

    // Get parity from the spend info
    let parity = spend_info.output_key_parity() == bitcoin::key::Parity::Odd;

    Ok(TaprootControlBlock::new(
        *internal_key,
        parity,
        merkle_proof,
    ))
}

/// Generate a taproot commit address with the given public key and script
pub fn generate_taproot_commit_address(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    source_key: &XOnlyPublicKey,
    envelope_script: &ScriptBuf,
    network: Network,
) -> Result<Address> {
    // Create taproot builder with the script
    let builder = create_taproot_builder(envelope_script);

    // Finalize to get the taproot spend info
    let taproot_spend_info = builder.finalize(secp, *source_key).map_err(|e| {
        WalletError::BitcoinError(format!("Failed to create taproot spend info: {:?}", e))
    })?;

    // Get the output key
    let output_key = taproot_spend_info.output_key();

    // Create the taproot address
    let address = Address::p2tr(secp, output_key.to_inner(), None, network);
    Ok(address)
}

/// Compute Taproot script path signature
pub fn compute_taproot_script_path_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    input: &PsbtInput,
    envelope_script: &ScriptBuf,
    secret_key: &SecretKey,
) -> Result<Vec<u8>> {
    // Get witness UTXO safely with error handling
    let witness_utxo = input.witness_utxo.as_ref().ok_or_else(|| {
        WalletError::BitcoinError(format!(
            "Missing witness UTXO for Taproot input at index {}",
            input_index
        ))
    })?;

    // For Taproot, use the appropriate sighash algorithm from input or default to All
    let sighash_type = match input.sighash_type {
        Some(s) => s.taproot_hash_ty().unwrap_or(TapSighashType::All),
        None => TapSighashType::All,
    };

    // Get the leaf hash for our script
    let leaf_hash = taproot_leaf_hash(envelope_script);

    // Create a binding for the array so it lives long enough
    let utxo_array = [witness_utxo.clone()];
    let prevouts = bitcoin::sighash::Prevouts::All(&utxo_array);

    // Compute the script path sighash
    let sighash = sighash_cache
        .taproot_script_spend_signature_hash(input_index, &prevouts, leaf_hash, sighash_type)
        .map_err(|e| {
            WalletError::BitcoinError(format!(
                "Failed to compute Taproot script path signature hash: {}",
                e
            ))
        })?;

    // Create a message from the sighash
    let message = create_message_from_hash(&sighash[..])?;

    // Convert SecretKey to Keypair for Schnorr signing
    let keypair = Keypair::from_secret_key(&secp, &secret_key);

    // Get the XOnly pubkey directly from the keypair
    let xonly_pubkey = XOnlyPublicKey::from_keypair(&keypair).0;

    // Create schnorr signature with the keypair
    let schnorr_sig = secp.sign_schnorr_no_aux_rand(&message, &keypair);

    let mut sig_bytes = schnorr_sig.as_ref().to_vec();

    // Add sighash byte for Taproot if not ALL
    if sighash_type != TapSighashType::All {
        sig_bytes.push(sighash_type as u8);
    }

    // Verify signature
    verify_schnorr_signature(secp, &message, &schnorr_sig, &xonly_pubkey)?;

    Ok(sig_bytes)
}

/// Add Taproot script path witness data to the input
pub fn add_taproot_script_path_witness(
    input: &mut PsbtInput,
    signature_bytes: Vec<u8>,
    envelope_script: &ScriptBuf,
    control_block: &TaprootControlBlock,
) -> Result<()> {
    let mut witness = Witness::new();

    // Add signature
    witness.push(signature_bytes);

    // Add the script that we're revealing
    witness.push(envelope_script.as_bytes());

    // Add the control block
    witness.push(control_block.serialize());

    input.final_script_witness = Some(witness);

    // Empty script_sig for segwit
    input.final_script_sig = Some(create_empty_script_sig());

    Ok(())
}

/// Try to sign a taproot input for reveal transaction
pub fn try_sign_taproot_reveal(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input: &mut PsbtInput,
    input_index: usize,
    private_key: &bitcoin::PrivateKey,
    public_key: &bitcoin::PublicKey,
    envelope_script: &ScriptBuf,
    network: Network,
) -> Result<bool> {
    // Get the XOnly public key from the full public key
    let xonly_pubkey = get_xonly_pubkey(public_key)?;

    // Get secret key from private key
    let secret_key = SecretKey::from_slice(&private_key.inner[..])
        .map_err(|e| WalletError::BitcoinError(format!("Failed to create secret key: {:?}", e)))?;

    // Generate the taproot commit address for the given key and script
    // This is the address that was used in the commit transaction
    let commit_address =
        generate_taproot_commit_address(secp, &xonly_pubkey, envelope_script, network)?;

    // Ensure the witness UTXO is using the correct script_pubkey from the commit address
    // This is crucial for correct signature verification
    let commit_script_pubkey = commit_address.script_pubkey();

    // Update the witness UTXO with the correct script_pubkey if it exists
    if let Some(witness_utxo) = &mut input.witness_utxo {
        witness_utxo.script_pubkey = commit_script_pubkey.clone();
    } else {
        // If there's no witness UTXO, create one with the commit script pubkey
        // We'll need to extract the value from the current input
        let value = match &input.witness_utxo {
            Some(utxo) => utxo.value,
            None => {
                return Err(WalletError::BitcoinError(
                    "Missing witness UTXO for Taproot reveal input".to_string(),
                ))
            }
        };

        input.witness_utxo = Some(bitcoin::blockdata::transaction::TxOut {
            value,
            script_pubkey: commit_script_pubkey.clone(),
        });
    }

    // Compute the signature using the script path
    // Note: We're using the updated witness UTXO with the correct script_pubkey
    let signature_bytes = compute_taproot_script_path_signature(
        secp,
        sighash_cache,
        input_index,
        input,
        envelope_script,
        &secret_key,
    )?;

    // Create control block for witness data
    let control_block = create_taproot_control_block(secp, &xonly_pubkey, envelope_script)?;

    // Add the witness data to the input
    add_taproot_script_path_witness(input, signature_bytes, envelope_script, &control_block)?;

    Ok(true)
}