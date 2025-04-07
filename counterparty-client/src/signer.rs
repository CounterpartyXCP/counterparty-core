use std::str::FromStr;
use std::collections::HashMap;

use bitcoin::amount::Amount;
use bitcoin::secp256k1::Secp256k1;
use bitcoin::secp256k1::Message;
use bitcoin::ScriptBuf;
use bitcoin::{Address, Network, PrivateKey, PublicKey};

use bitcoin::blockdata::script::{Builder, PushBytesBuf};
use bitcoin::blockdata::transaction::TxOut;
use bitcoin::consensus::{deserialize, serialize};
use bitcoin::psbt::Psbt;
use bitcoin::sighash::{EcdsaSighashType, SighashCache};
use bitcoin::TapSighashType;
use bitcoin::Transaction;

use crate::wallet::WalletError;
use crate::wallet::AddressInfo;


type Result<T> = std::result::Result<T, WalletError>;

/// Parse a raw transaction from hexadecimal format
fn parse_transaction(raw_tx_hex: &str) -> Result<Transaction> {
    // Parse the raw transaction
    let tx_bytes = hex::decode(raw_tx_hex)
        .map_err(|e| WalletError::BitcoinError(format!("Invalid transaction hex: {}", e)))?;

    let tx: Transaction = deserialize(&tx_bytes)
        .map_err(|e| WalletError::BitcoinError(format!("Invalid transaction format: {}", e)))?;

    Ok(tx)
}

/// Create a PSBT from an unsigned transaction
fn create_psbt(tx: Transaction) -> Result<Psbt> {
    Psbt::from_unsigned_tx(tx)
        .map_err(|e| WalletError::BitcoinError(format!("Failed to create PSBT: {}", e)))
}

/// Decode a script hex string into a ScriptBuf
fn decode_script(script_hex: &str, index: usize) -> Result<ScriptBuf> {
    let script_bytes = hex::decode(script_hex)
        .map_err(|e| WalletError::BitcoinError(
            format!("Invalid script_pubkey hex at index {}: {}", index, e)
        ))?;

    Ok(ScriptBuf::from_bytes(script_bytes))
}

/// Add UTXOs to the PSBT inputs
fn add_utxos_to_psbt(psbt: &mut Psbt, utxos: &[(&str, u64)]) -> Result<()> {
    for (i, (script_hex, amount)) in utxos.iter().enumerate() {
        let script = decode_script(script_hex, i)?;

        if let Some(input) = psbt.inputs.get_mut(i) {
            // Add witness UTXO with correct amount
            input.witness_utxo = Some(TxOut {
                value: Amount::from_sat(*amount),
                script_pubkey: script.clone(),
            });

            // Set sighash type to ALL
            input.sighash_type = Some(TapSighashType::All.into());
        }
    }

    Ok(())
}

/// Check if a private key can sign a specific input
fn can_sign_input(
    script_pubkey: &ScriptBuf,
    public_key: &PublicKey,
    address_type: &str
) -> Result<bool> {
    match address_type {
        "bech32" => {
            // Check if the script matches a P2WPKH for this key
            let compressed_pubkey = bitcoin::key::CompressedPublicKey::from_slice(
                &public_key.to_bytes(),
            ).map_err(|e| WalletError::BitcoinError(format!("Invalid public key: {}", e)))?;
            
            let expected_script = Address::p2wpkh(&compressed_pubkey, Network::Bitcoin)
                .script_pubkey();
            
            Ok(script_pubkey == &expected_script)
        }
        "p2pkh" => {
            // Check if the script matches a P2PKH for this key
            let expected_script = Address::p2pkh(public_key, Network::Bitcoin).script_pubkey();
            Ok(script_pubkey == &expected_script)
        }
        _ => Ok(false),
    }
}

/// Generate a signing script based on address type
fn get_signing_script(
    public_key: &PublicKey,
    script_pubkey: &ScriptBuf,
    address_type: &str
) -> Result<ScriptBuf> {
    if address_type == "bech32" {
        // For P2WPKH, we need to use a P2PKH script for the signature hash
        let compressed_pubkey = bitcoin::key::CompressedPublicKey::from_slice(
            &public_key.to_bytes(),
        ).map_err(|e| WalletError::BitcoinError(format!("Invalid public key: {}", e)))?;
        
        let pubkey_hash = compressed_pubkey.pubkey_hash();
        Ok(ScriptBuf::new_p2pkh(&pubkey_hash))
    } else {
        Ok(script_pubkey.clone())
    }
}

/// Add signature to PSBT input based on address type
fn add_signature_to_input(
    input: &mut bitcoin::psbt::Input,
    signature_bytes: Vec<u8>,
    pubkey_bytes: Vec<u8>,
    address_type: &str
) -> Result<()> {
    if address_type == "bech32" {
        // For P2WPKH, set witness data
        let mut witness = bitcoin::blockdata::witness::Witness::new();
        witness.push(signature_bytes);
        witness.push(pubkey_bytes);
        input.final_script_witness = Some(witness);

        // Empty script_sig for segwit
        input.final_script_sig = Some(ScriptBuf::new());
    } else {
        // For P2PKH, create scriptSig: <signature> <pubkey>
        let sig_push_bytes = PushBytesBuf::try_from(signature_bytes)
            .map_err(|e| WalletError::BitcoinError(
                format!("Failed to convert signature to PushBytesBuf: {:?}", e)
            ))?;

        let pubkey_push_bytes = PushBytesBuf::try_from(pubkey_bytes)
            .map_err(|e| WalletError::BitcoinError(
                format!("Failed to convert pubkey to PushBytesBuf: {:?}", e)
            ))?;

        let script_sig = Builder::new()
            .push_slice(&sig_push_bytes[..])
            .push_slice(&pubkey_push_bytes[..])
            .into_script();

        input.final_script_sig = Some(script_sig);
    }

    Ok(())
}

