Counterparty
============
Decentralised financial instruments in a protocol build on top of the Bitcoin blockchain

## Description
* Embeds data in the blockchain using `OP_RETURN`.

## Dependencies
* Python 3
* SQLite3, Requests, AppDirs, Colorama
* Bitcoind

## Instructions
* Make sure that you are running Bitcoind (or another compatible Bitcoin client) locally and with transaction indexing and the JSON‐RPC interface enabled (options `-txindex` and `-server`).
	* Right now, Counterparty should only be used on testnet, for which the command‐line option `-testnet` should given too.
* Run `python3 counterparty.py follow` in one terminal.
* In another, run any of counterparty’s other functions (e.g. `python3 counterparty.py send` or `python3 counterparty.py order`).
* Entities selling an asset for BTC should require a fee be paid (to miners) by the buyer. (But all orders allow this.) Otherwise someone can seem to accept every sell offer.

## To do
* Bets and CFDs
* API

## Limitations
* No market orders.
* No all‐or‐none orders; but the Chicago Board Options Exchange doesn’t allow those either.
* No changing open orders.

## Launch
* Release testnet a couple of weeks before 0.9 is supposed to come out (e.g. with Bitcoin 0.9 RC 1).
	* testnet practice funding period
		* Cap at 1 BTC per address.
		* Bonus proportional to block number.
		* [Proof of burn](https://en.bitcoin.it/wiki/Proof_of_burn#Coin-burning_as_a_tool_for_transition_between_cryptocurrencies)
* Release 1.0 and start real proof of burn as soon after Bitcoin 0.9 as possible.
* Actual funding by donation.
* Register domain(s).
