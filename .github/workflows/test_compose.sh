#!/bin/bash

set -e
set -x

if [ -f "./DOCKER_COMPOSE_TEST_LOCK" ]; then
    echo "A test is already running or the last one failed. Exiting."
    exit 1
fi
touch "./DOCKER_COMPOSE_TEST_LOCK"

GIT_BRANCH="$1"

# pull the latest code
rm -rf counterparty-core
git clone --branch "$GIT_BRANCH" https://github.com/CounterpartyXCP/counterparty-core.git
cd counterparty-core

VERSION=$(cat docker-compose.yml | grep 'image: counterparty/counterparty:' | awk -F ":" '{print $3}')

# stop the running containers
docker compose --profile mainnet stop counterparty-core
docker compose --profile testnet stop counterparty-core-testnet

# remove counterparty-core container
#docker rm counterparty-core-counterparty-core-1
docker container prune -f

# remove counterparty-core image
docker rmi counterparty/counterparty:$VERSION || true

# build the counterparty-core new image
docker build -t counterparty/counterparty:$VERSION . > build.txt 2>&1
COUNTERPARTY_RS_CACHED=$(awk '/COPY \.\/counterparty-rs \/counterparty-rs/{getline; print}' build.txt | awk '{print $2}')
cat build.txt

# re-start containers
docker compose --profile mainnet up -d
docker compose --profile testnet up -d

# wait for counterparty-core to be ready
while [ "$(docker compose logs counterparty-core 2>&1 | grep 'API Watcher - Catch up completed.')" = "" ]; do
    echo "Waiting for counterparty-core mainnet to be ready"
    sleep 1
done

while [ "$(docker compose logs counterparty-core-testnet 2>&1 | grep 'API Watcher - Catch up completed.')" = "" ]; do
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

if [ "$response_v2_mainnet" -ne 200 ]; then
    echo "Failed to get API v2 root mainnet"
    exit 1
fi

# Let's reparse 50 blocks before Dredd and compare hashes tests
CURRENT_HEIGHT=$(curl http://localhost:4000/v2/ --silent | jq '.result.counterparty_height')
REPARSE_FROM=$(($CURRENT_HEIGHT-50))

# Stop, reparse and start counterparty-core mainnet
docker compose --profile mainnet stop counterparty-core
docker compose --profile mainnet run counterparty-core reparse $REPARSE_FROM \
   --backend-connect=bitcoind \
   --indexd-connect=addrindexrs \
   --rpc-host=0.0.0.0 \
   --api-host=0.0.0.0
docker compose --profile mainnet up -d counterparty-core

# wait for counterparty-core to be ready
while [ "$(docker compose logs counterparty-core 2>&1 | grep 'API Watcher - Catch up completed.')" = "" ]; do
    echo "Waiting for counterparty-core mainnet to be ready"
    sleep 1
done

# Run dredd test
dredd


# Run compare hashes test
. "$HOME/.profile"
cd counterparty-core

if [ "$COUNTERPARTY_RS_CACHED" != "CACHED" ]; then
    hatch env prune
fi

hatch run pytest counterpartycore/test/compare_hashes_test.py --comparehashes
sudo python3 -m pytest counterpartycore/test/api_db_test.py --testapidb
cd ..


rm -f ../DOCKER_COMPOSE_TEST_LOCK
exit 0
