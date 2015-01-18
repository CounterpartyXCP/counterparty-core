[![Build Status](https://travis-ci.org/CounterpartyXCP/counterpartyd.svg?branch=develop)](https://travis-ci.org/CounterpartyXCP/counterpartyd)
[![Coverage Status](https://coveralls.io/repos/CounterpartyXCP/counterpartyd/badge.png?branch=develop)](https://coveralls.io/r/CounterpartyXCP/counterpartyd?branch=develop)

# Description
`counterpartyd` is the reference implementation of the [Counterparty
Protocol](https://github.com/CounterpartyXCP/Counterparty).


# Dependencies
* [Python 3](http://python.org)
* Python 3 [packages](https://github.com/CounterpartyXCP/counterpartyd/blob/master/pip-requirements.txt)
* The [jmcorgan](https://github.com/jmcorgan/bitcoin/tree/addrindex) branch of
  Bitcoin Core with the following options set:
```
rpcuser=bitcoinrpc
rpcpassword=$PASSWORD
txindex=1
server=1
addrindex=1
```


# Versioning
* Major version changes require a full (automatic) rebuild of the database.
* Minor version changes require a(n automatic) database reparse.
* All protocol changes are retroactive on testnet.

# Installation

Many systems still have Python 2 installed. Make sure that you're always using Python 3.
`apsw` requires SQLite 3.8.5 or higher.
```
$ pip3 install -r pip-requirements.txt
```

# Usage

To get started, run `$ counterpartyd.py --rpc-password=$PASSWORD server`.

For a summary of the available command‐line arguments and options, see
`$ counterpartyd.py --help` and `$ counterparty-cli.py --help`.

The test suite is invoked with `$ py.test` in the root directory of the
repository.


### Input and Output
* Quantities of divisible assets are written to eight decimal places.
* Quantities of indivisible assets are written as integers.
* All other quantities, i.e. prices, odds, leverages, feed values and target
values, fee multipliers, are represented internally as fractions, but printed
to four decimal places. Call prices are stored as integers with six decimal
places of precision.


# Further Reading

* [Official Documentation](http://counterparty.io/docs/)
* [Community Wiki](https://github.com/CounterpartyXCP/Community/wiki)
