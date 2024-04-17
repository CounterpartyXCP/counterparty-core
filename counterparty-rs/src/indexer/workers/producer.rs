use std::{thread::sleep, time::Duration};

use bitcoincore_rpc::bitcoin::hashes::Hash;
use crossbeam_channel::{Receiver, Sender};
use tracing::info;

use crate::indexer::{
    bitcoin_client::BitcoinRpc,
    database::DatabaseOps,
    types::{
        error::Error,
        pipeline::{BlockHasPrevBlockHash, Done, PipelineDataInitial},
    },
    utils::{in_reorg_window, with_retry},
};

fn get_last_matching_height<C, D, B>(
    client: &C,
    db: &D,
    done: Done,
    start_height: u32,
) -> Result<u32, Error>
where
    C: BitcoinRpc<B>,
    D: DatabaseOps,
    B: BlockHasPrevBlockHash,
{
    for i in (1..=start_height).rev() {
        let current_block_hash = client.get_block_hash(i)?;
        let current_block = client.get_block(&current_block_hash)?;
        let expected_prev_block_hash = current_block
            .get_prev_block_hash()
            .to_raw_hash()
            .to_byte_array()
            .to_vec();

        let j = i - 1;
        let prev_block_hash = with_retry(
            done.clone(),
            || {
                db.block_at_height_has_hash(j)?
                    .ok_or(Error::BlockNotWritten(j))
            },
            format!("Timedout waiting for block at index {} to be written", j),
        )?;

        if prev_block_hash == expected_prev_block_hash {
            return Ok(j);
        }
    }

    Err(Error::NoHashMatchFound)
}

pub fn new<C, D, B>(
    client: C,
    db: D,
    start_height: u32,
    reorg_window: u32,
) -> impl Fn(
    Receiver<Box<PipelineDataInitial>>,
    Sender<Box<PipelineDataInitial>>,
    Done,
) -> Result<(), Error>
       + Clone
where
    C: BitcoinRpc<B>,
    D: DatabaseOps,
    B: BlockHasPrevBlockHash,
{
    move |_, tx, done| {
        let mut height = start_height;
        let mut target_height = height - 1;
        let mut reorg_detection_enabled = false;
        loop {
            if done.try_recv().is_ok() {
                return Ok(());
            }

            if target_height < height {
                target_height = with_retry(
                    done.clone(),
                    || client.get_blockchain_height(),
                    "Error fetching blockchain info".into(),
                )?;
            }

            if target_height < height {
                sleep(Duration::from_secs(10));
                continue;
            }

            if in_reorg_window(height, target_height, reorg_window) {
                if !reorg_detection_enabled {
                    info!("Entering reorg window");
                    reorg_detection_enabled = true;
                }
                let last_matching_height =
                    get_last_matching_height(&client, &db, done.clone(), height)?;

                let last_saved_height = height - 1;
                if last_matching_height < last_saved_height {
                    info!(
                        "Reorganization detected. Rolling back from height {} to {}",
                        last_saved_height, last_matching_height
                    );

                    db.write_batch(|batch| db.rollback_to_height(batch, last_matching_height))?;
                    height = last_matching_height + 1;
                    target_height = height - 1;
                    reorg_detection_enabled = false;
                    continue;
                }
            } else if reorg_detection_enabled {
                info!("Leaving reorg window");
                reorg_detection_enabled = false
            };

            if tx
                .send(Box::new(PipelineDataInitial {
                    height,
                    target_height,
                }))
                .is_err()
            {
                return Ok(());
            };

            height += 1;
        }
    }
}

// TODO: add tests
#[cfg(test)]
#[allow(clippy::unwrap_used)]
mod tests {
    use super::*;
    use bitcoincore_rpc::bitcoin::BlockHash;
    use crossbeam_channel::unbounded;

    use crate::{
        indexer::{
            bitcoin_client::BitcoinRpc,
            database::Database,
            test_utils::{test_block_hash, test_sha256_hash},
            types::{entry::BlockAtHeightHasHash, error::Error},
        },
        new_test_db,
    };

    #[derive(Clone)]
    struct MockBlock {
        prev_hash: BlockHash,
    }

    impl MockBlock {
        fn new(_: BlockHash, prev_hash: BlockHash) -> Box<Self> {
            Box::new(MockBlock { prev_hash })
        }
    }

