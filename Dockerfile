# Build stage
FROM alpine:3.18 as builder

# Install build dependencies
RUN apk add --no-cache python3 py3-pip leveldb \
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

# Create virtual environment
RUN python3 -m venv /venv
ENV PATH="/venv/bin:$PATH"

# Install maturin in the virtual environment
RUN pip3 install --upgrade pip
RUN pip3 install maturin

# Copy source code
COPY . /counterparty-core

# Build Rust components
WORKDIR /counterparty-core/counterparty-rs
RUN pip3 install .

# Build Python components
WORKDIR /counterparty-core/counterparty-core
RUN pip3 install .

# Runtime stage
FROM alpine:3.18

# Install only runtime dependencies
RUN apk add --no-cache python3 leveldb libstdc++

# Copy virtual environment from builder stage
COPY --from=builder /venv /venv

# Make sure we use the Python from the virtual environment
ENV PATH="/venv/bin:$PATH"

# Set entrypoint
ENTRYPOINT ["/venv/bin/counterparty-server"]
CMD ["start"]