use std::sync::Arc;

use rocksdb::{
    ColumnFamily, ColumnFamilyDescriptor, Direction, IteratorMode, Options, WriteBatch,
    WriteOptions, DB,
};

use crate::indexer::{constants::CP_HEIGHT, types::entry::BlockAtHeightSpentOutputInTx};

use super::types::{
    entry::{
        get_cf_index_names, get_cf_names, make_key, to_cf_name, BlockAtHeightHasHash, FromEntry,
        ScriptHashHasOutputsInBlockAtHeight, ToEntry, TxidVoutPrefix, CF_INDEX_PREFIX_LENGTHS,
        CF_PREFIX_LENGTHS, INDEX_CF_NAME_SUFFIX,
    },
    error::Error,
};

const MAX_BLOCK_HEIGHT_KEY: &[u8; 16] = b"max_block_height";

pub trait DatabaseOps: Clone + Send + 'static {
    fn get_max_block_height(&self) -> Result<u32, Error>;
    fn get_funding_block_entries(
        &self,
        script_hash: [u8; 20],
    ) -> Result<Vec<BlockAtHeightHasHash>, Error>;
    fn filter_spent(
        &self,
        outputs: Vec<(TxidVoutPrefix, u64)>,
    ) -> Result<Vec<(TxidVoutPrefix, u64)>, Error>;
    fn put_max_block_height(&self, batch: &mut WriteBatch, height: u32) -> Result<(), Error>;
    #[allow(clippy::ptr_arg)]
    fn put_entries(
        &self,
        batch: &mut WriteBatch,
        min_index_height: Option<u32>,
        entries: &Vec<Box<dyn ToEntry>>,
    ) -> Result<(), Error>;
    fn delete_indexes_below_height(
        &self,
        cf: &ColumnFamily,
        batch: &mut WriteBatch,
        height: u32,
    ) -> Result<(), Error>;
    fn write_batch<F: FnOnce(&mut WriteBatch) -> Result<(), Error>>(
        &self,
        f: F,
    ) -> Result<(), Error>;
    fn block_at_height_has_hash(&self, height: u32) -> Result<Option<Vec<u8>>, Error>;
    fn rollback_to_height(&self, batch: &mut WriteBatch, height: u32) -> Result<(), Error>;
}

#[derive(Clone)]
pub struct Database {
    db: Arc<DB>,
}

impl Database {
    pub fn new(path: String) -> Result<Self, Error> {
        let cfs: Vec<ColumnFamilyDescriptor> = get_cf_names()
            .into_iter()
            .zip(CF_PREFIX_LENGTHS)
            .chain(
                get_cf_index_names()
                    .into_iter()
                    .zip(CF_INDEX_PREFIX_LENGTHS),
            )
            .map(|(name, prefix_length)| {
                let mut opts = Options::default();
                opts.set_level_compaction_dynamic_level_bytes(true);
                opts.set_prefix_extractor(rocksdb::SliceTransform::create_fixed_prefix(
                    prefix_length,
                ));
                ColumnFamilyDescriptor::new(name, opts)
            })
            .collect();
        let mut opts = Options::default();
        opts.increase_parallelism(std::thread::available_parallelism()?.get() as i32);
        opts.create_if_missing(true);
        opts.create_missing_column_families(true);
        let db = Arc::new(DB::open_cf_descriptors(&opts, path, cfs)?);
        Ok(Database { db })
    }

    fn cf(&self, cf_name: String) -> Result<&ColumnFamily, Error> {
        self.db
            .cf_handle(&cf_name)
            .ok_or(Error::RocksDBColumnFamily(cf_name))
    }
}

impl DatabaseOps for Database {
    fn get_max_block_height(&self) -> Result<u32, Error> {
        Ok(u32::from_be_bytes(
            self.db
                .get(MAX_BLOCK_HEIGHT_KEY)?
                .unwrap_or((CP_HEIGHT - 1).to_be_bytes().to_vec())
                .try_into()
                .map_err(|_| Error::U32Conversion("Could not convert max block height".into()))?,
        ))
    }

