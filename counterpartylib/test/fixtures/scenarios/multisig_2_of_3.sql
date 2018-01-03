-- PRAGMA page_size=1024;
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
INSERT INTO balances VALUES('2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',149849426438);
INSERT INTO balances VALUES('2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',50420824);
INSERT INTO balances VALUES('2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',996000000);
INSERT INTO balances VALUES('2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC',89474);
INSERT INTO balances VALUES('2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBB',4000000);
INSERT INTO balances VALUES('2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',10526);
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
INSERT INTO bet_expirations VALUES(13,'86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',310023);
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
INSERT INTO bet_match_resolutions VALUES('86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243_19e4f4787538366983026745d72265d95c32180e741934be0c0c9a9392640de8',1,310018,'0',0,59137500,NULL,NULL,3112500);
INSERT INTO bet_match_resolutions VALUES('cb395180f84879bfa8aadbfc3b0a1f9ceb43805f930567451334aad30bab00a6_78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3',1,310019,'1',159300000,315700000,NULL,NULL,25000000);
INSERT INTO bet_match_resolutions VALUES('170565b2aa082c64e3cf8f0ccf2bf675372a4f068f698b663eddf916d432e52b_b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679',5,310020,NULL,NULL,NULL,'NotEqual',1330000000,70000000);
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
INSERT INTO bet_matches VALUES('86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243_19e4f4787538366983026745d72265d95c32180e741934be0c0c9a9392640de8',13,'86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',14,'19e4f4787538366983026745d72265d95c32180e741934be0c0c9a9392640de8','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,1,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',100,1388000100,0.0,15120,41500000,20750000,310012,310013,310013,10,10,310022,5000000,'settled: liquidated for bear');
INSERT INTO bet_matches VALUES('cb395180f84879bfa8aadbfc3b0a1f9ceb43805f930567451334aad30bab00a6_78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3',15,'cb395180f84879bfa8aadbfc3b0a1f9ceb43805f930567451334aad30bab00a6','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',16,'78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,1,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',100,1388000100,0.0,5040,150000000,350000000,310014,310015,310015,10,10,310024,5000000,'settled');
INSERT INTO bet_matches VALUES('170565b2aa082c64e3cf8f0ccf2bf675372a4f068f698b663eddf916d432e52b_b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679',17,'170565b2aa082c64e3cf8f0ccf2bf675372a4f068f698b663eddf916d432e52b','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',18,'b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',2,3,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',100,1388000200,1.0,5040,750000000,650000000,310016,310017,310017,10,10,310026,5000000,'settled: for notequal');
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
INSERT INTO bets VALUES(13,'86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243',310012,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,1388000100,50000000,8500000,25000000,4250000,0.0,15120,10,310022,5000000,'expired');
INSERT INTO bets VALUES(14,'19e4f4787538366983026745d72265d95c32180e741934be0c0c9a9392640de8',310013,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1,1388000100,25000000,4250000,41500000,0,0.0,15120,10,310023,5000000,'filled');
INSERT INTO bets VALUES(15,'cb395180f84879bfa8aadbfc3b0a1f9ceb43805f930567451334aad30bab00a6',310014,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,1388000100,150000000,0,350000000,0,0.0,5040,10,310024,5000000,'filled');
INSERT INTO bets VALUES(16,'78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3',310015,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1,1388000100,350000000,0,150000000,0,0.0,5040,10,310025,5000000,'filled');
INSERT INTO bets VALUES(17,'170565b2aa082c64e3cf8f0ccf2bf675372a4f068f698b663eddf916d432e52b',310016,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',2,1388000200,750000000,0,650000000,0,1.0,5040,10,310026,5000000,'filled');
INSERT INTO bets VALUES(18,'b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679',310017,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',3,1388000200,650000000,0,750000000,0,1.0,5040,10,310027,5000000,'filled');
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
INSERT INTO blocks VALUES(309999,'8b3bef249cb3b0fa23a4936c1249b6bd41daeadc848c8d2e409ea1cbc10adfe7',309999000,NULL,NULL,'63f0fef31d02da85fa779e9a0e1b585b1a6a4e59e14564249e288e074e91c223','63f0fef31d02da85fa779e9a0e1b585b1a6a4e59e14564249e288e074e91c223','63f0fef31d02da85fa779e9a0e1b585b1a6a4e59e14564249e288e074e91c223');
INSERT INTO blocks VALUES(310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,NULL,NULL,'cff3ba7c92f6b318eb4a4a5e2b90b655fc055d4e8a82101b813aef6e1c6152e4','9f6f20e36fd2b2b44df6e91fbfaeffc6d7fae9917b27d196245ee90c36d99ff1','85a06958d9c6620e0cf4e8d7502819df9a79125bc6f1f143d27bf9e1e03dad33');
INSERT INTO blocks VALUES(310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,NULL,NULL,'2281de0177f4fcf8d730e2751d7b9fb5da4df741196bbcaff470c7860a2ca0b6','b393dcd93d8e02cf3475cc428183d9c979afb11414ca9e8f867401351182d047','9096a5e156a91add456c6659b592df1eced8d2bbb460539d2904f2d1bcb31b72');
INSERT INTO blocks VALUES(310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,NULL,NULL,'802742a55d8ab83de24c45efb86d1daa0ad4e565cc4db6dcaa5cedb16ec4125f','a4e334790934f7c9ebaad65350678a7aaabccd408ecd2ce42b236b7006fbe6d6','5ceecc1fb4ed6c5e549adf31638321ec4698fc889187dc0d8fbb4801da50d5c4');
INSERT INTO blocks VALUES(310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,NULL,NULL,'ed279c6a985256134cfb39f1283ec97c8dc800b7255a3e8243ca9846884d0378','64d1ecab20a6e90414bc724e158a5fdfd4053ad32f982d27498aeadda3d9510d','073528e1297f2cbe38b5c3ad02d5026194ad9ee16c94872781f9e46bdba96b5f');
INSERT INTO blocks VALUES(310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,NULL,NULL,'bba1ec90ee149be7d8a88ff9df1fca931e076e885be21bc822637829a8675e02','3345111af3d4dbd9ec2e2ee1429369c530d43e5306b97dd74afc1267646a592a','8f8e7e8e03586f60ec838ba2f56e88d5c6ba70e8a78277ed391fde705091fc9d');
INSERT INTO blocks VALUES(310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,NULL,NULL,'5f8a9d465e686b3e9471041bd15d645b7fc8afee36ee890873aa6c3c51d87bb5','82fcba49d0bfc014ac8ab30a4691026d26b5d26420e95b458356f15cf5aee8d6','274c5b87e5f8911af6da954c4799a169e38e6995af03565e169e1755dc834056');
INSERT INTO blocks VALUES(310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,NULL,NULL,'153795f1c7ae2dbec7fc19bb25d03dd518f0664bca82b9bb92bb7c4f1e22f040','bf441cf8ad660bcd326ddbde426c754967354ea138c97090832df658740b8911','e0c3647fdedfdfb2720d75082fcba0c27ed9148fb12ac7552ad85938ab8c3863');
INSERT INTO blocks VALUES(310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,NULL,NULL,'c5d21baa8c6949a8e9f0d73a37436d431bf4876ab3b60b82553877ec53fc4454','7394aba3ed78139155e8e2a3254e0acffda47efc1c8c5ada709b9efe5a28cdcb','2ad30c8d01ab5218d92b4428592481bcbd592290dcc62ea8da8bcdc38ea8bdb9');
INSERT INTO blocks VALUES(310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,NULL,NULL,'579de8204446e9128076fd27a644a82da77ca5ff2793ff56815c24a11218af5e','666e6d9782286353933cfb3bab6831856d70081b02b35ec0607e5430bc295df3','f31c66f44d95d0b61bc25aad5eeaab319660cec0bcc1875cb530e0f3d67d85a6');
INSERT INTO blocks VALUES(310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,NULL,NULL,'c03a6e31f50f172c86029ce6a810ec730e1179ad3e76ba5d4290595ec414bb87','fb1b8ee4e94d23f56f967a4f2c48301855261c1a76ece49afa0b7519f9705806','373a57f6f56397ace901dc53c35c43ea4b97d4912156039de3036bf61b8dcab1');
INSERT INTO blocks VALUES(310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,NULL,NULL,'804651f6571bb24ef7534c97116ae35fb0b6b31aa6a4574a419aae7fc2900b1c','3fdaf1047a7e198c4aee58a91ef03ec877bdb08f4e0c925d71e6f6313bfab670','d743b760869b75cb09970c597d89a6d70a73e64465c8e87ccc9f6be7014a0bec');
INSERT INTO blocks VALUES(310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,NULL,NULL,'a9a18fcba1a83d637dcfd633f32848d55c86c5b499e0c15af6a626653b7424b8','48fc3614db40e4e4bec1155b7a0fb626aeb055d70324ff215de9e0a277eeaad3','cb343bb5eb47ec500b876ea8cf15d10a7c0cf3a231c5f40b68f66841095c20bd');
INSERT INTO blocks VALUES(310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,NULL,NULL,'27298dbdb9026b5d54228b686b7a76f9d42479da79b38b9ef7cd13e4fee27159','2ace23067da65eebd379aeb5af299552a1a9c9ac8de16de4ba3cc977b9d798ef','42263a28c60f5cf142c45762993d8a66bd8ac1ddca739a660607d8e50915aac0');
INSERT INTO blocks VALUES(310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,NULL,NULL,'f5fbbb8870bb8253cfba52c58765b8c2493ceee6a2db5779a4212ed456bf892e','1b59846be20f983f8c11f92770b17da6a7bb18dd6341861d2fa39f68404764aa','fe3703102f11850d5a05516fb20f6d6d997d753d60395d5db048086892938d0b');
INSERT INTO blocks VALUES(310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,NULL,NULL,'f1e77a7a4d28d64a0cfd878112074b6205ef09055b93b8923b0c6466a07ea500','2074eddf0e2e6b893e209f1909fe5b44a2db9801dcc795ccafcce7ee43407dbe','b0ae68f0d09eb74c1bc2605b6bead68b0c5bbb9f6c1df6f007af4e693034abc0');
INSERT INTO blocks VALUES(310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,NULL,NULL,'014bcc839c0ea0d2fecd9aab3074528ffee3b2dce7f805e4d459e2dfb3d98a51','ffc017fa42d6c15fdd490fe0409857444e169aa4a172910433bd56cff0e4e839','09ea9ca7a899be44d42651362e520f7e06a7086e79d4f9d68494ad2c7b52363b');
INSERT INTO blocks VALUES(310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,NULL,NULL,'9f72d6a84ee58e1e851a90a62b525dc257c3b1b0c7e9964f93a7e5df6a2e4007','a10c4dcd15745010b18524941893aee733c5a55ab9e63aee83ca7131b631f0d5','9f438e48515420d808e3d82719dd5321958061f001a070380ce8a72952deac76');
INSERT INTO blocks VALUES(310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,NULL,NULL,'5d1e195a7d313d703253640cd98be600b04a7d98aae69b5327a29e740573198d','d8fdf48250eaf35baa0e030cf6a95c1f98168ba497004e631683bda5ddab60df','e707a284a666aea1d264838dda10799972490f42661cb08ee5b2fe68753eb7bf');
INSERT INTO blocks VALUES(310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,NULL,NULL,'f38538a4a2cba9bcf8821b56e1dc877990e027135d3f220338cd8cb11f3eb205','a8c27bf785bc19f39134d007a2aff2782e213f730c94d249ccda5ea91d8d7136','d545c0c5a54d1a8514d65673b2278ed8dbe0d9a362ea9c7ca834f9a8f8988dd1');
INSERT INTO blocks VALUES(310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,NULL,NULL,'3a51f1f061d953c940ac7e53f8bb37df041f2d4f42a16f5c5d23707b8b0c0dc6','deb26b8e986e0d53a29d241f1ab54cea51fbc607b119cc05fe005e28b7008be8','57113bf3feee0bc56c20d8b2c23f5bccca366190eb8f6756151b484c42b672c8');
INSERT INTO blocks VALUES(310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,NULL,NULL,'cce3284c53fcf79ba268d925e32ab70e3d4df1e6f13dbcbe2920e93fc689128b','d5434623eff03d14611743be2752e04bbbf38f80b5be056bcb02cf2c5048db02','79ad3742fe53a2b2a4726a2aef284fe5aa04a13f7af72cb3b2b11cc4f4bb0260');
INSERT INTO blocks VALUES(310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,NULL,NULL,'6ad5172a6dcaa6706d5a4f6fd8ada183e103b9faab58e42c1365613a26477490','d4c8489e95f8d6f14dc10f60f038d547bd803ded41ac8cfafc158069e4f8519f','377a0e5a3e560d738ebf528ef643d7ba2894a6fa24b3492641dbd5461f5b57db');
INSERT INTO blocks VALUES(310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,NULL,NULL,'c9361fea7f3dd2415969eb6ad7fe893381c9ca65ea391f2e47a966e342db3a90','95b712dcec129d97951cd5e87f470a769cd00ab07494a3366e64187b77a38bac','98626fd381b02a30566dbd98d6fdc05185d9f9e3ce2d9883fb85c5172e43ab16');
INSERT INTO blocks VALUES(310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,NULL,NULL,'f63680db66cf963aaaebf64130629790e7492b5ea9396434c2179a5eb8774412','40167719df19f666f726aeb80bb1ccd153a131046f13384fe193f6a984d0aace','8406742bb74d7e1b491a3244da57b2f6d218ea47da4cc3868b8da7ee4b65ca30');
INSERT INTO blocks VALUES(310024,'b03042b4e18a222b4c8d1e9e1970d93e6e2a2d41686d227ff8ecf0a839223dc5',310024000,NULL,NULL,'d69ea243fcd5e525ae03af680d5610b654a9d2bad17782e196305aaa110a6ba9','bf6f9ad62cd3b708d6207eb40e62ee96c9c959e0612aaa2943c63987fa2ed449','dfc861263a222e252d511775f9d6d663308fb6f83f7b0c1b8db453ffcc348988');
INSERT INTO blocks VALUES(310025,'a872e560766832cc3b4f7f222228cb6db882ce3c54f6459f62c71d5cd6e90666',310025000,NULL,NULL,'721906ed4cbd1524fafdc8e3ffef27d8b03e0c798bbcbe3eee7bc7f14afe4e81','0e1387e3528daeb461c7a7c044a388627611ec3f7e77b731a18cc25d2bcdc33c','c3de1e38a511e72400f40eea5fda52f3ac94e4db6154bd1eb125a3bcaa0e1d1d');
INSERT INTO blocks VALUES(310026,'6c96350f6f2f05810f19a689de235eff975338587194a36a70dfd0fcd490941a',310026000,NULL,NULL,'27912da2afa797876030dd0e50c31aea462d54c7bfa4f89d2f14fdb7b80db6b0','ff95dd4b219d103075a79335c21fe0a2fe6cf80d5cff723ed548d98eb9bece06','0b3eb741e4444e20a0ba3dd1ea4166e4984089b70fe1c012a96fb093c087919d');
INSERT INTO blocks VALUES(310027,'d7acfac66df393c4482a14c189742c0571b89442eb7f817b34415a560445699e',310027000,NULL,NULL,'cc0734ecfd2bdbd2d04d236b853f60e324feaa9115fae33a8add961c4a5f9436','b19eb988754076bc42bdf165be98822b6f619068468761f01060681a6fa31f3c','e99c9bfe9c7ee3990c7b1a60a64465c076d20399d9154fe69104c987f4c7fd1f');
INSERT INTO blocks VALUES(310028,'02409fcf8fa06dafcb7f11e38593181d9c42cc9d5e2ddc304d098f990bd9530b',310028000,NULL,NULL,'d3f5fbbe85d5a81fef8735c73349f61a43122f4b6f3f7aa61215323a683ce3aa','a040dbcf587e67b24304f01d641385d658a20f6c69e8daadab4c043066cb7536','22bc09d7d0e4889fcc24c7657d63653965d7929d72fbaf5d6ab0194dde077449');
INSERT INTO blocks VALUES(310029,'3c739fa8b40c118d5547ea356ee8d10ee2898871907643ec02e5db9d00f03cc6',310029000,NULL,NULL,'74d08f0d1cad9f7102d0cfe70f50614c7ae7f4844ca6d02390031e1e96c2b418','c0366be7047c86cbf11bea545ab9dcc8ba672fac443ba1c11698e78af2be62e6','30effd338425af99e60693c641a18a23e4a00a17da492ca25cf537832d8fced5');
INSERT INTO blocks VALUES(310030,'d5071cddedf89765ee0fd58f209c1c7d669ba8ea66200a57587da8b189b9e4f5',310030000,NULL,NULL,'753a1a8bb877851ae24dbc33884344f34ee18c6b0d70a4d909231448b943e8cd','b13f1f382c2f7ec18c44985b82f6364450468d66198ce9367ffcc5fed7c42548','43e1f0c225831db99db8e7e5adcbd0a3f55a7a476db1d27a68fa60beab56123b');
INSERT INTO blocks VALUES(310031,'0b02b10f41380fff27c543ea8891ecb845bf7a003ac5c87e15932aff3bfcf689',310031000,NULL,NULL,'f7c62d08a4efc854dea6f47249786d3d00778d97223dd84de1d0fd1eef3e2ee7','aead17b231b1a25e6c2dae9319d75121351448b59321b7e94a399996a1f0d60a','13561a2e9d63c53b7f2276d9d42c6433e05565445e06aaa9f2076e67ff0a4b76');
INSERT INTO blocks VALUES(310032,'66346be81e6ba04544f2ae643b76c2b7b1383f038fc2636e02e49dc7ec144074',310032000,NULL,NULL,'833690f195e85b427b61890640fe8f0cc7419e0f4301b6f4738bab12be06dbb8','bbf0c26b41f9eabe9d56dbefc7fafba191eb68609c29afa89f32d74f16fe8da0','70535c37c5a83e2cbfbb8b17e6266b7819f0ebcc587f7bcde11b690b1fbef05b');
INSERT INTO blocks VALUES(310033,'999c65df9661f73e8c01f1da1afda09ac16788b72834f0ff5ea3d1464afb4707',310033000,NULL,NULL,'a1e118474a6f70b8f700a67b43ee0272c4609d3309603b5be6434ca587eaa704','85bae4397bc02a5d04993b2eac896c4b97f307c439f637c31fb73e642e026a27','103ccb49c3815ea713f46c774442de0aeecf2e0ea91cf8222dd45a03592cc5fd');
INSERT INTO blocks VALUES(310034,'f552edd2e0a648230f3668e72ddf0ddfb1e8ac0f4c190f91b89c1a8c2e357208',310034000,NULL,NULL,'3b6427f61fb59ffd674ed8e0af75687fc4ccf8b462011727d4dc4bdf4c794775','ffe93e6476f3b7322d169b66fb80204c57fe456efefabf56143da5dfb0a72ff7','5a7b061d061cef55fc361b0ec5a8539360cb8738f1728b74aa5503229bd0bd41');
INSERT INTO blocks VALUES(310035,'a13cbb016f3044207a46967a4ba1c87dab411f78c55c1179f2336653c2726ae2',310035000,NULL,NULL,'d065384f739c52a718f656717f88eb2fecc10d8567a93ccf823434c003d28c55','2966efac4dbab31752e12487ff96090e86ab6556bffb08025458fd47eaf40a16','8f19a6761c1b5d2de7dcbf76c92de104a6d678d0e46b0dc0fac1ecce8d8b0048');
INSERT INTO blocks VALUES(310036,'158648a98f1e1bd1875584ce8449eb15a4e91a99a923bbb24c4210135cef0c76',310036000,NULL,NULL,'22cddc8dbfcbaf4b851fa5379c740a96294acc3d772dcf6d684881bef18d7fbf','3f1a5a32dd888668454fd57b199439eef9114cfca04510a769770e9f6089af9e','a962e315f033d428ae988fab35e3ae5fa68b9a32f3638d255794a4b99a2f38d9');
INSERT INTO blocks VALUES(310037,'563acfd6d991ce256d5655de2e9429975c8dceeb221e76d5ec6e9e24a2c27c07',310037000,NULL,NULL,'93172c51a9c4cb5c33937a199a32ad3c13a40a60f4c194a1187e2c59a15c0ccc','b7f8377b6c70c1247eb25f5db88ca68cf84fddf47b133978dc0a28205413e236','6bd2e8f4852253339379f0922cb138281e9ea669ec206e11564f4b3bcd37f687');
INSERT INTO blocks VALUES(310038,'b44b4cad12431c32df27940e18d51f63897c7472b70950d18454edfd640490b2',310038000,NULL,NULL,'7a167a13f7e576c7e066035dbe2a2513659f1386c095a9e63afa494c043b7def','0fc349f0c7d902afc4f3d69e461a3bb7f450c50558135463dd6d17d8aa2ead7c','efcc0fb93bd66a644746c5b4e79400c1112655aff4fd4ca20c27268970ab3cc4');
INSERT INTO blocks VALUES(310039,'5fa1ae9c5e8a599247458987b006ad3a57f686df1f7cc240bf119e911b56c347',310039000,NULL,NULL,'4733d9ada3d4f60bc09f0a6eba3fdcdcd8e8b18adfd38c7bf06372259e2d38f3','38ea4e2c8228e01d00490197d9b8e7d05a2fc9e8527f23947092f3d539072abf','8b020b27e2c20f0196d12b6e9a5325864bb74286dedaa509cfbe0b28aef42125');
INSERT INTO blocks VALUES(310040,'7200ded406675453eadddfbb2d14c2a4526c7dc2b5de14bd48b29243df5e1aa3',310040000,NULL,NULL,'b8021bbe3744e58cedfc3dd99220fce48f4e56a8fe8256d7894dd55c7312a76d','c8594cd2647c52947633dfda0028d85bef7c019f2d66861729b0e0ab00e8459f','179c4937d2f449f2e329c8ecc49bf97f4e2495dc75fa34817bdcdcc15e543c6a');
INSERT INTO blocks VALUES(310041,'5db592ff9ba5fac1e030cf22d6c13b70d330ba397f415340086ee7357143b359',310041000,NULL,NULL,'017b79a5fb34785dd39964a61a5bde69d676f75ee085c27bbc9e3381983c2dab','9bccdbaa23e01eafb1751327f2bb4e8d1c794a5debae6ade11f7d7f608dbb0a8','7c70e2364764c20b3e7083ac85dee8bfc40e7ec93281a86ebbe14ccff1ae8cd6');
INSERT INTO blocks VALUES(310042,'826fd4701ef2824e9559b069517cd3cb990aff6a4690830f78fc845ab77fa3e4',310042000,NULL,NULL,'cf5389c037b6c619025bf95d9718fb5548cd67978c3ebf26f76029873828162e','a488449874213709a55cac0528d05e487b7dde4b9b94e3b1e7655ad2c10aad74','c82400c982ec847996e5a16ae90987ac9d0cc0fe2d34af4c4257b519853d685e');
INSERT INTO blocks VALUES(310043,'2254a12ada208f1dd57bc17547ecaf3c44720323c47bc7d4b1262477cb7f3c51',310043000,NULL,NULL,'df116ea1fcf5f968644dcc97c1149f0ef6061b188fd56c27152543256ce79009','bd4e7dc21e58950d106cdccb541a3d5f7a877f393fb70fd2f0c7482113502d15','c34dcb9ccdfc16d90fe2c79266dafef4d07164343719f2581bfc443ff7faeda8');
INSERT INTO blocks VALUES(310044,'3346d24118d8af0b3c6bcc42f8b85792e7a2e7036ebf6e4c25f4f6723c78e46b',310044000,NULL,NULL,'c12cfaa984bfb34e781ac93848a87cdc0318c45a1cd9f02d31f5c3a4abe8d918','731fad4d817532ca555646a41600ec8a70087f52f7f6f51065755f82a9e0f8a4','c922cd891e234edd6ba88167d96fe100497bd34242e57cd193650e1b2ac277c2');
INSERT INTO blocks VALUES(310045,'7bba0ab243839e91ad1a45a762bf074011f8a9883074d68203c6d1b46fffde98',310045000,NULL,NULL,'999a9ed2673de2db7637e22eb8a1876e0c794e90f09cdd76d1442e56ae12b1c8','17dc78a2aa842bd1062d4123d400d2eabfe0afb5ae20bade2dfd6355fb6afa84','75a17c932d6442d840286650a7c58d957268c82df7968af6073eeeafae0f780f');
INSERT INTO blocks VALUES(310046,'47db6788c38f2d6d712764979e41346b55e78cbb4969e0ef5c4336faf18993a6',310046000,NULL,NULL,'240c9a2f6dc918ed868abfb5de6838d7a17f02263fdda0ccd3c7481c09e155d1','142400f7e1e91067f83e14f1a50387e601fe53a2933245a19cb52f0d8e528145','b241b1f12288edb9f31ef6dc0452594174a918aebb8be6265fce776189114cac');
INSERT INTO blocks VALUES(310047,'a9ccabcc2a098a7d25e4ab8bda7c4e66807eefa42e29890dcd88149a10de7075',310047000,NULL,NULL,'79836105e355e25afd709d15632e2c0d1ab53ab251cd3750ffee9fea4a2605b8','db093621caffa5c3160e98df5ae2c827a37eaabac1fdec10e2af8b11c461a30c','20a96bf56cbed338b7a5ffcbdae5b4f72b44763583b0ac560af8cc426427ef42');
INSERT INTO blocks VALUES(310048,'610bf3935a85b05a98556c55493c6de45bed4d7b3b6c8553a984718765796309',310048000,NULL,NULL,'6bf0789392e97311c4283d9f748b37effe7b0d1678076e30ce5725eff345a8c5','97600e87f7c00f01e2c89cd456b59cad7e7bc151ad62e7d4a1fb5bb9b1a76861','28612cafc14e3d9a70864377e4c81635ee130c883b54d27a846935bba078669f');
INSERT INTO blocks VALUES(310049,'4ad2761923ad49ad2b283b640f1832522a2a5d6964486b21591b71df6b33be3c',310049000,NULL,NULL,'1842c46a03800f5e191cb8d641aead6bc80e6d25c2ec826f3a5df426059cc1cb','8029b34151c52feec8e266b376c11ad9186e633b27ea29f2978a5071228cbf4e','904127f00cef3a1dacc838aa14c5d2a04eb0583376404691335a8f63e9623b19');
INSERT INTO blocks VALUES(310050,'8cfeb60a14a4cec6e9be13d699694d49007d82a31065a17890383e262071e348',310050000,NULL,NULL,'d424b02109320491b2d32388869d6468ab1fca26d4bf72374cfef729efad866d','c78db222eeffa8b2bec2de94bd1b4a80f81ba0707a5fb2bed5addce08baf9b93','769a60423ca83c440fcaa79186bf77ea9d4d32ad36f4e9691783a0919e2ba595');
INSERT INTO blocks VALUES(310051,'b53c90385dd808306601350920c6af4beb717518493fd23b5c730eea078f33e6',310051000,NULL,NULL,'d1db4181403136b41168ab7786831f2fadfc418a05b7477246ab097bab531859','5995c7b4b02c901d98ce214f4eec449b029c5730fc3ebcb057330e3152a89004','9ff4d1de98ff2e895c1177402d32572556ee2952b68f5388aec465994f03fbe7');
INSERT INTO blocks VALUES(310052,'0acdacf4e4b6fca756479cb055191b367b1fa433aa558956f5f08fa5b7b394e2',310052000,NULL,NULL,'97fdb6b2c8e636d23109a67af55ab4bb30955a84073274de3fdc788074dc1b6b','e1dbbcd2c45044d5f593eb90b2b55c1d54fce8fcf0dc0e508816981fdb558313','ac8b263ddff3770231fab39c9185367f7e40e66812f571e2efd5f0d67b3e0655');
INSERT INTO blocks VALUES(310053,'68348f01b6dc49b2cb30fe92ac43e527aa90d859093d3bf7cd695c64d2ef744f',310053000,NULL,NULL,'0506be4f04a22058504406210af3f1475dbf6d6834c1c1b7f6ac0fe013b47363','d99cb0997783d49a876a55e656f405b51d40357e52fdfcb8f9b359c4dceda504','21e32fafd1eab4a3051884ef6237a8e3b1c7fc06c19498d73957b3f394ab3556');
INSERT INTO blocks VALUES(310054,'a8b5f253df293037e49b998675620d5477445c51d5ec66596e023282bb9cd305',310054000,NULL,NULL,'3dc7894c1368c9ef5d32a95fdc292e7de8237b73b61365a25b9d0da95eedc2e6','9e2acdf2233b24160db59b528b6433a1c0c7d24a1ed84d591102b7f566505fec','b8a85b8f37991be38e0c8d00608dc0cdfcf36ed07e2415610f5a8dc7c2b4a61f');
INSERT INTO blocks VALUES(310055,'4b069152e2dc82e96ed8a3c3547c162e8c3aceeb2a4ac07972f8321a535b9356',310055000,NULL,NULL,'a9ef2c8bf3a88c326d2bdd722c3d82ed4f4c10b65620b136d4b893ed93174795','994dd9266e2510bcb915fbea209b830ff7cbb8665ac192c9afc5610e61e8c4c8','a6f121226606dd601ef90e3e4c58ff7e69be6a95d45e714e26bfbdba237a2269');
INSERT INTO blocks VALUES(310056,'7603eaed418971b745256742f9d2ba70b2c2b2f69f61de6cc70e61ce0336f9d3',310056000,NULL,NULL,'13b76edecb04a9733107d5c21420ee20424fd463dcde2ea98424ad99ed3383f0','cf5c7642bd1ebbc1eb8df2b5d42b302416c789a96161965ac86d16118045d8a1','c4e177ca6624df3befaf540b169cb72585ba180346b538e37ebaaf99796d85ed');
INSERT INTO blocks VALUES(310057,'4a5fdc84f2d66ecb6ee3e3646aad20751ce8694e64e348d3c8aab09d33a3e411',310057000,NULL,NULL,'41c8a47d7bc4e73aa2f09685acb9fac052c5c55764ec3a8250abbbcde40dbe90','deb7eb6dd6b277d5b9cd01c16d734df5b5f3bf0d76b2cc10269bf857c5f22f54','c190774e567aef74ae50b0ad6426af0368ef49b79ddfad0cf80376540ed0b4b9');
INSERT INTO blocks VALUES(310058,'a6eef3089896f0cae0bfe9423392e45c48f4efe4310b14d8cfbdb1fea613635f',310058000,NULL,NULL,'0b8ec211d258206ab8c318c079d9deb33d444a7086d5a05aaba97abc0be137df','174cff6a63610cc478563e6fd70ac268feb81836a83374705598b89d5abe4f8b','b729e6cf19d621d3b41290e1e32fae00b260a866a68d341de6971617eacdb137');
INSERT INTO blocks VALUES(310059,'ab505de874c43f97c90be1c26a769e6c5cb140405c993b4a6cc7afc795f156a9',310059000,NULL,NULL,'f5c2686408577854893d11b02f52d8ea917e90777dddf67c98aabb36a3339b6f','96441b048082539f9c6004516520d16ede601699b770973139b6ea353154edc4','321942f7714865c69f0ca44be8681d0c4e8de34977ff8ca3e7e91382dc9d695f');
INSERT INTO blocks VALUES(310060,'974ad5fbef621e0a38eab811608dc9afaf10c8ecc85fed913075ba1a145e889b',310060000,NULL,NULL,'b80d446905550494f56f4f8240b501d593b0d0e63b5d98a09e180b1a0a68e3b1','c8381c0ed18bb351691ec09bc226e1f4d4a9166045754b03042c4650e395499b','cc115b2001bf2c503796e308eb28f3d532f293827bcaa37f3a53180934955173');
INSERT INTO blocks VALUES(310061,'35d267d21ad386e7b7632292af1c422b0310dde7ca49a82f9577525a29c138cf',310061000,NULL,NULL,'41b30d23becc727151698b29a1bb733e45ae5086683c5256d073a6f817baaf49','5bd22692d801b1f8df529ef107f4d059a86435eaa740ae11b84fe0b6aef42013','42b80bac356cfa5a4a78c86e10886ac0ffc64d7571ac4d99a5bf55a05bd7da87');
INSERT INTO blocks VALUES(310062,'b31a0054145319ef9de8c1cb19df5bcf4dc8a1ece20053aa494e5d3a00a2852f',310062000,NULL,NULL,'f873f47e89715e965c98e92616339f8ff4200f6b8ef5cf747e8de2d101cbde02','4f0893ee6ad4894b6b5c944e50db86b0fd6f99479d49dda1a003021df824c0ad','fb6e0211d2ce1c67c8e628c83d9b271cd61481b887debe2c784a656255ae934d');
INSERT INTO blocks VALUES(310063,'0cbcbcd5b7f2dc288e3a34eab3d4212463a5a56e886804fb4f9f1cf929eadebe',310063000,NULL,NULL,'14ce21ebfe6a00eccd7bf1aac2d5cf122441d2ebe8c0f5fd6dd14a95b5a209b3','7f796e7ace7aa40b8a1f04a46d25513282b618c55319b4f68e1d9d360f6d7950','3da24f496b7f65f0694ed628b4aa4899d7d4a473f32b90709b59bbef9847d487');
INSERT INTO blocks VALUES(310064,'e2db8065a195e85cde9ddb868a17d39893a60fb2b1255aa5f0c88729de7cbf30',310064000,NULL,NULL,'adb05bac5e7f1e6a1679d5c51f252dc877ebd99c2b73a56df69a9c848cef98a7','3b94fe42770e835c0d63b7b2f35cd81a15d04a40de83ef48f930c510c8e32cc4','d7b2a4e35fb980aca3c1aaee0211f2db8dac1b4aeb60bcc0c7a0ab9a50b3ee9b');
INSERT INTO blocks VALUES(310065,'8a7bc7a77c831ac4fd11b8a9d22d1b6a0661b07cef05c2e600c7fb683b861d2a',310065000,NULL,NULL,'9065476b6b2cfb122888e036cea71d36f3d5f7d6c72451c63d770b40a4560fac','e12a2810d33e461cd2ac027cd47d36c3c5adadb067bac6d9f644bfbfe9da5471','3b18281d497f98f9444f1e3bbc31dd25417949a9384b5ca2b732aff15b0399a3');
INSERT INTO blocks VALUES(310066,'b6959be51eb084747d301f7ccaf9e75f2292c9404633b1532e3692659939430d',310066000,NULL,NULL,'7d5d369827ec0cd44743ed9a519d45003789ff8dc2e511191d2726e1482f58d2','b08ed28a4999340516482d4ccc42b088c8b4c3f406662e0e1c743afbf1e7d931','5a18517a33dd468eaf17e6a046f71bc69436c1830e6b45455943f208a515f18c');
INSERT INTO blocks VALUES(310067,'8b08eae98d7193c9c01863fac6effb9162bda010daeacf9e0347112f233b8577',310067000,NULL,NULL,'301b22a9338d5dd39bbebf6bf518ac53bbb8e1cf7469322484cbcee2fee666ef','09f382e013bee5ae289a8b08227f9bb19c670890b0d1e15f112a5d5885821534','8c9a3e43e9399a58965b7b94945711c2b3ae2af0eb5111b286dea7bbb0c51813');
INSERT INTO blocks VALUES(310068,'9280e7297ef6313341bc81787a36acfc9af58f83a415afff5e3154f126cf52b5',310068000,NULL,NULL,'fc281736e1dfe5a89a9a3dd098565c645904a4ad1626dd70ac8e9bc447dfb8b8','81f640de7806f418258e2978cfced2ab673201ed1a678b0fa22a20930054cebb','64c6b1f326287b1a7e9e0522403fa165a61ba305d2f19b5f93df3d496ee02c18');
INSERT INTO blocks VALUES(310069,'486351f0655bf594ffaab1980cff17353b640b63e9c27239109addece189a6f7',310069000,NULL,NULL,'b0249a0dfd008a4554adc24085d3c5f44278403cbccb44ba27ee354b23c5627b','9a7f5b756c5d73edb524d422a8a5d227c5e9fab6f0fd2e6646761ed0007d062d','de328dc579528887205aac41cf2ad254aaf488ec745b75ded33a733ee5db5fa2');
INSERT INTO blocks VALUES(310070,'8739e99f4dee8bebf1332f37f49a125348b40b93b74fe35579dd52bfba4fa7e5',310070000,NULL,NULL,'d34051879c8db679ac5c49e50edf2085d0ce88dfc1adb971e7b097c0177854c2','e56021609f98e96e1199ff36c4e08a339b6fe1b69ed5081a2c9bc998e9ce42ea','40deefcb408a03705f270533a36b529e37de3cc0f4e633523e7b49e77a7a5133');
INSERT INTO blocks VALUES(310071,'7a099aa1bba0ead577f1e44f35263a1f115ed6a868c98d4dd71609072ae7f80b',310071000,NULL,NULL,'0186c5312af19576cc628a85014ce7c33892dc23b5352c8ff5a0f230adfe263b','6de40bf32dceab202303159d267daad0919b8b7f71cd3da03ee1169337bc58a1','06465e1fd6c78e699791f83e8caa24e246a796529af05eba01c208c3ba6ecf16');
INSERT INTO blocks VALUES(310072,'7b17ecedc07552551b8129e068ae67cb176ca766ea3f6df74b597a94e3a7fc8a',310072000,NULL,NULL,'5376530512d61c3967f21cf01418d317ed072976119b8583fefaf3991b93d8b2','c9b0ee70c5750b8c1e4c31c3dfc00823b0a666459ed1bd09137766f92a5069fd','56bb72efd000a77075e332b48c73a5e1bc652bbba236bc3491de796610027d39');
INSERT INTO blocks VALUES(310073,'ee0fe3cc9b3a48a2746b6090b63b442b97ea6055d48edcf4b2288396764c6943',310073000,NULL,NULL,'d15fe704fe5de58e9203ff5ded50218a1a01609b65a1a259aec510b8b9e6d690','6b75a95806c7c950f5fae76007502a48628b17cfc6923455ea2d8be68c5117c5','88af95e09c22a541877512072a2f50c035e93e70ab519aa6116537f178eb760a');
INSERT INTO blocks VALUES(310074,'ceab38dfde01f711a187601731ad575d67cfe0b7dbc61dcd4f15baaef72089fb',310074000,NULL,NULL,'61015667044d0dddac3bdb16db67faa6ebcb71758101bfad898fca8ed183e7c3','592e7cd1ccf872ec28bef462d3ebfff58dbaa822b81267f5b1428e024a8b9b39','f2d29f98bd1ee2be54fbbd57916bf2c201175d6f41ccedcf6c28ec156a65571a');
INSERT INTO blocks VALUES(310075,'ef547198c6e36d829f117cfd7077ccde45158e3c545152225fa24dba7a26847b',310075000,NULL,NULL,'5dd06f32075c46b6e573d73f12c1c31cf82cac5d1588bbdf302b8fe95c4b948b','76ee6ef068bc43af7d896e8ad4c0ea3bbd1918d1587b08420e4fb26f31b7c89a','a31421b0548693f49e8bf0776aa88e62277be3fd2654391418af65346e906e51');
INSERT INTO blocks VALUES(310076,'3b0499c2e8e8f0252c7288d4ecf66efc426ca37aad3524424d14c8bc6f8b0d92',310076000,NULL,NULL,'8e1782c2f35a07fcc4c57b34b2226b70cc4c7af2761386f38fc8fd74d53d5e60','652f8bc4d1ca249665b646cfac80b3705b0ba92dbee62a76d11723bf42e41a68','5473f0fed6ac7fe03a1489b8e202de2e46ec8335e80c71f0482362ac2477a744');
INSERT INTO blocks VALUES(310077,'d2adeefa9024ab3ff2822bc36acf19b6c647cea118cf15b86c6bc00c3322e7dd',310077000,NULL,NULL,'6469ff80c3890d274817d30602f33d5d4b0a7c0a9e3b85100d21d7b38d894efb','e59092837addae646f9ebafa2cd744edba3c30a88158aa1e94584cca42ee6dfc','ae6d83fa30c7e2ea23e9ca305979595565bca6916b5c67a52f2893b414c3deff');
INSERT INTO blocks VALUES(310078,'f6c17115ef0efe489c562bcda4615892b4d4b39db0c9791fe193d4922bd82cd6',310078000,NULL,NULL,'3ca73c2bf37c694281938a0599335633dccf0284a027f5f3b8e17a9e68cbcdf0','c097c7aef159b6cd3d6e62c32fd290e779d2698a21cdbd896dc3b9eaa3b2a786','629d1a90d98b15644bed237a33d4dd6f87d8a8b1eff639d1b4fd83e60e514518');
INSERT INTO blocks VALUES(310079,'f2fbd2074d804e631db44cb0fb2e1db3fdc367e439c21ffc40d73104c4d7069c',310079000,NULL,NULL,'ae4a36e1ce7d5e11f059301684573cddce85b70ba69188a116e0611ceba5c140','57140cf9c00cdb196216ce9cf2e71a8d8db43091df6a13f47aa056e4274a0cc3','a009db5ca9e260fb71c2fcefbf60326297f195e6421a1d05415fd8e05e1fa66a');
INSERT INTO blocks VALUES(310080,'42943b914d9c367000a78b78a544cc4b84b1df838aadde33fe730964a89a3a6c',310080000,NULL,NULL,'c2c0b96c64f1ed555c8553da976e0fcc3a5ef403819ceac49cf22b476281ced1','61e80ca9d3eb4b297092caf43f7f691a4dbb93a70599fd75f3969c1b56621d07','65c56d4f1ee81f3129e98965c1b837cfeb12c0c3650672f101c553ba96a64b81');
INSERT INTO blocks VALUES(310081,'6554f9d307976249e7b7e260e08046b3b55d318f8b6af627fed5be3063f123c4',310081000,NULL,NULL,'88d1b09f8141b90b44740e4618422298f8a64f2b3d11230c6b04084ef8d11b2c','a42bd02208226d506ada1c5b7def779a4eef87fc4e13c50ab44fb480093b4aa2','e8c96442ae3d5b84825671210b6be79577adc68561e137f1d53086fc543965b7');
INSERT INTO blocks VALUES(310082,'4f1ef91b1dcd575f8ac2e66a67715500cbca154bd6f3b8148bb7015a6aa6c644',310082000,NULL,NULL,'dab22ae7a9216033777136cbbac87a3597cf6478a2fd008260caab3cad0cde3f','7593e878d24834694407503a26e3681955131db1f86cf10a27196af39f07b724','ba7fd814bdfc5fffd076ec4e9568ae3d7c874259b0a8a37ea3bc98a0f1156167');
INSERT INTO blocks VALUES(310083,'9b1f6fd6ff9b0dc4e37603cfb0625f49067c775b99e12492afd85392d3c8d850',310083000,NULL,NULL,'a185e60dc97d19a211b0dfaa3f3da154956499b4af146751bf1d776fc68c15b8','f02827e1845149b8150e44f4defe5f2f88bf7c2ae803b478b1fe4fde57f056a9','44370fc9d877e7365106d4d0b5da542b6bad08446870a004ac79e5cb04a319ce');
INSERT INTO blocks VALUES(310084,'1e0972523e80306441b9f4157f171716199f1428db2e818a7f7817ccdc8859e3',310084000,NULL,NULL,'622c574321be176c535fde918f319e10cfacaab383978be51406334303d14a8d','c97f6cd5be801ab5480c4d7802fcef96b8415e8cdd60af57978b53096622d62a','e22bc12575555c0e70c8d4eaab173d7d4e6ac7e9f9e2175bb4a839ef6a86b296');
INSERT INTO blocks VALUES(310085,'c5b6e9581831e3bc5848cd7630c499bca26d9ece5156d36579bdb72d54817e34',310085000,NULL,NULL,'5556084b92f51175d4de4097fcd820a3c367c2f0630d3a20081296e892462d84','720d1cec1d5aa27971a701b42a86255c101f86c12cb44bcc51ea079b6b5661ac','004ca2e72c1c85ed0c4522325287b83def831eee9432804164d0c2691cd1ddcf');
INSERT INTO blocks VALUES(310086,'080c1dc55a4ecf4824cf9840602498cfc35b5f84099f50b71b45cb63834c7a78',310086000,NULL,NULL,'fc9dd8ef92fc7d47b187a75bd16e9698d61fa9ce6b4da7bba75982f59b0fbbc5','7df5d704dc6103564f033d594603393d6488aa0c42fd15de04e6b58ecf438871','5ccca6b11377f70b03db09b1534d9118e63e67a3997999ec5220336c7099c731');
INSERT INTO blocks VALUES(310087,'4ec8cb1c38b22904e8087a034a6406b896eff4dd28e7620601c6bddf82e2738c',310087000,NULL,NULL,'21f7329fa27373fba176043db9081b0d9f95f75421e5adce87177a3edffcedc0','bd5ebea30fb214174250a1826d071710da6d437f1b28f06af22d4ee849a39cd1','a0e50830fe4baec5efaf8cf2195e272b2655b248c39497ee0148d5f0a87e2667');
INSERT INTO blocks VALUES(310088,'e945c815c433cbddd0bf8e66c5c23b51072483492acda98f5c2c201020a8c5b3',310088000,NULL,NULL,'19164a10a0602df57d1add2e3a31ad4eef9d3ef9e53e70174b44aa91de2d6296','66361e50b33885e6888d055de3b4a3616bec123bb059e4c8d80c13b6df8d40b5','7ba059e436fe62e42b722bfde794d5e4fa052cdd6326968f888bda7135aa5ba3');
INSERT INTO blocks VALUES(310089,'0382437f895ef3e7e38bf025fd4f606fd44d4bbd6aea71dbdc4ed11a7cd46f33',310089000,NULL,NULL,'87f1c713c5f2cd84fab28b996008900f86bf9eaad25ceedac1507348a949be7c','5388bec940f87804ad768f2b98bb493f0b5a47d4e7d092f925be36a26c20dfa2','807612f01cc6a4a70ce335172e46149f6d1cfb3d2e1651188991cb70a15e60d4');
INSERT INTO blocks VALUES(310090,'b756db71dc037b5a4582de354a3347371267d31ebda453e152f0a13bb2fae969',310090000,NULL,NULL,'75264a6a628d669a60b4a8ca7e24b6b5ef1ad2c74d955b8325959f906c3bc337','046d82688b0c082f7f1acfdb01a127c787ead8aebd999035ecba5e2934c97a0a','c424b34a39913049454ab9cb8f176674b731f68a6d4d7976049819dd9084e5ed');
INSERT INTO blocks VALUES(310091,'734a9aa485f36399d5efb74f3b9c47f8b5f6fd68c9967f134b14cfe7e2d7583c',310091000,NULL,NULL,'27914e38b3ca9d8444275e5c6d24b5cfe0b4093f7c645d5c1fc3c39e0d3a3c60','5eb204d19c88d23761529f388f831799a90d3557b4034463d634d363776e4bc7','b37fabbc0b5dd9d2f32661c98817bff3aba271b14480a8181b30e8a82eeeca7c');
INSERT INTO blocks VALUES(310092,'56386beb65f9228740d4ad43a1c575645f6daf59e0dd9f22551c59215b5e8c3d',310092000,NULL,NULL,'eca83e762899ace4d990b8acb23183263df5f92be10b63aecab3518b340b975d','ba3445096fa5d16c7828eaa6a800b8d565f559ff078412b57dcdcd99b03832ea','ed5f0d7264071786f3b6ec28e04b9fff9d67696283e7efb124a661fb0f89b75c');
INSERT INTO blocks VALUES(310093,'a74a2425f2f4be24bb5f715173e6756649e1cbf1b064aeb1ef60e0b94b418ddc',310093000,NULL,NULL,'3544fab97fe90a35b1f52ba955f88a8149d90329986df38d97e12992201bb187','d769983a2dbb1f492adf6ca8f2164ac611ef7564bec5308afd544cd15cdd20ef','1f1115c3c61869de6049cc031488846b804a200bc2b2c69133cf58a971a90da9');
INSERT INTO blocks VALUES(310094,'2a8f976f20c4e89ff01071915ac96ee35192d54df3a246bf61fd4a0cccfb5b23',310094000,NULL,NULL,'df1e6d8f1be344f78c0b58baf7260c2abdbed3175adc45a122947815c08fcc16','2ed9ce48e807b574cce435e723523c90e687088203013ec31dd1b74ff35be645','17c44e4fddabb50ec608fcac57afbd92a98cf1688aa27114bf2f1a04050e867e');
INSERT INTO blocks VALUES(310095,'bed0fa40c9981223fb40b3be8124ca619edc9dd34d0c907369477ea92e5d2cd2',310095000,NULL,NULL,'8b9febcfe1a9447f6a820c060f503dfe6e5c02738df4d9d63b007fe03847a6c7','a9c168069960563a56b6a6259390b1a18f97d79d0b051ba41b2d4d29b11b917c','a922b3058ff03551deaa28be53dea1420b6bdd21509d436bf11cd921f8f6b398');
INSERT INTO blocks VALUES(310096,'306aeec3db435fabffdf88c2f26ee83caa4c2426375a33daa2be041dbd27ea2f',310096000,NULL,NULL,'b927091b4cf42f8537058a9adbec3814b574c1e1ccd242fe44c5f3671a191304','92b86b186be4d5c765b8e2f8a3acdf3fdbff68ae2ac0557338972944d658f73f','0601ef4009aecd36a2cc6504af35eeb222fa33dc60a200558cec5499dce5b5ff');
INSERT INTO blocks VALUES(310097,'13e8e16e67c7cdcc80d477491e554b43744f90e8e1a9728439a11fab42cefadf',310097000,NULL,NULL,'649d094cfc74f90e06bb4514276aaf3b0a0ed45f56397a2f774cae9602d02e6f','a8a899800d8b982bda05d909a8571c595e464d5053271f64fda02f2b13b56b52','25753ae7b48c4fcd705c9741ad8e1580a5623225c8afca00d979ea62323d7f25');
INSERT INTO blocks VALUES(310098,'ca5bca4b5ec4fa6183e05176abe921cff884c4e20910fab55b603cef48dc3bca',310098000,NULL,NULL,'c9a9dec300afba2cc3f171f76ff4c07cbeb7a41a86a3f498f712e066a8acbd17','7c777fb0f56a471cfe49212e2149f01a11fc17b5ebc66cc48acd4607aec78eaf','4a403e0f6e1a624947e027f50d14c50ebf667a2cb3eb334ccdf24ac56af41d48');
INSERT INTO blocks VALUES(310099,'3c4c2279cd7de0add5ec469648a845875495a7d54ebfb5b012dcc5a197b7992a',310099000,NULL,NULL,'3c7434887f9373b5370664180ba640fa63c2eb5b85569875105e4f4db67d8c02','44b0a8887e4dd961f99799e008a1ca1eb9047ef4131b15615aa8182b5dadb104','d906f5aa362014171f7550308b4219532b9cfc7518a6f7f53fdf4afd6a388065');
INSERT INTO blocks VALUES(310100,'96925c05b3c7c80c716f5bef68d161c71d044252c766ca0e3f17f255764242cb',310100000,NULL,NULL,'7e6a09386c3d8552a0dcc25b75143876a3046ebac0ff9cb09d6224ea7e2f3df9','e70f06991c1862c207b68471ff115f1da8951fdb06eccb304117cc3ad6b762ae','047d6d3bdca2a1c4521a572e65086eda0fda1bc992618a3cc5d8d80300694530');
INSERT INTO blocks VALUES(310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,NULL,NULL,'6903c0c5941f334f1374aa731e389b010043fc5940d4e9ae8b94480fb4fca030','395933b37ccb9db46f89226efc2e2dd4dc30566bc27a96f3753a6ba54c92e704','b7883f02c559ea4b1443c0ba955ef431567fa997f0fb06b44ec96bbf0cfd869d');
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
INSERT INTO broadcasts VALUES(12,'c045731917392e0eb1d390eb1ffadea08d2dfa1653a8b967aff9df79c1bfc4f1',310011,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1388000000,100.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(19,'16db4d63be8839383e28cdab7edf52c1264340fb5db51ae5341801983ff48861',310018,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1388000050,99.86166,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(20,'f0409d985023c1fcb9cd0df5530b65b71c1ebff78f36020f157fadd109f4c52f',310019,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1388000101,100.343,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(21,'4e33149428c2fe189c237ed80abd77262c4f2df3fdfad7e275631f2ef51b0a7e',310020,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1388000201,2.0,5000000,'Unit Test',0,'valid');
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
INSERT INTO btcpays VALUES(5,'957a0550bc7ce9cc16d5ff5426bdb111ddb1261739a39bcb93334f15f859a495',310004,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',50000000,'12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8_792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c','valid');
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
INSERT INTO burns VALUES(1,'15b35d5497f454c43576f21a1b61d99bde25dfc5aae1a4796dcf55e739d6a399',310000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',62000000,93000000000,'valid');
INSERT INTO burns VALUES(23,'181709b341ec136f90975fdaa362c767ebd789e72f16d4e17348ab2985c1bd01',310022,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',38000000,56999887262,'valid');
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
INSERT INTO credits VALUES(310000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',93000000000,'burn','15b35d5497f454c43576f21a1b61d99bde25dfc5aae1a4796dcf55e739d6a399');
INSERT INTO credits VALUES(310001,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',50000000,'send','52e4c56494983092daf8cef2850b69a66e0c0cdbef3ec3ba92d42983bda70505');
INSERT INTO credits VALUES(310004,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',100000000,'btcpay','957a0550bc7ce9cc16d5ff5426bdb111ddb1261739a39bcb93334f15f859a495');
INSERT INTO credits VALUES(310005,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',1000000000,'issuance','3542e3a185495b9cafae33747e3840236f65c94e360e0725b384821af67a2ecf');
INSERT INTO credits VALUES(310006,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC',100000,'issuance','875294dc37e08c5c392c297179dc89aabe49e0f3d8484c62687e78a44477f452');
INSERT INTO credits VALUES(310007,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBB',4000000,'send','209ca33a9b698c14c16090296e84e1556ed194a32b4ffb537f5e08327867ec48');
INSERT INTO credits VALUES(310008,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',526,'send','bad7a9312cc465ddd3083b0158963134db90dbf61d999841766f283f348ddf6a');
INSERT INTO credits VALUES(310009,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',24,'dividend','cb9991934562490fc66980601a2afbf34d7b1d772079c1e56a9094488e454e96');
INSERT INTO credits VALUES(310010,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',420800,'dividend','5012de31b4fc38e61ffc4e4423e39190a5a294c2ab9d137b84cebf7ff3e76e17');
INSERT INTO credits VALUES(310013,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',4250000,'filled','19e4f4787538366983026745d72265d95c32180e741934be0c0c9a9392640de8');
INSERT INTO credits VALUES(310014,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',5000000,'cancel order','792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c');
INSERT INTO credits VALUES(310015,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',0,'filled','78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3');
INSERT INTO credits VALUES(310015,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',0,'filled','78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3');
INSERT INTO credits VALUES(310017,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',0,'filled','b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679');
INSERT INTO credits VALUES(310017,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',0,'filled','b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679');
INSERT INTO credits VALUES(310018,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',59137500,'bet settled: liquidated for bear','16db4d63be8839383e28cdab7edf52c1264340fb5db51ae5341801983ff48861');
INSERT INTO credits VALUES(310018,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',3112500,'feed fee','16db4d63be8839383e28cdab7edf52c1264340fb5db51ae5341801983ff48861');
INSERT INTO credits VALUES(310019,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',159300000,'bet settled','f0409d985023c1fcb9cd0df5530b65b71c1ebff78f36020f157fadd109f4c52f');
INSERT INTO credits VALUES(310019,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',315700000,'bet settled','f0409d985023c1fcb9cd0df5530b65b71c1ebff78f36020f157fadd109f4c52f');
INSERT INTO credits VALUES(310019,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',25000000,'feed fee','f0409d985023c1fcb9cd0df5530b65b71c1ebff78f36020f157fadd109f4c52f');
INSERT INTO credits VALUES(310020,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',1330000000,'bet settled: for notequal','4e33149428c2fe189c237ed80abd77262c4f2df3fdfad7e275631f2ef51b0a7e');
INSERT INTO credits VALUES(310020,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',70000000,'feed fee','4e33149428c2fe189c237ed80abd77262c4f2df3fdfad7e275631f2ef51b0a7e');
INSERT INTO credits VALUES(310022,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',56999887262,'burn','181709b341ec136f90975fdaa362c767ebd789e72f16d4e17348ab2985c1bd01');
INSERT INTO credits VALUES(310023,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',8500000,'recredit wager remaining','86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243');
INSERT INTO credits VALUES(310023,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',10000,'send','057f27f2340282c1a82250563b67a37497eb8e07c2f5d0905422238158488488');
INSERT INTO credits VALUES(310032,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',50000000,'cancel order','cc068ab4b7834ebc0a7742e86691d4f2a82c13baef4ca13662c72d6b51e48d64');
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
INSERT INTO debits VALUES(310001,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',50000000,'send','52e4c56494983092daf8cef2850b69a66e0c0cdbef3ec3ba92d42983bda70505');
INSERT INTO debits VALUES(310003,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',105000000,'open order','792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c');
INSERT INTO debits VALUES(310005,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',50000000,'issuance fee','3542e3a185495b9cafae33747e3840236f65c94e360e0725b384821af67a2ecf');
INSERT INTO debits VALUES(310006,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',50000000,'issuance fee','875294dc37e08c5c392c297179dc89aabe49e0f3d8484c62687e78a44477f452');
INSERT INTO debits VALUES(310007,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',4000000,'send','209ca33a9b698c14c16090296e84e1556ed194a32b4ffb537f5e08327867ec48');
INSERT INTO debits VALUES(310008,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC',526,'send','bad7a9312cc465ddd3083b0158963134db90dbf61d999841766f283f348ddf6a');
INSERT INTO debits VALUES(310009,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',24,'dividend','cb9991934562490fc66980601a2afbf34d7b1d772079c1e56a9094488e454e96');
INSERT INTO debits VALUES(310009,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',20000,'dividend fee','cb9991934562490fc66980601a2afbf34d7b1d772079c1e56a9094488e454e96');
INSERT INTO debits VALUES(310010,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',420800,'dividend','5012de31b4fc38e61ffc4e4423e39190a5a294c2ab9d137b84cebf7ff3e76e17');
INSERT INTO debits VALUES(310010,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',20000,'dividend fee','5012de31b4fc38e61ffc4e4423e39190a5a294c2ab9d137b84cebf7ff3e76e17');
INSERT INTO debits VALUES(310012,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',50000000,'bet','86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243');
INSERT INTO debits VALUES(310013,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',25000000,'bet','19e4f4787538366983026745d72265d95c32180e741934be0c0c9a9392640de8');
INSERT INTO debits VALUES(310014,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',150000000,'bet','cb395180f84879bfa8aadbfc3b0a1f9ceb43805f930567451334aad30bab00a6');
INSERT INTO debits VALUES(310015,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',350000000,'bet','78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3');
INSERT INTO debits VALUES(310016,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',750000000,'bet','170565b2aa082c64e3cf8f0ccf2bf675372a4f068f698b663eddf916d432e52b');
INSERT INTO debits VALUES(310017,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',650000000,'bet','b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679');
INSERT INTO debits VALUES(310021,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',50000000,'open order','cc068ab4b7834ebc0a7742e86691d4f2a82c13baef4ca13662c72d6b51e48d64');
INSERT INTO debits VALUES(310023,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC',10000,'send','057f27f2340282c1a82250563b67a37497eb8e07c2f5d0905422238158488488');
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
INSERT INTO dividends VALUES(10,'cb9991934562490fc66980601a2afbf34d7b1d772079c1e56a9094488e454e96',310009,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB','XCP',600,20000,'valid');
INSERT INTO dividends VALUES(11,'5012de31b4fc38e61ffc4e4423e39190a5a294c2ab9d137b84cebf7ff3e76e17',310010,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC','XCP',800,20000,'valid');
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
CREATE TABLE issuances(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
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
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
INSERT INTO issuances VALUES(6,'3542e3a185495b9cafae33747e3840236f65c94e360e0725b384821af67a2ecf',310005,'BBBB',1000000000,1,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,0,0,0.0,'',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(7,'875294dc37e08c5c392c297179dc89aabe49e0f3d8484c62687e78a44477f452',310006,'BBBC',100000,0,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,0,0,0.0,'foobar',50000000,0,'valid',NULL);
-- Triggers and indices on  issuances
CREATE TRIGGER _issuances_delete BEFORE DELETE ON issuances BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO issuances(rowid,tx_index,tx_hash,block_index,asset,quantity,divisible,source,issuer,transfer,callable,call_date,call_price,description,fee_paid,locked,status,asset_longname) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.asset)||','||quote(old.quantity)||','||quote(old.divisible)||','||quote(old.source)||','||quote(old.issuer)||','||quote(old.transfer)||','||quote(old.callable)||','||quote(old.call_date)||','||quote(old.call_price)||','||quote(old.description)||','||quote(old.fee_paid)||','||quote(old.locked)||','||quote(old.status)||','||quote(old.asset_longname)||')');
                            END;
CREATE TRIGGER _issuances_insert AFTER INSERT ON issuances BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM issuances WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _issuances_update AFTER UPDATE ON issuances BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE issuances SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',asset='||quote(old.asset)||',quantity='||quote(old.quantity)||',divisible='||quote(old.divisible)||',source='||quote(old.source)||',issuer='||quote(old.issuer)||',transfer='||quote(old.transfer)||',callable='||quote(old.callable)||',call_date='||quote(old.call_date)||',call_price='||quote(old.call_price)||',description='||quote(old.description)||',fee_paid='||quote(old.fee_paid)||',locked='||quote(old.locked)||',status='||quote(old.status)||',asset_longname='||quote(old.asset_longname)||' WHERE rowid='||old.rowid);
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
INSERT INTO messages VALUES(0,310000,'insert','credits','{"action": "burn", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310000, "event": "15b35d5497f454c43576f21a1b61d99bde25dfc5aae1a4796dcf55e739d6a399", "quantity": 93000000000}',0);
INSERT INTO messages VALUES(1,310000,'insert','burns','{"block_index": 310000, "burned": 62000000, "earned": 93000000000, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "15b35d5497f454c43576f21a1b61d99bde25dfc5aae1a4796dcf55e739d6a399", "tx_index": 1}',0);
INSERT INTO messages VALUES(2,310001,'insert','debits','{"action": "send", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310001, "event": "52e4c56494983092daf8cef2850b69a66e0c0cdbef3ec3ba92d42983bda70505", "quantity": 50000000}',0);
INSERT INTO messages VALUES(3,310001,'insert','credits','{"action": "send", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "asset": "XCP", "block_index": 310001, "event": "52e4c56494983092daf8cef2850b69a66e0c0cdbef3ec3ba92d42983bda70505", "quantity": 50000000}',0);
INSERT INTO messages VALUES(4,310001,'insert','sends','{"asset": "XCP", "block_index": 310001, "destination": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "quantity": 50000000, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "52e4c56494983092daf8cef2850b69a66e0c0cdbef3ec3ba92d42983bda70505", "tx_index": 2}',0);
INSERT INTO messages VALUES(5,310002,'insert','orders','{"block_index": 310002, "expiration": 10, "expire_index": 310012, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 50000000, "give_remaining": 50000000, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "tx_hash": "12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8", "tx_index": 3}',0);
INSERT INTO messages VALUES(6,310003,'insert','debits','{"action": "open order", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310003, "event": "792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c", "quantity": 105000000}',0);
INSERT INTO messages VALUES(7,310003,'insert','orders','{"block_index": 310003, "expiration": 10, "expire_index": 310013, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 50000000, "get_remaining": 50000000, "give_asset": "XCP", "give_quantity": 105000000, "give_remaining": 105000000, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "tx_hash": "792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c", "tx_index": 4}',0);
INSERT INTO messages VALUES(8,310003,'update','orders','{"fee_provided_remaining": 142858, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8"}',0);
INSERT INTO messages VALUES(9,310003,'update','orders','{"fee_provided_remaining": 6800, "fee_required_remaining": 42858, "get_remaining": 0, "give_remaining": 5000000, "status": "open", "tx_hash": "792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c"}',0);
INSERT INTO messages VALUES(10,310003,'insert','order_matches','{"backward_asset": "XCP", "backward_quantity": 100000000, "block_index": 310003, "fee_paid": 857142, "forward_asset": "BTC", "forward_quantity": 50000000, "id": "12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8_792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c", "match_expire_index": 310023, "status": "pending", "tx0_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx0_block_index": 310002, "tx0_expiration": 10, "tx0_hash": "12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8", "tx0_index": 3, "tx1_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx1_block_index": 310003, "tx1_expiration": 10, "tx1_hash": "792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c", "tx1_index": 4}',0);
INSERT INTO messages VALUES(11,310004,'insert','credits','{"action": "btcpay", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310004, "event": "957a0550bc7ce9cc16d5ff5426bdb111ddb1261739a39bcb93334f15f859a495", "quantity": 100000000}',0);
INSERT INTO messages VALUES(12,310004,'update','order_matches','{"order_match_id": "12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8_792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c", "status": "completed"}',0);
INSERT INTO messages VALUES(13,310004,'insert','btcpays','{"block_index": 310004, "btc_amount": 50000000, "destination": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "order_match_id": "12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8_792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c", "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "957a0550bc7ce9cc16d5ff5426bdb111ddb1261739a39bcb93334f15f859a495", "tx_index": 5}',0);
INSERT INTO messages VALUES(14,310005,'insert','debits','{"action": "issuance fee", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310005, "event": "3542e3a185495b9cafae33747e3840236f65c94e360e0725b384821af67a2ecf", "quantity": 50000000}',0);
INSERT INTO messages VALUES(15,310005,'insert','issuances','{"asset": "BBBB", "asset_longname": null, "block_index": 310005, "call_date": 0, "call_price": 0.0, "callable": false, "description": "", "divisible": true, "fee_paid": 50000000, "issuer": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "locked": false, "quantity": 1000000000, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "transfer": false, "tx_hash": "3542e3a185495b9cafae33747e3840236f65c94e360e0725b384821af67a2ecf", "tx_index": 6}',0);
INSERT INTO messages VALUES(16,310005,'insert','credits','{"action": "issuance", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBB", "block_index": 310005, "event": "3542e3a185495b9cafae33747e3840236f65c94e360e0725b384821af67a2ecf", "quantity": 1000000000}',0);
INSERT INTO messages VALUES(17,310006,'insert','debits','{"action": "issuance fee", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310006, "event": "875294dc37e08c5c392c297179dc89aabe49e0f3d8484c62687e78a44477f452", "quantity": 50000000}',0);
INSERT INTO messages VALUES(18,310006,'insert','issuances','{"asset": "BBBC", "asset_longname": null, "block_index": 310006, "call_date": 0, "call_price": 0.0, "callable": false, "description": "foobar", "divisible": false, "fee_paid": 50000000, "issuer": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "locked": false, "quantity": 100000, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "transfer": false, "tx_hash": "875294dc37e08c5c392c297179dc89aabe49e0f3d8484c62687e78a44477f452", "tx_index": 7}',0);
INSERT INTO messages VALUES(19,310006,'insert','credits','{"action": "issuance", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBC", "block_index": 310006, "event": "875294dc37e08c5c392c297179dc89aabe49e0f3d8484c62687e78a44477f452", "quantity": 100000}',0);
INSERT INTO messages VALUES(20,310007,'insert','debits','{"action": "send", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBB", "block_index": 310007, "event": "209ca33a9b698c14c16090296e84e1556ed194a32b4ffb537f5e08327867ec48", "quantity": 4000000}',0);
INSERT INTO messages VALUES(21,310007,'insert','credits','{"action": "send", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "asset": "BBBB", "block_index": 310007, "event": "209ca33a9b698c14c16090296e84e1556ed194a32b4ffb537f5e08327867ec48", "quantity": 4000000}',0);
INSERT INTO messages VALUES(22,310007,'insert','sends','{"asset": "BBBB", "block_index": 310007, "destination": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "quantity": 4000000, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "209ca33a9b698c14c16090296e84e1556ed194a32b4ffb537f5e08327867ec48", "tx_index": 8}',0);
INSERT INTO messages VALUES(23,310008,'insert','debits','{"action": "send", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBC", "block_index": 310008, "event": "bad7a9312cc465ddd3083b0158963134db90dbf61d999841766f283f348ddf6a", "quantity": 526}',0);
INSERT INTO messages VALUES(24,310008,'insert','credits','{"action": "send", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "asset": "BBBC", "block_index": 310008, "event": "bad7a9312cc465ddd3083b0158963134db90dbf61d999841766f283f348ddf6a", "quantity": 526}',0);
INSERT INTO messages VALUES(25,310008,'insert','sends','{"asset": "BBBC", "block_index": 310008, "destination": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "quantity": 526, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "bad7a9312cc465ddd3083b0158963134db90dbf61d999841766f283f348ddf6a", "tx_index": 9}',0);
INSERT INTO messages VALUES(26,310009,'insert','debits','{"action": "dividend", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310009, "event": "cb9991934562490fc66980601a2afbf34d7b1d772079c1e56a9094488e454e96", "quantity": 24}',0);
INSERT INTO messages VALUES(27,310009,'insert','debits','{"action": "dividend fee", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310009, "event": "cb9991934562490fc66980601a2afbf34d7b1d772079c1e56a9094488e454e96", "quantity": 20000}',0);
INSERT INTO messages VALUES(28,310009,'insert','credits','{"action": "dividend", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "asset": "XCP", "block_index": 310009, "event": "cb9991934562490fc66980601a2afbf34d7b1d772079c1e56a9094488e454e96", "quantity": 24}',0);
INSERT INTO messages VALUES(29,310009,'insert','dividends','{"asset": "BBBB", "block_index": 310009, "dividend_asset": "XCP", "fee_paid": 20000, "quantity_per_unit": 600, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "cb9991934562490fc66980601a2afbf34d7b1d772079c1e56a9094488e454e96", "tx_index": 10}',0);
INSERT INTO messages VALUES(30,310010,'insert','debits','{"action": "dividend", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310010, "event": "5012de31b4fc38e61ffc4e4423e39190a5a294c2ab9d137b84cebf7ff3e76e17", "quantity": 420800}',0);
INSERT INTO messages VALUES(31,310010,'insert','debits','{"action": "dividend fee", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310010, "event": "5012de31b4fc38e61ffc4e4423e39190a5a294c2ab9d137b84cebf7ff3e76e17", "quantity": 20000}',0);
INSERT INTO messages VALUES(32,310010,'insert','credits','{"action": "dividend", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "asset": "XCP", "block_index": 310010, "event": "5012de31b4fc38e61ffc4e4423e39190a5a294c2ab9d137b84cebf7ff3e76e17", "quantity": 420800}',0);
INSERT INTO messages VALUES(33,310010,'insert','dividends','{"asset": "BBBC", "block_index": 310010, "dividend_asset": "XCP", "fee_paid": 20000, "quantity_per_unit": 800, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "5012de31b4fc38e61ffc4e4423e39190a5a294c2ab9d137b84cebf7ff3e76e17", "tx_index": 11}',0);
INSERT INTO messages VALUES(34,310011,'insert','broadcasts','{"block_index": 310011, "fee_fraction_int": 5000000, "locked": false, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "c045731917392e0eb1d390eb1ffadea08d2dfa1653a8b967aff9df79c1bfc4f1", "tx_index": 12, "value": 100.0}',0);
INSERT INTO messages VALUES(35,310012,'insert','debits','{"action": "bet", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310012, "event": "86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243", "quantity": 50000000}',0);
INSERT INTO messages VALUES(36,310012,'insert','bets','{"bet_type": 0, "block_index": 310012, "counterwager_quantity": 25000000, "counterwager_remaining": 25000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310022, "fee_fraction_int": 5000000.0, "feed_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "leverage": 15120, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "target_value": 0.0, "tx_hash": "86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243", "tx_index": 13, "wager_quantity": 50000000, "wager_remaining": 50000000}',0);
INSERT INTO messages VALUES(37,310013,'update','orders','{"status": "expired", "tx_hash": "12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8"}',0);
INSERT INTO messages VALUES(38,310013,'insert','order_expirations','{"block_index": 310013, "order_hash": "12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8", "order_index": 3, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3"}',0);
INSERT INTO messages VALUES(39,310013,'insert','debits','{"action": "bet", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310013, "event": "19e4f4787538366983026745d72265d95c32180e741934be0c0c9a9392640de8", "quantity": 25000000}',0);
INSERT INTO messages VALUES(40,310013,'insert','bets','{"bet_type": 1, "block_index": 310013, "counterwager_quantity": 41500000, "counterwager_remaining": 41500000, "deadline": 1388000100, "expiration": 10, "expire_index": 310023, "fee_fraction_int": 5000000.0, "feed_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "leverage": 15120, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "target_value": 0.0, "tx_hash": "19e4f4787538366983026745d72265d95c32180e741934be0c0c9a9392640de8", "tx_index": 14, "wager_quantity": 25000000, "wager_remaining": 25000000}',0);
INSERT INTO messages VALUES(41,310013,'update','bets','{"counterwager_remaining": 4250000, "status": "open", "tx_hash": "86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243", "wager_remaining": 8500000}',0);
INSERT INTO messages VALUES(42,310013,'insert','credits','{"action": "filled", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310013, "event": "19e4f4787538366983026745d72265d95c32180e741934be0c0c9a9392640de8", "quantity": 4250000}',0);
INSERT INTO messages VALUES(43,310013,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "19e4f4787538366983026745d72265d95c32180e741934be0c0c9a9392640de8", "wager_remaining": 4250000}',0);
INSERT INTO messages VALUES(44,310013,'insert','bet_matches','{"backward_quantity": 20750000, "block_index": 310013, "deadline": 1388000100, "fee_fraction_int": 5000000, "feed_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "forward_quantity": 41500000, "id": "86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243_19e4f4787538366983026745d72265d95c32180e741934be0c0c9a9392640de8", "initial_value": 100.0, "leverage": 15120, "match_expire_index": 310022, "status": "pending", "target_value": 0.0, "tx0_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx0_bet_type": 0, "tx0_block_index": 310012, "tx0_expiration": 10, "tx0_hash": "86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243", "tx0_index": 13, "tx1_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx1_bet_type": 1, "tx1_block_index": 310013, "tx1_expiration": 10, "tx1_hash": "19e4f4787538366983026745d72265d95c32180e741934be0c0c9a9392640de8", "tx1_index": 14}',0);
INSERT INTO messages VALUES(45,310014,'update','orders','{"status": "expired", "tx_hash": "792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c"}',0);
INSERT INTO messages VALUES(46,310014,'insert','credits','{"action": "cancel order", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310014, "event": "792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c", "quantity": 5000000}',0);
INSERT INTO messages VALUES(47,310014,'insert','order_expirations','{"block_index": 310014, "order_hash": "792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c", "order_index": 4, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3"}',0);
INSERT INTO messages VALUES(48,310014,'insert','debits','{"action": "bet", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310014, "event": "cb395180f84879bfa8aadbfc3b0a1f9ceb43805f930567451334aad30bab00a6", "quantity": 150000000}',0);
INSERT INTO messages VALUES(49,310014,'insert','bets','{"bet_type": 0, "block_index": 310014, "counterwager_quantity": 350000000, "counterwager_remaining": 350000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310024, "fee_fraction_int": 5000000.0, "feed_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "leverage": 5040, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "target_value": 0.0, "tx_hash": "cb395180f84879bfa8aadbfc3b0a1f9ceb43805f930567451334aad30bab00a6", "tx_index": 15, "wager_quantity": 150000000, "wager_remaining": 150000000}',0);
INSERT INTO messages VALUES(50,310015,'insert','debits','{"action": "bet", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310015, "event": "78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3", "quantity": 350000000}',0);
INSERT INTO messages VALUES(51,310015,'insert','bets','{"bet_type": 1, "block_index": 310015, "counterwager_quantity": 150000000, "counterwager_remaining": 150000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310025, "fee_fraction_int": 5000000.0, "feed_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "leverage": 5040, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "target_value": 0.0, "tx_hash": "78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3", "tx_index": 16, "wager_quantity": 350000000, "wager_remaining": 350000000}',0);
INSERT INTO messages VALUES(52,310015,'insert','credits','{"action": "filled", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310015, "event": "78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3", "quantity": 0}',0);
INSERT INTO messages VALUES(53,310015,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "cb395180f84879bfa8aadbfc3b0a1f9ceb43805f930567451334aad30bab00a6", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(54,310015,'insert','credits','{"action": "filled", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310015, "event": "78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3", "quantity": 0}',0);
INSERT INTO messages VALUES(55,310015,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(56,310015,'insert','bet_matches','{"backward_quantity": 350000000, "block_index": 310015, "deadline": 1388000100, "fee_fraction_int": 5000000, "feed_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "forward_quantity": 150000000, "id": "cb395180f84879bfa8aadbfc3b0a1f9ceb43805f930567451334aad30bab00a6_78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3", "initial_value": 100.0, "leverage": 5040, "match_expire_index": 310024, "status": "pending", "target_value": 0.0, "tx0_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx0_bet_type": 0, "tx0_block_index": 310014, "tx0_expiration": 10, "tx0_hash": "cb395180f84879bfa8aadbfc3b0a1f9ceb43805f930567451334aad30bab00a6", "tx0_index": 15, "tx1_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx1_bet_type": 1, "tx1_block_index": 310015, "tx1_expiration": 10, "tx1_hash": "78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3", "tx1_index": 16}',0);
INSERT INTO messages VALUES(57,310016,'insert','debits','{"action": "bet", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310016, "event": "170565b2aa082c64e3cf8f0ccf2bf675372a4f068f698b663eddf916d432e52b", "quantity": 750000000}',0);
INSERT INTO messages VALUES(58,310016,'insert','bets','{"bet_type": 2, "block_index": 310016, "counterwager_quantity": 650000000, "counterwager_remaining": 650000000, "deadline": 1388000200, "expiration": 10, "expire_index": 310026, "fee_fraction_int": 5000000.0, "feed_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "leverage": 5040, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "target_value": 1.0, "tx_hash": "170565b2aa082c64e3cf8f0ccf2bf675372a4f068f698b663eddf916d432e52b", "tx_index": 17, "wager_quantity": 750000000, "wager_remaining": 750000000}',0);
INSERT INTO messages VALUES(59,310017,'insert','debits','{"action": "bet", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310017, "event": "b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679", "quantity": 650000000}',0);
INSERT INTO messages VALUES(60,310017,'insert','bets','{"bet_type": 3, "block_index": 310017, "counterwager_quantity": 750000000, "counterwager_remaining": 750000000, "deadline": 1388000200, "expiration": 10, "expire_index": 310027, "fee_fraction_int": 5000000.0, "feed_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "leverage": 5040, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "target_value": 1.0, "tx_hash": "b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679", "tx_index": 18, "wager_quantity": 650000000, "wager_remaining": 650000000}',0);
INSERT INTO messages VALUES(61,310017,'insert','credits','{"action": "filled", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310017, "event": "b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679", "quantity": 0}',0);
INSERT INTO messages VALUES(62,310017,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "170565b2aa082c64e3cf8f0ccf2bf675372a4f068f698b663eddf916d432e52b", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(63,310017,'insert','credits','{"action": "filled", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310017, "event": "b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679", "quantity": 0}',0);
INSERT INTO messages VALUES(64,310017,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(65,310017,'insert','bet_matches','{"backward_quantity": 650000000, "block_index": 310017, "deadline": 1388000200, "fee_fraction_int": 5000000, "feed_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "forward_quantity": 750000000, "id": "170565b2aa082c64e3cf8f0ccf2bf675372a4f068f698b663eddf916d432e52b_b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679", "initial_value": 100.0, "leverage": 5040, "match_expire_index": 310026, "status": "pending", "target_value": 1.0, "tx0_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx0_bet_type": 2, "tx0_block_index": 310016, "tx0_expiration": 10, "tx0_hash": "170565b2aa082c64e3cf8f0ccf2bf675372a4f068f698b663eddf916d432e52b", "tx0_index": 17, "tx1_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx1_bet_type": 3, "tx1_block_index": 310017, "tx1_expiration": 10, "tx1_hash": "b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679", "tx1_index": 18}',0);
INSERT INTO messages VALUES(66,310018,'insert','broadcasts','{"block_index": 310018, "fee_fraction_int": 5000000, "locked": false, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "text": "Unit Test", "timestamp": 1388000050, "tx_hash": "16db4d63be8839383e28cdab7edf52c1264340fb5db51ae5341801983ff48861", "tx_index": 19, "value": 99.86166}',0);
INSERT INTO messages VALUES(67,310018,'insert','credits','{"action": "bet settled: liquidated for bear", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310018, "event": "16db4d63be8839383e28cdab7edf52c1264340fb5db51ae5341801983ff48861", "quantity": 59137500}',0);
INSERT INTO messages VALUES(68,310018,'insert','credits','{"action": "feed fee", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310018, "event": "16db4d63be8839383e28cdab7edf52c1264340fb5db51ae5341801983ff48861", "quantity": 3112500}',0);
INSERT INTO messages VALUES(69,310018,'insert','bet_match_resolutions','{"bear_credit": 59137500, "bet_match_id": "86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243_19e4f4787538366983026745d72265d95c32180e741934be0c0c9a9392640de8", "bet_match_type_id": 1, "block_index": 310018, "bull_credit": 0, "escrow_less_fee": null, "fee": 3112500, "settled": false, "winner": null}',0);
INSERT INTO messages VALUES(70,310018,'update','bet_matches','{"bet_match_id": "86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243_19e4f4787538366983026745d72265d95c32180e741934be0c0c9a9392640de8", "status": "settled: liquidated for bear"}',0);
INSERT INTO messages VALUES(71,310019,'insert','broadcasts','{"block_index": 310019, "fee_fraction_int": 5000000, "locked": false, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "text": "Unit Test", "timestamp": 1388000101, "tx_hash": "f0409d985023c1fcb9cd0df5530b65b71c1ebff78f36020f157fadd109f4c52f", "tx_index": 20, "value": 100.343}',0);
INSERT INTO messages VALUES(72,310019,'insert','credits','{"action": "bet settled", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310019, "event": "f0409d985023c1fcb9cd0df5530b65b71c1ebff78f36020f157fadd109f4c52f", "quantity": 159300000}',0);
INSERT INTO messages VALUES(73,310019,'insert','credits','{"action": "bet settled", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310019, "event": "f0409d985023c1fcb9cd0df5530b65b71c1ebff78f36020f157fadd109f4c52f", "quantity": 315700000}',0);
INSERT INTO messages VALUES(74,310019,'insert','credits','{"action": "feed fee", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310019, "event": "f0409d985023c1fcb9cd0df5530b65b71c1ebff78f36020f157fadd109f4c52f", "quantity": 25000000}',0);
INSERT INTO messages VALUES(75,310019,'insert','bet_match_resolutions','{"bear_credit": 315700000, "bet_match_id": "cb395180f84879bfa8aadbfc3b0a1f9ceb43805f930567451334aad30bab00a6_78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3", "bet_match_type_id": 1, "block_index": 310019, "bull_credit": 159300000, "escrow_less_fee": null, "fee": 25000000, "settled": true, "winner": null}',0);
INSERT INTO messages VALUES(76,310019,'update','bet_matches','{"bet_match_id": "cb395180f84879bfa8aadbfc3b0a1f9ceb43805f930567451334aad30bab00a6_78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3", "status": "settled"}',0);
INSERT INTO messages VALUES(77,310020,'insert','broadcasts','{"block_index": 310020, "fee_fraction_int": 5000000, "locked": false, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "text": "Unit Test", "timestamp": 1388000201, "tx_hash": "4e33149428c2fe189c237ed80abd77262c4f2df3fdfad7e275631f2ef51b0a7e", "tx_index": 21, "value": 2.0}',0);
INSERT INTO messages VALUES(78,310020,'insert','credits','{"action": "bet settled: for notequal", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310020, "event": "4e33149428c2fe189c237ed80abd77262c4f2df3fdfad7e275631f2ef51b0a7e", "quantity": 1330000000}',0);
INSERT INTO messages VALUES(79,310020,'insert','credits','{"action": "feed fee", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310020, "event": "4e33149428c2fe189c237ed80abd77262c4f2df3fdfad7e275631f2ef51b0a7e", "quantity": 70000000}',0);
INSERT INTO messages VALUES(80,310020,'insert','bet_match_resolutions','{"bear_credit": null, "bet_match_id": "170565b2aa082c64e3cf8f0ccf2bf675372a4f068f698b663eddf916d432e52b_b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679", "bet_match_type_id": 5, "block_index": 310020, "bull_credit": null, "escrow_less_fee": 1330000000, "fee": 70000000, "settled": null, "winner": "NotEqual"}',0);
INSERT INTO messages VALUES(81,310020,'update','bet_matches','{"bet_match_id": "170565b2aa082c64e3cf8f0ccf2bf675372a4f068f698b663eddf916d432e52b_b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679", "status": "settled: for notequal"}',0);
INSERT INTO messages VALUES(82,310021,'insert','debits','{"action": "open order", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBB", "block_index": 310021, "event": "cc068ab4b7834ebc0a7742e86691d4f2a82c13baef4ca13662c72d6b51e48d64", "quantity": 50000000}',0);
INSERT INTO messages VALUES(83,310021,'insert','orders','{"block_index": 310021, "expiration": 10, "expire_index": 310031, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 50000000, "get_remaining": 50000000, "give_asset": "BBBB", "give_quantity": 50000000, "give_remaining": 50000000, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "tx_hash": "cc068ab4b7834ebc0a7742e86691d4f2a82c13baef4ca13662c72d6b51e48d64", "tx_index": 22}',0);
INSERT INTO messages VALUES(84,310022,'insert','credits','{"action": "burn", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310022, "event": "181709b341ec136f90975fdaa362c767ebd789e72f16d4e17348ab2985c1bd01", "quantity": 56999887262}',0);
INSERT INTO messages VALUES(85,310022,'insert','burns','{"block_index": 310022, "burned": 38000000, "earned": 56999887262, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "181709b341ec136f90975fdaa362c767ebd789e72f16d4e17348ab2985c1bd01", "tx_index": 23}',0);
INSERT INTO messages VALUES(86,310023,'update','bets','{"status": "expired", "tx_hash": "86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243"}',0);
INSERT INTO messages VALUES(87,310023,'insert','credits','{"action": "recredit wager remaining", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310023, "event": "86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243", "quantity": 8500000}',0);
INSERT INTO messages VALUES(88,310023,'insert','bet_expirations','{"bet_hash": "86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243", "bet_index": 13, "block_index": 310023, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3"}',0);
INSERT INTO messages VALUES(89,310023,'insert','debits','{"action": "send", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBC", "block_index": 310023, "event": "057f27f2340282c1a82250563b67a37497eb8e07c2f5d0905422238158488488", "quantity": 10000}',0);
INSERT INTO messages VALUES(90,310023,'insert','credits','{"action": "send", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "asset": "BBBC", "block_index": 310023, "event": "057f27f2340282c1a82250563b67a37497eb8e07c2f5d0905422238158488488", "quantity": 10000}',0);
INSERT INTO messages VALUES(91,310023,'insert','sends','{"asset": "BBBC", "block_index": 310023, "destination": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "quantity": 10000, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "057f27f2340282c1a82250563b67a37497eb8e07c2f5d0905422238158488488", "tx_index": 24}',0);
INSERT INTO messages VALUES(92,310032,'update','orders','{"status": "expired", "tx_hash": "cc068ab4b7834ebc0a7742e86691d4f2a82c13baef4ca13662c72d6b51e48d64"}',0);
INSERT INTO messages VALUES(93,310032,'insert','credits','{"action": "cancel order", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBB", "block_index": 310032, "event": "cc068ab4b7834ebc0a7742e86691d4f2a82c13baef4ca13662c72d6b51e48d64", "quantity": 50000000}',0);
INSERT INTO messages VALUES(94,310032,'insert','order_expirations','{"block_index": 310032, "order_hash": "cc068ab4b7834ebc0a7742e86691d4f2a82c13baef4ca13662c72d6b51e48d64", "order_index": 22, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3"}',0);
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
INSERT INTO order_expirations VALUES(3,'12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',310013);
INSERT INTO order_expirations VALUES(4,'792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',310014);
INSERT INTO order_expirations VALUES(22,'cc068ab4b7834ebc0a7742e86691d4f2a82c13baef4ca13662c72d6b51e48d64','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',310032);
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
INSERT INTO order_matches VALUES('12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8_792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c',3,'12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',4,'792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BTC',50000000,'XCP',100000000,310002,310003,310003,10,10,310023,857142,'completed');
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
INSERT INTO orders VALUES(3,'12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8',310002,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BTC',50000000,0,'XCP',100000000,0,10,310012,0,0,1000000,142858,'expired');
INSERT INTO orders VALUES(4,'792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c',310003,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',105000000,5000000,'BTC',50000000,0,10,310013,900000,42858,6800,6800,'expired');
INSERT INTO orders VALUES(22,'cc068ab4b7834ebc0a7742e86691d4f2a82c13baef4ca13662c72d6b51e48d64',310021,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',50000000,50000000,'XCP',50000000,50000000,10,310031,0,0,6800,6800,'expired');
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
CREATE TABLE sends(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      destination TEXT,
                      asset TEXT,
                      quantity INTEGER,
                      status TEXT, memo BLOB,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
INSERT INTO sends VALUES(2,'52e4c56494983092daf8cef2850b69a66e0c0cdbef3ec3ba92d42983bda70505',310001,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',50000000,'valid',NULL);
INSERT INTO sends VALUES(8,'209ca33a9b698c14c16090296e84e1556ed194a32b4ffb537f5e08327867ec48',310007,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBB',4000000,'valid',NULL);
INSERT INTO sends VALUES(9,'bad7a9312cc465ddd3083b0158963134db90dbf61d999841766f283f348ddf6a',310008,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',526,'valid',NULL);
INSERT INTO sends VALUES(24,'057f27f2340282c1a82250563b67a37497eb8e07c2f5d0905422238158488488',310023,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',10000,'valid',NULL);
-- Triggers and indices on  sends
CREATE TRIGGER _sends_delete BEFORE DELETE ON sends BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO sends(rowid,tx_index,tx_hash,block_index,source,destination,asset,quantity,status,memo) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.destination)||','||quote(old.asset)||','||quote(old.quantity)||','||quote(old.status)||','||quote(old.memo)||')');
                            END;
CREATE TRIGGER _sends_insert AFTER INSERT ON sends BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM sends WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _sends_update AFTER UPDATE ON sends BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE sends SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',destination='||quote(old.destination)||',asset='||quote(old.asset)||',quantity='||quote(old.quantity)||',status='||quote(old.status)||',memo='||quote(old.memo)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX destination_idx ON sends (destination);
CREATE INDEX memo_idx ON sends (memo);
CREATE INDEX source_idx ON sends (source);

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
INSERT INTO transactions VALUES(1,'15b35d5497f454c43576f21a1b61d99bde25dfc5aae1a4796dcf55e739d6a399',310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
INSERT INTO transactions VALUES(2,'52e4c56494983092daf8cef2850b69a66e0c0cdbef3ec3ba92d42983bda70505',310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3',7800,7650,X'0000000000000000000000010000000002FAF080',1);
INSERT INTO transactions VALUES(3,'12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8',310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,1000000,X'0000000A00000000000000000000000002FAF08000000000000000010000000005F5E100000A0000000000000000',1);
INSERT INTO transactions VALUES(4,'792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c',310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000000A00000000000000010000000006422C4000000000000000000000000002FAF080000A00000000000DBBA0',1);
INSERT INTO transactions VALUES(5,'957a0550bc7ce9cc16d5ff5426bdb111ddb1261739a39bcb93334f15f859a495',310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',50000000,9675,X'0000000B12B8EF5D36AD332A8700BE63C5B6E41F4AC8CAD15899E4BA651664E951D384D8792289D0CC057F06FEE7C5CDFA65C770BF30F7BCC9EA85DD83E0DCC9D6CF655C',1);
INSERT INTO transactions VALUES(6,'3542e3a185495b9cafae33747e3840236f65c94e360e0725b384821af67a2ecf',310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'000000140000000000004767000000003B9ACA000100000000000000000000',1);
INSERT INTO transactions VALUES(7,'875294dc37e08c5c392c297179dc89aabe49e0f3d8484c62687e78a44477f452',310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'00000014000000000000476800000000000186A00000000000000000000006666F6F626172',1);
INSERT INTO transactions VALUES(8,'209ca33a9b698c14c16090296e84e1556ed194a32b4ffb537f5e08327867ec48',310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3',7800,7650,X'00000000000000000000476700000000003D0900',1);
INSERT INTO transactions VALUES(9,'bad7a9312cc465ddd3083b0158963134db90dbf61d999841766f283f348ddf6a',310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3',7800,7650,X'000000000000000000004768000000000000020E',1);
INSERT INTO transactions VALUES(10,'cb9991934562490fc66980601a2afbf34d7b1d772079c1e56a9094488e454e96',310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'00000032000000000000025800000000000047670000000000000001',1);
INSERT INTO transactions VALUES(11,'5012de31b4fc38e61ffc4e4423e39190a5a294c2ab9d137b84cebf7ff3e76e17',310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'00000032000000000000032000000000000047680000000000000001',1);
INSERT INTO transactions VALUES(12,'c045731917392e0eb1d390eb1ffadea08d2dfa1653a8b967aff9df79c1bfc4f1',310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000001E52BB33004059000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(13,'86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243',310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',7800,7650,X'00000028000052BB33640000000002FAF08000000000017D7840000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(14,'19e4f4787538366983026745d72265d95c32180e741934be0c0c9a9392640de8',310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',7800,7650,X'00000028000152BB336400000000017D78400000000002793D60000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(15,'cb395180f84879bfa8aadbfc3b0a1f9ceb43805f930567451334aad30bab00a6',310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',7800,7650,X'00000028000052BB33640000000008F0D1800000000014DC93800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(16,'78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3',310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',7800,7650,X'00000028000152BB33640000000014DC93800000000008F0D1800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(17,'170565b2aa082c64e3cf8f0ccf2bf675372a4f068f698b663eddf916d432e52b',310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',7800,7650,X'00000028000252BB33C8000000002CB417800000000026BE36803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(18,'b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679',310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',7800,7650,X'00000028000352BB33C80000000026BE3680000000002CB417803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(19,'16db4d63be8839383e28cdab7edf52c1264340fb5db51ae5341801983ff48861',310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000001E52BB33324058F7256FFC115E004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(20,'f0409d985023c1fcb9cd0df5530b65b71c1ebff78f36020f157fadd109f4c52f',310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000001E52BB3365405915F3B645A1CB004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(21,'4e33149428c2fe189c237ed80abd77262c4f2df3fdfad7e275631f2ef51b0a7e',310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000001E52BB33C94000000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(22,'cc068ab4b7834ebc0a7742e86691d4f2a82c13baef4ca13662c72d6b51e48d64',310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000000A00000000000047670000000002FAF08000000000000000010000000002FAF080000A0000000000000000',1);
INSERT INTO transactions VALUES(23,'181709b341ec136f90975fdaa362c767ebd789e72f16d4e17348ab2985c1bd01',310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','mvCounterpartyXXXXXXXXXXXXXXW24Hef',100000000,5625,X'',1);
INSERT INTO transactions VALUES(24,'057f27f2340282c1a82250563b67a37497eb8e07c2f5d0905422238158488488',310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3',7800,7650,X'0000000000000000000047680000000000002710',1);
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
INSERT INTO undolog VALUES(4,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=93000000000 WHERE rowid=1');
INSERT INTO undolog VALUES(5,'DELETE FROM debits WHERE rowid=1');
INSERT INTO undolog VALUES(6,'DELETE FROM balances WHERE rowid=2');
INSERT INTO undolog VALUES(7,'DELETE FROM credits WHERE rowid=2');
INSERT INTO undolog VALUES(8,'DELETE FROM sends WHERE rowid=2');
INSERT INTO undolog VALUES(9,'DELETE FROM orders WHERE rowid=1');
INSERT INTO undolog VALUES(10,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92950000000 WHERE rowid=1');
INSERT INTO undolog VALUES(11,'DELETE FROM debits WHERE rowid=2');
INSERT INTO undolog VALUES(12,'DELETE FROM orders WHERE rowid=2');
INSERT INTO undolog VALUES(13,'UPDATE orders SET tx_index=3,tx_hash=''12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8'',block_index=310002,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''BTC'',give_quantity=50000000,give_remaining=50000000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=10,expire_index=310012,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(14,'UPDATE orders SET tx_index=4,tx_hash=''792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c'',block_index=310003,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''XCP'',give_quantity=105000000,give_remaining=105000000,get_asset=''BTC'',get_quantity=50000000,get_remaining=50000000,expiration=10,expire_index=310013,fee_required=900000,fee_required_remaining=900000,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(15,'DELETE FROM order_matches WHERE rowid=1');
INSERT INTO undolog VALUES(16,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92845000000 WHERE rowid=1');
INSERT INTO undolog VALUES(17,'DELETE FROM credits WHERE rowid=3');
INSERT INTO undolog VALUES(18,'UPDATE order_matches SET id=''12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8_792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c'',tx0_index=3,tx0_hash=''12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8'',tx0_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx1_index=4,tx1_hash=''792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c'',tx1_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',forward_asset=''BTC'',forward_quantity=50000000,backward_asset=''XCP'',backward_quantity=100000000,tx0_block_index=310002,tx1_block_index=310003,block_index=310003,tx0_expiration=10,tx1_expiration=10,match_expire_index=310023,fee_paid=857142,status=''pending'' WHERE rowid=1');
INSERT INTO undolog VALUES(19,'DELETE FROM btcpays WHERE rowid=5');
INSERT INTO undolog VALUES(20,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92945000000 WHERE rowid=1');
INSERT INTO undolog VALUES(21,'DELETE FROM debits WHERE rowid=3');
INSERT INTO undolog VALUES(22,'DELETE FROM assets WHERE rowid=3');
INSERT INTO undolog VALUES(23,'DELETE FROM issuances WHERE rowid=6');
INSERT INTO undolog VALUES(24,'DELETE FROM balances WHERE rowid=3');
INSERT INTO undolog VALUES(25,'DELETE FROM credits WHERE rowid=4');
INSERT INTO undolog VALUES(26,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92895000000 WHERE rowid=1');
INSERT INTO undolog VALUES(27,'DELETE FROM debits WHERE rowid=4');
INSERT INTO undolog VALUES(28,'DELETE FROM assets WHERE rowid=4');
INSERT INTO undolog VALUES(29,'DELETE FROM issuances WHERE rowid=7');
INSERT INTO undolog VALUES(30,'DELETE FROM balances WHERE rowid=4');
INSERT INTO undolog VALUES(31,'DELETE FROM credits WHERE rowid=5');
INSERT INTO undolog VALUES(32,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''BBBB'',quantity=1000000000 WHERE rowid=3');
INSERT INTO undolog VALUES(33,'DELETE FROM debits WHERE rowid=5');
INSERT INTO undolog VALUES(34,'DELETE FROM balances WHERE rowid=5');
INSERT INTO undolog VALUES(35,'DELETE FROM credits WHERE rowid=6');
INSERT INTO undolog VALUES(36,'DELETE FROM sends WHERE rowid=8');
INSERT INTO undolog VALUES(37,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''BBBC'',quantity=100000 WHERE rowid=4');
INSERT INTO undolog VALUES(38,'DELETE FROM debits WHERE rowid=6');
INSERT INTO undolog VALUES(39,'DELETE FROM balances WHERE rowid=6');
INSERT INTO undolog VALUES(40,'DELETE FROM credits WHERE rowid=7');
INSERT INTO undolog VALUES(41,'DELETE FROM sends WHERE rowid=9');
INSERT INTO undolog VALUES(42,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92845000000 WHERE rowid=1');
INSERT INTO undolog VALUES(43,'DELETE FROM debits WHERE rowid=7');
INSERT INTO undolog VALUES(44,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92844999976 WHERE rowid=1');
INSERT INTO undolog VALUES(45,'DELETE FROM debits WHERE rowid=8');
INSERT INTO undolog VALUES(46,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3'',asset=''XCP'',quantity=50000000 WHERE rowid=2');
INSERT INTO undolog VALUES(47,'DELETE FROM credits WHERE rowid=8');
INSERT INTO undolog VALUES(48,'DELETE FROM dividends WHERE rowid=10');
INSERT INTO undolog VALUES(49,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92844979976 WHERE rowid=1');
INSERT INTO undolog VALUES(50,'DELETE FROM debits WHERE rowid=9');
INSERT INTO undolog VALUES(51,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92844559176 WHERE rowid=1');
INSERT INTO undolog VALUES(52,'DELETE FROM debits WHERE rowid=10');
INSERT INTO undolog VALUES(53,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3'',asset=''XCP'',quantity=50000024 WHERE rowid=2');
INSERT INTO undolog VALUES(54,'DELETE FROM credits WHERE rowid=9');
INSERT INTO undolog VALUES(55,'DELETE FROM dividends WHERE rowid=11');
INSERT INTO undolog VALUES(56,'DELETE FROM broadcasts WHERE rowid=12');
INSERT INTO undolog VALUES(57,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92844539176 WHERE rowid=1');
INSERT INTO undolog VALUES(58,'DELETE FROM debits WHERE rowid=11');
INSERT INTO undolog VALUES(59,'DELETE FROM bets WHERE rowid=1');
INSERT INTO undolog VALUES(60,'UPDATE orders SET tx_index=3,tx_hash=''12b8ef5d36ad332a8700be63c5b6e41f4ac8cad15899e4ba651664e951d384d8'',block_index=310002,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''BTC'',give_quantity=50000000,give_remaining=0,get_asset=''XCP'',get_quantity=100000000,get_remaining=0,expiration=10,expire_index=310012,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=142858,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(61,'DELETE FROM order_expirations WHERE rowid=3');
INSERT INTO undolog VALUES(62,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92794539176 WHERE rowid=1');
INSERT INTO undolog VALUES(63,'DELETE FROM debits WHERE rowid=12');
INSERT INTO undolog VALUES(64,'DELETE FROM bets WHERE rowid=2');
INSERT INTO undolog VALUES(65,'UPDATE bets SET tx_index=13,tx_hash=''86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243'',block_index=310012,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=0,deadline=1388000100,wager_quantity=50000000,wager_remaining=50000000,counterwager_quantity=25000000,counterwager_remaining=25000000,target_value=0.0,leverage=15120,expiration=10,expire_index=310022,fee_fraction_int=5000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(66,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92769539176 WHERE rowid=1');
INSERT INTO undolog VALUES(67,'DELETE FROM credits WHERE rowid=10');
INSERT INTO undolog VALUES(68,'UPDATE bets SET tx_index=14,tx_hash=''19e4f4787538366983026745d72265d95c32180e741934be0c0c9a9392640de8'',block_index=310013,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=1,deadline=1388000100,wager_quantity=25000000,wager_remaining=25000000,counterwager_quantity=41500000,counterwager_remaining=41500000,target_value=0.0,leverage=15120,expiration=10,expire_index=310023,fee_fraction_int=5000000,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(69,'DELETE FROM bet_matches WHERE rowid=1');
INSERT INTO undolog VALUES(70,'UPDATE orders SET tx_index=4,tx_hash=''792289d0cc057f06fee7c5cdfa65c770bf30f7bcc9ea85dd83e0dcc9d6cf655c'',block_index=310003,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''XCP'',give_quantity=105000000,give_remaining=5000000,get_asset=''BTC'',get_quantity=50000000,get_remaining=0,expiration=10,expire_index=310013,fee_required=900000,fee_required_remaining=42858,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(71,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92773789176 WHERE rowid=1');
INSERT INTO undolog VALUES(72,'DELETE FROM credits WHERE rowid=11');
INSERT INTO undolog VALUES(73,'DELETE FROM order_expirations WHERE rowid=4');
INSERT INTO undolog VALUES(74,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92778789176 WHERE rowid=1');
INSERT INTO undolog VALUES(75,'DELETE FROM debits WHERE rowid=13');
INSERT INTO undolog VALUES(76,'DELETE FROM bets WHERE rowid=3');
INSERT INTO undolog VALUES(77,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92628789176 WHERE rowid=1');
INSERT INTO undolog VALUES(78,'DELETE FROM debits WHERE rowid=14');
INSERT INTO undolog VALUES(79,'DELETE FROM bets WHERE rowid=4');
INSERT INTO undolog VALUES(80,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(81,'DELETE FROM credits WHERE rowid=12');
INSERT INTO undolog VALUES(82,'UPDATE bets SET tx_index=15,tx_hash=''cb395180f84879bfa8aadbfc3b0a1f9ceb43805f930567451334aad30bab00a6'',block_index=310014,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=0,deadline=1388000100,wager_quantity=150000000,wager_remaining=150000000,counterwager_quantity=350000000,counterwager_remaining=350000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310024,fee_fraction_int=5000000,status=''open'' WHERE rowid=3');
INSERT INTO undolog VALUES(83,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(84,'DELETE FROM credits WHERE rowid=13');
INSERT INTO undolog VALUES(85,'UPDATE bets SET tx_index=16,tx_hash=''78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3'',block_index=310015,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=1,deadline=1388000100,wager_quantity=350000000,wager_remaining=350000000,counterwager_quantity=150000000,counterwager_remaining=150000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310025,fee_fraction_int=5000000,status=''open'' WHERE rowid=4');
INSERT INTO undolog VALUES(86,'DELETE FROM bet_matches WHERE rowid=2');
INSERT INTO undolog VALUES(87,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(88,'DELETE FROM debits WHERE rowid=15');
INSERT INTO undolog VALUES(89,'DELETE FROM bets WHERE rowid=5');
INSERT INTO undolog VALUES(90,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=91528789176 WHERE rowid=1');
INSERT INTO undolog VALUES(91,'DELETE FROM debits WHERE rowid=16');
INSERT INTO undolog VALUES(92,'DELETE FROM bets WHERE rowid=6');
INSERT INTO undolog VALUES(93,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(94,'DELETE FROM credits WHERE rowid=14');
INSERT INTO undolog VALUES(95,'UPDATE bets SET tx_index=17,tx_hash=''170565b2aa082c64e3cf8f0ccf2bf675372a4f068f698b663eddf916d432e52b'',block_index=310016,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=2,deadline=1388000200,wager_quantity=750000000,wager_remaining=750000000,counterwager_quantity=650000000,counterwager_remaining=650000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310026,fee_fraction_int=5000000,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(96,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(97,'DELETE FROM credits WHERE rowid=15');
INSERT INTO undolog VALUES(98,'UPDATE bets SET tx_index=18,tx_hash=''b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679'',block_index=310017,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=3,deadline=1388000200,wager_quantity=650000000,wager_remaining=650000000,counterwager_quantity=750000000,counterwager_remaining=750000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310027,fee_fraction_int=5000000,status=''open'' WHERE rowid=6');
INSERT INTO undolog VALUES(99,'DELETE FROM bet_matches WHERE rowid=3');
INSERT INTO undolog VALUES(100,'DELETE FROM broadcasts WHERE rowid=19');
INSERT INTO undolog VALUES(101,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(102,'DELETE FROM credits WHERE rowid=16');
INSERT INTO undolog VALUES(103,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90937926676 WHERE rowid=1');
INSERT INTO undolog VALUES(104,'DELETE FROM credits WHERE rowid=17');
INSERT INTO undolog VALUES(105,'DELETE FROM bet_match_resolutions WHERE rowid=1');
INSERT INTO undolog VALUES(106,'UPDATE bet_matches SET id=''86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243_19e4f4787538366983026745d72265d95c32180e741934be0c0c9a9392640de8'',tx0_index=13,tx0_hash=''86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243'',tx0_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx1_index=14,tx1_hash=''19e4f4787538366983026745d72265d95c32180e741934be0c0c9a9392640de8'',tx1_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=15120,forward_quantity=41500000,backward_quantity=20750000,tx0_block_index=310012,tx1_block_index=310013,block_index=310013,tx0_expiration=10,tx1_expiration=10,match_expire_index=310022,fee_fraction_int=5000000,status=''pending'' WHERE rowid=1');
INSERT INTO undolog VALUES(107,'DELETE FROM broadcasts WHERE rowid=20');
INSERT INTO undolog VALUES(108,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90941039176 WHERE rowid=1');
INSERT INTO undolog VALUES(109,'DELETE FROM credits WHERE rowid=18');
INSERT INTO undolog VALUES(110,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=91100339176 WHERE rowid=1');
INSERT INTO undolog VALUES(111,'DELETE FROM credits WHERE rowid=19');
INSERT INTO undolog VALUES(112,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=91416039176 WHERE rowid=1');
INSERT INTO undolog VALUES(113,'DELETE FROM credits WHERE rowid=20');
INSERT INTO undolog VALUES(114,'DELETE FROM bet_match_resolutions WHERE rowid=2');
INSERT INTO undolog VALUES(115,'UPDATE bet_matches SET id=''cb395180f84879bfa8aadbfc3b0a1f9ceb43805f930567451334aad30bab00a6_78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3'',tx0_index=15,tx0_hash=''cb395180f84879bfa8aadbfc3b0a1f9ceb43805f930567451334aad30bab00a6'',tx0_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx1_index=16,tx1_hash=''78739e7f0c87978bb5c8600db150dac4f6b6fc424889562afc7374edee19fac3'',tx1_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=5040,forward_quantity=150000000,backward_quantity=350000000,tx0_block_index=310014,tx1_block_index=310015,block_index=310015,tx0_expiration=10,tx1_expiration=10,match_expire_index=310024,fee_fraction_int=5000000,status=''pending'' WHERE rowid=2');
INSERT INTO undolog VALUES(116,'DELETE FROM broadcasts WHERE rowid=21');
INSERT INTO undolog VALUES(117,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=91441039176 WHERE rowid=1');
INSERT INTO undolog VALUES(118,'DELETE FROM credits WHERE rowid=21');
INSERT INTO undolog VALUES(119,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92771039176 WHERE rowid=1');
INSERT INTO undolog VALUES(120,'DELETE FROM credits WHERE rowid=22');
INSERT INTO undolog VALUES(121,'DELETE FROM bet_match_resolutions WHERE rowid=3');
INSERT INTO undolog VALUES(122,'UPDATE bet_matches SET id=''170565b2aa082c64e3cf8f0ccf2bf675372a4f068f698b663eddf916d432e52b_b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679'',tx0_index=17,tx0_hash=''170565b2aa082c64e3cf8f0ccf2bf675372a4f068f698b663eddf916d432e52b'',tx0_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx1_index=18,tx1_hash=''b8b743d7ab870a99b3310a15fe5ae1dfe2a7c13afc5c6fce6a532f1f98c6b679'',tx1_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx0_bet_type=2,tx1_bet_type=3,feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',initial_value=100,deadline=1388000200,target_value=1.0,leverage=5040,forward_quantity=750000000,backward_quantity=650000000,tx0_block_index=310016,tx1_block_index=310017,block_index=310017,tx0_expiration=10,tx1_expiration=10,match_expire_index=310026,fee_fraction_int=5000000,status=''pending'' WHERE rowid=3');
INSERT INTO undolog VALUES(123,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''BBBB'',quantity=996000000 WHERE rowid=3');
INSERT INTO undolog VALUES(124,'DELETE FROM debits WHERE rowid=17');
INSERT INTO undolog VALUES(125,'DELETE FROM orders WHERE rowid=3');
INSERT INTO undolog VALUES(126,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92841039176 WHERE rowid=1');
INSERT INTO undolog VALUES(127,'DELETE FROM credits WHERE rowid=23');
INSERT INTO undolog VALUES(128,'DELETE FROM burns WHERE rowid=23');
INSERT INTO undolog VALUES(129,'UPDATE bets SET tx_index=13,tx_hash=''86609abcd81835cc472bd8c193d27e1048b5f7cba981414117fbf8cc67f84243'',block_index=310012,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=0,deadline=1388000100,wager_quantity=50000000,wager_remaining=8500000,counterwager_quantity=25000000,counterwager_remaining=4250000,target_value=0.0,leverage=15120,expiration=10,expire_index=310022,fee_fraction_int=5000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(130,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=149840926438 WHERE rowid=1');
INSERT INTO undolog VALUES(131,'DELETE FROM credits WHERE rowid=24');
INSERT INTO undolog VALUES(132,'DELETE FROM bet_expirations WHERE rowid=13');
INSERT INTO undolog VALUES(133,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''BBBC'',quantity=99474 WHERE rowid=4');
INSERT INTO undolog VALUES(134,'DELETE FROM debits WHERE rowid=18');
INSERT INTO undolog VALUES(135,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3'',asset=''BBBC'',quantity=526 WHERE rowid=6');
INSERT INTO undolog VALUES(136,'DELETE FROM credits WHERE rowid=25');
INSERT INTO undolog VALUES(137,'DELETE FROM sends WHERE rowid=24');
INSERT INTO undolog VALUES(138,'UPDATE orders SET tx_index=22,tx_hash=''cc068ab4b7834ebc0a7742e86691d4f2a82c13baef4ca13662c72d6b51e48d64'',block_index=310021,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''BBBB'',give_quantity=50000000,give_remaining=50000000,get_asset=''XCP'',get_quantity=50000000,get_remaining=50000000,expiration=10,expire_index=310031,fee_required=0,fee_required_remaining=0,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=3');
INSERT INTO undolog VALUES(139,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''BBBB'',quantity=946000000 WHERE rowid=3');
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
