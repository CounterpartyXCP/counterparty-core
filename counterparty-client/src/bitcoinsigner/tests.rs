//! Hermetic round-trip tests for the transaction signer.
//!
//! Strategy (per the release plan): prefer property/round-trip assertions over
//! brittle hardcoded hex. For each script type we build an unsigned transaction
//! plus a matching UTXO, sign it through the crate's public
//! `sign_transaction`, and assert that:
//!   * signing succeeds (each signer verifies its own ECDSA/Schnorr signature
//!     against the input's key before returning — a successful sign is real
//!     cryptographic verification, not a stub),
//!   * the resulting PSBT is finalized (script_sig and/or witness present), and
//!   * the transaction re-serializes and re-parses cleanly.
//!
//! For the single-key ECDSA cases (P2PKH, P2WPKH, both P2WSH shapes, legacy
//! P2SH, nested P2SH-P2WSH, and P2SH-P2WPKH) we additionally *independently*
//! re-derive the sighash from the signed transaction and verify the produced
//! signature against the input's script/pubkey with `secp256k1`.
//!
//! Coverage: P2PKH, P2WPKH, P2SH (legacy), P2SH-P2WPKH, P2SH-P2WSH (nested),
//! P2WSH (pay-to-pubkey and pay-to-pubkey-hash), P2TR key-path, P2TR script-path,
//! plus multi-input (two taproot key-path, two taproot script-path) and
//! mixed-input (taproot + P2WPKH) transactions.

use std::collections::HashMap;

use bitcoin::blockdata::script::{Builder, Instruction};
use bitcoin::consensus::encode::{deserialize, serialize};
use bitcoin::key::TapTweak;
use bitcoin::opcodes::all::{OP_CHECKMULTISIG, OP_CHECKSIG, OP_PUSHNUM_1};
use bitcoin::secp256k1::{Message, Secp256k1, SecretKey};
use bitcoin::sighash::{EcdsaSighashType, Prevouts, SighashCache, TapSighashType};
use bitcoin::taproot::{LeafVersion, TapLeafHash, TaprootBuilder};
use bitcoin::{
    absolute, transaction, Address, Amount, CompressedPublicKey, Network, OutPoint, PrivateKey,
    PublicKey, ScriptBuf, Sequence, Transaction, TxIn, TxOut, Witness, XOnlyPublicKey,
};
use secrecy::SecretString;

use super::sign_transaction;
use super::types::{UTXOList, UTXO};
use crate::wallet::AddressInfo;

const NETWORK: Network = Network::Regtest;
const UTXO_AMOUNT: u64 = 100_000;

/// Deterministic key material shared by all signer tests.
struct TestKey {
    wif: String,
    public_key: PublicKey,
    xonly: XOnlyPublicKey,
}

fn test_key() -> TestKey {
    let secp = Secp256k1::new();
    let sk = SecretKey::from_slice(&[0x11u8; 32]).unwrap();
    let pk = PrivateKey::new(sk, NETWORK);
    let public_key = PublicKey::from_private_key(&secp, &pk);
    let xonly = XOnlyPublicKey::from_slice(&public_key.to_bytes()[1..33]).unwrap();
    TestKey {
        wif: pk.to_wif(),
        public_key,
        xonly,
    }
}

/// A wallet address map with a single entry keyed by `addr`.
fn address_map(
    addr: &str,
    wif: &str,
    addr_type: &str,
    pubkey: &str,
) -> HashMap<String, AddressInfo> {
    let mut m = HashMap::new();
    m.insert(
        addr.to_string(),
        AddressInfo {
            public_key: pubkey.to_string(),
            private_key: SecretString::from(wif.to_string()),
            label: "test".to_string(),
            address_type: addr_type.to_string(),
        },
    );
    m
}

/// A minimal single-input, single-output unsigned transaction.
fn unsigned_tx() -> Transaction {
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
            value: Amount::from_sat(UTXO_AMOUNT - 1_000),
            script_pubkey: ScriptBuf::new_op_return([]),
        }],
    }
}

/// An unsigned transaction with `n` distinct inputs and a single OP_RETURN
/// output. Distinct outpoints (same null txid, increasing vout) keep the inputs
/// unique without needing real prevout txids.
fn unsigned_tx_n(n: usize) -> Transaction {
    let input = (0..n)
        .map(|i| {
            let mut previous_output = OutPoint::null();
            previous_output.vout = i as u32;
            TxIn {
                previous_output,
                script_sig: ScriptBuf::new(),
                sequence: Sequence::MAX,
                witness: Witness::new(),
            }
        })
        .collect();
    Transaction {
        version: transaction::Version::TWO,
        lock_time: absolute::LockTime::ZERO,
        input,
        output: vec![TxOut {
            value: Amount::from_sat(UTXO_AMOUNT),
            script_pubkey: ScriptBuf::new_op_return([]),
        }],
    }
}

fn raw_hex(tx: &Transaction) -> String {
    hex::encode(serialize(tx))
}

fn parse_signed(hex_str: &str) -> Transaction {
    deserialize(&hex::decode(hex_str).unwrap()).unwrap()
}

/// `<pubkey> OP_CHECKSIG` — a single-key script used for P2SH/P2WSH tests.
fn single_key_script(pubkey: &PublicKey) -> ScriptBuf {
    Builder::new()
        .push_key(pubkey)
        .push_opcode(OP_CHECKSIG)
        .into_script()
}

/// `<xonly> OP_CHECKSIG` — a single-key tapscript for the P2TR script-path test.
fn single_key_tapscript(xonly: &XOnlyPublicKey) -> ScriptBuf {
    Builder::new()
        .push_x_only_key(xonly)
        .push_opcode(OP_CHECKSIG)
        .into_script()
}

