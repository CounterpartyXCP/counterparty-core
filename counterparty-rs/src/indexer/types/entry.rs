use super::error::Error;
use std::fmt::Debug;

pub fn to_cf_name<T>() -> String {
    let full_type_name = std::any::type_name::<T>();
    let type_name = full_type_name.split("::").last().unwrap_or(full_type_name);
    type_name.chars().fold(String::new(), |mut acc, c| {
        if c.is_uppercase() {
            if !acc.is_empty() {
                acc.push('_');
            }
            acc.extend(c.to_lowercase());
        } else {
            acc.push(c);
        }
        acc
    })
}

pub fn get_cf_names() -> [String; 4] {
    [
        to_cf_name::<ScriptHashHasOutputsInBlockAtHeight>(),
        to_cf_name::<BlockAtHeightSpentOutputInTx>(),
        to_cf_name::<TxInBlockAtHeight>(),
        to_cf_name::<BlockAtHeightHasHash>(),
    ]
}
pub const CF_PREFIX_LENGTHS: [usize; 4] = [20, 36, 32, 4];
pub fn get_cf_index_names() -> [String; 4] {
    [
        to_cf_name::<ScriptHashHasOutputsInBlockAtHeight>() + INDEX_CF_NAME_SUFFIX,
        to_cf_name::<BlockAtHeightSpentOutputInTx>() + INDEX_CF_NAME_SUFFIX,
        to_cf_name::<TxInBlockAtHeight>() + INDEX_CF_NAME_SUFFIX,
        to_cf_name::<BlockAtHeightHasHash>() + INDEX_CF_NAME_SUFFIX,
    ]
}
pub const CF_INDEX_PREFIX_LENGTHS: [usize; 4] = [4, 4, 4, 4];
pub const INDEX_CF_NAME_SUFFIX: &str = "_index";

pub fn make_key(parts: &[Vec<u8>]) -> Vec<u8> {
    let mut key = Vec::new();
    for p in parts {
        key.extend_from_slice(p)
    }
    key
}

pub type Entry = (Vec<u8>, Vec<u8>);

pub trait ToEntry: Debug + Send {
    fn to_entry(&self) -> Entry;
    fn to_index(&self) -> Entry;
    fn cf_name(&self) -> String;
    fn height(&self) -> u32;
}

pub trait FromEntry: Sized {
    fn from_entry(entry: Entry) -> Result<Self, Error>;
    fn from_index(entry: Entry) -> Result<Self, Error>;
}

#[derive(Debug)]
pub struct WritableEntry<E: ToEntry> {
    base: E,
    entry: Entry,
}

impl<E: ToEntry> WritableEntry<E> {
    pub fn new(base: E) -> Self {
        let entry = base.to_entry();
        Self { base, entry }
    }
}

impl<E: ToEntry> ToEntry for WritableEntry<E> {
    fn to_entry(&self) -> Entry {
        self.entry.clone()
    }

    fn to_index(&self) -> Entry {
        self.base.to_index()
    }

    fn cf_name(&self) -> String {
        self.base.cf_name()
    }

    fn height(&self) -> u32 {
        self.base.height()
    }
}

#[derive(Clone, PartialEq, Eq, Debug)]
pub struct ScriptHashHasOutputsInBlockAtHeight {
    pub script_hash: [u8; 20],
    pub height: u32,
}

impl ToEntry for ScriptHashHasOutputsInBlockAtHeight {
    // [script_hash (20 bytes)][height (4 bytes)]
    fn to_entry(&self) -> (Vec<u8>, Vec<u8>) {
        let key = make_key(&[
            self.script_hash.to_vec(),
            self.height.to_be_bytes().to_vec(),
        ]);
        (key, Vec::new())
    }

    fn to_index(&self) -> (Vec<u8>, Vec<u8>) {
        let key = make_key(&[
            self.height.to_be_bytes().to_vec(),
            self.script_hash.to_vec(),
        ]);
        (key, Vec::new())
    }

    fn cf_name(&self) -> String {
        to_cf_name::<Self>()
    }

    fn height(&self) -> u32 {
        self.height
    }
}

impl FromEntry for ScriptHashHasOutputsInBlockAtHeight {
    fn from_entry((key, _): Entry) -> Result<Self, Error> {
        if key.len() != 24 {
            return Err(Error::KeyParse(
                "ScriptHashHasOutputsInBlockAtHeight entry".into(),
            ));
        }
        let script_hash = <[u8; 20]>::try_from(&key[0..20])?;
        let height = u32::from_be_bytes(key[20..24].try_into()?);
        Ok(ScriptHashHasOutputsInBlockAtHeight {
            script_hash,
            height,
        })
    }