/// Sign a PSBT input with a private key if possible
fn try_sign_input(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &SighashCache<&Transaction>,
    input: &mut bitcoin::psbt::Input,
    input_index: usize,
    private_key: &PrivateKey,
    public_key: &PublicKey,
    address_type: &str,
    script_pubkey: &ScriptBuf
) -> Result<bool> {
    // Check if this key can sign this input
    if !can_sign_input(script_pubkey, public_key, address_type)? {
        return Ok(false);
    }

    // Get sighash type
    let sighash_type = EcdsaSighashType::All;

    // Get the signing script
    let signing_script = get_signing_script(public_key, script_pubkey, address_type)?;

    // Compute signature hash
    let sighash = sighash_cache
        .legacy_signature_hash(input_index, &signing_script, sighash_type.to_u32())
        .map_err(|e| WalletError::BitcoinError(
            format!("Failed to compute signature hash: {}", e)
        ))?;

    // Create a message from the sighash
    let message = Message::from_digest_slice(&sighash[..])
        .map_err(|e| WalletError::BitcoinError(
            format!("Failed to create message: {}", e)
        ))?;

    // Get secret key from private key
    let secret_key = bitcoin::secp256k1::SecretKey::from_slice(&private_key.inner[..])
        .map_err(|e| WalletError::BitcoinError(
            format!("Failed to create secret key: {:?}", e)
        ))?;

    // Sign the message
    let signature = secp.sign_ecdsa(&message, &secret_key);

    // Serialize the signature and add sighash type
    let mut signature_bytes = signature.serialize_der().to_vec();
    signature_bytes.push(sighash_type as u8);

    // Add the signature to the input
    add_signature_to_input(
        input,
        signature_bytes,
        public_key.to_bytes(),
        address_type
    )?;

    Ok(true)
}

/// Sign PSBT inputs with wallet private keys
fn sign_psbt_inputs(
    psbt: &mut Psbt,
    addresses: &HashMap<String, AddressInfo>
) -> Result<Vec<bool>> {
    // Create secp256k1 context for signing
    let secp = Secp256k1::new();

    // Track which inputs were signed
    let mut signed_inputs = vec![false; psbt.inputs.len()];

    // Create a SighashCache for computing signature hashes
    // Clone transaction to avoid borrowing conflict
    let unsigned_tx_clone = psbt.unsigned_tx.clone();
    let sighash_cache = SighashCache::new(&unsigned_tx_clone);

    // Try to sign with each key in our wallet
    for (addr_str, info) in addresses {
        let private_key = match PrivateKey::from_str(&info.private_key) {
            Ok(pk) => pk,
            Err(e) => {
                eprintln!("Invalid private key for {}: {:?}", addr_str, e);
                continue;
            }
        };

        // Get the public key
        let public_key = PublicKey::from_private_key(&secp, &private_key);

        // Sign each input one by one
        for i in 0..psbt.inputs.len() {
            if signed_inputs[i] {
                continue; // Skip already signed inputs
            }

            // First get script_pubkey for this input
            let script_pubkey = match &psbt.inputs[i].witness_utxo {
                Some(utxo) => utxo.script_pubkey.clone(),
                None => continue, // Skip inputs without witness UTXO
            };

            // Now we can mutably borrow the input
            let input = &mut psbt.inputs[i];
            
            match try_sign_input(
                &secp,
                &sighash_cache,
                input,
                i,
                &private_key,
                &public_key,
                &info.address_type,
                &script_pubkey
            ) {
                Ok(true) => signed_inputs[i] = true,
                Ok(false) => {}, // Could not sign this input with this key
                Err(e) => eprintln!("Error signing input {}: {:?}", i, e),
            }
        }
    }

    Ok(signed_inputs)
}

/// Extract and serialize the final transaction
fn extract_and_serialize_transaction(psbt: Psbt) -> Result<String> {
    let finalized_tx = psbt.extract_tx()
        .map_err(|e| WalletError::BitcoinError(
            format!("Failed to extract transaction: {:?}", e)
        ))?;

    // Serialize to hex
    let signed_tx_bytes = serialize(&finalized_tx);
    let signed_tx_hex = hex::encode(signed_tx_bytes);

    Ok(signed_tx_hex)
}

/// Sign a raw Bitcoin transaction
///
/// This function signs an unsigned transaction with private keys from the wallet.
/// It supports P2PKH and P2WPKH (bech32) inputs.
///
/// # Arguments
///
/// * `addresses` - HashMap of addresses and their information
/// * `raw_tx_hex` - Unsigned transaction in hexadecimal format
/// * `utxos` - Vector of (script_pubkey_hex, amount_in_satoshis) pairs for each input
///
/// # Returns
///
/// * `Result<String>` - Signed transaction in hexadecimal format or error
pub fn sign_transaction(
    addresses: &HashMap<String, AddressInfo>,
    raw_tx_hex: &str,
    utxos: Vec<(&str, u64)>,
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
    let signed_inputs = sign_psbt_inputs(&mut psbt, addresses)?;

    // Check if any inputs were signed
    if !signed_inputs.iter().any(|&signed| signed) {
        return Err(WalletError::BitcoinError(
            "No inputs could be signed with keys in this wallet".to_string(),
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
        eprintln!(
            "Warning: Could not sign inputs at indices: {:?}",
            unsigned_indices
        );
    }

    // Extract and serialize the final transaction
    extract_and_serialize_transaction(psbt)
}