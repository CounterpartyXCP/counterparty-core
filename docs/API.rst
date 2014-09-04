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


Connecting and Making Requests
---------------------------------

By default, ``counterpartyd`` will listen on port ``4000`` (if on mainnet) or port ``14000`` (on testnet) for API
requests. 

Note that this API is built on JSON-RPC 2.0, not 1.1. JSON-RPC itself is pretty lightweight, and API requests
are made via a HTTP POST request to ``/api/`` (note the trailing slash), with JSON-encoded data passed as the POST body.

General Format
^^^^^^^^^^^^^^^

All requests must have POST data that is JSON encoded and in the format of:

``{ "method": "METHOD NAME", "params": {"param1": "value1", "param2": "value2"}, "jsonrpc": "2.0", "id": 0 }``

In particular, note the ``jsonrpc`` and ``id`` properties. These are requirements under the JSON-RPC 2.0 spec.

Here's an example of the POST data for a valid API request:

.. code-block::

    {
      "method": "get_burns",
      "params": {"order_by": 'tx_hash',
                 "order_dir": 'asc',
                 "start_block": 280537,
                 "end_block": 280539},
      "jsonrpc": "2.0",
      "id": 0,
    }

You should note that the data in ``params`` is a JSON object (e.g. mapping), not an array. In other words, 
**the API only supports named arguments, not positional arguments** (e.g. use
{"argument1": "value1", "argument2": "value2"} instead of ["value1", "value2"]). This is the case for safety and bug-minimzation reasons.

For more information on JSON RPC, please see the `JSON RPC 2.0 specification <http://www.jsonrpc.org/specification>`__.

Authentication
^^^^^^^^^^^^^^^
Also note that the ``counterpartyd`` API interface requires HTTP basic authentication to use. The username and password required
are stored in the ``counterpartyd.conf`` file, as ``rpc-user`` and ``rpc-password``, respectively. You can also modify
``rpc-host`` and ``rpc-port`` to change what interface and port number ``counterpartyd`` binds to from the defaults.

.. _examples:

Below we provide a few examples of using the ``counterpartyd`` API. Examples in other languages are welcome,
if you'd like to submit them to us, structured in a way to be useful to other people and use standard libraries/methods. 

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
      "params": {"filters": {'field': 'burned', 'op': '>', 'value': 20000000},
                 "filterop": "AND",
                 "order_by": 'tx_hash',
                 "order_dir": 'asc',
                 "start_block": 280537,
                 "end_block": 280539},
      "jsonrpc": "2.0",
      "id": 0,
    }
    response = requests.post(
      url, data=json.dumps(payload), headers=headers, auth=auth).json()
    print("GET_BURNS RESULT: ", response)
    
    #Fetch all debits for > 2 XCP between blocks 280537 and 280539, sorting the results by quantity (descending order)
    payload = {
      "method": "get_debits",
      "params": {"filters": [{'field': 'asset', 'op': '==', 'value': "XCP"},
                             {'field': 'quantity', 'op': '>', 'value': 200000000}],
                "filterop": 'AND',
                "order_by": 'quantity',
                "order_dir": 'desc'},
      "jsonrpc": "2.0",
      "id": 0,
    }
    response = requests.post(
      url, data=json.dumps(payload), headers=headers, auth=auth).json()
    print("GET_DEBITS RESULT: ", response)
    
    
    #Send 1 XCP (specified in satoshis) from one address to another (you must have the sending address in your bitcoind wallet
    # and it will be broadcast as a multisig transaction
    payload = {
      "method": "create_send",
      "params": {'source': "1CUdFmgK9trTNZHALfqGvd8d6nUZqH2AAf",
                 'destination': "17rRm52PYGkntcJxD2yQF9jQqRS4S2nZ7E",
                 'asset': "XCP",
                 'quantity': 100000000},
      "jsonrpc": "2.0",
      "id": 0,
    }
    unsigned_tx = requests.post(url, data=json.dumps(payload), headers=headers, auth=auth)
    print("\nCREATE_SEND RESULT: ", unsigned_tx)

    #2. Now sign it with a key from the wallet
    payload = {
      "method": "sign_tx",
      "params": {'unsigned_tx_hex': unsigned_tx}, #could also specify an external private key to use for signing here
      "jsonrpc": "2.0",
      "id": 0,
    }
    signed_tx = requests.post(url, data=json.dumps(payload), headers=headers, auth=auth)
    print("\nSIGN_TX RESULT: ", signed_tx)

    #3. Now broadcast the signed transaction
    payload = {
      "method": "broadcast_tx",
      "params": {'signed_tx_hex': signed_tx},
      "jsonrpc": "2.0",
      "id": 0,
    }
    tx_hash = requests.post(url, data=json.dumps(payload), headers=headers, auth=auth)
    print("\BROADCAST_TX RESULT: ", tx_hash)
    

PHP Example
^^^^^^^^^^^^

