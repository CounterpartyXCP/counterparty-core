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
INSERT INTO balances VALUES('2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',149849426438);
INSERT INTO balances VALUES('2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',50420824);
INSERT INTO balances VALUES('2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB',996000000);
INSERT INTO balances VALUES('2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',89474);
INSERT INTO balances VALUES('2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB',4000000);
INSERT INTO balances VALUES('2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',10526);
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
INSERT INTO bet_expirations VALUES(13,'6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',310023);
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
INSERT INTO bet_match_resolutions VALUES('6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1_f0d2a7c5d14e94a67b9917282b3d7198535e444a5d3c1d2b84260aea2ce5d48b',1,310018,'0',0,59137500,NULL,NULL,3112500);
INSERT INTO bet_match_resolutions VALUES('a7049b5fa97a608a0b3de5d169a12b8a585e94e038ab89852c630744e9b60f36_07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f',1,310019,'1',159300000,315700000,NULL,NULL,25000000);
INSERT INTO bet_match_resolutions VALUES('f7463c39fdcf70265fc7e3e1e8418086c6cf3cead714121fdb19f240f47c4868_ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5',5,310020,NULL,NULL,NULL,'NotEqual',1330000000,70000000);
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
INSERT INTO bet_matches VALUES('6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1_f0d2a7c5d14e94a67b9917282b3d7198535e444a5d3c1d2b84260aea2ce5d48b',13,'6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',14,'f0d2a7c5d14e94a67b9917282b3d7198535e444a5d3c1d2b84260aea2ce5d48b','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',0,1,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',100,1388000100,0.0,15120,41500000,20750000,310012,310013,310013,10,10,310022,5000000,'settled: liquidated for bear');
INSERT INTO bet_matches VALUES('a7049b5fa97a608a0b3de5d169a12b8a585e94e038ab89852c630744e9b60f36_07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f',15,'a7049b5fa97a608a0b3de5d169a12b8a585e94e038ab89852c630744e9b60f36','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',16,'07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',0,1,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',100,1388000100,0.0,5040,150000000,350000000,310014,310015,310015,10,10,310024,5000000,'settled');
INSERT INTO bet_matches VALUES('f7463c39fdcf70265fc7e3e1e8418086c6cf3cead714121fdb19f240f47c4868_ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5',17,'f7463c39fdcf70265fc7e3e1e8418086c6cf3cead714121fdb19f240f47c4868','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',18,'ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',2,3,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',100,1388000200,1.0,5040,750000000,650000000,310016,310017,310017,10,10,310026,5000000,'settled: for notequal');
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
INSERT INTO bets VALUES(13,'6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1',310012,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',0,1388000100,50000000,8500000,25000000,4250000,0.0,15120,10,310022,5000000,'expired');
INSERT INTO bets VALUES(14,'f0d2a7c5d14e94a67b9917282b3d7198535e444a5d3c1d2b84260aea2ce5d48b',310013,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1,1388000100,25000000,4250000,41500000,0,0.0,15120,10,310023,5000000,'filled');
INSERT INTO bets VALUES(15,'a7049b5fa97a608a0b3de5d169a12b8a585e94e038ab89852c630744e9b60f36',310014,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',0,1388000100,150000000,0,350000000,0,0.0,5040,10,310024,5000000,'filled');
INSERT INTO bets VALUES(16,'07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f',310015,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1,1388000100,350000000,0,150000000,0,0.0,5040,10,310025,5000000,'filled');
INSERT INTO bets VALUES(17,'f7463c39fdcf70265fc7e3e1e8418086c6cf3cead714121fdb19f240f47c4868',310016,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',2,1388000200,750000000,0,650000000,0,1.0,5040,10,310026,5000000,'filled');
INSERT INTO bets VALUES(18,'ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5',310017,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',3,1388000200,650000000,0,750000000,0,1.0,5040,10,310027,5000000,'filled');
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
INSERT INTO blocks VALUES(309999,'4b5b541fe4ea8e9f9470af202bb6597a368e47cb82afe6f5cee42d8324f667640c580cb69dce4808dfb530b8d698db315d190792647c83be6a7446511950834a',309999000,NULL,NULL,NULL,NULL,NULL);
INSERT INTO blocks VALUES(310000,'2ee5123266f21fb8f65495c281a368e1b9f93b6c411986e06efc895a8d82467683e6ea5d863714b23582c1c59576650d07c405a8d9bf0d088ee65621178b259d',310000000,NULL,NULL,'e816bc52c35d49565a37fa1bb9c98ed5c53aa8dcdd72c52fdb9e507a7c9cb812','cef6e8ff97c15914de17b99b704707b3eb9514d489cbc1bd0061d65c23e38b32','686445958dfe29cccf38990c13d667a4e1a596c5a9a8752d24d47a2e1809c75a');
INSERT INTO blocks VALUES(310001,'03a9a24e190a996364217761558e380b94ae9792b8b4dcaa92b6c58d80b9f8f7fcf9a34037be4cd6ad5e0c039b511cccc40c3438a5067822e3cd309f06519612',310001000,NULL,NULL,'8e848283d0ed13b3122b178a32b94bc8e0aa7b5abc82280e3fde4e6c90676a61','4bb66b3c8de333007be317749372121a6e8fe89e666d871705862a67e4488262','11be5745cd705a142e0d153bf0960f32cdbe64cf4eddd3c12006b2e052a41c2b');
INSERT INTO blocks VALUES(310002,'d574e4fee71454532c0207f27b9c46f07c5c2e20f43829ddeee8f798053413ac6e0d1b9ad2259a0370fe08581fab3e950ce629db5fadd823251254bf606a05bd',310002000,NULL,NULL,'bf25d797eaa3a10445fe4aa9b708ae0bf586dc5bf9a485f89b025c997be5d454','2389a1d2c0fcde41a5d4212db0d214f63700286771c09a919c04529d9e2278a7','ae975ae8b1a7dfb4f9ec4042353f7e35ea008beb1b633cd0f8f51676d22fbc93');
INSERT INTO blocks VALUES(310003,'44392d9d661459ba31140c59e7d8bcd16b071c864c59f65e2edd9e3c16d598e81aaba40f11019a379bfc6d7811e0265fbb8b276d99cdea7f739fb736f433052a',310003000,NULL,NULL,'888d0894da9cdfef60d5f6897347e23f504022fad9c5e32c5d515678f9f9ccd3','361ad3bf9a200b351803e6f77f175709fb7e997c0b5aafd5ec30d99b1ceaa738','c4e58152b9573cff47166339fed607cb9a4950e5d2ccf9f11291560fa824a2e2');
INSERT INTO blocks VALUES(310004,'58c6f6fbf77a64a5e0df123b1258ae6c3e6d4e21901cc942aeb67b1332422c71e1e7e996c5d4f403159ce5ca3863b7ec7ef8281bbbce5960e258492872055fb5',310004000,NULL,NULL,'1d9688881cdeb863cc8ca8d6adc12a8cb095bd586744ab6215f46e113d0cd622','cd09e2c8dfdc04312fa5c72e298985ed80e3ea4f003f36184b7a8c2aae17d48e','a85b8f7159d279ee2d65265af1a5f76b6421d3b260e63f2c4d6f57109636f258');
INSERT INTO blocks VALUES(310005,'348a1b690661597ee6e950446e7a1deb8bef7906c0e98a78ab4d0fe799fac5f3007dcd648ff0c61da35b19cf99f16f3028e10ba206968475d741fa8a86c4a7ae',310005000,NULL,NULL,'e41568e9c2d6aeb3bf7093312374bf5aa9a8ba870d1e0b6301afef8df2be2416','ba9d7e4c52ae540ad3e8c8d92714f47c66ddd1f047288d0ad4ce987199f2cb1b','3ab8999bc5952f6edca1c721fbfc4158b66fab4dda83366cf87ec48897f61a3c');
INSERT INTO blocks VALUES(310006,'9d31b774b633c35635b71669c07880b521880cee9298b6aba44752ec1734cd2aa26b3bed95409d874e68685636a31a038b784d3e085525ab8c26f7e3b7ba3676',310006000,NULL,NULL,'b42a7337b295149c2b4b8ce2cb84b7af2e851151ffdfa4d2032ea68e8b249913','00bd878443fae225662cd9d12aa5e6f9b7aac1f51621f7bf7096ec3a05de40c7','71a652edb5632cd32af858c55c151a71472fc16973adaa654eecd70f85350e99');
INSERT INTO blocks VALUES(310007,'41007a4ed39e7df941059c3db6b24b74c1913b80e0fd38d0073a5b121880fd0f7e98989d8d70766957919371fdaf4e5b44125f9f7c449c3b6bea298253075fe3',310007000,NULL,NULL,'361ce9e2b3439309bab9b178296b0ad5e5a36333155f55b24d3f9a7694aa723a','c815dc87d2af16aec79d815c9c99cf1c6efd9f6b4aad726d3624f976bcde42a1','3c5b6bf2b5b571deb0538408306286ce3fe3ac45ab34f566487728cb77a74104');
INSERT INTO blocks VALUES(310008,'aa28e5948d1158f318393846b4ef67e53ca4c4b047ed8b06eb861db29914e9f1dfe11a8b73aa2225519843661a61e9038cb347015be916c5a44222ed71b8b604',310008000,NULL,NULL,'aa82a49c881e74962acc7f89327fa8ee2f780795d477da64057483e14fd81a74','de908fe16f26f282b3cca41988831433714aa1c02588dcdb86f90ddf20e4f338','063b448cd93ec9e2bb092d758621df4bac97912991f8070dd7a536e717df2e53');
INSERT INTO blocks VALUES(310009,'550d7d84590c6e4e7caed4e722151f7e110dc39bf3f54f719babfe89775095abb2d2454014b4cb01fb1e0a7e91639559ce17e096be5178b5c2ca5b22ad41b33a',310009000,NULL,NULL,'d5cfc49d4841d7153135da28f880671c874f08d3fc4f43dd82b0a97aec2f0cd5','a361a6c5ebbe2f8d1f2ae6f9bd1b1fe57062bac4d17c656f7b14f48ded4a781a','f512553c21b2bfc2198e9c9e708c4ce92f9168d11dd285ae42ad9a592a05e451');
INSERT INTO blocks VALUES(310010,'477c4a3445e32cd0c8ef67c808ac6a6362ebc953c396e2d5c0d7e4f185becd15fa99bd7635358dbb3b5a92e9f03b7fa2dda8d4714e181ec4552b279df3ba81f0',310010000,NULL,NULL,'ad4c8b6bee2c0fefd6344ca14e90f3b080a31b7748deeed4e7bd55bba20d09fc','7e834cf89a6995d7d3b2e4cb61c3b43b1dccaec5234a5f2fa91c52e52726711f','088086651a375f10fa151881b23888580bcb3392b019274b10835a01b55cc771');
INSERT INTO blocks VALUES(310011,'05f81b5c1b067b647894014cea65558826be42cca20a6cccb8623d80059182b77da00922539c59a0a7b63f6f011ca0f564fada0451e891644728b874c65267b9',310011000,NULL,NULL,'32c883ad4818e0dc9c2838d5f496dbaf5de00da7a2f512ab47afaff883f87eec','042149ac06c19ea8e19599b02c82d8f403ed93a07228a42698ee348db89825e0','2baf88c2347350160c4a44a104d550b8af37a3d56901b8bac419d21b74d69304');
INSERT INTO blocks VALUES(310012,'e9d898aae43fc103110e4935cabf01b6016571b1af82e27af04b57c12302b05eab217f075ac3344b0a422e76b8c762c119cb290c867bb6eed432994ec28af027',310012000,NULL,NULL,'0684336ba5aeebc8b8e050ddaac757015a4c1e3373aae137470ca40c908cd507','a211c005c442016195e9dfa3cb7e15afe1da42ed702b75987eaa8057cbec04d3','6d606a82e17fa3bf4c5278875ec9c44054f018e434ad43575ed54e407edefef2');
INSERT INTO blocks VALUES(310013,'2251b497007459321f72cda82681d07d131dd81cc29137b18c534bbb09271678f4497d0316ffac262f021f901078926dee11c791a3524ad850ee948474abd3b5',310013000,NULL,NULL,'a09e84b4852b63827394c31411bdb905124b037d58d8b76a8347e81da9f97969','dc860f05623d83e0c60292c2b830596686f5145672fcae2c590b1c197915c8f9','de1c2e703cd85627f07df1f39293d079f98c4af066cd5545fd84a07370eef187');
INSERT INTO blocks VALUES(310014,'f98fb331e66361507190a1cb1df81b814d24517e7f219029c068b649c9b8a75703770369ebafd864d104225d6fe1fbf13705d1a37a819b04fb151ed390d7bcf8',310014000,NULL,NULL,'923add1899335dba733a7cff4d7afed4e71ba341923449af5db0d3c54d5be993','207c5daf7be17428d92fc52a8c1115790f903b09141e38e0a579bbd4ceebfe1c','25337c2b17f2bd17fc60d323ea59c58f122e4d2c6b39ed86c5a8557265510a58');
INSERT INTO blocks VALUES(310015,'7c25469d6b4fed0e8bb9e4325994c4de1737570fece605b4ca388be6921406b64a395dc519b33c0dff4f93930b32737a941bbb850e31f2ebcd2caba520bc2820',310015000,NULL,NULL,'6d4967ceb5678cea8d8294fb96ae32e0b62a62f0e0377fef126862152eeba561','c3cf470589b1beac49a0cd9a866f22b074830b1c8b6330429e81e3de30a9accf','32505c4f5c257f96193d0a72d3371493b16195cb2cf8dbe5c1d6bca484b4dda1');
INSERT INTO blocks VALUES(310016,'9f1c56677b369099f059cc145b98f2e3f8895631cdf0f72b7fe76fd953ab68c202329848dfb53f8146552876eba37f50ed02da34f23447f518449bf0ac0cc29e',310016000,NULL,NULL,'94ef9a4780b1f7873708b25184b92050c95f7408e11d9997d040e453829aceae','386718951a500e8274ad9d306fbe99a7e1658741d851e06d7a741ecbab6e770e','6b65135bc3fe7efe23526b1840813220ecf8c1d1f54858c7eca7b47a845023a7');
INSERT INTO blocks VALUES(310017,'4c02945de20ccdc874ae21bf56aea2f40a029c17b81fcf602b367bdbc286f9ec0cacab35fc07ac60aefa4a96a586aed20129ad66d45ab87697704d731e06b40d',310017000,NULL,NULL,'aa9a3504d2885f270e9e6c06bf8abb3ad1103d4579c073a56cf4fbfb48217efa','af599f4467672b3ee5606de2e8ce9b2c1962c763c01a172cca4c9691c5928c03','c549360f2088fd2fd374e9742ad6a99de8da9f4a158f66af3a228ca5db30c726');
INSERT INTO blocks VALUES(310018,'6a26d120314af1710052c8f8f78453f944a146039679c781e04ddbb5a2d010927726fa6f81d3e01fc1fcc3363c06e8e1a81a35636684c4dbcd51edf561a9c0fc',310018000,NULL,NULL,'90f06376f6836d4bf561c1e85eef21193202d30b9e4b8dc3072b5c366563b51f','5d880c0fc859b32d78dcce0667ebb0330fdb570666c2ed2bff78f8eee25d045d','805f7fb18db8d6a8ab1861b343d8632280363bc1276c45b83cd33df046839125');
INSERT INTO blocks VALUES(310019,'592e775a9259b1a5a7b0d7c2e028ff320783e7b49243ed6a20ece89a72964f3af4ed129698c4a143ad682a1493f982c5f8193d3b0e36b3df43964520409beb7a',310019000,NULL,NULL,'602b4a0d153c06b3c6ee847411ad48fdee7086404c6ec6ad85faec28b35b327e','9988113cd3354346d1bdcc6d3c34cfd0c6c75e9f714eddf5692cb73570f78145','e640b13b08ca0070d7fbe9e06d3dd85eec51a1d8ca5040540f1b6d342378e717');
INSERT INTO blocks VALUES(310020,'87fac74eef20e6121d9a66c90481f801a10d636976a6a6e7cf42fc38cc104a470e1b4cab3f9670be86c93ec1a407a1b464599121df6c8109ec7247b25c7efc62',310020000,NULL,NULL,'45a0a236aa8c016d28a303caf112aeb4d36707164dbf1176f540e2c7d6263b67','79b933a2c0e7a7d076edf3c48e382ac7fa7cde33cceb48ed8f5c68c7b4d925fa','9a2bf869172c2f6a191f423d79c32792fcb1964399e330df24305d3cc9e32371');
INSERT INTO blocks VALUES(310021,'68a4f307918e2f39fb393e5ad6a7e2fb2e35ab5043402ce37e984de670579682af5c7ef98637478bc0efeb579dc9aaca7f199116b390c452ceedca420909355d',310021000,NULL,NULL,'f90afca1e4374e0262f3df2df3471b72cd80c68df0ec7aa4c73615d1c58f7988','869913d09f06ad472bc8e08f73697010fb7f4e972196b411c41cd11e9dde64f5','85155a91c81282638c3ee0effaf6bfdca442b0568a7c21e695f812e5db4adb44');
INSERT INTO blocks VALUES(310022,'5052fbeb009f77f5629fb701a2e4a379ef6c5591a87ab4d2315c8b79fc8821301b21f146150b2af542eddd82e8e94bc021dd1a9ef8e837891248ab68f4afa7d0',310022000,NULL,NULL,'c3db3a28d76c563e542a2b51a5c0d64cceef756f60f35c5e5f6c45bdb70d4a09','b4e2cf4d59b93f189a6168df3db35d7b988eb5973d3a38de646563e664d5848e','0b6fdcbc202573be69bffd64001ca983ed593e36a5a6666fb459b8bedaf3b430');
INSERT INTO blocks VALUES(310023,'1aab02bbb1a7450d612af368e571d955812f9a376e9f7f80c8eb8296ec40ebfa964f5c9b5e56d4e0cc2d584b38c3280c2b8b2ac272ac00f4d0bffd5348006b4c',310023000,NULL,NULL,'6ff05f741b50093ebc810df7c7fb5e1b8380808f6fff797be08bcd4f7efa5053','4dcdec371d40fa61864765eb13e9cf431bac4ce89dcd42e7352883ba2234db1a','ac4a0e6331a797b6a2c247d73e9c51d19e0fc8ccee63de70ff3abc9800f9311b');
INSERT INTO blocks VALUES(310024,'232fc55d72da13e22bb39e10cf9bdc29a634f1c6d13c598f8a1886fc6adde9f0db1ec92afc8f2e7e099ad1d225277067c9beebb14116168bcc961d43cc0a5b88',310024000,NULL,NULL,'b16a04470b94666225efca948d8b7d767393ee9efc94219a8d26895cbb60c22e','3ef3c701800f6074bb602b571e5a8d19781fbbdd60ca267c05bc250437f9585c','741509ad4c717f610d23bb5243429ded3c191ad0f0c273020da6f7d682556081');
INSERT INTO blocks VALUES(310025,'39e5551cc35f579114d5a36f841b8aa487e8277ede3b03bfe73f31b16ffc92d8a9535c485518839f3a1f5789222f234e3ac59e67f949ebb2f86044e72296a4fe',310025000,NULL,NULL,'dbf56ff9f01dabe4542e7750fae099ab1cb1fd45bb2983f85fe32431340b3111','691dd63747b61dce784041d75fcac41c3dd4656adc4274a1a3aff1c90c968e0d','a62637a35a5043e2800f18cb6523c67514d3671438ef2a8365725409800ca780');
INSERT INTO blocks VALUES(310026,'dd6f9e911867c1680a777ed34699914cae82576da2f3fe064cec0f77af56f3af2b9309a9e56195f3a63897446e7cc37ebfa8257aa4758e81fcf70d9b12d77bbe',310026000,NULL,NULL,'239af650125aa4bda16074af2a09979aa5d7ea3567aa1f59a798f7c305b6c46d','ba0fafe054064946852a671ba79e2c80a52693b442503976abac73862e954ad7','0f701b79c3b362bd981d5f3162b4808ce3ae365537cf932ca18c1ec4bdb596d5');
INSERT INTO blocks VALUES(310027,'9adde4402993118c8963435b66b5cd74676459f5aec1f4098ded4e99592879c8072b1603611ccb10fa2f1e7e88e087f812553796839664f2a3ed510c4aed9337',310027000,NULL,NULL,'5880e8b5d2647e884a9fb77fd638e81a0f38b4b4a64df3934c3c71b43504239c','49b26d082c924e19605789f985cf78038aaa03e96471efc1f75e2f2c64f37719','c2ebd04a011f8ec94b151c511fbfecc2b7af29da2d3e531092d912748df365f9');
INSERT INTO blocks VALUES(310028,'158e01a36be6070d70d4f5723fca07d5a49fa057b32c651893df7bf1c5752a41444ddb9499d11fdfdaa7b5a63070f9294a55e1a6a4e751ed154b5330dc10111e',310028000,NULL,NULL,'56af8635bbe2abebdc5aff4f836c5baabe70f84737537273088f7528149ec71f','5f8af77533501f78f0202cd7efd646e62e3c652eb948c219176cc532caa00ff3','d17aea4ef56a3e4628eb6b4219b747f23c7a5796bcd80557a7dee2717ff41b26');
INSERT INTO blocks VALUES(310029,'fcd8b3ff5ebaa56426855b262003f15cc0602e452db1ec6c9bc475388553d4766503fc6cde9290903fff1dd94652676b826a229031ee7cb56f69a6d633895fac',310029000,NULL,NULL,'800221e277c8e05cf0abc79c046decc45b055ce89ef0ff82fe6ba12697280f07','ddd58b10691c1ddb56100821e2c22d068134db04f6fdf980e1f339b20679b43e','b20ac214f61703c08589be19d8099ec4f09e67af938b98517dbd2c414fe193d6');
INSERT INTO blocks VALUES(310030,'b49587ccb88b99aa75b91045c596f731a16ce7523207ae0cfd2b2400898576943ae0969a28c5500d20d72a33c9a79b5fc3f5840bd550846d272462cd66fcc259',310030000,NULL,NULL,'d8a712d33cef1a92c370f1fbb8415fb76dd3bdbdaecb02ffd5c89b9c6c2fce16','56d1f71235ffba9d7fec50368d5ab4574cd095d1943593cb434a87193ebb8bd2','38d12732bafdf07267834dcc72c75ef18c1d938c028ba70b77a5624a2abc01e4');
INSERT INTO blocks VALUES(310031,'7a898e085dea5f59d75df0d4b5dd1a8b12c269d1eaef4e8c78938294abef4813e858c6e6f7bba2e5918a853f71decb610ce80fe3da936587396c44086eed86c8',310031000,NULL,NULL,'b4cd7c58d30d0cce0f96e37061f2912eb1265feba175c7acc159cc34285f79ca','6aba61d75f95c0684b26d94ecd21479346cc6e85c29a26a6e86c74d5fefc1679','d505d38737a770a94d66dce65ed2d9fcef96f097927fc96b66f3131691f4bf3c');
INSERT INTO blocks VALUES(310032,'d5778cdb9b17207d9caffc0190842356895364e0c5e6247f02c2fb91d4dcde85becbc7958f07b9c99a9833f45599a0c175a8a3b026ec879467142eff3e3c1457',310032000,NULL,NULL,'0613a2b221c159e9ed7888d9510f95a93e3343feb779481e37ebe71d8d0daf62','2a331acc92b438105204a52eed8080e08c964db4770ac71c0027f89a74c54be4','e68e9234b3c46b70e142a3cba104bbce037da57f69b778788e8d47718ec68ca9');
INSERT INTO blocks VALUES(310033,'ecc0f5ba6c110a32e76689e934d9101617db692d61600ebfe32b500fecd78dcf75bd5712de67e59b99d5b16d9eaaa8378a46a73a35fb10f8821bf75a173507b0',310033000,NULL,NULL,'7aba755f4181160a2ff0c5198488ae39e00bad9a945b337999d4fb279adee2ac','5cf04732ef406d3d77352d8e5c245ad69e17a82c94a19be7dcf4ec2a3a78dc1f','ae569028fb2e25992ff015efcdfa577e7886914647f796951ba28f275490bf6c');
INSERT INTO blocks VALUES(310034,'75ece066b260c4843383467558849588e5ce1f1634da9bea7c9c0e1821150a386baf940a2624b4c0c3fc4bc4996bf97f545fa61a4ec90c57ca5127c1ccdbec84',310034000,NULL,NULL,'57706a1f21ef11de63cd1bdab42947fe9a65f2ac25ad4cc8d512051ac15f7676','659f18b1e6cf7409ba1c4842e81048bea8599bc750157a90b7b3872e09aa0274','0dfd11ffd1701a35a5c3c15b3bbe72b02b47fd49606d20a6c468aa6d7a903a41');
INSERT INTO blocks VALUES(310035,'0c8e6a86abf191a1bad2897dcc7aad3e5a5c1439799c55c95f435eb6fb9e50ac892d58d1a9c9424009d0730fd59ecb202de2e1c155d5fc70a8da9868946caa51',310035000,NULL,NULL,'185ccc6c0ce76cbab13199bd1585ef9c59a786c2b2bb5bf497de52a01e06dd95','f3288fe5f0279917100021b23b125d7d5608be4895265dd3ba036b8ab71e2750','360bf820f77fe665edaf009efc7db0202a17aa18b7eb22abd61be31ad1f7828b');
INSERT INTO blocks VALUES(310036,'4011ea78ccc04ca2ee8d6bf0b14eef82bfa9456869415a8126f2bee5a1bf961c8436571c00fe20e82c78bee44159e0a3523736123c641b871d271642e8f7ef1b',310036000,NULL,NULL,'7224964eb0ff40750d2f6de365bfca18844a68635b37f0e961a9df2f9635aecb','180440a84eca85f3d7abd993fb56b40ed1586008263c8bed6ec90b3bda5ab4e2','c9d2b1a9563d7dd9ece4eaaa5faf389d053a26f017bf89f05dafbb149505d082');
INSERT INTO blocks VALUES(310037,'7f94ef56feec97124f1e6f04b862fed49ae7c179ee143701cf0eec922b5d39932831274f5528d8d9b0e8e115236cfca7f2d78da21db5596565314e625300ef49',310037000,NULL,NULL,'daea77a4b0bd18c07c1136c8c7a7f9de8a44b2dd7cf492d367e57a87d15fa427','f5f8134f2c7fdb7505fa54d7fbd602857d48941970f2f4854c983432c136351e','eb160bae105fd60586ddb3e16d25c85d465e4778d2f1c81b0a2d44321c254a0b');
INSERT INTO blocks VALUES(310038,'e7c42cc00226117b58f818813df49a64af8ca6352a8490a2894676aba647c1bc8d4ae58bb883b710348233879c841da83eda54d35c5ec279f8a2e1ccba8a4264',310038000,NULL,NULL,'f0dc045412fc563df1607db011629f49336a4f7247be490fc55e9ef7d1410bda','9b353bacbcf68d0da280012daf32b6cca7907527926ea75336ffbefcd488f8d3','17903cb4639ec5f9fb59347b6c39ffd29b49fe7580d3f33b040b0e61ecaf3494');
INSERT INTO blocks VALUES(310039,'1efd67747830ff43e4cb5f2837d40789a0a781a79c5de4a7966ef64101c39169c28b7eb78481c4b92d14d997be3bbc7f5c6a6a8af8c729825c0e6a07fc6fbeea',310039000,NULL,NULL,'f0b68981e18ab7b4effd302d012484b07dd417867bb4f258f3c34621b3d2ad5f','b453a094848bc46fb909586805c099c2872a209aa90f8945fdaf74177805f9bf','6ec4351bd2ce694819aaa0e96c1bdcf6566ee0fc365573f88845c52ff508f442');
INSERT INTO blocks VALUES(310040,'0afea7365138d9d478c1a57003d66b1998e462cfe57a9a3a1a9360f5e305e9e639387f6849770c33995e1126cefa8ed66faf8a8af03e5c0853191091978d04b1',310040000,NULL,NULL,'a7d6ed81356649564a8c26880321d2d8321f0ecd9edb101b7ec35886e598af97','fabdf5879aef498076e0902db44022a83fcf220f76252d01cff8e75506cfde06','519a775424dbb69221c2a803f1139b0a016fe22054500ba880fb6387f3f6accb');
INSERT INTO blocks VALUES(310041,'a332959f882f2a2846237e5ce8874beddc8e28c551f7d5be885c79b1d4650c5ff3c9855069302643e9315390e2dc1e7e072e7f90afecd5fe4f3f14b31f38caf3',310041000,NULL,NULL,'a1d86c43453104e1fa31fd2db8a9f8cf54b31388ddcae3f3565f86e4b5da2920','dc564d76fac60b40d321b937fcd0ba039ecaf93d1fed112318f86711e7271bbb','13cdb77bf5c22ea41554b4b77eac20dd9c7cc67d4d7974f7c8b82bc7b4778f9f');
INSERT INTO blocks VALUES(310042,'ee6c4eafabbae31087db301639be2c8d82b31a3004ed19a30a3c6faafdef5c0a363ae91e97c4cc88254bfb0d16213816e610da28233ee3775969dbeba213ea2e',310042000,NULL,NULL,'1b08ae78e0c437b9f5086f86a51ad5673a32cf713928b7b7ee8a75c83322d5f7','b3ecb099f2d52b6b11a845a3d0d1fb814410c850a09db8e0a5064145446f5697','ea1ba1660ac9c76d8d065caa822c197b0450aafe0958d3b84b7057146a3d0f26');
INSERT INTO blocks VALUES(310043,'1fd0b3a1241e5435a39f816d44b6a009780a37e2a131fa7be8423875f81defa4b571a0c9b89cc335c2698dbd66f55fa333bb80e20fa2ed03d9c3e8c95276d05c',310043000,NULL,NULL,'cec50fb80a39aa3d0ab802f0ee846def8ffd2da1855a943ab84a8638265c732f','e1b8fb9539f4cc05aa22f664e195982e3b610f9dc05dab1ff1a8ba6e0fbda9c4','f3b97fca4721a85f8ccefe09f8410f1f4f74ae80e83bd11d975234fa68e39a5c');
INSERT INTO blocks VALUES(310044,'8074ad14f920e3bcdfe75f606c3a261e14275b3ec48d8678841492f633feb1a25c48c729e10d192e59d52b1ed5bc10185b2d0636835b05b3962e4be08b06f194',310044000,NULL,NULL,'2ca02778165680d5928fd1a08a7354ed513564bb97f5e78a1957354a721e4904','458b3cc9f33fe809005ff8ff45ffd4273447a184700e441420093c79a8a05c31','2c7bf92f83d8bc872b98f1d85020563502777e6df10e0d69f97607873a8af665');
INSERT INTO blocks VALUES(310045,'edbfe164803ccbc044c2d602e6ee85546a00d478e5ec3a9475a487cfcd7deef64155b201530367be15262f05ae77a8270ac8dfed18355302a01bc37d0d1d98ea',310045000,NULL,NULL,'422ba010cd15a99b2fa0e79702343a524a51805c19d0e7e54645d08958a6fbe6','351861db2a3dd49e4e5de2e8dafb1d7336fe0b68c6f1451b47ea0999f40717f5','7e3c6adf2a80871a11a971a37ece4476c0bf213920de62d93d5f6f8c82f4d857');
INSERT INTO blocks VALUES(310046,'c1d7a9dc0c93554dacedb41e6f4e7d97b7cf23a9706e6052b7c583233632b4f3cb8596e5b59b6957413ea1da603c2fe125eacf6b2257fb2ae48de3652893eb22',310046000,NULL,NULL,'02e0541583d2c50497b36068ce1b6d97b39405f56467ba1d75ef7c579760527f','33a4b257a3b2d75cbda96985633de00493e70b610ce21b65ad3c3d745db35565','fb89647bc5000cd0bb5067083b381d5c4be6ac8b8fe72e5c6ce0faca5c5210e3');
INSERT INTO blocks VALUES(310047,'86c6061e10d6032dd6051842afb28b6121ba443e4ace7ebcc213258fbd8aa86136ea03f5c3eafe13e560b9589871011f786bf204cc8ac6a419c263f138ddf72c',310047000,NULL,NULL,'d941669f9e431e712d860033703129fa49f32835815fedc6869439db1d7ae974','010b6a4841dbd938f47c984dad8ca15f42858de3397afda18f46668505442b25','b4bd3c8600de8de74bf135d7d8560b4bd9e11b473d69845b4fed55c7decb2507');
INSERT INTO blocks VALUES(310048,'41f80924d6d10e6ff29f9926dcc1bc644a30d87657975c22165d4c54f8c30938b9bec93e24e7033bff0ad7e6540bec0ae0c3333c7f54499c7809c450cdf91451',310048000,NULL,NULL,'d08fbe5408671c75fe5f29aa878382b9440b5437dfe41d29c098c141fdc36472','33f5bd290e5edcb82e5d0a04941f3c691e627a319256307240fa312fc5cf6694','f90cfe98b0efdfb41925543eeeef2f68fc1bbfb0c5a1bf38944054070964c7c7');
INSERT INTO blocks VALUES(310049,'51e01a7614ad99af02c4171df920803ed9a88ff9a47254f0d0faf521f5f806b840bf88a311c54a08edbb9fc2f152214bb930f1b8368245c8cd263473b79f808b',310049000,NULL,NULL,'63d7952cc9ca391008390dda8d828de313cec102a05fbbb07ac33be446ea4d36','f99a826f91aeb4ef0c68ca4b6605d58e3e9636d73fbf014ca0758b083f3e08a7','5f1d3a6c53ef584c2311dfa28775db293fa5b9c01fbeb09ab7b6f12fe91a2452');
INSERT INTO blocks VALUES(310050,'c719b9e1f31934a3bf53ed8f8a4f59ad22f3d0481008f4a7116f31cbfcd2b71ebf296f8a6890f522c72303d63c6f6b76b802f5b93808620f3b6ff515155ea73f',310050000,NULL,NULL,'182b84f3d015b349365d31e2b2affd8e170355e2d3324ec028261209dbbfe084','cc3d250047ab1014f1a078d459f964534d2bab278e53f26ffdf0654d26adc527','96bd9255028085d63e84c6f76000425a998657b1693c0fbc7005a39db78f0b1c');
INSERT INTO blocks VALUES(310051,'e88246311bb74b66ad0f97fe2f5734e0c68d0329f05a389c35ef8a8575e8c078b92b401bccdf84f2950fd884cf0c22e2079594050292b01ffc69c8e779150ac6',310051000,NULL,NULL,'2b3f4788c774098ee318d2add0636a6bc3c90b3fcf05067175f74367baac9871','e4b2c0460a9befb04b56610a7659ff363dc8cb98fd34a776a6ac9bde8ceb9ad7','918f8a00c34762ec1d0bf35e7b9ec66aff646d34fc61cdd8a001a430e56f62c2');
INSERT INTO blocks VALUES(310052,'1c7e09c9d97f26b1be51752c372a88ff5b5da358c76002a42647916b5e27d8e0f75effc92c15f034a75cab7ca8d8a9ec34c64f1fbfe8690c585cafc553add37d',310052000,NULL,NULL,'a137236a6885d0888fa3290f3eee03d0690ce7ab614db275f195dfd6684b247d','6e1fbd74579bd07594076b02744d6902fd94460997bee1c076c147bc9e9f252f','4611afc23b76e30a4386ee53174e2172bf12958a42a52193ccf3a7d87be03e3e');
INSERT INTO blocks VALUES(310053,'60ed831a77cedc82909d871edc4e6525de5669cc238f7b9010336b4f5c80f4eb29fc8f8f05cb9a41db4e1311f437015c8bb02b214b69cf04f909e14868ccb66f',310053000,NULL,NULL,'711d347d4a6e2396a2022fad421836ae4ff7d19e4ccebd690d62721e2318141f','4cd876af6594f6b8e83e2ec149e1c0ab8a2aaf6a9112dcc8990706badcd41757','21d1d3c34ced5df3249a5082e7cdb2dc2ee87fcb8027373a445a7a9463fb642c');
INSERT INTO blocks VALUES(310054,'0871d6f27552c73bda0f3a9f2557d87b89a0589ed5da70ed84a42dd89456a877d24e0e439953fff2123f110100aaf350755afe5ba6ccbe4f01b1965528e1b39f',310054000,NULL,NULL,'f6603211b827feea8c66561e64a33b80953d1c72a255615c0c1693538d6f237f','0f166800c04437ddce27a4f2e7ee3c2deecb801d77e8bc3a0ecd589cdf3fae7e','7ed49c883fa2799263cb84cd6d8afc6bf1bb1692e9188f990128fc350a2cfabd');
INSERT INTO blocks VALUES(310055,'3edee52236cc6d3fcf0c9e108ca28515924cbfa3b9ab8d6f2ce59b1f234558ba3d50c88381fc53f0d607e67dfa8cf497f45f32def36c5a444233a0edaa649987',310055000,NULL,NULL,'68f1c842433153648ef29254b88e9298cb372ff2b2e6896425adbba50acc4ef7','772fef71ce9b7591412cc03c32eebabb319f12831b55971ced31106961e3b8f5','46d3598ca4a4a46eebae553f5d52e91f25d4df831156b9e9d6ef121f2b0893e9');
INSERT INTO blocks VALUES(310056,'bd46235733652f0ae9e77cd97e22a371fb6778c023c98e49684616eee72b64696b1376ebfcc8e897ceb18d8415b08d5d8b27bb788bb1f6de3b8baf985e2f5c0b',310056000,NULL,NULL,'b9eb88d9cae7ca88da2113debfa500f867ccfb6f9c9154fc29694bbb081e7181','90ebae76152dcbeff8842f928752af420ee74fa87e832b810054c5f2ea13b63b','d93ab72c4a509d2c8f77978d7d2c3b7f37374968a01085fd45fd255ebefb73a1');
INSERT INTO blocks VALUES(310057,'91e818ef3f1425e86d13808bcb5cb4125205d61f8d063f21cd37a445269ad14f96bdc18283a12ddde8d6775bc55b2ff91c7910fd7d512ee242dde68d8d4f1520',310057000,NULL,NULL,'7d1c0879946a01511cdd68603fd3027083f69c16e6df29f4df8adee4e3f03242','203667ef6b4e9d265b506586f2c506f27dba9e689f483fad9c8c35ef0fb2f7a1','ee9f8a923bd5edc04ffeb0decd059f598ee8d366c661bceddbb2dc2725b2b0aa');
INSERT INTO blocks VALUES(310058,'ab68270f350c7c11d62cfe38e0b20c6763c770f9d9dbbfaa16cff8ab3d746a9b71047d4fde90c7705688b7f36ed3479a9718fb1a455cdedb5bf97309e3344e3a',310058000,NULL,NULL,'9cac9b7b2196d8c3a84fc470826f57e46b2f1fb36888e7c23ce86df4697dc93a','14f6ae9c9a446d48cb000db91852a2baae13ef91b38e9c678c4eb788a5eff6f2','1652cddf3b9f20a63a3fcf724dd1b5605fe2c456316c8da0398bf58ddef9b2f5');
INSERT INTO blocks VALUES(310059,'d08b01ec4f2055eed65363e748f638470b4e989c815ba93395c139de56eb925e577bf05c46a1cf2051a238a2ce1c62bb137583d12d9b5a30e3d1fe2118e50009',310059000,NULL,NULL,'f2d5ad6fd9b92e4aa3fa6c23fd94d6d9ef2667827e26efa4c92d50bb34c9b72d','d4d41e3ba44db61c3457418dc7349e42ddd63fd486c40c085b086763923592bd','aec10fc3651944fac48b4099acb10a9ead65933ea5924401506d436996eca6c3');
INSERT INTO blocks VALUES(310060,'76cc352a0973bd5cee8255c511eff6cc34a554d636ef61ab3ef6621dd0eaab17b3032e5ade33c8712b1d45960ba779974e79998b0b7738b6815ac93d2eb8181d',310060000,NULL,NULL,'9f3f8d37f9a8e7bceaa006d0a2edbca6e6ddf0d73de342839d035a41369505f6','bdc8a3d3fc5476b2639327c0e16d6cefc29c9c76df4e069c8ee7ea36f943c355','67b175bd4776628bfa630035677728d26121c1d9b76944245121cfa1bd3e27e0');
INSERT INTO blocks VALUES(310061,'80a038ba3f297cfc699d7be560b9be58d8a88f4b127468e22d5d633b6b3e359430d738c20f7c5182a435bcc1a49a056e84ce705ccc504405bb70700030f86260',310061000,NULL,NULL,'fb9ee691ca3312c3403dd37410d8aa8548b222a376aa4066186c914d27fd33d0','51e4b1b8a8080a88785cd0ca163edc0684a556b251663f357955a4b851108e89','9f210711cab6c319487161dc22f820dded76a83c86270099a1758b7cbed4445d');
INSERT INTO blocks VALUES(310062,'9fb37033c32405d7e00ff9b69272079af198e9960fbddb8dbba542b7b6911ceb833868bad3759566a7a2736b9d719ca82690627d83491ed40467e6b18830a711',310062000,NULL,NULL,'e56199cb9900ac69881bb1c6ab1601bef5a8eef7c1a544061416bad54b9a1036','08a360979db2fb08eba104e5180c0b0d9c477d1ed31d65eaf1b95ced05dc0fab','3fce4be49dcfac4a2daf9a74fd7bc0a3a636f447042cfc7eab1eb403b33b375c');
INSERT INTO blocks VALUES(310063,'807f83f652635dd041b0e46222d9a136099f478a5159c501735eb3a64b32d664250ec44f4668df72b1f2b8ce34ff2e1c260b6fcd87febebcc44e99faa098cd7c',310063000,NULL,NULL,'b9bb45158dd2f43e33d3519f6ed8686e9654d6f7e6aa84d1190bcaf93ced6887','b20ebce3e214fc4e908941ba5eeee69fc0588f0e744171ce0a3366a2a52826c2','6a2f835ad4c0b86f6df7b35b115fc0c2e519af8cdc1e14ffa001f06c0b3768f3');
INSERT INTO blocks VALUES(310064,'cdfd286ed7373f1a2b525d37a903df4ac53788422414fa5fa5b408dc04d11991b3bb3c7dc7be3bc98d65c31265c01abd59f6c9f4cf6cb25c8da4a28fcc74f576',310064000,NULL,NULL,'ecb5bb8f0ea58caf8c4f2ceb499ecc3ff6a93c97afe6b8c56ae668bb43dad59e','451b2556e986041b99141cb9887527fcf023196bee93acf9acf4e47ab0ddbc25','56d883f44f5aa83ce35a523597ef5caa372f8581d307eba4c0abd9a112cbdb73');
INSERT INTO blocks VALUES(310065,'e971d529b30e42e87f399558d975181220fadc9b160b37dc5fe82752be193de9c7022dc509061f99158c7e585799f336ea3dd8fe63d55b57772af676e91108c8',310065000,NULL,NULL,'6f9201a85e9c0e15436a8919b164e55dc425ac6a6bc24164069c67cac54423c0','e94f8f31c7dfef00e533c2c33eb0f23cc70b9b3c36beef1d3bce97fb3a428c5b','7782ebf91ae95adc0ae83721c851d5334cd7af7e4b8ed7117cfd12d79d5be47f');
INSERT INTO blocks VALUES(310066,'0758bfcf08b5a8eb40e4937fd84fc69458338483a8471865b38fa252d8644be6c22962996b80aa3fb37db97f2e2a213049c9cb356d8564d26fb1ad5de14ccef8',310066000,NULL,NULL,'993bb15f85c784f46cf83f752972330cf2470e56f4ca169c1cd467d5ac4a22c3','77ce7fd4876c9f0e512341f4c0533ce53b9c658687d6696539a6facfa44ea4d6','dd492d96fed8eca2952066c54a074cea0817e5e7fa013104ef9f0bf41fd98a2e');
INSERT INTO blocks VALUES(310067,'359caeb095b44b88cb86676c4a94ac830211c31e25c326c9c75e3ac60c5f28c1ee7387fc46ac6ba2946a6ce41a067637047ac4effb32777dd9f694ef1aa88ef2',310067000,NULL,NULL,'e74928b5d3a29e79e31913c19638f03d6a8c91a97d182c30a6a168509c6a8420','2b5fac3b54ad941155517c931997fadbbcfdf76b49fa77b3beb2818aa1425c4e','43ff701a7ed46c2f08cacf72f389ca75978f16eb715912bbd3cedd778400b047');
INSERT INTO blocks VALUES(310068,'2f1264342a2fd66c9493f2fa062cb8477ef86f72c532149ffd45353fca250a9985c027d7ccee2e646c96533196f6dd60ef9bcb12b3f156dbe71edbd088418487',310068000,NULL,NULL,'a629046420d71c8dfd8ca11a56d0a78d9bc26f20c6852d3ed56309fe5dc6ed40','8eca4ac79073cbcc2884edaba91413fa5e781949dd2b1baca8b5a6dbc431964b','5018f361e3a6e9e8c7a2295c16beeba34269afdbfb741fcdfd4bac82c23269da');
INSERT INTO blocks VALUES(310069,'b08114be39f1ba70cbf72cf9ac4b008d8582dce4d4d7c789e7da57eb264fab24fdeceae387dbb23d5dc0c73f8faa013c5a499ee8d2761b959128c9694802230e',310069000,NULL,NULL,'17148fa6f1483c0c44773a2e6daac1c079255d473fcd92191b52feac3d1a5ac3','2ed9edf874ca7bc0b02b3b3dc9471bfba631535b9b84aac37bc0ba8b58c4e458','1bd7e2b05d56066021c0756c83b524a2bb5136cb165211e698d26e6cc9fdef78');
INSERT INTO blocks VALUES(310070,'5f1384e1063f3c21946d063c75dcb43a6ddc4642eac6f79eee0a80ea99320bf8b26ecf86b1e79889e1c733cd278219e76315130a30b440d84cd288be58bf3853',310070000,NULL,NULL,'504dab28a409f1ad2d6d72c194ce9876622805c72d1460a5a57ed1552f371df3','500bb6d4d50850c0d9cbd310f50b5983c5416937696f9905a83e4865d9a4d212','5b7f3f542ceabaf1c32a4cd533e414a940d2d06bcb2782a6e1d080ede8e43c2c');
INSERT INTO blocks VALUES(310071,'c80b492818257e806e4fbe093c89c7965275aa8e36d1bb888d1f79a059e95dadc40273e59de99eb8d80c5e8e1445509d8baee4c733d2c470598620f3048cfafd',310071000,NULL,NULL,'95baf4d73e054e765d0ce826f62f6e4876f4bcb7505cc34b4f1cb2f21f3b86f7','d2318bd8e97b6b4d21d53ea11751185f8b6727dd77ad4f241c937c46f462f158','aaeae872d746f51294b43daa20b1976aa4aaf52951e097a8ba8870577b455ecd');
INSERT INTO blocks VALUES(310072,'64a311227b25fe4606729312295546a9ade70637e896cdd8321257c0b173e38701be1e5bfefbdd2cf1eb908d5076f2b464c8664281cca6a9d9bfd715ca085a93',310072000,NULL,NULL,'504414ff8ac1d24ab1f89f1d051eb78bbb41fd6ae0530fd02facd962a2ea630c','dd92e193f2d12a007f498d0b0e291b831a2c94a39d499235a2018e1417a89e55','e1d64cb0927d1e20ce300e84f1e08ec3a76fd2c0a83676bf4c50f10820523b36');
INSERT INTO blocks VALUES(310073,'acc6dfdc3cf0651092a08818eed4eeaf9abfd322f1e46bec97e6a8ce96317612d4f3873e194310f1335da4ac225ed92b1a59237cde4fe1d2049be6a2b66c1f1d',310073000,NULL,NULL,'d940c802c3784ef802459a3b3740f0923f16e850e42b69a22e683aafe012e411','d9286ae0f5c1bc6543a8546f69f684be0f6422bfc2c5ed1f3b28faf0033dc2c4','7af12c1ebefcd8e53f6dbb4fac9592489acabd9d854ba067854c24e3c814d419');
INSERT INTO blocks VALUES(310074,'a00f647aa4b5d9142500fdc7da95b47c60c0affa3275cab56a875b1e082fa8037b3c32e6a002f92010c2d8bc1abaad10c2373fbd246b59e69af1e97df5c3a3f2',310074000,NULL,NULL,'3602625858b5c373aa4d0621e360229992aba34560ace9196e715f11d5ffb847','130214dde9816fb603108d7905580a520f65dbe29ec8cf60eecf8cb653a9e85d','57917df7d2d5c5716ea06d5bade4859a2206bdca2591dda7f0dc084c98b7103a');
INSERT INTO blocks VALUES(310075,'53035b827f91f83e75adef2f62607377fcffcd185902cb742a72d751e4d57e0432562fe92b0cc6f7221ecbe53ced6aea685ba2383dd9e2a78fce462778b75010',310075000,NULL,NULL,'2499d57c72c96236bcb0ba291978452dc63ae12270dc1198a0e84dc24de1d195','46713a3aee2a7399ac4332014e029aade79f03f59baf7b838de44849fb380c0d','eb63015aba80ab5d191e087043e0526edfb98361acc1eafd68653c3dc42b1314');
INSERT INTO blocks VALUES(310076,'98867155f362ec51c5d01c1ee81fec7c0fd5bf08892df7e78140ca21c443c084876793d528480ef54ea1e185fe435869dd7dd284119b92f4a3f63d05173a6580',310076000,NULL,NULL,'b040dbda159ed2f8feaa9053483d29bb3f0476ef19cb72e9c2a788be0f752412','d011383e8a386d183f5d3f1dc0869c3ac029ccb587a62839500c400b97ced75e','f6e9b8f12044aac8272f591a7c2e996f8adebed14bd748bca8f0e703105d75a4');
INSERT INTO blocks VALUES(310077,'2f9ac5c43c034f11cf28d62fb787f8c109662e4187b8af0d7dbd81b524f474ba9f4ab6bb6a36ce44003839ba82f7018065499543c9e3b4b1be0e96b9d56cd9d7',310077000,NULL,NULL,'c5d6e4cc522041d57f56dc6192fd64a15d304755bd71e455812052c417f8a002','297464b346cb542a6520dece0c7804edd53b3c40c0b631c16ac8637bb8a509aa','2a517cc88cd62951e259364c5e1b0966fa9bd11a862f67c2591f12076a4ee522');
INSERT INTO blocks VALUES(310078,'5e535d532426974fe1c45ebc463ec7a93fc3625a5da33119975481c4c98ec8ad81ab13fcb7e8943ae4fb26b41aeaa7ca0f50fa22d16c7d18e5deb3820e96df1e',310078000,NULL,NULL,'b952431ddfa1c9df32f48b0936d6246f4d9a02c3a861cf065948fb9d68626ca8','1888556f1f3f63a3a0cdb6d025d664be70bcb44e576f6dc17937e68ede2fd2fe','f2f77c73be3b16114c8b635e59c29659c28fab05a52535a0df587f9e9da17acc');
INSERT INTO blocks VALUES(310079,'e41a51db594c3e7919b4aac63e6100a092461b81518721da953a476986f5bf8e29085cfe6a08ec452fa547b704c4c4eca957ae193c27281dfa7f113a0f6df941',310079000,NULL,NULL,'8a34a1d84400d38e890e8edf57e6b9f2694a598eacfc8c4ea575ccc7748c78e4','463fa1ee6b50e7738a401e02d20c1a1e424aa3090377ae171f075eca57a7133f','9a803a02560edcde53b0472bb9693ddc3c8c8893057280be8e398e02abece352');
INSERT INTO blocks VALUES(310080,'fa67febda99884d857fb9bba17476225a600f76535a9431d21c261662434b85b9b4d4ce3cb591d043f80ebe0adaf9263e0a368d949d291e14778b46d07dabe91',310080000,NULL,NULL,'476452f452e1eda71b0b6615549823e1a6541394ff50e7531e8958e596526739','5bdd52851ed1eb4b410422b2aa9d33679d8f78846592e546ed250452d953601f','885ad091dea5b46a983f9a64279ffa574ce2c7ec2c1e213acf5cd642a805c195');
INSERT INTO blocks VALUES(310081,'98a5ce8fe941cef091735620c3119d97a382b9c80cc1764d1d30c94300037d0e519063378746b7edbfc60aa506fc04ebd539ada353534b7a5b3d621dec791da9',310081000,NULL,NULL,'188bdde66f82a719e3849d3f7c8c1a70250ff2c9b129dc07704db9abbe00b2bf','2031722da6c0c3355f55a2d5879538090b5cbf3a5dc466f1ffea2189ccb8480c','3a4db62a3acfa4bd2797460ffb3e8c3540ade11510574dc39d4ea67c457cada0');
INSERT INTO blocks VALUES(310082,'7702f9604bf3efed6578761f4c52de99779c7c42d7543774d425a4c3537befbd2e7181355f8a1130d3d8ad9ff3bbeaaca4e26cfaefff15e575ac4b2eb19b7051',310082000,NULL,NULL,'755c86f5f05e73620e1267c82f740eff72166d9324f4942ec026a6c7b20bd9d2','c323c2e5be1b80771d463be3bd219edb27c9d85a2ba089e2f38067c94a332689','fffe81d7fa3f238fe19190aa75b28c3ec8e2ff1435895a0a38efb1293780a6f6');
INSERT INTO blocks VALUES(310083,'f190eca1a75147eeec93cf96f106e346b908fc47e6a363093d5b229901bd58fb34fc8db82a8feb2d3dcbeac0c901ce98378f7e1dec0ff7aea7235c6d822a62b0',310083000,NULL,NULL,'16a5cb9e0061eaa1dbfa22cfe9962efd54b38174991b2c4abd4cfd16b86d1b42','24462b8ac2e185891cfdd504aadbcd2fc4306a15f0b975da1e908ea4bbe6a819','7f6ca26e0e1a8010a47c803625af3577f5d428b5161a62911899ecc96558fafc');
INSERT INTO blocks VALUES(310084,'d15e3c53c8bad6d8a4dcbb870b622505e4dabe8b3d3b7ffac8aa4976cdcefc91fc13c1c1a1700d7417e829310f9826fbc82307636fc3f95bcce561a8dd8f7ea0',310084000,NULL,NULL,'8653f7142e95518c34f1819dd4e75c8fac3c4397677fe9c9564af19a87e7cd1d','a6f2d08a7dc1a0269937dda1b60c955948d998a67b1678d3b392b8ee36470638','6f364fe7216e84ac28e12717d0f1627bfc39e152a188974e472439cc031cfd17');
INSERT INTO blocks VALUES(310085,'464aeb24455523d820981afe0f284487ec0a36b1388182f88388370811c394bc18686bfe2b8429f7d37569070f13e95952e877b7a84000c6c0e769e5e76cf437',310085000,NULL,NULL,'3c923cc5b8cfc39c3568e961b7a1eefa5c05b251ff00903cdfe404da677271bd','a5f365f0f2cefebea851fe5fdb44a6129711b0d86e909317eea7fda5bc94afbd','1261a5108a42e88abf65ec48780b3680c1bd45b6efab2cce5e70d32b395df19d');
INSERT INTO blocks VALUES(310086,'0c1d3e5b62d04ec82124010d58d052a0a2f9dfb71684580d0c5a8d37e286768f5eb4ce31dd4a677bbbf199d47ee843ec864deae51f4b2ca29d765015748b5742',310086000,NULL,NULL,'98701f364e8cd6cb05db7a13f03b55616c4dbffffb38e8294e7856fdec5a264b','3e51c899ccd1b8a2722f5f031a902659f7a2b016ae3d14a2e7514c205f1e4a47','a73b4ef29fb3c1d2902f42724fbe7ad187ec6e1069a1ce2c32406610e05dc719');
INSERT INTO blocks VALUES(310087,'799dd8fedf7036eca0b8298ac48c295690d12f9c71aa98727c927a6cb0224c62433ab878dff483f6d2754bde36f06fce594bdb06559c1d1a0a51848bfb395419',310087000,NULL,NULL,'f836a487b5dc8e5e5571a767485d99d9fa0a5f23e4a3f9033efaa3a384caea06','d06c5a3b7939a4cf7336cff76620577f7c3c4119cfd6592893c23cb2a30312ff','0329d103dc4fd5b7d9fde2d39458d19f75be80df3be7a9a1de3bd00298804bfa');
INSERT INTO blocks VALUES(310088,'8e1e809b86f3fbde2cabe6510052084ec68d7857c34f8dd334c99e8aeecf32ac1669f2789aa41acf3f33119c5d0aeafed03d8288765c178174a8db27887c22aa',310088000,NULL,NULL,'047cc2f08359e322054aa0c60ae320d9eb743df4df6c0fac169fb3deb35eb9a8','13c73ae61bd476f3cd3a722d12191ccf90cc291dbb354f4f7b5acc8d5b4ef9df','3c0ea60a91ebfe531ea52fbe9c71795aff11f74afa357214df83e1da638d57d7');
INSERT INTO blocks VALUES(310089,'9803c2ce201e643165ba86a8a739ec73a05f29d23237d8d2de56f46f417be665785871d0d36cd3146f999d0252635b9ae8a3dd86f597b1cb59cf6879e116b5be',310089000,NULL,NULL,'303363343196ac2329151c92c70b14354744cb427300a7414f8553418de88af1','bf82f3171ed5f1534cb804b5556609d4420971f900425f98e3f5674d607e1c8a','b2b8cefc039d76f8e61c4a20321f1c14fead7f0b3a06c01157458a2800365de5');
INSERT INTO blocks VALUES(310090,'1ea5f2b04b763909ad541951a0d21078be9d08e6bd7a23499ea69fa4ee8a67f02791404da26f6b64ed5bfc0bed66c28e4e98b703d7466f96311c5c838ab6d9c2',310090000,NULL,NULL,'3fc2fc4d1ce3e962e466a60acfa218af0429be1ebcea747493588a877bd1e2ec','845137e573bb7eabb65c6666837956b600a1f338fa887b770f3bd17c3c4be296','204f02a1b0ec642f837a855a286747ad38a3daafe6cc50a1c35fc8c635a4cb7f');
INSERT INTO blocks VALUES(310091,'09f4ee2e18880732c0ac4f58e012ff8fe9223899aeae5e051c9796439d98570637670e0cf50c0727e3017287f268466368c550fdbd3bd210387615af76c0a515',310091000,NULL,NULL,'f3dff7b24af79173642650dd140a1656b2ae6b99b8fd58375f489ccbae53762b','cceead4e16d1747ca2aba787c7841dc21b57c8afd8a20776384c6bfba620aa04','1f96b08f3d53470d48fb5cfcd7961327a5ee2f703ccb3a0cce17717bd44c2b47');
INSERT INTO blocks VALUES(310092,'ae270aca6bf2998680fd12abfdbd158ee5bfb8131fddbe54f5466c6f7a7ff114517a253f8756e13c2bde73e9b851ad2b24ce06bac2086ce3e240331bae518a2c',310092000,NULL,NULL,'d0d36d91c23cb77978e5d21b01311945dc1f51e40dc99933791fe42a9352349a','74369b5d201448e10ed628043aada9135a5485d485aa24a0945f38daa1853ade','19fb03b2b1b2d7da5ac29def6ae197c6f907bbe8e501e6d72c170377418331e1');
INSERT INTO blocks VALUES(310093,'2c950816e8a2e9c29fac064891a58465f30a62197864d549f856157c223a1f78f1e39f753e792f64b48c500d77e47602093941df590450d21da55758f81a659d',310093000,NULL,NULL,'827dbd7d20da585596cb987d94c9c8c813e885803a8a68b85e9f54f507da240b','82c5d19d4c230f3901a3f78d9a71c2207367dbf37b60c50bf15df7d3e74c4187','ddc353f487764fad9e421075d2c150ef800dbac3bd4fa4b2a4d5676db131b095');
INSERT INTO blocks VALUES(310094,'c7eda9512bcac5c3b73e17923afdce541011780a51f2f59338bd91f539b223655a64a2680972f32e340a268ee6dca4caf0ea6ed8ad02a3840e5ca7075c6cc69b',310094000,NULL,NULL,'21b0ea787a71311f4cd3be99bfa1b8a235f2bd8b70c179571cef72dae9b2b431','5d79b48f44c4b4d12a416e8200f2c7d8efaa416b42fe4da446f2dfc47b41a056','44f36a0625c622dcce3864dc5cefbeab94d3764dbb978f47cea65e2fc2734257');
INSERT INTO blocks VALUES(310095,'4ff3aa594932ca9e13370bd1a9fcaf0d07dcd6c28949afda5fff201a876e77331c483f93c8fc7295d3c8eb0d4ed3d4f53d062e17e87789392db93bec453cf1d2',310095000,NULL,NULL,'9451d54b90cc637b0c669f25f9fbe3facf2b35ff53b727e40d73be51054e0e34','9c387cb4bf45e5833250663de7b7454542d6345ee3004190cbd0f2d2fec95ae1','40d7732eefe1057dca708ea088f9b3cc7699af61e17d1f0557ab5f5ed5eb55f4');
INSERT INTO blocks VALUES(310096,'7f6ebf5b7e09d78febea9dce370ca98e1a00cd911b6ee8b4c1f46c3ee5e54754040ae2e5443d5e53ff2af3b615b08063111b4876e034ef31c9ec0f5e75695772',310096000,NULL,NULL,'8a43f6bedc2fc0078e92a5ff451f16f7e22f04e5bdf7e0cda33b25456a1c67e9','2c6713ab533230494a61af03c44002b2c85da2d005f6e55e67de61b7c26741e9','45979c0ed1f7dac5fe8388f931551dce423198d1a75ada4704dd67ab5c311c17');
INSERT INTO blocks VALUES(310097,'e44698e52e70ebb58d3d004f8eb4943aada1835e5ae673ae54f5a62231df0f0fc3a68ece57823e624b4f365ce199d50e35ec15619e508f8cbf71134d82facefb',310097000,NULL,NULL,'cbb1773323f97f27fe02109730ebaf9fc2c19d204465fe611f9c3ee53d908198','7f74302ba0f8d992ff09e325c710136ce4ed37bcf9dc2a3d4d07780e168ca9ac','1978a081d9a67d2a73dde3653fbe1a8eefce0f3325e23811eca80bd3f1958e13');
INSERT INTO blocks VALUES(310098,'031441b70e39a3d6dcf5a532eddb405d5abd8d723029ca8be3cfe400f0e4fb012a63d859e610eb48c7e41c4e80768e877321e92f8ff406e700d8c161e8a3f4d2',310098000,NULL,NULL,'ff5c427b12273e9d0866d6b92917526504d01f2493d3c6c4ec36fcc32b87b835','fc1bd8967a94859035f751a111b974d388fa974b3a7968e7a5b2f7a2261d0cfc','f856a7c9b2da234db3b87d642bb46b645647d52ca3c1d1612c3f936dc072cf9e');
INSERT INTO blocks VALUES(310099,'2456675ed07aaa79602718040e1f29e546938bec8a15b26492dbfd58d5388ea21ff3440ff29138f4e2cfb47662ea3e4e50476f7280c0e58b51b53bc08c014fc2',310099000,NULL,NULL,'a359867d060e4aebf415ac3b036c8b0cb1ce40ea888353c9dd5dce65c6aed62d','48a9cf25c242a1af648662e91534cf4780e32eeb1b72c3f70c1d61261a39925a','2fffb987b64c88745c6b8257c52c83d230b44d15505a966248baaa42fc033f93');
INSERT INTO blocks VALUES(310100,'b9b9a79de83063df4410925030cc3710aad6999f8ca9955305b477dda2e3777293c7ddd7c4eb6e9c3f2aec2e23e2415d0037dfcaf61a52b351ca564f2cf1556d',310100000,NULL,NULL,'d7abf16fde21874edd85e9ae0c8dc757bbc70ce373f3441c621a392c5ace15d6','156a16ea8797efc96736d2e9d15b886e37c59dc149414075d48db8041299fc2e','e2843611a89ddc2cc8e7c252b7a2a9455f76578871da00f5f6ea5262b50e7417');
INSERT INTO blocks VALUES(310101,'e8a8ebd85a460cf5987683360a1c77e6728b4e59027220f8eceda05c720bc38c91f6193bc43739da026cd28f340e1a10b9900bfa3eed11f88339147c61b65504',310101000,NULL,NULL,'afa2d315906400fd733496c02fa0ef5fb0ab58cfb479991089f6072d223575b5','3c5f1ef57653650ee2c56ca8e74491cf0f7d8e8c56aa6ca7ac9c554471e398c1','68dd243f257406887df54dc8675181c05b10c9749a45bf7ab77f0fe6d78f8a88');
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
INSERT INTO broadcasts VALUES(12,'7da765a612160e2ecacad56ff32acd28faa11e7a4974f6d6c5d9e5a54955a816',310011,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1388000000,100.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(19,'26124f23215b3cd695728ce8a0da20b6a5e397b308d5e59882f8fc0c541de4d4',310018,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1388000050,99.86166,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(20,'c8e3bfcc53f8cae8c5ae3099ef8dab163c487e902f02fbf6feb0a004af0c1e89',310019,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1388000101,100.343,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(21,'0dd4ea49a1f58f4a9cad0d85e97324880bb10cf59651ee2eb04a282d9ebe46eb',310020,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1388000201,2.0,5000000,'Unit Test',0,'valid');
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
INSERT INTO btcpays VALUES(5,'0becc70a783b2f5e985ee0fca248152608cae01aa3400cb64f0b31a745b5221c',310004,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',50000000,'21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7_dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643','valid');
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
INSERT INTO burns VALUES(1,'baf568fd33ac5ee3efa137cd8f9a030a339889a96834134f9e99815447d2c2f6',310000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',62000000,93000000000,'valid');
INSERT INTO burns VALUES(23,'702e60afb8f29d914c6d06d44f1e15be1d872c73d0796fe9d29dd5c45b31a5c4',310022,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',38000000,56999887262,'valid');
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
                      tx_index INTEGER UNIQUE,
                      tx_hash TEXT UNIQUE,
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
INSERT INTO credits VALUES(310000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',93000000000,'burn','baf568fd33ac5ee3efa137cd8f9a030a339889a96834134f9e99815447d2c2f6');
INSERT INTO credits VALUES(310001,'2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',50000000,'send','d18296c6a110057ced7671a1a23faadf5deeba8088157367a1de49637f273673');
INSERT INTO credits VALUES(310004,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',100000000,'btcpay','0becc70a783b2f5e985ee0fca248152608cae01aa3400cb64f0b31a745b5221c');
INSERT INTO credits VALUES(310005,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB',1000000000,'issuance','097b59f4e505d7d5013b9656106223be410d094b06f8d8d20774e70b1e70ed70');
INSERT INTO credits VALUES(310006,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',100000,'issuance','543a14fb8742b89677d7109b7b7e7ae2907482718d7658ba59bb99f3b9c07ae2');
INSERT INTO credits VALUES(310007,'2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB',4000000,'send','c0126dbca92db91189f931c8cf6e82a2fa6498b4dedefdabaeb7ac4c4a4598a3');
INSERT INTO credits VALUES(310008,'2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',526,'send','0d1d40de06a2f09339b68f6e2ee973f07b44530b2ec95012be248439bfbcf8ab');
INSERT INTO credits VALUES(310009,'2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',24,'dividend','606a0e1142b6dc559439d3a7a760ecd1e30fea5b8cd2fa08c9af89117809d41f');
INSERT INTO credits VALUES(310010,'2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',420800,'dividend','09fc25f258bd33ae01db6e823c084de00790dd74ef89b964e7f3432bff0f83fb');
INSERT INTO credits VALUES(310013,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',4250000,'filled','f0d2a7c5d14e94a67b9917282b3d7198535e444a5d3c1d2b84260aea2ce5d48b');
INSERT INTO credits VALUES(310014,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',5000000,'cancel order','dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643');
INSERT INTO credits VALUES(310015,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',0,'filled','07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f');
INSERT INTO credits VALUES(310015,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',0,'filled','07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f');
INSERT INTO credits VALUES(310017,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',0,'filled','ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5');
INSERT INTO credits VALUES(310017,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',0,'filled','ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5');
INSERT INTO credits VALUES(310018,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',59137500,'bet settled: liquidated for bear','26124f23215b3cd695728ce8a0da20b6a5e397b308d5e59882f8fc0c541de4d4');
INSERT INTO credits VALUES(310018,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',3112500,'feed fee','26124f23215b3cd695728ce8a0da20b6a5e397b308d5e59882f8fc0c541de4d4');
INSERT INTO credits VALUES(310019,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',159300000,'bet settled','c8e3bfcc53f8cae8c5ae3099ef8dab163c487e902f02fbf6feb0a004af0c1e89');
INSERT INTO credits VALUES(310019,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',315700000,'bet settled','c8e3bfcc53f8cae8c5ae3099ef8dab163c487e902f02fbf6feb0a004af0c1e89');
INSERT INTO credits VALUES(310019,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',25000000,'feed fee','c8e3bfcc53f8cae8c5ae3099ef8dab163c487e902f02fbf6feb0a004af0c1e89');
INSERT INTO credits VALUES(310020,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',1330000000,'bet settled: for notequal','0dd4ea49a1f58f4a9cad0d85e97324880bb10cf59651ee2eb04a282d9ebe46eb');
INSERT INTO credits VALUES(310020,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',70000000,'feed fee','0dd4ea49a1f58f4a9cad0d85e97324880bb10cf59651ee2eb04a282d9ebe46eb');
INSERT INTO credits VALUES(310022,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',56999887262,'burn','702e60afb8f29d914c6d06d44f1e15be1d872c73d0796fe9d29dd5c45b31a5c4');
INSERT INTO credits VALUES(310023,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',8500000,'recredit wager remaining','6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1');
INSERT INTO credits VALUES(310023,'2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',10000,'send','80a30ebcb3366a99961ce3f1f20ce3a66252cb534158154776832d6dac72174b');
INSERT INTO credits VALUES(310032,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB',50000000,'cancel order','c5e46cd93c5e2236f8cee219d3c00c7af0f7c883428500a247095e7ce73da951');
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
INSERT INTO debits VALUES(310001,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',50000000,'send','d18296c6a110057ced7671a1a23faadf5deeba8088157367a1de49637f273673');
INSERT INTO debits VALUES(310003,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',105000000,'open order','dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643');
INSERT INTO debits VALUES(310005,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',50000000,'issuance fee','097b59f4e505d7d5013b9656106223be410d094b06f8d8d20774e70b1e70ed70');
INSERT INTO debits VALUES(310006,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',50000000,'issuance fee','543a14fb8742b89677d7109b7b7e7ae2907482718d7658ba59bb99f3b9c07ae2');
INSERT INTO debits VALUES(310007,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB',4000000,'send','c0126dbca92db91189f931c8cf6e82a2fa6498b4dedefdabaeb7ac4c4a4598a3');
INSERT INTO debits VALUES(310008,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',526,'send','0d1d40de06a2f09339b68f6e2ee973f07b44530b2ec95012be248439bfbcf8ab');
INSERT INTO debits VALUES(310009,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',24,'dividend','606a0e1142b6dc559439d3a7a760ecd1e30fea5b8cd2fa08c9af89117809d41f');
INSERT INTO debits VALUES(310009,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',20000,'dividend fee','606a0e1142b6dc559439d3a7a760ecd1e30fea5b8cd2fa08c9af89117809d41f');
INSERT INTO debits VALUES(310010,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',420800,'dividend','09fc25f258bd33ae01db6e823c084de00790dd74ef89b964e7f3432bff0f83fb');
INSERT INTO debits VALUES(310010,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',20000,'dividend fee','09fc25f258bd33ae01db6e823c084de00790dd74ef89b964e7f3432bff0f83fb');
INSERT INTO debits VALUES(310012,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',50000000,'bet','6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1');
INSERT INTO debits VALUES(310013,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',25000000,'bet','f0d2a7c5d14e94a67b9917282b3d7198535e444a5d3c1d2b84260aea2ce5d48b');
INSERT INTO debits VALUES(310014,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',150000000,'bet','a7049b5fa97a608a0b3de5d169a12b8a585e94e038ab89852c630744e9b60f36');
INSERT INTO debits VALUES(310015,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',350000000,'bet','07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f');
INSERT INTO debits VALUES(310016,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',750000000,'bet','f7463c39fdcf70265fc7e3e1e8418086c6cf3cead714121fdb19f240f47c4868');
INSERT INTO debits VALUES(310017,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',650000000,'bet','ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5');
INSERT INTO debits VALUES(310021,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB',50000000,'open order','c5e46cd93c5e2236f8cee219d3c00c7af0f7c883428500a247095e7ce73da951');
INSERT INTO debits VALUES(310023,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',10000,'send','80a30ebcb3366a99961ce3f1f20ce3a66252cb534158154776832d6dac72174b');
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
INSERT INTO dividends VALUES(10,'606a0e1142b6dc559439d3a7a760ecd1e30fea5b8cd2fa08c9af89117809d41f',310009,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB','XCP',600,20000,'valid');
INSERT INTO dividends VALUES(11,'09fc25f258bd33ae01db6e823c084de00790dd74ef89b964e7f3432bff0f83fb',310010,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC','XCP',800,20000,'valid');
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
INSERT INTO issuances VALUES(6,'097b59f4e505d7d5013b9656106223be410d094b06f8d8d20774e70b1e70ed70',310005,'BBBB',1000000000,1,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',0,0,0,0.0,'',50000000,0,'valid');
INSERT INTO issuances VALUES(7,'543a14fb8742b89677d7109b7b7e7ae2907482718d7658ba59bb99f3b9c07ae2',310006,'BBBC',100000,0,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',0,0,0,0.0,'foobar',50000000,0,'valid');
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
INSERT INTO messages VALUES(0,310000,'insert','credits','{"action": "burn", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310000, "event": "baf568fd33ac5ee3efa137cd8f9a030a339889a96834134f9e99815447d2c2f6", "quantity": 93000000000}',0);
INSERT INTO messages VALUES(1,310000,'insert','burns','{"block_index": 310000, "burned": 62000000, "earned": 93000000000, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "valid", "tx_hash": "baf568fd33ac5ee3efa137cd8f9a030a339889a96834134f9e99815447d2c2f6", "tx_index": 1}',0);
INSERT INTO messages VALUES(2,310001,'insert','debits','{"action": "send", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310001, "event": "d18296c6a110057ced7671a1a23faadf5deeba8088157367a1de49637f273673", "quantity": 50000000}',0);
INSERT INTO messages VALUES(3,310001,'insert','credits','{"action": "send", "address": "2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310001, "event": "d18296c6a110057ced7671a1a23faadf5deeba8088157367a1de49637f273673", "quantity": 50000000}',0);
INSERT INTO messages VALUES(4,310001,'insert','sends','{"asset": "XCP", "block_index": 310001, "destination": "2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "quantity": 50000000, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "valid", "tx_hash": "d18296c6a110057ced7671a1a23faadf5deeba8088157367a1de49637f273673", "tx_index": 2}',0);
INSERT INTO messages VALUES(5,310002,'insert','orders','{"block_index": 310002, "expiration": 10, "expire_index": 310012, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 50000000, "give_remaining": 50000000, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "open", "tx_hash": "21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7", "tx_index": 3}',0);
INSERT INTO messages VALUES(6,310003,'insert','debits','{"action": "open order", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310003, "event": "dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643", "quantity": 105000000}',0);
INSERT INTO messages VALUES(7,310003,'insert','orders','{"block_index": 310003, "expiration": 10, "expire_index": 310013, "fee_provided": 10000, "fee_provided_remaining": 10000, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 50000000, "get_remaining": 50000000, "give_asset": "XCP", "give_quantity": 105000000, "give_remaining": 105000000, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "open", "tx_hash": "dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643", "tx_index": 4}',0);
INSERT INTO messages VALUES(8,310003,'update','orders','{"fee_provided_remaining": 142858, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7"}',0);
INSERT INTO messages VALUES(9,310003,'update','orders','{"fee_provided_remaining": 10000, "fee_required_remaining": 42858, "get_remaining": 0, "give_remaining": 5000000, "status": "open", "tx_hash": "dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643"}',0);
INSERT INTO messages VALUES(10,310003,'insert','order_matches','{"backward_asset": "XCP", "backward_quantity": 100000000, "block_index": 310003, "fee_paid": 857142, "forward_asset": "BTC", "forward_quantity": 50000000, "id": "21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7_dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643", "match_expire_index": 310023, "status": "pending", "tx0_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "tx0_block_index": 310002, "tx0_expiration": 10, "tx0_hash": "21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7", "tx0_index": 3, "tx1_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "tx1_block_index": 310003, "tx1_expiration": 10, "tx1_hash": "dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643", "tx1_index": 4}',0);
INSERT INTO messages VALUES(11,310004,'insert','credits','{"action": "btcpay", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310004, "event": "0becc70a783b2f5e985ee0fca248152608cae01aa3400cb64f0b31a745b5221c", "quantity": 100000000}',0);
INSERT INTO messages VALUES(12,310004,'update','order_matches','{"order_match_id": "21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7_dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643", "status": "completed"}',0);
INSERT INTO messages VALUES(13,310004,'insert','btcpays','{"block_index": 310004, "btc_amount": 50000000, "destination": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "order_match_id": "21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7_dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643", "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "valid", "tx_hash": "0becc70a783b2f5e985ee0fca248152608cae01aa3400cb64f0b31a745b5221c", "tx_index": 5}',0);
INSERT INTO messages VALUES(14,310005,'insert','debits','{"action": "issuance fee", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310005, "event": "097b59f4e505d7d5013b9656106223be410d094b06f8d8d20774e70b1e70ed70", "quantity": 50000000}',0);
INSERT INTO messages VALUES(15,310005,'insert','issuances','{"asset": "BBBB", "block_index": 310005, "call_date": 0, "call_price": 0.0, "callable": false, "description": "", "divisible": true, "fee_paid": 50000000, "issuer": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "locked": false, "quantity": 1000000000, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "valid", "transfer": false, "tx_hash": "097b59f4e505d7d5013b9656106223be410d094b06f8d8d20774e70b1e70ed70", "tx_index": 6}',0);
INSERT INTO messages VALUES(16,310005,'insert','credits','{"action": "issuance", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "BBBB", "block_index": 310005, "event": "097b59f4e505d7d5013b9656106223be410d094b06f8d8d20774e70b1e70ed70", "quantity": 1000000000}',0);
INSERT INTO messages VALUES(17,310006,'insert','debits','{"action": "issuance fee", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310006, "event": "543a14fb8742b89677d7109b7b7e7ae2907482718d7658ba59bb99f3b9c07ae2", "quantity": 50000000}',0);
INSERT INTO messages VALUES(18,310006,'insert','issuances','{"asset": "BBBC", "block_index": 310006, "call_date": 0, "call_price": 0.0, "callable": false, "description": "foobar", "divisible": false, "fee_paid": 50000000, "issuer": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "locked": false, "quantity": 100000, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "valid", "transfer": false, "tx_hash": "543a14fb8742b89677d7109b7b7e7ae2907482718d7658ba59bb99f3b9c07ae2", "tx_index": 7}',0);
INSERT INTO messages VALUES(19,310006,'insert','credits','{"action": "issuance", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "BBBC", "block_index": 310006, "event": "543a14fb8742b89677d7109b7b7e7ae2907482718d7658ba59bb99f3b9c07ae2", "quantity": 100000}',0);
INSERT INTO messages VALUES(20,310007,'insert','debits','{"action": "send", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "BBBB", "block_index": 310007, "event": "c0126dbca92db91189f931c8cf6e82a2fa6498b4dedefdabaeb7ac4c4a4598a3", "quantity": 4000000}',0);
INSERT INTO messages VALUES(21,310007,'insert','credits','{"action": "send", "address": "2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "BBBB", "block_index": 310007, "event": "c0126dbca92db91189f931c8cf6e82a2fa6498b4dedefdabaeb7ac4c4a4598a3", "quantity": 4000000}',0);
INSERT INTO messages VALUES(22,310007,'insert','sends','{"asset": "BBBB", "block_index": 310007, "destination": "2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "quantity": 4000000, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "valid", "tx_hash": "c0126dbca92db91189f931c8cf6e82a2fa6498b4dedefdabaeb7ac4c4a4598a3", "tx_index": 8}',0);
INSERT INTO messages VALUES(23,310008,'insert','debits','{"action": "send", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "BBBC", "block_index": 310008, "event": "0d1d40de06a2f09339b68f6e2ee973f07b44530b2ec95012be248439bfbcf8ab", "quantity": 526}',0);
INSERT INTO messages VALUES(24,310008,'insert','credits','{"action": "send", "address": "2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "BBBC", "block_index": 310008, "event": "0d1d40de06a2f09339b68f6e2ee973f07b44530b2ec95012be248439bfbcf8ab", "quantity": 526}',0);
INSERT INTO messages VALUES(25,310008,'insert','sends','{"asset": "BBBC", "block_index": 310008, "destination": "2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "quantity": 526, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "valid", "tx_hash": "0d1d40de06a2f09339b68f6e2ee973f07b44530b2ec95012be248439bfbcf8ab", "tx_index": 9}',0);
INSERT INTO messages VALUES(26,310009,'insert','debits','{"action": "dividend", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310009, "event": "606a0e1142b6dc559439d3a7a760ecd1e30fea5b8cd2fa08c9af89117809d41f", "quantity": 24}',0);
INSERT INTO messages VALUES(27,310009,'insert','debits','{"action": "dividend fee", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310009, "event": "606a0e1142b6dc559439d3a7a760ecd1e30fea5b8cd2fa08c9af89117809d41f", "quantity": 20000}',0);
INSERT INTO messages VALUES(28,310009,'insert','credits','{"action": "dividend", "address": "2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310009, "event": "606a0e1142b6dc559439d3a7a760ecd1e30fea5b8cd2fa08c9af89117809d41f", "quantity": 24}',0);
INSERT INTO messages VALUES(29,310009,'insert','dividends','{"asset": "BBBB", "block_index": 310009, "dividend_asset": "XCP", "fee_paid": 20000, "quantity_per_unit": 600, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "valid", "tx_hash": "606a0e1142b6dc559439d3a7a760ecd1e30fea5b8cd2fa08c9af89117809d41f", "tx_index": 10}',0);
INSERT INTO messages VALUES(30,310010,'insert','debits','{"action": "dividend", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310010, "event": "09fc25f258bd33ae01db6e823c084de00790dd74ef89b964e7f3432bff0f83fb", "quantity": 420800}',0);
INSERT INTO messages VALUES(31,310010,'insert','debits','{"action": "dividend fee", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310010, "event": "09fc25f258bd33ae01db6e823c084de00790dd74ef89b964e7f3432bff0f83fb", "quantity": 20000}',0);
INSERT INTO messages VALUES(32,310010,'insert','credits','{"action": "dividend", "address": "2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310010, "event": "09fc25f258bd33ae01db6e823c084de00790dd74ef89b964e7f3432bff0f83fb", "quantity": 420800}',0);
INSERT INTO messages VALUES(33,310010,'insert','dividends','{"asset": "BBBC", "block_index": 310010, "dividend_asset": "XCP", "fee_paid": 20000, "quantity_per_unit": 800, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "valid", "tx_hash": "09fc25f258bd33ae01db6e823c084de00790dd74ef89b964e7f3432bff0f83fb", "tx_index": 11}',0);
INSERT INTO messages VALUES(34,310011,'insert','broadcasts','{"block_index": 310011, "fee_fraction_int": 5000000, "locked": false, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "7da765a612160e2ecacad56ff32acd28faa11e7a4974f6d6c5d9e5a54955a816", "tx_index": 12, "value": 100.0}',0);
INSERT INTO messages VALUES(35,310012,'insert','debits','{"action": "bet", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310012, "event": "6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1", "quantity": 50000000}',0);
INSERT INTO messages VALUES(36,310012,'insert','bets','{"bet_type": 0, "block_index": 310012, "counterwager_quantity": 25000000, "counterwager_remaining": 25000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310022, "fee_fraction_int": 5000000.0, "feed_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "leverage": 15120, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "open", "target_value": 0.0, "tx_hash": "6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1", "tx_index": 13, "wager_quantity": 50000000, "wager_remaining": 50000000}',0);
INSERT INTO messages VALUES(37,310013,'update','orders','{"status": "expired", "tx_hash": "21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7"}',0);
INSERT INTO messages VALUES(38,310013,'insert','order_expirations','{"block_index": 310013, "order_hash": "21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7", "order_index": 3, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2"}',0);
INSERT INTO messages VALUES(39,310013,'insert','debits','{"action": "bet", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310013, "event": "f0d2a7c5d14e94a67b9917282b3d7198535e444a5d3c1d2b84260aea2ce5d48b", "quantity": 25000000}',0);
INSERT INTO messages VALUES(40,310013,'insert','bets','{"bet_type": 1, "block_index": 310013, "counterwager_quantity": 41500000, "counterwager_remaining": 41500000, "deadline": 1388000100, "expiration": 10, "expire_index": 310023, "fee_fraction_int": 5000000.0, "feed_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "leverage": 15120, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "open", "target_value": 0.0, "tx_hash": "f0d2a7c5d14e94a67b9917282b3d7198535e444a5d3c1d2b84260aea2ce5d48b", "tx_index": 14, "wager_quantity": 25000000, "wager_remaining": 25000000}',0);
INSERT INTO messages VALUES(41,310013,'update','bets','{"counterwager_remaining": 4250000, "status": "open", "tx_hash": "6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1", "wager_remaining": 8500000}',0);
INSERT INTO messages VALUES(42,310013,'insert','credits','{"action": "filled", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310013, "event": "f0d2a7c5d14e94a67b9917282b3d7198535e444a5d3c1d2b84260aea2ce5d48b", "quantity": 4250000}',0);
INSERT INTO messages VALUES(43,310013,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "f0d2a7c5d14e94a67b9917282b3d7198535e444a5d3c1d2b84260aea2ce5d48b", "wager_remaining": 4250000}',0);
INSERT INTO messages VALUES(44,310013,'insert','bet_matches','{"backward_quantity": 20750000, "block_index": 310013, "deadline": 1388000100, "fee_fraction_int": 5000000, "feed_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "forward_quantity": 41500000, "id": "6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1_f0d2a7c5d14e94a67b9917282b3d7198535e444a5d3c1d2b84260aea2ce5d48b", "initial_value": 100.0, "leverage": 15120, "match_expire_index": 310022, "status": "pending", "target_value": 0.0, "tx0_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "tx0_bet_type": 0, "tx0_block_index": 310012, "tx0_expiration": 10, "tx0_hash": "6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1", "tx0_index": 13, "tx1_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "tx1_bet_type": 1, "tx1_block_index": 310013, "tx1_expiration": 10, "tx1_hash": "f0d2a7c5d14e94a67b9917282b3d7198535e444a5d3c1d2b84260aea2ce5d48b", "tx1_index": 14}',0);
INSERT INTO messages VALUES(45,310014,'update','orders','{"status": "expired", "tx_hash": "dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643"}',0);
INSERT INTO messages VALUES(46,310014,'insert','credits','{"action": "cancel order", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310014, "event": "dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643", "quantity": 5000000}',0);
INSERT INTO messages VALUES(47,310014,'insert','order_expirations','{"block_index": 310014, "order_hash": "dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643", "order_index": 4, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2"}',0);
INSERT INTO messages VALUES(48,310014,'insert','debits','{"action": "bet", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310014, "event": "a7049b5fa97a608a0b3de5d169a12b8a585e94e038ab89852c630744e9b60f36", "quantity": 150000000}',0);
INSERT INTO messages VALUES(49,310014,'insert','bets','{"bet_type": 0, "block_index": 310014, "counterwager_quantity": 350000000, "counterwager_remaining": 350000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310024, "fee_fraction_int": 5000000.0, "feed_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "leverage": 5040, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "open", "target_value": 0.0, "tx_hash": "a7049b5fa97a608a0b3de5d169a12b8a585e94e038ab89852c630744e9b60f36", "tx_index": 15, "wager_quantity": 150000000, "wager_remaining": 150000000}',0);
INSERT INTO messages VALUES(50,310015,'insert','debits','{"action": "bet", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310015, "event": "07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f", "quantity": 350000000}',0);
INSERT INTO messages VALUES(51,310015,'insert','bets','{"bet_type": 1, "block_index": 310015, "counterwager_quantity": 150000000, "counterwager_remaining": 150000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310025, "fee_fraction_int": 5000000.0, "feed_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "leverage": 5040, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "open", "target_value": 0.0, "tx_hash": "07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f", "tx_index": 16, "wager_quantity": 350000000, "wager_remaining": 350000000}',0);
INSERT INTO messages VALUES(52,310015,'insert','credits','{"action": "filled", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310015, "event": "07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f", "quantity": 0}',0);
INSERT INTO messages VALUES(53,310015,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "a7049b5fa97a608a0b3de5d169a12b8a585e94e038ab89852c630744e9b60f36", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(54,310015,'insert','credits','{"action": "filled", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310015, "event": "07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f", "quantity": 0}',0);
INSERT INTO messages VALUES(55,310015,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(56,310015,'insert','bet_matches','{"backward_quantity": 350000000, "block_index": 310015, "deadline": 1388000100, "fee_fraction_int": 5000000, "feed_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "forward_quantity": 150000000, "id": "a7049b5fa97a608a0b3de5d169a12b8a585e94e038ab89852c630744e9b60f36_07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f", "initial_value": 100.0, "leverage": 5040, "match_expire_index": 310024, "status": "pending", "target_value": 0.0, "tx0_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "tx0_bet_type": 0, "tx0_block_index": 310014, "tx0_expiration": 10, "tx0_hash": "a7049b5fa97a608a0b3de5d169a12b8a585e94e038ab89852c630744e9b60f36", "tx0_index": 15, "tx1_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "tx1_bet_type": 1, "tx1_block_index": 310015, "tx1_expiration": 10, "tx1_hash": "07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f", "tx1_index": 16}',0);
INSERT INTO messages VALUES(57,310016,'insert','debits','{"action": "bet", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310016, "event": "f7463c39fdcf70265fc7e3e1e8418086c6cf3cead714121fdb19f240f47c4868", "quantity": 750000000}',0);
INSERT INTO messages VALUES(58,310016,'insert','bets','{"bet_type": 2, "block_index": 310016, "counterwager_quantity": 650000000, "counterwager_remaining": 650000000, "deadline": 1388000200, "expiration": 10, "expire_index": 310026, "fee_fraction_int": 5000000.0, "feed_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "leverage": 5040, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "open", "target_value": 1.0, "tx_hash": "f7463c39fdcf70265fc7e3e1e8418086c6cf3cead714121fdb19f240f47c4868", "tx_index": 17, "wager_quantity": 750000000, "wager_remaining": 750000000}',0);
INSERT INTO messages VALUES(59,310017,'insert','debits','{"action": "bet", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310017, "event": "ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5", "quantity": 650000000}',0);
INSERT INTO messages VALUES(60,310017,'insert','bets','{"bet_type": 3, "block_index": 310017, "counterwager_quantity": 750000000, "counterwager_remaining": 750000000, "deadline": 1388000200, "expiration": 10, "expire_index": 310027, "fee_fraction_int": 5000000.0, "feed_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "leverage": 5040, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "open", "target_value": 1.0, "tx_hash": "ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5", "tx_index": 18, "wager_quantity": 650000000, "wager_remaining": 650000000}',0);
INSERT INTO messages VALUES(61,310017,'insert','credits','{"action": "filled", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310017, "event": "ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5", "quantity": 0}',0);
INSERT INTO messages VALUES(62,310017,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "f7463c39fdcf70265fc7e3e1e8418086c6cf3cead714121fdb19f240f47c4868", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(63,310017,'insert','credits','{"action": "filled", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310017, "event": "ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5", "quantity": 0}',0);
INSERT INTO messages VALUES(64,310017,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(65,310017,'insert','bet_matches','{"backward_quantity": 650000000, "block_index": 310017, "deadline": 1388000200, "fee_fraction_int": 5000000, "feed_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "forward_quantity": 750000000, "id": "f7463c39fdcf70265fc7e3e1e8418086c6cf3cead714121fdb19f240f47c4868_ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5", "initial_value": 100.0, "leverage": 5040, "match_expire_index": 310026, "status": "pending", "target_value": 1.0, "tx0_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "tx0_bet_type": 2, "tx0_block_index": 310016, "tx0_expiration": 10, "tx0_hash": "f7463c39fdcf70265fc7e3e1e8418086c6cf3cead714121fdb19f240f47c4868", "tx0_index": 17, "tx1_address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "tx1_bet_type": 3, "tx1_block_index": 310017, "tx1_expiration": 10, "tx1_hash": "ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5", "tx1_index": 18}',0);
INSERT INTO messages VALUES(66,310018,'insert','broadcasts','{"block_index": 310018, "fee_fraction_int": 5000000, "locked": false, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "valid", "text": "Unit Test", "timestamp": 1388000050, "tx_hash": "26124f23215b3cd695728ce8a0da20b6a5e397b308d5e59882f8fc0c541de4d4", "tx_index": 19, "value": 99.86166}',0);
INSERT INTO messages VALUES(67,310018,'insert','credits','{"action": "bet settled: liquidated for bear", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310018, "event": "26124f23215b3cd695728ce8a0da20b6a5e397b308d5e59882f8fc0c541de4d4", "quantity": 59137500}',0);
INSERT INTO messages VALUES(68,310018,'insert','credits','{"action": "feed fee", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310018, "event": "26124f23215b3cd695728ce8a0da20b6a5e397b308d5e59882f8fc0c541de4d4", "quantity": 3112500}',0);
INSERT INTO messages VALUES(69,310018,'insert','bet_match_resolutions','{"bear_credit": 59137500, "bet_match_id": "6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1_f0d2a7c5d14e94a67b9917282b3d7198535e444a5d3c1d2b84260aea2ce5d48b", "bet_match_type_id": 1, "block_index": 310018, "bull_credit": 0, "escrow_less_fee": null, "fee": 3112500, "settled": false, "winner": null}',0);
INSERT INTO messages VALUES(70,310018,'update','bet_matches','{"bet_match_id": "6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1_f0d2a7c5d14e94a67b9917282b3d7198535e444a5d3c1d2b84260aea2ce5d48b", "status": "settled: liquidated for bear"}',0);
INSERT INTO messages VALUES(71,310019,'insert','broadcasts','{"block_index": 310019, "fee_fraction_int": 5000000, "locked": false, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "valid", "text": "Unit Test", "timestamp": 1388000101, "tx_hash": "c8e3bfcc53f8cae8c5ae3099ef8dab163c487e902f02fbf6feb0a004af0c1e89", "tx_index": 20, "value": 100.343}',0);
INSERT INTO messages VALUES(72,310019,'insert','credits','{"action": "bet settled", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310019, "event": "c8e3bfcc53f8cae8c5ae3099ef8dab163c487e902f02fbf6feb0a004af0c1e89", "quantity": 159300000}',0);
INSERT INTO messages VALUES(73,310019,'insert','credits','{"action": "bet settled", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310019, "event": "c8e3bfcc53f8cae8c5ae3099ef8dab163c487e902f02fbf6feb0a004af0c1e89", "quantity": 315700000}',0);
INSERT INTO messages VALUES(74,310019,'insert','credits','{"action": "feed fee", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310019, "event": "c8e3bfcc53f8cae8c5ae3099ef8dab163c487e902f02fbf6feb0a004af0c1e89", "quantity": 25000000}',0);
INSERT INTO messages VALUES(75,310019,'insert','bet_match_resolutions','{"bear_credit": 315700000, "bet_match_id": "a7049b5fa97a608a0b3de5d169a12b8a585e94e038ab89852c630744e9b60f36_07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f", "bet_match_type_id": 1, "block_index": 310019, "bull_credit": 159300000, "escrow_less_fee": null, "fee": 25000000, "settled": true, "winner": null}',0);
INSERT INTO messages VALUES(76,310019,'update','bet_matches','{"bet_match_id": "a7049b5fa97a608a0b3de5d169a12b8a585e94e038ab89852c630744e9b60f36_07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f", "status": "settled"}',0);
INSERT INTO messages VALUES(77,310020,'insert','broadcasts','{"block_index": 310020, "fee_fraction_int": 5000000, "locked": false, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "valid", "text": "Unit Test", "timestamp": 1388000201, "tx_hash": "0dd4ea49a1f58f4a9cad0d85e97324880bb10cf59651ee2eb04a282d9ebe46eb", "tx_index": 21, "value": 2.0}',0);
INSERT INTO messages VALUES(78,310020,'insert','credits','{"action": "bet settled: for notequal", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310020, "event": "0dd4ea49a1f58f4a9cad0d85e97324880bb10cf59651ee2eb04a282d9ebe46eb", "quantity": 1330000000}',0);
INSERT INTO messages VALUES(79,310020,'insert','credits','{"action": "feed fee", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310020, "event": "0dd4ea49a1f58f4a9cad0d85e97324880bb10cf59651ee2eb04a282d9ebe46eb", "quantity": 70000000}',0);
INSERT INTO messages VALUES(80,310020,'insert','bet_match_resolutions','{"bear_credit": null, "bet_match_id": "f7463c39fdcf70265fc7e3e1e8418086c6cf3cead714121fdb19f240f47c4868_ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5", "bet_match_type_id": 5, "block_index": 310020, "bull_credit": null, "escrow_less_fee": 1330000000, "fee": 70000000, "settled": null, "winner": "NotEqual"}',0);
INSERT INTO messages VALUES(81,310020,'update','bet_matches','{"bet_match_id": "f7463c39fdcf70265fc7e3e1e8418086c6cf3cead714121fdb19f240f47c4868_ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5", "status": "settled: for notequal"}',0);
INSERT INTO messages VALUES(82,310021,'insert','debits','{"action": "open order", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "BBBB", "block_index": 310021, "event": "c5e46cd93c5e2236f8cee219d3c00c7af0f7c883428500a247095e7ce73da951", "quantity": 50000000}',0);
INSERT INTO messages VALUES(83,310021,'insert','orders','{"block_index": 310021, "expiration": 10, "expire_index": 310031, "fee_provided": 10000, "fee_provided_remaining": 10000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 50000000, "get_remaining": 50000000, "give_asset": "BBBB", "give_quantity": 50000000, "give_remaining": 50000000, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "open", "tx_hash": "c5e46cd93c5e2236f8cee219d3c00c7af0f7c883428500a247095e7ce73da951", "tx_index": 22}',0);
INSERT INTO messages VALUES(84,310022,'insert','credits','{"action": "burn", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310022, "event": "702e60afb8f29d914c6d06d44f1e15be1d872c73d0796fe9d29dd5c45b31a5c4", "quantity": 56999887262}',0);
INSERT INTO messages VALUES(85,310022,'insert','burns','{"block_index": 310022, "burned": 38000000, "earned": 56999887262, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "valid", "tx_hash": "702e60afb8f29d914c6d06d44f1e15be1d872c73d0796fe9d29dd5c45b31a5c4", "tx_index": 23}',0);
INSERT INTO messages VALUES(86,310023,'update','bets','{"status": "expired", "tx_hash": "6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1"}',0);
INSERT INTO messages VALUES(87,310023,'insert','credits','{"action": "recredit wager remaining", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310023, "event": "6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1", "quantity": 8500000}',0);
INSERT INTO messages VALUES(88,310023,'insert','bet_expirations','{"bet_hash": "6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1", "bet_index": 13, "block_index": 310023, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2"}',0);
INSERT INTO messages VALUES(89,310023,'insert','debits','{"action": "send", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "BBBC", "block_index": 310023, "event": "80a30ebcb3366a99961ce3f1f20ce3a66252cb534158154776832d6dac72174b", "quantity": 10000}',0);
INSERT INTO messages VALUES(90,310023,'insert','credits','{"action": "send", "address": "2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "BBBC", "block_index": 310023, "event": "80a30ebcb3366a99961ce3f1f20ce3a66252cb534158154776832d6dac72174b", "quantity": 10000}',0);
INSERT INTO messages VALUES(91,310023,'insert','sends','{"asset": "BBBC", "block_index": 310023, "destination": "2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "quantity": 10000, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "status": "valid", "tx_hash": "80a30ebcb3366a99961ce3f1f20ce3a66252cb534158154776832d6dac72174b", "tx_index": 24}',0);
INSERT INTO messages VALUES(92,310032,'update','orders','{"status": "expired", "tx_hash": "c5e46cd93c5e2236f8cee219d3c00c7af0f7c883428500a247095e7ce73da951"}',0);
INSERT INTO messages VALUES(93,310032,'insert','credits','{"action": "cancel order", "address": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "BBBB", "block_index": 310032, "event": "c5e46cd93c5e2236f8cee219d3c00c7af0f7c883428500a247095e7ce73da951", "quantity": 50000000}',0);
INSERT INTO messages VALUES(94,310032,'insert','order_expirations','{"block_index": 310032, "order_hash": "c5e46cd93c5e2236f8cee219d3c00c7af0f7c883428500a247095e7ce73da951", "order_index": 22, "source": "2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2"}',0);
-- Triggers and indices on  messages
CREATE TRIGGER _messages_delete BEFORE DELETE ON messages BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO messages(rowid,message_index,block_index,command,category,bindings,timestamp) VALUES('||old.rowid||','||quote(old.message_index)||','||quote(old.block_index)||','||quote(old.command)||','||quote(old.category)||','||quote(old.bindings)||','||quote(old.timestamp)||')');
                            END;
CREATE TRIGGER _messages_insert AFTER INSERT ON messages BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM messages WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _messages_update AFTER UPDATE ON messages BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE messages SET message_index='||quote(old.message_index)||',block_index='||quote(old.block_index)||',command='||quote(old.command)||',category='||quote(old.category)||',bindings='||quote(old.bindings)||',timestamp='||quote(old.timestamp)||' WHERE rowid='||old.rowid);
                            END;
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
INSERT INTO order_expirations VALUES(3,'21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',310013);
INSERT INTO order_expirations VALUES(4,'dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',310014);
INSERT INTO order_expirations VALUES(22,'c5e46cd93c5e2236f8cee219d3c00c7af0f7c883428500a247095e7ce73da951','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',310032);
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
INSERT INTO order_matches VALUES('21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7_dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643',3,'21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',4,'dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BTC',50000000,'XCP',100000000,310002,310003,310003,10,10,310023,857142,'completed');
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
INSERT INTO orders VALUES(3,'21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7',310002,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BTC',50000000,0,'XCP',100000000,0,10,310012,0,0,1000000,142858,'expired');
INSERT INTO orders VALUES(4,'dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643',310003,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',105000000,5000000,'BTC',50000000,0,10,310013,900000,42858,10000,10000,'expired');
INSERT INTO orders VALUES(22,'c5e46cd93c5e2236f8cee219d3c00c7af0f7c883428500a247095e7ce73da951',310021,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB',50000000,50000000,'XCP',50000000,50000000,10,310031,0,0,10000,10000,'expired');
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

-- Table  postqueue
DROP TABLE IF EXISTS postqueue;
CREATE TABLE postqueue(
                      message BLOB);
-- Triggers and indices on  postqueue
CREATE TRIGGER _postqueue_delete BEFORE DELETE ON postqueue BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO postqueue(rowid,message) VALUES('||old.rowid||','||quote(old.message)||')');
                            END;
CREATE TRIGGER _postqueue_insert AFTER INSERT ON postqueue BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM postqueue WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _postqueue_update AFTER UPDATE ON postqueue BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE postqueue SET message='||quote(old.message)||' WHERE rowid='||old.rowid);
                            END;

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
INSERT INTO sends VALUES(2,'d18296c6a110057ced7671a1a23faadf5deeba8088157367a1de49637f273673',310001,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',50000000,'valid');
INSERT INTO sends VALUES(8,'c0126dbca92db91189f931c8cf6e82a2fa6498b4dedefdabaeb7ac4c4a4598a3',310007,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBB',4000000,'valid');
INSERT INTO sends VALUES(9,'0d1d40de06a2f09339b68f6e2ee973f07b44530b2ec95012be248439bfbcf8ab',310008,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',526,'valid');
INSERT INTO sends VALUES(24,'80a30ebcb3366a99961ce3f1f20ce3a66252cb534158154776832d6dac72174b',310023,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','BBBC',10000,'valid');
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
INSERT INTO transactions VALUES(1,'baf568fd33ac5ee3efa137cd8f9a030a339889a96834134f9e99815447d2c2f6',310000,'2ee5123266f21fb8f65495c281a368e1b9f93b6c411986e06efc895a8d82467683e6ea5d863714b23582c1c59576650d07c405a8d9bf0d088ee65621178b259d',310000000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,10000,X'',1);
INSERT INTO transactions VALUES(2,'d18296c6a110057ced7671a1a23faadf5deeba8088157367a1de49637f273673',310001,'03a9a24e190a996364217761558e380b94ae9792b8b4dcaa92b6c58d80b9f8f7fcf9a34037be4cd6ad5e0c039b511cccc40c3438a5067822e3cd309f06519612',310001000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,10000,X'0000000000000000000000010000000002FAF080',1);
INSERT INTO transactions VALUES(3,'21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7',310002,'d574e4fee71454532c0207f27b9c46f07c5c2e20f43829ddeee8f798053413ac6e0d1b9ad2259a0370fe08581fab3e950ce629db5fadd823251254bf606a05bd',310002000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,1000000,X'0000000A00000000000000000000000002FAF08000000000000000010000000005F5E100000A0000000000000000',1);
INSERT INTO transactions VALUES(4,'dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643',310003,'44392d9d661459ba31140c59e7d8bcd16b071c864c59f65e2edd9e3c16d598e81aaba40f11019a379bfc6d7811e0265fbb8b276d99cdea7f739fb736f433052a',310003000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,10000,X'0000000A00000000000000010000000006422C4000000000000000000000000002FAF080000A00000000000DBBA0',1);
INSERT INTO transactions VALUES(5,'0becc70a783b2f5e985ee0fca248152608cae01aa3400cb64f0b31a745b5221c',310004,'58c6f6fbf77a64a5e0df123b1258ae6c3e6d4e21901cc942aeb67b1332422c71e1e7e996c5d4f403159ce5ca3863b7ec7ef8281bbbce5960e258492872055fb5',310004000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',50000000,10000,X'0000000B21553A43DAB2C64EA38EEBB4BB68406ADABE478AB682A4C57F3F9C38325D4FC7DABD54DA622C526E5E0114734A216530219588C48FDE8A2F2B3BF2EB52F4E643',1);
INSERT INTO transactions VALUES(6,'097b59f4e505d7d5013b9656106223be410d094b06f8d8d20774e70b1e70ed70',310005,'348a1b690661597ee6e950446e7a1deb8bef7906c0e98a78ab4d0fe799fac5f3007dcd648ff0c61da35b19cf99f16f3028e10ba206968475d741fa8a86c4a7ae',310005000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,10000,X'000000140000000000004767000000003B9ACA000100000000000000000000',1);
INSERT INTO transactions VALUES(7,'543a14fb8742b89677d7109b7b7e7ae2907482718d7658ba59bb99f3b9c07ae2',310006,'9d31b774b633c35635b71669c07880b521880cee9298b6aba44752ec1734cd2aa26b3bed95409d874e68685636a31a038b784d3e085525ab8c26f7e3b7ba3676',310006000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,10000,X'00000014000000000000476800000000000186A00000000000000000000006666F6F626172',1);
INSERT INTO transactions VALUES(8,'c0126dbca92db91189f931c8cf6e82a2fa6498b4dedefdabaeb7ac4c4a4598a3',310007,'41007a4ed39e7df941059c3db6b24b74c1913b80e0fd38d0073a5b121880fd0f7e98989d8d70766957919371fdaf4e5b44125f9f7c449c3b6bea298253075fe3',310007000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,10000,X'00000000000000000000476700000000003D0900',1);
INSERT INTO transactions VALUES(9,'0d1d40de06a2f09339b68f6e2ee973f07b44530b2ec95012be248439bfbcf8ab',310008,'aa28e5948d1158f318393846b4ef67e53ca4c4b047ed8b06eb861db29914e9f1dfe11a8b73aa2225519843661a61e9038cb347015be916c5a44222ed71b8b604',310008000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,10000,X'000000000000000000004768000000000000020E',1);
INSERT INTO transactions VALUES(10,'606a0e1142b6dc559439d3a7a760ecd1e30fea5b8cd2fa08c9af89117809d41f',310009,'550d7d84590c6e4e7caed4e722151f7e110dc39bf3f54f719babfe89775095abb2d2454014b4cb01fb1e0a7e91639559ce17e096be5178b5c2ca5b22ad41b33a',310009000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,10000,X'00000032000000000000025800000000000047670000000000000001',1);
INSERT INTO transactions VALUES(11,'09fc25f258bd33ae01db6e823c084de00790dd74ef89b964e7f3432bff0f83fb',310010,'477c4a3445e32cd0c8ef67c808ac6a6362ebc953c396e2d5c0d7e4f185becd15fa99bd7635358dbb3b5a92e9f03b7fa2dda8d4714e181ec4552b279df3ba81f0',310010000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,10000,X'00000032000000000000032000000000000047680000000000000001',1);
INSERT INTO transactions VALUES(12,'7da765a612160e2ecacad56ff32acd28faa11e7a4974f6d6c5d9e5a54955a816',310011,'05f81b5c1b067b647894014cea65558826be42cca20a6cccb8623d80059182b77da00922539c59a0a7b63f6f011ca0f564fada0451e891644728b874c65267b9',310011000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,10000,X'0000001E52BB33004059000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(13,'6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1',310012,'e9d898aae43fc103110e4935cabf01b6016571b1af82e27af04b57c12302b05eab217f075ac3344b0a422e76b8c762c119cb290c867bb6eed432994ec28af027',310012000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,10000,X'00000028000052BB33640000000002FAF08000000000017D7840000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(14,'f0d2a7c5d14e94a67b9917282b3d7198535e444a5d3c1d2b84260aea2ce5d48b',310013,'2251b497007459321f72cda82681d07d131dd81cc29137b18c534bbb09271678f4497d0316ffac262f021f901078926dee11c791a3524ad850ee948474abd3b5',310013000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,10000,X'00000028000152BB336400000000017D78400000000002793D60000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(15,'a7049b5fa97a608a0b3de5d169a12b8a585e94e038ab89852c630744e9b60f36',310014,'f98fb331e66361507190a1cb1df81b814d24517e7f219029c068b649c9b8a75703770369ebafd864d104225d6fe1fbf13705d1a37a819b04fb151ed390d7bcf8',310014000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,10000,X'00000028000052BB33640000000008F0D1800000000014DC93800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(16,'07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f',310015,'7c25469d6b4fed0e8bb9e4325994c4de1737570fece605b4ca388be6921406b64a395dc519b33c0dff4f93930b32737a941bbb850e31f2ebcd2caba520bc2820',310015000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,10000,X'00000028000152BB33640000000014DC93800000000008F0D1800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(17,'f7463c39fdcf70265fc7e3e1e8418086c6cf3cead714121fdb19f240f47c4868',310016,'9f1c56677b369099f059cc145b98f2e3f8895631cdf0f72b7fe76fd953ab68c202329848dfb53f8146552876eba37f50ed02da34f23447f518449bf0ac0cc29e',310016000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,10000,X'00000028000252BB33C8000000002CB417800000000026BE36803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(18,'ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5',310017,'4c02945de20ccdc874ae21bf56aea2f40a029c17b81fcf602b367bdbc286f9ec0cacab35fc07ac60aefa4a96a586aed20129ad66d45ab87697704d731e06b40d',310017000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,10000,X'00000028000352BB33C80000000026BE3680000000002CB417803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(19,'26124f23215b3cd695728ce8a0da20b6a5e397b308d5e59882f8fc0c541de4d4',310018,'6a26d120314af1710052c8f8f78453f944a146039679c781e04ddbb5a2d010927726fa6f81d3e01fc1fcc3363c06e8e1a81a35636684c4dbcd51edf561a9c0fc',310018000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,10000,X'0000001E52BB33324058F7256FFC115E004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(20,'c8e3bfcc53f8cae8c5ae3099ef8dab163c487e902f02fbf6feb0a004af0c1e89',310019,'592e775a9259b1a5a7b0d7c2e028ff320783e7b49243ed6a20ece89a72964f3af4ed129698c4a143ad682a1493f982c5f8193d3b0e36b3df43964520409beb7a',310019000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,10000,X'0000001E52BB3365405915F3B645A1CB004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(21,'0dd4ea49a1f58f4a9cad0d85e97324880bb10cf59651ee2eb04a282d9ebe46eb',310020,'87fac74eef20e6121d9a66c90481f801a10d636976a6a6e7cf42fc38cc104a470e1b4cab3f9670be86c93ec1a407a1b464599121df6c8109ec7247b25c7efc62',310020000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,10000,X'0000001E52BB33C94000000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(22,'c5e46cd93c5e2236f8cee219d3c00c7af0f7c883428500a247095e7ce73da951',310021,'68a4f307918e2f39fb393e5ad6a7e2fb2e35ab5043402ce37e984de670579682af5c7ef98637478bc0efeb579dc9aaca7f199116b390c452ceedca420909355d',310021000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','',0,10000,X'0000000A00000000000047670000000002FAF08000000000000000010000000002FAF080000A0000000000000000',1);
INSERT INTO transactions VALUES(23,'702e60afb8f29d914c6d06d44f1e15be1d872c73d0796fe9d29dd5c45b31a5c4',310022,'5052fbeb009f77f5629fb701a2e4a379ef6c5591a87ab4d2315c8b79fc8821301b21f146150b2af542eddd82e8e94bc021dd1a9ef8e837891248ab68f4afa7d0',310022000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','mvCounterpartyXXXXXXXXXXXXXXW24Hef',100000000,10000,X'',1);
INSERT INTO transactions VALUES(24,'80a30ebcb3366a99961ce3f1f20ce3a66252cb534158154776832d6dac72174b',310023,'1aab02bbb1a7450d612af368e571d955812f9a376e9f7f80c8eb8296ec40ebfa964f5c9b5e56d4e0cc2d584b38c3280c2b8b2ac272ac00f4d0bffd5348006b4c',310023000,'2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,10000,X'0000000000000000000047680000000000002710',1);
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
INSERT INTO undolog VALUES(6,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=93000000000 WHERE rowid=1');
INSERT INTO undolog VALUES(7,'DELETE FROM messages WHERE rowid=2');
INSERT INTO undolog VALUES(8,'DELETE FROM debits WHERE rowid=1');
INSERT INTO undolog VALUES(9,'DELETE FROM balances WHERE rowid=2');
INSERT INTO undolog VALUES(10,'DELETE FROM messages WHERE rowid=3');
INSERT INTO undolog VALUES(11,'DELETE FROM credits WHERE rowid=2');
INSERT INTO undolog VALUES(12,'DELETE FROM messages WHERE rowid=4');
INSERT INTO undolog VALUES(13,'DELETE FROM sends WHERE rowid=2');
INSERT INTO undolog VALUES(14,'DELETE FROM messages WHERE rowid=5');
INSERT INTO undolog VALUES(15,'DELETE FROM orders WHERE rowid=1');
INSERT INTO undolog VALUES(16,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92950000000 WHERE rowid=1');
INSERT INTO undolog VALUES(17,'DELETE FROM messages WHERE rowid=6');
INSERT INTO undolog VALUES(18,'DELETE FROM debits WHERE rowid=2');
INSERT INTO undolog VALUES(19,'DELETE FROM messages WHERE rowid=7');
INSERT INTO undolog VALUES(20,'DELETE FROM orders WHERE rowid=2');
INSERT INTO undolog VALUES(21,'UPDATE orders SET tx_index=3,tx_hash=''21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7'',block_index=310002,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',give_asset=''BTC'',give_quantity=50000000,give_remaining=50000000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=10,expire_index=310012,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(22,'DELETE FROM messages WHERE rowid=8');
INSERT INTO undolog VALUES(23,'UPDATE orders SET tx_index=4,tx_hash=''dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643'',block_index=310003,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',give_asset=''XCP'',give_quantity=105000000,give_remaining=105000000,get_asset=''BTC'',get_quantity=50000000,get_remaining=50000000,expiration=10,expire_index=310013,fee_required=900000,fee_required_remaining=900000,fee_provided=10000,fee_provided_remaining=10000,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(24,'DELETE FROM messages WHERE rowid=9');
INSERT INTO undolog VALUES(25,'DELETE FROM messages WHERE rowid=10');
INSERT INTO undolog VALUES(26,'DELETE FROM order_matches WHERE rowid=1');
INSERT INTO undolog VALUES(27,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92845000000 WHERE rowid=1');
INSERT INTO undolog VALUES(28,'DELETE FROM messages WHERE rowid=11');
INSERT INTO undolog VALUES(29,'DELETE FROM credits WHERE rowid=3');
INSERT INTO undolog VALUES(30,'UPDATE order_matches SET id=''21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7_dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643'',tx0_index=3,tx0_hash=''21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7'',tx0_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',tx1_index=4,tx1_hash=''dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643'',tx1_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',forward_asset=''BTC'',forward_quantity=50000000,backward_asset=''XCP'',backward_quantity=100000000,tx0_block_index=310002,tx1_block_index=310003,block_index=310003,tx0_expiration=10,tx1_expiration=10,match_expire_index=310023,fee_paid=857142,status=''pending'' WHERE rowid=1');
INSERT INTO undolog VALUES(31,'DELETE FROM messages WHERE rowid=12');
INSERT INTO undolog VALUES(32,'DELETE FROM messages WHERE rowid=13');
INSERT INTO undolog VALUES(33,'DELETE FROM btcpays WHERE rowid=5');
INSERT INTO undolog VALUES(34,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92945000000 WHERE rowid=1');
INSERT INTO undolog VALUES(35,'DELETE FROM messages WHERE rowid=14');
INSERT INTO undolog VALUES(36,'DELETE FROM debits WHERE rowid=3');
INSERT INTO undolog VALUES(37,'DELETE FROM assets WHERE rowid=3');
INSERT INTO undolog VALUES(38,'DELETE FROM messages WHERE rowid=15');
INSERT INTO undolog VALUES(39,'DELETE FROM issuances WHERE rowid=6');
INSERT INTO undolog VALUES(40,'DELETE FROM balances WHERE rowid=3');
INSERT INTO undolog VALUES(41,'DELETE FROM messages WHERE rowid=16');
INSERT INTO undolog VALUES(42,'DELETE FROM credits WHERE rowid=4');
INSERT INTO undolog VALUES(43,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92895000000 WHERE rowid=1');
INSERT INTO undolog VALUES(44,'DELETE FROM messages WHERE rowid=17');
INSERT INTO undolog VALUES(45,'DELETE FROM debits WHERE rowid=4');
INSERT INTO undolog VALUES(46,'DELETE FROM assets WHERE rowid=4');
INSERT INTO undolog VALUES(47,'DELETE FROM messages WHERE rowid=18');
INSERT INTO undolog VALUES(48,'DELETE FROM issuances WHERE rowid=7');
INSERT INTO undolog VALUES(49,'DELETE FROM balances WHERE rowid=4');
INSERT INTO undolog VALUES(50,'DELETE FROM messages WHERE rowid=19');
INSERT INTO undolog VALUES(51,'DELETE FROM credits WHERE rowid=5');
INSERT INTO undolog VALUES(52,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''BBBB'',quantity=1000000000 WHERE rowid=3');
INSERT INTO undolog VALUES(53,'DELETE FROM messages WHERE rowid=20');
INSERT INTO undolog VALUES(54,'DELETE FROM debits WHERE rowid=5');
INSERT INTO undolog VALUES(55,'DELETE FROM balances WHERE rowid=5');
INSERT INTO undolog VALUES(56,'DELETE FROM messages WHERE rowid=21');
INSERT INTO undolog VALUES(57,'DELETE FROM credits WHERE rowid=6');
INSERT INTO undolog VALUES(58,'DELETE FROM messages WHERE rowid=22');
INSERT INTO undolog VALUES(59,'DELETE FROM sends WHERE rowid=8');
INSERT INTO undolog VALUES(60,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''BBBC'',quantity=100000 WHERE rowid=4');
INSERT INTO undolog VALUES(61,'DELETE FROM messages WHERE rowid=23');
INSERT INTO undolog VALUES(62,'DELETE FROM debits WHERE rowid=6');
INSERT INTO undolog VALUES(63,'DELETE FROM balances WHERE rowid=6');
INSERT INTO undolog VALUES(64,'DELETE FROM messages WHERE rowid=24');
INSERT INTO undolog VALUES(65,'DELETE FROM credits WHERE rowid=7');
INSERT INTO undolog VALUES(66,'DELETE FROM messages WHERE rowid=25');
INSERT INTO undolog VALUES(67,'DELETE FROM sends WHERE rowid=9');
INSERT INTO undolog VALUES(68,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92845000000 WHERE rowid=1');
INSERT INTO undolog VALUES(69,'DELETE FROM messages WHERE rowid=26');
INSERT INTO undolog VALUES(70,'DELETE FROM debits WHERE rowid=7');
INSERT INTO undolog VALUES(71,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92844999976 WHERE rowid=1');
INSERT INTO undolog VALUES(72,'DELETE FROM messages WHERE rowid=27');
INSERT INTO undolog VALUES(73,'DELETE FROM debits WHERE rowid=8');
INSERT INTO undolog VALUES(74,'UPDATE balances SET address=''2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=50000000 WHERE rowid=2');
INSERT INTO undolog VALUES(75,'DELETE FROM messages WHERE rowid=28');
INSERT INTO undolog VALUES(76,'DELETE FROM credits WHERE rowid=8');
INSERT INTO undolog VALUES(77,'DELETE FROM messages WHERE rowid=29');
INSERT INTO undolog VALUES(78,'DELETE FROM dividends WHERE rowid=10');
INSERT INTO undolog VALUES(79,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92844979976 WHERE rowid=1');
INSERT INTO undolog VALUES(80,'DELETE FROM messages WHERE rowid=30');
INSERT INTO undolog VALUES(81,'DELETE FROM debits WHERE rowid=9');
INSERT INTO undolog VALUES(82,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92844559176 WHERE rowid=1');
INSERT INTO undolog VALUES(83,'DELETE FROM messages WHERE rowid=31');
INSERT INTO undolog VALUES(84,'DELETE FROM debits WHERE rowid=10');
INSERT INTO undolog VALUES(85,'UPDATE balances SET address=''2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=50000024 WHERE rowid=2');
INSERT INTO undolog VALUES(86,'DELETE FROM messages WHERE rowid=32');
INSERT INTO undolog VALUES(87,'DELETE FROM credits WHERE rowid=9');
INSERT INTO undolog VALUES(88,'DELETE FROM messages WHERE rowid=33');
INSERT INTO undolog VALUES(89,'DELETE FROM dividends WHERE rowid=11');
INSERT INTO undolog VALUES(90,'DELETE FROM messages WHERE rowid=34');
INSERT INTO undolog VALUES(91,'DELETE FROM broadcasts WHERE rowid=12');
INSERT INTO undolog VALUES(92,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92844539176 WHERE rowid=1');
INSERT INTO undolog VALUES(93,'DELETE FROM messages WHERE rowid=35');
INSERT INTO undolog VALUES(94,'DELETE FROM debits WHERE rowid=11');
INSERT INTO undolog VALUES(95,'DELETE FROM messages WHERE rowid=36');
INSERT INTO undolog VALUES(96,'DELETE FROM bets WHERE rowid=1');
INSERT INTO undolog VALUES(97,'UPDATE orders SET tx_index=3,tx_hash=''21553a43dab2c64ea38eebb4bb68406adabe478ab682a4c57f3f9c38325d4fc7'',block_index=310002,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',give_asset=''BTC'',give_quantity=50000000,give_remaining=0,get_asset=''XCP'',get_quantity=100000000,get_remaining=0,expiration=10,expire_index=310012,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=142858,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(98,'DELETE FROM messages WHERE rowid=37');
INSERT INTO undolog VALUES(99,'DELETE FROM messages WHERE rowid=38');
INSERT INTO undolog VALUES(100,'DELETE FROM order_expirations WHERE rowid=3');
INSERT INTO undolog VALUES(101,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92794539176 WHERE rowid=1');
INSERT INTO undolog VALUES(102,'DELETE FROM messages WHERE rowid=39');
INSERT INTO undolog VALUES(103,'DELETE FROM debits WHERE rowid=12');
INSERT INTO undolog VALUES(104,'DELETE FROM messages WHERE rowid=40');
INSERT INTO undolog VALUES(105,'DELETE FROM bets WHERE rowid=2');
INSERT INTO undolog VALUES(106,'UPDATE bets SET tx_index=13,tx_hash=''6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1'',block_index=310012,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',bet_type=0,deadline=1388000100,wager_quantity=50000000,wager_remaining=50000000,counterwager_quantity=25000000,counterwager_remaining=25000000,target_value=0.0,leverage=15120,expiration=10,expire_index=310022,fee_fraction_int=5000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(107,'DELETE FROM messages WHERE rowid=41');
INSERT INTO undolog VALUES(108,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92769539176 WHERE rowid=1');
INSERT INTO undolog VALUES(109,'DELETE FROM messages WHERE rowid=42');
INSERT INTO undolog VALUES(110,'DELETE FROM credits WHERE rowid=10');
INSERT INTO undolog VALUES(111,'UPDATE bets SET tx_index=14,tx_hash=''f0d2a7c5d14e94a67b9917282b3d7198535e444a5d3c1d2b84260aea2ce5d48b'',block_index=310013,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',bet_type=1,deadline=1388000100,wager_quantity=25000000,wager_remaining=25000000,counterwager_quantity=41500000,counterwager_remaining=41500000,target_value=0.0,leverage=15120,expiration=10,expire_index=310023,fee_fraction_int=5000000,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(112,'DELETE FROM messages WHERE rowid=43');
INSERT INTO undolog VALUES(113,'DELETE FROM messages WHERE rowid=44');
INSERT INTO undolog VALUES(114,'DELETE FROM bet_matches WHERE rowid=1');
INSERT INTO undolog VALUES(115,'UPDATE orders SET tx_index=4,tx_hash=''dabd54da622c526e5e0114734a216530219588c48fde8a2f2b3bf2eb52f4e643'',block_index=310003,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',give_asset=''XCP'',give_quantity=105000000,give_remaining=5000000,get_asset=''BTC'',get_quantity=50000000,get_remaining=0,expiration=10,expire_index=310013,fee_required=900000,fee_required_remaining=42858,fee_provided=10000,fee_provided_remaining=10000,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(116,'DELETE FROM messages WHERE rowid=45');
INSERT INTO undolog VALUES(117,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92773789176 WHERE rowid=1');
INSERT INTO undolog VALUES(118,'DELETE FROM messages WHERE rowid=46');
INSERT INTO undolog VALUES(119,'DELETE FROM credits WHERE rowid=11');
INSERT INTO undolog VALUES(120,'DELETE FROM messages WHERE rowid=47');
INSERT INTO undolog VALUES(121,'DELETE FROM order_expirations WHERE rowid=4');
INSERT INTO undolog VALUES(122,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92778789176 WHERE rowid=1');
INSERT INTO undolog VALUES(123,'DELETE FROM messages WHERE rowid=48');
INSERT INTO undolog VALUES(124,'DELETE FROM debits WHERE rowid=13');
INSERT INTO undolog VALUES(125,'DELETE FROM messages WHERE rowid=49');
INSERT INTO undolog VALUES(126,'DELETE FROM bets WHERE rowid=3');
INSERT INTO undolog VALUES(127,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92628789176 WHERE rowid=1');
INSERT INTO undolog VALUES(128,'DELETE FROM messages WHERE rowid=50');
INSERT INTO undolog VALUES(129,'DELETE FROM debits WHERE rowid=14');
INSERT INTO undolog VALUES(130,'DELETE FROM messages WHERE rowid=51');
INSERT INTO undolog VALUES(131,'DELETE FROM bets WHERE rowid=4');
INSERT INTO undolog VALUES(132,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(133,'DELETE FROM messages WHERE rowid=52');
INSERT INTO undolog VALUES(134,'DELETE FROM credits WHERE rowid=12');
INSERT INTO undolog VALUES(135,'UPDATE bets SET tx_index=15,tx_hash=''a7049b5fa97a608a0b3de5d169a12b8a585e94e038ab89852c630744e9b60f36'',block_index=310014,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',bet_type=0,deadline=1388000100,wager_quantity=150000000,wager_remaining=150000000,counterwager_quantity=350000000,counterwager_remaining=350000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310024,fee_fraction_int=5000000,status=''open'' WHERE rowid=3');
INSERT INTO undolog VALUES(136,'DELETE FROM messages WHERE rowid=53');
INSERT INTO undolog VALUES(137,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(138,'DELETE FROM messages WHERE rowid=54');
INSERT INTO undolog VALUES(139,'DELETE FROM credits WHERE rowid=13');
INSERT INTO undolog VALUES(140,'UPDATE bets SET tx_index=16,tx_hash=''07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f'',block_index=310015,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',bet_type=1,deadline=1388000100,wager_quantity=350000000,wager_remaining=350000000,counterwager_quantity=150000000,counterwager_remaining=150000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310025,fee_fraction_int=5000000,status=''open'' WHERE rowid=4');
INSERT INTO undolog VALUES(141,'DELETE FROM messages WHERE rowid=55');
INSERT INTO undolog VALUES(142,'DELETE FROM messages WHERE rowid=56');
INSERT INTO undolog VALUES(143,'DELETE FROM bet_matches WHERE rowid=2');
INSERT INTO undolog VALUES(144,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(145,'DELETE FROM messages WHERE rowid=57');
INSERT INTO undolog VALUES(146,'DELETE FROM debits WHERE rowid=15');
INSERT INTO undolog VALUES(147,'DELETE FROM messages WHERE rowid=58');
INSERT INTO undolog VALUES(148,'DELETE FROM bets WHERE rowid=5');
INSERT INTO undolog VALUES(149,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=91528789176 WHERE rowid=1');
INSERT INTO undolog VALUES(150,'DELETE FROM messages WHERE rowid=59');
INSERT INTO undolog VALUES(151,'DELETE FROM debits WHERE rowid=16');
INSERT INTO undolog VALUES(152,'DELETE FROM messages WHERE rowid=60');
INSERT INTO undolog VALUES(153,'DELETE FROM bets WHERE rowid=6');
INSERT INTO undolog VALUES(154,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(155,'DELETE FROM messages WHERE rowid=61');
INSERT INTO undolog VALUES(156,'DELETE FROM credits WHERE rowid=14');
INSERT INTO undolog VALUES(157,'UPDATE bets SET tx_index=17,tx_hash=''f7463c39fdcf70265fc7e3e1e8418086c6cf3cead714121fdb19f240f47c4868'',block_index=310016,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',bet_type=2,deadline=1388000200,wager_quantity=750000000,wager_remaining=750000000,counterwager_quantity=650000000,counterwager_remaining=650000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310026,fee_fraction_int=5000000,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(158,'DELETE FROM messages WHERE rowid=62');
INSERT INTO undolog VALUES(159,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(160,'DELETE FROM messages WHERE rowid=63');
INSERT INTO undolog VALUES(161,'DELETE FROM credits WHERE rowid=15');
INSERT INTO undolog VALUES(162,'UPDATE bets SET tx_index=18,tx_hash=''ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5'',block_index=310017,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',bet_type=3,deadline=1388000200,wager_quantity=650000000,wager_remaining=650000000,counterwager_quantity=750000000,counterwager_remaining=750000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310027,fee_fraction_int=5000000,status=''open'' WHERE rowid=6');
INSERT INTO undolog VALUES(163,'DELETE FROM messages WHERE rowid=64');
INSERT INTO undolog VALUES(164,'DELETE FROM messages WHERE rowid=65');
INSERT INTO undolog VALUES(165,'DELETE FROM bet_matches WHERE rowid=3');
INSERT INTO undolog VALUES(166,'DELETE FROM messages WHERE rowid=66');
INSERT INTO undolog VALUES(167,'DELETE FROM broadcasts WHERE rowid=19');
INSERT INTO undolog VALUES(168,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(169,'DELETE FROM messages WHERE rowid=67');
INSERT INTO undolog VALUES(170,'DELETE FROM credits WHERE rowid=16');
INSERT INTO undolog VALUES(171,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=90937926676 WHERE rowid=1');
INSERT INTO undolog VALUES(172,'DELETE FROM messages WHERE rowid=68');
INSERT INTO undolog VALUES(173,'DELETE FROM credits WHERE rowid=17');
INSERT INTO undolog VALUES(174,'DELETE FROM messages WHERE rowid=69');
INSERT INTO undolog VALUES(175,'DELETE FROM bet_match_resolutions WHERE rowid=1');
INSERT INTO undolog VALUES(176,'UPDATE bet_matches SET id=''6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1_f0d2a7c5d14e94a67b9917282b3d7198535e444a5d3c1d2b84260aea2ce5d48b'',tx0_index=13,tx0_hash=''6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1'',tx0_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',tx1_index=14,tx1_hash=''f0d2a7c5d14e94a67b9917282b3d7198535e444a5d3c1d2b84260aea2ce5d48b'',tx1_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=15120,forward_quantity=41500000,backward_quantity=20750000,tx0_block_index=310012,tx1_block_index=310013,block_index=310013,tx0_expiration=10,tx1_expiration=10,match_expire_index=310022,fee_fraction_int=5000000,status=''pending'' WHERE rowid=1');
INSERT INTO undolog VALUES(177,'DELETE FROM messages WHERE rowid=70');
INSERT INTO undolog VALUES(178,'DELETE FROM messages WHERE rowid=71');
INSERT INTO undolog VALUES(179,'DELETE FROM broadcasts WHERE rowid=20');
INSERT INTO undolog VALUES(180,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=90941039176 WHERE rowid=1');
INSERT INTO undolog VALUES(181,'DELETE FROM messages WHERE rowid=72');
INSERT INTO undolog VALUES(182,'DELETE FROM credits WHERE rowid=18');
INSERT INTO undolog VALUES(183,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=91100339176 WHERE rowid=1');
INSERT INTO undolog VALUES(184,'DELETE FROM messages WHERE rowid=73');
INSERT INTO undolog VALUES(185,'DELETE FROM credits WHERE rowid=19');
INSERT INTO undolog VALUES(186,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=91416039176 WHERE rowid=1');
INSERT INTO undolog VALUES(187,'DELETE FROM messages WHERE rowid=74');
INSERT INTO undolog VALUES(188,'DELETE FROM credits WHERE rowid=20');
INSERT INTO undolog VALUES(189,'DELETE FROM messages WHERE rowid=75');
INSERT INTO undolog VALUES(190,'DELETE FROM bet_match_resolutions WHERE rowid=2');
INSERT INTO undolog VALUES(191,'UPDATE bet_matches SET id=''a7049b5fa97a608a0b3de5d169a12b8a585e94e038ab89852c630744e9b60f36_07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f'',tx0_index=15,tx0_hash=''a7049b5fa97a608a0b3de5d169a12b8a585e94e038ab89852c630744e9b60f36'',tx0_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',tx1_index=16,tx1_hash=''07113541fb277906296ecf5be57c45bc01545463bf60f2cc144f2de3e467244f'',tx1_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=5040,forward_quantity=150000000,backward_quantity=350000000,tx0_block_index=310014,tx1_block_index=310015,block_index=310015,tx0_expiration=10,tx1_expiration=10,match_expire_index=310024,fee_fraction_int=5000000,status=''pending'' WHERE rowid=2');
INSERT INTO undolog VALUES(192,'DELETE FROM messages WHERE rowid=76');
INSERT INTO undolog VALUES(193,'DELETE FROM messages WHERE rowid=77');
INSERT INTO undolog VALUES(194,'DELETE FROM broadcasts WHERE rowid=21');
INSERT INTO undolog VALUES(195,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=91441039176 WHERE rowid=1');
INSERT INTO undolog VALUES(196,'DELETE FROM messages WHERE rowid=78');
INSERT INTO undolog VALUES(197,'DELETE FROM credits WHERE rowid=21');
INSERT INTO undolog VALUES(198,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92771039176 WHERE rowid=1');
INSERT INTO undolog VALUES(199,'DELETE FROM messages WHERE rowid=79');
INSERT INTO undolog VALUES(200,'DELETE FROM credits WHERE rowid=22');
INSERT INTO undolog VALUES(201,'DELETE FROM messages WHERE rowid=80');
INSERT INTO undolog VALUES(202,'DELETE FROM bet_match_resolutions WHERE rowid=3');
INSERT INTO undolog VALUES(203,'UPDATE bet_matches SET id=''f7463c39fdcf70265fc7e3e1e8418086c6cf3cead714121fdb19f240f47c4868_ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5'',tx0_index=17,tx0_hash=''f7463c39fdcf70265fc7e3e1e8418086c6cf3cead714121fdb19f240f47c4868'',tx0_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',tx1_index=18,tx1_hash=''ed19ce43174e2ed120e1c5cd40ed705630c5cbb01ccc36927bbec56de193fad5'',tx1_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',tx0_bet_type=2,tx1_bet_type=3,feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',initial_value=100,deadline=1388000200,target_value=1.0,leverage=5040,forward_quantity=750000000,backward_quantity=650000000,tx0_block_index=310016,tx1_block_index=310017,block_index=310017,tx0_expiration=10,tx1_expiration=10,match_expire_index=310026,fee_fraction_int=5000000,status=''pending'' WHERE rowid=3');
INSERT INTO undolog VALUES(204,'DELETE FROM messages WHERE rowid=81');
INSERT INTO undolog VALUES(205,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''BBBB'',quantity=996000000 WHERE rowid=3');
INSERT INTO undolog VALUES(206,'DELETE FROM messages WHERE rowid=82');
INSERT INTO undolog VALUES(207,'DELETE FROM debits WHERE rowid=17');
INSERT INTO undolog VALUES(208,'DELETE FROM messages WHERE rowid=83');
INSERT INTO undolog VALUES(209,'DELETE FROM orders WHERE rowid=3');
INSERT INTO undolog VALUES(210,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=92841039176 WHERE rowid=1');
INSERT INTO undolog VALUES(211,'DELETE FROM messages WHERE rowid=84');
INSERT INTO undolog VALUES(212,'DELETE FROM credits WHERE rowid=23');
INSERT INTO undolog VALUES(213,'DELETE FROM messages WHERE rowid=85');
INSERT INTO undolog VALUES(214,'DELETE FROM burns WHERE rowid=23');
INSERT INTO undolog VALUES(215,'UPDATE bets SET tx_index=13,tx_hash=''6ec162e8abe733631652b93cb00e1dd6417f68b7205d3c54e690111518c092a1'',block_index=310012,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',feed_address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',bet_type=0,deadline=1388000100,wager_quantity=50000000,wager_remaining=8500000,counterwager_quantity=25000000,counterwager_remaining=4250000,target_value=0.0,leverage=15120,expiration=10,expire_index=310022,fee_fraction_int=5000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(216,'DELETE FROM messages WHERE rowid=86');
INSERT INTO undolog VALUES(217,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''XCP'',quantity=149840926438 WHERE rowid=1');
INSERT INTO undolog VALUES(218,'DELETE FROM messages WHERE rowid=87');
INSERT INTO undolog VALUES(219,'DELETE FROM credits WHERE rowid=24');
INSERT INTO undolog VALUES(220,'DELETE FROM messages WHERE rowid=88');
INSERT INTO undolog VALUES(221,'DELETE FROM bet_expirations WHERE rowid=13');
INSERT INTO undolog VALUES(222,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''BBBC'',quantity=99474 WHERE rowid=4');
INSERT INTO undolog VALUES(223,'DELETE FROM messages WHERE rowid=89');
INSERT INTO undolog VALUES(224,'DELETE FROM debits WHERE rowid=18');
INSERT INTO undolog VALUES(225,'UPDATE balances SET address=''2_mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''BBBC'',quantity=526 WHERE rowid=6');
INSERT INTO undolog VALUES(226,'DELETE FROM messages WHERE rowid=90');
INSERT INTO undolog VALUES(227,'DELETE FROM credits WHERE rowid=25');
INSERT INTO undolog VALUES(228,'DELETE FROM messages WHERE rowid=91');
INSERT INTO undolog VALUES(229,'DELETE FROM sends WHERE rowid=24');
INSERT INTO undolog VALUES(230,'UPDATE orders SET tx_index=22,tx_hash=''c5e46cd93c5e2236f8cee219d3c00c7af0f7c883428500a247095e7ce73da951'',block_index=310021,source=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',give_asset=''BBBB'',give_quantity=50000000,give_remaining=50000000,get_asset=''XCP'',get_quantity=50000000,get_remaining=50000000,expiration=10,expire_index=310031,fee_required=0,fee_required_remaining=0,fee_provided=10000,fee_provided_remaining=10000,status=''open'' WHERE rowid=3');
INSERT INTO undolog VALUES(231,'DELETE FROM messages WHERE rowid=92');
INSERT INTO undolog VALUES(232,'UPDATE balances SET address=''2_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2'',asset=''BBBB'',quantity=946000000 WHERE rowid=3');
INSERT INTO undolog VALUES(233,'DELETE FROM messages WHERE rowid=93');
INSERT INTO undolog VALUES(234,'DELETE FROM credits WHERE rowid=26');
INSERT INTO undolog VALUES(235,'DELETE FROM messages WHERE rowid=94');
INSERT INTO undolog VALUES(236,'DELETE FROM order_expirations WHERE rowid=22');

-- Table  undolog_block
DROP TABLE IF EXISTS undolog_block;
CREATE TABLE undolog_block(
                        block_index INTEGER PRIMARY KEY,
                        first_undo_index INTEGER);
INSERT INTO undolog_block VALUES(310001,6);
INSERT INTO undolog_block VALUES(310002,14);
INSERT INTO undolog_block VALUES(310003,16);
INSERT INTO undolog_block VALUES(310004,27);
INSERT INTO undolog_block VALUES(310005,34);
INSERT INTO undolog_block VALUES(310006,43);
INSERT INTO undolog_block VALUES(310007,52);
INSERT INTO undolog_block VALUES(310008,60);
INSERT INTO undolog_block VALUES(310009,68);
INSERT INTO undolog_block VALUES(310010,79);
INSERT INTO undolog_block VALUES(310011,90);
INSERT INTO undolog_block VALUES(310012,92);
INSERT INTO undolog_block VALUES(310013,97);
INSERT INTO undolog_block VALUES(310014,115);
INSERT INTO undolog_block VALUES(310015,127);
INSERT INTO undolog_block VALUES(310016,144);
INSERT INTO undolog_block VALUES(310017,149);
INSERT INTO undolog_block VALUES(310018,166);
INSERT INTO undolog_block VALUES(310019,178);
INSERT INTO undolog_block VALUES(310020,193);
INSERT INTO undolog_block VALUES(310021,205);
INSERT INTO undolog_block VALUES(310022,210);
INSERT INTO undolog_block VALUES(310023,215);
INSERT INTO undolog_block VALUES(310024,230);
INSERT INTO undolog_block VALUES(310025,230);
INSERT INTO undolog_block VALUES(310026,230);
INSERT INTO undolog_block VALUES(310027,230);
INSERT INTO undolog_block VALUES(310028,230);
INSERT INTO undolog_block VALUES(310029,230);
INSERT INTO undolog_block VALUES(310030,230);
INSERT INTO undolog_block VALUES(310031,230);
INSERT INTO undolog_block VALUES(310032,230);
INSERT INTO undolog_block VALUES(310033,237);
INSERT INTO undolog_block VALUES(310034,237);
INSERT INTO undolog_block VALUES(310035,237);
INSERT INTO undolog_block VALUES(310036,237);
INSERT INTO undolog_block VALUES(310037,237);
INSERT INTO undolog_block VALUES(310038,237);
INSERT INTO undolog_block VALUES(310039,237);
INSERT INTO undolog_block VALUES(310040,237);
INSERT INTO undolog_block VALUES(310041,237);
INSERT INTO undolog_block VALUES(310042,237);
INSERT INTO undolog_block VALUES(310043,237);
INSERT INTO undolog_block VALUES(310044,237);
INSERT INTO undolog_block VALUES(310045,237);
INSERT INTO undolog_block VALUES(310046,237);
INSERT INTO undolog_block VALUES(310047,237);
INSERT INTO undolog_block VALUES(310048,237);
INSERT INTO undolog_block VALUES(310049,237);
INSERT INTO undolog_block VALUES(310050,237);
INSERT INTO undolog_block VALUES(310051,237);
INSERT INTO undolog_block VALUES(310052,237);
INSERT INTO undolog_block VALUES(310053,237);
INSERT INTO undolog_block VALUES(310054,237);
INSERT INTO undolog_block VALUES(310055,237);
INSERT INTO undolog_block VALUES(310056,237);
INSERT INTO undolog_block VALUES(310057,237);
INSERT INTO undolog_block VALUES(310058,237);
INSERT INTO undolog_block VALUES(310059,237);
INSERT INTO undolog_block VALUES(310060,237);
INSERT INTO undolog_block VALUES(310061,237);
INSERT INTO undolog_block VALUES(310062,237);
INSERT INTO undolog_block VALUES(310063,237);
INSERT INTO undolog_block VALUES(310064,237);
INSERT INTO undolog_block VALUES(310065,237);
INSERT INTO undolog_block VALUES(310066,237);
INSERT INTO undolog_block VALUES(310067,237);
INSERT INTO undolog_block VALUES(310068,237);
INSERT INTO undolog_block VALUES(310069,237);
INSERT INTO undolog_block VALUES(310070,237);
INSERT INTO undolog_block VALUES(310071,237);
INSERT INTO undolog_block VALUES(310072,237);
INSERT INTO undolog_block VALUES(310073,237);
INSERT INTO undolog_block VALUES(310074,237);
INSERT INTO undolog_block VALUES(310075,237);
INSERT INTO undolog_block VALUES(310076,237);
INSERT INTO undolog_block VALUES(310077,237);
INSERT INTO undolog_block VALUES(310078,237);
INSERT INTO undolog_block VALUES(310079,237);
INSERT INTO undolog_block VALUES(310080,237);
INSERT INTO undolog_block VALUES(310081,237);
INSERT INTO undolog_block VALUES(310082,237);
INSERT INTO undolog_block VALUES(310083,237);
INSERT INTO undolog_block VALUES(310084,237);
INSERT INTO undolog_block VALUES(310085,237);
INSERT INTO undolog_block VALUES(310086,237);
INSERT INTO undolog_block VALUES(310087,237);
INSERT INTO undolog_block VALUES(310088,237);
INSERT INTO undolog_block VALUES(310089,237);
INSERT INTO undolog_block VALUES(310090,237);
INSERT INTO undolog_block VALUES(310091,237);
INSERT INTO undolog_block VALUES(310092,237);
INSERT INTO undolog_block VALUES(310093,237);
INSERT INTO undolog_block VALUES(310094,237);
INSERT INTO undolog_block VALUES(310095,237);
INSERT INTO undolog_block VALUES(310096,237);
INSERT INTO undolog_block VALUES(310097,237);
INSERT INTO undolog_block VALUES(310098,237);
INSERT INTO undolog_block VALUES(310099,237);
INSERT INTO undolog_block VALUES(310100,237);
INSERT INTO undolog_block VALUES(310101,237);

-- For primary key autoincrements the next id to use is stored in
-- sqlite_sequence
DELETE FROM main.sqlite_sequence WHERE name='undolog';
INSERT INTO main.sqlite_sequence VALUES ('undolog', 236);

COMMIT TRANSACTION;
