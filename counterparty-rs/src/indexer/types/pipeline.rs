use bitcoincore_rpc::bitcoin::BlockHash;

use crate::indexer::{block::ToSerializedBlock, config::Mode};

use super::{
    entry::{ToEntry, TxidVoutPrefix},
    error::Error,
};

pub trait BlockHasEntries {
    fn get_entries(&self, mode: Mode, height: u32) -> Vec<Box<dyn ToEntry>>;
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

pub trait Transition<S, I, O> {
    fn transition(self: Box<Self>, input: I) -> Result<(O, S), Error>;
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
                prev: self, // Assuming PipelineDataInitial is Clone
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

impl<B: BlockHasEntries + ToSerializedBlock> Transition<Box<PipelineDataWithEntries<B>>, Mode, ()>
    for PipelineDataWithBlock<B>
{
    fn transition(
        self: Box<Self>,
        mode: Mode,
    ) -> Result<((), Box<PipelineDataWithEntries<B>>), Error> {
        let height = self.get_height();
        let entries = self.block.get_entries(mode, height);
        let serialized_block = self.block.to_serialized_block(height);
        Ok((
            (),
            Box::new(PipelineDataWithEntries {
                prev: self,
                entries,
                serialized_block,
            }),
        ))
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
    pub serialized_block: Vec<u8>,
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
                serialized_block: self.serialized_block,
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
    pub serialized_block: Vec<u8>,
}

impl<B> HasHeight for PipelineDataWithoutEntries<B> {
    fn get_height(&self) -> u32 {
        self.prev.get_height()
    }

    fn get_target_height(&self) -> u32 {
        self.prev.get_target_height()
    }
}

impl<B> Transition<(), (), Vec<u8>> for PipelineDataWithoutEntries<B> {
    fn transition(self: Box<Self>, _: ()) -> Result<(Vec<u8>, ()), Error> {
        Ok((self.serialized_block, ()))
    }
}
