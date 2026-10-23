# Unreleased

## Protocol

- Add fairminter cards (`fairminter_cards`): a fairminter can distribute a set
  of card subassets (`<asset>.<name>`, by default numbered `<asset>.1` ..
  `<asset>.N`, at most 1000) instead of one asset, like a trading card game
  booster. Each card has a draw weight, an optional `max_supply` and an optional
  name; a fairmint pays as usual and its cards are drawn
  in the block that follows the mint, seeded by that block's hash and the
  fairmint hash, so a draw is unpredictable for the minter and the same on every
  node. A card whose supply is exhausted leaves the draw. `hard_cap`,
  `max_mint_per_tx` (required, at most 1000) and `max_mint_per_address` count
  cards; `premint_quantity`, `soft_cap`, `minted_asset_commission`,
  `pool_quantity` and divisible assets are refused. A card subasset that already
  exists is taken over if its issuer opens the fairminter, so cards can be
  issued with their artwork beforehand. The cards are
  `fair_minting` (not issuable by their owner) until the fairminter closes;
  `lock_quantity` and `lock_description` then apply to them as to the parent.
- Add the `addcards` message (type 92): the issuer of an open card fairminter
  may append cards to it, and/or set `lock_cards`, after which no card can be
  added. A fairminter opened with `lock_cards` never changes its cards, which
  minters can rely on.
- From the same activation, among several issuances of an asset sharing a
  `tx_index` (a fairminter's closing issuance, a card fairminter's open and draw
  issuances), the latest one is the asset's current issuance. Before, the choice
  was left to SQLite.

- Record XCP destruction when a nonzero pool deposit, pool withdrawal, or
  fairminter pool-creation fee is charged (`fix_pool_fee_destruction`). This
  keeps XCP supply and asset conservation consistent with the debited balances,
  including the API's supply projection. Trading fees retained in pool reserves
  are unaffected. No such fee has been charged on mainnet, testnet4 or signet,
  so no historical block is affected.

## Upgrade compatibility

- Refresh published minimum-version requirements in a background thread every
  five minutes, including API-only mode. The watcher no longer relies on a
  once-at-startup call to an otherwise unused daily timer.
- Expose cached protocol compatibility in the API root, response headers and
  health readiness. Before activation, report a pending upgrade without blocking
  service. At a known unsupported activation height, stop parsing before writing
  the block and return `503 protocol_upgrade_required` for ordinary API requests;
  diagnostic endpoints remain available and liveness stays separate.
- Retain known upgrade requirements during metadata outages and report stale or
  unknown verification explicitly. `--force` remains an explicit, advertised
  unsafe bypass. No protocol rules, activation heights or ledger formats change.
- Verify upgrade metadata at startup before any `UPGRADE_ACTIONS` reparse, so
  reparsed blocks are checked against the published requirements.

## API

- Add the `cards` and `lock_cards` parameters to `compose/fairminter`, the
  `compose/addcards` endpoint, `/v2/fairminters/<tx_hash>/cards` (the cards of
  a fairminter, with the card asset's supply under `asset_info` in verbose
  mode) and the `lock_cards` field of fairminters. The `NEW_FAIRMINTER_CARD`
  event records each card; drawn cards appear as `fairmint` issuances and
  credits carried by the fairmint transaction.
- Return MPMA decoding failures, including malformed address tables and
  recipient indexes past the end of the table, through the existing
  `message_data.error` response (HTTP 200) of `/v2/transactions/unpack` and
  `/v2/transactions/info`, rather than a generic HTTP 503 and unexpected-error
  reports. Verbose `unpacked_data` reports the specific error instead of the
  generic "Could not unpack data". Historical data still requires its original
  `block_index`; omitting it uses the current height's protocol rules. This does
  not change consensus decoding or accept legacy messages under current rules.

## Codebase

- Bump `quinn-proto` to 0.11.19 and `rustls` to 0.23.46 in `counterparty-client`
  (RUSTSEC-2026-0338 to -0342, RUSTSEC-2026-0346 to -0349), and triage the
  unmaintained `unsafe-libyaml` and standalone `zbus` crates in the audit
  configuration.
- Bump `pyo3` to 0.29.3 (RUSTSEC-2026-0176, RUSTSEC-2026-0177), `rustls` to
  0.23.46 and `rustls-webpki` to 0.103.16 (RUSTSEC-2026-0049, -0098, -0099,
  -0104, -0285, -0346, -0348, -0349) in `counterparty-rs`.
- Bump `Werkzeug` to 3.1.9 (GHSA-g6x2-hccm-hh4m). The advisory only affects
  nodes running on Windows.
- Bump `rustls-webpki` to 0.103.16 (RUSTSEC-2026-0382) and `webpki-root-certs`
  to 1.0.10 (RUSTSEC-2026-0383) in `counterparty-client`.

## Bootstrap

- Download signed bootstrap snapshots from `https://bootstrap.counterparty.io`
  so the storage backend can be migrated without another client URL change.
  Snapshot filenames, selected snapshot version, and signature verification
  are unchanged.
