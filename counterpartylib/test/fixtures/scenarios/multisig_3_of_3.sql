-- PRAGMA page_size=1024;
-- PRAGMA encoding='UTF-8';
-- PRAGMA auto_vacuum=NONE;
-- PRAGMA max_page_count=1073741823;

BEGIN TRANSACTION;

-- Table  assets
DROP TABLE IF EXISTS assets;
CREATE TABLE assets(
                      asset_id TEXT UNIQUE,
                      asset_name TEXT UNIQUE,
                      block_index INTEGER);
INSERT INTO assets VALUES('0','BTC',NULL);
INSERT INTO assets VALUES('1','XCP',NULL);
INSERT INTO assets VALUES('18279','BBBB',310005);
INSERT INTO assets VALUES('18280','BBBC',310006);
-- Triggers and indices on  assets
CREATE TRIGGER _assets_delete BEFORE DELETE ON assets BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO assets(rowid,asset_id,asset_name,block_index) VALUES('||old.rowid||','||quote(old.asset_id)||','||quote(old.asset_name)||','||quote(old.block_index)||')');
                            END;
CREATE TRIGGER _assets_insert AFTER INSERT ON assets BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM assets WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _assets_update AFTER UPDATE ON assets BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE assets SET asset_id='||quote(old.asset_id)||',asset_name='||quote(old.asset_name)||',block_index='||quote(old.block_index)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX id_idx ON assets (asset_id);
CREATE INDEX name_idx ON assets (asset_name);

