use std::{collections::HashMap, sync::Arc, thread::JoinHandle};

use bitcoin::hashes::hex::ToHex;
use bitcoincore_rpc::{
    bitcoin::{
        consensus::serialize,
        hashes::{sha256d::Hash as Sha256dHash, Hash},
        Block, BlockHash,
    },
    Auth, Client, RpcApi,
};
use crossbeam_channel::{bounded, select, unbounded, Receiver, Sender};

use super::{
    block::{Block as CrateBlock, ToSerializedBlock, Transaction, Vin, Vout},
    config::{Config, Mode},
    stopper::{Done, Stopper},
    types::{
        entry::{
            BlockAtHeightHasHash, BlockAtHeightSpentOutputInTx,
            ScriptHashHasOutputsInBlockAtHeight, ToEntry, TxInBlockAtHeight, TxidVoutPrefix,
            WritableEntry,
        },
        error::Error,
        pipeline::{BlockHasEntries, BlockHasOutputs, BlockHasPrevBlockHash},
    },
    workers::new_worker_pool,
};

impl BlockHasEntries for Block {
    fn get_entries(&self, mode: Mode, height: u32) -> Vec<Box<dyn ToEntry>> {
        let hash = self.block_hash().as_byte_array().to_owned();
        let mut entries: Vec<Box<dyn ToEntry>> =
            vec![Box::new(WritableEntry::new(BlockAtHeightHasHash {
                height,
                hash,
            }))];
        if mode == Mode::Fetcher {
            return entries;
        }
        let mut script_hashes = HashMap::new();
        for tx in self.txdata.iter() {
            let entry = TxInBlockAtHeight {
                txid: tx.txid().to_byte_array(),
                height,
            };
            entries.push(Box::new(WritableEntry::new(entry)));
            for i in tx.input.iter() {
                let entry = BlockAtHeightSpentOutputInTx {
                    txid: i.previous_output.txid.to_byte_array(),
                    vout: i.previous_output.vout,
                    height,
                };
                entries.push(Box::new(WritableEntry::new(entry)));
            }
            for o in tx.output.iter() {
                let script_hash = o.script_pubkey.script_hash().as_byte_array().to_owned();
                script_hashes.entry(script_hash).or_insert_with(|| {
                    let entry = ScriptHashHasOutputsInBlockAtHeight {
                        script_hash,
                        height,
                    };
                    entries.push(Box::new(WritableEntry::new(entry)));
                });
            }
        }
        entries
    }
}

impl ToSerializedBlock for Block {
    fn to_serialized_block(&self, height: u32) -> Vec<u8> {
        let mut transactions = Vec::new();
        for tx in self.txdata.iter() {
            let tx_bytes = serialize(tx);
            let mut vins = Vec::new();
            let mut segwit = false;
            let mut vtxinwit = Vec::new();
            for vin in tx.input.iter() {
                let hash = vin.previous_output.txid.to_hex();
                if !vin.witness.is_empty() {
                    vtxinwit
                        .append(&mut vin.witness.iter().map(|w| w.to_hex()).collect::<Vec<_>>());
                    segwit = true
                }
                vins.push(Vin {
                    hash,
                    n: vin.previous_output.vout,
                    sequence: vin.sequence.0,
                    script_sig: vin.script_sig.to_hex_string(),
                })
            }
            let mut vouts = Vec::new();
            for vout in tx.output.iter() {
                vouts.push(Vout {
                    value: vout.value.to_sat(),
                    script_pub_key: vout.script_pubkey.to_hex_string(),
                })
            }
            transactions.push(Transaction {
                version: tx.version.0,
                segwit,
                coinbase: tx.is_coinbase(),
                lock_time: tx.lock_time.to_consensus_u32(),
                tx_id: tx.txid().to_hex(),
                tx_hash: Sha256dHash::hash(&tx_bytes).to_hex(),
                vtxinwit,
                vin: vins,
                vout: vouts,
            })
        }
        #[allow(clippy::expect_used)]
        serde_json::to_vec(&CrateBlock {
            height,
            version: self.header.version.to_consensus(),
            hash_prev: self.header.prev_blockhash.to_hex(),
            hash_merkle_root: self.header.merkle_root.to_hex(),
            block_time: self.header.time,
            bits: self.header.bits.to_consensus(),
            nonce: self.header.nonce,
            block_hash: self.block_hash().to_hex(),
            transaction_count: self.txdata.len(),
            transactions,
        })
        .expect("Block serialization failed unexpectedly")
    }
}

