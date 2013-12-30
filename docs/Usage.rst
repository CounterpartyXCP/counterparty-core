The command‐line syntax of ``counterpartyd`` is, generally that of
``counterpartyd.py {OPTIONS} ACTION {ACTION-OPTIONS}``. There is a one action
per message type, and the action produces and broadcasts a message of that
type; the message parameters are specified following the name of the message
type. There are also actions which do not correspond to message types, but
rather exist to provide information about the state of the Counterparty
network, e.g. current balances or open orders.

For a summary of the command‐line arguments and options, see ``counterpartyd.py
--help``.

``counterpartyd`` identifies an Order, Bet, Order Match or Bet Match by an
‘Order ID’, ‘Bet ID’, ‘Order Match ID’, or ‘Bet Match ID’, respectively. Match
IDs are concatenations of the hashes of the two transactions which compose the
corresponding Match, in the order of their appearances in the blockchain.


Other Actions
^^^^^^^^^^^^^

Watch
"""""
The ``watch`` action prints out tables of open orders, open bets, feeds, and
order matches currently awaiting Bitcoin payments from one of your addresses.

Asset
"""""
The ``asset`` action displays the basic properties of a given asset.

Address
"""""""
The ``address`` action displays the details of of all transactions involving
the Counterparty address which is its argument.


Example Usage
^^^^^^^^^^^^^



Display
^^^^^^^
* Quantities of divisible assets are written to eight decimal places.
* Quantities of indivisible assets are written as integers.
* All other quantities, e.g. of prices, odds, leverages, feed values, are specified to four decimal places.
