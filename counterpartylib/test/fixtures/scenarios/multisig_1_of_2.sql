PRAGMA page_size=4096;
-- PRAGMA encoding='UTF-8';
-- PRAGMA auto_vacuum=NONE;
-- PRAGMA max_page_count=1073741823;

BEGIN TRANSACTION;

-- Table  addresses
DROP TABLE IF EXISTS addresses;
CREATE TABLE addresses(
                      address TEXT UNIQUE,
                      options INTEGER,
                      block_index INTEGER);
-- Triggers and indices on  addresses
CREATE TRIGGER _addresses_delete BEFORE DELETE ON addresses BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO addresses(rowid,address,options,block_index) VALUES('||old.rowid||','||quote(old.address)||','||quote(old.options)||','||quote(old.block_index)||')');
                            END;
CREATE TRIGGER _addresses_insert AFTER INSERT ON addresses BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM addresses WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _addresses_update AFTER UPDATE ON addresses BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE addresses SET address='||quote(old.address)||',options='||quote(old.options)||',block_index='||quote(old.block_index)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX addresses_idx ON addresses (address);

-- Table  assets
DROP TABLE IF EXISTS assets;
CREATE TABLE assets(
                      asset_id TEXT UNIQUE,
                      asset_name TEXT UNIQUE,
                      block_index INTEGER,
                      asset_longname TEXT);
INSERT INTO assets VALUES('0','BTC',NULL,NULL);
INSERT INTO assets VALUES('1','XCP',NULL,NULL);
INSERT INTO assets VALUES('18279','BBBB',310005,NULL);
INSERT INTO assets VALUES('18280','BBBC',310006,NULL);
-- Triggers and indices on  assets
CREATE TRIGGER _assets_delete BEFORE DELETE ON assets BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO assets(rowid,asset_id,asset_name,block_index,asset_longname) VALUES('||old.rowid||','||quote(old.asset_id)||','||quote(old.asset_name)||','||quote(old.block_index)||','||quote(old.asset_longname)||')');
                            END;
CREATE TRIGGER _assets_insert AFTER INSERT ON assets BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM assets WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _assets_update AFTER UPDATE ON assets BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE assets SET asset_id='||quote(old.asset_id)||',asset_name='||quote(old.asset_name)||',block_index='||quote(old.block_index)||',asset_longname='||quote(old.asset_longname)||' WHERE rowid='||old.rowid);
                            END;
CREATE UNIQUE INDEX asset_longname_idx ON assets(asset_longname);
CREATE INDEX id_idx ON assets (asset_id);
CREATE INDEX name_idx ON assets (asset_name);

-- Table  balances
DROP TABLE IF EXISTS balances;
CREATE TABLE balances(
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER);
INSERT INTO balances VALUES('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',149849426438);
INSERT INTO balances VALUES('1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',50420824);
INSERT INTO balances VALUES('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB',996000000);
INSERT INTO balances VALUES('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',89474);
INSERT INTO balances VALUES('1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB',4000000);
INSERT INTO balances VALUES('1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',10526);
-- Triggers and indices on  balances
CREATE TRIGGER _balances_delete BEFORE DELETE ON balances BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO balances(rowid,address,asset,quantity) VALUES('||old.rowid||','||quote(old.address)||','||quote(old.asset)||','||quote(old.quantity)||')');
                            END;
CREATE TRIGGER _balances_insert AFTER INSERT ON balances BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM balances WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _balances_update AFTER UPDATE ON balances BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE balances SET address='||quote(old.address)||',asset='||quote(old.asset)||',quantity='||quote(old.quantity)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX address_asset_idx ON balances (address, asset);

-- Table  bet_expirations
DROP TABLE IF EXISTS bet_expirations;
CREATE TABLE bet_expirations(
                      bet_index INTEGER PRIMARY KEY,
                      bet_hash TEXT UNIQUE,
                      source TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index),
                      FOREIGN KEY (bet_index, bet_hash) REFERENCES bets(tx_index, tx_hash));
INSERT INTO bet_expirations VALUES(13,'74062934f0a97c41851735fef2a7df4d9ad9945424f09a54281e145a5e32492f','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',310023);
-- Triggers and indices on  bet_expirations
CREATE TRIGGER _bet_expirations_delete BEFORE DELETE ON bet_expirations BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO bet_expirations(rowid,bet_index,bet_hash,source,block_index) VALUES('||old.rowid||','||quote(old.bet_index)||','||quote(old.bet_hash)||','||quote(old.source)||','||quote(old.block_index)||')');
                            END;
CREATE TRIGGER _bet_expirations_insert AFTER INSERT ON bet_expirations BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM bet_expirations WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _bet_expirations_update AFTER UPDATE ON bet_expirations BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE bet_expirations SET bet_index='||quote(old.bet_index)||',bet_hash='||quote(old.bet_hash)||',source='||quote(old.source)||',block_index='||quote(old.block_index)||' WHERE rowid='||old.rowid);
                            END;

-- Table  bet_match_expirations
DROP TABLE IF EXISTS bet_match_expirations;
CREATE TABLE bet_match_expirations(
                      bet_match_id TEXT PRIMARY KEY,
                      tx0_address TEXT,
                      tx1_address TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (bet_match_id) REFERENCES bet_matches(id),
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index));
-- Triggers and indices on  bet_match_expirations
CREATE TRIGGER _bet_match_expirations_delete BEFORE DELETE ON bet_match_expirations BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO bet_match_expirations(rowid,bet_match_id,tx0_address,tx1_address,block_index) VALUES('||old.rowid||','||quote(old.bet_match_id)||','||quote(old.tx0_address)||','||quote(old.tx1_address)||','||quote(old.block_index)||')');
                            END;
CREATE TRIGGER _bet_match_expirations_insert AFTER INSERT ON bet_match_expirations BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM bet_match_expirations WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _bet_match_expirations_update AFTER UPDATE ON bet_match_expirations BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE bet_match_expirations SET bet_match_id='||quote(old.bet_match_id)||',tx0_address='||quote(old.tx0_address)||',tx1_address='||quote(old.tx1_address)||',block_index='||quote(old.block_index)||' WHERE rowid='||old.rowid);
                            END;

-- Table  bet_match_resolutions
DROP TABLE IF EXISTS bet_match_resolutions;
CREATE TABLE bet_match_resolutions(
                      bet_match_id TEXT PRIMARY KEY,
                      bet_match_type_id INTEGER,
                      block_index INTEGER,
                      winner TEXT,
                      settled BOOL,
                      bull_credit INTEGER,
                      bear_credit INTEGER,
                      escrow_less_fee INTEGER,
                      fee INTEGER,
                      FOREIGN KEY (bet_match_id) REFERENCES bet_matches(id),
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index));
INSERT INTO bet_match_resolutions VALUES('74062934f0a97c41851735fef2a7df4d9ad9945424f09a54281e145a5e32492f_6a5f30666a5f24b6e0e6f31cf06b22ee74d3e692a550297450bdf1d36b1cc167',1,310018,'0',0,59137500,NULL,NULL,3112500);
INSERT INTO bet_match_resolutions VALUES('2066b9a6b8913412384a0401ef57bfc604e7c5a2c141e23111a8ccc6881b0fb3_65db3ab58b65891a947ab9bdba4723e907678bf3b48397add62802dcc65d1d8e',1,310019,'1',159300000,315700000,NULL,NULL,25000000);
INSERT INTO bet_match_resolutions VALUES('94b11df6b519372bfbcf0ec5f3e6465a63e323c7cd7cff83a8abd78596d4bce4_a7daff1ca2874f6b18a8f1a1e70db27f58c6b39a9f106c353223fbccde57098e',5,310020,NULL,NULL,NULL,'NotEqual',1330000000,70000000);
-- Triggers and indices on  bet_match_resolutions
CREATE TRIGGER _bet_match_resolutions_delete BEFORE DELETE ON bet_match_resolutions BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO bet_match_resolutions(rowid,bet_match_id,bet_match_type_id,block_index,winner,settled,bull_credit,bear_credit,escrow_less_fee,fee) VALUES('||old.rowid||','||quote(old.bet_match_id)||','||quote(old.bet_match_type_id)||','||quote(old.block_index)||','||quote(old.winner)||','||quote(old.settled)||','||quote(old.bull_credit)||','||quote(old.bear_credit)||','||quote(old.escrow_less_fee)||','||quote(old.fee)||')');
                            END;
CREATE TRIGGER _bet_match_resolutions_insert AFTER INSERT ON bet_match_resolutions BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM bet_match_resolutions WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _bet_match_resolutions_update AFTER UPDATE ON bet_match_resolutions BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE bet_match_resolutions SET bet_match_id='||quote(old.bet_match_id)||',bet_match_type_id='||quote(old.bet_match_type_id)||',block_index='||quote(old.block_index)||',winner='||quote(old.winner)||',settled='||quote(old.settled)||',bull_credit='||quote(old.bull_credit)||',bear_credit='||quote(old.bear_credit)||',escrow_less_fee='||quote(old.escrow_less_fee)||',fee='||quote(old.fee)||' WHERE rowid='||old.rowid);
                            END;

