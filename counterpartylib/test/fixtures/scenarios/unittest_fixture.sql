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
INSERT INTO addresses VALUES('myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',0,310488);
INSERT INTO addresses VALUES('mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',1,310490);
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
INSERT INTO assets VALUES('697326324582','DIVISIBLE',310001,NULL);
INSERT INTO assets VALUES('1911882621324134','NODIVISIBLE',310002,NULL);
INSERT INTO assets VALUES('16199343190','CALLABLE',310003,NULL);
INSERT INTO assets VALUES('137134819','LOCKED',310004,NULL);
INSERT INTO assets VALUES('211518','MAXI',310016,NULL);
INSERT INTO assets VALUES('2122675428648001','PAYTOSCRIPT',310109,NULL);
INSERT INTO assets VALUES('62667321322601','LOCKEDPREV',310113,NULL);
INSERT INTO assets VALUES('26819977213','DIVIDEND',310494,NULL);
INSERT INTO assets VALUES('178522493','PARENT',310497,NULL);
INSERT INTO assets VALUES('95428956661682277','A95428956661682277',310498,'PARENT.already.issued');
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
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',91875000000);
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',98800000000);
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','NODIVISIBLE',985);
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','CALLABLE',1000);
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','LOCKED',1000);
INSERT INTO balances VALUES('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','DIVISIBLE',100000000);
INSERT INTO balances VALUES('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',99999990);
INSERT INTO balances VALUES('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',300000000);
INSERT INTO balances VALUES('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','DIVISIBLE',1000000000);
INSERT INTO balances VALUES('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','NODIVISIBLE',5);
INSERT INTO balances VALUES('1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','NODIVISIBLE',10);
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','MAXI',9223372036854775807);
INSERT INTO balances VALUES('myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','XCP',92999138812);
INSERT INTO balances VALUES('munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','XCP',92999130360);
INSERT INTO balances VALUES('mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',92949122099);
INSERT INTO balances VALUES('mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK','XCP',14999857);
INSERT INTO balances VALUES('2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',46449548498);
INSERT INTO balances VALUES('2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','PAYTOSCRIPT',1000);
INSERT INTO balances VALUES('2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000);
INSERT INTO balances VALUES('mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','LOCKEDPREV',1000);
INSERT INTO balances VALUES('tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx','XCP',92999030129);
INSERT INTO balances VALUES('mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',0);
INSERT INTO balances VALUES('mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','DIVIDEND',90);
INSERT INTO balances VALUES('mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','DIVIDEND',10);
INSERT INTO balances VALUES('mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','XCP',92945878046);
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','PARENT',100000000);
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','A95428956661682277',100000000);
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
INSERT INTO bet_match_resolutions VALUES('2a2169991597036b6dad687ea1feffd55465a204466f40c35cbba811cb3109b1_5c6562ddad0bc8a1faaded18813a65522cd273709acd190cf9d3271817eefc93',1,310102,'1',9,9,NULL,NULL,0);
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
INSERT INTO bet_matches VALUES('2a2169991597036b6dad687ea1feffd55465a204466f40c35cbba811cb3109b1_5c6562ddad0bc8a1faaded18813a65522cd273709acd190cf9d3271817eefc93',20,'2a2169991597036b6dad687ea1feffd55465a204466f40c35cbba811cb3109b1','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',21,'5c6562ddad0bc8a1faaded18813a65522cd273709acd190cf9d3271817eefc93','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',1,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000001,0.0,5040,9,9,310019,310020,310020,100,100,310119,5000000,'settled');
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
INSERT INTO bets VALUES(20,'2a2169991597036b6dad687ea1feffd55465a204466f40c35cbba811cb3109b1',310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000001,9,0,9,0,0.0,5040,100,310119,5000000,'filled');
INSERT INTO bets VALUES(21,'5c6562ddad0bc8a1faaded18813a65522cd273709acd190cf9d3271817eefc93',310020,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1388000001,9,0,9,0,0.0,5040,100,310120,5000000,'filled');
INSERT INTO bets VALUES(102,'db4ea092bea6036e3d1e5f6ec863db9b900252b4f4d6d9faa6165323f433c51e',310101,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',3,1388000200,10,10,10,10,0.0,5040,1000,311101,5000000,'open');
INSERT INTO bets VALUES(113,'d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048',310112,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',3,1388000200,10,10,10,10,0.0,5040,1000,311112,5000000,'open');
INSERT INTO bets VALUES(488,'41e821ae1c6b553d0fa5d5a807b2e7e9ffaec5d62706d9d2a59c6e65a3ed9cef',310487,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',1,1388000001,9,9,9,9,0.0,5040,100,310587,5000000,'open');
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
INSERT INTO blocks VALUES(310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,NULL,NULL,'cf0ea1d313e22ba5f413075b88e07dffc5c00e59f95eeb6d6dec935bd77f5ae4','f06c23e6040a063ed59693baa0d63492dce64e1debc7455b22f5535c9dfbdc67','a2f055f16d61e66beb49eed7edea807f409d9b7a7b5b157ee6d607e6669d7d50');
INSERT INTO blocks VALUES(310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,NULL,NULL,'11461f972c4cd85c87b5abfedb3cee589d09e945570d34564dcde6f4df9d2b57','ff8358e8c8b2cb9a1765deadb77bdfc6eae05a844831a0a8c8820d416d54446e','f2096443ad1c76278a597fb9ac4d3fe896d6f20f29090bd9ecbe76fa3ab06e38');
INSERT INTO blocks VALUES(310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,NULL,NULL,'355d92f841de89a1d97c3b2ea7623959ea4494bb62ea7e67ad359beb68caca8c','b17176b511fdea4cd899cfaf83f2e12193a4c92d1b199f18f590eb4fed90fa25','0346a175d47c401ad42280c62003473f6bbcfde755a22f4add42cc3780245ab7');
INSERT INTO blocks VALUES(310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,NULL,NULL,'edcd7e344fb5cca16999f025594890b8b54543555e61eb3807406bb4204677f2','b6dffe5b8c1f483c3c20832d23dddd7b530afe7ac1f3f57f433da59d83b48f06','0ddc15e3f49c12107717d87a720062696fffc76a3a8b7830ed9ba8aa98a03249');
INSERT INTO blocks VALUES(310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,NULL,NULL,'abd71a31bc1f8a072761b23a5bc2976731ebdf305d1d7d33922e93573f308129','3da72b0c813432f47a3a70887dfd29350d270e9ebaca9875ed6304c91888e387','1525daa1f9dd2b6a2a0f40417e6dc6345d3718afa7f32c8a18b6a97413ec070b');
INSERT INTO blocks VALUES(310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,NULL,NULL,'0c3914f9676e506a96e6db793f15200ef33087cd47de4d27628849013a391daa','2d59f139907859f9108360f7fa4695101a6b5ef0b7dd0e56c2dd41641e58e9af','33a8620ab33c4413868f14b8b5d2268e34ebca6fe534eebd4684449d1ace985d');
INSERT INTO blocks VALUES(310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,NULL,NULL,'57ff5f34a9e418b179db9003414c5f3bdfa7feeb538f24071b23d024a3d05df0','a4a6fb433e6c49968fded16954502c472b0d21b74c6cce8d08c8c53c00f2781e','af0a8b0b616144b79b6ce3771629aeb8d63da5a4938eabd6a337eb36edbeab36');
INSERT INTO blocks VALUES(310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,NULL,NULL,'bfed530458339aab02ff75ad76738569dc6997c7a35d4452351678b04e022f68','ce20264c332892b0a5e0c3e2d4b63d02c901fa2c3f8c5171b2896b50c82ea0af','a26912398d5616bac54bcc22726978b847932feb549ae9ab3cdc120e60467041');
INSERT INTO blocks VALUES(310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,NULL,NULL,'d4feec997754d11a1502e5351ed62fcfbfcafb770e19a37da41d1d88b7b45ed4','d25c9f48fbbe2010a62cad729d45b658a2caf9a7c9abc65a30e2a7fc47bc83e5','cd632298bc31042965d8077a93c2ae891fcc6ffb658cf23b8614b1444ab74d8f');
INSERT INTO blocks VALUES(310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,NULL,NULL,'4ab5ff9e71bbc83956557fb5abec98372fa38e5580838fb258b2d831bfc4d9ea','173e769e0b4fa951ef0267c7e218f3a473d9a5857b0880d654a2181f244c92e2','bb715316a2db2c92ad539c3abb2216bf1d9bab1cf073a5cea7c053c22bbb8122');
INSERT INTO blocks VALUES(310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,NULL,NULL,'1909ef40a24263776cb9e0d52a690048b50728855a0fe4b0e1ba3834a9e401c1','7d1ef03dad99c4bdf7a8e5af7209a136c8ac392922dd3afdbcc0446ea1f5f604','9445ffe26b521bef12f598aa95693c83cf10ef4bf803f3b012787aac1c5a5c60');
INSERT INTO blocks VALUES(310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,NULL,NULL,'c3d51a5f2df90c089844ba4de7d5541f6051490aa1389e5945a7bb91d49e3589','86ebe5be8b9443f411adcd49e7443a34941979c0c6bf40136a3b44193024abfc','f01fd21667d4a5f230f420e686a45be6694e3844513d9b5879a29d2e44434cf1');
INSERT INTO blocks VALUES(310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,NULL,NULL,'a9dc31556d38b118eeb0bcbb3a374a0ed79adec4eb23e00c80c0599ba97c9a7a','5a729b250068fe7b175a540b66a30326344514e357023184540ef97bae5e16e7','d9bf59b4fed364b8bfccc44a6cfebf02ed148254083d6061809fe49bba555088');
INSERT INTO blocks VALUES(310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,NULL,NULL,'e72be5070d0a5853631d902d334e8b88eddf6e79616373311babc4a0a27dd3d8','1294e3d0871b0c2297d9980ed46bfa3563b33b202b426949dadeeba7075b4bc7','0ad52a8098aa135f4dd0e00e22f67c446de96c96cc7d9a479e47589b3d833e14');
INSERT INTO blocks VALUES(310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,NULL,NULL,'cb0962222af917dbac2a11465c22cd80770c0b3cdb8bdc0870c99a8116745c9e','d5431af170b331497d8967969820632880473d06dae0d06fa7ffc93a0cb90180','5b244e091feb919ed89aec9b583fb8c9964a86eddfd626f2682f0793786926a1');
INSERT INTO blocks VALUES(310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,NULL,NULL,'6ff899433f22546c41a15f20b4c66913c747931500fee10d58c4a17b9e2f0c88','b77c1d69b3ac7348e336cce9948f982efafa1cb56cbdde85fe9f49a73871ba3b','3787b0fbc5c17dc7f4ba150dfd0966a6db5dfb67088e435f130fe368ff8a1723');
INSERT INTO blocks VALUES(310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,NULL,NULL,'ec66a06cde401b66917c6d1d4e1ee8893405cfbf0474560d9997d6960c8af710','6d3d469ad1b72a67ee50d8a7c6c57069da3a0e2e9d12a23a30bbf4f2ccc64cb6','ef6563409b61b3b4479b95729189a482c8006a559ebac2998bbe05a9a8355575');
INSERT INTO blocks VALUES(310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,NULL,NULL,'b2053109bff06dae1705fc32ab0712f38bf9d206fa3517fbf0a938d1b5f33bad','223e10a8e23e4435e635f1dda533a0662dff9f0e3fb86b72a22b2c191f731a80','91a444e032604af986689fdae1572cb9cecd947321c1b03003665a798514675b');
INSERT INTO blocks VALUES(310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,NULL,NULL,'d7051de4d03fb31bfedf215b407b1edc12789c1f2748abb5a72257ad8f5113ce','9eb6f4683bebb675467829573cd2f7e3ab613d21398c5aef31ed389a40f3c48d','cfbeee22fb20d23e226650edb83035dbea270df10a4f44be475d8c45e6697480');
INSERT INTO blocks VALUES(310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,NULL,NULL,'35c95a70193ded2f9ee18254a91ce5d4834bb162fc3cca85dd432339257539b8','88220e5f48660f8b9e339c3afb65ffbad83d632164f1df8e22af2ee6fc18826e','e2aa61d05a41b52373e8493fe02f6e6598812c2f2a1cd28969d9b74fae7d3e95');
INSERT INTO blocks VALUES(310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,NULL,NULL,'8315de64ee1051c333687ba9fae6244287b85bcc1e3a4b67f3fe7d51b931378b','087de9b1715dfdac7372489fc615b597c9575c9520eb1ad5f7435a2641388621','399a1fe20e75d25794349dd947faac6c9318d9ce263f0c5074a9a14a7e5c8ace');
INSERT INTO blocks VALUES(310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,NULL,NULL,'c2d646bd3f54eec73cd9da6f5da4bc159d0c64e8fb9ad4095dfa58850e65c7b1','e5f36761a4755ebc133389b9bc01a085c585a24fa346c784123f3dd5a125ad27','bd81db38e4fe466c30dad46b8dfb83c06795a1d9a4ec8b8bb214da8528ab10a8');
INSERT INTO blocks VALUES(310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,NULL,NULL,'619367fb7657e0fb4800acd385eb5593d085ce5cbfbfb098dafa98612d9fd445','e62992a5e4f80347f92c512e1bd47df4c2f4e9fa0c38b7ca73befd39fd181d54','fd5aed4f82224f556564e111c9794e7e9d9faa8e5bd963eff1a568988d25629a');
INSERT INTO blocks VALUES(310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,NULL,NULL,'ba865dbc8263aaf153d7264dfc6a580bebe9391ca0551f15a1c822c6cbe2b8de','e62acd9368da6141ddf435bd919fe0e124bd77646207d69a2544790107ab88a5','bededd6079ef5367f411df9cfc1169b928aa5dd1c14f53efac88aed4dcbf720e');
INSERT INTO blocks VALUES(310024,'b03042b4e18a222b4c8d1e9e1970d93e6e2a2d41686d227ff8ecf0a839223dc5',310024000,NULL,NULL,'368e948cbf42de80aca51abe75d09ec78196924453719182ccc86419df5da2db','2c65dfdc0d371025c6d497e087b8548633238d6049242fa411383fcce72b096e','4c34db99df09b4a60253f026716cbcd11ee595802f2be74a6adfac886c174832');
INSERT INTO blocks VALUES(310025,'a872e560766832cc3b4f7f222228cb6db882ce3c54f6459f62c71d5cd6e90666',310025000,NULL,NULL,'9f7132c808936f580d4fb1dc5791541a5a3d23532d1093c20d434007f8dde54c','ca60850f73099aabc38d1521a94d611cc02f4539620a17488d1e9a445087104f','b894a5cf511aa832d56087e89985dc5ad6e5a7b068171bb30bf8a0f2377eedc9');
INSERT INTO blocks VALUES(310026,'6c96350f6f2f05810f19a689de235eff975338587194a36a70dfd0fcd490941a',310026000,NULL,NULL,'074ea6f10a5290cff31f7b21483f7b2248723c8d1b5bc060c31219f66f37def7','21db77ad7cd241752184fa9fd61ab9cf670cd40105d7d9b887d8df62f25e5cfc','ae0d316bfa366d6abddf7b31668637d368cdf1d2cc4c1edc7d0b8ea54ab3d2ca');
INSERT INTO blocks VALUES(310027,'d7acfac66df393c4482a14c189742c0571b89442eb7f817b34415a560445699e',310027000,NULL,NULL,'a3ade2b2e5bc701996f511f3e85d596b60f882a3254fd975769c0f38b3b14cb3','9469f4c4b4f208f2a46569234006846d18ae108ca6a98600ab70bac1ef1ad633','1d87d1b486bee3fb8cf4173d3d82a4cc1660f7a7d7d083f1b7ca2e2d77d59e17');
INSERT INTO blocks VALUES(310028,'02409fcf8fa06dafcb7f11e38593181d9c42cc9d5e2ddc304d098f990bd9530b',310028000,NULL,NULL,'3bf124a34825b5c487c94dd79b1ea4f25e657294966879f1c10b56b37a3d29b5','55de4927d0ba81d336f143b08224af9fe9a862bf0ed4d39fbe242e9c5946bcf4','05860b3837ca2776cfcf26b5d52f92f5c41209cc8947ed1b2fe7a277642aa715');
INSERT INTO blocks VALUES(310029,'3c739fa8b40c118d5547ea356ee8d10ee2898871907643ec02e5db9d00f03cc6',310029000,NULL,NULL,'e502eb7b282e0bd4940d8f75ef51d677a641f3d55304adcb015bc249c97892bf','3d879f96d783e70a75f71c2b44ae4c5601bc8f1192b828f1b35400b8c99aa0f2','89440eab5ad2bf512efe5852b4a17bd38bfc69ff3a1145eb3fb496da9cacb149');
INSERT INTO blocks VALUES(310030,'d5071cddedf89765ee0fd58f209c1c7d669ba8ea66200a57587da8b189b9e4f5',310030000,NULL,NULL,'d64b5eb04ddfb5600be40142b1fd27c308387a35942a6e8a6916407bbc1313b1','c859356c985f3c051d5b01424759e66e9ec7c2eac055eb9fc2b0ad7323253a6a','ed840710aee0b7c92f12c79a3f0135f6d1eca6a2120ad1290e775a2beab35d62');
INSERT INTO blocks VALUES(310031,'0b02b10f41380fff27c543ea8891ecb845bf7a003ac5c87e15932aff3bfcf689',310031000,NULL,NULL,'e9c97dd7adb1b22d4ed0238607faeb2d14c090fbd7d685275ee802ab23b4b740','4cdafec839c7abdda11f10437d890c952b3416929ff6e715f44e8c57412437af','0c70b1bb4f0a8382eb5a9737905082f7e1c9aa33b5d47be965b9d57262635e3c');
INSERT INTO blocks VALUES(310032,'66346be81e6ba04544f2ae643b76c2b7b1383f038fc2636e02e49dc7ec144074',310032000,NULL,NULL,'2544ffced9af1aabd84ab51fb78c56c9beac03dcb286aebd4202938dfa0754ea','2fc6c250a775ac70976d371540df4a7af608ca1b106b7efb7bc5a820ff505bdb','d47cd36f4432c135d7b987569f1e3ebb982972a235e6dfecc70d070fdfc32dbf');
INSERT INTO blocks VALUES(310033,'999c65df9661f73e8c01f1da1afda09ac16788b72834f0ff5ea3d1464afb4707',310033000,NULL,NULL,'4355d3ebb95187fec36b1847a4c3777d8e1d5541bd1d9ff8461b8ac5b9881261','d99b155e06fb50de6e7e6b646c641e3862d3d6df0ab9aec3e360fba0fcb54776','10718f4fa54baff4569ae3e2da50b470538276dedd602c7821834bbbf48d9a3c');
INSERT INTO blocks VALUES(310034,'f552edd2e0a648230f3668e72ddf0ddfb1e8ac0f4c190f91b89c1a8c2e357208',310034000,NULL,NULL,'c7fcb5134bd8131c035d65b5eeef8a3cd214348822563232a992f3f703c6b0b9','826d7b750bb4ad8fabd67c825c81f840b7a7a264489a9263410a5cb204d3309f','228aaffd74bc403a83d36e8bd3c2c77c4760c67532996f99d4935f0fd55ca4f0');
INSERT INTO blocks VALUES(310035,'a13cbb016f3044207a46967a4ba1c87dab411f78c55c1179f2336653c2726ae2',310035000,NULL,NULL,'c41c280498ce05d6073fc6e89be2684dc68c345c1c43c00b9a3f9041954fce26','f96598e2169d42d81b91ba03e7403dbd25a61399290f358022a998e4375fe2b9','56fd3e161a75a197c1ad427157a0eb01333b6a82dfba2da2bfa2e1ef3837b36d');
INSERT INTO blocks VALUES(310036,'158648a98f1e1bd1875584ce8449eb15a4e91a99a923bbb24c4210135cef0c76',310036000,NULL,NULL,'86c67fd234ca9d2406080018b2677386990fac477db8008c0092d40a398203ed','ae7fdf3e9388811e96d470070db9ac45b5b19754bb4ad424aade40fede3c9cf9','df4ea17c7804c1d6d9e5cff7b1d11c754a7cdac4db91b30810835595d03fd4ad');
INSERT INTO blocks VALUES(310037,'563acfd6d991ce256d5655de2e9429975c8dceeb221e76d5ec6e9e24a2c27c07',310037000,NULL,NULL,'3ae6272437eb0758a779d68785c41e119d1204dd5421c78e03b9d12eba64804b','aa9600ce32fd7c1d6e963a51648eaae043685d3369413785517172d1f94d551b','e3e3864d0a17663467b274dcd6feed5d4025b8fb4b047561eae7c7da9623a993');
INSERT INTO blocks VALUES(310038,'b44b4cad12431c32df27940e18d51f63897c7472b70950d18454edfd640490b2',310038000,NULL,NULL,'18f7552567b898f6c2cfe8c829903912445de5dbf05b56a13bf9b402a24fdc11','46ce886f050bf7a80355da9cb15b35f5d38809ef2ec1a25250f057b63f51cdfc','77beeb631f64157640ae1141ac68c7db2130377cccc136b79807a8718930f932');
INSERT INTO blocks VALUES(310039,'5fa1ae9c5e8a599247458987b006ad3a57f686df1f7cc240bf119e911b56c347',310039000,NULL,NULL,'85f2255f9256a5faf59ddec1c58b1d3bc12c91bc2c62ead61b48e1f94ea2888d','23a26edddf0c8662b055ed992c75c706221b59ce9a7aa45b757a3d5158772e8c','9064602b9d21f6886fa924facd00b443db5e5ed73379e8cc682255cd0c651c24');
INSERT INTO blocks VALUES(310040,'7200ded406675453eadddfbb2d14c2a4526c7dc2b5de14bd48b29243df5e1aa3',310040000,NULL,NULL,'b799477db184351df5503f8d15d5461a0483ea35142c003b7e640429663ad943','163682e05a9a10f3e3240420c932a7f3f2172484de30dbcac0319ac23a4726f1','8da80f6c9094635b7be238d6b6e9a9f2f3bac8a85ec615d3e640baca01c8e56b');
INSERT INTO blocks VALUES(310041,'5db592ff9ba5fac1e030cf22d6c13b70d330ba397f415340086ee7357143b359',310041000,NULL,NULL,'efa9cd46741b59e74263d6d348584f1a61e8ba32163c09fc3ff2e41a5431a483','a159868ce28207aa243e7ecc50f188e8e34e5ddb5d801b645b1c16a596e060ed','205ca99a5f70548d81d3e0fa2156410652f3f807f5fe6232aaa9c26d5c453596');
INSERT INTO blocks VALUES(310042,'826fd4701ef2824e9559b069517cd3cb990aff6a4690830f78fc845ab77fa3e4',310042000,NULL,NULL,'f3159919f381d46a3e1341703e55192a02a36519e71fc2675285a3a14c4ee04d','52bca7ccb83bfe83d8693ebc4c5b1ce518b2ae472dfc81f2c2940dc2460eeeab','d5501b31bd43f47559d1e94c674ede53bcaa4406cf43d3e6f85752325315a21a');
INSERT INTO blocks VALUES(310043,'2254a12ada208f1dd57bc17547ecaf3c44720323c47bc7d4b1262477cb7f3c51',310043000,NULL,NULL,'961c79ea2b7dcc2d7489c423b568fb978631e71732d6b998bcc0657aa4d19194','1fa2eb6aa4c8b5efd093c6e484dddb85eabfa0de55edc929e04487ce65e73608','b65d9e08a33e46b455881632f2e6c36986f02c5e5eeda0fad98d10e234ad0261');
INSERT INTO blocks VALUES(310044,'3346d24118d8af0b3c6bcc42f8b85792e7a2e7036ebf6e4c25f4f6723c78e46b',310044000,NULL,NULL,'d674c39010fd4554efa487d97a3d9cae278ed9b4aff0ce57db33bd881beeb3e3','ddc2517e1efddbe56185e00d77333ef9f2f2ad6c59e042d65a8f4d8c2b323e5e','4c368ce7a7f95221458ced06886428938d71ad540b311b4b32dd3d5e1f84e1d6');
INSERT INTO blocks VALUES(310045,'7bba0ab243839e91ad1a45a762bf074011f8a9883074d68203c6d1b46fffde98',310045000,NULL,NULL,'9ba70a032ae92672174421689c0845784f0cef7374e88b2f5258260191864bf1','3b1d5cd9cb8e7b753233ac0dac5e697226ae372bff3813852434d96996e78fac','2c067f81c1daae2ae6ec79757af49547e0573d321bbde55ac5d93de1d9374baf');
INSERT INTO blocks VALUES(310046,'47db6788c38f2d6d712764979e41346b55e78cbb4969e0ef5c4336faf18993a6',310046000,NULL,NULL,'114a6ab930fbdf8531431620ed219db3756a634c5b99af6ce1ee66d527d277ff','becb4b0241accefb95aee137e58d406e15e87c28ed3f051938b4fc02e249b21c','780019da2a4ff8eb8090cd1b92194358fe5d43d63c735a51a70e0bdaa175043b');
INSERT INTO blocks VALUES(310047,'a9ccabcc2a098a7d25e4ab8bda7c4e66807eefa42e29890dcd88149a10de7075',310047000,NULL,NULL,'5356512c94ea2c77623d874a927aae8c3dce287a34dfd27a617abfa57142c7f3','6e06ce8a113de9e8b1a88516a512671aa2cdef60168a40d91742caa281417634','e8590540dcd376704d921b79d227087859728d7316b882179e6131ab3096385c');
INSERT INTO blocks VALUES(310048,'610bf3935a85b05a98556c55493c6de45bed4d7b3b6c8553a984718765796309',310048000,NULL,NULL,'0902ca0868560d05049c983bca3ab91cdd5eafc46ab0a948d702abcbc4010582','67a2fb81ebb42dc6781746a403d81b4e7603f82f02724074541d42380d7269fe','51959c28679ee1bc313d3e644e9cd90a5940bd63f882cf9c591e7fde09e07554');
INSERT INTO blocks VALUES(310049,'4ad2761923ad49ad2b283b640f1832522a2a5d6964486b21591b71df6b33be3c',310049000,NULL,NULL,'978794628fc95756032cb7fb4e9d5ed286373d84fafbcfceec9af71d18c4c0be','ac68aa21454eb2a2ca973b5451523fc6d2a4df6906b9472891cf8e06087e130c','a0f38204999559d9bb981ee601e12c66aef069c3111f43e73822d6ac6cd37e9e');
INSERT INTO blocks VALUES(310050,'8cfeb60a14a4cec6e9be13d699694d49007d82a31065a17890383e262071e348',310050000,NULL,NULL,'ff16abeb1d35e0e422f165e206b0d69e0b9ff48b68fc6656c1af74801908b92d','720d553ed03860df12ab60af34cfec86b9d7ec80275f6d8815e3f61166e3af88','4d93289c0de9d68188482f63c601c2b0076d2326495db73c68510729830b446a');
INSERT INTO blocks VALUES(310051,'b53c90385dd808306601350920c6af4beb717518493fd23b5c730eea078f33e6',310051000,NULL,NULL,'556ff900993e70cabefd05ddd5dbe3e8e10bb5c9ada7913b75d84af067004ed5','656a21084dc8f46455fd2a42ebbdb0efd5c879ccb16e9b1532a6ab5323debdb4','06b3f2325eea2f9902a66e4c43e8aba98f05ad2c550707cb536fa2d0d0c51a16');
INSERT INTO blocks VALUES(310052,'0acdacf4e4b6fca756479cb055191b367b1fa433aa558956f5f08fa5b7b394e2',310052000,NULL,NULL,'15af3a616a2974aa70b7b58f88132051f335af299473db925b619fda8be1afc7','3f90b36b7ebc9a2daea1e498bb44100f12f35c9df04260448bd38b23375b16be','a71b134198aeb081b672f80581fd3f43d3a1b53c5b99b67b0c8b5a0c71ebf058');
INSERT INTO blocks VALUES(310053,'68348f01b6dc49b2cb30fe92ac43e527aa90d859093d3bf7cd695c64d2ef744f',310053000,NULL,NULL,'ed0ed3b480b38929a425c2b61c86582495764624e020cb86b3a95fc7d59c692c','67427731be09b73755cd460d142686c903b819b7b8af48297d460ab91fde3609','a787a41c4d06fa5b1477e30a3217174256c6ced1c2635087a6ba9b596233529f');
INSERT INTO blocks VALUES(310054,'a8b5f253df293037e49b998675620d5477445c51d5ec66596e023282bb9cd305',310054000,NULL,NULL,'f012825d2d549910910ad6b7e4ac2373d095b53869f0793709684f0ff05bb108','c5e4ba3e2011e7fbf238285525a544de3cc0fe9360a3451392a4c03acd508690','b32885e9a5da8ad45a701f58e2f7a4174d1965eb1ae6eabb262ff9b4044250d3');
INSERT INTO blocks VALUES(310055,'4b069152e2dc82e96ed8a3c3547c162e8c3aceeb2a4ac07972f8321a535b9356',310055000,NULL,NULL,'90c08144277fe622573282349edaf9e59289b716b5b4e368d88ac25e67e788d1','5e4a8aee5f04d75d9ffcc85e8344c445b5facfc838f39a77b6b0d5acf6cd8213','48acd75fa3df7585470e5151d1ca9bdd2a9363ba5e933d8430cf0846955e0d1d');
INSERT INTO blocks VALUES(310056,'7603eaed418971b745256742f9d2ba70b2c2b2f69f61de6cc70e61ce0336f9d3',310056000,NULL,NULL,'c888ae590b64fa4514ed7f94ba785b12e881052185cc4702b598cf6e48cbb3ba','1cb780a12bb6040055fa694822a4f39c340a18a858f0b65a8b227a6fd6fb4f31','f52e3916a01980fdf2be199125045f18c47533dcf33e99d5d200cec1346c7170');
INSERT INTO blocks VALUES(310057,'4a5fdc84f2d66ecb6ee3e3646aad20751ce8694e64e348d3c8aab09d33a3e411',310057000,NULL,NULL,'e68c9a569fda6f1e1e59502953c9735857a0ee158a76397722436466df24708e','2e175f240928edbbd5a5c6c5f3fbacd9516a36c7e99501703e9d1b19999b2029','bba148acaeb166c819205f9a679b784ebe3f8bc34db8391487115e87019e9b2a');
INSERT INTO blocks VALUES(310058,'a6eef3089896f0cae0bfe9423392e45c48f4efe4310b14d8cfbdb1fea613635f',310058000,NULL,NULL,'9f6607682f4a6274c2a45895f849816aec83ff0820709ba781634b84518eb05d','cca92bb672e368c0c1e5b4674a48e150a870f56a67339cbd74926d541ae2a4e4','7cefdc6020ac271318e5b88dd8068d5448a929a8a281d51a136b25df72809a53');
INSERT INTO blocks VALUES(310059,'ab505de874c43f97c90be1c26a769e6c5cb140405c993b4a6cc7afc795f156a9',310059000,NULL,NULL,'49b10a5c390f603e7be0d405bf1fcae95fd15682ef2e41a3b2fcf713d271e541','12b8b50b634cb6843258f1c130df1cae60898c902d3e66ad00e1303fde4d8724','b43a3e23fa5b6f80feaccc18f8322de22a89122b0738e6eeb4bc215dd607870d');
INSERT INTO blocks VALUES(310060,'974ad5fbef621e0a38eab811608dc9afaf10c8ecc85fed913075ba1a145e889b',310060000,NULL,NULL,'1d6cea34d6f7042ced3a5211da80de88fa77c900af5526f3033b715e4f68df17','40fa40a1a2c02ca514f309fe27268e9e493374bf3edfca8de66e3d46efa32ba6','8bba4830a2e412f871a64c840b4373de0e71ca413fb2eb0fe377be0a1a07e25e');
INSERT INTO blocks VALUES(310061,'35d267d21ad386e7b7632292af1c422b0310dde7ca49a82f9577525a29c138cf',310061000,NULL,NULL,'0c43668fdc3d6cc6ec84fee99c68f0eff21650a618db35bc20e428550eae9b0c','4aa0becfc939793d7dccbb0b19881889a20c801e6c627be8ab8a2ffbd8cee8de','4eda1f020ab67e02ecef314948a95ccdab85405c599a68f91df1b9bcf2a20a5a');
INSERT INTO blocks VALUES(310062,'b31a0054145319ef9de8c1cb19df5bcf4dc8a1ece20053aa494e5d3a00a2852f',310062000,NULL,NULL,'cf03a34b29d3a8f8ea5fadb017426f2843c6ab2e785032b6dec70d7aba7bce4a','3317013c1e6464e0296f5aa7f50208ede42ff9051e4e3ce2da92584cb80a3079','bdeac1cfad5e574e2623c223ca298eace0533421bddd16b56ddd41a1d6b3fbb1');
INSERT INTO blocks VALUES(310063,'0cbcbcd5b7f2dc288e3a34eab3d4212463a5a56e886804fb4f9f1cf929eadebe',310063000,NULL,NULL,'e145dfc2c7f053a1ba4c8a41d042b40c0748eefcf9e56c5e906ad4b12f3653eb','b58f95d06b31f7bb5c6f6bd5c5c4460ef4e4ce0e1d154b8557a18cb73f36d432','3384f7e8da50633cfc2fd3608add81b4f4bfc196f5e71f55b0f7e3b01d57fc0b');
INSERT INTO blocks VALUES(310064,'e2db8065a195e85cde9ddb868a17d39893a60fb2b1255aa5f0c88729de7cbf30',310064000,NULL,NULL,'ebc34184623da16251782c82098c7fcfda42f95b155eadfacab2a53e3b34333e','e33ac70126559506de70ca420f152dcb639fd0e841d0d7259c0136d518fd4f39','fdff932f664bc91a6086ad459f1649fe10406d4c3c54dc40be1b18343c8a340e');
INSERT INTO blocks VALUES(310065,'8a7bc7a77c831ac4fd11b8a9d22d1b6a0661b07cef05c2e600c7fb683b861d2a',310065000,NULL,NULL,'db746a9e0ad8f37c14ef14180dd1bc562ae757a6d4d042a517bb8953f34c6958','9d52ca0b8859777bcbe84606017ec53961075699eff51b34b80e5a6ed33b137f','d2d330bd0b5274f1240f3aac53f2a1f61e01c793c0c78fe9d49001ed594ef488');
INSERT INTO blocks VALUES(310066,'b6959be51eb084747d301f7ccaf9e75f2292c9404633b1532e3692659939430d',310066000,NULL,NULL,'cc71a63314b770e4e010bc7c66d8ab808451b6401e6df8558455a2bfc9bb4882','5122312265a8305639f6490bc51fb025626dbcd38c5735ce85cd652348f2e86e','9264be9211acebd61404813252d3ddc86d1bd009729ab4785a905d3b6277d691');
INSERT INTO blocks VALUES(310067,'8b08eae98d7193c9c01863fac6effb9162bda010daeacf9e0347112f233b8577',310067000,NULL,NULL,'a5812c0f3a37b04d5105bca6b0c4819a41beeedf5b0f314f476ab55d6c31235d','764477c3a233cd407804695f42948d3017951e90b7474cfcc24ef81ee49fdad9','51a40440527c9f90fd211acef06f5f739d6e291ab248d03fa1f5a08a7c56646d');
INSERT INTO blocks VALUES(310068,'9280e7297ef6313341bc81787a36acfc9af58f83a415afff5e3154f126cf52b5',310068000,NULL,NULL,'14f065751896a2724251b6ca6d0297b344986980075fb72ad058ad0b5bedcd3c','866fceb74e8e97d663493f3546519b01f51e1a3cb25bde4b0f3c2e960d2eda85','eb0762c42cdf4f7e5170ba3562c8fd3ea770f966315be1d90784d7245c46736b');
INSERT INTO blocks VALUES(310069,'486351f0655bf594ffaab1980cff17353b640b63e9c27239109addece189a6f7',310069000,NULL,NULL,'a7dd17b4760fb65ac58be1b1653f7cb0e90574c47f70c61ff9f940ad15ad3658','9e0565827fcf295ae2149bfcf5e0db29237f447760832083baf94de145bdb531','f3d7f34ffc53c99d4528d1b55a7b525829f640bb2737ccc5a89517dbe9df2a74');
INSERT INTO blocks VALUES(310070,'8739e99f4dee8bebf1332f37f49a125348b40b93b74fe35579dd52bfba4fa7e5',310070000,NULL,NULL,'8068a6bcc5d1fc1a78562f0f3165423b45b4674e55f21c4c09948fb65ee632c0','03f84e0f0838204a53ce54e3cfecde00b2e5741ed08aab0c0d9ed99513ab4655','106e2361f138370ad5fa515a00a1b86c78b76ea690a349043adb991ef013579c');
INSERT INTO blocks VALUES(310071,'7a099aa1bba0ead577f1e44f35263a1f115ed6a868c98d4dd71609072ae7f80b',310071000,NULL,NULL,'af86ffad4b8dd68a0f18142935bbb18623cc5ce2e9e0c02f04c0e7a5dd974e17','9b3e1c7af0bb119e69813161c19aeac4dd5a594ece5f67f21ffb55b8edaa111f','a8a6ac8374ae71a3ac5468227f5d0eca29761cc648285dfecafff6177c72a438');
INSERT INTO blocks VALUES(310072,'7b17ecedc07552551b8129e068ae67cb176ca766ea3f6df74b597a94e3a7fc8a',310072000,NULL,NULL,'36de48518d1446b33f2230c5eee7d18e040db543fe03dca001174f8382c209ee','33fccfbad1dd91d9102b82f11b7c97883bc5d5fdfd44584cca6c40fbd04ce2d8','22ad8e53c7345473bf4a76ea43f2a97900db53d7b7f58d3775ed900448211dbd');
INSERT INTO blocks VALUES(310073,'ee0fe3cc9b3a48a2746b6090b63b442b97ea6055d48edcf4b2288396764c6943',310073000,NULL,NULL,'4374f567cbc460b73e74d6190db353c3ee86b92c3f99e392beae3caeb264eb5f','7544980dbaa8029ae36d883e3079bcc82f2d140072d4dd65cb3384510692ff45','4842e2efb931b3fa5b6ead4e16250a7295855c25e47311fdd7b4eeac68c030f9');
INSERT INTO blocks VALUES(310074,'ceab38dfde01f711a187601731ad575d67cfe0b7dbc61dcd4f15baaef72089fb',310074000,NULL,NULL,'54fd95cdf7f9374d1687590f2860276afe67a265ddd9216e5b63fb06c5bd569e','1efba9ea6a8d2e7ee6ee2070b84b497feb66e3387e05c1e4f4989f086e5e02a2','88479094bd18fe5094f4d148f4dc3f13d742d935652a832e2ea5c1e1dfe37544');
INSERT INTO blocks VALUES(310075,'ef547198c6e36d829f117cfd7077ccde45158e3c545152225fa24dba7a26847b',310075000,NULL,NULL,'2b42e23b43d30f91fe7705a01f0c8ec86d6230815b587704bcc70b91b5ae87b8','a370830ef1758c18c88e6d9fcc5803fc15f1dbdad0f2d6a0773f902d86ad7c97','f5d103ec89acbab7ad6b9ef52f89246954f0dd3ebb37966875168c9312571dc8');
INSERT INTO blocks VALUES(310076,'3b0499c2e8e8f0252c7288d4ecf66efc426ca37aad3524424d14c8bc6f8b0d92',310076000,NULL,NULL,'577092728a4dc81cd9a06fcf6d2b058f0e4ce8bcb395819a704d6b4144f041dc','05ce95f07d03f4417a2fd15224418c8ba4ae196e9ec6f3192f5324c028363641','9241b9191eea89bf2340fde6217275422b209cef1daf89fcea30b780942fbe42');
INSERT INTO blocks VALUES(310077,'d2adeefa9024ab3ff2822bc36acf19b6c647cea118cf15b86c6bc00c3322e7dd',310077000,NULL,NULL,'d1ba60181f3061673c64ecd0b92abbc19b1a6e69a927dfefdfd8b8c74171ecd2','6c9e35feb56fb01c37fce04a1e6dc5f7747a6d26ee2f39ac584f11e8359dce71','f86f40615f542bfed8f99b470ba2f256695035eddca3e441892c778ca57caa6d');
INSERT INTO blocks VALUES(310078,'f6c17115ef0efe489c562bcda4615892b4d4b39db0c9791fe193d4922bd82cd6',310078000,NULL,NULL,'c0a9270d15793e68cfd1cf445315d737bed7052914da6def4f014c21f0c9e0c5','d59b48425061f0965947dd025cfa0fba8855e997f376572c585db72203b9a80a','38a8ac7d89d133a9bf9b5bb45b6777e297c2d9996326c6bb15d822de482abbc0');
INSERT INTO blocks VALUES(310079,'f2fbd2074d804e631db44cb0fb2e1db3fdc367e439c21ffc40d73104c4d7069c',310079000,NULL,NULL,'74eaddecbf5ab6608c1e95c1c313c13f2af2b649512cc8c7016717d21e93f815','d3f32df02f0e7cd7c2163b47b3ff73d175046599ed626ab343647e1a04525e3c','21c3cc166cc2cae0f92eb5ddf3fa756b250a727a935b664e84e5ee9ba37a7eb9');
INSERT INTO blocks VALUES(310080,'42943b914d9c367000a78b78a544cc4b84b1df838aadde33fe730964a89a3a6c',310080000,NULL,NULL,'a759e3aac1b015e28b8b524106a74b943b215faac8d5079384ec7351b2239bde','f588a6cf255e710d9ee481d53f8bc0fc0e1567d58ee701f1b77f0848db881f5f','bedcb19a30346c7dafb69826612a0564e51e0e9f4f95ad5763519051021479e4');
INSERT INTO blocks VALUES(310081,'6554f9d307976249e7b7e260e08046b3b55d318f8b6af627fed5be3063f123c4',310081000,NULL,NULL,'71622e25e8497db6fa222e33c60ea582698e72ca5789a52c9252bf51191cadaa','9a2e169d5fa3721f9bb8852c93ca8ed5dfbcccef05cba99ed3f1c61c937f4366','9cd1f9762e0f7ea305e2913d83e5582c661fd1c80391bf6f66a84c32f3e57256');
INSERT INTO blocks VALUES(310082,'4f1ef91b1dcd575f8ac2e66a67715500cbca154bd6f3b8148bb7015a6aa6c644',310082000,NULL,NULL,'47e9d8fbcbafcee2b4c145ce651333ce49812533d13f7f9a0e9a448f51cfbacd','c2cd395566e0a7b16c76cc0ead2c2cc87a684d5a499c76b2370afffe4b408ad1','b7c57b8cde728e5d2e066a01f8504c2ef7a0f991f39b4fdb287bd1f258694ed5');
INSERT INTO blocks VALUES(310083,'9b1f6fd6ff9b0dc4e37603cfb0625f49067c775b99e12492afd85392d3c8d850',310083000,NULL,NULL,'e61148e7a8125f7225a6b6e1d77786f8b28b0b8a74e60fef3f75fa4de8f7d882','21fb4596655071cca486c2e6988ec980799a9827e2e5f169033a45d21b3c7a75','a20637035f78b8a82db3b641c718fd57e21a6ae073d70fee0dd9864d6fc41b9c');
INSERT INTO blocks VALUES(310084,'1e0972523e80306441b9f4157f171716199f1428db2e818a7f7817ccdc8859e3',310084000,NULL,NULL,'20fb450589ddc6c904fbb61cca8588e85e865635c12402ce7ae72995ab884c14','feb3992f370b8465a732bc4d90691b99db691f44e1697ad2775a6df216d93b13','923c36a16f2bf594c627528028b5ffb7641d99ceb5ea38a450f6fceffc226547');
INSERT INTO blocks VALUES(310085,'c5b6e9581831e3bc5848cd7630c499bca26d9ece5156d36579bdb72d54817e34',310085000,NULL,NULL,'9cea37d548308505f80dc438d5183bac6c6ca424ea4dd9c85d883b05d67cdc92','277205c28e54078d55ce1641fed64ff4b409b686fbe4aa3a018cead2f969c501','072195a0c3b8f8702b095e0fd68f7c3e5a73c2b4f7c56e7cf43d8ee6c9dceb82');
INSERT INTO blocks VALUES(310086,'080c1dc55a4ecf4824cf9840602498cfc35b5f84099f50b71b45cb63834c7a78',310086000,NULL,NULL,'e11bab5fba2d038086c65030b90ce1cbc988314d0c9846aa7ddac4fd357bd01a','ef3ac1de31e29795732b362218bd244945bea4183273512ff6974ecd0c0a7aef','db8fa0ad3ad8a56661e240daf33b69225ff97976efeef24cd895c9654a9efa64');
INSERT INTO blocks VALUES(310087,'4ec8cb1c38b22904e8087a034a6406b896eff4dd28e7620601c6bddf82e2738c',310087000,NULL,NULL,'777873e7ebd0ec3052be65197ec0db8bd72e46d2053badb0f37be1f6e84ae0b3','3bec931f7207a5b03e5a7d390787cd737e598d04025a1514c7654ef34fd1aedc','a75d37034c8ddcd7daa36d0773008d364faa17b9905dc90a37968566385b6db3');
INSERT INTO blocks VALUES(310088,'e945c815c433cbddd0bf8e66c5c23b51072483492acda98f5c2c201020a8c5b3',310088000,NULL,NULL,'85a5ea57af33dfddddbcbe1a1c87994efe5a21a645713aa164f19e19bfb23c64','4030ee911aec8ebfbbeecede9cfb977088fb591b20cf52d5340e5aa13e41c7f7','beb8652cf06561dc6b798e78f0e7dfa8921cd9aaf9947ce84e3bb94d9ef0732c');
INSERT INTO blocks VALUES(310089,'0382437f895ef3e7e38bf025fd4f606fd44d4bbd6aea71dbdc4ed11a7cd46f33',310089000,NULL,NULL,'bdf3b6e7a14a3aa22d42a7d69f2f96b0993f1eef2952a7d74313c37e1b407523','255675a022762a349d44af6315173e05c685f351f2b3b770e0ec80e128969a4b','ba21f03b582bc6698df762342fe26df04c6453836bf6ea35353233975dc85d58');
INSERT INTO blocks VALUES(310090,'b756db71dc037b5a4582de354a3347371267d31ebda453e152f0a13bb2fae969',310090000,NULL,NULL,'9b3ee688c5786ecc438ec9c843ba5f898fe1ab1a8bc3903ad7789aaf6b0c0bf0','7d658801ab6fbe73231469da5204c5e1c73d290b83449187ec5eec71b846616d','4b7fc45182433ce245b2faaa42bc134289ac0a338377b56b9191808c96315af6');
INSERT INTO blocks VALUES(310091,'734a9aa485f36399d5efb74f3b9c47f8b5f6fd68c9967f134b14cfe7e2d7583c',310091000,NULL,NULL,'25578ac389a77dbf9589b23c5470f3199016ac66a415540ae03efac29dfe7adc','1cb14bc9f998c85e670e2e291cde3a2debe9b4013840c0c060417f509c7210ea','ce8b45c4d106659a3acba781929a52786f70ffdec9e65fc5da3169ee30d3bc53');
INSERT INTO blocks VALUES(310092,'56386beb65f9228740d4ad43a1c575645f6daf59e0dd9f22551c59215b5e8c3d',310092000,NULL,NULL,'bb9109ba299c99cb104ebf2ef6e75141c50264d701d27119525ab5d0a54c1a40','889afcda8b6e0848c7d43014beb0e181c78fa69d3aedec508f4bc0eb8a416029','b0bb48b2ccd92a8bcdf13e46882f2e644bc2cd79e6d10721e3d97ee4cc6a7a2a');
INSERT INTO blocks VALUES(310093,'a74a2425f2f4be24bb5f715173e6756649e1cbf1b064aeb1ef60e0b94b418ddc',310093000,NULL,NULL,'cdb21362b3eb4fc10ba3c6bf3aba41bfc5bd0bf2475f742c1069cb4383be7b95','dec762d55ba88cb2c043f627b2a8b26c920cce9d4dc2746065c0bcf2795c2d99','233ffeb528d1f022f8d2ea4a60f5df0a6f479c84feff64cb37a1272916ff9433');
INSERT INTO blocks VALUES(310094,'2a8f976f20c4e89ff01071915ac96ee35192d54df3a246bf61fd4a0cccfb5b23',310094000,NULL,NULL,'b82568de09fe4ea06f3dca053dbcbcc61dbe5e44dd300a4301c995ba180f894d','625beebc3c34fa3276e022a37c79137c8f09af21454e8171cce7ab7a04453047','0b5eeb8793b5c39faa7970b36b089b39a5053c0303f3fcc948a4c7af300b9791');
INSERT INTO blocks VALUES(310095,'bed0fa40c9981223fb40b3be8124ca619edc9dd34d0c907369477ea92e5d2cd2',310095000,NULL,NULL,'513c4a041ee80ba72d1d8428605c682e3485fa45341460bc33fae6540dffb571','b7794e7c8dfe3947ab8d256b94af8bc43acb9ca11f696a81cf9ad98062372959','0991d3d9a1c16bdae293da4704a103255b4c9dbb4e269d6a708086a8b94a2fca');
INSERT INTO blocks VALUES(310096,'306aeec3db435fabffdf88c2f26ee83caa4c2426375a33daa2be041dbd27ea2f',310096000,NULL,NULL,'3e8ff43c8d671159355b2d40a995fb8f6d84f6216fa8326fa80ae39aa9d15d03','8117c5400c1cfdb97456cf3b79e8572aecf23c29d1c336d5543979d0e81cc158','7814291465e2a3095c6b54b0e19197cf51744ced1a59009f48454c22cc959609');
INSERT INTO blocks VALUES(310097,'13e8e16e67c7cdcc80d477491e554b43744f90e8e1a9728439a11fab42cefadf',310097000,NULL,NULL,'19d91de7be12136737d3f8990e7a4a793912c952e71e017d723d750118e849c6','1e2f99bf2c03b8c915bd23c94431002d3801a13caf40d9b42f22001c2faf305a','659e00f8e3e704e249e542b3237f9296b074a98b6eca193973b126cec13f47bd');
INSERT INTO blocks VALUES(310098,'ca5bca4b5ec4fa6183e05176abe921cff884c4e20910fab55b603cef48dc3bca',310098000,NULL,NULL,'be75df2e5aff3faaebfc0ce4ab5134790fa728f84500e6989739dddc058738de','7f692426eab57621527d12cc4a49aa85841de9856cd46ad6992a658ed5c15fb1','362e5a812e77bc02d26956809709d0ded4f70821688534607a468c179dda529a');
INSERT INTO blocks VALUES(310099,'3c4c2279cd7de0add5ec469648a845875495a7d54ebfb5b012dcc5a197b7992a',310099000,NULL,NULL,'9090b8a4a26ea7dff75658317ce2c6ab828b3b42684922e44debfd1bf8330b8d','c3b0869da7bd7abbda54895e6de81cffd2febe007e1f7085da8cc657512278e6','563ccb48a597e1c80dc8553d6ecf65e4b2f7c9aa2ce2db6fe8dc55a4e17714fe');
INSERT INTO blocks VALUES(310100,'96925c05b3c7c80c716f5bef68d161c71d044252c766ca0e3f17f255764242cb',310100000,NULL,NULL,'d48d30db433bcee44d87153fb3db17d37fbe3534f23eb16ac853b3420d86d80e','793627f8b7de24827faca4a19ce374f39c90b74e278b83a599cb637877bd6388','562c854faed9ee1b116624d1c25f21a0f4daf3687c5927595ca77719f04495fc');
INSERT INTO blocks VALUES(310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,NULL,NULL,'53c6f9247cd255c86a69c05c4463ab94f9a3277496c155398c38dc6f7121fe9b','7388dcdfb1f5a54a0d4a4d3e50d486b24a662cef04f054a582e2d5b0bcf3ca28','d40ef2f397e30a8fd78a3ea375696fb1b4d5a1da0a15411cf45ececf1cd9a6f7');
INSERT INTO blocks VALUES(310102,'11e25883fd0479b78ddb1953ef67e3c3d1ffc82bd1f9e918a75c2194f7137f99',310102000,NULL,NULL,'b225c48fb4c40b2e0695991251f6d69217df6e00c01613e0a20f6a3e34f50d5b','7d553f87ef9f2beea74631e2e6ec107522b9f4756f041e2ee40fa3946909b3dd','a126dc9824e0a182cd5172648efdd12cccb1618d79c65b7b56ddf1fd37e82dd7');
INSERT INTO blocks VALUES(310103,'559a208afea6dd27b8bfeb031f1bd8f57182dcab6cf55c4089a6c49fb4744f17',310103000,NULL,NULL,'fc2a8ce8efc122e5cbd631998e611dc8707cfe0b8d3f6a531fe5bcc21c17feae','ece7991721b8e94950e2a9f41b9285b34be716340a7621b1c1528f8065e9ac28','41c62ec1789a651252dd8d949d35e34632b3eb09c00a1dd97517c5e8716eb91e');
INSERT INTO blocks VALUES(310104,'55b82e631b61d22a8524981ff3b5e3ab4ad7b732b7d1a06191064334b8f2dfd2',310104000,NULL,NULL,'b1a7115902d371d13889008320e52473cd5b34591bd657e372c0048df020012e','66dacde33bddb633552c94d9107669297fe26ccdcf482f9098f1e6c05f3d01e6','87689a1faf48f5bd4ff9113a498d2d4e16fcbc5c7699e8e820d382aabc820a71');
INSERT INTO blocks VALUES(310105,'1d72cdf6c4a02a5f973e6eaa53c28e9e13014b4f5bb13f91621a911b27fe936a',310105000,NULL,NULL,'b5fcda12415e713fc81278b95515fe86ecc6beb5810e4f80eb9645f09870dab0','656d27bdbf841c33dd3c11253159dc5d8a6d7885db3174f4f9c6a8382d6a7209','1038cb85b5ddc04a4e75cbdb2c137408cbe8118c0e0ffbd4d72c72eb84002f74');
INSERT INTO blocks VALUES(310106,'9d39cbe8c8a5357fc56e5c2f95bf132382ddad14cbc8abd54e549d58248140ff',310106000,NULL,NULL,'f3c98c954cf939951d8b24a257bc6b1bc152a6a0bcf6b580ac281c26bbf16499','6138a4e92289d72dab6e43906e545dcc3d1475102b7f33195118de74a53fe576','54a5509ff4caf654c17df14e637e3d88e88c6a20f689f985bae24bb5bfc26225');
INSERT INTO blocks VALUES(310107,'51cc04005e49fa49e661946a0e147240b0e5aac174252c96481ab7ddd5487435',310107000,NULL,NULL,'a550df26b8dee075bee82fc59c44ce5cbf65fe9df10c60f3f3009faa2791c783','b30d22c6d7e8bf574e3b3e11d08bcb73c5853ba348e8688a25670a861d3f4e3a','54aaf1da7c27187fec33d9886418c43665bd9bfed524758b50ba22b8cfb6da20');
INSERT INTO blocks VALUES(310108,'8f2d3861aa42f8e75dc14a23d6046bd89feef0d81996b6e1adc2a2828fbc8b34',310108000,NULL,NULL,'e1d8c345c74760010223a823895471d3ad6a2db5c6a70b13850d5cd977414518','d03bdcdbb4980ea415ab73c8e91a7fca7099c8c176d6bb4c2fdf72b6873175ae','3f7d829cc9384906983ef46e45861e4f83f0b62b4d6dfcd1595f44127e65ed87');
INSERT INTO blocks VALUES(310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,NULL,NULL,'8fb63d8460a222163d15eab76a61e383ffa251a175c16f209648d6782c304059','cff81539539169771000a550581dbdf4d4d1fdabecfb9032342269ff5f100b61','6e14ff94299f23858666703adc12e901074fbd6a9e3f41eb173cd37e5f0516fe');
INSERT INTO blocks VALUES(310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,NULL,NULL,'250f7b5c6f00bf06c9cd4de8dea0b8166e2decf093910ea32eabd615b910e7e6','d6853c803a38efdd5190401e94244333cb4f46752a2868d4a03e6d7d6c8c2bad','4836269143b8561235eabaf3f739f56d53a610a0f65d4b65d37fc7bbef2a4316');
INSERT INTO blocks VALUES(310111,'fde71b9756d5ba0b6d8b230ee885af01f9c4461a55dbde8678279166a21b20ae',310111000,NULL,NULL,'0c3c3d099bf08803f67c2a77d0d67779674d1063cc72d8794b8fe62a55049d75','9cab90baa72446a36a7c176e82eed32ce968f96b0f29067b240a10a71ed95808','d1bba1d8d50665711c374fa195aac33238be02b525183c502cc66196904d6a64');
INSERT INTO blocks VALUES(310112,'5b06f69bfdde1083785cf68ebc2211b464839033c30a099d3227b490bf3ab251',310112000,NULL,NULL,'557fdd1240793f8607a2b4c638ce800d5260c2adb294aac95d6c5eab7e98c3a9','4fc0df4832258d430e645f1950407e19e72ea27d28b8ae1851333e8e8718086b','19a996be3b3b673c4d21755dd74c156fa2fd70fc2a411c25547b8b131b7bed5c');
INSERT INTO blocks VALUES(310113,'63914cf376d3076b697b9234810dfc084ed5a885d5cd188dd5462560da25d5e7',310113000,NULL,NULL,'4ecad4a5c8e9b54101c4a037d6c86a7eb36d3cf0503e60a1bf13c5a4196c5989','baf1f86b3145fd8dc33aa2fcb2e882cf69ffadee81e8412ed2092c634934709c','ef4dfcb8c723aea3090f195731d1a8606254fcc73e543ea58353650c85440d2c');
INSERT INTO blocks VALUES(310114,'24fc2dded4f811eff58b32cda85d90fb5773e81b9267e9a03c359bc730d82283',310114000,NULL,NULL,'00380ec3118a5e8f9cab403d10870dd5bc339421297fcb6196a3112d70541ecd','22e3851c91f780c0152549b24228d0dab3542c2632b633995c0d8dcfd8e26601','78e0dfd940a74e84224ba8ca4791b9def440534eb68e3b080efd162b84be8f9d');
INSERT INTO blocks VALUES(310115,'a632d67ff5f832fe9c3c675f855f08a4969c6d78c0211e71b2a24fe04be5656a',310115000,NULL,NULL,'0acd3a07c5df54e883ff9871852c961b00771d3f4afccb3b1941d0b1c7b300cc','cf921f50b98df4ec37f2a9803315a798198507adcbfd8fd54e6a9bc539cc8f41','8a4aa660c005bd29b5504bd9c12aedd3361b46da6ab45e6ad620f5456fb0d528');
INSERT INTO blocks VALUES(310116,'8495ba36b331473c4f3529681a118a4cc4fa4d51cd9b8dccb1f13e5ef841dd84',310116000,NULL,NULL,'6c6845d3be70cbe9a71c33227983f695c96877aac6d3a8d6a6839760b4691d25','a7e01a910cc919588be3b0c19c4bb7c36499b0a9b0347834d40fbb54fdf05fb6','18c32a0a867ef553ee15273506d939d91f001c05c57d7c6c269a4822a4db1952');
INSERT INTO blocks VALUES(310117,'978a3eac44917b82d009332797e2b6fe64c7ce313c0f15bfd9b7bb68e4f35a71',310117000,NULL,NULL,'0465a90ff545d58e69c07c204160360bcc6fba5cc60fb81d7e6e389d9ff8133e','1100b7084683079d36f9ec6e4cb1ec457ae4c45941cdbaa0f4d53bc458e2fa9f','56c1b562246edaa100732531243c61f21fda1ff783265909182b4f783c5f7ad5');
INSERT INTO blocks VALUES(310118,'02487d8bd4dadabd06a44fdeb67616e6830c3556ec10faad40a42416039f4723',310118000,NULL,NULL,'011ed3df8ae72a02b686e98aa8db07c973e1e12c2ac09891ba90d783ae63161f','7ed056a59c2b15a2d082f75c8728ee1e7f9b0eea6cb56b37f41319b115e39771','e6ca631f6c99acd2bb4b9b0cc8b9d0c868b52eb073ed9fddf5ff94ed03d97bdd');
INSERT INTO blocks VALUES(310119,'6d6be3478c874c27f5d354c9375884089511b1aaaa3cc3421759d8e3aaeb5481',310119000,NULL,NULL,'a6620b1b6a5b1f54fe6a8076fc35f0f3ce15315e9f549f5ff3fa0f5b6094919f','1312871691c685ced39676d4d4bd8825d2109587d1ec36f2dadc50f68b4d9cca','8ce874afb9b425f94988904a2885d54425de128782e6ba9d98495309c14b65b0');
INSERT INTO blocks VALUES(310120,'2bba7fd459ea76fe54d6d7faf437c31af8253438d5685e803c71484c53887deb',310120000,NULL,NULL,'e38e2aa0bf8831b90e69b40c78d4b7d41bc564527451b5f9b332bb0beb54c923','1901f4d80a526969a544b68b1a695f07aa078ad719b8803c0b7543fcb4a974d6','bf9569b0ff7ae5749497264ebc8f171dbb28b79b289b6d9846c47953db0b92db');
INSERT INTO blocks VALUES(310121,'9b3ea991d6c2fe58906bdc75ba6a2095dcb7f00cfdd6108ac75c938f93c94ee7',310121000,NULL,NULL,'5b988c8ad133bb5ff5ac1ee4ad0a6a4fd431247db373e43c9be2a020520f438b','9921b651b8ca004602b16f95d76b2ea76f03456d9a978abb02bb340f360df7a7','b6c125fee8aea48092fbf396b5b838d04985f5d9958b28d57bf0f8f90f58c822');
INSERT INTO blocks VALUES(310122,'d31b927c46e8f9ba2ccfb02f11a72179e08474bdd1b60dd3dcfd2e91a9ea2932',310122000,NULL,NULL,'70ddab8f1d6283ce5a054650dbcd02d7ad4ca9c35de7bed920c2f266bc092070','a45cd1eea6626efa3af3dcd3c89782c50cc3b683c1b22249dc67d288e56aeb17','df4140191d065ec2d4ad20b8212258dcee2607b3b2860bbc52ff3fb238a2b0ce');
INSERT INTO blocks VALUES(310123,'be6d35019a923fcef1125a27387d27237755c136f4926c5eddbf150402ea2bbd',310123000,NULL,NULL,'3670feebcf979edce175ad5b296a4c88fd7fc6bdc251dda84d487b1b092e41dd','78c648296fcc7856757b990a92cf9512c61d180b08d451b63ed4e796d051d338','9ad996db2f2c3ad98cfa5972794637d176c41dfc829b6025c74f156b9342eee8');
INSERT INTO blocks VALUES(310124,'0984b4a908f1a7dac9dcd94da1ee451e367cc6f3216ee8cdee15eae5d0700810',310124000,NULL,NULL,'9883fff318e7cf9021fb4cc39261840f682e8adabb934549dbae2a10d2a71de3','c58aaf910fe01fd9ba6a892ea421c0933f4cebec80c6d2d556accc81102428d3','d792a27515fbeeda7eee6eec142c93ac6c4a15325874c9490b9ffaec165b8a64');
INSERT INTO blocks VALUES(310125,'cc28d39365904b2f91276d09fae040adb1bbbfd4d37d8c329fced276dc52c6a6',310125000,NULL,NULL,'1840685242f9090297d4b432e305e4a093f90faa0b673953b648fbed948f31b6','3d1e4c3a02456d7f79402a89f6a39dcb235fde15b275a762197b70e643d29e25','018e59311dfb3985d3639e925b138ebf541ce6fa19218699bf6d618cdc9cd529');
INSERT INTO blocks VALUES(310126,'c9d6c2bd3eeb87f3f1033a13de8255a56445341c920a6a0ee2fb030877106797',310126000,NULL,NULL,'1a83f417c18439cd3c6269626c44b480317290f0c27a9b9f883a01653de69272','7cde633cf5f7bc1176a3faa6ad03a449d3fb0d21dcce5885d2a37b81448a2ca5','998baffb473c8b0621d6dfd906ff281a0ad4c8e2670c4505b8ac6d3027fafbe0');
INSERT INTO blocks VALUES(310127,'c952f369e2b3317725b4b73ba1922b84af881bd59054be94406a5d9bbb106904',310127000,NULL,NULL,'094c53dfd00b5004d074987dba90a6c9c47841d01041d0aeb61923c48315d1bb','0ac0ddcc5c45d4d709d9070814832bfa2339eaf5edbed98232cda4b1731e5478','97e5ef9afbaf57a5990272f215e75771952744f3b81e7d3f1ed26b356c78890d');
INSERT INTO blocks VALUES(310128,'990b0d3575caf5909286b9701ece586338067fbd35357fec7d6a54c6a6120079',310128000,NULL,NULL,'28ad1365daaadc866e79b6b1a555fa31bd804a85827d958cebb9d29511f78e19','aa9a25819899fc8948c4906673cfc8128c0a98417db8fe659098d28ca12e3786','e16472413c31d850db6b6b7d9e0537a608bae86fb70a8d2fe8aa6746a305c8e4');
INSERT INTO blocks VALUES(310129,'fa8a7d674a9a3e4b40053cf3b819385a71831eec2f119a0f0640c6870ca1dddc',310129000,NULL,NULL,'61587f9b5d05f8f553f0a4f580f38a140edcf7d9facb13c542865f5ec586a32c','ca3752868d963f0c165166928139cb078aefd0ebcbd9ab8f182c631ff941a56b','8591fcb2776fdbca0328bb106cc652a7c843312beacf3aba6ca270f1c08f33c7');
INSERT INTO blocks VALUES(310130,'d3046e8e8ab77a67bf0629a3bab0bea4975631d52099d2ddc9c9fa0860522721',310130000,NULL,NULL,'1ee8c39657890ac946e2aac5409147cdbf1b0004db1f00d997cf45452596f781','bb38c9be1ef6ce22f1f14319cb3e1385d70fc63f7d0b2d80789c9af018baaa71','c83da14dc43dc874407eb36e579af2ea65da475f38eb550a19fab5c947a2523d');
INSERT INTO blocks VALUES(310131,'d6b4357496bc2c42b58a7d1260a3615bfdb86e2ce68cd20914ef3dd3c0cdd34d',310131000,NULL,NULL,'aee45272e68725a2746582f1847582eb9808289d3deca144f8c6cb43bc4f42e6','69fba2b86abed1e740d45d33ec1bed7d2bf7de0f3bd9633959bfe77a21dd7aeb','099f79eb3dc9f7629628a8d13f6f644851413484a5c9dfd9dac251485749cd66');
INSERT INTO blocks VALUES(310132,'1b95a691bf4abf92f0dde901e1152cc5bd87a792d4b42613655e4046a57ab818',310132000,NULL,NULL,'a3fe51c1d168ed726a78b72db61175f2abb07ea6c614b2886f3054cdd1a858fe','352b00e4db389d411377c2302ecf272f97268e953c30d0976a5d12bffc5a17f7','56c8685802d784ad336a2b1fbe32a64fc379218d00c44ebee1737c0c37304aab');
INSERT INTO blocks VALUES(310133,'1029c14051faabf90641371a82f9e2352eaa3d6b1da66737fcf447568ca4ec51',310133000,NULL,NULL,'626743e51b462163f23f22079d672379def21382fd88f9155ddd453ca3d633ef','1a7a1af397c6619b629eba7fdef0f0ea2d737e673d182fe985421dee61d0c63a','63d87b0f2e9baba3d46697a3a50735fe3a9d236b13dcb337a2f1d8676b5c15b4');
INSERT INTO blocks VALUES(310134,'1748478069b32162affa59105257d81ef9d78aee27c626e7b24d11beb2831398',310134000,NULL,NULL,'4b6e3202cae46fa80222e3ddec001213062ab76b8848eaaf4ab73f44bd84ac55','855a47de54b979a3d958a921c2679825084193b9f1eb0fa56393e0186fb1b440','2ee81708d3e2cab5a2e865909da30568c1072dbd93db1e6b7232f9b7cce2769f');
INSERT INTO blocks VALUES(310135,'d128d3469b1a5f8fb43e64b40f8a394945d1eb2f19ccbac2603f7044a4097e4f',310135000,NULL,NULL,'e32784cedeadac39bb292da2c5eaffc983f416e0bf387978691e4c0fa5b1715a','80e68a8a303975543781e760be8d8b151206fb0335d3e0f5c2821d3e482b0ef0','401a2a085cb2c6274825a956a69d43f4f39c1e9c2bc77530bf6765e76bc92d85');
INSERT INTO blocks VALUES(310136,'6ec490aaffe2c222a9d6876a18d1c3d385c742ff4c12d1334613a54042a543a5',310136000,NULL,NULL,'93c67fdabd991708d1e35dabbdf7acb4e928763eeb817b32a79cd0bdb414fd2a','5fd1f9311646bed047ec4ac1d5aa5c74d68d26ddf6bdec14f2f53f4cb9c1f6b1','ac6ca74499abdb3d042115b29c525167fc97b902465deb4140af5c7d26bdc3bf');
INSERT INTO blocks VALUES(310137,'7b44f07e233498303a57e5350f366b767809f1a3426d57b1b754dc16aba76900',310137000,NULL,NULL,'8a43d01155ba47b8b1311c41d5a57112198857701c2970d0fd373da04ef4e585','d1f1a4a5fb78621aa1be58d32795feef8ac82572c34a694bf6b0b8c3c73ba7d6','7bece0ad3c0bd6fa91fede24bb1741399bd62d18719502fdea9688d4ad24c2d3');
INSERT INTO blocks VALUES(310138,'d2d658ccbf9baa89c32659e8b6c25b640af4b9b2f28f9d40baae840206402ab5',310138000,NULL,NULL,'4acf0244f3188f60152acc8ca30dcaeadf12e6669b15377c81b7e6dc3c8892b6','645be1bed53d63c268cd21d99a914aa4268b5a357dafa57f706075a66e42f948','4015afab0930065b77b42d057b8f1ae3bfdda80a6156eeb43cbaeb7ed268dfa1');
INSERT INTO blocks VALUES(310139,'b2c6fb61f2ae0b9d75d18fce4c52a53b1d24772b1ad66c51ca51090210527d46',310139000,NULL,NULL,'2d77bdd47ed1b3be1c2edf41473bd5eb707d06dab33717b01c4a227f9855d73d','c1e0ab9fe21f807be3431a5d28c048b7f5c49ee5cfba7b9a0a837d1fa5c90f4c','bb210f0649312cebb3e08c0edb78a6bd82d61b7e7426a4f476dd69cafa883495');
INSERT INTO blocks VALUES(310140,'edddddea90e07a466298219fd7f5a88975f1213289f7c434ed47152af6b68ebb',310140000,NULL,NULL,'277c0c6dd1c505dc6f9a222c737296396569d8e007c4b9a42582f108e90fa624','ab9a8224e0e3f8f728b56fd3ff40d960d9d336b2743932053b2419423223f2ac','b4c342f5be2acd3135682a0661e6a29342bd6fe92b699efd4f7221d3e2d14872');
INSERT INTO blocks VALUES(310141,'b5b71d2a271bd638561c56f4ffbe94d6086debaaa86bfeb02ef0d71339310709',310141000,NULL,NULL,'f5d0edff3f22b2e025c884b7c738abe641bca9110a6b9a7b90de179fd6e5d2dc','d272db9ecd97edb037736fe46ab9585397f38a6d1c1d9455e64b8439811ebe4f','550f2e3dd1118335b336162eef5592b8b8af4d78695c036f5946481d82455866');
INSERT INTO blocks VALUES(310142,'a98ae174c41ab8fc575d9c8d53d8e02d8e446b8c6c0d98a20ff234eba082b143',310142000,NULL,NULL,'a9f00ec826a30e66820ab2920cf9573244a24dacd63d48c080b9e80b1c5e05b7','0c2ddacd61856ee0743eca9125326981ab9f5711982f53874a0f8153089a8d97','1979ac800951d8be57954cdf798ebd3f83510090bb4c915442e3543bdc5733b1');
INSERT INTO blocks VALUES(310143,'8ba2f7feb302a5f9ec3e8c7fc718b02379df4698f6387d00858005b8f01e062f',310143000,NULL,NULL,'b5765899f770fdb6cf1120535d85826c6b0ae44b16b8d5a619c5cd12c98783ea','39ef998b6c6130f79df8dcb5abff84c18a485915f1088b36a10de30da8c6f9c6','17125ab3e1ce5c91c5066e514d20d1ef400a0e9b1663b86523e2dead2b3de769');
INSERT INTO blocks VALUES(310144,'879ffa05ae6b24b236591c1f1537909179ed1245a27c5fdadd2218ab2193cdb9',310144000,NULL,NULL,'1a80f48136e5938b33f817a7cc1cb60aaf6d628b7811abd43e38cc807a18072a','0b547c8db7446cd3f26dd0d8b88d533c1361fa5dfae6127b85e87095b42ab66b','1999385e0d670c4500109cd77174050daa7941456900ec8aa463d5765b861a5f');
INSERT INTO blocks VALUES(310145,'175449ef0aa4580593ad4a7d0c5a9b117e1549ea772af00caa4ccdc9b1bf7a6e',310145000,NULL,NULL,'fce2f084c1776fcb36b3ae3e0c952893934e24672ffa0d3dac72bb1278af8264','bcef3d9f5eb82fb2198d268e442edfca029d5aa3ccff5e5306f0a1a8cf43b30c','fe5b294e9af1e946aa0943c93b135adfd68af72712a98d1aa4df146cacc4a52c');
INSERT INTO blocks VALUES(310146,'e954ab6a110455d745503f7cc8df9d92c1a800fafdd151e7b1912830a9cb7184',310146000,NULL,NULL,'9a98eb971580a0a69fceafc5fd41f398f1908b626c47df57965d1863e9a24b84','036b1784841e65e5905b012f2b74c70e1d9c33b769603c01387d13e693343411','0b8c933f89aa2198be717b2089b613a9f342a1660f42c337a8d8d2196661234b');
INSERT INTO blocks VALUES(310147,'7650c95eba7bf1cad81575ed12f32a8cc36281a6f41bef13afe1dfc1b03a7e83',310147000,NULL,NULL,'336a89d3d137810d3220d2de432f72e3b3ccd2ada2b746da3859c77dbb89d6a3','184e1861a82afa97634e0ad72cff532220a37d75f8eb5e1265039188124f6ad6','93dd40c557eab4df473adcace77584ba87af323ff8b27ad1ea2b3b784ff3a614');
INSERT INTO blocks VALUES(310148,'77c29785877724be924f965215eb50ffe916e3b6b3a2beaea3e3ae4796545a7e',310148000,NULL,NULL,'f904794337dd67d356981d2623b8c3d1d78ba584cd98a8c1db939951d3102612','c75b4218153bfdf3baf44f22f99523f7c54d957994ee838c05c08dd52d98c06f','566e1adf185ae4b544504d527c16b0e677295fe707cf8b4052c458d15f5a7d1f');
INSERT INTO blocks VALUES(310149,'526b3c4a74c2663fc04ed5234c86974bffddb7235c8736d76860778c30207b3c',310149000,NULL,NULL,'c2972fbd048790f54d9ecef4e18aedec8ae7aa28227d1d43bd19cd71b4feff85','8dac7e6494cc67fc5c186e74b08d9fc8bc92cf71af9b0e1d919c48e9fecf7660','2cf8f7dc887e18f7e315ac9417eec53c2ec295f7af8907ec896777f8edeb2f64');
INSERT INTO blocks VALUES(310150,'cdd141f7463967dbeb78bf69dc1cd8e12489f58c4ea0a5dc9c5c01ec4fcea333',310150000,NULL,NULL,'88b999e4ae34386b826b0f3b315953b5eeda8d9ef496af051498bfce6d8737fc','db25206ba3a052c622c6a5063359308d04fc2a031d6509447d838cf96a0632d1','258a3a82166a0a8385e6187b078227e054071b737031c20c5be747f15982e618');
INSERT INTO blocks VALUES(310151,'a0f31cc6e12ec86e65e999e806ab3bfa18f4f1084e4aeb4fbd699b4fe284b330',310151000,NULL,NULL,'b7c176a2eff86655f8b0b71cc8bd3bab3a92ba203d4ccd911d63f3d2ce7fdc25','c6868100e51f390d57b2da8324915c9751aa3882b6e102055fcfe229d1abfc85','248b562425ebb02eaba4ee2e1cabc106942d3285ffa0d25e06f556df2115a4c5');
INSERT INTO blocks VALUES(310152,'89c8cc3a0938c63a35e89d039aa84318a0fc4e13afac6beb849ac37140132c67',310152000,NULL,NULL,'3f9471c393bc2bf144b17a5febea88c42982ae746fd700a5903c0e6e541e2b09','ff691488593add72ffd8fb9c8eab2b2c6f92dc2082615b3829f4b84fc8a81f88','6acb99470c24760963632f7af2e13c69bdc05fa54ec608a82cc96f91b2ec9819');
INSERT INTO blocks VALUES(310153,'d1121dfa68f4a1de4f97c123d2d2a41a102971a44b34927a78cd539ad8dca482',310153000,NULL,NULL,'c6bc81e7b7e6758bbbfe10fa0e688b09e679fb74a18134639e172c18c6e017a7','6c303c21dd9de15f2a265d88e04a2c110f32718da29a06294ebafe9ed91d4441','d1f917485804ea478bf4adf8f6d9551b6b8413ef96290c5600246d01070f9adc');
INSERT INTO blocks VALUES(310154,'ba982ea2e99d3bc5f574897c85485f89430ae38cf4ab49b7716ed466afa506d6',310154000,NULL,NULL,'b3e07f9de85ab67e88042b1bb52302c6eb16b7ff45d5be6a49700f115ed396d4','b21fe34642b2c9ff09e65be86103f1c3390a01eb51b4d8b98456558639ef6e1f','5bb4a78b32d1a06d4f181f7d74c2c432826607f5390277b43cca9995202fc3b2');
INSERT INTO blocks VALUES(310155,'cefb3b87c7b75a0eb8f062a0cde8e1073774ae035d176e9769fc87071c12d137',310155000,NULL,NULL,'27014841a468e23bcb70c718919745eadcded4310031a7be90a4732c96509404','0e5f0bfae3a6ced9c6498cbe95b8bcb56c76530830baa61345b8072aa6e28ff3','8f4c7b9184da4180bfde0b4e7f7afc9a2fdbf63fac5da64cf42e8035a6afb23e');
INSERT INTO blocks VALUES(310156,'6e3811e65cb02434f9fde0445a7a2b03fe796041458737d0afcc52208f988a83',310156000,NULL,NULL,'5597aaadb8cc75848219f9fde3f5d76bb5592689c72068db59922732e89eef9d','ff3319c50ddd9bbd558542bdde3d612a475b543d6a34ea76738d929b5e05a380','27cf134bc6b41c343930ebc9fb5c6a0f45f1e9ed08dcdad554ca477849bcb34b');
INSERT INTO blocks VALUES(310157,'51dd192502fe797c55287b04c403cc63c087020a01c974a565dd4038db82f94a',310157000,NULL,NULL,'cc1ae27fef286424e40204f6b575e9e079e1f7a5ccf6cc356729a7c4a7f83eb8','9b4884eaca300843017c2732aa8d09815eee4701cff996cc8b6ca6d62af4055d','46d289e1107bbc0a6ae0db8d9b9f92ff3cca025d6aab5724b05e0dfcf277cb46');
INSERT INTO blocks VALUES(310158,'749395af0c3221b8652d31b4c4410c19b10404d941c7e78d765b865f853559d2',310158000,NULL,NULL,'6d80d98e778b30c124b0255b3e72620f432245d0f841f6bd62a0fcff44843bf0','03a33d54ece86ab81f4f6e1cb337b07b6fc105a580a4ff82496885c7671939a4','a07a94dc8904a5d02a169900f7db2c1d8a5ff33ea0aafaad713d25209b4b8d7c');
INSERT INTO blocks VALUES(310159,'fc0e9f7b6ae99080bc41625588cef73b59c8a9f7a21d7f9f1bf96192ba631c12',310159000,NULL,NULL,'d8ab8bb14092afea6cc675d2f50891318e3169bf9dbe2d07e80c4db95f0f2033','c292a08eda8cb807f0c11947fc08c748353bf545596d8c6c03a4a734d25461a6','51fc2727acbcf49b50f2f3283eca94ada6b1db3897e1647dcbec254602312405');
INSERT INTO blocks VALUES(310160,'163a82beeba44b4cb83a31764047880455a94a03e859dc050da782ed89c5fa8b',310160000,NULL,NULL,'2d76a042d062b73b7dd956d5cff0ee397f068c04eae6cf5b9522d3d55e88cee9','df1e1e18b65c4322284ab36204d9f4397c0dade89bf25486c8b84f6358e0f18e','676125a42a324b1547fc2260f3af6df7b3fe1983ae77e0b7db5bf777d450263f');
INSERT INTO blocks VALUES(310161,'609c983d412a23c693e666abdea3f672e256674bf9ee55df89b5d9777c9264d8',310161000,NULL,NULL,'beb3496742415027bcc0d59f3385809523c8783cd91a5670f2fb6fec3230e980','e61374e297180716eee972376d16b85266342dfcee4f383ba9061360f7c0a425','6dca3ff16b1a54f6899095762c12837a535d72a79da2e1564031b8cb508960d2');
INSERT INTO blocks VALUES(310162,'043e9645e019f0b6a019d54c5fef5eebee8ce2da1273a21283c517da126fc804',310162000,NULL,NULL,'066a2b93df863300741145cd6a4f1a9ea616bc787861cb8ab809f59d47a6fa1f','bc115f6ddeebabd3e0ea592604ff679267b755376e509c4760cfa394e86498df','6e8e47accc7dc2db25c0f3c0c06f5ca9168982b6f21f2ee2aa36f02fddd59b34');
INSERT INTO blocks VALUES(310163,'959e0a858a81922d2edf84d1fbb49d7c7e897a8f49f70bd5b066744b77836353',310163000,NULL,NULL,'460c271269ccdd8775925b511705207baed8fc212caa7e74fc08a80be600a38a','d16b6243e4c0718a2adca941956564325985750a9a0833aaa35635335cb504ea','876cc5729a94481d3e12c80c1c58a812612fac27c7886a60371c2cdf75b12994');
INSERT INTO blocks VALUES(310164,'781b7188be61c98d864d75954cf412b2a181364cc1046de45266ccc8cdb730e2',310164000,NULL,NULL,'19a7948cd1bc4a89a427d48bb01330dadff848e2b32ec8b8abe342872850b268','54068fbe0e385c8ae2df5cb2c601397e15c019c732e37ed484573f07106741e3','4b4c2b04f9b3e1e52fdc624494aa3634b3808e99f772b017e28ee356f9df7a7a');
INSERT INTO blocks VALUES(310165,'a75081e4143fa95d4aa29618fea17fc3fabd85e84059cc45c96a73473fc32599',310165000,NULL,NULL,'97f0a48a26daf011a8c7b22bb772228a0c8a920eccd011e713956100c9fbdf33','0783c9e3d99f4f95b64b38b92c4e8b7d257f325d10cd83bc86d684378b9ebbd6','3e0aeec95eb3b4e5324a938e70051a4864ad5cbc2cffec9c94a845f46c1e046a');
INSERT INTO blocks VALUES(310166,'a440d426adaa83fa9bb7e3d4a04b4fa06e896fc2813f5966941f1ad1f28cfb41',310166000,NULL,NULL,'edbd00e1229c673f4f15b3ac7bbe020f54b5f3a61b1d158658471076a55c77b0','683f4ab00ee1ff495bf452c511c1582100191ef7b575139b9d2f102c852018c8','e893bda80a80e50bf84d0ad6b1f013a2f657a04ebafcd3b560d1e1690b5adba3');
INSERT INTO blocks VALUES(310167,'ab4293dbea81fedacca1a0d5230fe85a230afc9490d895aa6963acc216125f66',310167000,NULL,NULL,'e118e0f3aad5be73080f4d1892517e8fd2c4575589ccdfadf980edebb9a66a14','d2be4356643047c7bd04eede767d4f6853885f408827f3bec8c54ceb2b7fd71b','eb2c7b7a6a2c2038630041e7f01c65c1b3c07db5cbbe0fb6c5e4fac4fb093674');
INSERT INTO blocks VALUES(310168,'a12b36a88c2b0ed41f1419a29cc118fae4ecd2f70003de77848bf4a9b2b72dc9',310168000,NULL,NULL,'267f48eb4e3b0925f4f472d8ce6ec57ec5039911b13a14ff2884a41a9cafd7b1','ad748b661aad47fa8963b43999846ef9bd00ea2595747f835710360afed16797','5d3e9d0a1425b5a5103a9c17c4de4a44b655ab2859f9a6cd166677d7b7f5fa0a');
INSERT INTO blocks VALUES(310169,'204809a85ead8ba63f981fc1db8ae95afe92015f003eaebbec166021867421f3',310169000,NULL,NULL,'df394a6f3b2a9b9dded6019dce9f3d3214db1f30019faffbdc2ce614f629b25a','3a92e2c7808a00a0ff2b2fb4695b225acf6262c57753023334bcf3de8e1c7ace','476944d746ace20f3da3bc0c080855e656030739d6871ec7dd21e63bfdd2484c');
INSERT INTO blocks VALUES(310170,'b38b0345a20a367dfe854e455e5752f63ac2d9be8de33eab264a29e87f94d119',310170000,NULL,NULL,'3081081c2ab6d8280ef721c5836d0fb7e89eb3d747a4e4522d2e22f5a6b153a2','f4ada9df3e82d94ba52292e829c4c814b3f0d04f0e3f8606a90fed651634fafd','6134bed0cc8a6889636eb22dabf36f5722379739f97e06e0955409c334469046');
INSERT INTO blocks VALUES(310171,'b8ba5ae8d97900ce37dd451e8c6d8b3a0e2664bb1c103bf697355bf3b1de2d2d',310171000,NULL,NULL,'e6a4017e4f7d9da50bb3817990c3e115d5035443de8824dc01b5380a5b4c52a9','e335e773387256c016b82649c44647ce0355aa108249413f02117fe14f39c56d','a8be6056941ff01e7b5b3cb5db68deff1a3b517321420380ed3a6c0d083e2bb9');
INSERT INTO blocks VALUES(310172,'b17fda199c609ab4cc2d85194dd53fa51ba960212f3964a9d2fe2cfe0bb57055',310172000,NULL,NULL,'89e90622bf8363bcee5cd7ab6d48b6d06ce4cbd067f9985e35e67fc683f4c103','d03bfc2a16d240505e3413ce267b263a0ddde5b3f8a04acb6a67d33a89434996','d935c6d1bfc245f9b5471e7b335ca3ff5fe6d39ae1ac0725318261d577229a33');
INSERT INTO blocks VALUES(310173,'f2dcdc5ffc0aca2e71e6e0466391b388870229398a1f3c57dec646b806a65016',310173000,NULL,NULL,'35ceee6a23757fa49e7f5c34ccf0fd034731e95d564257b443ebfdee7cd294d3','73c9dd3d2f5390d0d4379cc8f5e195ba4a0b4d280d3fe663db3940d4a42108ef','8fbddcff14956130b5f2a845b52b27fc79d92ffa81defb7857c55cc98bc2a4a3');
INSERT INTO blocks VALUES(310174,'fa6f46af9e3664353a473f6fffce56fa295e07985018bface8141b4bf7924679',310174000,NULL,NULL,'101dedf34bc0788c0589c8e2b1d7da4ec65f6eab2e3c5523c0903db685cab017','71d9279604a4ac7dbd49f6672ec6cd19ba59b62302eb1b1bd78ecd3b6d4a5263','94f451d2f6ecb9adc5e52d225dbfb3cd92f1c27daed8ea1cd16ec3b9672a9af2');
INSERT INTO blocks VALUES(310175,'f71e79fe5f03c3bc7f1360febc5d8f79fc2768ce0ff1872cf27a829b49017333',310175000,NULL,NULL,'67de4a0a9e52d9ae06caf62b3412d0bf2c10a6b24716210b21212d75be75ad6c','90b52df6f0427a7dc695fa0e17a7bf3e59d788cf4016bb65c451a151c38f121b','bb745a685ec720a42dbcd35af72dc3abb65df32452997a45b76bd0a1df2a35d5');
INSERT INTO blocks VALUES(310176,'67cd1d81f2998f615602346065e37f9ceb8916abb74b5762ead317d5e26453c6',310176000,NULL,NULL,'a90bd400e15727fada1a27be4a6e228bd91a15f0dbd0fb7de3b6779a8bf89e4c','b870ef1dabda015a561f74122039890b1c9c98e2c4c547dea34ed296fc99e8e1','7404791223ec44a22b104e38e894bd031807717c5dec2128cd9bdb4028d0ac7d');
INSERT INTO blocks VALUES(310177,'6856b1971121b91c907aaf7aed286648a6074f0bd1f66bd55da2b03116192a52',310177000,NULL,NULL,'bac315d07dee18e27336a46ff3ffeed58aaf8eb1eb702e98a93c06303c937716','80b0eed7b842a9779b358c5293771470290876f3acb617d85e1a97e786a73092','4ad038bae4eebc7a29173a647291d24701ad7161713629b43b0da4e0ca837f58');
INSERT INTO blocks VALUES(310178,'8094fdc6e549c4fab18c62e4a9be5583990c4167721a7e72f46eaf1e4e04d816',310178000,NULL,NULL,'186ea0ece84d21ee21889ff13c98959dfc1842063a970e0c095552f0ca86515e','79d67c9aecc8676b0743ebc9af6b78c6f40d264b54bcb510b0028715fc1ca4bd','0931c08454cea0c7449f4e7193a7790780f6655964412a02bcbf9dd967fe82d4');
INSERT INTO blocks VALUES(310179,'d1528027cd25a1530cdc32c4eaff3751a851c947ddc748d99a7d3026a5e581a7',310179000,NULL,NULL,'0200402ef08256efa0adc85b2b4b15fb7448b5107b65fafbcc7985d809e84bc8','3bbcd82428f094a7089c7c9a5c74be0e400e4a03181ea95faea8681323851d43','ce3cd42b7f3d934c99cb3e9500697c79fecf468a69b5d8701c7583bc8f3d90ac');
INSERT INTO blocks VALUES(310180,'f2f401a5e3141a8387aaf9799e8fef92eb0fc68370dae1e27622893406d685c1',310180000,NULL,NULL,'13829eeaf9bdc54f87366e35616c5a57cd836c63db8a9ba7d117d02377ef43e1','2398e91ec31dc2810a4648946a85f5af7df71cae0b678f99aaa17e97d215785b','7655e841ad45a5a5036ce8db7f6d70c423b2718cee53cac2bea3633989098004');
INSERT INTO blocks VALUES(310181,'bd59318cdba0e511487d1e4e093b146b0f362c875d35ab5251592b3d9fed7145',310181000,NULL,NULL,'81b4d83a623a55019ad720c1bd3ecef100d8ca49deda91b8ba6ffe9802764df7','82cb247f5dfeeb31342861a77bceb74957ceb62932de536d837988a2f471f599','e3c4ff466471a4a5dad15f43387396fc5ad4eef2bb780db0ef9d40af5df49bcb');
INSERT INTO blocks VALUES(310182,'a7e66b4671a11af2743889a10b19d4af09ec873e2b8eb36949d710d22e1d768f',310182000,NULL,NULL,'935e40f93195d450b292481aac481f445d2de8786d04d26263f4adc5a348704c','1a48f71be7c5f3baa68d68c393a6c68d63596c561005ac7c6df457584fc18c6a','44e9068dbcabc6e8cc2bba24eb710a725d0d94c385162fd126127cb196acaf69');
INSERT INTO blocks VALUES(310183,'85318afb50dc77cf9edfef4d6192f7203415e93be43f19b15ca53e170b0477bb',310183000,NULL,NULL,'268bf841be40615472bf4c60b5306d0763ed50510fbb55c47a6a0ac726e8701f','82d2641b1ab0cdf057e8e68b0cd7824ff8c60222f8d4e23125d68beacf2b3293','f82094b5df7848f7877dd9c8bf14d8411ae5bb2434372ef57a61cb7c62d51f72');
INSERT INTO blocks VALUES(310184,'042a898e29c2ebf0fdbb4156d29d9ba1a5935e7ed707928cb21824c76dd53bfc',310184000,NULL,NULL,'64323488ca4d32a1f548842db4ac772b750599ce6222020ef6149b4a0e54a935','9a7f77be4828adcfee8ea1f106ecbcb55ae758d5098a6fa1aa3a494af957f7cb','053835bca73d08aca5e0d3a259450f4148bb4a28c87b9fb5d28cd5fcdca3fcec');
INSERT INTO blocks VALUES(310185,'bd78c092ae353c78798482830c007aac1be07e9bc8e52855f620a3d48f46811f',310185000,NULL,NULL,'8946baadef2e19c5e4e4b2d771b36982a217486dcb0f95097b41ce633e61da94','8956f030f917aa87d9b309bd845b59cb37ba2265184ff1f67bfa4b61e32d43c3','d4772930b7f8f6bdbee8410d01ad4dcb67e10dc0ac442fb0c76e14aa85505e64');
INSERT INTO blocks VALUES(310186,'e30a3a92cc2e5ad0133e5cee1f789a1a28bea620974f9ab8fa663da53e5bf707',310186000,NULL,NULL,'e68b5525927cfee15fefee02a16fd700abf6b6e7b4e32e57df7d324fae7ae090','137a7a7a1ae71a317f7c3c48f7f84e4a782a515fa2096c2abe2c1adeab4e8256','1850fba350859cbca88cd82afa596c83eae84a6f1e88474a02734be1d4703602');
INSERT INTO blocks VALUES(310187,'fc6402c86b66b6e953d23ed33d149faa0988fa90aa9f7434e2863e33da2f3414',310187000,NULL,NULL,'c42efa24d48339fc341908a30c6679beeadc9f5918d8d3e62d5c4b06fec845d5','cc587cfca94dbe30e6670dbfc4a5e3ec46732731f5c66aab9c7ef9028b05c22a','29d7fd0e186034c2607894b2c56d3840c51be2c9030556099ae589d5d30356aa');
INSERT INTO blocks VALUES(310188,'85694a80e534a53d921b5d2c6b789b747aa73bf5556b91eeed2df148e2ada917',310188000,NULL,NULL,'13de1d9b569d5d2525ecfa39b1eda69f9fd474683b6e34554b1a755125e96e5d','2fcc160068a4eb52ac410937237ec3813bfee52750bd8cef939738b81c8ac30b','6fc00912cd7650f9fff9d466551e9ce6f91861fd553c225a1f81148160788a5d');
INSERT INTO blocks VALUES(310189,'7c036dadf19348348edbe0abe84861f03370415ed2fec991b9374dbb0ca19a06',310189000,NULL,NULL,'582b8b3d3a226d3f6df497cb933ed5f42e1e992c0c25372ec15de424c0a33368','ae81616b5fd77e3672318a0a5ef1b20106afc3ce7d730c8beef848d73ba53a0f','0085ed9f842b72c51f0028302749fceb9f132a099aa5a696a574f65c42323d28');
INSERT INTO blocks VALUES(310190,'d6ef65299fb9dfc165284015ff2b23804ffef0b5c8baf6e5fa631211a2edbd8d',310190000,NULL,NULL,'d4c49d5e3aaf21e6fe1c30663d0ba93f7dc9ddb03611e3751fba9aac8d382ac4','48c70376450aa80a2a920e4b871d27d1efe703b377ba446a262e06c9a6677611','c7734bb7231a466736c2c8eaf5e159423d830b565a654920c00c2400b115727e');
INSERT INTO blocks VALUES(310191,'5987ffecb8d4a70887a7ce2b7acb9a326f176cca3ccf270f6040219590329139',310191000,NULL,NULL,'23d340ff3f1979a43bd1336c9c882b5ee01c646cd104060feacdb5db78025cca','704b02ead8ed3e4e6505225fc620073993e9c3b13209bff9b5f638d5f21ce23b','8f7b72bb16a996176fcc33e6646862695fbf9766c23b7d2309febc6f0113db1e');
INSERT INTO blocks VALUES(310192,'31b7be43784f8cc2ce7bc982d29a48ff93ef95ba18f82380881c901c50cd0caa',310192000,NULL,NULL,'cd18860851bceba4a0174480ccdc0f6ddc47b31ce71af8ec8500cb07f75d9da9','17018479e73908fd235313691ed8464b93a0a5db774d3608294e23fba918c672','41d416ceaa0099e870f6b3afaf976310446c264ccade940411cbe1b58d49db69');
INSERT INTO blocks VALUES(310193,'ff3bb9c107f3a6e138440dee2d60c65e342dfbf216e1872c7cdb45f2a4d8852a',310193000,NULL,NULL,'391e97ae7ccf5bc38ac72e7ad1256f24c28297c625bd9a789cba8231a5ade046','d08696a916e09e242fd20a9f8314cd4fb6305e991b506c53e3ef3f77e2d1d6dd','9563d9c28bffaf477075c589a093bbe8620bc494ad8671c62f0c75da3641543d');
INSERT INTO blocks VALUES(310194,'d1d8f8c242a06005f59d3c4f85983f1fa5d5edcc65eb48e7b75ed7165558434a',310194000,NULL,NULL,'9141c9b38087c7cf2b8c11ffd55c2eabcb3bb09f132ac0baf9c3779f628dd42b','d5f418ef4569bb977ff73ab64235b3697d0f7f326f95696e6f63c56cdd180d6d','aa1f8cf3b3c93664952b5363fbcb9e8a0afcab51ee983527841e3a8fbf69cdbd');
INSERT INTO blocks VALUES(310195,'0b2f1f57c9a7546faac835cbe43243473fa6533b6e4d8bf8d13b8e3c710faf53',310195000,NULL,NULL,'705918f002db29e7b3dfbfd6378f79d53e33c6ffa3948b2e3b5c85f85009bbde','d0165e09e04c2049de1d8582291e623c80477499203b702e46fb829390ed64c0','2fbe5a04fcdd633377196a0a9f4aa8447fda782ce5305de82535a551edfe2fb7');
INSERT INTO blocks VALUES(310196,'280e7f4c9d1457e116b27f6fc2b806d3787002fe285826e468e07f4a0e3bd2e6',310196000,NULL,NULL,'59e12df19e3c0e3e23a5d1e9783c75e236a000774a038553312919a0f46b8227','57dc6e1a18ce4910ba32e109820e8e0630070251ec745e63557c98ce71dedd80','3d996d8b50dba164c9bb01e0f8ffe58deb3f3e9bce4a64973c7c808e667b7536');
INSERT INTO blocks VALUES(310197,'68de4c7fd020395a407ef59ea267412bbd2f19b0a654f09c0dafbc7c9ada4467',310197000,NULL,NULL,'a0e1817dfc258180fa1629710ff3b6026181a9042fecd2c8b0b5e38118199e07','58d18f5f2362b4bfbf155b16fc4e8868b311286b25365f3b4b1a9bf73fab69b4','f17c3153db515d62a2d85ca0fad4f33377ddbf998331f146ea8d6ab95f692620');
INSERT INTO blocks VALUES(310198,'30340d4b655879e82543773117d72017a546630ceac29f591d514f37dd5b1cc2',310198000,NULL,NULL,'ff51bfc670b1387bfce53781750e35a3bf69d907167cf9cf57e15613cc0ff3b2','1443d1c76f64272d6ea00fb8f78913e72c617c515a162c9f1c213be02d48008a','a872b2667f4254bf6f90d2de1bfff588b030679108e2804fd34f7a397165d4c5');
INSERT INTO blocks VALUES(310199,'494ebe4ce57d53dc0f51e1281f7e335c7315a6a064e982c3852b7179052a4613',310199000,NULL,NULL,'e5f8f8f00de32f0d8d2b62eba27218edcee77563960fe074da5ae86bf5b553f1','87fca2825c48b9ec9db31e2d6e8e8354a0ceff7fa3df299dc2868c7d616a9599','dfa1a82d6459677d97002a18947332872773a95162d63e816b70ae5dbbffc5cd');
INSERT INTO blocks VALUES(310200,'d5169d7b23c44e02a5322e91039ccc7959b558608cf164328cd63dbaf9c81a03',310200000,NULL,NULL,'fd8fb664576868d4f1c843b28efc7ee028417034a33d6f5635238bd13c701b2a','a88ca1fa9d0dfccf2e49323a500ebdfab7ba13b60dc9011c6b510741148dbf54','c432d54f33739d16a9146018932b48424dc703313662e81832f8ff2557756774');
INSERT INTO blocks VALUES(310201,'8842bf23ded504bb28765128c0097e1de47d135f01c5cf47680b3bcf5720ad95',310201000,NULL,NULL,'7e2dbbf14c0620ac0fd4e0e676857e2d055fff80cadfe2d9d0dfe07d36738722','f20074cd00170edae909606eb1bd3937afaa3711590eb7d788c564ddbdc6600f','07b3460b02675704febb522ccc5d6278ec7bbec7b6cee11443e131c9b28f87f3');
INSERT INTO blocks VALUES(310202,'95fa18eecbc0905377a70b3ccd48636528d5131ccfa0126ed4639bc60d0003d8',310202000,NULL,NULL,'084c24e81842ec8edc4144ad64df9f12377318fe4dc491b307b7d377f3f81b2b','76c57648e216c5f191f04b79d2a1149d273b2a58a6b4956eb1d077abd2cfc113','24e5ac01807eb5d41c96b835fa18d5e217fc5d080c90ddc37f9fcb50755b2b90');
INSERT INTO blocks VALUES(310203,'ab15c43e5ac0b9d4bd7da5a14b8030b55b83d5d1855d9174364adbebf42432f8',310203000,NULL,NULL,'4b0b8d82a5a2c8600a09b1050eed4440d9e0f2d817498f3e32ba27ebcfbaf6d5','3e49b55d1309646ffce3b91d3cc3c53c488377518fe30cf6397c0d3c2aec45f4','31891e3085dc4cecb3de3409ce67aa84ffa41cbc749356946ab1d34d4e05ac90');
INSERT INTO blocks VALUES(310204,'18996fb47d68e7f4ae140dc1eb80df3e5aba513a344a949fd7c3b4f7cd4d64cb',310204000,NULL,NULL,'9f81657142f7523c01595bef4e9008d8525c2337f6d90140e05abad619d94416','89015233602aeb77d2097a328f2a5a065245131ac88ec6ac2d2b9b056e7764b6','c1e3b815ef7b44a995259de56999466e98c7f9d6c0dee78cad96e0f089443677');
INSERT INTO blocks VALUES(310205,'5363526ff34a35e018d1a18544ad865352a9abf4c801c50aa55742e71630c13a',310205000,NULL,NULL,'fd1cdea0193ed914cc408968efa42377d7c69453aa9bdf8bdf0731d4b1501b01','1ea101d94c29967a141d71d3b8b15b278f3530c4c16c7e0219b892072d89f8f6','a24df68da3ac7b5b37b30e6dd6525f2678fa8e8f0d6b782dd73acd7a529a5cce');
INSERT INTO blocks VALUES(310206,'0615d9fca5bdf694dca2b255fb9e9256f316aa6b8a9fc700aa63e769189b0518',310206000,NULL,NULL,'5845d6bedf81fba710999bf2954b3c1f3f9ca007a09d812ccae8e2a6d3b9bb07','e26d49ceb523c99c2583e7bec1b4bbe1f8686c2bd009626fa4c8966c642a1bb8','a61f4963ed5a816ad3bfed8ce3aeab741c9402fcf33cfce60de7a2b9f419ce3a');
INSERT INTO blocks VALUES(310207,'533b4ece95c58d080f958b3982cbd4d964e95f789d0beffe4dd3c67c50f62585',310207000,NULL,NULL,'b65cf7069a0eb909357cd5d45129b70c576eeabc0cb13404029d088e24a2be34','596206790b52de9f791b99f7e71e3543cec87d4c3b9439ded8b7cbcd182b08e6','ac3daa740c8e3e4030f352ce22746b84bdf59f7aeafca335638787f26801029c');
INSERT INTO blocks VALUES(310208,'26c1535b00852aec245bac47ad0167b3fa76f6e661fc96534b1c5e7fdc752f44',310208000,NULL,NULL,'aa54dc010fec8a0ef3871c91667c45e88ffac08ee2fc93274d7ad1b2b5b28102','3414e0af132ec9df1da5a4304a3c94529bd915631443d34b759a017ad166863a','3e2c95a281341d60fd6a813a59e6deb8ccd62fed1ec350dfd21faa4670d45370');
INSERT INTO blocks VALUES(310209,'23827b94762c64225d218fa3070a3ea1efce392e3a47a1663d894b8ff8a429bf',310209000,NULL,NULL,'c7866cb2098c87c1333da5b3dce4c84bdeb620c9f1898456b7cceb23e4027df0','56dce3d0e9dfa62c44e422f41ecc1517bc98302341496db287adf309f666d3bb','34bd0fdca56715326ac2d3f31b1ebae838202dbad86035d406679ec8a093d902');
INSERT INTO blocks VALUES(310210,'70b24078df58ecc8f7370b73229d39e52bbadcf539814deccb98948ebd86ccc0',310210000,NULL,NULL,'207a1c90d1658d55fa0fc2e1507fce98521647ab5c4d11099c2742279cc92b3f','ecd4bb45bef1d8b395add25118bbeedc8d96f818a471bd7606554946a023b151','e63b2e789bef308da00e5c7ddf5c89780af1984429fcdd55e07b3814ddef0dfb');
INSERT INTO blocks VALUES(310211,'4acb44225e022e23c7fdea483db5b1f2e04069431a29c682604fe97d270c926d',310211000,NULL,NULL,'dfc7fe172f9bc77148a1bfad5d441a3688f718b4985406d0cefd4c4dcd926208','f999268e3400907f85a0448d124df4d139b228327721fad7ad29ef595b0d16c9','2f8826e485f34aa96835e8b91ed6ad37a53c6a94ac5e70a6652d72b2ba2b3634');
INSERT INTO blocks VALUES(310212,'6ef5229ec6ea926e99bf4467b0ed49d444eedb652cc792d2b8968b1e9f3b0547',310212000,NULL,NULL,'32a39bff0606ec93454a2cb144c0bbd1939bf2be6a2ae369b885afc0b5ef33c9','2e46422b38cddef2d8a10b343115c5e587b5456480fb1a019f0a5d541e90afb8','e2cff82e5e34a815399d4965bedf70d5ec1358265703bef5a2772c1d2520c2b2');
INSERT INTO blocks VALUES(310213,'17673a8aeff01a8cdc80528df2bd87cdd4a748fcb36d44f3a6d221a6cbddcbe7',310213000,NULL,NULL,'15968873880e97e849e59971d4ef19881b1c11c3148dba966f51d986c59ccf36','fa1e7562a89ee572607e6cdbf26c80d4ee1aac2bcd45374d166e2e993f8672cb','c1e4475b7c4fdb61383fa508770f4fdfaca5628394e5e1f465adc81953b36af5');
INSERT INTO blocks VALUES(310214,'4393b639990f6f7cd47b56da62c3470dcbb31ef37094b76f53829fc12d313454',310214000,NULL,NULL,'dcbdc463154fe49a7f22611fcb53e5ca78501424ba741040d89cac9db0a03ac4','5928d3221dd0bd142368585dc56f9f8a68885be95b7ad46c35bc37fbc61f651f','6da3f0fc4ece01ada0d8fc76dba3190d1e0bf1ed745d61766b3bd0cf8e10200d');
INSERT INTO blocks VALUES(310215,'c26253deaf7e8df5d62b158ea4290fc9e92a4a689dadc36915650679743a74c7',310215000,NULL,NULL,'6047855f1c691f27ade1cc4c587f1c11ff68f5f5bd7959a23f801e5da7773eed','b6410b25a5d6f17a5431f621d6226491bcb2ed97dac543c06e832cdaa8853d5a','8f1e227b429f083de586759366794a539e0dc721416ecfb08bdb0335425db2af');
INSERT INTO blocks VALUES(310216,'6b77673d16911635a36fe55575d26d58cda818916ef008415fa58076eb15b524',310216000,NULL,NULL,'a12fbb09858868de79095c8e3222f6fa179f2f00bc3c97c8205fd9367ae05aef','f8b3b6d36fcb97071d826e68d2e6e5bc60f982c470e68644d94a6ec1342d0148','ab229426b51a98f1e4e47e0906042fa084b24b58c19423bb3e793bfd5275091f');
INSERT INTO blocks VALUES(310217,'0e09244f49225d1115a2a0382365b5728adbf04f997067ea17df89e84f9c13a8',310217000,NULL,NULL,'419d8dc096dd58523cd4822748754158f0c11945bbb62100cb5268cd802580a8','a61fb813a69ed40eae923918a73a8dfe51dd6fa14f5426ada1a5a543ab7bb0ce','de266d7fdc36fc91f4abab94928ab78eddd4019810d2f92b2a829518af2d4511');
INSERT INTO blocks VALUES(310218,'3eb26381d8c93399926bb83c146847bfe0b69024220cb145fe6601f6dda957d9',310218000,NULL,NULL,'a36c07f7fdfaf7878d73baf14aee58b42220b2b2411fd1864450ec6ce1fbd173','dc1d785fe75a506a691f0eccaf752017fbaf5ce2b7225bdde3fb538281698e4e','464942cf41e39c9ef9db96274b7df1da1db6c5406f490bd79d43f07615cf2580');
INSERT INTO blocks VALUES(310219,'60da40e38967aadf08696641d44ee5372586b884929974e1cbd5c347dc5befbf',310219000,NULL,NULL,'7958aa94088ecf0384a9a6b0569e9507d208e009e9ce139c823960e40996a47e','c9aa622e3b372ba0c76efe97c1443cb89f2dfbcf8ff5e28dedf9b3abab3d6384','9bf9d8a0e84c3ff9aaf6a1754fe6fc35b4d4df2a41713615b1c621a06c436403');
INSERT INTO blocks VALUES(310220,'d78c428ac4d622ab4b4554aa87aeee013d58f428422b35b0ba0f736d491392ef',310220000,NULL,NULL,'00907c4368c2dc76d1ef98a0ba3c86bc4746ed2734b0c10f3797e0af70714240','d0c3959f899232cdb5fed61bac2c09e45254959e8bc1a076acb3ba5e3ee63e65','adacbc3aad0457764f7cf56a9f9a17acc7684184e95d3eac17bbde4cb3122067');
INSERT INTO blocks VALUES(310221,'cf5263e382afd268e6059b28dc5862285632efe8d36ba218930765e633d48f2d',310221000,NULL,NULL,'2e42f882087dc2158036592298321113f1b34e15b414efa6d43364c06d368540','cf40107f8d11aa8ba96b03912967f88c44e69e20d7105f497d5418fc08aa5800','2cd053da11b95d507c38d9081d664adbe5d4ed37e29dfb0773bad6ee88342423');
INSERT INTO blocks VALUES(310222,'1519f6ec801bf490282065f5299d631be6553af4b0883df344e7f7e5f49c4993',310222000,NULL,NULL,'00c4a5d41dd629bd0973c03152e4519214dce68498999c8dddc1f7a1cad28a82','6a012ee8e82d8d24b0a24d4bbab74cbe226afea1a9c1e129aceccd1d7591a107','1931516d229906d6f10ef5e342e50d17f95f07a992ed7d21a68348cc7f9f8275');
INSERT INTO blocks VALUES(310223,'af208e2029fa49c19aa4770e582e32e0802d0baac463b00393a7a668fa2ea047',310223000,NULL,NULL,'41c7a0fa22ebee9d55f2a3b118314293d155c349ba01069a23ddff76dc842955','1080406ec3ccb84490487860bdd507637fa8fbdc68fc886d082bfcdf9ac835e7','36ded47c2ed71194d12dad88df58f09cf2330bd25188be88c3bcd93daf7360eb');
INSERT INTO blocks VALUES(310224,'5b57815583a5333b14beb50b4a35aeb108375492ee452feeeeb7c4a96cfd6e4c',310224000,NULL,NULL,'66c268462442b69efb56b29e08aae1a404d3543e0a20711e8998a31af45ee929','1d5188bf347d72bc66239f3b4c709ecca24141c5474755c567f4176293f275af','a194a6d16950a389fb392f1a122dca72e52485108e297f6c7988bffef8bf118a');
INSERT INTO blocks VALUES(310225,'0c2992fc10b2ce8d6d08e018397d366c94231d3a05953e79f2db00605c82e41c',310225000,NULL,NULL,'cf39fb28a7e4d4db7657bb11a30d592a15c049000d7ac86d4fb3d942bf879b95','61dccc2a6cdf50b56700c893611fac0dd6cccadcd672cd438452ebd30852ccf7','e7b04387dc33338f7b39d6c924156688295c88275fb4cb96b0bb1ea3bc1c6e58');
INSERT INTO blocks VALUES(310226,'b3f6cd212aee8c17ae964536852e7a53c69433bef01e212425a5e99ec0b7e1cb',310226000,NULL,NULL,'cb622a4d04645ad96d3e0006f2b7632e8b82e44206d6c1cb75212b059fe18de5','2c131ef357cdc433dce05cf915be1b2c243e51208c877852a19c67968caddca4','4ac767660ddf05ed19f42e78b5a247e7f9fd115154f55028f9a6d95428eb302c');
INSERT INTO blocks VALUES(310227,'ea8386e130dd4e84669dc8b2ef5f4818e2f5f35403f2dc1696dba072af2bc552',310227000,NULL,NULL,'60ae4209347248a3f7ad39b6436627f06e45433f6b6dd89cfd3383d68974a41c','200ccbec2ba0927612c50a1ce2a58f856ecbda876943bfc2d3404724fff1927a','8273442a90d408fae256c26d870aceccbb9d541fc2a104727a9875796d23df40');
INSERT INTO blocks VALUES(310228,'8ab465399d5feb5b7933f3e55539a2f53495277dd0780b7bf15f9338560efc7b',310228000,NULL,NULL,'798206ee77c9e2fc8fe943f9bf2074c9c2560f534e3304b944e2ed3c89ce8bcb','c8c9a18e8420e274c98c528e0d0636aba20f5a6c983135a61e9cd47d60123185','83617d28a54ec58cec109e93120aa8791fd76f6c04854c4f2717f30ae009d747');
INSERT INTO blocks VALUES(310229,'d0ccca58f131c8a12ef375dc70951c3aa79c638b4c4d371c7f720c9c784f3297',310229000,NULL,NULL,'becad39a4d1bc8d73a856fa1d2bfa251f29b23fec9448a91932dc610243fd8df','1d817cb41854bebc85173e6c6c0a8e6ae5a1bdbbd1077a64265ec4c96d60ca45','b7dd93aa929618526ed5d9bf1db14d9162fa88e4542d33b9ffaf174cb27c54c9');
INSERT INTO blocks VALUES(310230,'f126b9318ad8e2d5812d3703ce083a43e179775615b03bd379dae5db46362f35',310230000,NULL,NULL,'e08eac4daa7d7bc70f2f47a835bb80993d6d6db06d8d8986101b717db1c62ed6','d37fa640132bf2595891bfaa5d1d562495c780569e2a5d4f8863fd60d6396d95','feff929ebf277ff1a55e782f2f64cf72258cfee2abe21d32b3cee3b78445ec91');
INSERT INTO blocks VALUES(310231,'8667a5b933b6a43dab53858e76e4b9f24c3ac83d3f10b97bb20fde902abd4ceb',310231000,NULL,NULL,'a761c29e76c9d5090cd1d6424beb91d0a9fd9546c67ecaa6d4879177b6745b59','7bdcbdcc058e4c3d39751316b39bc65594624dc79fc8556e2847c94fb5986200','520544c049d347d95bfc6d985b11214669697790fbd05838c17dc6451bac4daf');
INSERT INTO blocks VALUES(310232,'813813cec50fd01b6d28277785f9e0ae81f3f0ca4cdee9c4a4415d3719c294e8',310232000,NULL,NULL,'5da469b7e21ad8ec4fe7cc2f426dcaeb18a3a4a3c44385d529a8b252c77a9e43','721ab1fecac8b537de1c90225f23a62d02a6e8b392f5211a8e020d9169dc75f6','793902c2bb1fe3a6242a4c96e535cb0058d7bca137d69242a333b15108e79880');
INSERT INTO blocks VALUES(310233,'79a443f726c2a7464817deb2c737a264c10488cac02c001fd1a4d1a76de411d6',310233000,NULL,NULL,'d8531834d572acc01591997cac000185facc033e1ab72f8218a70d0ae3898914','a0b57a1491335a2fde88223b77d7c8a248101187be0b71894b6c56c426603867','7dbf64b5ce7465e0e3390ea7a9ad0830ceadc19df6fc2ddf9b4d689c598c02f1');
INSERT INTO blocks VALUES(310234,'662e70a85ddc71d3feae92864315e63c2e1be0db715bb5d8432c21a0c14a63cd',310234000,NULL,NULL,'0ac6803ab61e14bb08fd8051424565086ab11b4d33faef077f5a0732eec6f766','b719ec81bc5245492809b946a86c76c121148d506292a4ae125b368f1a24b72a','ebccba6680b530c308a978224b0b18248741c3ee3d628d74ddb6dcf6bdd4936a');
INSERT INTO blocks VALUES(310235,'66915fa9ef2878c38eaf21c50df95d87669f63b40da7bdf30e3c72c6b1fba38e',310235000,NULL,NULL,'5f7de1c7fe45858dcc844604a77051d55de3b9dbb5f5d9910ead8bd0f3af48d8','8d81c116619e760608161facac457bb00d4e816c049afbe42f6e0f7d7f1d09cd','9799c2a0c24805486516ed99469538a4886cf98a49b8f76e7c20a08c262e1713');
INSERT INTO blocks VALUES(310236,'d47fadd733c145ad1a3f4b00e03016697ad6e83b15bd6a781589a3a574de23e4',310236000,NULL,NULL,'c0437ca60921bb73516c31a74f78d2fb48d2c628b629c8f55c8fbb0060718d76','1c50aa16f8543f1eee5c2585aa8f7ee373bdb58648b430189ef4d8c9b0b767db','a2b7425af7902590b1e866a3ae54a8d87d348f8a14c893d29568c870c32d73d9');
INSERT INTO blocks VALUES(310237,'2561400b16b93cfbb1eaba0f10dfaa1b06d70d9a4d560639d1bcc7759e012095',310237000,NULL,NULL,'4340ab34a083b38dbca477b6cc2479e6d70ffd6d6b9b75772068674297abadff','2f23795147dfb09a113607e442cdc926222a2b9c3dc173b9e92ab8560de20c9f','2208d39063107f97ebccec221f1fc485c86ef7cf282a82fd42f2efc7e56d7e01');
INSERT INTO blocks VALUES(310238,'43420903497d2735dc3077f4d4a2227c29e6fc2fa1c8fd5d55e7ba88782d3d55',310238000,NULL,NULL,'6a76891c10ff0f9416ae1a024b985d621154918bd8ab545980b57fd2d18c4af7','31d5717812d8f7e54ac8b7a000c7b599e2123a1de205cef6559b3930c466b961','b831385e30599354d27a0c7c8c7d06d171133062cd2f6155b7cc00e0bc422bb4');
INSERT INTO blocks VALUES(310239,'065efefe89eadd92ef1d12b092fd891690da79eec79f96b969fbaa9166cd6ef1',310239000,NULL,NULL,'1128bb89562fc3b112da425a3dee67adaf741a8021ee378bdfeb44af3b1b1fac','82b7482bdf98200b43d483dc7725ea9069ab96d897fa88dfafd73334132d362e','c55b0902647bffb9c8bb2fea2552a07d66d013de88ffe3ef943424fa69caa985');
INSERT INTO blocks VALUES(310240,'50aac88bb1fa76530134b6826a6cc0d056b0f4c784f86744aae3cfc487eeeb26',310240000,NULL,NULL,'be05624b84b2e76794f065f36b4e98d6c6c120f1d8a5db91957bbe7008ce3240','bfd037773e4ad5fedd072183d19e824c36cf21549c374f7d7dab3ac313a1542b','dece652f4fb05ff9fb6e85d949a96bddfc2cc531a9c7a3256a4eda3bb156806e');
INSERT INTO blocks VALUES(310241,'792d50a3f8c22ddafe63fa3ba9a0a39dd0e358ba4e2ebcd853ca12941e85bee4',310241000,NULL,NULL,'5abfdfb1aa42fb80ca4538062d152d965b6a7a56bd1e170a7a109409a4606b7a','e0bccb8ee5ac848700b228d8d21970f33fcc7a2c091e4b1d1f7f71c09404ecbe','7a57fbefdb5dfc3daf87cab532c7097d7bb33f70e4b982dacac1b589123d7695');
INSERT INTO blocks VALUES(310242,'85dda4f2d80069b72728c9e6af187e79f486254666604137533cbfe216c5ea93',310242000,NULL,NULL,'5f354f767df3256aa6a23544a7164160b9fabe481c85d1891f5250b3026dd7b8','a9b87a1cd3146663579bf192b97136602806865bb60ca2d464e3111872b61b7f','67b44307bb1d6d9e32122397bc1cf66ffe95ae285d57a2403854f91235fc2854');
INSERT INTO blocks VALUES(310243,'a1f51c9370b0c1171b5be282b5b4892000d8e932d5d41963e28e5d55436ba1bd',310243000,NULL,NULL,'ea3acc31b3c298237fa11ca4400c65ee46732c96e0b7fac5a183dd49d938e730','b7226a87411a48bc0b25e014f2929d63979a297600f51723a0c9bb89fef120b0','3a738918b23a0bc5db32025060dac960a735ebe0a9db335be6705370b2b9ad83');
INSERT INTO blocks VALUES(310244,'46e98809a8af5158ede4dfaa5949f5be35578712d59a9f4f1de995a6342c58df',310244000,NULL,NULL,'07ad792741a48d5a7b657e6c4dc83e3534c79bd1e7da7044139516124adc8f80','baab169058840f62c00af1dc51ee0a77fb964dd27c6241463650fdb6c77d3b6a','b0bb572001a81674ba2659b9d7b2bff4062cf6fa21c7e361dfe190099edb6c33');
INSERT INTO blocks VALUES(310245,'59f634832088aced78462dd164efd7081148062a63fd5b669af422f4fb55b7ae',310245000,NULL,NULL,'d36a618af8e92da03b373ab0137ded666db6cef906a6b2c0cb8c71057a1a5903','18cf40a1489af6f99dc454630c35dddf20acacbf979d47acb30a5831e55f920e','04a8ea6878a3649a3c0d69a7e3a6022d15eae72474215b672f9f8944f7f3ba75');
INSERT INTO blocks VALUES(310246,'6f3d690448b1bd04aaf01cd2a8e7016d0618a61088f2b226b442360d02b2e4cd',310246000,NULL,NULL,'a34e154571ee585a839053a851a007d6d433d3efd2b3e923a9c4ec4bb0dc9d98','a2103af3fa84dc4015979f3a629c46e2234f534f86d7c5a403275a8eae144ba7','5e8d222973f42712b98898de1d5bbc30aeb8c14c2d2e61f812e2f02cbe919217');
INSERT INTO blocks VALUES(310247,'fce808e867645071dc8c198bc9a3757536948b972292f743b1e14d2d8283ed66',310247000,NULL,NULL,'ee94fcb9210718095ccdf63f30ab081f45dff765a9ca4f5c86b1b0d98973ef90','39cff977657fdbe649c601531383548a3922cde40dd998c355c201cb6deee9f6','9595aad8ecf35fc0d116c709bc52b7216971c72679255dce3d57041231fcb8eb');
INSERT INTO blocks VALUES(310248,'26c05bbcfef8bcd00d0967e804903d340c337b9d9f3a3e3e5a9773363c3e9275',310248000,NULL,NULL,'029884a5273466fa45cdfbd91ae3aaca50af0771d22f6b55af6367348c2802e2','6951bec53cc30ad6d9dd3f38f5fa8e4b876cdb1637595d38614ff3e42b53edce','ce50eabd157fe0ef4628fddd70b0fcfd561edde0faa42cf73b7300cd199c90be');
INSERT INTO blocks VALUES(310249,'93f5a32167b07030d75400af321ca5009a2cf9fce0e97ea763b92593b8133617',310249000,NULL,NULL,'dc10674812c5249c693ab7b148d048439a0d77266014f3afc1810a6260838f02','2f53ae50e27194404c5b85dab55335582b2961c6997393a9c48e6708bab8f1dc','2ee3074d5d0aa67697030dad00bcafe4d23dc0b6da4082a38c785b7d9aca8b9a');
INSERT INTO blocks VALUES(310250,'4364d780ef6a5e11c1bf2e36374e848dbbd8d041cde763f9a2f3b85f5bb017a2',310250000,NULL,NULL,'a0fd49b46ff0000e83d4c56281dfe2be1bbfc924c75969726754b05bf7107641','5148416db7a3e45edd128f1b9b5c61b916ce94f25638cc90a8d73f60afe64176','e34c27c6e108eda56c1b1f5e281ca2f523b945db72a3efba2e01e4351a467675');
INSERT INTO blocks VALUES(310251,'63a3897d988330d59b8876ff13aa9eac968de3807f1800b343bd246571f0dca7',310251000,NULL,NULL,'bdef6a6203d28d314dc087e539a9cdad19d123b605824f0a66f13bf5f72de9b8','6742a15406482537d29722db3302d492647e4c7487d840fc8e7d74d0806c3bee','02c6ea7f5f2e5ece06767c3b17fc24eb52e1596a082437dac38cc4113495f654');
INSERT INTO blocks VALUES(310252,'768d65dfb67d6b976279cbfcf5927bb082fad08037bc0c72127fab0ebab7bc43',310252000,NULL,NULL,'8da11bec0d58b196ddb073d3aba0def98f01f83da654765fcae21cae6046214e','2c11848ca51ba429a094ef40b1aa019c132cd9fd6f954139dab5324d77eb7125','49a31bc466f14059a6c77038f705335a6dc4773d8d87b0e84aa5a5e69efc8d9b');
INSERT INTO blocks VALUES(310253,'bc167428ff6b39acf39fa56f5ca83db24493d8dd2ada59b02b45f59a176dbe9e',310253000,NULL,NULL,'2efa2c5781899d213741e795ca62fbee9d3ddf53792ce002db7484adc66bfbd4','1036976d6406322c4c0afb2c6be13d6b89cfb2feb30306c9df8a499330d5489f','4a65ecb59ce1d8bf929a955ee1c902804c531b46bf48443d68814861d4654803');
INSERT INTO blocks VALUES(310254,'ebda5a4932d24f6cf250ffbb9232913ae47af84d0f0317c12ae6506c05db26e0',310254000,NULL,NULL,'d062ec468e76421d3769a99eb3c8b2cbf4bf393d109ba13b3bce128613fff547','098200d06ee21c916a203065eae3cffe8e2c80e32bce890f96e6bee400cf16ee','fac0551621b4fccc06c8b0e2a3e23e2d17f364fa4b3ae4e07103509e1a0bf1b9');
INSERT INTO blocks VALUES(310255,'cf36803c1789a98e8524f7bcaff084101d4bc98593ef3c9b9ad1a75d2961f8f4',310255000,NULL,NULL,'5c531dc8a7461e9e7a2ead654509d76c9be3427b1d2b75c0ac7ae0e03126c49a','b9c0f364e8694264c33b7d993ed45f645410820dd0ff39704b79f6aaa64a46c4','43527f56f20c0e74d5e6ed3fa5856a2c99ded534b6a60986419a750c7295391c');
INSERT INTO blocks VALUES(310256,'d0b4cf4e77cbbaee784767f3c75675ab1bf50e733db73fa337aa20edefdd5619',310256000,NULL,NULL,'8da9f0162e15e33e14e5e1e22c2fd847055a65b99eec519dd069a83bb9006b51','fbb34ac53fa4a19bb467c92b87291aeafd8bf8c43be49c7d487f962df5c50d21','27e32ad35a4c5bd5b2ea00b9e97d984441ef13d65122afd162024a4fa1084502');
INSERT INTO blocks VALUES(310257,'0f42e304acaa582130b496647aa41dcb6b76b5700f7c43dd74b8275c35565f34',310257000,NULL,NULL,'0cf6657db5f3145587a466c05f237289b639668d844abfd8d46430c090b54913','71c115bc32aefb584d499c054cd09d0ea58ea0cc11d187bd5add8f261f43f055','62fb32fa2ec6f587349e0f1865626a80c08848a30abbb278bbdba98359094e25');
INSERT INTO blocks VALUES(310258,'3a0156dd7512738a0a7adba8eeac1815fac224f49312f75b19a36afb744c579f',310258000,NULL,NULL,'e340defe4bd84e788f9c5b083849e6aa1d5c7f33123ebe62d7abe04b8a9e312e','0725d989aaa9e8f1a5604f1807ec8f5aa2db518ec2397479e7e6c48c4d2b04ca','f8f6bf4fd9cb40068aec2f65913fa062ef9f9a1608cd2a122fdbaa2959d74824');
INSERT INTO blocks VALUES(310259,'e5ed3cdaaf637dd7aa2a7db134253afe716ffdf153e05672df3159b71f8538a9',310259000,NULL,NULL,'03ca0cbce5a5b50988c19c0d4e754240f50821695dca767d1169f8c7f5c1fdcc','19e343fb3645b7ae94a299eb13691ea02d054e8acef0484a95a4079e42e487b1','5f9a06c5b49b78099a61dfb78e2aa6e3eef051bc8d64f48049b346184e5b21a5');
INSERT INTO blocks VALUES(310260,'8717ddcc837032ad1dc0bb148ddc0f6a561ed0d483b81abb0c493c5c82ec33cd',310260000,NULL,NULL,'83a3b43e01f4f25ba05b527415baa3e8b8adba319628c245988136bd8fcdfcfe','de3dee5cacbf5af3aaf1dac7cae860b06af7a2ba227f2bd81840d149354a05db','634379f887ca1360541b11855641f154ada5ede15c9f19939a82a51de8be3596');
INSERT INTO blocks VALUES(310261,'a2a9d8c28ea41df606e81bf99cddb84b593bf5ed1e68743d38d63a7b49a50232',310261000,NULL,NULL,'e61c12005d60870fee947fff469631ee540b1a0d6b8aa67614cfacc0a9f65ec0','58b8a751b3daa23993a773073b44d4bb2715075dbe3cc1738f3138383646504e','7f94e9ea6bb021df9e6cde27c100dd6b14656497542a97d79b134b8af6d77dee');
INSERT INTO blocks VALUES(310262,'e8ebcee80fbf5afb735db18419a68d61a5ffdde1b3f189e51967155c559ee4ce',310262000,NULL,NULL,'c21ac4906d435af5b9ef5576da6bce454f65ef16099b7ee03219a4ae1851bb91','a1e30e203c037b242cb1a41e5fd948828da8192a5db70453602961183a00d36d','2571caae4fbb9399d9f26772dacf9a55864027d1c82a1aa36867550d1c260583');
INSERT INTO blocks VALUES(310263,'f5a2d8d77ac9aac8f0c9218eecbb814e4dd0032ec764f15c11407072e037b3c2',310263000,NULL,NULL,'676f6c532ff23839fef228a9fac7719e77a3c20efdc17f3cb2d13035c78820e8','ca47834be7a15554ab2dd401462d7d5c14f3f5f9ef9ba715488b1b3704de15ab','6615b9ed0c2167ab043f6c4e2b8f810be406013396f0a90edcb65f7e60c09de8');
INSERT INTO blocks VALUES(310264,'ae968fb818cd631d3e3774d176c24ae6a035de4510b133f0a0dd135dc0ae7416',310264000,NULL,NULL,'258854505b1d3067bf360f3d0dcb369ed7a90fec8744578d3dde51a79db72c25','21f8b38aa107a9c6fbd6439244ce85a8a6abd12fde211c4569d28353cad5b8bd','d0abc5d66f3eaafe1c9013179df68de3d12e2ca63d8573a50890ac41d57061b5');
INSERT INTO blocks VALUES(310265,'41b50a1dfd10119afd4f288c89aad1257b22471a7d2177facb328157ed6346a1',310265000,NULL,NULL,'72ab32c420a7dcac0e7c36c4d9ca81e237955b4d8bc57c87078ba292923ce98d','9685f9791c085e79a3c298dfe4f49fd1dbf8b4bdacf45e1d25e7d18382ca0e7c','3cd9a665b3536b1e250f7a981a4d6cdd81515d15403dbef6db2fab9107bc3dc4');
INSERT INTO blocks VALUES(310266,'1c7c8fa2dc51e8f3cecd776435e68c10d0da238032ebba29cbd4e18b6c299431',310266000,NULL,NULL,'b81386d19aac285fee4e39a818cb0442e378372f7d55f92e6028b37f974e4a61','578600253e06f32b4ee4a312df8213ea7cf12f841858bdf6123b0169cb4bd42e','4d92733a5c6575f8c77e3973f34b69c69f93d981fba221f1b2adcbd2c7d72e43');
INSERT INTO blocks VALUES(310267,'c0aa0f7d4b7bb6842bf9f86f1ff7f028831ee7e7e2d7e495cc85623e5ad39199',310267000,NULL,NULL,'ea8fef9e82e451d9650777b051f19fe5e34b8976f1bcc1880b6eebe5feda34d5','face84fc0aa45f7b072d73d4930b32e223cc4c22a620c39334fc836e16b2fb5c','492919e1cc67f31cd87b42c8bc8b50ca866b8fef001ac6e154e93b86cd5617a0');
INSERT INTO blocks VALUES(310268,'b476840cc1ce090f6cf61d31a01807864e0a18dc117d60793d34df4f748189af',310268000,NULL,NULL,'1545d381812f0f0caa827a237f145838276fe058b05af4808615738ca9910bf1','ee67f9fcd6ce50ee98da722352a917a46d3c71d2e5ea50294a55c613817e77dd','86fd24f10d8c7a5e466d9e67208d5e18982c0eb4a0ed143b926d05da69f4ae2b');
INSERT INTO blocks VALUES(310269,'37460a2ed5ecbad3303fd73e0d9a0b7ba1ab91b552a022d5f300b4da1b14e21e',310269000,NULL,NULL,'fd9cf61ac6e1fba409e4220a141ed6c89c18c893c7a752af53d5f7608bc04a67','6d1424cf68a5b1dfddbbafb260989c5b27c060a40026e829476d979cbd8f4412','6128b9d5471bf7e07573101648820f42ea3ba6f3f23ccc65d49a7fe914ff3155');
INSERT INTO blocks VALUES(310270,'a534f448972c42450ad7b7a7b91a084cf1e9ad08863107ef5abc2b2b4997395d',310270000,NULL,NULL,'1d34c8c0dfdb4733a7b589647abb0e6a08f8de93a5c86fbab786f6d9d1500785','fc2696c78afd3051d10ea3ecc56280d2633b732a7c755b9057aa30fb11f58f53','bc08249b37b7131e682299d7ee53cb9e48f8f200d5a4e7f3f8da00cb0648503b');
INSERT INTO blocks VALUES(310271,'67e6efb2226a2489d4c1d7fd5dd4c38531aca8e3d687062d2274aa5348363b0b',310271000,NULL,NULL,'cf38baabc6e8a082eba1bd8ca2f72af5eb01cb76bd3c9eb101b27080a3a70d17','b28638da352abf83f2250bbc2da0f75b14483d7d4c69c93636484e9e3aaa326a','0f785a63bafee05514b984af6254bd44296e4b9844ebadf809e24443adcc0957');
INSERT INTO blocks VALUES(310272,'6015ede3e28e642cbcf60bc8d397d066316935adbce5d27673ea95e8c7b78eea',310272000,NULL,NULL,'2b2763fa5ab2962582c303062da8b8da7280274e615b3e37f93a32e44793ccc8','329d5096486b8dc452e2a1ee0a36d9a17ddd5bbb3149ddeee2bdb4989a7a3a35','8b5deba3dfc13cb06eec38723f548f2fd6d531e1147edc12f49022f4982e8f5b');
INSERT INTO blocks VALUES(310273,'625dad04c47f3f1d7f0794fe98d80122c7621284d0c3cf4a110a2e4f2153c96a',310273000,NULL,NULL,'ff9df73d4f92b7557c36f20d8f622923dda225a1ae2871e60f16ee2dfdf5b9d8','f79f73097410b602df3a98901e26ed37d07f1da95249cf0e3a62c811d4f7de3a','9d0ca6e26cd8910a1dfc7c25f7f51e78077e4430b1319ddc3a967cf8807fa207');
INSERT INTO blocks VALUES(310274,'925266253df52bed8dc44148f22bbd85648840f83baee19a9c1ab0a4ce8003b6',310274000,NULL,NULL,'ece29ec2cd160d7634009f41cc2d0f13330d53ec6971c019d69dfa4367f86646','bf01b445bc208b9efcb314f1cfa1ea4300fc152ad46a973044abf56dc74e9c62','7d49f2e7c4f8568996c84c264cb1dbd8b2ba8bf119336bf26f4e89e11e8b96b7');
INSERT INTO blocks VALUES(310275,'85adc228e31fb99c910e291e36e3c6eafdfd7dcaebf5609a6e017269a6c705c9',310275000,NULL,NULL,'23738d6d8dbf8b44b481f6c0eade991987c84e8025fe1f484c7acd3ead7f4163','c0f70c46688ecb9eccaa94bdcbb3fc54eaf3af76cc450b62dfd7a9513bbbd50f','4c30970be3c58b1fe583636129da2200181b29d6acbb96116ed5ac2c2f52c772');
INSERT INTO blocks VALUES(310276,'ba172f268e6d1a966075623814c8403796b4eab22ef9885345c7b59ab973cc77',310276000,NULL,NULL,'a241e1cb19bfbebb3bbb09c6471760b8379ddc73a67d69b4d84fd1d21dfb7034','99d32cb4d9b52ec0726c907330b2a60d7cf8380c8012f804cf8838bee1b0ecec','3641c3e725d716834ac23fa588cd8cd15027e99bf6c1f671e3876b1a8a0e8b56');
INSERT INTO blocks VALUES(310277,'c74bd3d505a05204eb020119b72a291a2684f5a849682632e4f24b73e9524f93',310277000,NULL,NULL,'0efa57fd462031a87831832a789ed7751aac5f6c19a23767555b3f7145d87532','08e71c5246f1225a02a00c8b52bb7a92c6937da9c9659129a5dcd2981069bbb3','d174d374fb385a266dccaac4ea2d72a76a75c046d94bbbda2ee7295f649d01d6');
INSERT INTO blocks VALUES(310278,'7945512bca68961325e5e1054df4d02ee87a0bc60ac4e1306be3d95479bada05',310278000,NULL,NULL,'0045189a4da126b22e91e4bc2a7ac37dc90ec0869b7fcbc927919fca4cce5259','6e3580c7af675e8fdd1c5366a7af2e387f8d8d9192589794883a28ad2ce6a499','ab267fa647c85466ff53809482a652a882bd0c410ac510055c224107dc632744');
INSERT INTO blocks VALUES(310279,'1a9417f9adc7551b82a8c9e1e79c0639476ed9329e0233e7f0d6499618d04b4f',310279000,NULL,NULL,'442b7d4dee025b81c298ca0f6a5b9dbdf17ed0087fc36eab7f0671d5a19c9a2c','04f51f4c3de467be5cfb32cccba5cd482eb14657d7f67a60820204fa22afaa41','8a98c441d8c09794112b77aad59479a8b51367cd0abb88b282a0448f8532c16d');
INSERT INTO blocks VALUES(310280,'bf2195835108e32903e4b57c8dd7e25b4d15dd96b4b000d3dbb62f609f800142',310280000,NULL,NULL,'38d7f98ae9cfb8e3938032dc33899e2e3e5a88e9037571cdddf8ed4709fc8225','d25ed55e962a45fbade2012c35ef507dd76fa0c67553343bb6568569bf1c08ca','0cd48a323ba3037d916b20a06953a93f8281ec999d80d9cb96dcda6ebf41907f');
INSERT INTO blocks VALUES(310281,'4499b9f7e17fc1ecc7dc54c0c77e57f3dc2c9ea55593361acbea0e456be8830f',310281000,NULL,NULL,'51237cee3b85f1636e336259b115fad87acc830c71e13ca79e344efb7c308ecc','77eb5540b9f1e2f80cd3cb8572ee80bc112391e0236b560749aaf9952fb6705b','736bd00a9bf26d3008eafac1cfcaa4d03fa809a79e2cba3e469be8011a043cf3');
INSERT INTO blocks VALUES(310282,'51a29336aa32e5b121b40d4eba0beb0fd337c9f622dacb50372990e5f5134e6f',310282000,NULL,NULL,'73adccef91b5c738e8810d4781a38edf98d2aa0a8cb619d575e9bdeda979f1fb','889f3e1047c8ca362c1ce4749d1c7ad167dab1e5f85e509d114b1ba1bac8f240','5e420dfbfe75996c2e9bc5d2666d97fe018d02c4c16acb832efa829790d19b0b');
INSERT INTO blocks VALUES(310283,'df8565428e67e93a62147b440477386758da778364deb9fd0c81496e0321cf49',310283000,NULL,NULL,'5853e60a1b79d4f154cc1f3dc8b0a4d6130ac07784bac16f257f92b9ef294144','1ce62f0a42cb7ecd8c35436253e8234b83e81ba5abc757965b5041400139eee2','5f32d74d72797ec37de909e9d29062bb828c089ee5bbe548629c56ee70e48ae0');
INSERT INTO blocks VALUES(310284,'f9d05d83d3fa7bb3f3c79b8c554301d20f12fbb953f82616ac4aad6e6cc0abe7',310284000,NULL,NULL,'ce33194cb67aa0a5facd788cc24706ef249bcecc95a9965f91065146b33e464b','c354cfcb046ca331ae57c00f64b56defd034278e5616ef7d1f3e559dc538bf0a','df8fee3032728be5d3131064b5120fce2c51c7ab3d7ab42f9bf42148959ee681');
INSERT INTO blocks VALUES(310285,'8cef48dbc69cd0a07a5acd4f4190aa199ebce996c47e24ecc44f17de5e3c285a',310285000,NULL,NULL,'3af35e85e98aebe1a9c778570c730bf80e085a08ca707c1a5d44b50f2579e71c','35e84bd8780b8efbdc3207b9fef22e12ff71798477971a50088b9c8def3c77ed','2c007da064e18a74a19bf56c0d6404f4c06e794db736bd3001d6bc1812e391c3');
INSERT INTO blocks VALUES(310286,'d4e01fb028cc6f37497f2231ebf6c00125b12e5353e65bdbf5b2ce40691d47d0',310286000,NULL,NULL,'4b09b627adda46ee7cf7116102a330ba2aa1ce714b2fa133f7952af34a52ede9','5a868b89444476076be22e42526c4462c5b865012d9970b917376c5342750311','c1c6112ad61b02edbc8903f069a17bc0927f4168f8521cd5d310e6c872ce04a0');
INSERT INTO blocks VALUES(310287,'a78514aa15a5096e4d4af3755e090390727cfa628168f1d35e8ac1d179fb51f4',310287000,NULL,NULL,'67786e4ffab15cb78c7bb44ef160d1e5d99b599eecb5ff4f906a6599d744d410','791a49e50583660824bb3ec141a54951c2fd737ed963b1e65b653c22a4fc4a84','62536480717487ac29ad8b04b4776030b6ef6ce42d7dbd2fc6ab53f2c1c8beac');
INSERT INTO blocks VALUES(310288,'2a5c5b3406a944a9ae2615f97064de9af5da07b0258d58c1d6949e95501249e7',310288000,NULL,NULL,'600716d2696160b3ba290636180f2afa24bf8d24435022b4539a4cc965c18dfc','3a1e3da301643f22a9b2719922a4621879b2c2d8b790e646f135bc3b5d165e65','9c7e4ce3ec31ae9248b6b976014278c08e8b0743fae95776a206d9c5c075bdc8');
INSERT INTO blocks VALUES(310289,'dda3dc28762969f5b068768d52ddf73f04674ffeddb1cc4f6a684961ecca8f75',310289000,NULL,NULL,'cd6d4b17759152edbf25fd72dce9b9126ea31a2bb1a5435636801e0ee4be1158','26aeba5ab63445ebd419a02915a835d8d6a0bc25bac49dd799e356325687c8f8','944dff09faa6ed80c3a1602ace3dc63b4f137489d0c9ea432e45fc5cef428749');
INSERT INTO blocks VALUES(310290,'fe962fe98ce9f3ee1ed1e71dbffce93735d8004e7a9b95804fb456f18501a370',310290000,NULL,NULL,'04a9135f416dc041d3c1c0216a84fd780d133213c3369691fbf5e8848af9d14f','74c57c7e7db040f0974be44dae944c978ed2ddb01390d616c9bfaa6816ed198e','349acdb121649e8ca9c9566556466803d0be33742f621239108cca3bd39e8e28');
INSERT INTO blocks VALUES(310291,'1eeb72097fd0bce4c2377160926b25bf8166dfd6e99402570bf506e153e25aa2',310291000,NULL,NULL,'50f556e01b9e8c135b20187bf863839e651a0d0bf4cfd1008b446531776f7917','13ede25257044f3bd98c6905c216bed45b0d054951d2c5e86a3cf4707699a279','487d7085d1e6c224242668bf45450ec6cf0d56aba98bd5d1447c85d6d823a006');
INSERT INTO blocks VALUES(310292,'9c87d12effe7e07dcaf3f71074c0a4f9f8a23c2ed49bf2634dc83e286ba3131d',310292000,NULL,NULL,'9d4bf4b1c5dba1132a9cbfd78c1d94cbaf15d7648da80c8bc1a8dce12a79eac0','1b761ed985b1e55c95598c5c0f37df4a1e06dfd26c17792b1020cf0d28fa9a56','715d7986bb0e740706651a275e5376a52e6ddaa48080e405bedd3682476e8516');
INSERT INTO blocks VALUES(310293,'bc18127444c7aebf0cdc5d9d30a3108b25dd3f29bf28d904176c986fa5433712',310293000,NULL,NULL,'a51a3f9af39175cc9d142eff67811307ad8f51cdd8161aaf0d98af9e2be28efa','2fd7a38fbb17d7b0eec35f2f03a28c4aee7f579d7f42e3ab124cf5eca07869eb','9f82a0cff769dbd0538872004d46549b19b8e49afeddffcbb6b49b4254c0b617');
INSERT INTO blocks VALUES(310294,'4d6ee08b06c8a11b88877b941282dc679e83712880591213fb51c2bf1838cd4d',310294000,NULL,NULL,'3e9858caa8e835295aa7e78505ea34ce0726e3f5f6cf9fbc6dc4393a28724a25','36566c7c396ecf454c6fa6d3b27dd7ad2c138a85edd74672f2e7d9791e77f0b6','4d554fa9bd033e5d8c7f80abfba8b9aa5a169c04f215fcbddaa87ea39d3f104f');
INSERT INTO blocks VALUES(310295,'66b8b169b98858de4ceefcb4cbf3a89383e72180a86aeb2694d4f3467a654a53',310295000,NULL,NULL,'bf48715799c46d629641ba5b72405f6e6cf0500886da94fcc6fddd306a86b02a','2d6b79733125c81413a3e70acf597a11e986893264588da74e9b8a0d5d46e1da','5893f34d5bb90df0eab0ae014d9b7d7fbe72d10e5bb6574224baa9e706c219d6');
INSERT INTO blocks VALUES(310296,'75ceb8b7377c650147612384601cf512e27db7b70503d816b392b941531b5916',310296000,NULL,NULL,'08e2361ae4b98387ee43fd7230ea8b296dee677b337f0e211527e3cf29a64e9b','517c81a10cc4219c38e3f947dd862f6983a4a2eb22459dba31f1a656bdf4eeff','45eee86b93fee1a5aac554977577082d2f46374a77ab28540d5a74bb131bf27e');
INSERT INTO blocks VALUES(310297,'d8ccb0c27b1ee885d882ab6314a294b2fb13068b877e35539a51caa46171b650',310297000,NULL,NULL,'cfefc3138983a33686dd1fc37f06fa1d7e01d9b218f7242cdd59005633c0ded8','85ae0c384a76e7c93b29204df759293f7a488fc71edf6b4abaea1944fa3a85d7','b789bc15051032c5244a3cee642f4cb6e11e2d2f867d2d3a7699651d5a12f764');
INSERT INTO blocks VALUES(310298,'8ca08f7c45e9de5dfc053183c3ee5fadfb1a85c9e5ca2570e2480ef05175547a',310298000,NULL,NULL,'25254257d6f6724161b2b73f94d28d3fd40594b4846699b8a2d5f45d205b1fec','0633d67a69ae2c0ea1e7d3c349cfe1f3b753e387446787987c50782ee4601b68','9114f308e01b0d81fec357e564be68ab8f427aa99def423d61952463eca67fd4');
INSERT INTO blocks VALUES(310299,'a1cdac6a49a5b71bf5802df800a97310bbf964d53e6464563e5490a0b6fef5e9',310299000,NULL,NULL,'756acb1055ec75df8fa70f80e23d75f2b47e75035bfd68802e68308785a2ee14','299d47f0c18c1629003069df0afd0bb877b45f06b5609ec171c7b87ae65a0be0','ab1689ed06ebed24ffc9b55c5dc10691b368a99cb1c0a1f81d0359d05d13f10b');
INSERT INTO blocks VALUES(310300,'395b0b4d289c02416af743d28fb7516486dea87844309ebef2663dc21b76dcb2',310300000,NULL,NULL,'e30027ca81176dc1e79a0ab3a5afbb839a3338dbe9ea6057aebcd383ed884c1d','8338432f3d159dd15129a269d1cf3866cc7cda8c3845ab349ee6cc240ecd7020','0939d6b72f204819acff73bbc8a3308d638b0b1c18f649155354568a910c8fb4');
INSERT INTO blocks VALUES(310301,'52f13163068f40428b55ccb8496653d0e63e3217ce1dbea8deda8407b7810e8a',310301000,NULL,NULL,'4c2bcffc796af76a2607a978289942241e63a6387e0a2ae8fc3d02c6b5519fb0','676af2de3d30fc26112e65d493b9c2401f93822c8e414cc5e7231e60b728e6e0','daa83c0381792e9ddeee52d9c7173009231e7375c7261e8b603effeb1000b11c');
INSERT INTO blocks VALUES(310302,'ca03ebc1453dbb1b52c8cc1bc6b343d76ef4c1eaac321a0837c6028384b8d5aa',310302000,NULL,NULL,'a39fdd7f84d2f6e29b613a8a724bc0902d9abd2d6b4d2f46c3b0512928d69b3f','ef3dfc32bc5b72ec279a0229af8bf6548bfb5bf4ed717e3e81ccb7710f802021','738d525cb061bd0a909dc54c618c2ee5a37aebdaac06d825e77099163b4709f4');
INSERT INTO blocks VALUES(310303,'d4e6600c553f0f1e3c3af36dd9573352a25033920d7b1e9912e7daae3058dcca',310303000,NULL,NULL,'23f307ef560a02210f4aae5fe605c6d8af9317ab17f1e1ef0944038a3515da49','d1c0461baeac24d356af8ba5283753c778f8ab0fa222c51b753758268f1e7fa4','34769593531b667a3014e917912aea20979cf92c9552713dde80e4d70dcf6a00');
INSERT INTO blocks VALUES(310304,'b698b0c6cb64ca397b3616ce0c4297ca94b20a5332dcc2e2b85d43f5b69a4f1c',310304000,NULL,NULL,'6baa2ac646d3725fa01111959753844d22181cbbd1801cb12c4208be3709a3a3','96ea912eae3265566ab229e5d5a25354c0713471d73d866b9a09c9b2954d53e5','60e7355f566ed3d6fc7b6e9793bc0775530be498541be5623399121dc9c08264');
INSERT INTO blocks VALUES(310305,'cfba0521675f1e08aef4ecdbc2848fe031e47f8b41014bcd4b5934c1aa483c5b',310305000,NULL,NULL,'c366fd009860a090c632131eae9380820e512009bbbaa6f7bc5529afab7a88c1','35584be5484303aa263d746735209b04d92a6baa6045e2d684496ff5dabe59ef','44e4230326ec1e458212269e1ff44d1e7554a175b3e859c26c4f3e3d33e64c33');
INSERT INTO blocks VALUES(310306,'a88a07c577a6f2f137f686036411a866cae27ff8af4e1dfb8290606780ec722a',310306000,NULL,NULL,'fd12969b828d689063b4885a0356fc17e5207794d1f5b6a17bdeb8d584815a79','df65a3a9f318fd30166869a3d5d6eabb9c84399f15a7a50f39422a05ff851997','ecb8b015600a0eba4fb1ab175419b3812b4bd91800c13f8a9a9170ecb8cee6e3');
INSERT INTO blocks VALUES(310307,'bc5ccf771903eb94e336daf54b134459e1f9dd4465dec9eaa66a8ee0e76d426c',310307000,NULL,NULL,'e168094d31f56d36e4c3863fe719e6064b08ccc6f3c2adb490b1359360026aee','272ae60ff5120848055f08303e13a982fc66959f3e3b72f7d7461c7f91252944','14af4668958f133d45c8cdc8f693508cbb36474c49ddee116267f5e2ca38deee');
INSERT INTO blocks VALUES(310308,'2291ffd9650760ff861660a70403252d078c677bb037a38e9d4a506b10ee2a30',310308000,NULL,NULL,'523b3bba7b02e2c4e588f21ed14b7b4f6630f887cc89f9361487b581d7e633b5','30df282ad2859208c35204fe5e2d395734e041bd9644b8b8626678fdd64058c1','f83a9533bd42395b0be51f8965623e880826a4b09a4de4ae7b78f8ed34c16645');
INSERT INTO blocks VALUES(310309,'ca3ca8819aa3e5fc4238d80e5f06f74ca0c0980adbbf5e2be0076243e7731737',310309000,NULL,NULL,'effe1a68917014086da3bf8696f6c13f3cf2cb5cbd6c18b80ed622e476cff017','197a65735f9d06d433abdd01f29f44ec697ba537ead9107ebe9cd889393a053c','caa05eb5bb7ba980ca20dde0b385488836b1db1e68a73e97f9529c78cc824e06');
INSERT INTO blocks VALUES(310310,'07cd7252e3e172168e33a1265b396c3708ae43b761d02448add81e476b1bcb2c',310310000,NULL,NULL,'968fb8a7409531a27ffb52af484e7c1076f05b58f9a51bf9cf3d5a7d83b12002','b9b9eef5f4c1720522286ce5f6375613c267684ac330210ab664e29219065cc0','1bb5ef6617635653a92c888483d4157521405cf8b23fb693e46af6537b683616');
INSERT INTO blocks VALUES(310311,'2842937eabfdd890e3f233d11c030bed6144b884d3a9029cd2252126221caf36',310311000,NULL,NULL,'8c69639a757d0195594fa1da3f6b35a0e8c62b8df7f95db81e26d496b8c9dd72','86b9b4356e26ab703e29060a4ff1be0c5cad328b2490d983eae10c24369a1649','9facd678f588f531b30edaad155ce95ee3fb6b6ad474b7c6c430296295e7609f');
INSERT INTO blocks VALUES(310312,'8168511cdfdc0018672bf22f3c6808af709430dd0757609abe10fcd0c3aabfd7',310312000,NULL,NULL,'8d839bac01b9aae5e554f691ae0ee42cee072f9367fcc2811d4b3f65640cfcad','802b3d153e101c2772b1c96c851efab754f77fd3fd7eb59848d510f8994a9d86','7b2e480fc1f315bf509f3e6ab2e7a0c0cc9e3ce55bc94a96754dcef13bd2a6b1');
INSERT INTO blocks VALUES(310313,'7c1b734c019c4f3e27e8d5cbee28e64aa6c66bb041d2a450e03537e3fac8e7e5',310313000,NULL,NULL,'1377f4255bfd7ff6638734733a4b8faec97fd62aeb954e42b477c875ccc50b73','e96392425727ab5eb4e16a61aef7d28cd0826ad7bc1d8266b3c187bb22bb5d51','61d37eabde159a0d0b48bfe41181151267db397b9c47cb87a76548670e60403f');
INSERT INTO blocks VALUES(310314,'1ce78314eee22e87ccae74ff129b1803115a953426a5b807f2c55fb10fb63dc8',310314000,NULL,NULL,'8ed80d44f0d6ad01a30611d94b91f735ef3a166cf0dfa7531492a3e4ac7c29f1','17d9134674657a9958c43efaea302df438762233e7e5d57811b71378e3d62695','e2179b6b68fca09853ef1ffdc3f9f6edcd25f102ddf0b70789060708b3c89e94');
INSERT INTO blocks VALUES(310315,'bd356b1bce263f7933fb4b64cf8298d2f085ca1480975d6346a8f5dab0db72cb',310315000,NULL,NULL,'24b5905cf0d5349b7031870af9677916892e3292fa61455a75e84c1605a398ba','d8bad5e8a6ab63c8e0394c200e6b90cb2a1feabe3f58dc0faaaab59bb0b82654','9bbecd66b4cf28fcb204ced8e39d93eb4afd677fed5e4e52e158b67afa59188f');
INSERT INTO blocks VALUES(310316,'ea9e5e747996c8d8741877afdcf296413126e2b45c693f3abdb602a5dae3fa44',310316000,NULL,NULL,'a191657253ca159739403f35417ef74637b053db49c7db62465fde4c54e69239','daf2edaf9fb8e7f718f56cff9e570869297ce6bd350794501b05e02a541e1c84','fa135a38274ea3278d05d03638c4c03113e5ea441c86332477b0bf8589cc9d1f');
INSERT INTO blocks VALUES(310317,'aa8a533edd243f1484917951e45f0b7681446747cebcc54d43c78eda68134d63',310317000,NULL,NULL,'bf6d880b9fa42b0e38523c00c92a898093afd068450be504a0a56bafd69ed647','740737c2cd6ffb9a5e89e2ae0d34afe5f0bb48d120ae482802b76d07100b6153','00f396cc57c2d3d133c10e534be116d51e18c1961923963f954ac7424bac14c7');
INSERT INTO blocks VALUES(310318,'c1be6c211fbad07a10b96ac7e6850a90c43ba2a38e05d53225d913cc2cf60b03',310318000,NULL,NULL,'6422eb2cab5937adb9ca2194c025d0dce63cd62e18d7ebd63220207957c942ee','3cb46a2e5b1a3ef3dd37dbe0cc429962982812eb9c7f87b5282a77a4a7f6185c','79d7337745e0c7ae24b7202722daed1839d54637fab467be462ea12a02fc18a2');
INSERT INTO blocks VALUES(310319,'f7fc6204a576c37295d0c65aac3d8202db94b6a4fa879fff63510d470dcefa71',310319000,NULL,NULL,'efb625496aa4365f5ac198a82833c880a60cd5f86d04689463216619cd7d96b8','ed69cef0ba9e4a9371deca76209629cc988257493a69006504b96a99b3da4222','dc1b87481b3fea72c3a559722fef7c09c0735088b94d22814e8476942fdb0822');
INSERT INTO blocks VALUES(310320,'fd34ebe6ba298ba423d860a62c566c05372521438150e8341c430116824e7e0b',310320000,NULL,NULL,'8c3938d7b3c0a822ebee67f1ecf21b1db6496e19471cf1f2cd00f30325d0c88a','b87169ed018fdc8251d14b58f8d0e09001e45ab5dd76eb2408ab625d34ec584b','713d5e18c02f18257e9dea62e4d0a11b09a320499476897b89d382aba1f012a5');
INSERT INTO blocks VALUES(310321,'f74be89e9ceb0779f3c7f97c34fb97cd7c51942244cbc2018d17a3f423dd3ae5',310321000,NULL,NULL,'21e4c3a7afd02f183cbb69709fc6c006ab3d38fef3466de1a1870232d1c891bd','77ef24833ac345e51eeb48fa9adbb111e31ffa3739298ce12a18d2f581c9a79a','bba2ab4a03b7b81ffa73a77c41555391344ca440a4e647a615d4fc225a7d7536');
INSERT INTO blocks VALUES(310322,'ce0b1afb355e6fd897e74b556a9441f202e3f2b524d1d88bc54e18f860b57668',310322000,NULL,NULL,'01b3b28c4d8eb796827267c06e6362206884e44f40c3f72d9b5c9d1e6cdfb29a','3833d915749baf7aa33484d7a6b6b28e4acf0d78ee0f1b4e8ab44b22d756a3e3','f4c6d6c561f0cfb039691be9c3f8231de3e0d788dac03bf71b875bae14e627d3');
INSERT INTO blocks VALUES(310323,'df82040c0cbd905e7991a88786090b93606168a7248c8b099d6b9c166c7e80fd',310323000,NULL,NULL,'a362da58df0d31eeaa93a25c91c17bec62f9cad6ff0c31420584ce293ecafdbc','2d41c7286053cb2256526ce42c03ab1288dfa066720e9ae5e5dac4532d512de4','d0982ddde562afdfb0479f27dbf096aeb0d77eefcbba4a21232fee74d1dab962');
INSERT INTO blocks VALUES(310324,'367d0ac107cbc7f93857d79e6fa96d47b1c98f88b3fdda97c51f9163e2366826',310324000,NULL,NULL,'d1b353ac97e000471c66df8ee04d7b0c25f7eead2414e5648cd2ef334881bad6','051b158e05c22a326dd8becd27d142b52477b9209f369599db5c5e25484af157','e5b68749e4fe0e4872668d5c285b1be926bd12dc5689000126032df634bea3d8');
INSERT INTO blocks VALUES(310325,'60d50997f57a876b2f9291e1ae19c776df95b2e46c14fe6574fb0e4ce8021eac',310325000,NULL,NULL,'7734300dc764c67fde935dd4432396de4a31cedc2901f3fc70bf1576797cf7b0','7671d8cfff3601fc44132a6d274c1ab1fb0b4fb712041d86eb28157667682251','58ee4f7d37563d34117122dc8bb010a20845075b56ad869882281904a712e259');
INSERT INTO blocks VALUES(310326,'d6f210a1617e1a8eb819fc0e9ef06bd135e15ae65af407e7413f0901f5996573',310326000,NULL,NULL,'ebe859a722587fd456695c6a46af7f0bf54c03e940bdbb5424520a8c1fe70617','72884e56565b442c37cbbc572fa762c7b7b3c549c396037393463be7afb089fa','f39f77d3482b55c88892c2dad7bd5bbe80cae6cb390ba289a9478874be7f0060');
INSERT INTO blocks VALUES(310327,'9fa4076881b482d234c2085a93526b057ead3c73a6e73c1ed1cdee1a59af8adc',310327000,NULL,NULL,'8ced7a546ee2c746d4dc3f0ecd2fb4eaa62c65c4e98be74545d8de22c03526e6','ccbabd4fc70b15ebb6f28afa6f96e4a1f0af08e6a3cdfb518ae008432b908739','fdbce83458154ba508994a137a10765a6839480d02848e10c9a9109ba6abfb91');
INSERT INTO blocks VALUES(310328,'c7ffd388714d8d0fc77e92d05145e6845c72e6bfd32aeb61845515eca2fa2daf',310328000,NULL,NULL,'bb5d3479e492f52a0b3b69d29852faefdff645f9b113eae82594f57e8aa40b5d','42fa2df2e053f97e86881395e5d66de912e59bf73eb5be322ab170b06fabd344','5999bf8bf21c559f829a57fa7edd5c5074419d39b49704696114fecb22df290a');
INSERT INTO blocks VALUES(310329,'67fb2e77f8d77924c877a58c1af13e1e16b9df425340ed30e9816a9553fd5a30',310329000,NULL,NULL,'4ad2c9d802db762537be19143ef5eca474cd9f749bbbc661cb95bcf1dcb0b02b','a5336a1818452ca9888d582bb5ad8182e00ec37723d42e6769b001069f96232a','4a88ff263f731f81abd8e2febce738f462ee7fcac70f9b977ae05b31b637fe04');
INSERT INTO blocks VALUES(310330,'b62c222ad5a41084eb4d779e36f635c922ff8fe275df41a9259f9a54b9adcc0c',310330000,NULL,NULL,'4a9a6b59d56f6b7cf867095d939f9bddbf779141177feda470df3759b7d48be3','263932b9bd949d4b0557a7fcd5597a0c607c722b34e644f9795e4f08713a4436','a84918efd6e8771547c06ac5aa22997957477caa0f24f4d0597822d27e6a7d85');
INSERT INTO blocks VALUES(310331,'52fb4d803a141f02b12a603244801e2e555a2dffb13a76c93f9ce13f9cf9b21e',310331000,NULL,NULL,'c676b9c31e0e3d74d005ad0a52a18ba34688b6002da5d269bcea0f789a4f8e91','646197318fca63f2c8068c0a119f122d02cfea4a5c95201d6cc2eada9ba276a6','12b07925997a4864d5246dae7a5f1b4e9b95325a80f85e9419f9cea049eb39d6');
INSERT INTO blocks VALUES(310332,'201086b0aab856c8b9c7b57d40762e907746fea722dbed8efb518f4bfd0dfdf2',310332000,NULL,NULL,'cf0b702c03ecff4bda1254dd5e96ca580b69d5d02d1f233725fccbe1f5f32000','8197afee90f808a95bd5a3dbc9c41618e3a07a3039dc2e2539a94cb023e54a0b','8d2eaf4efa13f8ac8c562df50c2aa42faa1712524e5a6f3a4c9951046ce7ff71');
INSERT INTO blocks VALUES(310333,'b7476114e72d4a38d0bebb0b388444619c6f1b62f97b598fed2e1ec7cd08ee82',310333000,NULL,NULL,'b40359eb197db65549946d93a39b2a732e0694d21b8d0138b9bfce4f5a87ae5b','c8b269f3fb117e7ea3a9592a023787d886ffc388f91fd651618f807c017c9a67','47758750d0e1f7442af589928789a97083611593cf3eeb5655eafcf2ff920756');
INSERT INTO blocks VALUES(310334,'a39eb839c62b127287ea01dd087b2fc3ad59107ef012decae298e40c1dec52cd',310334000,NULL,NULL,'7cb471ec146f9ec1e4d1b93184ea641f7b8088807dedcd1c0be4ca5ba99e80e1','24eb770852273754585985a5fed612de801663408db3703bb9771d5bcf518cb9','02a05d081b1f31fb73a5cd52a6a12d16b91a5f742f79958782235eed17d00a0b');
INSERT INTO blocks VALUES(310335,'23bd6092da66032357b13b95206e6527a8d22e6637a097d696d7a96c8858cc89',310335000,NULL,NULL,'47de747ec20cbec96a6bc4b71f67ea827c7a5a1ab0d3541fd539efac7442d644','ba840a499b9de3ae457db93220ebb7bf61560f33660b8e7b980178325d114cec','fba9e40b6634a5819c749c81cfc1c7156ae285a285a9c7abcb557ceb2f4d9af1');
INSERT INTO blocks VALUES(310336,'ec4b8d0968dbae28789be96ffa5a7e27c3846064683acd7c3eb86f1f0cc58199',310336000,NULL,NULL,'c216588e623d2b3d03499c7e9f817106b20a8c98765979987633f1e4e50d9594','a6c20cca4d22fa5b8357fae640f1a90e3e656f9015eb5db289ef6da17b597f1c','d0dd8fcdb805c5ea6b264d59ebc0342fc9a733bd3e01f2e2dc218877ca6e406b');
INSERT INTO blocks VALUES(310337,'055247d24ba9860eb2eadf9ec7ea966b86794a0e3727e6ffbcba0af38f2bc34a',310337000,NULL,NULL,'a558b47328f54b79a5ad9f7737af0e4df07e13e20f150296370e111879c09c2e','15c9f81424d97e28fc5d40b9f74edee6bed3f68f8c81dcf572cbd786626ff353','1b5b59a19a61ebe9d9ce3286249ac54241471cfc8923221a9fe852d254bef71e');
INSERT INTO blocks VALUES(310338,'97944272a7e86b716c6587d0da0d2094b6f7e29714daa00fec8677205a049bcd',310338000,NULL,NULL,'31bea50c6481fa982eace70df5fc13d2981f1af13962809e3492b493a0dd4905','ee8efb364c79aae62d48d0198d7ca348d71f312eaef01daf906fec89d2fe9166','49768f28ffa34bf90e8c77e542e190702cb27fc2aea49a181d40cf219bb3ba01');
INSERT INTO blocks VALUES(310339,'99d59ea38842e00c8ba156276582ff67c5fc8c3d3c6929246623d8f51239a052',310339000,NULL,NULL,'6605ca3db3c509fbc8574f2e10a3f981e2ff17b2812946ec8f2b1e49ba44f220','af5e50fc6a529fb06423c8ad7beed13c6e1de1c3f746f53dcedb7af76e0d95ff','81d25a3cbfc83a026ad79f0727682cbb3c201d33b7983ccd4ccd5ac5173e5bcb');
INSERT INTO blocks VALUES(310340,'f7a193f14949aaae1167aebf7a6814c44712d2b19f6bf802e72be5f97dd7f5a0',310340000,NULL,NULL,'7db1ad1952cac2dda86fff6e5f939010bb30a1da26af438d354e17f423d5bf1f','f42c5c43148a61dace7d50127d905f236ad738774c20d4f874fc3b824b58cf92','43ccf07d2a227525144e345d331d14db2e1e7b38f75cde262ac79dd083a49630');
INSERT INTO blocks VALUES(310341,'6c468431e0169b7df175afd661bc21a66f6b4353160f7a6c9df513a6b1788a7f',310341000,NULL,NULL,'1a1eef01250d2c53a1b34a8ee5b1e8fce984c3d47d28c544c6e162493b51225b','5fcdf7ababadc89a26c3833bc8b819642466504b58323cded8cdb8a904239ce6','6b2e5a4e632e315bf11f8c47db7d006c892d348edfaf1eccb27cca24c972c34f');
INSERT INTO blocks VALUES(310342,'48669c2cb8e6bf2ca7f8e4846816d35396cbc88c349a8d1318ded0598a30edf7',310342000,NULL,NULL,'3c85c0b825985b04b42137da7e59fb3daaaf9e65b871b79390a4d8b31be5da92','b165c708026f386ddc7206518e594fcef7b5782fa0db77db6ce5b02e3b563145','125e12db8b360e03e22c18961c2a60872743428f940983e199e01e6ccfd881aa');
INSERT INTO blocks VALUES(310343,'41a1030c13ae11f5565e0045c73d15edc583a1ff6f3a8f5eac94ffcfaf759e11',310343000,NULL,NULL,'26f4ea323dd31b715c7a7f4ab8f1feabb199333a8494449ed538ff13215bb3b2','37808f9fb4ad766c671be7e9703aa7c7ea53991fa838400536d25f304ebe8090','f515ab3eb57dbcb4711196bca1a5028c8770509d8a8dc0b382deec2ff0f75a46');
INSERT INTO blocks VALUES(310344,'97b74842207c7cd27160b23d74d7deb603882e4e5e61e2899c96a39b079b3977',310344000,NULL,NULL,'444314748cb1fa1c836b3b4de65c3920c7fe446741193e5f77843affe3bee908','52dd50744ce4773a3db8dcf016a392a133ff7ebbeaf293d4ecb4a32fcc575a19','849da066633342a3d6616eb0522af16ff59ef93e1abf6d36836d213816a50aba');
INSERT INTO blocks VALUES(310345,'0bda7b13d1bc2ba4c3c72e0f27157067677595264d6430038f0b227118de8c65',310345000,NULL,NULL,'d1775816bb104187076be74e78e87fc6d367c3cb31d372329aec2b635002ca2e','15f4f9eb55ff5d2b8efb40a57193f253470889b1fb2f532f02b66d236bc902bf','6a0aaf301c18fed1c6590ae2b02c55d98404c8675b10d7b3bf8b2330e8bb8eea');
INSERT INTO blocks VALUES(310346,'0635503844de474dd694ecbcfb93e578268f77a80230a29986dfa7eeade15b16',310346000,NULL,NULL,'3244eed1df8ec4ae0ddb04f9f6e59e54244ca3df10dc21fc89c99c74ba734781','58faa47bcd277d0d52d39a46473882adc797797cf2c30967418fb4ae832dc21d','9f414c666ec7d88f1e5c6108dbbc232927792b7d8e3009304d4bc63f028de5d2');
INSERT INTO blocks VALUES(310347,'f3f6b7e7a27c8da4318f9f2f694f37aaa9255bbdad260cb46f319a4755a1a84d',310347000,NULL,NULL,'6fd1802c269750b69ec04df457d47cd6b44c261340ebd5b4da61f06ede6aa166','716162f3fea6641e6ac697eb11880c5b39903de4ab30fa24e899e363d5c1d9cd','4f7519bc5aca6f049cbd12673c60101e90186d546c83bd645bef5329c0c86354');
INSERT INTO blocks VALUES(310348,'c912af0d57982701bcda4293ad1ff3456299fd9e4a1da939d8d94bcb86634412',310348000,NULL,NULL,'668330e80a23f499c0e91b01c4c51aab393813b840f81b6b672611e391699faf','8c169d593d4c922ef7d3f530f6de4da37c01716f19ea19b48b122a6135f3e293','3897ce5e4de17a7426f6d9b79180b6251b2cb80eda05a6b17dece7717775d02b');
INSERT INTO blocks VALUES(310349,'ca911c788add2e16726f4e194137f595823092482e48ff8dd3bdbe56c203523c',310349000,NULL,NULL,'32b36035ac1684e93126657ecd9711feb689672f64cceb03d220a8089dfacf12','8d54849ce08f65fd3dd06baf845e5a3132b84c960e6f316c4bbbbe5a3d2b7b01','b713fa5c10580843d3fe6508febe47444a0c43e40e60e5fa053a0d7583a006a3');
INSERT INTO blocks VALUES(310350,'c20d54368c4e558c44e2fbaa0765d3aecc8c9f01d456e3ff219508b5d06bd69d',310350000,NULL,NULL,'dbe70bf3b8e4b74ac25c1b6737b6a760e6a06a4f96ee83a5ca728c8501d4af05','1e46f66542896fa2ff6048472d49feed3065a6fffaad639da03027b00ce377bf','18ad85a9454cb303b8e43ed8ce459add5f997c586daf4c5d222826a2badeec49');
INSERT INTO blocks VALUES(310351,'656bd69a59329dbea94b8b22cfdaaec8de9ab50204868f006494d78e7f88e26f',310351000,NULL,NULL,'89bb7ea865a221a3646f78ea774a7cf1e15e8d65b85ddcfbdf87773145904151','f99c452388cd3d8aa59f7c75fa06770a116b5f69263dddbb7b5fdcffc7ffc524','2f6a9e7f4e3c26743fb17486a71ddd023118fb9cfec983cb27579b2cb42f311a');
INSERT INTO blocks VALUES(310352,'fb97d2f766a23acb9644fef833e0257fdb74546e50d9e2303cf88d2e82b71a50',310352000,NULL,NULL,'fdbf27d576a72b046776be0e5c0a91d060619778aadef3df1d30f1a7785a0fdb','1d2f391bb7990954e14c69c9429b54b9f5a88791ec4b2fba2facb464152417f4','08d65bb578b63a687b04c31a074a5196a0f31d426458586eb05c67436a8cb4a1');
INSERT INTO blocks VALUES(310353,'2d3e451f189fc2f29704b1b09820278dd1eeb347fef11352d7a680c9aecc13b8',310353000,NULL,NULL,'73429d323376209447edc6d2ddbfd51f0bcde21736ea6dad61dc96b6984a1fa1','8ad1adee999dd851e81025b31920d1f0f66c1e56433e7b2b110d03cfccd7a141','cd72a28f948e6bd08dd1abbfaa13a8d583aa93167419adcfb88cc9f1c03e4720');
INSERT INTO blocks VALUES(310354,'437d9635e1702247e0d9330347cc6e339e3678be89a760ba9bf79dd2cd8803e0',310354000,NULL,NULL,'b2bbcbb6a7db94b2a5681c6e380ac13480bb49c29a3fbb3c7c1eb740f70f8324','8d6870632f2336908828a72e7445c9d8ecbec3d420b234dad2b17ae06c0a709c','41387c4ef537f1678c5a6b901ee10d80160cc88a342e1a9e46680ab84fdfbb93');
INSERT INTO blocks VALUES(310355,'ea80897a4f9167bfc775e4e43840d9ea6f839f3571c7ab4433f1e082f4bbe37d',310355000,NULL,NULL,'ccbd3ea41587c3c1d92f355979b49c5340a0a90060f07c228c22d6ff76b25579','8dfb02eb42bf84a085d150a0dc3fb2effa201594da47639e8f77fea0a7084eea','685da8498d0ae124db4d940bed662fc0cb052e203b0a1984e6b5f2dd2c7da66d');
INSERT INTO blocks VALUES(310356,'68088305f7eba74c1d50458e5e5ca5a849f0b4a4e9935709d8ee56877b1b55c4',310356000,NULL,NULL,'06a95d39e110e40ba318320d50984096cbec88c680f426f721154555efc2561f','3516c2e9b180883b3526ee0a028c6d22b2a8a028b896423eb71db31cc284d566','f110ecdf8e3091f36044c1ba9787cc6bddf5775ddcabd6f24dc16c6e2cb7dea7');
INSERT INTO blocks VALUES(310357,'4572f7f4ad467ef78212e9e08fa2ce3f01f2acc28c0b8ca9d1479380726bab1f',310357000,NULL,NULL,'443f947352e853367d1c10d25771c7d78eec22fac19c5bace6f96b8f949e264b','af4dd2cd8426ceb8c7dacc24b30d4d48e1152340a5a81f32b745878558969f4a','9a76ff7794213d5d8061f485f924956bf9aeb90bd8bd7eeda9004502bcb403c8');
INSERT INTO blocks VALUES(310358,'d5eae5513f1264d00d8c83fe9271e984774526d89b03ecd78d62d4d95ec1dea6',310358000,NULL,NULL,'c2cd71dc9e7d5ccb5d5e9d6b55c47010c9db6a573d01820da1c8960970fd571f','635f90dc6b705e3e5928101d6ffc32a247088fd8965e0e372358b35ba822df31','1feabe9769de66cb12b0f8b83c81a11138b9c5dfbf6f887ecfa72ab50b43d60a');
INSERT INTO blocks VALUES(310359,'4fa301160e7e0be18a33065475b1511e859475f390133857a803de0692a9b74f',310359000,NULL,NULL,'5b7646bafc6b11eb1554ea1e02221883043b435ae973c3678505fa2128aadfb7','eeec8a86b03a3973bdf5215e1789277ab7aa4c47f4e9f05a44a312c01e0ccf0d','5f33df883cb678ed754e91e6362ebc29dafde4e2a6e0b9a97846c0c291beb7c3');
INSERT INTO blocks VALUES(310360,'cc852c3c20dbb58466f9a3c9f6df59ef1c3584f849272e100823a95b7a3c79f0',310360000,NULL,NULL,'b0e937568a47c244e3b29cfb3a5e7196c171acc1565c44020345c715b7774658','32f4991609b3d8cbddbee2fe5e7aff49e7d4f5334ba0d283893733f19d3f448b','76128acbc2f3503bd608a6396778ae186fc180bfe34a3dc74d7fa69e095620b5');
INSERT INTO blocks VALUES(310361,'636110c0af5c76ada1a19fa5cd012e3ee796723f8a7b3a5457d8cb81d6c57019',310361000,NULL,NULL,'fd5b67bb571f4e9c0c37c6a5c9e1181133c301e05f4f97a41bd827eda7a6db3c','4ad763ba9a9de4e6fd2f48d1342b9c2b4f87224fe591cddcf0ea3aab19187ab3','5ac5a4601879ba6a2200896ee23a4a6c6441b6881a7d783a5b5fedd90212d01e');
INSERT INTO blocks VALUES(310362,'6199591a598e9b2159adb828ab26d48c37c26b784f8467a6bb55d51d7b6390f2',310362000,NULL,NULL,'38382cc090b349809c4798c3c83b485f8ff682fd5b5b2568357d62ef30f7c046','2eed1cb542570837b9e34c5ef140428d09c132369e5073061d9b1580338fad97','4fd0a63ff37e8fb5a55c45049f2dc4d8c8ef57dc1b17e25acc282d5636268af4');
INSERT INTO blocks VALUES(310363,'a31967b730f72da6ad20f563df18c081c13e3537ba7ea5ab5d01db40e02647e6',310363000,NULL,NULL,'82911a691937d87629bc14e5294f68a25ff2fc6512370db032834b85a623d5c3','baa8c23f6f8bbed9640382166a4fa59eba156a3c94b645334124a57ad886136d','3d63350e3a837c655125caa738646b4e53b562d0d14745406fda3347d07e497b');
INSERT INTO blocks VALUES(310364,'67025b6f69e33546f3309b229ea1ae22ed12b0544b48e202f5387e08d13be0c9',310364000,NULL,NULL,'cc362ce4c2142e539057430e2dd6402b985c62fefa4e4ad33afe1305f53af8a4','973037f8124687eaeba2e9f3e301cb20b9370bef4acd3f2c86eedf595b792b73','66908fa9d7b89b5ff51efa5953f0998b294a32f4adb2f6652e6a5b5f85e7992a');
INSERT INTO blocks VALUES(310365,'b65b578ed93a85ea5f5005ec957765e2d41e741480adde6968315fe09784c409',310365000,NULL,NULL,'49e41f95f081b70e3f540fa22864cc4f229ceabfdfd54f2da112f1fd35466617','aa3e39acb1dc1a955f579a9a40961a80319c5dd484ddf322ca6edc6b67cec932','832a2387fda8e43ced8ecbf888e9f2c5d50b549e6eff776f7324771549d2803b');
INSERT INTO blocks VALUES(310366,'a7843440b110ab26327672e3d65125a1b9efd838671422b6ede6c85890352440',310366000,NULL,NULL,'687c5f3e381d164499126ff90785e3635c825db3808267d4de2ec0e37cc7c597','610fbd2d8f4dad57d7efca0772534da791785cb2c45de1906a9b282792faa9f8','697cd92a766a57d9c2b1596a23fcd8d657d716f4fd6a25a0706b8fc9d248d7cc');
INSERT INTO blocks VALUES(310367,'326c7e51165800a892b48909d105ff5ea572ff408d56d1623ad66d3dfeeb4f47',310367000,NULL,NULL,'d7fe976a4b2cca2e23d082a703ef4f4739e110ce1e0a373e76064f6186856ff7','531453a70483611396ce5bacc17e22125b1b61f61d56c110fb72a929b95deb9a','c48543cf1396609605134430a5fc93923fbedf4252b58ad6e020705044d626dd');
INSERT INTO blocks VALUES(310368,'f7bfee2feb32c2bfd998dc0f6bff5e5994a3131808b912d692c3089528b4e006',310368000,NULL,NULL,'97f0a0f9e6f355dd179aa2941412decc1b0a06de0dc14dce8538aed6e35d41ba','289eb338000f45b4d7e143a08a490fbee8d307eb0975f5a2ed62586c2f625e0e','deeea67ccc286cb23f50fe8d5e642d17b124954495f641f461ab000d3cd2481e');
INSERT INTO blocks VALUES(310369,'0f836b76eb06019a6bb01776e80bc10dac9fb77002262c80d6683fd42dbfc8da',310369000,NULL,NULL,'1b5d9ec9bd918c84a5f9b6882c94a739cc1ad1362dedfbdf7b2009fd42251d66','a9122294ce4ccd606d3fa1787fb9c44f25811fb2fe486c9d58b407b5da50dd8b','197af15f362bc8c18c2bd1d5aca2b79556b33275572fffa7f868225fc7642683');
INSERT INTO blocks VALUES(310370,'9eb8f1f6cc0ed3d2a77c5b2c66965150c8ceb26d357b9844e19674d8221fef67',310370000,NULL,NULL,'578b039ed2b9a25e1c75ad9a5242c5962d6645616dc53fb08386602e40f14486','d61d958644caab04dc236d04d3654abeb1fd625dd7b9cdc01ca5caeae9b41f58','37e9260c66d48415ba90722ff4bbc074b8728ff91cae04a68b46bdd518c13eea');
INSERT INTO blocks VALUES(310371,'7404cb31a39887a9841c2c27309d8c50b88748ed5fa8a3e5ba4cc3fc18310154',310371000,NULL,NULL,'473d21b8218a2b02f7fa0d5daf114fa988e4a3d97c33aebe97e51a8d22252492','8abb7bf5c66895fd9e9de804ed8e35b3b1d12054a4e45ab3df6cd41194d836e6','e30de0f41d3926c79fd8cbea50099a41f36dc50c420c299c977b29c964921713');
INSERT INTO blocks VALUES(310372,'d3a790f6f5f85e2662a9d5fcd94a38bfe9f318ffd695f4770b6ea0770e1ae18d',310372000,NULL,NULL,'0c306eb25702d190ce32cac521b1fac9b8a7cbcf441fd74be8de2e002b4ce14c','ad3d52b024093fcc5b88b7a3176c4117468f0f675fd9e908c727ebedc5e2eff3','ff4296a6928838e82b1eeeb1f858d13c584ba88fb3e74b416bf3db9e34887ea3');
INSERT INTO blocks VALUES(310373,'c192bec419937220c2705ce8a260ba0922940af116e10a2bc9db94f7497cf9c0',310373000,NULL,NULL,'48d14b17f9074ce1f75ab32581e8f6fe7d518ebd669af6508e5d986d97c92b3d','b60270d322c86c6452289e0968be64c2217ebeec34944e43aef908e119f838ea','174a30f174545ab7ab9518f74a72f795585904f254368ae0c4deec49c312cdcd');
INSERT INTO blocks VALUES(310374,'f541273d293a084509916c10aec0de40092c7695888ec7510f23e0c7bb405f8e',310374000,NULL,NULL,'aee93917f6fe0046069aaff48d5d1875a9c4451acec6562a377428bfb1184cd4','46decb141683d0bf4c52e4f756b955c923bfb3995025d0f19a8ef7cac1dd2b60','f99326ca39fd568571a0d9a6dfab6b58e813c48de57a20beaf2e07fc3aeb98fa');
INSERT INTO blocks VALUES(310375,'da666e1886212e20c154aba9d6b617e471106ddc9b8c8a28e9860baf82a17458',310375000,NULL,NULL,'2b0d74911bba5c9530b69c04fec512fe4c5df25458e5237db884586a221fa30b','9349961eeb706cf083d6ef1fff69cc871def662dd23fd7854135c1b0dc1a78fb','ecc7a6198195814fce89d8fe77e2f894cabb15279ef709a8fa10fd828eddd25e');
INSERT INTO blocks VALUES(310376,'5dc483d7d1697eb823cba64bb8d6c0aded59d00ea37067de0caeebf3ea4ea7dc',310376000,NULL,NULL,'a6f84afe2845ba2fa4e5e7377b1d4474dbde6dfc9c4bed050e6d10cc80025e82','a5f607569f31beb9ba2a0496a9eb2eb40a6926df4b174161b73f53719ad04767','8020b19dabe8b7a9fefedcd8fcfaf7a1321daa2be8d35ef3ae629da76c73c614');
INSERT INTO blocks VALUES(310377,'f8d1cac1fef3fa6e7ad1c44ff6ae2c6920985bad74e77a6868612ee81f16b0b3',310377000,NULL,NULL,'e006e13691719e4fce65e72c692d3affeae8ae465de2a3b285a1bed4eb518a70','4dd3a5ae07e934557005871e7c72351077b1092580eadda11fcd3501bb000579','1692a74437da997a7c3d781b677f32c90ded0ae5d1b9fed1a855a3d9cb7be602');
INSERT INTO blocks VALUES(310378,'fec994dd24e213aa78f166ca315c90cb74ee871295a252723dd269c13fc614ce',310378000,NULL,NULL,'607ffa4928577b82f275750353fcecc2e50098d227f18bb8ea95ac2bbb10eea6','49533405fa36a389e0d8cac965389e23eb421da5833d625d160f75fa9defdeab','74b2a09761929974845bf4d55d7deb726b3bdab1973c60eeb9b2a6a52635022f');
INSERT INTO blocks VALUES(310379,'d86cdb36616976eafb054477058de5670a02194f3ee27911df1822ff1c26f19c',310379000,NULL,NULL,'9f17e8d662dbbfc12a56dc36172b3154bc9b05a87885d1411826481e1ca4f6ea','4514a78a69d0987ff60976334f70d0533a1c5726099ae73d93be187a57f25f44','ffadb9365f46b0db18582e14314c7dbe0fa80a7259b3f3505ec2636581adf4be');
INSERT INTO blocks VALUES(310380,'292dba1b887326f0719fe00caf9863afc613fc1643e041ba7678a325cf2b6aae',310380000,NULL,NULL,'d617e30e1a32ed1cf269a190fd4c843755413492827546a0b3ed14278f817532','77038e6b75820a64c9fc9530b3d2c8411cc4da649fc69a3d235424c2dd5500c5','1a46bd5b59ce1f47ed54a49eac43c6f87e23fecf2492d924f2f3d75311622437');
INSERT INTO blocks VALUES(310381,'6726e0171d41e8b03e8c7a245ef69477b44506b651efe999e892e1e6d9d4cf38',310381000,NULL,NULL,'8af8d819f02927de4a74d3d37dcecf6e5124d53be37603764b1b1adad13b0d7a','48b66540bea91d2c2d216d5c13e88dfd9c1f1a36cae2ec721253034041e63af6','78fd13787ff5201e0a3e1907a3b2b6720a733b1b4e23a39f447816fd8cd42c38');
INSERT INTO blocks VALUES(310382,'0be33004c34938cedd0901b03c95e55d91590aa2fec6c5f6e44aec5366a0e7d8',310382000,NULL,NULL,'809d5c20335bbefe8e4f3552e24b24d96f6ee4ab12f3bfc9e74898371cf69797','159e8434abde33d3a97a4e7701cafec884a6d0d7ad78852ee7db449a18c5e23f','50c8c27232fd5b2594609bf194a58e9f3de31e0db458037c77f544165e16c1ab');
INSERT INTO blocks VALUES(310383,'992ff9a3b2f4e303854514d4cad554ff333c1f3f84961aa5a6b570af44a74508',310383000,NULL,NULL,'d8ec301994a5333f8efe7cc547a833d26c6766deb0b39c4fc18d1bdb470ee903','aecbe5619daf47a60ab2765502725a284224c0985e91993b212c50c3449d197a','13a6081f1cb6ab1af1dc0ef67b0c8b28c201ae269c7cc26bd077b60bb82524ee');
INSERT INTO blocks VALUES(310384,'d518c696796401d77956d878cbdc247e207f03198eabc2749d61ebeadee87e5e',310384000,NULL,NULL,'fe47a03993cb9079a6e72810552d631fe838bcfaba3b34c73c9948af77266df2','e69bc390fb0a624f6d33512a55e9732857afee1b114df97761186ac648f63111','2f66d6f42c97e58cbfe71dd95520a4555226bcbb7bd650722033ff2f9423c987');
INSERT INTO blocks VALUES(310385,'2aa6a491a03a1a16adbc5f5e795c97ec338345cfdf10ff711ffb7ac3a0e26e28',310385000,NULL,NULL,'6114e98e0004cf0f9472fce6bfa6bb99ae38e57214c8b134f30da1d62399f6ef','d3e6a4df9ff34518f8fe243dc87c981aef0cc7b89ff9ca466269a19493aeaecb','8ebb0e5ce61790c2305cb0c741c41e388716232626613a921b3254f56429ca11');
INSERT INTO blocks VALUES(310386,'9d19a754b48a180fd5ebb0ae63e96fa9f4a67e475aeefa41f8f4f8420e677eda',310386000,NULL,NULL,'4c52d59ade1bd2068e3b75b8b3cd1d23c6a94b6437f7966d10f5a07bf8f630ff','1c250ef18892c191c535562bb35bb1c8bd4f515ab00bc4cf0b564436b2bd33ee','69979da8691f6161e16e041b5fd571ac3646fa1eb4937f62b37a15907595711d');
INSERT INTO blocks VALUES(310387,'b4cac00f59c626206e193575b3ba9bfddd83bbfc374ebeb2838acd25e34a6c2b',310387000,NULL,NULL,'327e9a842233568888998ec1456b6f78c093b47639707d44e6336b2bc18d955f','d7de64dd98a65b478518d909b1f0f2860f6a0b8e5e530f23ee55caffbaf1a545','7200defd6535d43330245672b1a62530db5c1cca7a39269dfdc0746582f84866');
INSERT INTO blocks VALUES(310388,'41a04637694ea47a57b76fb52d3e8cfe67ee28e3e8744218f652166abe833284',310388000,NULL,NULL,'6efaab188a5cae39ef547a804f61bcbc2be4881e0569f49d7622b407f6860401','4916559fdc472a474aa4c652c85b0db143744daed0d98d7f2fddd1dba32be88e','509839754a7098b14bbad68537a2220a6a77506263e6d7563c3d5b2a4e38754a');
INSERT INTO blocks VALUES(310389,'3ec95ae011161c6752f308d28bde892b2846e96a96de164e5f3394744d0aa607',310389000,NULL,NULL,'89c686d5d973691a7281268c867f837b86b140a05f16f12302a3cdeb3b6a0ee9','b2e0098e42f81a8a9369d510b17be67446feb3e5da1b1eb37acd9f0b33b29fce','bf9012565eba5ac9475a41f2ba82ff8f8c59741a75d8097eb069c03ec478ab1b');
INSERT INTO blocks VALUES(310390,'f05a916c6be28909fa19d176e0232f704d8108f73083dded5365d05b306ddf1a',310390000,NULL,NULL,'2c4eceebb94d0c7a7702478d9547d1afbb42ab5ecb5ae6271a3f69942bd77e50','8e3a48b160083860b0928dd97150477980da9097945c4ae3ee144c505f131b86','040c9d7544e978d183cdd454abb3aabaddd15de2d80336a866173afe2ae3b1e8');
INSERT INTO blocks VALUES(310391,'fc26112b7fdd8aaf333645607dabc9781eac067d4468d63bb46628623e122952',310391000,NULL,NULL,'06397124ee2a1bcb9104899469394855d4ecccd1a08626d650bdf3169e227831','b1b4f0fc9ba54527ea0902192a61158bb5383f1959f187915c07f88bdf11caaa','33bdd756c22a50d5f260c69d807762146bce89b44cfbd97343b0e7e7073eb64c');
INSERT INTO blocks VALUES(310392,'f7022ecab2f2179c398580460f50c643b10d4b6869e5519db6ef5d5a27d84a1d',310392000,NULL,NULL,'44974b5fec0be3a2958d39f2d6824a2e82733f873a404ec9887178c620843149','97a039be078662ac5b1a275d5618224c1a90886c79b9fb651dfcb14481da8e8a','f31f0b97dfbb1119e2269f9421ee54df95568c3cf294e746bd35478b16c007b2');
INSERT INTO blocks VALUES(310393,'e6aeef89ab079721e7eae02f7b197acfb37c2de587d35a5cf4dd1e3c54d68308',310393000,NULL,NULL,'1863677c0e552344607b1af3eb8ef8f4fc6b2a73d63eebb3e9928302c887970f','c488dd61c64182cdc779e96a2b312463d42ff9829d1d518c8a9daa1a4cb26de3','2f1e08a137937a75111dbbc9e4fdd1361100b6d468095c917d8cb10cdf512c25');
INSERT INTO blocks VALUES(310394,'2a944743c3beb3bf1b530bd6a210682a0a0e9b0e6a9ff938d9be856236779a6f',310394000,NULL,NULL,'3838ba6e84376ed8dffb3fee9b5928d903952c0d8a8ad41ab63a9651a1c8c770','e329db30a579327664d135ce9c3661a259378dcc12e179232599e0186c7bfe91','5a49d4295273ed80e950753803f468143317b02b739a41d1b98991e4b09547e4');
INSERT INTO blocks VALUES(310395,'19eb891ce70b82db2f2745e1d60e0cf445363aaff4e96335f9014d92312d20e4',310395000,NULL,NULL,'872367d61f81cddeb555da5f9c4f46a8ac57c24629ab073094e407a4555a8555','2234b36f4187eb0da9ed6a633aa2e15075d5efb23f154963885e7fd42495e4a5','9fc47a43a5cb11bf7a1ac91818daaceb7a2111322403fecf0399839fb3f83eb2');
INSERT INTO blocks VALUES(310396,'aea407729ac8d8e9221efd9d70106d14df6aaf9f2f87dc6f490835a9caadf08e',310396000,NULL,NULL,'b9a9eaaf1cf6cfa4ae5b0f314812a9a2346209da0b7ce57e16010d2a01c0092a','25946162b9af068438633980c75eaf9e508144f603f7a913de56cc11a7a482f6','f07c15882b5b8cbe6e4f56269ce6a0bfdf117a3930bcd661fa5ab0f11600a2c6');
INSERT INTO blocks VALUES(310397,'7c429e56a19e884a8a77a759b52334a4b79404081b976270114043ba94d7985c',310397000,NULL,NULL,'b61f36bcc934a18fdccf7806d41482684ca129801d0b9ce7815dcd488fc49a66','e697fb2f445f03a1d895b904be58a554af4c26ed74a65eb0e52c98e490efbd44','aeb0212745e82e9be98860e787c86c2fa05c3c125c2b9324159180625031bf3a');
INSERT INTO blocks VALUES(310398,'55c046db86dee1d63c0e46e6df79b5b77dfd4ab2ff5da79e6360ce77dd98335e',310398000,NULL,NULL,'9446476e123e5dd354682c60591cab8b712c30df9080dde756246eef45e21df5','0d20ba449b95f7d128c8b78ef2a37ec390e6177b2041a2b035a72cb8e6062ba9','8296146bdb9d78035438451466beee1e71fa847cbf201157fa01ed7471ddff55');
INSERT INTO blocks VALUES(310399,'765abc449b3127d71ab971e0c2ae69c570284e0c5dacf4c3c07f2e4eca180e7a',310399000,NULL,NULL,'50d288bca09d446f56544fb1ec50d613bdf156488468ac92d433425a3cab0804','82214bf1638d82e5b66919990e24d3960eb02a423bb3f36bcdd730b17267e340','87fe647b7b2e7705d96551c3311082bdb0829cd36f762ee673aaa827801f8b60');
INSERT INTO blocks VALUES(310400,'925bc6f6f45fe2fb2d494e852aaf667d8623e5dae2e92fdffa80f15661f04218',310400000,NULL,NULL,'349a24fd446727bb1793ccf88fc569d20eb680c10e506fc25b281ce6ec3fd7bd','e7ce5e8c9c4160590dcdaba04bc866267a9784f99fe68bebd337da16768e8f18','ad6fe8cf7b1ca017fe391b5db8787b22dea29f2c979cb2cea5fd2a26c68b270d');
INSERT INTO blocks VALUES(310401,'f7b9af2e2cd16c478eed4a34021f2009944dbc9b757bf8fe4fc03f9d900e0351',310401000,NULL,NULL,'52c06b68cad19608420b73476a73b411d0327382b92bd454cadf1b8616eb17a5','6ff1e13b2110c6ee69e86818bd32bacdffa6f4e91fd2d8c2b09b5db35062be81','8a6e37ed782e8898532ad664152a01685fd54b4ffe85435452e380ddeadfb0b9');
INSERT INTO blocks VALUES(310402,'1404f1826cd93e1861dd92ca3f3b05c65e8578b88626577a3cbad1e771b96e44',310402000,NULL,NULL,'8bf64213a454c62dd4b0dcd7dfa298da0244a6aa7ae6fff98be6f49d50d259ab','3e776187716a384a84170b2e7dbbb5c152d98535351c1f5b4b00c7bf5ea7ff33','922ea212f254923a75e6b2b9d86c6d331a9cabdd5e4326aad073f332f18f35b7');
INSERT INTO blocks VALUES(310403,'f7426dbd4a0808148b5fc3eb66df4a8ad606c97888c175850f65099286c7581c',310403000,NULL,NULL,'fb2a365372522d1442792cb38e1a4167eda2612ef442c776749097a3d541a827','1fad731787bca55d4102d8d355ccb9625590baaccd0ae63490320efbf5aaf90f','4934f36685f17524c70fdc84f046e30b92c9a1e2b26c9dabbbd6c5f497a052a9');
INSERT INTO blocks VALUES(310404,'401c327424b39a6d908f1a2f2202208a7893a5bedc2b9aff8e7eda0b64040040',310404000,NULL,NULL,'47f96d798df9cad17667be908ebb063ab9f79d947784a78189d247e626864a5f','10b2cfe8ebe45dac311048b4aa8d15d7c59ae17f5c1a0c132cfb675d893de8d5','8e557c467da3d2bc76b471cfacbf55c9f04d68ae6ff4e03ec3bdd3f5c3d3f5ed');
INSERT INTO blocks VALUES(310405,'4f6928561724e0f6aab2fc40719f591823ca7e57e42d1589a943f8c55400430a',310405000,NULL,NULL,'185780205a9ab241bb0656799fd0d5942c1e3e5854abd1d06573da550b04b096','8cbd52dd97944b34f080d675a51360dafcd38183cb08633e6ea247d2c5074435','6fed16548b7c8c562007196cd02207a2ce9249250fdb78e474dceaf3d29cd3ab');
INSERT INTO blocks VALUES(310406,'6784365c24e32a1dd59043f89283c7f4ac8ceb3ef75310414ded9903a9967b97',310406000,NULL,NULL,'367b9de2313c5f7fce0c2dc2b4a8e2bc059f6881bc924f7315e8e2ca61728a59','0d104d4ce44d11e581f51e5a33ec9e35a994b2b992842b173fb8a2756412b4b2','cbbd5f94b693937301d64788ff0c76894c88c7c4f2a4328c2ef984532e15d4e0');
INSERT INTO blocks VALUES(310407,'84396eb206e0ec366059d9e60aefdb381bca5082d58bffb3d2a7e7b6227fc01e',310407000,NULL,NULL,'2bdbd79575aa2ff52ba0cce3fc1a1aac6120d598a8ab0ff3925e1395e6cad2d1','a3407057dc90723c90ed8f2df5af7840e50daa4c4bdedd47181c17a1e8563934','be2152ead8fb09d8832eb3c4e526ee09037c326667e05bfd39197ba9bd98ce41');
INSERT INTO blocks VALUES(310408,'4827c178805e2abae5cb6625605623b3260622b364b7b6be455060deaaec2cda',310408000,NULL,NULL,'fcd0edef8c4ae9517a6e793a2742c598de38c122829b7a7aa265310417ac92c3','3ee1e7949bdb395a4e481f94344fccb2781abcb3f5d1fea2bbadb9de9228a426','c943fc6fe41e6ad638947b44faae7e132e5792c2eb8fa4a3b879db86ab953c7d');
INSERT INTO blocks VALUES(310409,'01a719656ad1140e975b2bdc8eebb1e7395905fd814b30690ab0a7abd4f76bba',310409000,NULL,NULL,'5b663c40873af21ebc721f2689e2c57a2c787fff579c58f033bba75910a64837','68fbf3a110ed24946d1594f5a4de1dae9c4b6f0394188a71ab89996e9fb4e55b','74dd3ac071da6ab8e47c48877df4c40aae28b12008a06816e415cb0a3c149e63');
INSERT INTO blocks VALUES(310410,'247a0070ac1ab6a3bd3ec5e73f802d9fbdcfa7ee562eaeeb21193f487ec4d348',310410000,NULL,NULL,'93c5a33931b2a33933bc286d6987b34730c0677460e4875d5c032ae86c2e01f0','bd755bf0718d5a0423ec41a8ac84b1554751ff8f0a3f63d87e7e0f58aaa31008','57d028eb51a5a83ef47a3029bca5b57ea9d393c018679339e4d47f342c43d16c');
INSERT INTO blocks VALUES(310411,'26cae3289bb171773e9e876faa3e45f0ccc992380bb4d00c3a01d087ef537ae2',310411000,NULL,NULL,'8d98498f89619a2e334e9ac69bf8ff37251af6431d9bb6d1ea8bbc404c5e560d','103563dcfc7b9f149b6efdad7cae17b090d4a8232fd4c37fac7bcf942d784b55','2cb1397e487c5aefcce5466283936e39f4e65d83a1551bfc1de7261439f9b4e9');
INSERT INTO blocks VALUES(310412,'ab84ad5a3df5cfdce9f90b8d251eb6f68b55e6976a980de6de5bcda148b0cd20',310412000,NULL,NULL,'a16a650c4b63ed783e7229980be1177da867c188a5039ed5c58b9717f6ccf634','4daa6f0799529346ba4ee87e2aed1450447921dfa92e785378fae39c234a7c8f','5b053c680612c3d9f1e6c4442135899eaddc93b072b940b398b53a9e5acddbb2');
INSERT INTO blocks VALUES(310413,'21c33c9fd432343b549f0036c3620754565c3ad99f19f91f4e42344f10ec79bf',310413000,NULL,NULL,'768577c1a7c2cf2cc19cd8dbe823f1bdb8a222daee4c7ac7b5ead6633040c283','7ae9815341dccd2d1bff8dbcfdbcce4e52b4aac8f2fdd421348ed9f44cd19e38','09d6ae75ffad9c53551a88fe0928d5c5b3fe240a54778586dda0e3b8244fded2');
INSERT INTO blocks VALUES(310414,'8cff03c07fd2a899c3bcf6ac93e05840e00de3133da14a413e9807304db854b6',310414000,NULL,NULL,'906c491f164877c31002da41233c237d0d4a945a0072406a7b7d13df74be7eec','807cd64b4d8ee3d91a5cbc651e42feeacd5248b6572310472743ca71a9f24621','4ee085724279fb52c94ee6067db3afc396e72a4d01f7a0c42f3b2996a9af86ce');
INSERT INTO blocks VALUES(310415,'dd0facbd37cca09870f6054d95710d5d97528ed3d1faf2557914b61a1fc9c1cc',310415000,NULL,NULL,'d27f99b4a67dfc910d3b932f97b7299779f245e95f871140d3c90f13cc6e506e','67fe947c260b3d8748887e94f68c3725664bb6dbd72187e9312ee48a42770ec3','4eb6ac2c359b001535e7283a0a0742e6df0b13e54687d9081fa37c37823ab87f');
INSERT INTO blocks VALUES(310416,'7302158055327843ded75203f7cf9320c8719b9d1a044207d2a97f09791a5b6b',310416000,NULL,NULL,'90fcd04c508a9821e0ba0ed36cd7cfadd1d3c95116e3f52ad69f98d3d14de571','1041a17c5c146181a56da6ef17386814299be8a22c76a2b2f8a4a2768b2b531c','11bd89221975183863af00e2a593521f8fb66b06a684de76c35a72a2fc370729');
INSERT INTO blocks VALUES(310417,'2fef6d72654cbd4ea08e0989c18c32f2fe22de70a4c2d863c1778086b0449002',310417000,NULL,NULL,'19cbb26c6d24df5b110a5aae9b53a911a61b2086dde926273a1b0f66c1049e6b','920154e272608daa3c501588cf0eee50c2c45a385d30f42711657ae4a6de3bf5','ac87dfd86e83284bdd5ed0e52a61232dcc1bb1c2a5cafbebf1685192e1584313');
INSERT INTO blocks VALUES(310418,'fc27f87607fd57cb02ce54d83cec184cf7d196738f52a8eb9c91b1ea7d071509',310418000,NULL,NULL,'2dc971d2db4e92e2d5dcef124bf9cdad33c41a71d6ae3db80297cb2257911f0d','290826e9c72e49636370d0dad56ba1c2c9209d888b993e030838f84300c0225a','b55694db9a0c78950f0d8dc359df38cdeb7cd7fd62ac241ef8a7fbe9be435a74');
INSERT INTO blocks VALUES(310419,'9df404f5ce813fe6eb0541203c108bc7a0a2bac341a69d607c6641c140e21c8e',310419000,NULL,NULL,'7ad2bf141622a0db4b27b1f4dab4857d1595e3f746a4113992850a680ebf1f37','d06653b493d120dd288637d530cd3f6efa1c8f5c252bb275572c1948ff0f3539','f07a5380ab1dc92ad40afe17545f2d2ea342dcd4610ad3042170f7871c58604f');
INSERT INTO blocks VALUES(310420,'138b3f1773159c0dd265a2d32dd2141202d174c2e52a4aeac3588224a3558372',310420000,NULL,NULL,'3602b26268d1bd3fc5f08f170e9767ff07c91f6976a1c342dc6b24f7ee98c509','ae8e61a57232c10bd15c655bb8c76007dcef394ba64d1619157ca58990e18c25','bcda1bb6f5b36b698834bbd3ceb742b5a0d3bfcbdf379111487f5ae26629e249');
INSERT INTO blocks VALUES(310421,'71fe2b0e02c5cad8588636016483ddd97a4ef0737283b5fd4ab6ea5dc5c56b9a',310421000,NULL,NULL,'1c1facfa3852b33c173a08d06450335a2b230541c60973a154e8dd864f3c3c8b','01bfd609f878bb6149779f6377d7868d5b7fa3b831f68cd757967b982cd09ad4','4936c1ea412f2f3dffdfbda3b510618f0eb52732fbe18f378d90b504cb9f6681');
INSERT INTO blocks VALUES(310422,'cd40260541b9ed20abaac53b8f601d01cd972c34f28d91718854f1f3a4026158',310422000,NULL,NULL,'e788123aefd1129554fa2c166dbd06ce68f913730183ca73cf248c1f5284eba4','6577ad9a9e3889fb5eeac7fc9039af8d4537a8fc28b4a9de85e230f5d9da3583','c896300d18bef7ad88059a6e937d03e0c7ebbef9435b48b8584f0a94f3bef946');
INSERT INTO blocks VALUES(310423,'6ca0d6d246108b2df3de62a4dd454ff940e1945f194ba72566089f98ad72f4db',310423000,NULL,NULL,'ad445e5351af8739b2f74cbba8b44201c20ab55ad1db064402614fb97f35c375','dd7b66518e8ec22359df2d8ad4c0349fe4ab3a74620aaf2ef4bdc93a4c7e2d92','65a454f20b4c1d4fa09803d2d772fae72d4520c64e79ea04942540213616aac6');
INSERT INTO blocks VALUES(310424,'ed42fe6896e4ba9ded6ea352a1e7e02f3d786bfc9379780daba4e7aa049668ad',310424000,NULL,NULL,'e89872ed802fe4421844882958fe6384cf21a85a6dcf10db761e2bb4a77ed24e','bb05836e569bc4c85141c5b4d2832efa5a83ad519260e96d92f6ee16fe4a0c80','0a1cb658246d6b02455eb931eae6abe0746e8c60eb8ed2f687ad2abb4cec42f1');
INSERT INTO blocks VALUES(310425,'73f4be91e41a2ccd1c4d836a5cea28aea906ac9ede7773d9cd51dff5936f1ba7',310425000,NULL,NULL,'29e595e9ac7717013cfc8d12255496192234abbddd8a66762a5eaff0c49f3750','2cedf78c9d13e32fde5792907f2ac9f409fe701740533b94ceab6b8087f790b1','dbe058b9a3988e433ca93db2aad13190fa2e184bce95954539ac1d02014fd271');
INSERT INTO blocks VALUES(310426,'9d28065325bb70b8e272f6bee3bc2cd5ea4ea4d36e293075096e204cb53dc415',310426000,NULL,NULL,'9b9509ce7b7bf380f4d030604810a755c71fabe27152be990997a6a9db37ff15','c037094c1947835fceefa8a25a81724d9c88191d5f5199d3a59339bd44407289','b03f372d1969faae308d55866de8061f89679c9560584f513d9431d642a13753');
INSERT INTO blocks VALUES(310427,'d08e8bc7035bbf08ec91bf42839eccb3d7e489d68f85a0be426f95709a976a2a',310427000,NULL,NULL,'f1b834e2a380f1b9a78c592acbe78ec809220c620e15f296ab8d7ecea6cd392e','81d439d9d368279e97c8739243efb01c7027be218d831d93127364fa247aed95','cd2f8bb4cc5da7efd2c7b965025d1aa8a51321fe985a295e4229f4131eb9931e');
INSERT INTO blocks VALUES(310428,'2eef4e1784ee12bcb13628f2c0dc7c008db6aaf55930d5de09513425f55658a2',310428000,NULL,NULL,'9e963a17fbc4a5c20d48094f1459959033520f92d7a8bc044b71bbffb8dd173d','002b7ac255f66476970512e50d7ca9cb5da695bea9763bf0379f8d8e6c77a71c','eb848b2e385f61525f501d6be7c05f9d0c329177b6b76592629bb6bf2faf6419');
INSERT INTO blocks VALUES(310429,'086bfbba799c6d66a39d90a810b8dd6753f2904a48e2c01590845adda214cf8d',310429000,NULL,NULL,'ac8cfd965b9c53f32731a3e0fcdb6df5746d646b02c88b5201a674125e37eed5','4b68376b50d77145ada0ebc72c3eb43b54b4743b538dbc9fa2c914515882dbb7','fd1f96cdc9d92cf5a9c5ba149ec5483e6135928cd11733d2d12bca75b739e8b4');
INSERT INTO blocks VALUES(310430,'870cf1829f84d1f29c231190205fe2e961738240fc16477c7de24da037763048',310430000,NULL,NULL,'33654e32dfd41ff3a5744b57fd2483a08a2b4729c18ca54c3ac5d95a1bf0ef21','3323c2d01e777caaca3eeaf6f2af8299cee1622589cbaf08f4d245356642d2f2','b41ace275ef94590dda9b3358f0e7dcffab6786310cacbbc05ba2ec0106f83d7');
INSERT INTO blocks VALUES(310431,'20b72324e40ffc43a49569b560d6245c679e638b9d20404fc1e3386992d63648',310431000,NULL,NULL,'ba8837c811ae87981cc37cb49438d958fa58dfc5a95824040f2fd088465406d1','67aadda0a565f4f5e2786b5007e56e2d10077e87e7d3acc216fe0803365b7b81','3222b7bba9967d493d10961b041044357f7489f9b803f85b792d802a4ef32b70');
INSERT INTO blocks VALUES(310432,'c81811aca423aa2ccb3fd717b54a24a990611365c360667687dc723e9208ad93',310432000,NULL,NULL,'7864019cb0cbbcd895154421183d6acb932b1d64441103b913d52469f656655f','c12942ffa02a5f8eaddf3e8e55ad0ea03f29cebd9e822e00c504c162cddd0471','31046c01a3aa517558533fbe88faa781e5c1cb6764b5f0c026fc0b63ae704418');
INSERT INTO blocks VALUES(310433,'997e4a145d638ad3dcdb2865f8b8fd95242cbc4a4359407791f421f129b1d725',310433000,NULL,NULL,'a6da92ef0df7d092de09f2f8d2c99ff65ad74e2a0bd2ea25f8335614372f5279','f0eefd9f81db595b07fe719a41e67e54fdb987e177f05d37040237db3be2a8a5','1a140e6104a971102da71d5a8f8aaf2457854c26875dc4c78fe269761d6c1f42');
INSERT INTO blocks VALUES(310434,'61df9508e53a7fe477f063e0ff7e86fbb0aef80ff2ddedc556236a38f49ac4d8',310434000,NULL,NULL,'e288db28ac6a42822f85fd042f65b57378bc6cc2f8616edfa88143d7b1c9ddcc','173f8b7d2c581e9f088b3fb6e96ad2af597b172717d8f8732fd5857997f0f3d7','03c42139757da7f7c673c5bee1a362cee3cc565d6a25ac758c1b5fd69fd1678a');
INSERT INTO blocks VALUES(310435,'f24cf5e1296952a47556ac80a455a2c45da5c0dc2b388b51d235a3f741793d5f',310435000,NULL,NULL,'e87af314e8d7a5f2315ccc559d7c2255c008ba63aff017696201db69344d423f','a4dd5a36f1aeee54e99bb23095b64707fc0b3fde5f64e33135429a100e4ea558','f64aebce10c70b3e3ca770de4ff898289f0ac3c34d602badb2ec446f9376a5dd');
INSERT INTO blocks VALUES(310436,'a5e341ba92bdf9b3938691cd3aab87731eba5428bb61a804cecf9178c8da0c19',310436000,NULL,NULL,'82327b93bd3ffcdf797bc2f6470b9c8c5101e54b924ec5f141a31356aa8865c7','c6b0f05a847c30dd3f2d3f8cb7c26a84f1d005b4720a553f9dd8b717185d7f05','f5ad89dcce89c1a057a80a5c1a42ad1fd941f61a9173d2d3ec716c44b65547bd');
INSERT INTO blocks VALUES(310437,'9e18d0ffff2cb464c664cefc76e32d35752c9e639045542a73746f5ec2f3b002',310437000,NULL,NULL,'70d86f9ef8df495474de06b94e1857693c73d9ca3528356b82553a52fdce0dda','809d60564fefff56688616b7fb96378d4eb425e5c8de36b34f0c9070935dac26','b55f241b4e06ab61692cf04dd1ac8471f3fcb401e827623ac596cfa112ce5a42');
INSERT INTO blocks VALUES(310438,'36be4b3470275ff5e23ed4be8f380d6e034eb827ebe9143218d6e4689ea5a9fc',310438000,NULL,NULL,'44b90478e32373205462f0fb212da636b31db6dfb99a2b56923beb97a3a64722','2cf7695a3cea08358af8bd9378b1d6ad6c7223cbac01589042ace6c3cb312196','81c9d18abfd08338b9d0b15230b383b321e9d190bd613d66595190a21287a8f7');
INSERT INTO blocks VALUES(310439,'4f2449fce22be0edb4d2aefac6f35ce5a47b871623d07c2a8c166363112b2877',310439000,NULL,NULL,'66b791b9deb7d2fc8b075f41d712e300ffa9c46ca9d6f4e7cec6429ca6a65163','41f11f77910c12535fa183e819b36a0dda32eaafe0ae8016e2ce7c23d5c1d67d','e64a05de00e68427bbbdf4e68adf33b97a93901486852835a9b71ecf5743eee1');
INSERT INTO blocks VALUES(310440,'89d6bd4cdac1cae08c704490406c41fbc5e1efa6c2d7f161e9175149175ef12a',310440000,NULL,NULL,'5baa10e1659182ba4511f87f08deda38d5de3501c63efd376604cc199140d27c','c6762d7334806b6b62c3cee84f65346d1121493d3bc3f890af174c4abe4710ae','aacea94a21489aa7d0397ea837f4ac0d3c561336acfd2bca86aa75f2fc3b9156');
INSERT INTO blocks VALUES(310441,'2df1dc53d6481a1ce3a6fee51ad4adcce95f702606fee7c43feda4965cf9ee15',310441000,NULL,NULL,'2d490229fead1b15a8350da7bcc83c483dae06e4a2f574c6e8fde248acd449d6','f9fcb16a928c44b86ab2af7407a2ca269455b144694a80927b9213bf8e7ac710','e7e21095b9d69b5f825d8363d378fb468eaa990ddf920b5baf57d791b364f054');
INSERT INTO blocks VALUES(310442,'50844c48722edb7681c5d0095c524113415106691e71db34acc44dbc6462bfec',310442000,NULL,NULL,'a3728bacfbdd289b7af24248b9bdacd5643bd5412bb993f5380278631eabb9e9','5d2600af95413d101a9e3d98b2d9f5ea02cf1cf6a28bf7e96870e167638a7be9','d3659ec932bcf706d9416ef7e94b3da4e5bd984b9fa218f71163e1f84ec254a4');
INSERT INTO blocks VALUES(310443,'edc940455632270b7deda409a3489b19b147be89c4d8f434c284e326b749c79a',310443000,NULL,NULL,'d829da764f6397b22a6b97ef396b363ef2cf071990df2dc9c0d03806db6a46b5','4c595c9a60ccc98d2f6cd75c92c28333174c618337457f9c5ccf362252732081','2f4850256a47573796569d31719a6f3c908eb039be4162c7bc8f14af499e52a2');
INSERT INTO blocks VALUES(310444,'68c9efab28e78e0ef8d316239612f918408ce66be09e8c03428049a6ee3d32e4',310444000,NULL,NULL,'ef53249bf0f13e1f2073b815c8d8da3ab744b6d277b29ddbc0bd68bd006af34b','5ec6d64106ac1c65cd1dd2129c786aca3cf426c7a1b5f6a966b6684b37755293','dcaa1cc8f65b4959a80b0d1394835e73109aea16474286178283706a34f37bfb');
INSERT INTO blocks VALUES(310445,'22a2e3896f1c56aefb2d27032a234ea38d93edf2b6331e72e7b4e3952f0234ef',310445000,NULL,NULL,'7e731cda90932b2b4844abdbc3ff60683173104e6c72ed81c65d9a17fd4872dc','6da5abcb8ff2a77c33c7c43061754d9fe8e587157a98e194157faf534d2ee9c6','3a5eaec8e960422afb2f197ef3e2a05506501ab5bb3a51ffda58a7174bc36adf');
INSERT INTO blocks VALUES(310446,'e8b0856eff3efce5f5114d6378a4e5c9e69e972825bc55cc00c26954cd1c8837',310446000,NULL,NULL,'db55bac8025e95a567ba984f36dcb09357aa3e9b8706bb594e669b628d4e7204','e8efb64e8f5f867f1c0db99afa9f9a3e3a06d0e1d55e16e9639ca36c3bda5cd4','cce84afd1d095bd5e4c6a75901402aed4b3fea7c9e48aa02b9cf85c3b51b7abe');
INSERT INTO blocks VALUES(310447,'3f4bc894c0bc04ee24ed1e34849af9f719f55df50c8bc36dc059ec5fa0e1c8a8',310447000,NULL,NULL,'5cc4fa447cc291ffcce7be3c4f8fc70041bf8af5c2dd591136d4a449095d2570','026eb6a7315302879ca62afb071da788deb5759eb3de89cf68fec00ec638d9f0','406f9e39e035af40f82dbdb0466282c8b7ff229d8e180183ea2a3e112f59b7f9');
INSERT INTO blocks VALUES(310448,'6a6c7c07ba5b579abd81a7e888bd36fc0e02a2bcfb69dbfa061b1b64bfa1bd10',310448000,NULL,NULL,'ce49854f4493c163bc891888f920fbc6dd8855c30870beb757df69b33de52633','e47cc99299a82c9be619633effff5b9cace113215d7f71aa7d2327e69d3ca3bb','34c08ea594d8cc84e36af8c82fbd8ceee0cc7be708f50d5b8cd9cdd66fb86e09');
INSERT INTO blocks VALUES(310449,'9e256a436ff8dae9ff77ed4cac4c3bfbbf026681548265a1b62c771d9d8e0779',310449000,NULL,NULL,'84557595cf2067a95924119b8ed5fea114acd9ca1b0df4dbe4ae5181a739b5d1','4e3048f5eeba69570f9ffd86a3573e85bdfb46a92acf60d55c04d41f49f7f870','ec0d06e8545e9e08357c2ab872826ac3b614ac3ed50d188d7d3d13d53f177a97');
INSERT INTO blocks VALUES(310450,'2d9b2ccc3ad3a32910295d7f7f0d0e671b074494adc373fc49aa874d575e36a3',310450000,NULL,NULL,'0e3b252b73fb652f904780da9fc59d1081d712337a9b15cf1a56ea72fbe96c73','c98b9428cf94077169705f3961816f87293eb89bc840167b1ed8ffb074aef48e','0e0453152812c11041ba2a361863fbc26928e90bdaebc0900359260e976430d6');
INSERT INTO blocks VALUES(310451,'55731a82b9b28b1aa82445a9e351c9df3a58420f1c2f6b1c9db1874483277296',310451000,NULL,NULL,'790eccd04e24e5f10f843d63bbdc1538cf1aabb0e8e6c862104be0ef845f603f','3fda9e8b7ebc417311c9f14e61c9dca2e490702c1c796eeb1df156f174d52cb5','b14b035157ada74692f8f46fbb5c22f36c565ba54eb32f22de32f2c5760166e1');
INSERT INTO blocks VALUES(310452,'016abbaa1163348d8b6bc497cc487880d469f9300374a72ecb793a03d64572aa',310452000,NULL,NULL,'30962129b060b63050fe8f249592587d74cdabc4ebb5680230a280da880c8586','a1bf92fe5ae4df49a6059263dfd3a9ed105ec24ae02cb9127c0408f7330d962c','5538cbdeaffe9153d33ef0592b00c060a3e4bcc09f0392d933877c6121d52ee2');
INSERT INTO blocks VALUES(310453,'610be2f49623d3fe8c86eacf3620347ed1dc53194bf01e77393b83541ba5d776',310453000,NULL,NULL,'56f4aa1086d8985a00cc295cf9618d976e69ba426b0c3d103bea6b47b58e4355','a81de51b7b56cc68f599e592be22e11c2f0b51ca27c027f13b58f05b2229a8e1','a2625b3233c0e0af566e3f582f3a7fcf269dd0ad2e19888e6432632276320b98');
INSERT INTO blocks VALUES(310454,'baea6ad71f16d05b37bb30ca881c73bc48fd931f4bf3ac908a28d7681e976ee9',310454000,NULL,NULL,'38d14a206003b812cbaf5f200235dbe12aa6a674e5f3379cb186a781cb5a5654','022e8475ba7e68c75b4a00387ae431b7bdaa4d125dcd1b19d08e9c431d3e6057','44791afe50ccf8d9bb7cefd5ba59fa4235a2890c535c9bba75b33ff7804bf389');
INSERT INTO blocks VALUES(310455,'31a375541362b0037245816d50628b0428a28255ff6eddd3dd92ef0262a0a744',310455000,NULL,NULL,'b2ff303a67c05bc12fcdfdb774ea4ddc690434c3371428b3416d38105f265f28','91a1dc2fe8dd56e137b210136966950c79b4badcdf787b4b9fafa7985847192a','8ffb4b1542e54f5b1dee4af634bc93c95ba1a1efcc858d46f36a16b82785503c');
INSERT INTO blocks VALUES(310456,'5fee45c5019669a46a049142c0c4b6cf382e06127211e822f5f6f7320b6b50fa',310456000,NULL,NULL,'6cc16b442fd7758ed7bae9f50367fa60debdb5d81bffc5abccda044573aeaf15','5125d7f8718a5a26aed1e1db2ce80e8d2eb4d96bbc91277bace52f571b7f8c26','2d98ae3b9a116b263b4a767fbc9f165aeb60eff5ef08b7dbc40650ee7c2b550a');
INSERT INTO blocks VALUES(310457,'9ce5a2673739be824552754ce60fd5098cf954729bb18be1078395f0c437cce9',310457000,NULL,NULL,'8fa0401d245b1b1e8b40760a54f331564d8597e242462ec412878e36a9b06800','061dc1962f44d4da9de8ad6bff4d96650058f5d444951e9c808b901db8717c81','733a69987b34de657a71c45843e247a3fc6eb17b48b2f45c9c4083e6859028f9');
INSERT INTO blocks VALUES(310458,'deca40ba154ebc8c6268668b69a447e35ad292db4504d196e8a91abdc5312aac',310458000,NULL,NULL,'520f92700e31b8a35260a280ae11bf8668b0e09d34795a9d88678f2977e19f7c','b0208287d25e4ca6a1856236b4d4c7a3608533f0a47a9c673806d5d3baeb2297','09a0836c80cb8bbeb7cb277260550366dbb40d84a7e210dda609c0c63f468390');
INSERT INTO blocks VALUES(310459,'839c15fa5eea10c91851e160a73a6a8ee273a31ab5385fe5bd71920cbc08b565',310459000,NULL,NULL,'d7f728b78228a914b8767a6caeaf2267e9dbd50490a27f6c23bd96060eab8ee0','21a24d787b30434a230cae77e281636855ff40a8fb4aaaad35eb034835f63e97','1a44d01f35cfa784af70e6993c03095ccefdb5504bb34c5e968dbaf299837bf6');
INSERT INTO blocks VALUES(310460,'9b5f351a5c85aaaa737b6a55f20ebf04cafdf36013cdee73c4aaac376ad4562b',310460000,NULL,NULL,'33c2b4c6d22888448a2458ff2ce6a1cfae5e858acae2a57e4cc0232980f8fa4a','2ae25ed250bd603684d0affe8b14af5a1b8d1554beaed08aa8f723cc3c66cf8d','c1c9a23ec73518a61bf3f7cc47688c42a6395b8cf094822030a7f9dc224fecfc');
INSERT INTO blocks VALUES(310461,'8131c823f11c22066362517f8c80d93bfc4c3b0a12890bdd51a0e5a043d26b7b',310461000,NULL,NULL,'22426912d3317922912326da552af284677c9b76b6416b6c056668f27ae4f19f','13b7774cf2a5a0f3d65031cd5f9ee498eaeee5c1e0e8ecbd346e0427d847a5c0','2e8786706cfe740dac19f4a1443fce0bcbc123f73002aa648a7da7f5e7caa97d');
INSERT INTO blocks VALUES(310462,'16f8fad8c21560b9d7f88c3b22293192c24f5264c964d2de303a0c742c27d146',310462000,NULL,NULL,'74225b62e696aaeafbd4d6db40b41081c7493d9cc44984729d8619ff9450ce32','4f23d4da0bbe4b8bb7e00b6b746b4180356013c63f7a6f9b3eee479380b04e4f','ddd5bda2b7545d072551013819672a23737e4534020ae5cd17ef8d39cf6e7070');
INSERT INTO blocks VALUES(310463,'bf919937d8d1b5d5f421b9f59e5893ecb9e77861c6ab6ffe6d2722f52483bd94',310463000,NULL,NULL,'b970979bfe0d44ae2f21f7d98bdcc4ae37287b93cad9fa51f32a62337ceba0c1','7b9a9095733a9d870b33aef4bb15767c32b012c27b52de8731358178b87bfb50','6fc633e9ff7a02f50981c5d214a308d92270cc001ed608f28c131d0feee8e44e');
INSERT INTO blocks VALUES(310464,'91f08dec994751a6057753945249e9c11964b98b654704e585d9239462bc6f60',310464000,NULL,NULL,'00007a158b003fcca20c9fcaa8d73a556f0206bc9a7ab3e5c566ea1bda8648cb','28d7eceb69efcc6736dd64c65ed218dae2e8d0e9d4d7284b0572a5d1065a9d52','c0e9d7733d5ba65eb2ac43c12efd2da92b427015e9a107ee873ac3eeda7902f7');
INSERT INTO blocks VALUES(310465,'5686aaff2718a688b9a69411e237912869699f756c3eb7bf7c3cf2b9e3756b3d',310465000,NULL,NULL,'09c407870b056db90148a9e4cb8ada003898ff28c584bec6a5be90514758a851','7a4f4ed76efc69ddb5fc13abe258656d6a5e4a845203b5f3f9133716093d7f6d','4b70069cd971f4dfc1e67893daa8660861eb6032563ca7633f58f32eeb045477');
INSERT INTO blocks VALUES(310466,'8a68637850c014116da671bb544fb5deddda7682223055a58bdcf7b2e79501fc',310466000,NULL,NULL,'23bcfdbb44d8fc2ae6a86ea073ab080158014f04516b256a70d846399e7383cd','57124a566cf1e863b27fa19e3c982fe4a5115119ffb745624697380ad8d5f900','fe03b9bbefc0174bce42b84fc9d69741deb3879e427186ae0a2ec933f7f7a2f5');
INSERT INTO blocks VALUES(310467,'d455a803e714bb6bd9e582edc34e624e7e3d80ee6c7b42f7207d763fff5c2bd3',310467000,NULL,NULL,'a43abeddb61ad99d57f208cb0c6cc3e0b05a200009e6d90641a2bc7aac707adf','fb3b1ef99d2f323e1bdd6998b78b6044c8c7328fafad6b9fea1de7bd0244a265','1457c3c53a1438c65a8ac60b66a1bb5ac8a984811707b518697dfd340e86840a');
INSERT INTO blocks VALUES(310468,'d84dfd2fcf6d8005aeeac01e03b287af788c81955612375510e37a4ab5766891',310468000,NULL,NULL,'fc909facd6ba38fa0908fd49a6e2f25bd8284de5265ef761497b8a2d595344b3','5c84a33365a6954fe639a1c2b1df030b8728d5d331df5ea1ef4a60f976cfa5d2','ae3213702be23f8bb084926661b80af14e0ff1e020763eacef2387ad3fc56813');
INSERT INTO blocks VALUES(310469,'2fbbf2724f537d539b675acb6a479e530c7aac5f93b4045f4356ea4b0f8a8755',310469000,NULL,NULL,'09f0d1c9bde8cdd63544fbb5eab46c2954654d32f3736f9975cf860588aa65cf','38083f12891b03e2f089b02f7cb6b7fc7b6cb7091613e1d299051717eef6748b','b59cfff2482c5c0d2faa04ea4970003d1a1e130c6128f966f2cff413d0ffa087');
INSERT INTO blocks VALUES(310470,'ebb7c8e3fbe0b123a456d753b85b8c123ca3b315da14a00379ebd34784b28921',310470000,NULL,NULL,'41832b12459e778621b8f576e597b9f639390338605b30e5be28423b016b199a','bc0a8227d8698655c56004a73150eb92144469fd22d4ce8bf0f48c27084e99ae','daae99af681c8c7ef77d711e322c17eac6c3b240d8d35b17ca87e6581d4a0190');
INSERT INTO blocks VALUES(310471,'fc6f8162c55ecffeaabb09f70f071fd0cb7a9ef1bccaafaf27fe9a936defb739',310471000,NULL,NULL,'bf701017153742cb597353349c90ec66f790f222dd98d617d98a0117f1de3274','d912707e01e39b078d3cee49df85af32019d7367d199543259bc98864c3ddae5','706fc4045c80960f844116ebcfd15769d4c2b9d44cf3205867810f4d64511f7e');
INSERT INTO blocks VALUES(310472,'57ee5dec5e95b3d9c65a21c407294a32ed538658a6910b16124f18020f16bdf7',310472000,NULL,NULL,'2a162bbd5a20f89a39156995658fd0c4715881bc130922d0edf95b60ece60b9c','c9f21a9ff022fd95423d3eb56017f4f6f8ad56a9fde974c5d08b37f01a0d0f13','44091ff03fdfebca7b824eeac1486ef1e77dfeacea2ccec91f21587351efec44');
INSERT INTO blocks VALUES(310473,'33994c8f6d06134f886b47e14cb4b5af8fc0fd66e6bd60b3a71986622483e095',310473000,NULL,NULL,'1ce10996ec9e37d8ddc204f038542c6781da88d2d45bae1952a88ab993b81e88','ad410d51bae82f8322d110d7b2270a1ff74c0ca64dfc31c5d293cfee7dbbb459','48304cd55f4ede39e1c56b386826964fc8715146d8e368711f33e9400280bed9');
INSERT INTO blocks VALUES(310474,'312ee99e9526e9c240d76e3c3d1fe4c0a21f58156a15f2789605b3e7f7794a09',310474000,NULL,NULL,'5ae424c24ca30aad5aca8298a13ae9371f55b15bc789c7731d833c6e7c7cb04e','b091eceeb4b263d9fa55bd5595cd298ff8b335e03007d62339033cd884137d48','d5c650cee209dfc09a93c25583adb10d36c7d85e5e061c5f5d83acbb4eeca337');
INSERT INTO blocks VALUES(310475,'bb9289bcd79075962117aef1161b333dbc403efebd593d93fc315146a2f040eb',310475000,NULL,NULL,'b9b257efe76a36c340629ceb265822dd10449a08eadc69667a8ea05af5c052f8','345c94c7b237efaf2b4e92802125b7d783e456e36ab6868d1f4126698361ba89','8087122e7e4d4981ebde8a7eb1111e23c64e5ae2d76913c2b9f1eba859cc2e57');
INSERT INTO blocks VALUES(310476,'3712e1ebd195749e0dc92f32f7f451dd76f499bf16d709462309ce358a9370d0',310476000,NULL,NULL,'070c06b36f3a77c04fb4bcc3ab1045e95f198f3f970846e59c35db0d03cdaf2c','014e01dabe6dd8db8e0477f9b12d4f4e3589e41223ec8c9ca5035b942524ca41','e4cd72ae77ef635066c9e3ac9404d6e62d488add9a04529127651f816154010b');
INSERT INTO blocks VALUES(310477,'7381973c554ac2bbdc849e8ea8c4a0ecbb46e7967d322446d0d83c3f9deab918',310477000,NULL,NULL,'4954596dd44d112fd0407c215be3c9534a348d6f708ae4a1e66527d1ac2830b1','1351438c8ea21d9619f81e51cfd188dbefd6a4816fe3c30b68210ac160890e9b','8f5b340dcdedd6ae4589ac3fc0a76b24637e7eb018165e270e6d6627d82ced64');
INSERT INTO blocks VALUES(310478,'c09ee871af7f2a611d43e6130aed171e301c23c5d1a29d183d40bf15898b4fa0',310478000,NULL,NULL,'d9cac2e29863569bc96aaf022437906a534968a17bf965c54bf59931cd92e590','cbec4d277b86a587fd0463340a8990600046f6f166f6fde0b6ec1ee817ab12bb','b4bbb665ecb6aefb067e16848908bef515dccace3f04fcf300f3ad97d6f86600');
INSERT INTO blocks VALUES(310479,'f3d691ce35f62df56d142160b6e2cdcba19d4995c01f802da6ce30bfe8d30030',310479000,NULL,NULL,'2e48a89a55b6f368745e1c022683e93c20bdd920011518f18fd936f2190ac5e0','81d4ab55e022000a1bb3fbe758e497425c5196951c3e7896d3c641d54b4f2db6','4887e40ca3c5c77c9fd8eabd5e0f4f398462c492435e60170889685ff451f45d');
INSERT INTO blocks VALUES(310480,'2694e89a62b3abd03a38dfd318c05eb5871f1be00a6e1bf06826fd54d142e681',310480000,NULL,NULL,'aa54124d86e74bebd14ea481ac2a5a5186236ffe214747f1af11ac370565525c','8d7e0f8a6f052692155e23eb612c02468830485938e7cb77a91e0c2061611385','79c9ddaeabedea01cd8f06e0e373e66bbb7ed3cafd2b3f1c53820855f951ece1');
INSERT INTO blocks VALUES(310481,'db37d8f98630ebc61767736ae2c523e4e930095bf54259c01de4d36fd60b6f4a',310481000,NULL,NULL,'fbbe1266bb773e5a3f5b48e82566ff75bc74bfea9424f81f670952565db15c59','8bc755d288d8d6525d9161e5d5072631a72e46d2373de37c7851aa10f3479ed5','d175f441efa0df068b749a90eb5c88998db0c9b0a3a7a551f82035ce99192036');
INSERT INTO blocks VALUES(310482,'2e27db87dfb6439c006637734e876cc662d1ca74c717756f90f0e535df0787d6',310482000,NULL,NULL,'bd28a97e90054319c4c301c3e99d68aaa5e1bf5a145a8f2c4529040bb8137209','838486910c9c7722fb3afbac7b0514cdd94126486f6671697423b34164b9906f','c694ce95e84b3cee8a705a181d9149248bb659e901dc8c1ad4c910ebe75a3baa');
INSERT INTO blocks VALUES(310483,'013bac61f8e33c8d8d0f60f5e6a4ec3de9b16696703dea9802f64a258601c460',310483000,NULL,NULL,'fbbeacec99c9ed99a7fc37cdd5673fe8bdce08eba7fcb25b696e262af29ca5d8','2be6ebe515877a76a7b83b1929ca2ef77be1df3aa3d6766c0c47450898ad7adf','82211621fcdcb509f59849369b5e7589336460b16dba9a6692aa2fc612330838');
INSERT INTO blocks VALUES(310484,'7cac2b3630c31b592fa0497792bed58d3c41120c009471c348b16b5578b3aa2b',310484000,NULL,NULL,'310bc7c61c1325ee3f97e888658fd74e1fe4adccef4924abb6978150fe6f3dad','ec800faf2b61e7b1c2c85157d09b058f59defc14ffbe64d82dffea2a0368ade2','45b377c86df7974a6ccded36ebad5eba11107142c8dcc5d1c9afe4a3e9c6ff0e');
INSERT INTO blocks VALUES(310485,'eab5febc9668cd438178496417b22da5f77ceaed5bb6e01fc0f04bef1f5b4478',310485000,NULL,NULL,'b7f66db9ea5838b65286422d0cac262f6b81bbd5a7397adf7b8d85b21354dbcd','c2c0301119eb8f6e5ee8f72a4f93366a7c2b9f327f087a5aabff7d73892ca74f','aa75dcd8f063732620e0ff45e462ea2e77b684cfc0849a7601e67e096f566480');
INSERT INTO blocks VALUES(310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,NULL,NULL,'0f829769e4da773089d7b05047a499db5f6d1b17795d4fba912882caee9813e0','ea66c7d9251a0eb884fef48de05cb58bbcf3a9e08319f01c96f180aeb0de9bab','84e19bb72b6eda92f25fbda46a71b5667ccb99101b1fd61c21dd449b6164fada');
INSERT INTO blocks VALUES(310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,NULL,NULL,'4b4d7a79843342e96e5d9d71bbc49690245b3098be75e7b86f273021d526216d','76fbd411c43f3f67c8bf61138c5672de0cfda2d98f112a6e50b3a5d084d7cc72','6bed8b3dd1b2e231ab1558b844c960c11100ae5ce0d63273a235c4fbad368fad');
INSERT INTO blocks VALUES(310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,NULL,NULL,'2d7e59026ea4c8933e9c7474936931ca49d4af91f9b9985f3c76085fb3a69104','78e801f2d1968c860ac2563e9cc912c18cb8e5f95996011e84c289833fbd46da','a9b4ba01e9d690f998df1804cdadfab24eb104051177772cdbde05cddbc571f2');
INSERT INTO blocks VALUES(310489,'2efdb36f986b3e3ccc6cc9b0c1c3cdcb07429fb43cbc0cc3b6c87d1b33f258b6',310489000,NULL,NULL,'716354a370f344980e98785a444b56b21188bc699e7fbd0c877b6f2fabf35efc','23d9af03e6aa29fbab29c8e2a5a0419680053bba19594105cc8ef4d3db05d418','9c27f546ea9df51ab1b50f5bea7204b39c2b31d042dbfb6f0692f1badfe6abce');
INSERT INTO blocks VALUES(310490,'e2cb04b8a7368c95359c9d5ff33e64209200fb606de0d64b7c0f67bb1cb8d87c',310490000,NULL,NULL,'906a38f4256f50312891119c99721537992438af85421e317574ce1810e2b909','5f934032dce4102cd1d72d3f887526e78baa4a78991bc43cf0a1ebefe08fdec7','6c381fa7b061ed017ac5f38ab43eb381c16636358c2a7f85c23b51dd8d3b1817');
INSERT INTO blocks VALUES(310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,NULL,NULL,'3114d8091cfcaa9944c6fab49d51950535c4ef269877d58c372ed80b2b472ec6','f065728a3544adc085fae976759c0d040a34ca0a8ddd39260b55f0262cd5baa8','963bc92eb4a961af661866bb742dfd32278beae019dddba75a3b638d606e2a85');
INSERT INTO blocks VALUES(310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,NULL,NULL,'98af18583618fdeed545347c013763d068e8294405d265911cc5e1bc420bc740','daf4d2c1a1ad5206abcf7744bdd06fae99c442fb2607a843dcabb5727d02916e','af586637be16170fc41033cddac17f4cce00919cf2ecf9ddd7ab908ecff5ace2');
INSERT INTO blocks VALUES(310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,NULL,NULL,'29119cd30a4733916fbfd0551506eaa16f7bb1bdfbdf8d17ac4e5bb20d1cb09c','7ec4cfa94544900c8e8732ad51be7cee6452aa1884ea940cd5c98862fb4aaba6','3f9f745c45cfb24a6db253f070162ef57b8351f3ccc034422f371e813d5e7f24');
INSERT INTO blocks VALUES(310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,NULL,NULL,'72d71bd72263699ea9f2b097ad141be5bc394f49d8b0b0a6b2ff6a87b0ee3919','9350c3ba33d0546d1194c5fa767ced28834b26246aedc56d89b1d48ec4f26014','4b8b6c7c248554f857cdc731d91c62528cdc6fcca4a5e52a608d8851a8350fc0');
INSERT INTO blocks VALUES(310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,NULL,NULL,'5a7e5a36882466373d576bb5f4ccd1bc72ecaf548b9589baa803a7275a7a24cd','09e9db121649cacd979fd18bbaa35e519361e727e7e072e2f2f86291160cdb29','2259494219eda0536e9effcd049cda9085771b39572f306a8fa23617ca80ebe3');
INSERT INTO blocks VALUES(310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,NULL,NULL,'7ac6121c624b634f44695172761830926afe76bb18c4cc9195773f3a26966941','9eda85cce745579122ba9c6e24b63cd83f2e5161031a34e6ee9bf08b80823cb4','59048372075aea2db712846e90a1e02ffc5c7cd72999c118194422c22df50426');
INSERT INTO blocks VALUES(310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,NULL,NULL,'28c6e92b2299b9cbbb5953f8b7ff3de0fe962d15642ba27e43faa64e1935e819','ff8136601b9e0138a999d1f0467af6e8535a2bcdd2b622af7be0178a083b9519','6591af2fc7cec99598a9f616b539d2cbc3e515993ddaaaa2a11b79ffe097ae46');
INSERT INTO blocks VALUES(310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,NULL,NULL,'5fe6cdb0828379bf240fad99c68bba34e1889bbc19605ce5c297b82352264414','b488f6f0e6c233f202ee17c0843236d464144e79c870af88bae56355ae9372b7','79506020a6c68ef1b4c723c00bc64649619b6be693b6818184b328822114ab22');
INSERT INTO blocks VALUES(310499,'1950e1a4d7fc820ed9603f6df6819c3c953c277c726340dec2a4253e261a1764',310499000,NULL,NULL,'b9fcbdafddd46fdda061f6e9f8744b426b6ca37e32b315df1098cbc7899ae9b9','032166892f568bb97f4f69ef5bdf49cc1b15cc9f8c7f6c1f3e1f9d54816ad7e5','bb92f04e57d4a9824e5ecca1ce92c2ed5809ebb77c36e80f2ff90c0c7f92f3c7');
INSERT INTO blocks VALUES(310500,'54aeaf47d5387964e2d51617bf3af50520a0449410e0d096cf8c2aa9dad5550b',310500000,NULL,NULL,'5ffefc7a2724be6bd697796bb82638ec913c5cbb73627153d1a13b48c7a6c02d','35f4a33840d002ab4e0e44f11c1749ae95b41376927fb346140508b32518edd1','68636b47dd25d30b4d8b3060b0d97d88b8b108ff9e883c7483798788530d36b6');
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
INSERT INTO broadcasts VALUES(18,'d14388b74b63d93e4477b1fe8426028bb8ab20656703e3ce8deeb23c2fe0b8af',310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000000,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(19,'f9e0527c85a9084d7eda91fc30a49993370d029efea031a8ccccdf846146a660',310018,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',0,NULL,NULL,NULL,1,'valid');
INSERT INTO broadcasts VALUES(103,'16462eac6c795cea6e5985ee063867d8c61ae24373df02048186d28118d25bae',310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000002,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(112,'510f6feb902159622d83f64eae590a4fec88989869a20caf5804c313aa5e0186',310111,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',1388000002,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(487,'3b95e07a2194174ac020de27e8b2b6ee24d5fc120f118df516ba28495657cf14',310486,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',1388000000,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(489,'870fb08b373705423f31ccd91fdbcabe135ad92d74e709a959dfa2e12f9a6638',310488,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',1388000002,1.0,0,'options 0',0,'valid');
INSERT INTO broadcasts VALUES(490,'685d7f99fa76a05201c3239a4e0d9060ea53307b171f6ad7d482a26c73e9c0d1',310489,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',0,NULL,NULL,NULL,1,'valid');
INSERT INTO broadcasts VALUES(491,'7c437705c315212315c85c0b8ba09d358679c91be20b54f30929c5a6052426af',310490,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',1388000004,1.0,0,'options 1',0,'valid');
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
INSERT INTO burns VALUES(104,'65d4048700fb8ae03f321be93c6669b8497f506a1f43920f96d994f43358c35b',310103,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',62000000,92999138821,'valid');
INSERT INTO burns VALUES(105,'95332a7e3e2b04f2c10e3027327bfc31b686947fb05381e28903e3ff569bd4ff',310104,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b',62000000,92999130460,'valid');
INSERT INTO burns VALUES(106,'e062d1ebf4cb71bd22d80c949b956f5286080838a7607ccf87945b2b3abfcafa',310105,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',62000000,92999122099,'valid');
INSERT INTO burns VALUES(107,'bbf0b9f6992755a3e371fb0c0b72f6828831e81c6f7ada6f95ba1104fb901ac3',310106,'mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK',10000,14999857,'valid');
INSERT INTO burns VALUES(109,'93c6d2499a0536c31c77a3db3fc9fc8456fbd0726c45b8f716af16f938727a73',310108,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',31000000,46499548508,'valid');
INSERT INTO burns VALUES(117,'27929c4fcad307a76ea7da34dd2691084f678a22ee43ce7f3842b78730ee08f9',310116,'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx',62000000,92999030129,'valid');
INSERT INTO burns VALUES(494,'c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a',310493,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',62000000,92995878046,'valid');
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
INSERT INTO credits VALUES(310001,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000000,'issuance','1fc2e5a57f584b2f2edd05676e75c33d03eed1d3098cc0550ea33474e3ec9db1');
INSERT INTO credits VALUES(310002,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','NODIVISIBLE',1000,'issuance','7b1bf5144346279271b1ff78664f118224fe27fd8679d6c1519345f9c6c54584');
INSERT INTO credits VALUES(310003,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','CALLABLE',1000,'issuance','c26f3a0c4e57e41919ff27aae95a9a9d4d65d34c6da6f1893884a17c8d407140');
INSERT INTO credits VALUES(310004,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','LOCKED',1000,'issuance','90b5734be98b0f2a0bd4b6a269c8db3368e2e387bb890ade239951d05423b4da');
INSERT INTO credits VALUES(310007,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','DIVISIBLE',100000000,'send','6e91ae23de2035e3e28c3322712212333592a1f666bcff9dd91aec45d5ea2753');
INSERT INTO credits VALUES(310008,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'send','4fd55abadfdbe77c3bda2431749cca934a29994a179620a62c1b57f28bd62a43');
INSERT INTO credits VALUES(310012,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',300000000,'send','698e97e507da8623cf38ab42701853443c8f7fe0d93b4674aabb42f9800ee9d6');
INSERT INTO credits VALUES(310013,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','DIVISIBLE',1000000000,'send','0cfeeb559ed794d067557df0376a6c213b48b174b80cdb2c3c6d365cf538e132');
INSERT INTO credits VALUES(310014,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','NODIVISIBLE',5,'send','1facb0072f16f6bdca64ea859c82b850f58f0ec7ff410d901679772a4727515a');
INSERT INTO credits VALUES(310015,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','NODIVISIBLE',10,'send','e3b6667b7baa515048a7fcf2be7818e3e7622371236b78e19b4b08e2d7e7818c');
INSERT INTO credits VALUES(310016,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','MAXI',9223372036854775807,'issuance','bd4e9cbbe69c2db893cd32182a2d315c89c45ba4e31aa5775d1fe42d841cea39');
INSERT INTO credits VALUES(310020,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','5c6562ddad0bc8a1faaded18813a65522cd273709acd190cf9d3271817eefc93');
INSERT INTO credits VALUES(310020,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',0,'filled','5c6562ddad0bc8a1faaded18813a65522cd273709acd190cf9d3271817eefc93');
INSERT INTO credits VALUES(310102,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',9,'bet settled','16462eac6c795cea6e5985ee063867d8c61ae24373df02048186d28118d25bae');
INSERT INTO credits VALUES(310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',9,'bet settled','16462eac6c795cea6e5985ee063867d8c61ae24373df02048186d28118d25bae');
INSERT INTO credits VALUES(310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'feed fee','16462eac6c795cea6e5985ee063867d8c61ae24373df02048186d28118d25bae');
INSERT INTO credits VALUES(310103,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','XCP',92999138821,'burn','65d4048700fb8ae03f321be93c6669b8497f506a1f43920f96d994f43358c35b');
INSERT INTO credits VALUES(310104,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','XCP',92999130460,'burn','95332a7e3e2b04f2c10e3027327bfc31b686947fb05381e28903e3ff569bd4ff');
INSERT INTO credits VALUES(310105,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',92999122099,'burn','e062d1ebf4cb71bd22d80c949b956f5286080838a7607ccf87945b2b3abfcafa');
INSERT INTO credits VALUES(310106,'mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK','XCP',14999857,'burn','bbf0b9f6992755a3e371fb0c0b72f6828831e81c6f7ada6f95ba1104fb901ac3');
INSERT INTO credits VALUES(310108,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',46499548508,'burn','93c6d2499a0536c31c77a3db3fc9fc8456fbd0726c45b8f716af16f938727a73');
INSERT INTO credits VALUES(310109,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','PAYTOSCRIPT',1000,'issuance','e8baf787b9e4636a3cad0ffeb62992ad7abb160dc6506af0546f566dc178de7e');
INSERT INTO credits VALUES(310110,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000,'send','f6a0f819e899b407cbfa07b4eff3d58902af3899abfbaa47d5f31d5b398e76e7');
INSERT INTO credits VALUES(310113,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','LOCKEDPREV',1000,'issuance','34bce6f409758b3d6fd13282a99b277ef1fdf44a1025d2901075cac0249dbc63');
INSERT INTO credits VALUES(310116,'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx','XCP',92999030129,'burn','27929c4fcad307a76ea7da34dd2691084f678a22ee43ce7f3842b78730ee08f9');
INSERT INTO credits VALUES(310481,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'send','b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5');
INSERT INTO credits VALUES(310482,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'send','c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34');
INSERT INTO credits VALUES(310493,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',92995878046,'burn','c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a');
INSERT INTO credits VALUES(310494,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','DIVIDEND',100,'issuance','321bed395482e034f2ce0a4dbf28d1f800592a658e26ea91ae9c5b0928204503');
INSERT INTO credits VALUES(310495,'mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','DIVIDEND',10,'send','02156b9a1f643fb48330396274a37620c8abbbe5eddb2f8b53dadd135f5d2e2e');
INSERT INTO credits VALUES(310496,'mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','XCP',92945878046,'send','a35ab1736565aceddbd1d71f92fc7f39d1361006aa9099f731e54e762964d5ba');
INSERT INTO credits VALUES(310497,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','PARENT',100000000,'issuance','076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f');
INSERT INTO credits VALUES(310498,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','A95428956661682277',100000000,'issuance','0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf');
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
INSERT INTO debits VALUES(310001,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','1fc2e5a57f584b2f2edd05676e75c33d03eed1d3098cc0550ea33474e3ec9db1');
INSERT INTO debits VALUES(310002,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','7b1bf5144346279271b1ff78664f118224fe27fd8679d6c1519345f9c6c54584');
INSERT INTO debits VALUES(310003,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','c26f3a0c4e57e41919ff27aae95a9a9d4d65d34c6da6f1893884a17c8d407140');
INSERT INTO debits VALUES(310004,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','90b5734be98b0f2a0bd4b6a269c8db3368e2e387bb890ade239951d05423b4da');
INSERT INTO debits VALUES(310005,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'issuance fee','344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc');
INSERT INTO debits VALUES(310006,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8');
INSERT INTO debits VALUES(310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000,'send','6e91ae23de2035e3e28c3322712212333592a1f666bcff9dd91aec45d5ea2753');
INSERT INTO debits VALUES(310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'send','4fd55abadfdbe77c3bda2431749cca934a29994a179620a62c1b57f28bd62a43');
INSERT INTO debits VALUES(310009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','21460d5c07284f9be9baf824927d0d4e4eb790e297f3162305841607b672349b');
INSERT INTO debits VALUES(310010,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','1899b2e6ec36ba4bc9d035e6640b0a62b08c3a147c77c89183a77d9ed9081b3a');
INSERT INTO debits VALUES(310012,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',300000000,'send','698e97e507da8623cf38ab42701853443c8f7fe0d93b4674aabb42f9800ee9d6');
INSERT INTO debits VALUES(310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',1000000000,'send','0cfeeb559ed794d067557df0376a6c213b48b174b80cdb2c3c6d365cf538e132');
INSERT INTO debits VALUES(310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','NODIVISIBLE',5,'send','1facb0072f16f6bdca64ea859c82b850f58f0ec7ff410d901679772a4727515a');
INSERT INTO debits VALUES(310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','NODIVISIBLE',10,'send','e3b6667b7baa515048a7fcf2be7818e3e7622371236b78e19b4b08e2d7e7818c');
INSERT INTO debits VALUES(310016,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','bd4e9cbbe69c2db893cd32182a2d315c89c45ba4e31aa5775d1fe42d841cea39');
INSERT INTO debits VALUES(310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',9,'bet','2a2169991597036b6dad687ea1feffd55465a204466f40c35cbba811cb3109b1');
INSERT INTO debits VALUES(310020,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',9,'bet','5c6562ddad0bc8a1faaded18813a65522cd273709acd190cf9d3271817eefc93');
INSERT INTO debits VALUES(310101,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',10,'bet','db4ea092bea6036e3d1e5f6ec863db9b900252b4f4d6d9faa6165323f433c51e');
INSERT INTO debits VALUES(310107,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','XCP',100,'open dispenser','9834219d2825b4d85ca7ee0d75a5372d9d42ce75eb9144951fca1af5a25915ec');
INSERT INTO debits VALUES(310109,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',50000000,'issuance fee','e8baf787b9e4636a3cad0ffeb62992ad7abb160dc6506af0546f566dc178de7e');
INSERT INTO debits VALUES(310110,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000,'send','f6a0f819e899b407cbfa07b4eff3d58902af3899abfbaa47d5f31d5b398e76e7');
INSERT INTO debits VALUES(310112,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',10,'bet','d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048');
INSERT INTO debits VALUES(310113,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',50000000,'issuance fee','34bce6f409758b3d6fd13282a99b277ef1fdf44a1025d2901075cac0249dbc63');
INSERT INTO debits VALUES(310114,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',0,'issuance fee','025b810fce7735c5869b90846007e5f604f60c1beda4c1695f1c7fbec3d44bc2');
INSERT INTO debits VALUES(310115,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',0,'issuance fee','4ab1a24283c1dbfc710be7b215d64e8a4510ee97af019e210049c25773b50beb');
INSERT INTO debits VALUES(310481,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'send','b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5');
INSERT INTO debits VALUES(310482,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'send','c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34');
INSERT INTO debits VALUES(310487,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','XCP',9,'bet','41e821ae1c6b553d0fa5d5a807b2e7e9ffaec5d62706d9d2a59c6e65a3ed9cef');
INSERT INTO debits VALUES(310491,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','74db175c4669a3d3a59e3fcddce9e97fcd7d12c35b58ef31845a1b20a1739498');
INSERT INTO debits VALUES(310494,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',50000000,'issuance fee','321bed395482e034f2ce0a4dbf28d1f800592a658e26ea91ae9c5b0928204503');
INSERT INTO debits VALUES(310495,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','DIVIDEND',10,'send','02156b9a1f643fb48330396274a37620c8abbbe5eddb2f8b53dadd135f5d2e2e');
INSERT INTO debits VALUES(310496,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',92945878046,'send','a35ab1736565aceddbd1d71f92fc7f39d1361006aa9099f731e54e762964d5ba');
INSERT INTO debits VALUES(310497,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f');
INSERT INTO debits VALUES(310498,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',25000000,'issuance fee','0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf');
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
INSERT INTO dispensers VALUES(108,'9834219d2825b4d85ca7ee0d75a5372d9d42ce75eb9144951fca1af5a25915ec',310107,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','XCP',100,100,100,0,100,NULL,NULL,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b');
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
INSERT INTO issuances VALUES(2,'1fc2e5a57f584b2f2edd05676e75c33d03eed1d3098cc0550ea33474e3ec9db1',0,310001,'DIVISIBLE',100000000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Divisible asset',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(3,'7b1bf5144346279271b1ff78664f118224fe27fd8679d6c1519345f9c6c54584',0,310002,'NODIVISIBLE',1000,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'No divisible asset',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(4,'c26f3a0c4e57e41919ff27aae95a9a9d4d65d34c6da6f1893884a17c8d407140',0,310003,'CALLABLE',1000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Callable asset',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(5,'90b5734be98b0f2a0bd4b6a269c8db3368e2e387bb890ade239951d05423b4da',0,310004,'LOCKED',1000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Locked asset',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(6,'344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc',0,310005,'LOCKED',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Locked asset',0,1,'valid',NULL,0);
INSERT INTO issuances VALUES(17,'bd4e9cbbe69c2db893cd32182a2d315c89c45ba4e31aa5775d1fe42d841cea39',0,310016,'MAXI',9223372036854775807,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Maximum quantity',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(110,'e8baf787b9e4636a3cad0ffeb62992ad7abb160dc6506af0546f566dc178de7e',0,310109,'PAYTOSCRIPT',1000,0,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',0,0,0,0.0,'PSH issued asset',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(114,'34bce6f409758b3d6fd13282a99b277ef1fdf44a1025d2901075cac0249dbc63',0,310113,'LOCKEDPREV',1000,1,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',0,0,0,0.0,'Locked asset',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(115,'025b810fce7735c5869b90846007e5f604f60c1beda4c1695f1c7fbec3d44bc2',0,310114,'LOCKEDPREV',0,1,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',0,0,0,0.0,'Locked asset',0,1,'valid',NULL,0);
INSERT INTO issuances VALUES(116,'4ab1a24283c1dbfc710be7b215d64e8a4510ee97af019e210049c25773b50beb',0,310115,'LOCKEDPREV',0,1,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',0,0,0,0.0,'changed',0,0,'valid',NULL,0);
INSERT INTO issuances VALUES(495,'321bed395482e034f2ce0a4dbf28d1f800592a658e26ea91ae9c5b0928204503',0,310494,'DIVIDEND',100,1,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',0,0,0,0.0,'',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(498,'076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f',0,310497,'PARENT',100000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Parent asset',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(499,'0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf',0,310498,'A95428956661682277',100000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Child of parent',25000000,0,'valid','PARENT.already.issued',0);
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
INSERT INTO messages VALUES(6,310001,'insert','issuances','[''asset'', ''asset_longname'', ''block_index'', ''call_date'', ''call_price'', ''callable'', ''description'', ''divisible'', ''fee_paid'', ''issuer'', ''locked'', ''quantity'', ''reset'', ''source'', ''status'', ''transfer'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(7,310001,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(8,310002,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(9,310002,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(10,310002,'insert','issuances','[''asset'', ''asset_longname'', ''block_index'', ''call_date'', ''call_price'', ''callable'', ''description'', ''divisible'', ''fee_paid'', ''issuer'', ''locked'', ''quantity'', ''reset'', ''source'', ''status'', ''transfer'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(11,310002,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(12,310003,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(13,310003,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(14,310003,'insert','issuances','[''asset'', ''asset_longname'', ''block_index'', ''call_date'', ''call_price'', ''callable'', ''description'', ''divisible'', ''fee_paid'', ''issuer'', ''locked'', ''quantity'', ''reset'', ''source'', ''status'', ''transfer'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(15,310003,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(16,310004,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(17,310004,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(18,310004,'insert','issuances','[''asset'', ''asset_longname'', ''block_index'', ''call_date'', ''call_price'', ''callable'', ''description'', ''divisible'', ''fee_paid'', ''issuer'', ''locked'', ''quantity'', ''reset'', ''source'', ''status'', ''transfer'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(19,310004,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(20,310005,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(21,310005,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(22,310005,'insert','issuances','[''asset'', ''asset_longname'', ''block_index'', ''call_date'', ''call_price'', ''callable'', ''description'', ''divisible'', ''fee_paid'', ''issuer'', ''locked'', ''quantity'', ''reset'', ''source'', ''status'', ''transfer'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(23,310006,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(24,310006,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(25,310006,'insert','orders','[''block_index'', ''expiration'', ''expire_index'', ''fee_provided'', ''fee_provided_remaining'', ''fee_required'', ''fee_required_remaining'', ''get_asset'', ''get_quantity'', ''get_remaining'', ''give_asset'', ''give_quantity'', ''give_remaining'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(26,310007,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(27,310007,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(28,310007,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(29,310007,'insert','sends','[''asset'', ''block_index'', ''destination'', ''quantity'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(30,310008,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(31,310008,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(32,310008,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(33,310008,'insert','sends','[''asset'', ''block_index'', ''destination'', ''quantity'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(34,310009,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(35,310009,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(36,310009,'insert','orders','[''block_index'', ''expiration'', ''expire_index'', ''fee_provided'', ''fee_provided_remaining'', ''fee_required'', ''fee_required_remaining'', ''get_asset'', ''get_quantity'', ''get_remaining'', ''give_asset'', ''give_quantity'', ''give_remaining'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(37,310010,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(38,310010,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(39,310010,'insert','orders','[''block_index'', ''expiration'', ''expire_index'', ''fee_provided'', ''fee_provided_remaining'', ''fee_required'', ''fee_required_remaining'', ''get_asset'', ''get_quantity'', ''get_remaining'', ''give_asset'', ''give_quantity'', ''give_remaining'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(40,310011,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(41,310011,'insert','orders','[''block_index'', ''expiration'', ''expire_index'', ''fee_provided'', ''fee_provided_remaining'', ''fee_required'', ''fee_required_remaining'', ''get_asset'', ''get_quantity'', ''get_remaining'', ''give_asset'', ''give_quantity'', ''give_remaining'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(42,310012,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(43,310012,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(44,310012,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(45,310012,'insert','sends','[''asset'', ''block_index'', ''destination'', ''quantity'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(46,310013,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(47,310013,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(48,310013,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(49,310013,'insert','sends','[''asset'', ''block_index'', ''destination'', ''quantity'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(50,310014,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(51,310014,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(52,310014,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(53,310014,'insert','sends','[''asset'', ''block_index'', ''destination'', ''quantity'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(54,310015,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(55,310015,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(56,310015,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(57,310015,'insert','sends','[''asset'', ''block_index'', ''destination'', ''quantity'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(58,310016,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(59,310016,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(60,310016,'insert','issuances','[''asset'', ''asset_longname'', ''block_index'', ''call_date'', ''call_price'', ''callable'', ''description'', ''divisible'', ''fee_paid'', ''issuer'', ''locked'', ''quantity'', ''reset'', ''source'', ''status'', ''transfer'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(61,310016,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(62,310017,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(63,310017,'insert','broadcasts','[''block_index'', ''fee_fraction_int'', ''locked'', ''source'', ''status'', ''text'', ''timestamp'', ''tx_hash'', ''tx_index'', ''value'']',0);
INSERT INTO messages VALUES(64,310018,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(65,310018,'insert','broadcasts','[''block_index'', ''fee_fraction_int'', ''locked'', ''source'', ''status'', ''text'', ''timestamp'', ''tx_hash'', ''tx_index'', ''value'']',0);
INSERT INTO messages VALUES(66,310019,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(67,310019,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(68,310019,'insert','bets','[''bet_type'', ''block_index'', ''counterwager_quantity'', ''counterwager_remaining'', ''deadline'', ''expiration'', ''expire_index'', ''fee_fraction_int'', ''feed_address'', ''leverage'', ''source'', ''status'', ''target_value'', ''tx_hash'', ''tx_index'', ''wager_quantity'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(69,310020,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(70,310020,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(71,310020,'insert','bets','[''bet_type'', ''block_index'', ''counterwager_quantity'', ''counterwager_remaining'', ''deadline'', ''expiration'', ''expire_index'', ''fee_fraction_int'', ''feed_address'', ''leverage'', ''source'', ''status'', ''target_value'', ''tx_hash'', ''tx_index'', ''wager_quantity'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(72,310020,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(73,310020,'update','bets','[''counterwager_remaining'', ''status'', ''tx_hash'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(74,310020,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(75,310020,'update','bets','[''counterwager_remaining'', ''status'', ''tx_hash'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(76,310020,'insert','bet_matches','[''backward_quantity'', ''block_index'', ''deadline'', ''fee_fraction_int'', ''feed_address'', ''forward_quantity'', ''id'', ''initial_value'', ''leverage'', ''match_expire_index'', ''status'', ''target_value'', ''tx0_address'', ''tx0_bet_type'', ''tx0_block_index'', ''tx0_expiration'', ''tx0_hash'', ''tx0_index'', ''tx1_address'', ''tx1_bet_type'', ''tx1_block_index'', ''tx1_expiration'', ''tx1_hash'', ''tx1_index'']',0);
INSERT INTO messages VALUES(77,310021,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(78,310022,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(79,310023,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(80,310024,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(81,310025,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(82,310026,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(83,310027,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(84,310028,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(85,310029,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(86,310030,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(87,310031,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(88,310032,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(89,310033,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(90,310034,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(91,310035,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(92,310036,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(93,310037,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(94,310038,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(95,310039,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(96,310040,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(97,310041,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(98,310042,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(99,310043,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(100,310044,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(101,310045,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(102,310046,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(103,310047,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(104,310048,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(105,310049,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(106,310050,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(107,310051,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(108,310052,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(109,310053,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(110,310054,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(111,310055,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(112,310056,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(113,310057,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(114,310058,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(115,310059,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(116,310060,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(117,310061,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(118,310062,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(119,310063,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(120,310064,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(121,310065,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(122,310066,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(123,310067,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(124,310068,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(125,310069,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(126,310070,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(127,310071,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(128,310072,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(129,310073,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(130,310074,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(131,310075,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(132,310076,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(133,310077,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(134,310078,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(135,310079,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(136,310080,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(137,310081,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(138,310082,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(139,310083,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(140,310084,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(141,310085,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(142,310086,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(143,310087,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(144,310088,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(145,310089,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(146,310090,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(147,310091,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(148,310092,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(149,310093,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(150,310094,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(151,310095,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(152,310096,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(153,310097,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(154,310098,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(155,310099,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(156,310100,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(157,310101,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(158,310101,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(159,310101,'insert','bets','[''bet_type'', ''block_index'', ''counterwager_quantity'', ''counterwager_remaining'', ''deadline'', ''expiration'', ''expire_index'', ''fee_fraction_int'', ''feed_address'', ''leverage'', ''source'', ''status'', ''target_value'', ''tx_hash'', ''tx_index'', ''wager_quantity'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(160,310102,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(161,310102,'insert','broadcasts','[''block_index'', ''fee_fraction_int'', ''locked'', ''source'', ''status'', ''text'', ''timestamp'', ''tx_hash'', ''tx_index'', ''value'']',0);
INSERT INTO messages VALUES(162,310102,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(163,310102,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(164,310102,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(165,310102,'insert','bet_match_resolutions','[''bear_credit'', ''bet_match_id'', ''bet_match_type_id'', ''block_index'', ''bull_credit'', ''escrow_less_fee'', ''fee'', ''settled'', ''winner'']',0);
INSERT INTO messages VALUES(166,310102,'update','bet_matches','[''bet_match_id'', ''status'']',0);
INSERT INTO messages VALUES(167,310103,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(168,310103,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(169,310103,'insert','burns','[''block_index'', ''burned'', ''earned'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(170,310104,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(171,310104,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(172,310104,'insert','burns','[''block_index'', ''burned'', ''earned'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(173,310105,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(174,310105,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(175,310105,'insert','burns','[''block_index'', ''burned'', ''earned'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(176,310106,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(177,310106,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(178,310106,'insert','burns','[''block_index'', ''burned'', ''earned'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(179,310107,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(180,310107,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(181,310107,'insert','dispensers','[''asset'', ''block_index'', ''escrow_quantity'', ''give_quantity'', ''give_remaining'', ''oracle_address'', ''origin'', ''satoshirate'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(182,310108,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(183,310108,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(184,310108,'insert','burns','[''block_index'', ''burned'', ''earned'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(185,310109,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(186,310109,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(187,310109,'insert','issuances','[''asset'', ''asset_longname'', ''block_index'', ''call_date'', ''call_price'', ''callable'', ''description'', ''divisible'', ''fee_paid'', ''issuer'', ''locked'', ''quantity'', ''reset'', ''source'', ''status'', ''transfer'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(188,310109,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(189,310110,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(190,310110,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(191,310110,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(192,310110,'insert','sends','[''asset'', ''block_index'', ''destination'', ''quantity'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(193,310111,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(194,310111,'insert','broadcasts','[''block_index'', ''fee_fraction_int'', ''locked'', ''source'', ''status'', ''text'', ''timestamp'', ''tx_hash'', ''tx_index'', ''value'']',0);
INSERT INTO messages VALUES(195,310112,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(196,310112,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(197,310112,'insert','bets','[''bet_type'', ''block_index'', ''counterwager_quantity'', ''counterwager_remaining'', ''deadline'', ''expiration'', ''expire_index'', ''fee_fraction_int'', ''feed_address'', ''leverage'', ''source'', ''status'', ''target_value'', ''tx_hash'', ''tx_index'', ''wager_quantity'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(198,310113,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(199,310113,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(200,310113,'insert','issuances','[''asset'', ''asset_longname'', ''block_index'', ''call_date'', ''call_price'', ''callable'', ''description'', ''divisible'', ''fee_paid'', ''issuer'', ''locked'', ''quantity'', ''reset'', ''source'', ''status'', ''transfer'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(201,310113,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(202,310114,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(203,310114,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(204,310114,'insert','issuances','[''asset'', ''asset_longname'', ''block_index'', ''call_date'', ''call_price'', ''callable'', ''description'', ''divisible'', ''fee_paid'', ''issuer'', ''locked'', ''quantity'', ''reset'', ''source'', ''status'', ''transfer'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(205,310115,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(206,310115,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(207,310115,'insert','issuances','[''asset'', ''asset_longname'', ''block_index'', ''call_date'', ''call_price'', ''callable'', ''description'', ''divisible'', ''fee_paid'', ''issuer'', ''locked'', ''quantity'', ''reset'', ''source'', ''status'', ''transfer'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(208,310116,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(209,310116,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(210,310116,'insert','burns','[''block_index'', ''burned'', ''earned'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(211,310117,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(212,310118,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(213,310119,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(214,310120,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(215,310121,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(216,310122,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(217,310123,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(218,310124,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(219,310125,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(220,310126,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(221,310127,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(222,310128,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(223,310129,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(224,310130,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(225,310131,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(226,310132,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(227,310133,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(228,310134,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(229,310135,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(230,310136,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(231,310137,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(232,310138,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(233,310139,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(234,310140,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(235,310141,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(236,310142,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(237,310143,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(238,310144,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(239,310145,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(240,310146,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(241,310147,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(242,310148,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(243,310149,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(244,310150,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(245,310151,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(246,310152,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(247,310153,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(248,310154,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(249,310155,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(250,310156,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(251,310157,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(252,310158,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(253,310159,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(254,310160,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(255,310161,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(256,310162,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(257,310163,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(258,310164,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(259,310165,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(260,310166,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(261,310167,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(262,310168,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(263,310169,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(264,310170,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(265,310171,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(266,310172,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(267,310173,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(268,310174,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(269,310175,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(270,310176,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(271,310177,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(272,310178,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(273,310179,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(274,310180,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(275,310181,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(276,310182,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(277,310183,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(278,310184,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(279,310185,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(280,310186,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(281,310187,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(282,310188,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(283,310189,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(284,310190,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(285,310191,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(286,310192,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(287,310193,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(288,310194,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(289,310195,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(290,310196,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(291,310197,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(292,310198,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(293,310199,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(294,310200,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(295,310201,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(296,310202,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(297,310203,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(298,310204,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(299,310205,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(300,310206,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(301,310207,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(302,310208,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(303,310209,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(304,310210,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(305,310211,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(306,310212,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(307,310213,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(308,310214,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(309,310215,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(310,310216,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(311,310217,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(312,310218,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(313,310219,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(314,310220,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(315,310221,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(316,310222,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(317,310223,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(318,310224,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(319,310225,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(320,310226,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(321,310227,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(322,310228,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(323,310229,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(324,310230,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(325,310231,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(326,310232,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(327,310233,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(328,310234,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(329,310235,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(330,310236,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(331,310237,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(332,310238,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(333,310239,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(334,310240,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(335,310241,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(336,310242,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(337,310243,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(338,310244,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(339,310245,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(340,310246,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(341,310247,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(342,310248,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(343,310249,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(344,310250,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(345,310251,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(346,310252,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(347,310253,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(348,310254,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(349,310255,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(350,310256,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(351,310257,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(352,310258,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(353,310259,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(354,310260,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(355,310261,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(356,310262,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(357,310263,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(358,310264,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(359,310265,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(360,310266,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(361,310267,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(362,310268,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(363,310269,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(364,310270,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(365,310271,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(366,310272,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(367,310273,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(368,310274,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(369,310275,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(370,310276,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(371,310277,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(372,310278,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(373,310279,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(374,310280,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(375,310281,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(376,310282,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(377,310283,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(378,310284,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(379,310285,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(380,310286,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(381,310287,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(382,310288,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(383,310289,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(384,310290,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(385,310291,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(386,310292,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(387,310293,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(388,310294,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(389,310295,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(390,310296,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(391,310297,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(392,310298,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(393,310299,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(394,310300,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(395,310301,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(396,310302,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(397,310303,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(398,310304,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(399,310305,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(400,310306,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(401,310307,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(402,310308,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(403,310309,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(404,310310,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(405,310311,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(406,310312,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(407,310313,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(408,310314,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(409,310315,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(410,310316,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(411,310317,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(412,310318,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(413,310319,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(414,310320,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(415,310321,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(416,310322,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(417,310323,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(418,310324,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(419,310325,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(420,310326,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(421,310327,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(422,310328,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(423,310329,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(424,310330,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(425,310331,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(426,310332,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(427,310333,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(428,310334,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(429,310335,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(430,310336,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(431,310337,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(432,310338,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(433,310339,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(434,310340,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(435,310341,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(436,310342,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(437,310343,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(438,310344,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(439,310345,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(440,310346,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(441,310347,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(442,310348,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(443,310349,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(444,310350,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(445,310351,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(446,310352,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(447,310353,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(448,310354,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(449,310355,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(450,310356,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(451,310357,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(452,310358,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(453,310359,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(454,310360,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(455,310361,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(456,310362,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(457,310363,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(458,310364,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(459,310365,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(460,310366,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(461,310367,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(462,310368,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(463,310369,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(464,310370,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(465,310371,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(466,310372,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(467,310373,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(468,310374,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(469,310375,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(470,310376,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(471,310377,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(472,310378,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(473,310379,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(474,310380,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(475,310381,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(476,310382,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(477,310383,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(478,310384,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(479,310385,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(480,310386,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(481,310387,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(482,310388,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(483,310389,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(484,310390,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(485,310391,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(486,310392,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(487,310393,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(488,310394,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(489,310395,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(490,310396,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(491,310397,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(492,310398,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(493,310399,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(494,310400,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(495,310401,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(496,310402,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(497,310403,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(498,310404,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(499,310405,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(500,310406,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(501,310407,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(502,310408,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(503,310409,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(504,310410,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(505,310411,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(506,310412,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(507,310413,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(508,310414,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(509,310415,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(510,310416,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(511,310417,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(512,310418,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(513,310419,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(514,310420,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(515,310421,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(516,310422,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(517,310423,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(518,310424,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(519,310425,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(520,310426,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(521,310427,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(522,310428,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(523,310429,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(524,310430,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(525,310431,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(526,310432,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(527,310433,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(528,310434,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(529,310435,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(530,310436,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(531,310437,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(532,310438,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(533,310439,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(534,310440,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(535,310441,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(536,310442,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(537,310443,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(538,310444,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(539,310445,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(540,310446,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(541,310447,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(542,310448,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(543,310449,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(544,310450,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(545,310451,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(546,310452,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(547,310453,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(548,310454,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(549,310455,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(550,310456,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(551,310457,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(552,310458,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(553,310459,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(554,310460,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(555,310461,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(556,310462,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(557,310463,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(558,310464,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(559,310465,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(560,310466,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(561,310467,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(562,310468,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(563,310469,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(564,310470,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(565,310471,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(566,310472,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(567,310473,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(568,310474,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(569,310475,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(570,310476,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(571,310477,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(572,310478,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(573,310479,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(574,310480,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(575,310481,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(576,310481,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(577,310481,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(578,310481,'insert','sends','[''asset'', ''block_index'', ''destination'', ''memo'', ''quantity'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(579,310482,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(580,310482,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(581,310482,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(582,310482,'insert','sends','[''asset'', ''block_index'', ''destination'', ''memo'', ''quantity'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(583,310483,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(584,310484,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(585,310485,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(586,310486,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(587,310486,'insert','broadcasts','[''block_index'', ''fee_fraction_int'', ''locked'', ''source'', ''status'', ''text'', ''timestamp'', ''tx_hash'', ''tx_index'', ''value'']',0);
INSERT INTO messages VALUES(588,310487,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(589,310487,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(590,310487,'insert','bets','[''bet_type'', ''block_index'', ''counterwager_quantity'', ''counterwager_remaining'', ''deadline'', ''expiration'', ''expire_index'', ''fee_fraction_int'', ''feed_address'', ''leverage'', ''source'', ''status'', ''target_value'', ''tx_hash'', ''tx_index'', ''wager_quantity'', ''wager_remaining'']',0);
INSERT INTO messages VALUES(591,310488,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(592,310488,'insert','broadcasts','[''block_index'', ''fee_fraction_int'', ''locked'', ''source'', ''status'', ''text'', ''timestamp'', ''tx_hash'', ''tx_index'', ''value'']',0);
INSERT INTO messages VALUES(593,310488,'insert','replace','[''address'', ''block_index'', ''options'']',0);
INSERT INTO messages VALUES(594,310489,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(595,310489,'insert','broadcasts','[''block_index'', ''fee_fraction_int'', ''locked'', ''source'', ''status'', ''text'', ''timestamp'', ''tx_hash'', ''tx_index'', ''value'']',0);
INSERT INTO messages VALUES(596,310490,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(597,310490,'insert','broadcasts','[''block_index'', ''fee_fraction_int'', ''locked'', ''source'', ''status'', ''text'', ''timestamp'', ''tx_hash'', ''tx_index'', ''value'']',0);
INSERT INTO messages VALUES(598,310490,'insert','replace','[''address'', ''block_index'', ''options'']',0);
INSERT INTO messages VALUES(599,310491,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(600,310491,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(601,310491,'insert','orders','[''block_index'', ''expiration'', ''expire_index'', ''fee_provided'', ''fee_provided_remaining'', ''fee_required'', ''fee_required_remaining'', ''get_asset'', ''get_quantity'', ''get_remaining'', ''give_asset'', ''give_quantity'', ''give_remaining'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(602,310492,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(603,310492,'insert','orders','[''block_index'', ''expiration'', ''expire_index'', ''fee_provided'', ''fee_provided_remaining'', ''fee_required'', ''fee_required_remaining'', ''get_asset'', ''get_quantity'', ''get_remaining'', ''give_asset'', ''give_quantity'', ''give_remaining'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(604,310492,'update','orders','[''fee_provided_remaining'', ''fee_required_remaining'', ''get_remaining'', ''give_remaining'', ''status'', ''tx_hash'']',0);
INSERT INTO messages VALUES(605,310492,'update','orders','[''fee_provided_remaining'', ''fee_required_remaining'', ''get_remaining'', ''give_remaining'', ''status'', ''tx_hash'']',0);
INSERT INTO messages VALUES(606,310492,'insert','order_matches','[''backward_asset'', ''backward_quantity'', ''block_index'', ''fee_paid'', ''forward_asset'', ''forward_quantity'', ''id'', ''match_expire_index'', ''status'', ''tx0_address'', ''tx0_block_index'', ''tx0_expiration'', ''tx0_hash'', ''tx0_index'', ''tx1_address'', ''tx1_block_index'', ''tx1_expiration'', ''tx1_hash'', ''tx1_index'']',0);
INSERT INTO messages VALUES(607,310493,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(608,310493,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(609,310493,'insert','burns','[''block_index'', ''burned'', ''earned'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(610,310494,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(611,310494,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(612,310494,'insert','issuances','[''asset'', ''asset_longname'', ''block_index'', ''call_date'', ''call_price'', ''callable'', ''description'', ''divisible'', ''fee_paid'', ''issuer'', ''locked'', ''quantity'', ''reset'', ''source'', ''status'', ''transfer'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(613,310494,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(614,310495,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(615,310495,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(616,310495,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(617,310495,'insert','sends','[''asset'', ''block_index'', ''destination'', ''quantity'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(618,310496,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(619,310496,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(620,310496,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(621,310496,'insert','sends','[''asset'', ''block_index'', ''destination'', ''quantity'', ''source'', ''status'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(622,310497,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(623,310497,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(624,310497,'insert','issuances','[''asset'', ''asset_longname'', ''block_index'', ''call_date'', ''call_price'', ''callable'', ''description'', ''divisible'', ''fee_paid'', ''issuer'', ''locked'', ''quantity'', ''reset'', ''source'', ''status'', ''transfer'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(625,310497,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(626,310498,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(627,310498,'insert','debits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(628,310498,'insert','issuances','[''asset'', ''asset_longname'', ''block_index'', ''call_date'', ''call_price'', ''callable'', ''description'', ''divisible'', ''fee_paid'', ''issuer'', ''locked'', ''quantity'', ''reset'', ''source'', ''status'', ''transfer'', ''tx_hash'', ''tx_index'']',0);
INSERT INTO messages VALUES(629,310498,'insert','credits','[''action'', ''address'', ''asset'', ''block_index'', ''event'', ''quantity'']',0);
INSERT INTO messages VALUES(630,310499,'insert','replace','[''block_index'']',0);
INSERT INTO messages VALUES(631,310500,'insert','replace','[''block_index'']',0);
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
INSERT INTO order_matches VALUES('74db175c4669a3d3a59e3fcddce9e97fcd7d12c35b58ef31845a1b20a1739498_1b294dd8592e76899b1c106782e4c96e63114abd8e3fa09ab6d2d52496b5bf81',492,'74db175c4669a3d3a59e3fcddce9e97fcd7d12c35b58ef31845a1b20a1739498','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',493,'1b294dd8592e76899b1c106782e4c96e63114abd8e3fa09ab6d2d52496b5bf81','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'BTC',800000,310491,310492,310492,2000,2000,310512,7200,'pending');
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
INSERT INTO orders VALUES(7,'4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8',310006,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,100000000,'DIVISIBLE',100000000,100000000,2000,312006,0,0,6800,6800,'open');
INSERT INTO orders VALUES(10,'21460d5c07284f9be9baf824927d0d4e4eb790e297f3162305841607b672349b',310009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,100000000,'DIVISIBLE',100000000,100000000,2000,312009,0,0,6800,6800,'open');
INSERT INTO orders VALUES(11,'1899b2e6ec36ba4bc9d035e6640b0a62b08c3a147c77c89183a77d9ed9081b3a',310010,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,100000000,'BTC',1000000,1000000,2000,312010,900000,900000,6800,6800,'open');
INSERT INTO orders VALUES(12,'a1768d7db2db3b9732b26df8c04db4b9a8535a1e5cf684a680e81e7c06f394b6',310011,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BTC',666667,666667,'XCP',100000000,100000000,2000,312011,0,0,1000000,1000000,'open');
INSERT INTO orders VALUES(492,'74db175c4669a3d3a59e3fcddce9e97fcd7d12c35b58ef31845a1b20a1739498',310491,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,0,'BTC',800000,0,2000,312491,900000,892800,6800,6800,'open');
INSERT INTO orders VALUES(493,'1b294dd8592e76899b1c106782e4c96e63114abd8e3fa09ab6d2d52496b5bf81',310492,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BTC',800000,0,'XCP',100000000,0,2000,312492,0,0,1000000,992800,'open');
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
INSERT INTO sends VALUES(8,'6e91ae23de2035e3e28c3322712212333592a1f666bcff9dd91aec45d5ea2753',310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','DIVISIBLE',100000000,'valid',0,NULL);
INSERT INTO sends VALUES(9,'4fd55abadfdbe77c3bda2431749cca934a29994a179620a62c1b57f28bd62a43',310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'valid',0,NULL);
INSERT INTO sends VALUES(13,'698e97e507da8623cf38ab42701853443c8f7fe0d93b4674aabb42f9800ee9d6',310012,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',300000000,'valid',0,NULL);
INSERT INTO sends VALUES(14,'0cfeeb559ed794d067557df0376a6c213b48b174b80cdb2c3c6d365cf538e132',310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','DIVISIBLE',1000000000,'valid',0,NULL);
INSERT INTO sends VALUES(15,'1facb0072f16f6bdca64ea859c82b850f58f0ec7ff410d901679772a4727515a',310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','NODIVISIBLE',5,'valid',0,NULL);
INSERT INTO sends VALUES(16,'e3b6667b7baa515048a7fcf2be7818e3e7622371236b78e19b4b08e2d7e7818c',310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','NODIVISIBLE',10,'valid',0,NULL);
INSERT INTO sends VALUES(111,'f6a0f819e899b407cbfa07b4eff3d58902af3899abfbaa47d5f31d5b398e76e7',310110,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000,'valid',0,NULL);
INSERT INTO sends VALUES(482,'b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5',310481,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'valid',0,X'68656C6C6F');
INSERT INTO sends VALUES(483,'c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34',310482,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'valid',0,X'FADE0001');
INSERT INTO sends VALUES(496,'02156b9a1f643fb48330396274a37620c8abbbe5eddb2f8b53dadd135f5d2e2e',310495,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','DIVIDEND',10,'valid',0,NULL);
INSERT INTO sends VALUES(497,'a35ab1736565aceddbd1d71f92fc7f39d1361006aa9099f731e54e762964d5ba',310496,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','XCP',92945878046,'valid',0,NULL);
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
INSERT INTO transactions VALUES(1,'6dc5b0a33d4d4297e0f5cc2d23ae307951d32aab2d86b7fa147b385219f3a597',310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
INSERT INTO transactions VALUES(2,'1fc2e5a57f584b2f2edd05676e75c33d03eed1d3098cc0550ea33474e3ec9db1',310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'00000014000000A25BE34B66000000174876E800010000000000000000000F446976697369626C65206173736574',1);
INSERT INTO transactions VALUES(3,'7b1bf5144346279271b1ff78664f118224fe27fd8679d6c1519345f9c6c54584',310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'000000140006CAD8DC7F0B6600000000000003E800000000000000000000124E6F20646976697369626C65206173736574',1);
INSERT INTO transactions VALUES(4,'c26f3a0c4e57e41919ff27aae95a9a9d4d65d34c6da6f1893884a17c8d407140',310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001400000003C58E5C5600000000000003E8010000000000000000000E43616C6C61626C65206173736574',1);
INSERT INTO transactions VALUES(5,'90b5734be98b0f2a0bd4b6a269c8db3368e2e387bb890ade239951d05423b4da',310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001400000000082C82E300000000000003E8010000000000000000000C4C6F636B6564206173736574',1);
INSERT INTO transactions VALUES(6,'344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc',310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001400000000082C82E3000000000000000001000000000000000000044C4F434B',1);
INSERT INTO transactions VALUES(7,'4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8',310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000000010000000005F5E100000000A25BE34B660000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(8,'6e91ae23de2035e3e28c3322712212333592a1f666bcff9dd91aec45d5ea2753',310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,7650,X'00000000000000A25BE34B660000000005F5E100',1);
INSERT INTO transactions VALUES(9,'4fd55abadfdbe77c3bda2431749cca934a29994a179620a62c1b57f28bd62a43',310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,7650,X'0000000000000000000000010000000005F5E100',1);
INSERT INTO transactions VALUES(10,'21460d5c07284f9be9baf824927d0d4e4eb790e297f3162305841607b672349b',310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000000010000000005F5E100000000A25BE34B660000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(11,'1899b2e6ec36ba4bc9d035e6640b0a62b08c3a147c77c89183a77d9ed9081b3a',310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000000010000000005F5E100000000000000000000000000000F424007D000000000000DBBA0',1);
INSERT INTO transactions VALUES(12,'a1768d7db2db3b9732b26df8c04db4b9a8535a1e5cf684a680e81e7c06f394b6',310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,1000000,X'0000000A000000000000000000000000000A2C2B00000000000000010000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(13,'698e97e507da8623cf38ab42701853443c8f7fe0d93b4674aabb42f9800ee9d6',310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1000,7650,X'0000000000000000000000010000000011E1A300',1);
INSERT INTO transactions VALUES(14,'0cfeeb559ed794d067557df0376a6c213b48b174b80cdb2c3c6d365cf538e132',310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1000,7650,X'00000000000000A25BE34B66000000003B9ACA00',1);
INSERT INTO transactions VALUES(15,'1facb0072f16f6bdca64ea859c82b850f58f0ec7ff410d901679772a4727515a',310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,7650,X'000000000006CAD8DC7F0B660000000000000005',1);
INSERT INTO transactions VALUES(16,'e3b6667b7baa515048a7fcf2be7818e3e7622371236b78e19b4b08e2d7e7818c',310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',1000,7650,X'000000000006CAD8DC7F0B66000000000000000A',1);
INSERT INTO transactions VALUES(17,'bd4e9cbbe69c2db893cd32182a2d315c89c45ba4e31aa5775d1fe42d841cea39',310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'000000140000000000033A3E7FFFFFFFFFFFFFFF01000000000000000000104D6178696D756D207175616E74697479',1);
INSERT INTO transactions VALUES(18,'d14388b74b63d93e4477b1fe8426028bb8ab20656703e3ce8deeb23c2fe0b8af',310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001E52BB33003FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(19,'f9e0527c85a9084d7eda91fc30a49993370d029efea031a8ccccdf846146a660',310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','',0,6800,X'0000001E4CC552003FF000000000000000000000046C6F636B',1);
INSERT INTO transactions VALUES(20,'2a2169991597036b6dad687ea1feffd55465a204466f40c35cbba811cb3109b1',310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000152BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(21,'5c6562ddad0bc8a1faaded18813a65522cd273709acd190cf9d3271817eefc93',310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000052BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(102,'db4ea092bea6036e3d1e5f6ec863db9b900252b4f4d6d9faa6165323f433c51e',310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000352BB33C8000000000000000A000000000000000A0000000000000000000013B0000003E8',1);
INSERT INTO transactions VALUES(103,'16462eac6c795cea6e5985ee063867d8c61ae24373df02048186d28118d25bae',310102,'11e25883fd0479b78ddb1953ef67e3c3d1ffc82bd1f9e918a75c2194f7137f99',310102000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001E52BB33023FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(104,'65d4048700fb8ae03f321be93c6669b8497f506a1f43920f96d994f43358c35b',310103,'559a208afea6dd27b8bfeb031f1bd8f57182dcab6cf55c4089a6c49fb4744f17',310103000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,-99994375,X'',1);
INSERT INTO transactions VALUES(105,'95332a7e3e2b04f2c10e3027327bfc31b686947fb05381e28903e3ff569bd4ff',310104,'55b82e631b61d22a8524981ff3b5e3ab4ad7b732b7d1a06191064334b8f2dfd2',310104000,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,-99994375,X'',1);
INSERT INTO transactions VALUES(106,'e062d1ebf4cb71bd22d80c949b956f5286080838a7607ccf87945b2b3abfcafa',310105,'1d72cdf6c4a02a5f973e6eaa53c28e9e13014b4f5bb13f91621a911b27fe936a',310105000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,-99994375,X'',1);
INSERT INTO transactions VALUES(107,'bbf0b9f6992755a3e371fb0c0b72f6828831e81c6f7ada6f95ba1104fb901ac3',310106,'9d39cbe8c8a5357fc56e5c2f95bf132382ddad14cbc8abd54e549d58248140ff',310106000,'mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK','mvCounterpartyXXXXXXXXXXXXXXW24Hef',10000,5625,X'',1);
INSERT INTO transactions VALUES(108,'9834219d2825b4d85ca7ee0d75a5372d9d42ce75eb9144951fca1af5a25915ec',310107,'51cc04005e49fa49e661946a0e147240b0e5aac174252c96481ab7ddd5487435',310107000,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','',0,6150,X'0000000C000000000000000100000000000000640000000000000064000000000000006400',1);
INSERT INTO transactions VALUES(109,'93c6d2499a0536c31c77a3db3fc9fc8456fbd0726c45b8f716af16f938727a73',310108,'8f2d3861aa42f8e75dc14a23d6046bd89feef0d81996b6e1adc2a2828fbc8b34',310108000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','mvCounterpartyXXXXXXXXXXXXXXW24Hef',31000000,5625,X'',1);
INSERT INTO transactions VALUES(110,'e8baf787b9e4636a3cad0ffeb62992ad7abb160dc6506af0546f566dc178de7e',310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','',0,6800,X'0000001400078A8FE2E5E44100000000000003E8000000000000000000001050534820697373756564206173736574',1);
INSERT INTO transactions VALUES(111,'f6a0f819e899b407cbfa07b4eff3d58902af3899abfbaa47d5f31d5b398e76e7',310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',5430,7650,X'00000000000000A25BE34B660000000005F5E100',1);
INSERT INTO transactions VALUES(112,'510f6feb902159622d83f64eae590a4fec88989869a20caf5804c313aa5e0186',310111,'fde71b9756d5ba0b6d8b230ee885af01f9c4461a55dbde8678279166a21b20ae',310111000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','',0,5975,X'0000001E52BB33023FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(113,'d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048',310112,'5b06f69bfdde1083785cf68ebc2211b464839033c30a099d3227b490bf3ab251',310112000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',5430,7124,X'00000028000352BB33C8000000000000000A000000000000000A0000000000000000000013B0000003E8',1);
INSERT INTO transactions VALUES(114,'34bce6f409758b3d6fd13282a99b277ef1fdf44a1025d2901075cac0249dbc63',310113,'63914cf376d3076b697b9234810dfc084ed5a885d5cd188dd5462560da25d5e7',310113000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','',0,6800,X'00000014000038FEDF6D2C6900000000000003E8010000000000000000000C4C6F636B6564206173736574',1);
INSERT INTO transactions VALUES(115,'025b810fce7735c5869b90846007e5f604f60c1beda4c1695f1c7fbec3d44bc2',310114,'24fc2dded4f811eff58b32cda85d90fb5773e81b9267e9a03c359bc730d82283',310114000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','',0,6800,X'00000014000038FEDF6D2C69000000000000000001000000000000000000044C4F434B',1);
INSERT INTO transactions VALUES(116,'4ab1a24283c1dbfc710be7b215d64e8a4510ee97af019e210049c25773b50beb',310115,'a632d67ff5f832fe9c3c675f855f08a4969c6d78c0211e71b2a24fe04be5656a',310115000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','',0,6800,X'00000014000038FEDF6D2C69000000000000000001000000000000000000076368616E676564',1);
INSERT INTO transactions VALUES(117,'27929c4fcad307a76ea7da34dd2691084f678a22ee43ce7f3842b78730ee08f9',310116,'8495ba36b331473c4f3529681a118a4cc4fa4d51cd9b8dccb1f13e5ef841dd84',310116000,'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
INSERT INTO transactions VALUES(482,'b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5',310481,'db37d8f98630ebc61767736ae2c523e4e930095bf54259c01de4d36fd60b6f4a',310481000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6375,X'0000000200000000000000010000000005F5E1006F8D6AE8A3B381663118B4E1EFF4CFC7D0954DD6EC68656C6C6F',1);
INSERT INTO transactions VALUES(483,'c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34',310482,'2e27db87dfb6439c006637734e876cc662d1ca74c717756f90f0e535df0787d6',310482000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','',0,6350,X'0000000200000000000000010000000005F5E1006F4838D8B3588C4C7BA7C1D06F866E9B3739C63037FADE0001',1);
INSERT INTO transactions VALUES(487,'3b95e07a2194174ac020de27e8b2b6ee24d5fc120f118df516ba28495657cf14',310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','',0,6800,X'0000001E52BB33003FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(488,'41e821ae1c6b553d0fa5d5a807b2e7e9ffaec5d62706d9d2a59c6e65a3ed9cef',310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',5430,7650,X'00000028000152BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(489,'870fb08b373705423f31ccd91fdbcabe135ad92d74e709a959dfa2e12f9a6638',310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','',0,6800,X'0000001E52BB33023FF000000000000000000000096F7074696F6E732030',1);
INSERT INTO transactions VALUES(490,'685d7f99fa76a05201c3239a4e0d9060ea53307b171f6ad7d482a26c73e9c0d1',310489,'2efdb36f986b3e3ccc6cc9b0c1c3cdcb07429fb43cbc0cc3b6c87d1b33f258b6',310489000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','',0,6800,X'0000001E52BB33033FF000000000000000000000046C6F636B',1);
INSERT INTO transactions VALUES(491,'7c437705c315212315c85c0b8ba09d358679c91be20b54f30929c5a6052426af',310490,'e2cb04b8a7368c95359c9d5ff33e64209200fb606de0d64b7c0f67bb1cb8d87c',310490000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','',0,6800,X'0000001E52BB33043FF000000000000000000000096F7074696F6E732031',1);
INSERT INTO transactions VALUES(492,'74db175c4669a3d3a59e3fcddce9e97fcd7d12c35b58ef31845a1b20a1739498',310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000000010000000005F5E100000000000000000000000000000C350007D000000000000DBBA0',1);
INSERT INTO transactions VALUES(493,'1b294dd8592e76899b1c106782e4c96e63114abd8e3fa09ab6d2d52496b5bf81',310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','',0,1000000,X'0000000A000000000000000000000000000C350000000000000000010000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(494,'c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a',310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
INSERT INTO transactions VALUES(495,'321bed395482e034f2ce0a4dbf28d1f800592a658e26ea91ae9c5b0928204503',310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','',0,6800,X'00000014000000063E985FFD00000000000000640100000000000000000000',1);
INSERT INTO transactions VALUES(496,'02156b9a1f643fb48330396274a37620c8abbbe5eddb2f8b53dadd135f5d2e2e',310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj',5430,7650,X'00000000000000063E985FFD000000000000000A',1);
INSERT INTO transactions VALUES(497,'a35ab1736565aceddbd1d71f92fc7f39d1361006aa9099f731e54e762964d5ba',310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj',5430,7650,X'00000000000000000000000100000015A4018C1E',1);
INSERT INTO transactions VALUES(498,'076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f',310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6300,X'00000014000000000AA4097D0000000005F5E100010000000000000000000C506172656E74206173736574',1);
INSERT INTO transactions VALUES(499,'0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf',310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6550,X'0000001501530821671B10650000000005F5E10001108E90A57DBA9967C422E83080F22F0C684368696C64206F6620706172656E74',1);
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
INSERT INTO undolog VALUES(152,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92050000000 WHERE rowid=1');
INSERT INTO undolog VALUES(153,'DELETE FROM debits WHERE rowid=26');
INSERT INTO undolog VALUES(154,'UPDATE balances SET address=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',asset=''XCP'',quantity=99999990 WHERE rowid=7');
INSERT INTO undolog VALUES(155,'DELETE FROM credits WHERE rowid=27');
INSERT INTO undolog VALUES(156,'DELETE FROM sends WHERE rowid=8');
INSERT INTO undolog VALUES(157,'UPDATE balances SET address=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',asset=''XCP'',quantity=199999990 WHERE rowid=7');
INSERT INTO undolog VALUES(158,'DELETE FROM debits WHERE rowid=27');
INSERT INTO undolog VALUES(159,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91950000000 WHERE rowid=1');
INSERT INTO undolog VALUES(160,'DELETE FROM credits WHERE rowid=28');
INSERT INTO undolog VALUES(161,'DELETE FROM sends WHERE rowid=9');
INSERT INTO undolog VALUES(162,'DELETE FROM broadcasts WHERE rowid=487');
INSERT INTO undolog VALUES(163,'UPDATE balances SET address=''myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM'',asset=''XCP'',quantity=92999138821 WHERE rowid=13');
INSERT INTO undolog VALUES(164,'DELETE FROM debits WHERE rowid=28');
INSERT INTO undolog VALUES(165,'DELETE FROM bets WHERE rowid=5');
INSERT INTO undolog VALUES(166,'DELETE FROM broadcasts WHERE rowid=489');
INSERT INTO undolog VALUES(167,'DELETE FROM addresses WHERE rowid=1');
INSERT INTO undolog VALUES(168,'DELETE FROM broadcasts WHERE rowid=490');
INSERT INTO undolog VALUES(169,'DELETE FROM broadcasts WHERE rowid=491');
INSERT INTO undolog VALUES(170,'DELETE FROM addresses WHERE rowid=2');
INSERT INTO undolog VALUES(171,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92050000000 WHERE rowid=1');
INSERT INTO undolog VALUES(172,'DELETE FROM debits WHERE rowid=29');
INSERT INTO undolog VALUES(173,'DELETE FROM orders WHERE rowid=5');
INSERT INTO undolog VALUES(174,'DELETE FROM orders WHERE rowid=6');
INSERT INTO undolog VALUES(175,'UPDATE orders SET tx_index=492,tx_hash=''74db175c4669a3d3a59e3fcddce9e97fcd7d12c35b58ef31845a1b20a1739498'',block_index=310491,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''XCP'',give_quantity=100000000,give_remaining=100000000,get_asset=''BTC'',get_quantity=800000,get_remaining=800000,expiration=2000,expire_index=312491,fee_required=900000,fee_required_remaining=900000,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(176,'UPDATE orders SET tx_index=493,tx_hash=''1b294dd8592e76899b1c106782e4c96e63114abd8e3fa09ab6d2d52496b5bf81'',block_index=310492,source=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',give_asset=''BTC'',give_quantity=800000,give_remaining=800000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=2000,expire_index=312492,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=6');
INSERT INTO undolog VALUES(177,'DELETE FROM order_matches WHERE rowid=1');
INSERT INTO undolog VALUES(178,'DELETE FROM balances WHERE rowid=22');
INSERT INTO undolog VALUES(179,'DELETE FROM credits WHERE rowid=29');
INSERT INTO undolog VALUES(180,'DELETE FROM burns WHERE rowid=494');
INSERT INTO undolog VALUES(181,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''XCP'',quantity=92995878046 WHERE rowid=22');
INSERT INTO undolog VALUES(182,'DELETE FROM debits WHERE rowid=30');
INSERT INTO undolog VALUES(183,'DELETE FROM assets WHERE rowid=10');
INSERT INTO undolog VALUES(184,'DELETE FROM issuances WHERE rowid=11');
INSERT INTO undolog VALUES(185,'DELETE FROM balances WHERE rowid=23');
INSERT INTO undolog VALUES(186,'DELETE FROM credits WHERE rowid=30');
INSERT INTO undolog VALUES(187,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''DIVIDEND'',quantity=100 WHERE rowid=23');
INSERT INTO undolog VALUES(188,'DELETE FROM debits WHERE rowid=31');
INSERT INTO undolog VALUES(189,'DELETE FROM balances WHERE rowid=24');
INSERT INTO undolog VALUES(190,'DELETE FROM credits WHERE rowid=31');
INSERT INTO undolog VALUES(191,'DELETE FROM sends WHERE rowid=10');
INSERT INTO undolog VALUES(192,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''XCP'',quantity=92945878046 WHERE rowid=22');
INSERT INTO undolog VALUES(193,'DELETE FROM debits WHERE rowid=32');
INSERT INTO undolog VALUES(194,'DELETE FROM balances WHERE rowid=25');
INSERT INTO undolog VALUES(195,'DELETE FROM credits WHERE rowid=32');
INSERT INTO undolog VALUES(196,'DELETE FROM sends WHERE rowid=11');
INSERT INTO undolog VALUES(197,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91950000000 WHERE rowid=1');
INSERT INTO undolog VALUES(198,'DELETE FROM debits WHERE rowid=33');
INSERT INTO undolog VALUES(199,'DELETE FROM assets WHERE rowid=11');
INSERT INTO undolog VALUES(200,'DELETE FROM issuances WHERE rowid=12');
INSERT INTO undolog VALUES(201,'DELETE FROM balances WHERE rowid=26');
INSERT INTO undolog VALUES(202,'DELETE FROM credits WHERE rowid=33');
INSERT INTO undolog VALUES(203,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91900000000 WHERE rowid=1');
INSERT INTO undolog VALUES(204,'DELETE FROM debits WHERE rowid=34');
INSERT INTO undolog VALUES(205,'DELETE FROM assets WHERE rowid=12');
INSERT INTO undolog VALUES(206,'DELETE FROM issuances WHERE rowid=13');
INSERT INTO undolog VALUES(207,'DELETE FROM balances WHERE rowid=27');
INSERT INTO undolog VALUES(208,'DELETE FROM credits WHERE rowid=34');

-- Table  undolog_block
DROP TABLE IF EXISTS undolog_block;
CREATE TABLE undolog_block(
                        block_index INTEGER PRIMARY KEY,
                        first_undo_index INTEGER);
INSERT INTO undolog_block VALUES(310400,152);
INSERT INTO undolog_block VALUES(310401,152);
INSERT INTO undolog_block VALUES(310402,152);
INSERT INTO undolog_block VALUES(310403,152);
INSERT INTO undolog_block VALUES(310404,152);
INSERT INTO undolog_block VALUES(310405,152);
INSERT INTO undolog_block VALUES(310406,152);
INSERT INTO undolog_block VALUES(310407,152);
INSERT INTO undolog_block VALUES(310408,152);
INSERT INTO undolog_block VALUES(310409,152);
INSERT INTO undolog_block VALUES(310410,152);
INSERT INTO undolog_block VALUES(310411,152);
INSERT INTO undolog_block VALUES(310412,152);
INSERT INTO undolog_block VALUES(310413,152);
INSERT INTO undolog_block VALUES(310414,152);
INSERT INTO undolog_block VALUES(310415,152);
INSERT INTO undolog_block VALUES(310416,152);
INSERT INTO undolog_block VALUES(310417,152);
INSERT INTO undolog_block VALUES(310418,152);
INSERT INTO undolog_block VALUES(310419,152);
INSERT INTO undolog_block VALUES(310420,152);
INSERT INTO undolog_block VALUES(310421,152);
INSERT INTO undolog_block VALUES(310422,152);
INSERT INTO undolog_block VALUES(310423,152);
INSERT INTO undolog_block VALUES(310424,152);
INSERT INTO undolog_block VALUES(310425,152);
INSERT INTO undolog_block VALUES(310426,152);
INSERT INTO undolog_block VALUES(310427,152);
INSERT INTO undolog_block VALUES(310428,152);
INSERT INTO undolog_block VALUES(310429,152);
INSERT INTO undolog_block VALUES(310430,152);
INSERT INTO undolog_block VALUES(310431,152);
INSERT INTO undolog_block VALUES(310432,152);
INSERT INTO undolog_block VALUES(310433,152);
INSERT INTO undolog_block VALUES(310434,152);
INSERT INTO undolog_block VALUES(310435,152);
INSERT INTO undolog_block VALUES(310436,152);
INSERT INTO undolog_block VALUES(310437,152);
INSERT INTO undolog_block VALUES(310438,152);
INSERT INTO undolog_block VALUES(310439,152);
INSERT INTO undolog_block VALUES(310440,152);
INSERT INTO undolog_block VALUES(310441,152);
INSERT INTO undolog_block VALUES(310442,152);
INSERT INTO undolog_block VALUES(310443,152);
INSERT INTO undolog_block VALUES(310444,152);
INSERT INTO undolog_block VALUES(310445,152);
INSERT INTO undolog_block VALUES(310446,152);
INSERT INTO undolog_block VALUES(310447,152);
INSERT INTO undolog_block VALUES(310448,152);
INSERT INTO undolog_block VALUES(310449,152);
INSERT INTO undolog_block VALUES(310450,152);
INSERT INTO undolog_block VALUES(310451,152);
INSERT INTO undolog_block VALUES(310452,152);
INSERT INTO undolog_block VALUES(310453,152);
INSERT INTO undolog_block VALUES(310454,152);
INSERT INTO undolog_block VALUES(310455,152);
INSERT INTO undolog_block VALUES(310456,152);
INSERT INTO undolog_block VALUES(310457,152);
INSERT INTO undolog_block VALUES(310458,152);
INSERT INTO undolog_block VALUES(310459,152);
INSERT INTO undolog_block VALUES(310460,152);
INSERT INTO undolog_block VALUES(310461,152);
INSERT INTO undolog_block VALUES(310462,152);
INSERT INTO undolog_block VALUES(310463,152);
INSERT INTO undolog_block VALUES(310464,152);
INSERT INTO undolog_block VALUES(310465,152);
INSERT INTO undolog_block VALUES(310466,152);
INSERT INTO undolog_block VALUES(310467,152);
INSERT INTO undolog_block VALUES(310468,152);
INSERT INTO undolog_block VALUES(310469,152);
INSERT INTO undolog_block VALUES(310470,152);
INSERT INTO undolog_block VALUES(310471,152);
INSERT INTO undolog_block VALUES(310472,152);
INSERT INTO undolog_block VALUES(310473,152);
INSERT INTO undolog_block VALUES(310474,152);
INSERT INTO undolog_block VALUES(310475,152);
INSERT INTO undolog_block VALUES(310476,152);
INSERT INTO undolog_block VALUES(310477,152);
INSERT INTO undolog_block VALUES(310478,152);
INSERT INTO undolog_block VALUES(310479,152);
INSERT INTO undolog_block VALUES(310480,152);
INSERT INTO undolog_block VALUES(310481,152);
INSERT INTO undolog_block VALUES(310482,157);
INSERT INTO undolog_block VALUES(310483,162);
INSERT INTO undolog_block VALUES(310484,162);
INSERT INTO undolog_block VALUES(310485,162);
INSERT INTO undolog_block VALUES(310486,162);
INSERT INTO undolog_block VALUES(310487,163);
INSERT INTO undolog_block VALUES(310488,166);
INSERT INTO undolog_block VALUES(310489,168);
INSERT INTO undolog_block VALUES(310490,169);
INSERT INTO undolog_block VALUES(310491,171);
INSERT INTO undolog_block VALUES(310492,174);
INSERT INTO undolog_block VALUES(310493,178);
INSERT INTO undolog_block VALUES(310494,181);
INSERT INTO undolog_block VALUES(310495,187);
INSERT INTO undolog_block VALUES(310496,192);
INSERT INTO undolog_block VALUES(310497,197);
INSERT INTO undolog_block VALUES(310498,203);
INSERT INTO undolog_block VALUES(310499,209);
INSERT INTO undolog_block VALUES(310500,209);

-- For primary key autoincrements the next id to use is stored in
-- sqlite_sequence
DELETE FROM main.sqlite_sequence WHERE name='undolog';
INSERT INTO main.sqlite_sequence VALUES ('undolog', 208);

COMMIT TRANSACTION;
