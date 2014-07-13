## Client Versions ##
* v9.31.0 (2014-07-10)
	* change fee_required calculation for orders matching (protocol change: 310500)
	* don’t skip negative get quantity remainig for orders matching (protocol change: 310500)
* v9.30.0 (2014-07-06)
	* hotfix for error in block 309485
* v9.29.4 (2014-07-05)
	* Armory support
* v9.29.3 (2014-06-26)
	* bug in RPS re-matching
* v9.29.2 (2014-06-26)
	* bug in fee calculation
* v9.29.1 (2014-06-26)
	* 'publish' command (compose only)
* v9.29.0 (2014-06-26)
	* bug fixes
* v9.28.0 (2014-06-26)
	* add rps and rpsresolve transactions (protocol change: 308500)
* v9.27.0 (2014-06-25)
	* extend order match expiration time to 20 blocks (protocol change: 308000)
* v9.26.2 (2014-06-17)
	* currency agnosticism
* v9.26.1
	* automatic transaction encoding
* v9.26.0
	* *major* speed‐up in reparsing
	* support for mempool (so‐called ‘unconfirmed’ or ‘zero‐confirmation’) transactions
* v9.25.0
	* issuance fee only upon first issuance (protocol change: 310000)
	* misc. clean‐up
	* make dust sizes user‐configurable per‐tx (through API)
	* bet debug logging
	* tweak issuance parsing logic (minor protocol change: 310000)
	* constituent orders of expired order matches re‐match (protocol change: 310000)
* v9.24.2
	* bug in version checking: mandatory manual upgrade
* v9.24.1
	* replace internal Python filters with SQL queries (much faster parsing)
	* totally re‐did API: now much faster, more powerful (almost entirely backwards‐compatible: see API documentation)
* v9.24.0
	* bug in previous version
* v9.23.0
	* allow assets to be traded for themselves
* v9.22.0
	* bug in previous bugfix
* v9.21.0
	* bug in bet parsing
* v9.20.0
	* remove deadline checking in bets
	* functionality to drop open bets, pending bet matches
* v9.19.0
	* speed up catching up with blockchain
	* raw SQL query API method
	* fractional leverage with CFDs
	* bug fixes
* v9.18.0
	* tweaked test suite
	* fixed failed sanity check on testnet
* v9.17.0
	* failed XCP conservation sanity check on testnet (deadline checking in bets)
* v9.16.3
	* bug fixes
* v9.16.2
	* order bug in last version
	* improve `--force`
* v9.16.1
	* allow exact fees to be specified in CLI
	* improved algorithm for choosing unspent txouts in transaction construction
	* allow the unconfirmed inputs CLI option
* v9.16
	* regular version, database, Bitcoind checking in API
	* better testcoin support
	* simplify version checking (combined DB and client versions), which necessitates skipping versions
	* simplify betting fees: just deduct from pot at settlement (protocol change: retroactive)
	* CLI option for frequency of asset conservation sanity checks
* v6.15
	* bug in calculation of holders (protocol change: retroactive)
* v6.14
	* fully floating transaction fees
	* lots of miscellaneous bug fixes
	* replenish fee_required_remaining on order match expiration (protocol change: 297000)
	* transaction signing for source addresses not in Bitcoin Core wallet
	* tweaks to API
* v6.13
	* miscellaneous bug fixes
	* add some sanity checks
	* partially allow for CLI input of private keys (to bypass Bitcoind wallet)
	* tweak the API
	* fill out the test suite a bit
	* temporarily double the default fee to .0002 BTC
* v6.12
* v6.11
* v6.10
* v6.9
* v6.8
* v6.8
* v6.7
* v6.6
* v6.5
* v6.4
* v6.3
* v6.2
* v6.1
* v6.0
* v5.3
* v5.2
* v5.1
* v5.0
* v4.3
* v0.4.2
* v0.4.1
* v0.4
* v0.3
* v0.2
* v0.1
	* initial release

## Other Protocol Changes ##
* issuances fees regression: 285306
* double credits on order match expirations: retroactive
* arbitrary spend with multi‐sig input: retroactive
* deduct `fee_required`, too: 287800
* value, quantity, etc. sanity checking: retroactive
* reduce issuance fee to 0.5 XCP: 291700
* match only with positive get/counterwager remaining: 292000
* pay‐to‐pubkeyhash encoding: 293000
* filtered negative order fees: 294000
* dividends on escrowed funds: 294500
* fractions, not decimals, for rounding: 294500
* no dividends to self: 296000
