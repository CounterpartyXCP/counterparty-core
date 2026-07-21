// Common utility functions for transaction signing across different address types

use bitcoin::amount::Amount;
use bitcoin::blockdata::script::PushBytesBuf;
use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::{Message, Secp256k1, SecretKey};
use bitcoin::sighash::{EcdsaSighashType, SighashCache, TapSighashType};
use bitcoin::{CompressedPublicKey, PublicKey, ScriptBuf, TapSighash, Transaction, XOnlyPublicKey};

use super::types::{Result, UTXOType};
use crate::wallet::WalletError;

/// Convert script bytes to PushBytesBuf for script building
pub fn to_push_bytes(bytes: &[u8]) -> Result<PushBytesBuf> {
    PushBytesBuf::try_from(bytes.to_vec())
        .map_err(|e| WalletError::BitcoinError(format!("Failed to convert to push bytes: {:?}", e)))
}

/// Create a message from a hash
pub fn create_message_from_hash(hash: &[u8]) -> Result<Message> {
    Message::from_digest_slice(hash)
        .map_err(|e| WalletError::BitcoinError(format!("Failed to create message: {}", e)))
}

pub fn create_message_from_tap_sighash(sighash: TapSighash) -> Result<Message> {
    let mut sighash_bytes = [0u8; 32];
    let hash_bytes: &[u8] = sighash.as_ref();
    sighash_bytes.copy_from_slice(&hash_bytes[0..32]);
    create_message_from_hash(&sighash_bytes)
}

