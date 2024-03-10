[![Build Status Circle](https://circleci.com/gh/CounterpartyXCP/counterparty-core.svg?&style=shield)](https://circleci.com/gh/CounterpartyXCP/counterparty-core)


# Description
`counterparty-lib` is the reference implementation of the [Counterparty Protocol](https://counterparty.io).

**Note:** for the command-line interface to `counterparty-lib`, see [`counterparty-cli`](https://github.com/CounterpartyXCP/counterparty-cli).


# Getting Started

The simplest way to get your Counterparty node up and running is to use Docker Compose.

```
sudo apt install docker-compose
```

Then, for `mainnet`, run:

```bash
docker-compose -f simplenode/compose.yml up
```

For `testnet`, modify the Docker Compose file in `simplenode/` and then run:
```bash
docker-compose -f simplenode/compose.yml -p simplenode-testnet up
```

Wait for your node to catch up with the network.


# Manual Installation

Dependencies:

- Bitcoin Core
- Addrindexrs
- Python >= 3.10
- Rust
- Maturin
- Leveldb

## Install dependencies

### Install Bitcoin Core

Download the latest [Bitcoin Core](https://github.com/bitcoin/bitcoin/releases) and create
a `bitcoin.conf` file (by default located in `~.bitcoin/`) with the following options:

```
rpcuser=rpc
rpcpassword=rpc
server=1
addresstype=legacy
txindex=1
prune=0
mempoolfullrbf=1
```

Adding the following lines, and opening up port `8333` to incoming traffic may improve your sync speed:

```
listen=1
dbcache=4000
```

### Install Rust

The recommended way to install Rust is to use `rustup`:

```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

See https://www.rust-lang.org/tools/install for more information.


### Install Addrindexrs

Download and install the latest [Addrindexrs](https://github.com/CounterpartyXCP/addrindexrs):

```bash
git clone https://github.com/CounterpartyXCP/addrindexrs.git
cd addrindexrs
# Set the necessary environment variables
export ADDRINDEXRS_JSONRPC_IMPORT=1
export ADDRINDEXRS_COOKIE=rpc:rpc
cargo build --release
ulimit -n 8192
cargo run --release -- -vvv
```

### Install Python >= 3.10 and Maturin

On Ubuntu 22.04 and similar:

```
apt-get install -y python3 python3-dev python3-pip
pip3 install maturin
```

On MacOS:

```
brew install python
pip3 install maturin
```

See https://brew.sh/ to install Homewrew.


### Install Leveldb

On Ubuntu 22.04 and similar:

```
apt-get install -y libleveldb-dev
```

On MacOS:

```
brew install leveldb
```

## Install Counterparty Core

Download the latest version `counterparty-core`:

```
git clone https://github.com/CounterpartyXCP/counterparty-core.git
```

Install `counterparty-rs`:

```
cd counterparty-core/counterparty-rs
pip3 install .
```

Install `counterparty-lib`:

```
cd counterparty-core/counterparty-lib
pip3 install .
```

Install `counterparty-cli`:

```
cd counterparty-core/counterparty-cli
pip3 install .
```

*Note for MacOS user*

Use this command if you get an error while installing one of the packages:

```
CFLAGS="-I/opt/homebrew/include -L/opt/homebrew/lib"
```

# Usage

## Configuration

Manual configuration is not necessary for most use cases, but example configuration files may be found in the (docker/) directory.

By default, the **configuration files** are named `server.conf` and `client.conf` and located in the following directories:

* Linux: `~/.config/counterparty/`
* Windows: `%APPDATA%\Counterparty\`

Client and Server log files are named `counterparty.client.[testnet.]log` and `counterparty.server.[testnet.]log`, and located in the following directories:

* Linux: `~/.cache/counterparty/log/`
* Windows: `%APPDATA%\Local\Counterparty\counterparty\Logs`

Counterparty API activity is logged in `server.[testnet.]api.log` and `client.[testnet.]api.log`.

Counterparty database files are by default named `counterparty.[testnet.]db` and located in the following directories:

* Linux: `~/.local/share/counterparty`
* Windows: `%APPDATA%\Roaming\Counterparty\counterparty`

All configurable parameters in the configuration file can also be passed as a `counterpart-server` argument. Use `counterparty-server --help` to see the list of these settings.

## Catch up on the latest block

You will not be able to run `counterparty-server` until `addrindexrs` has caught up (and its RPC server is running), which in turn requires `bitcoind` have caught up as well.

When `bitcoind` and `addrindexrs` have caught up, Counterparty-server must parse all blocks before being operational. This initial parsing can take a very long time. There are three different ways to catch-up:

1. The classic way using the `start` command. This command is normally used when the database is up to date and contains almost all the blocks. This method is the longest and can take several weeks on a small setup.

        counterparty-server start

2. The `kickstart` command. This operation requires stopping Bitcoin Core and will read the blocks directly from the *.blk files. This method takes less than 24 hours on a small configuration.

        counterparty-server kickstart

3. The `bootstrap` command. This command downloads a database from a centralized server maintained by the Counterparty Core developers. **The `bootstrap` should not be used for commercial or public-facing nodes.**

        counterparty-server bootstrap


## Start the server

If you used the `kickstart` or `bootstrap` command to catch up the last blocks you must then start the server with `start`:

```
counterparty-server start
```

# Further Reading

* [Official Project Documentation](http://counterparty.io/docs/)
