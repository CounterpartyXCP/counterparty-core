use std::collections::HashMap;
use std::str::FromStr;

use bitcoin::amount::Amount;
use bitcoin::secp256k1::Message;
use bitcoin::secp256k1::Secp256k1;
use bitcoin::ScriptBuf;
use bitcoin::{Address, Network, PrivateKey, PublicKey};

use bitcoin::blockdata::script::{Builder, Instruction, PushBytesBuf};
use bitcoin::blockdata::transaction::TxOut;
use bitcoin::consensus::{deserialize, serialize};
use bitcoin::psbt::Psbt;
use bitcoin::sighash::{EcdsaSighashType, SighashCache};
use bitcoin::Transaction;
use bitcoin::XOnlyPublicKey;

use crate::wallet::AddressInfo;
use crate::wallet::WalletError;

type Result<T> = std::result::Result<T, WalletError>;

/// Represents the different types of Bitcoin addresses supported
#[derive(Debug, Clone, Copy, PartialEq)]
enum AddressType {
    P2PKH,
    P2WPKH,
    P2SHP2WPKH,
    P2TR,
    P2WSH,
    Unknown,
}

impl AddressType {
    /// Converts a string to AddressType
    fn from_str(address_type: &str) -> Self {
        match address_type {
            "p2pkh" => Self::P2PKH,
            "p2wpkh" | "bech32" => Self::P2WPKH,
            "p2sh-p2wpkh" => Self::P2SHP2WPKH,
            "p2tr" => Self::P2TR,
            "p2wsh" => Self::P2WSH,
            _ => Self::Unknown,
        }
    }

    /* /// Converts an AddressType to string
    fn to_str(&self) -> &'static str {
        match self {
            Self::P2PKH => "p2pkh",
            Self::P2WPKH => "p2wpkh",
            Self::P2SHP2WPKH => "p2sh-p2wpkh",
            Self::P2TR => "p2tr",
            Self::P2WSH => "p2wsh",
            Self::Unknown => "unknown",
        }
    }

    /// Indicates if the type is segwit
    fn is_segwit(&self) -> bool {
        matches!(self, Self::P2WPKH | Self::P2SHP2WPKH | Self::P2WSH | Self::P2TR)
    } */
}

//
// MESSAGE AND SIGNATURE UTILITIES
//

/// Creates a Message from a signature hash
fn create_message_from_hash(sighash: &[u8]) -> Result<Message> {
    Message::from_digest_slice(sighash)
        .map_err(|e| WalletError::BitcoinError(format!("Failed to create message: {}", e)))
}

/// Verifies an ECDSA signature
fn verify_ecdsa_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    message: &Message,
    signature: &bitcoin::secp256k1::ecdsa::Signature,
    public_key: &PublicKey,
) -> Result<()> {
    if secp
        .verify_ecdsa(message, signature, &public_key.inner)
        .is_err()
    {
        return Err(WalletError::BitcoinError(format!(
            "Generated ECDSA signature failed verification"
        )));
    }
    Ok(())
}

/// Verifies a Schnorr signature
fn verify_schnorr_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    message: &Message,
    signature: &bitcoin::secp256k1::schnorr::Signature,
    xonly_pubkey: &XOnlyPublicKey,
) -> Result<()> {
    if secp
        .verify_schnorr(signature, message, xonly_pubkey)
        .is_err()
    {
        return Err(WalletError::BitcoinError(format!(
            "Generated Schnorr signature failed verification"
        )));
    }
    Ok(())
}

/// Encodes an ECDSA signature with sighash type
fn encode_ecdsa_signature(
    signature: &bitcoin::secp256k1::ecdsa::Signature,
    sighash_type: EcdsaSighashType,
) -> Vec<u8> {
    let mut sig_bytes = signature.serialize_der().to_vec();
    sig_bytes.push(sighash_type as u8);
    sig_bytes
}

