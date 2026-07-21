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
//! For the two single-key ECDSA cases (P2PKH, P2WPKH) we additionally
//! *independently* re-derive the sighash from the signed transaction and verify
//! the produced signature against the input's script/pubkey with `secp256k1`.
//!
//! Coverage: P2PKH, P2WPKH, P2SH (legacy), P2SH-P2WPKH, P2WSH, P2TR key-path,
//! P2TR script-path. See the module-level notes in the workstream report for the
//! (none) deferred script types.

use std::collections::HashMap;

use bitcoin::blockdata::script::{Builder, Instruction};
use bitcoin::consensus::encode::{deserialize, serialize};
use bitcoin::opcodes::all::OP_CHECKSIG;
use bitcoin::secp256k1::{Message, Secp256k1, SecretKey};
use bitcoin::sighash::{EcdsaSighashType, SighashCache};
use bitcoin::taproot::TaprootBuilder;
use bitcoin::{
    absolute, transaction, Address, Amount, CompressedPublicKey, Network, OutPoint, PrivateKey,
    PublicKey, ScriptBuf, Sequence, Transaction, TxIn, TxOut, Witness, XOnlyPublicKey,
};
use secrecy::Secret;

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
            private_key: Secret::new(wif.to_string()),
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
    let mut cache = SighashCache::new(&parsed);
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
    utxo.redeem_script = Some(redeem);
    let mut utxos = UTXOList::new();
    utxos.add(utxo);

    let tx = unsigned_tx();
    let addresses = address_map(&addr, &k.wif, "p2sh", &k.public_key.to_string());
    let signed = sign_transaction(&addresses, &raw_hex(&tx), &utxos, NETWORK).unwrap();

    let parsed = parse_signed(&signed);
    assert!(
        !parsed.input[0].script_sig.is_empty(),
        "P2SH-legacy must produce a scriptSig"
    );
    assert!(parsed.input[0].witness.is_empty());
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
}

#[test]
fn signs_p2wsh_input() {
    let k = test_key();
    let witness_script = single_key_script(&k.public_key);
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
    assert!(parsed.input[0].script_sig.is_empty());
    let witness: Vec<&[u8]> = parsed.input[0].witness.iter().collect();
    // signer pushes <sig> <pubkey> <witness_script>.
    assert_eq!(witness.len(), 3, "witness = <sig> <pubkey> <witnessScript>");
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
    // Key-path spend: a single Schnorr signature (64 or 65 bytes).
    assert_eq!(witness.len(), 1, "key-path witness = <schnorr sig>");
    assert!(matches!(witness[0].len(), 64 | 65));
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
