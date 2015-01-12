[![Build Status](https://travis-ci.org/CounterpartyXCP/counterpartyd.svg?branch=develop)](https://travis-ci.org/CounterpartyXCP/counterpartyd)
[![Coverage Status](https://coveralls.io/repos/CounterpartyXCP/counterpartyd/badge.png?branch=develop)](https://coveralls.io/r/CounterpartyXCP/counterpartyd?branch=develop)

# Description
`counterpartyd` is the reference implementation of the [Counterparty
Protocol](https://github.com/CounterpartyXCP/Counterparty).


# Dependencies
* [Python 3](http://python.org)
* Python 3 [packages](https://github.com/CounterpartyXCP/counterpartyd/blob/master/pip-requirements.txt)
* [Patched Bitcoin Core](https://github.com/btcdrak/bitcoin/releases/tag/addrindex-0.10.0) with the following options set:

```
rpcuser=bitcoinrpc
rpcpassword=$PASSWORD
txindex=1
server=1
addrindex=1
rpcthreads=1000
rpctimeout=300
```


# Versioning
* Major version changes require a full (automatic) rebuild of the database.
* Minor version changes require a(n automatic) database reparse.
* All protocol changes are retroactive on testnet.

# Installation

`pip install counterparty-lib`

or

```
git clone https://github.com/CounterpartyXCP/counterpartyd.git
cd counterpartyd
python setup.py install`
```

# Example

```
from counterparty import server

# initialise the server
db = server.initialise(...)

# start synchronisation with the blockchain and RPC server
server.start_all(db)
```

# Test suite

The test suite is invoked with `$ py.test` in the `counterparty` directory of the
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
