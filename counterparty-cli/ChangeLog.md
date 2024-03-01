## Command Line Interface Versions ##
* master (unreleased)
	* Added indexd arguments
	* removed backend-name argument
* v1.1.4 (2017/10/26)
    * Added enhanced send arguments support.
* v1.1.3 (2017/05/01)
    * Added `vacuum` command to server CLI.
* v1.1.2 (2016/07/11)
    * Added P2SH support (to match counterparty-lib 9.55.0)
	* added `get_tx_info` command
	* added `--disable-utxo-locks` to `compose_transaction` to disable the locking of selected UTXOs for when the 'user' doesn't intend to broadcast the TX (straight away)
	* Peg dependency versions in `setup.py`
	* Added `debug_config` argument to print config to CLI.
	* Added `--quiet` flag to `bootstrap` command
	* Logging improvements
        * Removed `rps` and `rpsresolve` commands
	* Updated `README.md`
* v1.1.1 (2015/04/20)
	* Fix `broadcast` command
	* Cleaner, Commented-out Default Config Files
	* Support new configuration parameter: `no-check-asset-conservation`, `rpc-batch-size`, `requests-timeout`
* v1.1.0 (2015/03/31)
	* Code reorganisation
	* Remove `market` command
	* Add `getrows` command
	* Add `clientapi` module
	* Rename `get_running_info` to `getinfo`
	* Rename `backend-ssl-verify` to `backend-ssl-no-verify`
	* Rename `rpc-allow-cors` to `rpc-no-allow-cors`
	* Change installation procedure
* v1.0.1 (2015/03/18)
	* Update minimum `counterparty-lib` version from `v9.49.4` to `v9.50.0`
* v1.0.0 (2015/02/05)
	* Initial Release
