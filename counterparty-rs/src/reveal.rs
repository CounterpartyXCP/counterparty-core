//! Source authorization of inscription "reveal" transactions
//! (protocol change `require_reveal_source_signature`).
//!
//! A Counterparty message carried by a taproot envelope is published in two
//! steps: a *commit* transaction pays a P2TR output whose script tree holds the
//! envelope leaf, and a *reveal* transaction spends that output through the
//! leaf. The parser recognises the reveal by shape alone (an `OP_RETURN
//! CNTRPRTY` output plus a three-element witness on input 0) and attributes the
//! message to the address that funded the commit -- one hop further back than an
//! ordinary input.
//!
//! Nothing in that attribution used to prove the funder had anything to do with
//! the envelope. Anyone can hand out a P2TR address whose hidden leaf carries a
//! `sweep`; whoever pays plain BTC to it becomes the "source" of that sweep as
//! soon as the address' author spends the payment in a reveal
//! (GHSA-q27c-r246-f6qw). A P2WSH output with a three-element witness worked
//! the same way, without any real signature at all.
//!
//! This module makes Bitcoin's own script validation carry the proof of consent.
//! A reveal is accepted only when
//!
//! 1. the output it spends is a P2TR output,
//! 2. its witness is a tapscript spend of that output -- the control block
//!    commits the leaf to the output key under leaf version `0xc0`, so unknown
//!    leaf versions (which succeed without executing anything) are out,
//! 3. the leaf is a *canonical* envelope: `OP_FALSE OP_IF <pushes only> OP_ENDIF
//!    <32-byte key> OP_CHECKSIG` and nothing else, so no `OP_SUCCESSx` can
//!    short-circuit the `OP_CHECKSIG` and no unknown-key-type rule can turn it
//!    into a no-op, and
//! 4. that 32-byte key is a key of the source address itself.
//!
//! Under 1-3 the transaction can only be valid if `OP_CHECKSIG` ran with a
//! genuine Schnorr signature by the leaf key over this very transaction. Under 4
//! that key belongs to the source, so the source signed the message. The
//! `SIGHASH` flag of that signature is checked separately by
//! `gettxinfo.check_signatures_sighash_flag`.
//!
//! The rule is evaluated by the Python parser (`gettxinfo.py`) through the pyo3
//! wrapper in `utils.rs`; this module is deliberately pure so that every node
//! computes it from the same three byte strings and nothing else.

use std::fmt;

use bitcoin::hashes::{hash160, Hash};
use bitcoin::key::{Secp256k1, TapTweak, Verification, XOnlyPublicKey};
use bitcoin::opcodes::all::{OP_CHECKSIG, OP_ENDIF, OP_IF};
use bitcoin::script::{Instruction, Script};
use bitcoin::secp256k1::Parity;
use bitcoin::taproot::{ControlBlock, LeafVersion};

/// Why a reveal transaction is *not* provably signed by its source.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum RevealError {
    /// The witness of input 0 is not `<signature> <leaf script> <control block>`.
    WitnessShape(usize),
    /// The output the reveal spends is not a P2TR output.
    CommitNotP2tr,
    /// The P2TR output key is not a valid x-only public key.
    InvalidCommitKey,
    /// The last witness element does not decode as a taproot control block.
    InvalidControlBlock,
    /// The control block uses a leaf version other than `0xc0` (tapscript).
    LeafVersion(u8),
    /// The control block does not commit the leaf script to the output key.
    CommitmentMismatch,
    /// The leaf script is not a canonical envelope.
    NotAnEnvelope(&'static str),
    /// The 32 bytes before `OP_CHECKSIG` are not a valid x-only public key.
    InvalidLeafKey,
    /// The leaf key is not a key of the source address.
    SourceKeyMismatch,
}

