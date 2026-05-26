use base64::{engine::general_purpose::STANDARD as BASE64, Engine as _};
use bitcoin::Transaction;
use bitcoin::Txid;
use bitcoin::{Block, BlockHash};
use lazy_static::lazy_static;
use reqwest::blocking::Client as HttpClient;
use reqwest::header::{HeaderMap, HeaderValue, CONTENT_TYPE};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::collections::HashMap;
use std::str::FromStr;
use std::sync::{Arc, Mutex};

lazy_static! {
    pub(crate) static ref BATCH_CLIENT: Mutex<Option<BatchRpcClient>> = Mutex::new(None);
}

#[derive(Debug, Clone)]
pub struct BatchRpcClient {
    client: Arc<HttpClient>,
    url: String,
    auth: String,
    // Optional `X-API-Key` header value. When set, every RPC request
    // includes it so a Cloud-Armor-style gateway grants a higher
    // per-key rate-limit bucket; left as `None` for self-hosted nodes.
    api_key: Option<String>,
    cache: Arc<Mutex<HashMap<Txid, Option<Transaction>>>>,
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
    pub fn new(
        url: String,
        user: String,
        password: String,
        api_key: Option<String>,
    ) -> Result<Self, BatchRpcError> {
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

        // Sanitize: an empty string is treated as "no API key" so the caller
        // can pass `Some("".into())` when the Python config left the value
        // blank without us emitting an invalid header.
        let api_key = api_key.filter(|s| !s.is_empty());

        Ok(BatchRpcClient {
            client: Arc::new(client),
            url,
            auth,
            api_key,
            cache: Arc::new(Mutex::new(HashMap::new())),
        })
    }

    fn auth_headers(&self) -> Result<HeaderMap, BatchRpcError> {
        let mut headers = HeaderMap::new();
        let auth_value = HeaderValue::from_str(&self.auth)
            .map_err(|e| BatchRpcError::InvalidResponse(e.to_string()))?;
        headers.insert("Authorization", auth_value);
        if let Some(api_key) = &self.api_key {
            // Skip the header silently if the configured key contains
            // characters that aren't valid in an HTTP header value, rather
            // than panicking the worker thread.
            if let Ok(value) = HeaderValue::from_str(api_key) {
                headers.insert("X-API-Key", value);
            }
        }
        Ok(headers)
    }

    // Le reste du code reste inchangé...
    pub fn get_transactions(
        &self,
        txids: &[Txid],
    ) -> Result<Vec<Option<Transaction>>, BatchRpcError> {
        if txids.is_empty() {
            return Ok(vec![]);
        }

        let mut cache = self.cache.lock().unwrap();
        let mut uncached_txids = Vec::new();
        let mut result_map = HashMap::new();

        for txid in txids {
            if let Some(tx) = cache.get(txid) {
                result_map.insert(*txid, tx.clone());
            } else {
                uncached_txids.push(*txid);
            }
        }

        if uncached_txids.is_empty() {
            return Ok(txids
                .iter()
                .map(|txid| result_map.get(txid).cloned().flatten())
                .collect());
        }

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

        let response = self
            .client
            .post(&self.url)
            .headers(self.auth_headers()?)
            .json(&requests)
            .send()?;

        if !response.status().is_success() {
            return Err(BatchRpcError::Rpc(format!(
                "HTTP error: {}",
                response.status()
            )));
        }

        let responses: Vec<RpcResponse> = response.json()?;

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

            if tx.is_some() {
                cache.insert(*txid, tx.clone());
            }
            result_map.insert(*txid, tx);
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

        let response = self
            .client
            .post(&self.url)
            .headers(self.auth_headers()?)
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

        let response = self
            .client
            .post(&self.url)
            .headers(self.auth_headers()?)
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

        let response = self
            .client
            .post(&self.url)
            .headers(self.auth_headers()?)
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
