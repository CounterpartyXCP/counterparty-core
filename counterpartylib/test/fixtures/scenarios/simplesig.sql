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
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',149849426438);
INSERT INTO balances VALUES('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',50420824);
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',996000000);
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC',89474);
INSERT INTO balances VALUES('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBB',4000000);
INSERT INTO balances VALUES('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',10526);
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
INSERT INTO bet_expirations VALUES(13,'5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',310023);
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
INSERT INTO bet_match_resolutions VALUES('5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a_edd28543ae87ae56f5bd55437cab05f7f4d8a1709cb12e139dab176eb5f7e74a',1,310018,'0',0,59137500,NULL,NULL,3112500);
INSERT INTO bet_match_resolutions VALUES('bc42268279947c6dd5a517df41ae838c22c7194c686180700d8087dc3c8ce36c_faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67',1,310019,'1',159300000,315700000,NULL,NULL,25000000);
INSERT INTO bet_match_resolutions VALUES('0bedbaab766013a9381fee7cf956cb5a93eda3df67762633c7427706bbd3349d_864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715',5,310020,NULL,NULL,NULL,'NotEqual',1330000000,70000000);
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
INSERT INTO bet_matches VALUES('5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a_edd28543ae87ae56f5bd55437cab05f7f4d8a1709cb12e139dab176eb5f7e74a',13,'5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',14,'edd28543ae87ae56f5bd55437cab05f7f4d8a1709cb12e139dab176eb5f7e74a','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',100,1388000100,0.0,15120,41500000,20750000,310012,310013,310013,10,10,310022,99999999,'settled: liquidated for bear');
INSERT INTO bet_matches VALUES('bc42268279947c6dd5a517df41ae838c22c7194c686180700d8087dc3c8ce36c_faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67',15,'bc42268279947c6dd5a517df41ae838c22c7194c686180700d8087dc3c8ce36c','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',16,'faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',100,1388000100,0.0,5040,150000000,350000000,310014,310015,310015,10,10,310024,99999999,'settled');
INSERT INTO bet_matches VALUES('0bedbaab766013a9381fee7cf956cb5a93eda3df67762633c7427706bbd3349d_864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715',17,'0bedbaab766013a9381fee7cf956cb5a93eda3df67762633c7427706bbd3349d','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',18,'864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',2,3,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',100,1388000200,1.0,5040,750000000,650000000,310016,310017,310017,10,10,310026,99999999,'settled: for notequal');
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
INSERT INTO bets VALUES(13,'5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a',310012,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1388000100,50000000,8500000,25000000,4250000,0.0,15120,10,310022,99999999,'expired');
INSERT INTO bets VALUES(14,'edd28543ae87ae56f5bd55437cab05f7f4d8a1709cb12e139dab176eb5f7e74a',310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000100,25000000,4250000,41500000,0,0.0,15120,10,310023,99999999,'filled');
INSERT INTO bets VALUES(15,'bc42268279947c6dd5a517df41ae838c22c7194c686180700d8087dc3c8ce36c',310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1388000100,150000000,0,350000000,0,0.0,5040,10,310024,99999999,'filled');
INSERT INTO bets VALUES(16,'faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67',310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000100,350000000,0,150000000,0,0.0,5040,10,310025,99999999,'filled');
INSERT INTO bets VALUES(17,'0bedbaab766013a9381fee7cf956cb5a93eda3df67762633c7427706bbd3349d',310016,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',2,1388000200,750000000,0,650000000,0,1.0,5040,10,310026,99999999,'filled');
INSERT INTO bets VALUES(18,'864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715',310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',3,1388000200,650000000,0,750000000,0,1.0,5040,10,310027,99999999,'filled');
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
INSERT INTO blocks VALUES(310000,'2ee5123266f21fb8f65495c281a368e1b9f93b6c411986e06efc895a8d82467683e6ea5d863714b23582c1c59576650d07c405a8d9bf0d088ee65621178b259d',310000000,NULL,NULL,'f3e1d432b546670845393fae1465975aa99602a7648e0da125e6b8f4d55cbcac','0fc8b9a115ba49c78879c5d75b92bdccd2f5e398e8e8042cc9d0e4568cea9f53','88838f2cfc1eef675714adf7cfef07e7934a12ae60cfa75ca571888ef3d47b5c');
INSERT INTO blocks VALUES(310001,'03a9a24e190a996364217761558e380b94ae9792b8b4dcaa92b6c58d80b9f8f7fcf9a34037be4cd6ad5e0c039b511cccc40c3438a5067822e3cd309f06519612',310001000,NULL,NULL,'799a07e7b411c96c92618baa5b998db22fa9ac0a9f7e231e571a237132a813c7','2232e3c5e460148e6c3170643de634af34b78e3c6778b5cda5d0a9f361c05186','bf633fa02403943431451d766dd6bda164a5750fe24a40fbf0dc5593eceae22a');
INSERT INTO blocks VALUES(310002,'d574e4fee71454532c0207f27b9c46f07c5c2e20f43829ddeee8f798053413ac6e0d1b9ad2259a0370fe08581fab3e950ce629db5fadd823251254bf606a05bd',310002000,NULL,NULL,'c5ac2b0cc1745402a7693afc6e5aa4394c1c2c1c70b069911fa793cfef55a4d3','28ffcc056815d1bd8fb9b15101e75318643348dfae3de71c4c8f15b3603e7781','008554413f04fecfab22254a59f36a513ebc91dea343930cefa454e1a3d1141e');
INSERT INTO blocks VALUES(310003,'44392d9d661459ba31140c59e7d8bcd16b071c864c59f65e2edd9e3c16d598e81aaba40f11019a379bfc6d7811e0265fbb8b276d99cdea7f739fb736f433052a',310003000,NULL,NULL,'0c22178d665b7b83b80d9686df23f12ecd6ae3a5744b729c528f9ecc3c94b051','79e7f0d78f450f30b7a24060d08a6c457ae3f66bae1869c739134d79fb25b58e','53d87de16d9e5fa9461c0657b2b2aba2fbee5d9cf4873898dfc6d92a300b0290');
INSERT INTO blocks VALUES(310004,'58c6f6fbf77a64a5e0df123b1258ae6c3e6d4e21901cc942aeb67b1332422c71e1e7e996c5d4f403159ce5ca3863b7ec7ef8281bbbce5960e258492872055fb5',310004000,NULL,NULL,'9b1bb2d232c1e24fd52c4fd299776924fae5b0deab3d37dc359632777c80294b','8f22bb96e46eb95cb5fc28625ec4a11e910082820713fb0f139e4c00d2260cf8','3309e278511bcc4dfc3a84353652c094d2c00dd60c1c187d4acc4a0b5ddcdcb7');
INSERT INTO blocks VALUES(310005,'348a1b690661597ee6e950446e7a1deb8bef7906c0e98a78ab4d0fe799fac5f3007dcd648ff0c61da35b19cf99f16f3028e10ba206968475d741fa8a86c4a7ae',310005000,NULL,NULL,'92ab51eb151104ac16d901ee7bddd5b6cec176a7ce91359b331767963bdbc2f8','9cba99d917c0978ea045695e5ea30f2394f8583e097e7a9a2510cb7f316e2087','8417e1bf70a6f5fb3bfd2dadf524c533f81278ddc1509d213e4d518a018e06b4');
INSERT INTO blocks VALUES(310006,'9d31b774b633c35635b71669c07880b521880cee9298b6aba44752ec1734cd2aa26b3bed95409d874e68685636a31a038b784d3e085525ab8c26f7e3b7ba3676',310006000,NULL,NULL,'ca4d8f6af1678bc1c40c60b97d409d1503b6a93cffc828a132abe7fd4f77a911','6e58e2efdeceaa2b277a02268bee313f08e389dbbc8d8c80f98d179c73a2e395','98e32478f3c6b43d0bf4fc41db167617ef8c6041fc272cbe9e701ab8c3cfb0b6');
INSERT INTO blocks VALUES(310007,'41007a4ed39e7df941059c3db6b24b74c1913b80e0fd38d0073a5b121880fd0f7e98989d8d70766957919371fdaf4e5b44125f9f7c449c3b6bea298253075fe3',310007000,NULL,NULL,'ec5ea53c7c9980060c08faa94fe708d0560bd4667843071cdd49ca07781f8197','96861e114b5429406a5863acebdcb44633898c6f59c4b15eb95d87f428796df4','9d486d0e558a12175c309b966655d10816ff1e6aec1fa21879e737128ecc8cd5');
INSERT INTO blocks VALUES(310008,'aa28e5948d1158f318393846b4ef67e53ca4c4b047ed8b06eb861db29914e9f1dfe11a8b73aa2225519843661a61e9038cb347015be916c5a44222ed71b8b604',310008000,NULL,NULL,'c805eed4b9512a6d277cc5814145f6db7a12ddce6f9df1a1656aafd11730c433','33c928168cec22c62351622dbb777f02e8c16b1ddbe5ed208b600913957d14d9','93a59ba291e911f994cef10c8298a7fce5712ec4ec036462850473b65c8bad1b');
INSERT INTO blocks VALUES(310009,'550d7d84590c6e4e7caed4e722151f7e110dc39bf3f54f719babfe89775095abb2d2454014b4cb01fb1e0a7e91639559ce17e096be5178b5c2ca5b22ad41b33a',310009000,NULL,NULL,'89b985b58171d607af4fca31f87774e68ffe9c5e6ce6819555242df327225300','66624aee36323782397a05fa187736123469fa715e81a5c2644a136e10676dc5','e7ff38221b51714138836fdf286673150c8cfb0ed81d063ccff6d14e89d60ece');
INSERT INTO blocks VALUES(310010,'477c4a3445e32cd0c8ef67c808ac6a6362ebc953c396e2d5c0d7e4f185becd15fa99bd7635358dbb3b5a92e9f03b7fa2dda8d4714e181ec4552b279df3ba81f0',310010000,NULL,NULL,'9364be6a0b1c52254b405f51631f654b7670b1e8befc3171cd3d6b00e8679b5e','0c15109bea6696aed0c06aac8c13c250d556d8f9cc7859ff25a4f539bc35a831','8f4f43582796918e9dcb649e81d4b883441a68df54e0d17cebbe6a4dd2c4b360');
INSERT INTO blocks VALUES(310011,'05f81b5c1b067b647894014cea65558826be42cca20a6cccb8623d80059182b77da00922539c59a0a7b63f6f011ca0f564fada0451e891644728b874c65267b9',310011000,NULL,NULL,'8d855d1d96fc2439e12cea023a8b89188d66af4f2b0909899088f6f49bc19788','543e27f624bc06d5ee24054493f41bedf61eecf2729d302767d78a81763f1008','beb6d1ba88c38b4d9c860d821c4a2f2a20b1ecc60e66ff90bb68d922e5ad8255');
INSERT INTO blocks VALUES(310012,'e9d898aae43fc103110e4935cabf01b6016571b1af82e27af04b57c12302b05eab217f075ac3344b0a422e76b8c762c119cb290c867bb6eed432994ec28af027',310012000,NULL,NULL,'c44aa2983ed171cc07ff6e5d0c4b5c8b11e5d91dd07e38be0c1b9125ae3bf456','144796f674c1de4eeff3f8cf4b6c55e1d43d87ed621e6337981b51d8c52c6c4a','64e4e1da6dce309c58b170829e89fdd42e0b9d935dda16091c51972cd34609a8');
INSERT INTO blocks VALUES(310013,'2251b497007459321f72cda82681d07d131dd81cc29137b18c534bbb09271678f4497d0316ffac262f021f901078926dee11c791a3524ad850ee948474abd3b5',310013000,NULL,NULL,'5be56741bca8dec52d2a67e53dcd63160d4526f7dc0df67fda0de77bf4e9da8a','efb4ddefad2233e81c0a24181ccaa3e407b6b49426cdc9164fee41e14227cbe5','fd24eab2b1ee8311962ae4b4ae690bd242c11ca86fff3204579b11f8f158aa74');
INSERT INTO blocks VALUES(310014,'f98fb331e66361507190a1cb1df81b814d24517e7f219029c068b649c9b8a75703770369ebafd864d104225d6fe1fbf13705d1a37a819b04fb151ed390d7bcf8',310014000,NULL,NULL,'f86452c1cd357d643eee042d1fd66436098685de4c52a7936a03ce20bda1079a','6e5a15ec5cc08aa390b2caca3894068db0d33f029b55b4f40d1bbeb8e58eb6a7','c9a65984a417eb28ee670fd9c48470f6622fb582c7d2adae2c383cdf02e6cc97');
INSERT INTO blocks VALUES(310015,'7c25469d6b4fed0e8bb9e4325994c4de1737570fece605b4ca388be6921406b64a395dc519b33c0dff4f93930b32737a941bbb850e31f2ebcd2caba520bc2820',310015000,NULL,NULL,'bae2bbbf6218c0c024869311fcab4a20fd23aef08df2de2fc91c455f6d9fc0b3','7572a85b67c9abf8b8e295a8b373fa1052bf12c33717e90f59f27bfdc2edc05f','36484f9aa9bdea9e28a4dbe25f0902ea6f43a2300cbef966331b9c3bb0a0f954');
INSERT INTO blocks VALUES(310016,'9f1c56677b369099f059cc145b98f2e3f8895631cdf0f72b7fe76fd953ab68c202329848dfb53f8146552876eba37f50ed02da34f23447f518449bf0ac0cc29e',310016000,NULL,NULL,'bad1ac257a33472aef96bfe3c31edb133dda78d3d50cdfdce60ff15ff16b10e0','61cbd4b71742c0a57bc7aad0759eaded28f74dbf7725b9578be3a008572f5cb8','c477044efcf1fca2083dc22b718fd200a0eb795a873f249c9eb557f6b312f848');
INSERT INTO blocks VALUES(310017,'4c02945de20ccdc874ae21bf56aea2f40a029c17b81fcf602b367bdbc286f9ec0cacab35fc07ac60aefa4a96a586aed20129ad66d45ab87697704d731e06b40d',310017000,NULL,NULL,'4face53b64e3760e7dcd2521355795bf84c08cc4fc9f4714202f4ab9f9dc05fc','0f6d7f2eff9e54c0eed2633263c9096b814220e2d9ad728d7ff6fe0ee03ef425','dffcba3854f0ed63f9fceb3adb254d653401faaf1fa437c9603bd88160ca4993');
INSERT INTO blocks VALUES(310018,'6a26d120314af1710052c8f8f78453f944a146039679c781e04ddbb5a2d010927726fa6f81d3e01fc1fcc3363c06e8e1a81a35636684c4dbcd51edf561a9c0fc',310018000,NULL,NULL,'f6c2e0002faec9c351fa0e6fd4d6319ef90bbb18f523bcff7a7de93f03828995','3440bab5c9b0283624c13ea7fd8292c841c84f4dd81a7762b2f60ce1bae69499','e50aeb3be4f1aa9707603224b954ebca4d91d62071a872734309f2ea8c54def5');
INSERT INTO blocks VALUES(310019,'592e775a9259b1a5a7b0d7c2e028ff320783e7b49243ed6a20ece89a72964f3af4ed129698c4a143ad682a1493f982c5f8193d3b0e36b3df43964520409beb7a',310019000,NULL,NULL,'10758b2da0121a48b575407509018c5b1eeadf37bb5c2b72754537400202fc2c','b462bf354c171e96fa227aa9371dff110a649e0fb770ba46f5bcfede6c806106','38b4dbf3d675abdecb33f7aa74a6076defacc07a9e77f138a5d14b362a97aa0f');
INSERT INTO blocks VALUES(310020,'87fac74eef20e6121d9a66c90481f801a10d636976a6a6e7cf42fc38cc104a470e1b4cab3f9670be86c93ec1a407a1b464599121df6c8109ec7247b25c7efc62',310020000,NULL,NULL,'d4e0407b10cc1081f759911dbec043539234133a35cb558c4d618551a394db48','00369f335970160d232e066b59c6ecb13068f0bab1b3534076846f2f56191631','cf6b8b4e642d7e1ccd0a0a826159a5c8628734ffeb05b5acdf450d50e521fbfa');
INSERT INTO blocks VALUES(310021,'68a4f307918e2f39fb393e5ad6a7e2fb2e35ab5043402ce37e984de670579682af5c7ef98637478bc0efeb579dc9aaca7f199116b390c452ceedca420909355d',310021000,NULL,NULL,'79627943b1596067ed0fffc089f6f364588f5f24e9203d2645089f40d174f269','19569c35ca38ce7e6dac071541bc551fe81963ac7b978bf149915ed289d069db','f0130fb44c8c8b8b1cd08d8165811d8b9256a0fe732589f97fb07915f8ae725f');
INSERT INTO blocks VALUES(310022,'5052fbeb009f77f5629fb701a2e4a379ef6c5591a87ab4d2315c8b79fc8821301b21f146150b2af542eddd82e8e94bc021dd1a9ef8e837891248ab68f4afa7d0',310022000,NULL,NULL,'a293e8104811b548c6011206210787df28356f4364fb58841a0d47ec5ac569d6','bdecaaef78cddc4cb5e9ad4ab9bb418f0217ec4e0ef41a1c1d0e86f30ee345d3','75deb4421f6451c5ee2b98c4c115fb4bf463b36c5614a1348235639da1671dea');
INSERT INTO blocks VALUES(310023,'1aab02bbb1a7450d612af368e571d955812f9a376e9f7f80c8eb8296ec40ebfa964f5c9b5e56d4e0cc2d584b38c3280c2b8b2ac272ac00f4d0bffd5348006b4c',310023000,NULL,NULL,'20eb4a448bb91b5bffd9a56770bd5e0ac2ef4654179896b8928af2f64f43f03f','a6f3607598b6f9fa920e003c534370e127db782c887cfd5501c179d83c61cfe7','27918c084044b58e8ca45831f3046e0b15e228514abc941bc8f35eeb95e9c606');
INSERT INTO blocks VALUES(310024,'232fc55d72da13e22bb39e10cf9bdc29a634f1c6d13c598f8a1886fc6adde9f0db1ec92afc8f2e7e099ad1d225277067c9beebb14116168bcc961d43cc0a5b88',310024000,NULL,NULL,'5a8400b9458a2bf130e2e456047732cb13b77197d8c21b7f247f0757c9437919','26598b260579ae5a7c18b3387d1982f301c9858b60ed3e1513501e6483b852fd','94be2608a7f42ff7aef37acf3a8776672a93e927757c472ebec11df811afad61');
INSERT INTO blocks VALUES(310025,'39e5551cc35f579114d5a36f841b8aa487e8277ede3b03bfe73f31b16ffc92d8a9535c485518839f3a1f5789222f234e3ac59e67f949ebb2f86044e72296a4fe',310025000,NULL,NULL,'134a2ed73efdec3c56857e92885355bba1f0325097bf958ce9387060841ec23c','4ef12ed0065940492bdcf408ade1c581f5e077f92f3df4ce78a670ce24e1579a','039a15f05edde945a8f33e9d4d400890215531971b291cd0361740bb4c0f7981');
INSERT INTO blocks VALUES(310026,'dd6f9e911867c1680a777ed34699914cae82576da2f3fe064cec0f77af56f3af2b9309a9e56195f3a63897446e7cc37ebfa8257aa4758e81fcf70d9b12d77bbe',310026000,NULL,NULL,'991650c3d89e104026aab7489e596692d3c104a2374bf3a2078bfbd0e0ed4ffe','798dd066d5d3a2128050353356026338542c60d6d57beea5b120a766398d08b1','148843b4dab1fd3edc1bb0ab1fd139ac6cfd63265aded234a5182ae8e48968d2');
INSERT INTO blocks VALUES(310027,'9adde4402993118c8963435b66b5cd74676459f5aec1f4098ded4e99592879c8072b1603611ccb10fa2f1e7e88e087f812553796839664f2a3ed510c4aed9337',310027000,NULL,NULL,'6f258efddeb2c542fc610bb169df58beda36852735fc051a046378fffd4a88bc','be0faa91f02fcbb0ef54e80d4cbf204f2480e2918c9d60c15465df37065c3914','d252d480c66cf12bc73c734ccc1e89d2ca079c71de49583887b99e736a2c1c0b');
INSERT INTO blocks VALUES(310028,'158e01a36be6070d70d4f5723fca07d5a49fa057b32c651893df7bf1c5752a41444ddb9499d11fdfdaa7b5a63070f9294a55e1a6a4e751ed154b5330dc10111e',310028000,NULL,NULL,'f6020d6aa398f6a19e34375aef4bc3d9e2af81bc3f469aedcb438b7a4244452e','d6927dfe5ab631ea3f59d55e72799381cbe04cc1b395b52309db6c3ba156f65f','354d83a3fc730eba3b34332a541ac237f5e3f397177f2e8f7eb0adfbcd985999');
INSERT INTO blocks VALUES(310029,'fcd8b3ff5ebaa56426855b262003f15cc0602e452db1ec6c9bc475388553d4766503fc6cde9290903fff1dd94652676b826a229031ee7cb56f69a6d633895fac',310029000,NULL,NULL,'3d1ebe501f5c0706c48001f34df56a82f1ab55c24f7eabd27d7c608b7ef5f53d','4e4b7d132196d86608120ed27e6e81ab2815e727ae88026c6c728864c4a6c4bc','2aec87b59dcb6334868834a556f13ed6c575882601b872a0456d0a731b3f142c');
INSERT INTO blocks VALUES(310030,'b49587ccb88b99aa75b91045c596f731a16ce7523207ae0cfd2b2400898576943ae0969a28c5500d20d72a33c9a79b5fc3f5840bd550846d272462cd66fcc259',310030000,NULL,NULL,'b45b0ed17cec893daf9b0755d8fe96acb5a57d185febee1accdf12d0f6548149','8abfcc7ff3c2cd25f326d4d838c015e4728a5d297e1a5dbdebc7023f6c31eee7','38a65589771b127f11a34c3f08c3cb9b225850cff988786113afe107f8add596');
INSERT INTO blocks VALUES(310031,'7a898e085dea5f59d75df0d4b5dd1a8b12c269d1eaef4e8c78938294abef4813e858c6e6f7bba2e5918a853f71decb610ce80fe3da936587396c44086eed86c8',310031000,NULL,NULL,'a09ade623465eb0723906a09c0dfa9ec3d3608c89d0dc9a6c29771d7e0270870','9aa7872405dbca4ed3bc7a2f1134e3c19484737f66c3c0fa3a48649396cc357b','8c36410b72a2a14a5382db4e397470fda262b44f354ae83e94d10387147bba37');
INSERT INTO blocks VALUES(310032,'d5778cdb9b17207d9caffc0190842356895364e0c5e6247f02c2fb91d4dcde85becbc7958f07b9c99a9833f45599a0c175a8a3b026ec879467142eff3e3c1457',310032000,NULL,NULL,'ac17144975b1c8afae2b06674d2b37ebff0f65340d18bc8b4d2a3d4393ffea2f','52ce8b0a497305eeebe8246e428edaff8d771a53c64ee6dc419b445116156365','a0dbda5c78375b458840d428499f025b461cb1a4a0babfb0b4307fdbd073d981');
INSERT INTO blocks VALUES(310033,'ecc0f5ba6c110a32e76689e934d9101617db692d61600ebfe32b500fecd78dcf75bd5712de67e59b99d5b16d9eaaa8378a46a73a35fb10f8821bf75a173507b0',310033000,NULL,NULL,'b3b5d5b1902c2ef0de433fae13b45a172292f6670e6ae3510b66b1c668589a1f','a09b582c2075b500d1d3f9acbd4a6343d7f9925031aad5756fd81d6ba7cbd9c7','974f09285989e7708fb5ffe094c9d74094af96a8582dc67f1e5d7e170048f09a');
INSERT INTO blocks VALUES(310034,'75ece066b260c4843383467558849588e5ce1f1634da9bea7c9c0e1821150a386baf940a2624b4c0c3fc4bc4996bf97f545fa61a4ec90c57ca5127c1ccdbec84',310034000,NULL,NULL,'9472707aabedf5777a39795c6203b6c739918f192289461dfd04a60de1e0c957','cd45a1f448fce243c83f1e984e80f624bb860291afce4533fd2f714016347463','b589f6293cc4b468585c051635d261595d8903ad30ed8a3b47a3afca78b020f8');
INSERT INTO blocks VALUES(310035,'0c8e6a86abf191a1bad2897dcc7aad3e5a5c1439799c55c95f435eb6fb9e50ac892d58d1a9c9424009d0730fd59ecb202de2e1c155d5fc70a8da9868946caa51',310035000,NULL,NULL,'beefce8b07b546b6f4b7841f0902071df6c2b6690b0e8c761081a05906bb2d54','3d890a1f17b1f33ad4fede90c4b78f6f4536d99274923fb0e853d2626e0cd8f0','8293033cb665a579b15ed0237bba9fb8ae8e8c317608418b2b59e9ceb4d235bd');
INSERT INTO blocks VALUES(310036,'4011ea78ccc04ca2ee8d6bf0b14eef82bfa9456869415a8126f2bee5a1bf961c8436571c00fe20e82c78bee44159e0a3523736123c641b871d271642e8f7ef1b',310036000,NULL,NULL,'09ef6e4b0507f56156c178c9c88a1cd4c4954ccbe349d885b79ef48b5743f050','303d7d0c28becc78eb87492072e9259d6307ce023f7496ca5b0ddd66ae4687c0','d7bca816eaae52531aecf5dfabc4971f6ab8ae1123a12f57bc2d40af63664f09');
INSERT INTO blocks VALUES(310037,'7f94ef56feec97124f1e6f04b862fed49ae7c179ee143701cf0eec922b5d39932831274f5528d8d9b0e8e115236cfca7f2d78da21db5596565314e625300ef49',310037000,NULL,NULL,'9031545d6509e31bc0694eac4d8b0f227cba3017c2c67c8475e782be62daf78d','dd31e2dc030e7197de7b39a89bdfc2c021cc5d80e2aff0a208781e5ddd8162dd','149183b3878b1112866da67eee007a488c906858e6a41e5ec2cd19316a733632');
INSERT INTO blocks VALUES(310038,'e7c42cc00226117b58f818813df49a64af8ca6352a8490a2894676aba647c1bc8d4ae58bb883b710348233879c841da83eda54d35c5ec279f8a2e1ccba8a4264',310038000,NULL,NULL,'8bf7837453018b11389958dfa7a901098387088d926b64073dfdc862a4efd20c','22c93b74ec96bb5c171ad1f9858b23c99ccbac22447daee5363b27d87e3dbfe1','2fd0a473052386d456a16c1a222e2023d630222290c5f6dc8f9b88639d69a668');
INSERT INTO blocks VALUES(310039,'1efd67747830ff43e4cb5f2837d40789a0a781a79c5de4a7966ef64101c39169c28b7eb78481c4b92d14d997be3bbc7f5c6a6a8af8c729825c0e6a07fc6fbeea',310039000,NULL,NULL,'c1a5c848da36b34fc10df323539ec8a363da62c373afebb5236b6985a5b6ad57','671f7e2800cffef071dc261d356bc8ec48b6abac8347bdaa186908d79c0a6453','b54594291ab0aa24549e9858dfc6e178a99134a4b0c8455764c890a2fff7664b');
INSERT INTO blocks VALUES(310040,'0afea7365138d9d478c1a57003d66b1998e462cfe57a9a3a1a9360f5e305e9e639387f6849770c33995e1126cefa8ed66faf8a8af03e5c0853191091978d04b1',310040000,NULL,NULL,'872fca779c7f012871ac7fddb3f4006fe9573e4c0889bd2de790dc0158e6732a','8ef6ff70cbb3e2458e643cfceb9a36e8583df65cec0099c27eda9f9e63277557','897cc0777bd14775d0fb67b7a1c50b3167a78a9fd5e041438dc7e8bcff3fec97');
INSERT INTO blocks VALUES(310041,'a332959f882f2a2846237e5ce8874beddc8e28c551f7d5be885c79b1d4650c5ff3c9855069302643e9315390e2dc1e7e072e7f90afecd5fe4f3f14b31f38caf3',310041000,NULL,NULL,'b12c996ac0c0023e4e230fdda1fb0132b4131034dd930ab4b294af6f469e0bdc','8aa46725e18dacd782ce8ef84fdb7b7827327c582842f3f30e42ffdc70640734','a85b8c128563e8f40f85d187c6df633af7cb3a4b23358514c8ec97f05160fe39');
INSERT INTO blocks VALUES(310042,'ee6c4eafabbae31087db301639be2c8d82b31a3004ed19a30a3c6faafdef5c0a363ae91e97c4cc88254bfb0d16213816e610da28233ee3775969dbeba213ea2e',310042000,NULL,NULL,'7a8d6356e216afe4e589d26b471171d4bec625f9aeb6ee3f3af6c95d48f0b725','a02fc5512773165291cab8d9697d28c0343bd8ba3acf3cc52e15d7b724f45024','6996e73d0ef9f19e7bca96ff488a3c1dde5312809e129d7249fda21365f0dacf');
INSERT INTO blocks VALUES(310043,'1fd0b3a1241e5435a39f816d44b6a009780a37e2a131fa7be8423875f81defa4b571a0c9b89cc335c2698dbd66f55fa333bb80e20fa2ed03d9c3e8c95276d05c',310043000,NULL,NULL,'00d2b046d86a0816bda22f1ad5e6b4c1b898bfed2c65df3c6e7ad7466a001b6a','1671e4d0c93e129fc8fcd59738499e40588cc3bfdb1d4a27c3f48be0192d64f7','37d7e3e411985778cf5bf09809127159d756d987dd4406351d64331338394104');
INSERT INTO blocks VALUES(310044,'8074ad14f920e3bcdfe75f606c3a261e14275b3ec48d8678841492f633feb1a25c48c729e10d192e59d52b1ed5bc10185b2d0636835b05b3962e4be08b06f194',310044000,NULL,NULL,'c49bc1a16630633105f839824678cddb2dcd7d186071300bf4911fbf4cb9442a','127674a1e5112e34466a2e617ec2be0827130cd488e680f2cc52d7669011931b','448cae39af52df6c773840adf7d9a32206d19b1acbb8247b078040102ab719e0');
INSERT INTO blocks VALUES(310045,'edbfe164803ccbc044c2d602e6ee85546a00d478e5ec3a9475a487cfcd7deef64155b201530367be15262f05ae77a8270ac8dfed18355302a01bc37d0d1d98ea',310045000,NULL,NULL,'e3de0ca395651f7a1598738f2604581407f2b45b736f5aac2ad64e867295efc2','ff3ee58bc415c3555105f0c5b40e97dce479cbf7f35e5e35d03b5cb5571ec7db','064076a297d947ca94f19c3b9415a0eb0a20435007caaecb69cb290fbacfcb34');
INSERT INTO blocks VALUES(310046,'c1d7a9dc0c93554dacedb41e6f4e7d97b7cf23a9706e6052b7c583233632b4f3cb8596e5b59b6957413ea1da603c2fe125eacf6b2257fb2ae48de3652893eb22',310046000,NULL,NULL,'ed901088e07f2e89f721cf23f968a3d9f070ed6dca4cdb172839e9a661a9b1d8','9f08d7cfb5618a8b0ebd54b028418025cc88312fd103945a4adc8c0998c5f8cf','3f96e396dbca80f8d323278414572dba74ad07f984a603f9f484244876a1f41b');
INSERT INTO blocks VALUES(310047,'86c6061e10d6032dd6051842afb28b6121ba443e4ace7ebcc213258fbd8aa86136ea03f5c3eafe13e560b9589871011f786bf204cc8ac6a419c263f138ddf72c',310047000,NULL,NULL,'121e4e8d312ac0b95d72b1700db6f430b3724f75f00af90132db5e6c21fbc53e','ff0e537f22484bf00deb66ea804300a2d696f1e8de23766f08334f0208975b62','336266f4ec49a149634a951f4bb7c40b0510bf9c38937617421382498982c4c1');
INSERT INTO blocks VALUES(310048,'41f80924d6d10e6ff29f9926dcc1bc644a30d87657975c22165d4c54f8c30938b9bec93e24e7033bff0ad7e6540bec0ae0c3333c7f54499c7809c450cdf91451',310048000,NULL,NULL,'53b15d51a08eff5fed146c635008936e37e7e887fe29a2f120ba0ed880ee667f','b3dc9ad8fdbe71cb08702ebe3fd2697162735452f4311e7ff41dc4863f967348','215ed36a2424585ac5f5571e31689595a6613bce95230352560d426e6baeaa0e');
INSERT INTO blocks VALUES(310049,'51e01a7614ad99af02c4171df920803ed9a88ff9a47254f0d0faf521f5f806b840bf88a311c54a08edbb9fc2f152214bb930f1b8368245c8cd263473b79f808b',310049000,NULL,NULL,'eee2ad25f711f1c125a4964847a5eaa7c2265ebb324df498b30a8287d7a12161','42cf58aa8061a0ef3991094d916ed7738f944400152fb73042d0926e05063391','d8aabf90bee6ac9157985a8fa99a37b1aecd15f42f43b3cf2684fc673ef4de03');
INSERT INTO blocks VALUES(310050,'c719b9e1f31934a3bf53ed8f8a4f59ad22f3d0481008f4a7116f31cbfcd2b71ebf296f8a6890f522c72303d63c6f6b76b802f5b93808620f3b6ff515155ea73f',310050000,NULL,NULL,'b03d4f0a027bc98edbdd15c1ce220a5bc3566adda6313772ca8501923c26fc5c','e30e27d6789641ed9163fe85337f4cda3d93bd177ae818d12a5e8437bd70a103','74aa78d2ecfb7fa398136bd0c13e87a5a90c77656049cf727d39a52864e9d0e0');
INSERT INTO blocks VALUES(310051,'e88246311bb74b66ad0f97fe2f5734e0c68d0329f05a389c35ef8a8575e8c078b92b401bccdf84f2950fd884cf0c22e2079594050292b01ffc69c8e779150ac6',310051000,NULL,NULL,'eb1690ec7cc4fad1417b1c2cf66c4260bd0bff5d628d4d9e4dd591a01bd89fdb','f8a2b2d4691fb077889009b867ce742e8688161b744e656ebbd4b4d51b07401f','953fc211a99d992c275a13db6354e43bc8cbabac5474ef412aa5ef20d7b0078b');
INSERT INTO blocks VALUES(310052,'1c7e09c9d97f26b1be51752c372a88ff5b5da358c76002a42647916b5e27d8e0f75effc92c15f034a75cab7ca8d8a9ec34c64f1fbfe8690c585cafc553add37d',310052000,NULL,NULL,'2fdb743bae81963ec46bb2b12b2df50df5812475e96427f55abe524946901495','717a4598198953db101bbd0f22b4c32ab2628ec7e2c51f490879c53005dcc773','b52879945d58bcae735a05888e65016827483be2c616fc924fac4d29f014c8cf');
INSERT INTO blocks VALUES(310053,'60ed831a77cedc82909d871edc4e6525de5669cc238f7b9010336b4f5c80f4eb29fc8f8f05cb9a41db4e1311f437015c8bb02b214b69cf04f909e14868ccb66f',310053000,NULL,NULL,'66a979e684410a1fd761ff4622a0257d2d064de65519c6425048f5b5576231fb','1baa29b161bd7b68e18a22864e53a22cac0b63f03a4ddf8272feabac1796bcba','9a705e87a79683bf3185f6cc20c210232462ea17b9eb8d331ea16b2db8a3d0f6');
INSERT INTO blocks VALUES(310054,'0871d6f27552c73bda0f3a9f2557d87b89a0589ed5da70ed84a42dd89456a877d24e0e439953fff2123f110100aaf350755afe5ba6ccbe4f01b1965528e1b39f',310054000,NULL,NULL,'291d96fd959f92027f92e25ac8ecf2e3f4602eadb8353e6a4c0c5db486a8040f','b61d89611206ff13777d4fb46cfc0c4f9347d8240af52dbc7715bc91f1935d68','e688413503eeece5440275fe62318671637b3aa8a7fc6c7378a0fbcefdd457b1');
INSERT INTO blocks VALUES(310055,'3edee52236cc6d3fcf0c9e108ca28515924cbfa3b9ab8d6f2ce59b1f234558ba3d50c88381fc53f0d607e67dfa8cf497f45f32def36c5a444233a0edaa649987',310055000,NULL,NULL,'2d70ac8848c48f2851118dabf74b766726525a324faed1a93ea962ef251de880','4509aad9ff6e2b67fe1fe1517bd98aeca37617ae5138a9a60ff0c3ac97aead52','beab9295ca6633e6bf475a47b83cd0605eede0a646e882a245a9b1db3e57eefd');
INSERT INTO blocks VALUES(310056,'bd46235733652f0ae9e77cd97e22a371fb6778c023c98e49684616eee72b64696b1376ebfcc8e897ceb18d8415b08d5d8b27bb788bb1f6de3b8baf985e2f5c0b',310056000,NULL,NULL,'f0358dd54c295b6b736f66c9cbffda24bc56c61761f94bbc29ba4975a569409e','b73e3d866f58ff1a14a827010239afd667de7a2b3b8f693a07be415833fbf0ec','2c2af44513a277eeab1f4fb6185443538b9d778bef8457c5da71a803e4af05ab');
INSERT INTO blocks VALUES(310057,'91e818ef3f1425e86d13808bcb5cb4125205d61f8d063f21cd37a445269ad14f96bdc18283a12ddde8d6775bc55b2ff91c7910fd7d512ee242dde68d8d4f1520',310057000,NULL,NULL,'b4a5de4ab2fee5a5d625e35691225e8d51ada6c0c0255778c72a372642b0d87d','18d767c42d705a280970ec565cf5cc61635db9440ea450ca9b9372e3b45d927d','670b7974467c67b91655ce206f4cb9ea23c17fe8f19633099295bcb948759a14');
INSERT INTO blocks VALUES(310058,'ab68270f350c7c11d62cfe38e0b20c6763c770f9d9dbbfaa16cff8ab3d746a9b71047d4fde90c7705688b7f36ed3479a9718fb1a455cdedb5bf97309e3344e3a',310058000,NULL,NULL,'1783e1c883c3f10f8b4ed888002910370707bfa479c6deb48711f555a26d51b7','45f369842f28f4d1ce276436351c1c8d7058c21a574f07987f5ec168e28af530','6455394065f956797965d32182e03d5232306f300cd2dda9430e5565dad6de77');
INSERT INTO blocks VALUES(310059,'d08b01ec4f2055eed65363e748f638470b4e989c815ba93395c139de56eb925e577bf05c46a1cf2051a238a2ce1c62bb137583d12d9b5a30e3d1fe2118e50009',310059000,NULL,NULL,'4ecaeade9c9e63d43ea60eb7282b684b708f142e46ad25807c906e5a9b3da9b7','55315cdd4e12f64e505b550b1ab7031e47a4a38afd4c1e99a9f7c9c175513dbb','fce7fa5ea4c49a2a309ffa1284cb1964fa9c52f2427ec7364f428377e6fefc1a');
INSERT INTO blocks VALUES(310060,'76cc352a0973bd5cee8255c511eff6cc34a554d636ef61ab3ef6621dd0eaab17b3032e5ade33c8712b1d45960ba779974e79998b0b7738b6815ac93d2eb8181d',310060000,NULL,NULL,'3073feeb0b9cb0680ce0775d2244d4b857945abf8057f9fff73e3e1dd990bf72','c7418f003de26d2c1510e7713c959f311c86300ba595ae8b8d76b2019466a2a9','0048fe914e010bd64b001680223b5822223ff62cdff53525989df0bbe7c4c27d');
INSERT INTO blocks VALUES(310061,'80a038ba3f297cfc699d7be560b9be58d8a88f4b127468e22d5d633b6b3e359430d738c20f7c5182a435bcc1a49a056e84ce705ccc504405bb70700030f86260',310061000,NULL,NULL,'96c4c024112811085a4a502b04686eab225d64f129acb1acbd73cf1e6c402a2b','0f083456e81d29d02678482a3bf6dab0a8abfd1911d986f9ca6d8cf6a55b4a63','9954ba6edd89bf1d1a2c8e7fec366ef9aa1e83bd836f117458287e5e5aaf853d');
INSERT INTO blocks VALUES(310062,'9fb37033c32405d7e00ff9b69272079af198e9960fbddb8dbba542b7b6911ceb833868bad3759566a7a2736b9d719ca82690627d83491ed40467e6b18830a711',310062000,NULL,NULL,'153c680b372c1c80d98ab8b80d9dd4260646551935f4f70063b99e0fb126bf9f','5616cb7b80a7f21da4203a88e1119aef107a8fbd96a19bc8454a8584b3a7ac7a','2f1a49ede39ed50813e6168c77549aaaaa2bf2fd0edff0ae16c524b9eb57d145');
INSERT INTO blocks VALUES(310063,'807f83f652635dd041b0e46222d9a136099f478a5159c501735eb3a64b32d664250ec44f4668df72b1f2b8ce34ff2e1c260b6fcd87febebcc44e99faa098cd7c',310063000,NULL,NULL,'cb8ce9ef122691f289f254b5bd353e2b0c10a0b42f89e37095e6414e2d19e695','e0f1c8807ec0c77e88dbb452e3bdf96e953021f9a242d4d8c164630a2a48237b','869c02d77a1180a4b7efd1a3bf2f45cb4ee7c91ae2d1db2b74959f2328d76e69');
INSERT INTO blocks VALUES(310064,'cdfd286ed7373f1a2b525d37a903df4ac53788422414fa5fa5b408dc04d11991b3bb3c7dc7be3bc98d65c31265c01abd59f6c9f4cf6cb25c8da4a28fcc74f576',310064000,NULL,NULL,'144936dc78bc9de33fff406f291fdd4627d910eecc7e3932131f26e3c13758e4','e95ce11d317662a4b525160f78c5791071c896ac4603fcc4b35560d67e8802c8','b28434e70ad458bfae5b6b3241f21a3f233c592809ba1256a231bdb9c0cbe691');
INSERT INTO blocks VALUES(310065,'e971d529b30e42e87f399558d975181220fadc9b160b37dc5fe82752be193de9c7022dc509061f99158c7e585799f336ea3dd8fe63d55b57772af676e91108c8',310065000,NULL,NULL,'195858e58932f7cb09b1f372def847c0237dc0385ede7b5ea8c96058b40f5571','32f1780bd60d9caf2329754bba1674070db0ae24265cf530c5375d86d8e31295','46767a578fd6ba384c414284ed423bfafc5b58782ec7af07bce2698e01821d1e');
INSERT INTO blocks VALUES(310066,'0758bfcf08b5a8eb40e4937fd84fc69458338483a8471865b38fa252d8644be6c22962996b80aa3fb37db97f2e2a213049c9cb356d8564d26fb1ad5de14ccef8',310066000,NULL,NULL,'accaf75fad3f8c5dccf476cbcb4ab634243fe54f706746ddc9bbda86298a36a6','43ebd0c077cbeab0d8bcc8a623a0c217370cac87998cd271827ef68ae6abf97a','dbc14603ebfd745430e00216aa276cd3b72689ace2069594f04a0c3cb10022f3');
INSERT INTO blocks VALUES(310067,'359caeb095b44b88cb86676c4a94ac830211c31e25c326c9c75e3ac60c5f28c1ee7387fc46ac6ba2946a6ce41a067637047ac4effb32777dd9f694ef1aa88ef2',310067000,NULL,NULL,'d6846fdf6c9708dcd2e8c8644bb687d8da954989508b0d02d785d59b509d9909','8202ee1718ff1b93d5971eed0cf5d0cd0fb65acf33d9c51f0414bc94f800fec1','c0a0015c452b2926c08171f4e937ff99dd8810da92895c406e909238e14d66c0');
INSERT INTO blocks VALUES(310068,'2f1264342a2fd66c9493f2fa062cb8477ef86f72c532149ffd45353fca250a9985c027d7ccee2e646c96533196f6dd60ef9bcb12b3f156dbe71edbd088418487',310068000,NULL,NULL,'b208ada2b6a94aafdaacd6fd01c32fb4ebc616dfb1c4aa02ac2289f4cf033fdd','baa8e09869d6717531fcba144d3ebe60f78c7d539fa5e4fcab839786c316578b','80f5330d819f6c70a7f6a6250b06b3961c2c582ddb3272ada2e9044a509454d2');
INSERT INTO blocks VALUES(310069,'b08114be39f1ba70cbf72cf9ac4b008d8582dce4d4d7c789e7da57eb264fab24fdeceae387dbb23d5dc0c73f8faa013c5a499ee8d2761b959128c9694802230e',310069000,NULL,NULL,'d0050dbf85c9fb5cfe88ade565a5976bf0fb6eea263d8980dd009a72a1c04f81','3647919b32d75a2b645100c672c71a65fcf27d672d7c5c1eaf3a1e2652f1f120','6d1badc2029d7d234dc79bcaf12acbadb3816fad2897a8e3a04df4ec8289d327');
INSERT INTO blocks VALUES(310070,'5f1384e1063f3c21946d063c75dcb43a6ddc4642eac6f79eee0a80ea99320bf8b26ecf86b1e79889e1c733cd278219e76315130a30b440d84cd288be58bf3853',310070000,NULL,NULL,'df63fbb4133f74484b568da86c701e10c4e28b1c047fc27f93bc5287d013b15d','21c8088e85dfdd09279be1361b78b9d8c568848d20d7d54b059620674b598fd2','e7e3b41d2e5ad501113d8aff2050683c9b6ee101244417c4ea5b5745db64e93d');
INSERT INTO blocks VALUES(310071,'c80b492818257e806e4fbe093c89c7965275aa8e36d1bb888d1f79a059e95dadc40273e59de99eb8d80c5e8e1445509d8baee4c733d2c470598620f3048cfafd',310071000,NULL,NULL,'b4127d65d3611e2bfbd974f1b90099a717d10a4b9b26d5ad817871ae3cdc8516','c3118d9213735e3ef42f47cea6686c6f09e48beae6e9bb2bf5b546336b76b1dc','604f60abda5d91ed4fea9d949de19f79afa5ceb4a9d1d83903554f7992867fba');
INSERT INTO blocks VALUES(310072,'64a311227b25fe4606729312295546a9ade70637e896cdd8321257c0b173e38701be1e5bfefbdd2cf1eb908d5076f2b464c8664281cca6a9d9bfd715ca085a93',310072000,NULL,NULL,'35e860497cf0a6046c1f0409dea188452333d2d9cf2a9e0ef3321bea5d4cf0e4','13171993b9aee0350f5e5a60139e7574f464454dad22f55f664e3692c01cec99','c5a772c00067e442d332535f207943691686f027864f42c8bf51b03530f7a0d4');
INSERT INTO blocks VALUES(310073,'acc6dfdc3cf0651092a08818eed4eeaf9abfd322f1e46bec97e6a8ce96317612d4f3873e194310f1335da4ac225ed92b1a59237cde4fe1d2049be6a2b66c1f1d',310073000,NULL,NULL,'322480282050f8f9699f2387e36df75724cf7dcb1025791664502891141e9d5c','eea849f0c8e5f8ea1edb2302194b2b2415c9a7a582ab0698b23c9ce0dc172d45','f881a69a35f7f40e567ed35b2febb7ccc7d1b65cec942783c61073cb283fcc47');
INSERT INTO blocks VALUES(310074,'a00f647aa4b5d9142500fdc7da95b47c60c0affa3275cab56a875b1e082fa8037b3c32e6a002f92010c2d8bc1abaad10c2373fbd246b59e69af1e97df5c3a3f2',310074000,NULL,NULL,'a60e86ff8d795b087e4719ec9af48dffd197d33c26e46389b3b550111096109c','4e161ca5b7cb5f0926988f363990b235a18649be520199f65de2615fb2858b28','fc1d677a2f6983cea9f52163dfbc15e3f1a5a140464d303bd9a22098308f9178');
INSERT INTO blocks VALUES(310075,'53035b827f91f83e75adef2f62607377fcffcd185902cb742a72d751e4d57e0432562fe92b0cc6f7221ecbe53ced6aea685ba2383dd9e2a78fce462778b75010',310075000,NULL,NULL,'d3b5b430f3f4e608877232fdd5ae0c53ac10ce9a9b2c37e978eab16e8eb6ca62','bbb9447a83f0560233287f6300f623b099432415b08ca39d0890f1536c0a4d19','13a2e74f473f4cebbfb79054bf1485682ba1f49e22d2b1aae67a2a740b33f636');
INSERT INTO blocks VALUES(310076,'98867155f362ec51c5d01c1ee81fec7c0fd5bf08892df7e78140ca21c443c084876793d528480ef54ea1e185fe435869dd7dd284119b92f4a3f63d05173a6580',310076000,NULL,NULL,'a494efaf91c425b73a1d14dcc8990c22037e44de21bee985c73f875b2d159632','5cf12d84bb8b7a0e5d8335c558ba0a6eda04369455cd481827a1245a54601bf0','11133d28dbf04d43c3d1f07feb3b3fdc7d06630dc40ce52286d727c8705d347a');
INSERT INTO blocks VALUES(310077,'2f9ac5c43c034f11cf28d62fb787f8c109662e4187b8af0d7dbd81b524f474ba9f4ab6bb6a36ce44003839ba82f7018065499543c9e3b4b1be0e96b9d56cd9d7',310077000,NULL,NULL,'d930bbdef0c331b30f755de4969c5fd099b787461fc06e18006f0ba89c2be19c','75d650847abf3ab5bbf69bfec19165afdf3da6e38e6c044dbb6b64ba51f7b8c1','9ab0c461bc72b5f3265cb4060fb75faf28c744c934dabf3f087168df616f27fc');
INSERT INTO blocks VALUES(310078,'5e535d532426974fe1c45ebc463ec7a93fc3625a5da33119975481c4c98ec8ad81ab13fcb7e8943ae4fb26b41aeaa7ca0f50fa22d16c7d18e5deb3820e96df1e',310078000,NULL,NULL,'b11a6a52e7ed2aea8448941fdd9a56d9dceeb57a731c9ad1bb07468719ad30c8','fc9aee9e02cfe8270f3a21dc154abdc911642ce3f76018250893ec38eb55766d','9dcc9b1b3e281e768f4f45a6a86f6c8353240a11c2bd5d4394d933cf34552a61');
INSERT INTO blocks VALUES(310079,'e41a51db594c3e7919b4aac63e6100a092461b81518721da953a476986f5bf8e29085cfe6a08ec452fa547b704c4c4eca957ae193c27281dfa7f113a0f6df941',310079000,NULL,NULL,'809be3ccf041d65c81fe99fade5310f2fb5de939964c29b381ca6c90ccdbca33','4d4087e1d855fce516f42ea2992197d8dcbda8a51b3a1a042ea17b0bfead9ae9','8461a93aaacce129dd1f84978935d7e1584755d74c9ef4b16c5fb4f725d815a7');
INSERT INTO blocks VALUES(310080,'fa67febda99884d857fb9bba17476225a600f76535a9431d21c261662434b85b9b4d4ce3cb591d043f80ebe0adaf9263e0a368d949d291e14778b46d07dabe91',310080000,NULL,NULL,'1d53e6a686d25aaeb9d78755583d54f2f96fcc89083d1253afa1b2ce6dede2e7','b6e697edb90b4d4b3115cfc561d3d9191ad401b2fc56c5a052588b2b948be52c','ba7daf8bffb679a2e5f1c75dee00eeff318771bcb264148083617eec019bf23e');
INSERT INTO blocks VALUES(310081,'98a5ce8fe941cef091735620c3119d97a382b9c80cc1764d1d30c94300037d0e519063378746b7edbfc60aa506fc04ebd539ada353534b7a5b3d621dec791da9',310081000,NULL,NULL,'26f8aa2cd284d09e2a5d334359c04aee4d8cbc326aef762d3327812ab2ee8e56','db5709e8400efbd24b003a9278d7809637e412d2c66f9a21a1227c85005a5c5e','2a259e925098808db1073402110e802f0c57987c810be7fbc2e8a84f13f50640');
INSERT INTO blocks VALUES(310082,'7702f9604bf3efed6578761f4c52de99779c7c42d7543774d425a4c3537befbd2e7181355f8a1130d3d8ad9ff3bbeaaca4e26cfaefff15e575ac4b2eb19b7051',310082000,NULL,NULL,'46973d6e354a34a5c54aaf399bd9f4094f015b690f1b8f70ed5b072a84a5f789','165a37e389235f056f0f99c49c5f987c4603f449fcf1e7dd64437e10d70d7785','7de7f679b86d39b8ae82aaa4a94396238029d56cfc364960871751a667d98b31');
INSERT INTO blocks VALUES(310083,'f190eca1a75147eeec93cf96f106e346b908fc47e6a363093d5b229901bd58fb34fc8db82a8feb2d3dcbeac0c901ce98378f7e1dec0ff7aea7235c6d822a62b0',310083000,NULL,NULL,'043f03eb05bbfdc6e7c48f94a7ab25821f77701567461fd6f05c72955c6045e2','5f4ef177fec8d251e0bc36fc673b0a2ecdac1e9bf07a1ff0b0eea8180a089877','17145edc4062f0088fbf5850f7aee6753123a5a37a321e1709a244f3b773cd99');
INSERT INTO blocks VALUES(310084,'d15e3c53c8bad6d8a4dcbb870b622505e4dabe8b3d3b7ffac8aa4976cdcefc91fc13c1c1a1700d7417e829310f9826fbc82307636fc3f95bcce561a8dd8f7ea0',310084000,NULL,NULL,'d89cb8329798749f3dd724b4e8aa6fed50d90b745dbe44eac5c256b8b1fbdab7','a5f1ea3b6a3962da0eac11b05cb7bb3021c6c244fd6698b62adb194c6250a621','aa1c28927952f050d806efdb3338c425b5009d6631ff51d4d2984e3785924409');
INSERT INTO blocks VALUES(310085,'464aeb24455523d820981afe0f284487ec0a36b1388182f88388370811c394bc18686bfe2b8429f7d37569070f13e95952e877b7a84000c6c0e769e5e76cf437',310085000,NULL,NULL,'5081d77b00967a2377093de6e85a1c6f4c8d9096995c9c261f726b55aa01cb16','8e4ea72ed66b46f7e8387310775c24af02874efd312f213d68b9c8d3d2a5ddcb','774408ece825bb939774ba3a7d5dccb707c005bf0da26c91712c779e72341565');
INSERT INTO blocks VALUES(310086,'0c1d3e5b62d04ec82124010d58d052a0a2f9dfb71684580d0c5a8d37e286768f5eb4ce31dd4a677bbbf199d47ee843ec864deae51f4b2ca29d765015748b5742',310086000,NULL,NULL,'97fa9e88a85bd3c418613187f0d63a682d00135c2bbc8add633b1f2cb397a6df','e00ce0783caa759aa598578127273e1662bd4266b38fd5d9276aa619cdb41123','0371416adbf2d9f2d09e2ce37e1969c761916499b43a05e8a5b22ea2eb5af1a7');
INSERT INTO blocks VALUES(310087,'799dd8fedf7036eca0b8298ac48c295690d12f9c71aa98727c927a6cb0224c62433ab878dff483f6d2754bde36f06fce594bdb06559c1d1a0a51848bfb395419',310087000,NULL,NULL,'a060b83f15068d8eb40ffdd6e87a92b505e45c76e559351e8a4067b338d58b0e','f8f81f27afcb180bfdba8871eb729bfa28f2d44f5a8c5cd4e0f4ffc8c1827157','0b6a395d6de6ee3acfae27d7a8db8bb86a50fd2c52a98d73179d51ab02061ada');
INSERT INTO blocks VALUES(310088,'8e1e809b86f3fbde2cabe6510052084ec68d7857c34f8dd334c99e8aeecf32ac1669f2789aa41acf3f33119c5d0aeafed03d8288765c178174a8db27887c22aa',310088000,NULL,NULL,'d59defe063e13cb06084e22df43c5b7f087a557b5ce476aa650d0e85766283ca','66e629b948d50e337deb484f04019cbce0b63ee49ad38e632ece57aeac7fccbb','0c3de9469a4950857cc8c39dbaa609d0c7789f10b3764151078966ad27358cf0');
INSERT INTO blocks VALUES(310089,'9803c2ce201e643165ba86a8a739ec73a05f29d23237d8d2de56f46f417be665785871d0d36cd3146f999d0252635b9ae8a3dd86f597b1cb59cf6879e116b5be',310089000,NULL,NULL,'87a14b55f40e81c605e22d00f6bd6c91d97b1efa8bb92838b78394df8c6a74e5','1ec449f33508aa9e55648f7a27768a8e178c1d9c7d4e21cf0560eb24d46a2a1d','cf0d51cf1cf2232a200810cf15d1a87e22154f0b468fd672a46040bbf5221640');
INSERT INTO blocks VALUES(310090,'1ea5f2b04b763909ad541951a0d21078be9d08e6bd7a23499ea69fa4ee8a67f02791404da26f6b64ed5bfc0bed66c28e4e98b703d7466f96311c5c838ab6d9c2',310090000,NULL,NULL,'ecf81e18fd4f3d0f02f5ce0e3af0cface22b84e3595ee3126119befd62efbec3','ed8b2b8e883bc9ddb2275441f311e662300859a7f98cbe4e216eda21ed171f15','99e043cebcf70a7bdd664b01f41f7e7519623b82ec7a6f808cbd7fff532316e5');
INSERT INTO blocks VALUES(310091,'09f4ee2e18880732c0ac4f58e012ff8fe9223899aeae5e051c9796439d98570637670e0cf50c0727e3017287f268466368c550fdbd3bd210387615af76c0a515',310091000,NULL,NULL,'e3df34192b7b31ac8b3265cf26dd80fb0fdd6f1529a60d432c1fd1ed19e23bf2','b23035e277ccd66d2f33196ca32a5d0d8e0199e062f6dbaae4b8f6e29aeaaa12','19ab81fa6b1996650ad7c43b6cd486989ea585ba99302b30acbb9ec2c98d55c2');
INSERT INTO blocks VALUES(310092,'ae270aca6bf2998680fd12abfdbd158ee5bfb8131fddbe54f5466c6f7a7ff114517a253f8756e13c2bde73e9b851ad2b24ce06bac2086ce3e240331bae518a2c',310092000,NULL,NULL,'401a5b9d8f01042bc787b601f096d268209cd276f5cde9d526d94b11ddc8f8db','557697db4ef63810d8e6eb1d2e22d6833c976ed980ecdf8509c2be18e5b23d55','b3d53fbfc557f6fc87330b3d9230b7da1b86d33c72d49482868d9902f62b269d');
INSERT INTO blocks VALUES(310093,'2c950816e8a2e9c29fac064891a58465f30a62197864d549f856157c223a1f78f1e39f753e792f64b48c500d77e47602093941df590450d21da55758f81a659d',310093000,NULL,NULL,'9b0ec19d4bf43b50e12bd66b23eeaeb2ce7e223a8245e2dabbc19bd11ce21a40','39217689521da143c01af12850704ffd0a3dd5189471721c3b7bc243ee1e171f','c6997e1fdcfab323072a539ac4f79ff3e6871d54a3066a177f07fe0b054f6b6e');
INSERT INTO blocks VALUES(310094,'c7eda9512bcac5c3b73e17923afdce541011780a51f2f59338bd91f539b223655a64a2680972f32e340a268ee6dca4caf0ea6ed8ad02a3840e5ca7075c6cc69b',310094000,NULL,NULL,'fd27eca7bcf5f096061e892f9a21bb47fa86cdb32ba67562e3f34ab8e68a6627','61b185ba2d437347c70d02bf20db0e74cf2fe2ccd6f3167eff6c08f5d398b8c4','bbb07da1ab4b18cbbdb3d0537d396a2ef107fc67e385a759a0f1dc5f069c0998');
INSERT INTO blocks VALUES(310095,'4ff3aa594932ca9e13370bd1a9fcaf0d07dcd6c28949afda5fff201a876e77331c483f93c8fc7295d3c8eb0d4ed3d4f53d062e17e87789392db93bec453cf1d2',310095000,NULL,NULL,'ddf9fe363dfa3f851d6b662e42551c6f3d3b05a864758457a6cc22d15304e728','698a7755897c983c5463af8355f76b128659a1bb609ac6301b5315fee043aad8','4d52876651a10396e9ef7f0b32f974f73dbdcbf7f8ee64da919c63177f30f26c');
INSERT INTO blocks VALUES(310096,'7f6ebf5b7e09d78febea9dce370ca98e1a00cd911b6ee8b4c1f46c3ee5e54754040ae2e5443d5e53ff2af3b615b08063111b4876e034ef31c9ec0f5e75695772',310096000,NULL,NULL,'e9e5d3d557faa26dbb23f06cf8ac907507b4aa9d128336da36efdefb36e63554','4ac07c9f3e0710d92edfef6520c7887b505379cc45466a61f7d9a6ed37d4dcf8','0fef5c722ea5fca8f346c972b89a48d96e677e37a2084b37fcdbee50d18561d4');
INSERT INTO blocks VALUES(310097,'e44698e52e70ebb58d3d004f8eb4943aada1835e5ae673ae54f5a62231df0f0fc3a68ece57823e624b4f365ce199d50e35ec15619e508f8cbf71134d82facefb',310097000,NULL,NULL,'9123fe1a8c4b45012a5f5927dfc4ec4aa4bd9a16604ff3344ae95b1a394a85be','f8dd175a04f858cba89a2b341a6702e3cd2359555b9b87a0d1dc885d76dc8e64','0ecd253956a6dc7c71e6a5d36de6c034ea1d0f422eeda585703e2849360b9dd2');
INSERT INTO blocks VALUES(310098,'031441b70e39a3d6dcf5a532eddb405d5abd8d723029ca8be3cfe400f0e4fb012a63d859e610eb48c7e41c4e80768e877321e92f8ff406e700d8c161e8a3f4d2',310098000,NULL,NULL,'811a5c61947f9d9e29aa5e33457c0a5df1f422f8383d98d684b517a0a92f3423','da66f58913f0c93b564d64b738f2f9d83063c2d9fb87862411116d2dfd151098','9dd7ec77252bf66c5a3d3614408be1f4a708bb02d82777bc2214aa36fbddc80e');
INSERT INTO blocks VALUES(310099,'2456675ed07aaa79602718040e1f29e546938bec8a15b26492dbfd58d5388ea21ff3440ff29138f4e2cfb47662ea3e4e50476f7280c0e58b51b53bc08c014fc2',310099000,NULL,NULL,'527eebfb2c994343387ce3caffabca67fb478bce80b516f27474a142d65f68f7','4ae2675d40f21e0253e54b6a86b40ed84fc30fcdb7234d4273caa44f467a2bf1','e3876bb9d27c74d3e5425e68eee4708d3698a9bbbecd231cde434ed4ec67acd9');
INSERT INTO blocks VALUES(310100,'b9b9a79de83063df4410925030cc3710aad6999f8ca9955305b477dda2e3777293c7ddd7c4eb6e9c3f2aec2e23e2415d0037dfcaf61a52b351ca564f2cf1556d',310100000,NULL,NULL,'d18b36c9a523c84365b561f8747b9469091a2af6055ec8605c9f07402bb9c131','36e3f20ac4bc2d3a2074823d11cf86d026c64222e208abb9045fb36849e20862','b868b165e1f042532dfd199bf3ddfec9ac3fe1296de096bb088c34c09d044329');
INSERT INTO blocks VALUES(310101,'e8a8ebd85a460cf5987683360a1c77e6728b4e59027220f8eceda05c720bc38c91f6193bc43739da026cd28f340e1a10b9900bfa3eed11f88339147c61b65504',310101000,NULL,NULL,'9ef1ea46847b94d3ba16b2f62b2cccb5d2813f8e58d26ac2952e914f8d75f89e','480800d405d0139757ec7909026e98d7af22ae81ffe2a3ee9b096635dd137d21','77db64f873932f3f75787a9a829c911cc593310d39e6a9dff90c8245fccd872d');
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
INSERT INTO broadcasts VALUES(12,'168b0c4059ca939b80dc4c8d7af2777f81e580df6d2ea476e7961c51d7eb2993',310011,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000000,100.0,99999999,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(19,'2cd827a7d27adf046e9735abaad1d376ad7ef1f8fad1a10e44a691f9ddc3957b',310018,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000050,99.86166,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(20,'bd43db240fc7d12dcf355a246c260a7baf2ccd0935ebda51c728b30072e4f420',310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000101,100.343,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(21,'7901472b8045571531191f34980d497f1793c806718b9cfdbbba656b641852d6',310020,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000201,2.0,5000000,'Unit Test',0,'valid');
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
INSERT INTO btcpays VALUES(5,'69f56e706e73bd62dfcbe113744432bee5f2af57933b720d9dd72fef53ccfbf3',310004,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',50000000,'ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a_833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a','valid');
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
INSERT INTO burns VALUES(1,'610b15f0c2d3845f124cc6026b6c212033de94218b25f89d5dbde47d11085a89',310000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',62000000,93000000000,'valid');
INSERT INTO burns VALUES(23,'6d1a0e0dedda4a78cf11ac7a1c6fd2c32d9fd7c99d97ae7d524f223641646b85',310022,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',38000000,56999887262,'valid');
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
INSERT INTO credits VALUES(310000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',93000000000,'burn','610b15f0c2d3845f124cc6026b6c212033de94218b25f89d5dbde47d11085a89');
INSERT INTO credits VALUES(310001,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',50000000,'send','72928dacb4dc84a6b9ebf9f43ea2a9ab8791f7ffa8e94a5c38b05d7cfd4a5c3f');
INSERT INTO credits VALUES(310004,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'btcpay','69f56e706e73bd62dfcbe113744432bee5f2af57933b720d9dd72fef53ccfbf3');
INSERT INTO credits VALUES(310005,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',1000000000,'issuance','81972e1b6d68a5b857edf2a874805ca26013c7d5cf6d186a4bbd35699545b52a');
INSERT INTO credits VALUES(310006,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC',100000,'issuance','d7ab55e6bd9d4c60143d68db9ef75c6d7cb72b5a73f196c356a76b3f3849da83');
INSERT INTO credits VALUES(310007,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBB',4000000,'send','a5e00545ea476f6ce3fad4fcd0a18faceef4bea400d1132f450796c1112295ce');
INSERT INTO credits VALUES(310008,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',526,'send','623aa2a13bd21853e263e41767fc7ce91c2e938d5a175400e807102924f4921e');
INSERT INTO credits VALUES(310009,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',24,'dividend','dda46f3ab92292e4ce918567ebc2c83e0a3707d78a07acb86517cf936f78638c');
INSERT INTO credits VALUES(310010,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',420800,'dividend','5995ba45f8db07202fb542aaac7bd6b9224091764295034e8cf68d2752824d87');
INSERT INTO credits VALUES(310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',4250000,'filled','edd28543ae87ae56f5bd55437cab05f7f4d8a1709cb12e139dab176eb5f7e74a');
INSERT INTO credits VALUES(310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',5000000,'cancel order','833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a');
INSERT INTO credits VALUES(310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67');
INSERT INTO credits VALUES(310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67');
INSERT INTO credits VALUES(310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715');
INSERT INTO credits VALUES(310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715');
INSERT INTO credits VALUES(310018,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',59137500,'bet settled: liquidated for bear','2cd827a7d27adf046e9735abaad1d376ad7ef1f8fad1a10e44a691f9ddc3957b');
INSERT INTO credits VALUES(310018,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',3112500,'feed fee','2cd827a7d27adf046e9735abaad1d376ad7ef1f8fad1a10e44a691f9ddc3957b');
INSERT INTO credits VALUES(310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',159300000,'bet settled','bd43db240fc7d12dcf355a246c260a7baf2ccd0935ebda51c728b30072e4f420');
INSERT INTO credits VALUES(310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',315700000,'bet settled','bd43db240fc7d12dcf355a246c260a7baf2ccd0935ebda51c728b30072e4f420');
INSERT INTO credits VALUES(310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',25000000,'feed fee','bd43db240fc7d12dcf355a246c260a7baf2ccd0935ebda51c728b30072e4f420');
INSERT INTO credits VALUES(310020,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',1330000000,'bet settled: for notequal','7901472b8045571531191f34980d497f1793c806718b9cfdbbba656b641852d6');
INSERT INTO credits VALUES(310020,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',70000000,'feed fee','7901472b8045571531191f34980d497f1793c806718b9cfdbbba656b641852d6');
INSERT INTO credits VALUES(310022,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',56999887262,'burn','6d1a0e0dedda4a78cf11ac7a1c6fd2c32d9fd7c99d97ae7d524f223641646b85');
INSERT INTO credits VALUES(310023,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',8500000,'recredit wager remaining','5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a');
INSERT INTO credits VALUES(310023,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',10000,'send','a40605acb5b55718ba35b408883c20eecd845425ec463c0720b57901585820e2');
INSERT INTO credits VALUES(310032,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',50000000,'cancel order','38d5ec6c73a559b1d1409e0506e2bec30b7db9fd6ca385f2b50202ede6cede56');
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
INSERT INTO debits VALUES(310001,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'send','72928dacb4dc84a6b9ebf9f43ea2a9ab8791f7ffa8e94a5c38b05d7cfd4a5c3f');
INSERT INTO debits VALUES(310003,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',105000000,'open order','833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a');
INSERT INTO debits VALUES(310005,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','81972e1b6d68a5b857edf2a874805ca26013c7d5cf6d186a4bbd35699545b52a');
INSERT INTO debits VALUES(310006,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','d7ab55e6bd9d4c60143d68db9ef75c6d7cb72b5a73f196c356a76b3f3849da83');
INSERT INTO debits VALUES(310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',4000000,'send','a5e00545ea476f6ce3fad4fcd0a18faceef4bea400d1132f450796c1112295ce');
INSERT INTO debits VALUES(310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC',526,'send','623aa2a13bd21853e263e41767fc7ce91c2e938d5a175400e807102924f4921e');
INSERT INTO debits VALUES(310009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',24,'dividend','dda46f3ab92292e4ce918567ebc2c83e0a3707d78a07acb86517cf936f78638c');
INSERT INTO debits VALUES(310009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',20000,'dividend fee','dda46f3ab92292e4ce918567ebc2c83e0a3707d78a07acb86517cf936f78638c');
INSERT INTO debits VALUES(310010,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',420800,'dividend','5995ba45f8db07202fb542aaac7bd6b9224091764295034e8cf68d2752824d87');
INSERT INTO debits VALUES(310010,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',20000,'dividend fee','5995ba45f8db07202fb542aaac7bd6b9224091764295034e8cf68d2752824d87');
INSERT INTO debits VALUES(310012,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'bet','5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a');
INSERT INTO debits VALUES(310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',25000000,'bet','edd28543ae87ae56f5bd55437cab05f7f4d8a1709cb12e139dab176eb5f7e74a');
INSERT INTO debits VALUES(310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',150000000,'bet','bc42268279947c6dd5a517df41ae838c22c7194c686180700d8087dc3c8ce36c');
INSERT INTO debits VALUES(310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',350000000,'bet','faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67');
INSERT INTO debits VALUES(310016,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',750000000,'bet','0bedbaab766013a9381fee7cf956cb5a93eda3df67762633c7427706bbd3349d');
INSERT INTO debits VALUES(310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',650000000,'bet','864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715');
INSERT INTO debits VALUES(310021,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',50000000,'open order','38d5ec6c73a559b1d1409e0506e2bec30b7db9fd6ca385f2b50202ede6cede56');
INSERT INTO debits VALUES(310023,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC',10000,'send','a40605acb5b55718ba35b408883c20eecd845425ec463c0720b57901585820e2');
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
INSERT INTO dividends VALUES(10,'dda46f3ab92292e4ce918567ebc2c83e0a3707d78a07acb86517cf936f78638c',310009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB','XCP',600,20000,'valid');
INSERT INTO dividends VALUES(11,'5995ba45f8db07202fb542aaac7bd6b9224091764295034e8cf68d2752824d87',310010,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC','XCP',800,20000,'valid');
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
INSERT INTO issuances VALUES(6,'81972e1b6d68a5b857edf2a874805ca26013c7d5cf6d186a4bbd35699545b52a',310005,'BBBB',1000000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'',50000000,0,'valid');
INSERT INTO issuances VALUES(7,'d7ab55e6bd9d4c60143d68db9ef75c6d7cb72b5a73f196c356a76b3f3849da83',310006,'BBBC',100000,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'foobar',50000000,0,'valid');
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
INSERT INTO messages VALUES(0,310000,'insert','credits','{"action": "burn", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310000, "event": "610b15f0c2d3845f124cc6026b6c212033de94218b25f89d5dbde47d11085a89", "quantity": 93000000000}',0);
INSERT INTO messages VALUES(1,310000,'insert','burns','{"block_index": 310000, "burned": 62000000, "earned": 93000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "610b15f0c2d3845f124cc6026b6c212033de94218b25f89d5dbde47d11085a89", "tx_index": 1}',0);
INSERT INTO messages VALUES(2,310001,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310001, "event": "72928dacb4dc84a6b9ebf9f43ea2a9ab8791f7ffa8e94a5c38b05d7cfd4a5c3f", "quantity": 50000000}',0);
INSERT INTO messages VALUES(3,310001,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310001, "event": "72928dacb4dc84a6b9ebf9f43ea2a9ab8791f7ffa8e94a5c38b05d7cfd4a5c3f", "quantity": 50000000}',0);
INSERT INTO messages VALUES(4,310001,'insert','sends','{"asset": "XCP", "block_index": 310001, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 50000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "72928dacb4dc84a6b9ebf9f43ea2a9ab8791f7ffa8e94a5c38b05d7cfd4a5c3f", "tx_index": 2}',0);
INSERT INTO messages VALUES(5,310002,'insert','orders','{"block_index": 310002, "expiration": 10, "expire_index": 310012, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 50000000, "give_remaining": 50000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a", "tx_index": 3}',0);
INSERT INTO messages VALUES(6,310003,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310003, "event": "833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a", "quantity": 105000000}',0);
INSERT INTO messages VALUES(7,310003,'insert','orders','{"block_index": 310003, "expiration": 10, "expire_index": 310013, "fee_provided": 10000, "fee_provided_remaining": 10000, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 50000000, "get_remaining": 50000000, "give_asset": "XCP", "give_quantity": 105000000, "give_remaining": 105000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a", "tx_index": 4}',0);
INSERT INTO messages VALUES(8,310003,'update','orders','{"fee_provided_remaining": 142858, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a"}',0);
INSERT INTO messages VALUES(9,310003,'update','orders','{"fee_provided_remaining": 10000, "fee_required_remaining": 42858, "get_remaining": 0, "give_remaining": 5000000, "status": "open", "tx_hash": "833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a"}',0);
INSERT INTO messages VALUES(10,310003,'insert','order_matches','{"backward_asset": "XCP", "backward_quantity": 100000000, "block_index": 310003, "fee_paid": 857142, "forward_asset": "BTC", "forward_quantity": 50000000, "id": "ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a_833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a", "match_expire_index": 310023, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 310002, "tx0_expiration": 10, "tx0_hash": "ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a", "tx0_index": 3, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_block_index": 310003, "tx1_expiration": 10, "tx1_hash": "833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a", "tx1_index": 4}',0);
INSERT INTO messages VALUES(11,310004,'insert','credits','{"action": "btcpay", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310004, "event": "69f56e706e73bd62dfcbe113744432bee5f2af57933b720d9dd72fef53ccfbf3", "quantity": 100000000}',0);
INSERT INTO messages VALUES(12,310004,'update','order_matches','{"order_match_id": "ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a_833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a", "status": "completed"}',0);
INSERT INTO messages VALUES(13,310004,'insert','btcpays','{"block_index": 310004, "btc_amount": 50000000, "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "order_match_id": "ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a_833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a", "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "69f56e706e73bd62dfcbe113744432bee5f2af57933b720d9dd72fef53ccfbf3", "tx_index": 5}',0);
INSERT INTO messages VALUES(14,310005,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310005, "event": "81972e1b6d68a5b857edf2a874805ca26013c7d5cf6d186a4bbd35699545b52a", "quantity": 50000000}',0);
INSERT INTO messages VALUES(15,310005,'insert','issuances','{"asset": "BBBB", "block_index": 310005, "call_date": 0, "call_price": 0.0, "callable": false, "description": "", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "81972e1b6d68a5b857edf2a874805ca26013c7d5cf6d186a4bbd35699545b52a", "tx_index": 6}',0);
INSERT INTO messages VALUES(16,310005,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBB", "block_index": 310005, "event": "81972e1b6d68a5b857edf2a874805ca26013c7d5cf6d186a4bbd35699545b52a", "quantity": 1000000000}',0);
INSERT INTO messages VALUES(17,310006,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310006, "event": "d7ab55e6bd9d4c60143d68db9ef75c6d7cb72b5a73f196c356a76b3f3849da83", "quantity": 50000000}',0);
INSERT INTO messages VALUES(18,310006,'insert','issuances','{"asset": "BBBC", "block_index": 310006, "call_date": 0, "call_price": 0.0, "callable": false, "description": "foobar", "divisible": false, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "d7ab55e6bd9d4c60143d68db9ef75c6d7cb72b5a73f196c356a76b3f3849da83", "tx_index": 7}',0);
INSERT INTO messages VALUES(19,310006,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBC", "block_index": 310006, "event": "d7ab55e6bd9d4c60143d68db9ef75c6d7cb72b5a73f196c356a76b3f3849da83", "quantity": 100000}',0);
INSERT INTO messages VALUES(20,310007,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBB", "block_index": 310007, "event": "a5e00545ea476f6ce3fad4fcd0a18faceef4bea400d1132f450796c1112295ce", "quantity": 4000000}',0);
INSERT INTO messages VALUES(21,310007,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "BBBB", "block_index": 310007, "event": "a5e00545ea476f6ce3fad4fcd0a18faceef4bea400d1132f450796c1112295ce", "quantity": 4000000}',0);
INSERT INTO messages VALUES(22,310007,'insert','sends','{"asset": "BBBB", "block_index": 310007, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 4000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "a5e00545ea476f6ce3fad4fcd0a18faceef4bea400d1132f450796c1112295ce", "tx_index": 8}',0);
INSERT INTO messages VALUES(23,310008,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBC", "block_index": 310008, "event": "623aa2a13bd21853e263e41767fc7ce91c2e938d5a175400e807102924f4921e", "quantity": 526}',0);
INSERT INTO messages VALUES(24,310008,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "BBBC", "block_index": 310008, "event": "623aa2a13bd21853e263e41767fc7ce91c2e938d5a175400e807102924f4921e", "quantity": 526}',0);
INSERT INTO messages VALUES(25,310008,'insert','sends','{"asset": "BBBC", "block_index": 310008, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 526, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "623aa2a13bd21853e263e41767fc7ce91c2e938d5a175400e807102924f4921e", "tx_index": 9}',0);
INSERT INTO messages VALUES(26,310009,'insert','debits','{"action": "dividend", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310009, "event": "dda46f3ab92292e4ce918567ebc2c83e0a3707d78a07acb86517cf936f78638c", "quantity": 24}',0);
INSERT INTO messages VALUES(27,310009,'insert','debits','{"action": "dividend fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310009, "event": "dda46f3ab92292e4ce918567ebc2c83e0a3707d78a07acb86517cf936f78638c", "quantity": 20000}',0);
INSERT INTO messages VALUES(28,310009,'insert','credits','{"action": "dividend", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310009, "event": "dda46f3ab92292e4ce918567ebc2c83e0a3707d78a07acb86517cf936f78638c", "quantity": 24}',0);
INSERT INTO messages VALUES(29,310009,'insert','dividends','{"asset": "BBBB", "block_index": 310009, "dividend_asset": "XCP", "fee_paid": 20000, "quantity_per_unit": 600, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "dda46f3ab92292e4ce918567ebc2c83e0a3707d78a07acb86517cf936f78638c", "tx_index": 10}',0);
INSERT INTO messages VALUES(30,310010,'insert','debits','{"action": "dividend", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310010, "event": "5995ba45f8db07202fb542aaac7bd6b9224091764295034e8cf68d2752824d87", "quantity": 420800}',0);
INSERT INTO messages VALUES(31,310010,'insert','debits','{"action": "dividend fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310010, "event": "5995ba45f8db07202fb542aaac7bd6b9224091764295034e8cf68d2752824d87", "quantity": 20000}',0);
INSERT INTO messages VALUES(32,310010,'insert','credits','{"action": "dividend", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310010, "event": "5995ba45f8db07202fb542aaac7bd6b9224091764295034e8cf68d2752824d87", "quantity": 420800}',0);
INSERT INTO messages VALUES(33,310010,'insert','dividends','{"asset": "BBBC", "block_index": 310010, "dividend_asset": "XCP", "fee_paid": 20000, "quantity_per_unit": 800, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "5995ba45f8db07202fb542aaac7bd6b9224091764295034e8cf68d2752824d87", "tx_index": 11}',0);
INSERT INTO messages VALUES(34,310011,'insert','broadcasts','{"block_index": 310011, "fee_fraction_int": 99999999, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "168b0c4059ca939b80dc4c8d7af2777f81e580df6d2ea476e7961c51d7eb2993", "tx_index": 12, "value": 100.0}',0);
INSERT INTO messages VALUES(35,310012,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310012, "event": "5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a", "quantity": 50000000}',0);
INSERT INTO messages VALUES(36,310012,'insert','bets','{"bet_type": 0, "block_index": 310012, "counterwager_quantity": 25000000, "counterwager_remaining": 25000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310022, "fee_fraction_int": 99999999.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 15120, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a", "tx_index": 13, "wager_quantity": 50000000, "wager_remaining": 50000000}',0);
INSERT INTO messages VALUES(37,310013,'update','orders','{"status": "expired", "tx_hash": "ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a"}',0);
INSERT INTO messages VALUES(38,310013,'insert','order_expirations','{"block_index": 310013, "order_hash": "ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a", "order_index": 3, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
INSERT INTO messages VALUES(39,310013,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310013, "event": "edd28543ae87ae56f5bd55437cab05f7f4d8a1709cb12e139dab176eb5f7e74a", "quantity": 25000000}',0);
INSERT INTO messages VALUES(40,310013,'insert','bets','{"bet_type": 1, "block_index": 310013, "counterwager_quantity": 41500000, "counterwager_remaining": 41500000, "deadline": 1388000100, "expiration": 10, "expire_index": 310023, "fee_fraction_int": 99999999.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 15120, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "edd28543ae87ae56f5bd55437cab05f7f4d8a1709cb12e139dab176eb5f7e74a", "tx_index": 14, "wager_quantity": 25000000, "wager_remaining": 25000000}',0);
INSERT INTO messages VALUES(41,310013,'update','bets','{"counterwager_remaining": 4250000, "status": "open", "tx_hash": "5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a", "wager_remaining": 8500000}',0);
INSERT INTO messages VALUES(42,310013,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310013, "event": "edd28543ae87ae56f5bd55437cab05f7f4d8a1709cb12e139dab176eb5f7e74a", "quantity": 4250000}',0);
INSERT INTO messages VALUES(43,310013,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "edd28543ae87ae56f5bd55437cab05f7f4d8a1709cb12e139dab176eb5f7e74a", "wager_remaining": 4250000}',0);
INSERT INTO messages VALUES(44,310013,'insert','bet_matches','{"backward_quantity": 20750000, "block_index": 310013, "deadline": 1388000100, "fee_fraction_int": 99999999, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 41500000, "id": "5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a_edd28543ae87ae56f5bd55437cab05f7f4d8a1709cb12e139dab176eb5f7e74a", "initial_value": 100.0, "leverage": 15120, "match_expire_index": 310022, "status": "pending", "target_value": 0.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 0, "tx0_block_index": 310012, "tx0_expiration": 10, "tx0_hash": "5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a", "tx0_index": 13, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_bet_type": 1, "tx1_block_index": 310013, "tx1_expiration": 10, "tx1_hash": "edd28543ae87ae56f5bd55437cab05f7f4d8a1709cb12e139dab176eb5f7e74a", "tx1_index": 14}',0);
INSERT INTO messages VALUES(45,310014,'update','orders','{"status": "expired", "tx_hash": "833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a"}',0);
INSERT INTO messages VALUES(46,310014,'insert','credits','{"action": "cancel order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310014, "event": "833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a", "quantity": 5000000}',0);
INSERT INTO messages VALUES(47,310014,'insert','order_expirations','{"block_index": 310014, "order_hash": "833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a", "order_index": 4, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
INSERT INTO messages VALUES(48,310014,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310014, "event": "bc42268279947c6dd5a517df41ae838c22c7194c686180700d8087dc3c8ce36c", "quantity": 150000000}',0);
INSERT INTO messages VALUES(49,310014,'insert','bets','{"bet_type": 0, "block_index": 310014, "counterwager_quantity": 350000000, "counterwager_remaining": 350000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310024, "fee_fraction_int": 99999999.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "bc42268279947c6dd5a517df41ae838c22c7194c686180700d8087dc3c8ce36c", "tx_index": 15, "wager_quantity": 150000000, "wager_remaining": 150000000}',0);
INSERT INTO messages VALUES(50,310015,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310015, "event": "faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67", "quantity": 350000000}',0);
INSERT INTO messages VALUES(51,310015,'insert','bets','{"bet_type": 1, "block_index": 310015, "counterwager_quantity": 150000000, "counterwager_remaining": 150000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310025, "fee_fraction_int": 99999999.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67", "tx_index": 16, "wager_quantity": 350000000, "wager_remaining": 350000000}',0);
INSERT INTO messages VALUES(52,310015,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310015, "event": "faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67", "quantity": 0}',0);
INSERT INTO messages VALUES(53,310015,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "bc42268279947c6dd5a517df41ae838c22c7194c686180700d8087dc3c8ce36c", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(54,310015,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310015, "event": "faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67", "quantity": 0}',0);
INSERT INTO messages VALUES(55,310015,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(56,310015,'insert','bet_matches','{"backward_quantity": 350000000, "block_index": 310015, "deadline": 1388000100, "fee_fraction_int": 99999999, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 150000000, "id": "bc42268279947c6dd5a517df41ae838c22c7194c686180700d8087dc3c8ce36c_faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67", "initial_value": 100.0, "leverage": 5040, "match_expire_index": 310024, "status": "pending", "target_value": 0.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 0, "tx0_block_index": 310014, "tx0_expiration": 10, "tx0_hash": "bc42268279947c6dd5a517df41ae838c22c7194c686180700d8087dc3c8ce36c", "tx0_index": 15, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_bet_type": 1, "tx1_block_index": 310015, "tx1_expiration": 10, "tx1_hash": "faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67", "tx1_index": 16}',0);
INSERT INTO messages VALUES(57,310016,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310016, "event": "0bedbaab766013a9381fee7cf956cb5a93eda3df67762633c7427706bbd3349d", "quantity": 750000000}',0);
INSERT INTO messages VALUES(58,310016,'insert','bets','{"bet_type": 2, "block_index": 310016, "counterwager_quantity": 650000000, "counterwager_remaining": 650000000, "deadline": 1388000200, "expiration": 10, "expire_index": 310026, "fee_fraction_int": 99999999.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 1.0, "tx_hash": "0bedbaab766013a9381fee7cf956cb5a93eda3df67762633c7427706bbd3349d", "tx_index": 17, "wager_quantity": 750000000, "wager_remaining": 750000000}',0);
INSERT INTO messages VALUES(59,310017,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310017, "event": "864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715", "quantity": 650000000}',0);
INSERT INTO messages VALUES(60,310017,'insert','bets','{"bet_type": 3, "block_index": 310017, "counterwager_quantity": 750000000, "counterwager_remaining": 750000000, "deadline": 1388000200, "expiration": 10, "expire_index": 310027, "fee_fraction_int": 99999999.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 1.0, "tx_hash": "864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715", "tx_index": 18, "wager_quantity": 650000000, "wager_remaining": 650000000}',0);
INSERT INTO messages VALUES(61,310017,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310017, "event": "864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715", "quantity": 0}',0);
INSERT INTO messages VALUES(62,310017,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "0bedbaab766013a9381fee7cf956cb5a93eda3df67762633c7427706bbd3349d", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(63,310017,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310017, "event": "864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715", "quantity": 0}',0);
INSERT INTO messages VALUES(64,310017,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(65,310017,'insert','bet_matches','{"backward_quantity": 650000000, "block_index": 310017, "deadline": 1388000200, "fee_fraction_int": 99999999, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 750000000, "id": "0bedbaab766013a9381fee7cf956cb5a93eda3df67762633c7427706bbd3349d_864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715", "initial_value": 100.0, "leverage": 5040, "match_expire_index": 310026, "status": "pending", "target_value": 1.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 2, "tx0_block_index": 310016, "tx0_expiration": 10, "tx0_hash": "0bedbaab766013a9381fee7cf956cb5a93eda3df67762633c7427706bbd3349d", "tx0_index": 17, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_bet_type": 3, "tx1_block_index": 310017, "tx1_expiration": 10, "tx1_hash": "864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715", "tx1_index": 18}',0);
INSERT INTO messages VALUES(66,310018,'insert','broadcasts','{"block_index": 310018, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000050, "tx_hash": "2cd827a7d27adf046e9735abaad1d376ad7ef1f8fad1a10e44a691f9ddc3957b", "tx_index": 19, "value": 99.86166}',0);
INSERT INTO messages VALUES(67,310018,'insert','credits','{"action": "bet settled: liquidated for bear", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310018, "event": "2cd827a7d27adf046e9735abaad1d376ad7ef1f8fad1a10e44a691f9ddc3957b", "quantity": 59137500}',0);
INSERT INTO messages VALUES(68,310018,'insert','credits','{"action": "feed fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310018, "event": "2cd827a7d27adf046e9735abaad1d376ad7ef1f8fad1a10e44a691f9ddc3957b", "quantity": 3112500}',0);
INSERT INTO messages VALUES(69,310018,'insert','bet_match_resolutions','{"bear_credit": 59137500, "bet_match_id": "5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a_edd28543ae87ae56f5bd55437cab05f7f4d8a1709cb12e139dab176eb5f7e74a", "bet_match_type_id": 1, "block_index": 310018, "bull_credit": 0, "escrow_less_fee": null, "fee": 3112500, "settled": false, "winner": null}',0);
INSERT INTO messages VALUES(70,310018,'update','bet_matches','{"bet_match_id": "5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a_edd28543ae87ae56f5bd55437cab05f7f4d8a1709cb12e139dab176eb5f7e74a", "status": "settled: liquidated for bear"}',0);
INSERT INTO messages VALUES(71,310019,'insert','broadcasts','{"block_index": 310019, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000101, "tx_hash": "bd43db240fc7d12dcf355a246c260a7baf2ccd0935ebda51c728b30072e4f420", "tx_index": 20, "value": 100.343}',0);
INSERT INTO messages VALUES(72,310019,'insert','credits','{"action": "bet settled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310019, "event": "bd43db240fc7d12dcf355a246c260a7baf2ccd0935ebda51c728b30072e4f420", "quantity": 159300000}',0);
INSERT INTO messages VALUES(73,310019,'insert','credits','{"action": "bet settled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310019, "event": "bd43db240fc7d12dcf355a246c260a7baf2ccd0935ebda51c728b30072e4f420", "quantity": 315700000}',0);
INSERT INTO messages VALUES(74,310019,'insert','credits','{"action": "feed fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310019, "event": "bd43db240fc7d12dcf355a246c260a7baf2ccd0935ebda51c728b30072e4f420", "quantity": 25000000}',0);
INSERT INTO messages VALUES(75,310019,'insert','bet_match_resolutions','{"bear_credit": 315700000, "bet_match_id": "bc42268279947c6dd5a517df41ae838c22c7194c686180700d8087dc3c8ce36c_faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67", "bet_match_type_id": 1, "block_index": 310019, "bull_credit": 159300000, "escrow_less_fee": null, "fee": 25000000, "settled": true, "winner": null}',0);
INSERT INTO messages VALUES(76,310019,'update','bet_matches','{"bet_match_id": "bc42268279947c6dd5a517df41ae838c22c7194c686180700d8087dc3c8ce36c_faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67", "status": "settled"}',0);
INSERT INTO messages VALUES(77,310020,'insert','broadcasts','{"block_index": 310020, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000201, "tx_hash": "7901472b8045571531191f34980d497f1793c806718b9cfdbbba656b641852d6", "tx_index": 21, "value": 2.0}',0);
INSERT INTO messages VALUES(78,310020,'insert','credits','{"action": "bet settled: for notequal", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310020, "event": "7901472b8045571531191f34980d497f1793c806718b9cfdbbba656b641852d6", "quantity": 1330000000}',0);
INSERT INTO messages VALUES(79,310020,'insert','credits','{"action": "feed fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310020, "event": "7901472b8045571531191f34980d497f1793c806718b9cfdbbba656b641852d6", "quantity": 70000000}',0);
INSERT INTO messages VALUES(80,310020,'insert','bet_match_resolutions','{"bear_credit": null, "bet_match_id": "0bedbaab766013a9381fee7cf956cb5a93eda3df67762633c7427706bbd3349d_864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715", "bet_match_type_id": 5, "block_index": 310020, "bull_credit": null, "escrow_less_fee": 1330000000, "fee": 70000000, "settled": null, "winner": "NotEqual"}',0);
INSERT INTO messages VALUES(81,310020,'update','bet_matches','{"bet_match_id": "0bedbaab766013a9381fee7cf956cb5a93eda3df67762633c7427706bbd3349d_864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715", "status": "settled: for notequal"}',0);
INSERT INTO messages VALUES(82,310021,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBB", "block_index": 310021, "event": "38d5ec6c73a559b1d1409e0506e2bec30b7db9fd6ca385f2b50202ede6cede56", "quantity": 50000000}',0);
INSERT INTO messages VALUES(83,310021,'insert','orders','{"block_index": 310021, "expiration": 10, "expire_index": 310031, "fee_provided": 10000, "fee_provided_remaining": 10000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 50000000, "get_remaining": 50000000, "give_asset": "BBBB", "give_quantity": 50000000, "give_remaining": 50000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "38d5ec6c73a559b1d1409e0506e2bec30b7db9fd6ca385f2b50202ede6cede56", "tx_index": 22}',0);
INSERT INTO messages VALUES(84,310022,'insert','credits','{"action": "burn", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310022, "event": "6d1a0e0dedda4a78cf11ac7a1c6fd2c32d9fd7c99d97ae7d524f223641646b85", "quantity": 56999887262}',0);
INSERT INTO messages VALUES(85,310022,'insert','burns','{"block_index": 310022, "burned": 38000000, "earned": 56999887262, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "6d1a0e0dedda4a78cf11ac7a1c6fd2c32d9fd7c99d97ae7d524f223641646b85", "tx_index": 23}',0);
INSERT INTO messages VALUES(86,310023,'update','bets','{"status": "expired", "tx_hash": "5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a"}',0);
INSERT INTO messages VALUES(87,310023,'insert','credits','{"action": "recredit wager remaining", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310023, "event": "5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a", "quantity": 8500000}',0);
INSERT INTO messages VALUES(88,310023,'insert','bet_expirations','{"bet_hash": "5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a", "bet_index": 13, "block_index": 310023, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
INSERT INTO messages VALUES(89,310023,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBC", "block_index": 310023, "event": "a40605acb5b55718ba35b408883c20eecd845425ec463c0720b57901585820e2", "quantity": 10000}',0);
INSERT INTO messages VALUES(90,310023,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "BBBC", "block_index": 310023, "event": "a40605acb5b55718ba35b408883c20eecd845425ec463c0720b57901585820e2", "quantity": 10000}',0);
INSERT INTO messages VALUES(91,310023,'insert','sends','{"asset": "BBBC", "block_index": 310023, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 10000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "a40605acb5b55718ba35b408883c20eecd845425ec463c0720b57901585820e2", "tx_index": 24}',0);
INSERT INTO messages VALUES(92,310032,'update','orders','{"status": "expired", "tx_hash": "38d5ec6c73a559b1d1409e0506e2bec30b7db9fd6ca385f2b50202ede6cede56"}',0);
INSERT INTO messages VALUES(93,310032,'insert','credits','{"action": "cancel order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBB", "block_index": 310032, "event": "38d5ec6c73a559b1d1409e0506e2bec30b7db9fd6ca385f2b50202ede6cede56", "quantity": 50000000}',0);
INSERT INTO messages VALUES(94,310032,'insert','order_expirations','{"block_index": 310032, "order_hash": "38d5ec6c73a559b1d1409e0506e2bec30b7db9fd6ca385f2b50202ede6cede56", "order_index": 22, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
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
INSERT INTO order_expirations VALUES(3,'ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',310013);
INSERT INTO order_expirations VALUES(4,'833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',310014);
INSERT INTO order_expirations VALUES(22,'38d5ec6c73a559b1d1409e0506e2bec30b7db9fd6ca385f2b50202ede6cede56','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',310032);
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
INSERT INTO order_matches VALUES('ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a_833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a',3,'ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',4,'833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BTC',50000000,'XCP',100000000,310002,310003,310003,10,10,310023,857142,'completed');
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
INSERT INTO orders VALUES(3,'ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a',310002,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BTC',50000000,0,'XCP',100000000,0,10,310012,0,0,1000000,142858,'expired');
INSERT INTO orders VALUES(4,'833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a',310003,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',105000000,5000000,'BTC',50000000,0,10,310013,900000,42858,10000,10000,'expired');
INSERT INTO orders VALUES(22,'38d5ec6c73a559b1d1409e0506e2bec30b7db9fd6ca385f2b50202ede6cede56',310021,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',50000000,50000000,'XCP',50000000,50000000,10,310031,0,0,10000,10000,'expired');
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
INSERT INTO sends VALUES(2,'72928dacb4dc84a6b9ebf9f43ea2a9ab8791f7ffa8e94a5c38b05d7cfd4a5c3f',310001,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',50000000,'valid');
INSERT INTO sends VALUES(8,'a5e00545ea476f6ce3fad4fcd0a18faceef4bea400d1132f450796c1112295ce',310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBB',4000000,'valid');
INSERT INTO sends VALUES(9,'623aa2a13bd21853e263e41767fc7ce91c2e938d5a175400e807102924f4921e',310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',526,'valid');
INSERT INTO sends VALUES(24,'a40605acb5b55718ba35b408883c20eecd845425ec463c0720b57901585820e2',310023,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',10000,'valid');
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
INSERT INTO transactions VALUES(1,'610b15f0c2d3845f124cc6026b6c212033de94218b25f89d5dbde47d11085a89',310000,'2ee5123266f21fb8f65495c281a368e1b9f93b6c411986e06efc895a8d82467683e6ea5d863714b23582c1c59576650d07c405a8d9bf0d088ee65621178b259d',310000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,10000,X'',1);
INSERT INTO transactions VALUES(2,'72928dacb4dc84a6b9ebf9f43ea2a9ab8791f7ffa8e94a5c38b05d7cfd4a5c3f',310001,'03a9a24e190a996364217761558e380b94ae9792b8b4dcaa92b6c58d80b9f8f7fcf9a34037be4cd6ad5e0c039b511cccc40c3438a5067822e3cd309f06519612',310001000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,10000,X'0000000000000000000000010000000002FAF080',1);
INSERT INTO transactions VALUES(3,'ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a',310002,'d574e4fee71454532c0207f27b9c46f07c5c2e20f43829ddeee8f798053413ac6e0d1b9ad2259a0370fe08581fab3e950ce629db5fadd823251254bf606a05bd',310002000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,1000000,X'0000000A00000000000000000000000002FAF08000000000000000010000000005F5E100000A0000000000000000',1);
INSERT INTO transactions VALUES(4,'833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a',310003,'44392d9d661459ba31140c59e7d8bcd16b071c864c59f65e2edd9e3c16d598e81aaba40f11019a379bfc6d7811e0265fbb8b276d99cdea7f739fb736f433052a',310003000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000000A00000000000000010000000006422C4000000000000000000000000002FAF080000A00000000000DBBA0',1);
INSERT INTO transactions VALUES(5,'69f56e706e73bd62dfcbe113744432bee5f2af57933b720d9dd72fef53ccfbf3',310004,'58c6f6fbf77a64a5e0df123b1258ae6c3e6d4e21901cc942aeb67b1332422c71e1e7e996c5d4f403159ce5ca3863b7ec7ef8281bbbce5960e258492872055fb5',310004000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',50000000,10000,X'0000000BAD6082998925F47865B58B6D344C1B1CF0AB059D091F33334CCB92436F37EB8A833AC1C9139ACC7A9AAABBF04BDF3E4AF95A3425762D39D8CC2CC23113861D2A',1);
INSERT INTO transactions VALUES(6,'81972e1b6d68a5b857edf2a874805ca26013c7d5cf6d186a4bbd35699545b52a',310005,'348a1b690661597ee6e950446e7a1deb8bef7906c0e98a78ab4d0fe799fac5f3007dcd648ff0c61da35b19cf99f16f3028e10ba206968475d741fa8a86c4a7ae',310005000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'000000140000000000004767000000003B9ACA000100000000000000000000',1);
INSERT INTO transactions VALUES(7,'d7ab55e6bd9d4c60143d68db9ef75c6d7cb72b5a73f196c356a76b3f3849da83',310006,'9d31b774b633c35635b71669c07880b521880cee9298b6aba44752ec1734cd2aa26b3bed95409d874e68685636a31a038b784d3e085525ab8c26f7e3b7ba3676',310006000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'00000014000000000000476800000000000186A00000000000000000000006666F6F626172',1);
INSERT INTO transactions VALUES(8,'a5e00545ea476f6ce3fad4fcd0a18faceef4bea400d1132f450796c1112295ce',310007,'41007a4ed39e7df941059c3db6b24b74c1913b80e0fd38d0073a5b121880fd0f7e98989d8d70766957919371fdaf4e5b44125f9f7c449c3b6bea298253075fe3',310007000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,10000,X'00000000000000000000476700000000003D0900',1);
INSERT INTO transactions VALUES(9,'623aa2a13bd21853e263e41767fc7ce91c2e938d5a175400e807102924f4921e',310008,'aa28e5948d1158f318393846b4ef67e53ca4c4b047ed8b06eb861db29914e9f1dfe11a8b73aa2225519843661a61e9038cb347015be916c5a44222ed71b8b604',310008000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,10000,X'000000000000000000004768000000000000020E',1);
INSERT INTO transactions VALUES(10,'dda46f3ab92292e4ce918567ebc2c83e0a3707d78a07acb86517cf936f78638c',310009,'550d7d84590c6e4e7caed4e722151f7e110dc39bf3f54f719babfe89775095abb2d2454014b4cb01fb1e0a7e91639559ce17e096be5178b5c2ca5b22ad41b33a',310009000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'00000032000000000000025800000000000047670000000000000001',1);
INSERT INTO transactions VALUES(11,'5995ba45f8db07202fb542aaac7bd6b9224091764295034e8cf68d2752824d87',310010,'477c4a3445e32cd0c8ef67c808ac6a6362ebc953c396e2d5c0d7e4f185becd15fa99bd7635358dbb3b5a92e9f03b7fa2dda8d4714e181ec4552b279df3ba81f0',310010000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'00000032000000000000032000000000000047680000000000000001',1);
INSERT INTO transactions VALUES(12,'168b0c4059ca939b80dc4c8d7af2777f81e580df6d2ea476e7961c51d7eb2993',310011,'05f81b5c1b067b647894014cea65558826be42cca20a6cccb8623d80059182b77da00922539c59a0a7b63f6f011ca0f564fada0451e891644728b874c65267b9',310011000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000001E52BB3300405900000000000005F5E0FF09556E69742054657374',1);
INSERT INTO transactions VALUES(13,'5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a',310012,'e9d898aae43fc103110e4935cabf01b6016571b1af82e27af04b57c12302b05eab217f075ac3344b0a422e76b8c762c119cb290c867bb6eed432994ec28af027',310012000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,10000,X'00000028000052BB33640000000002FAF08000000000017D7840000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(14,'edd28543ae87ae56f5bd55437cab05f7f4d8a1709cb12e139dab176eb5f7e74a',310013,'2251b497007459321f72cda82681d07d131dd81cc29137b18c534bbb09271678f4497d0316ffac262f021f901078926dee11c791a3524ad850ee948474abd3b5',310013000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,10000,X'00000028000152BB336400000000017D78400000000002793D60000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(15,'bc42268279947c6dd5a517df41ae838c22c7194c686180700d8087dc3c8ce36c',310014,'f98fb331e66361507190a1cb1df81b814d24517e7f219029c068b649c9b8a75703770369ebafd864d104225d6fe1fbf13705d1a37a819b04fb151ed390d7bcf8',310014000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,10000,X'00000028000052BB33640000000008F0D1800000000014DC93800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(16,'faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67',310015,'7c25469d6b4fed0e8bb9e4325994c4de1737570fece605b4ca388be6921406b64a395dc519b33c0dff4f93930b32737a941bbb850e31f2ebcd2caba520bc2820',310015000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,10000,X'00000028000152BB33640000000014DC93800000000008F0D1800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(17,'0bedbaab766013a9381fee7cf956cb5a93eda3df67762633c7427706bbd3349d',310016,'9f1c56677b369099f059cc145b98f2e3f8895631cdf0f72b7fe76fd953ab68c202329848dfb53f8146552876eba37f50ed02da34f23447f518449bf0ac0cc29e',310016000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,10000,X'00000028000252BB33C8000000002CB417800000000026BE36803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(18,'864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715',310017,'4c02945de20ccdc874ae21bf56aea2f40a029c17b81fcf602b367bdbc286f9ec0cacab35fc07ac60aefa4a96a586aed20129ad66d45ab87697704d731e06b40d',310017000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,10000,X'00000028000352BB33C80000000026BE3680000000002CB417803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(19,'2cd827a7d27adf046e9735abaad1d376ad7ef1f8fad1a10e44a691f9ddc3957b',310018,'6a26d120314af1710052c8f8f78453f944a146039679c781e04ddbb5a2d010927726fa6f81d3e01fc1fcc3363c06e8e1a81a35636684c4dbcd51edf561a9c0fc',310018000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000001E52BB33324058F7256FFC115E004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(20,'bd43db240fc7d12dcf355a246c260a7baf2ccd0935ebda51c728b30072e4f420',310019,'592e775a9259b1a5a7b0d7c2e028ff320783e7b49243ed6a20ece89a72964f3af4ed129698c4a143ad682a1493f982c5f8193d3b0e36b3df43964520409beb7a',310019000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000001E52BB3365405915F3B645A1CB004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(21,'7901472b8045571531191f34980d497f1793c806718b9cfdbbba656b641852d6',310020,'87fac74eef20e6121d9a66c90481f801a10d636976a6a6e7cf42fc38cc104a470e1b4cab3f9670be86c93ec1a407a1b464599121df6c8109ec7247b25c7efc62',310020000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000001E52BB33C94000000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(22,'38d5ec6c73a559b1d1409e0506e2bec30b7db9fd6ca385f2b50202ede6cede56',310021,'68a4f307918e2f39fb393e5ad6a7e2fb2e35ab5043402ce37e984de670579682af5c7ef98637478bc0efeb579dc9aaca7f199116b390c452ceedca420909355d',310021000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000000A00000000000047670000000002FAF08000000000000000010000000002FAF080000A0000000000000000',1);
INSERT INTO transactions VALUES(23,'6d1a0e0dedda4a78cf11ac7a1c6fd2c32d9fd7c99d97ae7d524f223641646b85',310022,'5052fbeb009f77f5629fb701a2e4a379ef6c5591a87ab4d2315c8b79fc8821301b21f146150b2af542eddd82e8e94bc021dd1a9ef8e837891248ab68f4afa7d0',310022000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mvCounterpartyXXXXXXXXXXXXXXW24Hef',100000000,10000,X'',1);
INSERT INTO transactions VALUES(24,'a40605acb5b55718ba35b408883c20eecd845425ec463c0720b57901585820e2',310023,'1aab02bbb1a7450d612af368e571d955812f9a376e9f7f80c8eb8296ec40ebfa964f5c9b5e56d4e0cc2d584b38c3280c2b8b2ac272ac00f4d0bffd5348006b4c',310023000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,10000,X'0000000000000000000047680000000000002710',1);
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
INSERT INTO undolog VALUES(4,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=93000000000 WHERE rowid=1');
INSERT INTO undolog VALUES(5,'DELETE FROM debits WHERE rowid=1');
INSERT INTO undolog VALUES(6,'DELETE FROM balances WHERE rowid=2');
INSERT INTO undolog VALUES(7,'DELETE FROM credits WHERE rowid=2');
INSERT INTO undolog VALUES(8,'DELETE FROM sends WHERE rowid=2');
INSERT INTO undolog VALUES(9,'DELETE FROM orders WHERE rowid=1');
INSERT INTO undolog VALUES(10,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92950000000 WHERE rowid=1');
INSERT INTO undolog VALUES(11,'DELETE FROM debits WHERE rowid=2');
INSERT INTO undolog VALUES(12,'DELETE FROM orders WHERE rowid=2');
INSERT INTO undolog VALUES(13,'UPDATE orders SET tx_index=3,tx_hash=''ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a'',block_index=310002,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''BTC'',give_quantity=50000000,give_remaining=50000000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=10,expire_index=310012,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(14,'UPDATE orders SET tx_index=4,tx_hash=''833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a'',block_index=310003,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''XCP'',give_quantity=105000000,give_remaining=105000000,get_asset=''BTC'',get_quantity=50000000,get_remaining=50000000,expiration=10,expire_index=310013,fee_required=900000,fee_required_remaining=900000,fee_provided=10000,fee_provided_remaining=10000,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(15,'DELETE FROM order_matches WHERE rowid=1');
INSERT INTO undolog VALUES(16,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92845000000 WHERE rowid=1');
INSERT INTO undolog VALUES(17,'DELETE FROM credits WHERE rowid=3');
INSERT INTO undolog VALUES(18,'UPDATE order_matches SET id=''ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a_833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a'',tx0_index=3,tx0_hash=''ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a'',tx0_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx1_index=4,tx1_hash=''833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a'',tx1_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',forward_asset=''BTC'',forward_quantity=50000000,backward_asset=''XCP'',backward_quantity=100000000,tx0_block_index=310002,tx1_block_index=310003,block_index=310003,tx0_expiration=10,tx1_expiration=10,match_expire_index=310023,fee_paid=857142,status=''pending'' WHERE rowid=1');
INSERT INTO undolog VALUES(19,'DELETE FROM btcpays WHERE rowid=5');
INSERT INTO undolog VALUES(20,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92945000000 WHERE rowid=1');
INSERT INTO undolog VALUES(21,'DELETE FROM debits WHERE rowid=3');
INSERT INTO undolog VALUES(22,'DELETE FROM assets WHERE rowid=3');
INSERT INTO undolog VALUES(23,'DELETE FROM issuances WHERE rowid=6');
INSERT INTO undolog VALUES(24,'DELETE FROM balances WHERE rowid=3');
INSERT INTO undolog VALUES(25,'DELETE FROM credits WHERE rowid=4');
INSERT INTO undolog VALUES(26,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92895000000 WHERE rowid=1');
INSERT INTO undolog VALUES(27,'DELETE FROM debits WHERE rowid=4');
INSERT INTO undolog VALUES(28,'DELETE FROM assets WHERE rowid=4');
INSERT INTO undolog VALUES(29,'DELETE FROM issuances WHERE rowid=7');
INSERT INTO undolog VALUES(30,'DELETE FROM balances WHERE rowid=4');
INSERT INTO undolog VALUES(31,'DELETE FROM credits WHERE rowid=5');
INSERT INTO undolog VALUES(32,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''BBBB'',quantity=1000000000 WHERE rowid=3');
INSERT INTO undolog VALUES(33,'DELETE FROM debits WHERE rowid=5');
INSERT INTO undolog VALUES(34,'DELETE FROM balances WHERE rowid=5');
INSERT INTO undolog VALUES(35,'DELETE FROM credits WHERE rowid=6');
INSERT INTO undolog VALUES(36,'DELETE FROM sends WHERE rowid=8');
INSERT INTO undolog VALUES(37,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''BBBC'',quantity=100000 WHERE rowid=4');
INSERT INTO undolog VALUES(38,'DELETE FROM debits WHERE rowid=6');
INSERT INTO undolog VALUES(39,'DELETE FROM balances WHERE rowid=6');
INSERT INTO undolog VALUES(40,'DELETE FROM credits WHERE rowid=7');
INSERT INTO undolog VALUES(41,'DELETE FROM sends WHERE rowid=9');
INSERT INTO undolog VALUES(42,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92845000000 WHERE rowid=1');
INSERT INTO undolog VALUES(43,'DELETE FROM debits WHERE rowid=7');
INSERT INTO undolog VALUES(44,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92844999976 WHERE rowid=1');
INSERT INTO undolog VALUES(45,'DELETE FROM debits WHERE rowid=8');
INSERT INTO undolog VALUES(46,'UPDATE balances SET address=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',asset=''XCP'',quantity=50000000 WHERE rowid=2');
INSERT INTO undolog VALUES(47,'DELETE FROM credits WHERE rowid=8');
INSERT INTO undolog VALUES(48,'DELETE FROM dividends WHERE rowid=10');
INSERT INTO undolog VALUES(49,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92844979976 WHERE rowid=1');
INSERT INTO undolog VALUES(50,'DELETE FROM debits WHERE rowid=9');
INSERT INTO undolog VALUES(51,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92844559176 WHERE rowid=1');
INSERT INTO undolog VALUES(52,'DELETE FROM debits WHERE rowid=10');
INSERT INTO undolog VALUES(53,'UPDATE balances SET address=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',asset=''XCP'',quantity=50000024 WHERE rowid=2');
INSERT INTO undolog VALUES(54,'DELETE FROM credits WHERE rowid=9');
INSERT INTO undolog VALUES(55,'DELETE FROM dividends WHERE rowid=11');
INSERT INTO undolog VALUES(56,'DELETE FROM broadcasts WHERE rowid=12');
INSERT INTO undolog VALUES(57,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92844539176 WHERE rowid=1');
INSERT INTO undolog VALUES(58,'DELETE FROM debits WHERE rowid=11');
INSERT INTO undolog VALUES(59,'DELETE FROM bets WHERE rowid=1');
INSERT INTO undolog VALUES(60,'UPDATE orders SET tx_index=3,tx_hash=''ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a'',block_index=310002,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''BTC'',give_quantity=50000000,give_remaining=0,get_asset=''XCP'',get_quantity=100000000,get_remaining=0,expiration=10,expire_index=310012,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=142858,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(61,'DELETE FROM order_expirations WHERE rowid=3');
INSERT INTO undolog VALUES(62,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92794539176 WHERE rowid=1');
INSERT INTO undolog VALUES(63,'DELETE FROM debits WHERE rowid=12');
INSERT INTO undolog VALUES(64,'DELETE FROM bets WHERE rowid=2');
INSERT INTO undolog VALUES(65,'UPDATE bets SET tx_index=13,tx_hash=''5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a'',block_index=310012,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=0,deadline=1388000100,wager_quantity=50000000,wager_remaining=50000000,counterwager_quantity=25000000,counterwager_remaining=25000000,target_value=0.0,leverage=15120,expiration=10,expire_index=310022,fee_fraction_int=99999999,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(66,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92769539176 WHERE rowid=1');
INSERT INTO undolog VALUES(67,'DELETE FROM credits WHERE rowid=10');
INSERT INTO undolog VALUES(68,'UPDATE bets SET tx_index=14,tx_hash=''edd28543ae87ae56f5bd55437cab05f7f4d8a1709cb12e139dab176eb5f7e74a'',block_index=310013,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=1,deadline=1388000100,wager_quantity=25000000,wager_remaining=25000000,counterwager_quantity=41500000,counterwager_remaining=41500000,target_value=0.0,leverage=15120,expiration=10,expire_index=310023,fee_fraction_int=99999999,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(69,'DELETE FROM bet_matches WHERE rowid=1');
INSERT INTO undolog VALUES(70,'UPDATE orders SET tx_index=4,tx_hash=''833ac1c9139acc7a9aaabbf04bdf3e4af95a3425762d39d8cc2cc23113861d2a'',block_index=310003,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''XCP'',give_quantity=105000000,give_remaining=5000000,get_asset=''BTC'',get_quantity=50000000,get_remaining=0,expiration=10,expire_index=310013,fee_required=900000,fee_required_remaining=42858,fee_provided=10000,fee_provided_remaining=10000,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(71,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92773789176 WHERE rowid=1');
INSERT INTO undolog VALUES(72,'DELETE FROM credits WHERE rowid=11');
INSERT INTO undolog VALUES(73,'DELETE FROM order_expirations WHERE rowid=4');
INSERT INTO undolog VALUES(74,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92778789176 WHERE rowid=1');
INSERT INTO undolog VALUES(75,'DELETE FROM debits WHERE rowid=13');
INSERT INTO undolog VALUES(76,'DELETE FROM bets WHERE rowid=3');
INSERT INTO undolog VALUES(77,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92628789176 WHERE rowid=1');
INSERT INTO undolog VALUES(78,'DELETE FROM debits WHERE rowid=14');
INSERT INTO undolog VALUES(79,'DELETE FROM bets WHERE rowid=4');
INSERT INTO undolog VALUES(80,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(81,'DELETE FROM credits WHERE rowid=12');
INSERT INTO undolog VALUES(82,'UPDATE bets SET tx_index=15,tx_hash=''bc42268279947c6dd5a517df41ae838c22c7194c686180700d8087dc3c8ce36c'',block_index=310014,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=0,deadline=1388000100,wager_quantity=150000000,wager_remaining=150000000,counterwager_quantity=350000000,counterwager_remaining=350000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310024,fee_fraction_int=99999999,status=''open'' WHERE rowid=3');
INSERT INTO undolog VALUES(83,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(84,'DELETE FROM credits WHERE rowid=13');
INSERT INTO undolog VALUES(85,'UPDATE bets SET tx_index=16,tx_hash=''faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67'',block_index=310015,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=1,deadline=1388000100,wager_quantity=350000000,wager_remaining=350000000,counterwager_quantity=150000000,counterwager_remaining=150000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310025,fee_fraction_int=99999999,status=''open'' WHERE rowid=4');
INSERT INTO undolog VALUES(86,'DELETE FROM bet_matches WHERE rowid=2');
INSERT INTO undolog VALUES(87,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(88,'DELETE FROM debits WHERE rowid=15');
INSERT INTO undolog VALUES(89,'DELETE FROM bets WHERE rowid=5');
INSERT INTO undolog VALUES(90,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91528789176 WHERE rowid=1');
INSERT INTO undolog VALUES(91,'DELETE FROM debits WHERE rowid=16');
INSERT INTO undolog VALUES(92,'DELETE FROM bets WHERE rowid=6');
INSERT INTO undolog VALUES(93,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(94,'DELETE FROM credits WHERE rowid=14');
INSERT INTO undolog VALUES(95,'UPDATE bets SET tx_index=17,tx_hash=''0bedbaab766013a9381fee7cf956cb5a93eda3df67762633c7427706bbd3349d'',block_index=310016,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=2,deadline=1388000200,wager_quantity=750000000,wager_remaining=750000000,counterwager_quantity=650000000,counterwager_remaining=650000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310026,fee_fraction_int=99999999,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(96,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(97,'DELETE FROM credits WHERE rowid=15');
INSERT INTO undolog VALUES(98,'UPDATE bets SET tx_index=18,tx_hash=''864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715'',block_index=310017,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=3,deadline=1388000200,wager_quantity=650000000,wager_remaining=650000000,counterwager_quantity=750000000,counterwager_remaining=750000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310027,fee_fraction_int=99999999,status=''open'' WHERE rowid=6');
INSERT INTO undolog VALUES(99,'DELETE FROM bet_matches WHERE rowid=3');
INSERT INTO undolog VALUES(100,'DELETE FROM broadcasts WHERE rowid=19');
INSERT INTO undolog VALUES(101,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(102,'DELETE FROM credits WHERE rowid=16');
INSERT INTO undolog VALUES(103,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90937926676 WHERE rowid=1');
INSERT INTO undolog VALUES(104,'DELETE FROM credits WHERE rowid=17');
INSERT INTO undolog VALUES(105,'DELETE FROM bet_match_resolutions WHERE rowid=1');
INSERT INTO undolog VALUES(106,'UPDATE bet_matches SET id=''5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a_edd28543ae87ae56f5bd55437cab05f7f4d8a1709cb12e139dab176eb5f7e74a'',tx0_index=13,tx0_hash=''5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a'',tx0_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx1_index=14,tx1_hash=''edd28543ae87ae56f5bd55437cab05f7f4d8a1709cb12e139dab176eb5f7e74a'',tx1_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=15120,forward_quantity=41500000,backward_quantity=20750000,tx0_block_index=310012,tx1_block_index=310013,block_index=310013,tx0_expiration=10,tx1_expiration=10,match_expire_index=310022,fee_fraction_int=99999999,status=''pending'' WHERE rowid=1');
INSERT INTO undolog VALUES(107,'DELETE FROM broadcasts WHERE rowid=20');
INSERT INTO undolog VALUES(108,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90941039176 WHERE rowid=1');
INSERT INTO undolog VALUES(109,'DELETE FROM credits WHERE rowid=18');
INSERT INTO undolog VALUES(110,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91100339176 WHERE rowid=1');
INSERT INTO undolog VALUES(111,'DELETE FROM credits WHERE rowid=19');
INSERT INTO undolog VALUES(112,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91416039176 WHERE rowid=1');
INSERT INTO undolog VALUES(113,'DELETE FROM credits WHERE rowid=20');
INSERT INTO undolog VALUES(114,'DELETE FROM bet_match_resolutions WHERE rowid=2');
INSERT INTO undolog VALUES(115,'UPDATE bet_matches SET id=''bc42268279947c6dd5a517df41ae838c22c7194c686180700d8087dc3c8ce36c_faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67'',tx0_index=15,tx0_hash=''bc42268279947c6dd5a517df41ae838c22c7194c686180700d8087dc3c8ce36c'',tx0_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx1_index=16,tx1_hash=''faca8b02a24a4e8a29164f5d3a4ce443c55c4060c34f7ad3cb42ad862c5a6f67'',tx1_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=5040,forward_quantity=150000000,backward_quantity=350000000,tx0_block_index=310014,tx1_block_index=310015,block_index=310015,tx0_expiration=10,tx1_expiration=10,match_expire_index=310024,fee_fraction_int=99999999,status=''pending'' WHERE rowid=2');
INSERT INTO undolog VALUES(116,'DELETE FROM broadcasts WHERE rowid=21');
INSERT INTO undolog VALUES(117,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91441039176 WHERE rowid=1');
INSERT INTO undolog VALUES(118,'DELETE FROM credits WHERE rowid=21');
INSERT INTO undolog VALUES(119,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92771039176 WHERE rowid=1');
INSERT INTO undolog VALUES(120,'DELETE FROM credits WHERE rowid=22');
INSERT INTO undolog VALUES(121,'DELETE FROM bet_match_resolutions WHERE rowid=3');
INSERT INTO undolog VALUES(122,'UPDATE bet_matches SET id=''0bedbaab766013a9381fee7cf956cb5a93eda3df67762633c7427706bbd3349d_864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715'',tx0_index=17,tx0_hash=''0bedbaab766013a9381fee7cf956cb5a93eda3df67762633c7427706bbd3349d'',tx0_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx1_index=18,tx1_hash=''864b93f55d4aa6cec4717b264d7cc351d7b0ef169d4d584008be703ade736715'',tx1_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx0_bet_type=2,tx1_bet_type=3,feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',initial_value=100,deadline=1388000200,target_value=1.0,leverage=5040,forward_quantity=750000000,backward_quantity=650000000,tx0_block_index=310016,tx1_block_index=310017,block_index=310017,tx0_expiration=10,tx1_expiration=10,match_expire_index=310026,fee_fraction_int=99999999,status=''pending'' WHERE rowid=3');
INSERT INTO undolog VALUES(123,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''BBBB'',quantity=996000000 WHERE rowid=3');
INSERT INTO undolog VALUES(124,'DELETE FROM debits WHERE rowid=17');
INSERT INTO undolog VALUES(125,'DELETE FROM orders WHERE rowid=3');
INSERT INTO undolog VALUES(126,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92841039176 WHERE rowid=1');
INSERT INTO undolog VALUES(127,'DELETE FROM credits WHERE rowid=23');
INSERT INTO undolog VALUES(128,'DELETE FROM burns WHERE rowid=23');
INSERT INTO undolog VALUES(129,'UPDATE bets SET tx_index=13,tx_hash=''5da0ca591e5336da0304bc8f7a201af3465685c492b284495898da35a402e32a'',block_index=310012,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=0,deadline=1388000100,wager_quantity=50000000,wager_remaining=8500000,counterwager_quantity=25000000,counterwager_remaining=4250000,target_value=0.0,leverage=15120,expiration=10,expire_index=310022,fee_fraction_int=99999999,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(130,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=149840926438 WHERE rowid=1');
INSERT INTO undolog VALUES(131,'DELETE FROM credits WHERE rowid=24');
INSERT INTO undolog VALUES(132,'DELETE FROM bet_expirations WHERE rowid=13');
INSERT INTO undolog VALUES(133,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''BBBC'',quantity=99474 WHERE rowid=4');
INSERT INTO undolog VALUES(134,'DELETE FROM debits WHERE rowid=18');
INSERT INTO undolog VALUES(135,'UPDATE balances SET address=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',asset=''BBBC'',quantity=526 WHERE rowid=6');
INSERT INTO undolog VALUES(136,'DELETE FROM credits WHERE rowid=25');
INSERT INTO undolog VALUES(137,'DELETE FROM sends WHERE rowid=24');
INSERT INTO undolog VALUES(138,'UPDATE orders SET tx_index=22,tx_hash=''38d5ec6c73a559b1d1409e0506e2bec30b7db9fd6ca385f2b50202ede6cede56'',block_index=310021,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''BBBB'',give_quantity=50000000,give_remaining=50000000,get_asset=''XCP'',get_quantity=50000000,get_remaining=50000000,expiration=10,expire_index=310031,fee_required=0,fee_required_remaining=0,fee_provided=10000,fee_provided_remaining=10000,status=''open'' WHERE rowid=3');
INSERT INTO undolog VALUES(139,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''BBBB'',quantity=946000000 WHERE rowid=3');
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
