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
use bitcoin::Transaction;
use bitcoin::XOnlyPublicKey;
// Removed unused import
// use bitcoin::taproot::TapLeafHash;

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

/// Determine the address type from script_pubkey
fn determine_address_type(script_pubkey: &ScriptBuf) -> String {
    if script_pubkey.is_p2pkh() {
        "p2pkh".to_string()
    } else if script_pubkey.is_p2wpkh() {
        "p2wpkh".to_string()
    } else if script_pubkey.is_p2sh() {
        "p2sh".to_string()
    } else if script_pubkey.is_p2wsh() {
        "p2wsh".to_string()
    } else if script_pubkey.is_p2tr() {
        "p2tr".to_string()
    } else {
        "unknown".to_string()
    }
}

/// Prepare a single UTXO and add it to the PSBT input at a specific index
fn prepare_utxo_for_input(
    psbt: &mut Psbt, 
    index: usize, 
    script_hex: &str, 
    amount: u64
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
            _ => EcdsaSighashType::All.into(),
        };
        
        input.sighash_type = Some(sighash_type);
    }

    Ok(())
}

/// Add UTXOs to the PSBT inputs
fn add_utxos_to_psbt(psbt: &mut Psbt, utxos: &[(&str, u64)]) -> Result<()> {
    for (i, (script_hex, amount)) in utxos.iter().enumerate() {
        prepare_utxo_for_input(psbt, i, script_hex, *amount)?;
    }
    Ok(())
}

/// Check if a private key can sign a P2WPKH input
fn can_sign_p2wpkh(script_pubkey: &ScriptBuf, public_key: &PublicKey) -> Result<bool> {
    // Check if the script matches a P2WPKH for this key
    let compressed_pubkey = bitcoin::key::CompressedPublicKey::from_slice(
        &public_key.to_bytes(),
    ).map_err(|e| WalletError::BitcoinError(format!("Invalid public key: {}", e)))?;
    
    // Address::p2wpkh does not return a Result, so no need for map_err
    let expected_script = Address::p2wpkh(&compressed_pubkey, Network::Bitcoin)
        .script_pubkey();
    
    Ok(script_pubkey == &expected_script)
}

/// Check if a private key can sign a P2PKH input
fn can_sign_p2pkh(script_pubkey: &ScriptBuf, public_key: &PublicKey) -> Result<bool> {
    // Check if the script matches a P2PKH for this key
    let expected_script = Address::p2pkh(public_key, Network::Bitcoin)
        .script_pubkey();
    Ok(script_pubkey == &expected_script)
}

/// Check if a private key can sign a P2SH-P2WPKH input
fn can_sign_p2sh_p2wpkh(script_pubkey: &ScriptBuf, public_key: &PublicKey) -> Result<bool> {
    // For P2SH-P2WPKH, we need to check if it's a P2SH wrapping a P2WPKH for this key
    let compressed_pubkey = bitcoin::key::CompressedPublicKey::from_slice(
        &public_key.to_bytes(),
    ).map_err(|e| WalletError::BitcoinError(format!("Invalid public key: {}", e)))?;
    
    // Remove map_err, Address::p2wpkh returns an Address directly
    let p2wpkh = Address::p2wpkh(&compressed_pubkey, Network::Bitcoin);
    
    // Address::p2sh takes a script as input
    let expected_script = Address::p2sh(&p2wpkh.script_pubkey(), Network::Bitcoin)
        .map_err(|e| WalletError::BitcoinError(format!("Failed to create P2SH-P2WPKH address: {}", e)))?
        .script_pubkey();
    
    Ok(script_pubkey == &expected_script)
}

/// Check if a private key can sign a P2TR input
fn can_sign_p2tr(script_pubkey: &ScriptBuf, public_key: &PublicKey) -> Result<bool> {
    // For P2TR, we need to check if it's a Taproot output for this key
    // Convert ECDSA public key to x-only public key
    let secp = Secp256k1::verification_only();
    let xonly_pubkey = XOnlyPublicKey::from_slice(&public_key.to_bytes()[1..33])
        .map_err(|e| WalletError::BitcoinError(format!("Failed to convert to xonly pubkey: {}", e)))?;
    
    // Create expected P2TR script
    let p2tr_address = Address::p2tr(&secp, xonly_pubkey, None, Network::Bitcoin);
    let expected_script = p2tr_address.script_pubkey();
    
    Ok(script_pubkey == &expected_script)
}