#[test]
fn signs_p2pkh_input() {
    let k = test_key();
    let spk = ScriptBuf::new_p2pkh(&k.public_key.pubkey_hash());
    let addr = Address::from_script(&spk, NETWORK).unwrap().to_string();

    let mut utxos = UTXOList::new();
    utxos.add(UTXO::new(UTXO_AMOUNT, spk.clone()));

    let tx = unsigned_tx();
    let addresses = address_map(&addr, &k.wif, "p2pkh", &k.public_key.to_string());
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();

    let parsed = parse_signed(&signed);
    assert!(
        !parsed.input[0].script_sig.is_empty(),
        "P2PKH must produce a scriptSig"
    );
    assert!(
        parsed.input[0].witness.is_empty(),
        "P2PKH must not produce a witness"
    );

    // Independent verification: recompute the legacy sighash and verify the
    // signature embedded in the scriptSig against the pushed pubkey.
    let pushes: Vec<Vec<u8>> = parsed.input[0]
        .script_sig
        .instructions()
        .filter_map(|i| match i {
            Ok(Instruction::PushBytes(b)) => Some(b.as_bytes().to_vec()),
            _ => None,
        })
        .collect();
    assert_eq!(pushes.len(), 2, "scriptSig = <sig> <pubkey>");
    let (sig_bytes, pk_bytes) = (&pushes[0], &pushes[1]);

    let secp = Secp256k1::new();
    let cache = SighashCache::new(&parsed);
    let sighash = cache
        .legacy_signature_hash(0, &spk, EcdsaSighashType::All as u32)
        .unwrap();
    let msg = Message::from_digest_slice(sighash.as_ref()).unwrap();
    let sig =
        bitcoin::secp256k1::ecdsa::Signature::from_der(&sig_bytes[..sig_bytes.len() - 1]).unwrap();
    let pubkey = PublicKey::from_slice(pk_bytes).unwrap();
    assert!(secp.verify_ecdsa(&msg, &sig, &pubkey.inner).is_ok());
}

#[test]
fn signs_p2wpkh_input() {
    let k = test_key();
    let cpk = CompressedPublicKey::from_slice(&k.public_key.to_bytes()).unwrap();
    let spk = ScriptBuf::new_p2wpkh(&cpk.wpubkey_hash());
    let addr = Address::from_script(&spk, NETWORK).unwrap().to_string();

    let mut utxos = UTXOList::new();
    utxos.add(UTXO::new(UTXO_AMOUNT, spk.clone()));

    let tx = unsigned_tx();
    let addresses = address_map(&addr, &k.wif, "bech32", &k.public_key.to_string());
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();

    let parsed = parse_signed(&signed);
    assert!(
        parsed.input[0].script_sig.is_empty(),
        "P2WPKH scriptSig must be empty"
    );
    let witness: Vec<&[u8]> = parsed.input[0].witness.iter().collect();
    assert_eq!(witness.len(), 2, "witness = <sig> <pubkey>");

    // Independent verification of the BIP143 signature.
    let (sig_bytes, pk_bytes) = (witness[0], witness[1]);
    let secp = Secp256k1::new();
    let mut cache = SighashCache::new(&parsed);
    let sighash = cache
        .p2wpkh_signature_hash(
            0,
            &spk,
            Amount::from_sat(UTXO_AMOUNT),
            EcdsaSighashType::All,
        )
        .unwrap();
    let msg = Message::from_digest_slice(sighash.as_ref()).unwrap();
    let sig =
        bitcoin::secp256k1::ecdsa::Signature::from_der(&sig_bytes[..sig_bytes.len() - 1]).unwrap();
    let pubkey = PublicKey::from_slice(pk_bytes).unwrap();
    assert!(secp.verify_ecdsa(&msg, &sig, &pubkey.inner).is_ok());
}

#[test]
fn signs_p2sh_legacy_input() {
    let k = test_key();
    let redeem = single_key_script(&k.public_key);
    let spk = ScriptBuf::new_p2sh(&redeem.script_hash());
    let addr = Address::from_script(&spk, NETWORK).unwrap().to_string();

    let mut utxo = UTXO::new(UTXO_AMOUNT, spk);
    utxo.redeem_script = Some(redeem.clone());
    let mut utxos = UTXOList::new();
    utxos.add(utxo);

    let tx = unsigned_tx();
    let addresses = address_map(&addr, &k.wif, "p2sh", &k.public_key.to_string());
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();

    let parsed = parse_signed(&signed);
    assert!(parsed.input[0].witness.is_empty());
    // Redeem `<pubkey> OP_CHECKSIG` embeds the pubkey, so the scriptSig is
    // `<sig> <redeemScript>` (no separate pubkey push) — the regression being
    // that the old signer always pushed the pubkey.
    let script_pushes: Vec<Vec<u8>> = parsed.input[0]
        .script_sig
        .instructions()
        .filter_map(|i| match i {
            Ok(Instruction::PushBytes(b)) => Some(b.as_bytes().to_vec()),
            _ => None,
        })
        .collect();
    assert_eq!(script_pushes.len(), 2, "scriptSig = <sig> <redeemScript>");
    assert_eq!(
        script_pushes[1],
        redeem.as_bytes(),
        "last push is the redeem script"
    );

    // Independent spendability check: legacy sighash over the redeem script.
    let secp = Secp256k1::new();
    let cache = SighashCache::new(&parsed);
    let sighash = cache
        .legacy_signature_hash(0, &redeem, EcdsaSighashType::All as u32)
        .unwrap();
    let msg = Message::from_digest_slice(sighash.as_ref()).unwrap();
    let sig_bytes = &script_pushes[0];
    let sig =
        bitcoin::secp256k1::ecdsa::Signature::from_der(&sig_bytes[..sig_bytes.len() - 1]).unwrap();
    assert!(secp.verify_ecdsa(&msg, &sig, &k.public_key.inner).is_ok());
}