    impl BlockHasPrevBlockHash for MockBlock {
        fn get_prev_block_hash(&self) -> &BlockHash {
            &self.prev_hash
        }
    }

    #[derive(Clone)]
    struct MockBitcoinRpc {
        blocks_by_height: std::collections::HashMap<u32, BlockHash>, // Map height to block hash
        blocks_by_hash: std::collections::HashMap<BlockHash, Box<MockBlock>>, // Map hash to MockBlock
        blockchain_height: u32,
    }

    impl MockBitcoinRpc {
        fn new(blocks: Vec<(u32, BlockHash, Box<MockBlock>)>, blockchain_height: u32) -> Self {
            let mut rpc = MockBitcoinRpc {
                blocks_by_height: std::collections::HashMap::new(),
                blocks_by_hash: std::collections::HashMap::new(),
                blockchain_height,
            };
            for (height, hash, block) in blocks {
                rpc.blocks_by_height.insert(height, hash);
                rpc.blocks_by_hash.insert(hash, block);
            }
            rpc
        }
    }

    impl BitcoinRpc<MockBlock> for MockBitcoinRpc {
        fn get_block_hash(&self, height: u32) -> Result<BlockHash, Error> {
            Ok(self.blocks_by_height.get(&height).cloned().unwrap())
        }

        fn get_block(&self, hash: &BlockHash) -> Result<Box<MockBlock>, Error> {
            Ok(self.blocks_by_hash.get(hash).cloned().unwrap())
        }

        fn get_blockchain_height(&self) -> Result<u32, Error> {
            Ok(self.blockchain_height)
        }
    }

    #[test]
    fn test_get_last_matching_height_no_reorg() {
        let blocks = vec![
            (
                1,
                test_block_hash(1),
                MockBlock::new(test_block_hash(1), test_block_hash(0)),
            ),
            (
                2,
                test_block_hash(2),
                MockBlock::new(test_block_hash(2), test_block_hash(1)),
            ),
        ];
        let mock_rpc = MockBitcoinRpc::new(blocks, 2);

        let db = new_test_db!().unwrap();
        db.write_batch(|batch| {
            db.put_entries(
                batch,
                None,
                &vec![
                    Box::new(BlockAtHeightHasHash {
                        height: 0,
                        hash: test_sha256_hash(0),
                    }),
                    Box::new(BlockAtHeightHasHash {
                        height: 1,
                        hash: test_sha256_hash(1),
                    }),
                ],
            )
        })
        .unwrap();

        let (_, rx) = unbounded();
        let result = get_last_matching_height(&mock_rpc, &db, rx, 2).unwrap();
        assert_eq!(result, 1);
    }

    #[test]
    fn test_get_last_matching_height_reorg() {
        let blocks = vec![
            (
                1,
                test_block_hash(1),
                MockBlock::new(test_block_hash(1), test_block_hash(0)),
            ),
            (
                2,
                test_block_hash(2),
                MockBlock::new(test_block_hash(2), test_block_hash(1)),
            ),
            (
                3,
                test_block_hash(3),
                MockBlock::new(test_block_hash(3), test_block_hash(2)),
            ),
            (
                4,
                test_block_hash(4),
                MockBlock::new(test_block_hash(4), test_block_hash(3)),
            ),
        ];
        let mock_rpc = MockBitcoinRpc::new(blocks, 2);

        let db = new_test_db!().unwrap();
        db.write_batch(|batch| {
            db.put_entries(
                batch,
                None,
                &vec![
                    Box::new(BlockAtHeightHasHash {
                        height: 0,
                        hash: test_sha256_hash(0),
                    }),
                    Box::new(BlockAtHeightHasHash {
                        height: 1,
                        hash: test_sha256_hash(1),
                    }),
                    Box::new(BlockAtHeightHasHash {
                        height: 2,
                        hash: test_sha256_hash(3),
                    }),
                    Box::new(BlockAtHeightHasHash {
                        height: 3,
                        hash: test_sha256_hash(4),
                    }),
                ],
            )
        })
        .unwrap();

        let (_, rx) = unbounded();
        let result = get_last_matching_height(&mock_rpc, &db, rx, 3).unwrap();
        assert_eq!(result, 1);
    }
}
