use bitcoin::secp256k1::{Secp256k1, SecretKey};
use bitcoin::Network;
use std::collections::HashMap;

use super::common::bitcoin_err;
use super::p2pkh::P2PKHSigner;
use super::p2sh::P2SHSigner;
use super::p2trkps::P2TRKPSSigner;
use super::p2trsps::P2TRSPSSigner;
use super::p2wpkh::P2WPKHSigner;
use super::p2wsh::P2WSHSigner;
use super::psbt::{
    create_psbt_from_raw, extract_transaction, init_sighash_cache, is_psbt_finalized,
};
use super::types::{InputSigner, Result, UTXOList, UTXOType, UTXO};
use crate::wallet::{AddressInfo, KeyService, WalletError};

/// Check if a given public key can sign for a specific UTXO type and script
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
        UTXOType::P2TRKPS => {
            let secp = Secp256k1::verification_only();
            let xonly_pubkey = super::common::get_xonly_pubkey(public_key)?;
            let address = bitcoin::Address::p2tr(&secp, xonly_pubkey, None, network);
            Ok(script_pubkey == &address.script_pubkey())
        }
        // Script-based address types need more context to verify
        UTXOType::P2SH | UTXOType::P2WSH | UTXOType::P2TRSPS | UTXOType::Unknown => Ok(false),
    }
}

/// Sign a specific PSBT input using the appropriate InputSigner
fn sign_input_by_type(
    sighash_cache: &mut bitcoin::sighash::SighashCache<&bitcoin::Transaction>,
    psbt: &mut bitcoin::psbt::Psbt,
    input_index: usize,
    secret_key: &SecretKey,
    public_key: &bitcoin::PublicKey,
    utxo: &UTXO,
) -> Result<bool> {
    let utxo_type = utxo.get_type();
    let input = &mut psbt.inputs[input_index];

    // Use the appropriate signer based on UTXO type
    match utxo_type {
        UTXOType::P2PKH => {
            P2PKHSigner::sign_input(
                sighash_cache,
                input,
                input_index,
                secret_key,
                public_key,
                utxo,
            )?;
            Ok(true)
        }
        UTXOType::P2WPKH => {
            P2WPKHSigner::sign_input(
                sighash_cache,
                input,
                input_index,
                secret_key,
                public_key,
                utxo,
            )?;
            Ok(true)
        }
        UTXOType::P2SH => {
            P2SHSigner::sign_input(
                sighash_cache,
                input,
                input_index,
                secret_key,
                public_key,
                utxo,
            )?;
            Ok(true)
        }
        UTXOType::P2WSH => {
            P2WSHSigner::sign_input(
                sighash_cache,
                input,
                input_index,
                secret_key,
                public_key,
                utxo,
            )?;
            Ok(true)
        }
        UTXOType::P2TRKPS => {
            P2TRKPSSigner::sign_input(
                sighash_cache,
                input,
                input_index,
                secret_key,
                public_key,
                utxo,
            )?;
            Ok(true)
        }
        UTXOType::P2TRSPS => {
            P2TRSPSSigner::sign_input(
                sighash_cache,
                input,
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

/// Find matching address info from the wallet for a specific UTXO
fn find_address_for_utxo<'a>(
    addresses: &'a HashMap<String, AddressInfo>,
    utxo: &'a UTXO,
    network: Network,
) -> Result<Option<(&'a String, &'a AddressInfo)>> {
    // Special case for P2TR script path spending - use the provided source address
    if utxo.get_type() == UTXOType::P2TRSPS {
        if let Some(source_address) = &utxo.source_address {
            // Wrap the result in Some() to match the return type
            if let Some(addr_info) = addresses.get(source_address) {
                return Ok(Some((source_address, addr_info)));
            } else {
                return Err(WalletError::AddressNotFound(source_address.clone()));
            }
        }
    }

    // For other types, try to find a matching address in our wallet
    for (addr_str, addr_info) in addresses {
        // Get the public key from the address info
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
    let mut signed_inputs = vec![false; psbt.inputs.len()];

    // Try to sign each input
    for i in 0..psbt.inputs.len() {
        let utxo = utxos
            .get(i)
            .ok_or_else(|| bitcoin_err(format!("Missing UTXO for input {}", i)))?;

        // Find a matching address in our wallet
        match find_address_for_utxo(addresses, utxo, network)? {
            Some((_addr_str, addr_info)) => {
                // Use KeyService to sign with the private key
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

    // Verify signing results
    if !signed_inputs.iter().any(|&signed| signed) {
        return Err(bitcoin_err(
            "No inputs could be signed with the provided addresses",
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
        return Err(bitcoin_err(format!(
            "Could not sign inputs at indices: {:?}",
            unsigned_indices
        )));
    }

    // Check if the PSBT is properly finalized
    if !is_psbt_finalized(&psbt) {
        return Err(bitcoin_err("Not all inputs were properly finalized"));
    }

    // Extract and serialize the final transaction
    extract_transaction(psbt)
}
