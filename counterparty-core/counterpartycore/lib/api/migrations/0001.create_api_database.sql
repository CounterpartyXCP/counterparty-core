CREATE TABLE IF NOT EXISTS blocks(
                      block_index INTEGER UNIQUE,
                      block_hash TEXT UNIQUE,
                      block_time INTEGER,
                      previous_block_hash TEXT UNIQUE,
                      difficulty INTEGER, ledger_hash TEXT, txlist_hash TEXT, messages_hash TEXT, transaction_count INTEGER,
                      PRIMARY KEY (block_index, block_hash));
CREATE INDEX IF NOT EXISTS blocks_block_index_idx ON blocks (block_index);
CREATE INDEX IF NOT EXISTS blocks_block_index_block_hash_idx ON blocks (block_index, block_hash);
CREATE TABLE IF NOT EXISTS transactions(
                      tx_index INTEGER UNIQUE,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      block_hash TEXT,
                      block_time INTEGER,
                      source TEXT,
                      destination TEXT,
                      btc_amount INTEGER,
                      fee INTEGER,
                      data BLOB,
                      supported BOOL DEFAULT 1,
                      FOREIGN KEY (block_index, block_hash) REFERENCES blocks(block_index, block_hash),
                      PRIMARY KEY (tx_index, tx_hash, block_index));
CREATE INDEX IF NOT EXISTS transactions_block_index_idx ON transactions (block_index);
CREATE INDEX IF NOT EXISTS transactions_tx_index_idx ON transactions (tx_index);
CREATE INDEX IF NOT EXISTS transactions_tx_hash_idx ON transactions (tx_hash);
CREATE INDEX IF NOT EXISTS transactions_block_index_tx_index_idx ON transactions (block_index, tx_index);
CREATE INDEX IF NOT EXISTS transactions_tx_index_tx_hash_block_index_idx ON transactions (tx_index, tx_hash, block_index);
CREATE TABLE IF NOT EXISTS transaction_outputs(
                        tx_index,
                        tx_hash TEXT,
                        block_index INTEGER,
                        out_index INTEGER,
                        destination TEXT,
                        btc_amount INTEGER,
                        PRIMARY KEY (tx_hash, out_index),
                        FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
CREATE TABLE IF NOT EXISTS mempool(
                      tx_hash TEXT,
                      command TEXT,
                      category TEXT,
                      bindings TEXT,
                      timestamp INTEGER, event TEXT);
CREATE TABLE IF NOT EXISTS debits(
                      block_index INTEGER,
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER,
                      action TEXT,
                      event TEXT, tx_index INTEGER,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index));
CREATE INDEX IF NOT EXISTS debits_address_idx ON debits (address);
CREATE INDEX IF NOT EXISTS debits_asset_idx ON debits (asset);
CREATE INDEX IF NOT EXISTS debits_block_index_idx ON debits (block_index);
CREATE TABLE IF NOT EXISTS credits(
                      block_index INTEGER,
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER,
                      calling_function TEXT,
                      event TEXT, tx_index INTEGER,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index));
CREATE INDEX IF NOT EXISTS credits_address_idx ON credits (address);
CREATE INDEX IF NOT EXISTS credits_asset_idx ON credits (asset);
CREATE INDEX IF NOT EXISTS credits_block_index_idx ON credits (block_index);
CREATE TABLE IF NOT EXISTS balances(
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER, block_index INTEGER, tx_index INTEGER);
CREATE INDEX IF NOT EXISTS balances_address_asset_idx ON balances (address, asset);
CREATE INDEX IF NOT EXISTS balances_address_idx ON balances (address);
CREATE INDEX IF NOT EXISTS balances_asset_idx ON balances (asset);
CREATE INDEX IF NOT EXISTS balances_block_index_idx ON balances (block_index);
CREATE TABLE IF NOT EXISTS assets(
                      asset_id TEXT UNIQUE,
                      asset_name TEXT UNIQUE,
                      block_index INTEGER,
                      asset_longname TEXT);
CREATE INDEX IF NOT EXISTS assets_asset_name_idx ON assets (asset_name);
CREATE INDEX IF NOT EXISTS assets_asset_id_idx ON assets (asset_id);
CREATE UNIQUE INDEX IF NOT EXISTS assets_asset_longname_idx ON assets (asset_longname);
CREATE TABLE IF NOT EXISTS addresses(
                      address TEXT UNIQUE,
                      options INTEGER,
                      block_index INTEGER);
