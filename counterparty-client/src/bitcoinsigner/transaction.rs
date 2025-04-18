use bitcoin::Network;
use bitcoin::secp256k1::{Secp256k1, SecretKey};
use std::collections::HashMap;

use super::p2pkh;
use super::p2wpkh;
use super::p2sh;
use super::p2wsh;
use super::p2trkps;
use super::p2trsps;
use super::psbt::{create_psbt_from_raw, extract_transaction, init_sighash_cache, is_psbt_finalized};
use super::types::{Result, UTXO, UTXOList, UTXOType};
use super::utils::{parse_private_key, get_public_key};
use crate::wallet::{AddressInfo, WalletError};

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
    network: Network,
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
        },
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
        },
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
        },
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
        },
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
        },
        UTXOType::P2TRSPS => {
            p2trsps::sign_psbt_input(
                sighash_cache,
                &mut psbt.inputs[input_index],
                input_index,
                secret_key,
                public_key,
                utxo,
                network,
            )?;
            Ok(true)
        },
        UTXOType::Unknown => {
            // Skip unknown UTXO types
            Ok(false)
        },
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
        // Parse the private key to get the public key
        let private_key = parse_private_key(&addr_info.private_key, network)?;
        let secp = Secp256k1::new();
        let public_key = get_public_key(&secp, &private_key);
        
        // Check if this key can sign the input
        if super::utils::can_sign_input(&utxo.script_pubkey, &public_key, utxo.get_type(), network)? {
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
/// * Signed transaction in hex format
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
        let utxo = utxos.get(i).ok_or_else(|| {
            WalletError::BitcoinError(format!("Missing UTXO for input {}", i))
        })?;
        
        // Find a matching address in our wallet
        match find_address_for_utxo(addresses, utxo, network)? {
            Some((_addr_str, addr_info)) => {
                // Parse the private key
                let private_key = parse_private_key(&addr_info.private_key, network)?;
                
                // Get the public key
                let secp = Secp256k1::new();
                let public_key = get_public_key(&secp, &private_key);
                
                // Try to sign the input
                match sign_input_by_type(
                    &mut sighash_cache,
                    &mut psbt,
                    i,
                    &SecretKey::from_slice(&private_key.inner[..])
                        .map_err(|e| WalletError::BitcoinError(format!("Invalid private key: {}", e)))?,
                    &public_key,
                    utxo,
                    network,
                ) {
                    Ok(true) => {
                        signed_inputs[i] = true;
                    },
                    Ok(false) => {
                        // Could not sign this input with this key
                    },
                    Err(e) => {
                        return Err(e);
                    },
                }
            },
            None => {
                // No matching address found for this input
            },
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
