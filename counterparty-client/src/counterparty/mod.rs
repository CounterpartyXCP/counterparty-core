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
//! **from the composed transaction itself** and compares the fields that matter
//! for a transfer (asset, quantity, destination). It then also confirms the
//! transaction's **BTC** outputs only pay the source (change) or the destination
//! ([`decode::verify_btc_recipients`]) — a matching payload alone does not stop a
//! hostile server from routing the change to an attacker.
//!
//! ## Scope and safe degradation
//!
//! This layer verifies *which* addresses the transaction pays and *what* the
//! payload encodes; it does **not** bound *how much* BTC leaves as miner fee. A
//! [`Verification::Match`] therefore only rules out a wrong destination/asset/
//! quantity and a diverted BTC output — it is safe against value theft only in
//! combination with the caller's absolute miner-fee cap
//! (`commands::wallet::transaction::ensure_fee_within_limit`), which bounds a
//! hostile server routing the balance to fees.
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

/// Numeric Counterparty asset ids for the two special assets, mirroring
/// `ledger.issuances.generate_asset_id`.
const BTC_ASSET_ID: u64 = 0;
const XCP_ASSET_ID: u64 = 1;

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
    /// The wallet source address that funds and signs the transaction (already
    /// label-resolved). Used to confirm the transaction's BTC value returns to
    /// the source as change rather than being siphoned to a third party. `None`
    /// skips the BTC-flow check (the wallet path always supplies it).
    pub source: Option<String>,
    /// Expected `sweep` flags OR-mask (`FLAG_BALANCES=1`, `FLAG_OWNERSHIP=2`,
    /// `FLAG_BINARY_MEMO=4`). `None` skips the check. A sweep with a different
    /// flag mask than requested can transfer asset *ownership* the user did not
    /// intend, so it must be verified for a `sweep` command.
    pub flags: Option<u64>,
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
/// For a command *inside* this set, an `Unverifiable` outcome is treated as a
/// hard failure by the caller (a server that a verifiable command cannot decode
/// is refused, never trusted — see `verify_composed_transaction_or_abort`).
pub fn is_verifiable_type(tx_type: &str) -> bool {
    matches!(tx_type, "send" | "enhanced_send" | "sweep")
}

/// The Counterparty message type id(s) a verifiable command may legitimately
/// compose to. A composed transaction whose embedded type is **not** in this set
/// is a type mismatch and must be refused.
///
/// This binding is the load-bearing defence against a message-type-confusion
/// attack: the per-type verifiers check *disjoint* field sets (a `sweep` payload
/// carries no asset or quantity, so [`decode::verify_sweep`] only checks the
/// destination). Dispatching on the composed type alone — without confirming it
/// matches the command the user ran — would let a hostile server compose a
/// balance-and-ownership-draining `sweep` (type 4) to the user's intended
/// destination in response to a bounded `send 10 XCP` and have it pass as a
/// "verified" match. `compose_send` yields classic `send` (0) or `enhanced_send`
/// (2) for a single destination (multi-destination MPMA (3) is not in this set,
/// so it degrades to `Unverifiable` and is refused for a verifiable command).
fn expected_message_types(tx_type: &str) -> &'static [u32] {
    match tx_type {
        "send" => &[0, 2],
        "enhanced_send" => &[2],
        "sweep" => &[4],
        _ => &[],
    }
}

/// Message type id of a *dispense trigger* — the only Counterparty payload a
/// plain `--asset BTC` send may legitimately carry. It encodes no
/// asset/quantity/destination (its presence just tells consensus to run any
/// dispenser paid by this transaction), so it moves none of the source's
/// assets. Mirrors `counterpartycore/lib/messages/dispense.py` (`ID = 13`).
const DISPENSE_ID: u32 = 13;

/// Human-readable name for a Counterparty message type id, for error messages.
fn message_type_name(type_id: u32) -> &'static str {
    match type_id {
        0 => "send",
        2 => "enhanced_send",
        3 => "mpma_send",
        4 => "sweep",
        _ => "unknown",
    }
}

