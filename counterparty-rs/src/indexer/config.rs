use pyo3::{exceptions::PyValueError, types::PyDict, FromPyObject, PyAny, PyErr, PyResult};
use tracing::Level;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Mode {
    Indexer,
    Fetcher,
}

impl<'source> FromPyObject<'source> for Mode {
    fn extract(obj: &'source PyAny) -> PyResult<Self> {
        let mode_str: String = obj.extract()?;
        match mode_str.as_str() {
            "indexer" => Ok(Mode::Indexer),
            "fetcher" => Ok(Mode::Fetcher),
            _ => Err(PyErr::new::<PyValueError, _>(
                "'mode' must be either 'indexer' or 'fetcher'",
            )),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct LogLevel(Level);

impl From<LogLevel> for Level {
    fn from(log_level: LogLevel) -> Self {
        log_level.0
    }
}

impl<'source> FromPyObject<'source> for LogLevel {
    fn extract(obj: &'source PyAny) -> PyResult<Self> {
        let level_str: String = obj.extract()?;
        match level_str.as_str() {
            "trace" => Ok(LogLevel(Level::TRACE)),
            "debug" => Ok(LogLevel(Level::DEBUG)),
            "info" => Ok(LogLevel(Level::INFO)),
            "warn" => Ok(LogLevel(Level::WARN)),
            "error" => Ok(LogLevel(Level::ERROR)),
            _ => Err(PyErr::new::<PyValueError, _>(
                "'log_level' must be one of 'trace', 'debug', 'info', 'warn', or 'error'",
            )),
        }
    }
}

#[derive(Debug, Clone)]
pub struct Config {
    pub rpc_address: String,
    pub rpc_user: String,
    pub rpc_password: String,
    pub log_file: String,
    pub log_level: LogLevel,
    pub db_dir: String,
    pub consume_blocks: bool,
    pub start_height: Option<u32>,
    pub mode: Mode,
    pub prefix: Vec<u8>,
}

impl<'source> FromPyObject<'source> for Config {
    fn extract(obj: &'source PyAny) -> PyResult<Self> {
        let dict = obj.downcast::<PyDict>()?;
        let rpc_address: String = dict
            .get_item("rpc_address")?
            .ok_or(PyErr::new::<PyValueError, _>("'rpc_address' is required"))?
            .extract()?;
        let rpc_user: String = dict
            .get_item("rpc_user")?
            .ok_or(PyErr::new::<PyValueError, _>("'rpc_user' is required"))?
            .extract()?;
        let rpc_password: String = dict
            .get_item("rpc_password")?
            .ok_or(PyErr::new::<PyValueError, _>("'rpc_password' is required"))?
            .extract()?;
        let db_dir: String = dict
            .get_item("db_dir")?
            .ok_or(PyErr::new::<PyValueError, _>("'db_dir' is required"))?
            .extract()?;
        let log_file: String = dict
            .get_item("log_file")?
            .ok_or(PyErr::new::<PyValueError, _>("'log_file' is required"))?
            .extract()?;

        let consume_blocks = match dict.get_item("consume_blocks")? {
            Some(item) => item.extract()?,
            None => false,
        };

        let start_height = match dict.get_item("start_height") {
            Ok(Some(item)) => item.extract()?,
            _ => None,
        };

        let mode = match dict.get_item("mode") {
            Ok(Some(item)) => item.extract()?,
            _ => Mode::Fetcher,
        };

        let log_level = match dict.get_item("log_level") {
            Ok(Some(item)) => item.extract()?,
            _ => LogLevel(Level::INFO),
        };

        let prefix = match dict.get_item("prefix") {
            Ok(Some(item)) => item.extract::<Vec<u8>>()?,
            _ => b"CNTRPRTY".to_vec(),
        };

        Ok(Config {
            rpc_address,
            rpc_user,
            rpc_password,
            log_file,
            log_level,
            db_dir,
            consume_blocks,
            start_height,
            mode,
            prefix,
        })
    }
}
