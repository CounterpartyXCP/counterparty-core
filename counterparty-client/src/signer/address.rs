use bitcoin::secp256k1::Secp256k1;
use bitcoin::Address;
use bitcoin::Network;
use bitcoin::PublicKey;
use bitcoin::ScriptBuf;
use std::str::FromStr;

use crate::signer::types::{AddressType, Result};
use crate::signer::utils::{get_compressed_pubkey, get_xonly_pubkey, standardize_address_type};

/// Check if a script is a P2SH-P2WPKH script
pub fn is_p2sh_p2wpkh_script(script_pubkey: &ScriptBuf) -> bool {
    if !script_pubkey.is_p2sh() {
        return false;
    }

    // Check for P2SH-P2WPKH pattern using safe iteration
    let mut iter = script_pubkey.instructions_minimal();

    // First instruction should be OP_HASH160
    if let Some(Ok(bitcoin::blockdata::script::Instruction::Op(op1))) = iter.next() {
        if op1 == bitcoin::blockdata::opcodes::all::OP_HASH160 {
            // Second instruction should be a 20-byte push
            if let Some(Ok(bitcoin::blockdata::script::Instruction::PushBytes(bytes))) = iter.next()
            {
                if bytes.len() == 20 {
                    // Third instruction should be OP_EQUAL
                    if let Some(Ok(bitcoin::blockdata::script::Instruction::Op(op2))) = iter.next()
                    {
                        if op2 == bitcoin::blockdata::opcodes::all::OP_EQUAL {
                            // No more instructions
                            if iter.next().is_none() {
                                // This confirms it's a P2SH, but we can't fully verify it's specifically P2SH-P2WPKH
                                // without the redeem script. We rely on can_sign_input to verify using the address matching.
                                return true;
                            }
                        }
                    }
                }
            }
        }
    }

    false
}

/// Determine the address type from script_pubkey
pub fn determine_address_type(script_pubkey: &ScriptBuf) -> String {
    if script_pubkey.is_p2pkh() {
        "p2pkh".to_string()
    } else if script_pubkey.is_p2wpkh() {
        "p2wpkh".to_string()
    } else if script_pubkey.is_p2sh() {
        if is_p2sh_p2wpkh_script(script_pubkey) {
            "p2sh-p2wpkh".to_string()
        } else {
            "p2sh".to_string()
        }
    } else if script_pubkey.is_p2wsh() {
        "p2wsh".to_string()
    } else if script_pubkey.is_p2tr() {
        "p2tr".to_string()
    } else {
        "unknown".to_string()
    }
}

/// Helper function to check if a script matches an expected script
pub fn script_matches(script_pubkey: &ScriptBuf, expected_script: &ScriptBuf) -> bool {
    script_pubkey == expected_script
}

/// Utility function to check if a key can sign an input by first creating the corresponding address
pub fn can_sign_with_address_creation<F>(
    script_pubkey: &ScriptBuf,
    public_key: &PublicKey,
    create_address: F,
) -> Result<bool>
where
    F: FnOnce(&PublicKey) -> Result<Address>,
{
    let expected_address = create_address(public_key)?;
    let expected_script = expected_address.script_pubkey();
    Ok(script_matches(script_pubkey, &expected_script))
}

/// Check if a public key is used in a witness script
pub fn is_pubkey_in_witness_script(
    witness_script: &ScriptBuf,
    public_key: &PublicKey,
) -> Result<bool> {
    // Convert the public key to serialized format that we're looking for
    let pubkey_bytes = public_key.to_bytes();

    // Parse the script into instructions
    let mut iter = witness_script.instructions_minimal();

    // Iterate through all elements in the script
    while let Some(result) = iter.next() {
        // Only process successfully parsed instructions
        if let Ok(instruction) = result {
            if let bitcoin::blockdata::script::Instruction::PushBytes(bytes) = instruction {
                // Check if this pushed data is a public key
                if bytes.len() == pubkey_bytes.len() && bytes.as_bytes() == pubkey_bytes.as_slice()
                {
                    return Ok(true);
                }
            }
        }
    }

    Ok(false)
}

