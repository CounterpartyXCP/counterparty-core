use super::{types::error::Error, utils::Broadcaster};
use crossbeam_channel::Receiver;
use std::sync::{Arc, Mutex};
use uuid::Uuid;

pub type Done = Receiver<()>;

#[derive(Clone)]
pub struct Stopper {
    broadcaster: Broadcaster<()>,
    is_stopped: Arc<Mutex<bool>>,
}

impl Stopper {
    pub fn new() -> Self {
        Stopper {
            broadcaster: Broadcaster::new(),
            is_stopped: Arc::new(Mutex::new(false)),
        }
    }

    pub fn stop(&self) -> Result<(), Error> {
        let mut stopped_guard = self.is_stopped.lock()?;
        if *stopped_guard {
            return Ok(());
        }
        *stopped_guard = true;
        self.broadcaster.broadcast(())
    }

    pub fn subscribe(&self) -> Result<(Uuid, Done), Error> {
        let stopped = self.is_stopped.lock()?;
        if *stopped {
            return Err(Error::Stopped);
        }
        self.broadcaster.subscribe()
    }

    pub fn unsubscribe(&self, id: Uuid) -> Result<(), Error> {
        self.broadcaster.unsubscribe(id)
    }

    pub fn stopped(&self) -> Result<bool, Error> {
        let stopped = self.is_stopped.lock()?;
        Ok(*stopped)
    }
}
