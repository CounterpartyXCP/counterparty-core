CREATE TABLE IF NOT EXISTS blocks(
                      block_index INTEGER UNIQUE,
                      block_hash TEXT UNIQUE,
                      block_time INTEGER,
                      ledger_hash TEXT,
                      txlist_hash TEXT,
                      messages_hash TEXT,
                      previous_block_hash TEXT UNIQUE,
                      difficulty INTEGER,
                      transaction_count INTEGER,
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
                      utxos_info TEXT, transaction_type TEXT,
                      FOREIGN KEY (block_index, block_hash) REFERENCES blocks(block_index, block_hash),
                      PRIMARY KEY (tx_index, tx_hash, block_index));
CREATE INDEX IF NOT EXISTS transactions_block_index_idx ON transactions (block_index);
CREATE INDEX IF NOT EXISTS transactions_tx_index_idx ON transactions (tx_index);
CREATE INDEX IF NOT EXISTS transactions_tx_hash_idx ON transactions (tx_hash);
CREATE INDEX IF NOT EXISTS transactions_block_index_tx_index_idx ON transactions (block_index, tx_index);
CREATE INDEX IF NOT EXISTS transactions_tx_index_tx_hash_block_index_idx ON transactions (tx_index, tx_hash, block_index);
CREATE INDEX IF NOT EXISTS transactions_source_idx ON transactions (source);
CREATE TABLE IF NOT EXISTS debits(
                      block_index INTEGER,
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER,
                      action TEXT,
                      event TEXT, tx_index INTEGER, utxo TEXT, utxo_address TEXT,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index));
CREATE INDEX IF NOT EXISTS debits_address_idx ON debits (address);
CREATE INDEX IF NOT EXISTS debits_asset_idx ON debits (asset);
CREATE INDEX IF NOT EXISTS debits_block_index_idx ON debits (block_index);
CREATE INDEX IF NOT EXISTS debits_event_idx ON debits (event);
CREATE INDEX IF NOT EXISTS debits_action_idx ON debits (action);
CREATE INDEX IF NOT EXISTS debits_quantity_idx ON debits (quantity);
CREATE INDEX IF NOT EXISTS debits_utxo_idx ON debits (utxo);
CREATE INDEX IF NOT EXISTS debits_utxo_address_idx ON debits (utxo_address);
CREATE TABLE IF NOT EXISTS credits(
                      block_index INTEGER,
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER,
                      calling_function TEXT,
                      event TEXT, tx_index INTEGER, utxo TEXT, utxo_address TEXT,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index));
CREATE INDEX IF NOT EXISTS credits_address_idx ON credits (address);
CREATE INDEX IF NOT EXISTS credits_asset_idx ON credits (asset);
CREATE INDEX IF NOT EXISTS credits_block_index_idx ON credits (block_index);
CREATE INDEX IF NOT EXISTS credits_event_idx ON credits (event);
CREATE INDEX IF NOT EXISTS credits_calling_function_idx ON credits (calling_function);
CREATE INDEX IF NOT EXISTS credits_quantity_idx ON credits (quantity);
CREATE INDEX IF NOT EXISTS credits_utxo_idx ON credits (utxo);
CREATE INDEX IF NOT EXISTS credits_utxo_address_idx ON credits (utxo_address);
CREATE TABLE IF NOT EXISTS balances(
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER, block_index INTEGER, tx_index INTEGER, utxo TEXT, utxo_address TEXT);
CREATE INDEX IF NOT EXISTS balances_address_asset_idx ON balances (address, asset);
CREATE INDEX IF NOT EXISTS balances_address_idx ON balances (address);
CREATE INDEX IF NOT EXISTS balances_asset_idx ON balances (asset);
CREATE INDEX IF NOT EXISTS balances_block_index_idx ON balances (block_index);
CREATE INDEX IF NOT EXISTS balances_quantity_idx ON balances (quantity);
CREATE INDEX IF NOT EXISTS balances_utxo_idx ON balances (utxo);
CREATE INDEX IF NOT EXISTS balances_utxo_address_idx ON balances (utxo_address);
CREATE TABLE IF NOT EXISTS assets(
                      asset_id TEXT UNIQUE,
                      asset_name TEXT UNIQUE,
                      block_index INTEGER,
                      asset_longname TEXT);