/// Signs a message with ECDSA and verifies the signature
fn sign_and_verify_ecdsa(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    message: &Message,
    secret_key: &bitcoin::secp256k1::SecretKey,
    public_key: &PublicKey,
    sighash_type: EcdsaSighashType,
) -> Result<Vec<u8>> {
    // Sign with ECDSA
    let signature = secp.sign_ecdsa(message, secret_key);

    // Verify the signature
    verify_ecdsa_signature(secp, message, &signature, public_key)?;

    // Encode with sighash type
    Ok(encode_ecdsa_signature(&signature, sighash_type))
}

//
// KEY CONVERSION UTILITIES
//

/// Converts a PublicKey to CompressedPublicKey
fn get_compressed_pubkey(public_key: &PublicKey) -> Result<bitcoin::key::CompressedPublicKey> {
    bitcoin::key::CompressedPublicKey::from_slice(&public_key.to_bytes())
        .map_err(|e| WalletError::BitcoinError(format!("Invalid public key: {}", e)))
}

/// Converts a PublicKey to XOnlyPublicKey
fn get_xonly_pubkey(public_key: &PublicKey) -> Result<XOnlyPublicKey> {
    XOnlyPublicKey::from_slice(&public_key.to_bytes()[1..33])
        .map_err(|e| WalletError::BitcoinError(format!("Failed to convert to xonly pubkey: {}", e)))
}

/// Creates a standard witness with signature and public key
fn create_witness_with_sig_and_pubkey(
    signature_bytes: Vec<u8>,
    pubkey_bytes: Vec<u8>,
) -> bitcoin::blockdata::witness::Witness {
    let mut witness = bitcoin::blockdata::witness::Witness::new();
    witness.push(signature_bytes);
    witness.push(pubkey_bytes);
    witness
}

/// Creates an empty script_sig for SegWit inputs
fn create_empty_script_sig() -> ScriptBuf {
    ScriptBuf::new()
}

//
// TRANSACTION PARSING UTILITIES
//

/// Parse a raw transaction from hexadecimal format
fn parse_transaction(raw_tx_hex: &str) -> Result<Transaction> {
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
    let script_bytes = hex::decode(script_hex).map_err(|e| {
        WalletError::BitcoinError(format!(
            "Invalid script_pubkey hex at index {}: {}",
            index, e
        ))
    })?;

    Ok(ScriptBuf::from_bytes(script_bytes))
}

/// Check if a script is a P2SH-P2WPKH script
fn is_p2sh_p2wpkh_script(script_pubkey: &ScriptBuf) -> bool {
    if !script_pubkey.is_p2sh() {
        return false;
    }

    // Check for P2SH-P2WPKH pattern using safe iteration
    let mut iter = script_pubkey.instructions_minimal();

    // First instruction should be OP_HASH160
    if let Some(Ok(Instruction::Op(op1))) = iter.next() {
        if op1 == bitcoin::blockdata::opcodes::all::OP_HASH160 {
            // Second instruction should be a 20-byte push
            if let Some(Ok(Instruction::PushBytes(bytes))) = iter.next() {
                if bytes.len() == 20 {
                    // Third instruction should be OP_EQUAL
                    if let Some(Ok(Instruction::Op(op2))) = iter.next() {
                        if op2 == bitcoin::blockdata::opcodes::all::OP_EQUAL {
                            // No more instructions
                            if iter.next().is_none() {
                                // This confirms it's a P2SH, but we can't fully verify it's specifically P2SH-P2WPKH
                                // without the redeem script. We rely on can_sign_input to verify using the address matching.
                                // The 20-byte hash length is consistent with P2SH-P2WPKH, which is a good hint.
                                return true;
                            }
                        }
                    }
                }
            }
        }
    }

    false
}

/// Determine the address type from script_pubkey with a more robust approach
fn determine_address_type(script_pubkey: &ScriptBuf) -> String {
    if script_pubkey.is_p2pkh() {
        "p2pkh".to_string()
    } else if script_pubkey.is_p2wpkh() {
        "p2wpkh".to_string()
    } else if script_pubkey.is_p2sh() {
        if is_p2sh_p2wpkh_script(script_pubkey) {
            "p2sh-p2wpkh".to_string()
        } else {
            "p2sh".to_string()
        }
    } else if script_pubkey.is_p2wsh() {
        "p2wsh".to_string()
    } else if script_pubkey.is_p2tr() {
        "p2tr".to_string()
    } else {
        "unknown".to_string()
    }
}

