# Counterparty

The official Counterparty protocol specification


## Summary

Counterparty is a protocol designed to use the Bitcoin blockchain as a
transport layer and as a service for trusted timestamping and proof‐of‐
publication.

All wallet management is handled by Bitcoind/Bitcoin-Qt: the user must specify
which of his addresses he would like to use to make a given Counterparty
transaction.

The reference implementation is `counterpartyd`, which is hosted at
<https://github.com/PhantomPhreak/counterpartyd>.


## Parsing

Every Counterparty message has the following identifying features:
* One source address
* One destination address
* A quantity of bitcoins sent from the source to the destination, if it exists.
* A fee, in bitcoins, paid to the bitcoin miners who include the transaction in
a block.
* Up to 80 bytes of miscellaneous ‘data’, imbedded in the Bitcoin transaction’s
one alloted `OP_RETURN` output.

For identification purposes, every Counterparty transaction’s ‘data’ field is
prefixed by the string ‘CNTRPRTY’, encoded in UTF‐8. This string is long enough
that transactions with pseudo‐random data stored in the `OP_RETURN` field
will be extremely unlikely to be mistaken for Counterparty transactions. In
testing, this string is simply ‘XX’.

Every Bitcoin transaction carrying a Counterparty transaction must have between
one and three outputs: the destination output (optional), the data output
(required), and the change output (optional), in that order. The change output
has no importance to Counterparty.

The existence of the destination output, and the significance of the size of
the Bitcoin fee and the Bitcoins transacted, depend on the Counterparty
message type, which is determined by the four bytes in the data field that
immediately follow the identification prefix. The rest of the data has a
formatting specific to the message type, described in the source code.

Every Counterparty transaction must, moreover, have a unique and unambiguous
source address: all of the inputs to a Bitcoin transaction which contains a
Counterparty transaction must be the same—the unique source of the funds in the
Bitcoin transaction is the source of the Counterparty transaction within.

The source and destination of a Counterparty transaction are Bitcoin addresses,
and any Bitcoin address may receive any Counterparty asset (and send it, if it
owns any).

All messages are parsed in order, one at a time, ignoring block boundaries for
everything except for the expiration of orders and bets.


## Message Types

* Send
* Order
* BTCPay
* Issue
* Broadcast
* Bet
* Dividend
* Burn


### Send

A **send** message sends a quantity of any Counterparty asset from the source
address to the destination address. If the sender does not hold a sufficient
amount of that asset at the time that the send message is parsed (in the
sequence of transactions), then the send is invalid.


### Order

An ‘order’ is an offer to *give* a particular quantity of a particular asset
and *get* some quantity of some other asset in return. No distinction is drawn
between a ‘buy order’ and a ‘sell order’. The assets being given are escrowed
away immediately upon the order being parsed. That is, if someone wants to give
1 XCP for 2 BTC, then as soon as he publishes that order, his balance of XCP is
reduced by one.

When an order is seen in the blockchain, the protocol attempts to match it,
deterministically, with another open order previously seen. Two matched orders
are called a ‘order match’. If either of a order match’s orders involved
Bitcoin, then the order match is assigned the status ‘awaiting BTC payment’
until the necessary BTCPay transaction is published. Otherwise, the trade is
completed immediately, with the protocol itself assigning the participating
addresses their new balances.

All orders are *limit orders*: an asking price is specified in the ratio of how
much of one would like to get and give; an order is matched to the open order
with the best price, and the order match is made at *that* price. That is, if
there is one open order to sell at .11 XCP/BTC, and another at .12 XCP/BTC,
then any new order to buy at .14 XCP/BTC will be matched to the first sell
order, and the XCP and BTC will be traded at a price of .11 XCP/BTC.

All orders allow for partial execution; there are no all‐or‐none orders (but
the Chicago Board Options Exchange doesn’t allow those either). If, in the
previous example, the party buying the bitcoins wanted to buy more than the
first sell offer had available, then the rest of the buy order would be filled
by the latter existing order. After all possible order matches are made, the
current (buy) order is listed as an open order itself. If there exist multiple
open orders at the same price, then order that was placed earlier is matched
first.

Open orders cannot be changed. To cancel an open order of your own, simply
[attempt to] fill it yourself.

Open orders expire after they have been open for a user‐specified number of
blocks. Order Matches waiting for Bitcoin payments expire as soon as one of the
constituent orders expires. Upon the expiration of all orders and order matches, the
escrowed funds are returned to the parties that originally had them.

In general, there can be no such thing as a fake order, because the assets that
each party is offering are stored in escrow. However, it is impossible to
escrow bitcoins, so those attempting to buy bitcoins may ask that only orders
which pay a fee in bitcoins to Bitcoin miners be matched to their own. On the
other hand, when creating an order to sell bitcoins, a user may pay whatever
fee he likes.