    fn get_funding_block_entries(
        &self,
        script_hash: [u8; 20],
    ) -> Result<Vec<BlockAtHeightHasHash>, Error> {
        let mut results = Vec::new();
        let height_iter = self.db.prefix_iterator_cf(
            self.cf(to_cf_name::<ScriptHashHasOutputsInBlockAtHeight>())?,
            script_hash,
        );
        for result in height_iter {
            let (key, value) = result?;
            let entry = (key.to_vec(), value.to_vec());
            let height = ScriptHashHasOutputsInBlockAtHeight::from_entry(entry)?.height;
            let height_as_bytes = height.to_be_bytes();
            #[allow(clippy::expect_used, clippy::expect_fun_call)]
            let hash = self
                .db
                .get_cf(
                    self.cf(to_cf_name::<BlockAtHeightHasHash>())?,
                    height_as_bytes,
                )?
                .expect(&format!(
                    "DB should have BlockAtHeightHasHash index for block at height: {}",
                    height
                ));
            results.push(BlockAtHeightHasHash::from_entry((
                height_as_bytes.to_vec(),
                hash,
            ))?);
        }
        Ok(results)
    }

    fn filter_spent(
        &self,
        outputs: Vec<(TxidVoutPrefix, u64)>,
    ) -> Result<Vec<(TxidVoutPrefix, u64)>, Error> {
        let mut unspent = Vec::new();
        for o in outputs {
            let mut iter = self.db.prefix_iterator_cf(
                self.cf(to_cf_name::<BlockAtHeightSpentOutputInTx>())?,
                o.0.to_prefix(),
            );
            if iter.next().is_none() {
                unspent.push(o);
            }
        }
        Ok(unspent)
    }

    fn put_max_block_height(&self, batch: &mut WriteBatch, height: u32) -> Result<(), Error> {
        batch.put(MAX_BLOCK_HEIGHT_KEY, height.to_be_bytes());
        Ok(())
    }

    fn put_entries(
        &self,
        batch: &mut WriteBatch,
        min_index_height: Option<u32>,
        entries: &Vec<Box<dyn ToEntry>>,
    ) -> Result<(), Error> {
        for entry in entries {
            let (key, value) = entry.to_entry();
            self.db.put_cf(self.cf(entry.cf_name())?, key, value)?;
            if min_index_height.is_some() {
                let (key, value) = entry.to_index();
                self.db
                    .put_cf(self.cf(entry.cf_name() + INDEX_CF_NAME_SUFFIX)?, key, value)?;
            }
        }

        if let Some(height) = min_index_height {
            for cf_name in get_cf_index_names() {
                self.delete_indexes_below_height(self.cf(cf_name)?, batch, height)?
            }
        }
        Ok(())
    }

    fn delete_indexes_below_height(
        &self,
        cf: &ColumnFamily,
        batch: &mut WriteBatch,
        height: u32,
    ) -> Result<(), Error> {
        // range has exclusive end
        batch.delete_range_cf(cf, [0u8; 4], height.to_be_bytes());
        Ok(())
    }

    fn write_batch<F: FnOnce(&mut WriteBatch) -> Result<(), Error>>(
        &self,
        f: F,
    ) -> Result<(), Error> {
        let mut batch = WriteBatch::default();
        f(&mut batch)?;
        let write_options = WriteOptions::default();
        Ok(self.db.write_opt(batch, &write_options)?)
    }

    fn block_at_height_has_hash(&self, height: u32) -> Result<Option<Vec<u8>>, Error> {
        Ok(self.db.get_cf(
            self.cf(to_cf_name::<BlockAtHeightHasHash>())?,
            height.to_be_bytes(),
        )?)
    }

    fn rollback_to_height(&self, batch: &mut WriteBatch, height: u32) -> Result<(), Error> {
        for cf_name in get_cf_names() {
            let entry_cf = self.cf(cf_name.clone())?;
            let index_cf = self.cf(cf_name + INDEX_CF_NAME_SUFFIX)?;
            let prefix = (height + 1).to_be_bytes();
            let index_iter = self
                .db
                .iterator_cf(index_cf, IteratorMode::From(&prefix, Direction::Forward));
            for entry in index_iter {
                let (index_key, _) = entry.or(Err(Error::RocksDBIter(
                    "Encounted unwrappable entry in rollback iter".into(),
                )))?;
                batch.delete_cf(index_cf, &index_key);
                let mut entry_key = index_key.to_vec();
                if entry_key.len() > 4 {
                    entry_key = make_key(&[index_key[4..].to_vec(), index_key[0..4].to_vec()]);
                }
                batch.delete_cf(entry_cf, entry_key);
            }
        }
        self.put_max_block_height(batch, height)
    }
}

