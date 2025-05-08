use clap::{Arg, Command};

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
                .required(true)
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
