[![Build Status Travis](https://travis-ci.org/CounterpartyXCP/counterparty-lib.svg?branch=develop)](https://travis-ci.org/CounterpartyXCP/counterparty-lib)
[![Build Status Circle](https://circleci.com/gh/CounterpartyXCP/counterparty-lib.svg?&style=shield)](https://circleci.com/gh/CounterpartyXCP/counterparty-lib)
[![Coverage Status](https://coveralls.io/repos/CounterpartyXCP/counterparty-lib/badge.png?branch=develop)](https://coveralls.io/r/CounterpartyXCP/counterparty-lib?branch=develop)
[![Latest Version](https://pypip.in/version/counterparty-lib/badge.svg)](https://pypi.python.org/pypi/counterparty-lib/)
[![License](https://pypip.in/license/counterparty-lib/badge.svg)](https://pypi.python.org/pypi/counterparty-lib/)
[![Slack Status](http://slack.counterparty.io/badge.svg)](http://slack.counterparty.io)


# Description
`counterparty-lib` is the reference implementation of the [Counterparty Protocol](https://counterparty.io).

**Note:** for the command-line interface that used to be called `counterpartyd`, see [`counterparty-cli`](https://github.com/CounterpartyXCP/counterparty-cli).


# Requirements
* [Patched Bitcoin Core](https://github.com/btcdrak/bitcoin/releases) with the following options set:

	```
	rpcuser=bitcoinrpc
	rpcpassword=<password>
	server=1
	txindex=1
	addrindex=1
	rpcthreads=1000
	rpctimeout=300
	minrelaytxfee=0.00005
	limitfreerelay=0
	```


# Installation

```
$ git clone https://github.com/CounterpartyXCP/counterparty-lib.git
$ cd counterparty-lib
$ python3 setup.py install
```


# Usage

```
$ python3
>>> from counterpartylib import server
>>> db = server.initialise(<options>)
>>> server.start_all(db)
```


# Further Reading

* [Official Project Documentation](http://counterparty.io/docs/)