/// Check if a private key can sign a specific input
fn can_sign_input(
    script_pubkey: &ScriptBuf,
    public_key: &PublicKey,
    address_type: &str
) -> Result<bool> {
    match address_type {
        "p2wpkh" | "bech32" => can_sign_p2wpkh(script_pubkey, public_key),
        "p2pkh" => can_sign_p2pkh(script_pubkey, public_key),
        "p2sh-p2wpkh" => can_sign_p2sh_p2wpkh(script_pubkey, public_key),
        "p2tr" => can_sign_p2tr(script_pubkey, public_key),
        _ => Ok(false), // Unknown address type
    }
}

/// Get P2WPKH signing script for a public key
fn get_p2wpkh_signing_script(public_key: &PublicKey) -> Result<ScriptBuf> {
    // For P2WPKH, we need to use a P2PKH script for the signature hash
    let compressed_pubkey = bitcoin::key::CompressedPublicKey::from_slice(
        &public_key.to_bytes(),
    ).map_err(|e| WalletError::BitcoinError(format!("Invalid public key: {}", e)))?;
    
    let pubkey_hash = compressed_pubkey.pubkey_hash();
    Ok(ScriptBuf::new_p2pkh(&pubkey_hash))
}

/// Get P2SH-P2WPKH signing script for a public key
fn get_p2sh_p2wpkh_signing_script(public_key: &PublicKey) -> Result<ScriptBuf> {
    // Same as P2WPKH for signing purposes
    get_p2wpkh_signing_script(public_key)
}

/// Get default signing script (uses script_pubkey directly)
fn get_default_signing_script(script_pubkey: &ScriptBuf) -> Result<ScriptBuf> {
    Ok(script_pubkey.clone())
}

/// Generate a signing script based on address type
fn get_signing_script(
    public_key: &PublicKey,
    script_pubkey: &ScriptBuf,
    address_type: &str
) -> Result<ScriptBuf> {
    match address_type {
        "p2wpkh" | "bech32" => get_p2wpkh_signing_script(public_key),
        "p2sh-p2wpkh" => get_p2sh_p2wpkh_signing_script(public_key),
        "p2tr" | _ => get_default_signing_script(script_pubkey),
    }
}

/// Add P2WPKH signature to input
fn add_p2wpkh_signature(
    input: &mut bitcoin::psbt::Input,
    signature_bytes: Vec<u8>,
    pubkey_bytes: Vec<u8>
) -> Result<()> {
    // For P2WPKH, set witness data
    let mut witness = bitcoin::blockdata::witness::Witness::new();
    witness.push(signature_bytes);
    witness.push(pubkey_bytes);
    input.final_script_witness = Some(witness);

    // Empty script_sig for segwit
    input.final_script_sig = Some(ScriptBuf::new());
    
    Ok(())
}

/// Add P2PKH signature to input
fn add_p2pkh_signature(
    input: &mut bitcoin::psbt::Input,
    signature_bytes: Vec<u8>,
    pubkey_bytes: Vec<u8>
) -> Result<()> {
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
    
    Ok(())
}

/// Add P2SH-P2WPKH signature to input
fn add_p2sh_p2wpkh_signature(
    input: &mut bitcoin::psbt::Input,
    signature_bytes: Vec<u8>,
    pubkey_bytes: Vec<u8>
) -> Result<()> {
    // For P2SH-P2WPKH, set both script_sig and witness data
    
    // 1. Create redeem script (P2WPKH)
    let compressed_pubkey = bitcoin::key::CompressedPublicKey::from_slice(
        &pubkey_bytes,
    ).map_err(|e| WalletError::BitcoinError(format!("Invalid public key: {}", e)))?;
    
    // Use wpubkey_hash for P2WPKH
    let pubkey_hash = compressed_pubkey.wpubkey_hash();
    let redeem_script = ScriptBuf::new_p2wpkh(&pubkey_hash);
    
    // 2. Set script_sig to push redeem script
    let redeem_script_bytes = PushBytesBuf::try_from(redeem_script.to_bytes())
        .map_err(|e| WalletError::BitcoinError(
            format!("Failed to convert redeem script to PushBytesBuf: {:?}", e)
        ))?;
    
    let script_sig = Builder::new()
        .push_slice(&redeem_script_bytes[..])
        .into_script();
    
    input.final_script_sig = Some(script_sig);
    
    // 3. Set witness data (same as P2WPKH)
    let mut witness = bitcoin::blockdata::witness::Witness::new();
    witness.push(signature_bytes);
    witness.push(pubkey_bytes);
    input.final_script_witness = Some(witness);
    
    Ok(())
}

