FROM counterparty/base

MAINTAINER Counterparty Developers <dev@counterparty.io>

# Install
COPY . /counterparty-lib
WORKDIR /counterparty-lib
RUN pip3 install -r requirements.txt
RUN python3 setup.py install --with-serpent

COPY docker/server.conf /root/.config/counterparty/server.conf
COPY docker/start.sh /usr/local/bin/start.sh
RUN chmod a+x /usr/local/bin/start.sh

# Install counterparty-cli
# NOTE: We can't use "ARG" here, as travis runs an older version of docker without support for build arguments
# NOTE2: In the future, counterparty-lib and counterparty-cli will go back to being one repo...
RUN git clone -b master https://github.com/CounterpartyXCP/counterparty-cli.git /counterparty-cli
WORKDIR /counterparty-cli
RUN pip3 install -r requirements.txt
RUN python3 setup.py install

# Install bootstrap data (mainnet and testnet)
RUN counterparty-server bootstrap
RUN counterparty-server --testnet bootstrap

EXPOSE 4000 4001

# NOTE: Defaults to running on mainnet, specify -e TESTNET=1 to start up on testnet
ENTRYPOINT ["start.sh"]