Payments of bitcoins to close order matches waiting for bitcoins are done with
the a **btcpay** message, which stores in its `OP_RETURN` output only the
transaction hashes which compose the Order Match which it fulfils.


### Issue

Assets are issued with the **issuance** message type: the user picks a name and
a quantity, and the protocol credits his address accordingly. The Asset ID must
either be unique or be one previously issued by the same address.  When
re‐issuing an asset, that is, issuing more of an already‐issued asset, the
divisibilities and the issuing address must match.

Asset names are strings of uppercase ASCII characters that, when encoded as a
decimal integer, are greater than 26^3 and less than or equal to 256^8: all
asset names, other than ‘BTC’ and ‘XCP’ must be at least four letters long.
Asset names are stored as eight‐byte unsigned integers in the `OP_RETURN``
field.

Assets may be either divisible or indivisible, and divisible assets are
divisible to eight decimal places.

The rights to issue assets under a given name may be transferred to any other
address. A transaction which constitutes such a transfer must not itself issue
any more of that asset. Otherwise, issuances of zero quantity are interpreted
as locking, irreversibly, the issuance of the asset in question, and
guaranteeing its holders against its inflation.


### Broadcast

A **broadcast** message publishes textual and numerical information, along
with a timestamp, as part of a series of broadcasts called a ‘feed’. One feed
is associated with one address: any broadcast from a given address is part of
that address’s feed. The timestamps of a feed must increase monotonically.

Bets are made on the numerical values in a feed, which values may be the prices
of a currency, or parts of a code for describing discrete possible outcomes of
a future event, for example. One might describe such a code with a text like,
‘US QE on 2014-01-01: dec=1, const=2, inc=3’ and announce the results with ‘US
QE on 2014-01-01: decrease!’ and a value of 1. The schema for more complicated
bets may be published off‐chain.

The publishing of a single broadcast with a null string for a textual message
locks that feed, and prevents it both from being the source of any further
broadcasts and from being the subject of any new bets. (If a feed is locked
while there are open bets or unsettled bet matches that refer to it, then those
bets and bet matches will expire harmlessly.)

A feed is identified by the address which publishes it.


### Bet

There are (currently) two kinds of **bets**. The first is a wager that the
value of a particular feed will be equal (or not equal) to a certain value —
the *target value* — at the *deadline*. The second is a contract for difference
with a definite settlement date. Both simple Equal/NotEqual Bets and Bull/Bear
CFDs have their wagers put in escrow upon being matched, and they are settled
when the feed that they rely on passes the deadline. CFDs, actually, may be
force‐liquidated before then if the feed value moves so much that the escrow is
exhausted.

CFDs may be leveraged, and their leverage level is specified with 5040 equal to
the unit and stored as an integer: a leverage level of 5040 means that the
wager should be leveraged 1:1; a level of 10080 means that a one‐point increase
in the value of a feed entails a two‐point increase (decrease) in the value of
the contract for the bull (bear).

CFDs have no target value and Equal/NotEqual Bets cannot be leveraged. However,
for two Bets to be matched, their leverage levels, deadlines and target values
must be identical. Otherwise, they are matched the same way that orders are,
except a Bet’s *odds* are the multiplicative inverse of an order’s price
(odds = wager/counterwager): each Bet is matched, if possible, to the open
Bet with the highest odds, as much as possible.

0 is not a valid target value, and Bet Matches (contracts) are not affected by
broadcasts with a null value.

Bets cannot have a deadline later that the timestamp of the last broadcast of
the feed that they refer to.

Bets expire the same way that orders do, i.e. after a particular number of
blocks. Bet Matches expire 2016 blocks after a block is seen with a block timestamp
after its deadline.

Open bets cannot be changed. To cancel an open bet of your own, simply [attempt
to] fill it yourself.


### Dividend

A dividend payment is a payment of some quantity of XCP to every holder of a
given asset in proportion to the size of their holdings. Dividend‐yielding
assets may be either divisible or indivisible. A dividend payment to any asset
may originate from any address.


### Burn

Balances in Counterparty’s native currency, ‘XCP’, will be initialised by
‘burning’ bitcoins in miners’ fees during a particular period of time using the
a **burn** message type. The number of XCP earned per bitcoin is calculated
thus: 

	XCP_EARNED = BTC_BURNED * (1000 * (1 + .5 * ((END_BLOCK - CURRENT_BLOCK) / (END_BLOCK - START_BLOCK))

`END_BLOCK` is the block after which the burn period is over and
`START_BLOCK` is the block with which the burn period begins. The earlier the
burn, the better the price, which may be between 1000 and 1500 XCP/BTC.

Burn messages have precisely the string ‘ProofOfBurn’ stored in the
`OP_RETURN` output.
