//! Independent, client-side decoding of a **server-composed** Counterparty
//! transaction, used to verify that what the wallet is about to sign matches
//! what the user actually requested (closes review finding **H1**).
//!
//! The client sends the user's intent (asset / quantity / destination) to the
//! API server, which composes the raw transaction and returns it. Without an
//! independent check, a malicious, compromised, or man-in-the-middled server
//! could return a transaction that spends to a different destination or asset
//! than requested, and the user — who only sees an unreadable obfuscated
//! `OP_RETURN` — would sign it. This module re-derives the Counterparty payload
//! **from the composed transaction itself** and compares the three fields that
//! matter for a transfer.
//!
//! ## Scope and safe degradation
//!
//! Only the transfer message types where a tampered payload is most dangerous
//! are decoded here: classic `send` (0), `enhanced_send` (2) and `sweep` (4).
//! Every other transaction type, and any encoding this module does not handle
//! (bare-multisig / taproot-envelope data outputs), returns
//! [`Verification::Unverifiable`] so the caller can warn the user and require an
//! explicit confirmation rather than silently trusting the server. A decoder
//! that is wrong or out of date therefore raises a false *alarm* — it can never
//! wave through a bad transaction.
//!
//! ## Source of truth
//!
//! The byte formats mirror the Python composer/parser
//! (`counterpartycore/lib/messages/versions/{send1,enhancedsend}.py`,
//! `messages/sweep.py`) and the Rust indexer
//! (`counterparty-rs/src/indexer/bitcoin_client.rs`, for the ARC4 key and data
//! extraction). Keep them in sync when those formats change.

mod address;
mod arc4;
mod decode;
mod extract;

use bitcoin::consensus::deserialize;
use bitcoin::Network;
use bitcoin::Transaction;

/// The user's request, resolved to the values the composed transaction must
/// encode. A `None` field is simply not checked — e.g. the asset name could not
/// be resolved to an id, or the transaction type carries no single quantity.
#[derive(Debug, Default, Clone)]
pub struct Intent {
    /// Expected Counterparty asset id (numeric). `None` skips the asset check.
    pub asset_id: Option<u64>,
    /// Expected quantity, in satoshis/base units. `None` skips the check.
    pub quantity: Option<u64>,
    /// Expected destination address (already label-resolved). `None` skips it.
    pub destination: Option<String>,
}

/// Outcome of checking a composed transaction against the user's [`Intent`].
#[derive(Debug, PartialEq, Eq)]
pub enum Verification {
    /// Every field the client could independently check matched the request.
    Match,
    /// A decoded field disagreed with the request. The caller MUST refuse to
    /// sign/broadcast.
    Mismatch {
        field: &'static str,
        requested: String,
        composed: String,
    },
    /// The transaction type or encoding is outside this client's independent
    /// decoder. The caller MUST warn the user and require explicit confirmation
    /// (they are trusting the API server for this transaction).
    Unverifiable { reason: String },
}

/// Transaction-type command names this client can independently verify today.
/// A command outside this set degrades safely to [`Verification::Unverifiable`].
fn is_verifiable_type(tx_type: &str) -> bool {
    matches!(tx_type, "send" | "enhanced_send" | "sweep")
}

/// Resolve a Counterparty asset *name* to its numeric id **offline**, mirroring
/// `ledger.issuances.generate_asset_id`:
///
/// * `BTC` → 0, `XCP` → 1;
/// * numeric asset `A<n>` → `n`;
/// * a base-26 named asset (A–Z, 4–12 chars, not starting with `A`) → its
///   base-26 value.
///
/// Returns `None` for a sub-asset longname (contains `.`, needs the on-chain
/// registry) or any name that is not a valid standard asset — the caller then
/// skips the asset check rather than comparing against a wrong id. Because this
/// is algorithmic, the resulting check does not depend on (and cannot be spoofed
/// by) the API server.
pub fn asset_id_for_name(name: &str) -> Option<u64> {
    const BTC_ID: u64 = 0;
    const XCP_ID: u64 = 1;

    match name {
        "BTC" => return Some(BTC_ID),
        "XCP" => return Some(XCP_ID),
        _ => {}
    }

    // Sub-asset longnames (PARENT.child) are registry-assigned; can't resolve.
    if name.contains('.') {
        return None;
    }

    let bytes = name.as_bytes();

    // Numeric asset name: `A` followed by decimal digits.
    if bytes.first() == Some(&b'A') {
        return name[1..].parse::<u64>().ok();
    }

    // Base-26 named asset. Standard names are 4–12 characters of A–Z.
    if !(4..=12).contains(&name.len()) {
        return None;
    }
    let mut n: u64 = 0;
    for &c in bytes {
        let digit = match c {
            b'A'..=b'Z' => u64::from(c - b'A'),
            _ => return None,
        };
        n = n.checked_mul(26)?.checked_add(digit)?;
    }
    Some(n)
}