CREATE INDEX IF NOT EXISTS addresses_address_idx ON addresses (address);
CREATE TABLE IF NOT EXISTS "sends"(
                              tx_index INTEGER,
                              tx_hash TEXT,
                              block_index INTEGER,
                              source TEXT,
                              destination TEXT,
                              asset TEXT,
                              quantity INTEGER,
                              status TEXT,
                              msg_index INTEGER DEFAULT 0, memo BLOB,
                              PRIMARY KEY (tx_index, msg_index),
                              FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                              UNIQUE (tx_hash, msg_index) ON CONFLICT FAIL);
CREATE INDEX IF NOT EXISTS sends_block_index_idx ON sends (block_index);
CREATE INDEX IF NOT EXISTS sends_source_idx ON sends (source);
CREATE INDEX IF NOT EXISTS sends_destination_idx ON sends (destination);
CREATE INDEX IF NOT EXISTS sends_asset_idx ON sends (asset);
CREATE INDEX IF NOT EXISTS sends_memo_idx ON sends (memo);
CREATE TABLE IF NOT EXISTS destructions(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      asset INTEGER,
                      quantity INTEGER,
                      tag TEXT,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
CREATE INDEX IF NOT EXISTS destructions_status_idx ON destructions (status);
CREATE INDEX IF NOT EXISTS destructions_source_idx ON destructions (source);
CREATE TABLE IF NOT EXISTS orders(
                            tx_index INTEGER,
                            tx_hash TEXT,
                            block_index INTEGER,
                            source TEXT,
                            give_asset TEXT,
                            give_quantity INTEGER,
                            give_remaining INTEGER,
                            get_asset TEXT,
                            get_quantity INTEGER,
                            get_remaining INTEGER,
                            expiration INTEGER,
                            expire_index INTEGER,
                            fee_required INTEGER,
                            fee_required_remaining INTEGER,
                            fee_provided INTEGER,
                            fee_provided_remaining INTEGER,
                            status TEXT);
CREATE INDEX IF NOT EXISTS orders_block_index_idx ON orders (block_index);
CREATE INDEX IF NOT EXISTS orders_tx_index_tx_hash_idx ON orders (tx_index, tx_hash);
CREATE INDEX IF NOT EXISTS orders_give_asset_idx ON orders (give_asset);
CREATE INDEX IF NOT EXISTS orders_tx_hash_idx ON orders (tx_hash);
CREATE INDEX IF NOT EXISTS orders_expire_index_idx ON orders (expire_index);
CREATE INDEX IF NOT EXISTS orders_get_asset_give_asset_idx ON orders (get_asset, give_asset);
CREATE INDEX IF NOT EXISTS orders_status_idx ON orders (status);
CREATE INDEX IF NOT EXISTS orders_source_give_asset_idx ON orders (source, give_asset);
CREATE TABLE IF NOT EXISTS order_matches(
                                    id TEXT,
                                    tx0_index INTEGER,
                                    tx0_hash TEXT,
                                    tx0_address TEXT,
                                    tx1_index INTEGER,
                                    tx1_hash TEXT,
                                    tx1_address TEXT,
                                    forward_asset TEXT,
                                    forward_quantity INTEGER,
                                    backward_asset TEXT,
                                    backward_quantity INTEGER,
                                    tx0_block_index INTEGER,
                                    tx1_block_index INTEGER,
                                    block_index INTEGER,
                                    tx0_expiration INTEGER,
                                    tx1_expiration INTEGER,
                                    match_expire_index INTEGER,
                                    fee_paid INTEGER,
                                    status TEXT);
CREATE INDEX IF NOT EXISTS order_matches_block_index_idx ON order_matches (block_index);
CREATE INDEX IF NOT EXISTS order_matches_forward_asset_idx ON order_matches (forward_asset);
CREATE INDEX IF NOT EXISTS order_matches_backward_asset_idx ON order_matches (backward_asset);
CREATE INDEX IF NOT EXISTS order_matches_id_idx ON order_matches (id);
CREATE INDEX IF NOT EXISTS order_matches_tx0_address_forward_asset_idx ON order_matches (tx0_address, forward_asset);
CREATE INDEX IF NOT EXISTS order_matches_tx1_address_backward_asset_idx ON order_matches (tx1_address, backward_asset);
CREATE INDEX IF NOT EXISTS order_matches_match_expire_index_idx ON order_matches (match_expire_index);
CREATE INDEX IF NOT EXISTS order_matches_status_idx ON order_matches (status);
CREATE INDEX IF NOT EXISTS order_matches_tx0_hash_idx ON order_matches (tx0_hash);
CREATE INDEX IF NOT EXISTS order_matches_tx1_hash_idx ON order_matches (tx1_hash);
CREATE TABLE IF NOT EXISTS order_expirations(
                                        order_hash TEXT PRIMARY KEY,
                                        source TEXT,
                                        block_index INTEGER,
                                        FOREIGN KEY (block_index) REFERENCES blocks(block_index));
CREATE INDEX IF NOT EXISTS order_expirations_block_index_idx ON order_expirations (block_index);
CREATE INDEX IF NOT EXISTS order_expirations_source_idx ON order_expirations (source);
CREATE TABLE IF NOT EXISTS order_match_expirations(
                                              order_match_id TEXT PRIMARY KEY,
                                              tx0_address TEXT,
                                              tx1_address TEXT,
                                              block_index INTEGER,
                                              FOREIGN KEY (block_index) REFERENCES blocks(block_index));
CREATE INDEX IF NOT EXISTS order_match_expirations_block_index_idx ON order_match_expirations (block_index);
CREATE INDEX IF NOT EXISTS order_match_expirations_tx0_address_idx ON order_match_expirations (tx0_address);
CREATE INDEX IF NOT EXISTS order_match_expirations_tx1_address_idx ON order_match_expirations (tx1_address);
CREATE TABLE IF NOT EXISTS btcpays(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      destination TEXT,
                      btc_amount INTEGER,
                      order_match_id TEXT,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
CREATE INDEX IF NOT EXISTS btcpays_block_index_idx ON btcpays (block_index);
CREATE INDEX IF NOT EXISTS btcpays_source_idx ON btcpays (source);
CREATE INDEX IF NOT EXISTS btcpays_destination_idx ON btcpays (destination);
CREATE TABLE IF NOT EXISTS "issuances"(
                              tx_index INTEGER,
                              tx_hash TEXT,
                              msg_index INTEGER DEFAULT 0,
                              block_index INTEGER,
                              asset TEXT,
                              quantity INTEGER,
                              divisible BOOL,
                              source TEXT,
                              issuer TEXT,
                              transfer BOOL,
                              callable BOOL,
                              call_date INTEGER,
                              call_price REAL,
                              description TEXT,
                              fee_paid INTEGER,
                              locked BOOL,
                              status TEXT,
                              asset_longname TEXT,
                              reset BOOL,
                              PRIMARY KEY (tx_index, msg_index),
                              FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                              UNIQUE (tx_hash, msg_index));
CREATE INDEX IF NOT EXISTS issuances_block_index_idx ON issuances (block_index);
CREATE INDEX IF NOT EXISTS issuances_asset_status_idx ON issuances (asset, status);
CREATE INDEX IF NOT EXISTS issuances_status_idx ON issuances (status);
CREATE INDEX IF NOT EXISTS issuances_source_idx ON issuances (source);
CREATE INDEX IF NOT EXISTS issuances_asset_longname_idx ON issuances (asset_longname);
CREATE INDEX IF NOT EXISTS issuances_status_asset_tx_index_idx ON issuances (status, asset, tx_index DESC);
CREATE TABLE IF NOT EXISTS broadcasts(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      timestamp INTEGER,
                      value REAL,
                      fee_fraction_int INTEGER,
                      text TEXT,
                      locked BOOL,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
CREATE INDEX IF NOT EXISTS broadcasts_block_index_idx ON broadcasts (block_index);
CREATE INDEX IF NOT EXISTS broadcasts_status_source_idx ON broadcasts (status, source);
CREATE INDEX IF NOT EXISTS broadcasts_status_source_tx_index_idx ON broadcasts (status, source, tx_index);
CREATE INDEX IF NOT EXISTS broadcasts_timestamp_idx ON broadcasts (timestamp);
CREATE TABLE IF NOT EXISTS bets(
                        tx_index INTEGER,
                        tx_hash TEXT,
                        block_index INTEGER,
                        source TEXT,
                        feed_address TEXT,
                        bet_type INTEGER,
                        deadline INTEGER,
                        wager_quantity INTEGER,
                        wager_remaining INTEGER,
                        counterwager_quantity INTEGER,
                        counterwager_remaining INTEGER,
                        target_value REAL,
                        leverage INTEGER,
                        expiration INTEGER,
                        expire_index INTEGER,
                        fee_fraction_int INTEGER,
                        status TEXT);
CREATE INDEX IF NOT EXISTS bets_block_index_idx ON bets (block_index);
CREATE INDEX IF NOT EXISTS bets_tx_index_tx_hash_idx ON bets (tx_index, tx_hash);
CREATE INDEX IF NOT EXISTS bets_status_idx ON bets (status);
CREATE INDEX IF NOT EXISTS bets_tx_hash_idx ON bets (tx_hash);
CREATE INDEX IF NOT EXISTS bets_feed_address_idx ON bets (feed_address);
CREATE INDEX IF NOT EXISTS bets_expire_index_idx ON bets (expire_index);
CREATE INDEX IF NOT EXISTS bets_feed_address_bet_type_idx ON bets (feed_address, bet_type);
CREATE TABLE IF NOT EXISTS bet_matches(
                                id TEXT,
                                tx0_index INTEGER,
                                tx0_hash TEXT,
                                tx0_address TEXT,
                                tx1_index INTEGER,
                                tx1_hash TEXT,
                                tx1_address TEXT,
                                tx0_bet_type INTEGER,
                                tx1_bet_type INTEGER,
                                feed_address TEXT,
                                initial_value INTEGER,
                                deadline INTEGER,
                                target_value REAL,
                                leverage INTEGER,
                                forward_quantity INTEGER,
                                backward_quantity INTEGER,
                                tx0_block_index INTEGER,
                                tx1_block_index INTEGER,
                                block_index INTEGER,
                                tx0_expiration INTEGER,
                                tx1_expiration INTEGER,
                                match_expire_index INTEGER,
                                fee_fraction_int INTEGER,
                                status TEXT);
CREATE INDEX IF NOT EXISTS bet_matches_block_index_idx ON bet_matches (block_index);
CREATE INDEX IF NOT EXISTS bet_matches_id_idx ON bet_matches (id);
CREATE INDEX IF NOT EXISTS bet_matches_status_idx ON bet_matches (status);
CREATE INDEX IF NOT EXISTS bet_matches_deadline_idx ON bet_matches (deadline);
CREATE INDEX IF NOT EXISTS bet_matches_tx0_address_idx ON bet_matches (tx0_address);
CREATE INDEX IF NOT EXISTS bet_matches_tx1_address_idx ON bet_matches (tx1_address);
CREATE TABLE IF NOT EXISTS bet_expirations(
                                    bet_index INTEGER PRIMARY KEY,
                                    bet_hash TEXT UNIQUE,
                                    source TEXT,
                                    block_index INTEGER,
                                    FOREIGN KEY (block_index) REFERENCES blocks(block_index));
CREATE INDEX IF NOT EXISTS bet_expirations_block_index_idx ON bet_expirations (block_index);
CREATE INDEX IF NOT EXISTS bet_expirations_source_idx ON bet_expirations (source);
CREATE TABLE IF NOT EXISTS bet_match_expirations(
                                          bet_match_id TEXT PRIMARY KEY,
                                          tx0_address TEXT,
                                          tx1_address TEXT,
                                          block_index INTEGER,
                                          FOREIGN KEY (block_index) REFERENCES blocks(block_index));
CREATE INDEX IF NOT EXISTS bet_match_expirations_block_index_idx ON bet_match_expirations (block_index);
CREATE INDEX IF NOT EXISTS bet_match_expirations_tx0_address_idx ON bet_match_expirations (tx0_address);
CREATE INDEX IF NOT EXISTS bet_match_expirations_tx1_address_idx ON bet_match_expirations (tx1_address);
CREATE TABLE IF NOT EXISTS bet_match_resolutions(
                                            bet_match_id TEXT PRIMARY KEY,
                                            bet_match_type_id INTEGER,
                                            block_index INTEGER,
                                            winner TEXT,
                                            settled BOOL,
                                            bull_credit INTEGER,
                                            bear_credit INTEGER,
                                            escrow_less_fee INTEGER,
                                            fee INTEGER,
                                            FOREIGN KEY (block_index) REFERENCES blocks(block_index));
CREATE TABLE IF NOT EXISTS dividends(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      asset TEXT,
                      dividend_asset TEXT,
                      quantity_per_unit INTEGER,
                      fee_paid INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
CREATE INDEX IF NOT EXISTS dividends_block_index_idx ON dividends (block_index);
CREATE INDEX IF NOT EXISTS dividends_source_idx ON dividends (source);
CREATE INDEX IF NOT EXISTS dividends_asset_idx ON dividends (asset);
CREATE TABLE IF NOT EXISTS burns(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      burned INTEGER,
                      earned INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
CREATE INDEX IF NOT EXISTS burns_status_idx ON burns (status);
CREATE INDEX IF NOT EXISTS burns_source_idx ON burns (source);
CREATE TABLE IF NOT EXISTS cancels(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      offer_hash TEXT,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
CREATE INDEX IF NOT EXISTS cancels_block_index_idx ON cancels (block_index);
CREATE INDEX IF NOT EXISTS cancels_source_idx ON cancels (source);
CREATE TABLE IF NOT EXISTS rps(
                        tx_index INTEGER,
                        tx_hash TEXT,
                        block_index INTEGER,
                        source TEXT,
                        possible_moves INTEGER,
                        wager INTEGER,
                        move_random_hash TEXT,
                        expiration INTEGER,
                        expire_index INTEGER,
                        status TEXT);
CREATE INDEX IF NOT EXISTS rps_source_idx ON rps (source);
CREATE INDEX IF NOT EXISTS rps_wager_possible_moves_idx ON rps (wager, possible_moves);
CREATE INDEX IF NOT EXISTS rps_status_idx ON rps (status);
CREATE INDEX IF NOT EXISTS rps_tx_index_idx ON rps (tx_index);
CREATE INDEX IF NOT EXISTS rps_tx_hash_idx ON rps (tx_hash);
CREATE INDEX IF NOT EXISTS rps_expire_index_idx ON rps (expire_index);
CREATE INDEX IF NOT EXISTS rps_tx_index_tx_hash_idx ON rps (tx_index, tx_hash);
CREATE TABLE IF NOT EXISTS rps_matches(
                                id TEXT,
                                tx0_index INTEGER,
                                tx0_hash TEXT,
                                tx0_address TEXT,
                                tx1_index INTEGER,
                                tx1_hash TEXT,
                                tx1_address TEXT,
                                tx0_move_random_hash TEXT,
                                tx1_move_random_hash TEXT,
                                wager INTEGER,
                                possible_moves INTEGER,
                                tx0_block_index INTEGER,
                                tx1_block_index INTEGER,
                                block_index INTEGER,
                                tx0_expiration INTEGER,
                                tx1_expiration INTEGER,
                                match_expire_index INTEGER,
                                status TEXT);
CREATE INDEX IF NOT EXISTS rps_matches_tx0_address_idx ON rps_matches (tx0_address);
CREATE INDEX IF NOT EXISTS rps_matches_tx1_address_idx ON rps_matches (tx1_address);
CREATE INDEX IF NOT EXISTS rps_matches_status_idx ON rps_matches (status);
CREATE INDEX IF NOT EXISTS rps_matches_id_idx ON rps_matches (id);
CREATE INDEX IF NOT EXISTS rps_matches_match_expire_index_idx ON rps_matches (match_expire_index);
CREATE TABLE IF NOT EXISTS rps_expirations(
                                    rps_index INTEGER PRIMARY KEY,
                                    rps_hash TEXT UNIQUE,
                                    source TEXT,
                                    block_index INTEGER,
                                    FOREIGN KEY (block_index) REFERENCES blocks(block_index));
CREATE INDEX IF NOT EXISTS rps_expirations_block_index_idx ON rps_expirations (block_index);
CREATE INDEX IF NOT EXISTS rps_expirations_source_idx ON rps_expirations (source);
CREATE TABLE IF NOT EXISTS rps_match_expirations(
                                            rps_match_id TEXT PRIMARY KEY,
                                            tx0_address TEXT,
                                            tx1_address TEXT,
                                            block_index INTEGER,
                                            FOREIGN KEY (block_index) REFERENCES blocks(block_index));
CREATE INDEX IF NOT EXISTS rps_match_expirations_block_index_idx ON rps_match_expirations (block_index);
CREATE INDEX IF NOT EXISTS rps_match_expirations_tx0_address_idx ON rps_match_expirations (tx0_address);
CREATE INDEX IF NOT EXISTS rps_match_expirations_tx1_address_idx ON rps_match_expirations (tx1_address);
CREATE TABLE IF NOT EXISTS rpsresolves(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      move INTEGER,
                      random TEXT,
                      rps_match_id TEXT,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
CREATE INDEX IF NOT EXISTS rpsresolves_block_index_idx ON rpsresolves (block_index);
CREATE INDEX IF NOT EXISTS rpsresolves_source_idx ON rpsresolves (source);
CREATE INDEX IF NOT EXISTS rpsresolves_rps_match_id_idx ON rpsresolves (rps_match_id);
CREATE TABLE IF NOT EXISTS sweeps(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      destination TEXT,
                      flags INTEGER,
                      status TEXT,
                      memo BLOB,
                      fee_paid INTEGER,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
CREATE INDEX IF NOT EXISTS sweeps_block_index_idx ON sweeps (block_index);
CREATE INDEX IF NOT EXISTS sweeps_source_idx ON sweeps (source);
CREATE INDEX IF NOT EXISTS sweeps_destination_idx ON sweeps (destination);
CREATE INDEX IF NOT EXISTS sweeps_memo_idx ON sweeps (memo);
CREATE TABLE IF NOT EXISTS dispensers(
                                tx_index INTEGER,
                                tx_hash TEXT,
                                block_index INTEGER,
                                source TEXT,
                                asset TEXT,
                                give_quantity INTEGER,
                                escrow_quantity INTEGER,
                                satoshirate INTEGER,
                                status INTEGER,
                                give_remaining INTEGER,
                                oracle_address TEXT,
                                last_status_tx_hash TEXT,
                                origin TEXT,
                                dispense_count INTEGER DEFAULT 0, last_status_tx_source TEXT, close_block_index TEXT);
CREATE INDEX IF NOT EXISTS dispensers_block_index_idx ON dispensers (block_index);
CREATE INDEX IF NOT EXISTS dispensers_source_idx ON dispensers (source);
CREATE INDEX IF NOT EXISTS dispensers_asset_idx ON dispensers (asset);
CREATE INDEX IF NOT EXISTS dispensers_tx_index_idx ON dispensers (tx_index);
CREATE INDEX IF NOT EXISTS dispensers_tx_hash_idx ON dispensers (tx_hash);
CREATE INDEX IF NOT EXISTS dispensers_status_idx ON dispensers (status);
CREATE INDEX IF NOT EXISTS dispensers_give_remaining_idx ON dispensers (give_remaining);
CREATE INDEX IF NOT EXISTS dispensers_status_block_index_idx ON dispensers (status, block_index);
CREATE INDEX IF NOT EXISTS dispensers_source_origin_idx ON dispensers (source, origin);
CREATE INDEX IF NOT EXISTS dispensers_source_asset_origin_idx ON dispensers (source, asset, origin);
CREATE INDEX IF NOT EXISTS dispensers_last_status_tx_hash_idx ON dispensers (last_status_tx_hash);
CREATE TABLE IF NOT EXISTS dispenses (
                                tx_index INTEGER,
                                dispense_index INTEGER,
                                tx_hash TEXT,
                                block_index INTEGER,
                                source TEXT,
                                destination TEXT,
                                asset TEXT,
                                dispense_quantity INTEGER,
                                dispenser_tx_hash TEXT,
                                btc_amount INTEGER DEFAULT 0,
                                PRIMARY KEY (tx_index, dispense_index, source, destination),
                                FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
CREATE INDEX IF NOT EXISTS dispenses_tx_hash_idx ON dispenses (tx_hash);
CREATE INDEX IF NOT EXISTS dispenses_block_index_idx ON dispenses (block_index);
CREATE INDEX IF NOT EXISTS dispenses_dispenser_tx_hash_idx ON dispenses (dispenser_tx_hash);
CREATE TABLE IF NOT EXISTS dispenser_refills(
                                        tx_index INTEGER,
                                        tx_hash TEXT,
                                        block_index INTEGER,
                                        source TEXT,
                                        destination TEXT,
                                        asset TEXT,
                                        dispense_quantity INTEGER,
                                        dispenser_tx_hash TEXT,
                                        PRIMARY KEY (tx_index, tx_hash, source, destination),
                                        FOREIGN KEY (tx_index, tx_hash, block_index)
                                            REFERENCES transactions(tx_index, tx_hash, block_index));
CREATE INDEX IF NOT EXISTS dispenser_refills_tx_hash_idx ON dispenser_refills (tx_hash);
CREATE INDEX IF NOT EXISTS dispenser_refills_block_index_idx ON dispenser_refills (block_index);
CREATE TABLE IF NOT EXISTS messages(
                      message_index INTEGER PRIMARY KEY,
                      block_index INTEGER,
                      command TEXT,
                      category TEXT,
                      bindings TEXT,
                      timestamp INTEGER,
                      event TEXT,
                      tx_hash TEXT,
                      previous_state TEXT,
                      insert_rowid INTEGER,
                      event_hash TEXT);
CREATE INDEX IF NOT EXISTS messages_block_index_idx ON messages (block_index);
CREATE INDEX IF NOT EXISTS messages_block_index_message_index_idx ON messages (block_index, message_index);
CREATE INDEX IF NOT EXISTS messages_event_idx ON messages (event);
CREATE INDEX IF NOT EXISTS messages_tx_hash_idx ON messages (tx_hash);
CREATE INDEX IF NOT EXISTS messages_block_index_event_idx ON messages (block_index, event);
CREATE INDEX IF NOT EXISTS messages_event_hash_idx ON messages (event_hash, event);
CREATE INDEX IF NOT EXISTS dispenses_asset_idx ON dispenses (asset);
CREATE INDEX IF NOT EXISTS dispenses_source_idx ON dispenses (source);
CREATE INDEX IF NOT EXISTS dispenses_destination_idx ON dispenses (destination);
CREATE INDEX IF NOT EXISTS transactions_source_idx ON transactions (source);
CREATE INDEX IF NOT EXISTS debits_event_idx ON debits (event);
CREATE INDEX IF NOT EXISTS debits_action_idx ON debits (action);
CREATE INDEX IF NOT EXISTS credits_event_idx ON credits (event);
CREATE INDEX IF NOT EXISTS credits_calling_function_idx ON credits (calling_function);
CREATE INDEX IF NOT EXISTS issuances_issuer_idx ON issuances (issuer);
CREATE INDEX IF NOT EXISTS dispensers_source_asset_origin_status_idx ON dispensers (source, asset, origin, status);
CREATE INDEX IF NOT EXISTS dispensers_close_block_index_status_idx ON dispensers (close_block_index, status);
CREATE INDEX IF NOT EXISTS balances_quantity_idx ON balances (quantity);
CREATE INDEX IF NOT EXISTS orders_get_quantity_idx ON orders (get_quantity);
CREATE INDEX IF NOT EXISTS orders_give_quantity_idx ON orders (give_quantity);
CREATE INDEX IF NOT EXISTS dispensers_give_quantity_idx ON dispensers (give_quantity);
CREATE INDEX IF NOT EXISTS dispenses_dispense_quantity_idx ON dispenses (dispense_quantity);
CREATE INDEX IF NOT EXISTS debits_quantity_idx ON debits (quantity);
CREATE INDEX IF NOT EXISTS credits_quantity_idx ON credits (quantity);


CREATE TABLE IF NOT EXISTS all_expirations(
                      type TEXT,
                      object_id TEXT,
                      block_index INTEGER);
CREATE INDEX IF NOT EXISTS all_expirations_type_idx ON all_expirations (type);
CREATE INDEX IF NOT EXISTS all_expirations_block_index_idx ON all_expirations (block_index);


CREATE VIEW IF NOT EXISTS asset_holders AS 
            SELECT asset, address, quantity, NULL AS escrow,
                ('balances_' || CAST(rowid AS VARCAHR)) AS cursor_id, 'balances' AS holding_type, NULL AS status
            FROM balances
         UNION ALL 
            SELECT give_asset AS asset, source AS address, give_remaining AS quantity, tx_hash AS escrow,
                ('open_order_' || CAST(rowid AS VARCAHR)) AS cursor_id,
                'open_order' AS holding_type, status
            FROM orders WHERE status = 'open'
         UNION ALL 
            SELECT forward_asset AS asset, tx0_address AS address, forward_quantity AS quantity,
                id AS escrow, ('order_match_' || CAST(rowid AS VARCAHR)) AS cursor_id,
                'pending_order_match' AS holding_type, status
            FROM order_matches WHERE status = 'pending'
         UNION ALL 
            SELECT backward_asset AS asset, tx1_address AS address, backward_quantity AS quantity,
                id AS escrow, ('order_match_' || CAST(rowid AS VARCAHR)) AS cursor_id,
                'pending_order_match' AS holding_type, status
            FROM order_matches WHERE status = 'pending'
         UNION ALL 
            SELECT asset, source AS address, give_remaining AS quantity,
            tx_hash AS escrow, ('open_dispenser_' || CAST(rowid AS VARCAHR)) AS cursor_id,
            'open_dispenser' AS holding_type, status
            FROM dispensers WHERE status = 0;


CREATE VIEW  IF NOT EXISTS xcp_holders AS
            SELECT * FROM asset_holders
         UNION ALL 
            SELECT 'XCP' AS asset, source AS address, wager_remaining AS quantity,
            tx_hash AS escrow, ('open_bet_' || CAST(rowid AS VARCAHR)) AS cursor_id,
            'open_bet' AS holding_type, status
            FROM bets WHERE status = 'open'
         UNION ALL 
            SELECT 'XCP' AS asset, tx0_address AS address, forward_quantity AS quantity,
            id AS escrow, ('bet_match_' || CAST(rowid AS VARCAHR)) AS cursor_id,
            'pending_bet_match' AS holding_type, status
            FROM bet_matches WHERE status = 'pending'
         UNION ALL 
            SELECT 'XCP' AS asset, tx1_address AS address, backward_quantity AS quantity,
            id AS escrow, ('bet_match_' || CAST(rowid AS VARCAHR)) AS cursor_id,
            'pending_bet_match' AS holding_type, status
            FROM bet_matches WHERE status = 'pending'
         UNION ALL 
            SELECT 'XCP' AS asset, source AS address, wager AS quantity,
            tx_hash AS escrow, ('open_rps_' || CAST(rowid AS VARCAHR)) AS cursor_id,
            'open_rps' AS holding_type, status
            FROM rps WHERE status = 'open'
         UNION ALL 
            SELECT 'XCP' AS asset, tx0_address AS address, wager AS quantity,
            id AS escrow, ('rps_match_' || CAST(rowid AS VARCAHR)) AS cursor_id,
            'pending_rps_match' AS holding_type, status
            FROM rps_matches WHERE status IN ('pending', 'pending and resolved', 'resolved and pending')
         UNION ALL 
            SELECT 'XCP' AS asset, tx1_address AS address, wager AS quantity,
            id AS escrow, ('rps_match_' || CAST(rowid AS VARCAHR)) AS cursor_id,
            'pending_rps_match' AS holding_type, status
            FROM rps_matches WHERE status IN ('pending', 'pending and resolved', 'resolved and pending')
         UNION ALL 
            SELECT asset, source AS address, give_remaining AS quantity,
            tx_hash AS escrow, ('open_dispenser_' || CAST(rowid AS VARCAHR)) AS cursor_id,
            'open_dispenser' AS holding_type, status
            FROM dispensers WHERE status = 0;

CREATE TABLE IF NOT EXISTS assets_info(
                        asset TEXT UNIQUE,
                        asset_id TEXT UNIQUE,
                        asset_longname TEXT,
                        issuer TEXT,
                        owner TEXT,
                        divisible BOOL,
                        locked BOOL DEFAULT 0,
                        supply INTEGER DEFAULT 0,
                        description TEXT,
                        first_issuance_block_index INTEGER,
                        last_issuance_block_index INTEGER
                        );
CREATE INDEX IF NOT EXISTS assets_info_asset_idx ON assets_info (asset);
CREATE INDEX IF NOT EXISTS assets_info_asset_longname_idx ON assets_info (asset_longname);
CREATE INDEX IF NOT EXISTS assets_info_issuer_idx ON assets_info (issuer);
CREATE INDEX IF NOT EXISTS assets_info_owner_idx ON assets_info (owner);
