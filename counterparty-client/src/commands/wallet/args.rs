use std::collections::{HashMap, HashSet};
use std::sync::{LazyLock, Mutex, MutexGuard};

use clap::{Arg, Command};

use crate::commands::api::commands::{enum_choices, json_scalar_to_string, push_help_note};
use crate::commands::api::ApiEndpointArg;

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

/// Long flags the top-level CLI reserves (its `.global(true)` flags, plus clap's
/// auto-generated `help`/`version`), plus `yes` — the `--yes` long flag every
/// `wallet transaction` command injects as its non-interactive broadcast flag
/// (its `-y` *short* alias needs no reservation: a manifest arg named `y` maps to
/// the distinct long flag `--y`). A manifest arg whose name collides with one of
/// these would define a conflicting `--<flag>` on a subcommand that already
/// carries it, which clap rejects when the whole command tree is built (a panic
/// in debug, a hard error in release) — bricking *every* invocation until the
/// endpoint cache is refreshed. The endpoint manifest is fetched from the API
/// server (or read from a locally-writable cache), i.e. not fully trusted, so
/// such a name is skipped rather than leaked into clap.
pub const RESERVED_LONG_FLAGS: &[&str] = &[
    "help",
    "version",
    "config-file",
    "mainnet",
    "signet",
    "testnet4",
    "regtest",
    "json",
    "update-cache",
    "yes",
];

/// Whether a manifest-supplied argument name is safe to register as a clap
/// `--long` flag. Rejects an empty or over-long name, a collision with a
/// [`RESERVED_LONG_FLAGS`] entry, and any name that is not a conventional long
/// flag (ASCII alphanumerics plus `-`/`_`, not starting with `-`) — all shapes a
/// hostile or corrupted manifest could otherwise use to brick command building.
pub fn is_valid_arg_name(name: &str) -> bool {
    !name.is_empty()
        && name.len() <= 64
        && !name.starts_with('-')
        && !RESERVED_LONG_FLAGS.contains(&name)
        && name
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '-' || c == '_')
}

/// Build and register one manifest-derived clap argument, shared verbatim by the
/// `api <fn>` and `wallet transaction <type>` builders so the two cannot drift
/// (they historically did — only one carried the [`is_valid_arg_name`] guard).
///
/// Returns `cmd` unchanged when the name is unsafe (see [`is_valid_arg_name`]) or
/// already used on this command. Otherwise leaks the caller-supplied
/// `internal_id` and the long flag, records the `internal_id -> name` mapping in
/// [`ID_ARG_MAP`] scoped by `command_name`, surfaces the server's enum/default
/// metadata in `--help` (deliberately not wired as a clap `default_value`: an
/// omitted optional flag must stay unsent so the server applies its own default),
/// and installs the shared bool value-parser for boolean args.
pub fn add_manifest_argument(
    cmd: Command,
    arg: &ApiEndpointArg,
    internal_id: String,
    command_name: &str,
    used_long_names: &mut HashSet<String>,
) -> Command {
    // Skip an unsafe manifest arg name rather than let it brick command building.
    // Skipping only drops that one CLI flag; the command keeps working.
    if !is_valid_arg_name(&arg.name) {
        return cmd;
    }

    // Skip a duplicate long name on this command.
    if used_long_names.contains(&arg.name) {
        return cmd;
    }
    used_long_names.insert(arg.name.clone());

    let static_internal_id: &'static str = Box::leak(internal_id.into_boxed_str());
    let static_long_flag: &'static str = Box::leak(arg.name.clone().into_boxed_str());

    let id_map_key = format!("{}:{}", command_name, static_internal_id);
    id_arg_map().insert(id_map_key, arg.name.clone());

    let mut help_text = arg.description.as_deref().unwrap_or("").to_string();
    if let Some(choices) = enum_choices(arg) {
        push_help_note(&mut help_text, &format!("possible values: {choices}"));
    }
    if let Some(default) = arg.default.as_ref().and_then(json_scalar_to_string) {
        push_help_note(&mut help_text, &format!("default: {default}"));
    }
    let static_help: &'static str = Box::leak(help_text.into_boxed_str());

    let mut cmd_arg = Arg::new(static_internal_id)
        .long(static_long_flag)
        .help(static_help);

    if arg.required {
        cmd_arg = cmd_arg.required(true);
    }

    if arg.arg_type == "bool" {
        // Accept a value for boolean flags (--flag true/false/1/0).
        cmd_arg = cmd_arg.value_name("BOOL").value_parser(parse_bool_flag);
    } else {
        cmd_arg = cmd_arg.value_name("VALUE");
    }

    cmd.arg(cmd_arg)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_bool_flag_normalises_and_rejects() {
        assert_eq!(parse_bool_flag("TRUE").unwrap(), "true");
        assert_eq!(parse_bool_flag("1").unwrap(), "true");
        assert_eq!(parse_bool_flag("False").unwrap(), "false");
        assert_eq!(parse_bool_flag("0").unwrap(), "false");
        assert!(parse_bool_flag("nope").is_err());
    }

    #[test]
    fn is_valid_arg_name_accepts_real_params_and_rejects_reserved_or_malformed() {
        // Real compose parameter names pass.
        assert!(is_valid_arg_name("asset"));
        assert!(is_valid_arg_name("give_quantity"));
        assert!(is_valid_arg_name("quantity_by_price"));
        // A manifest arg named `y` is fine — it maps to the distinct `--y` long
        // flag, not the `-y` short alias of `--yes`.
        assert!(is_valid_arg_name("y"));
        // Reserved global / clap-auto / injected flags are rejected.
        for reserved in [
            "json",
            "mainnet",
            "regtest",
            "config-file",
            "help",
            "version",
            "yes",
        ] {
            assert!(!is_valid_arg_name(reserved), "{reserved} must be reserved");
        }
        // Malformed / injection-ish names are rejected.
        assert!(!is_valid_arg_name(""));
        assert!(!is_valid_arg_name("--json"));
        assert!(!is_valid_arg_name("bad name"));
        assert!(!is_valid_arg_name("weird=val"));
        assert!(!is_valid_arg_name(&"x".repeat(65)));
    }

    #[test]
    fn add_manifest_argument_skips_reserved_and_duplicate_names() {
        let mut used = HashSet::new();
        let reserved = ApiEndpointArg {
            name: "yes".to_string(),
            required: false,
            arg_type: "string".to_string(),
            description: None,
            default: None,
            members: None,
        };
        // A reserved name (would collide with the injected `--yes`) is dropped.
        let cmd = add_manifest_argument(
            Command::new("send"),
            &reserved,
            "__transaction_send_arg_0_yes".to_string(),
            "send",
            &mut used,
        );
        assert!(cmd.get_arguments().all(|a| a.get_long() != Some("yes")));
        assert!(!used.contains("yes"));

        // A valid name is registered once; a repeat is skipped.
        let asset = ApiEndpointArg {
            name: "asset".to_string(),
            required: false,
            arg_type: "string".to_string(),
            description: None,
            default: None,
            members: None,
        };
        let cmd = add_manifest_argument(
            cmd,
            &asset,
            "__transaction_send_arg_1_asset".to_string(),
            "send",
            &mut used,
        );
        let cmd = add_manifest_argument(
            cmd,
            &asset,
            "__transaction_send_arg_2_asset".to_string(),
            "send",
            &mut used,
        );
        assert_eq!(
            cmd.get_arguments()
                .filter(|a| a.get_long() == Some("asset"))
                .count(),
            1
        );
    }
}
