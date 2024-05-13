use std::{
    cmp::min,
    collections::HashMap,
    sync::{Arc, Mutex},
    time::{Duration, Instant},
};

use crossbeam_channel::{after, select, unbounded, Receiver, Sender};
use rand::{thread_rng, Rng};
use tracing::{debug, error, info};

use super::types::{error::Error, pipeline::Done};

#[derive(Debug, Clone)]
pub struct RetryConfig {
    pub base_delay: Duration,
    pub max_delay: Duration,
    pub timeout: Duration,
}

impl Default for RetryConfig {
    fn default() -> Self {
        RetryConfig {
            base_delay: Duration::from_millis(500),
            max_delay: Duration::from_secs(10),
            timeout: Duration::from_secs(60),
        }
    }
}

pub fn with_retry_custom<T, F>(
    done: Done,
    mut operation: F,
    error_message: String,
    config: RetryConfig,
) -> Result<T, Error>
where
    F: FnMut() -> Result<T, Error>,
{
    let mut rng = thread_rng();
    let timeout_timer = after(config.timeout);
    let mut attempts = 0;
    loop {
        match operation() {
            Ok(result) => return Ok(result),
            Err(e) => {
                let delay = config.base_delay * 2_u32.checked_pow(attempts).unwrap_or(u32::MAX);
                let jitter = rng.gen_range(0.5..1.5);
                let delay_with_jitter =
                    Duration::from_secs((delay.as_secs_f64() * jitter).round() as u64);
                attempts += 1;

                let retry_timer = after(min(delay_with_jitter, config.max_delay));

                select! {
                    recv(done) -> _ => {
                        return Err(Error::OperationCancelled(error_message));
                    }
                    recv(retry_timer) -> _ => {
                        debug!("{} Retrying after error: {:?}", error_message, e);
                    }
                    recv(timeout_timer) -> _ => {
                        error!("{} Maximum timeout reached. Last error: {:?}", error_message, e);
                        return Err(e);
                    }
                }
            }
        }
    }
}

pub fn with_retry<T, F>(done: Done, mut operation: F, error_message: String) -> Result<T, Error>
where
    F: FnMut() -> Result<T, Error>,
{
    with_retry_custom(done, &mut operation, error_message, RetryConfig::default())
}

pub fn timed<T, F>(m: String, f: F) -> Result<T, Error>
where
    F: FnOnce() -> Result<T, Error>,
{
    info!("{}...", m);
    let start = Instant::now();
    let result = f();
    let duration = start.elapsed();
    info!("{} took {:?}", m, duration);
    result
}

pub fn in_reorg_window(height: u32, target_height: u32, reorg_window: u32) -> bool {
    height >= target_height - reorg_window
}

#[derive(Clone)]
pub struct Broadcaster<T> {
    subscribers: Arc<Mutex<HashMap<usize, Sender<T>>>>,
    next_id: Arc<Mutex<usize>>,
}

impl<T> Broadcaster<T>
where
    T: Clone + Send + 'static,
{
    pub fn new() -> Self {
        Broadcaster {
            subscribers: Arc::new(Mutex::new(HashMap::new())),
            next_id: Arc::new(Mutex::new(0)),
        }
    }

    pub fn subscribe(&self) -> Result<(usize, Receiver<T>), Error> {
        let (tx, rx) = unbounded();
        let mut id_guard = self.next_id.lock()?;
        let id = *id_guard;
        *id_guard += 1;
        self.subscribers.lock()?.insert(id, tx);
        Ok((id, rx))
    }

    pub fn broadcast(&self, message: T) -> Result<(), Error> {
        let subscribers = self.subscribers.lock()?;
        for tx in subscribers.values() {
            tx.send(message.clone()).ok();
        }
        Ok(())
    }
}
