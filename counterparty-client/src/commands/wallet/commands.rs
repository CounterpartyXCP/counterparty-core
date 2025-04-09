use clap::{Arg, ArgAction, Command};

/// Builds the main wallet command with its subcommands
pub fn build_command() -> Command {
    Command::new("wallet")
        .about("Manage your Counterparty wallet")
        .subcommand(build_add_address_command())
        .subcommand(build_show_address_command())
        .subcommand(build_list_addresses_command())
}

/// Builds the addaddress subcommand
fn build_add_address_command() -> Command {
    Command::new("add_address")
        .about("Generate or import a new Bitcoin address")
        .arg(
            Arg::new("private_key")
                .long("private-key")
                .help("Existing private key to import")
                .value_name("PRIVATE_KEY"),
        )
        .arg(
            Arg::new("mnemonic")
                .long("mnemonic")
                .help("BIP39 mnemonic phrase")
                .value_name("MNEMONIC"),
        )
        .arg(
            Arg::new("path")
                .long("path")
                .help("Derivation path (default: m/84'/0'/0'/0/0 for bech32)")
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
                .help("Type of address to generate (bech32 or p2pkh, default: bech32)")
                .value_name("TYPE")
                .value_parser(["bech32", "p2pkh"])
                .default_value("bech32"),
        )
}

/// Builds the showaddress subcommand
fn build_show_address_command() -> Command {
    Command::new("show_address")
        .about("Show details for a specific address")
        .arg(
            Arg::new("address")
                .long("address")
                .help("The blockchain address to show")
                .required(true)
                .value_name("ADDRESS"),
        )
        .arg(
            Arg::new("private_key")
                .long("private-key")
                .help("Show private key and other sensitive information")
                .action(ArgAction::SetTrue),
        )
}

/// Builds the addresses subcommand
fn build_list_addresses_command() -> Command {
    Command::new("list_addresses")
        .about("List all addresses in the wallet")
        .arg(
            Arg::new("verbose")
                .long("verbose")
                .help("Show detailed information")
                .action(ArgAction::SetTrue),
        )
}