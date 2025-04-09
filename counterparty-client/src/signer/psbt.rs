use bitcoin::amount::Amount;
use bitcoin::blockdata::transaction::TxOut;
use bitcoin::psbt::{Input as PsbtInput, Psbt};
use bitcoin::secp256k1::{Secp256k1, SecretKey};
use bitcoin::sighash::SighashCache;
use bitcoin::ScriptBuf;
use bitcoin::Transaction;
use bitcoin::{Network, PrivateKey, PublicKey};
use std::collections::HashMap;
use std::str::FromStr;

use crate::signer::address::{can_sign_input, determine_address_type};
use crate::signer::signature::{add_signature_to_input, compute_signature};
use crate::signer::taproot::try_sign_taproot_reveal;
use crate::signer::types::Result;
use crate::signer::utils::decode_script;
use crate::wallet::{AddressInfo, WalletError};
use crate::helpers;

/// Initialize signing context and signed_inputs vector
pub fn init_signing_context(input_count: usize) -> (Secp256k1<bitcoin::secp256k1::All>, Vec<bool>) {
    // Create secp256k1 context for signing
    let secp = Secp256k1::new();
    // Track which inputs were signed
    let signed_inputs = vec![false; input_count];

    (secp, signed_inputs)
}

/// Get the script_pubkey for an input
pub fn get_input_script_pubkey(psbt: &Psbt, input_index: usize) -> Option<ScriptBuf> {
    psbt.inputs
        .get(input_index)
        .and_then(|input| input.witness_utxo.as_ref())
        .map(|utxo| utxo.script_pubkey.clone())
}

/// Try sign a PSBT input with a private key if possible
pub fn try_sign_input(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input: &mut PsbtInput,
    input_index: usize,
    private_key: &PrivateKey,
    public_key: &PublicKey,
    address_type: &str,
    script_pubkey: &ScriptBuf,
    network: Network,
) -> Result<bool> {
    // Check if this key can sign this input
    if !can_sign_input(
        script_pubkey,
        public_key,
        address_type,
        Some(input),
        network,
    )? {
        return Ok(false);
    }

    // Clone the witness script if needed, to avoid borrowing issues
    let witness_script_clone = if address_type == "p2wsh" {
        input.witness_script.clone()
    } else {
        None
    };

    // Get secret key from private key
    let secret_key = SecretKey::from_slice(&private_key.inner[..])
        .map_err(|e| WalletError::BitcoinError(format!("Failed to create secret key: {:?}", e)))?;

    // Compute signature based on address type
    let signature_bytes = compute_signature(
        secp,
        sighash_cache,
        input_index,
        input,
        script_pubkey,
        &secret_key,
        public_key,
        address_type,
    )?;

    // Add the signature to the input
    add_signature_to_input(
        input,
        signature_bytes,
        public_key.to_bytes(),
        address_type,
        witness_script_clone.as_ref(),
    )?;

    Ok(true)
}

/// Prepare a single UTXO and add it to the PSBT input at a specific index
pub fn prepare_utxo_for_input(
    psbt: &mut Psbt,
    index: usize,
    script_hex: &str,
    amount: u64,
) -> Result<()> {
    let script = decode_script(script_hex, index)?;
    let address_type = determine_address_type(&script);

    if let Some(input) = psbt.inputs.get_mut(index) {
        // Add witness UTXO with correct amount
        input.witness_utxo = Some(TxOut {
            value: Amount::from_sat(amount),
            script_pubkey: script.clone(),
        });

        // Set appropriate sighash type based on address type
        let sighash_type = match address_type.as_str() {
            "p2tr" => bitcoin::sighash::TapSighashType::All.into(),
            _ => bitcoin::sighash::EcdsaSighashType::All.into(),
        };

        input.sighash_type = Some(sighash_type);
    }

    Ok(())
}

/// Add UTXOs to the PSBT inputs
pub fn add_utxos_to_psbt(psbt: &mut Psbt, utxos: &[(&str, u64)]) -> Result<()> {
    for (i, (script_hex, amount)) in utxos.iter().enumerate() {
        prepare_utxo_for_input(psbt, i, script_hex, *amount)?;
    }
    Ok(())
}

