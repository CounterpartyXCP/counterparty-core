# Unreleased

## Protocol

- Add Fairboosters (`fairboosters`): boosters of trading cards sold for XCP.
  A `fairbooster` (message 130) creates a free named or numeric asset, with a
  supply of 1 and locked, and a list of cards, each with an id, a name, the
  hash of its image, a draw weight and a supply (0 for unlimited). It also sets
  a description, an image URL, the price of a booster, the maximum number of
  boosters, the number of cards per booster, and the base URL and extension of
  the card images (`<base_url>/<id>.<extension>`). Creating a fairbooster costs
  0.5 XCP for a named asset (a numeric one is free, as with an issuance), plus
  a gas fee for each card it can sell (`max_boosters * cards_per_booster`).
  The gas fee (`fee_parameters` 130, counted in cards) prices each card at the
  average number of cards per block it brings the last 2016 blocks to, between
  0.001 XCP (`min_unit_fee`) and 0.1 XCP (`max_unit_fee`): 0.001 XCP up to
  about 45, 0.05 XCP at 55, and 0.1 XCP from about 60. A large capacity
  therefore pays for the usage it creates, whether it is bought in one
  transaction or in several, and never more than 0.1 XCP per card. Both fees
  are destroyed: the asset fee as the `fee_paid` of the issuance, like an
  issuance fee, and the gas fee as a destruction. A name that an active
  fairminter earmarked as its `lp_asset` cannot be used.
- `buybooster` (message 132) buys one booster. It carries the terms the buyer
  accepts: the highest price paid (`max_price`), the number of cards of a
  booster and the number of cards of the fairbooster. An update of the
  fairbooster confirmed before the purchase, in an earlier block or earlier in
  the same one, therefore makes it invalid instead of changing what the buyer
  pays or gets. The price goes to the owner of the fairbooster (the issuer of
  its asset), and the cards are drawn in the next block, among the cards the
  fairbooster had when the booster was bought. Each card is picked with a
  probability proportional to its weight among the cards that are not
  exhausted, seeded by that block's hash and the purchase hash, so a draw is
  unpredictable for the buyer and the same on every node. Every drawn card
  becomes an asset of its own,
  `<fairbooster>.<card_id>.<card_name>.<serial>` (spaces in the name become
  `_`), with a supply of 1, locked quantity and description, issued to the
  buyer; its numeric asset name skips the names earmarked as an `lp_asset`. A
  purchase is refused when every booster is sold or when the cards
  left, after those of the pending purchases, cannot fill a booster; the
  fairbooster is then `closed` until an update reopens it.
- `updatefairbooster` (message 131) lets the owner change every parameter but
  the name, and add cards. Existing cards cannot change. Raising the capacity
  (the cards of the boosters sold plus `cards_per_booster` for each booster
  left) above what was already paid for pays the gas fee of the added cards,
  and `max_boosters` cannot go below the number of boosters sold.
- From the same activation, the subassets of a fairbooster can only be created
  by its draws, and the three messages get their own `transaction_type`.

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

- Add the `compose/fairbooster`, `compose/updatefairbooster` and
  `compose/buybooster` endpoints. The cards are passed as
  `<id>:<name>:<image_hash>:<weight>:<supply>` separated by commas. The first
  two return the XCP fee they charge (`xcp_fee`), also available from their
  `estimatexcpfees` sub-routes, and `compose/fairbooster` refuses an asset
  that a parsed mempool transaction already creates (HTTP 409). The terms of
  `compose/buybooster` default to the current ones of the fairbooster.
- Add `/v2/fairboosters`, `/v2/fairboosters/<asset>` and its `/cards` (with the
  number of copies drawn), `/updates`, `/purchases` and `/draws`,
  `/v2/boosters/<tx_hash>` and its `/draws`, and
  `/v2/addresses/<address>/fairboosters`, `/boosters` and `/booster_cards`. A
  draw records the copy number of its card (`copy_number`). The new events are
  `NEW_FAIRBOOSTER`, `FAIRBOOSTER_UPDATE`, `NEW_FAIRBOOSTER_CARD`,
  `NEW_FAIRBOOSTER_UPDATE`, `NEW_FAIRBOOSTER_PURCHASE` and
  `NEW_FAIRBOOSTER_DRAW`; those with a `source` are listed in
  `/v2/addresses/<address>/events`.
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