-- Table  bet_matches
DROP TABLE IF EXISTS bet_matches;
CREATE TABLE bet_matches(
                      id TEXT PRIMARY KEY,
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
                      status TEXT,
                      FOREIGN KEY (tx0_index, tx0_hash, tx0_block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                      FOREIGN KEY (tx1_index, tx1_hash, tx1_block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
INSERT INTO bet_matches VALUES('74062934f0a97c41851735fef2a7df4d9ad9945424f09a54281e145a5e32492f_6a5f30666a5f24b6e0e6f31cf06b22ee74d3e692a550297450bdf1d36b1cc167',13,'74062934f0a97c41851735fef2a7df4d9ad9945424f09a54281e145a5e32492f','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',14,'6a5f30666a5f24b6e0e6f31cf06b22ee74d3e692a550297450bdf1d36b1cc167','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',0,1,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',100,1388000100,0.0,15120,41500000,20750000,310012,310013,310013,10,10,310022,99999999,'settled: liquidated for bear');
INSERT INTO bet_matches VALUES('2066b9a6b8913412384a0401ef57bfc604e7c5a2c141e23111a8ccc6881b0fb3_65db3ab58b65891a947ab9bdba4723e907678bf3b48397add62802dcc65d1d8e',15,'2066b9a6b8913412384a0401ef57bfc604e7c5a2c141e23111a8ccc6881b0fb3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',16,'65db3ab58b65891a947ab9bdba4723e907678bf3b48397add62802dcc65d1d8e','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',0,1,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',100,1388000100,0.0,5040,150000000,350000000,310014,310015,310015,10,10,310024,99999999,'settled');
INSERT INTO bet_matches VALUES('94b11df6b519372bfbcf0ec5f3e6465a63e323c7cd7cff83a8abd78596d4bce4_a7daff1ca2874f6b18a8f1a1e70db27f58c6b39a9f106c353223fbccde57098e',17,'94b11df6b519372bfbcf0ec5f3e6465a63e323c7cd7cff83a8abd78596d4bce4','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',18,'a7daff1ca2874f6b18a8f1a1e70db27f58c6b39a9f106c353223fbccde57098e','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',2,3,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',100,1388000200,1.0,5040,750000000,650000000,310016,310017,310017,10,10,310026,99999999,'settled: for notequal');
-- Triggers and indices on  bet_matches
CREATE TRIGGER _bet_matches_delete BEFORE DELETE ON bet_matches BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO bet_matches(rowid,id,tx0_index,tx0_hash,tx0_address,tx1_index,tx1_hash,tx1_address,tx0_bet_type,tx1_bet_type,feed_address,initial_value,deadline,target_value,leverage,forward_quantity,backward_quantity,tx0_block_index,tx1_block_index,block_index,tx0_expiration,tx1_expiration,match_expire_index,fee_fraction_int,status) VALUES('||old.rowid||','||quote(old.id)||','||quote(old.tx0_index)||','||quote(old.tx0_hash)||','||quote(old.tx0_address)||','||quote(old.tx1_index)||','||quote(old.tx1_hash)||','||quote(old.tx1_address)||','||quote(old.tx0_bet_type)||','||quote(old.tx1_bet_type)||','||quote(old.feed_address)||','||quote(old.initial_value)||','||quote(old.deadline)||','||quote(old.target_value)||','||quote(old.leverage)||','||quote(old.forward_quantity)||','||quote(old.backward_quantity)||','||quote(old.tx0_block_index)||','||quote(old.tx1_block_index)||','||quote(old.block_index)||','||quote(old.tx0_expiration)||','||quote(old.tx1_expiration)||','||quote(old.match_expire_index)||','||quote(old.fee_fraction_int)||','||quote(old.status)||')');
                            END;
CREATE TRIGGER _bet_matches_insert AFTER INSERT ON bet_matches BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM bet_matches WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _bet_matches_update AFTER UPDATE ON bet_matches BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE bet_matches SET id='||quote(old.id)||',tx0_index='||quote(old.tx0_index)||',tx0_hash='||quote(old.tx0_hash)||',tx0_address='||quote(old.tx0_address)||',tx1_index='||quote(old.tx1_index)||',tx1_hash='||quote(old.tx1_hash)||',tx1_address='||quote(old.tx1_address)||',tx0_bet_type='||quote(old.tx0_bet_type)||',tx1_bet_type='||quote(old.tx1_bet_type)||',feed_address='||quote(old.feed_address)||',initial_value='||quote(old.initial_value)||',deadline='||quote(old.deadline)||',target_value='||quote(old.target_value)||',leverage='||quote(old.leverage)||',forward_quantity='||quote(old.forward_quantity)||',backward_quantity='||quote(old.backward_quantity)||',tx0_block_index='||quote(old.tx0_block_index)||',tx1_block_index='||quote(old.tx1_block_index)||',block_index='||quote(old.block_index)||',tx0_expiration='||quote(old.tx0_expiration)||',tx1_expiration='||quote(old.tx1_expiration)||',match_expire_index='||quote(old.match_expire_index)||',fee_fraction_int='||quote(old.fee_fraction_int)||',status='||quote(old.status)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX valid_feed_idx ON bet_matches (feed_address, status);

-- Table  bets
DROP TABLE IF EXISTS bets;
CREATE TABLE bets(
                      tx_index INTEGER UNIQUE,
                      tx_hash TEXT UNIQUE,
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
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                      PRIMARY KEY (tx_index, tx_hash));
INSERT INTO bets VALUES(13,'74062934f0a97c41851735fef2a7df4d9ad9945424f09a54281e145a5e32492f',310012,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',0,1388000100,50000000,8500000,25000000,4250000,0.0,15120,10,310022,99999999,'expired');
INSERT INTO bets VALUES(14,'6a5f30666a5f24b6e0e6f31cf06b22ee74d3e692a550297450bdf1d36b1cc167',310013,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1,1388000100,25000000,4250000,41500000,0,0.0,15120,10,310023,99999999,'filled');
INSERT INTO bets VALUES(15,'2066b9a6b8913412384a0401ef57bfc604e7c5a2c141e23111a8ccc6881b0fb3',310014,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',0,1388000100,150000000,0,350000000,0,0.0,5040,10,310024,99999999,'filled');
INSERT INTO bets VALUES(16,'65db3ab58b65891a947ab9bdba4723e907678bf3b48397add62802dcc65d1d8e',310015,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1,1388000100,350000000,0,150000000,0,0.0,5040,10,310025,99999999,'filled');
INSERT INTO bets VALUES(17,'94b11df6b519372bfbcf0ec5f3e6465a63e323c7cd7cff83a8abd78596d4bce4',310016,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',2,1388000200,750000000,0,650000000,0,1.0,5040,10,310026,99999999,'filled');
INSERT INTO bets VALUES(18,'a7daff1ca2874f6b18a8f1a1e70db27f58c6b39a9f106c353223fbccde57098e',310017,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',3,1388000200,650000000,0,750000000,0,1.0,5040,10,310027,99999999,'filled');
-- Triggers and indices on  bets
CREATE TRIGGER _bets_delete BEFORE DELETE ON bets BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO bets(rowid,tx_index,tx_hash,block_index,source,feed_address,bet_type,deadline,wager_quantity,wager_remaining,counterwager_quantity,counterwager_remaining,target_value,leverage,expiration,expire_index,fee_fraction_int,status) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.feed_address)||','||quote(old.bet_type)||','||quote(old.deadline)||','||quote(old.wager_quantity)||','||quote(old.wager_remaining)||','||quote(old.counterwager_quantity)||','||quote(old.counterwager_remaining)||','||quote(old.target_value)||','||quote(old.leverage)||','||quote(old.expiration)||','||quote(old.expire_index)||','||quote(old.fee_fraction_int)||','||quote(old.status)||')');
                            END;
CREATE TRIGGER _bets_insert AFTER INSERT ON bets BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM bets WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _bets_update AFTER UPDATE ON bets BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE bets SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',feed_address='||quote(old.feed_address)||',bet_type='||quote(old.bet_type)||',deadline='||quote(old.deadline)||',wager_quantity='||quote(old.wager_quantity)||',wager_remaining='||quote(old.wager_remaining)||',counterwager_quantity='||quote(old.counterwager_quantity)||',counterwager_remaining='||quote(old.counterwager_remaining)||',target_value='||quote(old.target_value)||',leverage='||quote(old.leverage)||',expiration='||quote(old.expiration)||',expire_index='||quote(old.expire_index)||',fee_fraction_int='||quote(old.fee_fraction_int)||',status='||quote(old.status)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX feed_valid_bettype_idx ON bets (feed_address, status, bet_type);

-- Table  blocks
DROP TABLE IF EXISTS blocks;
CREATE TABLE blocks(
                      block_index INTEGER UNIQUE,
                      block_hash TEXT UNIQUE,
                      block_time INTEGER,
                      previous_block_hash TEXT UNIQUE,
                      difficulty INTEGER, ledger_hash TEXT, txlist_hash TEXT, messages_hash TEXT,
                      PRIMARY KEY (block_index, block_hash));
INSERT INTO blocks VALUES(309999,'8b3bef249cb3b0fa23a4936c1249b6bd41daeadc848c8d2e409ea1cbc10adfe7',309999000,NULL,NULL,'63f0fef31d02da85fa779e9a0e1b585b1a6a4e59e14564249e288e074e91c223','63f0fef31d02da85fa779e9a0e1b585b1a6a4e59e14564249e288e074e91c223','e0b62f4bd64b1c6dc3f1d82dfe897a83e989b6d7b01fa835f074b5cfe311d8f4');
INSERT INTO blocks VALUES(310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,NULL,NULL,'98ccdf7cd2fb29a8a01cbed5f133b70b6966c6c56354dad00baacedd0673c87e','faf6476a908c85f6e26ca5d182688d6da3f326296602d5ad3aa5979cb8bc110b','e741dffbbc2f0a5a0e4079090bfee9286a0e36b1889164596567b3eb09ca2a45');
INSERT INTO blocks VALUES(310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,NULL,NULL,'fd43dc5efe2ee796ef7d24f8d478a67aa58bf85f538ef4b9a49b983a315deb26','544f7958bf7661b78699c708ba1097da0dbb044acee3d1d8aa9a32d6b659a14d','d80069c0e562ccab36549ff58729f152d0e7eca58a570cf6b95fb684561268f1');
INSERT INTO blocks VALUES(310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,NULL,NULL,'dbae4fff32545b4f3c104fb5a051dcaeacecd27401c84c09f93923b8bc30eab5','ee37e75a4eba165ed448b7cf96d188d7f738aca4d90a781c7f473974e12564d5','1560a9607031daefcd238fb98c9ed61ec0f819bda3f3a5ee69d7a7777e66d2d0');
INSERT INTO blocks VALUES(310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,NULL,NULL,'fd0ae9793d9513540246b94ad116fc0531e8e07b2c014752e175a12e2a7a82d4','107902b17490957ebc0d2cb5dba1f5e667e3a393acfd8b3adde9f6b17aaad5c4','ba4b89607b3fc30562c25bd43e6fc75c22df179595f140ed8379d88f891de34a');
INSERT INTO blocks VALUES(310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,NULL,NULL,'bd894777a85b731155a0d6362766b4220c03db4f3e5fbf030d6c2529cb5f3537','65e6a7c64c8439a60fb066d96d5165e6e40974bd1b98812ac6a4172fb1db1511','a248e58dcfbd8821b3e5892a5a74430d8aec911e21cca6f412603260ce525921');
INSERT INTO blocks VALUES(310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,NULL,NULL,'264c98f1d460f78e52def545d25482fd76549a5309d04841bc27b335f06470a2','9ede5548f7cb273af825360a6285fe9a51e9625c9084b2dde7bec013dec24f0e','af34dabcfe246f12c5e720e4ccf5a48469b6e23fd6fef01e8979e1d95a24572e');
INSERT INTO blocks VALUES(310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,NULL,NULL,'a1f2aa5a0b8d030c2fc4e1243c3173319ecf68d232262ea3dc8bfdd03a3f923a','b068f40e42354371dcdaf561d539f29064821b17df18202da4b29f18454bc5e6','cdfa5fa6c169da038c3a9db79194b37860a574d02d7e6a36c914dc77f5b867a5');
INSERT INTO blocks VALUES(310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,NULL,NULL,'8709aa2d5064ea2b7ab51a887d21f5fddcb7046753cd883317b533ed121f8504','12aca854ba76d88452886d49c15209fa5c6c7bf51663a4a20fbe80e1758bbee2','6ea15f7dccae1637ffedc08f2406153adb70b40acf63b83cc46ea6a80b3d8c5e');
INSERT INTO blocks VALUES(310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,NULL,NULL,'c1c516176fe38b69b31e3668b5ef20805bd90d3112c77f5652f838af8e7f604a','c36659d2f410882a7227efcf32d865f5b8f61d852560930ddf8d55a89743e16f','056412d34241196f81310043e6a139dbb7a7c6ca3b1cf79e549985198bebae8d');
INSERT INTO blocks VALUES(310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,NULL,NULL,'ae8ee9e681f0ac96de96babc1c80e5188b3e0cb91074a0dfd8511ee7d0ae64c8','7e2f8c7c9e433cf60d29670510b246131f6c56edeaedb639305b681a8cebc7fb','a31e2957a879e459d5e6d175f95d9ee0350e726f62b022e7c3f68c6eccf13fc3');
INSERT INTO blocks VALUES(310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,NULL,NULL,'0451ffa5d7ffb0e588e58ac7eacf77f6b3e17f1d27c1039f03d7716b16fb234f','766130f06027ca807ac5607f19420e69252f0e857b2aa4310e39acd77d48c345','4a6d9ec7e63005f343f0846042d1812238573a6b7d15d809ddb7419151dc396f');
INSERT INTO blocks VALUES(310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,NULL,NULL,'dfaae3f28c2f75e4bcc49034ff2a191b5a41b88035c5d266181617c8c65ad5d3','00fac0ef0491a19ce4708bfee27169d45da6ae95a0b373032fafb1b21bb1bd23','f7304ed4faac20c6557186e5c3419d4ee7f367a466d1c30052e14b863146067c');
INSERT INTO blocks VALUES(310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,NULL,NULL,'c711e8cf2d9bbed01724a7b22cbd4900a4fd0a126bb7ecbd7c97ca15a6276553','5cda3e140d5c05a931acf97a3b26ee9f0445934009517921861321e8ee0b1fce','f4cdad5de24363bfc1512df45258520c8f4e54e54565272ffe58f30cd40045f8');
INSERT INTO blocks VALUES(310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,NULL,NULL,'3dfa5822de8a4c674f1517b17e50d2ef63ccbb1fc4ae96fe5e1dc05cd353aa4b','df3c5a6cd88e6b8cb9e09942ad25fba960307a5137b720065db6cdc4b1e9ceb9','1704c188b8adc2245c9b52a421c024792698ed523434cf673cb1bf13d06f95f9');
INSERT INTO blocks VALUES(310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,NULL,NULL,'49fcaed957776bc62c9f1feac30dad8c0574596d312f9efee7a453e00bf64866','95fb34c0731b8b0fec5241e2a5f786963023b5eac6c848814dbea1da92a5a7ab','014865ce38a2d452724c5584938346f2dffcc50151c8c525f367fe553e92eb17');
INSERT INTO blocks VALUES(310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,NULL,NULL,'4e4abd3e8ab2658a7ac673e3a178ceac76fee41cf48bb6ed007d241c079979bf','844b4c886a7c11436c6968b45c0cb6e1e5c9be53c0f8cae32b5a22d1b898b2a9','6082fc17db052949e4ae9db18434ec9f2d1b3fd2b1cb648c70e5ea46cce56c28');
INSERT INTO blocks VALUES(310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,NULL,NULL,'17a28cca0777254af26544edfefcad8810e847e5d173fded9a7813719cf1162f','b1afe5f3b2e7f8ee44fecde0dcf3524b4a73dd0b2af804850a0aa3e7984577fc','38005370a753330b9f419875e1d237ac96313b83b2c69f5e291c34db666be6f0');
INSERT INTO blocks VALUES(310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,NULL,NULL,'1fb58120e9eb78908fda6265cad12b4a5770701e9a271bd5c4bc94059bd3bab5','6393f91ca4fe883c1605aa322bc75cf80303eabb871fd7d5f7db140afa2f120f','41cdffc6f229f327dbe803f2be1e2947c2d5d3d012b3e8a99646a0ca93d9ffa4');
INSERT INTO blocks VALUES(310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,NULL,NULL,'304243c1b11644e04d325d7100e4c757c07b874f0349e60163a5a544e84e951f','a97beaba0b28737b58cc1b0a888c794efe1cdd7ed770adac67aff2b079b77376','b3ec7f99c38b0b0b83046d46edaf00ac0667eed160d0f5f9d3614c224a1d41bc');
INSERT INTO blocks VALUES(310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,NULL,NULL,'fc9905ee4863b3cf29a3e558ee690a24ed978a4fd79c464bdde30a34cfff19fe','b0859e985b14ebb5a63c223e5469f7cf16e657e77448edcd20be2ce5a54b0420','779df1578db03b47ec8bfa8932e8d2f18f19413386c38fd40d31d2ab7885657b');
INSERT INTO blocks VALUES(310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,NULL,NULL,'e433feac4a09ad727bd3764b10a568acf5c659745a695e9d7e8790514f6bc98e','cf412243cca46684c5da41c1e2dc6f8cb04d9d299f143d18cbe66905055ff9cc','533af90f477c146b42dd7beeac8c8e6bc2ca23e097d71d8a8aeb0dae4930692f');
INSERT INTO blocks VALUES(310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,NULL,NULL,'622f92da40eae0b1b57218b32ad18daf7d79c9e0202fed4a288d75b8fdcd19d2','862319792c2af47984ab47d1da375843675f1645b2d764a59ccd14a63fe0e74c','70eb82280c16b7236b02cad1a2c4bad1b485e05d19c335686cada44f05248dc6');
INSERT INTO blocks VALUES(310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,NULL,NULL,'b7aa8d9ebc37d52d8dcce2cc17431d6edf5a183b73ac85bb3d91276592215cfd','e595f9aa6b9065b14e5d79c144133c97ec9350ea87a2fc2b0af738725624bbdc','4f4a5eb299fccc72dcc4497a97ff65df42466efa771bdff1568fbd603838949d');
INSERT INTO blocks VALUES(310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,NULL,NULL,'501c058860063ca599f3b946d465b3bbd84fd483a2a80527e456e3de32b48a19','564191ca6ff5e205b25a768e75f49d2145e63a9b9603a37ac1b82f6b6ecb131c','58c1dd44f17e6fb965f1d69ecf5adffe5c576fdd046477b4fb5393bdf7d81634');
INSERT INTO blocks VALUES(310024,'b03042b4e18a222b4c8d1e9e1970d93e6e2a2d41686d227ff8ecf0a839223dc5',310024000,NULL,NULL,'222986ec44fae1a6196d64dec24b79872970823f17bf0459d3b247bdef316675','31bb0edd3dc1f1bec10ae938583184a45f61d0b65fc414540383cd453b8ed0c7','5eb71f8dbd6e5356fcc2afdfcddec79e97261a9436eb18cc878f6db6a4a69cea');
INSERT INTO blocks VALUES(310025,'a872e560766832cc3b4f7f222228cb6db882ce3c54f6459f62c71d5cd6e90666',310025000,NULL,NULL,'bcd88006b9cb98445a74c656d424435e82eeaef95dd9c54e394b42808dc9cb8b','396b52eac2816bba0452577d31fa6c0e8a963657eb7a0b70e635929978c93bf5','80a010a436125add8bc1735dca69ef10c08d576bbffded83b3152f65a18cf811');
INSERT INTO blocks VALUES(310026,'6c96350f6f2f05810f19a689de235eff975338587194a36a70dfd0fcd490941a',310026000,NULL,NULL,'3de7bf2043ac2e68bc9eaf8d1c12195a4f2400bc78c8deed0d487af11edf401e','9f72e45ef431346f9949f2acd8c95859407604337a7e4d5e6acce27606b19230','17791823490d0b6f7dd3a8559fd5276cedb41f72749512b5432569ae3b9f78de');
INSERT INTO blocks VALUES(310027,'d7acfac66df393c4482a14c189742c0571b89442eb7f817b34415a560445699e',310027000,NULL,NULL,'6c2a67783cf36e8987dc1805f87532ee1b94f79fb00952d8ee4cf3daaf655f85','02d3f00cfc4eee6ab15b72d67d1767e10436b745a0a9215dda0e7fcc3d075cf2','a3453a83897c511d0abb3ed2cc889eff02c2e52c3b26f0acb8380b855c0150aa');
INSERT INTO blocks VALUES(310028,'02409fcf8fa06dafcb7f11e38593181d9c42cc9d5e2ddc304d098f990bd9530b',310028000,NULL,NULL,'659c73390e2e7eccc07d690fb438181c604787208bc45f466e57721fa1e21a64','aba8dc128b97abffd7f07266e463ab60620d1d7850ddb8a2a147624136871042','a2cdd473e48f71db4e340d5861dfd5f4788d2a9483b93b459b0e60708d6d57dd');
INSERT INTO blocks VALUES(310029,'3c739fa8b40c118d5547ea356ee8d10ee2898871907643ec02e5db9d00f03cc6',310029000,NULL,NULL,'87449e7ff7316e49012934d83c1f5b733cedf39680299a9582eb216e260e0c02','c68885ca5a2077cae4288ae737212df2616dcb67313e707e0b04e579cc13a0d3','c4cc46cce93e30e321f0a8bdbec9bfe4f2889caabd02b30bbc178db7c35d742c');
INSERT INTO blocks VALUES(310030,'d5071cddedf89765ee0fd58f209c1c7d669ba8ea66200a57587da8b189b9e4f5',310030000,NULL,NULL,'6c4a7f749d0308edf5c88b3ea4de3b1d497ba3bc06435594d77686318b744b0f','40dd59e71c94cd5641c1c448c21006dd15fb1509a18e7dac439623dcc737f11d','41784be78fafcb2414694e41746576d92e3805f4df553ce1739ccc5ed0c88759');
INSERT INTO blocks VALUES(310031,'0b02b10f41380fff27c543ea8891ecb845bf7a003ac5c87e15932aff3bfcf689',310031000,NULL,NULL,'ecc04b1b2c7803ca17dc2a32adebd0960de2c04c8dbfec9cd88771dd883c885a','24f03b3c8ca0247bbeab53cf76f9a63e9a4b1f024ace3614e6977b9201ba25ed','888a597e56acab417efd2cbeea5291f605404540356411a9312aed8067a8f654');
INSERT INTO blocks VALUES(310032,'66346be81e6ba04544f2ae643b76c2b7b1383f038fc2636e02e49dc7ec144074',310032000,NULL,NULL,'01e769c5b990db44a9e534bc6c759567eb4283e0ea252578dd525923c7fde02c','3992a2d85650e9b096de6aa6b16042d78cd0230ad89e2b88416bcae399073570','50564da5d4a429de472a72e11c80af8b5efba346d4a080aba8b5ae9cb372dc68');
INSERT INTO blocks VALUES(310033,'999c65df9661f73e8c01f1da1afda09ac16788b72834f0ff5ea3d1464afb4707',310033000,NULL,NULL,'2df6b8dca0ffa8d6d55997605188637c2b86300e4dd7ebe3f1f275690169fd46','08e8e3415ed5058de1320f7a54cca71b7ab3958132fc670a966502ca754ec5e0','2cd43796215b9a8f6c2c22d81da2c93247f898f4b999dd5dac69e2de637ee09e');
INSERT INTO blocks VALUES(310034,'f552edd2e0a648230f3668e72ddf0ddfb1e8ac0f4c190f91b89c1a8c2e357208',310034000,NULL,NULL,'7f0dc7c1527a7d11831d272f0295eacabcb96fa3599f5a716bd29ba1bb6b7577','839057e366a17995ed55ad1d18658cfbae736c23f2e24afd94d74a38b72c8715','fc2c1c8e08246c38bdfdba930ec80da6a460c2b86ff7c7e70501d09cbf11bfcc');
INSERT INTO blocks VALUES(310035,'a13cbb016f3044207a46967a4ba1c87dab411f78c55c1179f2336653c2726ae2',310035000,NULL,NULL,'5e0cdf1764ed94672c29144f9c1bd9c3e70784f17c9dd1c9e4ce703a99bb3599','79a9550691c6c2dae130f09d97d014a445f8cf1d3078e0026d78bfc9997a853f','9f33737d64053974721de7f6bb8b9530aede1b3d336a9bf5f61b83c0006a2de2');
INSERT INTO blocks VALUES(310036,'158648a98f1e1bd1875584ce8449eb15a4e91a99a923bbb24c4210135cef0c76',310036000,NULL,NULL,'96da34a5a66b89aa3e8857b4a4edca51a56a0cbbfe600d8153077875624a153e','5b067bebd64404c8a8c2add7f23870cabb97e27ecb8db16d39a67cdaec4c6ebf','bee037a5229cc8c58fdcd9e39161af44bf12dba4863df2625eb5cb2fa5f0f2dd');
INSERT INTO blocks VALUES(310037,'563acfd6d991ce256d5655de2e9429975c8dceeb221e76d5ec6e9e24a2c27c07',310037000,NULL,NULL,'d481358c19b4220aa9a3d135fd0651fada6df8d0f27b9ec954ac07950e876c0c','e7551c718a87497db6f77f2a48e474d8366eb7a5dd98e604f7b53891bf3e0570','6a706f5a533f2a469286588d60d4f6862a87821918c2b266d27d3a2864df4a08');
INSERT INTO blocks VALUES(310038,'b44b4cad12431c32df27940e18d51f63897c7472b70950d18454edfd640490b2',310038000,NULL,NULL,'4e9fcc454ee53b3617c792eb6577c2eefa6eee6aa4a2925538cb1976d48817c9','7aa80c2ddf969ce13c2efc3a68933598fedf8af0ad2335ccf72cc74888de909e','9d863d986a9899811bc0652db3a18d6e5b996b8e87fca37d3a6b7d4b0ce5a64d');
INSERT INTO blocks VALUES(310039,'5fa1ae9c5e8a599247458987b006ad3a57f686df1f7cc240bf119e911b56c347',310039000,NULL,NULL,'795c5652d9679942a02060edfb497b072009695d9a72fb144fa3591dba65a2ce','0cfc8049206a1254ac8af048cb28224a9b962be921cc47936b7be68017937450','4225bfe35c597eef7a25da48d36c950fc005d84f10d93ab94a9adcd5b608fe4d');
INSERT INTO blocks VALUES(310040,'7200ded406675453eadddfbb2d14c2a4526c7dc2b5de14bd48b29243df5e1aa3',310040000,NULL,NULL,'e569e6e8083818e594e92b3356833e8dd54fcfcf5ed25af0d09e36e24b9dd441','bfea614138614a2cd080cab8cb4766232a71ec6244fa7e59580626fe46552199','af7a1de8c1eb09dd223ca7ee470d815b8744b16fafa946976931a9c4532d19a7');
INSERT INTO blocks VALUES(310041,'5db592ff9ba5fac1e030cf22d6c13b70d330ba397f415340086ee7357143b359',310041000,NULL,NULL,'2247fcc633175a91921d226f412e56822379c79ca799117c39ecaaca0a702192','d748e2586b9f4f1eed29afe4e5333f87c8ab309e73df79ed5387814268cae807','5b25b431faa87fff0a26536b39975a87d4df6c1d69482636a9bf6a603a78a3ae');
INSERT INTO blocks VALUES(310042,'826fd4701ef2824e9559b069517cd3cb990aff6a4690830f78fc845ab77fa3e4',310042000,NULL,NULL,'0246c3a2a70b33a038ccdb816f6b0922a50d08310f360cbd5db4df58e97fc4dd','bc088a33a816038bc995fdc9d552d0a0bd30b7e41d89bf92cffda09836d82fab','0555259c23b96352b1bc46646a870be63b929c99480b2440df7d3e69b207a7f6');
INSERT INTO blocks VALUES(310043,'2254a12ada208f1dd57bc17547ecaf3c44720323c47bc7d4b1262477cb7f3c51',310043000,NULL,NULL,'cbe39e9d1a132cdc568f893bbc3d4f55d27bacf7af31f027ebea1b4bed9f0009','e342ab17f54d4d89f656c12a9331da880efe638170f9f8b2eee9cd52b9b5a014','b84fa1217975d2ece89b74b3ecd76de3f278cd93d8a948bcbe2b360953acee9b');
INSERT INTO blocks VALUES(310044,'3346d24118d8af0b3c6bcc42f8b85792e7a2e7036ebf6e4c25f4f6723c78e46b',310044000,NULL,NULL,'1202b05e118f0940ce270d9002d010076115a0197d889fee2d971a77709899bc','45318991c3cbc53ad2980bcdfe96ddf266ff8f565acb663e9f94ad4e196a1585','3095a608f58a10a1aeb928582b638ca24c8dda2a7e2bab57f23fc99b7a001eaf');
INSERT INTO blocks VALUES(310045,'7bba0ab243839e91ad1a45a762bf074011f8a9883074d68203c6d1b46fffde98',310045000,NULL,NULL,'0bc49f765419c0b5b4911cccf03b0d9959aabacda266480b98245de0c0d35fc5','da585690e5453012ad5bf9fafb413c6d7949a2d5151f6a268fef4bf845c34cbc','4808f5e4f2b38743d4ebd2e0bcb5c6e29a0f0b87b49da32dfbf871dd229802ab');
INSERT INTO blocks VALUES(310046,'47db6788c38f2d6d712764979e41346b55e78cbb4969e0ef5c4336faf18993a6',310046000,NULL,NULL,'e42bf9806d0ff3a0663756f7955b30735747d14fcb0915c89884baa12795163d','2dced688bab2ab866e9b190e0111114a8f04cd64d2608cc3b17e6dffe60f79d3','67fa88dffbf3f7c58ffce80807485f3151646fe690043fca637723e389bd2c12');
INSERT INTO blocks VALUES(310047,'a9ccabcc2a098a7d25e4ab8bda7c4e66807eefa42e29890dcd88149a10de7075',310047000,NULL,NULL,'b19b5e14741284b4ca06b736120e903363651460a6efb3ede1aca3a4f3c00df1','b3d95f8e9fa8c7f39ce1169e8a6434a803e95e2dc2e37f1d5aaca0c9eab8c820','125ac8f5943d27993c523905c73f8da4f8d163bc8e387cb750bce0c1c1e81cd2');
INSERT INTO blocks VALUES(310048,'610bf3935a85b05a98556c55493c6de45bed4d7b3b6c8553a984718765796309',310048000,NULL,NULL,'e870de901ba86d65d0e2053251ffb32cc7dffb55fcc2efbc006a2b9137314a39','d734a3bbd9bc7ffa01c2778d56b9e7a9a0fc999de89effdd1f1d085b5f042727','31b6a93eb9884a16474639dace1ab8f8b306cc0fed3dd9088f67083d9ac278b4');
INSERT INTO blocks VALUES(310049,'4ad2761923ad49ad2b283b640f1832522a2a5d6964486b21591b71df6b33be3c',310049000,NULL,NULL,'44cf354cdc8552ed37e5911340397d3531d0ba45100feae27377130d4ddef359','c51634f6f05eb24e00f2a96c1970e7dd134ad3dfb3ae0590c61093e90f3aa5f7','1b23a328fe5719523f24a0de8f409cd0abc7e84fbf5db9c9454cd48acd0e1581');
INSERT INTO blocks VALUES(310050,'8cfeb60a14a4cec6e9be13d699694d49007d82a31065a17890383e262071e348',310050000,NULL,NULL,'7d72f11f48ac99553e1b2c52a7ff5645fbe05728a10a002727b9270dbb32daed','8467d432623327ba8dab49fc75453d8b643b6186cc1dfcd1908bbf0f0ad91c18','17f9964cfc861bea05f8d080425f6c98b4aee4f7a6404cfc97b46ff267b68982');
INSERT INTO blocks VALUES(310051,'b53c90385dd808306601350920c6af4beb717518493fd23b5c730eea078f33e6',310051000,NULL,NULL,'35a965dc90686fc4eb20450da81ca8db9125e25c2cdd7146fd61d98841d80c24','32b87b3cd8a1360abf15f182040e23c189ff53b5970598d03aaf55390d9db113','f27b5f0f5b9caf222ec5c20c6bf2d72d3a81e526eac5f446b22fc285d3637609');
INSERT INTO blocks VALUES(310052,'0acdacf4e4b6fca756479cb055191b367b1fa433aa558956f5f08fa5b7b394e2',310052000,NULL,NULL,'8604d503e7194ee1c8ebe1143019207b2aad163655107a3d23d018ef26cef550','a156a6c776a4713faa12841b37c5f5e0853cae8d6d778567ad0299d40d73c7a6','0eb01dc4b4992d7509df5815e7fe098a3ca76fb3c32dd63bbc2ba2ee05c009a7');
INSERT INTO blocks VALUES(310053,'68348f01b6dc49b2cb30fe92ac43e527aa90d859093d3bf7cd695c64d2ef744f',310053000,NULL,NULL,'ecdb64ffc44490eeb12199d2da5c1189c07f4102f5b91494cbe4ec68fe6bb6d4','53bd785e46bab3c81c992214a04a27ffd486e844d64287cff4151405ac607511','33684e694a3a4b9abcd6726699eeb1cbfe17da9013b5f165c38b40c907fbdf1c');
INSERT INTO blocks VALUES(310054,'a8b5f253df293037e49b998675620d5477445c51d5ec66596e023282bb9cd305',310054000,NULL,NULL,'b96b0d51d6327284f5922b65e5d023afd2b2e44c9e11f435afbe2a71df4e6eb2','a64e046ff68cb71914a14c6d851c2cba6f56674cf9a623c9bacc766f359942a0','76c84564ee5240d4a29929589984dd997dcc71100ff21ad59b69405f2941d49f');
INSERT INTO blocks VALUES(310055,'4b069152e2dc82e96ed8a3c3547c162e8c3aceeb2a4ac07972f8321a535b9356',310055000,NULL,NULL,'c5be3fc23a9c41b7b78cc7df4ed13d1d35fdd7edab77c998cef5a5a5fe2a7d33','f57484ccb66224532681fb8a41e332f561736289b6914954cb44093cb30cd96a','f32e9063295ba3d187758279e78e8bd8515d7d1e8c1ea1bde029b7181878178d');
INSERT INTO blocks VALUES(310056,'7603eaed418971b745256742f9d2ba70b2c2b2f69f61de6cc70e61ce0336f9d3',310056000,NULL,NULL,'faa7cf6128f229fe3d408797c77ef2972eb28d16542b32ec87c5fd42d2495018','9a6f5d304c42cada57d1c90b06f2597d3b41443f759a3d4467a0dc047e58c502','5902d6fbbf553973c09f056cc628dd9e04380c9bf4c8196af68176d371ae9e1b');
INSERT INTO blocks VALUES(310057,'4a5fdc84f2d66ecb6ee3e3646aad20751ce8694e64e348d3c8aab09d33a3e411',310057000,NULL,NULL,'135af680c59a3d707ff3e6b67fbbb0aaaf0a97724d36ba584087658ae8c0db19','994e9b9daf8fe52660edf7e68843cbb0c3312eb801f813ca03c4e086a8bb836f','a56eb2ee5fb6447c71a2598fd894952a06a95bb51bb424c87fcc4aa7d4509bf1');
INSERT INTO blocks VALUES(310058,'a6eef3089896f0cae0bfe9423392e45c48f4efe4310b14d8cfbdb1fea613635f',310058000,NULL,NULL,'496b559ef740feabe42d55356bc770bab7b927d79260c22848b7f47d51918f11','5baf8b47fb8b934050bf3e4a80e712e0c689c053e80042f760aa9c24a41885ab','72f1c10d6f6a702acc9efefe40f620ea00ea3e0259df4eb29aefe07b1f68c43b');
INSERT INTO blocks VALUES(310059,'ab505de874c43f97c90be1c26a769e6c5cb140405c993b4a6cc7afc795f156a9',310059000,NULL,NULL,'608eb77e572aa596c9e14c6e4cb1dc1993bcbcfe735cf0453124c2801192ecc9','3f7a7dd82895f7fbe2c2b771707ad7273ca18122d2fab9c9a8a9dd4bad845a02','3b4e83a3d48528e70ba004c48f9646388802aff4878c462043b3bd85af64f24e');
INSERT INTO blocks VALUES(310060,'974ad5fbef621e0a38eab811608dc9afaf10c8ecc85fed913075ba1a145e889b',310060000,NULL,NULL,'bc5c375d1237425486c9f46bd749fba20b5635bcaf3e2d9178b35ddfbb700f14','c1a2a98b36731aa1d7dde7acc9e6b647fbe48f39160750b51d89165d8f736739','8c560d0e4a4cda0fbbf1d4724451bdb46d48faed0d5e52a4a90b13da547e008f');
INSERT INTO blocks VALUES(310061,'35d267d21ad386e7b7632292af1c422b0310dde7ca49a82f9577525a29c138cf',310061000,NULL,NULL,'c6d48d72746c0e18fa0f1b0b16f663869be2c4684a9d98b634e691ea495f4d81','c994805d444dcb26cfdd137c1d589a582928e3a6a4720bc113c503c6ac07c27d','16ffebf9c2dc351fbf45277bada1f6e1553e7020114b3baef4c0bb2d38b6f6c6');
INSERT INTO blocks VALUES(310062,'b31a0054145319ef9de8c1cb19df5bcf4dc8a1ece20053aa494e5d3a00a2852f',310062000,NULL,NULL,'8deffdb1602f1aa2d0d1956d2297ba30ac78901ea27eb223ad8bf7ca83b18110','8402ef2385652f0d073ba62f7aaf02c299575556fe8a2dc9598d6d40a1be6126','4031fa53350dcfec98d5f528b86c34d454080c16dff22fdfbc95b1846b656486');
INSERT INTO blocks VALUES(310063,'0cbcbcd5b7f2dc288e3a34eab3d4212463a5a56e886804fb4f9f1cf929eadebe',310063000,NULL,NULL,'34859861f240c6553ffbf63fff9bc884f231276ec6173964d5fc6641a6d79b16','6b268cd9d65067ce8300526d53ac44f3c7566a7c4dd3bd8bbd22f0e2aa800bd4','1897b269aebb76e0ca9663c0210d88999739b3ca24aedaad0c9bdbb009c61833');
INSERT INTO blocks VALUES(310064,'e2db8065a195e85cde9ddb868a17d39893a60fb2b1255aa5f0c88729de7cbf30',310064000,NULL,NULL,'fa185f9b97a1666ce3b966dc09b8a7870ba55896a54a54f54d3420708d5a8ae0','4fcd3861c869c061efd839fc4424131c0aee45c513bd517bc0a4d33f0da146b2','e983d561717d0ea6f49ff714ad12e0065798a97f4975ade6f9bdadb9ada26933');
INSERT INTO blocks VALUES(310065,'8a7bc7a77c831ac4fd11b8a9d22d1b6a0661b07cef05c2e600c7fb683b861d2a',310065000,NULL,NULL,'9f75da9f944d59b1841d690b2994ead7fb0ee3d679ddbdb0b692e49238f66603','10768fd7ef0339c2d5e762aff6b85994b320ddbce267735be0ac934cbc5de566','8c82c7db656c84f1bfe18b3caf9ac82d5368c5467306d1ff8e09887c05a9e367');
INSERT INTO blocks VALUES(310066,'b6959be51eb084747d301f7ccaf9e75f2292c9404633b1532e3692659939430d',310066000,NULL,NULL,'4740587d203632d1b4061343436e25e12941f0f80be03c3ab390a1c08b842b59','e04b9dffd8ad762a6cc413bf185492717b2b2af4e2788b360a266ef93498cd0b','7c71f5164c7815a5c01d7bf5de1957848cec25f46c9bea68bd7ad0496d313b8c');
INSERT INTO blocks VALUES(310067,'8b08eae98d7193c9c01863fac6effb9162bda010daeacf9e0347112f233b8577',310067000,NULL,NULL,'d6eecb0ca22f29b50e52cd5dec8f408250a7b1ddc61bfa9bf6cc6ef0a85a6ffc','017162e601daee366b32908af5a5d2ba90c5dfc1da174df958b2bf7febcb6e4f','54800f5149f8da473647664a0320a872d0c27f7b02bd43a866e33441077b3221');
INSERT INTO blocks VALUES(310068,'9280e7297ef6313341bc81787a36acfc9af58f83a415afff5e3154f126cf52b5',310068000,NULL,NULL,'1508605d4796eb2d8b0553b307827f570b5020f4cacf773926b6c8f2c1b003c8','ddeb6401e2850c6d4e5d525e2fd20a9cef8ab95709b2b5d66b3cd565399f10ca','9e37f9b7f2d3b437fb6ed156a666cd60f826a317bc5b69140425595159cabb20');
INSERT INTO blocks VALUES(310069,'486351f0655bf594ffaab1980cff17353b640b63e9c27239109addece189a6f7',310069000,NULL,NULL,'ea7afbe0817cfef5a5a940bf88b057d01d092182dd5d0c7fd156b6750fdf4cb2','573e36436c33944ecf75022989535645086531204e161937b2cbd027bf87141d','e4258181b75c444547d2dc25c22b478b3db849dbf6f1ce62088fb206cff89dc4');
INSERT INTO blocks VALUES(310070,'8739e99f4dee8bebf1332f37f49a125348b40b93b74fe35579dd52bfba4fa7e5',310070000,NULL,NULL,'f805d8bd0b724ffeb9e466367e8524bcbcf2c0fe0525b8ff2707af2013824a2c','23926c68a46e983e90c14ee40d7e2de82f53f41f6b089362a158ea6847283b63','8d567b21f4f4b27328ce0e5807404455d3733117cd82594bb059d1e3feb99be8');
INSERT INTO blocks VALUES(310071,'7a099aa1bba0ead577f1e44f35263a1f115ed6a868c98d4dd71609072ae7f80b',310071000,NULL,NULL,'305123423486d17e97e8370399b9079a35977465e4cf8c5b33d50bd7004b463b','21b0e327dae6d5c77b40746cfe1143c90185f8b668ba4fbaf01d08494fa007ef','fcb531aaf597f05aa9966245fa935a8ee89d1c2810c99a8631e04c2cd0f222f6');
INSERT INTO blocks VALUES(310072,'7b17ecedc07552551b8129e068ae67cb176ca766ea3f6df74b597a94e3a7fc8a',310072000,NULL,NULL,'b04fcd2cf46165fa31626b476aa06f9ad8c8cd1d5aa1cfdc014e0d55fa7e0761','f32bb472a6e64ac8763e4871c6c3d6d68c6454bd9600948f17e64916cf595921','b1cc39e4c57938f3fe886a0d26c9547aef2625a6e94c873547e2bbbba3958f28');
INSERT INTO blocks VALUES(310073,'ee0fe3cc9b3a48a2746b6090b63b442b97ea6055d48edcf4b2288396764c6943',310073000,NULL,NULL,'209f05567343042c8a9172138cc14e28a2e53f9addf16c7affa469fbea9728ae','fd3cf4f48fe2fb3360bcdce3fd33c8548ea2e136aa451c7eb5a98ec90b98ebe0','444f273213480179db98f7fb4469dadb2e4546a11624e6f2fe94ce496afaf5d5');
INSERT INTO blocks VALUES(310074,'ceab38dfde01f711a187601731ad575d67cfe0b7dbc61dcd4f15baaef72089fb',310074000,NULL,NULL,'fc18c0dcd6011c4147575f09bdc6e1eb0e6ae7d3144339859054df458651618a','b71b224db7314ab46a54757e14b2fee8dce3733672ce03908e32492b16230a89','7b936bc19a669eaadbb422229b550cb063c1705a27372cecd1f17b2d68d8909a');
INSERT INTO blocks VALUES(310075,'ef547198c6e36d829f117cfd7077ccde45158e3c545152225fa24dba7a26847b',310075000,NULL,NULL,'f304dbebd02e4536b1754502e6f51e058ed309fdf95a2db8329dd7e5635824ad','594876df3290edddacf606dd0913b304d9f3b0384e3c40377966365de65165f6','b2385add74957035a7ccf400954717bf4d19a93297477f8852505fd17aa88d92');
INSERT INTO blocks VALUES(310076,'3b0499c2e8e8f0252c7288d4ecf66efc426ca37aad3524424d14c8bc6f8b0d92',310076000,NULL,NULL,'f39c071315c869425bdbcf05ff84130a0860f5f47b4f851cea970f58a6edc9f8','91869514ff285a96ae67643b9de4598b318d9e7fa4cc46eb4117ddb0a127a095','56e486d9bd5a2ccf62cb8483182229d778bd61d706beebaf3886a05e14858c47');
INSERT INTO blocks VALUES(310077,'d2adeefa9024ab3ff2822bc36acf19b6c647cea118cf15b86c6bc00c3322e7dd',310077000,NULL,NULL,'20624d783cd8e82044df58c05e6171a744505df43623d9c2a828c1331f505ca8','ce672c5fc95b78390e2ea741e39eb49ca53e8e05b6ad5fd5e2afc9501ce8c458','7d84f3f9e0187bc907857f4a02148c8d03c06165cbc2c48dd562fd098ec90b82');
INSERT INTO blocks VALUES(310078,'f6c17115ef0efe489c562bcda4615892b4d4b39db0c9791fe193d4922bd82cd6',310078000,NULL,NULL,'41ae6610121587bd8171a02da3c50645e8e6d3642aef2c560d46f12707506b66','8277e13126b053967f582c51c73bb111a879320991d8dbc7240ad95fb3bb876e','32d0c699d184bfc036d44cbb1e96255316d33786c9010b7b2abc03923c1b33a1');
INSERT INTO blocks VALUES(310079,'f2fbd2074d804e631db44cb0fb2e1db3fdc367e439c21ffc40d73104c4d7069c',310079000,NULL,NULL,'bbc2068f2a4b47c86198a5cb7242e26f385077126c7a3294eca6607485b1170b','1cdf1f0d032f38ce236d2fcb52a19eb8f51f83f76a8876b19326437781bf5cb1','1fe12a741189b9a1eff55339b1d9aaa2ce0b69b4cd4370ff8073bb5ebad20bba');
INSERT INTO blocks VALUES(310080,'42943b914d9c367000a78b78a544cc4b84b1df838aadde33fe730964a89a3a6c',310080000,NULL,NULL,'fc4350d187ec74fa6dfbbca7f6c51849b78356f853c6c713d10ae4a39ee4f7e2','9704a390181d9cdb9473fe8bcc52994e1f2813e93eb139810ee03eca71ba1110','c28a41455f13bcc5cdc647e5a307102046ee372d4fc1d80a2f9782f9d5c61a81');
INSERT INTO blocks VALUES(310081,'6554f9d307976249e7b7e260e08046b3b55d318f8b6af627fed5be3063f123c4',310081000,NULL,NULL,'3cadb90f0285d3e3bb107caa2165e88d855cfa057fcff1fccfb278a8f64c9b1c','0b8e11ec1428277552538a8570ed531544abb6d32210e6829ae87870c401ec33','b69b46fc72f56c36979bc449ff4dd362218f4ecdf7e510c37cd254c0323a3f98');
INSERT INTO blocks VALUES(310082,'4f1ef91b1dcd575f8ac2e66a67715500cbca154bd6f3b8148bb7015a6aa6c644',310082000,NULL,NULL,'f3390bff59484b5ce0d84f5034fc88f4d862334ef3c0d7addaa9be7f0e67006f','8f54e452047214f8f1294e088a1c72d502e80eaacfa181fab5a73db518c5e61a','c32312761a305a9306d9dbde7f8fae3351c3a7f99240263c037daf8e72c11ad3');
INSERT INTO blocks VALUES(310083,'9b1f6fd6ff9b0dc4e37603cfb0625f49067c775b99e12492afd85392d3c8d850',310083000,NULL,NULL,'0354bf318eaec5c79b4a7835c76c89f373ab0e413f9fe4ebdea442f57763a971','8cce11544f86e376d4358ede31e913dd1789d4e3ede5f5274359f12f60afdc24','59dbc35ac2bc35c13c2c81851171146c28d0c90f91c25a701f31ff0de5037d3c');
INSERT INTO blocks VALUES(310084,'1e0972523e80306441b9f4157f171716199f1428db2e818a7f7817ccdc8859e3',310084000,NULL,NULL,'e22b7a64e15ded24f6c54a5f627354dd2c3ed8175c2f4cd31aa5a6789d7b67e4','bc7bb06c726923d375fa62137999f456d9053a165ccbee2d26de80b27d19210d','9df3da70837497ec5d07ca151583c45c982670038102397cecb61b45f7bc9686');
INSERT INTO blocks VALUES(310085,'c5b6e9581831e3bc5848cd7630c499bca26d9ece5156d36579bdb72d54817e34',310085000,NULL,NULL,'7b8a6f62709cf4d20820031f43d968ea46d73d8cee4ad40f414da60b9be4e676','85eb8b927b69ea10f52a5153e6e1fd844c379eb02f2024a670192a372a6cd078','e8aaa7c8ef44bbc4eb46acec9385964cf31bd7e8a1dc3de330e3e26efa20fbd3');
INSERT INTO blocks VALUES(310086,'080c1dc55a4ecf4824cf9840602498cfc35b5f84099f50b71b45cb63834c7a78',310086000,NULL,NULL,'ae82ee2f7f1e075937b5b8eef065f8643a7bef0428e00689ee773558905eef19','aebacb19b84ef8b70d1c21250b542fdea6bf9335ad25aa685965fe604e37b7dd','67acf1bfdf3dd129b0d06b93d747639342c8f502a3d2a532ac17d084d8cfc7b1');
INSERT INTO blocks VALUES(310087,'4ec8cb1c38b22904e8087a034a6406b896eff4dd28e7620601c6bddf82e2738c',310087000,NULL,NULL,'ced371f1349e81cc2f179f064e4b9b202650a0f79e9b4513666ace29f0e8b3cb','07690f944313e288b413c1273f44f1a164d3895b9cf8ad79787d0ead5384a566','a9594ed793dc35abe324592ddb422a6772eb26b521a280cd9e49358b0125c78c');
INSERT INTO blocks VALUES(310088,'e945c815c433cbddd0bf8e66c5c23b51072483492acda98f5c2c201020a8c5b3',310088000,NULL,NULL,'6c343897092c5dfcd32ee96dc8b96f38fedd31fa58cf5757a3e15a254942cd59','a28711053614403631eeb21c2d8486cffea56f3fa00d032b86f22827ffb2b39f','d98cbd1bc5a284ab1417a04be4fd89fc5ec0f247daffbcdafcf3a2901cc6c7b9');
INSERT INTO blocks VALUES(310089,'0382437f895ef3e7e38bf025fd4f606fd44d4bbd6aea71dbdc4ed11a7cd46f33',310089000,NULL,NULL,'abc7afdaefa89bf58bc4c28401740657eca24c902ba551f55becb6a1c8992675','e78688762e94d19efd9199abfbaeab3d9d14d37a747c81f6b2158b85ccab9e3a','d528b04b3f8e92cf2441d4862aa7a6f9611c05710388db11a14156a0a79f650c');
INSERT INTO blocks VALUES(310090,'b756db71dc037b5a4582de354a3347371267d31ebda453e152f0a13bb2fae969',310090000,NULL,NULL,'4c8ca9b4eeae7adfec822b20665e7bd6fecb51d4f30cc2c826f18402d8401a9b','7808e62c952be675a64e1af8ed7bbb2791e6541e4bc80c45ede5c1159bb9987b','712de76eee5576f4bb7bf112e3821a018d6a5519acbcc35ff87d05592b11c772');
INSERT INTO blocks VALUES(310091,'734a9aa485f36399d5efb74f3b9c47f8b5f6fd68c9967f134b14cfe7e2d7583c',310091000,NULL,NULL,'fe7fd2b60c3216d79dfe4e6d38880f6d3b9fde747b619f2c477108825235663d','ce101e2f70b5ae77519e52ae935d5c6844ff3ea1e39e891c8ea6f080e0cf04b0','40cc19ff393c11bd03fc8acc75f58d0d131d466e0d98a18cfcfb7d8a04529987');
INSERT INTO blocks VALUES(310092,'56386beb65f9228740d4ad43a1c575645f6daf59e0dd9f22551c59215b5e8c3d',310092000,NULL,NULL,'420b8ff3c159f7e89df2274682e7ef798a0c0233149365114bfd934c38806098','4a2a72ec1cd48e3297dea091d7beed7adfd4d4a8ab38b0f796ecee102f1e1292','2d9df6ee2fc2bd0bce8f3bc5b4bdde8742d2be3a80f09acf959dbbd30589a0f8');
INSERT INTO blocks VALUES(310093,'a74a2425f2f4be24bb5f715173e6756649e1cbf1b064aeb1ef60e0b94b418ddc',310093000,NULL,NULL,'f4fac6a570b4f6332a628a3f8e27f5f081689fb4255363cff1cd8bd0244eecea','5c2a280dde9a4e45cb9b6bd025df5be2c4238664540643f26b61fc2177bc4b8d','b36b74b7d7308cabf5c2ede53c6dd6a4df94f709b3fde01d4486d65f17c9a384');
INSERT INTO blocks VALUES(310094,'2a8f976f20c4e89ff01071915ac96ee35192d54df3a246bf61fd4a0cccfb5b23',310094000,NULL,NULL,'adea7b4cacc06ba1f7dc260f30039943936f5baeecf5a8a452d4cbcaa994a70d','10ef44a0abadcb379d361a787308d50ac982c88df84d2b900b6ba38f1631c9c1','ccb01eb91ebcff80dc5f2c164f8be09ce38e62e033d1dfab228a37e4102a3dbd');
INSERT INTO blocks VALUES(310095,'bed0fa40c9981223fb40b3be8124ca619edc9dd34d0c907369477ea92e5d2cd2',310095000,NULL,NULL,'a2290c6a24befab16b4d9ed768c3129d582edbafdf8a2326c7ed50397e5db674','4b5424b0524e870f3ffac34dab99a2e997bd2dede0daae5c87f972e3dec6f009','991d7774d8d8fdc15ec45a918b070408e495b7ad633a7e1e11e58626f90a6033');
INSERT INTO blocks VALUES(310096,'306aeec3db435fabffdf88c2f26ee83caa4c2426375a33daa2be041dbd27ea2f',310096000,NULL,NULL,'b3c321ea2fb119cbaacfb39f219be47cb346cdd40d895980afd34b4157a3b7ec','0370a8165e6fbc0137f2773587f874008ba0ed309bdb21c2cc328f11a46c3b42','de3d7542e29d12e0802a879a98a335f61f6ad448a7a292fea3af6818e641bd59');
INSERT INTO blocks VALUES(310097,'13e8e16e67c7cdcc80d477491e554b43744f90e8e1a9728439a11fab42cefadf',310097000,NULL,NULL,'456a1bd4d6b30f24e798a9c1f975af109db030b0bca19db6b29788f938ce6c4d','044b7c3397fdc7ad2b0d8dd25d011c8cb785140e231ceb13f25b333bf9122379','808fd1894195de6c2dde5bb72389f9e469c9a5fd688f9456154e4deceff21d28');
INSERT INTO blocks VALUES(310098,'ca5bca4b5ec4fa6183e05176abe921cff884c4e20910fab55b603cef48dc3bca',310098000,NULL,NULL,'f48d6574488a24155420ae76aa7dcecfe73f6a262a2434a96eb2e93f6bbf02b6','d440d64101c114cf0d07a6965620ea87865bb38516a6a9df027b56a8568ec001','d3a8877e8da2dca536a3adcd6f41520ff0a8688427da84f5154e6e246d516950');
INSERT INTO blocks VALUES(310099,'3c4c2279cd7de0add5ec469648a845875495a7d54ebfb5b012dcc5a197b7992a',310099000,NULL,NULL,'e936debeb5d219215ba24e56ed34edb435131877c2947c0801824155fdc70c05','1c917e55ecc05094872120d52dde49cd59b02716df14d3771a3bc46ff455e7d0','e0b4a4b31d6b1a1305c39ec7fd6e77e119ac6ffbf562028b478a7b5ee885bb90');
INSERT INTO blocks VALUES(310100,'96925c05b3c7c80c716f5bef68d161c71d044252c766ca0e3f17f255764242cb',310100000,NULL,NULL,'2b033a615b9eb693ed59daca9bc047f61a3519bec5c2b64f968cf717c75afe79','21db85905d11a6b7b8e2bd82552b452e6e1add9bb7f8d7f96b1754f8f6d57c38','351395f48df2c3993cfad6e7229956568ca0f44206a55308cc5e7b2feb85b590');
INSERT INTO blocks VALUES(310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,NULL,NULL,'6a41dd11d8b611f6fde79e06a4f65d20fc15419f8336646130c02e9f7d87eff4','5f385ceec78dabb1637a9fcfbaccf8759b0abb9e4539afec68d56fca4fe72ab8','d5e75b7eeeaa2da2a00ac4876877c8eb17fd7fca62cf365e9c9af6b6e78c7b54');
-- Triggers and indices on  blocks
CREATE INDEX block_index_idx ON blocks (block_index);
CREATE INDEX index_hash_idx ON blocks (block_index, block_hash);

-- Table  broadcasts
DROP TABLE IF EXISTS broadcasts;
CREATE TABLE broadcasts(
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
INSERT INTO broadcasts VALUES(12,'a21533ad03334823cca2aa8e57c383113a7f93a5810c5df8dd2fa70f6eec416d',310011,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1388000000,100.0,99999999,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(19,'f020ae6c0b1aadbba4893581678ef87f9d2a925be5e6b08d02440e213f6183b4',310018,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1388000050,99.86166,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(20,'dccbd8852c8d489d32f87be0c86a631b63ec50202b0109a2be6aa96f27f89600',310019,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1388000101,100.343,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(21,'457f36dccce6664a8e28b00ebf47aa60ba4a41b46642aceef0e2a297429eb64e',310020,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1388000201,2.0,5000000,'Unit Test',0,'valid');
-- Triggers and indices on  broadcasts
CREATE TRIGGER _broadcasts_delete BEFORE DELETE ON broadcasts BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO broadcasts(rowid,tx_index,tx_hash,block_index,source,timestamp,value,fee_fraction_int,text,locked,status) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.timestamp)||','||quote(old.value)||','||quote(old.fee_fraction_int)||','||quote(old.text)||','||quote(old.locked)||','||quote(old.status)||')');
                            END;
CREATE TRIGGER _broadcasts_insert AFTER INSERT ON broadcasts BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM broadcasts WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _broadcasts_update AFTER UPDATE ON broadcasts BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE broadcasts SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',timestamp='||quote(old.timestamp)||',value='||quote(old.value)||',fee_fraction_int='||quote(old.fee_fraction_int)||',text='||quote(old.text)||',locked='||quote(old.locked)||',status='||quote(old.status)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX status_source_idx ON broadcasts (status, source);
CREATE INDEX status_source_index_idx ON broadcasts (status, source, tx_index);
CREATE INDEX timestamp_idx ON broadcasts (timestamp);

-- Table  btcpays
DROP TABLE IF EXISTS btcpays;
CREATE TABLE btcpays(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      destination TEXT,
                      btc_amount INTEGER,
                      order_match_id TEXT,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
INSERT INTO btcpays VALUES(5,'ed17dc38233838e15d319a1786825b9e7cdba815554c9d6f4dd527615bce10b8',310004,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',50000000,'332b030da57b9565324df01414778b1eafbee6c52343fea80774ee1725484367_f093b6c00e1bbe85106db6874b1ab4e3f4378d0bf0bcffbd8b51835285dfbf3f','valid');
-- Triggers and indices on  btcpays
CREATE TRIGGER _btcpays_delete BEFORE DELETE ON btcpays BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO btcpays(rowid,tx_index,tx_hash,block_index,source,destination,btc_amount,order_match_id,status) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.destination)||','||quote(old.btc_amount)||','||quote(old.order_match_id)||','||quote(old.status)||')');
                            END;
CREATE TRIGGER _btcpays_insert AFTER INSERT ON btcpays BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM btcpays WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _btcpays_update AFTER UPDATE ON btcpays BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE btcpays SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',destination='||quote(old.destination)||',btc_amount='||quote(old.btc_amount)||',order_match_id='||quote(old.order_match_id)||',status='||quote(old.status)||' WHERE rowid='||old.rowid);
                            END;

-- Table  burns
DROP TABLE IF EXISTS burns;
CREATE TABLE burns(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      burned INTEGER,
                      earned INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
INSERT INTO burns VALUES(1,'9b6b1abb696d8d1b70c5beed046d7cddd23cd95b69ef18946cb18c5b56cfde30',310000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',62000000,93000000000,'valid');
INSERT INTO burns VALUES(23,'c81cd36f1efabd22f1a00923714fd5a5f1ba07852ef1f0763223563e3f55dfda',310022,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',38000000,56999887262,'valid');
-- Triggers and indices on  burns
CREATE TRIGGER _burns_delete BEFORE DELETE ON burns BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO burns(rowid,tx_index,tx_hash,block_index,source,burned,earned,status) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.burned)||','||quote(old.earned)||','||quote(old.status)||')');
                            END;
CREATE TRIGGER _burns_insert AFTER INSERT ON burns BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM burns WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _burns_update AFTER UPDATE ON burns BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE burns SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',burned='||quote(old.burned)||',earned='||quote(old.earned)||',status='||quote(old.status)||' WHERE rowid='||old.rowid);
                            END;

-- Table  cancels
DROP TABLE IF EXISTS cancels;
CREATE TABLE cancels(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      offer_hash TEXT,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
-- Triggers and indices on  cancels
CREATE TRIGGER _cancels_delete BEFORE DELETE ON cancels BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO cancels(rowid,tx_index,tx_hash,block_index,source,offer_hash,status) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.offer_hash)||','||quote(old.status)||')');
                            END;
CREATE TRIGGER _cancels_insert AFTER INSERT ON cancels BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM cancels WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _cancels_update AFTER UPDATE ON cancels BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE cancels SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',offer_hash='||quote(old.offer_hash)||',status='||quote(old.status)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX cancels_block_index_idx ON cancels (block_index);

-- Table  credits
DROP TABLE IF EXISTS credits;
CREATE TABLE credits(
                      block_index INTEGER,
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER,
                      calling_function TEXT,
                      event TEXT,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index));
INSERT INTO credits VALUES(310000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',93000000000,'burn','9b6b1abb696d8d1b70c5beed046d7cddd23cd95b69ef18946cb18c5b56cfde30');
INSERT INTO credits VALUES(310001,'1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',50000000,'send','58e839ec2b1584d3474014093393ce57e5c22d6e686213ee4a7a0abe7bbac33c');
INSERT INTO credits VALUES(310004,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',100000000,'btcpay','ed17dc38233838e15d319a1786825b9e7cdba815554c9d6f4dd527615bce10b8');
INSERT INTO credits VALUES(310005,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB',1000000000,'issuance','cd2b44cb56dd5aaae1181c42ab8953ebb9d0fb8e177e960ffe55e3500b3aae25');
INSERT INTO credits VALUES(310006,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',100000,'issuance','38ac60a8d36a01a1489572df7e787da96a9af013adc0f4fe2e6098cea44840cf');
INSERT INTO credits VALUES(310007,'1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB',4000000,'send','f337451a19eac3c2fe66daf7d44d39c41a012d2dfd85de90cc3877bbc2e7d30c');
INSERT INTO credits VALUES(310008,'1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',526,'send','c639e9482b31b487115b4437dd87cff98338003fabf18066bf051e1164aa4394');
INSERT INTO credits VALUES(310009,'1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',24,'dividend','7881c1fe7881a590d09302dde67cfd888a74154888e0c310bd01575f560b8ac8');
INSERT INTO credits VALUES(310010,'1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',420800,'dividend','c41898ad625e2236110101070c09e9f28b6fea1ed436ecb78f231f3f99f123f7');
INSERT INTO credits VALUES(310013,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',4250000,'filled','6a5f30666a5f24b6e0e6f31cf06b22ee74d3e692a550297450bdf1d36b1cc167');
INSERT INTO credits VALUES(310014,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',5000000,'cancel order','f093b6c00e1bbe85106db6874b1ab4e3f4378d0bf0bcffbd8b51835285dfbf3f');
INSERT INTO credits VALUES(310015,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',0,'filled','65db3ab58b65891a947ab9bdba4723e907678bf3b48397add62802dcc65d1d8e');
INSERT INTO credits VALUES(310015,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',0,'filled','65db3ab58b65891a947ab9bdba4723e907678bf3b48397add62802dcc65d1d8e');
INSERT INTO credits VALUES(310017,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',0,'filled','a7daff1ca2874f6b18a8f1a1e70db27f58c6b39a9f106c353223fbccde57098e');
INSERT INTO credits VALUES(310017,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',0,'filled','a7daff1ca2874f6b18a8f1a1e70db27f58c6b39a9f106c353223fbccde57098e');
INSERT INTO credits VALUES(310018,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',59137500,'bet settled: liquidated for bear','f020ae6c0b1aadbba4893581678ef87f9d2a925be5e6b08d02440e213f6183b4');
INSERT INTO credits VALUES(310018,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',3112500,'feed fee','f020ae6c0b1aadbba4893581678ef87f9d2a925be5e6b08d02440e213f6183b4');
INSERT INTO credits VALUES(310019,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',159300000,'bet settled','dccbd8852c8d489d32f87be0c86a631b63ec50202b0109a2be6aa96f27f89600');
INSERT INTO credits VALUES(310019,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',315700000,'bet settled','dccbd8852c8d489d32f87be0c86a631b63ec50202b0109a2be6aa96f27f89600');
INSERT INTO credits VALUES(310019,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',25000000,'feed fee','dccbd8852c8d489d32f87be0c86a631b63ec50202b0109a2be6aa96f27f89600');
INSERT INTO credits VALUES(310020,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',1330000000,'bet settled: for notequal','457f36dccce6664a8e28b00ebf47aa60ba4a41b46642aceef0e2a297429eb64e');
INSERT INTO credits VALUES(310020,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',70000000,'feed fee','457f36dccce6664a8e28b00ebf47aa60ba4a41b46642aceef0e2a297429eb64e');
INSERT INTO credits VALUES(310022,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',56999887262,'burn','c81cd36f1efabd22f1a00923714fd5a5f1ba07852ef1f0763223563e3f55dfda');
INSERT INTO credits VALUES(310023,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',8500000,'recredit wager remaining','74062934f0a97c41851735fef2a7df4d9ad9945424f09a54281e145a5e32492f');
INSERT INTO credits VALUES(310023,'1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',10000,'send','c576ecde0f86c86725b540c9f5e6ae57a378fe9694260f7859eca55613d9d341');
INSERT INTO credits VALUES(310032,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB',50000000,'cancel order','6cb08a1c0547ab0d0d37b74633c1c8a2fd2372d9fd72eb3abdea298f2b245fee');
-- Triggers and indices on  credits
CREATE TRIGGER _credits_delete BEFORE DELETE ON credits BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO credits(rowid,block_index,address,asset,quantity,calling_function,event) VALUES('||old.rowid||','||quote(old.block_index)||','||quote(old.address)||','||quote(old.asset)||','||quote(old.quantity)||','||quote(old.calling_function)||','||quote(old.event)||')');
                            END;
CREATE TRIGGER _credits_insert AFTER INSERT ON credits BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM credits WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _credits_update AFTER UPDATE ON credits BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE credits SET block_index='||quote(old.block_index)||',address='||quote(old.address)||',asset='||quote(old.asset)||',quantity='||quote(old.quantity)||',calling_function='||quote(old.calling_function)||',event='||quote(old.event)||' WHERE rowid='||old.rowid);
                            END;

-- Table  debits
DROP TABLE IF EXISTS debits;
CREATE TABLE debits(
                      block_index INTEGER,
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER,
                      action TEXT,
                      event TEXT,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index));
INSERT INTO debits VALUES(310001,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',50000000,'send','58e839ec2b1584d3474014093393ce57e5c22d6e686213ee4a7a0abe7bbac33c');
INSERT INTO debits VALUES(310003,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',105000000,'open order','f093b6c00e1bbe85106db6874b1ab4e3f4378d0bf0bcffbd8b51835285dfbf3f');
INSERT INTO debits VALUES(310005,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',50000000,'issuance fee','cd2b44cb56dd5aaae1181c42ab8953ebb9d0fb8e177e960ffe55e3500b3aae25');
INSERT INTO debits VALUES(310006,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',50000000,'issuance fee','38ac60a8d36a01a1489572df7e787da96a9af013adc0f4fe2e6098cea44840cf');
INSERT INTO debits VALUES(310007,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB',4000000,'send','f337451a19eac3c2fe66daf7d44d39c41a012d2dfd85de90cc3877bbc2e7d30c');
INSERT INTO debits VALUES(310008,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',526,'send','c639e9482b31b487115b4437dd87cff98338003fabf18066bf051e1164aa4394');
INSERT INTO debits VALUES(310009,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',24,'dividend','7881c1fe7881a590d09302dde67cfd888a74154888e0c310bd01575f560b8ac8');
INSERT INTO debits VALUES(310009,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',20000,'dividend fee','7881c1fe7881a590d09302dde67cfd888a74154888e0c310bd01575f560b8ac8');
INSERT INTO debits VALUES(310010,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',420800,'dividend','c41898ad625e2236110101070c09e9f28b6fea1ed436ecb78f231f3f99f123f7');
INSERT INTO debits VALUES(310010,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',20000,'dividend fee','c41898ad625e2236110101070c09e9f28b6fea1ed436ecb78f231f3f99f123f7');
INSERT INTO debits VALUES(310012,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',50000000,'bet','74062934f0a97c41851735fef2a7df4d9ad9945424f09a54281e145a5e32492f');
INSERT INTO debits VALUES(310013,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',25000000,'bet','6a5f30666a5f24b6e0e6f31cf06b22ee74d3e692a550297450bdf1d36b1cc167');
INSERT INTO debits VALUES(310014,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',150000000,'bet','2066b9a6b8913412384a0401ef57bfc604e7c5a2c141e23111a8ccc6881b0fb3');
INSERT INTO debits VALUES(310015,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',350000000,'bet','65db3ab58b65891a947ab9bdba4723e907678bf3b48397add62802dcc65d1d8e');
INSERT INTO debits VALUES(310016,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',750000000,'bet','94b11df6b519372bfbcf0ec5f3e6465a63e323c7cd7cff83a8abd78596d4bce4');
INSERT INTO debits VALUES(310017,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',650000000,'bet','a7daff1ca2874f6b18a8f1a1e70db27f58c6b39a9f106c353223fbccde57098e');
INSERT INTO debits VALUES(310021,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB',50000000,'open order','6cb08a1c0547ab0d0d37b74633c1c8a2fd2372d9fd72eb3abdea298f2b245fee');
INSERT INTO debits VALUES(310023,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',10000,'send','c576ecde0f86c86725b540c9f5e6ae57a378fe9694260f7859eca55613d9d341');
-- Triggers and indices on  debits
CREATE TRIGGER _debits_delete BEFORE DELETE ON debits BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO debits(rowid,block_index,address,asset,quantity,action,event) VALUES('||old.rowid||','||quote(old.block_index)||','||quote(old.address)||','||quote(old.asset)||','||quote(old.quantity)||','||quote(old.action)||','||quote(old.event)||')');
                            END;
CREATE TRIGGER _debits_insert AFTER INSERT ON debits BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM debits WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _debits_update AFTER UPDATE ON debits BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE debits SET block_index='||quote(old.block_index)||',address='||quote(old.address)||',asset='||quote(old.asset)||',quantity='||quote(old.quantity)||',action='||quote(old.action)||',event='||quote(old.event)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX address_idx ON debits (address);
CREATE INDEX asset_idx ON debits (asset);

-- Table  destructions
DROP TABLE IF EXISTS destructions;
CREATE TABLE destructions(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      asset INTEGER,
                      quantity INTEGER,
                      tag TEXT,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
-- Triggers and indices on  destructions
CREATE TRIGGER _destructions_delete BEFORE DELETE ON destructions BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO destructions(rowid,tx_index,tx_hash,block_index,source,asset,quantity,tag,status) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.asset)||','||quote(old.quantity)||','||quote(old.tag)||','||quote(old.status)||')');
                            END;
CREATE TRIGGER _destructions_insert AFTER INSERT ON destructions BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM destructions WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _destructions_update AFTER UPDATE ON destructions BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE destructions SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',asset='||quote(old.asset)||',quantity='||quote(old.quantity)||',tag='||quote(old.tag)||',status='||quote(old.status)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX status_idx ON destructions (status);

-- Table  dispenser_refills
DROP TABLE IF EXISTS dispenser_refills;
CREATE TABLE dispenser_refills(
                      tx_index INTEGER,
                      tx_hash TEXT,
                      block_index INTEGER,
                      source TEXT,
                      destination TEXT,
                      asset TEXT,
                      dispense_quantity INTEGER,
                      dispenser_tx_hash TEXT,
                      PRIMARY KEY (tx_index, tx_hash, source, destination),
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
-- Triggers and indices on  dispenser_refills
CREATE TRIGGER _dispenser_refills_delete BEFORE DELETE ON dispenser_refills BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO dispenser_refills(rowid,tx_index,tx_hash,block_index,source,destination,asset,dispense_quantity,dispenser_tx_hash) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.destination)||','||quote(old.asset)||','||quote(old.dispense_quantity)||','||quote(old.dispenser_tx_hash)||')');
                            END;
CREATE TRIGGER _dispenser_refills_insert AFTER INSERT ON dispenser_refills BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM dispenser_refills WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _dispenser_refills_update AFTER UPDATE ON dispenser_refills BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE dispenser_refills SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',destination='||quote(old.destination)||',asset='||quote(old.asset)||',dispense_quantity='||quote(old.dispense_quantity)||',dispenser_tx_hash='||quote(old.dispenser_tx_hash)||' WHERE rowid='||old.rowid);
                            END;

-- Table  dispensers
DROP TABLE IF EXISTS dispensers;
CREATE TABLE dispensers(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      asset TEXT,
                      give_quantity INTEGER,
                      escrow_quantity INTEGER,
                      satoshirate INTEGER,
                      status INTEGER,
                      give_remaining INTEGER, oracle_address TEXT, last_status_tx_hash TEXT, origin TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
-- Triggers and indices on  dispensers
CREATE TRIGGER _dispensers_delete BEFORE DELETE ON dispensers BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO dispensers(rowid,tx_index,tx_hash,block_index,source,asset,give_quantity,escrow_quantity,satoshirate,status,give_remaining,oracle_address,last_status_tx_hash,origin) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.asset)||','||quote(old.give_quantity)||','||quote(old.escrow_quantity)||','||quote(old.satoshirate)||','||quote(old.status)||','||quote(old.give_remaining)||','||quote(old.oracle_address)||','||quote(old.last_status_tx_hash)||','||quote(old.origin)||')');
                            END;
CREATE TRIGGER _dispensers_insert AFTER INSERT ON dispensers BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM dispensers WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _dispensers_update AFTER UPDATE ON dispensers BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE dispensers SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',asset='||quote(old.asset)||',give_quantity='||quote(old.give_quantity)||',escrow_quantity='||quote(old.escrow_quantity)||',satoshirate='||quote(old.satoshirate)||',status='||quote(old.status)||',give_remaining='||quote(old.give_remaining)||',oracle_address='||quote(old.oracle_address)||',last_status_tx_hash='||quote(old.last_status_tx_hash)||',origin='||quote(old.origin)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX dispensers_asset_idx ON dispensers (asset);
CREATE INDEX dispensers_source_idx ON dispensers (source);

-- Table  dispenses
DROP TABLE IF EXISTS dispenses;
CREATE TABLE dispenses(
                      tx_index INTEGER,
                      dispense_index INTEGER,
                      tx_hash TEXT,
                      block_index INTEGER,
                      source TEXT,
                      destination TEXT,
                      asset TEXT,
                      dispense_quantity INTEGER,
                      dispenser_tx_hash TEXT,
                      PRIMARY KEY (tx_index, dispense_index, source, destination),
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
-- Triggers and indices on  dispenses
CREATE TRIGGER _dispenses_delete BEFORE DELETE ON dispenses BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO dispenses(rowid,tx_index,dispense_index,tx_hash,block_index,source,destination,asset,dispense_quantity,dispenser_tx_hash) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.dispense_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.destination)||','||quote(old.asset)||','||quote(old.dispense_quantity)||','||quote(old.dispenser_tx_hash)||')');
                            END;
CREATE TRIGGER _dispenses_insert AFTER INSERT ON dispenses BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM dispenses WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _dispenses_update AFTER UPDATE ON dispenses BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE dispenses SET tx_index='||quote(old.tx_index)||',dispense_index='||quote(old.dispense_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',destination='||quote(old.destination)||',asset='||quote(old.asset)||',dispense_quantity='||quote(old.dispense_quantity)||',dispenser_tx_hash='||quote(old.dispenser_tx_hash)||' WHERE rowid='||old.rowid);
                            END;

-- Table  dividends
DROP TABLE IF EXISTS dividends;
CREATE TABLE dividends(
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
INSERT INTO dividends VALUES(10,'7881c1fe7881a590d09302dde67cfd888a74154888e0c310bd01575f560b8ac8',310009,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB','XCP',600,20000,'valid');
INSERT INTO dividends VALUES(11,'c41898ad625e2236110101070c09e9f28b6fea1ed436ecb78f231f3f99f123f7',310010,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC','XCP',800,20000,'valid');
-- Triggers and indices on  dividends
CREATE TRIGGER _dividends_delete BEFORE DELETE ON dividends BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO dividends(rowid,tx_index,tx_hash,block_index,source,asset,dividend_asset,quantity_per_unit,fee_paid,status) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.asset)||','||quote(old.dividend_asset)||','||quote(old.quantity_per_unit)||','||quote(old.fee_paid)||','||quote(old.status)||')');
                            END;
CREATE TRIGGER _dividends_insert AFTER INSERT ON dividends BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM dividends WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _dividends_update AFTER UPDATE ON dividends BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE dividends SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',asset='||quote(old.asset)||',dividend_asset='||quote(old.dividend_asset)||',quantity_per_unit='||quote(old.quantity_per_unit)||',fee_paid='||quote(old.fee_paid)||',status='||quote(old.status)||' WHERE rowid='||old.rowid);
                            END;

-- Table  issuances
DROP TABLE IF EXISTS issuances;
CREATE TABLE "issuances"(
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
INSERT INTO issuances VALUES(6,'cd2b44cb56dd5aaae1181c42ab8953ebb9d0fb8e177e960ffe55e3500b3aae25',0,310005,'BBBB',1000000000,1,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',0,0,0,0.0,'',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(7,'38ac60a8d36a01a1489572df7e787da96a9af013adc0f4fe2e6098cea44840cf',0,310006,'BBBC',100000,0,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',0,0,0,0.0,'',50000000,0,'valid',NULL,0);
-- Triggers and indices on  issuances
CREATE TRIGGER _issuances_delete BEFORE DELETE ON issuances BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO issuances(rowid,tx_index,tx_hash,msg_index,block_index,asset,quantity,divisible,source,issuer,transfer,callable,call_date,call_price,description,fee_paid,locked,status,asset_longname,reset) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.msg_index)||','||quote(old.block_index)||','||quote(old.asset)||','||quote(old.quantity)||','||quote(old.divisible)||','||quote(old.source)||','||quote(old.issuer)||','||quote(old.transfer)||','||quote(old.callable)||','||quote(old.call_date)||','||quote(old.call_price)||','||quote(old.description)||','||quote(old.fee_paid)||','||quote(old.locked)||','||quote(old.status)||','||quote(old.asset_longname)||','||quote(old.reset)||')');
                            END;
CREATE TRIGGER _issuances_insert AFTER INSERT ON issuances BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM issuances WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _issuances_update AFTER UPDATE ON issuances BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE issuances SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',msg_index='||quote(old.msg_index)||',block_index='||quote(old.block_index)||',asset='||quote(old.asset)||',quantity='||quote(old.quantity)||',divisible='||quote(old.divisible)||',source='||quote(old.source)||',issuer='||quote(old.issuer)||',transfer='||quote(old.transfer)||',callable='||quote(old.callable)||',call_date='||quote(old.call_date)||',call_price='||quote(old.call_price)||',description='||quote(old.description)||',fee_paid='||quote(old.fee_paid)||',locked='||quote(old.locked)||',status='||quote(old.status)||',asset_longname='||quote(old.asset_longname)||',reset='||quote(old.reset)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX valid_asset_idx ON issuances (asset, status);

-- Table  mempool
DROP TABLE IF EXISTS mempool;
CREATE TABLE mempool(
                      tx_hash TEXT,
                      command TEXT,
                      category TEXT,
                      bindings TEXT,
                      timestamp INTEGER);

-- Table  messages
DROP TABLE IF EXISTS messages;
CREATE TABLE messages(
                      message_index INTEGER PRIMARY KEY,
                      block_index INTEGER,
                      command TEXT,
                      category TEXT,
                      bindings TEXT,
                      timestamp INTEGER);
INSERT INTO messages VALUES(0,309999,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(1,310000,'insert','replace','[''block_index'', ''first_undo_index'']',0);
INSERT INTO messages VALUES(2,310000,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(3,310000,'insert','burns','[''block_index'', ''burned'', ''earned'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(4,310001,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(5,310001,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(6,310001,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(7,310001,'insert','sends','[''asset'', ''block_index'', ''destination'', ''quantity'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(8,310002,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(9,310002,'insert','orders','[''block_index'', ''expiration'', ''expire_index'', ''fee_provided'', ''fee_provided_remaining'', ''fee_required'', ''fee_required_remaining'', ''get_asset'', ''get_quantity'', ''get_remaining'', ''give_asset'', ''give_quantity'', ''give_remaining'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(10,310003,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(11,310003,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(12,310003,'insert','orders','[''block_index'', ''expiration'', ''expire_index'', ''fee_provided'', ''fee_provided_remaining'', ''fee_required'', ''fee_required_remaining'', ''get_asset'', ''get_quantity'', ''get_remaining'', ''give_asset'', ''give_quantity'', ''give_remaining'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(13,310003,'update','orders','[''fee_provided_remaining'', ''fee_required_remaining'', ''get_remaining'', ''give_remaining'', ''status'', ''tx_hash'']',0);
INSERT INTO messages VALUES(14,310003,'update','orders','[''fee_provided_remaining'', ''fee_required_remaining'', ''get_remaining'', ''give_remaining'', ''status'', ''tx_hash'']',0);
INSERT INTO messages VALUES(15,310003,'insert','order_matches','[''backward_asset'', ''backward_quantity'', ''block_index'', ''fee_paid'', ''forward_asset'', ''forward_quantity'', ''id'', ''match_expire_index'', ''status'', ''tx0_address'', ''tx0_block_index'', ''tx0_expiration'', ''tx0_hash'', ''tx0_index'', ''tx1_address'', ''tx1_block_index'', ''tx1_expiration'', ''tx1_hash'', ''tx1_index'']',0);
INSERT INTO messages VALUES(16,310004,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(17,310004,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(18,310004,'update','order_matches','[''order_match_id'', ''status'']',0);
INSERT INTO messages VALUES(19,310004,'insert','btcpays','[''block_index'', ''btc_amount'', ''destination'', ''order_match_id'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(20,310005,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(21,310005,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(22,310005,'insert','issuances','[''asset'', ''asset_longname'', ''block_index'', ''call_date'', ''call_price'', ''callable'', ''description'', ''divisible'', ''fee_paid'', ''issuer'', ''locked'', ''quantity'', ''reset'', ''source'', ''status'', ''transfer'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(23,310005,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(24,310006,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(25,310006,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(26,310006,'insert','issuances','[''asset'', ''asset_longname'', ''block_index'', ''call_date'', ''call_price'', ''callable'', ''description'', ''divisible'', ''fee_paid'', ''issuer'', ''locked'', ''quantity'', ''reset'', ''source'', ''status'', ''transfer'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(27,310006,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(28,310007,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(29,310007,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(30,310007,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(31,310007,'insert','sends','[''asset'', ''block_index'', ''destination'', ''quantity'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(32,310008,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(33,310008,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(34,310008,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(35,310008,'insert','sends','[''asset'', ''block_index'', ''destination'', ''quantity'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(36,310009,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(37,310009,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(38,310009,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(39,310009,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(40,310009,'insert','dividends','[''asset'', ''block_index'', ''dividend_asset'', ''fee_paid'', ''quantity_per_unit'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(41,310010,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(42,310010,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(43,310010,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(44,310010,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(45,310010,'insert','dividends','[''asset'', ''block_index'', ''dividend_asset'', ''fee_paid'', ''quantity_per_unit'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(46,310011,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(47,310011,'insert','broadcasts','[''block_index'', ''fee_fraction_int'', ''locked'', ''source'', ''status'', ''text'', ''timestamp'', ''tx_hash'', ''tx_index'', ''value'']',0);
INSERT INTO messages VALUES(48,310012,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(49,310012,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(50,310012,'insert','bets','[''bet_type'', ''block_index'', ''counterwager_quantity'', ''counterwager_remaining'', ''deadline'', ''expiration'', ''expire_index'', ''fee_fraction_int'', ''feed_address'', ''leverage'', ''source'', ''status'', ''target_value'', ''tx_hash'', ''tx_index'', ''wager_quantity'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(51,310013,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(52,310013,'update','orders','[''status'', ''tx_hash'']',0);
INSERT INTO messages VALUES(53,310013,'insert','order_expirations','[''block_index'', ''order_hash'', ''order_index'', ''source'']',0);
INSERT INTO messages VALUES(54,310013,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(55,310013,'insert','bets','[''bet_type'', ''block_index'', ''counterwager_quantity'', ''counterwager_remaining'', ''deadline'', ''expiration'', ''expire_index'', ''fee_fraction_int'', ''feed_address'', ''leverage'', ''source'', ''status'', ''target_value'', ''tx_hash'', ''tx_index'', ''wager_quantity'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(56,310013,'update','bets','[''counterwager_remaining'', ''status'', ''tx_hash'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(57,310013,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(58,310013,'update','bets','[''counterwager_remaining'', ''status'', ''tx_hash'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(59,310013,'insert','bet_matches','[''backward_quantity'', ''block_index'', ''deadline'', ''fee_fraction_int'', ''feed_address'', ''forward_quantity'', ''id'', ''initial_value'', ''leverage'', ''match_expire_index'', ''status'', ''target_value'', ''tx0_address'', ''tx0_bet_type'', ''tx0_block_index'', ''tx0_expiration'', ''tx0_hash'', ''tx0_index'', ''tx1_address'', ''tx1_bet_type'', ''tx1_block_index'', ''tx1_expiration'', ''tx1_hash'', ''tx1_index'']',0);
INSERT INTO messages VALUES(60,310014,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(61,310014,'update','orders','[''status'', ''tx_hash'']',0);
INSERT INTO messages VALUES(62,310014,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(63,310014,'insert','order_expirations','[''block_index'', ''order_hash'', ''order_index'', ''source'']',0);
INSERT INTO messages VALUES(64,310014,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(65,310014,'insert','bets','[''bet_type'', ''block_index'', ''counterwager_quantity'', ''counterwager_remaining'', ''deadline'', ''expiration'', ''expire_index'', ''fee_fraction_int'', ''feed_address'', ''leverage'', ''source'', ''status'', ''target_value'', ''tx_hash'', ''tx_index'', ''wager_quantity'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(66,310015,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(67,310015,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(68,310015,'insert','bets','[''bet_type'', ''block_index'', ''counterwager_quantity'', ''counterwager_remaining'', ''deadline'', ''expiration'', ''expire_index'', ''fee_fraction_int'', ''feed_address'', ''leverage'', ''source'', ''status'', ''target_value'', ''tx_hash'', ''tx_index'', ''wager_quantity'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(69,310015,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(70,310015,'update','bets','[''counterwager_remaining'', ''status'', ''tx_hash'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(71,310015,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(72,310015,'update','bets','[''counterwager_remaining'', ''status'', ''tx_hash'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(73,310015,'insert','bet_matches','[''backward_quantity'', ''block_index'', ''deadline'', ''fee_fraction_int'', ''feed_address'', ''forward_quantity'', ''id'', ''initial_value'', ''leverage'', ''match_expire_index'', ''status'', ''target_value'', ''tx0_address'', ''tx0_bet_type'', ''tx0_block_index'', ''tx0_expiration'', ''tx0_hash'', ''tx0_index'', ''tx1_address'', ''tx1_bet_type'', ''tx1_block_index'', ''tx1_expiration'', ''tx1_hash'', ''tx1_index'']',0);
INSERT INTO messages VALUES(74,310016,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(75,310016,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(76,310016,'insert','bets','[''bet_type'', ''block_index'', ''counterwager_quantity'', ''counterwager_remaining'', ''deadline'', ''expiration'', ''expire_index'', ''fee_fraction_int'', ''feed_address'', ''leverage'', ''source'', ''status'', ''target_value'', ''tx_hash'', ''tx_index'', ''wager_quantity'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(77,310017,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(78,310017,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(79,310017,'insert','bets','[''bet_type'', ''block_index'', ''counterwager_quantity'', ''counterwager_remaining'', ''deadline'', ''expiration'', ''expire_index'', ''fee_fraction_int'', ''feed_address'', ''leverage'', ''source'', ''status'', ''target_value'', ''tx_hash'', ''tx_index'', ''wager_quantity'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(80,310017,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(81,310017,'update','bets','[''counterwager_remaining'', ''status'', ''tx_hash'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(82,310017,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(83,310017,'update','bets','[''counterwager_remaining'', ''status'', ''tx_hash'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(84,310017,'insert','bet_matches','[''backward_quantity'', ''block_index'', ''deadline'', ''fee_fraction_int'', ''feed_address'', ''forward_quantity'', ''id'', ''initial_value'', ''leverage'', ''match_expire_index'', ''status'', ''target_value'', ''tx0_address'', ''tx0_bet_type'', ''tx0_block_index'', ''tx0_expiration'', ''tx0_hash'', ''tx0_index'', ''tx1_address'', ''tx1_bet_type'', ''tx1_block_index'', ''tx1_expiration'', ''tx1_hash'', ''tx1_index'']',0);
INSERT INTO messages VALUES(85,310018,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(86,310018,'insert','broadcasts','[''block_index'', ''fee_fraction_int'', ''locked'', ''source'', ''status'', ''text'', ''timestamp'', ''tx_hash'', ''tx_index'', ''value'']',0);
INSERT INTO messages VALUES(87,310018,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(88,310018,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(89,310018,'insert','bet_match_resolutions','[''bear_credit'', ''bet_match_id'', ''bet_match_type_id'', ''block_index'', ''bull_credit'', ''escrow_less_fee'', ''fee'', ''settled'', ''winner'']',0);
INSERT INTO messages VALUES(90,310018,'update','bet_matches','[''bet_match_id'', ''status'']',0);
INSERT INTO messages VALUES(91,310019,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(92,310019,'insert','broadcasts','[''block_index'', ''fee_fraction_int'', ''locked'', ''source'', ''status'', ''text'', ''timestamp'', ''tx_hash'', ''tx_index'', ''value'']',0);
INSERT INTO messages VALUES(93,310019,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(94,310019,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(95,310019,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(96,310019,'insert','bet_match_resolutions','[''bear_credit'', ''bet_match_id'', ''bet_match_type_id'', ''block_index'', ''bull_credit'', ''escrow_less_fee'', ''fee'', ''settled'', ''winner'']',0);
INSERT INTO messages VALUES(97,310019,'update','bet_matches','[''bet_match_id'', ''status'']',0);
INSERT INTO messages VALUES(98,310020,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(99,310020,'insert','broadcasts','[''block_index'', ''fee_fraction_int'', ''locked'', ''source'', ''status'', ''text'', ''timestamp'', ''tx_hash'', ''tx_index'', ''value'']',0);
INSERT INTO messages VALUES(100,310020,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(101,310020,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(102,310020,'insert','bet_match_resolutions','[''bear_credit'', ''bet_match_id'', ''bet_match_type_id'', ''block_index'', ''bull_credit'', ''escrow_less_fee'', ''fee'', ''settled'', ''winner'']',0);
INSERT INTO messages VALUES(103,310020,'update','bet_matches','[''bet_match_id'', ''status'']',0);
INSERT INTO messages VALUES(104,310021,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(105,310021,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(106,310021,'insert','orders','[''block_index'', ''expiration'', ''expire_index'', ''fee_provided'', ''fee_provided_remaining'', ''fee_required'', ''fee_required_remaining'', ''get_asset'', ''get_quantity'', ''get_remaining'', ''give_asset'', ''give_quantity'', ''give_remaining'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(107,310022,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(108,310022,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(109,310022,'insert','burns','[''block_index'', ''burned'', ''earned'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(110,310023,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(111,310023,'update','bets','[''status'', ''tx_hash'']',0);
INSERT INTO messages VALUES(112,310023,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(113,310023,'insert','bet_expirations','[''bet_hash'', ''bet_index'', ''block_index'', ''source'']',0);
INSERT INTO messages VALUES(114,310023,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(115,310023,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(116,310023,'insert','sends','[''asset'', ''block_index'', ''destination'', ''quantity'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(117,310024,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(118,310025,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(119,310026,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(120,310027,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(121,310028,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(122,310029,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(123,310030,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(124,310031,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(125,310032,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(126,310032,'update','orders','[''status'', ''tx_hash'']',0);
INSERT INTO messages VALUES(127,310032,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(128,310032,'insert','order_expirations','[''block_index'', ''order_hash'', ''order_index'', ''source'']',0);
INSERT INTO messages VALUES(129,310033,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(130,310034,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(131,310035,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(132,310036,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(133,310037,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(134,310038,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(135,310039,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(136,310040,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(137,310041,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(138,310042,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(139,310043,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(140,310044,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(141,310045,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(142,310046,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(143,310047,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(144,310048,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(145,310049,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(146,310050,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(147,310051,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(148,310052,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(149,310053,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(150,310054,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(151,310055,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(152,310056,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(153,310057,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(154,310058,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(155,310059,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(156,310060,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(157,310061,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(158,310062,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(159,310063,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(160,310064,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(161,310065,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(162,310066,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(163,310067,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(164,310068,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(165,310069,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(166,310070,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(167,310071,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(168,310072,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(169,310073,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(170,310074,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(171,310075,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(172,310076,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(173,310077,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(174,310078,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(175,310079,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(176,310080,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(177,310081,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(178,310082,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(179,310083,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(180,310084,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(181,310085,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(182,310086,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(183,310087,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(184,310088,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(185,310089,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(186,310090,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(187,310091,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(188,310092,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(189,310093,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(190,310094,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(191,310095,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(192,310096,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(193,310097,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(194,310098,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(195,310099,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(196,310100,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(197,310101,'insert','replace','[''block_index'']',0);
-- Triggers and indices on  messages
CREATE INDEX block_index_message_index_idx ON messages (block_index, message_index);

-- Table  order_expirations
DROP TABLE IF EXISTS order_expirations;
CREATE TABLE order_expirations(
                      order_index INTEGER PRIMARY KEY,
                      order_hash TEXT UNIQUE,
                      source TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index),
                      FOREIGN KEY (order_index, order_hash) REFERENCES orders(tx_index, tx_hash));
INSERT INTO order_expirations VALUES(3,'332b030da57b9565324df01414778b1eafbee6c52343fea80774ee1725484367','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',310013);
INSERT INTO order_expirations VALUES(4,'f093b6c00e1bbe85106db6874b1ab4e3f4378d0bf0bcffbd8b51835285dfbf3f','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',310014);
INSERT INTO order_expirations VALUES(22,'6cb08a1c0547ab0d0d37b74633c1c8a2fd2372d9fd72eb3abdea298f2b245fee','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',310032);
-- Triggers and indices on  order_expirations
CREATE TRIGGER _order_expirations_delete BEFORE DELETE ON order_expirations BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO order_expirations(rowid,order_index,order_hash,source,block_index) VALUES('||old.rowid||','||quote(old.order_index)||','||quote(old.order_hash)||','||quote(old.source)||','||quote(old.block_index)||')');
                            END;
CREATE TRIGGER _order_expirations_insert AFTER INSERT ON order_expirations BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM order_expirations WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _order_expirations_update AFTER UPDATE ON order_expirations BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE order_expirations SET order_index='||quote(old.order_index)||',order_hash='||quote(old.order_hash)||',source='||quote(old.source)||',block_index='||quote(old.block_index)||' WHERE rowid='||old.rowid);
                            END;

-- Table  order_match_expirations
DROP TABLE IF EXISTS order_match_expirations;
CREATE TABLE order_match_expirations(
                      order_match_id TEXT PRIMARY KEY,
                      tx0_address TEXT,
                      tx1_address TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (order_match_id) REFERENCES order_matches(id),
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index));
-- Triggers and indices on  order_match_expirations
CREATE TRIGGER _order_match_expirations_delete BEFORE DELETE ON order_match_expirations BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO order_match_expirations(rowid,order_match_id,tx0_address,tx1_address,block_index) VALUES('||old.rowid||','||quote(old.order_match_id)||','||quote(old.tx0_address)||','||quote(old.tx1_address)||','||quote(old.block_index)||')');
                            END;
CREATE TRIGGER _order_match_expirations_insert AFTER INSERT ON order_match_expirations BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM order_match_expirations WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _order_match_expirations_update AFTER UPDATE ON order_match_expirations BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE order_match_expirations SET order_match_id='||quote(old.order_match_id)||',tx0_address='||quote(old.tx0_address)||',tx1_address='||quote(old.tx1_address)||',block_index='||quote(old.block_index)||' WHERE rowid='||old.rowid);
                            END;

-- Table  order_matches
DROP TABLE IF EXISTS order_matches;
CREATE TABLE order_matches(
                      id TEXT PRIMARY KEY,
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
                      status TEXT,
                      FOREIGN KEY (tx0_index, tx0_hash, tx0_block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                      FOREIGN KEY (tx1_index, tx1_hash, tx1_block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
INSERT INTO order_matches VALUES('332b030da57b9565324df01414778b1eafbee6c52343fea80774ee1725484367_f093b6c00e1bbe85106db6874b1ab4e3f4378d0bf0bcffbd8b51835285dfbf3f',3,'332b030da57b9565324df01414778b1eafbee6c52343fea80774ee1725484367','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',4,'f093b6c00e1bbe85106db6874b1ab4e3f4378d0bf0bcffbd8b51835285dfbf3f','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BTC',50000000,'XCP',100000000,310002,310003,310003,10,10,310023,857142,'completed');
-- Triggers and indices on  order_matches
CREATE TRIGGER _order_matches_delete BEFORE DELETE ON order_matches BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO order_matches(rowid,id,tx0_index,tx0_hash,tx0_address,tx1_index,tx1_hash,tx1_address,forward_asset,forward_quantity,backward_asset,backward_quantity,tx0_block_index,tx1_block_index,block_index,tx0_expiration,tx1_expiration,match_expire_index,fee_paid,status) VALUES('||old.rowid||','||quote(old.id)||','||quote(old.tx0_index)||','||quote(old.tx0_hash)||','||quote(old.tx0_address)||','||quote(old.tx1_index)||','||quote(old.tx1_hash)||','||quote(old.tx1_address)||','||quote(old.forward_asset)||','||quote(old.forward_quantity)||','||quote(old.backward_asset)||','||quote(old.backward_quantity)||','||quote(old.tx0_block_index)||','||quote(old.tx1_block_index)||','||quote(old.block_index)||','||quote(old.tx0_expiration)||','||quote(old.tx1_expiration)||','||quote(old.match_expire_index)||','||quote(old.fee_paid)||','||quote(old.status)||')');
                            END;
CREATE TRIGGER _order_matches_insert AFTER INSERT ON order_matches BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM order_matches WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _order_matches_update AFTER UPDATE ON order_matches BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE order_matches SET id='||quote(old.id)||',tx0_index='||quote(old.tx0_index)||',tx0_hash='||quote(old.tx0_hash)||',tx0_address='||quote(old.tx0_address)||',tx1_index='||quote(old.tx1_index)||',tx1_hash='||quote(old.tx1_hash)||',tx1_address='||quote(old.tx1_address)||',forward_asset='||quote(old.forward_asset)||',forward_quantity='||quote(old.forward_quantity)||',backward_asset='||quote(old.backward_asset)||',backward_quantity='||quote(old.backward_quantity)||',tx0_block_index='||quote(old.tx0_block_index)||',tx1_block_index='||quote(old.tx1_block_index)||',block_index='||quote(old.block_index)||',tx0_expiration='||quote(old.tx0_expiration)||',tx1_expiration='||quote(old.tx1_expiration)||',match_expire_index='||quote(old.match_expire_index)||',fee_paid='||quote(old.fee_paid)||',status='||quote(old.status)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX backward_status_idx ON order_matches (backward_asset, status);
CREATE INDEX forward_status_idx ON order_matches (forward_asset, status);
CREATE INDEX match_expire_idx ON order_matches (status, match_expire_index);
CREATE INDEX tx0_address_idx ON order_matches (tx0_address);
CREATE INDEX tx1_address_idx ON order_matches (tx1_address);

-- Table  orders
DROP TABLE IF EXISTS orders;
CREATE TABLE orders(
                      tx_index INTEGER UNIQUE,
                      tx_hash TEXT UNIQUE,
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
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                      PRIMARY KEY (tx_index, tx_hash));
INSERT INTO orders VALUES(3,'332b030da57b9565324df01414778b1eafbee6c52343fea80774ee1725484367',310002,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BTC',50000000,0,'XCP',100000000,0,10,310012,0,0,1000000,142858,'expired');
INSERT INTO orders VALUES(4,'f093b6c00e1bbe85106db6874b1ab4e3f4378d0bf0bcffbd8b51835285dfbf3f',310003,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',105000000,5000000,'BTC',50000000,0,10,310013,900000,42858,6800,6800,'expired');
INSERT INTO orders VALUES(22,'6cb08a1c0547ab0d0d37b74633c1c8a2fd2372d9fd72eb3abdea298f2b245fee',310021,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB',50000000,50000000,'XCP',50000000,50000000,10,310031,0,0,6800,6800,'expired');
-- Triggers and indices on  orders
CREATE TRIGGER _orders_delete BEFORE DELETE ON orders BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO orders(rowid,tx_index,tx_hash,block_index,source,give_asset,give_quantity,give_remaining,get_asset,get_quantity,get_remaining,expiration,expire_index,fee_required,fee_required_remaining,fee_provided,fee_provided_remaining,status) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.give_asset)||','||quote(old.give_quantity)||','||quote(old.give_remaining)||','||quote(old.get_asset)||','||quote(old.get_quantity)||','||quote(old.get_remaining)||','||quote(old.expiration)||','||quote(old.expire_index)||','||quote(old.fee_required)||','||quote(old.fee_required_remaining)||','||quote(old.fee_provided)||','||quote(old.fee_provided_remaining)||','||quote(old.status)||')');
                            END;
CREATE TRIGGER _orders_insert AFTER INSERT ON orders BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM orders WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _orders_update AFTER UPDATE ON orders BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE orders SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',give_asset='||quote(old.give_asset)||',give_quantity='||quote(old.give_quantity)||',give_remaining='||quote(old.give_remaining)||',get_asset='||quote(old.get_asset)||',get_quantity='||quote(old.get_quantity)||',get_remaining='||quote(old.get_remaining)||',expiration='||quote(old.expiration)||',expire_index='||quote(old.expire_index)||',fee_required='||quote(old.fee_required)||',fee_required_remaining='||quote(old.fee_required_remaining)||',fee_provided='||quote(old.fee_provided)||',fee_provided_remaining='||quote(old.fee_provided_remaining)||',status='||quote(old.status)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX expire_idx ON orders (expire_index, status);
CREATE INDEX give_asset_idx ON orders (give_asset);
CREATE INDEX give_get_status_idx ON orders (get_asset, give_asset, status);
CREATE INDEX give_status_idx ON orders (give_asset, status);
CREATE INDEX source_give_status_idx ON orders (source, give_asset, status);

-- Table  rps
DROP TABLE IF EXISTS rps;
CREATE TABLE rps(
                      tx_index INTEGER UNIQUE,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      possible_moves INTEGER,
                      wager INTEGER,
                      move_random_hash TEXT,
                      expiration INTEGER,
                      expire_index INTEGER,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                      PRIMARY KEY (tx_index, tx_hash));
-- Triggers and indices on  rps
CREATE TRIGGER _rps_delete BEFORE DELETE ON rps BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO rps(rowid,tx_index,tx_hash,block_index,source,possible_moves,wager,move_random_hash,expiration,expire_index,status) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.possible_moves)||','||quote(old.wager)||','||quote(old.move_random_hash)||','||quote(old.expiration)||','||quote(old.expire_index)||','||quote(old.status)||')');
                            END;
CREATE TRIGGER _rps_insert AFTER INSERT ON rps BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM rps WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _rps_update AFTER UPDATE ON rps BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE rps SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',possible_moves='||quote(old.possible_moves)||',wager='||quote(old.wager)||',move_random_hash='||quote(old.move_random_hash)||',expiration='||quote(old.expiration)||',expire_index='||quote(old.expire_index)||',status='||quote(old.status)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX matching_idx ON rps (wager, possible_moves);

-- Table  rps_expirations
DROP TABLE IF EXISTS rps_expirations;
CREATE TABLE rps_expirations(
                      rps_index INTEGER PRIMARY KEY,
                      rps_hash TEXT UNIQUE,
                      source TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index),
                      FOREIGN KEY (rps_index, rps_hash) REFERENCES rps(tx_index, tx_hash));
-- Triggers and indices on  rps_expirations
CREATE TRIGGER _rps_expirations_delete BEFORE DELETE ON rps_expirations BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO rps_expirations(rowid,rps_index,rps_hash,source,block_index) VALUES('||old.rowid||','||quote(old.rps_index)||','||quote(old.rps_hash)||','||quote(old.source)||','||quote(old.block_index)||')');
                            END;
CREATE TRIGGER _rps_expirations_insert AFTER INSERT ON rps_expirations BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM rps_expirations WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _rps_expirations_update AFTER UPDATE ON rps_expirations BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE rps_expirations SET rps_index='||quote(old.rps_index)||',rps_hash='||quote(old.rps_hash)||',source='||quote(old.source)||',block_index='||quote(old.block_index)||' WHERE rowid='||old.rowid);
                            END;

-- Table  rps_match_expirations
DROP TABLE IF EXISTS rps_match_expirations;
CREATE TABLE rps_match_expirations(
                      rps_match_id TEXT PRIMARY KEY,
                      tx0_address TEXT,
                      tx1_address TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (rps_match_id) REFERENCES rps_matches(id),
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index));
-- Triggers and indices on  rps_match_expirations
CREATE TRIGGER _rps_match_expirations_delete BEFORE DELETE ON rps_match_expirations BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO rps_match_expirations(rowid,rps_match_id,tx0_address,tx1_address,block_index) VALUES('||old.rowid||','||quote(old.rps_match_id)||','||quote(old.tx0_address)||','||quote(old.tx1_address)||','||quote(old.block_index)||')');
                            END;
CREATE TRIGGER _rps_match_expirations_insert AFTER INSERT ON rps_match_expirations BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM rps_match_expirations WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _rps_match_expirations_update AFTER UPDATE ON rps_match_expirations BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE rps_match_expirations SET rps_match_id='||quote(old.rps_match_id)||',tx0_address='||quote(old.tx0_address)||',tx1_address='||quote(old.tx1_address)||',block_index='||quote(old.block_index)||' WHERE rowid='||old.rowid);
                            END;

-- Table  rps_matches
DROP TABLE IF EXISTS rps_matches;
CREATE TABLE rps_matches(
                      id TEXT PRIMARY KEY,
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
                      status TEXT,
                      FOREIGN KEY (tx0_index, tx0_hash, tx0_block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                      FOREIGN KEY (tx1_index, tx1_hash, tx1_block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
-- Triggers and indices on  rps_matches
CREATE TRIGGER _rps_matches_delete BEFORE DELETE ON rps_matches BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO rps_matches(rowid,id,tx0_index,tx0_hash,tx0_address,tx1_index,tx1_hash,tx1_address,tx0_move_random_hash,tx1_move_random_hash,wager,possible_moves,tx0_block_index,tx1_block_index,block_index,tx0_expiration,tx1_expiration,match_expire_index,status) VALUES('||old.rowid||','||quote(old.id)||','||quote(old.tx0_index)||','||quote(old.tx0_hash)||','||quote(old.tx0_address)||','||quote(old.tx1_index)||','||quote(old.tx1_hash)||','||quote(old.tx1_address)||','||quote(old.tx0_move_random_hash)||','||quote(old.tx1_move_random_hash)||','||quote(old.wager)||','||quote(old.possible_moves)||','||quote(old.tx0_block_index)||','||quote(old.tx1_block_index)||','||quote(old.block_index)||','||quote(old.tx0_expiration)||','||quote(old.tx1_expiration)||','||quote(old.match_expire_index)||','||quote(old.status)||')');
                            END;
CREATE TRIGGER _rps_matches_insert AFTER INSERT ON rps_matches BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM rps_matches WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _rps_matches_update AFTER UPDATE ON rps_matches BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE rps_matches SET id='||quote(old.id)||',tx0_index='||quote(old.tx0_index)||',tx0_hash='||quote(old.tx0_hash)||',tx0_address='||quote(old.tx0_address)||',tx1_index='||quote(old.tx1_index)||',tx1_hash='||quote(old.tx1_hash)||',tx1_address='||quote(old.tx1_address)||',tx0_move_random_hash='||quote(old.tx0_move_random_hash)||',tx1_move_random_hash='||quote(old.tx1_move_random_hash)||',wager='||quote(old.wager)||',possible_moves='||quote(old.possible_moves)||',tx0_block_index='||quote(old.tx0_block_index)||',tx1_block_index='||quote(old.tx1_block_index)||',block_index='||quote(old.block_index)||',tx0_expiration='||quote(old.tx0_expiration)||',tx1_expiration='||quote(old.tx1_expiration)||',match_expire_index='||quote(old.match_expire_index)||',status='||quote(old.status)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX rps_match_expire_idx ON rps_matches (status, match_expire_index);
CREATE INDEX rps_tx0_address_idx ON rps_matches (tx0_address);
CREATE INDEX rps_tx1_address_idx ON rps_matches (tx1_address);

-- Table  rpsresolves
DROP TABLE IF EXISTS rpsresolves;
CREATE TABLE rpsresolves(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      move INTEGER,
                      random TEXT,
                      rps_match_id TEXT,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
-- Triggers and indices on  rpsresolves
CREATE TRIGGER _rpsresolves_delete BEFORE DELETE ON rpsresolves BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO rpsresolves(rowid,tx_index,tx_hash,block_index,source,move,random,rps_match_id,status) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.move)||','||quote(old.random)||','||quote(old.rps_match_id)||','||quote(old.status)||')');
                            END;
CREATE TRIGGER _rpsresolves_insert AFTER INSERT ON rpsresolves BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM rpsresolves WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _rpsresolves_update AFTER UPDATE ON rpsresolves BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE rpsresolves SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',move='||quote(old.move)||',random='||quote(old.random)||',rps_match_id='||quote(old.rps_match_id)||',status='||quote(old.status)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX rps_match_id_idx ON rpsresolves (rps_match_id);

-- Table  sends
DROP TABLE IF EXISTS sends;
CREATE TABLE "sends"(
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
INSERT INTO sends VALUES(2,'58e839ec2b1584d3474014093393ce57e5c22d6e686213ee4a7a0abe7bbac33c',310001,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',50000000,'valid',0,NULL);
INSERT INTO sends VALUES(8,'f337451a19eac3c2fe66daf7d44d39c41a012d2dfd85de90cc3877bbc2e7d30c',310007,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB',4000000,'valid',0,NULL);
INSERT INTO sends VALUES(9,'c639e9482b31b487115b4437dd87cff98338003fabf18066bf051e1164aa4394',310008,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',526,'valid',0,NULL);
INSERT INTO sends VALUES(24,'c576ecde0f86c86725b540c9f5e6ae57a378fe9694260f7859eca55613d9d341',310023,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',10000,'valid',0,NULL);
-- Triggers and indices on  sends
CREATE TRIGGER _sends_delete BEFORE DELETE ON sends BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO sends(rowid,tx_index,tx_hash,block_index,source,destination,asset,quantity,status,msg_index,memo) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.destination)||','||quote(old.asset)||','||quote(old.quantity)||','||quote(old.status)||','||quote(old.msg_index)||','||quote(old.memo)||')');
                            END;
CREATE TRIGGER _sends_insert AFTER INSERT ON sends BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM sends WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _sends_update AFTER UPDATE ON sends BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE sends SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',destination='||quote(old.destination)||',asset='||quote(old.asset)||',quantity='||quote(old.quantity)||',status='||quote(old.status)||',msg_index='||quote(old.msg_index)||',memo='||quote(old.memo)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX destination_idx ON sends (destination);
CREATE INDEX memo_idx ON sends (memo);
CREATE INDEX source_idx ON sends (source);

-- Table  sweeps
DROP TABLE IF EXISTS sweeps;
CREATE TABLE sweeps(
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
-- Triggers and indices on  sweeps
CREATE TRIGGER _sweeps_delete BEFORE DELETE ON sweeps BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO sweeps(rowid,tx_index,tx_hash,block_index,source,destination,flags,status,memo,fee_paid) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.destination)||','||quote(old.flags)||','||quote(old.status)||','||quote(old.memo)||','||quote(old.fee_paid)||')');
                            END;
CREATE TRIGGER _sweeps_insert AFTER INSERT ON sweeps BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM sweeps WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _sweeps_update AFTER UPDATE ON sweeps BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE sweeps SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',destination='||quote(old.destination)||',flags='||quote(old.flags)||',status='||quote(old.status)||',memo='||quote(old.memo)||',fee_paid='||quote(old.fee_paid)||' WHERE rowid='||old.rowid);
                            END;

-- Table  transaction_outputs
DROP TABLE IF EXISTS transaction_outputs;
CREATE TABLE transaction_outputs(
                        tx_index,
                        tx_hash TEXT, 
                        block_index INTEGER,
                        out_index INTEGER,
                        destination TEXT,
                        btc_amount INTEGER,
                        PRIMARY KEY (tx_hash, out_index),
                        FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));

-- Table  transactions
DROP TABLE IF EXISTS transactions;
CREATE TABLE transactions(
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
INSERT INTO transactions VALUES(1,'9b6b1abb696d8d1b70c5beed046d7cddd23cd95b69ef18946cb18c5b56cfde30',310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
INSERT INTO transactions VALUES(2,'58e839ec2b1584d3474014093393ce57e5c22d6e686213ee4a7a0abe7bbac33c',310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1000,7650,X'0000000000000000000000010000000002FAF080',1);
INSERT INTO transactions VALUES(3,'332b030da57b9565324df01414778b1eafbee6c52343fea80774ee1725484367',310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,1000000,X'0000000A00000000000000000000000002FAF08000000000000000010000000005F5E100000A0000000000000000',1);
INSERT INTO transactions VALUES(4,'f093b6c00e1bbe85106db6874b1ab4e3f4378d0bf0bcffbd8b51835285dfbf3f',310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,6800,X'0000000A00000000000000010000000006422C4000000000000000000000000002FAF080000A00000000000DBBA0',1);
INSERT INTO transactions VALUES(5,'ed17dc38233838e15d319a1786825b9e7cdba815554c9d6f4dd527615bce10b8',310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',50000000,9675,X'0000000B332B030DA57B9565324DF01414778B1EAFBEE6C52343FEA80774EE1725484367F093B6C00E1BBE85106DB6874B1AB4E3F4378D0BF0BCFFBD8B51835285DFBF3F',1);
INSERT INTO transactions VALUES(6,'cd2b44cb56dd5aaae1181c42ab8953ebb9d0fb8e177e960ffe55e3500b3aae25',310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,6800,X'000000140000000000004767000000003B9ACA000100000000000000000000',1);
INSERT INTO transactions VALUES(7,'38ac60a8d36a01a1489572df7e787da96a9af013adc0f4fe2e6098cea44840cf',310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,6800,X'00000014000000000000476800000000000186A00000000000000000000000',1);
INSERT INTO transactions VALUES(8,'f337451a19eac3c2fe66daf7d44d39c41a012d2dfd85de90cc3877bbc2e7d30c',310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1000,7650,X'00000000000000000000476700000000003D0900',1);
INSERT INTO transactions VALUES(9,'c639e9482b31b487115b4437dd87cff98338003fabf18066bf051e1164aa4394',310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1000,7650,X'000000000000000000004768000000000000020E',1);
INSERT INTO transactions VALUES(10,'7881c1fe7881a590d09302dde67cfd888a74154888e0c310bd01575f560b8ac8',310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,6800,X'00000032000000000000025800000000000047670000000000000001',1);
INSERT INTO transactions VALUES(11,'c41898ad625e2236110101070c09e9f28b6fea1ed436ecb78f231f3f99f123f7',310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,6800,X'00000032000000000000032000000000000047680000000000000001',1);
INSERT INTO transactions VALUES(12,'a21533ad03334823cca2aa8e57c383113a7f93a5810c5df8dd2fa70f6eec416d',310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,6800,X'0000001E52BB3300405900000000000005F5E0FF09556E69742054657374',1);
INSERT INTO transactions VALUES(13,'74062934f0a97c41851735fef2a7df4d9ad9945424f09a54281e145a5e32492f',310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1000,7650,X'00000028000052BB33640000000002FAF08000000000017D7840000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(14,'6a5f30666a5f24b6e0e6f31cf06b22ee74d3e692a550297450bdf1d36b1cc167',310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1000,7650,X'00000028000152BB336400000000017D78400000000002793D60000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(15,'2066b9a6b8913412384a0401ef57bfc604e7c5a2c141e23111a8ccc6881b0fb3',310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1000,7650,X'00000028000052BB33640000000008F0D1800000000014DC93800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(16,'65db3ab58b65891a947ab9bdba4723e907678bf3b48397add62802dcc65d1d8e',310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1000,7650,X'00000028000152BB33640000000014DC93800000000008F0D1800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(17,'94b11df6b519372bfbcf0ec5f3e6465a63e323c7cd7cff83a8abd78596d4bce4',310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1000,7650,X'00000028000252BB33C8000000002CB417800000000026BE36803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(18,'a7daff1ca2874f6b18a8f1a1e70db27f58c6b39a9f106c353223fbccde57098e',310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1000,7650,X'00000028000352BB33C80000000026BE3680000000002CB417803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(19,'f020ae6c0b1aadbba4893581678ef87f9d2a925be5e6b08d02440e213f6183b4',310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,6800,X'0000001E52BB33324058F7256FFC115E004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(20,'dccbd8852c8d489d32f87be0c86a631b63ec50202b0109a2be6aa96f27f89600',310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,6800,X'0000001E52BB3365405915F3B645A1CB004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(21,'457f36dccce6664a8e28b00ebf47aa60ba4a41b46642aceef0e2a297429eb64e',310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,6800,X'0000001E52BB33C94000000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(22,'6cb08a1c0547ab0d0d37b74633c1c8a2fd2372d9fd72eb3abdea298f2b245fee',310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,6800,X'0000000A00000000000047670000000002FAF08000000000000000010000000002FAF080000A0000000000000000',1);
INSERT INTO transactions VALUES(23,'c81cd36f1efabd22f1a00923714fd5a5f1ba07852ef1f0763223563e3f55dfda',310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','mvCounterpartyXXXXXXXXXXXXXXW24Hef',100000000,14675,X'',1);
INSERT INTO transactions VALUES(24,'c576ecde0f86c86725b540c9f5e6ae57a378fe9694260f7859eca55613d9d341',310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1000,7650,X'0000000000000000000047680000000000002710',1);
-- Triggers and indices on  transactions
CREATE INDEX index_hash_index_idx ON transactions (tx_index, tx_hash, block_index);
CREATE INDEX index_index_idx ON transactions (block_index, tx_index);
CREATE INDEX tx_hash_idx ON transactions (tx_hash);
CREATE INDEX tx_index_idx ON transactions (tx_index);

-- Table  undolog
DROP TABLE IF EXISTS undolog;
CREATE TABLE undolog(
                        undo_index INTEGER PRIMARY KEY AUTOINCREMENT,
                        sql TEXT);
INSERT INTO undolog VALUES(4,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=93000000000 WHERE rowid=1');
INSERT INTO undolog VALUES(5,'DELETE FROM debits WHERE rowid=1');
INSERT INTO undolog VALUES(6,'DELETE FROM balances WHERE rowid=2');
INSERT INTO undolog VALUES(7,'DELETE FROM credits WHERE rowid=2');
INSERT INTO undolog VALUES(8,'DELETE FROM sends WHERE rowid=1');
INSERT INTO undolog VALUES(9,'DELETE FROM orders WHERE rowid=1');
INSERT INTO undolog VALUES(10,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92950000000 WHERE rowid=1');
INSERT INTO undolog VALUES(11,'DELETE FROM debits WHERE rowid=2');
INSERT INTO undolog VALUES(12,'DELETE FROM orders WHERE rowid=2');
INSERT INTO undolog VALUES(13,'UPDATE orders SET tx_index=3,tx_hash=''332b030da57b9565324df01414778b1eafbee6c52343fea80774ee1725484367'',block_index=310002,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',give_asset=''BTC'',give_quantity=50000000,give_remaining=50000000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=10,expire_index=310012,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(14,'UPDATE orders SET tx_index=4,tx_hash=''f093b6c00e1bbe85106db6874b1ab4e3f4378d0bf0bcffbd8b51835285dfbf3f'',block_index=310003,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',give_asset=''XCP'',give_quantity=105000000,give_remaining=105000000,get_asset=''BTC'',get_quantity=50000000,get_remaining=50000000,expiration=10,expire_index=310013,fee_required=900000,fee_required_remaining=900000,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(15,'DELETE FROM order_matches WHERE rowid=1');
INSERT INTO undolog VALUES(16,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92845000000 WHERE rowid=1');
INSERT INTO undolog VALUES(17,'DELETE FROM credits WHERE rowid=3');
INSERT INTO undolog VALUES(18,'UPDATE order_matches SET id=''332b030da57b9565324df01414778b1eafbee6c52343fea80774ee1725484367_f093b6c00e1bbe85106db6874b1ab4e3f4378d0bf0bcffbd8b51835285dfbf3f'',tx0_index=3,tx0_hash=''332b030da57b9565324df01414778b1eafbee6c52343fea80774ee1725484367'',tx0_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',tx1_index=4,tx1_hash=''f093b6c00e1bbe85106db6874b1ab4e3f4378d0bf0bcffbd8b51835285dfbf3f'',tx1_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',forward_asset=''BTC'',forward_quantity=50000000,backward_asset=''XCP'',backward_quantity=100000000,tx0_block_index=310002,tx1_block_index=310003,block_index=310003,tx0_expiration=10,tx1_expiration=10,match_expire_index=310023,fee_paid=857142,status=''pending'' WHERE rowid=1');
INSERT INTO undolog VALUES(19,'DELETE FROM btcpays WHERE rowid=5');
INSERT INTO undolog VALUES(20,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92945000000 WHERE rowid=1');
INSERT INTO undolog VALUES(21,'DELETE FROM debits WHERE rowid=3');
INSERT INTO undolog VALUES(22,'DELETE FROM assets WHERE rowid=3');
INSERT INTO undolog VALUES(23,'DELETE FROM issuances WHERE rowid=1');
INSERT INTO undolog VALUES(24,'DELETE FROM balances WHERE rowid=3');
INSERT INTO undolog VALUES(25,'DELETE FROM credits WHERE rowid=4');
INSERT INTO undolog VALUES(26,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92895000000 WHERE rowid=1');
INSERT INTO undolog VALUES(27,'DELETE FROM debits WHERE rowid=4');
INSERT INTO undolog VALUES(28,'DELETE FROM assets WHERE rowid=4');
INSERT INTO undolog VALUES(29,'DELETE FROM issuances WHERE rowid=2');
INSERT INTO undolog VALUES(30,'DELETE FROM balances WHERE rowid=4');
INSERT INTO undolog VALUES(31,'DELETE FROM credits WHERE rowid=5');
INSERT INTO undolog VALUES(32,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''BBBB'',quantity=1000000000 WHERE rowid=3');
INSERT INTO undolog VALUES(33,'DELETE FROM debits WHERE rowid=5');
INSERT INTO undolog VALUES(34,'DELETE FROM balances WHERE rowid=5');
INSERT INTO undolog VALUES(35,'DELETE FROM credits WHERE rowid=6');
INSERT INTO undolog VALUES(36,'DELETE FROM sends WHERE rowid=2');
INSERT INTO undolog VALUES(37,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''BBBC'',quantity=100000 WHERE rowid=4');
INSERT INTO undolog VALUES(38,'DELETE FROM debits WHERE rowid=6');
INSERT INTO undolog VALUES(39,'DELETE FROM balances WHERE rowid=6');
INSERT INTO undolog VALUES(40,'DELETE FROM credits WHERE rowid=7');
INSERT INTO undolog VALUES(41,'DELETE FROM sends WHERE rowid=3');
INSERT INTO undolog VALUES(42,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92845000000 WHERE rowid=1');
INSERT INTO undolog VALUES(43,'DELETE FROM debits WHERE rowid=7');
INSERT INTO undolog VALUES(44,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92844999976 WHERE rowid=1');
INSERT INTO undolog VALUES(45,'DELETE FROM debits WHERE rowid=8');
INSERT INTO undolog VALUES(46,'UPDATE balances SET address=''1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=50000000 WHERE rowid=2');
INSERT INTO undolog VALUES(47,'DELETE FROM credits WHERE rowid=8');
INSERT INTO undolog VALUES(48,'DELETE FROM dividends WHERE rowid=10');
INSERT INTO undolog VALUES(49,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92844979976 WHERE rowid=1');
INSERT INTO undolog VALUES(50,'DELETE FROM debits WHERE rowid=9');
INSERT INTO undolog VALUES(51,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92844559176 WHERE rowid=1');
INSERT INTO undolog VALUES(52,'DELETE FROM debits WHERE rowid=10');
INSERT INTO undolog VALUES(53,'UPDATE balances SET address=''1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=50000024 WHERE rowid=2');
INSERT INTO undolog VALUES(54,'DELETE FROM credits WHERE rowid=9');
INSERT INTO undolog VALUES(55,'DELETE FROM dividends WHERE rowid=11');
INSERT INTO undolog VALUES(56,'DELETE FROM broadcasts WHERE rowid=12');
INSERT INTO undolog VALUES(57,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92844539176 WHERE rowid=1');
INSERT INTO undolog VALUES(58,'DELETE FROM debits WHERE rowid=11');
INSERT INTO undolog VALUES(59,'DELETE FROM bets WHERE rowid=1');
INSERT INTO undolog VALUES(60,'UPDATE orders SET tx_index=3,tx_hash=''332b030da57b9565324df01414778b1eafbee6c52343fea80774ee1725484367'',block_index=310002,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',give_asset=''BTC'',give_quantity=50000000,give_remaining=0,get_asset=''XCP'',get_quantity=100000000,get_remaining=0,expiration=10,expire_index=310012,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=142858,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(61,'DELETE FROM order_expirations WHERE rowid=3');
INSERT INTO undolog VALUES(62,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92794539176 WHERE rowid=1');
INSERT INTO undolog VALUES(63,'DELETE FROM debits WHERE rowid=12');
INSERT INTO undolog VALUES(64,'DELETE FROM bets WHERE rowid=2');
INSERT INTO undolog VALUES(65,'UPDATE bets SET tx_index=13,tx_hash=''74062934f0a97c41851735fef2a7df4d9ad9945424f09a54281e145a5e32492f'',block_index=310012,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',bet_type=0,deadline=1388000100,wager_quantity=50000000,wager_remaining=50000000,counterwager_quantity=25000000,counterwager_remaining=25000000,target_value=0.0,leverage=15120,expiration=10,expire_index=310022,fee_fraction_int=99999999,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(66,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92769539176 WHERE rowid=1');
INSERT INTO undolog VALUES(67,'DELETE FROM credits WHERE rowid=10');
INSERT INTO undolog VALUES(68,'UPDATE bets SET tx_index=14,tx_hash=''6a5f30666a5f24b6e0e6f31cf06b22ee74d3e692a550297450bdf1d36b1cc167'',block_index=310013,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',bet_type=1,deadline=1388000100,wager_quantity=25000000,wager_remaining=25000000,counterwager_quantity=41500000,counterwager_remaining=41500000,target_value=0.0,leverage=15120,expiration=10,expire_index=310023,fee_fraction_int=99999999,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(69,'DELETE FROM bet_matches WHERE rowid=1');
INSERT INTO undolog VALUES(70,'UPDATE orders SET tx_index=4,tx_hash=''f093b6c00e1bbe85106db6874b1ab4e3f4378d0bf0bcffbd8b51835285dfbf3f'',block_index=310003,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',give_asset=''XCP'',give_quantity=105000000,give_remaining=5000000,get_asset=''BTC'',get_quantity=50000000,get_remaining=0,expiration=10,expire_index=310013,fee_required=900000,fee_required_remaining=42858,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(71,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92773789176 WHERE rowid=1');
INSERT INTO undolog VALUES(72,'DELETE FROM credits WHERE rowid=11');
INSERT INTO undolog VALUES(73,'DELETE FROM order_expirations WHERE rowid=4');
INSERT INTO undolog VALUES(74,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92778789176 WHERE rowid=1');
INSERT INTO undolog VALUES(75,'DELETE FROM debits WHERE rowid=13');
INSERT INTO undolog VALUES(76,'DELETE FROM bets WHERE rowid=3');
INSERT INTO undolog VALUES(77,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92628789176 WHERE rowid=1');
INSERT INTO undolog VALUES(78,'DELETE FROM debits WHERE rowid=14');
INSERT INTO undolog VALUES(79,'DELETE FROM bets WHERE rowid=4');
INSERT INTO undolog VALUES(80,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(81,'DELETE FROM credits WHERE rowid=12');
INSERT INTO undolog VALUES(82,'UPDATE bets SET tx_index=15,tx_hash=''2066b9a6b8913412384a0401ef57bfc604e7c5a2c141e23111a8ccc6881b0fb3'',block_index=310014,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',bet_type=0,deadline=1388000100,wager_quantity=150000000,wager_remaining=150000000,counterwager_quantity=350000000,counterwager_remaining=350000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310024,fee_fraction_int=99999999,status=''open'' WHERE rowid=3');
INSERT INTO undolog VALUES(83,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(84,'DELETE FROM credits WHERE rowid=13');
INSERT INTO undolog VALUES(85,'UPDATE bets SET tx_index=16,tx_hash=''65db3ab58b65891a947ab9bdba4723e907678bf3b48397add62802dcc65d1d8e'',block_index=310015,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',bet_type=1,deadline=1388000100,wager_quantity=350000000,wager_remaining=350000000,counterwager_quantity=150000000,counterwager_remaining=150000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310025,fee_fraction_int=99999999,status=''open'' WHERE rowid=4');
INSERT INTO undolog VALUES(86,'DELETE FROM bet_matches WHERE rowid=2');
INSERT INTO undolog VALUES(87,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(88,'DELETE FROM debits WHERE rowid=15');
INSERT INTO undolog VALUES(89,'DELETE FROM bets WHERE rowid=5');
INSERT INTO undolog VALUES(90,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=91528789176 WHERE rowid=1');
INSERT INTO undolog VALUES(91,'DELETE FROM debits WHERE rowid=16');
INSERT INTO undolog VALUES(92,'DELETE FROM bets WHERE rowid=6');
INSERT INTO undolog VALUES(93,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(94,'DELETE FROM credits WHERE rowid=14');
INSERT INTO undolog VALUES(95,'UPDATE bets SET tx_index=17,tx_hash=''94b11df6b519372bfbcf0ec5f3e6465a63e323c7cd7cff83a8abd78596d4bce4'',block_index=310016,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',bet_type=2,deadline=1388000200,wager_quantity=750000000,wager_remaining=750000000,counterwager_quantity=650000000,counterwager_remaining=650000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310026,fee_fraction_int=99999999,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(96,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(97,'DELETE FROM credits WHERE rowid=15');
INSERT INTO undolog VALUES(98,'UPDATE bets SET tx_index=18,tx_hash=''a7daff1ca2874f6b18a8f1a1e70db27f58c6b39a9f106c353223fbccde57098e'',block_index=310017,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',bet_type=3,deadline=1388000200,wager_quantity=650000000,wager_remaining=650000000,counterwager_quantity=750000000,counterwager_remaining=750000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310027,fee_fraction_int=99999999,status=''open'' WHERE rowid=6');
INSERT INTO undolog VALUES(99,'DELETE FROM bet_matches WHERE rowid=3');
INSERT INTO undolog VALUES(100,'DELETE FROM broadcasts WHERE rowid=19');
INSERT INTO undolog VALUES(101,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(102,'DELETE FROM credits WHERE rowid=16');
INSERT INTO undolog VALUES(103,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=90937926676 WHERE rowid=1');
INSERT INTO undolog VALUES(104,'DELETE FROM credits WHERE rowid=17');
INSERT INTO undolog VALUES(105,'DELETE FROM bet_match_resolutions WHERE rowid=1');
INSERT INTO undolog VALUES(106,'UPDATE bet_matches SET id=''74062934f0a97c41851735fef2a7df4d9ad9945424f09a54281e145a5e32492f_6a5f30666a5f24b6e0e6f31cf06b22ee74d3e692a550297450bdf1d36b1cc167'',tx0_index=13,tx0_hash=''74062934f0a97c41851735fef2a7df4d9ad9945424f09a54281e145a5e32492f'',tx0_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',tx1_index=14,tx1_hash=''6a5f30666a5f24b6e0e6f31cf06b22ee74d3e692a550297450bdf1d36b1cc167'',tx1_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=15120,forward_quantity=41500000,backward_quantity=20750000,tx0_block_index=310012,tx1_block_index=310013,block_index=310013,tx0_expiration=10,tx1_expiration=10,match_expire_index=310022,fee_fraction_int=99999999,status=''pending'' WHERE rowid=1');
INSERT INTO undolog VALUES(107,'DELETE FROM broadcasts WHERE rowid=20');
INSERT INTO undolog VALUES(108,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=90941039176 WHERE rowid=1');
INSERT INTO undolog VALUES(109,'DELETE FROM credits WHERE rowid=18');
INSERT INTO undolog VALUES(110,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=91100339176 WHERE rowid=1');
INSERT INTO undolog VALUES(111,'DELETE FROM credits WHERE rowid=19');
INSERT INTO undolog VALUES(112,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=91416039176 WHERE rowid=1');
INSERT INTO undolog VALUES(113,'DELETE FROM credits WHERE rowid=20');
INSERT INTO undolog VALUES(114,'DELETE FROM bet_match_resolutions WHERE rowid=2');
INSERT INTO undolog VALUES(115,'UPDATE bet_matches SET id=''2066b9a6b8913412384a0401ef57bfc604e7c5a2c141e23111a8ccc6881b0fb3_65db3ab58b65891a947ab9bdba4723e907678bf3b48397add62802dcc65d1d8e'',tx0_index=15,tx0_hash=''2066b9a6b8913412384a0401ef57bfc604e7c5a2c141e23111a8ccc6881b0fb3'',tx0_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',tx1_index=16,tx1_hash=''65db3ab58b65891a947ab9bdba4723e907678bf3b48397add62802dcc65d1d8e'',tx1_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=5040,forward_quantity=150000000,backward_quantity=350000000,tx0_block_index=310014,tx1_block_index=310015,block_index=310015,tx0_expiration=10,tx1_expiration=10,match_expire_index=310024,fee_fraction_int=99999999,status=''pending'' WHERE rowid=2');
INSERT INTO undolog VALUES(116,'DELETE FROM broadcasts WHERE rowid=21');
INSERT INTO undolog VALUES(117,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=91441039176 WHERE rowid=1');
INSERT INTO undolog VALUES(118,'DELETE FROM credits WHERE rowid=21');
INSERT INTO undolog VALUES(119,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92771039176 WHERE rowid=1');
INSERT INTO undolog VALUES(120,'DELETE FROM credits WHERE rowid=22');
INSERT INTO undolog VALUES(121,'DELETE FROM bet_match_resolutions WHERE rowid=3');
INSERT INTO undolog VALUES(122,'UPDATE bet_matches SET id=''94b11df6b519372bfbcf0ec5f3e6465a63e323c7cd7cff83a8abd78596d4bce4_a7daff1ca2874f6b18a8f1a1e70db27f58c6b39a9f106c353223fbccde57098e'',tx0_index=17,tx0_hash=''94b11df6b519372bfbcf0ec5f3e6465a63e323c7cd7cff83a8abd78596d4bce4'',tx0_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',tx1_index=18,tx1_hash=''a7daff1ca2874f6b18a8f1a1e70db27f58c6b39a9f106c353223fbccde57098e'',tx1_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',tx0_bet_type=2,tx1_bet_type=3,feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',initial_value=100,deadline=1388000200,target_value=1.0,leverage=5040,forward_quantity=750000000,backward_quantity=650000000,tx0_block_index=310016,tx1_block_index=310017,block_index=310017,tx0_expiration=10,tx1_expiration=10,match_expire_index=310026,fee_fraction_int=99999999,status=''pending'' WHERE rowid=3');
INSERT INTO undolog VALUES(123,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''BBBB'',quantity=996000000 WHERE rowid=3');
INSERT INTO undolog VALUES(124,'DELETE FROM debits WHERE rowid=17');
INSERT INTO undolog VALUES(125,'DELETE FROM orders WHERE rowid=3');
INSERT INTO undolog VALUES(126,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92841039176 WHERE rowid=1');
INSERT INTO undolog VALUES(127,'DELETE FROM credits WHERE rowid=23');
INSERT INTO undolog VALUES(128,'DELETE FROM burns WHERE rowid=23');
INSERT INTO undolog VALUES(129,'UPDATE bets SET tx_index=13,tx_hash=''74062934f0a97c41851735fef2a7df4d9ad9945424f09a54281e145a5e32492f'',block_index=310012,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',bet_type=0,deadline=1388000100,wager_quantity=50000000,wager_remaining=8500000,counterwager_quantity=25000000,counterwager_remaining=4250000,target_value=0.0,leverage=15120,expiration=10,expire_index=310022,fee_fraction_int=99999999,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(130,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=149840926438 WHERE rowid=1');
INSERT INTO undolog VALUES(131,'DELETE FROM credits WHERE rowid=24');
INSERT INTO undolog VALUES(132,'DELETE FROM bet_expirations WHERE rowid=13');
INSERT INTO undolog VALUES(133,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''BBBC'',quantity=99474 WHERE rowid=4');
INSERT INTO undolog VALUES(134,'DELETE FROM debits WHERE rowid=18');
INSERT INTO undolog VALUES(135,'UPDATE balances SET address=''1_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''BBBC'',quantity=526 WHERE rowid=6');
INSERT INTO undolog VALUES(136,'DELETE FROM credits WHERE rowid=25');
INSERT INTO undolog VALUES(137,'DELETE FROM sends WHERE rowid=4');
INSERT INTO undolog VALUES(138,'UPDATE orders SET tx_index=22,tx_hash=''6cb08a1c0547ab0d0d37b74633c1c8a2fd2372d9fd72eb3abdea298f2b245fee'',block_index=310021,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',give_asset=''BBBB'',give_quantity=50000000,give_remaining=50000000,get_asset=''XCP'',get_quantity=50000000,get_remaining=50000000,expiration=10,expire_index=310031,fee_required=0,fee_required_remaining=0,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=3');
INSERT INTO undolog VALUES(139,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''BBBB'',quantity=946000000 WHERE rowid=3');
INSERT INTO undolog VALUES(140,'DELETE FROM credits WHERE rowid=26');
INSERT INTO undolog VALUES(141,'DELETE FROM order_expirations WHERE rowid=22');

-- Table  undolog_block
DROP TABLE IF EXISTS undolog_block;
CREATE TABLE undolog_block(
                        block_index INTEGER PRIMARY KEY,
                        first_undo_index INTEGER);
INSERT INTO undolog_block VALUES(310001,4);
INSERT INTO undolog_block VALUES(310002,9);
INSERT INTO undolog_block VALUES(310003,10);
INSERT INTO undolog_block VALUES(310004,16);
INSERT INTO undolog_block VALUES(310005,20);
INSERT INTO undolog_block VALUES(310006,26);
INSERT INTO undolog_block VALUES(310007,32);
INSERT INTO undolog_block VALUES(310008,37);
INSERT INTO undolog_block VALUES(310009,42);
INSERT INTO undolog_block VALUES(310010,49);
INSERT INTO undolog_block VALUES(310011,56);
INSERT INTO undolog_block VALUES(310012,57);
INSERT INTO undolog_block VALUES(310013,60);
INSERT INTO undolog_block VALUES(310014,70);
INSERT INTO undolog_block VALUES(310015,77);
INSERT INTO undolog_block VALUES(310016,87);
INSERT INTO undolog_block VALUES(310017,90);
INSERT INTO undolog_block VALUES(310018,100);
INSERT INTO undolog_block VALUES(310019,107);
INSERT INTO undolog_block VALUES(310020,116);
INSERT INTO undolog_block VALUES(310021,123);
INSERT INTO undolog_block VALUES(310022,126);
INSERT INTO undolog_block VALUES(310023,129);
INSERT INTO undolog_block VALUES(310024,138);
INSERT INTO undolog_block VALUES(310025,138);
INSERT INTO undolog_block VALUES(310026,138);
INSERT INTO undolog_block VALUES(310027,138);
INSERT INTO undolog_block VALUES(310028,138);
INSERT INTO undolog_block VALUES(310029,138);
INSERT INTO undolog_block VALUES(310030,138);
INSERT INTO undolog_block VALUES(310031,138);
INSERT INTO undolog_block VALUES(310032,138);
INSERT INTO undolog_block VALUES(310033,142);
INSERT INTO undolog_block VALUES(310034,142);
INSERT INTO undolog_block VALUES(310035,142);
INSERT INTO undolog_block VALUES(310036,142);
INSERT INTO undolog_block VALUES(310037,142);
INSERT INTO undolog_block VALUES(310038,142);
INSERT INTO undolog_block VALUES(310039,142);
INSERT INTO undolog_block VALUES(310040,142);
INSERT INTO undolog_block VALUES(310041,142);
INSERT INTO undolog_block VALUES(310042,142);
INSERT INTO undolog_block VALUES(310043,142);
INSERT INTO undolog_block VALUES(310044,142);
INSERT INTO undolog_block VALUES(310045,142);
INSERT INTO undolog_block VALUES(310046,142);
INSERT INTO undolog_block VALUES(310047,142);
INSERT INTO undolog_block VALUES(310048,142);
INSERT INTO undolog_block VALUES(310049,142);
INSERT INTO undolog_block VALUES(310050,142);
INSERT INTO undolog_block VALUES(310051,142);
INSERT INTO undolog_block VALUES(310052,142);
INSERT INTO undolog_block VALUES(310053,142);
INSERT INTO undolog_block VALUES(310054,142);
INSERT INTO undolog_block VALUES(310055,142);
INSERT INTO undolog_block VALUES(310056,142);
INSERT INTO undolog_block VALUES(310057,142);
INSERT INTO undolog_block VALUES(310058,142);
INSERT INTO undolog_block VALUES(310059,142);
INSERT INTO undolog_block VALUES(310060,142);
INSERT INTO undolog_block VALUES(310061,142);
INSERT INTO undolog_block VALUES(310062,142);
INSERT INTO undolog_block VALUES(310063,142);
INSERT INTO undolog_block VALUES(310064,142);
INSERT INTO undolog_block VALUES(310065,142);
INSERT INTO undolog_block VALUES(310066,142);
INSERT INTO undolog_block VALUES(310067,142);
INSERT INTO undolog_block VALUES(310068,142);
INSERT INTO undolog_block VALUES(310069,142);
INSERT INTO undolog_block VALUES(310070,142);
INSERT INTO undolog_block VALUES(310071,142);
INSERT INTO undolog_block VALUES(310072,142);
INSERT INTO undolog_block VALUES(310073,142);
INSERT INTO undolog_block VALUES(310074,142);
INSERT INTO undolog_block VALUES(310075,142);
INSERT INTO undolog_block VALUES(310076,142);
INSERT INTO undolog_block VALUES(310077,142);
INSERT INTO undolog_block VALUES(310078,142);
INSERT INTO undolog_block VALUES(310079,142);
INSERT INTO undolog_block VALUES(310080,142);
INSERT INTO undolog_block VALUES(310081,142);
INSERT INTO undolog_block VALUES(310082,142);
INSERT INTO undolog_block VALUES(310083,142);
INSERT INTO undolog_block VALUES(310084,142);
INSERT INTO undolog_block VALUES(310085,142);
INSERT INTO undolog_block VALUES(310086,142);
INSERT INTO undolog_block VALUES(310087,142);
INSERT INTO undolog_block VALUES(310088,142);
INSERT INTO undolog_block VALUES(310089,142);
INSERT INTO undolog_block VALUES(310090,142);
INSERT INTO undolog_block VALUES(310091,142);
INSERT INTO undolog_block VALUES(310092,142);
INSERT INTO undolog_block VALUES(310093,142);
INSERT INTO undolog_block VALUES(310094,142);
INSERT INTO undolog_block VALUES(310095,142);
INSERT INTO undolog_block VALUES(310096,142);
INSERT INTO undolog_block VALUES(310097,142);
INSERT INTO undolog_block VALUES(310098,142);
INSERT INTO undolog_block VALUES(310099,142);
INSERT INTO undolog_block VALUES(310100,142);
INSERT INTO undolog_block VALUES(310101,142);

-- For primary key autoincrements the next id to use is stored in
-- sqlite_sequence
DELETE FROM main.sqlite_sequence WHERE name='undolog';
INSERT INTO main.sqlite_sequence VALUES ('undolog', 141);

COMMIT TRANSACTION;