//
// PSBT INPUT PREPARATION
//

/// Prepare a single UTXO and add it to the PSBT input at a specific index
fn prepare_utxo_for_input(
    psbt: &mut Psbt,
    index: usize,
    script_hex: &str,
    amount: u64,
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

//
// ADDRESS UTILITIES
//

/// Standardize address type string to ensure consistency
/// Converts legacy names like "bech32" to standard names like "p2wpkh"
fn standardize_address_type(address_type: &str) -> &str {
    match address_type {
        "bech32" => "p2wpkh",
        _ => address_type,
    }
}

/// Helper function to check if a script matches an expected script
fn script_matches(script_pubkey: &ScriptBuf, expected_script: &ScriptBuf) -> bool {
    script_pubkey == expected_script
}

/// Utility function to check if a key can sign an input by first creating the corresponding address
fn can_sign_with_address_creation<F>(
    script_pubkey: &ScriptBuf,
    public_key: &PublicKey,
    create_address: F,
) -> Result<bool>
where
    F: FnOnce(&PublicKey) -> Result<Address>,
{
    let expected_address = create_address(public_key)?;
    let expected_script = expected_address.script_pubkey();
    Ok(script_matches(script_pubkey, &expected_script))
}

/// Check if a public key is used in a witness script
fn is_pubkey_in_witness_script(witness_script: &ScriptBuf, public_key: &PublicKey) -> Result<bool> {
    // Convert the public key to serialized format that we're looking for
    let pubkey_bytes = public_key.to_bytes();

    // Parse the script into instructions
    let mut iter = witness_script.instructions_minimal();

    // Iterate through all elements in the script
    while let Some(result) = iter.next() {
        // Only process successfully parsed instructions
        if let Ok(instruction) = result {
            match instruction {
                Instruction::PushBytes(bytes) => {
                    // Check if this pushed data is a public key
                    if bytes.len() == pubkey_bytes.len()
                        && bytes.as_bytes() == pubkey_bytes.as_slice()
                    {
                        return Ok(true);
                    }
                }
                // You could add more cases for opcodes that manipulate public keys
                _ => {}
            }
        }
    }

    Ok(false)
}

//
// INPUT SIGNING CAPABILITY CHECKS
//

/// Check if a key can sign a P2WPKH input
fn can_sign_p2wpkh_input(
    script_pubkey: &ScriptBuf,
    public_key: &PublicKey,
    network: Network,
) -> Result<bool> {
    can_sign_with_address_creation(script_pubkey, public_key, |pubkey| -> Result<Address> {
        let compressed_pubkey = get_compressed_pubkey(pubkey)?;
        Ok(Address::p2wpkh(&compressed_pubkey, network))
    })
}

/// Check if a key can sign a P2PKH input
fn can_sign_p2pkh_input(
    script_pubkey: &ScriptBuf,
    public_key: &PublicKey,
    network: Network,
) -> Result<bool> {
    can_sign_with_address_creation(script_pubkey, public_key, |pubkey| {
        Ok(Address::p2pkh(pubkey, network))
    })
}

/// Check if a key can sign a P2SH-P2WPKH input
fn can_sign_p2sh_p2wpkh_input(
    script_pubkey: &ScriptBuf,
    public_key: &PublicKey,
    network: Network,
) -> Result<bool> {
    can_sign_with_address_creation(script_pubkey, public_key, |pubkey| -> Result<Address> {
        let compressed_pubkey = get_compressed_pubkey(pubkey)?;
        let p2wpkh = Address::p2wpkh(&compressed_pubkey, network);
        Address::p2sh(&p2wpkh.script_pubkey(), network).map_err(|e| {
            WalletError::BitcoinError(format!("Failed to create P2SH-P2WPKH address: {}", e))
        })
    })
}

/// Check if a key can sign a P2TR input
fn can_sign_p2tr_input(
    script_pubkey: &ScriptBuf,
    public_key: &PublicKey,
    network: Network,
) -> Result<bool> {
    can_sign_with_address_creation(script_pubkey, public_key, |pubkey| -> Result<Address> {
        let secp = Secp256k1::verification_only();
        let xonly_pubkey = get_xonly_pubkey(pubkey)?;
        Ok(Address::p2tr(&secp, xonly_pubkey, None, network))
    })
}

/// Check if a key can sign a P2WSH input
fn can_sign_p2wsh_input(
    script_pubkey: &ScriptBuf,
    public_key: &PublicKey,
    witness_script: Option<&ScriptBuf>,
    network: Network,
) -> Result<bool> {
    if let Some(script) = witness_script {
        can_sign_with_address_creation(script_pubkey, public_key, |_| {
            Ok(Address::p2wsh(script, network))
        })
        .and_then(|matches| {
            if matches {
                is_pubkey_in_witness_script(script, public_key)
            } else {
                Ok(false)
            }
        })
    } else {
        Ok(false)
    }
}

/// Check if a private key can sign a specific input
fn can_sign_input(
    script_pubkey: &ScriptBuf,
    public_key: &PublicKey,
    address_type: &str,
    psbt_input: Option<&bitcoin::psbt::Input>,
    network: Network,
) -> Result<bool> {
    let addr_type = AddressType::from_str(standardize_address_type(address_type));

    match addr_type {
        AddressType::P2WPKH => can_sign_p2wpkh_input(script_pubkey, public_key, network),
        AddressType::P2PKH => can_sign_p2pkh_input(script_pubkey, public_key, network),
        AddressType::P2SHP2WPKH => can_sign_p2sh_p2wpkh_input(script_pubkey, public_key, network),
        AddressType::P2TR => can_sign_p2tr_input(script_pubkey, public_key, network),
        AddressType::P2WSH => {
            if let Some(input) = psbt_input {
                can_sign_p2wsh_input(
                    script_pubkey,
                    public_key,
                    input.witness_script.as_ref(),
                    network,
                )
            } else {
                Ok(false)
            }
        }
        AddressType::Unknown => Ok(false),
    }
}

//
// SIGNING SCRIPT GENERATION
//

/// Generate a P2PKH signing script
fn get_p2pkh_signing_script(public_key: &PublicKey) -> Result<ScriptBuf> {
    let compressed_pubkey = get_compressed_pubkey(public_key)?;
    let pubkey_hash = compressed_pubkey.pubkey_hash();
    Ok(ScriptBuf::new_p2pkh(&pubkey_hash))
}

/// Generate a signing script based on address type
fn get_signing_script(
    public_key: &PublicKey,
    script_pubkey: &ScriptBuf,
    address_type: &str,
    witness_script: Option<&ScriptBuf>,
) -> Result<ScriptBuf> {
    let addr_type = AddressType::from_str(standardize_address_type(address_type));

    match addr_type {
        AddressType::P2WPKH | AddressType::P2SHP2WPKH => {
            // For P2WPKH and P2SH-P2WPKH, we need to use a P2PKH script for the signature hash
            get_p2pkh_signing_script(public_key)
        }

        AddressType::P2WSH => {
            // For P2WSH, the signing script is the witness script itself
            witness_script.map(|script| script.clone()).ok_or_else(|| {
                WalletError::BitcoinError(format!("Missing witness script for P2WSH"))
            })
        }

        // By default, use the script_pubkey directly
        _ => Ok(script_pubkey.clone()),
    }
}

//
// SIGNATURE COMPUTATION
//

/// Compute Taproot (P2TR) signature
fn compute_p2tr_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    input: &bitcoin::psbt::Input,
    secret_key: &bitcoin::secp256k1::SecretKey,
    public_key: &PublicKey,
) -> Result<Vec<u8>> {
    // For Taproot, use the appropriate sighash algorithm from input or default to All
    let sighash_type = match input.sighash_type {
        Some(s) => s
            .taproot_hash_ty()
            .unwrap_or(bitcoin::sighash::TapSighashType::All),
        None => bitcoin::sighash::TapSighashType::All,
    };

    // Get witness UTXO safely with error handling
    let witness_utxo = input.witness_utxo.as_ref().ok_or_else(|| {
        WalletError::BitcoinError(format!(
            "Missing witness UTXO for Taproot input at index {}",
            input_index
        ))
    })?;

    // Create the Prevouts structure
    let prevouts = bitcoin::sighash::Prevouts::One(input_index, witness_utxo);

    let sighash = sighash_cache
        .taproot_key_spend_signature_hash(input_index, &prevouts, sighash_type)
        .map_err(|e| {
            WalletError::BitcoinError(format!("Failed to compute Taproot signature hash: {}", e))
        })?;

    // Create a message from the sighash
    let message = create_message_from_hash(&sighash[..])?;

    // Convert SecretKey to Keypair
    let keypair = bitcoin::secp256k1::Keypair::from_secret_key(&secp, &secret_key);
    let schnorr_sig = secp.sign_schnorr_no_aux_rand(&message, &keypair);
    let mut sig_bytes = schnorr_sig.as_ref().to_vec();

    // Add sighash byte for Taproot if not ALL
    if sighash_type != bitcoin::sighash::TapSighashType::All {
        sig_bytes.push(sighash_type as u8);
    }

    // Verify the signature
    let xonly_pubkey = get_xonly_pubkey(public_key)?;
    verify_schnorr_signature(secp, &message, &schnorr_sig, &xonly_pubkey)?;

    Ok(sig_bytes)
}

