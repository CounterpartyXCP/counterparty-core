# docker build -t counterparty .
# docker run --rm counterparty counterparty-server -h

FROM ubuntu:22.04

RUN apt-get update
# install dependencies
RUN apt-get update && apt-get install -y \
  python3 \
  python3-dev \
  python3-pip \
  libleveldb-dev \
  curl \
  libclang-dev \
  && rm -rf /var/lib/apt/lists/*

# install rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# install maturin
RUN pip3 install maturin

# copy repository
COPY README.md /README.md
COPY ./counterparty-rs /counterparty-rs
COPY ./counterparty-core /counterparty-core

# install counterparty-rs
WORKDIR /counterparty-rs
RUN pip3 install .

# install counterparty-core
WORKDIR /counterparty-core
RUN pip3 install .

ENTRYPOINT [ "counterparty-server"]
CMD [ "start" ]