impl fmt::Display for RevealError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            RevealError::WitnessShape(n) => write!(
                f,
                "witness has {} elements, a tapscript reveal has exactly 3",
                n
            ),
            RevealError::CommitNotP2tr => write!(f, "the spent commit output is not P2TR"),
            RevealError::InvalidCommitKey => write!(f, "invalid P2TR output key"),
            RevealError::InvalidControlBlock => write!(f, "invalid taproot control block"),
            RevealError::LeafVersion(v) => {
                write!(f, "unsupported taproot leaf version 0x{:02x}", v)
            }
            RevealError::CommitmentMismatch => {
                write!(
                    f,
                    "control block does not commit the leaf to the output key"
                )
            }
            RevealError::NotAnEnvelope(reason) => {
                write!(f, "leaf is not a canonical envelope ({})", reason)
            }
            RevealError::InvalidLeafKey => write!(f, "invalid envelope public key"),
            RevealError::SourceKeyMismatch => {
                write!(f, "envelope key does not belong to the source address")
            }
        }
    }
}

impl std::error::Error for RevealError {}

/// Checks that Bitcoin consensus guarantees `witness` (input 0 of a reveal
/// transaction spending `commit_script_pubkey`) carries a signature by a key of
/// the address whose scriptPubKey is `source_script_pubkey`.
///
/// Pure and total: every failure is reported as a [`RevealError`], never as a
/// panic, whatever the three byte strings contain.
pub fn check_reveal_source_signature(
    commit_script_pubkey: &[u8],
    source_script_pubkey: &[u8],
    witness: &[Vec<u8>],
) -> Result<(), RevealError> {
    if witness.len() != 3 {
        return Err(RevealError::WitnessShape(witness.len()));
    }

    // 1. The reveal spends a P2TR output: `OP_1 <32-byte output key>`.
    let commit_script = Script::from_bytes(commit_script_pubkey);
    if !commit_script.is_p2tr() {
        return Err(RevealError::CommitNotP2tr);
    }
    let output_key = XOnlyPublicKey::from_slice(&commit_script_pubkey[2..34])
        .map_err(|_| RevealError::InvalidCommitKey)?;

    // 2. The witness is a tapscript (leaf version 0xc0) spend of that output.
    //    `ControlBlock::decode` enforces the `33 + 32m` length, so a P2WSH
    //    witness script or an annex in this position is rejected here.
    let control_block =
        ControlBlock::decode(&witness[2]).map_err(|_| RevealError::InvalidControlBlock)?;
    if control_block.leaf_version != LeafVersion::TapScript {
        return Err(RevealError::LeafVersion(
            control_block.leaf_version.to_consensus(),
        ));
    }
    let leaf_script = Script::from_bytes(&witness[1]);
    let secp = Secp256k1::verification_only();
    if !control_block.verify_taproot_commitment(&secp, output_key, leaf_script) {
        return Err(RevealError::CommitmentMismatch);
    }

    // 3. The leaf is a canonical envelope ending in `<key> OP_CHECKSIG`.
    let leaf_key = envelope_leaf_key(leaf_script)?;

    // 4. That key is a key of the source address.
    if !source_controls_key(&secp, Script::from_bytes(source_script_pubkey), &leaf_key) {
        return Err(RevealError::SourceKeyMismatch);
    }
    Ok(())
}

/// `OP_1NEGATE` and `OP_1`..`OP_16`: the only non-data opcodes allowed inside
/// the envelope. They only push a number and none of them is an `OP_SUCCESSx`.
fn is_pushnum(opcode: bitcoin::Opcode) -> bool {
    let byte = opcode.to_u8();
    byte == 0x4f || (0x51..=0x60).contains(&byte)
}

