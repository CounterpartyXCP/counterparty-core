FORMAT: 1A
HOST: https://api.counterparty.io:4000

# Counterparty Core API

The Counterparty Core API is the recommended (and only supported) way to query the state of a Counterparty node. 

Please see [Apiary](https://counterpartycore.docs.apiary.io/) for interactive documentation.

API routes are divided into 11 groups:

<GROUP_TOC>

## Headers and HTTP Code

When the server is not ready, that is to say when all the blocks are not yet parsed, all routes return a 503 error except `/` and those in the `/blocks`, `/transactions` and `/backend` groups which always return a result.

All API responses contain the following 3 headers:

    * `X-COUNTERPARTY-HEIGHT` contains the last block parsed by Counterparty
    * `X-BITCOIN-HEIGHT` contains the last block known to Bitcoin Core
    * `X-COUNTERPARTY-READY` contains true if `X-COUNTERPARTY-HEIGHT` >= `X-BITCOIN-HEIGHT` - 1

## Responses Format

All API responses follow the following format:

    ```
    {
        "error": <error_messsage_if_success_is_false>,
        "result": <result_of_the_query_if_success_is_true>
        "next_cursor": <cursor_value_to_get_the_next_page>
    }
    ```

All queries that return lists from the database accept the "cursor" and "limit" arguments. To get the next page you must use "?cursor=<next_cursor>".

## Bitcoin Core Proxy

Routes in the `/v2/bitcoin` group serve as a proxy to make requests to Bitcoin Core.

## Events API

One of the new features of API v2 is being able to make requests by events. This is the most powerful way to recover the vast majority of data.

For example to retrieve events concerning dispensers for a given block:

```
/v2/blocks/<int:block_index>/events/OPEN_DISPENSER
/v2/blocks/<int:block_index>/events/DISPENSER_UPDATE
/v2/blocks/<int:block_index>/events/REFILL_DISPENSER
/v2/blocks/<int:block_index>/events/DISPENSE
```

Or to know the events triggered by a given transaction:

`/v2/transactions/<tx_hash>/events`

Here is a list of events classified by theme and for each an example response:

<EVENTS_DOC>

# Counterparty API Root [<ROOT_PATH>]

### Get Server Info [GET /v2/]

Returns server information and the list of documented routes in JSON format.

+ Response 200 (application/json)

    ```
    {
        "server_ready": true,
        "network": "mainnet",
        "version": "10.1.2",
        "backend_height": 840796,
        "counterparty_height": 840796,
        "routes": [
            <API Documentation in JSON>
        ]
    }
    ```

<API_BLUEPRINT>