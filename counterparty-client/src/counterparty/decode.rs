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

/// The address paid by an output, canonicalised for `network`, if it resolves.
fn output_address(out: &bitcoin::TxOut, network: Network) -> Option<String> {
    Address::from_script(&out.script_pubkey, network)
        .ok()
        .map(|a| a.to_string())
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

    // Consensus (`gettxinfo` `get_tx_info_new`) credits the asset to **every**
    // non-data output that appears *before* the OP_RETURN, joined with "-", and
    // treats outputs after it as change. So the destination must be the single
    // output preceding the data output. Two ways a positional lookback at only
    // `idx - 1` would be unsafe: (a) checking that *some* output pays the address
    // lets a server pay it from a change-position output while diverting the real
    // destination; (b) if the server places two+ outputs before the OP_RETURN,
    // consensus credits their *join* (`"source-dest"`) — a pseudo-address that is
    // never a valid recipient, so the asset is permanently lost — yet the last
    // one could still be the destination. Require exactly one, and that it pays
    // the destination.
    if let Some(dest) = &intent.destination {
        let want = normalize_address(dest, network);
        let mismatch = |composed: &str| {
            Some(Verification::Mismatch {
                field: "destination",
                requested: want.clone(),
                composed: composed.to_string(),
            })
        };
        match tx
            .output
            .iter()
            .position(|o| o.script_pubkey.is_op_return())
        {
            None => checks.push(mismatch("no OP_RETURN data output found")),
            Some(idx) => {
                let pre: Vec<&bitcoin::TxOut> = tx.output[..idx]
                    .iter()
                    .filter(|o| !o.script_pubkey.is_op_return())
                    .collect();
                match pre.as_slice() {
                    [only] if output_address(only, network).as_deref() == Some(want.as_str()) => {}
                    [_only] => checks.push(mismatch(
                        "the output before the OP_RETURN does not pay this address",
                    )),
                    [] => checks.push(mismatch("no destination output precedes the OP_RETURN")),
                    _ => checks.push(mismatch(
                        "more than one output precedes the OP_RETURN; consensus would credit \
                         their join, not the requested destination",
                    )),
                }
            }
        }
    }

    combine(checks)
}

/// How much BTC a composed transaction may pay the *requested destination*.
/// Change back to the source is always allowed; any output to a third-party
/// address (or to a script with no address) is always refused.
#[derive(Debug, Clone, Copy)]
pub enum DestinationBtc {
    /// The destination must receive **no** BTC. `enhanced_send` (2) and `sweep`
    /// (4) carry the destination in their payload and move value on the ledger,
    /// not on-chain, so any destination-paying output is a server siphoning
    /// funds to a server-chosen address and is refused.
    Forbidden,
    /// The destination may receive **at most** `max` sats in total — the dust
    /// *marker* output of a classic `send` (type 0). Without this bound a hostile
    /// server could inflate that marker (or add a second destination output) and
    /// route the user's whole BTC balance to the destination while the asset
    /// payload still matched; the miner-fee cap misses it because the value
    /// leaves as an output, not as fee.
    AtMost(u64),
    /// The destination must receive **exactly** `expected` sats in total — a
    /// plain BTC send, where the delivered amount *is* the user's requested
    /// `--quantity`. Requiring the exact total (not merely "some output pays it")
    /// stops a server adding a second destination output to over-pay.
    Exactly(u64),
}

/// Upper bound on the BTC a classic `send` (type 0) may pay its destination. The
/// destination output is only a dust *marker* — the asset itself moves on the
/// ledger via the OP_RETURN — so anything materially above dust signals a siphon.
/// Set well above any standard dust threshold so a legitimate marker is never
/// rejected, while still bounding a hostile server's leak to a negligible amount.
pub const MAX_CLASSIC_SEND_DEST_SAT: u64 = 10_000;

