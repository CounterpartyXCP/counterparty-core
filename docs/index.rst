Counterparty
========================================

**Counterparty is an protocol that provides decentralized financial instrument on top of the Bitcoin blockchain.** 

Besides acting as a store of value, decentralized payment network and public ledger, Bitcoin itself allows programs to embed arbitrary data into
transactions. The value of this is immense, as it allows programs to be developed that add new functionality on top of Bitcoin, while inheriting
Bitcoin's security model, peer to peer processing system, and decentralized nature in the process.   

The Counterparty reference client (``counterpartyd``), as well as any other programs that implement the Counterparty specification can perform the following types of operations:
  
- **Send**: Send and receive XCP, the currency native to the protocol, or any user‐created currencies.
- **User‐Defined Assets**: Issue user‐defined currencies/assets and pay dividends on them.
- **Distributed Exchange**: Trade XCP, BTC or any asset with any other.
- **Feeds**: Broadcast information which may be used as the subject of a bet.
- **Betting, Financial Derivatives**: Make bets, or construct contracts for difference, on the numerical value of a feed.

Specifications
---------------

.. toctree::
   :maxdepth: 3

   CounterpartySpec

counterpartyd
---------------

.. toctree::
   :maxdepth: 3

   GettingStarted
   Usage 
   BuildingFromSource
   API


Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`