/// Create an empty script signature (used in SegWit)
pub fn create_empty_script_sig() -> ScriptBuf {
    ScriptBuf::new()
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

/// Signs a message with ECDSA and returns the signature bytes
pub fn sign_message_ecdsa(
    secp: &Secp256k1<bitcoin::secp256k1::All>,
    message: &Message,
    secret_key: &SecretKey,
    public_key: &PublicKey,
    sighash_type: EcdsaSighashType,
) -> Result<Vec<u8>> {
    let signature = secp.sign_ecdsa(message, secret_key);

    // Verify signature
    if secp
        .verify_ecdsa(message, &signature, &public_key.inner)
        .is_err()
    {
        return Err(WalletError::BitcoinError(
            "Generated signature failed verification".to_string(),
        ));
    }

    // Encode the signature with sighash type
    Ok(encode_ecdsa_signature(&signature, sighash_type))
}

/// Computes the legacy signature hash for P2PKH and legacy P2SH inputs
pub fn compute_legacy_sighash(
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    script_pubkey: &ScriptBuf,
    sighash_type: EcdsaSighashType,
) -> Result<[u8; 32]> {
    let sighash = sighash_cache
        .legacy_signature_hash(input_index, script_pubkey, sighash_type as u32)
        .map_err(|e| {
            WalletError::BitcoinError(format!("Failed to compute signature hash: {}", e))
        })?;

    // Convert sighash to [u8; 32]
    let mut bytes = [0u8; 32];
    let hash_bytes: &[u8] = sighash.as_ref();
    bytes.copy_from_slice(&hash_bytes[0..32]);
    Ok(bytes)
}

/// Computes the signature hash for SegWit inputs (P2WPKH or P2SH-P2WPKH)
pub fn compute_segwit_sighash(
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    script_pubkey: &ScriptBuf,
    amount: u64,
    sighash_type: EcdsaSighashType,
) -> Result<[u8; 32]> {
    let amount = Amount::from_sat(amount);
    let sighash = sighash_cache
        .p2wpkh_signature_hash(input_index, script_pubkey, amount, sighash_type)
        .map_err(|e| {
            WalletError::BitcoinError(format!("Failed to compute signature hash: {}", e))
        })?;

    // Convert sighash to [u8; 32]
    let mut bytes = [0u8; 32];
    let hash_bytes: &[u8] = sighash.as_ref();
    bytes.copy_from_slice(&hash_bytes[0..32]);
    Ok(bytes)
}

/// Computes the signature hash for P2WSH inputs
pub fn compute_p2wsh_sighash(
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    witness_script: &ScriptBuf,
    amount: u64,
    sighash_type: EcdsaSighashType,
) -> Result<[u8; 32]> {
    let amount = Amount::from_sat(amount);
    let sighash = sighash_cache
        .p2wsh_signature_hash(input_index, witness_script, amount, sighash_type)
        .map_err(|e| {
            WalletError::BitcoinError(format!("Failed to compute signature hash: {}", e))
        })?;

    // Convert sighash to [u8; 32]
    let mut bytes = [0u8; 32];
    let hash_bytes: &[u8] = sighash.as_ref();
    bytes.copy_from_slice(&hash_bytes[0..32]);
    Ok(bytes)
}

/// Common function to handle ECDSA signature creation across different address types
pub fn create_and_verify_ecdsa_signature(
    sighash_cache: &mut SighashCache<&Transaction>,
    input_index: usize,
    script_code: &ScriptBuf,
    amount: Option<u64>,
    utxo_type: UTXOType,
    secret_key: &SecretKey,
    public_key: &PublicKey,
    input: &mut PsbtInput,
) -> Result<Vec<u8>> {
    let sighash_type = get_ecdsa_sighash_type(input);
    // Compute the sighash based on the address type
    let sighash = match utxo_type {
        UTXOType::P2PKH => {
            compute_legacy_sighash(sighash_cache, input_index, script_code, sighash_type)?
        }
        UTXOType::P2WPKH => {
            let amount = amount.ok_or_else(|| {
                WalletError::BitcoinError("Amount required for SegWit inputs".to_string())
            })?;
            compute_segwit_sighash(
                sighash_cache,
                input_index,
                script_code,
                amount,
                sighash_type,
            )?
        }
        UTXOType::P2WSH => {
            let amount = amount.ok_or_else(|| {
                WalletError::BitcoinError("Amount required for SegWit inputs".to_string())
            })?;
            compute_p2wsh_sighash(
                sighash_cache,
                input_index,
                script_code,
                amount,
                sighash_type,
            )?
        }
        UTXOType::P2SH => {
            // For P2SH, need to determine if it's wrapping P2WPKH or legacy
            if script_code.is_p2wpkh() {
                let amount = amount.ok_or_else(|| {
                    WalletError::BitcoinError("Amount required for SegWit inputs".to_string())
                })?;
                compute_segwit_sighash(
                    sighash_cache,
                    input_index,
                    script_code,
                    amount,
                    sighash_type,
                )?
            } else {
                compute_legacy_sighash(sighash_cache, input_index, script_code, sighash_type)?
            }
        }
        _ => {
            return Err(WalletError::BitcoinError(
                "Unsupported UTXO type for ECDSA signing".to_string(),
            ))
        }
    };

    // Create a message from the sighash
    let message = create_message_from_hash(&sighash)?;

    // Create a secp256k1 context
    let secp = Secp256k1::new();

    // Sign the message
    sign_message_ecdsa(&secp, &message, secret_key, public_key, sighash_type)
}

/// Helper to create a Bitcoin error with formatted message
pub fn bitcoin_err<S: Into<String>>(msg: S) -> WalletError {
    WalletError::BitcoinError(msg.into())
}

#[cfg(test)]
mod tests {
    use super::*;
    use bitcoin::{absolute, transaction, OutPoint, Sequence, TxIn, TxOut, Witness};

    fn keypair(seed: u8) -> (SecretKey, PublicKey) {
        let secp = Secp256k1::new();
        let sk = SecretKey::from_slice(&[seed; 32]).unwrap();
        let pk = bitcoin::PrivateKey::new(sk, bitcoin::Network::Regtest);
        (sk, PublicKey::from_private_key(&secp, &pk))
    }

    fn one_input_tx() -> Transaction {
        Transaction {
            version: transaction::Version::TWO,
            lock_time: absolute::LockTime::ZERO,
            input: vec![TxIn {
                previous_output: OutPoint::null(),
                script_sig: ScriptBuf::new(),
                sequence: Sequence::MAX,
                witness: Witness::new(),
            }],
            output: vec![TxOut {
                value: Amount::from_sat(1000),
                script_pubkey: ScriptBuf::new(),
            }],
        }
    }

    #[test]
    fn to_push_bytes_roundtrips() {
        assert_eq!(to_push_bytes(&[1, 2, 3]).unwrap().as_bytes(), &[1, 2, 3]);
    }

    #[test]
    fn create_message_from_hash_requires_32_bytes() {
        assert!(create_message_from_hash(&[0u8; 32]).is_ok());
        assert!(create_message_from_hash(&[0u8; 31]).is_err());
    }

    #[test]
    fn empty_script_sig_is_empty() {
        assert!(create_empty_script_sig().is_empty());
    }

    #[test]
    fn ecdsa_sighash_type_defaults_to_all_and_reads_explicit() {
        let mut input = PsbtInput::default();
        assert_eq!(get_ecdsa_sighash_type(&input), EcdsaSighashType::All);
        input.sighash_type = Some(EcdsaSighashType::All.into());
        assert_eq!(get_ecdsa_sighash_type(&input), EcdsaSighashType::All);
    }

    #[test]
    fn tap_sighash_type_defaults_to_all_and_reads_explicit() {
        let mut input = PsbtInput::default();
        assert_eq!(get_tap_sighash_type(&input), TapSighashType::All);
        input.sighash_type = Some(TapSighashType::All.into());
        assert_eq!(get_tap_sighash_type(&input), TapSighashType::All);
    }

    #[test]
    fn xonly_and_compressed_pubkey_conversions_succeed() {
        let (_, public) = keypair(0x11);
        assert!(get_xonly_pubkey(&public).is_ok());
        assert!(get_compressed_pubkey(&public).is_ok());
    }

    #[test]
    fn sign_message_ecdsa_produces_der_with_trailing_sighash_flag() {
        let (sk, public) = keypair(0x11);
        let secp = Secp256k1::new();
        let msg = create_message_from_hash(&[7u8; 32]).unwrap();
        let sig = sign_message_ecdsa(&secp, &msg, &sk, &public, EcdsaSighashType::All).unwrap();
        assert_eq!(sig[0], 0x30, "DER signatures start with 0x30");
        assert_eq!(*sig.last().unwrap(), EcdsaSighashType::All as u8);
    }

    #[test]
    fn encode_ecdsa_signature_appends_sighash_flag() {
        let (sk, _) = keypair(0x11);
        let secp = Secp256k1::new();
        let msg = create_message_from_hash(&[9u8; 32]).unwrap();
        let raw = secp.sign_ecdsa(&msg, &sk);
        let encoded = encode_ecdsa_signature(&raw, EcdsaSighashType::None);
        assert_eq!(*encoded.last().unwrap(), EcdsaSighashType::None as u8);
    }

    #[test]
    fn bitcoin_err_wraps_message() {
        let e = bitcoin_err("boom");
        assert!(matches!(e, WalletError::BitcoinError(_)));
        assert!(e.to_string().contains("boom"));
    }

    #[test]
    fn create_and_verify_ecdsa_requires_amount_for_segwit() {
        let tx = one_input_tx();
        let mut cache = SighashCache::new(&tx);
        let (sk, public) = keypair(0x11);
        let mut input = PsbtInput::default();
        // P2WPKH with no amount is a clean error, not a panic.
        let res = create_and_verify_ecdsa_signature(
            &mut cache,
            0,
            &ScriptBuf::new(),
            None,
            UTXOType::P2WPKH,
            &sk,
            &public,
            &mut input,
        );
        assert!(res.is_err());
    }

    #[test]
    fn create_and_verify_ecdsa_rejects_unsupported_type() {
        let tx = one_input_tx();
        let mut cache = SighashCache::new(&tx);
        let (sk, public) = keypair(0x11);
        let mut input = PsbtInput::default();
        // Taproot key-path is not ECDSA-signable here.
        let res = create_and_verify_ecdsa_signature(
            &mut cache,
            0,
            &ScriptBuf::new(),
            Some(1000),
            UTXOType::P2TRKPS,
            &sk,
            &public,
            &mut input,
        );
        assert!(res.is_err());
    }

    #[test]
    fn create_and_verify_ecdsa_signs_p2pkh_input() {
        // Exercises the legacy sighash + ECDSA sign/verify path end-to-end.
        let (sk, public) = keypair(0x11);
        let spk = bitcoin::Address::p2pkh(public, bitcoin::Network::Regtest).script_pubkey();
        let tx = one_input_tx();
        let mut cache = SighashCache::new(&tx);
        let mut input = PsbtInput::default();
        let sig = create_and_verify_ecdsa_signature(
            &mut cache,
            0,
            &spk,
            None,
            UTXOType::P2PKH,
            &sk,
            &public,
            &mut input,
        )
        .unwrap();
        assert_eq!(sig[0], 0x30);
    }
}
