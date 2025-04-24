use bitcoin::secp256k1::{Secp256k1, SecretKey};
use bitcoin::Network;
use std::collections::HashMap;

use super::p2pkh;
use super::p2sh;
use super::p2trkps;
use super::p2trsps;
use super::p2wpkh;
use super::p2wsh;
use super::psbt::{
    create_psbt_from_raw, extract_transaction, init_sighash_cache, is_psbt_finalized,
};
use super::types::{Result, UTXOList, UTXOType, UTXO};
use crate::wallet::{AddressInfo, KeyService, WalletError};

/// Verify if the signature is successful by checking if the public key can sign the input
pub fn can_sign_input(
    script_pubkey: &bitcoin::ScriptBuf,
    public_key: &bitcoin::PublicKey,
    utxo_type: UTXOType,
    network: Network,
) -> Result<bool> {
    match utxo_type {
        UTXOType::P2PKH => {
            let address = bitcoin::Address::p2pkh(public_key, network);
            Ok(script_pubkey == &address.script_pubkey())
        }
        UTXOType::P2WPKH => {
            let compressed_key = super::common::get_compressed_pubkey(public_key)?;
            let address = bitcoin::Address::p2wpkh(&compressed_key, network);
            Ok(script_pubkey == &address.script_pubkey())
        }
        UTXOType::P2SH => {
            // For P2SH, we need the redeem script to verify
            // This is typically handled in the specific signing function
            Ok(false)
        }
        UTXOType::P2WSH => {
            // For P2WSH, we need the witness script to verify
            // This is typically handled in the specific signing function
            Ok(false)
        }
        UTXOType::P2TRKPS => {
            let secp = Secp256k1::verification_only();
            let xonly_pubkey = super::common::get_xonly_pubkey(public_key)?;
            let address = bitcoin::Address::p2tr(&secp, xonly_pubkey, None, network);
            Ok(script_pubkey == &address.script_pubkey())
        }
        UTXOType::P2TRSPS => {
            // For P2TR script path, this is handled in the specific signing function
            // We rely on the source_address field
            Ok(false)
        }
        UTXOType::Unknown => Ok(false),
    }
}

/// Track which inputs were successfully signed
fn track_inputs(input_count: usize) -> Vec<bool> {
    vec![false; input_count]
}

/// Sign a specific PSBT input based on UTXO type
fn sign_input_by_type(
    sighash_cache: &mut bitcoin::sighash::SighashCache<&bitcoin::Transaction>,
    psbt: &mut bitcoin::psbt::Psbt,
    input_index: usize,
    secret_key: &SecretKey,
    public_key: &bitcoin::PublicKey,
    utxo: &UTXO,
) -> Result<bool> {
    let utxo_type = utxo.get_type();

    match utxo_type {
        UTXOType::P2PKH => {
            p2pkh::sign_psbt_input(
                sighash_cache,
                &mut psbt.inputs[input_index],
                input_index,
                secret_key,
                public_key,
                utxo,
            )?;
            Ok(true)
        }
        UTXOType::P2WPKH => {
            p2wpkh::sign_psbt_input(
                sighash_cache,
                &mut psbt.inputs[input_index],
                input_index,
                secret_key,
                public_key,
                utxo,
            )?;
            Ok(true)
        }
        UTXOType::P2SH => {
            p2sh::sign_psbt_input(
                sighash_cache,
                &mut psbt.inputs[input_index],
                input_index,
                secret_key,
                public_key,
                utxo,
            )?;
            Ok(true)
        }
        UTXOType::P2WSH => {
            p2wsh::sign_psbt_input(
                sighash_cache,
                &mut psbt.inputs[input_index],
                input_index,
                secret_key,
                public_key,
                utxo,
            )?;
            Ok(true)
        }
        UTXOType::P2TRKPS => {
            p2trkps::sign_psbt_input(
                sighash_cache,
                &mut psbt.inputs[input_index],
                input_index,
                secret_key,
                public_key,
                utxo,
            )?;
            Ok(true)
        }
        UTXOType::P2TRSPS => {
            p2trsps::sign_psbt_input(
                sighash_cache,
                &mut psbt.inputs[input_index],
                input_index,
                secret_key,
                public_key,
                utxo,
            )?;
            Ok(true)
        }
        UTXOType::Unknown => {
            // Skip unknown UTXO types
            Ok(false)
        }
    }
}