/// Returns the key of a canonical envelope leaf:
/// `OP_FALSE OP_IF <push-only body> OP_ENDIF <32-byte key> OP_CHECKSIG`.
///
/// Stricter than the data extraction in `indexer/bitcoin_client.rs` on purpose.
/// With tapscript, an `OP_SUCCESSx` anywhere in the leaf -- even inside the
/// never-executed `OP_IF` branch -- makes the spend valid without running
/// `OP_CHECKSIG`, an `OP_CHECKSIG` on a key that is not 32 bytes long succeeds
/// with any non-empty signature, and anything after `OP_CHECKSIG` could discard
/// its result. Only the exact shape below lets Bitcoin's validation stand in for
/// a signature check by the leaf key.
fn envelope_leaf_key(script: &Script) -> Result<XOnlyPublicKey, RevealError> {
    let mut instructions = script.instructions();

    // OP_FALSE / OP_0 is decoded as an empty push.
    match instructions.next() {
        Some(Ok(Instruction::PushBytes(push))) if push.is_empty() => {}
        _ => return Err(RevealError::NotAnEnvelope("must start with OP_FALSE")),
    }
    match instructions.next() {
        Some(Ok(Instruction::Op(OP_IF))) => {}
        _ => {
            return Err(RevealError::NotAnEnvelope(
                "OP_FALSE must be followed by OP_IF",
            ))
        }
    }
    loop {
        match instructions.next() {
            Some(Ok(Instruction::PushBytes(_))) => {}
            Some(Ok(Instruction::Op(OP_ENDIF))) => break,
            Some(Ok(Instruction::Op(opcode))) if is_pushnum(opcode) => {}
            Some(Ok(Instruction::Op(_))) => {
                return Err(RevealError::NotAnEnvelope(
                    "non-push opcode inside the envelope",
                ))
            }
            Some(Err(_)) => return Err(RevealError::NotAnEnvelope("unparsable script")),
            None => return Err(RevealError::NotAnEnvelope("missing OP_ENDIF")),
        }
    }
    let key = match instructions.next() {
        Some(Ok(Instruction::PushBytes(push))) if push.len() == 32 => {
            XOnlyPublicKey::from_slice(push.as_bytes()).map_err(|_| RevealError::InvalidLeafKey)?
        }
        _ => {
            return Err(RevealError::NotAnEnvelope(
                "OP_ENDIF must be followed by a 32-byte key",
            ))
        }
    };
    match instructions.next() {
        Some(Ok(Instruction::Op(OP_CHECKSIG))) => {}
        _ => {
            return Err(RevealError::NotAnEnvelope(
                "key must be followed by OP_CHECKSIG",
            ))
        }
    }
    if instructions.next().is_some() {
        return Err(RevealError::NotAnEnvelope(
            "trailing bytes after OP_CHECKSIG",
        ));
    }
    Ok(key)
}

/// Whether `key` is a key of the address `source` (the output that funded the
/// commit transaction).
///
/// The envelope holds an x-only key, so both parities of the corresponding
/// compressed key are tried. Accepted source types and the keys they accept:
///
/// * P2TR: the output key itself, or an internal key whose BIP86 (no script
///   tree) tweak is the output key -- a wallet may sign the leaf with either;
/// * P2WPKH: the compressed key hashing to the witness program;
/// * P2SH-P2WPKH: the compressed key whose nested P2WPKH hashes to the script;
/// * P2PKH: the compressed or uncompressed key hashing to the pubkey hash.
///
/// Every other kind of source (bare multisig, P2WSH, P2SH scripts, ...) has no
/// single key that could have consented and never authorizes a reveal.
fn source_controls_key<C: Verification>(
    secp: &Secp256k1<C>,
    source: &Script,
    key: &XOnlyPublicKey,
) -> bool {
    let bytes = source.as_bytes();
    let compressed = [
        key.public_key(Parity::Even).serialize(),
        key.public_key(Parity::Odd).serialize(),
    ];

    if source.is_p2tr() {
        let output_key = &bytes[2..34];
        if key.serialize() == output_key {
            return true;
        }
        let (tweaked, _parity) = key.tap_tweak(secp, None);
        return tweaked.serialize() == output_key;
    }
    if source.is_p2wpkh() {
        let program = &bytes[2..22];
        return compressed
            .iter()
            .any(|pubkey| hash160::Hash::hash(pubkey).as_byte_array() == program);
    }
    if source.is_p2pkh() {
        let pubkey_hash = &bytes[3..23];
        let uncompressed = [
            key.public_key(Parity::Even).serialize_uncompressed(),
            key.public_key(Parity::Odd).serialize_uncompressed(),
        ];
        return compressed
            .iter()
            .any(|pubkey| hash160::Hash::hash(pubkey).as_byte_array() == pubkey_hash)
            || uncompressed
                .iter()
                .any(|pubkey| hash160::Hash::hash(pubkey).as_byte_array() == pubkey_hash);
    }
    if source.is_p2sh() {
        let script_hash = &bytes[2..22];
        return compressed.iter().any(|pubkey| {
            // redeem script of a nested P2WPKH: OP_0 <20-byte pubkey hash>
            let mut redeem_script = vec![0x00, 0x14];
            redeem_script.extend_from_slice(hash160::Hash::hash(pubkey).as_byte_array());
            hash160::Hash::hash(&redeem_script).as_byte_array() == script_hash
        });
    }
    false
}

