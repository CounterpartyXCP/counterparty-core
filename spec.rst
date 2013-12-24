Counterparty Specification
==========================

**Version: 0.0.1**

**ATTENTION:**
*Counterparty* is currently operating only on the Bitcoin ``testnet``
blockchain, because it requires the use of a feature of the Bitcoin protocol
that is not yet enabled in the official client (namely ``OP_RETURN`` outputs).


Summary
-------

Counterparty is a protocol designed to use the Bitcoin blockchain as a
transport layer, and as a service for trusted timestamping and proof‐of‐
publication.

All wallet management is handled by ``bitcoind``/``bitcoin-qt``: the user must
specify which of his addresses he would like to use to make a given
Counterparty transaction.

The reference implementation is ``counterpartyd.py``, which is hosted at
https://github.com/phantomphreak/Counterparty.


Protocol
--------

Every Counterparty message has the following identifying features:
* One source address
* Zero or one destination addresses
* A quantity of bitcoins sent from the source to the destination, if it exists.
* A fee, in bitcoins, paid to the bitcoin miners who include the transaction in
a block.
* Up to 80 bytes of miscellaneous ‘data’, imbedded in the Bitcoin transaction’s
one alloted ``OP_RETURN`` output.

For identification purposes, every Counterparty transaction’s ‘data’ field is
prefixed by a common string, encoded in UTF‐8. In testing, this string is
simply ‘TEST’. In the production version, this string will be longer, so that
transactions with pseudo‐random data stored in the ``OP_RETURN`` field will be
extremely unlikely to be mistaken as Counterparty transactions.

Every Counterparty transaction must, moreover, have a unique and unambiguous
source address: all of the inputs to a Bitcoin transaction which contains a
Counterparty transaction must be the same—the unique source of the funds in the
Bitcoin transaction is the source of the Counterparty transaction within.

The destination address is simply the address of the first transaction output
containing a valid Bitcoin address.

The existence of the destination address, and the significance of the size of
the Bitcoin fee and the Bitcoins transacted, depends on the Counterparty
message type. The message type is determined by the four bytes in the data
field that immediately follow the identification prefix. The rest of the data
has a formatting specific to the message type.

All messages are parsed in order, one at a time, ignoring block boundaries for
everything except for the expiration of orders and bets.

Orders and deals are identified by an ‘Order ID’ and a ‘Deal ID’, respectively,
which, in both cases, are a concatenation of hashes of the two transaction
which compose them, in order of their appearance in the blockchain.

A feed is identified by the address which publishes it.


Message Types
^^^^^^^^^^^^^
* Send
* Order
* BTCPay
* Issue
* Broadcast
* Bet
* Dividend
* Burn


Proof of Burn
-------------

Balances in the currency native to Counterparty, ‘XCP’, will be initialised by
‘burning’ bitcoins in miners’ fees during particular period of time using the
``burn`` command, for which there is a corresponding message type. The number
of XCP earned per bitcoin is calculated thus: 

