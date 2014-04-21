Interacting with the API
=========================

.. warning::

    This API documentation is still in an early state. It contains errors, omissions, etc., and could change drastically at any time.
    

Overview
----------

``counterpartyd`` features a full-fledged JSON RPC 2.0-based API, which allows
third-party applications to perform functions on the Counterparty network
without having to deal with the low‐level details of the protocol such as
transaction encoding and state management.


Connecting to the API
----------------------

By default, ``counterpartyd`` will listen on port ``4000`` (if on mainnet) or port ``14000`` (on testnet) for API
requests. API requests are made via a HTTP POST request to ``/api/``, with JSON-encoded
data passed as the POST body. For more information on JSON RPC, please see the `JSON RPC 2.0 specification <http://www.jsonrpc.org/specification>`__.

.. _examples:

Python Example
^^^^^^^^^^^^^^^

.. code-block:: python

    import json
    import requests
    from requests.auth import HTTPBasicAuth
    
    url = "http://localhost:4000/api/"
    headers = {'content-type': 'application/json'}
    auth = HTTPBasicAuth('rpcuser', 'rpcpassword')
    
    #Fetch all balances for all assets for a specific address, using keyword-based arguments
    payload = {
      "method": "get_balances",
      "params": {"filters": {'field': 'address', 'op': '==', 'value': "14qqz8xpzzEtj6zLs3M1iASP7T4mj687yq"}},
      "jsonrpc": "2.0",
      "id": 0,
    }
    response = requests.post(
      url, data=json.dumps(payload), headers=headers, auth=auth).json()
    print("GET_BALANCES RESULT: ", response)

    #Fetch all balances for all assets for both of two addresses, using keyword-based arguments
    payload = {
      "method": "get_balances",
      "params": {"filters": [{'field': 'address', 'op': '==', 'value': "14qqz8xpzzEtj6zLs3M1iASP7T4mj687yq"},
                             {'field': 'address', 'op': '==', 'value': "1bLockjTFXuSENM8fGdfNUaWqiM4GPe7V"}],
                             "filterop": "or"},
      "jsonrpc": "2.0",
      "id": 0,
    }
    response = requests.post(
      url, data=json.dumps(payload), headers=headers, auth=auth).json()
    print("GET_BALANCES RESULT: ", response)

    #Get all burns between blocks 280537 and 280539 where greater than .2 BTC was burned, sorting by tx_hash (ascending order)
    #With this (and the rest of the examples below) we use positional arguments, instead of keyword-based arguments
    payload = {
      "method": "get_burns",
      "params": [{'field': 'burned', 'op': '>', 'value': 20000000}, True, 'tx_hash', 'asc', 280537, 280539],
      "jsonrpc": "2.0",
      "id": 0,
    }
    response = requests.post(
      url, data=json.dumps(payload), headers=headers, auth=auth).json()
    print("GET_BURNS RESULT: ", response)
    
    #Fetch all debits for > 2 XCP between blocks 280537 and 280539, sorting the results by quantity (descending order)
    payload = {
      "method": "get_debits",
      "params": [[{'field': 'asset', 'op': '==', 'value': "XCP"}, {'field': 'quantity', 'op': '>', 'value': 200000000}], 'quantity', 'desc'],
      "jsonrpc": "2.0",
      "id": 0,
    }
    response = requests.post(
      url, data=json.dumps(payload), headers=headers, auth=auth).json()
    print("GET_DEBITS RESULT: ", response)
    
    #Send 1 XCP (specified in satoshis) from one address to another (you must have the sending address in your wallet
    # and it will be returned as an unsigned OP_RETURN transaction in this example, as the multisig parameter is
    # specified as False
    payload = {
      "method": "create_send",
      "params": ["1CUdFmgK9trTNZHALfqGvd8d6nUZqH2AAf", "17rRm52PYGkntcJxD2yQF9jQqRS4S2nZ7E", "XCP", 100000000, false],
      "jsonrpc": "2.0",
      "id": 0,
    }
    response = requests.post(
      url, data=json.dumps(payload), headers=headers, auth=auth).json()
    print("\nDO_SEND RESULT: ", response)

PHP Example
^^^^^^^^^^^^

With PHP, you can connect and query ``counterpartyd`` using the `json-rpc2php <https://github.com/subutux/json-rpc2php>`__
library. Here's a simple example that will get you the asset balances for a specific address:

.. code-block:: php

    $client = new jsonRPCClient('http://localhost:4000/jsonrpc/', array('username' => 'myusername', 'password' => 'mypass'));
    $addr = '15vA2MJ4ESG3Rt1PVQ79D1LFMBBNtcSz1f'; // BTC/XCP address you want to query
    $res = $client->get_balances(array('field' => 'address', 'op' => '==', 'value' => $addr));



Terms & Conventions
---------------------

.. _assets:

assets
^^^^^^^^^

Everywhere in the API an asset is referenced as an uppercase alphabetic (base
26) string name of the asset, of at least 4 characters in length and not starting with 'A', or as 'BTC' or 'XCP' as appropriate. Examples are:

- "BTC"
- "XCP"
- "FOOBAR"

.. _quantitys:

Quantities & balances
^^^^^^^^^^^^^^^^^^^^^^

Anywhere where an quantity is specified, it is specified in **satoshis** (if a divisible asset), or as whole numbers
(if an indivisible asset). To convert satoshis to floating-point, simply cast to float and divide by 100,000,000.

Examples:

- 4381030000 = 43.8103 (if divisible asset)
- 4381030000 = 4381030000 (if indivisible asset) 

**NOTE:** XCP and BTC themselves are divisible assets, and thus are listed in satoshis.

.. _ratios:

floats
^^^^^^^^^^^^^^^^^^^^

Floats are are ratios or floating point values with six decimal places of precision, used in bets, dividends and callbacks.

.. _filtering:

Filtering Read API results
^^^^^^^^^^^^^^^^^^^^^^^^^^

The Counterparty API aims to be as simple and flexible as possible. To this end, it includes a straightforward
way to filter the results of most :ref:`Read API functions <read_api>` to get the data you want, and only that.

For each Read API function that supports it, a ``filters`` parameter exists. To apply a filter to a specific data field,
specify an object (e.g. dict in Python) as this parameter, with the following members:

