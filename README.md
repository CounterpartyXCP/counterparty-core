<br />
<div align="center"><a href="https://www.counterparty.io/"><img src="https://www.counterparty.io/images/xcp.svg" width="200"></a></div>

<h1 align="center">
  Counterparty: an Extension to Bitcoin by State-Machine Replication
</h1>

<div align="center">
<table>
<tr>
    <td>Testing</td>
    <td>
        <a target="_blank" rel="noopener noreferrer" href="https://codecov.io/gh/CounterpartyXCP/counterparty-core" >
            <img src="https://codecov.io/gh/CounterpartyXCP/counterparty-core/graph/badge.svg?token=Qj8WFBsXmm"  alt="Codecov" style="max-width: 100%;"/>
        </a>
        <a target="_blank" rel="noopener noreferrer" href="https://github.com/CounterpartyXCP/counterparty-core/actions/workflows/units_test.yml/badge.svg"><img src="https://github.com/CounterpartyXCP/counterparty-core/actions/workflows/units_test.yml/badge.svg" alt="Functionals" style="max-width: 100%;"></a>
        <a target="_blank" rel="noopener noreferrer" href="https://github.com/CounterpartyXCP/counterparty-core/actions/workflows/functionals_test.yml/badge.svg"><img src="https://github.com/CounterpartyXCP/counterparty-core/actions/workflows/functionals_test.yml/badge.svg" alt="Functionals" style="max-width: 100%;"></a>
        <a target="_blank" rel="noopener noreferrer" href="https://github.com/CounterpartyXCP/counterparty-core/actions/workflows/integrations_test.yml/badge.svg"><img src="https://github.com/CounterpartyXCP/counterparty-core/actions/workflows/integrations_test.yml/badge.svg" alt="Functionals" style="max-width: 100%;"></a>
        <a target="_blank" rel="noopener noreferrer" href="https://github.com/CounterpartyXCP/counterparty-core/actions/workflows/property_test.yml/badge.svg"><img src="https://github.com/CounterpartyXCP/counterparty-core/actions/workflows/property_test.yml/badge.svg" alt="Functionals" style="max-width: 100%;"></a>
    </td>
</tr>
<tr>
    <td>Scanning</td>
    <td>
        <a target="_blank" rel="noopener noreferrer" href="https://github.com/CounterpartyXCP/counterparty-core/actions/workflows/bandit_scanner.yml/badge.svg"><img src="https://github.com/CounterpartyXCP/counterparty-core/actions/workflows/bandit_scanner.yml/badge.svg" alt="Functionals" style="max-width: 100%;"></a>
        <a target="_blank" rel="noopener noreferrer" href="https://github.com/CounterpartyXCP/counterparty-core/actions/workflows/codeql_scanner.yml/badge.svg"><img src="https://github.com/CounterpartyXCP/counterparty-core/actions/workflows/codeql_scanner.yml/badge.svg" alt="Functionals" style="max-width: 100%;"></a>
        <a target="_blank" rel="noopener noreferrer" href="https://github.com/CounterpartyXCP/counterparty-core/actions/workflows/pylint_scanner.yml/badge.svg"><img src="https://github.com/CounterpartyXCP/counterparty-core/actions/workflows/pylint_scanner.yml/badge.svg" alt="Functionals" style="max-width: 100%;"></a>
        <a target="_blank" rel="noopener noreferrer" href="https://github.com/CounterpartyXCP/counterparty-core/actions/workflows/ruff_scanner.yml/badge.svg"><img src="https://github.com/CounterpartyXCP/counterparty-core/actions/workflows/ruff_scanner.yml/badge.svg" alt="Functionals" style="max-width: 100%;"></a>
    </td>
</tr>
<tr>
    <td>Docker</td>
    <td>
        <a target="_blank" rel="noopener noreferrer" href="https://github.com/CounterpartyXCP/counterparty-core/actions/workflows/docker.yml/badge.svg">
            <img src="https://github.com/CounterpartyXCP/counterparty-core/actions/workflows/docker.yml/badge.svg" alt="Docker" style="max-width: 100%;">
        </a>
        <a target="_blank" rel="noopener noreferrer" href="https://hub.docker.com/r/counterparty/counterparty"><img alt="Docker Image Size" src="https://img.shields.io/docker/image-size/counterparty/counterparty" style="max-width: 100%;"></a>
    </td>
</tr>
<tr>
    <td>Github</td>
    <td>
        <img alt="GitHub commit activity" src="https://img.shields.io/github/commit-activity/t/CounterpartyXCP/counterparty-core">
        <img alt="GitHub contributors" src="https://img.shields.io/github/contributors/CounterpartyXCP/counterparty-core">
        <img alt="GitHub Release Date" src="https://img.shields.io/github/release-date/CounterpartyXCP/counterparty-core">
    </td>
