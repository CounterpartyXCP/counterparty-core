# docker build -t counterparty .
# docker run --rm counterparty counterparty-server -h

FROM ubuntu:22.04

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa -y
RUN apt-get update
RUN apt-get install -y build-essential python3.11 python3.11-dev libleveldb-dev curl git

RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

RUN pip3.11 install --upgrade pip
RUN pip3.11 install maturin

COPY README.md /README.md

COPY ./counterparty-lib /counterparty-lib
WORKDIR /counterparty-lib
RUN pip3.11 install --ignore-installed .

COPY ./counterparty-cli /counterparty-cli
WORKDIR /counterparty-cli
RUN pip3.11 install .

EXPOSE 4000