/// Add P2TR signature to input
fn add_p2tr_signature(
    input: &mut bitcoin::psbt::Input,
    signature_bytes: Vec<u8>
) -> Result<()> {
    // For P2TR, add as BIP 341 Taproot signature
    let mut witness = bitcoin::blockdata::witness::Witness::new();
    witness.push(signature_bytes);
    input.final_script_witness = Some(witness);
    
    // Empty script_sig for segwit
    input.final_script_sig = Some(ScriptBuf::new());
    
    Ok(())
}

/// Add signature to PSBT input based on address type
fn add_signature_to_input(
    input: &mut bitcoin::psbt::Input,
    signature_bytes: Vec<u8>,
    pubkey_bytes: Vec<u8>,
    address_type: &str,
) -> Result<()> {
    match address_type {
        "p2wpkh" | "bech32" => add_p2wpkh_signature(input, signature_bytes, pubkey_bytes),
        "p2pkh" => add_p2pkh_signature(input, signature_bytes, pubkey_bytes),
        "p2sh-p2wpkh" => add_p2sh_p2wpkh_signature(input, signature_bytes, pubkey_bytes),
        "p2tr" => add_p2tr_signature(input, signature_bytes),
        _ => {
            Err(WalletError::BitcoinError(
                format!("Unsupported address type: {}", address_type)
            ))
        }
    }
}

/// Compute Taproot (P2TR) signature
fn compute_taproot_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    input: &bitcoin::psbt::Input,
    secret_key: &bitcoin::secp256k1::SecretKey,
    public_key: &PublicKey
) -> Result<Vec<u8>> {
    // For Taproot, use the appropriate sighash algorithm
    let sighash_type = bitcoin::sighash::TapSighashType::All;
    
    // Create the Prevouts structure
    let prevouts = bitcoin::sighash::Prevouts::One(
        input_index, 
        input.witness_utxo.as_ref().unwrap()
    );
    
    let sighash = sighash_cache
        .taproot_key_spend_signature_hash(input_index, &prevouts, sighash_type)
        .map_err(|e| WalletError::BitcoinError(
            format!("Failed to compute Taproot signature hash: {}", e)
        ))?;

    // Create a message from the sighash
    let message = Message::from_digest_slice(&sighash[..])
        .map_err(|e| WalletError::BitcoinError(
            format!("Failed to create message: {}", e)
        ))?;

    // Convert SecretKey to Keypair
    let keypair = bitcoin::secp256k1::Keypair::from_secret_key(&secp, &secret_key);
    let schnorr_sig = secp.sign_schnorr_no_aux_rand(&message, &keypair);
    let mut sig_bytes = schnorr_sig.as_ref().to_vec();
    
    // Add sighash byte for Taproot if not ALL
    if sighash_type != bitcoin::sighash::TapSighashType::All {
        sig_bytes.push(sighash_type as u8);
    }
    
    // Verify the signature
    let xonly_pubkey = XOnlyPublicKey::from_slice(&public_key.to_bytes()[1..33])
        .map_err(|e| WalletError::BitcoinError(format!("Failed to convert to xonly pubkey: {}", e)))?;
        
    if secp.verify_schnorr(&schnorr_sig, &message, &xonly_pubkey).is_err() {
        return Err(WalletError::BitcoinError(
            format!("Generated Taproot signature failed verification")
        ));
    }
    
    Ok(sig_bytes)
}

