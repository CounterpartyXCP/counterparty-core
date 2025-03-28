#!/bin/bash

# Function to display messages with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to perform a complete rebuild cycle
perform_rebuild_cycle() {
    local repo_dir=$1
    
    log_message "Starting rebuild cycle..."
    
    # Checkout develop branch
    git checkout develop
    
    # Pull latest changes
    git pull -f origin develop:develop
    
    # Install counterparty-rs module
    if [ -d "$repo_dir/counterparty-rs" ]; then
        cd "$repo_dir/counterparty-rs"
        pip install -e .
        cd "$repo_dir"
    fi
    
    # Run rebuild
    log_message "Running rebuild..."
    counterparty-server rebuild
    
    log_message "Rebuild cycle completed."
}

# Get the repository root directory (script will be in counterparty-core/tools)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Navigate to the repository directory
log_message "Changing to repository directory: $REPO_DIR"
cd "$REPO_DIR" || exit 1

# Infinite loop
while true; do
    perform_rebuild_cycle "$REPO_DIR"
    log_message "Starting next cycle in 5 seconds..."
    sleep 5
done