With PHP, you can connect and query ``counterpartyd`` using the `JsonRPC <https://github.com/fguillot/JsonRPC>`__
library. Here's a simple example that will get you the asset balances for a specific address:

.. code-block:: php

    <?php
    require 'JsonRPC/src/JsonRPC/Client.php';
    use JsonRPC\Client;
    $client = new Client('http://localhost:4000/api/');
    $client->authentication('rpcuser', 'rpcpassword');
    
    $result = $client->execute('get_balances', array('filters' => array('field' => 'address', 'op' => '==', 'value' => '1NFeBp9s5aQ1iZ26uWyiK2AYUXHxs7bFmB')));
    print("get_balances result:\n");
    var_dump($result);
    
    $result2 = $client->execute('get_running_info');
    print("get_running_info result:\n");
    var_dump($result2);
    ?>
    
curl Example
^^^^^^^^^^^^^

Here's an example using ``curl`` to make an API call to the ``get_running_info`` method on mainnet.

.. code-block:: none

    curl http://127.0.0.1:4000/api/ --user rpcuser:rpcpassword -H 'Content-Type: application/json; charset=UTF-8' -H 'Accept: application/json, text/javascript' --data-binary '{"jsonrpc":"2.0","id":0,"method":"get_running_info"}'

For testnet, you could use the example above, but change the port to ``14000`` and change the username and password as necessary.


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

.. _floats:

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
- op: The comparison operation to perform. One of: ``"=="``, ``"!="``, ``">"``, ``"<"``, ``">="``, ``"<="``, ``"IN"``, ``"LIKE"``, ``"NOT IN"``, ``"NOT LIKE"``
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
the specific comparison logic used, please see `this page <http://www.sqlite.org/lang_expr.html>`__.

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
- ``auto`` may also be specified to let ``counterpartyd`` choose here. Note that at this time, ``auto`` is effectively the same as
  ``multisig``.

- To return the Counterparty transaction encoded into arbitrary address outputs (i.e. pubkeyhash encoding), specify
  ``pubkeyhash`` for the ``encoding`` parameter. ``pubkey`` is also required to be set (as above, with ``multisig`` encoding)
  if the source address is not contained in the local ``bitcoind`` ``wallet.dat``. Note that this method is **not** recommended
  as a first-resort, as it pollutes the UTXO set.

With any of the above settings, as the *unsigned* raw transaction is returned from the ``create_`` API call itself, you
then have two approaches with respect to broadcasting the transaction on the network:

- If the private key you need to sign the raw transaction is in the local ``bitcoind`` ``wallet.dat``, you should then call the
  ``sign_tx`` API call and pass it to the raw unsigned transaction string as the ``tx_hex`` parameter, with the ``privkey`` parameter
  set to None. This method will then return the signed hex transaction, which you can then broadcast using the ``broadcast_tx``
  API method.
- If the private key you need to sign the raw transaction is *not* in the local ``bitcoind`` ``wallet.dat``, you must first sign
  the transaction yourself (or, alternatively, you can call the ``sign_tx`` API method and specify
  the private key string to it, and ``counterpartyd`` will sign it for you). In either case, once you have the signed,
  hex-encoded transaction string, you can then call the ``broadcast_tx`` API method, which will then broadcast the transaction on the
  Bitcoin network for you.
  
**Note that you can also use a :ref:`do_ call instead <do_table>`, which will take care of creating the transaction,
signing it, and broadcasting it, all in one step.**



.. _read_api:

Read API Function Reference
------------------------------------

.. _get_table:

get_{table}
^^^^^^^^^^^^^^
**get_{table}(filters=[], filterop='AND', order_by=None, order_dir=None, start_block=None, end_block=None, status=None,
limit=1000, offset=0, show_expired=True)**

**{table}** must be one of the following values:
``balances``, ``credits``, ``debits``, ``bets``, ``bet_matches``, ``broadcasts``, ``btcpays``, ``burns``, 
``callbacks``, ``cancels``, ``dividends``, ``issuances``, ``orders``, ``order_matches``, ``sends``, 
``bet_expirations``, ``order_expirations``, ``bet_match_expirations``, ``order_match_expirations``,
``rps``, ``rps_expirations``, ``rps_matches``, ``rps_match_expirations``, or ``rpsresolves``.

For example: ``get_balances``, ``get_credits``, ``get_debits``, etc are all valid API methods.

