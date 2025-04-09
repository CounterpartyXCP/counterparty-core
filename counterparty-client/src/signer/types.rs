use std::str::FromStr;

// Re-export the WalletError to maintain compatibility
pub use crate::wallet::WalletError;

/// Type alias for Result with WalletError
pub type Result<T> = std::result::Result<T, WalletError>;

/// Represents the different types of Bitcoin addresses supported
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum AddressType {
    P2PKH,
    P2WPKH,
    P2SHP2WPKH,
    P2TR,
    P2WSH,
    Unknown,
}

impl FromStr for AddressType {
    type Err = ();

    fn from_str(s: &str) -> std::result::Result<Self, Self::Err> {
        let address_type = match s {
            "p2pkh" => Self::P2PKH,
            "p2wpkh" | "bech32" => Self::P2WPKH,
            "p2sh-p2wpkh" => Self::P2SHP2WPKH,
            "p2tr" => Self::P2TR,
            "p2wsh" => Self::P2WSH,
            _ => Self::Unknown,
        };
        Ok(address_type)
    }
}