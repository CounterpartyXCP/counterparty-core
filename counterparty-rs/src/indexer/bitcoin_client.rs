use std::cmp::min;
use std::collections::HashMap;
use std::iter::repeat;
use std::thread::JoinHandle;

use crate::b58::b58_encode;
use crate::utils::script_to_address;
use bitcoin::{
    consensus::serialize,
    hashes::{hex::prelude::*, ripemd160, sha256, sha256d::Hash as Sha256dHash, Hash},
    opcodes::all::{
        OP_CHECKMULTISIG, OP_CHECKSIG, OP_EQUAL, OP_HASH160, OP_PUSHNUM_1, OP_PUSHNUM_2,
        OP_PUSHNUM_3, OP_RETURN,
    },
    script::Instruction::{Op, PushBytes},
    Block, BlockHash, Script, TxOut,
};
use bitcoincore_rpc::bitcoin::script::Instruction;
use crossbeam_channel::{bounded, select, unbounded, Receiver, Sender};
use crypto::rc4::Rc4;
use crypto::symmetriccipher::SynchronousStreamCipher;

use crate::indexer::block::VinOutput;
use crate::indexer::rpc_client::{BatchRpcClient, BATCH_CLIENT};

use std::sync::Arc;

use super::{
    block::{
        Block as CrateBlock, ParsedVouts, PotentialDispenser, ToBlock, Transaction, Vin, Vout,
    },
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
                txid: tx.compute_txid().to_byte_array(),
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
    let mut rc4 = Rc4::new(key);
    let mut result: Vec<u8> = repeat(0).take(data.len()).collect();
    rc4.process(data, &mut result);
    result
}

fn is_valid_segwit_script(script: &Script) -> bool {
    if let Some(Ok(PushBytes(pb))) = script.instructions().next() {
        return pb.is_empty();
    }
    false
}

enum ParseOutput {
    Destination(String),
    Data(Vec<u8>),
}

impl ParseOutput {
    pub fn is_destination(&self) -> bool {
        matches!(self, ParseOutput::Destination(_))
    }
}