/// Check if a key can sign a P2WPKH input
pub fn can_sign_p2wpkh_input(
    script_pubkey: &ScriptBuf,
    public_key: &PublicKey,
    network: Network,
) -> Result<bool> {
    can_sign_with_address_creation(script_pubkey, public_key, |pubkey| -> Result<Address> {
        let compressed_pubkey = get_compressed_pubkey(pubkey)?;
        Ok(Address::p2wpkh(&compressed_pubkey, network))
    })
}

/// Check if a key can sign a P2PKH input
pub fn can_sign_p2pkh_input(
    script_pubkey: &ScriptBuf,
    public_key: &PublicKey,
    network: Network,
) -> Result<bool> {
    can_sign_with_address_creation(script_pubkey, public_key, |pubkey| {
        Ok(Address::p2pkh(pubkey, network))
    })
}

/// Check if a key can sign a P2SH-P2WPKH input
pub fn can_sign_p2sh_p2wpkh_input(
    script_pubkey: &ScriptBuf,
    public_key: &PublicKey,
    network: Network,
) -> Result<bool> {
    can_sign_with_address_creation(script_pubkey, public_key, |pubkey| -> Result<Address> {
        let compressed_pubkey = get_compressed_pubkey(pubkey)?;
        let p2wpkh = Address::p2wpkh(&compressed_pubkey, network);
        Address::p2sh(&p2wpkh.script_pubkey(), network).map_err(|e| {
            crate::wallet::WalletError::BitcoinError(format!(
                "Failed to create P2SH-P2WPKH address: {}",
                e
            ))
        })
    })
}

/// Check if a key can sign a P2TR input
pub fn can_sign_p2tr_input(
    script_pubkey: &ScriptBuf,
    public_key: &PublicKey,
    network: Network,
) -> Result<bool> {
    can_sign_with_address_creation(script_pubkey, public_key, |pubkey| -> Result<Address> {
        let secp = Secp256k1::verification_only();
        let xonly_pubkey = get_xonly_pubkey(pubkey)?;
        Ok(Address::p2tr(&secp, xonly_pubkey, None, network))
    })
}

/// Check if a key can sign a P2WSH input
pub fn can_sign_p2wsh_input(
    script_pubkey: &ScriptBuf,
    public_key: &PublicKey,
    witness_script: Option<&ScriptBuf>,
    network: Network,
) -> Result<bool> {
    if let Some(script) = witness_script {
        can_sign_with_address_creation(script_pubkey, public_key, |_| {
            Ok(Address::p2wsh(script, network))
        })
        .and_then(|matches| {
            if matches {
                is_pubkey_in_witness_script(script, public_key)
            } else {
                Ok(false)
            }
        })
    } else {
        Ok(false)
    }
}

/// Check if a private key can sign a specific input
pub fn can_sign_input(
    script_pubkey: &ScriptBuf,
    public_key: &PublicKey,
    address_type: &str,
    psbt_input: Option<&bitcoin::psbt::Input>,
    network: Network,
) -> Result<bool> {
    let addr_type = AddressType::from_str(standardize_address_type(address_type))
        .expect("AddressType::from_str never returns an error");

    match addr_type {
        AddressType::P2WPKH => can_sign_p2wpkh_input(script_pubkey, public_key, network),
        AddressType::P2PKH => can_sign_p2pkh_input(script_pubkey, public_key, network),
        AddressType::P2SHP2WPKH => can_sign_p2sh_p2wpkh_input(script_pubkey, public_key, network),
        AddressType::P2TR => can_sign_p2tr_input(script_pubkey, public_key, network),
        AddressType::P2WSH => {
            if let Some(input) = psbt_input {
                can_sign_p2wsh_input(
                    script_pubkey,
                    public_key,
                    input.witness_script.as_ref(),
                    network,
                )
            } else {
                Ok(false)
            }
        }
        AddressType::Unknown => Ok(false),
    }
}
