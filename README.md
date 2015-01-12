# Description

`counterparty-cli` is a command line interface for [`counterparty-lib`](https://github.com/CounterpartyXCP/counterpartyd).

# Dependencies

* [Python 3](http://python.org)
* [`counterparty-lib`](https://github.com/CounterpartyXCP/counterpartyd)
* [Bitcoin Core](https://github.com/bitcoin/bitcoin) 

# Installation

`pip install counterparty-cli`

or

```
git clone https://github.com/CounterpartyXCP/counterparty-cli.git
cd counterparty-cli
python setup.py install
```

# Counterparty server

Use `counterparty-server.py` to start synchronization with the blockchain and RPC server.

For a list of the available command‐line arguments and options, see
`$ ./counterparty-server.py --help`.

Example:

`./counterparty-server.py --testnet server`

Configuration file:

OS  | Path
------------- | -------------
MacOS | ~/Library/Application Support/counterparty-server/counterparty-server.conf
XP | C:\Documents and Settings\username\Application Data\counterparty-server\counterparty-server.conf
Vista, 7 | C:\Users\username\AppData\Roaming\counterparty-server\counterparty-server.conf
Linux | ~/.config/counterparty-server/counterparty-server.conf

A counterparty-server configuration file looks like this:

    [Default]
    backend-name = addrindex
    backend-connect = localhost
    backend-user = rpcuser
    backend-password = password
    rpc-host = 0.0.0.0
    rpc-user = rpcuser
    rpc-password = password


# Counterparty client
Use `counterparty-client.py` to manage you Counterparty wallet.

For a list of the available command‐line arguments and options, see
`$ ./counterparty-client.py --help`.
For a list of the available arguments for a particular command, see
`$ ./counterparty-client.py send --help`.

Example:

`./counterparty-client.py --testnet send --source=mi9Q6EVaXL1n85J4pRAsR3nVoo2yfDmquV --asset=XCP --quantity=0.1 --destination=muQjaj46wghHprjSjpgU7D55JxKyK5dJtZ`

Configuration file:

OS  | Path
------------- | -------------
MacOS | ~/Library/Application Support/counterparty-client/counterparty-client.conf
XP | C:\Documents and Settings\username\Application Data\counterparty-client\counterparty-client.conf
Vista, 7 | C:\Users\username\AppData\Roaming\counterparty-client\counterparty-client.conf
Linux | ~/.config/counterparty-client/counterparty-client.conf

A counterparty-client configuration file looks like this:

    [Default]
    wallet-name = bitcoincore
    wallet-connect = localhost
    wallet-user = rpcuser
    wallet-password = password
    counterparty-rpc-host = localhost
    counterparty-rpc-user = rpcuser
    counterparty-rpc-password = password

# Further Reading

* [Official Documentation](http://counterparty.io/docs/)
* [Community Wiki](https://github.com/CounterpartyXCP/Community/wiki)
