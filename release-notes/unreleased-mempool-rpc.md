# Unreleased — mempool backend lookup recovery

- Prevent a missing mempool transaction or parent lookup from retrying indefinitely on the block-processing thread. Failed speculative batches roll back without marking their transactions unsupported. Confirmed-block RPC retry and consensus validation behavior are unchanged.