#[cfg(test)]
#[allow(clippy::unwrap_used)]
mod tests {
    use rocksdb::IteratorMode;

    use super::*;
    use crate::{
        indexer::{
            test_utils::{test_h160_hash, test_sha256_hash},
            types::entry::{
                BlockAtHeightHasHash, BlockAtHeightSpentOutputInTx, FromEntry,
                ScriptHashHasOutputsInBlockAtHeight, TxInBlockAtHeight,
            },
        },
        new_test_db,
    };

    #[test]
    fn test_max_block_height() {
        let db = new_test_db!().unwrap();
        assert_eq!(db.get_max_block_height().unwrap(), CP_HEIGHT - 1);

        let height = 37;
        db.write_batch(|batch| db.put_max_block_height(batch, height))
            .unwrap();
        assert_eq!(db.get_max_block_height().unwrap(), height);
    }

    #[test]
    fn test_block_at_height_has_hash() {
        let db = new_test_db!().unwrap();
        let n = 2;

        let entries = (0..n)
            .map(|height| -> Box<dyn ToEntry> {
                Box::new(BlockAtHeightHasHash {
                    height,
                    hash: test_sha256_hash(height),
                })
            })
            .collect();

        (0..n).for_each(|height| {
            assert_eq!(db.block_at_height_has_hash(height).unwrap(), None);
        });

        db.write_batch(|batch| db.put_entries(batch, None, &entries))
            .unwrap();
        (0..n).for_each(|height| {
            assert_eq!(
                db.block_at_height_has_hash(height).unwrap(),
                Some(test_sha256_hash(height).to_vec())
            );
        });
    }

    #[test]
    fn test_get_funding_block_heights_found() {
        let db = new_test_db!().unwrap();
        let script_hash = test_h160_hash(1);
        let entries: Vec<Box<dyn ToEntry>> = vec![
            Box::new(ScriptHashHasOutputsInBlockAtHeight {
                script_hash,
                height: 1001,
            }),
            Box::new(BlockAtHeightHasHash {
                height: 1001,
                hash: test_sha256_hash(1),
            }),
            Box::new(ScriptHashHasOutputsInBlockAtHeight {
                script_hash,
                height: 1002,
            }),
            Box::new(BlockAtHeightHasHash {
                height: 1002,
                hash: test_sha256_hash(2),
            }),
        ];
        db.write_batch(|batch| db.put_entries(batch, None, &entries))
            .unwrap();

        let entries = db.get_funding_block_entries(script_hash).unwrap();
        assert_eq!(entries.len(), 2);
        assert_eq!(entries[0].height, 1001);
        assert_eq!(entries[0].hash, test_sha256_hash(1));
        assert_eq!(entries[1].height, 1002);
        assert_eq!(entries[1].hash, test_sha256_hash(2));
    }

    #[test]
    fn test_get_funding_block_heights_multiple_script_hashes() {
        let db = new_test_db!().unwrap();
        let script_hash1 = test_h160_hash(1);
        let script_hash2 = test_h160_hash(2);

        let entries: Vec<Box<dyn ToEntry>> = vec![
            Box::new(ScriptHashHasOutputsInBlockAtHeight {
                script_hash: script_hash1,
                height: 1001,
            }),
            Box::new(BlockAtHeightHasHash {
                height: 1001,
                hash: test_sha256_hash(1),
            }),
            Box::new(ScriptHashHasOutputsInBlockAtHeight {
                script_hash: script_hash2,
                height: 1002,
            }),
            Box::new(BlockAtHeightHasHash {
                height: 1002,
                hash: test_sha256_hash(2),
            }),
        ];
        db.write_batch(|batch| db.put_entries(batch, None, &entries))
            .unwrap();

        let entries1 = db.get_funding_block_entries(script_hash1).unwrap();
        assert_eq!(entries1.len(), 1);
        assert_eq!(entries1[0].height, 1001);
        let entries2 = db.get_funding_block_entries(script_hash2).unwrap();
        assert_eq!(entries2.len(), 1);
        assert_eq!(entries2[0].height, 1002);
    }

    #[test]
    fn test_filter_spent_all_unspent() {
        let db = new_test_db!().unwrap();
        let inputs = vec![
            (
                TxidVoutPrefix {
                    txid: test_sha256_hash(1),
                    vout: 0,
                },
                0,
            ),
            (
                TxidVoutPrefix {
                    txid: test_sha256_hash(2),
                    vout: 1,
                },
                1,
            ),
        ];

        let result = db.filter_spent(inputs.clone()).unwrap();
        assert_eq!(result, inputs, "All txid/vout should be unspent");
    }