CREATE INDEX IF NOT EXISTS assets_asset_name_idx ON assets (asset_name);
CREATE INDEX IF NOT EXISTS assets_asset_id_idx ON assets (asset_id);
CREATE UNIQUE INDEX IF NOT EXISTS assets_asset_longname_idx ON assets (asset_longname);
CREATE TABLE IF NOT EXISTS addresses(
            address TEXT,
            options INTEGER,
            block_index INTEGER
        );
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
                              msg_index INTEGER DEFAULT 0, memo BLOB, fee_paid INTEGER DEFAULT 0, send_type TEXT, source_address TEXT, destination_address TEXT,
                              PRIMARY KEY (tx_index, msg_index),
                              FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                              UNIQUE (tx_hash, msg_index) ON CONFLICT FAIL);
CREATE INDEX IF NOT EXISTS sends_block_index_idx ON sends (block_index);
CREATE INDEX IF NOT EXISTS sends_source_idx ON sends (source);
CREATE INDEX IF NOT EXISTS sends_destination_idx ON sends (destination);
CREATE INDEX IF NOT EXISTS sends_asset_idx ON sends (asset);
CREATE INDEX IF NOT EXISTS sends_memo_idx ON sends (memo);
CREATE TABLE IF NOT EXISTS destructions(
            tx_index INTEGER,
            tx_hash TEXT,
            block_index INTEGER,
            source TEXT,
            asset INTEGER,
            quantity INTEGER,
            tag TEXT,
            status TEXT
        );
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
CREATE INDEX IF NOT EXISTS orders_get_quantity_idx ON orders (get_quantity);
CREATE INDEX IF NOT EXISTS orders_give_quantity_idx ON orders (give_quantity);
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
CREATE TABLE IF NOT EXISTS issuances(
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
                status TEXT,
                asset_longname TEXT,
                description_locked BOOL,
                fair_minting BOOL DEFAULT 0, asset_events TEXT, locked BOOL DEFAULT FALSE, reset BOOL DEFAULT FALSE,
                PRIMARY KEY (tx_index, msg_index),
                UNIQUE (tx_hash, msg_index)
            );
CREATE INDEX IF NOT EXISTS issuances_block_index_idx ON issuances (block_index);
CREATE INDEX IF NOT EXISTS issuances_asset_status_idx ON issuances (asset, status);
CREATE INDEX IF NOT EXISTS issuances_status_idx ON issuances (status);
CREATE INDEX IF NOT EXISTS issuances_source_idx ON issuances (source);
CREATE INDEX IF NOT EXISTS issuances_asset_longname_idx ON issuances (asset_longname);
CREATE INDEX IF NOT EXISTS issuances_status_asset_tx_index_idx ON issuances (status, asset, tx_index DESC);
CREATE INDEX IF NOT EXISTS issuances_issuer_idx ON issuances (issuer);
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
                                dispense_count INTEGER DEFAULT 0,
                                last_status_tx_source TEXT,
                                close_block_index INTEGER);
