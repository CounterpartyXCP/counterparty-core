use std::{thread::JoinHandle, time::Instant};

use crate::indexer::{
    bitcoin_client::{BitcoinClient, BitcoinRpc},
    database::DatabaseOps,
    types::{error::Error, pipeline::Stopper},
    utils::timed,
    workers::{extractor, fetcher, new_worker_pool, orderer, producer, reporter, writer},
};
use bitcoincore_rpc::bitcoin::Block;
use crossbeam_channel::{bounded, unbounded, Sender};
use tracing::info;

pub fn new<D>(
    parallelism: usize,
    client: BitcoinClient,
    stopper: Stopper,
    tx_block: Sender<Box<Block>>,
    db: D,
) -> Result<Vec<JoinHandle<Result<(), Error>>>, Error>
where
    D: DatabaseOps,
{
    if stopper.stopped() {
        return Err(Error::Stopped);
    }

    let start_height = timed("First database op: GetMaxBlockHeight".into(), || {
        db.get_max_block_height()
    })? + 1;
    let reorg_window = 50;

    let start = Instant::now();

    let capacity = 32;
    let (_, rx_start) = unbounded();
    let (tx_c1, rx_c1) = bounded(capacity);
    let (tx_c2, rx_c2) = bounded(capacity);
    let (tx_c3, rx_c3) = bounded(capacity);
    let (tx_c4, rx_c4) = bounded(capacity);
    let (tx_c5, rx_c5) = unbounded();

    let mut handles = Vec::new();
    let target_block = timed(
        "First Bitcoin client op: GetBlockchainHeight".into(),
        || client.get_blockchain_height(),
    )?;
    info!("Starting at block height: {}", start_height);
    info!("Targeting block height: {}", target_block);

    handles.append(&mut new_worker_pool(
        "Producer".into(),
        1,
        rx_start,
        tx_c1,
        stopper.clone(),
        producer::new(client.clone(), db.clone(), start_height, reorg_window),
    )?);

    handles.append(&mut new_worker_pool(
        "Fetcher".into(),
        parallelism / 2,
        rx_c1.clone(),
        tx_c2.clone(),
        stopper.clone(),
        fetcher::new(client.clone()),
    )?);

    handles.append(&mut new_worker_pool(
        "Extractor".into(),
        parallelism / 4,
        rx_c2.clone(),
        tx_c3.clone(),
        stopper.clone(),
        extractor::new(),
    )?);

    handles.append(&mut new_worker_pool(
        "Orderer".into(),
        1,
        rx_c3.clone(),
        tx_c4.clone(),
        stopper.clone(),
        orderer::new(start_height),
    )?);

    handles.append(&mut new_worker_pool(
        "Writer".into(),
        1,
        rx_c4.clone(),
        tx_c5.clone(),
        stopper.clone(),
        writer::new(db.clone(), start_height, reorg_window, 1),
    )?);

    handles.append(&mut new_worker_pool(
        "Reporter".into(),
        1,
        rx_c5.clone(),
        tx_block.clone(),
        stopper.clone(),
        reporter::new(start, start_height, rx_c1, rx_c2, rx_c3, rx_c4),
    )?);

    info!("Indexer started");
    Ok(handles)
}