impl BlockHasPrevBlockHash for Block {
    fn get_prev_block_hash(&self) -> &BlockHash {
        &self.header.prev_blockhash
    }
}

impl BlockHasOutputs for Block {
    fn get_script_hash_outputs(&self, script_hash: [u8; 20]) -> Vec<(TxidVoutPrefix, u64)> {
        let mut outputs = Vec::new();
        for tx in self.txdata.iter() {
            for (i, o) in tx.output.iter().enumerate() {
                if script_hash == o.script_pubkey.script_hash().as_byte_array().as_ref() {
                    outputs.push((
                        TxidVoutPrefix {
                            txid: tx.txid().to_byte_array(),
                            vout: i as u32,
                        },
                        o.value.to_sat(),
                    ));
                }
            }
        }
        outputs
    }
}

pub trait BitcoinRpc<B>: Send + Clone + 'static {
    fn get_block_hash(&self, height: u32) -> Result<BlockHash, Error>;
    fn get_block(&self, hash: &BlockHash) -> Result<Box<B>, Error>;
    fn get_blockchain_height(&self) -> Result<u32, Error>;
}

#[derive(Clone)]
pub struct BitcoinClient {
    n: usize,
    config: Config,
    stopper: Stopper,
    channels: Channels,
}

struct GetBlockHash {
    height: u32,
    sender: Sender<Result<BlockHash, Error>>,
}

struct GetBlock {
    hash: BlockHash,
    sender: Sender<Result<Box<Block>, Error>>,
}

struct GetBlockchainHeight {
    sender: Sender<Result<u32, Error>>,
}

type Channel<T> = (Sender<T>, Receiver<T>);

#[derive(Clone)]
struct Channels {
    get_block_hash: Channel<GetBlockHash>,
    get_block: Channel<GetBlock>,
    get_blockchain_height: Channel<GetBlockchainHeight>,
}

impl Channels {
    fn new(n: usize) -> Self {
        Channels {
            get_block_hash: bounded(n),
            get_block: bounded(n),
            get_blockchain_height: bounded(n),
        }
    }
}

impl BitcoinClient {
    pub fn new(config: &Config, stopper: Stopper, n: usize) -> Self {
        BitcoinClient {
            n,
            config: config.clone(),
            stopper,
            channels: Channels::new(n),
        }
    }

    pub fn start(&self) -> Result<Vec<JoinHandle<Result<(), Error>>>, Error> {
        let (_tx, _rx) = unbounded();
        let client = BitcoinClientInner::new(&self.config)?;
        new_worker_pool(
            "BitcoinClient".into(),
            self.n,
            _rx,
            _tx,
            self.stopper.clone(),
            Self::worker(client, self.channels.clone()),
        )
    }

    fn worker(
        client: BitcoinClientInner,
        channels: Channels,
    ) -> impl Fn(Receiver<()>, Sender<()>, Done) -> Result<(), Error> + Clone {
        move |_, _, done| loop {
            select! {
              recv(done) -> _ => {
                return Ok(())
              },
              recv(channels.get_block_hash.1) -> msg => {
                if let Ok(GetBlockHash {height, sender}) = msg {
                  sender.send(client.get_block_hash(height))?;
                }
              },
              recv(channels.get_block.1) -> msg => {
                if let Ok(GetBlock {hash, sender}) = msg {
                  sender.send(client.get_block(&hash))?;
                }
              },
              recv(channels.get_blockchain_height.1) -> msg => {
                if let Ok(GetBlockchainHeight {sender}) = msg {
                  sender.send(client.get_blockchain_height())?;
                }
              }
            }
        }
    }
}

impl BitcoinRpc<Block> for BitcoinClient {
    fn get_block_hash(&self, height: u32) -> Result<BlockHash, Error> {
        let (tx, rx) = bounded(1);
        self.channels
            .get_block_hash
            .0
            .send(GetBlockHash { height, sender: tx })?;
        let (_, done) = self.stopper.subscribe()?;
        select! {
            recv(done) -> _ => Err(Error::Stopped),
            recv(rx) -> result => result?
        }
    }

    fn get_block(&self, hash: &BlockHash) -> Result<Box<Block>, Error> {
        let (tx, rx) = bounded(1);
        self.channels.get_block.0.send(GetBlock {
            hash: *hash,
            sender: tx,
        })?;
        let (_, done) = self.stopper.subscribe()?;
        select! {
            recv(done) -> _ => Err(Error::Stopped),
            recv(rx) -> result => result?
        }
    }

