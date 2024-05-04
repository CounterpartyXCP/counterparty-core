use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
};

use bitcoincore_rpc::bitcoin::BlockHash;
use crossbeam_channel::Receiver;

use crate::indexer::utils::Broadcaster;

use super::{
    entry::{ToEntry, TxidVoutPrefix},
    error::Error,
};

pub type Done = Receiver<()>;

#[derive(Clone)]
pub struct Stopper {
    broadcaster: Broadcaster<()>,
    stopped: Arc<AtomicBool>,
}

impl Stopper {
    #[allow(clippy::new_without_default)]
    pub fn new() -> Self {
        Stopper {
            broadcaster: Broadcaster::new(),
            stopped: Arc::new(AtomicBool::new(false)),
        }
    }

    pub fn stop(&self) -> Result<(), Error> {
        self.stopped.store(true, Ordering::SeqCst);
        self.broadcaster.broadcast(())
    }

    pub fn subscribe(&self) -> Result<(usize, Done), Error> {
        self.broadcaster.subscribe()
    }

    pub fn stopped(&self) -> bool {
        self.stopped.load(Ordering::SeqCst)
    }
}

pub trait BlockHasEntries {
    fn get_entries(&self, height: u32) -> Vec<Box<dyn ToEntry>>;
}

pub trait BlockHasOutputs {
    fn get_script_hash_outputs(&self, script_hash: [u8; 20]) -> Vec<(TxidVoutPrefix, u64)>;
}

pub trait BlockHasPrevBlockHash {
    fn get_prev_block_hash(&self) -> &BlockHash;
}

pub trait HasHeight {
    fn get_height(&self) -> u32;
    fn get_target_height(&self) -> u32;
}

pub trait HasHash {
    fn get_hash(&self) -> &BlockHash;
}

pub trait SetBlock<B: BlockHasEntries, U> {
    fn set_block(self: Box<Self>, hash: BlockHash, block: Box<B>) -> Box<U>;
}

pub trait HasBlock<B: BlockHasEntries, U, S> {
    fn with_entries(self: Box<Self>) -> Box<U>;
    fn take_block(self) -> (Box<B>, Box<S>);
}

pub trait HasEntries<U> {
    fn take_entries(self) -> (Vec<Box<dyn ToEntry>>, Box<U>);
}

pub struct PipelineDataInitial {
    pub height: u32,
    pub target_height: u32,
}

impl HasHeight for PipelineDataInitial {
    fn get_height(&self) -> u32 {
        self.height
    }

    fn get_target_height(&self) -> u32 {
        self.target_height
    }
}

impl<B: BlockHasEntries> SetBlock<B, PipelineDataWithBlock<B>> for PipelineDataInitial {
    fn set_block(self: Box<Self>, hash: BlockHash, block: Box<B>) -> Box<PipelineDataWithBlock<B>> {
        Box::new(PipelineDataWithBlock {
            prev: self,
            hash,
            block,
        })
    }
}

pub struct PipelineDataWithBlock<B> {
    pub prev: Box<PipelineDataInitial>,
    pub hash: BlockHash,
    pub block: Box<B>,
}

impl<B: BlockHasEntries> HasBlock<B, PipelineDataWithEntries<B>, PipelineDataInitial>
    for PipelineDataWithBlock<B>
{
    fn with_entries(self: Box<Self>) -> Box<PipelineDataWithEntries<B>> {
        let entries = self.block.get_entries(self.get_height());
        Box::new(PipelineDataWithEntries {
            prev: self,
            entries,
        })
    }

    fn take_block(self) -> (Box<B>, Box<PipelineDataInitial>) {
        (self.block, self.prev)
    }
}

impl<B> HasHeight for PipelineDataWithBlock<B> {
    fn get_height(&self) -> u32 {
        self.prev.get_height()
    }

    fn get_target_height(&self) -> u32 {
        self.prev.get_target_height()
    }
}

impl<B> HasHash for PipelineDataWithBlock<B> {
    fn get_hash(&self) -> &BlockHash {
        &self.hash
    }
}

pub struct PipelineDataWithEntries<B> {
    pub prev: Box<PipelineDataWithBlock<B>>,
    pub entries: Vec<Box<dyn ToEntry>>,
}

impl<B> HasHeight for PipelineDataWithEntries<B> {
    fn get_height(&self) -> u32 {
        self.prev.get_height()
    }

    fn get_target_height(&self) -> u32 {
        self.prev.get_target_height()
    }
}

impl<B> HasHash for PipelineDataWithEntries<B> {
    fn get_hash(&self) -> &BlockHash {
        self.prev.get_hash()
    }
}

impl<B> HasEntries<PipelineDataWithBlock<B>> for PipelineDataWithEntries<B> {
    fn take_entries(self) -> (Vec<Box<dyn ToEntry>>, Box<PipelineDataWithBlock<B>>) {
        (self.entries, self.prev)
    }
}

pub struct PipelineDataBatch<U> {
    pub batch: Vec<Box<U>>,
    pub num_entries: usize,
}
