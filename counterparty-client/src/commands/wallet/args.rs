use std::collections::HashMap;
use std::sync::{LazyLock, Mutex, MutexGuard};

/// Global static mapping between internal argument IDs and their original names.
pub static ID_ARG_MAP: LazyLock<Mutex<HashMap<String, String>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

/// Lock [`ID_ARG_MAP`], recovering from a poisoned mutex instead of panicking.
/// The map only ever holds `arg-id -> name` strings, so a panic in another
/// thread while it was held cannot leave a half-updated *entry* — recovering the
/// guard is safe and keeps a single poisoned build-time insert from bringing down
/// an unrelated command.
pub fn id_arg_map() -> MutexGuard<'static, HashMap<String, String>> {
    ID_ARG_MAP.lock().unwrap_or_else(|e| e.into_inner())
}

/// Shared `value_parser` for boolean CLI flags: accepts `true`/`false`/`1`/`0`
/// (case-insensitive) and normalises to `"true"`/`"false"`. Used by both the
/// `api <fn>` and `wallet transaction <type>` argument builders so the two never
/// drift.
pub fn parse_bool_flag(s: &str) -> std::result::Result<String, String> {
    match s.to_lowercase().as_str() {
        "true" | "1" => Ok("true".to_string()),
        "false" | "0" => Ok("false".to_string()),
        _ => Err(format!("Invalid boolean value: {s}. Use true/false or 1/0")),
    }
}
