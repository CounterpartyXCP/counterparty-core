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
INSERT INTO bet_expirations VALUES(13,'c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',310023);
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
INSERT INTO bet_match_resolutions VALUES('c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662_b96f2d38e2dfd09addcd61a9ddb18fa7faa72b526a1ec0a4dad8cfbc77d0a839',1,310018,'0',0,59137500,NULL,NULL,3112500);
INSERT INTO bet_match_resolutions VALUES('801527b9dba145637cb07e12906651f53ffd55f5501d24535bc7a43fb2100c29_e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0',1,310019,'1',159300000,315700000,NULL,NULL,25000000);
INSERT INTO bet_match_resolutions VALUES('c551d52dd756f4fce025dda64bc12ef845746c40c2db544f37a9bc81c1d2bd83_4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685',5,310020,NULL,NULL,NULL,'NotEqual',1330000000,70000000);
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
INSERT INTO bet_matches VALUES('c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662_b96f2d38e2dfd09addcd61a9ddb18fa7faa72b526a1ec0a4dad8cfbc77d0a839',13,'c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',14,'b96f2d38e2dfd09addcd61a9ddb18fa7faa72b526a1ec0a4dad8cfbc77d0a839','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,1,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',100,1388000100,0.0,15120,41500000,20750000,310012,310013,310013,10,10,310022,5000000,'settled: liquidated for bear');
INSERT INTO bet_matches VALUES('801527b9dba145637cb07e12906651f53ffd55f5501d24535bc7a43fb2100c29_e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0',15,'801527b9dba145637cb07e12906651f53ffd55f5501d24535bc7a43fb2100c29','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',16,'e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,1,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',100,1388000100,0.0,5040,150000000,350000000,310014,310015,310015,10,10,310024,5000000,'settled');
INSERT INTO bet_matches VALUES('c551d52dd756f4fce025dda64bc12ef845746c40c2db544f37a9bc81c1d2bd83_4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685',17,'c551d52dd756f4fce025dda64bc12ef845746c40c2db544f37a9bc81c1d2bd83','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',18,'4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',2,3,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',100,1388000200,1.0,5040,750000000,650000000,310016,310017,310017,10,10,310026,5000000,'settled: for notequal');
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
INSERT INTO bets VALUES(13,'c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662',310012,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,1388000100,50000000,8500000,25000000,4250000,0.0,15120,10,310022,5000000,'expired');
INSERT INTO bets VALUES(14,'b96f2d38e2dfd09addcd61a9ddb18fa7faa72b526a1ec0a4dad8cfbc77d0a839',310013,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1,1388000100,25000000,4250000,41500000,0,0.0,15120,10,310023,5000000,'filled');
INSERT INTO bets VALUES(15,'801527b9dba145637cb07e12906651f53ffd55f5501d24535bc7a43fb2100c29',310014,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,1388000100,150000000,0,350000000,0,0.0,5040,10,310024,5000000,'filled');
INSERT INTO bets VALUES(16,'e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0',310015,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1,1388000100,350000000,0,150000000,0,0.0,5040,10,310025,5000000,'filled');
INSERT INTO bets VALUES(17,'c551d52dd756f4fce025dda64bc12ef845746c40c2db544f37a9bc81c1d2bd83',310016,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',2,1388000200,750000000,0,650000000,0,1.0,5040,10,310026,5000000,'filled');
INSERT INTO bets VALUES(18,'4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685',310017,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',3,1388000200,650000000,0,750000000,0,1.0,5040,10,310027,5000000,'filled');
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
INSERT INTO blocks VALUES(310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,NULL,NULL,'09fa44ed277cd9e448baf3d4a2accc520d57c77fed0d97379ba9bb804e3dda71','7d9cd23062d78e9eb1a892f69b154410935e9675ede8e05fe9c1269cd3c54b12','2942e4a213def5730ad4f05847480fb4c988afe9905a8e923d73d1f7b93b8b8e');
INSERT INTO blocks VALUES(310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,NULL,NULL,'b2237a0b0b29b2198355f47d38cb995e013c0e074c29dcbf1b99ed4c0f459c8d','955bb12ee95c328b789112ccb2c765ed2d5396243af340f1d21bac682bd5152b','f7409f091134744b5c6607e98a051578417d414b2b1ce3b6e65bd2dfcd4d2b5e');
INSERT INTO blocks VALUES(310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,NULL,NULL,'a3c393a285361d2981551f0a903d45847e7a0142779692d384bc77bac420db18','d8bb96ce066c9f3ab1e3180addeb44ad4c03fbbdc0fc13c7ba48173fcd61e3ee','4da901cfec76f803d41654cc8396b2e6f11fd17b80c2c47651de45d83843bee9');
INSERT INTO blocks VALUES(310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,NULL,NULL,'f96ba90a471ab5524a574cc4ff72a228a8dc7019824482a664569dcb41c126c7','56de16a16dec905993be87e59d6927f0e6a9e4be87807680822d05246af3ebce','80762d98feeb351dbfedccc65ee9c102880e77edce579123cd3d8bb80dc10e8f');
INSERT INTO blocks VALUES(310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,NULL,NULL,'943a23e317f71981b24d636cae98f495b2bb00c949b1603a778eb7500894c844','34ba97623580233bd7bf79b5e666a30e93748d338a5b06a3445d5555fe5dc64f','340d12f372095a7bf50ec2b9157b1f5d88232a779bea5452fa368eb7025492d0');
INSERT INTO blocks VALUES(310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,NULL,NULL,'0c5f3dd2d439a571eec03583442fb051bedf5bc0b0ede92012922b27847af2a1','681bfcaa9e9ee89062a24adef9b382fb8f29d09264d110e9b65be4d90a8a556d','0fbbf716554ea29b632fbd6a4e7dc3c33cddc03cf38f2a42f011cc6e229a9799');
INSERT INTO blocks VALUES(310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,NULL,NULL,'377fe894d79d60b011958ed747908b6009c5e0261fa177caefc664cb8db4c74b','97a6303294a5d9185c14b54b3008e6c34e3f9512c138e7ec715d7a6694582a30','e0164654c8167fb11da6226a5983ed9ce5f19d2ae131d3913021cc66d36a1668');
INSERT INTO blocks VALUES(310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,NULL,NULL,'4be55eb54e78e829306dfa31248b3073d311f49da420d9844f9aedabfbd296e3','06fb9d0e2cff567898f80ca35f0bc4abb494cc434aba89706f692de5e825d8b6','1d4bbcf0caf5bd5322382ecfddd223a9f64b2531d1ffcfab5bf8eb4eec4bcf61');
INSERT INTO blocks VALUES(310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,NULL,NULL,'1248da848479b90f9dada38eaa02b9fe1226859e6ed1e3c4a121172786178dea','ccb0bed40631d947fb98a3e70b913716ac5a568628b292bf69a9a2567593770d','ff8f6f3d9d596643d6ba3337581b9602811034b73d9a0ea10b6c3d3272cf87b2');
INSERT INTO blocks VALUES(310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,NULL,NULL,'1e1b07f218127eccdfab98a4bc127ce185cda15314e72328dfe10eb8f2f18726','e71d8e48020f2e9528edbb5c6eed9d1f2db638926cbd140d9d40105d7dded55b','ed4cffe78e9a0ef6b4c00510272ca34e595a9587672f4922227c9f876262989f');
INSERT INTO blocks VALUES(310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,NULL,NULL,'03be7c3d8dc521277625164e3e828be106672cba205129c014ce7771a3b8730f','c783f48df416cf85a9e52be8425146a7c85976d17818da0161f3dfccd15a203f','fef2b3ceb01af75d35771c7b95c1daa8048970ff42537ccd6ceb86c4ea8cb432');
INSERT INTO blocks VALUES(310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,NULL,NULL,'db6d49ef7cfb461f9431b2e712f694f0747012ae28f3684e0d41476f77fab667','744adec451aff59f47bedc41a39e6dabdd614a949344f26358dace334d86db81','91d906d0a31168adee534460448af217a8b28575ce0ab5a7535248b2f22d9036');
INSERT INTO blocks VALUES(310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,NULL,NULL,'ac399d193def488d3457876edef42dd651b30c976025c3d6f810e4d37c88c822','7b10d4ca47c0a692abcc3257d0382d635e36a00caa74ea9bd772a84c0aa8e1e1','126b013e78929b9436f592d17ecabb1d9d7d8ad331ed25208483d879d8ce899a');
INSERT INTO blocks VALUES(310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,NULL,NULL,'f6fd6f6280b1c580abe8e31de28bfa0f269d453068946733cad69d29f6874936','23f7e4fd5727bdd4f2440733b07b45105e7b6b89a681c3fc3a19df4dce1f696d','4ede0c519949929d004749ffd29b4b6c8e64edc3e82819e3a4c60c3a52c32860');
INSERT INTO blocks VALUES(310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,NULL,NULL,'0c52d56c6f7c25da7b757aba30e890e9eff402155b5497a5420e13e69b7cb54b','fa145f81638fd9cd8ee68a876573835445a374ab9b234b45205eb2c94d2d8552','b2642685c4300d8ba8479551474cb14f68caaa7565abaa78648a4c3d08b8c430');
INSERT INTO blocks VALUES(310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,NULL,NULL,'03cd020f708d5f082f5b63e3c1f58e5f25d564a60699ae0f23471115d9e37d5e','b4fffeac5c29891fa925af3f0d24fd53c58adac801cb166c64622d686075941f','baf6027c2dc24272e70a0d24d4a70ab075b15e5ad05fe3b01db6bd376bd04b54');
INSERT INTO blocks VALUES(310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,NULL,NULL,'d95cf7b2af3f578fc64450d484323075e81999a868918d3dbf89160269d68980','ca3ad15a2bf676788266c6c51a85a2197a75f4f202a5caf4fc35657345435874','2c62dc5895a5bd4bc737504866e5df82f8cac9a49d891a196f3e1b7d66ca3d7d');
INSERT INTO blocks VALUES(310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,NULL,NULL,'725783dab777f54b11be66fdf47280852fd6b4d8a9b9f2fbba9e92056538ce73','0834dfffcdd543b36bfd630736cc352c929a733f86056b0dbf00260d25616d9c','48aefe357492852824cba88c6d3fca8f418fb098cac466881c9f615e96eb2ef6');
INSERT INTO blocks VALUES(310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,NULL,NULL,'05ad248fa836b50ce72a2f61c7465a455cc48ac92f2c0ff9bb9f94e69081d1e7','26e198539f2451da1c6b323d9befcb644c7ca4658937a542c0a22c440a3d1def','b1b7174f071fec189c65035ad1e0a4f3754135de85809bf983f07f9f9111f3cf');
INSERT INTO blocks VALUES(310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,NULL,NULL,'0ab8707bce7b77beecc32ad6124482cb561776ed245ce6dce08f5318e2cf396f','99929dd656a297edc829124da4cb4e4dc62a2b1fbc79f1449edcd537d5d04187','10742d29c2a7522dad0c0489502b69d21c14775f253ae1913eeac1de9f8cdd2e');
INSERT INTO blocks VALUES(310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,NULL,NULL,'198edc4bf109549538a2f8f96714536a99a1568fe16fe4254881520474adc68d','c9512b1f77d54cee8818987c296e47b0ea276f8720e5b599b5734ca9e0cacbfe','4e8d816516b10c67f8bf47d6c96fcbcbfd8f1331f1748384be55dfc36cc59de0');
INSERT INTO blocks VALUES(310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,NULL,NULL,'52482033c5c11ad24257707137b090606305497618e29050b2fdd3e13bc822ce','d189716a4c57504c639ed9ff920891a481140648d15248d90566a70b21708908','b0fb32c856e14ddf0ad1051f4b9ca1603155b8e733f75b255be715a5c74c4660');
INSERT INTO blocks VALUES(310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,NULL,NULL,'85d639cc8147885470da26d3c0470dba0eb8b6870d5941b12bcc4afb8fcd9af1','8e86f485f5235dbc98d4c055390b454ad0da088cc56c300a9b83b090b6b83017','f11643edc405224e0c93e84b33f491aa2a1d31f2c42e4b8ab9a9289cbdba8aaf');
INSERT INTO blocks VALUES(310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,NULL,NULL,'eb62ce47d68491a84b9a29b92db2742021881f0274072f1bc39dfef08cd7a590','e2e6761135e3d456b9609c7b7bbda7430fa45c87cf74fe187c3ce51b16144b50','ae07a7b1df6ae5d261045987e8d5e6b4a779800ef610ffcf8fdd4bfcdcf3287d');
INSERT INTO blocks VALUES(310024,'b03042b4e18a222b4c8d1e9e1970d93e6e2a2d41686d227ff8ecf0a839223dc5',310024000,NULL,NULL,'45e73afbc34855b5cbd342a6fb77545e01f3ff4601a04c6dd25dff665aeff484','e4cddeb1666051841f2da8a55202042f13d6d201ecc878febd92de83ac8ff866','3123a844a906ee97def05fb7d74b275ba54a2f5923a10051b63111891afef9f3');
INSERT INTO blocks VALUES(310025,'a872e560766832cc3b4f7f222228cb6db882ce3c54f6459f62c71d5cd6e90666',310025000,NULL,NULL,'714702b25559325c7bacffdf28e0af30c47bf48e6b4fda053c21ea31c7604128','ff14e6b2899270e29e2e6964a20da2b388688d8d47e28e6826900dee0d242c98','751f8de4026158e28daf0ecfa6bfdf051f626cd4a59bbee934df33080cfd6d2e');
INSERT INTO blocks VALUES(310026,'6c96350f6f2f05810f19a689de235eff975338587194a36a70dfd0fcd490941a',310026000,NULL,NULL,'b305741a1e277ba0ce8436b914784ea0156616ac308282a7f29dbca62a54cc82','c59e72ce16bdfa23aac2f507e12a8d10059694abb04b09df2b55ab12b39802f0','aa87de79cfc45db251f0a49ed3b569cd43798410352f25a99d53136f109ecb56');
INSERT INTO blocks VALUES(310027,'d7acfac66df393c4482a14c189742c0571b89442eb7f817b34415a560445699e',310027000,NULL,NULL,'1f833f7396917e02b4b65b0a05d19754b6a53b030b659514d0c21cad062d45f9','d146b7ae81386af0900a3315c2d6c7ca700b941fb93cc59838c62a12e2138bfe','6eb78f8638f1df91f713d65583c6b227382d21b886250f0bad9d95d2daa0eeb1');
INSERT INTO blocks VALUES(310028,'02409fcf8fa06dafcb7f11e38593181d9c42cc9d5e2ddc304d098f990bd9530b',310028000,NULL,NULL,'47b38906beda7ad735a86b9fd63669b0357b7ae0a0c1a54c9827bc8b90185626','e75c42d585da7426600e4427c70db85c0450e34972b3ab02f427348326c86a8b','27667bb169eae1b6cce65bce8b0721ca0bc42a20ea8b0bf53efdaede9e0115b3');
INSERT INTO blocks VALUES(310029,'3c739fa8b40c118d5547ea356ee8d10ee2898871907643ec02e5db9d00f03cc6',310029000,NULL,NULL,'e69f6c9b649ac04920be70f9b076f7909bcebd8312afa715be3d8922794a72e7','ff42207b3c49e4a5c6ff8bbff03353bc8ab4dd2098b9e74405ed2cf019cbb0b2','cbe76901ff225c9831c6dc68c3c2a0963fe03fd1bf1905f09c05dba5ff7628c0');
INSERT INTO blocks VALUES(310030,'d5071cddedf89765ee0fd58f209c1c7d669ba8ea66200a57587da8b189b9e4f5',310030000,NULL,NULL,'c51828b04433b000787c92eaa7e5abd5cc0bc31c619cb8479aff675af6e00c55','5e59d2ed71e1ec87709e3b78992015678b9ec5b2ef7537611f0ed669256badef','1ac863187b48dcf797f80b5c8a00a7300d8e2bbd9536e5b56d2a98015b77c5c6');
INSERT INTO blocks VALUES(310031,'0b02b10f41380fff27c543ea8891ecb845bf7a003ac5c87e15932aff3bfcf689',310031000,NULL,NULL,'26d91568af76b5ad4b357693ecb0b9341aabbf5de5d5c83f9998dc2f95d76e5e','375429c2017d60fabaf4a7a05cb22e46ad9a474f43c9a649174d9f3cbf9db761','3745177c77a2b0c7f832dbb549d1137b444ec9b827ac1d27f395c2dd1a1fc6ec');
INSERT INTO blocks VALUES(310032,'66346be81e6ba04544f2ae643b76c2b7b1383f038fc2636e02e49dc7ec144074',310032000,NULL,NULL,'21f8da71c386ec1e5e31a35c1190b895f2df52529ea028d5fba25e0d57616952','f8d52343adf8d50adb06af1f9bf6762576d8b08c4cf160706cb2688ed22c9869','5b73552a13ad313718eda4c16592a27ccc22d31ebe2e3fd4076f3c7db6c91986');
INSERT INTO blocks VALUES(310033,'999c65df9661f73e8c01f1da1afda09ac16788b72834f0ff5ea3d1464afb4707',310033000,NULL,NULL,'1c844a38fc28e83406c8019615d0c24a1ea84e6ffe4da392d29f353ca676001b','0caf0ed5f95befe7967f260c97f8df3fe8086922a53dab339e5a25280799c20f','45a558cf3bc5c49c475362241b9b36a27e63665495a7d7acc927503c78eb14c0');
INSERT INTO blocks VALUES(310034,'f552edd2e0a648230f3668e72ddf0ddfb1e8ac0f4c190f91b89c1a8c2e357208',310034000,NULL,NULL,'0533bc0d3bc008b5d65932c569e9f85e3217ea9efbb8937935be93b7a01ec2a8','c9e8cf21b372a9ff53e0619899d03a9ca73f0a8756a4a2cea49c1968a3fd780d','924d7e269d6e3f2ff680d66ac4d0a5a648f0679245f66078c58bb08a986596ec');
INSERT INTO blocks VALUES(310035,'a13cbb016f3044207a46967a4ba1c87dab411f78c55c1179f2336653c2726ae2',310035000,NULL,NULL,'b5f0b7406fe3b6dbcbb5c3b28fb8fb119e237f07532f500b422058ba898e5b22','caca0dc3a83f2f4201f6aa8ebb8102876f3c877c782f4fc93c16a94013c1aa11','52789c58a17cd66bc335d24a95611c6b700e7cb44de90b8cd2e6e199cab48d5e');
INSERT INTO blocks VALUES(310036,'158648a98f1e1bd1875584ce8449eb15a4e91a99a923bbb24c4210135cef0c76',310036000,NULL,NULL,'7519ac8cdf4c13b25929d913e3858855aca68bcf3fe6d3636e7371894af27f04','d8e73f35827507296fd1033feed68383867f48ebe958f4d4bf71e64cc99ae7e0','965d18c8f02a7356e441ef814353880646270729db1370d85e6d10772ed4384b');
INSERT INTO blocks VALUES(310037,'563acfd6d991ce256d5655de2e9429975c8dceeb221e76d5ec6e9e24a2c27c07',310037000,NULL,NULL,'f417da67da0c23d4bc44bbb864de5b94057916e28502641ba70764f44165a1fa','222e0352447762974f053447fb27d1c4d1023540bc12ad58659691907330e2e3','5da42a84270c2c8c7124a40bfad6f9c8073ad85cb6f0657ccdd4ca0f3998d784');
INSERT INTO blocks VALUES(310038,'b44b4cad12431c32df27940e18d51f63897c7472b70950d18454edfd640490b2',310038000,NULL,NULL,'098eb6f2b0a1c584d969167f50bb55383ab71593ed1f0ca61d83c4513a209107','5fffb2bb03fe5a472f6d8b3b14dbe97912d3888d9e2ac94672864763b3ecd831','4c04c8616aa4399071327f04ddab2c23273cedc9d1b3b6b5da685db7727bbc8b');
INSERT INTO blocks VALUES(310039,'5fa1ae9c5e8a599247458987b006ad3a57f686df1f7cc240bf119e911b56c347',310039000,NULL,NULL,'a4aa60a1320e47c975628f6650d8fdc44b6a729d26a3178031e32fcb48b59491','6a8a5111df6227a3c330738d5af386be33ed41cc908e8e7878a46fdfb7d46f4f','e8985b6131e1b30e8826002686bfdaac22e1b71661ef5d44e945128ef5dd405e');
INSERT INTO blocks VALUES(310040,'7200ded406675453eadddfbb2d14c2a4526c7dc2b5de14bd48b29243df5e1aa3',310040000,NULL,NULL,'cc5b2af6948531b635b18a4b6698efa318190762c8e4419aa9ca3634e7ed5d1e','c237ea577108b81271e6f2dca11fb0ea32dada162dc1671d4398501b45ddaf84','dfc94123c7454b24f0dd7c8d77597e8987317811999e9547d9d076bfe3824161');
INSERT INTO blocks VALUES(310041,'5db592ff9ba5fac1e030cf22d6c13b70d330ba397f415340086ee7357143b359',310041000,NULL,NULL,'7ad02b4853bde78025942e9f58c212a76c1828337610347e516d4a359af804b5','bd88f5cf0308d3ebd6d2f63f96f3214065c141138a2139e11cb4726128f92c50','48819f01337b451a9273c66cffeedec270637cc62829cdd2e75515ca1da10ecd');
INSERT INTO blocks VALUES(310042,'826fd4701ef2824e9559b069517cd3cb990aff6a4690830f78fc845ab77fa3e4',310042000,NULL,NULL,'64a91735950113c13603e49ca549fae9b30092a9fc02d53a32a20eaef64ab6ce','a65e928f55bcb4e4f38a049b64cf9bc7660c4a67b68beed33d9a4ee95a1a2594','4db7d06954b0f517792f261275a9ade7d39add0d50447ef4a47d69fb6195d766');
INSERT INTO blocks VALUES(310043,'2254a12ada208f1dd57bc17547ecaf3c44720323c47bc7d4b1262477cb7f3c51',310043000,NULL,NULL,'68107847c7a9dd19612d8b47c1a39cdc446c752f2c05ea8fcd961a42f835d155','05059334de59abe65d942dd20cd179ca591fbcc966c9b0beebcd854b4ab3819d','bdb454a407e1101e75ef6fee7da62fab426b16eeec47b957c9193ab4a03b21c4');
INSERT INTO blocks VALUES(310044,'3346d24118d8af0b3c6bcc42f8b85792e7a2e7036ebf6e4c25f4f6723c78e46b',310044000,NULL,NULL,'64d4d51adb6994360b3dbf04663c4f067ba223e62912fe1c5a96a190225bb54c','ebff685fbd36bdd51b4c3b3d7d62ea6793be83f243009af0a73aeaf70e18d761','03e267dda3d81c3b0016ee931c6bd6c1ea2d2b996584b0d172e1d1509ed2c390');
INSERT INTO blocks VALUES(310045,'7bba0ab243839e91ad1a45a762bf074011f8a9883074d68203c6d1b46fffde98',310045000,NULL,NULL,'3ba2d7685f63962f576e9fa94e4d6709ace95249a3064804c3822078c982d11d','73a8d3c72366d393782c146c1a34a0c0fcdb060dce3c81dfcabe82d719476afa','c4148885a77d9bbc5764438f3283cf61bcafca253e765529a1441522925db496');
INSERT INTO blocks VALUES(310046,'47db6788c38f2d6d712764979e41346b55e78cbb4969e0ef5c4336faf18993a6',310046000,NULL,NULL,'6502f277568bed2705c5f496e278e5d99310ff6705751a3999cb4b2bc7d725bd','696136b6d9694f3c225298fedcdf51a62af0a9921c973857e1880314b3f63beb','107c06ed2d0da5aa91377775eda027988c805484a76a0e1d0ff5a79f8f4227eb');
INSERT INTO blocks VALUES(310047,'a9ccabcc2a098a7d25e4ab8bda7c4e66807eefa42e29890dcd88149a10de7075',310047000,NULL,NULL,'5dae29289f36e64b87d56f9870af0bd5ad77ca45f1093c1a41140ea397945130','35d0435eef9064d45f7071cdf23ce939b1115e9de35708251a964584f77895b4','4cf876ed7b7f77bba2c32a2fbdbb4b44cd5a8d505037571b8a45a64e408d1dfb');
INSERT INTO blocks VALUES(310048,'610bf3935a85b05a98556c55493c6de45bed4d7b3b6c8553a984718765796309',310048000,NULL,NULL,'d5dee49d7b78e2ce4dd2a648e345a52bbfa7e0e76de9e970b1dc0b6aea66c130','4fd33bce0d6b4bcace6e51848eddbd3b58480904e37a68f68b2ad61510dd9658','bf568a2f491d688909afa35679964979dad64f132eb7ac347546461c2af2b443');
INSERT INTO blocks VALUES(310049,'4ad2761923ad49ad2b283b640f1832522a2a5d6964486b21591b71df6b33be3c',310049000,NULL,NULL,'2b4c97a93933b8986ebb061d47f2e8bbb1672206058ae3c3ae388bab36b8cbc8','a97be25b977480372c8ca374ff844208620f27a68e2d392f97636bc2f1d3f2d0','d4ea3bfcd344ac3be01bdd77bac5a994affe58613f60068f6eea2a3e1f274127');
INSERT INTO blocks VALUES(310050,'8cfeb60a14a4cec6e9be13d699694d49007d82a31065a17890383e262071e348',310050000,NULL,NULL,'115913763ca7ef5691512a5c6d47cbd49203aee8a3242928f62640912c935872','e0f7c294cb638216f1b9b05d44928166070b4e87cc4ade859e96dcddb2346078','4456eb8eed47633c9875eaa8d3f39c63c33b1e8357e46ff6ada8212b640e3502');
INSERT INTO blocks VALUES(310051,'b53c90385dd808306601350920c6af4beb717518493fd23b5c730eea078f33e6',310051000,NULL,NULL,'72f24dc53c759a08aeb447d826bf64aad71ca8f4ab9640e30e440e6bc050a0eb','1c8252d4e2dd9e57cb413b110dab3b8823086b51972c7ba542f63f10141ba995','7b130ba86a4ae887d6286dc40084f9bbe28c2ef37c6bd5cd04be31ae16d4f39b');
INSERT INTO blocks VALUES(310052,'0acdacf4e4b6fca756479cb055191b367b1fa433aa558956f5f08fa5b7b394e2',310052000,NULL,NULL,'07846004f2da033bfd113e13040b0d0d605375370b7437e2ca2ea9467fc80c1a','8f92f9ed19b1a5c69a19249eaf904b4bd7317cd8cf01190bbbb19c612a223ad9','c6061285e701699b4f2370f3a345d9115392fccc474a9526a6a8d999cfbaf214');
INSERT INTO blocks VALUES(310053,'68348f01b6dc49b2cb30fe92ac43e527aa90d859093d3bf7cd695c64d2ef744f',310053000,NULL,NULL,'7bf9a701337c043a7268cecca5ff765c24600a2056137cd03e3ead9d64ef2348','1a6384c755395cb8e3e8ff1756e1a1af9c57cc0d5cda5b9a0376ecb2576133d8','d88ab74ccf245c53f664b7182fe900aa52ed94d13800033451acbe1c47783e68');
INSERT INTO blocks VALUES(310054,'a8b5f253df293037e49b998675620d5477445c51d5ec66596e023282bb9cd305',310054000,NULL,NULL,'d544aec17018203fe2f5c9bda52a5da53d41d3364b8026770d1f620aa53e6c36','ed6f07cb1d850a0640f39ec336ac8af2cdc438019819ed7803befc263f89b0f8','48ffa87f5a953d7bed272369faa5c8a73522a85c1ad7295d056ae53236ea5de1');
INSERT INTO blocks VALUES(310055,'4b069152e2dc82e96ed8a3c3547c162e8c3aceeb2a4ac07972f8321a535b9356',310055000,NULL,NULL,'bd3044c66f7e2c24944a9c938b8f162ac8f566a1338444c219396eadf5179d3e','022c88f88723eb041396eddcfc2810fb7b7af7c4a72c29ab6aff928ad3450b2f','77c1ea9fd2ae5729e62c91562323dfdcde3f21847057594cce9e53152c5ac566');
INSERT INTO blocks VALUES(310056,'7603eaed418971b745256742f9d2ba70b2c2b2f69f61de6cc70e61ce0336f9d3',310056000,NULL,NULL,'b19346f726636aa9da55af6106a471c596a7f7b93289b70d3d33b45334bca9d3','86e83d40435e60335257133bccf6b2f164fcf0ad8899cd84910bd67a08325ac3','d61989afdf5f272d46831ef649343ff07e298e2c5211bc5a37849908595e9ba7');
INSERT INTO blocks VALUES(310057,'4a5fdc84f2d66ecb6ee3e3646aad20751ce8694e64e348d3c8aab09d33a3e411',310057000,NULL,NULL,'35c2ad9ccd3bd68cdb0c4d8fd4e30938521b8559c1cec331a29b1802d649947a','a152d70d72e05abf7149a1ad5e3d49753650d748ebbaa6692e907ea90da22e83','dd40c80d43fb1763050d6730a649a6ad1740066e064a3133d59ef377e02af375');
INSERT INTO blocks VALUES(310058,'a6eef3089896f0cae0bfe9423392e45c48f4efe4310b14d8cfbdb1fea613635f',310058000,NULL,NULL,'e9a705d6661f0345ffe0f45ae26c0d6ba6bd5a125eef2f0e9558d0702ee6d63f','e720c4668bb21ebee8237ba69500fe01dc9f4dceb0c7ac94d0384293c36459dd','365709584d37248d266241a455df0dcebcb2a781e385763c530f18a2e63720e5');
INSERT INTO blocks VALUES(310059,'ab505de874c43f97c90be1c26a769e6c5cb140405c993b4a6cc7afc795f156a9',310059000,NULL,NULL,'61efe4d33a7f70cae34df86753532aee25fb0b153744acb962142691f6979482','821d022109535116be5f42b49df6cf85ed5ab02f71a47e92207ed24ee3ea18ea','60146941ec98ae54a0f0b12c7f8cf84eb75853f0be14f9df53a91c110171482f');
INSERT INTO blocks VALUES(310060,'974ad5fbef621e0a38eab811608dc9afaf10c8ecc85fed913075ba1a145e889b',310060000,NULL,NULL,'59d9785e783c59c12783977087ad439b2dacad9ae1ef2be6384bfc9036da9804','c2780d47d8350870c75ff0e1cdddd0db4b158e0f039216ecfc7f13250905b002','00fccd95832b7115d865f9b6d11dc7a8c2b2a06180c0928eb3945ff2ee2fb1b2');
INSERT INTO blocks VALUES(310061,'35d267d21ad386e7b7632292af1c422b0310dde7ca49a82f9577525a29c138cf',310061000,NULL,NULL,'e257d59ab5dfb01b8396bd12d2fd169f9ac7629365b90bf6e593e627738d3754','ac20bf016e2d2e0ed1fc3187acbbaea57ad3dc746b4d9b49daac31fdb359c984','0ae91e548735687e756702d5245542b5c96114c704dac577fddb0942c2ced171');
INSERT INTO blocks VALUES(310062,'b31a0054145319ef9de8c1cb19df5bcf4dc8a1ece20053aa494e5d3a00a2852f',310062000,NULL,NULL,'0dc0317a88a6fc4ac791cd4d45edcf2a142fb83aa2e8a2f299fcac48a2c2e04d','4ee6a9174a1a5e270b8fd1b11503cd4418631a97071fcf7e6f49b0962d533119','ca08559c0b3982503c71be4eb1c637bb12b326de4afcc27e3f8710b9ad277777');
INSERT INTO blocks VALUES(310063,'0cbcbcd5b7f2dc288e3a34eab3d4212463a5a56e886804fb4f9f1cf929eadebe',310063000,NULL,NULL,'892d6a49aebb262f2a626a35c0806c488c836c04d33122c2d65ecd8904fe3d85','f3ba598cb25fd241ea084390aee3cb41e8694126aebde0efe5c98eb63eeeb529','fb020f3f4a72b2779ac5188c9ae09a9b3ceda8fd480d5af0548150d6c21bcf87');
INSERT INTO blocks VALUES(310064,'e2db8065a195e85cde9ddb868a17d39893a60fb2b1255aa5f0c88729de7cbf30',310064000,NULL,NULL,'e345abbf8dc42737a9f2dd038534409200d63a9ebf5d1cbf3344ea9413c388c0','7bcd2a0aa46d4de0e1a1d3a054a763a7aef07305ffa9ea46bdbe7388fece2266','6613bd2acab2e56dd54320bdce490cafd341a16ecd379aea52ac0170b67a154d');
INSERT INTO blocks VALUES(310065,'8a7bc7a77c831ac4fd11b8a9d22d1b6a0661b07cef05c2e600c7fb683b861d2a',310065000,NULL,NULL,'84ec781d054c0602ed97384cd32cd060b938627ea490a7635fa3ac0babba94cc','c8c5e25aa614a6f3ab05289acf944d7260a393e4f32298ac23587f99635b8714','80da3935b79818e3968f43c6c2eaebb8b44cfe84d13b1a6228f5e013bc89544a');
INSERT INTO blocks VALUES(310066,'b6959be51eb084747d301f7ccaf9e75f2292c9404633b1532e3692659939430d',310066000,NULL,NULL,'3478612a8bb95c2966891fb4d1b35493a1342364a6f08404b83ac9fdda763aa2','887201ffc0ea17e0a32128963aa4c7f316683f132906b54fb2d014c930c37ba4','3f2a7249287cdbf66fdc893736f21468ec51a946a31fd95bbf12c58dca0c0db9');
INSERT INTO blocks VALUES(310067,'8b08eae98d7193c9c01863fac6effb9162bda010daeacf9e0347112f233b8577',310067000,NULL,NULL,'c532c4c5f5e2ae1026ec2582645d9aef06afee46cb9781427a1f40667378ed67','8765907d8242ee1f44966008f508956da9ed5703fbce5461029995529c58731d','d50e4cf80290070cf2d63ba54d4190d17fa6f45871884b3afc6e5a9ff1c5de75');
INSERT INTO blocks VALUES(310068,'9280e7297ef6313341bc81787a36acfc9af58f83a415afff5e3154f126cf52b5',310068000,NULL,NULL,'5508189396fa6dfe63a7d06fe97a3073e986eb305bcb49430157f99e3848cd69','3310e609a318ec7b169265210f45ce7be10a5777c23e432ea1c3aaf20438d255','f756cef6f0dd65383c83ea416f4b7173a2957976c5ab48e87cbd1cea73c942e2');
INSERT INTO blocks VALUES(310069,'486351f0655bf594ffaab1980cff17353b640b63e9c27239109addece189a6f7',310069000,NULL,NULL,'9b0b5d09dc7aaffaf5a3603fa2b914c54b04755a5ddbf83476320149f802292a','399f6fe88b6e839370a296540d89fafba4cb00a0230fd51a071524a57a59e611','68f7c309ab6cfcec428c55869fadfaf2a7f987f7512600a6429941252f5ff59b');
INSERT INTO blocks VALUES(310070,'8739e99f4dee8bebf1332f37f49a125348b40b93b74fe35579dd52bfba4fa7e5',310070000,NULL,NULL,'2e40d398c2eb131e195a667f1b2b5e8de29e80423a2d0dd3935fad6dd7cc919c','fb3b5f85fc22e42bee16d892055e8e67b7f013212e1c0c0efe1c129447dfd6ad','e0519eb6a4c37ac9011505ee8aaada1c491374a64732d91e83b5a8ba5b2400d8');
INSERT INTO blocks VALUES(310071,'7a099aa1bba0ead577f1e44f35263a1f115ed6a868c98d4dd71609072ae7f80b',310071000,NULL,NULL,'763d3d949dc16a797f5b8a2f5a27fd34b4636fa3dbf33eabed5db048e1a848b4','9e28e0ce84f5c5bc2f253ab59f34ee9714a2a5daaa1801766ee56a987da9f826','07bfdb5d905ca15ba7730e381589c23171caa3a05c5e73e9dae83d24d177cc06');
INSERT INTO blocks VALUES(310072,'7b17ecedc07552551b8129e068ae67cb176ca766ea3f6df74b597a94e3a7fc8a',310072000,NULL,NULL,'d9b9d6a52f757604a5652aac64c343a47a928160790963521ce33d125486cb0b','b6a7a07e61822afdba626b752fdfcabb876d868118fff88b32b842f9042b3341','653a3d40578985eb6f2484a3835cf0b261308824403c883379964ae534281f23');
INSERT INTO blocks VALUES(310073,'ee0fe3cc9b3a48a2746b6090b63b442b97ea6055d48edcf4b2288396764c6943',310073000,NULL,NULL,'9c1a650b6029cc982e9e617b619da6d88878453ccea68ff82047581d5cc74e9c','4adcf30a9c7bf0f73cd27a93c2133c1f212db7948de99e70f870edb901e9e449','79cc6c140252db44df20df21f489a05e85f793a52a9ee16e0f07868a7958c530');
INSERT INTO blocks VALUES(310074,'ceab38dfde01f711a187601731ad575d67cfe0b7dbc61dcd4f15baaef72089fb',310074000,NULL,NULL,'32d648a0d0b99f6826376e8badb278c06f95a0ab781cd873e2f7f55219953b01','a00840b8340b55d00e06d47c86a2b36da4231f6dfaca1ce328cd44c0e2fc8216','bed4204871ee5f2b767908401f3437476b523b9f863b954d5cfc4de843234b36');
INSERT INTO blocks VALUES(310075,'ef547198c6e36d829f117cfd7077ccde45158e3c545152225fa24dba7a26847b',310075000,NULL,NULL,'67cd615e67e397cae8195fc8753403563e9100ecd623b2796a46b137ca553be2','ef0e089e02569eeaf42c68389eb9c751a891e985e90a1782b9a282cf8f191d3f','a47917a7addc5d8a2a4707adad2ad8fa5137429095757bf76e3c8ac26be10510');
INSERT INTO blocks VALUES(310076,'3b0499c2e8e8f0252c7288d4ecf66efc426ca37aad3524424d14c8bc6f8b0d92',310076000,NULL,NULL,'d636f3831cd35437271557e6299024d70c4be6b9a685a4fed61e7d67e61540dd','51862315f3cc9bc92b53799df2064c54d17b85fe7ae47c131f2204551dbc9d0e','dbd5221922ea9adb1b17de1d3454f7ce7dd03abec59df28b8c2a8f3e011c6dbb');
INSERT INTO blocks VALUES(310077,'d2adeefa9024ab3ff2822bc36acf19b6c647cea118cf15b86c6bc00c3322e7dd',310077000,NULL,NULL,'abf96247f6b99a24e518d89162c23cffc821d5cae5703f5b7c7c4587e34cdf98','338a21d7510ae328941d63ae15bbc9ace5f4760537541cf4b53e1272bea9bc53','d96efa3e2a345381b17763564a5e372128aa043cd046083273ef975b73408d27');
INSERT INTO blocks VALUES(310078,'f6c17115ef0efe489c562bcda4615892b4d4b39db0c9791fe193d4922bd82cd6',310078000,NULL,NULL,'06aeace2e79321c6776dd1098982e71bfc0baadc55470721022db67a03bd4478','23c50cb387d35297984b5d31a0089564ce48c140dcee48cddc28683f435a5205','27a5c6793e32e9c84ba85a0e05c118ab8d5baa6476c59a4df04e3a7f60b94289');
INSERT INTO blocks VALUES(310079,'f2fbd2074d804e631db44cb0fb2e1db3fdc367e439c21ffc40d73104c4d7069c',310079000,NULL,NULL,'ba2c7078ee940b14e584459985a5a4785156762135541d40a138c31ff9bfe4fb','6fb53a5620fb941d58b95bfb3ec4aa87d0e4e2caaccd094761bcee5603cbcb02','306d14ed6805705842256d7426aa50094060e2a4b8f50efd4de7fe0a3c82b891');
INSERT INTO blocks VALUES(310080,'42943b914d9c367000a78b78a544cc4b84b1df838aadde33fe730964a89a3a6c',310080000,NULL,NULL,'af327b161ed9fa8022f3efd81b695d25ad9ae8f250a6d08739a40b0883262045','9b4bc6eae159dc8fd4e20ce9f35efab266ae514d60629b28089528a366029ab7','c35f0d403226bdc5028e1c0daaa65594049edb996bf47f92c9bdcfcfb5443b5f');
INSERT INTO blocks VALUES(310081,'6554f9d307976249e7b7e260e08046b3b55d318f8b6af627fed5be3063f123c4',310081000,NULL,NULL,'2c4d6568a9c77737c5942fab33613a1ef055ce21b9f0a9b4a42fcdf6e9536a59','7ac535a727e07c8ba84bccf8500f56eb65d8a25108f40b93e90991c51d0e06c0','4ce4fd718e3561339638a3fbbe62c47ba08443cb759a67f7e4ad83e79305963e');
INSERT INTO blocks VALUES(310082,'4f1ef91b1dcd575f8ac2e66a67715500cbca154bd6f3b8148bb7015a6aa6c644',310082000,NULL,NULL,'0b8dcdff637e5e60ae045d4c7646bd47e6047fc992860c99dd422477b9a90d74','b8d879ec26267a85877d07c4323a4ee3eed2244f703038832b9edc8e6cdbd56e','78040337bef8d50a7511699b814b8eea06c4d888510f852a604cd98a6fcee314');
INSERT INTO blocks VALUES(310083,'9b1f6fd6ff9b0dc4e37603cfb0625f49067c775b99e12492afd85392d3c8d850',310083000,NULL,NULL,'eec6578a8bc1f5766427f4753ded18cb97c53e710f5fff8918bbdadb59678f64','341bc17dae9bad815f3dfd3a69a8df337b6c97460b72b72f5a3299c2c4aa2cb1','cfce3dd62671da65918bd2bc7156a8f0d9c8b0c7145bbfc104ca8dc3869587b4');
INSERT INTO blocks VALUES(310084,'1e0972523e80306441b9f4157f171716199f1428db2e818a7f7817ccdc8859e3',310084000,NULL,NULL,'a2b2ed6a61f1c9a3d322a050178c6be119b89d1a0795fa9c9d7484ad8edfcecd','06e8a4adbd4d40d56ac5fc8393246ea06df495d541137dc645941ea9e5d5a3c7','91b49dac60fa8167c06dc72372efd3d9aaae423281b18733abf2f81f579ad72a');
INSERT INTO blocks VALUES(310085,'c5b6e9581831e3bc5848cd7630c499bca26d9ece5156d36579bdb72d54817e34',310085000,NULL,NULL,'02828eaf91883ad16beb5563f9c84cb226269c655a886857b31e5e150a1053ec','fd06b895ffde29c4bf06a046f0ae3cf61c5921336a4f35f3da57d34b60fd5668','e2526c4ada8b5b3592bd9626c543fbf8b7576547624fc8a947465ec30d13394f');
INSERT INTO blocks VALUES(310086,'080c1dc55a4ecf4824cf9840602498cfc35b5f84099f50b71b45cb63834c7a78',310086000,NULL,NULL,'5427b45ed778796c26d0d2ddf73e975856cc9ae081c36762e78d046f6cfc376c','0b14e7c45c4d5df56a3d5aec7067067cfa2a9311d73731b32388a01aca119de2','5753b9e8843d9e4b65385cbb57ff54a47b5057440d03853e8910e5d025a20ca4');
INSERT INTO blocks VALUES(310087,'4ec8cb1c38b22904e8087a034a6406b896eff4dd28e7620601c6bddf82e2738c',310087000,NULL,NULL,'34c2664f81b1bbb53c728636097bc4b7cede67bb318ddcc5e5e6b5735bcc55a7','5c05a372b7fef59688dc4e71960cf12fee50c2dcf13c1bceecb17a32ccbe3684','c2a9d002621eab899130d2629662647cf1a7b0eef8e9b784e521b4a902757176');
INSERT INTO blocks VALUES(310088,'e945c815c433cbddd0bf8e66c5c23b51072483492acda98f5c2c201020a8c5b3',310088000,NULL,NULL,'14615dfa6194665d43cf2f495b8f65fb9efa04c2e90885172d229ad4a9dd2358','ef215a02494f73de0c0347657f220b1abf74376263d45df3018c1d3d86519896','4ad5f2aa0474fd9c6e2b3d7802fb8d1c1617c6789681689fdd37b247f7cf6248');
INSERT INTO blocks VALUES(310089,'0382437f895ef3e7e38bf025fd4f606fd44d4bbd6aea71dbdc4ed11a7cd46f33',310089000,NULL,NULL,'fc0f077548225d481384a1aba2d91ed4ec8b2df0f0a57ab603305c615672b25f','7d292593cd8656876cb669650c36833683e4de53bc500e39440e1e900a0aa803','792fb138a89bfaa42acff8f347d1cbb774b345a3efeb909d716ecb9bd1f599e6');
INSERT INTO blocks VALUES(310090,'b756db71dc037b5a4582de354a3347371267d31ebda453e152f0a13bb2fae969',310090000,NULL,NULL,'5749263295014a597071acf2293fcd185d02a6a7b3a96df859aae3bf146b276e','72ccf9dbe6f9165e937d039169bde2f28ef3d6c011e950e057a7ba740a3f61af','d73ae606582e426d37f16ec3d1acfc0718ce3f25c8588ed94f50abe399c6b890');
INSERT INTO blocks VALUES(310091,'734a9aa485f36399d5efb74f3b9c47f8b5f6fd68c9967f134b14cfe7e2d7583c',310091000,NULL,NULL,'ae369a1ec3e4f2aea602eab8c7ab1181cacd6b8d01582c96c4771fdd7b3de771','3c7bf7f0d554de6de353138acd6a10f37f591cfbdd44219c17effc1b7a97eaa7','3dc09f58845ac733bc079e95890c3a1c3b8ff8a8b2c0ae536810510c230fdbca');
INSERT INTO blocks VALUES(310092,'56386beb65f9228740d4ad43a1c575645f6daf59e0dd9f22551c59215b5e8c3d',310092000,NULL,NULL,'06a2ac591c418d2b01c74edf2524100afd1140c3933f32120c4cc3180c1de3f0','f7a742170351b41a277b7d93c382148dc3a848756c453842efd887e6756f5c6e','d4a657e57aeae2ff58fafbb153c69377d15ad284d3696c7fe08ba983dec79ad9');
INSERT INTO blocks VALUES(310093,'a74a2425f2f4be24bb5f715173e6756649e1cbf1b064aeb1ef60e0b94b418ddc',310093000,NULL,NULL,'cdf0ae4d5d06b8735e3e62f5a76a902fee40742fc760578dae98b43635f2e57a','0126feb6a2757ee547f99250d204d2a801b4b162ccce18900782a95915ef137a','377670e6c082b99251e90459a4eced1447485147d9500b1c050995ca55a510ba');
INSERT INTO blocks VALUES(310094,'2a8f976f20c4e89ff01071915ac96ee35192d54df3a246bf61fd4a0cccfb5b23',310094000,NULL,NULL,'77d836433add0cf3f7691884ec1607dde9a3996df00128703644527fb096bab5','2cf55e7bf342cdf16614c5c4b039559320f48d9ffca5e083813451dac3ab591a','ae9e8aa1859797728a286b7ef7790a05f9937a20298f933d4b70b1dceb151649');
INSERT INTO blocks VALUES(310095,'bed0fa40c9981223fb40b3be8124ca619edc9dd34d0c907369477ea92e5d2cd2',310095000,NULL,NULL,'770a0187b5c98725dc32e15a414b9323030f407749fcb0652b1e1f2e4e762e7e','effbc18f90462734e974e9ba54e28e32a0354955c2ae016f66fa4d58e0a52ffa','f8018a58d9ce00dfa6903c937336b844676259b82ff91d46885d700446730646');
INSERT INTO blocks VALUES(310096,'306aeec3db435fabffdf88c2f26ee83caa4c2426375a33daa2be041dbd27ea2f',310096000,NULL,NULL,'567e91f9456ecd020fbd2fe940d796ac976981485f870db8cb0bc41d77a0fd0f','0c59f9ab4309e7b2f4d40156d30201257263a171a96a6714829f36de3b83bb7b','07106ca06722dcff9ea8f0107eeedc0a06192de3747451983f0bec4cd0f3bf4a');
INSERT INTO blocks VALUES(310097,'13e8e16e67c7cdcc80d477491e554b43744f90e8e1a9728439a11fab42cefadf',310097000,NULL,NULL,'447ceafb93aeb346eb98d87db46f07f4d1f51ffde3d44adc6056a624bea3b0c3','b8e8aaa6c11c4511822c4b8e09127dadb7b88a7d456aa695f93bf561a79500b0','0e8ee91e0586ebbded917101b470734dbcac2093a238005e782d4f50aa46d4e1');
INSERT INTO blocks VALUES(310098,'ca5bca4b5ec4fa6183e05176abe921cff884c4e20910fab55b603cef48dc3bca',310098000,NULL,NULL,'f510ec6201f4eb850d4f62b399d0d360d0d8cca7e3d955f849ad59a22fba1677','36b6d529261f73aabdd8bbf922e5565ea47570306cc223924a60393bc3cc78ed','c789e17bc81ae4bdd38943946023075b869c8193d8379060bea5c34d2fce4e8b');
INSERT INTO blocks VALUES(310099,'3c4c2279cd7de0add5ec469648a845875495a7d54ebfb5b012dcc5a197b7992a',310099000,NULL,NULL,'1f956e2c07defac832b7c90982c1e7a1192988c4d1e622b54b40b78065deafef','c72db338fbf0bff38725d5002c5f41be6eec96ad96f4c0ec96a9f842a7217f81','da9edfb75d2b3f69d7724068461e568cd6bcd9c5ce11bc0b1a26daaad3397cce');
INSERT INTO blocks VALUES(310100,'96925c05b3c7c80c716f5bef68d161c71d044252c766ca0e3f17f255764242cb',310100000,NULL,NULL,'ac4cc3e01feb10ba2211afdff4ec43a4ce13a12e1a90dc6f675c390e6395b1e3','e263b2d9feb9bc8fdb3451df672dcd1b558bf58593b1fb4d3138d2e1d5d0ae25','dd2a3582ed90406d865d54c30f39cc3706c9cda86507b97c8d3ae30ec0a16337');
INSERT INTO blocks VALUES(310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,NULL,NULL,'0a4bb35bf922a8175ef5559e74084d32caa16f599df84adb5e255de26b92c1c4','2f877e4a9bd300c9cbaf076539eac063a9690e2a6dd4c56f4cf1a4a21c99ec13','0144b3e87d3bf92554826edbdb380459efad9937b371fc6c548a4cb6cdf43799');
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
INSERT INTO broadcasts VALUES(12,'7b5c1011873b6a960b4ebb77e2a9fb22da8e65ec69faa4f0ba11d717cce3fda4',310011,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1388000000,100.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(19,'56f842d76ab0841e7f5c109c5add9eb46f44c88d14fd68b6f456570813f9e0c6',310018,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1388000050,99.86166,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(20,'5435a2ee4341f69c06b11da5f5474135b552e8d1fdfa1c590dda4bc5fb534f45',310019,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1388000101,100.343,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(21,'c522e7b202315126aff183b3939a3ce5d8ddf33639a876d1e8a6eca93759d576',310020,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',1388000201,2.0,5000000,'Unit Test',0,'valid');
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
INSERT INTO btcpays VALUES(5,'c8d628a3107bf36f4576fff6a7237019146d06f9ebb99b53a89783ff766d5117',310004,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',50000000,'53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71_cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16','valid');
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
INSERT INTO burns VALUES(1,'c9ff1be2579378fad6d83ca87e6c91428b1eb8cfd1b0f341b3c7e452764404f5',310000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',62000000,93000000000,'valid');
INSERT INTO burns VALUES(23,'3739350ed4c86474468cb1fed825b1ef141304d638b298867d0b2ae58c509c22',310022,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',38000000,56999887262,'valid');
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
INSERT INTO credits VALUES(310000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',93000000000,'burn','c9ff1be2579378fad6d83ca87e6c91428b1eb8cfd1b0f341b3c7e452764404f5');
INSERT INTO credits VALUES(310001,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',50000000,'send','062d5d8a8262f91cc16de8833e429bc92c0a4f63f61c4c8048a41bc254b97fd3');
INSERT INTO credits VALUES(310004,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',100000000,'btcpay','c8d628a3107bf36f4576fff6a7237019146d06f9ebb99b53a89783ff766d5117');
INSERT INTO credits VALUES(310005,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',1000000000,'issuance','ff48da90dfe51b4aa156b69cbda46269886a76a44613a217f1e8dbf172495e12');
INSERT INTO credits VALUES(310006,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC',100000,'issuance','ce78de24c5c55bbac91a3c08e92f4e817fa0cd73c65a5136aa3ded1c7284a6ad');
INSERT INTO credits VALUES(310007,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBB',4000000,'send','f88727652b1502fabb4c45190bdc56b100a3d384bf5976311c4b41f433420bfc');
INSERT INTO credits VALUES(310008,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',526,'send','97e94072d8a73bd1bd2a00a3a48424207dd9ee5c56ba349dfb621d6057870f95');
INSERT INTO credits VALUES(310009,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',24,'dividend','a0b04ac9dd798854a39b5905235237a6cbbe2de50ffd49694a3002d1543f5536');
INSERT INTO credits VALUES(310010,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',420800,'dividend','b93ca7e398b5ffe8173673d93ca9b39984ac9b0bb19f1de45c7c0730a8877690');
INSERT INTO credits VALUES(310013,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',4250000,'filled','b96f2d38e2dfd09addcd61a9ddb18fa7faa72b526a1ec0a4dad8cfbc77d0a839');
INSERT INTO credits VALUES(310014,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',5000000,'cancel order','cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16');
INSERT INTO credits VALUES(310015,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',0,'filled','e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0');
INSERT INTO credits VALUES(310015,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',0,'filled','e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0');
INSERT INTO credits VALUES(310017,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',0,'filled','4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685');
INSERT INTO credits VALUES(310017,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',0,'filled','4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685');
INSERT INTO credits VALUES(310018,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',59137500,'bet settled: liquidated for bear','56f842d76ab0841e7f5c109c5add9eb46f44c88d14fd68b6f456570813f9e0c6');
INSERT INTO credits VALUES(310018,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',3112500,'feed fee','56f842d76ab0841e7f5c109c5add9eb46f44c88d14fd68b6f456570813f9e0c6');
INSERT INTO credits VALUES(310019,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',159300000,'bet settled','5435a2ee4341f69c06b11da5f5474135b552e8d1fdfa1c590dda4bc5fb534f45');
INSERT INTO credits VALUES(310019,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',315700000,'bet settled','5435a2ee4341f69c06b11da5f5474135b552e8d1fdfa1c590dda4bc5fb534f45');
INSERT INTO credits VALUES(310019,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',25000000,'feed fee','5435a2ee4341f69c06b11da5f5474135b552e8d1fdfa1c590dda4bc5fb534f45');
INSERT INTO credits VALUES(310020,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',1330000000,'bet settled: for notequal','c522e7b202315126aff183b3939a3ce5d8ddf33639a876d1e8a6eca93759d576');
INSERT INTO credits VALUES(310020,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',70000000,'feed fee','c522e7b202315126aff183b3939a3ce5d8ddf33639a876d1e8a6eca93759d576');
INSERT INTO credits VALUES(310022,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',56999887262,'burn','3739350ed4c86474468cb1fed825b1ef141304d638b298867d0b2ae58c509c22');
INSERT INTO credits VALUES(310023,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',8500000,'recredit wager remaining','c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662');
INSERT INTO credits VALUES(310023,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',10000,'send','a0e06860c5e6db0aa890002288d961e6dd1a8dda1b030a364325879d1b6b535f');
INSERT INTO credits VALUES(310032,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',50000000,'cancel order','adbc8051e249732266e5988fb0f3abd38dc2fee11fa97da87912a913e0a16d4d');
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
INSERT INTO debits VALUES(310001,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',50000000,'send','062d5d8a8262f91cc16de8833e429bc92c0a4f63f61c4c8048a41bc254b97fd3');
INSERT INTO debits VALUES(310003,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',105000000,'open order','cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16');
INSERT INTO debits VALUES(310005,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',50000000,'issuance fee','ff48da90dfe51b4aa156b69cbda46269886a76a44613a217f1e8dbf172495e12');
INSERT INTO debits VALUES(310006,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',50000000,'issuance fee','ce78de24c5c55bbac91a3c08e92f4e817fa0cd73c65a5136aa3ded1c7284a6ad');
INSERT INTO debits VALUES(310007,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',4000000,'send','f88727652b1502fabb4c45190bdc56b100a3d384bf5976311c4b41f433420bfc');
INSERT INTO debits VALUES(310008,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC',526,'send','97e94072d8a73bd1bd2a00a3a48424207dd9ee5c56ba349dfb621d6057870f95');
INSERT INTO debits VALUES(310009,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',24,'dividend','a0b04ac9dd798854a39b5905235237a6cbbe2de50ffd49694a3002d1543f5536');
INSERT INTO debits VALUES(310009,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',20000,'dividend fee','a0b04ac9dd798854a39b5905235237a6cbbe2de50ffd49694a3002d1543f5536');
INSERT INTO debits VALUES(310010,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',420800,'dividend','b93ca7e398b5ffe8173673d93ca9b39984ac9b0bb19f1de45c7c0730a8877690');
INSERT INTO debits VALUES(310010,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',20000,'dividend fee','b93ca7e398b5ffe8173673d93ca9b39984ac9b0bb19f1de45c7c0730a8877690');
INSERT INTO debits VALUES(310012,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',50000000,'bet','c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662');
INSERT INTO debits VALUES(310013,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',25000000,'bet','b96f2d38e2dfd09addcd61a9ddb18fa7faa72b526a1ec0a4dad8cfbc77d0a839');
INSERT INTO debits VALUES(310014,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',150000000,'bet','801527b9dba145637cb07e12906651f53ffd55f5501d24535bc7a43fb2100c29');
INSERT INTO debits VALUES(310015,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',350000000,'bet','e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0');
INSERT INTO debits VALUES(310016,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',750000000,'bet','c551d52dd756f4fce025dda64bc12ef845746c40c2db544f37a9bc81c1d2bd83');
INSERT INTO debits VALUES(310017,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',650000000,'bet','4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685');
INSERT INTO debits VALUES(310021,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',50000000,'open order','adbc8051e249732266e5988fb0f3abd38dc2fee11fa97da87912a913e0a16d4d');
INSERT INTO debits VALUES(310023,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC',10000,'send','a0e06860c5e6db0aa890002288d961e6dd1a8dda1b030a364325879d1b6b535f');
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
INSERT INTO dividends VALUES(10,'a0b04ac9dd798854a39b5905235237a6cbbe2de50ffd49694a3002d1543f5536',310009,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB','XCP',600,20000,'valid');
INSERT INTO dividends VALUES(11,'b93ca7e398b5ffe8173673d93ca9b39984ac9b0bb19f1de45c7c0730a8877690',310010,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBC','XCP',800,20000,'valid');
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
INSERT INTO issuances VALUES(6,'ff48da90dfe51b4aa156b69cbda46269886a76a44613a217f1e8dbf172495e12',310005,'BBBB',1000000000,1,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,0,0,0.0,'',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(7,'ce78de24c5c55bbac91a3c08e92f4e817fa0cd73c65a5136aa3ded1c7284a6ad',310006,'BBBC',100000,0,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',0,0,0,0.0,'foobar',50000000,0,'valid',NULL);
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
INSERT INTO messages VALUES(0,310000,'insert','credits','{"action": "burn", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310000, "event": "c9ff1be2579378fad6d83ca87e6c91428b1eb8cfd1b0f341b3c7e452764404f5", "quantity": 93000000000}',0);
INSERT INTO messages VALUES(1,310000,'insert','burns','{"block_index": 310000, "burned": 62000000, "earned": 93000000000, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "c9ff1be2579378fad6d83ca87e6c91428b1eb8cfd1b0f341b3c7e452764404f5", "tx_index": 1}',0);
INSERT INTO messages VALUES(2,310001,'insert','debits','{"action": "send", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310001, "event": "062d5d8a8262f91cc16de8833e429bc92c0a4f63f61c4c8048a41bc254b97fd3", "quantity": 50000000}',0);
INSERT INTO messages VALUES(3,310001,'insert','credits','{"action": "send", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "asset": "XCP", "block_index": 310001, "event": "062d5d8a8262f91cc16de8833e429bc92c0a4f63f61c4c8048a41bc254b97fd3", "quantity": 50000000}',0);
INSERT INTO messages VALUES(4,310001,'insert','sends','{"asset": "XCP", "block_index": 310001, "destination": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "quantity": 50000000, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "062d5d8a8262f91cc16de8833e429bc92c0a4f63f61c4c8048a41bc254b97fd3", "tx_index": 2}',0);
INSERT INTO messages VALUES(5,310002,'insert','orders','{"block_index": 310002, "expiration": 10, "expire_index": 310012, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 50000000, "give_remaining": 50000000, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "tx_hash": "53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71", "tx_index": 3}',0);
INSERT INTO messages VALUES(6,310003,'insert','debits','{"action": "open order", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310003, "event": "cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16", "quantity": 105000000}',0);
INSERT INTO messages VALUES(7,310003,'insert','orders','{"block_index": 310003, "expiration": 10, "expire_index": 310013, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 50000000, "get_remaining": 50000000, "give_asset": "XCP", "give_quantity": 105000000, "give_remaining": 105000000, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "tx_hash": "cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16", "tx_index": 4}',0);
INSERT INTO messages VALUES(8,310003,'update','orders','{"fee_provided_remaining": 142858, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71"}',0);
INSERT INTO messages VALUES(9,310003,'update','orders','{"fee_provided_remaining": 6800, "fee_required_remaining": 42858, "get_remaining": 0, "give_remaining": 5000000, "status": "open", "tx_hash": "cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16"}',0);
INSERT INTO messages VALUES(10,310003,'insert','order_matches','{"backward_asset": "XCP", "backward_quantity": 100000000, "block_index": 310003, "fee_paid": 857142, "forward_asset": "BTC", "forward_quantity": 50000000, "id": "53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71_cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16", "match_expire_index": 310023, "status": "pending", "tx0_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx0_block_index": 310002, "tx0_expiration": 10, "tx0_hash": "53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71", "tx0_index": 3, "tx1_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx1_block_index": 310003, "tx1_expiration": 10, "tx1_hash": "cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16", "tx1_index": 4}',0);
INSERT INTO messages VALUES(11,310004,'insert','credits','{"action": "btcpay", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310004, "event": "c8d628a3107bf36f4576fff6a7237019146d06f9ebb99b53a89783ff766d5117", "quantity": 100000000}',0);
INSERT INTO messages VALUES(12,310004,'update','order_matches','{"order_match_id": "53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71_cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16", "status": "completed"}',0);
INSERT INTO messages VALUES(13,310004,'insert','btcpays','{"block_index": 310004, "btc_amount": 50000000, "destination": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "order_match_id": "53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71_cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16", "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "c8d628a3107bf36f4576fff6a7237019146d06f9ebb99b53a89783ff766d5117", "tx_index": 5}',0);
INSERT INTO messages VALUES(14,310005,'insert','debits','{"action": "issuance fee", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310005, "event": "ff48da90dfe51b4aa156b69cbda46269886a76a44613a217f1e8dbf172495e12", "quantity": 50000000}',0);
INSERT INTO messages VALUES(15,310005,'insert','issuances','{"asset": "BBBB", "asset_longname": null, "block_index": 310005, "call_date": 0, "call_price": 0.0, "callable": false, "description": "", "divisible": true, "fee_paid": 50000000, "issuer": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "locked": false, "quantity": 1000000000, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "transfer": false, "tx_hash": "ff48da90dfe51b4aa156b69cbda46269886a76a44613a217f1e8dbf172495e12", "tx_index": 6}',0);
INSERT INTO messages VALUES(16,310005,'insert','credits','{"action": "issuance", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBB", "block_index": 310005, "event": "ff48da90dfe51b4aa156b69cbda46269886a76a44613a217f1e8dbf172495e12", "quantity": 1000000000}',0);
INSERT INTO messages VALUES(17,310006,'insert','debits','{"action": "issuance fee", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310006, "event": "ce78de24c5c55bbac91a3c08e92f4e817fa0cd73c65a5136aa3ded1c7284a6ad", "quantity": 50000000}',0);
INSERT INTO messages VALUES(18,310006,'insert','issuances','{"asset": "BBBC", "asset_longname": null, "block_index": 310006, "call_date": 0, "call_price": 0.0, "callable": false, "description": "foobar", "divisible": false, "fee_paid": 50000000, "issuer": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "locked": false, "quantity": 100000, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "transfer": false, "tx_hash": "ce78de24c5c55bbac91a3c08e92f4e817fa0cd73c65a5136aa3ded1c7284a6ad", "tx_index": 7}',0);
INSERT INTO messages VALUES(19,310006,'insert','credits','{"action": "issuance", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBC", "block_index": 310006, "event": "ce78de24c5c55bbac91a3c08e92f4e817fa0cd73c65a5136aa3ded1c7284a6ad", "quantity": 100000}',0);
INSERT INTO messages VALUES(20,310007,'insert','debits','{"action": "send", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBB", "block_index": 310007, "event": "f88727652b1502fabb4c45190bdc56b100a3d384bf5976311c4b41f433420bfc", "quantity": 4000000}',0);
INSERT INTO messages VALUES(21,310007,'insert','credits','{"action": "send", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "asset": "BBBB", "block_index": 310007, "event": "f88727652b1502fabb4c45190bdc56b100a3d384bf5976311c4b41f433420bfc", "quantity": 4000000}',0);
INSERT INTO messages VALUES(22,310007,'insert','sends','{"asset": "BBBB", "block_index": 310007, "destination": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "quantity": 4000000, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "f88727652b1502fabb4c45190bdc56b100a3d384bf5976311c4b41f433420bfc", "tx_index": 8}',0);
INSERT INTO messages VALUES(23,310008,'insert','debits','{"action": "send", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBC", "block_index": 310008, "event": "97e94072d8a73bd1bd2a00a3a48424207dd9ee5c56ba349dfb621d6057870f95", "quantity": 526}',0);
INSERT INTO messages VALUES(24,310008,'insert','credits','{"action": "send", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "asset": "BBBC", "block_index": 310008, "event": "97e94072d8a73bd1bd2a00a3a48424207dd9ee5c56ba349dfb621d6057870f95", "quantity": 526}',0);
INSERT INTO messages VALUES(25,310008,'insert','sends','{"asset": "BBBC", "block_index": 310008, "destination": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "quantity": 526, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "97e94072d8a73bd1bd2a00a3a48424207dd9ee5c56ba349dfb621d6057870f95", "tx_index": 9}',0);
INSERT INTO messages VALUES(26,310009,'insert','debits','{"action": "dividend", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310009, "event": "a0b04ac9dd798854a39b5905235237a6cbbe2de50ffd49694a3002d1543f5536", "quantity": 24}',0);
INSERT INTO messages VALUES(27,310009,'insert','debits','{"action": "dividend fee", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310009, "event": "a0b04ac9dd798854a39b5905235237a6cbbe2de50ffd49694a3002d1543f5536", "quantity": 20000}',0);
INSERT INTO messages VALUES(28,310009,'insert','credits','{"action": "dividend", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "asset": "XCP", "block_index": 310009, "event": "a0b04ac9dd798854a39b5905235237a6cbbe2de50ffd49694a3002d1543f5536", "quantity": 24}',0);
INSERT INTO messages VALUES(29,310009,'insert','dividends','{"asset": "BBBB", "block_index": 310009, "dividend_asset": "XCP", "fee_paid": 20000, "quantity_per_unit": 600, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "a0b04ac9dd798854a39b5905235237a6cbbe2de50ffd49694a3002d1543f5536", "tx_index": 10}',0);
INSERT INTO messages VALUES(30,310010,'insert','debits','{"action": "dividend", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310010, "event": "b93ca7e398b5ffe8173673d93ca9b39984ac9b0bb19f1de45c7c0730a8877690", "quantity": 420800}',0);
INSERT INTO messages VALUES(31,310010,'insert','debits','{"action": "dividend fee", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310010, "event": "b93ca7e398b5ffe8173673d93ca9b39984ac9b0bb19f1de45c7c0730a8877690", "quantity": 20000}',0);
INSERT INTO messages VALUES(32,310010,'insert','credits','{"action": "dividend", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "asset": "XCP", "block_index": 310010, "event": "b93ca7e398b5ffe8173673d93ca9b39984ac9b0bb19f1de45c7c0730a8877690", "quantity": 420800}',0);
INSERT INTO messages VALUES(33,310010,'insert','dividends','{"asset": "BBBC", "block_index": 310010, "dividend_asset": "XCP", "fee_paid": 20000, "quantity_per_unit": 800, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "b93ca7e398b5ffe8173673d93ca9b39984ac9b0bb19f1de45c7c0730a8877690", "tx_index": 11}',0);
INSERT INTO messages VALUES(34,310011,'insert','broadcasts','{"block_index": 310011, "fee_fraction_int": 5000000, "locked": false, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "7b5c1011873b6a960b4ebb77e2a9fb22da8e65ec69faa4f0ba11d717cce3fda4", "tx_index": 12, "value": 100.0}',0);
INSERT INTO messages VALUES(35,310012,'insert','debits','{"action": "bet", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310012, "event": "c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662", "quantity": 50000000}',0);
INSERT INTO messages VALUES(36,310012,'insert','bets','{"bet_type": 0, "block_index": 310012, "counterwager_quantity": 25000000, "counterwager_remaining": 25000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310022, "fee_fraction_int": 5000000.0, "feed_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "leverage": 15120, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "target_value": 0.0, "tx_hash": "c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662", "tx_index": 13, "wager_quantity": 50000000, "wager_remaining": 50000000}',0);
INSERT INTO messages VALUES(37,310013,'update','orders','{"status": "expired", "tx_hash": "53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71"}',0);
INSERT INTO messages VALUES(38,310013,'insert','order_expirations','{"block_index": 310013, "order_hash": "53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71", "order_index": 3, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3"}',0);
INSERT INTO messages VALUES(39,310013,'insert','debits','{"action": "bet", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310013, "event": "b96f2d38e2dfd09addcd61a9ddb18fa7faa72b526a1ec0a4dad8cfbc77d0a839", "quantity": 25000000}',0);
INSERT INTO messages VALUES(40,310013,'insert','bets','{"bet_type": 1, "block_index": 310013, "counterwager_quantity": 41500000, "counterwager_remaining": 41500000, "deadline": 1388000100, "expiration": 10, "expire_index": 310023, "fee_fraction_int": 5000000.0, "feed_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "leverage": 15120, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "target_value": 0.0, "tx_hash": "b96f2d38e2dfd09addcd61a9ddb18fa7faa72b526a1ec0a4dad8cfbc77d0a839", "tx_index": 14, "wager_quantity": 25000000, "wager_remaining": 25000000}',0);
INSERT INTO messages VALUES(41,310013,'update','bets','{"counterwager_remaining": 4250000, "status": "open", "tx_hash": "c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662", "wager_remaining": 8500000}',0);
INSERT INTO messages VALUES(42,310013,'insert','credits','{"action": "filled", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310013, "event": "b96f2d38e2dfd09addcd61a9ddb18fa7faa72b526a1ec0a4dad8cfbc77d0a839", "quantity": 4250000}',0);
INSERT INTO messages VALUES(43,310013,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "b96f2d38e2dfd09addcd61a9ddb18fa7faa72b526a1ec0a4dad8cfbc77d0a839", "wager_remaining": 4250000}',0);
INSERT INTO messages VALUES(44,310013,'insert','bet_matches','{"backward_quantity": 20750000, "block_index": 310013, "deadline": 1388000100, "fee_fraction_int": 5000000, "feed_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "forward_quantity": 41500000, "id": "c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662_b96f2d38e2dfd09addcd61a9ddb18fa7faa72b526a1ec0a4dad8cfbc77d0a839", "initial_value": 100.0, "leverage": 15120, "match_expire_index": 310022, "status": "pending", "target_value": 0.0, "tx0_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx0_bet_type": 0, "tx0_block_index": 310012, "tx0_expiration": 10, "tx0_hash": "c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662", "tx0_index": 13, "tx1_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx1_bet_type": 1, "tx1_block_index": 310013, "tx1_expiration": 10, "tx1_hash": "b96f2d38e2dfd09addcd61a9ddb18fa7faa72b526a1ec0a4dad8cfbc77d0a839", "tx1_index": 14}',0);
INSERT INTO messages VALUES(45,310014,'update','orders','{"status": "expired", "tx_hash": "cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16"}',0);
INSERT INTO messages VALUES(46,310014,'insert','credits','{"action": "cancel order", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310014, "event": "cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16", "quantity": 5000000}',0);
INSERT INTO messages VALUES(47,310014,'insert','order_expirations','{"block_index": 310014, "order_hash": "cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16", "order_index": 4, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3"}',0);
INSERT INTO messages VALUES(48,310014,'insert','debits','{"action": "bet", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310014, "event": "801527b9dba145637cb07e12906651f53ffd55f5501d24535bc7a43fb2100c29", "quantity": 150000000}',0);
INSERT INTO messages VALUES(49,310014,'insert','bets','{"bet_type": 0, "block_index": 310014, "counterwager_quantity": 350000000, "counterwager_remaining": 350000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310024, "fee_fraction_int": 5000000.0, "feed_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "leverage": 5040, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "target_value": 0.0, "tx_hash": "801527b9dba145637cb07e12906651f53ffd55f5501d24535bc7a43fb2100c29", "tx_index": 15, "wager_quantity": 150000000, "wager_remaining": 150000000}',0);
INSERT INTO messages VALUES(50,310015,'insert','debits','{"action": "bet", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310015, "event": "e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0", "quantity": 350000000}',0);
INSERT INTO messages VALUES(51,310015,'insert','bets','{"bet_type": 1, "block_index": 310015, "counterwager_quantity": 150000000, "counterwager_remaining": 150000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310025, "fee_fraction_int": 5000000.0, "feed_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "leverage": 5040, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "target_value": 0.0, "tx_hash": "e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0", "tx_index": 16, "wager_quantity": 350000000, "wager_remaining": 350000000}',0);
INSERT INTO messages VALUES(52,310015,'insert','credits','{"action": "filled", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310015, "event": "e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0", "quantity": 0}',0);
INSERT INTO messages VALUES(53,310015,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "801527b9dba145637cb07e12906651f53ffd55f5501d24535bc7a43fb2100c29", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(54,310015,'insert','credits','{"action": "filled", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310015, "event": "e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0", "quantity": 0}',0);
INSERT INTO messages VALUES(55,310015,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(56,310015,'insert','bet_matches','{"backward_quantity": 350000000, "block_index": 310015, "deadline": 1388000100, "fee_fraction_int": 5000000, "feed_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "forward_quantity": 150000000, "id": "801527b9dba145637cb07e12906651f53ffd55f5501d24535bc7a43fb2100c29_e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0", "initial_value": 100.0, "leverage": 5040, "match_expire_index": 310024, "status": "pending", "target_value": 0.0, "tx0_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx0_bet_type": 0, "tx0_block_index": 310014, "tx0_expiration": 10, "tx0_hash": "801527b9dba145637cb07e12906651f53ffd55f5501d24535bc7a43fb2100c29", "tx0_index": 15, "tx1_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx1_bet_type": 1, "tx1_block_index": 310015, "tx1_expiration": 10, "tx1_hash": "e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0", "tx1_index": 16}',0);
INSERT INTO messages VALUES(57,310016,'insert','debits','{"action": "bet", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310016, "event": "c551d52dd756f4fce025dda64bc12ef845746c40c2db544f37a9bc81c1d2bd83", "quantity": 750000000}',0);
INSERT INTO messages VALUES(58,310016,'insert','bets','{"bet_type": 2, "block_index": 310016, "counterwager_quantity": 650000000, "counterwager_remaining": 650000000, "deadline": 1388000200, "expiration": 10, "expire_index": 310026, "fee_fraction_int": 5000000.0, "feed_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "leverage": 5040, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "target_value": 1.0, "tx_hash": "c551d52dd756f4fce025dda64bc12ef845746c40c2db544f37a9bc81c1d2bd83", "tx_index": 17, "wager_quantity": 750000000, "wager_remaining": 750000000}',0);
INSERT INTO messages VALUES(59,310017,'insert','debits','{"action": "bet", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310017, "event": "4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685", "quantity": 650000000}',0);
INSERT INTO messages VALUES(60,310017,'insert','bets','{"bet_type": 3, "block_index": 310017, "counterwager_quantity": 750000000, "counterwager_remaining": 750000000, "deadline": 1388000200, "expiration": 10, "expire_index": 310027, "fee_fraction_int": 5000000.0, "feed_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "leverage": 5040, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "target_value": 1.0, "tx_hash": "4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685", "tx_index": 18, "wager_quantity": 650000000, "wager_remaining": 650000000}',0);
INSERT INTO messages VALUES(61,310017,'insert','credits','{"action": "filled", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310017, "event": "4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685", "quantity": 0}',0);
INSERT INTO messages VALUES(62,310017,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "c551d52dd756f4fce025dda64bc12ef845746c40c2db544f37a9bc81c1d2bd83", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(63,310017,'insert','credits','{"action": "filled", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310017, "event": "4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685", "quantity": 0}',0);
INSERT INTO messages VALUES(64,310017,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(65,310017,'insert','bet_matches','{"backward_quantity": 650000000, "block_index": 310017, "deadline": 1388000200, "fee_fraction_int": 5000000, "feed_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "forward_quantity": 750000000, "id": "c551d52dd756f4fce025dda64bc12ef845746c40c2db544f37a9bc81c1d2bd83_4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685", "initial_value": 100.0, "leverage": 5040, "match_expire_index": 310026, "status": "pending", "target_value": 1.0, "tx0_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx0_bet_type": 2, "tx0_block_index": 310016, "tx0_expiration": 10, "tx0_hash": "c551d52dd756f4fce025dda64bc12ef845746c40c2db544f37a9bc81c1d2bd83", "tx0_index": 17, "tx1_address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "tx1_bet_type": 3, "tx1_block_index": 310017, "tx1_expiration": 10, "tx1_hash": "4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685", "tx1_index": 18}',0);
INSERT INTO messages VALUES(66,310018,'insert','broadcasts','{"block_index": 310018, "fee_fraction_int": 5000000, "locked": false, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "text": "Unit Test", "timestamp": 1388000050, "tx_hash": "56f842d76ab0841e7f5c109c5add9eb46f44c88d14fd68b6f456570813f9e0c6", "tx_index": 19, "value": 99.86166}',0);
INSERT INTO messages VALUES(67,310018,'insert','credits','{"action": "bet settled: liquidated for bear", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310018, "event": "56f842d76ab0841e7f5c109c5add9eb46f44c88d14fd68b6f456570813f9e0c6", "quantity": 59137500}',0);
INSERT INTO messages VALUES(68,310018,'insert','credits','{"action": "feed fee", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310018, "event": "56f842d76ab0841e7f5c109c5add9eb46f44c88d14fd68b6f456570813f9e0c6", "quantity": 3112500}',0);
INSERT INTO messages VALUES(69,310018,'insert','bet_match_resolutions','{"bear_credit": 59137500, "bet_match_id": "c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662_b96f2d38e2dfd09addcd61a9ddb18fa7faa72b526a1ec0a4dad8cfbc77d0a839", "bet_match_type_id": 1, "block_index": 310018, "bull_credit": 0, "escrow_less_fee": null, "fee": 3112500, "settled": false, "winner": null}',0);
INSERT INTO messages VALUES(70,310018,'update','bet_matches','{"bet_match_id": "c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662_b96f2d38e2dfd09addcd61a9ddb18fa7faa72b526a1ec0a4dad8cfbc77d0a839", "status": "settled: liquidated for bear"}',0);
INSERT INTO messages VALUES(71,310019,'insert','broadcasts','{"block_index": 310019, "fee_fraction_int": 5000000, "locked": false, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "text": "Unit Test", "timestamp": 1388000101, "tx_hash": "5435a2ee4341f69c06b11da5f5474135b552e8d1fdfa1c590dda4bc5fb534f45", "tx_index": 20, "value": 100.343}',0);
INSERT INTO messages VALUES(72,310019,'insert','credits','{"action": "bet settled", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310019, "event": "5435a2ee4341f69c06b11da5f5474135b552e8d1fdfa1c590dda4bc5fb534f45", "quantity": 159300000}',0);
INSERT INTO messages VALUES(73,310019,'insert','credits','{"action": "bet settled", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310019, "event": "5435a2ee4341f69c06b11da5f5474135b552e8d1fdfa1c590dda4bc5fb534f45", "quantity": 315700000}',0);
INSERT INTO messages VALUES(74,310019,'insert','credits','{"action": "feed fee", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310019, "event": "5435a2ee4341f69c06b11da5f5474135b552e8d1fdfa1c590dda4bc5fb534f45", "quantity": 25000000}',0);
INSERT INTO messages VALUES(75,310019,'insert','bet_match_resolutions','{"bear_credit": 315700000, "bet_match_id": "801527b9dba145637cb07e12906651f53ffd55f5501d24535bc7a43fb2100c29_e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0", "bet_match_type_id": 1, "block_index": 310019, "bull_credit": 159300000, "escrow_less_fee": null, "fee": 25000000, "settled": true, "winner": null}',0);
INSERT INTO messages VALUES(76,310019,'update','bet_matches','{"bet_match_id": "801527b9dba145637cb07e12906651f53ffd55f5501d24535bc7a43fb2100c29_e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0", "status": "settled"}',0);
INSERT INTO messages VALUES(77,310020,'insert','broadcasts','{"block_index": 310020, "fee_fraction_int": 5000000, "locked": false, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "text": "Unit Test", "timestamp": 1388000201, "tx_hash": "c522e7b202315126aff183b3939a3ce5d8ddf33639a876d1e8a6eca93759d576", "tx_index": 21, "value": 2.0}',0);
INSERT INTO messages VALUES(78,310020,'insert','credits','{"action": "bet settled: for notequal", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310020, "event": "c522e7b202315126aff183b3939a3ce5d8ddf33639a876d1e8a6eca93759d576", "quantity": 1330000000}',0);
INSERT INTO messages VALUES(79,310020,'insert','credits','{"action": "feed fee", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310020, "event": "c522e7b202315126aff183b3939a3ce5d8ddf33639a876d1e8a6eca93759d576", "quantity": 70000000}',0);
INSERT INTO messages VALUES(80,310020,'insert','bet_match_resolutions','{"bear_credit": null, "bet_match_id": "c551d52dd756f4fce025dda64bc12ef845746c40c2db544f37a9bc81c1d2bd83_4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685", "bet_match_type_id": 5, "block_index": 310020, "bull_credit": null, "escrow_less_fee": 1330000000, "fee": 70000000, "settled": null, "winner": "NotEqual"}',0);
INSERT INTO messages VALUES(81,310020,'update','bet_matches','{"bet_match_id": "c551d52dd756f4fce025dda64bc12ef845746c40c2db544f37a9bc81c1d2bd83_4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685", "status": "settled: for notequal"}',0);
INSERT INTO messages VALUES(82,310021,'insert','debits','{"action": "open order", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBB", "block_index": 310021, "event": "adbc8051e249732266e5988fb0f3abd38dc2fee11fa97da87912a913e0a16d4d", "quantity": 50000000}',0);
INSERT INTO messages VALUES(83,310021,'insert','orders','{"block_index": 310021, "expiration": 10, "expire_index": 310031, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 50000000, "get_remaining": 50000000, "give_asset": "BBBB", "give_quantity": 50000000, "give_remaining": 50000000, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "open", "tx_hash": "adbc8051e249732266e5988fb0f3abd38dc2fee11fa97da87912a913e0a16d4d", "tx_index": 22}',0);
INSERT INTO messages VALUES(84,310022,'insert','credits','{"action": "burn", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310022, "event": "3739350ed4c86474468cb1fed825b1ef141304d638b298867d0b2ae58c509c22", "quantity": 56999887262}',0);
INSERT INTO messages VALUES(85,310022,'insert','burns','{"block_index": 310022, "burned": 38000000, "earned": 56999887262, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "3739350ed4c86474468cb1fed825b1ef141304d638b298867d0b2ae58c509c22", "tx_index": 23}',0);
INSERT INTO messages VALUES(86,310023,'update','bets','{"status": "expired", "tx_hash": "c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662"}',0);
INSERT INTO messages VALUES(87,310023,'insert','credits','{"action": "recredit wager remaining", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "XCP", "block_index": 310023, "event": "c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662", "quantity": 8500000}',0);
INSERT INTO messages VALUES(88,310023,'insert','bet_expirations','{"bet_hash": "c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662", "bet_index": 13, "block_index": 310023, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3"}',0);
INSERT INTO messages VALUES(89,310023,'insert','debits','{"action": "send", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBC", "block_index": 310023, "event": "a0e06860c5e6db0aa890002288d961e6dd1a8dda1b030a364325879d1b6b535f", "quantity": 10000}',0);
INSERT INTO messages VALUES(90,310023,'insert','credits','{"action": "send", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "asset": "BBBC", "block_index": 310023, "event": "a0e06860c5e6db0aa890002288d961e6dd1a8dda1b030a364325879d1b6b535f", "quantity": 10000}',0);
INSERT INTO messages VALUES(91,310023,'insert','sends','{"asset": "BBBC", "block_index": 310023, "destination": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3", "quantity": 10000, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "status": "valid", "tx_hash": "a0e06860c5e6db0aa890002288d961e6dd1a8dda1b030a364325879d1b6b535f", "tx_index": 24}',0);
INSERT INTO messages VALUES(92,310032,'update','orders','{"status": "expired", "tx_hash": "adbc8051e249732266e5988fb0f3abd38dc2fee11fa97da87912a913e0a16d4d"}',0);
INSERT INTO messages VALUES(93,310032,'insert','credits','{"action": "cancel order", "address": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3", "asset": "BBBB", "block_index": 310032, "event": "adbc8051e249732266e5988fb0f3abd38dc2fee11fa97da87912a913e0a16d4d", "quantity": 50000000}',0);
INSERT INTO messages VALUES(94,310032,'insert','order_expirations','{"block_index": 310032, "order_hash": "adbc8051e249732266e5988fb0f3abd38dc2fee11fa97da87912a913e0a16d4d", "order_index": 22, "source": "3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3"}',0);
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
INSERT INTO order_expirations VALUES(3,'53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',310013);
INSERT INTO order_expirations VALUES(4,'cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',310014);
INSERT INTO order_expirations VALUES(22,'adbc8051e249732266e5988fb0f3abd38dc2fee11fa97da87912a913e0a16d4d','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',310032);
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
INSERT INTO order_matches VALUES('53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71_cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16',3,'53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',4,'cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BTC',50000000,'XCP',100000000,310002,310003,310003,10,10,310023,857142,'completed');
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
INSERT INTO orders VALUES(3,'53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71',310002,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BTC',50000000,0,'XCP',100000000,0,10,310012,0,0,1000000,142858,'expired');
INSERT INTO orders VALUES(4,'cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16',310003,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','XCP',105000000,5000000,'BTC',50000000,0,10,310013,900000,42858,6800,6800,'expired');
INSERT INTO orders VALUES(22,'adbc8051e249732266e5988fb0f3abd38dc2fee11fa97da87912a913e0a16d4d',310021,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','BBBB',50000000,50000000,'XCP',50000000,50000000,10,310031,0,0,6800,6800,'expired');
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
INSERT INTO sends VALUES(2,'062d5d8a8262f91cc16de8833e429bc92c0a4f63f61c4c8048a41bc254b97fd3',310001,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','XCP',50000000,'valid',NULL);
INSERT INTO sends VALUES(8,'f88727652b1502fabb4c45190bdc56b100a3d384bf5976311c4b41f433420bfc',310007,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBB',4000000,'valid',NULL);
INSERT INTO sends VALUES(9,'97e94072d8a73bd1bd2a00a3a48424207dd9ee5c56ba349dfb621d6057870f95',310008,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',526,'valid',NULL);
INSERT INTO sends VALUES(24,'a0e06860c5e6db0aa890002288d961e6dd1a8dda1b030a364325879d1b6b535f',310023,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3','BBBC',10000,'valid',NULL);
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
INSERT INTO transactions VALUES(1,'c9ff1be2579378fad6d83ca87e6c91428b1eb8cfd1b0f341b3c7e452764404f5',310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
INSERT INTO transactions VALUES(2,'062d5d8a8262f91cc16de8833e429bc92c0a4f63f61c4c8048a41bc254b97fd3',310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3',7800,7650,X'0000000000000000000000010000000002FAF080',1);
INSERT INTO transactions VALUES(3,'53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71',310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,1000000,X'0000000A00000000000000000000000002FAF08000000000000000010000000005F5E100000A0000000000000000',1);
INSERT INTO transactions VALUES(4,'cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16',310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000000A00000000000000010000000006422C4000000000000000000000000002FAF080000A00000000000DBBA0',1);
INSERT INTO transactions VALUES(5,'c8d628a3107bf36f4576fff6a7237019146d06f9ebb99b53a89783ff766d5117',310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',50000000,9675,X'0000000B53EBB2ED5C051ACC4F7FBDF6988847795B05C96F2C90066D1967135502B80D71CF2BF59916ADAD3C4C08F9DBA3C8B7252222281E03150892EE23BF6BC050CF16',1);
INSERT INTO transactions VALUES(6,'ff48da90dfe51b4aa156b69cbda46269886a76a44613a217f1e8dbf172495e12',310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'000000140000000000004767000000003B9ACA000100000000000000000000',1);
INSERT INTO transactions VALUES(7,'ce78de24c5c55bbac91a3c08e92f4e817fa0cd73c65a5136aa3ded1c7284a6ad',310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'00000014000000000000476800000000000186A00000000000000000000006666F6F626172',1);
INSERT INTO transactions VALUES(8,'f88727652b1502fabb4c45190bdc56b100a3d384bf5976311c4b41f433420bfc',310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3',7800,7650,X'00000000000000000000476700000000003D0900',1);
INSERT INTO transactions VALUES(9,'97e94072d8a73bd1bd2a00a3a48424207dd9ee5c56ba349dfb621d6057870f95',310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3',7800,7650,X'000000000000000000004768000000000000020E',1);
INSERT INTO transactions VALUES(10,'a0b04ac9dd798854a39b5905235237a6cbbe2de50ffd49694a3002d1543f5536',310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'00000032000000000000025800000000000047670000000000000001',1);
INSERT INTO transactions VALUES(11,'b93ca7e398b5ffe8173673d93ca9b39984ac9b0bb19f1de45c7c0730a8877690',310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'00000032000000000000032000000000000047680000000000000001',1);
INSERT INTO transactions VALUES(12,'7b5c1011873b6a960b4ebb77e2a9fb22da8e65ec69faa4f0ba11d717cce3fda4',310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000001E52BB33004059000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(13,'c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662',310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',7800,7650,X'00000028000052BB33640000000002FAF08000000000017D7840000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(14,'b96f2d38e2dfd09addcd61a9ddb18fa7faa72b526a1ec0a4dad8cfbc77d0a839',310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',7800,7650,X'00000028000152BB336400000000017D78400000000002793D60000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(15,'801527b9dba145637cb07e12906651f53ffd55f5501d24535bc7a43fb2100c29',310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',7800,7650,X'00000028000052BB33640000000008F0D1800000000014DC93800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(16,'e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0',310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',7800,7650,X'00000028000152BB33640000000014DC93800000000008F0D1800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(17,'c551d52dd756f4fce025dda64bc12ef845746c40c2db544f37a9bc81c1d2bd83',310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',7800,7650,X'00000028000252BB33C8000000002CB417800000000026BE36803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(18,'4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685',310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3',7800,7650,X'00000028000352BB33C80000000026BE3680000000002CB417803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(19,'56f842d76ab0841e7f5c109c5add9eb46f44c88d14fd68b6f456570813f9e0c6',310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000001E52BB33324058F7256FFC115E004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(20,'5435a2ee4341f69c06b11da5f5474135b552e8d1fdfa1c590dda4bc5fb534f45',310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000001E52BB3365405915F3B645A1CB004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(21,'c522e7b202315126aff183b3939a3ce5d8ddf33639a876d1e8a6eca93759d576',310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000001E52BB33C94000000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(22,'adbc8051e249732266e5988fb0f3abd38dc2fee11fa97da87912a913e0a16d4d',310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','',0,6800,X'0000000A00000000000047670000000002FAF08000000000000000010000000002FAF080000A0000000000000000',1);
INSERT INTO transactions VALUES(23,'3739350ed4c86474468cb1fed825b1ef141304d638b298867d0b2ae58c509c22',310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','mvCounterpartyXXXXXXXXXXXXXXW24Hef',100000000,5625,X'',1);
INSERT INTO transactions VALUES(24,'a0e06860c5e6db0aa890002288d961e6dd1a8dda1b030a364325879d1b6b535f',310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,'3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3','3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3',7800,7650,X'0000000000000000000047680000000000002710',1);
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
INSERT INTO undolog VALUES(13,'UPDATE orders SET tx_index=3,tx_hash=''53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71'',block_index=310002,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''BTC'',give_quantity=50000000,give_remaining=50000000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=10,expire_index=310012,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(14,'UPDATE orders SET tx_index=4,tx_hash=''cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16'',block_index=310003,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''XCP'',give_quantity=105000000,give_remaining=105000000,get_asset=''BTC'',get_quantity=50000000,get_remaining=50000000,expiration=10,expire_index=310013,fee_required=900000,fee_required_remaining=900000,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(15,'DELETE FROM order_matches WHERE rowid=1');
INSERT INTO undolog VALUES(16,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92845000000 WHERE rowid=1');
INSERT INTO undolog VALUES(17,'DELETE FROM credits WHERE rowid=3');
INSERT INTO undolog VALUES(18,'UPDATE order_matches SET id=''53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71_cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16'',tx0_index=3,tx0_hash=''53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71'',tx0_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx1_index=4,tx1_hash=''cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16'',tx1_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',forward_asset=''BTC'',forward_quantity=50000000,backward_asset=''XCP'',backward_quantity=100000000,tx0_block_index=310002,tx1_block_index=310003,block_index=310003,tx0_expiration=10,tx1_expiration=10,match_expire_index=310023,fee_paid=857142,status=''pending'' WHERE rowid=1');
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
INSERT INTO undolog VALUES(60,'UPDATE orders SET tx_index=3,tx_hash=''53ebb2ed5c051acc4f7fbdf6988847795b05c96f2c90066d1967135502b80d71'',block_index=310002,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''BTC'',give_quantity=50000000,give_remaining=0,get_asset=''XCP'',get_quantity=100000000,get_remaining=0,expiration=10,expire_index=310012,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=142858,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(61,'DELETE FROM order_expirations WHERE rowid=3');
INSERT INTO undolog VALUES(62,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92794539176 WHERE rowid=1');
INSERT INTO undolog VALUES(63,'DELETE FROM debits WHERE rowid=12');
INSERT INTO undolog VALUES(64,'DELETE FROM bets WHERE rowid=2');
INSERT INTO undolog VALUES(65,'UPDATE bets SET tx_index=13,tx_hash=''c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662'',block_index=310012,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=0,deadline=1388000100,wager_quantity=50000000,wager_remaining=50000000,counterwager_quantity=25000000,counterwager_remaining=25000000,target_value=0.0,leverage=15120,expiration=10,expire_index=310022,fee_fraction_int=5000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(66,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92769539176 WHERE rowid=1');
INSERT INTO undolog VALUES(67,'DELETE FROM credits WHERE rowid=10');
INSERT INTO undolog VALUES(68,'UPDATE bets SET tx_index=14,tx_hash=''b96f2d38e2dfd09addcd61a9ddb18fa7faa72b526a1ec0a4dad8cfbc77d0a839'',block_index=310013,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=1,deadline=1388000100,wager_quantity=25000000,wager_remaining=25000000,counterwager_quantity=41500000,counterwager_remaining=41500000,target_value=0.0,leverage=15120,expiration=10,expire_index=310023,fee_fraction_int=5000000,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(69,'DELETE FROM bet_matches WHERE rowid=1');
INSERT INTO undolog VALUES(70,'UPDATE orders SET tx_index=4,tx_hash=''cf2bf59916adad3c4c08f9dba3c8b7252222281e03150892ee23bf6bc050cf16'',block_index=310003,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''XCP'',give_quantity=105000000,give_remaining=5000000,get_asset=''BTC'',get_quantity=50000000,get_remaining=0,expiration=10,expire_index=310013,fee_required=900000,fee_required_remaining=42858,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=2');
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
INSERT INTO undolog VALUES(82,'UPDATE bets SET tx_index=15,tx_hash=''801527b9dba145637cb07e12906651f53ffd55f5501d24535bc7a43fb2100c29'',block_index=310014,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=0,deadline=1388000100,wager_quantity=150000000,wager_remaining=150000000,counterwager_quantity=350000000,counterwager_remaining=350000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310024,fee_fraction_int=5000000,status=''open'' WHERE rowid=3');
INSERT INTO undolog VALUES(83,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(84,'DELETE FROM credits WHERE rowid=13');
INSERT INTO undolog VALUES(85,'UPDATE bets SET tx_index=16,tx_hash=''e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0'',block_index=310015,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=1,deadline=1388000100,wager_quantity=350000000,wager_remaining=350000000,counterwager_quantity=150000000,counterwager_remaining=150000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310025,fee_fraction_int=5000000,status=''open'' WHERE rowid=4');
INSERT INTO undolog VALUES(86,'DELETE FROM bet_matches WHERE rowid=2');
INSERT INTO undolog VALUES(87,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(88,'DELETE FROM debits WHERE rowid=15');
INSERT INTO undolog VALUES(89,'DELETE FROM bets WHERE rowid=5');
INSERT INTO undolog VALUES(90,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=91528789176 WHERE rowid=1');
INSERT INTO undolog VALUES(91,'DELETE FROM debits WHERE rowid=16');
INSERT INTO undolog VALUES(92,'DELETE FROM bets WHERE rowid=6');
INSERT INTO undolog VALUES(93,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(94,'DELETE FROM credits WHERE rowid=14');
INSERT INTO undolog VALUES(95,'UPDATE bets SET tx_index=17,tx_hash=''c551d52dd756f4fce025dda64bc12ef845746c40c2db544f37a9bc81c1d2bd83'',block_index=310016,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=2,deadline=1388000200,wager_quantity=750000000,wager_remaining=750000000,counterwager_quantity=650000000,counterwager_remaining=650000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310026,fee_fraction_int=5000000,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(96,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(97,'DELETE FROM credits WHERE rowid=15');
INSERT INTO undolog VALUES(98,'UPDATE bets SET tx_index=18,tx_hash=''4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685'',block_index=310017,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=3,deadline=1388000200,wager_quantity=650000000,wager_remaining=650000000,counterwager_quantity=750000000,counterwager_remaining=750000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310027,fee_fraction_int=5000000,status=''open'' WHERE rowid=6');
INSERT INTO undolog VALUES(99,'DELETE FROM bet_matches WHERE rowid=3');
INSERT INTO undolog VALUES(100,'DELETE FROM broadcasts WHERE rowid=19');
INSERT INTO undolog VALUES(101,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(102,'DELETE FROM credits WHERE rowid=16');
INSERT INTO undolog VALUES(103,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90937926676 WHERE rowid=1');
INSERT INTO undolog VALUES(104,'DELETE FROM credits WHERE rowid=17');
INSERT INTO undolog VALUES(105,'DELETE FROM bet_match_resolutions WHERE rowid=1');
INSERT INTO undolog VALUES(106,'UPDATE bet_matches SET id=''c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662_b96f2d38e2dfd09addcd61a9ddb18fa7faa72b526a1ec0a4dad8cfbc77d0a839'',tx0_index=13,tx0_hash=''c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662'',tx0_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx1_index=14,tx1_hash=''b96f2d38e2dfd09addcd61a9ddb18fa7faa72b526a1ec0a4dad8cfbc77d0a839'',tx1_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=15120,forward_quantity=41500000,backward_quantity=20750000,tx0_block_index=310012,tx1_block_index=310013,block_index=310013,tx0_expiration=10,tx1_expiration=10,match_expire_index=310022,fee_fraction_int=5000000,status=''pending'' WHERE rowid=1');
INSERT INTO undolog VALUES(107,'DELETE FROM broadcasts WHERE rowid=20');
INSERT INTO undolog VALUES(108,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=90941039176 WHERE rowid=1');
INSERT INTO undolog VALUES(109,'DELETE FROM credits WHERE rowid=18');
INSERT INTO undolog VALUES(110,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=91100339176 WHERE rowid=1');
INSERT INTO undolog VALUES(111,'DELETE FROM credits WHERE rowid=19');
INSERT INTO undolog VALUES(112,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=91416039176 WHERE rowid=1');
INSERT INTO undolog VALUES(113,'DELETE FROM credits WHERE rowid=20');
INSERT INTO undolog VALUES(114,'DELETE FROM bet_match_resolutions WHERE rowid=2');
INSERT INTO undolog VALUES(115,'UPDATE bet_matches SET id=''801527b9dba145637cb07e12906651f53ffd55f5501d24535bc7a43fb2100c29_e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0'',tx0_index=15,tx0_hash=''801527b9dba145637cb07e12906651f53ffd55f5501d24535bc7a43fb2100c29'',tx0_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx1_index=16,tx1_hash=''e6f0f001573cc115d7e0631e93f0c19072b38344663d720d2d4b6d53a8a062c0'',tx1_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=5040,forward_quantity=150000000,backward_quantity=350000000,tx0_block_index=310014,tx1_block_index=310015,block_index=310015,tx0_expiration=10,tx1_expiration=10,match_expire_index=310024,fee_fraction_int=5000000,status=''pending'' WHERE rowid=2');
INSERT INTO undolog VALUES(116,'DELETE FROM broadcasts WHERE rowid=21');
INSERT INTO undolog VALUES(117,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=91441039176 WHERE rowid=1');
INSERT INTO undolog VALUES(118,'DELETE FROM credits WHERE rowid=21');
INSERT INTO undolog VALUES(119,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92771039176 WHERE rowid=1');
INSERT INTO undolog VALUES(120,'DELETE FROM credits WHERE rowid=22');
INSERT INTO undolog VALUES(121,'DELETE FROM bet_match_resolutions WHERE rowid=3');
INSERT INTO undolog VALUES(122,'UPDATE bet_matches SET id=''c551d52dd756f4fce025dda64bc12ef845746c40c2db544f37a9bc81c1d2bd83_4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685'',tx0_index=17,tx0_hash=''c551d52dd756f4fce025dda64bc12ef845746c40c2db544f37a9bc81c1d2bd83'',tx0_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx1_index=18,tx1_hash=''4140920350272088d7e18a9a8df7335156c924efd13941a04af08aff76e70685'',tx1_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',tx0_bet_type=2,tx1_bet_type=3,feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',initial_value=100,deadline=1388000200,target_value=1.0,leverage=5040,forward_quantity=750000000,backward_quantity=650000000,tx0_block_index=310016,tx1_block_index=310017,block_index=310017,tx0_expiration=10,tx1_expiration=10,match_expire_index=310026,fee_fraction_int=5000000,status=''pending'' WHERE rowid=3');
INSERT INTO undolog VALUES(123,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''BBBB'',quantity=996000000 WHERE rowid=3');
INSERT INTO undolog VALUES(124,'DELETE FROM debits WHERE rowid=17');
INSERT INTO undolog VALUES(125,'DELETE FROM orders WHERE rowid=3');
INSERT INTO undolog VALUES(126,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=92841039176 WHERE rowid=1');
INSERT INTO undolog VALUES(127,'DELETE FROM credits WHERE rowid=23');
INSERT INTO undolog VALUES(128,'DELETE FROM burns WHERE rowid=23');
INSERT INTO undolog VALUES(129,'UPDATE bets SET tx_index=13,tx_hash=''c2c200de0b8c985d958357a809af0fed20ed3c7dd5515fd3566e4021087de662'',block_index=310012,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',feed_address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',bet_type=0,deadline=1388000100,wager_quantity=50000000,wager_remaining=8500000,counterwager_quantity=25000000,counterwager_remaining=4250000,target_value=0.0,leverage=15120,expiration=10,expire_index=310022,fee_fraction_int=5000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(130,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''XCP'',quantity=149840926438 WHERE rowid=1');
INSERT INTO undolog VALUES(131,'DELETE FROM credits WHERE rowid=24');
INSERT INTO undolog VALUES(132,'DELETE FROM bet_expirations WHERE rowid=13');
INSERT INTO undolog VALUES(133,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',asset=''BBBC'',quantity=99474 WHERE rowid=4');
INSERT INTO undolog VALUES(134,'DELETE FROM debits WHERE rowid=18');
INSERT INTO undolog VALUES(135,'UPDATE balances SET address=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj_3'',asset=''BBBC'',quantity=526 WHERE rowid=6');
INSERT INTO undolog VALUES(136,'DELETE FROM credits WHERE rowid=25');
INSERT INTO undolog VALUES(137,'DELETE FROM sends WHERE rowid=24');
INSERT INTO undolog VALUES(138,'UPDATE orders SET tx_index=22,tx_hash=''adbc8051e249732266e5988fb0f3abd38dc2fee11fa97da87912a913e0a16d4d'',block_index=310021,source=''3_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_3'',give_asset=''BBBB'',give_quantity=50000000,give_remaining=50000000,get_asset=''XCP'',get_quantity=50000000,get_remaining=50000000,expiration=10,expire_index=310031,fee_required=0,fee_required_remaining=0,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=3');
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
