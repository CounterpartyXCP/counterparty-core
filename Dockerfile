# docker build -t counterparty .
# docker run --rm counterparty counterparty-server -h

FROM ubuntu:22.04

RUN apt-get update
# install dependencies
RUN apt-get install -y python3 python3-dev python3-pip libleveldb-dev curl

# install rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# install maturin
RUN pip3 install maturin

# copy repository
COPY README.md /README.md
COPY ./counterparty-rs /counterparty-rs
COPY ./counterparty-lib /counterparty-lib
COPY ./counterparty-cli /counterparty-cli

# install counterparty-lib
WORKDIR /counterparty-rs
RUN pip3 install .

# install counterparty-lib
WORKDIR /counterparty-lib
RUN pip3 install .

# install counterparty-cli
WORKDIR /counterparty-cli
RUN pip3 install .

ENTRYPOINT [ "counterparty-server", "start" ]
CMD [ "-h" ]
