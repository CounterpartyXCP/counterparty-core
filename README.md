[![Latest Version](https://pypip.in/version/counterparty-cli/badge.svg)](https://pypi.python.org/pypi/counterparty-cli/)
[![Supported Python versions](https://pypip.in/py_versions/counterparty-cli/badge.svg)](https://pypi.python.org/pypi/counterparty-cli/)
[![License](https://pypip.in/license/counterparty-cli/badge.svg)](https://pypi.python.org/pypi/counterparty-cli/)


# Description

`counterparty-cli` is a command line interface for [`counterparty-lib`](https://github.com/CounterpartyXCP/counterpartyd).


# Requirements

* [Patched Bitcoin Core](https://github.com/btcdrak/bitcoin/releases) with the following options set:

	```
	rpcuser=bitcoinrpc
	rpcpassword=<password>
	txindex=1
	server=1
	addrindex=1
	rpcthreads=1000
	rpctimeout=300
	```

# Installation

```
$ git clone https://github.com/CounterpartyXCP/counterparty-cli.git
$ cd counterparty-cli
$ python3 setup.py install
```


# Usage

* `$ counterparty-server --help`

* `$ counterparty-client --help`


# Further Reading

* [Official Project Documentation](http://counterparty.io/docs/)