#[test]
fn signs_p2sh_p2wsh_nested_input() {
    let k = test_key();
    // Nested P2SH-P2WSH: scriptPubKey is P2SH, redeem script is the P2WSH
    // program, and the inner witness script is `<pubkey> OP_CHECKSIG`. Before the
    // fix `get_type` misrouted this to the native-P2WSH signer (empty scriptSig),
    // producing an unspendable input.
    let witness_script = single_key_script(&k.public_key);
    let redeem = ScriptBuf::new_p2wsh(&witness_script.wscript_hash());
    let spk = ScriptBuf::new_p2sh(&redeem.script_hash());
    let addr = Address::from_script(&spk, NETWORK).unwrap().to_string();

    let mut utxo = UTXO::new(UTXO_AMOUNT, spk);
    utxo.redeem_script = Some(redeem.clone());
    utxo.witness_script = Some(witness_script.clone());
    let mut utxos = UTXOList::new();
    utxos.add(utxo);

    let tx = unsigned_tx();
    let addresses = address_map(&addr, &k.wif, "p2sh", &k.public_key.to_string());
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();

    let parsed = parse_signed(&signed);
    // scriptSig pushes the redeem (witness program); witness = <sig> <witnessScript>.
    let script_pushes: Vec<Vec<u8>> = parsed.input[0]
        .script_sig
        .instructions()
        .filter_map(|i| match i {
            Ok(Instruction::PushBytes(b)) => Some(b.as_bytes().to_vec()),
            _ => None,
        })
        .collect();
    assert_eq!(script_pushes.len(), 1, "scriptSig pushes the redeem script");
    assert_eq!(script_pushes[0], redeem.as_bytes());
    let witness: Vec<&[u8]> = parsed.input[0].witness.iter().collect();
    assert_eq!(
        witness.len(),
        2,
        "pay-to-pubkey witness = <sig> <witnessScript>"
    );

    // Independent spendability check: BIP143 P2WSH sighash over the inner script.
    let secp = Secp256k1::new();
    let mut cache = SighashCache::new(&parsed);
    let sighash = cache
        .p2wsh_signature_hash(
            0,
            &witness_script,
            Amount::from_sat(UTXO_AMOUNT),
            EcdsaSighashType::All,
        )
        .unwrap();
    let msg = Message::from_digest_slice(sighash.as_ref()).unwrap();
    let sig_bytes = witness[0];
    let sig =
        bitcoin::secp256k1::ecdsa::Signature::from_der(&sig_bytes[..sig_bytes.len() - 1]).unwrap();
    assert!(secp.verify_ecdsa(&msg, &sig, &k.public_key.inner).is_ok());
}

#[test]
fn signs_p2sh_p2wpkh_input() {
    let k = test_key();
    let cpk = CompressedPublicKey::from_slice(&k.public_key.to_bytes()).unwrap();
    // Redeem script is the P2WPKH program; scriptPubKey wraps it in P2SH.
    let redeem = ScriptBuf::new_p2wpkh(&cpk.wpubkey_hash());
    let spk = ScriptBuf::new_p2sh(&redeem.script_hash());
    let addr = Address::from_script(&spk, NETWORK).unwrap().to_string();

    let mut utxo = UTXO::new(UTXO_AMOUNT, spk);
    utxo.redeem_script = Some(redeem);
    let mut utxos = UTXOList::new();
    utxos.add(utxo);

    let tx = unsigned_tx();
    let addresses = address_map(&addr, &k.wif, "p2sh", &k.public_key.to_string());
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();

    let parsed = parse_signed(&signed);
    // P2SH-P2WPKH: scriptSig pushes the redeem script; witness carries sig+pubkey.
    assert!(
        !parsed.input[0].script_sig.is_empty(),
        "P2SH-P2WPKH must push the redeem script in scriptSig"
    );
    let witness: Vec<&[u8]> = parsed.input[0].witness.iter().collect();
    assert_eq!(witness.len(), 2, "witness = <sig> <pubkey>");

    // Independent spendability check: BIP143 sighash over the P2WPKH redeem
    // program (the wrapped witness program), verified against the pushed pubkey.
    let redeem = ScriptBuf::new_p2wpkh(&cpk.wpubkey_hash());
    let (sig_bytes, pk_bytes) = (witness[0], witness[1]);
    let secp = Secp256k1::new();
    let mut cache = SighashCache::new(&parsed);
    let sighash = cache
        .p2wpkh_signature_hash(
            0,
            &redeem,
            Amount::from_sat(UTXO_AMOUNT),
            EcdsaSighashType::All,
        )
        .unwrap();
    let msg = Message::from_digest_slice(sighash.as_ref()).unwrap();
    let sig =
        bitcoin::secp256k1::ecdsa::Signature::from_der(&sig_bytes[..sig_bytes.len() - 1]).unwrap();
    let pubkey = PublicKey::from_slice(pk_bytes).unwrap();
    assert!(secp.verify_ecdsa(&msg, &sig, &pubkey.inner).is_ok());
}

#[test]
fn signs_p2wsh_pay_to_pubkey_input() {
    let k = test_key();
    // `<pubkey> OP_CHECKSIG` already embeds the pubkey, so the witness must NOT
    // push a separate pubkey — otherwise it stays on the stack and CHECKSIG
    // fails. This is the regression: the old signer always pushed the pubkey.
    let witness_script = single_key_script(&k.public_key);
    let spk = ScriptBuf::new_p2wsh(&witness_script.wscript_hash());
    let addr = Address::from_script(&spk, NETWORK).unwrap().to_string();

    let mut utxo = UTXO::new(UTXO_AMOUNT, spk);
    utxo.witness_script = Some(witness_script.clone());
    let mut utxos = UTXOList::new();
    utxos.add(utxo);

    let tx = unsigned_tx();
    let addresses = address_map(&addr, &k.wif, "p2wsh", &k.public_key.to_string());
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();

    let parsed = parse_signed(&signed);
    assert!(parsed.input[0].script_sig.is_empty());
    let witness: Vec<&[u8]> = parsed.input[0].witness.iter().collect();
    assert_eq!(
        witness.len(),
        2,
        "pay-to-pubkey witness = <sig> <witnessScript>"
    );
    assert_eq!(
        witness[1],
        witness_script.as_bytes(),
        "last element is the script"
    );

    // Independent spendability check: recompute the BIP143 P2WSH sighash and
    // verify the signature against the pubkey embedded in the witness script.
    let secp = Secp256k1::new();
    let mut cache = SighashCache::new(&parsed);
    let sighash = cache
        .p2wsh_signature_hash(
            0,
            &witness_script,
            Amount::from_sat(UTXO_AMOUNT),
            EcdsaSighashType::All,
        )
        .unwrap();
    let msg = Message::from_digest_slice(sighash.as_ref()).unwrap();
    let sig_bytes = witness[0];
    let sig =
        bitcoin::secp256k1::ecdsa::Signature::from_der(&sig_bytes[..sig_bytes.len() - 1]).unwrap();
    assert!(secp.verify_ecdsa(&msg, &sig, &k.public_key.inner).is_ok());
}

