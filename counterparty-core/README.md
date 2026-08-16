# Counterparty Core

**Counterparty Core** is the reference implementation of the
[Counterparty Protocol](https://counterparty.io), an extension to the Bitcoin
protocol which implements a number of features that Bitcoin itself does not
offer. These include token issuance, a fully decentralized and trustless asset
exchange, contracts for difference, native oracles and trustless gaming.
Counterparty works by ‘writing in the margins’ of Bitcoin transactions, and all
Counterparty transactions are Bitcoin transactions with additional data that the
Counterparty software can read and interpret.

This package is the Python node (`counterparty-server`): it parses the Bitcoin
blockchain, maintains the Counterparty ledger and serves the Counterparty API.
It depends on [`counterparty-rs`](https://pypi.org/project/counterparty-rs/),
the Rust extension used for performance-critical work.

## Documentation

- **[docs.counterparty.io](https://docs.counterparty.io)** — official project
  documentation, including installation and node operation instructions.
- **[apidocs.counterparty.io](https://apidocs.counterparty.io/)** — the
  Counterparty Core API reference.
- **[github.com/CounterpartyXCP/counterparty-core](https://github.com/CounterpartyXCP/counterparty-core)**
  — the source repository, its
  [README](https://github.com/CounterpartyXCP/counterparty-core/blob/master/README.md)
  and [release notes](https://github.com/CounterpartyXCP/counterparty-core/tree/master/release-notes).

## Contributing

Bug reports and substantial pull requests are welcome — see the
[contributing guidelines](https://github.com/CounterpartyXCP/counterparty-core/blob/master/.github/CONTRIBUTING.md)
before opening either. Security vulnerabilities must be disclosed privately per
the [security policy](https://github.com/CounterpartyXCP/counterparty-core/blob/master/SECURITY.md).

## License

MIT — see
[LICENSE](https://github.com/CounterpartyXCP/counterparty-core/blob/master/LICENSE).
