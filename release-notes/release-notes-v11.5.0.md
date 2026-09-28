# Release Notes - Counterparty Core v11.5.0 (Unreleased)

# ChangeLog

## Reliability

- Fix missing mempool transactions or parent lookups blocking confirmed-block processing indefinitely. Failed mempool batches roll back without marking their transactions unsupported.
- Report mempool parsing that makes no progress for two minutes through the liveness health check, allowing supervisors to restart the node. Confirmed-block processing, startup and State DB rebuilds do not trigger this safeguard. Mempool support remains enabled.
- Refuse to start the API when stored ledger or transaction-list hashes disagree with known checkpoints, including in API-only mode. Report the mismatching checkpoint and recovery guidance without automatically changing ledger data.