/// Compute SegWit (P2WPKH, P2SH-P2WPKH) signature
fn compute_segwit_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    input: &bitcoin::psbt::Input,
    signing_script: &ScriptBuf,
    secret_key: &bitcoin::secp256k1::SecretKey,
    public_key: &PublicKey
) -> Result<Vec<u8>> {
    // For SegWit, use the correct method for segwit signatures
    let sighash_type = EcdsaSighashType::All;
    
    let sighash = sighash_cache
        .p2wpkh_signature_hash(
            input_index,
            &signing_script,
            input.witness_utxo.as_ref().unwrap().value,
            sighash_type
        )
        .map_err(|e| WalletError::BitcoinError(
            format!("Failed to compute SegWit signature hash: {}", e)
        ))?;

    // Create a message from the sighash
    let message = Message::from_digest_slice(&sighash[..])
        .map_err(|e| WalletError::BitcoinError(
            format!("Failed to create message: {}", e)
        ))?;

    // Sign with ECDSA
    let signature = secp.sign_ecdsa(&message, &secret_key);
    
    // Serialize the signature and add sighash type
    let mut sig_bytes = signature.serialize_der().to_vec();
    sig_bytes.push(sighash_type as u8);
    
    // Verify the signature
    if secp.verify_ecdsa(&message, &signature, &public_key.inner).is_err() {
        return Err(WalletError::BitcoinError(
            format!("Generated SegWit signature failed verification")
        ));
    }
    
    Ok(sig_bytes)
}

/// Compute Legacy (P2PKH) signature
fn compute_legacy_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    signing_script: &ScriptBuf,
    secret_key: &bitcoin::secp256k1::SecretKey,
    public_key: &PublicKey
) -> Result<Vec<u8>> {
    // For legacy, use legacy_signature_hash
    let sighash_type = EcdsaSighashType::All;
    
    let sighash = sighash_cache
        .legacy_signature_hash(input_index, &signing_script, sighash_type as u32)
        .map_err(|e| WalletError::BitcoinError(
            format!("Failed to compute legacy signature hash: {}", e)
        ))?;

    // Create a message from the sighash
    let message = Message::from_digest_slice(&sighash[..])
        .map_err(|e| WalletError::BitcoinError(
            format!("Failed to create message: {}", e)
        ))?;

    // Sign with ECDSA
    let signature = secp.sign_ecdsa(&message, &secret_key);
    
    // Serialize the signature and add sighash type
    let mut sig_bytes = signature.serialize_der().to_vec();
    sig_bytes.push(sighash_type as u8);
    
    // Verify the signature
    if secp.verify_ecdsa(&message, &signature, &public_key.inner).is_err() {
        return Err(WalletError::BitcoinError(
            format!("Generated legacy signature failed verification")
        ));
    }
    
    Ok(sig_bytes)
}

/// Try sign a PSBT input with a private key if possible
fn try_sign_input(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
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

    // Get the signing script
    let signing_script = get_signing_script(public_key, script_pubkey, address_type)?;

    // Get secret key from private key
    let secret_key = bitcoin::secp256k1::SecretKey::from_slice(&private_key.inner[..])
        .map_err(|e| WalletError::BitcoinError(
            format!("Failed to create secret key: {:?}", e)
        ))?;

    // Compute signature based on address type
    let signature_bytes = if address_type == "p2tr" {
        compute_taproot_signature(secp, sighash_cache, input_index, input, &secret_key, public_key)?
    } else if address_type == "p2wpkh" || address_type == "bech32" || address_type == "p2sh-p2wpkh" {
        compute_segwit_signature(secp, sighash_cache, input_index, input, &signing_script, &secret_key, public_key)?
    } else {
        compute_legacy_signature(secp, sighash_cache, input_index, &signing_script, &secret_key, public_key)?
    };

    // Add the signature to the input
    add_signature_to_input(
        input,
        signature_bytes,
        public_key.to_bytes(),
        address_type
    )?;

    Ok(true)
}

