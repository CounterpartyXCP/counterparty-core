use clap::{Arg, ArgAction, Command};

/// Builds the main wallet command with its subcommands
pub fn build_command() -> Command {
    Command::new("wallet")
        .about("Manage your Counterparty wallet")
        .subcommand(build_new_address_command())
        .subcommand(build_import_address_command())
        .subcommand(build_export_address_command())
        .subcommand(build_list_addresses_command())
        .subcommand(build_address_balances_command())
        .subcommand(build_change_password_command())
        .subcommand(build_sign_command())
        .subcommand(build_broadcast_command())
        .subcommand(build_disconnect_command())
}

/// Builds the send_transaction command
pub fn build_send_transaction_command() -> Command {
    Command::new("transaction").about("Send Counterparty transactions")
}

/// Builds the sign transaction command
pub fn build_sign_command() -> Command {
    Command::new("sign")
        .about("Sign a raw Bitcoin transaction without broadcasting")
        .arg(
            Arg::new("rawtransaction")
                .long("rawtransaction")
                .help("Raw unsigned transaction in hexadecimal format")
                .required(true)
                .value_name("HEX"),
        )
        .arg(
            Arg::new("utxos")
                .long("utxos")
                .help("JSON array of UTXOs corresponding to inputs in the format [{\"scriptPubKey\":\"hex\",\"amount\":satoshis,\"redeemScript\":\"hex\",\"witnessScript\":\"hex\",\"sourceAddress\":\"addr\",\"leafScript\":\"hex\"}]")
                .required(false)
                .value_name("JSON"),
        )
}

/// Builds the broadcast transaction command
pub fn build_broadcast_command() -> Command {
    Command::new("broadcast")
        .about("Broadcast a signed Bitcoin transaction to the network")
        .arg(
            Arg::new("rawtransaction")
                .long("rawtransaction")
                .help("Raw signed transaction in hexadecimal format")
                .required(true)
                .value_name("HEX"),
        )
}

/// Builds the new_address subcommand for generating a random address
fn build_new_address_command() -> Command {
    Command::new("new_address")
        .about("Generate a new random Bitcoin address")
        .arg(
            Arg::new("label")
                .long("label")
                .help("A label for the address")
                .value_name("LABEL"),
        )
        .arg(
            Arg::new("address_type")
                .long("address-type")
                .help("Type of address to generate (bech32, p2pkh, or taproot, default: bech32)")
                .value_name("TYPE")
                .value_parser(["bech32", "p2pkh", "taproot"])
                .default_value("bech32"),
        )
}

/// Builds the import_address subcommand for importing existing keys
fn build_import_address_command() -> Command {
    Command::new("import_address")
        .about("Import an existing private key or mnemonic")
        .arg(
            Arg::new("private_key")
                .long("private-key")
                .help("Existing private key to import. Use @ prefix to read from a file.")
                .value_name("PRIVATE_KEY"),
        )
        .arg(
            Arg::new("mnemonic")
                .long("mnemonic")
                .help("BIP39 mnemonic phrase. Use @ prefix to read from a file.")
                .value_name("MNEMONIC"),
        )
        .arg(
            Arg::new("path")
                .long("path")
                .help("Derivation path (default depends on address type)")
                .value_name("PATH"),
        )
        .arg(
            Arg::new("label")
                .long("label")
                .help("A label for the address")
                .value_name("LABEL"),
        )
        .arg(
            Arg::new("address_type")
                .long("address-type")
                .help("Type of address to generate (bech32, p2pkh, or taproot, default: bech32)")
                .value_name("TYPE")
                .value_parser(["bech32", "p2pkh", "taproot"])
                .default_value("bech32"),
        )
}

/// Builds the export_address subcommand
fn build_export_address_command() -> Command {
    Command::new("export_address")
        .about("Export details for a specific address including private key")
        .arg(
            Arg::new("address")
                .long("address")
                .help("The blockchain address to export")
                .required(true)
                .value_name("ADDRESS"),
        )
        .arg(
            Arg::new("yes")
                .long("yes")
                .short('y')
                .help("Skip the confirmation prompt before revealing the private key")
                .action(ArgAction::SetTrue),
        )
}

/// Builds the addresses subcommand
fn build_list_addresses_command() -> Command {
    Command::new("list_addresses").about("List all addresses in the wallet")
}

/// Builds the address_balances subcommand
fn build_address_balances_command() -> Command {
    Command::new("address_balances")
        .about("Display balances for a specific address")
        .arg(
            Arg::new("address")
                .long("address")
                .help("The blockchain address to check balances for")
                .required(true)
                .value_name("ADDRESS"),
        )
}