    fn from_index((key, _): Entry) -> Result<Self, Error> {
        if key.len() != 24 {
            return Err(Error::KeyParse(
                "ScriptHashHasOutputsInBlockAtHeight index".into(),
            ));
        }
        let height = u32::from_be_bytes(key[0..4].try_into()?);
        let script_hash = <[u8; 20]>::try_from(&key[4..24])?;
        Ok(ScriptHashHasOutputsInBlockAtHeight {
            script_hash,
            height,
        })
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TxidVoutPrefix {
    pub txid: [u8; 32],
    pub vout: u32,
}

impl TxidVoutPrefix {
    pub fn to_prefix(&self) -> Vec<u8> {
        make_key(&[self.txid.to_vec(), self.vout.to_be_bytes().to_vec()])
    }
}

#[derive(Clone, PartialEq, Eq, Debug)]
pub struct BlockAtHeightSpentOutputInTx {
    pub txid: [u8; 32],
    pub vout: u32,
    pub height: u32,
}

impl ToEntry for BlockAtHeightSpentOutputInTx {
    // [txid (32 bytes)][vout (4 bytes)][height (4 bytes)]
    fn to_entry(&self) -> (Vec<u8>, Vec<u8>) {
        let key = make_key(&[
            TxidVoutPrefix {
                txid: self.txid,
                vout: self.vout,
            }
            .to_prefix(),
            self.height.to_be_bytes().to_vec(),
        ]);
        (key, Vec::new())
    }

    fn to_index(&self) -> (Vec<u8>, Vec<u8>) {
        let key = make_key(&[
            self.height.to_be_bytes().to_vec(),
            TxidVoutPrefix {
                txid: self.txid,
                vout: self.vout,
            }
            .to_prefix(),
        ]);
        (key, Vec::new())
    }

    fn cf_name(&self) -> String {
        to_cf_name::<Self>()
    }

    fn height(&self) -> u32 {
        self.height
    }
}

impl FromEntry for BlockAtHeightSpentOutputInTx {
    fn from_entry((key, _): Entry) -> Result<Self, Error> {
        if key.len() != 40 {
            return Err(Error::KeyParse("BlockAtHeightSpentOutputInTx entry".into()));
        }
        let txid = <[u8; 32]>::try_from(&key[0..32])?;
        let vout = u32::from_be_bytes(key[32..36].try_into()?);
        let height = u32::from_be_bytes(key[36..40].try_into()?);
        Ok(BlockAtHeightSpentOutputInTx { txid, vout, height })
    }

    fn from_index((key, _): Entry) -> Result<Self, Error> {
        if key.len() != 40 {
            return Err(Error::KeyParse("BlockAtHeightSpentOutputInTx index".into()));
        }
        let height = u32::from_be_bytes(key[0..4].try_into()?);
        let txid = <[u8; 32]>::try_from(&key[4..36])?;
        let vout = u32::from_be_bytes(key[36..40].try_into()?);
        Ok(BlockAtHeightSpentOutputInTx { txid, vout, height })
    }
}

#[derive(Clone, PartialEq, Eq, Debug)]
pub struct TxInBlockAtHeight {
    pub txid: [u8; 32],
    pub height: u32,
}

impl ToEntry for TxInBlockAtHeight {
    // [txid (32 bytes)][height (4 bytes)]
    fn to_entry(&self) -> (Vec<u8>, Vec<u8>) {
        let key = make_key(&[
            b"S-".into(),
            self.txid.to_vec(),
            self.height.to_be_bytes().to_vec(),
        ]);
        (key, Vec::new())
    }

    fn to_index(&self) -> (Vec<u8>, Vec<u8>) {
        let key = make_key(&[
            self.height.to_be_bytes().to_vec(),
            b"S-".into(),
            self.txid.to_vec(),
        ]);
        (key, Vec::new())
    }

    fn cf_name(&self) -> String {
        to_cf_name::<Self>()
    }

    fn height(&self) -> u32 {
        self.height
    }
}

impl FromEntry for TxInBlockAtHeight {
    fn from_entry((key, _): Entry) -> Result<Self, Error> {
        if key.len() != 38 {
            return Err(Error::KeyParse("TxInBlockAtHeight entry".into()));
        }
        let txid = <[u8; 32]>::try_from(&key[2..34])?;
        let height = u32::from_be_bytes(key[34..38].try_into()?);
        Ok(TxInBlockAtHeight { txid, height })
    }

    fn from_index((key, _): Entry) -> Result<Self, Error> {
        if key.len() != 38 {
            return Err(Error::KeyParse("TxInBlockAtHeight index".into()));
        }
        let height = u32::from_be_bytes(key[0..4].try_into()?);
        let txid = <[u8; 32]>::try_from(&key[6..38])?;
        Ok(TxInBlockAtHeight { txid, height })
    }
}

#[derive(Clone, PartialEq, Eq, Debug)]
pub struct BlockAtHeightHasHash {
    pub height: u32,
    pub hash: [u8; 32],
}

impl ToEntry for BlockAtHeightHasHash {
    // [height (4 bytes)]
    fn to_entry(&self) -> (Vec<u8>, Vec<u8>) {
        let key = make_key(&[self.height.to_be_bytes().to_vec()]);
        (key, self.hash.to_vec())
    }

    fn to_index(&self) -> (Vec<u8>, Vec<u8>) {
        self.to_entry()
    }

    fn cf_name(&self) -> String {
        to_cf_name::<Self>()
    }

    fn height(&self) -> u32 {
        self.height
    }
}

impl FromEntry for BlockAtHeightHasHash {
    fn from_entry((key, value): Entry) -> Result<Self, Error> {
        if key.len() != 4 {
            return Err(Error::KeyParse("BlockAtHeightHasHash entry".into()));
        }

        if value.len() != 32 {
            return Err(Error::ValueParse("BlockAtHeightHasHash".into()));
        }

        let height = u32::from_be_bytes(key.as_slice().try_into()?);
        let hash = <[u8; 32]>::try_from(&value[..])?;
        Ok(BlockAtHeightHasHash { height, hash })
    }

    fn from_index(entry: Entry) -> Result<Self, Error> {
        Self::from_entry(entry)
    }
}

#[cfg(test)]
#[allow(clippy::unwrap_used)]
mod tests {
    use crate::indexer::test_utils::{test_h160_hash, test_sha256_hash};

    use super::*;

    #[test]
    fn test_script_hash_has_outputs_in_block_at_height() {
        let original = ScriptHashHasOutputsInBlockAtHeight {
            script_hash: test_h160_hash(1),
            height: 12345,
        };

        let entry = original.to_entry();
        assert!(entry.1.is_empty());
        assert_eq!(
            original,
            ScriptHashHasOutputsInBlockAtHeight::from_entry(entry).unwrap()
        );

        let index = original.to_index();
        assert!(index.1.is_empty());
        assert_eq!(
            original,
            ScriptHashHasOutputsInBlockAtHeight::from_index(index).unwrap()
        );

        assert_eq!(
            original.cf_name(),
            "script_hash_has_outputs_in_block_at_height"
        );
    }

    #[test]
    fn test_block_at_height_spent_output_in_tx() {
        let original = BlockAtHeightSpentOutputInTx {
            txid: test_sha256_hash(2),
            vout: 10,
            height: 54321,
        };

        let entry = original.to_entry();
        assert!(entry.1.is_empty());
        assert_eq!(
            original,
            BlockAtHeightSpentOutputInTx::from_entry(entry).unwrap()
        );

        let index = original.to_index();
        assert!(index.1.is_empty());
        assert_eq!(
            original,
            BlockAtHeightSpentOutputInTx::from_index(index).unwrap()
        );

        assert_eq!(original.cf_name(), "block_at_height_spent_output_in_tx")
    }

    #[test]
    fn test_tx_in_block_at_height() {
        let original = TxInBlockAtHeight {
            txid: test_sha256_hash(3),
            height: 67890,
        };

        let entry = original.to_entry();
        assert!(entry.1.is_empty());
        assert_eq!(original, TxInBlockAtHeight::from_entry(entry).unwrap());

        let index = original.to_index();
        assert!(index.1.is_empty());
        assert_eq!(original, TxInBlockAtHeight::from_index(index).unwrap());

        assert_eq!(original.cf_name(), "tx_in_block_at_height")
    }

    #[test]
    fn test_block_at_height_has_hash() {
        let original = BlockAtHeightHasHash {
            height: 123,
            hash: test_sha256_hash(4),
        };

        let entry = original.to_entry();
        assert_eq!(original, BlockAtHeightHasHash::from_entry(entry).unwrap());

        let index = original.to_index();
        assert_eq!(original, BlockAtHeightHasHash::from_index(index).unwrap());

        assert_eq!(original.cf_name(), "block_at_height_has_hash")
    }
}