/// Verify Schnorr signature for Taproot
fn verify_schnorr_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    message: &Message,
    signature_bytes: &[u8],
    public_key: &PublicKey
) -> Result<bool> {
    if signature_bytes.len() < 64 {
        return Err(WalletError::BitcoinError(
            format!("Schnorr signature too short")
        ));
    }
    
    let schnorr_sig = bitcoin::secp256k1::schnorr::Signature::from_slice(&signature_bytes[0..64])
        .map_err(|e| WalletError::BitcoinError(
            format!("Invalid Schnorr signature: {:?}", e)
        ))?;
        
    let xonly_pubkey = XOnlyPublicKey::from_slice(&public_key.to_bytes()[1..33])
        .map_err(|e| WalletError::BitcoinError(format!("Failed to convert to xonly pubkey: {}", e)))?;
        
    Ok(secp.verify_schnorr(&schnorr_sig, message, &xonly_pubkey).is_ok())
}

/// Verify ECDSA signature for P2PKH and P2WPKH
fn verify_ecdsa_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    message: &Message,
    signature_bytes: &[u8],
    public_key: &PublicKey
) -> Result<bool> {
    // Strip sighash byte and parse DER signature
    let sig_len = signature_bytes.len() - 1; // Last byte is sighash type
    let signature = bitcoin::secp256k1::ecdsa::Signature::from_der(&signature_bytes[0..sig_len])
        .map_err(|e| WalletError::BitcoinError(
            format!("Invalid DER signature: {:?}", e)
        ))?;
        
    Ok(secp.verify_ecdsa(message, &signature, &public_key.inner).is_ok())
}

/// Verify a signature is valid
fn verify_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    message: &Message,
    signature_bytes: &[u8],
    public_key: &PublicKey,
    address_type: &str
) -> Result<bool> {
    if address_type == "p2tr" {
        verify_schnorr_signature(secp, message, signature_bytes, public_key)
    } else {
        verify_ecdsa_signature(secp, message, signature_bytes, public_key)
    }
}

/// Initialize signing context and signed_inputs vector
fn init_signing_context(
    input_count: usize
) -> (Secp256k1<bitcoin::secp256k1::All>, Vec<bool>) {
    // Create secp256k1 context for signing
    let secp = Secp256k1::new();
    // Track which inputs were signed
    let signed_inputs = vec![false; input_count];
    
    (secp, signed_inputs)
}

/// Process a private key for all inputs in the PSBT
fn process_key_for_inputs(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    psbt: &mut Psbt,
    signed_inputs: &mut Vec<bool>,
    private_key: &PrivateKey,
    public_key: &PublicKey,
    address_type: &str
) -> Result<()> {
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
            secp,
            sighash_cache,
            input,
            i,
            private_key,
            public_key,
            address_type,
            &script_pubkey
        ) {
            Ok(true) => signed_inputs[i] = true,
            Ok(false) => {}, // Could not sign this input with this key
            Err(e) => return Err(e), // Propagate error
        }
    }
    
    Ok(())
}

/// Sign PSBT inputs with wallet private keys
fn sign_psbt_inputs(
    psbt: &mut Psbt,
    addresses: &HashMap<String, AddressInfo>
) -> Result<Vec<bool>> {
    // Initialize signing context
    let (secp, mut signed_inputs) = init_signing_context(psbt.inputs.len());

    // Create a SighashCache for computing signature hashes
    // Clone transaction to avoid borrowing conflict
    let unsigned_tx_clone = psbt.unsigned_tx.clone();
    let mut sighash_cache = SighashCache::new(&unsigned_tx_clone);

    // Try to sign with each key in our wallet
    for (addr_str, info) in addresses {
        let private_key = match PrivateKey::from_str(&info.private_key) {
            Ok(pk) => pk,
            Err(e) => {
                return Err(WalletError::BitcoinError(
                    format!("Invalid private key for {}: {:?}", addr_str, e)
                ));
            }
        };

        // Get the public key
        let public_key = PublicKey::from_private_key(&secp, &private_key);

        // Map old address_type names to new standardized ones
        let address_type = match info.address_type.as_str() {
            "bech32" => "p2wpkh", // Standardize on p2wpkh instead of bech32
            other => other,
        };

        // Process this key for all inputs
        process_key_for_inputs(
            &secp,
            &mut sighash_cache,
            psbt,
            &mut signed_inputs,
            &private_key,
            &public_key,
            &address_type
        )?;
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
/// It supports P2PKH, P2WPKH (bech32), P2SH-P2WPKH, and P2TR inputs.
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