#[test]
fn signs_p2wsh_pay_to_pubkey_hash_input() {
    let k = test_key();
    // A P2PKH-style witness script commits to the pubkey *hash*, so the witness
    // must carry the pubkey: <sig> <pubkey> <witnessScript>.
    let witness_script = ScriptBuf::new_p2pkh(&k.public_key.pubkey_hash());
    let spk = ScriptBuf::new_p2wsh(&witness_script.wscript_hash());
    let addr = Address::from_script(&spk, NETWORK).unwrap().to_string();

    let mut utxo = UTXO::new(UTXO_AMOUNT, spk);
    utxo.witness_script = Some(witness_script);
    let mut utxos = UTXOList::new();
    utxos.add(utxo);

    let tx = unsigned_tx();
    let addresses = address_map(&addr, &k.wif, "p2wsh", &k.public_key.to_string());
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();

    let parsed = parse_signed(&signed);
    let witness: Vec<&[u8]> = parsed.input[0].witness.iter().collect();
    assert_eq!(witness.len(), 3, "witness = <sig> <pubkey> <witnessScript>");
    assert_eq!(
        witness[1],
        k.public_key.to_bytes(),
        "middle element is the pubkey"
    );

    // Independent spendability check: BIP143 P2WSH sighash over the P2PKH-style
    // witness script, verified against the pubkey carried in the witness.
    let witness_script = ScriptBuf::new_p2pkh(&k.public_key.pubkey_hash());
    let secp = Secp256k1::new();
    let mut cache = SighashCache::new(&parsed);
    let sighash = cache
        .p2wsh_signature_hash(
            0,
            &witness_script,
            Amount::from_sat(UTXO_AMOUNT),
            EcdsaSighashType::All,
        )
        .unwrap();
    let msg = Message::from_digest_slice(sighash.as_ref()).unwrap();
    let sig_bytes = witness[0];
    let sig =
        bitcoin::secp256k1::ecdsa::Signature::from_der(&sig_bytes[..sig_bytes.len() - 1]).unwrap();
    let pubkey = PublicKey::from_slice(witness[1]).unwrap();
    assert!(secp.verify_ecdsa(&msg, &sig, &pubkey.inner).is_ok());
}

#[test]
fn signs_p2tr_key_path_input() {
    let k = test_key();
    let secp = Secp256k1::new();
    let spk = ScriptBuf::new_p2tr(&secp, k.xonly, None);
    let addr = Address::from_script(&spk, NETWORK).unwrap().to_string();

    let mut utxos = UTXOList::new();
    utxos.add(UTXO::new(UTXO_AMOUNT, spk.clone()));

    let tx = unsigned_tx();
    let addresses = address_map(&addr, &k.wif, "taproot", &k.public_key.to_string());
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();

    let parsed = parse_signed(&signed);
    assert!(parsed.input[0].script_sig.is_empty());
    let witness: Vec<&[u8]> = parsed.input[0].witness.iter().collect();
    // Key-path spend: a single Schnorr signature. The client fixes the sighash
    // type to SIGHASH_DEFAULT, so it is exactly 64 bytes — a 65-byte signature
    // would mean a stray non-default sighash byte was appended.
    assert_eq!(witness.len(), 1, "key-path witness = <schnorr sig>");
    assert_eq!(witness[0].len(), 64, "SIGHASH_DEFAULT => 64-byte signature");
}

#[test]
fn signs_p2tr_script_path_input() {
    let k = test_key();
    let secp = Secp256k1::new();
    let leaf_script = single_key_tapscript(&k.xonly);

    // Build the taproot output that commits to the single-leaf tree so the
    // control block the signer derives is consistent with the scriptPubKey.
    let spend_info = TaprootBuilder::new()
        .add_leaf(0, leaf_script.clone())
        .unwrap()
        .finalize(&secp, k.xonly)
        .unwrap();
    let spk = ScriptBuf::new_p2tr_tweaked(spend_info.output_key());

    // Script-path UTXOs are matched via `source_address`, not scriptPubKey.
    let source_address = "p2tr-script-path-source".to_string();
    let mut utxo = UTXO::new(UTXO_AMOUNT, spk);
    utxo.leaf_script = Some(leaf_script);
    utxo.source_address = Some(source_address.clone());
    let mut utxos = UTXOList::new();
    utxos.add(utxo);

    let tx = unsigned_tx();
    let addresses = address_map(
        &source_address,
        &k.wif,
        "taproot",
        &k.public_key.to_string(),
    );
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();

    let parsed = parse_signed(&signed);
    assert!(parsed.input[0].script_sig.is_empty());
    let witness: Vec<&[u8]> = parsed.input[0].witness.iter().collect();
    // Script-path spend: <signature> <leaf script> <control block>.
    assert_eq!(
        witness.len(),
        3,
        "script-path witness = <sig> <script> <control block>"
    );
}

