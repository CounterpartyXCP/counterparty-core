//! Pull the de-obfuscated Counterparty message out of a composed transaction.
//!
//! Handles the `OP_RETURN` data encoding, which is what every small payload
//! uses (`send`, `enhanced_send` and `sweep` all fit under the 80-byte
//! `OP_RETURN` limit). Bare-multisig and taproot-envelope encodings are not
//! decoded here and return [`Extracted::Unsupported`] so the caller degrades
//! safely.

use bitcoin::hashes::Hash;
use bitcoin::opcodes::all::{OP_CHECKMULTISIG, OP_CHECKSIG, OP_PUSHNUM_1, OP_RETURN};
use bitcoin::opcodes::Opcode;
use bitcoin::script::Instruction;
use bitcoin::{Script, Transaction};

use super::arc4;

/// The 8-byte Counterparty message prefix.
const PREFIX: &[u8] = b"CNTRPRTY";

/// Result of extracting the Counterparty message from a transaction.
pub enum Extracted {
    /// The de-obfuscated, prefix-stripped message (type id byte + body).
    Message(Vec<u8>),
    /// No decodable `OP_RETURN` Counterparty data output was found in a form
    /// this module handles.
    Unsupported(&'static str),
}

/// The RC4 key for `tx`: the first input's txid in **display** byte order
/// (`to_byte_array()` is internal/little-endian, so reverse it — mirrors
/// `counterparty-rs/src/indexer/bitcoin_client.rs:699` and the composer's
/// `unhexlify(txid_hex)`).
fn arc4_key(tx: &Transaction) -> Option<[u8; 32]> {
    let first = tx.input.first()?;
    let mut key = first.previous_output.txid.to_byte_array();
    key.reverse();
    Some(key)
}

/// The single data push of a strict `[OP_RETURN, <push>]` script. This mirrors
/// consensus (`parse_vout` in `counterparty-rs/src/indexer/bitcoin_client.rs`),
/// which matches only that exact shape and treats any other OP_RETURN (bare, or
/// with extra opcodes or *multiple* pushes) as non-Counterparty. Returns `None`
/// for a non-OP_RETURN script or any shape other than one leading `OP_RETURN`
/// followed by exactly one data push — so a multi-push OP_RETURN, which the
/// previous concatenating logic would "decode" into a message consensus never
/// sees, is now correctly rejected instead.
fn opreturn_single_push(script: &Script) -> Option<Vec<u8>> {
    if !script.is_op_return() {
        return None;
    }
    let mut instructions = script.instructions();
    // The leading OP_RETURN opcode (guaranteed present by `is_op_return`).
    match instructions.next()? {
        Ok(Instruction::Op(op)) if op == OP_RETURN => {}
        _ => return None,
    }
    // Then exactly one data push.
    let data = match instructions.next()? {
        Ok(Instruction::PushBytes(bytes)) => bytes.as_bytes().to_vec(),
        _ => return None,
    };
    // Anything after the single push (a second push, or another opcode) is not
    // the consensus shape.
    if instructions.next().is_some() {
        return None;
    }
    Some(data)
}

/// The trailing opcode of a script, or `None` if the script is empty or its last
/// instruction is a data push rather than an opcode.
fn last_opcode(script: &Script) -> Option<Opcode> {
    match script.instructions().last() {
        Some(Ok(Instruction::Op(op))) => Some(op),
        _ => None,
    }
}

/// A **conservative heuristic** for whether a non-`OP_RETURN` output looks like a
/// Counterparty *data* output: a bare pay-to-pubkey (`… OP_CHECKSIG`) or
/// bare-multisig (`… OP_CHECKMULTISIG`) whose RC4-de-obfuscated content carries
/// the `CNTRPRTY` prefix. It follows the P2PK/multisig branches of `parse_vout`
/// (`counterparty-rs/src/indexer/bitcoin_client.rs`), where the prefix sits at
/// index 1 (after a leading length byte), unlike the `OP_RETURN` encoding.
///
/// This is deliberately **not** a bit-exact reimplementation of consensus data
/// extraction: the length guards below (`< 2`) bail out of some legacy
/// M/N-pushed-as-data multisig shapes that consensus *would* read, so this can
/// under-detect. That is safe because it is not the fund-safety guarantee — it
/// only feeds the extra hidden-message check in
/// [`reject_hidden_message_on_btc_send`](super::reject_hidden_message_on_btc_send).
/// The actual guarantee is [`decode::verify_btc_recipients`](super::decode::verify_btc_recipients):
/// any such data output is a bare multisig / bare P2PK that resolves to **no
/// address** (or, for a data-carrying P2PKH, a non-source/non-destination
/// address), so it is refused there before a `Match` can be returned. A false
/// negative here therefore cannot let funds leave — it can at worst let a
/// no-address output through to that backstop, which rejects it.
///
/// A standard destination is *not* flagged: P2WPKH/P2SH/P2WSH/P2TR do not end in
/// `OP_CHECKSIG`/`OP_CHECKMULTISIG`, and a P2PKH (which does end in `OP_CHECKSIG`)
/// de-obfuscates to bytes that do not carry the prefix — exactly as consensus
/// classifies it as a destination, not data.
fn is_extra_data_output(script: &Script, key: &[u8; 32]) -> bool {
    let instructions: Vec<Instruction> = match script.instructions().collect::<Result<_, _>>() {
        Ok(i) => i,
        // An unparsable script is not something consensus reads as data.
        Err(_) => return false,
    };

    // Extract the obfuscated candidate bytes the way consensus does.
    let mut enc = match last_opcode(script) {
        Some(op) if op == OP_CHECKSIG => {
            // Consensus reads instruction index 2 as the data carrier.
            match instructions.get(2) {
                Some(Instruction::PushBytes(b)) => b.as_bytes().to_vec(),
                Some(Instruction::Op(op)) if *op == OP_PUSHNUM_1 => vec![1],
                Some(Instruction::Op(op)) => vec![op.to_u8()],
                None => return false,
            }
        }
        Some(op) if op == OP_CHECKMULTISIG => {
            // The "pubkey" pushes carry the data; consensus drops the last one
            // and strips each chunk's leading sign byte and trailing nonce byte.
            let pushes: Vec<&[u8]> = instructions
                .iter()
                .filter_map(|i| match i {
                    Instruction::PushBytes(b) => Some(b.as_bytes()),
                    _ => None,
                })
                .collect();
            if pushes.len() < 2 {
                return false;
            }
            let mut enc = Vec::new();
            for chunk in &pushes[..pushes.len() - 1] {
                if chunk.len() < 2 {
                    return false;
                }
                enc.extend_from_slice(&chunk[1..chunk.len() - 1]);
            }
            enc
        }
        _ => return false,
    };

    arc4::decrypt(key, &mut enc);
    enc.len() > PREFIX.len() && enc[1..=PREFIX.len()] == *PREFIX
}

/// Extract and de-obfuscate the Counterparty message embedded in `tx`.
pub fn extract_message(tx: &Transaction) -> Extracted {
    let Some(key) = arc4_key(tx) else {
        return Extracted::Unsupported("composed transaction has no inputs");
    };

    // Exactly one OP_RETURN data output is expected. If there are several,
    // decoding is ambiguous — degrade safely rather than guess.
    let mut op_returns = tx.output.iter().filter(|o| o.script_pubkey.is_op_return());
    let Some(data_output) = op_returns.next() else {
        return Extracted::Unsupported(
            "no OP_RETURN data output found (bare-multisig or taproot-envelope encoding is not independently verified)",
        );
    };
    if op_returns.next().is_some() {
        return Extracted::Unsupported("multiple OP_RETURN outputs; cannot verify unambiguously");
    }

    let Some(mut payload) = opreturn_single_push(&data_output.script_pubkey) else {
        return Extracted::Unsupported(
            "OP_RETURN is not a single-push data output (does not match the consensus shape)",
        );
    };

    // Consensus concatenates *every* data output (OP_RETURN plus any bare-P2PK /
    // bare-multisig data output) in output order. This client only decodes the
    // single OP_RETURN, so if the transaction hides an additional consensus data
    // output, the message we verify is not the one consensus would parse. Refuse
    // rather than verify a partial payload — a hostile server could otherwise
    // pass a benign OP_RETURN past verification while a multisig output prepends
    // an attacker sweep/send that consensus acts on.
    if tx
        .output
        .iter()
        .any(|o| is_extra_data_output(&o.script_pubkey, &key))
    {
        return Extracted::Unsupported(
            "transaction carries an additional bare-multisig or pay-to-pubkey data output that \
             consensus would combine with the OP_RETURN; refusing to verify a partial message",
        );
    }

    arc4::decrypt(&key, &mut payload);

    match payload.strip_prefix(PREFIX) {
        Some(message) if !message.is_empty() => Extracted::Message(message.to_vec()),
        _ => Extracted::Unsupported("data output is not a Counterparty message"),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use bitcoin::absolute::LockTime;
    use bitcoin::transaction::Version;
    use bitcoin::{Amount, OutPoint, ScriptBuf, Sequence, Transaction, TxIn, TxOut, Txid, Witness};

    // Build a 1-input, 1-OP_RETURN transaction carrying `message` obfuscated the
    // way the composer does (RC4 over CNTRPRTY+message, keyed by the first
    // input's txid in display order).
    fn tx_with_message(txid_display: [u8; 32], message: &[u8]) -> Transaction {
        // Txid stores internal (reversed) order; feed the reverse so that
        // arc4_key() recovers `txid_display`.
        let mut internal = txid_display;
        internal.reverse();
        let txid = Txid::from_byte_array(internal);

        let mut payload = PREFIX.to_vec();
        payload.extend_from_slice(message);
        arc4::decrypt(&txid_display, &mut payload); // symmetric: this obfuscates

        let push = bitcoin::script::PushBytesBuf::try_from(payload).unwrap();
        Transaction {
            version: Version::TWO,
            lock_time: LockTime::ZERO,
            input: vec![TxIn {
                previous_output: OutPoint { txid, vout: 0 },
                script_sig: ScriptBuf::new(),
                sequence: Sequence::MAX,
                witness: Witness::new(),
            }],
            output: vec![TxOut {
                value: Amount::ZERO,
                script_pubkey: ScriptBuf::new_op_return(&push),
            }],
        }
    }

    #[test]
    fn extracts_and_deobfuscates_message() {
        let key = [0x11u8; 32];
        let msg = b"\x00\x01\x02hello";
        let tx = tx_with_message(key, msg);
        match extract_message(&tx) {
            Extracted::Message(m) => assert_eq!(m, msg),
            Extracted::Unsupported(r) => panic!("expected message, got: {r}"),
        }
    }

    #[test]
    fn non_counterparty_output_is_unsupported() {
        // An OP_RETURN whose de-obfuscated content lacks the CNTRPRTY prefix.
        let key = [0x22u8; 32];
        let mut internal = key;
        internal.reverse();
        let txid = Txid::from_byte_array(internal);
        let push = bitcoin::script::PushBytesBuf::try_from(b"not-counterparty".to_vec()).unwrap();
        let tx = Transaction {
            version: Version::TWO,
            lock_time: LockTime::ZERO,
            input: vec![TxIn {
                previous_output: OutPoint { txid, vout: 0 },
                script_sig: ScriptBuf::new(),
                sequence: Sequence::MAX,
                witness: Witness::new(),
            }],
            output: vec![TxOut {
                value: Amount::ZERO,
                script_pubkey: ScriptBuf::new_op_return(&push),
            }],
        };
        assert!(matches!(extract_message(&tx), Extracted::Unsupported(_)));
    }

    #[test]
    fn multi_push_op_return_is_unsupported() {
        // Consensus (`parse_vout`) accepts only `[OP_RETURN, <single push>]`. A
        // multi-push OP_RETURN is not a Counterparty data output on-chain, so the
        // client must not concatenate its pushes and "decode" a message consensus
        // never sees.
        let script = bitcoin::script::Builder::new()
            .push_opcode(OP_RETURN)
            .push_slice(b"CNTRPRTYAA")
            .push_slice(b"BB")
            .into_script();
        let tx = Transaction {
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
            output: vec![TxOut {
                value: Amount::ZERO,
                script_pubkey: script,
            }],
        };
        assert!(matches!(extract_message(&tx), Extracted::Unsupported(_)));
    }

    #[test]
    fn extra_bare_multisig_data_output_is_refused() {
        // A benign OP_RETURN the client would "verify", plus a hidden bare-multisig
        // data output consensus would concatenate with it. Consensus reads the
        // first "pubkey"'s inner 31 bytes as `[len, CNTRPRTY, payload]` after RC4,
        // so the client must refuse rather than verify only the OP_RETURN.
        use bitcoin::blockdata::script::Builder;
        use bitcoin::opcodes::all::{OP_CHECKMULTISIG, OP_PUSHNUM_1, OP_PUSHNUM_2};
        use bitcoin::script::PushBytes;

        let key = [0x33u8; 32];
        let mut internal = key;
        internal.reverse();
        let txid = Txid::from_byte_array(internal);

        let mut op_return_payload = PREFIX.to_vec();
        op_return_payload.extend_from_slice(b"\x02benign-enhanced-send");
        arc4::decrypt(&key, &mut op_return_payload);
        let op_return_push = bitcoin::script::PushBytesBuf::try_from(op_return_payload).unwrap();

        let hidden = b"\x04hidden-sweep";
        let mut plain = vec![(PREFIX.len() + hidden.len()) as u8];
        plain.extend_from_slice(PREFIX);
        plain.extend_from_slice(hidden);
        plain.resize(31, 0); // one multisig data chunk carries 31 bytes
        let mut obf = plain;
        arc4::decrypt(&key, &mut obf); // symmetric obfuscation

        let mut pk1 = vec![0x02u8]; // sign byte + 31 data bytes + nonce byte
        pk1.extend_from_slice(&obf);
        pk1.push(0x00);
        let pk2 = [0x02u8; 33]; // second "pubkey": no data (dropped by consensus)

        let multisig = Builder::new()
            .push_opcode(OP_PUSHNUM_1)
            .push_slice(<&PushBytes>::try_from(pk1.as_slice()).unwrap())
            .push_slice(<&PushBytes>::try_from(pk2.as_slice()).unwrap())
            .push_opcode(OP_PUSHNUM_2)
            .push_opcode(OP_CHECKMULTISIG)
            .into_script();

        let tx = Transaction {
            version: Version::TWO,
            lock_time: LockTime::ZERO,
            input: vec![TxIn {
                previous_output: OutPoint { txid, vout: 0 },
                script_sig: ScriptBuf::new(),
                sequence: Sequence::MAX,
                witness: Witness::new(),
            }],
            output: vec![
                TxOut {
                    value: Amount::ZERO,
                    script_pubkey: ScriptBuf::new_op_return(&op_return_push),
                },
                TxOut {
                    value: Amount::from_sat(546),
                    script_pubkey: multisig,
                },
            ],
        };

        assert!(matches!(extract_message(&tx), Extracted::Unsupported(_)));
    }

    #[test]
    fn normal_p2pkh_destination_alongside_op_return_still_extracts() {
        // A P2PKH output ends in OP_CHECKSIG (like the consensus data-P2PK path),
        // but its 20-byte hash does not de-obfuscate to the CNTRPRTY prefix, so it
        // must not be mistaken for a hidden data output (no false positive).
        use bitcoin::hashes::Hash as _;

        let key = [0x44u8; 32];
        let mut internal = key;
        internal.reverse();
        let txid = Txid::from_byte_array(internal);

        let msg = b"\x02real-message";
        let mut payload = PREFIX.to_vec();
        payload.extend_from_slice(msg);
        arc4::decrypt(&key, &mut payload);
        let push = bitcoin::script::PushBytesBuf::try_from(payload).unwrap();

        let p2pkh = ScriptBuf::new_p2pkh(&bitcoin::PubkeyHash::from_byte_array([0x07; 20]));

        let tx = Transaction {
            version: Version::TWO,
            lock_time: LockTime::ZERO,
            input: vec![TxIn {
                previous_output: OutPoint { txid, vout: 0 },
                script_sig: ScriptBuf::new(),
                sequence: Sequence::MAX,
                witness: Witness::new(),
            }],
            output: vec![
                TxOut {
                    value: Amount::from_sat(546),
                    script_pubkey: p2pkh,
                },
                TxOut {
                    value: Amount::ZERO,
                    script_pubkey: ScriptBuf::new_op_return(&push),
                },
            ],
        };

        match extract_message(&tx) {
            Extracted::Message(m) => assert_eq!(m, msg),
            Extracted::Unsupported(r) => panic!("P2PKH destination wrongly flagged: {r}"),
        }
    }

    #[test]
    fn no_op_return_is_unsupported() {
        let tx = Transaction {
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
            output: vec![TxOut {
                value: Amount::from_sat(1000),
                script_pubkey: ScriptBuf::new(),
            }],
        };
        assert!(matches!(extract_message(&tx), Extracted::Unsupported(_)));
    }
}
