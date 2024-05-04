#!/bin/bash

set -e
set -x

if [ -f "./DOCKER_COMPOSE_TEST_LOCK" ]; then
    echo "A test is already running. Exiting."
    exit 1
fi
touch "./DOCKER_COMPOSE_TEST_LOCK"

GIT_BRANCH="$1"
PROFILE="$2"

if [ "$PROFILE" = "testnet" ]; then
    PORT=14000
else
    PORT=4000
fi

# pull the latest code
rm -rf counterparty-core
git clone --branch "$GIT_BRANCH" https://github.com/CounterpartyXCP/counterparty-core.git
cd counterparty-core

VERSION=$(cat docker-compose.yml | grep 'image: counterparty/counterparty:' | awk -F ":" '{print $3}')

# stop the running containers
docker compose --profile $PROFILE stop

# remove counterparty-core container
#docker rm counterparty-core-counterparty-core-1
docker container prune -f

# remove counterparty-core image
docker rmi counterparty/counterparty:$VERSION || true

# build the counterparty-core new image
docker build -t counterparty/counterparty:$VERSION .

# remove the counterparty-core data
# sudo rm -rf ~/.local/share/counterparty-docker-data/counterparty/*

# re-start containers
docker compose --profile $PROFILE up -d

while [ "$(docker compose --profile $PROFILE logs counterparty-core-$PROFILE 2>&1 | grep 'Ready for queries')" = "" ]; do
    echo "Waiting for counterparty-core $PROFILE to be ready"
    sleep 1
done

if [ "$PROFILE" = "mainnet" ]; then
    # Run dredd rest
    dredd
    # Run compare hashes test
    pip uninstall -y counterparty-rs
    pip install -e counterparty-rs
    cd counterparty-core
    hatch env prune
    hatch run pytest counterpartycore/test/compare_hashes_test.py --comparehashes
    cd ..
fi


server_response_v1=$(curl -X POST http://127.0.0.1:$PORT/v1/api/ \
                        --user rpc:rpc \
                        -H 'Content-Type: application/json; charset=UTF-8'\
                        -H 'Accept: application/json, text/javascript' \
                        --data-binary '{ "jsonrpc": "2.0", "id": 0, "method": "get_running_info" }' \
                        --write-out '%{http_code}' --silent --output /dev/null)

if [ "$server_response_v1" -ne 200 ]; then
    echo "Failed to get_running_info"
    rm -f ../DOCKER_COMPOSE_TEST_LOCK
    exit 1
fi

server_response_v2=$(curl http://api:api@127.0.0.1:$PORT/ \
                        --write-out '%{http_code}' --silent --output /dev/null)

if [ "$server_response_v2" -ne 200 ]; then
    echo "Failed to get API v2 root"
    rm -f ../DOCKER_COMPOSE_TEST_LOCK
    exit 1
fi

rm -f ../DOCKER_COMPOSE_TEST_LOCK
exit 0