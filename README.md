[![Build Status](https://travis-ci.org/CounterpartyXCP/counterpartyd.svg)](https://travis-ci.org/CounterpartyXCP/counterpartyd)
[![Build Status](https://circleci.com/gh/CounterpartyXCP/counterpartyd.svg?&style=shield)](https://circleci.com/gh/CounterpartyXCP/counterpartyd)
[![Coverage Status](https://coveralls.io/repos/CounterpartyXCP/counterpartyd/badge.png)](https://coveralls.io/r/CounterpartyXCP/counterpartyd)
[![Latest Version](https://pypip.in/version/counterparty-lib/badge.svg)](https://pypi.python.org/pypi/counterparty-lib/)
[![Wheel Status](https://pypip.in/wheel/counterparty-lib/badge.svg)](https://pypi.python.org/pypi/counterparty-lib/)
[![Supported Python versions](https://pypip.in/py_versions/counterparty-lib/badge.svg)](https://pypi.python.org/pypi/counterparty-lib/)
[![License](https://pypip.in/license/counterparty-lib/badge.svg)](https://pypi.python.org/pypi/counterparty-lib/)


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


# Further Reading

* [Official Project Documentation](http://counterparty.io/docs/)
