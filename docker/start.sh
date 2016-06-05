#!/bin/bash

# Bootstrap if the database does not exist (do this here to handle cases
# where a volume is mounted over the share dir, like the fednode docker compose config does...)
if [ -z "$TESTNET" ] && [ ! -f /root/.local/share/counterparty/counterparty.db ]; then
    echo "No counterparty database exists. Downloading mainnet bootstrap DB..."
    counterparty-server bootstrap --quiet
fi
if [ -n "$TESTNET" ] && [ ! -f /root/.local/share/counterparty/counterparty.testnet.db ]; then
    echo "No counterparty database exists. Downloading testnet bootstrap DB..."
    counterparty-server --testnet bootstrap --quiet
fi

# Specify defaults (defaults are overridden if defined in the environment)
DEFAULT_BACKEND_CONNECT="bitcoin"
DEFAULT_BACKEND_PORT=8332
DEFAULT_RPC_PORT=4000
EXTRA_PARAMS=""
if [ -n "$TESTNET" ]; then
    EXTRA_PARAMS="${EXTRA_PARAMS} --testnet"
    DEFAULT_BACKEND_CONNECT="bitcoin-testnet"
    DEFAULT_BACKEND_PORT=18332
    DEFAULT_RPC_PORT=4001
fi
if [ -n "$VERBOSE" ]; then
    EXTRA_PARAMS="${EXTRA_PARAMS} --verbose"
fi

: ${BACKEND_CONNECT:=$DEFAULT_BACKEND_CONNECT}
: ${BACKEND_PORT:=$DEFAULT_BACKEND_PORT}
: ${BACKEND_USER:="rpc"}
: ${BACKEND_PASSWORD:="rpc"}
: ${RPC_PORT:=$DEFAULT_RPC_PORT}
: ${RPC_USER:="rpc"}
: ${RPC_PASSWORD:="rpc"}
: ${COMMAND:="start"}

# Kick off the server, defaulting to the "start" subcommand
/usr/local/bin/counterparty-server \
  --backend-connect=${BACKEND_CONNECT} --backend-port=${BACKEND_PORT} \
  --backend-user=${BACKEND_USER} --backend-password=${BACKEND_PASSWORD} \
  --rpc-port=${RPC_PORT} --rpc-user=${RPC_USER} --rpc-password=${RPC_PASSWORD} \
  ${EXTRA_PARAMS} ${COMMAND}
