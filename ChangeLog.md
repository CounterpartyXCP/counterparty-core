## Library Versions ##
* v9.59.1 (2021-01-17)
    * Fixed api issues while building P2SH encoded transactions
* v9.59.0 (2021-01-11)
    * Empty address dispensers
    * Added addrindexrs and removed indexd
    * Added support for xcp-proxy
    * Several bug fixes
* v9.56.0 (2018-09-16)
    * Segwit support!
    * Several changes related to CIP19
    (https://github.com/CounterpartyXCP/cips/blob/master/cip-0019.md) (protocol change: 557236)
    * Usage of estimatesmartfee due to deprecation of the estimatefee method
    * Use Bitcoin 0.16.3 with indexd as a transaction index
    * allow multisig encoding method as the bytespersigop DoS protection was changed in Bitcoin Core v0.13.0
    * API change (backwards compatible): adds extended_tx_info parameter to create methods
    * Breaking API change. The result of get_unspent_txouts has changed and now looks like this: [{
                "amount": 0.001,
                "confirmations": 2,
                "height": 1211095,
                "txid": "832d27a9b6134ecf50c5e1724bca3ebb797c21fb05b850a9abf145372acc3933",
                "value": 100000,
                "vout": 1
            }]
    * Fixed unpack API method for enhanced sends
    * Upgrade SQLite/APSW to v3.12.2
        * Run `python3 setup.py install_apsw` to upgrade your installed version.
        * Run `./tools/upgradesqlitepagesize.py <PATHTOYOURDB>` while your node is OFFLINE to upgrade.
          Most likely the path to your DB is `~/.local/share/counterparty/counterparty.db`.
* v9.55.4 (2017-10-31)
    * Fix for uncaught exception in short asset name issuances
* v9.55.3 (2017-09-26)
    * Implemented CIP-9 Enhanced Send (https://github.com/CounterpartyXCP/cips/blob/master/cip-0009.md) (protocol change: 489956)
    * Implemented CIP-11 Shorten Transaction Type ID Namespace (https://github.com/CounterpartyXCP/cips/blob/master/cip-0011.md) (protocol change: 489956)
    * Implemented CIP-12 Memo Requirement through Broadcasts (https://github.com/CounterpartyXCP/cips/blob/master/cip-0012.md) (protocol change: 489956)
    * Fixes locked issuance workaround (https://github.com/CounterpartyXCP/counterparty-lib/pull/999)
    * Updated python-bitcoinlib library for handling blocks that include transactions with segwit outputs
    * Test suite and services updates
    * Remove rpcthreads recommendation
* v9.55.2 (2017-05-01)
    * Implemented CIP-4 subassets (https://github.com/CounterpartyXCP/cips/blob/master/cip-0004.md) (protocol change: 467417)
    * Moved to bitcoind 0.13.2-addrindex (please use at least 0.13.2 with this version of counterparty-lib)
* v9.55.1 (2016-12-02)
    * Hotfix for integer overflow bug that caused a crash on mainnet block #441563
* v9.55.0 (2016-07-11)
    * P2SH support for source / destination of addresses (protocol change: 423888)
    * Moved check for invalid broadcast to better place to prevent broadcasting a cancel on a locked feed (protocol change: 423888)
    * Only use first usable input for source (protocol change: 423888)
    * Fixed issue with broadcasts of exactly 52 chars, by always adding a varint to specify the length (protocol change: 423888)
    * Cleanup destroy.parse and add unit tests for it (protocol change: 423888)
    * Added Docker image building (counterparty/counterparty-server on Dockerhub)
    * Enhanced Travis to run test suite inside Docker image, and push image if testsuite passes
    * UTXO "locking" used to construct a transaction for 3 seconds to avoid a user double spending against himself
    * Improved APSW install routine to downgrade when newer version is installed
    * Tweaked CORS headers so that web clients may authenticate directly against counterparty-server
    * Numerous logging fixes to make logging more robust
    * Further performance enhancements when fetching raw transactions from bitcoind
    * Peg dependencies at specific versions!
    * Added debug_config method to print config to CLI
    * Mask username/password in backend URL when logging
    * Updated python-bitcoinlib to newest version
    * No longer ceil the size of a transaction to KBs when calculating fees
    * Use dynamic estimated fee (from bitcoind)
    * Fix for bytespersigop DoS protection in Bitcoin Core v0.12.1
    * Test suite:
        * Reorganization of the test suite at numerous points for more robustness and capabilities
        * Added ability to mock protocol changes to allow for testing of certain changes on or off
        * Modified CI builds to make it easier to read logging reports
        * Added numerous tests to test suite for better coverage
        * Execute tests in forward order, not reverse order, and ensure they are sorted
        * Add logging prefix to mempool status to be able to filter it
        * Fix when running a single unittest
        * Use prettyprint for debugging database records
        * Created script to easily copy test scenarios
        * Better test detection
* v9.54.0 (2016-03-05)
    * Execute post install tasks when called via `pip`
    * Max fee fraction of 1
    * Don't handle bet matches for invalid broadcast.
* v9.53.0 (2016-01-18)
    * Remove `messages` table from being covered by "undolog" functionality added in `v9.52.0`.
    * Add `min_message_index` to `get_blocks` API call.
    * Retry more than once with `getrawtransaction_batch` if a specific txhash is not found in `bitcoind`'s addrindex.
    * Update `setup.py` to properly utilize (newer) egg-style install. Previously the "old" style install was invoked when it shouldn't have been.
    * Update backend mempool caching code to keep full mempool, instead of just XCP transactions (from @rubensayshi).
    * Increase max `OP_RETURN` size used from 40 bytes to 80 bytes (from @rubensayshi).
    * Add ModuleLoggingFilter for (NodeJS-style) module-level log filtering (from @rubensayshi).
    * Fixed `backend.get_unspent_outputs` from raising exception when a transaction contains an output with garbage data (from @rubensayshi).
    * `base58_check_decode` padding byte used should be `x00`, not the `version` (from @rubensayshi).
    * Require `sudo` for non-container `travis` builds, due to our `serpent` dependency (from @rubensayshi).
    * Made `getrawtransaction_batch` deal better with missing raw transactions from `bitcoind`.
    * A number of other small bug fixes, logging tweaks, etc.
    * NOTE: This versions mhash (message hash) will be different than that of nodes running `9.52.0`, but the other hashes should continue to match.
* v9.52.0 (2015-10-31)
    * Added "undolog" functionality to avoid full reparses when encountering a blockchain reorganisation
    * Removed use of `tornado` library in the API module. We use `flask`'s threaded server instead
    * Added `getrawtransaction` and `getrawtransaction_batch` methods to the API
    * Added optional `custom_inputs` parameter to API calls, which allows for controlling the exact UTXOs to use in transactions (thanks, tokenly)
    * Added `message_hash`, derived from changes to the `counterparty-lib` database. Displayed on each new block, makes checking for DB-level consensus easier
* v9.51.4 (2015-09-26)
    * Significant performance and caching optimizations around bitcoind addrindex interaction
    * Fixed issues around responsiveness with larger mempool sizes
    * Mempool refresh period changed from 2 seconds to .5 seconds
    * Bug fixes with coinbase transaction processing
    * `unspent_tx_hash` argument added to `transaction.construct()`
    * Faster transaction chaining
    * Checkpoint hashes updated
* v9.51.3 (2015-05-13)
    * Handle correctly -2 error (reorg) from RPC queries
    * `scriptpubkey_to_address()` return None for coinbase
    * Thread-safe raw transactions cache
    * Include prefix to calculate total data length
* v9.51.2 (2015-04-23)
    * miscellaneous bug fixes
    * dramatically reduced default batch size (from 5000 to 20)
    * renamed repository to `counterparty-lib`
* v9.51.1 (2015-04-20)
    * rename `server.api.log` to `server.access.log`
    * add `requests_timeout` parameter
    * add `rpc_batch_size` parameter and optimize RPC calls for block parsing and UTXO search
    * add `check_asset_conservation` parameter and optimize assets conservation checking
    * miscellaneous bug fixes
    * code reorganisation
* v9.51.0 (2015-04-01)
    * check for null data chunks (protocol change: 352000)
    * disable rock‐paper‐scissors (protocol change: 352000)
    * deprecate `get_asset_info(assets)` API method
    * deprecate `get_xcp_supply()` API method in favor of `get_supply(asset)`
    * `get_unspent_txouts` API method parameter and return values changed
    * authentication on JSON‐RPC API is off by default
    * `rpc_password` configuration parameter is no longer mandatory
    * default to using `opreturn` encoding when possible
    * catch unhandled exception with invalid script on testnet
    * added HTTP REST API
* v9.50.0 (2015-03-18)
    * hotfix: global integer overflow
* v9.49.4 (2015-02-05)
    * reconceived this package as a libary
    * moved CLI to new repository: `counterparty-cli`
    * remove signing and broadcast functionality from API (`do_*`, `sign_tx`, `broadcast_tx` calls)
    * created `setup.py` build script
    * return to using `requests` for handling connections to backend
    * introduced global variable `CURRENT_BLOCK_INDEX`
    * renamed configuration parameter: `jmcorgan` -> `addrindex`
    * renamed configuration parameter: `BACKEND_RPC_*` -> `BACKEND_*`
    * renamed configuration parameter: `BLOCKCHAIN_SERVICE_NAME` -> `BACKEND_NAME`
    * prepared version check for repository rename to `counterparty-lib`
    * moved API docs to wiki
    * improved test coverage
    * miscellaneous bug fixes
    * improved docstring coverage
    * removed option to use Insight, Blockr and SoChain as a backend
    * tweaked Coveralls configuration
    * Rename the database file name from `counterpartyd.9.db` to `counterparty.db`
    * Add BTCD support
* v9.49.3 (2014-12-28)
    * better logging when handling `SIGTERM`, `SIGKILL`
    * update README
    * if no RPC password is specified, generate automatically
    * allow manually providing pubkeys for multi‐sig addresses
    * removed deprecated callback functionality
    * new log format, architecture
    * fixed API Status Poller
    * fixed troublesome `socket.timeout` error
    * code reorganisation
    * code cleanup
* v9.49.2 (2014-12-19)
    * prepare for ‘destroy’ functionality
    * match IDs now include underscore
    * code clean‐up
    * mainnet burns are hard‐coded
    * sanity checks for manually provided public and private keys
    * handle protocol changes more elegantly
    * more sophisticated version checking
    * removed obsolete `carefulness` CLI option
    * removed addrindex for unconfirmed transactions
    * use python-bitcoinlib for RPC communication with backend
    * log unhandled exceptions
    * updated API docs
    * misc. bug fixes
* v9.49.1 (2014-12-11)
    * don’t print user‐submitted text
* v9.49.0 (2014-12-11)
    * hotfix: numeric asset names (protocol change: 334000)
    * sanity check on transaction construction
    * minor bug fixes
* v9.48.0 (2014-12-08)
    * better enforcement of single source, destination
* v9.47.1 (2014-12-02)
    * change first testnet block to 310000
* v9.47.0 (2014-12-01)
    * multi‐signature address support (protocol change: 333500)
    * numeric asset names (protocol change: 333500)
    * kickstart functionality
    * better process‐locking
    * improvements to documentation
    * graceful shutdown of processes
    * faster server startup
    * support for jmcorgan Bitcoin Core fork for block explorer
    * change first testnet block to 281000
    * make protocol changes always retroactive on testnet
* v9.46.0 (2014-11-03)
    * new consensus hashes, with `tx_info` and consensus version
    * Coveralls support
    * rewrite of README
    * better multi‐sig address handling
    * multi‐sig change
    * use new process‐locking mechanism
    * use GitHub Pages for hosting minimum version information
    * bump versions of dependencies
    * miscellaneous clean up
* v9.45.0 (2014-10-23)
    * add dividend fee of 0.0002 XCP per recipient (protocol change: 330000)
* v9.44.0 (2014-09-22)
    * server action requires `server` positional argument
    * lockfile
    * made `--force` server‐side only, moved after `server` argument
    * multiple sources, destinations (testnet protocol change: 303000)
    * multi‐signature support (testnet protocol change: 303000)
* v9.43.0 (2014-09-14)
    * generate movements hash for each block (start at block: 322000)
* v9.42.0 (2014-09-04)
    * disable dividends to XCP holders (protocol change: 320000)
    * allow dividends only from issuers (protocol change: 320000)
* v9.41.0 (2014-08-21)
    * fixed bug in new text and descriptions
* v9.40.0 (2014-08-20)
    * allow dividends to be paid to XCP holders (protocol change: 317500)
    * fixed bug in BTCpay validation
    * allow null expirations (protocol change: 317500)
    * assert first block in database is BLOCK_FIRST
    * arbitrarily long asset descriptions and broadcast texts (protocol change: 317500)
* v9.39.0 (2014-08-06)
    * re‐match expired order matches from a new block all at once (protocol change: 315000)
    * bug in issuance fee (protocol change: 315000)
* v9.38.0 (2014-08-05)
    * don’t close order matches when penalizing (protocol change: 314250)
* v9.37.0 (2014-08-02)
    * close sell BTC orders and order_matches of addresses that fail to make a BTC payment (protocol change: 313900)
* v9.36.0 (2014-08-02)
    * version mismatch
* v9.35.0 (2014-08-02)
    * minimum BTC order match size; don’t check source address of BTCpay (protocol change: 313900)
* v9.34.0 (2014-07-24)
    * CFDs temporarily disabled
* v9.33.1 (2014-07-23)
    * moved Armory support to Counterwallet (allow use of uncompressed keys)
    * improved performance of mempool population
    * new ‘blockchain’ backend
* v9.33.0 (2014-07-18)
    * bug in call_date and call_price sanity checks (protocol change: 312500)
* v9.32.0 (2014-07-15)
    * API underlying library changed from cherrypy to flask
    * "/" supported as an API endpoint
    * "/api" with no trailing slash no longer supported as an API endpoint (use "/" or "/api/" instead)
    * per-request API checks taken out to their own thread to improve performance and prevent dogpiling
    * new dependencies: tornado, flask and Flask-HTTPAuth. cherrypy dependency removed
* v9.31.0 (2014-07-10)
    * change fee_required calculation for orders matching (protocol change: 310500)
    * don’t skip negative get quantity remaining for orders matching (protocol change: 310500)
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