#[test]
fn rejects_p2tr_script_path_leaf_committing_to_a_different_key() {
    let k = test_key();
    let secp = Secp256k1::new();

    // A leaf that CHECKSIGs a *different* key than the signer's, while the
    // signer's key is the taproot internal key. The output still reconstructs
    // (the address commits to this exact leaf + internal key), so the output-key
    // reconstruction check alone would pass — but the signature is made with the
    // signer's key, which this leaf's CHECKSIG would reject on-chain, giving an
    // unspendable input. The signer must refuse to sign it up front.
    let other_sk = SecretKey::from_slice(&[0x22u8; 32]).unwrap();
    let other_pk = PublicKey::from_private_key(&secp, &PrivateKey::new(other_sk, NETWORK));
    let other_xonly = XOnlyPublicKey::from_slice(&other_pk.to_bytes()[1..33]).unwrap();
    let leaf_script = single_key_tapscript(&other_xonly);

    let spend_info = TaprootBuilder::new()
        .add_leaf(0, leaf_script.clone())
        .unwrap()
        .finalize(&secp, k.xonly)
        .unwrap();
    let spk = ScriptBuf::new_p2tr_tweaked(spend_info.output_key());

    let source_address = "p2tr-wrong-leaf-source".to_string();
    let mut utxo = UTXO::new(UTXO_AMOUNT, spk);
    utxo.leaf_script = Some(leaf_script);
    utxo.source_address = Some(source_address.clone());
    let mut utxos = UTXOList::new();
    utxos.add(utxo);

    let tx = unsigned_tx();
    let addresses = address_map(
        &source_address,
        &k.wif,
        "taproot",
        &k.public_key.to_string(),
    );
    assert!(sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).is_err());
}

/// Regression test for the multi-input Taproot key-path sighash. A BIP341
/// sighash commits to *every* input's prevout, so signing a taproot input in a
/// 2-input transaction must feed the signer both prevouts. Before the fix this
/// returned a `PrevoutsSizeError` and aborted the whole signing.
#[test]
fn signs_multi_input_p2tr_key_path() {
    let k = test_key();
    let secp = Secp256k1::new();
    let spk = ScriptBuf::new_p2tr(&secp, k.xonly, None);
    let addr = Address::from_script(&spk, NETWORK).unwrap().to_string();

    // Two taproot UTXOs spent by the same address.
    let mut utxos = UTXOList::new();
    utxos.add(UTXO::new(UTXO_AMOUNT, spk.clone()));
    utxos.add(UTXO::new(UTXO_AMOUNT, spk));

    let tx = unsigned_tx_n(2);
    let addresses = address_map(&addr, &k.wif, "taproot", &k.public_key.to_string());
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();

    let parsed = parse_signed(&signed);
    assert_eq!(parsed.input.len(), 2);
    for input in &parsed.input {
        let witness: Vec<&[u8]> = input.witness.iter().collect();
        assert_eq!(witness.len(), 1, "each key-path input has one Schnorr sig");
        assert_eq!(witness[0].len(), 64, "SIGHASH_DEFAULT => 64-byte signature");
    }
}

/// Regression test for the multi-input Taproot script-path sighash (same
/// `Prevouts::All` requirement as the key-path case, exercised through the
/// script-path signer).
#[test]
fn signs_multi_input_p2tr_script_path() {
    let k = test_key();
    let secp = Secp256k1::new();
    let leaf_script = single_key_tapscript(&k.xonly);
    let spend_info = TaprootBuilder::new()
        .add_leaf(0, leaf_script.clone())
        .unwrap()
        .finalize(&secp, k.xonly)
        .unwrap();
    let spk = ScriptBuf::new_p2tr_tweaked(spend_info.output_key());

    let source_address = "p2tr-script-path-source".to_string();
    let make_utxo = || {
        let mut u = UTXO::new(UTXO_AMOUNT, spk.clone());
        u.leaf_script = Some(leaf_script.clone());
        u.source_address = Some(source_address.clone());
        u
    };
    let mut utxos = UTXOList::new();
    utxos.add(make_utxo());
    utxos.add(make_utxo());

    let tx = unsigned_tx_n(2);
    let addresses = address_map(
        &source_address,
        &k.wif,
        "taproot",
        &k.public_key.to_string(),
    );
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();

    let parsed = parse_signed(&signed);
    assert_eq!(parsed.input.len(), 2);
    for input in &parsed.input {
        assert_eq!(
            input.witness.len(),
            3,
            "script-path witness = <sig> <script> <control block>"
        );
    }
}

/// Mixed multi-input regression: a taproot input alongside a P2WPKH input. The
/// taproot sighash still needs *all* prevouts even though only one input is
/// taproot.
#[test]
fn signs_mixed_taproot_and_p2wpkh_inputs() {
    let k = test_key();
    let secp = Secp256k1::new();

    let tr_spk = ScriptBuf::new_p2tr(&secp, k.xonly, None);
    let tr_addr = Address::from_script(&tr_spk, NETWORK).unwrap().to_string();

    let cpk = CompressedPublicKey::from_slice(&k.public_key.to_bytes()).unwrap();
    let wpkh_spk = ScriptBuf::new_p2wpkh(&cpk.wpubkey_hash());
    let wpkh_addr = Address::from_script(&wpkh_spk, NETWORK)
        .unwrap()
        .to_string();

    // Input 0 = taproot, input 1 = P2WPKH.
    let mut utxos = UTXOList::new();
    utxos.add(UTXO::new(UTXO_AMOUNT, tr_spk));
    utxos.add(UTXO::new(UTXO_AMOUNT, wpkh_spk));

    let tx = unsigned_tx_n(2);
    let mut addresses = address_map(&tr_addr, &k.wif, "taproot", &k.public_key.to_string());
    addresses.extend(address_map(
        &wpkh_addr,
        &k.wif,
        "bech32",
        &k.public_key.to_string(),
    ));
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();

    let parsed = parse_signed(&signed);
    assert_eq!(parsed.input.len(), 2);
    // Taproot input: single Schnorr sig; P2WPKH input: <sig> <pubkey>.
    assert_eq!(parsed.input[0].witness.len(), 1);
    assert_eq!(parsed.input[1].witness.len(), 2);
    assert!(parsed.input[0].script_sig.is_empty());
    assert!(parsed.input[1].script_sig.is_empty());
}

