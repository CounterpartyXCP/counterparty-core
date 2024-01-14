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
INSERT INTO blocks VALUES(310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,NULL,NULL,'11461f972c4cd85c87b5abfedb3cee589d09e945570d34564dcde6f4df9d2b57','c98c67acf95576305ce0ab7b4254095810e2829539ba981399101e1c1160ce70','6068f4b7a1ec5df45f118f3da83f34f14e3af301bdd3879258468f893cf24f7e');
INSERT INTO blocks VALUES(310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,NULL,NULL,'355d92f841de89a1d97c3b2ea7623959ea4494bb62ea7e67ad359beb68caca8c','83949e7638dee6e40fe6af5e0e4293f320efafcd828f1c1b680a1050720f01ce','ec451a4d600785415bb90c92329f7126019a3062f90926e56cee19314b415310');
INSERT INTO blocks VALUES(310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,NULL,NULL,'edcd7e344fb5cca16999f025594890b8b54543555e61eb3807406bb4204677f2','f0f1c788b2de58c85bf27abd8c6812322244ea0c8a0c7eb586dba20cbb6266e7','bb9d02ae750c6ecfb64088494c14289fa92efc6e4e1ee4533465a8fd825b8e1e');
INSERT INTO blocks VALUES(310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,NULL,NULL,'abd71a31bc1f8a072761b23a5bc2976731ebdf305d1d7d33922e93573f308129','ad697452602d521f0042134d279a6815d83f0aedf17b942b24e3c0db35a4329a','e481fade1455e80caef9d0ae429c48d4263547375000e8329a504bfc9707811e');
INSERT INTO blocks VALUES(310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,NULL,NULL,'0c3914f9676e506a96e6db793f15200ef33087cd47de4d27628849013a391daa','56a42851f8d33f1299aed8dbb23fea0b61e882bfebf14a0fed9cf197007f2055','4bb0206be32ad88526e3cb39ee0daec53492fd743d14c36afeffd9d77df0fe13');
INSERT INTO blocks VALUES(310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,NULL,NULL,'57ff5f34a9e418b179db9003414c5f3bdfa7feeb538f24071b23d024a3d05df0','f4271024b06d5c0aa417214005d503cc63fc08f5eed17f42e5743d1f71d109e8','abb090cc9f4d7ea088837c89a167f3a426601c3f0b44f2786cf31b2ec3e26ed9');
INSERT INTO blocks VALUES(310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,NULL,NULL,'bfed530458339aab02ff75ad76738569dc6997c7a35d4452351678b04e022f68','6fa8225b2e9d0da90194f688c06301e09eed409648e9ffe91f3371db412f62c1','e31a7bf97d2ed0afe97a6d1681ed195f5b4327b148d054640c52abd0c0c900a0');
INSERT INTO blocks VALUES(310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,NULL,NULL,'d4feec997754d11a1502e5351ed62fcfbfcafb770e19a37da41d1d88b7b45ed4','649bb0ea1af5e0b2f993279b3e6b4369de798c901fdd28a0a4605be8b65f6dc6','2058ca8b87780a49f20cad8d36a9b1c0592abec264437dace13d59eab45fbbc0');
INSERT INTO blocks VALUES(310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,NULL,NULL,'4ab5ff9e71bbc83956557fb5abec98372fa38e5580838fb258b2d831bfc4d9ea','b681b1be3f64cc0b8a5c8eab5fc39cecfc8a31410fd041fdef811bbf84dc5fb4','ce75b96ff248dcc6c843dbe7f1432095ccb936f7ccb44e5b3d9c587b9c2f2ced');
INSERT INTO blocks VALUES(310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,NULL,NULL,'1909ef40a24263776cb9e0d52a690048b50728855a0fe4b0e1ba3834a9e401c1','44d952f3d7055db519ec9b060db4d5496774f87e6e2ab1dad4a04e4fa87b4a7a','c82862151fa43335d3ebc0543425e89e6bae5478b58b9ba4d8956561b11f7829');
INSERT INTO blocks VALUES(310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,NULL,NULL,'c3d51a5f2df90c089844ba4de7d5541f6051490aa1389e5945a7bb91d49e3589','397244dcec1f4786085bbc415e227af108586d0e9300849b34b309ec34796c6e','effea8ad98afed02b5c9a9856dff7848baa8375fa72c1391e5fae59ca1ab6038');
INSERT INTO blocks VALUES(310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,NULL,NULL,'a9dc31556d38b118eeb0bcbb3a374a0ed79adec4eb23e00c80c0599ba97c9a7a','0682683cf445b294b40699c7191bd3c912c0de61af13215871888e8f6a887929','cf745d863497a1301bc37612cc99fd806cbd30abf89b25ed1f976b690c0f33c1');
INSERT INTO blocks VALUES(310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,NULL,NULL,'e72be5070d0a5853631d902d334e8b88eddf6e79616373311babc4a0a27dd3d8','7d0b0406252bc3184abc9c4317d3cda92df70b63d2c9e82bc4d3c9176f7cb500','ea380aa2241f5d4eb17c019f3e4e72bde73437c32e7e92bb7b8ea6a3e16c0313');
INSERT INTO blocks VALUES(310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,NULL,NULL,'cb0962222af917dbac2a11465c22cd80770c0b3cdb8bdc0870c99a8116745c9e','bd3dbd32341a37a1ad84706bfb6b5f83f27bf843e8ec179aa23c37e34528726e','621cbd7caa921bfb9c01b196a4a799a9640d3ccd94126051fbad5cca26d35a23');
INSERT INTO blocks VALUES(310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,NULL,NULL,'6ff899433f22546c41a15f20b4c66913c747931500fee10d58c4a17b9e2f0c88','2c9c0dacece5d5dfb1dbbcf0d9ffa0871239d6f03cc2f22b5fddeb4af37594c8','7a3662562c2ec312d8696cb0399374accb936855a328ace8a25ec48633ea0494');
INSERT INTO blocks VALUES(310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,NULL,NULL,'ec66a06cde401b66917c6d1d4e1ee8893405cfbf0474560d9997d6960c8af710','aecd7a8cde4a51bcb813613162f090909d350a99f73638fc6fb72367d8f3edff','afe7a3ca203c96895fb611f832f74ff5b689e25614d8f950bd11b1e899142c1e');
INSERT INTO blocks VALUES(310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,NULL,NULL,'b2053109bff06dae1705fc32ab0712f38bf9d206fa3517fbf0a938d1b5f33bad','a960cfe980e550637c6d48e75574e0aaad6a4bd2cb82dab067c0ba41199dda0f','b65b8f91204b488b184c7be521c3930e96dc4c5369dbefcf65b726577b6ff814');
INSERT INTO blocks VALUES(310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,NULL,NULL,'d7051de4d03fb31bfedf215b407b1edc12789c1f2748abb5a72257ad8f5113ce','94426d2676a5b37791fb904ee81eefab637e975bf4b002603f255d5236c99513','89a08f4170f588988fd0f81ad9938bd2458a0a4945125e0034945b86fa05b160');
INSERT INTO blocks VALUES(310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,NULL,NULL,'35c95a70193ded2f9ee18254a91ce5d4834bb162fc3cca85dd432339257539b8','0cf6f7edf76cca26ff9947c7c515683eda70e7706cc1c953a29bca09f7e9b14a','d2f5ae2c328de0653a534087046bfcb03d1b808f5f58891e1c9c2f234466716e');
INSERT INTO blocks VALUES(310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,NULL,NULL,'8315de64ee1051c333687ba9fae6244287b85bcc1e3a4b67f3fe7d51b931378b','55f9adc8caa2dfd9ef2c2ba251d7a81f910b0cf0620b33abeb431d026f18be26','b25d31af31b19417bcf4d65ec73fe9e670d5ee329b755cb06895641f85d08317');
INSERT INTO blocks VALUES(310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,NULL,NULL,'c2d646bd3f54eec73cd9da6f5da4bc159d0c64e8fb9ad4095dfa58850e65c7b1','dbe0486a5c97a7b92779b86b088aea7db93da2625cc54b58cd8b0b7c7f6a794b','a48562041bf1787cf6b8e2f14d7505ec2821e20adba7464cb32c4f242c56378a');
INSERT INTO blocks VALUES(310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,NULL,NULL,'619367fb7657e0fb4800acd385eb5593d085ce5cbfbfb098dafa98612d9fd445','3ca9d30624cf613db555ee648c702146b618eb0c5402cd80223f792d4c24c588','9ce930a58fb79d6b3c8f1b5a22b7824248429bf9128f3d26f6bb2c1176a29890');
INSERT INTO blocks VALUES(310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,NULL,NULL,'ba865dbc8263aaf153d7264dfc6a580bebe9391ca0551f15a1c822c6cbe2b8de','1eadd8cb119230016170533bdafce87f42121bda14190ae86dd012f3473f0d4b','9b7984b98310314168c2d4e792dc05d7f8a9a6de62aa439221b5a389c64eb9e4');
INSERT INTO blocks VALUES(310024,'b03042b4e18a222b4c8d1e9e1970d93e6e2a2d41686d227ff8ecf0a839223dc5',310024000,NULL,NULL,'368e948cbf42de80aca51abe75d09ec78196924453719182ccc86419df5da2db','10b66f858da5654d76a958e0f1795ca5c3955cee9ae4f769e250387f88ed62a6','b2e881823d6773376a8b2691e2987243d7bb0c088965dd20d199b9558bb870a7');
INSERT INTO blocks VALUES(310025,'a872e560766832cc3b4f7f222228cb6db882ce3c54f6459f62c71d5cd6e90666',310025000,NULL,NULL,'9f7132c808936f580d4fb1dc5791541a5a3d23532d1093c20d434007f8dde54c','f1799b6572be54c9e1eee2b214afe923cc68bb8aede154c8bb4d9781636a8003','96beee951073fec74d46d133f03fca6d4df2110bca84a6669f3802b7dea2211e');
INSERT INTO blocks VALUES(310026,'6c96350f6f2f05810f19a689de235eff975338587194a36a70dfd0fcd490941a',310026000,NULL,NULL,'074ea6f10a5290cff31f7b21483f7b2248723c8d1b5bc060c31219f66f37def7','24c557e0f9b6bdcb56cac33183a868f0d4a98f6ec3f3e96e81c3ecff424b1e9d','28b472af5b0ec0dcbf2180df7219cbbff2762e9ad50cef46f78bf5aa70d69b2d');
INSERT INTO blocks VALUES(310027,'d7acfac66df393c4482a14c189742c0571b89442eb7f817b34415a560445699e',310027000,NULL,NULL,'a3ade2b2e5bc701996f511f3e85d596b60f882a3254fd975769c0f38b3b14cb3','fd188409c0b7a14380a8f8fbb68d3ad4166836c2c7507075a6e3d983ef9c4361','29d570da644bbb62e2261e0ef44cbcbd9db0ace5a8e02069fd0939d6b6cfcd15');
INSERT INTO blocks VALUES(310028,'02409fcf8fa06dafcb7f11e38593181d9c42cc9d5e2ddc304d098f990bd9530b',310028000,NULL,NULL,'3bf124a34825b5c487c94dd79b1ea4f25e657294966879f1c10b56b37a3d29b5','107a3012b22cc06e08755d8298273f514e53bd9aa3783f945039dee51d518f9c','68f732b5d3150acdfb88274fe8f40e049fd78b1620fa6a393fa2dbb0d5d1e7dd');
INSERT INTO blocks VALUES(310029,'3c739fa8b40c118d5547ea356ee8d10ee2898871907643ec02e5db9d00f03cc6',310029000,NULL,NULL,'e502eb7b282e0bd4940d8f75ef51d677a641f3d55304adcb015bc249c97892bf','59744e8ac3d1ac2d6c2cdfb88af650b6d7c315a1883dc741d2ce5a1a4bd961be','ff8b7a73384abbca1955ff4c468804b131e098defd1a30cc9db226f88da825e2');
INSERT INTO blocks VALUES(310030,'d5071cddedf89765ee0fd58f209c1c7d669ba8ea66200a57587da8b189b9e4f5',310030000,NULL,NULL,'d64b5eb04ddfb5600be40142b1fd27c308387a35942a6e8a6916407bbc1313b1','ab521603daf188e196088b8b87e601a08661bdc7e4f8a45e50ef3dcb03b1b334','51045bbe24e7ed833ac285bbb41ceb3f81f1a5fabd25dbd4b7c621c6b384d6d3');
INSERT INTO blocks VALUES(310031,'0b02b10f41380fff27c543ea8891ecb845bf7a003ac5c87e15932aff3bfcf689',310031000,NULL,NULL,'e9c97dd7adb1b22d4ed0238607faeb2d14c090fbd7d685275ee802ab23b4b740','57fa120c1b422e814374e7face23af95055ac769c5e92c4c79e127d46217b0c5','693394120442490e4c9693420ac0011258a0db45dd76ef0d2622ab3b67a9e56f');
INSERT INTO blocks VALUES(310032,'66346be81e6ba04544f2ae643b76c2b7b1383f038fc2636e02e49dc7ec144074',310032000,NULL,NULL,'2544ffced9af1aabd84ab51fb78c56c9beac03dcb286aebd4202938dfa0754ea','ded104217f735a07690ab25bc366c1d32ca7435226ffec6c4420f0360b041b6a','a5df6d50f2d4626993c08cfcd470856c0f45db4c2849c1f91420222e675b9d61');
INSERT INTO blocks VALUES(310033,'999c65df9661f73e8c01f1da1afda09ac16788b72834f0ff5ea3d1464afb4707',310033000,NULL,NULL,'4355d3ebb95187fec36b1847a4c3777d8e1d5541bd1d9ff8461b8ac5b9881261','10dfd85d3bef47037fce13358eda4f624622595e9e1074fc5d235d0626e6ac4f','9b06312d864276f40f86de0a9609765c3d15abf81fb201ee92fd5ffdfee55147');
INSERT INTO blocks VALUES(310034,'f552edd2e0a648230f3668e72ddf0ddfb1e8ac0f4c190f91b89c1a8c2e357208',310034000,NULL,NULL,'c7fcb5134bd8131c035d65b5eeef8a3cd214348822563232a992f3f703c6b0b9','b1772192fe5ae400bfad0c6c15b0cc047b6ffdafbbd77661886423f0fa6fe823','125fc94e7c6e8f911f8967ac6b6d8d79c4407a43e2a711a537987344832d26b5');
INSERT INTO blocks VALUES(310035,'a13cbb016f3044207a46967a4ba1c87dab411f78c55c1179f2336653c2726ae2',310035000,NULL,NULL,'c41c280498ce05d6073fc6e89be2684dc68c345c1c43c00b9a3f9041954fce26','73310d0216df4367cae732c40459f470b1335fe4be1225dee1c41818ee9bbb0a','abfa08aa02c0c23b8882acbbde6239a898023e13eff835735bcace24f432cd99');
INSERT INTO blocks VALUES(310036,'158648a98f1e1bd1875584ce8449eb15a4e91a99a923bbb24c4210135cef0c76',310036000,NULL,NULL,'86c67fd234ca9d2406080018b2677386990fac477db8008c0092d40a398203ed','fc34ac777facee3ffd3aec61ffe9f771469b4d9e2bdcc072d58c092af32a06a6','cfcd1c01b5580b8d7583dd197cffb847cd653b31562c37bf432bebaa7c960d38');
INSERT INTO blocks VALUES(310037,'563acfd6d991ce256d5655de2e9429975c8dceeb221e76d5ec6e9e24a2c27c07',310037000,NULL,NULL,'3ae6272437eb0758a779d68785c41e119d1204dd5421c78e03b9d12eba64804b','2e274b56f098e7b9b28d5c825aebc7590c9a5c2bf0c4bd43a68ad2bdd1ee7d58','4442d5f627ec096fcb2fb5d3d52fda81d6bd743763660e7365deda9e18d32bc9');
INSERT INTO blocks VALUES(310038,'b44b4cad12431c32df27940e18d51f63897c7472b70950d18454edfd640490b2',310038000,NULL,NULL,'18f7552567b898f6c2cfe8c829903912445de5dbf05b56a13bf9b402a24fdc11','bebe3086c16076727281bcf208b6b06e4f5723126dcf962e0cdd3f2e642743ee','7adff7e008cbb1df29ec356676cf9dd25072a426421404cfef3d3b09883a5b30');
INSERT INTO blocks VALUES(310039,'5fa1ae9c5e8a599247458987b006ad3a57f686df1f7cc240bf119e911b56c347',310039000,NULL,NULL,'85f2255f9256a5faf59ddec1c58b1d3bc12c91bc2c62ead61b48e1f94ea2888d','12a64fd90a24fd6bb67147c32386152975af9c7c5b26db065d1938c10aef1831','910b59b9ff62ab413000065b475173389683dfb4ad28c1b11c37be6cd84e792b');
INSERT INTO blocks VALUES(310040,'7200ded406675453eadddfbb2d14c2a4526c7dc2b5de14bd48b29243df5e1aa3',310040000,NULL,NULL,'b799477db184351df5503f8d15d5461a0483ea35142c003b7e640429663ad943','15c8758e26b1bd6881634c7067576b3af4ca597a428ac93a7e77a3381e641a3e','5cdddd6f95daddaa58c238801bd75da59cb2979c6eff63811836e1fdca15af4f');
INSERT INTO blocks VALUES(310041,'5db592ff9ba5fac1e030cf22d6c13b70d330ba397f415340086ee7357143b359',310041000,NULL,NULL,'efa9cd46741b59e74263d6d348584f1a61e8ba32163c09fc3ff2e41a5431a483','f4dd328ad6418312702b52eb3c3cfa9d41c38931eb97291c84d66cab6a16f1c6','259d8c34dd63c6131cf317d92d7b39aec1443d16cc95d15c411a3f0fef09b416');
INSERT INTO blocks VALUES(310042,'826fd4701ef2824e9559b069517cd3cb990aff6a4690830f78fc845ab77fa3e4',310042000,NULL,NULL,'f3159919f381d46a3e1341703e55192a02a36519e71fc2675285a3a14c4ee04d','53d33612812b80cd0d50d2b0cf3167333e505c3f4516c2bcfb56b36ca4ee3370','5e4b4c32e32ef3ec8ab85e95d6a311d54d0b7fbe4b89931301b1381a7fb50e9b');
INSERT INTO blocks VALUES(310043,'2254a12ada208f1dd57bc17547ecaf3c44720323c47bc7d4b1262477cb7f3c51',310043000,NULL,NULL,'961c79ea2b7dcc2d7489c423b568fb978631e71732d6b998bcc0657aa4d19194','27e9d4404c7e95912d071fbec3614552b72ee758a84c5ce07723ab8f3f78e92e','19f970887fce78b533973f9f109f4ffddda1c9ad598bd57be6b15a3a9a8b0465');
INSERT INTO blocks VALUES(310044,'3346d24118d8af0b3c6bcc42f8b85792e7a2e7036ebf6e4c25f4f6723c78e46b',310044000,NULL,NULL,'d674c39010fd4554efa487d97a3d9cae278ed9b4aff0ce57db33bd881beeb3e3','b5e6b9ce39b1f0e9a396d76773ff09e98e0b14684b27748326a4e42d92f2201e','14d896fba1b46029a268e8277bbadb42a0ca44226d98a2aa1df46b9501ef54b8');
INSERT INTO blocks VALUES(310045,'7bba0ab243839e91ad1a45a762bf074011f8a9883074d68203c6d1b46fffde98',310045000,NULL,NULL,'9ba70a032ae92672174421689c0845784f0cef7374e88b2f5258260191864bf1','44c0c4607cb412a373b32a9c074a107d81f127ab5ce4ade71d424f142eac20ee','d924836281d50ce4cb47437f394e47c1972fbee93f5671cbbd6ee60a6926591a');
INSERT INTO blocks VALUES(310046,'47db6788c38f2d6d712764979e41346b55e78cbb4969e0ef5c4336faf18993a6',310046000,NULL,NULL,'114a6ab930fbdf8531431620ed219db3756a634c5b99af6ce1ee66d527d277ff','acd16cf40f39d329567130c4e3cde7dcb542876507e07e0b4551b4f5876bf3fb','7083f547a727385edd392b29a421f5331eb6266d04d359b76acda762c346316e');
INSERT INTO blocks VALUES(310047,'a9ccabcc2a098a7d25e4ab8bda7c4e66807eefa42e29890dcd88149a10de7075',310047000,NULL,NULL,'5356512c94ea2c77623d874a927aae8c3dce287a34dfd27a617abfa57142c7f3','e4f5c305105f0f8aca56c405ef862f296003bbd50c9745feffd26cd9d8747d64','f161ef9a5c284b3cc061ccab69ba4fee2eeae7db940448587af9b68250615227');
INSERT INTO blocks VALUES(310048,'610bf3935a85b05a98556c55493c6de45bed4d7b3b6c8553a984718765796309',310048000,NULL,NULL,'0902ca0868560d05049c983bca3ab91cdd5eafc46ab0a948d702abcbc4010582','aee5101356aaa4b7df3dffc664999daf73ff61047a2ea2af3968c9caed495208','0e1bed4b3f632bc50613cef3755cf845444bb4d711635057f26c977521b520e8');
INSERT INTO blocks VALUES(310049,'4ad2761923ad49ad2b283b640f1832522a2a5d6964486b21591b71df6b33be3c',310049000,NULL,NULL,'978794628fc95756032cb7fb4e9d5ed286373d84fafbcfceec9af71d18c4c0be','761e40301eb79087e41ad468b13bbb44357a31139f5c68d643f0729414a298cc','31a7c0e19c3d9a3be1c0cd1c3be0719581be5b747545b3977ea52a44b1207585');
INSERT INTO blocks VALUES(310050,'8cfeb60a14a4cec6e9be13d699694d49007d82a31065a17890383e262071e348',310050000,NULL,NULL,'ff16abeb1d35e0e422f165e206b0d69e0b9ff48b68fc6656c1af74801908b92d','2e24baa1662d1db28d4f24cd7b5d62f2be395d67045876bbb19791cb6bd83895','6d372227d4f56d408594fcee6785e4267337ee9e1247fad9fe44901cf1db0e2e');
INSERT INTO blocks VALUES(310051,'b53c90385dd808306601350920c6af4beb717518493fd23b5c730eea078f33e6',310051000,NULL,NULL,'556ff900993e70cabefd05ddd5dbe3e8e10bb5c9ada7913b75d84af067004ed5','9b640fef6d98944648c60f06cb9354e617e6dbfc7e344542b21df3c3386633f0','f77d373391621f89af1dede34c825ca3e087e4bba0223bb2924a11322452a632');
INSERT INTO blocks VALUES(310052,'0acdacf4e4b6fca756479cb055191b367b1fa433aa558956f5f08fa5b7b394e2',310052000,NULL,NULL,'15af3a616a2974aa70b7b58f88132051f335af299473db925b619fda8be1afc7','e5f0414696decf12064d85620d6159495749b228002ac1e0c4976ae3f1ec8213','12cd0a3ef144ddb062dc29e1f5e8ba275cf56bb2d9ea3ef2ecb8124a50d1a1f6');
INSERT INTO blocks VALUES(310053,'68348f01b6dc49b2cb30fe92ac43e527aa90d859093d3bf7cd695c64d2ef744f',310053000,NULL,NULL,'ed0ed3b480b38929a425c2b61c86582495764624e020cb86b3a95fc7d59c692c','d6f8f412bc902313556282d0f7c9be5fbfda09632a1a9f6c3eaa0bb73ba7f3f6','9185bf881e63b6de9bb492d2e9b2c7dfecde64b6fbcbbf5462beb1db94d7628f');
INSERT INTO blocks VALUES(310054,'a8b5f253df293037e49b998675620d5477445c51d5ec66596e023282bb9cd305',310054000,NULL,NULL,'f012825d2d549910910ad6b7e4ac2373d095b53869f0793709684f0ff05bb108','93949160eae37f91bd251c4d944e4a56d30eed896b1ea9ea29f7458899eb320d','2febb791a247d35963c312b5084a4a531f32a0b50ed7dd479fbd098f6f5f2d68');
INSERT INTO blocks VALUES(310055,'4b069152e2dc82e96ed8a3c3547c162e8c3aceeb2a4ac07972f8321a535b9356',310055000,NULL,NULL,'90c08144277fe622573282349edaf9e59289b716b5b4e368d88ac25e67e788d1','57b15f1a83f1b2921ce3560a9b92f3346bdb3eaa0be30c1080fee201caa64584','7bf273d0a9b8cfc88f18e44a4d104eaf761ffb43b89e56c6079953b9adf72635');
INSERT INTO blocks VALUES(310056,'7603eaed418971b745256742f9d2ba70b2c2b2f69f61de6cc70e61ce0336f9d3',310056000,NULL,NULL,'c888ae590b64fa4514ed7f94ba785b12e881052185cc4702b598cf6e48cbb3ba','650400804f41a3399cfe41c123213a645e43a55773e67d77016103c015b5dd8c','c493f1251a9414df2947d5c80f49bbe9c9eb20c43187c69207ec7fef4dd0e06b');
INSERT INTO blocks VALUES(310057,'4a5fdc84f2d66ecb6ee3e3646aad20751ce8694e64e348d3c8aab09d33a3e411',310057000,NULL,NULL,'e68c9a569fda6f1e1e59502953c9735857a0ee158a76397722436466df24708e','dcb53e76b504ba9e2a818171aeec4833c2a540375987842c16ce46e8842bbc80','6c4834d5ec45cab3829a43c132f37f1498316ea44153488de4aca5b1c75ce738');
INSERT INTO blocks VALUES(310058,'a6eef3089896f0cae0bfe9423392e45c48f4efe4310b14d8cfbdb1fea613635f',310058000,NULL,NULL,'9f6607682f4a6274c2a45895f849816aec83ff0820709ba781634b84518eb05d','f480fb7a7c6d8692e31e8a2b1e0f38f5c4d1f59b4c882d03b61ad9047a4957f7','14ea59fa190c0af6aa34583fde6fa5d4f8ee702fccef7b3e5e0ab9f5ba22d94a');
INSERT INTO blocks VALUES(310059,'ab505de874c43f97c90be1c26a769e6c5cb140405c993b4a6cc7afc795f156a9',310059000,NULL,NULL,'49b10a5c390f603e7be0d405bf1fcae95fd15682ef2e41a3b2fcf713d271e541','aff9150556ae5e2c4a7ef8bdf6b1e593ee78ffd637a4cd97acd02901d4716ac9','8bc7082c78a6d322ec78546a20d085653a5d492f66034e16c80753807d99ee80');
INSERT INTO blocks VALUES(310060,'974ad5fbef621e0a38eab811608dc9afaf10c8ecc85fed913075ba1a145e889b',310060000,NULL,NULL,'1d6cea34d6f7042ced3a5211da80de88fa77c900af5526f3033b715e4f68df17','3a736727d6688231d9092264c53bc3bc407207e7180fd43cfe1660f4e5c7740a','41bdcc158d830137c673c98a8d8e8a14b0bfdb5e25b6b3d6cd1497b70cf3231c');
INSERT INTO blocks VALUES(310061,'35d267d21ad386e7b7632292af1c422b0310dde7ca49a82f9577525a29c138cf',310061000,NULL,NULL,'0c43668fdc3d6cc6ec84fee99c68f0eff21650a618db35bc20e428550eae9b0c','5f3b60445f0c6352c905a009f8b42d1afe47ea6fe7ddb6781fbc32fa3ed95e3f','750eb9f23802154dee971cf8526157ab431cf89efbed98e91c58216e3fc3e2cf');
INSERT INTO blocks VALUES(310062,'b31a0054145319ef9de8c1cb19df5bcf4dc8a1ece20053aa494e5d3a00a2852f',310062000,NULL,NULL,'cf03a34b29d3a8f8ea5fadb017426f2843c6ab2e785032b6dec70d7aba7bce4a','c83f6d1349f48dd911ee368c280b3aeadfaad7fd6b944494122eb993fb93f87a','03a0bbafdafb122af4a39d53c38cb5db4678bef2722bf22b5065daf81ad95b07');
INSERT INTO blocks VALUES(310063,'0cbcbcd5b7f2dc288e3a34eab3d4212463a5a56e886804fb4f9f1cf929eadebe',310063000,NULL,NULL,'e145dfc2c7f053a1ba4c8a41d042b40c0748eefcf9e56c5e906ad4b12f3653eb','27d11564a346de19820a95a7ebe8f36e0ebf6b43020d49c0a58a99d7b0ba698d','52adf751ddff9b7bfe35c61191ef9460712a7c086cb1424bbe1ff2e0ee6da85e');
INSERT INTO blocks VALUES(310064,'e2db8065a195e85cde9ddb868a17d39893a60fb2b1255aa5f0c88729de7cbf30',310064000,NULL,NULL,'ebc34184623da16251782c82098c7fcfda42f95b155eadfacab2a53e3b34333e','141f397417a65e1a7439237e4461cb7d59c165bbbc0dfa111ee4203e80e1d70f','ade7a4f24e84f133d8f710512136314f9695190aacfbec4819a17b461fe5cff5');
INSERT INTO blocks VALUES(310065,'8a7bc7a77c831ac4fd11b8a9d22d1b6a0661b07cef05c2e600c7fb683b861d2a',310065000,NULL,NULL,'db746a9e0ad8f37c14ef14180dd1bc562ae757a6d4d042a517bb8953f34c6958','93eb147e04cdf05690159490d1d07fcdc1080612bea35ed0681bde03f4710374','81f1c2ffc0424017c5ce6af3127f457933c8a8332b108b8dcb4b622884192335');
INSERT INTO blocks VALUES(310066,'b6959be51eb084747d301f7ccaf9e75f2292c9404633b1532e3692659939430d',310066000,NULL,NULL,'cc71a63314b770e4e010bc7c66d8ab808451b6401e6df8558455a2bfc9bb4882','dd65a2b4b991fe9c1cdff1cf88a797c2cd072cd1796906d5b377fd1184099639','141238bee11ded72e74ade61d7401479a5edce439ed9038799377e4de642344c');
INSERT INTO blocks VALUES(310067,'8b08eae98d7193c9c01863fac6effb9162bda010daeacf9e0347112f233b8577',310067000,NULL,NULL,'a5812c0f3a37b04d5105bca6b0c4819a41beeedf5b0f314f476ab55d6c31235d','0e5a3a52072cac7c2aff1d2eccae5a5aa2ae1c17684644b3951878b4792c55ef','3a7eb5f84bd1d0cb76cd207be6793f9eef2cdace74511600028324104fc6f03c');
INSERT INTO blocks VALUES(310068,'9280e7297ef6313341bc81787a36acfc9af58f83a415afff5e3154f126cf52b5',310068000,NULL,NULL,'14f065751896a2724251b6ca6d0297b344986980075fb72ad058ad0b5bedcd3c','e0690eb90ee184a92352db75894485e9934af17a5090f366fce48c832c5343a0','462f13af3f3a2f828e4dce762c9f7c756deb5e353f77508bd1af7dbd9054374c');
INSERT INTO blocks VALUES(310069,'486351f0655bf594ffaab1980cff17353b640b63e9c27239109addece189a6f7',310069000,NULL,NULL,'a7dd17b4760fb65ac58be1b1653f7cb0e90574c47f70c61ff9f940ad15ad3658','ad364a5a56a09230295b91dfe478fb444900be50d3771e42052d7fa058233ffe','c1af8ed56f2fafc6865e5f814292161721c31d49c85ceb2022a393dbb62cb81f');
INSERT INTO blocks VALUES(310070,'8739e99f4dee8bebf1332f37f49a125348b40b93b74fe35579dd52bfba4fa7e5',310070000,NULL,NULL,'8068a6bcc5d1fc1a78562f0f3165423b45b4674e55f21c4c09948fb65ee632c0','99d3cef0b92802e6189bf03f11d352143def66c7fceb84bee53855c7ca3da2c6','c473fe547a03d0f254898472c99dcf3c7a0888c8c221885429a8aa5c452c8218');
INSERT INTO blocks VALUES(310071,'7a099aa1bba0ead577f1e44f35263a1f115ed6a868c98d4dd71609072ae7f80b',310071000,NULL,NULL,'af86ffad4b8dd68a0f18142935bbb18623cc5ce2e9e0c02f04c0e7a5dd974e17','7f544c1fd412afce3e484c0de94d931cca6c61026e76a4806a48621e7028a211','3b0be95395691f460f1ff83868e9057724913f3f5194d2a6b2dd6f3c4181f846');
INSERT INTO blocks VALUES(310072,'7b17ecedc07552551b8129e068ae67cb176ca766ea3f6df74b597a94e3a7fc8a',310072000,NULL,NULL,'36de48518d1446b33f2230c5eee7d18e040db543fe03dca001174f8382c209ee','b8c8f58dcd0e59d859eaac820a30bba8061d6c061d07a9e1e0cc85eabc6e39f5','f8cb8191b3cdb02d429a6e7ef18c74cbe8bdcafe935b795a68d5bce5cd44db7d');
INSERT INTO blocks VALUES(310073,'ee0fe3cc9b3a48a2746b6090b63b442b97ea6055d48edcf4b2288396764c6943',310073000,NULL,NULL,'4374f567cbc460b73e74d6190db353c3ee86b92c3f99e392beae3caeb264eb5f','77599c315e1ca105d62bfe9e39c16dbb52598ca9f3fdd1ea3a74bc63437fcb6a','bee3b2e93cb3fe7cf12b486af257bf307dc6dd526d0298663ecefbd750a179c6');
INSERT INTO blocks VALUES(310074,'ceab38dfde01f711a187601731ad575d67cfe0b7dbc61dcd4f15baaef72089fb',310074000,NULL,NULL,'54fd95cdf7f9374d1687590f2860276afe67a265ddd9216e5b63fb06c5bd569e','b82178cd1fdcc0c280068452e20ebbe00a57072d23210730ebe17c44e369f4c2','51339528ee20af2355f1f52466eefb6319f7e635a703ba38bba12381f9a06160');
INSERT INTO blocks VALUES(310075,'ef547198c6e36d829f117cfd7077ccde45158e3c545152225fa24dba7a26847b',310075000,NULL,NULL,'2b42e23b43d30f91fe7705a01f0c8ec86d6230815b587704bcc70b91b5ae87b8','cd6db2a1c99275658c7ff094dc5604365aed638687df3e95c104bcdb57ab5508','a56a1c3de6ac2adf00bca4b4ffb03ec1d473a6f92f7ccfe7c83fb786266860b3');
INSERT INTO blocks VALUES(310076,'3b0499c2e8e8f0252c7288d4ecf66efc426ca37aad3524424d14c8bc6f8b0d92',310076000,NULL,NULL,'577092728a4dc81cd9a06fcf6d2b058f0e4ce8bcb395819a704d6b4144f041dc','def8a487cbd3201b24a20526c84bbd726eb9048a781f0c1d50a84b3aa4066c88','e3f72b8b577930ce49d25eda580538b4a6c2d152c1a1f36be4e0467e0a28ff75');
INSERT INTO blocks VALUES(310077,'d2adeefa9024ab3ff2822bc36acf19b6c647cea118cf15b86c6bc00c3322e7dd',310077000,NULL,NULL,'d1ba60181f3061673c64ecd0b92abbc19b1a6e69a927dfefdfd8b8c74171ecd2','ac307b6bd18c2ab88e754f1149b8adc36d9c65c22cde6245416fe869ca8a4c77','af2a3d4f1899df5caec17a1df17ec7250dae6c953820c078ad33eb332a34194c');
INSERT INTO blocks VALUES(310078,'f6c17115ef0efe489c562bcda4615892b4d4b39db0c9791fe193d4922bd82cd6',310078000,NULL,NULL,'c0a9270d15793e68cfd1cf445315d737bed7052914da6def4f014c21f0c9e0c5','958300402b0b290e656ef1d192f494950052e0a5967347a678a2ce052e0dfa0a','f2c87153fefd2ac81627f7583bcdbdc969c5fff9716756c682a2ea81e64cfaab');
INSERT INTO blocks VALUES(310079,'f2fbd2074d804e631db44cb0fb2e1db3fdc367e439c21ffc40d73104c4d7069c',310079000,NULL,NULL,'74eaddecbf5ab6608c1e95c1c313c13f2af2b649512cc8c7016717d21e93f815','5449ccd0837ef3ba42db0fbdbd6eb0e909e936ae5f0180fc9721dced815031d2','60f34ccfce8ed16227fb384076ab00fa6ec46ce841a38f1c0d058f28b28294b8');
INSERT INTO blocks VALUES(310080,'42943b914d9c367000a78b78a544cc4b84b1df838aadde33fe730964a89a3a6c',310080000,NULL,NULL,'a759e3aac1b015e28b8b524106a74b943b215faac8d5079384ec7351b2239bde','a7e99a206b91cbd05f52b80e70a3d25f9d400528548dc062daa76326dee729dd','ec684e5541f63965c0bc7c8ca7493de6369b9ec01139fbd67b055cbd4a46c700');
INSERT INTO blocks VALUES(310081,'6554f9d307976249e7b7e260e08046b3b55d318f8b6af627fed5be3063f123c4',310081000,NULL,NULL,'71622e25e8497db6fa222e33c60ea582698e72ca5789a52c9252bf51191cadaa','06d9af1134ec9318017c4b36541c0698e47706a52b3ac8cf139d5106b9aea462','6d8e59b5b8d9024b139e4fdb65a21d33c781e43255e2a177a13638ce5ff47431');
INSERT INTO blocks VALUES(310082,'4f1ef91b1dcd575f8ac2e66a67715500cbca154bd6f3b8148bb7015a6aa6c644',310082000,NULL,NULL,'47e9d8fbcbafcee2b4c145ce651333ce49812533d13f7f9a0e9a448f51cfbacd','4596faf77635ccc06a9a48b19c870f6b4c7eb085c12ad1c90e6288c69292790a','1f526b2a3fdb9990e8e8bb4eed7a38860092273b9a9e2a3caba7892b291d9721');
INSERT INTO blocks VALUES(310083,'9b1f6fd6ff9b0dc4e37603cfb0625f49067c775b99e12492afd85392d3c8d850',310083000,NULL,NULL,'e61148e7a8125f7225a6b6e1d77786f8b28b0b8a74e60fef3f75fa4de8f7d882','7b2d597a05dbfc8a2378d4b3860bcd6e47d2c34ecd1b744d736107ff82119f7f','62c0d51fecb85b96e70d82a36d88ad08354df86e0e317db48a073f653bb9084a');
INSERT INTO blocks VALUES(310084,'1e0972523e80306441b9f4157f171716199f1428db2e818a7f7817ccdc8859e3',310084000,NULL,NULL,'20fb450589ddc6c904fbb61cca8588e85e865635c12402ce7ae72995ab884c14','09c165ba1df6f27e2aa33cdbfef61b9e8d513ddc762c393cd1e023c114bde106','13c3fa1873eb1a316bf4c21618eeda996690afd969b2a08b346ce77535378253');
INSERT INTO blocks VALUES(310085,'c5b6e9581831e3bc5848cd7630c499bca26d9ece5156d36579bdb72d54817e34',310085000,NULL,NULL,'9cea37d548308505f80dc438d5183bac6c6ca424ea4dd9c85d883b05d67cdc92','d38ba03f0576181a41b01f36b7ea7c8fe47f5676a0e373a19972296fd7a6d05d','447eb776e7b9e6f68caae4d71833ee34e2973f36fe62832cf696db58062b1be3');
INSERT INTO blocks VALUES(310086,'080c1dc55a4ecf4824cf9840602498cfc35b5f84099f50b71b45cb63834c7a78',310086000,NULL,NULL,'e11bab5fba2d038086c65030b90ce1cbc988314d0c9846aa7ddac4fd357bd01a','aa2c6ca24f6f923d7d1aa1926ad32daa1eddc0219d9b2cb47f07946ca11a846a','07d192841a24aa17b731a7bd857a5a31de4095c44e8aaa2c3247808ad8c90453');
INSERT INTO blocks VALUES(310087,'4ec8cb1c38b22904e8087a034a6406b896eff4dd28e7620601c6bddf82e2738c',310087000,NULL,NULL,'777873e7ebd0ec3052be65197ec0db8bd72e46d2053badb0f37be1f6e84ae0b3','c530a6e6879329e456d2ed1880510677a992fa6b85bff5111255083fe022349c','98bb729f97e4a410f62fd74c27f48485c1612ba4a6a24ceb1dfadc6472274431');
INSERT INTO blocks VALUES(310088,'e945c815c433cbddd0bf8e66c5c23b51072483492acda98f5c2c201020a8c5b3',310088000,NULL,NULL,'85a5ea57af33dfddddbcbe1a1c87994efe5a21a645713aa164f19e19bfb23c64','b1cffbb067cea99584f5a56738b3bd9395c4d711fc7dc5c6f4437ae1c63bb281','1cdc13ecd04fe5d131c13e32adc422ddf42a4de84abdc1646986eca62d94a49e');
INSERT INTO blocks VALUES(310089,'0382437f895ef3e7e38bf025fd4f606fd44d4bbd6aea71dbdc4ed11a7cd46f33',310089000,NULL,NULL,'bdf3b6e7a14a3aa22d42a7d69f2f96b0993f1eef2952a7d74313c37e1b407523','062e67330758047334fd9c8c613d05920092d05e5670538099b0be934302dd8d','585fc6ec1e9a9eb2c4abd01f54d0ba25980fc3f090f55f07928a447b7a0c9b73');
INSERT INTO blocks VALUES(310090,'b756db71dc037b5a4582de354a3347371267d31ebda453e152f0a13bb2fae969',310090000,NULL,NULL,'9b3ee688c5786ecc438ec9c843ba5f898fe1ab1a8bc3903ad7789aaf6b0c0bf0','235b64576e3b967880f8aac005fcd36fc003c1b9fcf835640996ad32122e48d6','62771b93f871dab0ae615f8ae7e3fd9869c90573ea9e5cf1fcd4a8e29a5adfee');
INSERT INTO blocks VALUES(310091,'734a9aa485f36399d5efb74f3b9c47f8b5f6fd68c9967f134b14cfe7e2d7583c',310091000,NULL,NULL,'25578ac389a77dbf9589b23c5470f3199016ac66a415540ae03efac29dfe7adc','97275aa317354eb1b6fa888bc56b924c37d3ac3a535c3d18f47a5b90543163d7','87403061ee8a986dc24e7222be8d7291d15bed3c7710ffa129de7bc056d25616');
INSERT INTO blocks VALUES(310092,'56386beb65f9228740d4ad43a1c575645f6daf59e0dd9f22551c59215b5e8c3d',310092000,NULL,NULL,'bb9109ba299c99cb104ebf2ef6e75141c50264d701d27119525ab5d0a54c1a40','97aa90205fadfb0baacd11cdc93e31e514dea4a1508d90c2c20606c8f2b9e995','0f69554296933e89d18d461f7d862c51ad616b76019cf83ae81e7f58b5de73f7');
INSERT INTO blocks VALUES(310093,'a74a2425f2f4be24bb5f715173e6756649e1cbf1b064aeb1ef60e0b94b418ddc',310093000,NULL,NULL,'cdb21362b3eb4fc10ba3c6bf3aba41bfc5bd0bf2475f742c1069cb4383be7b95','bcd7921fe5f2f77023e5f1bd5b434a7d5560ff55845807e5162be1e8baa03fdd','4acfc26bf1d1c9d1a9df67a1d9cf797975a5550e699ac3f25c60ec7d6aebb57c');
INSERT INTO blocks VALUES(310094,'2a8f976f20c4e89ff01071915ac96ee35192d54df3a246bf61fd4a0cccfb5b23',310094000,NULL,NULL,'b82568de09fe4ea06f3dca053dbcbcc61dbe5e44dd300a4301c995ba180f894d','bbde2bcc318cdbd9ddbee930965d55f19c5de3786f02cd08464de99e8ae04a6f','71fb283dc8c1ab106fb33c8eb12bede04df175687df3f692c1a8a6a63816c199');
INSERT INTO blocks VALUES(310095,'bed0fa40c9981223fb40b3be8124ca619edc9dd34d0c907369477ea92e5d2cd2',310095000,NULL,NULL,'513c4a041ee80ba72d1d8428605c682e3485fa45341460bc33fae6540dffb571','599d1575fbc8092435346b6248cb9ff5f7eaa7191a5b7e7ab6141dca8f4b0308','934c137b150bc71080d32d887d28ecdf0b289760e8d22efe9b0976873bfcf40c');
INSERT INTO blocks VALUES(310096,'306aeec3db435fabffdf88c2f26ee83caa4c2426375a33daa2be041dbd27ea2f',310096000,NULL,NULL,'3e8ff43c8d671159355b2d40a995fb8f6d84f6216fa8326fa80ae39aa9d15d03','0992da743701a15c21083b4a43b3948e6e5d725ef7d74de9afc0364cdb9c8311','b3776beccaa152c1ecadfc139933a118f9f6d2abf8db559c190da80730b01488');
INSERT INTO blocks VALUES(310097,'13e8e16e67c7cdcc80d477491e554b43744f90e8e1a9728439a11fab42cefadf',310097000,NULL,NULL,'19d91de7be12136737d3f8990e7a4a793912c952e71e017d723d750118e849c6','850f2592b4656e5a78d35d0c348e202cd522e9e169d7ee9e25ee73cd62239ffb','c0f7b5df1952c0f81a26610fac9a55706433efd6b9658b964b9fd5e4716df6f8');
INSERT INTO blocks VALUES(310098,'ca5bca4b5ec4fa6183e05176abe921cff884c4e20910fab55b603cef48dc3bca',310098000,NULL,NULL,'be75df2e5aff3faaebfc0ce4ab5134790fa728f84500e6989739dddc058738de','3383987b4b952d43378b8745b3007db1618dec50860f75664473ce59533e95c9','289437fcd4dcbc88bfab9e642cf1c93ff586cb96f2f5793e6f2842c001530c6a');
INSERT INTO blocks VALUES(310099,'3c4c2279cd7de0add5ec469648a845875495a7d54ebfb5b012dcc5a197b7992a',310099000,NULL,NULL,'9090b8a4a26ea7dff75658317ce2c6ab828b3b42684922e44debfd1bf8330b8d','5a80614b7f99456dbe0e665f17ea8ca86c4ec4594d693e33b4d30a2daa6c24a5','bb5ee778d08fec5bb38fffd3300c195aa2b161e9f01d2e5779356e23f0bc26ce');
INSERT INTO blocks VALUES(310100,'96925c05b3c7c80c716f5bef68d161c71d044252c766ca0e3f17f255764242cb',310100000,NULL,NULL,'d48d30db433bcee44d87153fb3db17d37fbe3534f23eb16ac853b3420d86d80e','7cd1141ba6bc6bcb3b64cf8fdef91953689837ff6e0f250c4d3fac83de58ab30','b91c543bc2108ad8bf8491db7525c0f44da3a263e1d494cf8de91bc3ac6bedba');
INSERT INTO blocks VALUES(310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,NULL,NULL,'53c6f9247cd255c86a69c05c4463ab94f9a3277496c155398c38dc6f7121fe9b','d4a4a3bc58b5617ce8f74c36186cd84098be7f5ea5956c0a7a503f84c11fe125','538840a683bdf50b2ecaf6f30e2214b03717b9f4eeb4e155307153396d1f3958');
INSERT INTO blocks VALUES(310102,'11e25883fd0479b78ddb1953ef67e3c3d1ffc82bd1f9e918a75c2194f7137f99',310102000,NULL,NULL,'b225c48fb4c40b2e0695991251f6d69217df6e00c01613e0a20f6a3e34f50d5b','b6b704b7d8808306fe22f59748670af1339ee5c720f45289f7833ab8c95dafd3','a812c96e6771d3c2f9ff084986f27b8fd954631201bf89cc28746123e2d9a61d');
INSERT INTO blocks VALUES(310103,'559a208afea6dd27b8bfeb031f1bd8f57182dcab6cf55c4089a6c49fb4744f17',310103000,NULL,NULL,'fc2a8ce8efc122e5cbd631998e611dc8707cfe0b8d3f6a531fe5bcc21c17feae','d49b5142daab5e762ab7cceb64ba8fa0094a00bda1190783943efeed5a3e032d','6691440413a891e1ba7eb5db52a5c1eb1124a3c880ae491e488104cc675aa217');
INSERT INTO blocks VALUES(310104,'55b82e631b61d22a8524981ff3b5e3ab4ad7b732b7d1a06191064334b8f2dfd2',310104000,NULL,NULL,'b1a7115902d371d13889008320e52473cd5b34591bd657e372c0048df020012e','5c7c6d4624b1c022801e2125cc2807ae4e35fb76cabe13128f1c9bb9ab130900','f7be00e6bd9ff6f206db86bf54a8fbf3b214dda4c1ba125a223f7bf81c7e9a73');
INSERT INTO blocks VALUES(310105,'1d72cdf6c4a02a5f973e6eaa53c28e9e13014b4f5bb13f91621a911b27fe936a',310105000,NULL,NULL,'b5fcda12415e713fc81278b95515fe86ecc6beb5810e4f80eb9645f09870dab0','4ef311bf0399c69ab6caa6a26191279233390ebca0aeda224f3d65bad41d875f','c8a768be5d9f53638b248a3d7516cc7182299bfe946633c9339cff1ea2f9453d');
INSERT INTO blocks VALUES(310106,'9d39cbe8c8a5357fc56e5c2f95bf132382ddad14cbc8abd54e549d58248140ff',310106000,NULL,NULL,'f3c98c954cf939951d8b24a257bc6b1bc152a6a0bcf6b580ac281c26bbf16499','ad4ee8cad90e06f0e870f54190ce5ebb0fa0003e2ff1ae96638df15b8e83f0cf','df758b865b88681f629b77d0486a7fd3df51c209d844b6040b29c5ec860f8260');
INSERT INTO blocks VALUES(310107,'51cc04005e49fa49e661946a0e147240b0e5aac174252c96481ab7ddd5487435',310107000,NULL,NULL,'a550df26b8dee075bee82fc59c44ce5cbf65fe9df10c60f3f3009faa2791c783','522776c16dd3cfaacf9ebbb5ab53eefeae34669a4f5e3a492e73f4c889f61ea7','cb18e1f438e18a19f0b87ee2d0b4800504698e0d38c62b4696c0921e337e077c');
INSERT INTO blocks VALUES(310108,'8f2d3861aa42f8e75dc14a23d6046bd89feef0d81996b6e1adc2a2828fbc8b34',310108000,NULL,NULL,'e1d8c345c74760010223a823895471d3ad6a2db5c6a70b13850d5cd977414518','b5e43f0fd63608b598cef91e4c4286810c91dbc2e169b9af4ff2f0c7e351bff1','24730d0f0fdf07f993a9976a201cc161206ce170581249d4e690569f55af411f');
INSERT INTO blocks VALUES(310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,NULL,NULL,'8fb63d8460a222163d15eab76a61e383ffa251a175c16f209648d6782c304059','b269ab7f2184f78faa477d59df5e1906ef185331360ded0beaf3d52a894aa50b','658cd0c9ae6c8c473d1bba16aabfbcde2f7a8baa8133ec8e876434c1c0fe4627');
INSERT INTO blocks VALUES(310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,NULL,NULL,'250f7b5c6f00bf06c9cd4de8dea0b8166e2decf093910ea32eabd615b910e7e6','e924032dcd74c210dbef1f70920cd9e051edbce192dc1275a572b0812bc0da40','67eb906a73fe4685f51b8b9130fc24a56119a63629d30d9ac982b5067840a508');
INSERT INTO blocks VALUES(310111,'fde71b9756d5ba0b6d8b230ee885af01f9c4461a55dbde8678279166a21b20ae',310111000,NULL,NULL,'0c3c3d099bf08803f67c2a77d0d67779674d1063cc72d8794b8fe62a55049d75','fa898712ae9fbb3dd715aea5cf878240e76916e0cb6ef5b41268c801ba7205b5','91901a61341cc566a696deebcf6fd0fa169848ed2d9ffe0cf09158e31630ad7b');
INSERT INTO blocks VALUES(310112,'5b06f69bfdde1083785cf68ebc2211b464839033c30a099d3227b490bf3ab251',310112000,NULL,NULL,'557fdd1240793f8607a2b4c638ce800d5260c2adb294aac95d6c5eab7e98c3a9','45391955f88b32792da83eff41adf3dfab23764ee62b9779608ad6edc2b3b904','b7c5ad524c63a96323bdebe649ccb7b602ed8ce1590b7247dce785f1ac844109');
INSERT INTO blocks VALUES(310113,'63914cf376d3076b697b9234810dfc084ed5a885d5cd188dd5462560da25d5e7',310113000,NULL,NULL,'4ecad4a5c8e9b54101c4a037d6c86a7eb36d3cf0503e60a1bf13c5a4196c5989','a35261b19c18d8f77a9d1f4f9846d431118bc927190db447606014d50bcc42d4','44431c3af93253d9d623f02370cd7e15381966a66b002f2dfea6e4b5478d618f');
INSERT INTO blocks VALUES(310114,'24fc2dded4f811eff58b32cda85d90fb5773e81b9267e9a03c359bc730d82283',310114000,NULL,NULL,'00380ec3118a5e8f9cab403d10870dd5bc339421297fcb6196a3112d70541ecd','e7872836851ab5e8cf77173022ae2660a31ebda9424fecdce81e5efac8573dea','84bfddac655d91b6ea824abd96ee3eb00bd1e1600588b076c3b9b404bd61dbc2');
INSERT INTO blocks VALUES(310115,'a632d67ff5f832fe9c3c675f855f08a4969c6d78c0211e71b2a24fe04be5656a',310115000,NULL,NULL,'0acd3a07c5df54e883ff9871852c961b00771d3f4afccb3b1941d0b1c7b300cc','318e8ffa103b371da240f4ba96973b328833b6a2c9c7d42cb863a22dbbc50cdb','c808d3220defd4d46631274568f0c1bc8539c0ae01ac81e75fa9ec6b1849897a');
INSERT INTO blocks VALUES(310116,'8495ba36b331473c4f3529681a118a4cc4fa4d51cd9b8dccb1f13e5ef841dd84',310116000,NULL,NULL,'6c6845d3be70cbe9a71c33227983f695c96877aac6d3a8d6a6839760b4691d25','5f9ac8c236ad2e50ae576fed8e7622310659687fa70ebf0b84bb1f78cfa256f9','de11d829d2583bbf1a9c1514b814b3f7113b75ad68979b670b924ab3c69abbd9');
INSERT INTO blocks VALUES(310117,'978a3eac44917b82d009332797e2b6fe64c7ce313c0f15bfd9b7bb68e4f35a71',310117000,NULL,NULL,'0465a90ff545d58e69c07c204160360bcc6fba5cc60fb81d7e6e389d9ff8133e','0b2748cbe4ddae7d85979ec51c89db0819a22fa13d044b8232c5b0ab213b1027','fd2a187b8aef7656cc4706a367a3021f5a2f4300cd5f323ee58086c5828176e1');
INSERT INTO blocks VALUES(310118,'02487d8bd4dadabd06a44fdeb67616e6830c3556ec10faad40a42416039f4723',310118000,NULL,NULL,'011ed3df8ae72a02b686e98aa8db07c973e1e12c2ac09891ba90d783ae63161f','bfd758af44d5c72017e86935b71f362425de42cf05336732c669a8dfd807c6d5','89d2fd78a0f78f02905ba109b2f40ee42a330035b7d4d1075effe50f2a2483b6');
INSERT INTO blocks VALUES(310119,'6d6be3478c874c27f5d354c9375884089511b1aaaa3cc3421759d8e3aaeb5481',310119000,NULL,NULL,'a6620b1b6a5b1f54fe6a8076fc35f0f3ce15315e9f549f5ff3fa0f5b6094919f','1a9ef2da2a7196005d377583a9b955d90168e776edca324b58cfbe7c03a77ff5','55affa68f2686d1f0818b74e518f5e0d015dce94ed7aaa8823a2a6cf8be8ca41');
INSERT INTO blocks VALUES(310120,'2bba7fd459ea76fe54d6d7faf437c31af8253438d5685e803c71484c53887deb',310120000,NULL,NULL,'e38e2aa0bf8831b90e69b40c78d4b7d41bc564527451b5f9b332bb0beb54c923','5e658b063c6472e3b856b8c7dcbb1811121191fa091099caad0e567be0f7db40','4b9053d71f591cc32a6ff268422434a63c9042d187a3edaaedb945a3c77f7cd3');
INSERT INTO blocks VALUES(310121,'9b3ea991d6c2fe58906bdc75ba6a2095dcb7f00cfdd6108ac75c938f93c94ee7',310121000,NULL,NULL,'5b988c8ad133bb5ff5ac1ee4ad0a6a4fd431247db373e43c9be2a020520f438b','f4b851c2d73a65b5feb246f043aa3f0bdeaae257d0d27a0a1172684fad06dfea','0ab17a6243830dca769ace434c24f3cd312aa56865552c6f16feccc93ab9e0a7');
INSERT INTO blocks VALUES(310122,'d31b927c46e8f9ba2ccfb02f11a72179e08474bdd1b60dd3dcfd2e91a9ea2932',310122000,NULL,NULL,'70ddab8f1d6283ce5a054650dbcd02d7ad4ca9c35de7bed920c2f266bc092070','6b5cbbee7d063e9c8294d8e618507f1307ec88c44c8a534f3474616f1a7f86c2','3048758b3f532b7875bfcef6244f6a3de9813cbf91a0a469ece13e8387edb20b');
INSERT INTO blocks VALUES(310123,'be6d35019a923fcef1125a27387d27237755c136f4926c5eddbf150402ea2bbd',310123000,NULL,NULL,'3670feebcf979edce175ad5b296a4c88fd7fc6bdc251dda84d487b1b092e41dd','8382f904869541ccc613d0c37bc07ff1f225e73f6388e2d8c025ba4929078a21','89eeb39bf61fab1a073698d9677fdbc59d8ed75cb8637dda85e976455a9b3c51');
INSERT INTO blocks VALUES(310124,'0984b4a908f1a7dac9dcd94da1ee451e367cc6f3216ee8cdee15eae5d0700810',310124000,NULL,NULL,'9883fff318e7cf9021fb4cc39261840f682e8adabb934549dbae2a10d2a71de3','0a1fdcbde438a565897746274c30fb86743a0c597beecd5aa959f1af86c13df5','723f5f8870b596ec48a0e9415547fb586896758ece5ef44e4d88112d18bfee56');
INSERT INTO blocks VALUES(310125,'cc28d39365904b2f91276d09fae040adb1bbbfd4d37d8c329fced276dc52c6a6',310125000,NULL,NULL,'1840685242f9090297d4b432e305e4a093f90faa0b673953b648fbed948f31b6','9c88228602d52a1bb04c9bb621522342820eedaedfba6c29a39bed215c014216','1c144528c8685c6151fad666aa94ad7c02b6694606a716440dbeef8c304b8da5');
INSERT INTO blocks VALUES(310126,'c9d6c2bd3eeb87f3f1033a13de8255a56445341c920a6a0ee2fb030877106797',310126000,NULL,NULL,'1a83f417c18439cd3c6269626c44b480317290f0c27a9b9f883a01653de69272','435d47a767ad68b0cdc5a91564c9430c511ab366bfb76498ae2de8d584938979','f18696a0f12465cf10bd471d71eb9759ccab63362e0c9f76064bad65615cebec');
INSERT INTO blocks VALUES(310127,'c952f369e2b3317725b4b73ba1922b84af881bd59054be94406a5d9bbb106904',310127000,NULL,NULL,'094c53dfd00b5004d074987dba90a6c9c47841d01041d0aeb61923c48315d1bb','cb12cec508b26597b0dfd2d439299292582ce1317b7ae5df56dcb1661a40f5a4','c1760a8f3b592a5b8d0fa5605af2d013dd1dba0fe70147020c160f33f7665f9f');
INSERT INTO blocks VALUES(310128,'990b0d3575caf5909286b9701ece586338067fbd35357fec7d6a54c6a6120079',310128000,NULL,NULL,'28ad1365daaadc866e79b6b1a555fa31bd804a85827d958cebb9d29511f78e19','b879df34179b06d5d57fca45d3c4fb1c3e39d68f5215fdc5a76744afde4b0234','01ffb7ca56b25b49916260dbac140abce1f82625210da34692bf29aff8f3fa61');
INSERT INTO blocks VALUES(310129,'fa8a7d674a9a3e4b40053cf3b819385a71831eec2f119a0f0640c6870ca1dddc',310129000,NULL,NULL,'61587f9b5d05f8f553f0a4f580f38a140edcf7d9facb13c542865f5ec586a32c','3987cd93ad1d32da856cf3803253e3168850a9dd6b96bcb26fb6f30cda617a47','557965938bd005f198c673e1185cd03795d7b5a9cdc117d92811f1574e61b0d5');
INSERT INTO blocks VALUES(310130,'d3046e8e8ab77a67bf0629a3bab0bea4975631d52099d2ddc9c9fa0860522721',310130000,NULL,NULL,'1ee8c39657890ac946e2aac5409147cdbf1b0004db1f00d997cf45452596f781','810834b97ca4f49fd8ec3277efb2497098c650b40aeaa717308bd89c3a38b56a','febf71ea1d0154fb8708c5c6ecc14279ed719a8e1eab532a6e7ba530e75bab0e');
INSERT INTO blocks VALUES(310131,'d6b4357496bc2c42b58a7d1260a3615bfdb86e2ce68cd20914ef3dd3c0cdd34d',310131000,NULL,NULL,'aee45272e68725a2746582f1847582eb9808289d3deca144f8c6cb43bc4f42e6','de537863866e13f0c4a1121db511aabeab46e812615624f6a20b8cc4492a020e','b20de27262950b1200b230872bdcc4e99a3c5b97e1a72175c8185899b770db78');
INSERT INTO blocks VALUES(310132,'1b95a691bf4abf92f0dde901e1152cc5bd87a792d4b42613655e4046a57ab818',310132000,NULL,NULL,'a3fe51c1d168ed726a78b72db61175f2abb07ea6c614b2886f3054cdd1a858fe','f4abed03636a6e02654c5a85bbd3bdad078144aaeb1cf47f5d5fcf501f30730a','ea69b21c76982676fda6e394a9efe90ac98358fcd77ecfc73b47183c95e74d56');
INSERT INTO blocks VALUES(310133,'1029c14051faabf90641371a82f9e2352eaa3d6b1da66737fcf447568ca4ec51',310133000,NULL,NULL,'626743e51b462163f23f22079d672379def21382fd88f9155ddd453ca3d633ef','43c0c7db5097646f2f0f457854b64ac054992dba05b7cc2e77b1a315911b57ab','4ead7ebc302438a3ad7face1afb4acd38bfd3873e5fb2081b187bff817499306');
INSERT INTO blocks VALUES(310134,'1748478069b32162affa59105257d81ef9d78aee27c626e7b24d11beb2831398',310134000,NULL,NULL,'4b6e3202cae46fa80222e3ddec001213062ab76b8848eaaf4ab73f44bd84ac55','c8e45f5599e91de70014039d79220edb0390b660d2ba9cdb92bf5c98f871ddf5','c11cc394775a3445ea51782d5d0ee20698bdbdcbeddb4ccac1c3aa46e6cfd27d');
INSERT INTO blocks VALUES(310135,'d128d3469b1a5f8fb43e64b40f8a394945d1eb2f19ccbac2603f7044a4097e4f',310135000,NULL,NULL,'e32784cedeadac39bb292da2c5eaffc983f416e0bf387978691e4c0fa5b1715a','93a20b7abc783d5f9de9333e9d4c77e7168ec5e11abdc6e9ac22fd69831b337a','ab129a48ae7c497a2ccef37745f532be92f7f8f6343bbd0678d3c0a0086d7351');
INSERT INTO blocks VALUES(310136,'6ec490aaffe2c222a9d6876a18d1c3d385c742ff4c12d1334613a54042a543a5',310136000,NULL,NULL,'93c67fdabd991708d1e35dabbdf7acb4e928763eeb817b32a79cd0bdb414fd2a','7de194549b0ae4fb8f40531bbf9e65f97f9f80c1a3cb4466694c71f6de7c5450','470d19543d1c821993d84d09967ebdc721b63db0bf11434c03d7d0fa761db349');
INSERT INTO blocks VALUES(310137,'7b44f07e233498303a57e5350f366b767809f1a3426d57b1b754dc16aba76900',310137000,NULL,NULL,'8a43d01155ba47b8b1311c41d5a57112198857701c2970d0fd373da04ef4e585','b559e35a3cbeea50f6dddb8a640454a0599c1980a5a97f9d56128b3c53b9cfa2','d358597394eb3415f1faa8bd3d2817fa438d8529f05fd3e219600c256065de5d');
INSERT INTO blocks VALUES(310138,'d2d658ccbf9baa89c32659e8b6c25b640af4b9b2f28f9d40baae840206402ab5',310138000,NULL,NULL,'4acf0244f3188f60152acc8ca30dcaeadf12e6669b15377c81b7e6dc3c8892b6','1480baa79ee762a2a35da94c8f0383045ab4e6612b2a6086e1f4715959ecbadb','f565ffc4bebc00e26efad1c4d00113abcb2cf98b9d71cdc66a093b48ba0b6127');
INSERT INTO blocks VALUES(310139,'b2c6fb61f2ae0b9d75d18fce4c52a53b1d24772b1ad66c51ca51090210527d46',310139000,NULL,NULL,'2d77bdd47ed1b3be1c2edf41473bd5eb707d06dab33717b01c4a227f9855d73d','f763ad1db75d500b537caa15673f5eb2efdc0be8df4ad829258e74aecefb15ef','86a1d3b63a03f1643ddd73016b917e27b481e56a70f1bdd80cf101f59cffcb03');
INSERT INTO blocks VALUES(310140,'edddddea90e07a466298219fd7f5a88975f1213289f7c434ed47152af6b68ebb',310140000,NULL,NULL,'277c0c6dd1c505dc6f9a222c737296396569d8e007c4b9a42582f108e90fa624','5f0653467964727ef918764ac36306294b6529bf26165844ea79f04b9a2edf92','6a0c5512b9718a3179333158f3fe08602b3a837e98640a9f0f2f77e9054696eb');
INSERT INTO blocks VALUES(310141,'b5b71d2a271bd638561c56f4ffbe94d6086debaaa86bfeb02ef0d71339310709',310141000,NULL,NULL,'f5d0edff3f22b2e025c884b7c738abe641bca9110a6b9a7b90de179fd6e5d2dc','30538a35119232e64d3111cc111fc5bae67d00cee391d4d25408c1616119e4d1','7266d36f6b54f0531625847eb86e0a034cb8fb6c58a505c6b8986ae202effe5a');
INSERT INTO blocks VALUES(310142,'a98ae174c41ab8fc575d9c8d53d8e02d8e446b8c6c0d98a20ff234eba082b143',310142000,NULL,NULL,'a9f00ec826a30e66820ab2920cf9573244a24dacd63d48c080b9e80b1c5e05b7','97379ccc6f282d41500ca0be20d2652381b22b4aa0c5f6cf8b2790caa136f0ed','407ca564a6e51fa4aaf400e22f0aaebd7d2947dc6d6d758738478d7861bba773');
INSERT INTO blocks VALUES(310143,'8ba2f7feb302a5f9ec3e8c7fc718b02379df4698f6387d00858005b8f01e062f',310143000,NULL,NULL,'b5765899f770fdb6cf1120535d85826c6b0ae44b16b8d5a619c5cd12c98783ea','f8b5efa1f407f080e317c9f90e350b928b5d16da84e37d73bc2d598b42a9c411','c1d5e0d39c399504b52bc778c1fae7b7a0a95393689b2bd7e7415464ac4cc99e');
INSERT INTO blocks VALUES(310144,'879ffa05ae6b24b236591c1f1537909179ed1245a27c5fdadd2218ab2193cdb9',310144000,NULL,NULL,'1a80f48136e5938b33f817a7cc1cb60aaf6d628b7811abd43e38cc807a18072a','b2f5c8d49af0e61a6bda659d04927826bc328e1d88b1e2916b27eaaad9890bfe','97ff358a31758c0a4abd24df10b6ff2bbe8718fb6f57d94a9a4f446ad8558875');
INSERT INTO blocks VALUES(310145,'175449ef0aa4580593ad4a7d0c5a9b117e1549ea772af00caa4ccdc9b1bf7a6e',310145000,NULL,NULL,'fce2f084c1776fcb36b3ae3e0c952893934e24672ffa0d3dac72bb1278af8264','5dd43c069b3679478cc0d222b63b78fc0d8da458539f987f490a7ca7788ef1b2','42a492aefc7e8104727d3d7f2ae8fef53e24965665116eecf371c41416b796f9');
INSERT INTO blocks VALUES(310146,'e954ab6a110455d745503f7cc8df9d92c1a800fafdd151e7b1912830a9cb7184',310146000,NULL,NULL,'9a98eb971580a0a69fceafc5fd41f398f1908b626c47df57965d1863e9a24b84','defc57ed3eb0ab616c15c7e751941e3542b3601525e0993b13790901e869567b','e2dd9dac449f7f1d640b83a58f24cabdb0471bce6e8da2e4adb9fcbedaa36625');
INSERT INTO blocks VALUES(310147,'7650c95eba7bf1cad81575ed12f32a8cc36281a6f41bef13afe1dfc1b03a7e83',310147000,NULL,NULL,'336a89d3d137810d3220d2de432f72e3b3ccd2ada2b746da3859c77dbb89d6a3','3fbebe305a04523bc0f7f1fdc4e2826ed26d8d0feecb3b92786a4b10d9d2e721','27a463b5c2de0015edaee7139d7a3d482a49575893f932ed3b791e1f4be2f5b6');
INSERT INTO blocks VALUES(310148,'77c29785877724be924f965215eb50ffe916e3b6b3a2beaea3e3ae4796545a7e',310148000,NULL,NULL,'f904794337dd67d356981d2623b8c3d1d78ba584cd98a8c1db939951d3102612','141bb957e0fd1c92c24f3f4c4c0fde9be26a992a60f54751e3d8f9dc4bd46a57','b78d311e3127bc9ea3740e6bc0b15db59e86f0081f796b973f625574318f63bf');
INSERT INTO blocks VALUES(310149,'526b3c4a74c2663fc04ed5234c86974bffddb7235c8736d76860778c30207b3c',310149000,NULL,NULL,'c2972fbd048790f54d9ecef4e18aedec8ae7aa28227d1d43bd19cd71b4feff85','436ff07ff0b8ea64e9a995495f3b1d20f981541c759db5eb42680a15c3bc991c','7e246fcc6c6340675574cbc73155db5a3b950788998877bc245e03ebe40df7c4');
INSERT INTO blocks VALUES(310150,'cdd141f7463967dbeb78bf69dc1cd8e12489f58c4ea0a5dc9c5c01ec4fcea333',310150000,NULL,NULL,'88b999e4ae34386b826b0f3b315953b5eeda8d9ef496af051498bfce6d8737fc','500016b56d567e3e390b35a79da139fe191b70bd058166c199480d8655c2e50b','5b68af3b0b65fed25be659439db39f739b53050d9fe3f3733dc59a9a6fc761b5');
INSERT INTO blocks VALUES(310151,'a0f31cc6e12ec86e65e999e806ab3bfa18f4f1084e4aeb4fbd699b4fe284b330',310151000,NULL,NULL,'b7c176a2eff86655f8b0b71cc8bd3bab3a92ba203d4ccd911d63f3d2ce7fdc25','c6c7630fae99cc5185289ad75c2fd9aa35bfd9abddc20e09c1e4cad5217bc875','c9e504e1b1329cb461df14de5db307326716a1c3f600552cdf6020fd96e19eb6');
INSERT INTO blocks VALUES(310152,'89c8cc3a0938c63a35e89d039aa84318a0fc4e13afac6beb849ac37140132c67',310152000,NULL,NULL,'3f9471c393bc2bf144b17a5febea88c42982ae746fd700a5903c0e6e541e2b09','0201fa6b307da1b0f4bce4369d7505452b949a6473372d43f85599bd09967bd4','38b5a07df78ae87312fd7c797489ab93aa14eb68e20c4488b1b4e19467930efa');
INSERT INTO blocks VALUES(310153,'d1121dfa68f4a1de4f97c123d2d2a41a102971a44b34927a78cd539ad8dca482',310153000,NULL,NULL,'c6bc81e7b7e6758bbbfe10fa0e688b09e679fb74a18134639e172c18c6e017a7','b530e6e2230bbc560837e3414106dd0c422495011195abb06413b1705f45c4b5','cf0c0bf88c3d73653f853ed73a86f50ff7b57e7425969350599a64ccc620fde8');
INSERT INTO blocks VALUES(310154,'ba982ea2e99d3bc5f574897c85485f89430ae38cf4ab49b7716ed466afa506d6',310154000,NULL,NULL,'b3e07f9de85ab67e88042b1bb52302c6eb16b7ff45d5be6a49700f115ed396d4','479147f9cc032a8feed31dded0fb855f006e973a419ac954164f28f277ea08bd','c49d3ba7db3c0291afbd3e93ff58a00469ca57f60aba6d95657193e321c14a3a');
INSERT INTO blocks VALUES(310155,'cefb3b87c7b75a0eb8f062a0cde8e1073774ae035d176e9769fc87071c12d137',310155000,NULL,NULL,'27014841a468e23bcb70c718919745eadcded4310031a7be90a4732c96509404','2ed22dff71e6cc2cc9845016a2bca1df689894b2daa16ea3bb1bc2d7a7b3c3af','24669b815b51b7343cd547fc40dea1c96af4aa149f968a95d10f1cc356b2af6b');
INSERT INTO blocks VALUES(310156,'6e3811e65cb02434f9fde0445a7a2b03fe796041458737d0afcc52208f988a83',310156000,NULL,NULL,'5597aaadb8cc75848219f9fde3f5d76bb5592689c72068db59922732e89eef9d','2d9eb317476c21cd0fda69ca362527f596a5bad425d8e0f60f082958a605ddcb','6a81d8f1cb56c597601042c714f73bc80ece534eb1150297ecd839c0a058939e');
INSERT INTO blocks VALUES(310157,'51dd192502fe797c55287b04c403cc63c087020a01c974a565dd4038db82f94a',310157000,NULL,NULL,'cc1ae27fef286424e40204f6b575e9e079e1f7a5ccf6cc356729a7c4a7f83eb8','4e10358b8227f836d59f653b63c063865382c134de5ffadb8f161e7b9a49aa70','8c61bbb73a23b900ba583fc45a1b80ef29c5c61d6a527e46903103b7f9ea349b');
INSERT INTO blocks VALUES(310158,'749395af0c3221b8652d31b4c4410c19b10404d941c7e78d765b865f853559d2',310158000,NULL,NULL,'6d80d98e778b30c124b0255b3e72620f432245d0f841f6bd62a0fcff44843bf0','e9fdd043b03b5a7c2c6e4f2a3b07e6e838cbef8eb478d280585c75bae234663c','f7d699d1a8bdd2685dc8e56e0aaabc21d9054840a6bc46d6af32abb1fc0aa3b0');
INSERT INTO blocks VALUES(310159,'fc0e9f7b6ae99080bc41625588cef73b59c8a9f7a21d7f9f1bf96192ba631c12',310159000,NULL,NULL,'d8ab8bb14092afea6cc675d2f50891318e3169bf9dbe2d07e80c4db95f0f2033','949f3653f01823c884b3766218b3c4925a2de82a9b779eaf3f42b1a7c067f3f1','f65d63ba42bc3f9b65059523a4d0fc494eb57e7213307bebbd9624e1ec0c319e');
INSERT INTO blocks VALUES(310160,'163a82beeba44b4cb83a31764047880455a94a03e859dc050da782ed89c5fa8b',310160000,NULL,NULL,'2d76a042d062b73b7dd956d5cff0ee397f068c04eae6cf5b9522d3d55e88cee9','b6c4caf9e555eebc949973b8ff57b4a76c82df80fa629d81a55940e600bb0d47','573526400b31a2abdf2b30e0fdbce22de279fe25fa1a0ca6cf13188fe156acd4');
INSERT INTO blocks VALUES(310161,'609c983d412a23c693e666abdea3f672e256674bf9ee55df89b5d9777c9264d8',310161000,NULL,NULL,'beb3496742415027bcc0d59f3385809523c8783cd91a5670f2fb6fec3230e980','94d68a46c5fa37a73a12bc8ced0f4feacfbc4b7d0dee89ac1c1a4c3930b8f15c','08214a79d4322613fd88fd3b6633df17a89d41dbdd52cada651895a63dbd0205');
INSERT INTO blocks VALUES(310162,'043e9645e019f0b6a019d54c5fef5eebee8ce2da1273a21283c517da126fc804',310162000,NULL,NULL,'066a2b93df863300741145cd6a4f1a9ea616bc787861cb8ab809f59d47a6fa1f','351410f927236cf5b2865ecea49da0126292a6ba5b20af530c81f51cffc2eb93','2caddaf6a9d60161b6a92faaf08a207d25d96dc277e6c592482c5aea9ac745fd');
INSERT INTO blocks VALUES(310163,'959e0a858a81922d2edf84d1fbb49d7c7e897a8f49f70bd5b066744b77836353',310163000,NULL,NULL,'460c271269ccdd8775925b511705207baed8fc212caa7e74fc08a80be600a38a','002f643b213c0220b96dedad350c3543e1fadab767c42129638f224dbac21377','bc61ac43d4dba63a3d271263e1098f24bcb3cfc6075b5ddd4d9579c92a62b804');
INSERT INTO blocks VALUES(310164,'781b7188be61c98d864d75954cf412b2a181364cc1046de45266ccc8cdb730e2',310164000,NULL,NULL,'19a7948cd1bc4a89a427d48bb01330dadff848e2b32ec8b8abe342872850b268','b4791dc92d2e1a4d3449fc8969e3fc0023a1756c3d66e53b6fe3c260f8e11688','08d660717f33a2576e59f62d86d986ac4d79c0e9b74adbd2450bf4ab276e2f30');
INSERT INTO blocks VALUES(310165,'a75081e4143fa95d4aa29618fea17fc3fabd85e84059cc45c96a73473fc32599',310165000,NULL,NULL,'97f0a48a26daf011a8c7b22bb772228a0c8a920eccd011e713956100c9fbdf33','8b3a0027231476cc9440104a4fd10752d3604b6d55e0ed21738adced671c5a76','6d9c5edc730287cc53b4137ec8a82b6521a67f60f5b5151a2798b982fcc871f0');
INSERT INTO blocks VALUES(310166,'a440d426adaa83fa9bb7e3d4a04b4fa06e896fc2813f5966941f1ad1f28cfb41',310166000,NULL,NULL,'edbd00e1229c673f4f15b3ac7bbe020f54b5f3a61b1d158658471076a55c77b0','574d031910827ce07f28a2b77b81a6d9b287b7da72d24562ffc10dc82ef09d9f','318a31cbf3d787455f0d6953e203f21697554938c1725eb60d4ecdcb1d4d3de7');
INSERT INTO blocks VALUES(310167,'ab4293dbea81fedacca1a0d5230fe85a230afc9490d895aa6963acc216125f66',310167000,NULL,NULL,'e118e0f3aad5be73080f4d1892517e8fd2c4575589ccdfadf980edebb9a66a14','a3b10a69f38f49727182f1332d0a4bb1a2294d4e3c54d77bb4abbfe4a05f2638','24b095184c4e1bd0753aefe0fe5b941e8f86f2979351cc77882031db14db1eb0');
INSERT INTO blocks VALUES(310168,'a12b36a88c2b0ed41f1419a29cc118fae4ecd2f70003de77848bf4a9b2b72dc9',310168000,NULL,NULL,'267f48eb4e3b0925f4f472d8ce6ec57ec5039911b13a14ff2884a41a9cafd7b1','6f507172591873708e6d54cc27b1da4ea2cb0eff5704ea7fb7ae64874c62b7c5','c51b8aecb3ee9a5f0174366c1ab0212c89ad0297da40f1abeabac91636d723b1');
INSERT INTO blocks VALUES(310169,'204809a85ead8ba63f981fc1db8ae95afe92015f003eaebbec166021867421f3',310169000,NULL,NULL,'df394a6f3b2a9b9dded6019dce9f3d3214db1f30019faffbdc2ce614f629b25a','da13ec728e66ccdcf8d231793e06b03149d78241e6a793586048d315f5413ed2','94b52d720b88f4bd797ffb613778392ed83a86897b3c679910ba7ddc7cfd4dc2');
INSERT INTO blocks VALUES(310170,'b38b0345a20a367dfe854e455e5752f63ac2d9be8de33eab264a29e87f94d119',310170000,NULL,NULL,'3081081c2ab6d8280ef721c5836d0fb7e89eb3d747a4e4522d2e22f5a6b153a2','de211a4ab13a2d6c2d27bca9de1cb3292f40d1fc651251a97282e6a40263e8d0','9d7f545205dd609c7d75a3b557033c9d5635b327415e8ad4cbfac5a929fac22a');
INSERT INTO blocks VALUES(310171,'b8ba5ae8d97900ce37dd451e8c6d8b3a0e2664bb1c103bf697355bf3b1de2d2d',310171000,NULL,NULL,'e6a4017e4f7d9da50bb3817990c3e115d5035443de8824dc01b5380a5b4c52a9','d6d52a373eb442f4610e31de57b2b390a38d6b6559ce00a5ed8d372c9bf949ce','bc76a85c322d3a97c33226c694fcb27687f3e539372b55c532c2e241a1ce7a67');
INSERT INTO blocks VALUES(310172,'b17fda199c609ab4cc2d85194dd53fa51ba960212f3964a9d2fe2cfe0bb57055',310172000,NULL,NULL,'89e90622bf8363bcee5cd7ab6d48b6d06ce4cbd067f9985e35e67fc683f4c103','7b80d1bf6daf82e1d248ed06a7d72f7b23bac25ee8702d6c2b41442a2e430c62','ddfb744c300a9176b5805397ea230893906b35db10e0c0f533d30f23477562df');
INSERT INTO blocks VALUES(310173,'f2dcdc5ffc0aca2e71e6e0466391b388870229398a1f3c57dec646b806a65016',310173000,NULL,NULL,'35ceee6a23757fa49e7f5c34ccf0fd034731e95d564257b443ebfdee7cd294d3','9001d513d309bd76dd6fbbb16aae07a3e01320c5a5bb2cd35a34565393ee5f6c','fad2a392eedd4a804cbdbf6cdbc5b6f289e8021f9c9b6cb9d911257ff60fa5ca');
INSERT INTO blocks VALUES(310174,'fa6f46af9e3664353a473f6fffce56fa295e07985018bface8141b4bf7924679',310174000,NULL,NULL,'101dedf34bc0788c0589c8e2b1d7da4ec65f6eab2e3c5523c0903db685cab017','984b2fd92f7c68764c89e0bc9d9d751a7cca983b6af916cdefbc0f06f85fbecd','b386b1d044d1c914973bd30f1a07e0e3f9849716b247b0efc979e98ce19ea101');
INSERT INTO blocks VALUES(310175,'f71e79fe5f03c3bc7f1360febc5d8f79fc2768ce0ff1872cf27a829b49017333',310175000,NULL,NULL,'67de4a0a9e52d9ae06caf62b3412d0bf2c10a6b24716210b21212d75be75ad6c','10c01e007998ddf26943d30490efecce6f6934057b7917eee99681e9a2d0159c','ac772cf088924de619b4cce5a0012a520749c8c35fb3f2f0d938146bc05eb6a3');
INSERT INTO blocks VALUES(310176,'67cd1d81f2998f615602346065e37f9ceb8916abb74b5762ead317d5e26453c6',310176000,NULL,NULL,'a90bd400e15727fada1a27be4a6e228bd91a15f0dbd0fb7de3b6779a8bf89e4c','aee829918fb61922903deae5d15744fa5af9f0556416fb0930a9cd1eed1dc008','b91a65f9cb67e1921bb07a4bab39123af7cbd03e3689f536ff0e35c0a33e5859');
INSERT INTO blocks VALUES(310177,'6856b1971121b91c907aaf7aed286648a6074f0bd1f66bd55da2b03116192a52',310177000,NULL,NULL,'bac315d07dee18e27336a46ff3ffeed58aaf8eb1eb702e98a93c06303c937716','a4d3e311a16d7f6be2c4e274ac6a3ad6e33e7d3804a77398e33cd461469507c5','e438afee02fea83d72bf1445ab44c3e279a4886f9b4d8f5e3bdd1bab51d53c6c');
INSERT INTO blocks VALUES(310178,'8094fdc6e549c4fab18c62e4a9be5583990c4167721a7e72f46eaf1e4e04d816',310178000,NULL,NULL,'186ea0ece84d21ee21889ff13c98959dfc1842063a970e0c095552f0ca86515e','cf3ce5e8cbcecd217998ead345f9f2261cf000108feb5f616a0a7a271de16568','5c3234da243ebec92b119161205b5c5abe681e2cb94741d4d18b9ef2325db913');
INSERT INTO blocks VALUES(310179,'d1528027cd25a1530cdc32c4eaff3751a851c947ddc748d99a7d3026a5e581a7',310179000,NULL,NULL,'0200402ef08256efa0adc85b2b4b15fb7448b5107b65fafbcc7985d809e84bc8','873a1fe73da9a361514b59c76a86aa87a9f959018e5ac83b340110a250081d44','e7ed34924d0324b5713a2dd47cdb24b2bfc4decf512af848508fee7a7af0ccf0');
INSERT INTO blocks VALUES(310180,'f2f401a5e3141a8387aaf9799e8fef92eb0fc68370dae1e27622893406d685c1',310180000,NULL,NULL,'13829eeaf9bdc54f87366e35616c5a57cd836c63db8a9ba7d117d02377ef43e1','5ddd1db1a24c2eb82a6afddad27efb4619c1706336c64214a02345a0abd6d681','d1602a0b2abf3311aedfc89941919378c9ace69f73bc051c59f7fbbc78bba95c');
INSERT INTO blocks VALUES(310181,'bd59318cdba0e511487d1e4e093b146b0f362c875d35ab5251592b3d9fed7145',310181000,NULL,NULL,'81b4d83a623a55019ad720c1bd3ecef100d8ca49deda91b8ba6ffe9802764df7','e9ccef6699a7b7d1190c193629cd03700c258eaa3ae3208815d43555cf1b6df6','f9c58932426eae89b4fd92680ff0f989bea8868b3ab55b6b57a8cb3a4b9f81fc');
INSERT INTO blocks VALUES(310182,'a7e66b4671a11af2743889a10b19d4af09ec873e2b8eb36949d710d22e1d768f',310182000,NULL,NULL,'935e40f93195d450b292481aac481f445d2de8786d04d26263f4adc5a348704c','4920c2e2b69e3c262bb91967d4560f736caa2daff8b9809b7e46576fd470c698','8bd59b6afd2b1d1e0dc363d58a532127d89028c8d7283bb24363cce9f6d8926c');
INSERT INTO blocks VALUES(310183,'85318afb50dc77cf9edfef4d6192f7203415e93be43f19b15ca53e170b0477bb',310183000,NULL,NULL,'268bf841be40615472bf4c60b5306d0763ed50510fbb55c47a6a0ac726e8701f','6b438193f6e0e8f80a02e21dc97729ec8c8be43b7da35f6156c090a45c03f255','9d4974047a3c002c0bb58460db642ec7f4303f4f8346f1913b8a7e3b25c75613');
INSERT INTO blocks VALUES(310184,'042a898e29c2ebf0fdbb4156d29d9ba1a5935e7ed707928cb21824c76dd53bfc',310184000,NULL,NULL,'64323488ca4d32a1f548842db4ac772b750599ce6222020ef6149b4a0e54a935','33da0c618ab805d9f75bb94fc515fff2ec6e251f20f932a7f9f8d135652bd78a','c2638b9a7368cb881abfb2d617fd66c70f3c8d6ceb34930480f16ca1485f0efe');
INSERT INTO blocks VALUES(310185,'bd78c092ae353c78798482830c007aac1be07e9bc8e52855f620a3d48f46811f',310185000,NULL,NULL,'8946baadef2e19c5e4e4b2d771b36982a217486dcb0f95097b41ce633e61da94','14da352d882e4d8160f559d25f2e116a5108c9ea71dea3cbcf0429e206f4f5dd','24b6cf6824bed0b61c1f5c80c745cdc99b14c05c2ec457fc8aeac9abb37cdd34');
INSERT INTO blocks VALUES(310186,'e30a3a92cc2e5ad0133e5cee1f789a1a28bea620974f9ab8fa663da53e5bf707',310186000,NULL,NULL,'e68b5525927cfee15fefee02a16fd700abf6b6e7b4e32e57df7d324fae7ae090','7c8cdf18d10a5820a9d483088537583cf21aab343a6a509ed3f7f97894340f54','9e01de6844e5a97652d461fa585ad8b099743ea56142d7bfaea7810524e993b8');
INSERT INTO blocks VALUES(310187,'fc6402c86b66b6e953d23ed33d149faa0988fa90aa9f7434e2863e33da2f3414',310187000,NULL,NULL,'c42efa24d48339fc341908a30c6679beeadc9f5918d8d3e62d5c4b06fec845d5','9a97230084e48d40ed0357ef736b762afd33ed633e8f8536c5e5f3c3a59b6f3a','d7bc69b10107d865d050ed3e0f0eba1799cf640b44206debcaa3fa7eeefbab6f');
INSERT INTO blocks VALUES(310188,'85694a80e534a53d921b5d2c6b789b747aa73bf5556b91eeed2df148e2ada917',310188000,NULL,NULL,'13de1d9b569d5d2525ecfa39b1eda69f9fd474683b6e34554b1a755125e96e5d','164132cf7ae5a96592dcac3475a6b07d05f18f5609893df099cfb632eaa3dafb','719a19c2475de284883113a18eb3661d5b3b272b53fc7b6d0a6342bb4e2e04c1');
INSERT INTO blocks VALUES(310189,'7c036dadf19348348edbe0abe84861f03370415ed2fec991b9374dbb0ca19a06',310189000,NULL,NULL,'582b8b3d3a226d3f6df497cb933ed5f42e1e992c0c25372ec15de424c0a33368','201d4ba71fdabc30043b98323aaf22c1d0f906a45f4db30cf479b4ca96e9ebf3','4c62c83c5161eaf347efc32986fe98d76b1823daf18cff060ee4532d773810cf');
INSERT INTO blocks VALUES(310190,'d6ef65299fb9dfc165284015ff2b23804ffef0b5c8baf6e5fa631211a2edbd8d',310190000,NULL,NULL,'d4c49d5e3aaf21e6fe1c30663d0ba93f7dc9ddb03611e3751fba9aac8d382ac4','07bb09fb4785945a839d76f760f4ec91cc38472a3cc411d5989b028775bdd896','93d35f6130c25f3c8e5445c1fd6bc904685cc415e1f59f921805ffa620f98ab7');
INSERT INTO blocks VALUES(310191,'5987ffecb8d4a70887a7ce2b7acb9a326f176cca3ccf270f6040219590329139',310191000,NULL,NULL,'23d340ff3f1979a43bd1336c9c882b5ee01c646cd104060feacdb5db78025cca','64dff234fbd2bf2bc1197d33d2473dd4ecbeedbe867817c46ed84cdd5dec8772','38ce6f67325382998c3a3f36e8cf5efd2ff7db023767630b0ffcbb5b019dab60');
INSERT INTO blocks VALUES(310192,'31b7be43784f8cc2ce7bc982d29a48ff93ef95ba18f82380881c901c50cd0caa',310192000,NULL,NULL,'cd18860851bceba4a0174480ccdc0f6ddc47b31ce71af8ec8500cb07f75d9da9','ce4f27443f650dde2151ecf40b9f589d5adbe03847665cd6b8ebf70f2115e32f','2e8d46af5e1689d432e42ef1762f2f567fee9a2499eb57c43a1556e39f2c22c2');
INSERT INTO blocks VALUES(310193,'ff3bb9c107f3a6e138440dee2d60c65e342dfbf216e1872c7cdb45f2a4d8852a',310193000,NULL,NULL,'391e97ae7ccf5bc38ac72e7ad1256f24c28297c625bd9a789cba8231a5ade046','dca92f638e56a80ff6c1d26ef12b32d9173cf329035a7f186dfe2fb7077fbafa','432dd65254e324b83fdf14e38754da1c18615078c94c4073c309a52a4d02595a');
INSERT INTO blocks VALUES(310194,'d1d8f8c242a06005f59d3c4f85983f1fa5d5edcc65eb48e7b75ed7165558434a',310194000,NULL,NULL,'9141c9b38087c7cf2b8c11ffd55c2eabcb3bb09f132ac0baf9c3779f628dd42b','ec18d353da7442a1a21f14a84c039ba9012f20c387eb2062be7ea51dbcc77325','de479d236080bbaf81e9ed643e6b7af75d359f47726015280002594b5e2a03fe');
INSERT INTO blocks VALUES(310195,'0b2f1f57c9a7546faac835cbe43243473fa6533b6e4d8bf8d13b8e3c710faf53',310195000,NULL,NULL,'705918f002db29e7b3dfbfd6378f79d53e33c6ffa3948b2e3b5c85f85009bbde','c484c1dd8c757584cf8598674d538749d9401469ee159516da1d11bf40ed2003','7f19b93104d3f54830a5a6836d979e6065720ecff22ab135be13943caed3da88');
INSERT INTO blocks VALUES(310196,'280e7f4c9d1457e116b27f6fc2b806d3787002fe285826e468e07f4a0e3bd2e6',310196000,NULL,NULL,'59e12df19e3c0e3e23a5d1e9783c75e236a000774a038553312919a0f46b8227','3867367bb4e3e14fbf54984c7a7bab856e30d405b6bfbe8cf70fb186f21f40b8','b29df2ed5e9f529bd103b69ae72e6b3daf02463f55ced14c9694ed154643ff5e');
INSERT INTO blocks VALUES(310197,'68de4c7fd020395a407ef59ea267412bbd2f19b0a654f09c0dafbc7c9ada4467',310197000,NULL,NULL,'a0e1817dfc258180fa1629710ff3b6026181a9042fecd2c8b0b5e38118199e07','7cbdf23ab7b3150414a7368cc69d7c320f9d776194f4b27ac79ad841a20ddfe7','792d1ae3752ebd842306fe59ab720f9dd7fc8c4a964526d8e27da348112dce56');
INSERT INTO blocks VALUES(310198,'30340d4b655879e82543773117d72017a546630ceac29f591d514f37dd5b1cc2',310198000,NULL,NULL,'ff51bfc670b1387bfce53781750e35a3bf69d907167cf9cf57e15613cc0ff3b2','9ec60827000d1f89af4e7abe4ae85f4d67f19bf7d473a37c3a3967dd78b59966','c5950be29b5cc2e224866ce5bdff975aaacdaf6f9c710b5db3cd3d089e7f0949');
INSERT INTO blocks VALUES(310199,'494ebe4ce57d53dc0f51e1281f7e335c7315a6a064e982c3852b7179052a4613',310199000,NULL,NULL,'e5f8f8f00de32f0d8d2b62eba27218edcee77563960fe074da5ae86bf5b553f1','87198286a6e8001945168c1d572f5d7f0045b1e6504e5d437b5f207013063244','902425d3c14bd7ad9f22383869a89547080211c3bdc8b60d3abacfbcce8b8df6');
INSERT INTO blocks VALUES(310200,'d5169d7b23c44e02a5322e91039ccc7959b558608cf164328cd63dbaf9c81a03',310200000,NULL,NULL,'fd8fb664576868d4f1c843b28efc7ee028417034a33d6f5635238bd13c701b2a','5724c2f2fff609e86b038c9495200de26c8de6b6ba40048302636f5988831780','dea389a097fc32e1e5b8a57e7f7683b9fc1a0cc385265bcd808e4e4866432257');
INSERT INTO blocks VALUES(310201,'8842bf23ded504bb28765128c0097e1de47d135f01c5cf47680b3bcf5720ad95',310201000,NULL,NULL,'7e2dbbf14c0620ac0fd4e0e676857e2d055fff80cadfe2d9d0dfe07d36738722','e1f55ef715561eeccc47a679862a913da0aa02c3fcbe26a25d1fa4a5e348429b','aee6b86d654c16e48b7b80a3bf020c15028cc2032a267e1b5949ff0c0e322aa1');
INSERT INTO blocks VALUES(310202,'95fa18eecbc0905377a70b3ccd48636528d5131ccfa0126ed4639bc60d0003d8',310202000,NULL,NULL,'084c24e81842ec8edc4144ad64df9f12377318fe4dc491b307b7d377f3f81b2b','220e36428b8ee1694cd624fe50547a5c076efe3bf54cb1c7c79d09a842131918','69f98485b630517132b7a0e2e2eb044050f9abe94dcaa250ae520a260cb63266');
INSERT INTO blocks VALUES(310203,'ab15c43e5ac0b9d4bd7da5a14b8030b55b83d5d1855d9174364adbebf42432f8',310203000,NULL,NULL,'4b0b8d82a5a2c8600a09b1050eed4440d9e0f2d817498f3e32ba27ebcfbaf6d5','767e5320638735019fe5dac03eb40f9605fde10411c471df1be6334d65e54878','e934a4b378764b2c9c22511f43a10a2b8f076571ede2247d6afe5f705bbbda0e');
INSERT INTO blocks VALUES(310204,'18996fb47d68e7f4ae140dc1eb80df3e5aba513a344a949fd7c3b4f7cd4d64cb',310204000,NULL,NULL,'9f81657142f7523c01595bef4e9008d8525c2337f6d90140e05abad619d94416','6d1a2e09cbe70126210c02a5a06cebd67f2a2cd385325d99253857adec3eb877','c301c5defaebf67273cea2192a0d9d32d6156aa004bc4199ae353bd8b9bb1976');
INSERT INTO blocks VALUES(310205,'5363526ff34a35e018d1a18544ad865352a9abf4c801c50aa55742e71630c13a',310205000,NULL,NULL,'fd1cdea0193ed914cc408968efa42377d7c69453aa9bdf8bdf0731d4b1501b01','72d600c25d5eb86460869e9cf525aa23f16ba1c5d1a4ee837fd60e345432938f','15b29258535972b1d12c0986d64aee4dcefd847b59321bd1cee03d6893bc254e');
INSERT INTO blocks VALUES(310206,'0615d9fca5bdf694dca2b255fb9e9256f316aa6b8a9fc700aa63e769189b0518',310206000,NULL,NULL,'5845d6bedf81fba710999bf2954b3c1f3f9ca007a09d812ccae8e2a6d3b9bb07','bc670df0c9458698b1af4a08913675070b6a1ae1cbebe507bcd5b02b3f2b2601','55885c95d32c38e9856306f0cd7737f13fc0568e33637b8531fade85b2797944');
INSERT INTO blocks VALUES(310207,'533b4ece95c58d080f958b3982cbd4d964e95f789d0beffe4dd3c67c50f62585',310207000,NULL,NULL,'b65cf7069a0eb909357cd5d45129b70c576eeabc0cb13404029d088e24a2be34','e79ac4e24b64428d20849e8c57390b3ed7248f41dd688d02712d8536cc6978e9','42bd51ae88019be318f1a7ed20fb42a924442bf6b5b848db37e599a8e12a2a62');
INSERT INTO blocks VALUES(310208,'26c1535b00852aec245bac47ad0167b3fa76f6e661fc96534b1c5e7fdc752f44',310208000,NULL,NULL,'aa54dc010fec8a0ef3871c91667c45e88ffac08ee2fc93274d7ad1b2b5b28102','9b1940e3b1d31ea38c721d2e6f289d05ef7f3c001325d2523bac2e0510f32350','b95f3b8c0983c1e45c92803fb359828fac4482fa8ce4a67229eb3b975c987f4d');
INSERT INTO blocks VALUES(310209,'23827b94762c64225d218fa3070a3ea1efce392e3a47a1663d894b8ff8a429bf',310209000,NULL,NULL,'c7866cb2098c87c1333da5b3dce4c84bdeb620c9f1898456b7cceb23e4027df0','ec8d5fb7ff2a03a5931e9d4ec5c616641451e9f10f8d90df8a468671fab42a82','92656f8a3c761d0f234ebb0aada69d24478c76fd7ec15fb7475378e67df8e87b');
INSERT INTO blocks VALUES(310210,'70b24078df58ecc8f7370b73229d39e52bbadcf539814deccb98948ebd86ccc0',310210000,NULL,NULL,'207a1c90d1658d55fa0fc2e1507fce98521647ab5c4d11099c2742279cc92b3f','0d68e753eedb5bf0f7e4dc4310a2382e4fbaa565d11d329aedc20a5bea1b5a0c','a970171f5fe096d454a89a34b4132fbec396c8fae5699199dd372eb36f7b75bf');
INSERT INTO blocks VALUES(310211,'4acb44225e022e23c7fdea483db5b1f2e04069431a29c682604fe97d270c926d',310211000,NULL,NULL,'dfc7fe172f9bc77148a1bfad5d441a3688f718b4985406d0cefd4c4dcd926208','de9c42de195b324543a15210e5063526382a8903a3519844d8f04d79a36a33b5','9999965f630ed49c2b282e7426b587174578faa8ccb385bc5c28866722f2d1cf');
INSERT INTO blocks VALUES(310212,'6ef5229ec6ea926e99bf4467b0ed49d444eedb652cc792d2b8968b1e9f3b0547',310212000,NULL,NULL,'32a39bff0606ec93454a2cb144c0bbd1939bf2be6a2ae369b885afc0b5ef33c9','a9b078dd5b02a985f92816277cdb53cebb98901e0f5aa01fd7517c0d4e73ffbd','3665151496c0639c9d83452037ece4bd6b6991ea6162dbabc9b78f565e9ccc25');
INSERT INTO blocks VALUES(310213,'17673a8aeff01a8cdc80528df2bd87cdd4a748fcb36d44f3a6d221a6cbddcbe7',310213000,NULL,NULL,'15968873880e97e849e59971d4ef19881b1c11c3148dba966f51d986c59ccf36','729e656ef17310f74f9960b29cc960aca0ee43b6d0444bb34395d40046e42767','fe0ae27f0146c89e60b86eb0a3e39909575c9cc5f3a908cf415274c153a28e75');
INSERT INTO blocks VALUES(310214,'4393b639990f6f7cd47b56da62c3470dcbb31ef37094b76f53829fc12d313454',310214000,NULL,NULL,'dcbdc463154fe49a7f22611fcb53e5ca78501424ba741040d89cac9db0a03ac4','32f88755f4e2d5c340abbe78edbf72c952fc9c5f0eeaa89a3a62e49166764659','baf051d6b71c94cb384109ea1043062045472ff7ec9053a497be552670735325');
INSERT INTO blocks VALUES(310215,'c26253deaf7e8df5d62b158ea4290fc9e92a4a689dadc36915650679743a74c7',310215000,NULL,NULL,'6047855f1c691f27ade1cc4c587f1c11ff68f5f5bd7959a23f801e5da7773eed','cef4ef870938d2bbfc4bab833b5655f4192b769478a4cc7efe598201d3c65915','a617bdb934f69fb26ce7181f46635f73603e7a35f288c7b7ed9af1e0b87b2e7e');
INSERT INTO blocks VALUES(310216,'6b77673d16911635a36fe55575d26d58cda818916ef008415fa58076eb15b524',310216000,NULL,NULL,'a12fbb09858868de79095c8e3222f6fa179f2f00bc3c97c8205fd9367ae05aef','57c5b6d97e049419508522cb008a2ba2d1fb17758802e62894462e3797da7dac','049c20b53dee71d1baeed0ba2b35fe954ce5176f932085591fc1b13002b1a925');
INSERT INTO blocks VALUES(310217,'0e09244f49225d1115a2a0382365b5728adbf04f997067ea17df89e84f9c13a8',310217000,NULL,NULL,'419d8dc096dd58523cd4822748754158f0c11945bbb62100cb5268cd802580a8','0db02f57d037d07a18d46f7d71e364293ad763e30ce28b6f9f0ca9249d89a3ed','7bb24ec4e135bcd974db88901817c52b299691be0ff7e96f281f406371ffc089');
INSERT INTO blocks VALUES(310218,'3eb26381d8c93399926bb83c146847bfe0b69024220cb145fe6601f6dda957d9',310218000,NULL,NULL,'a36c07f7fdfaf7878d73baf14aee58b42220b2b2411fd1864450ec6ce1fbd173','8c15c4f778592255791044293164c893bc5cbf08f016aca8ae8b0635a483dd62','d35fb571e4a750529b40f69dcb956c95c80c3579af86fbc667dd01f85af3ff15');
INSERT INTO blocks VALUES(310219,'60da40e38967aadf08696641d44ee5372586b884929974e1cbd5c347dc5befbf',310219000,NULL,NULL,'7958aa94088ecf0384a9a6b0569e9507d208e009e9ce139c823960e40996a47e','99460baa5c084807972318e3d3f1d934f2baa77fb1429616e13eaf7733e0b344','125d1ea3749a1a1bd8285f1653faf6f188b74488abc1da26dac5328d4225739a');
INSERT INTO blocks VALUES(310220,'d78c428ac4d622ab4b4554aa87aeee013d58f428422b35b0ba0f736d491392ef',310220000,NULL,NULL,'00907c4368c2dc76d1ef98a0ba3c86bc4746ed2734b0c10f3797e0af70714240','d08520af8d64e87b66601d763ecc89ed5415cdea31230ebcd878843b55c01be4','369fb984be83948acd401ad8d9257e7c3738e6a0075fc2c8e539bff1db07a8ca');
INSERT INTO blocks VALUES(310221,'cf5263e382afd268e6059b28dc5862285632efe8d36ba218930765e633d48f2d',310221000,NULL,NULL,'2e42f882087dc2158036592298321113f1b34e15b414efa6d43364c06d368540','8b10dbff770f960c66528020a7bfe2fe6a55f6d209bcc74dd6626b1af1a35cc5','342cccd87b8e8f658ea44e553bb10a2b014a4e88abbb0420ea4d5ac24bc33532');
INSERT INTO blocks VALUES(310222,'1519f6ec801bf490282065f5299d631be6553af4b0883df344e7f7e5f49c4993',310222000,NULL,NULL,'00c4a5d41dd629bd0973c03152e4519214dce68498999c8dddc1f7a1cad28a82','287fe2a481571c609cdea23cf9ad007c988dba3981f87cf7adb257e09d4ab2cd','86c799e28a4bc6e9a5fac8aa39631ea74ef593b1a5b6e106a0ab995452b384c0');
INSERT INTO blocks VALUES(310223,'af208e2029fa49c19aa4770e582e32e0802d0baac463b00393a7a668fa2ea047',310223000,NULL,NULL,'41c7a0fa22ebee9d55f2a3b118314293d155c349ba01069a23ddff76dc842955','655ed70b2ed1dbe62ce73613f55e7838a26a31caa24ad69dbe5ab4436965dcbe','11bf6f7dc107164e029bf9bb6881a79ae4b176e199a13157ad4f332dc01b8218');
INSERT INTO blocks VALUES(310224,'5b57815583a5333b14beb50b4a35aeb108375492ee452feeeeb7c4a96cfd6e4c',310224000,NULL,NULL,'66c268462442b69efb56b29e08aae1a404d3543e0a20711e8998a31af45ee929','1af734c70d13e816190a155c1fff630faef8c6dbe681bb079ae9999c3a04a29f','13b4775097e7f8ab19b1b385b7f33301b71e2916cbf68187a1015e97db9e6f64');
INSERT INTO blocks VALUES(310225,'0c2992fc10b2ce8d6d08e018397d366c94231d3a05953e79f2db00605c82e41c',310225000,NULL,NULL,'cf39fb28a7e4d4db7657bb11a30d592a15c049000d7ac86d4fb3d942bf879b95','312172ab312fdb9afd03c393db7ca676decc6a6218fd93cf5ca2c689a7320991','2356d4faa8dbbb7d7c37e303a5e6645350d7970f9a75926930bc97e9ff52059a');
INSERT INTO blocks VALUES(310226,'b3f6cd212aee8c17ae964536852e7a53c69433bef01e212425a5e99ec0b7e1cb',310226000,NULL,NULL,'cb622a4d04645ad96d3e0006f2b7632e8b82e44206d6c1cb75212b059fe18de5','6395179bcd7bb16175d97c65f16862f0c9e4f0206cea2c199dae4d51f7789793','a6cba7cb9e081bc1f9a89c49e315f2d0b362917d984024a4c616d6d30b45ffc5');
INSERT INTO blocks VALUES(310227,'ea8386e130dd4e84669dc8b2ef5f4818e2f5f35403f2dc1696dba072af2bc552',310227000,NULL,NULL,'60ae4209347248a3f7ad39b6436627f06e45433f6b6dd89cfd3383d68974a41c','7d39eee470bf2d3128cabaebd6abbdd8328c6b5ab81b0bb2172926f66dc11791','d6961f4cb91d94a303c3b3aa6b219db4c2ad191808f8c47e4ed84b0dcc84c4fd');
INSERT INTO blocks VALUES(310228,'8ab465399d5feb5b7933f3e55539a2f53495277dd0780b7bf15f9338560efc7b',310228000,NULL,NULL,'798206ee77c9e2fc8fe943f9bf2074c9c2560f534e3304b944e2ed3c89ce8bcb','ec15f394a05b491a6a1a242c869ed86ef3bf3cbb7713e54e45ec04c43428a901','e87dc001fe650d00b73be547855ee0f34f431bd42b73997f2582d75ff9be1cf8');
INSERT INTO blocks VALUES(310229,'d0ccca58f131c8a12ef375dc70951c3aa79c638b4c4d371c7f720c9c784f3297',310229000,NULL,NULL,'becad39a4d1bc8d73a856fa1d2bfa251f29b23fec9448a91932dc610243fd8df','826808e21c97839126feeed6315a088d1dc56573b85112ea7dc5a854166d26c9','07adc7d990d901290326e1513cbfe10a7460d54a2a5c1d78b193aeb141980c2a');
INSERT INTO blocks VALUES(310230,'f126b9318ad8e2d5812d3703ce083a43e179775615b03bd379dae5db46362f35',310230000,NULL,NULL,'e08eac4daa7d7bc70f2f47a835bb80993d6d6db06d8d8986101b717db1c62ed6','5c1bf9eed2f61a580c9ca687d00c2bf5cd450d8a7c944463f3e33993fefa7782','cd056b2939153810183c922d449a53407ab324095319823bfa80ee6c9dc68a21');
INSERT INTO blocks VALUES(310231,'8667a5b933b6a43dab53858e76e4b9f24c3ac83d3f10b97bb20fde902abd4ceb',310231000,NULL,NULL,'a761c29e76c9d5090cd1d6424beb91d0a9fd9546c67ecaa6d4879177b6745b59','827ffe82b20e513087fff1935dcdae183903ab362edbf1280498f593b08532a6','67f6dff588d73228c62f8ccec62d465baddcb6cfeae7d90c17dc39c61baddc76');
INSERT INTO blocks VALUES(310232,'813813cec50fd01b6d28277785f9e0ae81f3f0ca4cdee9c4a4415d3719c294e8',310232000,NULL,NULL,'5da469b7e21ad8ec4fe7cc2f426dcaeb18a3a4a3c44385d529a8b252c77a9e43','e5066e77f6bfbccceeed96734b269104bf9adae5bf59441640ac3a6cb1e711d5','270ae7508fa973759b4d0e0da2f9acb8e084568908dfe89acf5486ac2812071b');
INSERT INTO blocks VALUES(310233,'79a443f726c2a7464817deb2c737a264c10488cac02c001fd1a4d1a76de411d6',310233000,NULL,NULL,'d8531834d572acc01591997cac000185facc033e1ab72f8218a70d0ae3898914','d4d6f1312707d6d605f25c15d83a1cc9dc396c4762467089caca9ecb61cfe17a','4854518ac325474c6f590f9e1289a273ccf082409d21a3884f4d8407fd3c30bc');
INSERT INTO blocks VALUES(310234,'662e70a85ddc71d3feae92864315e63c2e1be0db715bb5d8432c21a0c14a63cd',310234000,NULL,NULL,'0ac6803ab61e14bb08fd8051424565086ab11b4d33faef077f5a0732eec6f766','5d7a81bce7922d9483840007d4e8a171f766dece86ebc78a383c17ddf5a70148','bbcd0eddbf01f0b1f924c7bc4b094c8e2d959b355cd92237781c5b83374ae8f5');
INSERT INTO blocks VALUES(310235,'66915fa9ef2878c38eaf21c50df95d87669f63b40da7bdf30e3c72c6b1fba38e',310235000,NULL,NULL,'5f7de1c7fe45858dcc844604a77051d55de3b9dbb5f5d9910ead8bd0f3af48d8','b9d6ac75274c9846ff59ebca1e16ffe8979a69c315058fb854eb4f8025de1b4e','829536f73098525032621a71df9250055db919c0ff98705de79a6aa172cfe1fc');
INSERT INTO blocks VALUES(310236,'d47fadd733c145ad1a3f4b00e03016697ad6e83b15bd6a781589a3a574de23e4',310236000,NULL,NULL,'c0437ca60921bb73516c31a74f78d2fb48d2c628b629c8f55c8fbb0060718d76','1879ba4b3949b6c10ce1af392a1d4e5c6f5c755a40369f76a29d0ca490c34450','5d184b15cf7435c9d80a5ca703e7cd1c5e51c14773d79b8cc11d35bc75df7e5a');
INSERT INTO blocks VALUES(310237,'2561400b16b93cfbb1eaba0f10dfaa1b06d70d9a4d560639d1bcc7759e012095',310237000,NULL,NULL,'4340ab34a083b38dbca477b6cc2479e6d70ffd6d6b9b75772068674297abadff','471b971a930c8ab259e98cd1c049f6d4054ad7eae421bdc81a6da316148c712d','c044d70184dcc0fbd21b7f8403e779138eb3fab6121f73addf91d34ca67ab3c5');
INSERT INTO blocks VALUES(310238,'43420903497d2735dc3077f4d4a2227c29e6fc2fa1c8fd5d55e7ba88782d3d55',310238000,NULL,NULL,'6a76891c10ff0f9416ae1a024b985d621154918bd8ab545980b57fd2d18c4af7','68a0123ed65b90454b914bdac9ddacd4c78b75690032c0d66f5352c4c7fb2813','4122699487d24b2612813611617319ab0d92a910bbb8901095e46f39f55f2203');
INSERT INTO blocks VALUES(310239,'065efefe89eadd92ef1d12b092fd891690da79eec79f96b969fbaa9166cd6ef1',310239000,NULL,NULL,'1128bb89562fc3b112da425a3dee67adaf741a8021ee378bdfeb44af3b1b1fac','1e90d307f280205d270ca7c3d6143abae217b46c3e7f15d04bcfdc96c3fc3115','5b224d65bdcb8d518307dbf74c6b4cea2aebca23915b005f0ed3e0fc5367eda2');
INSERT INTO blocks VALUES(310240,'50aac88bb1fa76530134b6826a6cc0d056b0f4c784f86744aae3cfc487eeeb26',310240000,NULL,NULL,'be05624b84b2e76794f065f36b4e98d6c6c120f1d8a5db91957bbe7008ce3240','d2422495ae4ad3b94b8ab85f830f04a95606f53b694fd2550b01dedb16de8860','a0dad06591020147fc120ab748e08daa169f63c46ea9ff555a45c053d937f89b');
INSERT INTO blocks VALUES(310241,'792d50a3f8c22ddafe63fa3ba9a0a39dd0e358ba4e2ebcd853ca12941e85bee4',310241000,NULL,NULL,'5abfdfb1aa42fb80ca4538062d152d965b6a7a56bd1e170a7a109409a4606b7a','26e84b2b90c02625be05546293be31d4ef52aae389836b16894e21411f85590d','f6a6aeb3117ae8c56e7f3548b264eafeb0dc04128ed07eef817897d586ea7fa9');
INSERT INTO blocks VALUES(310242,'85dda4f2d80069b72728c9e6af187e79f486254666604137533cbfe216c5ea93',310242000,NULL,NULL,'5f354f767df3256aa6a23544a7164160b9fabe481c85d1891f5250b3026dd7b8','ba8cef08f7eeb5270967e79b814d9604111481655caef021b4a94830ec7cbada','b00434f27aa31be498dcc411ebe132bdb6d800fd83acbc899aff6b059e0e2045');
INSERT INTO blocks VALUES(310243,'a1f51c9370b0c1171b5be282b5b4892000d8e932d5d41963e28e5d55436ba1bd',310243000,NULL,NULL,'ea3acc31b3c298237fa11ca4400c65ee46732c96e0b7fac5a183dd49d938e730','9039d04461b6e62745866a51b52c5a552dc82083faa026bbf50de2229cd70e28','39ab9ec682aa44a7d8c1f0cac6f03eb3aea5a41562c53dd980b34aedf5101e2d');
INSERT INTO blocks VALUES(310244,'46e98809a8af5158ede4dfaa5949f5be35578712d59a9f4f1de995a6342c58df',310244000,NULL,NULL,'07ad792741a48d5a7b657e6c4dc83e3534c79bd1e7da7044139516124adc8f80','bb43ec20936ff8d741b5ea629bc19911afb75dd1c7d5c1a70aef783a82a7acef','140f1db00f5591ac032b5985bac63065b4ddfbe6f8acd86a023fa2b39ffd119c');
INSERT INTO blocks VALUES(310245,'59f634832088aced78462dd164efd7081148062a63fd5b669af422f4fb55b7ae',310245000,NULL,NULL,'d36a618af8e92da03b373ab0137ded666db6cef906a6b2c0cb8c71057a1a5903','51edd2365b0835439322b3a54197a80793882b7696e6600e5224298968c3cb59','ed62153a8c21237f5570bb47a606e00fafb3631bc7f05187f1d534ac359c72b6');
INSERT INTO blocks VALUES(310246,'6f3d690448b1bd04aaf01cd2a8e7016d0618a61088f2b226b442360d02b2e4cd',310246000,NULL,NULL,'a34e154571ee585a839053a851a007d6d433d3efd2b3e923a9c4ec4bb0dc9d98','ef15f15c76fb241a68b39c9f5ad400a0602ec60adbf82fa1fbacd7d1543ef320','7c0e8be1921d54cec4fa0777f8072ba25009157204da057dca2dd2518a3d5c98');
INSERT INTO blocks VALUES(310247,'fce808e867645071dc8c198bc9a3757536948b972292f743b1e14d2d8283ed66',310247000,NULL,NULL,'ee94fcb9210718095ccdf63f30ab081f45dff765a9ca4f5c86b1b0d98973ef90','c7e84b0ad91d97f079377b0a7af8fa96817fef24e6126454cc76243b4f92458b','a5be9a422f0ebfc7f1cc38085918a7231f494102d358f7bb17b0e6fc1a087f91');
INSERT INTO blocks VALUES(310248,'26c05bbcfef8bcd00d0967e804903d340c337b9d9f3a3e3e5a9773363c3e9275',310248000,NULL,NULL,'029884a5273466fa45cdfbd91ae3aaca50af0771d22f6b55af6367348c2802e2','fbea33ffd38215d750e04675f7a4c3b5ce07aafeaa012ecaa081bc84308602c2','3a635e743b5da2d5b41465f319328abab3c78c37db30f33cf6d296895d5b0d00');
INSERT INTO blocks VALUES(310249,'93f5a32167b07030d75400af321ca5009a2cf9fce0e97ea763b92593b8133617',310249000,NULL,NULL,'dc10674812c5249c693ab7b148d048439a0d77266014f3afc1810a6260838f02','2ab263421028384a236a576f1173d659fe937cb9c122efd45983bd50cae95c1a','88bb595f64467e5523ec70f6947526ceab56cd6b5ddd234c5c88d26d81421901');
INSERT INTO blocks VALUES(310250,'4364d780ef6a5e11c1bf2e36374e848dbbd8d041cde763f9a2f3b85f5bb017a2',310250000,NULL,NULL,'a0fd49b46ff0000e83d4c56281dfe2be1bbfc924c75969726754b05bf7107641','582c7ff8729e5d2f258dd91afe31f7e0e3598ad8f457d8b5401b1505a4aaa681','93899112b33812cc7bb8ddb08081377fb67775a736a7ad5df9958dc30d186d30');
INSERT INTO blocks VALUES(310251,'63a3897d988330d59b8876ff13aa9eac968de3807f1800b343bd246571f0dca7',310251000,NULL,NULL,'bdef6a6203d28d314dc087e539a9cdad19d123b605824f0a66f13bf5f72de9b8','11fb3e1fed805999a5c764b4f27a91a27aacd4b27c99a35479b9b57bd2ec8dc5','32d9605bc1842cc88707caafa0b408de41a8500fdfedbd2341a94cc4f56a4908');
INSERT INTO blocks VALUES(310252,'768d65dfb67d6b976279cbfcf5927bb082fad08037bc0c72127fab0ebab7bc43',310252000,NULL,NULL,'8da11bec0d58b196ddb073d3aba0def98f01f83da654765fcae21cae6046214e','b0c2c8274fef58c6edf095a79cbf39892b0efb0de8aef1e2a773ece58a08579b','5a297a10f76656010b479246d8f9c0cbc931dead60dd97ebf870db4f1492ce58');
INSERT INTO blocks VALUES(310253,'bc167428ff6b39acf39fa56f5ca83db24493d8dd2ada59b02b45f59a176dbe9e',310253000,NULL,NULL,'2efa2c5781899d213741e795ca62fbee9d3ddf53792ce002db7484adc66bfbd4','c773d6d338f64d6645b391de2717a667a41bccb32a75f70a0906d3c047f51629','1bcd9daf74532b25b5cecdf8f287a11f3925a35531ec875da080700eb068b4a2');
INSERT INTO blocks VALUES(310254,'ebda5a4932d24f6cf250ffbb9232913ae47af84d0f0317c12ae6506c05db26e0',310254000,NULL,NULL,'d062ec468e76421d3769a99eb3c8b2cbf4bf393d109ba13b3bce128613fff547','b08bd49f37ecc81fe77cd707e234f0e7b7acd8f664dc64d072db887fadf98ebc','a801c00088c61d6c627e80f823035845e29b3318b7143963d564cfa3df3a6020');
INSERT INTO blocks VALUES(310255,'cf36803c1789a98e8524f7bcaff084101d4bc98593ef3c9b9ad1a75d2961f8f4',310255000,NULL,NULL,'5c531dc8a7461e9e7a2ead654509d76c9be3427b1d2b75c0ac7ae0e03126c49a','e1a00d54c8588fd83d6c975ac8065fbecf2f1eaef6799cd1c742202ec761d07b','c9fef74e43dfc2af620a07ff26d7ebeefacbd16384f7f5ea37182d3ed265ab7a');
INSERT INTO blocks VALUES(310256,'d0b4cf4e77cbbaee784767f3c75675ab1bf50e733db73fa337aa20edefdd5619',310256000,NULL,NULL,'8da9f0162e15e33e14e5e1e22c2fd847055a65b99eec519dd069a83bb9006b51','903f644a1f08b18069ef0d3e6b9e86ac81b6bded5a6453c8d5c08dd50b477a14','b77b1ca26fad139fbb78e2f2a446b3796435564bed42c08e535bdee03b9cc041');
INSERT INTO blocks VALUES(310257,'0f42e304acaa582130b496647aa41dcb6b76b5700f7c43dd74b8275c35565f34',310257000,NULL,NULL,'0cf6657db5f3145587a466c05f237289b639668d844abfd8d46430c090b54913','20c4f630fa42c6bf82bc60b4638a437dba607793d9eb6e6cd2f96c8905546f3a','d77f81605c2cd9b3d5942dd8a4204948d7580080edc9ce88061dd1428bb65ccf');
INSERT INTO blocks VALUES(310258,'3a0156dd7512738a0a7adba8eeac1815fac224f49312f75b19a36afb744c579f',310258000,NULL,NULL,'e340defe4bd84e788f9c5b083849e6aa1d5c7f33123ebe62d7abe04b8a9e312e','43b3619de5e35dd86cd85b133b0ec163b670538e750ef99147829c45c6a5e7a5','adaa26b17a39769603b2780c857655fe78d2acf07f179559ccc5f85d3129e6d9');
INSERT INTO blocks VALUES(310259,'e5ed3cdaaf637dd7aa2a7db134253afe716ffdf153e05672df3159b71f8538a9',310259000,NULL,NULL,'03ca0cbce5a5b50988c19c0d4e754240f50821695dca767d1169f8c7f5c1fdcc','d50eb50ce038331fa8de876ff412e02ef511d92c433e25bbbf9a8c70922ba492','0f5149ae07e114d9724ea9501fdb50edcf6abd5d764f2951c204be2c878e8f62');
INSERT INTO blocks VALUES(310260,'8717ddcc837032ad1dc0bb148ddc0f6a561ed0d483b81abb0c493c5c82ec33cd',310260000,NULL,NULL,'83a3b43e01f4f25ba05b527415baa3e8b8adba319628c245988136bd8fcdfcfe','534e89205ae75a96830ef9d11fb8c155cf9e83cc2c45d728c72a6343cf4dfeff','f1ccabea0fd9a55341f56e464a2ca75b6ae304ed985436b408b1651dfc7f3dac');
INSERT INTO blocks VALUES(310261,'a2a9d8c28ea41df606e81bf99cddb84b593bf5ed1e68743d38d63a7b49a50232',310261000,NULL,NULL,'e61c12005d60870fee947fff469631ee540b1a0d6b8aa67614cfacc0a9f65ec0','72b1114fa24eb78c4308dac122516eceb7d301ce05c0a9f6d25b63fe898647f4','b3f94d71e46552f1e4d34990efbf9bef44c33ed0cb182f8375b438de983a9584');
INSERT INTO blocks VALUES(310262,'e8ebcee80fbf5afb735db18419a68d61a5ffdde1b3f189e51967155c559ee4ce',310262000,NULL,NULL,'c21ac4906d435af5b9ef5576da6bce454f65ef16099b7ee03219a4ae1851bb91','d7fc1e86bcd85a7b02ebcbac204550ed4ab9d9f31eb13fc2a41302b7e2e1bf0e','fdcc317c0b296fb4dcefe4d01e787cecaabc3c59585f35ca938928f980a29890');
INSERT INTO blocks VALUES(310263,'f5a2d8d77ac9aac8f0c9218eecbb814e4dd0032ec764f15c11407072e037b3c2',310263000,NULL,NULL,'676f6c532ff23839fef228a9fac7719e77a3c20efdc17f3cb2d13035c78820e8','b1c26661319b78f64fe2b817ef9c1a53acb450d47a801a0f7d0ebdfa4b10ac93','1b7bebe07400bd4620e4ab7073a5caae153f9a91af604002c0c5f8e24ff658d5');
INSERT INTO blocks VALUES(310264,'ae968fb818cd631d3e3774d176c24ae6a035de4510b133f0a0dd135dc0ae7416',310264000,NULL,NULL,'258854505b1d3067bf360f3d0dcb369ed7a90fec8744578d3dde51a79db72c25','e0861621aa7d8187b22f552077b01091538b9db37efce34a1dcb90c4ce652779','195d55ba0ee1f5df9e264ff8147c8dd1cd6d2051e15472dafa5654fcd362ad1f');
INSERT INTO blocks VALUES(310265,'41b50a1dfd10119afd4f288c89aad1257b22471a7d2177facb328157ed6346a1',310265000,NULL,NULL,'72ab32c420a7dcac0e7c36c4d9ca81e237955b4d8bc57c87078ba292923ce98d','d91e0e807787b993922e4fe885061451bbaa40007531f21e0500f0ef2fa56b8b','df027064e78e3a9b63aa03298e8a3844bf76528421e6faa441a5830624c48c34');
INSERT INTO blocks VALUES(310266,'1c7c8fa2dc51e8f3cecd776435e68c10d0da238032ebba29cbd4e18b6c299431',310266000,NULL,NULL,'b81386d19aac285fee4e39a818cb0442e378372f7d55f92e6028b37f974e4a61','8fdaef77dab8f24056a89c4915757660fb1dd170d86041c7c1798cc8c60936cf','ac9a1acc44dd9967c72f83689e6a4fe77b73a068c6685f47bcc39a058fe98ea2');
INSERT INTO blocks VALUES(310267,'c0aa0f7d4b7bb6842bf9f86f1ff7f028831ee7e7e2d7e495cc85623e5ad39199',310267000,NULL,NULL,'ea8fef9e82e451d9650777b051f19fe5e34b8976f1bcc1880b6eebe5feda34d5','a18c33df911b3cdc9386bb276797d28c8fd6d72179fdac0b945238aed4445a6b','a363bb74b7e485a1e4693259c5bf675f1b02cb6f7d1dc7fb2c3d9504316b92f1');
INSERT INTO blocks VALUES(310268,'b476840cc1ce090f6cf61d31a01807864e0a18dc117d60793d34df4f748189af',310268000,NULL,NULL,'1545d381812f0f0caa827a237f145838276fe058b05af4808615738ca9910bf1','e7a5ee862c58693a0146a39cfd39b1aed548603e5568f550e84aa53ab26a55c9','50f4eb7cdbe1aa45f7a77086438a6380b08fce8665dddd5c2fbce1ba0ff20a33');
INSERT INTO blocks VALUES(310269,'37460a2ed5ecbad3303fd73e0d9a0b7ba1ab91b552a022d5f300b4da1b14e21e',310269000,NULL,NULL,'fd9cf61ac6e1fba409e4220a141ed6c89c18c893c7a752af53d5f7608bc04a67','014913db32d5fd9750e72e4b428a890abe43fe6f69b245d7f2a5dacf21d4f539','dc97aea8ee3be0c355424b4be085ca542111b1379af003a9c820f6f9fe265ede');
INSERT INTO blocks VALUES(310270,'a534f448972c42450ad7b7a7b91a084cf1e9ad08863107ef5abc2b2b4997395d',310270000,NULL,NULL,'1d34c8c0dfdb4733a7b589647abb0e6a08f8de93a5c86fbab786f6d9d1500785','5518f60f15f9e424943c1eda78ec741b4b6b923189deb9ac069cca4262258476','5c8bbee2cb4603a63c2a1bd7ddd851b007cfff63b5f97f43e0ca4ed94b66ca32');
INSERT INTO blocks VALUES(310271,'67e6efb2226a2489d4c1d7fd5dd4c38531aca8e3d687062d2274aa5348363b0b',310271000,NULL,NULL,'cf38baabc6e8a082eba1bd8ca2f72af5eb01cb76bd3c9eb101b27080a3a70d17','89cfeeb0a3b75c359d95154c3af3ddee6d695b98de0ef473ab39a19c73b72161','b51705f3876c9f110076b03f352ee48cdc2f01c43bfab22337f17e05366a3e49');
INSERT INTO blocks VALUES(310272,'6015ede3e28e642cbcf60bc8d397d066316935adbce5d27673ea95e8c7b78eea',310272000,NULL,NULL,'2b2763fa5ab2962582c303062da8b8da7280274e615b3e37f93a32e44793ccc8','faf8e83288c410cc60357e7c0cdd7750d39da528d9eafde5259381bef2480a48','8c08d14234f9bc166f0319e3a14e84a832199107fc27d4020b324acaf20d59e0');
INSERT INTO blocks VALUES(310273,'625dad04c47f3f1d7f0794fe98d80122c7621284d0c3cf4a110a2e4f2153c96a',310273000,NULL,NULL,'ff9df73d4f92b7557c36f20d8f622923dda225a1ae2871e60f16ee2dfdf5b9d8','4c37943a2c2ead278274bb609b81e94ff1af83905612546c0187cd4052c63006','c3874a1fce6488f3af6e5e6c9d9b0e7e43cdd501993342702657f6cb1eceb3be');
INSERT INTO blocks VALUES(310274,'925266253df52bed8dc44148f22bbd85648840f83baee19a9c1ab0a4ce8003b6',310274000,NULL,NULL,'ece29ec2cd160d7634009f41cc2d0f13330d53ec6971c019d69dfa4367f86646','5c0806686964bd9418f2b457ab470e16cffb583412897d863f9b254537b920ab','efc60cbeb24c5f84aa2bb0599680d4a6c6d8add3e35795f1d4356df53b8ba134');
INSERT INTO blocks VALUES(310275,'85adc228e31fb99c910e291e36e3c6eafdfd7dcaebf5609a6e017269a6c705c9',310275000,NULL,NULL,'23738d6d8dbf8b44b481f6c0eade991987c84e8025fe1f484c7acd3ead7f4163','fde62d29308a957d6dbc92cc840e48861a4c4ce85554b534ac965c3cd480547b','6e759e28c72436ff2a6095e77004d86ddcfd735f672c5f59867f32e9ce763dbe');
INSERT INTO blocks VALUES(310276,'ba172f268e6d1a966075623814c8403796b4eab22ef9885345c7b59ab973cc77',310276000,NULL,NULL,'a241e1cb19bfbebb3bbb09c6471760b8379ddc73a67d69b4d84fd1d21dfb7034','6e640b3f3e9a25f508950dbfc498d32a751f992a5625d0c97a57f0acff15c2f4','1f1c8f41da69cc86226cf030060a4bf61abaf55d03b9520ecc32e4460f6b4138');
INSERT INTO blocks VALUES(310277,'c74bd3d505a05204eb020119b72a291a2684f5a849682632e4f24b73e9524f93',310277000,NULL,NULL,'0efa57fd462031a87831832a789ed7751aac5f6c19a23767555b3f7145d87532','7d391153639eecd4167a220cb7bf073dd27081869a379cbd8f8795ce4a1ff531','953acaa5318dcd8bddcb21edcca58d9db698cb1e770612e79d53ec1324fbcc4f');
INSERT INTO blocks VALUES(310278,'7945512bca68961325e5e1054df4d02ee87a0bc60ac4e1306be3d95479bada05',310278000,NULL,NULL,'0045189a4da126b22e91e4bc2a7ac37dc90ec0869b7fcbc927919fca4cce5259','86272aec392e1feb1eccf21ff2409d298f6ed69780031cbc7923795ffd5f2f3e','134b78341ff6c0c52183b69ca7880e9490b08c635a286cabfcd51fa7564872ac');
INSERT INTO blocks VALUES(310279,'1a9417f9adc7551b82a8c9e1e79c0639476ed9329e0233e7f0d6499618d04b4f',310279000,NULL,NULL,'442b7d4dee025b81c298ca0f6a5b9dbdf17ed0087fc36eab7f0671d5a19c9a2c','cbe8147d9ddec515d8d56bc31c6bf801d4705bee9fb4494a8ed88a0b92e2bd54','0bb16bd70ba4fd6cec10f6b8e44de64338667ee9dc11a5bbb25401527adef8cd');
INSERT INTO blocks VALUES(310280,'bf2195835108e32903e4b57c8dd7e25b4d15dd96b4b000d3dbb62f609f800142',310280000,NULL,NULL,'38d7f98ae9cfb8e3938032dc33899e2e3e5a88e9037571cdddf8ed4709fc8225','73363411aedfbab3ae4102629765a74388f979462f5489025145ca1821ee483f','0f081bf2e372fdd9c3b2d72fa1f4476f5248b3fbd365e28083a07ab904ba43f0');
INSERT INTO blocks VALUES(310281,'4499b9f7e17fc1ecc7dc54c0c77e57f3dc2c9ea55593361acbea0e456be8830f',310281000,NULL,NULL,'51237cee3b85f1636e336259b115fad87acc830c71e13ca79e344efb7c308ecc','bf748509ebbe579b49d13087e37312559202d1e7acc82b6c502b5e6633ee7b98','9a0cf3de1c2e7d77ec206af528ef713af9a53e5e5b72c196fdd5e70d1cd914e9');
INSERT INTO blocks VALUES(310282,'51a29336aa32e5b121b40d4eba0beb0fd337c9f622dacb50372990e5f5134e6f',310282000,NULL,NULL,'73adccef91b5c738e8810d4781a38edf98d2aa0a8cb619d575e9bdeda979f1fb','2f5a9ad2f63a829db23c62af184ec0d45e132c28f9c35265ee4aa8da787ae8a0','1e61ad171ae9444bcf4f72cddf0d8135048dfa213bf292affe9c3ca598c8df9d');
INSERT INTO blocks VALUES(310283,'df8565428e67e93a62147b440477386758da778364deb9fd0c81496e0321cf49',310283000,NULL,NULL,'5853e60a1b79d4f154cc1f3dc8b0a4d6130ac07784bac16f257f92b9ef294144','5c8387e242ab488d3cec88e4fd7f0c89c75e44c49c35d7ba7c2f1ae1c7c45f84','6dbeeb0e648af523d25bd04d349fbe8f6fcb3f1aa62abab07c8e1fba3fd8a572');
INSERT INTO blocks VALUES(310284,'f9d05d83d3fa7bb3f3c79b8c554301d20f12fbb953f82616ac4aad6e6cc0abe7',310284000,NULL,NULL,'ce33194cb67aa0a5facd788cc24706ef249bcecc95a9965f91065146b33e464b','9f377567b87a0f5c93d2970dffd67970b04756f0be8386864ad084e88bcd745c','daf1b52c161d51b45f336ee427bb78037669884059c8ff1503f01d0fef4cae77');
INSERT INTO blocks VALUES(310285,'8cef48dbc69cd0a07a5acd4f4190aa199ebce996c47e24ecc44f17de5e3c285a',310285000,NULL,NULL,'3af35e85e98aebe1a9c778570c730bf80e085a08ca707c1a5d44b50f2579e71c','3c09892406f89e196413a4637e929ef8e218411f07c45f45a70b1d76b002f725','3b5a34a5501feb8a7ce5731c41db3e2cd2e0332be1a3d8db993137f57ff0d4c2');
INSERT INTO blocks VALUES(310286,'d4e01fb028cc6f37497f2231ebf6c00125b12e5353e65bdbf5b2ce40691d47d0',310286000,NULL,NULL,'4b09b627adda46ee7cf7116102a330ba2aa1ce714b2fa133f7952af34a52ede9','d01304e3aa21eaf7a51f67045a8fb1ee3e78eea57a1ae51c04295b9155cf7786','ce3e095a2454199bed3776a93982873467e16774605297d40b8a1670aeba1ec8');
INSERT INTO blocks VALUES(310287,'a78514aa15a5096e4d4af3755e090390727cfa628168f1d35e8ac1d179fb51f4',310287000,NULL,NULL,'67786e4ffab15cb78c7bb44ef160d1e5d99b599eecb5ff4f906a6599d744d410','1f47b7981778c975c36bbd7237d0cb3b7e64a5afd21e4fb3eccb82ca36d4390e','f147d283ebfaa889c1b322e56c597e9c36ca9a7ab51669945c11c9372982859c');
INSERT INTO blocks VALUES(310288,'2a5c5b3406a944a9ae2615f97064de9af5da07b0258d58c1d6949e95501249e7',310288000,NULL,NULL,'600716d2696160b3ba290636180f2afa24bf8d24435022b4539a4cc965c18dfc','b2b45e14afe860a8009188454b922587162679c6d83733570bea1a60bad4fed4','99f3eaf94699784f13989124295a05a7edc063c8120204ab952e0ed7a58288e2');
INSERT INTO blocks VALUES(310289,'dda3dc28762969f5b068768d52ddf73f04674ffeddb1cc4f6a684961ecca8f75',310289000,NULL,NULL,'cd6d4b17759152edbf25fd72dce9b9126ea31a2bb1a5435636801e0ee4be1158','354b129353776c14bd16ece4606e1d9251623af639b6e89102360cee0089e9b4','455264015c4a1c4c848e01320aa42426dcaefc482d888305dabc45b3fb394488');
INSERT INTO blocks VALUES(310290,'fe962fe98ce9f3ee1ed1e71dbffce93735d8004e7a9b95804fb456f18501a370',310290000,NULL,NULL,'04a9135f416dc041d3c1c0216a84fd780d133213c3369691fbf5e8848af9d14f','dbce7f3691b295ff9d69e80080e53d67a716d371bdb1c425e6e5568da2e77c44','aa4fff93cad8a5f1565f691d1cfe869bd0331d95e8cdb2cd42dfd59762b3a3dc');
INSERT INTO blocks VALUES(310291,'1eeb72097fd0bce4c2377160926b25bf8166dfd6e99402570bf506e153e25aa2',310291000,NULL,NULL,'50f556e01b9e8c135b20187bf863839e651a0d0bf4cfd1008b446531776f7917','a88dcaa72e3d785a73ed82d4a3e6fdefa87accf06103030acab73090a6a9f7bd','72ce2a31654b4165b9b71da2ef5979a8da5194b242630db48900e43754ddb625');
INSERT INTO blocks VALUES(310292,'9c87d12effe7e07dcaf3f71074c0a4f9f8a23c2ed49bf2634dc83e286ba3131d',310292000,NULL,NULL,'9d4bf4b1c5dba1132a9cbfd78c1d94cbaf15d7648da80c8bc1a8dce12a79eac0','6903d9f698a0052bd1d581f09483ef64b8987604480ad9f81889f72c52e1f9e6','0d6c20cc31437c5b2b3ed1bbf4c589eb55437de318b54f6b4dd5dc6aeccebf96');
INSERT INTO blocks VALUES(310293,'bc18127444c7aebf0cdc5d9d30a3108b25dd3f29bf28d904176c986fa5433712',310293000,NULL,NULL,'a51a3f9af39175cc9d142eff67811307ad8f51cdd8161aaf0d98af9e2be28efa','a9f6ccbfeaff5aa5aec4ee0c0af3566b8479532e531aef0e81ae389cbb178aa5','fce2a6270639d48be87aecfcb5e97c8160f8b6f649fd6455a9794745d06ae147');
INSERT INTO blocks VALUES(310294,'4d6ee08b06c8a11b88877b941282dc679e83712880591213fb51c2bf1838cd4d',310294000,NULL,NULL,'3e9858caa8e835295aa7e78505ea34ce0726e3f5f6cf9fbc6dc4393a28724a25','40aba1256892e2089a57199ea38e52b0b9cb77cafefd9bb4b5dc9d9e3da4bea6','138bd800e04e326887f7d4903aa461812fd8eebd4e265c553e8e889327b9f9e0');
INSERT INTO blocks VALUES(310295,'66b8b169b98858de4ceefcb4cbf3a89383e72180a86aeb2694d4f3467a654a53',310295000,NULL,NULL,'bf48715799c46d629641ba5b72405f6e6cf0500886da94fcc6fddd306a86b02a','4303630df841fb715d088fca850388a3c3ece41cb79a375de3bfe50392f0e838','283c5b07e3cde1af8ab58928a4e4f2cf1f68431ccf9b660f33658d38796ae4d6');
INSERT INTO blocks VALUES(310296,'75ceb8b7377c650147612384601cf512e27db7b70503d816b392b941531b5916',310296000,NULL,NULL,'08e2361ae4b98387ee43fd7230ea8b296dee677b337f0e211527e3cf29a64e9b','476c8fed20910ce19f7a4b340e392d53963a5baa423f6bd0777013d642caed39','da4aaef7953120aae1f8038b8523b9150a3ad5f28625e9f6363d1bfb4439d056');
INSERT INTO blocks VALUES(310297,'d8ccb0c27b1ee885d882ab6314a294b2fb13068b877e35539a51caa46171b650',310297000,NULL,NULL,'cfefc3138983a33686dd1fc37f06fa1d7e01d9b218f7242cdd59005633c0ded8','1d2838690566f515f672f363178ae0138bb67505e9af8f2f0adea9c58dc02d21','0270e14bf21ac688020724217de60564bfee4604176b4fe3797793bf6df93e13');
INSERT INTO blocks VALUES(310298,'8ca08f7c45e9de5dfc053183c3ee5fadfb1a85c9e5ca2570e2480ef05175547a',310298000,NULL,NULL,'25254257d6f6724161b2b73f94d28d3fd40594b4846699b8a2d5f45d205b1fec','c077cd7b5118ec46d7cffc4b8230e5a0bfdbb4f120962b7b5c74eecce3c8022c','44dcb5541824596a137c335d6a3c33e1e9a40842ceeb61b4f55fab7818533df3');
INSERT INTO blocks VALUES(310299,'a1cdac6a49a5b71bf5802df800a97310bbf964d53e6464563e5490a0b6fef5e9',310299000,NULL,NULL,'756acb1055ec75df8fa70f80e23d75f2b47e75035bfd68802e68308785a2ee14','47a372935b0ee023fd20f994fd35e765c675bd429b123f3ad2f29c6b343c71cd','cb3d655092550944ad0c55dda55097fc81286b4c7ace028e436d281227e05bf9');
INSERT INTO blocks VALUES(310300,'395b0b4d289c02416af743d28fb7516486dea87844309ebef2663dc21b76dcb2',310300000,NULL,NULL,'e30027ca81176dc1e79a0ab3a5afbb839a3338dbe9ea6057aebcd383ed884c1d','46d13ed7115506cc2f65487b38c8a35950813feadfc29b36d540670d046ec834','5d12bdcbecf5789f765733f1060e78e754db9a9782c5a2fbc8bf5ad57f6ba921');
INSERT INTO blocks VALUES(310301,'52f13163068f40428b55ccb8496653d0e63e3217ce1dbea8deda8407b7810e8a',310301000,NULL,NULL,'4c2bcffc796af76a2607a978289942241e63a6387e0a2ae8fc3d02c6b5519fb0','9d178cfce4cc241f12a61e04ebc552f5a84facea192ae2673c2fd32d600d126d','1ea28b6cfafd27d6ccda82c69cd4213aa094a97f2a5a18248929c5176e07fa0d');
INSERT INTO blocks VALUES(310302,'ca03ebc1453dbb1b52c8cc1bc6b343d76ef4c1eaac321a0837c6028384b8d5aa',310302000,NULL,NULL,'a39fdd7f84d2f6e29b613a8a724bc0902d9abd2d6b4d2f46c3b0512928d69b3f','09a774c58971fbec44d43b3d8f980ed0df90155ca4468b9492aa00a9f8c19551','3606e7c1b2e7731597fa68f5134810eb1d5455ec6ebd46b4b21a9a7a8b69d656');
INSERT INTO blocks VALUES(310303,'d4e6600c553f0f1e3c3af36dd9573352a25033920d7b1e9912e7daae3058dcca',310303000,NULL,NULL,'23f307ef560a02210f4aae5fe605c6d8af9317ab17f1e1ef0944038a3515da49','7e30fadff629e34653d2640939c5960ecc4726f1708fc7a8d70678ab2a56f597','3aeaa0fdc09c0640772c2ed73cf9fbd65c02a9cbd3b33a79e1367a6f6fab2fd7');
INSERT INTO blocks VALUES(310304,'b698b0c6cb64ca397b3616ce0c4297ca94b20a5332dcc2e2b85d43f5b69a4f1c',310304000,NULL,NULL,'6baa2ac646d3725fa01111959753844d22181cbbd1801cb12c4208be3709a3a3','538b92db686b8b7b2f49e037e6425c443e202075d5b222df590ef36e910a7f91','29a2839b0cffc16054f5c2a83383339e78a5de4ad4e9f396d1d6da48b9471d5d');
INSERT INTO blocks VALUES(310305,'cfba0521675f1e08aef4ecdbc2848fe031e47f8b41014bcd4b5934c1aa483c5b',310305000,NULL,NULL,'c366fd009860a090c632131eae9380820e512009bbbaa6f7bc5529afab7a88c1','7d1c43812e48ca71e142564c7f546aa9421cb479112ac5d28e02ae9259a8740b','2cb256710393266b4c61d0a235456e70537fa419e88f0035d44f256eea3bb9b5');
INSERT INTO blocks VALUES(310306,'a88a07c577a6f2f137f686036411a866cae27ff8af4e1dfb8290606780ec722a',310306000,NULL,NULL,'fd12969b828d689063b4885a0356fc17e5207794d1f5b6a17bdeb8d584815a79','90ad06792dcbabfda30adf7d2cf8bc6985c4dce3334ac09efb8080f4f9948adc','28b959ced1a3ee72e23bd3462814a85f8dc5765515ef5d981228ea6c3221ba2e');
INSERT INTO blocks VALUES(310307,'bc5ccf771903eb94e336daf54b134459e1f9dd4465dec9eaa66a8ee0e76d426c',310307000,NULL,NULL,'e168094d31f56d36e4c3863fe719e6064b08ccc6f3c2adb490b1359360026aee','1fc9f62f8fc4481a052d450a3e6b716a736f27c4d656466a6424326a11091171','d963bdd45b2a619f7ea2617f3e229f088a0de0bc108e10627806f46afed21020');
INSERT INTO blocks VALUES(310308,'2291ffd9650760ff861660a70403252d078c677bb037a38e9d4a506b10ee2a30',310308000,NULL,NULL,'523b3bba7b02e2c4e588f21ed14b7b4f6630f887cc89f9361487b581d7e633b5','4d58f69181e21f8f5f702ba517131f5373bd7d87bb5832bed11d637caed435b4','41a0aff2c7bcd1c96a4cb01597a8e64cf5879dd831c03811b9a505224f7e6735');
INSERT INTO blocks VALUES(310309,'ca3ca8819aa3e5fc4238d80e5f06f74ca0c0980adbbf5e2be0076243e7731737',310309000,NULL,NULL,'effe1a68917014086da3bf8696f6c13f3cf2cb5cbd6c18b80ed622e476cff017','39a3d044db43c820a9000be964a8b6dcf90a73c07c0d5ba4fa026f7a9ca582c9','0c7af838a7a6bb29a35c808e8f9c2f80f6a48a148bb75319748e26a9fc669da2');
INSERT INTO blocks VALUES(310310,'07cd7252e3e172168e33a1265b396c3708ae43b761d02448add81e476b1bcb2c',310310000,NULL,NULL,'968fb8a7409531a27ffb52af484e7c1076f05b58f9a51bf9cf3d5a7d83b12002','28bcce4a1619876b77467cc171d29c32951592437fdb45c8ec8a02573237169c','4afee610b652f67443fd63c97158fe64567bcf94dd81a55480dce131c171774b');
INSERT INTO blocks VALUES(310311,'2842937eabfdd890e3f233d11c030bed6144b884d3a9029cd2252126221caf36',310311000,NULL,NULL,'8c69639a757d0195594fa1da3f6b35a0e8c62b8df7f95db81e26d496b8c9dd72','a213b4c36ffd67d3e6f17f6e0d0b79c67f223db87f3a14b18303483c09b54880','dc0325822051af46131fea34547f17687c20e61bac35589650835751283efe61');
INSERT INTO blocks VALUES(310312,'8168511cdfdc0018672bf22f3c6808af709430dd0757609abe10fcd0c3aabfd7',310312000,NULL,NULL,'8d839bac01b9aae5e554f691ae0ee42cee072f9367fcc2811d4b3f65640cfcad','994e653838cbeb9eda97b1be90a5189574d7ac5c21e32ffdffb2208d6cf1e722','04fcf474468d079dadc12715648e8a5e9b8464171dcc152170131c13dff3f0f9');
INSERT INTO blocks VALUES(310313,'7c1b734c019c4f3e27e8d5cbee28e64aa6c66bb041d2a450e03537e3fac8e7e5',310313000,NULL,NULL,'1377f4255bfd7ff6638734733a4b8faec97fd62aeb954e42b477c875ccc50b73','30d85e88d69c204ae7864417e910da548fc4f4cc7f275c6d6c406e973b8457e7','d1dd14b334c0a93771227ae64778f8eab4853a47edf698d8de6f23e24a394556');
INSERT INTO blocks VALUES(310314,'1ce78314eee22e87ccae74ff129b1803115a953426a5b807f2c55fb10fb63dc8',310314000,NULL,NULL,'8ed80d44f0d6ad01a30611d94b91f735ef3a166cf0dfa7531492a3e4ac7c29f1','3f1d3f340503f43d5cddf9337034cb07bc09ae0d4b264e6794fdbc895a24f112','4467cab69f322fa33aecccaf724c5ffb75d7b543962cb829d4dbae19fa7e6850');
INSERT INTO blocks VALUES(310315,'bd356b1bce263f7933fb4b64cf8298d2f085ca1480975d6346a8f5dab0db72cb',310315000,NULL,NULL,'24b5905cf0d5349b7031870af9677916892e3292fa61455a75e84c1605a398ba','9a3271e941405743af8faa0438d23f2d1ea66de0f0f18cacb2d8983ec5a1feb5','24da73946fcc269d01ddb8b5b4bdf23fce039fb71fdf7f0d29390ff4fb40a49b');
INSERT INTO blocks VALUES(310316,'ea9e5e747996c8d8741877afdcf296413126e2b45c693f3abdb602a5dae3fa44',310316000,NULL,NULL,'a191657253ca159739403f35417ef74637b053db49c7db62465fde4c54e69239','2ee34a972202437ee803abc90e4992c0face3dc760b8199f29efc9ba731781ea','d7a7499217bfee1a6dfeaed315212c366032697cdfae9e106c7c349c092ac582');
INSERT INTO blocks VALUES(310317,'aa8a533edd243f1484917951e45f0b7681446747cebcc54d43c78eda68134d63',310317000,NULL,NULL,'bf6d880b9fa42b0e38523c00c92a898093afd068450be504a0a56bafd69ed647','e25bd4d3402ddb450ac86ad2f1885831d83a64900c4423644dbdddd98e837959','b7b1f7f12eb1c0d58c726282439a7d697dfada02a78210ee86646d75de2275aa');
INSERT INTO blocks VALUES(310318,'c1be6c211fbad07a10b96ac7e6850a90c43ba2a38e05d53225d913cc2cf60b03',310318000,NULL,NULL,'6422eb2cab5937adb9ca2194c025d0dce63cd62e18d7ebd63220207957c942ee','7b183ed6fff402ee976cc16afbf85bae15a1dfd3397255e3a803ebf4ce606a1a','0b1797d2cdd0e124ade322fe36659311fca0365babdfb64a7713134750099b24');
INSERT INTO blocks VALUES(310319,'f7fc6204a576c37295d0c65aac3d8202db94b6a4fa879fff63510d470dcefa71',310319000,NULL,NULL,'efb625496aa4365f5ac198a82833c880a60cd5f86d04689463216619cd7d96b8','c8178ea7e91c3ac5305cad1a449bc0a316fb7455ec97c2e8c084a1fd1fc4ea2a','0bff7e561b6a4643c4f6ce44095634e0d29d29dbd97509bf967356a17a7f69dc');
INSERT INTO blocks VALUES(310320,'fd34ebe6ba298ba423d860a62c566c05372521438150e8341c430116824e7e0b',310320000,NULL,NULL,'8c3938d7b3c0a822ebee67f1ecf21b1db6496e19471cf1f2cd00f30325d0c88a','8a62c1841b93fc8e3c299ecde0a8944ac0ee5d4367b27fabf5e9ec1e4a26bbe6','381ee45ffe5e5c37240ae56dec59c66596b6cba9f7f3cffe4b685904aaa7370e');
INSERT INTO blocks VALUES(310321,'f74be89e9ceb0779f3c7f97c34fb97cd7c51942244cbc2018d17a3f423dd3ae5',310321000,NULL,NULL,'21e4c3a7afd02f183cbb69709fc6c006ab3d38fef3466de1a1870232d1c891bd','c7928776d0951ef5a5cdc288be8079f3dd79da74e4cab9664cec9b92ea07a21e','61355328de1af0aa7a561a8759dd635ee6f147dce4e42542655b5402d8976540');
INSERT INTO blocks VALUES(310322,'ce0b1afb355e6fd897e74b556a9441f202e3f2b524d1d88bc54e18f860b57668',310322000,NULL,NULL,'01b3b28c4d8eb796827267c06e6362206884e44f40c3f72d9b5c9d1e6cdfb29a','1cb190f48b66dec3bb0a00ad6c67a8784b23adfccf50036b210a13eb8733aeb9','1acb61dba6792b41433946f45c7c57f4b7bfd45281741aefade1ee183d6b1694');
INSERT INTO blocks VALUES(310323,'df82040c0cbd905e7991a88786090b93606168a7248c8b099d6b9c166c7e80fd',310323000,NULL,NULL,'a362da58df0d31eeaa93a25c91c17bec62f9cad6ff0c31420584ce293ecafdbc','12e0d031d7d6352b5592f86be3e8e48e1296a41a9dc8c2810f80dab22a9cc05c','83f83512012b2e0f18464a69ac56a4d256f2d9f969b6e23059325d863e0a946c');
INSERT INTO blocks VALUES(310324,'367d0ac107cbc7f93857d79e6fa96d47b1c98f88b3fdda97c51f9163e2366826',310324000,NULL,NULL,'d1b353ac97e000471c66df8ee04d7b0c25f7eead2414e5648cd2ef334881bad6','61f94684a3d4a02599cba4f883c85dcc0dd34fb76730a7a6a5878245ed58b2e6','8379d9a7068a0b2591d5856cea0f7d98818c55fabb7a08a185f1945f7afba9d7');
INSERT INTO blocks VALUES(310325,'60d50997f57a876b2f9291e1ae19c776df95b2e46c14fe6574fb0e4ce8021eac',310325000,NULL,NULL,'7734300dc764c67fde935dd4432396de4a31cedc2901f3fc70bf1576797cf7b0','1ed1cd84365a7bc86cd2d898464da0ddd24170a306cfe8c1cd00a82c7f449a49','f1202d25c5bbe34ffa4d527584a82382d322876c3817f093085f1db00115a95e');
INSERT INTO blocks VALUES(310326,'d6f210a1617e1a8eb819fc0e9ef06bd135e15ae65af407e7413f0901f5996573',310326000,NULL,NULL,'ebe859a722587fd456695c6a46af7f0bf54c03e940bdbb5424520a8c1fe70617','ed90b4328a66a49dd752700ce59b244c433d8f28e69bd77f289f9f0fee774c01','5a44ee0aa071fa524b9382df335da189e82036da33f85dec7fef2972b5620d37');
INSERT INTO blocks VALUES(310327,'9fa4076881b482d234c2085a93526b057ead3c73a6e73c1ed1cdee1a59af8adc',310327000,NULL,NULL,'8ced7a546ee2c746d4dc3f0ecd2fb4eaa62c65c4e98be74545d8de22c03526e6','11431f7aee07ab67b2c1740a3d51a511bb090d2b3850a166f0fc171d7656c8d8','cd7fb08af6ed7869f26dcd81c5fb42767e876628fe1bd8650f7237cea51c01c0');
INSERT INTO blocks VALUES(310328,'c7ffd388714d8d0fc77e92d05145e6845c72e6bfd32aeb61845515eca2fa2daf',310328000,NULL,NULL,'bb5d3479e492f52a0b3b69d29852faefdff645f9b113eae82594f57e8aa40b5d','10b7f7fafec5614dcf63d7de50ca9521bd4bd89c59b7fea2db99401cec40dde4','ab8b96536cb041c38f91e5e22d007ae96e10ebd484447e108b55f255c7b19cb7');
INSERT INTO blocks VALUES(310329,'67fb2e77f8d77924c877a58c1af13e1e16b9df425340ed30e9816a9553fd5a30',310329000,NULL,NULL,'4ad2c9d802db762537be19143ef5eca474cd9f749bbbc661cb95bcf1dcb0b02b','d3c1e08c50b0692c5f480676d6d52959451d5d90ec4da8e4e007da605dffd4aa','65a6e0a7afd941ef47477618a595c0d23dd7df1a79ef1f203e3e8103fb1d4592');
INSERT INTO blocks VALUES(310330,'b62c222ad5a41084eb4d779e36f635c922ff8fe275df41a9259f9a54b9adcc0c',310330000,NULL,NULL,'4a9a6b59d56f6b7cf867095d939f9bddbf779141177feda470df3759b7d48be3','504abb6e3dc407d21b33631ffdc3d3f1d58e48e5bb422a48cde399faa42333df','11a26ccc79faf3c9bf4bfd9832e80bf69dc06f1145b5ccc7de45394fa27c01e7');
INSERT INTO blocks VALUES(310331,'52fb4d803a141f02b12a603244801e2e555a2dffb13a76c93f9ce13f9cf9b21e',310331000,NULL,NULL,'c676b9c31e0e3d74d005ad0a52a18ba34688b6002da5d269bcea0f789a4f8e91','d7d0a368e42750f8f19f5f7098e423ad72347471c5422a9450b6f9bd826a14f5','8080a0a8c0921007f18c25b5a857c328e091c5e0e1f8d6c96be291898188b46b');
INSERT INTO blocks VALUES(310332,'201086b0aab856c8b9c7b57d40762e907746fea722dbed8efb518f4bfd0dfdf2',310332000,NULL,NULL,'cf0b702c03ecff4bda1254dd5e96ca580b69d5d02d1f233725fccbe1f5f32000','f31b1b665aeda4da533623a511466de3ed8f605eeaec280edff1eaa4df19c3b0','33e4a78db25abd2270766393b99a4d31792994ee452dcdcfd86be0fe98474740');
INSERT INTO blocks VALUES(310333,'b7476114e72d4a38d0bebb0b388444619c6f1b62f97b598fed2e1ec7cd08ee82',310333000,NULL,NULL,'b40359eb197db65549946d93a39b2a732e0694d21b8d0138b9bfce4f5a87ae5b','00d887f97da0744382b846164c4ab335eebeb56006988d8ab0b2629fc6236fa0','a04cc6d7870ce02ff0c116a4fed29a14bc51109a1d6e82ccb9063c283713f197');
INSERT INTO blocks VALUES(310334,'a39eb839c62b127287ea01dd087b2fc3ad59107ef012decae298e40c1dec52cd',310334000,NULL,NULL,'7cb471ec146f9ec1e4d1b93184ea641f7b8088807dedcd1c0be4ca5ba99e80e1','db034109b939a81b9e937547f34b4fbf13aea9d88e2289a55ec28a8e43a305bb','610f2671b4df4069406f40e80f29bc34ed625ef94412ed5e5d374cb048c4c9ef');
INSERT INTO blocks VALUES(310335,'23bd6092da66032357b13b95206e6527a8d22e6637a097d696d7a96c8858cc89',310335000,NULL,NULL,'47de747ec20cbec96a6bc4b71f67ea827c7a5a1ab0d3541fd539efac7442d644','a07462deed568d202a72975afc59676bf69f63808e71a5468e714f26ebd1f30a','a455f6cf5e58302f37453ef09f24aa016b8f4d7d1a3162b9eb0ecda98331f00d');
INSERT INTO blocks VALUES(310336,'ec4b8d0968dbae28789be96ffa5a7e27c3846064683acd7c3eb86f1f0cc58199',310336000,NULL,NULL,'c216588e623d2b3d03499c7e9f817106b20a8c98765979987633f1e4e50d9594','3ce319daa80298a2f24367d67e2834f9795622701e052bc1e1cc884846d2ac01','9b79b8aff346fc674e7670c3a38f950179a64385e2d7375d98776719fc500cad');
INSERT INTO blocks VALUES(310337,'055247d24ba9860eb2eadf9ec7ea966b86794a0e3727e6ffbcba0af38f2bc34a',310337000,NULL,NULL,'a558b47328f54b79a5ad9f7737af0e4df07e13e20f150296370e111879c09c2e','b406d69fc557a89695497cc81f8c59f79ef1eb48747799319cfb6b34fdde988b','b5c129332e464f78421b5d7655eceb512d173ffe3a83cef09bd04c3ea9f7ad46');
INSERT INTO blocks VALUES(310338,'97944272a7e86b716c6587d0da0d2094b6f7e29714daa00fec8677205a049bcd',310338000,NULL,NULL,'31bea50c6481fa982eace70df5fc13d2981f1af13962809e3492b493a0dd4905','71020e50e0127f37a22315cca384f4bd8d9db89fd04e4859bbf362fdd5f6e219','1526bb1c2970b87d55cd6ec646002351c07ea21c0bdd0931336eb99ad75588a9');
INSERT INTO blocks VALUES(310339,'99d59ea38842e00c8ba156276582ff67c5fc8c3d3c6929246623d8f51239a052',310339000,NULL,NULL,'6605ca3db3c509fbc8574f2e10a3f981e2ff17b2812946ec8f2b1e49ba44f220','243a5e2be4451b637bb532986a87cd4ce929c3eef7bad5fced5330486351d673','36125551435033db96d5e2e9c7bfcf9b8198ff950ae2626b3bb7f03e99f98297');
INSERT INTO blocks VALUES(310340,'f7a193f14949aaae1167aebf7a6814c44712d2b19f6bf802e72be5f97dd7f5a0',310340000,NULL,NULL,'7db1ad1952cac2dda86fff6e5f939010bb30a1da26af438d354e17f423d5bf1f','61473ca9ccb3e94ce5a1c665eb3425165fa75b4127ec8adffcf37524b42b172c','c2f51085b6ff62c8bd20ff11027f08a7cd77897e6874370102eb9e050ec24e38');
INSERT INTO blocks VALUES(310341,'6c468431e0169b7df175afd661bc21a66f6b4353160f7a6c9df513a6b1788a7f',310341000,NULL,NULL,'1a1eef01250d2c53a1b34a8ee5b1e8fce984c3d47d28c544c6e162493b51225b','ec49ef2d3c9c44ad869c28af93ef68763205b4ca373a7f4693eea2038c365021','3d74267041503e3e374a808c3e8007b64964c71806b456532aef72d332d44d0e');
INSERT INTO blocks VALUES(310342,'48669c2cb8e6bf2ca7f8e4846816d35396cbc88c349a8d1318ded0598a30edf7',310342000,NULL,NULL,'3c85c0b825985b04b42137da7e59fb3daaaf9e65b871b79390a4d8b31be5da92','10f4ea2831cfc446442f3efb44668838cac01822f76d0efaf99e097dd7991030','bba53584685ad0428af83bc6d7df82c1b561ce5f3803bccfa79f7d0bb5f78b8c');
INSERT INTO blocks VALUES(310343,'41a1030c13ae11f5565e0045c73d15edc583a1ff6f3a8f5eac94ffcfaf759e11',310343000,NULL,NULL,'26f4ea323dd31b715c7a7f4ab8f1feabb199333a8494449ed538ff13215bb3b2','21d5fd4fb2ee3e81ad2b0894af98a53f7d8ee8cf5662b552d513f4387fcc684f','b8f0dc917ed3c38edd90fd5575335d4566326cfac3dc683854157cd87e4e23d5');
INSERT INTO blocks VALUES(310344,'97b74842207c7cd27160b23d74d7deb603882e4e5e61e2899c96a39b079b3977',310344000,NULL,NULL,'444314748cb1fa1c836b3b4de65c3920c7fe446741193e5f77843affe3bee908','5cd9571d1b25b20986e46c10ed0ca4473a50f50d71c1770d4d663f51c7c32ffd','c02fdfff7e6aa59e85108c0dcd80582c73705bbed8971000a5556d5332de4b9b');
INSERT INTO blocks VALUES(310345,'0bda7b13d1bc2ba4c3c72e0f27157067677595264d6430038f0b227118de8c65',310345000,NULL,NULL,'d1775816bb104187076be74e78e87fc6d367c3cb31d372329aec2b635002ca2e','61973233b4f2a2f4721a88e8b254765b2431a79776eea6bdb444a4034617d817','aa38500a16192e6d3b70104247b403665f78b328b4248e613abf94a44ea6c733');
INSERT INTO blocks VALUES(310346,'0635503844de474dd694ecbcfb93e578268f77a80230a29986dfa7eeade15b16',310346000,NULL,NULL,'3244eed1df8ec4ae0ddb04f9f6e59e54244ca3df10dc21fc89c99c74ba734781','b5890677cb7e663d373946ce62771a0a92fbf5c6bf0a34682b05288754709c06','72a24fffb42d05046174dd82165a460c12285068c77bd6479d39fcda8c127875');
INSERT INTO blocks VALUES(310347,'f3f6b7e7a27c8da4318f9f2f694f37aaa9255bbdad260cb46f319a4755a1a84d',310347000,NULL,NULL,'6fd1802c269750b69ec04df457d47cd6b44c261340ebd5b4da61f06ede6aa166','fd0e973576da0ffcffa3036bd769b61f0c348f5bcb2ac5e47a91f53a3250bba3','9344c6ff34533553d29cb944241820412e6bc6c9781318ffdd4a72921716f758');
INSERT INTO blocks VALUES(310348,'c912af0d57982701bcda4293ad1ff3456299fd9e4a1da939d8d94bcb86634412',310348000,NULL,NULL,'668330e80a23f499c0e91b01c4c51aab393813b840f81b6b672611e391699faf','f424acca2c409d1a0e371486335b20c5f93e7c901e3edb54a04576e5ef2745a8','b9ba0d222499cb8403aa39eb3c28f1e99d8218d62a0983001fef5c807d035c83');
INSERT INTO blocks VALUES(310349,'ca911c788add2e16726f4e194137f595823092482e48ff8dd3bdbe56c203523c',310349000,NULL,NULL,'32b36035ac1684e93126657ecd9711feb689672f64cceb03d220a8089dfacf12','ed7771852fe3771c52af43c6a9b15ceba6442294d2edf632417d1c9a2057b98a','d7ce929d6b359d650f8aa75f2eecb415d3d71dd0fd02b13dc79578e798cad915');
INSERT INTO blocks VALUES(310350,'c20d54368c4e558c44e2fbaa0765d3aecc8c9f01d456e3ff219508b5d06bd69d',310350000,NULL,NULL,'dbe70bf3b8e4b74ac25c1b6737b6a760e6a06a4f96ee83a5ca728c8501d4af05','5e108b60c7f1c0d34a92ce1ad52b37ad0a4ac1476f83693e74a4396da2ac3f8e','17a8f023f4a612de82d599a98246732c2f5308d1cc4680e8ac2a345085314d20');
INSERT INTO blocks VALUES(310351,'656bd69a59329dbea94b8b22cfdaaec8de9ab50204868f006494d78e7f88e26f',310351000,NULL,NULL,'89bb7ea865a221a3646f78ea774a7cf1e15e8d65b85ddcfbdf87773145904151','d1ab85bb2877335cb9b1e294c21d447c794b6a5dfab3ce09d72736c6a315f16f','abf1944257081c1fc5125011ee495f13d55e11623ca28d40eb7122f2fb8615d8');
INSERT INTO blocks VALUES(310352,'fb97d2f766a23acb9644fef833e0257fdb74546e50d9e2303cf88d2e82b71a50',310352000,NULL,NULL,'fdbf27d576a72b046776be0e5c0a91d060619778aadef3df1d30f1a7785a0fdb','867692666dafb5a3e3ce472a404a0c22c552a355a116eb4f8b6fb0024081d852','595839378d9f894d7de6775d24b9b412ee615b46ce609cf8425ce4baa7036f8c');
INSERT INTO blocks VALUES(310353,'2d3e451f189fc2f29704b1b09820278dd1eeb347fef11352d7a680c9aecc13b8',310353000,NULL,NULL,'73429d323376209447edc6d2ddbfd51f0bcde21736ea6dad61dc96b6984a1fa1','a7e508b5ec585ff2d492bbbb72be0f7ceb312884f8727a39dd57d007b8d6db2f','71458e5d38c0d7e5f0a023eeedeb03d0cbb40b2bfcba49a005dd21b91d6232d5');
INSERT INTO blocks VALUES(310354,'437d9635e1702247e0d9330347cc6e339e3678be89a760ba9bf79dd2cd8803e0',310354000,NULL,NULL,'b2bbcbb6a7db94b2a5681c6e380ac13480bb49c29a3fbb3c7c1eb740f70f8324','49d2d049a5ee12aebb41a3a6177eb6be3ae6e0c3e38f1c3736b29ff6a0600b9e','c295087e31c231d27be21dfb5d1e76483b27440277c0cb6473940f3a5971fe97');
INSERT INTO blocks VALUES(310355,'ea80897a4f9167bfc775e4e43840d9ea6f839f3571c7ab4433f1e082f4bbe37d',310355000,NULL,NULL,'ccbd3ea41587c3c1d92f355979b49c5340a0a90060f07c228c22d6ff76b25579','3d0cda6a09453d5c1c4b57449e74cccb92a09c80dbad43d89798d723583cf33c','93df075ebff0a4f6185801e085d6ae6cc57550c87b2650cac85f1c374217db73');
INSERT INTO blocks VALUES(310356,'68088305f7eba74c1d50458e5e5ca5a849f0b4a4e9935709d8ee56877b1b55c4',310356000,NULL,NULL,'06a95d39e110e40ba318320d50984096cbec88c680f426f721154555efc2561f','de6a7a281c4ad171c7cccff7690a26aed6c58ed406182842f75dff14cbb2d859','f8df13de6c3036c572a007d5c1a5da815a217090feb75af244ed80c54ccb3412');
INSERT INTO blocks VALUES(310357,'4572f7f4ad467ef78212e9e08fa2ce3f01f2acc28c0b8ca9d1479380726bab1f',310357000,NULL,NULL,'443f947352e853367d1c10d25771c7d78eec22fac19c5bace6f96b8f949e264b','415ba7464a9960b688e47e777e01c742024e2f20dc61c508910e3936b226cd0e','de81cb1d1c717e720f32df7dae69a9ad809f05a57dc97f1d5b4ae41183c64cb2');
INSERT INTO blocks VALUES(310358,'d5eae5513f1264d00d8c83fe9271e984774526d89b03ecd78d62d4d95ec1dea6',310358000,NULL,NULL,'c2cd71dc9e7d5ccb5d5e9d6b55c47010c9db6a573d01820da1c8960970fd571f','29f1685407cf1838e814ea13bb6ac72d384a5d03cff9bed4b1f69e2d1bee03b1','f97a1b44731bc8902e606a50c3c810fa22878556e789bdd6938b1674f1270115');
INSERT INTO blocks VALUES(310359,'4fa301160e7e0be18a33065475b1511e859475f390133857a803de0692a9b74f',310359000,NULL,NULL,'5b7646bafc6b11eb1554ea1e02221883043b435ae973c3678505fa2128aadfb7','90e5e58be1c72ee3092504b1eec00563aa24fa6e9b638d5f4be818512ceb2737','5e83583124da28d04c40f8e09c021a7ddec8e8d01d35ba6015138e3004857a2e');
INSERT INTO blocks VALUES(310360,'cc852c3c20dbb58466f9a3c9f6df59ef1c3584f849272e100823a95b7a3c79f0',310360000,NULL,NULL,'b0e937568a47c244e3b29cfb3a5e7196c171acc1565c44020345c715b7774658','6a7ab3c46df34ce743057f8c54be2d09d6e0eb60c758b64b9bc4da73a788d0c9','1f4e7a7f1c2ff02f0c50a87538891d556726984fb9d45c19968c68b17480d820');
INSERT INTO blocks VALUES(310361,'636110c0af5c76ada1a19fa5cd012e3ee796723f8a7b3a5457d8cb81d6c57019',310361000,NULL,NULL,'fd5b67bb571f4e9c0c37c6a5c9e1181133c301e05f4f97a41bd827eda7a6db3c','78a74acd87985c733af23937d8b03dc447e6adb6f9817caf13dac5c7047e3354','629b2ccc8fbe62f01d099e7b6506472b27f554fb3a5a2c24d7e67e9dfadce600');
INSERT INTO blocks VALUES(310362,'6199591a598e9b2159adb828ab26d48c37c26b784f8467a6bb55d51d7b6390f2',310362000,NULL,NULL,'38382cc090b349809c4798c3c83b485f8ff682fd5b5b2568357d62ef30f7c046','ff21f978a1d4383d215defe9cf09b918d69e22ddf78879aa6c84a651084a3adc','cda1fb0b5d09fb2d3717d511c7dceb4bda560c7e451171021c2d2ca1ac600009');
INSERT INTO blocks VALUES(310363,'a31967b730f72da6ad20f563df18c081c13e3537ba7ea5ab5d01db40e02647e6',310363000,NULL,NULL,'82911a691937d87629bc14e5294f68a25ff2fc6512370db032834b85a623d5c3','f7ec2f1805efacc1382b16afc4be664c5f5f379364534d4996968abca090145c','68452b60297ee71032eb46bc1eb84fe8addaa6ceaeb01ae0f05c8a8ec62ee088');
INSERT INTO blocks VALUES(310364,'67025b6f69e33546f3309b229ea1ae22ed12b0544b48e202f5387e08d13be0c9',310364000,NULL,NULL,'cc362ce4c2142e539057430e2dd6402b985c62fefa4e4ad33afe1305f53af8a4','edc348b3d301b47ecda10afcecc0a43239aa4f75be97580379b155edcd147b4b','0e2666363f9bcec608ba3deb854ae41509081ee7d02bb7473d835fa43706c24f');
INSERT INTO blocks VALUES(310365,'b65b578ed93a85ea5f5005ec957765e2d41e741480adde6968315fe09784c409',310365000,NULL,NULL,'49e41f95f081b70e3f540fa22864cc4f229ceabfdfd54f2da112f1fd35466617','16cf1f37d2f49233858fc014551532bc0d5f31d6f9978f77ced5b84b5b49b707','b5eda136a7fcfa1b5d229c0af103e9a79e72798900538033ae99aad3d9eece93');
INSERT INTO blocks VALUES(310366,'a7843440b110ab26327672e3d65125a1b9efd838671422b6ede6c85890352440',310366000,NULL,NULL,'687c5f3e381d164499126ff90785e3635c825db3808267d4de2ec0e37cc7c597','7b12747ff17494198232a2ea646f17ae84cc3be13cbf366e2eba4b609cb630ed','a374bc0eb668adf1d050964efb1ad1bb53d500cb98201c7c1b7dc12d06b6ed88');
INSERT INTO blocks VALUES(310367,'326c7e51165800a892b48909d105ff5ea572ff408d56d1623ad66d3dfeeb4f47',310367000,NULL,NULL,'d7fe976a4b2cca2e23d082a703ef4f4739e110ce1e0a373e76064f6186856ff7','18e334bbe7d70a4f5c42a28ed7f3ecfb0fac600427408111525c3eb590361dbf','42e57d9fdb5a27a26f5916ffd79ddcd8c1f70f5c4fdcf63231b27d6e195f5b54');
INSERT INTO blocks VALUES(310368,'f7bfee2feb32c2bfd998dc0f6bff5e5994a3131808b912d692c3089528b4e006',310368000,NULL,NULL,'97f0a0f9e6f355dd179aa2941412decc1b0a06de0dc14dce8538aed6e35d41ba','289522320a1bf3d3ecdcf8ac7ca2f6afd4b00c1b39ce734330285005dd827e5d','ded9543b1ee4a58266ea06703eea93348e3f6912b08ffcb4d93d8aeb9919af66');
INSERT INTO blocks VALUES(310369,'0f836b76eb06019a6bb01776e80bc10dac9fb77002262c80d6683fd42dbfc8da',310369000,NULL,NULL,'1b5d9ec9bd918c84a5f9b6882c94a739cc1ad1362dedfbdf7b2009fd42251d66','cf6283e005102802148a0363645411ccddb087a56a5fd0b5bec9b21e5d638949','5fba4343f4fbbfaeecd2bab908e1c1fc8906ef3e9b8edab558cf155046b8872e');
INSERT INTO blocks VALUES(310370,'9eb8f1f6cc0ed3d2a77c5b2c66965150c8ceb26d357b9844e19674d8221fef67',310370000,NULL,NULL,'578b039ed2b9a25e1c75ad9a5242c5962d6645616dc53fb08386602e40f14486','c0da477f2abb6a785beb28be9627fb8d164f9864c2624cd3702c58b2b3d14dc5','b9ecbe66db8153b4a67468eb3c135eb391358ef248e63aa550384fda8ed31a5c');
INSERT INTO blocks VALUES(310371,'7404cb31a39887a9841c2c27309d8c50b88748ed5fa8a3e5ba4cc3fc18310154',310371000,NULL,NULL,'473d21b8218a2b02f7fa0d5daf114fa988e4a3d97c33aebe97e51a8d22252492','8e8ade427bcd233010286fe1d67d44061c7d4ba18681cf11066e2951b1847274','4ecae6b26b3f358c605b80b65ebd2f655298a71baf497bfd2453641b67311521');
INSERT INTO blocks VALUES(310372,'d3a790f6f5f85e2662a9d5fcd94a38bfe9f318ffd695f4770b6ea0770e1ae18d',310372000,NULL,NULL,'0c306eb25702d190ce32cac521b1fac9b8a7cbcf441fd74be8de2e002b4ce14c','f1396d85065a71408b9d5118328b067d7937b63c210f017c82631274b1cf741a','bd743e750525c5857a7f0d7b71830c0623a18e30012dc3b80140528bdde1b7c7');
INSERT INTO blocks VALUES(310373,'c192bec419937220c2705ce8a260ba0922940af116e10a2bc9db94f7497cf9c0',310373000,NULL,NULL,'48d14b17f9074ce1f75ab32581e8f6fe7d518ebd669af6508e5d986d97c92b3d','f1fc0cedd62fd55087aa5ad0ea33fbd520dbafb476e6f1c322fcb52dcadec3ea','9decd59a299a34bdbfb4aaf0dd1e82d6b11a0c82240f8183ad813c6304ebb3f6');
INSERT INTO blocks VALUES(310374,'f541273d293a084509916c10aec0de40092c7695888ec7510f23e0c7bb405f8e',310374000,NULL,NULL,'aee93917f6fe0046069aaff48d5d1875a9c4451acec6562a377428bfb1184cd4','a4ad7d71774d9b28cf839faa8bb6ecaa43f70d5a1f05c86d1b4b59cceade9eee','2e304744e490918eefa5160ed756d34769359b031baecd70a81b6fd824828802');
INSERT INTO blocks VALUES(310375,'da666e1886212e20c154aba9d6b617e471106ddc9b8c8a28e9860baf82a17458',310375000,NULL,NULL,'2b0d74911bba5c9530b69c04fec512fe4c5df25458e5237db884586a221fa30b','0e084f247a18754fa746c4741fc2b30e4e86bc6436c7f83232ce07040d6abbcf','0691a468161bb0368cd68e7f33e51e78ee0a17ec90cfad3e0592aa780dee388f');
INSERT INTO blocks VALUES(310376,'5dc483d7d1697eb823cba64bb8d6c0aded59d00ea37067de0caeebf3ea4ea7dc',310376000,NULL,NULL,'a6f84afe2845ba2fa4e5e7377b1d4474dbde6dfc9c4bed050e6d10cc80025e82','25924386c41e6863d14455e476c783e3471d56961ae09ce9201891728bf0b8c2','0055f9a1e5d3a35a9a839011242d6bc03345a422f0508f67ac0d9566b05be9fc');
INSERT INTO blocks VALUES(310377,'f8d1cac1fef3fa6e7ad1c44ff6ae2c6920985bad74e77a6868612ee81f16b0b3',310377000,NULL,NULL,'e006e13691719e4fce65e72c692d3affeae8ae465de2a3b285a1bed4eb518a70','94260a48d69ce6fd842f024e7e657c082ccbd7fa78da551df928128d19e377c6','e41008e535ac47b5958d45476707237d5f935fdede54b8954a8d7edeb082a500');
INSERT INTO blocks VALUES(310378,'fec994dd24e213aa78f166ca315c90cb74ee871295a252723dd269c13fc614ce',310378000,NULL,NULL,'607ffa4928577b82f275750353fcecc2e50098d227f18bb8ea95ac2bbb10eea6','c9f38122bf6b1d638d30f4125a3945d7efbf9dbe84899deec603910c4ad37a58','bf18248d166435940105a79c6c8b63bc77864b04c6cd59bb8a45b9150abf1544');
INSERT INTO blocks VALUES(310379,'d86cdb36616976eafb054477058de5670a02194f3ee27911df1822ff1c26f19c',310379000,NULL,NULL,'9f17e8d662dbbfc12a56dc36172b3154bc9b05a87885d1411826481e1ca4f6ea','54f38c2b86066b968d6f4a125a7d4cde3029104722c1d4e9c8cc25b54f6aea25','6f4f06ece8814b57ca284a33e1c9cb8c5896b4fd4955a431a6d2ae08043ae393');
INSERT INTO blocks VALUES(310380,'292dba1b887326f0719fe00caf9863afc613fc1643e041ba7678a325cf2b6aae',310380000,NULL,NULL,'d617e30e1a32ed1cf269a190fd4c843755413492827546a0b3ed14278f817532','e0d7e94f19fab7791f1e59d99fb0d90d9d979630bf47539e92b5e6dd33bdd739','58a9b5f3b6437019612418f80926ecf824ddec253983aa5aa0a64bc03e422a3c');
INSERT INTO blocks VALUES(310381,'6726e0171d41e8b03e8c7a245ef69477b44506b651efe999e892e1e6d9d4cf38',310381000,NULL,NULL,'8af8d819f02927de4a74d3d37dcecf6e5124d53be37603764b1b1adad13b0d7a','17f768a71f0b80ce379425c3832a203eaaa72b0a751efe7f3789bd4bf077871b','cdc47db076b613942f5c1dbd22f23752ebe2d94bc94cc27c64442c0573e4557b');
INSERT INTO blocks VALUES(310382,'0be33004c34938cedd0901b03c95e55d91590aa2fec6c5f6e44aec5366a0e7d8',310382000,NULL,NULL,'809d5c20335bbefe8e4f3552e24b24d96f6ee4ab12f3bfc9e74898371cf69797','c99acaf6b5c95cbabba99f384f277598509b58fab22e628f9f416d758a78adbb','01e4704adbe26ab24cec7dbf67d4f84bb8c82d5ebc89314347da01028c8c5704');
INSERT INTO blocks VALUES(310383,'992ff9a3b2f4e303854514d4cad554ff333c1f3f84961aa5a6b570af44a74508',310383000,NULL,NULL,'d8ec301994a5333f8efe7cc547a833d26c6766deb0b39c4fc18d1bdb470ee903','616b01d37c2d46887637a0a69e4bd6aec50474d09cf40ac3c57e59e8fa8a02f5','9f63f1a53410b0fb40d23f42b6ca2722622de46ed63f45fe2c2955fc30412cb2');
INSERT INTO blocks VALUES(310384,'d518c696796401d77956d878cbdc247e207f03198eabc2749d61ebeadee87e5e',310384000,NULL,NULL,'fe47a03993cb9079a6e72810552d631fe838bcfaba3b34c73c9948af77266df2','3a670f52fbeab1331e52555bf71933702800ddb749f7736d4148c11f3da66096','003a23eec1c3f64647ec712db652b88d1782ec2bf571c4b43c3321b91ce496c0');
INSERT INTO blocks VALUES(310385,'2aa6a491a03a1a16adbc5f5e795c97ec338345cfdf10ff711ffb7ac3a0e26e28',310385000,NULL,NULL,'6114e98e0004cf0f9472fce6bfa6bb99ae38e57214c8b134f30da1d62399f6ef','2146d67908ca24ee0e1a0c82ec8c6bc50009e47a4f9d6b289852662fcdef31b3','a3e12a3398797870bee91e535be2480d0b18a970c7f7b0633b67a33487d1af21');
INSERT INTO blocks VALUES(310386,'9d19a754b48a180fd5ebb0ae63e96fa9f4a67e475aeefa41f8f4f8420e677eda',310386000,NULL,NULL,'4c52d59ade1bd2068e3b75b8b3cd1d23c6a94b6437f7966d10f5a07bf8f630ff','dd56444ac5e10cb63457792aca1257f441d6afae9ce8707eff0a5114ca738892','5fdbd22a5886cd418e2395a25fc3842efe11c162a2c272dd67136241a542aa12');
INSERT INTO blocks VALUES(310387,'b4cac00f59c626206e193575b3ba9bfddd83bbfc374ebeb2838acd25e34a6c2b',310387000,NULL,NULL,'327e9a842233568888998ec1456b6f78c093b47639707d44e6336b2bc18d955f','88e484982a8266310c003163797d42c9f0d115fba7c2dd3b318a15054a6f4485','43810694ce2f2fb3da52034a59477bc49f67b475d3c107708d313787fee3ef33');
INSERT INTO blocks VALUES(310388,'41a04637694ea47a57b76fb52d3e8cfe67ee28e3e8744218f652166abe833284',310388000,NULL,NULL,'6efaab188a5cae39ef547a804f61bcbc2be4881e0569f49d7622b407f6860401','6a3381747afac000fa7e905b2e70b6c113d8d277db5a7e7a9159ffede155d437','cad82bdd1a13661f678901e8184b0d2b386ddcf4f9a146f5f445b07fcefe7ebc');
INSERT INTO blocks VALUES(310389,'3ec95ae011161c6752f308d28bde892b2846e96a96de164e5f3394744d0aa607',310389000,NULL,NULL,'89c686d5d973691a7281268c867f837b86b140a05f16f12302a3cdeb3b6a0ee9','fb27a75920b64dd345b4a8d60d3ad1af1f44f0bdb1d0346093520a761afafb25','8b0d4506e617d33a7bd442aa75061af103e4b1f7c28a82ad7bfb303ccf781add');
INSERT INTO blocks VALUES(310390,'f05a916c6be28909fa19d176e0232f704d8108f73083dded5365d05b306ddf1a',310390000,NULL,NULL,'2c4eceebb94d0c7a7702478d9547d1afbb42ab5ecb5ae6271a3f69942bd77e50','afc8ab9049a7a368128396f540efcd0a83b973d43b4f798e3e8bebb779d3d010','eb116ed17d6b344bd13a1be1b6b859b0baaad755156954ccc95cd980c9969d91');
INSERT INTO blocks VALUES(310391,'fc26112b7fdd8aaf333645607dabc9781eac067d4468d63bb46628623e122952',310391000,NULL,NULL,'06397124ee2a1bcb9104899469394855d4ecccd1a08626d650bdf3169e227831','b5af95d2f6c2e3749bd8848dd099b41d8eca472903c2aaead84f08c3a42d53cf','dabf2a525c104896cacc2b3697695b6d026dd4d9bb7967d1c61ffc5d2f988d34');
INSERT INTO blocks VALUES(310392,'f7022ecab2f2179c398580460f50c643b10d4b6869e5519db6ef5d5a27d84a1d',310392000,NULL,NULL,'44974b5fec0be3a2958d39f2d6824a2e82733f873a404ec9887178c620843149','505d070b123a773649ca8dce57ab6e2754f9d90088a70b09e00878f69027c4e7','5de25707c495833f6b7505133ad456fed095a4fb7b0e982ef0ad7d5e0ad75e81');
INSERT INTO blocks VALUES(310393,'e6aeef89ab079721e7eae02f7b197acfb37c2de587d35a5cf4dd1e3c54d68308',310393000,NULL,NULL,'1863677c0e552344607b1af3eb8ef8f4fc6b2a73d63eebb3e9928302c887970f','5a5c67b192064878690608c80ec9846803c261a2af87e897fad284ab2935a45c','f1bdff8e73f9bef9da481989881ea52dab9513d289ac61db85184b7195fc1234');
INSERT INTO blocks VALUES(310394,'2a944743c3beb3bf1b530bd6a210682a0a0e9b0e6a9ff938d9be856236779a6f',310394000,NULL,NULL,'3838ba6e84376ed8dffb3fee9b5928d903952c0d8a8ad41ab63a9651a1c8c770','c91e6b5d055c5112823c3d87858b75b7013edce5371a9665674e3c3f1e346fce','b19e1613753b076fecf841f1dfa3668a691f001a241949bacaf707d317c94c3d');
INSERT INTO blocks VALUES(310395,'19eb891ce70b82db2f2745e1d60e0cf445363aaff4e96335f9014d92312d20e4',310395000,NULL,NULL,'872367d61f81cddeb555da5f9c4f46a8ac57c24629ab073094e407a4555a8555','4c428863fc51ea61698a764dcd88f828814dbc65b56d990ca1c139691c596c4c','25f0680d90d7b8f699803f783917a02224ba8c988a8fa7e77b91f0fbc3d79612');
INSERT INTO blocks VALUES(310396,'aea407729ac8d8e9221efd9d70106d14df6aaf9f2f87dc6f490835a9caadf08e',310396000,NULL,NULL,'b9a9eaaf1cf6cfa4ae5b0f314812a9a2346209da0b7ce57e16010d2a01c0092a','d7a602d6ce046f8a7ffd4220e1bb2318257691cf30b35a0f6aa911c03641429f','5d8f3d8647c40555866d48fd85486ae1d4a3c0cdd6f8df984d79b6e8c92c32df');
INSERT INTO blocks VALUES(310397,'7c429e56a19e884a8a77a759b52334a4b79404081b976270114043ba94d7985c',310397000,NULL,NULL,'b61f36bcc934a18fdccf7806d41482684ca129801d0b9ce7815dcd488fc49a66','e5d7506a1e37f494e5708285c4619d5ccf5ff1134d404174c130dde6c583b193','9ec675bbdf960d8af7f49cd77885029dd0364fa2fd73af6689941962a7dde959');
INSERT INTO blocks VALUES(310398,'55c046db86dee1d63c0e46e6df79b5b77dfd4ab2ff5da79e6360ce77dd98335e',310398000,NULL,NULL,'9446476e123e5dd354682c60591cab8b712c30df9080dde756246eef45e21df5','35c20a4e7f271e2e0bf62b508c9f9ed733da456ccf293178e0047ee367ab318f','c3b9daa841f49ea27db9a789c3537cb00fb479525c1b59b216c3fa4dee0817f2');
INSERT INTO blocks VALUES(310399,'765abc449b3127d71ab971e0c2ae69c570284e0c5dacf4c3c07f2e4eca180e7a',310399000,NULL,NULL,'50d288bca09d446f56544fb1ec50d613bdf156488468ac92d433425a3cab0804','8e34c9c3005a861164837d28166eaa403231b533ab5c405ca4e3f07e1d37250d','05cc594a759537362e2f617273d87cfb0fef63119dd2e89392ea0b661e9eab47');
INSERT INTO blocks VALUES(310400,'925bc6f6f45fe2fb2d494e852aaf667d8623e5dae2e92fdffa80f15661f04218',310400000,NULL,NULL,'349a24fd446727bb1793ccf88fc569d20eb680c10e506fc25b281ce6ec3fd7bd','14e72e2828c8252029b31544a6908415765b0d0726eda833083d6f9e74cad750','b5b1529399f988839fc45628ab324177a9d3a12b37cb48148cbcc6e706da63a9');
INSERT INTO blocks VALUES(310401,'f7b9af2e2cd16c478eed4a34021f2009944dbc9b757bf8fe4fc03f9d900e0351',310401000,NULL,NULL,'52c06b68cad19608420b73476a73b411d0327382b92bd454cadf1b8616eb17a5','58e1e1c9f6e823de3bf07fdcef120d794c50566d70469a02872c513ff8cdefd0','00bf9490d255dbd10caf670bfbdc6a02f06f215b4d064c0c63c4309f930cecf9');
INSERT INTO blocks VALUES(310402,'1404f1826cd93e1861dd92ca3f3b05c65e8578b88626577a3cbad1e771b96e44',310402000,NULL,NULL,'8bf64213a454c62dd4b0dcd7dfa298da0244a6aa7ae6fff98be6f49d50d259ab','5b61a4a2f32afbaa8214a7e688d6462d449a1534040d545fa4db42efd755bf00','4ffcf2623f5cad8e7dc1ebfc1bf1ad55f489ad0722b3487211ce39c8ff7aefff');
INSERT INTO blocks VALUES(310403,'f7426dbd4a0808148b5fc3eb66df4a8ad606c97888c175850f65099286c7581c',310403000,NULL,NULL,'fb2a365372522d1442792cb38e1a4167eda2612ef442c776749097a3d541a827','88d8e78f2a62b006a15f81f3881809d7665876cf38d10d167f7c02cc92038a72','3e33c4e4e1441e200db80b6341986341730155bbfc758acdc6d6af4517de2a95');
INSERT INTO blocks VALUES(310404,'401c327424b39a6d908f1a2f2202208a7893a5bedc2b9aff8e7eda0b64040040',310404000,NULL,NULL,'47f96d798df9cad17667be908ebb063ab9f79d947784a78189d247e626864a5f','bc762bbe1e2bc5ac16c5e031734976d0356afc3588d6eead9d850572e1da2bab','370243e39d925739c8268366d82325619cb036d6c1aea7d5da92e9a9fa41e090');
INSERT INTO blocks VALUES(310405,'4f6928561724e0f6aab2fc40719f591823ca7e57e42d1589a943f8c55400430a',310405000,NULL,NULL,'185780205a9ab241bb0656799fd0d5942c1e3e5854abd1d06573da550b04b096','721c43020d2ce2f9b969b2d146682d6cb8bf5fde0a7d995b1d6d08e98cc0ba21','1ac998cc047f68524fafb5bf43361fe7fc86cbfe77778cc8d767286e01f8e761');
INSERT INTO blocks VALUES(310406,'6784365c24e32a1dd59043f89283c7f4ac8ceb3ef75310414ded9903a9967b97',310406000,NULL,NULL,'367b9de2313c5f7fce0c2dc2b4a8e2bc059f6881bc924f7315e8e2ca61728a59','1aad4d9b91690f632de4e156cf3e70ebe4893e44054d914c832a0c046f29da12','621e0c890e2bd732c240c2744b6abec3d2fbfa2cfee9aab0da554df1b99f4157');
INSERT INTO blocks VALUES(310407,'84396eb206e0ec366059d9e60aefdb381bca5082d58bffb3d2a7e7b6227fc01e',310407000,NULL,NULL,'2bdbd79575aa2ff52ba0cce3fc1a1aac6120d598a8ab0ff3925e1395e6cad2d1','9c7e5f7633430d42c2f0b9261d170a06348e35140abcae4d1afa6e002383d3cf','62c465a48d022e4775f63f51564ba3ceda144ac294635d0d022842dd447cb5cb');
INSERT INTO blocks VALUES(310408,'4827c178805e2abae5cb6625605623b3260622b364b7b6be455060deaaec2cda',310408000,NULL,NULL,'fcd0edef8c4ae9517a6e793a2742c598de38c122829b7a7aa265310417ac92c3','b60c0348477409872d277b6fdf514130b07f27aad2f582b4fe5e93ba74fa5b28','3648a0b454bce5ec120f35a2b15d12873aeed3f2b517f89e7241d03698aaacfa');
INSERT INTO blocks VALUES(310409,'01a719656ad1140e975b2bdc8eebb1e7395905fd814b30690ab0a7abd4f76bba',310409000,NULL,NULL,'5b663c40873af21ebc721f2689e2c57a2c787fff579c58f033bba75910a64837','ee3d1021480d167abe07e352ddeb94100ee088212e32049aefce1c582ffd6d3e','4851a2e370d68239076966929bf99f2b630ad7e7e22b530be37792773e49ec19');
INSERT INTO blocks VALUES(310410,'247a0070ac1ab6a3bd3ec5e73f802d9fbdcfa7ee562eaeeb21193f487ec4d348',310410000,NULL,NULL,'93c5a33931b2a33933bc286d6987b34730c0677460e4875d5c032ae86c2e01f0','84e8d6d5bc7f223f021d8d79fada23794404671e5729cef24601ffc58010ac13','34b5e222c916ff649792139afaf356e50e93d86c5453dbdac3790fab4b3ee974');
INSERT INTO blocks VALUES(310411,'26cae3289bb171773e9e876faa3e45f0ccc992380bb4d00c3a01d087ef537ae2',310411000,NULL,NULL,'8d98498f89619a2e334e9ac69bf8ff37251af6431d9bb6d1ea8bbc404c5e560d','cd124ba44cca5d154a8a27b6f154f7576837847055f8eca35e6c9f18424cf63d','703767dc1dce5c2df0b1fd143c539bbb2206f7b7db86b480d041faf258d115c9');
INSERT INTO blocks VALUES(310412,'ab84ad5a3df5cfdce9f90b8d251eb6f68b55e6976a980de6de5bcda148b0cd20',310412000,NULL,NULL,'a16a650c4b63ed783e7229980be1177da867c188a5039ed5c58b9717f6ccf634','bfec7984862635d79e9303da3af4399da92d67f8f130543825373c35fc06813a','f4abd7a8ad3131851538670e20f177c44f21674f500b809e4b37646652a03f3f');
INSERT INTO blocks VALUES(310413,'21c33c9fd432343b549f0036c3620754565c3ad99f19f91f4e42344f10ec79bf',310413000,NULL,NULL,'768577c1a7c2cf2cc19cd8dbe823f1bdb8a222daee4c7ac7b5ead6633040c283','747e4799a02bbb02feb104318490c4b816666384706a1705bbd43722b8090a54','ad1f6b9d2cb8a9c4c26c83a78aaf8da5cc3df72b2aaff5cb3e58d032b6b10db4');
INSERT INTO blocks VALUES(310414,'8cff03c07fd2a899c3bcf6ac93e05840e00de3133da14a413e9807304db854b6',310414000,NULL,NULL,'906c491f164877c31002da41233c237d0d4a945a0072406a7b7d13df74be7eec','604b893b5dbc3481a517161c7a0b2cd0634a6bef14c6235ddc2f46901c979c9b','e05bffbc054e6fe9b49b5d7d4fc7dfce4f15e4c10a4bacdabc78135dcdd59205');
INSERT INTO blocks VALUES(310415,'dd0facbd37cca09870f6054d95710d5d97528ed3d1faf2557914b61a1fc9c1cc',310415000,NULL,NULL,'d27f99b4a67dfc910d3b932f97b7299779f245e95f871140d3c90f13cc6e506e','3866a5985d755f89cb232e84ec9f70cb7a5260956c139b2877ed9158a857aedb','2392068f8ba7d151147197819a6392becad5624d02af036af811544ae7deedc8');
INSERT INTO blocks VALUES(310416,'7302158055327843ded75203f7cf9320c8719b9d1a044207d2a97f09791a5b6b',310416000,NULL,NULL,'90fcd04c508a9821e0ba0ed36cd7cfadd1d3c95116e3f52ad69f98d3d14de571','e2643c14bdfe531170d07ac22e3a570b7e406179a9d5a516b12e761efdfe3fe0','dc92e3ace8525206ae0679ecb997b0adeaf9099ebd20075c244ca7ab3cd0bc2e');
INSERT INTO blocks VALUES(310417,'2fef6d72654cbd4ea08e0989c18c32f2fe22de70a4c2d863c1778086b0449002',310417000,NULL,NULL,'19cbb26c6d24df5b110a5aae9b53a911a61b2086dde926273a1b0f66c1049e6b','eaa173abfa2df61b4f57bbcd7dc4987fc1f474fe78f89ff003877a93c2ce23db','a24426406838b6e0d578c232d6bfa42d1a9aefa1ee1ce705681101f171625e85');
INSERT INTO blocks VALUES(310418,'fc27f87607fd57cb02ce54d83cec184cf7d196738f52a8eb9c91b1ea7d071509',310418000,NULL,NULL,'2dc971d2db4e92e2d5dcef124bf9cdad33c41a71d6ae3db80297cb2257911f0d','300902840e0762042c4f93480fe1d6f1c5a58d6323ea96a7e52fbb85fd7399ea','77bddbcee2cbe28fa5a567a049a1258b776d3e92dd9b26f5c22bc427215bf385');
INSERT INTO blocks VALUES(310419,'9df404f5ce813fe6eb0541203c108bc7a0a2bac341a69d607c6641c140e21c8e',310419000,NULL,NULL,'7ad2bf141622a0db4b27b1f4dab4857d1595e3f746a4113992850a680ebf1f37','5883b63b29689a69110c59efddabad2e5671ef434626392aa874a0bca5fc8845','4ca3620dbce651dbeee2e0633878a4b7e1f4b43dd8c1a60013ddf1fba2610b41');
INSERT INTO blocks VALUES(310420,'138b3f1773159c0dd265a2d32dd2141202d174c2e52a4aeac3588224a3558372',310420000,NULL,NULL,'3602b26268d1bd3fc5f08f170e9767ff07c91f6976a1c342dc6b24f7ee98c509','bb1d674b5408e79a39a4ae74f64c187eadb336ee750c8ba4be4d558ba935b000','961e75f57d75ca758d21546d993ecf1044f447a2945af2165d4267defb5b7cb0');
INSERT INTO blocks VALUES(310421,'71fe2b0e02c5cad8588636016483ddd97a4ef0737283b5fd4ab6ea5dc5c56b9a',310421000,NULL,NULL,'1c1facfa3852b33c173a08d06450335a2b230541c60973a154e8dd864f3c3c8b','d9dc190008a3c1d70819a8a07c3d6cbfbc8f35419c2cda530807da7894dab869','aff83bfb8c403616a262a8067bc7f8798e2063863ad546d918bc83ce9b193d3e');
INSERT INTO blocks VALUES(310422,'cd40260541b9ed20abaac53b8f601d01cd972c34f28d91718854f1f3a4026158',310422000,NULL,NULL,'e788123aefd1129554fa2c166dbd06ce68f913730183ca73cf248c1f5284eba4','28b4e1986da978533bdab54974c709ab300a2ff4a09ec1ae31e2931c38c70888','0886d85c7529d022a9b888d9d8ed197226a77fd6136205980d13b91962ba6dfc');
INSERT INTO blocks VALUES(310423,'6ca0d6d246108b2df3de62a4dd454ff940e1945f194ba72566089f98ad72f4db',310423000,NULL,NULL,'ad445e5351af8739b2f74cbba8b44201c20ab55ad1db064402614fb97f35c375','4c2efd859e81024fb1539ee3a0f00053a1796ade0f2f8b474751fa83266472b8','03d8f539d08211e9e4b597713bdcc1b6b228447f319d1ffeefbd5bc5d1d061ca');
INSERT INTO blocks VALUES(310424,'ed42fe6896e4ba9ded6ea352a1e7e02f3d786bfc9379780daba4e7aa049668ad',310424000,NULL,NULL,'e89872ed802fe4421844882958fe6384cf21a85a6dcf10db761e2bb4a77ed24e','d4a242f40e666764acb2d62187e1c1599d3f2bfd4f5af29847ec9490c3cd1834','d06153ea34289af41c093d82ae7976cd2a5605c17fb74c72cf5dc7f5502cdcbe');
INSERT INTO blocks VALUES(310425,'73f4be91e41a2ccd1c4d836a5cea28aea906ac9ede7773d9cd51dff5936f1ba7',310425000,NULL,NULL,'29e595e9ac7717013cfc8d12255496192234abbddd8a66762a5eaff0c49f3750','0c647eb9eacc74becb621996dfe54aeaa29377aeaaac19765fe542b2482505a5','a4cfd08efae020ffe99b6e8d19395d8b6e7a53f23c6874020383be2dc5da9a03');
INSERT INTO blocks VALUES(310426,'9d28065325bb70b8e272f6bee3bc2cd5ea4ea4d36e293075096e204cb53dc415',310426000,NULL,NULL,'9b9509ce7b7bf380f4d030604810a755c71fabe27152be990997a6a9db37ff15','48e9de57ca983381d7de8e4758a08a3eaab2558c7515532f2015f1074625c112','fd928674b7ff4dda8b87596b37c44ace840c613bc5cee7d591c6a85f4fa8b6ab');
INSERT INTO blocks VALUES(310427,'d08e8bc7035bbf08ec91bf42839eccb3d7e489d68f85a0be426f95709a976a2a',310427000,NULL,NULL,'f1b834e2a380f1b9a78c592acbe78ec809220c620e15f296ab8d7ecea6cd392e','827262a02a0de33109ff63f88eeb2c422b81bad1806a392fc7d660f99b13d263','9c70e84c38045d1b1fa5978c1f66a758d99b1c8bfb7b79a8e547d318f9accba1');
INSERT INTO blocks VALUES(310428,'2eef4e1784ee12bcb13628f2c0dc7c008db6aaf55930d5de09513425f55658a2',310428000,NULL,NULL,'9e963a17fbc4a5c20d48094f1459959033520f92d7a8bc044b71bbffb8dd173d','cc6b7331cf4e478c6b74e4976205ce09405d773247f1a1caf0df64caa1318de4','ba4af77207ebaed9d2edd6e120bbd7e33e2b3882cc9f56c7ecdb540ba6c47f3f');
INSERT INTO blocks VALUES(310429,'086bfbba799c6d66a39d90a810b8dd6753f2904a48e2c01590845adda214cf8d',310429000,NULL,NULL,'ac8cfd965b9c53f32731a3e0fcdb6df5746d646b02c88b5201a674125e37eed5','2a0e448cd8220509aae3e6e683f112a16cccf6e58917d8c895c867e51ead71c8','f34e0d189cd567f10e7714e3d07e7d124d8beb482722f6a42f27a50b58bf2522');
INSERT INTO blocks VALUES(310430,'870cf1829f84d1f29c231190205fe2e961738240fc16477c7de24da037763048',310430000,NULL,NULL,'33654e32dfd41ff3a5744b57fd2483a08a2b4729c18ca54c3ac5d95a1bf0ef21','8e24d513cbb9ff4c7ec6872a6b0694f4425aca3bd099f9fe0b66a30744abee05','aacbfb99291c682d3eb2767aa4ab87bf61fa1edd532a4fcc69ba1a2d1b146905');
INSERT INTO blocks VALUES(310431,'20b72324e40ffc43a49569b560d6245c679e638b9d20404fc1e3386992d63648',310431000,NULL,NULL,'ba8837c811ae87981cc37cb49438d958fa58dfc5a95824040f2fd088465406d1','2a4c84bc0d7da01acb2bd4f4322484bc5ea2ad32d0efe5123bf3a52b6cf691e7','bcde3724e99ffd4f1691e3da2cc7bd6cdb52da5cbc43b57bcecb1632d4105ae3');
INSERT INTO blocks VALUES(310432,'c81811aca423aa2ccb3fd717b54a24a990611365c360667687dc723e9208ad93',310432000,NULL,NULL,'7864019cb0cbbcd895154421183d6acb932b1d64441103b913d52469f656655f','5dc335adaf604205a12d19d2567303652db932b6a163c9ff54be906e7da9c5a6','94df9e98d9e57d55ceda1bee46b5ad91e06d7587d147cb79f4954db1a3cfa5e2');
INSERT INTO blocks VALUES(310433,'997e4a145d638ad3dcdb2865f8b8fd95242cbc4a4359407791f421f129b1d725',310433000,NULL,NULL,'a6da92ef0df7d092de09f2f8d2c99ff65ad74e2a0bd2ea25f8335614372f5279','ce60e873eaa65574802cb41efa409feeee92a46c6a4d51f6e1e6aa95312270b0','4b648adad7f21273e1aa0f9808dbb8a70488d0dc9f6a2c55fa2da040cdb1bdac');
INSERT INTO blocks VALUES(310434,'61df9508e53a7fe477f063e0ff7e86fbb0aef80ff2ddedc556236a38f49ac4d8',310434000,NULL,NULL,'e288db28ac6a42822f85fd042f65b57378bc6cc2f8616edfa88143d7b1c9ddcc','c1e683e0ab4201507ac2535d5a7a469d98a2597f7ef151f5db22a8a197707460','fe80733674530cae1c99c5a1ca40047e408b601ca4baa01192fc5e6b11917080');
INSERT INTO blocks VALUES(310435,'f24cf5e1296952a47556ac80a455a2c45da5c0dc2b388b51d235a3f741793d5f',310435000,NULL,NULL,'e87af314e8d7a5f2315ccc559d7c2255c008ba63aff017696201db69344d423f','a4e793b17dbe82da719637f8b776633f6a409be4393ea3dea4baf0c1b02d4d68','31edeac0ca44d833e362cc001c42f4f9fe17b78a998676f1e2ff7a618582f08a');
INSERT INTO blocks VALUES(310436,'a5e341ba92bdf9b3938691cd3aab87731eba5428bb61a804cecf9178c8da0c19',310436000,NULL,NULL,'82327b93bd3ffcdf797bc2f6470b9c8c5101e54b924ec5f141a31356aa8865c7','d7242b41ecfc6588b7674b8c7b14937170390a48bb340acc9f571e15675bc4db','1d28b167d78fe413e72e409dd6c4634cabf73eb13cbd2b60aaa378c40c75176f');
INSERT INTO blocks VALUES(310437,'9e18d0ffff2cb464c664cefc76e32d35752c9e639045542a73746f5ec2f3b002',310437000,NULL,NULL,'70d86f9ef8df495474de06b94e1857693c73d9ca3528356b82553a52fdce0dda','b10d9ee7bf8b1e63f724d293fba510f3671484476182b5656c5a590227fe69e1','cba36f376a701b344b0b60efe68ad3aaf85a6b5ef847468f7247668df5fab5d0');
INSERT INTO blocks VALUES(310438,'36be4b3470275ff5e23ed4be8f380d6e034eb827ebe9143218d6e4689ea5a9fc',310438000,NULL,NULL,'44b90478e32373205462f0fb212da636b31db6dfb99a2b56923beb97a3a64722','719f7e5ac1f0564d1425ac480fe957db5e9512dc645a2220e3dd44852a066c4d','c69692e9f2d74988796b8caa64a3ed445d71fe73bc26e11cfd99d811ba7c22ff');
INSERT INTO blocks VALUES(310439,'4f2449fce22be0edb4d2aefac6f35ce5a47b871623d07c2a8c166363112b2877',310439000,NULL,NULL,'66b791b9deb7d2fc8b075f41d712e300ffa9c46ca9d6f4e7cec6429ca6a65163','d1aabe2782e3d90acba2c040aa38e3b1516a1f0201f8ff0602f2e0c0c52e00b6','9ac46647483f04a4ad10766cc63ca38153b6911f64bed752639416394d02befe');
INSERT INTO blocks VALUES(310440,'89d6bd4cdac1cae08c704490406c41fbc5e1efa6c2d7f161e9175149175ef12a',310440000,NULL,NULL,'5baa10e1659182ba4511f87f08deda38d5de3501c63efd376604cc199140d27c','a5d331c1b48f85f8fc59ec5b69b36c12dc07393b7846b66c1f244d546f1018bd','8da17a037de017eb957a8ed0c52d10ae788c9fefd54d73d718a174cb79c0aba0');
INSERT INTO blocks VALUES(310441,'2df1dc53d6481a1ce3a6fee51ad4adcce95f702606fee7c43feda4965cf9ee15',310441000,NULL,NULL,'2d490229fead1b15a8350da7bcc83c483dae06e4a2f574c6e8fde248acd449d6','eafe7133ccb403f6e63e4c22172e2af6c75ef2daf580f1da71dfc00dcee7df7f','36503cdd6fd72e3b3dd5d5b74a47b3d72e9a48bc41425fc1c58810e2aefdc0be');
INSERT INTO blocks VALUES(310442,'50844c48722edb7681c5d0095c524113415106691e71db34acc44dbc6462bfec',310442000,NULL,NULL,'a3728bacfbdd289b7af24248b9bdacd5643bd5412bb993f5380278631eabb9e9','c2074eeeb7c6bfff82482f2ef367c07ea67870346a20fb7c985cdc21c41408af','6e3e9e40bc6a8e3b121838d7c66cf9f7b47084c82957305e8a7b9bc06f3ddea1');
INSERT INTO blocks VALUES(310443,'edc940455632270b7deda409a3489b19b147be89c4d8f434c284e326b749c79a',310443000,NULL,NULL,'d829da764f6397b22a6b97ef396b363ef2cf071990df2dc9c0d03806db6a46b5','3964959be7c6f3bd42e8ce644bfe61205a0ce960408b6e5f551be44d267a95d0','fdadba004f6fc961261a6d3dd482eae4e96cebb3b63c863d08fc0fdbc097dbcf');
INSERT INTO blocks VALUES(310444,'68c9efab28e78e0ef8d316239612f918408ce66be09e8c03428049a6ee3d32e4',310444000,NULL,NULL,'ef53249bf0f13e1f2073b815c8d8da3ab744b6d277b29ddbc0bd68bd006af34b','6ccc645366d0723befecd56beb1da56b72cd9834a9128903f0747f064500a75d','3c9fc11d66877be3cd38cefde6b260d00a76c451bbb4ca6e0ecc60fffdb9fd98');
INSERT INTO blocks VALUES(310445,'22a2e3896f1c56aefb2d27032a234ea38d93edf2b6331e72e7b4e3952f0234ef',310445000,NULL,NULL,'7e731cda90932b2b4844abdbc3ff60683173104e6c72ed81c65d9a17fd4872dc','c09b5fe5e683ecec9102aa5e18f97f337b267b219e291781e67f66f971118137','e7cce07bb69e6ee9a486a484abbaac2a3fdb7b9897e20facfb21570a4dc4b33a');
INSERT INTO blocks VALUES(310446,'e8b0856eff3efce5f5114d6378a4e5c9e69e972825bc55cc00c26954cd1c8837',310446000,NULL,NULL,'db55bac8025e95a567ba984f36dcb09357aa3e9b8706bb594e669b628d4e7204','2104fea62456cf8499d75f68889574ff3fb5dc32458dbb8b7fe8781f23ba1840','6219988d1f4cb0c79eba8bd6781c79d155ae92db75f59f7ab7df724c7b37ebc2');
INSERT INTO blocks VALUES(310447,'3f4bc894c0bc04ee24ed1e34849af9f719f55df50c8bc36dc059ec5fa0e1c8a8',310447000,NULL,NULL,'5cc4fa447cc291ffcce7be3c4f8fc70041bf8af5c2dd591136d4a449095d2570','4a9ed0cbcf6c60a5b8dc310df8b49e16798d42f1544109b8195bb29406b6f7d8','d1ac199dc46b93087abfeacad1fb19b606f3dac862f506c0abc400676a8594ba');
INSERT INTO blocks VALUES(310448,'6a6c7c07ba5b579abd81a7e888bd36fc0e02a2bcfb69dbfa061b1b64bfa1bd10',310448000,NULL,NULL,'ce49854f4493c163bc891888f920fbc6dd8855c30870beb757df69b33de52633','efedcb221de2c016534b039c214fee82cc57d186e31d57cf6bd46586d87f80d7','5609dc5ad865063053375aa06d3b5244507a5d34bf7197ba2d62cca72a12ea08');
INSERT INTO blocks VALUES(310449,'9e256a436ff8dae9ff77ed4cac4c3bfbbf026681548265a1b62c771d9d8e0779',310449000,NULL,NULL,'84557595cf2067a95924119b8ed5fea114acd9ca1b0df4dbe4ae5181a739b5d1','4e7fbabd657f23c19a599988f3b617af403324ff7db561a046986391986ce504','4cdbd317de86d0456703a3b3759354a1fb9dc033a551d7f0890a10fe16f14742');
INSERT INTO blocks VALUES(310450,'2d9b2ccc3ad3a32910295d7f7f0d0e671b074494adc373fc49aa874d575e36a3',310450000,NULL,NULL,'0e3b252b73fb652f904780da9fc59d1081d712337a9b15cf1a56ea72fbe96c73','d4d72fe2390340f7d31d58f298197c1dfc743d01399e345471e827b9b217f6b3','d664363e3409f0c4d4aa25df9fc7441371f3b0204f6d9294708b2f4ae7c239bd');
INSERT INTO blocks VALUES(310451,'55731a82b9b28b1aa82445a9e351c9df3a58420f1c2f6b1c9db1874483277296',310451000,NULL,NULL,'790eccd04e24e5f10f843d63bbdc1538cf1aabb0e8e6c862104be0ef845f603f','230eb8d94207c9fc9489993cc0faba2a5454f168019f4c948c05b33c060029b4','37e49c9138c0a7d5acb562caecc452636fb5516c36aa471db0349ad0de5a3412');
INSERT INTO blocks VALUES(310452,'016abbaa1163348d8b6bc497cc487880d469f9300374a72ecb793a03d64572aa',310452000,NULL,NULL,'30962129b060b63050fe8f249592587d74cdabc4ebb5680230a280da880c8586','71384d7fb14c374806f77ec374c1e3612aa05b5b8de490b06cdbd80dad3c2e0f','900d864f3c0058ec17d78e8e72f6cf15618742531da00421c4e16f6cc60567bf');
INSERT INTO blocks VALUES(310453,'610be2f49623d3fe8c86eacf3620347ed1dc53194bf01e77393b83541ba5d776',310453000,NULL,NULL,'56f4aa1086d8985a00cc295cf9618d976e69ba426b0c3d103bea6b47b58e4355','0c4fc005705e474e83826e77972e09684b876fc2012114c0f9749dcd4a521ad8','03673838eb57973c9aca69825cbbdb52e1e5fc14be6fc996f8ce6e174d4bfb67');
INSERT INTO blocks VALUES(310454,'baea6ad71f16d05b37bb30ca881c73bc48fd931f4bf3ac908a28d7681e976ee9',310454000,NULL,NULL,'38d14a206003b812cbaf5f200235dbe12aa6a674e5f3379cb186a781cb5a5654','93c1e481e63094ba0acb87b00c9e536ef9cd3bdcf4f42e975de1732e0c5382bb','954acbf0ea0972b61c22ec4f3396ef30db85d1eda63fb6b18eb55c4dee94c695');
INSERT INTO blocks VALUES(310455,'31a375541362b0037245816d50628b0428a28255ff6eddd3dd92ef0262a0a744',310455000,NULL,NULL,'b2ff303a67c05bc12fcdfdb774ea4ddc690434c3371428b3416d38105f265f28','596f4ac708d1cf820b951b02d62961264e8c05f3fd98fe8ca2d1383a019e949d','304845c5e3cbc4bbe3ed8aaac44ef393dd318842423f71a73643c0163a683efb');
INSERT INTO blocks VALUES(310456,'5fee45c5019669a46a049142c0c4b6cf382e06127211e822f5f6f7320b6b50fa',310456000,NULL,NULL,'6cc16b442fd7758ed7bae9f50367fa60debdb5d81bffc5abccda044573aeaf15','9bbff8d29712375735abb97ef018493ee73915236c5419b43fe6e4bdf8d40718','a496e95800025eba786c40679ad3adb82e771eb393a58dd60c157c81c078ddff');
INSERT INTO blocks VALUES(310457,'9ce5a2673739be824552754ce60fd5098cf954729bb18be1078395f0c437cce9',310457000,NULL,NULL,'8fa0401d245b1b1e8b40760a54f331564d8597e242462ec412878e36a9b06800','d6abc7e4c3a17be2cbde72dc975203e403b9287370776e98fc5d01328b1b4d69','45828f2b4130f952cf3c2680f8a1259d1a8a9cda9bda13dd76fe70bc89fc659c');
INSERT INTO blocks VALUES(310458,'deca40ba154ebc8c6268668b69a447e35ad292db4504d196e8a91abdc5312aac',310458000,NULL,NULL,'520f92700e31b8a35260a280ae11bf8668b0e09d34795a9d88678f2977e19f7c','14fdef76d2ab34ff8bde25d16e18d78c8d19236185acc7abef28ea5e5a779487','d25edd70e9064bd407f10089f5aefdc9ab10660e0e5945bd502f8e16533f2f0a');
INSERT INTO blocks VALUES(310459,'839c15fa5eea10c91851e160a73a6a8ee273a31ab5385fe5bd71920cbc08b565',310459000,NULL,NULL,'d7f728b78228a914b8767a6caeaf2267e9dbd50490a27f6c23bd96060eab8ee0','62170515ad9163cae5e94ead38c6b3c017cdd873e7567d5747f43d21facc7f49','f4f6e2674a8a4247784960c7019728eb01c9736f65d83a8e82bf0c64fb721492');
INSERT INTO blocks VALUES(310460,'9b5f351a5c85aaaa737b6a55f20ebf04cafdf36013cdee73c4aaac376ad4562b',310460000,NULL,NULL,'33c2b4c6d22888448a2458ff2ce6a1cfae5e858acae2a57e4cc0232980f8fa4a','52e3fb9a3215fe0153dfadc4cb72fabe7dec92cc5c96bb0e3fcf73bf2f25e9a1','bee587e8b2ee173e1d528a28f0f88995c34c65857338feb7467f496f42c6887c');
INSERT INTO blocks VALUES(310461,'8131c823f11c22066362517f8c80d93bfc4c3b0a12890bdd51a0e5a043d26b7b',310461000,NULL,NULL,'22426912d3317922912326da552af284677c9b76b6416b6c056668f27ae4f19f','bbd91e17d61baa378842ca799f0a182ab351b1e3057db292537d0fd821965896','38bf5aa19a39f836b02f0634a986ccc1ef7cf010e8d9bc83255ee60a10eec257');
INSERT INTO blocks VALUES(310462,'16f8fad8c21560b9d7f88c3b22293192c24f5264c964d2de303a0c742c27d146',310462000,NULL,NULL,'74225b62e696aaeafbd4d6db40b41081c7493d9cc44984729d8619ff9450ce32','42575e166f903577d54fa52731396b46ba89c985916ed31d48dcfe1cec43bb77','2caa171a6e1d22414be79c604011a04eebc50aa5d183a30df10a4b5f9580bcba');
INSERT INTO blocks VALUES(310463,'bf919937d8d1b5d5f421b9f59e5893ecb9e77861c6ab6ffe6d2722f52483bd94',310463000,NULL,NULL,'b970979bfe0d44ae2f21f7d98bdcc4ae37287b93cad9fa51f32a62337ceba0c1','c782662fe7f3f742d152ada347e4f0b6864f733f4782ddee46ffa6aee08c3088','b7d63a046fbece814dd73f8230f4f7c5b3f36a2a3596f1c8808a4ce1d124c84e');
INSERT INTO blocks VALUES(310464,'91f08dec994751a6057753945249e9c11964b98b654704e585d9239462bc6f60',310464000,NULL,NULL,'00007a158b003fcca20c9fcaa8d73a556f0206bc9a7ab3e5c566ea1bda8648cb','7256458b6ebf01451110cc10b04672f12306c6140e664f702feec7f6c8b9b0f9','b6bcd4993e9ca1aad4abe0a760e22a342b21fe4c37b3b666c7dd38c7091391fe');
INSERT INTO blocks VALUES(310465,'5686aaff2718a688b9a69411e237912869699f756c3eb7bf7c3cf2b9e3756b3d',310465000,NULL,NULL,'09c407870b056db90148a9e4cb8ada003898ff28c584bec6a5be90514758a851','722960d9e015d1167c7ccb802855af5b1a657b9bccb76b1d1b258140d0c0dd55','d9cf916d7a106a2ce9db7957630fc961cdec05e7534550710b14703054943339');
INSERT INTO blocks VALUES(310466,'8a68637850c014116da671bb544fb5deddda7682223055a58bdcf7b2e79501fc',310466000,NULL,NULL,'23bcfdbb44d8fc2ae6a86ea073ab080158014f04516b256a70d846399e7383cd','4c4be75ff04d95e0ae90779e9e031a2abff920290837e9d4218bfef3df9a02e5','6669ec88a641c466eae4b4a082e040b766899088aa7cd81fd7543db425b596f6');
INSERT INTO blocks VALUES(310467,'d455a803e714bb6bd9e582edc34e624e7e3d80ee6c7b42f7207d763fff5c2bd3',310467000,NULL,NULL,'a43abeddb61ad99d57f208cb0c6cc3e0b05a200009e6d90641a2bc7aac707adf','dcff629bf8e9a1487879f8c7047da2762f3e23b4f67c950c4e8c475dfd688a5b','13bfdb2e67f7f6a9cd34fe25c2fafdf4612b9eef0ddfcad23cc0572eaa1a85e2');
INSERT INTO blocks VALUES(310468,'d84dfd2fcf6d8005aeeac01e03b287af788c81955612375510e37a4ab5766891',310468000,NULL,NULL,'fc909facd6ba38fa0908fd49a6e2f25bd8284de5265ef761497b8a2d595344b3','de0c4e553db424fcd2c9ed6025f1e0141dbdcfce6faf84e67576fc3b0763f916','bfaf24c45a6ce75aa4b2fd161b8b32a0b13da661fbd16b8e297cd06e100647f0');
INSERT INTO blocks VALUES(310469,'2fbbf2724f537d539b675acb6a479e530c7aac5f93b4045f4356ea4b0f8a8755',310469000,NULL,NULL,'09f0d1c9bde8cdd63544fbb5eab46c2954654d32f3736f9975cf860588aa65cf','5b1ec9c5f86e525f31fb2385b5186181fa3bc93ba97c344c9309d5815ca0e02a','8c49156118977dc1916f4eea55c12077c586fbf41c04277c8cffd15762a3c123');
INSERT INTO blocks VALUES(310470,'ebb7c8e3fbe0b123a456d753b85b8c123ca3b315da14a00379ebd34784b28921',310470000,NULL,NULL,'41832b12459e778621b8f576e597b9f639390338605b30e5be28423b016b199a','871bec82e1157da89ec6d0adaff0be01fa894bdab80acf79c6d0b33d1c3c8538','3464fc739b6c7eb1567f60ca751b73e9691bae8cdfd357b5431de39c53bd13b1');
INSERT INTO blocks VALUES(310471,'fc6f8162c55ecffeaabb09f70f071fd0cb7a9ef1bccaafaf27fe9a936defb739',310471000,NULL,NULL,'bf701017153742cb597353349c90ec66f790f222dd98d617d98a0117f1de3274','446d13b0bb30f4697e944b4c84fb88b3e812706e88ec8872f967f153a787dac2','66b7fbdde44c7e3110c5ad1338aadd9343809ddfc8fec78fa825eaab0338c521');
INSERT INTO blocks VALUES(310472,'57ee5dec5e95b3d9c65a21c407294a32ed538658a6910b16124f18020f16bdf7',310472000,NULL,NULL,'2a162bbd5a20f89a39156995658fd0c4715881bc130922d0edf95b60ece60b9c','3dbef02555e17b6024086b9f044ad07db30b1bb9b69d02292298e9f91db87e51','f82a5ce38ff2e79b48bb0049acde7567b83a9dd913f7c309bcc9668c00244032');
INSERT INTO blocks VALUES(310473,'33994c8f6d06134f886b47e14cb4b5af8fc0fd66e6bd60b3a71986622483e095',310473000,NULL,NULL,'1ce10996ec9e37d8ddc204f038542c6781da88d2d45bae1952a88ab993b81e88','3df87575a31d9756719c0d4dbb41178c80295030c9af0b4dac292e775ffa9087','7e5ec9d6c31ef47db0241bae402eff804fe1074515668d42c25235fed65c1899');
INSERT INTO blocks VALUES(310474,'312ee99e9526e9c240d76e3c3d1fe4c0a21f58156a15f2789605b3e7f7794a09',310474000,NULL,NULL,'5ae424c24ca30aad5aca8298a13ae9371f55b15bc789c7731d833c6e7c7cb04e','57c0f2076e5c4274e4499aa01c63b27385633b32d713da637863ed302ca4dc7e','d30a72c8913610666d0037cc4a31323bd7cea5af1c10849f8a895ee66f311213');
INSERT INTO blocks VALUES(310475,'bb9289bcd79075962117aef1161b333dbc403efebd593d93fc315146a2f040eb',310475000,NULL,NULL,'b9b257efe76a36c340629ceb265822dd10449a08eadc69667a8ea05af5c052f8','6f322a709bfbbda9243f799ce668b33c6ccb7e6bbdcc9d20d40ca1e1dc69fcbb','6d661966c1478ebbcc65eb66d631d650c70d2eedc62e81785193c216ec857156');
INSERT INTO blocks VALUES(310476,'3712e1ebd195749e0dc92f32f7f451dd76f499bf16d709462309ce358a9370d0',310476000,NULL,NULL,'070c06b36f3a77c04fb4bcc3ab1045e95f198f3f970846e59c35db0d03cdaf2c','cd9c686ca0850709224f3c25a519c8f5ec0757fa2a14b20b5baefd63fcfc2586','69bf375bbcc0a6d21be4876170256fd5732e6371c14d9b00b0dc2e5403bc44ad');
INSERT INTO blocks VALUES(310477,'7381973c554ac2bbdc849e8ea8c4a0ecbb46e7967d322446d0d83c3f9deab918',310477000,NULL,NULL,'4954596dd44d112fd0407c215be3c9534a348d6f708ae4a1e66527d1ac2830b1','3939e2190968336d00d20b087dceabf7770706f073bf228d281ce931c8ade9bd','c9ff1f65db03fb29f53ba0067aa5aeadace75478c0ccfbd0c7475266b132701a');
INSERT INTO blocks VALUES(310478,'c09ee871af7f2a611d43e6130aed171e301c23c5d1a29d183d40bf15898b4fa0',310478000,NULL,NULL,'d9cac2e29863569bc96aaf022437906a534968a17bf965c54bf59931cd92e590','697ff4dc9bc4a306f5edf7ec498a599bbe4f45e7f36b0cd17e12509bcc9dcb31','8c98a668358fb54dd1105a97a4cf73215fdbcf05e79160f0472d18894ad15a5b');
INSERT INTO blocks VALUES(310479,'f3d691ce35f62df56d142160b6e2cdcba19d4995c01f802da6ce30bfe8d30030',310479000,NULL,NULL,'2e48a89a55b6f368745e1c022683e93c20bdd920011518f18fd936f2190ac5e0','113a40602fad45741ae3755305d2df2535429e45dc70c66d348bed7b6809a659','4da130400fe0276bb8a9727bb9b41afe00164629142f77f387d6f990a1a327a0');
INSERT INTO blocks VALUES(310480,'2694e89a62b3abd03a38dfd318c05eb5871f1be00a6e1bf06826fd54d142e681',310480000,NULL,NULL,'aa54124d86e74bebd14ea481ac2a5a5186236ffe214747f1af11ac370565525c','b1d9ea45e3f96188c38f1858a4e01f1e109a935888c595898e0e7ee9dee8aec0','d0108a908995f267eb98535290ed2126beaa1334dab61abf224c78513fe447d6');
INSERT INTO blocks VALUES(310481,'db37d8f98630ebc61767736ae2c523e4e930095bf54259c01de4d36fd60b6f4a',310481000,NULL,NULL,'fbbe1266bb773e5a3f5b48e82566ff75bc74bfea9424f81f670952565db15c59','2e82bf346fb757db69196724fcde1ab261e2de307661c3301de495b1b3b28d00','4add23473116b3b6b471643d1a7f7794a9feaea1a4eb52e01fb79ec6f0000538');
INSERT INTO blocks VALUES(310482,'2e27db87dfb6439c006637734e876cc662d1ca74c717756f90f0e535df0787d6',310482000,NULL,NULL,'bd28a97e90054319c4c301c3e99d68aaa5e1bf5a145a8f2c4529040bb8137209','a96ac11317e79c201ec12563997f9a440377a9174ea9c25c53509d086ec1bbd1','f77563b88a09eedf72cfff01b8aadd2c0e79b62f92471e1cd166997d53149e00');
INSERT INTO blocks VALUES(310483,'013bac61f8e33c8d8d0f60f5e6a4ec3de9b16696703dea9802f64a258601c460',310483000,NULL,NULL,'fbbeacec99c9ed99a7fc37cdd5673fe8bdce08eba7fcb25b696e262af29ca5d8','6dbac8f3e3000c9767b24ce9a3c41fbb70a566ecdcd4cde146a55ecc1e182629','9579ca4c9b680b5f0a3aabe4afa30501bac13eb623c0f69d57c74eff7463f1f0');
INSERT INTO blocks VALUES(310484,'7cac2b3630c31b592fa0497792bed58d3c41120c009471c348b16b5578b3aa2b',310484000,NULL,NULL,'310bc7c61c1325ee3f97e888658fd74e1fe4adccef4924abb6978150fe6f3dad','4c633adbe07a86283812fddb69f3777d733a6b9d064cee1a906b3893340bbf4a','7a7282ce5cf8f415d9dc7b7e7f6e5b053a36bd39cc970c0e6b539c1c6cc08e95');
INSERT INTO blocks VALUES(310485,'eab5febc9668cd438178496417b22da5f77ceaed5bb6e01fc0f04bef1f5b4478',310485000,NULL,NULL,'b7f66db9ea5838b65286422d0cac262f6b81bbd5a7397adf7b8d85b21354dbcd','78fc2d766032d3efb528b76374fdc26e6c9f4c55defa6c2bb69798c226e1657c','c7a6777413cd8d244af6824aa73f0d9a1682dbe2f346a62f898040249e0e53f1');
INSERT INTO blocks VALUES(310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,NULL,NULL,'0f829769e4da773089d7b05047a499db5f6d1b17795d4fba912882caee9813e0','364bdba2a8891b61674e7ceae84b1193bfcab544d632e01775b2693fb5fead98','e48af4134604ed6310a3cc86ac9e5092dd13631b041dc94a121323c8b79413d4');
INSERT INTO blocks VALUES(310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,NULL,NULL,'4b4d7a79843342e96e5d9d71bbc49690245b3098be75e7b86f273021d526216d','a654d4d19a06cb12652811b6d9f954c1358a9397e523373f9a7c9fb76ea1a43b','5cd31a4a88db4fb80e952cfbd36176d55c478e9662f3c81402a3b779af94d63d');
INSERT INTO blocks VALUES(310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,NULL,NULL,'2d7e59026ea4c8933e9c7474936931ca49d4af91f9b9985f3c76085fb3a69104','2ec0ac25452e16d6b37845a8f77d4d945164009633caf81864a254017714af79','49d2421cbd286c06a578b2b1d8dd1c5e5496cf5c46fde7407f09d8fd08f4e995');
INSERT INTO blocks VALUES(310489,'2efdb36f986b3e3ccc6cc9b0c1c3cdcb07429fb43cbc0cc3b6c87d1b33f258b6',310489000,NULL,NULL,'716354a370f344980e98785a444b56b21188bc699e7fbd0c877b6f2fabf35efc','7d2643922346df24e3a5037e1b3270cc4d457fb015907844849149f32d5f9c88','7a2806b70e29427fa06452a81804ac74b9de7cedd075a0043bc4b1713627af8b');
INSERT INTO blocks VALUES(310490,'e2cb04b8a7368c95359c9d5ff33e64209200fb606de0d64b7c0f67bb1cb8d87c',310490000,NULL,NULL,'906a38f4256f50312891119c99721537992438af85421e317574ce1810e2b909','46bd80b83aa765f2bdc24f4fb7bed43787c1a36dd08f228287b547a71163d739','2d41b52af75de177b6774c0d48cc44de3953d122103e4a3978155fffe22f752b');
INSERT INTO blocks VALUES(310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,NULL,NULL,'3114d8091cfcaa9944c6fab49d51950535c4ef269877d58c372ed80b2b472ec6','6076ca3a7a14276ad40808a5a0ae589e8c90b9abc708d4938fb622315e8875dc','3b733f69fbd35b07af8f34296f4983d6d2a80687038736fb71c7a6d6c6529a54');
INSERT INTO blocks VALUES(310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,NULL,NULL,'98af18583618fdeed545347c013763d068e8294405d265911cc5e1bc420bc740','4bd4fa501b3838ba404ab14f07d9b1687776ed65326c715d44ac5946f4ba0378','f5f2b8156ff31c21772722b7d48eba860f1c8a63437d0f9c69891287abfd6749');
INSERT INTO blocks VALUES(310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,NULL,NULL,'29119cd30a4733916fbfd0551506eaa16f7bb1bdfbdf8d17ac4e5bb20d1cb09c','5aaa408ea44cc64a0d1e2bd0e82abd43bf218ac249fee0bbaeecd298896c88a4','cfbf0105a27c35545e25978918c7f4d76c8f8cec2962053ece6ff408dc4ef9aa');
INSERT INTO blocks VALUES(310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,NULL,NULL,'72d71bd72263699ea9f2b097ad141be5bc394f49d8b0b0a6b2ff6a87b0ee3919','3f16375e46b0b836e26476e90c07d576945cd18c585d6c90ab93958bc20f8ba0','3f701c05b2cdc420cc2d5cb466ac02fe4a09a2332d72412f1a76a5ba1319f5b7');
INSERT INTO blocks VALUES(310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,NULL,NULL,'5a7e5a36882466373d576bb5f4ccd1bc72ecaf548b9589baa803a7275a7a24cd','f96d79c29fb3af9022cb0f8b6afbf79b79e5438f46b7abb5653846556d6cee59','e3b220f39e6cebb5aea6a4ba9e526e469e4d318714ff24de57e71762ae89d982');
INSERT INTO blocks VALUES(310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,NULL,NULL,'7ac6121c624b634f44695172761830926afe76bb18c4cc9195773f3a26966941','88526a902982e3ec2f04af069911feb6e5bf2e5e806aa7e9e7e7ef5235b50de6','85d1dde9618193c5267a8cc2d08efe16a84ebd862c0edece2ddeb5d1048b4ce0');
INSERT INTO blocks VALUES(310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,NULL,NULL,'28c6e92b2299b9cbbb5953f8b7ff3de0fe962d15642ba27e43faa64e1935e819','1c90cbdd644a602d99d5d9c0141a0e8227fd5e7c9db10a70c1cdaccdd482a2a7','dfd6b6c9942d35a2e4b2857ed7a597a7e35e84e63706ac57ac1dd402228e5106');
INSERT INTO blocks VALUES(310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,NULL,NULL,'5fe6cdb0828379bf240fad99c68bba34e1889bbc19605ce5c297b82352264414','ee6d77413eb2c915443de0d3aa7fd23a354669ae7af6005d748993c5e9545241','56e001abfe77d83ba7d0ced5cac1d55e021ac34ea5a9db6f322e60bd94143df2');
INSERT INTO blocks VALUES(310499,'1950e1a4d7fc820ed9603f6df6819c3c953c277c726340dec2a4253e261a1764',310499000,NULL,NULL,'b9fcbdafddd46fdda061f6e9f8744b426b6ca37e32b315df1098cbc7899ae9b9','f11b658c0b6f9ca4e8c994a1090c7143b1512efc1e6654deaa0a1309f1d3d899','249eaf7f270e7201a84d8c9a5ddb3153d5f215808212c7c0dd194edfe4cf5366');
INSERT INTO blocks VALUES(310500,'54aeaf47d5387964e2d51617bf3af50520a0449410e0d096cf8c2aa9dad5550b',310500000,NULL,NULL,'5ffefc7a2724be6bd697796bb82638ec913c5cbb73627153d1a13b48c7a6c02d','c9b60915c124494fa479ebf81fe15a9fdca32300af13dc1add20ab6f98b7cc74','2a7668fab04d1e11a92c0b68ccf21bd9b6cae4d4285f19dfbbbce3b3417f4c1c');
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
INSERT INTO credits VALUES(310001,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000000,'issuance','f39122dc568d4944517cd9eb8672d1e26af489dd3f19869822fd8f764f8ede3e');
INSERT INTO credits VALUES(310002,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','NODIVISIBLE',1000,'issuance','6918b78b211a5dff82d06967557cc4108972ed09d33f22550f69f5c1fb98aeac');
INSERT INTO credits VALUES(310003,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','CALLABLE',1000,'issuance','0f8bf23ef258a64fcee75dd874c5823a7b433262c2fad48dea38c3aae6cf9c32');
INSERT INTO credits VALUES(310004,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','LOCKED',1000,'issuance','00117692428d88a274f0b7f2880accf904a98e52101b20b8c57dd47458624c1f');
INSERT INTO credits VALUES(310007,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','DIVISIBLE',100000000,'send','6e91ae23de2035e3e28c3322712212333592a1f666bcff9dd91aec45d5ea2753');
INSERT INTO credits VALUES(310008,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'send','4fd55abadfdbe77c3bda2431749cca934a29994a179620a62c1b57f28bd62a43');
INSERT INTO credits VALUES(310012,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',300000000,'send','698e97e507da8623cf38ab42701853443c8f7fe0d93b4674aabb42f9800ee9d6');
INSERT INTO credits VALUES(310013,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','DIVISIBLE',1000000000,'send','0cfeeb559ed794d067557df0376a6c213b48b174b80cdb2c3c6d365cf538e132');
INSERT INTO credits VALUES(310014,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','NODIVISIBLE',5,'send','1facb0072f16f6bdca64ea859c82b850f58f0ec7ff410d901679772a4727515a');
INSERT INTO credits VALUES(310015,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','NODIVISIBLE',10,'send','e3b6667b7baa515048a7fcf2be7818e3e7622371236b78e19b4b08e2d7e7818c');
INSERT INTO credits VALUES(310016,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','MAXI',9223372036854775807,'issuance','5fc976779815ce0a76240f1098d0972c49c07c0dbf57655b7c08926b19bcd7b1');
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
INSERT INTO credits VALUES(310109,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','PAYTOSCRIPT',1000,'issuance','be6beb6a0a3486a10712c2e4b9dfde42b1795da9801f9eb81e2fd2d4b48e9c7f');
INSERT INTO credits VALUES(310110,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000,'send','f6a0f819e899b407cbfa07b4eff3d58902af3899abfbaa47d5f31d5b398e76e7');
INSERT INTO credits VALUES(310113,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','LOCKEDPREV',1000,'issuance','927771b6e8ba35190e7453ecf07d28649f06477cdf9c76106b26ba9b5f7453c8');
INSERT INTO credits VALUES(310116,'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx','XCP',92999030129,'burn','27929c4fcad307a76ea7da34dd2691084f678a22ee43ce7f3842b78730ee08f9');
INSERT INTO credits VALUES(310481,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'send','b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5');
INSERT INTO credits VALUES(310482,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'send','c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34');
INSERT INTO credits VALUES(310493,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',92995878046,'burn','c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a');
INSERT INTO credits VALUES(310494,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','DIVIDEND',100,'issuance','321bed395482e034f2ce0a4dbf28d1f800592a658e26ea91ae9c5b0928204503');
INSERT INTO credits VALUES(310495,'mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','DIVIDEND',10,'send','02156b9a1f643fb48330396274a37620c8abbbe5eddb2f8b53dadd135f5d2e2e');
INSERT INTO credits VALUES(310496,'mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','XCP',92945878046,'send','a35ab1736565aceddbd1d71f92fc7f39d1361006aa9099f731e54e762964d5ba');
INSERT INTO credits VALUES(310497,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','PARENT',100000000,'issuance','0c15f09ff74f5d325a75f7764e35c6c06d860f0763e6b23be81c00c0566fcb08');
INSERT INTO credits VALUES(310498,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','A95428956661682277',100000000,'issuance','38a4c1dd75429c070078db1a9367430169b8d66f9e4cf8608667066ad89305ef');
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
INSERT INTO debits VALUES(310001,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','f39122dc568d4944517cd9eb8672d1e26af489dd3f19869822fd8f764f8ede3e');
INSERT INTO debits VALUES(310002,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','6918b78b211a5dff82d06967557cc4108972ed09d33f22550f69f5c1fb98aeac');
INSERT INTO debits VALUES(310003,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','0f8bf23ef258a64fcee75dd874c5823a7b433262c2fad48dea38c3aae6cf9c32');
INSERT INTO debits VALUES(310004,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','00117692428d88a274f0b7f2880accf904a98e52101b20b8c57dd47458624c1f');
INSERT INTO debits VALUES(310005,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'issuance fee','5ded386dd851ba25a66316e804811e3d89000b7bb8d3ba19549619341c3e425e');
INSERT INTO debits VALUES(310006,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','4f0433ba841038e2e16328445930dd7bca35309b14b0da4451c8f94c631368b8');
INSERT INTO debits VALUES(310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000,'send','6e91ae23de2035e3e28c3322712212333592a1f666bcff9dd91aec45d5ea2753');
INSERT INTO debits VALUES(310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'send','4fd55abadfdbe77c3bda2431749cca934a29994a179620a62c1b57f28bd62a43');
INSERT INTO debits VALUES(310009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','21460d5c07284f9be9baf824927d0d4e4eb790e297f3162305841607b672349b');
INSERT INTO debits VALUES(310010,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','1899b2e6ec36ba4bc9d035e6640b0a62b08c3a147c77c89183a77d9ed9081b3a');
INSERT INTO debits VALUES(310012,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',300000000,'send','698e97e507da8623cf38ab42701853443c8f7fe0d93b4674aabb42f9800ee9d6');
INSERT INTO debits VALUES(310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',1000000000,'send','0cfeeb559ed794d067557df0376a6c213b48b174b80cdb2c3c6d365cf538e132');
INSERT INTO debits VALUES(310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','NODIVISIBLE',5,'send','1facb0072f16f6bdca64ea859c82b850f58f0ec7ff410d901679772a4727515a');
INSERT INTO debits VALUES(310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','NODIVISIBLE',10,'send','e3b6667b7baa515048a7fcf2be7818e3e7622371236b78e19b4b08e2d7e7818c');
INSERT INTO debits VALUES(310016,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','5fc976779815ce0a76240f1098d0972c49c07c0dbf57655b7c08926b19bcd7b1');
INSERT INTO debits VALUES(310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',9,'bet','2a2169991597036b6dad687ea1feffd55465a204466f40c35cbba811cb3109b1');
INSERT INTO debits VALUES(310020,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',9,'bet','5c6562ddad0bc8a1faaded18813a65522cd273709acd190cf9d3271817eefc93');
INSERT INTO debits VALUES(310101,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',10,'bet','db4ea092bea6036e3d1e5f6ec863db9b900252b4f4d6d9faa6165323f433c51e');
INSERT INTO debits VALUES(310107,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','XCP',100,'open dispenser','9834219d2825b4d85ca7ee0d75a5372d9d42ce75eb9144951fca1af5a25915ec');
INSERT INTO debits VALUES(310109,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',50000000,'issuance fee','be6beb6a0a3486a10712c2e4b9dfde42b1795da9801f9eb81e2fd2d4b48e9c7f');
INSERT INTO debits VALUES(310110,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000,'send','f6a0f819e899b407cbfa07b4eff3d58902af3899abfbaa47d5f31d5b398e76e7');
INSERT INTO debits VALUES(310112,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',10,'bet','d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048');
INSERT INTO debits VALUES(310113,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',50000000,'issuance fee','927771b6e8ba35190e7453ecf07d28649f06477cdf9c76106b26ba9b5f7453c8');
INSERT INTO debits VALUES(310114,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',0,'issuance fee','48b504783d9edbcd7946e3fed3342168148b3edfe0938b49894eed300743b4a3');
INSERT INTO debits VALUES(310115,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',0,'issuance fee','49de14513c642f19ae54643978ebd716312a28e7915081165d220d803ee9df0c');
INSERT INTO debits VALUES(310481,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'send','b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5');
INSERT INTO debits VALUES(310482,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'send','c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34');
INSERT INTO debits VALUES(310487,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','XCP',9,'bet','41e821ae1c6b553d0fa5d5a807b2e7e9ffaec5d62706d9d2a59c6e65a3ed9cef');
INSERT INTO debits VALUES(310491,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','74db175c4669a3d3a59e3fcddce9e97fcd7d12c35b58ef31845a1b20a1739498');
INSERT INTO debits VALUES(310494,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',50000000,'issuance fee','321bed395482e034f2ce0a4dbf28d1f800592a658e26ea91ae9c5b0928204503');
INSERT INTO debits VALUES(310495,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','DIVIDEND',10,'send','02156b9a1f643fb48330396274a37620c8abbbe5eddb2f8b53dadd135f5d2e2e');
INSERT INTO debits VALUES(310496,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',92945878046,'send','a35ab1736565aceddbd1d71f92fc7f39d1361006aa9099f731e54e762964d5ba');
INSERT INTO debits VALUES(310497,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','0c15f09ff74f5d325a75f7764e35c6c06d860f0763e6b23be81c00c0566fcb08');
INSERT INTO debits VALUES(310498,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',25000000,'issuance fee','38a4c1dd75429c070078db1a9367430169b8d66f9e4cf8608667066ad89305ef');
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
INSERT INTO issuances VALUES(2,'f39122dc568d4944517cd9eb8672d1e26af489dd3f19869822fd8f764f8ede3e',0,310001,'DIVISIBLE',100000000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(3,'6918b78b211a5dff82d06967557cc4108972ed09d33f22550f69f5c1fb98aeac',0,310002,'NODIVISIBLE',1000,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(4,'0f8bf23ef258a64fcee75dd874c5823a7b433262c2fad48dea38c3aae6cf9c32',0,310003,'CALLABLE',1000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(5,'00117692428d88a274f0b7f2880accf904a98e52101b20b8c57dd47458624c1f',0,310004,'LOCKED',1000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(6,'5ded386dd851ba25a66316e804811e3d89000b7bb8d3ba19549619341c3e425e',0,310005,'LOCKED',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'',0,0,'valid',NULL,0);
INSERT INTO issuances VALUES(17,'5fc976779815ce0a76240f1098d0972c49c07c0dbf57655b7c08926b19bcd7b1',0,310016,'MAXI',9223372036854775807,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(110,'be6beb6a0a3486a10712c2e4b9dfde42b1795da9801f9eb81e2fd2d4b48e9c7f',0,310109,'PAYTOSCRIPT',1000,0,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',0,0,0,0.0,'',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(114,'927771b6e8ba35190e7453ecf07d28649f06477cdf9c76106b26ba9b5f7453c8',0,310113,'LOCKEDPREV',1000,1,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',0,0,0,0.0,'',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(115,'48b504783d9edbcd7946e3fed3342168148b3edfe0938b49894eed300743b4a3',0,310114,'LOCKEDPREV',0,1,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',0,0,0,0.0,'',0,0,'valid',NULL,0);
INSERT INTO issuances VALUES(116,'49de14513c642f19ae54643978ebd716312a28e7915081165d220d803ee9df0c',0,310115,'LOCKEDPREV',0,1,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',0,0,0,0.0,'',0,0,'valid',NULL,0);
INSERT INTO issuances VALUES(495,'321bed395482e034f2ce0a4dbf28d1f800592a658e26ea91ae9c5b0928204503',0,310494,'DIVIDEND',100,1,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',0,0,0,0.0,'',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(498,'0c15f09ff74f5d325a75f7764e35c6c06d860f0763e6b23be81c00c0566fcb08',0,310497,'PARENT',100000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'',50000000,0,'valid',NULL,0);
INSERT INTO issuances VALUES(499,'38a4c1dd75429c070078db1a9367430169b8d66f9e4cf8608667066ad89305ef',0,310498,'A95428956661682277',100000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'',25000000,0,'valid','PARENT.already.issued',0);
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
INSERT INTO transactions VALUES(2,'f39122dc568d4944517cd9eb8672d1e26af489dd3f19869822fd8f764f8ede3e',310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'00000014000000A25BE34B66000000174876E8000100000000000000000000',1);
INSERT INTO transactions VALUES(3,'6918b78b211a5dff82d06967557cc4108972ed09d33f22550f69f5c1fb98aeac',310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'000000140006CAD8DC7F0B6600000000000003E80000000000000000000000',1);
INSERT INTO transactions VALUES(4,'0f8bf23ef258a64fcee75dd874c5823a7b433262c2fad48dea38c3aae6cf9c32',310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001400000003C58E5C5600000000000003E80100000000000000000000',1);
INSERT INTO transactions VALUES(5,'00117692428d88a274f0b7f2880accf904a98e52101b20b8c57dd47458624c1f',310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001400000000082C82E300000000000003E80100000000000000000000',1);
INSERT INTO transactions VALUES(6,'5ded386dd851ba25a66316e804811e3d89000b7bb8d3ba19549619341c3e425e',310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001400000000082C82E300000000000000000100000000000000000000',1);
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
INSERT INTO transactions VALUES(17,'5fc976779815ce0a76240f1098d0972c49c07c0dbf57655b7c08926b19bcd7b1',310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'000000140000000000033A3E7FFFFFFFFFFFFFFF0100000000000000000000',1);
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
INSERT INTO transactions VALUES(110,'be6beb6a0a3486a10712c2e4b9dfde42b1795da9801f9eb81e2fd2d4b48e9c7f',310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','',0,6800,X'0000001400078A8FE2E5E44100000000000003E80000000000000000000000',1);
INSERT INTO transactions VALUES(111,'f6a0f819e899b407cbfa07b4eff3d58902af3899abfbaa47d5f31d5b398e76e7',310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',5430,7650,X'00000000000000A25BE34B660000000005F5E100',1);
INSERT INTO transactions VALUES(112,'510f6feb902159622d83f64eae590a4fec88989869a20caf5804c313aa5e0186',310111,'fde71b9756d5ba0b6d8b230ee885af01f9c4461a55dbde8678279166a21b20ae',310111000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','',0,5975,X'0000001E52BB33023FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(113,'d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048',310112,'5b06f69bfdde1083785cf68ebc2211b464839033c30a099d3227b490bf3ab251',310112000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',5430,7124,X'00000028000352BB33C8000000000000000A000000000000000A0000000000000000000013B0000003E8',1);
INSERT INTO transactions VALUES(114,'927771b6e8ba35190e7453ecf07d28649f06477cdf9c76106b26ba9b5f7453c8',310113,'63914cf376d3076b697b9234810dfc084ed5a885d5cd188dd5462560da25d5e7',310113000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','',0,6800,X'00000014000038FEDF6D2C6900000000000003E80100000000000000000000',1);
INSERT INTO transactions VALUES(115,'48b504783d9edbcd7946e3fed3342168148b3edfe0938b49894eed300743b4a3',310114,'24fc2dded4f811eff58b32cda85d90fb5773e81b9267e9a03c359bc730d82283',310114000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','',0,6800,X'00000014000038FEDF6D2C6900000000000000000100000000000000000000',1);
INSERT INTO transactions VALUES(116,'49de14513c642f19ae54643978ebd716312a28e7915081165d220d803ee9df0c',310115,'a632d67ff5f832fe9c3c675f855f08a4969c6d78c0211e71b2a24fe04be5656a',310115000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','',0,6800,X'00000014000038FEDF6D2C6900000000000000000100000000000000000000',1);
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
INSERT INTO transactions VALUES(498,'0c15f09ff74f5d325a75f7764e35c6c06d860f0763e6b23be81c00c0566fcb08',310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6000,X'00000014000000000AA4097D0000000005F5E1000100000000000000000000',1);
INSERT INTO transactions VALUES(499,'38a4c1dd75429c070078db1a9367430169b8d66f9e4cf8608667066ad89305ef',310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6175,X'0000001501530821671B10650000000005F5E10001108E90A57DBA9967C422E83080F22F0C68',1);
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
