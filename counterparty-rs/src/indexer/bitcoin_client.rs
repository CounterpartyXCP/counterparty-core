use std::{collections::HashMap, sync::Arc, thread::JoinHandle};

use crate::b58::b58_encode;
use crate::utils::script_to_address;
use bitcoin::hashes::hex::ToHex;
use bitcoincore_rpc::{
    bitcoin::{
        consensus::serialize,
        hashes::{ripemd160, sha256, sha256d::Hash as Sha256dHash, Hash},
        opcodes::all::{
            OP_CHECKMULTISIG, OP_CHECKSIG, OP_DUP, OP_EQUAL, OP_EQUALVERIFY, OP_HASH160,
        },
        script::Instruction::{Op, PushBytes},
        Block, BlockHash, Script,
    },
    Auth, Client, RpcApi,
};
use crossbeam_channel::{bounded, select, unbounded, Receiver, Sender};
use crypto::buffer::{RefReadBuffer, RefWriteBuffer, WriteBuffer};
use crypto::rc4::Rc4;
use crypto::symmetriccipher::Decryptor;
use tracing::warn;

use super::{
    block::{Block as CrateBlock, ToBlock, Transaction, Vin, Vout},
    config::{Config, Mode},
    stopper::Stopper,
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

fn arc4_decrypt(key: &[u8], data: &[u8]) -> Vec<u8> {
    let mut read_buf = RefReadBuffer::new(data);
    let mut buf = Vec::new();
    let mut write_buf = RefWriteBuffer::new(&mut buf);
    Rc4::new(&key)
        .decrypt(&mut read_buf, &mut write_buf, false)
        .expect("RC4 decryption failed");
    write_buf
        .take_remaining()
        .iter()
        .map(|&i| i)
        .collect::<Vec<_>>()
}

fn is_valid_segwit_script(config: &Config, script: &Script, height: u32) -> bool {
    if config.segwit_supported(height) {
        if let Some(Ok(PushBytes(pb))) = script.instructions().next() {
            if pb.len() == 0 {
                return true;
            }
        }
    }
    return false;
}

impl ToBlock for Block {
    fn to_block(&self, config: Config, height: u32) -> CrateBlock {
        let mut transactions = Vec::new();
        for tx in self.txdata.iter() {
            let tx_bytes = serialize(tx);
            let mut vins = Vec::new();
            let mut segwit = false;
            let mut vtxinwit = Vec::new();
            let mut key = Vec::new();
            for vin in tx.input.iter() {
                if key.len() == 0 {
                    key = vin.previous_output.txid.to_byte_array().to_vec();
                }
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
                    script_sig: vin.script_sig.to_bytes(),
                })
            }
            let mut vouts = Vec::new();
            let mut fee = 0;
            for (vi, vout) in tx.output.iter().enumerate() {
                vouts.push(Vout {
                    value: vout.value.to_sat(),
                    script_pub_key: vout.script_pubkey.to_bytes(),
                });

                let output_value = vout.value.to_sat();
                let fee = fee - output_value;
                let mut destination = None;
                let mut data = None;
                if vout.script_pubkey.is_op_return() {
                    for result in vout.script_pubkey.instructions().into_iter() {
                        if let Ok(i) = result {
                            if let PushBytes(pb) = i {
                                let bytes = arc4_decrypt(&key, pb.as_bytes());
                                if bytes.starts_with(&config.prefix) {
                                    data = Some(bytes[config.prefix.len()..].to_vec());
                                }
                            }
                        } else {
                            warn!(
                                "Encountered invalid OP_RETURN script | tx: {}, vout: {}",
                                tx.txid().to_hex(),
                                vi
                            );
                            continue;
                        }
                    }
                } else if let Some(Ok(Op(OP_CHECKSIG))) = vout.script_pubkey.instructions().next() {
                    match vout
                        .script_pubkey
                        .instructions()
                        .collect::<Vec<_>>()
                        .as_slice()
                    {
                        [Ok(Op(OP_DUP)), Ok(Op(OP_HASH160)), Ok(PushBytes(pb)), Ok(Op(OP_EQUALVERIFY)), Ok(Op(OP_CHECKSIG))] =>
                        {
                            let bytes = arc4_decrypt(&key, pb.as_bytes());
                            if bytes[1..=config.prefix.len()] == config.prefix {
                                let chunk_len = bytes[0] as usize;
                                let chunk = bytes[1..=chunk_len].to_vec();
                                data = Some(chunk[config.prefix.len()..].to_vec());
                            } else {
                                destination = Some(b58_encode(
                                    config
                                        .address_version
                                        .clone()
                                        .into_iter()
                                        .chain(bytes)
                                        .collect::<Vec<_>>()
                                        .as_slice(),
                                ));
                            }
                        }
                        _ => {
                            warn!(
                                "Encountered invalid OP_CHECKSIG script | tx: {}, vout: {}",
                                tx.txid().to_hex(),
                                vi
                            );
                            continue;
                        }
                    }
                } else if vout.script_pubkey.is_multisig() {
                    let mut chunks = Vec::new();
                    let mut signatures_required = 0;
                    match vout
                        .script_pubkey
                        .instructions()
                        .collect::<Vec<_>>()
                        .as_slice()
                    {
                        [Ok(PushBytes(sigs_req_pb)), Ok(PushBytes(pk1_pb)), Ok(PushBytes(pk2_pb)), Ok(PushBytes(pk3_pb)), Ok(Op(OP_CHECKMULTISIG))] =>
                        {
                            signatures_required = u32::from_be_bytes(
                                sigs_req_pb
                                    .as_bytes()
                                    .try_into()
                                    .expect("Invalid signatures required byte encountered"),
                            );
                            for pb in [pk1_pb, pk2_pb, pk3_pb] {
                                chunks.push(pb.as_bytes().to_vec());
                            }
                        }
                        [Ok(PushBytes(sigs_req_pb)), Ok(PushBytes(pk1_pb)), Ok(PushBytes(pk2_pb)), Ok(PushBytes(pk3_pb)), Ok(PushBytes(pk4_pb)), Ok(Op(OP_CHECKMULTISIG))] =>
                        {
                            signatures_required = u32::from_be_bytes(
                                sigs_req_pb
                                    .as_bytes()
                                    .try_into()
                                    .expect("Invalid signatures required byte encountered"),
                            );
                            for pb in [pk1_pb, pk2_pb, pk3_pb, pk4_pb] {
                                chunks.push(pb.as_bytes().to_vec());
                            }
                        }
                        _ => {
                            warn!(
                                "Encountered invalid OP_MULTISIG script | tx: {}, vout: {}",
                                tx.txid().to_hex(),
                                vi
                            );
                            continue;
                        }
                    }
                    let mut enc_bytes = Vec::new();
                    for chunk in chunks.iter() {
                        enc_bytes.extend(chunk[1..chunk.len() - 1].to_vec());
                    }
                    let bytes = arc4_decrypt(&key, &enc_bytes);
                    if bytes[1..=config.prefix.len()] == config.prefix {
                        let chunk_len = bytes[0] as usize;
                        let chunk = bytes[1..=chunk_len].to_vec();
                        data = Some(chunk[config.prefix.len()..].to_vec());
                    } else {
                        let mut pub_key_hashes = chunks
                            .into_iter()
                            .map(|chunk| {
                                b58_encode(
                                    &config
                                        .address_version
                                        .clone()
                                        .into_iter()
                                        .chain(
                                            ripemd160::Hash::hash(
                                                sha256::Hash::hash(&chunk).as_byte_array(),
                                            )
                                            .as_byte_array()
                                            .to_vec(),
                                        )
                                        .collect::<Vec<_>>(),
                                )
                            })
                            .collect::<Vec<_>>();
                        pub_key_hashes.sort();
                        let pub_key_hashes_n_s = pub_key_hashes.len().to_string();
                        destination = Some(
                            [signatures_required.to_string()]
                                .into_iter()
                                .chain(pub_key_hashes.into_iter().chain([pub_key_hashes_n_s]))
                                .collect::<Vec<_>>()
                                .join("_"),
                        )
                    }
                } else if config.p2sh_address_supported(height) {
                    match vout
                        .script_pubkey
                        .instructions()
                        .collect::<Vec<_>>()
                        .as_slice()
                    {
                        [Ok(Op(OP_HASH160)), Ok(PushBytes(pb)), Ok(Op(OP_EQUAL))] => {
                            destination = Some(b58_encode(
                                &config
                                    .p2sh_address_version
                                    .clone()
                                    .into_iter()
                                    .chain(pb.as_bytes().to_vec())
                                    .collect::<Vec<_>>(),
                            ));
                        }
                        _ => {
                            warn!(
                                "Encountered invalid P2SH script | tx: {}, vout: {}",
                                tx.txid().to_hex(),
                                vi
                            );
                            continue;
                        }
                    }
                } else if is_valid_segwit_script(&config, &vout.script_pubkey, height) {
                    destination = Some(
                        script_to_address(
                            vout.script_pubkey.as_bytes().to_vec(),
                            config.network.to_string().as_str(),
                        )
                        .expect("Segwit script to address failed"),
                    );
                }
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
        CrateBlock {
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
        }
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

#[derive(Clone)]
pub struct BitcoinClient {
    n: usize,
    config: Config,
    stopper: Stopper,
    channels: Channels,
}

impl BitcoinClient {
    pub fn new(config: &Config, stopper: Stopper, n: usize) -> Result<Self, Error> {
        Ok(BitcoinClient {
            n,
            config: config.clone(),
            stopper,
            channels: Channels::new(n),
        })
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
    ) -> impl Fn(Receiver<()>, Sender<()>, Stopper) -> Result<(), Error> + Clone {
        move |_, _, stopper| loop {
            let (_, done) = stopper.subscribe()?;
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
        let (id, done) = self.stopper.subscribe()?;
        select! {
            recv(done) -> _ => Err(Error::Stopped),
            recv(rx) -> result => {
                self.stopper.unsubscribe(id)?;
                result?
            }
        }
    }

    fn get_block(&self, hash: &BlockHash) -> Result<Box<Block>, Error> {
        let (tx, rx) = bounded(1);
        self.channels.get_block.0.send(GetBlock {
            hash: *hash,
            sender: tx,
        })?;
        let (id, done) = self.stopper.subscribe()?;
        select! {
            recv(done) -> _ => Err(Error::Stopped),
            recv(rx) -> result => {
                self.stopper.unsubscribe(id)?;
                result?
            }
        }
    }

    fn get_blockchain_height(&self) -> Result<u32, Error> {
        let (tx, rx) = bounded(1);
        self.channels
            .get_blockchain_height
            .0
            .send(GetBlockchainHeight { sender: tx })?;
        let (id, done) = self.stopper.subscribe()?;
        select! {
            recv(done) -> _ => Err(Error::Stopped),
            recv(rx) -> result => {
                self.stopper.unsubscribe(id)?;
                result?
            }
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
