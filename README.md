[![Build Status](https://travis-ci.org/CounterpartyXCP/counterpartyd.svg?branch=develop)](https://travis-ci.org/CounterpartyXCP/counterpartyd)
[![Build Status](https://circleci.com/gh/CounterpartyXCP/counterpartyd.svg?&style=shield)](https://circleci.com/gh/CounterpartyXCP/counterpartyd)
[![Coverage Status](https://coveralls.io/repos/CounterpartyXCP/counterpartyd/badge.png?branch=develop)](https://coveralls.io/r/CounterpartyXCP/counterpartyd?branch=develop)

# Description
`counterparty-lib` is the reference implementation of the [Counterparty Protocol](https://counterparty.io).


# Requirements
* [Patched Bitcoin Core](https://github.com/btcdrak/bitcoin/releases) with the following options set:

```
rpcuser=bitcoinrpc
rpcpassword=$PASSWORD
txindex=1
server=1
addrindex=1
rpcthreads=1000
rpctimeout=300
```


# Installation

```
git clone https://github.com/CounterpartyXCP/counterpartyd.git
cd counterpartyd
python3 setup.py install`
```

# Usage

```
from counterpartylib import server

# initialise the server
db = server.initialise(...)

# start synchronisation with the blockchain and RPC server
server.start_all(db)
```

# Test suite

The test suite is invoked with `$ py.test-3.4` in the `counterpartylib` directory of the
repository.


# Further Reading

* [Official Project Documentation](http://counterparty.io/docs/)
