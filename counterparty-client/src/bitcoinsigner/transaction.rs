use bitcoin::secp256k1::SecretKey;
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
) -> Result<(&'a String, &'a AddressInfo)> {
    // If the UTXO has a source_address, use it directly
    if let Some(source_address) = &utxo.source_address {
        if let Some(addr_info) = addresses.get(source_address) {
            return Ok((source_address, addr_info));
        } else {
            return Err(WalletError::AddressNotFound(source_address.clone()));
        }
    }

    // Otherwise, convert the script_pubkey to an address
    let address = bitcoin::Address::from_script(&utxo.script_pubkey, network).map_err(|_| {
        WalletError::BitcoinError(format!(
            "Could not convert script_pubkey to address for type {:?}",
            utxo.get_type()
        ))
    })?;

    let address_str = address.to_string();

    // Look for this address in our wallet
    for (addr_str, addr_info) in addresses {
        if addr_str == &address_str {
            return Ok((addr_str, addr_info));
        }
    }

    // No matching address found
    Err(WalletError::AddressNotFound(address_str))
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

        // Find a matching address in our wallet - handle the error case separately
        let result = find_address_for_utxo(addresses, utxo, network);
        match result {
            Ok((_addr_str, addr_info)) => {
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
            Err(e) => return Err(e), // Propagate errors
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
