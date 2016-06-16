bitcoin-cli -testnet -rpcconnect=0.tcp.ngrok.io -rpcport=15419 -rpcuser=bitcoin -rpcpassword=fsJoJupAXx getinfo

sudo apt-get -y install python3 python3-pip python3.4-venv

# from http://www.ethdocs.org/en/latest/ethereum-clients/cpp-ethereum/building-from-source/linux-ubuntu.html
sudo apt-add-repository -y ppa:george-edison55/cmake-3.x

sudo apt-get -y update
sudo apt-get -y install language-pack-en-base
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
cd ../counterparty-lib && pip install --upgrade -r requirements.txt && python setup.py install --with-solc --with-serpent
python setup.py install


# below values should be your bitcoind RPC
echo '
[Default]
backend-connect=0.tcp.ngrok.io
backend-port=15419
backend-user=bitcoin
backend-password=fsJoJupAXx
' > ~/.config/counterparty/server.conf

# same
echo '
[Default]
wallet-connect=0.tcp.ngrok.io
wallet-port=15419
wallet-user=bitcoin
wallet-password=fsJoJupAXx
' > ~/.config/counterparty/server.conf

# one of the addresses that I've preloaded and are in my bitcoind
# change if you're using your own bitcoind, create an address (`bitcoin-cli -testnet getnewaddress`), send it some BTC and XCP from your TESTNET counterwallet ;)
SOURCE="miJqNkHhC5xsB61gsiSWXeTLnEGSQnWbXB"

counterparty-server --verbose --testnet bootstrap  # download bootstrap image
counterparty-server --verbose --testnet start
