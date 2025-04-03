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

# Create root directory for the project
RUN mkdir -p /counterparty-core

# Copy files required to build counterparty-rs
COPY README.md /counterparty-core/README.md
COPY counterparty-core/counterpartycore/lib/config.py /counterparty-core/counterparty-core/counterpartycore/lib/config.py

# Build Rust components
COPY ./counterparty-rs /counterparty-core/counterparty-rs
WORKDIR /counterparty-core/counterparty-rs
RUN pip3 install .

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
    htop

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