#[test]
fn utxo_get_type_classifies_each_script() {
    let k = test_key();
    let secp = Secp256k1::new();

    // P2PKH
    let spk = ScriptBuf::new_p2pkh(&k.public_key.pubkey_hash());
    assert_eq!(UTXO::new(1, spk).get_type(), super::types::UTXOType::P2PKH);

    // P2WPKH
    let cpk = CompressedPublicKey::from_slice(&k.public_key.to_bytes()).unwrap();
    let spk = ScriptBuf::new_p2wpkh(&cpk.wpubkey_hash());
    assert_eq!(UTXO::new(1, spk).get_type(), super::types::UTXOType::P2WPKH);

    // P2TR key path
    let spk = ScriptBuf::new_p2tr(&secp, k.xonly, None);
    assert_eq!(
        UTXO::new(1, spk).get_type(),
        super::types::UTXOType::P2TRKPS
    );

    // P2SH (redeem script present)
    let redeem = single_key_script(&k.public_key);
    let mut u = UTXO::new(1, ScriptBuf::new_p2sh(&redeem.script_hash()));
    u.redeem_script = Some(redeem);
    assert_eq!(u.get_type(), super::types::UTXOType::P2SH);

    // P2WSH (witness script present)
    let ws = single_key_script(&k.public_key);
    let mut u = UTXO::new(1, ScriptBuf::new_p2wsh(&ws.wscript_hash()));
    u.witness_script = Some(ws);
    assert_eq!(u.get_type(), super::types::UTXOType::P2WSH);
}

#[test]
fn sign_transaction_errors_when_no_address_matches() {
    let k = test_key();
    let spk = ScriptBuf::new_p2pkh(&k.public_key.pubkey_hash());
    let mut utxos = UTXOList::new();
    utxos.add(UTXO::new(UTXO_AMOUNT, spk));

    // Empty wallet: the input's address is not present.
    let addresses: HashMap<String, AddressInfo> = HashMap::new();
    let tx = unsigned_tx();
    let result = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK);
    assert!(result.is_err(), "signing must fail without a matching key");
}

/// Independent Taproot key-path verification: re-derive the BIP341 key-spend
/// sighash from the signed transaction and verify the produced Schnorr signature
/// against the *tweaked output key* committed by the scriptPubKey (not just its
/// own key), and assert the signature is the standard 64-byte SIGHASH_DEFAULT
/// form.
#[test]
fn p2tr_key_path_signature_verifies_against_output_key() {
    let k = test_key();
    let secp = Secp256k1::new();
    let spk = ScriptBuf::new_p2tr(&secp, k.xonly, None);
    let addr = Address::from_script(&spk, NETWORK).unwrap().to_string();

    let mut utxos = UTXOList::new();
    utxos.add(UTXO::new(UTXO_AMOUNT, spk.clone()));
    let tx = unsigned_tx();
    let addresses = address_map(&addr, &k.wif, "taproot", &k.public_key.to_string());
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();
    let parsed = parse_signed(&signed);

    let witness: Vec<&[u8]> = parsed.input[0].witness.iter().collect();
    assert_eq!(witness.len(), 1);
    let sig_bytes = witness[0];
    assert_eq!(
        sig_bytes.len(),
        64,
        "taproot must use SIGHASH_DEFAULT (64-byte signature)"
    );

    let prevouts = vec![TxOut {
        value: Amount::from_sat(UTXO_AMOUNT),
        script_pubkey: spk,
    }];
    let mut cache = SighashCache::new(&parsed);
    let sighash = cache
        .taproot_key_spend_signature_hash(0, &Prevouts::All(&prevouts), TapSighashType::Default)
        .unwrap();
    let msg = Message::from_digest_slice(sighash.as_ref()).unwrap();
    let sig = bitcoin::secp256k1::schnorr::Signature::from_slice(sig_bytes).unwrap();

    // Output key = internal key tweaked with an empty merkle root (BIP86).
    let (output_key, _) = k.xonly.tap_tweak(&secp, None);
    assert!(secp
        .verify_schnorr(&sig, &msg, &output_key.to_x_only_public_key())
        .is_ok());
}

/// Independent Taproot script-path verification: re-derive the tapscript sighash
/// and verify the Schnorr signature against the leaf's internal key.
#[test]
fn p2tr_script_path_signature_verifies_against_internal_key() {
    let k = test_key();
    let secp = Secp256k1::new();
    let leaf_script = single_key_tapscript(&k.xonly);
    let spend_info = TaprootBuilder::new()
        .add_leaf(0, leaf_script.clone())
        .unwrap()
        .finalize(&secp, k.xonly)
        .unwrap();
    let spk = ScriptBuf::new_p2tr_tweaked(spend_info.output_key());

    let source_address = "p2tr-sps-verify".to_string();
    let mut utxo = UTXO::new(UTXO_AMOUNT, spk.clone());
    utxo.leaf_script = Some(leaf_script.clone());
    utxo.source_address = Some(source_address.clone());
    let mut utxos = UTXOList::new();
    utxos.add(utxo);

    let tx = unsigned_tx();
    let addresses = address_map(
        &source_address,
        &k.wif,
        "taproot",
        &k.public_key.to_string(),
    );
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();
    let parsed = parse_signed(&signed);

    let witness: Vec<&[u8]> = parsed.input[0].witness.iter().collect();
    let sig_bytes = witness[0];
    assert_eq!(sig_bytes.len(), 64, "SIGHASH_DEFAULT 64-byte signature");

    let leaf_hash = TapLeafHash::from_script(&leaf_script, LeafVersion::TapScript);
    let prevouts = vec![TxOut {
        value: Amount::from_sat(UTXO_AMOUNT),
        script_pubkey: spk,
    }];
    let mut cache = SighashCache::new(&parsed);
    let sighash = cache
        .taproot_script_spend_signature_hash(
            0,
            &Prevouts::All(&prevouts),
            leaf_hash,
            TapSighashType::Default,
        )
        .unwrap();
    let msg = Message::from_digest_slice(sighash.as_ref()).unwrap();
    let sig = bitcoin::secp256k1::schnorr::Signature::from_slice(sig_bytes).unwrap();
    assert!(secp.verify_schnorr(&sig, &msg, &k.xonly).is_ok());
}

