use std::collections::HashMap;
use std::sync::{LazyLock, Mutex};

/// Global static mapping between internal argument IDs and their original names.
pub static ID_ARG_MAP: LazyLock<Mutex<HashMap<String, String>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));
pub static LONG_ARG_MAP: LazyLock<Mutex<HashMap<String, String>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));