**Parameters:**

  * **filters (list/dict):** An optional filtering object, or list of filtering objects. See :ref:`Filtering Read API
    results <filtering>` for more information.
  * **filterop (string):** Specifies how multiple filter settings are combined. Defaults to ``AND``, but ``OR`` can
    be specified as well. See :ref:`Filtering Read API results <filtering>` for more information.
  * **order_by  (string):** If sorted results are desired, specify the name of an attribute of the appropriate table to
    order the results by (e.g. ``quantity`` for :ref:`balance objects <balance-object>`, if you called ``get_balances``).
    If left blank, the list of results will be returned unordered. 
  * **order_dir (string):** The direction of the ordering. Either ``ASC`` for ascending order, or ``DESC`` for descending
    order. Must be set if ``order_by`` is specified. Leave blank if ``order_by`` is not specified.
  * **start_block (integer):** If specified, only results from the specified block index on will be returned 
  * **end_block (integer):** If specified, only results up to and including the specified block index on will be returned
  * **status (string/list):** return only results with the specified status or statuses (if a list of status strings is supplied).
    See the :ref:`list of possible statuses <status-list>`. Note that if ``null`` is supplied (the default), then status is not filtered.
    Also note that status filtering can be done via the ``filters`` parameter, but doing it through this parameter is more
    flexible, as it essentially allows for situations where ``OR`` filter logic is desired, as well as status-based filtering.
  * **limit (integer):** (maximum) number of elements to return. Can specify a value less than or equal to 1000. For more results, use
    a combination of ``limit`` and ``offset`` parameters to paginate results.
  * **offset (integer):** return results starting from specified ``offset``

**Special Parameters:**

  * **show_expired (boolean):** used only for ``get_orders``. When false, get_orders don't return orders which expire next block.

**Return:**

  A list of objects with attributes corresponding to the queried table fields.

**Examples:**

  * To get a listing of bets, call ``get_bets``. This method will return a list of one or more :ref:`bet objects <bet-object>` .
  * To get a listing all open orders for a given address like 1Ayw5aXXTnqYfS3LbguMCf9dxRqzbTVbjf, you could call
    ``get_orders`` with the appropriate parameters. This method will return a list of one or more :ref:`order objects <order-object>`.

**Notes:**

  * Please note that the ``get_balances`` API call will not return balances for BTC itself. It only returns balances
    for XCP and other Counterparty assets. To get BTC-based balances, use an existing system such as Insight, blockr.io,
    or blockchain.info.


.. _get_asset_info:

get_asset_info
^^^^^^^^^^^^^^
**get_asset_info(assets)**

Gets information on an issued asset. 

**Parameters:**

  * **assets (list):** A list of one or more :ref:`asset <assets>` for which to retrieve information.

**Return:**

  ``null`` if the asset was not found. Otherwise, a list of one or more objects, each one with the following parameters:

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

.. _get_asset_names:

get_asset_names
^^^^^^^^^^^^^^^^
**get_asset_names()**

Returns a list of all existing Counterparty assets. 

**Parameters:** None

**Return:**

  A list of existing Counterparty asset names.

.. _get_messages:

get_messages
^^^^^^^^^^^^^^
**get_messages(block_index)**

Return message feed activity for the specified block index. The message feed essentially tracks all counterpartyd
database actions and allows for lower-level state tracking for applications that hook into it.
   
**Parameters:**

  * **block_index (integer):** The block index for which to retrieve activity.

**Return:** 
  
  A list of one or more :ref:`messages <message-object>` if there was any activity in the block, otherwise ``[]`` (empty list).

.. _get_messages_by_index:

get_messages_by_index
^^^^^^^^^^^^^^^^^^^^^^
**get_messages_by_index(message_indexes)**

Return the message feed messages whose ``message_index`` values are contained in the specified list of message indexes.
   
**Parameters:**

  * **message_indexes (list)**: An array of one or more ``message_index`` values for which the cooresponding message feed entries are desired. 

**Return:** 

  A list containing a `message <#message-object>`_ for each message found in the specified ``message_indexes`` list. If none were found, ``[]`` (empty list) is returned.

.. _get_xcp_supply:

get_xcp_supply
^^^^^^^^^^^^^^^
**get_xcp_supply()**

Gets the current total quantity of XCP in existance (i.e. quantity created via proof-of-burn, minus quantity
destroyed via asset issuances, etc).

**Parameters:**

  None

**Return:** 

  The :ref:`quantity <quantitys>` of XCP currently in existance.

.. _get_block_info:

get_block_info
^^^^^^^^^^^^^^
**get_block_info(block_index)**

Gets some basic information on a specific block.

**Parameters:**

  * **block_index (integer)**: The block index for which to retrieve information.

**Return:** 

  If the block was found, an object with the following parameters:
     
  - **block_index** (*integer*): The block index (i.e. block height). Should match what was specified for the *block_index* input parameter). 
  - **block_hash** (*string*): The block hash identifier
  - **block_time** (*integer*): A UNIX timestamp of when the block was processed by the network 


.. _get_blocks:

get_blocks
^^^^^^^^^^^^^^^^^

**get_blocks(block_indexes)**

Gets block and message data (for each block) in a bulk fashon. If fetching info and messages for multiple blocks, this
is much quicker than using multiple ``get_block_info()`` and ``get_messages()`` calls.

**Parameters:**

  * **block_index (list)**: A list of 1 or more block indexes for which to retrieve the data.