/// Independent, *cryptographic* multi-input Taproot key-path verification. The
/// `signs_multi_input_p2tr_key_path` regression asserts only witness structure; a
/// wrong-prevout-set bug would still produce a self-consistent (signer verifies
/// its own sig) but on-chain-*invalid* signature that structure checks miss. This
/// re-derives each input's BIP341 sighash over the FULL prevout set and verifies
/// every signature against the tweaked output key.
#[test]
fn multi_input_p2tr_key_path_signatures_verify_against_all_prevouts() {
    let k = test_key();
    let secp = Secp256k1::new();
    let spk = ScriptBuf::new_p2tr(&secp, k.xonly, None);
    let addr = Address::from_script(&spk, NETWORK).unwrap().to_string();

    let mut utxos = UTXOList::new();
    utxos.add(UTXO::new(UTXO_AMOUNT, spk.clone()));
    utxos.add(UTXO::new(UTXO_AMOUNT, spk.clone()));

    let tx = unsigned_tx_n(2);
    let addresses = address_map(&addr, &k.wif, "taproot", &k.public_key.to_string());
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();
    let parsed = parse_signed(&signed);
    assert_eq!(parsed.input.len(), 2);

    let prevouts = vec![
        TxOut {
            value: Amount::from_sat(UTXO_AMOUNT),
            script_pubkey: spk.clone(),
        },
        TxOut {
            value: Amount::from_sat(UTXO_AMOUNT),
            script_pubkey: spk,
        },
    ];
    let (output_key, _) = k.xonly.tap_tweak(&secp, None);
    for i in 0..2 {
        let witness: Vec<&[u8]> = parsed.input[i].witness.iter().collect();
        assert_eq!(witness.len(), 1);
        let sig_bytes = witness[0];
        assert_eq!(sig_bytes.len(), 64, "SIGHASH_DEFAULT 64-byte signature");
        let mut cache = SighashCache::new(&parsed);
        let sighash = cache
            .taproot_key_spend_signature_hash(i, &Prevouts::All(&prevouts), TapSighashType::Default)
            .unwrap();
        let msg = Message::from_digest_slice(sighash.as_ref()).unwrap();
        let sig = bitcoin::secp256k1::schnorr::Signature::from_slice(sig_bytes).unwrap();
        assert!(
            secp.verify_schnorr(&sig, &msg, &output_key.to_x_only_public_key())
                .is_ok(),
            "input {i} signature must verify against the all-prevouts sighash"
        );
    }
}

/// Bitcoin consensus (BIP62) requires low-S ECDSA signatures. secp256k1's signer
/// always normalises S, so a produced signature must already equal its low-S
/// normalisation — assert it, so a future change that emits high-S (non-standard,
/// relay-rejected) signatures is caught.
#[test]
fn ecdsa_signature_is_low_s_canonical() {
    let k = test_key();
    let cpk = CompressedPublicKey::from_slice(&k.public_key.to_bytes()).unwrap();
    let spk = ScriptBuf::new_p2wpkh(&cpk.wpubkey_hash());
    let addr = Address::from_script(&spk, NETWORK).unwrap().to_string();

    let mut utxos = UTXOList::new();
    utxos.add(UTXO::new(UTXO_AMOUNT, spk));
    let tx = unsigned_tx();
    let addresses = address_map(&addr, &k.wif, "bech32", &k.public_key.to_string());
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();
    let parsed = parse_signed(&signed);

    let witness: Vec<&[u8]> = parsed.input[0].witness.iter().collect();
    let sig_bytes = witness[0];
    let sig =
        bitcoin::secp256k1::ecdsa::Signature::from_der(&sig_bytes[..sig_bytes.len() - 1]).unwrap();
    let mut normalized = sig;
    normalized.normalize_s();
    assert_eq!(sig, normalized, "ECDSA signature must be low-S (canonical)");
}

/// Uncompressed keys produce a 65-byte pubkey and a different `pubkey_hash`, so a
/// P2PKH spend with one must stay internally consistent (the pushed pubkey is the
/// uncompressed form and the signature verifies against it).
#[test]
fn signs_p2pkh_with_uncompressed_key() {
    let secp = Secp256k1::new();
    let sk = SecretKey::from_slice(&[0x11u8; 32]).unwrap();
    let pk = PrivateKey {
        compressed: false,
        network: NETWORK.into(),
        inner: sk,
    };
    let public_key = PublicKey::from_private_key(&secp, &pk);
    assert_eq!(
        public_key.to_bytes().len(),
        65,
        "uncompressed pubkey is 65 bytes"
    );

    let spk = ScriptBuf::new_p2pkh(&public_key.pubkey_hash());
    let addr = Address::from_script(&spk, NETWORK).unwrap().to_string();
    let mut utxos = UTXOList::new();
    utxos.add(UTXO::new(UTXO_AMOUNT, spk.clone()));
    let tx = unsigned_tx();
    let addresses = address_map(&addr, &pk.to_wif(), "p2pkh", &public_key.to_string());
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();
    let parsed = parse_signed(&signed);

    let pushes: Vec<Vec<u8>> = parsed.input[0]
        .script_sig
        .instructions()
        .filter_map(|i| match i {
            Ok(Instruction::PushBytes(b)) => Some(b.as_bytes().to_vec()),
            _ => None,
        })
        .collect();
    assert_eq!(pushes.len(), 2, "scriptSig = <sig> <pubkey>");
    assert_eq!(
        pushes[1].len(),
        65,
        "pushed pubkey is uncompressed (65 bytes)"
    );

    let cache = SighashCache::new(&parsed);
    let sighash = cache
        .legacy_signature_hash(0, &spk, EcdsaSighashType::All as u32)
        .unwrap();
    let msg = Message::from_digest_slice(sighash.as_ref()).unwrap();
    let sig =
        bitcoin::secp256k1::ecdsa::Signature::from_der(&pushes[0][..pushes[0].len() - 1]).unwrap();
    assert!(secp.verify_ecdsa(&msg, &sig, &public_key.inner).is_ok());
}

