# Contributing to Counterparty Core

## Reporting a Security Issue

If you believe you have found a security vulnerability, **do not open a public
issue or pull request**. Follow the responsible-disclosure process in
[SECURITY.md](../SECURITY.md), which also covers the status of the (now
discontinued) bug bounty program.


## Reporting an Issue

* Check whether the issue has already been reported.

* List the exact steps required to reproduce the issue, including the exact
  version/commit being run and the platform the software is running on.

* Try to reproduce the issue with verbose logging enabled (`--verbose`) and
  share the relevant log output.


## Making a Pull Request

* **Submit pull requests of substantial value only.** Large numbers of tiny,
  mechanically generated PRs are a maintenance burden, not a contribution.
  Batch related small fixes into a single PR, and open an issue first for
  anything non-trivial so the approach can be discussed. Trivial or
  mass-produced PRs may be closed without review.

* Make (almost) all pull requests against the `develop` branch.

* Code should follow [PEP8](https://peps.python.org/pep-0008/) and must pass
  `ruff check` and `ruff format` (configuration is in `ruff.toml` at the
  repository root, which is authoritative where it differs — e.g. the
  100-character line length).

* Add tests to cover any new or revised logic, and verify that the full test
  suite passes.

* Update the [release notes](../release-notes/) for any user-facing change.

* Changes to consensus logic must be deterministic and gated behind a protocol
  change activation (see `protocol_changes.json`); discuss these in an issue
  before submitting a PR.

* Commit messages should be neatly formatted and descriptive, with a summary
  line, and commits should be organized into logical units.