#[cfg(test)]
#[allow(clippy::unwrap_used)]
mod tests {
    use super::*;
    use bitcoin::key::{Keypair, PublicKey, Secp256k1, TapTweak, XOnlyPublicKey};
    use bitcoin::opcodes::all::{
        OP_CAT, OP_CHECKSIG, OP_CHECKSIGVERIFY, OP_DROP, OP_ENDIF, OP_IF, OP_NOP, OP_RESERVED,
    };
    use bitcoin::opcodes::OP_FALSE;
    use bitcoin::script::{Builder, PushBytesBuf, ScriptBuf};
    use bitcoin::secp256k1::{All, SecretKey};
    use bitcoin::taproot::{LeafVersion, TaprootBuilder};
    use bitcoin::CompressedPublicKey;

    struct Key {
        xonly: XOnlyPublicKey,
        compressed: CompressedPublicKey,
    }

    fn key(seed: u8) -> Key {
        let secp = Secp256k1::new();
        let secret = SecretKey::from_slice(&[seed; 32]).unwrap();
        let keypair = Keypair::from_secret_key(&secp, &secret);
        Key {
            xonly: XOnlyPublicKey::from_keypair(&keypair).0,
            compressed: CompressedPublicKey(keypair.public_key()),
        }
    }

    fn secp() -> Secp256k1<All> {
        Secp256k1::new()
    }

    fn push(builder: Builder, data: &[u8]) -> Builder {
        builder.push_slice(PushBytesBuf::try_from(data.to_vec()).unwrap())
    }

    fn envelope_body(builder: Builder) -> Builder {
        push(builder, b"some counterparty message")
    }

    /// `OP_FALSE OP_IF <data> OP_ENDIF <key> OP_CHECKSIG`
    fn envelope(leaf_key: &XOnlyPublicKey) -> ScriptBuf {
        let builder = Builder::new().push_opcode(OP_FALSE).push_opcode(OP_IF);
        envelope_body(builder)
            .push_opcode(OP_ENDIF)
            .push_slice(leaf_key.serialize())
            .push_opcode(OP_CHECKSIG)
            .into_script()
    }

    /// `ord`-style envelope with tags pushed both as data and as OP_PUSHNUM.
    fn ord_envelope(leaf_key: &XOnlyPublicKey) -> ScriptBuf {
        let builder = Builder::new().push_opcode(OP_FALSE).push_opcode(OP_IF);
        let builder = push(builder, b"ord");
        let builder = push(builder, &[0x07]);
        let builder = push(builder, b"xcp");
        let builder = builder.push_int(1);
        let builder = push(builder, b"text/plain");
        let builder = push(builder, &[0x05]);
        let builder = push(builder, &[0xa1, 0x01, 0x02]);
        let builder = builder.push_opcode(OP_FALSE);
        let builder = push(builder, b"hello");
        builder
            .push_opcode(OP_ENDIF)
            .push_slice(leaf_key.serialize())
            .push_opcode(OP_CHECKSIG)
            .into_script()
    }

    /// Commit output and control block of a single-leaf tree.
    fn commit(internal_key: &XOnlyPublicKey, leaf: &ScriptBuf) -> (Vec<u8>, Vec<u8>) {
        commit_with_version(internal_key, leaf, LeafVersion::TapScript)
    }

    fn commit_with_version(
        internal_key: &XOnlyPublicKey,
        leaf: &ScriptBuf,
        version: LeafVersion,
    ) -> (Vec<u8>, Vec<u8>) {
        let spend_info = TaprootBuilder::new()
            .add_leaf_with_ver(0, leaf.clone(), version)
            .unwrap()
            .finalize(&secp(), *internal_key)
            .unwrap();
        let script_pubkey = ScriptBuf::new_p2tr_tweaked(spend_info.output_key());
        let control_block = spend_info
            .control_block(&(leaf.clone(), version))
            .unwrap()
            .serialize();
        (script_pubkey.into_bytes(), control_block)
    }

