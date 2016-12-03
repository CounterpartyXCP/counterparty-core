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
INSERT INTO bet_expirations VALUES(13,'72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',310023);
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
INSERT INTO bet_match_resolutions VALUES('72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64_f6a6834a51451c205353d5d36950b48b7deebca3ea339b31a66e8204163cecfc',1,310018,'0',0,59137500,NULL,NULL,3112500);
INSERT INTO bet_match_resolutions VALUES('9b3799f2ce6c01f8fc8d54dd43b103b8ab992ae345d7af234b67bd8c0aa4d9b2_97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d',1,310019,'1',159300000,315700000,NULL,NULL,25000000);
INSERT INTO bet_match_resolutions VALUES('5fae745825197093b0f1efcdffc79d58a6f609e1b794c537faa555c01c270f13_ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a',5,310020,NULL,NULL,NULL,'NotEqual',1330000000,70000000);
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
INSERT INTO bet_matches VALUES('72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64_f6a6834a51451c205353d5d36950b48b7deebca3ea339b31a66e8204163cecfc',13,'72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',14,'f6a6834a51451c205353d5d36950b48b7deebca3ea339b31a66e8204163cecfc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',100,1388000100,0.0,15120,41500000,20750000,310012,310013,310013,10,10,310022,5000000,'settled: liquidated for bear');
INSERT INTO bet_matches VALUES('9b3799f2ce6c01f8fc8d54dd43b103b8ab992ae345d7af234b67bd8c0aa4d9b2_97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d',15,'9b3799f2ce6c01f8fc8d54dd43b103b8ab992ae345d7af234b67bd8c0aa4d9b2','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',16,'97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',100,1388000100,0.0,5040,150000000,350000000,310014,310015,310015,10,10,310024,5000000,'settled');
INSERT INTO bet_matches VALUES('5fae745825197093b0f1efcdffc79d58a6f609e1b794c537faa555c01c270f13_ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a',17,'5fae745825197093b0f1efcdffc79d58a6f609e1b794c537faa555c01c270f13','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',18,'ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',2,3,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',100,1388000200,1.0,5040,750000000,650000000,310016,310017,310017,10,10,310026,5000000,'settled: for notequal');
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
INSERT INTO bets VALUES(13,'72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64',310012,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1388000100,50000000,8500000,25000000,4250000,0.0,15120,10,310022,5000000,'expired');
INSERT INTO bets VALUES(14,'f6a6834a51451c205353d5d36950b48b7deebca3ea339b31a66e8204163cecfc',310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000100,25000000,4250000,41500000,0,0.0,15120,10,310023,5000000,'filled');
INSERT INTO bets VALUES(15,'9b3799f2ce6c01f8fc8d54dd43b103b8ab992ae345d7af234b67bd8c0aa4d9b2',310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1388000100,150000000,0,350000000,0,0.0,5040,10,310024,5000000,'filled');
INSERT INTO bets VALUES(16,'97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d',310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000100,350000000,0,150000000,0,0.0,5040,10,310025,5000000,'filled');
INSERT INTO bets VALUES(17,'5fae745825197093b0f1efcdffc79d58a6f609e1b794c537faa555c01c270f13',310016,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',2,1388000200,750000000,0,650000000,0,1.0,5040,10,310026,5000000,'filled');
INSERT INTO bets VALUES(18,'ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a',310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',3,1388000200,650000000,0,750000000,0,1.0,5040,10,310027,5000000,'filled');
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
INSERT INTO blocks VALUES(309999,'8b3bef249cb3b0fa23a4936c1249b6bd41daeadc848c8d2e409ea1cbc10adfe7',309999000,NULL,NULL,'3e2cd73017159fdc874453f227e9d0dc4dabba6d10e03458f3399f1d340c4ad1','3e2cd73017159fdc874453f227e9d0dc4dabba6d10e03458f3399f1d340c4ad1','3e2cd73017159fdc874453f227e9d0dc4dabba6d10e03458f3399f1d340c4ad1');
INSERT INTO blocks VALUES(310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,NULL,NULL,'f3e1d432b546670845393fae1465975aa99602a7648e0da125e6b8f4d55cbcac','618a3685c96778f3bbb71b6238959cc62e936f25461a33778e976c64afdf1865','0692da030e79edba303afe4d4b55ba6ec32b7806b156954168fb5b6aba626e93');
INSERT INTO blocks VALUES(310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,NULL,NULL,'799a07e7b411c96c92618baa5b998db22fa9ac0a9f7e231e571a237132a813c7','7b7087270ebbb00bf7b3bec1d22d89c305c8e50947a8fd11b6948f7114a7a7d2','4c797f946cb4302227c2b4893b77f7e10479bfa73cb99a0bcdd2c2a1bf5a914d');
INSERT INTO blocks VALUES(310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,NULL,NULL,'c5ac2b0cc1745402a7693afc6e5aa4394c1c2c1c70b069911fa793cfef55a4d3','15c965c7228140b6602b5e09b76a7fa4ca939809bc730509cc4c0b3685c2385f','0cd85d7ad1e162114ae0fc72cedb89102f66fef48878f763adee21510e212d92');
INSERT INTO blocks VALUES(310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,NULL,NULL,'0c22178d665b7b83b80d9686df23f12ecd6ae3a5744b729c528f9ecc3c94b051','40a565bf2bd14175ee8dbec1f2dee6468102a9f5fe4fb59c0e8dea72b9402e8c','bde605f4162aefd7df21a72f8c2f7df26e2578916476faa92b985a5c887af464');
INSERT INTO blocks VALUES(310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,NULL,NULL,'9b1bb2d232c1e24fd52c4fd299776924fae5b0deab3d37dc359632777c80294b','a248d21d022946e2e3d6f97b906c0ff25ece83f6af0a4c001bf5143a2cea3e00','91317022bb960a20fc022698ec18306d33cc3b61844d93e0f446ae01f2dc01fe');
INSERT INTO blocks VALUES(310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,NULL,NULL,'92ab51eb151104ac16d901ee7bddd5b6cec176a7ce91359b331767963bdbc2f8','24a4c4162bb7bcf5953e0ef77618e706bcbec36ac88dee6c7a766040248c6c9c','fbb7f641db113500c799ea19b39b27d023112bafce8e07a2cf8e512da0d4ee6e');
INSERT INTO blocks VALUES(310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,NULL,NULL,'ca4d8f6af1678bc1c40c60b97d409d1503b6a93cffc828a132abe7fd4f77a911','03bf64b0ee5ad2c3d798fd4b24fdb8e6dcb82778e668f2cd73510f5e62911f62','53b3560831bf7681e9e7594d8abcb7e0eab795cd31fd88095c3ababd164cb330');
INSERT INTO blocks VALUES(310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,NULL,NULL,'ec5ea53c7c9980060c08faa94fe708d0560bd4667843071cdd49ca07781f8197','66930aa9a8b50f9f16d41a71c8f439ea66cca8e16f8eb404047a4cb06b176b07','3835dea8eff37cecaf00f85909131b31004f38a4a79e4032a0cce52c35771e65');
INSERT INTO blocks VALUES(310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,NULL,NULL,'c805eed4b9512a6d277cc5814145f6db7a12ddce6f9df1a1656aafd11730c433','516e1ff51f43a4a826e6dd281a35210e600fa21f60187c9debeae2418eae84a4','6ba973b4c1151c6c16f671e1cdc60b3c0c0e0ca4d28ce367cb651ff36ff7b791');
INSERT INTO blocks VALUES(310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,NULL,NULL,'89b985b58171d607af4fca31f87774e68ffe9c5e6ce6819555242df327225300','98225b9587cd125077bbecaaf31ad784289db3ded614833827f83c81712dd0d1','3fd9e9686c13e52a8f56518fc4a3963bf641200d76f783cf4b995fba21e96203');
INSERT INTO blocks VALUES(310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,NULL,NULL,'9364be6a0b1c52254b405f51631f654b7670b1e8befc3171cd3d6b00e8679b5e','629aad8605fbf3fe2d11a3b534d30ac417c59eeb4bd4aeb06a203098f0d4b4ac','10b4d0a281e4c06ad1a0bcd259bd88aad900c718f575b081b92c43ee2b73194a');
INSERT INTO blocks VALUES(310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,NULL,NULL,'8d855d1d96fc2439e12cea023a8b89188d66af4f2b0909899088f6f49bc19788','0991f5c6c1924a9d96da933036c13fdc529a78cdd41e8463abd6c4f2cf27ead8','b629bae422593cc5e30b0a8b1f7b3844b56dd1e961053e19c812473026aedff0');
INSERT INTO blocks VALUES(310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,NULL,NULL,'c44aa2983ed171cc07ff6e5d0c4b5c8b11e5d91dd07e38be0c1b9125ae3bf456','b15f2ad037aca052eacad37931fdb5a46221b68e7ae022b4902bb4e45bac67a6','6654541a12f58078251e1bbd9fc7a9624a2efb8d2eb1545579a1b83c818884b7');
INSERT INTO blocks VALUES(310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,NULL,NULL,'5be56741bca8dec52d2a67e53dcd63160d4526f7dc0df67fda0de77bf4e9da8a','3ac5a0bd88d84886229b2a02be50117bebd323ed6a70ed87d86f7eafe3c74b88','957047e7864969c3bb8f1f17f8d3dd6d9989360fe88ebb0978b7b2d7f97b4847');
INSERT INTO blocks VALUES(310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,NULL,NULL,'f86452c1cd357d643eee042d1fd66436098685de4c52a7936a03ce20bda1079a','450b50f70bc58cad1dda144a0c81277169f33a78f51ef53f03c7607d28ee4275','9b2c9637659847fcbe95e28592246939e3a42cea88741cb314e9eae567c6af5a');
INSERT INTO blocks VALUES(310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,NULL,NULL,'bae2bbbf6218c0c024869311fcab4a20fd23aef08df2de2fc91c455f6d9fc0b3','b34a3701141db779227c02b9b11463cc1ea32ed1c8e2fd25ac6c64bc5eb6dbfe','e2c3814886eef3243b2fbcd3279992dd4a28bf3b71d49347a2e14f74a1658034');
INSERT INTO blocks VALUES(310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,NULL,NULL,'bad1ac257a33472aef96bfe3c31edb133dda78d3d50cdfdce60ff15ff16b10e0','424bafc992cc8a9252ac032e2ae6bf0fa7d4a0f51068ced7979879897a02a3b5','91cd18163bd5f7c61283ed3cd1366dcfab584b0c44dbddfa7214bab4fb8574e2');
INSERT INTO blocks VALUES(310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,NULL,NULL,'4face53b64e3760e7dcd2521355795bf84c08cc4fc9f4714202f4ab9f9dc05fc','55bba292f23d97949d86885959e7649656be1627fc7925c8509a83d79f45a39c','5a462b4bfa8d171e5a01196265ee0d8fc0d34bdf8e13f206e7339e1b1c08c8c1');
INSERT INTO blocks VALUES(310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,NULL,NULL,'f6c2e0002faec9c351fa0e6fd4d6319ef90bbb18f523bcff7a7de93f03828995','e0c84d66e26b5a82d8bf79f3ba65f30a07ead90c858c58e5d09b562f4379ced9','ddcc9cf8271fd5ddbdf3daa07de805dcae554dfd9ec14cebe164bd404e0e0b52');
INSERT INTO blocks VALUES(310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,NULL,NULL,'10758b2da0121a48b575407509018c5b1eeadf37bb5c2b72754537400202fc2c','277a7dffb48445be0d9527448065d33d3b359831800f0855f80693b2614afc46','e176177d5bc4e50484b7618a359ea128abe7a647f29cb6e56469222f5470b231');
INSERT INTO blocks VALUES(310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,NULL,NULL,'d4e0407b10cc1081f759911dbec043539234133a35cb558c4d618551a394db48','f45985dc79c5135296d4ecbf72241ff4d6012f27b9d24906c65c46d60e009190','b0842eda087147f5c598038e4cbee0aca5212149771a21facd548b0e2c2f0854');
INSERT INTO blocks VALUES(310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,NULL,NULL,'79627943b1596067ed0fffc089f6f364588f5f24e9203d2645089f40d174f269','45d7e5718a4866b4b10d1d1bf678e55703129a2e8fa0bf4e4478fe532edc9788','7a71a03263af317d0ef2e97fcae059ed27675cbc66bef8f256d59df24d7171d2');
INSERT INTO blocks VALUES(310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,NULL,NULL,'a293e8104811b548c6011206210787df28356f4364fb58841a0d47ec5ac569d6','3bc8f3a38d80847670a5740ed10be31205662d4efbb72740fedbf99224d6bd1e','47099ad6dc8a5d37eab91f50a7af91643e33f6eaea609ca6fbb447eba3ed84b2');
INSERT INTO blocks VALUES(310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,NULL,NULL,'20eb4a448bb91b5bffd9a56770bd5e0ac2ef4654179896b8928af2f64f43f03f','622dcafab11c8db73b95f28a9e13c271903c956efa80379e2cdcb49d089b46dd','19b10605869fe25b6bde4e0ef5d8da4243f1886ca7818da5ba39deba3ff99ab6');
INSERT INTO blocks VALUES(310024,'b03042b4e18a222b4c8d1e9e1970d93e6e2a2d41686d227ff8ecf0a839223dc5',310024000,NULL,NULL,'5a8400b9458a2bf130e2e456047732cb13b77197d8c21b7f247f0757c9437919','23c362a088741325ae536b3f036860b56a4d78fd6fdef96b7ecc1179cf349d96','f443162c8e7715c131795b472b9a4c5121b74de5439faf38c43c5ecb9f35d78d');
INSERT INTO blocks VALUES(310025,'a872e560766832cc3b4f7f222228cb6db882ce3c54f6459f62c71d5cd6e90666',310025000,NULL,NULL,'134a2ed73efdec3c56857e92885355bba1f0325097bf958ce9387060841ec23c','eb5debf94bc3e4a03ef7c2e32fc9f761a5254edcfbce9841c5cf0e55a17061c8','be20a8ea8f52488ede035fbf1de5cbab4f7663e3bb72e518130a26611895b934');
INSERT INTO blocks VALUES(310026,'6c96350f6f2f05810f19a689de235eff975338587194a36a70dfd0fcd490941a',310026000,NULL,NULL,'991650c3d89e104026aab7489e596692d3c104a2374bf3a2078bfbd0e0ed4ffe','aaf0d8964e8ecf867463e6c62da6073dfe5885f158280a7f45b31bed20c25f48','fd45f23890c073d35931a7ffb320941b75dcb3211d11b1209bccb06f46433d7b');
INSERT INTO blocks VALUES(310027,'d7acfac66df393c4482a14c189742c0571b89442eb7f817b34415a560445699e',310027000,NULL,NULL,'6f258efddeb2c542fc610bb169df58beda36852735fc051a046378fffd4a88bc','2a189969f3ed890fb1653274bd683b70a04be1e3b457a70d941756fc839501b6','fb5586edd395ed428c358bdf39fb8dd2f501ff75059539e5d9711a7760da29b6');
INSERT INTO blocks VALUES(310028,'02409fcf8fa06dafcb7f11e38593181d9c42cc9d5e2ddc304d098f990bd9530b',310028000,NULL,NULL,'f6020d6aa398f6a19e34375aef4bc3d9e2af81bc3f469aedcb438b7a4244452e','853a6fdb55a7682f2f796673df534d94ab6644defa2161d83b99c83bec0ac132','23427ef1addd93194bc726f4aaee05f9a02030aed520a4fa005d4faac69a3fb1');
INSERT INTO blocks VALUES(310029,'3c739fa8b40c118d5547ea356ee8d10ee2898871907643ec02e5db9d00f03cc6',310029000,NULL,NULL,'3d1ebe501f5c0706c48001f34df56a82f1ab55c24f7eabd27d7c608b7ef5f53d','b74372e1eddb5dad2dc3181d1fb0164ca831b5ef3f9809b1a4927dbf4bfecaa6','112df69d6c8e3959c289cd52cee87e5acf5546f337ddd65ec363afdfd5c8a315');
INSERT INTO blocks VALUES(310030,'d5071cddedf89765ee0fd58f209c1c7d669ba8ea66200a57587da8b189b9e4f5',310030000,NULL,NULL,'b45b0ed17cec893daf9b0755d8fe96acb5a57d185febee1accdf12d0f6548149','c700fc18802a307da700884b51bdc655ffc2f92d9d3815f2b75ee9fee03c26c4','9930710617c128681bb8b93490fc24ff277d13e253c3c3a3d0e9f44dc7029440');
INSERT INTO blocks VALUES(310031,'0b02b10f41380fff27c543ea8891ecb845bf7a003ac5c87e15932aff3bfcf689',310031000,NULL,NULL,'a09ade623465eb0723906a09c0dfa9ec3d3608c89d0dc9a6c29771d7e0270870','16e80418fb15a23f92f410dfd6b8cd42247f31f890b7e1d9287a15adcbce6645','733d784ab17c6eda80bed7af946de16b2ad43299739fe2d386b2f86e0adfc038');
INSERT INTO blocks VALUES(310032,'66346be81e6ba04544f2ae643b76c2b7b1383f038fc2636e02e49dc7ec144074',310032000,NULL,NULL,'ac17144975b1c8afae2b06674d2b37ebff0f65340d18bc8b4d2a3d4393ffea2f','01b5d870b6f9adf6fc325dc2106c28e0e2e4a857fb9d98c84ada171bb36d9737','04f8e77464e16c74f6a192b37d298126fdaaec92eea5aeb913f81e016e50b46d');
INSERT INTO blocks VALUES(310033,'999c65df9661f73e8c01f1da1afda09ac16788b72834f0ff5ea3d1464afb4707',310033000,NULL,NULL,'b3b5d5b1902c2ef0de433fae13b45a172292f6670e6ae3510b66b1c668589a1f','f624964dfafb3956badef32e37bb382281a8e8b00fa18d4c7314be65a2d0e418','ac63e1f6b48e8a9c1494d7b2a40eec177e2ae4e99f7977c4a0bd5c7dbad8ff58');
INSERT INTO blocks VALUES(310034,'f552edd2e0a648230f3668e72ddf0ddfb1e8ac0f4c190f91b89c1a8c2e357208',310034000,NULL,NULL,'9472707aabedf5777a39795c6203b6c739918f192289461dfd04a60de1e0c957','b0f5cccb62e307510938961b6544559a0f929680bbee71e3c4b2069a279353d3','8d19009b8dab43091fa536ebe579c997d0f68bb91bb4cf2a89e1b42a4f690749');
INSERT INTO blocks VALUES(310035,'a13cbb016f3044207a46967a4ba1c87dab411f78c55c1179f2336653c2726ae2',310035000,NULL,NULL,'beefce8b07b546b6f4b7841f0902071df6c2b6690b0e8c761081a05906bb2d54','052c785d363e1144ad2e1cd62265fedc2f3f8e9671c9b3cc73238f72ed6a4c48','c0a9ee19935722672939d658cd8d7a77ac6c331565ef58fb84f33e6c57b8ab7a');
INSERT INTO blocks VALUES(310036,'158648a98f1e1bd1875584ce8449eb15a4e91a99a923bbb24c4210135cef0c76',310036000,NULL,NULL,'09ef6e4b0507f56156c178c9c88a1cd4c4954ccbe349d885b79ef48b5743f050','d888b2867c8efe4dbd14765705248ebcd17ab6d233c5e07773b8b3053d49b03f','8dbc16533742b196fa3803a6182962633a14c9c66ae23e0d48f455df6c43bd7f');
INSERT INTO blocks VALUES(310037,'563acfd6d991ce256d5655de2e9429975c8dceeb221e76d5ec6e9e24a2c27c07',310037000,NULL,NULL,'9031545d6509e31bc0694eac4d8b0f227cba3017c2c67c8475e782be62daf78d','f48928fe0ddf922493f0642bb17df5ee4359b2ec3fd6e9061bc7abc4f9dd8bd3','f2c661f5122772a532ceed7f80ebbd39a565e5bf6c7b443f87048c38701e6ac6');
INSERT INTO blocks VALUES(310038,'b44b4cad12431c32df27940e18d51f63897c7472b70950d18454edfd640490b2',310038000,NULL,NULL,'8bf7837453018b11389958dfa7a901098387088d926b64073dfdc862a4efd20c','356aa58f159f1440dba44769888a348338d89e459207f6770e1ed587c5307b28','54e48ea0b65af2b99892ce07273801c6d217082831e5a4f07492af4c9fb1b963');
INSERT INTO blocks VALUES(310039,'5fa1ae9c5e8a599247458987b006ad3a57f686df1f7cc240bf119e911b56c347',310039000,NULL,NULL,'c1a5c848da36b34fc10df323539ec8a363da62c373afebb5236b6985a5b6ad57','f841ce616fe577ecc2d8c0706cec551a6d25cc6532864fbe6a5f82f7a485bd52','dc55ed8ee810790fe5e38d2e42b329f2c607e9046f735406b4dcbfd7cb3cb0a7');
INSERT INTO blocks VALUES(310040,'7200ded406675453eadddfbb2d14c2a4526c7dc2b5de14bd48b29243df5e1aa3',310040000,NULL,NULL,'872fca779c7f012871ac7fddb3f4006fe9573e4c0889bd2de790dc0158e6732a','311aac2a781edf370c2915369cb516aacee0625247997b1937fcac958f95fa7d','5005c66164d4993179295045e3dfbad17f21595812517d46c859be11c3afc0aa');
INSERT INTO blocks VALUES(310041,'5db592ff9ba5fac1e030cf22d6c13b70d330ba397f415340086ee7357143b359',310041000,NULL,NULL,'b12c996ac0c0023e4e230fdda1fb0132b4131034dd930ab4b294af6f469e0bdc','2c2b4d51ea81f8d2ad89c9d27ba6de22176100e47989dbe40a83a4e64058f58d','98e8686830cb3c6bab68e9f4e5e062a261dd9d7d0f8d7baae91bef4d78578cf5');
INSERT INTO blocks VALUES(310042,'826fd4701ef2824e9559b069517cd3cb990aff6a4690830f78fc845ab77fa3e4',310042000,NULL,NULL,'7a8d6356e216afe4e589d26b471171d4bec625f9aeb6ee3f3af6c95d48f0b725','69285dae6f1dd3ce7d0f03a94c9f8857b1383d3d8edcc58249012985b609ef97','a355243d458cacd70cd0026614b11766b6dc9f5121347d22eddbb455c1f1cd57');
INSERT INTO blocks VALUES(310043,'2254a12ada208f1dd57bc17547ecaf3c44720323c47bc7d4b1262477cb7f3c51',310043000,NULL,NULL,'00d2b046d86a0816bda22f1ad5e6b4c1b898bfed2c65df3c6e7ad7466a001b6a','01204864aa75022a8683bd5f62f02466c8b2481b63845a1d1f5753379ffc9a17','2b7dd0fd20d9439c3680de23e92e4d124768f93463cc7166cd934c3774fe88a5');
INSERT INTO blocks VALUES(310044,'3346d24118d8af0b3c6bcc42f8b85792e7a2e7036ebf6e4c25f4f6723c78e46b',310044000,NULL,NULL,'c49bc1a16630633105f839824678cddb2dcd7d186071300bf4911fbf4cb9442a','cddac0488a4aee219ec364e043e18955a2ff31def8555fc6dc90cd9c58abe1fd','ca736c14e5ed4abdb721e6ae7d72a00926ed5932703a807bf1c6181047988d70');
INSERT INTO blocks VALUES(310045,'7bba0ab243839e91ad1a45a762bf074011f8a9883074d68203c6d1b46fffde98',310045000,NULL,NULL,'e3de0ca395651f7a1598738f2604581407f2b45b736f5aac2ad64e867295efc2','24fa2fc9069ad67e411305c1b70e6857686487e8e2c48e9dc1f44ed470faab02','a4a46b8c13f57529765021dc2507818633520941b6d5d7bdce61304a96e5331d');
INSERT INTO blocks VALUES(310046,'47db6788c38f2d6d712764979e41346b55e78cbb4969e0ef5c4336faf18993a6',310046000,NULL,NULL,'ed901088e07f2e89f721cf23f968a3d9f070ed6dca4cdb172839e9a661a9b1d8','3de6a798a653f099209279befe9c532230d354b14f52478aadc8accad3e6ff9e','9edd30f58eaedf190620889982896673d2ca8ae201ba6fdb061aa1cb15286de0');
INSERT INTO blocks VALUES(310047,'a9ccabcc2a098a7d25e4ab8bda7c4e66807eefa42e29890dcd88149a10de7075',310047000,NULL,NULL,'121e4e8d312ac0b95d72b1700db6f430b3724f75f00af90132db5e6c21fbc53e','1a0e66a3b7e94aa5ee7c3bfbbde9dbb49cba7945341f5d159e2264423a6ad402','f64289fdf5013151751293620e06015170299552b83a90e64cc8d25acb6b579e');
INSERT INTO blocks VALUES(310048,'610bf3935a85b05a98556c55493c6de45bed4d7b3b6c8553a984718765796309',310048000,NULL,NULL,'53b15d51a08eff5fed146c635008936e37e7e887fe29a2f120ba0ed880ee667f','303b40def08a8392acd6b3bcf3749bddd1019941973b838665d6469737e9cbb8','a0ac47b94c558345b891d2163ba99f2a5f4a6346171c83091adc90d1cb3628f7');
INSERT INTO blocks VALUES(310049,'4ad2761923ad49ad2b283b640f1832522a2a5d6964486b21591b71df6b33be3c',310049000,NULL,NULL,'eee2ad25f711f1c125a4964847a5eaa7c2265ebb324df498b30a8287d7a12161','18368385d85931487e55b20dcaa82956b48f802111101400a4846518c31b9444','cdf69f451712958f8391ed33c00cae1c648fdc4b1488b62d191e06879049df62');
INSERT INTO blocks VALUES(310050,'8cfeb60a14a4cec6e9be13d699694d49007d82a31065a17890383e262071e348',310050000,NULL,NULL,'b03d4f0a027bc98edbdd15c1ce220a5bc3566adda6313772ca8501923c26fc5c','d89e4d65ed93468472da2d611079d2fe5f35088602981162dfa42b7fc715060b','bde7283a02509ccb47072adfb25419882684b8563aac920113220a2eea5f1d26');
INSERT INTO blocks VALUES(310051,'b53c90385dd808306601350920c6af4beb717518493fd23b5c730eea078f33e6',310051000,NULL,NULL,'eb1690ec7cc4fad1417b1c2cf66c4260bd0bff5d628d4d9e4dd591a01bd89fdb','bef72f8110045a995553b1c7d312ae7f136d0b9dc0111c25477c9bdd4d0d1282','51c2ca8d4ffa1a67b96544fbd6b5421384d62f13f6c42eff4fc96ba359f194c2');
INSERT INTO blocks VALUES(310052,'0acdacf4e4b6fca756479cb055191b367b1fa433aa558956f5f08fa5b7b394e2',310052000,NULL,NULL,'2fdb743bae81963ec46bb2b12b2df50df5812475e96427f55abe524946901495','3e491a22db1c0661cda5224b22e4080037c31563941aed3d0659fc28e122c3f3','bbcd7f517d761a063f1ebdd657d712baa8c8da045775d0498c3d098d35926d2a');
INSERT INTO blocks VALUES(310053,'68348f01b6dc49b2cb30fe92ac43e527aa90d859093d3bf7cd695c64d2ef744f',310053000,NULL,NULL,'66a979e684410a1fd761ff4622a0257d2d064de65519c6425048f5b5576231fb','e0c474f82fe58fc0d97667bfc7d94decb98c3b89a1c9cec6687bc323f1af2648','c54214bdb5f64ff3296b2f1e4a09dd46c21429f2558f4a4802a209ed344d4718');
INSERT INTO blocks VALUES(310054,'a8b5f253df293037e49b998675620d5477445c51d5ec66596e023282bb9cd305',310054000,NULL,NULL,'291d96fd959f92027f92e25ac8ecf2e3f4602eadb8353e6a4c0c5db486a8040f','1fccde6722ed1ef1eb36dfada23baec2d23f263b3f7c48785fd7a3cfbb0df3b8','e813d5b3c76cd4356f956540a911cddedc5bc2758489fa3eb4b10bef95a7da0d');
INSERT INTO blocks VALUES(310055,'4b069152e2dc82e96ed8a3c3547c162e8c3aceeb2a4ac07972f8321a535b9356',310055000,NULL,NULL,'2d70ac8848c48f2851118dabf74b766726525a324faed1a93ea962ef251de880','abb3bd8f6b8a753a151e1b445299b4f1549b3513e2bf2bdd5e427fb05a8c7167','2cfdf4f06e96096cc3b46e354fa842f468dde739a6412b5e0b85c18f44e84801');
INSERT INTO blocks VALUES(310056,'7603eaed418971b745256742f9d2ba70b2c2b2f69f61de6cc70e61ce0336f9d3',310056000,NULL,NULL,'f0358dd54c295b6b736f66c9cbffda24bc56c61761f94bbc29ba4975a569409e','a82d35d9f495459ea97979dcff6a550b6a48d2b051920d20b3ec0ac2b3eda9f5','d6093b5f5eafcad99e0f1231fde4fde4281c2dfa5564513a3da6cf5631e277a5');
INSERT INTO blocks VALUES(310057,'4a5fdc84f2d66ecb6ee3e3646aad20751ce8694e64e348d3c8aab09d33a3e411',310057000,NULL,NULL,'b4a5de4ab2fee5a5d625e35691225e8d51ada6c0c0255778c72a372642b0d87d','6ccffe2ede71352d778248309235af854bd8c6ad8dda62717d4f755da06b1855','556855952a0144ebe7515340037737fa137219434548617c5bab645b3553bce6');
INSERT INTO blocks VALUES(310058,'a6eef3089896f0cae0bfe9423392e45c48f4efe4310b14d8cfbdb1fea613635f',310058000,NULL,NULL,'1783e1c883c3f10f8b4ed888002910370707bfa479c6deb48711f555a26d51b7','d47102b31c0951deafc3ac1978b3f225715a05da38ed78bbd26f0f3973cea1c8','54e84e96a9395810490512637ab233876188780bedfa76f439f99965c433e43c');
INSERT INTO blocks VALUES(310059,'ab505de874c43f97c90be1c26a769e6c5cb140405c993b4a6cc7afc795f156a9',310059000,NULL,NULL,'4ecaeade9c9e63d43ea60eb7282b684b708f142e46ad25807c906e5a9b3da9b7','8824b0148795b41528c637f7ea5f536b7327da0f5246f380ab86b1fd6764ccf9','a9ee8e21fa39f7f61482c99d7df3bc554aec23e8d407fc353afb50b29605d2a4');
INSERT INTO blocks VALUES(310060,'974ad5fbef621e0a38eab811608dc9afaf10c8ecc85fed913075ba1a145e889b',310060000,NULL,NULL,'3073feeb0b9cb0680ce0775d2244d4b857945abf8057f9fff73e3e1dd990bf72','ecf6f3763c9ecc748cdc88f2d5d52e4a2a283a0a91f7d72313a0c6b0da5c9aee','149e49344e5d37a95aa90647a169356c3bd06b783126786be729af7deebac9b5');
INSERT INTO blocks VALUES(310061,'35d267d21ad386e7b7632292af1c422b0310dde7ca49a82f9577525a29c138cf',310061000,NULL,NULL,'96c4c024112811085a4a502b04686eab225d64f129acb1acbd73cf1e6c402a2b','be50ebc0b8bd19a10140e9739f0ff8747a9371f45b2a07bd6310d7d4ee57d575','c818ed455632a27bfe087615b21abee2426e9d9aa74310cfc4770ab216e187cc');
INSERT INTO blocks VALUES(310062,'b31a0054145319ef9de8c1cb19df5bcf4dc8a1ece20053aa494e5d3a00a2852f',310062000,NULL,NULL,'153c680b372c1c80d98ab8b80d9dd4260646551935f4f70063b99e0fb126bf9f','aa47840d961cdaabb41ccb10efbe5d2362e15030d5d5cce594e0978b10ac7a0b','cc7e5b78b587404bd54a3b5e9a5f7641bd74d008c98dd0463362617030976beb');
INSERT INTO blocks VALUES(310063,'0cbcbcd5b7f2dc288e3a34eab3d4212463a5a56e886804fb4f9f1cf929eadebe',310063000,NULL,NULL,'cb8ce9ef122691f289f254b5bd353e2b0c10a0b42f89e37095e6414e2d19e695','e872a1d4209e27427534025921b2196eeb5b338aaba3c1378431601e8fa42cad','ecc8d6a4f6ccdd74f85c693e15991606f79fceda0bdbe8b179e9e38fe8d476f3');
INSERT INTO blocks VALUES(310064,'e2db8065a195e85cde9ddb868a17d39893a60fb2b1255aa5f0c88729de7cbf30',310064000,NULL,NULL,'144936dc78bc9de33fff406f291fdd4627d910eecc7e3932131f26e3c13758e4','90d34a5359617a866d55c26841997ed2cee7b94fb3fd96c2ade267dc70864704','7102089b25cedf60eb7e6c9be16580e8b76e25a307b8b8715941aa517b8f6adb');
INSERT INTO blocks VALUES(310065,'8a7bc7a77c831ac4fd11b8a9d22d1b6a0661b07cef05c2e600c7fb683b861d2a',310065000,NULL,NULL,'195858e58932f7cb09b1f372def847c0237dc0385ede7b5ea8c96058b40f5571','b75dd25e303062af3ec7b213b6abd59594c42887c0086d54fb4efa23646acc4a','9244a831d34f76985f57a4a7ae14e8047bebac7c8aecacb814b351b51f95b80d');
INSERT INTO blocks VALUES(310066,'b6959be51eb084747d301f7ccaf9e75f2292c9404633b1532e3692659939430d',310066000,NULL,NULL,'accaf75fad3f8c5dccf476cbcb4ab634243fe54f706746ddc9bbda86298a36a6','c54af8f9a5849e3384259f8756f46bcbba469f07f923760d2e9c87115663efd2','a26b221325b8f334782e78f82f2528693e19b8d6d623669094b019b3214e5ae4');
INSERT INTO blocks VALUES(310067,'8b08eae98d7193c9c01863fac6effb9162bda010daeacf9e0347112f233b8577',310067000,NULL,NULL,'d6846fdf6c9708dcd2e8c8644bb687d8da954989508b0d02d785d59b509d9909','cc1151c7e63cc07fbd9b3de17560aa46d4857caf4330e423e833bfdc3e6f6c38','e2454e10aa3df6012d9e9942adf8e1a6fade6f46e2b9fcef7608af9a5f8eed76');
INSERT INTO blocks VALUES(310068,'9280e7297ef6313341bc81787a36acfc9af58f83a415afff5e3154f126cf52b5',310068000,NULL,NULL,'b208ada2b6a94aafdaacd6fd01c32fb4ebc616dfb1c4aa02ac2289f4cf033fdd','d2f3aca88e445391a642c245ce574f3fdbf4df949394091f73c5c75d09344767','cb41362e05e468b491a2fd67319e9f17ba71a32d7e4b05197dcbb417e04a1ac3');
INSERT INTO blocks VALUES(310069,'486351f0655bf594ffaab1980cff17353b640b63e9c27239109addece189a6f7',310069000,NULL,NULL,'d0050dbf85c9fb5cfe88ade565a5976bf0fb6eea263d8980dd009a72a1c04f81','55e958b891f65d2109f0a44e632dc1c290a6bc716b673bc8fc43af1c1e132b02','cbfabeee9f8fbba1251901ce83cfd2872e8919c76e4a0cb4a853fe87c22388ca');
INSERT INTO blocks VALUES(310070,'8739e99f4dee8bebf1332f37f49a125348b40b93b74fe35579dd52bfba4fa7e5',310070000,NULL,NULL,'df63fbb4133f74484b568da86c701e10c4e28b1c047fc27f93bc5287d013b15d','0680448cae45d4c9654d7f806b9d94ccfc003f2421eec7307ac634423097b34a','081889d84ac89a73f7026a927c91f0530606a038beb712296811d87096790751');
INSERT INTO blocks VALUES(310071,'7a099aa1bba0ead577f1e44f35263a1f115ed6a868c98d4dd71609072ae7f80b',310071000,NULL,NULL,'b4127d65d3611e2bfbd974f1b90099a717d10a4b9b26d5ad817871ae3cdc8516','3f5f8ef4b278488649e8db3d7e4312e2cef4775c86b526d7d08e04c52cbba897','cb393c947212fe4c1a6501da29291d8dbfd897305b16289efc974b5139295aaa');
INSERT INTO blocks VALUES(310072,'7b17ecedc07552551b8129e068ae67cb176ca766ea3f6df74b597a94e3a7fc8a',310072000,NULL,NULL,'35e860497cf0a6046c1f0409dea188452333d2d9cf2a9e0ef3321bea5d4cf0e4','dd039e330afe303515b8eb7a84df214393798b9eaa7fd47f0d7bd36330b292a2','5856c2ef01ef056854404beabe3bf1420d742b7c15f54187ae514b1bb4690f8d');
INSERT INTO blocks VALUES(310073,'ee0fe3cc9b3a48a2746b6090b63b442b97ea6055d48edcf4b2288396764c6943',310073000,NULL,NULL,'322480282050f8f9699f2387e36df75724cf7dcb1025791664502891141e9d5c','442174ce88e0544b7b12c9ced44224cdb94709b58eaeb0b4a73e4367db061885','2e0f5566177c8117fad66e2c694313f8c32858d8754129ad92f721c1a7dae4ef');
INSERT INTO blocks VALUES(310074,'ceab38dfde01f711a187601731ad575d67cfe0b7dbc61dcd4f15baaef72089fb',310074000,NULL,NULL,'a60e86ff8d795b087e4719ec9af48dffd197d33c26e46389b3b550111096109c','9bacda391d026a1a6d57e0696031b836434255dd210e888df589e5162394bd76','1894f3c90cb32b719d412805bc325f28c5e8d1613dc67735db7e29dc2f2302da');
INSERT INTO blocks VALUES(310075,'ef547198c6e36d829f117cfd7077ccde45158e3c545152225fa24dba7a26847b',310075000,NULL,NULL,'d3b5b430f3f4e608877232fdd5ae0c53ac10ce9a9b2c37e978eab16e8eb6ca62','841a7b6178089172eba63790b027703ab586300561a10d177fa0ba84a4fb0698','58c51110b203ef99067dac6b974c656516d6a74396b1fbda4bbb8b1c3620c89e');
INSERT INTO blocks VALUES(310076,'3b0499c2e8e8f0252c7288d4ecf66efc426ca37aad3524424d14c8bc6f8b0d92',310076000,NULL,NULL,'a494efaf91c425b73a1d14dcc8990c22037e44de21bee985c73f875b2d159632','d7cf7e42608784515e7dfc7e1ab9d4ad06f81d6349a093533cfd037eb522502d','84dafd2df9a80db09283e64577e09eb3471c8442104705379dfee52566ef99ec');
INSERT INTO blocks VALUES(310077,'d2adeefa9024ab3ff2822bc36acf19b6c647cea118cf15b86c6bc00c3322e7dd',310077000,NULL,NULL,'d930bbdef0c331b30f755de4969c5fd099b787461fc06e18006f0ba89c2be19c','e2f76eb8f726ed708d4b680635903244c1a0a07b071e6231fd1c912feac53da3','b66b6989b0f6063e64699c762c2007ccf8427517c9e11f1c70b22abacb48c61a');
INSERT INTO blocks VALUES(310078,'f6c17115ef0efe489c562bcda4615892b4d4b39db0c9791fe193d4922bd82cd6',310078000,NULL,NULL,'b11a6a52e7ed2aea8448941fdd9a56d9dceeb57a731c9ad1bb07468719ad30c8','7388236c832504497363c821d1f44afa04ef2af6bf288508ef66182acb44e8a5','238c1a5e3a26efdd878573174227726598c85a4ab1f4722aa2f752f8f0b3bd38');
INSERT INTO blocks VALUES(310079,'f2fbd2074d804e631db44cb0fb2e1db3fdc367e439c21ffc40d73104c4d7069c',310079000,NULL,NULL,'809be3ccf041d65c81fe99fade5310f2fb5de939964c29b381ca6c90ccdbca33','cd765cc969b91fdb7ea1227fd98bf359ab73e945c6570ce440ed983eeabb618b','d7bc7b9c5bfc8005cecbdd6e4be4ad50ed04c64ed1ce9a5b1724dafddaea96b8');
INSERT INTO blocks VALUES(310080,'42943b914d9c367000a78b78a544cc4b84b1df838aadde33fe730964a89a3a6c',310080000,NULL,NULL,'1d53e6a686d25aaeb9d78755583d54f2f96fcc89083d1253afa1b2ce6dede2e7','d84a6ba2b0e0e26f02834049b36d824cee934ee9b28576679903822e58a191a0','acb1d4276e2c967e182d31ae2ddf41e57b80878fbe9dc7c5214ec946f8a94958');
INSERT INTO blocks VALUES(310081,'6554f9d307976249e7b7e260e08046b3b55d318f8b6af627fed5be3063f123c4',310081000,NULL,NULL,'26f8aa2cd284d09e2a5d334359c04aee4d8cbc326aef762d3327812ab2ee8e56','f3a327934322a0a9a0d097d734fd9dde31d7b03a2719fd62a3a3f946451b9cc0','8c69a1867f0f19b50afcac8f882f7689c27b3796cfba8ccd5e037df17ac9f3de');
INSERT INTO blocks VALUES(310082,'4f1ef91b1dcd575f8ac2e66a67715500cbca154bd6f3b8148bb7015a6aa6c644',310082000,NULL,NULL,'46973d6e354a34a5c54aaf399bd9f4094f015b690f1b8f70ed5b072a84a5f789','e747b288ca616f8b25fce857ef568cd6d7758e3d31593b9f8778bf6816ad1c80','a172be18d069fb2356901f5a2f149183f674799f715c106f5f2b2db7ac2a9839');
INSERT INTO blocks VALUES(310083,'9b1f6fd6ff9b0dc4e37603cfb0625f49067c775b99e12492afd85392d3c8d850',310083000,NULL,NULL,'043f03eb05bbfdc6e7c48f94a7ab25821f77701567461fd6f05c72955c6045e2','0158f9fe596c1e162cf6108b3b76b414545fc506950642bb416bc21fee450391','b9658267fb530db2d38ea85bcb9af5a4600a84e3afee8cf73810045baf3bf5f7');
INSERT INTO blocks VALUES(310084,'1e0972523e80306441b9f4157f171716199f1428db2e818a7f7817ccdc8859e3',310084000,NULL,NULL,'d89cb8329798749f3dd724b4e8aa6fed50d90b745dbe44eac5c256b8b1fbdab7','4b062830a04a89721d5d44d1821732b321118d432690d37c98702130b871d468','1973038456124029f99bf2fcf71ef43c860c47bc63acc3d2205fcc1684851ef7');
INSERT INTO blocks VALUES(310085,'c5b6e9581831e3bc5848cd7630c499bca26d9ece5156d36579bdb72d54817e34',310085000,NULL,NULL,'5081d77b00967a2377093de6e85a1c6f4c8d9096995c9c261f726b55aa01cb16','8a267d37794f44c571c7d3500e10be28649225d3c4e6d20ff53064c0661e5cac','8ab3f33fe9a4197dbdf2ed45f546cad184d2932d70911b21a3459b0b45e45c01');
INSERT INTO blocks VALUES(310086,'080c1dc55a4ecf4824cf9840602498cfc35b5f84099f50b71b45cb63834c7a78',310086000,NULL,NULL,'97fa9e88a85bd3c418613187f0d63a682d00135c2bbc8add633b1f2cb397a6df','17e9d9c9f9ebb28957e132b8f39fb61039b16d5ea2c259608d34c6818119d0bc','1a556d6a98f98e7b6ed56c936cff89d479a40629fa30fb196e5b6c689a244905');
INSERT INTO blocks VALUES(310087,'4ec8cb1c38b22904e8087a034a6406b896eff4dd28e7620601c6bddf82e2738c',310087000,NULL,NULL,'a060b83f15068d8eb40ffdd6e87a92b505e45c76e559351e8a4067b338d58b0e','b8063aee9c2b98403463f7735056d391d9f2c2a4a5046378c195c65182b9f7b7','378f08e0066cd605adafa140f475d1dc3b60041b094bbaf0255be5eaccb41b5b');
INSERT INTO blocks VALUES(310088,'e945c815c433cbddd0bf8e66c5c23b51072483492acda98f5c2c201020a8c5b3',310088000,NULL,NULL,'d59defe063e13cb06084e22df43c5b7f087a557b5ce476aa650d0e85766283ca','9f96d9e374371853dec806febd9e349fc9b08f659feea39d982bab4ddd54d821','07fe772448895d1a06f3e9d70cc64f5352529c9e7a590d15d43db334ab61c685');
INSERT INTO blocks VALUES(310089,'0382437f895ef3e7e38bf025fd4f606fd44d4bbd6aea71dbdc4ed11a7cd46f33',310089000,NULL,NULL,'87a14b55f40e81c605e22d00f6bd6c91d97b1efa8bb92838b78394df8c6a74e5','ddea15459535b74e4344b821c5b96163e7e402eeb107ecb5f8676d376d64bc3b','c2b0ed037a71648b3b7aaeb11628f7a4a0002aa9bef9bc0b537f144bd1b5fd9e');
INSERT INTO blocks VALUES(310090,'b756db71dc037b5a4582de354a3347371267d31ebda453e152f0a13bb2fae969',310090000,NULL,NULL,'ecf81e18fd4f3d0f02f5ce0e3af0cface22b84e3595ee3126119befd62efbec3','bcab868de11ff7e8a5329554beca4daad0fb3cddefc0f0ba4fd6b6133fef4d41','753fbd0e57088fb4c49edf15a92f66a42fd5f3aa3e4bb34bbf2673a96178007e');
INSERT INTO blocks VALUES(310091,'734a9aa485f36399d5efb74f3b9c47f8b5f6fd68c9967f134b14cfe7e2d7583c',310091000,NULL,NULL,'e3df34192b7b31ac8b3265cf26dd80fb0fdd6f1529a60d432c1fd1ed19e23bf2','f007f6812572b21fc32900bfc198f0c89a992176cbf88b59d95fc60ef9ac0920','cca7416b0737d51cbbbefccaf0280449d4b455a99a96004a2e1e4bccf767ebf6');
INSERT INTO blocks VALUES(310092,'56386beb65f9228740d4ad43a1c575645f6daf59e0dd9f22551c59215b5e8c3d',310092000,NULL,NULL,'401a5b9d8f01042bc787b601f096d268209cd276f5cde9d526d94b11ddc8f8db','343e7e76ccc6199da0953aa5574be2f4f71e09c00d609a4fd8055eaa676481f8','37a6cf60c72391dbba25912c65b3e02b3f83cc83fb99d875c062bb0761c4015c');
INSERT INTO blocks VALUES(310093,'a74a2425f2f4be24bb5f715173e6756649e1cbf1b064aeb1ef60e0b94b418ddc',310093000,NULL,NULL,'9b0ec19d4bf43b50e12bd66b23eeaeb2ce7e223a8245e2dabbc19bd11ce21a40','af6d986ec5907b0414b4ebe7b6f9cf8905dd16a6d479115c40ed4d4c52a21f3b','10e0a5ba078f36ae2d0717e68152426aa20434740a41d891f2eef01781f287df');
INSERT INTO blocks VALUES(310094,'2a8f976f20c4e89ff01071915ac96ee35192d54df3a246bf61fd4a0cccfb5b23',310094000,NULL,NULL,'fd27eca7bcf5f096061e892f9a21bb47fa86cdb32ba67562e3f34ab8e68a6627','d9e583e767c13f45c172f8e2fb0d6e70e7bc6277d5513f21edc160438f64099f','41b93937b62fcd3e21b4d29996de47e8b4b8a7d7f608365f97f07c2b79ce7975');
INSERT INTO blocks VALUES(310095,'bed0fa40c9981223fb40b3be8124ca619edc9dd34d0c907369477ea92e5d2cd2',310095000,NULL,NULL,'ddf9fe363dfa3f851d6b662e42551c6f3d3b05a864758457a6cc22d15304e728','805127f54216336ceb98b17125af635758ce0b22059e385fadd721342ae69488','5dde12e8052be6b15d056cf80221a33541210ae5a186dedff572ffee01ae1b81');
INSERT INTO blocks VALUES(310096,'306aeec3db435fabffdf88c2f26ee83caa4c2426375a33daa2be041dbd27ea2f',310096000,NULL,NULL,'e9e5d3d557faa26dbb23f06cf8ac907507b4aa9d128336da36efdefb36e63554','1524e9686eeec955acebaa549348a31f7b071f9b5991534cdcaa90c4ffa5b7ed','c1dee5aed6a3b12a69bc5a1e194d81e819293553653f67c6b9bbb08ef5396588');
INSERT INTO blocks VALUES(310097,'13e8e16e67c7cdcc80d477491e554b43744f90e8e1a9728439a11fab42cefadf',310097000,NULL,NULL,'9123fe1a8c4b45012a5f5927dfc4ec4aa4bd9a16604ff3344ae95b1a394a85be','81829ad23d4361847eacfae7c7ab8fe89b5729386450d69e0156c5b84c2e1c4b','01cf70496ab73ef84109f829a82ed3a8dc4fe5b71bd0886a3dfaad087654ab1d');
INSERT INTO blocks VALUES(310098,'ca5bca4b5ec4fa6183e05176abe921cff884c4e20910fab55b603cef48dc3bca',310098000,NULL,NULL,'811a5c61947f9d9e29aa5e33457c0a5df1f422f8383d98d684b517a0a92f3423','ed035c6111f7a7704f33b9988f61909cc9cb24d4211df2237a45f71eead406c8','71aa0151b922e798b2f53f7aaa6930c241a4a6dcba4825f089d50ab9d58cf422');
INSERT INTO blocks VALUES(310099,'3c4c2279cd7de0add5ec469648a845875495a7d54ebfb5b012dcc5a197b7992a',310099000,NULL,NULL,'527eebfb2c994343387ce3caffabca67fb478bce80b516f27474a142d65f68f7','92aa656871a7e85b11b3529d26ead009f7368b507a5e439545ad16bbc25a72e5','652592221cc5b55e4dda9846cd19502b0c8322688c2785a2efcdc9fad80e278d');
INSERT INTO blocks VALUES(310100,'96925c05b3c7c80c716f5bef68d161c71d044252c766ca0e3f17f255764242cb',310100000,NULL,NULL,'d18b36c9a523c84365b561f8747b9469091a2af6055ec8605c9f07402bb9c131','c52ca4dd8f47dce11c06e4f1a07d618e7826db2737976f5c047b1f155c6017c5','ce1a7281a9251f5af68c099d88fa9b6436e7d615f23e979af98c3b4c5f3bdc53');
INSERT INTO blocks VALUES(310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,NULL,NULL,'9ef1ea46847b94d3ba16b2f62b2cccb5d2813f8e58d26ac2952e914f8d75f89e','fb51d9c2e1ed5d70d8b10cf7e21ce240b648f18a79610953b305cf672bdaecfd','58e3e4ce766b0a3b3f4d39d1967f8128f7e6f2e56619b386cd022b9c3469000f');
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
INSERT INTO broadcasts VALUES(12,'bf56a1b4fb8fd5baa2ebae12b961d01e17f20812690d8e0de26a766c12857777',310011,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000000,100.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(19,'286d0d3c199816de92ae01f4976a20b1b5e838e63a9c75034a216eb8def721fd',310018,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000050,99.86166,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(20,'81c1352495060dcc6b95618054280fbce920365aa025f4903e1840d6902b067d',310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000101,100.343,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(21,'248e7b3add0f648221a23da67e6e3ab52c12fd50b4ce589ad8273877c89967ad',310020,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000201,2.0,5000000,'Unit Test',0,'valid');
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
INSERT INTO btcpays VALUES(5,'6a386e57268814b5dd38dce3e6471223e09d29aaca603183c3418fe90df94e82',310004,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',50000000,'507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379_178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424','valid');
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
INSERT INTO burns VALUES(1,'6dc5b0a33d4d4297e0f5cc2d23ae307951d32aab2d86b7fa147b385219f3a597',310000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',62000000,93000000000,'valid');
INSERT INTO burns VALUES(23,'c3f73d02e630cb2824f044e6d91f47b1ce351feff0339ea7b85652d24d8ff6bc',310022,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',38000000,56999887262,'valid');
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
INSERT INTO credits VALUES(310000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',93000000000,'burn','6dc5b0a33d4d4297e0f5cc2d23ae307951d32aab2d86b7fa147b385219f3a597');
INSERT INTO credits VALUES(310001,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',50000000,'send','e535051ed7386995cc9152ea2d403f8460a59a5d084d4443158e466d743b3d63');
INSERT INTO credits VALUES(310004,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'btcpay','6a386e57268814b5dd38dce3e6471223e09d29aaca603183c3418fe90df94e82');
INSERT INTO credits VALUES(310005,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',1000000000,'issuance','22c284e49ded9ee4c668a675f1eaf32925992911384db539cfef1b3784ea7cd6');
INSERT INTO credits VALUES(310006,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC',100000,'issuance','21fe775c51dee2527cbafa7d5231a22ae988f7428563c2bbaad3692b65a32e28');
INSERT INTO credits VALUES(310007,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBB',4000000,'send','611bd2d4fd7dae2282e00873249574cd435052cb274fe70ec9b96a1549d78042');
INSERT INTO credits VALUES(310008,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',526,'send','2f40b6b1c699c15fd194fa30a003dcf2a2a4421a92aece4e5a5ee9c4b475d43d');
INSERT INTO credits VALUES(310009,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',24,'dividend','8d3c3043fd1507d2446705284cb9b08315e4573bb6530eacf091de73bebebd9e');
INSERT INTO credits VALUES(310010,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',420800,'dividend','1330d6ba840f2a7b29cbfb8d7fa1e22450aad4111e2a7ef1fcaaf518dda6490b');
INSERT INTO credits VALUES(310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',4250000,'filled','f6a6834a51451c205353d5d36950b48b7deebca3ea339b31a66e8204163cecfc');
INSERT INTO credits VALUES(310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',5000000,'cancel order','178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424');
INSERT INTO credits VALUES(310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d');
INSERT INTO credits VALUES(310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d');
INSERT INTO credits VALUES(310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a');
INSERT INTO credits VALUES(310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a');
INSERT INTO credits VALUES(310018,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',59137500,'bet settled: liquidated for bear','286d0d3c199816de92ae01f4976a20b1b5e838e63a9c75034a216eb8def721fd');
INSERT INTO credits VALUES(310018,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',3112500,'feed fee','286d0d3c199816de92ae01f4976a20b1b5e838e63a9c75034a216eb8def721fd');
INSERT INTO credits VALUES(310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',159300000,'bet settled','81c1352495060dcc6b95618054280fbce920365aa025f4903e1840d6902b067d');
INSERT INTO credits VALUES(310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',315700000,'bet settled','81c1352495060dcc6b95618054280fbce920365aa025f4903e1840d6902b067d');
INSERT INTO credits VALUES(310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',25000000,'feed fee','81c1352495060dcc6b95618054280fbce920365aa025f4903e1840d6902b067d');
INSERT INTO credits VALUES(310020,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',1330000000,'bet settled: for notequal','248e7b3add0f648221a23da67e6e3ab52c12fd50b4ce589ad8273877c89967ad');
INSERT INTO credits VALUES(310020,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',70000000,'feed fee','248e7b3add0f648221a23da67e6e3ab52c12fd50b4ce589ad8273877c89967ad');
INSERT INTO credits VALUES(310022,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',56999887262,'burn','c3f73d02e630cb2824f044e6d91f47b1ce351feff0339ea7b85652d24d8ff6bc');
INSERT INTO credits VALUES(310023,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',8500000,'recredit wager remaining','72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64');
INSERT INTO credits VALUES(310023,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',10000,'send','004cbeaac3e999874c19d95a83cde38472c9392c17ae93b49e741ce078694912');
INSERT INTO credits VALUES(310032,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',50000000,'cancel order','6f890013e2d78bfc0201e4570d2c778487a1b63eb5209f22dd9f89058cc5ac58');
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
INSERT INTO debits VALUES(310001,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'send','e535051ed7386995cc9152ea2d403f8460a59a5d084d4443158e466d743b3d63');
INSERT INTO debits VALUES(310003,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',105000000,'open order','178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424');
INSERT INTO debits VALUES(310005,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','22c284e49ded9ee4c668a675f1eaf32925992911384db539cfef1b3784ea7cd6');
INSERT INTO debits VALUES(310006,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','21fe775c51dee2527cbafa7d5231a22ae988f7428563c2bbaad3692b65a32e28');
INSERT INTO debits VALUES(310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',4000000,'send','611bd2d4fd7dae2282e00873249574cd435052cb274fe70ec9b96a1549d78042');
INSERT INTO debits VALUES(310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC',526,'send','2f40b6b1c699c15fd194fa30a003dcf2a2a4421a92aece4e5a5ee9c4b475d43d');
INSERT INTO debits VALUES(310009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',24,'dividend','8d3c3043fd1507d2446705284cb9b08315e4573bb6530eacf091de73bebebd9e');
INSERT INTO debits VALUES(310009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',20000,'dividend fee','8d3c3043fd1507d2446705284cb9b08315e4573bb6530eacf091de73bebebd9e');
INSERT INTO debits VALUES(310010,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',420800,'dividend','1330d6ba840f2a7b29cbfb8d7fa1e22450aad4111e2a7ef1fcaaf518dda6490b');
INSERT INTO debits VALUES(310010,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',20000,'dividend fee','1330d6ba840f2a7b29cbfb8d7fa1e22450aad4111e2a7ef1fcaaf518dda6490b');
INSERT INTO debits VALUES(310012,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'bet','72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64');
INSERT INTO debits VALUES(310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',25000000,'bet','f6a6834a51451c205353d5d36950b48b7deebca3ea339b31a66e8204163cecfc');
INSERT INTO debits VALUES(310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',150000000,'bet','9b3799f2ce6c01f8fc8d54dd43b103b8ab992ae345d7af234b67bd8c0aa4d9b2');
INSERT INTO debits VALUES(310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',350000000,'bet','97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d');
INSERT INTO debits VALUES(310016,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',750000000,'bet','5fae745825197093b0f1efcdffc79d58a6f609e1b794c537faa555c01c270f13');
INSERT INTO debits VALUES(310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',650000000,'bet','ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a');
INSERT INTO debits VALUES(310021,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',50000000,'open order','6f890013e2d78bfc0201e4570d2c778487a1b63eb5209f22dd9f89058cc5ac58');
INSERT INTO debits VALUES(310023,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC',10000,'send','004cbeaac3e999874c19d95a83cde38472c9392c17ae93b49e741ce078694912');
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
INSERT INTO dividends VALUES(10,'8d3c3043fd1507d2446705284cb9b08315e4573bb6530eacf091de73bebebd9e',310009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB','XCP',600,20000,'valid');
INSERT INTO dividends VALUES(11,'1330d6ba840f2a7b29cbfb8d7fa1e22450aad4111e2a7ef1fcaaf518dda6490b',310010,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC','XCP',800,20000,'valid');
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
INSERT INTO issuances VALUES(6,'22c284e49ded9ee4c668a675f1eaf32925992911384db539cfef1b3784ea7cd6',310005,'BBBB',1000000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'',50000000,0,'valid');
INSERT INTO issuances VALUES(7,'21fe775c51dee2527cbafa7d5231a22ae988f7428563c2bbaad3692b65a32e28',310006,'BBBC',100000,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'foobar',50000000,0,'valid');
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
INSERT INTO messages VALUES(0,310000,'insert','credits','{"action": "burn", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310000, "event": "6dc5b0a33d4d4297e0f5cc2d23ae307951d32aab2d86b7fa147b385219f3a597", "quantity": 93000000000}',0);
INSERT INTO messages VALUES(1,310000,'insert','burns','{"block_index": 310000, "burned": 62000000, "earned": 93000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "6dc5b0a33d4d4297e0f5cc2d23ae307951d32aab2d86b7fa147b385219f3a597", "tx_index": 1}',0);
INSERT INTO messages VALUES(2,310001,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310001, "event": "e535051ed7386995cc9152ea2d403f8460a59a5d084d4443158e466d743b3d63", "quantity": 50000000}',0);
INSERT INTO messages VALUES(3,310001,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310001, "event": "e535051ed7386995cc9152ea2d403f8460a59a5d084d4443158e466d743b3d63", "quantity": 50000000}',0);
INSERT INTO messages VALUES(4,310001,'insert','sends','{"asset": "XCP", "block_index": 310001, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 50000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "e535051ed7386995cc9152ea2d403f8460a59a5d084d4443158e466d743b3d63", "tx_index": 2}',0);
INSERT INTO messages VALUES(5,310002,'insert','orders','{"block_index": 310002, "expiration": 10, "expire_index": 310012, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 50000000, "give_remaining": 50000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379", "tx_index": 3}',0);
INSERT INTO messages VALUES(6,310003,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310003, "event": "178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424", "quantity": 105000000}',0);
INSERT INTO messages VALUES(7,310003,'insert','orders','{"block_index": 310003, "expiration": 10, "expire_index": 310013, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 50000000, "get_remaining": 50000000, "give_asset": "XCP", "give_quantity": 105000000, "give_remaining": 105000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424", "tx_index": 4}',0);
INSERT INTO messages VALUES(8,310003,'update','orders','{"fee_provided_remaining": 142858, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379"}',0);
INSERT INTO messages VALUES(9,310003,'update','orders','{"fee_provided_remaining": 6800, "fee_required_remaining": 42858, "get_remaining": 0, "give_remaining": 5000000, "status": "open", "tx_hash": "178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424"}',0);
INSERT INTO messages VALUES(10,310003,'insert','order_matches','{"backward_asset": "XCP", "backward_quantity": 100000000, "block_index": 310003, "fee_paid": 857142, "forward_asset": "BTC", "forward_quantity": 50000000, "id": "507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379_178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424", "match_expire_index": 310023, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 310002, "tx0_expiration": 10, "tx0_hash": "507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379", "tx0_index": 3, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_block_index": 310003, "tx1_expiration": 10, "tx1_hash": "178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424", "tx1_index": 4}',0);
INSERT INTO messages VALUES(11,310004,'insert','credits','{"action": "btcpay", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310004, "event": "6a386e57268814b5dd38dce3e6471223e09d29aaca603183c3418fe90df94e82", "quantity": 100000000}',0);
INSERT INTO messages VALUES(12,310004,'update','order_matches','{"order_match_id": "507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379_178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424", "status": "completed"}',0);
INSERT INTO messages VALUES(13,310004,'insert','btcpays','{"block_index": 310004, "btc_amount": 50000000, "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "order_match_id": "507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379_178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424", "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "6a386e57268814b5dd38dce3e6471223e09d29aaca603183c3418fe90df94e82", "tx_index": 5}',0);
INSERT INTO messages VALUES(14,310005,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310005, "event": "22c284e49ded9ee4c668a675f1eaf32925992911384db539cfef1b3784ea7cd6", "quantity": 50000000}',0);
INSERT INTO messages VALUES(15,310005,'insert','issuances','{"asset": "BBBB", "block_index": 310005, "call_date": 0, "call_price": 0.0, "callable": false, "description": "", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "22c284e49ded9ee4c668a675f1eaf32925992911384db539cfef1b3784ea7cd6", "tx_index": 6}',0);
INSERT INTO messages VALUES(16,310005,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBB", "block_index": 310005, "event": "22c284e49ded9ee4c668a675f1eaf32925992911384db539cfef1b3784ea7cd6", "quantity": 1000000000}',0);
INSERT INTO messages VALUES(17,310006,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310006, "event": "21fe775c51dee2527cbafa7d5231a22ae988f7428563c2bbaad3692b65a32e28", "quantity": 50000000}',0);
INSERT INTO messages VALUES(18,310006,'insert','issuances','{"asset": "BBBC", "block_index": 310006, "call_date": 0, "call_price": 0.0, "callable": false, "description": "foobar", "divisible": false, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "21fe775c51dee2527cbafa7d5231a22ae988f7428563c2bbaad3692b65a32e28", "tx_index": 7}',0);
INSERT INTO messages VALUES(19,310006,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBC", "block_index": 310006, "event": "21fe775c51dee2527cbafa7d5231a22ae988f7428563c2bbaad3692b65a32e28", "quantity": 100000}',0);
INSERT INTO messages VALUES(20,310007,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBB", "block_index": 310007, "event": "611bd2d4fd7dae2282e00873249574cd435052cb274fe70ec9b96a1549d78042", "quantity": 4000000}',0);
INSERT INTO messages VALUES(21,310007,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "BBBB", "block_index": 310007, "event": "611bd2d4fd7dae2282e00873249574cd435052cb274fe70ec9b96a1549d78042", "quantity": 4000000}',0);
INSERT INTO messages VALUES(22,310007,'insert','sends','{"asset": "BBBB", "block_index": 310007, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 4000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "611bd2d4fd7dae2282e00873249574cd435052cb274fe70ec9b96a1549d78042", "tx_index": 8}',0);
INSERT INTO messages VALUES(23,310008,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBC", "block_index": 310008, "event": "2f40b6b1c699c15fd194fa30a003dcf2a2a4421a92aece4e5a5ee9c4b475d43d", "quantity": 526}',0);
INSERT INTO messages VALUES(24,310008,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "BBBC", "block_index": 310008, "event": "2f40b6b1c699c15fd194fa30a003dcf2a2a4421a92aece4e5a5ee9c4b475d43d", "quantity": 526}',0);
INSERT INTO messages VALUES(25,310008,'insert','sends','{"asset": "BBBC", "block_index": 310008, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 526, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "2f40b6b1c699c15fd194fa30a003dcf2a2a4421a92aece4e5a5ee9c4b475d43d", "tx_index": 9}',0);
INSERT INTO messages VALUES(26,310009,'insert','debits','{"action": "dividend", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310009, "event": "8d3c3043fd1507d2446705284cb9b08315e4573bb6530eacf091de73bebebd9e", "quantity": 24}',0);
INSERT INTO messages VALUES(27,310009,'insert','debits','{"action": "dividend fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310009, "event": "8d3c3043fd1507d2446705284cb9b08315e4573bb6530eacf091de73bebebd9e", "quantity": 20000}',0);
INSERT INTO messages VALUES(28,310009,'insert','credits','{"action": "dividend", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310009, "event": "8d3c3043fd1507d2446705284cb9b08315e4573bb6530eacf091de73bebebd9e", "quantity": 24}',0);
INSERT INTO messages VALUES(29,310009,'insert','dividends','{"asset": "BBBB", "block_index": 310009, "dividend_asset": "XCP", "fee_paid": 20000, "quantity_per_unit": 600, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "8d3c3043fd1507d2446705284cb9b08315e4573bb6530eacf091de73bebebd9e", "tx_index": 10}',0);
INSERT INTO messages VALUES(30,310010,'insert','debits','{"action": "dividend", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310010, "event": "1330d6ba840f2a7b29cbfb8d7fa1e22450aad4111e2a7ef1fcaaf518dda6490b", "quantity": 420800}',0);
INSERT INTO messages VALUES(31,310010,'insert','debits','{"action": "dividend fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310010, "event": "1330d6ba840f2a7b29cbfb8d7fa1e22450aad4111e2a7ef1fcaaf518dda6490b", "quantity": 20000}',0);
INSERT INTO messages VALUES(32,310010,'insert','credits','{"action": "dividend", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310010, "event": "1330d6ba840f2a7b29cbfb8d7fa1e22450aad4111e2a7ef1fcaaf518dda6490b", "quantity": 420800}',0);
INSERT INTO messages VALUES(33,310010,'insert','dividends','{"asset": "BBBC", "block_index": 310010, "dividend_asset": "XCP", "fee_paid": 20000, "quantity_per_unit": 800, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "1330d6ba840f2a7b29cbfb8d7fa1e22450aad4111e2a7ef1fcaaf518dda6490b", "tx_index": 11}',0);
INSERT INTO messages VALUES(34,310011,'insert','broadcasts','{"block_index": 310011, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "bf56a1b4fb8fd5baa2ebae12b961d01e17f20812690d8e0de26a766c12857777", "tx_index": 12, "value": 100.0}',0);
INSERT INTO messages VALUES(35,310012,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310012, "event": "72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64", "quantity": 50000000}',0);
INSERT INTO messages VALUES(36,310012,'insert','bets','{"bet_type": 0, "block_index": 310012, "counterwager_quantity": 25000000, "counterwager_remaining": 25000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310022, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 15120, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64", "tx_index": 13, "wager_quantity": 50000000, "wager_remaining": 50000000}',0);
INSERT INTO messages VALUES(37,310013,'update','orders','{"status": "expired", "tx_hash": "507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379"}',0);
INSERT INTO messages VALUES(38,310013,'insert','order_expirations','{"block_index": 310013, "order_hash": "507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379", "order_index": 3, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
INSERT INTO messages VALUES(39,310013,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310013, "event": "f6a6834a51451c205353d5d36950b48b7deebca3ea339b31a66e8204163cecfc", "quantity": 25000000}',0);
INSERT INTO messages VALUES(40,310013,'insert','bets','{"bet_type": 1, "block_index": 310013, "counterwager_quantity": 41500000, "counterwager_remaining": 41500000, "deadline": 1388000100, "expiration": 10, "expire_index": 310023, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 15120, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "f6a6834a51451c205353d5d36950b48b7deebca3ea339b31a66e8204163cecfc", "tx_index": 14, "wager_quantity": 25000000, "wager_remaining": 25000000}',0);
INSERT INTO messages VALUES(41,310013,'update','bets','{"counterwager_remaining": 4250000, "status": "open", "tx_hash": "72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64", "wager_remaining": 8500000}',0);
INSERT INTO messages VALUES(42,310013,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310013, "event": "f6a6834a51451c205353d5d36950b48b7deebca3ea339b31a66e8204163cecfc", "quantity": 4250000}',0);
INSERT INTO messages VALUES(43,310013,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "f6a6834a51451c205353d5d36950b48b7deebca3ea339b31a66e8204163cecfc", "wager_remaining": 4250000}',0);
INSERT INTO messages VALUES(44,310013,'insert','bet_matches','{"backward_quantity": 20750000, "block_index": 310013, "deadline": 1388000100, "fee_fraction_int": 5000000, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 41500000, "id": "72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64_f6a6834a51451c205353d5d36950b48b7deebca3ea339b31a66e8204163cecfc", "initial_value": 100.0, "leverage": 15120, "match_expire_index": 310022, "status": "pending", "target_value": 0.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 0, "tx0_block_index": 310012, "tx0_expiration": 10, "tx0_hash": "72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64", "tx0_index": 13, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_bet_type": 1, "tx1_block_index": 310013, "tx1_expiration": 10, "tx1_hash": "f6a6834a51451c205353d5d36950b48b7deebca3ea339b31a66e8204163cecfc", "tx1_index": 14}',0);
INSERT INTO messages VALUES(45,310014,'update','orders','{"status": "expired", "tx_hash": "178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424"}',0);
INSERT INTO messages VALUES(46,310014,'insert','credits','{"action": "cancel order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310014, "event": "178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424", "quantity": 5000000}',0);
INSERT INTO messages VALUES(47,310014,'insert','order_expirations','{"block_index": 310014, "order_hash": "178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424", "order_index": 4, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
INSERT INTO messages VALUES(48,310014,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310014, "event": "9b3799f2ce6c01f8fc8d54dd43b103b8ab992ae345d7af234b67bd8c0aa4d9b2", "quantity": 150000000}',0);
INSERT INTO messages VALUES(49,310014,'insert','bets','{"bet_type": 0, "block_index": 310014, "counterwager_quantity": 350000000, "counterwager_remaining": 350000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310024, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "9b3799f2ce6c01f8fc8d54dd43b103b8ab992ae345d7af234b67bd8c0aa4d9b2", "tx_index": 15, "wager_quantity": 150000000, "wager_remaining": 150000000}',0);
INSERT INTO messages VALUES(50,310015,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310015, "event": "97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d", "quantity": 350000000}',0);
INSERT INTO messages VALUES(51,310015,'insert','bets','{"bet_type": 1, "block_index": 310015, "counterwager_quantity": 150000000, "counterwager_remaining": 150000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310025, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d", "tx_index": 16, "wager_quantity": 350000000, "wager_remaining": 350000000}',0);
INSERT INTO messages VALUES(52,310015,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310015, "event": "97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d", "quantity": 0}',0);
INSERT INTO messages VALUES(53,310015,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "9b3799f2ce6c01f8fc8d54dd43b103b8ab992ae345d7af234b67bd8c0aa4d9b2", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(54,310015,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310015, "event": "97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d", "quantity": 0}',0);
INSERT INTO messages VALUES(55,310015,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(56,310015,'insert','bet_matches','{"backward_quantity": 350000000, "block_index": 310015, "deadline": 1388000100, "fee_fraction_int": 5000000, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 150000000, "id": "9b3799f2ce6c01f8fc8d54dd43b103b8ab992ae345d7af234b67bd8c0aa4d9b2_97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d", "initial_value": 100.0, "leverage": 5040, "match_expire_index": 310024, "status": "pending", "target_value": 0.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 0, "tx0_block_index": 310014, "tx0_expiration": 10, "tx0_hash": "9b3799f2ce6c01f8fc8d54dd43b103b8ab992ae345d7af234b67bd8c0aa4d9b2", "tx0_index": 15, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_bet_type": 1, "tx1_block_index": 310015, "tx1_expiration": 10, "tx1_hash": "97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d", "tx1_index": 16}',0);
INSERT INTO messages VALUES(57,310016,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310016, "event": "5fae745825197093b0f1efcdffc79d58a6f609e1b794c537faa555c01c270f13", "quantity": 750000000}',0);
INSERT INTO messages VALUES(58,310016,'insert','bets','{"bet_type": 2, "block_index": 310016, "counterwager_quantity": 650000000, "counterwager_remaining": 650000000, "deadline": 1388000200, "expiration": 10, "expire_index": 310026, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 1.0, "tx_hash": "5fae745825197093b0f1efcdffc79d58a6f609e1b794c537faa555c01c270f13", "tx_index": 17, "wager_quantity": 750000000, "wager_remaining": 750000000}',0);
INSERT INTO messages VALUES(59,310017,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310017, "event": "ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a", "quantity": 650000000}',0);
INSERT INTO messages VALUES(60,310017,'insert','bets','{"bet_type": 3, "block_index": 310017, "counterwager_quantity": 750000000, "counterwager_remaining": 750000000, "deadline": 1388000200, "expiration": 10, "expire_index": 310027, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 1.0, "tx_hash": "ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a", "tx_index": 18, "wager_quantity": 650000000, "wager_remaining": 650000000}',0);
INSERT INTO messages VALUES(61,310017,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310017, "event": "ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a", "quantity": 0}',0);
INSERT INTO messages VALUES(62,310017,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "5fae745825197093b0f1efcdffc79d58a6f609e1b794c537faa555c01c270f13", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(63,310017,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310017, "event": "ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a", "quantity": 0}',0);
INSERT INTO messages VALUES(64,310017,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(65,310017,'insert','bet_matches','{"backward_quantity": 650000000, "block_index": 310017, "deadline": 1388000200, "fee_fraction_int": 5000000, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 750000000, "id": "5fae745825197093b0f1efcdffc79d58a6f609e1b794c537faa555c01c270f13_ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a", "initial_value": 100.0, "leverage": 5040, "match_expire_index": 310026, "status": "pending", "target_value": 1.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 2, "tx0_block_index": 310016, "tx0_expiration": 10, "tx0_hash": "5fae745825197093b0f1efcdffc79d58a6f609e1b794c537faa555c01c270f13", "tx0_index": 17, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_bet_type": 3, "tx1_block_index": 310017, "tx1_expiration": 10, "tx1_hash": "ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a", "tx1_index": 18}',0);
INSERT INTO messages VALUES(66,310018,'insert','broadcasts','{"block_index": 310018, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000050, "tx_hash": "286d0d3c199816de92ae01f4976a20b1b5e838e63a9c75034a216eb8def721fd", "tx_index": 19, "value": 99.86166}',0);
INSERT INTO messages VALUES(67,310018,'insert','credits','{"action": "bet settled: liquidated for bear", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310018, "event": "286d0d3c199816de92ae01f4976a20b1b5e838e63a9c75034a216eb8def721fd", "quantity": 59137500}',0);
INSERT INTO messages VALUES(68,310018,'insert','credits','{"action": "feed fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310018, "event": "286d0d3c199816de92ae01f4976a20b1b5e838e63a9c75034a216eb8def721fd", "quantity": 3112500}',0);
INSERT INTO messages VALUES(69,310018,'insert','bet_match_resolutions','{"bear_credit": 59137500, "bet_match_id": "72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64_f6a6834a51451c205353d5d36950b48b7deebca3ea339b31a66e8204163cecfc", "bet_match_type_id": 1, "block_index": 310018, "bull_credit": 0, "escrow_less_fee": null, "fee": 3112500, "settled": false, "winner": null}',0);
INSERT INTO messages VALUES(70,310018,'update','bet_matches','{"bet_match_id": "72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64_f6a6834a51451c205353d5d36950b48b7deebca3ea339b31a66e8204163cecfc", "status": "settled: liquidated for bear"}',0);
INSERT INTO messages VALUES(71,310019,'insert','broadcasts','{"block_index": 310019, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000101, "tx_hash": "81c1352495060dcc6b95618054280fbce920365aa025f4903e1840d6902b067d", "tx_index": 20, "value": 100.343}',0);
INSERT INTO messages VALUES(72,310019,'insert','credits','{"action": "bet settled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310019, "event": "81c1352495060dcc6b95618054280fbce920365aa025f4903e1840d6902b067d", "quantity": 159300000}',0);
INSERT INTO messages VALUES(73,310019,'insert','credits','{"action": "bet settled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310019, "event": "81c1352495060dcc6b95618054280fbce920365aa025f4903e1840d6902b067d", "quantity": 315700000}',0);
INSERT INTO messages VALUES(74,310019,'insert','credits','{"action": "feed fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310019, "event": "81c1352495060dcc6b95618054280fbce920365aa025f4903e1840d6902b067d", "quantity": 25000000}',0);
INSERT INTO messages VALUES(75,310019,'insert','bet_match_resolutions','{"bear_credit": 315700000, "bet_match_id": "9b3799f2ce6c01f8fc8d54dd43b103b8ab992ae345d7af234b67bd8c0aa4d9b2_97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d", "bet_match_type_id": 1, "block_index": 310019, "bull_credit": 159300000, "escrow_less_fee": null, "fee": 25000000, "settled": true, "winner": null}',0);
INSERT INTO messages VALUES(76,310019,'update','bet_matches','{"bet_match_id": "9b3799f2ce6c01f8fc8d54dd43b103b8ab992ae345d7af234b67bd8c0aa4d9b2_97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d", "status": "settled"}',0);
INSERT INTO messages VALUES(77,310020,'insert','broadcasts','{"block_index": 310020, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000201, "tx_hash": "248e7b3add0f648221a23da67e6e3ab52c12fd50b4ce589ad8273877c89967ad", "tx_index": 21, "value": 2.0}',0);
INSERT INTO messages VALUES(78,310020,'insert','credits','{"action": "bet settled: for notequal", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310020, "event": "248e7b3add0f648221a23da67e6e3ab52c12fd50b4ce589ad8273877c89967ad", "quantity": 1330000000}',0);
INSERT INTO messages VALUES(79,310020,'insert','credits','{"action": "feed fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310020, "event": "248e7b3add0f648221a23da67e6e3ab52c12fd50b4ce589ad8273877c89967ad", "quantity": 70000000}',0);
INSERT INTO messages VALUES(80,310020,'insert','bet_match_resolutions','{"bear_credit": null, "bet_match_id": "5fae745825197093b0f1efcdffc79d58a6f609e1b794c537faa555c01c270f13_ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a", "bet_match_type_id": 5, "block_index": 310020, "bull_credit": null, "escrow_less_fee": 1330000000, "fee": 70000000, "settled": null, "winner": "NotEqual"}',0);
INSERT INTO messages VALUES(81,310020,'update','bet_matches','{"bet_match_id": "5fae745825197093b0f1efcdffc79d58a6f609e1b794c537faa555c01c270f13_ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a", "status": "settled: for notequal"}',0);
INSERT INTO messages VALUES(82,310021,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBB", "block_index": 310021, "event": "6f890013e2d78bfc0201e4570d2c778487a1b63eb5209f22dd9f89058cc5ac58", "quantity": 50000000}',0);
INSERT INTO messages VALUES(83,310021,'insert','orders','{"block_index": 310021, "expiration": 10, "expire_index": 310031, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 50000000, "get_remaining": 50000000, "give_asset": "BBBB", "give_quantity": 50000000, "give_remaining": 50000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "6f890013e2d78bfc0201e4570d2c778487a1b63eb5209f22dd9f89058cc5ac58", "tx_index": 22}',0);
INSERT INTO messages VALUES(84,310022,'insert','credits','{"action": "burn", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310022, "event": "c3f73d02e630cb2824f044e6d91f47b1ce351feff0339ea7b85652d24d8ff6bc", "quantity": 56999887262}',0);
INSERT INTO messages VALUES(85,310022,'insert','burns','{"block_index": 310022, "burned": 38000000, "earned": 56999887262, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "c3f73d02e630cb2824f044e6d91f47b1ce351feff0339ea7b85652d24d8ff6bc", "tx_index": 23}',0);
INSERT INTO messages VALUES(86,310023,'update','bets','{"status": "expired", "tx_hash": "72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64"}',0);
INSERT INTO messages VALUES(87,310023,'insert','credits','{"action": "recredit wager remaining", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310023, "event": "72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64", "quantity": 8500000}',0);
INSERT INTO messages VALUES(88,310023,'insert','bet_expirations','{"bet_hash": "72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64", "bet_index": 13, "block_index": 310023, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
INSERT INTO messages VALUES(89,310023,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBC", "block_index": 310023, "event": "004cbeaac3e999874c19d95a83cde38472c9392c17ae93b49e741ce078694912", "quantity": 10000}',0);
INSERT INTO messages VALUES(90,310023,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "BBBC", "block_index": 310023, "event": "004cbeaac3e999874c19d95a83cde38472c9392c17ae93b49e741ce078694912", "quantity": 10000}',0);
INSERT INTO messages VALUES(91,310023,'insert','sends','{"asset": "BBBC", "block_index": 310023, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 10000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "004cbeaac3e999874c19d95a83cde38472c9392c17ae93b49e741ce078694912", "tx_index": 24}',0);
INSERT INTO messages VALUES(92,310032,'update','orders','{"status": "expired", "tx_hash": "6f890013e2d78bfc0201e4570d2c778487a1b63eb5209f22dd9f89058cc5ac58"}',0);
INSERT INTO messages VALUES(93,310032,'insert','credits','{"action": "cancel order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBB", "block_index": 310032, "event": "6f890013e2d78bfc0201e4570d2c778487a1b63eb5209f22dd9f89058cc5ac58", "quantity": 50000000}',0);
INSERT INTO messages VALUES(94,310032,'insert','order_expirations','{"block_index": 310032, "order_hash": "6f890013e2d78bfc0201e4570d2c778487a1b63eb5209f22dd9f89058cc5ac58", "order_index": 22, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
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
INSERT INTO order_expirations VALUES(3,'507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',310013);
INSERT INTO order_expirations VALUES(4,'178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',310014);
INSERT INTO order_expirations VALUES(22,'6f890013e2d78bfc0201e4570d2c778487a1b63eb5209f22dd9f89058cc5ac58','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',310032);
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
INSERT INTO order_matches VALUES('507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379_178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424',3,'507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',4,'178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BTC',50000000,'XCP',100000000,310002,310003,310003,10,10,310023,857142,'completed');
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
INSERT INTO orders VALUES(3,'507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379',310002,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BTC',50000000,0,'XCP',100000000,0,10,310012,0,0,1000000,142858,'expired');
INSERT INTO orders VALUES(4,'178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424',310003,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',105000000,5000000,'BTC',50000000,0,10,310013,900000,42858,6800,6800,'expired');
INSERT INTO orders VALUES(22,'6f890013e2d78bfc0201e4570d2c778487a1b63eb5209f22dd9f89058cc5ac58',310021,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',50000000,50000000,'XCP',50000000,50000000,10,310031,0,0,6800,6800,'expired');
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
INSERT INTO sends VALUES(2,'e535051ed7386995cc9152ea2d403f8460a59a5d084d4443158e466d743b3d63',310001,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',50000000,'valid');
INSERT INTO sends VALUES(8,'611bd2d4fd7dae2282e00873249574cd435052cb274fe70ec9b96a1549d78042',310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBB',4000000,'valid');
INSERT INTO sends VALUES(9,'2f40b6b1c699c15fd194fa30a003dcf2a2a4421a92aece4e5a5ee9c4b475d43d',310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',526,'valid');
INSERT INTO sends VALUES(24,'004cbeaac3e999874c19d95a83cde38472c9392c17ae93b49e741ce078694912',310023,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',10000,'valid');
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
INSERT INTO transactions VALUES(1,'6dc5b0a33d4d4297e0f5cc2d23ae307951d32aab2d86b7fa147b385219f3a597',310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
INSERT INTO transactions VALUES(2,'e535051ed7386995cc9152ea2d403f8460a59a5d084d4443158e466d743b3d63',310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,7650,X'0000000000000000000000010000000002FAF080',1);
INSERT INTO transactions VALUES(3,'507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379',310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,1000000,X'0000000A00000000000000000000000002FAF08000000000000000010000000005F5E100000A0000000000000000',1);
INSERT INTO transactions VALUES(4,'178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424',310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000000010000000006422C4000000000000000000000000002FAF080000A00000000000DBBA0',1);
INSERT INTO transactions VALUES(5,'6a386e57268814b5dd38dce3e6471223e09d29aaca603183c3418fe90df94e82',310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',50000000,9675,X'0000000B507FDABA6D6173642277FA3744428FA9AED27C8DC16612AAE6B2AD3A9FBB5379178E4AC45CF71F96A3A09F58739B504348173DA619E567ED0B3C6BC790181424',1);
INSERT INTO transactions VALUES(6,'22c284e49ded9ee4c668a675f1eaf32925992911384db539cfef1b3784ea7cd6',310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'000000140000000000004767000000003B9ACA000100000000000000000000',1);
INSERT INTO transactions VALUES(7,'21fe775c51dee2527cbafa7d5231a22ae988f7428563c2bbaad3692b65a32e28',310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'00000014000000000000476800000000000186A00000000000000000000006666F6F626172',1);
INSERT INTO transactions VALUES(8,'611bd2d4fd7dae2282e00873249574cd435052cb274fe70ec9b96a1549d78042',310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,7650,X'00000000000000000000476700000000003D0900',1);
INSERT INTO transactions VALUES(9,'2f40b6b1c699c15fd194fa30a003dcf2a2a4421a92aece4e5a5ee9c4b475d43d',310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,7650,X'000000000000000000004768000000000000020E',1);
INSERT INTO transactions VALUES(10,'8d3c3043fd1507d2446705284cb9b08315e4573bb6530eacf091de73bebebd9e',310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'00000032000000000000025800000000000047670000000000000001',1);
INSERT INTO transactions VALUES(11,'1330d6ba840f2a7b29cbfb8d7fa1e22450aad4111e2a7ef1fcaaf518dda6490b',310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'00000032000000000000032000000000000047680000000000000001',1);
INSERT INTO transactions VALUES(12,'bf56a1b4fb8fd5baa2ebae12b961d01e17f20812690d8e0de26a766c12857777',310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001E52BB33004059000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(13,'72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64',310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000052BB33640000000002FAF08000000000017D7840000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(14,'f6a6834a51451c205353d5d36950b48b7deebca3ea339b31a66e8204163cecfc',310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,12175,X'00000028000152BB336400000000017D78400000000002793D60000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(15,'9b3799f2ce6c01f8fc8d54dd43b103b8ab992ae345d7af234b67bd8c0aa4d9b2',310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,12175,X'00000028000052BB33640000000008F0D1800000000014DC93800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(16,'97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d',310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,12175,X'00000028000152BB33640000000014DC93800000000008F0D1800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(17,'5fae745825197093b0f1efcdffc79d58a6f609e1b794c537faa555c01c270f13',310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,12175,X'00000028000252BB33C8000000002CB417800000000026BE36803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(18,'ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a',310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,12175,X'00000028000352BB33C80000000026BE3680000000002CB417803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(19,'286d0d3c199816de92ae01f4976a20b1b5e838e63a9c75034a216eb8def721fd',310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,11325,X'0000001E52BB33324058F7256FFC115E004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(20,'81c1352495060dcc6b95618054280fbce920365aa025f4903e1840d6902b067d',310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001E52BB3365405915F3B645A1CB004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(21,'248e7b3add0f648221a23da67e6e3ab52c12fd50b4ce589ad8273877c89967ad',310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001E52BB33C94000000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(22,'6f890013e2d78bfc0201e4570d2c778487a1b63eb5209f22dd9f89058cc5ac58',310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000047670000000002FAF08000000000000000010000000002FAF080000A0000000000000000',1);
INSERT INTO transactions VALUES(23,'c3f73d02e630cb2824f044e6d91f47b1ce351feff0339ea7b85652d24d8ff6bc',310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mvCounterpartyXXXXXXXXXXXXXXW24Hef',100000000,10150,X'',1);
INSERT INTO transactions VALUES(24,'004cbeaac3e999874c19d95a83cde38472c9392c17ae93b49e741ce078694912',310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,7650,X'0000000000000000000047680000000000002710',1);
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
INSERT INTO undolog VALUES(13,'UPDATE orders SET tx_index=3,tx_hash=''507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379'',block_index=310002,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''BTC'',give_quantity=50000000,give_remaining=50000000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=10,expire_index=310012,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(14,'UPDATE orders SET tx_index=4,tx_hash=''178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424'',block_index=310003,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''XCP'',give_quantity=105000000,give_remaining=105000000,get_asset=''BTC'',get_quantity=50000000,get_remaining=50000000,expiration=10,expire_index=310013,fee_required=900000,fee_required_remaining=900000,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(15,'DELETE FROM order_matches WHERE rowid=1');
INSERT INTO undolog VALUES(16,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92845000000 WHERE rowid=1');
INSERT INTO undolog VALUES(17,'DELETE FROM credits WHERE rowid=3');
INSERT INTO undolog VALUES(18,'UPDATE order_matches SET id=''507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379_178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424'',tx0_index=3,tx0_hash=''507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379'',tx0_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx1_index=4,tx1_hash=''178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424'',tx1_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',forward_asset=''BTC'',forward_quantity=50000000,backward_asset=''XCP'',backward_quantity=100000000,tx0_block_index=310002,tx1_block_index=310003,block_index=310003,tx0_expiration=10,tx1_expiration=10,match_expire_index=310023,fee_paid=857142,status=''pending'' WHERE rowid=1');
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
INSERT INTO undolog VALUES(60,'UPDATE orders SET tx_index=3,tx_hash=''507fdaba6d6173642277fa3744428fa9aed27c8dc16612aae6b2ad3a9fbb5379'',block_index=310002,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''BTC'',give_quantity=50000000,give_remaining=0,get_asset=''XCP'',get_quantity=100000000,get_remaining=0,expiration=10,expire_index=310012,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=142858,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(61,'DELETE FROM order_expirations WHERE rowid=3');
INSERT INTO undolog VALUES(62,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92794539176 WHERE rowid=1');
INSERT INTO undolog VALUES(63,'DELETE FROM debits WHERE rowid=12');
INSERT INTO undolog VALUES(64,'DELETE FROM bets WHERE rowid=2');
INSERT INTO undolog VALUES(65,'UPDATE bets SET tx_index=13,tx_hash=''72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64'',block_index=310012,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=0,deadline=1388000100,wager_quantity=50000000,wager_remaining=50000000,counterwager_quantity=25000000,counterwager_remaining=25000000,target_value=0.0,leverage=15120,expiration=10,expire_index=310022,fee_fraction_int=5000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(66,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92769539176 WHERE rowid=1');
INSERT INTO undolog VALUES(67,'DELETE FROM credits WHERE rowid=10');
INSERT INTO undolog VALUES(68,'UPDATE bets SET tx_index=14,tx_hash=''f6a6834a51451c205353d5d36950b48b7deebca3ea339b31a66e8204163cecfc'',block_index=310013,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=1,deadline=1388000100,wager_quantity=25000000,wager_remaining=25000000,counterwager_quantity=41500000,counterwager_remaining=41500000,target_value=0.0,leverage=15120,expiration=10,expire_index=310023,fee_fraction_int=5000000,status=''open'' WHERE rowid=2');
INSERT INTO undolog VALUES(69,'DELETE FROM bet_matches WHERE rowid=1');
INSERT INTO undolog VALUES(70,'UPDATE orders SET tx_index=4,tx_hash=''178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424'',block_index=310003,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''XCP'',give_quantity=105000000,give_remaining=5000000,get_asset=''BTC'',get_quantity=50000000,get_remaining=0,expiration=10,expire_index=310013,fee_required=900000,fee_required_remaining=42858,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=2');
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
INSERT INTO undolog VALUES(82,'UPDATE bets SET tx_index=15,tx_hash=''9b3799f2ce6c01f8fc8d54dd43b103b8ab992ae345d7af234b67bd8c0aa4d9b2'',block_index=310014,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=0,deadline=1388000100,wager_quantity=150000000,wager_remaining=150000000,counterwager_quantity=350000000,counterwager_remaining=350000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310024,fee_fraction_int=5000000,status=''open'' WHERE rowid=3');
INSERT INTO undolog VALUES(83,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(84,'DELETE FROM credits WHERE rowid=13');
INSERT INTO undolog VALUES(85,'UPDATE bets SET tx_index=16,tx_hash=''97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d'',block_index=310015,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=1,deadline=1388000100,wager_quantity=350000000,wager_remaining=350000000,counterwager_quantity=150000000,counterwager_remaining=150000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310025,fee_fraction_int=5000000,status=''open'' WHERE rowid=4');
INSERT INTO undolog VALUES(86,'DELETE FROM bet_matches WHERE rowid=2');
INSERT INTO undolog VALUES(87,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(88,'DELETE FROM debits WHERE rowid=15');
INSERT INTO undolog VALUES(89,'DELETE FROM bets WHERE rowid=5');
INSERT INTO undolog VALUES(90,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91528789176 WHERE rowid=1');
INSERT INTO undolog VALUES(91,'DELETE FROM debits WHERE rowid=16');
INSERT INTO undolog VALUES(92,'DELETE FROM bets WHERE rowid=6');
INSERT INTO undolog VALUES(93,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(94,'DELETE FROM credits WHERE rowid=14');
INSERT INTO undolog VALUES(95,'UPDATE bets SET tx_index=17,tx_hash=''5fae745825197093b0f1efcdffc79d58a6f609e1b794c537faa555c01c270f13'',block_index=310016,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=2,deadline=1388000200,wager_quantity=750000000,wager_remaining=750000000,counterwager_quantity=650000000,counterwager_remaining=650000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310026,fee_fraction_int=5000000,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(96,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(97,'DELETE FROM credits WHERE rowid=15');
INSERT INTO undolog VALUES(98,'UPDATE bets SET tx_index=18,tx_hash=''ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a'',block_index=310017,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=3,deadline=1388000200,wager_quantity=650000000,wager_remaining=650000000,counterwager_quantity=750000000,counterwager_remaining=750000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310027,fee_fraction_int=5000000,status=''open'' WHERE rowid=6');
INSERT INTO undolog VALUES(99,'DELETE FROM bet_matches WHERE rowid=3');
INSERT INTO undolog VALUES(100,'DELETE FROM broadcasts WHERE rowid=19');
INSERT INTO undolog VALUES(101,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(102,'DELETE FROM credits WHERE rowid=16');
INSERT INTO undolog VALUES(103,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90937926676 WHERE rowid=1');
INSERT INTO undolog VALUES(104,'DELETE FROM credits WHERE rowid=17');
INSERT INTO undolog VALUES(105,'DELETE FROM bet_match_resolutions WHERE rowid=1');
INSERT INTO undolog VALUES(106,'UPDATE bet_matches SET id=''72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64_f6a6834a51451c205353d5d36950b48b7deebca3ea339b31a66e8204163cecfc'',tx0_index=13,tx0_hash=''72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64'',tx0_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx1_index=14,tx1_hash=''f6a6834a51451c205353d5d36950b48b7deebca3ea339b31a66e8204163cecfc'',tx1_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=15120,forward_quantity=41500000,backward_quantity=20750000,tx0_block_index=310012,tx1_block_index=310013,block_index=310013,tx0_expiration=10,tx1_expiration=10,match_expire_index=310022,fee_fraction_int=5000000,status=''pending'' WHERE rowid=1');
INSERT INTO undolog VALUES(107,'DELETE FROM broadcasts WHERE rowid=20');
INSERT INTO undolog VALUES(108,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90941039176 WHERE rowid=1');
INSERT INTO undolog VALUES(109,'DELETE FROM credits WHERE rowid=18');
INSERT INTO undolog VALUES(110,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91100339176 WHERE rowid=1');
INSERT INTO undolog VALUES(111,'DELETE FROM credits WHERE rowid=19');
INSERT INTO undolog VALUES(112,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91416039176 WHERE rowid=1');
INSERT INTO undolog VALUES(113,'DELETE FROM credits WHERE rowid=20');
INSERT INTO undolog VALUES(114,'DELETE FROM bet_match_resolutions WHERE rowid=2');
INSERT INTO undolog VALUES(115,'UPDATE bet_matches SET id=''9b3799f2ce6c01f8fc8d54dd43b103b8ab992ae345d7af234b67bd8c0aa4d9b2_97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d'',tx0_index=15,tx0_hash=''9b3799f2ce6c01f8fc8d54dd43b103b8ab992ae345d7af234b67bd8c0aa4d9b2'',tx0_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx1_index=16,tx1_hash=''97ceb8c9190c4d2e7279cb2cbb1b1a3e119fd16949485299b549848a82b5084d'',tx1_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=5040,forward_quantity=150000000,backward_quantity=350000000,tx0_block_index=310014,tx1_block_index=310015,block_index=310015,tx0_expiration=10,tx1_expiration=10,match_expire_index=310024,fee_fraction_int=5000000,status=''pending'' WHERE rowid=2');
INSERT INTO undolog VALUES(116,'DELETE FROM broadcasts WHERE rowid=21');
INSERT INTO undolog VALUES(117,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91441039176 WHERE rowid=1');
INSERT INTO undolog VALUES(118,'DELETE FROM credits WHERE rowid=21');
INSERT INTO undolog VALUES(119,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92771039176 WHERE rowid=1');
INSERT INTO undolog VALUES(120,'DELETE FROM credits WHERE rowid=22');
INSERT INTO undolog VALUES(121,'DELETE FROM bet_match_resolutions WHERE rowid=3');
INSERT INTO undolog VALUES(122,'UPDATE bet_matches SET id=''5fae745825197093b0f1efcdffc79d58a6f609e1b794c537faa555c01c270f13_ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a'',tx0_index=17,tx0_hash=''5fae745825197093b0f1efcdffc79d58a6f609e1b794c537faa555c01c270f13'',tx0_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx1_index=18,tx1_hash=''ddcec6a946c0429ec23ff34491647a1f8fda8496974f628154855445bb3fbf4a'',tx1_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx0_bet_type=2,tx1_bet_type=3,feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',initial_value=100,deadline=1388000200,target_value=1.0,leverage=5040,forward_quantity=750000000,backward_quantity=650000000,tx0_block_index=310016,tx1_block_index=310017,block_index=310017,tx0_expiration=10,tx1_expiration=10,match_expire_index=310026,fee_fraction_int=5000000,status=''pending'' WHERE rowid=3');
INSERT INTO undolog VALUES(123,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''BBBB'',quantity=996000000 WHERE rowid=3');
INSERT INTO undolog VALUES(124,'DELETE FROM debits WHERE rowid=17');
INSERT INTO undolog VALUES(125,'DELETE FROM orders WHERE rowid=3');
INSERT INTO undolog VALUES(126,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92841039176 WHERE rowid=1');
INSERT INTO undolog VALUES(127,'DELETE FROM credits WHERE rowid=23');
INSERT INTO undolog VALUES(128,'DELETE FROM burns WHERE rowid=23');
INSERT INTO undolog VALUES(129,'UPDATE bets SET tx_index=13,tx_hash=''72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64'',block_index=310012,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=0,deadline=1388000100,wager_quantity=50000000,wager_remaining=8500000,counterwager_quantity=25000000,counterwager_remaining=4250000,target_value=0.0,leverage=15120,expiration=10,expire_index=310022,fee_fraction_int=5000000,status=''open'' WHERE rowid=1');
INSERT INTO undolog VALUES(130,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=149840926438 WHERE rowid=1');
INSERT INTO undolog VALUES(131,'DELETE FROM credits WHERE rowid=24');
INSERT INTO undolog VALUES(132,'DELETE FROM bet_expirations WHERE rowid=13');
INSERT INTO undolog VALUES(133,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''BBBC'',quantity=99474 WHERE rowid=4');
INSERT INTO undolog VALUES(134,'DELETE FROM debits WHERE rowid=18');
INSERT INTO undolog VALUES(135,'UPDATE balances SET address=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',asset=''BBBC'',quantity=526 WHERE rowid=6');
INSERT INTO undolog VALUES(136,'DELETE FROM credits WHERE rowid=25');
INSERT INTO undolog VALUES(137,'DELETE FROM sends WHERE rowid=24');
INSERT INTO undolog VALUES(138,'UPDATE orders SET tx_index=22,tx_hash=''6f890013e2d78bfc0201e4570d2c778487a1b63eb5209f22dd9f89058cc5ac58'',block_index=310021,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''BBBB'',give_quantity=50000000,give_remaining=50000000,get_asset=''XCP'',get_quantity=50000000,get_remaining=50000000,expiration=10,expire_index=310031,fee_required=0,fee_required_remaining=0,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=3');
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