/// Find matching address info from the wallet for a UTXO
fn find_address_for_utxo<'a>(
    addresses: &'a HashMap<String, AddressInfo>,
    utxo: &'a UTXO,
    network: Network,
) -> Result<Option<(&'a String, &'a AddressInfo)>> {
    // For P2TR script path spending, use the source address
    if utxo.get_type() == UTXOType::P2TRSPS {
        if let Some(source_address) = &utxo.source_address {
            if let Some(addr_info) = addresses.get(source_address) {
                return Ok(Some((source_address, addr_info)));
            } else {
                return Err(WalletError::AddressNotFound(source_address.clone()));
            }
        }
    }

    // Try to find an address in our wallet that matches the script_pubkey
    for (addr_str, addr_info) in addresses {
        // Get the public key from the private key securely
        let public_key = KeyService::get_public_key(&addr_info.private_key, network)?;

        // Check if this key can sign the input
        if can_sign_input(&utxo.script_pubkey, &public_key, utxo.get_type(), network)? {
            return Ok(Some((addr_str, addr_info)));
        }
    }

    // No matching address found
    Ok(None)
}

/// Sign a transaction using wallet addresses
///
/// # Arguments
///
/// * `addresses` - Wallet addresses and their information
/// * `raw_tx_hex` - Raw unsigned transaction in hex format
/// * `utxos` - List of UTXOs corresponding to transaction inputs
/// * `network` - Bitcoin network (mainnet, testnet, etc.)
///
/// # Returns
///
/// * `Result<String>` - Signed transaction in hex format
pub fn sign_transaction(
    addresses: &HashMap<String, AddressInfo>,
    raw_tx_hex: &str,
    utxos: &UTXOList,
    network: Network,
) -> Result<String> {
    // Create PSBT from raw transaction
    let mut psbt = create_psbt_from_raw(raw_tx_hex, utxos)?;

    // Initialize the signature cache
    let tx_clone = psbt.unsigned_tx.clone();
    let mut sighash_cache = init_sighash_cache(&tx_clone);

    // Track which inputs were signed
    let mut signed_inputs = track_inputs(psbt.inputs.len());

    // Try to sign each input
    for i in 0..psbt.inputs.len() {
        let utxo = utxos
            .get(i)
            .ok_or_else(|| WalletError::BitcoinError(format!("Missing UTXO for input {}", i)))?;

        // Find a matching address in our wallet
        match find_address_for_utxo(addresses, utxo, network)? {
            Some((_addr_str, addr_info)) => {
                // Use KeyService to sign without exposing the private key
                let input_index = i; // Capture for the closure
                let input_signed = KeyService::sign_with_key(
                    &addr_info.private_key,
                    network,
                    |secret_key, public_key| {
                        // Sign the input within the closure
                        sign_input_by_type(
                            &mut sighash_cache,
                            &mut psbt,
                            input_index,
                            secret_key,
                            public_key,
                            utxo,
                        )
                    },
                )?;

                if input_signed {
                    signed_inputs[i] = true;
                }
            }
            None => {
                // No matching address found for this input
            }
        }
    }

    // Check if any inputs were signed
    if !signed_inputs.iter().any(|&signed| signed) {
        return Err(WalletError::BitcoinError(
            "No inputs could be signed with the provided addresses".to_string(),
        ));
    }

    // Check for unsigned inputs
    let unsigned_indices: Vec<usize> = signed_inputs
        .iter()
        .enumerate()
        .filter(|(_, &signed)| !signed)
        .map(|(i, _)| i)
        .collect();

    if !unsigned_indices.is_empty() {
        return Err(WalletError::BitcoinError(format!(
            "Could not sign inputs at indices: {:?}",
            unsigned_indices
        )));
    }

    // Check if the PSBT is finalized
    if !is_psbt_finalized(&psbt) {
        return Err(WalletError::BitcoinError(
            "Not all inputs were properly finalized".to_string(),
        ));
    }

    // Extract and serialize the final transaction
    extract_transaction(psbt)
}