    fn witness(leaf: &ScriptBuf, control_block: &[u8]) -> Vec<Vec<u8>> {
        vec![vec![0x01; 64], leaf.to_bytes(), control_block.to_vec()]
    }

    fn p2wpkh(key: &Key) -> Vec<u8> {
        ScriptBuf::new_p2wpkh(&key.compressed.wpubkey_hash()).into_bytes()
    }

    fn p2tr_bip86(key: &Key) -> Vec<u8> {
        ScriptBuf::new_p2tr(&secp(), key.xonly, None).into_bytes()
    }

    fn p2pkh_compressed(key: &Key) -> Vec<u8> {
        ScriptBuf::new_p2pkh(&PublicKey::from(key.compressed).pubkey_hash()).into_bytes()
    }

    fn p2pkh_uncompressed(key: &Key) -> Vec<u8> {
        let uncompressed = PublicKey::new_uncompressed(key.compressed.0);
        ScriptBuf::new_p2pkh(&uncompressed.pubkey_hash()).into_bytes()
    }

    fn p2sh_p2wpkh(key: &Key) -> Vec<u8> {
        let redeem = ScriptBuf::new_p2wpkh(&key.compressed.wpubkey_hash());
        ScriptBuf::new_p2sh(&redeem.script_hash()).into_bytes()
    }

    /// The honest flow: the source's own key in the leaf, single-leaf commit.
    fn honest(source_spk: Vec<u8>, source: &Key) -> Result<(), RevealError> {
        let leaf = envelope(&source.xonly);
        let (commit_spk, control_block) = commit(&source.xonly, &leaf);
        check_reveal_source_signature(&commit_spk, &source_spk, &witness(&leaf, &control_block))
    }

    #[test]
    fn accepts_p2wpkh_source_signing_with_its_key() {
        for seed in 1..=8u8 {
            // both key parities occur across these seeds
            let source = key(seed);
            assert_eq!(honest(p2wpkh(&source), &source), Ok(()), "seed {}", seed);
        }
    }

    #[test]
    fn accepts_p2tr_source_signing_with_internal_or_output_key() {
        let source = key(3);
        // internal (untweaked) key in the leaf
        assert_eq!(honest(p2tr_bip86(&source), &source), Ok(()));
        // tweaked output key in the leaf
        let (output_key, _) = source.xonly.tap_tweak(&secp(), None);
        let output_key = output_key.to_inner();
        let leaf = envelope(&output_key);
        let (commit_spk, control_block) = commit(&output_key, &leaf);
        assert_eq!(
            check_reveal_source_signature(
                &commit_spk,
                &p2tr_bip86(&source),
                &witness(&leaf, &control_block)
            ),
            Ok(())
        );
    }

    #[test]
    fn accepts_p2pkh_and_nested_p2wpkh_sources() {
        let source = key(4);
        assert_eq!(honest(p2pkh_compressed(&source), &source), Ok(()));
        assert_eq!(honest(p2pkh_uncompressed(&source), &source), Ok(()));
        assert_eq!(honest(p2sh_p2wpkh(&source), &source), Ok(()));
    }

    #[test]
    fn accepts_ord_style_envelopes() {
        let source = key(5);
        let leaf = ord_envelope(&source.xonly);
        let (commit_spk, control_block) = commit(&source.xonly, &leaf);
        assert_eq!(
            check_reveal_source_signature(
                &commit_spk,
                &p2wpkh(&source),
                &witness(&leaf, &control_block)
            ),
            Ok(())
        );
    }

    #[test]
    fn accepts_a_commit_whose_internal_key_is_not_the_source_key() {
        // Only the leaf key must be the source's: the internal key is the
        // committer's business (it merely decides who can key-path spend).
        let source = key(6);
        let other = key(7);
        let leaf = envelope(&source.xonly);
        let (commit_spk, control_block) = commit(&other.xonly, &leaf);
        assert_eq!(
            check_reveal_source_signature(
                &commit_spk,
                &p2wpkh(&source),
                &witness(&leaf, &control_block)
            ),
            Ok(())
        );
    }

