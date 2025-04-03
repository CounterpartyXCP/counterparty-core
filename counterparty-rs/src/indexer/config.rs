use std::fmt::Display;

use pyo3::{exceptions::PyValueError, types::PyDict, FromPyObject, PyAny, PyErr, PyResult};
use tracing::level_filters::LevelFilter;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Mode {
    Indexer,
    Fetcher,
}

impl<'source> FromPyObject<'source> for Mode {
    fn extract(obj: &'source PyAny) -> PyResult<Self> {
        let mode_str: String = obj.extract()?;
        match mode_str.trim().to_lowercase().as_str() {
            "indexer" => Ok(Mode::Indexer),
            "fetcher" => Ok(Mode::Fetcher),
            _ => Err(PyErr::new::<PyValueError, _>(
                "'mode' must be either 'indexer' or 'fetcher'",
            )),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct LogLevel(LevelFilter);

impl From<LogLevel> for LevelFilter {
    fn from(log_level: LogLevel) -> Self {
        log_level.0
    }
}

impl<'source> FromPyObject<'source> for LogLevel {
    fn extract(obj: &'source PyAny) -> PyResult<Self> {
        let level_str: String = obj.extract()?;
        match level_str.trim().to_lowercase().as_str() {
            "trace" => Ok(LogLevel(LevelFilter::TRACE)),
            "debug" => Ok(LogLevel(LevelFilter::DEBUG)),
            "info" => Ok(LogLevel(LevelFilter::INFO)),
            "warn" => Ok(LogLevel(LevelFilter::WARN)),
            "error" => Ok(LogLevel(LevelFilter::ERROR)),
            "off" => Ok(LogLevel(LevelFilter::OFF)),
            _ => Err(PyErr::new::<PyValueError, _>(
                "'log_level' must be one of 'trace', 'debug', 'info', 'warn', 'error' or 'off'",
            )),
        }
    }
}

#[derive(Debug, Clone)]
pub enum Network {
    Mainnet,
    Testnet3,
    Testnet4,
    Regtest,
}

impl<'source> FromPyObject<'source> for Network {
    fn extract(obj: &'source PyAny) -> PyResult<Self> {
        let network_str: String = obj.extract()?;
        match network_str.trim().to_lowercase().as_str() {
            "mainnet" => Ok(Network::Mainnet),
            "testnet3" => Ok(Network::Testnet3),
            "testnet4" => Ok(Network::Testnet4),
            "regtest" => Ok(Network::Regtest),
            _ => Err(PyErr::new::<PyValueError, _>(
                "'network' must be either 'mainnet', 'testnet' or 'testnet4'",
            )),
        }
    }
}

impl Display for Network {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let s = match self {
            Network::Mainnet => "mainnet",
            Network::Testnet3 => "testnet3",
            Network::Testnet4 => "testnet4",
            Network::Regtest => "regtest",
        };
        write!(f, "{}", s)
    }
}

#[derive(Debug, Clone)]
pub struct Heights {
    pub segwit: u32,
    pub p2sh_addresses: u32,
    pub p2sh_dispensers: u32,
    pub correct_segwit_txids: u32,
    pub multisig_addresses: u32,
    pub taproot_support: u32,
    pub fix_is_segwit: u32,
}

impl Heights {
    pub fn new(network: Network) -> Self {
        match network {
            Network::Mainnet => Heights {
                segwit: 557236,
                p2sh_addresses: 423888,
                p2sh_dispensers: 724000,
                correct_segwit_txids: 662000,
                multisig_addresses: 333500,
                taproot_support: 900000,
                fix_is_segwit: 900000,
            },
            Network::Testnet3 => Heights {
                segwit: 1440200,
                p2sh_addresses: 0,
                p2sh_dispensers: 2163328,
                correct_segwit_txids: 1666625,
                multisig_addresses: 0,
                taproot_support: 5000000,
                fix_is_segwit: 5000000,
            },
            Network::Testnet4 => Heights {
                segwit: 0,
                p2sh_addresses: 0,
                p2sh_dispensers: 0,
                correct_segwit_txids: 0,
                multisig_addresses: 0,
                taproot_support: 80000,
                fix_is_segwit: 80000,
            },
            Network::Regtest => Heights {
                segwit: 0,
                p2sh_addresses: 0,
                p2sh_dispensers: 0,
                correct_segwit_txids: 0,
                multisig_addresses: 0,
                taproot_support: 0,
                fix_is_segwit: 0,
            },
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
    pub address_version: Vec<u8>,
    pub p2sh_address_version: Vec<u8>,
    pub network: Network,
    pub heights: Heights,
    pub json_format: bool,
    pub only_write_in_reorg_window: bool,
    pub enable_all_protocol_changes: bool,
}

impl Config {
    pub fn segwit_supported(&self, height: u32) -> bool {
        height >= self.heights.segwit || self.enable_all_protocol_changes
    }

    pub fn p2sh_address_supported(&self, height: u32) -> bool {
        height >= self.heights.p2sh_addresses || self.enable_all_protocol_changes
    }

    pub fn p2sh_dispensers_supported(&self, height: u32) -> bool {
        height >= self.heights.p2sh_dispensers || self.enable_all_protocol_changes
    }

    pub fn correct_segwit_txids_enabled(&self, height: u32) -> bool {
        height >= self.heights.correct_segwit_txids || self.enable_all_protocol_changes
    }

    pub fn multisig_addresses_enabled(&self, height: u32) -> bool {
        height >= self.heights.multisig_addresses || self.enable_all_protocol_changes
    }

    pub fn taproot_support_enabled(&self, height: u32) -> bool {
        height >= self.heights.taproot_support || self.enable_all_protocol_changes
    }

    pub fn fix_is_segwit_enabled(&self, height: u32) -> bool {
        height >= self.heights.fix_is_segwit || self.enable_all_protocol_changes
    }

    pub fn unspendable(&self) -> String {
        match self.network {
            Network::Mainnet => "1CounterpartyXXXXXXXXXXXXXXXUWLpVr",
            Network::Testnet3 => "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
            Network::Testnet4 => "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
            Network::Regtest => "mvCounterpartyXXXXXXXXXXXXXXW24Hef",
        }
        .into()
    }
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
            _ => LogLevel(LevelFilter::INFO),
        };

        let json_format = match dict.get_item("json_format") {
            Ok(Some(item)) => item.extract()?,
            _ => false,
        };

        let only_write_in_reorg_window = match dict.get_item("only_write_in_reorg_window") {
            Ok(Some(item)) => item.extract()?,
            _ => false,
        };

        let prefix = match dict.get_item("prefix") {
            Ok(Some(item)) => item.extract::<Vec<u8>>()?,
            _ => b"CNTRPRTY".to_vec(),
        };

        let network = match dict.get_item("network") {
            Ok(Some(item)) => item.extract()?,
            _ => Network::Mainnet, // Default to Mainnet if not provided or in case of an error
        };

        let enable_all_protocol_changes = match dict.get_item("enable_all_protocol_changes") {
            Ok(Some(item)) => item.extract()?,
            _ => false,
        };

        let heights = Heights::new(network.clone());

        let address_version = match dict.get_item("address_version") {
            Ok(Some(item)) => item.extract::<Vec<u8>>()?,
            _ => match network {
                Network::Mainnet => vec![0x00],
                Network::Testnet3 => vec![0x6F],
                Network::Testnet4 => vec![0x6F],
                Network::Regtest => vec![0x6F],
            },
        };

        let p2sh_address_version = match dict.get_item("p2sh_address_version") {
            Ok(Some(item)) => item.extract::<Vec<u8>>()?,
            _ => match network {
                Network::Mainnet => vec![0x05],
                Network::Testnet3 => vec![0xC4],
                Network::Testnet4 => vec![0xC4],
                Network::Regtest => vec![0xC4],
            },
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
            address_version,
            p2sh_address_version,
            network,
            heights,
            json_format,
            only_write_in_reorg_window,
            enable_all_protocol_changes,
        })
    }
}
