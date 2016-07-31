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
INSERT INTO bet_expirations VALUES(13,'4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',310023);
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
INSERT INTO bet_match_resolutions VALUES('4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf_571bf2b57a7251ca3e8dfc6df5f93b4cdb420976a4bcf3a8dcdb633af78f0fcf',1,310018,'0',0,59137500,NULL,NULL,3112500);
INSERT INTO bet_match_resolutions VALUES('6ef15062104f20e15f0a7fc5ad3184e22cef35f3eff6aa0d3a6b0fb00482f2cd_9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891',1,310019,'1',159300000,315700000,NULL,NULL,25000000);
INSERT INTO bet_match_resolutions VALUES('69ea81f72e31ccd89ef9c363a72d210e58c5316df7b2ac3738604ff24fc57f31_8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514',5,310020,NULL,NULL,NULL,'NotEqual',1330000000,70000000);
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
INSERT INTO bet_matches VALUES('4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf_571bf2b57a7251ca3e8dfc6df5f93b4cdb420976a4bcf3a8dcdb633af78f0fcf',13,'4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',14,'571bf2b57a7251ca3e8dfc6df5f93b4cdb420976a4bcf3a8dcdb633af78f0fcf','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',100,1388000100,0.0,15120,41500000,20750000,310012,310013,310013,10,10,310022,5000000,'settled: liquidated for bear');
INSERT INTO bet_matches VALUES('6ef15062104f20e15f0a7fc5ad3184e22cef35f3eff6aa0d3a6b0fb00482f2cd_9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891',15,'6ef15062104f20e15f0a7fc5ad3184e22cef35f3eff6aa0d3a6b0fb00482f2cd','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',16,'9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',100,1388000100,0.0,5040,150000000,350000000,310014,310015,310015,10,10,310024,5000000,'settled');
INSERT INTO bet_matches VALUES('69ea81f72e31ccd89ef9c363a72d210e58c5316df7b2ac3738604ff24fc57f31_8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514',17,'69ea81f72e31ccd89ef9c363a72d210e58c5316df7b2ac3738604ff24fc57f31','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',18,'8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',2,3,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',100,1388000200,1.0,5040,750000000,650000000,310016,310017,310017,10,10,310026,5000000,'settled: for notequal');
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
INSERT INTO bets VALUES(13,'4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf',310012,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1388000100,50000000,8500000,25000000,4250000,0.0,15120,10,310022,5000000,'expired');
INSERT INTO bets VALUES(14,'571bf2b57a7251ca3e8dfc6df5f93b4cdb420976a4bcf3a8dcdb633af78f0fcf',310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000100,25000000,4250000,41500000,0,0.0,15120,10,310023,5000000,'filled');
INSERT INTO bets VALUES(15,'6ef15062104f20e15f0a7fc5ad3184e22cef35f3eff6aa0d3a6b0fb00482f2cd',310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1388000100,150000000,0,350000000,0,0.0,5040,10,310024,5000000,'filled');
INSERT INTO bets VALUES(16,'9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891',310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000100,350000000,0,150000000,0,0.0,5040,10,310025,5000000,'filled');
INSERT INTO bets VALUES(17,'69ea81f72e31ccd89ef9c363a72d210e58c5316df7b2ac3738604ff24fc57f31',310016,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',2,1388000200,750000000,0,650000000,0,1.0,5040,10,310026,5000000,'filled');
INSERT INTO bets VALUES(18,'8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514',310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',3,1388000200,650000000,0,750000000,0,1.0,5040,10,310027,5000000,'filled');
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
INSERT INTO blocks VALUES(310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,NULL,NULL,NULL,'f3e1d432b546670845393fae1465975aa99602a7648e0da125e6b8f4d55cbcac','74baad601b5f5e83ccc034b12956183c3b4c96973be90b1f65625f1d289a4486','91be11aea0c9cafc4b843a064d95cd2addf128675d6a371b090f60cd7e38aa67');
INSERT INTO blocks VALUES(310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,NULL,NULL,NULL,'799a07e7b411c96c92618baa5b998db22fa9ac0a9f7e231e571a237132a813c7','0dc02d2fd80a10d1114962cfe63af6e12e3d1ff674ed7767939c76bec2254cb1','f1ec93926b060a8cf2593aa5e2de13b01dcec42bcb2a846132ce36ec98ba33c4');
INSERT INTO blocks VALUES(310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,NULL,NULL,NULL,'c5ac2b0cc1745402a7693afc6e5aa4394c1c2c1c70b069911fa793cfef55a4d3','aa7c7f07c6e4c0345389a04bda57bd712330a33fc4465f39f14be5a37716d7b6','57d4db612011b6d82a7da956430ae07afb5a5cda017b4e47f5c1766392b7319c');
INSERT INTO blocks VALUES(310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,NULL,NULL,NULL,'0c22178d665b7b83b80d9686df23f12ecd6ae3a5744b729c528f9ecc3c94b051','28fd28c599426f9aa3303889b93795ae0b4ed3680df18fb7d0141e9937e6264b','1bc659e8aab36b3671f7dd37c24f310329b643e2fd773fe693e8401d32b69245');
INSERT INTO blocks VALUES(310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,NULL,NULL,NULL,'9b1bb2d232c1e24fd52c4fd299776924fae5b0deab3d37dc359632777c80294b','a4ca924d04d2c2f20e15b50dfe19f59d9096d50b08e0cd01f7eb4e92aeaba18d','7e65937b3703c6fce9d973eccb3f7133ab5c2c2dcf26d8d62927edaf6908f63d');
INSERT INTO blocks VALUES(310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,NULL,NULL,NULL,'92ab51eb151104ac16d901ee7bddd5b6cec176a7ce91359b331767963bdbc2f8','acc523608fe2bbffd7b1e4918940550a8408467041c4146193da99b3ee35b1c4','08cb0df0b34f48641dcde55fe4c3875965bcaed3bee1482b64fe532388a1ea4a');
INSERT INTO blocks VALUES(310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,NULL,NULL,NULL,'ca4d8f6af1678bc1c40c60b97d409d1503b6a93cffc828a132abe7fd4f77a911','d750a4e96261df20bc7a70f734f1e5a93ce5f72d95ddfd94f99ca997cb5dd3e4','cf05f2b98a06c6eb86d1f2fcd9ff2b32958c86fa31fe6284e00b8ff5f90a076e');
INSERT INTO blocks VALUES(310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,NULL,NULL,NULL,'ec5ea53c7c9980060c08faa94fe708d0560bd4667843071cdd49ca07781f8197','cf6dcb95093f20e5330e656d860a94e2e0a2f7fa512f84aa52b000752f72f71d','9f77c40e2682b2937ff69c00b291fbb6c167e3929a953e16d27ba1c7bca9fe70');
INSERT INTO blocks VALUES(310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,NULL,NULL,NULL,'c805eed4b9512a6d277cc5814145f6db7a12ddce6f9df1a1656aafd11730c433','81b558d2fa194eb13a096aafa5ad2da8a865049f5dec5a4a383732a6b945f8ff','b2370ec6d99bec617ab7b0ebe2f5da6e7de049d6eebfceb1deafc5747f3d4bdd');
INSERT INTO blocks VALUES(310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,NULL,NULL,NULL,'89b985b58171d607af4fca31f87774e68ffe9c5e6ce6819555242df327225300','fdf5079f2e72d9d89e15670fabbb074ac0cc4bf3bec46ff03c9f58387d90a3a3','952c2a8d6d487f2762bc32a9827d2e176dba8c9a0a157602945d1cbfae501dcf');
INSERT INTO blocks VALUES(310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,NULL,NULL,NULL,'9364be6a0b1c52254b405f51631f654b7670b1e8befc3171cd3d6b00e8679b5e','fa9188da88edfe9ccd69d51c43fdffeaf62d8f9066e4021c9720880e4d6c3c38','1b20b2e01ebda5da354d8d8023c2d61c8f55f7daa3c2b1b0b59c67dbd30d2eb3');
INSERT INTO blocks VALUES(310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,NULL,NULL,NULL,'8d855d1d96fc2439e12cea023a8b89188d66af4f2b0909899088f6f49bc19788','f6af840adbcce341ca1a432ffac75b3bb6405e73460d6bdfdcc7b84f052efc44','dd6e05a231bb31529886c6a3da8cea65e4deda187079040097d3d4a2f7c45a3f');
INSERT INTO blocks VALUES(310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,NULL,NULL,NULL,'c44aa2983ed171cc07ff6e5d0c4b5c8b11e5d91dd07e38be0c1b9125ae3bf456','4a0fc2a0d0bbbc0948d03a054d6a48509cce9c4630465f96dba1341e366b61b5','d8c3ab48b7242756b12cc713f6e435b2871930b7c46dc655975f61078819f1fa');
INSERT INTO blocks VALUES(310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,NULL,NULL,NULL,'5be56741bca8dec52d2a67e53dcd63160d4526f7dc0df67fda0de77bf4e9da8a','3115a3d88c4522b28a6ede890c7da09a58837559792ff6ca18f968ace32d8f70','4fa350230009a3febbf0eabc5334f8d8df698640259b0dc4e852d12a4fdfa99b');
INSERT INTO blocks VALUES(310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,NULL,NULL,NULL,'f86452c1cd357d643eee042d1fd66436098685de4c52a7936a03ce20bda1079a','ae953f27b93505f28ebee1ede304f445d86f4eb7c44b05bf9503a848cfbecce4','332e7312e7bf5d253469a21cf8b72d4f6edd7d2892a61ffdb415a460dc012687');
INSERT INTO blocks VALUES(310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,NULL,NULL,NULL,'bae2bbbf6218c0c024869311fcab4a20fd23aef08df2de2fc91c455f6d9fc0b3','0ca04008bab36f7c0fdc301437e481eaabb86e56d71a55ac2124c8471d63006a','401303a15e487992bf075e53fcb1ae3c6cb9ab1dba5930743d4e107c66d7bd4a');
INSERT INTO blocks VALUES(310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,NULL,NULL,NULL,'bad1ac257a33472aef96bfe3c31edb133dda78d3d50cdfdce60ff15ff16b10e0','2de549c7cf68a2ed644c51a073aaf7aac0d235dcc9ab5de2561d4a40a2f937f8','11b40f6cb7d2338c36489a4573d4e4b6a259e62c103d2a3ef867582d3f46ec12');
INSERT INTO blocks VALUES(310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,NULL,NULL,NULL,'4face53b64e3760e7dcd2521355795bf84c08cc4fc9f4714202f4ab9f9dc05fc','964ab3c0c7ca65d48664926a11ec98f85d02991d0d6f87f175adafe0ed2e50d2','f6ae0ec6af348b8c8f3f92cdea774b1c143bddd2552d9524e6091cd53d048ed6');
INSERT INTO blocks VALUES(310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,NULL,NULL,NULL,'f6c2e0002faec9c351fa0e6fd4d6319ef90bbb18f523bcff7a7de93f03828995','5f871ea58c94b0994b1c85206f7bfc0c3eb430c8db5c53aa05401a54c74b127f','94d8ac41d1dffb0f922031cfbf7c4aff42cec31a4594d882fedc649caed78bbc');
INSERT INTO blocks VALUES(310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,NULL,NULL,NULL,'10758b2da0121a48b575407509018c5b1eeadf37bb5c2b72754537400202fc2c','d00d9661d7e405f51d961f7451aea25a3e69ad346ac9a54e61248d4d105cef29','2abfcca5a096d45ff8c46d3efa8fa0a8d78071e6edc7ed176ca6577b4bb04c41');
INSERT INTO blocks VALUES(310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,NULL,NULL,NULL,'d4e0407b10cc1081f759911dbec043539234133a35cb558c4d618551a394db48','ba729896107ee12e06ebca8bdb6d5e8fa029f88f441f409026d5b221b76c7132','965bab542fe6a3d1b8c99f112ab676adee7774ebbc0e39aff1c553e4ff9258e8');
INSERT INTO blocks VALUES(310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,NULL,NULL,NULL,'79627943b1596067ed0fffc089f6f364588f5f24e9203d2645089f40d174f269','287eeaadd91593a21774c1833908a5c2923b67934f68e2883d87c553ba9839dd','cd51b25a15c7762ef80158be42f6aa4a376518eebcf07c50521b7c0c373d80bf');
INSERT INTO blocks VALUES(310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,NULL,NULL,NULL,'a293e8104811b548c6011206210787df28356f4364fb58841a0d47ec5ac569d6','c4b8fc396c9087e76135871b7fa69129c349966a61a5191860343a32f88c1bec','5688b9aa322722725515ee5c89c3cec06868297319628930933bcc8a78d0cccb');
INSERT INTO blocks VALUES(310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,NULL,NULL,NULL,'20eb4a448bb91b5bffd9a56770bd5e0ac2ef4654179896b8928af2f64f43f03f','0fdbebfd260cc85c3ba3bd79850748ea9741fcfe6cb64a82559fb0eebc4213f6','6b12497bb0cea782b6379d52f1118dd0583b765ec466fa6c78136cdbe21051b2');
INSERT INTO blocks VALUES(310024,'b03042b4e18a222b4c8d1e9e1970d93e6e2a2d41686d227ff8ecf0a839223dc5',310024000,NULL,NULL,NULL,'5a8400b9458a2bf130e2e456047732cb13b77197d8c21b7f247f0757c9437919','8c7454f7fa2e6fb7fc83ee716c121bb4b687757e4cd66bad645ad643843348e0','063dd1e5e6ddb3962d094ccfd291be50fb5b6b3f814c5815f8a7eb4a6d545c6d');
INSERT INTO blocks VALUES(310025,'a872e560766832cc3b4f7f222228cb6db882ce3c54f6459f62c71d5cd6e90666',310025000,NULL,NULL,NULL,'134a2ed73efdec3c56857e92885355bba1f0325097bf958ce9387060841ec23c','e00cb52f045408f2dbfe16d3ba631b910a4216d3f3040baebf391cd8eed7c0b9','f031f4bbe578fc1066d2af8f453a59d8be1b8306911813878939d9708aa8756f');
INSERT INTO blocks VALUES(310026,'6c96350f6f2f05810f19a689de235eff975338587194a36a70dfd0fcd490941a',310026000,NULL,NULL,NULL,'991650c3d89e104026aab7489e596692d3c104a2374bf3a2078bfbd0e0ed4ffe','8e1964261328bd2cd482e9db05f6fd29e45faa9a1e44d356c98d037e2d23da79','ed57ae9a2ec27360d9632251b86cc36916e39d17c95040cd5ef90814a2e7945c');
INSERT INTO blocks VALUES(310027,'d7acfac66df393c4482a14c189742c0571b89442eb7f817b34415a560445699e',310027000,NULL,NULL,NULL,'6f258efddeb2c542fc610bb169df58beda36852735fc051a046378fffd4a88bc','e72b5a71157c6d07386faf1a9a9449cca890e2debe865c3ebbe8583d90c66f5a','4e68197341807a517d6d63d65fe6b17e816293c78406d9797ec94354436d2894');
INSERT INTO blocks VALUES(310028,'02409fcf8fa06dafcb7f11e38593181d9c42cc9d5e2ddc304d098f990bd9530b',310028000,NULL,NULL,NULL,'f6020d6aa398f6a19e34375aef4bc3d9e2af81bc3f469aedcb438b7a4244452e','bc3d52d196eb31563358e2675885bfff8a365cd312813531017ff38c751a5534','f4383c6fd0717fa12c4526b2b579cd647344511d2b02132c300188ed8c01196e');
INSERT INTO blocks VALUES(310029,'3c739fa8b40c118d5547ea356ee8d10ee2898871907643ec02e5db9d00f03cc6',310029000,NULL,NULL,NULL,'3d1ebe501f5c0706c48001f34df56a82f1ab55c24f7eabd27d7c608b7ef5f53d','aaf86554e12a8ac7d2fc533a4fc21f5d33b22daa8ff4ea8e7355a0d71a350698','be9387be8a9c989eaa17a197b75665405aea4263a88c875b6694afe2c4732047');
INSERT INTO blocks VALUES(310030,'d5071cddedf89765ee0fd58f209c1c7d669ba8ea66200a57587da8b189b9e4f5',310030000,NULL,NULL,NULL,'b45b0ed17cec893daf9b0755d8fe96acb5a57d185febee1accdf12d0f6548149','1f1e822ea13169b216e67f3b6cb4ddb7b65ed347861440904b7961f1221f64c8','a03d5a16f543dedba6513c83d437f7c57ab6449142dd71589a95bd4668d700bd');
INSERT INTO blocks VALUES(310031,'0b02b10f41380fff27c543ea8891ecb845bf7a003ac5c87e15932aff3bfcf689',310031000,NULL,NULL,NULL,'a09ade623465eb0723906a09c0dfa9ec3d3608c89d0dc9a6c29771d7e0270870','91ffe98523d7e1af983e1a86d75ef16f62514f6c57837da68a0701b0ccfc168f','e167784cb4eecb855dc2daf5d00a6825d665516a5fdc19a3ec724718967126c8');
INSERT INTO blocks VALUES(310032,'66346be81e6ba04544f2ae643b76c2b7b1383f038fc2636e02e49dc7ec144074',310032000,NULL,NULL,NULL,'ac17144975b1c8afae2b06674d2b37ebff0f65340d18bc8b4d2a3d4393ffea2f','ce3bacc5c1579089645ada2e4e7fe8f6c043cc73d93589faa1eb2f330a8702ac','0e07d0c3310a017ff915b51d38912ae19054d097afba0575767c6dee0a714959');
INSERT INTO blocks VALUES(310033,'999c65df9661f73e8c01f1da1afda09ac16788b72834f0ff5ea3d1464afb4707',310033000,NULL,NULL,NULL,'b3b5d5b1902c2ef0de433fae13b45a172292f6670e6ae3510b66b1c668589a1f','e2902d445fa9deaa7be258a82ae844881b53af16514196c23e638a6ae77a0cc1','90515a02eadfc80170f519582109e537ab7c9c8f09036bba7509efe2c801b6a7');
INSERT INTO blocks VALUES(310034,'f552edd2e0a648230f3668e72ddf0ddfb1e8ac0f4c190f91b89c1a8c2e357208',310034000,NULL,NULL,NULL,'9472707aabedf5777a39795c6203b6c739918f192289461dfd04a60de1e0c957','7bcd5b31cef24667d2794637e256ce52948802556940b3ecaf94af5ceb819817','7d777c58562644bef6e8f432e356a3e87e659c458979d834fd5fc70068e43173');
INSERT INTO blocks VALUES(310035,'a13cbb016f3044207a46967a4ba1c87dab411f78c55c1179f2336653c2726ae2',310035000,NULL,NULL,NULL,'beefce8b07b546b6f4b7841f0902071df6c2b6690b0e8c761081a05906bb2d54','589872ec85b1511bf8b5051e2a73f39893187f26a66c8e34ed48d614bc5f0af7','c0ad28893c512bef6daf178c4a56b3381916b32fbf7d64008f28ea6f17449e34');
INSERT INTO blocks VALUES(310036,'158648a98f1e1bd1875584ce8449eb15a4e91a99a923bbb24c4210135cef0c76',310036000,NULL,NULL,NULL,'09ef6e4b0507f56156c178c9c88a1cd4c4954ccbe349d885b79ef48b5743f050','3b5327d91b7b6bd0c80ec7cf53fda36e7118e5aa94bc8440e259b1abf934f569','668aa3b70f83bf67b9ceaed7c1e9b13726bff9003cefddf4c7edd488d00c53d5');
INSERT INTO blocks VALUES(310037,'563acfd6d991ce256d5655de2e9429975c8dceeb221e76d5ec6e9e24a2c27c07',310037000,NULL,NULL,NULL,'9031545d6509e31bc0694eac4d8b0f227cba3017c2c67c8475e782be62daf78d','6da26ef7b75e0f54d947f1afb6957281ff94c23381a2f4d4d7624c738e12c233','22ed96250c234d9cba564770baafd78ac4af088326342dc8d285c292a9aaff9f');
INSERT INTO blocks VALUES(310038,'b44b4cad12431c32df27940e18d51f63897c7472b70950d18454edfd640490b2',310038000,NULL,NULL,NULL,'8bf7837453018b11389958dfa7a901098387088d926b64073dfdc862a4efd20c','330dc5e8f278fa450a042329314cdcaeee9c0a71f6890e5185d92de93ca5d0e5','420ec68543e5e48ce6b0790a9b6650266bc0e13cfc57c0a93c6ff8663ef28357');
INSERT INTO blocks VALUES(310039,'5fa1ae9c5e8a599247458987b006ad3a57f686df1f7cc240bf119e911b56c347',310039000,NULL,NULL,NULL,'c1a5c848da36b34fc10df323539ec8a363da62c373afebb5236b6985a5b6ad57','1686a96ad2608edc5267f2f176b69d7f9b01a047cf02352ff2f1ba9dfa1312a0','de3e39510c4c68c250220dba9708ad3376f93647cb29fe2df0d3aa05d9f710a7');
INSERT INTO blocks VALUES(310040,'7200ded406675453eadddfbb2d14c2a4526c7dc2b5de14bd48b29243df5e1aa3',310040000,NULL,NULL,NULL,'872fca779c7f012871ac7fddb3f4006fe9573e4c0889bd2de790dc0158e6732a','50b18b02654d56ac403c4a9868cb983b3d72320e6cf40b5218c0a57a9ce510bd','841980212618822e9f2641a7b1d5e6cd16723c5fb27a8c90c71e2959b5a4bb5b');
INSERT INTO blocks VALUES(310041,'5db592ff9ba5fac1e030cf22d6c13b70d330ba397f415340086ee7357143b359',310041000,NULL,NULL,NULL,'b12c996ac0c0023e4e230fdda1fb0132b4131034dd930ab4b294af6f469e0bdc','182d5aa358e873f2c8cd257263a9ed0aae37d3395a1422ea8797c5189966abab','d8f419d82e0b3e56b19816027d30144cf50abb6bfd3758d3e7d7d1e1a542868c');
INSERT INTO blocks VALUES(310042,'826fd4701ef2824e9559b069517cd3cb990aff6a4690830f78fc845ab77fa3e4',310042000,NULL,NULL,NULL,'7a8d6356e216afe4e589d26b471171d4bec625f9aeb6ee3f3af6c95d48f0b725','de17627cf8d1e90bbda289103863913ad9640316c247775cd012e71932600adc','75f6706d1fde3266aa0a5a1c37829a776fef89dafd14dbd3ebb32573479be5f7');
INSERT INTO blocks VALUES(310043,'2254a12ada208f1dd57bc17547ecaf3c44720323c47bc7d4b1262477cb7f3c51',310043000,NULL,NULL,NULL,'00d2b046d86a0816bda22f1ad5e6b4c1b898bfed2c65df3c6e7ad7466a001b6a','c7080fa25f7c6a4c16855e2fe24d725ea1fab34a5b511276ae99073811b69e9e','957dfa3e8a824e3f34fc43ef94bd239139cc2f41e684c80e3fb4688e25107d7e');
INSERT INTO blocks VALUES(310044,'3346d24118d8af0b3c6bcc42f8b85792e7a2e7036ebf6e4c25f4f6723c78e46b',310044000,NULL,NULL,NULL,'c49bc1a16630633105f839824678cddb2dcd7d186071300bf4911fbf4cb9442a','6b8f7073adedee9549a1863ae38aa23c07bf5f257cedada853182e02581c5aca','65c78e63bec5b519e60bb4b3dd4c3a88562b5117a92b82ea8d1a84900ff737d0');
INSERT INTO blocks VALUES(310045,'7bba0ab243839e91ad1a45a762bf074011f8a9883074d68203c6d1b46fffde98',310045000,NULL,NULL,NULL,'e3de0ca395651f7a1598738f2604581407f2b45b736f5aac2ad64e867295efc2','af15e45e9da7fd203268496f7b54e6c87317e0f83cdbf989af768575218b70a5','95535633cfb7a787b82afb2cf28d2f5d216b45caf22f39dd3895326abe8da291');
INSERT INTO blocks VALUES(310046,'47db6788c38f2d6d712764979e41346b55e78cbb4969e0ef5c4336faf18993a6',310046000,NULL,NULL,NULL,'ed901088e07f2e89f721cf23f968a3d9f070ed6dca4cdb172839e9a661a9b1d8','db2e1d0b0d582846716feca49c887f0aec2326a48e242721c4341043323cebcb','4cc47e85ffb74c44d3a26328bb3c12c711e79311b349d43dcd559c20b3ed8d3c');
INSERT INTO blocks VALUES(310047,'a9ccabcc2a098a7d25e4ab8bda7c4e66807eefa42e29890dcd88149a10de7075',310047000,NULL,NULL,NULL,'121e4e8d312ac0b95d72b1700db6f430b3724f75f00af90132db5e6c21fbc53e','488e9c20915211f861b7ef8ab540c0b4b10556c2a131235cea311a603d337ea8','36b6d55805dad8f64f695a7f5d816687ef853a15960eb3ef84297f453cf82584');
INSERT INTO blocks VALUES(310048,'610bf3935a85b05a98556c55493c6de45bed4d7b3b6c8553a984718765796309',310048000,NULL,NULL,NULL,'53b15d51a08eff5fed146c635008936e37e7e887fe29a2f120ba0ed880ee667f','c8a397fa57777d6d23762fd180d176fdaf6d306e4da8ae2e949dadabbcce1020','451ad73ed2ad2d43554f46df48011559ec15ba1e9e6aa954416bc4ef3ab75c0d');
INSERT INTO blocks VALUES(310049,'4ad2761923ad49ad2b283b640f1832522a2a5d6964486b21591b71df6b33be3c',310049000,NULL,NULL,NULL,'eee2ad25f711f1c125a4964847a5eaa7c2265ebb324df498b30a8287d7a12161','5d498043fcd0d970b4cdda9f73c0869f73dc2e53d377a0e8c2029d5aabf8cc5e','f7f67d5aa474675aef421efb0b3ac9896628bc73ef92e0591a766d3108d304d5');
INSERT INTO blocks VALUES(310050,'8cfeb60a14a4cec6e9be13d699694d49007d82a31065a17890383e262071e348',310050000,NULL,NULL,NULL,'b03d4f0a027bc98edbdd15c1ce220a5bc3566adda6313772ca8501923c26fc5c','12e9ccad25a6c969b5a2f1d71b8ec22b14fdacad12858ce917466bb55b12a7b6','9a4a6eec36b9c4c4a03a20d133c5df381ddbdf32b80ef73514d1b815abab07f2');
INSERT INTO blocks VALUES(310051,'b53c90385dd808306601350920c6af4beb717518493fd23b5c730eea078f33e6',310051000,NULL,NULL,NULL,'eb1690ec7cc4fad1417b1c2cf66c4260bd0bff5d628d4d9e4dd591a01bd89fdb','a2ea05138d0ab65b09354acd3c2e781109724916a0cf0ca3a853691c17fb72b8','ad8738caebe5210f9bea8164d80ff000705c0505f25291760c429de9b17353b6');
INSERT INTO blocks VALUES(310052,'0acdacf4e4b6fca756479cb055191b367b1fa433aa558956f5f08fa5b7b394e2',310052000,NULL,NULL,NULL,'2fdb743bae81963ec46bb2b12b2df50df5812475e96427f55abe524946901495','0a6f1164e5aee243536da5c6295999157342db53e3033dbddd74b84c4014aff9','87a84f545cb3c7f31d13b252bc389597e021b4c992b0e9ada503600665cf6f7a');
INSERT INTO blocks VALUES(310053,'68348f01b6dc49b2cb30fe92ac43e527aa90d859093d3bf7cd695c64d2ef744f',310053000,NULL,NULL,NULL,'66a979e684410a1fd761ff4622a0257d2d064de65519c6425048f5b5576231fb','e33621ba14670ffffad77f1bc6f52cb1089b9ddeee3a780f694fd2f0c0ef6aa8','2a3e361b305ab2460ad9ff5451c8698e889d923548756b3474e12717cb6f718b');
INSERT INTO blocks VALUES(310054,'a8b5f253df293037e49b998675620d5477445c51d5ec66596e023282bb9cd305',310054000,NULL,NULL,NULL,'291d96fd959f92027f92e25ac8ecf2e3f4602eadb8353e6a4c0c5db486a8040f','2a0724105672c7eb9b9cda299d2c00fe2f1a54806a9d29f7e309363459342fc9','859ccb80eb764383748e938a35906d661dc07f6924ae9e24904bb9fff11c82c6');
INSERT INTO blocks VALUES(310055,'4b069152e2dc82e96ed8a3c3547c162e8c3aceeb2a4ac07972f8321a535b9356',310055000,NULL,NULL,NULL,'2d70ac8848c48f2851118dabf74b766726525a324faed1a93ea962ef251de880','2c5e9cb49ff55877025e7e72bb3bde3196d5e47122ed12bd4123125786a16271','ad848d32ac7a1edab24f1cd39630f9768782e3526132bef39a3362496b9d33bc');
INSERT INTO blocks VALUES(310056,'7603eaed418971b745256742f9d2ba70b2c2b2f69f61de6cc70e61ce0336f9d3',310056000,NULL,NULL,NULL,'f0358dd54c295b6b736f66c9cbffda24bc56c61761f94bbc29ba4975a569409e','1479384b5a0da6cce9325ded017d6469ced8c465252d0f0930e05c457097fbb9','2fdd78b8bbcee65405ef1384236edcb70fa99c33ec1ba5b6efffa379b7a40567');
INSERT INTO blocks VALUES(310057,'4a5fdc84f2d66ecb6ee3e3646aad20751ce8694e64e348d3c8aab09d33a3e411',310057000,NULL,NULL,NULL,'b4a5de4ab2fee5a5d625e35691225e8d51ada6c0c0255778c72a372642b0d87d','036ea5db89c3f400ced8f0c647992549c31ef998ef2ba5372f8bab9f7350c81c','a1081f2413fbd2560461baf595448f880222468c8b4077b6cfac00d39cb338ed');
INSERT INTO blocks VALUES(310058,'a6eef3089896f0cae0bfe9423392e45c48f4efe4310b14d8cfbdb1fea613635f',310058000,NULL,NULL,NULL,'1783e1c883c3f10f8b4ed888002910370707bfa479c6deb48711f555a26d51b7','3b23f5405d3b09000fb0aa821a7428a765e0cc797462066f2f1945a4d5bac46d','e06b981c59cdbd09b2d97a229997bb769aabe00bf134755b2d820953c7d38e38');
INSERT INTO blocks VALUES(310059,'ab505de874c43f97c90be1c26a769e6c5cb140405c993b4a6cc7afc795f156a9',310059000,NULL,NULL,NULL,'4ecaeade9c9e63d43ea60eb7282b684b708f142e46ad25807c906e5a9b3da9b7','e16f202c96adcc82eca658ef7a3a0c9337b0d7697e7962f169c88003f08b0ad9','e32f5e3a701b3e126e84b584b1ec2e38116278d3ec659a9ed62ed606fe1c074d');
INSERT INTO blocks VALUES(310060,'974ad5fbef621e0a38eab811608dc9afaf10c8ecc85fed913075ba1a145e889b',310060000,NULL,NULL,NULL,'3073feeb0b9cb0680ce0775d2244d4b857945abf8057f9fff73e3e1dd990bf72','ec8dbee41f6b96b42b18d19cb0130d1b2844037766379bf70b2fc9950419f159','11c883cd18e74d4b4bcf2e7107b11dcca7774ff8804c6a53553a789e3aa6bcdc');
INSERT INTO blocks VALUES(310061,'35d267d21ad386e7b7632292af1c422b0310dde7ca49a82f9577525a29c138cf',310061000,NULL,NULL,NULL,'96c4c024112811085a4a502b04686eab225d64f129acb1acbd73cf1e6c402a2b','dff90307254bba6dd1b9de36951df93ae3b9b5664d4dbbbdd601ef46159df3aa','b33e43aa17a46cf5f40db4190bb89be9de423ab5b3736611b6c2bc9b9b39721d');
INSERT INTO blocks VALUES(310062,'b31a0054145319ef9de8c1cb19df5bcf4dc8a1ece20053aa494e5d3a00a2852f',310062000,NULL,NULL,NULL,'153c680b372c1c80d98ab8b80d9dd4260646551935f4f70063b99e0fb126bf9f','e1ac0b5ca8b1fa2e3f42cbcdd92ed18ddd69ee1a48963d8d8616ddc67202a3b6','5f750aff88b4bd4407f4373bce4f8495dddee809c4ff33a4fd02b111e6666fdb');
INSERT INTO blocks VALUES(310063,'0cbcbcd5b7f2dc288e3a34eab3d4212463a5a56e886804fb4f9f1cf929eadebe',310063000,NULL,NULL,NULL,'cb8ce9ef122691f289f254b5bd353e2b0c10a0b42f89e37095e6414e2d19e695','14598940a17ad5443be106ada719bd9b88befc4b351db32762ce6c37ea820095','9a2f56ff44d67ac2db139b87188d40d92717edf7c8e4ff2b4f2bf3e00a5a912a');
INSERT INTO blocks VALUES(310064,'e2db8065a195e85cde9ddb868a17d39893a60fb2b1255aa5f0c88729de7cbf30',310064000,NULL,NULL,NULL,'144936dc78bc9de33fff406f291fdd4627d910eecc7e3932131f26e3c13758e4','090a1d860230e9a7dd371bcd8af0c04f3f587d07dd58fd617218e2b28962c206','f7f7f475aae74c644f90d6ce63a2f5c09e030b39b6166ecfc2d3a3db302840d5');
INSERT INTO blocks VALUES(310065,'8a7bc7a77c831ac4fd11b8a9d22d1b6a0661b07cef05c2e600c7fb683b861d2a',310065000,NULL,NULL,NULL,'195858e58932f7cb09b1f372def847c0237dc0385ede7b5ea8c96058b40f5571','bafdba519c1792bc644fd3cd375bdb41769bb043ead9fc9770b9c955ef9cb33c','dc586184a7a1d6dfff0ddfa8128e5ca7cba114d376f2298e32f2e62eddb8ba71');
INSERT INTO blocks VALUES(310066,'b6959be51eb084747d301f7ccaf9e75f2292c9404633b1532e3692659939430d',310066000,NULL,NULL,NULL,'accaf75fad3f8c5dccf476cbcb4ab634243fe54f706746ddc9bbda86298a36a6','edec53d6b28605204d2ce3a859b33697fa6a9822840a9349bbc7a0d5a40155ad','cd54d836ca338381863c4a7762441f9db4d59a7b9d3157b7965c594a3d5b8964');
INSERT INTO blocks VALUES(310067,'8b08eae98d7193c9c01863fac6effb9162bda010daeacf9e0347112f233b8577',310067000,NULL,NULL,NULL,'d6846fdf6c9708dcd2e8c8644bb687d8da954989508b0d02d785d59b509d9909','82478225175e6c0598f6ffee293cb4c6e777c98f1d69dbb5afad816407311cac','4f3a60f8468f02d996bf456407db6895928ee8eeae9acb35dc8427bc540dd9d0');
INSERT INTO blocks VALUES(310068,'9280e7297ef6313341bc81787a36acfc9af58f83a415afff5e3154f126cf52b5',310068000,NULL,NULL,NULL,'b208ada2b6a94aafdaacd6fd01c32fb4ebc616dfb1c4aa02ac2289f4cf033fdd','c8a5f430bc112bcb93abf67cd8191a50113d99834401cc0226221089dd4cadec','27eee330424c08340424178f6503f8d16af2bc88c0d590a31fb0551453928227');
INSERT INTO blocks VALUES(310069,'486351f0655bf594ffaab1980cff17353b640b63e9c27239109addece189a6f7',310069000,NULL,NULL,NULL,'d0050dbf85c9fb5cfe88ade565a5976bf0fb6eea263d8980dd009a72a1c04f81','827491a15241506f819e4fd866efdb4fbb60626bd7dcb110822ab5a53c600b73','4e51f9bffad47885c00344032a0226c23da23d005bdfeab16b368c2a9a8e83d5');
INSERT INTO blocks VALUES(310070,'8739e99f4dee8bebf1332f37f49a125348b40b93b74fe35579dd52bfba4fa7e5',310070000,NULL,NULL,NULL,'df63fbb4133f74484b568da86c701e10c4e28b1c047fc27f93bc5287d013b15d','b36684e4bc62c7b5c61657035eb9aeec4c57a9ea095a764d7b13b6907f228db3','b724aa026cff67c751d0f86a7ae82856bd24544a9976ed58c0c66495d853b8c7');
INSERT INTO blocks VALUES(310071,'7a099aa1bba0ead577f1e44f35263a1f115ed6a868c98d4dd71609072ae7f80b',310071000,NULL,NULL,NULL,'b4127d65d3611e2bfbd974f1b90099a717d10a4b9b26d5ad817871ae3cdc8516','c0b275f9a791b0350155bfaf479f2c44ee11860303546b0e7ba10f85e7ccc390','6cf6c42e1824404a53d2c48dc66f22a7f427457d3ba1537f21f0a97cc669dbd2');
INSERT INTO blocks VALUES(310072,'7b17ecedc07552551b8129e068ae67cb176ca766ea3f6df74b597a94e3a7fc8a',310072000,NULL,NULL,NULL,'35e860497cf0a6046c1f0409dea188452333d2d9cf2a9e0ef3321bea5d4cf0e4','2f84bd8acdf2c160965ef865b1b647c778cfcdfcbe96ba59ce23860b30b901fc','3d41e5ffbcd67784d8988cf53be3632f882fb6dbd5aa6cb870c01a8a28470a2c');
INSERT INTO blocks VALUES(310073,'ee0fe3cc9b3a48a2746b6090b63b442b97ea6055d48edcf4b2288396764c6943',310073000,NULL,NULL,NULL,'322480282050f8f9699f2387e36df75724cf7dcb1025791664502891141e9d5c','05244f35e20367904a1d362cb73eee343a1398b5f252d36db09636408e5f8ad8','71de6e45f21e39c2408a80b5615f5ba77681aa261d8471fc6d56a3ff59537f32');
INSERT INTO blocks VALUES(310074,'ceab38dfde01f711a187601731ad575d67cfe0b7dbc61dcd4f15baaef72089fb',310074000,NULL,NULL,NULL,'a60e86ff8d795b087e4719ec9af48dffd197d33c26e46389b3b550111096109c','4f5835a9f926dd576ed5fb5e42ced4db84a45be88c5f984550ac9b608e97b0a9','b03ff25ec4fbf4095d3c58e6b227a03459212539837a5a7e13dc64cfecbad9c3');
INSERT INTO blocks VALUES(310075,'ef547198c6e36d829f117cfd7077ccde45158e3c545152225fa24dba7a26847b',310075000,NULL,NULL,NULL,'d3b5b430f3f4e608877232fdd5ae0c53ac10ce9a9b2c37e978eab16e8eb6ca62','49a7226bf3eb8aec80c78ae66b92b281f87181edb82957a8ca346a0e54a930f4','2ed3e1e38d41a7bddc7ff490bdcab21cc6470a5544d254023270e3cf83a0cd17');
INSERT INTO blocks VALUES(310076,'3b0499c2e8e8f0252c7288d4ecf66efc426ca37aad3524424d14c8bc6f8b0d92',310076000,NULL,NULL,NULL,'a494efaf91c425b73a1d14dcc8990c22037e44de21bee985c73f875b2d159632','e2e77bfb91a0804deee950519cc118016899497fceaaedc6f1bfd427d96861f2','7475dd992496525976dc769710f3026fb29c8bbc7d104cb50574e3987f68054e');
INSERT INTO blocks VALUES(310077,'d2adeefa9024ab3ff2822bc36acf19b6c647cea118cf15b86c6bc00c3322e7dd',310077000,NULL,NULL,NULL,'d930bbdef0c331b30f755de4969c5fd099b787461fc06e18006f0ba89c2be19c','8fcfd3ed8bccf8a8755119b3a56465e4009416706be1260066994151850a2501','01b8c34450d868bdf694e49d22b71e4ed67e2c10db8a247ae1b4393e6aa1208f');
INSERT INTO blocks VALUES(310078,'f6c17115ef0efe489c562bcda4615892b4d4b39db0c9791fe193d4922bd82cd6',310078000,NULL,NULL,NULL,'b11a6a52e7ed2aea8448941fdd9a56d9dceeb57a731c9ad1bb07468719ad30c8','024dfe1de002f7815f284967a0197eef6f7cb256dd9c992e4b938114aeaaddc3','13c5aff65e40d834020b099200dff150d6cc977f5ff4c722c5f3f0977c270c35');
INSERT INTO blocks VALUES(310079,'f2fbd2074d804e631db44cb0fb2e1db3fdc367e439c21ffc40d73104c4d7069c',310079000,NULL,NULL,NULL,'809be3ccf041d65c81fe99fade5310f2fb5de939964c29b381ca6c90ccdbca33','c3f8543a3a6f097d9204c8d08ac2651df88fbcba5c02b5ef763ff2e4d5aa1a95','a212b2e309f82e244bf0a6c4ebda2c173379a6e680cf4280cf5ee604ca3b8697');
INSERT INTO blocks VALUES(310080,'42943b914d9c367000a78b78a544cc4b84b1df838aadde33fe730964a89a3a6c',310080000,NULL,NULL,NULL,'1d53e6a686d25aaeb9d78755583d54f2f96fcc89083d1253afa1b2ce6dede2e7','66ff23b556f850ffb3817f8503f3f43e503a4e4beb2881c09939574b6fb6cfb8','bb8c7fde2942df5244a201f5fcad5c5e607622479930ce570adef3226492b401');
INSERT INTO blocks VALUES(310081,'6554f9d307976249e7b7e260e08046b3b55d318f8b6af627fed5be3063f123c4',310081000,NULL,NULL,NULL,'26f8aa2cd284d09e2a5d334359c04aee4d8cbc326aef762d3327812ab2ee8e56','ac3f8dc06d9cc9a9665a45f9e87da5c35468725641eaaa5dc6acb34f2bf5dae7','4650ba5a2fbce7d199f32e4432cf657bcf07de2d80fe2bc8f2d835e4f42e90a6');
INSERT INTO blocks VALUES(310082,'4f1ef91b1dcd575f8ac2e66a67715500cbca154bd6f3b8148bb7015a6aa6c644',310082000,NULL,NULL,NULL,'46973d6e354a34a5c54aaf399bd9f4094f015b690f1b8f70ed5b072a84a5f789','64c94b5a05c49d1e0ed3840c0029f277c0ca13970aab42a1618ecbc0eec7dd4c','5337559ce06ee60904cf5ad7c69fc1540dc93b98952051bc392edcff923c03b8');
INSERT INTO blocks VALUES(310083,'9b1f6fd6ff9b0dc4e37603cfb0625f49067c775b99e12492afd85392d3c8d850',310083000,NULL,NULL,NULL,'043f03eb05bbfdc6e7c48f94a7ab25821f77701567461fd6f05c72955c6045e2','3fda7366145f03925c36c356ad7dc3e8d9728abb635c388b4c57633d87344f30','7b79968fe22e6f792da2da1134194cc6ccef3c0cfbf7c33048a1139ae7072694');
INSERT INTO blocks VALUES(310084,'1e0972523e80306441b9f4157f171716199f1428db2e818a7f7817ccdc8859e3',310084000,NULL,NULL,NULL,'d89cb8329798749f3dd724b4e8aa6fed50d90b745dbe44eac5c256b8b1fbdab7','841d9470b5bd484734dafebf1167206e2c3552d24dca761e3b103134ed198d42','78528b4348f32125458612a8b05e039dc620c6ccdf58b65e45c7cc8fd4b00ddf');
INSERT INTO blocks VALUES(310085,'c5b6e9581831e3bc5848cd7630c499bca26d9ece5156d36579bdb72d54817e34',310085000,NULL,NULL,NULL,'5081d77b00967a2377093de6e85a1c6f4c8d9096995c9c261f726b55aa01cb16','671c091e2176f17bdeddc2f4ea54724022c60e4599b40fc671a3132d6c98f53b','3db17fe6bb3f0c2e85d10250bce3189da6ee99a80416dcdac75823799c71be92');
INSERT INTO blocks VALUES(310086,'080c1dc55a4ecf4824cf9840602498cfc35b5f84099f50b71b45cb63834c7a78',310086000,NULL,NULL,NULL,'97fa9e88a85bd3c418613187f0d63a682d00135c2bbc8add633b1f2cb397a6df','3687ddf0b29642f0c17d13d855a9e70ccbdb550a65ca70cf12f980cfad8dfba6','f025bcefdd58beebbb865116b1b761db34358e4287400dab4119f6df57907023');
INSERT INTO blocks VALUES(310087,'4ec8cb1c38b22904e8087a034a6406b896eff4dd28e7620601c6bddf82e2738c',310087000,NULL,NULL,NULL,'a060b83f15068d8eb40ffdd6e87a92b505e45c76e559351e8a4067b338d58b0e','6b6e049e26c6fd46611d8ce5585eb6d4dff64350e76eb4de0b86addb371baaa9','71bd79580fb774e75cb18ed5619f4eb47ffc7965fdef216a680d3a19553471e3');
INSERT INTO blocks VALUES(310088,'e945c815c433cbddd0bf8e66c5c23b51072483492acda98f5c2c201020a8c5b3',310088000,NULL,NULL,NULL,'d59defe063e13cb06084e22df43c5b7f087a557b5ce476aa650d0e85766283ca','f726bcda9551877030097c9192909f991dd1d450280b7ad6dcee8fc783b227c2','65c74c3631595f4b7e63793427c43ea5c93f9e1a18735f495e03f32d5ab03d2e');
INSERT INTO blocks VALUES(310089,'0382437f895ef3e7e38bf025fd4f606fd44d4bbd6aea71dbdc4ed11a7cd46f33',310089000,NULL,NULL,NULL,'87a14b55f40e81c605e22d00f6bd6c91d97b1efa8bb92838b78394df8c6a74e5','8c44fe940d2890839d7329614dec01f9781c73a1023e8d6337fbe7dd61137d5d','b2f1acb7f993f6f93ab6b651046f7768974535f34ca8e37e4d4002d5a05b0faf');
INSERT INTO blocks VALUES(310090,'b756db71dc037b5a4582de354a3347371267d31ebda453e152f0a13bb2fae969',310090000,NULL,NULL,NULL,'ecf81e18fd4f3d0f02f5ce0e3af0cface22b84e3595ee3126119befd62efbec3','b29a030f70c5aff779007e405a1f460cae174549a507b3e0f42e027674128534','467f84a59774bf1ab039b69fcd6c6f90ebf63cc8a1229207c9abafffa2105883');
INSERT INTO blocks VALUES(310091,'734a9aa485f36399d5efb74f3b9c47f8b5f6fd68c9967f134b14cfe7e2d7583c',310091000,NULL,NULL,NULL,'e3df34192b7b31ac8b3265cf26dd80fb0fdd6f1529a60d432c1fd1ed19e23bf2','d7c75866386756e0d7cc9ecea60bccf9bc7812466b8829066015a01c4908095a','a61d6e6c47756a434637138dc34b0f2f2c76e35f2014fd828ce318d24471b1e3');
INSERT INTO blocks VALUES(310092,'56386beb65f9228740d4ad43a1c575645f6daf59e0dd9f22551c59215b5e8c3d',310092000,NULL,NULL,NULL,'401a5b9d8f01042bc787b601f096d268209cd276f5cde9d526d94b11ddc8f8db','c50944f6da4f0f64cf66e3bf2a77c5d6b5bf5cda912f7a8bacaffc5cd70b6102','d6633affe8ee7df8ac8e5580ee8740e26d48a4ef0a227ef4831f2201d7f8c8f4');
INSERT INTO blocks VALUES(310093,'a74a2425f2f4be24bb5f715173e6756649e1cbf1b064aeb1ef60e0b94b418ddc',310093000,NULL,NULL,NULL,'9b0ec19d4bf43b50e12bd66b23eeaeb2ce7e223a8245e2dabbc19bd11ce21a40','ed38d5fe734a637580263be1db3276e0bf085572ca142a142cf5b0bce4a4d3fb','62d64fef1d6fffb5985f41d602f361148b941cea470495671eba29fcb923f638');
INSERT INTO blocks VALUES(310094,'2a8f976f20c4e89ff01071915ac96ee35192d54df3a246bf61fd4a0cccfb5b23',310094000,NULL,NULL,NULL,'fd27eca7bcf5f096061e892f9a21bb47fa86cdb32ba67562e3f34ab8e68a6627','6b16a02767311881f96858d9663e3f193682ce717d57d7d4faa80d44a6e8fcbd','9e4be5c476b49d10315a4c59296771cbb915af623f9b4ef230b9319c8982dd19');
INSERT INTO blocks VALUES(310095,'bed0fa40c9981223fb40b3be8124ca619edc9dd34d0c907369477ea92e5d2cd2',310095000,NULL,NULL,NULL,'ddf9fe363dfa3f851d6b662e42551c6f3d3b05a864758457a6cc22d15304e728','942839694e52397a2f4112e99e86eabb1b418a47eac227e4c45780be484c6173','50ee6474ade1650fc8a041b8e4e6bf9ec41b63229da6114b909bbd8f6b772dc4');
INSERT INTO blocks VALUES(310096,'306aeec3db435fabffdf88c2f26ee83caa4c2426375a33daa2be041dbd27ea2f',310096000,NULL,NULL,NULL,'e9e5d3d557faa26dbb23f06cf8ac907507b4aa9d128336da36efdefb36e63554','f99e7916717dce7f4cbf056efb1ae1b166aec4d919389bf7e56793ecffd8551a','55704dc0042b3ea66f7387118a642d7bf6092e2de7e208086a7a5455825203a6');
INSERT INTO blocks VALUES(310097,'13e8e16e67c7cdcc80d477491e554b43744f90e8e1a9728439a11fab42cefadf',310097000,NULL,NULL,NULL,'9123fe1a8c4b45012a5f5927dfc4ec4aa4bd9a16604ff3344ae95b1a394a85be','c8abfea30d25331a40a7f85c0014cf72ca2589126aa3a758f65f4cfae943e9f9','1cdc9c00deafeb4e2d6e3662d64a8bc54807b42c1be0feca4b3cfe761efd5d78');
INSERT INTO blocks VALUES(310098,'ca5bca4b5ec4fa6183e05176abe921cff884c4e20910fab55b603cef48dc3bca',310098000,NULL,NULL,NULL,'811a5c61947f9d9e29aa5e33457c0a5df1f422f8383d98d684b517a0a92f3423','807202b2a2474ce51bc2eb04baae65227e85c381d1e1c1b3b013bb752b61a8c1','61455590c8e08be658b8fcd1a292fdffafc51d1161d24128909440fca9b45926');
INSERT INTO blocks VALUES(310099,'3c4c2279cd7de0add5ec469648a845875495a7d54ebfb5b012dcc5a197b7992a',310099000,NULL,NULL,NULL,'527eebfb2c994343387ce3caffabca67fb478bce80b516f27474a142d65f68f7','6d5aa6af4a91471f42a6df821d460bcbd9899ffdec93446c23f5edf924c44764','6b356ea35ee6f6bbd26a7770c094224a04112e88cafa40bc38d636c02d3f2716');
INSERT INTO blocks VALUES(310100,'96925c05b3c7c80c716f5bef68d161c71d044252c766ca0e3f17f255764242cb',310100000,NULL,NULL,NULL,'d18b36c9a523c84365b561f8747b9469091a2af6055ec8605c9f07402bb9c131','5b079deddb141247a89f7f7145dc8b53ebdd192b93651f8ae3580d41165969ce','eacc62b7d2fd000b56b3cf0e87486f3cb99849fa2d688d55946286ca74f3e743');
INSERT INTO blocks VALUES(310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,NULL,NULL,NULL,'9ef1ea46847b94d3ba16b2f62b2cccb5d2813f8e58d26ac2952e914f8d75f89e','a5c06eba023f1c1d3065b549fbf077c4fcc5b278507aebdc892fc636a80d459f','540cf7a7f4287bc772e1739bcf402eec6fcb5058b2cdac9612b41f5ea746f892');
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
INSERT INTO broadcasts VALUES(12,'4c463de446788fd82021d9a61afdf87711edc0bfec6cea335c14f6966a791c4a',310011,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000000,100.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(19,'f32a9dc3652b5a34a1b402e2e74ca21fb176af7f4363c87e2479f43862b99fa3',310018,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000050,99.86166,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(20,'5a7dfb5d040d1f678a7ee2742e356470bd3eb70202d160c36d40a2ac455c7602',310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000101,100.343,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(21,'2ac0641e18da4abe25a2903291acb5ebee70346a7e6f2cf6b8af2357155a08c3',310020,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000201,2.0,5000000,'Unit Test',0,'valid');
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
INSERT INTO btcpays VALUES(5,'eff7f54c74ef873def02c9c01fb1528c4567652b3294879ebca1189d4e6e8c53',310004,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',50000000,'ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a_f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4','valid');
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
INSERT INTO burns VALUES(1,'77f08141941118b414589e9affe2b15dea5dbe8139a52cd26083f25c1f87c6eb',310000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',62000000,93000000000,'valid');
INSERT INTO burns VALUES(23,'e726ab1e20269b41f023967295b2aa5c277d678c1a821fe03a6ad816405f5b49',310022,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',38000000,56999887262,'valid');
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
INSERT INTO credits VALUES(310000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',93000000000,'burn','77f08141941118b414589e9affe2b15dea5dbe8139a52cd26083f25c1f87c6eb');
INSERT INTO credits VALUES(310001,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',50000000,'send','88fb0912c957d33f32021c55c3bb835e2c587bb8d38e745bca95ee070ce8357b');
INSERT INTO credits VALUES(310004,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'btcpay','eff7f54c74ef873def02c9c01fb1528c4567652b3294879ebca1189d4e6e8c53');
INSERT INTO credits VALUES(310005,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',1000000000,'issuance','db756d47b99b67f065d2f736dee3a42f06c6d1fd99f90db83bf9108281b9c03a');
INSERT INTO credits VALUES(310006,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC',100000,'issuance','dd638964cb69198b98ee08b69f934b5d2fded3a986a1fb5da0d5dc60ff4cf8f3');
INSERT INTO credits VALUES(310007,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBB',4000000,'send','b57db455f07acb9fae894954ee8f9f32ca6d474514efdde0ccbd144e56e49bf9');
INSERT INTO credits VALUES(310008,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',526,'send','96a04482fc202152dec10f962cf531cf7c33224e06ed92ae7d5b3916dc12029f');
INSERT INTO credits VALUES(310009,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',24,'dividend','bec899c5a6b6c680ab1d82e0f5678e9985a0485f044e2fcf1c01b536f5c9534f');
INSERT INTO credits VALUES(310010,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',420800,'dividend','1029ff552b19972d663283b45a442085422ccbce8d09c882f7c8901d00cee53d');
INSERT INTO credits VALUES(310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',4250000,'filled','571bf2b57a7251ca3e8dfc6df5f93b4cdb420976a4bcf3a8dcdb633af78f0fcf');
INSERT INTO credits VALUES(310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',5000000,'cancel order','f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4');
INSERT INTO credits VALUES(310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891');
INSERT INTO credits VALUES(310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891');
INSERT INTO credits VALUES(310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514');
INSERT INTO credits VALUES(310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514');
INSERT INTO credits VALUES(310018,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',59137500,'bet settled: liquidated for bear','f32a9dc3652b5a34a1b402e2e74ca21fb176af7f4363c87e2479f43862b99fa3');
INSERT INTO credits VALUES(310018,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',3112500,'feed fee','f32a9dc3652b5a34a1b402e2e74ca21fb176af7f4363c87e2479f43862b99fa3');
INSERT INTO credits VALUES(310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',159300000,'bet settled','5a7dfb5d040d1f678a7ee2742e356470bd3eb70202d160c36d40a2ac455c7602');
INSERT INTO credits VALUES(310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',315700000,'bet settled','5a7dfb5d040d1f678a7ee2742e356470bd3eb70202d160c36d40a2ac455c7602');
INSERT INTO credits VALUES(310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',25000000,'feed fee','5a7dfb5d040d1f678a7ee2742e356470bd3eb70202d160c36d40a2ac455c7602');
INSERT INTO credits VALUES(310020,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',1330000000,'bet settled: for notequal','2ac0641e18da4abe25a2903291acb5ebee70346a7e6f2cf6b8af2357155a08c3');
INSERT INTO credits VALUES(310020,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',70000000,'feed fee','2ac0641e18da4abe25a2903291acb5ebee70346a7e6f2cf6b8af2357155a08c3');
INSERT INTO credits VALUES(310022,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',56999887262,'burn','e726ab1e20269b41f023967295b2aa5c277d678c1a821fe03a6ad816405f5b49');
INSERT INTO credits VALUES(310023,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',8500000,'recredit wager remaining','4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf');
INSERT INTO credits VALUES(310023,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',10000,'send','179efdc874bbb88a8a7b475f54a51dabd0119ad7bf18be27a41f155258af86a3');
INSERT INTO credits VALUES(310032,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',50000000,'cancel order','ad327d1cdbf8db607518f98984766bbe594cc47ed24cbc84aac4e45de99fd038');
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
INSERT INTO debits VALUES(310001,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'send','88fb0912c957d33f32021c55c3bb835e2c587bb8d38e745bca95ee070ce8357b');
INSERT INTO debits VALUES(310003,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',105000000,'open order','f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4');
INSERT INTO debits VALUES(310005,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','db756d47b99b67f065d2f736dee3a42f06c6d1fd99f90db83bf9108281b9c03a');
INSERT INTO debits VALUES(310006,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','dd638964cb69198b98ee08b69f934b5d2fded3a986a1fb5da0d5dc60ff4cf8f3');
INSERT INTO debits VALUES(310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',4000000,'send','b57db455f07acb9fae894954ee8f9f32ca6d474514efdde0ccbd144e56e49bf9');
INSERT INTO debits VALUES(310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC',526,'send','96a04482fc202152dec10f962cf531cf7c33224e06ed92ae7d5b3916dc12029f');
INSERT INTO debits VALUES(310009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',24,'dividend','bec899c5a6b6c680ab1d82e0f5678e9985a0485f044e2fcf1c01b536f5c9534f');
INSERT INTO debits VALUES(310009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',20000,'dividend fee','bec899c5a6b6c680ab1d82e0f5678e9985a0485f044e2fcf1c01b536f5c9534f');
INSERT INTO debits VALUES(310010,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',420800,'dividend','1029ff552b19972d663283b45a442085422ccbce8d09c882f7c8901d00cee53d');
INSERT INTO debits VALUES(310010,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',20000,'dividend fee','1029ff552b19972d663283b45a442085422ccbce8d09c882f7c8901d00cee53d');
INSERT INTO debits VALUES(310012,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'bet','4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf');
INSERT INTO debits VALUES(310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',25000000,'bet','571bf2b57a7251ca3e8dfc6df5f93b4cdb420976a4bcf3a8dcdb633af78f0fcf');
INSERT INTO debits VALUES(310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',150000000,'bet','6ef15062104f20e15f0a7fc5ad3184e22cef35f3eff6aa0d3a6b0fb00482f2cd');
INSERT INTO debits VALUES(310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',350000000,'bet','9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891');
INSERT INTO debits VALUES(310016,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',750000000,'bet','69ea81f72e31ccd89ef9c363a72d210e58c5316df7b2ac3738604ff24fc57f31');
INSERT INTO debits VALUES(310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',650000000,'bet','8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514');
INSERT INTO debits VALUES(310021,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',50000000,'open order','ad327d1cdbf8db607518f98984766bbe594cc47ed24cbc84aac4e45de99fd038');
INSERT INTO debits VALUES(310023,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC',10000,'send','179efdc874bbb88a8a7b475f54a51dabd0119ad7bf18be27a41f155258af86a3');
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
INSERT INTO dividends VALUES(10,'bec899c5a6b6c680ab1d82e0f5678e9985a0485f044e2fcf1c01b536f5c9534f',310009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB','XCP',600,20000,'valid');
INSERT INTO dividends VALUES(11,'1029ff552b19972d663283b45a442085422ccbce8d09c882f7c8901d00cee53d',310010,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC','XCP',800,20000,'valid');
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
INSERT INTO issuances VALUES(6,'db756d47b99b67f065d2f736dee3a42f06c6d1fd99f90db83bf9108281b9c03a',310005,'BBBB',1000000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'',50000000,0,'valid');
INSERT INTO issuances VALUES(7,'dd638964cb69198b98ee08b69f934b5d2fded3a986a1fb5da0d5dc60ff4cf8f3',310006,'BBBC',100000,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'foobar',50000000,0,'valid');
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
INSERT INTO messages VALUES(0,310000,'insert','credits','{"action": "burn", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310000, "event": "77f08141941118b414589e9affe2b15dea5dbe8139a52cd26083f25c1f87c6eb", "quantity": 93000000000}',0);
INSERT INTO messages VALUES(1,310000,'insert','burns','{"block_index": 310000, "burned": 62000000, "earned": 93000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "77f08141941118b414589e9affe2b15dea5dbe8139a52cd26083f25c1f87c6eb", "tx_index": 1}',0);
INSERT INTO messages VALUES(2,310001,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310001, "event": "88fb0912c957d33f32021c55c3bb835e2c587bb8d38e745bca95ee070ce8357b", "quantity": 50000000}',0);
INSERT INTO messages VALUES(3,310001,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310001, "event": "88fb0912c957d33f32021c55c3bb835e2c587bb8d38e745bca95ee070ce8357b", "quantity": 50000000}',0);
INSERT INTO messages VALUES(4,310001,'insert','sends','{"asset": "XCP", "block_index": 310001, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 50000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "88fb0912c957d33f32021c55c3bb835e2c587bb8d38e745bca95ee070ce8357b", "tx_index": 2}',0);
INSERT INTO messages VALUES(5,310002,'insert','orders','{"block_index": 310002, "expiration": 10, "expire_index": 310012, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 50000000, "give_remaining": 50000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a", "tx_index": 3}',0);
INSERT INTO messages VALUES(6,310003,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310003, "event": "f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4", "quantity": 105000000}',0);
INSERT INTO messages VALUES(7,310003,'insert','orders','{"block_index": 310003, "expiration": 10, "expire_index": 310013, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 50000000, "get_remaining": 50000000, "give_asset": "XCP", "give_quantity": 105000000, "give_remaining": 105000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4", "tx_index": 4}',0);
INSERT INTO messages VALUES(8,310003,'update','orders','{"fee_provided_remaining": 142858, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a"}',0);
INSERT INTO messages VALUES(9,310003,'update','orders','{"fee_provided_remaining": 6800, "fee_required_remaining": 42858, "get_remaining": 0, "give_remaining": 5000000, "status": "open", "tx_hash": "f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4"}',0);
INSERT INTO messages VALUES(10,310003,'insert','order_matches','{"backward_asset": "XCP", "backward_quantity": 100000000, "block_index": 310003, "fee_paid": 857142, "forward_asset": "BTC", "forward_quantity": 50000000, "id": "ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a_f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4", "match_expire_index": 310023, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 310002, "tx0_expiration": 10, "tx0_hash": "ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a", "tx0_index": 3, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_block_index": 310003, "tx1_expiration": 10, "tx1_hash": "f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4", "tx1_index": 4}',0);
INSERT INTO messages VALUES(11,310004,'insert','credits','{"action": "btcpay", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310004, "event": "eff7f54c74ef873def02c9c01fb1528c4567652b3294879ebca1189d4e6e8c53", "quantity": 100000000}',0);
INSERT INTO messages VALUES(12,310004,'update','order_matches','{"order_match_id": "ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a_f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4", "status": "completed"}',0);
INSERT INTO messages VALUES(13,310004,'insert','btcpays','{"block_index": 310004, "btc_amount": 50000000, "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "order_match_id": "ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a_f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4", "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "eff7f54c74ef873def02c9c01fb1528c4567652b3294879ebca1189d4e6e8c53", "tx_index": 5}',0);
INSERT INTO messages VALUES(14,310005,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310005, "event": "db756d47b99b67f065d2f736dee3a42f06c6d1fd99f90db83bf9108281b9c03a", "quantity": 50000000}',0);
INSERT INTO messages VALUES(15,310005,'insert','issuances','{"asset": "BBBB", "block_index": 310005, "call_date": 0, "call_price": 0.0, "callable": false, "description": "", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "db756d47b99b67f065d2f736dee3a42f06c6d1fd99f90db83bf9108281b9c03a", "tx_index": 6}',0);
INSERT INTO messages VALUES(16,310005,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBB", "block_index": 310005, "event": "db756d47b99b67f065d2f736dee3a42f06c6d1fd99f90db83bf9108281b9c03a", "quantity": 1000000000}',0);
INSERT INTO messages VALUES(17,310006,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310006, "event": "dd638964cb69198b98ee08b69f934b5d2fded3a986a1fb5da0d5dc60ff4cf8f3", "quantity": 50000000}',0);
INSERT INTO messages VALUES(18,310006,'insert','issuances','{"asset": "BBBC", "block_index": 310006, "call_date": 0, "call_price": 0.0, "callable": false, "description": "foobar", "divisible": false, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "dd638964cb69198b98ee08b69f934b5d2fded3a986a1fb5da0d5dc60ff4cf8f3", "tx_index": 7}',0);
INSERT INTO messages VALUES(19,310006,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBC", "block_index": 310006, "event": "dd638964cb69198b98ee08b69f934b5d2fded3a986a1fb5da0d5dc60ff4cf8f3", "quantity": 100000}',0);
INSERT INTO messages VALUES(20,310007,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBB", "block_index": 310007, "event": "b57db455f07acb9fae894954ee8f9f32ca6d474514efdde0ccbd144e56e49bf9", "quantity": 4000000}',0);
INSERT INTO messages VALUES(21,310007,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "BBBB", "block_index": 310007, "event": "b57db455f07acb9fae894954ee8f9f32ca6d474514efdde0ccbd144e56e49bf9", "quantity": 4000000}',0);
INSERT INTO messages VALUES(22,310007,'insert','sends','{"asset": "BBBB", "block_index": 310007, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 4000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "b57db455f07acb9fae894954ee8f9f32ca6d474514efdde0ccbd144e56e49bf9", "tx_index": 8}',0);
INSERT INTO messages VALUES(23,310008,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBC", "block_index": 310008, "event": "96a04482fc202152dec10f962cf531cf7c33224e06ed92ae7d5b3916dc12029f", "quantity": 526}',0);
INSERT INTO messages VALUES(24,310008,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "BBBC", "block_index": 310008, "event": "96a04482fc202152dec10f962cf531cf7c33224e06ed92ae7d5b3916dc12029f", "quantity": 526}',0);
INSERT INTO messages VALUES(25,310008,'insert','sends','{"asset": "BBBC", "block_index": 310008, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 526, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "96a04482fc202152dec10f962cf531cf7c33224e06ed92ae7d5b3916dc12029f", "tx_index": 9}',0);
INSERT INTO messages VALUES(26,310009,'insert','debits','{"action": "dividend", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310009, "event": "bec899c5a6b6c680ab1d82e0f5678e9985a0485f044e2fcf1c01b536f5c9534f", "quantity": 24}',0);
INSERT INTO messages VALUES(27,310009,'insert','debits','{"action": "dividend fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310009, "event": "bec899c5a6b6c680ab1d82e0f5678e9985a0485f044e2fcf1c01b536f5c9534f", "quantity": 20000}',0);
INSERT INTO messages VALUES(28,310009,'insert','credits','{"action": "dividend", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310009, "event": "bec899c5a6b6c680ab1d82e0f5678e9985a0485f044e2fcf1c01b536f5c9534f", "quantity": 24}',0);
INSERT INTO messages VALUES(29,310009,'insert','dividends','{"asset": "BBBB", "block_index": 310009, "dividend_asset": "XCP", "fee_paid": 20000, "quantity_per_unit": 600, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "bec899c5a6b6c680ab1d82e0f5678e9985a0485f044e2fcf1c01b536f5c9534f", "tx_index": 10}',0);
INSERT INTO messages VALUES(30,310010,'insert','debits','{"action": "dividend", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310010, "event": "1029ff552b19972d663283b45a442085422ccbce8d09c882f7c8901d00cee53d", "quantity": 420800}',0);
INSERT INTO messages VALUES(31,310010,'insert','debits','{"action": "dividend fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310010, "event": "1029ff552b19972d663283b45a442085422ccbce8d09c882f7c8901d00cee53d", "quantity": 20000}',0);
INSERT INTO messages VALUES(32,310010,'insert','credits','{"action": "dividend", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310010, "event": "1029ff552b19972d663283b45a442085422ccbce8d09c882f7c8901d00cee53d", "quantity": 420800}',0);
INSERT INTO messages VALUES(33,310010,'insert','dividends','{"asset": "BBBC", "block_index": 310010, "dividend_asset": "XCP", "fee_paid": 20000, "quantity_per_unit": 800, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "1029ff552b19972d663283b45a442085422ccbce8d09c882f7c8901d00cee53d", "tx_index": 11}',0);
INSERT INTO messages VALUES(34,310011,'insert','broadcasts','{"block_index": 310011, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "4c463de446788fd82021d9a61afdf87711edc0bfec6cea335c14f6966a791c4a", "tx_index": 12, "value": 100.0}',0);
INSERT INTO messages VALUES(35,310012,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310012, "event": "4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf", "quantity": 50000000}',0);
INSERT INTO messages VALUES(36,310012,'insert','bets','{"bet_type": 0, "block_index": 310012, "counterwager_quantity": 25000000, "counterwager_remaining": 25000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310022, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 15120, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf", "tx_index": 13, "wager_quantity": 50000000, "wager_remaining": 50000000}',0);
INSERT INTO messages VALUES(37,310013,'update','orders','{"status": "expired", "tx_hash": "ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a"}',0);
INSERT INTO messages VALUES(38,310013,'insert','order_expirations','{"block_index": 310013, "order_hash": "ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a", "order_index": 3, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
INSERT INTO messages VALUES(39,310013,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310013, "event": "571bf2b57a7251ca3e8dfc6df5f93b4cdb420976a4bcf3a8dcdb633af78f0fcf", "quantity": 25000000}',0);
INSERT INTO messages VALUES(40,310013,'insert','bets','{"bet_type": 1, "block_index": 310013, "counterwager_quantity": 41500000, "counterwager_remaining": 41500000, "deadline": 1388000100, "expiration": 10, "expire_index": 310023, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 15120, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "571bf2b57a7251ca3e8dfc6df5f93b4cdb420976a4bcf3a8dcdb633af78f0fcf", "tx_index": 14, "wager_quantity": 25000000, "wager_remaining": 25000000}',0);
INSERT INTO messages VALUES(41,310013,'update','bets','{"counterwager_remaining": 4250000, "status": "open", "tx_hash": "4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf", "wager_remaining": 8500000}',0);
INSERT INTO messages VALUES(42,310013,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310013, "event": "571bf2b57a7251ca3e8dfc6df5f93b4cdb420976a4bcf3a8dcdb633af78f0fcf", "quantity": 4250000}',0);
INSERT INTO messages VALUES(43,310013,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "571bf2b57a7251ca3e8dfc6df5f93b4cdb420976a4bcf3a8dcdb633af78f0fcf", "wager_remaining": 4250000}',0);
INSERT INTO messages VALUES(44,310013,'insert','bet_matches','{"backward_quantity": 20750000, "block_index": 310013, "deadline": 1388000100, "fee_fraction_int": 5000000, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 41500000, "id": "4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf_571bf2b57a7251ca3e8dfc6df5f93b4cdb420976a4bcf3a8dcdb633af78f0fcf", "initial_value": 100.0, "leverage": 15120, "match_expire_index": 310022, "status": "pending", "target_value": 0.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 0, "tx0_block_index": 310012, "tx0_expiration": 10, "tx0_hash": "4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf", "tx0_index": 13, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_bet_type": 1, "tx1_block_index": 310013, "tx1_expiration": 10, "tx1_hash": "571bf2b57a7251ca3e8dfc6df5f93b4cdb420976a4bcf3a8dcdb633af78f0fcf", "tx1_index": 14}',0);
INSERT INTO messages VALUES(45,310014,'update','orders','{"status": "expired", "tx_hash": "f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4"}',0);
INSERT INTO messages VALUES(46,310014,'insert','credits','{"action": "cancel order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310014, "event": "f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4", "quantity": 5000000}',0);
INSERT INTO messages VALUES(47,310014,'insert','order_expirations','{"block_index": 310014, "order_hash": "f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4", "order_index": 4, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
INSERT INTO messages VALUES(48,310014,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310014, "event": "6ef15062104f20e15f0a7fc5ad3184e22cef35f3eff6aa0d3a6b0fb00482f2cd", "quantity": 150000000}',0);
INSERT INTO messages VALUES(49,310014,'insert','bets','{"bet_type": 0, "block_index": 310014, "counterwager_quantity": 350000000, "counterwager_remaining": 350000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310024, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "6ef15062104f20e15f0a7fc5ad3184e22cef35f3eff6aa0d3a6b0fb00482f2cd", "tx_index": 15, "wager_quantity": 150000000, "wager_remaining": 150000000}',0);
INSERT INTO messages VALUES(50,310015,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310015, "event": "9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891", "quantity": 350000000}',0);
INSERT INTO messages VALUES(51,310015,'insert','bets','{"bet_type": 1, "block_index": 310015, "counterwager_quantity": 150000000, "counterwager_remaining": 150000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310025, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891", "tx_index": 16, "wager_quantity": 350000000, "wager_remaining": 350000000}',0);
INSERT INTO messages VALUES(52,310015,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310015, "event": "9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891", "quantity": 0}',0);
INSERT INTO messages VALUES(53,310015,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "6ef15062104f20e15f0a7fc5ad3184e22cef35f3eff6aa0d3a6b0fb00482f2cd", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(54,310015,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310015, "event": "9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891", "quantity": 0}',0);
INSERT INTO messages VALUES(55,310015,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(56,310015,'insert','bet_matches','{"backward_quantity": 350000000, "block_index": 310015, "deadline": 1388000100, "fee_fraction_int": 5000000, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 150000000, "id": "6ef15062104f20e15f0a7fc5ad3184e22cef35f3eff6aa0d3a6b0fb00482f2cd_9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891", "initial_value": 100.0, "leverage": 5040, "match_expire_index": 310024, "status": "pending", "target_value": 0.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 0, "tx0_block_index": 310014, "tx0_expiration": 10, "tx0_hash": "6ef15062104f20e15f0a7fc5ad3184e22cef35f3eff6aa0d3a6b0fb00482f2cd", "tx0_index": 15, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_bet_type": 1, "tx1_block_index": 310015, "tx1_expiration": 10, "tx1_hash": "9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891", "tx1_index": 16}',0);
INSERT INTO messages VALUES(57,310016,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310016, "event": "69ea81f72e31ccd89ef9c363a72d210e58c5316df7b2ac3738604ff24fc57f31", "quantity": 750000000}',0);
INSERT INTO messages VALUES(58,310016,'insert','bets','{"bet_type": 2, "block_index": 310016, "counterwager_quantity": 650000000, "counterwager_remaining": 650000000, "deadline": 1388000200, "expiration": 10, "expire_index": 310026, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 1.0, "tx_hash": "69ea81f72e31ccd89ef9c363a72d210e58c5316df7b2ac3738604ff24fc57f31", "tx_index": 17, "wager_quantity": 750000000, "wager_remaining": 750000000}',0);
INSERT INTO messages VALUES(59,310017,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310017, "event": "8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514", "quantity": 650000000}',0);
INSERT INTO messages VALUES(60,310017,'insert','bets','{"bet_type": 3, "block_index": 310017, "counterwager_quantity": 750000000, "counterwager_remaining": 750000000, "deadline": 1388000200, "expiration": 10, "expire_index": 310027, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 1.0, "tx_hash": "8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514", "tx_index": 18, "wager_quantity": 650000000, "wager_remaining": 650000000}',0);
INSERT INTO messages VALUES(61,310017,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310017, "event": "8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514", "quantity": 0}',0);
INSERT INTO messages VALUES(62,310017,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "69ea81f72e31ccd89ef9c363a72d210e58c5316df7b2ac3738604ff24fc57f31", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(63,310017,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310017, "event": "8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514", "quantity": 0}',0);
INSERT INTO messages VALUES(64,310017,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(65,310017,'insert','bet_matches','{"backward_quantity": 650000000, "block_index": 310017, "deadline": 1388000200, "fee_fraction_int": 5000000, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 750000000, "id": "69ea81f72e31ccd89ef9c363a72d210e58c5316df7b2ac3738604ff24fc57f31_8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514", "initial_value": 100.0, "leverage": 5040, "match_expire_index": 310026, "status": "pending", "target_value": 1.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 2, "tx0_block_index": 310016, "tx0_expiration": 10, "tx0_hash": "69ea81f72e31ccd89ef9c363a72d210e58c5316df7b2ac3738604ff24fc57f31", "tx0_index": 17, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_bet_type": 3, "tx1_block_index": 310017, "tx1_expiration": 10, "tx1_hash": "8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514", "tx1_index": 18}',0);
INSERT INTO messages VALUES(66,310018,'insert','broadcasts','{"block_index": 310018, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000050, "tx_hash": "f32a9dc3652b5a34a1b402e2e74ca21fb176af7f4363c87e2479f43862b99fa3", "tx_index": 19, "value": 99.86166}',0);
INSERT INTO messages VALUES(67,310018,'insert','credits','{"action": "bet settled: liquidated for bear", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310018, "event": "f32a9dc3652b5a34a1b402e2e74ca21fb176af7f4363c87e2479f43862b99fa3", "quantity": 59137500}',0);
INSERT INTO messages VALUES(68,310018,'insert','credits','{"action": "feed fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310018, "event": "f32a9dc3652b5a34a1b402e2e74ca21fb176af7f4363c87e2479f43862b99fa3", "quantity": 3112500}',0);
INSERT INTO messages VALUES(69,310018,'insert','bet_match_resolutions','{"bear_credit": 59137500, "bet_match_id": "4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf_571bf2b57a7251ca3e8dfc6df5f93b4cdb420976a4bcf3a8dcdb633af78f0fcf", "bet_match_type_id": 1, "block_index": 310018, "bull_credit": 0, "escrow_less_fee": null, "fee": 3112500, "settled": false, "winner": null}',0);
INSERT INTO messages VALUES(70,310018,'update','bet_matches','{"bet_match_id": "4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf_571bf2b57a7251ca3e8dfc6df5f93b4cdb420976a4bcf3a8dcdb633af78f0fcf", "status": "settled: liquidated for bear"}',0);
INSERT INTO messages VALUES(71,310019,'insert','broadcasts','{"block_index": 310019, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000101, "tx_hash": "5a7dfb5d040d1f678a7ee2742e356470bd3eb70202d160c36d40a2ac455c7602", "tx_index": 20, "value": 100.343}',0);
INSERT INTO messages VALUES(72,310019,'insert','credits','{"action": "bet settled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310019, "event": "5a7dfb5d040d1f678a7ee2742e356470bd3eb70202d160c36d40a2ac455c7602", "quantity": 159300000}',0);
INSERT INTO messages VALUES(73,310019,'insert','credits','{"action": "bet settled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310019, "event": "5a7dfb5d040d1f678a7ee2742e356470bd3eb70202d160c36d40a2ac455c7602", "quantity": 315700000}',0);
INSERT INTO messages VALUES(74,310019,'insert','credits','{"action": "feed fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310019, "event": "5a7dfb5d040d1f678a7ee2742e356470bd3eb70202d160c36d40a2ac455c7602", "quantity": 25000000}',0);
INSERT INTO messages VALUES(75,310019,'insert','bet_match_resolutions','{"bear_credit": 315700000, "bet_match_id": "6ef15062104f20e15f0a7fc5ad3184e22cef35f3eff6aa0d3a6b0fb00482f2cd_9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891", "bet_match_type_id": 1, "block_index": 310019, "bull_credit": 159300000, "escrow_less_fee": null, "fee": 25000000, "settled": true, "winner": null}',0);
INSERT INTO messages VALUES(76,310019,'update','bet_matches','{"bet_match_id": "6ef15062104f20e15f0a7fc5ad3184e22cef35f3eff6aa0d3a6b0fb00482f2cd_9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891", "status": "settled"}',0);
INSERT INTO messages VALUES(77,310020,'insert','broadcasts','{"block_index": 310020, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000201, "tx_hash": "2ac0641e18da4abe25a2903291acb5ebee70346a7e6f2cf6b8af2357155a08c3", "tx_index": 21, "value": 2.0}',0);
INSERT INTO messages VALUES(78,310020,'insert','credits','{"action": "bet settled: for notequal", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310020, "event": "2ac0641e18da4abe25a2903291acb5ebee70346a7e6f2cf6b8af2357155a08c3", "quantity": 1330000000}',0);
INSERT INTO messages VALUES(79,310020,'insert','credits','{"action": "feed fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310020, "event": "2ac0641e18da4abe25a2903291acb5ebee70346a7e6f2cf6b8af2357155a08c3", "quantity": 70000000}',0);
INSERT INTO messages VALUES(80,310020,'insert','bet_match_resolutions','{"bear_credit": null, "bet_match_id": "69ea81f72e31ccd89ef9c363a72d210e58c5316df7b2ac3738604ff24fc57f31_8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514", "bet_match_type_id": 5, "block_index": 310020, "bull_credit": null, "escrow_less_fee": 1330000000, "fee": 70000000, "settled": null, "winner": "NotEqual"}',0);
INSERT INTO messages VALUES(81,310020,'update','bet_matches','{"bet_match_id": "69ea81f72e31ccd89ef9c363a72d210e58c5316df7b2ac3738604ff24fc57f31_8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514", "status": "settled: for notequal"}',0);
INSERT INTO messages VALUES(82,310021,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBB", "block_index": 310021, "event": "ad327d1cdbf8db607518f98984766bbe594cc47ed24cbc84aac4e45de99fd038", "quantity": 50000000}',0);
INSERT INTO messages VALUES(83,310021,'insert','orders','{"block_index": 310021, "expiration": 10, "expire_index": 310031, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 50000000, "get_remaining": 50000000, "give_asset": "BBBB", "give_quantity": 50000000, "give_remaining": 50000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "ad327d1cdbf8db607518f98984766bbe594cc47ed24cbc84aac4e45de99fd038", "tx_index": 22}',0);
INSERT INTO messages VALUES(84,310022,'insert','credits','{"action": "burn", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310022, "event": "e726ab1e20269b41f023967295b2aa5c277d678c1a821fe03a6ad816405f5b49", "quantity": 56999887262}',0);
INSERT INTO messages VALUES(85,310022,'insert','burns','{"block_index": 310022, "burned": 38000000, "earned": 56999887262, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "e726ab1e20269b41f023967295b2aa5c277d678c1a821fe03a6ad816405f5b49", "tx_index": 23}',0);
INSERT INTO messages VALUES(86,310023,'update','bets','{"status": "expired", "tx_hash": "4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf"}',0);
INSERT INTO messages VALUES(87,310023,'insert','credits','{"action": "recredit wager remaining", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310023, "event": "4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf", "quantity": 8500000}',0);
INSERT INTO messages VALUES(88,310023,'insert','bet_expirations','{"bet_hash": "4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf", "bet_index": 13, "block_index": 310023, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
INSERT INTO messages VALUES(89,310023,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBC", "block_index": 310023, "event": "179efdc874bbb88a8a7b475f54a51dabd0119ad7bf18be27a41f155258af86a3", "quantity": 10000}',0);
INSERT INTO messages VALUES(90,310023,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "BBBC", "block_index": 310023, "event": "179efdc874bbb88a8a7b475f54a51dabd0119ad7bf18be27a41f155258af86a3", "quantity": 10000}',0);
INSERT INTO messages VALUES(91,310023,'insert','sends','{"asset": "BBBC", "block_index": 310023, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 10000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "179efdc874bbb88a8a7b475f54a51dabd0119ad7bf18be27a41f155258af86a3", "tx_index": 24}',0);
INSERT INTO messages VALUES(92,310032,'update','orders','{"status": "expired", "tx_hash": "ad327d1cdbf8db607518f98984766bbe594cc47ed24cbc84aac4e45de99fd038"}',0);
INSERT INTO messages VALUES(93,310032,'insert','credits','{"action": "cancel order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBB", "block_index": 310032, "event": "ad327d1cdbf8db607518f98984766bbe594cc47ed24cbc84aac4e45de99fd038", "quantity": 50000000}',0);
INSERT INTO messages VALUES(94,310032,'insert','order_expirations','{"block_index": 310032, "order_hash": "ad327d1cdbf8db607518f98984766bbe594cc47ed24cbc84aac4e45de99fd038", "order_index": 22, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
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
INSERT INTO order_expirations VALUES(4,'f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',310014);
INSERT INTO order_expirations VALUES(22,'ad327d1cdbf8db607518f98984766bbe594cc47ed24cbc84aac4e45de99fd038','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',310032);
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
INSERT INTO order_matches VALUES('ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a_f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4',3,'ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',4,'f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BTC',50000000,'XCP',100000000,310002,310003,310003,10,10,310023,857142,'completed');
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
INSERT INTO orders VALUES(4,'f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4',310003,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',105000000,5000000,'BTC',50000000,0,10,310013,900000,42858,6800,6800,'expired');
INSERT INTO orders VALUES(22,'ad327d1cdbf8db607518f98984766bbe594cc47ed24cbc84aac4e45de99fd038',310021,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',50000000,50000000,'XCP',50000000,50000000,10,310031,0,0,6800,6800,'expired');
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
INSERT INTO sends VALUES(2,'88fb0912c957d33f32021c55c3bb835e2c587bb8d38e745bca95ee070ce8357b',310001,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',50000000,'valid');
INSERT INTO sends VALUES(8,'b57db455f07acb9fae894954ee8f9f32ca6d474514efdde0ccbd144e56e49bf9',310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBB',4000000,'valid');
INSERT INTO sends VALUES(9,'96a04482fc202152dec10f962cf531cf7c33224e06ed92ae7d5b3916dc12029f',310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',526,'valid');
INSERT INTO sends VALUES(24,'179efdc874bbb88a8a7b475f54a51dabd0119ad7bf18be27a41f155258af86a3',310023,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',10000,'valid');
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
INSERT INTO transactions VALUES(1,'77f08141941118b414589e9affe2b15dea5dbe8139a52cd26083f25c1f87c6eb',310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
INSERT INTO transactions VALUES(2,'88fb0912c957d33f32021c55c3bb835e2c587bb8d38e745bca95ee070ce8357b',310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,7650,X'0000000000000000000000010000000002FAF080',1);
INSERT INTO transactions VALUES(3,'ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a',310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,1000000,X'0000000A00000000000000000000000002FAF08000000000000000010000000005F5E100000A0000000000000000',1);
INSERT INTO transactions VALUES(4,'f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4',310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000000010000000006422C4000000000000000000000000002FAF080000A00000000000DBBA0',1);
INSERT INTO transactions VALUES(5,'eff7f54c74ef873def02c9c01fb1528c4567652b3294879ebca1189d4e6e8c53',310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',50000000,9675,X'0000000BAD6082998925F47865B58B6D344C1B1CF0AB059D091F33334CCB92436F37EB8AF6D59B73FAC606F1704AF16FCD812A5CFD07E8A48C172CF06447447CFB3E6CD4',1);
INSERT INTO transactions VALUES(6,'db756d47b99b67f065d2f736dee3a42f06c6d1fd99f90db83bf9108281b9c03a',310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'000000140000000000004767000000003B9ACA000100000000000000000000',1);
INSERT INTO transactions VALUES(7,'dd638964cb69198b98ee08b69f934b5d2fded3a986a1fb5da0d5dc60ff4cf8f3',310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'00000014000000000000476800000000000186A00000000000000000000006666F6F626172',1);
INSERT INTO transactions VALUES(8,'b57db455f07acb9fae894954ee8f9f32ca6d474514efdde0ccbd144e56e49bf9',310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,7650,X'00000000000000000000476700000000003D0900',1);
INSERT INTO transactions VALUES(9,'96a04482fc202152dec10f962cf531cf7c33224e06ed92ae7d5b3916dc12029f',310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,7650,X'000000000000000000004768000000000000020E',1);
INSERT INTO transactions VALUES(10,'bec899c5a6b6c680ab1d82e0f5678e9985a0485f044e2fcf1c01b536f5c9534f',310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'00000032000000000000025800000000000047670000000000000001',1);
INSERT INTO transactions VALUES(11,'1029ff552b19972d663283b45a442085422ccbce8d09c882f7c8901d00cee53d',310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'00000032000000000000032000000000000047680000000000000001',1);
INSERT INTO transactions VALUES(12,'4c463de446788fd82021d9a61afdf87711edc0bfec6cea335c14f6966a791c4a',310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001E52BB33004059000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(13,'4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf',310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000052BB33640000000002FAF08000000000017D7840000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(14,'571bf2b57a7251ca3e8dfc6df5f93b4cdb420976a4bcf3a8dcdb633af78f0fcf',310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000152BB336400000000017D78400000000002793D60000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(15,'6ef15062104f20e15f0a7fc5ad3184e22cef35f3eff6aa0d3a6b0fb00482f2cd',310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000052BB33640000000008F0D1800000000014DC93800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(16,'9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891',310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000152BB33640000000014DC93800000000008F0D1800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(17,'69ea81f72e31ccd89ef9c363a72d210e58c5316df7b2ac3738604ff24fc57f31',310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000252BB33C8000000002CB417800000000026BE36803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(18,'8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514',310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000352BB33C80000000026BE3680000000002CB417803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(19,'f32a9dc3652b5a34a1b402e2e74ca21fb176af7f4363c87e2479f43862b99fa3',310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001E52BB33324058F7256FFC115E004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(20,'5a7dfb5d040d1f678a7ee2742e356470bd3eb70202d160c36d40a2ac455c7602',310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001E52BB3365405915F3B645A1CB004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(21,'2ac0641e18da4abe25a2903291acb5ebee70346a7e6f2cf6b8af2357155a08c3',310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001E52BB33C94000000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(22,'ad327d1cdbf8db607518f98984766bbe594cc47ed24cbc84aac4e45de99fd038',310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000047670000000002FAF08000000000000000010000000002FAF080000A0000000000000000',1);
INSERT INTO transactions VALUES(23,'e726ab1e20269b41f023967295b2aa5c277d678c1a821fe03a6ad816405f5b49',310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mvCounterpartyXXXXXXXXXXXXXXW24Hef',100000000,5625,X'',1);
INSERT INTO transactions VALUES(24,'179efdc874bbb88a8a7b475f54a51dabd0119ad7bf18be27a41f155258af86a3',310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,7650,X'0000000000000000000047680000000000002710',1);
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
INSERT INTO undolog VALUES(14,'UPDATE orders SET tx_index=4,tx_hash=''f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4'',block_index=310003,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''XCP'',give_quantity=105000000,give_remaining=105000000,get_asset=''BTC'',get_quantity=50000000,get_remaining=50000000,expiration=10,expire_index=310013,fee_required=900000,fee_required_remaining=900000,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(15,'DELETE FROM order_matches WHERE rowid=1');
INSERT INTO undolog VALUES(16,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92845000000 WHERE rowid=1');
INSERT INTO undolog VALUES(17,'DELETE FROM credits WHERE rowid=3');
INSERT INTO undolog VALUES(18,'UPDATE order_matches SET id=''ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a_f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4'',tx0_index=3,tx0_hash=''ad6082998925f47865b58b6d344c1b1cf0ab059d091f33334ccb92436f37eb8a'',tx0_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx1_index=4,tx1_hash=''f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4'',tx1_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',forward_asset=''BTC'',forward_quantity=50000000,backward_asset=''XCP'',backward_quantity=100000000,tx0_block_index=310002,tx1_block_index=310003,block_index=310003,tx0_expiration=10,tx1_expiration=10,match_expire_index=310023,fee_paid=857142,status=''pending'' WHERE rowid=1');
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
INSERT INTO undolog VALUES(65,'UPDATE bets SET tx_index=13,tx_hash=''4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf'',block_index=310012,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=0,deadline=1388000100,wager_quantity=50000000,wager_remaining=50000000,counterwager_quantity=25000000,counterwager_remaining=25000000,target_value=0.0,leverage=15120,expiration=10,expire_index=310022,fee_fraction_int=5000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(66,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92769539176 WHERE rowid=1');
INSERT INTO undolog VALUES(67,'DELETE FROM credits WHERE rowid=10');
INSERT INTO undolog VALUES(68,'UPDATE bets SET tx_index=14,tx_hash=''571bf2b57a7251ca3e8dfc6df5f93b4cdb420976a4bcf3a8dcdb633af78f0fcf'',block_index=310013,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=1,deadline=1388000100,wager_quantity=25000000,wager_remaining=25000000,counterwager_quantity=41500000,counterwager_remaining=41500000,target_value=0.0,leverage=15120,expiration=10,expire_index=310023,fee_fraction_int=5000000,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(69,'DELETE FROM bet_matches WHERE rowid=1');
INSERT INTO undolog VALUES(70,'UPDATE orders SET tx_index=4,tx_hash=''f6d59b73fac606f1704af16fcd812a5cfd07e8a48c172cf06447447cfb3e6cd4'',block_index=310003,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''XCP'',give_quantity=105000000,give_remaining=5000000,get_asset=''BTC'',get_quantity=50000000,get_remaining=0,expiration=10,expire_index=310013,fee_required=900000,fee_required_remaining=42858,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=2');
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
INSERT INTO undolog VALUES(82,'UPDATE bets SET tx_index=15,tx_hash=''6ef15062104f20e15f0a7fc5ad3184e22cef35f3eff6aa0d3a6b0fb00482f2cd'',block_index=310014,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=0,deadline=1388000100,wager_quantity=150000000,wager_remaining=150000000,counterwager_quantity=350000000,counterwager_remaining=350000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310024,fee_fraction_int=5000000,status=''open'' WHERE rowid=3');
INSERT INTO undolog VALUES(83,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(84,'DELETE FROM credits WHERE rowid=13');
INSERT INTO undolog VALUES(85,'UPDATE bets SET tx_index=16,tx_hash=''9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891'',block_index=310015,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=1,deadline=1388000100,wager_quantity=350000000,wager_remaining=350000000,counterwager_quantity=150000000,counterwager_remaining=150000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310025,fee_fraction_int=5000000,status=''open'' WHERE rowid=4');
INSERT INTO undolog VALUES(86,'DELETE FROM bet_matches WHERE rowid=2');
INSERT INTO undolog VALUES(87,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(88,'DELETE FROM debits WHERE rowid=15');
INSERT INTO undolog VALUES(89,'DELETE FROM bets WHERE rowid=5');
INSERT INTO undolog VALUES(90,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91528789176 WHERE rowid=1');
INSERT INTO undolog VALUES(91,'DELETE FROM debits WHERE rowid=16');
INSERT INTO undolog VALUES(92,'DELETE FROM bets WHERE rowid=6');
INSERT INTO undolog VALUES(93,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(94,'DELETE FROM credits WHERE rowid=14');
INSERT INTO undolog VALUES(95,'UPDATE bets SET tx_index=17,tx_hash=''69ea81f72e31ccd89ef9c363a72d210e58c5316df7b2ac3738604ff24fc57f31'',block_index=310016,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=2,deadline=1388000200,wager_quantity=750000000,wager_remaining=750000000,counterwager_quantity=650000000,counterwager_remaining=650000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310026,fee_fraction_int=5000000,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(96,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(97,'DELETE FROM credits WHERE rowid=15');
INSERT INTO undolog VALUES(98,'UPDATE bets SET tx_index=18,tx_hash=''8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514'',block_index=310017,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=3,deadline=1388000200,wager_quantity=650000000,wager_remaining=650000000,counterwager_quantity=750000000,counterwager_remaining=750000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310027,fee_fraction_int=5000000,status=''open'' WHERE rowid=6');
INSERT INTO undolog VALUES(99,'DELETE FROM bet_matches WHERE rowid=3');
INSERT INTO undolog VALUES(100,'DELETE FROM broadcasts WHERE rowid=19');
INSERT INTO undolog VALUES(101,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(102,'DELETE FROM credits WHERE rowid=16');
INSERT INTO undolog VALUES(103,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90937926676 WHERE rowid=1');
INSERT INTO undolog VALUES(104,'DELETE FROM credits WHERE rowid=17');
INSERT INTO undolog VALUES(105,'DELETE FROM bet_match_resolutions WHERE rowid=1');
INSERT INTO undolog VALUES(106,'UPDATE bet_matches SET id=''4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf_571bf2b57a7251ca3e8dfc6df5f93b4cdb420976a4bcf3a8dcdb633af78f0fcf'',tx0_index=13,tx0_hash=''4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf'',tx0_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx1_index=14,tx1_hash=''571bf2b57a7251ca3e8dfc6df5f93b4cdb420976a4bcf3a8dcdb633af78f0fcf'',tx1_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=15120,forward_quantity=41500000,backward_quantity=20750000,tx0_block_index=310012,tx1_block_index=310013,block_index=310013,tx0_expiration=10,tx1_expiration=10,match_expire_index=310022,fee_fraction_int=5000000,status=''pending'' WHERE rowid=1');
INSERT INTO undolog VALUES(107,'DELETE FROM broadcasts WHERE rowid=20');
INSERT INTO undolog VALUES(108,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90941039176 WHERE rowid=1');
INSERT INTO undolog VALUES(109,'DELETE FROM credits WHERE rowid=18');
INSERT INTO undolog VALUES(110,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91100339176 WHERE rowid=1');
INSERT INTO undolog VALUES(111,'DELETE FROM credits WHERE rowid=19');
INSERT INTO undolog VALUES(112,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91416039176 WHERE rowid=1');
INSERT INTO undolog VALUES(113,'DELETE FROM credits WHERE rowid=20');
INSERT INTO undolog VALUES(114,'DELETE FROM bet_match_resolutions WHERE rowid=2');
INSERT INTO undolog VALUES(115,'UPDATE bet_matches SET id=''6ef15062104f20e15f0a7fc5ad3184e22cef35f3eff6aa0d3a6b0fb00482f2cd_9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891'',tx0_index=15,tx0_hash=''6ef15062104f20e15f0a7fc5ad3184e22cef35f3eff6aa0d3a6b0fb00482f2cd'',tx0_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx1_index=16,tx1_hash=''9c9557de76767ded300be7de07ecf2d2ef3d179c2609f7ac38d32cca498fe891'',tx1_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=5040,forward_quantity=150000000,backward_quantity=350000000,tx0_block_index=310014,tx1_block_index=310015,block_index=310015,tx0_expiration=10,tx1_expiration=10,match_expire_index=310024,fee_fraction_int=5000000,status=''pending'' WHERE rowid=2');
INSERT INTO undolog VALUES(116,'DELETE FROM broadcasts WHERE rowid=21');
INSERT INTO undolog VALUES(117,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91441039176 WHERE rowid=1');
INSERT INTO undolog VALUES(118,'DELETE FROM credits WHERE rowid=21');
INSERT INTO undolog VALUES(119,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92771039176 WHERE rowid=1');
INSERT INTO undolog VALUES(120,'DELETE FROM credits WHERE rowid=22');
INSERT INTO undolog VALUES(121,'DELETE FROM bet_match_resolutions WHERE rowid=3');
INSERT INTO undolog VALUES(122,'UPDATE bet_matches SET id=''69ea81f72e31ccd89ef9c363a72d210e58c5316df7b2ac3738604ff24fc57f31_8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514'',tx0_index=17,tx0_hash=''69ea81f72e31ccd89ef9c363a72d210e58c5316df7b2ac3738604ff24fc57f31'',tx0_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx1_index=18,tx1_hash=''8d7753e9a285856d7b07f8f32601ac24455d21ac197ed4ea0f32c1939af87514'',tx1_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx0_bet_type=2,tx1_bet_type=3,feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',initial_value=100,deadline=1388000200,target_value=1.0,leverage=5040,forward_quantity=750000000,backward_quantity=650000000,tx0_block_index=310016,tx1_block_index=310017,block_index=310017,tx0_expiration=10,tx1_expiration=10,match_expire_index=310026,fee_fraction_int=5000000,status=''pending'' WHERE rowid=3');
INSERT INTO undolog VALUES(123,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''BBBB'',quantity=996000000 WHERE rowid=3');
INSERT INTO undolog VALUES(124,'DELETE FROM debits WHERE rowid=17');
INSERT INTO undolog VALUES(125,'DELETE FROM orders WHERE rowid=3');
INSERT INTO undolog VALUES(126,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92841039176 WHERE rowid=1');
INSERT INTO undolog VALUES(127,'DELETE FROM credits WHERE rowid=23');
INSERT INTO undolog VALUES(128,'DELETE FROM burns WHERE rowid=23');
INSERT INTO undolog VALUES(129,'UPDATE bets SET tx_index=13,tx_hash=''4706517b2003dc133459f0f982fc2747c1163fad45542b7493389aed5535e1bf'',block_index=310012,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=0,deadline=1388000100,wager_quantity=50000000,wager_remaining=8500000,counterwager_quantity=25000000,counterwager_remaining=4250000,target_value=0.0,leverage=15120,expiration=10,expire_index=310022,fee_fraction_int=5000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(130,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=149840926438 WHERE rowid=1');
INSERT INTO undolog VALUES(131,'DELETE FROM credits WHERE rowid=24');
INSERT INTO undolog VALUES(132,'DELETE FROM bet_expirations WHERE rowid=13');
INSERT INTO undolog VALUES(133,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''BBBC'',quantity=99474 WHERE rowid=4');
INSERT INTO undolog VALUES(134,'DELETE FROM debits WHERE rowid=18');
INSERT INTO undolog VALUES(135,'UPDATE balances SET address=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',asset=''BBBC'',quantity=526 WHERE rowid=6');
INSERT INTO undolog VALUES(136,'DELETE FROM credits WHERE rowid=25');
INSERT INTO undolog VALUES(137,'DELETE FROM sends WHERE rowid=24');
INSERT INTO undolog VALUES(138,'UPDATE orders SET tx_index=22,tx_hash=''ad327d1cdbf8db607518f98984766bbe594cc47ed24cbc84aac4e45de99fd038'',block_index=310021,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''BBBB'',give_quantity=50000000,give_remaining=50000000,get_asset=''XCP'',get_quantity=50000000,get_remaining=50000000,expiration=10,expire_index=310031,fee_required=0,fee_required_remaining=0,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=3');
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
