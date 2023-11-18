[![Build Status Travis](https://travis-ci.org/CounterpartyXCP/counterparty-lib.svg?branch=develop)](https://travis-ci.org/CounterpartyXCP/counterparty-lib)
[![Build Status Circle](https://circleci.com/gh/CounterpartyXCP/counterparty-lib.svg?&style=shield)](https://circleci.com/gh/CounterpartyXCP/counterparty-lib)
[![Coverage Status](https://coveralls.io/repos/CounterpartyXCP/counterparty-lib/badge.png?branch=develop)](https://coveralls.io/r/CounterpartyXCP/counterparty-lib?branch=develop)
[![Latest Version](https://pypip.in/version/counterparty-lib/badge.svg)](https://pypi.python.org/pypi/counterparty-lib/)
[![License](https://pypip.in/license/counterparty-lib/badge.svg)](https://pypi.python.org/pypi/counterparty-lib/)
[![Docker Pulls](https://img.shields.io/docker/pulls/counterparty/counterparty-server.svg?maxAge=2592000)](https://hub.docker.com/r/counterparty/counterparty-server/)


# Description
`counterparty-lib` is the reference implementation of the [Counterparty Protocol](https://counterparty.io).

**Note:** for the command-line interface to `counterparty-lib`, see [`counterparty-cli`](https://github.com/CounterpartyXCP/counterparty-cli).


# Installation

**WARNING** Master branch should only be used for testing. For production releases uses tagged releases.

For a simple Docker-based install of the Counterparty software stack, see [this guide](http://counterparty.io/docs/federated_node/).


# Manual installation

Download the latest [Bitcoin Core](https://github.com/bitcoin/bitcoin/releases) and create
a `bitcoin.conf` file with the following options:

```
rpcuser=bitcoinrpc
rpcpassword=rpc
server=1
txindex=1
rpctimeout=300
zmqpubhashblock=tcp://127.0.0.1:28832
zmqpubhashtx=tcp://127.0.0.1:28832
addresstype=legacy
```
**Note:** you can and should replace the RPC credentials. Remember to use the changed RPC credentials throughout this document.

Download and install latest addrindexrs:
```
$ git clone https://github.com/CounterpartyXCP/addrindexrs.git
$ cd addrindexrs
$ cargo check
 -- Setup the appropiate environment variables --
  - ADDRINDEXRS_JSONRPC_IMPORT=1
  - ADDRINDEXRS_TXID_LIMIT=15000
  - ADDRINDEXRS_COOKIE=user:password
  - ADDRINDEXRS_INDEXER_RPC_ADDR=0.0.0.0:8432
  - ADDRINDEXRS_DAEMON_RPC_ADDR=bitcoin:8332
 --
$ cargo build --release
$ cargo run --release
```

You could run the indexd daemon with a process manager like `forever` or `pm2` (recommended).

Then, download and install `counterparty-lib`:

```
$ git clone https://github.com/CounterpartyXCP/counterparty-lib.git
$ cd counterparty-lib
$ sudo pip3 install --upgrade -r requirements.txt
$ sudo python3 setup.py install
```

Followed by `counterparty-cli`:

```
$ git clone https://github.com/CounterpartyXCP/counterparty-cli.git
$ cd counterparty-cli
$ sudo pip3 install --upgrade -r requirements.txt
$ sudo python3 setup.py install
```

Note on **sudo**: both counterparty-lib and counterparty-server can be installed by non-sudoers. Please refer to external documentation for instructions on using pip without root access and other information related to custom install locations.


Then, launch the daemon via:

```
$ counterparty-server bootstrap
$ counterparty-server --backend-password=rpc start
```

# Basic Usage

## Via command-line

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

Manual configuration is not necessary for most use cases. "back-end" and "wallet" are used to access Bitcoin server RPC.

A `counterparty-server` configuration file looks like this:

	[Default]
	backend-name = indexd
	backend-user = <user>
	backend-password = <password>
	indexd-connect = localhost
	indexd-port = 8432
	rpc-host = 0.0.0.0
	rpc-user = <rpcuser>
	rpc-password = <rpcpassword>

The ``force`` argument can be used either in the server configuration file or passed at runtime to make the server keep running in the case it loses connectivity with the Internet and falls behind the back-end database. This may be useful for *non-production* Counterparty servers that need to maintain RPC service availability even when the backend or counterparty server has no Internet connectivity.

A `counterparty-client` configuration file looks like this:

	[Default]
	wallet-name = bitcoincore
	wallet-connect = localhost
	wallet-user = <user>
	wallet-password = <password>
	counterparty-rpc-connect = localhost
	counterparty-rpc-user = <rpcuser>
	counterparty-rpc-password = <password>


# Developer notes

## Versioning

* Major version changes require a full (automatic) rebuild of the database.
* Minor version changes require a(n automatic) database reparse.
* All protocol changes are retroactive on testnet.

## Continuous integration
 - TravisCI is setup to run all tests with 1 command and generate a coverage report and let `python-coveralls` parse and upload it.
   It does runs with `--skiptestbook=all` so it will not do the reparsing of the bootstrap files.
 - CircleCI is setup to split the tests as much as possible to make it easier to read the error reports.
   It also runs the `integration_test.test_book` tests, which reparse the bootstrap files.


# Further Reading

* [Official Project Documentation](http://counterparty.io/docs/)
