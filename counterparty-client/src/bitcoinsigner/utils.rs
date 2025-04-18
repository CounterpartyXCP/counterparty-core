use bitcoin::blockdata::script::{Builder, PushBytesBuf};
use bitcoin::blockdata::witness::Witness;
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::{Message, Secp256k1};
use bitcoin::sighash::{EcdsaSighashType, SighashCache, TapSighashType};
use bitcoin::{CompressedPublicKey, Network, PrivateKey, PublicKey, ScriptBuf, Transaction, XOnlyPublicKey};
use std::str::FromStr;

use super::types::{Result, UTXOType};
use crate::wallet::WalletError;

/// Create a message from a hash
pub fn create_message_from_hash(hash: &[u8]) -> Result<Message> {
    Message::from_digest_slice(hash)
        .map_err(|e| WalletError::BitcoinError(format!("Failed to create message: {}", e)))
}

/// Decode a hex-encoded script
pub fn decode_script(script_hex: &str) -> Result<ScriptBuf> {
    let script_bytes = hex::decode(script_hex)
        .map_err(|e| WalletError::BitcoinError(format!("Invalid script hex: {}", e)))?;

    Ok(ScriptBuf::from_bytes(script_bytes))
}

/// Create an empty script signature (used in SegWit)
pub fn create_empty_script_sig() -> ScriptBuf {
    ScriptBuf::new()
}

/// Create a witness stack with signature and public key
pub fn create_witness_stack(signature: Vec<u8>, pubkey: Vec<u8>) -> Witness {
    let mut witness = Witness::new();
    witness.push(signature);
    witness.push(pubkey);
    witness
}

/// Get an xonly public key from a standard public key
pub fn get_xonly_pubkey(public_key: &PublicKey) -> Result<XOnlyPublicKey> {
    XOnlyPublicKey::from_slice(&public_key.to_bytes()[1..33])
        .map_err(|e| WalletError::BitcoinError(format!("Failed to convert to xonly pubkey: {}", e)))
}

/// Get a compressed public key from a public key
pub fn get_compressed_pubkey(public_key: &PublicKey) -> Result<CompressedPublicKey> {
    CompressedPublicKey::from_slice(&public_key.to_bytes())
        .map_err(|e| WalletError::BitcoinError(format!("Invalid public key: {}", e)))
}

/// Determine the sighash type for ECDSA signatures based on input data
pub fn get_ecdsa_sighash_type(input: &PsbtInput) -> EcdsaSighashType {
    match input.sighash_type {
        Some(s) => s.ecdsa_hash_ty().unwrap_or(EcdsaSighashType::All),
        None => EcdsaSighashType::All,
    }
}

/// Determine the sighash type for Taproot signatures based on input data
pub fn get_tap_sighash_type(input: &PsbtInput) -> TapSighashType {
    match input.sighash_type {
        Some(s) => s.taproot_hash_ty().unwrap_or(TapSighashType::All),
        None => TapSighashType::All,
    }
}

/// Encode an ECDSA signature with its sighash type
pub fn encode_ecdsa_signature(
    sig: &bitcoin::secp256k1::ecdsa::Signature,
    sighash_type: EcdsaSighashType,
) -> Vec<u8> {
    let mut sig_bytes = sig.serialize_der().to_vec();
    sig_bytes.push(sighash_type as u8);
    sig_bytes
}

/// Parse a private key from a string
pub fn parse_private_key(private_key_str: &str, _network: Network) -> Result<PrivateKey> {
    PrivateKey::from_str(private_key_str).map_err(|e| {
        WalletError::BitcoinError(format!("Invalid private key: {:?}", e))
    })
}

/// Get a public key from a private key
pub fn get_public_key(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    private_key: &PrivateKey,
) -> PublicKey {
    PublicKey::from_private_key(secp, private_key)
}

/// Convert script bytes to PushBytesBuf for script building
pub fn to_push_bytes(bytes: &[u8]) -> Result<PushBytesBuf> {
    PushBytesBuf::try_from(bytes.to_vec()).map_err(|e| {
        WalletError::BitcoinError(format!("Failed to convert to push bytes: {:?}", e))
    })
}

/// Convert hex string to bytes
pub fn hex_to_bytes(hex_str: &str) -> Result<Vec<u8>> {
    hex::decode(hex_str).map_err(|e| {
        WalletError::BitcoinError(format!("Invalid hex string: {}", e))
    })
}

/// Convert an UTXO type to a string representation
pub fn utxo_type_to_string(utxo_type: UTXOType) -> &'static str {
    match utxo_type {
        UTXOType::P2PKH => "p2pkh",
        UTXOType::P2SH => "p2sh",
        UTXOType::P2WPKH => "p2wpkh",
        UTXOType::P2WSH => "p2wsh",
        UTXOType::P2TRKPS => "p2tr-kps",
        UTXOType::P2TRSPS => "p2tr-sps",
        UTXOType::Unknown => "unknown",
    }
}

/// Verify if the signature is successful by checking if the public key can sign the input
pub fn can_sign_input(
    script_pubkey: &ScriptBuf,
    public_key: &PublicKey,
    utxo_type: UTXOType,
    network: Network,
) -> Result<bool> {
    match utxo_type {
        UTXOType::P2PKH => {
            let address = bitcoin::Address::p2pkh(public_key, network);
            Ok(script_pubkey == &address.script_pubkey())
        },
        UTXOType::P2WPKH => {
            let compressed_key = get_compressed_pubkey(public_key)?;
            let address = bitcoin::Address::p2wpkh(&compressed_key, network);
            Ok(script_pubkey == &address.script_pubkey())
        },
        UTXOType::P2SH => {
            // For P2SH, we need the redeem script to verify
            // This is typically handled in the specific signing function
            Ok(false)
        },
        UTXOType::P2WSH => {
            // For P2WSH, we need the witness script to verify
            // This is typically handled in the specific signing function
            Ok(false)
        },
        UTXOType::P2TRKPS => {
            let secp = Secp256k1::verification_only();
            let xonly_pubkey = get_xonly_pubkey(public_key)?;
            let address = bitcoin::Address::p2tr(&secp, xonly_pubkey, None, network);
            Ok(script_pubkey == &address.script_pubkey())
        },
        UTXOType::P2TRSPS => {
            // For P2TR script path, this is handled in the specific signing function
            // We rely on the source_address field
            Ok(false)
        },
        UTXOType::Unknown => Ok(false),
    }
}
