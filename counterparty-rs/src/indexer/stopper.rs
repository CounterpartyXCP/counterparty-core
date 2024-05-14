use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
};

use crossbeam_channel::Receiver;

use super::{types::error::Error, utils::Broadcaster};

pub type Done = Receiver<()>;

#[derive(Clone)]
pub struct Stopper {
    broadcaster: Broadcaster<()>,
    stopped: Arc<AtomicBool>,
}

impl Stopper {
    #[allow(clippy::new_without_default)]
    pub fn new() -> Self {
        Stopper {
            broadcaster: Broadcaster::new(),
            stopped: Arc::new(AtomicBool::new(false)),
        }
    }

    pub fn stop(&self) -> Result<(), Error> {
        self.stopped.store(true, Ordering::SeqCst);
        self.broadcaster.broadcast(())
    }

    pub fn subscribe(&self) -> Result<(u64, Done), Error> {
        self.broadcaster.subscribe()
    }

    #[allow(dead_code)]
    pub fn unsubscribe(&self, id: u64) -> Result<(), Error> {
        self.broadcaster.unsubscribe(id)
    }

    pub fn stopped(&self) -> bool {
        self.stopped.load(Ordering::SeqCst)
    }
}