CREATE INDEX IF NOT EXISTS dispensers_block_index_idx ON dispensers (block_index);
CREATE INDEX IF NOT EXISTS dispensers_source_idx ON dispensers (source);
CREATE INDEX IF NOT EXISTS dispensers_asset_idx ON dispensers (asset);
CREATE INDEX IF NOT EXISTS dispensers_tx_index_idx ON dispensers (tx_index);
CREATE INDEX IF NOT EXISTS dispensers_tx_hash_idx ON dispensers (tx_hash);
CREATE INDEX IF NOT EXISTS dispensers_status_idx ON dispensers (status);
CREATE INDEX IF NOT EXISTS dispensers_give_remaining_idx ON dispensers (give_remaining);
CREATE INDEX IF NOT EXISTS dispensers_status_block_index_idx ON dispensers (status, block_index);
CREATE INDEX IF NOT EXISTS dispensers_source_origin_idx ON dispensers (source, origin);
CREATE INDEX IF NOT EXISTS dispensers_source_asset_origin_status_idx ON dispensers (source, asset, origin, status);
CREATE INDEX IF NOT EXISTS dispensers_last_status_tx_hash_idx ON dispensers (last_status_tx_hash);
CREATE INDEX IF NOT EXISTS dispensers_close_block_index_status_idx ON dispensers (close_block_index, status);
CREATE INDEX IF NOT EXISTS dispensers_give_quantity_idx ON dispensers (give_quantity);
CREATE TABLE IF NOT EXISTS dispenses (
                                tx_index INTEGER,
                                dispense_index INTEGER,
                                tx_hash TEXT,
                                block_index INTEGER,
                                source TEXT,
                                destination TEXT,
                                asset TEXT,
                                dispense_quantity INTEGER,
                                dispenser_tx_hash TEXT, btc_amount INTEGER,
                                PRIMARY KEY (tx_index, dispense_index, source, destination),
                                FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
CREATE INDEX IF NOT EXISTS dispenses_tx_hash_idx ON dispenses (tx_hash);
CREATE INDEX IF NOT EXISTS dispenses_block_index_idx ON dispenses (block_index);
CREATE INDEX IF NOT EXISTS dispenses_dispenser_tx_hash_idx ON dispenses (dispenser_tx_hash);
CREATE INDEX IF NOT EXISTS dispenses_asset_idx ON dispenses (asset);
CREATE INDEX IF NOT EXISTS dispenses_source_idx ON dispenses (source);
CREATE INDEX IF NOT EXISTS dispenses_destination_idx ON dispenses (destination);
CREATE INDEX IF NOT EXISTS dispenses_dispense_quantity_idx ON dispenses (dispense_quantity);
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
CREATE TABLE IF NOT EXISTS fairminters (
            tx_hash TEXT,
            tx_index INTEGER,
            block_index INTEGER,
            source TEXT,
            asset TEXT,
            asset_parent TEXT,
            asset_longname TEXT,
            description TEXT,
            price INTEGER,
            quantity_by_price INTEGER,
            hard_cap INTEGER,
            burn_payment BOOL,
            max_mint_per_tx INTEGER,
            premint_quantity INTEGER,
            start_block INTEGER,
            end_block INTEGER,
            minted_asset_commission_int INTEGER,
            soft_cap INTEGER,
            soft_cap_deadline_block INTEGER,
            lock_description BOOL,
            lock_quantity BOOL,
            divisible BOOL,
            pre_minted BOOL DEFAULT 0,
            status TEXT
        );
CREATE INDEX IF NOT EXISTS fairminters_tx_hash_idx ON fairminters (tx_hash);
CREATE INDEX IF NOT EXISTS fairminters_block_index_idx ON fairminters (block_index);
CREATE INDEX IF NOT EXISTS fairminters_asset_idx ON fairminters (asset);
CREATE INDEX IF NOT EXISTS fairminters_asset_longname_idx ON fairminters (asset_longname);
CREATE INDEX IF NOT EXISTS fairminters_asset_parent_idx ON fairminters (asset_parent);
CREATE INDEX IF NOT EXISTS fairminters_source_idx ON fairminters (source);
CREATE INDEX IF NOT EXISTS fairminters_status_idx ON fairminters (status);
CREATE TABLE IF NOT EXISTS fairmints (
            tx_hash TEXT PRIMARY KEY,
            tx_index INTEGER,
            block_index INTEGER,
            source TEXT,
            fairminter_tx_hash TEXT,
            asset TEXT,
            earn_quantity INTEGER,
            paid_quantity INTEGER,
            commission INTEGER,
            status TEXT
        );
CREATE INDEX IF NOT EXISTS fairmints_tx_hash_idx ON fairmints (tx_hash);
CREATE INDEX IF NOT EXISTS fairmints_block_index_idx ON fairmints (block_index);
CREATE INDEX IF NOT EXISTS fairmints_fairminter_tx_hash_idx ON fairmints (fairminter_tx_hash);
CREATE INDEX IF NOT EXISTS fairmints_asset_idx ON fairmints (asset);
CREATE INDEX IF NOT EXISTS fairmints_source_idx ON fairmints (source);
CREATE INDEX IF NOT EXISTS fairmints_status_idx ON fairmints (status);
CREATE TABLE IF NOT EXISTS transaction_count(
            block_index INTEGER,
            transaction_id INTEGER,
            count INTEGER);
CREATE INDEX IF NOT EXISTS transaction_count_block_index_transaction_id_idx ON transaction_count (block_index, transaction_id);
CREATE TABLE IF NOT EXISTS messages(
                      message_index INTEGER PRIMARY KEY,
                      block_index INTEGER,
                      command TEXT,
                      category TEXT,
                      bindings TEXT,
                      timestamp INTEGER,
                      event TEXT,
                      tx_hash TEXT,
                      event_hash TEXT);
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
                      timestamp INTEGER,
                      event TEXT, addresses TEXT);

