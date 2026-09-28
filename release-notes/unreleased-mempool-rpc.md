# Unreleased — mempool backend lookup recovery

- Prevent a missing mempool transaction or parent lookup from retrying indefinitely on the block-processing thread. Failed speculative batches roll back without marking their transactions unsupported. Confirmed-block RPC retry and consensus validation behavior are unchanged.
- Add a cross-process mempool progress watchdog. The isolated `/healthz/live` listener returns `503 mempool_parser_stalled` when an active speculative batch makes no progress for 120 seconds, allowing the supervisor to restart the node. Progress is renewed after each listed/parsed transaction and the signal is cleared on success or rollback. Mempool support stays enabled.

## Recovery deployment

Use `/healthz/live` (not readiness) for liveness. For Kubernetes, a ten-second
period with three consecutive failures triggers recovery approximately 30 seconds
after the watchdog trips; restart/startup time is additional. A pre-existing
60-failure threshold would add ten minutes and must be reduced in the deployment.
Retain a separate generous startup probe for initial sync and State DB rebuilds.

The watchdog is unarmed during confirmed-block parsing, idle following and
startup, and ignored during API startup, API-only operation and State DB rebuilds.
An individual speculative transaction taking over 120 seconds without a progress
checkpoint will deliberately trigger recovery. This bounds best-effort work; it
does not impose a timeout on consensus validation. The supervisor's normal
restart backoff still applies. The watchdog is a safety net, not the normal retry
mechanism and not a detector for every possible deadlock outside mempool parsing.