/// Test-only builder: a composed-transaction hex carrying an `enhanced_send` to
/// `destination`, obfuscated exactly as the server composer does (RC4 over
/// `CNTRPRTY` + `[0x02]` + CBOR, keyed by the first input's txid in display
/// order). Shared by this module's tests and the transaction-flow tests so the
/// obfuscation logic is written once. `destination` must be a witness address.
#[cfg(test)]
pub(crate) fn build_test_enhanced_send_tx_hex(
    txid_display: [u8; 32],
    asset_id: u64,
    quantity: u64,
    destination: &bitcoin::Address,
) -> String {
    use bitcoin::hashes::Hash as _;
    use ciborium::value::Value;

    let wp = destination
        .witness_program()
        .expect("test destination must be a witness address");
    let mut packed = vec![0x03, wp.version() as u8];
    packed.extend_from_slice(wp.program().as_bytes());

    let mut cbor = Vec::new();
    ciborium::into_writer(
        &Value::Array(vec![
            Value::Integer(asset_id.into()),
            Value::Integer(quantity.into()),
            Value::Bytes(packed),
            Value::Bytes(vec![]),
        ]),
        &mut cbor,
    )
    .unwrap();

    let mut payload = b"CNTRPRTY".to_vec();
    payload.push(0x02); // enhanced_send type id
    payload.extend_from_slice(&cbor);
    arc4::decrypt(&txid_display, &mut payload); // obfuscate (RC4 is symmetric)

    let mut internal = txid_display;
    internal.reverse();
    let push = bitcoin::script::PushBytesBuf::try_from(payload).unwrap();
    let tx = Transaction {
        version: bitcoin::transaction::Version::TWO,
        lock_time: bitcoin::absolute::LockTime::ZERO,
        input: vec![bitcoin::TxIn {
            previous_output: bitcoin::OutPoint {
                txid: bitcoin::Txid::from_byte_array(internal),
                vout: 0,
            },
            script_sig: bitcoin::ScriptBuf::new(),
            sequence: bitcoin::Sequence::MAX,
            witness: bitcoin::Witness::new(),
        }],
        output: vec![bitcoin::TxOut {
            value: bitcoin::Amount::ZERO,
            script_pubkey: bitcoin::ScriptBuf::new_op_return(&push),
        }],
    };
    hex::encode(bitcoin::consensus::serialize(&tx))
}

