use bitcoin::secp256k1::{Secp256k1, Message};
use bitcoin::secp256k1::ecdsa;
use bitcoin::PublicKey;
use bitcoin::XOnlyPublicKey;
use bitcoin::sighash::EcdsaSighashType;

use crate::signer::types::Result;
use crate::wallet::WalletError;

/// Verifies an ECDSA signature
pub fn verify_ecdsa_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    message: &Message,
    signature: &ecdsa::Signature,
    public_key: &PublicKey,
) -> Result<()> {
    if secp
        .verify_ecdsa(message, signature, &public_key.inner)
        .is_err()
    {
        return Err(WalletError::BitcoinError(
            "Generated ECDSA signature failed verification".to_string()
        ));
    }
    Ok(())
}

/// Verifies a Schnorr signature
pub fn verify_schnorr_signature(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    message: &Message,
    signature: &bitcoin::secp256k1::schnorr::Signature,
    xonly_pubkey: &XOnlyPublicKey,
) -> Result<()> {
    if secp
        .verify_schnorr(signature, message, xonly_pubkey)
        .is_err()
    {
        return Err(WalletError::BitcoinError(
            "Generated Schnorr signature failed verification".to_string()
        ));
    }
    Ok(())
}

/// Encodes an ECDSA signature with sighash type
pub fn encode_ecdsa_signature(
    signature: &ecdsa::Signature,
    sighash_type: EcdsaSighashType,
) -> Vec<u8> {
    let mut sig_bytes = signature.serialize_der().to_vec();
    sig_bytes.push(sighash_type as u8);
    sig_bytes
}