/// Split a de-obfuscated Counterparty message into `(type_id, body)`, mirroring
/// `counterpartycore/lib/parser/messagetype.unpack`: the type id is a single
/// byte when that byte is non-zero (the `short_tx_type_id` form, active on every
/// live network), otherwise a 4-byte big-endian id. Classic `send` has id `0`,
/// so it is 4-byte-prefixed on-chain — reading a single byte here (as a naive
/// `split_first` would) misparses it and silently disables its verification.
fn unpack_message_type(message: &[u8]) -> Option<(u32, &[u8])> {
    // Matches the consensus `len > 1` / `len > 4` guards: there must be at least
    // one byte of body after the type prefix.
    if message.len() > 1 && message[0] > 0 {
        return Some((u32::from(message[0]), &message[1..]));
    }
    if message.len() > 4 {
        let id = u32::from_be_bytes(message[0..4].try_into().ok()?);
        return Some((id, &message[4..]));
    }
    None
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
    // Lower bound of the numeric-asset id range (`A<n>`); named assets live
    // strictly below it. Mirrors `generate_asset_id`'s `26**12 + 1 <= id`.
    const NUMERIC_ASSET_MIN: u64 = 26_u64.pow(12) + 1;
    // `generate_asset_id`'s `assert asset_id >= 26**3` for base-26 named assets.
    const NAMED_ASSET_MIN: u64 = 26_u64.pow(3);

    match name {
        "BTC" => return Some(BTC_ASSET_ID),
        "XCP" => return Some(XCP_ASSET_ID),
        _ => {}
    }

    // Sub-asset longnames (PARENT.child) are registry-assigned; can't resolve.
    if name.contains('.') {
        return None;
    }

    let bytes = name.as_bytes();

    // Numeric asset name: `A` followed by decimal digits. Only ids in
    // `[26^12 + 1, u64::MAX]` are valid — consensus rejects anything smaller, so
    // resolving it would compute a *wrong* offline anchor (e.g. `A5` -> 5).
    if bytes.first() == Some(&b'A') {
        let n = name[1..].parse::<u64>().ok()?;
        return (n >= NUMERIC_ASSET_MIN).then_some(n);
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
    // Faithful to `generate_asset_id`: a base-26 id is in `[26^3, 26^12)`.
    (NAMED_ASSET_MIN..NUMERIC_ASSET_MIN)
        .contains(&n)
        .then_some(n)
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

/// Test-only builder: a composed-transaction hex carrying a classic `send`
/// (type 0), obfuscated exactly as the server composer does. Type 0 is
/// **4-byte-prefixed** on-chain (`\x00\x00\x00\x00`), followed by `>QQ`
/// (asset id, quantity). Outputs are `[dust→destination, OP_RETURN, extra…]`,
/// so the destination sits before the OP_RETURN (the consensus position) and
/// `extra_outputs` model change/attacker outputs for the BTC-flow checks.
#[cfg(test)]
pub(crate) fn build_test_classic_send_tx_hex(
    txid_display: [u8; 32],
    asset_id: u64,
    quantity: u64,
    destination: &bitcoin::Address,
    extra_outputs: &[(bitcoin::Address, u64)],
) -> String {
    use bitcoin::hashes::Hash as _;

    let mut message = vec![0x00u8, 0x00, 0x00, 0x00]; // type 0, 4-byte prefix
    message.extend_from_slice(&asset_id.to_be_bytes());
    message.extend_from_slice(&quantity.to_be_bytes());

    let mut payload = b"CNTRPRTY".to_vec();
    payload.extend_from_slice(&message);
    arc4::decrypt(&txid_display, &mut payload); // obfuscate (RC4 is symmetric)

    let mut internal = txid_display;
    internal.reverse();
    let push = bitcoin::script::PushBytesBuf::try_from(payload).unwrap();

    let mut output = vec![
        bitcoin::TxOut {
            value: bitcoin::Amount::from_sat(546),
            script_pubkey: destination.script_pubkey(),
        },
        bitcoin::TxOut {
            value: bitcoin::Amount::ZERO,
            script_pubkey: bitcoin::ScriptBuf::new_op_return(&push),
        },
    ];
    for (addr, value) in extra_outputs {
        output.push(bitcoin::TxOut {
            value: bitcoin::Amount::from_sat(*value),
            script_pubkey: addr.script_pubkey(),
        });
    }

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
        output,
    };
    hex::encode(bitcoin::consensus::serialize(&tx))
}

/// Test-only builder: a plain BTC transfer with **no** Counterparty data
/// output at all, exactly as `compose_send_btc` produces for a non-dispenser
/// destination (`data = None`, output = `[(destination, quantity), (change,
/// source)]`).
#[cfg(test)]
pub(crate) fn build_test_plain_btc_send_tx_hex(
    destination: &bitcoin::Address,
    quantity: u64,
    source: &bitcoin::Address,
    change: u64,
) -> String {
    use bitcoin::hashes::Hash as _;

    let tx = Transaction {
        version: bitcoin::transaction::Version::TWO,
        lock_time: bitcoin::absolute::LockTime::ZERO,
        input: vec![bitcoin::TxIn {
            previous_output: bitcoin::OutPoint {
                txid: bitcoin::Txid::all_zeros(),
                vout: 0,
            },
            script_sig: bitcoin::ScriptBuf::new(),
            sequence: bitcoin::Sequence::MAX,
            witness: bitcoin::Witness::new(),
        }],
        output: vec![
            bitcoin::TxOut {
                value: bitcoin::Amount::from_sat(quantity),
                script_pubkey: destination.script_pubkey(),
            },
            bitcoin::TxOut {
                value: bitcoin::Amount::from_sat(change),
                script_pubkey: source.script_pubkey(),
            },
        ],
    };
    hex::encode(bitcoin::consensus::serialize(&tx))
}

/// Test-only builder: a composed-transaction hex carrying a `sweep` (type 4),
/// obfuscated exactly as the server composer does (RC4 over `CNTRPRTY`, the type
/// byte `0x04`, and CBOR `[packed_destination, flags, memo]`, keyed by the first
/// input's txid in display order). Its only value output is change back to
/// `source`, mirroring a real sweep (the destination is carried in the payload,
/// not as a BTC output).
#[cfg(test)]
pub(crate) fn build_test_sweep_tx_hex(
    txid_display: [u8; 32],
    destination: &bitcoin::Address,
    flags: u64,
    source: &bitcoin::Address,
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
            Value::Bytes(packed),
            Value::Integer(flags.into()),
            Value::Bytes(vec![]),
        ]),
        &mut cbor,
    )
    .unwrap();

    let mut payload = b"CNTRPRTY".to_vec();
    payload.push(0x04); // sweep type id
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
        output: vec![
            bitcoin::TxOut {
                value: bitcoin::Amount::ZERO,
                script_pubkey: bitcoin::ScriptBuf::new_op_return(&push),
            },
            // Change back to the source (a real sweep pays no BTC to the payload
            // destination), so `verify_btc_recipients` would pass on its own.
            bitcoin::TxOut {
                value: bitcoin::Amount::from_sat(1000),
                script_pubkey: source.script_pubkey(),
            },
        ],
    };
    hex::encode(bitcoin::consensus::serialize(&tx))
}