/// Compute SegWit (P2WPKH/P2SH-P2WPKH) signature
fn compute_segwit_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    input: &bitcoin::psbt::Input,
    signing_script: &ScriptBuf,
    secret_key: &bitcoin::secp256k1::SecretKey,
    public_key: &PublicKey,
) -> Result<Vec<u8>> {
    // For SegWit, use the correct method for segwit signatures
    let sighash_type = EcdsaSighashType::All;

    // Get witness UTXO safely with error handling
    let witness_utxo = input.witness_utxo.as_ref().ok_or_else(|| {
        WalletError::BitcoinError(format!(
            "Missing witness UTXO for SegWit input at index {}",
            input_index
        ))
    })?;

    let sighash = sighash_cache
        .p2wpkh_signature_hash(
            input_index,
            &signing_script,
            witness_utxo.value,
            sighash_type,
        )
        .map_err(|e| {
            WalletError::BitcoinError(format!("Failed to compute SegWit signature hash: {}", e))
        })?;

    // Create a message from the sighash and sign it
    let message = create_message_from_hash(&sighash[..])?;
    sign_and_verify_ecdsa(secp, &message, secret_key, public_key, sighash_type)
}

/// Compute P2WSH signature
fn compute_p2wsh_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    input: &bitcoin::psbt::Input,
    signing_script: &ScriptBuf,
    secret_key: &bitcoin::secp256k1::SecretKey,
    public_key: &PublicKey,
) -> Result<Vec<u8>> {
    // For P2WSH, use the correct method for segwit signatures
    let sighash_type = match input.sighash_type {
        Some(s) => s.ecdsa_hash_ty().unwrap_or(EcdsaSighashType::All),
        None => EcdsaSighashType::All,
    };

    // Get witness UTXO safely with error handling
    let witness_utxo = input.witness_utxo.as_ref().ok_or_else(|| {
        WalletError::BitcoinError(format!(
            "Missing witness UTXO for P2WSH input at index {}",
            input_index
        ))
    })?;

    let sighash = sighash_cache
        .p2wsh_signature_hash(
            input_index,
            signing_script,
            witness_utxo.value,
            sighash_type,
        )
        .map_err(|e| {
            WalletError::BitcoinError(format!("Failed to compute P2WSH signature hash: {}", e))
        })?;

    // Create a message from the sighash and sign it
    let message = create_message_from_hash(&sighash[..])?;
    sign_and_verify_ecdsa(secp, &message, secret_key, public_key, sighash_type)
}

