# you need a bitcoind instance and set the below vars properly
# if you don't have a local bitcoind you can use mine (ask me to open it up)
export BITCOIN_RPC_HOST="0.tcp.ngrok.io"
export BITCOIN_RPC_PORT="15419"
export BITCOIN_RPC_USER="bitcoin"
export BITCOIN_RPC_PASSWORD="fsJoJupAXx"

sudo apt-get -y install python3 python3-pip python3.4-venv

# from http://www.ethdocs.org/en/latest/ethereum-clients/cpp-ethereum/building-from-source/linux-ubuntu.html
sudo apt-add-repository -y ppa:george-edison55/cmake-3.x

sudo apt-get -y update
sudo apt-get -y install language-pack-en-base
sudo apt-get -y install gcc-4.8
sudo dpkg-reconfigure locales
sudo apt-get -y install software-properties-common

sudo add-apt-repository -y ppa:ethereum/ethereum
sudo add-apt-repository -y ppa:ethereum/ethereum-dev
sudo apt-get -y update

sudo apt-get -y install build-essential git cmake libboost-all-dev libgmp-dev \
    libleveldb-dev libminiupnpc-dev libreadline-dev libncurses5-dev \
    libcurl4-openssl-dev libcryptopp-dev libmicrohttpd-dev libjsoncpp-dev \
    libargtable2-dev libedit-dev mesa-common-dev ocl-icd-libopencl1 opencl-headers \
    libgoogle-perftools-dev ocl-icd-dev libv8-dev libz-dev

sudo apt-get -y install libjson-rpc-cpp-dev
sduo apt-get -y install libjsonrpccpp-dev

# setup loggin config
echo 'export COUNTERPARTY_LOGGING="-counterpartylib.lib.blocks.list_tx.skip,-counterpartylib.lib.check,*"' >> ~/.bashrc
export COUNTERPARTY_LOGGING="-counterpartylib.lib.blocks.list_tx.skip,-counterpartylib.lib.check,*"

git clone https://github.com/rubensayshi/counterparty-cli.git
git clone https://github.com/rubensayshi/counterparty-lib.git
cd counterparty-lib && git checkout evmparty && cd ..  # checkout the evmparty branch for LIB

cd counterparty-cli

pyvenv-3.4 venv
source venv/bin/activate

# install stuff
pip install pytest
pip install --upgrade -r requirements.txt
python setup.py install

git checkout evmparty  # checkout the evmparty branch for CLI

# remove the downloade counterpartylib and symlink the git checkout into place
rm -rf venv/lib/python3.4/site-packages/counterparty_lib-9.54.0.egg-info
rm -rf venv/lib/python3.4/site-packages/counterpartylib
ln -s ../counterparty-lib venv/lib/python3.4/site-packages/counterparty_lib-9.54.0.egg-info
ln -s ../counterparty-lib/counterpartylib venv/lib/python3.4/site-packages/counterpartylib

# install again to update stuff
cd ../counterparty-lib && pip install --upgrade -r requirements.txt && python setup.py install --with-solc --with-serpent && cd ../counterparty-cli
python setup.py install


# below values should be your bitcoind RPC
echo "
[Default]
backend-connect=${BITCOIN_RPC_HOST}
backend-port=${BITCOIN_RPC_PORT}
backend-user=${BITCOIN_RPC_USER}
backend-password=${BITCOIN_RPC_PASSWORD}
" > ~/.config/counterparty/server.conf

# same
echo "
[Default]
wallet-connect=${BITCOIN_RPC_HOST}
wallet-port=${BITCOIN_RPC_PORT}
wallet-user=${BITCOIN_RPC_USER}
wallet-password=${BITCOIN_RPC_PASSWORD}
" > ~/.config/counterparty/client.conf

# you need an address that is in bitcoind and preloaded with some BTC / XCP
# change if you're using your own bitcoind, create an address (`bitcoin-cli -testnet getnewaddress`), send it some BTC and XCP from your TESTNET counterwallet ;)
SOURCE="miJqNkHhC5xsB61gsiSWXeTLnEGSQnWbXB"

counterparty-server --verbose --testnet bootstrap  # download bootstrap image
counterparty-server --verbose --testnet start
