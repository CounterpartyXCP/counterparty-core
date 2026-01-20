use std::collections::HashMap;

use bitcoin::{Block, Transaction, Txid};
use crossbeam_channel::{select, Receiver, Sender};

use crate::indexer::{
    bitcoin_client::collect_required_input_txids,
    config::Config,
    rpc_client::{build_cached_transactions_map, get_cached_transaction, BatchRpcClient},
    stopper::Stopper,
    types::{
        error::Error,
        pipeline::{HasHeight, PipelineDataWithBlock, PipelineDataWithPrefetchedTxs},
    },
    utils::with_retry,
};

pub fn new(
    config: Config,
) -> impl Fn(
    Receiver<Box<PipelineDataWithBlock<Block>>>,
    Sender<Box<PipelineDataWithPrefetchedTxs<Block>>>,
    Stopper,
) -> Result<(), Error> + Clone {
    move |rx, tx, stopper| {
        let batch_client = BatchRpcClient::new(
            config.rpc_address.clone(),
            config.rpc_user.clone(),
            config.rpc_password.clone(),
        )
        .map_err(|e| Error::BitcoinRpc(format!("Failed to create BatchRpcClient: {:#?}", e)))?;

        let (_, done) = stopper.subscribe()?;
        loop {
            select! {
                recv(done) -> _ => return Ok(()),
                recv(rx) -> result => {
                    let data = match result {
                        Ok(data) => data,
                        Err(_) => return Ok(()),
                    };

                    let height = data.get_height();
                    let (preliminary_results, all_txids, missing_txids) =
                        collect_required_input_txids(&data.block, &config, height);

                    if !missing_txids.is_empty() {
                        let _ = with_retry(
                            stopper.clone(),
                            || {
                                batch_client
                                    .get_transactions(&missing_txids)
                                    .map(|_| ())
                                    .map_err(|e| Error::BitcoinRpc(format!("{:#?}", e)))
                            },
                            format!("Error prefetching transactions for height {}", height),
                        )?;
                    }

                    let mut reveal_parent_txids: Vec<Txid> = Vec::new();
                    for (tx_idx, prelim) in preliminary_results.iter().enumerate() {
                        if !prelim.is_reveal_tx || !prelim.needs_inputs {
                            continue;
                        }
                        let tx = &data.block.txdata[tx_idx];
                        if tx.input.is_empty() {
                            continue;
                        }
                        let first_input_txid = tx.input[0].previous_output.txid;
                        let cached_prev = get_cached_transaction(&first_input_txid);
                        if let Some(Some(prev_tx)) = cached_prev {
                            if !prev_tx.input.is_empty() {
                                let parent_txid = prev_tx.input[0].previous_output.txid;
                                if get_cached_transaction(&parent_txid).is_none() {
                                    reveal_parent_txids.push(parent_txid);
                                }
                            }
                        }
                    }

                    if !reveal_parent_txids.is_empty() {
                        reveal_parent_txids.sort();
                        reveal_parent_txids.dedup();
                        let _ = with_retry(
                            stopper.clone(),
                            || {
                                batch_client
                                    .get_transactions(&reveal_parent_txids)
                                    .map(|_| ())
                                    .map_err(|e| Error::BitcoinRpc(format!("{:#?}", e)))
                            },
                            format!("Error prefetching reveal parent transactions for height {}", height),
                        )?;
                    }

                    let mut txids_for_cache = all_txids.clone();
                    txids_for_cache.extend(reveal_parent_txids.into_iter());
                    txids_for_cache.sort();
                    txids_for_cache.dedup();

                    let prev_txs_cache: HashMap<Txid, Option<Transaction>> =
                        build_cached_transactions_map(&txids_for_cache);

                    let next_data = Box::new(PipelineDataWithPrefetchedTxs {
                        prev: data,
                        prev_txs_cache,
                    });

                    if tx.send(next_data).is_err() {
                        return Ok(());
                    }
                }
            }
        }
    }
}