/// Confirm that every BTC-bearing output pays either the source (change) or the
/// requested destination — nothing to a third party — and that the destination
/// receives only what `dest_policy` permits. A matching Counterparty payload
/// (asset/quantity/destination) does **not** by itself stop a hostile server
/// from routing the transaction's BTC to an attacker output *or* over-paying the
/// destination with the user's own funds; this is the check that does.
///
/// When the source is unknown the change/siphon distinction cannot be made, so
/// this **fails closed** with [`Verification::Unverifiable`] rather than passing
/// — the caller then refuses a verifiable-type command (or requires explicit
/// confirmation) instead of silently trusting the BTC routing. The wallet path
/// always supplies the source, so this only guards a caller that forgot to.
///
/// Change back to the source is always allowed, so a self-transfer
/// (source == destination) still verifies — every output then pays the source,
/// so `to_destination` is 0 and the amount policy is vacuous.
pub fn verify_btc_recipients(
    tx: &Transaction,
    intent: &Intent,
    network: Network,
    dest_policy: DestinationBtc,
) -> Verification {
    let Some(source) = intent.source.as_ref() else {
        return Verification::Unverifiable {
            reason: "cannot verify BTC routing: the funding source address is unknown".to_string(),
        };
    };
    let source = normalize_address(source, network);
    let destination = intent
        .destination
        .as_ref()
        .map(|d| normalize_address(d, network));
    let dest_is_source = destination.as_deref() == Some(source.as_str());

    let allow_destination = !matches!(dest_policy, DestinationBtc::Forbidden);
    let requested = if allow_destination {
        format!("BTC only to source ({source}) or the destination")
    } else {
        format!("BTC only to source ({source}) as change")
    };

    // Total BTC paid to the destination. Only counts outputs paying the
    // destination and *not* the source (source is matched first below), so a
    // self-transfer contributes nothing here.
    let mut to_destination: u64 = 0;
    for out in &tx.output {
        // Data outputs carry no spendable value to a recipient.
        if out.script_pubkey.is_op_return() {
            continue;
        }
        match output_address(out, network) {
            // Change back to the source is always allowed (checked first, so a
            // self-transfer where source == destination is not counted below).
            Some(addr) if addr == source => {}
            Some(addr) if allow_destination && Some(&addr) == destination.as_ref() => {
                to_destination = to_destination.saturating_add(out.value.to_sat());
            }
            Some(addr) => {
                return Verification::Mismatch {
                    field: "btc_output",
                    requested,
                    composed: format!("{} sats to {addr}", out.value.to_sat()),
                };
            }
            None => {
                return Verification::Mismatch {
                    field: "btc_output",
                    requested,
                    composed: "an output pays a script that resolves to no address".to_string(),
                };
            }
        }
    }

    // Enforce how much the destination was allowed to receive. A self-transfer
    // (destination == source) pays everything as source change, so the amount
    // policy is skipped (it would otherwise wrongly reject `Exactly`).
    if !dest_is_source {
        match dest_policy {
            DestinationBtc::AtMost(max) if to_destination > max => {
                return Verification::Mismatch {
                    field: "btc_output",
                    requested: format!("at most {max} sats to the destination (a dust marker)"),
                    composed: format!("{to_destination} sats to the destination"),
                };
            }
            DestinationBtc::Exactly(expected) if to_destination != expected => {
                return Verification::Mismatch {
                    field: "btc_output",
                    requested: format!("exactly {expected} sats to the destination"),
                    composed: format!("{to_destination} sats to the destination"),
                };
            }
            _ => {}
        }
    }

    Verification::Match
}

