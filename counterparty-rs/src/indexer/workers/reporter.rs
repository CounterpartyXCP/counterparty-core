use std::{
    collections::VecDeque,
    time::{Duration, Instant},
};

use crossbeam_channel::{select, Receiver, Sender};
use tracing::info;

use crate::indexer::{
    constants::CP_HEIGHT,
    types::{
        error::Error,
        pipeline::{
            BlockHasEntries, Done, HasBlock, HasHeight, PipelineDataBatch, PipelineDataInitial,
        },
    },
};

pub fn new<C, D, E, F, T, U, B>(
    start: Instant,
    start_height: u32,
    rx_c1: Receiver<C>,
    rx_c2: Receiver<D>,
    rx_c3: Receiver<E>,
    rx_c4: Receiver<F>,
) -> impl Fn(Receiver<Box<PipelineDataBatch<T>>>, Sender<Box<B>>, Done) -> Result<(), Error> + Clone
where
    T: HasHeight + HasBlock<B, U, PipelineDataInitial>,
    B: BlockHasEntries,
{
    move |rx, tx, done| {
        let mut last_round_time = start;
        let mut prev_height = start_height - 1;
        let mut max_height = 0;
        let mut bpss = VecDeque::new();
        let mut epss = VecDeque::new();
        let blocks_window = 500;
        let eps_window = 60;
        let mut total_num_entries = 0;
        let mut num_blocks = 0;
        let mut num_entries = 0;
        loop {
            select! {
                recv(done) -> _ => return Ok(()),
                recv(rx) -> result => {
                  let data = match result {
                      Ok(data) => data,
                      Err(_) => return Ok(()),
                  };
                  total_num_entries += data.num_entries as i64;
                  num_entries += data.num_entries;
                  let mut height = prev_height;
                  for data in data.batch.into_iter() {
                      if data.get_height() != height + 1 {
                          return Err(Error::OrderInvariant(height, data.get_height()));
                      }
                      height = data.get_height();
                      max_height = data.get_target_height();
                      let (b, _) = data.take_block();
                      if tx.send(b).is_err() {
                        return Ok(())
                      }
                  }
                  num_blocks += height - prev_height;
                  prev_height = height;
                  let total_elapsed = start.elapsed().as_secs();
                  if last_round_time.elapsed() < Duration::from_secs(1) {
                      continue;
                  }
                  let elapsed = last_round_time.elapsed().as_secs_f64();
                  let bps = num_blocks as f64 / elapsed;
                  bpss.push_back(bps);
                  if bpss.len() > blocks_window {
                      bpss.pop_front();
                  }
                  let avg_bps = bpss.iter().sum::<f64>() / bpss.len() as f64;

                  let eps = num_entries as f64 / elapsed;
                  epss.push_back(eps);
                  if epss.len() > eps_window {
                      epss.pop_front();
                  }
                  let avg_eps = epss.iter().sum::<f64>() / epss.len() as f64;

                  let progress = ((height - CP_HEIGHT) as f64 / (max_height - CP_HEIGHT) as f64) * 100.0;
                  let remaining_blocks = max_height - height;
                  let estimated_secs_remaining = if avg_bps > 0.0 {
                      remaining_blocks as f64 / avg_bps
                  } else {
                      0.0
                  };
                  let remaining_hrs = estimated_secs_remaining / 3600.0;
                  let progress_formatted = format!("{:.2}", progress);
                  let avg_bps_formatted = format!("{:.2}", avg_bps);
                  let avg_eps_formatted = format!("{:.2}", avg_eps);
                  let total_elapsed_formatted = format!("{:.2}", total_elapsed);
                  let remaining_hrs_formatted = format!("{:.2}", remaining_hrs);

                  info!(
                      height = height,
                      max_height = max_height,
                      progress = progress_formatted,
                      avg_bps = avg_bps_formatted,
                      avg_eps = avg_eps_formatted,
                      total_elapsed = total_elapsed_formatted,
                      remaining_hrs = remaining_hrs_formatted,
                      rx_c1_len = rx_c1.len(),
                      rx_c2_len = rx_c2.len(),
                      rx_c3_len = rx_c3.len(),
                      rx_c4_len = rx_c4.len(),
                      total_num_entries = total_num_entries,
                      "Write"
                  );
                  last_round_time = Instant::now();
                  num_blocks = 0;
                  num_entries = 0;
              }
            }
        }
    }
}
