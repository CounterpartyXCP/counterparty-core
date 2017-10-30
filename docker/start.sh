#!/bin/bash

# Run "setup.py develop" if we need to (can be the case if the .egg-info paths get removed, or mounted over, e.g. fednode)
if [ ! -d /counterparty-lib/counterparty_lib.egg-info ]; then
    cd /counterparty-lib; python3 setup.py develop; cd /
fi
if [ ! -d /counterparty-cli/counterparty_cli.egg-info ]; then
    cd /counterparty-cli; python3 setup.py develop; cd /
fi

# Bootstrap if the database does not exist (do this here to handle cases
# where a volume is mounted over the share dir, like the fednode docker compose config does...)
if [ ! -f /root/.local/share/monaparty/monaparty.db ]; then
    echo "Downloading mainnet bootstrap DB..."
    counterparty-server bootstrap --quiet
fi
if [ ! -f /root/.local/share/monaparty/monaparty.testnet.db ]; then
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