CREATE TRIGGER IF NOT EXISTS block_update_balances
                           BEFORE UPDATE ON balances BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_credits
                           BEFORE UPDATE ON credits BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_debits
                           BEFORE UPDATE ON debits BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_messages
                           BEFORE UPDATE ON messages BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_order_match_expirations
                           BEFORE UPDATE ON order_match_expirations BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_order_matches
                           BEFORE UPDATE ON order_matches BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_order_expirations
                           BEFORE UPDATE ON order_expirations BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_orders
                           BEFORE UPDATE ON orders BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_bet_match_expirations
                           BEFORE UPDATE ON bet_match_expirations BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_bet_matches
                           BEFORE UPDATE ON bet_matches BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_bet_match_resolutions
                           BEFORE UPDATE ON bet_match_resolutions BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_bet_expirations
                           BEFORE UPDATE ON bet_expirations BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_bets
                           BEFORE UPDATE ON bets BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_broadcasts
                           BEFORE UPDATE ON broadcasts BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_btcpays
                           BEFORE UPDATE ON btcpays BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_burns
                           BEFORE UPDATE ON burns BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_cancels
                           BEFORE UPDATE ON cancels BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_dividends
                           BEFORE UPDATE ON dividends BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_rps_match_expirations
                           BEFORE UPDATE ON rps_match_expirations BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_rps_expirations
                           BEFORE UPDATE ON rps_expirations BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_rpsresolves
                           BEFORE UPDATE ON rpsresolves BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_rps_matches
                           BEFORE UPDATE ON rps_matches BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_rps
                           BEFORE UPDATE ON rps BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_destructions
                           BEFORE UPDATE ON destructions BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_assets
                           BEFORE UPDATE ON assets BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_addresses
                           BEFORE UPDATE ON addresses BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_sweeps
                           BEFORE UPDATE ON sweeps BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_dispensers
                           BEFORE UPDATE ON dispensers BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_dispenser_refills
                           BEFORE UPDATE ON dispenser_refills BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE TRIGGER IF NOT EXISTS block_update_fairmints
                           BEFORE UPDATE ON fairmints BEGIN
                               SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
                           END;
CREATE INDEX IF NOT EXISTS issuances_status_asset_longname_tx_index_idx ON issuances (status, asset_longname, tx_index DESC);
CREATE TABLE IF NOT EXISTS config (
            name TEXT PRIMARY KEY,
            value TEXT
        );
CREATE INDEX IF NOT EXISTS config_config_name_idx ON config (name);
CREATE TRIGGER IF NOT EXISTS block_update_transaction_count
            BEFORE UPDATE ON transaction_count BEGIN
                SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
            END;
