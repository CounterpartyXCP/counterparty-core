# Counterparty Client (`xcp`)

A command-line client for the [Counterparty](https://counterparty.io) v2 API and
a local, encrypted Bitcoin wallet. It composes, signs and broadcasts Counterparty
transactions against a Counterparty API server, and exposes the full API surface
as CLI commands.

The crate builds two identical binaries: **`xcp`** (short) and
**`counterparty-client`**.

> ⚠️ **Beta.** This client is new. Test on `signet`/`testnet4`/`regtest` before
> using it with real funds on `mainnet`, and **back up your keys** (see
> [Backups](#backups)).

## Install (from source)

There are no pre-built binaries yet — build from this repository.

Requires Rust **1.88 or newer** (stable) — see [rustup.rs](https://rustup.rs). (The
minimum is set by dependencies such as `keyring`; the CI `MSRV` job enforces it.)

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

The wallet DB is a single encrypted file (`cocoon`, written atomically) with
owner-only permissions on Unix. The password is stored in your OS keyring after
it is verified, so it is only cached once it actually unlocks the wallet.
`wallet disconnect` clears the stored password (and always works, even if the
wallet can't be unlocked). On a headless Linux server you need a running Secret
Service provider (e.g. `gnome-keyring`) for the keyring to work.

**Non-interactive password (`XCP_WALLET_PASSWORD`).** For automation, CI or a
headless server without a keyring, set the `XCP_WALLET_PASSWORD` environment
variable: it is used to create and unlock the wallet without a prompt (it must
still meet the 12-character minimum for a new wallet, and is verified before
use). Prefer the OS keyring for interactive use — an environment variable is
visible to other processes running as the same user (e.g. `/proc/<pid>/environ`
on Linux) and can leak into shell history, CI logs or crash dumps.

**Password & at-rest protection.** A new wallet password must be **at least 12
characters** and reasonably varied (a trivially repetitive one — a single
repeated character or a short repeating pattern — is rejected). Encryption at
rest uses `cocoon` (ChaCha20-Poly1305 with a PBKDF2 key derivation, a *fixed,
non-memory-hard* work factor): it protects a *stolen* `wallet.db` against offline
password guessing, with the strength of your passphrase as the main defence — so
choose a long, high-entropy one. It is **not** a substitute for OS-level disk encryption or for keeping
the file off shared/multi-user machines. Your private keys never leave the
machine: they are used to sign transactions locally and are never sent to the API
server.

**Transaction verification.** The server composes each transaction, but you sign
it locally — so for `send`, `enhanced_send` and `sweep` the client independently
decodes the transaction it is about to sign (straight from the raw bytes, not the
server's summary) and checks that:

- the **asset, quantity and destination** in the Counterparty payload match what
  you asked for; and
- the transaction's **BTC** goes only back to your source address (change) or to
  the requested destination — never to a third-party output — and the **miner fee**
  is below a sanity limit.

It **refuses to sign or broadcast on any mismatch**, which makes those transfers
safe even against a malfunctioning, compromised, or man-in-the-middled API server.
For a plain `--asset BTC` send the client also refuses any Counterparty message
hidden in the transaction's `OP_RETURN` (only a dispense trigger is allowed), and
a `sweep` requires an explicit `--flags` so its balance/ownership scope is always
verified. If a `send`/`enhanced_send`/`sweep` comes back in a form the client
cannot decode, that is **also** refused (fail-closed) — `--yes` does not override
it. `--yes` likewise never auto-confirms a transaction the client could not fully
verify — an unresolvable asset name, a **quantity whose decimal scale rests on the
server's reported divisibility** for a non-BTC/XCP asset, or a fee it could not
bound because the inputs are legacy or under-reported; it prints a warning and
still asks you to confirm.

Some things still rest on the server and are called out at run time:

- **Other transaction types** (issuance, order, dispenser, …) and the rare
  payload encodings the client does not decode (bare-multisig, taproot-envelope,
  pre-`taproot_support` legacy) **cannot** be independently verified: the client
  warns and falls back to the confirmation prompt — review them before confirming.
- **Sub-asset / non-standard asset names** cannot be resolved offline (they need
  the on-chain registry), so the *asset* field goes unchecked; the client says so
  explicitly (destination, quantity and BTC routing are still verified).
- **Divisibility** is looked up from the server, and human `--quantity` conversion
  depends on it, so a server that lies about an asset's divisibility could mis-size
  the amount (by a factor of 1e8) — always to *your* requested destination, never
  to a third party. Because that magnitude rests on the server, `--yes` will **not**
  auto-confirm such a transfer: the client shows the amount and asks you to confirm.
- **Legacy (P2PKH) inputs**: the legacy signature does not commit the input amount,
  so the displayed fee relies on the server-reported input values for those inputs.
  Prefer bech32/taproot addresses, whose signatures commit the amount.

**Transport.** On any public network the client **refuses a cleartext `http://`
API URL** and pins its HTTP client to HTTPS (so a redirect cannot downgrade the
scheme), because a network attacker able to read or *alter* the compose response
could otherwise change the transaction you sign. Only regtest (localhost) may use
`http://`.

## Wallet

```sh
# Create a new address (types: bech32 [default], p2pkh, taproot).
# This prints a BIP39 recovery phrase ONCE — write it down (see Backups).
xcp wallet new_address --label savings --address-type bech32

# Import an existing key or BIP39 mnemonic. Omit both secret flags to be
# prompted without echo, or read from a file with the @file form (recommended).
xcp wallet import_address --mnemonic "@/path/to/seed.txt" --address-type taproot
xcp wallet import_address --address-type taproot   # prompts for the secret

xcp wallet list_addresses
xcp wallet address_balances --address <address>

# Reveal an address's private key (prompts for confirmation; -y/--yes skips it)
xcp wallet export_address --address <address>

xcp wallet change_password
xcp wallet disconnect
```

> 🔒 Passing a secret directly (`--private-key <key>`, `--mnemonic <phrase>`)
> exposes it in your shell history and process list. Prefer the `@file` form
> (reads the secret from a file), or omit both flags to be prompted for the
> secret without echo.

### Backups

Each address is an **independent key**; there is no single wallet-wide seed.

- `new_address` derives a fresh key and shows its BIP39 mnemonic **once, at
  creation** — write it down. It is never stored and cannot be shown again.
- At any time you can reveal an address's private key (WIF) with
  `export_address`; that WIF is a complete backup of that one address.
- The wallet database (`wallet.db`) is encrypted, but treat it as sensitive and
  back it up too. It is written atomically, but a lost/corrupted file can only
  be recovered from the per-address mnemonics/WIFs above.

## Sending Counterparty transactions

`wallet transaction <type>` composes via the API, signs locally, shows a summary,
asks for confirmation, then broadcasts. One subcommand exists per `compose_*` API
function (`send`, `issuance`, `order`, `dispenser`, `dividend`, …). Pass
`-y`/`--yes` to skip the broadcast confirmation prompt (for scripting; the same
flag works on `wallet broadcast`).

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

# --json emits plain JSON on stdout (no colour, no YAML) for piping into jq etc.
xcp --json api get_block_by_height --block_index 100000 | jq .result.block_hash
```

Output is coloured YAML by default, but only when stdout is a terminal — piped or
redirected output is plain (no ANSI). Pass the global `--json` flag for
machine-readable JSON on stdout (status messages then go to stderr).

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

# Regtest integration tests (require a live counterparty-server at
# http://localhost:24000, plus bitcoin-cli on PATH for the E2E). These are
# #[ignore]d so a plain `cargo test` skips them:
#   * full_compose_send_scales_quantity_regtest — divisibility lookup + compose
#     reachability over HTTP (no signing/broadcasting);
#   * full_fund_compose_sign_broadcast_accept_regtest — a full black-box
#     fund → compose → sign → broadcast → accept cycle through the `xcp` binary,
#     signing with the client's own signer (tests/e2e_regtest.rs).
cargo test -- --ignored
```
