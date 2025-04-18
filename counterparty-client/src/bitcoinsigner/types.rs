use bitcoin::ScriptBuf;
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

    /// Creates a P2SH UTXO
    pub fn new_p2sh(amount: u64, script_pubkey: ScriptBuf, redeem_script: ScriptBuf) -> Self {
        Self {
            amount,
            script_pubkey,
            redeem_script: Some(redeem_script),
            witness_script: None,
            leaf_script: None,
            source_address: None,
        }
    }

    /// Creates a P2WSH UTXO
    pub fn new_p2wsh(amount: u64, script_pubkey: ScriptBuf, witness_script: ScriptBuf) -> Self {
        Self {
            amount,
            script_pubkey,
            redeem_script: None,
            witness_script: Some(witness_script),
            leaf_script: None,
            source_address: None,
        }
    }

    /// Creates a P2TR script path spending UTXO
    pub fn new_p2tr_sps(
        amount: u64,
        script_pubkey: ScriptBuf,
        leaf_script: ScriptBuf,
        source_address: String,
    ) -> Self {
        Self {
            amount,
            script_pubkey,
            redeem_script: None,
            witness_script: None,
            leaf_script: Some(leaf_script),
            source_address: Some(source_address),
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

    /// Creates a UTXO list from a vector of UTXOs
    pub fn from_vec(utxos: Vec<UTXO>) -> Self {
        Self(utxos)
    }

    /// Adds a UTXO to the list
    pub fn add(&mut self, utxo: UTXO) {
        self.0.push(utxo);
    }

    /// Returns the number of UTXOs in the list
    pub fn len(&self) -> usize {
        self.0.len()
    }

    /// Checks if the list is empty
    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
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
