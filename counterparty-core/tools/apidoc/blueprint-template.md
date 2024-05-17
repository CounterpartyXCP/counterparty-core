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

- All API responses follow the following format:

    ```
    {
        "error": <error_messsage_if_success_is_false>,
        "result": <result_of_the_query_if_success_is_true>
    }
    ```

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

Here is the list of all the events that you can use classified by theme:

### Blocks and Transactions

- `NEW_BLOCK`
- `NEW_TRANSACTION`
- `NEW_TRANSACTION_OUTPUT`
- `BLOCK_PARSED`
- `TRANSACTION_PARSED`

### Asset Movements

- `DEBIT`
- `CREDIT`
- `ENHANCED_SEND`
- `MPMA_SEND`
- `SEND`
- `ASSET_TRANSFER`
- `SWEEP`
- `ASSET_DIVIDEND`

### Asset Creation and Destruction

- `RESET_ISSUANCE`
- `ASSET_CREATION`
- `ASSET_ISSUANCE`
- `ASSET_DESTRUCTION`

### DEX

- `OPEN_ORDER`
- `ORDER_MATCH`
- `ORDER_UPDATE`
- `ORDER_FILLED`
- `ORDER_MATCH_UPDATE`
- `BTC_PAY`
- `CANCEL_ORDER`
- `ORDER_EXPIRATION`
- `ORDER_MATCH_EXPIRATION`

### Dispenser

- `OPEN_DISPENSER`
- `DISPENSER_UPDATE`
- `REFILL_DISPENSER`
- `DISPENSE`

### Broadcast

- `BROADCAST`

### Bets

- `OPEN_BET`
- `BET_UPDATE`
- `BET_MATCH`
- `BET_MATCH_UPDATE`
- `BET_EXPIRATION`
- `BET_MATCH_EXPIRATION`
- `BET_MATCH_RESOLUTON`
- `CANCEL_BET`

### Burns

- `BURN`

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