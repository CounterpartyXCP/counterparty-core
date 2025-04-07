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
    let tx_bytes = match hex::decode(raw_tx_hex) {
        Ok(bytes) => bytes,
        Err(e) => {
            return Err(WalletError::BitcoinError(format!(
                "Invalid transaction hex: {}",
                e
            )))
        }
    };

    let tx: Transaction = match deserialize(&tx_bytes) {
        Ok(tx) => tx,
        Err(e) => {
            return Err(WalletError::BitcoinError(format!(
                "Invalid transaction format: {}",
                e
            )))
        }
    };

    // Validate input count
    if tx.input.len() != utxos.len() {
        return Err(WalletError::BitcoinError(format!(
            "Number of UTXOs ({}) does not match number of inputs ({})",
            utxos.len(),
            tx.input.len()
        )));
    }

    // Create secp256k1 context for signing
    let secp = Secp256k1::new();

    // Create a PSBT from the transaction
    let mut psbt = match Psbt::from_unsigned_tx(tx) {
        Ok(psbt) => psbt,
        Err(e) => {
            return Err(WalletError::BitcoinError(format!(
                "Failed to create PSBT: {}",
                e
            )))
        }
    };

    // Add UTXOs to the PSBT inputs
    for (i, (script_hex, amount)) in utxos.iter().enumerate() {
        let script_bytes = match hex::decode(script_hex) {
            Ok(bytes) => bytes,
            Err(e) => {
                return Err(WalletError::BitcoinError(format!(
                    "Invalid script_pubkey hex at index {}: {}",
                    i, e
                )))
            }
        };

        let script = ScriptBuf::from_bytes(script_bytes);

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

    // Track which inputs were signed
    let mut signed_inputs = vec![false; psbt.inputs.len()];

    // Create a SighashCache for computing signature hashes
    let sighash_cache = SighashCache::new(&psbt.unsigned_tx);

    // Try to sign with each key in our wallet
    for (addr_str, info) in addresses {
        let private_key = match PrivateKey::from_str(&info.private_key) {
            Ok(pk) => pk,
            Err(e) => {
                eprintln!("Invalid private key for {}: {:?}", addr_str, e);
                continue;
            }
        };

        // Create secret key from the private key
        let secret_key = match bitcoin::secp256k1::SecretKey::from_slice(&private_key.inner[..]) {
            Ok(sk) => sk,
            Err(e) => {
                eprintln!("Failed to create secret key for {}: {:?}", addr_str, e);
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

            if let Some(input) = psbt.inputs.get_mut(i) {
                if let Some(utxo) = &input.witness_utxo {
                    let script_pubkey = &utxo.script_pubkey;

                    // Determine if this key can sign this input
                    let can_sign = match info.address_type.as_str() {
                        "bech32" => {
                            // Check if the script matches a P2WPKH for this key
                            let compressed_pubkey = bitcoin::key::CompressedPublicKey::from_slice(
                                &public_key.to_bytes(),
                            )
                            .map_err(|e| {
                                WalletError::BitcoinError(format!(
                                    "Invalid public key: {}",
                                    e
                                ))
                            })?;
                            let expected_script =
                                Address::p2wpkh(&compressed_pubkey, Network::Bitcoin)
                                    .script_pubkey();
                            script_pubkey == &expected_script
                        }
                        "p2pkh" => {
                            // Check if the script matches a P2PKH for this key
                            let expected_script =
                                Address::p2pkh(&public_key, Network::Bitcoin).script_pubkey();
                            script_pubkey == &expected_script
                        }
                        _ => false,
                    };

                    if can_sign {
                        // Get sighash type
                        let sighash_type = EcdsaSighashType::All;

                        // For P2WPKH, we need to use a P2PKH script for the signature hash
                        let signing_script = if info.address_type == "bech32" {
                            let compressed_pubkey =
                                bitcoin::key::CompressedPublicKey::from_slice(
                                    &public_key.to_bytes(),
                                )
                                .map_err(|e| {
                                    WalletError::BitcoinError(format!(
                                        "Invalid public key: {}",
                                        e
                                    ))
                                })?;
                            let pubkey_hash = compressed_pubkey.pubkey_hash();
                            ScriptBuf::new_p2pkh(&pubkey_hash)
                        } else {
                            script_pubkey.clone()
                        };

                        // Compute signature hash using legacy method (works for both P2PKH and segwit)
                        let sighash = sighash_cache
                            .legacy_signature_hash(i, &signing_script, sighash_type.to_u32())
                            .map_err(|e| {
                                WalletError::BitcoinError(format!(
                                    "Failed to compute signature hash: {}",
                                    e
                                ))
                            })?;

                        // Create a message from the sighash
                        let message = Message::from_digest_slice(&sighash[..]).map_err(|e| {
                            WalletError::BitcoinError(format!(
                                "Failed to create message: {}",
                                e
                            ))
                        })?;

                        // Sign the message
                        let signature = secp.sign_ecdsa(&message, &secret_key);

                        // Serialize the signature and add sighash type
                        let mut signature_bytes = signature.serialize_der().to_vec();
                        signature_bytes.push(sighash_type as u8);

                        // Convert to PushBytesBuf for script building
                        let sig_push_bytes = PushBytesBuf::try_from(signature_bytes.clone())
                            .map_err(|e| {
                                WalletError::BitcoinError(format!(
                                    "Failed to convert signature to PushBytesBuf: {:?}",
                                    e
                                ))
                            })?;

                        let pubkey_bytes = public_key.to_bytes();
                        let pubkey_push_bytes = PushBytesBuf::try_from(pubkey_bytes.clone())
                            .map_err(|e| {
                                WalletError::BitcoinError(format!(
                                    "Failed to convert pubkey to PushBytesBuf: {:?}",
                                    e
                                ))
                            })?;

                        // Add the signature to the input
                        if info.address_type == "bech32" {
                            // For P2WPKH, set witness data
                            let mut witness = bitcoin::blockdata::witness::Witness::new();
                            // Here we use the original byte vectors which implement AsRef<[u8]>
                            witness.push(signature_bytes);
                            witness.push(pubkey_bytes);
                            input.final_script_witness = Some(witness);

                            // Empty script_sig for segwit
                            input.final_script_sig = Some(ScriptBuf::new());
                        } else {
                            // For P2PKH, create scriptSig: <signature> <pubkey>
                            let script_sig = Builder::new()
                                .push_slice(&sig_push_bytes[..])
                                .push_slice(&pubkey_push_bytes[..])
                                .into_script();

                            input.final_script_sig = Some(script_sig);
                        }

                        signed_inputs[i] = true;
                    }
                }
            }
        }
    }

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

    // Extract finalized transaction
    let finalized_tx = match psbt.extract_tx() {
        Ok(tx) => tx,
        Err(e) => {
            return Err(WalletError::BitcoinError(format!(
                "Failed to extract transaction: {:?}",
                e
            )))
        }
    };

    // Serialize to hex
    let signed_tx_bytes = serialize(&finalized_tx);
    let signed_tx_hex = hex::encode(signed_tx_bytes);

    Ok(signed_tx_hex)
}