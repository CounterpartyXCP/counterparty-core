FORMAT: 1A
HOST: https://api.counterparty.io:4000

# Counterparty Core API

The Counterparty Core API is the recommended way to query the state of a Counterparty node. All other methods have no official support.

API routes are divided into groups:

<GROUP_TOC>

## Headers and HTTP Code

When the server is not ready, that is to say when all the extant blocks have not yet been parsed, every route will return a `503` error, except `/` and those routes that are in the `/blocks`, `/transactions` and `/backend` groups.

All API responses contain the following 3 headers:

* `X-COUNTERPARTY-HEIGHT` contains the last block parsed by Counterparty
* `X-BITCOIN-HEIGHT` contains the last block known to Bitcoin Core
* `X-COUNTERPARTY-READY` contains true if `X-COUNTERPARTY-HEIGHT` >= `X-BITCOIN-HEIGHT` - 1

## Responses Format

All API responses follow the following format:

```
{
    "error": <error_messsage_if_success_is_false>,
    "result": <result_of_the_query_if_success_is_true>,
    "next_cursor": <cursor_value_to_get_the_next_page>,
    "result_count": <number_of_results>
}
```

## Pagination

For all routes that return a list of results from the database, you can choose between two pagination modes:

- With the `cursor` and `limit` parameters
- With the `offset` and `limit` parameters

The `cursor` parameter allows you to get results from a certain index. This index is generally retrieved from the `next_cursor` field of the previous result (see above).
The `offset` parameter allows you to ignore a certain number of results before returning the rest.

For example:
`/v2/blocks?limit=5&cursor=844575` allows you to recover blocks 844575 to 844570.
`/v2/blocks?limit=5&offset=5` allows you to retrieve the 5th to the tenth most recent blocks.

All responses contain a `result_count` field allowing you to calculate the number of pages.

## Bitcoin Core Proxy

Routes in the `/v2/bitcoin` group serve as a proxy to make requests to Bitcoin Core.

## Events API

One of the new features of API v2 is the ability to make requests by events. This is the most powerful way to recover the vast majority of data.

For example to retrieve events concerning dispensers for a given block:

```
/v2/blocks/<int:block_index>/events/OPEN_DISPENSER
/v2/blocks/<int:block_index>/events/DISPENSER_UPDATE
/v2/blocks/<int:block_index>/events/REFILL_DISPENSER
/v2/blocks/<int:block_index>/events/DISPENSE
```

Or to know the events triggered by a given transaction:

`/v2/transactions/<tx_hash>/events`

### ZeroMQ Publisher

You can enable the ZeroMQ server by starting `counterparty-server` with the `--enable-zmq-publisher` flag.
All events are published, each in a specific topic. You can subscribe to the events that interest you. For example in Python:

```
context = zmq.asyncio.Context()
socket = context.socket(zmq.SUB)
socket.setsockopt(zmq.RCVHWM, 0)
socket.setsockopt_string(zmq.SUBSCRIBE, "CREDIT")
socket.setsockopt_string(zmq.SUBSCRIBE, "DEBIT")
```

You can use an empty string to subscribe to all events.

By default events are published on port `4001`, you can customize this port with the flag `--zmq-publisher-port`.

You can see a complete, working example in Python here: https://github.com/CounterpartyXCP/counterparty-core/blob/master/counterparty-core/tools/zmqclient.py.


### Notes about update events

For the events `DISPENSER_UPDATE` and `ORDER_UPDATE`, depending on the reason for the update, the fields present in `params` may be different.

Here are the different possibilities for `DISPENSER_UPDATE`:

On refill dispenser and on dispense:

- give_remaining
- dispense_count
- source
- asset
- status

On closing dispenser with delay:

- last_status_tx_hash
- source
- asset
- status

On closing dispenser:

- give_remaining
- source
- asset
- status

and those for `ORDER_UPDATE`:

On order cancellation:

- status
- tx_hash

On order match cancellation:

- give_remaining
- get_remaining
- status
- fee_required_remaining

On order match:

- give_remaining
- get_remaining
- fee_required_remaining
- fee_provided_remaining
- status

## Events Reference

Here is a list of events classified by theme and for each an example response:

<EVENTS_DOC>

# Counterparty API Root [/v2/]

### Get Server Info [GET /v2/]

Returns server information and the list of documented routes in JSON format.

+ Response 200 (application/json)

    ```
    {
        "result": {
            "server_ready": true,
            "network": "mainnet",
            "version": "10.4.1",
            "backend_height": 850214,
            "counterparty_height": 850214,
            "documentation": "https://counterpartycore.docs.apiary.io/",
            "blueprint": "http://localhost:4000/v2/blueprint"
        }
    }
    ```

<API_BLUEPRINT>
