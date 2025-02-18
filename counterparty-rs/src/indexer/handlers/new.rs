use std::cmp::max;

use crossbeam_channel::bounded;
use tracing::{info, debug};

use crate::indexer::{
    bitcoin_client::BitcoinClient, config::Config, database::Database, logging::setup_logging,
    stopper::Stopper, types::error::Error, Indexer,
};

pub fn new(config: Config) -> Result<Indexer, Error> {
    setup_logging(&config);

    info!("Indexer initializing...");
    let parallelism = std::thread::available_parallelism()?;
    let stopper = Stopper::new();
    let client = BitcoinClient::new(&config, stopper.clone(), parallelism.into())?;
    let handles = client.start()?;
    debug!("Connecting to database: {}", config.db_dir);
    let db = Database::new(config.db_dir.to_string())?;
    debug!("Connected");
    let chan = bounded(64);
    debug!("Initialized");

    Ok(Indexer {
        config,
        parallelism: max(parallelism.into(), 4),
        stopper,
        client,
        db,
        chan,
        handles,
    })
}