fn parse_vout(
    config: &Config,
    key: Vec<u8>,
    height: u32,
    txid: String,
    vi: usize,
    vout: &TxOut,
) -> Result<(ParseOutput, Option<PotentialDispenser>), Error> {
    let value = vout.value.to_sat();
    let is_p2sh = matches!(
        vout.script_pubkey
            .instructions()
            .collect::<Vec<_>>()
            .as_slice(),
        [Ok(Op(OP_HASH160)), Ok(PushBytes(_)), Ok(Op(OP_EQUAL))]
    );
    if vout.script_pubkey.is_op_return() {
        if let [Ok(Op(OP_RETURN)), Ok(PushBytes(pb))] = vout
            .script_pubkey
            .instructions()
            .collect::<Vec<_>>()
            .as_slice()
        {
            let bytes = arc4_decrypt(&key, pb.as_bytes());
            if bytes.starts_with(&config.prefix) {
                return Ok((
                    ParseOutput::Data(bytes[config.prefix.len()..].to_vec()),
                    Some(PotentialDispenser {
                        destination: None,
                        value: None,
                    }),
                ));
            }
        }
        Err(Error::ParseVout(format!(
            "Encountered invalid OP_RETURN script | tx: {}, vout: {}",
            txid, vi
        )))
    } else if vout.script_pubkey.instructions().last() == Some(Ok(Op(OP_CHECKSIG))) {
        let instructions: Vec<_> = vout.script_pubkey.instructions().collect();
        if instructions.len() < 3 {
            return Err(Error::ParseVout(format!(
                "Encountered invalid OP_CHECKSIG script | tx: {}, vout: {}",
                txid, vi
            )));
        }
        let pb = match instructions.get(2) {
            Some(Ok(instruction)) => match instruction {
                Instruction::Op(OP_PUSHNUM_1) => vec![1],
                Instruction::PushBytes(bytes) => bytes.as_bytes().to_vec(),
                Instruction::Op(op) => vec![op.to_u8()],
            },
            Some(Err(_)) => vec![],
            None => vec![],
        };
        let bytes = arc4_decrypt(&key, &pb);
        if bytes.len() >= config.prefix.len() && bytes[1..=config.prefix.len()] == config.prefix {
            let data_len = bytes[0] as usize;
            let data = bytes[1..=data_len].to_vec();
            return Ok((
                ParseOutput::Data(data[config.prefix.len()..].to_vec()),
                Some(PotentialDispenser {
                    destination: None,
                    value: Some(value),
                }),
            ));
        } else {
            let destination = b58_encode(
                config
                    .address_version
                    .clone()
                    .into_iter()
                    .chain(pb)
                    .collect::<Vec<_>>()
                    .as_slice(),
            );
            return Ok((
                ParseOutput::Destination(destination.clone()),
                Some(PotentialDispenser {
                    destination: Some(destination),
                    value: Some(value),
                }),
            ));
        }
    } else if vout.script_pubkey.instructions().last() == Some(Ok(Op(OP_CHECKMULTISIG))) {
        let mut chunks = Vec::new();
        #[allow(unused_assignments)]
        let mut signatures_required = 0;
        match vout
            .script_pubkey
            .instructions()
            .collect::<Vec<_>>()
            .as_slice()
        {
            [Ok(PushBytes(_pk0_pb)), Ok(PushBytes(pk1_pb)), Ok(PushBytes(pk2_pb)), Ok(PushBytes(_pk3_pb)), Ok(Op(OP_CHECKMULTISIG))] =>
            {
                signatures_required = 1;
                for pb in [pk1_pb, pk2_pb] {
                    chunks.push(pb.as_bytes().to_vec());
                }
            }
            [Ok(Op(OP_PUSHNUM_1)), Ok(PushBytes(pk1_pb)), Ok(PushBytes(pk2_pb)), Ok(Op(OP_PUSHNUM_2)), Ok(Op(OP_CHECKMULTISIG))] =>
            {
                signatures_required = 1;
                for pb in [pk1_pb, pk2_pb] {
                    chunks.push(pb.as_bytes().to_vec());
                }
            }
            [Ok(Op(OP_PUSHNUM_2)), Ok(PushBytes(pk1_pb)), Ok(PushBytes(pk2_pb)), Ok(Op(OP_PUSHNUM_2)), Ok(Op(OP_CHECKMULTISIG))] =>
            {
                signatures_required = 2;
                for pb in [pk1_pb, pk2_pb] {
                    chunks.push(pb.as_bytes().to_vec());
                }
            }
            // legacy edge case
            [Ok(Op(OP_PUSHNUM_3)), Ok(PushBytes(pk1_pb)), Ok(PushBytes(pk2_pb)), Ok(Op(OP_PUSHNUM_2)), Ok(Op(OP_CHECKMULTISIG))] =>
            {
                signatures_required = 3;
                for pb in [pk1_pb, pk2_pb] {
                    chunks.push(pb.as_bytes().to_vec());
                }
            }
            [Ok(Op(OP_PUSHNUM_1)), Ok(PushBytes(pk1_pb)), Ok(PushBytes(pk2_pb)), Ok(PushBytes(pk3_pb)), Ok(Op(OP_PUSHNUM_3)), Ok(Op(OP_CHECKMULTISIG))] =>
            {
                signatures_required = 1;
                for pb in [pk1_pb, pk2_pb, pk3_pb] {
                    chunks.push(pb.as_bytes().to_vec());
                }
            }
            [Ok(PushBytes(_pk0_pb)), Ok(PushBytes(pk1_pb)), Ok(PushBytes(pk2_pb)), Ok(PushBytes(pk3_pb)), Ok(PushBytes(_pk4_pb)), Ok(Op(OP_CHECKMULTISIG))] =>
            {
                signatures_required = 2;
                for pb in [pk1_pb, pk2_pb, pk3_pb] {
                    chunks.push(pb.as_bytes().to_vec());
                }
            }
            [Ok(Op(OP_PUSHNUM_2)), Ok(PushBytes(pk1_pb)), Ok(PushBytes(pk2_pb)), Ok(PushBytes(pk3_pb)), Ok(Op(OP_PUSHNUM_3)), Ok(Op(OP_CHECKMULTISIG))] =>
            {
                signatures_required = 2;
                for pb in [pk1_pb, pk2_pb, pk3_pb] {
                    chunks.push(pb.as_bytes().to_vec());
                }
            }
            [Ok(Op(OP_PUSHNUM_3)), Ok(PushBytes(pk1_pb)), Ok(PushBytes(pk2_pb)), Ok(PushBytes(pk3_pb)), Ok(Op(OP_PUSHNUM_3)), Ok(Op(OP_CHECKMULTISIG))] =>
            {
                signatures_required = 3;
                for pb in [pk1_pb, pk2_pb, pk3_pb] {
                    chunks.push(pb.as_bytes().to_vec());
                }
            }
            _ => {
                return Err(Error::ParseVout(format!(
                    "Encountered invalid OP_MULTISIG script | tx: {}, vout: {}",
                    txid, vi
                )));
            }
        }
        let mut enc_bytes = Vec::new();
        for chunk in chunks.iter().take(chunks.len() - 1) {
            // (No data in last pubkey.)
            if chunk.len() < 2 {
                return Err(Error::ParseVout(format!(
                    "Encountered invalid OP_MULTISIG script | tx: {}, vout: {}",
                    txid, vi
                )));
            }
            enc_bytes.extend(chunk[1..chunk.len() - 1].to_vec()); // Skip sign byte and nonce byte.
        }
        let bytes = arc4_decrypt(&key, &enc_bytes);
        if bytes.len() >= config.prefix.len() && bytes[1..=config.prefix.len()] == config.prefix {
            let chunk_len = min(bytes[0] as usize, bytes.len() - 1);
            let chunk = bytes[1..=chunk_len].to_vec();
            return Ok((
                ParseOutput::Data(chunk[config.prefix.len()..].to_vec()),
                Some(PotentialDispenser {
                    destination: None,
                    value: Some(value),
                }),
            ));
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
                                ripemd160::Hash::hash(sha256::Hash::hash(&chunk).as_byte_array())
                                    .as_byte_array()
                                    .to_vec(),
                            )
                            .collect::<Vec<_>>(),
                    )
                })
                .collect::<Vec<_>>();
            pub_key_hashes.sort();
            let pub_key_hashes_n_s = pub_key_hashes.len().to_string();
            let destination = [signatures_required.to_string()]
                .into_iter()
                .chain(pub_key_hashes.into_iter().chain([pub_key_hashes_n_s]))
                .collect::<Vec<_>>()
                .join("_");
            return Ok((
                ParseOutput::Destination(destination.clone()),
                Some(PotentialDispenser {
                    destination: Some(destination),
                    value: Some(value),
                }),
            ));
        }
    } else if is_p2sh && config.p2sh_address_supported(height) {
        if let [Ok(Op(OP_HASH160)), Ok(PushBytes(pb)), Ok(Op(OP_EQUAL))] = vout
            .script_pubkey
            .instructions()
            .collect::<Vec<_>>()
            .as_slice()
        {
            let destination = b58_encode(
                &config
                    .p2sh_address_version
                    .clone()
                    .into_iter()
                    .chain(pb.as_bytes().to_vec())
                    .collect::<Vec<_>>(),
            );
            let mut potential_dispenser = Some(PotentialDispenser {
                destination: None,
                value: None,
            });
            if config.p2sh_dispensers_supported(height) {
                potential_dispenser = Some(PotentialDispenser {
                    destination: Some(destination.clone()),
                    value: Some(value),
                });
            }
            return Ok((ParseOutput::Destination(destination), potential_dispenser));
        }
        return Err(Error::ParseVout(format!(
            "Encountered invalid P2SH script | tx: {}, vout: {}",
            txid, vi
        )));
    } else if config.segwit_supported(height) && is_valid_segwit_script(&vout.script_pubkey) {
        let destination = script_to_address(
            vout.script_pubkey.as_bytes().to_vec(),
            config.network.to_string().as_str(),
        )
        .map_err(|e| Error::ParseVout(format!("Segwit script to address failed: {}", e)))?;
        let mut potential_dispenser = Some(PotentialDispenser {
            destination: None,
            value: None,
        });
        if config.correct_segwit_txids_enabled(height) {
            potential_dispenser = Some(PotentialDispenser {
                destination: Some(destination.clone()),
                value: Some(value),
            });
        }
        return Ok((ParseOutput::Destination(destination), potential_dispenser));
    } else {
        return Err(Error::ParseVout(format!(
            "Unrecognized output type | tx: {}, vout: {}",
            txid, vi
        )));
    }
}

