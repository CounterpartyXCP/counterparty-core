# docker build -t counterparty .
# docker run --rm counterparty counterparty-server -h

FROM ubuntu:22.04

RUN apt-get update
# avoid interactive dialog
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata
# install add-apt-repository
RUN apt-get install -y software-properties-common
# add deadsnakes ppa repository
RUN add-apt-repository ppa:deadsnakes/ppa -y
RUN apt-get update
# install python3.11 and other dependencies
RUN apt-get install -y build-essential python3.11 python3.11-dev libleveldb-dev curl git

# install pip3.11
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11
RUN pip3.11 install --upgrade pip

# set python3.11 as default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

# install rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# install maturin
RUN pip3.11 install maturin
# Fix ERROR: Cannot uninstall 'blinker'. It is a distutils installed project and thus we cannot accurately determine which files belong to it which would lead to only a partial uninstall.
RUN apt-get remove python3-blinker -y

# copy repository
COPY README.md /README.md
COPY ./counterparty-rs /counterparty-rs
COPY ./counterparty-lib /counterparty-lib
COPY ./counterparty-cli /counterparty-cli

# install counterparty-lib
WORKDIR /counterparty-rs
RUN cargo build
RUN pip3.11 install .

# install counterparty-lib
WORKDIR /counterparty-lib
RUN pip3.11 install .

# install counterparty-cli
WORKDIR /counterparty-cli
RUN pip3.11 install .

# expose API port
EXPOSE 4000
