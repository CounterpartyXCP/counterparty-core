## Client Versions ##
* v9.16 (unreleased)
	* simplify version checking (combined DB and client versions), which necessitates skipping versions
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