pub fn parse_transaction(
    tx: &bitcoin::Transaction,
    config: &Config,
    height: u32,
    parse_vouts: bool,
) -> Transaction {
    let tx_bytes = serialize(tx);
    let mut vins = Vec::new();
    let mut segwit = false;
    let mut vtxinwit: Vec<Vec<String>> = Vec::new();

    let key = if !tx.input.is_empty() {
        let mut key = tx.input[0].previous_output.txid.to_byte_array().to_vec();
        key.reverse();
        key
    } else {
        Vec::new()
    };

    let mut vouts = Vec::new();
    let mut destinations = Vec::new();
    let mut fee = 0;
    let mut btc_amount = 0;
    let mut data = Vec::new();
    let mut potential_dispensers = Vec::new();
    let mut err = None;
    for vout in tx.output.iter() {
        vouts.push(Vout {
            value: vout.value.to_sat(),
            script_pub_key: vout.script_pubkey.to_bytes(),
        });
    }
    let mut parsed_vouts: Result<ParsedVouts, String> = Err("Not Parsed".to_string());
    if parse_vouts {
        for (vi, vout) in tx.output.iter().enumerate() {
            if !config.multisig_addresses_enabled(height) {
                continue;
            }
            let output_value = vout.value.to_sat() as i64;
            fee -= output_value;
            let result = parse_vout(
                &config,
                key.clone(),
                height,
                tx.compute_txid().to_string(),
                vi,
                vout,
            );
            match result {
                Err(e) => {
                    err = Some(e);
                    break;
                }
                Ok((parse_output, potential_dispenser)) => {
                    potential_dispensers.push(potential_dispenser);
                    if data.is_empty()
                        && parse_output.is_destination()
                        && destinations != vec![config.unspendable()]
                    {
                        if let ParseOutput::Destination(destination) = parse_output {
                            destinations.push(destination);
                        }
                        btc_amount += output_value;
                    } else if parse_output.is_destination() {
                        break;
                    } else if let ParseOutput::Data(mut new_data) = parse_output {
                        data.append(&mut new_data)
                    }
                }
            }
        }
        if !config.multisig_addresses_enabled(height) {
            err = Some(Error::ParseVout(
                "Multisig addresses are not enabled".to_string(),
            ));
        }
        parsed_vouts = if let Some(e) = err {
            Err(e.to_string())
        } else {
            Ok(ParsedVouts {
                destinations,
                btc_amount,
                fee,
                data: data.clone(),
                potential_dispensers,
            })
        };
    }

    // Try to get previous transactions info if RPC is available and data is not empty
    let mut prev_txs = vec![None; tx.input.len()];
    if !data.is_empty() {
        if BATCH_CLIENT.lock().unwrap().is_none() {
            *BATCH_CLIENT.lock().unwrap() = Some(
                BatchRpcClient::new(
                    config.rpc_address.clone(),
                    config.rpc_user.clone(),
                    config.rpc_password.clone(),
                )
                .unwrap(),
            );
        }

        if let Some(batch_client) = BATCH_CLIENT.lock().unwrap().as_ref() {
            let input_txids: Vec<_> = tx
                .input
                .iter()
                .map(|vin| vin.previous_output.txid)
                .collect();
            prev_txs = batch_client
                .get_transactions(&input_txids)
                .unwrap_or_default();
        }
    }

    // Always process all inputs
    for (i, vin) in tx.input.iter().enumerate() {
        let hash = vin.previous_output.txid.to_string();

        if !vin.witness.is_empty() {
            vtxinwit.push(
                vin.witness
                    .iter()
                    .map(|w| w.as_hex().to_string())
                    .collect::<Vec<_>>(),
            );
            segwit = true;
        } else {
            vtxinwit.push(Vec::new());
        }

        let vin_info = prev_txs.get(i).and_then(|prev_tx| {
            prev_tx.as_ref().and_then(|tx| {
                let vout_idx = vin.previous_output.vout as usize;
                tx.output.get(vout_idx).map(|output| VinOutput {
                    value: output.value.to_sat(),
                    script_pub_key: output.script_pubkey.to_bytes(),
                    is_segwit: !vin.witness.is_empty(),
                })
            })
        });

        vins.push(Vin {
            hash,
            n: vin.previous_output.vout,
            sequence: vin.sequence.0,
            script_sig: vin.script_sig.to_bytes(),
            info: vin_info,
        });
    }

    let tx_id = tx.compute_txid().to_string();
    let tx_hash;
    if segwit && config.correct_segwit_txids_enabled(height) {
        tx_hash = tx_id.clone();
    } else {
        tx_hash = Sha256dHash::hash(&tx_bytes).to_string();
    }

    Transaction {
        version: tx.version.0,
        segwit,
        coinbase: tx.is_coinbase(),
        lock_time: tx.lock_time.to_consensus_u32(),
        tx_id,
        tx_hash,
        vtxinwit,
        vin: vins,
        vout: vouts,
        parsed_vouts,
    }
}

