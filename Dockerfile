FROM alpine:3.18

# Install runtime dependencies (rarely change)
RUN apk add --no-cache python3 py3-pip leveldb libstdc++

# Install build dependencies (will be removed later)
RUN apk add --no-cache --virtual .build-deps \
    python3-dev \
    musl-dev \
    openssl-dev \
    leveldb-dev \
    pkgconfig \
    curl \
    build-base \
    libffi-dev \
    clang-dev \
    llvm-dev

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install maturin
RUN pip3 install maturin

# Copy README
COPY . counterparty-core

WORKDIR /counterparty-core/counterparty-rs
RUN pip3 install .

WORKDIR /counterparty-core/counterparty-core
RUN pip3 install .

# Cleanup to reduce image size
RUN apk del .build-deps && \
    rm -rf /root/.cargo /root/.cache && \
    pip3 cache purge

ENTRYPOINT ["counterparty-server"]
CMD ["start"]