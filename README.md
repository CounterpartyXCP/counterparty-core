Counterparty
============
Decentralised financial instruments in a protocol build on top of the Bitcoin blockchain

## Description
* Embeds data in the blockchain using `OP_RETURN`.
* A virtual asset (for example, an IOU) is just an indivisible asset with one unit (a satoshi).

## Dependencies
* Python 3
* SQLite3, Requests, AppDirs
* Bitcoind

## Instructions
* Make sure that you are running Bitcoind (or another compatible Bitcoin client) locally and with transaction indexing and the JSON‐RPC interface enabled (options `-txindex` and `-server`).
	* Right now, Counterparty should only be used on testnet, for which the command‐line option `-testnet` should given too.
* Run `python3 counterparty.py follow` in one terminal.
* In another, run any of counterparty’s other functions (e.g. `python3 counterparty.py send` or `python3 counterparty.py history`).
* Divisible amounts are written as floats; indivisible amounts are written as ints.
* Entities selling an asset for BTC should require a fee be paid (to miners) by the buyer. (But all orders allow this.) Otherwise someone can seem to accept every sell offer.

## To do
* API
* Dividends: `sendall(amount, asset_id)`
* Price feeds, bets (e.g. CFDs)
	* Price feeds must be in XCP only (and dividends).
	* Feed identifier is derived from `tx_hash`.
	* No display muliplier.
	* Pascal strings.
	* Currencies with price feeds and unautomated pegs?
	* Reannounces? Renounces?
	* Bets may have to be able to use `block_time`.
* Asset ID strings
	* Hand‐picked Base58‐encoded 8‐byte Pascal strings (length?, checksum? version byte? leading zeros?)
	* Full‐length, except for XBT, XCP, which are hard‐coded in?
		* Just require full‐length for the *issuance* of all other currencies (XBT, XCP are created otherwise).
* testnet practice funding period

## Limitations
* No market orders.
* No all‐or‐none orders; but the Chicago Board Options Exchange doesn’t allow those either.
* No changing open orders.

## Launch
* Release testnet a couple of weeks before 0.9 is supposed to come out (e.g. with Bitcoin 0.9 RC 1).
* Release 1.0 and start proof of burn as soon after Bitcoin 0.9 as possible.
* Price feeds for gambling, major fiat currencies, precious metals.
* Proof of burn: send Bitcoins to address `Counterparty0000000<hash>` between two block indexs (inclusive).
	* 100x multiplier (for divisibility)?
	* Alternatives: a new message type with exorbitant fees, throw away the money on `OP_RETURN`. (These are harder to understand, suggest false positives.)
	* [Proof of burn](https://en.bitcoin.it/wiki/Proof_of_burn#Coin-burning_as_a_tool_for_transition_between_cryptocurrencies)
	* Recommend no more than 1 BTC. (Cap per address as disincentive.)
	* Bonus proportional to block number.
* Funding by donation.
* Register domain(s).
