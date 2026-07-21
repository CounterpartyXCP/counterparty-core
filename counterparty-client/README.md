# Counterparty Client (`xcp`)

A command-line client for the [Counterparty](https://counterparty.io) v2 API and
a local, encrypted Bitcoin wallet. It composes, signs and broadcasts Counterparty
transactions against a Counterparty API server, and exposes the full API surface
as CLI commands.

The crate builds two identical binaries: **`xcp`** (short) and
**`counterparty-client`**.

> ⚠️ **Beta.** This client is new. Test on `signet`/`testnet4`/`regtest` before
> using it with real funds on `mainnet`, and keep a backup of your mnemonics.

## Install (from source)

There are no pre-built binaries yet — build from this repository.

Requires a recent stable [Rust toolchain](https://rustup.rs).

```sh
git clone https://github.com/CounterpartyXCP/counterparty-core.git
cd counterparty-core/counterparty-client

# Build the release binaries into ./target/release/{xcp,counterparty-client}
cargo build --release

# …or install them onto your PATH (~/.cargo/bin)
cargo install --path .
```

Verify the install:

```sh
xcp --version
```

## Networks

Pick the network with a global flag; the default is **mainnet**.

| Flag         | Network  | Default API endpoint                        |
|--------------|----------|---------------------------------------------|
| `--mainnet`  | Mainnet  | `https://api.counterparty.io:4000`          |
| `--signet`   | Signet   | `https://signet.counterparty.io:34000`      |
| `--testnet4` | Testnet4 | `https://testnet4.counterparty.io:44000`    |
| `--regtest`  | Regtest  | `http://localhost:24000`                    |

These defaults, and per-network paths, are written to a config file on first run
(see below); edit it to point at your own Counterparty API server.

## Files

| Purpose     | Location                                                          |
|-------------|------------------------------------------------------------------|
| Config      | `<data_dir>/counterparty-client/config.toml`                     |
| Wallet DB   | `<data_dir>/counterparty-client/<network>/wallet.db` (encrypted) |
| API cache   | `<cache_dir>/counterparty-client/<network>/…`                    |

`<data_dir>`/`<cache_dir>` follow the OS convention — e.g. on macOS
`~/Library/Application Support` and `~/Library/Caches`; on Linux
`~/.local/share` and `~/.cache`. Override the config path with `--config-file`.

The wallet DB is encrypted at rest (`cocoon`); the password is stored in your
OS keyring. `wallet disconnect` clears the cached password.

## Wallet

```sh
# Create a new address (types: bech32 [default], p2pkh, taproot)
xcp wallet new_address --label savings --address-type bech32

# Import an existing key or BIP39 mnemonic (use @file to read from a file)
xcp wallet import_address --mnemonic "@/path/to/seed.txt" --address-type taproot

xcp wallet list_addresses
xcp wallet address_balances --address <address>

# Reveal an address's private key (prompts for the wallet password)
xcp wallet export_address --address <address>

xcp wallet change_password
xcp wallet disconnect
```

## Sending Counterparty transactions

`wallet transaction <type>` composes via the API, signs locally, shows a summary,
asks for confirmation, then broadcasts. One subcommand exists per `compose_*` API
function (`send`, `issuance`, `order`, `dispenser`, `dividend`, …).

```sh
# Send 10 units of a divisible asset
xcp wallet transaction send --address <source> --destination <dest> \
    --asset XCP --quantity 10

# Issue 1000 of a new indivisible asset
xcp wallet transaction issuance --address <source> \
    --asset MYTOKEN --quantity 1000 --divisible false
```

**Quantities are human-readable here.** For a *divisible* asset, `--quantity 10`
means 10.0 units; decimals (up to 8 places) are accepted. For an *indivisible*
asset, the quantity must be a whole number. The client looks up each asset's
divisibility and converts to satoshis for you. (BTC-denominated fields such as a
dispenser's `mainchainrate` are always in satoshis.)

Sign and broadcast can also be run separately:

```sh
xcp wallet sign --rawtransaction <hex> [--utxos <json>]
xcp wallet broadcast --rawtransaction <signed-hex>
```

## Raw API access

Every API route is available under `api`. Use `api --help` to list them.

```sh
xcp api get_asset_info --asset XCP
xcp --testnet4 api get_block_by_height --block_index 100000
```

> Note: raw `api compose_*` commands are the expert path and expect **quantities
> in satoshis** (they are sent to the API verbatim). Use `wallet transaction …`
> for automatic, divisibility-aware amounts.

## Other

```sh
xcp --update-cache        # refresh the cached list of API endpoints
xcp completion            # generate shell completions (bash, zsh, fish, …)
```

## Development

```sh
cargo test                                   # unit + integration tests
cargo clippy --all-targets -- -D warnings
cargo fmt --check

# The full compose→sign→broadcast integration test needs a running regtest
# counterparty-server reachable at http://localhost:24000:
cargo test -- --ignored
```
