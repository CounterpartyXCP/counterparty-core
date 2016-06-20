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

 - block gas limit
 - execution order

 - UnitTests
   - blocks
   - ethutils
   - logging
   - specials
   - transactions

INSTALL
=======
http://www.ethdocs.org/en/latest/ethereum-clients/cpp-ethereum/building-from-source/linux-ubuntu.html
 - the LLVM part is not neccesary
 - the `sudo add-apt-repository -y ppa:ethereum/ethereum-qt` is not neccesary
    - but then you need to remove the following from the apt-get install:
      `qtbase5-dev qt5-default qtdeclarative5-dev libqt5webkit5-dev libqt5webengine5-dev`
 - if fails `sudo apt-get -y install libjson-rpc-cpp-dev` try `apt-get -y install libjsonrpccpp-dev`

 - somehow get your `counterparty-server` to use the `evmparty` branch of `counterparty-lib`

 - `python setup.py install_solc`
 - `python setup.py install_serpent`
 - `python setup.py install`

 - `pip install pytest`

 - `py.test-3.4 -vv -x -s counterpartylib/test/evm/`
