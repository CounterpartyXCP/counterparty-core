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
# Default to checking out `master`. Allow other branches to be checked out via the `BRANCH` build-arg
# NOTE this won't work with dockerhub automated builds as we currently can't pass in build args
# NOTE2: we could instead put the dockerfile in the counterparty-cli repo and have pip checkout counterparty-lib automatically
# but that approach is not optimal as well -- would like more control (e.g. being able to set up a dev container)
# In the future, counterparty-lib and counterparty-cli will go back to being one repo...
ARG BRANCH=master
ENV BRANCH ${BRANCH}
RUN git clone -b ${BRANCH} https://github.com/CounterpartyXCP/counterparty-cli.git /counterparty-cli
WORKDIR /counterparty-cli
RUN pip3 install -r requirements.txt
RUN python3 setup.py install

# Install bootstrap data (mainnet and testnet)
RUN counterparty-server bootstrap
RUN counterparty-server --testnet bootstrap

EXPOSE 4000 4001

# NOTE: Defaults to running on mainnet, specify -e TESTNET=1 to start up on testnet
ENTRYPOINT ["start.sh"]