impl ToBlock for Block {
    fn to_block(&self, config: Config, height: u32) -> CrateBlock {
        let mut transactions = Vec::new();
        for tx in self.txdata.iter() {
            transactions.push(parse_transaction(tx, &config, height, true));
        }
        CrateBlock {
            height,
            version: self.header.version.to_consensus(),
            hash_prev: self.header.prev_blockhash.to_string(),
            hash_merkle_root: self.header.merkle_root.to_string(),
            block_time: self.header.time,
            bits: self.header.bits.to_consensus(),
            nonce: self.header.nonce,
            block_hash: self.block_hash().to_string(),
            transaction_count: self.txdata.len(),
            transactions,
        }
    }
}

pub fn parse_block(
    block: Block,
    config: &Config,
    height: u32,
    parse_vouts: bool,
) -> Result<CrateBlock, Error> {
    let mut transactions = Vec::new();
    for tx in block.txdata.iter() {
        transactions.push(parse_transaction(tx, config, height, parse_vouts));
    }
    Ok(CrateBlock {
        height,
        version: block.header.version.to_consensus(),
        hash_prev: block.header.prev_blockhash.to_string(),
        hash_merkle_root: block.header.merkle_root.to_string(),
        block_time: block.header.time,
        bits: block.header.bits.to_consensus(),
        nonce: block.header.nonce,
        block_hash: block.block_hash().to_string(),
        transaction_count: block.txdata.len(),
        transactions,
    })
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
                            txid: tx.compute_txid().to_byte_array(),
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
    inner: Arc<BitcoinClientInner>,
    n: usize,
    config: Config,
    stopper: Stopper,
    channels: Channels,
}

