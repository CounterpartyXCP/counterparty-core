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
INSERT INTO blocks VALUES(310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,NULL,NULL,'a1f2aa5a0b8d030c2fc4e1243c3173319ecf68d232262ea3dc8bfdd03a3f923a','afa257be6b0f57581b8f1b932b3c8473ff5c89e4bd6c3d3e3dd6a8c3cd9b09d3','343130b4bb08ac7410a7f49b7fc597d5447930565405b93a3ab709b61fc9ef9d');
INSERT INTO blocks VALUES(310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,NULL,NULL,'8709aa2d5064ea2b7ab51a887d21f5fddcb7046753cd883317b533ed121f8504','40941bb90c086bd2716de8afc1fba5eb75721143a86a606ef99ee3312de95614','290fb16c1216ea97acd63fe8fcbc33fe7f96fe7d99ded4f0e0e95d0d52b25d56');
INSERT INTO blocks VALUES(310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,NULL,NULL,'c1c516176fe38b69b31e3668b5ef20805bd90d3112c77f5652f838af8e7f604a','9b186632fe722ba57daaa01573568c3d3405f7fcb0a729005a6338266a4debfa','d237db48000ec3c79f614fe4cae01c369c00eceff19da02c127ec425625e7191');
INSERT INTO blocks VALUES(310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,NULL,NULL,'ae8ee9e681f0ac96de96babc1c80e5188b3e0cb91074a0dfd8511ee7d0ae64c8','39f4f154cbeae9a65b43ac831b2d5ad0e6f6575b909b979bd4bd97dadbab4cdd','effa586e9beecef76196a346d81e43d66a618e5aa516d80234ab05d3516ce8db');
INSERT INTO blocks VALUES(310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,NULL,NULL,'0451ffa5d7ffb0e588e58ac7eacf77f6b3e17f1d27c1039f03d7716b16fb234f','0cea2e2e06c6423d1c5ba19f6128fbe8fe6d6c3688316c9c35dd31cf03d38c97','fd09be09f14fd1ab5805b4575a78ad9882ced68015f8c4f92559572cdb887816');
INSERT INTO blocks VALUES(310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,NULL,NULL,'dfaae3f28c2f75e4bcc49034ff2a191b5a41b88035c5d266181617c8c65ad5d3','0134329cfdaf63e5946b9b5a94b73f59b9a870d4569ca07c0cce078bf13714a5','47c297afd3fbda7a965b7cb3ce3a6cd522f9d2fb252fb5310b9565e6a7c23f99');
INSERT INTO blocks VALUES(310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,NULL,NULL,'c711e8cf2d9bbed01724a7b22cbd4900a4fd0a126bb7ecbd7c97ca15a6276553','9a3fb4fb846c9ffff3a50a0a31f3ac3900ba7048a60dd69c6e14752734358f1c','55eb19b8344aa4d2e2f5ba1b9580c7ae1a69f25ecfbdb0f3e5295003b07124ed');
INSERT INTO blocks VALUES(310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,NULL,NULL,'3dfa5822de8a4c674f1517b17e50d2ef63ccbb1fc4ae96fe5e1dc05cd353aa4b','6228a449b24d607b8fe1aea60a0292874cfe515a9440bee2829f6e61efa0b2a6','4ee9449c834b22405f57cc29e62a7a84f8177ab4e98a726d2608538c3a3f6ab7');
INSERT INTO blocks VALUES(310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,NULL,NULL,'49fcaed957776bc62c9f1feac30dad8c0574596d312f9efee7a453e00bf64866','700cf4c54e23c0cfb4d8b02bc6cb1ca509637dd95312629625aa92d32d5548d2','00e58393a424f61e93cfd14a86a015760af3da9d8dc70285c97d12f8e6546847');
INSERT INTO blocks VALUES(310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,NULL,NULL,'4e4abd3e8ab2658a7ac673e3a178ceac76fee41cf48bb6ed007d241c079979bf','288c9c0f37cb0c2e9db66d4b88b165391a67f06016ac84c485e9b9158ee51f2d','852b755cd06bf0c05797a6ead12e040a92ff64ff95a8361ec81ecec56a9128d4');
INSERT INTO blocks VALUES(310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,NULL,NULL,'17a28cca0777254af26544edfefcad8810e847e5d173fded9a7813719cf1162f','1bf7e0a4aa8356584087591a8c8e8b28185a6ebfe1a15a85f01165a04ff57913','692e1e781920dbfc12b5fb72c5acc6fdd7cb42a9216dd6365d769da9813a7690');
INSERT INTO blocks VALUES(310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,NULL,NULL,'1fb58120e9eb78908fda6265cad12b4a5770701e9a271bd5c4bc94059bd3bab5','62678a570c40b5a12469e442b3a54f1416d9113de2db501f37ed533f345e71c1','bd688371536fb13aefd9e5146c23784fece59b655fae3cfbd27f3d51fa29b7ab');
INSERT INTO blocks VALUES(310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,NULL,NULL,'304243c1b11644e04d325d7100e4c757c07b874f0349e60163a5a544e84e951f','a174e4813aa967f5466148f27f4f8511ed9404295bf613e112c08b72eb3229ad','0cec07770b90eb47f9cad6dac2812caee8c26804e1943d3de126ee0446465ef1');
INSERT INTO blocks VALUES(310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,NULL,NULL,'fc9905ee4863b3cf29a3e558ee690a24ed978a4fd79c464bdde30a34cfff19fe','c551c2094651cd0e06e0cd9d513fec771b69f4bb89c3034f201c89f703cf8a23','7479f59d633a6843dcab3f7c7552673841e0d288999be3461911cc927fc77d7c');
INSERT INTO blocks VALUES(310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,NULL,NULL,'e433feac4a09ad727bd3764b10a568acf5c659745a695e9d7e8790514f6bc98e','087d41720991e4b6bb72c6141334a65c9a289454dd8fd57edc33a09db467d086','61ab49e905ea5c5cd4c8092b911c26f96970e87e207cf79d5ea220e2bb0fd7fc');
INSERT INTO blocks VALUES(310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,NULL,NULL,'622f92da40eae0b1b57218b32ad18daf7d79c9e0202fed4a288d75b8fdcd19d2','caa77e83354d56437795411f9625dff332c0dd39d059a0ad7381fe1f37e38999','9bec58123c4b3dc119548dfc046a6f9575734c5a340c652249520661073bd055');
INSERT INTO blocks VALUES(310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,NULL,NULL,'b7aa8d9ebc37d52d8dcce2cc17431d6edf5a183b73ac85bb3d91276592215cfd','df23960a57099b0b64572553e56794b1eff3004e684ee2b31187b585aeb03587','737f968dcfd2ad3fb783d30e09a6d123298f6dc6d90de47413a8da6ab02fa507');
INSERT INTO blocks VALUES(310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,NULL,NULL,'501c058860063ca599f3b946d465b3bbd84fd483a2a80527e456e3de32b48a19','c680a6d4f839ba4f9420a99f0512e51fc1db0b661ed027332f440c6089eb615a','058b99c7da903a3286e9c0c9f57fe9e8fc7c7de9fed0501dac48bfeabdfe27c8');
INSERT INTO blocks VALUES(310024,'b03042b4e18a222b4c8d1e9e1970d93e6e2a2d41686d227ff8ecf0a839223dc5',310024000,NULL,NULL,'222986ec44fae1a6196d64dec24b79872970823f17bf0459d3b247bdef316675','f40aab7ef7167a17e35279423d9c14d49a9ebc05691fa658b09add1373216959','9e212fbbe705ae6446f1e9f0397cf4fa28732925227e0376172ffa3a7eb82d50');
INSERT INTO blocks VALUES(310025,'a872e560766832cc3b4f7f222228cb6db882ce3c54f6459f62c71d5cd6e90666',310025000,NULL,NULL,'bcd88006b9cb98445a74c656d424435e82eeaef95dd9c54e394b42808dc9cb8b','0e3736813d3c0e789cd9474449abcf83118b5559cbc2f4dfd4d3ee51b5847a57','c438e97a081204acde941d0c625c6a8c64b4e6343d265ffd23c128187b6f2841');
INSERT INTO blocks VALUES(310026,'6c96350f6f2f05810f19a689de235eff975338587194a36a70dfd0fcd490941a',310026000,NULL,NULL,'3de7bf2043ac2e68bc9eaf8d1c12195a4f2400bc78c8deed0d487af11edf401e','c3572580398fcd71e5a1fef6e10217a99dec1aa605d61830ebb64ea65b7907ae','90e490dea7d1fdef0174a0dea745687566bc7f6b677f2668d0379487c0299484');
INSERT INTO blocks VALUES(310027,'d7acfac66df393c4482a14c189742c0571b89442eb7f817b34415a560445699e',310027000,NULL,NULL,'6c2a67783cf36e8987dc1805f87532ee1b94f79fb00952d8ee4cf3daaf655f85','b8b9d102d56df94d4fcea6f8aeb92d3cb859d3281c9fac7407842b7f05313737','da7104c716911ba36a1239852af71961d434e07a6f5788b99c1645c3c0efd152');
INSERT INTO blocks VALUES(310028,'02409fcf8fa06dafcb7f11e38593181d9c42cc9d5e2ddc304d098f990bd9530b',310028000,NULL,NULL,'659c73390e2e7eccc07d690fb438181c604787208bc45f466e57721fa1e21a64','55eafa176bc145ec7b98497c8a156226c68bd3b921cbdd06a890b2bd660ca050','a27c29a15664be4e41040267ed54b1a727c5cff8286b3db1258e2235432b601d');
INSERT INTO blocks VALUES(310029,'3c739fa8b40c118d5547ea356ee8d10ee2898871907643ec02e5db9d00f03cc6',310029000,NULL,NULL,'87449e7ff7316e49012934d83c1f5b733cedf39680299a9582eb216e260e0c02','c2fc809ff3ef6b74b10b1439fe15c275c6fd925e92dea73cf9d603948aba0d8f','b43338814db1c563e67521dcef7af1cc59104a9c5e19aa78a90efcf86ca1f84d');
INSERT INTO blocks VALUES(310030,'d5071cddedf89765ee0fd58f209c1c7d669ba8ea66200a57587da8b189b9e4f5',310030000,NULL,NULL,'6c4a7f749d0308edf5c88b3ea4de3b1d497ba3bc06435594d77686318b744b0f','45db1d0cde22349299df8245e7ed24d308e1b1cb227098178606650f20832aaa','8a7a9105b77a9f8e4d94c169ebb9bc108d0d5224655297add858bfe1bab7e5ba');
INSERT INTO blocks VALUES(310031,'0b02b10f41380fff27c543ea8891ecb845bf7a003ac5c87e15932aff3bfcf689',310031000,NULL,NULL,'ecc04b1b2c7803ca17dc2a32adebd0960de2c04c8dbfec9cd88771dd883c885a','981653075dd609f44e0a5673dac2b63824b84e26080ec226547892c67dd7cc33','5a824a765cdbf092de7d36cef9959f77306da28c29cd4cea2b055135a367745b');
INSERT INTO blocks VALUES(310032,'66346be81e6ba04544f2ae643b76c2b7b1383f038fc2636e02e49dc7ec144074',310032000,NULL,NULL,'01e769c5b990db44a9e534bc6c759567eb4283e0ea252578dd525923c7fde02c','81778134948c3577216eeeb6db7fe9687545d855dc3b5f6bdf6053a7edf3eaf3','0e9f7f7ae207d4f4ad8955fba51b145154d8a35c26cea1827a1509bb2c616519');
INSERT INTO blocks VALUES(310033,'999c65df9661f73e8c01f1da1afda09ac16788b72834f0ff5ea3d1464afb4707',310033000,NULL,NULL,'2df6b8dca0ffa8d6d55997605188637c2b86300e4dd7ebe3f1f275690169fd46','650b0875a0fb44a0ad1b04edf1a0eb1b50b5ecc423c6ecdd37b5aa60b5e85663','379499fb3f9d048666b757fb567cd29b3f7732c8b18d6b824f438f0b9e0d724a');
INSERT INTO blocks VALUES(310034,'f552edd2e0a648230f3668e72ddf0ddfb1e8ac0f4c190f91b89c1a8c2e357208',310034000,NULL,NULL,'7f0dc7c1527a7d11831d272f0295eacabcb96fa3599f5a716bd29ba1bb6b7577','e9d6c050b077d8e6902999bf64a0f1bf420c881b8a32c511ae81b0359e83a542','b792f463a90a4b99bd585b6b09ba598800df7f72bfc46c1c4d6532da3aea0b65');
INSERT INTO blocks VALUES(310035,'a13cbb016f3044207a46967a4ba1c87dab411f78c55c1179f2336653c2726ae2',310035000,NULL,NULL,'5e0cdf1764ed94672c29144f9c1bd9c3e70784f17c9dd1c9e4ce703a99bb3599','e755b5d80c9995dfa5763b080b9bdd349fd7b5bd940a661836ad418202b77384','cceb0d5e9015f411b1ddfa1a2575d7bd6353022b3596db218dcca80ea06f4d5c');
INSERT INTO blocks VALUES(310036,'158648a98f1e1bd1875584ce8449eb15a4e91a99a923bbb24c4210135cef0c76',310036000,NULL,NULL,'96da34a5a66b89aa3e8857b4a4edca51a56a0cbbfe600d8153077875624a153e','cbc0139fb09af6a6c63e07847a37f15767a1f7b01d6305cf40179de841c4f093','13b202b0bbfe0779f9bfa3845ba7c00db6a08a3e69076dfba0897a0533f69170');
INSERT INTO blocks VALUES(310037,'563acfd6d991ce256d5655de2e9429975c8dceeb221e76d5ec6e9e24a2c27c07',310037000,NULL,NULL,'d481358c19b4220aa9a3d135fd0651fada6df8d0f27b9ec954ac07950e876c0c','0493eb6bbab5ced7f25c6f5a3b32e4e2da321a5c761855ef64b5e050ddcfe431','21568213e6fa8e5c8c4e6a605646b635d00852fca984bc08e6d96fc44f18e7ed');
INSERT INTO blocks VALUES(310038,'b44b4cad12431c32df27940e18d51f63897c7472b70950d18454edfd640490b2',310038000,NULL,NULL,'4e9fcc454ee53b3617c792eb6577c2eefa6eee6aa4a2925538cb1976d48817c9','64b95af50bbee190166820a564e858e5c86769c04b22a68c2bed5adee0f7292f','2a116a6a25289ebb492aeb08ed11c420ba91a41714d70c7293f20c6d61c8f866');
INSERT INTO blocks VALUES(310039,'5fa1ae9c5e8a599247458987b006ad3a57f686df1f7cc240bf119e911b56c347',310039000,NULL,NULL,'795c5652d9679942a02060edfb497b072009695d9a72fb144fa3591dba65a2ce','9927f1558918a59509f668789e75198eb432fd63e0a7ffb46160d002c0932188','a47fe1e6cb9464de547b7bd5f63d13e81c637b0f70f7f9aff83c92b4b9d724ae');
INSERT INTO blocks VALUES(310040,'7200ded406675453eadddfbb2d14c2a4526c7dc2b5de14bd48b29243df5e1aa3',310040000,NULL,NULL,'e569e6e8083818e594e92b3356833e8dd54fcfcf5ed25af0d09e36e24b9dd441','969f7176f1a56d43e0d1b4da9cbac17cb1a934be64c12b3784ef33b584513271','8b5b40b27ed3077337747a6069283ce822753e98b70573ff28c5fbabc6354156');
INSERT INTO blocks VALUES(310041,'5db592ff9ba5fac1e030cf22d6c13b70d330ba397f415340086ee7357143b359',310041000,NULL,NULL,'2247fcc633175a91921d226f412e56822379c79ca799117c39ecaaca0a702192','29cb8f1b29affa41416aca0265599863f6b739538f13bc6672f6b3c17e411045','f3ee14e47e98fe9be722e5b150b8c3d528a34efd473258b680326c4b8aeb7556');
INSERT INTO blocks VALUES(310042,'826fd4701ef2824e9559b069517cd3cb990aff6a4690830f78fc845ab77fa3e4',310042000,NULL,NULL,'0246c3a2a70b33a038ccdb816f6b0922a50d08310f360cbd5db4df58e97fc4dd','d1ca4c9abe26de83d9a0170461c87f2c219926f8dcb0c48793d74a0cbf01a43a','462dd0ed247fa45dadb7a299fa1e6e367c3db0ee1206664c23c1bd35bb189b21');
INSERT INTO blocks VALUES(310043,'2254a12ada208f1dd57bc17547ecaf3c44720323c47bc7d4b1262477cb7f3c51',310043000,NULL,NULL,'cbe39e9d1a132cdc568f893bbc3d4f55d27bacf7af31f027ebea1b4bed9f0009','452b2e3ff4075f702cddcb4b8fd9006c756dda7a3527d635f637a200fd621c91','36b903ed1c74c65401293381923674dcca0dcfae93076b029d9cc9e859d23193');
INSERT INTO blocks VALUES(310044,'3346d24118d8af0b3c6bcc42f8b85792e7a2e7036ebf6e4c25f4f6723c78e46b',310044000,NULL,NULL,'1202b05e118f0940ce270d9002d010076115a0197d889fee2d971a77709899bc','527114d86a06f44f12e1f789f095227f9710b47e95251cdbd6f4c03309eae61d','fdb65c7adf0be37b86e426f22c8f36721ee9658feeb10171a4f444f3a7dfa182');
INSERT INTO blocks VALUES(310045,'7bba0ab243839e91ad1a45a762bf074011f8a9883074d68203c6d1b46fffde98',310045000,NULL,NULL,'0bc49f765419c0b5b4911cccf03b0d9959aabacda266480b98245de0c0d35fc5','ed6954fc7aadd8f80684cc67580b9cc16f9a402296ac91c021de0148a1ccb4a8','3b69994a0d03bbc71f228795a36cb3b657b210c5c4143ac80f00232ae9ebe434');
INSERT INTO blocks VALUES(310046,'47db6788c38f2d6d712764979e41346b55e78cbb4969e0ef5c4336faf18993a6',310046000,NULL,NULL,'e42bf9806d0ff3a0663756f7955b30735747d14fcb0915c89884baa12795163d','2e62ee5d03044d0b6086419a6d2fed78b7db3bee75a2bc158bbc04a8f5c34908','151e6cb2504c777a41a413b620f260ad1d3e175230ea183791fd2b856666fc54');
INSERT INTO blocks VALUES(310047,'a9ccabcc2a098a7d25e4ab8bda7c4e66807eefa42e29890dcd88149a10de7075',310047000,NULL,NULL,'b19b5e14741284b4ca06b736120e903363651460a6efb3ede1aca3a4f3c00df1','bd40f4de40c172e5b5997091f4a069ea54d25504421e6225ef3d9ee360fbca6c','d6ce56c72621844097e8fc3eb4abfa7a1ddc37300e33995f6b0df7b90eb708fe');
INSERT INTO blocks VALUES(310048,'610bf3935a85b05a98556c55493c6de45bed4d7b3b6c8553a984718765796309',310048000,NULL,NULL,'e870de901ba86d65d0e2053251ffb32cc7dffb55fcc2efbc006a2b9137314a39','d89730ea689c2912f38a2d2dc86caf6dc35a3e183c4d394129f21368f5c1d371','7f1d8103ee88b9d07d554a3a25fcb73a336bdcc52a037129bc7625f79a4c87a0');
INSERT INTO blocks VALUES(310049,'4ad2761923ad49ad2b283b640f1832522a2a5d6964486b21591b71df6b33be3c',310049000,NULL,NULL,'44cf354cdc8552ed37e5911340397d3531d0ba45100feae27377130d4ddef359','1100866c04ae89913abf573ee61b3a7b56ec8fb7526c7d9c9938d61a187586ab','18577db81062abb3831351555f06f96ff951bd17bbcd4a9b610a9a6a9989b178');
INSERT INTO blocks VALUES(310050,'8cfeb60a14a4cec6e9be13d699694d49007d82a31065a17890383e262071e348',310050000,NULL,NULL,'7d72f11f48ac99553e1b2c52a7ff5645fbe05728a10a002727b9270dbb32daed','1d95ff7cb416f1915ba7db0099ba9591b97c6bc673cb43296cc82655627eb1ad','478c226bfdb2ddcd3f7ab2e0b3448e14eb494e097c53acc84755ad45384af18e');
INSERT INTO blocks VALUES(310051,'b53c90385dd808306601350920c6af4beb717518493fd23b5c730eea078f33e6',310051000,NULL,NULL,'35a965dc90686fc4eb20450da81ca8db9125e25c2cdd7146fd61d98841d80c24','9d15589506565edb31f7627a37c1f6a6bca01d584b0dc815e8603689f07a80db','40139babec20bcd7915d24efc22f4052bd52f5c58537ce376f456c9c01223a92');
INSERT INTO blocks VALUES(310052,'0acdacf4e4b6fca756479cb055191b367b1fa433aa558956f5f08fa5b7b394e2',310052000,NULL,NULL,'8604d503e7194ee1c8ebe1143019207b2aad163655107a3d23d018ef26cef550','40053c62babd7f69b9822b6d4223732008d45250146216762da4e13b1b9d3a3b','b966ae06b23cfd9495081251da2ac41cda1a39462ea55b17238f9b5fae860179');
INSERT INTO blocks VALUES(310053,'68348f01b6dc49b2cb30fe92ac43e527aa90d859093d3bf7cd695c64d2ef744f',310053000,NULL,NULL,'ecdb64ffc44490eeb12199d2da5c1189c07f4102f5b91494cbe4ec68fe6bb6d4','7d74527f370a78a8dca189b60657f9fd15c27ba5f875344546bb8d6e5b54c8c5','21b2bb3cb2af87b875e6aec6ab061028ee1881ed9dea2461dd9dfedc3d8e0ce4');
INSERT INTO blocks VALUES(310054,'a8b5f253df293037e49b998675620d5477445c51d5ec66596e023282bb9cd305',310054000,NULL,NULL,'b96b0d51d6327284f5922b65e5d023afd2b2e44c9e11f435afbe2a71df4e6eb2','70b8a2eccd5c79e1c270abfdf683dc4423ff315a62486db9e5972a12daaf60ea','ac0768def530ceb321c48ee0f9b5a2837a070e1534741019ce401d6492cd3fde');
INSERT INTO blocks VALUES(310055,'4b069152e2dc82e96ed8a3c3547c162e8c3aceeb2a4ac07972f8321a535b9356',310055000,NULL,NULL,'c5be3fc23a9c41b7b78cc7df4ed13d1d35fdd7edab77c998cef5a5a5fe2a7d33','0072c2fbc0915dcc39103950d4a48feba19eac28bde001d3dfe0f9ddc25e5152','e4b797073a6c02001b297706b00543df6ad2d031c907f38ff96070180c5ecca6');
INSERT INTO blocks VALUES(310056,'7603eaed418971b745256742f9d2ba70b2c2b2f69f61de6cc70e61ce0336f9d3',310056000,NULL,NULL,'faa7cf6128f229fe3d408797c77ef2972eb28d16542b32ec87c5fd42d2495018','46c53b0ab86b04c06e8302726aeed5922fb5b3d940102422c53bdf4bafe285e4','6392adcb77175958bb512f1eed9cb4fee9582f89380526cc6c41d414ba5a8186');
INSERT INTO blocks VALUES(310057,'4a5fdc84f2d66ecb6ee3e3646aad20751ce8694e64e348d3c8aab09d33a3e411',310057000,NULL,NULL,'135af680c59a3d707ff3e6b67fbbb0aaaf0a97724d36ba584087658ae8c0db19','8b3fe70c1d1b8fa1a247810dfbc2667ca0307860c112002e47107fe4836b8138','1e709fa565ec0a7aede23f6ae21c5818099e5c81e1e53522a9591ab5b94055d1');
INSERT INTO blocks VALUES(310058,'a6eef3089896f0cae0bfe9423392e45c48f4efe4310b14d8cfbdb1fea613635f',310058000,NULL,NULL,'496b559ef740feabe42d55356bc770bab7b927d79260c22848b7f47d51918f11','ddbb4db386fab0fbbb7edee7c7c45676f994d6feb088f50b0f3edaddcc809e47','ffa3868bc761e4624e402c26ae54dfd9e2082b8f1d961a30cde94aa1b780a009');
INSERT INTO blocks VALUES(310059,'ab505de874c43f97c90be1c26a769e6c5cb140405c993b4a6cc7afc795f156a9',310059000,NULL,NULL,'608eb77e572aa596c9e14c6e4cb1dc1993bcbcfe735cf0453124c2801192ecc9','b8d3a5abf9edc13434594de8ec0cdf3b760f6917798eab89ff2a6a4f0bda06d9','4eb41e13f80ca36bfc8eec3a53eff45c703b2cbc86d9aaf8cb32c8a1ec57c977');
INSERT INTO blocks VALUES(310060,'974ad5fbef621e0a38eab811608dc9afaf10c8ecc85fed913075ba1a145e889b',310060000,NULL,NULL,'bc5c375d1237425486c9f46bd749fba20b5635bcaf3e2d9178b35ddfbb700f14','1766568459fde2e95dbe4a1c1b73a37b6f8443dc1ec36cb44a38fadd95d8f807','495b87b3772d3caa3055cb4514d3822ad87f0110eda26f3c582b0b9575b11227');
INSERT INTO blocks VALUES(310061,'35d267d21ad386e7b7632292af1c422b0310dde7ca49a82f9577525a29c138cf',310061000,NULL,NULL,'c6d48d72746c0e18fa0f1b0b16f663869be2c4684a9d98b634e691ea495f4d81','9f6619aae8ab667b4291ec14e89386177dec7f3465def984144d2991d10476ab','9a918ac00a36b1f5ebcd998bd575413c7c1d7d6886d25910e82bf3ffbaa59ef6');
INSERT INTO blocks VALUES(310062,'b31a0054145319ef9de8c1cb19df5bcf4dc8a1ece20053aa494e5d3a00a2852f',310062000,NULL,NULL,'8deffdb1602f1aa2d0d1956d2297ba30ac78901ea27eb223ad8bf7ca83b18110','278612a215aec2522b38d2ddd268f051906a858996b526fa53c48743b1f33c2e','a1866858995e45f66ab8c55e3674318cbf9b843b79dfd3148da300f46f42cf1d');
INSERT INTO blocks VALUES(310063,'0cbcbcd5b7f2dc288e3a34eab3d4212463a5a56e886804fb4f9f1cf929eadebe',310063000,NULL,NULL,'34859861f240c6553ffbf63fff9bc884f231276ec6173964d5fc6641a6d79b16','a884effb413598885693dd0eed419a3a2a35db95fe4d6582e580bc141f28377c','16d80190de1e1479a6ff939431ca950fe3bd99b663bd4d7f06e65f8d5f6a76be');
INSERT INTO blocks VALUES(310064,'e2db8065a195e85cde9ddb868a17d39893a60fb2b1255aa5f0c88729de7cbf30',310064000,NULL,NULL,'fa185f9b97a1666ce3b966dc09b8a7870ba55896a54a54f54d3420708d5a8ae0','070c320cd53cca3d81560367d437e1f4cb2afb10ab6339e2f1cfb0a2dd6d6063','f7c2b1af0b85e7c9fb2d29ea12d120745cab3bd918c9f922fb4144d75b346c1a');
INSERT INTO blocks VALUES(310065,'8a7bc7a77c831ac4fd11b8a9d22d1b6a0661b07cef05c2e600c7fb683b861d2a',310065000,NULL,NULL,'9f75da9f944d59b1841d690b2994ead7fb0ee3d679ddbdb0b692e49238f66603','fb310206b118e11d48becbd11a695199fd7cc3553dd8b2a7c29c6a927f5bafb7','ede1f73c1b35febddfc426af34cab094b2374ca3a4a5b8371c841a5fe3b12dbe');
INSERT INTO blocks VALUES(310066,'b6959be51eb084747d301f7ccaf9e75f2292c9404633b1532e3692659939430d',310066000,NULL,NULL,'4740587d203632d1b4061343436e25e12941f0f80be03c3ab390a1c08b842b59','041e6429d7ad46da6e1a2547daf274a0df952ac4f9b43eaadfeafa6e005141d6','a38c4c37c0a503cc3d6aadbe89eeefbd0f9ba387f32318915b38f66783ce47c8');
INSERT INTO blocks VALUES(310067,'8b08eae98d7193c9c01863fac6effb9162bda010daeacf9e0347112f233b8577',310067000,NULL,NULL,'d6eecb0ca22f29b50e52cd5dec8f408250a7b1ddc61bfa9bf6cc6ef0a85a6ffc','f8e9baf27b01e99db390d6ee2e06b8ac7d92951c331d8240fdf0dd711ad75979','21a10adc024e7f2401f108985c3bed245e71792493a66b4c0de02773d688af5b');
INSERT INTO blocks VALUES(310068,'9280e7297ef6313341bc81787a36acfc9af58f83a415afff5e3154f126cf52b5',310068000,NULL,NULL,'1508605d4796eb2d8b0553b307827f570b5020f4cacf773926b6c8f2c1b003c8','fe7a135af64a7668cee07a66fa146b6a7a54fc78b96eb7c62d0bbd8b8ec4a820','a8e824e548420874f103887f9ed8c383fc104b0ad1f7085d72104c3980be91f8');
INSERT INTO blocks VALUES(310069,'486351f0655bf594ffaab1980cff17353b640b63e9c27239109addece189a6f7',310069000,NULL,NULL,'ea7afbe0817cfef5a5a940bf88b057d01d092182dd5d0c7fd156b6750fdf4cb2','561526733017c46e8f7476f6f7f0a1c317a372adf6ccbe2a34e4d8b0fee1a694','b5dbb1be55a10f7653b7ac5d50bdbbb35d1c708fa99ae665f920e55c52efdfc2');
INSERT INTO blocks VALUES(310070,'8739e99f4dee8bebf1332f37f49a125348b40b93b74fe35579dd52bfba4fa7e5',310070000,NULL,NULL,'f805d8bd0b724ffeb9e466367e8524bcbcf2c0fe0525b8ff2707af2013824a2c','4c10a876e31ee15289cd2d82d8771bd9aaffd0e335c6de15f8d5316e6e7ee81a','f15431fb4902f601706d04170a078e96833bcfa5d240d28bf84e3f2eff67baa2');
INSERT INTO blocks VALUES(310071,'7a099aa1bba0ead577f1e44f35263a1f115ed6a868c98d4dd71609072ae7f80b',310071000,NULL,NULL,'305123423486d17e97e8370399b9079a35977465e4cf8c5b33d50bd7004b463b','660d6afeecb2375668200669bac5cf258dbd18b0f61213eb01d29e133a45917c','4abafcffd714cf4442741698b9e9373496d0bf06ed4debe83abb079b975a3491');
INSERT INTO blocks VALUES(310072,'7b17ecedc07552551b8129e068ae67cb176ca766ea3f6df74b597a94e3a7fc8a',310072000,NULL,NULL,'b04fcd2cf46165fa31626b476aa06f9ad8c8cd1d5aa1cfdc014e0d55fa7e0761','0791350dc66254e276bfea1651fdda43705668f461f5451fd91fb7e084b26aa2','be99e728476c12785fc80e0cee01513168061ec47fd4e7a4388e56cf83e81da2');
INSERT INTO blocks VALUES(310073,'ee0fe3cc9b3a48a2746b6090b63b442b97ea6055d48edcf4b2288396764c6943',310073000,NULL,NULL,'209f05567343042c8a9172138cc14e28a2e53f9addf16c7affa469fbea9728ae','4885e82f77b273e102f9019b8451e08910a7d98daf19366a0a2b9db779352c0f','1c8a16f61e7591de03ed94e1367e4983237cd1b7fcb71159e9adb42ff40bafbd');
INSERT INTO blocks VALUES(310074,'ceab38dfde01f711a187601731ad575d67cfe0b7dbc61dcd4f15baaef72089fb',310074000,NULL,NULL,'fc18c0dcd6011c4147575f09bdc6e1eb0e6ae7d3144339859054df458651618a','49cbefb674e3da718d86151b10bb37755e158a2bdca642a542897361f15fde66','dd347291931e00267e647f92426d29fd31bac2d17e33bcbc8ce4da246f652187');
INSERT INTO blocks VALUES(310075,'ef547198c6e36d829f117cfd7077ccde45158e3c545152225fa24dba7a26847b',310075000,NULL,NULL,'f304dbebd02e4536b1754502e6f51e058ed309fdf95a2db8329dd7e5635824ad','b5e7c72a91d779334162c8fcb6282c7e5baeb43ef83d8f8c0eeb4dd0579f0916','da2c2b5def56e26aca1675b040034650665100b3ac897289a900581cf829e88f');
INSERT INTO blocks VALUES(310076,'3b0499c2e8e8f0252c7288d4ecf66efc426ca37aad3524424d14c8bc6f8b0d92',310076000,NULL,NULL,'f39c071315c869425bdbcf05ff84130a0860f5f47b4f851cea970f58a6edc9f8','e399bd32bd2988f29b4fb003686b343bd72ae59297412480a359bd56ded23ca5','301b91e522175be0c4e42eec38934eceae1a7e2ccd617d3366c6a59e9bbc9760');
INSERT INTO blocks VALUES(310077,'d2adeefa9024ab3ff2822bc36acf19b6c647cea118cf15b86c6bc00c3322e7dd',310077000,NULL,NULL,'20624d783cd8e82044df58c05e6171a744505df43623d9c2a828c1331f505ca8','c587d5426925227ed7d0ef11834b5bb1291fcf0ea3f0bcac864e4356187b6a10','e599272caa2a788eca77af92dc3fb1c092dc4f56abdd8244ebc760b700d4e486');
INSERT INTO blocks VALUES(310078,'f6c17115ef0efe489c562bcda4615892b4d4b39db0c9791fe193d4922bd82cd6',310078000,NULL,NULL,'41ae6610121587bd8171a02da3c50645e8e6d3642aef2c560d46f12707506b66','c8331e225af242d83e283889e6234d601ecb507373f4b7de891b8508d1b7b1b6','62e261d2500459db879e2129f824d6e49aaf05e13a40435c8422973dd81204dc');
INSERT INTO blocks VALUES(310079,'f2fbd2074d804e631db44cb0fb2e1db3fdc367e439c21ffc40d73104c4d7069c',310079000,NULL,NULL,'bbc2068f2a4b47c86198a5cb7242e26f385077126c7a3294eca6607485b1170b','42ee671f6b45a8e36b4e57dc7edaa2501b075eb75bcfce535435ee4c0cdf2e66','8fe19103fd2f09af809b8a3c91be4d57c3489de01cdbe3eaba426aacf09511ac');
INSERT INTO blocks VALUES(310080,'42943b914d9c367000a78b78a544cc4b84b1df838aadde33fe730964a89a3a6c',310080000,NULL,NULL,'fc4350d187ec74fa6dfbbca7f6c51849b78356f853c6c713d10ae4a39ee4f7e2','f35b5543ac99e33a4ea6fb61b688d06a2b5b9cc79776df32c24e848b5dad80c0','572cfba20920f03c3869458a0acfc980dd2a78ff8ef50d556efdf62c73f0c950');
INSERT INTO blocks VALUES(310081,'6554f9d307976249e7b7e260e08046b3b55d318f8b6af627fed5be3063f123c4',310081000,NULL,NULL,'3cadb90f0285d3e3bb107caa2165e88d855cfa057fcff1fccfb278a8f64c9b1c','3ff813ab5112e5adf9f50936955db90036ed0e2ba309022002c69e81473d7c04','083434881837aad62d84bccfbd07e5564d0df409db72c196d036189673ee9e46');
INSERT INTO blocks VALUES(310082,'4f1ef91b1dcd575f8ac2e66a67715500cbca154bd6f3b8148bb7015a6aa6c644',310082000,NULL,NULL,'f3390bff59484b5ce0d84f5034fc88f4d862334ef3c0d7addaa9be7f0e67006f','3d843f898e46d0ec4c4cf79709ec7326a0e45d44361a2c9fe45e546bd5f1e630','c1a19f3f6f0032d73ffc9d15fc8c80d6ed503b166d48f623948b8f10a0037d39');
INSERT INTO blocks VALUES(310083,'9b1f6fd6ff9b0dc4e37603cfb0625f49067c775b99e12492afd85392d3c8d850',310083000,NULL,NULL,'0354bf318eaec5c79b4a7835c76c89f373ab0e413f9fe4ebdea442f57763a971','6405368df02c1207da46178c106ac287c7c90e5b87a98154aa938f6ef5a570d1','d4fda15bd80261a62665803d2300636015ada7fb8ac44d3677b6337732bdec3e');
INSERT INTO blocks VALUES(310084,'1e0972523e80306441b9f4157f171716199f1428db2e818a7f7817ccdc8859e3',310084000,NULL,NULL,'e22b7a64e15ded24f6c54a5f627354dd2c3ed8175c2f4cd31aa5a6789d7b67e4','6f58e857b2891d43f22bb4b44d296ff18f3078de01cf90aeed104283d66342a2','5a2bdbc283d65d974df9b892983efed70ba6a81626879c9c17d5f2f5b5ac2ce5');
INSERT INTO blocks VALUES(310085,'c5b6e9581831e3bc5848cd7630c499bca26d9ece5156d36579bdb72d54817e34',310085000,NULL,NULL,'7b8a6f62709cf4d20820031f43d968ea46d73d8cee4ad40f414da60b9be4e676','51c8a62f3e4c43e6eea75410efb977c8ddd2ad8e64c0d6ce6f63a4e5eb153400','07f64512e291449e752cdae8715681b96217b8a715781ae2140089536ea3007f');
INSERT INTO blocks VALUES(310086,'080c1dc55a4ecf4824cf9840602498cfc35b5f84099f50b71b45cb63834c7a78',310086000,NULL,NULL,'ae82ee2f7f1e075937b5b8eef065f8643a7bef0428e00689ee773558905eef19','7358e41e9a61f87d68cc6851768346daea2e100ab896e86c0047e47228e6cc29','6d8b7384f5e5bc8064c39b7c342d38aadf2aca27d7962120ca5165653ef07760');
INSERT INTO blocks VALUES(310087,'4ec8cb1c38b22904e8087a034a6406b896eff4dd28e7620601c6bddf82e2738c',310087000,NULL,NULL,'ced371f1349e81cc2f179f064e4b9b202650a0f79e9b4513666ace29f0e8b3cb','0e8cd750f8ad91d5b14d2b05b7c03621367036703bed1654555b94592ff41e11','73212ee74016e3ed348965379e6a8500d39459732fb166cc9589b1583edc612c');
INSERT INTO blocks VALUES(310088,'e945c815c433cbddd0bf8e66c5c23b51072483492acda98f5c2c201020a8c5b3',310088000,NULL,NULL,'6c343897092c5dfcd32ee96dc8b96f38fedd31fa58cf5757a3e15a254942cd59','c38a183db86650f155005a8828155aaf2fc6d92aa89066d7f0843a123800d771','e23062e6a618b27e4efd309afb246f1254e5e78d70595477851b0eea06fd173f');
INSERT INTO blocks VALUES(310089,'0382437f895ef3e7e38bf025fd4f606fd44d4bbd6aea71dbdc4ed11a7cd46f33',310089000,NULL,NULL,'abc7afdaefa89bf58bc4c28401740657eca24c902ba551f55becb6a1c8992675','609b4f777892b43541593da80d09aa2c3928f2f73600009615196a7f89ca8123','585f87be8dff91a1669a7a8bc9c3f98e7bc436d9db7a2af7f3eec61ff2295225');
INSERT INTO blocks VALUES(310090,'b756db71dc037b5a4582de354a3347371267d31ebda453e152f0a13bb2fae969',310090000,NULL,NULL,'4c8ca9b4eeae7adfec822b20665e7bd6fecb51d4f30cc2c826f18402d8401a9b','fba4f7514306c49b3045912791cc21a26527a23e58dcb1c8adc5563e5c6e901d','cad5a108008134f11ae847cab86a638d99d04621c6ad6581d019cfa209942a56');
INSERT INTO blocks VALUES(310091,'734a9aa485f36399d5efb74f3b9c47f8b5f6fd68c9967f134b14cfe7e2d7583c',310091000,NULL,NULL,'fe7fd2b60c3216d79dfe4e6d38880f6d3b9fde747b619f2c477108825235663d','3a62ce0eeff09c242b3a7c3a8da6dd20bf06c1c2fbf224f73646791557ce3d4c','24d1fac2d211c5ba57f73097ab62b9127c0a0e18ddbbb8950cd27050bcfc17af');
INSERT INTO blocks VALUES(310092,'56386beb65f9228740d4ad43a1c575645f6daf59e0dd9f22551c59215b5e8c3d',310092000,NULL,NULL,'420b8ff3c159f7e89df2274682e7ef798a0c0233149365114bfd934c38806098','9c866b1985d2ff084264e192e5defce4af96b7aca461a46f58c659008113909a','09fcfab44a4e68fe7ef6d59e8a9f946d4e01963670999fc40d86c2319d90c333');
INSERT INTO blocks VALUES(310093,'a74a2425f2f4be24bb5f715173e6756649e1cbf1b064aeb1ef60e0b94b418ddc',310093000,NULL,NULL,'f4fac6a570b4f6332a628a3f8e27f5f081689fb4255363cff1cd8bd0244eecea','271c5484d7a74166a1b83e9dc6f56cc391d5b01829c9b594deb087e58a22b762','4bf5145f8d1374d6f642b7205cb55da07c2ac36c4ecafc37111d76535b70eebc');
INSERT INTO blocks VALUES(310094,'2a8f976f20c4e89ff01071915ac96ee35192d54df3a246bf61fd4a0cccfb5b23',310094000,NULL,NULL,'adea7b4cacc06ba1f7dc260f30039943936f5baeecf5a8a452d4cbcaa994a70d','7d8deca0e4f444c015cdf98c74255215af14198d17619640186c6486bb3a6be6','158353e853cef615a3eac507d742725ec370419642d6b28f6558bfea76bba7f7');
INSERT INTO blocks VALUES(310095,'bed0fa40c9981223fb40b3be8124ca619edc9dd34d0c907369477ea92e5d2cd2',310095000,NULL,NULL,'a2290c6a24befab16b4d9ed768c3129d582edbafdf8a2326c7ed50397e5db674','8bab183d2c7670f060de1a64663fe4ec602cc9df957a4d1ccd4b2c5e4876e5ab','0db0a35d8e7e113a3c0a1efc9e44ed3e882a6cb383c712df1721f793f6d56a00');
INSERT INTO blocks VALUES(310096,'306aeec3db435fabffdf88c2f26ee83caa4c2426375a33daa2be041dbd27ea2f',310096000,NULL,NULL,'b3c321ea2fb119cbaacfb39f219be47cb346cdd40d895980afd34b4157a3b7ec','6997f2cf50cb2331a8d5cea3f97b32b41a9c40b6006041939b21008016e013c8','7aaaed5fa0f635e8d0b221c10d247898024206d81b8113f26d9a0f23fe62464c');
INSERT INTO blocks VALUES(310097,'13e8e16e67c7cdcc80d477491e554b43744f90e8e1a9728439a11fab42cefadf',310097000,NULL,NULL,'456a1bd4d6b30f24e798a9c1f975af109db030b0bca19db6b29788f938ce6c4d','bd930dddbfc97b06fba95a33417533bd58fd5e95326d8677d2939790850a67de','c1fcb0f53df871ff7929b6ad25319c9003c506c19a0a10fa1161cb90d8bdd0d1');
INSERT INTO blocks VALUES(310098,'ca5bca4b5ec4fa6183e05176abe921cff884c4e20910fab55b603cef48dc3bca',310098000,NULL,NULL,'f48d6574488a24155420ae76aa7dcecfe73f6a262a2434a96eb2e93f6bbf02b6','bf2e65b5a1da6ac499a4ebcde81b607f6516de77ed2a10ff363ddb05dd8e288d','7b6846ad011831383295e07b80299518eb920f1b66a4b622f7f211d8f9527bdb');
INSERT INTO blocks VALUES(310099,'3c4c2279cd7de0add5ec469648a845875495a7d54ebfb5b012dcc5a197b7992a',310099000,NULL,NULL,'e936debeb5d219215ba24e56ed34edb435131877c2947c0801824155fdc70c05','d18b9514ed9fda087d3c98eca75ea68388964396143b925cc58ce2e2d5c1c5da','bb00665755a2e9c8f8bc495d95819b53ffcf48dc4f7d8fa97e4ebd5aa2de1fb2');
INSERT INTO blocks VALUES(310100,'96925c05b3c7c80c716f5bef68d161c71d044252c766ca0e3f17f255764242cb',310100000,NULL,NULL,'2b033a615b9eb693ed59daca9bc047f61a3519bec5c2b64f968cf717c75afe79','1c39371c274124af6085dcf02fcdfda68d36d261bb47d7763ea3f09b70d0f62b','e439701e8cb83aaada44101128f9fdabde02a0cf2b9a668a1ceb74036c0d12b1');
INSERT INTO blocks VALUES(310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,NULL,NULL,'6a41dd11d8b611f6fde79e06a4f65d20fc15419f8336646130c02e9f7d87eff4','e2c84c519b3d759f8efb016894a981411328df6f0a778835c95ed4116fef01f5','1869b045ada5fc901687d975c6d9d10512edef02ea64482c837d6dc27f3bd105');
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
INSERT INTO credits VALUES(310006,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',100000,'issuance','ddefdf227fd8cd8df1e77f0b531e98a033d2e5b237fa4331b83c003de54877d9');
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
INSERT INTO debits VALUES(310006,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',50000000,'issuance fee','ddefdf227fd8cd8df1e77f0b531e98a033d2e5b237fa4331b83c003de54877d9');
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
INSERT INTO issuances VALUES(7,'ddefdf227fd8cd8df1e77f0b531e98a033d2e5b237fa4331b83c003de54877d9',0,310006,'BBBC',100000,0,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',0,0,0,0.0,'foobar',50000000,0,'valid',NULL,0);
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
INSERT INTO transactions VALUES(7,'ddefdf227fd8cd8df1e77f0b531e98a033d2e5b237fa4331b83c003de54877d9',310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,6800,X'00000014000000000000476800000000000186A00000000000000000000006666F6F626172',1);
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
