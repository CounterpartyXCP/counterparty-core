use std::sync;

use crossbeam_channel::SendError;
use pyo3::exceptions::PyException;
use pyo3::PyErr;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum Error {
    #[error("IO error: {0}")]
    IO(#[from] std::io::Error),
    #[error("RPC error: {0}")]
    Rpc(#[from] bitcoincore_rpc::Error),
    #[error("RocksDB error: {0}")]
    RocksDB(#[from] rocksdb::Error),
    #[error("TryFromSlice error: {0}")]
    TryFromSlice(#[from] std::array::TryFromSliceError),
    #[error("Recv error: {0}")]
    Recv(#[from] crossbeam_channel::RecvError),
    #[error("Send error: {0}")]
    Send(String),
    #[error("KeyParse error: {0}")]
    KeyParse(String),
    #[error("ValueParse error: {0}")]
    ValueParse(String),
    #[error("RocksDBIter error: {0}")]
    RocksDBIter(String),
    #[error("RocksDBColumnFamily error: {0}")]
    RocksDBColumnFamily(String),
    #[error("U32Conversion error: {0}")]
    U32Conversion(String),
    #[error("Stopped error")]
    Stopped,
    #[error("GracefulExitFailure: {0}")]
    GracefulExitFailure(String),
    #[error("Block not yet written: {0}")]
    BlockNotWritten(u32),
    #[error("No hash match found!")]
    NoHashMatchFound,
    #[error("OpertionCancelled error: {0}")]
    OperationCancelled(String),
    #[error("Sync error: {0}")]
    Sync(String),
    #[error("OrderInvariantError: Essential ordering constraint violated between {0} and {1}")]
    OrderInvariant(u32, u32),
}

impl<T> From<SendError<T>> for Error {
    fn from(value: SendError<T>) -> Self {
        Error::Send(value.to_string())
    }
}

impl<E> From<sync::PoisonError<E>> for Error {
    fn from(value: sync::PoisonError<E>) -> Self {
        Error::Sync(value.to_string())
    }
}

impl From<Error> for PyErr {
    fn from(value: Error) -> PyErr {
        PyException::new_err(value.to_string())
    }
}
