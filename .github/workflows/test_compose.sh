#!/bin/bash

set -e
set -x

#exit 0

export PATH="/snap/bin:$PATH"

if [ -f "./DOCKER_COMPOSE_TEST_LOCK" ]; then
    echo "A test is already running or the last one failed. Exiting."
    exit 1
fi
touch "./DOCKER_COMPOSE_TEST_LOCK"

GIT_BRANCH="$1"

# pull the latest code
sudo rm -rf counterparty-core
git clone --branch "$GIT_BRANCH" https://github.com/CounterpartyXCP/counterparty-core.git
cd counterparty-core

VERSION=$(cat docker-compose.yml | grep 'image: counterparty/counterparty:' | awk -F ":" '{print $3}')

# verbose mode
sed -i 's/#- "--verbose"/-  "-vv"/g' docker-compose.yml

# stop the running containers
docker compose --profile mainnet stop counterparty-core
docker compose --profile testnet stop counterparty-core-testnet

# remove counterparty-core container
docker container prune -f

# remove counterparty-core image
docker rmi counterparty/counterparty:$VERSION || true

# build the counterparty-core new image
docker build -t counterparty/counterparty:$VERSION .

# re-start containers
docker compose --profile mainnet up -d
docker compose --profile testnet up -d

# wait for counterparty-core to be ready
while [ "$(docker compose logs counterparty-core 2>&1 | grep 'Watching for new blocks')" = "" ]; do
    echo "Waiting for counterparty-core mainnet to be ready"
    sleep 1
done

while [ "$(docker compose logs counterparty-core-testnet 2>&1 | grep 'Watching for new blocks')" = "" ]; do
    echo "Waiting for counterparty-core testnet to be ready"
    sleep 1
done


# check running info with API v1 mainnet
response_v1_mainnet=$(curl -X POST http://127.0.0.1:4100/v1/ \
                        --user rpc:rpc \
                        -H 'Content-Type: application/json; charset=UTF-8'\
                        -H 'Accept: application/json, text/javascript' \
                        --data-binary '{ "jsonrpc": "2.0", "id": 0, "method": "get_running_info" }' \
                        --write-out '%{http_code}' --silent --output /dev/null)

if [ "$response_v1_mainnet" -ne 200 ]; then
    echo "Failed to get_running_info mainnet"
    exit 1
fi

# check running info with API v1 testnet
response_v1_testnet=$(curl -X POST http://127.0.0.1:14100/v1/ \
                        --user rpc:rpc \
                        -H 'Content-Type: application/json; charset=UTF-8'\
                        -H 'Accept: application/json, text/javascript' \
                        --data-binary '{ "jsonrpc": "2.0", "id": 0, "method": "get_running_info" }' \
                        --write-out '%{http_code}' --silent --output /dev/null)

if [ "$response_v1_testnet" -ne 200 ]; then
    echo "Failed to get_running_info testnet"
    exit 1
fi

# check running info with API v2 mainnet
response_v2_mainnet=$(curl http://localhost:4000/v2/ \
                        --write-out '%{http_code}' --silent --output /dev/null)

if [ "$response_v2_mainnet" -ne 200 ]; then
    echo "Failed to get API v2 root mainnet"
    exit 1
fi

# check running info with API v2 testnet
response_v2_testnet=$(curl http://localhost:14000/v2/ \
                        --write-out '%{http_code}' --silent --output /dev/null)

if [ "$response_v2_testnet" -ne 200 ]; then
    echo "Failed to get API v2 root testnet"
    exit 1
fi

# Let's reparse 50 blocks before Dredd and compare hashes tests
CURRENT_HEIGHT=$(curl http://localhost:4000/v2/ --silent | jq '.result.counterparty_height')
REPARSE_FROM=$(($CURRENT_HEIGHT-50))

# Stop, reparse and start counterparty-core mainnet
LOG_PATH=$(docker inspect --format='{{.LogPath}}' counterparty-core-counterparty-core-1)
sudo rm -f $LOG_PATH
sudo touch $LOG_PATH

docker compose --profile mainnet stop counterparty-core
docker compose --profile mainnet run counterparty-core reparse $REPARSE_FROM \
   --backend-connect=bitcoind \
   --indexd-connect=addrindexrs \
   --rpc-host=0.0.0.0 \
   --api-host=0.0.0.0

sudo rm -f $LOG_PATH
sudo touch $LOG_PATH

docker compose --profile mainnet up -d counterparty-core

# wait for counterparty-core to be ready
while [ "$(docker compose logs counterparty-core 2>&1 | grep 'Watching for new blocks...')" = "" ]; do
    echo "Waiting for counterparty-core mainnet to be ready"
    sleep 1
done

# Run compare hashes test
. "$HOME/.profile"
cd counterparty-core
sudo python3 -m pytest counterpartycore/test/mainnet_test.py --testapidb --comparehashes
cd ..


rm -f ../DOCKER_COMPOSE_TEST_LOCK
exit 0