/// Test-only builder: a plain-BTC-send-shaped transaction whose single
/// OP_RETURN carries `message` (the de-obfuscated bytes *after* the `CNTRPRTY`
/// prefix — type-id byte(s) + body), obfuscated the way the composer does.
/// Outputs `[dust→destination, OP_RETURN(message), change→source]`, so every BTC
/// recipient checks out and only the hidden payload is suspicious.
#[cfg(test)]
pub(crate) fn build_test_btc_send_with_message_tx_hex(
    txid_display: [u8; 32],
    destination: &bitcoin::Address,
    quantity: u64,
    source: &bitcoin::Address,
    message: &[u8],
) -> String {
    use bitcoin::hashes::Hash as _;

    let mut payload = b"CNTRPRTY".to_vec();
    payload.extend_from_slice(message);
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
        output: vec![
            bitcoin::TxOut {
                value: bitcoin::Amount::from_sat(quantity),
                script_pubkey: destination.script_pubkey(),
            },
            bitcoin::TxOut {
                value: bitcoin::Amount::ZERO,
                script_pubkey: bitcoin::ScriptBuf::new_op_return(&push),
            },
            bitcoin::TxOut {
                value: bitcoin::Amount::from_sat(1000),
                script_pubkey: source.script_pubkey(),
            },
        ],
    };
    hex::encode(bitcoin::consensus::serialize(&tx))
}