-- Table  balances
DROP TABLE IF EXISTS balances;
CREATE TABLE balances(
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER);
INSERT INTO balances VALUES('3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',149849426438);
INSERT INTO balances VALUES('3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',50420824);
INSERT INTO balances VALUES('3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',996000000);
INSERT INTO balances VALUES('3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC',89474);
INSERT INTO balances VALUES('3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBB',4000000);
INSERT INTO balances VALUES('3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',10526);
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
INSERT INTO bet_expirations VALUES(13,'936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',310023);
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
INSERT INTO bet_match_resolutions VALUES('936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f_f964ef723387946ba8ea78589e5772370ad0909a985cd83a281d26f192fe6bbb',1,310018,'0',0,59137500,NULL,NULL,3112500);
INSERT INTO bet_match_resolutions VALUES('4a4eb3b3f79303bc6b2f37f049c145808164176f996edaddba16320b7eb0bf0d_6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300',1,310019,'1',159300000,315700000,NULL,NULL,25000000);
INSERT INTO bet_match_resolutions VALUES('cee3a40d67546871412e28c6210d70713b46597718ab72d4a62944555e51a2a8_f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0',5,310020,NULL,NULL,NULL,'NotEqual',1330000000,70000000);
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
INSERT INTO bet_matches VALUES('936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f_f964ef723387946ba8ea78589e5772370ad0909a985cd83a281d26f192fe6bbb',13,'936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',14,'f964ef723387946ba8ea78589e5772370ad0909a985cd83a281d26f192fe6bbb','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,1,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',100,1388000100,0.0,15120,41500000,20750000,310012,310013,310013,10,10,310022,5000000,'settled: liquidated for bear');
INSERT INTO bet_matches VALUES('4a4eb3b3f79303bc6b2f37f049c145808164176f996edaddba16320b7eb0bf0d_6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300',15,'4a4eb3b3f79303bc6b2f37f049c145808164176f996edaddba16320b7eb0bf0d','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',16,'6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,1,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',100,1388000100,0.0,5040,150000000,350000000,310014,310015,310015,10,10,310024,5000000,'settled');
INSERT INTO bet_matches VALUES('cee3a40d67546871412e28c6210d70713b46597718ab72d4a62944555e51a2a8_f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0',17,'cee3a40d67546871412e28c6210d70713b46597718ab72d4a62944555e51a2a8','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',18,'f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',2,3,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',100,1388000200,1.0,5040,750000000,650000000,310016,310017,310017,10,10,310026,5000000,'settled: for notequal');
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
INSERT INTO bets VALUES(13,'936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f',310012,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,1388000100,50000000,8500000,25000000,4250000,0.0,15120,10,310022,5000000,'expired');
INSERT INTO bets VALUES(14,'f964ef723387946ba8ea78589e5772370ad0909a985cd83a281d26f192fe6bbb',310013,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1,1388000100,25000000,4250000,41500000,0,0.0,15120,10,310023,5000000,'filled');
INSERT INTO bets VALUES(15,'4a4eb3b3f79303bc6b2f37f049c145808164176f996edaddba16320b7eb0bf0d',310014,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,1388000100,150000000,0,350000000,0,0.0,5040,10,310024,5000000,'filled');
INSERT INTO bets VALUES(16,'6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300',310015,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1,1388000100,350000000,0,150000000,0,0.0,5040,10,310025,5000000,'filled');
INSERT INTO bets VALUES(17,'cee3a40d67546871412e28c6210d70713b46597718ab72d4a62944555e51a2a8',310016,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',2,1388000200,750000000,0,650000000,0,1.0,5040,10,310026,5000000,'filled');
INSERT INTO bets VALUES(18,'f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0',310017,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',3,1388000200,650000000,0,750000000,0,1.0,5040,10,310027,5000000,'filled');
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
                      difficulty INTEGER,
                      gas_used INTEGER, ledger_hash TEXT, txlist_hash TEXT, messages_hash TEXT,
                      PRIMARY KEY (block_index, block_hash));
INSERT INTO blocks VALUES(309999,'8b3bef249cb3b0fa23a4936c1249b6bd41daeadc848c8d2e409ea1cbc10adfe7',309999000,NULL,NULL,NULL,'3e2cd73017159fdc874453f227e9d0dc4dabba6d10e03458f3399f1d340c4ad1','3e2cd73017159fdc874453f227e9d0dc4dabba6d10e03458f3399f1d340c4ad1','3e2cd73017159fdc874453f227e9d0dc4dabba6d10e03458f3399f1d340c4ad1');
INSERT INTO blocks VALUES(310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,NULL,NULL,NULL,'61b8d900911023a49473738d5186481759c83d199e5194bc82c9452e84906639','9f87bc63fd77cfc85940d2260373ca4c35f29f9e3783a0956778b4de10edc3c7','4cc5b6e4cd81708da50784caeb4c34154c2defc0b5e4478171906ca3fd2dafb6');
INSERT INTO blocks VALUES(310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,NULL,NULL,NULL,'ebe0f12f47c486891f6459bdbb5d88efd4ca598208678a830179370ba1830687','c8fab01dc0df7ef54cf4ffe2a6eda47581010e04e9c0dc48df54afa275228306','e814ad99c6d963e8a5c822052c5ce1da648dabeb557fd207f77c6d15c8cc0966');
INSERT INTO blocks VALUES(310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,NULL,NULL,NULL,'5ee662e5b5901393cf880b37a52ace39c55f2d6474aba20fd0529120e298f654','6ce85db4a4022684bce8ba86d51e3ad9b55148f05e92f6e5af3515312af4fd54','8ea34222da0efe5111736b2a554886ccf42bb74c08d5a0edf5a09694c1ccd1a9');
INSERT INTO blocks VALUES(310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,NULL,NULL,NULL,'ab20efe1b47b7835255641e57894fb59005742fae3cc3823cb2e99050f6baa6c','dfd085a8e72e40423b574b4fbc7086c2bc8fee90bd374229beb8c1cbf1156583','b5eeb80ccead443c1cc8d7665aff2902f13fe2915cc52f27f89a111cfb6fea8f');
INSERT INTO blocks VALUES(310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,NULL,NULL,NULL,'9c1ae7470ded5d3298dfce8a3a09d839e0edc53b58e0c498ea916cc558f74ac0','550e1146cf14abddb2bf0faf521520167217e7b418e25ac3d146deb5f0d7ffaa','0cc61c88a94fa58442d51498fdb086e8841ae4b97099470e21088e652fd440b1');
INSERT INTO blocks VALUES(310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,NULL,NULL,NULL,'703760c323dd2de22d8ae32743e35d121bf2ad7b07a1cfd7f6639e40d88a607c','20de07d628e113b29cc6fc03cb45f39b08e4df3ed2e012f31aae8112767e70d3','589afbe9c673cc7080868f8c5405c9f2c76c97d3773011553319f80928f4b088');
INSERT INTO blocks VALUES(310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,NULL,NULL,NULL,'f54b1744002540d32f13bf6357ed1abd56671b1e6bd0008f8edb8df39a17b8bb','8254d45c7a6cf9200f4174a23f2fe3c4fd0e4764514a0f9a025491bb2c143229','47403c730886b445121a99d725ec70ea39feb92fa5156bad20fdae1c3f2f50ae');
INSERT INTO blocks VALUES(310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,NULL,NULL,NULL,'d96d7a605f24dd4c5a1dffdd11da22975337c8acbcb26b5c3534e5e0ded0fa9c','64d9a3d64446c23ffa79a269c51454e760bd7b862b04f6421aed7a4fed6b95c9','ff43b341bdfa69709e582a9e7db45b492203253858f56f866349358c911b14fc');
INSERT INTO blocks VALUES(310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,NULL,NULL,NULL,'f6e0dd981f49bf4b4a8d7d51d82f1a556aec06b5725c4fdb3716835fdf7a9d76','46a735a6c2bbb78c35b7579278c158f20aa37957da0749ea3be2bfce8c121d68','2dab768505134110adcb2a32a48b78f4950e3d628c0db23a6ccc34cabd069268');
INSERT INTO blocks VALUES(310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,NULL,NULL,NULL,'d40850196547e864aad2086202712fe7fa5fc7ecb1a219e2a0831414546160ea','73a02cd61208d58a78568265cf7000928315622e8ba68256f8683bbf65297989','66d88df7202f1338f0d986c4bd2d1d9b69f7b3c58685c95647e04e2bac957095');
INSERT INTO blocks VALUES(310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,NULL,NULL,NULL,'7102ab487dd276b7d9e9edbeca6476ff49097a0e4bd4de8f78783b765f06881e','66c8dc384e19c072b273a9a6b4b34518a7c43b76a4b0cd49396e8ceed3f4082a','0c087389955ce6fe668f180a6a4a9d0361be207ebcadbe2b126d030a3345b994');
INSERT INTO blocks VALUES(310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,NULL,NULL,NULL,'d6bdac57d1137296d9fd89e01af21273e8c3b498d8d07c5dc36416c259507233','7f4fb2795704d038f2ce01f0823075b08f1f815a3b38554c1fadd44fd054066d','079367517b13a49e861a3b7a644d02edb13e2585a12f5d96a7a7ee61397bca39');
INSERT INTO blocks VALUES(310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,NULL,NULL,NULL,'8e1aa013f3f569d4ddbdca2185eea1709e3c03a8a6422785884d7f0965f2d9cf','59e058f1762fa16878369a5b4a71d5f9fe48dd237d220248285a4b4e190f6679','b371e605c6eb8928a11f146e56fde7ad9e584bd08273b6c2e5afa2d368c29ade');
INSERT INTO blocks VALUES(310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,NULL,NULL,NULL,'8475956c6345170ac29d3b04fa1a814bb408fe46274a7e7afd6d1ca5009b992d','c14c6f135b49bef551b26674e96bb901db7f69c62b641c52da3fd60d4ba0b69b','b489cf8ff93a8cea159ebb4aa397b1e0a0b8a06d4a84ff85edeb2e0dd8539305');
INSERT INTO blocks VALUES(310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,NULL,NULL,NULL,'8311dae8a09924081e7427f3904c6e1770463290288ea43dfc4b6764332502e9','b828b5c08b6009c1bdcce5de716eeff20005e492720997c278790419a8bb9446','1993b40b0f14f399182fe8ae976f64903a3dfe04eeebdf1d0f994edd02e6ad70');
INSERT INTO blocks VALUES(310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,NULL,NULL,NULL,'8417e4f77a012183afac998f853b73e3db88649e543e5925e7fe89b7fad69cf3','ab3d647a0f90ffb47ffb028f140a8ca443e7b7b12b74c688af3538fdbe43f275','845d0dbbe371bc1e8f7841f1cb304c897771a75598232199dec12e6ea6612b3e');
INSERT INTO blocks VALUES(310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,NULL,NULL,NULL,'a7e86a607b2a6272711e262d282687e59570415e23633bf2ac23b32e789ad7b4','4dbe36e28ddc84c93bf3660908ee9c90299dd3b54c4eab4c9131d6dd60d330b0','94119126d9b992b1195057f28fe11d52daff38dd41b82d774951b90ab9a22c91');
INSERT INTO blocks VALUES(310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,NULL,NULL,NULL,'cc0961443f7d5fa0da918042c483c115ee7a20825c7cf88d4495d77acc2588f8','7e4122737e714aaa0a0c91611567b3befa180140f96199c389bdf074d8eb1ae4','6763de94948221953d5930df57857a40493c7ef7823298241c3b9ac826f33eab');
INSERT INTO blocks VALUES(310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,NULL,NULL,NULL,'2dcbc2539f12c6a156ba1f37130eb8284adbbf1ea470c0beb1ca0e87a41c58f4','7fa90fe094a6a8a95bc3f6f44f491407ddcf6ef4cc9d5c7504bf402e77012f70','e4c631b0b907ec8f536dc8a03a9135cae71110b0b0c0af35fe7873bd103cbf20');
INSERT INTO blocks VALUES(310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,NULL,NULL,NULL,'b25da08e76acf3b391dcb9facc3199b551f264ad20aff8df178ee49f4a31228d','122ff031774b3fc36c776093fcacfa58c8894da6aa9954e13db5439685e91a7e','ee920f22af896dd545f3cd51484d3f9c1573735f59773d6823f7e9276ad0f3ef');
INSERT INTO blocks VALUES(310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,NULL,NULL,NULL,'840c8a8a58ccb19d8e91e74190ffb71b858ec64e65ec199fb6180e6946b65073','c746b2a9fe874fb1dc1b0423e0a8d343d89567a6ed93651f19e2f155b38d08ae','f57c97103a87ae3ad2c6e83c57ca4811b83a24890c9d7f65209a5d81ac79b892');
INSERT INTO blocks VALUES(310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,NULL,NULL,NULL,'d34033435391ffce6e5a97e9fb066e78bb9dd68bb3e5ff05951e46299c06c90e','1d780ccef8dcdf1c1530b6a3e025436e8a34b5d91713b514ba240fc7822e8587','3e58bde1b0b4e80fc8af1ff0d2851bb4b5c804a5616d13e02fa107c8c5e40b7b');
INSERT INTO blocks VALUES(310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,NULL,NULL,NULL,'6255fbe050f584204af3699be4dda1216e82ba435d0e2c060ce0e1381c195cdb','25c0fc2f6909eec0ea7fb9253a6b1757ab78148dd8f34e22db6370023c856b8a','c9b52c40398cb40a7c1f4bacec081fc9cb72944002adb0dec3603e6b584a5671');
INSERT INTO blocks VALUES(310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,NULL,NULL,NULL,'29bb99fb17976f56e3e5046b2439ee0ffb76a2be604431f445764ebf1599d6aa','456038502ef24a5c65dd382eb9a93ab1650a07780154d2ca0f48eb14aba205bb','5e756a55407d321a82b1374a1aab5b762f9f448adfbbef36ec3b1a3d4dc34a74');
INSERT INTO blocks VALUES(310024,'b03042b4e18a222b4c8d1e9e1970d93e6e2a2d41686d227ff8ecf0a839223dc5',310024000,NULL,NULL,NULL,'e2e1342acfa248051b746fc9a1eaac8528d7f0ade612e6ceb78242cfba61871b','c1dc22759d4f3597950ea755e212afd7ef166c2fc5e1dab6f1d8efafa70d7fe0','69815c21da3cedc1ef08d2dfdce4c3c5f163f0883183474946c4b6b5a2673325');
INSERT INTO blocks VALUES(310025,'a872e560766832cc3b4f7f222228cb6db882ce3c54f6459f62c71d5cd6e90666',310025000,NULL,NULL,NULL,'48b5a21d1c7dc5bfb66d2dca3251d50d15ae844bb7095116a4e11e94e17e5708','64cf2eda5f04c2535da8ff14fcb95b2a06b32047c2e2f3d47c3487c8f0b5ff63','17d05a2f4183affc22977a5606cc35f5b793311734fbda566128950252e00925');
INSERT INTO blocks VALUES(310026,'6c96350f6f2f05810f19a689de235eff975338587194a36a70dfd0fcd490941a',310026000,NULL,NULL,NULL,'a2347a53ce3f450e6f97027a615edcb4fc3309ddfbe31a45c0137aa875f949e3','fe63e42aba969faba8ae267ba7245654002a0a6ce739c39cce93f958d91f552f','7d622728f8f992629a0aff56796ff54f92f80cbea3e41b5321135bc90e44e255');
INSERT INTO blocks VALUES(310027,'d7acfac66df393c4482a14c189742c0571b89442eb7f817b34415a560445699e',310027000,NULL,NULL,NULL,'7b3fd188f2213eda60e5818765ba1bab4fdc0eac8a2b258d93b0467069dac53e','50a677ed2abb80967ed40d84baabaf91b114090122b86b943657965a3644ae98','c2c22a646c8bc73742aa2353f0e5024a9bb6d5e473881c045ac90beb4a3ff2d0');
INSERT INTO blocks VALUES(310028,'02409fcf8fa06dafcb7f11e38593181d9c42cc9d5e2ddc304d098f990bd9530b',310028000,NULL,NULL,NULL,'0ca1bbbf1b71eb7779f18c9df1f864e53b2cec2a9a56980d9d8249994441107a','4fa2d84c12221ec8b917c6adce8d2fcc4a33207031e2f1daf27a1f6f73433d3f','de1d0b1c7ddbd40ce6cfa749d261ed88862bfae6dd61eb3b733dd084da094b7f');
INSERT INTO blocks VALUES(310029,'3c739fa8b40c118d5547ea356ee8d10ee2898871907643ec02e5db9d00f03cc6',310029000,NULL,NULL,NULL,'18b7ca215fd5d4dcb6cab043b24c55f08b05ca8e0feb0d8671e9cb3a5d73a3d5','0678f5193c92ebad6571302d2ae569978eb1cf964e6c8e93d2aea9b28ba50368','f4aa970e5297a73cc8a75e4e606e026b99a635ae42659fc687e0dde56e7575e0');
INSERT INTO blocks VALUES(310030,'d5071cddedf89765ee0fd58f209c1c7d669ba8ea66200a57587da8b189b9e4f5',310030000,NULL,NULL,NULL,'12235f188b2abd632a60a9b7174840811ea6a0a8f4e6f5ab370752d8f79cd008','0b7c2d1b006482c19ed3c34902110b1cd5a52b3d80b48575974d4cc636eb2ab9','45743b7db276bb78c452f501ebc8b44d0f824e24552c3958bc52afef7970bbe8');
INSERT INTO blocks VALUES(310031,'0b02b10f41380fff27c543ea8891ecb845bf7a003ac5c87e15932aff3bfcf689',310031000,NULL,NULL,NULL,'9ee68abe5213d5c092fffe9cfb3d98bba96b496d05c19277161ed8e0ceaaad73','5b61041170b139066726716caccb6f4d79e0af8a4146681fd7a9c12b8855d207','c71eda9dad917ce61064b2001a852d5709b95208abf9a7f8e0410e9f28fd3dbf');
INSERT INTO blocks VALUES(310032,'66346be81e6ba04544f2ae643b76c2b7b1383f038fc2636e02e49dc7ec144074',310032000,NULL,NULL,NULL,'e761e0cebc6ad10c3651ddca9777b8151e47d9769bb84357cbf5886aefd81433','604ad3439dbc859a77c504330c7af0513a04b29bf801dbbf594e86814ab781b2','5a656a79d87fa1ff3363c52b567512c8f5bff6b3026089ff2e1b13c04d7b20a6');
INSERT INTO blocks VALUES(310033,'999c65df9661f73e8c01f1da1afda09ac16788b72834f0ff5ea3d1464afb4707',310033000,NULL,NULL,NULL,'b44d41018936a41ca0d688f4c643a13ea00fcc6a03335c659cc4f30c988884d1','70e6f7c541ee8bb7118b35370a9cf4f8383e4d98a3259072312a600e9fea1943','17428b41f981f4ab5565a18f19276020dc632e51cd8d383469dd04a9d765f78d');
INSERT INTO blocks VALUES(310034,'f552edd2e0a648230f3668e72ddf0ddfb1e8ac0f4c190f91b89c1a8c2e357208',310034000,NULL,NULL,NULL,'d28ad316de3582937fb53de526b83db49e06e97466d428f6add2a29d06dee2db','b8db7010cde1cdbd4fb23b2748d185b8e3a19a1385af325ce3c5c3322b6ee4d6','4255e71f98b871219e872a9df91751fee79d1869191571d5aa5a120e3718b9dd');
INSERT INTO blocks VALUES(310035,'a13cbb016f3044207a46967a4ba1c87dab411f78c55c1179f2336653c2726ae2',310035000,NULL,NULL,NULL,'bd978c16cc8cfacdde3b04d99a77b2657f1865031e58fee9d14e180607db0417','f59b8cee30b188f22f511c8d9da6e13fba0f88d4c10350d6ab4b4e820e2e2f0f','581d23e11e9770dee35e51fa77f2cb10f1b2ebdce21b0670b8706ac3b97f5b74');
INSERT INTO blocks VALUES(310036,'158648a98f1e1bd1875584ce8449eb15a4e91a99a923bbb24c4210135cef0c76',310036000,NULL,NULL,NULL,'fa884e2d4c2ecd63379aceb64bf26825d225f326ed56ba3dde2bada1dbda756c','4fa664d6aafb6921e5db62b111f8de549bf3e7b418683c44cfa0344f668ea0d5','50925fb0ad3432d97b22c99ba785c0452da05aca9e7c4b92b49b36b7e222b15f');
INSERT INTO blocks VALUES(310037,'563acfd6d991ce256d5655de2e9429975c8dceeb221e76d5ec6e9e24a2c27c07',310037000,NULL,NULL,NULL,'6f0d5373605a2c221b9314c4942ac3b406f7dc6881a9414a327affa4bdda1a1f','d3d5fc56a21ba492ad33193cc2ed6e446d4996ecfeace57cba8e61c89e84811a','b99acb20455d053a0c4a45f029a05e42ac1ffaa349500650c07db0f15f5489bb');
INSERT INTO blocks VALUES(310038,'b44b4cad12431c32df27940e18d51f63897c7472b70950d18454edfd640490b2',310038000,NULL,NULL,NULL,'5de04c6d375f93803617551491ff35482ec0643deb6d30afe8e638249a240242','8ba9145d6651df211591a493a4756629315ae9bc204120feddd2da93c223fb10','f3af64b4edaef94a70f346a366ea178fde5ebff2a6d6bf3ede5d67230336a98a');
INSERT INTO blocks VALUES(310039,'5fa1ae9c5e8a599247458987b006ad3a57f686df1f7cc240bf119e911b56c347',310039000,NULL,NULL,NULL,'a09466981079e109e6967ba24d123a673e4a97589f5c194d0f106d08b2435c9b','b9b9950d49dfe75965af4eb06413ee6a2924888e06e801fb208f72a48ab6b79a','739ca49219c457e29b49174e49a1c78ac2c9544b5265801d525d3113f37b387d');
INSERT INTO blocks VALUES(310040,'7200ded406675453eadddfbb2d14c2a4526c7dc2b5de14bd48b29243df5e1aa3',310040000,NULL,NULL,NULL,'aa2fcdfeadb68397a09a20e2a65e3dc814a5936c0e56ae02d218a3b53c833cba','1f790775427cf25958e5d03f66f9b4960d72b0b932cb49ef426904728e5c77f9','7759acf8a96c5f735e8cc873de4ef6e95447ae3f894814b2953de45c56f6107b');
INSERT INTO blocks VALUES(310041,'5db592ff9ba5fac1e030cf22d6c13b70d330ba397f415340086ee7357143b359',310041000,NULL,NULL,NULL,'afce1194f4ad77e79b25ccc0cabdadf0b9eb6ce95bc4118ca4fdeba0d1b52c76','a0307be122954e7fdd86127133681c60c10a95ac021ba700fea45fd2e0a90a10','534805f00c787306d6d7daef52b60c8ccff0a740038cd1ad982475e77505561c');
INSERT INTO blocks VALUES(310042,'826fd4701ef2824e9559b069517cd3cb990aff6a4690830f78fc845ab77fa3e4',310042000,NULL,NULL,NULL,'a2879252d3c15ff131701832c2edc967e8457703e099b730036c4ae0ba4fa8da','dfaea7be191387fe537bd225c0fa8b7a1b589f84420015dc1bbd5ac6bbe4af69','cb2f61846eb67a1d936116135633be561731efda19b3ae432e12206d93baffea');
INSERT INTO blocks VALUES(310043,'2254a12ada208f1dd57bc17547ecaf3c44720323c47bc7d4b1262477cb7f3c51',310043000,NULL,NULL,NULL,'4ab2eef21554c6af18f776a94727bbd9956dfddfcb4737212bd56bb528520f48','31eb1f718fd19568f8752090bacd7626d26cc02b84e5cd61cd02665ed812b609','69dd40b75d0bc59c0b25db90ecd9b070d3f72ae31e50e54f93209b93dd1358d5');
INSERT INTO blocks VALUES(310044,'3346d24118d8af0b3c6bcc42f8b85792e7a2e7036ebf6e4c25f4f6723c78e46b',310044000,NULL,NULL,NULL,'fa76aa545d6f409caad41c15baa52a2eac6e3c1bf55a64781b64433ebbe45669','8d99246a59d59d88891ff74fc1eadc3e2c4b2352e0f3f3389456ccae700f4a09','889e20058d99b90a945b475b0865bf3e1d51846a24132244fdae04025f75bffe');
INSERT INTO blocks VALUES(310045,'7bba0ab243839e91ad1a45a762bf074011f8a9883074d68203c6d1b46fffde98',310045000,NULL,NULL,NULL,'95aa6cc6d015cf1731be5d69946847bbf971c7b4924477ef279f114f69467456','fc19d2fe1fa0bd07fd4ea86f185d4e899bd3c778bf4e703b6ce4141f5f36fc9f','e54702f408c553c2e01711088ea7453cb31678df0ed5431094fcfde13a1f1275');
INSERT INTO blocks VALUES(310046,'47db6788c38f2d6d712764979e41346b55e78cbb4969e0ef5c4336faf18993a6',310046000,NULL,NULL,NULL,'71ecbfe582bb604f38fd0e31d495e5ee2ee804e8e1fffa4f3051e81828f3212e','a5523e3c99d646b97622a631d6305e45fb5f48212c8995742fffed8bd188ba84','34193defc418d781c41874259ff52614a2a2052caee9a863ddf9477a97dfb5bd');
INSERT INTO blocks VALUES(310047,'a9ccabcc2a098a7d25e4ab8bda7c4e66807eefa42e29890dcd88149a10de7075',310047000,NULL,NULL,NULL,'4d04b3b97abb769884a0def4a01bc1ddb43436946c88e6b7f0df7da2df4aed3c','099748322185e590da78c969792f7b295051f096b71a88d44f583c726e53fba5','ae5979f9040f391974e747aee0598c4df688e6e974ec7b9f73c18e6f24e851c9');
INSERT INTO blocks VALUES(310048,'610bf3935a85b05a98556c55493c6de45bed4d7b3b6c8553a984718765796309',310048000,NULL,NULL,NULL,'9c7e28f8460e4237a0545cfe618f6ad161bdbd5a872201b6df92b82be03db4c7','5a8091771dfa7d389ef722ba69fa3bba2006627afd1abd64d5035bb149f38ceb','c2e4c0f8b8eb0364455f0ec87a2a26363772e9ed7dcd78f135bdea1856a29b70');
INSERT INTO blocks VALUES(310049,'4ad2761923ad49ad2b283b640f1832522a2a5d6964486b21591b71df6b33be3c',310049000,NULL,NULL,NULL,'d7709586e763af2742f924b6cfc83b27ffb2916ca9ed1b167ed89b4b8da56362','726a9553f4a08e5979609f5e9ab35f603743f670b68581aabd6f0814fafa4e65','344475174441b038b6e26c59150d3973a751c7f05cdfed81bc49406e7891b6e0');
INSERT INTO blocks VALUES(310050,'8cfeb60a14a4cec6e9be13d699694d49007d82a31065a17890383e262071e348',310050000,NULL,NULL,NULL,'f45a1d964d934d198df85b7d351fcd110fa0108b1b041547544db56b02e1412b','c815dace076a340c33be9b862bba458f8ee7ce685f106615bb8c9da9a3c6f43a','ceb23fe6cb37763d34cde1c6eac6a7ac4d2e7b00423762402396b01e87e432b8');
INSERT INTO blocks VALUES(310051,'b53c90385dd808306601350920c6af4beb717518493fd23b5c730eea078f33e6',310051000,NULL,NULL,NULL,'50855682e52590a4a32defc2177fde793c68d0738dadf7f301d7f9649b0401a6','7c8c8c380324c0d4ebd7ff22cc43b66a736474eac21260384292cac7d033d9cd','d339d6554b6f98420026fd723b6bdb7a65ab6dcf4ea21cb111127e81714c2cc2');
INSERT INTO blocks VALUES(310052,'0acdacf4e4b6fca756479cb055191b367b1fa433aa558956f5f08fa5b7b394e2',310052000,NULL,NULL,NULL,'7e2483b132ceaba17fd7ad36e9c1e83a4ca519dd0436c51d4c7dcf54a1ada87b','b79711c0d55f1a8f99965f53171f9eaac3765f5146ffca0afb60a2f954faa9cc','b918d5de8a6cd5f9ff23ae591c7de9764211888688b1b05f5bf329db3066004e');
INSERT INTO blocks VALUES(310053,'68348f01b6dc49b2cb30fe92ac43e527aa90d859093d3bf7cd695c64d2ef744f',310053000,NULL,NULL,NULL,'bad7aa75a07734400ad14e4a18ace48682dfe82ed44b4d7597d9272ceeecc5c2','8975d9c9b12d54799d380e380a58e872f2b75973c84f9ef9da720908c7d6eb72','299192de0e4a0065df525664e7e4d6e9a0d3a962868d1d626b5c9f92230b9b01');
INSERT INTO blocks VALUES(310054,'a8b5f253df293037e49b998675620d5477445c51d5ec66596e023282bb9cd305',310054000,NULL,NULL,NULL,'277dbf0d29d7a8b97a6574f2bf14dab15d869441984693a6e24f7f7dca5ccf08','e455edc2f28e6dc0e381d02d9b7b41bff77296d8e1e7f614e19e542014422075','6c272dc1079bbb3b75bb40b323f205de48aa9057410b7e8e7931aabd7c795bf1');
INSERT INTO blocks VALUES(310055,'4b069152e2dc82e96ed8a3c3547c162e8c3aceeb2a4ac07972f8321a535b9356',310055000,NULL,NULL,NULL,'a2b93c3588bacb0e2eb137617699a2d7ae9dc1cdd9103c4deadcef98d4b44dbe','a47a175fa9374fd8694dcbc9bee53a146c2fc02c178edafe52bb2c8615576967','bd3b0156d827f06ca0a847a8be37e0871c2d5185343bf08734d335e9543204f3');
INSERT INTO blocks VALUES(310056,'7603eaed418971b745256742f9d2ba70b2c2b2f69f61de6cc70e61ce0336f9d3',310056000,NULL,NULL,NULL,'f718c52819c66e792d074ca220d4df166c3f25e226d7d0a981cbfaeb8159868e','2e48e6025d44b4a8e3646b31813b019bea264a25e0bd9a5fed7a063ac647a1b9','51cbb4c56110efeefc4075d14d0b1ef55c070148bbdb644b4c6e0b2c06901750');
INSERT INTO blocks VALUES(310057,'4a5fdc84f2d66ecb6ee3e3646aad20751ce8694e64e348d3c8aab09d33a3e411',310057000,NULL,NULL,NULL,'f5ac3a89663df8239fe39b91817d786f1a802532362f03aa1a2cab42787c075e','ef9f6cb8c2880046bfa268601798ad157f333ee7c723385f7a61fd2dfe03a891','c5e93fcd127f82338cb4599deace34b737b7404467b746934fa3952f88cd7a59');
INSERT INTO blocks VALUES(310058,'a6eef3089896f0cae0bfe9423392e45c48f4efe4310b14d8cfbdb1fea613635f',310058000,NULL,NULL,NULL,'7922e7f1fd6ea0da3e0bef551420e48eeef02530d92662b1f4e3b1f614ac25aa','6df71210d9d33ea378e9bfe55169ef784f927bc473a52e686098cc284ddf72e5','e150aefd7d2f41df5e96d1a26b8e4d204b8499026832d8cd2c140868916b401a');
INSERT INTO blocks VALUES(310059,'ab505de874c43f97c90be1c26a769e6c5cb140405c993b4a6cc7afc795f156a9',310059000,NULL,NULL,NULL,'6a96fc67f0fcbd07ffe71176deff4e04ac7687e88b44ebae21cd960b834a5ce7','9c0b818033e852f078781b28a7267cafa84be851fd54021f4dd83b478038d30e','9f503955e53fa5d1e0bb16f17c8153a1262178451309c558c6ba6fa2bba6ee03');
INSERT INTO blocks VALUES(310060,'974ad5fbef621e0a38eab811608dc9afaf10c8ecc85fed913075ba1a145e889b',310060000,NULL,NULL,NULL,'65be0b54231417d6ecc39a64a1152a687321a45dc4ae2bfc57cb7afb387819f2','6abfc05f6a7087abc49d2f3524f38e42089f9d026d36ccf5b9e76eb36d1ed0d4','05d317854b07ac4c9b82af93a265588aced1da4563cd6bd0c22f9e20365febef');
INSERT INTO blocks VALUES(310061,'35d267d21ad386e7b7632292af1c422b0310dde7ca49a82f9577525a29c138cf',310061000,NULL,NULL,NULL,'4fe377a4727a4d2cf62835663beb38b651812e0bac02f5e7b704a8bf1aaf904f','cd19c2dc9c430f582457274a1f1ca3d094f69f04a58d48aaaf58fcb329e379de','a6eff404e31f3bd56b828e564d8102e4afdeea1ee852ceca4cb2e7ba1e567dee');
INSERT INTO blocks VALUES(310062,'b31a0054145319ef9de8c1cb19df5bcf4dc8a1ece20053aa494e5d3a00a2852f',310062000,NULL,NULL,NULL,'a0d52688b9c9f25b4a1458cc66d529b6e8bbea70e7efbc6a4ad6e7d906a68f6e','57f88118b7f4907e6b70c6ac1f2a16ac2da089c8fb358155229e307e75932321','9f2a8065fc8d7791ffbcf3ada2da535a4635fc7294fc246f65ba49c9231a8386');
INSERT INTO blocks VALUES(310063,'0cbcbcd5b7f2dc288e3a34eab3d4212463a5a56e886804fb4f9f1cf929eadebe',310063000,NULL,NULL,NULL,'8d7600132b9350adfdc74ff1720032475763cec6c1356041363688706d50c154','56e24ce3df5f28d8ac7941c583228e01a41cbb7e06e489147235c31d77248a30','543f47cfb27d95e41862e6f1b75de0c91bf266cc6960af8e4fdc1c90a5ca2228');
INSERT INTO blocks VALUES(310064,'e2db8065a195e85cde9ddb868a17d39893a60fb2b1255aa5f0c88729de7cbf30',310064000,NULL,NULL,NULL,'100ba9e5f1bc19ead558c0d2ffb0b16e65942e87cc612f2b132329d3d1ff8b96','e30b1714fc0c13fb8b53dbb6dac70d8d5ba7fe7543f9585c78dd561c2215f6fc','64596fc1cedf83b6031f6ca121a15662550c356d7170f35e3396c8a13ab1fa5d');
INSERT INTO blocks VALUES(310065,'8a7bc7a77c831ac4fd11b8a9d22d1b6a0661b07cef05c2e600c7fb683b861d2a',310065000,NULL,NULL,NULL,'50b18e418b408e35cff10f880c0d3223a4818b1df6b4c1f5150898b1aed25493','acdaed5312b42486c3a3ea0328dcac9198c4064552994b215b0608a3d44afae6','5dda2ffee0beaffbfb61c11df42c92d979de073713dcea50943ee0c52e282641');
INSERT INTO blocks VALUES(310066,'b6959be51eb084747d301f7ccaf9e75f2292c9404633b1532e3692659939430d',310066000,NULL,NULL,NULL,'f5fda3c45bc6ebe635f6238c05b93ba234b93c6a915e96beddfb16b85073f3e5','26af4d671d231c15023fd32562a74affdc133c74c3f6e460a4fd9123519fcf48','676cc5fbced2e63757ae66a984f82a364095f97e16d70700eead20a4fa85b357');
INSERT INTO blocks VALUES(310067,'8b08eae98d7193c9c01863fac6effb9162bda010daeacf9e0347112f233b8577',310067000,NULL,NULL,NULL,'81ca4f25ef719bbf86d6cba43a282eb36ec449449c319be35378c563a44f559f','da8217ff6d582d0638dcf22e56782e57d40483d3a852ac97440fb845656d96ea','c8798dee016c4e2e168d00afe21ed95b70275180314cf8b6dcaa7fd1b5ed7845');
INSERT INTO blocks VALUES(310068,'9280e7297ef6313341bc81787a36acfc9af58f83a415afff5e3154f126cf52b5',310068000,NULL,NULL,NULL,'8557bd6303862effbd1c33e3e107e2e022114b9767fb45205c9f481164c3d5c6','92f97e9abfc480e9b83c17ec5354154bf809a195a5ee20c968ac4c9a35ded7bf','86653f400d0ee35375c6370c9516ed14b6ddf8cd411d7713e38ce843846bd873');
INSERT INTO blocks VALUES(310069,'486351f0655bf594ffaab1980cff17353b640b63e9c27239109addece189a6f7',310069000,NULL,NULL,NULL,'40c4d44d5cdc0d7f54851ead6ac6660ff76d2050e4d54f16a31433a0df77a7ac','1ffd0a00ffbde8d212c120216da8b97c1f21ee310ca032790753447149427cf5','f7830c2e7227647cbd0094f766c463006f6ab85d05c13b61bcbe1babe96eb780');
INSERT INTO blocks VALUES(310070,'8739e99f4dee8bebf1332f37f49a125348b40b93b74fe35579dd52bfba4fa7e5',310070000,NULL,NULL,NULL,'4a18f0eb6d6edac2b0b9d0bc288f2f8a407874b030566c74c6287418d88e3ccc','800ad8a2720d55248e235e818c3564c08355bf73cb8d36224f02314c63128ff0','00f7e36b003c78b95ea1e4d4584c1c057eddd676910e3c930620242ab30ce300');
INSERT INTO blocks VALUES(310071,'7a099aa1bba0ead577f1e44f35263a1f115ed6a868c98d4dd71609072ae7f80b',310071000,NULL,NULL,NULL,'e44590beb89eec5c857ac2c96cfb62d167cddf12424fa0f13932e65f4909d994','623b685aed47be5a917bea903037bfe1806c83d3767799451574790131eb8228','cafb1cc2f0e9179b895730a72d6286a16aa4f2fea1d7fdc36188df8e0ad8938b');
INSERT INTO blocks VALUES(310072,'7b17ecedc07552551b8129e068ae67cb176ca766ea3f6df74b597a94e3a7fc8a',310072000,NULL,NULL,NULL,'9973f75b68193b7d2c20b87482d2f82922bcce699cbad8ff4bf322edd04b3424','918b0b8bfa31a0fe2141ad9ba68556f01ea1d7a191320ffc9fec0de60be93ef0','fb6eb3de99728ee22b5ec531b11a6cd3cc240699e1db993917b74ddbb1bc3662');
INSERT INTO blocks VALUES(310073,'ee0fe3cc9b3a48a2746b6090b63b442b97ea6055d48edcf4b2288396764c6943',310073000,NULL,NULL,NULL,'6c409328f7652ece7066f8f02cf71f7728c76f993ceba2a81e5ef7d63d193caa','23c8983f534a59a7c2b77b1d43398d496b6340ad28950c4ac05c57a0c98711f6','ebad1e87f71015d8c7bbdae72455e44d6e78bde1c850fd59075edde1ea3f0fa8');
INSERT INTO blocks VALUES(310074,'ceab38dfde01f711a187601731ad575d67cfe0b7dbc61dcd4f15baaef72089fb',310074000,NULL,NULL,NULL,'43a4c6be750352910e0dbb3fa1aa9ee8c950769ce0a36215b75b44bd6bb6120a','134bcaa1e2e2f910bff883ba62a6ae5f9638b2f4306ce8f48a69b6747cb8c51f','6f24d79caf69f6b2eddfc9e65aa2dfb33415465636a82ac22ba465e9d83a8d44');
INSERT INTO blocks VALUES(310075,'ef547198c6e36d829f117cfd7077ccde45158e3c545152225fa24dba7a26847b',310075000,NULL,NULL,NULL,'29f7e2a7a114c53db172871813d235c6131ada57b54dd10bacd8944d7a0b95ac','b6e0f590eeba8f8473c7f0963aa9df1e1cd7a1567aa2faa6f4a36f0f5e1b37ec','a34f9e8ec7b1d945047f8c7836368303d3054f4cf0985265850801e825b1d96c');
INSERT INTO blocks VALUES(310076,'3b0499c2e8e8f0252c7288d4ecf66efc426ca37aad3524424d14c8bc6f8b0d92',310076000,NULL,NULL,NULL,'b2e7116c6225fbbfbf562249b64a005c77e06ddae4ffa833bdd337b8aa283143','ed08e40a2b1f037a739f8fe326396554d12caadc3170c2a42e453ef6518e7034','936fd559cd51208521b48666801551198f031000c59d235afd1e47fcd54cc267');
INSERT INTO blocks VALUES(310077,'d2adeefa9024ab3ff2822bc36acf19b6c647cea118cf15b86c6bc00c3322e7dd',310077000,NULL,NULL,NULL,'d44c52769b0b2a5d39ce666b5240a33ec763ae0fd5ebc6f6f0caa1c48385b04b','d8de6b2720b303e5159a96c2b8225381f8d4527cb474e8b2c4598d3cc1b623bd','eba032fb33db604963b4c3b145b3af74f6e2d79838847e6f01bbdcda50a13476');
INSERT INTO blocks VALUES(310078,'f6c17115ef0efe489c562bcda4615892b4d4b39db0c9791fe193d4922bd82cd6',310078000,NULL,NULL,NULL,'48ded8ec67e45ca3712501b16878781a634d3207bad442b2709c4328c6bcab2b','2cdc3ef55ea24b94daedccf5b845481b1500224fda70ea375d078f93a175ebd9','eae57031284cf37185ad59f069a6f853c6ff4ba488a7736780623a3b7b9f34ab');
INSERT INTO blocks VALUES(310079,'f2fbd2074d804e631db44cb0fb2e1db3fdc367e439c21ffc40d73104c4d7069c',310079000,NULL,NULL,NULL,'0d936afadc2c6474dcedfe9340beacd9fc3e2858bff1e898b2abe47d8663feca','9758971d50b4224155b9fa782bad4723de6e46ff93a6910a87bee38b57255a8d','6732f7aee274b3ecccb53c13666eeb770d81e0f67ca3261fc7cb743629f3ace0');
INSERT INTO blocks VALUES(310080,'42943b914d9c367000a78b78a544cc4b84b1df838aadde33fe730964a89a3a6c',310080000,NULL,NULL,NULL,'8d5cd3d014fe810ecba48f04803ff5a8cd0798e68585150ae91c67f2046fb26c','04b3a729cffaceb371c6ef2ce7fb54f08752ee9871fa413ea40cf42d3ea2e1c6','207ce12c4926ac2c05c54c286628dd8ccd427c7a4a2ef929c9a3e2a72c7f47e5');
INSERT INTO blocks VALUES(310081,'6554f9d307976249e7b7e260e08046b3b55d318f8b6af627fed5be3063f123c4',310081000,NULL,NULL,NULL,'a92910e332d6ac86ad4c83628fbb31116cfa72f991c2dd572d4572f426f2516a','6561ec7ae80bbea810bfc82ca7925c4889dab5078d5d82c0971be70b09f0e1aa','80948cecb485341b51f778fc99846b448bab07afb67ba61e0206a2e86f9c74aa');
INSERT INTO blocks VALUES(310082,'4f1ef91b1dcd575f8ac2e66a67715500cbca154bd6f3b8148bb7015a6aa6c644',310082000,NULL,NULL,NULL,'449ffd19c32cbe7437bc8f6f4ac6dee41b71ad012dae05d3ec867ca000b6ad4c','7f5cdf2ab247c4c4f01dcc80b257a9bd8df617604bf3883b1761e5d38960d52f','32384f14a92a22cdbc42b5b711a124c7068da85e25425aef583ff636699d9179');
INSERT INTO blocks VALUES(310083,'9b1f6fd6ff9b0dc4e37603cfb0625f49067c775b99e12492afd85392d3c8d850',310083000,NULL,NULL,NULL,'3758d98b0e35dd75fc4ef2c0d3b1e450d26049205674c6619b147db6956ad556','406ecce9adf511857a20f04a0230c09edec705fb5cd04adf6c008e5df9619380','2cb0a857584310c16b2729aa997cff2b33466796594247274be99208f04b644a');
INSERT INTO blocks VALUES(310084,'1e0972523e80306441b9f4157f171716199f1428db2e818a7f7817ccdc8859e3',310084000,NULL,NULL,NULL,'847eb7215177053358e3e58a060fa6e36bc052478c22c30e28263ccb337a7eaf','9ff378149724e3791c34798cb6e792b746ffeb1dc25487618e0612c9adffba40','8eec6ac29e16619e0ad46ae27e190eb1499938daeca22316423c976b33508ebe');
INSERT INTO blocks VALUES(310085,'c5b6e9581831e3bc5848cd7630c499bca26d9ece5156d36579bdb72d54817e34',310085000,NULL,NULL,NULL,'8098df2267623176c28b2814f1e3f3a9cc5c791e1ba51a6b3ca8092c01edd7db','b46544e1a8cbdc4bb84ba0e65622057c937d0559f97ee034a2b905aa63579b15','d32ca671f32d858a0424a541555008b0cb319264d2e222fcf7a43925076a93a6');
INSERT INTO blocks VALUES(310086,'080c1dc55a4ecf4824cf9840602498cfc35b5f84099f50b71b45cb63834c7a78',310086000,NULL,NULL,NULL,'ad40ae66f60ad4d0ff2c17894d99feeb98dc3ecd380d1980a053f2477752137f','8ec90a0d0d6e18f916d9409d961edf41525fa79d29859e5c6f5a675128a29637','31eecc4949b5086124f1cb39cb7b4e1910d16e1b77b9006379e046f97117b0a3');
INSERT INTO blocks VALUES(310087,'4ec8cb1c38b22904e8087a034a6406b896eff4dd28e7620601c6bddf82e2738c',310087000,NULL,NULL,NULL,'caa2b4b9d8b4136e285b498fddca55455c4383c8f791a0320f7cdd9ae5141269','0d4787c09f814d404037a9ff7d8676a3e1475f97d1eabe97f183d129a680664e','88d3c8b4a2deadd758d5c90650fdf20ecd7426853c5e8e32809f73959f0f8d7f');
INSERT INTO blocks VALUES(310088,'e945c815c433cbddd0bf8e66c5c23b51072483492acda98f5c2c201020a8c5b3',310088000,NULL,NULL,NULL,'b6896509f90af92204b1825839a9ea5cd1ee4afe11e40cba568c03a16a93a2ec','5fdeade4b91b354a30d881dcffbca1ac08998d99478ce3e93d4bec2bf54e8c81','f7d50bf615527505920b20e4fb91d78366db89b9d42947ffac4dde64185e9d78');
INSERT INTO blocks VALUES(310089,'0382437f895ef3e7e38bf025fd4f606fd44d4bbd6aea71dbdc4ed11a7cd46f33',310089000,NULL,NULL,NULL,'158c8967ec4582068411fdd5e0946930f7460f16c47bbc3d0cd31d2d1d1febb9','ba7e81e477306cb8c0b5e39477a22180d042726f1db35b47a8ad04daf736e0f6','91b2fa6bcd33a821d5d0a53cebdfbb5ecac5b169d28e37daedcf184e4a1945cd');
INSERT INTO blocks VALUES(310090,'b756db71dc037b5a4582de354a3347371267d31ebda453e152f0a13bb2fae969',310090000,NULL,NULL,NULL,'28bebdd7269c24773d1d6c2cbace6431cbc7e3440fca9bdafea880bad4af4299','27f1cfc4f33f71f91bf217f199ad6e8b73afd567988409063e96cfe5aaa44d0c','e722eb4536d08efb503b2c6e596e905af0573a8f83916f480e512c18c4d2865c');
INSERT INTO blocks VALUES(310091,'734a9aa485f36399d5efb74f3b9c47f8b5f6fd68c9967f134b14cfe7e2d7583c',310091000,NULL,NULL,NULL,'7de030240d95b4704840a2d2502c29d92815c932739545bd77d759fdcc542994','33144b01b1e1bc1ab6e5567c4e66b2bd3ee7fafba569e17ffb027eec0a236be5','1bd1ead0f51cd1467aa784f528747935b0653a0d1a87a3a648a1780ad36a65c7');
INSERT INTO blocks VALUES(310092,'56386beb65f9228740d4ad43a1c575645f6daf59e0dd9f22551c59215b5e8c3d',310092000,NULL,NULL,NULL,'f59d146c4256dc2b6ce0dfc94f95fb056b982664869f52f4af69ea3f904e9789','01c39bc585dbf350a3b3751391881dde173b4628400862eb3b18cd9e318ceed1','7b7d2ee4351b5f0fad8b561630b959d13559dac47387699d6a4b8ed7de31dab1');
INSERT INTO blocks VALUES(310093,'a74a2425f2f4be24bb5f715173e6756649e1cbf1b064aeb1ef60e0b94b418ddc',310093000,NULL,NULL,NULL,'ac729bafbfcc9c570984e561db83a04117b75116a2f30818d4fad9f6037f580d','cd65ae1e1499a651553d0a07a4bc8e39b84462c95b74a12009088238dcb97860','fcd639bba6fe3bcaaafa08643fdb3245dd528c25e6eafcd373ab325ef8915a92');
INSERT INTO blocks VALUES(310094,'2a8f976f20c4e89ff01071915ac96ee35192d54df3a246bf61fd4a0cccfb5b23',310094000,NULL,NULL,NULL,'5583ee37ba5595b7211734011dc3ce4635c8db72782f918380de2fb50fc08f09','0d37e1a3b9aa80f440812b3ca848354060332a82d6e1faf5ed6c0b240a1e7e91','a9ae74e1bde8bc61cc2bf193879447e19494a428b0298117536ae2fae2f534d3');
INSERT INTO blocks VALUES(310095,'bed0fa40c9981223fb40b3be8124ca619edc9dd34d0c907369477ea92e5d2cd2',310095000,NULL,NULL,NULL,'55e0948c9454355bcad97bede6459589cca2660f77899b0684406293dd2d5551','d74fe428a5e1c3ef98d689ab84207da55a2c6e983e93f17bea7bc10d4ccbad66','5b819d73c6ed11a07cc3195c644474a78681e7e122c3dba5876af8099dc08f54');
INSERT INTO blocks VALUES(310096,'306aeec3db435fabffdf88c2f26ee83caa4c2426375a33daa2be041dbd27ea2f',310096000,NULL,NULL,NULL,'06619cda7f7cd5dfed84397e6c6caf16a9fee57ccff60f09b0c0745f3768760a','cfd2859c22ca047d5768cfa7c746d3f564893112bd9c4dd80328aba76eb1b332','b4c0271e931181c9a6ca3255a773aaeac7ceb808a878288b77927d3526e0d24d');
INSERT INTO blocks VALUES(310097,'13e8e16e67c7cdcc80d477491e554b43744f90e8e1a9728439a11fab42cefadf',310097000,NULL,NULL,NULL,'375fb1cdac3e1cd47a987bae759ffe1d70d01d612e848f3c781d3fbbbb057912','f3cc73c2beef4e87d59fd80f78afeb9288fe552bf9ac282c5879c8d291e92788','544a468ec4a2fbfc44d639a801b2e69ad851a144e168635952d0ad8413fdcfac');
INSERT INTO blocks VALUES(310098,'ca5bca4b5ec4fa6183e05176abe921cff884c4e20910fab55b603cef48dc3bca',310098000,NULL,NULL,NULL,'163739e894f6ca7d02a6a08a1bcaa8aef7535f4c7f4396a34a7e544f8c9f7ee5','6ef4a6cda0b0a1920834506ccc81b4993d80d270e5ba8eef7ccc1314068e025d','80f289621f4e9f18d814d0abddab3bd5b60cabf49f9c920cec2a171b3552b28f');
INSERT INTO blocks VALUES(310099,'3c4c2279cd7de0add5ec469648a845875495a7d54ebfb5b012dcc5a197b7992a',310099000,NULL,NULL,NULL,'566ee39053b915c95b6cebb6af4a8d07642c5573831be032d835c764b168434c','8902c246529886516700b8f009457bb6e38ff6fe6babe5efa4e3fc2b819fca70','b7f068703ec0c581c6d717281b83655f34ce7e4d1c8b61f221552aa8be2fe08a');
INSERT INTO blocks VALUES(310100,'96925c05b3c7c80c716f5bef68d161c71d044252c766ca0e3f17f255764242cb',310100000,NULL,NULL,NULL,'3fd31d1f68f1c553b23ce73b5d54b301c7f0abd7274f1e01197aa398fc4221c6','a60950b5953305f083c4efe67dbfbb7b58ec8239721fd41b4a13036fb161e0a7','cc2453087694c541775bbbb6ba8b2c9a29f957466f79f985ab4affc9af0a698b');
INSERT INTO blocks VALUES(310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,NULL,NULL,NULL,'fb46cebe687b2634cc34780cb3982e9e7a230c5afb319825d4aa9bde0bb31013','e8afa2a15379de49ce0db85e98ce8526ff7a673d688cb24dde74a37b4916d903','ca384502dd2a50fb511ab6cc85f86e3401c6145a88cf2dee4251d460f2eda3fc');
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
INSERT INTO broadcasts VALUES(12,'80a69d4dab4de7a852c30cde4ba6485f56bff5ff5fd842412b04c8a707b990a1',310011,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1388000000,100.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(19,'bfdd28d2bea919d8dfb1a7610a84c58d2b5cf8cf81cf5f4a2f98b0e7b387f82e',310018,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1388000050,99.86166,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(20,'d01b89fe3d1ef6536fe268d84685706362f11493b8ae118db5c0712c7ba407a5',310019,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1388000101,100.343,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(21,'07309373ba2b262a3171265f9ccd9ad551acfd9cc46afa80af8eecc1aef9919d',310020,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1388000201,2.0,5000000,'Unit Test',0,'valid');
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
INSERT INTO btcpays VALUES(5,'765c5cdda1caa7e72af778b3914bc52376d05c3871e23da10aabe6f796f58d7e',310004,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',50000000,'17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b_1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf','valid');
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
INSERT INTO burns VALUES(1,'c1e905bc5cf715a830da1f202d03bb78d177fb9e17db793dc3269071d30dc345',310000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',62000000,93000000000,'valid');
INSERT INTO burns VALUES(23,'a3df7986a348290efe1842d8c904688840c99655fc7dd96497d0c25caa86df72',310022,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',38000000,56999887262,'valid');
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

-- Table  contracts
DROP TABLE IF EXISTS contracts;
CREATE TABLE contracts(
                      contract_id TEXT PRIMARY KEY,
                      tx_index INTEGER,
                      tx_hash TEXT,
                      block_index INTEGER,
                      source TEXT,
                      code BLOB,
                      nonce INTEGER,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
-- Triggers and indices on  contracts
CREATE TRIGGER _contracts_delete BEFORE DELETE ON contracts BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO contracts(rowid,contract_id,tx_index,tx_hash,block_index,source,code,nonce) VALUES('||old.rowid||','||quote(old.contract_id)||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.code)||','||quote(old.nonce)||')');
                            END;
CREATE TRIGGER _contracts_insert AFTER INSERT ON contracts BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM contracts WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _contracts_update AFTER UPDATE ON contracts BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE contracts SET contract_id='||quote(old.contract_id)||',tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',code='||quote(old.code)||',nonce='||quote(old.nonce)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX contract_id_idx ON contracts(contract_id);

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
INSERT INTO credits VALUES(310000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',93000000000,'burn','c1e905bc5cf715a830da1f202d03bb78d177fb9e17db793dc3269071d30dc345');
INSERT INTO credits VALUES(310001,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',50000000,'send','92d9d45e6feabf91ebf6912f1c3e26b2ae04469c134ac0f92c7f6db228de8584');
INSERT INTO credits VALUES(310004,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',100000000,'btcpay','765c5cdda1caa7e72af778b3914bc52376d05c3871e23da10aabe6f796f58d7e');
INSERT INTO credits VALUES(310005,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',1000000000,'issuance','2e8c72cbaa25b29c23ac87bb3d3ceaa8dbdeceb19f42209024b2f16200c8946d');
INSERT INTO credits VALUES(310006,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC',100000,'issuance','d197c133227ec1c2b049aa4d24efdae2d98edc8c74a2d505adea850379720042');
INSERT INTO credits VALUES(310007,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBB',4000000,'send','400483954b5a99ec8019524308c098d51c8a6adcaa6bdf421263c84f31580318');
INSERT INTO credits VALUES(310008,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',526,'send','9b2e794a3db76fe990da1ecb69f4f2fe30314fc7db3de3c3acde362f61f81b6e');
INSERT INTO credits VALUES(310009,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',24,'dividend','5714d20a8672800bcf9820a44452e4cda325ab55fd12a882364f8388bb149870');
INSERT INTO credits VALUES(310010,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',420800,'dividend','f822c423ecc41bcab9bf42b5c0ff7f9453b4363fb9ddb6347bcc0e302f378fc2');
INSERT INTO credits VALUES(310013,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',4250000,'filled','f964ef723387946ba8ea78589e5772370ad0909a985cd83a281d26f192fe6bbb');
INSERT INTO credits VALUES(310014,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',5000000,'cancel order','1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf');
INSERT INTO credits VALUES(310015,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',0,'filled','6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300');
INSERT INTO credits VALUES(310015,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',0,'filled','6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300');
INSERT INTO credits VALUES(310017,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',0,'filled','f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0');
INSERT INTO credits VALUES(310017,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',0,'filled','f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0');
INSERT INTO credits VALUES(310018,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',59137500,'bet settled: liquidated for bear','bfdd28d2bea919d8dfb1a7610a84c58d2b5cf8cf81cf5f4a2f98b0e7b387f82e');
INSERT INTO credits VALUES(310018,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',3112500,'feed fee','bfdd28d2bea919d8dfb1a7610a84c58d2b5cf8cf81cf5f4a2f98b0e7b387f82e');
INSERT INTO credits VALUES(310019,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',159300000,'bet settled','d01b89fe3d1ef6536fe268d84685706362f11493b8ae118db5c0712c7ba407a5');
INSERT INTO credits VALUES(310019,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',315700000,'bet settled','d01b89fe3d1ef6536fe268d84685706362f11493b8ae118db5c0712c7ba407a5');
INSERT INTO credits VALUES(310019,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',25000000,'feed fee','d01b89fe3d1ef6536fe268d84685706362f11493b8ae118db5c0712c7ba407a5');
INSERT INTO credits VALUES(310020,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',1330000000,'bet settled: for notequal','07309373ba2b262a3171265f9ccd9ad551acfd9cc46afa80af8eecc1aef9919d');
INSERT INTO credits VALUES(310020,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',70000000,'feed fee','07309373ba2b262a3171265f9ccd9ad551acfd9cc46afa80af8eecc1aef9919d');
INSERT INTO credits VALUES(310022,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',56999887262,'burn','a3df7986a348290efe1842d8c904688840c99655fc7dd96497d0c25caa86df72');
INSERT INTO credits VALUES(310023,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',8500000,'recredit wager remaining','936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f');
INSERT INTO credits VALUES(310023,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',10000,'send','2bcfc083fa3ea20dba690ee1e2c4e17d53dafd6fcc1799152a3e00525509cd7e');
INSERT INTO credits VALUES(310032,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',50000000,'cancel order','e9473a9fa150886f864f1ae0375a131f16defcc34cef67375eb87787bc8ae0a0');
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
INSERT INTO debits VALUES(310001,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',50000000,'send','92d9d45e6feabf91ebf6912f1c3e26b2ae04469c134ac0f92c7f6db228de8584');
INSERT INTO debits VALUES(310003,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',105000000,'open order','1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf');
INSERT INTO debits VALUES(310005,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',50000000,'issuance fee','2e8c72cbaa25b29c23ac87bb3d3ceaa8dbdeceb19f42209024b2f16200c8946d');
INSERT INTO debits VALUES(310006,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',50000000,'issuance fee','d197c133227ec1c2b049aa4d24efdae2d98edc8c74a2d505adea850379720042');
INSERT INTO debits VALUES(310007,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',4000000,'send','400483954b5a99ec8019524308c098d51c8a6adcaa6bdf421263c84f31580318');
INSERT INTO debits VALUES(310008,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC',526,'send','9b2e794a3db76fe990da1ecb69f4f2fe30314fc7db3de3c3acde362f61f81b6e');
INSERT INTO debits VALUES(310009,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',24,'dividend','5714d20a8672800bcf9820a44452e4cda325ab55fd12a882364f8388bb149870');
INSERT INTO debits VALUES(310009,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',20000,'dividend fee','5714d20a8672800bcf9820a44452e4cda325ab55fd12a882364f8388bb149870');
INSERT INTO debits VALUES(310010,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',420800,'dividend','f822c423ecc41bcab9bf42b5c0ff7f9453b4363fb9ddb6347bcc0e302f378fc2');
INSERT INTO debits VALUES(310010,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',20000,'dividend fee','f822c423ecc41bcab9bf42b5c0ff7f9453b4363fb9ddb6347bcc0e302f378fc2');
INSERT INTO debits VALUES(310012,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',50000000,'bet','936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f');
INSERT INTO debits VALUES(310013,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',25000000,'bet','f964ef723387946ba8ea78589e5772370ad0909a985cd83a281d26f192fe6bbb');
INSERT INTO debits VALUES(310014,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',150000000,'bet','4a4eb3b3f79303bc6b2f37f049c145808164176f996edaddba16320b7eb0bf0d');
INSERT INTO debits VALUES(310015,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',350000000,'bet','6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300');
INSERT INTO debits VALUES(310016,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',750000000,'bet','cee3a40d67546871412e28c6210d70713b46597718ab72d4a62944555e51a2a8');
INSERT INTO debits VALUES(310017,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',650000000,'bet','f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0');
INSERT INTO debits VALUES(310021,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',50000000,'open order','e9473a9fa150886f864f1ae0375a131f16defcc34cef67375eb87787bc8ae0a0');
INSERT INTO debits VALUES(310023,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC',10000,'send','2bcfc083fa3ea20dba690ee1e2c4e17d53dafd6fcc1799152a3e00525509cd7e');
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
INSERT INTO dividends VALUES(10,'5714d20a8672800bcf9820a44452e4cda325ab55fd12a882364f8388bb149870',310009,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB','XCP',600,20000,'valid');
INSERT INTO dividends VALUES(11,'f822c423ecc41bcab9bf42b5c0ff7f9453b4363fb9ddb6347bcc0e302f378fc2',310010,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC','XCP',800,20000,'valid');
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

-- Table  executions
DROP TABLE IF EXISTS executions;
CREATE TABLE executions(
                      tx_index INTEGER UNIQUE,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      contract_id TEXT,
                      gas_price INTEGER,
                      gas_start INTEGER,
                      gas_cost INTEGER,
                      gas_remained INTEGER,
                      value INTEGER,
                      data BLOB,
                      output BLOB,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
-- Triggers and indices on  executions
CREATE TRIGGER _executions_delete BEFORE DELETE ON executions BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO executions(rowid,tx_index,tx_hash,block_index,source,contract_id,gas_price,gas_start,gas_cost,gas_remained,value,data,output,status) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.contract_id)||','||quote(old.gas_price)||','||quote(old.gas_start)||','||quote(old.gas_cost)||','||quote(old.gas_remained)||','||quote(old.value)||','||quote(old.data)||','||quote(old.output)||','||quote(old.status)||')');
                            END;
CREATE TRIGGER _executions_insert AFTER INSERT ON executions BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM executions WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _executions_update AFTER UPDATE ON executions BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE executions SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',contract_id='||quote(old.contract_id)||',gas_price='||quote(old.gas_price)||',gas_start='||quote(old.gas_start)||',gas_cost='||quote(old.gas_cost)||',gas_remained='||quote(old.gas_remained)||',value='||quote(old.value)||',data='||quote(old.data)||',output='||quote(old.output)||',status='||quote(old.status)||' WHERE rowid='||old.rowid);
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
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
INSERT INTO issuances VALUES(6,'2e8c72cbaa25b29c23ac87bb3d3ceaa8dbdeceb19f42209024b2f16200c8946d',310005,'BBBB',1000000000,1,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,0,0,0.0,'',50000000,0,'valid');
INSERT INTO issuances VALUES(7,'d197c133227ec1c2b049aa4d24efdae2d98edc8c74a2d505adea850379720042',310006,'BBBC',100000,0,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,0,0,0.0,'foobar',50000000,0,'valid');
-- Triggers and indices on  issuances
CREATE TRIGGER _issuances_delete BEFORE DELETE ON issuances BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO issuances(rowid,tx_index,tx_hash,block_index,asset,quantity,divisible,source,issuer,transfer,callable,call_date,call_price,description,fee_paid,locked,status) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.asset)||','||quote(old.quantity)||','||quote(old.divisible)||','||quote(old.source)||','||quote(old.issuer)||','||quote(old.transfer)||','||quote(old.callable)||','||quote(old.call_date)||','||quote(old.call_price)||','||quote(old.description)||','||quote(old.fee_paid)||','||quote(old.locked)||','||quote(old.status)||')');
                            END;
CREATE TRIGGER _issuances_insert AFTER INSERT ON issuances BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM issuances WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _issuances_update AFTER UPDATE ON issuances BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE issuances SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',asset='||quote(old.asset)||',quantity='||quote(old.quantity)||',divisible='||quote(old.divisible)||',source='||quote(old.source)||',issuer='||quote(old.issuer)||',transfer='||quote(old.transfer)||',callable='||quote(old.callable)||',call_date='||quote(old.call_date)||',call_price='||quote(old.call_price)||',description='||quote(old.description)||',fee_paid='||quote(old.fee_paid)||',locked='||quote(old.locked)||',status='||quote(old.status)||' WHERE rowid='||old.rowid);
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
INSERT INTO messages VALUES(0,310000,'insert','credits','{"action": "burn", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310000, "event": "c1e905bc5cf715a830da1f202d03bb78d177fb9e17db793dc3269071d30dc345", "quantity": 93000000000}',0);
INSERT INTO messages VALUES(1,310000,'insert','burns','{"block_index": 310000, "burned": 62000000, "earned": 93000000000, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "c1e905bc5cf715a830da1f202d03bb78d177fb9e17db793dc3269071d30dc345", "tx_index": 1}',0);
INSERT INTO messages VALUES(2,310001,'insert','debits','{"action": "send", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310001, "event": "92d9d45e6feabf91ebf6912f1c3e26b2ae04469c134ac0f92c7f6db228de8584", "quantity": 50000000}',0);
INSERT INTO messages VALUES(3,310001,'insert','credits','{"action": "send", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "asset": "XCP", "block_index": 310001, "event": "92d9d45e6feabf91ebf6912f1c3e26b2ae04469c134ac0f92c7f6db228de8584", "quantity": 50000000}',0);
INSERT INTO messages VALUES(4,310001,'insert','sends','{"asset": "XCP", "block_index": 310001, "destination": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "quantity": 50000000, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "92d9d45e6feabf91ebf6912f1c3e26b2ae04469c134ac0f92c7f6db228de8584", "tx_index": 2}',0);
INSERT INTO messages VALUES(5,310002,'insert','orders','{"block_index": 310002, "expiration": 10, "expire_index": 310012, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 50000000, "give_remaining": 50000000, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "tx_hash": "17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b", "tx_index": 3}',0);
INSERT INTO messages VALUES(6,310003,'insert','debits','{"action": "open order", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310003, "event": "1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf", "quantity": 105000000}',0);
INSERT INTO messages VALUES(7,310003,'insert','orders','{"block_index": 310003, "expiration": 10, "expire_index": 310013, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 50000000, "get_remaining": 50000000, "give_asset": "XCP", "give_quantity": 105000000, "give_remaining": 105000000, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "tx_hash": "1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf", "tx_index": 4}',0);
INSERT INTO messages VALUES(8,310003,'update','orders','{"fee_provided_remaining": 142858, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b"}',0);
INSERT INTO messages VALUES(9,310003,'update','orders','{"fee_provided_remaining": 6800, "fee_required_remaining": 42858, "get_remaining": 0, "give_remaining": 5000000, "status": "open", "tx_hash": "1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf"}',0);
INSERT INTO messages VALUES(10,310003,'insert','order_matches','{"backward_asset": "XCP", "backward_quantity": 100000000, "block_index": 310003, "fee_paid": 857142, "forward_asset": "BTC", "forward_quantity": 50000000, "id": "17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b_1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf", "match_expire_index": 310023, "status": "pending", "tx0_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx0_block_index": 310002, "tx0_expiration": 10, "tx0_hash": "17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b", "tx0_index": 3, "tx1_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx1_block_index": 310003, "tx1_expiration": 10, "tx1_hash": "1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf", "tx1_index": 4}',0);
INSERT INTO messages VALUES(11,310004,'insert','credits','{"action": "btcpay", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310004, "event": "765c5cdda1caa7e72af778b3914bc52376d05c3871e23da10aabe6f796f58d7e", "quantity": 100000000}',0);
INSERT INTO messages VALUES(12,310004,'update','order_matches','{"order_match_id": "17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b_1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf", "status": "completed"}',0);
INSERT INTO messages VALUES(13,310004,'insert','btcpays','{"block_index": 310004, "btc_amount": 50000000, "destination": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "order_match_id": "17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b_1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf", "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "765c5cdda1caa7e72af778b3914bc52376d05c3871e23da10aabe6f796f58d7e", "tx_index": 5}',0);
INSERT INTO messages VALUES(14,310005,'insert','debits','{"action": "issuance fee", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310005, "event": "2e8c72cbaa25b29c23ac87bb3d3ceaa8dbdeceb19f42209024b2f16200c8946d", "quantity": 50000000}',0);
INSERT INTO messages VALUES(15,310005,'insert','issuances','{"asset": "BBBB", "block_index": 310005, "call_date": 0, "call_price": 0.0, "callable": false, "description": "", "divisible": true, "fee_paid": 50000000, "issuer": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "locked": false, "quantity": 1000000000, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "transfer": false, "tx_hash": "2e8c72cbaa25b29c23ac87bb3d3ceaa8dbdeceb19f42209024b2f16200c8946d", "tx_index": 6}',0);
INSERT INTO messages VALUES(16,310005,'insert','credits','{"action": "issuance", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBB", "block_index": 310005, "event": "2e8c72cbaa25b29c23ac87bb3d3ceaa8dbdeceb19f42209024b2f16200c8946d", "quantity": 1000000000}',0);
INSERT INTO messages VALUES(17,310006,'insert','debits','{"action": "issuance fee", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310006, "event": "d197c133227ec1c2b049aa4d24efdae2d98edc8c74a2d505adea850379720042", "quantity": 50000000}',0);
INSERT INTO messages VALUES(18,310006,'insert','issuances','{"asset": "BBBC", "block_index": 310006, "call_date": 0, "call_price": 0.0, "callable": false, "description": "foobar", "divisible": false, "fee_paid": 50000000, "issuer": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "locked": false, "quantity": 100000, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "transfer": false, "tx_hash": "d197c133227ec1c2b049aa4d24efdae2d98edc8c74a2d505adea850379720042", "tx_index": 7}',0);
INSERT INTO messages VALUES(19,310006,'insert','credits','{"action": "issuance", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBC", "block_index": 310006, "event": "d197c133227ec1c2b049aa4d24efdae2d98edc8c74a2d505adea850379720042", "quantity": 100000}',0);
INSERT INTO messages VALUES(20,310007,'insert','debits','{"action": "send", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBB", "block_index": 310007, "event": "400483954b5a99ec8019524308c098d51c8a6adcaa6bdf421263c84f31580318", "quantity": 4000000}',0);
INSERT INTO messages VALUES(21,310007,'insert','credits','{"action": "send", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "asset": "BBBB", "block_index": 310007, "event": "400483954b5a99ec8019524308c098d51c8a6adcaa6bdf421263c84f31580318", "quantity": 4000000}',0);
INSERT INTO messages VALUES(22,310007,'insert','sends','{"asset": "BBBB", "block_index": 310007, "destination": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "quantity": 4000000, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "400483954b5a99ec8019524308c098d51c8a6adcaa6bdf421263c84f31580318", "tx_index": 8}',0);
INSERT INTO messages VALUES(23,310008,'insert','debits','{"action": "send", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBC", "block_index": 310008, "event": "9b2e794a3db76fe990da1ecb69f4f2fe30314fc7db3de3c3acde362f61f81b6e", "quantity": 526}',0);
INSERT INTO messages VALUES(24,310008,'insert','credits','{"action": "send", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "asset": "BBBC", "block_index": 310008, "event": "9b2e794a3db76fe990da1ecb69f4f2fe30314fc7db3de3c3acde362f61f81b6e", "quantity": 526}',0);
INSERT INTO messages VALUES(25,310008,'insert','sends','{"asset": "BBBC", "block_index": 310008, "destination": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "quantity": 526, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "9b2e794a3db76fe990da1ecb69f4f2fe30314fc7db3de3c3acde362f61f81b6e", "tx_index": 9}',0);
INSERT INTO messages VALUES(26,310009,'insert','debits','{"action": "dividend", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310009, "event": "5714d20a8672800bcf9820a44452e4cda325ab55fd12a882364f8388bb149870", "quantity": 24}',0);
INSERT INTO messages VALUES(27,310009,'insert','debits','{"action": "dividend fee", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310009, "event": "5714d20a8672800bcf9820a44452e4cda325ab55fd12a882364f8388bb149870", "quantity": 20000}',0);
INSERT INTO messages VALUES(28,310009,'insert','credits','{"action": "dividend", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "asset": "XCP", "block_index": 310009, "event": "5714d20a8672800bcf9820a44452e4cda325ab55fd12a882364f8388bb149870", "quantity": 24}',0);
INSERT INTO messages VALUES(29,310009,'insert','dividends','{"asset": "BBBB", "block_index": 310009, "dividend_asset": "XCP", "fee_paid": 20000, "quantity_per_unit": 600, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "5714d20a8672800bcf9820a44452e4cda325ab55fd12a882364f8388bb149870", "tx_index": 10}',0);
INSERT INTO messages VALUES(30,310010,'insert','debits','{"action": "dividend", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310010, "event": "f822c423ecc41bcab9bf42b5c0ff7f9453b4363fb9ddb6347bcc0e302f378fc2", "quantity": 420800}',0);
INSERT INTO messages VALUES(31,310010,'insert','debits','{"action": "dividend fee", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310010, "event": "f822c423ecc41bcab9bf42b5c0ff7f9453b4363fb9ddb6347bcc0e302f378fc2", "quantity": 20000}',0);
INSERT INTO messages VALUES(32,310010,'insert','credits','{"action": "dividend", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "asset": "XCP", "block_index": 310010, "event": "f822c423ecc41bcab9bf42b5c0ff7f9453b4363fb9ddb6347bcc0e302f378fc2", "quantity": 420800}',0);
INSERT INTO messages VALUES(33,310010,'insert','dividends','{"asset": "BBBC", "block_index": 310010, "dividend_asset": "XCP", "fee_paid": 20000, "quantity_per_unit": 800, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "f822c423ecc41bcab9bf42b5c0ff7f9453b4363fb9ddb6347bcc0e302f378fc2", "tx_index": 11}',0);
INSERT INTO messages VALUES(34,310011,'insert','broadcasts','{"block_index": 310011, "fee_fraction_int": 5000000, "locked": false, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "80a69d4dab4de7a852c30cde4ba6485f56bff5ff5fd842412b04c8a707b990a1", "tx_index": 12, "value": 100.0}',0);
INSERT INTO messages VALUES(35,310012,'insert','debits','{"action": "bet", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310012, "event": "936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f", "quantity": 50000000}',0);
INSERT INTO messages VALUES(36,310012,'insert','bets','{"bet_type": 0, "block_index": 310012, "counterwager_quantity": 25000000, "counterwager_remaining": 25000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310022, "fee_fraction_int": 5000000.0, "feed_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "leverage": 15120, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "target_value": 0.0, "tx_hash": "936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f", "tx_index": 13, "wager_quantity": 50000000, "wager_remaining": 50000000}',0);
INSERT INTO messages VALUES(37,310013,'update','orders','{"status": "expired", "tx_hash": "17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b"}',0);
INSERT INTO messages VALUES(38,310013,'insert','order_expirations','{"block_index": 310013, "order_hash": "17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b", "order_index": 3, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3"}',0);
INSERT INTO messages VALUES(39,310013,'insert','debits','{"action": "bet", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310013, "event": "f964ef723387946ba8ea78589e5772370ad0909a985cd83a281d26f192fe6bbb", "quantity": 25000000}',0);
INSERT INTO messages VALUES(40,310013,'insert','bets','{"bet_type": 1, "block_index": 310013, "counterwager_quantity": 41500000, "counterwager_remaining": 41500000, "deadline": 1388000100, "expiration": 10, "expire_index": 310023, "fee_fraction_int": 5000000.0, "feed_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "leverage": 15120, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "target_value": 0.0, "tx_hash": "f964ef723387946ba8ea78589e5772370ad0909a985cd83a281d26f192fe6bbb", "tx_index": 14, "wager_quantity": 25000000, "wager_remaining": 25000000}',0);
INSERT INTO messages VALUES(41,310013,'update','bets','{"counterwager_remaining": 4250000, "status": "open", "tx_hash": "936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f", "wager_remaining": 8500000}',0);
INSERT INTO messages VALUES(42,310013,'insert','credits','{"action": "filled", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310013, "event": "f964ef723387946ba8ea78589e5772370ad0909a985cd83a281d26f192fe6bbb", "quantity": 4250000}',0);
INSERT INTO messages VALUES(43,310013,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "f964ef723387946ba8ea78589e5772370ad0909a985cd83a281d26f192fe6bbb", "wager_remaining": 4250000}',0);
INSERT INTO messages VALUES(44,310013,'insert','bet_matches','{"backward_quantity": 20750000, "block_index": 310013, "deadline": 1388000100, "fee_fraction_int": 5000000, "feed_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "forward_quantity": 41500000, "id": "936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f_f964ef723387946ba8ea78589e5772370ad0909a985cd83a281d26f192fe6bbb", "initial_value": 100.0, "leverage": 15120, "match_expire_index": 310022, "status": "pending", "target_value": 0.0, "tx0_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx0_bet_type": 0, "tx0_block_index": 310012, "tx0_expiration": 10, "tx0_hash": "936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f", "tx0_index": 13, "tx1_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx1_bet_type": 1, "tx1_block_index": 310013, "tx1_expiration": 10, "tx1_hash": "f964ef723387946ba8ea78589e5772370ad0909a985cd83a281d26f192fe6bbb", "tx1_index": 14}',0);
INSERT INTO messages VALUES(45,310014,'update','orders','{"status": "expired", "tx_hash": "1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf"}',0);
INSERT INTO messages VALUES(46,310014,'insert','credits','{"action": "cancel order", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310014, "event": "1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf", "quantity": 5000000}',0);
INSERT INTO messages VALUES(47,310014,'insert','order_expirations','{"block_index": 310014, "order_hash": "1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf", "order_index": 4, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3"}',0);
INSERT INTO messages VALUES(48,310014,'insert','debits','{"action": "bet", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310014, "event": "4a4eb3b3f79303bc6b2f37f049c145808164176f996edaddba16320b7eb0bf0d", "quantity": 150000000}',0);
INSERT INTO messages VALUES(49,310014,'insert','bets','{"bet_type": 0, "block_index": 310014, "counterwager_quantity": 350000000, "counterwager_remaining": 350000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310024, "fee_fraction_int": 5000000.0, "feed_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "leverage": 5040, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "target_value": 0.0, "tx_hash": "4a4eb3b3f79303bc6b2f37f049c145808164176f996edaddba16320b7eb0bf0d", "tx_index": 15, "wager_quantity": 150000000, "wager_remaining": 150000000}',0);
INSERT INTO messages VALUES(50,310015,'insert','debits','{"action": "bet", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310015, "event": "6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300", "quantity": 350000000}',0);
INSERT INTO messages VALUES(51,310015,'insert','bets','{"bet_type": 1, "block_index": 310015, "counterwager_quantity": 150000000, "counterwager_remaining": 150000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310025, "fee_fraction_int": 5000000.0, "feed_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "leverage": 5040, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "target_value": 0.0, "tx_hash": "6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300", "tx_index": 16, "wager_quantity": 350000000, "wager_remaining": 350000000}',0);
INSERT INTO messages VALUES(52,310015,'insert','credits','{"action": "filled", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310015, "event": "6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300", "quantity": 0}',0);
INSERT INTO messages VALUES(53,310015,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "4a4eb3b3f79303bc6b2f37f049c145808164176f996edaddba16320b7eb0bf0d", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(54,310015,'insert','credits','{"action": "filled", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310015, "event": "6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300", "quantity": 0}',0);
INSERT INTO messages VALUES(55,310015,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(56,310015,'insert','bet_matches','{"backward_quantity": 350000000, "block_index": 310015, "deadline": 1388000100, "fee_fraction_int": 5000000, "feed_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "forward_quantity": 150000000, "id": "4a4eb3b3f79303bc6b2f37f049c145808164176f996edaddba16320b7eb0bf0d_6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300", "initial_value": 100.0, "leverage": 5040, "match_expire_index": 310024, "status": "pending", "target_value": 0.0, "tx0_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx0_bet_type": 0, "tx0_block_index": 310014, "tx0_expiration": 10, "tx0_hash": "4a4eb3b3f79303bc6b2f37f049c145808164176f996edaddba16320b7eb0bf0d", "tx0_index": 15, "tx1_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx1_bet_type": 1, "tx1_block_index": 310015, "tx1_expiration": 10, "tx1_hash": "6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300", "tx1_index": 16}',0);
INSERT INTO messages VALUES(57,310016,'insert','debits','{"action": "bet", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310016, "event": "cee3a40d67546871412e28c6210d70713b46597718ab72d4a62944555e51a2a8", "quantity": 750000000}',0);
INSERT INTO messages VALUES(58,310016,'insert','bets','{"bet_type": 2, "block_index": 310016, "counterwager_quantity": 650000000, "counterwager_remaining": 650000000, "deadline": 1388000200, "expiration": 10, "expire_index": 310026, "fee_fraction_int": 5000000.0, "feed_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "leverage": 5040, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "target_value": 1.0, "tx_hash": "cee3a40d67546871412e28c6210d70713b46597718ab72d4a62944555e51a2a8", "tx_index": 17, "wager_quantity": 750000000, "wager_remaining": 750000000}',0);
INSERT INTO messages VALUES(59,310017,'insert','debits','{"action": "bet", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310017, "event": "f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0", "quantity": 650000000}',0);
INSERT INTO messages VALUES(60,310017,'insert','bets','{"bet_type": 3, "block_index": 310017, "counterwager_quantity": 750000000, "counterwager_remaining": 750000000, "deadline": 1388000200, "expiration": 10, "expire_index": 310027, "fee_fraction_int": 5000000.0, "feed_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "leverage": 5040, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "target_value": 1.0, "tx_hash": "f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0", "tx_index": 18, "wager_quantity": 650000000, "wager_remaining": 650000000}',0);
INSERT INTO messages VALUES(61,310017,'insert','credits','{"action": "filled", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310017, "event": "f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0", "quantity": 0}',0);
INSERT INTO messages VALUES(62,310017,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "cee3a40d67546871412e28c6210d70713b46597718ab72d4a62944555e51a2a8", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(63,310017,'insert','credits','{"action": "filled", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310017, "event": "f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0", "quantity": 0}',0);
INSERT INTO messages VALUES(64,310017,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(65,310017,'insert','bet_matches','{"backward_quantity": 650000000, "block_index": 310017, "deadline": 1388000200, "fee_fraction_int": 5000000, "feed_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "forward_quantity": 750000000, "id": "cee3a40d67546871412e28c6210d70713b46597718ab72d4a62944555e51a2a8_f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0", "initial_value": 100.0, "leverage": 5040, "match_expire_index": 310026, "status": "pending", "target_value": 1.0, "tx0_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx0_bet_type": 2, "tx0_block_index": 310016, "tx0_expiration": 10, "tx0_hash": "cee3a40d67546871412e28c6210d70713b46597718ab72d4a62944555e51a2a8", "tx0_index": 17, "tx1_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx1_bet_type": 3, "tx1_block_index": 310017, "tx1_expiration": 10, "tx1_hash": "f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0", "tx1_index": 18}',0);
INSERT INTO messages VALUES(66,310018,'insert','broadcasts','{"block_index": 310018, "fee_fraction_int": 5000000, "locked": false, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "text": "Unit Test", "timestamp": 1388000050, "tx_hash": "bfdd28d2bea919d8dfb1a7610a84c58d2b5cf8cf81cf5f4a2f98b0e7b387f82e", "tx_index": 19, "value": 99.86166}',0);
INSERT INTO messages VALUES(67,310018,'insert','credits','{"action": "bet settled: liquidated for bear", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310018, "event": "bfdd28d2bea919d8dfb1a7610a84c58d2b5cf8cf81cf5f4a2f98b0e7b387f82e", "quantity": 59137500}',0);
INSERT INTO messages VALUES(68,310018,'insert','credits','{"action": "feed fee", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310018, "event": "bfdd28d2bea919d8dfb1a7610a84c58d2b5cf8cf81cf5f4a2f98b0e7b387f82e", "quantity": 3112500}',0);
INSERT INTO messages VALUES(69,310018,'insert','bet_match_resolutions','{"bear_credit": 59137500, "bet_match_id": "936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f_f964ef723387946ba8ea78589e5772370ad0909a985cd83a281d26f192fe6bbb", "bet_match_type_id": 1, "block_index": 310018, "bull_credit": 0, "escrow_less_fee": null, "fee": 3112500, "settled": false, "winner": null}',0);
INSERT INTO messages VALUES(70,310018,'update','bet_matches','{"bet_match_id": "936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f_f964ef723387946ba8ea78589e5772370ad0909a985cd83a281d26f192fe6bbb", "status": "settled: liquidated for bear"}',0);
INSERT INTO messages VALUES(71,310019,'insert','broadcasts','{"block_index": 310019, "fee_fraction_int": 5000000, "locked": false, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "text": "Unit Test", "timestamp": 1388000101, "tx_hash": "d01b89fe3d1ef6536fe268d84685706362f11493b8ae118db5c0712c7ba407a5", "tx_index": 20, "value": 100.343}',0);
INSERT INTO messages VALUES(72,310019,'insert','credits','{"action": "bet settled", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310019, "event": "d01b89fe3d1ef6536fe268d84685706362f11493b8ae118db5c0712c7ba407a5", "quantity": 159300000}',0);
INSERT INTO messages VALUES(73,310019,'insert','credits','{"action": "bet settled", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310019, "event": "d01b89fe3d1ef6536fe268d84685706362f11493b8ae118db5c0712c7ba407a5", "quantity": 315700000}',0);
INSERT INTO messages VALUES(74,310019,'insert','credits','{"action": "feed fee", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310019, "event": "d01b89fe3d1ef6536fe268d84685706362f11493b8ae118db5c0712c7ba407a5", "quantity": 25000000}',0);
INSERT INTO messages VALUES(75,310019,'insert','bet_match_resolutions','{"bear_credit": 315700000, "bet_match_id": "4a4eb3b3f79303bc6b2f37f049c145808164176f996edaddba16320b7eb0bf0d_6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300", "bet_match_type_id": 1, "block_index": 310019, "bull_credit": 159300000, "escrow_less_fee": null, "fee": 25000000, "settled": true, "winner": null}',0);
INSERT INTO messages VALUES(76,310019,'update','bet_matches','{"bet_match_id": "4a4eb3b3f79303bc6b2f37f049c145808164176f996edaddba16320b7eb0bf0d_6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300", "status": "settled"}',0);
INSERT INTO messages VALUES(77,310020,'insert','broadcasts','{"block_index": 310020, "fee_fraction_int": 5000000, "locked": false, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "text": "Unit Test", "timestamp": 1388000201, "tx_hash": "07309373ba2b262a3171265f9ccd9ad551acfd9cc46afa80af8eecc1aef9919d", "tx_index": 21, "value": 2.0}',0);
INSERT INTO messages VALUES(78,310020,'insert','credits','{"action": "bet settled: for notequal", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310020, "event": "07309373ba2b262a3171265f9ccd9ad551acfd9cc46afa80af8eecc1aef9919d", "quantity": 1330000000}',0);
INSERT INTO messages VALUES(79,310020,'insert','credits','{"action": "feed fee", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310020, "event": "07309373ba2b262a3171265f9ccd9ad551acfd9cc46afa80af8eecc1aef9919d", "quantity": 70000000}',0);
INSERT INTO messages VALUES(80,310020,'insert','bet_match_resolutions','{"bear_credit": null, "bet_match_id": "cee3a40d67546871412e28c6210d70713b46597718ab72d4a62944555e51a2a8_f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0", "bet_match_type_id": 5, "block_index": 310020, "bull_credit": null, "escrow_less_fee": 1330000000, "fee": 70000000, "settled": null, "winner": "NotEqual"}',0);
INSERT INTO messages VALUES(81,310020,'update','bet_matches','{"bet_match_id": "cee3a40d67546871412e28c6210d70713b46597718ab72d4a62944555e51a2a8_f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0", "status": "settled: for notequal"}',0);
INSERT INTO messages VALUES(82,310021,'insert','debits','{"action": "open order", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBB", "block_index": 310021, "event": "e9473a9fa150886f864f1ae0375a131f16defcc34cef67375eb87787bc8ae0a0", "quantity": 50000000}',0);
INSERT INTO messages VALUES(83,310021,'insert','orders','{"block_index": 310021, "expiration": 10, "expire_index": 310031, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 50000000, "get_remaining": 50000000, "give_asset": "BBBB", "give_quantity": 50000000, "give_remaining": 50000000, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "tx_hash": "e9473a9fa150886f864f1ae0375a131f16defcc34cef67375eb87787bc8ae0a0", "tx_index": 22}',0);
INSERT INTO messages VALUES(84,310022,'insert','credits','{"action": "burn", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310022, "event": "a3df7986a348290efe1842d8c904688840c99655fc7dd96497d0c25caa86df72", "quantity": 56999887262}',0);
INSERT INTO messages VALUES(85,310022,'insert','burns','{"block_index": 310022, "burned": 38000000, "earned": 56999887262, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "a3df7986a348290efe1842d8c904688840c99655fc7dd96497d0c25caa86df72", "tx_index": 23}',0);
INSERT INTO messages VALUES(86,310023,'update','bets','{"status": "expired", "tx_hash": "936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f"}',0);
INSERT INTO messages VALUES(87,310023,'insert','credits','{"action": "recredit wager remaining", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310023, "event": "936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f", "quantity": 8500000}',0);
INSERT INTO messages VALUES(88,310023,'insert','bet_expirations','{"bet_hash": "936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f", "bet_index": 13, "block_index": 310023, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3"}',0);
INSERT INTO messages VALUES(89,310023,'insert','debits','{"action": "send", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBC", "block_index": 310023, "event": "2bcfc083fa3ea20dba690ee1e2c4e17d53dafd6fcc1799152a3e00525509cd7e", "quantity": 10000}',0);
INSERT INTO messages VALUES(90,310023,'insert','credits','{"action": "send", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "asset": "BBBC", "block_index": 310023, "event": "2bcfc083fa3ea20dba690ee1e2c4e17d53dafd6fcc1799152a3e00525509cd7e", "quantity": 10000}',0);
INSERT INTO messages VALUES(91,310023,'insert','sends','{"asset": "BBBC", "block_index": 310023, "destination": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "quantity": 10000, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "2bcfc083fa3ea20dba690ee1e2c4e17d53dafd6fcc1799152a3e00525509cd7e", "tx_index": 24}',0);
INSERT INTO messages VALUES(92,310032,'update','orders','{"status": "expired", "tx_hash": "e9473a9fa150886f864f1ae0375a131f16defcc34cef67375eb87787bc8ae0a0"}',0);
INSERT INTO messages VALUES(93,310032,'insert','credits','{"action": "cancel order", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBB", "block_index": 310032, "event": "e9473a9fa150886f864f1ae0375a131f16defcc34cef67375eb87787bc8ae0a0", "quantity": 50000000}',0);
INSERT INTO messages VALUES(94,310032,'insert','order_expirations','{"block_index": 310032, "order_hash": "e9473a9fa150886f864f1ae0375a131f16defcc34cef67375eb87787bc8ae0a0", "order_index": 22, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3"}',0);
-- Triggers and indices on  messages
CREATE INDEX block_index_message_index_idx ON messages (block_index, message_index);

-- Table  nonces
DROP TABLE IF EXISTS nonces;
CREATE TABLE nonces(
                      address TEXT PRIMARY KEY,
                      nonce INTEGER);
-- Triggers and indices on  nonces
CREATE TRIGGER _nonces_delete BEFORE DELETE ON nonces BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO nonces(rowid,address,nonce) VALUES('||old.rowid||','||quote(old.address)||','||quote(old.nonce)||')');
                            END;
CREATE TRIGGER _nonces_insert AFTER INSERT ON nonces BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM nonces WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _nonces_update AFTER UPDATE ON nonces BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE nonces SET address='||quote(old.address)||',nonce='||quote(old.nonce)||' WHERE rowid='||old.rowid);
                            END;

-- Table  order_expirations
DROP TABLE IF EXISTS order_expirations;
CREATE TABLE order_expirations(
                      order_index INTEGER PRIMARY KEY,
                      order_hash TEXT UNIQUE,
                      source TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index),
                      FOREIGN KEY (order_index, order_hash) REFERENCES orders(tx_index, tx_hash));
INSERT INTO order_expirations VALUES(3,'17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',310013);
INSERT INTO order_expirations VALUES(4,'1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',310014);
INSERT INTO order_expirations VALUES(22,'e9473a9fa150886f864f1ae0375a131f16defcc34cef67375eb87787bc8ae0a0','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',310032);
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
INSERT INTO order_matches VALUES('17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b_1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf',3,'17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',4,'1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BTC',50000000,'XCP',100000000,310002,310003,310003,10,10,310023,857142,'completed');
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
INSERT INTO orders VALUES(3,'17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b',310002,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BTC',50000000,0,'XCP',100000000,0,10,310012,0,0,1000000,142858,'expired');
INSERT INTO orders VALUES(4,'1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf',310003,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',105000000,5000000,'BTC',50000000,0,10,310013,900000,42858,6800,6800,'expired');
INSERT INTO orders VALUES(22,'e9473a9fa150886f864f1ae0375a131f16defcc34cef67375eb87787bc8ae0a0',310021,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',50000000,50000000,'XCP',50000000,50000000,10,310031,0,0,6800,6800,'expired');
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
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
INSERT INTO sends VALUES(2,'92d9d45e6feabf91ebf6912f1c3e26b2ae04469c134ac0f92c7f6db228de8584',310001,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',50000000,'valid');
INSERT INTO sends VALUES(8,'400483954b5a99ec8019524308c098d51c8a6adcaa6bdf421263c84f31580318',310007,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBB',4000000,'valid');
INSERT INTO sends VALUES(9,'9b2e794a3db76fe990da1ecb69f4f2fe30314fc7db3de3c3acde362f61f81b6e',310008,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',526,'valid');
INSERT INTO sends VALUES(24,'2bcfc083fa3ea20dba690ee1e2c4e17d53dafd6fcc1799152a3e00525509cd7e',310023,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',10000,'valid');
-- Triggers and indices on  sends
CREATE TRIGGER _sends_delete BEFORE DELETE ON sends BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO sends(rowid,tx_index,tx_hash,block_index,source,destination,asset,quantity,status) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.destination)||','||quote(old.asset)||','||quote(old.quantity)||','||quote(old.status)||')');
                            END;
CREATE TRIGGER _sends_insert AFTER INSERT ON sends BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM sends WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _sends_update AFTER UPDATE ON sends BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE sends SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',destination='||quote(old.destination)||',asset='||quote(old.asset)||',quantity='||quote(old.quantity)||',status='||quote(old.status)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX destination_idx ON sends (destination);
CREATE INDEX source_idx ON sends (source);

-- Table  storage
DROP TABLE IF EXISTS storage;
CREATE TABLE storage(
                      contract_id TEXT,
                      key BLOB,
                      value BLOB,
                      PRIMARY KEY(contract_id, `key`),
                      FOREIGN KEY (contract_id) REFERENCES contracts(contract_id));
-- Triggers and indices on  storage
CREATE TRIGGER _storage_delete BEFORE DELETE ON storage BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO storage(rowid,contract_id,key,value) VALUES('||old.rowid||','||quote(old.contract_id)||','||quote(old.key)||','||quote(old.value)||')');
                            END;
CREATE TRIGGER _storage_insert AFTER INSERT ON storage BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM storage WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _storage_update AFTER UPDATE ON storage BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE storage SET contract_id='||quote(old.contract_id)||',key='||quote(old.key)||',value='||quote(old.value)||' WHERE rowid='||old.rowid);
                            END;

-- Table  suicides
DROP TABLE IF EXISTS suicides;
CREATE TABLE suicides(
                      contract_id TEXT PRIMARY KEY,
                      FOREIGN KEY (contract_id) REFERENCES contracts(contract_id));
-- Triggers and indices on  suicides
CREATE TRIGGER _suicides_delete BEFORE DELETE ON suicides BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO suicides(rowid,contract_id) VALUES('||old.rowid||','||quote(old.contract_id)||')');
                            END;
CREATE TRIGGER _suicides_insert AFTER INSERT ON suicides BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM suicides WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _suicides_update AFTER UPDATE ON suicides BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE suicides SET contract_id='||quote(old.contract_id)||' WHERE rowid='||old.rowid);
                            END;

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
INSERT INTO transactions VALUES(1,'c1e905bc5cf715a830da1f202d03bb78d177fb9e17db793dc3269071d30dc345',310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
INSERT INTO transactions VALUES(2,'92d9d45e6feabf91ebf6912f1c3e26b2ae04469c134ac0f92c7f6db228de8584',310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3',7800,7650,X'0000000000000000000000010000000002FAF080',1);
INSERT INTO transactions VALUES(3,'17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b',310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,1000000,X'0000000A00000000000000000000000002FAF08000000000000000010000000005F5E100000A0000000000000000',1);
INSERT INTO transactions VALUES(4,'1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf',310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000000A00000000000000010000000006422C4000000000000000000000000002FAF080000A00000000000DBBA0',1);
INSERT INTO transactions VALUES(5,'765c5cdda1caa7e72af778b3914bc52376d05c3871e23da10aabe6f796f58d7e',310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',50000000,9675,X'0000000B17500C776ECB9D1AAD1CFA0407E2248C890537934132BB6EC52970C3530A157B1F96219C284999758BB60EE7169A3C13EC95FF5766228444D697DED138C26CCF',1);
INSERT INTO transactions VALUES(6,'2e8c72cbaa25b29c23ac87bb3d3ceaa8dbdeceb19f42209024b2f16200c8946d',310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'000000140000000000004767000000003B9ACA000100000000000000000000',1);
INSERT INTO transactions VALUES(7,'d197c133227ec1c2b049aa4d24efdae2d98edc8c74a2d505adea850379720042',310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'00000014000000000000476800000000000186A00000000000000000000006666F6F626172',1);
INSERT INTO transactions VALUES(8,'400483954b5a99ec8019524308c098d51c8a6adcaa6bdf421263c84f31580318',310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3',7800,7650,X'00000000000000000000476700000000003D0900',1);
INSERT INTO transactions VALUES(9,'9b2e794a3db76fe990da1ecb69f4f2fe30314fc7db3de3c3acde362f61f81b6e',310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3',7800,7650,X'000000000000000000004768000000000000020E',1);
INSERT INTO transactions VALUES(10,'5714d20a8672800bcf9820a44452e4cda325ab55fd12a882364f8388bb149870',310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'00000032000000000000025800000000000047670000000000000001',1);
INSERT INTO transactions VALUES(11,'f822c423ecc41bcab9bf42b5c0ff7f9453b4363fb9ddb6347bcc0e302f378fc2',310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'00000032000000000000032000000000000047680000000000000001',1);
INSERT INTO transactions VALUES(12,'80a69d4dab4de7a852c30cde4ba6485f56bff5ff5fd842412b04c8a707b990a1',310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000001E52BB33004059000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(13,'936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f',310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',7800,7650,X'00000028000052BB33640000000002FAF08000000000017D7840000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(14,'f964ef723387946ba8ea78589e5772370ad0909a985cd83a281d26f192fe6bbb',310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',7800,7650,X'00000028000152BB336400000000017D78400000000002793D60000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(15,'4a4eb3b3f79303bc6b2f37f049c145808164176f996edaddba16320b7eb0bf0d',310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',7800,7650,X'00000028000052BB33640000000008F0D1800000000014DC93800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(16,'6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300',310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',7800,7650,X'00000028000152BB33640000000014DC93800000000008F0D1800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(17,'cee3a40d67546871412e28c6210d70713b46597718ab72d4a62944555e51a2a8',310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',7800,7650,X'00000028000252BB33C8000000002CB417800000000026BE36803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(18,'f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0',310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',7800,7650,X'00000028000352BB33C80000000026BE3680000000002CB417803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(19,'bfdd28d2bea919d8dfb1a7610a84c58d2b5cf8cf81cf5f4a2f98b0e7b387f82e',310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000001E52BB33324058F7256FFC115E004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(20,'d01b89fe3d1ef6536fe268d84685706362f11493b8ae118db5c0712c7ba407a5',310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000001E52BB3365405915F3B645A1CB004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(21,'07309373ba2b262a3171265f9ccd9ad551acfd9cc46afa80af8eecc1aef9919d',310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000001E52BB33C94000000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(22,'e9473a9fa150886f864f1ae0375a131f16defcc34cef67375eb87787bc8ae0a0',310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000000A00000000000047670000000002FAF08000000000000000010000000002FAF080000A0000000000000000',1);
INSERT INTO transactions VALUES(23,'a3df7986a348290efe1842d8c904688840c99655fc7dd96497d0c25caa86df72',310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','mvCounterpartyXXXXXXXXXXXXXXW24Hef',100000000,5625,X'',1);
INSERT INTO transactions VALUES(24,'2bcfc083fa3ea20dba690ee1e2c4e17d53dafd6fcc1799152a3e00525509cd7e',310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3',7800,7650,X'0000000000000000000047680000000000002710',1);
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
INSERT INTO undolog VALUES(4,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=93000000000 WHERE rowid=1');
INSERT INTO undolog VALUES(5,'DELETE FROM debits WHERE rowid=1');
INSERT INTO undolog VALUES(6,'DELETE FROM balances WHERE rowid=2');
INSERT INTO undolog VALUES(7,'DELETE FROM credits WHERE rowid=2');
INSERT INTO undolog VALUES(8,'DELETE FROM sends WHERE rowid=2');
INSERT INTO undolog VALUES(9,'DELETE FROM orders WHERE rowid=1');
INSERT INTO undolog VALUES(10,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92950000000 WHERE rowid=1');
INSERT INTO undolog VALUES(11,'DELETE FROM debits WHERE rowid=2');
INSERT INTO undolog VALUES(12,'DELETE FROM orders WHERE rowid=2');
INSERT INTO undolog VALUES(13,'UPDATE orders SET tx_index=3,tx_hash=''17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b'',block_index=310002,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''BTC'',give_quantity=50000000,give_remaining=50000000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=10,expire_index=310012,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(14,'UPDATE orders SET tx_index=4,tx_hash=''1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf'',block_index=310003,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''XCP'',give_quantity=105000000,give_remaining=105000000,get_asset=''BTC'',get_quantity=50000000,get_remaining=50000000,expiration=10,expire_index=310013,fee_required=900000,fee_required_remaining=900000,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(15,'DELETE FROM order_matches WHERE rowid=1');
INSERT INTO undolog VALUES(16,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92845000000 WHERE rowid=1');
INSERT INTO undolog VALUES(17,'DELETE FROM credits WHERE rowid=3');
INSERT INTO undolog VALUES(18,'UPDATE order_matches SET id=''17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b_1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf'',tx0_index=3,tx0_hash=''17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b'',tx0_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx1_index=4,tx1_hash=''1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf'',tx1_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',forward_asset=''BTC'',forward_quantity=50000000,backward_asset=''XCP'',backward_quantity=100000000,tx0_block_index=310002,tx1_block_index=310003,block_index=310003,tx0_expiration=10,tx1_expiration=10,match_expire_index=310023,fee_paid=857142,status=''pending'' WHERE rowid=1');
INSERT INTO undolog VALUES(19,'DELETE FROM btcpays WHERE rowid=5');
INSERT INTO undolog VALUES(20,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92945000000 WHERE rowid=1');
INSERT INTO undolog VALUES(21,'DELETE FROM debits WHERE rowid=3');
INSERT INTO undolog VALUES(22,'DELETE FROM assets WHERE rowid=3');
INSERT INTO undolog VALUES(23,'DELETE FROM issuances WHERE rowid=6');
INSERT INTO undolog VALUES(24,'DELETE FROM balances WHERE rowid=3');
INSERT INTO undolog VALUES(25,'DELETE FROM credits WHERE rowid=4');
INSERT INTO undolog VALUES(26,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92895000000 WHERE rowid=1');
INSERT INTO undolog VALUES(27,'DELETE FROM debits WHERE rowid=4');
INSERT INTO undolog VALUES(28,'DELETE FROM assets WHERE rowid=4');
INSERT INTO undolog VALUES(29,'DELETE FROM issuances WHERE rowid=7');
INSERT INTO undolog VALUES(30,'DELETE FROM balances WHERE rowid=4');
INSERT INTO undolog VALUES(31,'DELETE FROM credits WHERE rowid=5');
INSERT INTO undolog VALUES(32,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''BBBB'',quantity=1000000000 WHERE rowid=3');
INSERT INTO undolog VALUES(33,'DELETE FROM debits WHERE rowid=5');
INSERT INTO undolog VALUES(34,'DELETE FROM balances WHERE rowid=5');
INSERT INTO undolog VALUES(35,'DELETE FROM credits WHERE rowid=6');
INSERT INTO undolog VALUES(36,'DELETE FROM sends WHERE rowid=8');
INSERT INTO undolog VALUES(37,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''BBBC'',quantity=100000 WHERE rowid=4');
INSERT INTO undolog VALUES(38,'DELETE FROM debits WHERE rowid=6');
INSERT INTO undolog VALUES(39,'DELETE FROM balances WHERE rowid=6');
INSERT INTO undolog VALUES(40,'DELETE FROM credits WHERE rowid=7');
INSERT INTO undolog VALUES(41,'DELETE FROM sends WHERE rowid=9');
INSERT INTO undolog VALUES(42,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92845000000 WHERE rowid=1');
INSERT INTO undolog VALUES(43,'DELETE FROM debits WHERE rowid=7');
INSERT INTO undolog VALUES(44,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92844999976 WHERE rowid=1');
INSERT INTO undolog VALUES(45,'DELETE FROM debits WHERE rowid=8');
INSERT INTO undolog VALUES(46,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3'',asset=''XCP'',quantity=50000000 WHERE rowid=2');
INSERT INTO undolog VALUES(47,'DELETE FROM credits WHERE rowid=8');
INSERT INTO undolog VALUES(48,'DELETE FROM dividends WHERE rowid=10');
INSERT INTO undolog VALUES(49,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92844979976 WHERE rowid=1');
INSERT INTO undolog VALUES(50,'DELETE FROM debits WHERE rowid=9');
INSERT INTO undolog VALUES(51,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92844559176 WHERE rowid=1');
INSERT INTO undolog VALUES(52,'DELETE FROM debits WHERE rowid=10');
INSERT INTO undolog VALUES(53,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3'',asset=''XCP'',quantity=50000024 WHERE rowid=2');
INSERT INTO undolog VALUES(54,'DELETE FROM credits WHERE rowid=9');
INSERT INTO undolog VALUES(55,'DELETE FROM dividends WHERE rowid=11');
INSERT INTO undolog VALUES(56,'DELETE FROM broadcasts WHERE rowid=12');
INSERT INTO undolog VALUES(57,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92844539176 WHERE rowid=1');
INSERT INTO undolog VALUES(58,'DELETE FROM debits WHERE rowid=11');
INSERT INTO undolog VALUES(59,'DELETE FROM bets WHERE rowid=1');
INSERT INTO undolog VALUES(60,'UPDATE orders SET tx_index=3,tx_hash=''17500c776ecb9d1aad1cfa0407e2248c890537934132bb6ec52970c3530a157b'',block_index=310002,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''BTC'',give_quantity=50000000,give_remaining=0,get_asset=''XCP'',get_quantity=100000000,get_remaining=0,expiration=10,expire_index=310012,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=142858,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(61,'DELETE FROM order_expirations WHERE rowid=3');
INSERT INTO undolog VALUES(62,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92794539176 WHERE rowid=1');
INSERT INTO undolog VALUES(63,'DELETE FROM debits WHERE rowid=12');
INSERT INTO undolog VALUES(64,'DELETE FROM bets WHERE rowid=2');
INSERT INTO undolog VALUES(65,'UPDATE bets SET tx_index=13,tx_hash=''936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f'',block_index=310012,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=0,deadline=1388000100,wager_quantity=50000000,wager_remaining=50000000,counterwager_quantity=25000000,counterwager_remaining=25000000,target_value=0.0,leverage=15120,expiration=10,expire_index=310022,fee_fraction_int=5000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(66,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92769539176 WHERE rowid=1');
INSERT INTO undolog VALUES(67,'DELETE FROM credits WHERE rowid=10');
INSERT INTO undolog VALUES(68,'UPDATE bets SET tx_index=14,tx_hash=''f964ef723387946ba8ea78589e5772370ad0909a985cd83a281d26f192fe6bbb'',block_index=310013,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=1,deadline=1388000100,wager_quantity=25000000,wager_remaining=25000000,counterwager_quantity=41500000,counterwager_remaining=41500000,target_value=0.0,leverage=15120,expiration=10,expire_index=310023,fee_fraction_int=5000000,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(69,'DELETE FROM bet_matches WHERE rowid=1');
INSERT INTO undolog VALUES(70,'UPDATE orders SET tx_index=4,tx_hash=''1f96219c284999758bb60ee7169a3c13ec95ff5766228444d697ded138c26ccf'',block_index=310003,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''XCP'',give_quantity=105000000,give_remaining=5000000,get_asset=''BTC'',get_quantity=50000000,get_remaining=0,expiration=10,expire_index=310013,fee_required=900000,fee_required_remaining=42858,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(71,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92773789176 WHERE rowid=1');
INSERT INTO undolog VALUES(72,'DELETE FROM credits WHERE rowid=11');
INSERT INTO undolog VALUES(73,'DELETE FROM order_expirations WHERE rowid=4');
INSERT INTO undolog VALUES(74,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92778789176 WHERE rowid=1');
INSERT INTO undolog VALUES(75,'DELETE FROM debits WHERE rowid=13');
INSERT INTO undolog VALUES(76,'DELETE FROM bets WHERE rowid=3');
INSERT INTO undolog VALUES(77,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92628789176 WHERE rowid=1');
INSERT INTO undolog VALUES(78,'DELETE FROM debits WHERE rowid=14');
INSERT INTO undolog VALUES(79,'DELETE FROM bets WHERE rowid=4');
INSERT INTO undolog VALUES(80,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(81,'DELETE FROM credits WHERE rowid=12');
INSERT INTO undolog VALUES(82,'UPDATE bets SET tx_index=15,tx_hash=''4a4eb3b3f79303bc6b2f37f049c145808164176f996edaddba16320b7eb0bf0d'',block_index=310014,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=0,deadline=1388000100,wager_quantity=150000000,wager_remaining=150000000,counterwager_quantity=350000000,counterwager_remaining=350000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310024,fee_fraction_int=5000000,status=''open'' WHERE rowid=3');
INSERT INTO undolog VALUES(83,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(84,'DELETE FROM credits WHERE rowid=13');
INSERT INTO undolog VALUES(85,'UPDATE bets SET tx_index=16,tx_hash=''6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300'',block_index=310015,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=1,deadline=1388000100,wager_quantity=350000000,wager_remaining=350000000,counterwager_quantity=150000000,counterwager_remaining=150000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310025,fee_fraction_int=5000000,status=''open'' WHERE rowid=4');
INSERT INTO undolog VALUES(86,'DELETE FROM bet_matches WHERE rowid=2');
INSERT INTO undolog VALUES(87,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(88,'DELETE FROM debits WHERE rowid=15');
INSERT INTO undolog VALUES(89,'DELETE FROM bets WHERE rowid=5');
INSERT INTO undolog VALUES(90,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=91528789176 WHERE rowid=1');
INSERT INTO undolog VALUES(91,'DELETE FROM debits WHERE rowid=16');
INSERT INTO undolog VALUES(92,'DELETE FROM bets WHERE rowid=6');
INSERT INTO undolog VALUES(93,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(94,'DELETE FROM credits WHERE rowid=14');
INSERT INTO undolog VALUES(95,'UPDATE bets SET tx_index=17,tx_hash=''cee3a40d67546871412e28c6210d70713b46597718ab72d4a62944555e51a2a8'',block_index=310016,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=2,deadline=1388000200,wager_quantity=750000000,wager_remaining=750000000,counterwager_quantity=650000000,counterwager_remaining=650000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310026,fee_fraction_int=5000000,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(96,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(97,'DELETE FROM credits WHERE rowid=15');
INSERT INTO undolog VALUES(98,'UPDATE bets SET tx_index=18,tx_hash=''f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0'',block_index=310017,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=3,deadline=1388000200,wager_quantity=650000000,wager_remaining=650000000,counterwager_quantity=750000000,counterwager_remaining=750000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310027,fee_fraction_int=5000000,status=''open'' WHERE rowid=6');
INSERT INTO undolog VALUES(99,'DELETE FROM bet_matches WHERE rowid=3');
INSERT INTO undolog VALUES(100,'DELETE FROM broadcasts WHERE rowid=19');
INSERT INTO undolog VALUES(101,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(102,'DELETE FROM credits WHERE rowid=16');
INSERT INTO undolog VALUES(103,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90937926676 WHERE rowid=1');
INSERT INTO undolog VALUES(104,'DELETE FROM credits WHERE rowid=17');
INSERT INTO undolog VALUES(105,'DELETE FROM bet_match_resolutions WHERE rowid=1');
INSERT INTO undolog VALUES(106,'UPDATE bet_matches SET id=''936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f_f964ef723387946ba8ea78589e5772370ad0909a985cd83a281d26f192fe6bbb'',tx0_index=13,tx0_hash=''936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f'',tx0_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx1_index=14,tx1_hash=''f964ef723387946ba8ea78589e5772370ad0909a985cd83a281d26f192fe6bbb'',tx1_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=15120,forward_quantity=41500000,backward_quantity=20750000,tx0_block_index=310012,tx1_block_index=310013,block_index=310013,tx0_expiration=10,tx1_expiration=10,match_expire_index=310022,fee_fraction_int=5000000,status=''pending'' WHERE rowid=1');
INSERT INTO undolog VALUES(107,'DELETE FROM broadcasts WHERE rowid=20');
INSERT INTO undolog VALUES(108,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90941039176 WHERE rowid=1');
INSERT INTO undolog VALUES(109,'DELETE FROM credits WHERE rowid=18');
INSERT INTO undolog VALUES(110,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=91100339176 WHERE rowid=1');
INSERT INTO undolog VALUES(111,'DELETE FROM credits WHERE rowid=19');
INSERT INTO undolog VALUES(112,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=91416039176 WHERE rowid=1');
INSERT INTO undolog VALUES(113,'DELETE FROM credits WHERE rowid=20');
INSERT INTO undolog VALUES(114,'DELETE FROM bet_match_resolutions WHERE rowid=2');
INSERT INTO undolog VALUES(115,'UPDATE bet_matches SET id=''4a4eb3b3f79303bc6b2f37f049c145808164176f996edaddba16320b7eb0bf0d_6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300'',tx0_index=15,tx0_hash=''4a4eb3b3f79303bc6b2f37f049c145808164176f996edaddba16320b7eb0bf0d'',tx0_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx1_index=16,tx1_hash=''6d2c540d181cf4d08834fbcd358ae3f2a42a8ddbdd5a0e6d06c30d44a94cd300'',tx1_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=5040,forward_quantity=150000000,backward_quantity=350000000,tx0_block_index=310014,tx1_block_index=310015,block_index=310015,tx0_expiration=10,tx1_expiration=10,match_expire_index=310024,fee_fraction_int=5000000,status=''pending'' WHERE rowid=2');
INSERT INTO undolog VALUES(116,'DELETE FROM broadcasts WHERE rowid=21');
INSERT INTO undolog VALUES(117,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=91441039176 WHERE rowid=1');
INSERT INTO undolog VALUES(118,'DELETE FROM credits WHERE rowid=21');
INSERT INTO undolog VALUES(119,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92771039176 WHERE rowid=1');
INSERT INTO undolog VALUES(120,'DELETE FROM credits WHERE rowid=22');
INSERT INTO undolog VALUES(121,'DELETE FROM bet_match_resolutions WHERE rowid=3');
INSERT INTO undolog VALUES(122,'UPDATE bet_matches SET id=''cee3a40d67546871412e28c6210d70713b46597718ab72d4a62944555e51a2a8_f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0'',tx0_index=17,tx0_hash=''cee3a40d67546871412e28c6210d70713b46597718ab72d4a62944555e51a2a8'',tx0_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx1_index=18,tx1_hash=''f1b00ac05403ef472123c39e7eb6257ed900b0855e899c8cd19b29b54d91b5f0'',tx1_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx0_bet_type=2,tx1_bet_type=3,feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',initial_value=100,deadline=1388000200,target_value=1.0,leverage=5040,forward_quantity=750000000,backward_quantity=650000000,tx0_block_index=310016,tx1_block_index=310017,block_index=310017,tx0_expiration=10,tx1_expiration=10,match_expire_index=310026,fee_fraction_int=5000000,status=''pending'' WHERE rowid=3');
INSERT INTO undolog VALUES(123,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''BBBB'',quantity=996000000 WHERE rowid=3');
INSERT INTO undolog VALUES(124,'DELETE FROM debits WHERE rowid=17');
INSERT INTO undolog VALUES(125,'DELETE FROM orders WHERE rowid=3');
INSERT INTO undolog VALUES(126,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92841039176 WHERE rowid=1');
INSERT INTO undolog VALUES(127,'DELETE FROM credits WHERE rowid=23');
INSERT INTO undolog VALUES(128,'DELETE FROM burns WHERE rowid=23');
INSERT INTO undolog VALUES(129,'UPDATE bets SET tx_index=13,tx_hash=''936ba31cc8a62c7f240382903cda44d738e485e5f59a1190a333ab082bb90b5f'',block_index=310012,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=0,deadline=1388000100,wager_quantity=50000000,wager_remaining=8500000,counterwager_quantity=25000000,counterwager_remaining=4250000,target_value=0.0,leverage=15120,expiration=10,expire_index=310022,fee_fraction_int=5000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(130,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=149840926438 WHERE rowid=1');
INSERT INTO undolog VALUES(131,'DELETE FROM credits WHERE rowid=24');
INSERT INTO undolog VALUES(132,'DELETE FROM bet_expirations WHERE rowid=13');
INSERT INTO undolog VALUES(133,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''BBBC'',quantity=99474 WHERE rowid=4');
INSERT INTO undolog VALUES(134,'DELETE FROM debits WHERE rowid=18');
INSERT INTO undolog VALUES(135,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3'',asset=''BBBC'',quantity=526 WHERE rowid=6');
INSERT INTO undolog VALUES(136,'DELETE FROM credits WHERE rowid=25');
INSERT INTO undolog VALUES(137,'DELETE FROM sends WHERE rowid=24');
INSERT INTO undolog VALUES(138,'UPDATE orders SET tx_index=22,tx_hash=''e9473a9fa150886f864f1ae0375a131f16defcc34cef67375eb87787bc8ae0a0'',block_index=310021,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''BBBB'',give_quantity=50000000,give_remaining=50000000,get_asset=''XCP'',get_quantity=50000000,get_remaining=50000000,expiration=10,expire_index=310031,fee_required=0,fee_required_remaining=0,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=3');
INSERT INTO undolog VALUES(139,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''BBBB'',quantity=946000000 WHERE rowid=3');
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
