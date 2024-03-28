#!/bin/bash

set +e
set -x

cd counterparty-core

GIT_BRANCH="$1"
VERSION=v$(cat compose.yml | grep 'image: counterparty/counterparty:' | awk -F ":" '{print $3}')

# pull the latest code
git clean -d -x -f
git checkout .
git pull -f origin $GIT_BRANCH:$GIT_BRANCH
git checkout $GIT_BRANCH

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

curl -X POST http://127.0.0.1:14000/api/ \
     --user rpc:rpc \
     -H 'Content-Type: application/json; charset=UTF-8'\
     -H 'Accept: application/json, text/javascript' \
     --data-binary '{ "jsonrpc": "2.0", "id": 0, "method": "get_running_info" }'