**Return:**

  A list of objects, one object for each valid block index specified, in order from first block index to last.
  Each object has the following parameters:

  - **block_index** (*integer*): The block index (i.e. block height). Should match what was specified for the *block_index* input parameter). 
  - **block_hash** (*string*): The block hash identifier
  - **block_time** (*integer*): A UNIX timestamp of when the block was processed by the network
  - **_messages** (*list*): A list of one or more :ref:`messages <message-object>` if there was any activity in the block, otherwise ``[]`` (empty list).

.. _get_running_info:

get_running_info
^^^^^^^^^^^^^^^^^
**get_running_info()**

Gets some operational parameters for counterpartyd.

**Parameters:**

  None

**Return:** 

  An object with the following parameters:

  - **db_caught_up** (*boolean*): ``true`` if counterpartyd block processing is caught up with the Bitcoin blockchain, ``false`` otherwise.
  - **bitcoin_block_count** (**integer**): The block height on the Bitcoin network (may not necessarily be the same as ``last_block``, if ``counterpartyd`` is catching up)
  - **last_block** (*integer*): The index (height) of the last block processed by ``counterpartyd``
  - **counterpartyd_version** (*float*): The counterpartyd program version, expressed as a float, such as 0.5
  - **last_message_index** (*integer*): The index (ID) of the last message in the ``counterpartyd`` message feed
  - **running_testnet** (*boolean*): ``true`` if counterpartyd is configured for testnet, ``false`` if configured on mainnet.
  - **db_version_major** (*integer*): The major version of the current counterpartyd database
  - **db_version_minor** (*integer*): The minor version of the current counterpartyd database


Action/Write API Function Reference
-----------------------------------

.. _sign_tx:

sign_tx
^^^^^^^^^^^^^^
**sign_tx(unsigned_tx_hex, privkey=None)**

Sign a transaction created with the Action/Write API.

**Parameters:**

  * **tx_hex (string):** A hex-encoded raw transaction (which was created via one of the ``create_`` calls).
  * **privkey (string):** The private key in WIF format to use for signing the transaction. If not provided,
    the private key must to be known by the ``bitcoind`` wallet.
  
**Return:** 

  A hex-encoded signed raw transaction ready to be broadcast with the ``broadcast_tx`` call.


.. _broadcast_tx:

broadcast_tx
^^^^^^^^^^^^^^
**broadcast_tx(signed_tx_hex)**

Broadcast a signed transaction onto the Bitcoin network.

**Parameters:**

  * **signed_tx_hex (string):** A hex-encoded signed raw transaction (which was created via one of the ``create_`` calls
    and signed with ``sign_tx`` method).
  
**Return:** 

  The created transaction's id on the Bitcoin network, or an error if the transaction is invalid for any reason.

.. _create_bet:

create_bet
^^^^^^^^^^^^^^
**create_bet(source, feed_address, bet_type, deadline, wager, counterwager, target_value=0.0, leverage=5040, encoding='auto', pubkey=null,
allow_unconfirmed_inputs=false, fee=null, fee_per_kb=10000)**

Issue a bet against a feed.

**Parameters:**

  * **source (string):** The address that will make the bet.
  * **feed_address (string):** The address that host the feed to be bet on.
  * **bet_type (integer):** 0 for Bullish CFD, 1 for Bearish CFD, 2 for Equal, 3 for NotEqual.
  * **deadline (integer):** The time at which the bet should be decided/settled, in Unix time.
  * **wager (integer):** The :ref:`quantity <quantitys>` of XCP to wager.
  * **counterwager (integer):** The minimum :ref:`quantity <quantitys>` of XCP to be wagered against, for the bets to match.
  * **target_value (float):** Target value for Equal/NotEqual bet
  * **leverage (integer):** Leverage, as a fraction of 5040
  * **encoding (string):** The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
  * **pubkey (string):** The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
  * **allow_unconfirmed_inputs (boolean):** Set to ``true`` to allow this transaction to utilize unconfirmed UTXOs as inputs.
  * **fee (integer):** If you'd like to specify a custom miners' fee, specify it here (in satoshi). Leave as default for ``counterpartyd`` to automatically choose. 
  * **fee_per_kb (integer):** The fee per kilobyte of transaction data constant that ``counterpartyd`` uses when deciding on the dynamic fee to use (in satoshi). Leave as default unless you know what you're doing.

**Return:** 

  The unsigned transaction, as an hex-encoded string. See :ref:`this section <encoding_param>` for more information.

.. _create_broadcast:

create_broadcast
^^^^^^^^^^^^^^
**create_broadcast(source, fee_fraction, text, value=0, encoding='multisig', pubkey=null,
allow_unconfirmed_inputs=false, fee=null, fee_per_kb=10000)**

Broadcast textual and numerical information to the network.

