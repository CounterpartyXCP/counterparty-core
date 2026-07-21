use bitcoin::psbt::Input as PsbtInput;
use bitcoin::secp256k1::SecretKey;
use bitcoin::sighash::SighashCache;
use bitcoin::ScriptBuf;
use bitcoin::{PublicKey, Transaction};
use std::str::FromStr;

type WalletError = crate::wallet::WalletError;
pub type Result<T> = std::result::Result<T, WalletError>;

/// Types of Bitcoin UTXO/addresses supported
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum UTXOType {
    /// Pay to Public Key Hash (legacy addresses)
    P2PKH,
    /// Pay to Script Hash
    P2SH,
    /// Pay to Witness Public Key Hash (native SegWit)
    P2WPKH,
    /// Pay to Witness Script Hash (native SegWit script)
    P2WSH,
    /// Pay to Taproot - Key Path Spending
    P2TRKPS,
    /// Pay to Taproot - Script Path Spending
    P2TRSPS,
    /// Unknown address type
    Unknown,
}

impl FromStr for UTXOType {
    type Err = ();

    fn from_str(s: &str) -> std::result::Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "p2pkh" => Ok(UTXOType::P2PKH),
            "p2sh" => Ok(UTXOType::P2SH),
            "p2wpkh" | "bech32" => Ok(UTXOType::P2WPKH),
            "p2wsh" => Ok(UTXOType::P2WSH),
            "p2tr" | "p2tr-kps" => Ok(UTXOType::P2TRKPS),
            "p2tr-sps" => Ok(UTXOType::P2TRSPS),
            _ => Ok(UTXOType::Unknown),
        }
    }
}

/// UTXO (Unspent Transaction Output) represents a spendable output
#[derive(Debug, Clone)]
pub struct UTXO {
    /// Amount in satoshis
    pub amount: u64,
    /// Script public key (determines the address type)
    pub script_pubkey: ScriptBuf,
    /// Redeem script (optional, for P2SH transactions)
    pub redeem_script: Option<ScriptBuf>,
    /// Witness script (optional, for P2WSH transactions)
    pub witness_script: Option<ScriptBuf>,
    /// Leaf script (optional, for P2TR script path spending)
    pub leaf_script: Option<ScriptBuf>,
    /// Source address (optional, for P2TR script path, the address used for signing)
    pub source_address: Option<String>,
}

impl UTXO {
    /// Creates a new UTXO with mandatory fields
    pub fn new(amount: u64, script_pubkey: ScriptBuf) -> Self {
        Self {
            amount,
            script_pubkey,
            redeem_script: None,
            witness_script: None,
            leaf_script: None,
            source_address: None,
        }
    }

    /// Determines the type of UTXO based on its properties
    pub fn get_type(&self) -> UTXOType {
        if self.leaf_script.is_some() && self.source_address.is_some() {
            return UTXOType::P2TRSPS;
        }

        if self.script_pubkey.is_p2tr() {
            return UTXOType::P2TRKPS;
        }

        if self.witness_script.is_some() {
            return UTXOType::P2WSH;
        }

        if self.redeem_script.is_some() {
            return UTXOType::P2SH;
        }

        if self.script_pubkey.is_p2wpkh() {
            return UTXOType::P2WPKH;
        }

        if self.script_pubkey.is_p2pkh() {
            return UTXOType::P2PKH;
        }

        UTXOType::Unknown
    }
}

/// A collection of UTXOs for signing
#[derive(Debug, Clone)]
pub struct UTXOList(pub Vec<UTXO>);

impl UTXOList {
    /// Creates a new empty UTXO list
    pub fn new() -> Self {
        Self(Vec::new())
    }

    /// Adds a UTXO to the list
    pub fn add(&mut self, utxo: UTXO) {
        self.0.push(utxo);
    }

    /// Returns the number of UTXOs in the list
    pub fn len(&self) -> usize {
        self.0.len()
    }

    /// Gets a UTXO at the specified index
    pub fn get(&self, index: usize) -> Option<&UTXO> {
        self.0.get(index)
    }
}

impl From<Vec<UTXO>> for UTXOList {
    fn from(utxos: Vec<UTXO>) -> Self {
        Self(utxos)
    }
}

