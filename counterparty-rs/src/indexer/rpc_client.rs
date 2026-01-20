use base64::{engine::general_purpose::STANDARD as BASE64, Engine as _};
use bitcoin::Transaction;
use bitcoin::Txid;
use bitcoin::{Block, BlockHash};
use lazy_static::lazy_static;
use reqwest::blocking::Client as HttpClient;
use reqwest::header::{HeaderMap, HeaderValue, CONTENT_TYPE};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use lru::LruCache;
use std::cell::RefCell;
use std::collections::HashMap;
use std::num::NonZeroUsize;
use std::str::FromStr;
use std::sync::{Arc, Mutex};

// Thread-local client - each worker thread gets its own connection
thread_local! {
    pub static THREAD_BATCH_CLIENT: RefCell<Option<BatchRpcClient>> = const { RefCell::new(None) };
}

lazy_static! {
    pub static ref GLOBAL_TX_CACHE: Mutex<LruCache<Txid, Option<Transaction>>> =
        Mutex::new(LruCache::new(NonZeroUsize::new(100_000).unwrap()));
}

pub fn get_cached_transaction(txid: &Txid) -> Option<Option<Transaction>> {
    let mut cache = GLOBAL_TX_CACHE.lock().unwrap();
    cache.get(txid).cloned()
}

pub fn build_cached_transactions_map(txids: &[Txid]) -> HashMap<Txid, Option<Transaction>> {
    let mut cache = GLOBAL_TX_CACHE.lock().unwrap();
    let mut result = HashMap::new();
    for txid in txids {
        if let Some(tx) = cache.get(txid) {
            result.insert(*txid, tx.clone());
        }
    }
    result
}

pub fn insert_cached_transactions(pairs: Vec<(Txid, Option<Transaction>)>) {
    let mut cache = GLOBAL_TX_CACHE.lock().unwrap();
    for (txid, tx) in pairs {
        cache.put(txid, tx);
    }
}

#[derive(Debug, Clone)]
pub struct BatchRpcClient {
    client: Arc<HttpClient>,
    url: String,
    auth: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct RpcRequest {
    jsonrpc: String,
    id: u64,
    method: String,
    params: Vec<Value>,
}

#[derive(Debug, Serialize, Deserialize)]
struct RpcResponse {
    result: Option<Value>,
    error: Option<RpcError>,
    id: u64,
}

#[derive(Debug, Serialize, Deserialize)]
struct RpcError {
    code: i32,
    message: String,
}

#[allow(dead_code)]
#[derive(Debug)]
pub enum BatchRpcError {
    Http(reqwest::Error),
    Rpc(String),
    Parse(serde_json::Error),
    InvalidResponse(String),
}

impl From<reqwest::Error> for BatchRpcError {
    fn from(err: reqwest::Error) -> Self {
        BatchRpcError::Http(err)
    }
}

impl From<serde_json::Error> for BatchRpcError {
    fn from(err: serde_json::Error) -> Self {
        BatchRpcError::Parse(err)
    }
}

impl BatchRpcClient {
    pub fn new(url: String, user: String, password: String) -> Result<Self, BatchRpcError> {
        let mut headers = HeaderMap::new();
        headers.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));

        let auth = format!("{}:{}", user, password);
        let auth = format!("Basic {}", BASE64.encode(auth));

        let client = HttpClient::builder()
            .connection_verbose(false) // Désactive les logs verbeux de reqwest
            .default_headers(headers)
            .pool_max_idle_per_host(32)
            .pool_idle_timeout(std::time::Duration::from_secs(90))
            .build()
            .map_err(BatchRpcError::Http)?;