/// Compute Legacy (P2PKH) signature
fn compute_legacy_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    signing_script: &ScriptBuf,
    secret_key: &bitcoin::secp256k1::SecretKey,
    public_key: &PublicKey,
) -> Result<Vec<u8>> {
    // For legacy, use legacy_signature_hash
    let sighash_type = EcdsaSighashType::All;

    let sighash = sighash_cache
        .legacy_signature_hash(input_index, &signing_script, sighash_type as u32)
        .map_err(|e| {
            WalletError::BitcoinError(format!("Failed to compute legacy signature hash: {}", e))
        })?;

    // Create a message from the sighash and sign it
    let message = create_message_from_hash(&sighash[..])?;
    sign_and_verify_ecdsa(secp, &message, secret_key, public_key, sighash_type)
}

/// Compute signature for an input based on its address type
fn compute_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    input: &bitcoin::psbt::Input,
    signing_script: &ScriptBuf,
    secret_key: &bitcoin::secp256k1::SecretKey,
    public_key: &PublicKey,
    address_type: &str,
) -> Result<Vec<u8>> {
    let addr_type = AddressType::from_str(standardize_address_type(address_type));

    match addr_type {
        AddressType::P2TR => compute_p2tr_signature(
            secp,
            sighash_cache,
            input_index,
            input,
            secret_key,
            public_key,
        ),

        AddressType::P2WPKH | AddressType::P2SHP2WPKH => compute_segwit_signature(
            secp,
            sighash_cache,
            input_index,
            input,
            signing_script,
            secret_key,
            public_key,
        ),

        AddressType::P2WSH => compute_p2wsh_signature(
            secp,
            sighash_cache,
            input_index,
            input,
            signing_script,
            secret_key,
            public_key,
        ),

        _ => compute_legacy_signature(
            secp,
            sighash_cache,
            input_index,
            signing_script,
            secret_key,
            public_key,
        ),
    }
}