</tr>
<tr>
    <td>Other</td>
    <td>
        <img alt="GitHub License" src="https://img.shields.io/github/license/CounterpartyXCP/counterparty-core">
        <img alt="Python Versions" src="https://img.shields.io/badge/python-3.10_%7C_3.11_%7C_3.12_%7C_3.13-green">
    </td>
</tr>
</table>
</div>


**Counterparty Core** is the reference implementation of the [Counterparty Protocol](https://counterparty.io), an extension to the Bitcoin protocol which implements a number of features that Bitcoin itself does not offer. These include token issuance, a fully decentralized and trustless asset exchange, contracts for difference, native oracles and trustless gaming. Counterparty works by ‘writing in the margins’ of Bitcoin transactions, and all Counterparty transactions are Bitcoin transactions with additional data that the Counterparty software can read and interpret.

See the **[official project documentation](http://docs.counterparty.io)** for more information, and for instructions on installing and running the Counterparty software. The reference for the Counterparty Core API is available at **[apidocs.counterparty.io](https://apidocs.counterparty.io/)**.

This repository contains:

- **[`counterparty-core/`](counterparty-core/)** — the Python reference implementation (the `counterparty-server` node).
- **[`counterparty-rs/`](counterparty-rs/)** — the Rust extension used by the node for performance-critical work.
- **[`counterparty-client/`](counterparty-client/)** — a Rust command-line client (`xcp`) with a local encrypted wallet, for composing, signing and broadcasting Counterparty transactions against an API server. See its [README](counterparty-client/README.md).


## Protocol upgrade signals

The node checks the published minimum-version requirements at startup, then
refreshes them in one background thread approximately every five minutes. Failed
refreshes retry after one minute. API requests and parsing never fetch metadata
over HTTP: the parser and API workers share one cached status.

Every v2 API response includes `X-COUNTERPARTY-PROTOCOL-STATUS`. When this binary
lacks a required upgrade, `X-COUNTERPARTY-REQUIRED-VERSION` identifies it. Both
headers are exposed to browser clients through CORS. The `/v2/` root adds a
`protocol_status` object with the status, required version, activation height,
change name, `last_checked`, `last_successful_check` (Unix seconds), metadata
error and explicit `force_override` flag.

- `compatible`: the binary supports the successfully fetched requirements.
- `upgrade_pending`: an unsupported requirement is known but its activation
  height has not been reached; normal responses continue.
- `incompatible`: a known unsupported requirement has activated. Ordinary
  ledger, compose and health requests return `503 protocol_upgrade_required`,
  with details in the error body's `protocol_status`. The v2 root, routes and OpenAPI
  diagnostics remain accessible. Results already in the response cache cannot
  bypass the guard.
- `unknown`: no usable verified status is available. Ordinary requests return
  `503 protocol_status_unknown` unless verification is deliberately bypassed.
- `stale`: the latest refresh failed or the last success is over ten minutes old.
  Previously verified requirements remain enforced and service continues under
  that cached policy. This is an availability grace state, not assurance that an
  unreachable publisher has announced no newer change; consumers should inspect
  the timestamps and alert on persistent staleness.
- `bypassed`: `--force` has deliberately disabled upgrade enforcement. The
  override is never advertised as compatible. Background metadata refresh still
  supplies advisory requirements when available; do not treat bypassed status
  as a safety guarantee.

Known activation boundaries are checked before a confirmed block can mutate the
ledger. An incompatible parser stops until the software is upgraded/restarted;
its API remains available for diagnostics. Dedicated `/healthz/ready` includes
the cached protocol status and returns 503 for incompatibility. `/healthz/live`
continues to describe process health, preventing repeated restarts of a binary
that cannot support the change. Readiness samples are refreshed once per second.

Diagnostics remain available directly on the node. A proxy that removes unready
backends may replace their error responses or hide the root; operators can use
the direct health listener or port-forwarding to inspect the upgrade reason.
This does not automatically roll back already-divergent history; follow the
target release's recovery guidance when upgrading after activation.

The deprecated v1 API, when explicitly enabled, uses the same guard and headers.
Its JSON-RPC error's `data` contains the protocol status; use the v2 root for
diagnostics when an upgrade is required.

API-only mode also receives background updates; its compatibility uses the frozen
ledger's height when no Bitcoin tip is available. Offline reparse tools keep
their existing local protocol checks. A startup metadata failure still prevents
normal startup unless `--force` is used. Existing checkpoint validation remains
mandatory; this does not permit corrupt history or change consensus rules,
activation heights or ledger formats.

Check readiness and protocol status together. These are self-reported operational
signals, not a cryptographic attestation of ledger correctness. Older binaries
cannot gain the new checks without an upgrade; a missing status header means
this observability is unsupported, not that the node is compatible.

## Contributing

Bug reports and substantial pull requests are welcome — see the [contributing guidelines](.github/CONTRIBUTING.md) before opening either, and [AGENTS.md](AGENTS.md) if you are using an AI agent. Security vulnerabilities must be disclosed privately per the [security policy](SECURITY.md).
