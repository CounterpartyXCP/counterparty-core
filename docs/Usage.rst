The command‐line syntax of ``counterpartyd`` is generally that of ``python3
counterpartyd.py {OPTIONS} ACTION {ACTION-OPTIONS}``. There is a one action per
message type, which action produces and broadcasts such a message; the message
parameters are specified following the name of the message type. There are also
actions which do not correspond to message types, but rather exist to provide
information about the state of the Counterparty network, e.g. current balances
or open orders.

For a summary of the command‐line arguments and options, see ``python3
counterpartyd.py --help``.

N.B. ``counterpartyd`` identifies an Order, Bet, Order Match or Bet Match by an
‘Order ID’, ‘Bet ID’, ‘Order Match ID’, or ‘Bet Match ID’, respectively. Match
IDs are concatenations of the hashes of the two transactions which compose the
corresponding Match, in the order of their appearances in the blockchain.


Configuration
^^^^^^^^^^^^^

testnet
``--testnet``

testcoin
``--testcoin``


--rpc-password

configuration file
        different format from bitcoin.conf
        server options


Display
^^^^^^^
* Quantities of divisible assets are written to eight decimal places.
* Quantities of indivisible assets are written as integers.
* All other quantities, i.e. prices, odds, leverages, feed values and target
values, are specified to four decimal places.


Functions
^^^^^^^^^^^^^^^^^

Server
""""""
This must be running in the background.

Burn
""""
* ``python3 counterpartyd.py --testnet --rpc-password=PASSWORD burn --from=mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns --quantity=.5``

Send
""""
* ``python3 counterpartyd.py --testnet --rpc-password=PASSWORD send --from=mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns --quantity=3 --asset=BBBC --to=n3BrDB6zDiEPWEE6wLxywFb4Yp9ZY5fHM7``
        * Divisible or indivisible

Order
"""""


BTCPay
""""""

Issue
"""""
* ``python3 counterpartyd.py --testnet --rpc-password=PASSWORD issuance --from=mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns --quantity 100 --asset 'BBBC'``
* ``python3 counterpartyd.py --testnet --rpc-password=PASSWORD issuance --from=mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns --quantity 100 --asset 'BBBQ' --divisible``


Broadcast
"""""""""

Bet
"""

Dividend
""""""""


Market
"""""
The ``market`` action prints out tables of open orders, open bets, feeds, and
order matches currently awaiting Bitcoin payments from one of your addresses.
It is capable of filtering orders by assets to be bought and sold.

Asset
"""""
The ``asset`` action displays the basic properties of a given asset.

Address
"""""""
The ``address`` action displays the details of of all transactions involving
the Counterparty address which is its argument.