XCP_EARNED = BTC_BURNED * (100 * (1 + ((END_BLOCK - CURRENT_BLOCK) / (END_BLOCK - START_BLOCK))

``END_BLOCK`` is the block after which the burn period is over and
``START_BLOCK`` is the block with which the burn period begins. The earlier the
burn, the better the price, which may be between 100 and 200 XCP/BTC.


Features
--------

Send
^^^^

The ``send`` command sends a quantity of any Counterparty asset from the source
address to the destination address. If the sender does not hold a sufficient
amount of that asset at the time that the send message is parsed (in the
sequence of transactions), then the send is invalid.


Order
^^^^^

An ‘order’ is an offer to *give* a particular quantity of a particular asset in
order to *get* some quantity of some other asset. No distinction is drawn
between a buy order and a sell order. The assets being given are escrowed away
immediately upon the order being parsed. That is, if someone wants to give 1
XCP for 2 BTC, then as soon as he publishes that order, his balance of XCP is
reduced by one,

When an order is seen in the blockchain, the protocol attempts to match it,
deterministically, with another open order previously seen. Two matched orders
are called a ‘deal’. If either of a deal’s orders involved Bitcoin, then the
deal is assigned the status ‘waiting for bitcoins’, until the necessary BTCPay
transaction is published. Otherwise, the trade is completed immediately, with
the protocol itself assigning the participating addresses their new balances.

All orders are *limit orders*: an asking price is specified in the ratio of how
much of one would like to get and give; an order is matched to the open order
with the best price, and the deal is made at *that* price. That is, if there is
one open order to sell at .11 XCP/BTC, and another at .12 XCP/BTC.  Then any
new order to buy at .14 XCP/BTC will be matched to the first sell order, and
the XCP and BTC will be traded at a price of .11 XCP/BTC.

All orders allow for partial execution; there are no all‐or‐none orders (but
the Chicago Board Options Exchange doesn’t allow those either). If, in the
previous example, the party buying the bitcoins wanted to buy more than the
first sell offer had available, then the rest of the buy order would be filled
by the latter existing order. After all possible deals are made, the current
(buy) order is listed as an open order itself. If there exist multiple open
orders at the same price, the order that was placed earlier is matched first.

Open orders cannot be changed. To cancel an open order of yours, simply
[attempt to] fill it yourself.

Open orders expire after they have been open for a user‐specified number of
blocks. Deals waiting for bitcoin payments expire as soon as one of the
constituent orders expires. Upon the expiration of all orders and deals, the
escrowed funds are returned to the parties that originally had them.

In general, there can be no such thing as a fake order, because the assets that
each party is offering are stored in escrow. However, it is impossible to
escrow bitcoins, so those attempting to buy bitcoins may ask that only orders
which pay a fee in bitcoins to Bitcoin miners be matched to their own. On the
other hand, when creating an order to sell bitcoins, a user may pay whatever
fee he likes.

Payments of bitcoins to close deals waiting for bitcoins are done with the
``btcpay`` command, which needs only the ID of the deal in question to make the
necessary payment.

The ``deadline`` should be after the expiration.


Issue
^^^^^

Assets are issued with the ``issue`` command: the user picks an integer Asset
ID and a quantity, and the protocol credits his address accordingly. The Asset
ID must either be unique or be one previously issued by the same address. When
re‐issuing an asset, that is, issuing more of an already‐issued asset, the
divisibilities and the issuing address must match.

Divisible assets are divisible to eight decimal places.


Broadcast
^^^^^^^^^

The ``broadcast`` command publishes textual and numerical information, along
with a timestamp, as part of a series called a ‘feed’. One feed is associated
with one address: any broadcast from a given address is part of that address’s
feed.

Bets are made on the sequence of numerical values in a feed, which values may
be the prices of a currency, or parts of a code for describing discrete
possible outcomes of a future event, for example. One might describe such a
code with something like, ``--text='US QE on 2014-01-01: dec=1, const=2, inc=3'``
and announce the results with ``--text='US QE on 2014-01-01: decrease!'
--value=1``. The schema for more complicated bets may be published off‐chain.

The publishing of a single broadcast with a null string for a textual message
locks that feed, and prevents it both from being the source of any further
broadcasts and from being the subject of any new bets. (If a feed is locked
while there are open bets or unsettled contracts that refer to it, then those
bets and contracts will expire harmlessly.)


Bet
^^^

**TBA**


Dividend
^^^^^^^^

A dividend payment is a payment of some quantity of XCP to every holder of a
given asset in proportion to the size of their holdings. Dividend‐yielding
assets must be indivisible. The dividend payment need not be made from the
address which first issued the shares (indivisible assets).


Watch
^^^^^

The ``watch`` command prints out tables of open orders, open bets, and deals
currently waiting for bitcoin payments from one of your addresses.


Acknowledgements
----------------
* cityglut@bitmessage.ch
* xnova@bitmessage.ch