/// Verify a server-composed transaction against the user's request.
///
/// * `raw_tx_hex` — the composed (unsigned or signed; outputs are identical)
///   transaction hex returned by the API.
/// * `tx_type` — the `wallet transaction <type>` command name.
/// * `intent` — the user's resolved request.
/// * `network` — the Bitcoin network, for address rendering.
pub fn verify_composed_transaction(
    raw_tx_hex: &str,
    tx_type: &str,
    intent: &Intent,
    network: Network,
) -> Verification {
    if !is_verifiable_type(tx_type) {
        return Verification::Unverifiable {
            reason: format!(
                "transaction type '{tx_type}' is not independently verified by this client; \
                 you are trusting the API server for its contents"
            ),
        };
    }

    let tx = match hex::decode(raw_tx_hex)
        .ok()
        .and_then(|bytes| deserialize::<Transaction>(&bytes).ok())
    {
        Some(tx) => tx,
        None => {
            return Verification::Unverifiable {
                reason: "could not parse the composed transaction".to_string(),
            }
        }
    };

    let message = match extract::extract_message(&tx) {
        extract::Extracted::Message(m) => m,
        extract::Extracted::Unsupported(reason) => {
            return Verification::Unverifiable {
                reason: reason.to_string(),
            }
        }
    };

    // Dispatch on the *actual* Counterparty message type embedded in the
    // transaction, not the command name — this catches a server that composed a
    // different message type than the command implies.
    let Some((type_id, body)) = message.split_first() else {
        return Verification::Unverifiable {
            reason: "empty Counterparty message".to_string(),
        };
    };

    match type_id {
        0 => decode::verify_classic_send(body, &tx, intent, network),
        2 => decode::verify_enhanced_send(body, intent, network),
        4 => decode::verify_sweep(body, intent, network),
        other => Verification::Unverifiable {
            reason: format!("composed message type {other} is not independently verified"),
        },
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use bitcoin::{Address, WitnessProgram, WitnessVersion};

    const NET: Network = Network::Regtest;

    // ---- asset_id_for_name ----

    #[test]
    fn asset_id_resolves_specials_numeric_and_base26() {
        // Golden values from ledger.issuances.generate_asset_id.
        assert_eq!(asset_id_for_name("BTC"), Some(0));
        assert_eq!(asset_id_for_name("XCP"), Some(1));
        assert_eq!(asset_id_for_name("FOOBAR"), Some(66051301));
        assert_eq!(asset_id_for_name("PEPECASH"), Some(121892899915));
        assert_eq!(
            asset_id_for_name("A95428956661682177"),
            Some(95428956661682177)
        );
    }

    #[test]
    fn asset_id_skips_subassets_and_invalid_names() {
        assert_eq!(asset_id_for_name("PEPECASH.card"), None); // subasset -> registry
        assert_eq!(asset_id_for_name("Axyz"), None); // "A" prefix but not numeric
        assert_eq!(asset_id_for_name("bad!"), None); // non A-Z char
        assert_eq!(asset_id_for_name("AB"), None); // too short for base-26
    }

    // ---- full path: verify_composed_transaction ----

    fn wpkh_addr(seed: u8) -> Address {
        let wp = WitnessProgram::new(WitnessVersion::V0, &[seed; 20]).unwrap();
        Address::from_witness_program(wp, NET)
    }

    #[test]
    fn verifies_matching_enhanced_send_end_to_end() {
        let dest = wpkh_addr(0x11);
        let hex = build_test_enhanced_send_tx_hex([0x11; 32], 7, 2500, &dest);
        let intent = Intent {
            asset_id: Some(7),
            quantity: Some(2500),
            destination: Some(dest.to_string()),
        };
        assert_eq!(
            verify_composed_transaction(&hex, "enhanced_send", &intent, NET),
            Verification::Match
        );
    }

    #[test]
    fn rejects_hostile_server_swapping_the_destination() {
        // The server composed a send to `attacker` while the user asked for `dest`.
        let dest = wpkh_addr(0x11);
        let attacker = wpkh_addr(0x22);
        let hex = build_test_enhanced_send_tx_hex([0x11; 32], 7, 2500, &attacker);
        let intent = Intent {
            asset_id: Some(7),
            quantity: Some(2500),
            destination: Some(dest.to_string()),
        };
        assert!(matches!(
            verify_composed_transaction(&hex, "enhanced_send", &intent, NET),
            Verification::Mismatch {
                field: "destination",
                ..
            }
        ));
    }

    #[test]
    fn unknown_type_degrades_to_unverifiable() {
        let dest = wpkh_addr(0x11);
        let hex = build_test_enhanced_send_tx_hex([0x11; 32], 7, 2500, &dest);
        // Even though the payload is a valid enhanced_send, a command outside the
        // verifiable set must not be silently trusted.
        assert!(matches!(
            verify_composed_transaction(&hex, "issuance", &Intent::default(), NET),
            Verification::Unverifiable { .. }
        ));
    }

    #[test]
    fn unparseable_transaction_is_unverifiable() {
        assert!(matches!(
            verify_composed_transaction("not-hex", "send", &Intent::default(), NET),
            Verification::Unverifiable { .. }
        ));
    }
}