/// A plain BTC transfer (`wallet transaction send --asset BTC`) carries no
/// Counterparty payload at all: `compose_send`'s `compose_send_btc` path
/// produces either an ordinary Bitcoin transaction with no data output, or —
/// when the destination is a live dispenser — one with a dispense-trigger
/// data output that itself carries no asset/quantity/destination fields.
/// Verify the requested destination/quantity directly against the
/// transaction's outputs instead of expecting a `send`/`enhanced_send`/`sweep`
/// message, which would otherwise either refuse every plain BTC send outright
/// (no data output to decode) or reject a legitimate dispense trigger as a
/// message-type mismatch (its type is neither 0, 2 nor 4).
pub fn verify_btc_send(tx: &Transaction, intent: &Intent, network: Network) -> Verification {
    // A plain BTC send legitimately pays the destination, and the amount it
    // delivers *is* the user's requested `--quantity` — so require the
    // destination to receive exactly that, in total. Requiring both fields to be
    // present makes the amount check unskippable: without a known quantity the
    // amount cannot be verified, so degrade to Unverifiable rather than waving a
    // possibly-over-paying transaction through.
    match (intent.destination.as_ref(), intent.quantity) {
        (Some(_dest), Some(qty)) => {
            verify_btc_recipients(tx, intent, network, DestinationBtc::Exactly(qty))
        }
        _ => Verification::Unverifiable {
            reason: "cannot verify a plain BTC send without both a destination and an amount"
                .to_string(),
        },
    }
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
///
/// A sweep moves *everything* the source owns to the destination, so the
/// destination is the primary check. The `flags` OR-mask
/// (`FLAG_BALANCES=1`, `FLAG_OWNERSHIP=2`, `FLAG_BINARY_MEMO=4`) is also verified:
/// a server that flips `FLAG_OWNERSHIP` on could hand away irreversible asset
/// *issuer rights* the user never asked to transfer.
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
    // The flags must decode to an integer; a non-integer here means an encoding
    // this client does not model, so degrade to Unverifiable rather than skip the
    // check silently.
    let Some(flags) = cbor_u64(&items[1]) else {
        return Verification::Unverifiable {
            reason: "sweep CBOR flags have an unexpected type".to_string(),
        };
    };

    // A sweep can transfer asset *ownership*, so its flags must be verified — a
    // server that turns `FLAG_OWNERSHIP` on could hand away irreversible issuer
    // rights the user never asked to transfer. If the requested flags could not be
    // resolved (the `sweep` command supplied none, or they failed to parse), fail
    // *closed*: return Unverifiable so the caller refuses a verifiable-type
    // transaction it cannot fully check, rather than silently skipping the flags
    // comparison via [`check`]'s `None`-means-unchecked behaviour.
    if intent.flags.is_none() {
        return Verification::Unverifiable {
            reason: "sweep flags were not provided, so FLAG_OWNERSHIP could not be verified; \
                     re-run the sweep with an explicit --flags"
                .to_string(),
        };
    }

    combine([
        check(
            "destination",
            &intent
                .destination
                .as_ref()
                .map(|d| normalize_address(d, network)),
            destination,
        ),
        check("sweep flags", &intent.flags, flags),
    ])
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

    // A minimal OP_RETURN data output, so classic-send tests exercise the
    // positional "destination is the output before the OP_RETURN" check.
    fn op_return_output() -> TxOut {
        let data = bitcoin::script::PushBytesBuf::try_from(vec![0xccu8]).unwrap();
        TxOut {
            value: Amount::ZERO,
            script_pubkey: ScriptBuf::new_op_return(&data),
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
        let tx = tx_with_outputs(vec![output_to(&dest), op_return_output()]);
        let intent = Intent {
            asset_id: Some(42),
            quantity: Some(1000),
            destination: Some(dest.to_string()),
            ..Default::default()
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
        let tx = tx_with_outputs(vec![output_to(&dest), op_return_output()]);
        let intent = Intent {
            asset_id: Some(42),
            quantity: Some(1000), // requested 1000
            destination: Some(dest.to_string()),
            ..Default::default()
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
        // The output before the OP_RETURN pays a different address than requested.
        let tx = tx_with_outputs(vec![output_to(&other), op_return_output()]);
        let intent = Intent {
            asset_id: Some(42),
            quantity: Some(1000),
            destination: Some(requested.to_string()),
            ..Default::default()
        };
        assert!(matches!(
            verify_classic_send(&body, &tx, &intent, NET),
            Verification::Mismatch {
                field: "destination",
                ..
            }
        ));
    }

    #[test]
    fn classic_send_rejects_two_outputs_before_the_op_return() {
        // A hostile server places a second non-data output before the OP_RETURN
        // (here `[decoy, destination, OP_RETURN]`). Consensus would credit the
        // asset to the *join* of both ("decoy-destination"), a pseudo-address that
        // is never a valid recipient — the asset is permanently lost — even though
        // the output immediately before the OP_RETURN does pay the destination.
        // A positional `idx - 1` lookback would wave this through; requiring
        // exactly one preceding output catches it.
        let decoy = wpkh_addr(0x22);
        let dest = wpkh_addr(0x11);
        let mut body = Vec::new();
        body.extend_from_slice(&42u64.to_be_bytes());
        body.extend_from_slice(&1000u64.to_be_bytes());
        let tx = tx_with_outputs(vec![
            output_to(&decoy),
            output_to(&dest),
            op_return_output(),
        ]);
        let intent = Intent {
            asset_id: Some(42),
            quantity: Some(1000),
            destination: Some(dest.to_string()),
            ..Default::default()
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
            ..Default::default()
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
            ..Default::default()
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
            ..Default::default()
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
            flags: Some(7),
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
            flags: Some(7),
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

    #[test]
    fn sweep_without_requested_flags_is_unverifiable() {
        // Fail closed: a sweep can transfer asset ownership, so if the requested
        // flags could not be resolved (none supplied), the flags check must not be
        // silently skipped — it degrades to Unverifiable, which the caller refuses
        // for a verifiable-type command.
        let dest = wpkh_addr(0x11);
        let body = cbor(vec![
            Value::Bytes(packed(&dest)),
            Value::Integer(3u64.into()), // FLAG_BALANCES | FLAG_OWNERSHIP
            Value::Bytes(vec![]),
        ]);
        let intent = Intent {
            destination: Some(dest.to_string()),
            flags: None, // the user did not pass --flags
            ..Default::default()
        };
        assert!(matches!(
            verify_sweep(&body, &intent, NET),
            Verification::Unverifiable { .. }
        ));
    }

    // ---- verify_btc_recipients (H2) ----

    fn value_output(addr: &Address, sats: u64) -> TxOut {
        TxOut {
            value: Amount::from_sat(sats),
            script_pubkey: addr.script_pubkey(),
        }
    }

    #[test]
    fn btc_recipients_allows_change_to_source_and_dust_to_destination() {
        let source = wpkh_addr(0x33);
        let dest = wpkh_addr(0x11);
        let tx = tx_with_outputs(vec![
            value_output(&dest, 546),
            op_return_output(),
            value_output(&source, 9000),
        ]);
        let intent = Intent {
            destination: Some(dest.to_string()),
            source: Some(source.to_string()),
            ..Default::default()
        };
        assert_eq!(
            verify_btc_recipients(
                &tx,
                &intent,
                NET,
                DestinationBtc::AtMost(MAX_CLASSIC_SEND_DEST_SAT)
            ),
            Verification::Match
        );
    }

    #[test]
    fn btc_recipients_rejects_a_third_party_output() {
        let source = wpkh_addr(0x33);
        let attacker = wpkh_addr(0x44);
        let tx = tx_with_outputs(vec![op_return_output(), value_output(&attacker, 9000)]);
        let intent = Intent {
            source: Some(source.to_string()),
            ..Default::default()
        };
        assert!(matches!(
            verify_btc_recipients(
                &tx,
                &intent,
                NET,
                DestinationBtc::AtMost(MAX_CLASSIC_SEND_DEST_SAT)
            ),
            Verification::Mismatch {
                field: "btc_output",
                ..
            }
        ));
    }

    #[test]
    fn btc_recipients_rejects_an_inflated_classic_send_destination_output() {
        // Classic send (type 0): a hostile server keeps the asset payload correct
        // but inflates the destination "dust" marker to route the user's BTC to
        // the destination. The AtMost dust bound must refuse it (M2).
        let source = wpkh_addr(0x33);
        let dest = wpkh_addr(0x11);
        let tx = tx_with_outputs(vec![
            value_output(&dest, 5_000_000), // 0.05 BTC dressed up as a "marker"
            op_return_output(),
            value_output(&source, 9000),
        ]);
        let intent = Intent {
            destination: Some(dest.to_string()),
            source: Some(source.to_string()),
            ..Default::default()
        };
        assert!(matches!(
            verify_btc_recipients(
                &tx,
                &intent,
                NET,
                DestinationBtc::AtMost(MAX_CLASSIC_SEND_DEST_SAT)
            ),
            Verification::Mismatch {
                field: "btc_output",
                ..
            }
        ));
    }

    #[test]
    fn btc_recipients_rejects_a_destination_output_for_enhanced_send_and_sweep() {
        // enhanced_send/sweep carry the destination in the payload and pay it no
        // BTC. When destination outputs are disallowed, a server that adds one
        // (funds leaving the wallet to a server-chosen address) is refused, even
        // though the address is the requested destination.
        let source = wpkh_addr(0x33);
        let dest = wpkh_addr(0x11);
        let tx = tx_with_outputs(vec![
            op_return_output(),
            value_output(&dest, 5000),
            value_output(&source, 9000),
        ]);
        let intent = Intent {
            destination: Some(dest.to_string()),
            source: Some(source.to_string()),
            ..Default::default()
        };
        assert!(matches!(
            verify_btc_recipients(&tx, &intent, NET, DestinationBtc::Forbidden),
            Verification::Mismatch {
                field: "btc_output",
                ..
            }
        ));
    }

    #[test]
    fn btc_recipients_allows_self_transfer_change_even_when_destination_disallowed() {
        // A sweep to oneself (source == destination): the only value output is
        // change back to the source, which must still be allowed even with
        // destination outputs disallowed (source is checked first).
        let same = wpkh_addr(0x33);
        let tx = tx_with_outputs(vec![op_return_output(), value_output(&same, 9000)]);
        let intent = Intent {
            destination: Some(same.to_string()),
            source: Some(same.to_string()),
            ..Default::default()
        };
        assert_eq!(
            verify_btc_recipients(&tx, &intent, NET, DestinationBtc::Forbidden),
            Verification::Match
        );
    }

    // ---- verify_btc_send (plain BTC transfer, no Counterparty payload) ----

    #[test]
    fn btc_send_matches_a_plain_transfer_with_no_data_output() {
        // No OP_RETURN at all: exactly what `compose_send_btc` produces for a
        // non-dispenser destination. Must verify, not be treated as
        // unverifiable/refused.
        let dest = wpkh_addr(0x11);
        let source = wpkh_addr(0x33);
        let tx = tx_with_outputs(vec![
            value_output(&dest, 5000),
            value_output(&source, 9000), // change
        ]);
        let intent = Intent {
            quantity: Some(5000),
            destination: Some(dest.to_string()),
            source: Some(source.to_string()),
            ..Default::default()
        };
        assert_eq!(verify_btc_send(&tx, &intent, NET), Verification::Match);
    }

    #[test]
    fn btc_send_matches_a_dispense_trigger_with_a_data_output() {
        // A BTC send to a live dispenser carries a dispense-trigger OP_RETURN
        // that is not a `send`/`enhanced_send`/`sweep` payload; `verify_btc_send`
        // must still verify the BTC flow without trying to decode it.
        let dest = wpkh_addr(0x11);
        let source = wpkh_addr(0x33);
        let tx = tx_with_outputs(vec![
            value_output(&dest, 5000),
            op_return_output(),
            value_output(&source, 9000),
        ]);
        let intent = Intent {
            quantity: Some(5000),
            destination: Some(dest.to_string()),
            source: Some(source.to_string()),
            ..Default::default()
        };
        assert_eq!(verify_btc_send(&tx, &intent, NET), Verification::Match);
    }

    #[test]
    fn btc_send_detects_wrong_amount() {
        let dest = wpkh_addr(0x11);
        let source = wpkh_addr(0x33);
        let tx = tx_with_outputs(vec![value_output(&dest, 1), value_output(&source, 9000)]);
        let intent = Intent {
            quantity: Some(5000), // requested 5000, paid 1
            destination: Some(dest.to_string()),
            source: Some(source.to_string()),
            ..Default::default()
        };
        assert!(matches!(
            verify_btc_send(&tx, &intent, NET),
            Verification::Mismatch {
                field: "btc_output",
                ..
            }
        ));
    }

    #[test]
    fn btc_send_rejects_an_extra_destination_output_that_over_pays() {
        // Correct destination and a first output paying exactly the requested
        // amount, but the server adds a *second* output to the same destination,
        // over-paying with the user's own BTC. Requiring the exact total (not
        // "some output pays it") refuses this (M2).
        let dest = wpkh_addr(0x11);
        let source = wpkh_addr(0x33);
        let tx = tx_with_outputs(vec![
            value_output(&dest, 5000),      // the requested amount
            value_output(&dest, 4_000_000), // an extra siphon to the destination
            value_output(&source, 9000),    // change
        ]);
        let intent = Intent {
            quantity: Some(5000),
            destination: Some(dest.to_string()),
            source: Some(source.to_string()),
            ..Default::default()
        };
        assert!(matches!(
            verify_btc_send(&tx, &intent, NET),
            Verification::Mismatch {
                field: "btc_output",
                ..
            }
        ));
    }

    #[test]
    fn btc_send_detects_diverted_change() {
        // Correct destination/amount, but the change leaks to a third party.
        let dest = wpkh_addr(0x11);
        let source = wpkh_addr(0x33);
        let attacker = wpkh_addr(0x44);
        let tx = tx_with_outputs(vec![
            value_output(&dest, 5000),
            value_output(&attacker, 9000),
        ]);
        let intent = Intent {
            quantity: Some(5000),
            destination: Some(dest.to_string()),
            source: Some(source.to_string()),
            ..Default::default()
        };
        assert!(matches!(
            verify_btc_send(&tx, &intent, NET),
            Verification::Mismatch {
                field: "btc_output",
                ..
            }
        ));
    }

    #[test]
    fn btc_recipients_fail_closed_when_source_unknown() {
        // Without a source the change/siphon distinction can't be made, so the
        // check fails *closed* (Unverifiable) rather than passing — otherwise a
        // caller that forgot the source would silently disable BTC-flow
        // protection and wave an attacker-paying output through.
        let attacker = wpkh_addr(0x44);
        let tx = tx_with_outputs(vec![value_output(&attacker, 9000)]);
        assert!(matches!(
            verify_btc_recipients(
                &tx,
                &Intent::default(),
                NET,
                DestinationBtc::AtMost(MAX_CLASSIC_SEND_DEST_SAT)
            ),
            Verification::Unverifiable { .. }
        ));
    }
}
