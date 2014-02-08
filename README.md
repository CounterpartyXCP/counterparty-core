# Changelog
* **v0.4**
* v0.3
* v0.2
* v0.1—initial release

# Description
Counterparty is a protocol for the creation and use of decentralised financial
instruments such as asset exchanges, contracts for difference and dividend
payments. It uses Bitcoin as a transport layer. The contents of this
repository, `counterpartyd`, constitute the reference implementation of the
protocol.

The Counterparty protocol specification may be found at
<https://github.com/PhantomPhreak/Counterparty>.

# Dependencies
* [Python 3](http://python.org)
* Python 3 packages: apsw, requests, appdirs, prettytable, python-dateutil, json-rpc, cherrypy, pycoin, pyzmq(v2.2+) (see [this link](https://github.com/xnova/counterpartyd_build/blob/master/dist/reqs.txt) for exact working versions)
* Bitcoind

# Installation

*NOTE: This section covers manual installation of counterpartyd. If you want more of
an automated approach to counterpartyd installation for Windows and Linux, see [this link](http://counterpartyd-build.readthedocs.org/en/latest/).*

In order for counterpartyd to function, it must be able to communicate with a
running instance of Bitcoind or Bitcoin-Qt, which handles many Bitcoin‐specific
matters on its behalf, including all wallet and private key management. For
such interoperability, Bitcoind must be run with the following options:
`-txindex=1` `-server=1`. This may require the setting of a JSON‐RPC password,
which may be saved in Bitcoind’s configuration file.

counterpartyd needs to know at least the JSON‐RPC password of the Bitcoind with
which it is supposed to communicate. The simplest way to set this is to
include it in all command‐line invocations of counterpartyd, such as
`./counterpartyd.py --rpc-password=PASSWORD ACTION`. To make this and other
options persistent across counterpartyd sessions, one may store the desired
settings in a configuration file specific to counterpartyd.

Note that the syntaxes for the countpartyd and the Bitcoind configuraion
files are not the same. A Bitcoind configuration file looks like this:

	rpcuser=bitcoinrpc
	rpcpassword=PASSWORD
	testnet=1
	txindex=1
	server=1

However, a counterpartyd configuration file looks like this:

	[Default]
	bitcoind-rpc-password=PASSWORD

Note the change in hyphenation between ‘rpcpassword’ and ‘rpc-password’.

If and only if counterpartyd is to be run on the Bitcoin testnet, with the
`--testnet` CLI option, Bitcoind must be set to do the same (`-testnet=1`).
counterpartyd may run with the `--testcoin` option on any blockchain,
however.

The test suite is invoked with `py.test`.

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

## Input and Output
* Quantities of divisible assets are written to eight decimal places.
* Quantities of indivisible assets are written as integers.
* All other quantities, i.e. prices, odds, leverages, feed values and target
values, fee multipliers, are specified to four decimal places.
* counterpartyd identifies an Order, Bet, Order Match or Bet Match by an
‘Order ID’, ‘Bet ID’, ‘Order Match ID’, or ‘Bet Match ID’, respectively. Match
IDs are concatenations of the hashes of the two transactions which compose the
corresponding Match, in the order of their appearances in the blockchain.


## Examples
The following examples are abridged for parsimony.

* Server

	The `server` command should always be running in the background. All other commands will fail if the index of the last block in the database is less than that of the last block seen by Bitcoind.

* Burn

	`burn --source=mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns --quantity=.5`

* Send divisible or indivisible assets

	```
	send --source=mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns --quantity=3 --asset=BBBC
	--to=n3BrDB6zDiEPWEE6wLxywFb4Yp9ZY5fHM7
	```

* Buy BTC for XCP
	
	```
	order --source=mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns --get-quantity=10 --get-asset=BTC
	--give-quantity=20 --give-asset=XCP --expiration=10 --fee_required=.001
	```

* Buy BBBC for BTC

	```
	order --source=mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns --get-quantity=10 --get-asset=BBBC
	--give-quantity=20 --give-asset=BTC --expiration=10 --fee_provided.001
	```

* Buy XCP for BBBC
	```
	order --source=mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns --get-quantity=10 --get-asset=XCP
	--give-quantity=20 --give-asset=BBBC --expiration=10
	```

* BTCPay

* Issue

	`issuance --source=mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns --quantity=100 --asset='BBBC'`

	`issuance --source=mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns --quantity=100 --asset='BBBQ' --divisible`

* Broadcast
	```
	broadcast --from=mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns --text="Bitcoin price feed" --value=825.22
	--fee-multiplier=0.001
	```

	Note: for some users counterpartyd has trouble parsing spaces in the --text argument. One workaround is to
		add an additional set of quotes. For example, --text='"Bitcoin price feed"'

* Bet

* Cancel
	```
	cancel --offer-hash=092f15d36786136c4d868c33356ec3c9b5a0c77de54ed0e96a8dbdd8af160c23
	```

* Dividend

* Market

	The `market` action prints out tables of open orders, open bets, feeds, and order matches currently awaiting 	        Bitcoin payments from one of your addresses. 
	
	It is capable of filtering orders by assets to be bought and sold.
	
	Example:
	
	To filter the market to only show offers to sell (give) BTC:
	```
	market --give-asset=BTC
	```
	
	To filter the market to only show offers to buy (get) BTC:
	```
	market --get-asset=BTC
	```
	
	To filter the market to only show offers to sell BTC for XCP:
	```
	market --give-asset=BTC --get-asset=XCP
	```

* Asset

	The `asset` action displays the basic properties of a given asset.

* Address

	The `address` action displays the details of of all transactions involving the Counterparty address which is its argument.