//
// SIGNATURE ADDITION TO INPUTS
//

/// Add signature to P2WPKH input
fn add_p2wpkh_signature(
    input: &mut bitcoin::psbt::Input,
    signature_bytes: Vec<u8>,
    pubkey_bytes: Vec<u8>,
) -> Result<()> {
    input.final_script_witness = Some(create_witness_with_sig_and_pubkey(
        signature_bytes,
        pubkey_bytes,
    ));
    input.final_script_sig = Some(create_empty_script_sig());
    Ok(())
}

/// Add signature to P2PKH input
fn add_p2pkh_signature(
    input: &mut bitcoin::psbt::Input,
    signature_bytes: Vec<u8>,
    pubkey_bytes: Vec<u8>,
) -> Result<()> {
    let sig_push_bytes = PushBytesBuf::try_from(signature_bytes).map_err(|e| {
        WalletError::BitcoinError(format!(
            "Failed to convert signature to PushBytesBuf: {:?}",
            e
        ))
    })?;

    let pubkey_push_bytes = PushBytesBuf::try_from(pubkey_bytes).map_err(|e| {
        WalletError::BitcoinError(format!("Failed to convert pubkey to PushBytesBuf: {:?}", e))
    })?;

    let script_sig = Builder::new()
        .push_slice(&sig_push_bytes[..])
        .push_slice(&pubkey_push_bytes[..])
        .into_script();

    input.final_script_sig = Some(script_sig);
    Ok(())
}

/// Add signature to P2SH-P2WPKH input
fn add_p2sh_p2wpkh_signature(
    input: &mut bitcoin::psbt::Input,
    signature_bytes: Vec<u8>,
    pubkey_bytes: Vec<u8>,
) -> Result<()> {
    // 1. Create redeem script (P2WPKH)
    let compressed_pubkey = bitcoin::key::CompressedPublicKey::from_slice(&pubkey_bytes)
        .map_err(|e| WalletError::BitcoinError(format!("Invalid public key: {}", e)))?;

    // Use wpubkey_hash for P2WPKH
    let pubkey_hash = compressed_pubkey.wpubkey_hash();
    let redeem_script = ScriptBuf::new_p2wpkh(&pubkey_hash);

    // 2. Set script_sig to push redeem script
    let redeem_script_bytes = PushBytesBuf::try_from(redeem_script.to_bytes()).map_err(|e| {
        WalletError::BitcoinError(format!(
            "Failed to convert redeem script to PushBytesBuf: {:?}",
            e
        ))
    })?;

    let script_sig = Builder::new()
        .push_slice(&redeem_script_bytes[..])
        .into_script();

    input.final_script_sig = Some(script_sig);

    // 3. Set witness data (same as P2WPKH)
    input.final_script_witness = Some(create_witness_with_sig_and_pubkey(
        signature_bytes,
        pubkey_bytes,
    ));

    Ok(())
}

