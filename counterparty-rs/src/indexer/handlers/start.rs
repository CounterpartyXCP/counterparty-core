use std::{thread::JoinHandle, time::Instant};

use crate::indexer::{
    bitcoin_client::{BitcoinClient, BitcoinRpc},
    config::Config,
    database::DatabaseOps,
    stopper::Stopper,
    types::{error::Error, pipeline::ChanOut},
    utils::timed,
    workers::{consumer, extractor, fetcher, new_worker_pool, orderer, producer, reporter, writer},
};
use crossbeam_channel::{bounded, unbounded};
use tracing::info;

pub fn new<D>(
    parallelism: usize,
    config: Config,
    client: BitcoinClient,
    stopper: Stopper,
    chan: ChanOut,
    db: D,
) -> Result<Vec<JoinHandle<Result<(), Error>>>, Error>
where
    D: DatabaseOps,
{
    if stopper.stopped()? {
        return Err(Error::Stopped);
    }

    let db_start_height = timed("First database op: GetMaxBlockHeight".into(), || {
        db.get_max_block_height()
    })? + 1;
    let mut start_height = db_start_height;
    if let Some(config_start_height) = config.start_height {
        start_height = config_start_height;
        db.write_batch(|batch| db.rollback_to_height(batch, start_height - 1))?;
    }
    let reorg_window = 50;

    let start = Instant::now();

    let capacity = 32;
    let (tx_end, rx_start) = unbounded();
    let (tx_c1, rx_c1) = bounded(capacity);
    let (tx_c2, rx_c2) = bounded(capacity);
    let (tx_c3, rx_c3) = bounded(capacity);
    let (tx_c4, rx_c4) = bounded(capacity);
    let (tx_c5, rx_c5) = bounded(capacity);

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
        extractor::new(config.clone()),
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
        writer::new(db.clone(), config.clone(), start_height, reorg_window, 1),
    )?);

    handles.append(&mut new_worker_pool(
        "Reporter".into(),
        1,
        rx_c5.clone(),
        chan.0,
        stopper.clone(),
        reporter::new(
            start,
            start_height,
            rx_c1,
            rx_c2,
            rx_c3,
            rx_c4,
            rx_c5,
            chan.1.clone(),
        ),
    )?);

    if config.consume_blocks {
        handles.append(&mut new_worker_pool(
            "Consumer".into(),
            1,
            chan.1,
            tx_end,
            stopper.clone(),
            consumer::new(),
        )?);
    }

    info!("{:?} started", config.mode);
    Ok(handles)
}
