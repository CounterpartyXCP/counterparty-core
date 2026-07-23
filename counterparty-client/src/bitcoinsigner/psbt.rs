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
pub fn init_sighash_cache(tx: &Transaction) -> SighashCache<&Transaction> {
    SighashCache::new(tx)
}

/// Mutably borrow a PSBT input by index, mapping an out-of-bounds index to a
/// typed error instead of panicking.
pub(super) fn input_mut(psbt: &mut Psbt, index: usize) -> Result<&mut bitcoin::psbt::Input> {
    psbt.inputs
        .get_mut(index)
        .ok_or(WalletError::PsbtInputOutOfBounds(index))
}

/// Add witness UTXO to PSBT input.
///
/// This is set for *every* input, including legacy (P2PKH / legacy-P2SH) ones.
/// A BIP341 taproot sighash commits to the prevout of every input, so signing a
/// taproot input in a mixed transaction needs each input's `TxOut` — and
/// `witness_utxo` is where the signer reads them from (`sign_transaction`
/// collects the full prevout set here). It is technically PSBT-noncompliant to
/// put a `witness_utxo` on a legacy input, but this PSBT is finalized and
/// extracted in-process and never exported, so no external consumer sees it, and
/// we do not have the full previous transaction required for `non_witness_utxo`.
fn add_witness_utxo(
    psbt: &mut Psbt,
    index: usize,
    script_pubkey: ScriptBuf,
    amount: u64,
) -> Result<()> {
    // The per-input sighash type is intentionally left unset: the signers read it
    // via `get_ecdsa_sighash_type` / `get_tap_sighash_type`, which default to
    // `SIGHASH_ALL` for ECDSA and `SIGHASH_DEFAULT` for taproot. Seeding it to
    // `EcdsaSighashType::All` here would force taproot inputs onto `All` (0x01)
    // and produce non-standard 65-byte Schnorr signatures.
    input_mut(psbt, index)?.witness_utxo = Some(TxOut {
        value: Amount::from_sat(amount),
        script_pubkey,
    });
    Ok(())
}

/// Add redeem script to PSBT input
fn add_redeem_script(psbt: &mut Psbt, index: usize, redeem_script: &ScriptBuf) -> Result<()> {
    input_mut(psbt, index)?.redeem_script = Some(redeem_script.clone());
    Ok(())
}

/// Add witness script to PSBT input
fn add_witness_script(psbt: &mut Psbt, index: usize, witness_script: &ScriptBuf) -> Result<()> {
    input_mut(psbt, index)?.witness_script = Some(witness_script.clone());
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

/// Extract the final transaction from a PSBT and serialize it to hex.
///
/// Uses `extract_tx_unchecked_fee_rate`, which does *not* enforce rust-bitcoin's
/// default 25 000 sat/vB "absurd fee rate" guard. This client only finalizes a
/// transaction the composer already built, and the user reviews the decoded
/// outputs and fee before broadcasting; enforcing the broadcast-safety heuristic
/// here would turn a legitimate high-fee-rate signing request (e.g. a large
/// input swept into a tiny OP_RETURN) into an opaque `AbsurdFeeRate` failure.
pub fn extract_transaction(psbt: Psbt) -> Result<String> {
    let tx = psbt.extract_tx_unchecked_fee_rate();
    let tx_bytes = serialize(&tx);
    Ok(hex::encode(tx_bytes))
}

/// Check if a PSBT has all inputs finalized
pub fn is_psbt_finalized(psbt: &Psbt) -> bool {
    psbt.inputs
        .iter()
        .all(|input| input.final_script_sig.is_some() || input.final_script_witness.is_some())
}
