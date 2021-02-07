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
INSERT INTO bet_match_resolutions VALUES('c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d_acb20e35d26e55048ed34b3e1f4046a704c8b6d130a7d33c064cb04b24356ee0',1,310102,'1',9,9,NULL,NULL,0);
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
INSERT INTO bet_matches VALUES('c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d_acb20e35d26e55048ed34b3e1f4046a704c8b6d130a7d33c064cb04b24356ee0',20,'c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',21,'acb20e35d26e55048ed34b3e1f4046a704c8b6d130a7d33c064cb04b24356ee0','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',1,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000001,0.0,5040,9,9,310019,310020,310020,100,100,310119,5000000,'settled');
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
INSERT INTO bets VALUES(20,'c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d',310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000001,9,0,9,0,0.0,5040,100,310119,5000000,'filled');
INSERT INTO bets VALUES(21,'acb20e35d26e55048ed34b3e1f4046a704c8b6d130a7d33c064cb04b24356ee0',310020,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1388000001,9,0,9,0,0.0,5040,100,310120,5000000,'filled');
INSERT INTO bets VALUES(102,'aac845aa4eb4232be418d70586755f7b132dc33d418da3bc96ced4f79570a305',310101,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',3,1388000200,10,10,10,10,0.0,5040,1000,311101,5000000,'open');
INSERT INTO bets VALUES(113,'d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048',310112,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',3,1388000200,10,10,10,10,0.0,5040,1000,311112,5000000,'open');
INSERT INTO bets VALUES(488,'2447f6974033ac41c40b4598dfb73fc7479fd85bb9d01de2267b3f7842803275',310487,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',1,1388000001,9,9,9,9,0.0,5040,100,310587,5000000,'open');
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
INSERT INTO blocks VALUES(310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,NULL,NULL,'11461f972c4cd85c87b5abfedb3cee589d09e945570d34564dcde6f4df9d2b57','76dd4e40ce9c89dbe5aaf5f48bb577a6e8ba12530bd770922a697ed0907b8cf4','c59552705d5ce3236c1c6e9562da91a1e7839b67346ba4e446eb6eb937353fb3');
INSERT INTO blocks VALUES(310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,NULL,NULL,'355d92f841de89a1d97c3b2ea7623959ea4494bb62ea7e67ad359beb68caca8c','34c42a025c5c0592e008ca41de09334728d31822dd2e89e50eb755a0ea6678d6','c4fef0d06ebbf594ba68fed7ae3df3281c064a6a2357a936f4aa7a63e4acec0a');
INSERT INTO blocks VALUES(310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,NULL,NULL,'edcd7e344fb5cca16999f025594890b8b54543555e61eb3807406bb4204677f2','79fd856561f83ac9b0105c2622817ee95b76b9fe514d43d80bd25eefdeb1f236','7e3ebeec3193d587a99ee4fbe526fa327dc19d1e018eb1be8b8fbec68e20a0e9');
INSERT INTO blocks VALUES(310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,NULL,NULL,'abd71a31bc1f8a072761b23a5bc2976731ebdf305d1d7d33922e93573f308129','0b4bbfc9c39b628898f8da6fa12859f453583d291a96d5d166c695ca182d54fe','74cf19ce94d2864dcc1596a87ddcfc02c91814411d540bd491af7d6b443ebed0');
INSERT INTO blocks VALUES(310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,NULL,NULL,'0c3914f9676e506a96e6db793f15200ef33087cd47de4d27628849013a391daa','624bdd0a3d08e2d864df3bce2d7d2c75f9f55ad4c5a7202e7192e0a2297f33fd','d6b54527ae9ffd7171f775fd4711cef29b04f9aa9da2726a41a7582e45003577');
INSERT INTO blocks VALUES(310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,NULL,NULL,'57ff5f34a9e418b179db9003414c5f3bdfa7feeb538f24071b23d024a3d05df0','2959426283694c4e4154c13cca75e1a6e557b1162213e9af9627564dc7fdd9f1','c5869cefda8d499ce849735b0d61b0276ecf23a0d971eb5907a1122155c4952d');
INSERT INTO blocks VALUES(310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,NULL,NULL,'bfed530458339aab02ff75ad76738569dc6997c7a35d4452351678b04e022f68','4e5b992fc87b86d8da3f3c106e6020a6882af6a08bdc1e4469c11572e00160bb','b32a3d519494225c43431e6289697f2c1a863f0cf1ae9d231898837ceaf22aba');
INSERT INTO blocks VALUES(310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,NULL,NULL,'d4feec997754d11a1502e5351ed62fcfbfcafb770e19a37da41d1d88b7b45ed4','adb9877ec3a9377c7c1e66c0d46c09b9beab264cfdfa2eb4c4e43ee3129d7373','f62f60e2657dce8db5f4dc88149fc465feae533b323afbf4ca0fc36d0b7c258e');
INSERT INTO blocks VALUES(310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,NULL,NULL,'4ab5ff9e71bbc83956557fb5abec98372fa38e5580838fb258b2d831bfc4d9ea','200b2326988ed3928f2a24b416b76065c5bd828df664827fc61b671ba89daec4','5d01ba241632d978e4b949255afe2ea4edc7f294dd36e68a958b0e39cf064b97');
INSERT INTO blocks VALUES(310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,NULL,NULL,'1909ef40a24263776cb9e0d52a690048b50728855a0fe4b0e1ba3834a9e401c1','a4f430f1766aa11bd3174d89ee2c519aa6dca5c894f647573097db8ae1d88ed4','06bca8e8d7ac50c394a12c1f4d71715c4be37c2082242db4ea97e4946560bf42');
INSERT INTO blocks VALUES(310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,NULL,NULL,'c3d51a5f2df90c089844ba4de7d5541f6051490aa1389e5945a7bb91d49e3589','bfde60e00f17f996da019002e01e5b20b6611a8c0997b7d777cccfbcf90b9138','966e5c9bf0b4e30a851e99f26bb85db5dcda716dc1ba7b618a42636206fba859');
INSERT INTO blocks VALUES(310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,NULL,NULL,'a9dc31556d38b118eeb0bcbb3a374a0ed79adec4eb23e00c80c0599ba97c9a7a','e23e7a068bdd41d3b4c8153ac572962a51395f845605266f1a7b876edfcc58a3','d5d206218f993d2109e0ebc7f69e9449ed8a3f978faf339bb4259d069e2c27c1');
INSERT INTO blocks VALUES(310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,NULL,NULL,'e72be5070d0a5853631d902d334e8b88eddf6e79616373311babc4a0a27dd3d8','70d6d2cc76d6eafd60b108dc08733c70d6b4a018441360ecf006491a98319f2f','f7de539d29aa189b3cbc00a62e0cc816aff925d09d3044bb158e60643be05d7e');
INSERT INTO blocks VALUES(310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,NULL,NULL,'cb0962222af917dbac2a11465c22cd80770c0b3cdb8bdc0870c99a8116745c9e','682831136b79ae77a003fa69f995aed4e55c2b81c8a61caee22a927d96c92000','60885a44a3931bfa8328147bbf7f0f090185fe6e2002d1bb65d0fbc8c8fbbb34');
INSERT INTO blocks VALUES(310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,NULL,NULL,'6ff899433f22546c41a15f20b4c66913c747931500fee10d58c4a17b9e2f0c88','e7cc744b750a7fc841644233b9351727ebe529014b7f529c6f5f675d50eac547','043d2845f2668596de7d0468ac41b0a4aec28ab5139df764f4b45da27dc8f6f0');
INSERT INTO blocks VALUES(310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,NULL,NULL,'ec66a06cde401b66917c6d1d4e1ee8893405cfbf0474560d9997d6960c8af710','837340ff1e2674e4b1b2ad78aa81958d2f9adabeb7565477e5ab006b574530d4','5dcbbf7ba7224408b51e2462090f9e0bd8703565df00ef71ae27ec869153d4d2');
INSERT INTO blocks VALUES(310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,NULL,NULL,'b2053109bff06dae1705fc32ab0712f38bf9d206fa3517fbf0a938d1b5f33bad','0a580bdbf224df576376785ba419db92b19f3d9ea10996c50fba737e7b1e85eb','30d886f234b03e7e4df9378740cea29e9507bceae5730112c479e936f787f304');
INSERT INTO blocks VALUES(310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,NULL,NULL,'d7051de4d03fb31bfedf215b407b1edc12789c1f2748abb5a72257ad8f5113ce','a9a1d9f080b85033e8bdc990c66a13242c01c38817febcea4f9ef28b7f44230e','3790cb52ececbd3117b15dc6d951dde4a08b1579e69aa5d9233d5b27d6550f37');
INSERT INTO blocks VALUES(310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,NULL,NULL,'35c95a70193ded2f9ee18254a91ce5d4834bb162fc3cca85dd432339257539b8','4989f663b6e5c498e616f97e975359c4e45342667491a5698225ddd48805ee95','cf5897204718613f86ec95321eb629f4227cfb867db469f9caa213b204b4a4e8');
INSERT INTO blocks VALUES(310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,NULL,NULL,'8315de64ee1051c333687ba9fae6244287b85bcc1e3a4b67f3fe7d51b931378b','f055dfbeedebcf6005e7c33acbc1f2597b6cfddceaeb109a4cb90672bcd27c8f','c63295328586975fa42c1e18e7f2238df5706fe4eba3b403197be7fe40221c59');
INSERT INTO blocks VALUES(310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,NULL,NULL,'c2d646bd3f54eec73cd9da6f5da4bc159d0c64e8fb9ad4095dfa58850e65c7b1','b7479a4262c2e37420071d33b88d1133572c551c71d9a555e348b66a650bb1be','ba736bae5e34608e0e1669a912babf7c5169cbfbc149a799779599d8a13b70f8');
INSERT INTO blocks VALUES(310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,NULL,NULL,'619367fb7657e0fb4800acd385eb5593d085ce5cbfbfb098dafa98612d9fd445','8e7180854beea8bbf3719d9cde94c87c0ce4a9435c19c0ca7b92c64ec3c0986b','ecc28315714c3c7af038418963a75a2298cc644c6c06cf31354f53e95a642886');
INSERT INTO blocks VALUES(310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,NULL,NULL,'ba865dbc8263aaf153d7264dfc6a580bebe9391ca0551f15a1c822c6cbe2b8de','cdf5302da97635c682b957d8deb2ef5d041cfac60a859caf0dcec39b8441aad8','1a47d24d871ba2323c3932e70317520b80e2eee6bcb5155ce8187c6e5e2e96d9');
INSERT INTO blocks VALUES(310024,'b03042b4e18a222b4c8d1e9e1970d93e6e2a2d41686d227ff8ecf0a839223dc5',310024000,NULL,NULL,'368e948cbf42de80aca51abe75d09ec78196924453719182ccc86419df5da2db','97366e41be651e4f7e6a2a33d135c77f0081c5ec1c15021e3488b992afe1f653','a6a0c0fce97d8b86e995244255c1dd3bd2c35a863ce61e1d56b29a5246d69cad');
INSERT INTO blocks VALUES(310025,'a872e560766832cc3b4f7f222228cb6db882ce3c54f6459f62c71d5cd6e90666',310025000,NULL,NULL,'9f7132c808936f580d4fb1dc5791541a5a3d23532d1093c20d434007f8dde54c','03b528217cc61fb49bc292ecff010dcfb052d980ad65b5eeeb3141cc2c8c7d0c','2d2240f0af2a5dfe951eb5d1f65c093a18438f8b0967280fbb4e8783ee6294e8');
INSERT INTO blocks VALUES(310026,'6c96350f6f2f05810f19a689de235eff975338587194a36a70dfd0fcd490941a',310026000,NULL,NULL,'074ea6f10a5290cff31f7b21483f7b2248723c8d1b5bc060c31219f66f37def7','ca60f54cb588a625675c6c8480597adb052d437d15fe6de8bbab2760f023b8bf','4213f8f50b226a1f7f06dc286479aef9462c1994cb4cc3eb5dc08b973c6db207');
INSERT INTO blocks VALUES(310027,'d7acfac66df393c4482a14c189742c0571b89442eb7f817b34415a560445699e',310027000,NULL,NULL,'a3ade2b2e5bc701996f511f3e85d596b60f882a3254fd975769c0f38b3b14cb3','a42c90d7ad48ea17c1aba8698f6be1c657205f312f2d9b555ee23222fc0acd5d','60db353447f25d43682eb032280887a37fe0b9a67f4d07bdbd2a268ec5530d2b');
INSERT INTO blocks VALUES(310028,'02409fcf8fa06dafcb7f11e38593181d9c42cc9d5e2ddc304d098f990bd9530b',310028000,NULL,NULL,'3bf124a34825b5c487c94dd79b1ea4f25e657294966879f1c10b56b37a3d29b5','84be0933934932b0cdf75ee976c412234ce556d0fcfec5dd70fcbbfb335bdc2a','d65f7c3e0035b4dbc08b62f454a181ff97aa2f54c3ae476b64694a8082c88dc5');
INSERT INTO blocks VALUES(310029,'3c739fa8b40c118d5547ea356ee8d10ee2898871907643ec02e5db9d00f03cc6',310029000,NULL,NULL,'e502eb7b282e0bd4940d8f75ef51d677a641f3d55304adcb015bc249c97892bf','b85fd660045c72fda54ac54f7c309485f40ce610b034acb299a7920b1ffa8b0b','97885f54e8606922753c57f79ac0a34b22744f758edd2d8deaf246542586d03c');
INSERT INTO blocks VALUES(310030,'d5071cddedf89765ee0fd58f209c1c7d669ba8ea66200a57587da8b189b9e4f5',310030000,NULL,NULL,'d64b5eb04ddfb5600be40142b1fd27c308387a35942a6e8a6916407bbc1313b1','927215893aaf1873637a1cc1ea26da0103ad2027bd10bbb2cddcbb1b244d8b1b','8599c2ccd9217f6b8ba9e3e5722277173224cbb29ae039919ac83dc94e7cb9aa');
INSERT INTO blocks VALUES(310031,'0b02b10f41380fff27c543ea8891ecb845bf7a003ac5c87e15932aff3bfcf689',310031000,NULL,NULL,'e9c97dd7adb1b22d4ed0238607faeb2d14c090fbd7d685275ee802ab23b4b740','6685db9a296948ceccae10407621f5a89f08501b6169eb0c3d0008e9258e7396','a71261d97d46314197c72d82129a029f4f82286941b02ec81bc5f1d29a036255');
INSERT INTO blocks VALUES(310032,'66346be81e6ba04544f2ae643b76c2b7b1383f038fc2636e02e49dc7ec144074',310032000,NULL,NULL,'2544ffced9af1aabd84ab51fb78c56c9beac03dcb286aebd4202938dfa0754ea','34c99ef430e6e473f4e7848b54551e92251a8ad1279f191c8b3ee155c3d2e225','603895ec674edcd02465957faf31d9d855cbbc1b4907a19e980e3f577748ef82');
INSERT INTO blocks VALUES(310033,'999c65df9661f73e8c01f1da1afda09ac16788b72834f0ff5ea3d1464afb4707',310033000,NULL,NULL,'4355d3ebb95187fec36b1847a4c3777d8e1d5541bd1d9ff8461b8ac5b9881261','9c98de1a6fa047e68bd035a876b0556d08b1e188852660f2f6534e286b1a5723','abcb6749af8606f2fa8a1ba15a8ab20b2e98bbf2b7763d795d10a4a09ad95d46');
INSERT INTO blocks VALUES(310034,'f552edd2e0a648230f3668e72ddf0ddfb1e8ac0f4c190f91b89c1a8c2e357208',310034000,NULL,NULL,'c7fcb5134bd8131c035d65b5eeef8a3cd214348822563232a992f3f703c6b0b9','0baa41b3cb2058576f832e7d9f59c40c693b908ee290668cafe23261e7470fd5','7beb702115bea37dd5eabf25aee4247c13d9bf315a6a13793c79ca0fa478ea91');
INSERT INTO blocks VALUES(310035,'a13cbb016f3044207a46967a4ba1c87dab411f78c55c1179f2336653c2726ae2',310035000,NULL,NULL,'c41c280498ce05d6073fc6e89be2684dc68c345c1c43c00b9a3f9041954fce26','efa7928da5996825f879c83134bae659933d2b757ad9627fcf554de1908fb8b2','efc254416fab775f25eae1d9a75399df9dcf247418cc79bcdba0a08fc5848225');
INSERT INTO blocks VALUES(310036,'158648a98f1e1bd1875584ce8449eb15a4e91a99a923bbb24c4210135cef0c76',310036000,NULL,NULL,'86c67fd234ca9d2406080018b2677386990fac477db8008c0092d40a398203ed','0563c49b0057ba5ca7eaba1d4617d9209aa3363d1882a3168cb800b423a01e56','e2d2686ddfe710f3796bb20cd792df33765431b0d8a1bd2247526a085b71f79a');
INSERT INTO blocks VALUES(310037,'563acfd6d991ce256d5655de2e9429975c8dceeb221e76d5ec6e9e24a2c27c07',310037000,NULL,NULL,'3ae6272437eb0758a779d68785c41e119d1204dd5421c78e03b9d12eba64804b','a77ffdfdfcbc0c909d943b75e10fb9286c458679ed13e8a8d938ff020935dfab','ede035f778622d4d127babd9025e224693213b216fa416f888885c3b83429af3');
INSERT INTO blocks VALUES(310038,'b44b4cad12431c32df27940e18d51f63897c7472b70950d18454edfd640490b2',310038000,NULL,NULL,'18f7552567b898f6c2cfe8c829903912445de5dbf05b56a13bf9b402a24fdc11','4b597ae170bb4bcaefcf488c0321856842aacd7a8d1ffb15b99dbcd5794c9f62','4209698c8a5630e7adae2ba1df411601d42ef05c561237263d6cc528b579dc56');
INSERT INTO blocks VALUES(310039,'5fa1ae9c5e8a599247458987b006ad3a57f686df1f7cc240bf119e911b56c347',310039000,NULL,NULL,'85f2255f9256a5faf59ddec1c58b1d3bc12c91bc2c62ead61b48e1f94ea2888d','fbfb8286910b3b5ee59a13b1ae371519c3ce18c11c9ffe9d5e13b82b312b3a19','4a614a74eb5941273fcff2ae091ef35df36e97b7b3e85831fe34d84ae92e4846');
INSERT INTO blocks VALUES(310040,'7200ded406675453eadddfbb2d14c2a4526c7dc2b5de14bd48b29243df5e1aa3',310040000,NULL,NULL,'b799477db184351df5503f8d15d5461a0483ea35142c003b7e640429663ad943','2247e92fe98e3ff04854b0931a6ac52667b378adf2473df4f72ed4727e23d7fb','7f127832f2698e6121d13daeecb5c83072357cd6f07ed3d7296a04697f9102e6');
INSERT INTO blocks VALUES(310041,'5db592ff9ba5fac1e030cf22d6c13b70d330ba397f415340086ee7357143b359',310041000,NULL,NULL,'efa9cd46741b59e74263d6d348584f1a61e8ba32163c09fc3ff2e41a5431a483','3141d1828980a8449ecc563fe1c6fb8b795b16167754c569ab4714b191db285b','e77aa6621b6cf6294bbab2c20067673a20c7404433a0961d72e2cf92a383dfa2');
INSERT INTO blocks VALUES(310042,'826fd4701ef2824e9559b069517cd3cb990aff6a4690830f78fc845ab77fa3e4',310042000,NULL,NULL,'f3159919f381d46a3e1341703e55192a02a36519e71fc2675285a3a14c4ee04d','eb5b80d9e47c2d4b233f95c81b1e7ade70b669824c7e88f0dd74bf12da5d98cb','02bebe712a8444c3f8a226b0ce967b2a9d8f1327b8fc6d41ddc1596b16e27522');
INSERT INTO blocks VALUES(310043,'2254a12ada208f1dd57bc17547ecaf3c44720323c47bc7d4b1262477cb7f3c51',310043000,NULL,NULL,'961c79ea2b7dcc2d7489c423b568fb978631e71732d6b998bcc0657aa4d19194','1089375f5640000baba2e41fd650449da2a9fb78cae1ecd2480d66e34cb99113','abd04fe017b05d0c1e4224e34293f020b58850d18c0c88be442b5ca644982d0b');
INSERT INTO blocks VALUES(310044,'3346d24118d8af0b3c6bcc42f8b85792e7a2e7036ebf6e4c25f4f6723c78e46b',310044000,NULL,NULL,'d674c39010fd4554efa487d97a3d9cae278ed9b4aff0ce57db33bd881beeb3e3','f749853a13a4556cdf6c6f32df5524fdfed3cbe833a5cff391590a4fee91f85f','6899b6fafca43daa8379ed93175d7cefcdb08d0c904df86632b9ad112211c749');
INSERT INTO blocks VALUES(310045,'7bba0ab243839e91ad1a45a762bf074011f8a9883074d68203c6d1b46fffde98',310045000,NULL,NULL,'9ba70a032ae92672174421689c0845784f0cef7374e88b2f5258260191864bf1','638f8098d799cf20bfebf815f52ad2fe877293589cb5bfe9267f075599cb25c2','5acd33bd7e4da84f58d556cfa42fb43b3d0ea0523f0b739a1be5ef29dd9f3407');
INSERT INTO blocks VALUES(310046,'47db6788c38f2d6d712764979e41346b55e78cbb4969e0ef5c4336faf18993a6',310046000,NULL,NULL,'114a6ab930fbdf8531431620ed219db3756a634c5b99af6ce1ee66d527d277ff','c57389d20d41056859042d395dad71684bcdb797702b5ca1fd086ede15d416be','7bb43adc70dc4621d34c4f7b0153f3351dc2230111717f3ba927911a2c1c38af');
INSERT INTO blocks VALUES(310047,'a9ccabcc2a098a7d25e4ab8bda7c4e66807eefa42e29890dcd88149a10de7075',310047000,NULL,NULL,'5356512c94ea2c77623d874a927aae8c3dce287a34dfd27a617abfa57142c7f3','e8de25b5f0d9d8cdff0fe8fd577debf9e03b6d084ad879418daeed1cd3fbaebd','ed273e1eb904e548c4dc1af3e59bb854e8adefa407e65b913f3ee35e57804c3e');
INSERT INTO blocks VALUES(310048,'610bf3935a85b05a98556c55493c6de45bed4d7b3b6c8553a984718765796309',310048000,NULL,NULL,'0902ca0868560d05049c983bca3ab91cdd5eafc46ab0a948d702abcbc4010582','c6429e977bd821d46209f8646005070ae8100793b3ad060a69092defe8b6479a','b32c5d4fe47b5fee90cc2f6376efef3f4509e9216c0b396ec9fbb2846a85a855');
INSERT INTO blocks VALUES(310049,'4ad2761923ad49ad2b283b640f1832522a2a5d6964486b21591b71df6b33be3c',310049000,NULL,NULL,'978794628fc95756032cb7fb4e9d5ed286373d84fafbcfceec9af71d18c4c0be','ee0178d893b2d6cf67e3d3cc931e1adb20a6dad1e60374441f6515ea2a024b7f','641684504f577590958cb8b297053876e58076fdaedf41c3fa3ea0e2632b66cd');
INSERT INTO blocks VALUES(310050,'8cfeb60a14a4cec6e9be13d699694d49007d82a31065a17890383e262071e348',310050000,NULL,NULL,'ff16abeb1d35e0e422f165e206b0d69e0b9ff48b68fc6656c1af74801908b92d','89a9271b8e1769b1c646dccde638e476b5978e6f1febc2d46f27cf547ac5944f','8ff65e0e6a5af46f64770d1c2b22088b05b70731df474443ee656508c65ea0ef');
INSERT INTO blocks VALUES(310051,'b53c90385dd808306601350920c6af4beb717518493fd23b5c730eea078f33e6',310051000,NULL,NULL,'556ff900993e70cabefd05ddd5dbe3e8e10bb5c9ada7913b75d84af067004ed5','1efed29a498e9ad2ad5899e1885a75d3cdd905ff35fd413884f1b2314ed09581','e884632fa35556fece3eb4c427100b1f2138d591414ad2bfee691b420b6cbc06');
INSERT INTO blocks VALUES(310052,'0acdacf4e4b6fca756479cb055191b367b1fa433aa558956f5f08fa5b7b394e2',310052000,NULL,NULL,'15af3a616a2974aa70b7b58f88132051f335af299473db925b619fda8be1afc7','9f8f9ef8d3abda82ec27b7ed4aeaafa25857c763f49ef0efdde8813d396ef0cb','430a31d4d21460ba28c17e13323ad59d6aa7cba3ee457ca7ab7c97272c9b0bdf');
INSERT INTO blocks VALUES(310053,'68348f01b6dc49b2cb30fe92ac43e527aa90d859093d3bf7cd695c64d2ef744f',310053000,NULL,NULL,'ed0ed3b480b38929a425c2b61c86582495764624e020cb86b3a95fc7d59c692c','8120b49ec58169764118faf50bf60029b977639b1790be0d57b7192b96c3046a','b14cf47db4743b6f5675ab729ec3d57445a6566321f4903bc6d15644cc3f0d12');
INSERT INTO blocks VALUES(310054,'a8b5f253df293037e49b998675620d5477445c51d5ec66596e023282bb9cd305',310054000,NULL,NULL,'f012825d2d549910910ad6b7e4ac2373d095b53869f0793709684f0ff05bb108','0d9a6ff9b029b7efbfd21dfacb7473626aab4e46c986412d26c28eeddf34a049','c12c65f4e54efaf55ce641a342687f093c67c3aab15f39ff850590b500b59c51');
INSERT INTO blocks VALUES(310055,'4b069152e2dc82e96ed8a3c3547c162e8c3aceeb2a4ac07972f8321a535b9356',310055000,NULL,NULL,'90c08144277fe622573282349edaf9e59289b716b5b4e368d88ac25e67e788d1','cf91778454007a015a01809f226d6a0b603ff4c02c731165c61b150b4016782c','3edf577c3b1874224e12aba021ace1128f19459093442afc256f36e5992fed53');
INSERT INTO blocks VALUES(310056,'7603eaed418971b745256742f9d2ba70b2c2b2f69f61de6cc70e61ce0336f9d3',310056000,NULL,NULL,'c888ae590b64fa4514ed7f94ba785b12e881052185cc4702b598cf6e48cbb3ba','2bf8a7557b0646f2b868dd63707e3421d083ff43d146a30f6cb8d50fbf522d17','52b8cb15c2a8669a772308512548cc5d7977dbdee440803f70aa2702ac6d06f6');
INSERT INTO blocks VALUES(310057,'4a5fdc84f2d66ecb6ee3e3646aad20751ce8694e64e348d3c8aab09d33a3e411',310057000,NULL,NULL,'e68c9a569fda6f1e1e59502953c9735857a0ee158a76397722436466df24708e','44566226444e1c11efea69b48f8b6406e3c0ad004197a2ba1894629368c0ce1c','070c34a2e9324cd88a9139b882cc8eb046e613820963ae4aa849853c2147d3dd');
INSERT INTO blocks VALUES(310058,'a6eef3089896f0cae0bfe9423392e45c48f4efe4310b14d8cfbdb1fea613635f',310058000,NULL,NULL,'9f6607682f4a6274c2a45895f849816aec83ff0820709ba781634b84518eb05d','53d0cad4ea1b47791128e1621d72863f6bf7d9e9c61e5b4b305acf2731076e95','a79e48dd0db1ecbd284c58e6455b42b7c918721272374d9b4e028c6cb8534528');
INSERT INTO blocks VALUES(310059,'ab505de874c43f97c90be1c26a769e6c5cb140405c993b4a6cc7afc795f156a9',310059000,NULL,NULL,'49b10a5c390f603e7be0d405bf1fcae95fd15682ef2e41a3b2fcf713d271e541','18fc665a8fcbdd69cf21780e6e1addd3b2e07c6218996a5853f0d7c1d080d38a','be971cdd2254b8dbffdf0d1850558a3a03122bdba27fad64e37f1a6fe32be703');
INSERT INTO blocks VALUES(310060,'974ad5fbef621e0a38eab811608dc9afaf10c8ecc85fed913075ba1a145e889b',310060000,NULL,NULL,'1d6cea34d6f7042ced3a5211da80de88fa77c900af5526f3033b715e4f68df17','27389bb1c158cdd83b61484951e0fb5ef1f86c9f48d6fb18ee3c0d2b803ac6d4','81ae70236d60d237b62126f557304eeea372a4998fa674631c07dab285608088');
INSERT INTO blocks VALUES(310061,'35d267d21ad386e7b7632292af1c422b0310dde7ca49a82f9577525a29c138cf',310061000,NULL,NULL,'0c43668fdc3d6cc6ec84fee99c68f0eff21650a618db35bc20e428550eae9b0c','3ec1ed737d95b213deeaf5801fcce87d967796de0a8d519c84a08b0895a11c34','dbaffe23159315afda374308d5d0ae3112e0048852b8c05b34fb87e9d0267cf3');
INSERT INTO blocks VALUES(310062,'b31a0054145319ef9de8c1cb19df5bcf4dc8a1ece20053aa494e5d3a00a2852f',310062000,NULL,NULL,'cf03a34b29d3a8f8ea5fadb017426f2843c6ab2e785032b6dec70d7aba7bce4a','801b7dda37bc274991b1f4322af726ee72e098468183be1931175c57ecdc9434','9b2cb332f21ab2b7a98272208b6d24fd799ea38c99c689558c971ad7907eca07');
INSERT INTO blocks VALUES(310063,'0cbcbcd5b7f2dc288e3a34eab3d4212463a5a56e886804fb4f9f1cf929eadebe',310063000,NULL,NULL,'e145dfc2c7f053a1ba4c8a41d042b40c0748eefcf9e56c5e906ad4b12f3653eb','2e58a9cc3c5142b6bcd3b6807e1851d5fbdacd80b8a6cd326b7dc70143af7112','5bcd6072ee322ae89f30ce0d42a1082c38d9eaaaaae221f078e638a43e27a6d6');
INSERT INTO blocks VALUES(310064,'e2db8065a195e85cde9ddb868a17d39893a60fb2b1255aa5f0c88729de7cbf30',310064000,NULL,NULL,'ebc34184623da16251782c82098c7fcfda42f95b155eadfacab2a53e3b34333e','1a31f784c683c1eb9e18f92a6cc9e7aa2175543baae0df4809c3469d581d1257','5ec229acd45b02690ab099479fdf53c3d56f77971c080d6ebfa340023c2093e3');
INSERT INTO blocks VALUES(310065,'8a7bc7a77c831ac4fd11b8a9d22d1b6a0661b07cef05c2e600c7fb683b861d2a',310065000,NULL,NULL,'db746a9e0ad8f37c14ef14180dd1bc562ae757a6d4d042a517bb8953f34c6958','0476c1a4ed7ab080b63f27683208fc2250c0d9d91ffdfaff8cc8b46864cd00fd','f20a5e9050eeaf2e8d4206069a7c28210bacc3f4d6da9e0d6568a81cfbfd91c2');
INSERT INTO blocks VALUES(310066,'b6959be51eb084747d301f7ccaf9e75f2292c9404633b1532e3692659939430d',310066000,NULL,NULL,'cc71a63314b770e4e010bc7c66d8ab808451b6401e6df8558455a2bfc9bb4882','7f31e86f2f2b89f0832f2729d23e321b25db963acad6c4cb898432a2815bd924','a0cec8d0e4c3d0d23911acd69f247367cf9e8b716b43410ca87f9d0d2b9ed636');
INSERT INTO blocks VALUES(310067,'8b08eae98d7193c9c01863fac6effb9162bda010daeacf9e0347112f233b8577',310067000,NULL,NULL,'a5812c0f3a37b04d5105bca6b0c4819a41beeedf5b0f314f476ab55d6c31235d','b49ea91f85529988a43ed4cc1730957d79025e9d68724dc693910c9b297f7622','51f4106632d997c8a0544aa9bbfc999fa7ac4ef5e5a6c8825f56f5d85376aecd');
INSERT INTO blocks VALUES(310068,'9280e7297ef6313341bc81787a36acfc9af58f83a415afff5e3154f126cf52b5',310068000,NULL,NULL,'14f065751896a2724251b6ca6d0297b344986980075fb72ad058ad0b5bedcd3c','fcf4532d25e78bf648f88178686ff2a9402e06f080cf73ea059b9b57afdfccbe','93e821ed71ec39f46fb55babf9997c2e4f484729926350871560997b77410c7d');
INSERT INTO blocks VALUES(310069,'486351f0655bf594ffaab1980cff17353b640b63e9c27239109addece189a6f7',310069000,NULL,NULL,'a7dd17b4760fb65ac58be1b1653f7cb0e90574c47f70c61ff9f940ad15ad3658','aeb34df363fb4b0a8ddd634858390ac460d0933eec0cd4d08eb8f51b3034cb0d','99b93b33e05f5640b0800f6324ebdaa62193ff56abe745efb28aebada1066004');
INSERT INTO blocks VALUES(310070,'8739e99f4dee8bebf1332f37f49a125348b40b93b74fe35579dd52bfba4fa7e5',310070000,NULL,NULL,'8068a6bcc5d1fc1a78562f0f3165423b45b4674e55f21c4c09948fb65ee632c0','3a635159c2a0ab25f3321c66a211fad9043713fc3f565729fef56cb4422cdb01','b666dd42d3bdc6c509902fd5a1b3b49da9184238863b6386ee404158ab239c57');
INSERT INTO blocks VALUES(310071,'7a099aa1bba0ead577f1e44f35263a1f115ed6a868c98d4dd71609072ae7f80b',310071000,NULL,NULL,'af86ffad4b8dd68a0f18142935bbb18623cc5ce2e9e0c02f04c0e7a5dd974e17','34ccd82160b077e1558320f693e8783b05fded291d4913a411cd82bc9508eaee','c2c6d8cef5062d35eafe84b684789274b0dbab407020e28a6ca4d139221b5a06');
INSERT INTO blocks VALUES(310072,'7b17ecedc07552551b8129e068ae67cb176ca766ea3f6df74b597a94e3a7fc8a',310072000,NULL,NULL,'36de48518d1446b33f2230c5eee7d18e040db543fe03dca001174f8382c209ee','96a02efa035cbd69c60d4a8af772f617a328b15c344d7461a810ffcaa0a48989','427ddce2d7279f25526f1fd94b182e565b36e41050f26897dcbcab51b0fc9d82');
INSERT INTO blocks VALUES(310073,'ee0fe3cc9b3a48a2746b6090b63b442b97ea6055d48edcf4b2288396764c6943',310073000,NULL,NULL,'4374f567cbc460b73e74d6190db353c3ee86b92c3f99e392beae3caeb264eb5f','150ef2991aa2b7708c1c889d17ba8b6ab519a7e70c798520e1d29685b3109267','abfbfc0784f2fb0b782b781670e0c9eccb2fb3fe21e22c5bbc683c273b16a9a2');
INSERT INTO blocks VALUES(310074,'ceab38dfde01f711a187601731ad575d67cfe0b7dbc61dcd4f15baaef72089fb',310074000,NULL,NULL,'54fd95cdf7f9374d1687590f2860276afe67a265ddd9216e5b63fb06c5bd569e','b2d4b4d6a29e570dd4f54c5de9a6aaafa9acea32cd7c2ec6358f64ea625a0cc3','3e514dd111f8583a4767e2dc33dc388bc2ba022240daa637858ba6df7866c83e');
INSERT INTO blocks VALUES(310075,'ef547198c6e36d829f117cfd7077ccde45158e3c545152225fa24dba7a26847b',310075000,NULL,NULL,'2b42e23b43d30f91fe7705a01f0c8ec86d6230815b587704bcc70b91b5ae87b8','5af5fe539d57afc520f5fa50f7176843531460f6de095e86dad351b619d705e6','7df9a94e58faff41dd4e09af32fb74745e2def8b17378bbea51af295b2d26fd8');
INSERT INTO blocks VALUES(310076,'3b0499c2e8e8f0252c7288d4ecf66efc426ca37aad3524424d14c8bc6f8b0d92',310076000,NULL,NULL,'577092728a4dc81cd9a06fcf6d2b058f0e4ce8bcb395819a704d6b4144f041dc','ea08f38c5466151bb0a8bf3fb23db915cae86c5315ae425e579310970c81a48c','81ce2a210340735479a21d73dd85503ac40bb61168d5a5957aeb9f2b0a56f9b6');
INSERT INTO blocks VALUES(310077,'d2adeefa9024ab3ff2822bc36acf19b6c647cea118cf15b86c6bc00c3322e7dd',310077000,NULL,NULL,'d1ba60181f3061673c64ecd0b92abbc19b1a6e69a927dfefdfd8b8c74171ecd2','c97ce2f8652af0d41166f96a35f79d7d330afa612d408a9ed41fba3275419e52','f0b29072c87e30030727658703ca1e602e6d14d3c6819171ad081693a79ed4e5');
INSERT INTO blocks VALUES(310078,'f6c17115ef0efe489c562bcda4615892b4d4b39db0c9791fe193d4922bd82cd6',310078000,NULL,NULL,'c0a9270d15793e68cfd1cf445315d737bed7052914da6def4f014c21f0c9e0c5','e4088510e8b02e2b5819ee81923ccc41499157aa2ce3bd5107ac6cddba4b05ae','ab5b2fe6bdb4ab329396736afc86ffb939b6a32cb9fc66a93da67b233969d134');
INSERT INTO blocks VALUES(310079,'f2fbd2074d804e631db44cb0fb2e1db3fdc367e439c21ffc40d73104c4d7069c',310079000,NULL,NULL,'74eaddecbf5ab6608c1e95c1c313c13f2af2b649512cc8c7016717d21e93f815','c4768ffa87a9b119bd362f39e4b17d6571e7364801243e8d0cc19a31db38d30b','3122061111602ce2dbd3a4f6afb624f41920b334d4ab7b75d36b8de808e98269');
INSERT INTO blocks VALUES(310080,'42943b914d9c367000a78b78a544cc4b84b1df838aadde33fe730964a89a3a6c',310080000,NULL,NULL,'a759e3aac1b015e28b8b524106a74b943b215faac8d5079384ec7351b2239bde','1683a5b4364d553e2ef30fabf4e20c1ba263789cfad94b3155192ad47f9bcbf9','52ec84a940030dd12bc0872a1710d547e205f0744ed69518f1ab6c3dc617e842');
INSERT INTO blocks VALUES(310081,'6554f9d307976249e7b7e260e08046b3b55d318f8b6af627fed5be3063f123c4',310081000,NULL,NULL,'71622e25e8497db6fa222e33c60ea582698e72ca5789a52c9252bf51191cadaa','cfc65becc71133ae9ab2359117c28445f559ee165bcd1148751a455c416c32c6','da3288ccf6b7a950a75a354011d1a7b896279ec534f496c5a6008ff47ee8dae6');
INSERT INTO blocks VALUES(310082,'4f1ef91b1dcd575f8ac2e66a67715500cbca154bd6f3b8148bb7015a6aa6c644',310082000,NULL,NULL,'47e9d8fbcbafcee2b4c145ce651333ce49812533d13f7f9a0e9a448f51cfbacd','8992dd9243f1ea83301d6fd669496754ab782e7d2902ea4b3ba2d669db385bb1','c64eb468c761f4ae122b966905958ee42e0089ddcf2eb92c03d7dac7a9384f3e');
INSERT INTO blocks VALUES(310083,'9b1f6fd6ff9b0dc4e37603cfb0625f49067c775b99e12492afd85392d3c8d850',310083000,NULL,NULL,'e61148e7a8125f7225a6b6e1d77786f8b28b0b8a74e60fef3f75fa4de8f7d882','5952412a3bd08c9c0fe08fc49406a35a6245b267c0d04349895c8df1367e65da','d57a6ded4f228a1212c06e52c98b803beb021ff5c005b2cd3076ad2d529ac1e2');
INSERT INTO blocks VALUES(310084,'1e0972523e80306441b9f4157f171716199f1428db2e818a7f7817ccdc8859e3',310084000,NULL,NULL,'20fb450589ddc6c904fbb61cca8588e85e865635c12402ce7ae72995ab884c14','8b1c1053f8ab1bb8281fdc42cdec916b1905ad594a32fbfd54ab00cc156ff652','a79c18b6865ede3b6c9f844334508b80970695c1251e02579af90e220eaf9d30');
INSERT INTO blocks VALUES(310085,'c5b6e9581831e3bc5848cd7630c499bca26d9ece5156d36579bdb72d54817e34',310085000,NULL,NULL,'9cea37d548308505f80dc438d5183bac6c6ca424ea4dd9c85d883b05d67cdc92','e8500ef3c8d7c5b1dc0d1c34942335a2439dd03d3e7d706d889da1d61ad42267','c10260d84814af2406e9620188e73103ea29f784829c9912766d62bc74b5005f');
INSERT INTO blocks VALUES(310086,'080c1dc55a4ecf4824cf9840602498cfc35b5f84099f50b71b45cb63834c7a78',310086000,NULL,NULL,'e11bab5fba2d038086c65030b90ce1cbc988314d0c9846aa7ddac4fd357bd01a','dbfd714658165162873c8e9ba993a3d86dc09d775a27d74f92066b85d04f5d2e','07eefbde9ba4287ba2d0a834daa630053fce4011dc335b3b62d9bd239da68633');
INSERT INTO blocks VALUES(310087,'4ec8cb1c38b22904e8087a034a6406b896eff4dd28e7620601c6bddf82e2738c',310087000,NULL,NULL,'777873e7ebd0ec3052be65197ec0db8bd72e46d2053badb0f37be1f6e84ae0b3','e532c1946b8adec70c5f153ab85d00d3323837028c9a2efaccd53b7fb0827bca','1cecbd8673833205ad259ead04849aca0dbe9db947ef8ff65b14a4f6ddc33bc0');
INSERT INTO blocks VALUES(310088,'e945c815c433cbddd0bf8e66c5c23b51072483492acda98f5c2c201020a8c5b3',310088000,NULL,NULL,'85a5ea57af33dfddddbcbe1a1c87994efe5a21a645713aa164f19e19bfb23c64','26d26921bb7e05c23a4a31497610711e0cfa0fef4b5dfceee22a36192c853710','84cea7f6075dd5da7f2f498092108e7f5bd22e9611b2c40b0970fe964776b1b5');
INSERT INTO blocks VALUES(310089,'0382437f895ef3e7e38bf025fd4f606fd44d4bbd6aea71dbdc4ed11a7cd46f33',310089000,NULL,NULL,'bdf3b6e7a14a3aa22d42a7d69f2f96b0993f1eef2952a7d74313c37e1b407523','b654d4aa73c8c571c7058025a8b78c2765a4a582b0bcfff6a2e2ff01cc3777bb','9cc8fc568bc3008a389f173b90dfe3247f8fdc387035bf92b0d35623b3ae5d9e');
INSERT INTO blocks VALUES(310090,'b756db71dc037b5a4582de354a3347371267d31ebda453e152f0a13bb2fae969',310090000,NULL,NULL,'9b3ee688c5786ecc438ec9c843ba5f898fe1ab1a8bc3903ad7789aaf6b0c0bf0','00ad0cd62a14650866e633959294cbb60cd8eef37a3b6f9e1eef52c6d7113724','867caaefb8a6731fea4143e82933bb5e2e57b9b3b62cb065915c6191ff757398');
INSERT INTO blocks VALUES(310091,'734a9aa485f36399d5efb74f3b9c47f8b5f6fd68c9967f134b14cfe7e2d7583c',310091000,NULL,NULL,'25578ac389a77dbf9589b23c5470f3199016ac66a415540ae03efac29dfe7adc','9644cdc3417fe13ce0b86f2e3eb0076243b5de912f0c75383fa5d2b946cbf9fd','90de122faa8ee2ca9f4ddc4e231cc703c3d49f27dbf70353dc7612d8d5b639fb');
INSERT INTO blocks VALUES(310092,'56386beb65f9228740d4ad43a1c575645f6daf59e0dd9f22551c59215b5e8c3d',310092000,NULL,NULL,'bb9109ba299c99cb104ebf2ef6e75141c50264d701d27119525ab5d0a54c1a40','e40c52b1a2c5d5dc99d89fe37cf0dfc5ee14a60f9cff42e67a9a66cb41083535','73a2c267e380b9d975fd8707dc53b6265ecbb17edce13323dba209777d5f05a6');
INSERT INTO blocks VALUES(310093,'a74a2425f2f4be24bb5f715173e6756649e1cbf1b064aeb1ef60e0b94b418ddc',310093000,NULL,NULL,'cdb21362b3eb4fc10ba3c6bf3aba41bfc5bd0bf2475f742c1069cb4383be7b95','dde50f429dad14f0cc40b308caa95defd6d6433e8bffcb3ac94d4195c6a4d6ce','1a93dbca4645191091e09bffb165bcd5fc835c7c9119a3b54eae867f75eba7a7');
INSERT INTO blocks VALUES(310094,'2a8f976f20c4e89ff01071915ac96ee35192d54df3a246bf61fd4a0cccfb5b23',310094000,NULL,NULL,'b82568de09fe4ea06f3dca053dbcbcc61dbe5e44dd300a4301c995ba180f894d','010e8ef2138afdd69e97a088476d124886d423a11c543b45f6fa5f63d9e4df7e','17004be78c855f847ba3b744aeef996239cdfa37f5a7df2917b2dc7e5be69057');
INSERT INTO blocks VALUES(310095,'bed0fa40c9981223fb40b3be8124ca619edc9dd34d0c907369477ea92e5d2cd2',310095000,NULL,NULL,'513c4a041ee80ba72d1d8428605c682e3485fa45341460bc33fae6540dffb571','cdfadcf4d34670637533003abc458d84b84eab903d2bc2914314ad8567b8be52','1806e9c9a83fe3b4ccc5ee881a8fa37147cbc7b741ada249115544444a7087de');
INSERT INTO blocks VALUES(310096,'306aeec3db435fabffdf88c2f26ee83caa4c2426375a33daa2be041dbd27ea2f',310096000,NULL,NULL,'3e8ff43c8d671159355b2d40a995fb8f6d84f6216fa8326fa80ae39aa9d15d03','0a1f425e3edcfc1685dbc8ac29f770ce39354eb4142c0b379eff383364774b44','051c9ee053de82324caafab37b961d2f3e02700575d344726f0fa1bbea32b412');
INSERT INTO blocks VALUES(310097,'13e8e16e67c7cdcc80d477491e554b43744f90e8e1a9728439a11fab42cefadf',310097000,NULL,NULL,'19d91de7be12136737d3f8990e7a4a793912c952e71e017d723d750118e849c6','e8579d991762638c0cb98a9fa6792a225e4964f93647b3aa2f20caa2f38442fa','8565129102742409356c875dab6595fa6f45fcc2a1ae562e1c6fe1130362b1d5');
INSERT INTO blocks VALUES(310098,'ca5bca4b5ec4fa6183e05176abe921cff884c4e20910fab55b603cef48dc3bca',310098000,NULL,NULL,'be75df2e5aff3faaebfc0ce4ab5134790fa728f84500e6989739dddc058738de','14432262fbb1cedac52a937bbf5ad6e923024b8216365a13a51ecbcdad54e596','0380c34b5c5fe065355b1cd2b7c4e5c1e3d87c051942b6e67ffc8a0cc5df0aaa');
INSERT INTO blocks VALUES(310099,'3c4c2279cd7de0add5ec469648a845875495a7d54ebfb5b012dcc5a197b7992a',310099000,NULL,NULL,'9090b8a4a26ea7dff75658317ce2c6ab828b3b42684922e44debfd1bf8330b8d','98ca31667acc568b3e65fa00a5cfa87eb1007cd136973bbf5edb3c85e48b5f69','8ed5874fb604faa6de66018ba574f36c55a0ad5259af9b559d7f8bf5e9b31d73');
INSERT INTO blocks VALUES(310100,'96925c05b3c7c80c716f5bef68d161c71d044252c766ca0e3f17f255764242cb',310100000,NULL,NULL,'d48d30db433bcee44d87153fb3db17d37fbe3534f23eb16ac853b3420d86d80e','5032e80b40215de67d4c98bb014a2abc17655d9f5ef2dd58ddfb32c3c278be47','c381ddffda4a948a5b56eab10b263dfa211f5df12888c28e77b54aef748dafcc');
INSERT INTO blocks VALUES(310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,NULL,NULL,'53c6f9247cd255c86a69c05c4463ab94f9a3277496c155398c38dc6f7121fe9b','995d0ec365efa6e802dca5387b57112e524153d8fcd0803d9e1f20fb4ae9ed46','f2337666c6747bac38d390ac57c195bd0533cdf53a1cf91b8e44b3a868aa8fd7');
INSERT INTO blocks VALUES(310102,'11e25883fd0479b78ddb1953ef67e3c3d1ffc82bd1f9e918a75c2194f7137f99',310102000,NULL,NULL,'b225c48fb4c40b2e0695991251f6d69217df6e00c01613e0a20f6a3e34f50d5b','2f589b56d991d3b5cc11d27390a75c356fe32f9535e569fc08868b25dce8cbff','72a77955e2833742b2a5fc2f96f5fe0390f9da43fc5be9954e5536780c603466');
INSERT INTO blocks VALUES(310103,'559a208afea6dd27b8bfeb031f1bd8f57182dcab6cf55c4089a6c49fb4744f17',310103000,NULL,NULL,'fc2a8ce8efc122e5cbd631998e611dc8707cfe0b8d3f6a531fe5bcc21c17feae','6503177c07808688b09a59dd91ef980354ad60ffb868cea60150a38fe157275c','ffbf949bbefecfa2f1c174765d07e9e7c821c816e795e370aa7ba30c3ba95443');
INSERT INTO blocks VALUES(310104,'55b82e631b61d22a8524981ff3b5e3ab4ad7b732b7d1a06191064334b8f2dfd2',310104000,NULL,NULL,'b1a7115902d371d13889008320e52473cd5b34591bd657e372c0048df020012e','b83f85260d4e003f3748c57cf6a159f7d522dc999f67cf03c07ea5d9e591aa76','af2e9b2044aed8eb650fa08122536fe8055bfb496a3a45436d59236f93d5bf4d');
INSERT INTO blocks VALUES(310105,'1d72cdf6c4a02a5f973e6eaa53c28e9e13014b4f5bb13f91621a911b27fe936a',310105000,NULL,NULL,'b5fcda12415e713fc81278b95515fe86ecc6beb5810e4f80eb9645f09870dab0','db1a4e55872858bacea65004a4fbeae225a7e1e0f02478093d087ddf6a7fa5df','2988173d827f7e27873410d4bd6406db72821ed295aac4f9665c1d080f025c41');
INSERT INTO blocks VALUES(310106,'9d39cbe8c8a5357fc56e5c2f95bf132382ddad14cbc8abd54e549d58248140ff',310106000,NULL,NULL,'f3c98c954cf939951d8b24a257bc6b1bc152a6a0bcf6b580ac281c26bbf16499','58b8847fab58f8816c541cd5a53140b0d7094fff2a7016e9a00a05e872f488a5','bca154ed275df33b4c5c93ccda4eaa9d5e39039de94b76fa712008dc01085e14');
INSERT INTO blocks VALUES(310107,'51cc04005e49fa49e661946a0e147240b0e5aac174252c96481ab7ddd5487435',310107000,NULL,NULL,'a550df26b8dee075bee82fc59c44ce5cbf65fe9df10c60f3f3009faa2791c783','67aa51c5a5ccaa239273a7f9b4fdeca11126f6e30e6d5ffc99d9431328778cb0','3df5fd222e7fda201e4cbaa99f321b2a73073e6e6b83dc9c4e03c21a8275ca0b');
INSERT INTO blocks VALUES(310108,'8f2d3861aa42f8e75dc14a23d6046bd89feef0d81996b6e1adc2a2828fbc8b34',310108000,NULL,NULL,'e1d8c345c74760010223a823895471d3ad6a2db5c6a70b13850d5cd977414518','916b7cf50fc15ae71c69acf1b707466233c009b174a388ca4472f99d86d4125e','1d768e5024783de603e65a16b7541c877ca33602ab03833dc09c014bfe08aa7e');
INSERT INTO blocks VALUES(310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,NULL,NULL,'8fb63d8460a222163d15eab76a61e383ffa251a175c16f209648d6782c304059','0e478fd6db789d1e5823cf2579146d751f6326c5aafc387f0ab5fe622f1475e3','915a2ef99e5bea2a33502186395f25e9b192db26286a338a754e9791c700ddc5');
INSERT INTO blocks VALUES(310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,NULL,NULL,'250f7b5c6f00bf06c9cd4de8dea0b8166e2decf093910ea32eabd615b910e7e6','e3bd0a71047fad1dc1c56827c57b7fb1dec6c0f1eb9c23634ca4df6defbf98e2','cc0e45bbef2909163212395ee4d3c61bd2e9a05ee28dfe36314c968c7f637eec');
INSERT INTO blocks VALUES(310111,'fde71b9756d5ba0b6d8b230ee885af01f9c4461a55dbde8678279166a21b20ae',310111000,NULL,NULL,'0c3c3d099bf08803f67c2a77d0d67779674d1063cc72d8794b8fe62a55049d75','9d461b8540a7534c81f03a0dbe70a8392b226d63c1a15501c01230f5b2e8811a','9f1d6fc87a91539c9be4651668432a57713237fc5ff68ea5f661348c97eed17e');
INSERT INTO blocks VALUES(310112,'5b06f69bfdde1083785cf68ebc2211b464839033c30a099d3227b490bf3ab251',310112000,NULL,NULL,'557fdd1240793f8607a2b4c638ce800d5260c2adb294aac95d6c5eab7e98c3a9','e11c4c5e10029301ebc6c9929be683f27e64a0a298c488b560aa7e43ce6d8349','c5c7974c8cf89a1823c26c48ca792796299196bb68b9e524518aaf0ea469e9f8');
INSERT INTO blocks VALUES(310113,'63914cf376d3076b697b9234810dfc084ed5a885d5cd188dd5462560da25d5e7',310113000,NULL,NULL,'4ecad4a5c8e9b54101c4a037d6c86a7eb36d3cf0503e60a1bf13c5a4196c5989','5bea44b1b28d1b9dc3f425c32ee0e53cd157abc13cb6ee898bbbeb1c3a0d22b0','e0489426d8ad4dab9ca2e8a499d0a4f42fd46df50c9932a1617a5ca1a8416919');
INSERT INTO blocks VALUES(310114,'24fc2dded4f811eff58b32cda85d90fb5773e81b9267e9a03c359bc730d82283',310114000,NULL,NULL,'00380ec3118a5e8f9cab403d10870dd5bc339421297fcb6196a3112d70541ecd','e98f8185a9984845185d7913c54f83c2f53dffb5a36fe8e57946fd2b1915214d','e29b262eab52345ac279f91379846327f1dcb504992b97435531858f67e65ccc');
INSERT INTO blocks VALUES(310115,'a632d67ff5f832fe9c3c675f855f08a4969c6d78c0211e71b2a24fe04be5656a',310115000,NULL,NULL,'0acd3a07c5df54e883ff9871852c961b00771d3f4afccb3b1941d0b1c7b300cc','a17e953f19623e68808846a06938f285e0749e2d0987569f6e2aa972848a1455','1fd06fc360a1bfee4db6caa7695560bbd32ceaff1853d30ea24b9f929958f5ac');
INSERT INTO blocks VALUES(310116,'8495ba36b331473c4f3529681a118a4cc4fa4d51cd9b8dccb1f13e5ef841dd84',310116000,NULL,NULL,'6c6845d3be70cbe9a71c33227983f695c96877aac6d3a8d6a6839760b4691d25','d9df2bf35b1c7ae44a8691d15bf40b9256030d62b8b81e1efdbe9ea78d20569c','f5fb1aee9bd68aaa6f9682b497bac2015c081f23cc666bbcec87eccd5e736584');
INSERT INTO blocks VALUES(310117,'978a3eac44917b82d009332797e2b6fe64c7ce313c0f15bfd9b7bb68e4f35a71',310117000,NULL,NULL,'0465a90ff545d58e69c07c204160360bcc6fba5cc60fb81d7e6e389d9ff8133e','49244964fe400b26274e945fe10a4920c4e89d6aa7e456a914c34bfb91752e86','fb176fb88140d5ad1f20dceb6b6b232374eb9a1cf8fe43d8f1e4088b88daab3b');
INSERT INTO blocks VALUES(310118,'02487d8bd4dadabd06a44fdeb67616e6830c3556ec10faad40a42416039f4723',310118000,NULL,NULL,'011ed3df8ae72a02b686e98aa8db07c973e1e12c2ac09891ba90d783ae63161f','b92d8d98ce77b6e8fdd9a83ffe4acf536a914de64317e0c1f12083f5ef75787e','4ecfa8564500a1c5a0fd3b613da2c504e19bf92833624cdbc25790470d871a4f');
INSERT INTO blocks VALUES(310119,'6d6be3478c874c27f5d354c9375884089511b1aaaa3cc3421759d8e3aaeb5481',310119000,NULL,NULL,'a6620b1b6a5b1f54fe6a8076fc35f0f3ce15315e9f549f5ff3fa0f5b6094919f','d6081506030f43ad7775be58a4a51ca6ca213873d116e32d42122e55713ffc99','328e7e9255ae45e1ee648940b9a94fb9093e9481a3adad5f07991ce1979effc0');
INSERT INTO blocks VALUES(310120,'2bba7fd459ea76fe54d6d7faf437c31af8253438d5685e803c71484c53887deb',310120000,NULL,NULL,'e38e2aa0bf8831b90e69b40c78d4b7d41bc564527451b5f9b332bb0beb54c923','9e97e48c1396b69ed4f8281d20290918999832084f2430b138d0a3f27b697f60','b8f539d26edc746686797592ccc043f453382f6b9e27002e8bda5449b0442189');
INSERT INTO blocks VALUES(310121,'9b3ea991d6c2fe58906bdc75ba6a2095dcb7f00cfdd6108ac75c938f93c94ee7',310121000,NULL,NULL,'5b988c8ad133bb5ff5ac1ee4ad0a6a4fd431247db373e43c9be2a020520f438b','a539cc4e31218e8ded53c91949db977b5e3f342cc1f0d2007462e7c7207acffe','aa32e729a2e45f77d192db5d878ad3acbce868ec2059c349120b53db7f046181');
INSERT INTO blocks VALUES(310122,'d31b927c46e8f9ba2ccfb02f11a72179e08474bdd1b60dd3dcfd2e91a9ea2932',310122000,NULL,NULL,'70ddab8f1d6283ce5a054650dbcd02d7ad4ca9c35de7bed920c2f266bc092070','289e85276870a4437ef0ca299b3d01ef7105ddcce17cac0d4f842e43e1dad1c6','49a2be78882dc63c4451b4466b5aa0135b07491c078429aa02624f31d2a2d1ed');
INSERT INTO blocks VALUES(310123,'be6d35019a923fcef1125a27387d27237755c136f4926c5eddbf150402ea2bbd',310123000,NULL,NULL,'3670feebcf979edce175ad5b296a4c88fd7fc6bdc251dda84d487b1b092e41dd','719e4fe7306e1f3992fcc6f7e655908dee1bdd4d736f2fc9b5d8432cf8e4321b','d5d880840e7e39dc08fa54454c3357a32e55ee655138ba5f337b1d3449083eee');
INSERT INTO blocks VALUES(310124,'0984b4a908f1a7dac9dcd94da1ee451e367cc6f3216ee8cdee15eae5d0700810',310124000,NULL,NULL,'9883fff318e7cf9021fb4cc39261840f682e8adabb934549dbae2a10d2a71de3','bc4b7b60aebff2f8a6f0a90a3ddf1ae825b75cdc67cbec5ad697679dfc9798a5','cfc038baf2c16a2b69e057380d6d1e26b4cb87670606f07c1047110e1a0a0c03');
INSERT INTO blocks VALUES(310125,'cc28d39365904b2f91276d09fae040adb1bbbfd4d37d8c329fced276dc52c6a6',310125000,NULL,NULL,'1840685242f9090297d4b432e305e4a093f90faa0b673953b648fbed948f31b6','fffc4ade708201ef1db941d52fb286edb95dc52d743b923db8a6e4b67345165e','c397b204931280cd0918c3cb934a583fe58c25fe462ac831f2465233cabcaf82');
INSERT INTO blocks VALUES(310126,'c9d6c2bd3eeb87f3f1033a13de8255a56445341c920a6a0ee2fb030877106797',310126000,NULL,NULL,'1a83f417c18439cd3c6269626c44b480317290f0c27a9b9f883a01653de69272','e4de345ff05c685bb356a80c6e35f518a57d276d0cbbf3124af91b0684ce13c5','16bdaf9c2ebe478ec0525dc853a99bda624e1712e9105968f846aad6b291abf4');
INSERT INTO blocks VALUES(310127,'c952f369e2b3317725b4b73ba1922b84af881bd59054be94406a5d9bbb106904',310127000,NULL,NULL,'094c53dfd00b5004d074987dba90a6c9c47841d01041d0aeb61923c48315d1bb','cda853e5e9079908e0bcc224c564324d89adf44ec628ee23c83e417b07298f84','72acf1d16a41dd69961d1b5b528a29fb2abb5e4aa25e8d8b743513a3d6822260');
INSERT INTO blocks VALUES(310128,'990b0d3575caf5909286b9701ece586338067fbd35357fec7d6a54c6a6120079',310128000,NULL,NULL,'28ad1365daaadc866e79b6b1a555fa31bd804a85827d958cebb9d29511f78e19','1e514d834d1e4bc046a7ec8aec390eda0dba89e7668aaff1c397fdb536f3b362','59e3d59cb72f2791974492e1dec06b1dc31b004cb834512c434af0176e1a5111');
INSERT INTO blocks VALUES(310129,'fa8a7d674a9a3e4b40053cf3b819385a71831eec2f119a0f0640c6870ca1dddc',310129000,NULL,NULL,'61587f9b5d05f8f553f0a4f580f38a140edcf7d9facb13c542865f5ec586a32c','36d4aa6383577e62add0ea6b720b19450cfdc30a4dc04715a4db6a8dfb877d79','fd1089b4fad88df4cf00f7c6ef195552dd630089a941b6fa9b789596e98c2810');
INSERT INTO blocks VALUES(310130,'d3046e8e8ab77a67bf0629a3bab0bea4975631d52099d2ddc9c9fa0860522721',310130000,NULL,NULL,'1ee8c39657890ac946e2aac5409147cdbf1b0004db1f00d997cf45452596f781','47cda5297a15edb54398f98247b216c1346ad77acba914e958d79bd20116bd95','8f19f2a664e6e081dde908082b53d283d36737432f829c304d7a64dc2cdc0dcd');
INSERT INTO blocks VALUES(310131,'d6b4357496bc2c42b58a7d1260a3615bfdb86e2ce68cd20914ef3dd3c0cdd34d',310131000,NULL,NULL,'aee45272e68725a2746582f1847582eb9808289d3deca144f8c6cb43bc4f42e6','9360404f33baaf439d8fa6bb56fe74a3c287ff4001f323d2f2258eb7ec6464bb','ca8eb34aeecb84c9c5c8843346bb1aaa6711c4648f19304fcbbb8ff52f06b2cb');
INSERT INTO blocks VALUES(310132,'1b95a691bf4abf92f0dde901e1152cc5bd87a792d4b42613655e4046a57ab818',310132000,NULL,NULL,'a3fe51c1d168ed726a78b72db61175f2abb07ea6c614b2886f3054cdd1a858fe','92dae5047f6334e996fb687bd0ac1da3d1e982cb41b7c95398bda95190e0ec49','5e70c803f25fb73e4c9f506f73f9c0c02f7d0cc38cbef6ae410222fe262936d9');
INSERT INTO blocks VALUES(310133,'1029c14051faabf90641371a82f9e2352eaa3d6b1da66737fcf447568ca4ec51',310133000,NULL,NULL,'626743e51b462163f23f22079d672379def21382fd88f9155ddd453ca3d633ef','e9fd8e2c5568a19be6da28a85a02756d8c5bec47c3e4efe46102030aaacc0e51','901cd70d5cb4cb85a54d6610182754e9e8e5ca6e162b71183f55e618f3ca976e');
INSERT INTO blocks VALUES(310134,'1748478069b32162affa59105257d81ef9d78aee27c626e7b24d11beb2831398',310134000,NULL,NULL,'4b6e3202cae46fa80222e3ddec001213062ab76b8848eaaf4ab73f44bd84ac55','e17ad23b1408fdcb3963a28849f2bdc7ae3b37a18eed76d3d1ac4702601537c6','8495860ce2170ac73e448ade2430d4d5ce9510662d0b09befb8483de07c612de');
INSERT INTO blocks VALUES(310135,'d128d3469b1a5f8fb43e64b40f8a394945d1eb2f19ccbac2603f7044a4097e4f',310135000,NULL,NULL,'e32784cedeadac39bb292da2c5eaffc983f416e0bf387978691e4c0fa5b1715a','0dd53dee532d924741c92a72dafbe91e15acfa49c3171c76a7a13d76230d9086','e3a6983c3bb4356a1d9505dd39561f973aeaf933ff2f98083e64e16144433175');
INSERT INTO blocks VALUES(310136,'6ec490aaffe2c222a9d6876a18d1c3d385c742ff4c12d1334613a54042a543a5',310136000,NULL,NULL,'93c67fdabd991708d1e35dabbdf7acb4e928763eeb817b32a79cd0bdb414fd2a','64acc571fbb0d14272f97b8fa24706ddd6744260c143ac8b5626cfe6b67687a1','ce042f1a1d6065576d9c88b86ab7e56b4578516a24f8a94a60579e2b75e2df21');
INSERT INTO blocks VALUES(310137,'7b44f07e233498303a57e5350f366b767809f1a3426d57b1b754dc16aba76900',310137000,NULL,NULL,'8a43d01155ba47b8b1311c41d5a57112198857701c2970d0fd373da04ef4e585','b53ebec2b854b66f60c4a993945195d93f39f71277be95a51b3dc05b8b1ee18b','46636f1ad9a4e7513ec9a2b015e3722c304177e5338b6885e0deb11a8ead75f9');
INSERT INTO blocks VALUES(310138,'d2d658ccbf9baa89c32659e8b6c25b640af4b9b2f28f9d40baae840206402ab5',310138000,NULL,NULL,'4acf0244f3188f60152acc8ca30dcaeadf12e6669b15377c81b7e6dc3c8892b6','ab8a4c24ca358ca1b1da99a067daf3b276aa072cccc1ae153a224936b18c5f83','93df73667d3ecec5c0275212202b8178fd4b772b20bf8b1c684f2e377b5b4f14');
INSERT INTO blocks VALUES(310139,'b2c6fb61f2ae0b9d75d18fce4c52a53b1d24772b1ad66c51ca51090210527d46',310139000,NULL,NULL,'2d77bdd47ed1b3be1c2edf41473bd5eb707d06dab33717b01c4a227f9855d73d','9156034707c7440a6c56018a7b5a35eae96713c3fa2142cbd9634565ffd5af22','140b91d18e589aa35ccd5b3a9a69235ba709e3e2db447732f598b873d18de19a');
INSERT INTO blocks VALUES(310140,'edddddea90e07a466298219fd7f5a88975f1213289f7c434ed47152af6b68ebb',310140000,NULL,NULL,'277c0c6dd1c505dc6f9a222c737296396569d8e007c4b9a42582f108e90fa624','c882d908b84409f2effd43a438ae5c7f8b1f89479c89af32b5e5dcdcf9697d33','7c578cc443ed679012e29855f19398eb90dbbb80c6c113817874acd8789447d4');
INSERT INTO blocks VALUES(310141,'b5b71d2a271bd638561c56f4ffbe94d6086debaaa86bfeb02ef0d71339310709',310141000,NULL,NULL,'f5d0edff3f22b2e025c884b7c738abe641bca9110a6b9a7b90de179fd6e5d2dc','8eae733fe82a61b93305afac29cffef82249a3776f6676b5b2bbfb240822ba44','4fc1008c35647460be162b1c4cca5d1933b3dd6f7953f171368e96b813faf48c');
INSERT INTO blocks VALUES(310142,'a98ae174c41ab8fc575d9c8d53d8e02d8e446b8c6c0d98a20ff234eba082b143',310142000,NULL,NULL,'a9f00ec826a30e66820ab2920cf9573244a24dacd63d48c080b9e80b1c5e05b7','c422a01a0cc18a533cf42a05d83ead2783fd31bbfaf1767f6686a07ebd5eae9b','faeca60433573160d16eac8379e15f17a4cc33a4606d978f009b99f0b55c5c4d');
INSERT INTO blocks VALUES(310143,'8ba2f7feb302a5f9ec3e8c7fc718b02379df4698f6387d00858005b8f01e062f',310143000,NULL,NULL,'b5765899f770fdb6cf1120535d85826c6b0ae44b16b8d5a619c5cd12c98783ea','191b8a6d58c089b2e889766a20a4d01f500c648241f96846f71ad1db748a39a9','726095104fbf7128f0f93c5503605050c43ca41e0637b15f2b644cc6fe0d9c01');
INSERT INTO blocks VALUES(310144,'879ffa05ae6b24b236591c1f1537909179ed1245a27c5fdadd2218ab2193cdb9',310144000,NULL,NULL,'1a80f48136e5938b33f817a7cc1cb60aaf6d628b7811abd43e38cc807a18072a','238296aaa498d3c8bc112aa634275e18e4afdb17d46776b1ab563eef3ee9963a','bccd2431fc732000b37e336b2baabe93b97700e448c4d3b15f4c8d6423e78b84');
INSERT INTO blocks VALUES(310145,'175449ef0aa4580593ad4a7d0c5a9b117e1549ea772af00caa4ccdc9b1bf7a6e',310145000,NULL,NULL,'fce2f084c1776fcb36b3ae3e0c952893934e24672ffa0d3dac72bb1278af8264','1d51eae9728b9100682ba7624af1a3666afbbe9f17c2f08a6b9d524ac2927b46','70ea4827763bbca4e44ec69087d2aa0ee2915fc7ba979db26bf8095b00fe1038');
INSERT INTO blocks VALUES(310146,'e954ab6a110455d745503f7cc8df9d92c1a800fafdd151e7b1912830a9cb7184',310146000,NULL,NULL,'9a98eb971580a0a69fceafc5fd41f398f1908b626c47df57965d1863e9a24b84','8d25f726f189adfec68d15cf2fb2304aa30034d1b897095e7a640bbe82065818','584890e5f4c2ca4b701e7b0bf8309ee0a5cd471c5e05a59fc580084eb408834e');
INSERT INTO blocks VALUES(310147,'7650c95eba7bf1cad81575ed12f32a8cc36281a6f41bef13afe1dfc1b03a7e83',310147000,NULL,NULL,'336a89d3d137810d3220d2de432f72e3b3ccd2ada2b746da3859c77dbb89d6a3','c529b8f4384fc9a4057b0b61de98b72f074715ec64aec0fc23fada2c878d170c','2d790c9567704a753e7bfdc6f396c10ecfbd8aafa0dbf46560fa1d082fd9429d');
INSERT INTO blocks VALUES(310148,'77c29785877724be924f965215eb50ffe916e3b6b3a2beaea3e3ae4796545a7e',310148000,NULL,NULL,'f904794337dd67d356981d2623b8c3d1d78ba584cd98a8c1db939951d3102612','c72a91ec0b580ee15a1c1d0205c0633e7a46b95f6aff7338f5aad16132b149ff','ef3157bc81b6325ab25af9a34c6bcbf52b96cf254ccfeda35cda75f2d813f3a2');
INSERT INTO blocks VALUES(310149,'526b3c4a74c2663fc04ed5234c86974bffddb7235c8736d76860778c30207b3c',310149000,NULL,NULL,'c2972fbd048790f54d9ecef4e18aedec8ae7aa28227d1d43bd19cd71b4feff85','1b550c4c4f7ee35d7e32fafb4fb77bb081b5cbc2903f3de5a7bccfda1c5e5c33','7dbaea6e496bf5d86631a07e1ebfa2d76816889fca9a4b9f0db3e1d7a8ff725a');
INSERT INTO blocks VALUES(310150,'cdd141f7463967dbeb78bf69dc1cd8e12489f58c4ea0a5dc9c5c01ec4fcea333',310150000,NULL,NULL,'88b999e4ae34386b826b0f3b315953b5eeda8d9ef496af051498bfce6d8737fc','15619d5374a2d26c1343c44acdfa66e6baba73bc1f01ef715a17c6e3812f81d1','8ed5241c98ee19446c978dca2d228cb34877b213d6e47b894522438b7d59fb37');
INSERT INTO blocks VALUES(310151,'a0f31cc6e12ec86e65e999e806ab3bfa18f4f1084e4aeb4fbd699b4fe284b330',310151000,NULL,NULL,'b7c176a2eff86655f8b0b71cc8bd3bab3a92ba203d4ccd911d63f3d2ce7fdc25','1a497ed2cc8e2aeba59750bfc4413f653b9392f4147d432512beafe0023141a2','6c90f9a4c15a5ed76a7706983f15c15fca9e1261a542db6a516ddff887537ad4');
INSERT INTO blocks VALUES(310152,'89c8cc3a0938c63a35e89d039aa84318a0fc4e13afac6beb849ac37140132c67',310152000,NULL,NULL,'3f9471c393bc2bf144b17a5febea88c42982ae746fd700a5903c0e6e541e2b09','cbf06ace5a8715ca030f6d4835bcf41b47b9f2e8dd14ddc358f25575d3442281','4aa103224fdc49cd25b89e8ac68afc01b3a2071d8e7ec9d60ff4a6e8974611bf');
INSERT INTO blocks VALUES(310153,'d1121dfa68f4a1de4f97c123d2d2a41a102971a44b34927a78cd539ad8dca482',310153000,NULL,NULL,'c6bc81e7b7e6758bbbfe10fa0e688b09e679fb74a18134639e172c18c6e017a7','48536be2fde4290927ccd5fb91fa59bebbc9209ce47a878e11d1e4c4adb62189','7ca3d7f2c6f187514e8fb232f31e1015a59c10b813852b2be08a7efcd9910687');
INSERT INTO blocks VALUES(310154,'ba982ea2e99d3bc5f574897c85485f89430ae38cf4ab49b7716ed466afa506d6',310154000,NULL,NULL,'b3e07f9de85ab67e88042b1bb52302c6eb16b7ff45d5be6a49700f115ed396d4','eb1db12be0bb913a56d21c80ce0461a5f0468591469a2de95974f55f2d2aa197','ed9ab1b8937e287cc1186062360ed6a4e75837e5c89885c31e9da50dc3b8a5da');
INSERT INTO blocks VALUES(310155,'cefb3b87c7b75a0eb8f062a0cde8e1073774ae035d176e9769fc87071c12d137',310155000,NULL,NULL,'27014841a468e23bcb70c718919745eadcded4310031a7be90a4732c96509404','6c49c35e501269d4c6738dd2624ba92c2e6696a9e9c1ca7a77a92c57734d93a9','a2575c50fea0d2e62363dced3565c543c035a434d8c7ce524e9948b9ceea5d3e');
INSERT INTO blocks VALUES(310156,'6e3811e65cb02434f9fde0445a7a2b03fe796041458737d0afcc52208f988a83',310156000,NULL,NULL,'5597aaadb8cc75848219f9fde3f5d76bb5592689c72068db59922732e89eef9d','2478b8d4e5d43e0e79b4b4852da7be50767bc10a7bb56830c83878015e72408a','19949c34a4ac98bff24bd175ee867e57cc41330ce8d111deedfe28cfebc28434');
INSERT INTO blocks VALUES(310157,'51dd192502fe797c55287b04c403cc63c087020a01c974a565dd4038db82f94a',310157000,NULL,NULL,'cc1ae27fef286424e40204f6b575e9e079e1f7a5ccf6cc356729a7c4a7f83eb8','edb1a3abf4a491156c16eb7a05bcddd3847fb0a248ac416285173853630adff4','b41ba71d905ac8da61c39db4ca1f775c7358df7232cdd1c3d83817e1bb253aa5');
INSERT INTO blocks VALUES(310158,'749395af0c3221b8652d31b4c4410c19b10404d941c7e78d765b865f853559d2',310158000,NULL,NULL,'6d80d98e778b30c124b0255b3e72620f432245d0f841f6bd62a0fcff44843bf0','176df3ecb3cd79a459d4efaacb7a6849fed1b9210255f89fdc9c5f65d8512acf','df926ada83b2abdac2e23052dce4c572c7068f7d2621c7c95df0e738b011edff');
INSERT INTO blocks VALUES(310159,'fc0e9f7b6ae99080bc41625588cef73b59c8a9f7a21d7f9f1bf96192ba631c12',310159000,NULL,NULL,'d8ab8bb14092afea6cc675d2f50891318e3169bf9dbe2d07e80c4db95f0f2033','21ddf629e505ce7e673aca4d1d3044e84f58c93d0894b631e26dc160d4eceb70','94a4ce2d2b7b85efd1bc1b12f76538a3f580cf6189139affdbc416a7bf4de032');
INSERT INTO blocks VALUES(310160,'163a82beeba44b4cb83a31764047880455a94a03e859dc050da782ed89c5fa8b',310160000,NULL,NULL,'2d76a042d062b73b7dd956d5cff0ee397f068c04eae6cf5b9522d3d55e88cee9','6d02d8ce522aa2820ca0e3f491c294c5bfc182cc856ca8fd0476ce417c6fde57','4ad9c790717e236238e5ea772300258eea0f0af5a44d4a9f919c8accf4f3ddff');
INSERT INTO blocks VALUES(310161,'609c983d412a23c693e666abdea3f672e256674bf9ee55df89b5d9777c9264d8',310161000,NULL,NULL,'beb3496742415027bcc0d59f3385809523c8783cd91a5670f2fb6fec3230e980','7ab8ff9d061cad9447edb016950df40217bcb2b6157e9d12f80f7edc732230db','8423151b04f173809c069326ce7e1ca24ffb5f4ea870388d76158fda65a8f3e5');
INSERT INTO blocks VALUES(310162,'043e9645e019f0b6a019d54c5fef5eebee8ce2da1273a21283c517da126fc804',310162000,NULL,NULL,'066a2b93df863300741145cd6a4f1a9ea616bc787861cb8ab809f59d47a6fa1f','82b576cf11dc04712d54c116fdb8c332a84bbc20165633d62d69ab5c4851667b','ed0cc54172f00bae83578b7ceb114faa0918209fe6e4c1855560760ee2a443c0');
INSERT INTO blocks VALUES(310163,'959e0a858a81922d2edf84d1fbb49d7c7e897a8f49f70bd5b066744b77836353',310163000,NULL,NULL,'460c271269ccdd8775925b511705207baed8fc212caa7e74fc08a80be600a38a','34d5b4512dd28171454260b321541a0abd66bfd37b74889f4d91ebf0c5a44a0e','3061f829b038356a41f5ae6eb87c8dd7aa9985ed395b36446ef5ba82039b38f9');
INSERT INTO blocks VALUES(310164,'781b7188be61c98d864d75954cf412b2a181364cc1046de45266ccc8cdb730e2',310164000,NULL,NULL,'19a7948cd1bc4a89a427d48bb01330dadff848e2b32ec8b8abe342872850b268','e7b82bea0d4cc756b8dfbc9e0c01affc0e26a0d3d4c5c129ce31393011a96578','bff20ad27118901a059f37be8204648eed4d3e589df88b36239c29c8963f0db4');
INSERT INTO blocks VALUES(310165,'a75081e4143fa95d4aa29618fea17fc3fabd85e84059cc45c96a73473fc32599',310165000,NULL,NULL,'97f0a48a26daf011a8c7b22bb772228a0c8a920eccd011e713956100c9fbdf33','275157ef5be5bd2ee74c97964fec858499e9fdd588f48e08364c22a6e7fbc124','567372284db2f476bdf2d9528a1c49d530023a8246078efcdfc4a637e0075cf5');
INSERT INTO blocks VALUES(310166,'a440d426adaa83fa9bb7e3d4a04b4fa06e896fc2813f5966941f1ad1f28cfb41',310166000,NULL,NULL,'edbd00e1229c673f4f15b3ac7bbe020f54b5f3a61b1d158658471076a55c77b0','34f0b82762c791251332b8a8533b2fd0294a269320a98d262ea847cc84395414','cb33aa8d2d3fa245a4f2274add6d070c22d474662617fc40e2a031d330009d4d');
INSERT INTO blocks VALUES(310167,'ab4293dbea81fedacca1a0d5230fe85a230afc9490d895aa6963acc216125f66',310167000,NULL,NULL,'e118e0f3aad5be73080f4d1892517e8fd2c4575589ccdfadf980edebb9a66a14','fcb92b27e70c3f4e4fa9e040be42f4402880dc94cdcbe8ec70abc7edcb35ab9a','60db3125515daec542fc00fc51e21e0868636ad8d08b167a56a16bd347a19e11');
INSERT INTO blocks VALUES(310168,'a12b36a88c2b0ed41f1419a29cc118fae4ecd2f70003de77848bf4a9b2b72dc9',310168000,NULL,NULL,'267f48eb4e3b0925f4f472d8ce6ec57ec5039911b13a14ff2884a41a9cafd7b1','745a42af3c334ea144d0161ba4cb9fa0ec3b1b82e767ff4092a1247d1aa50dc8','298b3be2a774c1dff90fd86b8d7f05664ef80f7853e368e1c614b638075c80f3');
INSERT INTO blocks VALUES(310169,'204809a85ead8ba63f981fc1db8ae95afe92015f003eaebbec166021867421f3',310169000,NULL,NULL,'df394a6f3b2a9b9dded6019dce9f3d3214db1f30019faffbdc2ce614f629b25a','04ea4e32a3123d4840c9387e019ff6f536b0523f9f4b16292f7fb3d640c358b2','ab9c92a8e0fc8dfdb162e9bce6f060d2e9132633ab6730c737179ed7ad7ea0d9');
INSERT INTO blocks VALUES(310170,'b38b0345a20a367dfe854e455e5752f63ac2d9be8de33eab264a29e87f94d119',310170000,NULL,NULL,'3081081c2ab6d8280ef721c5836d0fb7e89eb3d747a4e4522d2e22f5a6b153a2','745e599039410380cb5a39a30629e6661e28b676cb8e0b84bc3915480715e52d','002ed39b725f2fb67de7558c57f2b2a12c0914aaeaba1c1a2a42a43581b18961');
INSERT INTO blocks VALUES(310171,'b8ba5ae8d97900ce37dd451e8c6d8b3a0e2664bb1c103bf697355bf3b1de2d2d',310171000,NULL,NULL,'e6a4017e4f7d9da50bb3817990c3e115d5035443de8824dc01b5380a5b4c52a9','5605874ed07ec2b79fdc11ce7a1b2d4f19cb9403639745d9584cfb831c6dbfb3','4122ac3f74f2d45ce2b03c7ff9f99780fac545dc02a1373e740de44849ac415f');
INSERT INTO blocks VALUES(310172,'b17fda199c609ab4cc2d85194dd53fa51ba960212f3964a9d2fe2cfe0bb57055',310172000,NULL,NULL,'89e90622bf8363bcee5cd7ab6d48b6d06ce4cbd067f9985e35e67fc683f4c103','defbe55d64068742e020a78c7d2e880a9ca407257b4d6c17b4b5b40e84122817','d376f3798b3c34ee0c75fe0935dc6a7ddb23a3592453731c3ec1b9474d5569ca');
INSERT INTO blocks VALUES(310173,'f2dcdc5ffc0aca2e71e6e0466391b388870229398a1f3c57dec646b806a65016',310173000,NULL,NULL,'35ceee6a23757fa49e7f5c34ccf0fd034731e95d564257b443ebfdee7cd294d3','b8bf1ccb1f769f0559a5b8a39899d42af61cf8e7aa5680c6b905186769f337f8','87e07f244eafc35e5fe0263c14d4a428407df88ad540e6513d8364fe320cf7c2');
INSERT INTO blocks VALUES(310174,'fa6f46af9e3664353a473f6fffce56fa295e07985018bface8141b4bf7924679',310174000,NULL,NULL,'101dedf34bc0788c0589c8e2b1d7da4ec65f6eab2e3c5523c0903db685cab017','57ac656234cdbb7b8d0ab2fc6ac1dac7429b875763529fe13885ff18d09d860f','0132e704cc731c090d54145c08da360ead1dc44fe2109218dda60078305b7f25');
INSERT INTO blocks VALUES(310175,'f71e79fe5f03c3bc7f1360febc5d8f79fc2768ce0ff1872cf27a829b49017333',310175000,NULL,NULL,'67de4a0a9e52d9ae06caf62b3412d0bf2c10a6b24716210b21212d75be75ad6c','6aad646d6dd3808448bae6b5c00306ceb52a1142498782a553aeda89b24524e5','c77844e3a197eab8dbd46e0fa48693a2dda0cc587ff5a6b8d51c727aa2b9f492');
INSERT INTO blocks VALUES(310176,'67cd1d81f2998f615602346065e37f9ceb8916abb74b5762ead317d5e26453c6',310176000,NULL,NULL,'a90bd400e15727fada1a27be4a6e228bd91a15f0dbd0fb7de3b6779a8bf89e4c','828af1eea222edfccd87d4900ea966b3c2620539fb60b7fbd3ec80be9ceb4e64','a24ec011b66eb8bd39e73e32288b444d00283a1464a41cdf46206d2ad6de5717');
INSERT INTO blocks VALUES(310177,'6856b1971121b91c907aaf7aed286648a6074f0bd1f66bd55da2b03116192a52',310177000,NULL,NULL,'bac315d07dee18e27336a46ff3ffeed58aaf8eb1eb702e98a93c06303c937716','467249cab4533ff3a6e5fa6bdb8700f9b275293498b3552b3f8e265f16db0812','54be720630f40e4691b3c589851219b2ec6f7623dcc473b832c28a8915a1ff9b');
INSERT INTO blocks VALUES(310178,'8094fdc6e549c4fab18c62e4a9be5583990c4167721a7e72f46eaf1e4e04d816',310178000,NULL,NULL,'186ea0ece84d21ee21889ff13c98959dfc1842063a970e0c095552f0ca86515e','924d040441e2225191576f9c2128acbe5305c99be573a9d485b12bed48680d8d','178e1095944c3ffe6141aaf054ce7882f4f36f7557012f20080fca6a395bc4dd');
INSERT INTO blocks VALUES(310179,'d1528027cd25a1530cdc32c4eaff3751a851c947ddc748d99a7d3026a5e581a7',310179000,NULL,NULL,'0200402ef08256efa0adc85b2b4b15fb7448b5107b65fafbcc7985d809e84bc8','aa7a59be2b3b601aa0d71f8bf495a224b85e6605db20140e80df23f689c8b5c5','7c467e3f14954b7a8f08e59daa1f63628e315b46eb92605d70c3e444f44223ec');
INSERT INTO blocks VALUES(310180,'f2f401a5e3141a8387aaf9799e8fef92eb0fc68370dae1e27622893406d685c1',310180000,NULL,NULL,'13829eeaf9bdc54f87366e35616c5a57cd836c63db8a9ba7d117d02377ef43e1','8b16f083661945abbdd5f53332c1d746d7f59341c5250586de0627c3595cf83c','22e1d06c5f579ef0e5d10f66a75cbdc8cf1ff3068eae4d44dc99195757559519');
INSERT INTO blocks VALUES(310181,'bd59318cdba0e511487d1e4e093b146b0f362c875d35ab5251592b3d9fed7145',310181000,NULL,NULL,'81b4d83a623a55019ad720c1bd3ecef100d8ca49deda91b8ba6ffe9802764df7','504d7a96e01b8979349c377018aa9458f920e0cdc3c09c77574b31322d98c854','45fc0ff78a37f8e949e9511689f409d0f7ee4ac3b2ed23b6c73924a60b5553af');
INSERT INTO blocks VALUES(310182,'a7e66b4671a11af2743889a10b19d4af09ec873e2b8eb36949d710d22e1d768f',310182000,NULL,NULL,'935e40f93195d450b292481aac481f445d2de8786d04d26263f4adc5a348704c','085f3e0df816bc317c724492d0f7d7153323bed3fb7f9a010a8dd399ee63f5c0','80e74bab3649ca3eed365bff23637aa3bebaeb066b77c46d36946bcd44ff514a');
INSERT INTO blocks VALUES(310183,'85318afb50dc77cf9edfef4d6192f7203415e93be43f19b15ca53e170b0477bb',310183000,NULL,NULL,'268bf841be40615472bf4c60b5306d0763ed50510fbb55c47a6a0ac726e8701f','ca50c66c749bd315695b553eb725a9e6a3c29a399ae5b6ffe5c36cb8f0b13929','4345c59a312a79db3ea32f7e89f1741bb3d35e31faf47c591319b189209dcc01');
INSERT INTO blocks VALUES(310184,'042a898e29c2ebf0fdbb4156d29d9ba1a5935e7ed707928cb21824c76dd53bfc',310184000,NULL,NULL,'64323488ca4d32a1f548842db4ac772b750599ce6222020ef6149b4a0e54a935','8be1b5d80d01d3d9a8dc2479e007d577fc8263b3d368f59332560f9534412cdc','7f7f00c9bed612d025b672440d9f912d31c4d0d957894ab92313511a03bb1b7e');
INSERT INTO blocks VALUES(310185,'bd78c092ae353c78798482830c007aac1be07e9bc8e52855f620a3d48f46811f',310185000,NULL,NULL,'8946baadef2e19c5e4e4b2d771b36982a217486dcb0f95097b41ce633e61da94','5320b91cf7dcb4b2d00517a8ec48fbad80f47bc3a94ae1cdf2f781d18ba0487a','087a446c8832fcf3071bbbdd00c3e2c7444f6e5a708fdd93d5b73180a5c009cd');
INSERT INTO blocks VALUES(310186,'e30a3a92cc2e5ad0133e5cee1f789a1a28bea620974f9ab8fa663da53e5bf707',310186000,NULL,NULL,'e68b5525927cfee15fefee02a16fd700abf6b6e7b4e32e57df7d324fae7ae090','435ec84f55f3ace25ac9dc8bd68731aaf513e4a1559643b887477c77b9eeece7','8a428471b03627c8ca73e6763b2d5fe477d55aa622b0b52a8580d711cfcb6f1e');
INSERT INTO blocks VALUES(310187,'fc6402c86b66b6e953d23ed33d149faa0988fa90aa9f7434e2863e33da2f3414',310187000,NULL,NULL,'c42efa24d48339fc341908a30c6679beeadc9f5918d8d3e62d5c4b06fec845d5','ac2e855154f8dc9a3dab36cde207e068a859e74d80f075ecfc50447912877b77','61c41dd99e9fdbe5706241d4ed9b4bfcbc8d5539a4f90e59994fc2b954cd5315');
INSERT INTO blocks VALUES(310188,'85694a80e534a53d921b5d2c6b789b747aa73bf5556b91eeed2df148e2ada917',310188000,NULL,NULL,'13de1d9b569d5d2525ecfa39b1eda69f9fd474683b6e34554b1a755125e96e5d','e94a22ff07f51b5f1dbc17441d7dc5829b425da07e7eebbc3c938ba887d86b03','1ac542686e183bf0e4d21b76fa56eb5c7103290f52e74d9258f581786eac42f5');
INSERT INTO blocks VALUES(310189,'7c036dadf19348348edbe0abe84861f03370415ed2fec991b9374dbb0ca19a06',310189000,NULL,NULL,'582b8b3d3a226d3f6df497cb933ed5f42e1e992c0c25372ec15de424c0a33368','99a1d51ff7da680d24bfd24bf998e2f9477bcdac8509c03efa568b0467686965','4baca04e0b50d8c095495be5a1d04499e4741eff53abafffeeabec2eb762714c');
INSERT INTO blocks VALUES(310190,'d6ef65299fb9dfc165284015ff2b23804ffef0b5c8baf6e5fa631211a2edbd8d',310190000,NULL,NULL,'d4c49d5e3aaf21e6fe1c30663d0ba93f7dc9ddb03611e3751fba9aac8d382ac4','93da4438e95dde255baac5c79b60367b6fa7c05054baa7f3133e84792e852cd6','a0b54dd015451a01e54d39528d586389d30c64a672700a8be549254241fe79d9');
INSERT INTO blocks VALUES(310191,'5987ffecb8d4a70887a7ce2b7acb9a326f176cca3ccf270f6040219590329139',310191000,NULL,NULL,'23d340ff3f1979a43bd1336c9c882b5ee01c646cd104060feacdb5db78025cca','ad2b30b320539a7481a80ea9369da1f195f331eda182debe42b95c01e9040918','f662bd58da25a722f9a609e0817ff7e4c2d2161531c734b2e58fe59e42372a6b');
INSERT INTO blocks VALUES(310192,'31b7be43784f8cc2ce7bc982d29a48ff93ef95ba18f82380881c901c50cd0caa',310192000,NULL,NULL,'cd18860851bceba4a0174480ccdc0f6ddc47b31ce71af8ec8500cb07f75d9da9','22e2e9469407cfe99b237ef286855a39425010d911e22e1c27e5194913d35cfd','16878d2ddfbbd4e68d6ad6871bde82789cae6a2297fdbfe2e8476a1f6cdc9690');
INSERT INTO blocks VALUES(310193,'ff3bb9c107f3a6e138440dee2d60c65e342dfbf216e1872c7cdb45f2a4d8852a',310193000,NULL,NULL,'391e97ae7ccf5bc38ac72e7ad1256f24c28297c625bd9a789cba8231a5ade046','20dea13947f79c456cb7cd502972c4c75a7922a4e6aa9625146387f14a8f5134','88567ce42ff8db6e7380eec2991c91e5725f07bf0f7c61862c99fde454c49527');
INSERT INTO blocks VALUES(310194,'d1d8f8c242a06005f59d3c4f85983f1fa5d5edcc65eb48e7b75ed7165558434a',310194000,NULL,NULL,'9141c9b38087c7cf2b8c11ffd55c2eabcb3bb09f132ac0baf9c3779f628dd42b','b2f8c6473a9379b9774295fae95a3b78e1ab797d179d917eb79b3f1b3fde1039','c19db95dc5b2432d116687af741641dae826eb8b26e820507d10a01c78212d90');
INSERT INTO blocks VALUES(310195,'0b2f1f57c9a7546faac835cbe43243473fa6533b6e4d8bf8d13b8e3c710faf53',310195000,NULL,NULL,'705918f002db29e7b3dfbfd6378f79d53e33c6ffa3948b2e3b5c85f85009bbde','5a6dd936af8d8997bd30c50d7bffe8bed84c5c514bceeec9daeb8e0509f6d10c','933249665d32c2473a0327f96c75e0a7de19b4a777555b756d7e865538f51b92');
INSERT INTO blocks VALUES(310196,'280e7f4c9d1457e116b27f6fc2b806d3787002fe285826e468e07f4a0e3bd2e6',310196000,NULL,NULL,'59e12df19e3c0e3e23a5d1e9783c75e236a000774a038553312919a0f46b8227','ff8875a240b0ab841c617e6e48de0ec2d9f8440ac3d7aaacd607e958c0d230dc','a0485cf4624ede1e15e6226329d08d7509299e21b6e7ab99cae1d5699fa732df');
INSERT INTO blocks VALUES(310197,'68de4c7fd020395a407ef59ea267412bbd2f19b0a654f09c0dafbc7c9ada4467',310197000,NULL,NULL,'a0e1817dfc258180fa1629710ff3b6026181a9042fecd2c8b0b5e38118199e07','6af3be2ab53be33ef79488f2a0c2f75648b23c5d904e49102be884115e06db74','787664684e2039db2351a2c68cc345ba49dbd7a585c8c2d3224815d91d2b0085');
INSERT INTO blocks VALUES(310198,'30340d4b655879e82543773117d72017a546630ceac29f591d514f37dd5b1cc2',310198000,NULL,NULL,'ff51bfc670b1387bfce53781750e35a3bf69d907167cf9cf57e15613cc0ff3b2','036ebfc7d0728ee8710155267b5aea33728cd55143cd35c064bb538eaed48857','d7646b391ba9f6d604dfc0cb26735b299147148d78e79ea3d725b0d035af696d');
INSERT INTO blocks VALUES(310199,'494ebe4ce57d53dc0f51e1281f7e335c7315a6a064e982c3852b7179052a4613',310199000,NULL,NULL,'e5f8f8f00de32f0d8d2b62eba27218edcee77563960fe074da5ae86bf5b553f1','00eba7581bcab946056e3fbecf81ad6afc6e44d406153004f2bdc3d9461d0fa9','fc87528891adef10785f36e95d15d4d8511175a8554c02b989a65241c0850e9d');
INSERT INTO blocks VALUES(310200,'d5169d7b23c44e02a5322e91039ccc7959b558608cf164328cd63dbaf9c81a03',310200000,NULL,NULL,'fd8fb664576868d4f1c843b28efc7ee028417034a33d6f5635238bd13c701b2a','cfba4733a2f79e144111125e162b659eac864ce487e6f293e9320bb488b3992c','b3c869dd3aed5ce2cc274108aac7655db5fb70bab8381b0aa93d2b9e926ba7ec');
INSERT INTO blocks VALUES(310201,'8842bf23ded504bb28765128c0097e1de47d135f01c5cf47680b3bcf5720ad95',310201000,NULL,NULL,'7e2dbbf14c0620ac0fd4e0e676857e2d055fff80cadfe2d9d0dfe07d36738722','ee6a6849124448d915856966e35ce7a92c124e277e5fd2c7b0690831843a6bd6','1e48b8e4b150384475446823c2a5fe67848cef0afd5d425fcb6b912ea7ff247b');
INSERT INTO blocks VALUES(310202,'95fa18eecbc0905377a70b3ccd48636528d5131ccfa0126ed4639bc60d0003d8',310202000,NULL,NULL,'084c24e81842ec8edc4144ad64df9f12377318fe4dc491b307b7d377f3f81b2b','c8c7964a3acd407abe62cdb3fa5a03cf4076bb5ad4801980667cd8019a8551fe','ddadc9398dc871f1a788c9db13bb1979d189035ec2d54127fbad6bf3be83d745');
INSERT INTO blocks VALUES(310203,'ab15c43e5ac0b9d4bd7da5a14b8030b55b83d5d1855d9174364adbebf42432f8',310203000,NULL,NULL,'4b0b8d82a5a2c8600a09b1050eed4440d9e0f2d817498f3e32ba27ebcfbaf6d5','920cbda4b550b9592b113d0ae78ddf28d4779eebecc7cfcd8c47ca34688ba8eb','f1958cce9860342f448d2245c7bb3397cea961664f139c449ef2c15f478764a8');
INSERT INTO blocks VALUES(310204,'18996fb47d68e7f4ae140dc1eb80df3e5aba513a344a949fd7c3b4f7cd4d64cb',310204000,NULL,NULL,'9f81657142f7523c01595bef4e9008d8525c2337f6d90140e05abad619d94416','eb40b10c530f040a21ad23cbaac905907443a864313dd02e0228798aaa1660d9','0acbb99cf78de14a12521438252350e96e2e49067331bf74c7d6579bb356d18f');
INSERT INTO blocks VALUES(310205,'5363526ff34a35e018d1a18544ad865352a9abf4c801c50aa55742e71630c13a',310205000,NULL,NULL,'fd1cdea0193ed914cc408968efa42377d7c69453aa9bdf8bdf0731d4b1501b01','e45c4b2efb3256deb8ce0e508ac79b7005e478f6d086247790455e2fbb239571','6dedb3cbcf5e44aa3646b2690aa6d632d6d052217d81461d1356d1ce1ca21f61');
INSERT INTO blocks VALUES(310206,'0615d9fca5bdf694dca2b255fb9e9256f316aa6b8a9fc700aa63e769189b0518',310206000,NULL,NULL,'5845d6bedf81fba710999bf2954b3c1f3f9ca007a09d812ccae8e2a6d3b9bb07','dbfe96e6d95cb01a1fa151f9c4e231c4820a5f63b339c74d88322dff564be52e','521f3027ab5ebd7d9c36855a81ea291c3b532b4b78739fcb852d14fc9f176f57');
INSERT INTO blocks VALUES(310207,'533b4ece95c58d080f958b3982cbd4d964e95f789d0beffe4dd3c67c50f62585',310207000,NULL,NULL,'b65cf7069a0eb909357cd5d45129b70c576eeabc0cb13404029d088e24a2be34','9fdde2b66902bdce68123c5390b8ab74678e025ba1326e41f2cccf89dd9507c7','b70d3713a4f6acf7bb5a2bda392e815cdc468e53d66cf25ee5a8dded05c8cd14');
INSERT INTO blocks VALUES(310208,'26c1535b00852aec245bac47ad0167b3fa76f6e661fc96534b1c5e7fdc752f44',310208000,NULL,NULL,'aa54dc010fec8a0ef3871c91667c45e88ffac08ee2fc93274d7ad1b2b5b28102','bac0eb847e5a1ff514ff633f1a2b7482377321027adc4fcff75ed0da13cba1ff','e8b22d6df00e3dc4c57af6cce24df339bf0b9998381867694b8b356c89629889');
INSERT INTO blocks VALUES(310209,'23827b94762c64225d218fa3070a3ea1efce392e3a47a1663d894b8ff8a429bf',310209000,NULL,NULL,'c7866cb2098c87c1333da5b3dce4c84bdeb620c9f1898456b7cceb23e4027df0','86efd2166ad3a0485327aa745b175e9e790ad354c43875c33f7728deaa0ad073','77a930a234125af8a8f08bc4d5a574e2e20b8c9457f4feed3ed4799f294f3190');
INSERT INTO blocks VALUES(310210,'70b24078df58ecc8f7370b73229d39e52bbadcf539814deccb98948ebd86ccc0',310210000,NULL,NULL,'207a1c90d1658d55fa0fc2e1507fce98521647ab5c4d11099c2742279cc92b3f','2e435839dff2e2ef4654b558d8b304bda1ebb2d479f7ddba63672b5c7f2da8a3','6834935f73b4051b4bcd76b50e818d0633b12e036afe6987bb58756b6c7d0518');
INSERT INTO blocks VALUES(310211,'4acb44225e022e23c7fdea483db5b1f2e04069431a29c682604fe97d270c926d',310211000,NULL,NULL,'dfc7fe172f9bc77148a1bfad5d441a3688f718b4985406d0cefd4c4dcd926208','acfb695f137e20d7451165c5c664f0a1aa16f62db51ca4d132631908103ea97a','80f4e8463734adb23e8f53dcdf30066cc9c925a1f25ceb979042f671242c5cba');
INSERT INTO blocks VALUES(310212,'6ef5229ec6ea926e99bf4467b0ed49d444eedb652cc792d2b8968b1e9f3b0547',310212000,NULL,NULL,'32a39bff0606ec93454a2cb144c0bbd1939bf2be6a2ae369b885afc0b5ef33c9','7821aabdca20f884169d340e62827e874442b2db200d30ba57d75bac66715c58','462bcdf6a677fa7cd31148eb45072bb4d23c5fadc5ca6ed00d6cb62260a27c3d');
INSERT INTO blocks VALUES(310213,'17673a8aeff01a8cdc80528df2bd87cdd4a748fcb36d44f3a6d221a6cbddcbe7',310213000,NULL,NULL,'15968873880e97e849e59971d4ef19881b1c11c3148dba966f51d986c59ccf36','44e22a6d77ab0dbba76861de822c69ab946c5f1aeaf08e50d2e169cc1fdb6082','71c56909fe2ad9291fd82f271f56d3f7d2d3d50c42d536dfd0cbb004022e94a4');
INSERT INTO blocks VALUES(310214,'4393b639990f6f7cd47b56da62c3470dcbb31ef37094b76f53829fc12d313454',310214000,NULL,NULL,'dcbdc463154fe49a7f22611fcb53e5ca78501424ba741040d89cac9db0a03ac4','fbfbacda7e679a2fb6e8d28b3c3de565bc9cbf8c3fa4d7fc4c9ed71a6ec9ebde','b9588c5d0170060e50602e960d2c4bfd0e7c543e3e25359d6f2a179e6a788d1d');
INSERT INTO blocks VALUES(310215,'c26253deaf7e8df5d62b158ea4290fc9e92a4a689dadc36915650679743a74c7',310215000,NULL,NULL,'6047855f1c691f27ade1cc4c587f1c11ff68f5f5bd7959a23f801e5da7773eed','0d41ac1fec3eebddbfce292035d47997d2c3ada0a7286c3e5193e2737e6ec63d','ebf55d65638b8b962281e0c104ae1335cf06095fbe8374dd87288c0a372e307c');
INSERT INTO blocks VALUES(310216,'6b77673d16911635a36fe55575d26d58cda818916ef008415fa58076eb15b524',310216000,NULL,NULL,'a12fbb09858868de79095c8e3222f6fa179f2f00bc3c97c8205fd9367ae05aef','13fb950cbbb4310c23f7cc8b21a09cd6a5c29dc8c0b254985d8ae77d36d187da','bf5a325bb23a70a4f9e69a46e948aba25e6423b4723a17c11aff02fdf91131ca');
INSERT INTO blocks VALUES(310217,'0e09244f49225d1115a2a0382365b5728adbf04f997067ea17df89e84f9c13a8',310217000,NULL,NULL,'419d8dc096dd58523cd4822748754158f0c11945bbb62100cb5268cd802580a8','555677592a003ae66ea83a8dea9f33ea7bcfd9dcbc0f036863ad17f200ccbe1b','53db41a61542b6e5382027cd84da12f3e9c9fbd3dea8a1a55ad45aa5847d2ec7');
INSERT INTO blocks VALUES(310218,'3eb26381d8c93399926bb83c146847bfe0b69024220cb145fe6601f6dda957d9',310218000,NULL,NULL,'a36c07f7fdfaf7878d73baf14aee58b42220b2b2411fd1864450ec6ce1fbd173','46f03a93ea4bb4cc731d7bb6e1295d087e326b5e03012b068de59ab5b5673aef','66d5530aca9532f592bf9b72629bba5fa3e8b9f044197f2f08c6edf497a18d4f');
INSERT INTO blocks VALUES(310219,'60da40e38967aadf08696641d44ee5372586b884929974e1cbd5c347dc5befbf',310219000,NULL,NULL,'7958aa94088ecf0384a9a6b0569e9507d208e009e9ce139c823960e40996a47e','7e18a7a69dc5d085b872a594d9b5a3e58d971031da9312e1f89bc9e20f530023','46450578b51f0fd0dac7f7f510c206ebecf3395489909df1c368c10cf562a94b');
INSERT INTO blocks VALUES(310220,'d78c428ac4d622ab4b4554aa87aeee013d58f428422b35b0ba0f736d491392ef',310220000,NULL,NULL,'00907c4368c2dc76d1ef98a0ba3c86bc4746ed2734b0c10f3797e0af70714240','8d452de611c5cbbd05f46fc272ef88dbbe8a4ba27e1b68b70ff0a32731514865','6dc70b8da94c5d31eef564d159c611ca19c1e990fb565ce2e3ed7a83403ce6b5');
INSERT INTO blocks VALUES(310221,'cf5263e382afd268e6059b28dc5862285632efe8d36ba218930765e633d48f2d',310221000,NULL,NULL,'2e42f882087dc2158036592298321113f1b34e15b414efa6d43364c06d368540','c0764e91cde6b8ecfc32c78029bdd31e07798c0cee4e43985ab95312704b28de','2e80f10efb82f14735093addb3cd0f67a6b7076a88ff06019d8754fb24e31a54');
INSERT INTO blocks VALUES(310222,'1519f6ec801bf490282065f5299d631be6553af4b0883df344e7f7e5f49c4993',310222000,NULL,NULL,'00c4a5d41dd629bd0973c03152e4519214dce68498999c8dddc1f7a1cad28a82','8e0fd98d24143d2616c2712cbdd1ce8eb5a982f6d8b9031c8d554f16f909e270','ef638800d3dcc4b81283fb396f17114f7b0e1b1f850673c3b246699838fc95bc');
INSERT INTO blocks VALUES(310223,'af208e2029fa49c19aa4770e582e32e0802d0baac463b00393a7a668fa2ea047',310223000,NULL,NULL,'41c7a0fa22ebee9d55f2a3b118314293d155c349ba01069a23ddff76dc842955','20c8e7f20e664b9ab3373b6864f5cbecd44b50984082568942e8c22b3d8840a1','4a31eba029872983ac266498d70a6b089242ab635c3564f2d3857b753bd2d117');
INSERT INTO blocks VALUES(310224,'5b57815583a5333b14beb50b4a35aeb108375492ee452feeeeb7c4a96cfd6e4c',310224000,NULL,NULL,'66c268462442b69efb56b29e08aae1a404d3543e0a20711e8998a31af45ee929','60c09bf705da5081c224c1cb35b023dd592e6089ba2773eaa99106a07a079852','6386a62e824ac85815ad6de0cf959a8fecbca6cd15d5d027f4021a6f75362a46');
INSERT INTO blocks VALUES(310225,'0c2992fc10b2ce8d6d08e018397d366c94231d3a05953e79f2db00605c82e41c',310225000,NULL,NULL,'cf39fb28a7e4d4db7657bb11a30d592a15c049000d7ac86d4fb3d942bf879b95','0dc940206b542c2f5dd7858fae25bbe8f0e518ebb9e55a7e9465a6a1a9bc1325','b7dcdc52966c33878a63c4ab7cccd70b98e53cfdcfcace909019a962d7ec1df7');
INSERT INTO blocks VALUES(310226,'b3f6cd212aee8c17ae964536852e7a53c69433bef01e212425a5e99ec0b7e1cb',310226000,NULL,NULL,'cb622a4d04645ad96d3e0006f2b7632e8b82e44206d6c1cb75212b059fe18de5','8a9a76c298a11dc06d27fe662af1b57a44163b86b3be4dedaa498d16f6328ca1','9a0d0296cc67a2f3b9550b09bc561d6c92591748d94641964f21ff43d0ae874e');
INSERT INTO blocks VALUES(310227,'ea8386e130dd4e84669dc8b2ef5f4818e2f5f35403f2dc1696dba072af2bc552',310227000,NULL,NULL,'60ae4209347248a3f7ad39b6436627f06e45433f6b6dd89cfd3383d68974a41c','fa8f11878138553eb50f659bda2407521eace7ec269e9486b586560a80cc2193','9d186dedeb2dfc72a9219d1249c53a9e13af5f6449aba21ce4ff6acd6bed5865');
INSERT INTO blocks VALUES(310228,'8ab465399d5feb5b7933f3e55539a2f53495277dd0780b7bf15f9338560efc7b',310228000,NULL,NULL,'798206ee77c9e2fc8fe943f9bf2074c9c2560f534e3304b944e2ed3c89ce8bcb','c00812756c426c75f0e0f366269d092c2bc846e08376b79005b15a1bb9e78fa9','0900c04039407ff312efc0fb927e6253f3dcf706cdcfc259f362e12d0ec9fe58');
INSERT INTO blocks VALUES(310229,'d0ccca58f131c8a12ef375dc70951c3aa79c638b4c4d371c7f720c9c784f3297',310229000,NULL,NULL,'becad39a4d1bc8d73a856fa1d2bfa251f29b23fec9448a91932dc610243fd8df','fc92f5ddd944d8a77a398bf367ce1cdb43174d1e68d5a68bcbfa8e5ee3134919','8cafee2771a36286e86ba932f7525b5854ff7b4183a0dfe97a823510434ed97c');
INSERT INTO blocks VALUES(310230,'f126b9318ad8e2d5812d3703ce083a43e179775615b03bd379dae5db46362f35',310230000,NULL,NULL,'e08eac4daa7d7bc70f2f47a835bb80993d6d6db06d8d8986101b717db1c62ed6','fef4471af3bc26e1158c08c5ed797acd56c46dc46fd483308f29a7c7c6b2964c','19c5a6e00ce4ba4df771dcf6482914ceec23254e3c0a10e5ce6d9bad26134bca');
INSERT INTO blocks VALUES(310231,'8667a5b933b6a43dab53858e76e4b9f24c3ac83d3f10b97bb20fde902abd4ceb',310231000,NULL,NULL,'a761c29e76c9d5090cd1d6424beb91d0a9fd9546c67ecaa6d4879177b6745b59','252cd82cdba94f894e6156fe7b2df6ffce2b3101c3ebfc631105c9ab6f0b5cd7','70941d85dcfe0c728948113a18bee41e63e70a3a08be4176fa8ccaf8d724bbcc');
INSERT INTO blocks VALUES(310232,'813813cec50fd01b6d28277785f9e0ae81f3f0ca4cdee9c4a4415d3719c294e8',310232000,NULL,NULL,'5da469b7e21ad8ec4fe7cc2f426dcaeb18a3a4a3c44385d529a8b252c77a9e43','50414a7e78301d09f948577e325da12debe6d281a94cf018a1537e7f9cf3bd98','e702c73b1378042cae52f202ff96f515abf61ce2de502f15ea85a7c1128e0dbd');
INSERT INTO blocks VALUES(310233,'79a443f726c2a7464817deb2c737a264c10488cac02c001fd1a4d1a76de411d6',310233000,NULL,NULL,'d8531834d572acc01591997cac000185facc033e1ab72f8218a70d0ae3898914','26e226c8ffa76a441641b4b1962f5b57170bba7030485b74f377078ccda8b6f9','4b48d1eef1138ef202612c7e014e70822c29dd44dc7e2ddb87ca790158209f06');
INSERT INTO blocks VALUES(310234,'662e70a85ddc71d3feae92864315e63c2e1be0db715bb5d8432c21a0c14a63cd',310234000,NULL,NULL,'0ac6803ab61e14bb08fd8051424565086ab11b4d33faef077f5a0732eec6f766','08e241646a783a9e18d827432a894583a07807df74f5d600263c596fac723c7b','ac75082e99d82270a1cdd7fdeb392632a2a73315fbf733387e43880ec8c4c6e7');
INSERT INTO blocks VALUES(310235,'66915fa9ef2878c38eaf21c50df95d87669f63b40da7bdf30e3c72c6b1fba38e',310235000,NULL,NULL,'5f7de1c7fe45858dcc844604a77051d55de3b9dbb5f5d9910ead8bd0f3af48d8','b990d6f05c1278784e9fafe494076eb586edfe9d1ab2e5b4b55b20cd666008d7','eebaa09225e48780d4bde2061931b957e25d2c2d57363b713b85d7352a48a32c');
INSERT INTO blocks VALUES(310236,'d47fadd733c145ad1a3f4b00e03016697ad6e83b15bd6a781589a3a574de23e4',310236000,NULL,NULL,'c0437ca60921bb73516c31a74f78d2fb48d2c628b629c8f55c8fbb0060718d76','500f5b7c186a6ce208fddc6254be0ee23d984076522340508b91549a7044faf9','f0fd4e90d27089939a9b18ed6d2feac18bd60134b3f3d719f1fceb8fc3005cf5');
INSERT INTO blocks VALUES(310237,'2561400b16b93cfbb1eaba0f10dfaa1b06d70d9a4d560639d1bcc7759e012095',310237000,NULL,NULL,'4340ab34a083b38dbca477b6cc2479e6d70ffd6d6b9b75772068674297abadff','89b41b7f353c3c0fa4f0fb3688e26999f0524c840ff3f4c8c56357e94164468a','209e86fc2b75aab0bd40e379789952af2a8742106adf88e8f75cc341c25809f1');
INSERT INTO blocks VALUES(310238,'43420903497d2735dc3077f4d4a2227c29e6fc2fa1c8fd5d55e7ba88782d3d55',310238000,NULL,NULL,'6a76891c10ff0f9416ae1a024b985d621154918bd8ab545980b57fd2d18c4af7','83e241eb37d1944ee7c3ab834e6e2ab869ca9071b4e92fdb53429d63b60e57f0','871574096955d3aa05a3eb4e43c43ab345caaf0b1a551190b0d0828fe23e591c');
INSERT INTO blocks VALUES(310239,'065efefe89eadd92ef1d12b092fd891690da79eec79f96b969fbaa9166cd6ef1',310239000,NULL,NULL,'1128bb89562fc3b112da425a3dee67adaf741a8021ee378bdfeb44af3b1b1fac','299b307f4ee4aa77f3426a849f9b13a979338334a9d05deb1c4ae6fa850ad162','153f8b6f6e004cdbb0619c64000222188cd534c4da7554e06a657184888e4e91');
INSERT INTO blocks VALUES(310240,'50aac88bb1fa76530134b6826a6cc0d056b0f4c784f86744aae3cfc487eeeb26',310240000,NULL,NULL,'be05624b84b2e76794f065f36b4e98d6c6c120f1d8a5db91957bbe7008ce3240','b4ff46e3241c842548bdf79e3f93d6da4f2fe75121782991f80d85eebff555dd','81ba23fb8a04a63d217379d85c7ea90672d49a0195b7ccc178a3652eb3f4eec7');
INSERT INTO blocks VALUES(310241,'792d50a3f8c22ddafe63fa3ba9a0a39dd0e358ba4e2ebcd853ca12941e85bee4',310241000,NULL,NULL,'5abfdfb1aa42fb80ca4538062d152d965b6a7a56bd1e170a7a109409a4606b7a','a529c97092936f518725ac97d8a9e540a8af2a7e95d87cc3b3368d2c02fdd3c3','b717142be677d3e507b748ddf515732e97092180c9ce7ebab0e4d999f9eb2e49');
INSERT INTO blocks VALUES(310242,'85dda4f2d80069b72728c9e6af187e79f486254666604137533cbfe216c5ea93',310242000,NULL,NULL,'5f354f767df3256aa6a23544a7164160b9fabe481c85d1891f5250b3026dd7b8','944b30e4a44dd7b388af15e1ffa91d8ffa868952a24daf3c6f18199902bba3b7','4f68f360ab289c38f9a4b59beeb8f2e11d943885a0d584d550d9e6d4e635568d');
INSERT INTO blocks VALUES(310243,'a1f51c9370b0c1171b5be282b5b4892000d8e932d5d41963e28e5d55436ba1bd',310243000,NULL,NULL,'ea3acc31b3c298237fa11ca4400c65ee46732c96e0b7fac5a183dd49d938e730','d9c5c3a72b52724ce850c291a0e218c4026d454173c2961c316c681b87418232','9dd5490e2c51479f0940ef13270d99b0dbe19c44de31d4c91f77e529dd62d315');
INSERT INTO blocks VALUES(310244,'46e98809a8af5158ede4dfaa5949f5be35578712d59a9f4f1de995a6342c58df',310244000,NULL,NULL,'07ad792741a48d5a7b657e6c4dc83e3534c79bd1e7da7044139516124adc8f80','d525a5eb01479d697439dc75b7781bcb84b9abec0c5a552e65e76c0729bfe724','636d8ae99426f79816da31296594788f54021ee8d5094eefd351ed85ccfe8d5d');
INSERT INTO blocks VALUES(310245,'59f634832088aced78462dd164efd7081148062a63fd5b669af422f4fb55b7ae',310245000,NULL,NULL,'d36a618af8e92da03b373ab0137ded666db6cef906a6b2c0cb8c71057a1a5903','541f6af498bc3049b6f1a78dab4918c243e60badb57287d8b4c699e10ee02e80','36ed160b7dc1067d36a4e55a9cb594ddcfb4595818a786d2ee9365aecf6e01e3');
INSERT INTO blocks VALUES(310246,'6f3d690448b1bd04aaf01cd2a8e7016d0618a61088f2b226b442360d02b2e4cd',310246000,NULL,NULL,'a34e154571ee585a839053a851a007d6d433d3efd2b3e923a9c4ec4bb0dc9d98','8e0c2e59342079b813902eb97ed83a18424a5aef5bf1a0f0a3323ec16d20c7b9','2fd9d6b579b83d7a2f07d3872a51624d5115503e689d3c631114b5657f96abdb');
INSERT INTO blocks VALUES(310247,'fce808e867645071dc8c198bc9a3757536948b972292f743b1e14d2d8283ed66',310247000,NULL,NULL,'ee94fcb9210718095ccdf63f30ab081f45dff765a9ca4f5c86b1b0d98973ef90','671d4da503c7e0eea10b14ea1723edb7038a06a5fd2dc757b6700f3dc5261ca7','35f1452a3aa27141815cf677bc04f1e209fd344aec43fd20774cebfda2069e3b');
INSERT INTO blocks VALUES(310248,'26c05bbcfef8bcd00d0967e804903d340c337b9d9f3a3e3e5a9773363c3e9275',310248000,NULL,NULL,'029884a5273466fa45cdfbd91ae3aaca50af0771d22f6b55af6367348c2802e2','3760ff4aac40f27b8bcff8b97a35528d32c2f233a7aab5970c2933715abe997d','d4ddb653e81f5bebd3e91ebfcff363872f1db98598e0feea0cc0fb70a8d5b4e9');
INSERT INTO blocks VALUES(310249,'93f5a32167b07030d75400af321ca5009a2cf9fce0e97ea763b92593b8133617',310249000,NULL,NULL,'dc10674812c5249c693ab7b148d048439a0d77266014f3afc1810a6260838f02','5d5cecdde941b651dc38c8a4d13569b89e7be231937eba9dc234b872b8ad2d28','328c2dc203d3950a44764a60b6fab33d4ed4bf15f2e7437d8f2a499a49877fe3');
INSERT INTO blocks VALUES(310250,'4364d780ef6a5e11c1bf2e36374e848dbbd8d041cde763f9a2f3b85f5bb017a2',310250000,NULL,NULL,'a0fd49b46ff0000e83d4c56281dfe2be1bbfc924c75969726754b05bf7107641','81c10f4d6526cbc84325d75359fecf40498ab8f5926ae94162cc831d754d3e9b','2db654a11248d1266e4ad594b90262a5e6159df55dd1f8ad211fd8013053c0ac');
INSERT INTO blocks VALUES(310251,'63a3897d988330d59b8876ff13aa9eac968de3807f1800b343bd246571f0dca7',310251000,NULL,NULL,'bdef6a6203d28d314dc087e539a9cdad19d123b605824f0a66f13bf5f72de9b8','b40d9a7675154043fe1265452cc55ea0d5458d5693af61534efdda85064b15af','6c56adfbeb82b1dceb9bd08b300f498b0de733c7edd3728329c4db925817e199');
INSERT INTO blocks VALUES(310252,'768d65dfb67d6b976279cbfcf5927bb082fad08037bc0c72127fab0ebab7bc43',310252000,NULL,NULL,'8da11bec0d58b196ddb073d3aba0def98f01f83da654765fcae21cae6046214e','0452530f6f6cff63f3780c0a542f07a158b28b5f184d5525b1a4671860e0ce9f','ab2bdeb2c9163658a7c8dbd627959228fade34a8d924e93f831c25908f920c72');
INSERT INTO blocks VALUES(310253,'bc167428ff6b39acf39fa56f5ca83db24493d8dd2ada59b02b45f59a176dbe9e',310253000,NULL,NULL,'2efa2c5781899d213741e795ca62fbee9d3ddf53792ce002db7484adc66bfbd4','f89bc1b940222dcb0507c7b70396a5e33fd39647ff363ce1686374a05be83c08','81d719fbc03db2b447430b2fcd5c43953578a4b4bd899df372c5780eda781be8');
INSERT INTO blocks VALUES(310254,'ebda5a4932d24f6cf250ffbb9232913ae47af84d0f0317c12ae6506c05db26e0',310254000,NULL,NULL,'d062ec468e76421d3769a99eb3c8b2cbf4bf393d109ba13b3bce128613fff547','b8c9232e428003e639975635dac1a4afe06dfc59477fa732d8f769df04ad8f40','e579bcf76dcdd751f44c8726a3ec96a37e8ed381b48e2c74be09c4779ac19bde');
INSERT INTO blocks VALUES(310255,'cf36803c1789a98e8524f7bcaff084101d4bc98593ef3c9b9ad1a75d2961f8f4',310255000,NULL,NULL,'5c531dc8a7461e9e7a2ead654509d76c9be3427b1d2b75c0ac7ae0e03126c49a','f31d8a5c8bc4721daa2470cc9a9b72456344374ac4c9c2c1ae2094624c115808','f7c396b4115ed8948e54f7e4163e4fa1c5d4e7f380abc3a5ea996a7113c8aff8');
INSERT INTO blocks VALUES(310256,'d0b4cf4e77cbbaee784767f3c75675ab1bf50e733db73fa337aa20edefdd5619',310256000,NULL,NULL,'8da9f0162e15e33e14e5e1e22c2fd847055a65b99eec519dd069a83bb9006b51','382f4cc9655c9dfef1ca843dfc5f4c3337334d7a11c460fea21dc716e3e1fcda','574ca592fa6c36e37e71418824fa4e4c756f682df60d20a6055f91a228ed896a');
INSERT INTO blocks VALUES(310257,'0f42e304acaa582130b496647aa41dcb6b76b5700f7c43dd74b8275c35565f34',310257000,NULL,NULL,'0cf6657db5f3145587a466c05f237289b639668d844abfd8d46430c090b54913','6961a1c27a69e9742b451f9030f7556abedb4872c85531d61051b3353264b03c','69fc785aac8b3d6973e1238754e051fd86ee7ef212a8f02f9ed7f3813431c11d');
INSERT INTO blocks VALUES(310258,'3a0156dd7512738a0a7adba8eeac1815fac224f49312f75b19a36afb744c579f',310258000,NULL,NULL,'e340defe4bd84e788f9c5b083849e6aa1d5c7f33123ebe62d7abe04b8a9e312e','6694aa6cceaab675a8314cec01e384cc5b8b565124ed9fff21e0c821ec2873aa','dcf4bd7f33ca2cf6625534fcce3ae4fa375d11c378081c0100c2753bc6485848');
INSERT INTO blocks VALUES(310259,'e5ed3cdaaf637dd7aa2a7db134253afe716ffdf153e05672df3159b71f8538a9',310259000,NULL,NULL,'03ca0cbce5a5b50988c19c0d4e754240f50821695dca767d1169f8c7f5c1fdcc','9434d01174ca11c44755f41313155a3c081795dca93d081148eab228a81b10a8','239ef6d02a56f4bb731d518facbfa627bc6c6e037de48bcad52d4c43d3955178');
INSERT INTO blocks VALUES(310260,'8717ddcc837032ad1dc0bb148ddc0f6a561ed0d483b81abb0c493c5c82ec33cd',310260000,NULL,NULL,'83a3b43e01f4f25ba05b527415baa3e8b8adba319628c245988136bd8fcdfcfe','a0c7cba49596ddd72c6eb73bfcbe12e5373bdf243b5579e2f82ae583bdecb21e','a9c69fc55db8e095f65b71c901b41cde6407956b66e1931ca9905494817dd515');
INSERT INTO blocks VALUES(310261,'a2a9d8c28ea41df606e81bf99cddb84b593bf5ed1e68743d38d63a7b49a50232',310261000,NULL,NULL,'e61c12005d60870fee947fff469631ee540b1a0d6b8aa67614cfacc0a9f65ec0','c8d09f47831b239c605a01a369f744500b6b307c4bea2a8fb88622a7a5cd28f5','df0bb76e3817edac05432b2a2a051156721c75988bc9eb253504794ab60f0d22');
INSERT INTO blocks VALUES(310262,'e8ebcee80fbf5afb735db18419a68d61a5ffdde1b3f189e51967155c559ee4ce',310262000,NULL,NULL,'c21ac4906d435af5b9ef5576da6bce454f65ef16099b7ee03219a4ae1851bb91','677c31b60bcafd5ba6b8074e6748cb6c06f73f3ee28c772d31383ed66cc33a38','2e940132584bd01cdeafa14c3bde62f6c534b4074266fe53198eb0d602210767');
INSERT INTO blocks VALUES(310263,'f5a2d8d77ac9aac8f0c9218eecbb814e4dd0032ec764f15c11407072e037b3c2',310263000,NULL,NULL,'676f6c532ff23839fef228a9fac7719e77a3c20efdc17f3cb2d13035c78820e8','b0be6aad34a21917935fe500b3fb464577eadc1eda164479aeffa02e436c974a','d33e8da30f6e6504e385c94679bf09a1452165a7e9154bc8a38039531b19e9ee');
INSERT INTO blocks VALUES(310264,'ae968fb818cd631d3e3774d176c24ae6a035de4510b133f0a0dd135dc0ae7416',310264000,NULL,NULL,'258854505b1d3067bf360f3d0dcb369ed7a90fec8744578d3dde51a79db72c25','4fdf4e94a9fe6b8e2192b8c7a4a36edf66660740c66f5b9a35b3dd96d2e39806','a47ce02b96495ebfacb51a2f049a738785aa19a1f782c8ec52f77b7e7b8f8100');
INSERT INTO blocks VALUES(310265,'41b50a1dfd10119afd4f288c89aad1257b22471a7d2177facb328157ed6346a1',310265000,NULL,NULL,'72ab32c420a7dcac0e7c36c4d9ca81e237955b4d8bc57c87078ba292923ce98d','a9dda90317afda2ea620cbe4819de3f9bff210569112c3b6cc8996672165585d','4246b35b43466b583d21987702842f98f5de9bf1c14e7cf7e010d041a85b8f4b');
INSERT INTO blocks VALUES(310266,'1c7c8fa2dc51e8f3cecd776435e68c10d0da238032ebba29cbd4e18b6c299431',310266000,NULL,NULL,'b81386d19aac285fee4e39a818cb0442e378372f7d55f92e6028b37f974e4a61','1a509e785b6d0dafeb6cfee2326e9d16b4fe30f9a170120864db6a353a2c8f65','e234c23bdbd32260dd4fa99315d0d6bcef7a92e582567c487253a81dfe3dc796');
INSERT INTO blocks VALUES(310267,'c0aa0f7d4b7bb6842bf9f86f1ff7f028831ee7e7e2d7e495cc85623e5ad39199',310267000,NULL,NULL,'ea8fef9e82e451d9650777b051f19fe5e34b8976f1bcc1880b6eebe5feda34d5','de674878ebaee83afd74963622284c8bf2965a7f1247eece62fbd4a7a2d0843b','08dc74d0fa3f4a2203ae6fe6855476ac370ce8a4aee00df0653d243d99904ee3');
INSERT INTO blocks VALUES(310268,'b476840cc1ce090f6cf61d31a01807864e0a18dc117d60793d34df4f748189af',310268000,NULL,NULL,'1545d381812f0f0caa827a237f145838276fe058b05af4808615738ca9910bf1','ab95e245f427175bc61d396bb76468d1e8f827856b96967df5478e932c5bffd5','f53a2fb5af4f9d5656d1863e03455d1b49b33827fa25b41ad6bac074a623b9ab');
INSERT INTO blocks VALUES(310269,'37460a2ed5ecbad3303fd73e0d9a0b7ba1ab91b552a022d5f300b4da1b14e21e',310269000,NULL,NULL,'fd9cf61ac6e1fba409e4220a141ed6c89c18c893c7a752af53d5f7608bc04a67','bb1e8a2ec818c46170ec24cc22803caf3b49bd18b81a88327b31604f2ff2bf5b','f3a4b5f6a16da684188971f02a8d2623edf6f5885afc5f29865d3e910216a8f2');
INSERT INTO blocks VALUES(310270,'a534f448972c42450ad7b7a7b91a084cf1e9ad08863107ef5abc2b2b4997395d',310270000,NULL,NULL,'1d34c8c0dfdb4733a7b589647abb0e6a08f8de93a5c86fbab786f6d9d1500785','a968d196bc72bee20d195249c167f27d9baa932f2e87671b5308c7df8ede4ac1','9273fa9e02b0986b4069c686ab6434b9665c7fb3750a50f1b26c62a8bacc0e75');
INSERT INTO blocks VALUES(310271,'67e6efb2226a2489d4c1d7fd5dd4c38531aca8e3d687062d2274aa5348363b0b',310271000,NULL,NULL,'cf38baabc6e8a082eba1bd8ca2f72af5eb01cb76bd3c9eb101b27080a3a70d17','f85800535d634e2491c0fcb2f1d28d9d54b87755c08c7088d9bd3b1e99bb6ebd','80b5c6ecedc56b5601f666d80595cd2d167da78bcc0790a3f511486d0175f0e4');
INSERT INTO blocks VALUES(310272,'6015ede3e28e642cbcf60bc8d397d066316935adbce5d27673ea95e8c7b78eea',310272000,NULL,NULL,'2b2763fa5ab2962582c303062da8b8da7280274e615b3e37f93a32e44793ccc8','2d251d9c21523d31487c6bb03806a3c6eacbbd87570d129af0c4eff884c1dfc7','dcfac57087b085286cd70a7d563c4c91b2ccfecf9eecc79c2f98a7e7337c8397');
INSERT INTO blocks VALUES(310273,'625dad04c47f3f1d7f0794fe98d80122c7621284d0c3cf4a110a2e4f2153c96a',310273000,NULL,NULL,'ff9df73d4f92b7557c36f20d8f622923dda225a1ae2871e60f16ee2dfdf5b9d8','b528024370a366e0c3c17c81a6afd48ed6f8cbc61ef2744b568f82ef97477200','2e0c63d6dbb2467866e4eca7727884c877a13bbe5455d9adca7b63d8263f9a90');
INSERT INTO blocks VALUES(310274,'925266253df52bed8dc44148f22bbd85648840f83baee19a9c1ab0a4ce8003b6',310274000,NULL,NULL,'ece29ec2cd160d7634009f41cc2d0f13330d53ec6971c019d69dfa4367f86646','a6d1edea52f6adb539fd192f3181851205c00a8656e455b5535251f958c275f4','be0d3a4db36903b026917804b2bd999e42c1e215dae076edc05e4e7ceac253f7');
INSERT INTO blocks VALUES(310275,'85adc228e31fb99c910e291e36e3c6eafdfd7dcaebf5609a6e017269a6c705c9',310275000,NULL,NULL,'23738d6d8dbf8b44b481f6c0eade991987c84e8025fe1f484c7acd3ead7f4163','78fff0b20c5587e70d21b75cf665e989ec0a8d5366f05f28829540de20a63563','67ff25f210b8dd004f7ed4453a30e59eb5cb286dd7d43ef4cec6608accc183b6');
INSERT INTO blocks VALUES(310276,'ba172f268e6d1a966075623814c8403796b4eab22ef9885345c7b59ab973cc77',310276000,NULL,NULL,'a241e1cb19bfbebb3bbb09c6471760b8379ddc73a67d69b4d84fd1d21dfb7034','ae4dae5678a9eb2dad1fc170212b2794f0d780614ffc2f464f8e2071d2fd678d','c69332d8bd73073291a273076b93592abf1f5f2c53514f51934c35ea9accf191');
INSERT INTO blocks VALUES(310277,'c74bd3d505a05204eb020119b72a291a2684f5a849682632e4f24b73e9524f93',310277000,NULL,NULL,'0efa57fd462031a87831832a789ed7751aac5f6c19a23767555b3f7145d87532','3627782e01a5b98f602259395b122945104b3ebae075bbbbf61ea316a197e066','b96d96d7b0544a0d6a26a4808610a5bf5ba2b37cb98527b0d93b11fa504ef9ff');
INSERT INTO blocks VALUES(310278,'7945512bca68961325e5e1054df4d02ee87a0bc60ac4e1306be3d95479bada05',310278000,NULL,NULL,'0045189a4da126b22e91e4bc2a7ac37dc90ec0869b7fcbc927919fca4cce5259','b2062f330e6762adb9ef0d7b6fbb8ff273c07cb168a240c637f8e30d6465bbd9','eb471bfbc0288d39b7563c1bb2c6b3b1679aad46bc75bc7a3ac9789492e5b872');
INSERT INTO blocks VALUES(310279,'1a9417f9adc7551b82a8c9e1e79c0639476ed9329e0233e7f0d6499618d04b4f',310279000,NULL,NULL,'442b7d4dee025b81c298ca0f6a5b9dbdf17ed0087fc36eab7f0671d5a19c9a2c','a92bb3cb09b18fbaad350ab86c1bd177348ee26e17ce974506aa2095bf585f11','b94b2eb139d01a1545d9e2f439b9868ebcfbdfedb1248e300b28d7d615c80d61');
INSERT INTO blocks VALUES(310280,'bf2195835108e32903e4b57c8dd7e25b4d15dd96b4b000d3dbb62f609f800142',310280000,NULL,NULL,'38d7f98ae9cfb8e3938032dc33899e2e3e5a88e9037571cdddf8ed4709fc8225','b01f7b130d6259628a37ccf06e96877bd765f9630fe24eceeec8babe9cfdd404','f06d199a2c5c903b27a4a9ebb10cb5d6f32e7bbf6ce12b639c3499093c9aa64a');
INSERT INTO blocks VALUES(310281,'4499b9f7e17fc1ecc7dc54c0c77e57f3dc2c9ea55593361acbea0e456be8830f',310281000,NULL,NULL,'51237cee3b85f1636e336259b115fad87acc830c71e13ca79e344efb7c308ecc','7ed1e8e0f98d1928db424e3c70daa2bfec726e0050907043ef948ddcce2dbae0','a04d8bd1583c93515392b907e29886c61e8844be04254d8b2802299cb7264d82');
INSERT INTO blocks VALUES(310282,'51a29336aa32e5b121b40d4eba0beb0fd337c9f622dacb50372990e5f5134e6f',310282000,NULL,NULL,'73adccef91b5c738e8810d4781a38edf98d2aa0a8cb619d575e9bdeda979f1fb','d0db0c9763ce086889ceb5dfb88740441118eb615fdd293b95f663fb687bd15d','89da82f35abf19c241e638398c17fdb9bf7171f4c19c816229ed31ca9feaf1db');
INSERT INTO blocks VALUES(310283,'df8565428e67e93a62147b440477386758da778364deb9fd0c81496e0321cf49',310283000,NULL,NULL,'5853e60a1b79d4f154cc1f3dc8b0a4d6130ac07784bac16f257f92b9ef294144','aed0078d64860940972e5714150848649c58fbc61585739ac5562ad3f89dfca9','08bd7c8806463041292b8ef03823fdda5cc91b6547ed043d895f348626068b08');
INSERT INTO blocks VALUES(310284,'f9d05d83d3fa7bb3f3c79b8c554301d20f12fbb953f82616ac4aad6e6cc0abe7',310284000,NULL,NULL,'ce33194cb67aa0a5facd788cc24706ef249bcecc95a9965f91065146b33e464b','33eebecec55c216d853f9248afb69bc6e70619a559dd2017e85d064ba1326eb4','5ea4816db35fba896cdd530a34959a7a4a26da2de04d8da4f1386e79a339356f');
INSERT INTO blocks VALUES(310285,'8cef48dbc69cd0a07a5acd4f4190aa199ebce996c47e24ecc44f17de5e3c285a',310285000,NULL,NULL,'3af35e85e98aebe1a9c778570c730bf80e085a08ca707c1a5d44b50f2579e71c','11e628433e5adc3d227312947dd8e8088d8d4d9127abe6fa35393d44b42cd309','d5ab454de6c8d1a5ed5ebc3b05d120c519ac119bf3bbc582a7f3b50110ca8b5e');
INSERT INTO blocks VALUES(310286,'d4e01fb028cc6f37497f2231ebf6c00125b12e5353e65bdbf5b2ce40691d47d0',310286000,NULL,NULL,'4b09b627adda46ee7cf7116102a330ba2aa1ce714b2fa133f7952af34a52ede9','47aa5c9927cc0b25d06f35dd67e4dcf0d55e2812f9ed1862dd9aa55b9890c54f','39fa1cfc5689c871da27542bcfd629d57eec1581fdc54df6bccd74fd278553e4');
INSERT INTO blocks VALUES(310287,'a78514aa15a5096e4d4af3755e090390727cfa628168f1d35e8ac1d179fb51f4',310287000,NULL,NULL,'67786e4ffab15cb78c7bb44ef160d1e5d99b599eecb5ff4f906a6599d744d410','67a96eba27ab1066e57770fde0f77a7da3f9c1a80620e5dad5f111923b284ce0','a4f16c95009c0b03c2accae8e049e0a2e4892a16d0214f01b354783f093f7200');
INSERT INTO blocks VALUES(310288,'2a5c5b3406a944a9ae2615f97064de9af5da07b0258d58c1d6949e95501249e7',310288000,NULL,NULL,'600716d2696160b3ba290636180f2afa24bf8d24435022b4539a4cc965c18dfc','800534bb5717bb82118814e75671d85c069900be76001d12c0d694761fbd8dc7','af0f49c70307b8d6a9f75e5cc6af036981bcabb403e86b77cad35a4b7fae2346');
INSERT INTO blocks VALUES(310289,'dda3dc28762969f5b068768d52ddf73f04674ffeddb1cc4f6a684961ecca8f75',310289000,NULL,NULL,'cd6d4b17759152edbf25fd72dce9b9126ea31a2bb1a5435636801e0ee4be1158','838de979219e7a5ce3b80f2ad924f3273101f1daf391ccb05f90df2ee7bf0470','a8d6292dc1410a443e1a48285c3fc579def5d83a3924d10c6ea5a3447c2692b5');
INSERT INTO blocks VALUES(310290,'fe962fe98ce9f3ee1ed1e71dbffce93735d8004e7a9b95804fb456f18501a370',310290000,NULL,NULL,'04a9135f416dc041d3c1c0216a84fd780d133213c3369691fbf5e8848af9d14f','863e66fa35a9222ccf3e960f4d3851874a11c9ed37bd1bb960617dbdf74ea8e6','e204f077197554c5d108ce853131293cc1fc479c2317e46ea8d6e8e4cc02cbe2');
INSERT INTO blocks VALUES(310291,'1eeb72097fd0bce4c2377160926b25bf8166dfd6e99402570bf506e153e25aa2',310291000,NULL,NULL,'50f556e01b9e8c135b20187bf863839e651a0d0bf4cfd1008b446531776f7917','a575cbc49d31e64b7e0841316af95ec44103856bee8fdc35efb43c06230ceeb4','7c0d06026cc03167c34dce1e8c616980f3f32b67f87238c90b723ff6fa7e4e0c');
INSERT INTO blocks VALUES(310292,'9c87d12effe7e07dcaf3f71074c0a4f9f8a23c2ed49bf2634dc83e286ba3131d',310292000,NULL,NULL,'9d4bf4b1c5dba1132a9cbfd78c1d94cbaf15d7648da80c8bc1a8dce12a79eac0','a6e16bdde3ca753f34b1a70eb0a8316e8a605f33e74f1a7e3f3a7ea1342a7e9d','08dc01c8c1b8dab7c0f6ab88b290dc5226232879aae6e310fffc5e5177aa2ed1');
INSERT INTO blocks VALUES(310293,'bc18127444c7aebf0cdc5d9d30a3108b25dd3f29bf28d904176c986fa5433712',310293000,NULL,NULL,'a51a3f9af39175cc9d142eff67811307ad8f51cdd8161aaf0d98af9e2be28efa','efc0e769129e42cfc6682b13a21b675abae1c3fc969b78102bf0d3436f190fa1','525e64fe47957cddf6ebc579a3a14e6b98bb8f22647b0a312c674da29e4acdc3');
INSERT INTO blocks VALUES(310294,'4d6ee08b06c8a11b88877b941282dc679e83712880591213fb51c2bf1838cd4d',310294000,NULL,NULL,'3e9858caa8e835295aa7e78505ea34ce0726e3f5f6cf9fbc6dc4393a28724a25','be4fcb18e1d24f0768cc5c24b6c13e9b087fca45ab3af31d96a3f10e5bff4231','348c42aaa0200a7c3d6d8beb6f23fb52095c2eee07bf05dafde96d76a944a3f2');
INSERT INTO blocks VALUES(310295,'66b8b169b98858de4ceefcb4cbf3a89383e72180a86aeb2694d4f3467a654a53',310295000,NULL,NULL,'bf48715799c46d629641ba5b72405f6e6cf0500886da94fcc6fddd306a86b02a','52f0a6f76ce4ffed4a2cff4cbfa12ba639746a15e0ef942a8a98884ce6d6f8bf','6263e67741e9b595200ffb8fa9c70a21bb8017e9626c0c47ae59eb1b473c847e');
INSERT INTO blocks VALUES(310296,'75ceb8b7377c650147612384601cf512e27db7b70503d816b392b941531b5916',310296000,NULL,NULL,'08e2361ae4b98387ee43fd7230ea8b296dee677b337f0e211527e3cf29a64e9b','66c5645364519ca0430db894d2eaa6ac82f7d8914c3cb4a5672fdf3bd6cac8b9','bb1e05c0e10d9f5580eba49480d1772e4234aa55471bd94cf877414ba6e0012f');
INSERT INTO blocks VALUES(310297,'d8ccb0c27b1ee885d882ab6314a294b2fb13068b877e35539a51caa46171b650',310297000,NULL,NULL,'cfefc3138983a33686dd1fc37f06fa1d7e01d9b218f7242cdd59005633c0ded8','173f741e5e1806fce3f4f0b85299962c74408d3262b9752a543fd79ab310adb1','8a5bf3d3e2b032a601bfff53026d0fa4bde5f61a4e90ebef3913eea3fd3a7bf7');
INSERT INTO blocks VALUES(310298,'8ca08f7c45e9de5dfc053183c3ee5fadfb1a85c9e5ca2570e2480ef05175547a',310298000,NULL,NULL,'25254257d6f6724161b2b73f94d28d3fd40594b4846699b8a2d5f45d205b1fec','ecda196cf8ce0219589e5e82d248b83d8bdecdeb5a0da3b02aa6cc7b66d2c09a','657d91f3036889426df9df8247ee90df6c5fe36a3d8c6b1a9efed54aaee0dba1');
INSERT INTO blocks VALUES(310299,'a1cdac6a49a5b71bf5802df800a97310bbf964d53e6464563e5490a0b6fef5e9',310299000,NULL,NULL,'756acb1055ec75df8fa70f80e23d75f2b47e75035bfd68802e68308785a2ee14','bd31f490af463106fa1364081ff638616bd245b11878981928d0d0589e7b88c0','663d47a53efe6a593ae2f06f3ad6444efa180b5e59e82bdbf35d672af31cac6a');
INSERT INTO blocks VALUES(310300,'395b0b4d289c02416af743d28fb7516486dea87844309ebef2663dc21b76dcb2',310300000,NULL,NULL,'e30027ca81176dc1e79a0ab3a5afbb839a3338dbe9ea6057aebcd383ed884c1d','cde56e64e9ea960c6fd1560ff3033154be1f694daad3263297ee72d3f3a6182c','82164a2d9e837164df185848a67ff7ddd947d2eff43ba297450c62e5b4754b9b');
INSERT INTO blocks VALUES(310301,'52f13163068f40428b55ccb8496653d0e63e3217ce1dbea8deda8407b7810e8a',310301000,NULL,NULL,'4c2bcffc796af76a2607a978289942241e63a6387e0a2ae8fc3d02c6b5519fb0','6f3cb6e3a414bb29aec0d4aaf55ac706261b539befcb649259500a0c826ca7fd','b66920cfbb34ea08e06bb6fd594b7156a0a2d4021f8a43619397e81da6cd5267');
INSERT INTO blocks VALUES(310302,'ca03ebc1453dbb1b52c8cc1bc6b343d76ef4c1eaac321a0837c6028384b8d5aa',310302000,NULL,NULL,'a39fdd7f84d2f6e29b613a8a724bc0902d9abd2d6b4d2f46c3b0512928d69b3f','54bb8b0b1f24cd8d9d562c1fd9158f4ef6c4c6ced0974c4e4e461aa641842148','855568f20d2fdfac725046c1f422235a8d4805ae0fae8edd1e13861f846c87a4');
INSERT INTO blocks VALUES(310303,'d4e6600c553f0f1e3c3af36dd9573352a25033920d7b1e9912e7daae3058dcca',310303000,NULL,NULL,'23f307ef560a02210f4aae5fe605c6d8af9317ab17f1e1ef0944038a3515da49','d615d50f2c7f25b35a4826c629ac51383c1da2f1912a45da4b42eb3715a537ef','c308d0d1b55b151d0da4bcc3cf938d338cc5c74ba2f1b3bbcb13e193b8450e07');
INSERT INTO blocks VALUES(310304,'b698b0c6cb64ca397b3616ce0c4297ca94b20a5332dcc2e2b85d43f5b69a4f1c',310304000,NULL,NULL,'6baa2ac646d3725fa01111959753844d22181cbbd1801cb12c4208be3709a3a3','d747a9dbe53c2c31dee78560f7b6db3e2bf360693484855eca7f12c59122cec7','be92312e1b00b10735032583aa8c56f8beae12efb9ed242584e0e7eafaa1b310');
INSERT INTO blocks VALUES(310305,'cfba0521675f1e08aef4ecdbc2848fe031e47f8b41014bcd4b5934c1aa483c5b',310305000,NULL,NULL,'c366fd009860a090c632131eae9380820e512009bbbaa6f7bc5529afab7a88c1','5b38d6412ef33f7b9f98375c40abf96badbbe0644ef426381c85865d6367405b','66540145910f3127b31d280a4159b538d64596ac7471b4ec6b9219789e6cce67');
INSERT INTO blocks VALUES(310306,'a88a07c577a6f2f137f686036411a866cae27ff8af4e1dfb8290606780ec722a',310306000,NULL,NULL,'fd12969b828d689063b4885a0356fc17e5207794d1f5b6a17bdeb8d584815a79','934e049637f985892b04a774d8f5ee4b162ed8d6857271fcc409442a4c983a85','aebf341ee2c6a1b12db7b9c509e56babf3325c4f769d74d89883580426887550');
INSERT INTO blocks VALUES(310307,'bc5ccf771903eb94e336daf54b134459e1f9dd4465dec9eaa66a8ee0e76d426c',310307000,NULL,NULL,'e168094d31f56d36e4c3863fe719e6064b08ccc6f3c2adb490b1359360026aee','acc586f0030fb226ff74b676070a3849747249675d7393b81f1796d9d2545b0f','671f39cc124450d9e279d6ff6ea17a35f617db33f33c62ed1eb75f467fb38afc');
INSERT INTO blocks VALUES(310308,'2291ffd9650760ff861660a70403252d078c677bb037a38e9d4a506b10ee2a30',310308000,NULL,NULL,'523b3bba7b02e2c4e588f21ed14b7b4f6630f887cc89f9361487b581d7e633b5','daad0db70e16b858883c60d1f73720c71baebf5cf19c6ce506ed27aae3fdfa7c','4ba9671af5a41bfb26df994694bee5184c3f1d9f6d42379627f252cc05898dbb');
INSERT INTO blocks VALUES(310309,'ca3ca8819aa3e5fc4238d80e5f06f74ca0c0980adbbf5e2be0076243e7731737',310309000,NULL,NULL,'effe1a68917014086da3bf8696f6c13f3cf2cb5cbd6c18b80ed622e476cff017','c2118312939d20050474da5d689b1f2985883844c157568c205637b104a2edb2','ba9f6c29f116db42cf194def1e00a50f9788f8d8b90fefb02a045cebee7a3448');
INSERT INTO blocks VALUES(310310,'07cd7252e3e172168e33a1265b396c3708ae43b761d02448add81e476b1bcb2c',310310000,NULL,NULL,'968fb8a7409531a27ffb52af484e7c1076f05b58f9a51bf9cf3d5a7d83b12002','a5095bd80deb5155844c03956699d359ffbf0c08664755c5e457fa31522bb318','705e88b850583e0eca3e27b913853e7f6a060181c2506228e6e8c842e9131c2f');
INSERT INTO blocks VALUES(310311,'2842937eabfdd890e3f233d11c030bed6144b884d3a9029cd2252126221caf36',310311000,NULL,NULL,'8c69639a757d0195594fa1da3f6b35a0e8c62b8df7f95db81e26d496b8c9dd72','87eb47dcc6b7d64443f422293617f7679f60ea7d41a0fc98e66e4717e9684b03','b05ba32a00997dc486c74821de2c3dada80cc1c02e8dd123f605a6cdc5ed1421');
INSERT INTO blocks VALUES(310312,'8168511cdfdc0018672bf22f3c6808af709430dd0757609abe10fcd0c3aabfd7',310312000,NULL,NULL,'8d839bac01b9aae5e554f691ae0ee42cee072f9367fcc2811d4b3f65640cfcad','b3d643a0bed134c40365d7e1fea8478e60f08158999d8147e5a8a0739ee6843d','e2ed5656b5c0cbe5e73187d921f4ac144b7dbc08780c6bdf858c6c04cf0d469c');
INSERT INTO blocks VALUES(310313,'7c1b734c019c4f3e27e8d5cbee28e64aa6c66bb041d2a450e03537e3fac8e7e5',310313000,NULL,NULL,'1377f4255bfd7ff6638734733a4b8faec97fd62aeb954e42b477c875ccc50b73','e8a3a4659973a0110b46795aa9e0e671160189d171944bc89d784e082fd4b8e4','bd101173b4269f59db3a27203c3d09becf14fc35deafed564d561eadae2273c1');
INSERT INTO blocks VALUES(310314,'1ce78314eee22e87ccae74ff129b1803115a953426a5b807f2c55fb10fb63dc8',310314000,NULL,NULL,'8ed80d44f0d6ad01a30611d94b91f735ef3a166cf0dfa7531492a3e4ac7c29f1','dd54a8bcced43bcac9b2e2783061a2d9c44c34c07383bdbae9aedb3a1ceab1fb','3d7032b193673415740f390c0bb473b53210edd25ccf96660c71ff64afa0b56e');
INSERT INTO blocks VALUES(310315,'bd356b1bce263f7933fb4b64cf8298d2f085ca1480975d6346a8f5dab0db72cb',310315000,NULL,NULL,'24b5905cf0d5349b7031870af9677916892e3292fa61455a75e84c1605a398ba','c41277b6ed0b6a5591b6d8a5dc6275831816a0b38d80e758c55da94fdff684d0','dcc9fce87a61f2faacc52eb89e13fefd32dd01ff691a33e216603c4ea9002301');
INSERT INTO blocks VALUES(310316,'ea9e5e747996c8d8741877afdcf296413126e2b45c693f3abdb602a5dae3fa44',310316000,NULL,NULL,'a191657253ca159739403f35417ef74637b053db49c7db62465fde4c54e69239','5a0493b0c046a9e8822f8d8066dbbee6ded3a90ccfb7c90d33978bab664f2c18','b093c25741e09fe09d267fdaa7790467991e48e71943bae439411b11b7f2f1b1');
INSERT INTO blocks VALUES(310317,'aa8a533edd243f1484917951e45f0b7681446747cebcc54d43c78eda68134d63',310317000,NULL,NULL,'bf6d880b9fa42b0e38523c00c92a898093afd068450be504a0a56bafd69ed647','6d3b4018de0f1387d9fa13c12f2b665b87bfc7e71c87c0944655d0ce60f1773f','8aff1439da0edacfa6e822369857240d96ca5393907d092b77aff275dff54ba2');
INSERT INTO blocks VALUES(310318,'c1be6c211fbad07a10b96ac7e6850a90c43ba2a38e05d53225d913cc2cf60b03',310318000,NULL,NULL,'6422eb2cab5937adb9ca2194c025d0dce63cd62e18d7ebd63220207957c942ee','6937ab007cdf074357a4fa32bebf0cfeb7256b33ac47f36c4f41d1a63adfc1da','981e01f961de4142910014ed4f17a861e8374e9ca39f9a7badadd7150d47fbda');
INSERT INTO blocks VALUES(310319,'f7fc6204a576c37295d0c65aac3d8202db94b6a4fa879fff63510d470dcefa71',310319000,NULL,NULL,'efb625496aa4365f5ac198a82833c880a60cd5f86d04689463216619cd7d96b8','a00dbae611e4cffbeacb837828e8182ed0665235f301b2afca6462ac8eb72c28','75ffc7b13f5e650ff1f0e36290caed2e9dbae591dc31673cb8fcc42f3185142a');
INSERT INTO blocks VALUES(310320,'fd34ebe6ba298ba423d860a62c566c05372521438150e8341c430116824e7e0b',310320000,NULL,NULL,'8c3938d7b3c0a822ebee67f1ecf21b1db6496e19471cf1f2cd00f30325d0c88a','cad4b4523ebcdff7909e8ff7c5eb8c80d85a6343b9b216f7edc8ed8925713545','9d22e23f30dcdce54e159cc45d94008782cd695161c98c9da044fbbaea317fe0');
INSERT INTO blocks VALUES(310321,'f74be89e9ceb0779f3c7f97c34fb97cd7c51942244cbc2018d17a3f423dd3ae5',310321000,NULL,NULL,'21e4c3a7afd02f183cbb69709fc6c006ab3d38fef3466de1a1870232d1c891bd','cead4ac9cf2e9e185ad7f30a37cbb39993b3ad0d819560976a5c478b378d0004','5dcba624b23e2ee72f5cd957ddf44ad930672d61e0cd6bf06cbf18551c76c1bc');
INSERT INTO blocks VALUES(310322,'ce0b1afb355e6fd897e74b556a9441f202e3f2b524d1d88bc54e18f860b57668',310322000,NULL,NULL,'01b3b28c4d8eb796827267c06e6362206884e44f40c3f72d9b5c9d1e6cdfb29a','514a0805bbf2371e3763b77a329e556890d04f8b010c675f919bf54cbf2949d0','a5c068d02bb1e2f1bb54c30202ca26bfa61587407baff8677ea5576fdbbadf78');
INSERT INTO blocks VALUES(310323,'df82040c0cbd905e7991a88786090b93606168a7248c8b099d6b9c166c7e80fd',310323000,NULL,NULL,'a362da58df0d31eeaa93a25c91c17bec62f9cad6ff0c31420584ce293ecafdbc','25b2688ce8a29a36b265f0f76719ab90592a0ac816047373d24bc107cc2af3a1','1ffff2eb509dfc2e17b70711afeb2e4d9988fb541103448b50f8682e90fbf3f4');
INSERT INTO blocks VALUES(310324,'367d0ac107cbc7f93857d79e6fa96d47b1c98f88b3fdda97c51f9163e2366826',310324000,NULL,NULL,'d1b353ac97e000471c66df8ee04d7b0c25f7eead2414e5648cd2ef334881bad6','dc2c2bd652d3ce8d29700b05e69758caf760242e4104a45bbadd006bd60e30a5','bc0672ffcd92f59ea9595d36f6a09ee1f3ed10e10324cab8986ad19f592dac7f');
INSERT INTO blocks VALUES(310325,'60d50997f57a876b2f9291e1ae19c776df95b2e46c14fe6574fb0e4ce8021eac',310325000,NULL,NULL,'7734300dc764c67fde935dd4432396de4a31cedc2901f3fc70bf1576797cf7b0','4b1b7793a3c72117d7c10aed5d638e2380ae41e180642fbf00cd70eb04fd9958','f34ef6fefa93d7717372cc019148ad75d2647e13fe6e3143ec2fafed7cfb1314');
INSERT INTO blocks VALUES(310326,'d6f210a1617e1a8eb819fc0e9ef06bd135e15ae65af407e7413f0901f5996573',310326000,NULL,NULL,'ebe859a722587fd456695c6a46af7f0bf54c03e940bdbb5424520a8c1fe70617','61edda4c07d31f85dd3d11394f6bb20e7c7c6b0e6f5251ad137d3dc5704ef19c','544b049f4dc4763c9694f9e6edb1d193015110d2ace117f149649f76ad81286a');
INSERT INTO blocks VALUES(310327,'9fa4076881b482d234c2085a93526b057ead3c73a6e73c1ed1cdee1a59af8adc',310327000,NULL,NULL,'8ced7a546ee2c746d4dc3f0ecd2fb4eaa62c65c4e98be74545d8de22c03526e6','2df6e25726f55175acdfda607966a09054ee379ce0f3a20572b5747d2ccd3714','ffc45518b4da2c8838761f3950f087033229b5d9370ed77933e70d52999b746b');
INSERT INTO blocks VALUES(310328,'c7ffd388714d8d0fc77e92d05145e6845c72e6bfd32aeb61845515eca2fa2daf',310328000,NULL,NULL,'bb5d3479e492f52a0b3b69d29852faefdff645f9b113eae82594f57e8aa40b5d','804dcf1a3afd459b853097f002002b9b3fbba7ebd198d640dbf3d33906557b90','1a93b9f3d92dfd1d113c8d894a8b8dedb2a54a1e7d3b087eb6c3a52d0fa1839c');
INSERT INTO blocks VALUES(310329,'67fb2e77f8d77924c877a58c1af13e1e16b9df425340ed30e9816a9553fd5a30',310329000,NULL,NULL,'4ad2c9d802db762537be19143ef5eca474cd9f749bbbc661cb95bcf1dcb0b02b','3d9c70e9de44cd225655cabe1ffd2559d23a822ecd988fec90267af067b3600e','28290675e84bbbd77885c0b29a7ffd45f8ee3d11dca5dc2f384a0e048ca7625c');
INSERT INTO blocks VALUES(310330,'b62c222ad5a41084eb4d779e36f635c922ff8fe275df41a9259f9a54b9adcc0c',310330000,NULL,NULL,'4a9a6b59d56f6b7cf867095d939f9bddbf779141177feda470df3759b7d48be3','aa7f0eb4a619027687eb666c55d7f9ed8a8242732d9b9a4b1e9ef03578c51f04','e59f7424f7c851dc5102e3c898641da13e2dae08cb66f45bce391517fb12d87d');
INSERT INTO blocks VALUES(310331,'52fb4d803a141f02b12a603244801e2e555a2dffb13a76c93f9ce13f9cf9b21e',310331000,NULL,NULL,'c676b9c31e0e3d74d005ad0a52a18ba34688b6002da5d269bcea0f789a4f8e91','7a46f9c856aa50e37cc24751982ccce135c5209b184efb0406aac9df228a8c49','b498c4b2d261dafc37c02bb049512a10dceee49aea4f5db6c378a7207ed0e678');
INSERT INTO blocks VALUES(310332,'201086b0aab856c8b9c7b57d40762e907746fea722dbed8efb518f4bfd0dfdf2',310332000,NULL,NULL,'cf0b702c03ecff4bda1254dd5e96ca580b69d5d02d1f233725fccbe1f5f32000','c9ce031c0377ef78cd639526cfaa0bf18185c3a54949207c0416d4b42b4e2ea3','185af3c449bb91056a7801e1fab8ece03275742f8b19146ac317453b654b3530');
INSERT INTO blocks VALUES(310333,'b7476114e72d4a38d0bebb0b388444619c6f1b62f97b598fed2e1ec7cd08ee82',310333000,NULL,NULL,'b40359eb197db65549946d93a39b2a732e0694d21b8d0138b9bfce4f5a87ae5b','1f689a825209fbdbd42b35d63469211397ce313b9f51385dbc8c3fae18b99476','2d1a4cc5497d1c9d8e589691d339a007578600531949c324ac64a0bf04586ab5');
INSERT INTO blocks VALUES(310334,'a39eb839c62b127287ea01dd087b2fc3ad59107ef012decae298e40c1dec52cd',310334000,NULL,NULL,'7cb471ec146f9ec1e4d1b93184ea641f7b8088807dedcd1c0be4ca5ba99e80e1','211fb97ed8f43562b19b9e0f49fb282068e7e5c3fe62674c8c24cb8c66a6a7ae','fc534803eb2dc737cfec6dc7e120d48ec0a00c985695325e588d31860800a925');
INSERT INTO blocks VALUES(310335,'23bd6092da66032357b13b95206e6527a8d22e6637a097d696d7a96c8858cc89',310335000,NULL,NULL,'47de747ec20cbec96a6bc4b71f67ea827c7a5a1ab0d3541fd539efac7442d644','317ac03fd72f410d545e57d38f90ac4ca7270f52c45ea1ee61a9ec8a312b689f','f5e3df363a8e0a241f389510c156cdad103c82400df34bc959cb673decb3d2e2');
INSERT INTO blocks VALUES(310336,'ec4b8d0968dbae28789be96ffa5a7e27c3846064683acd7c3eb86f1f0cc58199',310336000,NULL,NULL,'c216588e623d2b3d03499c7e9f817106b20a8c98765979987633f1e4e50d9594','40ba486f57a47d264f773a3d43ef5a489c8e58817106cc59af558ca256319c59','86f54e6d23e62b4457f37cdf8e2b174a0002ab78c5a291ea8e15cad0e288b1a3');
INSERT INTO blocks VALUES(310337,'055247d24ba9860eb2eadf9ec7ea966b86794a0e3727e6ffbcba0af38f2bc34a',310337000,NULL,NULL,'a558b47328f54b79a5ad9f7737af0e4df07e13e20f150296370e111879c09c2e','83520e028e369129c97437b3505002591e2d4c124536fe8feb1e25afca37167b','93d3a116e8461e40afc1a5ed5862b85560fa595d52a26d4b080e8475fe63a87f');
INSERT INTO blocks VALUES(310338,'97944272a7e86b716c6587d0da0d2094b6f7e29714daa00fec8677205a049bcd',310338000,NULL,NULL,'31bea50c6481fa982eace70df5fc13d2981f1af13962809e3492b493a0dd4905','b3fed745dc2b7c21da6c57c901b4a8b3ffd125ccbc9608de891c21c6f579e080','6faaf5977be940a34c05c94ae7290c5c5aa53283b0b8a3b9ad9676dd70677e0d');
INSERT INTO blocks VALUES(310339,'99d59ea38842e00c8ba156276582ff67c5fc8c3d3c6929246623d8f51239a052',310339000,NULL,NULL,'6605ca3db3c509fbc8574f2e10a3f981e2ff17b2812946ec8f2b1e49ba44f220','e977c4d41d0f8a01a14c479039759b2ebb2389f279c67ba2c80f176602d1459b','5b7b1499d4209c313265dd1b6a46e30fa91b751aed7e1c23a9593f4dbfe68622');
INSERT INTO blocks VALUES(310340,'f7a193f14949aaae1167aebf7a6814c44712d2b19f6bf802e72be5f97dd7f5a0',310340000,NULL,NULL,'7db1ad1952cac2dda86fff6e5f939010bb30a1da26af438d354e17f423d5bf1f','c8d43a94a12cc6f093095a695fae56bccf2e321cd800031a8cb58029c031660c','f17441416b1d64441f5b8fc327256a8c1fe86668c75c377f3516e34d2cd129f2');
INSERT INTO blocks VALUES(310341,'6c468431e0169b7df175afd661bc21a66f6b4353160f7a6c9df513a6b1788a7f',310341000,NULL,NULL,'1a1eef01250d2c53a1b34a8ee5b1e8fce984c3d47d28c544c6e162493b51225b','a35dc0024698a5399586c5d6a62dd41c91adfe8c87c15bf57f599c73e837eaad','f3afa4b7d5210601aff364aac0967c0503c0a55eef6f02b44d67755298ab0c07');
INSERT INTO blocks VALUES(310342,'48669c2cb8e6bf2ca7f8e4846816d35396cbc88c349a8d1318ded0598a30edf7',310342000,NULL,NULL,'3c85c0b825985b04b42137da7e59fb3daaaf9e65b871b79390a4d8b31be5da92','7e300cf5098ac1ea1627ff39d96bc455999413d10abb8d180467f5651ad25726','e5a149c40a2893cab361be6b3b668be1b8f7ede1028b50f5bd6fe3528762984c');
INSERT INTO blocks VALUES(310343,'41a1030c13ae11f5565e0045c73d15edc583a1ff6f3a8f5eac94ffcfaf759e11',310343000,NULL,NULL,'26f4ea323dd31b715c7a7f4ab8f1feabb199333a8494449ed538ff13215bb3b2','962afbab4e2a71e8cd5d829b32a5754a9c1d3220e2eef0263ddfcd565fc4db7a','552cdcb6d568ceff52645001391a6933c2a96b669a65550749881f3a439b4272');
INSERT INTO blocks VALUES(310344,'97b74842207c7cd27160b23d74d7deb603882e4e5e61e2899c96a39b079b3977',310344000,NULL,NULL,'444314748cb1fa1c836b3b4de65c3920c7fe446741193e5f77843affe3bee908','a1c6af7fd601b9fc26e8ee1db43cee3639944a5f1a8543646645ad1b606ceb7f','f3eb4060e6ccb431402820cbd292a2ee9772a8f486121b036a9a09777fe4de55');
INSERT INTO blocks VALUES(310345,'0bda7b13d1bc2ba4c3c72e0f27157067677595264d6430038f0b227118de8c65',310345000,NULL,NULL,'d1775816bb104187076be74e78e87fc6d367c3cb31d372329aec2b635002ca2e','3dc7e6de7ce2ebe528f57bff1de0f631ee6d907a194e28fe279acf92a1466f5b','f443a2b290e3d11a521e289dad67f4561aa4c35f9c45919d622395f0022d08a2');
INSERT INTO blocks VALUES(310346,'0635503844de474dd694ecbcfb93e578268f77a80230a29986dfa7eeade15b16',310346000,NULL,NULL,'3244eed1df8ec4ae0ddb04f9f6e59e54244ca3df10dc21fc89c99c74ba734781','80c267bf4b4c677528095f32a3e85e60e0a4bb6ef5bff171036fe90785aa891d','3cc0d9a81683fb31611a341f3f35f42c6e7c04000ccbbbb5e749f8bcea1f6bd7');
INSERT INTO blocks VALUES(310347,'f3f6b7e7a27c8da4318f9f2f694f37aaa9255bbdad260cb46f319a4755a1a84d',310347000,NULL,NULL,'6fd1802c269750b69ec04df457d47cd6b44c261340ebd5b4da61f06ede6aa166','9e160dfc79ef80fbab34a797e292ab36ab0f60c0b2182802921492791d689bf6','1708bd999275f0314de79de791d3fff720bcf81e8f0dd29680907ea157de665c');
INSERT INTO blocks VALUES(310348,'c912af0d57982701bcda4293ad1ff3456299fd9e4a1da939d8d94bcb86634412',310348000,NULL,NULL,'668330e80a23f499c0e91b01c4c51aab393813b840f81b6b672611e391699faf','1f6c8a223e835807a984ec8e1aa01e066307c7a854434733ffd6e6ca24066971','db732bc7b1e390bdcac1629836314744cb93ff61fb1bb487e5f2038a2de0ff4c');
INSERT INTO blocks VALUES(310349,'ca911c788add2e16726f4e194137f595823092482e48ff8dd3bdbe56c203523c',310349000,NULL,NULL,'32b36035ac1684e93126657ecd9711feb689672f64cceb03d220a8089dfacf12','bef5740db79806b3e5886102ea824ba1f8550e1d55f323d3ccb660adad7deca3','41536f06058aa53a74615296ba613d42fcf4781f5c24df728c9302c79edcdc29');
INSERT INTO blocks VALUES(310350,'c20d54368c4e558c44e2fbaa0765d3aecc8c9f01d456e3ff219508b5d06bd69d',310350000,NULL,NULL,'dbe70bf3b8e4b74ac25c1b6737b6a760e6a06a4f96ee83a5ca728c8501d4af05','a9d2c6acd7eaf5c798cbd8243c1bd6b7634dda422ad3c4839c0beaef5a83ae0c','c80f3463372ddc133946616dfa7161e789a5187abcb1031427513f40f7ea667e');
INSERT INTO blocks VALUES(310351,'656bd69a59329dbea94b8b22cfdaaec8de9ab50204868f006494d78e7f88e26f',310351000,NULL,NULL,'89bb7ea865a221a3646f78ea774a7cf1e15e8d65b85ddcfbdf87773145904151','cd0336df5e4ccec39f6b03641e766fbfe2fcc73d21123fd02b946ba36086934b','57967fb614fde03444496536cd9435e33842c9c9e20ece3e3f18e2e27be9655d');
INSERT INTO blocks VALUES(310352,'fb97d2f766a23acb9644fef833e0257fdb74546e50d9e2303cf88d2e82b71a50',310352000,NULL,NULL,'fdbf27d576a72b046776be0e5c0a91d060619778aadef3df1d30f1a7785a0fdb','ce3e98f749f31ec0082c54bdefa582741793d0a049636ebe2ef933aec0231dcd','4591524ad7c6626ccb831cfa59348349ba7c0180a2149c47cd60e59aac189831');
INSERT INTO blocks VALUES(310353,'2d3e451f189fc2f29704b1b09820278dd1eeb347fef11352d7a680c9aecc13b8',310353000,NULL,NULL,'73429d323376209447edc6d2ddbfd51f0bcde21736ea6dad61dc96b6984a1fa1','015dd109e8665d3af271805f1966f2d7bf87cd989d1f6b1af01657746e67cc5f','9166cfdd4a2e7144bed00b5afe15a6662fa8b27d871af4e9ad1601d6f88e3bbf');
INSERT INTO blocks VALUES(310354,'437d9635e1702247e0d9330347cc6e339e3678be89a760ba9bf79dd2cd8803e0',310354000,NULL,NULL,'b2bbcbb6a7db94b2a5681c6e380ac13480bb49c29a3fbb3c7c1eb740f70f8324','ac333c913aee8b776bf2a1d0f0cdd7f1946c7e01d83887cfda661d3997c5f8d4','40d9550bc44a147337504c883467ccb0df44861b0b0652a66c107b1729a7baa5');
INSERT INTO blocks VALUES(310355,'ea80897a4f9167bfc775e4e43840d9ea6f839f3571c7ab4433f1e082f4bbe37d',310355000,NULL,NULL,'ccbd3ea41587c3c1d92f355979b49c5340a0a90060f07c228c22d6ff76b25579','0c4a78dab9ab654ad28aacaa66891d0be3332ee3d0222bb49dbf9e2a12fd7a9e','9eafc9d0c29a40fe6485cacd11f4aa982cb670040cbd94a2901558b45e6b717e');
INSERT INTO blocks VALUES(310356,'68088305f7eba74c1d50458e5e5ca5a849f0b4a4e9935709d8ee56877b1b55c4',310356000,NULL,NULL,'06a95d39e110e40ba318320d50984096cbec88c680f426f721154555efc2561f','01d2d0622139b644ea7d5340570ea0a4257953543fb189994fb975e6163d8a60','12c06774d25d13c63fa9bcfc21bb22c0f53b33fb53eccc22697b0fa1d02e51e1');
INSERT INTO blocks VALUES(310357,'4572f7f4ad467ef78212e9e08fa2ce3f01f2acc28c0b8ca9d1479380726bab1f',310357000,NULL,NULL,'443f947352e853367d1c10d25771c7d78eec22fac19c5bace6f96b8f949e264b','25788620f5a7f8d532948463770424c21e75b169432a2e4e1eb1f0a71a0ba6ed','fcbed554c8d39d1b001dab89eb1bc4328df608b93209c562f4bb260dbc23a579');
INSERT INTO blocks VALUES(310358,'d5eae5513f1264d00d8c83fe9271e984774526d89b03ecd78d62d4d95ec1dea6',310358000,NULL,NULL,'c2cd71dc9e7d5ccb5d5e9d6b55c47010c9db6a573d01820da1c8960970fd571f','a1b8f56fb42dd1c6a6e8027454ac7fddc2754b0656688576ec24a6ffdf6daaf7','876d919941b3b1fbda1363384135f292eef71d1fe8477e963452dc3da96cdaa5');
INSERT INTO blocks VALUES(310359,'4fa301160e7e0be18a33065475b1511e859475f390133857a803de0692a9b74f',310359000,NULL,NULL,'5b7646bafc6b11eb1554ea1e02221883043b435ae973c3678505fa2128aadfb7','1e6afae27a3102e7e9665a064e5ff112307388199ebb74e1fc461dcd8d38c85b','254fd8fb43c5c31b2b6fe6e845c9eaf18c9a9def0653a4b1e6540007f2f8fbed');
INSERT INTO blocks VALUES(310360,'cc852c3c20dbb58466f9a3c9f6df59ef1c3584f849272e100823a95b7a3c79f0',310360000,NULL,NULL,'b0e937568a47c244e3b29cfb3a5e7196c171acc1565c44020345c715b7774658','281d2e91b51727ac73fc558906e13a4955c1cfb6f9dd1fbf0dfedfa3e2cf5f95','a2f5bf59e4213704859865db723038436a35b253cfb04e6950f203c36a50391c');
INSERT INTO blocks VALUES(310361,'636110c0af5c76ada1a19fa5cd012e3ee796723f8a7b3a5457d8cb81d6c57019',310361000,NULL,NULL,'fd5b67bb571f4e9c0c37c6a5c9e1181133c301e05f4f97a41bd827eda7a6db3c','c04c35a1fce6da595c33b914dc15072b56e981470a81de7fc2009d1c9d8c1f00','a2f320edf5f692e8e29df89fdf5b1c1c384b5ba6a557e636f3eda29764c229fb');
INSERT INTO blocks VALUES(310362,'6199591a598e9b2159adb828ab26d48c37c26b784f8467a6bb55d51d7b6390f2',310362000,NULL,NULL,'38382cc090b349809c4798c3c83b485f8ff682fd5b5b2568357d62ef30f7c046','07937a84691f1b0bd1897a098318d8d7577da73c4c0fe3fe91931f47a4843259','c41520cabb7eb75305983ed593f90e298c1a1698122926d23d9cf8183a690b07');
INSERT INTO blocks VALUES(310363,'a31967b730f72da6ad20f563df18c081c13e3537ba7ea5ab5d01db40e02647e6',310363000,NULL,NULL,'82911a691937d87629bc14e5294f68a25ff2fc6512370db032834b85a623d5c3','11cf84026a85dca1b2c27408512a07092565061865d153913aa873f83e2062a9','dec4dbd331725676a1415edf4c770636db16024b9a638d20d3d517d311dc1154');
INSERT INTO blocks VALUES(310364,'67025b6f69e33546f3309b229ea1ae22ed12b0544b48e202f5387e08d13be0c9',310364000,NULL,NULL,'cc362ce4c2142e539057430e2dd6402b985c62fefa4e4ad33afe1305f53af8a4','a3864cf99fb338a60ad73c6550ab12cf1852c1aaa1c0d4b30a6454d55f787528','e477765422cab8ba7e76838e064c41108039194a405df9a09a27675cc9127c6f');
INSERT INTO blocks VALUES(310365,'b65b578ed93a85ea5f5005ec957765e2d41e741480adde6968315fe09784c409',310365000,NULL,NULL,'49e41f95f081b70e3f540fa22864cc4f229ceabfdfd54f2da112f1fd35466617','5788e72e314169198d92a014c2e06ca9ce795f4977b48343e6ece965b5cd1f3e','0f59ce84d484daa17eb468b036e16e03ac4373b80543cc1136ee6a402290518a');
INSERT INTO blocks VALUES(310366,'a7843440b110ab26327672e3d65125a1b9efd838671422b6ede6c85890352440',310366000,NULL,NULL,'687c5f3e381d164499126ff90785e3635c825db3808267d4de2ec0e37cc7c597','869e42fb7e4ab2269bf7e9d60accb707b379d4f9de7bc237841def956732ebf7','e79c3af0cc9d31a7addf7e842c906036d0a7f8e840c01dd2255e84a75c904820');
INSERT INTO blocks VALUES(310367,'326c7e51165800a892b48909d105ff5ea572ff408d56d1623ad66d3dfeeb4f47',310367000,NULL,NULL,'d7fe976a4b2cca2e23d082a703ef4f4739e110ce1e0a373e76064f6186856ff7','e0ef9aa9d9b7d1c3a65d42e7161724dc87d780b9522996d3ff65a25193ce2b93','44893db5bd2f4402e6be28ee3e849b59ff0db03611017f86a0cff5eed9c21270');
INSERT INTO blocks VALUES(310368,'f7bfee2feb32c2bfd998dc0f6bff5e5994a3131808b912d692c3089528b4e006',310368000,NULL,NULL,'97f0a0f9e6f355dd179aa2941412decc1b0a06de0dc14dce8538aed6e35d41ba','46d32b302c2deecf756e3958ee2228bb93ac98906ae54331efb5b90f62b85f77','3d50870a3238701e1cfa4997cba33f2c0a60ef5f1b3d743b1d68ed8f67949eda');
INSERT INTO blocks VALUES(310369,'0f836b76eb06019a6bb01776e80bc10dac9fb77002262c80d6683fd42dbfc8da',310369000,NULL,NULL,'1b5d9ec9bd918c84a5f9b6882c94a739cc1ad1362dedfbdf7b2009fd42251d66','b10d6c9fbfdac1627e51cb2aff6b121ace75c626a05fe16b11e6794c5683c60f','d4c4cac95ab99433346656e395709a7e35cbbf239befe4939dc9a1f03ea74f4c');
INSERT INTO blocks VALUES(310370,'9eb8f1f6cc0ed3d2a77c5b2c66965150c8ceb26d357b9844e19674d8221fef67',310370000,NULL,NULL,'578b039ed2b9a25e1c75ad9a5242c5962d6645616dc53fb08386602e40f14486','bdc20946af8409c997efd9283331552f073a3f0cd09eee60f1a56a4e1ffd760b','390d5f9da2620d2566de0b5948f8034fa19d747c962bbe3591ddc24dca549fc6');
INSERT INTO blocks VALUES(310371,'7404cb31a39887a9841c2c27309d8c50b88748ed5fa8a3e5ba4cc3fc18310154',310371000,NULL,NULL,'473d21b8218a2b02f7fa0d5daf114fa988e4a3d97c33aebe97e51a8d22252492','34d2d8b012eea200df732029472cd9d7fc9bbf42c1ce67adc25b7bf7c08419b8','9a2bf2f3c0b11674695619db0331f2e1c3023b5069a936d895b1fc5ebdbd957e');
INSERT INTO blocks VALUES(310372,'d3a790f6f5f85e2662a9d5fcd94a38bfe9f318ffd695f4770b6ea0770e1ae18d',310372000,NULL,NULL,'0c306eb25702d190ce32cac521b1fac9b8a7cbcf441fd74be8de2e002b4ce14c','0b80ff1489d766a23ee7929394d314c624620dfa6df0fab7af05474895614ff2','5c56e054077201ba73fe277789d0105cd53e6f1bc8a9b6d0148c5183186e80d8');
INSERT INTO blocks VALUES(310373,'c192bec419937220c2705ce8a260ba0922940af116e10a2bc9db94f7497cf9c0',310373000,NULL,NULL,'48d14b17f9074ce1f75ab32581e8f6fe7d518ebd669af6508e5d986d97c92b3d','4d9e02a4f6be869f7235a53149d36146db6ccce35e163bdd4d3ce1d4ea618f3f','7861881e4e2095369a7bbfde371648a02e0d31b265b1234a66cb28e5acb67781');
INSERT INTO blocks VALUES(310374,'f541273d293a084509916c10aec0de40092c7695888ec7510f23e0c7bb405f8e',310374000,NULL,NULL,'aee93917f6fe0046069aaff48d5d1875a9c4451acec6562a377428bfb1184cd4','aa1545e0a3eeae700fb9a5afe0365659e3ae1527ad555cfa69a368a62359b2e0','c149ffc5c5168825f4986e3289f92dd942ad446bfa1b8be4af928890405bb65e');
INSERT INTO blocks VALUES(310375,'da666e1886212e20c154aba9d6b617e471106ddc9b8c8a28e9860baf82a17458',310375000,NULL,NULL,'2b0d74911bba5c9530b69c04fec512fe4c5df25458e5237db884586a221fa30b','ec33fbe1aa123acb40c65b8a448436def7e670bc11f57e7ea81a590256fa03bf','e8df498dc7bb480788a03dd7e1a7404c910ca0a24bbc151a9d142fc97e8ca790');
INSERT INTO blocks VALUES(310376,'5dc483d7d1697eb823cba64bb8d6c0aded59d00ea37067de0caeebf3ea4ea7dc',310376000,NULL,NULL,'a6f84afe2845ba2fa4e5e7377b1d4474dbde6dfc9c4bed050e6d10cc80025e82','f60b11851450c388d0b34f0082ae562538eea1f7267d0c54739e24be001708e0','e4c8ea454d67c42109111faa87ed93ce77a05ba598b4c1816f93834969e4df56');
INSERT INTO blocks VALUES(310377,'f8d1cac1fef3fa6e7ad1c44ff6ae2c6920985bad74e77a6868612ee81f16b0b3',310377000,NULL,NULL,'e006e13691719e4fce65e72c692d3affeae8ae465de2a3b285a1bed4eb518a70','6120536c3ce65774b059eaf66cce3b67b9bc0d8fbffb5522c7fc0b659908ab73','b2389b762e54347c830ec7f424fa8d526f37dd01c20dd03ac9f3808d8262f603');
INSERT INTO blocks VALUES(310378,'fec994dd24e213aa78f166ca315c90cb74ee871295a252723dd269c13fc614ce',310378000,NULL,NULL,'607ffa4928577b82f275750353fcecc2e50098d227f18bb8ea95ac2bbb10eea6','5dd1bb601133d103e4da02e5565ce9f0ee904b9d40f11424b3838f00ad463233','d117ea88864fe3f19f367e1c3361e902dce3a79fe0c85e845d9fc51aea22c0bc');
INSERT INTO blocks VALUES(310379,'d86cdb36616976eafb054477058de5670a02194f3ee27911df1822ff1c26f19c',310379000,NULL,NULL,'9f17e8d662dbbfc12a56dc36172b3154bc9b05a87885d1411826481e1ca4f6ea','55989c1b10eecdbb7b71e454db4e06f11e316e4a8d7d37b4b27006c9498a1b95','f61499992c4f360f360ecc9e4465d33a768a9f27b66831958286944feb20aecb');
INSERT INTO blocks VALUES(310380,'292dba1b887326f0719fe00caf9863afc613fc1643e041ba7678a325cf2b6aae',310380000,NULL,NULL,'d617e30e1a32ed1cf269a190fd4c843755413492827546a0b3ed14278f817532','98c67bdbf6437cbb778f1b52bf478d346499483edebf307faa0692d51fca56ad','27ad849430ab9fec50a6cc2838684531f16b3a3418cf547b1767e21573ce98b3');
INSERT INTO blocks VALUES(310381,'6726e0171d41e8b03e8c7a245ef69477b44506b651efe999e892e1e6d9d4cf38',310381000,NULL,NULL,'8af8d819f02927de4a74d3d37dcecf6e5124d53be37603764b1b1adad13b0d7a','da4c589d45bb47c441a5f7a8b7e6190e1721e4b5645347977d3f7d8312b070d7','bb0f96f7a5e9caa7c6d8599054b26c9adfba26a5cc17dea6544fc233cec1c3ed');
INSERT INTO blocks VALUES(310382,'0be33004c34938cedd0901b03c95e55d91590aa2fec6c5f6e44aec5366a0e7d8',310382000,NULL,NULL,'809d5c20335bbefe8e4f3552e24b24d96f6ee4ab12f3bfc9e74898371cf69797','bef6a13095e99b40ac83677188467e6924fa7e878ed1005b5e724bbf244d91b5','44ee61ce4a2075b26dd50a706f51cbc34abd3218b7207970283e803677804545');
INSERT INTO blocks VALUES(310383,'992ff9a3b2f4e303854514d4cad554ff333c1f3f84961aa5a6b570af44a74508',310383000,NULL,NULL,'d8ec301994a5333f8efe7cc547a833d26c6766deb0b39c4fc18d1bdb470ee903','aa962cfc3a65ccb4f548f1661a064116836040a4a968c6f58818badca84fbe63','d7173018f252a3cebf864760095645a8dd03b73f22f1dcc6c99ee9176aa8dfd5');
INSERT INTO blocks VALUES(310384,'d518c696796401d77956d878cbdc247e207f03198eabc2749d61ebeadee87e5e',310384000,NULL,NULL,'fe47a03993cb9079a6e72810552d631fe838bcfaba3b34c73c9948af77266df2','488043a3bbadd8cd967201b139d5edd3c50adc437f6851c7b791ce719336302e','ff98e13c80a03a944947d83b2463ad37ca4eeb20928c3fa79d2e3a94b58102d3');
INSERT INTO blocks VALUES(310385,'2aa6a491a03a1a16adbc5f5e795c97ec338345cfdf10ff711ffb7ac3a0e26e28',310385000,NULL,NULL,'6114e98e0004cf0f9472fce6bfa6bb99ae38e57214c8b134f30da1d62399f6ef','c76613f28897cbacd300ef2ae6aeccc34af2fdaf1f68554141d0628c98283c4e','8690b311905f4adcd7fe3a42b42abe39a773dbecd2577df812267dc0cc539bdc');
INSERT INTO blocks VALUES(310386,'9d19a754b48a180fd5ebb0ae63e96fa9f4a67e475aeefa41f8f4f8420e677eda',310386000,NULL,NULL,'4c52d59ade1bd2068e3b75b8b3cd1d23c6a94b6437f7966d10f5a07bf8f630ff','eee5edc413a0775271370f073c2c36ff144123b5995a90842d3e65c1b5112418','4e82ea7881e328052b3a946e77e11f50ecfeafd344d7a799594308757d5dd73d');
INSERT INTO blocks VALUES(310387,'b4cac00f59c626206e193575b3ba9bfddd83bbfc374ebeb2838acd25e34a6c2b',310387000,NULL,NULL,'327e9a842233568888998ec1456b6f78c093b47639707d44e6336b2bc18d955f','5cf78e08f145a08fd3e099429cbef8e5ab59cb69bfabf88821f361f059adbddd','8cb7eb4d2b8c9cdef93620f738f3df1295b745ab891c9585288fe7a7fd9f6454');
INSERT INTO blocks VALUES(310388,'41a04637694ea47a57b76fb52d3e8cfe67ee28e3e8744218f652166abe833284',310388000,NULL,NULL,'6efaab188a5cae39ef547a804f61bcbc2be4881e0569f49d7622b407f6860401','e3abf47ed96b9b15c4c6702d1d21b2452af7869bdff81a7a26435d8dd23fd96c','3269ffb7660657f6876cffed982002c299525a493523add4fdd55feb208de6e5');
INSERT INTO blocks VALUES(310389,'3ec95ae011161c6752f308d28bde892b2846e96a96de164e5f3394744d0aa607',310389000,NULL,NULL,'89c686d5d973691a7281268c867f837b86b140a05f16f12302a3cdeb3b6a0ee9','b22a6d17eed5fd29190b52010e2e5e95184f1560a20b157feacabccadb5ff8bf','2d47c0d05601b6be7e356a81e2cec3de864d3a8988bc6508fa6ac97e18df72c2');
INSERT INTO blocks VALUES(310390,'f05a916c6be28909fa19d176e0232f704d8108f73083dded5365d05b306ddf1a',310390000,NULL,NULL,'2c4eceebb94d0c7a7702478d9547d1afbb42ab5ecb5ae6271a3f69942bd77e50','a9031515eb1113db7dd1f5441aba4527b4b8f6213147024e75235a6b97b98cba','69fa70c0ecafc358638bc0fb4ee975cfeb308a52c019de096acaaf879f7507ac');
INSERT INTO blocks VALUES(310391,'fc26112b7fdd8aaf333645607dabc9781eac067d4468d63bb46628623e122952',310391000,NULL,NULL,'06397124ee2a1bcb9104899469394855d4ecccd1a08626d650bdf3169e227831','ad3d718d6cacf0e28185cb2093fd8ea6f3977817eff4f83f4bcfd01896ba94d2','1f93797718f750a9fcb3dca42da0d42500bddbe566c88f3560a48a858216f519');
INSERT INTO blocks VALUES(310392,'f7022ecab2f2179c398580460f50c643b10d4b6869e5519db6ef5d5a27d84a1d',310392000,NULL,NULL,'44974b5fec0be3a2958d39f2d6824a2e82733f873a404ec9887178c620843149','50552937bb461b709b5be12d81b3f9e4c9316b6da317355a76fc70774c07f997','60527dcc5ae2b28806845c24b2c8cd242a962121b8bbaa0fad392838665d39db');
INSERT INTO blocks VALUES(310393,'e6aeef89ab079721e7eae02f7b197acfb37c2de587d35a5cf4dd1e3c54d68308',310393000,NULL,NULL,'1863677c0e552344607b1af3eb8ef8f4fc6b2a73d63eebb3e9928302c887970f','0f6302a52cca799465d6712da594cb2865a34edaa31dddc939843411692b8d95','7426a8c4cb60b3661fee7c8190299a88ae14b6912e2726a8f4584fe79417fd83');
INSERT INTO blocks VALUES(310394,'2a944743c3beb3bf1b530bd6a210682a0a0e9b0e6a9ff938d9be856236779a6f',310394000,NULL,NULL,'3838ba6e84376ed8dffb3fee9b5928d903952c0d8a8ad41ab63a9651a1c8c770','f2ab83f2a4bbabcd72c27543b9e06e23f67e4c657b6fae78e2fbdfd3a3a88008','e93009dd0ec0f2ce91c4487668253861888880313f73226b3fc7317403f036de');
INSERT INTO blocks VALUES(310395,'19eb891ce70b82db2f2745e1d60e0cf445363aaff4e96335f9014d92312d20e4',310395000,NULL,NULL,'872367d61f81cddeb555da5f9c4f46a8ac57c24629ab073094e407a4555a8555','4d56f40558dd8ff8104ec1632dfc9c475ab3cf2f366c5eaa907424dbc42758cb','42c79f6af57c8030e3c2e6cf134be9053764ebabb4af16a158b58ed8f6d6fd9c');
INSERT INTO blocks VALUES(310396,'aea407729ac8d8e9221efd9d70106d14df6aaf9f2f87dc6f490835a9caadf08e',310396000,NULL,NULL,'b9a9eaaf1cf6cfa4ae5b0f314812a9a2346209da0b7ce57e16010d2a01c0092a','69df6efd0b19ad5910bdd6a3b7c3c1f92e61fe564ac19f15ecc9396362d1e66a','0f13f519d420993c814adc94cad26f62d743a92ac998274c199d8ebfa6bbc984');
INSERT INTO blocks VALUES(310397,'7c429e56a19e884a8a77a759b52334a4b79404081b976270114043ba94d7985c',310397000,NULL,NULL,'b61f36bcc934a18fdccf7806d41482684ca129801d0b9ce7815dcd488fc49a66','e3b052e4b1512c1fc03460d8b165031b469b8bbef48f022311428de8d277db7b','1f4e0b0c894bb855b2b81ca2cb0276b1b2431c08e97b56ea781c39e5ef10e0de');
INSERT INTO blocks VALUES(310398,'55c046db86dee1d63c0e46e6df79b5b77dfd4ab2ff5da79e6360ce77dd98335e',310398000,NULL,NULL,'9446476e123e5dd354682c60591cab8b712c30df9080dde756246eef45e21df5','091bf9f1f1cdca320c408b483a22b330ed03cd363f4604d90d820f4c9934ff8b','ecfd874ce8216f17a56aee63b8fb96457c2e6d555f395969c9de621a3caf68f5');
INSERT INTO blocks VALUES(310399,'765abc449b3127d71ab971e0c2ae69c570284e0c5dacf4c3c07f2e4eca180e7a',310399000,NULL,NULL,'50d288bca09d446f56544fb1ec50d613bdf156488468ac92d433425a3cab0804','6fdf51dcb0482117a0c7841f35205e90326931daeb35d4a50759dafe6109e761','6befa8071f10075236ac9cbb69179a6f21f0fb6c1d9afbda8c31316a3d923726');
INSERT INTO blocks VALUES(310400,'925bc6f6f45fe2fb2d494e852aaf667d8623e5dae2e92fdffa80f15661f04218',310400000,NULL,NULL,'349a24fd446727bb1793ccf88fc569d20eb680c10e506fc25b281ce6ec3fd7bd','e00ad4a31e342653bca8de193018b6388dc878d949f22c4f7f385369d16e3b77','57ce9e1e074e87d8ed3d9f808169c8736b7be0434b5d2cc1c1dc16be51bca58e');
INSERT INTO blocks VALUES(310401,'f7b9af2e2cd16c478eed4a34021f2009944dbc9b757bf8fe4fc03f9d900e0351',310401000,NULL,NULL,'52c06b68cad19608420b73476a73b411d0327382b92bd454cadf1b8616eb17a5','7be2865d031ba77e2f589e86be49f6d6d3ef07f70975df72d3633527e3d7960c','8526961e086b6bf391a4243b92dc22f4f909013528b75c13e6e12eaa0d57947a');
INSERT INTO blocks VALUES(310402,'1404f1826cd93e1861dd92ca3f3b05c65e8578b88626577a3cbad1e771b96e44',310402000,NULL,NULL,'8bf64213a454c62dd4b0dcd7dfa298da0244a6aa7ae6fff98be6f49d50d259ab','498685cab34b81bceda2d35af648f5f10eb806fdd712e9e75b411d17ef7168d1','6143a3523ed5a3242ad94c146fc01fe35d63bdc7daac9b0797a3cef28cbaf6b2');
INSERT INTO blocks VALUES(310403,'f7426dbd4a0808148b5fc3eb66df4a8ad606c97888c175850f65099286c7581c',310403000,NULL,NULL,'fb2a365372522d1442792cb38e1a4167eda2612ef442c776749097a3d541a827','b9e9b0c64411d0330e0538fd8174c441ae985e44b237991fe001e1405cbb4355','046946a9e380676f95c2e5337a24b62c1e86f0af2d157ef17069adde1cdab4a5');
INSERT INTO blocks VALUES(310404,'401c327424b39a6d908f1a2f2202208a7893a5bedc2b9aff8e7eda0b64040040',310404000,NULL,NULL,'47f96d798df9cad17667be908ebb063ab9f79d947784a78189d247e626864a5f','62afe454f86713c40b93a806636717befa27c0ff6df5e713ed6fdfb5fbb87e89','407c1d1aeb8ddcbdfc0282b284226444e9ed408d93ac2ff9eb4ee808eb1d64cf');
INSERT INTO blocks VALUES(310405,'4f6928561724e0f6aab2fc40719f591823ca7e57e42d1589a943f8c55400430a',310405000,NULL,NULL,'185780205a9ab241bb0656799fd0d5942c1e3e5854abd1d06573da550b04b096','201c777861cc9d65d17bfadb3fa0b5450766d8eea6d7f3edecc7b3073d180fe3','30268e8682f822afd0fd9132a843b53de1191ef3240f9f2b6bee2f4edca00bd7');
INSERT INTO blocks VALUES(310406,'6784365c24e32a1dd59043f89283c7f4ac8ceb3ef75310414ded9903a9967b97',310406000,NULL,NULL,'367b9de2313c5f7fce0c2dc2b4a8e2bc059f6881bc924f7315e8e2ca61728a59','8a619709e56386a511226b71417ee7c089b1f0c12a9f48ea587fc17cc50dc18c','a586cdd7f523e5d46fc89ac34bfb1e5b61893ccd19349bdb2cfffb3f724de8e9');
INSERT INTO blocks VALUES(310407,'84396eb206e0ec366059d9e60aefdb381bca5082d58bffb3d2a7e7b6227fc01e',310407000,NULL,NULL,'2bdbd79575aa2ff52ba0cce3fc1a1aac6120d598a8ab0ff3925e1395e6cad2d1','2881a8cce0539785cf21c8ff5b3403a908de84b490022010fe74ecad0329d1e2','cc87ae0c7f741e7e6cb740a683debd47608bcd3ce52775fdadb218a6a5e97894');
INSERT INTO blocks VALUES(310408,'4827c178805e2abae5cb6625605623b3260622b364b7b6be455060deaaec2cda',310408000,NULL,NULL,'fcd0edef8c4ae9517a6e793a2742c598de38c122829b7a7aa265310417ac92c3','c3b02641b5d7096e86895f50bf2081972b2982e8e9974d85f3e24266dfe86413','e58d1f3a536cfe53ed57858ae83feec759d6dc41400167c883afd09dec66d1fb');
INSERT INTO blocks VALUES(310409,'01a719656ad1140e975b2bdc8eebb1e7395905fd814b30690ab0a7abd4f76bba',310409000,NULL,NULL,'5b663c40873af21ebc721f2689e2c57a2c787fff579c58f033bba75910a64837','ef0a7a61d4e11b40d2da832d05bf813b4b83768f168be5dde74e31a645e76a3e','7cda943c65a449f12680395d0f01d79556907d37afe313a2a4c4087b7e454122');
INSERT INTO blocks VALUES(310410,'247a0070ac1ab6a3bd3ec5e73f802d9fbdcfa7ee562eaeeb21193f487ec4d348',310410000,NULL,NULL,'93c5a33931b2a33933bc286d6987b34730c0677460e4875d5c032ae86c2e01f0','17b45b42abe3a13b93de019f83dfcf2387c6e4308a712fb6ee142c2c13bd0a5e','2606853bb07c2be6c2fd422688fc0bade220bb8b1fe949a800641c6189b4d5b2');
INSERT INTO blocks VALUES(310411,'26cae3289bb171773e9e876faa3e45f0ccc992380bb4d00c3a01d087ef537ae2',310411000,NULL,NULL,'8d98498f89619a2e334e9ac69bf8ff37251af6431d9bb6d1ea8bbc404c5e560d','823764f461b404119c9eb74ccbd198f9dde8037e64efe2ccea54ecf59f4734f4','30d6c058a9ae85520058458703ece1aa3bd61beb38c90d3cffc0b085eda73537');
INSERT INTO blocks VALUES(310412,'ab84ad5a3df5cfdce9f90b8d251eb6f68b55e6976a980de6de5bcda148b0cd20',310412000,NULL,NULL,'a16a650c4b63ed783e7229980be1177da867c188a5039ed5c58b9717f6ccf634','4de68d2f1f9ad13c5df2cdefebc231ad9f076bbff81d0f768b11f39391c5eeb4','1f54d00dde511fd50caae4edfcfdf111731fb54c229729cab1b897f56bbc6642');
INSERT INTO blocks VALUES(310413,'21c33c9fd432343b549f0036c3620754565c3ad99f19f91f4e42344f10ec79bf',310413000,NULL,NULL,'768577c1a7c2cf2cc19cd8dbe823f1bdb8a222daee4c7ac7b5ead6633040c283','37ff14c5685e45eba94d71e2397335944527befdec378aa655aa9be55c01dd6f','9e14ec39b7067c3dcbdc93fee615336f8aac09b9c2487f4a9c4a14acdbec3d1f');
INSERT INTO blocks VALUES(310414,'8cff03c07fd2a899c3bcf6ac93e05840e00de3133da14a413e9807304db854b6',310414000,NULL,NULL,'906c491f164877c31002da41233c237d0d4a945a0072406a7b7d13df74be7eec','4a6befa5c96579cdf70e3fbcf681a64fa141e237d8146984699315a7e4a9bd05','3102efc47982fae4e5ea738fea10880732e468cec4c0d34607d6c44a65071da9');
INSERT INTO blocks VALUES(310415,'dd0facbd37cca09870f6054d95710d5d97528ed3d1faf2557914b61a1fc9c1cc',310415000,NULL,NULL,'d27f99b4a67dfc910d3b932f97b7299779f245e95f871140d3c90f13cc6e506e','a1d9c2c74127699344c2977042773422409d354fc393f199fca9662868afa844','2a2f05f8157042b1d31678574bd5f1d8fc2685364cbccf1442163131c75127ea');
INSERT INTO blocks VALUES(310416,'7302158055327843ded75203f7cf9320c8719b9d1a044207d2a97f09791a5b6b',310416000,NULL,NULL,'90fcd04c508a9821e0ba0ed36cd7cfadd1d3c95116e3f52ad69f98d3d14de571','b87dd90386307110fbd1b2ffee32fde1b51d5d6a798335f516cf1b03f7821b6f','ff299c30f5cd5422433733a99272e07df0e9747337451d19e30957a7d3873c9c');
INSERT INTO blocks VALUES(310417,'2fef6d72654cbd4ea08e0989c18c32f2fe22de70a4c2d863c1778086b0449002',310417000,NULL,NULL,'19cbb26c6d24df5b110a5aae9b53a911a61b2086dde926273a1b0f66c1049e6b','53115a4c67ea4350e078d5079edca376d41a13ef7b3bb79ef2c2776e955cb410','48f64d3610f75e115ae09353fd773726e42538c8812e06328c9e64a4e6e4c8f6');
INSERT INTO blocks VALUES(310418,'fc27f87607fd57cb02ce54d83cec184cf7d196738f52a8eb9c91b1ea7d071509',310418000,NULL,NULL,'2dc971d2db4e92e2d5dcef124bf9cdad33c41a71d6ae3db80297cb2257911f0d','7a38fb4e2a8ff06135c3112016e39f4b48a6a22faa9dfef2ae986e2d15c9569f','b043acaef70a324b0e4d8b5c18c8f44a19b3de90a75bcd3fb85d9279cbb05ba2');
INSERT INTO blocks VALUES(310419,'9df404f5ce813fe6eb0541203c108bc7a0a2bac341a69d607c6641c140e21c8e',310419000,NULL,NULL,'7ad2bf141622a0db4b27b1f4dab4857d1595e3f746a4113992850a680ebf1f37','c16d243da8ce0411c52ccc06bb14dad3cf97a92bca609fde6b7e52b1d8b56d3f','1eed60267cbd4cbe165cd950d5e45d48823ae7b1ecf7ec40cc5738d98e8da1f2');
INSERT INTO blocks VALUES(310420,'138b3f1773159c0dd265a2d32dd2141202d174c2e52a4aeac3588224a3558372',310420000,NULL,NULL,'3602b26268d1bd3fc5f08f170e9767ff07c91f6976a1c342dc6b24f7ee98c509','f909cfaf7326866eb181ac03e274ff80225ec86650997df9c4311de30af791f0','1c59c6b43735835e53d540fe662e0895adfd428250da877b92f50cc68f5a9539');
INSERT INTO blocks VALUES(310421,'71fe2b0e02c5cad8588636016483ddd97a4ef0737283b5fd4ab6ea5dc5c56b9a',310421000,NULL,NULL,'1c1facfa3852b33c173a08d06450335a2b230541c60973a154e8dd864f3c3c8b','48d24440f8e6c9e685d9cca8fd960f2b36afdc4b2c27932f91fcbe984a684aef','a35594d1962e44acd9ab24034e670b39e804217afa6dd21e0069f843ab34399e');
INSERT INTO blocks VALUES(310422,'cd40260541b9ed20abaac53b8f601d01cd972c34f28d91718854f1f3a4026158',310422000,NULL,NULL,'e788123aefd1129554fa2c166dbd06ce68f913730183ca73cf248c1f5284eba4','492621c2779d6ce8735af4edfcbfa6fd2f16a2392af9ad7432f548b729870b6a','5ec857431d1c6fea510eb07fecaa4f11aea6dff84afd322cef03636e253563a8');
INSERT INTO blocks VALUES(310423,'6ca0d6d246108b2df3de62a4dd454ff940e1945f194ba72566089f98ad72f4db',310423000,NULL,NULL,'ad445e5351af8739b2f74cbba8b44201c20ab55ad1db064402614fb97f35c375','e756d4c1d37a6ea4b35a3586653771087a4c43b9cf03daf8732a96aed3f8b512','ddfd8b1263958bc7f88460fddaa52356ddd6e3b6b21cdac6fecb967306fb8eb2');
INSERT INTO blocks VALUES(310424,'ed42fe6896e4ba9ded6ea352a1e7e02f3d786bfc9379780daba4e7aa049668ad',310424000,NULL,NULL,'e89872ed802fe4421844882958fe6384cf21a85a6dcf10db761e2bb4a77ed24e','454a55cc3bfffbf8444b47eee810959b4f509b36398ae39e999f32b0203e5b0e','05fe6284f178561567ebb95209b46ade9aaa26377d42f6091ce61b6d3d2cc863');
INSERT INTO blocks VALUES(310425,'73f4be91e41a2ccd1c4d836a5cea28aea906ac9ede7773d9cd51dff5936f1ba7',310425000,NULL,NULL,'29e595e9ac7717013cfc8d12255496192234abbddd8a66762a5eaff0c49f3750','5c6dae63d57dd0c60ff61f569c7e7e23c7dcfc447aff11865e731a7cd35d9a14','5b89713f019bfd8bfaa90481728a394bcc25a95458af077394615f58a8211cc0');
INSERT INTO blocks VALUES(310426,'9d28065325bb70b8e272f6bee3bc2cd5ea4ea4d36e293075096e204cb53dc415',310426000,NULL,NULL,'9b9509ce7b7bf380f4d030604810a755c71fabe27152be990997a6a9db37ff15','7c7ff44c6e932b79f3ba715c6f8cf0e6ee17650a2ddcbaffabfb389528fd736f','f63e41921698e38fd6d82e338c59e443b35fa1123b276b4f3111644443c8f9b4');
INSERT INTO blocks VALUES(310427,'d08e8bc7035bbf08ec91bf42839eccb3d7e489d68f85a0be426f95709a976a2a',310427000,NULL,NULL,'f1b834e2a380f1b9a78c592acbe78ec809220c620e15f296ab8d7ecea6cd392e','b3d932601e711b6313f7a30ecbde263d33c2afaf08c744003ddebc6dd8581fd7','3820ef4bf1393dc7c09680a1e2f22945f757ce5f476a664d6e42d83f0acb9dbd');
INSERT INTO blocks VALUES(310428,'2eef4e1784ee12bcb13628f2c0dc7c008db6aaf55930d5de09513425f55658a2',310428000,NULL,NULL,'9e963a17fbc4a5c20d48094f1459959033520f92d7a8bc044b71bbffb8dd173d','24e96d6985d2467ac0abb67634fa1dd40bf347eb76a2e9f1f63de03deda50a9a','b64fbd499d6609c496e265032b7a460be6fb2db45b3025b962f6414c313a6dea');
INSERT INTO blocks VALUES(310429,'086bfbba799c6d66a39d90a810b8dd6753f2904a48e2c01590845adda214cf8d',310429000,NULL,NULL,'ac8cfd965b9c53f32731a3e0fcdb6df5746d646b02c88b5201a674125e37eed5','de4ee644e224ee40a6e48f55d0e1c5b2abdaa0a707c3c18ff801c0edf5f505bb','e513fd17b91936ad55ae7d79c67b14c1f6e91c43dac50b1a9bae26fb46efc23d');
INSERT INTO blocks VALUES(310430,'870cf1829f84d1f29c231190205fe2e961738240fc16477c7de24da037763048',310430000,NULL,NULL,'33654e32dfd41ff3a5744b57fd2483a08a2b4729c18ca54c3ac5d95a1bf0ef21','c39eedc9c189f70ed959451d7bdf5e837bdffc4dec9eb4ff238729d38cce940d','9f48ce497db1c0c73ed1fb48d36c4bbf5978a5084d1fd1cdc0b269e5ab3f5a16');
INSERT INTO blocks VALUES(310431,'20b72324e40ffc43a49569b560d6245c679e638b9d20404fc1e3386992d63648',310431000,NULL,NULL,'ba8837c811ae87981cc37cb49438d958fa58dfc5a95824040f2fd088465406d1','2ab6cbb8716a59d966ea41cb81fe11e76512b6941e534fc7534d5ffc12757d0f','1b339e805b807cb76f53a6b8d2b06cfd7ff115430af60f900435d4a048fcd98d');
INSERT INTO blocks VALUES(310432,'c81811aca423aa2ccb3fd717b54a24a990611365c360667687dc723e9208ad93',310432000,NULL,NULL,'7864019cb0cbbcd895154421183d6acb932b1d64441103b913d52469f656655f','1d36faf45d32e36944e5ce57b060cde1eece44d917c491efdc98517d5f257e3d','f81f8673327e7a0ff705743aa4301e3d1da511cc2399d89e2ad2ef8f77ace1b0');
INSERT INTO blocks VALUES(310433,'997e4a145d638ad3dcdb2865f8b8fd95242cbc4a4359407791f421f129b1d725',310433000,NULL,NULL,'a6da92ef0df7d092de09f2f8d2c99ff65ad74e2a0bd2ea25f8335614372f5279','6699acca5161e69474064bc65af80dcc7969241e42106d43352fd6e4b651adda','1ab58de64f514daedd11696020180957a11816344a508e3169b36838faa26aa0');
INSERT INTO blocks VALUES(310434,'61df9508e53a7fe477f063e0ff7e86fbb0aef80ff2ddedc556236a38f49ac4d8',310434000,NULL,NULL,'e288db28ac6a42822f85fd042f65b57378bc6cc2f8616edfa88143d7b1c9ddcc','49231a538de6497e93f8c6b21f48a6c5694db75a1baaaae7f31670743dcd6a37','90217398765aa350bd36fa769f82d00f08447823e69514b483ef243b0930b280');
INSERT INTO blocks VALUES(310435,'f24cf5e1296952a47556ac80a455a2c45da5c0dc2b388b51d235a3f741793d5f',310435000,NULL,NULL,'e87af314e8d7a5f2315ccc559d7c2255c008ba63aff017696201db69344d423f','4e55adb90c1a5ab2989a5969f701b5458218ec3bbf957e3bc73acf2d7cab8171','6927c224e07937d256135d621c6e4519904fcf64852dda45b8a83c4743214b80');
INSERT INTO blocks VALUES(310436,'a5e341ba92bdf9b3938691cd3aab87731eba5428bb61a804cecf9178c8da0c19',310436000,NULL,NULL,'82327b93bd3ffcdf797bc2f6470b9c8c5101e54b924ec5f141a31356aa8865c7','6dea3d8b96087a7d8486244de73a00933d2907ec07e0a4196b0cf25a8d4783e7','e519aa93a3e78050d29e58e3fec3bea0a201f8fc3ca2b7a6f61a6c33a1e9c3df');
INSERT INTO blocks VALUES(310437,'9e18d0ffff2cb464c664cefc76e32d35752c9e639045542a73746f5ec2f3b002',310437000,NULL,NULL,'70d86f9ef8df495474de06b94e1857693c73d9ca3528356b82553a52fdce0dda','8dff997ceb062b6d40f2344bf50f613b91f532907889fdc871ebb9280276bad7','c690e3e9850506b60f6fe70842babe9dac8b8cda7bc3b8ac29e594043787ad76');
INSERT INTO blocks VALUES(310438,'36be4b3470275ff5e23ed4be8f380d6e034eb827ebe9143218d6e4689ea5a9fc',310438000,NULL,NULL,'44b90478e32373205462f0fb212da636b31db6dfb99a2b56923beb97a3a64722','d20e153bee78483e1c806a1f04a07515d2d63a5ffb0c3f20e20a3b804aa4c2d4','2fb16271511e413943fe0ffb58ccc7e6b9c611fd4bbd9fc873a7b5da71db6923');
INSERT INTO blocks VALUES(310439,'4f2449fce22be0edb4d2aefac6f35ce5a47b871623d07c2a8c166363112b2877',310439000,NULL,NULL,'66b791b9deb7d2fc8b075f41d712e300ffa9c46ca9d6f4e7cec6429ca6a65163','adee3f57d0b0e321cf086dd968fd1f34ccba9d587c6129ceb4d275730625e128','e135f6cc544c5b3c4cbb87ee5f06a9b0a274e947253ecaf0d3c9bd0becc27ee5');
INSERT INTO blocks VALUES(310440,'89d6bd4cdac1cae08c704490406c41fbc5e1efa6c2d7f161e9175149175ef12a',310440000,NULL,NULL,'5baa10e1659182ba4511f87f08deda38d5de3501c63efd376604cc199140d27c','146729916823772773712688e19487a3bc762330b41cccf269276f7c29051cee','1843e5f8be3d4383179fac87df7a0ed90041b9d996d3fa5325cbb9dd206dfc92');
INSERT INTO blocks VALUES(310441,'2df1dc53d6481a1ce3a6fee51ad4adcce95f702606fee7c43feda4965cf9ee15',310441000,NULL,NULL,'2d490229fead1b15a8350da7bcc83c483dae06e4a2f574c6e8fde248acd449d6','893bbc852be6773790420d61e81293c2c8da6f8c866aa40a3352f92febdb1b46','be76b185f74f5f36836df80df4912ea70d5a4c3b8489f026766dad709471e05a');
INSERT INTO blocks VALUES(310442,'50844c48722edb7681c5d0095c524113415106691e71db34acc44dbc6462bfec',310442000,NULL,NULL,'a3728bacfbdd289b7af24248b9bdacd5643bd5412bb993f5380278631eabb9e9','4ce5b5e387775c726eb270051ba3d9aa04de5a9192bae0e0b2d58c85bbc31ffd','413859f783f7e9727a844c5205b944bee7b4e420f7417d7e9cb05eeed0585700');
INSERT INTO blocks VALUES(310443,'edc940455632270b7deda409a3489b19b147be89c4d8f434c284e326b749c79a',310443000,NULL,NULL,'d829da764f6397b22a6b97ef396b363ef2cf071990df2dc9c0d03806db6a46b5','2469f62b60a06221d180955ec8de95fd024c6841edead8814b0791d86a170f33','746ff4d1cc286d7f707c576cc40fd556fbb38ad3948b7c61dff2fd13758da8fd');
INSERT INTO blocks VALUES(310444,'68c9efab28e78e0ef8d316239612f918408ce66be09e8c03428049a6ee3d32e4',310444000,NULL,NULL,'ef53249bf0f13e1f2073b815c8d8da3ab744b6d277b29ddbc0bd68bd006af34b','6a9893c9853db945cd2a54bfa2220a26c5d47a0a5b7b7625626d07c4fbf07305','99585f09e9bcd7b5d969dcbeb7f3b58258f2e2fcf1b470d87690de2346b31c83');
INSERT INTO blocks VALUES(310445,'22a2e3896f1c56aefb2d27032a234ea38d93edf2b6331e72e7b4e3952f0234ef',310445000,NULL,NULL,'7e731cda90932b2b4844abdbc3ff60683173104e6c72ed81c65d9a17fd4872dc','3791d19b786372e99e843a64cea73c347693c9cc43d189b4dcdf8696ef8a7a74','87a69ff53bd04bb834eba8807933a31933616a50e1d18e5605e93b06b9bfda79');
INSERT INTO blocks VALUES(310446,'e8b0856eff3efce5f5114d6378a4e5c9e69e972825bc55cc00c26954cd1c8837',310446000,NULL,NULL,'db55bac8025e95a567ba984f36dcb09357aa3e9b8706bb594e669b628d4e7204','9794bfbe4e87fd7c5ca20643a63c5ddf8ab02589a6b02c363712ded35aa63c19','6e0454ee0801dc86373629f4fc087c12638ba62490fec3042a678b32e0e6b57b');
INSERT INTO blocks VALUES(310447,'3f4bc894c0bc04ee24ed1e34849af9f719f55df50c8bc36dc059ec5fa0e1c8a8',310447000,NULL,NULL,'5cc4fa447cc291ffcce7be3c4f8fc70041bf8af5c2dd591136d4a449095d2570','a92b78fe89c4dcc3fb6a3f237613b9bf107cdac0806f803be02ae7ce09cefcaf','fa17d0421b12fec316bac14e662d39ccae9d7e92e8794a6d89e95994f56d117f');
INSERT INTO blocks VALUES(310448,'6a6c7c07ba5b579abd81a7e888bd36fc0e02a2bcfb69dbfa061b1b64bfa1bd10',310448000,NULL,NULL,'ce49854f4493c163bc891888f920fbc6dd8855c30870beb757df69b33de52633','55029c9c957499ecded788d5be49ca498ca932891aab365f992a36317dc658b8','a336df80b73368b66166759f44c0fcc6020fe95a0f8bcf4dd811bdc42287e178');
INSERT INTO blocks VALUES(310449,'9e256a436ff8dae9ff77ed4cac4c3bfbbf026681548265a1b62c771d9d8e0779',310449000,NULL,NULL,'84557595cf2067a95924119b8ed5fea114acd9ca1b0df4dbe4ae5181a739b5d1','9c89b6a9d31edaf6443e20ad8778575c75322b3eace427f62c5943d892e3c1ca','b5edfb94c5caf9faa037a209487ce42479a97061bc9589d596fa2a5cb95b9eb6');
INSERT INTO blocks VALUES(310450,'2d9b2ccc3ad3a32910295d7f7f0d0e671b074494adc373fc49aa874d575e36a3',310450000,NULL,NULL,'0e3b252b73fb652f904780da9fc59d1081d712337a9b15cf1a56ea72fbe96c73','f6066b795d0e3dcbed6141169c3f7627c8773e2b444fb9bb6564c56139f9def1','2c54faf8490940f9286c143e065e368cf484bfe99a1bdcd7b4cd481ff8bfed2a');
INSERT INTO blocks VALUES(310451,'55731a82b9b28b1aa82445a9e351c9df3a58420f1c2f6b1c9db1874483277296',310451000,NULL,NULL,'790eccd04e24e5f10f843d63bbdc1538cf1aabb0e8e6c862104be0ef845f603f','2775b868e04a44a5f4d7b85df39a36bdb6f512442882d340caa280b50742d1f4','6255a353d31d30828436f3dfd34094b154d9be24e09f07a4fd533ea8129f21d6');
INSERT INTO blocks VALUES(310452,'016abbaa1163348d8b6bc497cc487880d469f9300374a72ecb793a03d64572aa',310452000,NULL,NULL,'30962129b060b63050fe8f249592587d74cdabc4ebb5680230a280da880c8586','d2ea7ae3238ca82862ed3a8e839e041955157a5629e26ed145d8c7608c03e424','3a733f72594133ffb1eb46cd8deae7efbd0eaba2bc96bfdf64a75aea0e3157cc');
INSERT INTO blocks VALUES(310453,'610be2f49623d3fe8c86eacf3620347ed1dc53194bf01e77393b83541ba5d776',310453000,NULL,NULL,'56f4aa1086d8985a00cc295cf9618d976e69ba426b0c3d103bea6b47b58e4355','ca605933771ad886761ea826a9265a8783877967e24ebe25a79f8659d4604fc5','52d53ef0f37156db2e5e3fc11caab09029c5bf6037a8cec23b78dfcf18fc142a');
INSERT INTO blocks VALUES(310454,'baea6ad71f16d05b37bb30ca881c73bc48fd931f4bf3ac908a28d7681e976ee9',310454000,NULL,NULL,'38d14a206003b812cbaf5f200235dbe12aa6a674e5f3379cb186a781cb5a5654','435deec1f48e8091019224d553091beac9cde9e6daaa653a21741e5c14e3a572','df989b51acfeeb983b4e6293da9c1ca0d5f341e688960fea82fc58f35a923fb1');
INSERT INTO blocks VALUES(310455,'31a375541362b0037245816d50628b0428a28255ff6eddd3dd92ef0262a0a744',310455000,NULL,NULL,'b2ff303a67c05bc12fcdfdb774ea4ddc690434c3371428b3416d38105f265f28','df5571e3a323a80468d2507e2f9a7e061d48e1ad10b41bcb5ac4fb89b2ddb7b5','a6d21c608406a410ab5167caf3bb46b5c327c20a2598872b86873dc30e365007');
INSERT INTO blocks VALUES(310456,'5fee45c5019669a46a049142c0c4b6cf382e06127211e822f5f6f7320b6b50fa',310456000,NULL,NULL,'6cc16b442fd7758ed7bae9f50367fa60debdb5d81bffc5abccda044573aeaf15','42c717aa271ed07c28e8d1fb5502689e53c77348527cb160a7c8bf36bf1e4541','f52382eb7004c7f566dcb2a80860ac1eebc80103c28b071278ebf1a6b8c75a9f');
INSERT INTO blocks VALUES(310457,'9ce5a2673739be824552754ce60fd5098cf954729bb18be1078395f0c437cce9',310457000,NULL,NULL,'8fa0401d245b1b1e8b40760a54f331564d8597e242462ec412878e36a9b06800','78e976a93fcaebe304a99823d7f56ccd35b305c426eeee9f89ef6c37f36bc95b','0f2e9232d22cc417ee55a04474395e7d7d040132d5c915eb1d053e182b138522');
INSERT INTO blocks VALUES(310458,'deca40ba154ebc8c6268668b69a447e35ad292db4504d196e8a91abdc5312aac',310458000,NULL,NULL,'520f92700e31b8a35260a280ae11bf8668b0e09d34795a9d88678f2977e19f7c','9efde60c1de6829b08c6dd1ed22b3772cdaaad133695b6288bbd88e603914179','c26d769bf9ab8b91df23f6082fc5cf5ceee53d69af91a7d84e848162cf314c51');
INSERT INTO blocks VALUES(310459,'839c15fa5eea10c91851e160a73a6a8ee273a31ab5385fe5bd71920cbc08b565',310459000,NULL,NULL,'d7f728b78228a914b8767a6caeaf2267e9dbd50490a27f6c23bd96060eab8ee0','f316b8df521e3d99a0155676da10f22ee0693638987938203b583ee4e09f7a65','a5a3bd88b44675f47aa1705a4f311c18f9d2b2165b5215f51ea1173fdd32d351');
INSERT INTO blocks VALUES(310460,'9b5f351a5c85aaaa737b6a55f20ebf04cafdf36013cdee73c4aaac376ad4562b',310460000,NULL,NULL,'33c2b4c6d22888448a2458ff2ce6a1cfae5e858acae2a57e4cc0232980f8fa4a','54c04c407e35921e4187449898fb0f16f06d994cbfe5bda52de9a14b617c6fbc','b4b79889fd3160b1431fb7f5a349b307417978f7f8675c80e4dd1e628d44da07');
INSERT INTO blocks VALUES(310461,'8131c823f11c22066362517f8c80d93bfc4c3b0a12890bdd51a0e5a043d26b7b',310461000,NULL,NULL,'22426912d3317922912326da552af284677c9b76b6416b6c056668f27ae4f19f','113fd87450c6cbf2d09d1be24f4977e75d7bccb2a97ddac22bfc96f1519a3004','807e0c00ef1f82882222eae619ea3ba7e75974655e54248bb1a1fbf03f543267');
INSERT INTO blocks VALUES(310462,'16f8fad8c21560b9d7f88c3b22293192c24f5264c964d2de303a0c742c27d146',310462000,NULL,NULL,'74225b62e696aaeafbd4d6db40b41081c7493d9cc44984729d8619ff9450ce32','da1470a347e29dac9b817636441a316f307879a4691c566ea65573fe5afd9102','cac1f65b6825c2c404e51ad2e9fadc05959167fe307a52825c0e3410a2aaf87e');
INSERT INTO blocks VALUES(310463,'bf919937d8d1b5d5f421b9f59e5893ecb9e77861c6ab6ffe6d2722f52483bd94',310463000,NULL,NULL,'b970979bfe0d44ae2f21f7d98bdcc4ae37287b93cad9fa51f32a62337ceba0c1','eec2943fecca426033e41929c8eba01b3578e9678fe9580e60a36c1bc3a68f84','ecd2bc297c66b0a442ef0de29ab2049f613fe099e639c42cd251440f4aeba45f');
INSERT INTO blocks VALUES(310464,'91f08dec994751a6057753945249e9c11964b98b654704e585d9239462bc6f60',310464000,NULL,NULL,'00007a158b003fcca20c9fcaa8d73a556f0206bc9a7ab3e5c566ea1bda8648cb','a2d52f28e9736310150dfe4ffa1de76982d6ae53b13219ab6dd63b7d61aee8e2','b316cc77dc508c8187e44d9904a96d039d7d57786ab6ba469f15948864c65b61');
INSERT INTO blocks VALUES(310465,'5686aaff2718a688b9a69411e237912869699f756c3eb7bf7c3cf2b9e3756b3d',310465000,NULL,NULL,'09c407870b056db90148a9e4cb8ada003898ff28c584bec6a5be90514758a851','6f697514367c7db6c79bb38c6ebc9c75391a105ef2a549ca26bfa791d6d75ea0','454947ff727b0ad198a206cf883906a98cde006e8273c8ef29b965d1a428e950');
INSERT INTO blocks VALUES(310466,'8a68637850c014116da671bb544fb5deddda7682223055a58bdcf7b2e79501fc',310466000,NULL,NULL,'23bcfdbb44d8fc2ae6a86ea073ab080158014f04516b256a70d846399e7383cd','2ab1ee84837b0168059b0f15ec0c53d6936daa4af908316677d91e1ac92f0245','654d2afe7edbcfe164dc4d4362c452802e5665ab3e32287997337dc4862a1a1b');
INSERT INTO blocks VALUES(310467,'d455a803e714bb6bd9e582edc34e624e7e3d80ee6c7b42f7207d763fff5c2bd3',310467000,NULL,NULL,'a43abeddb61ad99d57f208cb0c6cc3e0b05a200009e6d90641a2bc7aac707adf','bbb745a74368cbbb197cc4e014b58c11ff3753c6fdc4a347ca3d09afadacbab0','f2cf06bca7c41faf6ddc31d2d781b50f365808f3fe124349ecae0d6b9802e065');
INSERT INTO blocks VALUES(310468,'d84dfd2fcf6d8005aeeac01e03b287af788c81955612375510e37a4ab5766891',310468000,NULL,NULL,'fc909facd6ba38fa0908fd49a6e2f25bd8284de5265ef761497b8a2d595344b3','856cb39b89535d6409b2e95efc30606b54f9097cfaf3de3899b937792859e911','947c9e48d1441d177adb8c58978cfbb0ba9b24f8c5db01603b2a2912c2735f90');
INSERT INTO blocks VALUES(310469,'2fbbf2724f537d539b675acb6a479e530c7aac5f93b4045f4356ea4b0f8a8755',310469000,NULL,NULL,'09f0d1c9bde8cdd63544fbb5eab46c2954654d32f3736f9975cf860588aa65cf','4a0385bea6a64441bf0cdf873a256c9d0c81ed168921b8f557ba42ddb717fc2f','85d7e8d57c66094c882cac8f9df6c158b08ccdb5f5ffc9532ec2e7d724777466');
INSERT INTO blocks VALUES(310470,'ebb7c8e3fbe0b123a456d753b85b8c123ca3b315da14a00379ebd34784b28921',310470000,NULL,NULL,'41832b12459e778621b8f576e597b9f639390338605b30e5be28423b016b199a','d19e14fe6eedddb69a9fb12ef1decf59ed9af236e864e1149ca629d5e9efa6c0','84b321e4e3968a082eedbb79f47726ac223606dc1e4651c9179faeef007c9d89');
INSERT INTO blocks VALUES(310471,'fc6f8162c55ecffeaabb09f70f071fd0cb7a9ef1bccaafaf27fe9a936defb739',310471000,NULL,NULL,'bf701017153742cb597353349c90ec66f790f222dd98d617d98a0117f1de3274','9de099424725ade78ff256a2890f0dafe8bafe36002c3f06960bbbf3853597bd','5eb25c9c72d1c997ee201c87262d16288152fee9d515ea8873d4e607cd71a86f');
INSERT INTO blocks VALUES(310472,'57ee5dec5e95b3d9c65a21c407294a32ed538658a6910b16124f18020f16bdf7',310472000,NULL,NULL,'2a162bbd5a20f89a39156995658fd0c4715881bc130922d0edf95b60ece60b9c','6b285a619970b68a21ab77556a6d9e3cd600bb8b2fca93b72027c62b96ebe75a','f08351bce87a6f94ef278cc9844ef6cefbaba427888634d748ab2365c614d79a');
INSERT INTO blocks VALUES(310473,'33994c8f6d06134f886b47e14cb4b5af8fc0fd66e6bd60b3a71986622483e095',310473000,NULL,NULL,'1ce10996ec9e37d8ddc204f038542c6781da88d2d45bae1952a88ab993b81e88','c3c43c999494c3dbfec7cb3f5acc42cf6f958b0780aa15fc74dc2511ee4c717a','af336214162bc6b839eb7167adb0b9c9ecdbc5960c532a8837847c2cd74e9747');
INSERT INTO blocks VALUES(310474,'312ee99e9526e9c240d76e3c3d1fe4c0a21f58156a15f2789605b3e7f7794a09',310474000,NULL,NULL,'5ae424c24ca30aad5aca8298a13ae9371f55b15bc789c7731d833c6e7c7cb04e','82d23939db01e3636c6ab7c9c6f584ca3bcb0adde02c0752c95de310d63e46a1','645dc29ab43ba971453e1b22288443680010f266e89024ce6f8790b031347d47');
INSERT INTO blocks VALUES(310475,'bb9289bcd79075962117aef1161b333dbc403efebd593d93fc315146a2f040eb',310475000,NULL,NULL,'b9b257efe76a36c340629ceb265822dd10449a08eadc69667a8ea05af5c052f8','9cd0bd09a5d26d4073537905108433f8291d1dda717fb84282de462fa1500e2f','7ab319581051eb1352fc20bd63734b48c44f8f77d234091856e1a57661caeb2e');
INSERT INTO blocks VALUES(310476,'3712e1ebd195749e0dc92f32f7f451dd76f499bf16d709462309ce358a9370d0',310476000,NULL,NULL,'070c06b36f3a77c04fb4bcc3ab1045e95f198f3f970846e59c35db0d03cdaf2c','ae366fe8193cd3c629805348e5d5e06e34666174592506e50bf420be6885ea89','b51d0021e6ebfc2f74566f014984311d5ee590c5c2d8eb91d79e321c716c47df');
INSERT INTO blocks VALUES(310477,'7381973c554ac2bbdc849e8ea8c4a0ecbb46e7967d322446d0d83c3f9deab918',310477000,NULL,NULL,'4954596dd44d112fd0407c215be3c9534a348d6f708ae4a1e66527d1ac2830b1','183cd8f34601182c048a54b35fd9005e18de6c2a8bcd60ba90d2061d842b8c7b','016cf95f5ef186b54858ea4801da021894563c1b14d071d313b2f879996c12d1');
INSERT INTO blocks VALUES(310478,'c09ee871af7f2a611d43e6130aed171e301c23c5d1a29d183d40bf15898b4fa0',310478000,NULL,NULL,'d9cac2e29863569bc96aaf022437906a534968a17bf965c54bf59931cd92e590','e6c44a25aa534d92a958e71892fd17171576a0bee6906188969999d3d5f0ea2d','e963f73fa3c84d27a8d061890564ba5bc36c7c5bce4bd0ccc2c19a7fd34abf93');
INSERT INTO blocks VALUES(310479,'f3d691ce35f62df56d142160b6e2cdcba19d4995c01f802da6ce30bfe8d30030',310479000,NULL,NULL,'2e48a89a55b6f368745e1c022683e93c20bdd920011518f18fd936f2190ac5e0','4eca0ec6a908073e1f8c33d892e8710b99846e0615194a9649ff6240e038794d','8af23b95499afb3e32fdc640eff0bef799f9b1bce7d3ab106bff09b514dc4afb');
INSERT INTO blocks VALUES(310480,'2694e89a62b3abd03a38dfd318c05eb5871f1be00a6e1bf06826fd54d142e681',310480000,NULL,NULL,'aa54124d86e74bebd14ea481ac2a5a5186236ffe214747f1af11ac370565525c','573ab72a761fca920bb30b326cdafa359b25fab5d60881433db23dfe078c6e15','72499c23c9910f40c523fa9d358bef815b83bad3513357e89027517b3cd98472');
INSERT INTO blocks VALUES(310481,'db37d8f98630ebc61767736ae2c523e4e930095bf54259c01de4d36fd60b6f4a',310481000,NULL,NULL,'fbbe1266bb773e5a3f5b48e82566ff75bc74bfea9424f81f670952565db15c59','f23cc99c10d4249f7e82c2495feb2e2936af4eb7aea97320cac79bb58b4d2090','71fb1334a443cc2b9f6b3cd268d2f4d6c010d4b7ce28a64fca88e16b7370ab41');
INSERT INTO blocks VALUES(310482,'2e27db87dfb6439c006637734e876cc662d1ca74c717756f90f0e535df0787d6',310482000,NULL,NULL,'bd28a97e90054319c4c301c3e99d68aaa5e1bf5a145a8f2c4529040bb8137209','666eb4e0c4fa24ef3af9f7b17c9ac2f9ef530ba77b8a2599444c64704a26c678','e42808663dbeb7fb489d9be0ac242316fb6c63c51cbb0d412f3cdb0ab1c2ecd1');
INSERT INTO blocks VALUES(310483,'013bac61f8e33c8d8d0f60f5e6a4ec3de9b16696703dea9802f64a258601c460',310483000,NULL,NULL,'fbbeacec99c9ed99a7fc37cdd5673fe8bdce08eba7fcb25b696e262af29ca5d8','400287028df5fb8f313db35bedf95fa863f0de11f9b8386c7245613387aa3e0d','f43a6fba7b7be41943d46060d2482130af2f673d9ddcb6da5fd7f0b142945f77');
INSERT INTO blocks VALUES(310484,'7cac2b3630c31b592fa0497792bed58d3c41120c009471c348b16b5578b3aa2b',310484000,NULL,NULL,'310bc7c61c1325ee3f97e888658fd74e1fe4adccef4924abb6978150fe6f3dad','7a5198442a1005e4730c979c433914561d23e2ee572c20104b163786b14944f2','560f1904b436ef07d19d2321be9e7608697d9223f045a74241743cbed742d417');
INSERT INTO blocks VALUES(310485,'eab5febc9668cd438178496417b22da5f77ceaed5bb6e01fc0f04bef1f5b4478',310485000,NULL,NULL,'b7f66db9ea5838b65286422d0cac262f6b81bbd5a7397adf7b8d85b21354dbcd','069fd63fe9ad0e55767edb6dff81c5953732dcce30e3aa2ace62283da5b8811e','a7689d50ebe654cf0e04b6e1f57673298c8caf8570123db8debd2264b439f645');
INSERT INTO blocks VALUES(310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,NULL,NULL,'0f829769e4da773089d7b05047a499db5f6d1b17795d4fba912882caee9813e0','27246d612f84feff6e5a061d193c949af6c1437acb9e69b2272ee36152af0ecc','acd127b9760bfd4cf56445c96f206111437f463d45ddacb4de05c47320c06de9');
INSERT INTO blocks VALUES(310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,NULL,NULL,'4b4d7a79843342e96e5d9d71bbc49690245b3098be75e7b86f273021d526216d','916fda8dc753b14ba391417ff484d833248ddf45eb3198c31df06f4bfc643c67','0bcd4c3ba27b52370eebe564f3b7abb2bf7e3b659d1aec3fe72fc37183b309c0');
INSERT INTO blocks VALUES(310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,NULL,NULL,'2d7e59026ea4c8933e9c7474936931ca49d4af91f9b9985f3c76085fb3a69104','83a5940261b37c4aee43abe70e94380b0692c0828a018f6390df0d070dbfb96d','7a42ffbfed613243b4ec478f130c103e3b5752aae46c755f20c0a33762c7e345');
INSERT INTO blocks VALUES(310489,'2efdb36f986b3e3ccc6cc9b0c1c3cdcb07429fb43cbc0cc3b6c87d1b33f258b6',310489000,NULL,NULL,'716354a370f344980e98785a444b56b21188bc699e7fbd0c877b6f2fabf35efc','e5d62c71154e8a0f81a521470ff2a72696589d100f71063086220190880625c8','6ef6e3fe07dd6721997a621b6a2ddb8f461f0d89b8bdaf7f5faa13d445fad6b1');
INSERT INTO blocks VALUES(310490,'e2cb04b8a7368c95359c9d5ff33e64209200fb606de0d64b7c0f67bb1cb8d87c',310490000,NULL,NULL,'906a38f4256f50312891119c99721537992438af85421e317574ce1810e2b909','9cbde7b2c3fa85a09f1a100659a13a41db7dfb9a6d100048ff24dee837fe546a','6997a9533f8bc2b67f623288e944459711c3ed05bbeac97169e08583f7dd2184');
INSERT INTO blocks VALUES(310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,NULL,NULL,'3114d8091cfcaa9944c6fab49d51950535c4ef269877d58c372ed80b2b472ec6','77c53eb01eeb99a712bb8cc8013fed4dbc918fd3a3dad81717d07cea5d77f36a','61d1f921131c30184a631c159352732bace2366359bd8f335430d85b9503a80e');
INSERT INTO blocks VALUES(310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,NULL,NULL,'98af18583618fdeed545347c013763d068e8294405d265911cc5e1bc420bc740','5ffd5a36e3748d4a2de46184f9b7473dff9da7f461cff5eb2039e86362e1ea25','54e39ac0cee587ff52c65fcc34a6b2b78dc40b310a44b00f02a1f2343a7c8f2f');
INSERT INTO blocks VALUES(310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,NULL,NULL,'29119cd30a4733916fbfd0551506eaa16f7bb1bdfbdf8d17ac4e5bb20d1cb09c','f25deae56ede44d1ec9d4fd282c99b5a5a723230c6ab6fa4126004d5a12bd72f','ddc083f979895849be1e37a4ce77122af621a9db288eb8fd15fdeac4a609ceaa');
INSERT INTO blocks VALUES(310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,NULL,NULL,'72d71bd72263699ea9f2b097ad141be5bc394f49d8b0b0a6b2ff6a87b0ee3919','a18a699232e62a58f87c5b1d24d1753916ff3ec1b3bbb2676318f54d7305b5f8','9446af38205016d801c7ca2587d8944021eee0425c9a9eee368c4eb3c27b6675');
INSERT INTO blocks VALUES(310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,NULL,NULL,'5a7e5a36882466373d576bb5f4ccd1bc72ecaf548b9589baa803a7275a7a24cd','5f582341738669c30569b0a1e7930e128b43b897d76d3441e04a3c6b5cf5e8d3','ad4876ab119297bcc3b86b3cb9bc96c72b74842f2356aa405c4d8f6cb1d851d0');
INSERT INTO blocks VALUES(310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,NULL,NULL,'7ac6121c624b634f44695172761830926afe76bb18c4cc9195773f3a26966941','2f78db67dc720f820dd1eb2422638ae828996f893af843edff0e18c649536e18','2d5dc3d4408cc8fea56feefa35c1f0558761ed3d50c5e0ece61651266e28aea5');
INSERT INTO blocks VALUES(310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,NULL,NULL,'28c6e92b2299b9cbbb5953f8b7ff3de0fe962d15642ba27e43faa64e1935e819','2802fef5b6f878a4d82b8bdb65c41b91518aa4343c254875ed03fdb3fb9add27','b31594651e8d38353910b63503393f51945452786fef60e198fe4f2a28273f30');
INSERT INTO blocks VALUES(310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,NULL,NULL,'5fe6cdb0828379bf240fad99c68bba34e1889bbc19605ce5c297b82352264414','f5e38f106f3b01c9f9f1411ce6a6d5b6175729ff3948099ab530dcef30f07164','8493ce8a902a7a8862f40a2545e2cac6a4536f11b37437b6b541a6e829a4bdbc');
INSERT INTO blocks VALUES(310499,'1950e1a4d7fc820ed9603f6df6819c3c953c277c726340dec2a4253e261a1764',310499000,NULL,NULL,'b9fcbdafddd46fdda061f6e9f8744b426b6ca37e32b315df1098cbc7899ae9b9','362e1dca37ace8ff1153d9d0718caad5a6e4abbac810b5ae3dad26566490f8e8','78d740a346a018f1aa02da3694f8d57ef9b531e068a533f5dddf48dab1d0c60a');
INSERT INTO blocks VALUES(310500,'54aeaf47d5387964e2d51617bf3af50520a0449410e0d096cf8c2aa9dad5550b',310500000,NULL,NULL,'5ffefc7a2724be6bd697796bb82638ec913c5cbb73627153d1a13b48c7a6c02d','230349742d5a3e30b568712a54171da4f71de21d5c6fd353cdc59c6270afdc7e','42dc71a72aceaecf8874b326cf83858cac52f83fb0edc4769ff3aa6191a915cf');
INSERT INTO blocks VALUES(310501,'9d9019d15a1d878f2c39c7e3de4340a043a4a31aebb298acdf8e913284ae26ba',310501000,NULL,NULL,NULL,NULL,NULL);
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
INSERT INTO broadcasts VALUES(18,'3330c302fd75cb6b9e4d08ccc8821fee8f6f88c8a42123386941193813653c7a',310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000000,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(19,'a9d599c0f1669b071bf107f7e90f88fe692d56ca00b81e57c71a56530590e7ee',310018,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',0,NULL,NULL,NULL,1,'valid');
INSERT INTO broadcasts VALUES(103,'8da9a88357858b606f32f406e9a3f41d838178d0e1eb142f7a680fe8c4371ad8',310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000002,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(112,'510f6feb902159622d83f64eae590a4fec88989869a20caf5804c313aa5e0186',310111,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',1388000002,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(487,'096883e142a87377d3a4103f4702556e25824f1e23667aceb1690f66e1417062',310486,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',1388000000,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(489,'9b1cad827c97c463c2b39cc9d550693c438010ef85a10ee04d3db8699193e906',310488,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',1388000002,1.0,0,'options 0',0,'valid');
INSERT INTO broadcasts VALUES(490,'9a39bade308462ec65be3c8420a0f2189b1d4e947d4c7950a37176de71de4f87',310489,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',0,NULL,NULL,NULL,1,'valid');
INSERT INTO broadcasts VALUES(491,'4b233a74b9db14a8619ee8ec5558149e53ab033be31e803257f760aa9ef2f3b9',310490,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',1388000004,1.0,0,'options 1',0,'valid');
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
INSERT INTO credits VALUES(310001,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000000,'issuance','9cd12fbcb360926dfbc6fc57c2e513a149a66fd12092453c2765bc89d725d57e');
INSERT INTO credits VALUES(310002,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','NODIVISIBLE',1000,'issuance','2efe98f74b6d5963e271457253e6a1748a90992eb0531d60a615d3ccc3986b73');
INSERT INTO credits VALUES(310003,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','CALLABLE',1000,'issuance','4361d0ef173c245f3cc5053d5e2513ef9120e5e8abcdcf7c86e164becd53ceeb');
INSERT INTO credits VALUES(310004,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','LOCKED',1000,'issuance','e73d6a9873df9f2264fe2d7f2da66e3a8975bce90d9ec285e79eb47348b41fe1');
INSERT INTO credits VALUES(310007,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','DIVISIBLE',100000000,'send','95f1a544034d2814b7c484e4525891813fa9c10bb71f012f70602f99f31195ef');
INSERT INTO credits VALUES(310008,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'send','8d1e0fb12f2d7522615b11f81dcde1c58892f47e44b7f56b51f639440dbd4dbc');
INSERT INTO credits VALUES(310012,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',300000000,'send','1acf929efa6296558b1335f3cf94bd7260979c531097e2c4d0efc3d333fa5568');
INSERT INTO credits VALUES(310013,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','DIVISIBLE',1000000000,'send','62dfaed0ee983d767b9aec98cc49d716b807281e9e8e5d5cd8c5207c0d2f15dd');
INSERT INTO credits VALUES(310014,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','NODIVISIBLE',5,'send','9bb2e42d2f4ab601b7e8f50364fb1caed9dc9e8dc9071f660804f559bef875ba');
INSERT INTO credits VALUES(310015,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','NODIVISIBLE',10,'send','62172989ab319f239125b4635102e593a01cb4e7ba70a42d533ed9c61fadcca4');
INSERT INTO credits VALUES(310016,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','MAXI',9223372036854775807,'issuance','19cf9fd72fd7c1c766589c39cbba55cfd7495047d1773fa46e6b91c16ad85f93');
INSERT INTO credits VALUES(310020,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','acb20e35d26e55048ed34b3e1f4046a704c8b6d130a7d33c064cb04b24356ee0');
INSERT INTO credits VALUES(310020,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',0,'filled','acb20e35d26e55048ed34b3e1f4046a704c8b6d130a7d33c064cb04b24356ee0');
INSERT INTO credits VALUES(310102,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',9,'bet settled','8da9a88357858b606f32f406e9a3f41d838178d0e1eb142f7a680fe8c4371ad8');
INSERT INTO credits VALUES(310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',9,'bet settled','8da9a88357858b606f32f406e9a3f41d838178d0e1eb142f7a680fe8c4371ad8');
INSERT INTO credits VALUES(310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'feed fee','8da9a88357858b606f32f406e9a3f41d838178d0e1eb142f7a680fe8c4371ad8');
INSERT INTO credits VALUES(310103,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','XCP',92999138821,'burn','65d4048700fb8ae03f321be93c6669b8497f506a1f43920f96d994f43358c35b');
INSERT INTO credits VALUES(310104,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','XCP',92999130460,'burn','95332a7e3e2b04f2c10e3027327bfc31b686947fb05381e28903e3ff569bd4ff');
INSERT INTO credits VALUES(310105,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',92999122099,'burn','e062d1ebf4cb71bd22d80c949b956f5286080838a7607ccf87945b2b3abfcafa');
INSERT INTO credits VALUES(310106,'mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK','XCP',14999857,'burn','bbf0b9f6992755a3e371fb0c0b72f6828831e81c6f7ada6f95ba1104fb901ac3');
INSERT INTO credits VALUES(310108,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',46499548508,'burn','93c6d2499a0536c31c77a3db3fc9fc8456fbd0726c45b8f716af16f938727a73');
INSERT INTO credits VALUES(310109,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','PAYTOSCRIPT',1000,'issuance','ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e');
INSERT INTO credits VALUES(310110,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000,'send','f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481');
INSERT INTO credits VALUES(310113,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','LOCKEDPREV',1000,'issuance','5f66cb2a8f0a4605cf274a21daf0a61af10fdf3fdc5210e5bcf8f9f3d26b0bc9');
INSERT INTO credits VALUES(310116,'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx','XCP',92999030129,'burn','27929c4fcad307a76ea7da34dd2691084f678a22ee43ce7f3842b78730ee08f9');
INSERT INTO credits VALUES(310481,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'send','b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5');
INSERT INTO credits VALUES(310482,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'send','c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34');
INSERT INTO credits VALUES(310493,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',92995878046,'burn','c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a');
INSERT INTO credits VALUES(310494,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','DIVIDEND',100,'issuance','4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5');
INSERT INTO credits VALUES(310495,'mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','DIVIDEND',10,'send','129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc');
INSERT INTO credits VALUES(310496,'mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','XCP',92945878046,'send','1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6');
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
INSERT INTO debits VALUES(310001,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','9cd12fbcb360926dfbc6fc57c2e513a149a66fd12092453c2765bc89d725d57e');
INSERT INTO debits VALUES(310002,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','2efe98f74b6d5963e271457253e6a1748a90992eb0531d60a615d3ccc3986b73');
INSERT INTO debits VALUES(310003,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','4361d0ef173c245f3cc5053d5e2513ef9120e5e8abcdcf7c86e164becd53ceeb');
INSERT INTO debits VALUES(310004,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','e73d6a9873df9f2264fe2d7f2da66e3a8975bce90d9ec285e79eb47348b41fe1');
INSERT INTO debits VALUES(310005,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'issuance fee','1aa86ffaf6e3bafbd00660ccb794267a9e95814406394d2f1d5dbd6d2ef01579');
INSERT INTO debits VALUES(310006,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','b0240284e3e44dfcae7bd3e6ea9d8152f8424bd55659df84c866e07a3f6566f3');
INSERT INTO debits VALUES(310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000,'send','95f1a544034d2814b7c484e4525891813fa9c10bb71f012f70602f99f31195ef');
INSERT INTO debits VALUES(310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'send','8d1e0fb12f2d7522615b11f81dcde1c58892f47e44b7f56b51f639440dbd4dbc');
INSERT INTO debits VALUES(310009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','d83119298ac7c823cff97a1f9e333104696f19433e534eea64ebe0af42051391');
INSERT INTO debits VALUES(310010,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','c073532bca106afd5faa1c6fde8d6b4d9cb148a8940fc05a5ba66c7757365145');
INSERT INTO debits VALUES(310012,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',300000000,'send','1acf929efa6296558b1335f3cf94bd7260979c531097e2c4d0efc3d333fa5568');
INSERT INTO debits VALUES(310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',1000000000,'send','62dfaed0ee983d767b9aec98cc49d716b807281e9e8e5d5cd8c5207c0d2f15dd');
INSERT INTO debits VALUES(310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','NODIVISIBLE',5,'send','9bb2e42d2f4ab601b7e8f50364fb1caed9dc9e8dc9071f660804f559bef875ba');
INSERT INTO debits VALUES(310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','NODIVISIBLE',10,'send','62172989ab319f239125b4635102e593a01cb4e7ba70a42d533ed9c61fadcca4');
INSERT INTO debits VALUES(310016,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','19cf9fd72fd7c1c766589c39cbba55cfd7495047d1773fa46e6b91c16ad85f93');
INSERT INTO debits VALUES(310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',9,'bet','c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d');
INSERT INTO debits VALUES(310020,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',9,'bet','acb20e35d26e55048ed34b3e1f4046a704c8b6d130a7d33c064cb04b24356ee0');
INSERT INTO debits VALUES(310101,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',10,'bet','aac845aa4eb4232be418d70586755f7b132dc33d418da3bc96ced4f79570a305');
INSERT INTO debits VALUES(310107,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','XCP',100,'open dispenser','9834219d2825b4d85ca7ee0d75a5372d9d42ce75eb9144951fca1af5a25915ec');
INSERT INTO debits VALUES(310109,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',50000000,'issuance fee','ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e');
INSERT INTO debits VALUES(310110,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000,'send','f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481');
INSERT INTO debits VALUES(310112,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',10,'bet','d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048');
INSERT INTO debits VALUES(310113,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',50000000,'issuance fee','5f66cb2a8f0a4605cf274a21daf0a61af10fdf3fdc5210e5bcf8f9f3d26b0bc9');
INSERT INTO debits VALUES(310114,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',0,'issuance fee','74aa7471cdb1b13162e0116dd0cbcc4022cbdbdadef0ee0c5b8d63e527e666fe');
INSERT INTO debits VALUES(310115,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',0,'issuance fee','214edd39455a080e261e3c319f23d3fe5f064f48c044c0973811b6a85dd2990d');
INSERT INTO debits VALUES(310481,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'send','b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5');
INSERT INTO debits VALUES(310482,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'send','c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34');
INSERT INTO debits VALUES(310487,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','XCP',9,'bet','2447f6974033ac41c40b4598dfb73fc7479fd85bb9d01de2267b3f7842803275');
INSERT INTO debits VALUES(310491,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09');
INSERT INTO debits VALUES(310494,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',50000000,'issuance fee','4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5');
INSERT INTO debits VALUES(310495,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','DIVIDEND',10,'send','129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc');
INSERT INTO debits VALUES(310496,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',92945878046,'send','1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6');
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
                      give_remaining INTEGER,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
INSERT INTO dispensers VALUES(108,'9834219d2825b4d85ca7ee0d75a5372d9d42ce75eb9144951fca1af5a25915ec',310107,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','XCP',100,100,100,0,100);
-- Triggers and indices on  dispensers
CREATE TRIGGER _dispensers_delete BEFORE DELETE ON dispensers BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO dispensers(rowid,tx_index,tx_hash,block_index,source,asset,give_quantity,escrow_quantity,satoshirate,status,give_remaining) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.asset)||','||quote(old.give_quantity)||','||quote(old.escrow_quantity)||','||quote(old.satoshirate)||','||quote(old.status)||','||quote(old.give_remaining)||')');
                            END;
CREATE TRIGGER _dispensers_insert AFTER INSERT ON dispensers BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM dispensers WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _dispensers_update AFTER UPDATE ON dispensers BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE dispensers SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',asset='||quote(old.asset)||',give_quantity='||quote(old.give_quantity)||',escrow_quantity='||quote(old.escrow_quantity)||',satoshirate='||quote(old.satoshirate)||',status='||quote(old.status)||',give_remaining='||quote(old.give_remaining)||' WHERE rowid='||old.rowid);
                            END;

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
                              PRIMARY KEY (tx_index, msg_index),
                              FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index),
                              UNIQUE (tx_hash, msg_index));
INSERT INTO issuances VALUES(2,'9cd12fbcb360926dfbc6fc57c2e513a149a66fd12092453c2765bc89d725d57e',0,310001,'DIVISIBLE',100000000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Divisible asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(3,'2efe98f74b6d5963e271457253e6a1748a90992eb0531d60a615d3ccc3986b73',0,310002,'NODIVISIBLE',1000,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'No divisible asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(4,'4361d0ef173c245f3cc5053d5e2513ef9120e5e8abcdcf7c86e164becd53ceeb',0,310003,'CALLABLE',1000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Callable asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(5,'e73d6a9873df9f2264fe2d7f2da66e3a8975bce90d9ec285e79eb47348b41fe1',0,310004,'LOCKED',1000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Locked asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(6,'1aa86ffaf6e3bafbd00660ccb794267a9e95814406394d2f1d5dbd6d2ef01579',0,310005,'LOCKED',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Locked asset',0,1,'valid',NULL);
INSERT INTO issuances VALUES(17,'19cf9fd72fd7c1c766589c39cbba55cfd7495047d1773fa46e6b91c16ad85f93',0,310016,'MAXI',9223372036854775807,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Maximum quantity',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(110,'ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e',0,310109,'PAYTOSCRIPT',1000,0,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',0,0,0,0.0,'PSH issued asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(114,'5f66cb2a8f0a4605cf274a21daf0a61af10fdf3fdc5210e5bcf8f9f3d26b0bc9',0,310113,'LOCKEDPREV',1000,1,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',0,0,0,0.0,'Locked asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(115,'74aa7471cdb1b13162e0116dd0cbcc4022cbdbdadef0ee0c5b8d63e527e666fe',0,310114,'LOCKEDPREV',0,1,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',0,0,0,0.0,'Locked asset',0,1,'valid',NULL);
INSERT INTO issuances VALUES(116,'214edd39455a080e261e3c319f23d3fe5f064f48c044c0973811b6a85dd2990d',0,310115,'LOCKEDPREV',0,1,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',0,0,0,0.0,'changed',0,0,'valid',NULL);
INSERT INTO issuances VALUES(495,'4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5',0,310494,'DIVIDEND',100,1,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',0,0,0,0.0,'Test dividend',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(498,'076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f',0,310497,'PARENT',100000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Parent asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(499,'0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf',0,310498,'A95428956661682277',100000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Child of parent',25000000,0,'valid','PARENT.already.issued');
-- Triggers and indices on  issuances
CREATE TRIGGER _issuances_delete BEFORE DELETE ON issuances BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO issuances(rowid,tx_index,tx_hash,msg_index,block_index,asset,quantity,divisible,source,issuer,transfer,callable,call_date,call_price,description,fee_paid,locked,status,asset_longname) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.msg_index)||','||quote(old.block_index)||','||quote(old.asset)||','||quote(old.quantity)||','||quote(old.divisible)||','||quote(old.source)||','||quote(old.issuer)||','||quote(old.transfer)||','||quote(old.callable)||','||quote(old.call_date)||','||quote(old.call_price)||','||quote(old.description)||','||quote(old.fee_paid)||','||quote(old.locked)||','||quote(old.status)||','||quote(old.asset_longname)||')');
                            END;
CREATE TRIGGER _issuances_insert AFTER INSERT ON issuances BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM issuances WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _issuances_update AFTER UPDATE ON issuances BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE issuances SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',msg_index='||quote(old.msg_index)||',block_index='||quote(old.block_index)||',asset='||quote(old.asset)||',quantity='||quote(old.quantity)||',divisible='||quote(old.divisible)||',source='||quote(old.source)||',issuer='||quote(old.issuer)||',transfer='||quote(old.transfer)||',callable='||quote(old.callable)||',call_date='||quote(old.call_date)||',call_price='||quote(old.call_price)||',description='||quote(old.description)||',fee_paid='||quote(old.fee_paid)||',locked='||quote(old.locked)||',status='||quote(old.status)||',asset_longname='||quote(old.asset_longname)||' WHERE rowid='||old.rowid);
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
INSERT INTO messages VALUES(2,310001,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310001, "event": "9cd12fbcb360926dfbc6fc57c2e513a149a66fd12092453c2765bc89d725d57e", "quantity": 50000000}',0);
INSERT INTO messages VALUES(3,310001,'insert','issuances','{"asset": "DIVISIBLE", "asset_longname": null, "block_index": 310001, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Divisible asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "9cd12fbcb360926dfbc6fc57c2e513a149a66fd12092453c2765bc89d725d57e", "tx_index": 2}',0);
INSERT INTO messages VALUES(4,310001,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 310001, "event": "9cd12fbcb360926dfbc6fc57c2e513a149a66fd12092453c2765bc89d725d57e", "quantity": 100000000000}',0);
INSERT INTO messages VALUES(5,310002,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310002, "event": "2efe98f74b6d5963e271457253e6a1748a90992eb0531d60a615d3ccc3986b73", "quantity": 50000000}',0);
INSERT INTO messages VALUES(6,310002,'insert','issuances','{"asset": "NODIVISIBLE", "asset_longname": null, "block_index": 310002, "call_date": 0, "call_price": 0.0, "callable": false, "description": "No divisible asset", "divisible": false, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "2efe98f74b6d5963e271457253e6a1748a90992eb0531d60a615d3ccc3986b73", "tx_index": 3}',0);
INSERT INTO messages VALUES(7,310002,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "NODIVISIBLE", "block_index": 310002, "event": "2efe98f74b6d5963e271457253e6a1748a90992eb0531d60a615d3ccc3986b73", "quantity": 1000}',0);
INSERT INTO messages VALUES(8,310003,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310003, "event": "4361d0ef173c245f3cc5053d5e2513ef9120e5e8abcdcf7c86e164becd53ceeb", "quantity": 50000000}',0);
INSERT INTO messages VALUES(9,310003,'insert','issuances','{"asset": "CALLABLE", "asset_longname": null, "block_index": 310003, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Callable asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "4361d0ef173c245f3cc5053d5e2513ef9120e5e8abcdcf7c86e164becd53ceeb", "tx_index": 4}',0);
INSERT INTO messages VALUES(10,310003,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "CALLABLE", "block_index": 310003, "event": "4361d0ef173c245f3cc5053d5e2513ef9120e5e8abcdcf7c86e164becd53ceeb", "quantity": 1000}',0);
INSERT INTO messages VALUES(11,310004,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310004, "event": "e73d6a9873df9f2264fe2d7f2da66e3a8975bce90d9ec285e79eb47348b41fe1", "quantity": 50000000}',0);
INSERT INTO messages VALUES(12,310004,'insert','issuances','{"asset": "LOCKED", "asset_longname": null, "block_index": 310004, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Locked asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "e73d6a9873df9f2264fe2d7f2da66e3a8975bce90d9ec285e79eb47348b41fe1", "tx_index": 5}',0);
INSERT INTO messages VALUES(13,310004,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "LOCKED", "block_index": 310004, "event": "e73d6a9873df9f2264fe2d7f2da66e3a8975bce90d9ec285e79eb47348b41fe1", "quantity": 1000}',0);
INSERT INTO messages VALUES(14,310005,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310005, "event": "1aa86ffaf6e3bafbd00660ccb794267a9e95814406394d2f1d5dbd6d2ef01579", "quantity": 0}',0);
INSERT INTO messages VALUES(15,310005,'insert','issuances','{"asset": "LOCKED", "asset_longname": null, "block_index": 310005, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Locked asset", "divisible": true, "fee_paid": 0, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": true, "quantity": 0, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "1aa86ffaf6e3bafbd00660ccb794267a9e95814406394d2f1d5dbd6d2ef01579", "tx_index": 6}',0);
INSERT INTO messages VALUES(16,310006,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310006, "event": "b0240284e3e44dfcae7bd3e6ea9d8152f8424bd55659df84c866e07a3f6566f3", "quantity": 100000000}',0);
INSERT INTO messages VALUES(17,310006,'insert','orders','{"block_index": 310006, "expiration": 2000, "expire_index": 312006, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "DIVISIBLE", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "b0240284e3e44dfcae7bd3e6ea9d8152f8424bd55659df84c866e07a3f6566f3", "tx_index": 7}',0);
INSERT INTO messages VALUES(18,310007,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 310007, "event": "95f1a544034d2814b7c484e4525891813fa9c10bb71f012f70602f99f31195ef", "quantity": 100000000}',0);
INSERT INTO messages VALUES(19,310007,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "DIVISIBLE", "block_index": 310007, "event": "95f1a544034d2814b7c484e4525891813fa9c10bb71f012f70602f99f31195ef", "quantity": 100000000}',0);
INSERT INTO messages VALUES(20,310007,'insert','sends','{"asset": "DIVISIBLE", "block_index": 310007, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "95f1a544034d2814b7c484e4525891813fa9c10bb71f012f70602f99f31195ef", "tx_index": 8}',0);
INSERT INTO messages VALUES(21,310008,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310008, "event": "8d1e0fb12f2d7522615b11f81dcde1c58892f47e44b7f56b51f639440dbd4dbc", "quantity": 100000000}',0);
INSERT INTO messages VALUES(22,310008,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310008, "event": "8d1e0fb12f2d7522615b11f81dcde1c58892f47e44b7f56b51f639440dbd4dbc", "quantity": 100000000}',0);
INSERT INTO messages VALUES(23,310008,'insert','sends','{"asset": "XCP", "block_index": 310008, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "8d1e0fb12f2d7522615b11f81dcde1c58892f47e44b7f56b51f639440dbd4dbc", "tx_index": 9}',0);
INSERT INTO messages VALUES(24,310009,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310009, "event": "d83119298ac7c823cff97a1f9e333104696f19433e534eea64ebe0af42051391", "quantity": 100000000}',0);
INSERT INTO messages VALUES(25,310009,'insert','orders','{"block_index": 310009, "expiration": 2000, "expire_index": 312009, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "DIVISIBLE", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "d83119298ac7c823cff97a1f9e333104696f19433e534eea64ebe0af42051391", "tx_index": 10}',0);
INSERT INTO messages VALUES(26,310010,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310010, "event": "c073532bca106afd5faa1c6fde8d6b4d9cb148a8940fc05a5ba66c7757365145", "quantity": 100000000}',0);
INSERT INTO messages VALUES(27,310010,'insert','orders','{"block_index": 310010, "expiration": 2000, "expire_index": 312010, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 1000000, "get_remaining": 1000000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "c073532bca106afd5faa1c6fde8d6b4d9cb148a8940fc05a5ba66c7757365145", "tx_index": 11}',0);
INSERT INTO messages VALUES(28,310011,'insert','orders','{"block_index": 310011, "expiration": 2000, "expire_index": 312011, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 666667, "give_remaining": 666667, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "601cf81f77b46d4921ccd22a1156d8ca75bd7106570d9514101934e5ca644f3e", "tx_index": 12}',0);
INSERT INTO messages VALUES(29,310012,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310012, "event": "1acf929efa6296558b1335f3cf94bd7260979c531097e2c4d0efc3d333fa5568", "quantity": 300000000}',0);
INSERT INTO messages VALUES(30,310012,'insert','credits','{"action": "send", "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310012, "event": "1acf929efa6296558b1335f3cf94bd7260979c531097e2c4d0efc3d333fa5568", "quantity": 300000000}',0);
INSERT INTO messages VALUES(31,310012,'insert','sends','{"asset": "XCP", "block_index": 310012, "destination": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "quantity": 300000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "1acf929efa6296558b1335f3cf94bd7260979c531097e2c4d0efc3d333fa5568", "tx_index": 13}',0);
INSERT INTO messages VALUES(32,310013,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 310013, "event": "62dfaed0ee983d767b9aec98cc49d716b807281e9e8e5d5cd8c5207c0d2f15dd", "quantity": 1000000000}',0);
INSERT INTO messages VALUES(33,310013,'insert','credits','{"action": "send", "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "DIVISIBLE", "block_index": 310013, "event": "62dfaed0ee983d767b9aec98cc49d716b807281e9e8e5d5cd8c5207c0d2f15dd", "quantity": 1000000000}',0);
INSERT INTO messages VALUES(34,310013,'insert','sends','{"asset": "DIVISIBLE", "block_index": 310013, "destination": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "quantity": 1000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "62dfaed0ee983d767b9aec98cc49d716b807281e9e8e5d5cd8c5207c0d2f15dd", "tx_index": 14}',0);
INSERT INTO messages VALUES(35,310014,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "NODIVISIBLE", "block_index": 310014, "event": "9bb2e42d2f4ab601b7e8f50364fb1caed9dc9e8dc9071f660804f559bef875ba", "quantity": 5}',0);
INSERT INTO messages VALUES(36,310014,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "NODIVISIBLE", "block_index": 310014, "event": "9bb2e42d2f4ab601b7e8f50364fb1caed9dc9e8dc9071f660804f559bef875ba", "quantity": 5}',0);
INSERT INTO messages VALUES(37,310014,'insert','sends','{"asset": "NODIVISIBLE", "block_index": 310014, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 5, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "9bb2e42d2f4ab601b7e8f50364fb1caed9dc9e8dc9071f660804f559bef875ba", "tx_index": 15}',0);
INSERT INTO messages VALUES(38,310015,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "NODIVISIBLE", "block_index": 310015, "event": "62172989ab319f239125b4635102e593a01cb4e7ba70a42d533ed9c61fadcca4", "quantity": 10}',0);
INSERT INTO messages VALUES(39,310015,'insert','credits','{"action": "send", "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "NODIVISIBLE", "block_index": 310015, "event": "62172989ab319f239125b4635102e593a01cb4e7ba70a42d533ed9c61fadcca4", "quantity": 10}',0);
INSERT INTO messages VALUES(40,310015,'insert','sends','{"asset": "NODIVISIBLE", "block_index": 310015, "destination": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "quantity": 10, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "62172989ab319f239125b4635102e593a01cb4e7ba70a42d533ed9c61fadcca4", "tx_index": 16}',0);
INSERT INTO messages VALUES(41,310016,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310016, "event": "19cf9fd72fd7c1c766589c39cbba55cfd7495047d1773fa46e6b91c16ad85f93", "quantity": 50000000}',0);
INSERT INTO messages VALUES(42,310016,'insert','issuances','{"asset": "MAXI", "asset_longname": null, "block_index": 310016, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Maximum quantity", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 9223372036854775807, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "19cf9fd72fd7c1c766589c39cbba55cfd7495047d1773fa46e6b91c16ad85f93", "tx_index": 17}',0);
INSERT INTO messages VALUES(43,310016,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "MAXI", "block_index": 310016, "event": "19cf9fd72fd7c1c766589c39cbba55cfd7495047d1773fa46e6b91c16ad85f93", "quantity": 9223372036854775807}',0);
INSERT INTO messages VALUES(44,310017,'insert','broadcasts','{"block_index": 310017, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "3330c302fd75cb6b9e4d08ccc8821fee8f6f88c8a42123386941193813653c7a", "tx_index": 18, "value": 1.0}',0);
INSERT INTO messages VALUES(45,310018,'insert','broadcasts','{"block_index": 310018, "fee_fraction_int": null, "locked": true, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "text": null, "timestamp": 0, "tx_hash": "a9d599c0f1669b071bf107f7e90f88fe692d56ca00b81e57c71a56530590e7ee", "tx_index": 19, "value": null}',0);
INSERT INTO messages VALUES(46,310019,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310019, "event": "c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d", "quantity": 9}',0);
INSERT INTO messages VALUES(47,310019,'insert','bets','{"bet_type": 1, "block_index": 310019, "counterwager_quantity": 9, "counterwager_remaining": 9, "deadline": 1388000001, "expiration": 100, "expire_index": 310119, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d", "tx_index": 20, "wager_quantity": 9, "wager_remaining": 9}',0);
INSERT INTO messages VALUES(48,310020,'insert','debits','{"action": "bet", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310020, "event": "acb20e35d26e55048ed34b3e1f4046a704c8b6d130a7d33c064cb04b24356ee0", "quantity": 9}',0);
INSERT INTO messages VALUES(49,310020,'insert','bets','{"bet_type": 0, "block_index": 310020, "counterwager_quantity": 9, "counterwager_remaining": 9, "deadline": 1388000001, "expiration": 100, "expire_index": 310120, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "target_value": 0.0, "tx_hash": "acb20e35d26e55048ed34b3e1f4046a704c8b6d130a7d33c064cb04b24356ee0", "tx_index": 21, "wager_quantity": 9, "wager_remaining": 9}',0);
INSERT INTO messages VALUES(50,310020,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310020, "event": "acb20e35d26e55048ed34b3e1f4046a704c8b6d130a7d33c064cb04b24356ee0", "quantity": 0}',0);
INSERT INTO messages VALUES(51,310020,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(52,310020,'insert','credits','{"action": "filled", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310020, "event": "acb20e35d26e55048ed34b3e1f4046a704c8b6d130a7d33c064cb04b24356ee0", "quantity": 0}',0);
INSERT INTO messages VALUES(53,310020,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "acb20e35d26e55048ed34b3e1f4046a704c8b6d130a7d33c064cb04b24356ee0", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(54,310020,'insert','bet_matches','{"backward_quantity": 9, "block_index": 310020, "deadline": 1388000001, "fee_fraction_int": 5000000, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 9, "id": "c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d_acb20e35d26e55048ed34b3e1f4046a704c8b6d130a7d33c064cb04b24356ee0", "initial_value": 1.0, "leverage": 5040, "match_expire_index": 310119, "status": "pending", "target_value": 0.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 1, "tx0_block_index": 310019, "tx0_expiration": 100, "tx0_hash": "c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d", "tx0_index": 20, "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_bet_type": 0, "tx1_block_index": 310020, "tx1_expiration": 100, "tx1_hash": "acb20e35d26e55048ed34b3e1f4046a704c8b6d130a7d33c064cb04b24356ee0", "tx1_index": 21}',0);
INSERT INTO messages VALUES(55,310101,'insert','debits','{"action": "bet", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310101, "event": "aac845aa4eb4232be418d70586755f7b132dc33d418da3bc96ced4f79570a305", "quantity": 10}',0);
INSERT INTO messages VALUES(56,310101,'insert','bets','{"bet_type": 3, "block_index": 310101, "counterwager_quantity": 10, "counterwager_remaining": 10, "deadline": 1388000200, "expiration": 1000, "expire_index": 311101, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "target_value": 0.0, "tx_hash": "aac845aa4eb4232be418d70586755f7b132dc33d418da3bc96ced4f79570a305", "tx_index": 102, "wager_quantity": 10, "wager_remaining": 10}',0);
INSERT INTO messages VALUES(57,310102,'insert','broadcasts','{"block_index": 310102, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000002, "tx_hash": "8da9a88357858b606f32f406e9a3f41d838178d0e1eb142f7a680fe8c4371ad8", "tx_index": 103, "value": 1.0}',0);
INSERT INTO messages VALUES(58,310102,'insert','credits','{"action": "bet settled", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310102, "event": "8da9a88357858b606f32f406e9a3f41d838178d0e1eb142f7a680fe8c4371ad8", "quantity": 9}',0);
INSERT INTO messages VALUES(59,310102,'insert','credits','{"action": "bet settled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310102, "event": "8da9a88357858b606f32f406e9a3f41d838178d0e1eb142f7a680fe8c4371ad8", "quantity": 9}',0);
INSERT INTO messages VALUES(60,310102,'insert','credits','{"action": "feed fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310102, "event": "8da9a88357858b606f32f406e9a3f41d838178d0e1eb142f7a680fe8c4371ad8", "quantity": 0}',0);
INSERT INTO messages VALUES(61,310102,'insert','bet_match_resolutions','{"bear_credit": 9, "bet_match_id": "c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d_acb20e35d26e55048ed34b3e1f4046a704c8b6d130a7d33c064cb04b24356ee0", "bet_match_type_id": 1, "block_index": 310102, "bull_credit": 9, "escrow_less_fee": null, "fee": 0, "settled": true, "winner": null}',0);
INSERT INTO messages VALUES(62,310102,'update','bet_matches','{"bet_match_id": "c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d_acb20e35d26e55048ed34b3e1f4046a704c8b6d130a7d33c064cb04b24356ee0", "status": "settled"}',0);
INSERT INTO messages VALUES(63,310103,'insert','credits','{"action": "burn", "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "asset": "XCP", "block_index": 310103, "event": "65d4048700fb8ae03f321be93c6669b8497f506a1f43920f96d994f43358c35b", "quantity": 92999138821}',0);
INSERT INTO messages VALUES(64,310103,'insert','burns','{"block_index": 310103, "burned": 62000000, "earned": 92999138821, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "tx_hash": "65d4048700fb8ae03f321be93c6669b8497f506a1f43920f96d994f43358c35b", "tx_index": 104}',0);
INSERT INTO messages VALUES(65,310104,'insert','credits','{"action": "burn", "address": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b", "asset": "XCP", "block_index": 310104, "event": "95332a7e3e2b04f2c10e3027327bfc31b686947fb05381e28903e3ff569bd4ff", "quantity": 92999130460}',0);
INSERT INTO messages VALUES(66,310104,'insert','burns','{"block_index": 310104, "burned": 62000000, "earned": 92999130460, "source": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b", "status": "valid", "tx_hash": "95332a7e3e2b04f2c10e3027327bfc31b686947fb05381e28903e3ff569bd4ff", "tx_index": 105}',0);
INSERT INTO messages VALUES(67,310105,'insert','credits','{"action": "burn", "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "asset": "XCP", "block_index": 310105, "event": "e062d1ebf4cb71bd22d80c949b956f5286080838a7607ccf87945b2b3abfcafa", "quantity": 92999122099}',0);
INSERT INTO messages VALUES(68,310105,'insert','burns','{"block_index": 310105, "burned": 62000000, "earned": 92999122099, "source": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "status": "valid", "tx_hash": "e062d1ebf4cb71bd22d80c949b956f5286080838a7607ccf87945b2b3abfcafa", "tx_index": 106}',0);
INSERT INTO messages VALUES(69,310106,'insert','credits','{"action": "burn", "address": "mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK", "asset": "XCP", "block_index": 310106, "event": "bbf0b9f6992755a3e371fb0c0b72f6828831e81c6f7ada6f95ba1104fb901ac3", "quantity": 14999857}',0);
INSERT INTO messages VALUES(70,310106,'insert','burns','{"block_index": 310106, "burned": 10000, "earned": 14999857, "source": "mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK", "status": "valid", "tx_hash": "bbf0b9f6992755a3e371fb0c0b72f6828831e81c6f7ada6f95ba1104fb901ac3", "tx_index": 107}',0);
INSERT INTO messages VALUES(71,310107,'insert','debits','{"action": "open dispenser", "address": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b", "asset": "XCP", "block_index": 310107, "event": "9834219d2825b4d85ca7ee0d75a5372d9d42ce75eb9144951fca1af5a25915ec", "quantity": 100}',0);
INSERT INTO messages VALUES(72,310107,'insert','dispensers','{"asset": "XCP", "block_index": 310107, "escrow_quantity": 100, "give_quantity": 100, "give_remaining": 100, "satoshirate": 100, "source": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b", "status": 0, "tx_hash": "9834219d2825b4d85ca7ee0d75a5372d9d42ce75eb9144951fca1af5a25915ec", "tx_index": 108}',0);
INSERT INTO messages VALUES(73,310108,'insert','credits','{"action": "burn", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "XCP", "block_index": 310108, "event": "93c6d2499a0536c31c77a3db3fc9fc8456fbd0726c45b8f716af16f938727a73", "quantity": 46499548508}',0);
INSERT INTO messages VALUES(74,310108,'insert','burns','{"block_index": 310108, "burned": 31000000, "earned": 46499548508, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "valid", "tx_hash": "93c6d2499a0536c31c77a3db3fc9fc8456fbd0726c45b8f716af16f938727a73", "tx_index": 109}',0);
INSERT INTO messages VALUES(75,310109,'insert','debits','{"action": "issuance fee", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "XCP", "block_index": 310109, "event": "ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e", "quantity": 50000000}',0);
INSERT INTO messages VALUES(76,310109,'insert','issuances','{"asset": "PAYTOSCRIPT", "asset_longname": null, "block_index": 310109, "call_date": 0, "call_price": 0.0, "callable": false, "description": "PSH issued asset", "divisible": false, "fee_paid": 50000000, "issuer": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "locked": false, "quantity": 1000, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "valid", "transfer": false, "tx_hash": "ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e", "tx_index": 110}',0);
INSERT INTO messages VALUES(77,310109,'insert','credits','{"action": "issuance", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "PAYTOSCRIPT", "block_index": 310109, "event": "ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e", "quantity": 1000}',0);
INSERT INTO messages VALUES(78,310110,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 310110, "event": "f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481", "quantity": 100000000}',0);
INSERT INTO messages VALUES(79,310110,'insert','credits','{"action": "send", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "DIVISIBLE", "block_index": 310110, "event": "f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481", "quantity": 100000000}',0);
INSERT INTO messages VALUES(80,310110,'insert','sends','{"asset": "DIVISIBLE", "block_index": 310110, "destination": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481", "tx_index": 111}',0);
INSERT INTO messages VALUES(81,310111,'insert','broadcasts','{"block_index": 310111, "fee_fraction_int": 5000000, "locked": false, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "valid", "text": "Unit Test", "timestamp": 1388000002, "tx_hash": "510f6feb902159622d83f64eae590a4fec88989869a20caf5804c313aa5e0186", "tx_index": 112, "value": 1.0}',0);
INSERT INTO messages VALUES(82,310112,'insert','debits','{"action": "bet", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "XCP", "block_index": 310112, "event": "d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048", "quantity": 10}',0);
INSERT INTO messages VALUES(83,310112,'insert','bets','{"bet_type": 3, "block_index": 310112, "counterwager_quantity": 10, "counterwager_remaining": 10, "deadline": 1388000200, "expiration": 1000, "expire_index": 311112, "fee_fraction_int": 5000000.0, "feed_address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "leverage": 5040, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "open", "target_value": 0.0, "tx_hash": "d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048", "tx_index": 113, "wager_quantity": 10, "wager_remaining": 10}',0);
INSERT INTO messages VALUES(84,310113,'insert','debits','{"action": "issuance fee", "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "asset": "XCP", "block_index": 310113, "event": "5f66cb2a8f0a4605cf274a21daf0a61af10fdf3fdc5210e5bcf8f9f3d26b0bc9", "quantity": 50000000}',0);
INSERT INTO messages VALUES(85,310113,'insert','issuances','{"asset": "LOCKEDPREV", "asset_longname": null, "block_index": 310113, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Locked asset", "divisible": true, "fee_paid": 50000000, "issuer": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "locked": false, "quantity": 1000, "source": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "status": "valid", "transfer": false, "tx_hash": "5f66cb2a8f0a4605cf274a21daf0a61af10fdf3fdc5210e5bcf8f9f3d26b0bc9", "tx_index": 114}',0);
INSERT INTO messages VALUES(86,310113,'insert','credits','{"action": "issuance", "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "asset": "LOCKEDPREV", "block_index": 310113, "event": "5f66cb2a8f0a4605cf274a21daf0a61af10fdf3fdc5210e5bcf8f9f3d26b0bc9", "quantity": 1000}',0);
INSERT INTO messages VALUES(87,310114,'insert','debits','{"action": "issuance fee", "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "asset": "XCP", "block_index": 310114, "event": "74aa7471cdb1b13162e0116dd0cbcc4022cbdbdadef0ee0c5b8d63e527e666fe", "quantity": 0}',0);
INSERT INTO messages VALUES(88,310114,'insert','issuances','{"asset": "LOCKEDPREV", "asset_longname": null, "block_index": 310114, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Locked asset", "divisible": true, "fee_paid": 0, "issuer": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "locked": true, "quantity": 0, "source": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "status": "valid", "transfer": false, "tx_hash": "74aa7471cdb1b13162e0116dd0cbcc4022cbdbdadef0ee0c5b8d63e527e666fe", "tx_index": 115}',0);
INSERT INTO messages VALUES(89,310115,'insert','debits','{"action": "issuance fee", "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "asset": "XCP", "block_index": 310115, "event": "214edd39455a080e261e3c319f23d3fe5f064f48c044c0973811b6a85dd2990d", "quantity": 0}',0);
INSERT INTO messages VALUES(90,310115,'insert','issuances','{"asset": "LOCKEDPREV", "asset_longname": null, "block_index": 310115, "call_date": 0, "call_price": 0.0, "callable": false, "description": "changed", "divisible": true, "fee_paid": 0, "issuer": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "locked": false, "quantity": 0, "source": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "status": "valid", "transfer": false, "tx_hash": "214edd39455a080e261e3c319f23d3fe5f064f48c044c0973811b6a85dd2990d", "tx_index": 116}',0);
INSERT INTO messages VALUES(91,310116,'insert','credits','{"action": "burn", "address": "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx", "asset": "XCP", "block_index": 310116, "event": "27929c4fcad307a76ea7da34dd2691084f678a22ee43ce7f3842b78730ee08f9", "quantity": 92999030129}',0);
INSERT INTO messages VALUES(92,310116,'insert','burns','{"block_index": 310116, "burned": 62000000, "earned": 92999030129, "source": "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx", "status": "valid", "tx_hash": "27929c4fcad307a76ea7da34dd2691084f678a22ee43ce7f3842b78730ee08f9", "tx_index": 117}',0);
INSERT INTO messages VALUES(93,310481,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310481, "event": "b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5", "quantity": 100000000}',0);
INSERT INTO messages VALUES(94,310481,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310481, "event": "b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5", "quantity": 100000000}',0);
INSERT INTO messages VALUES(95,310481,'insert','sends','{"asset": "XCP", "block_index": 310481, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "memo": "68656c6c6f", "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5", "tx_index": 482}',0);
INSERT INTO messages VALUES(96,310482,'insert','debits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310482, "event": "c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34", "quantity": 100000000}',0);
INSERT INTO messages VALUES(97,310482,'insert','credits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310482, "event": "c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34", "quantity": 100000000}',0);
INSERT INTO messages VALUES(98,310482,'insert','sends','{"asset": "XCP", "block_index": 310482, "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "memo": "fade0001", "quantity": 100000000, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "valid", "tx_hash": "c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34", "tx_index": 483}',0);
INSERT INTO messages VALUES(99,310486,'insert','broadcasts','{"block_index": 310486, "fee_fraction_int": 5000000, "locked": false, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "096883e142a87377d3a4103f4702556e25824f1e23667aceb1690f66e1417062", "tx_index": 487, "value": 1.0}',0);
INSERT INTO messages VALUES(100,310487,'insert','debits','{"action": "bet", "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "asset": "XCP", "block_index": 310487, "event": "2447f6974033ac41c40b4598dfb73fc7479fd85bb9d01de2267b3f7842803275", "quantity": 9}',0);
INSERT INTO messages VALUES(101,310487,'insert','bets','{"bet_type": 1, "block_index": 310487, "counterwager_quantity": 9, "counterwager_remaining": 9, "deadline": 1388000001, "expiration": 100, "expire_index": 310587, "fee_fraction_int": 5000000.0, "feed_address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "leverage": 5040, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "open", "target_value": 0.0, "tx_hash": "2447f6974033ac41c40b4598dfb73fc7479fd85bb9d01de2267b3f7842803275", "tx_index": 488, "wager_quantity": 9, "wager_remaining": 9}',0);
INSERT INTO messages VALUES(102,310488,'insert','broadcasts','{"block_index": 310488, "fee_fraction_int": 0, "locked": false, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": "options 0", "timestamp": 1388000002, "tx_hash": "9b1cad827c97c463c2b39cc9d550693c438010ef85a10ee04d3db8699193e906", "tx_index": 489, "value": 1.0}',0);
INSERT INTO messages VALUES(103,310488,'insert','replace','{"address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "block_index": 310488, "options": 0}',0);
INSERT INTO messages VALUES(104,310489,'insert','broadcasts','{"block_index": 310489, "fee_fraction_int": null, "locked": true, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": null, "timestamp": 0, "tx_hash": "9a39bade308462ec65be3c8420a0f2189b1d4e947d4c7950a37176de71de4f87", "tx_index": 490, "value": null}',0);
INSERT INTO messages VALUES(105,310490,'insert','broadcasts','{"block_index": 310490, "fee_fraction_int": 0, "locked": false, "source": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "status": "valid", "text": "options 1", "timestamp": 1388000004, "tx_hash": "4b233a74b9db14a8619ee8ec5558149e53ab033be31e803257f760aa9ef2f3b9", "tx_index": 491, "value": 1.0}',0);
INSERT INTO messages VALUES(106,310490,'insert','replace','{"address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "block_index": 310490, "options": 1}',0);
INSERT INTO messages VALUES(107,310491,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310491, "event": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09", "quantity": 100000000}',0);
INSERT INTO messages VALUES(108,310491,'insert','orders','{"block_index": 310491, "expiration": 2000, "expire_index": 312491, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 800000, "get_remaining": 800000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09", "tx_index": 492}',0);
INSERT INTO messages VALUES(109,310492,'insert','orders','{"block_index": 310492, "expiration": 2000, "expire_index": 312492, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 800000, "give_remaining": 800000, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "tx_hash": "2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4", "tx_index": 493}',0);
INSERT INTO messages VALUES(110,310492,'update','orders','{"fee_provided_remaining": 6800, "fee_required_remaining": 892800, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09"}',0);
INSERT INTO messages VALUES(111,310492,'update','orders','{"fee_provided_remaining": 992800, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4"}',0);
INSERT INTO messages VALUES(112,310492,'insert','order_matches','{"backward_asset": "BTC", "backward_quantity": 800000, "block_index": 310492, "fee_paid": 7200, "forward_asset": "XCP", "forward_quantity": 100000000, "id": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09_2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4", "match_expire_index": 310512, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 310491, "tx0_expiration": 2000, "tx0_hash": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09", "tx0_index": 492, "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_block_index": 310492, "tx1_expiration": 2000, "tx1_hash": "2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4", "tx1_index": 493}',0);
INSERT INTO messages VALUES(113,310493,'insert','credits','{"action": "burn", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310493, "event": "c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a", "quantity": 92995878046}',0);
INSERT INTO messages VALUES(114,310493,'insert','burns','{"block_index": 310493, "burned": 62000000, "earned": 92995878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a", "tx_index": 494}',0);
INSERT INTO messages VALUES(115,310494,'insert','debits','{"action": "issuance fee", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310494, "event": "4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5", "quantity": 50000000}',0);
INSERT INTO messages VALUES(116,310494,'insert','issuances','{"asset": "DIVIDEND", "asset_longname": null, "block_index": 310494, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Test dividend", "divisible": true, "fee_paid": 50000000, "issuer": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "locked": false, "quantity": 100, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "transfer": false, "tx_hash": "4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5", "tx_index": 495}',0);
INSERT INTO messages VALUES(117,310494,'insert','credits','{"action": "issuance", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310494, "event": "4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5", "quantity": 100}',0);
INSERT INTO messages VALUES(118,310495,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310495, "event": "129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc", "quantity": 10}',0);
INSERT INTO messages VALUES(119,310495,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "DIVIDEND", "block_index": 310495, "event": "129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc", "quantity": 10}',0);
INSERT INTO messages VALUES(120,310495,'insert','sends','{"asset": "DIVIDEND", "block_index": 310495, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 10, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc", "tx_index": 496}',0);
INSERT INTO messages VALUES(121,310496,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310496, "event": "1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(122,310496,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "XCP", "block_index": 310496, "event": "1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(123,310496,'insert','sends','{"asset": "XCP", "block_index": 310496, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 92945878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6", "tx_index": 497}',0);
INSERT INTO messages VALUES(124,310497,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310497, "event": "076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f", "quantity": 50000000}',0);
INSERT INTO messages VALUES(125,310497,'insert','issuances','{"asset": "PARENT", "asset_longname": null, "block_index": 310497, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Parent asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f", "tx_index": 498}',0);
INSERT INTO messages VALUES(126,310497,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "PARENT", "block_index": 310497, "event": "076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f", "quantity": 100000000}',0);
INSERT INTO messages VALUES(127,310498,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310498, "event": "0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf", "quantity": 25000000}',0);
INSERT INTO messages VALUES(128,310498,'insert','issuances','{"asset": "A95428956661682277", "asset_longname": "PARENT.already.issued", "block_index": 310498, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Child of parent", "divisible": true, "fee_paid": 25000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf", "tx_index": 499}',0);
INSERT INTO messages VALUES(129,310498,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "A95428956661682277", "block_index": 310498, "event": "0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf", "quantity": 100000000}',0);
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
INSERT INTO order_matches VALUES('9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09_2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4',492,'9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',493,'2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'BTC',800000,310491,310492,310492,2000,2000,310512,7200,'pending');
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
INSERT INTO orders VALUES(7,'b0240284e3e44dfcae7bd3e6ea9d8152f8424bd55659df84c866e07a3f6566f3',310006,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,100000000,'DIVISIBLE',100000000,100000000,2000,312006,0,0,6800,6800,'open');
INSERT INTO orders VALUES(10,'d83119298ac7c823cff97a1f9e333104696f19433e534eea64ebe0af42051391',310009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,100000000,'DIVISIBLE',100000000,100000000,2000,312009,0,0,6800,6800,'open');
INSERT INTO orders VALUES(11,'c073532bca106afd5faa1c6fde8d6b4d9cb148a8940fc05a5ba66c7757365145',310010,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,100000000,'BTC',1000000,1000000,2000,312010,900000,900000,6800,6800,'open');
INSERT INTO orders VALUES(12,'601cf81f77b46d4921ccd22a1156d8ca75bd7106570d9514101934e5ca644f3e',310011,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BTC',666667,666667,'XCP',100000000,100000000,2000,312011,0,0,1000000,1000000,'open');
INSERT INTO orders VALUES(492,'9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09',310491,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,0,'BTC',800000,0,2000,312491,900000,892800,6800,6800,'open');
INSERT INTO orders VALUES(493,'2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4',310492,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BTC',800000,0,'XCP',100000000,0,2000,312492,0,0,1000000,992800,'open');
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
INSERT INTO sends VALUES(8,'95f1a544034d2814b7c484e4525891813fa9c10bb71f012f70602f99f31195ef',310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','DIVISIBLE',100000000,'valid',0,NULL);
INSERT INTO sends VALUES(9,'8d1e0fb12f2d7522615b11f81dcde1c58892f47e44b7f56b51f639440dbd4dbc',310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'valid',0,NULL);
INSERT INTO sends VALUES(13,'1acf929efa6296558b1335f3cf94bd7260979c531097e2c4d0efc3d333fa5568',310012,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',300000000,'valid',0,NULL);
INSERT INTO sends VALUES(14,'62dfaed0ee983d767b9aec98cc49d716b807281e9e8e5d5cd8c5207c0d2f15dd',310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','DIVISIBLE',1000000000,'valid',0,NULL);
INSERT INTO sends VALUES(15,'9bb2e42d2f4ab601b7e8f50364fb1caed9dc9e8dc9071f660804f559bef875ba',310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','NODIVISIBLE',5,'valid',0,NULL);
INSERT INTO sends VALUES(16,'62172989ab319f239125b4635102e593a01cb4e7ba70a42d533ed9c61fadcca4',310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','NODIVISIBLE',10,'valid',0,NULL);
INSERT INTO sends VALUES(111,'f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481',310110,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000,'valid',0,NULL);
INSERT INTO sends VALUES(482,'b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5',310481,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'valid',0,X'68656C6C6F');
INSERT INTO sends VALUES(483,'c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34',310482,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'valid',0,X'FADE0001');
INSERT INTO sends VALUES(496,'129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc',310495,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','DIVIDEND',10,'valid',0,NULL);
INSERT INTO sends VALUES(497,'1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6',310496,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','XCP',92945878046,'valid',0,NULL);
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
INSERT INTO transactions VALUES(2,'9cd12fbcb360926dfbc6fc57c2e513a149a66fd12092453c2765bc89d725d57e',310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'00000014000000A25BE34B66000000174876E800010000000000000000000F446976697369626C65206173736574',1);
INSERT INTO transactions VALUES(3,'2efe98f74b6d5963e271457253e6a1748a90992eb0531d60a615d3ccc3986b73',310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'000000140006CAD8DC7F0B6600000000000003E800000000000000000000124E6F20646976697369626C65206173736574',1);
INSERT INTO transactions VALUES(4,'4361d0ef173c245f3cc5053d5e2513ef9120e5e8abcdcf7c86e164becd53ceeb',310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001400000003C58E5C5600000000000003E8010000000000000000000E43616C6C61626C65206173736574',1);
INSERT INTO transactions VALUES(5,'e73d6a9873df9f2264fe2d7f2da66e3a8975bce90d9ec285e79eb47348b41fe1',310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001400000000082C82E300000000000003E8010000000000000000000C4C6F636B6564206173736574',1);
INSERT INTO transactions VALUES(6,'1aa86ffaf6e3bafbd00660ccb794267a9e95814406394d2f1d5dbd6d2ef01579',310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001400000000082C82E3000000000000000001000000000000000000044C4F434B',1);
INSERT INTO transactions VALUES(7,'b0240284e3e44dfcae7bd3e6ea9d8152f8424bd55659df84c866e07a3f6566f3',310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000000010000000005F5E100000000A25BE34B660000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(8,'95f1a544034d2814b7c484e4525891813fa9c10bb71f012f70602f99f31195ef',310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,7650,X'00000000000000A25BE34B660000000005F5E100',1);
INSERT INTO transactions VALUES(9,'8d1e0fb12f2d7522615b11f81dcde1c58892f47e44b7f56b51f639440dbd4dbc',310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,7650,X'0000000000000000000000010000000005F5E100',1);
INSERT INTO transactions VALUES(10,'d83119298ac7c823cff97a1f9e333104696f19433e534eea64ebe0af42051391',310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000000010000000005F5E100000000A25BE34B660000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(11,'c073532bca106afd5faa1c6fde8d6b4d9cb148a8940fc05a5ba66c7757365145',310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000000010000000005F5E100000000000000000000000000000F424007D000000000000DBBA0',1);
INSERT INTO transactions VALUES(12,'601cf81f77b46d4921ccd22a1156d8ca75bd7106570d9514101934e5ca644f3e',310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,1000000,X'0000000A000000000000000000000000000A2C2B00000000000000010000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(13,'1acf929efa6296558b1335f3cf94bd7260979c531097e2c4d0efc3d333fa5568',310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,7650,X'0000000000000000000000010000000011E1A300',1);
INSERT INTO transactions VALUES(14,'62dfaed0ee983d767b9aec98cc49d716b807281e9e8e5d5cd8c5207c0d2f15dd',310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,7650,X'00000000000000A25BE34B66000000003B9ACA00',1);
INSERT INTO transactions VALUES(15,'9bb2e42d2f4ab601b7e8f50364fb1caed9dc9e8dc9071f660804f559bef875ba',310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,7650,X'000000000006CAD8DC7F0B660000000000000005',1);
INSERT INTO transactions VALUES(16,'62172989ab319f239125b4635102e593a01cb4e7ba70a42d533ed9c61fadcca4',310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,7650,X'000000000006CAD8DC7F0B66000000000000000A',1);
INSERT INTO transactions VALUES(17,'19cf9fd72fd7c1c766589c39cbba55cfd7495047d1773fa46e6b91c16ad85f93',310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'000000140000000000033A3E7FFFFFFFFFFFFFFF01000000000000000000104D6178696D756D207175616E74697479',1);
INSERT INTO transactions VALUES(18,'3330c302fd75cb6b9e4d08ccc8821fee8f6f88c8a42123386941193813653c7a',310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001E52BB33003FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(19,'a9d599c0f1669b071bf107f7e90f88fe692d56ca00b81e57c71a56530590e7ee',310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','',0,6800,X'0000001E4CC552003FF000000000000000000000046C6F636B',1);
INSERT INTO transactions VALUES(20,'c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d',310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000152BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(21,'acb20e35d26e55048ed34b3e1f4046a704c8b6d130a7d33c064cb04b24356ee0',310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000052BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(102,'aac845aa4eb4232be418d70586755f7b132dc33d418da3bc96ced4f79570a305',310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000352BB33C8000000000000000A000000000000000A0000000000000000000013B0000003E8',1);
INSERT INTO transactions VALUES(103,'8da9a88357858b606f32f406e9a3f41d838178d0e1eb142f7a680fe8c4371ad8',310102,'11e25883fd0479b78ddb1953ef67e3c3d1ffc82bd1f9e918a75c2194f7137f99',310102000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001E52BB33023FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(104,'65d4048700fb8ae03f321be93c6669b8497f506a1f43920f96d994f43358c35b',310103,'559a208afea6dd27b8bfeb031f1bd8f57182dcab6cf55c4089a6c49fb4744f17',310103000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,-99994375,X'',1);
INSERT INTO transactions VALUES(105,'95332a7e3e2b04f2c10e3027327bfc31b686947fb05381e28903e3ff569bd4ff',310104,'55b82e631b61d22a8524981ff3b5e3ab4ad7b732b7d1a06191064334b8f2dfd2',310104000,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,-99994375,X'',1);
INSERT INTO transactions VALUES(106,'e062d1ebf4cb71bd22d80c949b956f5286080838a7607ccf87945b2b3abfcafa',310105,'1d72cdf6c4a02a5f973e6eaa53c28e9e13014b4f5bb13f91621a911b27fe936a',310105000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,-99994375,X'',1);
INSERT INTO transactions VALUES(107,'bbf0b9f6992755a3e371fb0c0b72f6828831e81c6f7ada6f95ba1104fb901ac3',310106,'9d39cbe8c8a5357fc56e5c2f95bf132382ddad14cbc8abd54e549d58248140ff',310106000,'mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK','mvCounterpartyXXXXXXXXXXXXXXW24Hef',10000,5625,X'',1);
INSERT INTO transactions VALUES(108,'9834219d2825b4d85ca7ee0d75a5372d9d42ce75eb9144951fca1af5a25915ec',310107,'51cc04005e49fa49e661946a0e147240b0e5aac174252c96481ab7ddd5487435',310107000,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','',0,6150,X'0000000C000000000000000100000000000000640000000000000064000000000000006400',1);
INSERT INTO transactions VALUES(109,'93c6d2499a0536c31c77a3db3fc9fc8456fbd0726c45b8f716af16f938727a73',310108,'8f2d3861aa42f8e75dc14a23d6046bd89feef0d81996b6e1adc2a2828fbc8b34',310108000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','mvCounterpartyXXXXXXXXXXXXXXW24Hef',31000000,5625,X'',1);
INSERT INTO transactions VALUES(110,'ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e',310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','',0,6800,X'0000001400078A8FE2E5E44100000000000003E8000000000000000000001050534820697373756564206173736574',1);
INSERT INTO transactions VALUES(111,'f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481',310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',5430,7650,X'00000000000000A25BE34B660000000005F5E100',1);
INSERT INTO transactions VALUES(112,'510f6feb902159622d83f64eae590a4fec88989869a20caf5804c313aa5e0186',310111,'fde71b9756d5ba0b6d8b230ee885af01f9c4461a55dbde8678279166a21b20ae',310111000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','',0,5975,X'0000001E52BB33023FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(113,'d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048',310112,'5b06f69bfdde1083785cf68ebc2211b464839033c30a099d3227b490bf3ab251',310112000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',5430,7124,X'00000028000352BB33C8000000000000000A000000000000000A0000000000000000000013B0000003E8',1);
INSERT INTO transactions VALUES(114,'5f66cb2a8f0a4605cf274a21daf0a61af10fdf3fdc5210e5bcf8f9f3d26b0bc9',310113,'63914cf376d3076b697b9234810dfc084ed5a885d5cd188dd5462560da25d5e7',310113000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','',0,6800,X'00000014000038FEDF6D2C6900000000000003E8010000000000000000000C4C6F636B6564206173736574',1);
INSERT INTO transactions VALUES(115,'74aa7471cdb1b13162e0116dd0cbcc4022cbdbdadef0ee0c5b8d63e527e666fe',310114,'24fc2dded4f811eff58b32cda85d90fb5773e81b9267e9a03c359bc730d82283',310114000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','',0,6800,X'00000014000038FEDF6D2C69000000000000000001000000000000000000044C4F434B',1);
INSERT INTO transactions VALUES(116,'214edd39455a080e261e3c319f23d3fe5f064f48c044c0973811b6a85dd2990d',310115,'a632d67ff5f832fe9c3c675f855f08a4969c6d78c0211e71b2a24fe04be5656a',310115000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','',0,6800,X'00000014000038FEDF6D2C69000000000000000001000000000000000000076368616E676564',1);
INSERT INTO transactions VALUES(117,'27929c4fcad307a76ea7da34dd2691084f678a22ee43ce7f3842b78730ee08f9',310116,'8495ba36b331473c4f3529681a118a4cc4fa4d51cd9b8dccb1f13e5ef841dd84',310116000,'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
INSERT INTO transactions VALUES(482,'b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5',310481,'db37d8f98630ebc61767736ae2c523e4e930095bf54259c01de4d36fd60b6f4a',310481000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6375,X'0000000200000000000000010000000005F5E1006F8D6AE8A3B381663118B4E1EFF4CFC7D0954DD6EC68656C6C6F',1);
INSERT INTO transactions VALUES(483,'c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34',310482,'2e27db87dfb6439c006637734e876cc662d1ca74c717756f90f0e535df0787d6',310482000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','',0,6350,X'0000000200000000000000010000000005F5E1006F4838D8B3588C4C7BA7C1D06F866E9B3739C63037FADE0001',1);
INSERT INTO transactions VALUES(487,'096883e142a87377d3a4103f4702556e25824f1e23667aceb1690f66e1417062',310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','',0,6800,X'0000001E52BB33003FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(488,'2447f6974033ac41c40b4598dfb73fc7479fd85bb9d01de2267b3f7842803275',310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',5430,7650,X'00000028000152BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(489,'9b1cad827c97c463c2b39cc9d550693c438010ef85a10ee04d3db8699193e906',310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','',0,6800,X'0000001E52BB33023FF000000000000000000000096F7074696F6E732030',1);
INSERT INTO transactions VALUES(490,'9a39bade308462ec65be3c8420a0f2189b1d4e947d4c7950a37176de71de4f87',310489,'2efdb36f986b3e3ccc6cc9b0c1c3cdcb07429fb43cbc0cc3b6c87d1b33f258b6',310489000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','',0,6800,X'0000001E52BB33033FF000000000000000000000046C6F636B',1);
INSERT INTO transactions VALUES(491,'4b233a74b9db14a8619ee8ec5558149e53ab033be31e803257f760aa9ef2f3b9',310490,'e2cb04b8a7368c95359c9d5ff33e64209200fb606de0d64b7c0f67bb1cb8d87c',310490000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','',0,6800,X'0000001E52BB33043FF000000000000000000000096F7074696F6E732031',1);
INSERT INTO transactions VALUES(492,'9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09',310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000000010000000005F5E100000000000000000000000000000C350007D000000000000DBBA0',1);
INSERT INTO transactions VALUES(493,'2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4',310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','',0,1000000,X'0000000A000000000000000000000000000C350000000000000000010000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(494,'c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a',310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
INSERT INTO transactions VALUES(495,'4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5',310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','',0,6800,X'00000014000000063E985FFD0000000000000064010000000000000000000D54657374206469766964656E64',1);
INSERT INTO transactions VALUES(496,'129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc',310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj',5430,7650,X'00000000000000063E985FFD000000000000000A',1);
INSERT INTO transactions VALUES(497,'1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6',310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj',5430,7650,X'00000000000000000000000100000015A4018C1E',1);
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
INSERT INTO undolog VALUES(175,'UPDATE orders SET tx_index=492,tx_hash=''9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09'',block_index=310491,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''XCP'',give_quantity=100000000,give_remaining=100000000,get_asset=''BTC'',get_quantity=800000,get_remaining=800000,expiration=2000,expire_index=312491,fee_required=900000,fee_required_remaining=900000,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(176,'UPDATE orders SET tx_index=493,tx_hash=''2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4'',block_index=310492,source=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',give_asset=''BTC'',give_quantity=800000,give_remaining=800000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=2000,expire_index=312492,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=6');
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