/// Add signature to P2TR input
fn add_p2tr_signature(input: &mut bitcoin::psbt::Input, signature_bytes: Vec<u8>) -> Result<()> {
    let mut witness = bitcoin::blockdata::witness::Witness::new();
    witness.push(signature_bytes);
    input.final_script_witness = Some(witness);

    // Empty script_sig for segwit
    input.final_script_sig = Some(create_empty_script_sig());

    Ok(())
}

/// Add signature to P2WSH input
fn add_p2wsh_signature(
    input: &mut bitcoin::psbt::Input,
    signature_bytes: Vec<u8>,
    pubkey_bytes: Vec<u8>,
    witness_script: &ScriptBuf,
) -> Result<()> {
    let mut witness = bitcoin::blockdata::witness::Witness::new();

    // Add signature
    witness.push(signature_bytes);

    // Add public key
    witness.push(pubkey_bytes);

    // Add the witness script
    witness.push(witness_script.as_bytes());

    input.final_script_witness = Some(witness);

    // Empty script_sig for segwit
    input.final_script_sig = Some(create_empty_script_sig());

    Ok(())
}

/// Add signature to PSBT input based on address type
fn add_signature_to_input(
    input: &mut bitcoin::psbt::Input,
    signature_bytes: Vec<u8>,
    pubkey_bytes: Vec<u8>,
    address_type: &str,
    witness_script: Option<&ScriptBuf>,
) -> Result<()> {
    let addr_type = AddressType::from_str(standardize_address_type(address_type));

    match addr_type {
        AddressType::P2WPKH => add_p2wpkh_signature(input, signature_bytes, pubkey_bytes),

        AddressType::P2PKH => add_p2pkh_signature(input, signature_bytes, pubkey_bytes),

        AddressType::P2SHP2WPKH => add_p2sh_p2wpkh_signature(input, signature_bytes, pubkey_bytes),

        AddressType::P2TR => add_p2tr_signature(input, signature_bytes),

        AddressType::P2WSH => {
            if let Some(script) = witness_script {
                add_p2wsh_signature(input, signature_bytes, pubkey_bytes, script)
            } else {
                Err(WalletError::BitcoinError(format!(
                    "Missing witness script for P2WSH"
                )))
            }
        }

        AddressType::Unknown => Err(WalletError::BitcoinError(format!(
            "Unsupported address type: {}",
            address_type
        ))),
    }
}

//
// PSBT PROCESSING
//

/// Try sign a PSBT input with a private key if possible
fn try_sign_input(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    input: &mut bitcoin::psbt::Input,
    input_index: usize,
    private_key: &PrivateKey,
    public_key: &PublicKey,
    address_type: &str,
    script_pubkey: &ScriptBuf,
    network: Network,
) -> Result<bool> {
    // Check if this key can sign this input
    if !can_sign_input(
        script_pubkey,
        public_key,
        address_type,
        Some(input),
        network,
    )? {
        return Ok(false);
    }

    // Clone the witness script if needed, to avoid borrowing issues
    let witness_script_clone = if address_type == "p2wsh" {
        input.witness_script.clone()
    } else {
        None
    };

    // Get the signing script
    let signing_script = get_signing_script(
        public_key,
        script_pubkey,
        address_type,
        witness_script_clone.as_ref(),
    )?;

    // Get secret key from private key
    let secret_key = bitcoin::secp256k1::SecretKey::from_slice(&private_key.inner[..])
        .map_err(|e| WalletError::BitcoinError(format!("Failed to create secret key: {:?}", e)))?;

    // Compute signature based on address type
    let signature_bytes = compute_signature(
        secp,
        sighash_cache,
        input_index,
        input,
        &signing_script,
        &secret_key,
        public_key,
        address_type,
    )?;

    // Add the signature to the input
    add_signature_to_input(
        input,
        signature_bytes,
        public_key.to_bytes(),
        address_type,
        witness_script_clone.as_ref(),
    )?;

    Ok(true)
}

