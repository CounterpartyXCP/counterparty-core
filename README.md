[![Build Status](https://travis-ci.org/CounterpartyXCP/counterpartyd.svg?branch=develop)](https://travis-ci.org/CounterpartyXCP/counterpartyd)
[![Coverage Status](https://coveralls.io/repos/CounterpartyXCP/counterpartyd/badge.png?branch=develop)](https://coveralls.io/r/CounterpartyXCP/counterpartyd?branch=develop)

# Description
`counterpartyd` is the reference implementation of the [Counterparty
Protocol](https://github.com/CounterpartyXCP/Counterparty).


# Dependencies
* [Python 3](http://python.org)
* [Python 3 packages](https://github.com/CounterpartyXCP/counterpartyd/blob/master/pip-requirements.txt)
* Bitcoin Core

Sometimes the underlying package requirements may change for `counterpartyd`.
If you build and installed it from scratch, you can manually update these
requirements by executing something like:
```
    pip3 install --upgrade -r pip-requirements.txt 
```

# Versioning
* Major version changes require a full (automatic) rebuild of the database.
* Minor version changes require a(n automatic) database reparse.
* All protocol changes are retroactive on testnet.


# Installation

**NOTE: This section covers manual installation of counterpartyd. If you want more of
an automated approach to counterpartyd installation for Windows and Linux, use
the [build system](http://counterparty.io/docs/build-system/).**

In order for counterpartyd to function, it must be able to communicate with a
running instance of Bitcoin Core, which handles many Bitcoin‐specific matters
on its behalf, including all wallet and private key management. For such
interoperability, Bitcoin Core must be run with the following options: `-txindex=1`
`-server=1`. This may require the setting of a JSON‐RPC password, which may be
saved in Bitcoin Core’s configuration file.

counterpartyd needs to know at least the JSON‐RPC password of the Bitcoin Core
with which it is supposed to communicate. The simplest way to set this is to
include it in all command‐line invocations of counterpartyd, such as
`./counterpartyd.py --rpc-password=PASSWORD ACTION`. To make this and other
options persistent across counterpartyd sessions, one may store the desired
settings in a configuration file specific to counterpartyd.

Note that the syntaxes for the countpartyd and the Bitcoin Core configuration
files are not the same. A Bitcoin Core configuration file looks like this:

	rpcuser=bitcoinrpc
	rpcpassword=PASSWORD
	testnet=1
	txindex=1
	server=1

However, a counterpartyd configuration file looks like this:

	[Default]
	backend-rpc-password=PASSWORD

Note the change in hyphenation between `rpcpassword` and `rpc-password`.

If and only if counterpartyd is to be run on the Bitcoin testnet, with the
`--testnet` CLI option, Bitcoin Core must be set to do the same (`-testnet=1`).
counterpartyd may run with the `--testcoin` option on any blockchain,
however.


# Usage
The command‐line syntax of counterpartyd is generally that of
`./counterpartyd.py {OPTIONS} ACTION {ACTION-OPTIONS}`. There is a one action
per message type, which action produces and broadcasts such a message; the
message parameters are specified following the name of the message type. There
are also actions which do not correspond to message types, but rather exist to
provide information about the state of the Counterparty network, e.g. current
balances or open orders.

For a summary of the command‐line arguments and options, see
`./counterpartyd.py --help`.

The test suite is invoked with `py.test` in the root directory of the repository.


### Input and Output
* Quantities of divisible assets are written to eight decimal places.
* Quantities of indivisible assets are written as integers.
* All other quantities, i.e. prices, odds, leverages, feed values and target
values, fee multipliers, are represented internally as fractions, but printed
to four decimal places. Call prices are stored as integers with six decimal
places of precision.


### Examples
See [the Counterparty Wiki](https://github.com/CounterpartyXCP/Community/wiki/CLI-Example-Usage).
