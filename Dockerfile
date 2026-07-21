# syntax=docker/dockerfile:1

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
    llvm-dev \
    patchelf

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Create virtual environment
RUN python3 -m venv /venv
ENV PATH="/venv/bin:$PATH"

# Install maturin in the virtual environment
RUN pip3 install --upgrade pip
RUN pip3 install maturin

# Create root directory for the project
RUN mkdir -p /counterparty-core

# === Rust dependency caching ===
# Copy only Cargo files and create dummy source to fetch dependencies (cacheable layer)
COPY ./counterparty-rs/Cargo.toml ./counterparty-rs/Cargo.lock /counterparty-core/counterparty-rs/
COPY ./counterparty-rs/build.rs /counterparty-core/counterparty-rs/
RUN mkdir -p /counterparty-core/counterparty-rs/src && \
    echo 'fn main() {}' > /counterparty-core/counterparty-rs/src/lib.rs

WORKDIR /counterparty-core/counterparty-rs

# Fetch dependencies - this layer is cached until Cargo.toml/Cargo.lock change
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    cargo fetch

# Copy files required for build
COPY README.md /counterparty-core/README.md
COPY counterparty-core/counterpartycore/lib/config.py /counterparty-core/counterparty-core/counterpartycore/lib/config.py

# Copy Rust source files
COPY ./counterparty-rs /counterparty-core/counterparty-rs

# Build with maturin, using persistent cache for target dir
ENV CARGO_TARGET_DIR=/cargo-target
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    --mount=type=cache,target=/cargo-target \
    maturin build --release -o /wheels && \
    pip3 install /wheels/*.whl

# Build Python components
COPY ./counterparty-core /counterparty-core/counterparty-core
WORKDIR /counterparty-core/counterparty-core
RUN pip3 install .

# Get the last commit hash and store it in a environment variable
COPY .git /counterparty-core/.git
RUN CURRENT_COMMIT=$(python3 -c "from counterpartycore.lib.utils import helpers; print(helpers.get_current_commit_hash(not_from_env=True))") && \
    echo "export CURRENT_COMMIT=\"$CURRENT_COMMIT\"" > /commit_env.sh

# Runtime stage
FROM alpine:3.18

# Install runtime dependencies and debugging utilities
RUN apk add --no-cache python3 leveldb libstdc++ \
    sqlite \
    httpie \
    busybox-extras \
    netcat-openbsd \
    htop \
    gnupg

# Copy virtual environment from builder stage
COPY --from=builder /venv /venv
COPY --from=builder /commit_env.sh /commit_env.sh

RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo '. /commit_env.sh' >> /entrypoint.sh && \
    echo 'exec /venv/bin/counterparty-server "$@"' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Make sure we use the Python from the virtual environment
ENV PATH="/venv/bin:$PATH"

# Set entrypoint with environment variables
ENTRYPOINT ["/entrypoint.sh"]