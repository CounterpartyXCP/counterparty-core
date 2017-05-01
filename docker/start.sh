#!/bin/bash

# Run "setup.py develop" if we need to (can be the case if the .egg-info paths get removed, or mounted over, e.g. fednode)
if [ ! -d /counterparty-lib/counterparty_lib.egg-info ]; then
    cd /counterparty-lib; python3 setup.py develop; cd /
fi
if [ ! -d /counterparty-cli/counterparty_cli.egg-info ]; then
    cd /counterparty-cli; python3 setup.py develop; cd /
fi

#########
# HACK: Use python-bitcoinlib snapshot version for testnet
# TODO: REMOVE THIS ONCE https://github.com/petertodd/python-bitcoinlib/pull/112 IS MERGED!
if [[ $PARAMS == *"testnet"* ]]; then
  echo "TESTNET USE DETECTED -- GETTING python-bitcoinlib 0.7.1-SNAPSHOT"
  rm -rf /usr/local/lib/python3.5/dist-packages/bitcoin /usr/local/lib/python3.5/dist-packages/python_bitcoinlib-*.dist-info
  pip3 install --upgrade git+https://github.com/CounterpartyXCP/python-bitcoinlib.git@112d66b11cde30b9c7e10895f057baab13cc35ec#egg=python-bitcoinlib-0.7.0
  #^ yes, we make it look like 0.7.0 (using version "0.7.1-SNAPSHOT" was causing all sorts of issues)
fi
#########

# Bootstrap if the database does not exist (do this here to handle cases
# where a volume is mounted over the share dir, like the fednode docker compose config does...)
if [ ! -f /root/.local/share/counterparty/counterparty.db ]; then
    echo "Downloading mainnet bootstrap DB..."
    counterparty-server bootstrap --quiet
fi
if [ ! -f /root/.local/share/counterparty/counterparty.testnet.db ]; then
    echo "Downloading testnet bootstrap DB..."
    counterparty-server --testnet bootstrap --quiet
fi

# Kick off the server, defaulting to the "start" subcommand
# Launch utilizing the SIGTERM/SIGINT propagation pattern from
# http://veithen.github.io/2014/11/16/sigterm-propagation.html
: ${PARAMS:=""}
: ${COMMAND:="start"}

trap 'kill -TERM $PID' TERM INT
/usr/local/bin/counterparty-server ${PARAMS} ${COMMAND} &
PID=$!
wait $PID
trap - TERM INT
wait $PID
EXIT_STATUS=$?