    #[test]
    fn rejects_the_reported_attack_p2tr_leaf_with_the_attacker_key() {
        // GHSA-q27c-r246-f6qw case A: the attacker publishes a commit address
        // whose leaf holds *their* key; the victim pays it; the attacker reveals.
        let victim = key(10);
        let attacker = key(11);
        let leaf = envelope(&attacker.xonly);
        let (commit_spk, control_block) = commit(&attacker.xonly, &leaf);
        assert_eq!(
            check_reveal_source_signature(
                &commit_spk,
                &p2wpkh(&victim),
                &witness(&leaf, &control_block)
            ),
            Err(RevealError::SourceKeyMismatch)
        );
        assert_eq!(
            check_reveal_source_signature(
                &commit_spk,
                &p2tr_bip86(&victim),
                &witness(&leaf, &control_block)
            ),
            Err(RevealError::SourceKeyMismatch)
        );
    }

    #[test]
    fn rejects_the_reported_attack_p2wsh_commit() {
        // GHSA-q27c-r246-f6qw case B: a P2WSH output whose witness script is
        // `OP_2DROP OP_1`, spent with witness [<64 bytes>, <envelope>, 6d51].
        let victim = key(10);
        let witness_script = ScriptBuf::from_bytes(vec![0x6d, 0x51]);
        let commit_spk = ScriptBuf::new_p2wsh(&witness_script.wscript_hash()).into_bytes();
        let leaf = envelope(&victim.xonly); // even the victim's own key does not help
        let witness = vec![vec![0x01; 64], leaf.to_bytes(), vec![0x6d, 0x51]];
        assert_eq!(
            check_reveal_source_signature(&commit_spk, &p2wpkh(&victim), &witness),
            Err(RevealError::CommitNotP2tr)
        );
    }

    #[test]
    fn rejects_a_witness_that_is_not_a_three_element_script_path() {
        let source = key(12);
        let leaf = envelope(&source.xonly);
        let (commit_spk, control_block) = commit(&source.xonly, &leaf);
        let mut with_annex = witness(&leaf, &control_block);
        with_annex.push(vec![0x50]);
        assert_eq!(
            check_reveal_source_signature(&commit_spk, &p2wpkh(&source), &with_annex),
            Err(RevealError::WitnessShape(4))
        );
        assert_eq!(
            check_reveal_source_signature(&commit_spk, &p2wpkh(&source), &[vec![0x01; 64]]),
            Err(RevealError::WitnessShape(1))
        );
        assert_eq!(
            check_reveal_source_signature(&commit_spk, &p2wpkh(&source), &[]),
            Err(RevealError::WitnessShape(0))
        );
    }

    #[test]
    fn rejects_unknown_leaf_versions() {
        // An unknown leaf version makes the spend valid without executing the
        // leaf, so the victim's key in it would prove nothing.
        let victim = key(13);
        let leaf = envelope(&victim.xonly);
        let version = LeafVersion::from_consensus(0xc2).unwrap();
        let (commit_spk, control_block) = commit_with_version(&victim.xonly, &leaf, version);
        assert_eq!(
            check_reveal_source_signature(
                &commit_spk,
                &p2wpkh(&victim),
                &witness(&leaf, &control_block)
            ),
            Err(RevealError::LeafVersion(0xc2))
        );
    }

    #[test]
    fn rejects_a_control_block_that_does_not_commit_the_leaf() {
        let source = key(14);
        let leaf = envelope(&source.xonly);
        let (commit_spk, _) = commit(&source.xonly, &leaf);
        // control block of the same leaf under a *different* internal key: the
        // tweak lands on another output key
        let (_, other_control_block) = commit(&key(15).xonly, &leaf);
        assert_eq!(
            check_reveal_source_signature(
                &commit_spk,
                &p2wpkh(&source),
                &witness(&leaf, &other_control_block)
            ),
            Err(RevealError::CommitmentMismatch)
        );
        // a leaf the commit does not hold, presented with the commit's own
        // control block
        let other_leaf = envelope(&key(15).xonly);
        let (_, control_block) = commit(&source.xonly, &leaf);
        assert_eq!(
            check_reveal_source_signature(
                &commit_spk,
                &p2wpkh(&source),
                &witness(&other_leaf, &control_block)
            ),
            Err(RevealError::CommitmentMismatch)
        );
        // garbage where the control block should be
        assert_eq!(
            check_reveal_source_signature(
                &commit_spk,
                &p2wpkh(&source),
                &witness(&leaf, &[0xc0; 40])
            ),
            Err(RevealError::InvalidControlBlock)
        );
    }

