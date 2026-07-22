//! Per-type decoders that compare a composed Counterparty message against the
//! user's [`Intent`].
//!
//! Coverage is deliberately narrow (see the module docs): classic `send` (0),
//! `enhanced_send` (2) and `sweep` (4). For the two types that carry a packed
//! destination in the payload, only the modern CBOR encoding (active under the
//! `taproot_support` protocol change, which every live network is now past) is
//! decoded; the pre-activation legacy struct encoding — which also uses a
//! different address packing — returns [`Verification::Unverifiable`] so the
//! caller degrades safely instead of risking a wrong decode.

use std::str::FromStr;

use bitcoin::{Address, Network, Transaction};
use ciborium::value::Value;

use super::{address, Intent, Verification};

/// Return a `Mismatch` if `expected` is present and differs from `composed`.
fn check<T>(field: &'static str, expected: &Option<T>, composed: T) -> Option<Verification>
where
    T: PartialEq + std::fmt::Display,
{
    match expected {
        Some(e) if *e != composed => Some(Verification::Mismatch {
            field,
            requested: e.to_string(),
            composed: composed.to_string(),
        }),
        _ => None,
    }
}

/// Canonicalise an address string for `network` (e.g. bech32 → lowercase), so a
/// comparison is not defeated by cosmetic differences. Falls back to the raw
/// string when it cannot be parsed for this network.
fn normalize_address(addr: &str, network: Network) -> String {
    Address::from_str(addr)
        .ok()
        .and_then(|a| a.require_network(network).ok())
        .map(|a| a.to_string())
        .unwrap_or_else(|| addr.to_string())
}

/// Decode `body` as a single CBOR array consuming all bytes.
fn cbor_array(body: &[u8]) -> Option<Vec<Value>> {
    let mut cursor = std::io::Cursor::new(body);
    let value: Value = ciborium::from_reader(&mut cursor).ok()?;
    if cursor.position() as usize != body.len() {
        return None; // trailing bytes: not a clean single CBOR item
    }
    match value {
        Value::Array(items) => Some(items),
        _ => None,
    }
}

fn cbor_u64(value: &Value) -> Option<u64> {
    match value {
        Value::Integer(i) => u64::try_from(i128::from(*i)).ok(),
        _ => None,
    }
}

fn cbor_bytes(value: &Value) -> Option<&[u8]> {
    match value {
        Value::Bytes(b) => Some(b),
        _ => None,
    }
}

/// Combine field checks: the first mismatch wins, otherwise `Match`.
fn combine(checks: impl IntoIterator<Item = Option<Verification>>) -> Verification {
    checks
        .into_iter()
        .flatten()
        .next()
        .unwrap_or(Verification::Match)
}

/// Classic `send` (type 0): payload is `>QQ` (asset id, quantity); the
/// destination is a regular transaction output, not part of the payload.
pub fn verify_classic_send(
    body: &[u8],
    tx: &Transaction,
    intent: &Intent,
    network: Network,
) -> Verification {
    if body.len() != 16 {
        return Verification::Unverifiable {
            reason: format!("unexpected classic-send payload length ({})", body.len()),
        };
    }
    let asset_id = u64::from_be_bytes(body[0..8].try_into().unwrap());
    let quantity = u64::from_be_bytes(body[8..16].try_into().unwrap());

    let mut checks = vec![
        check("asset", &intent.asset_id, asset_id),
        check("quantity", &intent.quantity, quantity),
    ];

    // The destination must be paid by one of the transaction's outputs.
    if let Some(dest) = &intent.destination {
        let want = normalize_address(dest, network);
        let paid = tx.output.iter().any(|o| {
            Address::from_script(&o.script_pubkey, network)
                .map(|a| a.to_string())
                .map(|a| a == want)
                .unwrap_or(false)
        });
        if !paid {
            checks.push(Some(Verification::Mismatch {
                field: "destination",
                requested: want,
                composed: "not paid by any transaction output".to_string(),
            }));
        }
    }

    combine(checks)
}

/// `enhanced_send` (type 2), modern CBOR form:
/// `[asset_id, quantity, packed_destination, memo]`.
pub fn verify_enhanced_send(body: &[u8], intent: &Intent, network: Network) -> Verification {
    let Some(items) = cbor_array(body) else {
        return Verification::Unverifiable {
            reason: "enhanced_send payload is not the modern CBOR encoding (legacy encoding is not independently verified)".to_string(),
        };
    };
    if items.len() != 4 {
        return Verification::Unverifiable {
            reason: format!("unexpected enhanced_send CBOR arity ({})", items.len()),
        };
    }
    let (Some(asset_id), Some(quantity), Some(addr_bytes)) = (
        cbor_u64(&items[0]),
        cbor_u64(&items[1]),
        cbor_bytes(&items[2]),
    ) else {
        return Verification::Unverifiable {
            reason: "enhanced_send CBOR fields have unexpected types".to_string(),
        };
    };
    let Some(destination) = address::unpack(addr_bytes, network) else {
        return Verification::Unverifiable {
            reason: "could not decode enhanced_send destination address".to_string(),
        };
    };

    combine([
        check("asset", &intent.asset_id, asset_id),
        check("quantity", &intent.quantity, quantity),
        check(
            "destination",
            &intent
                .destination
                .as_ref()
                .map(|d| normalize_address(d, network)),
            destination,
        ),
    ])
}

/// `sweep` (type 4), modern CBOR form: `[packed_destination, flags, memo]`.
/// A sweep moves *all* assets, so only the destination is checked.
pub fn verify_sweep(body: &[u8], intent: &Intent, network: Network) -> Verification {
    let Some(items) = cbor_array(body) else {
        return Verification::Unverifiable {
            reason: "sweep payload is not the modern CBOR encoding (legacy encoding is not independently verified)".to_string(),
        };
    };
    if items.len() != 3 {
        return Verification::Unverifiable {
            reason: format!("unexpected sweep CBOR arity ({})", items.len()),
        };
    }
    let Some(addr_bytes) = cbor_bytes(&items[0]) else {
        return Verification::Unverifiable {
            reason: "sweep CBOR destination has an unexpected type".to_string(),
        };
    };
    let Some(destination) = address::unpack(addr_bytes, network) else {
        return Verification::Unverifiable {
            reason: "could not decode sweep destination address".to_string(),
        };
    };

    combine([check(
        "destination",
        &intent
            .destination
            .as_ref()
            .map(|d| normalize_address(d, network)),
        destination,
    )])
}

#[cfg(test)]
mod tests {
    use super::*;
    use bitcoin::absolute::LockTime;
    use bitcoin::hashes::Hash as _;
    use bitcoin::transaction::Version;
    use bitcoin::{Amount, OutPoint, ScriptBuf, Sequence, TxIn, TxOut, Txid, Witness};

    const NET: Network = Network::Regtest;

    // Build a valid regtest P2WPKH address from a 20-byte program seed, so test
    // vectors never depend on a hand-typed bech32 checksum.
    fn wpkh_addr(seed: u8) -> Address {
        let program = [seed; 20];
        let wp = bitcoin::WitnessProgram::new(bitcoin::WitnessVersion::V0, &program).unwrap();
        Address::from_witness_program(wp, NET)
    }

    // The modern packed form (0x01/0x02/0x03 prefix) of an address, for building
    // CBOR payloads (mirrors counterparty-rs utils::pack).
    fn packed(addr: &Address) -> Vec<u8> {
        match (
            addr.pubkey_hash(),
            addr.script_hash(),
            addr.witness_program(),
        ) {
            (Some(h), _, _) => {
                let mut v = vec![0x01];
                v.extend_from_slice(h.as_byte_array());
                v
            }
            (_, Some(h), _) => {
                let mut v = vec![0x02];
                v.extend_from_slice(h.as_byte_array());
                v
            }
            (_, _, Some(wp)) => {
                let mut v = vec![0x03, wp.version() as u8];
                v.extend_from_slice(wp.program().as_bytes());
                v
            }
            _ => panic!("unpackable"),
        }
    }

    fn cbor(items: Vec<Value>) -> Vec<u8> {
        let mut out = Vec::new();
        ciborium::into_writer(&Value::Array(items), &mut out).unwrap();
        out
    }

    fn output_to(addr: &Address) -> TxOut {
        TxOut {
            value: Amount::from_sat(546),
            script_pubkey: addr.script_pubkey(),
        }
    }

    fn tx_with_outputs(outputs: Vec<TxOut>) -> Transaction {
        Transaction {
            version: Version::TWO,
            lock_time: LockTime::ZERO,
            input: vec![TxIn {
                previous_output: OutPoint {
                    txid: Txid::all_zeros(),
                    vout: 0,
                },
                script_sig: ScriptBuf::new(),
                sequence: Sequence::MAX,
                witness: Witness::new(),
            }],
            output: outputs,
        }
    }

    // ---- classic send (type 0) ----

    #[test]
    fn classic_send_matches_intent() {
        let dest = wpkh_addr(0x11);
        let mut body = Vec::new();
        body.extend_from_slice(&42u64.to_be_bytes()); // asset id
        body.extend_from_slice(&1000u64.to_be_bytes()); // quantity
        let tx = tx_with_outputs(vec![output_to(&dest)]);
        let intent = Intent {
            asset_id: Some(42),
            quantity: Some(1000),
            destination: Some(dest.to_string()),
        };
        assert_eq!(
            verify_classic_send(&body, &tx, &intent, NET),
            Verification::Match
        );
    }

    #[test]
    fn classic_send_detects_wrong_quantity() {
        let dest = wpkh_addr(0x11);
        let mut body = Vec::new();
        body.extend_from_slice(&42u64.to_be_bytes());
        body.extend_from_slice(&999u64.to_be_bytes()); // composed 999
        let tx = tx_with_outputs(vec![output_to(&dest)]);
        let intent = Intent {
            asset_id: Some(42),
            quantity: Some(1000), // requested 1000
            destination: Some(dest.to_string()),
        };
        assert!(matches!(
            verify_classic_send(&body, &tx, &intent, NET),
            Verification::Mismatch {
                field: "quantity",
                ..
            }
        ));
    }

    #[test]
    fn classic_send_detects_missing_destination_output() {
        let requested = wpkh_addr(0x11);
        let other = wpkh_addr(0x22);
        let mut body = Vec::new();
        body.extend_from_slice(&42u64.to_be_bytes());
        body.extend_from_slice(&1000u64.to_be_bytes());
        // Transaction pays a different address than requested.
        let tx = tx_with_outputs(vec![output_to(&other)]);
        let intent = Intent {
            asset_id: Some(42),
            quantity: Some(1000),
            destination: Some(requested.to_string()),
        };
        assert!(matches!(
            verify_classic_send(&body, &tx, &intent, NET),
            Verification::Mismatch {
                field: "destination",
                ..
            }
        ));
    }

    // ---- enhanced_send (type 2, CBOR) ----

    #[test]
    fn enhanced_send_matches_intent() {
        let dest = wpkh_addr(0x11);
        let body = cbor(vec![
            Value::Integer(7u64.into()),
            Value::Integer(2500u64.into()),
            Value::Bytes(packed(&dest)),
            Value::Bytes(vec![]),
        ]);
        let intent = Intent {
            asset_id: Some(7),
            quantity: Some(2500),
            destination: Some(dest.to_string()),
        };
        assert_eq!(
            verify_enhanced_send(&body, &intent, NET),
            Verification::Match
        );
    }

    #[test]
    fn enhanced_send_detects_tampered_destination() {
        // Payload sends to `other` while the user requested `requested`.
        let requested = wpkh_addr(0x11);
        let other = wpkh_addr(0x22);
        let body = cbor(vec![
            Value::Integer(7u64.into()),
            Value::Integer(2500u64.into()),
            Value::Bytes(packed(&other)),
            Value::Bytes(vec![]),
        ]);
        let intent = Intent {
            asset_id: Some(7),
            quantity: Some(2500),
            destination: Some(requested.to_string()),
        };
        assert!(matches!(
            verify_enhanced_send(&body, &intent, NET),
            Verification::Mismatch {
                field: "destination",
                ..
            }
        ));
    }

    #[test]
    fn enhanced_send_detects_tampered_asset() {
        let dest = wpkh_addr(0x11);
        let body = cbor(vec![
            Value::Integer(999u64.into()), // composed asset 999
            Value::Integer(2500u64.into()),
            Value::Bytes(packed(&dest)),
            Value::Bytes(vec![]),
        ]);
        let intent = Intent {
            asset_id: Some(7), // requested asset 7
            quantity: Some(2500),
            destination: Some(dest.to_string()),
        };
        assert!(matches!(
            verify_enhanced_send(&body, &intent, NET),
            Verification::Mismatch { field: "asset", .. }
        ));
    }

    #[test]
    fn enhanced_send_legacy_encoding_is_unverifiable() {
        // A legacy `>QQ21s` struct body is not CBOR -> safe degradation.
        let mut body = Vec::new();
        body.extend_from_slice(&7u64.to_be_bytes());
        body.extend_from_slice(&2500u64.to_be_bytes());
        body.extend_from_slice(&[0u8; 21]);
        let intent = Intent::default();
        assert!(matches!(
            verify_enhanced_send(&body, &intent, NET),
            Verification::Unverifiable { .. }
        ));
    }

    // ---- sweep (type 4, CBOR) ----

    #[test]
    fn sweep_matches_destination() {
        let dest = wpkh_addr(0x11);
        let body = cbor(vec![
            Value::Bytes(packed(&dest)),
            Value::Integer(7u64.into()), // flags
            Value::Bytes(vec![]),
        ]);
        let intent = Intent {
            destination: Some(dest.to_string()),
            ..Default::default()
        };
        assert_eq!(verify_sweep(&body, &intent, NET), Verification::Match);
    }

    #[test]
    fn sweep_detects_tampered_destination() {
        let requested = wpkh_addr(0x11);
        let other = wpkh_addr(0x22);
        let body = cbor(vec![
            Value::Bytes(packed(&other)),
            Value::Integer(7u64.into()),
            Value::Bytes(vec![]),
        ]);
        let intent = Intent {
            destination: Some(requested.to_string()),
            ..Default::default()
        };
        assert!(matches!(
            verify_sweep(&body, &intent, NET),
            Verification::Mismatch {
                field: "destination",
                ..
            }
        ));
    }
}