CREATE INDEX IF NOT EXISTS balances_utxo_asset_idx ON balances (utxo, asset);
CREATE TRIGGER IF NOT EXISTS block_update_fairminters
            BEFORE UPDATE ON fairminters BEGIN
                SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
            END;
CREATE INDEX IF NOT EXISTS blocks_ledger_hash_idx ON blocks (ledger_hash);
CREATE INDEX IF NOT EXISTS transactions_transaction_type_idx ON transactions (transaction_type);
CREATE INDEX IF NOT EXISTS balances_address_utxo_asset_idx ON balances (address, utxo, asset);
CREATE TRIGGER IF NOT EXISTS block_update_dispenses
            BEFORE UPDATE ON dispenses BEGIN
                SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
            END;
CREATE TRIGGER IF NOT EXISTS block_update_sends
            BEFORE UPDATE ON sends BEGIN
                SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
            END;
CREATE INDEX IF NOT EXISTS sends_block_index_send_type_idx ON sends (block_index, send_type);
CREATE INDEX IF NOT EXISTS sends_asset_send_type_idx ON sends (asset, send_type);
CREATE INDEX IF NOT EXISTS sends_status_idx ON sends (status);
CREATE INDEX IF NOT EXISTS sends_send_type_idx ON sends (send_type);
CREATE INDEX IF NOT EXISTS destructions_asset_idx ON destructions (asset);
CREATE TRIGGER IF NOT EXISTS block_update_issuances
            BEFORE UPDATE ON issuances BEGIN
                SELECT RAISE(FAIL, "UPDATES NOT ALLOWED");
            END;
CREATE VIEW IF NOT EXISTS all_expirations AS 
        SELECT 'order' AS type, order_hash AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCAHR), '_order_', CAST(rowid AS VARCAHR)) AS cursor_id
        FROM order_expirations
         UNION ALL 
        SELECT 'order_match' AS type, order_match_id AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCAHR), '_order_match_', CAST(rowid AS VARCAHR)) AS cursor_id
        FROM order_match_expirations
         UNION ALL 
        SELECT 'bet' AS type, bet_hash AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCAHR), '_bet_', CAST(rowid AS VARCAHR)) AS cursor_id
        FROM bet_expirations
         UNION ALL 
        SELECT 'bet_match' AS type, bet_match_id AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCAHR), '_bet_match_', CAST(rowid AS VARCAHR)) AS cursor_id
        FROM bet_match_expirations
         UNION ALL 
        SELECT 'rps' AS type, rps_hash AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCAHR), '_rps_', CAST(rowid AS VARCAHR)) AS cursor_id
        FROM rps_expirations
         UNION ALL 
        SELECT 'rps_match' AS type, rps_match_id AS object_id, block_index,
        CONCAT(CAST(block_index AS VARCAHR), '_rps_match_', CAST(rowid AS VARCAHR)) AS cursor_id
        FROM rps_match_expirations;