    #[test]
    fn rejects_an_invalid_output_key() {
        let source = key(16);
        let leaf = envelope(&source.xonly);
        let (_, control_block) = commit(&source.xonly, &leaf);
        // x = 0 is not on the curve
        let mut commit_spk = vec![0x51, 0x20];
        commit_spk.extend_from_slice(&[0u8; 32]);
        assert_eq!(
            check_reveal_source_signature(
                &commit_spk,
                &p2wpkh(&source),
                &witness(&leaf, &control_block)
            ),
            Err(RevealError::InvalidCommitKey)
        );
    }

    /// Runs the check on a leaf the commit genuinely commits to, so that only
    /// the envelope rule can fail.
    fn check_leaf(source: &Key, leaf: ScriptBuf) -> Result<(), RevealError> {
        let (commit_spk, control_block) = commit(&source.xonly, &leaf);
        check_reveal_source_signature(
            &commit_spk,
            &p2wpkh(source),
            &witness(&leaf, &control_block),
        )
    }

    #[test]
    fn rejects_op_success_inside_the_envelope() {
        // OP_SUCCESSx anywhere in the leaf validates the spend without running
        // OP_CHECKSIG, so the victim's key at the end would be decorative.
        let victim = key(17);
        for success_opcode in [OP_RESERVED, OP_CAT] {
            let builder = Builder::new().push_opcode(OP_FALSE).push_opcode(OP_IF);
            let leaf = envelope_body(builder)
                .push_opcode(success_opcode)
                .push_opcode(OP_ENDIF)
                .push_slice(victim.xonly.serialize())
                .push_opcode(OP_CHECKSIG)
                .into_script();
            assert_eq!(
                check_leaf(&victim, leaf),
                Err(RevealError::NotAnEnvelope(
                    "non-push opcode inside the envelope"
                )),
                "{:?}",
                success_opcode
            );
        }
    }

