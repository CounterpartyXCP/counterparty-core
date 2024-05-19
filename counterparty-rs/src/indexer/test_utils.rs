#![allow(clippy::expect_used, clippy::unwrap_used)]
use std::thread;

use bitcoincore_rpc::bitcoin::{hashes::Hash, BlockHash};
use crossbeam_channel::{unbounded, Receiver, Sender};

use super::{stopper::Stopper, types::error::Error};

pub fn test_worker<T, U, F, I>(mut worker_fn: F, input_data: I) -> Vec<U>
where
    T: Send + 'static,
    U: Send + 'static,
    F: FnMut(Receiver<Box<T>>, Sender<Box<U>>, Stopper) -> Result<(), Error>
        + Clone
        + Send
        + 'static,
    I: IntoIterator<Item = T>,
{
    let (tx, rx) = unbounded::<Box<T>>();
    let (out_tx, out_rx) = unbounded::<Box<U>>();
    let stopper = Stopper::new();
    let stopper_clone = stopper.clone();

    let handle = thread::spawn(move || worker_fn(rx, out_tx, stopper_clone));

    let mut input_count = 0;
    for item in input_data {
        tx.send(Box::new(item)).expect("Failed to send input");
        input_count += 1;
    }

    let mut output_data = Vec::with_capacity(input_count);

    for _ in 0..input_count {
        if let Ok(data) = out_rx.recv() {
            output_data.push(*data);
        }
    }

    stopper.stop().unwrap();
    handle
        .join()
        .expect("Worker thread paniced")
        .expect("Worker returned error");

    output_data
}

pub fn test_sha256_hash(i: u32) -> [u8; 32] {
    [i as u8; 32]
}

pub fn test_h160_hash(i: u32) -> [u8; 20] {
    [i as u8; 20]
}

pub fn test_block_hash(i: u32) -> BlockHash {
    BlockHash::from_slice(&test_sha256_hash(i)).unwrap()
}

#[macro_export]
macro_rules! new_test_db {
    () => {{
        use std::{fs, path::Path};

        let db_dir = "test_dbs";
        let dir_path = Path::new(db_dir);
        if !dir_path.exists() {
            fs::create_dir_all(dir_path).expect("Failed to create test database directory");
        }

        let file = Path::new(file!()).file_name().unwrap().to_str().unwrap();
        let line = line!();
        let test_id = format!("{}_{}", file, line).replace(".", "_");
        let db_path_str = format!("{}/test_{}", db_dir, test_id);
        let db_path = Path::new(&db_path_str);

        if db_path.exists() {
            fs::remove_dir_all(db_path).unwrap();
        }
        fs::create_dir_all(db_path).expect("Failed to create test database directory");

        Database::new(db_path_str)
    }};
}
