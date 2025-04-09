use bitcoin::blockdata::witness::Witness;
use bitcoin::key::CompressedPublicKey;
use bitcoin::secp256k1::Message;
use bitcoin::PublicKey;
use bitcoin::ScriptBuf;
use bitcoin::XOnlyPublicKey;

use crate::signer::types::Result;
use crate::wallet::WalletError;

/// Decode a script hex string into a ScriptBuf
pub fn decode_script(script_hex: &str, index: usize) -> Result<ScriptBuf> {
    let script_bytes = hex::decode(script_hex).map_err(|e| {
        WalletError::BitcoinError(format!(
            "Invalid script_pubkey hex at index {}: {}",
            index, e
        ))
    })?;

    Ok(ScriptBuf::from_bytes(script_bytes))
}

/// Creates a Message from a signature hash
pub fn create_message_from_hash(sighash: &[u8]) -> Result<Message> {
    Message::from_digest_slice(sighash)
        .map_err(|e| WalletError::BitcoinError(format!("Failed to create message: {}", e)))
}

/// Creates a standard witness with signature and public key
pub fn create_witness_with_sig_and_pubkey(
    signature_bytes: Vec<u8>,
    pubkey_bytes: Vec<u8>,
) -> Witness {
    let mut witness = Witness::new();
    witness.push(signature_bytes);
    witness.push(pubkey_bytes);
    witness
}

/// Creates an empty script_sig for SegWit inputs
pub fn create_empty_script_sig() -> ScriptBuf {
    ScriptBuf::new()
}

/// Get xonly pubkey from a regular pubkey
pub fn get_xonly_pubkey(public_key: &PublicKey) -> Result<XOnlyPublicKey> {
    XOnlyPublicKey::from_slice(&public_key.to_bytes()[1..33])
        .map_err(|e| WalletError::BitcoinError(format!("Failed to convert to xonly pubkey: {}", e)))
}

/// Converts a PublicKey to CompressedPublicKey
pub fn get_compressed_pubkey(public_key: &PublicKey) -> Result<CompressedPublicKey> {
    CompressedPublicKey::from_slice(&public_key.to_bytes())
        .map_err(|e| WalletError::BitcoinError(format!("Invalid public key: {}", e)))
}

/// Standardize address type string to ensure consistency
pub fn standardize_address_type(address_type: &str) -> &str {
    match address_type {
        "bech32" => "p2wpkh",
        _ => address_type,
    }
}