impl AsRef<[UTXO]> for UTXOList {
    fn as_ref(&self) -> &[UTXO] {
        &self.0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn keys(
        seed: u8,
    ) -> (
        bitcoin::PublicKey,
        bitcoin::secp256k1::Secp256k1<bitcoin::secp256k1::All>,
    ) {
        let secp = bitcoin::secp256k1::Secp256k1::new();
        let sk = bitcoin::secp256k1::SecretKey::from_slice(&[seed; 32]).unwrap();
        let pk = bitcoin::PrivateKey::new(sk, bitcoin::Network::Regtest);
        (bitcoin::PublicKey::from_private_key(&secp, &pk), secp)
    }

    fn p2wpkh_spk(seed: u8) -> ScriptBuf {
        let (public, _) = keys(seed);
        let cpk = bitcoin::CompressedPublicKey::from_slice(&public.to_bytes()).unwrap();
        bitcoin::Address::p2wpkh(&cpk, bitcoin::Network::Regtest).script_pubkey()
    }

    fn p2pkh_spk(seed: u8) -> ScriptBuf {
        let (public, _) = keys(seed);
        bitcoin::Address::p2pkh(public, bitcoin::Network::Regtest).script_pubkey()
    }

    fn p2tr_spk(seed: u8) -> ScriptBuf {
        let (public, secp) = keys(seed);
        let (xonly, _) = public.inner.x_only_public_key();
        bitcoin::Address::p2tr(&secp, xonly, None, bitcoin::Network::Regtest).script_pubkey()
    }

    #[test]
    fn from_str_maps_every_alias_and_defaults_to_unknown() {
        assert_eq!(UTXOType::from_str("p2pkh").unwrap(), UTXOType::P2PKH);
        assert_eq!(UTXOType::from_str("P2PKH").unwrap(), UTXOType::P2PKH);
        assert_eq!(UTXOType::from_str("p2sh").unwrap(), UTXOType::P2SH);
        assert_eq!(UTXOType::from_str("p2wpkh").unwrap(), UTXOType::P2WPKH);
        assert_eq!(UTXOType::from_str("bech32").unwrap(), UTXOType::P2WPKH);
        assert_eq!(UTXOType::from_str("p2wsh").unwrap(), UTXOType::P2WSH);
        assert_eq!(UTXOType::from_str("p2tr").unwrap(), UTXOType::P2TRKPS);
        assert_eq!(UTXOType::from_str("p2tr-kps").unwrap(), UTXOType::P2TRKPS);
        assert_eq!(UTXOType::from_str("p2tr-sps").unwrap(), UTXOType::P2TRSPS);
        assert_eq!(UTXOType::from_str("nonsense").unwrap(), UTXOType::Unknown);
    }

    #[test]
    fn get_type_classifies_by_script_and_optional_fields() {
        // Native script types inferred from the scriptPubKey.
        assert_eq!(UTXO::new(1, p2wpkh_spk(1)).get_type(), UTXOType::P2WPKH);
        assert_eq!(UTXO::new(1, p2pkh_spk(2)).get_type(), UTXOType::P2PKH);
        assert_eq!(UTXO::new(1, p2tr_spk(3)).get_type(), UTXOType::P2TRKPS);

        // A witness_script forces P2WSH regardless of the scriptPubKey.
        let mut wsh = UTXO::new(1, p2wpkh_spk(4));
        wsh.witness_script = Some(ScriptBuf::new());
        assert_eq!(wsh.get_type(), UTXOType::P2WSH);

        // A redeem_script (without a witness_script) forces P2SH.
        let mut sh = UTXO::new(1, p2pkh_spk(5));
        sh.redeem_script = Some(ScriptBuf::new());
        assert_eq!(sh.get_type(), UTXOType::P2SH);

        // leaf_script + source_address => taproot script path.
        let mut sps = UTXO::new(1, p2tr_spk(6));
        sps.leaf_script = Some(ScriptBuf::new());
        sps.source_address = Some("bcrt1p...".to_string());
        assert_eq!(sps.get_type(), UTXOType::P2TRSPS);

        // An unrecognised scriptPubKey is Unknown.
        assert_eq!(
            UTXO::new(1, ScriptBuf::from_bytes(vec![0x51])).get_type(),
            UTXOType::Unknown
        );
    }

    #[test]
    fn utxolist_new_add_get_and_conversions() {
        let mut list = UTXOList::new();
        assert_eq!(list.len(), 0);
        assert!(list.get(0).is_none());

        list.add(UTXO::new(100, p2wpkh_spk(1)));
        assert_eq!(list.len(), 1);
        assert_eq!(list.get(0).unwrap().amount, 100);
        assert!(list.get(1).is_none());

        // From<Vec<UTXO>> and AsRef<[UTXO]>.
        let from_vec: UTXOList = vec![UTXO::new(5, p2pkh_spk(2))].into();
        let slice: &[UTXO] = from_vec.as_ref();
        assert_eq!(slice.len(), 1);
        assert_eq!(slice[0].amount, 5);
    }
}

/// Trait for implementation of various transaction input signers
/// This provides a common interface for all address types
pub trait InputSigner {
    /// Sign a specific input in a PSBT
    fn sign_input(
        sighash_cache: &mut SighashCache<&Transaction>,
        input: &mut PsbtInput,
        input_index: usize,
        secret_key: &SecretKey,
        public_key: &PublicKey,
        utxo: &UTXO,
    ) -> Result<()>;
}