/// Guard the plain-BTC-send path against a Counterparty message hidden in an
/// OP_RETURN. Returns `Some(Mismatch)` when the transaction carries a
/// value-bearing payload (the fund-draining shape) or an unexpected number of
/// data outputs, and `None` when it is a genuine plain payment — no OP_RETURN,
/// a single non-Counterparty OP_RETURN (which consensus ignores), or a single
/// dispense trigger (type 13, which moves none of the source's assets).
fn reject_hidden_message_on_btc_send(tx: &Transaction) -> Option<Verification> {
    let mismatch = |composed: String| {
        Some(Verification::Mismatch {
            field: "message type",
            requested: "a plain BTC send (no Counterparty payload)".to_string(),
            composed,
        })
    };

    let op_return_count = tx
        .output
        .iter()
        .filter(|o| o.script_pubkey.is_op_return())
        .count();

    match op_return_count {
        // A plain payment. Nothing to hide a message in.
        0 => None,
        // Decode the single data output. Consensus only acts on a well-formed,
        // de-obfuscated `CNTRPRTY` payload, so a non-Counterparty OP_RETURN is
        // harmless; a Counterparty payload is allowed only if it is a dispense
        // trigger.
        1 => match extract::extract_message(tx) {
            extract::Extracted::Message(message) => match unpack_message_type(&message) {
                Some((DISPENSE_ID, _)) => None,
                Some((type_id, _)) => mismatch(format!(
                    "a '{}' message (type {type_id}) hidden in the OP_RETURN",
                    message_type_name(type_id)
                )),
                None => mismatch(
                    "an unrecognised Counterparty payload hidden in the OP_RETURN".to_string(),
                ),
            },
            extract::Extracted::Unsupported(_) => None,
        },
        // A legitimate BTC send has at most one data output (an optional dispense
        // trigger); more than one is ambiguous to decode and never expected, so
        // refuse rather than risk consensus acting on one we did not inspect.
        _ => mismatch("more than one OP_RETURN data output".to_string()),
    }
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

    // A plain BTC transfer (`asset == "BTC"`) is not a Counterparty message at
    // all — see `decode::verify_btc_send`. Without this, `extract_message`
    // reports "no data output found" and the caller (which treats `send` as a
    // verifiable type) would hard-refuse every ordinary BTC send.
    //
    // `verify_btc_send`/`verify_btc_recipients` only inspect the BTC recipients
    // and deliberately *skip* OP_RETURN outputs, so on their own they would wave
    // through a hostile server that hides a value-bearing message in the data
    // output. Because the composed transaction's first input is the user's own
    // (Counterparty "source") address, consensus would parse such a message and
    // debit the source's assets — the dust-to-destination BTC output being pure
    // cover. Refuse any embedded message other than a dispense trigger first.
    if tx_type == "send" && intent.asset_id == Some(BTC_ASSET_ID) {
        if let Some(mismatch) = reject_hidden_message_on_btc_send(&tx) {
            return mismatch;
        }
        return decode::verify_btc_send(&tx, intent, network);
    }

    let message = match extract::extract_message(&tx) {
        extract::Extracted::Message(m) => m,
        extract::Extracted::Unsupported(reason) => {
            return Verification::Unverifiable {
                reason: reason.to_string(),
            }
        }
    };

    // Decode the *actual* Counterparty message type embedded in the transaction.
    // The type prefix is decoded exactly as consensus packs it (1 or 4 bytes; see
    // `unpack_message_type`).
    let Some((type_id, body)) = unpack_message_type(&message) else {
        return Verification::Unverifiable {
            reason: "empty or truncated Counterparty message".to_string(),
        };
    };

    // Bind the composed type to the command the user ran. Without this, a server
    // handed a `send` command could compose a `sweep` (which the destination-only
    // `verify_sweep` would happily "match") and drain the whole wallet. A type
    // the command should never produce is a hard mismatch, not a soft
    // `Unverifiable` — the caller refuses to sign either way, but a mismatch
    // states plainly *why*.
    if !expected_message_types(tx_type).contains(&type_id) {
        return Verification::Mismatch {
            field: "message type",
            requested: format!("a '{tx_type}' transaction"),
            composed: format!(
                "a '{}' transaction (message type {type_id})",
                message_type_name(type_id)
            ),
        };
    }

    let payload = match type_id {
        0 => decode::verify_classic_send(body, &tx, intent, network),
        2 => decode::verify_enhanced_send(body, intent, network),
        4 => decode::verify_sweep(body, intent, network),
        other => {
            return Verification::Unverifiable {
                reason: format!("composed message type {other} is not independently verified"),
            }
        }
    };

    // The Counterparty payload (asset/quantity/destination) matched; now confirm
    // the *BTC* flows don't siphon funds — a matching payload does not stop a
    // hostile server from routing the change output to an attacker address. Only a
    // classic `send` (type 0) legitimately pays the destination a BTC (dust)
    // output; an `enhanced_send` (2) or `sweep` (4) carries the destination in its
    // payload and pays it no BTC, so a destination-paying output there is refused.
    match payload {
        Verification::Match => decode::verify_btc_recipients(&tx, intent, network, type_id == 0),
        other => other,
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

    #[test]
    fn asset_id_rejects_out_of_range_numeric_names() {
        // `generate_asset_id` only accepts numeric ids in [26^12 + 1, u64::MAX];
        // a smaller `A<n>` is not a valid asset, so it must not resolve to a wrong
        // offline anchor (previously `A5` -> Some(5)).
        assert_eq!(asset_id_for_name("A5"), None);
        assert_eq!(asset_id_for_name("A100"), None);
        assert_eq!(asset_id_for_name("A95428956661682176"), None); // 26^12, one below min
                                                                   // The smallest valid numeric id (26^12 + 1) still resolves.
        assert_eq!(
            asset_id_for_name("A95428956661682177"),
            Some(95428956661682177)
        );
    }

    // ---- full path: verify_composed_transaction ----

    fn wpkh_addr(seed: u8) -> Address {
        let wp = WitnessProgram::new(WitnessVersion::V0, &[seed; 20]).unwrap();
        Address::from_witness_program(wp, NET)
    }

    #[test]
    fn verifies_matching_enhanced_send_end_to_end() {
        let dest = wpkh_addr(0x11);
        let source = wpkh_addr(0x33);
        let hex = build_test_enhanced_send_tx_hex([0x11; 32], 7, 2500, &dest);
        let intent = Intent {
            asset_id: Some(7),
            quantity: Some(2500),
            destination: Some(dest.to_string()),
            // The BTC-flow check now fails closed without a source, so supply it
            // (the wallet path always does); the enhanced_send tx has no BTC
            // outputs, so any source verifies.
            source: Some(source.to_string()),
            ..Default::default()
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
            ..Default::default()
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

    // ---- H1: classic send (type 0) is 4-byte-prefixed and now verified ----

    #[test]
    fn unpack_message_type_matches_consensus_widths() {
        // Non-zero first byte -> 1-byte type id; leading zero -> 4-byte id.
        assert_eq!(
            unpack_message_type(&[2, 0xaa, 0xbb]),
            Some((2, &[0xaa, 0xbb][..]))
        );
        assert_eq!(
            unpack_message_type(&[0, 0, 0, 0, 0xcc]),
            Some((0, &[0xcc][..]))
        );
        // Too short to carry a type prefix plus a body.
        assert_eq!(unpack_message_type(&[0, 0, 0, 0]), None);
        assert_eq!(unpack_message_type(&[]), None);
    }

    #[test]
    fn classic_send_type0_wrong_destination_is_a_mismatch_not_unverifiable() {
        // Regression: the type-0 4-byte prefix used to be mis-parsed as one byte,
        // so classic-send verification silently never ran (returned Unverifiable).
        // A send paying the attacker must now be a hard destination Mismatch.
        let victim = wpkh_addr(0x11);
        let attacker = wpkh_addr(0x22);
        let hex = build_test_classic_send_tx_hex([0x11; 32], 1, 2500, &attacker, &[]);
        let intent = Intent {
            asset_id: Some(1),
            quantity: Some(2500),
            destination: Some(victim.to_string()),
            source: Some(victim.to_string()),
            flags: None,
        };
        assert!(matches!(
            verify_composed_transaction(&hex, "send", &intent, NET),
            Verification::Mismatch {
                field: "destination",
                ..
            }
        ));
    }

    #[test]
    fn classic_send_type0_matches_a_correct_transaction() {
        let dest = wpkh_addr(0x11);
        let source = wpkh_addr(0x33);
        let hex =
            build_test_classic_send_tx_hex([0x11; 32], 1, 2500, &dest, &[(source.clone(), 9000)]);
        let intent = Intent {
            asset_id: Some(1),
            quantity: Some(2500),
            destination: Some(dest.to_string()),
            source: Some(source.to_string()),
            flags: None,
        };
        assert_eq!(
            verify_composed_transaction(&hex, "send", &intent, NET),
            Verification::Match
        );
    }

    #[test]
    fn rejects_diverted_btc_change_to_a_third_party() {
        // The Counterparty payload (asset/quantity/destination) is correct, but
        // the BTC change is routed to an attacker output -> refuse despite Match.
        let dest = wpkh_addr(0x11);
        let source = wpkh_addr(0x33);
        let attacker = wpkh_addr(0x44);
        let hex = build_test_classic_send_tx_hex([0x11; 32], 1, 2500, &dest, &[(attacker, 9000)]);
        let intent = Intent {
            asset_id: Some(1),
            quantity: Some(2500),
            destination: Some(dest.to_string()),
            source: Some(source.to_string()),
            flags: None,
        };
        assert!(matches!(
            verify_composed_transaction(&hex, "send", &intent, NET),
            Verification::Mismatch {
                field: "btc_output",
                ..
            }
        ));
    }

    // ---- message-type confusion: a `send` must never verify as a `sweep` ----

    #[test]
    fn send_command_composed_as_sweep_is_a_type_mismatch() {
        // The user ran `send 2500 of asset 1 -> dest`, but the server composed a
        // type-4 *sweep* to that same destination. `verify_sweep` only checks the
        // destination, so without the command<->type binding this would pass as a
        // Match and drain the whole wallet. It must be a hard type Mismatch.
        let dest = wpkh_addr(0x11);
        let source = wpkh_addr(0x33);
        let hex = build_test_sweep_tx_hex([0x11; 32], &dest, 1, &source);
        let intent = Intent {
            asset_id: Some(1),
            quantity: Some(2500),
            destination: Some(dest.to_string()),
            source: Some(source.to_string()),
            flags: None,
        };
        assert!(matches!(
            verify_composed_transaction(&hex, "send", &intent, NET),
            Verification::Mismatch {
                field: "message type",
                ..
            }
        ));
    }

    #[test]
    fn sweep_command_composed_as_send_is_a_type_mismatch() {
        // The mirror case: a `sweep` command must not be silently verified as a
        // classic send (which checks a different, non-overlapping field set).
        let dest = wpkh_addr(0x11);
        let hex = build_test_classic_send_tx_hex([0x11; 32], 1, 2500, &dest, &[]);
        let intent = Intent {
            destination: Some(dest.to_string()),
            flags: Some(1),
            ..Default::default()
        };
        assert!(matches!(
            verify_composed_transaction(&hex, "sweep", &intent, NET),
            Verification::Mismatch {
                field: "message type",
                ..
            }
        ));
    }

    #[test]
    fn matching_sweep_command_verifies_end_to_end() {
        // A genuine sweep to the requested destination with the requested flags
        // still verifies cleanly (the binding does not over-reject).
        let dest = wpkh_addr(0x11);
        let source = wpkh_addr(0x33);
        let hex = build_test_sweep_tx_hex([0x11; 32], &dest, 3, &source);
        let intent = Intent {
            destination: Some(dest.to_string()),
            source: Some(source.to_string()),
            flags: Some(3),
            ..Default::default()
        };
        assert_eq!(
            verify_composed_transaction(&hex, "sweep", &intent, NET),
            Verification::Match
        );
    }

    // ---- HIGH regression: a plain BTC send must never be hard-refused ----

    #[test]
    fn plain_btc_send_with_no_data_output_verifies_instead_of_being_refused() {
        // Before the fix, `send --asset BTC` (no dispenser) always produced a
        // transaction with no OP_RETURN, which `extract_message` reported as
        // `Unsupported`, and since "send" is a verifiable type the caller would
        // hard-refuse to sign — every plain BTC send was broken.
        let dest = wpkh_addr(0x11);
        let source = wpkh_addr(0x33);
        let hex = build_test_plain_btc_send_tx_hex(&dest, 5000, &source, 9000);
        let intent = Intent {
            asset_id: Some(0), // BTC
            quantity: Some(5000),
            destination: Some(dest.to_string()),
            source: Some(source.to_string()),
            flags: None,
        };
        assert_eq!(
            verify_composed_transaction(&hex, "send", &intent, NET),
            Verification::Match
        );
    }

    #[test]
    fn plain_btc_send_wrong_amount_is_a_mismatch_not_unverifiable() {
        let dest = wpkh_addr(0x11);
        let attacker_amount_source = wpkh_addr(0x33);
        let hex = build_test_plain_btc_send_tx_hex(&dest, 1, &attacker_amount_source, 9000);
        let intent = Intent {
            asset_id: Some(0),
            quantity: Some(5000),
            destination: Some(dest.to_string()),
            source: Some(attacker_amount_source.to_string()),
            flags: None,
        };
        assert!(matches!(
            verify_composed_transaction(&hex, "send", &intent, NET),
            Verification::Mismatch {
                field: "destination",
                ..
            }
        ));
    }

    // Build the de-obfuscated body of a `sweep` (type 4) to `destination` with
    // `flags`, for hiding inside a BTC-send OP_RETURN.
    fn sweep_message(destination: &Address, flags: u64) -> Vec<u8> {
        use ciborium::value::Value;
        let wp = destination.witness_program().unwrap();
        let mut packed = vec![0x03, wp.version() as u8];
        packed.extend_from_slice(wp.program().as_bytes());
        let mut cbor = Vec::new();
        ciborium::into_writer(
            &Value::Array(vec![
                Value::Bytes(packed),
                Value::Integer(flags.into()),
                Value::Bytes(vec![]),
            ]),
            &mut cbor,
        )
        .unwrap();
        let mut message = vec![0x04u8]; // sweep type id
        message.extend_from_slice(&cbor);
        message
    }

    #[test]
    fn btc_send_hiding_a_sweep_in_the_op_return_is_refused() {
        // `send --asset BTC` paying `dest`. A hostile server pays that dust to
        // `dest` (cover) but hides a type-4 sweep to `attacker` in the OP_RETURN;
        // consensus (source = the user's first input) would drain the source's
        // balances *and* asset ownership to the attacker while every BTC recipient
        // (dest + source change) checks out. Must be a hard "message type"
        // Mismatch, never a Match — this is the finding the guard closes.
        let dest = wpkh_addr(0x11);
        let source = wpkh_addr(0x33);
        let attacker = wpkh_addr(0x44);
        let hidden = sweep_message(&attacker, 3); // FLAG_BALANCES | FLAG_OWNERSHIP
        let hex =
            build_test_btc_send_with_message_tx_hex([0x11; 32], &dest, 5000, &source, &hidden);
        let intent = Intent {
            asset_id: Some(0), // BTC
            quantity: Some(5000),
            destination: Some(dest.to_string()),
            source: Some(source.to_string()),
            flags: None,
        };
        assert!(matches!(
            verify_composed_transaction(&hex, "send", &intent, NET),
            Verification::Mismatch {
                field: "message type",
                ..
            }
        ));
    }

    #[test]
    fn btc_send_with_a_dispense_trigger_op_return_is_allowed() {
        // A genuine BTC send to a live dispenser carries a dispense-trigger data
        // output (message type 13, `\x0d\x00`), which moves none of the source's
        // assets. The guard must not over-reject it.
        let dest = wpkh_addr(0x11);
        let source = wpkh_addr(0x33);
        let dispense = [0x0du8, 0x00]; // DISPENSE_ID + one body byte
        let hex =
            build_test_btc_send_with_message_tx_hex([0x11; 32], &dest, 5000, &source, &dispense);
        let intent = Intent {
            asset_id: Some(0), // BTC
            quantity: Some(5000),
            destination: Some(dest.to_string()),
            source: Some(source.to_string()),
            flags: None,
        };
        assert_eq!(
            verify_composed_transaction(&hex, "send", &intent, NET),
            Verification::Match
        );
    }

    #[test]
    fn sweep_with_unrequested_ownership_flag_is_a_mismatch() {
        // The user asked to sweep balances only (flags = FLAG_BALANCES = 1) but the
        // server flipped FLAG_OWNERSHIP on (flags = 3), which would hand away asset
        // issuer rights. That must be refused.
        let dest = wpkh_addr(0x11);
        let source = wpkh_addr(0x33);
        let hex = build_test_sweep_tx_hex([0x11; 32], &dest, 3, &source);
        let intent = Intent {
            destination: Some(dest.to_string()),
            source: Some(source.to_string()),
            flags: Some(1),
            ..Default::default()
        };
        assert!(matches!(
            verify_composed_transaction(&hex, "sweep", &intent, NET),
            Verification::Mismatch {
                field: "sweep flags",
                ..
            }
        ));
    }
}
