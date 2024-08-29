# Release Notes - Counterparty Core v10.4.0 (2024-??-??)

This release includes a variety of protocol upgrades.

# Upgrading

# ChangeLog

## Protocole Changes

* Require Dispenser to be Source Address
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2141
    - Spec: https://gist.github.com/adamkrellenstein/04178f3f761ab5826afeb51eec817547
* Make Dispenses Normal Counterparty Transactions
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2141
    - Spec: https://gist.github.com/adamkrellenstein/e9162e89f9dc6521f17c9b2693eda52c
* Be Able to Lock Descriptions
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2153
    - Spec: https://gist.github.com/adamkrellenstein/94bd304ca4e464b6d5db0da2b05e3075
* Fair Minting Protocol
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2142
    - Spec: https://gist.github.com/ouziel-slama/9eb05ff9890eb402cd9adb4e166a5469
* UTXO Support
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2180
    - Spec: https://gist.github.com/ouziel-slama/3b3fa3738063c6390af0d6b692276935
* Gas System
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/2180
    - Spec: https://gist.github.com/adamkrellenstein/7c7cab257cee162233fc2ba6682eb8da
* Expire order matches then orders
    - PR: https://github.com/CounterpartyXCP/counterparty-core/pull/1794
    - Issue: https://github.com/CounterpartyXCP/counterparty-core/pull/1633

## Bugfixes

* Fix adding new transactions in unit test fixtures (`scenarios.py`)

## Codebase

* New test suite with `regtest` network

## API

## CLI

# Credits

* Ouziel Slama
* Warren Puffett
* Adam Krellenstein
