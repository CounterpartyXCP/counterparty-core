FROM monaparty/base

MAINTAINER Monaparty Developers <dev@monaparty.me>

# Install counterparty-lib
COPY . /counterparty-lib
WORKDIR /counterparty-lib
RUN pip3 install git+https://github.com/petertodd/python-bitcoinlib.git@98676f981bf14a6a3a8313e762161cc289043b58#egg=python-bitcoinlib-0.8.1
RUN pip3 install git+https://github.com/monaparty/python-altcoinlib@abb1e38#egg=python-altcoinlib-0.4.1
RUN pip3 install -r requirements.txt
RUN python3 setup.py develop
RUN python3 setup.py install_apsw
RUN pip3 freeze

# Install counterparty-cli
# NOTE: By default, check out the counterparty-cli master branch. You can override the BRANCH build arg for a different
# branch (as you should check out the same branch as what you have with counterparty-lib, or a compatible one)
# NOTE2: In the future, counterparty-lib and counterparty-cli will go back to being one repo...
ARG CLI_BRANCH=monaparty
ENV CLI_BRANCH ${CLI_BRANCH}
RUN git clone -b ${CLI_BRANCH} https://github.com/monaparty/counterparty-cli.git /counterparty-cli
WORKDIR /counterparty-cli
RUN pip3 install -r requirements.txt
RUN python3 setup.py develop
RUN pip3 freeze

# Additional setup
COPY docker/server.conf /root/.config/counterparty/server.conf
COPY docker/start.sh /usr/local/bin/start.sh
RUN chmod a+x /usr/local/bin/start.sh
WORKDIR /

# Pull the mainnet and testnet DB boostraps
RUN counterparty-server bootstrap --quiet
RUN counterparty-server --testnet bootstrap --quiet

EXPOSE 4000 14000

# NOTE: Defaults to running on mainnet, specify -e TESTNET=1 to start up on testnet
ENTRYPOINT ["start.sh"]

