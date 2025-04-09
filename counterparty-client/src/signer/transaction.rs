use bitcoin::consensus::{deserialize, serialize};
use bitcoin::psbt::Psbt;
use bitcoin::Network;
use bitcoin::Transaction;
use std::collections::HashMap;

use crate::signer::psbt::{add_utxos_to_psbt, sign_psbt_inputs};
use crate::signer::types::Result;
use crate::wallet::{AddressInfo, WalletError};

/// Parse a raw transaction from hexadecimal format
pub fn parse_transaction(raw_tx_hex: &str) -> Result<Transaction> {
    let tx_bytes = hex::decode(raw_tx_hex)
        .map_err(|e| WalletError::BitcoinError(format!("Invalid transaction hex: {}", e)))?;

    deserialize(&tx_bytes)
        .map_err(|e| WalletError::BitcoinError(format!("Invalid transaction format: {}", e)))
}

/// Create a PSBT from an unsigned transaction
pub fn create_psbt(tx: Transaction) -> Result<Psbt> {
    Psbt::from_unsigned_tx(tx)
        .map_err(|e| WalletError::BitcoinError(format!("Failed to create PSBT: {}", e)))
}

/// Extract and serialize the final transaction
pub fn extract_and_serialize_transaction(psbt: Psbt) -> Result<String> {
    let finalized_tx = psbt.extract_tx().map_err(|e| {
        WalletError::BitcoinError(format!("Failed to extract transaction: {:?}", e))
    })?;

    // Serialize to hex
    let signed_tx_bytes = serialize(&finalized_tx);
    let signed_tx_hex = hex::encode(signed_tx_bytes);

    Ok(signed_tx_hex)
}

/// Sign a raw Bitcoin transaction with a specific network (simple version)
///
/// This is a convenience function that calls the more comprehensive signing function
/// with default values (None) for Taproot reveal parameters.
///
/// # Arguments
///
/// * `addresses` - HashMap of addresses and their information
/// * `raw_tx_hex` - Unsigned transaction in hexadecimal format
/// * `utxos` - Vector of (script_pubkey_hex, amount_in_satoshis) pairs for each input
/// * `network` - Bitcoin network to use
///
/// # Returns
///
/// * `Result<String>` - Signed transaction in hexadecimal format or error
pub fn sign_transaction(
    addresses: &HashMap<String, AddressInfo>,
    raw_tx_hex: &str,
    utxos: Vec<(&str, u64)>,
    network: Network,
) -> Result<String> {
    sign_reveal_transaction(addresses, raw_tx_hex, utxos, network, None, None)
}

/// Sign a raw Bitcoin transaction with a specific network, supporting Taproot reveal
///
/// This function signs an unsigned transaction with private keys from the wallet.
/// It supports P2PKH, P2WPKH (bech32), P2SH-P2WPKH, P2WSH, and P2TR inputs.
/// For Taproot reveal transactions, it can also sign using script path spending
/// with the provided envelope script and source address.
///
/// # Arguments
///
/// * `addresses` - HashMap of addresses and their information
/// * `raw_tx_hex` - Unsigned transaction in hexadecimal format
/// * `utxos` - Vector of (script_pubkey_hex, amount_in_satoshis) pairs for each input
/// * `network` - Bitcoin network to use
/// * `envelope_script` - Optional envelope script hex for Taproot reveal transactions
/// * `source_address` - Optional source address for Taproot reveal transactions
///
/// # Returns
///
/// * `Result<String>` - Signed transaction in hexadecimal format or error
pub fn sign_reveal_transaction(
    addresses: &HashMap<String, AddressInfo>,
    raw_tx_hex: &str,
    utxos: Vec<(&str, u64)>,
    network: Network,
    envelope_script: Option<&str>,
    source_address: Option<&str>,
) -> Result<String> {
    // Parse the raw transaction
    let tx = parse_transaction(raw_tx_hex)?;

    // Validate input count
    if tx.input.len() != utxos.len() {
        return Err(WalletError::BitcoinError(format!(
            "Number of UTXOs ({}) does not match number of inputs ({})",
            utxos.len(),
            tx.input.len()
        )));
    }

    // Create a PSBT from the transaction
    let mut psbt = create_psbt(tx)?;

    // Add UTXOs to the PSBT inputs
    add_utxos_to_psbt(&mut psbt, &utxos)?;

    // Sign PSBT inputs with wallet keys
    let signed_inputs = sign_psbt_inputs(
        &mut psbt,
        addresses,
        network,
        envelope_script,
        source_address,
    )?;

    // Check if any inputs were signed
    if !signed_inputs.iter().any(|&signed| signed) {
        return Err(WalletError::BitcoinError(
            "No inputs could be signed with keys in this wallet".to_string(),
        ));
    }

    // Check for unsigned inputs - now return an error if any input remains unsigned
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

    // Extract and serialize the final transaction
    extract_and_serialize_transaction(psbt)
}
