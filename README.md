Counterparty
============
Decentralised financial instruments in a protocol build on top of the Bitcoin blockchain

## Description
Counterparty is a protocol for the creation and use of decentralised financial instruments such as asset exchanges, contracts for difference and dividend payments.

The contents of this repository, `counterpartyd`, constitute the reference implementation of the protocol.

The Counterparty documentation may be found at <http://counterparty.rtd.org>.

## Dependencies
* Python 3
* Python 3 packages: SQLite3, Requests, AppDirs, Colorama, PrettyTable
* Bitcoind

## Instructions
* Make sure that you are running Bitcoind (or another compatible Bitcoin client) locally and with transaction indexing and the JSON‐RPC interface enabled (options `-txindex` and `-server`).
	* Right now, Counterparty should only be used on testnet, for which the command‐line option `-testnet` should given too.
* Run `python3 counterpartyd.py` in one terminal.
* In another terminal, run any of counterparty’s other functions (e.g. `python3 counterpartyd.py send` or `python3 counterpartyd.py order`).
* Test with `py.test test.py`.
