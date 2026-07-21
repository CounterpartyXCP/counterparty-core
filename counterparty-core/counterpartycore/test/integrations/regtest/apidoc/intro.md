The Counterparty Core API is the recommended way to query the state of a Counterparty node. All other methods have no official support.

## Headers and HTTP Code

When the server is not ready, that is to say when all the extant blocks have not yet been parsed, every route will return a `503` error, except `/` and those routes that are in the `/blocks`, `/transactions` and `/backend` groups.

All API responses include the following headers:

* `X-COUNTERPARTY-HEIGHT` contains the last block parsed by Counterparty
* `X-BITCOIN-HEIGHT` contains the last block known to Bitcoin Core
* `X-COUNTERPARTY-READY` contains true if `X-COUNTERPARTY-HEIGHT` >= `X-BITCOIN-HEIGHT` - 1
* `X-LEDGER-STATE` contains `Starting`, `Catching Up`, `Following` or `Stopping`

The v2 API uses the following HTTP response codes:

* `200 OK` for successful requests.
* `204 No Content` for successful CORS preflight (`OPTIONS`) requests.
* `400 Bad Request` for invalid parameters, invalid compose/unpack inputs, address or transaction hash validation errors, backend RPC errors returned while handling a request, and other request-level API errors.
* `404 Not Found` when the requested route or resource does not exist.
* `500 Internal Server Error` for unexpected server errors before route handling can complete.
* `503 Service Unavailable` when the API or backend is not ready, or when an unexpected route-handling error is reported as temporarily unavailable.

Routes in the `/v2/bitcoin` group proxy Bitcoin Core responses and may return the proxied status code and headers.

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

## Query Cost Limits

To keep a single request from generating an unbounded amount of work, the server enforces two cost limits:

- **Maximum page size.** The `limit` parameter is capped at `1000` (configurable with `--api-limit-rows`, `0` removes the cap). A larger `limit` is silently clamped to the maximum. Use `cursor`/`offset` pagination to retrieve more results.
- **Maximum backend RPC fan-out.** Some endpoints resolve data from Bitcoin Core — most notably the transaction-info routes (`/v2/transactions/info`, `/v2/transactions/<tx_hash>/info`), which look up every input of a transaction, and the `/v2/addresses/<address>/compose/*` routes, which look up an address's UTXOs. A single request may trigger at most `1000` Bitcoin Core RPC calls (configurable with `--api-max-backend-rpc-calls`, `0` removes the cap). A request that would exceed this is rejected with HTTP `400` and an explanatory error. For large composes you can avoid the backend lookups entirely by supplying the UTXOs directly via the `inputs_set` parameter.

Identical Bitcoin Core lookups are cached, so repeated requests for the same transaction do not repeat the backend work.

## Bitcoin Core Proxy

Routes in the `/v2/bitcoin` group serve as a proxy to make requests to Bitcoin Core.

## Counterparty Transaction Data

Every Counterparty action is a Bitcoin transaction that carries an embedded Counterparty message. The embedded byte stream is identified by the 8-byte `CNTRPRTY` prefix. After the prefix is removed, the parser reads a message type identifier and passes the remaining bytes to the decoder for that message type.

Message type identifiers are normally encoded as 4-byte big-endian integers. When the `short_tx_type_id` protocol change is active, nonzero message type identifiers below 256 may instead be encoded in one byte. The remaining payload is message-specific; for example, a send, issuance, order, or dispenser message each has its own unpacking logic.

Counterparty data can be carried in Bitcoin outputs in different ways. The preferred compact form is `OP_RETURN` when the prefixed payload fits the configured size limit. Legacy or larger encodings may use multisig or P2SH-related data chunks, where the encoded chunks are recovered by the parser before the same `CNTRPRTY` prefix and message type rules are applied.

For application code, prefer the compose and decode helpers rather than parsing scripts manually. Compose routes accept an `encoding` parameter and return the extracted `data` field; `/v2/transactions/unpack` decodes extracted Counterparty data into a `message_type`, `message_type_id`, and message-specific `message_data`. Transaction routes with `verbose=true` can also include `unpacked_data`.

## Events API

One of the new features of API v2 is the ability to make requests by events. This is the most powerful way to recover the vast majority of data.

### Messages table

Counterparty Core is a deterministic state machine. As each block and transaction is parsed, Core writes deterministic event records to the `messages` table. These records form an internal event journal that is used for `messages_hash` calculations, comparing state across nodes or versions, feeding API and ZeroMQ event consumers, rebuilding secondary explorer or indexer databases, and supporting deterministic logging and mempool handling.

The `messages` table is useful for operators and integrators, but it is not a stable public data model. Field names, event payloads, and backfilled historical records may change across releases. Applications that need compatibility guarantees should prefer the documented API v2 event routes instead of depending directly on the raw table.

For example to retrieve events concerning dispensers for a given block:

```
/v2/blocks/<int:block_index>/events/OPEN_DISPENSER
/v2/blocks/<int:block_index>/events/DISPENSER_UPDATE
/v2/blocks/<int:block_index>/events/REFILL_DISPENSER
/v2/blocks/<int:block_index>/events/DISPENSE
```

Or to know the events triggered by a given transaction:

`/v2/transactions/<tx_hash>/events`

You can also obtain the events triggered by a transaction using the `verbose` flag:

`/v2/transactions?verbose=true`

However, please note that in this way, the following events are excluded from the list of events:
`NEW_TRANSACTION`, `TRANSACTION_PARSED`, `CREDIT`, `DEBIT`, `INCREMENT_TRANSACTION_COUNT`, `NEW_TRANSACTION_OUTPUT`.

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