/// Handle Taproot reveal transaction signing
pub fn handle_taproot_reveal(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    psbt: &mut Psbt,
    signed_inputs: &mut [bool],
    addresses: &HashMap<String, AddressInfo>,
    envelope_script_hex: &str,
    source_addr: &str,
    network: Network,
) -> Result<()> {
    // Verify that the source address exists in the wallet
    let source_info = addresses
        .get(source_addr)
        .ok_or_else(|| WalletError::AddressNotFound(source_addr.to_string()))?;

    // Parse the envelope script
    let script_bytes = hex::decode(envelope_script_hex)
        .map_err(|e| WalletError::BitcoinError(format!("Invalid envelope script hex: {}", e)))?;
    let envelope_script = ScriptBuf::from_bytes(script_bytes);

    // Parse the private key for the source address
    let private_key = PrivateKey::from_str(&source_info.private_key).map_err(|e| {
        WalletError::BitcoinError(format!("Invalid private key for {}: {:?}", source_addr, e))
    })?;

    // Get the public key
    let public_key = PublicKey::from_private_key(&secp, &private_key);

    // Sign first input that require Taproot reveal signature
    let input = &mut psbt.inputs[0];
    match try_sign_taproot_reveal(
        &secp,
        sighash_cache,
        input,
        0,
        &private_key,
        &public_key,
        &envelope_script,
        network,
    ) {
        Ok(true) => {
            signed_inputs[0] = true;
            Ok(())
        }
        Ok(false) => Ok(()),
        Err(e) => Err(e),
    }
}

/// Handle regular transaction signing (non-Taproot-reveal)
pub fn handle_regular_signing(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    psbt: &mut Psbt,
    signed_inputs: &mut [bool],
    addresses: &HashMap<String, AddressInfo>,
    network: Network,
) -> Result<()> {
    // Try to sign each input with each key
    for (addr_str, info) in addresses {
        let private_key = match PrivateKey::from_str(&info.private_key) {
            Ok(pk) => pk,
            Err(e) => {
                return Err(WalletError::BitcoinError(format!(
                    "Invalid private key for {}: {:?}",
                    addr_str, e
                )));
            }
        };

        // Get the public key
        let public_key = PublicKey::from_private_key(&secp, &private_key);

        // Try to sign each input with this key
        for i in 0..psbt.inputs.len() {
            // Skip already signed inputs
            if signed_inputs[i] {
                continue;
            }

            // Get script pubkey for this input
            let script_pubkey = match get_input_script_pubkey(psbt, i) {
                Some(script) => script,
                None => {
                    helpers::print_warning("Warning: Input at index {} missing witness_utxo", Some(&i.to_string()));
                    continue;
                }
            };

            // Try normal signing for this input
            let input = &mut psbt.inputs[i];
            match try_sign_input(
                &secp,
                sighash_cache,
                input,
                i,
                &private_key,
                &public_key,
                &info.address_type,
                &script_pubkey,
                network,
            ) {
                Ok(true) => {
                    signed_inputs[i] = true;
                }
                Ok(false) => {
                    // Could not sign this input with this key
                }
                Err(e) => return Err(e),
            }
        }
    }

    Ok(())
}

/// Sign PSBT inputs with wallet private keys
pub fn sign_psbt_inputs(
    psbt: &mut Psbt,
    addresses: &HashMap<String, AddressInfo>,
    network: Network,
    envelope_script: Option<&str>,
    source_address: Option<&str>,
) -> Result<Vec<bool>> {
    // Initialize signing context
    let (secp, mut signed_inputs) = init_signing_context(psbt.inputs.len());

    // Create a SighashCache for computing signature hashes
    // Clone transaction to avoid borrowing conflict
    let unsigned_tx_clone = psbt.unsigned_tx.clone();
    let mut sighash_cache = SighashCache::new(&unsigned_tx_clone);

    // Handle Taproot reveal transaction if parameters are provided
    if let (Some(envelope_script_hex), Some(source_addr)) = (envelope_script, source_address) {
        handle_taproot_reveal(
            &secp,
            &mut sighash_cache,
            psbt,
            &mut signed_inputs,
            addresses,
            envelope_script_hex,
            source_addr,
            network,
        )?;
    }

    // Try normal signing for any remaining unsigned inputs
    handle_regular_signing(
        &secp,
        &mut sighash_cache,
        psbt,
        &mut signed_inputs,
        addresses,
        network,
    )?;

    Ok(signed_inputs)
}
