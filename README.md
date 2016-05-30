[![Build Status Travis](https://travis-ci.org/CounterpartyXCP/counterparty-lib.svg?branch=develop)](https://travis-ci.org/CounterpartyXCP/counterparty-lib)
[![Build Status Circle](https://circleci.com/gh/CounterpartyXCP/counterparty-lib.svg?&style=shield)](https://circleci.com/gh/CounterpartyXCP/counterparty-lib)
[![Coverage Status](https://coveralls.io/repos/CounterpartyXCP/counterparty-lib/badge.png?branch=develop)](https://coveralls.io/r/CounterpartyXCP/counterparty-lib?branch=develop)
[![Latest Version](https://pypip.in/version/counterparty-lib/badge.svg)](https://pypi.python.org/pypi/counterparty-lib/)
[![License](https://pypip.in/license/counterparty-lib/badge.svg)](https://pypi.python.org/pypi/counterparty-lib/)
[![Slack Status](http://slack.counterparty.io/badge.svg)](http://slack.counterparty.io)
[![Docker Pulls](https://img.shields.io/docker/pulls/counterparty/counterparty-server.svg?maxAge=2592000)](https://hub.docker.com/r/counterparty/counterparty-server/)


# Description
`counterparty-lib` is the reference implementation of the [Counterparty Protocol](https://counterparty.io).

**Note:** for the command-line interface, see [`counterparty-cli`](https://github.com/CounterpartyXCP/counterparty-cli).


# Installation

For a simple Docker-based install of the Counterparty software stack, see [this guide](http://counterparty.io/docs/federated_node/).


# Manual installation

Download the newest [patched Bitcoin Core](https://github.com/btcdrak/bitcoin/releases) and create
a `bitcoin.conf` file with the following options:

```
rpcuser=bitcoinrpc
rpcpassword=rpc
server=1
txindex=1
addrindex=1
rpcthreads=100
rpctimeout=300
```

Then, download and install `counterparty-lib`:

```
$ git clone https://github.com/CounterpartyXCP/counterparty-lib.git
$ cd counterparty-lib
$ python3 setup.py install
```

Followed by `counterparty-cli`:

```
$ git clone https://github.com/CounterpartyXCP/counterparty-cli.git
$ cd counterparty-cli
$ python3 setup.py install
```

Then, launch the daemon via:

```
$ counterparty-server bootstrap
$ counterparty-server --backend-password=rpc start
```

Further command line options are available via:

* `$ counterparty-server --help`
* `$ counterparty-client --help`


# Python interface

Bare usage from Python is also possible, without installing `counterparty-cli`:

```
$ python3
>>> from counterpartylib import server
>>> db = server.initialise(<options>)
>>> server.start_all(db)
```


# Travis/Circle CI
 - TravisCI is setup to run all tests with 1 command and generate a coverage report and let `python-coveralls` parse and upload it.
   It does runs with `--skiptestbook=all` so it will not do the reparsing of the bootstrap files.
 - CircleCI is setup to split the tests as much as possible to make it easier to read the error reports.
   It also runs the `integration_test.test_book` tests, which reparse the bootstrap files.


# Further Reading

* [Official Project Documentation](http://counterparty.io/docs/)