**Parameters:**

  * **source (string):** The address that will be sending (must have the necessary quantity of the specified asset).
  * **fee_fraction (float):** How much of every bet on this feed should go to its operator; a fraction of 1, (i.e. .05 is five percent).
  * **text (string):** The textual part of the broadcast.
  * **timestamp (integer):** The timestamp of the broadcast, in Unix time.
  * **value (float):** Numerical value of the broadcast.
  * **encoding (string):** The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
  * **pubkey (string):** The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
  * **allow_unconfirmed_inputs (boolean):** Set to ``true`` to allow this transaction to utilize unconfirmed UTXOs as inputs.
  * **fee (integer):** If you'd like to specify a custom miners' fee, specify it here (in satoshi). Leave as default for ``counterpartyd`` to automatically choose. 
  * **fee_per_kb (integer):** The fee per kilobyte of transaction data constant that ``counterpartyd`` uses when deciding on the dynamic fee to use (in satoshi). Leave as default unless you know what you're doing.

**Return:** 

  The unsigned transaction, as an hex-encoded string. See :ref:`this section <encoding_param>` for more information.

.. _create_btcpay:

create_btcpay
^^^^^^^^^^^^^^
**create_btcpay(order_match_id, encoding='multisig', pubkey=null,
allow_unconfirmed_inputs=false, fee=null, fee_per_kb=10000)**

Create and (optionally) broadcast a BTCpay message, to settle an Order Match for which you owe BTC. 

**Parameters:**

  * **order_match_id (string):** The concatenation of the hashes of the two transactions which compose the order match.
  * **encoding (string):** The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
  * **pubkey (string):** The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
  * **allow_unconfirmed_inputs (boolean):** Set to ``true`` to allow this transaction to utilize unconfirmed UTXOs as inputs.
  * **fee (integer):** If you'd like to specify a custom miners' fee, specify it here (in satoshi). Leave as default for ``counterpartyd`` to automatically choose. 
  * **fee_per_kb (integer):** The fee per kilobyte of transaction data constant that ``counterpartyd`` uses when deciding on the dynamic fee to use (in satoshi). Leave as default unless you know what you're doing.

**Return:** 

  The unsigned transaction, as an hex-encoded string. See :ref:`this section <encoding_param>` for more information.

.. _create_burn:

create_burn
^^^^^^^^^^^^^^
**create_burn(source, quantity, encoding='multisig', pubkey=null, allow_unconfirmed_inputs=false, fee=null, fee_per_kb=10000)**

Burn a given quantity of BTC for XCP (**only possible between blocks 278310 and 283810**).

**Parameters:**

  * **source (string):** The address with the BTC to burn.
  * **quantity (integer):** The :ref:`quantity <quantitys>` of BTC to burn (1 BTC maximum burn per address).
  * **encoding (string):** The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
  * **pubkey (string):** The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
  * **allow_unconfirmed_inputs (boolean):** Set to ``true`` to allow this transaction to utilize unconfirmed UTXOs as inputs.
  * **fee (integer):** If you'd like to specify a custom miners' fee, specify it here (in satoshi). Leave as default for ``counterpartyd`` to automatically choose. 
  * **fee_per_kb (integer):** The fee per kilobyte of transaction data constant that ``counterpartyd`` uses when deciding on the dynamic fee to use (in satoshi). Leave as default unless you know what you're doing.

**Return:** 

  The unsigned transaction, as an hex-encoded string. See :ref:`this section <encoding_param>` for more information.

.. _create_callback:

create_callback
^^^^^^^^^^^^^^^^^
**create_callback(offer_hash, encoding='multisig', pubkey=null, allow_unconfirmed_inputs=false, fee=null, fee_per_kb=10000)**

