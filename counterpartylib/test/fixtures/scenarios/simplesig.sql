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
INSERT INTO bet_match_resolutions VALUES('72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64_d966330f429d59a82c6da65f61ef3768d58973f15fa899e9d1c9a981b4fa4bda',1,310018,'0',0,59137500,NULL,NULL,3112500);
INSERT INTO bet_match_resolutions VALUES('f96724f9dcd53ea256e509e6dad698cbc40fc910fac1b598135751c479177f93_c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6',1,310019,'1',159300000,315700000,NULL,NULL,25000000);
INSERT INTO bet_match_resolutions VALUES('a07db7528b9e94adcfb511d01128d3fc7ab19b90b36aebeba8033744b54ba4ab_622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3',5,310020,NULL,NULL,NULL,'NotEqual',1330000000,70000000);
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
INSERT INTO bet_matches VALUES('72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64_d966330f429d59a82c6da65f61ef3768d58973f15fa899e9d1c9a981b4fa4bda',13,'72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',14,'d966330f429d59a82c6da65f61ef3768d58973f15fa899e9d1c9a981b4fa4bda','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',100,1388000100,0.0,15120,41500000,20750000,310012,310013,310013,10,10,310022,5000000,'settled: liquidated for bear');
INSERT INTO bet_matches VALUES('f96724f9dcd53ea256e509e6dad698cbc40fc910fac1b598135751c479177f93_c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6',15,'f96724f9dcd53ea256e509e6dad698cbc40fc910fac1b598135751c479177f93','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',16,'c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',100,1388000100,0.0,5040,150000000,350000000,310014,310015,310015,10,10,310024,5000000,'settled');
INSERT INTO bet_matches VALUES('a07db7528b9e94adcfb511d01128d3fc7ab19b90b36aebeba8033744b54ba4ab_622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3',17,'a07db7528b9e94adcfb511d01128d3fc7ab19b90b36aebeba8033744b54ba4ab','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',18,'622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',2,3,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',100,1388000200,1.0,5040,750000000,650000000,310016,310017,310017,10,10,310026,5000000,'settled: for notequal');
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
INSERT INTO bets VALUES(14,'d966330f429d59a82c6da65f61ef3768d58973f15fa899e9d1c9a981b4fa4bda',310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000100,25000000,4250000,41500000,0,0.0,15120,10,310023,5000000,'filled');
INSERT INTO bets VALUES(15,'f96724f9dcd53ea256e509e6dad698cbc40fc910fac1b598135751c479177f93',310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1388000100,150000000,0,350000000,0,0.0,5040,10,310024,5000000,'filled');
INSERT INTO bets VALUES(16,'c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6',310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000100,350000000,0,150000000,0,0.0,5040,10,310025,5000000,'filled');
INSERT INTO bets VALUES(17,'a07db7528b9e94adcfb511d01128d3fc7ab19b90b36aebeba8033744b54ba4ab',310016,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',2,1388000200,750000000,0,650000000,0,1.0,5040,10,310026,5000000,'filled');
INSERT INTO bets VALUES(18,'622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3',310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',3,1388000200,650000000,0,750000000,0,1.0,5040,10,310027,5000000,'filled');
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
INSERT INTO blocks VALUES(310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,NULL,NULL,'cf0ea1d313e22ba5f413075b88e07dffc5c00e59f95eeb6d6dec935bd77f5ae4','f06c23e6040a063ed59693baa0d63492dce64e1debc7455b22f5535c9dfbdc67','935966a4190449faefd40145735a17c5733fcd4f80d81fb1b0368cf8c2507bb1');
INSERT INTO blocks VALUES(310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,NULL,NULL,'bdf1308701712d94da26f53fef4c440ea2fb7b0ef7361f424ba9263e747272bd','9e0d5e4fc106a6878353270467110206677b996e9cd5f9113aec59fde786cb4b','79fe346e58a7d346cb90b8be3404f8eadb410be2a4f8ba338134587847d76e74');
INSERT INTO blocks VALUES(310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,NULL,NULL,'cf830f949715ebeac09d4441878f60ac04d691c09d6c25c62a0d30fb5886cba9','fe5dc7935d266f1fed9e32780bb64a53d5e915366e79f72e09c69779a9b960d2','81e07c6aa88091db4e9470f0059a583df4162d12f9e236a2b6e6d4a4db874978');
INSERT INTO blocks VALUES(310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,NULL,NULL,'e881a675a38c4649cd44e6406ddc494996c761671bc349dcdea1de430a84258d','6e07c88646bff4efc740c3f89b6c047c9108ab023a33c9fb0db97094a5779aba','86f08d968c5822f3848d69a39d7e0cae1a85ecd07d2b56b001a7cc4846d48d10');
INSERT INTO blocks VALUES(310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,NULL,NULL,'13e0c6276f297ff1ca77705f1b18d807ca22f53735fba52f4f5c3766dc4b04e8','e5315b5cf4563080a36b1af9087e795c16f931b08a7de73feeb17453d11b4e36','0cae6a2fdc7cd08c81a0f0f9a9f91b304f5ae81850935ddc9fe73aa4c879e485');
INSERT INTO blocks VALUES(310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,NULL,NULL,'765896f532b411af9f889687a750d44414296c20002f3e2abed9551a6822937d','5846440bcc5d4269ce9dab206cf09f22338fd4fe12e38fec802225c75945d78a','1f575a287beada91f1ee7f69db6bf6992bc85c521a9ca38acafee35ab7679c38');
INSERT INTO blocks VALUES(310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,NULL,NULL,'853e3a8d39c4e8bdb36a0ec01a8d20f12335fcc00a00ac271e9d83be471d394f','c20213a509ff7d8684a8240ef3ff5a4c97b242f03573791cc84e8c34ca3e6bce','759434a5f80d4e92dc0157708667e89652aeb05be5d813a1f1d578f0145cf0c3');
INSERT INTO blocks VALUES(310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,NULL,NULL,'f2b2d250a94afa158f9ed84434c3ac7a0bfc97b4387e5e3c099afc95b8a6ad9c','0200a25ffb1ff9d9bdce14b56489bc35fd785406d84e9f28a4e04bbec212e35a','e50f23d06fe854bc184574609e82d341d223985958aa8fa64ec9226399337815');
INSERT INTO blocks VALUES(310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,NULL,NULL,'8c44f15f5606b6fe984a9fa7df8d7d5381fe87a6c8b634469804328885668569','c6cfc394523eb1850cfefeb3c72e9bd57f26c8ce994804cb82e3470b78a7e411','fe0a0fdc8b6cc67bce210db50bb9145fd6deed16424306819bcbdcaadd22b349');
INSERT INTO blocks VALUES(310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,NULL,NULL,'ba378e9192f290d3f9d3dd1e46aeef3a185bd5aff1be809c8974fca8dc142987','41df2e046f40c62b4066075b5f8ba56f472a7c533ffcdf6e2d6223176216abc1','4f4b25e0968ffaad88745cd1b24f550aa2e80be0677a91c9d166d11b99405af3');
INSERT INTO blocks VALUES(310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,NULL,NULL,'64f78f9eedce2931aedfe413b4f4bdeb728752e1c897e0bd44c7db665976a723','86c7ee6c82354134ef2a1389d6c4f0fdc432062d220ebd8e89b848a69e8c7368','917ef84e78a64aa44dd0369e4a75e1fe84f95c8c127d3971c5020557abd4da6e');
INSERT INTO blocks VALUES(310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,NULL,NULL,'671a1b4e1edd1f96dcfcc96d521fb2125ae5b9d2d01a76fc66686b7ed20c5662','a0236795a2f30215b50906324d3b5cc679c1c0b49172f8c6810b2179b1ce71fe','2ca08c3dcf516d956bdad436e030def5673042c7f85fe21f2a9fe1720bcef21b');
INSERT INTO blocks VALUES(310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,NULL,NULL,'1f5b502c341699b5a59b87566c0fc02b7db5c657919f014e41a00303aa53efc8','3d262297b4c7e9b36295db34b99aa0952670380336f58362c21c197ca400c123','9da86daf95da6d303078a2383f93bdfaf02ba59f99a8252473f9bd640d2c3a97');
INSERT INTO blocks VALUES(310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,NULL,NULL,'cd0cfff6de5dd4381301929c740015d5910339ba915a83eb4229ecb91ae84c17','455df8023ec0e6d643946d37ef013c3854c37bf8d28864fabe923329d4713bdb','41e9d76a3817fbb4c2c0a82cc0d8fed2d9ebe87fc5533a49862f90871022f0c6');
INSERT INTO blocks VALUES(310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,NULL,NULL,'5012d84065c7a39b5563f4fadeaf30670b47df3856f43d40fda74de663753e4e','7a9ecec87bdf7f4023f6689fde08cf282b6a08ed88a5cbd6a80b815a49ef2626','739be3e4239a0902870b00ed5a40d60e84942d2188608fbbcc35102cec93fd0c');
INSERT INTO blocks VALUES(310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,NULL,NULL,'0356494d376b2b65b9f4b066b9d2baf2ae90d82369b87914bb58a67927ced5af','740993c715f72ccb2736ce77df33915a86aaba477d72261040d50f92a02092e4','3252ca97f5f6b8e9527ed637b23e86099fb00f30a1cdd0509f907527f620ceeb');
INSERT INTO blocks VALUES(310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,NULL,NULL,'c90ff439bd04970ed9e6e25cbfce32160450925a37ba3360f40df8854529b52d','da34228bfd8ec828107aedb22fcf7bd6d29e73dc60fb5e15dae1d9313bd826fb','1cde33bf740f39ec25e5d45bca1717a25d3ec67fff648268705734fb13ea19bc');
INSERT INTO blocks VALUES(310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,NULL,NULL,'19cf18f708dab6a983a2642802deb38d25b6fc205ea663059a0569fa38bdaf8d','77a4bb1e1661ac05e30783469edd95bb50ec2069d45e4db5ea1136e1a544ae3b','2c90368b1c979b9862e349321f855cb362acbc02b751e9fa8405189c4b3fc6ca');
INSERT INTO blocks VALUES(310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,NULL,NULL,'d9ac565fbe7bf18c1d899dab8e0c98e070880e36fa51710382017d46ddf837cf','72a193dcdd722fb2f96edfcff97c57464e3fee80ae66ffe021c2f856dbfa5d78','a781966bb78d25fe34de9fd13107374070a0833fce196ece47fe044c24c5af01');
INSERT INTO blocks VALUES(310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,NULL,NULL,'b66661deef419a50557d171cc1bcae04f5bc260ed1f5ff56cf08ef39158617a1','ec9806d270ae82328799a53d687f0135d30d61b5e924827c98e74d5eb090d903','a217942d3b028a7e8851d3a9148d1c49b74aff261d6fa4d0daa9daa06d0409a9');
INSERT INTO blocks VALUES(310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,NULL,NULL,'57a6c53e41338011cb06cd60118961dcec0e800f62a2c4b1e9381c666319680f','6ffca1a70880422d58431f6b86c7b1b479ec8f0b7a56ddb8060491d1a650f8c0','a5af71ce315262fa7c8f2db6985650a98127163f2c90beb0fc9d645b6deadbc5');
INSERT INTO blocks VALUES(310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,NULL,NULL,'66c16af10125f298796da828f1a6c2b43123cda38e3dfc57ccc25b00f3da17f8','fd69fc15dd7ccbf475784217d1a8d02255385f7bd1accbaf5d85fdb6041c5fcb','b09087921fd88a0f3486a6b0d0ebb320e53bae7a457a078d7ac269bfdbb90562');
INSERT INTO blocks VALUES(310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,NULL,NULL,'43b6213cad601a389aed2a4e912be118dfab6cca5358d86bac03f4bee6765493','95e035972394ed0a3fb121448c05d13303792e00e78fd7b1a3c16083e414e51f','8acdc6dfe5291616663fad4a221e5da96df7e03a388575f87e65d1b294c4a656');
INSERT INTO blocks VALUES(310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,NULL,NULL,'8a9758963891bbfbdcb6515d8d3e49c941fedba7de82038776e9f8ed65e803c1','26c192d84a61141678896c4936b118b4b2125e5207261e6b47d6a7dcfb5c5e81','0504be50de090c927da77649ba470f7510045b95bd069755ae1bdda61d17ad39');
INSERT INTO blocks VALUES(310024,'b03042b4e18a222b4c8d1e9e1970d93e6e2a2d41686d227ff8ecf0a839223dc5',310024000,NULL,NULL,'cb034ab4a3e252fdfe9973a672e208295741a52634c9332b1501d612e0012e19','18e519d6255fa87eca9ec4ab2ff9cac574932fc4c7e564330a5a522277154318','be7b64f5001a77cc2e4371571d5c61406a3350aa479d6eef569888d743ebbe18');
INSERT INTO blocks VALUES(310025,'a872e560766832cc3b4f7f222228cb6db882ce3c54f6459f62c71d5cd6e90666',310025000,NULL,NULL,'5addc8253469d5c729cdffc1c637b75d9e8886a633d4406dedf2b1c16ba5b92a','c120da8806b8c87cd533434e42891e6e97eb831182773cf9cfeba0fcfaedb2ab','44d61a1d61f632beedbc0661b8c40b0984a1092002c2c7ac0a7d46b786c38cde');
INSERT INTO blocks VALUES(310026,'6c96350f6f2f05810f19a689de235eff975338587194a36a70dfd0fcd490941a',310026000,NULL,NULL,'8620bd0283c320330631185d1b2351718f174732bd099324a0880719cdfc18c7','4cc15f4dff81b57c8450db19a516dbaad70c1162efe9db1268b004e17fcf311c','03ff6675b104a73af75dd599b7f11670f5eae1d9253bba7a691fa7707a11092d');
INSERT INTO blocks VALUES(310027,'d7acfac66df393c4482a14c189742c0571b89442eb7f817b34415a560445699e',310027000,NULL,NULL,'96960e09478184f4f0ad38d1fc03f0c0240e58715a0a29745a6dc58c40003249','1d5c7d7753d018ccffb843bd918c81cd88c67441cd74e91775dac324f5349b23','d6172d3fdc5c44af844f6cf1e5de5eff13423db1defc498ca359e54d97689dc4');
INSERT INTO blocks VALUES(310028,'02409fcf8fa06dafcb7f11e38593181d9c42cc9d5e2ddc304d098f990bd9530b',310028000,NULL,NULL,'2f556d2528abe1c4e9d31f6ed70d400d94633d4dfb54c9a4f250e1b054f9a384','a4633797535b12dead2831944a1efe1fb346f966d488c0365b14b1756469da2e','e98cd43a417900aa3e9eb914e72066a476366ced12dc57c9752c62d3a9c07df1');
INSERT INTO blocks VALUES(310029,'3c739fa8b40c118d5547ea356ee8d10ee2898871907643ec02e5db9d00f03cc6',310029000,NULL,NULL,'be195b1f7b7b55dcefb83907d954736d4bf059a9e32055131efd16602d7761d6','09971541eabcd3d2b4ac0d67327c8be63fb4ebf4737eb94b8ea3fbafcadeb90a','1e1349331af4400b53d13e88d230ea14e17027085e711b7a98efca509bb574bd');
INSERT INTO blocks VALUES(310030,'d5071cddedf89765ee0fd58f209c1c7d669ba8ea66200a57587da8b189b9e4f5',310030000,NULL,NULL,'d3a25656dbb63eecf1c89820581fcab193d750f3a09ca8ab34a5008c8d89051d','c1e475392f72bb88165837a84a6dd9af656c155be5c81f9b6e8c003068db5200','a2288600cd7ecba37320ffeba4f3f515ad01df1110c5c448153382f4a0b1a8c0');
INSERT INTO blocks VALUES(310031,'0b02b10f41380fff27c543ea8891ecb845bf7a003ac5c87e15932aff3bfcf689',310031000,NULL,NULL,'0edb535f8c6a40062a86e4ea327cf7fb70310b6d55a6654d5a23e54498aa3159','51cf420663371f8211f03903fa823615c27a154ef86542a2f7ec7e75a2d0eddb','370e6b1289542b12bfd5a5fed9783d46943644a3c2d32b41cfc9afcbdad9ac9c');
INSERT INTO blocks VALUES(310032,'66346be81e6ba04544f2ae643b76c2b7b1383f038fc2636e02e49dc7ec144074',310032000,NULL,NULL,'a9208a1b7f782852d652e5089c6485744031176b4d285ea985bbc1df0ccf49c0','5138eb93aa9914a28112ef9fa4005d996dda5bba08786a9a8dc728966833682c','7261d0f0dd8f3cb8b83f9be4afe4c647e37038503c454bbb7371785a2c800442');
INSERT INTO blocks VALUES(310033,'999c65df9661f73e8c01f1da1afda09ac16788b72834f0ff5ea3d1464afb4707',310033000,NULL,NULL,'c8a973eb6bdd28dcab4f1b2a5e29e104944745e57a54e6d87b370aafb2e589f6','07a979003fbcb26557dfe5cf209641282821cbb5a542482defdf4c22776bc5a8','7051f189ad0c6a94e30e1b362fb9a50256d97fe5c13e1086f69c1be1e9cf466c');
INSERT INTO blocks VALUES(310034,'f552edd2e0a648230f3668e72ddf0ddfb1e8ac0f4c190f91b89c1a8c2e357208',310034000,NULL,NULL,'0d7b5809b7a5aa5ff854cfe141490a78c9b33e16f8102a8e804dbf0a0a8c0842','ed71ad3d3a6023890d4dc35209bd69cdcf71bf61dde70a6d129c378bef183588','9a338eea5c7d246392071a2a1227cf0fc4d3a9e8903a60452d3095ca46c9f61f');
INSERT INTO blocks VALUES(310035,'a13cbb016f3044207a46967a4ba1c87dab411f78c55c1179f2336653c2726ae2',310035000,NULL,NULL,'6b4c99289086445a7bf575110172a661c1cd37c418b70afd8ef3be0982041f5e','8ead56fbc3b80a396e52e9819bf095a1e7d462c51b2cd54202a107c09ee0473d','7bbe2c49156ccbc0ff33a87f739025128b2c8d165b9725986dd95a6b4bee7e0c');
INSERT INTO blocks VALUES(310036,'158648a98f1e1bd1875584ce8449eb15a4e91a99a923bbb24c4210135cef0c76',310036000,NULL,NULL,'f20b81389b2f4c9c9be4442b3c68f87da881406f1490637c7d93d63539155a7e','25290da6f7f8e2f37eeb6dfc5bf0544915c61068f7c266da501fcf87dae8b65b','623066f3de3e2ccf765a0c84cfefc6d4e9548066412fefcd74a9796aac04718d');
INSERT INTO blocks VALUES(310037,'563acfd6d991ce256d5655de2e9429975c8dceeb221e76d5ec6e9e24a2c27c07',310037000,NULL,NULL,'52d554e6b53b853066a3a8f931fc37779f3596c4388e277a9f66a95e001a09eb','c441c4509194de0fa7bacd345417bd70e1961cafb6cbcca11d74f82f532b407f','2311a53f9158d0d29c4e02933fc4d6e13b4eb1d57624ca0d66c25373c6eb07f3');
INSERT INTO blocks VALUES(310038,'b44b4cad12431c32df27940e18d51f63897c7472b70950d18454edfd640490b2',310038000,NULL,NULL,'08a949af614ff73a79313a5a949908b368efe1f8c131eeeb51ed610baf65ac46','b33ef62c1a72a5e707139b0ff92197c440f2f91ba78240441d8d61cb1785c7bb','a1a4b4d8f17db1759b56a56a1a421258075071a7a04866623174824c9e865644');
INSERT INTO blocks VALUES(310039,'5fa1ae9c5e8a599247458987b006ad3a57f686df1f7cc240bf119e911b56c347',310039000,NULL,NULL,'7ff8b2408ee1124a5ee573d31023660aabcdb21599bdcfb4a3bc1895d7910094','b638011cea9118e920b19039347ce10bef49afc8423cb8d10ad33d2127cc925a','f06e84cf8af50cedaa93bdcaf6e4e872a5a0ad62991c2b546f771b9c7439d5b8');
INSERT INTO blocks VALUES(310040,'7200ded406675453eadddfbb2d14c2a4526c7dc2b5de14bd48b29243df5e1aa3',310040000,NULL,NULL,'c687e753c01711e94cfcad1f16d2976a12ef5d6c3731c64db26f969c988fe7c3','772ea1c8971bac904e8b056e8def653305e4bc3336b44569a2f4c86f356b5c9f','5bbbbb65157f3e3e35807d7f941ce3c1c62c87d355994db75d1efd13a8bdd5df');
INSERT INTO blocks VALUES(310041,'5db592ff9ba5fac1e030cf22d6c13b70d330ba397f415340086ee7357143b359',310041000,NULL,NULL,'66f493ec8b5cf8140d1f627f008c50624d3069f56828df90286b53a2d6cbf47e','676dcd9dd03a540fd007331caac6d1ac107dd9d9bad6d435e88896fe571373fc','8e5feb6b77c011c0b89cd917d7d3b5ea3e9a8c1c7d93c2be778639ff5eeb6ebb');
INSERT INTO blocks VALUES(310042,'826fd4701ef2824e9559b069517cd3cb990aff6a4690830f78fc845ab77fa3e4',310042000,NULL,NULL,'33acd319bde452aa81b589435a31ee3add742870a928ef2c15a7a447b4b4e0fa','ac8fbf38ee632f1ceac563bc7a875553af3f30f1e6428ecd87e9977f5878f808','c5d725e263251d04f4bca6c90b02a0efcdadb40f841d9fa1f26e6b1386c14314');
INSERT INTO blocks VALUES(310043,'2254a12ada208f1dd57bc17547ecaf3c44720323c47bc7d4b1262477cb7f3c51',310043000,NULL,NULL,'83997825aa2597adb0292e265f01e937f621cc75d8cc18e23a4bd0c1fb0920c7','ccdb9c1c0a78ff2e68ce745710dde4186fd28fad9d0b22de76969b4a0bf9a7c4','1c43bf43a4eb6e9f43b71e111534129f41d15830e4edd36987ecd60578667511');
INSERT INTO blocks VALUES(310044,'3346d24118d8af0b3c6bcc42f8b85792e7a2e7036ebf6e4c25f4f6723c78e46b',310044000,NULL,NULL,'9890bca86442f329b2abf1b3bbf4d94e8ab54d10dfa7823a53f02fcfef030d88','67ca4856af7f27e78ae6c4e70e44f196aa00125b130d7bb0528d44928fd48aa3','5117f418dd58ad574742a1d51450dd78d874fd91feb8f78ce3f5fd294558248c');
INSERT INTO blocks VALUES(310045,'7bba0ab243839e91ad1a45a762bf074011f8a9883074d68203c6d1b46fffde98',310045000,NULL,NULL,'a909f658a8f405ef1f5cd8bbab03cbd865235544ae1c2f4dc20e2a4393181efc','70893b2af376f907a77835b55f45fae412f3643732e4e0e202fa5812cdf50a6f','5f3fe84a153aebc6eaf86f8e042ecddab52e75c59b3918cc864c3b6df0bbf839');
INSERT INTO blocks VALUES(310046,'47db6788c38f2d6d712764979e41346b55e78cbb4969e0ef5c4336faf18993a6',310046000,NULL,NULL,'713d2ccc66a1aa7797ea9b6af18b04245478c7582a8aee76cf2c7f3f3060df3a','34d099791de06a7c44b91f0b5dc9083a7fbad9f2f18896052c812662c94e8547','1dd6b1ba49395c38c67329f15c0b5c9d32994354169ee8f18394be3c3df3ce1f');
INSERT INTO blocks VALUES(310047,'a9ccabcc2a098a7d25e4ab8bda7c4e66807eefa42e29890dcd88149a10de7075',310047000,NULL,NULL,'534500ae61a04841771193d57384d27b54fa2bb92c0698beaa46509b3d39eb1c','6f6f236697288573c2344e9515e539372f96c0583798aec90acd8e733ae26743','4a3a2c84164e0d056848fb0d3f6e5d5c0db557777fb8d4192b2ba94961c60071');
INSERT INTO blocks VALUES(310048,'610bf3935a85b05a98556c55493c6de45bed4d7b3b6c8553a984718765796309',310048000,NULL,NULL,'48c8e5d9ab1887f092731ba2881a330d22d4f03f601dccc096fa5147042a3d55','3148b241c2a9b4f86a518e5ce1b0bf706c3727ecc32f2f6232caa03baa94abca','574425f1760e154c43dbcb669964c28058ffac541c5d553dd566494eb27a6acf');
INSERT INTO blocks VALUES(310049,'4ad2761923ad49ad2b283b640f1832522a2a5d6964486b21591b71df6b33be3c',310049000,NULL,NULL,'6c5ec3d2b7d8a724175559db977cb9ab78eecd39b9239688b30d6d3350cb01fe','6c9b8a266498980b895ba6a6aed1ab195cc20822325b765b20ce18de5e183f11','c93a3a1d6bd1dd3e24a51769fb2ab5a2bbc569cbe9ed0e629ec3ad5a6eb9ff87');
INSERT INTO blocks VALUES(310050,'8cfeb60a14a4cec6e9be13d699694d49007d82a31065a17890383e262071e348',310050000,NULL,NULL,'817dc86594b3820de76f1d2bc2400d702475d558d6ee5bef4313fc154bbdaca2','0facef3ab27c6ac4e8a3ef76fb2a60b6613a99e0979bd43ab0b15f98d7b48830','ad828d64050f9edd600dfdc111bbfc11d2058c173c7414011556d54d8960151d');
INSERT INTO blocks VALUES(310051,'b53c90385dd808306601350920c6af4beb717518493fd23b5c730eea078f33e6',310051000,NULL,NULL,'00916e6bac2f648f953c8d6dff21438a6ec53ad198b33f90667e8d4564e00e78','bef2a07cb6f48dacbd1bb3254b189a464ad3a761a79f299d5eb5f5c6e5248a73','696373e1f6da23f1fbdcbf94aa74373602d232930aa41990cc3e735f6ae8fe60');
INSERT INTO blocks VALUES(310052,'0acdacf4e4b6fca756479cb055191b367b1fa433aa558956f5f08fa5b7b394e2',310052000,NULL,NULL,'959df962b9bc7ef215f1530b886613404adaf81552d6eeb4b1401ea265ad5f4f','04fe372f4cf57c1e0832870c80cc20cbe6508ceb9d898836d71ab050dcc031ba','db73f096925b3521a32fd98d27e0e769161c0396e9f743619300a61bf38e7fba');
INSERT INTO blocks VALUES(310053,'68348f01b6dc49b2cb30fe92ac43e527aa90d859093d3bf7cd695c64d2ef744f',310053000,NULL,NULL,'d76b639ebddd434e5269de084de0b502e7f0eaff71b4e99de2d4ebdd1fc61380','34a907645ba1a57623912fb6c957a24e4185e25c13358cc12aa76c14884fa0c3','e5d457090954508e873738a403cb63f207c3b9e6f0f0fd0047d4a30935161296');
INSERT INTO blocks VALUES(310054,'a8b5f253df293037e49b998675620d5477445c51d5ec66596e023282bb9cd305',310054000,NULL,NULL,'525e8cabfc993080d128faf38a5e5c9e9afa61423a5f20a90d68cdcacc96b59b','478474854acb29e38f67b675f2f2901bf0f8d73d3cb6e474cfce4699945dd478','3f49fd22961dcf2a778fe27a219c4f9764342f34f2c611cc129d4d8bac93acd7');
INSERT INTO blocks VALUES(310055,'4b069152e2dc82e96ed8a3c3547c162e8c3aceeb2a4ac07972f8321a535b9356',310055000,NULL,NULL,'155ffdc74a2077a3da7d5c068833468c7d0758dfb525a799f910cdb1543beadb','d59a205914b4dc03e17ed35d9fdbbce2f4b9ef80c181d5df112e7bfa383632a8','5436aaec55569bc08288426b71885f7a70a423d8d56fbeda65fcf7f7914a0782');
INSERT INTO blocks VALUES(310056,'7603eaed418971b745256742f9d2ba70b2c2b2f69f61de6cc70e61ce0336f9d3',310056000,NULL,NULL,'4f6fe786e34af90927bcd888b4b2a8fc69d3ccdfe4c4bb37edb2007901ce234a','c2f0edf94964cbffde3c57612305f60ca1a59ee6932a94ac468ccdd8cf90e04c','668c0a97cb007742f0eaeec8067e3f3f9f81a62ea11e580990f875113bd714b6');
INSERT INTO blocks VALUES(310057,'4a5fdc84f2d66ecb6ee3e3646aad20751ce8694e64e348d3c8aab09d33a3e411',310057000,NULL,NULL,'30978d87fd8e32d9d27c92a0d4ca19d179b515ed95410fa96bf496b4cd8aa5e2','711560031ecaaaece3f404363611233f3474d8ae1dbcc6a448c97a1048bfdf84','e5373355ba0d4e7a5db1e0f52875e05f4ec548f33ca618cb3c23d93f59282346');
INSERT INTO blocks VALUES(310058,'a6eef3089896f0cae0bfe9423392e45c48f4efe4310b14d8cfbdb1fea613635f',310058000,NULL,NULL,'a0760bc5d2f04b381cc46aca84aa3788e8e3fbc833379a26ae812807d3a04fc5','36008695ca99f04dbda002f67fc0a9dc62c7e6cb8c4b9a80e3af875b84a63b4b','b8616bd99954132c6a76956869ab9bbedc403743f14bf5dcb889006c185dbc92');
INSERT INTO blocks VALUES(310059,'ab505de874c43f97c90be1c26a769e6c5cb140405c993b4a6cc7afc795f156a9',310059000,NULL,NULL,'26dcef9e54b1a34b6024f8402ddebb6e9449cd90c270e3db75354a001484b1a1','ed9aadd5bf453e0235cfd911c1cd3553627bbe1d25eb1a1aac497b890967ebf2','bfea09a87c3a78a876f5b2a4daf3232870869ca8ca24ae5eb3c1318e03e11010');
INSERT INTO blocks VALUES(310060,'974ad5fbef621e0a38eab811608dc9afaf10c8ecc85fed913075ba1a145e889b',310060000,NULL,NULL,'810ebcdb63a08af5a26d1fd4e7a3604afd03bd06ff620d6a86c665e1c81116d2','74ea1bc66471867bce9da35809b64fb3c1a90791bbf0320533027b4d12e6d596','0a56e68961158876e2a6790d0bfb376efda9deb9a8388369ebd5a3f0c7ad63da');
INSERT INTO blocks VALUES(310061,'35d267d21ad386e7b7632292af1c422b0310dde7ca49a82f9577525a29c138cf',310061000,NULL,NULL,'1edfc24d186c7e7267b11c03b0a29e57926e9ab25f668231a18a499cbd08c702','6a6cdbcf5d55319550e83c590715f61fa2daddbe10e122bcb976e5fd2032e4f7','36677c48fb9d531c6f217e17e87d27af977582e12ef2c6ad1e6a9513c1f98e1a');
INSERT INTO blocks VALUES(310062,'b31a0054145319ef9de8c1cb19df5bcf4dc8a1ece20053aa494e5d3a00a2852f',310062000,NULL,NULL,'b0de9503f019c9548a97bd198e6b1b58b57d6a7c231ace2d72adb0421b29e9b7','33f2551a7d712853e8402c691537e9fadc82d2d6a0c14886ace25b94ba354db5','b306dc776f8531146eb2047b19359f1cd9d9a9827b657ad96603acffb995bb3c');
INSERT INTO blocks VALUES(310063,'0cbcbcd5b7f2dc288e3a34eab3d4212463a5a56e886804fb4f9f1cf929eadebe',310063000,NULL,NULL,'62e41caff168eb4b15eb67ab2130510ba3f17ac186f8516cf5b5c6f168988345','586705bb63a3a743c1c473bb02f37de2e253f2939cad9b965643c152a3121fae','613146a6110dfdec2715aa593d8931d978ca3415489935ced3ab43225a2dd959');
INSERT INTO blocks VALUES(310064,'e2db8065a195e85cde9ddb868a17d39893a60fb2b1255aa5f0c88729de7cbf30',310064000,NULL,NULL,'a444b1535d27bb2917478019c4c59abf9474e87128f9ec1e44c20eea1f014f3c','b86dfdc6ccee141f4f12ce78a089f6faec4db8ab029f08b17c9b8215a7936e6c','c198617a304ace8d70bde8729f72a41b3d4d0020e043ce87104e964684e8f074');
INSERT INTO blocks VALUES(310065,'8a7bc7a77c831ac4fd11b8a9d22d1b6a0661b07cef05c2e600c7fb683b861d2a',310065000,NULL,NULL,'0ad978671f587f99e5e1c1b6f68ac3d18bb03a3bd7ea9afb63590bcef25160c8','7db9eb05067f7742a1c08189eb35729a7574df813d90f13d25f52310cc8eaa79','1b553b1cebb0e38907df6f7ace22006aac99cc00f8bb6b0f9a735121e77289f1');
INSERT INTO blocks VALUES(310066,'b6959be51eb084747d301f7ccaf9e75f2292c9404633b1532e3692659939430d',310066000,NULL,NULL,'a6bb36829770b24fa0b960b85566a0138360a60b52cec62d94d7df8cb0b8f8b4','14cc4112a7a5c34f96d9ff1b76514a29ce201a477ca57a86bd28187684d341fb','bf28dcb565ace45a9f4f7aaa6983b40e3235a9d0764f59c7a70409e7e865f577');
INSERT INTO blocks VALUES(310067,'8b08eae98d7193c9c01863fac6effb9162bda010daeacf9e0347112f233b8577',310067000,NULL,NULL,'9b8ceda9b170429d8b9ed517f0db95487b3058397e20d7e786577c8e46b389b8','90f776964db4605fd29d3e978c1ac830b138f54c10dda8fa9e9ed8aaa5c5e27d','129bf6fd60e183a94e7419a6908311843a67a292a45f5f9d46d667c259bdf2e0');
INSERT INTO blocks VALUES(310068,'9280e7297ef6313341bc81787a36acfc9af58f83a415afff5e3154f126cf52b5',310068000,NULL,NULL,'cee2e41baf86f1af24d555e9ab4a0c023b5f1ab2b054707d4434b4f60d31862a','9872572cac76df3e3db87dd285de26610387deea16dea4ab1d1e39f49f63a144','e6b2b6e6cd2beb453d239cb8c37b12d8fc893a2b56ccb38e9023b4de74cf74fc');
INSERT INTO blocks VALUES(310069,'486351f0655bf594ffaab1980cff17353b640b63e9c27239109addece189a6f7',310069000,NULL,NULL,'cbfd7ff728f05ba3f1db5972f1449618a79d3fd0d76bf7fe990aed2eb2316a38','7b78df8bad94a19a9b4ab24dd0a4c0405fe9d42169d184c7bc09b45eec53131d','28d588c4ebaa736e2aada22b563cc778c1b10fa0ed629d9c42d17475698baa3b');
INSERT INTO blocks VALUES(310070,'8739e99f4dee8bebf1332f37f49a125348b40b93b74fe35579dd52bfba4fa7e5',310070000,NULL,NULL,'9af85cd995c83b5a5f0cac66351cabdf9dc9faecfee080638fc76019663faaa6','07e77b25c549e8e4a425696f5c5b57caa2b818830b37d6c96becea8478541749','44acff01abd6b18077c2d9d70228a6dae568b2a139bfde14e93a474eade2ebf7');
INSERT INTO blocks VALUES(310071,'7a099aa1bba0ead577f1e44f35263a1f115ed6a868c98d4dd71609072ae7f80b',310071000,NULL,NULL,'a3c547e84db6b29630b87fa566e37796e0632ba616dd6d521d558632c3b55370','bb892d400f0edc774fe66eb1858fb34d7d70dc7b63b8ac1c338841345d13db58','d5e6f5070420fb9384b42ade627151b29c7e52df384284800866b2f1be9282ec');
INSERT INTO blocks VALUES(310072,'7b17ecedc07552551b8129e068ae67cb176ca766ea3f6df74b597a94e3a7fc8a',310072000,NULL,NULL,'a0170d8a72a0f8642c0863899bf034e754596e3fd8ddffefa91e7e9a7addf944','c18955fa68e579ec520bc0d89968865e3b263cfe90a2b0c3256985f1f0860eb1','43c3cf62694f71adb1c9beefa5595ac5e06943de4dfc446365d20ba3072ad521');
INSERT INTO blocks VALUES(310073,'ee0fe3cc9b3a48a2746b6090b63b442b97ea6055d48edcf4b2288396764c6943',310073000,NULL,NULL,'e0179a21342fcf35fa169567f1ef35bd6b0b1b048a98e90c049fdf3ee58e9da4','66d7459e7ef6726f23fa9001a234d059807be26e4c8f8fcae66cc8acfac5e4fd','e54428151703354930c13c004ad9435604f6dc219fb4a06d8ffb0bc17ec40758');
INSERT INTO blocks VALUES(310074,'ceab38dfde01f711a187601731ad575d67cfe0b7dbc61dcd4f15baaef72089fb',310074000,NULL,NULL,'8855ace296b0b078d90aa24fcd30ca9f9cccf9d3961f3dba4985a3ff187a02ac','9d79173f509ff3627ec6cd18f285e9b631a82c7a1e4ef5502b6d0e1c42d0996b','669e40d3fb64326a556321cab85790d500eb8cb14efe6d8940df35b1da4792e3');
INSERT INTO blocks VALUES(310075,'ef547198c6e36d829f117cfd7077ccde45158e3c545152225fa24dba7a26847b',310075000,NULL,NULL,'bde3a6c6cc31b96d58f466d3ce0361cc6366c8c239778f21b696d4063cf6d89e','dfdbfa63a0dcea523bf78d271a4854036145774d6def1ee6a26368d08f926a9a','714895cb46bae146ba80046689c20d17b0427070843d6ffc785ed1621de9d337');
INSERT INTO blocks VALUES(310076,'3b0499c2e8e8f0252c7288d4ecf66efc426ca37aad3524424d14c8bc6f8b0d92',310076000,NULL,NULL,'f562851b32a7005ee02b9e2491c0195dddce451e8fecb428209d087e69345303','88ff1424a811cb718fd035f1eabbb0d11abd4fee6e96f671c821b065a52c5fd8','eada4c6daf1a84389502d8f11ac07383e5f92ce616242cf3d1f6aebf19d33a26');
INSERT INTO blocks VALUES(310077,'d2adeefa9024ab3ff2822bc36acf19b6c647cea118cf15b86c6bc00c3322e7dd',310077000,NULL,NULL,'996cda7b65e623747deef936d61491cedd0159f44faa1e3536de1b6d6c474097','8585f89e5322381bce2218dd97f57dd3bd2ae3ba7da5ac5ab36890e6c679d0fc','95e7a2b857d1aba407ced549d4385f1718730403849b652a41f6c23f71ce3574');
INSERT INTO blocks VALUES(310078,'f6c17115ef0efe489c562bcda4615892b4d4b39db0c9791fe193d4922bd82cd6',310078000,NULL,NULL,'c8286f73cc3a070f4251b7c59bb485e611437a1916fd39ffac831dc78df54ecd','5ef4d5c2b6a68ea801e1ebf04de0910d39b4953df79293897c8ee95b19b236ba','fa687cd0a984638644a5f0ae7135f1f53e4ff9142f075f1cb9530e2f207a013d');
INSERT INTO blocks VALUES(310079,'f2fbd2074d804e631db44cb0fb2e1db3fdc367e439c21ffc40d73104c4d7069c',310079000,NULL,NULL,'ef9dab42700918027fac849f2088d2248a6291dc7bc24be583b556f37739631b','2d5db5fe26b2a2be743ef1773dddf5b754fd2eb291c53bb433229a64c3dc2ebd','af4509bc59823b0651bd955d97b96ffce4da8ef9b942a54e2695cb63f3af59d3');
INSERT INTO blocks VALUES(310080,'42943b914d9c367000a78b78a544cc4b84b1df838aadde33fe730964a89a3a6c',310080000,NULL,NULL,'c6bbc52f1e8f907b2d66378f4352f41ae3d354985aaab5f16d737d75a7e6b1d8','db60c764230f202aafb79f43ed58c74c1279257d35e49c70d43b8917c4934bc7','bd6628ebe16b46c5b97cea54de70675a6f279d7f45bd37c9726bc0028c99e81c');
INSERT INTO blocks VALUES(310081,'6554f9d307976249e7b7e260e08046b3b55d318f8b6af627fed5be3063f123c4',310081000,NULL,NULL,'66f7b7ff8f0217ed62938a5931d4a6a232546e5d58e09dfd3ba5a792c35fa560','9db19aa996ce1bbdfbe930e280d562b6a1674a9e258cd679052a885c8f550e93','cbbfe6c6684c7f238d14e7a21785087ee1d95ca6deefb92732706922d990e071');
INSERT INTO blocks VALUES(310082,'4f1ef91b1dcd575f8ac2e66a67715500cbca154bd6f3b8148bb7015a6aa6c644',310082000,NULL,NULL,'2b26c6d901ca9790987331432372046d9620d10ea163f4824208d6b23e8e7a35','79425e9c0b4f950f86fb8ff1fd34dd2c9a8f82236301a34730820d4e0e259216','6195f46cff465a3ddaf3d637e3d10706fb3aef6f8b49f8eab9bbb5e9b2f1224d');
INSERT INTO blocks VALUES(310083,'9b1f6fd6ff9b0dc4e37603cfb0625f49067c775b99e12492afd85392d3c8d850',310083000,NULL,NULL,'0d6d774dce93e94e870835005b0e8b04f010fb25158aa69a0fa0321d1577e987','e34be3b30e991158ab7b553a6cc8f00e71c2029c70c8e8c17ab47d8b3e1e418e','e5e67e57d85524ac89816fd585008fb1245041bda8b10a58195746980cc67243');
INSERT INTO blocks VALUES(310084,'1e0972523e80306441b9f4157f171716199f1428db2e818a7f7817ccdc8859e3',310084000,NULL,NULL,'9dbd171e3606b1662f6b576339b1e9aaa3da8a9f8a246bab905af255add4a762','0ce39ef2079b2b93403d2e4e962f22b74228b5e80e5a420c98d2eae02854b6dc','cb381f87b8aef56ada68effc8a08c095d7f56cb69ec29a52bb049108c5a5d72e');
INSERT INTO blocks VALUES(310085,'c5b6e9581831e3bc5848cd7630c499bca26d9ece5156d36579bdb72d54817e34',310085000,NULL,NULL,'db67b5dc6b0c0ddec22d0e716b72aa8cb6fa9702316f2a8e12659ee229094c16','b3f80496b10ba29f3226c63adbcd29a0ac74335e8fbbd16c91d8a6550ea3293e','ec2af9c06c2cb64733c1e364f33d096f50639f014132a4ce29bdceb6d5367351');
INSERT INTO blocks VALUES(310086,'080c1dc55a4ecf4824cf9840602498cfc35b5f84099f50b71b45cb63834c7a78',310086000,NULL,NULL,'7cf70b5298dbb36efbec2fb880b76e2514e3bad9d5200875fa3eb3ceb7719ee8','4a9c5608c8230f04d90d60daa8096bfe57c047744cfdad7208b17b653303f69b','3d06b755c41fddab627283c70577856fa6f5627c8895befe4883f59ffe2cdeb0');
INSERT INTO blocks VALUES(310087,'4ec8cb1c38b22904e8087a034a6406b896eff4dd28e7620601c6bddf82e2738c',310087000,NULL,NULL,'27106f400fe1ee93bde42f3bf3cf39737fb856bbf0df3f90fe0838cf7d38798c','c4669f71fdeb31986afe7a68779f4345203110ea10f7871f1f4d16867eb2d6ed','448a29bdd829f5f29cc2d3659d06086d46c54f83db066acc1d9a5291e8c93743');
INSERT INTO blocks VALUES(310088,'e945c815c433cbddd0bf8e66c5c23b51072483492acda98f5c2c201020a8c5b3',310088000,NULL,NULL,'28c9833eded6d68967f206e5884616f83bb9ad16b9d7a507031b96480aecc799','5caaba2a188d695232b1c4016a550a6ae8602afcd33d1e2755949679a71815be','708ea172df7bfe7df375e9da059f58b2067dd39e481f8df3a01525b93e78ae6d');
INSERT INTO blocks VALUES(310089,'0382437f895ef3e7e38bf025fd4f606fd44d4bbd6aea71dbdc4ed11a7cd46f33',310089000,NULL,NULL,'cdac6435934ea6e67a311495325c85237158ef30c009ea44c562c2127d79e696','7fa444c3cd644744082bf2ed72b83458d6d92819dac41859a6e561889e228f69','531073187c02e010efe14d368e3fbd699ef92f2ebfab6d3e7ec289942ab144ea');
INSERT INTO blocks VALUES(310090,'b756db71dc037b5a4582de354a3347371267d31ebda453e152f0a13bb2fae969',310090000,NULL,NULL,'cb33e420348e7969a2310445a6c17c79e647d3c6f3106d4fd0c0a1249e11ed6f','1e28b23ffe4c16961e973350e39a35847ce0a026daa4eedb42baf1937b756a8f','90070532d81083fc5a43f3c20f352e4bdfa8211ec32d5dd2140f9ea5497acac3');
INSERT INTO blocks VALUES(310091,'734a9aa485f36399d5efb74f3b9c47f8b5f6fd68c9967f134b14cfe7e2d7583c',310091000,NULL,NULL,'dda2531cf7db78a3f27c1ce70189b3f6efb69ddd24b61639f9deff42566bba2a','2ae2a1873846380a12d3e47a3150563293a49febe6526d6fcd57747510b4b318','28e40f9287dd4c8c9d346cc65d6b30d88a4bf5c588a2fdc53a7b36a99d7b340f');
INSERT INTO blocks VALUES(310092,'56386beb65f9228740d4ad43a1c575645f6daf59e0dd9f22551c59215b5e8c3d',310092000,NULL,NULL,'9ca7d9e1da0c6e4465d9e1c76990b6c48e62ee3a0b3b83189dc7a0f2c03a3006','bc62cd56ce7f79a8c309358b68e2a1e3613124ff6420f4d9e55f76d706432be9','94fe2c53b1b71d01e9f8be68c619cf778b8e58a8f77bbd2fd3f9fe76e550e6ff');
INSERT INTO blocks VALUES(310093,'a74a2425f2f4be24bb5f715173e6756649e1cbf1b064aeb1ef60e0b94b418ddc',310093000,NULL,NULL,'c6fc005e874909cf0393ac1bee7267f66cc5355c549d8657234a0ed6b429c869','95891f466c46a5b69655aac4610767302cb057fbd553db990aab5a87d46ba9c3','489e8fed28a7fa15594660ddb9117f72b709b5c8a7c229a06ea08018a5a6aeca');
INSERT INTO blocks VALUES(310094,'2a8f976f20c4e89ff01071915ac96ee35192d54df3a246bf61fd4a0cccfb5b23',310094000,NULL,NULL,'14dacaec0b37ca20f271e500d0ec1837a63006eb464728c067107738ad3167c6','96f6e13ba837527cdbc90e702d7bf049cdfaa57a7b87eff5600b5b994ffeb207','05c8845d2a68b6b746cf4d1b9c675242ac1b6a6ed3b19d588264f2227b1809d4');
INSERT INTO blocks VALUES(310095,'bed0fa40c9981223fb40b3be8124ca619edc9dd34d0c907369477ea92e5d2cd2',310095000,NULL,NULL,'05bd680c082185147e83785e7464d8890908d1550359b4fac79018b510475e01','3b73d3384fc0d59420f0a59b353a5cd291d145b672f2748ed34cbd79b7364a08','9b07872c6c634506ac7f56f708607e1e32f66f4caad959b4fe2c999b6611ad84');
INSERT INTO blocks VALUES(310096,'306aeec3db435fabffdf88c2f26ee83caa4c2426375a33daa2be041dbd27ea2f',310096000,NULL,NULL,'b50805d750ebd26f8dbced919948118f1f97ce7d117aa1760e7a3c4895f51e13','1c38f9f28882922ee1f7c9ef2c400ed582f1a5a2e78f5d07cc7e837b3e8257bf','5ccd07249241fd5965e698483c085d69fcd37d73ee029fc0c62c7aed59101a08');
INSERT INTO blocks VALUES(310097,'13e8e16e67c7cdcc80d477491e554b43744f90e8e1a9728439a11fab42cefadf',310097000,NULL,NULL,'dde96405c241e1d57334670e4eff7ed8db92056e6867cae10475a9bc30ba4619','588d792e31025c5cd8f22d8a448c140cecb0c697deb3b2dd8dbbf6ed4d60cf68','a66c4fad958ffb60db088d64c80d59712dc58402ac08fd5061e3367c5c594de7');
INSERT INTO blocks VALUES(310098,'ca5bca4b5ec4fa6183e05176abe921cff884c4e20910fab55b603cef48dc3bca',310098000,NULL,NULL,'613d78fbabba246a4d1cd9d50317e732795a59812df8395472347e15cec1ee9b','043424bae36f5583c12478c648e641e0bebb9973ad39c3338cba438cc3712928','6d51cbee9c9b6770dac33214495b20dfb4be991666ef0aca4ceba8f27653db3b');
INSERT INTO blocks VALUES(310099,'3c4c2279cd7de0add5ec469648a845875495a7d54ebfb5b012dcc5a197b7992a',310099000,NULL,NULL,'e535ca5960d2ce7508bd2157dd0cac3ea1f9ab14532a40884d522b4bba0d4979','4835b537b4519c321eaf1c19da3b6b537dd07648f7cd2fe64115e2e97fa2b516','442ec4739a7d0e538b33404a70fec923c228e97024bf2713b65bf5363479e56f');
INSERT INTO blocks VALUES(310100,'96925c05b3c7c80c716f5bef68d161c71d044252c766ca0e3f17f255764242cb',310100000,NULL,NULL,'970865291b7a6d8173d6ad2ae97335cb2e89d80cbbb7a79bb2328cf6c67fa6cd','21ac969585b1cce59a45cd3ba0bc37695d28506124ab52964a7136adf1ec1a59','4f51491b513bf50a9a06fdb4ac2800c76a795decd4bd0a9b6bf27ccba25dedd1');
INSERT INTO blocks VALUES(310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,NULL,NULL,'0741e57ad88cdada65134c9f131ff5bfd9498cb054378d829e34715e8db2aa6d','1f415c7233c53c789983560b4b1bbf62f4045b7d7b0b307651cf84591f88e418','c25023995c104c6c87c38c096cf58aa5fd1e1e013afcdd8fe8561a157db9a37a');
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
INSERT INTO broadcasts VALUES(19,'4184216d2afb9be606bd8b5a08ab19c50f4b274c962cf30a3985094f7444f548',310018,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000050,99.86166,5000000,'Unit Test',0,'valid');
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
INSERT INTO credits VALUES(310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',4250000,'filled','d966330f429d59a82c6da65f61ef3768d58973f15fa899e9d1c9a981b4fa4bda');
INSERT INTO credits VALUES(310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',5000000,'cancel order','178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424');
INSERT INTO credits VALUES(310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6');
INSERT INTO credits VALUES(310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6');
INSERT INTO credits VALUES(310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3');
INSERT INTO credits VALUES(310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3');
INSERT INTO credits VALUES(310018,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',59137500,'bet settled: liquidated for bear','4184216d2afb9be606bd8b5a08ab19c50f4b274c962cf30a3985094f7444f548');
INSERT INTO credits VALUES(310018,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',3112500,'feed fee','4184216d2afb9be606bd8b5a08ab19c50f4b274c962cf30a3985094f7444f548');
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
INSERT INTO debits VALUES(310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',25000000,'bet','d966330f429d59a82c6da65f61ef3768d58973f15fa899e9d1c9a981b4fa4bda');
INSERT INTO debits VALUES(310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',150000000,'bet','f96724f9dcd53ea256e509e6dad698cbc40fc910fac1b598135751c479177f93');
INSERT INTO debits VALUES(310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',350000000,'bet','c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6');
INSERT INTO debits VALUES(310016,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',750000000,'bet','a07db7528b9e94adcfb511d01128d3fc7ab19b90b36aebeba8033744b54ba4ab');
INSERT INTO debits VALUES(310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',650000000,'bet','622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3');
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
INSERT INTO issuances VALUES(6,'22c284e49ded9ee4c668a675f1eaf32925992911384db539cfef1b3784ea7cd6',310005,'BBBB',1000000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(7,'21fe775c51dee2527cbafa7d5231a22ae988f7428563c2bbaad3692b65a32e28',310006,'BBBC',100000,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'foobar',50000000,0,'valid',NULL);
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
INSERT INTO messages VALUES(15,310005,'insert','issuances','{"asset": "BBBB", "asset_longname": null, "block_index": 310005, "call_date": 0, "call_price": 0.0, "callable": false, "description": "", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "22c284e49ded9ee4c668a675f1eaf32925992911384db539cfef1b3784ea7cd6", "tx_index": 6}',0);
INSERT INTO messages VALUES(16,310005,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBB", "block_index": 310005, "event": "22c284e49ded9ee4c668a675f1eaf32925992911384db539cfef1b3784ea7cd6", "quantity": 1000000000}',0);
INSERT INTO messages VALUES(17,310006,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310006, "event": "21fe775c51dee2527cbafa7d5231a22ae988f7428563c2bbaad3692b65a32e28", "quantity": 50000000}',0);
INSERT INTO messages VALUES(18,310006,'insert','issuances','{"asset": "BBBC", "asset_longname": null, "block_index": 310006, "call_date": 0, "call_price": 0.0, "callable": false, "description": "foobar", "divisible": false, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "21fe775c51dee2527cbafa7d5231a22ae988f7428563c2bbaad3692b65a32e28", "tx_index": 7}',0);
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
INSERT INTO messages VALUES(39,310013,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310013, "event": "d966330f429d59a82c6da65f61ef3768d58973f15fa899e9d1c9a981b4fa4bda", "quantity": 25000000}',0);
INSERT INTO messages VALUES(40,310013,'insert','bets','{"bet_type": 1, "block_index": 310013, "counterwager_quantity": 41500000, "counterwager_remaining": 41500000, "deadline": 1388000100, "expiration": 10, "expire_index": 310023, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 15120, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "d966330f429d59a82c6da65f61ef3768d58973f15fa899e9d1c9a981b4fa4bda", "tx_index": 14, "wager_quantity": 25000000, "wager_remaining": 25000000}',0);
INSERT INTO messages VALUES(41,310013,'update','bets','{"counterwager_remaining": 4250000, "status": "open", "tx_hash": "72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64", "wager_remaining": 8500000}',0);
INSERT INTO messages VALUES(42,310013,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310013, "event": "d966330f429d59a82c6da65f61ef3768d58973f15fa899e9d1c9a981b4fa4bda", "quantity": 4250000}',0);
INSERT INTO messages VALUES(43,310013,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "d966330f429d59a82c6da65f61ef3768d58973f15fa899e9d1c9a981b4fa4bda", "wager_remaining": 4250000}',0);
INSERT INTO messages VALUES(44,310013,'insert','bet_matches','{"backward_quantity": 20750000, "block_index": 310013, "deadline": 1388000100, "fee_fraction_int": 5000000, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 41500000, "id": "72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64_d966330f429d59a82c6da65f61ef3768d58973f15fa899e9d1c9a981b4fa4bda", "initial_value": 100.0, "leverage": 15120, "match_expire_index": 310022, "status": "pending", "target_value": 0.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 0, "tx0_block_index": 310012, "tx0_expiration": 10, "tx0_hash": "72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64", "tx0_index": 13, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_bet_type": 1, "tx1_block_index": 310013, "tx1_expiration": 10, "tx1_hash": "d966330f429d59a82c6da65f61ef3768d58973f15fa899e9d1c9a981b4fa4bda", "tx1_index": 14}',0);
INSERT INTO messages VALUES(45,310014,'update','orders','{"status": "expired", "tx_hash": "178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424"}',0);
INSERT INTO messages VALUES(46,310014,'insert','credits','{"action": "cancel order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310014, "event": "178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424", "quantity": 5000000}',0);
INSERT INTO messages VALUES(47,310014,'insert','order_expirations','{"block_index": 310014, "order_hash": "178e4ac45cf71f96a3a09f58739b504348173da619e567ed0b3c6bc790181424", "order_index": 4, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
INSERT INTO messages VALUES(48,310014,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310014, "event": "f96724f9dcd53ea256e509e6dad698cbc40fc910fac1b598135751c479177f93", "quantity": 150000000}',0);
INSERT INTO messages VALUES(49,310014,'insert','bets','{"bet_type": 0, "block_index": 310014, "counterwager_quantity": 350000000, "counterwager_remaining": 350000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310024, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "f96724f9dcd53ea256e509e6dad698cbc40fc910fac1b598135751c479177f93", "tx_index": 15, "wager_quantity": 150000000, "wager_remaining": 150000000}',0);
INSERT INTO messages VALUES(50,310015,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310015, "event": "c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6", "quantity": 350000000}',0);
INSERT INTO messages VALUES(51,310015,'insert','bets','{"bet_type": 1, "block_index": 310015, "counterwager_quantity": 150000000, "counterwager_remaining": 150000000, "deadline": 1388000100, "expiration": 10, "expire_index": 310025, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6", "tx_index": 16, "wager_quantity": 350000000, "wager_remaining": 350000000}',0);
INSERT INTO messages VALUES(52,310015,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310015, "event": "c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6", "quantity": 0}',0);
INSERT INTO messages VALUES(53,310015,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "f96724f9dcd53ea256e509e6dad698cbc40fc910fac1b598135751c479177f93", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(54,310015,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310015, "event": "c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6", "quantity": 0}',0);
INSERT INTO messages VALUES(55,310015,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(56,310015,'insert','bet_matches','{"backward_quantity": 350000000, "block_index": 310015, "deadline": 1388000100, "fee_fraction_int": 5000000, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 150000000, "id": "f96724f9dcd53ea256e509e6dad698cbc40fc910fac1b598135751c479177f93_c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6", "initial_value": 100.0, "leverage": 5040, "match_expire_index": 310024, "status": "pending", "target_value": 0.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 0, "tx0_block_index": 310014, "tx0_expiration": 10, "tx0_hash": "f96724f9dcd53ea256e509e6dad698cbc40fc910fac1b598135751c479177f93", "tx0_index": 15, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_bet_type": 1, "tx1_block_index": 310015, "tx1_expiration": 10, "tx1_hash": "c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6", "tx1_index": 16}',0);
INSERT INTO messages VALUES(57,310016,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310016, "event": "a07db7528b9e94adcfb511d01128d3fc7ab19b90b36aebeba8033744b54ba4ab", "quantity": 750000000}',0);
INSERT INTO messages VALUES(58,310016,'insert','bets','{"bet_type": 2, "block_index": 310016, "counterwager_quantity": 650000000, "counterwager_remaining": 650000000, "deadline": 1388000200, "expiration": 10, "expire_index": 310026, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 1.0, "tx_hash": "a07db7528b9e94adcfb511d01128d3fc7ab19b90b36aebeba8033744b54ba4ab", "tx_index": 17, "wager_quantity": 750000000, "wager_remaining": 750000000}',0);
INSERT INTO messages VALUES(59,310017,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310017, "event": "622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3", "quantity": 650000000}',0);
INSERT INTO messages VALUES(60,310017,'insert','bets','{"bet_type": 3, "block_index": 310017, "counterwager_quantity": 750000000, "counterwager_remaining": 750000000, "deadline": 1388000200, "expiration": 10, "expire_index": 310027, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 1.0, "tx_hash": "622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3", "tx_index": 18, "wager_quantity": 650000000, "wager_remaining": 650000000}',0);
INSERT INTO messages VALUES(61,310017,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310017, "event": "622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3", "quantity": 0}',0);
INSERT INTO messages VALUES(62,310017,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "a07db7528b9e94adcfb511d01128d3fc7ab19b90b36aebeba8033744b54ba4ab", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(63,310017,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310017, "event": "622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3", "quantity": 0}',0);
INSERT INTO messages VALUES(64,310017,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(65,310017,'insert','bet_matches','{"backward_quantity": 650000000, "block_index": 310017, "deadline": 1388000200, "fee_fraction_int": 5000000, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 750000000, "id": "a07db7528b9e94adcfb511d01128d3fc7ab19b90b36aebeba8033744b54ba4ab_622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3", "initial_value": 100.0, "leverage": 5040, "match_expire_index": 310026, "status": "pending", "target_value": 1.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 2, "tx0_block_index": 310016, "tx0_expiration": 10, "tx0_hash": "a07db7528b9e94adcfb511d01128d3fc7ab19b90b36aebeba8033744b54ba4ab", "tx0_index": 17, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_bet_type": 3, "tx1_block_index": 310017, "tx1_expiration": 10, "tx1_hash": "622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3", "tx1_index": 18}',0);
INSERT INTO messages VALUES(66,310018,'insert','broadcasts','{"block_index": 310018, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000050, "tx_hash": "4184216d2afb9be606bd8b5a08ab19c50f4b274c962cf30a3985094f7444f548", "tx_index": 19, "value": 99.86166}',0);
INSERT INTO messages VALUES(67,310018,'insert','credits','{"action": "bet settled: liquidated for bear", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310018, "event": "4184216d2afb9be606bd8b5a08ab19c50f4b274c962cf30a3985094f7444f548", "quantity": 59137500}',0);
INSERT INTO messages VALUES(68,310018,'insert','credits','{"action": "feed fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310018, "event": "4184216d2afb9be606bd8b5a08ab19c50f4b274c962cf30a3985094f7444f548", "quantity": 3112500}',0);
INSERT INTO messages VALUES(69,310018,'insert','bet_match_resolutions','{"bear_credit": 59137500, "bet_match_id": "72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64_d966330f429d59a82c6da65f61ef3768d58973f15fa899e9d1c9a981b4fa4bda", "bet_match_type_id": 1, "block_index": 310018, "bull_credit": 0, "escrow_less_fee": null, "fee": 3112500, "settled": false, "winner": null}',0);
INSERT INTO messages VALUES(70,310018,'update','bet_matches','{"bet_match_id": "72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64_d966330f429d59a82c6da65f61ef3768d58973f15fa899e9d1c9a981b4fa4bda", "status": "settled: liquidated for bear"}',0);
INSERT INTO messages VALUES(71,310019,'insert','broadcasts','{"block_index": 310019, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000101, "tx_hash": "81c1352495060dcc6b95618054280fbce920365aa025f4903e1840d6902b067d", "tx_index": 20, "value": 100.343}',0);
INSERT INTO messages VALUES(72,310019,'insert','credits','{"action": "bet settled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310019, "event": "81c1352495060dcc6b95618054280fbce920365aa025f4903e1840d6902b067d", "quantity": 159300000}',0);
INSERT INTO messages VALUES(73,310019,'insert','credits','{"action": "bet settled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310019, "event": "81c1352495060dcc6b95618054280fbce920365aa025f4903e1840d6902b067d", "quantity": 315700000}',0);
INSERT INTO messages VALUES(74,310019,'insert','credits','{"action": "feed fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310019, "event": "81c1352495060dcc6b95618054280fbce920365aa025f4903e1840d6902b067d", "quantity": 25000000}',0);
INSERT INTO messages VALUES(75,310019,'insert','bet_match_resolutions','{"bear_credit": 315700000, "bet_match_id": "f96724f9dcd53ea256e509e6dad698cbc40fc910fac1b598135751c479177f93_c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6", "bet_match_type_id": 1, "block_index": 310019, "bull_credit": 159300000, "escrow_less_fee": null, "fee": 25000000, "settled": true, "winner": null}',0);
INSERT INTO messages VALUES(76,310019,'update','bet_matches','{"bet_match_id": "f96724f9dcd53ea256e509e6dad698cbc40fc910fac1b598135751c479177f93_c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6", "status": "settled"}',0);
INSERT INTO messages VALUES(77,310020,'insert','broadcasts','{"block_index": 310020, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000201, "tx_hash": "248e7b3add0f648221a23da67e6e3ab52c12fd50b4ce589ad8273877c89967ad", "tx_index": 21, "value": 2.0}',0);
INSERT INTO messages VALUES(78,310020,'insert','credits','{"action": "bet settled: for notequal", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310020, "event": "248e7b3add0f648221a23da67e6e3ab52c12fd50b4ce589ad8273877c89967ad", "quantity": 1330000000}',0);
INSERT INTO messages VALUES(79,310020,'insert','credits','{"action": "feed fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310020, "event": "248e7b3add0f648221a23da67e6e3ab52c12fd50b4ce589ad8273877c89967ad", "quantity": 70000000}',0);
INSERT INTO messages VALUES(80,310020,'insert','bet_match_resolutions','{"bear_credit": null, "bet_match_id": "a07db7528b9e94adcfb511d01128d3fc7ab19b90b36aebeba8033744b54ba4ab_622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3", "bet_match_type_id": 5, "block_index": 310020, "bull_credit": null, "escrow_less_fee": 1330000000, "fee": 70000000, "settled": null, "winner": "NotEqual"}',0);
INSERT INTO messages VALUES(81,310020,'update','bet_matches','{"bet_match_id": "a07db7528b9e94adcfb511d01128d3fc7ab19b90b36aebeba8033744b54ba4ab_622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3", "status": "settled: for notequal"}',0);
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
INSERT INTO sends VALUES(2,'e535051ed7386995cc9152ea2d403f8460a59a5d084d4443158e466d743b3d63',310001,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',50000000,'valid',NULL);
INSERT INTO sends VALUES(8,'611bd2d4fd7dae2282e00873249574cd435052cb274fe70ec9b96a1549d78042',310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBB',4000000,'valid',NULL);
INSERT INTO sends VALUES(9,'2f40b6b1c699c15fd194fa30a003dcf2a2a4421a92aece4e5a5ee9c4b475d43d',310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',526,'valid',NULL);
INSERT INTO sends VALUES(24,'004cbeaac3e999874c19d95a83cde38472c9392c17ae93b49e741ce078694912',310023,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',10000,'valid',NULL);
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
INSERT INTO transactions VALUES(14,'d966330f429d59a82c6da65f61ef3768d58973f15fa899e9d1c9a981b4fa4bda',310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000152BB336400000000017D78400000000002793D60000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(15,'f96724f9dcd53ea256e509e6dad698cbc40fc910fac1b598135751c479177f93',310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000052BB33640000000008F0D1800000000014DC93800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(16,'c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6',310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000152BB33640000000014DC93800000000008F0D1800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(17,'a07db7528b9e94adcfb511d01128d3fc7ab19b90b36aebeba8033744b54ba4ab',310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000252BB33C8000000002CB417800000000026BE36803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(18,'622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3',310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000352BB33C80000000026BE3680000000002CB417803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(19,'4184216d2afb9be606bd8b5a08ab19c50f4b274c962cf30a3985094f7444f548',310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001E52BB33324058F7256FFC115E004C4B4009556E69742054657374',1);
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
INSERT INTO undolog VALUES(68,'UPDATE bets SET tx_index=14,tx_hash=''d966330f429d59a82c6da65f61ef3768d58973f15fa899e9d1c9a981b4fa4bda'',block_index=310013,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=1,deadline=1388000100,wager_quantity=25000000,wager_remaining=25000000,counterwager_quantity=41500000,counterwager_remaining=41500000,target_value=0.0,leverage=15120,expiration=10,expire_index=310023,fee_fraction_int=5000000,status=''open'' WHERE rowid=2');
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
INSERT INTO undolog VALUES(82,'UPDATE bets SET tx_index=15,tx_hash=''f96724f9dcd53ea256e509e6dad698cbc40fc910fac1b598135751c479177f93'',block_index=310014,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=0,deadline=1388000100,wager_quantity=150000000,wager_remaining=150000000,counterwager_quantity=350000000,counterwager_remaining=350000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310024,fee_fraction_int=5000000,status=''open'' WHERE rowid=3');
INSERT INTO undolog VALUES(83,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(84,'DELETE FROM credits WHERE rowid=13');
INSERT INTO undolog VALUES(85,'UPDATE bets SET tx_index=16,tx_hash=''c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6'',block_index=310015,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=1,deadline=1388000100,wager_quantity=350000000,wager_remaining=350000000,counterwager_quantity=150000000,counterwager_remaining=150000000,target_value=0.0,leverage=5040,expiration=10,expire_index=310025,fee_fraction_int=5000000,status=''open'' WHERE rowid=4');
INSERT INTO undolog VALUES(86,'DELETE FROM bet_matches WHERE rowid=2');
INSERT INTO undolog VALUES(87,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92278789176 WHERE rowid=1');
INSERT INTO undolog VALUES(88,'DELETE FROM debits WHERE rowid=15');
INSERT INTO undolog VALUES(89,'DELETE FROM bets WHERE rowid=5');
INSERT INTO undolog VALUES(90,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91528789176 WHERE rowid=1');
INSERT INTO undolog VALUES(91,'DELETE FROM debits WHERE rowid=16');
INSERT INTO undolog VALUES(92,'DELETE FROM bets WHERE rowid=6');
INSERT INTO undolog VALUES(93,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(94,'DELETE FROM credits WHERE rowid=14');
INSERT INTO undolog VALUES(95,'UPDATE bets SET tx_index=17,tx_hash=''a07db7528b9e94adcfb511d01128d3fc7ab19b90b36aebeba8033744b54ba4ab'',block_index=310016,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=2,deadline=1388000200,wager_quantity=750000000,wager_remaining=750000000,counterwager_quantity=650000000,counterwager_remaining=650000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310026,fee_fraction_int=5000000,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(96,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(97,'DELETE FROM credits WHERE rowid=15');
INSERT INTO undolog VALUES(98,'UPDATE bets SET tx_index=18,tx_hash=''622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3'',block_index=310017,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',bet_type=3,deadline=1388000200,wager_quantity=650000000,wager_remaining=650000000,counterwager_quantity=750000000,counterwager_remaining=750000000,target_value=1.0,leverage=5040,expiration=10,expire_index=310027,fee_fraction_int=5000000,status=''open'' WHERE rowid=6');
INSERT INTO undolog VALUES(99,'DELETE FROM bet_matches WHERE rowid=3');
INSERT INTO undolog VALUES(100,'DELETE FROM broadcasts WHERE rowid=19');
INSERT INTO undolog VALUES(101,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90878789176 WHERE rowid=1');
INSERT INTO undolog VALUES(102,'DELETE FROM credits WHERE rowid=16');
INSERT INTO undolog VALUES(103,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90937926676 WHERE rowid=1');
INSERT INTO undolog VALUES(104,'DELETE FROM credits WHERE rowid=17');
INSERT INTO undolog VALUES(105,'DELETE FROM bet_match_resolutions WHERE rowid=1');
INSERT INTO undolog VALUES(106,'UPDATE bet_matches SET id=''72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64_d966330f429d59a82c6da65f61ef3768d58973f15fa899e9d1c9a981b4fa4bda'',tx0_index=13,tx0_hash=''72d34398a53d7f7273d08b7708da302a396b0b8d1e4fe25eaa9845638b3e3f64'',tx0_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx1_index=14,tx1_hash=''d966330f429d59a82c6da65f61ef3768d58973f15fa899e9d1c9a981b4fa4bda'',tx1_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=15120,forward_quantity=41500000,backward_quantity=20750000,tx0_block_index=310012,tx1_block_index=310013,block_index=310013,tx0_expiration=10,tx1_expiration=10,match_expire_index=310022,fee_fraction_int=5000000,status=''pending'' WHERE rowid=1');
INSERT INTO undolog VALUES(107,'DELETE FROM broadcasts WHERE rowid=20');
INSERT INTO undolog VALUES(108,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=90941039176 WHERE rowid=1');
INSERT INTO undolog VALUES(109,'DELETE FROM credits WHERE rowid=18');
INSERT INTO undolog VALUES(110,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91100339176 WHERE rowid=1');
INSERT INTO undolog VALUES(111,'DELETE FROM credits WHERE rowid=19');
INSERT INTO undolog VALUES(112,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91416039176 WHERE rowid=1');
INSERT INTO undolog VALUES(113,'DELETE FROM credits WHERE rowid=20');
INSERT INTO undolog VALUES(114,'DELETE FROM bet_match_resolutions WHERE rowid=2');
INSERT INTO undolog VALUES(115,'UPDATE bet_matches SET id=''f96724f9dcd53ea256e509e6dad698cbc40fc910fac1b598135751c479177f93_c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6'',tx0_index=15,tx0_hash=''f96724f9dcd53ea256e509e6dad698cbc40fc910fac1b598135751c479177f93'',tx0_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx1_index=16,tx1_hash=''c4a2b9e027a1d35189e75e410797e61df753f979288aacb5df0b95da7d052ef6'',tx1_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx0_bet_type=0,tx1_bet_type=1,feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',initial_value=100,deadline=1388000100,target_value=0.0,leverage=5040,forward_quantity=150000000,backward_quantity=350000000,tx0_block_index=310014,tx1_block_index=310015,block_index=310015,tx0_expiration=10,tx1_expiration=10,match_expire_index=310024,fee_fraction_int=5000000,status=''pending'' WHERE rowid=2');
INSERT INTO undolog VALUES(116,'DELETE FROM broadcasts WHERE rowid=21');
INSERT INTO undolog VALUES(117,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91441039176 WHERE rowid=1');
INSERT INTO undolog VALUES(118,'DELETE FROM credits WHERE rowid=21');
INSERT INTO undolog VALUES(119,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92771039176 WHERE rowid=1');
INSERT INTO undolog VALUES(120,'DELETE FROM credits WHERE rowid=22');
INSERT INTO undolog VALUES(121,'DELETE FROM bet_match_resolutions WHERE rowid=3');
INSERT INTO undolog VALUES(122,'UPDATE bet_matches SET id=''a07db7528b9e94adcfb511d01128d3fc7ab19b90b36aebeba8033744b54ba4ab_622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3'',tx0_index=17,tx0_hash=''a07db7528b9e94adcfb511d01128d3fc7ab19b90b36aebeba8033744b54ba4ab'',tx0_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx1_index=18,tx1_hash=''622431499aef08633e77f2978a62842d39764aaa84533c4f44b70cee38aeedf3'',tx1_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',tx0_bet_type=2,tx1_bet_type=3,feed_address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',initial_value=100,deadline=1388000200,target_value=1.0,leverage=5040,forward_quantity=750000000,backward_quantity=650000000,tx0_block_index=310016,tx1_block_index=310017,block_index=310017,tx0_expiration=10,tx1_expiration=10,match_expire_index=310026,fee_fraction_int=5000000,status=''pending'' WHERE rowid=3');
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