/// Builds the change_password subcommand
fn build_change_password_command() -> Command {
    Command::new("change_password").about("Change the wallet encryption password")
}

/// Builds the disconnect subcommand
fn build_disconnect_command() -> Command {
    Command::new("disconnect")
        .about("Clear the wallet password from the system keyring and memory cache")
}

#[cfg(test)]
mod tests {
    use super::*;

    fn subcommand_names(cmd: &Command) -> Vec<String> {
        cmd.get_subcommands()
            .map(|c| c.get_name().to_string())
            .collect()
    }

    #[test]
    fn build_command_wires_all_subcommands() {
        let cmd = build_command();
        assert_eq!(cmd.get_name(), "wallet");
        let names = subcommand_names(&cmd);
        for expected in [
            "new_address",
            "import_address",
            "export_address",
            "list_addresses",
            "address_balances",
            "change_password",
            "sign",
            "broadcast",
            "disconnect",
        ] {
            assert!(
                names.contains(&expected.to_string()),
                "missing subcommand {expected}"
            );
        }
    }

    #[test]
    fn send_transaction_command_name() {
        assert_eq!(build_send_transaction_command().get_name(), "transaction");
    }

    #[test]
    fn new_address_defaults_to_bech32_and_validates_type() {
        let m = build_new_address_command()
            .try_get_matches_from(["new_address"])
            .unwrap();
        assert_eq!(
            m.get_one::<String>("address_type").map(String::as_str),
            Some("bech32")
        );

        // An explicit valid type is accepted; an invalid one is rejected.
        assert!(build_new_address_command()
            .try_get_matches_from(["new_address", "--address-type", "taproot"])
            .is_ok());
        assert!(build_new_address_command()
            .try_get_matches_from(["new_address", "--address-type", "nonsense"])
            .is_err());
    }

    #[test]
    fn new_address_accepts_label() {
        let m = build_new_address_command()
            .try_get_matches_from(["new_address", "--label", "cold"])
            .unwrap();
        assert_eq!(
            m.get_one::<String>("label").map(String::as_str),
            Some("cold")
        );
    }

    #[test]
    fn import_address_parses_key_mnemonic_and_path() {
        let m = build_import_address_command()
            .try_get_matches_from([
                "import_address",
                "--private-key",
                "cKey",
                "--path",
                "m/84'/1'/0'/0/0",
                "--address-type",
                "p2pkh",
            ])
            .unwrap();
        assert_eq!(
            m.get_one::<String>("private_key").map(String::as_str),
            Some("cKey")
        );
        assert_eq!(
            m.get_one::<String>("path").map(String::as_str),
            Some("m/84'/1'/0'/0/0")
        );
    }

    #[test]
    fn export_address_requires_address_and_has_yes_flag() {
        // --address is required.
        assert!(build_export_address_command()
            .try_get_matches_from(["export_address"])
            .is_err());

        let m = build_export_address_command()
            .try_get_matches_from(["export_address", "--address", "bcrt1qx", "--yes"])
            .unwrap();
        assert_eq!(
            m.get_one::<String>("address").map(String::as_str),
            Some("bcrt1qx")
        );
        assert!(m.get_flag("yes"));

        // Short form -y also sets the flag.
        let m2 = build_export_address_command()
            .try_get_matches_from(["export_address", "--address", "bcrt1qx", "-y"])
            .unwrap();
        assert!(m2.get_flag("yes"));
    }

    #[test]
    fn sign_command_requires_rawtransaction_and_utxos_optional() {
        assert!(build_sign_command().try_get_matches_from(["sign"]).is_err());

        let m = build_sign_command()
            .try_get_matches_from(["sign", "--rawtransaction", "0200"])
            .unwrap();
        assert_eq!(
            m.get_one::<String>("rawtransaction").map(String::as_str),
            Some("0200")
        );
        assert!(m.get_one::<String>("utxos").is_none());
    }

    #[test]
    fn broadcast_command_requires_rawtransaction() {
        assert!(build_broadcast_command()
            .try_get_matches_from(["broadcast"])
            .is_err());
        let m = build_broadcast_command()
            .try_get_matches_from(["broadcast", "--rawtransaction", "deadbeef"])
            .unwrap();
        assert_eq!(
            m.get_one::<String>("rawtransaction").map(String::as_str),
            Some("deadbeef")
        );
    }

    #[test]
    fn address_balances_requires_address() {
        assert!(build_address_balances_command()
            .try_get_matches_from(["address_balances"])
            .is_err());
        let m = build_address_balances_command()
            .try_get_matches_from(["address_balances", "--address", "bcrt1qx"])
            .unwrap();
        assert_eq!(
            m.get_one::<String>("address").map(String::as_str),
            Some("bcrt1qx")
        );
    }
}