Make a call on a callable asset (where some whole or part of the asset is returned to the issuer, on or after the asset's call date).

**Parameters:**

  * **source (string):** The callback source address. Must be the same address as the specified asset's owner.
  * **fraction (float):** A floating point number greater than zero but less than or equal to 1, where 0% is for a callback of 0% of the balance of each of the asset's holders, and 1 would be for a callback of 100%). For example, ``0.56`` would be 56%. Each holder of the called asset will be paid the call price for the asset, times the number of units of that asset that were called back from them.
  * **encoding (string):** The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
  * **pubkey (string):** The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
  * **allow_unconfirmed_inputs (boolean):** Set to ``true`` to allow this transaction to utilize unconfirmed UTXOs as inputs.
  * **fee (integer):** If you'd like to specify a custom miners' fee, specify it here (in satoshi). Leave as default for ``counterpartyd`` to automatically choose. 
  * **fee_per_kb (integer):** The fee per kilobyte of transaction data constant that ``counterpartyd`` uses when deciding on the dynamic fee to use (in satoshi). Leave as default unless you know what you're doing.

**Return:** 

  The unsigned transaction, as an hex-encoded string. See :ref:`this section <encoding_param>` for more information.

.. _create_cancel:

create_cancel
^^^^^^^^^^^^^^
**create_cancel(offer_hash, encoding='multisig', pubkey=null, allow_unconfirmed_inputs=false, fee=null, fee_per_kb=10000)**

Cancel an open order or bet you created.

**Parameters:**

  * **offer_hash (string):** The transaction hash of the order or bet.
  * **encoding (string):** The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
  * **pubkey (string):** The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
  * **allow_unconfirmed_inputs (boolean):** Set to ``true`` to allow this transaction to utilize unconfirmed UTXOs as inputs.
  * **fee (integer):** If you'd like to specify a custom miners' fee, specify it here (in satoshi). Leave as default for ``counterpartyd`` to automatically choose. 
  * **fee_per_kb (integer):** The fee per kilobyte of transaction data constant that ``counterpartyd`` uses when deciding on the dynamic fee to use (in satoshi). Leave as default unless you know what you're doing.

**Return:** 

  The unsigned transaction, as an hex-encoded string. See :ref:`this section <encoding_param>` for more information.

.. _create_dividend:

create_dividend
^^^^^^^^^^^^^^^^^
**create_dividend(source, quantity_per_unit, asset, dividend_asset, encoding='multisig', pubkey=null, allow_unconfirmed_inputs=false, fee=null, fee_per_kb=10000)**

Issue a dividend on a specific user defined asset.

**Parameters:**

  * **source (string):** The address that will be issuing the dividend (must have the ownership of the asset which the dividend is being issued on).
  * **asset (string):** The :ref:`asset <assets>` that the dividends are being rewarded on.
  * **dividend_asset (string):** The :ref:`asset <assets>` that the dividends are paid in.
  * **quantity_per_unit (integer):** The :ref:`quantity <quantitys>` of XCP rewarded per whole unit of the asset.
  * **encoding (string):** The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
  * **pubkey (string):** The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
  * **allow_unconfirmed_inputs (boolean):** Set to ``true`` to allow this transaction to utilize unconfirmed UTXOs as inputs.
  * **fee (integer):** If you'd like to specify a custom miners' fee, specify it here (in satoshi). Leave as default for ``counterpartyd`` to automatically choose. 
  * **fee_per_kb (integer):** The fee per kilobyte of transaction data constant that ``counterpartyd`` uses when deciding on the dynamic fee to use (in satoshi). Leave as default unless you know what you're doing.

**Return:** 

  The unsigned transaction, as an hex-encoded string. See :ref:`this section <encoding_param>` for more information.

.. _create_issuance:

create_issuance
^^^^^^^^^^^^^^^^^
**create_issuance(source, asset, quantity, divisible, description, callable_=false, call_date=null, call_price=null,
transfer_destination=null, encoding='multisig', pubkey=null, allow_unconfirmed_inputs=false, fee=null, fee_per_kb=10000)**

Issue a new asset, issue more of an existing asset, lock an asset, or transfer the ownership of an asset (note that you can only do one of these operations in a given create_issuance call).

**Parameters:**

  * **source (string):** The address that will be issuing or transfering the asset.
  * **quantity (integer):** The :ref:`quantity <quantitys>` of the asset to issue (set to 0 if *transferring* an asset).
  * **asset (string):** The :ref:`asset <assets>` to issue or transfer.
  * **divisible (boolean):** Whether this asset is divisible or not (if a transfer, this value must match the value specified when the asset was originally issued).
  * **callable_ (boolean):** Whether the asset is callable or not.
  * **call_date (integer):** The timestamp at which the asset may be called back, in Unix time. Only valid for callable assets.
  * **call_price (float):** The :ref:`price <floats>` per unit XCP at which the asset may be called back, on or after the specified call_date. Only valid for callable assets.
  * **description (string):** A textual description for the asset. 52 bytes max.
  * **transfer_destination (string):** The address to receive the asset (only used when *transferring* assets -- leave set to ``null`` if issuing an asset).
  * **encoding (string):** The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
  * **pubkey (string):** The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
  * **allow_unconfirmed_inputs (boolean):** Set to ``true`` to allow this transaction to utilize unconfirmed UTXOs as inputs.
  * **fee (integer):** If you'd like to specify a custom miners' fee, specify it here (in satoshi). Leave as default for ``counterpartyd`` to automatically choose. 
  * **fee_per_kb (integer):** The fee per kilobyte of transaction data constant that ``counterpartyd`` uses when deciding on the dynamic fee to use (in satoshi). Leave as default unless you know what you're doing.

**Return:** 

  The unsigned transaction, as an hex-encoded string. See :ref:`this section <encoding_param>` for more information.

**Notes:**

  * To lock the issuance of the asset, specify "LOCK" for the ``description`` field. It's a special keyword that will
    not change the actual description, but will simply lock the asset quantity and not allow additional quantity to be
    issued for the asset.


.. _create_order:

create_order
^^^^^^^^^^^^^^
**create_order(source, give_asset, give_quantity, get_asset, get_quantity, expiration, fee_required=0, fee_provided=0, encoding='multisig', pubkey=null,
allow_unconfirmed_inputs=false, fee=null, fee_per_kb=10000)**

Issue an order request.

**Parameters:**

  * **source (string):** The address that will be issuing the order request (must have the necessary quantity of the specified asset to give).
  * **give_quantity (integer):** The :ref:`quantity <quantitys>` of the asset to give.
  * **give_asset (string):** The :ref:`asset <assets>` to give.
  * **get_quantity (integer):** The :ref:`quantity <quantitys>` of the asset requested in return.
  * **get_asset (string):** The :ref:`asset <assets>` requested in return.
  * **expiration (integer):** The number of blocks for which the order should be valid.
  * **fee_required (integer):** The miners' fee required to be paid by orders for them to match this one; in BTC; required only if buying BTC (may be zero, though). If not specified or set to ``null``, this defaults to 1% of the BTC desired for purchase.
  * **fee_provided (integer):** The miners' fee provided; in BTC; required only if selling BTC (should not be lower than is required for acceptance in a block).  If not specified or set to ``null``, this defaults to 1% of the BTC for sale. 
  * **encoding (string):** The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
  * **pubkey (string):** The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
  * **allow_unconfirmed_inputs (boolean):** Set to ``true`` to allow this transaction to utilize unconfirmed UTXOs as inputs.
  * **fee (integer):** If you'd like to specify a custom miners' fee, specify it here (in satoshi). Leave as default for ``counterpartyd`` to automatically choose. 
  * **fee_per_kb (integer):** The fee per kilobyte of transaction data constant that ``counterpartyd`` uses when deciding on the dynamic fee to use (in satoshi). Leave as default unless you know what you're doing.

**Return:** 

  The unsigned transaction, as an hex-encoded string. See :ref:`this section <encoding_param>` for more information.

.. _create_send:

create_send
^^^^^^^^^^^^^^
**create_send(source, destination, asset, quantity, encoding='multisig', pubkey=null, allow_unconfirmed_inputs=false, fee=null, fee_per_kb=10000)**

Send XCP or a user defined asset.

**Parameters:**

  * **source (string):** The address that will be sending (must have the necessary quantity of the specified asset).
  * **destination (string):** The address to receive the asset.
  * **quantity (integer):** The :ref:`quantity <quantitys>` of the asset to send.
  * **asset (string):** The :ref:`asset <assets>` to send.
  * **encoding (string):** The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
  * **pubkey (string):** The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
  * **allow_unconfirmed_inputs (boolean):** Set to ``true`` to allow this transaction to utilize unconfirmed UTXOs as inputs.
  * **fee (integer):** If you'd like to specify a custom miners' fee, specify it here (in satoshi). Leave as default for ``counterpartyd`` to automatically choose. 
  * **fee_per_kb (integer):** The fee per kilobyte of transaction data constant that ``counterpartyd`` uses when deciding on the dynamic fee to use (in satoshi). Leave as default unless you know what you're doing.

**Return:** 

  The unsigned transaction, as an hex-encoded string. See :ref:`this section <encoding_param>` for more information.

.. _create_rps:

create_rps
^^^^^^^^^^^^^^
**create_rps(source, possible_moves, wager, move_random_hash, expiration, encoding='multisig', pubkey=null,
allow_unconfirmed_inputs=false, fee=null, fee_per_kb=10000)**

Open a Rock-Paper-Scissors (RPS) like game.

**Parameters:**

  * **source (string):** The address that will be sending (must have the necessary quantity of the specified asset).
  * **possible_moves (integer):** The number of possible moves. Must be an odd number greater or equal than 3.
  * **wager (integer):** The :ref:`quantity <quantitys>` of XCP to wager.
  * **move_random_hash (string):** A 32 bytes hex string (64 chars): sha256(sha256(random+move)). Where random is 16 bytes random number.
  * **expiration (integer):** The number of blocks for which the game should be valid.
  * **encoding (string):** The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
  * **pubkey (string):** The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
  * **allow_unconfirmed_inputs (boolean):** Set to ``true`` to allow this transaction to utilize unconfirmed UTXOs as inputs.
  * **fee (integer):** If you'd like to specify a custom miners' fee, specify it here (in satoshi). Leave as default for ``counterpartyd`` to automatically choose. 
  * **fee_per_kb (integer):** The fee per kilobyte of transaction data constant that ``counterpartyd`` uses when deciding on the dynamic fee to use (in satoshi). Leave as default unless you know what you're doing.

**Return:** 

  The unsigned transaction, as an hex-encoded string. See :ref:`this section <encoding_param>` for more information.

create_rpsresolve
^^^^^^^^^^^^^^^^^^^^^^
**create_rpsresolve(source, move, random, rps_match_id, encoding='multisig', pubkey=null,
allow_unconfirmed_inputs=false, fee=null, fee_per_kb=10000)**

Resolve a Rock-Paper-Scissors game.

**Parameters:**
  * **source (string):** The address that will be sending (must have the necessary quantity of the specified asset).
  * **move (integer):** The selected move.
  * **random (string):** A 16 bytes hex string (32 chars) used to generate the move_random_hash value.
  * **rps_match_id (string):** The concatenation of the hashes of the two transactions which compose the rps match.
  * **encoding (string):** The encoding method to use, see :ref:`this section <encoding_param>` for more info.  
  * **pubkey (string):** The pubkey hex string. Required if multisig transaction encoding is specified for a key external to ``counterpartyd``'s local wallet. See :ref:`this section <encoding_param>` for more info.
  * **allow_unconfirmed_inputs (boolean):** Set to ``true`` to allow this transaction to utilize unconfirmed UTXOs as inputs.
  * **fee (integer):** If you'd like to specify a custom miners' fee, specify it here (in satoshi). Leave as default for ``counterpartyd`` to automatically choose. 
  * **fee_per_kb (integer):** The fee per kilobyte of transaction data constant that ``counterpartyd`` uses when deciding on the dynamic fee to use (in satoshi). Leave as default unless you know what you're doing.

**Return:** 

  The unsigned transaction, as an hex-encoded string. See :ref:`this section <encoding_param>` for more information.

.. _do_table:

do_{table}
^^^^^^^^^^^^^^
**do_{entity}(VARIABLE)**

This method is a simplified alternative to the appropriate ``create_`` method. Instead of returning just an unsigned
raw transaction, which you must then sign and broadcast, this call will create the transaction, then sign it and broadcast
it automatically.

**{entity}** must be one of the following values:
``bet``, ``broadcast``, ``btcpay``, ``burn``,  ``callback``, ``cancel``, ``dividend``, ``issuance``,
``order``, ``send``,  ``rps``, ``rpsresolve``.

For example: ``do_bet``, ``do_burn``, ``do_dividend``, etc are all valid API methods.

**Parameters:**

  * **privkey (string):** The private key in WIF format to use for signing the transaction. If not provided,
    the private key must to be known by the ``bitcoind`` wallet.
  * The other parameters for a given ``do_`` method are the same as the corresponding ``create_`` call.

**Return:**

  The created transaction's id on the Bitcoin network, or an error if the transaction is invalid for any reason.



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

.. _status-list:

Status
----------

Here the list of all possible status for each table:

* **balances**: No status field
* **bet_expirations**: No status field
* **bet_match_expirations**: No status field
* **bet_matches**: pending, settled: liquidated for bear, settled, settled: liquidated for bull, settled: for equal, settled: for notequal, dropped, expired
* **bets**: open, filled, cancelled, expired, dropped, invalid: {problem(s)}
* **broadcasts**: valid, invalid: {problem(s)}
* **btcpays**: valid, invalid: {problem(s)}
* **burns**: valid, invalid: {problem(s)}
* **callbacks**: valid, invalid: {problem(s)}
* **cancels**: valid, invalid: {problem(s)}
* **credits**: No status field
* **debits**: No status field
* **dividends**: valid, invalid: {problem(s)}
* **issuances**: valid, invalid: {problem(s)}
* **order_expirations**: No status field
* **order_match_expirations**: No status field
* **order_matches**: pending, completed, expired
* **orders**: open, filled, canceled, expired, invalid: {problem(s)}
* **sends**: valid, invalid: {problem(s)}
  

API Changes
-------------

This section documents any changes to the ``counterpartyd`` API, for version numbers where there were API-level modifications.

.. _9_32_0:

9.32.0
^^^^^^^^^^^^^^^^^^^^^^^

**Summary:** API framework overhaul for performance and simplicity 

* "/api" with no trailing slash no longer supported as an API endpoint (use "/" or "/api/" instead)
* We now consistently reject positional arguments with all API methods. Make sure your API calls do not use positional
  arguments (e.g. use {"argument1": "value1", "argument2": "value2"} instead of ["value1", "value2"])


.. _9_24_1:

9.24.1
^^^^^^^^^^^^^^^^^^^^^^^

**Summary:** New API parsing engine added, as well as dynamic get_ method composition in ``api.py``: 

* Added ``sql`` API method
* Filter params: Added ``LIKE``, ``NOT LIKE`` and ``IN``


.. _9_25_0:

9.25.0
^^^^^^^^^^^^^^^^^^^^^^^

* new do_* methods: like create_*, but also sign and broadcast the transaction. Same parameters as create_*, plus optional privkey parameter.

**backwards incompatible changes**

* create_*: accept only dict as parameters
* create_bet: ``bet_type`` must be a integer (instead string)
* create_bet: ``wager`` and ``counterwager`` args are replaced by ``wager_quantity`` and ``counterwager_quantity``
* create_issuance: parameter ``lock`` (boolean) removed (use LOCK in description)
* create_issuance: parameter ``transfer_destination`` replaced by ``destination``
* DatabaseError: now a DatabaseError is returned immediately if the counterpartyd database is behind the backend, instead of after fourteen seconds
