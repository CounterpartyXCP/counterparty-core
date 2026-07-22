//! Decoding of Counterparty's compact "packed address" form.
//!
//! Direct port of `counterparty-rs/src/utils.rs::unpack_address`, which is the
//! canonical implementation the Python `address.unpack` delegates to under the
//! `taproot_support` protocol change (the format current composes use):
//!
//! * `0x01` + 20-byte hash  → P2PKH
//! * `0x02` + 20-byte hash  → P2SH
//! * `0x03` + version + program → SegWit/Taproot witness program
//!
//! Returns the address string for `network`, or `None` if the bytes are not a
//! well-formed packed address (caller then degrades to "unverifiable").

use bitcoin::hashes::Hash;
use bitcoin::{Address, Network, PubkeyHash, ScriptHash, WitnessProgram, WitnessVersion};

/// Unpack a compact packed address into its string form for `network`.
pub fn unpack(packed: &[u8], network: Network) -> Option<String> {
    match packed.first()? {
        0x01 if packed.len() == 21 => {
            let hash = PubkeyHash::from_slice(&packed[1..]).ok()?;
            Some(Address::p2pkh(hash, network).to_string())
        }
        0x02 if packed.len() == 21 => {
            let hash = ScriptHash::from_slice(&packed[1..]).ok()?;
            Some(Address::p2sh_from_hash(hash, network).to_string())
        }
        0x03 if packed.len() >= 22 => {
            let version = WitnessVersion::try_from(packed[1]).ok()?;
            let program = WitnessProgram::new(version, &packed[2..]).ok()?;
            Some(Address::from_witness_program(program, network).to_string())
        }
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::str::FromStr;

    // Round-trip: pack a known address the same way the indexer does, then
    // confirm unpack() reproduces the canonical string.
    fn pack_roundtrip(addr: &str, network: Network) {
        let parsed = Address::from_str(addr)
            .unwrap()
            .require_network(network)
            .unwrap();
        // Mirror counterparty-rs utils::pack.
        let packed = match (
            parsed.pubkey_hash(),
            parsed.script_hash(),
            parsed.witness_program(),
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
            _ => panic!("unpackable address"),
        };
        assert_eq!(unpack(&packed, network).as_deref(), Some(addr));
    }

    #[test]
    fn unpacks_p2wpkh_bech32() {
        // BIP84 reference receive address (mainnet).
        pack_roundtrip(
            "bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu",
            Network::Bitcoin,
        );
    }

    #[test]
    fn unpacks_p2tr_bech32m() {
        // BIP86 reference receive address (mainnet).
        pack_roundtrip(
            "bc1p5cyxnuxmeuwuvkwfem96lqzszd02n6xdcjrs20cac6yqjjwudpxqkedrcr",
            Network::Bitcoin,
        );
    }

    #[test]
    fn unpacks_p2pkh_and_p2sh() {
        pack_roundtrip("1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH", Network::Bitcoin);
        pack_roundtrip("3P14159f73E4gFr7JterCCQh9QjiTjiZrG", Network::Bitcoin);
    }

    #[test]
    fn rejects_malformed() {
        assert_eq!(unpack(&[], Network::Bitcoin), None);
        assert_eq!(unpack(&[0x01, 0x00], Network::Bitcoin), None); // too short
        assert_eq!(unpack(&[0x09; 21], Network::Bitcoin), None); // unknown prefix
    }
}