CREATE VIEW IF NOT EXISTS all_holders AS 
        SELECT asset, address, quantity, NULL AS escrow, MAX(rowid) AS rowid,
            CONCAT('balances_', CAST(rowid AS VARCAHR)) AS cursor_id, 'balances' AS holding_type, NULL AS status
        FROM balances
        GROUP BY asset, address
         UNION ALL 
        SELECT * FROM (
            SELECT give_asset AS asset, source AS address, give_remaining AS quantity, tx_hash AS escrow,
                MAX(rowid) AS rowid, CONCAT('open_order_', CAST(rowid AS VARCAHR)) AS cursor_id,
                'open_order' AS holding_type, status
            FROM orders
            GROUP BY tx_hash
        ) WHERE status = 'open'
         UNION ALL 
        SELECT * FROM (
            SELECT forward_asset AS asset, tx0_address AS address, forward_quantity AS quantity,
                id AS escrow, MAX(rowid) AS rowid, CONCAT('order_match_', CAST(rowid AS VARCAHR)) AS cursor_id,
                'pending_order_match' AS holding_type, status
            FROM order_matches
            GROUP BY id
        ) WHERE status = 'pending'
         UNION ALL 
        SELECT * FROM (
            SELECT backward_asset AS asset, tx1_address AS address, backward_quantity AS quantity,
                id AS escrow, MAX(rowid) AS rowid, CONCAT('order_match_', CAST(rowid AS VARCAHR)) AS cursor_id,
                'pending_order_match' AS holding_type, status
            FROM order_matches
            GROUP BY id
        ) WHERE status = 'pending'
         UNION ALL 
        SELECT * FROM (
            SELECT 'XCP' AS asset, source AS address, wager_remaining AS quantity,
            tx_hash AS escrow, MAX(rowid) AS rowid, CONCAT('open_bet_', CAST(rowid AS VARCAHR)) AS cursor_id,
            'open_bet' AS holding_type, status
            FROM bets
            GROUP BY tx_hash
        ) WHERE status = 'open'
         UNION ALL 
        SELECT * FROM (
            SELECT 'XCP' AS asset, tx0_address AS address, forward_quantity AS quantity,
            id AS escrow, MAX(rowid) AS rowid, CONCAT('bet_match_', CAST(rowid AS VARCAHR)) AS cursor_id,
            'pending_bet_match' AS holding_type, status
            FROM bet_matches
            GROUP BY id
        ) WHERE status = 'pending'
         UNION ALL 
        SELECT * FROM (
            SELECT 'XCP' AS asset, tx1_address AS address, backward_quantity AS quantity,
            id AS escrow, MAX(rowid) AS rowid, CONCAT('bet_match_', CAST(rowid AS VARCAHR)) AS cursor_id,
            'pending_bet_match' AS holding_type, status
            FROM bet_matches
            GROUP BY id
        ) WHERE status = 'pending'
         UNION ALL 
        SELECT * FROM (
            SELECT 'XCP' AS asset, source AS address, wager AS quantity,
            tx_hash AS escrow, MAX(rowid) AS rowid, CONCAT('open_rps_', CAST(rowid AS VARCAHR)) AS cursor_id,
            'open_rps' AS holding_type, status
            FROM rps
            GROUP BY tx_hash
        ) WHERE status = 'open'
         UNION ALL 
        SELECT * FROM (
            SELECT 'XCP' AS asset, tx0_address AS address, wager AS quantity,
            id AS escrow, MAX(rowid) AS rowid, CONCAT('rps_match_', CAST(rowid AS VARCAHR)) AS cursor_id,
            'pending_rps_match' AS holding_type, status
            FROM rps_matches
            GROUP BY id
        ) WHERE status IN ('pending', 'pending and resolved', 'resolved and pending')
         UNION ALL 
        SELECT * FROM (
            SELECT 'XCP' AS asset, tx1_address AS address, wager AS quantity,
            id AS escrow, MAX(rowid) AS rowid, CONCAT('rps_match_', CAST(rowid AS VARCAHR)) AS cursor_id,
            'pending_rps_match' AS holding_type, status
            FROM rps_matches
            GROUP BY id
        ) WHERE status IN ('pending', 'pending and resolved', 'resolved and pending')
         UNION ALL 
        SELECT * FROM (
            SELECT asset, source AS address, give_remaining AS quantity,
            tx_hash AS escrow, MAX(rowid) AS rowid, CONCAT('open_dispenser_', CAST(rowid AS VARCAHR)) AS cursor_id,
            'open_dispenser' AS holding_type, status
            FROM dispensers
            GROUP BY source, asset
        ) WHERE status = 0;

INSERT INTO assets (asset_id, asset_name, block_index, asset_longname)
SELECT 0, 'BTC', NULL, NULL
WHERE NOT EXISTS (SELECT 1 FROM assets WHERE asset_name = 'BTC');

INSERT INTO assets (asset_id, asset_name, block_index, asset_longname)
SELECT 1, 'XCP', NULL, NULL
WHERE NOT EXISTS (SELECT 1 FROM assets WHERE asset_name = 'XCP');