impl BitcoinClient {
    pub fn new(config: &Config, stopper: Stopper, n: usize) -> Result<Self, Error> {
        let client = Self {
            inner: Arc::new(BitcoinClientInner::new(config)?),
            n,
            config: config.clone(),
            stopper,
            channels: Channels::new(n),
        };
        Ok(client)
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
    client: Arc<BatchRpcClient>,
}

impl BitcoinClientInner {
    fn new(config: &Config) -> Result<Self, Error> {
        let client = BatchRpcClient::new(
            config.rpc_address.clone(),
            config.rpc_user.clone(),
            config.rpc_password.clone(),
        )
        .map_err(|e| Error::BitcoinRpc(format!("Failed to create BatchRpcClient: {:#?}", e)))?;

        Ok(BitcoinClientInner {
            client: Arc::new(client),
        })
    }
}

impl BitcoinRpc<Block> for BitcoinClientInner {
    fn get_block_hash(&self, height: u32) -> Result<BlockHash, Error> {
        self.client
            .get_block_hash(height)
            .map_err(|e| Error::BitcoinRpc(format!("Failed to get block hash: {:#?}", e)))
    }

    fn get_block(&self, hash: &BlockHash) -> Result<Box<Block>, Error> {
        self.client
            .get_block(hash)
            .map(Box::new)
            .map_err(|e| Error::BitcoinRpc(format!("Failed to get block: {:#?}", e)))
    }

    fn get_blockchain_height(&self) -> Result<u32, Error> {
        self.client
            .get_blockchain_info()
            .map_err(|e| Error::BitcoinRpc(format!("Failed to get blockchain info: {:#?}", e)))
            .and_then(|info| {
                info["blocks"]
                    .as_u64()
                    .ok_or_else(|| {
                        Error::BitcoinRpc("Invalid blocks field in blockchain info".into())
                    })
                    .map(|h| h as u32)
            })
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
        assert_eq!(e.txid, block.txdata[0].compute_txid().to_byte_array());
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