/// The P2SH scriptPubKey only commits to `hash160(redeem)`. A hostile server
/// could supply a P2SH-P2WPKH redeem program committing to a *different* key than
/// the wallet's; signing it would yield a validly-signed-but-unspendable input.
/// The signer must reject a redeem whose wrapped key is not the signing key.
#[test]
fn p2sh_p2wpkh_with_foreign_redeem_key_is_rejected() {
    let k = test_key();
    let secp = Secp256k1::new();
    // A foreign key that the redeem's P2WPKH program commits to.
    let foreign_sk = SecretKey::from_slice(&[0x22u8; 32]).unwrap();
    let foreign_pk = PublicKey::from_private_key(&secp, &PrivateKey::new(foreign_sk, NETWORK));
    let foreign_cpk = CompressedPublicKey::from_slice(&foreign_pk.to_bytes()).unwrap();

    let redeem = ScriptBuf::new_p2wpkh(&foreign_cpk.wpubkey_hash());
    let spk = ScriptBuf::new_p2sh(&redeem.script_hash());
    let addr = Address::from_script(&spk, NETWORK).unwrap().to_string();

    let mut utxo = UTXO::new(UTXO_AMOUNT, spk);
    utxo.redeem_script = Some(redeem);
    let mut utxos = UTXOList::new();
    utxos.add(utxo);

    let tx = unsigned_tx();
    // The wallet key `k` would sign, but the redeem commits to `foreign` -> refuse.
    let addresses = address_map(&addr, &k.wif, "p2sh", &k.public_key.to_string());
    let result = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK);
    assert!(
        result.is_err(),
        "a P2SH-P2WPKH redeem committing to a foreign key must be refused"
    );
}

/// Regression for the removed absurd-fee-rate guard (M-4): a large input swept
/// into a tiny OP_RETURN output has a fee rate far above rust-bitcoin's default
/// 25 000 sat/vB limit, yet signing must still succeed.
#[test]
fn signs_high_fee_rate_transaction() {
    let k = test_key();
    let cpk = CompressedPublicKey::from_slice(&k.public_key.to_bytes()).unwrap();
    let spk = ScriptBuf::new_p2wpkh(&cpk.wpubkey_hash());
    let addr = Address::from_script(&spk, NETWORK).unwrap().to_string();

    let big_input = 100_000_000u64; // 1 BTC
    let mut utxos = UTXOList::new();
    utxos.add(UTXO::new(big_input, spk));

    let tx = Transaction {
        version: transaction::Version::TWO,
        lock_time: absolute::LockTime::ZERO,
        input: vec![TxIn {
            previous_output: OutPoint::null(),
            script_sig: ScriptBuf::new(),
            sequence: Sequence::MAX,
            witness: Witness::new(),
        }],
        output: vec![TxOut {
            // ~1 BTC fee over a ~110 vB tx => ~900k sat/vB, far above 25k.
            value: Amount::from_sat(1_000),
            script_pubkey: ScriptBuf::new_op_return([]),
        }],
    };
    let addresses = address_map(&addr, &k.wif, "bech32", &k.public_key.to_string());
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();
    assert!(!signed.is_empty());
}

/// A multisig witness script is a valid script the single-key signer cannot
/// spend; it must be rejected with an "unsupported script" error rather than
/// silently emitting a malformed `[<sig>, <script>]` witness (M-5).
#[test]
fn rejects_multisig_witness_script() {
    let k = test_key();
    // 1-of-1 multisig: OP_1 <pubkey> OP_1 OP_CHECKMULTISIG.
    let multisig = Builder::new()
        .push_opcode(OP_PUSHNUM_1)
        .push_key(&k.public_key)
        .push_opcode(OP_PUSHNUM_1)
        .push_opcode(OP_CHECKMULTISIG)
        .into_script();
    let spk = ScriptBuf::new_p2wsh(&multisig.wscript_hash());
    let addr = Address::from_script(&spk, NETWORK).unwrap().to_string();

    let mut utxo = UTXO::new(UTXO_AMOUNT, spk);
    utxo.witness_script = Some(multisig);
    let mut utxos = UTXOList::new();
    utxos.add(utxo);

    let tx = unsigned_tx();
    let addresses = address_map(&addr, &k.wif, "p2wsh", &k.public_key.to_string());
    let err = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap_err();
    assert!(
        err.to_string().contains("Unsupported script"),
        "expected unsupported-script error, got: {err}"
    );
}

/// A taproot output that commits to a script tree (non-empty merkle root) cannot
/// be key-path-spent with the wallet's empty-tree tweak; routing it to the
/// key-path signer must error instead of producing an invalid signature (M-2/M-6).
#[test]
fn rejects_key_path_spend_of_output_with_script_tree() {
    let k = test_key();
    let secp = Secp256k1::new();
    let leaf = single_key_tapscript(&k.xonly);
    let spend_info = TaprootBuilder::new()
        .add_leaf(0, leaf)
        .unwrap()
        .finalize(&secp, k.xonly)
        .unwrap();
    // Output key commits to the script tree, so it differs from the empty-tree
    // key-path output for the same internal key.
    let spk = ScriptBuf::new_p2tr_tweaked(spend_info.output_key());
    let addr = Address::from_script(&spk, NETWORK).unwrap().to_string();

    // No leaf_script/source_address => classified as key-path.
    let mut utxos = UTXOList::new();
    utxos.add(UTXO::new(UTXO_AMOUNT, spk));
    let tx = unsigned_tx();
    let addresses = address_map(&addr, &k.wif, "taproot", &k.public_key.to_string());
    let err = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap_err();
    assert!(
        err.to_string().contains("Unsupported script"),
        "expected unsupported-script error, got: {err}"
    );
}