    #[test]
    fn test_filter_spent_some_spent() {
        let db = new_test_db!().unwrap();
        let inputs = vec![
            (
                TxidVoutPrefix {
                    txid: test_sha256_hash(0),
                    vout: 0,
                },
                0,
            ),
            (
                TxidVoutPrefix {
                    txid: test_sha256_hash(1),
                    vout: 1,
                },
                1,
            ),
        ];

        // Simulate some txid/vout being spent
        let spent_entry = BlockAtHeightSpentOutputInTx {
            txid: test_sha256_hash(0),
            vout: 0,
            height: 1,
        };
        db.write_batch(|batch| db.put_entries(batch, Some(0), &vec![Box::new(spent_entry)]))
            .unwrap();

        let result = db.filter_spent(inputs.clone()).unwrap();
        assert_eq!(result, inputs[1..], "Only txid 1 should be unspent");
    }

    fn get_indexes<T: FromEntry>(db: &Database) -> Result<Vec<Box<T>>, Error> {
        db.db
            .iterator_cf(
                db.cf(to_cf_name::<T>() + INDEX_CF_NAME_SUFFIX)?,
                IteratorMode::Start,
            )
            .map(|r| {
                r.map_err(Error::from).and_then(|(key, value)| {
                    T::from_entry((key.to_vec(), value.to_vec())).map(Box::new)
                })
            })
            .collect()
    }

    #[test]
    fn test_delete_indexes_below_height() {
        let db = new_test_db!().unwrap();

        let n = 2;
        let entries = (0..n + 1)
            .map(|height| -> Box<dyn ToEntry> {
                Box::new(BlockAtHeightHasHash {
                    height,
                    hash: test_sha256_hash(height),
                })
            })
            .collect();

        db.write_batch(|batch| db.put_entries(batch, Some(0), &entries))
            .unwrap();

        db.write_batch(|batch| {
            db.delete_indexes_below_height(
                db.cf(to_cf_name::<BlockAtHeightHasHash>() + INDEX_CF_NAME_SUFFIX)?,
                batch,
                n,
            )
        })
        .unwrap();

        assert_eq!(
            get_indexes::<BlockAtHeightHasHash>(&db)
                .unwrap()
                .into_iter()
                .map(|b| b.to_entry())
                .collect::<Vec<_>>(),
            entries[(n as usize)..]
                .iter()
                .map(|b| b.to_entry())
                .collect::<Vec<_>>()
        );
    }

    #[test]
    fn test_put_entries_none() {
        let db = new_test_db!().unwrap();

        let entries_data = [
            (test_h160_hash(0), 999),
            (test_h160_hash(1), 1000),
            (test_h160_hash(2), 1001),
        ];

        let all_entries = entries_data
            .iter()
            .map(|&(script_hash, height)| -> Box<dyn ToEntry> {
                Box::new(ScriptHashHasOutputsInBlockAtHeight {
                    script_hash,
                    height,
                })
            })
            .collect();

        let all_entries_expected = entries_data
            .iter()
            .map(
                |&(script_hash, height)| ScriptHashHasOutputsInBlockAtHeight {
                    script_hash,
                    height,
                },
            )
            .collect::<Vec<ScriptHashHasOutputsInBlockAtHeight>>();

        db.write_batch(|b| db.put_entries(b, None, &all_entries))
            .unwrap();

        for entry in all_entries_expected.iter() {
            let cf_name = to_cf_name::<ScriptHashHasOutputsInBlockAtHeight>();
            let (entry_key, _) = entry.to_entry();
            let value = db
                .db
                .get_cf(db.cf(cf_name).unwrap(), entry_key.clone())
                .unwrap()
                .unwrap();
            let retrieved_entry =
                ScriptHashHasOutputsInBlockAtHeight::from_entry((entry_key, value)).unwrap();
            assert_eq!(entry, &retrieved_entry);

            let (index_key, _) = entry.to_index();
            let maybe_index =
                db.db
                    .get_cf(
                        db.cf(to_cf_name::<ScriptHashHasOutputsInBlockAtHeight>()
                            + INDEX_CF_NAME_SUFFIX)
                            .unwrap(),
                        &index_key,
                    )
                    .unwrap();
            assert!(
                maybe_index.is_none(),
                "Index should not exist when no minimum index height is specified"
            );
        }
    }