    #[test]
    fn rejects_non_canonical_envelopes() {
        let victim = key(18);
        let start = || Builder::new().push_opcode(OP_FALSE).push_opcode(OP_IF);

        // OP_NOP inside the body
        let leaf = envelope_body(start())
            .push_opcode(OP_NOP)
            .push_opcode(OP_ENDIF)
            .push_slice(victim.xonly.serialize())
            .push_opcode(OP_CHECKSIG)
            .into_script();
        assert!(matches!(
            check_leaf(&victim, leaf),
            Err(RevealError::NotAnEnvelope(_))
        ));

        // nested OP_IF
        let leaf = envelope_body(start().push_opcode(OP_IF))
            .push_opcode(OP_ENDIF)
            .push_opcode(OP_ENDIF)
            .push_slice(victim.xonly.serialize())
            .push_opcode(OP_CHECKSIG)
            .into_script();
        assert!(matches!(
            check_leaf(&victim, leaf),
            Err(RevealError::NotAnEnvelope(_))
        ));

        // key that is not 32 bytes (unknown key type: OP_CHECKSIG succeeds
        // with any non-empty signature)
        let leaf = envelope_body(start())
            .push_opcode(OP_ENDIF)
            .push_slice(victim.compressed.to_bytes())
            .push_opcode(OP_CHECKSIG)
            .into_script();
        assert!(matches!(
            check_leaf(&victim, leaf),
            Err(RevealError::NotAnEnvelope(_))
        ));

        // OP_CHECKSIGVERIFY / a second key after the check / trailing opcode
        let leaf = envelope_body(start())
            .push_opcode(OP_ENDIF)
            .push_slice(victim.xonly.serialize())
            .push_opcode(OP_CHECKSIGVERIFY)
            .into_script();
        assert!(matches!(
            check_leaf(&victim, leaf),
            Err(RevealError::NotAnEnvelope(_))
        ));
        let leaf = envelope_body(start())
            .push_opcode(OP_ENDIF)
            .push_slice(key(19).xonly.serialize())
            .push_opcode(OP_CHECKSIG)
            .push_opcode(OP_DROP)
            .push_slice(victim.xonly.serialize())
            .push_opcode(OP_CHECKSIG)
            .into_script();
        assert!(matches!(
            check_leaf(&victim, leaf),
            Err(RevealError::NotAnEnvelope(_))
        ));
        let leaf = envelope_body(start())
            .push_opcode(OP_ENDIF)
            .push_slice(victim.xonly.serialize())
            .push_opcode(OP_CHECKSIG)
            .push_opcode(OP_NOP)
            .into_script();
        assert_eq!(
            check_leaf(&victim, leaf),
            Err(RevealError::NotAnEnvelope(
                "trailing bytes after OP_CHECKSIG"
            ))
        );

        // does not start with OP_FALSE OP_IF
        let leaf = Builder::new()
            .push_slice(victim.xonly.serialize())
            .push_opcode(OP_CHECKSIG)
            .into_script();
        assert!(matches!(
            check_leaf(&victim, leaf),
            Err(RevealError::NotAnEnvelope(_))
        ));

        // missing OP_ENDIF
        let leaf = envelope_body(start())
            .push_slice(victim.xonly.serialize())
            .push_opcode(OP_CHECKSIG)
            .into_script();
        assert!(matches!(
            check_leaf(&victim, leaf),
            Err(RevealError::NotAnEnvelope(_))
        ));

        // truncated push
        let mut bytes = envelope(&victim.xonly).into_bytes();
        bytes.truncate(bytes.len() - 5);
        assert!(matches!(
            check_leaf(&victim, ScriptBuf::from_bytes(bytes)),
            Err(RevealError::NotAnEnvelope(_))
        ));
    }

    #[test]
    fn rejects_sources_without_a_single_key() {
        let source = key(20);
        let leaf = envelope(&source.xonly);
        let (commit_spk, control_block) = commit(&source.xonly, &leaf);
        let witness = witness(&leaf, &control_block);

        let p2wsh = ScriptBuf::new_p2wsh(&leaf.wscript_hash()).into_bytes();
        let multisig = Builder::new()
            .push_int(1)
            .push_slice(source.compressed.to_bytes())
            .push_slice(key(21).compressed.to_bytes())
            .push_int(2)
            .push_opcode(bitcoin::opcodes::all::OP_CHECKMULTISIG)
            .into_script()
            .into_bytes();
        let p2sh_other = ScriptBuf::new_p2sh(&leaf.script_hash()).into_bytes();
        let op_return = ScriptBuf::new_op_return(b"CNTRPRTY").into_bytes();
        for source_spk in [p2wsh, multisig, p2sh_other, op_return, Vec::new()] {
            assert_eq!(
                check_reveal_source_signature(&commit_spk, &source_spk, &witness),
                Err(RevealError::SourceKeyMismatch)
            );
        }
    }

    #[test]
    fn rejects_a_different_key_of_every_supported_source_type() {
        let source = key(22);
        let other = key(23);
        let leaf = envelope(&other.xonly);
        let (commit_spk, control_block) = commit(&other.xonly, &leaf);
        let witness = witness(&leaf, &control_block);
        for source_spk in [
            p2wpkh(&source),
            p2tr_bip86(&source),
            p2pkh_compressed(&source),
            p2pkh_uncompressed(&source),
            p2sh_p2wpkh(&source),
        ] {
            assert_eq!(
                check_reveal_source_signature(&commit_spk, &source_spk, &witness),
                Err(RevealError::SourceKeyMismatch)
            );
        }
    }

    #[test]
    fn error_messages_are_informative() {
        assert_eq!(
            RevealError::LeafVersion(0xc2).to_string(),
            "unsupported taproot leaf version 0xc2"
        );
        assert_eq!(
            RevealError::WitnessShape(4).to_string(),
            "witness has 4 elements, a tapscript reveal has exactly 3"
        );
    }
}
