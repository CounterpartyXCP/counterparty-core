//! RC4/ARC4 de-obfuscation of a Counterparty data output.
//!
//! Counterparty "encrypts" the `CNTRPRTY`-prefixed payload with RC4 keyed by the
//! **first input's txid in display byte order** (the composer uses
//! `unhexlify(txid_hex)`; the indexer uses `txid.to_byte_array()` then
//! `reverse()` — see `counterparty-rs/src/indexer/bitcoin_client.rs:699`). The
//! key is public (a txid), so this is obfuscation, not confidentiality; we only
//! need it to read the payload back. RC4 is symmetric, so the same operation
//! encrypts and decrypts.

use rc4::consts::U32;
use rc4::{Key, KeyInit, Rc4, StreamCipher};

/// De-obfuscate `data` in place with the 32-byte RC4 key (a first-input txid in
/// display byte order).
pub fn decrypt(key: &[u8; 32], data: &mut [u8]) {
    let key = Key::<U32>::from_slice(key);
    let mut cipher = Rc4::<U32>::new(key);
    cipher.apply_keystream(data);
}

#[cfg(test)]
mod tests {
    use super::*;

    // RC4 is symmetric: decrypt(decrypt(x)) == x.
    #[test]
    fn decrypt_is_its_own_inverse() {
        let key = [0x11u8; 32];
        let plain = b"CNTRPRTY\x00hello world".to_vec();
        let mut buf = plain.clone();
        decrypt(&key, &mut buf);
        assert_ne!(buf, plain, "obfuscation must change the bytes");
        decrypt(&key, &mut buf);
        assert_eq!(buf, plain, "applying RC4 twice restores the plaintext");
    }

    // Golden vector computed from a reference RC4 (the same algorithm the
    // Counterparty composer's `arc4` lib and the indexer's `rust-crypto` Rc4
    // implement). Proves this crate is byte-compatible with the server, so a
    // payload we de-obfuscate matches what was obfuscated on chain.
    #[test]
    fn matches_reference_rc4_keystream() {
        let key = [0x11u8; 32];
        let mut buf = b"CNTRPRTY\x00hello world".to_vec();
        decrypt(&key, &mut buf);
        assert_eq!(
            hex::encode(&buf),
            "cfc55b452ca4d21a213293651c504bf7478c7327"
        );
    }
}