- field: The field to filter on. Must be a valid field in the type of object being returned
- op: The comparison operation to perform. One of: ``"=="``, ``"!="``, ``">"``, ``"<"``, ``">="``, ``"<="``
- value: The value that the field will be compared against. Must be the same data type as the field is
  (e.g. if the field is a string, the value must be a string too)

If you want to filter by multiple fields, then you can specify a list of filter objects. To this end, API functions
that take ``filters`` also take a ``filterop`` parameter, which determines how the filters are combined when multiple
filters are specified. It defaults to ``"and"``, meaning that filters are ANDed togeher (and that any match
must satisfy all of them). You can also specify ``"or"`` as an alternative setting, which would mean that
filters are ORed together, and that any match must satisfy only one of them.

To disable filtering, you can just not specify the filter argument (if using keyword-based arguments), or,
if using positional arguments, just pass ``null`` or ``[]`` (empty list) for the parameter.

For examples of filtering in-use, please see the :ref:`API code examples <examples>`.

NOTE: Note that with strings being compared, operators like ``>=`` do a lexigraphic string comparison (which
compares, letter to letter, based on the ASCII ordering for individual characters. For more information on
the specific comparison logic used, please see `this page <http://docs.python.org/3/library/stdtypes.html#comparisons>`__.

.. _encoding_param:

The ``encoding`` Parameter of ``create_`` Calls 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

All ``create_`` API calls return an *unsigned raw transaction string*, hex encoded (i.e. the same format that ``bitcoind`` returns
with its raw transaction API calls).

The exact form and format of this unsigned raw transaction string is specified via the ``encoding`` and ``pubkey`` parameters on each ``create_``
API call:

- To return the transaction as an **OP_RETURN** transaction, specify ``opreturn`` for the ``encoding`` parameter.
  Note that as of ``bitcoind`` 0.9.0, not all Counterparty transactions are possible with OP_RETURN, due to the 40
  byte limit imposed by the ``bitcoind`` client in order for the transaction to be relayed on mainnet.
- To return the transaction as a **multisig** transaction, specify ``multisig`` for the ``encoding`` parameter.
    
    - If the source address is in the local ``bitcoind`` ``wallet.dat``. ``pubkey`` can be left as ``null``.
    - If the source address is *not* in the local ``bitcoind`` ``wallet.dat``, ``pubkey`` should be set to the hex-encoded
      public key.

- To return the Counterparty transaction encoded into arbitrary address outputs (i.e. pubkeyhash encoding), specify
  ``pubkeyhash`` for the ``encoding`` parameter. ``pubkey`` is also required to be set (as above, with ``multisig`` encoding)
  if the source address is not contained in the local ``bitcoind`` ``wallet.dat``. Note that this method is **not** recommended
  as a first-resort, as it pollutes the UTXO set.

With any of the above settings, as the *unsigned* raw transaction is returned from the ``create_`` API call itself, you
then have two approaches with respect to broadcasting the transaction on the network:

- If the private key you need to sign the raw transaction is in the local ``bitcoind`` ``wallet.dat``, you can simply call the
  ``transmit`` API call and pass it to the raw unsigned transaction string.
- If the private key you need to sign the raw transaction is *not* in the local ``bitcoind`` ``wallet.dat``, you must first sign
  the transaction yourself before calling ``transmit``. You must then pass the resultant signed
  hex-encoded transaction to ``transmit`` when you do call it, and specify ``is_signed`` as ``true``.


.. _read_api:

Read API Function Reference
------------------------------------

.. _get_balances:

get_balances
^^^^^^^^^^^^^^

.. py:function:: get_balances(filters=[], order_by=null, order_dir=null, filterop="and")

   Gets the current address balances, optionally filtered by an address and/or asset ID. This list does not
   include any BTC balances.

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param string order_by: If sorted results are desired, specify the name of a :ref:`balance object <balance-object>` attribute to order the results by (e.g. ``quantity``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.
   :return: A list of one or more :ref:`balance objects <balance-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_bets:

get_bets
^^^^^^^^^^^^^^

.. py:function:: get_bets(filters=[], is_valid=true, order_by=null, order_dir=null, start_block=null, end_block=null, filterop="and")

   Gets a listing of bets.

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid records. Set to ``false`` to return all records (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of a :ref:`bet object <bet-object>` attribute to order the results by (e.g. ``wager_quantity``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :param string filterop: Specifies how multiple filter settings are combined. Defaults to ``"and"``, but ``"or"`` can be specified as well. See :ref:`Filtering Read API results <filtering>` for more information.
   :return: A list of one or more :ref:`bet objects <bet-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_bet_matches:

get_bet_matches
^^^^^^^^^^^^^^^^^^^

.. py:function:: get_bet_matches(filters=[], is_settled=true, order_by=null, order_dir=null, start_block=null, end_block=null, filterop="and")

   Gets a listing of order matches.

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_settled: Set to ``true`` to only return settled bet match records. Set to ``false`` to return all records (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of a :ref:`bet match object <bet-match-object>` attribute to order the results by (e.g. ``deadline``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :param string filterop: Specifies how multiple filter settings are combined. Defaults to ``"and"``, but ``"or"`` can be specified as well. See :ref:`Filtering Read API results <filtering>` for more information.
   :return: A list of one or more :ref:`bet match objects <bet-match-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_broadcasts:

get_broadcasts
^^^^^^^^^^^^^^

.. py:function:: get_broadcasts(filters=[], is_valid=true, order_by=null, order_dir=null, start_block=null, end_block=null, filterop="and")

   Gets a listing of broadcasts.

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid records. Set to ``false`` to return all records (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of a :ref:`broadcast object <broadcast-object>` attribute to order the results by (e.g. ``fee_multiplier``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :param string filterop: Specifies how multiple filter settings are combined. Defaults to ``"and"``, but ``"or"`` can be specified as well. See :ref:`Filtering Read API results <filtering>` for more information.
   :return: A list of one or more :ref:`broadcast objects <broadcast-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_btcpays:

get_btcpays
^^^^^^^^^^^^^^

.. py:function:: get_btcpays(filters=[], is_valid=true, order_by=null, order_dir=null, start_block=null, end_block=null, filterop="and")

   Gets a listing of BTCPay records.

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid records. Set to ``false`` to return all records (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of a :ref:`BTCPay object <btcpay-object>` attribute to order the results by (e.g. ``block_index``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :param string filterop: Specifies how multiple filter settings are combined. Defaults to ``"and"``, but ``"or"`` can be specified as well. See :ref:`Filtering Read API results <filtering>` for more information.
   :return: A list of one or more :ref:`BTCPay objects <btcpay-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_burns:

get_burns
^^^^^^^^^^^^^^

.. py:function:: get_burns(filters=[], is_valid=true, order_by=null, order_dir=null, start_block=null, end_block=null, filterop="and")

   Gets a listing of burns.

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid records. Set to ``false`` to return all records (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of a :ref:`burn object <burn-object>` attribute to order the results by (e.g. ``tx_hash``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :param string filterop: Specifies how multiple filter settings are combined. Defaults to ``"and"``, but ``"or"`` can be specified as well. See :ref:`Filtering Read API results <filtering>` for more information.
   :return: A list of one or more :ref:`burn objects <burn-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_callbacks:

get_callbacks
^^^^^^^^^^^^^^

.. py:function:: get_callbacks(filters=[], is_valid=true, order_by=null, order_dir=null, start_block=null, end_block=null, filterop="and")

   Gets a listing of instances of an asset being called back (either wholly or partially).

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid records. Set to ``false`` to return all records (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of a :ref:`cancel object <cancel-object>` attribute to order the results by (e.g. ``source``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :param string filterop: Specifies how multiple filter settings are combined. Defaults to ``"and"``, but ``"or"`` can be specified as well. See :ref:`Filtering Read API results <filtering>` for more information.
   :return: A list of one or more :ref:`callback objects <callback-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_cancels:

get_cancels
^^^^^^^^^^^^^^

.. py:function:: get_cancels(filters=[], is_valid=true, order_by=null, order_dir=null, start_block=null, end_block=null, filterop="and")

   Gets a listing of canceled orders or bets.

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid records. Set to ``false`` to return all records (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of a :ref:`cancel object <cancel-object>` attribute to order the results by (e.g. ``source``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :param string filterop: Specifies how multiple filter settings are combined. Defaults to ``"and"``, but ``"or"`` can be specified as well. See :ref:`Filtering Read API results <filtering>` for more information.
   :return: A list of one or more :ref:`cancel objects <cancel-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_credits:

get_credits
^^^^^^^^^^^^^^

.. py:function:: get_credits(filters=[], order_by=null, order_dir=null, start_block=null, end_block=null, filterop="and")

   Gets a sorted history of address credits, optionally filtered to an address and/or asset. This list does not
   include any BTC credits.

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param string order_by: If sorted results are desired, specify the name of a :ref:`debit/credit object <debit-credit-object>` attribute to order the results by (e.g. ``tx_hash``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :param string filterop: Specifies how multiple filter settings are combined. Defaults to ``"and"``, but ``"or"`` can be specified as well. See :ref:`Filtering Read API results <filtering>` for more information.
   :return: A list of one or more :ref:`debit/credit objects <debit-credit-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_debits:

get_debits
^^^^^^^^^^^^^^

.. py:function:: get_debits(filters=[], order_by=null, order_dir=null, start_block=null, end_block=null, filterop="and")

   Gets a sorted history of address debits, optionally filtered to an address and/or asset. This list does not
   include any BTC debits.

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param string order_by: If sorted results are desired, specify the name of a :ref:`debit/credit object <debit-credit-object>` attribute to order the results by (e.g. ``tx_hash``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :param string filterop: Specifies how multiple filter settings are combined. Defaults to ``"and"``, but ``"or"`` can be specified as well. See :ref:`Filtering Read API results <filtering>` for more information.
   :return: A list of one or more :ref:`debit/credit objects <debit-credit-object>` if any matching records were found, otherwise ``[]`` (empty list).
   

.. _get_dividends:

get_dividends
^^^^^^^^^^^^^^

.. py:function:: get_dividends(filters=[], is_valid=true, order_by=null, order_dir=null, start_block=null, end_block=null, filterop="and")

   Gets a listing of dividends.

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid records. Set to ``false`` to return all records (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of a :ref:`dividend object <dividend-object>` attribute to order the results by (e.g. ``quantity_per_unit``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :param string filterop: Specifies how multiple filter settings are combined. Defaults to ``"and"``, but ``"or"`` can be specified as well. See :ref:`Filtering Read API results <filtering>` for more information.
   :return: A list of one or more :ref:`dividend objects <dividend-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_issuances:

get_issuances
^^^^^^^^^^^^^^

.. py:function:: get_issuances(filters=[], is_valid=true, order_by=null, order_dir=null, start_block=null, end_block=null, filterop="and")

   Gets a listing of asset issuances.

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid records. Set to ``false`` to return all records (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of an :ref:`issuance object <issuance-object>` attribute to order the results by (e.g. ``transfer``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :param string filterop: Specifies how multiple filter settings are combined. Defaults to ``"and"``, but ``"or"`` can be specified as well. See :ref:`Filtering Read API results <filtering>` for more information.
   :return: A list of one or more :ref:`issuance objects <issuance-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_orders:

get_orders
^^^^^^^^^^^^^^

.. py:function:: get_orders(filters=[], is_valid=true, show_empty=true, show_expired=true, order_by=null, order_dir=null, start_block=null, end_block=null, filterop="and")

   Gets a listing of orders.

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid records. Set to ``false`` to return all records (including invalid attempts).
   :param boolean show_empty: Set to ``false`` to not include empty orders in the results (i.e. where give remaining is zero).
   :param boolean show_expired: Set to ``false`` to not include expired orders in the results.
   :param string order_by: If sorted results are desired, specify the name of an :ref:`order object <order-object>` attribute to order the results by (e.g. ``get_asset``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :param string filterop: Specifies how multiple filter settings are combined. Defaults to ``"and"``, but ``"or"`` can be specified as well. See :ref:`Filtering Read API results <filtering>` for more information.
   :return: A list of one or more :ref:`order objects <order-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_order_matches:

get_order_matches
^^^^^^^^^^^^^^^^^^^

.. py:function:: get_order_matches(filters=[], post_filter_status=null, is_mine=false, order_by=null, order_dir=null, start_block=null, end_block=null, filterop="and")

   Gets a listing of order matches.

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean post_filter_status: Set to filter by status after filtering by filters (useful if filters has a number of addresses and filterop='or'). This parameter is set to either ``completed`` (to return completed matches only), ``pending`` (to return matches requiring BTC payment only) or ``null`` to return all records (including invalid attempts).
   :param boolean is_mine: Set to ``true`` to include results where either the ``tx0_address`` or ``tx1_address`` exist in the linked ``bitcoind`` wallet.
   :param string order_by: If sorted results are desired, specify the name of an :ref:`order match object <order-match-object>` attribute to order the results by (e.g. ``forward_asset``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :param string filterop: Specifies how multiple filter settings are combined. Defaults to ``"and"``, but ``"or"`` can be specified as well. See :ref:`Filtering Read API results <filtering>` for more information.
   :return: A list of one or more :ref:`order match objects <order-match-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_sends:

get_sends
^^^^^^^^^^^^^^

.. py:function:: get_sends(filters=[], is_valid=true, order_by=null, order_dir=null, start_block=null, end_block=null, filterop="and")

   Gets an optionally filtered listing of past sends.

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid records. Set to ``false`` to return all records (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of a :ref:`send object <send-object>` attribute to order the results by (e.g. ``asset``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :param string filterop: Specifies how multiple filter settings are combined. Defaults to ``"and"``, but ``"or"`` can be specified as well. See :ref:`Filtering Read API results <filtering>` for more information.
   :return: A list of one or more :ref:`send objects <send-object>` if any matching records were found, otherwise ``[]`` (empty list).

.. get_bet_expirations:

get_bet_expirations
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. py:function:: get_bet_expirations(filters=[], order_by=null, order_dir=null, filterop="and")

   Gets an optionally filtered listing of bet expirations.

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param string order_by: If sorted results are desired, specify the name of a :ref:`bet expiration objects <bet-expiration-object>` attribute to order the results by (e.g. ``quantity``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.
   :return: A list of one or more :ref:`bet expiration objects <bet-expiration-object>` if any matching records were found, otherwise ``[]`` (empty list).

.. get_order_expirations:

get_order_expirations
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. py:function:: get_order_expirations(filters=[], order_by=null, order_dir=null, filterop="and")

   Gets an optionally filtered listing of order expirations.

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param string order_by: If sorted results are desired, specify the name of a :ref:`order expiration objects <order-expiration-object>` attribute to order the results by (e.g. ``quantity``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.
   :return: A list of one or more :ref:`order expiration objects <order-expiration-object>` if any matching records were found, otherwise ``[]`` (empty list).

.. get_bet_match_expirations:

get_bet_match_expirations
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. py:function:: get_bet_match_expirations(filters=[], order_by=null, order_dir=null, filterop="and")

   Gets an optionally filtered listing of bet match expirations.

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param string order_by: If sorted results are desired, specify the name of a :ref:`bet match expiration objects <bet-match-expiration-object>` attribute to order the results by (e.g. ``quantity``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.
   :return: A list of one or more :ref:`bet match expiration objects <bet-match-expiration-object>` if any matching records were found, otherwise ``[]`` (empty list).

.. get_order_match_expirations:

get_order_match_expirations
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. py:function:: get_order_match_expirations(filters=[], order_by=null, order_dir=null, filterop="and")

   Gets an optionally filtered listing of order match expirations.

   :param list/dict filters: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param string order_by: If sorted results are desired, specify the name of a :ref:`order match expiration objects <order-match-expiration-object>` attribute to order the results by (e.g. ``quantity``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.
   :return: A list of one or more :ref:`order match expiration objects <order-match-expiration-object>` if any matching records were found, otherwise ``[]`` (empty list).

.. _get_asset_info:

get_asset_info
^^^^^^^^^^^^^^

.. py:function:: get_asset_info(assets)

   Gets information on an issued asset.

   :param string assets: A list of one or more :ref:`asset <assets>` for which to retrieve information.
   :return: ``null`` if the asset was not found. Otherwise, a list of one or more objects, each one with the following parameters:

     - **asset** (*string*): The :ref:`name <assets>` of the asset itself 
     - **owner** (*string*): The address that currently owns the asset (i.e. has issuance rights to it) 
     - **divisible** (*boolean*): Whether the asset is divisible or not
     - **locked** (*boolean*): Whether the asset is locked (future issuances prohibited)
     - **total_issued** (*integer*): The :ref:`quantity <quantitys>` of the asset issued, in total
     - **callable** (*boolean*): If the asset is callable or not
     - **call_date** (*integer*): The call date, as an epoch timestamp
     - **call_price** (*float*): The call price
     - **description** (*string*): The asset's current description
     - **issuer** (*string*): The asset's original owner (i.e. issuer)

.. _get_messages:

get_messages
^^^^^^^^^^^^^^

.. py:function:: get_messages(block_index)

   Return message feed activity for the specified block index. The message feed essentially tracks all counterpartyd
   database actions and allows for lower-level state tracking for applications that hook into it.
   
   :param integer block_index: The block index for which to retrieve activity. 
   :return: A list of one or more :ref:`message <message-object>` if there was any activity in the block, otherwise ``[]`` (empty list).

.. _get_messages_by_index:

get_messages_by_index
^^^^^^^^^^^^^^^^^^^^^^

.. py:function:: get_messages_by_index(message_indexes)

   Return the message feed messages whose ``message_index`` values are contained in the specified list of message indexes.
   
   :param list message_indexes: An array of one or more ``message_index`` values for which the cooresponding message feed entries are desired. 
   :return: A list containing a :ref:`message <message-object>` for each message found in the specified ``message_indexes`` list. If none were found, ``[]`` (empty list) is returned.

.. _get_xcp_supply:

get_xcp_supply
^^^^^^^^^^^^^^^

.. py:function:: get_xcp_supply(asset)

   Gets the current total quantity of XCP in existance (i.e. quantity created via proof-of-burn, minus quantity
   destroyed via asset issuances, etc).
   
   :return:  The :ref:`quantity <quantitys>` of XCP currently in existance.
   

.. _get_block_info:

get_block_info
^^^^^^^^^^^^^^

.. py:function:: get_block_info(block_index)

   Gets some basic information on a specific block.
   
   :param integer block_index: The block index for which to retrieve information.
   :return: If the block was found, an object with the following parameters:
     
     - **block_index** (*integer*): The block index (i.e. block height). Should match what was specified for the *block_index* input parameter). 
     - **block_hash** (*string*): The block hash identifier
     - **block_time** (*integer*): A UNIX timestamp of when the block was processed by the network 

.. _get_running_info:

get_running_info
^^^^^^^^^^^^^^

.. py:function:: get_running_info()

   Gets some operational parameters for counterpartyd.
   
   :return: An object with the following parameters:
   
     - **db_caught_up** (*boolean*): ``true`` if counterpartyd block processing is caught up with the Bitcoin blockchain, ``false`` otherwise.
     - **bitcoin_block_count** (**integer**): The block height on the Bitcoin network (may not necessarily be the same as ``last_block``, if ``counterpartyd`` is catching up)
     - **last_block** (*integer*): The index (height) of the last block processed by ``counterpartyd``
     - **counterpartyd_version** (*float*): The counterpartyd program version, expressed as a float, such as 0.5
     - **last_message_index** (*integer*): The index (ID) of the last message in the ``counterpartyd`` message feed
     - **running_testnet** (*boolean*): ``true`` if counterpartyd is configured for testnet, ``false`` if configured on mainnet.
     - **db_version_major** (*integer*): The major version of the current counterpartyd database
     - **db_version_minor** (*integer*): The minor version of the current counterpartyd database


.. _action_api:

Action/Write API Function Reference
-----------------------------------

.. _transmit:

transmit
^^^^^^^^^^^^^^

.. py:function:: transmit(tx_hex, is_signed=false)

   Broadcast a transaction created with the Action/Write API onto the Bitcoin network.

   :param string tx_hex: A hex-encoded raw transaction (which was created via one of the ``create_`` calls below).
   :param boolean is_signed: If ``false`` is specified here, the ``tx_hex`` string passed will be signed with a key
    in the local ``bitcoind``'s ``wallet.dat`` before being broadcast. If ``true`` is specified, the ``tx_hex`` specified
    is already signed and it will simply be broadcast.  
   :return: Returns the created transaction's id on the Bitcoin network, or an error if the transaction is invalid for any reason.


.. _create_bet:

create_bet
^^^^^^^^^^^^^^

.. py:function:: create_bet(source, feed_address, bet_type, deadline, wager, counterwager, target_value=0.0, leverage=5040, encoding='multisig', pubkey=null)

   Issue a bet against a feed.

   :param string source: The address that will make the bet.
   :param string feed_address: The address that host the feed to be bet on.
   :param integer bet_type: 0 for Bullish CFD, 1 for Bearish CFD, 2 for Equal, 3 for NotEqual.
   :param integer deadline: The time at which the bet should be decided/settled, in Unix time.
   :param integer wager: The :ref:`quantity <quantitys>` of XCP to wager.
   :param integer counterwager: The minimum :ref:`quantity <quantitys>` of XCP to be wagered against, for the bets to match.
   :param float target_value: Target value for Equal/NotEqual bet
   :param integer leverage: Leverage, as a fraction of 5040
   :param string encoding: The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
   :param string pubkey: The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
   :return: The unsigned hex-encoded transaction in either OP_RETURN or multisig format. See :ref:`this section <multisig_param>`.


.. _create_broadcast:

create_broadcast
^^^^^^^^^^^^^^

.. py:function:: create_broadcast(source, fee_multiplier, text, value=0, encoding='multisig', pubkey=null)

   Broadcast textual and numerical information to the network.

   :param string source: The address that will be sending (must have the necessary quantity of the specified asset).
   :param float fee_multiplier: How much of every bet on this feed should go to its operator; a fraction of 1, (i.e. .05 is five percent).
   :param string text: The textual part of the broadcast.
   :param integer timestamp: The timestamp of the broadcast, in Unix time.
   :param float value: Numerical value of the broadcast.
   :param string encoding: The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
   :param string pubkey: The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
   :return: The unsigned hex-encoded transaction in either OP_RETURN or multisig format. See :ref:`this section <multisig_param>`.


.. _create_btcpay:

create_btcpay
^^^^^^^^^^^^^^

.. py:function:: create_btcpay(order_match_id, encoding='multisig', pubkey=null)

   Create and (optionally) broadcast a BTCpay message, to settle an Order Match for which you owe BTC. 

   :param string order_match_id: The concatenation of the hashes of the two transactions which compose the order match.
   :param string encoding: The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
   :param string pubkey: The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
   :return: The unsigned hex-encoded transaction in either OP_RETURN or multisig format. See :ref:`this section <multisig_param>`.


.. _create_burn:

create_burn
^^^^^^^^^^^^^^

.. py:function:: create_burn(source, quantity, encoding='multisig', pubkey=null)

   Burn a given quantity of BTC for XCP (**only possible between blocks 278310 and 283810**).

   :param string source: The address with the BTC to burn.
   :param integer quantity: The :ref:`quantity <quantitys>` of BTC to burn (1 BTC maximum burn per address).
   :param string encoding: The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
   :param string pubkey: The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
   :return: The unsigned hex-encoded transaction in either OP_RETURN or multisig format. See :ref:`this section <multisig_param>`.


.. _create_callback:

create_callback
^^^^^^^^^^^^^^^^^

.. py:function:: create_callback(offer_hash, encoding='multisig', pubkey=null)

   Make a call on a callable asset (where some whole or part of the asset is returned to the issuer, on or after the asset's call date).

   :param string source: The callback source address. Must be the same address as the specified asset's owner.
   :param float fraction: A floating point number greater than zero but less than or equal to 1, where 0% is for a callback of 0%
    of the balance of each of the asset's holders, and 1 would be for a callback of 100%). For example, ``0.56`` would be 56%.
    Each holder of the called asset will be paid the call price for the asset, times the number of units of that asset that were called back from them.
   :param string encoding: The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
   :param string pubkey: The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
   :return: The unsigned hex-encoded transaction in either OP_RETURN or multisig format. See :ref:`this section <multisig_param>`.


.. _create_cancel:

create_cancel
^^^^^^^^^^^^^^

.. py:function:: create_cancel(offer_hash, encoding='multisig', pubkey=null)

   Cancel an open order or bet you created.

   :param string offer_hash: The transaction hash of the order or bet.
   :param string encoding: The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
   :param string pubkey: The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
   :return: The unsigned hex-encoded transaction in either OP_RETURN or multisig format. See :ref:`this section <multisig_param>`.


.. _create_dividend:

create_dividend
^^^^^^^^^^^^^^^^^

.. py:function:: create_dividend(source, quantity_per_unit, asset, dividend_asset, encoding='multisig', pubkey=null)

   Issue a dividend on a specific user defined asset.

   :param string source: The address that will be issuing the dividend (must have the ownership of the asset which the dividend is being issued on).
   :param string asset: The :ref:`asset <assets>` that the dividends are being rewarded on.
   :param string dividend_asset: The :ref:`asset <assets>` that the dividends are paid in.
   :param integer quantity_per_unit: The :ref:`quantity <quantitys>` of XCP rewarded per whole unit of the asset.
   :param string encoding: The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
   :param string pubkey: The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
   :return: The unsigned hex-encoded transaction in either OP_RETURN or multisig format. See :ref:`this section <multisig_param>`.


.. _create_issuance:

create_issuance
^^^^^^^^^^^^^^^^^

.. py:function:: create_issuance(source, asset, quantity, divisible, description, callable=false, call_date=null, call_price=null, transfer_destination=null, lock=false, encoding='multisig', pubkey=null):

   Issue a new asset, issue more of an existing asset, lock an asset, or transfer the ownership of an asset (note that
   you can only do one of these operations in a given create_issuance call).

   :param string source: The address that will be issuing or transfering the asset.
   :param integer quantity: The :ref:`quantity <quantitys>` of the asset to issue (set to 0 if *transferring* an asset).
   :param string asset: The :ref:`asset <assets>` to issue or transfer.
   :param boolean divisible: Whether this asset is divisible or not (if a transfer, this value must match the value
    specified when the asset was originally issued).
   :param boolean callable: Whether the asset is callable or not.
   :param integer call_date: The timestamp at which the asset may be called back, in Unix time. Only valid for callable assets.
   :param float call_price: The :ref:`price <floats>` per unit XCP at which the asset may be called back, on or after the specified call_date. Only valid for callable assets.
   :param string description: A textual description for the asset. 52 bytes max.
   :param string transfer_destination: The address to receive the asset (only used when *transferring* assets -- leave set to ``null`` if issuing an asset).
   :param boolean lock: Set to ``true`` if this asset should be locked with this API call. Only valid if the asset is not
    already locked. To keep as-is, set this to ``false``, or simply do not specify it. 
   :param string encoding: The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
   :param string pubkey: The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
   :return: The unsigned hex-encoded transaction in either OP_RETURN or multisig format. See :ref:`this section <multisig_param>`.


.. _create_order:

create_order
^^^^^^^^^^^^^^

.. py:function:: create_order(source, give_asset, give_quantity, get_asset, get_quantity, expiration, fee_required=0, fee_provided=0, encoding='multisig', pubkey=null)

   Issue an order request.

   :param string source: The address that will be issuing the order request (must have the necessary quantity of the specified asset to give).
   :param integer give_quantity: The :ref:`quantity <quantitys>` of the asset to give.
   :param string give_asset: The :ref:`asset <assets>` to give.
   :param integer get_quantity: The :ref:`quantity <quantitys>` of the asset requested in return.
   :param string get_asset: The :ref:`asset <assets>` requested in return.
   :param integer expiration: The number of blocks for which the order should be valid.
   :param integer fee_required: The miners' fee required to be paid by orders for them to match this one; in BTC;
    required only if buying BTC (may be zero, though). If not specified or set to ``null``, this defaults to 1% of the BTC desired for purchase.
   :param integer fee_provided: The miners' fee provided; in BTC; required only if selling BTC (should not be lower than
    is required for acceptance in a block).  If not specified or set to ``null``, this defaults to 1% of the BTC for sale. 
   :param string encoding: The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
   :param string pubkey: The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
   :return: The unsigned hex-encoded transaction in either OP_RETURN or multisig format. See :ref:`this section <multisig_param>`.


.. _create_send:

create_send
^^^^^^^^^^^^^^

.. py:function:: create_send(source, destination, asset, quantity, encoding='multisig', pubkey=null)

   Send XCP or a user defined asset.

   :param string source: The address that will be sending (must have the necessary quantity of the specified asset).
   :param string destination: The address to receive the asset.
   :param integer quantity: The :ref:`quantity <quantitys>` of the asset to send.
   :param string asset: The :ref:`asset <assets>` to send.
   :param string encoding: The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
   :param string pubkey: The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
   :return: The unsigned hex-encoded transaction in either OP_RETURN or multisig format. See :ref:`this section <multisig_param>`.

   
Objects
----------

The API calls documented can return any one of these objects.

.. _balance-object:

Balance Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes a balance that is associated to a specific address:

* **address** (*string*): The address that has the balance
* **asset** (*string*): The ID of the :ref:`asset <assets>` in which the balance is specified
* **quantity** (*integer*): The :ref:`balance <quantitys>` of the specified asset at this address


.. _bet-object:

Bet Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes a specific bet:

* **tx_index** (*integer*): The transaction index
* **tx_hash** (*string*): The transaction hash
* **block_index** (*integer*): The block index (block number in the block chain)
* **source** (*string*): The address that made the bet
* **feed_address** (*string*): The address with the feed that the bet is to be made on
* **bet_type** (*integer*): 0 for Bullish CFD, 1 for Bearish CFD, 2 for Equal, 3 for Not Equal
* **deadline** (*integer*): The timestamp at which the bet should be decided/settled, in Unix time.
* **wager_quantity** (*integer*): The :ref:`quantity <quantitys>` of XCP to wager
* **counterwager_quantity** (*integer*): The minimum :ref:`quantity <quantitys>` of XCP to be wagered by the user to bet against the bet issuer, if the other party were to accept the whole thing
* **wager_remaining** (*integer*): The quantity of XCP wagered that is remaining to bet on
* **odds** (*float*): 
* **target_value** (*float*): Target value for Equal/NotEqual bet
* **leverage** (*integer*): Leverage, as a fraction of 5040
* **expiration** (*integer*): The number of blocks for which the bet should be valid
* **fee_multiplier** (*integer*): 
* **validity** (*string*): Set to "valid" if a valid bet. Any other setting signifies an invalid/improper bet


.. _bet-match-object:

Bet Match Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes a specific occurance of two bets being matched (either partially, or fully):

* **tx0_index** (*integer*): The Bitcoin transaction index of the initial bet
* **tx0_hash** (*string*): The Bitcoin transaction hash of the initial bet
* **tx0_block_index** (*integer*): The Bitcoin block index of the initial bet
* **tx0_expiration** (*integer*): The number of blocks over which the initial bet was valid
* **tx0_address** (*string*): The address that issued the initial bet
* **tx0_bet_type** (*string*): The type of the initial bet (0 for Bullish CFD, 1 for Bearish CFD, 2 for Equal, 3 for Not Equal)
* **tx1_index** (*integer*): The transaction index of the matching (counter) bet
* **tx1_hash** (*string*): The transaction hash of the matching bet
* **tx1_block_index** (*integer*): The block index of the matching bet
* **tx1_address** (*string*): The address that issued the matching bet
* **tx1_expiration** (*integer*): The number of blocks over which the matching bet was valid
* **tx1_bet_type** (*string*): The type of the counter bet (0 for Bullish CFD, 1 for Bearish CFD, 2 for Equal, 3 for Not Equal)
* **feed_address** (*string*): The address of the feed that the bets refer to
* **initial_value** (*integer*): 
* **deadline** (*integer*): The timestamp at which the bet match was made, in Unix time.
* **target_value** (*float*): Target value for Equal/NotEqual bet  
* **leverage** (*integer*): Leverage, as a fraction of 5040
* **forward_quantity** (*integer*): The :ref:`quantity <quantitys>` of XCP bet in the initial bet
* **backward_quantity** (*integer*): The :ref:`quantity <quantitys>` of XCP bet in the matching bet
* **fee_multiplier** (*integer*): 
* **validity** (*string*): Set to "valid" if a valid order match. Any other setting signifies an invalid/improper order match


.. _broadcast-object:

Broadcast Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes a specific occurance of a broadcast event (i.e. creating/extending a feed):

* **tx_index** (*integer*): The transaction index
* **tx_hash** (*string*): The transaction hash
* **block_index** (*integer*): The block index (block number in the block chain)
* **source** (*string*): The address that made the broadcast
* **timestamp** (*string*): The time the broadcast was made, in Unix time. 
* **value** (*float*): The numerical value of the broadcast
* **fee_multiplier** (*float*): How much of every bet on this feed should go to its operator; a fraction of 1, (i.e. .05 is five percent)
* **text** (*string*): The textual component of the broadcast
* **validity** (*string*): Set to "valid" if a valid broadcast. Any other setting signifies an invalid/improper broadcast


.. _btcpay-object:

BTCPay Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that matches a request to settle an Order Match for which BTC is owed:

* **tx_index** (*integer*): The transaction index
* **tx_hash** (*string*): The transaction hash
* **block_index** (*integer*): The block index (block number in the block chain)
* **source** (*string*):
* **order_match_id** (*string*):
* **validity** (*string*): Set to "valid" if valid


.. _burn-object:

Burn Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes an instance of a specific burn:

* **tx_index** (*integer*): The transaction index
* **tx_hash** (*string*): The transaction hash
* **block_index** (*integer*): The block index (block number in the block chain)
* **source** (*string*): The address the burn was performed from
* **burned** (*integer*): The :ref:`quantity <quantitys>` of BTC burned
* **earned** (*integer*): The :ref:`quantity <quantitys>` of XPC actually earned from the burn (takes into account any bonus quantitys, 1 BTC limitation, etc)
* **validity** (*string*): Set to "valid" if a valid burn. Any other setting signifies an invalid/improper burn


.. _cancel-object:

Cancel Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes a cancellation of a (previously) open order or bet:

* **tx_index** (*integer*): The transaction index
* **tx_hash** (*string*): The transaction hash
* **block_index** (*integer*): The block index (block number in the block chain)
* **source** (*string*): The address with the open order or bet that was cancelled
* **offer_hash** (*string*): The transaction hash of the order or bet cancelled
* **validity** (*string*): Set to "valid" if a valid burn. Any other setting signifies an invalid/improper burn


.. _debit-credit-object:

Debit/Credit Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes a account debit or credit:

* **tx_index** (*integer*): The transaction index
* **tx_hash** (*string*): The transaction hash
* **block_index** (*integer*): The block index (block number in the block chain)
* **address** (*string*): The address debited or credited
* **asset** (*string*): The :ref:`asset <assets>` debited or credited
* **quantity** (*integer*): The :ref:`quantity <quantitys>` of the specified asset debited or credited


.. _dividend-object:

Dividend Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes an issuance of dividends on a specific user defined asset:

* **tx_index** (*integer*): The transaction index
* **tx_hash** (*string*): The transaction hash
* **block_index** (*integer*): The block index (block number in the block chain)
* **source** (*string*): The address that issued the dividend
* **asset** (*string*): The :ref:`asset <assets>` that the dividends are being rewarded on 
* **quantity_per_unit** (*integer*): The :ref:`quantity <quantitys>` of XCP rewarded per whole unit of the asset
* **validity** (*string*): Set to "valid" if a valid burn. Any other setting signifies an invalid/improper burn


.. _issuance-object:

Issuance Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes a specific occurance of a user defined asset being issued, or re-issued:

* **tx_index** (*integer*): The transaction index
* **tx_hash** (*string*): The transaction hash
* **block_index** (*integer*): The block index (block number in the block chain)
* **asset** (*string*): The :ref:`asset <assets>` being issued, or re-issued
* **quantity** (*integer*): The :ref:`quantity <quantitys>` of the specified asset being issued
* **divisible** (*boolean*): Whether or not the asset is divisible (must agree with previous issuances of the asset, if there are any)
* **issuer** (*string*): 
* **transfer** (*boolean*): Whether or not this objects marks the transfer of ownership rights for the specified quantity of this asset
* **validity** (*string*): Set to "valid" if a valid issuance. Any other setting signifies an invalid/improper issuance


.. _order-object:

Order Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes a specific order:

* **tx_index** (*integer*): The transaction index
* **tx_hash** (*string*): The transaction hash
* **block_index** (*integer*): The block index (block number in the block chain)
* **source** (*string*): The address that made the order
* **give_asset** (*string*): The :ref:`asset <assets>` being offered
* **give_quantity** (*integer*): The :ref:`quantity <quantitys>` of the specified asset being offered
* **give_remaining** (*integer*): The :ref:`quantity <quantitys>` of the specified give asset remaining for the order
* **get_asset** (*string*): The :ref:`asset <assets>` desired in exchange
* **get_quantity** (*integer*): The :ref:`quantity <quantitys>` of the specified asset desired in exchange
* **get_remaining** (*integer*): The :ref:`quantity <quantitys>` of the specified get asset remaining for the order
* **price** (*float*): The given exchange rate (as an exchange ratio desired from the asset offered to the asset desired)
* **expiration** (*integer*): The number of blocks over which the order should be valid
* **fee_provided** (*integer*): The miners' fee provided; in BTC; required only if selling BTC (should not be lower than is required for acceptance in a block)
* **fee_required** (*integer*): The miners' fee required to be paid by orders for them to match this one; in BTC; required only if buying BTC (may be zero, though)


.. _order-match-object:

Order Match Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes a specific occurance of two orders being matched (either partially, or fully):

* **tx0_index** (*integer*): The Bitcoin transaction index of the first (earlier) order
* **tx0_hash** (*string*): The Bitcoin transaction hash of the first order
* **tx0_block_index** (*integer*): The Bitcoin block index of the first order
* **tx0_expiration** (*integer*): The number of blocks over which the first order was valid
* **tx0_address** (*string*): The address that issued the first (earlier) order
* **tx1_index** (*integer*): The transaction index of the second (matching) order
* **tx1_hash** (*string*): The transaction hash of the second order
* **tx1_block_index** (*integer*): The block index of the second order
* **tx1_address** (*string*): The address that issued the second order
* **tx1_expiration** (*integer*): The number of blocks over which the second order was valid
* **forward_asset** (*string*): The :ref:`asset <assets>` exchanged FROM the first order to the second order
* **forward_quantity** (*integer*): The :ref:`quantity <quantitys>` of the specified forward asset
* **backward_asset** (*string*): The :ref:`asset <assets>` exchanged FROM the second order to the first order
* **backward_quantity** (*integer*): The :ref:`quantity <quantitys>` of the specified backward asset
* **validity** (*string*): Set to "valid" if a valid order match. Any other setting signifies an invalid/improper order match


.. _send-object:

Send Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes a specific send (e.g. "simple send", of XCP, or a user defined asset):

* **tx_index** (*integer*): The transaction index
* **tx_hash** (*string*): The transaction hash
* **block_index** (*integer*): The block index (block number in the block chain)
* **source** (*string*): The source address of the send
* **destination** (*string*): The destination address of the send
* **asset** (*string*): The :ref:`asset <assets>` being sent
* **quantity** (*integer*): The :ref:`quantity <quantitys>` of the specified asset sent
* **validity** (*string*): Set to "valid" if a valid send. Any other setting signifies an invalid/improper send


.. _message-object:

Message Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes a specific event in the counterpartyd message feed (which can be used by 3rd party applications
to track state changes to the counterpartyd database on a block-by-block basis).

* **message_index** (*integer*): The message index (i.e. transaction index)
* **block_index** (*integer*): The block index (block number in the block chain) this event occurred on
* **category** (*string*): A string denoting the entity that the message relates to, e.g. "credits", "burns", "debits".
  The category matches the relevant table name in counterpartyd (see blocks.py for more info).
* **command** (*string*): The operation done to the table noted in **category**. This is either "insert", or "update". 
* **bindings** (*string*): A JSON-encoded object containing the message data. The properties in this object match the
  columns in the table referred to by **category**.

  
.. _callback-object:

Callback Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes a specific asset callback (i.e. the exercising of a call option on an asset owned by the source address).

* **tx_index** (*integer*): The transaction index
* **tx_hash** (*string*): The transaction hash
* **block_index** (*integer*): The block index (block number in the block chain)
* **source** (*string*): The source address of the call back (should be the current owner of the asset)
* **fraction** (*integer*): A floating point number greater than zero but less than or equal to 1, where 0% is for a callback of 0%
    of the balance of each of the asset's holders, and 1 would be for a callback of 100%). For example, ``0.56`` would be 56%.
    Each holder of the called asset will be paid the call price for the asset, times the number of units of that asset that were called back from them.
* **asset** (*string*): The :ref:`asset <assets>` being called back
* **validity** (*string*): Set to "valid" if a valid send. Any other setting signifies an invalid/improper send


.. _bet-expiration-object:

Bet Expiration Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes the expiration of a bet created by the source address.

* **bet_index** (*integer*): The transaction index of the bet expiring
* **bet_hash** (*string*): The transaction hash of the bet expiriing
* **block_index** (*integer*): The block index (block number in the block chain) when this expiration occurred
* **source** (*string*): The source address that created the bet


.. _order-expiration-object:

Order Expiration Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes the expiration of an order created by the source address.

* **order_index** (*integer*): The transaction index of the order expiring
* **order_hash** (*string*): The transaction hash of the order expiriing
* **block_index** (*integer*): The block index (block number in the block chain) when this expiration occurred
* **source** (*string*): The source address that created the order


.. _bet-match-expiration-object:

Bet Match Expiration Object
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

An object that describes the expiration of a bet match.

* **bet_match_id** (*integer*): The transaction index of the bet match ID (e.g. the concatenation of the tx0 and tx1 hashes)
* **tx0_address** (*string*): The tx0 (first) address for the bet match
* **tx1_address** (*string*): The tx1 (second) address for the bet match
* **block_index** (*integer*): The block index (block number in the block chain) when this expiration occurred


.. _order-match-expiration-object:

Order Match Expiration Object
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

An object that describes the expiration of an order match.

* **order_match_id** (*integer*): The transaction index of the order match ID (e.g. the concatenation of the tx0 and tx1 hashes)
* **tx0_address** (*string*): The tx0 (first) address for the order match
* **tx1_address** (*string*): The tx1 (second) address for the order match
* **block_index** (*integer*): The block index (block number in the block chain) when this expiration occurred
  