    fn get_blockchain_height(&self) -> Result<u32, Error> {
        let (tx, rx) = bounded(1);
        self.channels
            .get_blockchain_height
            .0
            .send(GetBlockchainHeight { sender: tx })?;
        let (_, done) = self.stopper.subscribe()?;
        select! {
            recv(done) -> _ => Err(Error::Stopped),
            recv(rx) -> result => result?
        }
    }
}

#[derive(Clone)]
struct BitcoinClientInner {
    client: Arc<Client>,
}

impl BitcoinClientInner {
    fn new(config: &Config) -> Result<Self, Error> {
        let client = Client::new(
            &config.rpc_address,
            Auth::UserPass(config.rpc_user.clone(), config.rpc_password.clone()),
        )?;

        Ok(BitcoinClientInner {
            client: Arc::new(client),
        })
    }
}

impl BitcoinRpc<Block> for BitcoinClientInner {
    fn get_block_hash(&self, height: u32) -> Result<BlockHash, Error> {
        Ok(self.client.get_block_hash(height as u64)?)
    }

    fn get_block(&self, hash: &BlockHash) -> Result<Box<Block>, Error> {
        Ok(Box::new(self.client.get_block(hash)?))
    }

    fn get_blockchain_height(&self) -> Result<u32, Error> {
        Ok(self.client.get_blockchain_info()?.blocks as u32)
    }
}

#[cfg(test)]
#[allow(clippy::unwrap_used)]
mod tests {
    use bitcoincore_rpc::bitcoin::{
        absolute::LockTime,
        block::{self, Header},
        transaction, Amount, CompactTarget, OutPoint, ScriptBuf, ScriptHash, Sequence, Transaction,
        TxIn, TxMerkleNode, TxOut, Txid, Witness,
    };

    use crate::indexer::{
        test_utils::{test_block_hash, test_h160_hash, test_sha256_hash},
        types::entry::FromEntry,
    };

    use super::*;

    #[test]
    fn test_get_entries() {
        let height = 2;
        let script_pubkey = ScriptBuf::new_p2sh(&ScriptHash::from_byte_array(test_h160_hash(0)));
        let tx_in = TxIn {
            previous_output: OutPoint::new(Txid::from_slice(&test_sha256_hash(0)).unwrap(), 1),
            script_sig: ScriptBuf::from_bytes(test_h160_hash(0).to_vec()),
            sequence: Sequence(0xFFFFFFFF),
            witness: Witness::new(),
        };
        let tx_out = TxOut {
            value: Amount::MIN,
            script_pubkey: script_pubkey.clone(),
        };
        let tx = Transaction {
            version: transaction::Version::ONE,
            lock_time: LockTime::ZERO,
            input: vec![tx_in],
            output: vec![tx_out],
        };

        let block = Block {
            header: Header {
                version: block::Version::ONE,
                prev_blockhash: test_block_hash(1),
                merkle_root: TxMerkleNode::from_slice(&test_sha256_hash(height)).unwrap(),
                time: 1234567890,
                bits: CompactTarget::default(),
                nonce: 0,
            },
            txdata: vec![tx],
        };

        let entries = block.get_entries(Mode::Indexer, height);

        let entry = entries.first().unwrap().to_entry();
        let e = BlockAtHeightHasHash::from_entry(entry).unwrap();
        assert_eq!(e.height, height);
        assert_eq!(e.hash, block.block_hash().as_byte_array().to_owned());

        let entry = entries.get(1).unwrap().to_entry();
        let e = TxInBlockAtHeight::from_entry(entry).unwrap();
        assert_eq!(e.txid, block.txdata[0].txid().to_byte_array());
        assert_eq!(e.height, height);

        let entry = entries.get(2).unwrap().to_entry();
        let e = BlockAtHeightSpentOutputInTx::from_entry(entry).unwrap();
        assert_eq!(e.txid, test_sha256_hash(0));
        assert_eq!(e.vout, 1);
        assert_eq!(e.height, height);

        let entry = entries.get(3).unwrap().to_entry();
        let e = ScriptHashHasOutputsInBlockAtHeight::from_entry(entry).unwrap();
        assert_eq!(e.script_hash, script_pubkey.script_hash().to_byte_array());
        assert_eq!(e.height, height);
    }
}
