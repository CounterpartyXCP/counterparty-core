CounterParty
========================================

Besides acting as a store of value, decentralized payment network and public ledger, Bitcoin itself allows
programs to embed arbitrary data into transactions. The value of this is immense, as it allows programs to be
developed that essentially "extend" new functionality on top of Bitcoin, inheriting Bitcoin's security model,
peer to peer processing system, and decentralized nature in the process.   

**CounterParty is an encoding scheme that provides decentralized financial instrument functionality
on top of the Bitcoin blockchain.** CounterParty is one of the first of these efforts that essentially "extends"
Bitcoin, and because it lives on top of the Bitcoin blockchain, CounterParty transactions are fully
peer-to-peer, decentralized, and leverage the strength and security of the Bitcoin network.

The CounterParty reference client (``counterpartyd``), as well as any other programs that implement the
CounterParty specification can perform the following types of operations:
  
- **Simple send**: Send and receive "CounterParty coin" (more commonly known as simply **XCP**), which is CounterPartys own
  derived currency unit, used for both trading and for feature "spam control" (via fees)
- **Smart Assets**: Create user defined currencies or assets and pay dividends on them
- **Distributed exchange**: Trade XCP for BTC, or XCP for any CounterParty user defined currency (UDC)  
- **Betting**
- **what else?**

Specifications
---------------

.. toctree::
   :maxdepth: 3

   CounterPartySpec

counterpartyd
---------------

.. toctree::
   :maxdepth: 3

   GettingStarted
   BuildingFromSource
   API


Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`

