Interacting with the API
=========================

.. warning::

    This API documentation is still in an early state. It contains errors, omissions, etc., and could change drastically at any time.
    

Overview
----------

``counterpartyd`` features a full-fledged JSON RPC-based API, which allows
third-party applications to perform functions on the Counterparty network
without having to deal with the low‐level details of the protocol such as
transaction encoding and state management.

Please see the scripts in the ``examples`` subdirectory.


Connecting to the API
----------------------

By default, ``counterpartyd`` will listen on port ``4000`` (if on mainnet) or port ``14000`` (on testnet) for API
requests. API requests are made via a HTTP POST request to ``/jsonrpc/``, with JSON-encoded
data passed as the POST body. For more information on JSON RPC, please see the `JSON RPC specification <http://json-rpc.org/wiki/specification>`__.

.. _examples:

Python Example
^^^^^^^^^^^^^^^

.. code-block:: python

    import json
    import requests
    from requests.auth import HTTPBasicAuth
    
    url = "http://localhost:4000/jsonrpc/"
    headers = {'content-type': 'application/json'}
    auth = HTTPBasicAuth('rpcuser', 'rpcpassword')
    
    #Fetch all balances for all assets for a specific address, using keyword-based arguments
    payload = {
      "method": "get_balances",
      "params": {"filters": {'field': 'address', 'op': '==', 'value': sourceaddr}},
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
    
    #Fetch all debits for > 2 XCP between blocks 280537 and 280539, sorting the results by amount (descending order)
    payload = {
      "method": "get_debits",
      "params": [[{'field': 'asset', 'op': '==', 'value': "XCP"}, {'field': 'amount', 'op': '>', 'value': 200000000}], 'amount', 'desc'],
      "jsonrpc": "2.0",
      "id": 0,
    }
    response = requests.post(
      url, data=json.dumps(payload), headers=headers, auth=auth).json()
    print("GET_DEBITS RESULT: ", response)
    
    #Get information for a specific address
    payload = {
      "method": "get_address",
      "params": ["1CUdFmgK9trTNZHALfqGvd8d6nUZqH2AAf"],
      "jsonrpc": "2.0",
      "id": 0,
    }
    response = requests.post(
      url, data=json.dumps(payload), headers=headers, auth=auth).json()
    print("\nGET ADDRESS RESULT: ", response)
    
    #Send 1 XCP (specified in satoshis) from one address to another (you must have the sending address in your wallet)
    payload = {
      "method": "do_send",
      "params": ["1CUdFmgK9trTNZHALfqGvd8d6nUZqH2AAf", "17rRm52PYGkntcJxD2yQF9jQqRS4S2nZ7E", 100000000, "XCP"],
      "jsonrpc": "2.0",
      "id": 0,
    }
    response = requests.post(
      url, data=json.dumps(payload), headers=headers, auth=auth).json()
    print("\nDO_SEND RESULT: ", response)



Terms & Conventions
---------------------

.. _assets:

assets
^^^^^^^^^

Everywhere in the API an asset is referenced as an uppercase alphabetic (base
26) string name of the asset, of at least 4 characters in length, or as 'BTC' or 'XCP' as appropriate. Examples are:

- "BTC"
- "XCP"
- "FOOBAR"

.. _amounts:

amounts & balances
^^^^^^^^^^^^^^^^^^^^

Anywhere where an amount is specified, it is specified in **satoshis** (if a divisible asset), or as whole numbers
(if an indivisible asset). To convert satoshis to floating-point, simply cast to float and divide by 100,000,000.

Examples:

- 4381030000 = 43.8103 (if divisible asset)
- 4381030000 = 4381030000 (if indivisible asset) 

**NOTE:** XCP and BTC themselves are divisible assets, and thus are listed in satoshis.

.. _filtering:

Filtering Read API results
^^^^^^^^^^^^^^^^^^^^^^^^^^

The Counterparty API aims to be as simple and flexible as possible. To this end, it includes a straightforward
way to filter the results of most :ref:`Read API functions <read_api>` to get the data you want, and only that.

For each Read API function that supports it, a ``filter`` parameter exists. To apply a filter to a specific data field,
specify an object (e.g. dict in Python) as this parameter, with the following members:

- field: The field to filter on. Must be a valid field in the type of object being returned
- op: The comparison operation to perform. One of: ``"=="``, ``"!="``, ``">"``, ``"<"``, ``">="``, ``"<="``
- value: The value that the field will be compared against. Must be the same data type as the field is
  (e.g. if the field is a string, the value must be a string too)

If you want to filter by multiple fields, then you can specify a list of filter objects.

To disable filtering, you can just not specify the filter argument (if using keyword-based arguments), or,
if using positional arguments, just pass ``null`` or ``[]`` (empty list) for the parameter.

For examples of filtering in-use, please see the :ref:`API code examples <examples>`.

NOTE: Note that with strings being compared, operators like ``>=`` do a lexigraphic string comparison (which
compares, letter to letter, based on the ASCII ordering for individual characters. For more information on
the specific comparison logic used, please see `this page <http://docs.python.org/3/library/stdtypes.html#comparisons>`__.


.. _read_api:

Read API Function Reference
------------------------------------

.. _get_address:

get_address
^^^^^^^^^^^^^^

.. py:function:: get_address(address)

   Gets the history for a specific address

   :param string address: Address
   :return: An :ref:`address history object <address-history-object>` if the address was found, otherwise ``null``.


.. _get_balances:

get_balances
^^^^^^^^^^^^^^

.. py:function:: get_balances(filter=[], order_by=null, order_dir=null)

   Gets the current address balances, optionally filtered by an address and/or asset ID. This list does not
   include any BTC balances.

   :param list/dict filter: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param string order_by: If sorted results are desired, specify the name of a :ref:`balance object <balance-object>` attribute to order the results by (e.g. ``amount``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.
   :return: A list of one or more :ref:`balance objects <balance-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_bets:

get_bets
^^^^^^^^^^^^^^

.. py:function:: get_bets(filters=[], is_valid=true, order_by=null, order_dir=null, start_block=None, end_block=None)

   Gets a listing of bets.

   :param list/dict filter: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid bets. Set to ``false`` to return all bets (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of a :ref:`bet object <bet-object>` attribute to order the results by (e.g. ``wager_amount``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :return: A list of one or more :ref:`bet objects <bet-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_bet_matches:

get_bet_matches
^^^^^^^^^^^^^^^^^^^

.. py:function:: get_bet_matches(filters=[], is_valid=true, order_by=null, order_dir=null, start_block=None, end_block=None)

   Gets a listing of order matches.

   :param list/dict filter: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid bet matches. Set to ``false`` to return all bet matches (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of a :ref:`bet match object <bet-match-object>` attribute to order the results by (e.g. ``deadline``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :return: A list of one or more :ref:`bet match objects <bet-match-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_broadcasts:

get_broadcasts
^^^^^^^^^^^^^^

.. py:function:: get_broadcasts(filters=[], is_valid=true, order_by=null, order_dir=null, start_block=None, end_block=None)

   Gets a listing of broadcasts.

   :param list/dict filter: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid broadcasts. Set to ``false`` to return all broadcasts (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of a :ref:`broadcast object <broadcast-object>` attribute to order the results by (e.g. ``fee_multiplier``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :return: A list of one or more :ref:`broadcast objects <broadcast-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_btcpays:

get_btcpays
^^^^^^^^^^^^^^

.. py:function:: get_btcpays(filters=[], is_valid=true, order_by=null, order_dir=null, start_block=None, end_block=None)

   Gets a listing of BTCPay records.

   :param list/dict filter: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid BTCPays. Set to ``false`` to return all BTCPays (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of a :ref:`BTCPay object <btcpay-object>` attribute to order the results by (e.g. ``block_index``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :return: A list of one or more :ref:`BTCPay objects <btcpay-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_burns:

get_burns
^^^^^^^^^^^^^^

.. py:function:: get_burns(filters=[], is_valid=true, order_by=null, order_dir=null, start_block=None, end_block=None)

   Gets a listing of burns.

   :param list/dict filter: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid dividend issuances. Set to ``false`` to return all dividend issuances (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of a :ref:`burn object <burn-object>` attribute to order the results by (e.g. ``tx_hash``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :return: A list of one or more :ref:`burn objects <burn-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_cancels:

get_cancels
^^^^^^^^^^^^^^

.. py:function:: get_cancels(filters=[], is_valid=true, order_by=null, order_dir=null, start_block=None, end_block=None)

   Gets a listing of canceled orders or bets.

   :param list/dict filter: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid dividend issuances. Set to ``false`` to return all dividend issuances (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of a :ref:`cancel object <cancel-object>` attribute to order the results by (e.g. ``source``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :return: A list of one or more :ref:`cancel objects <cancel-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_credits:

get_credits
^^^^^^^^^^^^^^

.. py:function:: get_credits(filters=[], order_by=null, order_dir=null)

   Gets a sorted history of address credits, optionally filtered to an address and/or asset. This list does not
   include any BTC credits.

   :param list/dict filter: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param string order_by: If sorted results are desired, specify the name of a :ref:`debit/credit object <debit-credit-object>` attribute to order the results by (e.g. ``tx_hash``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :return: A list of one or more :ref:`debit/credit objects <debit-credit-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_debits:

get_debits
^^^^^^^^^^^^^^

.. py:function:: get_debits(filters=[], order_by=null, order_dir=null)

   Gets a sorted history of address debits, optionally filtered to an address and/or asset. This list does not
   include any BTC debits.

   :param list/dict filter: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param string order_by: If sorted results are desired, specify the name of a :ref:`debit/credit object <debit-credit-object>` attribute to order the results by (e.g. ``tx_hash``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :return: A list of one or more :ref:`debit/credit objects <debit-credit-object>` if any matching records were found, otherwise ``[]`` (empty list).
   

.. _get_dividends:

get_dividends
^^^^^^^^^^^^^^

.. py:function:: get_dividends(filters=[], is_valid=true, order_by=null, order_dir=null, start_block=None, end_block=None)

   Gets a listing of dividends.

   :param list/dict filter: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid dividend issuances. Set to ``false`` to return all dividend issuances (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of a :ref:`dividend object <dividend-object>` attribute to order the results by (e.g. ``amount_per_share``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :return: A list of one or more :ref:`dividend objects <dividend-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_issuances:

get_issuances
^^^^^^^^^^^^^^

.. py:function:: get_issuances(filters=[], is_valid=true, order_by=null, order_dir=null, start_block=None, end_block=None)

   Gets a listing of asset issuances.

   :param list/dict filter: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid issuances. Set to ``false`` to return all issuances (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of an :ref:`issuance object <issuance-object>` attribute to order the results by (e.g. ``transfer``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :return: A list of one or more :ref:`issuance objects <issuance-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_orders:

get_orders
^^^^^^^^^^^^^^

.. py:function:: get_orders(filters=[], is_valid=true, show_expired=true, order_by=null, order_dir=null, start_block=None, end_block=None)

   Gets a listing of orders (ordered by price, lowest to highest, and then by transaction ID).

   :param list/dict filter: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid orders. Set to ``false`` to return all orders (including invalid attempts).
   :param boolean show_expired: Set to ``true`` to include expired orders in the results.
   :param string order_by: If sorted results are desired, specify the name of an :ref:`order object <order-object>` attribute to order the results by (e.g. ``get_asset``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :return: A list of one or more :ref:`order objects <order-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_order_matches:

get_order_matches
^^^^^^^^^^^^^^^^^^^

.. py:function:: get_order_matches(filters=[], is_valid=true, is_mine=false, order_by=null, order_dir=null, start_block=None, end_block=None)

   Gets a listing of order matches.

   :param list/dict filter: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid order matches. Set to ``false`` to return all order matches (including invalid attempts).
   :param boolean is_mine: Set to ``true`` to include results where either the ``tx0_address`` or ``tx1_address`` exist in the linked ``bitcoind`` wallet.
   :param string order_by: If sorted results are desired, specify the name of an :ref:`order match object <order-match-object>` attribute to order the results by (e.g. ``forward_asset``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.  
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :return: A list of one or more :ref:`order match objects <order-match-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _get_sends:

get_sends
^^^^^^^^^^^^^^

.. py:function:: get_sends(filters=[], is_valid=true, order_by=null, order_dir=null, start_block=None, end_block=None)

   Gets an optionally filtered listing of past sends.

   :param list/dict filter: An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API results <filtering>` for more information.   
   :param boolean is_valid: Set to ``true`` to only return valid sends. Set to ``false`` to return all sends (including invalid attempts).
   :param string order_by: If sorted results are desired, specify the name of a :ref:`send object <send-object>` attribute to order the results by (e.g. ``asset``). If left blank, the list of results will be returned unordered. 
   :param string order_dir: The direction of the ordering. Either ``asc`` for ascending order, or ``desc`` for descending order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.
   :param integer start_block: If specified, only results from the specified block index on will be returned  
   :param integer end_block: If specified, only results up to and including the specified block index on will be returned  
   :return: A list of one or more :ref:`send objects <send-object>` if any matching records were found, otherwise ``[]`` (empty list).


.. _action_api:

Action/Write API Function Reference
-----------------------------------

.. _do_bet:

do_bet
^^^^^^^^^^^^^^

.. py:function:: do_bet(source, feed_address, bet_type, deadline, wager, counterwager, target_value=0.0, leverage=5040, unsigned=False)

   Issue a bet against a feed.

   :param string source: The address that will make the bet.
   :param string feed_address: The address that host the feed to be bet on.
   :param integer bet_type: 0 for Bullish CFD, 1 for Bearish CFD, 2 for Equal, 3 for NotEqual.
   :param integer deadline: The time at which the bet should be decided/settled, in Unix time.
   :param integer wager: The :ref:`quantity <amounts>` of XCP to wager.
   :param integer counterwager: The minimum :ref:`quantity <amounts>` of XCP to be wagered against, for the bets to match.
   :param float target_value: Target value for Equal/NotEqual bet
   :param integer leverage: Leverage, as a fraction of 5040
   :param boolean unsigned: If set to ``true``, just return the unsigned raw transaction (as hex) instead of actually processing it.
   :return: If unsigned is set to ``false``, the hash of the transaction on success. If unsigend is set to ``true``, the unsigned raw transaction is returned (see the line above).


.. _do_broadcast:

do_broadcast
^^^^^^^^^^^^^^

.. py:function:: do_broadcast(source, fee_multiplier, text, value=0, unsigned=False)

   Broadcast textual and numerical information to the network.

   :param string source: The address that will be sending (must have the necessary quantity of the specified asset).
   :param float fee_multiplier: How much of every bet on this feed should go to its operator; a fraction of 1, (i.e. .05 is five percent).
   :param string text: The textual part of the broadcast.
   :param integer timestamp: The timestamp of the broadcast, in Unix time.
   :param float value: Numerical value of the broadcast.
   :param boolean unsigned: If set to ``true``, just return the unsigned raw transaction (as hex) instead of actually processing it.
   :return: If unsigned is set to ``false``, the hash of the transaction on success. If unsigend is set to ``true``, the unsigned raw transaction is returned (see the line above).


.. _do_btcpay:

do_btcpay
^^^^^^^^^^^^^^

.. py:function:: do_btcpay(order_match_id, unsigned=False)

   Create and (optionally) broadcast a BTCpay message, to settle an Order Match for which you owe BTC. 

   :param string order_match_id: The concatenation of the hashes of the two transactions which compose the order match.
   :param boolean unsigned: If set to ``true``, just return the unsigned raw transaction (as hex) instead of actually processing it.
   :return: If unsigned is set to ``false``, the hash of the transaction on success. If unsigend is set to ``true``, the unsigned raw transaction is returned (see the line above).


.. _do_burn:

do_burn
^^^^^^^^^^^^^^

.. py:function:: do_burn(source, quantity, unsigned=False)

   Burn a given amount of BTC for XCP (**only possible between blocks 278310 and 283810**).

   :param string source: The address with the BTC to burn.
   :param integer quantity: The :ref:`amount <amounts>` of BTC to burn (1 BTC maximum burn per address).
   :param boolean unsigned: If set to ``true``, just return the unsigned raw transaction (as hex) instead of actually processing it.
   :return: If unsigned is set to ``false``, the hash of the transaction on success. If unsigend is set to ``true``, the unsigned raw transaction is returned (see the line above).


.. _do_cancel:

do_cancel
^^^^^^^^^^^^^^

.. py:function:: do_cancel(offer_hash, unsigned=False)

   Cancel an open order or bet you created.

   :param string offer_hash: The transaction hash of the order or bet.
   :param boolean unsigned: If set to ``true``, just return the unsigned raw transaction (as hex) instead of actually processing it.
   :return: If unsigned is set to ``false``, the hash of the transaction on success. If unsigend is set to ``true``, the unsigned raw transaction is returned (see the line above).


.. _do_dividend:

do_dividend
^^^^^^^^^^^^^^

.. py:function:: do_dividend(source, quantity_per_share, share_asset, unsigned=False)

   Issue a dividend on a specific user defined asset.

   :param string source: The address that will be issuing the dividend (must have the ownership of the asset which the dividend is being issued on).
   :param string share_asset: The :ref:`asset <assets>` that the dividends are being rewarded on.
   :param integer quantity_per_share: The :ref:`amount <amounts>` of XCP rewarded per share of the asset.
   :param boolean unsigned: If set to ``true``, just return the unsigned raw transaction (as hex) instead of actually processing it.
   :return: If unsigned is set to ``false``, the hash of the transaction on success. If unsigend is set to ``true``, the unsigned raw transaction is returned (see the line above).


.. _do_issuance:

do_issuance
^^^^^^^^^^^^^^

.. py:function:: do_issuance(source, quantity, asset, divisible, transfer_destination=null, unsigned=False)

   Issue a new asset, issue more of an existing asset or transfer the ownership of an asset.

   :param string source: The address that will be issuing or transfering the asset.
   :param integer quantity: The :ref:`quantity <amounts>` of the asset to issue (set to 0 if *transferring* an asset).
   :param string asset: The :ref:`asset <assets>` to issue or transfer.
   :param boolean divisible: Whether this asset is divisible or not (if a transfer, this value must match the value specified when the asset was originally issued).
   :param string transfer_destination: The address to receive the asset (only used when *transferring* assets -- leave set to ``null`` if issuing an asset).
   :param boolean unsigned: If set to ``true``, just return the unsigned raw transaction (as hex) instead of actually processing it.
   :return: If unsigned is set to ``false``, the hash of the transaction on success. If unsigend is set to ``true``, the unsigned raw transaction is returned (see the line above).


.. _do_order:

do_order
^^^^^^^^^^^^^^

.. py:function:: do_order(source, give_quantity, give_asset, get_quantity, get_asset, expiration, fee_required=0, fee_provided=config.MIN_FEE / config.UNIT, unsigned=False)

   Issue an order request.

   :param string source: The address that will be issuing the order request (must have the necessary quantity of the specified asset to give).
   :param integer give_quantity: The :ref:`quantity <amounts>` of the asset to give.
   :param string give_asset: The :ref:`asset <assets>` to give.
   :param integer get_quantity: The :ref:`quantity <amounts>` of the asset requested in return.
   :param string get_asset: The :ref:`asset <assets>` requested in return.
   :param integer expiration: The number of blocks for which the order should be valid.
   :param integer fee_required: The miners' fee required to be paid by orders for them to match this one; in BTC; required only if buying BTC (may be zero, though).
   :param integer fee_provided: The miners' fee provided; in BTC; required only if selling BTC (should not be lower than is required for acceptance in a block)
   :param boolean unsigned: If set to ``true``, just return the unsigned raw transaction (as hex) instead of actually processing it.
   :return: If unsigned is set to ``false``, the hash of the transaction on success. If unsigend is set to ``true``, the unsigned raw transaction is returned (see the line above).


.. _do_send:

do_send
^^^^^^^^^^^^^^

.. py:function:: do_send(source, destination, quantity, asset, unsigned=false)

   Send XCP or a user defined asset.

   :param string source: The address that will be sending (must have the necessary quantity of the specified asset).
   :param string destination: The address to receive the asset.
   :param integer quantity: The :ref:`quantity <amounts>` of the asset to send.
   :param string asset: The :ref:`asset <assets>` to send.
   :param boolean unsigned: If set to ``true``, just return the unsigned raw transaction (as hex) instead of actually processing it.
   :return: If unsigned is set to ``false``, the hash of the transaction on success. If unsigend is set to ``true``, the unsigned raw transaction is returned (see the line above).

   
Objects
----------

The API calls documented can return any one of these objects.


.. _address-history-object:

Address History Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes the history of a requested address:

* **balances** (*list*): Contains the balances for this address, as a list of :ref:`balance objects <balance-object>`.
* **burns** (*list*): Contains the burns performed with this address, as a list of :ref:`burn objects <burn-object>`.
* **sends** (*list*): The sends performed with this address, as a list of :ref:`send objects <send-object>`.
* **orders** (*list*): The orders of this address,  as a list of :ref:`order objects <order-object>`.
* **order_matches** (*list*): All orders matchings to which this address was a party, as a list of :ref:`order match objects <order-match-object>`.
* **btcpays** (*list*): The BTC pays on this address, as a list of :ref:`BTCPay objects <btc-pay-object>`.
* **issuances** (*list*): The asset issuances performed by this address, as a list of :ref:`issuance objects <issuance-object>`.
* **broadcasts** (*list*): The broadcasts performed by this address, as a list of :ref:`broadcast objects <broadcast-object>`.
* **bets** (*list*): All bets made from this address, as a list of :ref:`bet objects <bet-object>`.
* **bet_matches** (*list*): The bets matchings to which this address was a party, as a list of :ref:`bet match objects <bet-match-object>`.
* **dividends** (*list*): All dividends rewarded from this address, as a list of :ref:`dividend objects <dividend-object>`.
* **cancels** (*list*): All cancels from this address, as a list of :ref:`cancel objects <cancel-object>`.


.. _balance-object:

Balance Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes a balance that is associated to a specific address:

* **address** (*string*): The address that has the balance
* **asset** (*string*): The ID of the :ref:`asset <assets>` in which the balance is specified
* **amount** (*integer*): The :ref:`balance <amounts>` of the specified asset at this address


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
* **wager_amount** (*integer*): The :ref:`quantity <amounts>` of XCP to wager
* **counterwager_amount** (*integer*): The minimum :ref:`quantity <amounts>` of XCP to be wagered by the user to bet against the bet issuer, if the other party were to accept the whole thing
* **wager_remaining** (*integer*): The quantity of XCP wagered that is remaining to bet on
* **odds** (*float*): 
* **target_value** (*float*): Target value for Equal/NotEqual bet
* **leverage** (*integer*): Leverage, as a fraction of 5040
* **expiration** (*integer*): The number of blocks for which the bet should be valid
* **fee_multiplier** (*integer*): 
* **validity** (*string*): Set to "Valid" if a valid bet. Any other setting signifies an invalid/improper bet


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
* **forward_amount** (*integer*): The :ref:`amount <amounts>` of XCP bet in the initial bet
* **backward_amount** (*integer*): The :ref:`amount <amounts>` of XCP bet in the matching bet
* **fee_multiplier** (*integer*): 
* **validity** (*string*): Set to "Valid" if a valid order match. Any other setting signifies an invalid/improper order match


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
* **validity** (*string*): Set to "Valid" if a valid broadcast. Any other setting signifies an invalid/improper broadcast


.. _btcpay-object:

BTCPay Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that matches a request to settle an Order Match for which BTC is owed:

* **tx_index** (*integer*): The transaction index
* **tx_hash** (*string*): The transaction hash
* **block_index** (*integer*): The block index (block number in the block chain)
* **source** (*string*):
* **order_match_id** (*string*):
* **validity** (*string*): Set to "Valid" if valid


.. _burn-object:

Burn Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes an instance of a specific burn:

* **tx_index** (*integer*): The transaction index
* **tx_hash** (*string*): The transaction hash
* **block_index** (*integer*): The block index (block number in the block chain)
* **address** (*string*): The address the burn was performed from
* **burned** (*integer*): The :ref:`amount <amounts>` of BTC burned
* **earned** (*integer*): The :ref:`amount <amounts>` of XPC actually earned from the burn (takes into account any bonus amounts, 1 BTC limitation, etc)
* **validity** (*string*): Set to "Valid" if a valid burn. Any other setting signifies an invalid/improper burn


.. _cancel-object:

Cancel Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes a cancellation of a (previously) open order or bet:

* **tx_index** (*integer*): The transaction index
* **tx_hash** (*string*): The transaction hash
* **block_index** (*integer*): The block index (block number in the block chain)
* **source** (*string*): The address with the open order or bet that was cancelled
* **offer_hash** (*string*): The transaction hash of the order or bet cancelled
* **validity** (*string*): Set to "Valid" if a valid burn. Any other setting signifies an invalid/improper burn


.. _debit-credit-object:

Debit/Credit Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes a account debit or credit:

* **tx_index** (*integer*): The transaction index
* **tx_hash** (*string*): The transaction hash
* **block_index** (*integer*): The block index (block number in the block chain)
* **address** (*string*): The address debited or credited
* **asset** (*string*): The :ref:`asset <assets>` debited or credited
* **amount** (*integer*): The :ref:`amount <amounts>` of the specified asset debited or credited


.. _dividend-object:

Dividend Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes an issuance of dividends on a specific user defined asset:

* **tx_index** (*integer*): The transaction index
* **tx_hash** (*string*): The transaction hash
* **block_index** (*integer*): The block index (block number in the block chain)
* **source** (*string*): The address that issued the dividend
* **asset** (*string*): The :ref:`asset <assets>` that the dividends are being rewarded on 
* **amount_per_share** (*integer*): The :ref:`amount <amounts>` of XCP rewarded per share of the asset
* **validity** (*string*): Set to "Valid" if a valid burn. Any other setting signifies an invalid/improper burn


.. _issuance-object:

Issuance Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes a specific occurance of a user defined asset being issued, or re-issued:

* **tx_index** (*integer*): The transaction index
* **tx_hash** (*string*): The transaction hash
* **block_index** (*integer*): The block index (block number in the block chain)
* **asset** (*string*): The :ref:`asset <assets>` being issued, or re-issued
* **amount** (*integer*): The :ref:`amount <amounts>` of the specified asset being issued
* **divisible** (*boolean*): Whether or not the asset is divisible (must agree with previous issuances of the asset, if there are any)
* **issuer** (*string*): 
* **transfer** (*boolean*): Whether or not this objects marks the transfer of ownership rights for the specified quantity of this asset
* **validity** (*string*): Set to "Valid" if a valid issuance. Any other setting signifies an invalid/improper issuance


.. _order-object:

Order Object
^^^^^^^^^^^^^^^^^^^^^^^

An object that describes a specific order:

* **tx_index** (*integer*): The transaction index
* **tx_hash** (*string*): The transaction hash
* **block_index** (*integer*): The block index (block number in the block chain)
* **source** (*string*): The address that made the order
* **give_asset** (*string*): The :ref:`asset <assets>` being offered
* **give_amount** (*integer*): The :ref:`amount <amounts>` of the specified asset being offered
* **give_remaining** (*integer*):
* **get_asset** (*string*): The :ref:`asset <assets>` desired in exchange
* **get_amount** (*integer*): The :ref:`amount <amounts>` of the specified asset desired in exchange
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
* **forward_amount** (*integer*): The :ref:`amount <amounts>` of the specified forward asset
* **backward_asset** (*string*): The :ref:`asset <assets>` exchanged FROM the second order to the first order
* **backward_amount** (*integer*): The :ref:`amount <amounts>` of the specified backward asset
* **validity** (*string*): Set to "Valid" if a valid order match. Any other setting signifies an invalid/improper order match


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
* **amount** (*integer*): The :ref:`amount <amounts>` of the specified asset sent
* **validity** (*string*): Set to "Valid" if a valid send. Any other setting signifies an invalid/improper send
