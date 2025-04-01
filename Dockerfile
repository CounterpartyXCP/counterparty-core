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

# Set working directory to the root of the repository
WORKDIR /counterparty-core/counterparty-core

# Build Rust components
WORKDIR /counterparty-core/counterparty-rs
RUN pip3 install .

# Build Python components
WORKDIR /counterparty-core/counterparty-core
RUN pip3 install .

# Get the last commit hash and store it in a environment variable
RUN CURRENT_COMMIT=$(python3 -c "from counterpartycore.lib.utils import helpers; print(helpers.get_current_commit_hash(not_from_env=True))") && \
    echo "CURRENT_COMMIT=$CURRENT_COMMIT" >> /etc/environment && \
    echo "export CURRENT_COMMIT=$CURRENT_COMMIT" > /commit_env.sh

# Runtime stage
FROM alpine:3.18

# Install only runtime dependencies
RUN apk add --no-cache python3 leveldb libstdc++

# Copy virtual environment from builder stage
COPY --from=builder /venv /venv
COPY --from=builder /etc/environment /etc/environment
COPY --from=builder /commit_env.sh /commit_env.sh

# Make sure we use the Python from the virtual environment
ENV PATH="/venv/bin:$PATH"

# Set entrypoint with environment variables
ENTRYPOINT ["/bin/sh", "-c", "source /commit_env.sh && /venv/bin/counterparty-server $0 $@"]
CMD ["start"]