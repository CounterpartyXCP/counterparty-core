// Declare submodules
pub mod args;
mod broadcast;
mod commands;
mod handlers;
mod quantity;
mod transaction;
pub mod utils;

// Re-export public functions and types
pub use broadcast::add_broadcast_commands;
pub use commands::build_command;

use anyhow::Result;
use clap::ArgMatches;
use std::collections::HashMap;

use crate::commands::api::ApiEndpoint;
use crate::config::AppConfig;
use crate::wallet::BitcoinWallet;

/// Executes a wallet command
pub async fn execute_command(
    config: &AppConfig,
    matches: &ArgMatches,
    endpoints: &HashMap<String, ApiEndpoint>,
    wallet: &mut BitcoinWallet,
) -> Result<()> {
    match matches.subcommand() {
        Some(("new_address", sub_matches)) => handlers::handle_new_address(wallet, sub_matches),
        Some(("import_address", sub_matches)) => {
            handlers::handle_import_address(wallet, sub_matches)
        }
        Some(("export_address", sub_matches)) => {
            handlers::handle_export_address(wallet, sub_matches)
        }
        Some(("list_addresses", _sub_matches)) => handlers::handle_list_addresses(wallet),
        Some(("address_balances", sub_matches)) => {
            // Pass the config directly to the handler
            handlers::handle_address_balances(config, sub_matches).await
        }
        Some(("transaction", send_tx_matches)) => {
            // Process send_transaction subcommands
            match send_tx_matches.subcommand() {
                Some((tx_name, sub_matches)) => {
                    transaction::handle_transaction_command(
                        config,
                        endpoints,
                        tx_name,
                        sub_matches,
                        wallet,
                    )
                    .await
                }
                _ => {
                    // No transaction type provided, display send_transaction help
                    let mut send_tx_cmd = commands::build_send_transaction_command();
                    send_tx_cmd.print_help()?;
                    println!();
                    Ok(())
                }
            }
        }
        Some(("sign", sub_matches)) => {
            // Process sign command
            transaction::handle_sign_command(config, sub_matches, wallet).await
        }
        Some(("broadcast", sub_matches)) => {
            // Process broadcast command
            transaction::handle_broadcast_command(config, sub_matches).await
        }
        Some(("change_password", sub_matches)) => {
            handlers::handle_change_password(wallet, sub_matches)
        }
        Some(("disconnect", sub_matches)) => handlers::handle_disconnect(wallet, sub_matches),

        _ => {
            // No subcommand provided, display help
            let mut wallet_cmd = commands::build_command();
            wallet_cmd.print_help()?;
            println!();
            Ok(())
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::Network;

    fn wallet() -> (BitcoinWallet, tempfile::TempDir) {
        let dir = tempfile::tempdir().unwrap();
        (
            BitcoinWallet::new_for_test(dir.path(), Network::Regtest),
            dir,
        )
    }

    /// Dispatch `args` through the full wallet command tree (built with the
    /// `transaction` subcommand so that arm is reachable) against a hermetic
    /// wallet and empty endpoint set. Returns nothing on success.
    async fn dispatch(args: &[&str]) {
        let config = AppConfig::new();
        let endpoints: HashMap<String, ApiEndpoint> = HashMap::new();
        let (mut w, _dir) = wallet();
        let tree = add_broadcast_commands(build_command(), &endpoints);
        let matches = tree.try_get_matches_from(args.iter().copied()).unwrap();
        execute_command(&config, &matches, &endpoints, &mut w)
            .await
            .unwrap();
    }

    #[tokio::test]
    async fn dispatches_new_address() {
        dispatch(&["wallet", "new_address"]).await;
    }

    #[tokio::test]
    async fn dispatches_list_addresses() {
        dispatch(&["wallet", "list_addresses"]).await;
    }

    #[tokio::test]
    async fn dispatches_import_address() {
        let wif = {
            let sk = bitcoin::secp256k1::SecretKey::from_slice(&[3u8; 32]).unwrap();
            bitcoin::PrivateKey::new(sk, bitcoin::Network::Regtest).to_wif()
        };
        dispatch(&["wallet", "import_address", "--private-key", wif.as_str()]).await;
    }

    #[tokio::test]
    async fn transaction_without_subcommand_prints_help() {
        dispatch(&["wallet", "transaction"]).await;
    }

    #[tokio::test]
    async fn no_subcommand_prints_wallet_help() {
        dispatch(&["wallet"]).await;
    }
}
