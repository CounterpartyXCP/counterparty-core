[![Build Status Circle](https://circleci.com/gh/CounterpartyXCP/counterparty-lib.svg?&style=shield)](https://circleci.com/gh/CounterpartyXCP/counterparty-lib)


# Description
`counterparty-lib` is the reference implementation of the [Counterparty Protocol](https://counterparty.io).

**Note:** for the command-line interface to `counterparty-lib`, see [`counterparty-cli`](https://github.com/CounterpartyXCP/counterparty-cli).


# Getting Started

The simplest way to get your Counterparty node up and running is to use Docker Compose.

```
$ sudo apt install docker-compose
```

Then, for `mainnet`, run:

```bash
$ docker-compose -f simplenode/compose.yml up
```

For `testnet`, modify the Docker Compose file in `simplenode/` and then run:
```bash
$ docker-compose -f simplenode/compose.yml -p simplenode-testnet up
```

Wait for your node to catch up with the network.


# Manual Installation

**WARNING** The `master` branch should only be used as a development target. For production, use only the latest tagged release.

Download the latest [Bitcoin Core](https://github.com/bitcoin/bitcoin/releases) and create
a `bitcoin.conf` file (by default located in `~.bitcoin/`) with the following options:

```
rpcport=8332
rpcuser=bitcoinrpc
rpcpassword=rpc
server=1
printtoconsole=1
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

Download and install latest `addrindexrs`:

```bash
$ sudo apt install cargo libclang-dev build-essential
$ git clone https://github.com/CounterpartyXCP/addrindexrs.git
$ cd addrindexrs
$ cargo build --release
$ cargo run --release -- -vvv --jsonrpc-import=1 --txid-limit=15000 --cookie="bitcoinrpc:rpc" --indexer-rpc-addr="0.0.0.0:8432" --daemon-rpc-addr="localhost:8332"
```

Now, download and install `counterparty-lib`:

```bash
$ sudo apt install python3-pip
$ git clone https://github.com/CounterpartyXCP/counterparty-lib.git
$ brew install leveldb                                                # macOS-only
$ CFLAGS="-I/opt/homebrew/include -L/opt/homebrew/lib"                # macOS-only
$ pip3 install -e .
```

Followed by `counterparty-cli`:

```bash
$ git clone https://github.com/CounterpartyXCP/counterparty-cli.git
$ cd counterparty-cli
$ pip3 install -e .
```

Then, launch the daemon via:

```bash
$ counterparty-server bootstrap
$ counterparty-server start
```

**WARNING:** The `bootstrap` should not be used for commercial or public-facing nodes.

**Note:** You will not be able to run `counterparty-server` until `addrindexrs` has caught up (and its RPC server is running), which in turn requires `bitcoind` have caught up as well.


# Basic Usage

## via command-line

(Requires `counterparty-cli` to be installed.)

* The first time you run the server, you may bootstrap the local database with:
	`$ counterparty-server bootstrap`

* Start the server with:
	`$ counterparty-server start`

* Check the status of the server with:
	`$ counterparty-client getinfo`

* For additional command-line arguments and options:
	`$ counterparty-server --help`
	`$ counterparty-client --help`

## Via Python

Bare usage from Python is also possible, without installing `counterparty-cli`:

```
$ python3
>>> from counterpartylib import server
>>> db = server.initialise(<options>)
>>> server.start_all(db)
```

# Configuration and Operation

The paths to the **configuration** files, **log** files and **database** files are printed to the screen when starting the server in ‘verbose’ mode:
	`$ counterparty-server --verbose start`

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

## Configuration File Format

Manual configuration is not necessary for most use cases, but example configuration files may be found in the <docker/> directory.

The ``force`` argument can be used either in the server configuration file or passed at runtime to make the server keep running in the case it loses connectivity with the Internet and falls behind the back-end database. This may be useful for *non-production* Counterparty servers that need to maintain RPC service availability even when the backend or counterparty server has no Internet connectivity.


# Developer notes

## Versioning

* Major version changes require a full (automatic) rebuild of the database.
* Minor version changes require a(n automatic) database reparse.
* All protocol changes are retroactive on testnet.


# Further Reading

* [Official Project Documentation](http://counterparty.io/docs/)