    #[test]
    fn test_put_entries_some() {
        let db = new_test_db!().unwrap();

        let min_index_height = 1000;
        let entries_data = [
            (test_h160_hash(0), 999),
            (test_h160_hash(1), 1000),
            (test_h160_hash(2), 1001),
        ];
        let all_entries = entries_data
            .iter()
            .map(|&(script_hash, height)| -> Box<dyn ToEntry> {
                Box::new(ScriptHashHasOutputsInBlockAtHeight {
                    script_hash,
                    height,
                })
            })
            .collect();

        let all_entries_expected = entries_data
            .iter()
            .map(
                |&(script_hash, height)| ScriptHashHasOutputsInBlockAtHeight {
                    script_hash,
                    height,
                },
            )
            .collect::<Vec<ScriptHashHasOutputsInBlockAtHeight>>();

        db.write_batch(|b| db.put_entries(b, Some(min_index_height), &all_entries))
            .unwrap();

        for entry in all_entries_expected.iter() {
            let cf_name = to_cf_name::<ScriptHashHasOutputsInBlockAtHeight>();
            let (entry_key, _) = entry.to_entry();
            let value = db
                .db
                .get_cf(db.cf(cf_name).unwrap(), entry_key.clone())
                .unwrap()
                .unwrap();
            let retrieved_entry =
                ScriptHashHasOutputsInBlockAtHeight::from_entry((entry_key, value)).unwrap();
            assert_eq!(entry, &retrieved_entry);

            let (index_key, _) = entry.to_index();
            let maybe_index =
                db.db
                    .get_cf(
                        db.cf(to_cf_name::<ScriptHashHasOutputsInBlockAtHeight>()
                            + INDEX_CF_NAME_SUFFIX)
                            .unwrap(),
                        &index_key,
                    )
                    .unwrap();
            if retrieved_entry.height >= min_index_height {
                assert!(
                    maybe_index.is_some(),
                    "Index should exist for entries at or above the threshold"
                );
            } else {
                assert!(
                    maybe_index.is_none(),
                    "Index should not exist for entries below the threshold"
                );
            }
        }
    }

    #[test]
    fn test_rollback_to_height() {
        let db = new_test_db!().unwrap();

        let pre_reorg_entries: Vec<Box<dyn ToEntry>> = vec![
            Box::new(ScriptHashHasOutputsInBlockAtHeight {
                script_hash: test_h160_hash(1),
                height: 1,
            }),
            Box::new(BlockAtHeightSpentOutputInTx {
                txid: test_sha256_hash(2),
                vout: 1,
                height: 2,
            }),
            Box::new(TxInBlockAtHeight {
                txid: test_sha256_hash(5),
                height: 2,
            }),
            Box::new(BlockAtHeightHasHash {
                height: 2,
                hash: test_sha256_hash(6),
            }),
        ];

        let post_reorg_entries: Vec<Box<dyn ToEntry>> = vec![
            Box::new(ScriptHashHasOutputsInBlockAtHeight {
                script_hash: test_h160_hash(3),
                height: 3,
            }),
            Box::new(BlockAtHeightSpentOutputInTx {
                txid: test_sha256_hash(4),
                vout: 2,
                height: 4,
            }),
            Box::new(TxInBlockAtHeight {
                txid: test_sha256_hash(7),
                height: 5,
            }),
            Box::new(BlockAtHeightHasHash {
                height: 5,
                hash: test_sha256_hash(8),
            }),
        ];

        let entries = pre_reorg_entries
            .into_iter()
            .chain(post_reorg_entries)
            .collect();
        let height = 2;
        db.write_batch(|batch| db.put_entries(batch, Some(0), &entries))
            .unwrap();

        db.write_batch(|batch| db.rollback_to_height(batch, height))
            .unwrap();

        for entry in entries {
            if entry.height() <= height {
                assert!(
                    db.db
                        .get_cf(db.cf(entry.cf_name()).unwrap(), entry.to_entry().0)
                        .unwrap()
                        .is_some(),
                    "Entry should exist"
                );
            } else {
                assert!(
                    db.db
                        .get_cf(db.cf(entry.cf_name()).unwrap(), entry.to_entry().0)
                        .unwrap()
                        .is_none(),
                    "Entry should not exist"
                );
            }
        }

        assert_eq!(db.get_max_block_height().unwrap(), 2);
    }
}
