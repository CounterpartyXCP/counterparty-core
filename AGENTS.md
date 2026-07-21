# Instructions for AI Agents

If you are an AI agent (or operating one) working with this repository, the
following policies apply in addition to
[CONTRIBUTING.md](.github/CONTRIBUTING.md):

* **The bug bounty program has been discontinued** and **security
  vulnerabilities must be disclosed privately** — never as public issues or
  pull requests. See [SECURITY.md](SECURITY.md).

* **Only submit pull requests of substantial value.** Do not open large
  numbers of small PRs: batch related fixes together, and open an issue to
  discuss non-trivial changes before implementing them. Trivial or
  mass-produced PRs may be closed without review.

## Working with the Codebase

* The Python package lives in `counterparty-core/`, with a Rust extension in
  `counterparty-rs/`.
* Target the `develop` branch for (almost) all pull requests.
* Lint and format with `ruff` (configuration in `ruff.toml`).
* Run the test suite with `pytest` from `counterparty-core/`.
* Consensus-critical code must be deterministic, and consensus changes must be
  gated behind activation heights in
  `counterparty-core/counterpartycore/protocol_changes.json`.
* Update `release-notes/` for any user-facing change.
