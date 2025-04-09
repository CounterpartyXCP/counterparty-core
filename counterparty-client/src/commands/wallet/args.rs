use lazy_static::lazy_static;
use std::collections::HashMap;
use std::sync::Mutex;

// Global static mapping between internal argument IDs and their original names
lazy_static! {
    pub static ref ID_ARG_MAP: Mutex<HashMap<String, String>> = Mutex::new(HashMap::new());
    pub static ref LONG_ARG_MAP: Mutex<HashMap<String, String>> = Mutex::new(HashMap::new());
}