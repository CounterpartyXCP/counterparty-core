#!/bin/bash

set -e
set -x

if [ -f "./DOCKER_COMPOSE_TEST_LOCK" ]; then
    echo "A test is already running. Exiting."
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
docker compose stop

# remove counterparty-core container
docker rm counterparty-core-counterparty-core-1

# remove counterparty-core image
docker rmi counterparty/counterparty:$VERSION || true

# build the counterparty-core new image
docker build -t counterparty/counterparty:$VERSION .

# remove the counterparty-core data
sudo rm -rf ~/counterparty-docker-data/counterparty/*

# re-start containers
COUNTERPARTY_NETWORK=test docker compose up -d

while [ "$(docker compose logs counterparty-core 2>&1 | grep 'Ready for queries')" = "" ]; do
    echo "Waiting for counterparty-core to be ready"
    sleep 1
done

rm -f ../DOCKER_COMPOSE_TEST_LOCK

server_response=$(curl -X POST http://127.0.0.1:14000/api/ \
                        --user rpc:rpc \
                        -H 'Content-Type: application/json; charset=UTF-8'\
                        -H 'Accept: application/json, text/javascript' \
                        --data-binary '{ "jsonrpc": "2.0", "id": 0, "method": "get_running_info" }' \
                        --write-out '%{http_code}' --silent --output /dev/null)

if [ "$server_response" -ne 200 ]; then
    echo "Failed to get_running_info"
    exit 1
fi