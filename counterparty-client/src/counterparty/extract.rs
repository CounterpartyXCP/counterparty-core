//! Pull the de-obfuscated Counterparty message out of a composed transaction.
//!
//! Handles the `OP_RETURN` data encoding, which is what every small payload
//! uses (`send`, `enhanced_send` and `sweep` all fit under the 80-byte
//! `OP_RETURN` limit). Bare-multisig and taproot-envelope encodings are not
//! decoded here and return [`Extracted::Unsupported`] so the caller degrades
//! safely.

use bitcoin::hashes::Hash;
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

/// Concatenate the bytes pushed by an `OP_RETURN` script (all data pushes after
/// the `OP_RETURN` opcode). Counterparty uses a single push, but concatenating
/// is robust to either shape.
fn opreturn_pushed_data(script: &Script) -> Option<Vec<u8>> {
    if !script.is_op_return() {
        return None;
    }
    let mut out = Vec::new();
    for instr in script.instructions() {
        if let Ok(Instruction::PushBytes(bytes)) = instr {
            out.extend_from_slice(bytes.as_bytes());
        }
    }
    Some(out)
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

    let Some(mut payload) = opreturn_pushed_data(&data_output.script_pubkey) else {
        return Extracted::Unsupported("malformed OP_RETURN data output");
    };

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
