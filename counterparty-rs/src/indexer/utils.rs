use std::{
    cmp::min,
    collections::HashMap,
    sync::{Arc, Mutex},
    time::{Duration, Instant},
};

use crossbeam_channel::{after, select, unbounded, Receiver, Sender};
use rand::{thread_rng, Rng};
use tracing::{debug, error};
use uuid::Uuid;

use super::{stopper::Stopper, types::error::Error};

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
    stopper: Stopper,
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
    let (id, done) = stopper.subscribe()?;
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
                    },
                    recv(retry_timer) -> _ => {
                        debug!("{} Retrying after: {:?}", error_message, e);
                    },
                    recv(timeout_timer) -> _ => {
                        stopper.unsubscribe(id)?;
                        error!("{} Maximum timeout reached. Last error: {:?}", error_message, e);
                        return Err(e);
                    }
                }
            }
        }
    }
}

pub fn with_retry<T, F>(
    stopper: Stopper,
    mut operation: F,
    error_message: String,
) -> Result<T, Error>
where
    F: FnMut() -> Result<T, Error>,
{
    with_retry_custom(
        stopper,
        &mut operation,
        error_message,
        RetryConfig {
            timeout: Duration::MAX,
            ..RetryConfig::default()
        },
    )
}

pub fn timed<T, F>(m: String, f: F) -> Result<T, Error>
where
    F: FnOnce() -> Result<T, Error>,
{
    debug!("{}...", m);
    let start = Instant::now();
    let result = f();
    let duration = start.elapsed();
    debug!("{} took {:?}", m, duration);
    result
}

pub fn in_reorg_window(height: u32, target_height: u32, reorg_window: u32) -> bool {
    height >= target_height - reorg_window
}

#[derive(Clone)]
pub struct Broadcaster<T> {
    subscribers: Arc<Mutex<HashMap<Uuid, Sender<T>>>>,
}

impl<T> Broadcaster<T>
where
    T: Clone + Send + 'static,
{
    pub fn new() -> Self {
        Broadcaster {
            subscribers: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    pub fn subscribe(&self) -> Result<(Uuid, Receiver<T>), Error> {
        let (tx, rx) = unbounded();
        let id = Uuid::new_v4();
        let mut subscribers = self.subscribers.lock()?;
        subscribers.insert(id, tx);
        Ok((id, rx))
    }

    pub fn unsubscribe(&self, id: Uuid) -> Result<(), Error> {
        let mut subscribers = self.subscribers.lock()?;
        subscribers.remove(&id);
        Ok(())
    }

    pub fn broadcast(&self, message: T) -> Result<(), Error> {
        let subscribers = self.subscribers.lock()?;
        for tx in subscribers.values() {
            tx.send(message.clone()).ok();
        }
        Ok(())
    }
}
