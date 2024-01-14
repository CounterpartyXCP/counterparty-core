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
INSERT INTO balances VALUES('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',149849426438);
INSERT INTO balances VALUES('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',50420824);
INSERT INTO balances VALUES('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',996000000);
INSERT INTO balances VALUES('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC',89474);
INSERT INTO balances VALUES('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBB',4000000);
INSERT INTO balances VALUES('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',10526);
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
INSERT INTO bet_expirations VALUES(13,'1075391072b01264a783bf31205a83abdf7356c8c405753d3ef8599f852df887','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',310023);
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
INSERT INTO bet_match_resolutions VALUES('1075391072b01264a783bf31205a83abdf7356c8c405753d3ef8599f852df887_a067f79057992245507ea08e901e623918be2b0eb2d178e35b01f36da2d30a33',1,310018,'0',0,59137500,NULL,NULL,3112500);
INSERT INTO bet_match_resolutions VALUES('040e03dfdef2df24411a077cfe5f90f3311bbb82bb3783ea2d7e6f484afd3e2b_62ece578c6760773bd4252922a7a0af87da1a1c308f32423e20cf49a369ea0a2',1,310019,'1',159300000,315700000,NULL,NULL,25000000);
INSERT INTO bet_match_resolutions VALUES('578d8026c9a3a9173fdb7d5f10c6d5e7d49f375edf5fd8b3f29ccb37a8b42d1f_479b0fbec468381f1e27332755b12a69800680379d0037e02f641265a8beb183',5,310020,NULL,NULL,NULL,'NotEqual',1330000000,70000000);
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
INSERT INTO bet_matches VALUES('1075391072b01264a783bf31205a83abdf7356c8c405753d3ef8599f852df887_a067f79057992245507ea08e901e623918be2b0eb2d178e35b01f36da2d30a33',13,'1075391072b01264a783bf31205a83abdf7356c8c405753d3ef8599f852df887','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',14,'a067f79057992245507ea08e901e623918be2b0eb2d178e35b01f36da2d30a33','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,1,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',100,1388000100,0.0,15120,41500000,20750000,310012,310013,310013,10,10,310022,99999999,'settled: liquidated for bear');
INSERT INTO bet_matches VALUES('040e03dfdef2df24411a077cfe5f90f3311bbb82bb3783ea2d7e6f484afd3e2b_62ece578c6760773bd4252922a7a0af87da1a1c308f32423e20cf49a369ea0a2',15,'040e03dfdef2df24411a077cfe5f90f3311bbb82bb3783ea2d7e6f484afd3e2b','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',16,'62ece578c6760773bd4252922a7a0af87da1a1c308f32423e20cf49a369ea0a2','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,1,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',100,1388000100,0.0,5040,150000000,350000000,310014,310015,310015,10,10,310024,99999999,'settled');
INSERT INTO bet_matches VALUES('578d8026c9a3a9173fdb7d5f10c6d5e7d49f375edf5fd8b3f29ccb37a8b42d1f_479b0fbec468381f1e27332755b12a69800680379d0037e02f641265a8beb183',17,'578d8026c9a3a9173fdb7d5f10c6d5e7d49f375edf5fd8b3f29ccb37a8b42d1f','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',18,'479b0fbec468381f1e27332755b12a69800680379d0037e02f641265a8beb183','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',2,3,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',100,1388000200,1.0,5040,750000000,650000000,310016,310017,310017,10,10,310026,99999999,'settled: for notequal');
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
INSERT INTO bets VALUES(13,'1075391072b01264a783bf31205a83abdf7356c8c405753d3ef8599f852df887',310012,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,1388000100,50000000,8500000,25000000,4250000,0.0,15120,10,310022,99999999,'expired');
INSERT INTO bets VALUES(14,'a067f79057992245507ea08e901e623918be2b0eb2d178e35b01f36da2d30a33',310013,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1,1388000100,25000000,4250000,41500000,0,0.0,15120,10,310023,99999999,'filled');
INSERT INTO bets VALUES(15,'040e03dfdef2df24411a077cfe5f90f3311bbb82bb3783ea2d7e6f484afd3e2b',310014,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,1388000100,150000000,0,350000000,0,0.0,5040,10,310024,99999999,'filled');
INSERT INTO bets VALUES(16,'62ece578c6760773bd4252922a7a0af87da1a1c308f32423e20cf49a369ea0a2',310015,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1,1388000100,350000000,0,150000000,0,0.0,5040,10,310025,99999999,'filled');
INSERT INTO bets VALUES(17,'578d8026c9a3a9173fdb7d5f10c6d5e7d49f375edf5fd8b3f29ccb37a8b42d1f',310016,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',2,1388000200,750000000,0,650000000,0,1.0,5040,10,310026,99999999,'filled');
INSERT INTO bets VALUES(18,'479b0fbec468381f1e27332755b12a69800680379d0037e02f641265a8beb183',310017,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',3,1388000200,650000000,0,750000000,0,1.0,5040,10,310027,99999999,'filled');
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
INSERT INTO blocks VALUES(310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,NULL,NULL,'7e1322d444b3395f9d8ce6b1ca6d48e8f0d78e5d72da997fad9520899bdbebe3','702e537dd6e79386a246cbc44fbccf8ea2a4e575c9f1e072189fbbd831308672','f6c03e072960d3351d5c373892749c834b841b28e13ebd04207c9898767c06b2');
INSERT INTO blocks VALUES(310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,NULL,NULL,'3e18d8a969bce2d869cb86b28c23823d88e6d8a840a3cda905a003b37222ebb8','bcd62109b750a9b5c3a07fb6e3ba7a5feb2cb56fb554da3b2b4b560a632e3e2e','4791d9ddc61ec0830e5a570a3c786c90b42cd47400fcefc5e455e4e138ca8d69');
INSERT INTO blocks VALUES(310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,NULL,NULL,'71dfa527236bbaf632db18cf1773c63f7ee3a0076fc6562e46db0c955b346a9f','f7e5b51624875d95cb14e212ee733c94f12f69084eeefa4b77491479ea3ae990','a008521b8460b3c8aca7892437632e3626119a1d437faff2b237d4d18216fc0d');
INSERT INTO blocks VALUES(310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,NULL,NULL,'39feff81ad306adcfb9610e6bd8442e35dd6e1924e75a53708c1d2932bda67f6','a857bb0cb63c343a04d6efdf7d69f1de6f89a67dc25ca5b3e9cd9405ef48c416','f51bf3a6b60e2c86f5a4507a68bbdfb12bdb3a950cfc2e5afbf5f32a3d4a7c20');
INSERT INTO blocks VALUES(310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,NULL,NULL,'1cee0851ee48eeaa3f71e7a18f9f52fffa28cd3b2e1cbf1f79c0f562618b88c6','32e68b308a1281ef170d188fe7d19a93486667d45d8a6b50a0c39f00d6924cde','2946e79990ad0a64f66b84377cca8027581bf6d614641b0418b21ebee2b1f4bb');
INSERT INTO blocks VALUES(310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,NULL,NULL,'89f516c3fbdcd1540125561301db451fb55b1baead9ae8f408156075aed104ad','3a41f3c4d912ee4628975e61c4a04b836de31df5a9aa5fbd7031628d9c4f0eb6','020e97bfe963bf038ef26958e5b539d26196cbd198ca85edd4a24f4db1e11721');
INSERT INTO blocks VALUES(310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,NULL,NULL,'e9a37cfc1055e8c18d369896a14422cad3c5ac8d9b4d5aff6053d8e31dd56336','c46b595025716e9cc03bffda197de587a86f9a25da2f37e72ac90de2a0217421','67ce9abb6b1269ad6a6740c6298dd2cc638874dd7671a7b5658cc82c00ddb4ea');
INSERT INTO blocks VALUES(310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,NULL,NULL,'174c7c107c37e0ca2c907b1bc35e086eebbad8eb02493a2f166ff2279ecc013c','e8cba0a34dd4b9e49ae4e36ca5399f3013c693669046cc67d66e9b7d477ebf3f','80ad66e3bfbc73c80c5687f4af7a006665ccdbfa391099ed4234aab66f1ad2cf');
INSERT INTO blocks VALUES(310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,NULL,NULL,'1463da3ebe264e703ecc0c708baa98f737b31f51726f85d3ac646f5e301b7c10','199c24f78c2dcc11b3447008201261cdc9747b33db12c3c1d03317c8ca3fb32c','fa589449fc5c17276b363608ad649d267fa56bfd8c529b4491c1a134ab26f562');
INSERT INTO blocks VALUES(310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,NULL,NULL,'dfe8c57b4ce4ea12f002d11cfc127f95b7cea7727bcbaf64418b2d584602a250','9755d01e6b3fc7d5be0b0c31209a550eb6fc5e7d962a98add24f74e6b5e0f95a','4f4a93808db95c1c12139d54c4c078c04828e8594cab57380c54281e8b924562');
INSERT INTO blocks VALUES(310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,NULL,NULL,'f9c936d3bb4c8bbc20e544d9262ffa3906fbaeca5e4b2e3b241f6059868f506e','afac1f2ae198b3f3ed968184b41fae1dfe53c0990c844eef08131885e0137820','121b46608a4cd9d54b896afb614ee97d46ce2cf7f1540d3abc7e9fd29862a312');
INSERT INTO blocks VALUES(310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,NULL,NULL,'490bfec10bfd72eca7fcbae5887b94ce4739454a82e601dc754e4e9d1030f3c2','29a0f33a90d5c467e05671a71e77705f48a9185696447d4a62ca9cae6584ccd7','be331a92f59cb410c8b62a544b6adceace8b7f7213c4710fd87343b78412879e');
INSERT INTO blocks VALUES(310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,NULL,NULL,'621d39c103bff9a76ada332f41e3ad54c89676bb6057f624942ddf28b31b5927','352b67e837fa70ef22aba5c80593f02bc4e51c15c5ddc0f731e16875aca9be1d','deb8da3a61279d461f75cabd22b680c388a98006e48a1c0ffca83a57c0cf3466');
INSERT INTO blocks VALUES(310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,NULL,NULL,'7d31be770d6bb6669bcb0a8a5964e57a758788cbbb942d1d3da1abd25b5dd158','23351eb4f98b260af74ca7b660d25a6a7895295e4afd2ef2c98e2aeb2983ab44','4b2d12418b9acb6aa9ef22faed4e35b73674cef586f0574a5d983be0f01122a1');
INSERT INTO blocks VALUES(310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,NULL,NULL,'3aba9622f8de243bcd5e6a5c88fdf04a79a52d95bdc1778d57586b13f30e501c','437042f3bcb225376c34fead09b4c02f1d3cdd909ef9206084ed914b695d1cb6','22475f1fb911c1c8ffdc735aa6606ad3bc4f651dc9d1a091e25f749399690649');
INSERT INTO blocks VALUES(310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,NULL,NULL,'342e5dddd2289d3d6e381fade13e5a5e3ed27615b89bd8e06ea2bab8f8b48be8','0a001d4f4e178b064226b884c3a9d33777473daeec4d2cd8cbdc32c379a14598','5f435e29950871b450b0238b15b5034a46de07f0bb8814f78e753d98a65f204a');
INSERT INTO blocks VALUES(310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,NULL,NULL,'51b904e6b18ce4d17bdc491457036ff3a4ba70789ae929862844e9456c3b9b01','b5e16b4e13d4a440506e796c0b3780aec4a5ecc25b2d1a43585be0c7dd54dc55','f41900d4881fe7f3bbbb5a758746407750855b331558119f635555480f174776');
INSERT INTO blocks VALUES(310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,NULL,NULL,'03a60654bc84711524cb38171f6573acbe8cc2120787bd09e5ec621b2f53929c','fc498e78ed041b2cd56d310021a54de921307bf0acb2bbc34ed6f9a0e176314e','89084a798d22fc80975e570e754d1af439dcc9880e757ca39c9f15b793996409');
INSERT INTO blocks VALUES(310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,NULL,NULL,'a590602f34163cf8f880c3620f07a8cd27b9aeba8fc80ccb201d88364eaed210','8cb3e7860df3505947ee9c2934b109b9e22a10f3be007c369c126e5402338ae9','585b86fc37c2e87b37080ede4cf3f5e42424b881610d4e0a9519850e3aa9b639');
INSERT INTO blocks VALUES(310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,NULL,NULL,'1b340e7abac4c458e6a0c6ff2abd6dadaa2913414f450cf926725b5253210950','81a443f73eaa53d1a5f3a31aa34eb620add9824983face15d1d2f00b28f1f795','4adcaaf1b8cfbd4d669bc8660715d76d4115d536368bdbeb04a6ceffe0388d05');
INSERT INTO blocks VALUES(310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,NULL,NULL,'5a5a31ae9b03a362b44c9e38effadfeac273bd370374ea4816b8402d6b8a8a1a','1bd5a0ef692dec0f6dd481675f4a2a978de97bdf929309776519cb6df62e7b84','706626ecfc78a1d922724a93c5f78fb3181726b0ace82ab5f2c9c3b310b99766');
INSERT INTO blocks VALUES(310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,NULL,NULL,'2005a300856ccc74efe80c56927fc13619d5c40ab03ae4ee4fba2050bc2a6b75','358338ca7ac33e899342092aea0f0bd33a325515c5e3e64fd6f81ac53453aae7','de7b50e7a5cb5696d45368c4322ec12cab90f308b459d0b5bef8a31d8cda2f8a');
INSERT INTO blocks VALUES(310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,NULL,NULL,'95307de52e23a8433143d79710e7df22ba7205e2651c88a2eda220ebc8e0f289','475c95a4cce16f27e2623d4af7d0640fbe5d556adf7c4a975c6524a7c3b9d25c','45503b13615d5167aab3b58deefb30a31d14440c8d5eea628e26e9418fc5c6d7');
INSERT INTO blocks VALUES(310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,NULL,NULL,'de5a22c228bfc58ceaf428d55f180e951ff877537ef463821ce1206f07ab02f3','ca578aa139f331683c205e191ad1a20c09399763044c0e00d3554039d2bf1f11','23fed4f068c593a6b85539c3e15341cf1bb75ccf03f63efc5ef8557080319d8c');
INSERT INTO blocks VALUES(310024,'b03042b4e18a222b4c8d1e9e1970d93e6e2a2d41686d227ff8ecf0a839223dc5',310024000,NULL,NULL,'e54da9db6c4911087dcfb2824acfd7429431e3297f6b5836dfa8f95165ac9b08','d675f28b70e75b476599a3fc49cb5025a9c334cec19e136f0da04ce776610f55','5260cb4e8b60b6598d6184cf0cb7af009bf39ba6bc5361203b67a9ca01c58fdc');
INSERT INTO blocks VALUES(310025,'a872e560766832cc3b4f7f222228cb6db882ce3c54f6459f62c71d5cd6e90666',310025000,NULL,NULL,'dac63e0e407785c7a461d839ddd749f020f8a33026cd6ea2acd659567a36c40c','d08e12f5166d2e3d31ceb79ffc4650a3aacccf0346ec9b05d7d2b8722bd78abe','1529fad66399b238297a89275637d7c824e7672901174e5031ee644dcefcc96a');
INSERT INTO blocks VALUES(310026,'6c96350f6f2f05810f19a689de235eff975338587194a36a70dfd0fcd490941a',310026000,NULL,NULL,'0397b7da62fb672aadb96fbdfc37f3265ea04c4d401632d5d9018b9b0ad7cd45','853f42c7b6274df05aa3b5f1ac91f932533e162d8005dfd8ed23722194df2a6e','2a43f180e463bd49a9695a75f5f30318daa7744291eea282f0371d7b59565334');
INSERT INTO blocks VALUES(310027,'d7acfac66df393c4482a14c189742c0571b89442eb7f817b34415a560445699e',310027000,NULL,NULL,'dbe43e77c383acc66cb46105991ed066ed5309434016081c26ca1a7dd948b6ce','b27547325d6853c2f9c206b5612c16fdc6052ca691ae20b5fbcb6198ef7df756','6d94fbbae87b24b4d0ed7cb5473329c1b51edc1adf5b87b5992b185faf367bbe');
INSERT INTO blocks VALUES(310028,'02409fcf8fa06dafcb7f11e38593181d9c42cc9d5e2ddc304d098f990bd9530b',310028000,NULL,NULL,'ce1021a584895988014f16dd9f7b7b29bbe59ca8a761914f60c9290b5ec6a16f','60d53f8f5ccd73c5bc7aedf2a70da987fde6426bb7a51090d49ae80f83663820','7d14c5e0b1093ab1b7dc983e27ade8bb5abf84b7aeeb96530a9673937c33d7f5');
INSERT INTO blocks VALUES(310029,'3c739fa8b40c118d5547ea356ee8d10ee2898871907643ec02e5db9d00f03cc6',310029000,NULL,NULL,'4a066ff12cf6f8dad894e23cfbb4fe6a087893b717b3f0c1ec53764b1e922bf4','449a7f21d8edcbcb6f939f409e776c4b527608b53500af07296b90f4a2e707a5','f5e380ca601e64929cdc62c9aea945b305624d5ae9e6e5fe3bd1a23fc1cdc982');
INSERT INTO blocks VALUES(310030,'d5071cddedf89765ee0fd58f209c1c7d669ba8ea66200a57587da8b189b9e4f5',310030000,NULL,NULL,'be1cc89117e7cb3fc18eb610103d72f144c31848da4d8001c334aac577f19427','6bc7238a84fec14ad741cdd942e15df5699ac6ea6a61102778c9c2ab63330e96','547d8efcc98ad45be4aa9d3e0971d9f5e00e1bd8044482f519867bc2c99330f8');
INSERT INTO blocks VALUES(310031,'0b02b10f41380fff27c543ea8891ecb845bf7a003ac5c87e15932aff3bfcf689',310031000,NULL,NULL,'a616b3d81a1ad1db1a9b1491b06ff6bcead9037f75552d14a4c7234b6ff56670','5b578b4342a8a63e92374b4390cc027f3a6002f03e0e033c8a2302a71b587fed','510b2a0222c27be7c5cec45d65860f70eb50983c62e55f64e14f71c89d8d062a');
INSERT INTO blocks VALUES(310032,'66346be81e6ba04544f2ae643b76c2b7b1383f038fc2636e02e49dc7ec144074',310032000,NULL,NULL,'e7e76fe32ac5c06696c0bda815f29f1e0785a9d48641615f2ef78fa9982d258f','695743c6b4dcbd13a79cf3be6066e4a4aabfd905ab18a5d4ac9b174af7f673ac','3fe41d55e2ecbf727edcdc2dae6aa1ce12bbd75c848d06aa2f96ce8c9ae260e7');
INSERT INTO blocks VALUES(310033,'999c65df9661f73e8c01f1da1afda09ac16788b72834f0ff5ea3d1464afb4707',310033000,NULL,NULL,'f0d33d2f73f83449c18b9a7bea43857b36effa24eb248283d9356c5280e4992f','3c6e85881452eb13dd94b7a451640115c67606e559fa482d8f9cc35a22b96cfe','02b25d54dfc9e9180882cb8768e8b331c2678a77acab691758aad915f54539b6');
INSERT INTO blocks VALUES(310034,'f552edd2e0a648230f3668e72ddf0ddfb1e8ac0f4c190f91b89c1a8c2e357208',310034000,NULL,NULL,'434d631a1c3ef7d31d136b4eab8b3044dc2b65886bf43642537cc592db0415a3','970c68822b51cf760a267037c6d603fbc66b9615d17338dbdd15c3786859db30','3537111d540d7be4d1e8cf4958c7e1dfbf4060eb672ebabe931c714bd929a342');
INSERT INTO blocks VALUES(310035,'a13cbb016f3044207a46967a4ba1c87dab411f78c55c1179f2336653c2726ae2',310035000,NULL,NULL,'5ca42816d9c6aaed19f6d25cd02e842b5d834254f90a169630544c83a129c7e5','d21aac678857cbe7b857a1127daf64429e882ed84627184304471f5429a5045e','cfea38b683acfc92b8db7967859a1f5afada7388d46a8bdd612428c5070c188e');
INSERT INTO blocks VALUES(310036,'158648a98f1e1bd1875584ce8449eb15a4e91a99a923bbb24c4210135cef0c76',310036000,NULL,NULL,'31aecb842ea816f98aead90fed7ad005c010919a2ef2c5d7a8965b71832d3201','4b1e1b9ae106bcf31e9c798c7883775f68e209dda67e4b6dc37d6e1d3f97fac8','c8af2ceb09f58143def8721c9376d82b7ef9d22efd578bd94c5edb85dab240c9');
INSERT INTO blocks VALUES(310037,'563acfd6d991ce256d5655de2e9429975c8dceeb221e76d5ec6e9e24a2c27c07',310037000,NULL,NULL,'7a3167eb2c8a80c7c363ac47200ebc8cb6bd53f57da64465bec14bd86cf2c6c7','71896341d738bda74312408cbb383627f9cc4ad615edd092ffcaa66ea5b75f49','e764538b201534e1e8a081ee9210d301a358920120ab933e8305413183e78fd8');
INSERT INTO blocks VALUES(310038,'b44b4cad12431c32df27940e18d51f63897c7472b70950d18454edfd640490b2',310038000,NULL,NULL,'212bc51956081e57aa618360926e186824dce8987948ee7706403451ab417a0a','bfb15a7eb244ef6cd298f190e229c19551acd2cd2273af0dda734f3da78423c6','f465abf2097907a6a59288b6c1347133e3c299975ae1b8fc1c69f52423665855');
INSERT INTO blocks VALUES(310039,'5fa1ae9c5e8a599247458987b006ad3a57f686df1f7cc240bf119e911b56c347',310039000,NULL,NULL,'03e72d7551164403b41956638a0fdec8703c29373ea2b15c770717b0ec39fa95','83f35c9c238d407ff95115b870c0cc4890039a80c8d90e0118496ea319721ae0','c8b62e201da6c5697ed96b05b526f5640de2f8bc411ba6b88005b0d2e83168a7');
INSERT INTO blocks VALUES(310040,'7200ded406675453eadddfbb2d14c2a4526c7dc2b5de14bd48b29243df5e1aa3',310040000,NULL,NULL,'922aa744aa0c08274d1f47a0f80638c7937ecaaf95555e68ceec09449e60d080','367296ddf33441e3219121d783e74af442b76f207de90d90ef7f08b7ac77d7d7','00c9223b674cb3a982dcc201489a2e4b508434ae8edd8248e7a75b93d6ad62c0');
INSERT INTO blocks VALUES(310041,'5db592ff9ba5fac1e030cf22d6c13b70d330ba397f415340086ee7357143b359',310041000,NULL,NULL,'de422fc7f3f11d20b697e0ee57afe101ddeb5e84105153a3bb10f97f9c3f1783','ae78925450e34c1bb519dbe0c496f3813338065120b2ef4064f3173b520c9c51','d90df84c566c74e3351cac3faa1df87679727ace9b4e6004f554c3a57f463bbb');
INSERT INTO blocks VALUES(310042,'826fd4701ef2824e9559b069517cd3cb990aff6a4690830f78fc845ab77fa3e4',310042000,NULL,NULL,'82d7c9a0c9d63c3f93b125a9eabc2a7b5f560eccc5fb578d71ec071f150c8fac','b4ada6fd80777bd8d31566cf1148f92d7abe469984752d83133ef12bbd890d19','208e5a3bae94fddc91ea934a4ae446f444c06a96063e93bea329b600e57a47ba');
INSERT INTO blocks VALUES(310043,'2254a12ada208f1dd57bc17547ecaf3c44720323c47bc7d4b1262477cb7f3c51',310043000,NULL,NULL,'c9232d9cfb183cc9bc09bef78f7c83bac3d9af803e6916c9b14063c4f619d9e6','1a7646cdd6f8e2282faf4e165f77d072d1aa91c0d7cf91d7b205335e38a9d611','9efc12954457d56c788bc2eb3d7b5fb37c51b58cd80343213ff486afa89fd840');
INSERT INTO blocks VALUES(310044,'3346d24118d8af0b3c6bcc42f8b85792e7a2e7036ebf6e4c25f4f6723c78e46b',310044000,NULL,NULL,'71c3e7aa2ad71e35b752dd4e48381b4ca845c370e5c340f2a221dde808966a45','35987d00c0bae19fac6befe126421720a5d118e295f76a5718cf4e78a80c8456','cb1312a7227079f77d946aaf83efa54217098bee0a121a2fe055b19f234d5c4c');
INSERT INTO blocks VALUES(310045,'7bba0ab243839e91ad1a45a762bf074011f8a9883074d68203c6d1b46fffde98',310045000,NULL,NULL,'47230be2ba96e7adb6088b18788b52a65aa48183c2c00095b79999f5ea1af514','e9a5548cbb31298a4fdf78e380614411bd355e922e0e31fc1f857449589cf247','7f7bf9c5a653eb25f095dccbee50e46cf3011ebc664171a395c595526fb52809');
INSERT INTO blocks VALUES(310046,'47db6788c38f2d6d712764979e41346b55e78cbb4969e0ef5c4336faf18993a6',310046000,NULL,NULL,'2c306c41049fba2e58a07b5d14f930bcaa465b2afa4df24d8a887958555f0c57','aa14dccf338e7ac8cfdd65cb042959200f244ce921d21128236e61be64583594','382fc9bcef63a72179184af1655fc6de8c68effee537a6620633a56411223c3c');
INSERT INTO blocks VALUES(310047,'a9ccabcc2a098a7d25e4ab8bda7c4e66807eefa42e29890dcd88149a10de7075',310047000,NULL,NULL,'95a6325dcb8b9f7aef9da35bd20a46addef23aa5c36795beccacf992bee88d28','b37455eb111558fed4f0969365e6411387515554d48bac506f2882dcdce014bc','446b462da2f3f8a248607ea11de61bba59a3fdba49c9b005efcea5799e1acf8d');
INSERT INTO blocks VALUES(310048,'610bf3935a85b05a98556c55493c6de45bed4d7b3b6c8553a984718765796309',310048000,NULL,NULL,'8811d6a6b22ff3e0ecf399dd20a28a17ad000e99b17f90e63e02230ed42cf260','77b91c21914d208fa80e344240aaba36d4d89bbfd41c622aa4dc2f9c1f386fdc','4e1104b6c00c4b55f0c05d407beadf025b824d5fd113e6bf22cfb41294ee5225');
INSERT INTO blocks VALUES(310049,'4ad2761923ad49ad2b283b640f1832522a2a5d6964486b21591b71df6b33be3c',310049000,NULL,NULL,'4bffe3d3071cee255f64108bd8b97652f06190cb73caac5bdc4ef61d3ff9ecd6','2c5b3e64ff1ecda81d91ddeebd5e8fa54a3035c411826dfc251f725a3c61d407','11eeb929dbe7a14fbcd548bba907181c9359ff32a5acad6f576580aab44f235d');
INSERT INTO blocks VALUES(310050,'8cfeb60a14a4cec6e9be13d699694d49007d82a31065a17890383e262071e348',310050000,NULL,NULL,'b00d5001e914fde448457f3b373637385114eeb07d79751241f4c1f50cadc050','ae1fb2b460df2565c144469a7a7ef0b1d558b18adf838991388eb38d6c4156c5','fce84b1d3164101fbfa69f69a4faf44fd2ab4189f64ebfad14b405231b8a421a');
INSERT INTO blocks VALUES(310051,'b53c90385dd808306601350920c6af4beb717518493fd23b5c730eea078f33e6',310051000,NULL,NULL,'90dd8fabe43314ac6ab6f5485275a4b1131c232a1e9d92395fc030659873edb8','e550b163413c2d598c36af723cc05f056fc0548910d8d945c724a8148e8304e8','bdc194167f1da226315fbd3b9ff3c63dd3155b3cf97c7d5ca2314f615527c92e');
INSERT INTO blocks VALUES(310052,'0acdacf4e4b6fca756479cb055191b367b1fa433aa558956f5f08fa5b7b394e2',310052000,NULL,NULL,'923848bdc7906ab89898021e05e201f69305087b12803c459f066f2d681fe9b5','c8d9dc149104974679b8126e07e251bd3c0ab280205722d235ef6d42296089f5','c3e63cffc0ffa17269263f0368d9c120b6dbaa13c252e932250adf9ca67cc4b7');
INSERT INTO blocks VALUES(310053,'68348f01b6dc49b2cb30fe92ac43e527aa90d859093d3bf7cd695c64d2ef744f',310053000,NULL,NULL,'e5ecdf8c0a2166fa8fe25adea0d374d34131d29a3c901868fec579eb20a5a930','3392d0c472d01b788d8b63b7595ca9bf24b6a0801e5b5ec21725473e986ff45f','ceba2fb58f790a41178b05a708b559ec6397a728dc2d3fa4451ba487778ec389');
INSERT INTO blocks VALUES(310054,'a8b5f253df293037e49b998675620d5477445c51d5ec66596e023282bb9cd305',310054000,NULL,NULL,'03cd75c14bbe11800f4d436dce93235787e2521a19b1d5a90796a5de369680d1','910f30a84ea92c3019fde2165de33ca01d550f782dde27429165a29913e547ee','0ce001c2e977d2cae5dcce2841557ce3c9d3580dd13cb8e5fc1ce1ea752bc1fc');
INSERT INTO blocks VALUES(310055,'4b069152e2dc82e96ed8a3c3547c162e8c3aceeb2a4ac07972f8321a535b9356',310055000,NULL,NULL,'7239560704ca831dfe90791f1cd21ae1f1506275cf6b45933676be9b096d340b','366390124b09bca5f54a17a5fc3ba4c5a6a697921b996854779f3f9eb4b65f9f','381e6cb429f6c4a41905296540e8a3832a81af5a1446b0f80be1647b814b21eb');
INSERT INTO blocks VALUES(310056,'7603eaed418971b745256742f9d2ba70b2c2b2f69f61de6cc70e61ce0336f9d3',310056000,NULL,NULL,'3aa4ef8714cbb71c4f0b052dc7ec7795322103ba7b8361db3f33303f564f3815','0834bae9dbfd30d4de610432c47cd01b14a575c01fc536e59f4a6257d9e699cf','784b9caf58bf76d7d1f78d0b1734ecb613442abaf9f1fbb8f927e03312a68bd9');
INSERT INTO blocks VALUES(310057,'4a5fdc84f2d66ecb6ee3e3646aad20751ce8694e64e348d3c8aab09d33a3e411',310057000,NULL,NULL,'fee33c0a466c580887106b4bb7a8c6aeb7a049c94987bae64f695ae400c4a4a1','8e031ce14cac6450dcc46ec7264d8acb6adb519d75e3bc040e4577b4c5f2cfba','6549616373ff1795cb8f3567fccf8ad7d5eb886cc5898db93baf1ce2a27c593c');
INSERT INTO blocks VALUES(310058,'a6eef3089896f0cae0bfe9423392e45c48f4efe4310b14d8cfbdb1fea613635f',310058000,NULL,NULL,'94d58bd9a65a2e13c7ea2373e521952e916b0e1d31d803eced96e5c8903aa625','0dba8d1488afbd3177a3a91d866f4805325231ebf8360a9a8815cc64473d6c4a','0a48eb3c72ad799e509f941e232d0bf692c1436da5c0b4c6274f8bb0dac528a1');
INSERT INTO blocks VALUES(310059,'ab505de874c43f97c90be1c26a769e6c5cb140405c993b4a6cc7afc795f156a9',310059000,NULL,NULL,'e9c87b2a652d4ef3d48ac74424f57d06dd85893fd542e0784df067c37396b0df','1abc41d248b5e9259a6b08ba86169d673cc29f94e78a71be9d7441bc9a77f6b9','dd5f95bba8ab26d2f481e09bc08a1e523da214a0f54475b822a79db6adf4ebb2');
INSERT INTO blocks VALUES(310060,'974ad5fbef621e0a38eab811608dc9afaf10c8ecc85fed913075ba1a145e889b',310060000,NULL,NULL,'b664a0985edab20768aec36096a7b2faa159cef4af7e779ad421942137ee317a','63fb3bfc8d329a1623a6d8334cb4a4bbd1d5f4c77ea16705e19da8291fbb20a3','573613c4cda929d6f6372ca4c3fe402292e6503420d0a6a69a0bec97bd63c4c2');
INSERT INTO blocks VALUES(310061,'35d267d21ad386e7b7632292af1c422b0310dde7ca49a82f9577525a29c138cf',310061000,NULL,NULL,'5ffa5e1f36c5539b2f5a89a6a60d45ec6372ced770d9b0e0e8dfd61edad84c22','d3e8ebacca388999fd528ea2a5a482f0c4d667fee532db8857f9f675168e53e0','e32165bb53ab44e3be3a10e36418415c9abacb454f976c4b3be1c2075372bf86');
INSERT INTO blocks VALUES(310062,'b31a0054145319ef9de8c1cb19df5bcf4dc8a1ece20053aa494e5d3a00a2852f',310062000,NULL,NULL,'fc6f9f23c3b8954c7989b0e4ce40087b66dceabc7c0e407ac7f4b397fe2a1281','6f0472e056858cf57da0be45421ed93b61be143c3c34f101abca889282454e05','f2d9baa242b878ae3a39fc51c1da8fff56037f0a97c06c26d39d86aa7e873653');
INSERT INTO blocks VALUES(310063,'0cbcbcd5b7f2dc288e3a34eab3d4212463a5a56e886804fb4f9f1cf929eadebe',310063000,NULL,NULL,'cc6c3b8cf2c457b2f6afb5b208f968544767be8b86ca53bdab4224619a03121d','d524a6899d8974008dcb03fe0f434c47320d1f8cd44c47a74edda6b4ebdaeaef','0d6b94d1456c661c44745de9e6a8c80ad93a277c14e55efdb2d01c841de740e3');
INSERT INTO blocks VALUES(310064,'e2db8065a195e85cde9ddb868a17d39893a60fb2b1255aa5f0c88729de7cbf30',310064000,NULL,NULL,'cc57ac6aec118ebfb03f5113ad1af749522e60ef4ca201d48bd43478cc0a29e4','968b05f20ca272e61e5131788c83a57c2896eb595a847bd5aa8b97d49d47e2d6','d46579e3e6ba769bd42d3c1179b11d2c7f27c87a8298e60bd63574a3c3316aa4');
INSERT INTO blocks VALUES(310065,'8a7bc7a77c831ac4fd11b8a9d22d1b6a0661b07cef05c2e600c7fb683b861d2a',310065000,NULL,NULL,'9999be70079c0943f0a00c54236680bafe0c87dd3bb75c982211f751e7ecdcae','c1f6c1b0198ef66a4c5d4d2f43e6b8ac057416b33f1f33cac91c6ea5708cad85','75bab77c6c3eee327263379b4d3f29057d61870dd9c9cb7975d0cfaab848896d');
INSERT INTO blocks VALUES(310066,'b6959be51eb084747d301f7ccaf9e75f2292c9404633b1532e3692659939430d',310066000,NULL,NULL,'efb2fcb7b5628bb99994bc1ada157bf80b4516d961497aa011c06da1523801d7','33195fb07e3da90eaf09b847eae0398232bd91316bfdcb286585dceda46fa7b3','722b58abb36633eed6685bc3430708ae770baebcda0562991fd7158f2ba0e0cb');
INSERT INTO blocks VALUES(310067,'8b08eae98d7193c9c01863fac6effb9162bda010daeacf9e0347112f233b8577',310067000,NULL,NULL,'fb396fca9af7816f97b22b8bf1b01951e271a75f1a640dfc64955696dc1c0b7d','01e59066a1f68aabc3a3de5219342335d30da8729c565e0e1a5e1c5905799075','0c8589dedcc95c37b524b7e135b4165fde13983814633054d88633822676acaa');
INSERT INTO blocks VALUES(310068,'9280e7297ef6313341bc81787a36acfc9af58f83a415afff5e3154f126cf52b5',310068000,NULL,NULL,'6cbc681ed90e676cc507d07120888bd4c8759873a0b9215f721a0ce707070086','8a71503dfd4acb4efeee63baa639239f52e19db81579aa62498a62c69abac900','09e8209671604c53cb3520fdf327bb59544d3f10fa9ca7a52e06e1711acefb3f');
INSERT INTO blocks VALUES(310069,'486351f0655bf594ffaab1980cff17353b640b63e9c27239109addece189a6f7',310069000,NULL,NULL,'7cb734eb3e24e92de8915a6bea42b6ef721251c481ac9ec751cdbdc08e110011','ee2f5979301f3a6aa52184ca43502d25de5f0b021961c6aa38dfc8322744f240','13e906871a413ef7ccf224bb676fa3a459e1d09e380ee96a97217a5a5f744b3f');
INSERT INTO blocks VALUES(310070,'8739e99f4dee8bebf1332f37f49a125348b40b93b74fe35579dd52bfba4fa7e5',310070000,NULL,NULL,'7b57a4d1ce0995a938e174e52a096cc9829a0ddd59f698ed04d8b43371a78126','6a239c6056a0daac48e0115283555b6eca57a73fcf2765ec1b1c420696e0d13d','e53868ade1de82f0cf3f69d6f2b1a443c9857272da0d5ac9eb7c687ccd12422b');
INSERT INTO blocks VALUES(310071,'7a099aa1bba0ead577f1e44f35263a1f115ed6a868c98d4dd71609072ae7f80b',310071000,NULL,NULL,'f46f820a64ced97ccf68a56c048459de0b2855ecd4299e447c4b630913ce1749','fc14b471ab91dad6225a317630241f54ac80dbf8cb0a477607d7baa2aeb7b65e','4445d4936d1bddab6d94faad10e6a6e4a3d8bb4a2293e64583e66cb389d50ef4');
INSERT INTO blocks VALUES(310072,'7b17ecedc07552551b8129e068ae67cb176ca766ea3f6df74b597a94e3a7fc8a',310072000,NULL,NULL,'878239189ae0afa759af5e59db8a17fd17c0c9a2c017384fd2d0ca789e738050','afe1768a80b1f6bfbac8d70c8b1540fd0f29a5b9cb217892b9c27a600883ec23','edd1d9ec6112204eb42a7a5ebbbc1564b440beaa6ccfe0c172c67fd0f5531da3');
INSERT INTO blocks VALUES(310073,'ee0fe3cc9b3a48a2746b6090b63b442b97ea6055d48edcf4b2288396764c6943',310073000,NULL,NULL,'d2d86823f727bc075138653a682373a9c76d21d48b5881968adb66042b501e53','cf25e00d8b71a471a272502d35bea86edc6b6f4f3007696b9dd6ad8e8b7ba449','bff4cb8e9e32980556460e74b5c84e83b2fb5d6508d78d90fac80b41ce8c1495');
INSERT INTO blocks VALUES(310074,'ceab38dfde01f711a187601731ad575d67cfe0b7dbc61dcd4f15baaef72089fb',310074000,NULL,NULL,'9fd098fcc7d71c0c46fc741ea278de92589c44a6efc4980ced53843193553ea8','aa2f6500c55a91c6e60bc83726dcead497f6ebac5fc1c9e1d617e9b80fd412ad','4347a4f8c8415829d03a369a960485acd1cb59fde668eda54556ab666afbc3d5');
INSERT INTO blocks VALUES(310075,'ef547198c6e36d829f117cfd7077ccde45158e3c545152225fa24dba7a26847b',310075000,NULL,NULL,'f1ad21f9b4134bc0225c26fb8969af3565c07997197a7ed9636c01f187f07042','2c4a227879535e2b8d221a392a65bc72e31ba9ab92a7ebcb4fa457b14c4ac917','e8d4a48da0d31309dae956ff38480e4416269ef3223932b87a8cf80bca68fe20');
INSERT INTO blocks VALUES(310076,'3b0499c2e8e8f0252c7288d4ecf66efc426ca37aad3524424d14c8bc6f8b0d92',310076000,NULL,NULL,'9a1f3de6b5a255720973fb0c93ae2bc8fe8936565140b8ae991b9d83f86a0002','090af81ac5442543708ddc3ed847050b17034d0d8b6ea5fd3339cc98ad37a06c','20996f575be115017a70db3e4f715ac4dda28706a179108497a3c24f14be8fce');
INSERT INTO blocks VALUES(310077,'d2adeefa9024ab3ff2822bc36acf19b6c647cea118cf15b86c6bc00c3322e7dd',310077000,NULL,NULL,'ab56d9f59575b2d8ecc4933bbfa1fb0cb81c7a6fe84c1ba81bdee40c3da13164','e6ad99dcc009e08d0f16ca57f906f3414e6a61c77043160039465ec0e40821ea','863fc1bec91de300ff6ee2ae260eee65a9e767aa28ad88577e7ee0162d83070d');
INSERT INTO blocks VALUES(310078,'f6c17115ef0efe489c562bcda4615892b4d4b39db0c9791fe193d4922bd82cd6',310078000,NULL,NULL,'8399d461b5079a145c716f8f6004d2f7870fe93786bd944fa36ef27134c9517c','fe8df4cacc3eb35275182c2fe16c3b002fa780f067a5cff14196d43cd68ea5fc','47058784fe19d7d6ac754afe731e12de26802e9bf0b3902dddbbfb28927ab89c');
INSERT INTO blocks VALUES(310079,'f2fbd2074d804e631db44cb0fb2e1db3fdc367e439c21ffc40d73104c4d7069c',310079000,NULL,NULL,'b6696a1511704128bbd5ec2c80a1d7d8d3bda6b959f1a674537ace152cb7f8bc','912f6a9f27e810a69a30288979d630696179f6532963a9650c87f35b4450af48','53f3f85225c56bcffa27725beae6ca0e0491a62533b6b8868c54bf7097571017');
INSERT INTO blocks VALUES(310080,'42943b914d9c367000a78b78a544cc4b84b1df838aadde33fe730964a89a3a6c',310080000,NULL,NULL,'9aea0f996c36a815e4103b86ee7fc9be784d7c72549e54d04d84cf7fb8adfb78','d60827fd702c90182558068b501723401e4c68570d8ef822aeeb93c968b75439','67a24cee6ada7b400c602e7d24d9472dbddf6dff7bc0684149be61f9532221de');
INSERT INTO blocks VALUES(310081,'6554f9d307976249e7b7e260e08046b3b55d318f8b6af627fed5be3063f123c4',310081000,NULL,NULL,'7571b554c5600796b60982bb6df3517eed517a2a3627f8383b92a073cc4a5872','3e1d2f172f564c5c1560021647fe6f2a7af4b1a228ede09ec382f8c52cd32189','9a0de2f0be6f20ce07fe93afec8f7a773a1f477799e5165ed92975cc5891a1e3');
INSERT INTO blocks VALUES(310082,'4f1ef91b1dcd575f8ac2e66a67715500cbca154bd6f3b8148bb7015a6aa6c644',310082000,NULL,NULL,'b2507a73ff4f6998582daac667c457308ba78744e3d1d7533c0232092e3eab1f','ab7bb74f9509be2ed38c525278fa96d74254a47bc0a87e62216f951165dddbc8','dafa03f5cb09538f8a5ab54fe1118cab1f9e947bbe119689cc1730829849c30d');
INSERT INTO blocks VALUES(310083,'9b1f6fd6ff9b0dc4e37603cfb0625f49067c775b99e12492afd85392d3c8d850',310083000,NULL,NULL,'18566f22ffb9bc5f98712ef3234f8da84f8f3e382007b23c3bb8e6c910043746','5479699c2012ed1c8780876a9fda9fedb891cb52ec087843a44f3f14348b694e','782b035e22b11c4b988a43f6e593f44398afeb4c3ed9d69d5da0a1fca6ea05a1');
INSERT INTO blocks VALUES(310084,'1e0972523e80306441b9f4157f171716199f1428db2e818a7f7817ccdc8859e3',310084000,NULL,NULL,'72c44bddd5b54657623692e444bf893ca7b6d8da992c274bcbaa37c6db903825','09512a891f0194a532b4731406ac1ff87306b7653a795a714723c6a0a7213c8a','b6db306c87a58ee377b278730e6c7d8f83829e86a43b030e7cf6432ae529f790');
INSERT INTO blocks VALUES(310085,'c5b6e9581831e3bc5848cd7630c499bca26d9ece5156d36579bdb72d54817e34',310085000,NULL,NULL,'1ddc441adb4b262862caf5b811b2375bd376d9b5d7b8ee251c4337478833cde9','39a28d6dd9dec325215e5f3cd51f87fc652398b5e3256d0a8f2ad7e5209fe5b2','c4adec06eb491f5b097507566e6fe7ac1866e114e1a55a0bcc0950ebe09fb7c6');
INSERT INTO blocks VALUES(310086,'080c1dc55a4ecf4824cf9840602498cfc35b5f84099f50b71b45cb63834c7a78',310086000,NULL,NULL,'b59447846d380cb8d32639ca13e6e396b68b18483f70b6380296bff65dced3d2','87c3632d4f8ac5685380e6f8f61e8c886e89336a3779431b27fecfed48e21d3b','0bf3877569586c835b9a83212971da265af6d9c29d7bed54c8fca21b24e085f1');
INSERT INTO blocks VALUES(310087,'4ec8cb1c38b22904e8087a034a6406b896eff4dd28e7620601c6bddf82e2738c',310087000,NULL,NULL,'54a1c32d20665e7ff92ea43451ff2e59a98136ad7da576fa6b2614dda700b707','8c9c51e818d617cf6e701b26668ff12cbeb5f68ae90b5f9e8cb7319d3c109daa','8617cbf2aa306835f6511174ad2d7f4b8e96701228928b8fcee5b5ee269947b0');
INSERT INTO blocks VALUES(310088,'e945c815c433cbddd0bf8e66c5c23b51072483492acda98f5c2c201020a8c5b3',310088000,NULL,NULL,'f0bef715c366843e002c75992b8d50d82a3ea54f144350f158e862eb03cb45dd','83360ce6e8094726669ec42d06c0a10af938c23d8a21c729ec0f0c3907ebfa0b','5e36f65d03c365e3053c69baae77dc25d219106a063b1f100b6f640dc72298bf');
INSERT INTO blocks VALUES(310089,'0382437f895ef3e7e38bf025fd4f606fd44d4bbd6aea71dbdc4ed11a7cd46f33',310089000,NULL,NULL,'0a4ce98b783b97f81fff9ab73d7a7091087e8511ebb425c81ccf60c3f9edbfd6','b14e6bff6f32357eacf7a5332815cc862b7600bd168de28bf63c6f8281ce4ab9','d14459b0642114f54e8f3b77988fdb71a43b14bb545abc02d8bff152c9b5da52');
INSERT INTO blocks VALUES(310090,'b756db71dc037b5a4582de354a3347371267d31ebda453e152f0a13bb2fae969',310090000,NULL,NULL,'f3b6781eebab3a6928791cf281d4ae7cb4f7fb59c6ae7575eba253e6ec6e447b','11c71c19e62ab2baa724cecbafdaac9fb58a9341b253f61b8034f45e4da32030','19f04a541e507984ea43583713bde3b0b6c32ee8e683d3207689034f40b6dc7a');
INSERT INTO blocks VALUES(310091,'734a9aa485f36399d5efb74f3b9c47f8b5f6fd68c9967f134b14cfe7e2d7583c',310091000,NULL,NULL,'14261b6b340632c469847700cee16c0163a7f8cad4dac7ad4555efeb5f3235fb','f8e0b58e638e2460dfe4f07463b12a703512fd1bbb55b3a9f9d2d2396e190006','f527152fcb0f6c99bae240fa729b3ebd1ddf74f8e49e8d74d356d0ddefcfff74');
INSERT INTO blocks VALUES(310092,'56386beb65f9228740d4ad43a1c575645f6daf59e0dd9f22551c59215b5e8c3d',310092000,NULL,NULL,'3c033a502e1890e8a3c697e354cd1769e4300ce7f62ee7ac47a7201e1ad5de2c','3828fb580f50c657293dd8b0f060ac1ff3571d96f854d48b7ecf1f9ea4b3c815','93d4a0c82ab9c594f293d6aa801745d9345ebd193e0c791a1eb2a7a6b3d98d0f');
INSERT INTO blocks VALUES(310093,'a74a2425f2f4be24bb5f715173e6756649e1cbf1b064aeb1ef60e0b94b418ddc',310093000,NULL,NULL,'acc1dc4b7ec10c0989af833b57640be486035d76f74b57a50b023fb60f418be2','02238b7b4ab236edc57919fcbfe2247f92c04c396cc4e70df7e2ab0646b69909','ab8ce8aa140d6ec81d65b7f9dc61f5b21dfa5d774fb7125c42f53bc0fc3791e9');
INSERT INTO blocks VALUES(310094,'2a8f976f20c4e89ff01071915ac96ee35192d54df3a246bf61fd4a0cccfb5b23',310094000,NULL,NULL,'1443d97efeeb04291e117b152f1e18537035a59c80fabb574577cb3e66e5db59','045a4cadfab33795e26587405b596f86caa7abd0a16b87bbed1eaa70b9af016a','b0bbe6956e77d924853b1492efc4ae5d85b6c7ef9245b284eea52ceee2b5a66b');
INSERT INTO blocks VALUES(310095,'bed0fa40c9981223fb40b3be8124ca619edc9dd34d0c907369477ea92e5d2cd2',310095000,NULL,NULL,'1c74208da191b965f52006e577c3f4df30f29b36b1d137ab457bbfe30737285d','550f964afe7d7efadc9d1459b4894b5f1a655ed7ce76fb0e49bdf8b6e4fa3862','0849e04f7ff0037c4f03a50ee17881c5c56632e1b0ac92f9374a6fefcbb9d17e');
INSERT INTO blocks VALUES(310096,'306aeec3db435fabffdf88c2f26ee83caa4c2426375a33daa2be041dbd27ea2f',310096000,NULL,NULL,'662e1b232c5afeba4df756a31d7b63f7f33dbb4aa752abbea9f0b57f1c7c4295','99eac78368ee67168ee953457851409d41728996d64bba28b6e98d81c3ab1524','fcdf54628169365d282ff4e6b4e9ff6f018b9acfb074a66897b90bc3b6b9bc43');
INSERT INTO blocks VALUES(310097,'13e8e16e67c7cdcc80d477491e554b43744f90e8e1a9728439a11fab42cefadf',310097000,NULL,NULL,'8a1b60657764a35ce95c9e215600f63f0fc8c4933c682ea017553010743c97a2','c8d4be7d0f2a35e480690ad45d8ac312fcac27f515b21499210f50f6e69f3cb8','239bbc4d5d6db3c67b389f1e9d6a5aabdac53b35c1566b02e2d23960b517468b');
INSERT INTO blocks VALUES(310098,'ca5bca4b5ec4fa6183e05176abe921cff884c4e20910fab55b603cef48dc3bca',310098000,NULL,NULL,'c2e25d20f3c50a67a4268d9aa3e386c92e5217cf8f106d2affaae19e49b48828','9a2ce928416fd594c0d7ae894d0b9005f5169241eac9f7a7e73cac829e275c4b','6595e4fa2eb299d71dbb9610e5767162a2f901c81e56dc278a81ca251445d01a');
INSERT INTO blocks VALUES(310099,'3c4c2279cd7de0add5ec469648a845875495a7d54ebfb5b012dcc5a197b7992a',310099000,NULL,NULL,'bd7479caeb388072138c99d19624e495200df1bf02f47caf0ae8a5007fd9dfce','bf3d114c068fe2b308aea3f2bf334142e91c35f7c0a2550324dd66c6572eb0ab','32e247f1bcd4b51baa374437324b0e440969a392a53c2d7795d6e287f8836fd4');
INSERT INTO blocks VALUES(310100,'96925c05b3c7c80c716f5bef68d161c71d044252c766ca0e3f17f255764242cb',310100000,NULL,NULL,'ddb8394df96a37e0127c8894e669072cb195ac953e2a3e922b95bf40804820b6','ed26cd190dc12e7ca3837559e72407d04f1c3c05e9414ecfbfc876afb74bda52','0e4af3ac6b721e865fa18b360e915b9918cad61cdbb9044937ac52b3537334ef');
INSERT INTO blocks VALUES(310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,NULL,NULL,'3ed7694459a57281ba8e4159ce156333aae4b596aa3ab5193ea6c1901f2c9667','72e3d1c4a5ec536a1a271c45b6d1385f59f7293745214c20661d108d4100f25e','5945a0ab17157211dbf098d6fdd58bf9b9844ac78d7a7e28ea27cfc6ec98ff9a');
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
INSERT INTO broadcasts VALUES(12,'1a5b6320346fcb5f7b59ce88553ef92738d2f5ba0a7477e898df85b2730a0f1a',310011,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1388000000,100.0,99999999,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(19,'16a5d04f339e5765125c4b2fdda91e45e135e44df489b97805b5d3bae50a6485',310018,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1388000050,99.86166,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(20,'65c96e80d7bfe2c7b00086196a7fc38889d91f5907658a6bbe795c89ef90ce37',310019,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1388000101,100.343,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(21,'43232e4a2e0863cde59fb404a8da059c01cc8afb6c88b509f77d6cbfa02d187e',310020,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1388000201,2.0,5000000,'Unit Test',0,'valid');
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
INSERT INTO btcpays VALUES(5,'90eb885df58d93c1d5fdc86a88257db69e6ac7904409929733250b3f7bbe5613',310004,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',50000000,'04d5809f0085bf2655c500a8c65d6d8b42dd373160fb431af05792b0f30b63a6_98ef3d31d1777ad18801e94eef03d4314911ac03d7a82483b40614ea5cf80e52','valid');
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
INSERT INTO burns VALUES(1,'63f8a75a06328d984c928bdcf6bebb20d9c2b154712f1d03041d07c6f319efd2',310000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',62000000,93000000000,'valid');
INSERT INTO burns VALUES(23,'ec9788fbae83a6cdf980d5373d85911a27447410efa4b11997fefcc41bc89caa',310022,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',38000000,56999887262,'valid');
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
INSERT INTO credits VALUES(310000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',93000000000,'burn','63f8a75a06328d984c928bdcf6bebb20d9c2b154712f1d03041d07c6f319efd2');
INSERT INTO credits VALUES(310001,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',50000000,'send','5849bd15f5a73840e4babd220ed450d0f46128479d6bb7eaf9f4e98a409c97d4');
INSERT INTO credits VALUES(310004,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',100000000,'btcpay','90eb885df58d93c1d5fdc86a88257db69e6ac7904409929733250b3f7bbe5613');
INSERT INTO credits VALUES(310005,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',1000000000,'issuance','1ba2a0b4ee8543976aab629c78103c0ba86c60250c11d51f9bc40676487283b7');
INSERT INTO credits VALUES(310006,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC',100000,'issuance','af11bc43c2e85702af8be0a4558467839dbf917257fe6422dc2ae88250111b37');
INSERT INTO credits VALUES(310007,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBB',4000000,'send','30bfb2793bd1a65e5993edb9c3268db31bc96b8bf1f6e3bef037da4f4e93bc65');
INSERT INTO credits VALUES(310008,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',526,'send','7da21bef68887cb50f8582fc0dda69ee5414993450dfab7437891b5a1117e849');
INSERT INTO credits VALUES(310009,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',24,'dividend','f3cb8e3c39c261fef8d71c5222b8864bee3c7c1c4ec342430cff08945273779f');
INSERT INTO credits VALUES(310010,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',420800,'dividend','15741649c83a752d61662fe00bd28b1c33dfd7816cb92225a0a61008f9059a59');
INSERT INTO credits VALUES(310013,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',4250000,'filled','a067f79057992245507ea08e901e623918be2b0eb2d178e35b01f36da2d30a33');
INSERT INTO credits VALUES(310014,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',5000000,'cancel order','98ef3d31d1777ad18801e94eef03d4314911ac03d7a82483b40614ea5cf80e52');
INSERT INTO credits VALUES(310015,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',0,'filled','62ece578c6760773bd4252922a7a0af87da1a1c308f32423e20cf49a369ea0a2');
INSERT INTO credits VALUES(310015,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',0,'filled','62ece578c6760773bd4252922a7a0af87da1a1c308f32423e20cf49a369ea0a2');
INSERT INTO credits VALUES(310017,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',0,'filled','479b0fbec468381f1e27332755b12a69800680379d0037e02f641265a8beb183');
INSERT INTO credits VALUES(310017,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',0,'filled','479b0fbec468381f1e27332755b12a69800680379d0037e02f641265a8beb183');
INSERT INTO credits VALUES(310018,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',59137500,'bet settled: liquidated for bear','16a5d04f339e5765125c4b2fdda91e45e135e44df489b97805b5d3bae50a6485');
INSERT INTO credits VALUES(310018,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',3112500,'feed fee','16a5d04f339e5765125c4b2fdda91e45e135e44df489b97805b5d3bae50a6485');
INSERT INTO credits VALUES(310019,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',159300000,'bet settled','65c96e80d7bfe2c7b00086196a7fc38889d91f5907658a6bbe795c89ef90ce37');
INSERT INTO credits VALUES(310019,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',315700000,'bet settled','65c96e80d7bfe2c7b00086196a7fc38889d91f5907658a6bbe795c89ef90ce37');
INSERT INTO credits VALUES(310019,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',25000000,'feed fee','65c96e80d7bfe2c7b00086196a7fc38889d91f5907658a6bbe795c89ef90ce37');
INSERT INTO credits VALUES(310020,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',1330000000,'bet settled: for notequal','43232e4a2e0863cde59fb404a8da059c01cc8afb6c88b509f77d6cbfa02d187e');
INSERT INTO credits VALUES(310020,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',70000000,'feed fee','43232e4a2e0863cde59fb404a8da059c01cc8afb6c88b509f77d6cbfa02d187e');
INSERT INTO credits VALUES(310022,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',56999887262,'burn','ec9788fbae83a6cdf980d5373d85911a27447410efa4b11997fefcc41bc89caa');
INSERT INTO credits VALUES(310023,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',8500000,'recredit wager remaining','1075391072b01264a783bf31205a83abdf7356c8c405753d3ef8599f852df887');
INSERT INTO credits VALUES(310023,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',10000,'send','53290702a54a5c19d9a5e2fc1942c2381a4d2283f30d645579b982ae0dbb7fcc');
INSERT INTO credits VALUES(310032,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',50000000,'cancel order','cd79f155a7a8b7737cf959cdc347db22f2f38288261842997e13844a09f6f2ee');
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
INSERT INTO debits VALUES(310001,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',50000000,'send','5849bd15f5a73840e4babd220ed450d0f46128479d6bb7eaf9f4e98a409c97d4');
INSERT INTO debits VALUES(310003,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',105000000,'open order','98ef3d31d1777ad18801e94eef03d4314911ac03d7a82483b40614ea5cf80e52');
INSERT INTO debits VALUES(310005,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',50000000,'issuance fee','1ba2a0b4ee8543976aab629c78103c0ba86c60250c11d51f9bc40676487283b7');
INSERT INTO debits VALUES(310006,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',50000000,'issuance fee','af11bc43c2e85702af8be0a4558467839dbf917257fe6422dc2ae88250111b37');
INSERT INTO debits VALUES(310007,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',4000000,'send','30bfb2793bd1a65e5993edb9c3268db31bc96b8bf1f6e3bef037da4f4e93bc65');
INSERT INTO debits VALUES(310008,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC',526,'send','7da21bef68887cb50f8582fc0dda69ee5414993450dfab7437891b5a1117e849');
INSERT INTO debits VALUES(310009,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',24,'dividend','f3cb8e3c39c261fef8d71c5222b8864bee3c7c1c4ec342430cff08945273779f');
INSERT INTO debits VALUES(310009,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',20000,'dividend fee','f3cb8e3c39c261fef8d71c5222b8864bee3c7c1c4ec342430cff08945273779f');
INSERT INTO debits VALUES(310010,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',420800,'dividend','15741649c83a752d61662fe00bd28b1c33dfd7816cb92225a0a61008f9059a59');
INSERT INTO debits VALUES(310010,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',20000,'dividend fee','15741649c83a752d61662fe00bd28b1c33dfd7816cb92225a0a61008f9059a59');
INSERT INTO debits VALUES(310012,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',50000000,'bet','1075391072b01264a783bf31205a83abdf7356c8c405753d3ef8599f852df887');
INSERT INTO debits VALUES(310013,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',25000000,'bet','a067f79057992245507ea08e901e623918be2b0eb2d178e35b01f36da2d30a33');
INSERT INTO debits VALUES(310014,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',150000000,'bet','040e03dfdef2df24411a077cfe5f90f3311bbb82bb3783ea2d7e6f484afd3e2b');
INSERT INTO debits VALUES(310015,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',350000000,'bet','62ece578c6760773bd4252922a7a0af87da1a1c308f32423e20cf49a369ea0a2');
INSERT INTO debits VALUES(310016,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',750000000,'bet','578d8026c9a3a9173fdb7d5f10c6d5e7d49f375edf5fd8b3f29ccb37a8b42d1f');
INSERT INTO debits VALUES(310017,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',650000000,'bet','479b0fbec468381f1e27332755b12a69800680379d0037e02f641265a8beb183');
INSERT INTO debits VALUES(310021,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',50000000,'open order','cd79f155a7a8b7737cf959cdc347db22f2f38288261842997e13844a09f6f2ee');
INSERT INTO debits VALUES(310023,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC',10000,'send','53290702a54a5c19d9a5e2fc1942c2381a4d2283f30d645579b982ae0dbb7fcc');
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
INSERT INTO dividends VALUES(10,'f3cb8e3c39c261fef8d71c5222b8864bee3c7c1c4ec342430cff08945273779f',310009,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB','XCP',600,20000,'valid');
INSERT INTO dividends VALUES(11,'15741649c83a752d61662fe00bd28b1c33dfd7816cb92225a0a61008f9059a59',310010,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC','XCP',800,20000,'valid');
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
INSERT INTO issuances VALUES(6,'1ba2a0b4ee8543976aab629c78103c0ba86c60250c11d51f9bc40676487283b7',0,310005,'BBBB',1000000000,1,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,0,0,0.0,'',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(7,'af11bc43c2e85702af8be0a4558467839dbf917257fe6422dc2ae88250111b37',0,310006,'BBBC',100000,0,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,0,0,0.0,'',50000000,0,'valid',NULL,0);
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
INSERT INTO order_expirations VALUES(3,'04d5809f0085bf2655c500a8c65d6d8b42dd373160fb431af05792b0f30b63a6','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',310013);
INSERT INTO order_expirations VALUES(4,'98ef3d31d1777ad18801e94eef03d4314911ac03d7a82483b40614ea5cf80e52','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',310014);
INSERT INTO order_expirations VALUES(22,'cd79f155a7a8b7737cf959cdc347db22f2f38288261842997e13844a09f6f2ee','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',310032);
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
INSERT INTO order_matches VALUES('04d5809f0085bf2655c500a8c65d6d8b42dd373160fb431af05792b0f30b63a6_98ef3d31d1777ad18801e94eef03d4314911ac03d7a82483b40614ea5cf80e52',3,'04d5809f0085bf2655c500a8c65d6d8b42dd373160fb431af05792b0f30b63a6','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',4,'98ef3d31d1777ad18801e94eef03d4314911ac03d7a82483b40614ea5cf80e52','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BTC',50000000,'XCP',100000000,310002,310003,310003,10,10,310023,857142,'completed');
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
INSERT INTO orders VALUES(3,'04d5809f0085bf2655c500a8c65d6d8b42dd373160fb431af05792b0f30b63a6',310002,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BTC',50000000,0,'XCP',100000000,0,10,310012,0,0,1000000,142858,'expired');
INSERT INTO orders VALUES(4,'98ef3d31d1777ad18801e94eef03d4314911ac03d7a82483b40614ea5cf80e52',310003,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',105000000,5000000,'BTC',50000000,0,10,310013,900000,42858,6800,6800,'expired');
INSERT INTO orders VALUES(22,'cd79f155a7a8b7737cf959cdc347db22f2f38288261842997e13844a09f6f2ee',310021,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',50000000,50000000,'XCP',50000000,50000000,10,310031,0,0,6800,6800,'expired');
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
INSERT INTO sends VALUES(2,'5849bd15f5a73840e4babd220ed450d0f46128479d6bb7eaf9f4e98a409c97d4',310001,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',50000000,'valid',0,NULL);
INSERT INTO sends VALUES(8,'30bfb2793bd1a65e5993edb9c3268db31bc96b8bf1f6e3bef037da4f4e93bc65',310007,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBB',4000000,'valid',0,NULL);
INSERT INTO sends VALUES(9,'7da21bef68887cb50f8582fc0dda69ee5414993450dfab7437891b5a1117e849',310008,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',526,'valid',0,NULL);
INSERT INTO sends VALUES(24,'53290702a54a5c19d9a5e2fc1942c2381a4d2283f30d645579b982ae0dbb7fcc',310023,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',10000,'valid',0,NULL);
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
INSERT INTO transactions VALUES(1,'63f8a75a06328d984c928bdcf6bebb20d9c2b154712f1d03041d07c6f319efd2',310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
INSERT INTO transactions VALUES(2,'5849bd15f5a73840e4babd220ed450d0f46128479d6bb7eaf9f4e98a409c97d4',310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3',1000,7650,X'0000000000000000000000010000000002FAF080',1);
INSERT INTO transactions VALUES(3,'04d5809f0085bf2655c500a8c65d6d8b42dd373160fb431af05792b0f30b63a6',310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,1000000,X'0000000A00000000000000000000000002FAF08000000000000000010000000005F5E100000A0000000000000000',1);
INSERT INTO transactions VALUES(4,'98ef3d31d1777ad18801e94eef03d4314911ac03d7a82483b40614ea5cf80e52',310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000000A00000000000000010000000006422C4000000000000000000000000002FAF080000A00000000000DBBA0',1);
INSERT INTO transactions VALUES(5,'90eb885df58d93c1d5fdc86a88257db69e6ac7904409929733250b3f7bbe5613',310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',50000000,9675,X'0000000B04D5809F0085BF2655C500A8C65D6D8B42DD373160FB431AF05792B0F30B63A698EF3D31D1777AD18801E94EEF03D4314911AC03D7A82483B40614EA5CF80E52',1);
INSERT INTO transactions VALUES(6,'1ba2a0b4ee8543976aab629c78103c0ba86c60250c11d51f9bc40676487283b7',310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'000000140000000000004767000000003B9ACA000100000000000000000000',1);
INSERT INTO transactions VALUES(7,'af11bc43c2e85702af8be0a4558467839dbf917257fe6422dc2ae88250111b37',310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'00000014000000000000476800000000000186A00000000000000000000000',1);
INSERT INTO transactions VALUES(8,'30bfb2793bd1a65e5993edb9c3268db31bc96b8bf1f6e3bef037da4f4e93bc65',310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3',1000,7650,X'00000000000000000000476700000000003D0900',1);
INSERT INTO transactions VALUES(9,'7da21bef68887cb50f8582fc0dda69ee5414993450dfab7437891b5a1117e849',310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3',1000,7650,X'000000000000000000004768000000000000020E',1);
INSERT INTO transactions VALUES(10,'f3cb8e3c39c261fef8d71c5222b8864bee3c7c1c4ec342430cff08945273779f',310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'00000032000000000000025800000000000047670000000000000001',1);
INSERT INTO transactions VALUES(11,'15741649c83a752d61662fe00bd28b1c33dfd7816cb92225a0a61008f9059a59',310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'00000032000000000000032000000000000047680000000000000001',1);
INSERT INTO transactions VALUES(12,'1a5b6320346fcb5f7b59ce88553ef92738d2f5ba0a7477e898df85b2730a0f1a',310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000001E52BB3300405900000000000005F5E0FF09556E69742054657374',1);
INSERT INTO transactions VALUES(13,'1075391072b01264a783bf31205a83abdf7356c8c405753d3ef8599f852df887',310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1000,7650,X'00000028000052BB33640000000002FAF08000000000017D7840000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(14,'a067f79057992245507ea08e901e623918be2b0eb2d178e35b01f36da2d30a33',310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1000,7650,X'00000028000152BB336400000000017D78400000000002793D60000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(15,'040e03dfdef2df24411a077cfe5f90f3311bbb82bb3783ea2d7e6f484afd3e2b',310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1000,7650,X'00000028000052BB33640000000008F0D1800000000014DC93800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(16,'62ece578c6760773bd4252922a7a0af87da1a1c308f32423e20cf49a369ea0a2',310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1000,7650,X'00000028000152BB33640000000014DC93800000000008F0D1800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(17,'578d8026c9a3a9173fdb7d5f10c6d5e7d49f375edf5fd8b3f29ccb37a8b42d1f',310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1000,7650,X'00000028000252BB33C8000000002CB417800000000026BE36803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(18,'479b0fbec468381f1e27332755b12a69800680379d0037e02f641265a8beb183',310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1000,7650,X'00000028000352BB33C80000000026BE3680000000002CB417803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(19,'16a5d04f339e5765125c4b2fdda91e45e135e44df489b97805b5d3bae50a6485',310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000001E52BB33324058F7256FFC115E004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(20,'65c96e80d7bfe2c7b00086196a7fc38889d91f5907658a6bbe795c89ef90ce37',310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000001E52BB3365405915F3B645A1CB004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(21,'43232e4a2e0863cde59fb404a8da059c01cc8afb6c88b509f77d6cbfa02d187e',310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000001E52BB33C94000000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(22,'cd79f155a7a8b7737cf959cdc347db22f2f38288261842997e13844a09f6f2ee',310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000000A00000000000047670000000002FAF08000000000000000010000000002FAF080000A0000000000000000',1);
INSERT INTO transactions VALUES(23,'ec9788fbae83a6cdf980d5373d85911a27447410efa4b11997fefcc41bc89caa',310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','mvCounterpartyXXXXXXXXXXXXXXW24Hef',100000000,5625,X'',1);
INSERT INTO transactions VALUES(24,'53290702a54a5c19d9a5e2fc1942c2381a4d2283f30d645579b982ae0dbb7fcc',310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3',1000,7650,X'0000000000000000000047680000000000002710',1);
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
INSERT INTO undolog VALUES(4,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=93000000000 WHERE rowid=1');
INSERT INTO undolog VALUES(5,'DELETE FROM debits WHERE rowid=1');
INSERT INTO undolog VALUES(6,'DELETE FROM balances WHERE rowid=2');
INSERT INTO undolog VALUES(7,'DELETE FROM credits WHERE rowid=2');
INSERT INTO undolog VALUES(8,'DELETE FROM sends WHERE rowid=1');
INSERT INTO undolog VALUES(9,'DELETE FROM orders WHERE rowid=1');
INSERT INTO undolog VALUES(10,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92950000000 WHERE rowid=1');
INSERT INTO undolog VALUES(11,'DELETE FROM debits WHERE rowid=2');
INSERT INTO undolog VALUES(12,'DELETE FROM orders WHERE rowid=2');
INSERT INTO undolog VALUES(13,'UPDATE orders SET tx_index=3,tx_hash=''04d5809f0085bf2655c500a8c65d6d8b42dd373160fb431af05792b0f30b63a6'',block_index=310002,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''BTC'',give_quantity=50000000,give_remaining=50000000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=10,expire_index=310012,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(14,'UPDATE orders SET tx_index=4,tx_hash=''98ef3d31d1777ad18801e94eef03d4314911ac03d7a82483b40614ea5cf80e52'',block_index=310003,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''XCP'',give_quantity=105000000,give_remaining=105000000,get_asset=''BTC'',get_quantity=50000000,get_remaining=50000000,expiration=10,expire_index=310013,fee_required=900000,fee_required_remaining=900000,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(15,'DELETE FROM order_matches WHERE rowid=1');
INSERT INTO undolog VALUES(16,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92845000000 WHERE rowid=1');
INSERT INTO undolog VALUES(17,'DELETE FROM credits WHERE rowid=3');
INSERT INTO undolog VALUES(18,'UPDATE order_matches SET id=''04d5809f0085bf2655c500a8c65d6d8b42dd373160fb431af05792b0f30b63a6_98ef3d31d1777ad18801e94eef03d4314911ac03d7a82483b40614ea5cf80e52'',tx0_index=3,tx0_hash=''04d5809f0085bf2655c500a8c65d6d8b42dd373160fb431af05792b0f30b63a6'',tx0_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx1_index=4,tx1_hash=''98ef3d31d1777ad18801e94eef03d4314911ac03d7a82483b40614ea5cf80e52'',tx1_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',forward_asset=''BTC'',forward_quantity=50000000,backward_asset=''XCP'',backward_quantity=100000000,tx0_block_index=310002,tx1_block_index=310003,block_index=310003,tx0_expiration=10,tx1_expiration=10,match_expire_index=310023,fee_paid=857142,status=''pending'' WHERE rowid=1');
INSERT INTO undolog VALUES(19,'DELETE FROM btcpays WHERE rowid=5');
INSERT INTO undolog VALUES(20,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92945000000 WHERE rowid=1');
INSERT INTO undolog VALUES(21,'DELETE FROM debits WHERE rowid=3');
INSERT INTO undolog VALUES(22,'DELETE FROM assets WHERE rowid=3');
INSERT INTO undolog VALUES(23,'DELETE FROM issuances WHERE rowid=1');
INSERT INTO undolog VALUES(24,'DELETE FROM balances WHERE rowid=3');
INSERT INTO undolog VALUES(25,'DELETE FROM credits WHERE rowid=4');
INSERT INTO undolog VALUES(26,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92895000000 WHERE rowid=1');
INSERT INTO undolog VALUES(27,'DELETE FROM debits WHERE rowid=4');
INSERT INTO undolog VALUES(28,'DELETE FROM assets WHERE rowid=4');
INSERT INTO undolog VALUES(29,'DELETE FROM issuances WHERE rowid=2');
INSERT INTO undolog VALUES(30,'DELETE FROM balances WHERE rowid=4');
INSERT INTO undolog VALUES(31,'DELETE FROM credits WHERE rowid=5');
INSERT INTO undolog VALUES(32,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''BBBB'',quantity=1000000000 WHERE rowid=3');
INSERT INTO undolog VALUES(33,'DELETE FROM debits WHERE rowid=5');
INSERT INTO undolog VALUES(34,'DELETE FROM balances WHERE rowid=5');
INSERT INTO undolog VALUES(35,'DELETE FROM credits WHERE rowid=6');
INSERT INTO undolog VALUES(36,'DELETE FROM sends WHERE rowid=2');
INSERT INTO undolog VALUES(37,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''BBBC'',quantity=100000 WHERE rowid=4');
INSERT INTO undolog VALUES(38,'DELETE FROM debits WHERE rowid=6');
INSERT INTO undolog VALUES(39,'DELETE FROM balances WHERE rowid=6');
INSERT INTO undolog VALUES(40,'DELETE FROM credits WHERE rowid=7');
INSERT INTO undolog VALUES(41,'DELETE FROM sends WHERE rowid=3');
INSERT INTO undolog VALUES(42,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92845000000 WHERE rowid=1');
INSERT INTO undolog VALUES(43,'DELETE FROM debits WHERE rowid=7');
INSERT INTO undolog VALUES(44,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92844999976 WHERE rowid=1');
INSERT INTO undolog VALUES(45,'DELETE FROM debits WHERE rowid=8');
INSERT INTO undolog VALUES(46,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3'',asset=''XCP'',quantity=50000000 WHERE rowid=2');
INSERT INTO undolog VALUES(47,'DELETE FROM credits WHERE rowid=8');
INSERT INTO undolog VALUES(48,'DELETE FROM dividends WHERE rowid=10');
INSERT INTO undolog VALUES(49,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92844979976 WHERE rowid=1');
INSERT INTO undolog VALUES(50,'DELETE FROM debits WHERE rowid=9');
INSERT INTO undolog VALUES(51,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92844559176 WHERE rowid=1');
INSERT INTO undolog VALUES(52,'DELETE FROM debits WHERE rowid=10');
INSERT INTO undolog VALUES(53,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3'',asset=''XCP'',quantity=50000024 WHERE rowid=2');
INSERT INTO undolog VALUES(54,'DELETE FROM credits WHERE rowid=9');
INSERT INTO undolog VALUES(55,'DELETE FROM dividends WHERE rowid=11');
INSERT INTO undolog VALUES(56,'DELETE FROM broadcasts WHERE rowid=12');
INSERT INTO undolog VALUES(57,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92844539176 WHERE rowid=1');
INSERT INTO undolog VALUES(58,'DELETE FROM debits WHERE rowid=11');
INSERT INTO undolog VALUES(59,'DELETE FROM bets WHERE rowid=1');
INSERT INTO undolog VALUES(60,'UPDATE orders SET tx_index=3,tx_hash=''04d5809f0085bf2655c500a8c65d6d8b42dd373160fb431af05792b0f30b63a6'',block_index=310002,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''BTC'',give_quantity=50000000,give_remaining=0,get_asset=''XCP'',get_quantity=100000000,get_remaining=0,expiration=10,expire_index=310012,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=142858,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(61,'DELETE FROM order_expirations WHERE rowid=3');
INSERT INTO undolog VALUES(62,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92794539176 WHERE rowid=1');
INSERT INTO undolog VALUES(63,'DELETE FROM debits WHERE rowid=12');
INSERT INTO undolog VALUES(64,'DELETE FROM bets WHERE rowid=2');
INSERT INTO undolog VALUES(65,'UPDATE bets SET tx_index=13,tx_hash=''1075391072b01264a783bf31205a83abdf7356c8c405753d3ef8599f852df887'',block_index=310012,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=0,deadline=1388000100,wager_quantity=50000000,wager_remaining=50000000,counterwager_quantity=25000000,counterwager_remaining=25000000,target_value=0.0,leverage=15120,expiration=10,expire_index=310022,fee_fraction_int=99999999,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(66,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92769539176 WHERE rowid=1');
INSERT INTO undolog VALUES(67,'DELETE FROM credits WHERE rowid=10');
INSERT INTO undolog VALUES(68,'UPDATE bets SET tx_index=14,tx_hash=''a067f79057992245507ea08e901e623918be2b0eb2d178e35b01f36da2d30a33'',block_index=310013,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=1,deadline=1388000100,wager_quantity=25000000,wager_remaining=25000000,counterwager_quantity=41500000,counterwager_remaining=41500000,target_value=0.0,leverage=15120,expiration=10,expire_index=310023,fee_fraction_int=99999999,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(69,'DELETE FROM bet_matches WHERE rowid=1');
INSERT INTO undolog VALUES(70,'UPDATE orders SET tx_index=4,tx_hash=''98ef3d31d1777ad18801e94eef03d4314911ac03d7a82483b40614ea5cf80e52'',block_index=310003,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''XCP'',give_quantity=105000000,give_remaining=5000000,get_asset=''BTC'',get_quantity=50000000,get_remaining=0,expiration=10,expire_index=310013,fee_required=900000,fee_required_remaining=42858,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(71,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92773789176 WHERE rowid=1');
INSERT INTO undolog VALUES(72,'DELETE FROM credits WHERE rowid=11');
INSERT INTO undolog VALUES(73,'DELETE FROM order_expirations WHERE rowid=4');
INSERT INTO undolog VALUES(74,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92778789176 WHERE rowid=1');
INSERT INTO undolog VALUES(75,'DELETE FROM debits WHERE rowid=13');
INSERT INTO undolog VALUES(76,'DELETE FROM bets WHERE rowid=3');
INSERT INTO undolog VALUES(77,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92628789176 WHERE rowid=1');
INSERT INTO undolog VALUES(78,'DELETE FROM debits WHERE rowid=14');
INSERT INTO undolog VALUES(79,'DELETE FROM bets WHERE rowid=4');
INSERT INTO undolog VALUES(80,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(81,'DELETE FROM credits WHERE rowid=12');
INSERT INTO undolog VALUES(82,'UPDATE bets SET tx_index=15,tx_hash=''040e03dfdef2df24411a077cfe5f90f3311bbb82bb3783ea2d7e6f484afd3e2b'',block_index=310014,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=0,deadline=1388000100,wager_quantity=150000000,wager_remaining=150000000,counterwager_quantity=350000000,counterwager_remaining=350000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310024,fee_fraction_int=99999999,status=''open'' WHERE rowid=3');
INSERT INTO undolog VALUES(83,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(84,'DELETE FROM credits WHERE rowid=13');
INSERT INTO undolog VALUES(85,'UPDATE bets SET tx_index=16,tx_hash=''62ece578c6760773bd4252922a7a0af87da1a1c308f32423e20cf49a369ea0a2'',block_index=310015,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=1,deadline=1388000100,wager_quantity=350000000,wager_remaining=350000000,counterwager_quantity=150000000,counterwager_remaining=150000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310025,fee_fraction_int=99999999,status=''open'' WHERE rowid=4');
INSERT INTO undolog VALUES(86,'DELETE FROM bet_matches WHERE rowid=2');
INSERT INTO undolog VALUES(87,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(88,'DELETE FROM debits WHERE rowid=15');
INSERT INTO undolog VALUES(89,'DELETE FROM bets WHERE rowid=5');
INSERT INTO undolog VALUES(90,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=91528789176 WHERE rowid=1');
INSERT INTO undolog VALUES(91,'DELETE FROM debits WHERE rowid=16');
INSERT INTO undolog VALUES(92,'DELETE FROM bets WHERE rowid=6');
INSERT INTO undolog VALUES(93,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(94,'DELETE FROM credits WHERE rowid=14');
INSERT INTO undolog VALUES(95,'UPDATE bets SET tx_index=17,tx_hash=''578d8026c9a3a9173fdb7d5f10c6d5e7d49f375edf5fd8b3f29ccb37a8b42d1f'',block_index=310016,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=2,deadline=1388000200,wager_quantity=750000000,wager_remaining=750000000,counterwager_quantity=650000000,counterwager_remaining=650000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310026,fee_fraction_int=99999999,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(96,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(97,'DELETE FROM credits WHERE rowid=15');
INSERT INTO undolog VALUES(98,'UPDATE bets SET tx_index=18,tx_hash=''479b0fbec468381f1e27332755b12a69800680379d0037e02f641265a8beb183'',block_index=310017,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=3,deadline=1388000200,wager_quantity=650000000,wager_remaining=650000000,counterwager_quantity=750000000,counterwager_remaining=750000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310027,fee_fraction_int=99999999,status=''open'' WHERE rowid=6');
INSERT INTO undolog VALUES(99,'DELETE FROM bet_matches WHERE rowid=3');
INSERT INTO undolog VALUES(100,'DELETE FROM broadcasts WHERE rowid=19');
INSERT INTO undolog VALUES(101,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(102,'DELETE FROM credits WHERE rowid=16');
INSERT INTO undolog VALUES(103,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90937926676 WHERE rowid=1');
INSERT INTO undolog VALUES(104,'DELETE FROM credits WHERE rowid=17');
INSERT INTO undolog VALUES(105,'DELETE FROM bet_match_resolutions WHERE rowid=1');
INSERT INTO undolog VALUES(106,'UPDATE bet_matches SET id=''1075391072b01264a783bf31205a83abdf7356c8c405753d3ef8599f852df887_a067f79057992245507ea08e901e623918be2b0eb2d178e35b01f36da2d30a33'',tx0_index=13,tx0_hash=''1075391072b01264a783bf31205a83abdf7356c8c405753d3ef8599f852df887'',tx0_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx1_index=14,tx1_hash=''a067f79057992245507ea08e901e623918be2b0eb2d178e35b01f36da2d30a33'',tx1_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=15120,forward_quantity=41500000,backward_quantity=20750000,tx0_block_index=310012,tx1_block_index=310013,block_index=310013,tx0_expiration=10,tx1_expiration=10,match_expire_index=310022,fee_fraction_int=99999999,status=''pending'' WHERE rowid=1');
INSERT INTO undolog VALUES(107,'DELETE FROM broadcasts WHERE rowid=20');
INSERT INTO undolog VALUES(108,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90941039176 WHERE rowid=1');
INSERT INTO undolog VALUES(109,'DELETE FROM credits WHERE rowid=18');
INSERT INTO undolog VALUES(110,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=91100339176 WHERE rowid=1');
INSERT INTO undolog VALUES(111,'DELETE FROM credits WHERE rowid=19');
INSERT INTO undolog VALUES(112,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=91416039176 WHERE rowid=1');
INSERT INTO undolog VALUES(113,'DELETE FROM credits WHERE rowid=20');
INSERT INTO undolog VALUES(114,'DELETE FROM bet_match_resolutions WHERE rowid=2');
INSERT INTO undolog VALUES(115,'UPDATE bet_matches SET id=''040e03dfdef2df24411a077cfe5f90f3311bbb82bb3783ea2d7e6f484afd3e2b_62ece578c6760773bd4252922a7a0af87da1a1c308f32423e20cf49a369ea0a2'',tx0_index=15,tx0_hash=''040e03dfdef2df24411a077cfe5f90f3311bbb82bb3783ea2d7e6f484afd3e2b'',tx0_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx1_index=16,tx1_hash=''62ece578c6760773bd4252922a7a0af87da1a1c308f32423e20cf49a369ea0a2'',tx1_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=5040,forward_quantity=150000000,backward_quantity=350000000,tx0_block_index=310014,tx1_block_index=310015,block_index=310015,tx0_expiration=10,tx1_expiration=10,match_expire_index=310024,fee_fraction_int=99999999,status=''pending'' WHERE rowid=2');
INSERT INTO undolog VALUES(116,'DELETE FROM broadcasts WHERE rowid=21');
INSERT INTO undolog VALUES(117,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=91441039176 WHERE rowid=1');
INSERT INTO undolog VALUES(118,'DELETE FROM credits WHERE rowid=21');
INSERT INTO undolog VALUES(119,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92771039176 WHERE rowid=1');
INSERT INTO undolog VALUES(120,'DELETE FROM credits WHERE rowid=22');
INSERT INTO undolog VALUES(121,'DELETE FROM bet_match_resolutions WHERE rowid=3');
INSERT INTO undolog VALUES(122,'UPDATE bet_matches SET id=''578d8026c9a3a9173fdb7d5f10c6d5e7d49f375edf5fd8b3f29ccb37a8b42d1f_479b0fbec468381f1e27332755b12a69800680379d0037e02f641265a8beb183'',tx0_index=17,tx0_hash=''578d8026c9a3a9173fdb7d5f10c6d5e7d49f375edf5fd8b3f29ccb37a8b42d1f'',tx0_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx1_index=18,tx1_hash=''479b0fbec468381f1e27332755b12a69800680379d0037e02f641265a8beb183'',tx1_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx0_bet_type=2,tx1_bet_type=3,feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',initial_value=100,deadline=1388000200,target_value=1.0,leverage=5040,forward_quantity=750000000,backward_quantity=650000000,tx0_block_index=310016,tx1_block_index=310017,block_index=310017,tx0_expiration=10,tx1_expiration=10,match_expire_index=310026,fee_fraction_int=99999999,status=''pending'' WHERE rowid=3');
INSERT INTO undolog VALUES(123,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''BBBB'',quantity=996000000 WHERE rowid=3');
INSERT INTO undolog VALUES(124,'DELETE FROM debits WHERE rowid=17');
INSERT INTO undolog VALUES(125,'DELETE FROM orders WHERE rowid=3');
INSERT INTO undolog VALUES(126,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92841039176 WHERE rowid=1');
INSERT INTO undolog VALUES(127,'DELETE FROM credits WHERE rowid=23');
INSERT INTO undolog VALUES(128,'DELETE FROM burns WHERE rowid=23');
INSERT INTO undolog VALUES(129,'UPDATE bets SET tx_index=13,tx_hash=''1075391072b01264a783bf31205a83abdf7356c8c405753d3ef8599f852df887'',block_index=310012,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=0,deadline=1388000100,wager_quantity=50000000,wager_remaining=8500000,counterwager_quantity=25000000,counterwager_remaining=4250000,target_value=0.0,leverage=15120,expiration=10,expire_index=310022,fee_fraction_int=99999999,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(130,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=149840926438 WHERE rowid=1');
INSERT INTO undolog VALUES(131,'DELETE FROM credits WHERE rowid=24');
INSERT INTO undolog VALUES(132,'DELETE FROM bet_expirations WHERE rowid=13');
INSERT INTO undolog VALUES(133,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''BBBC'',quantity=99474 WHERE rowid=4');
INSERT INTO undolog VALUES(134,'DELETE FROM debits WHERE rowid=18');
INSERT INTO undolog VALUES(135,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3'',asset=''BBBC'',quantity=526 WHERE rowid=6');
INSERT INTO undolog VALUES(136,'DELETE FROM credits WHERE rowid=25');
INSERT INTO undolog VALUES(137,'DELETE FROM sends WHERE rowid=4');
INSERT INTO undolog VALUES(138,'UPDATE orders SET tx_index=22,tx_hash=''cd79f155a7a8b7737cf959cdc347db22f2f38288261842997e13844a09f6f2ee'',block_index=310021,source=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''BBBB'',give_quantity=50000000,give_remaining=50000000,get_asset=''XCP'',get_quantity=50000000,get_remaining=50000000,expiration=10,expire_index=310031,fee_required=0,fee_required_remaining=0,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=3');
INSERT INTO undolog VALUES(139,'UPDATE balances SET address=''1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''BBBB'',quantity=946000000 WHERE rowid=3');
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