/// Initialize signing context and signed_inputs vector
fn init_signing_context(input_count: usize) -> (Secp256k1<bitcoin::secp256k1::All>, Vec<bool>) {
    // Create secp256k1 context for signing
    let secp = Secp256k1::new();
    // Track which inputs were signed
    let signed_inputs = vec![false; input_count];

    (secp, signed_inputs)
}

/// Get the script_pubkey for an input
fn get_input_script_pubkey(psbt: &Psbt, input_index: usize) -> Option<ScriptBuf> {
    psbt.inputs
        .get(input_index)
        .and_then(|input| input.witness_utxo.as_ref())
        .map(|utxo| utxo.script_pubkey.clone())
}

/// Try to sign a specific input with a key
fn sign_input_with_key(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    psbt: &mut Psbt,
    input_index: usize,
    signed_inputs: &mut [bool],
    private_key: &PrivateKey,
    public_key: &PublicKey,
    address_type: &str,
    network: Network,
) -> Result<()> {
    // Skip already signed inputs
    if signed_inputs[input_index] {
        return Ok(());
    }

    // Get script_pubkey for this input
    let script_pubkey = match get_input_script_pubkey(psbt, input_index) {
        Some(script) => script,
        None => {
            // Log warning for missing witness_utxo
            eprintln!(
                "Warning: Input at index {} missing witness_utxo, required for signing",
                input_index
            );
            return Ok(());
        }
    };

    // Try to sign the input
    let input = &mut psbt.inputs[input_index];
    match try_sign_input(
        secp,
        sighash_cache,
        input,
        input_index,
        private_key,
        public_key,
        address_type,
        &script_pubkey,
        network,
    ) {
        Ok(true) => {
            signed_inputs[input_index] = true;
            Ok(())
        }
        Ok(false) => Ok(()), // Could not sign this input with this key
        Err(e) => Err(e),    // Propagate error
    }
}

/// Process a private key for all inputs in the PSBT
fn process_key_for_inputs(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    sighash_cache: &mut SighashCache<&Transaction>,
    psbt: &mut Psbt,
    signed_inputs: &mut Vec<bool>,
    private_key: &PrivateKey,
    public_key: &PublicKey,
    address_type: &str,
    network: Network,
) -> Result<()> {
    // Sign each input one by one
    for i in 0..psbt.inputs.len() {
        sign_input_with_key(
            secp,
            sighash_cache,
            psbt,
            i,
            signed_inputs,
            private_key,
            public_key,
            address_type,
            network,
        )?;
    }

    Ok(())
}

/// Sign PSBT inputs with wallet private keys
fn sign_psbt_inputs(
    psbt: &mut Psbt,
    addresses: &HashMap<String, AddressInfo>,
    network: Network,
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
                return Err(WalletError::BitcoinError(format!(
                    "Invalid private key for {}: {:?}",
                    addr_str, e
                )));
            }
        };

        // Get the public key
        let public_key = PublicKey::from_private_key(&secp, &private_key);

        // Process this key for all inputs
        process_key_for_inputs(
            &secp,
            &mut sighash_cache,
            psbt,
            &mut signed_inputs,
            &private_key,
            &public_key,
            &info.address_type,
            network,
        )?;
    }

    Ok(signed_inputs)
}

/// Extract and serialize the final transaction
fn extract_and_serialize_transaction(psbt: Psbt) -> Result<String> {
    let finalized_tx = psbt.extract_tx().map_err(|e| {
        WalletError::BitcoinError(format!("Failed to extract transaction: {:?}", e))
    })?;

    // Serialize to hex
    let signed_tx_bytes = serialize(&finalized_tx);
    let signed_tx_hex = hex::encode(signed_tx_bytes);

    Ok(signed_tx_hex)
}

//
// PUBLIC API
//

/// Sign a raw Bitcoin transaction with a specific network
///
/// This function signs an unsigned transaction with private keys from the wallet.
/// It supports P2PKH, P2WPKH (bech32), P2SH-P2WPKH, P2WSH, and P2TR inputs.
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
    let signed_inputs = sign_psbt_inputs(&mut psbt, addresses, network)?;

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