        Ok(BatchRpcClient {
            client: Arc::new(client),
            url,
            auth,
        })
    }

    /// Fetch transactions by txids with cache.
    /// Lock is released before HTTP call to avoid thread serialization on the mutex.
    pub fn get_transactions(
        &self,
        txids: &[Txid],
    ) -> Result<Vec<Option<Transaction>>, BatchRpcError> {
        if txids.is_empty() {
            return Ok(vec![]);
        }

        // Phase 1: Read cache under lock, collect uncached txids
        let uncached_txids: Vec<Txid>;
        let mut result_map: HashMap<Txid, Option<Transaction>> = HashMap::new();
        {
            let mut cache = GLOBAL_TX_CACHE.lock().unwrap();
            let mut uncached = Vec::new();
            for txid in txids {
                if let Some(tx) = cache.get(txid) {
                    result_map.insert(*txid, tx.clone());
                } else {
                    uncached.push(*txid);
                }
            }
            uncached_txids = uncached;
        } // Lock released here before HTTP call

        // All cached - return early
        if uncached_txids.is_empty() {
            return Ok(txids
                .iter()
                .map(|txid| result_map.get(txid).cloned().flatten())
                .collect());
        }

        // Phase 2: HTTP call without holding the lock
        let requests: Vec<RpcRequest> = uncached_txids
            .iter()
            .enumerate()
            .map(|(i, txid)| RpcRequest {
                jsonrpc: "2.0".to_string(),
                id: i as u64,
                method: "getrawtransaction".to_string(),
                params: vec![json!(txid.to_string()), json!(false)],
            })
            .collect();

        let mut headers = HeaderMap::new();
        headers.insert("Authorization", HeaderValue::from_str(&self.auth).unwrap());

        let response = self
            .client
            .post(&self.url)
            .headers(headers)
            .json(&requests)
            .send()?;

        if !response.status().is_success() {
            return Err(BatchRpcError::Rpc(format!(
                "HTTP error: {}",
                response.status()
            )));
        }

        let responses: Vec<RpcResponse> = response.json()?;

        // Phase 3: Parse responses and collect results
        let mut fetched: Vec<(Txid, Option<Transaction>)> = Vec::with_capacity(uncached_txids.len());
        for (txid, response) in uncached_txids.iter().zip(responses.into_iter()) {
            let tx = match response {
                RpcResponse {
                    result: Some(value),
                    error: None,
                    ..
                } => {
                    let hex = value.as_str().ok_or_else(|| {
                        BatchRpcError::InvalidResponse("Expected hex string".into())
                    })?;
                    let bytes = hex::decode(hex)
                        .map_err(|e| BatchRpcError::InvalidResponse(e.to_string()))?;
                    let tx: Transaction = bitcoin::consensus::deserialize(&bytes)
                        .map_err(|e| BatchRpcError::InvalidResponse(e.to_string()))?;
                    Some(tx)
                }
                RpcResponse {
                    error: Some(error), ..
                } => {
                    if error.code == -5 {
                        None
                    } else {
                        return Err(BatchRpcError::Rpc(error.message));
                    }
                }
                _ => None,
            };
            fetched.push((*txid, tx));
        }

        // Phase 4: Update cache under lock
        insert_cached_transactions(fetched.clone());

        // Merge into result_map
        for (txid, tx) in fetched {
            result_map.insert(txid, tx);
        }

        Ok(txids
            .iter()
            .map(|txid| result_map.get(txid).cloned().flatten())
            .collect())
    }

    pub fn get_block_hash(&self, height: u32) -> Result<BlockHash, BatchRpcError> {
        let request = RpcRequest {
            jsonrpc: "2.0".to_string(),
            id: 0,
            method: "getblockhash".to_string(),
            params: vec![json!(height)],
        };

        let mut headers = HeaderMap::new();
        headers.insert("Authorization", HeaderValue::from_str(&self.auth).unwrap());

        let response = self
            .client
            .post(&self.url)
            .headers(headers)
            .json(&request)
            .send()?;

        if !response.status().is_success() {
            return Err(BatchRpcError::Rpc(format!(
                "HTTP error: {}",
                response.status()
            )));
        }

        let response: RpcResponse = response.json()?;

        match response {
            RpcResponse {
                result: Some(value),
                error: None,
                ..
            } => {
                let hash_str = value.as_str().ok_or_else(|| {
                    BatchRpcError::InvalidResponse("Expected block hash string".into())
                })?;
                BlockHash::from_str(hash_str)
                    .map_err(|e| BatchRpcError::InvalidResponse(e.to_string()))
            }
            RpcResponse {
                error: Some(error), ..
            } => Err(BatchRpcError::Rpc(error.message)),
            _ => Err(BatchRpcError::InvalidResponse(
                "Invalid response format".into(),
            )),
        }
    }

    pub fn get_block(&self, hash: &BlockHash) -> Result<Block, BatchRpcError> {
        let request = RpcRequest {
            jsonrpc: "2.0".to_string(),
            id: 0,
            method: "getblock".to_string(),
            params: vec![json!(hash.to_string()), json!(0)],
        };

        let mut headers = HeaderMap::new();
        headers.insert("Authorization", HeaderValue::from_str(&self.auth).unwrap());

        let response = self
            .client
            .post(&self.url)
            .headers(headers)
            .json(&request)
            .send()?;

        if !response.status().is_success() {
            return Err(BatchRpcError::Rpc(format!(
                "HTTP error: {}",
                response.status()
            )));
        }

        let response: RpcResponse = response.json()?;

        match response {
            RpcResponse {
                result: Some(value),
                error: None,
                ..
            } => {
                let hex = value.as_str().ok_or_else(|| {
                    BatchRpcError::InvalidResponse("Expected block hex string".into())
                })?;
                let bytes =
                    hex::decode(hex).map_err(|e| BatchRpcError::InvalidResponse(e.to_string()))?;
                bitcoin::consensus::deserialize(&bytes)
                    .map_err(|e| BatchRpcError::InvalidResponse(e.to_string()))
            }
            RpcResponse {
                error: Some(error), ..
            } => Err(BatchRpcError::Rpc(error.message)),
            _ => Err(BatchRpcError::InvalidResponse(
                "Invalid response format".into(),
            )),
        }
    }

    pub fn get_blockchain_info(&self) -> Result<Value, BatchRpcError> {
        let request = RpcRequest {
            jsonrpc: "2.0".to_string(),
            id: 0,
            method: "getblockchaininfo".to_string(),
            params: vec![],
        };

        let mut headers = HeaderMap::new();
        headers.insert("Authorization", HeaderValue::from_str(&self.auth).unwrap());

        let response = self
            .client
            .post(&self.url)
            .headers(headers)
            .json(&request)
            .send()?;

        if !response.status().is_success() {
            return Err(BatchRpcError::Rpc(format!(
                "HTTP error: {}",
                response.status()
            )));
        }

        let response: RpcResponse = response.json()?;

        match response {
            RpcResponse {
                result: Some(value),
                error: None,
                ..
            } => Ok(value),
            RpcResponse {
                error: Some(error), ..
            } => Err(BatchRpcError::Rpc(error.message)),
            _ => Err(BatchRpcError::InvalidResponse(
                "Invalid response format".into(),
            )),
        }
    }
}
