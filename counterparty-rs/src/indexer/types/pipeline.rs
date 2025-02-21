use bitcoincore_rpc::bitcoin::BlockHash;
use crossbeam_channel::{Receiver, Sender};

use crate::indexer::block::{Block, ToBlock};
use crate::indexer::config::{Config, Mode};

use super::{
    entry::ToEntry,
    error::Error,
};

pub type ChanOut = (Sender<Box<Block>>, Receiver<Box<Block>>);

pub trait BlockHasEntries {
    fn get_entries(&self, mode: Mode, height: u32) -> Vec<Box<dyn ToEntry>>;
}


pub trait BlockHasPrevBlockHash {
    fn get_prev_block_hash(&self) -> &BlockHash;
}

pub trait HasHeight {
    fn get_height(&self) -> u32;
    fn get_target_height(&self) -> u32;
    fn get_rollback_height(&self) -> Option<u32>;
}

pub trait HasHash {
    fn get_hash(&self) -> &BlockHash;
}

pub trait Transition<S, I, O> {
    fn transition(self: Box<Self>, input: I) -> Result<(O, S), Error>;
}

pub struct PipelineDataInitial {
    pub height: u32,
    pub target_height: u32,
    pub rollback_height: Option<u32>,
}

impl HasHeight for PipelineDataInitial {
    fn get_height(&self) -> u32 {
        self.height
    }

    fn get_target_height(&self) -> u32 {
        self.target_height
    }

    fn get_rollback_height(&self) -> Option<u32> {
        self.rollback_height
    }
}

impl<B: BlockHasEntries> Transition<Box<PipelineDataWithBlock<B>>, (BlockHash, Box<B>), ()>
    for PipelineDataInitial
{
    fn transition(
        self: Box<Self>,
        (hash, block): (BlockHash, Box<B>),
    ) -> Result<((), Box<PipelineDataWithBlock<B>>), Error> {
        Ok((
            (),
            Box::new(PipelineDataWithBlock {
                prev: self,
                hash,
                block,
            }),
        ))
    }
}

pub struct PipelineDataWithBlock<B> {
    pub prev: Box<PipelineDataInitial>,
    pub hash: BlockHash,
    pub block: Box<B>,
}

impl<B> HasHeight for PipelineDataWithBlock<B> {
    fn get_height(&self) -> u32 {
        self.prev.get_height()
    }

    fn get_target_height(&self) -> u32 {
        self.prev.get_target_height()
    }

    fn get_rollback_height(&self) -> Option<u32> {
        self.prev.get_rollback_height()
    }
}

impl<B> HasHash for PipelineDataWithBlock<B> {
    fn get_hash(&self) -> &BlockHash {
        &self.hash
    }
}

impl<B: BlockHasEntries + ToBlock> Transition<Box<PipelineDataWithEntries<B>>, Config, ()>
    for PipelineDataWithBlock<B>
{
    fn transition(
        self: Box<Self>,
        config: Config,
    ) -> Result<((), Box<PipelineDataWithEntries<B>>), Error> {
        let height = self.get_height();
        let entries = self.block.get_entries(config.mode, height);
        let block = self.block.to_block(config, height);
        Ok((
            (),
            Box::new(PipelineDataWithEntries {
                prev: self,
                entries,
                block: Box::new(block),
            }),
        ))
    }
}

pub struct PipelineDataWithEntries<B> {
    pub prev: Box<PipelineDataWithBlock<B>>,
    pub entries: Vec<Box<dyn ToEntry>>,
    pub block: Box<Block>,
}

impl<B> HasHeight for PipelineDataWithEntries<B> {
    fn get_height(&self) -> u32 {
        self.prev.get_height()
    }

    fn get_target_height(&self) -> u32 {
        self.prev.get_target_height()
    }

    fn get_rollback_height(&self) -> Option<u32> {
        self.prev.get_rollback_height()
    }
}

impl<B> HasHash for PipelineDataWithEntries<B> {
    fn get_hash(&self) -> &BlockHash {
        self.prev.get_hash()
    }
}

impl<B> Transition<Box<PipelineDataWithoutEntries<B>>, (), Vec<Box<dyn ToEntry>>>
    for PipelineDataWithEntries<B>
{
    fn transition(
        self: Box<Self>,
        _: (),
    ) -> Result<(Vec<Box<dyn ToEntry>>, Box<PipelineDataWithoutEntries<B>>), Error> {
        Ok((
            self.entries,
            Box::new(PipelineDataWithoutEntries {
                prev: self.prev,
                block: self.block,
            }),
        ))
    }
}

pub struct PipelineDataBatch<U> {
    pub batch: Vec<Box<U>>,
    pub num_entries: usize,
}

pub struct PipelineDataWithoutEntries<B> {
    pub prev: Box<PipelineDataWithBlock<B>>,
    pub block: Box<Block>,
}

impl<B> HasHeight for PipelineDataWithoutEntries<B> {
    fn get_height(&self) -> u32 {
        self.prev.get_height()
    }

    fn get_target_height(&self) -> u32 {
        self.prev.get_target_height()
    }

    fn get_rollback_height(&self) -> Option<u32> {
        self.prev.get_rollback_height()
    }
}

impl<B> Transition<(), (), Box<Block>> for PipelineDataWithoutEntries<B> {
    fn transition(self: Box<Self>, _: ()) -> Result<(Box<Block>, ()), Error> {
        Ok((self.block, ()))
    }
}
