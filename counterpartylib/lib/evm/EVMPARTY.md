Differences between EVM on Ethereum and on CP
=============================================
We'll reference the EVM on Ethereum as ETHEVM and the EVM on CP as CPEVM

`block.prevhash`
----------------
ETHEVM `block.prevhash(0)` will return `0` because the contract is executed before the block is mined (afaik).
CPEVM `block.prevhash(0)` will return the current block, because the contract is not executed until the block is mined.

`block.log_listeners` vs `contract_tester.state.log_listeners`
--------------------------------------------------------------
because CP unittests create a new block for every execution of a contract
we need to append log_listeners to `contract_tester.state.log_listeners` instead of `block.log_listeners`.

TODO
====
 - ecrecover
 - send_asset

 - UnitTests
   - blocks
   - ethutils
   - logging
   - specials
   - transactions