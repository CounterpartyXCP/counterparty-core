use bitcoin::amount::Amount;
use bitcoin::blockdata::transaction::TxOut;
use bitcoin::consensus::{deserialize, serialize};
use bitcoin::psbt::Psbt;
use bitcoin::sighash::SighashCache;
use bitcoin::{ScriptBuf, Transaction};

use super::types::{Result, UTXOList};
use crate::wallet::WalletError;

/// Convert hex string to bytes
pub fn hex_to_bytes(hex_str: &str) -> Result<Vec<u8>> {
    hex::decode(hex_str)
        .map_err(|e| WalletError::BitcoinError(format!("Invalid hex string: {}", e)))
}

/// Parse a raw transaction from hexadecimal format
pub fn parse_transaction(raw_tx_hex: &str) -> Result<Transaction> {
    let tx_bytes = hex_to_bytes(raw_tx_hex)?;

    deserialize(&tx_bytes)
        .map_err(|e| WalletError::BitcoinError(format!("Invalid transaction format: {}", e)))
}

/// Create a PSBT from an unsigned transaction
pub fn create_psbt(tx: Transaction) -> Result<Psbt> {
    Psbt::from_unsigned_tx(tx)
        .map_err(|e| WalletError::BitcoinError(format!("Failed to create PSBT: {}", e)))
}

/// Initialize sighash cache for signature calculations
pub fn init_sighash_cache<'a>(tx: &'a Transaction) -> SighashCache<&'a Transaction> {
    SighashCache::new(tx)
}

/// Add witness UTXO to PSBT input
fn add_witness_utxo(
    psbt: &mut Psbt,
    index: usize,
    script_pubkey: ScriptBuf,
    amount: u64,
) -> Result<()> {
    if let Some(input) = psbt.inputs.get_mut(index) {
        input.witness_utxo = Some(TxOut {
            value: Amount::from_sat(amount),
            script_pubkey,
        });

        // Set default sighash type if not already set
        if input.sighash_type.is_none() {
            input.sighash_type = Some(bitcoin::sighash::EcdsaSighashType::All.into());
        }
    } else {
        return Err(WalletError::BitcoinError(format!(
            "PSBT input index {} out of bounds",
            index
        )));
    }

    Ok(())
}

/// Add redeem script to PSBT input
fn add_redeem_script(psbt: &mut Psbt, index: usize, redeem_script: &ScriptBuf) -> Result<()> {
    if let Some(input) = psbt.inputs.get_mut(index) {
        input.redeem_script = Some(redeem_script.clone());
    } else {
        return Err(WalletError::BitcoinError(format!(
            "PSBT input index {} out of bounds",
            index
        )));
    }

    Ok(())
}

/// Add witness script to PSBT input
fn add_witness_script(psbt: &mut Psbt, index: usize, witness_script: &ScriptBuf) -> Result<()> {
    if let Some(input) = psbt.inputs.get_mut(index) {
        input.witness_script = Some(witness_script.clone());
    } else {
        return Err(WalletError::BitcoinError(format!(
            "PSBT input index {} out of bounds",
            index
        )));
    }

    Ok(())
}

/// Add all UTXOs to PSBT inputs
fn add_utxos_to_psbt(psbt: &mut Psbt, utxos: &UTXOList) -> Result<()> {
    // Check if the number of inputs and UTXOs match
    if psbt.inputs.len() != utxos.len() {
        return Err(WalletError::BitcoinError(format!(
            "Number of PSBT inputs ({}) does not match number of UTXOs ({})",
            psbt.inputs.len(),
            utxos.len()
        )));
    }

    // Add each UTXO to the corresponding PSBT input
    for (i, utxo) in utxos.as_ref().iter().enumerate() {
        // Add witness UTXO
        add_witness_utxo(psbt, i, utxo.script_pubkey.clone(), utxo.amount)?;

        // Add redeem script if present
        if let Some(redeem_script) = &utxo.redeem_script {
            add_redeem_script(psbt, i, redeem_script)?;
        }

        // Add witness script if present
        if let Some(witness_script) = &utxo.witness_script {
            add_witness_script(psbt, i, witness_script)?;
        }
    }

    Ok(())
}

/// Create a PSBT from a raw transaction hex and UTXOs
pub fn create_psbt_from_raw(raw_tx_hex: &str, utxos: &UTXOList) -> Result<Psbt> {
    // Parse the raw transaction
    let tx = parse_transaction(raw_tx_hex)?;

    // Create a PSBT from the transaction
    let mut psbt = create_psbt(tx)?;

    // Add UTXOs to the PSBT
    add_utxos_to_psbt(&mut psbt, utxos)?;

    Ok(psbt)
}

/// Extract the final transaction from a PSBT and serialize it to hex
pub fn extract_transaction(psbt: Psbt) -> Result<String> {
    let tx = psbt.extract_tx().map_err(|e| {
        WalletError::BitcoinError(format!("Failed to extract transaction: {:?}", e))
    })?;

    let tx_bytes = serialize(&tx);
    let tx_hex = hex::encode(tx_bytes);

    Ok(tx_hex)
}

/// Check if a PSBT has all inputs finalized
pub fn is_psbt_finalized(psbt: &Psbt) -> bool {
    psbt.inputs
        .iter()
        .all(|input| input.final_script_sig.is_some() || input.final_script_witness.is_some())
}
