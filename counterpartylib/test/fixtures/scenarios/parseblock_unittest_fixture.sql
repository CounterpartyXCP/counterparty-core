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
INSERT INTO blocks VALUES(310116,'8495ba36b331473c4f3529681a118a4cc4fa4d51cd9b8dccb1f13e5ef841dd84',310116000,NULL,NULL,'6c6845d3be70cbe9a71c33227983f695c96877aac6d3a8d6a6839760b4691d25','53f941ca4d8d8457f702497e61c2fd3e19aab7c3e768cb6c8a51a39d74fc3582','7cc61b0f3b6254953065a77ca5cee9969aee683337483a829a2a34909af530cf');
INSERT INTO blocks VALUES(310117,'978a3eac44917b82d009332797e2b6fe64c7ce313c0f15bfd9b7bb68e4f35a71',310117000,NULL,NULL,'0465a90ff545d58e69c07c204160360bcc6fba5cc60fb81d7e6e389d9ff8133e','24f91cfad2f5a23ee709fb7cd3ae9d7443aab47a464538f86be40de98a0855bf','8a6ba8b58c12b9c4e0c6c925284eb366ce3ba26afcc3f2b1845afc7331360f6a');
INSERT INTO blocks VALUES(310118,'02487d8bd4dadabd06a44fdeb67616e6830c3556ec10faad40a42416039f4723',310118000,NULL,NULL,'011ed3df8ae72a02b686e98aa8db07c973e1e12c2ac09891ba90d783ae63161f','7f7e024a6851e68129c4245039f319d12ca1fc5eaebf9ffe44a1704f63f08e4f','954ba9227b13111df77a02cd8f0119090cdd955715fd2821d7ee0ee4586f0e1a');
INSERT INTO blocks VALUES(310119,'6d6be3478c874c27f5d354c9375884089511b1aaaa3cc3421759d8e3aaeb5481',310119000,NULL,NULL,'a6620b1b6a5b1f54fe6a8076fc35f0f3ce15315e9f549f5ff3fa0f5b6094919f','69cb77ef13ab76f867e53c14eb1295d74004c9faf50e5cdf3f54d13424616397','4b971449644d22031abe12396f73b631d64a410eabfe4c53e7c3d6f9337b70c5');
INSERT INTO blocks VALUES(310120,'2bba7fd459ea76fe54d6d7faf437c31af8253438d5685e803c71484c53887deb',310120000,NULL,NULL,'e38e2aa0bf8831b90e69b40c78d4b7d41bc564527451b5f9b332bb0beb54c923','387a324a256338b0f8f6b7a9b061aeb2d35c12b9b45f244da95c028dda425fc6','887130cd1d8e99dea8c9c5c12d42db4185a58183a813ca47d1e193b19d7f2a10');
INSERT INTO blocks VALUES(310121,'9b3ea991d6c2fe58906bdc75ba6a2095dcb7f00cfdd6108ac75c938f93c94ee7',310121000,NULL,NULL,'5b988c8ad133bb5ff5ac1ee4ad0a6a4fd431247db373e43c9be2a020520f438b','01e82374cb59650b947ab227d2a7307c779d63e7a15b8eb5deae3412c5c85da8','51be990684f6f8b0a94e7fe4ecdd1945466d24521cafa188b649b3e89eafd584');
INSERT INTO blocks VALUES(310122,'d31b927c46e8f9ba2ccfb02f11a72179e08474bdd1b60dd3dcfd2e91a9ea2932',310122000,NULL,NULL,'70ddab8f1d6283ce5a054650dbcd02d7ad4ca9c35de7bed920c2f266bc092070','f3d45a3f16292292943e39ba9ae1a22cb8c864a178313f22c873eb6e71c25d6b','02fc53f9df9f861ef38a0e569486bb78d9d3b54cbb670b7ae7761c1e3ded0c17');
INSERT INTO blocks VALUES(310123,'be6d35019a923fcef1125a27387d27237755c136f4926c5eddbf150402ea2bbd',310123000,NULL,NULL,'3670feebcf979edce175ad5b296a4c88fd7fc6bdc251dda84d487b1b092e41dd','29e714eeb473ee092bd6beb3f0ea00d4efbde0746704419d09b8ba386a885e14','921327eec95f25259e28bec24edd6d56f3f5e155837efdc9b5feff7d50d12d85');
INSERT INTO blocks VALUES(310124,'0984b4a908f1a7dac9dcd94da1ee451e367cc6f3216ee8cdee15eae5d0700810',310124000,NULL,NULL,'9883fff318e7cf9021fb4cc39261840f682e8adabb934549dbae2a10d2a71de3','4586f8f958c65ddb4c50b7cead252ac78ee59d3f67c70f96790f87fa9331a613','82f7b2ac84cdc94613d0dac08fdeac0c62b93525e48ffc314f02f63d0f9a3557');
INSERT INTO blocks VALUES(310125,'cc28d39365904b2f91276d09fae040adb1bbbfd4d37d8c329fced276dc52c6a6',310125000,NULL,NULL,'1840685242f9090297d4b432e305e4a093f90faa0b673953b648fbed948f31b6','a38021f02e97a8f9314aca088237e3688ce8eeb61b5cf847dfba5e1b5a426644','671a84a8e02a60e08be5e0c52bcb72e2ad5945d53b6be44158ccdae05db126fc');
INSERT INTO blocks VALUES(310126,'c9d6c2bd3eeb87f3f1033a13de8255a56445341c920a6a0ee2fb030877106797',310126000,NULL,NULL,'1a83f417c18439cd3c6269626c44b480317290f0c27a9b9f883a01653de69272','75b0731ea6e8d5c82fa251a805a973d1a851eed3c438e8f84cf007a0dca8ff3e','85ffe0bac1f62d645047729744aece21c3e2a904983720421942489ec6db04c5');
INSERT INTO blocks VALUES(310127,'c952f369e2b3317725b4b73ba1922b84af881bd59054be94406a5d9bbb106904',310127000,NULL,NULL,'094c53dfd00b5004d074987dba90a6c9c47841d01041d0aeb61923c48315d1bb','d292bf79a12c063f2727a6e545937d368c2e4990efdf8820b50cb8c509d002d0','6d7f3140df57cf3a8603f44262a4e76784381a66f78e0d2f23c8c148ce18a853');
INSERT INTO blocks VALUES(310128,'990b0d3575caf5909286b9701ece586338067fbd35357fec7d6a54c6a6120079',310128000,NULL,NULL,'28ad1365daaadc866e79b6b1a555fa31bd804a85827d958cebb9d29511f78e19','86496db35f13dfa63906f1b1a1c0032c83adcf5af6a3c193bf07a694a4bf2d16','85a7e666a1f884c65f5d93c4c8185c7387e584681a72439545b033ceeb78f8c2');
INSERT INTO blocks VALUES(310129,'fa8a7d674a9a3e4b40053cf3b819385a71831eec2f119a0f0640c6870ca1dddc',310129000,NULL,NULL,'61587f9b5d05f8f553f0a4f580f38a140edcf7d9facb13c542865f5ec586a32c','ae15a3293381e0767035e122ee4f50bb08845374f7af564413a8612289fca5df','fd854f3c7ec5eced2f509637b3175861c881b1c28fcf82e8f0b906701069e9c2');
INSERT INTO blocks VALUES(310130,'d3046e8e8ab77a67bf0629a3bab0bea4975631d52099d2ddc9c9fa0860522721',310130000,NULL,NULL,'1ee8c39657890ac946e2aac5409147cdbf1b0004db1f00d997cf45452596f781','ab285a8415460b04e9ebe8da585e6ab661e2beb30c04287c693668a8069d266e','1000b47c8ee5722bb18a73cb02fa1a9c9b2199b2ac048d1eb843f7e2d89fa64c');
INSERT INTO blocks VALUES(310131,'d6b4357496bc2c42b58a7d1260a3615bfdb86e2ce68cd20914ef3dd3c0cdd34d',310131000,NULL,NULL,'aee45272e68725a2746582f1847582eb9808289d3deca144f8c6cb43bc4f42e6','ef2a155b16b3fd8e7d42c13b0f9b08bd3ca59a660851d24fb7ab4344a0f95c3c','bfcdaae0e945b976b9ab1926e2b87c0cd4009360b135a7de6391a5b655c7d120');
INSERT INTO blocks VALUES(310132,'1b95a691bf4abf92f0dde901e1152cc5bd87a792d4b42613655e4046a57ab818',310132000,NULL,NULL,'a3fe51c1d168ed726a78b72db61175f2abb07ea6c614b2886f3054cdd1a858fe','9285fe7042e98d00ab266cf73862cd162ed6080b87a4ad1171f3c87b7a33ff46','96e7b59264a0a039dfda53344872bd395cbf43c0eddd0457aebb67235aee57fb');
INSERT INTO blocks VALUES(310133,'1029c14051faabf90641371a82f9e2352eaa3d6b1da66737fcf447568ca4ec51',310133000,NULL,NULL,'626743e51b462163f23f22079d672379def21382fd88f9155ddd453ca3d633ef','6e963b2974427712382d74ed387480bb9e4852ad2a888ae1df6f634e252b1040','8068aa75354bc625c90ef41e5efecdd9bb60b955bd5aedab0945fc85998b2f1e');
INSERT INTO blocks VALUES(310134,'1748478069b32162affa59105257d81ef9d78aee27c626e7b24d11beb2831398',310134000,NULL,NULL,'4b6e3202cae46fa80222e3ddec001213062ab76b8848eaaf4ab73f44bd84ac55','25a3e8573f18265b2839e91730b297696e22e9b901a2a4669d061e67deb4a52a','878a7c44d345b82c63962565243e03dae1096963ad8a8c8ad994e85e3900855f');
INSERT INTO blocks VALUES(310135,'d128d3469b1a5f8fb43e64b40f8a394945d1eb2f19ccbac2603f7044a4097e4f',310135000,NULL,NULL,'e32784cedeadac39bb292da2c5eaffc983f416e0bf387978691e4c0fa5b1715a','fe709078ebae536e3ebb1cf856f9ed08a1f8243f2d7de2c2c3adcc7ba7caf0eb','1ab918877a496f81e6366fcfef2cb9dec67b70d89278c121c08707c92124c167');
INSERT INTO blocks VALUES(310136,'6ec490aaffe2c222a9d6876a18d1c3d385c742ff4c12d1334613a54042a543a5',310136000,NULL,NULL,'93c67fdabd991708d1e35dabbdf7acb4e928763eeb817b32a79cd0bdb414fd2a','9bde5e42152fa231537f680690f5bf7e9263d38183814da70bdf3fae45c07696','820907ac3ccd720020d14bf383c79644227bbcd818a41d8962b7b15c0f40ebe4');
INSERT INTO blocks VALUES(310137,'7b44f07e233498303a57e5350f366b767809f1a3426d57b1b754dc16aba76900',310137000,NULL,NULL,'8a43d01155ba47b8b1311c41d5a57112198857701c2970d0fd373da04ef4e585','24785ab64db394c445baa26ca10fb5549f63c71a1b879ca7f3bb2edb8505618a','609e38dfded7074e79c636021506f24e0475b48a0334437e5cccf617aef711c1');
INSERT INTO blocks VALUES(310138,'d2d658ccbf9baa89c32659e8b6c25b640af4b9b2f28f9d40baae840206402ab5',310138000,NULL,NULL,'4acf0244f3188f60152acc8ca30dcaeadf12e6669b15377c81b7e6dc3c8892b6','d4f4eca64cfdd2e974eb1273340c88ac7a2957aa88d34333202c46f22dce7028','47216387313cae27743ba9bb02d8cd1c22c366f3b6d025070f0945c8da8f20f2');
INSERT INTO blocks VALUES(310139,'b2c6fb61f2ae0b9d75d18fce4c52a53b1d24772b1ad66c51ca51090210527d46',310139000,NULL,NULL,'2d77bdd47ed1b3be1c2edf41473bd5eb707d06dab33717b01c4a227f9855d73d','c446f490d32f397223e314258f3de5c559c10aa2644357c71a0d1cf00f40b6c5','43761efb1dde4ed86bd63c47b520c58de271d5406f4d6cfe78631c51a7288cc5');
INSERT INTO blocks VALUES(310140,'edddddea90e07a466298219fd7f5a88975f1213289f7c434ed47152af6b68ebb',310140000,NULL,NULL,'277c0c6dd1c505dc6f9a222c737296396569d8e007c4b9a42582f108e90fa624','145abae9a672a0d0a35b365ed05b9dbc37b1d17e4cb99f6ccfaff696ec4354ff','6f86a2a9dfa3280df4a8c6fbc3642568d2dbfefcab9ee99ed720ba3d81765e1d');
INSERT INTO blocks VALUES(310141,'b5b71d2a271bd638561c56f4ffbe94d6086debaaa86bfeb02ef0d71339310709',310141000,NULL,NULL,'f5d0edff3f22b2e025c884b7c738abe641bca9110a6b9a7b90de179fd6e5d2dc','498e1840530884940fd11fd3a63ba7a26d98a925fa48a9a2804a67b235e472fb','baf6df4fbf7fb799a77371d57c613d9e3a64cb96a7e432777e0f00ed2b67f4ea');
INSERT INTO blocks VALUES(310142,'a98ae174c41ab8fc575d9c8d53d8e02d8e446b8c6c0d98a20ff234eba082b143',310142000,NULL,NULL,'a9f00ec826a30e66820ab2920cf9573244a24dacd63d48c080b9e80b1c5e05b7','085ed36646b2a1970f21ebc908930f72d32290b26f2c045b5f42a84a142f6a37','df3dee66f754965c30687a55e4cd26f46e146b251c366cd1f61510d4f3db4e6a');
INSERT INTO blocks VALUES(310143,'8ba2f7feb302a5f9ec3e8c7fc718b02379df4698f6387d00858005b8f01e062f',310143000,NULL,NULL,'b5765899f770fdb6cf1120535d85826c6b0ae44b16b8d5a619c5cd12c98783ea','484946c8e6cc08dd11d38539ceeeff00324dcd1ffcfd0ebab3afcb9efcb06080','7bc56c590b516b5bf7c1a148e9492e075b277166faa3da73b926581d17f17eb1');
INSERT INTO blocks VALUES(310144,'879ffa05ae6b24b236591c1f1537909179ed1245a27c5fdadd2218ab2193cdb9',310144000,NULL,NULL,'1a80f48136e5938b33f817a7cc1cb60aaf6d628b7811abd43e38cc807a18072a','3af3eca34001823f8d8b5a1c15b35e9e205d62d8292fe02423c0cf82e211a014','4bcab1b8ee23c736004849f157a03b02b78aab586a539fe2bbb850874db02ff7');
INSERT INTO blocks VALUES(310145,'175449ef0aa4580593ad4a7d0c5a9b117e1549ea772af00caa4ccdc9b1bf7a6e',310145000,NULL,NULL,'fce2f084c1776fcb36b3ae3e0c952893934e24672ffa0d3dac72bb1278af8264','ed1cf87796c276fec94a653e8f66b7f342ed96d3e6e5b8ae3c148dae2dd0d147','5863f3a1b3fcfd7a8cbad3f1d07f444b7f61102d8631c1dbc05ee382df44a92b');
INSERT INTO blocks VALUES(310146,'e954ab6a110455d745503f7cc8df9d92c1a800fafdd151e7b1912830a9cb7184',310146000,NULL,NULL,'9a98eb971580a0a69fceafc5fd41f398f1908b626c47df57965d1863e9a24b84','2e20c89d5cc244066c954d2aeea596c450ecb72a431f722fe800ac6b9d7b9046','e06cda8817c94177a87fec095566884d5b5eae77c44249553813a781c45d7bf5');
INSERT INTO blocks VALUES(310147,'7650c95eba7bf1cad81575ed12f32a8cc36281a6f41bef13afe1dfc1b03a7e83',310147000,NULL,NULL,'336a89d3d137810d3220d2de432f72e3b3ccd2ada2b746da3859c77dbb89d6a3','34700d34647395223b8fb6935ce9f6900ae5118d5aaf9d8ead4b3f4dc224e611','d20cbb2297665b558c713c8bae630c1103eea96b31c1b5647bb6c540fd84303b');
INSERT INTO blocks VALUES(310148,'77c29785877724be924f965215eb50ffe916e3b6b3a2beaea3e3ae4796545a7e',310148000,NULL,NULL,'f904794337dd67d356981d2623b8c3d1d78ba584cd98a8c1db939951d3102612','f8864f1370fe3749abc453d6f32723f35f13292e4f897c1b22a81449adeb79ec','15a1ae87f150ce60c610d4820e5cdd0f0fbdf5e9d362f3c1e3d6ef75954cdfeb');
INSERT INTO blocks VALUES(310149,'526b3c4a74c2663fc04ed5234c86974bffddb7235c8736d76860778c30207b3c',310149000,NULL,NULL,'c2972fbd048790f54d9ecef4e18aedec8ae7aa28227d1d43bd19cd71b4feff85','d0c253239e284380a99a6be94e21da670f1c914ca87df0d19cca364bbd8d7820','28ceab1570d22316794c347efa0cec9ce346e2902417b2e52852468ce419f2d9');
INSERT INTO blocks VALUES(310150,'cdd141f7463967dbeb78bf69dc1cd8e12489f58c4ea0a5dc9c5c01ec4fcea333',310150000,NULL,NULL,'88b999e4ae34386b826b0f3b315953b5eeda8d9ef496af051498bfce6d8737fc','4f7e0769dbd4f7d7cf58fa78f4c6b305a85f8d631927ed4f39640772afd0390c','fad5d3765fca4b71343a94f3ea91141c88667eb239d4cdbc99b32e6aac5b280a');
INSERT INTO blocks VALUES(310151,'a0f31cc6e12ec86e65e999e806ab3bfa18f4f1084e4aeb4fbd699b4fe284b330',310151000,NULL,NULL,'b7c176a2eff86655f8b0b71cc8bd3bab3a92ba203d4ccd911d63f3d2ce7fdc25','85560973fc0a9d795dce3046e65dfc3111411274d9fa37a78d380a0fcdc95739','a85053a4f1aacb84163e7abc770fbe5b421129da80d1e68c331c877b46447f48');
INSERT INTO blocks VALUES(310152,'89c8cc3a0938c63a35e89d039aa84318a0fc4e13afac6beb849ac37140132c67',310152000,NULL,NULL,'3f9471c393bc2bf144b17a5febea88c42982ae746fd700a5903c0e6e541e2b09','eb20238e6675fecbb327025997309b4b434e1501cc877a539fda104bee76cec5','943da41da949d35107a9263c714d55a04b3da7030aff1e20d8a5e7e7146bf412');
INSERT INTO blocks VALUES(310153,'d1121dfa68f4a1de4f97c123d2d2a41a102971a44b34927a78cd539ad8dca482',310153000,NULL,NULL,'c6bc81e7b7e6758bbbfe10fa0e688b09e679fb74a18134639e172c18c6e017a7','1f8a79382a549bbc06c1615c5982049ac9afa1fa12df4b060bf00f08eed326cf','659e59d215dd04486417b71a340d397aacd9167d0c9eab879838c9c4e937399e');
INSERT INTO blocks VALUES(310154,'ba982ea2e99d3bc5f574897c85485f89430ae38cf4ab49b7716ed466afa506d6',310154000,NULL,NULL,'b3e07f9de85ab67e88042b1bb52302c6eb16b7ff45d5be6a49700f115ed396d4','c5fd8bb124088937ccdd2c9725cd7e0cdd9df4b83c37c9e77745b43dc18469e4','1d682d774dbea60d893b8c98b38c86f85aea5abee5ee7b784cdc6b3cff3291cf');
INSERT INTO blocks VALUES(310155,'cefb3b87c7b75a0eb8f062a0cde8e1073774ae035d176e9769fc87071c12d137',310155000,NULL,NULL,'27014841a468e23bcb70c718919745eadcded4310031a7be90a4732c96509404','3e5e1fded0e434b4a7d20e26042fff903dab794085ed7cadd1eb7c41eff1eb99','ad7ef71408857f4d1d148ef4317a62cec45a67eb2a96778c25ecfd33dd6b89a3');
INSERT INTO blocks VALUES(310156,'6e3811e65cb02434f9fde0445a7a2b03fe796041458737d0afcc52208f988a83',310156000,NULL,NULL,'5597aaadb8cc75848219f9fde3f5d76bb5592689c72068db59922732e89eef9d','e01418c889386a09b0a703bfc0072e86662238c52667690fc53ce5be01ad46ec','3c1d27dd95252a042b62e9b11c4d4c2493df08b26a8f0f32ed6e7bc2c9388d1b');
INSERT INTO blocks VALUES(310157,'51dd192502fe797c55287b04c403cc63c087020a01c974a565dd4038db82f94a',310157000,NULL,NULL,'cc1ae27fef286424e40204f6b575e9e079e1f7a5ccf6cc356729a7c4a7f83eb8','7f65e22797670ccc2d5d5efd787459f8c74c1668b701e8257d8f75b01f40ac9f','942c4ea3cebac62b83cb0ebe69c77e0684324717958a213129db85624ce8ff0b');
INSERT INTO blocks VALUES(310158,'749395af0c3221b8652d31b4c4410c19b10404d941c7e78d765b865f853559d2',310158000,NULL,NULL,'6d80d98e778b30c124b0255b3e72620f432245d0f841f6bd62a0fcff44843bf0','12b7b80caf29bb968e9a88ba86dd0c933fdc7a6d88ce96656139669a02136d95','b08baaf07145d3ab62fa57b31e81c13bf788a2c93f062373477682c1eec07c9e');
INSERT INTO blocks VALUES(310159,'fc0e9f7b6ae99080bc41625588cef73b59c8a9f7a21d7f9f1bf96192ba631c12',310159000,NULL,NULL,'d8ab8bb14092afea6cc675d2f50891318e3169bf9dbe2d07e80c4db95f0f2033','71fb63872f028a0308939a6f9a87d3234daad5dfed38de6cd4938c32cd94e43b','18738ce923053b0831b2efc4a48cb3e3d38cc8acc3601c5d9b2d9f14d76d1754');
INSERT INTO blocks VALUES(310160,'163a82beeba44b4cb83a31764047880455a94a03e859dc050da782ed89c5fa8b',310160000,NULL,NULL,'2d76a042d062b73b7dd956d5cff0ee397f068c04eae6cf5b9522d3d55e88cee9','6815d462053cb75c76cefc4ba5ce02001b82a313b49b7cb4bef26ce189bba07a','3ec4d265c02533fea947d75028ae0c8c12f3f976a1afd1cfc3716ab402ecf9e8');
INSERT INTO blocks VALUES(310161,'609c983d412a23c693e666abdea3f672e256674bf9ee55df89b5d9777c9264d8',310161000,NULL,NULL,'beb3496742415027bcc0d59f3385809523c8783cd91a5670f2fb6fec3230e980','a76135f72bacaca95b559c4d994fec5966cd55d5b27480987a7ba104e1285448','85d2379e8781d2f5de1858a6a247b7995fd7a21b2a1de2368b3d5f06c38ccc9f');
INSERT INTO blocks VALUES(310162,'043e9645e019f0b6a019d54c5fef5eebee8ce2da1273a21283c517da126fc804',310162000,NULL,NULL,'066a2b93df863300741145cd6a4f1a9ea616bc787861cb8ab809f59d47a6fa1f','2da7634093c56f5fb824368def4c8761a6087ee9dbf9d6feef9ffa43d31df53f','7d408605f8a755f9e63d2fc1c0f5264cce62697d060db8eb07421a7b8d0c1dd4');
INSERT INTO blocks VALUES(310163,'959e0a858a81922d2edf84d1fbb49d7c7e897a8f49f70bd5b066744b77836353',310163000,NULL,NULL,'460c271269ccdd8775925b511705207baed8fc212caa7e74fc08a80be600a38a','88c1ca85d1415d33b6ce4b3f787acbfe44e373e2f3372d634c528eb0900cf9f9','e1bc8bede317d0d04cb360744b3a77b174432082163ed50f0314637a698db1c0');
INSERT INTO blocks VALUES(310164,'781b7188be61c98d864d75954cf412b2a181364cc1046de45266ccc8cdb730e2',310164000,NULL,NULL,'19a7948cd1bc4a89a427d48bb01330dadff848e2b32ec8b8abe342872850b268','311a10b28cbdc4ceb2c999ffe2246f5545765c66778a3a84bb7792152242ca16','f97857f3ccf768c89ff8c96df30417535e2c9d80ac9e16647d016e57f37ddd21');
INSERT INTO blocks VALUES(310165,'a75081e4143fa95d4aa29618fea17fc3fabd85e84059cc45c96a73473fc32599',310165000,NULL,NULL,'97f0a48a26daf011a8c7b22bb772228a0c8a920eccd011e713956100c9fbdf33','1d8f8c2a53abf1f8439d52ed02da1bcde2c211310d652e33c5a9bc779c89928a','ea6c276627b774d2668da8250acdaa2bfe03311af6c7a058cd02803417d90b2e');
INSERT INTO blocks VALUES(310166,'a440d426adaa83fa9bb7e3d4a04b4fa06e896fc2813f5966941f1ad1f28cfb41',310166000,NULL,NULL,'edbd00e1229c673f4f15b3ac7bbe020f54b5f3a61b1d158658471076a55c77b0','0445163d3d79dac879423454ff712e501e65e0d962eb68208f53c54069e19793','cb35de1fb7178eecae589019f09d2c76d6c3bd4454f6e3bcaff2a0cc6b8ae9a6');
INSERT INTO blocks VALUES(310167,'ab4293dbea81fedacca1a0d5230fe85a230afc9490d895aa6963acc216125f66',310167000,NULL,NULL,'e118e0f3aad5be73080f4d1892517e8fd2c4575589ccdfadf980edebb9a66a14','4ee008963ecf651216a3986369699659baf1431022203e0fd8e4d6bff23d20b1','183e9028521bda4f07ef7634cc771deb8bc25994dbdc7e650b68775a263c9cf8');
INSERT INTO blocks VALUES(310168,'a12b36a88c2b0ed41f1419a29cc118fae4ecd2f70003de77848bf4a9b2b72dc9',310168000,NULL,NULL,'267f48eb4e3b0925f4f472d8ce6ec57ec5039911b13a14ff2884a41a9cafd7b1','de178dde0b16fd5f22d653d1cada88e3957ec1c3c0f480e4ea0dd74bb9a0f40d','560bb54420b91079251b6628e39bb278de9ac4685f8330f6f0f174a6328a85e7');
INSERT INTO blocks VALUES(310169,'204809a85ead8ba63f981fc1db8ae95afe92015f003eaebbec166021867421f3',310169000,NULL,NULL,'df394a6f3b2a9b9dded6019dce9f3d3214db1f30019faffbdc2ce614f629b25a','e90740bb73e1011e9fbc56bba8317ef70a37a739fd0861a27c4a4d8e1d51073c','a175f476c6befb3549f1b5ae885244be7ab32aebc00f7aa352a5ad6677f7ff54');
INSERT INTO blocks VALUES(310170,'b38b0345a20a367dfe854e455e5752f63ac2d9be8de33eab264a29e87f94d119',310170000,NULL,NULL,'3081081c2ab6d8280ef721c5836d0fb7e89eb3d747a4e4522d2e22f5a6b153a2','2a477baf59262dd6b01648db05304f704decc5881508b4d7d1187649093bad77','847a87ac651a0ccde16c6d618853803f1251a91e58bbac7295fa24db449f9eab');
INSERT INTO blocks VALUES(310171,'b8ba5ae8d97900ce37dd451e8c6d8b3a0e2664bb1c103bf697355bf3b1de2d2d',310171000,NULL,NULL,'e6a4017e4f7d9da50bb3817990c3e115d5035443de8824dc01b5380a5b4c52a9','c8ff876598cb9deef0ebccedfbe1efb7b3b0dc4dbcadbcd652219ca05e79d616','972812334d557461a70309fdc6ce235bf008497776c2eeb06eeaf52b42d8af40');
INSERT INTO blocks VALUES(310172,'b17fda199c609ab4cc2d85194dd53fa51ba960212f3964a9d2fe2cfe0bb57055',310172000,NULL,NULL,'89e90622bf8363bcee5cd7ab6d48b6d06ce4cbd067f9985e35e67fc683f4c103','7b65fa645b7ed3f3308fd79cbb3b3e5f461545c04d93d867a13779fcf3c8aeac','d3257b993d7704999e369b8777f5539583d1110aa33868f0cebc57e44ecac82f');
INSERT INTO blocks VALUES(310173,'f2dcdc5ffc0aca2e71e6e0466391b388870229398a1f3c57dec646b806a65016',310173000,NULL,NULL,'35ceee6a23757fa49e7f5c34ccf0fd034731e95d564257b443ebfdee7cd294d3','89e0491ccb2a2bced802c4b0ffe6f6997fd88676d7ffaa47a0fb77bbb86410a7','acc16f9885a95ccd8f5f64f9d66f5bbc0e17dd0a7c224a59f7915db73522f255');
INSERT INTO blocks VALUES(310174,'fa6f46af9e3664353a473f6fffce56fa295e07985018bface8141b4bf7924679',310174000,NULL,NULL,'101dedf34bc0788c0589c8e2b1d7da4ec65f6eab2e3c5523c0903db685cab017','6ba098756845325a8c808f466e983db82f0451f22232cc628d603d9939813798','c0e38cd0e0f96b80b77f6cf0bac88ebaa29c96a4f84d86b98851b96f9f597d52');
INSERT INTO blocks VALUES(310175,'f71e79fe5f03c3bc7f1360febc5d8f79fc2768ce0ff1872cf27a829b49017333',310175000,NULL,NULL,'67de4a0a9e52d9ae06caf62b3412d0bf2c10a6b24716210b21212d75be75ad6c','35df620729aa6e776dce8f36da0b8b6d01458e49549648d549755208d59f32e0','2066fd2501a34059530ba499cfb48d0afaa518149f3a66aa34449ec3faed5348');
INSERT INTO blocks VALUES(310176,'67cd1d81f2998f615602346065e37f9ceb8916abb74b5762ead317d5e26453c6',310176000,NULL,NULL,'a90bd400e15727fada1a27be4a6e228bd91a15f0dbd0fb7de3b6779a8bf89e4c','c5746a65355e60db8745a0dfa0b69316977dcbe5c617985e1adc27f04494891f','dc473874c85afeee62332d04e5eb1fcd84e147bf88bb442a149d5ca1f620afc9');
INSERT INTO blocks VALUES(310177,'6856b1971121b91c907aaf7aed286648a6074f0bd1f66bd55da2b03116192a52',310177000,NULL,NULL,'bac315d07dee18e27336a46ff3ffeed58aaf8eb1eb702e98a93c06303c937716','6397f6060e1bcbc42b1d603a3a44c21a0a49e345acc6679047729a0d2b8fba5f','8412aced5830e20cdc48434bd57b70dc3a51a22be126bb3c2ad33f5ecab504ef');
INSERT INTO blocks VALUES(310178,'8094fdc6e549c4fab18c62e4a9be5583990c4167721a7e72f46eaf1e4e04d816',310178000,NULL,NULL,'186ea0ece84d21ee21889ff13c98959dfc1842063a970e0c095552f0ca86515e','0eeff7c54bb9639953df70d6ececdc38a5ce53dea8446790ffd436a8ee870d1a','b74fa876adf0f60e91ef12ddff88c313e06c825739779ab8485f4aa10a8a0c9b');
INSERT INTO blocks VALUES(310179,'d1528027cd25a1530cdc32c4eaff3751a851c947ddc748d99a7d3026a5e581a7',310179000,NULL,NULL,'0200402ef08256efa0adc85b2b4b15fb7448b5107b65fafbcc7985d809e84bc8','c579feaa38074786fa56b95cc9ae499a827855899abd02eba46f51f49932e50c','1cc9c2cc647371e777db865f4717a1a5814a386a18c0d71c0c4a888320f04d2e');
INSERT INTO blocks VALUES(310180,'f2f401a5e3141a8387aaf9799e8fef92eb0fc68370dae1e27622893406d685c1',310180000,NULL,NULL,'13829eeaf9bdc54f87366e35616c5a57cd836c63db8a9ba7d117d02377ef43e1','f58654a29b82d57abf49c4947e755a8c20a56bc78255cfdd772022a05a83b708','f7d999386d71bfdba3415ebf8522891053d5dd2a204c101957a930fe6516d860');
INSERT INTO blocks VALUES(310181,'bd59318cdba0e511487d1e4e093b146b0f362c875d35ab5251592b3d9fed7145',310181000,NULL,NULL,'81b4d83a623a55019ad720c1bd3ecef100d8ca49deda91b8ba6ffe9802764df7','62b205c0e6c70c295eec129b05e4ede26043c62544f035ea59b9370f8b57863f','da803069f0cbb2b9b37fef45f632c56fdf335cbcda9c28c5ee30e1f3daac5a7b');
INSERT INTO blocks VALUES(310182,'a7e66b4671a11af2743889a10b19d4af09ec873e2b8eb36949d710d22e1d768f',310182000,NULL,NULL,'935e40f93195d450b292481aac481f445d2de8786d04d26263f4adc5a348704c','849efd82f60124755c4574cefe6b5283d3a1091375415638c308a239fb2bb1aa','d68f439c5c0578ba10080df73212e6fdaed5ddfea34ff4ecc3ba06eb3dbe8e4d');
INSERT INTO blocks VALUES(310183,'85318afb50dc77cf9edfef4d6192f7203415e93be43f19b15ca53e170b0477bb',310183000,NULL,NULL,'268bf841be40615472bf4c60b5306d0763ed50510fbb55c47a6a0ac726e8701f','71a91921a06e1641d9c8e0f825b1ab38fe44f7824897cfdb4f9a37079c30fa18','85c42dacbb55984178bd88d94cf1ebae6c3a0393c90993348650099ff39ad006');
INSERT INTO blocks VALUES(310184,'042a898e29c2ebf0fdbb4156d29d9ba1a5935e7ed707928cb21824c76dd53bfc',310184000,NULL,NULL,'64323488ca4d32a1f548842db4ac772b750599ce6222020ef6149b4a0e54a935','f66233971aec677a35376d79e443376a36146ec0e77474fbbae99c0323579f93','8f28d5dbc9fd60deca0885b63867fc970f5cdabb20de7712a8c3eb32b2345c2c');
INSERT INTO blocks VALUES(310185,'bd78c092ae353c78798482830c007aac1be07e9bc8e52855f620a3d48f46811f',310185000,NULL,NULL,'8946baadef2e19c5e4e4b2d771b36982a217486dcb0f95097b41ce633e61da94','1071029b32fd2dfa752d336cb317db258542acbf221865a4aa82f6e54264a9ff','69529556da8e75dc9f11c71270a1daa8347aab4a93ba85893aa3b24b951c660d');
INSERT INTO blocks VALUES(310186,'e30a3a92cc2e5ad0133e5cee1f789a1a28bea620974f9ab8fa663da53e5bf707',310186000,NULL,NULL,'e68b5525927cfee15fefee02a16fd700abf6b6e7b4e32e57df7d324fae7ae090','11f78aec380adff8e63968e134c724badc3936ef339b3b23e9e6f39dcc6a0d52','d44d3aa3b72f51ac81e4b1876fa5ac9d1e1858c14c31ef4b5ec4581008b21cb6');
INSERT INTO blocks VALUES(310187,'fc6402c86b66b6e953d23ed33d149faa0988fa90aa9f7434e2863e33da2f3414',310187000,NULL,NULL,'c42efa24d48339fc341908a30c6679beeadc9f5918d8d3e62d5c4b06fec845d5','c46940d2405d957c249b538241b31831d1fe7a35b9a53a5b0baa29e54e92798b','33267899a56ab859cf5b1d42bb4609b95a9a86860b8ad3e098391032a01fc18e');
INSERT INTO blocks VALUES(310188,'85694a80e534a53d921b5d2c6b789b747aa73bf5556b91eeed2df148e2ada917',310188000,NULL,NULL,'13de1d9b569d5d2525ecfa39b1eda69f9fd474683b6e34554b1a755125e96e5d','d9ba14abc7b0cf9d3c18356def5ffd1befe9bb69901b45645c576daa144aedfc','ce9cbe3bba708d7123a42bb405d000020ac3b5a9f4c32a2ebc90a0e9e89a4f68');
INSERT INTO blocks VALUES(310189,'7c036dadf19348348edbe0abe84861f03370415ed2fec991b9374dbb0ca19a06',310189000,NULL,NULL,'582b8b3d3a226d3f6df497cb933ed5f42e1e992c0c25372ec15de424c0a33368','9a33fcd7f7628ac3fa5e91cd233460dd7bb69ab60d31260decef725a52258f32','1dda6120c4e9b8304fb509fa6e7acb2202b88ec70011b78af709a41f677e95b5');
INSERT INTO blocks VALUES(310190,'d6ef65299fb9dfc165284015ff2b23804ffef0b5c8baf6e5fa631211a2edbd8d',310190000,NULL,NULL,'d4c49d5e3aaf21e6fe1c30663d0ba93f7dc9ddb03611e3751fba9aac8d382ac4','489c64000ff4faa19bb68905aacc7ae226aded227090d98a9fdbf51d64f3b0f2','e53cd517fb04eacc62ed817a532deb45264c304774c7345f9ae0a141d968d2c1');
INSERT INTO blocks VALUES(310191,'5987ffecb8d4a70887a7ce2b7acb9a326f176cca3ccf270f6040219590329139',310191000,NULL,NULL,'23d340ff3f1979a43bd1336c9c882b5ee01c646cd104060feacdb5db78025cca','5a60d8f8eddfd6702c6eef8181ace872a230ff4ecd5dcf4c775c4a05f9322e7c','ec4b094bf99a1151537e8edc8022a6f873f4b24949325ea569a7e3367d87dd77');
INSERT INTO blocks VALUES(310192,'31b7be43784f8cc2ce7bc982d29a48ff93ef95ba18f82380881c901c50cd0caa',310192000,NULL,NULL,'cd18860851bceba4a0174480ccdc0f6ddc47b31ce71af8ec8500cb07f75d9da9','3fceebec6816068e883414f5f4748c87e34c5d87ef140b689e6d81d5c53f1cad','b674b76d3c179444530ced3eaa275262cd8308ba5bc4cf7099c942ad77ad8ee4');
INSERT INTO blocks VALUES(310193,'ff3bb9c107f3a6e138440dee2d60c65e342dfbf216e1872c7cdb45f2a4d8852a',310193000,NULL,NULL,'391e97ae7ccf5bc38ac72e7ad1256f24c28297c625bd9a789cba8231a5ade046','7c08978890d87ae62b31ddd344e239ab165315c2ffb4effa5692d527f86b96fd','b554e7cdc039bfa546335d4f0ab2f27db2c17a0d985e49fe912ff2af789c05e7');
INSERT INTO blocks VALUES(310194,'d1d8f8c242a06005f59d3c4f85983f1fa5d5edcc65eb48e7b75ed7165558434a',310194000,NULL,NULL,'9141c9b38087c7cf2b8c11ffd55c2eabcb3bb09f132ac0baf9c3779f628dd42b','0ec485426174ef5aeae55af965e610487c1f7719f60553977bdd4bc7dca4bfe7','41c04cbf8f4d4341456b4cfc0da779426a3d0bcbaad75d60b7dd0bb48d12eb32');
INSERT INTO blocks VALUES(310195,'0b2f1f57c9a7546faac835cbe43243473fa6533b6e4d8bf8d13b8e3c710faf53',310195000,NULL,NULL,'705918f002db29e7b3dfbfd6378f79d53e33c6ffa3948b2e3b5c85f85009bbde','d5cce725f7fd086c2ecc96dc3b858d416a2df2616e5533ea75c084a670eb3f93','46148626a0a7c508daacdbe0b1e88b6d356bb6f049852dec83f4dd6920f10047');
INSERT INTO blocks VALUES(310196,'280e7f4c9d1457e116b27f6fc2b806d3787002fe285826e468e07f4a0e3bd2e6',310196000,NULL,NULL,'59e12df19e3c0e3e23a5d1e9783c75e236a000774a038553312919a0f46b8227','da36f7e0c25c28c055f490117dac50ccb388fdfb72bbf19bb0d90a30893eda0e','22b5ae240b29272e6aea30641dd939540da699b03c92fb4d40d24296ad6c4f7d');
INSERT INTO blocks VALUES(310197,'68de4c7fd020395a407ef59ea267412bbd2f19b0a654f09c0dafbc7c9ada4467',310197000,NULL,NULL,'a0e1817dfc258180fa1629710ff3b6026181a9042fecd2c8b0b5e38118199e07','0e3f7e8967768cbe51ac92fb530c9979c410ca95b2ce9f1e16608811092fc394','61e802eb54f620c312913f592dbe4f80e64838446321fa2f8009cc84248c1ff3');
INSERT INTO blocks VALUES(310198,'30340d4b655879e82543773117d72017a546630ceac29f591d514f37dd5b1cc2',310198000,NULL,NULL,'ff51bfc670b1387bfce53781750e35a3bf69d907167cf9cf57e15613cc0ff3b2','8ae181c0b65b7c7ad790b94c2031fd74f2c073db27bc9ecfb7afaea7b042fea9','6a093b28b6d9444a200915b3d8f9a6fccea445460003a0bafa1c1ea53df51e52');
INSERT INTO blocks VALUES(310199,'494ebe4ce57d53dc0f51e1281f7e335c7315a6a064e982c3852b7179052a4613',310199000,NULL,NULL,'e5f8f8f00de32f0d8d2b62eba27218edcee77563960fe074da5ae86bf5b553f1','da19510dc628545b44ce55ae863d7afee276ee8f04b47764a528c5f271529b4e','f658745f3222f413c56a77398133b597927a44ee8e117d728950be3ac5216a9d');
INSERT INTO blocks VALUES(310200,'d5169d7b23c44e02a5322e91039ccc7959b558608cf164328cd63dbaf9c81a03',310200000,NULL,NULL,'fd8fb664576868d4f1c843b28efc7ee028417034a33d6f5635238bd13c701b2a','50acdee5cd44637ae3e4f89a25f62444dc50b2e3f842a3659aa1aaf432a1d848','b3cf013a549316d073e8f01aac3723f7efc2f254a8ce521b002d344a55356b8d');
INSERT INTO blocks VALUES(310201,'8842bf23ded504bb28765128c0097e1de47d135f01c5cf47680b3bcf5720ad95',310201000,NULL,NULL,'7e2dbbf14c0620ac0fd4e0e676857e2d055fff80cadfe2d9d0dfe07d36738722','d2478112ea87ff8daee9e812ca39841a42bd2be474d4dccfdf5c37f395aa4227','31e2bb35446f64b362265bb6262c30325240086a3bc0a6c25378bf3829ed5382');
INSERT INTO blocks VALUES(310202,'95fa18eecbc0905377a70b3ccd48636528d5131ccfa0126ed4639bc60d0003d8',310202000,NULL,NULL,'084c24e81842ec8edc4144ad64df9f12377318fe4dc491b307b7d377f3f81b2b','330a26a103d7c32beb900488dfc7ae4a1515c1142d3b6b4df4f4c817d160a0ca','4ca4116c1b0be400c8f9f084f8e071a111cce8515faa3f16444813310fb05a72');
INSERT INTO blocks VALUES(310203,'ab15c43e5ac0b9d4bd7da5a14b8030b55b83d5d1855d9174364adbebf42432f8',310203000,NULL,NULL,'4b0b8d82a5a2c8600a09b1050eed4440d9e0f2d817498f3e32ba27ebcfbaf6d5','bd5deb76e4a796d53eb6a75cce3d8944ddb451af4c1a9f0533dcb38528672b9d','c7418cc7da3e33658dfb4daf4489ce05cee6f85ed4c0382ee26a713b6e141143');
INSERT INTO blocks VALUES(310204,'18996fb47d68e7f4ae140dc1eb80df3e5aba513a344a949fd7c3b4f7cd4d64cb',310204000,NULL,NULL,'9f81657142f7523c01595bef4e9008d8525c2337f6d90140e05abad619d94416','7bba914ab1b2acb23c28d3356ba71aa68c8d60ec96595d6599c13f48a1e05336','c69a61ce795503fecb85638ac8ea965bf3dbd60c8d06e3107c7d34a994ba95c0');
INSERT INTO blocks VALUES(310205,'5363526ff34a35e018d1a18544ad865352a9abf4c801c50aa55742e71630c13a',310205000,NULL,NULL,'fd1cdea0193ed914cc408968efa42377d7c69453aa9bdf8bdf0731d4b1501b01','2e3cd387247158fa0c5d7e0b632eb056810d7a2425291c0ea2d4e479932078af','5e8e6c5d06916b297a4015c5f542b2d7762e19b2969535e7b86e5d38c233e594');
INSERT INTO blocks VALUES(310206,'0615d9fca5bdf694dca2b255fb9e9256f316aa6b8a9fc700aa63e769189b0518',310206000,NULL,NULL,'5845d6bedf81fba710999bf2954b3c1f3f9ca007a09d812ccae8e2a6d3b9bb07','27cf72bc59e7984add96d14f9ba71423c99d0228e6cc593e78bb40f27ea971de','c83edd24cedcaedccdb29bec37cf9757441aee2a39dd077470840931c5a726ad');
INSERT INTO blocks VALUES(310207,'533b4ece95c58d080f958b3982cbd4d964e95f789d0beffe4dd3c67c50f62585',310207000,NULL,NULL,'b65cf7069a0eb909357cd5d45129b70c576eeabc0cb13404029d088e24a2be34','db724c8ed48bda3bd1c4cdec80e480caa7253143b4d71c4d3bfebf8164faa818','4df6fc2f5406377b0ad8ffc003eae0e894f4b5b5ad9b0082df5688abf6f0a7d3');
INSERT INTO blocks VALUES(310208,'26c1535b00852aec245bac47ad0167b3fa76f6e661fc96534b1c5e7fdc752f44',310208000,NULL,NULL,'aa54dc010fec8a0ef3871c91667c45e88ffac08ee2fc93274d7ad1b2b5b28102','4deeeea32258169b4dd6106b415af2e603b738526593d24d19499cf259e9dfe2','7ced3e07befc1732fba36d089953525564cc7da83c2ebc89a2b4440ac2cf9166');
INSERT INTO blocks VALUES(310209,'23827b94762c64225d218fa3070a3ea1efce392e3a47a1663d894b8ff8a429bf',310209000,NULL,NULL,'c7866cb2098c87c1333da5b3dce4c84bdeb620c9f1898456b7cceb23e4027df0','483d05ece05c52d0850d3c4ea554e0c66fdcac386f843a569805c0a2ef25e80e','18d10b29ac977c822e2534c80e3b614aae265a02bf4c26faf861c7d703b9625a');
INSERT INTO blocks VALUES(310210,'70b24078df58ecc8f7370b73229d39e52bbadcf539814deccb98948ebd86ccc0',310210000,NULL,NULL,'207a1c90d1658d55fa0fc2e1507fce98521647ab5c4d11099c2742279cc92b3f','300ab42880555810cf4063c5928fd8828ae667c6db75bc0a5c9dc17eab43dbc5','1abc378b89f3b95d492bc58ac77fdde9cff0d91f1015807f5f7683045b13d159');
INSERT INTO blocks VALUES(310211,'4acb44225e022e23c7fdea483db5b1f2e04069431a29c682604fe97d270c926d',310211000,NULL,NULL,'dfc7fe172f9bc77148a1bfad5d441a3688f718b4985406d0cefd4c4dcd926208','74e134e50d9670db75fe5660655a12bcd6f29d6c5405f9db5a1ff2250ab64504','ad746d7bf293802d7ff27634f782c5d64ace62065c792edf0170a42aa613545e');
INSERT INTO blocks VALUES(310212,'6ef5229ec6ea926e99bf4467b0ed49d444eedb652cc792d2b8968b1e9f3b0547',310212000,NULL,NULL,'32a39bff0606ec93454a2cb144c0bbd1939bf2be6a2ae369b885afc0b5ef33c9','2ae0b5fc4856b588694e107a1194d1e6efb50aa07f01a9adf69ea03ce9fedb78','3b5fdb65db9772798fb412724a4a2cac79134090d9878e933593a60dc2ff4591');
INSERT INTO blocks VALUES(310213,'17673a8aeff01a8cdc80528df2bd87cdd4a748fcb36d44f3a6d221a6cbddcbe7',310213000,NULL,NULL,'15968873880e97e849e59971d4ef19881b1c11c3148dba966f51d986c59ccf36','96cb4babde1e7b5ba98cc465e0a389dbba69a671d1a36e5d0b8da8e7015db66b','9544c59fa1bdd48c01807a2f9f1c4e87af316383b4bd3e23e5f4e4480e52c285');
INSERT INTO blocks VALUES(310214,'4393b639990f6f7cd47b56da62c3470dcbb31ef37094b76f53829fc12d313454',310214000,NULL,NULL,'dcbdc463154fe49a7f22611fcb53e5ca78501424ba741040d89cac9db0a03ac4','3cfead39592847d9d496ff635438c85347075d4df52dda429f7fc3f023047daa','626dd9a8ead702c8abb825a3dc89aacc043cc5a19560301371cdf6e2839357a5');
INSERT INTO blocks VALUES(310215,'c26253deaf7e8df5d62b158ea4290fc9e92a4a689dadc36915650679743a74c7',310215000,NULL,NULL,'6047855f1c691f27ade1cc4c587f1c11ff68f5f5bd7959a23f801e5da7773eed','9a9158d9d2f983b5f52b643e5e33c4b402a01e2f1f6d898df281bdc9a212a7e8','2017003ddad7ea45cd9cd644c02484a448fa5abf2dff50fb3a2c5d24f4299730');
INSERT INTO blocks VALUES(310216,'6b77673d16911635a36fe55575d26d58cda818916ef008415fa58076eb15b524',310216000,NULL,NULL,'a12fbb09858868de79095c8e3222f6fa179f2f00bc3c97c8205fd9367ae05aef','d039db3a13d49d11eac29d6938d18d4cc5e4831ce4a5f950250df4a9f91fab5a','e853d6aa1f55a17908506a723f9ae1fe80011ae4f9fa00cf3e31dacb1c51a54f');
INSERT INTO blocks VALUES(310217,'0e09244f49225d1115a2a0382365b5728adbf04f997067ea17df89e84f9c13a8',310217000,NULL,NULL,'419d8dc096dd58523cd4822748754158f0c11945bbb62100cb5268cd802580a8','a7aaf62742f07fabebb2bf19fa0597203b4e2192fede70312762a6881fcf0510','b331eda0f2f665a42f33f3600bbfd51346ebfe847c22e7931ef3e678f51d3443');
INSERT INTO blocks VALUES(310218,'3eb26381d8c93399926bb83c146847bfe0b69024220cb145fe6601f6dda957d9',310218000,NULL,NULL,'a36c07f7fdfaf7878d73baf14aee58b42220b2b2411fd1864450ec6ce1fbd173','533004d2cb11caa8ec17b66c77f17e3640ad5d5e7ba10f412af1bc6e0abbe239','354b668d6803953d4b7d2000e4d59f32ed28c12efddceb7865e971446c85a1c7');
INSERT INTO blocks VALUES(310219,'60da40e38967aadf08696641d44ee5372586b884929974e1cbd5c347dc5befbf',310219000,NULL,NULL,'7958aa94088ecf0384a9a6b0569e9507d208e009e9ce139c823960e40996a47e','5633d36768afe3cfa180cb4b7ed955fc82abd144ff885ce819f64961254fb4e1','b9ee358dbb789318f067ef0346d5d9598476250b9e39c1c9a3aa91f21e9f9ca8');
INSERT INTO blocks VALUES(310220,'d78c428ac4d622ab4b4554aa87aeee013d58f428422b35b0ba0f736d491392ef',310220000,NULL,NULL,'00907c4368c2dc76d1ef98a0ba3c86bc4746ed2734b0c10f3797e0af70714240','6f554728684de8b52dc50bd3ea7a098647e5f2cd836e7794604ff569aeaa7a66','e9598653879cd0fda166c41223a84a9dd61d27c95f8425280a33cf88b4f169ab');
INSERT INTO blocks VALUES(310221,'cf5263e382afd268e6059b28dc5862285632efe8d36ba218930765e633d48f2d',310221000,NULL,NULL,'2e42f882087dc2158036592298321113f1b34e15b414efa6d43364c06d368540','8234cc27c526222821bf7b511ef782bedcb3ad4d7027f080dfbbe5607b277847','d3d7b280cdccf8253bcd0c95b2dbd1899f4aeff4d17f52e04b958cf91dae2509');
INSERT INTO blocks VALUES(310222,'1519f6ec801bf490282065f5299d631be6553af4b0883df344e7f7e5f49c4993',310222000,NULL,NULL,'00c4a5d41dd629bd0973c03152e4519214dce68498999c8dddc1f7a1cad28a82','0f68788afe5a7ba9dcfa9469c07007a0ec2d0617ac99c3d2b3cc00dc2b354388','54fd39747e97c44a920ff8c9814f88a9d47fe55163ae05c1555bbf12b5788756');
INSERT INTO blocks VALUES(310223,'af208e2029fa49c19aa4770e582e32e0802d0baac463b00393a7a668fa2ea047',310223000,NULL,NULL,'41c7a0fa22ebee9d55f2a3b118314293d155c349ba01069a23ddff76dc842955','1cfdb87ff4f32c0ae6416fa8c1bf80608ebbe875aba86bf08c0f8afe183a908c','2ccf098b64f085d045e8b6d7d520f9026dfd2bb5ffad3f71c9a1c1633e03ac7a');
INSERT INTO blocks VALUES(310224,'5b57815583a5333b14beb50b4a35aeb108375492ee452feeeeb7c4a96cfd6e4c',310224000,NULL,NULL,'66c268462442b69efb56b29e08aae1a404d3543e0a20711e8998a31af45ee929','eb2799fbbe0e3a6c7967bc5bcafaed520b92488b77add435a2d6e525f0f68ec0','5f0bfb3be1d20ecd1fef444a0e0d8b5184e210bca4d225f92629ae76aeaa9f91');
INSERT INTO blocks VALUES(310225,'0c2992fc10b2ce8d6d08e018397d366c94231d3a05953e79f2db00605c82e41c',310225000,NULL,NULL,'cf39fb28a7e4d4db7657bb11a30d592a15c049000d7ac86d4fb3d942bf879b95','d2df4a352faf36244cd4ac2ead6f36250b560cca7d1d616dc91fad174d90e517','9b85bc7fce86cca712455302eba15423787f596d489aba928591ecec7b259d3d');
INSERT INTO blocks VALUES(310226,'b3f6cd212aee8c17ae964536852e7a53c69433bef01e212425a5e99ec0b7e1cb',310226000,NULL,NULL,'cb622a4d04645ad96d3e0006f2b7632e8b82e44206d6c1cb75212b059fe18de5','df9cb170a4c88833735c237af4d515c19d2ff605b33971607b8ff0f033e0abad','5faaaa6cb8a96d5b4733d959d7f789dd8f237a6e25309a1654598075d4665399');
INSERT INTO blocks VALUES(310227,'ea8386e130dd4e84669dc8b2ef5f4818e2f5f35403f2dc1696dba072af2bc552',310227000,NULL,NULL,'60ae4209347248a3f7ad39b6436627f06e45433f6b6dd89cfd3383d68974a41c','589cc7514d3588795f60a258822f0584380fe89b0909b1f78bfd0d83fd41b6a8','908c464b7591dd5419b6103d8ca5641025814cfbdc5dd9e34ec6e8414a9fcabf');
INSERT INTO blocks VALUES(310228,'8ab465399d5feb5b7933f3e55539a2f53495277dd0780b7bf15f9338560efc7b',310228000,NULL,NULL,'798206ee77c9e2fc8fe943f9bf2074c9c2560f534e3304b944e2ed3c89ce8bcb','5f56b81c0cf2e0e3b801bd98e2d6b850ece0da387e9dda3403960c086601e2c8','3e7d0f75cb4b593be0c04734f3e15aff3a67c2f2bbe774a35db001cbe630d3a6');
INSERT INTO blocks VALUES(310229,'d0ccca58f131c8a12ef375dc70951c3aa79c638b4c4d371c7f720c9c784f3297',310229000,NULL,NULL,'becad39a4d1bc8d73a856fa1d2bfa251f29b23fec9448a91932dc610243fd8df','ac1f35550132f238546737059eaeb6919a83784ed172b68a02f99521e377dd26','dc1ba416191a859806bd656cc898a09fe282f27d939b8aaa4e833fec5bb9d0cd');
INSERT INTO blocks VALUES(310230,'f126b9318ad8e2d5812d3703ce083a43e179775615b03bd379dae5db46362f35',310230000,NULL,NULL,'e08eac4daa7d7bc70f2f47a835bb80993d6d6db06d8d8986101b717db1c62ed6','7182d2571e372f7fb32728e3c1668968a3b310b3caf207fa109944ccdced6f47','3089099cbfee0a75380c8c409e17967344431b15f4aac3d0b341abe7906d4b2d');
INSERT INTO blocks VALUES(310231,'8667a5b933b6a43dab53858e76e4b9f24c3ac83d3f10b97bb20fde902abd4ceb',310231000,NULL,NULL,'a761c29e76c9d5090cd1d6424beb91d0a9fd9546c67ecaa6d4879177b6745b59','60a198917c85ad1bc0c147da833c2fe02bd290dc88aea7003f0c09e6a64b4885','00dbadcef42bc00787cac3f8c97e55cf21bc061db738ea40330b6b6bae0e1192');
INSERT INTO blocks VALUES(310232,'813813cec50fd01b6d28277785f9e0ae81f3f0ca4cdee9c4a4415d3719c294e8',310232000,NULL,NULL,'5da469b7e21ad8ec4fe7cc2f426dcaeb18a3a4a3c44385d529a8b252c77a9e43','6dd413d51bc3dc09d5088feb14a88260de1b6588cfb71a45019fdcbc47353fcb','0434c4067846fcf4448ba639c63c504040f6e30df8534aed9bfd8e4c0ba2a08b');
INSERT INTO blocks VALUES(310233,'79a443f726c2a7464817deb2c737a264c10488cac02c001fd1a4d1a76de411d6',310233000,NULL,NULL,'d8531834d572acc01591997cac000185facc033e1ab72f8218a70d0ae3898914','9e0df5679274f016dc2ceb57617dbc58b04887be36fa231bd6368db5cc731b8c','55f776910b33247f94cfb02b6cf75c78d26b0672640c3ab1e6cc3e7ebb411cb5');
INSERT INTO blocks VALUES(310234,'662e70a85ddc71d3feae92864315e63c2e1be0db715bb5d8432c21a0c14a63cd',310234000,NULL,NULL,'0ac6803ab61e14bb08fd8051424565086ab11b4d33faef077f5a0732eec6f766','632f35ba0d29440339a72f031578a458a6f362a62c9d4a96462ebbe28cb63ee0','9fff0a331bd593bc7d2077b4e94aacb4f6197e585b97c570e81a460ccfac96f2');
INSERT INTO blocks VALUES(310235,'66915fa9ef2878c38eaf21c50df95d87669f63b40da7bdf30e3c72c6b1fba38e',310235000,NULL,NULL,'5f7de1c7fe45858dcc844604a77051d55de3b9dbb5f5d9910ead8bd0f3af48d8','cf3dc240d6953e42319b133d4bfbb0ddd0692f48217682e3442f591f63f72247','4bbebd22e2ed90f3b5c25b51b4cff37f3c4eac9a2b8f48d4b0f2bd4fe1759197');
INSERT INTO blocks VALUES(310236,'d47fadd733c145ad1a3f4b00e03016697ad6e83b15bd6a781589a3a574de23e4',310236000,NULL,NULL,'c0437ca60921bb73516c31a74f78d2fb48d2c628b629c8f55c8fbb0060718d76','737a7d1f11cb4378b41c5eab523622065b94ea4c1107b3bc0204c36a3ea6069a','84990d4d030081a89d16e8d8b0fe08c04bfaa09bd889e29ad09f9d6bc5030456');
INSERT INTO blocks VALUES(310237,'2561400b16b93cfbb1eaba0f10dfaa1b06d70d9a4d560639d1bcc7759e012095',310237000,NULL,NULL,'4340ab34a083b38dbca477b6cc2479e6d70ffd6d6b9b75772068674297abadff','62008f7cf0a21a270c3425eff81fa1ab7c637e6b0ee8c478f0d8f2139fc6043f','9947e85ff9d9c5da857a92536efa8fc04a1d27708ed5f176bbbdc8b88363b247');
INSERT INTO blocks VALUES(310238,'43420903497d2735dc3077f4d4a2227c29e6fc2fa1c8fd5d55e7ba88782d3d55',310238000,NULL,NULL,'6a76891c10ff0f9416ae1a024b985d621154918bd8ab545980b57fd2d18c4af7','46973a9c8dba4d219aabbf8d48010663f7bfed691cb8f1272ac3c01e06ee20b7','1024d231141c24a0ffccc7f93def1b3272d935ac44e7e8f34370a49cc9aa189c');
INSERT INTO blocks VALUES(310239,'065efefe89eadd92ef1d12b092fd891690da79eec79f96b969fbaa9166cd6ef1',310239000,NULL,NULL,'1128bb89562fc3b112da425a3dee67adaf741a8021ee378bdfeb44af3b1b1fac','6bb99620b08f92c73d9ecdedbe5f50e629aa8247b34b5e6123a9a5c704ced342','34718d6fd15c5cd3b733f7b70ba003d8b1fa4916e43b4d3f4c69215f74c03266');
INSERT INTO blocks VALUES(310240,'50aac88bb1fa76530134b6826a6cc0d056b0f4c784f86744aae3cfc487eeeb26',310240000,NULL,NULL,'be05624b84b2e76794f065f36b4e98d6c6c120f1d8a5db91957bbe7008ce3240','d9ab3d8076257da6ca459b57fce8468e05b9b53afc473a6a41ba7dd8163f5db9','e2743c33c8c1ca41340307d608ee42ec17b5e464bb5ece6b083f5083e3355a3d');
INSERT INTO blocks VALUES(310241,'792d50a3f8c22ddafe63fa3ba9a0a39dd0e358ba4e2ebcd853ca12941e85bee4',310241000,NULL,NULL,'5abfdfb1aa42fb80ca4538062d152d965b6a7a56bd1e170a7a109409a4606b7a','4f68d9375ddfd628a93d5543f7259b82d45db946b1539a3aecf307b183d38417','d6816d1f72be27aefc10204fb51e7c84a7d777d5b529d49f1f958327aaef225a');
INSERT INTO blocks VALUES(310242,'85dda4f2d80069b72728c9e6af187e79f486254666604137533cbfe216c5ea93',310242000,NULL,NULL,'5f354f767df3256aa6a23544a7164160b9fabe481c85d1891f5250b3026dd7b8','412e99b355fbfe9eb2d2666ce4ecb25119bf399354605d67127eab890855a79b','d42a0da75fcaff89ad465f6b0aa2fdbba549fd3f05e20ec69d286cba72957771');
INSERT INTO blocks VALUES(310243,'a1f51c9370b0c1171b5be282b5b4892000d8e932d5d41963e28e5d55436ba1bd',310243000,NULL,NULL,'ea3acc31b3c298237fa11ca4400c65ee46732c96e0b7fac5a183dd49d938e730','f1f825af925c730dfadb28a7d52d07630d9dc10895d5164f23012f36d630146c','224ffb1433799029b0139ac6622b203de437166857894765590cd7f34fd8a112');
INSERT INTO blocks VALUES(310244,'46e98809a8af5158ede4dfaa5949f5be35578712d59a9f4f1de995a6342c58df',310244000,NULL,NULL,'07ad792741a48d5a7b657e6c4dc83e3534c79bd1e7da7044139516124adc8f80','5f5e3be6271253277b2a753e50a54a43a8b0b430a13c51931945140f6ed99102','e9702e704a699a315088a83ea53c731aee93dea5f5766607f5d354a891549f8b');
INSERT INTO blocks VALUES(310245,'59f634832088aced78462dd164efd7081148062a63fd5b669af422f4fb55b7ae',310245000,NULL,NULL,'d36a618af8e92da03b373ab0137ded666db6cef906a6b2c0cb8c71057a1a5903','48cf9edae0245e11ab8f419d69b8fae916d5ce63b7f6069aab40882d12df8ebc','3a67b230d5e0ab99b8d03a596add3b766a54ead002568c7e3efd0ecce228624e');
INSERT INTO blocks VALUES(310246,'6f3d690448b1bd04aaf01cd2a8e7016d0618a61088f2b226b442360d02b2e4cd',310246000,NULL,NULL,'a34e154571ee585a839053a851a007d6d433d3efd2b3e923a9c4ec4bb0dc9d98','1817d6ef338b0b85a4e3ff700c008a60eae8ee34eb8c51065a9eb4e02365e828','8e2a2140730553690e4c2435e5a3110c42401ac5d1212cf97749bf1ff4c3cf4a');
INSERT INTO blocks VALUES(310247,'fce808e867645071dc8c198bc9a3757536948b972292f743b1e14d2d8283ed66',310247000,NULL,NULL,'ee94fcb9210718095ccdf63f30ab081f45dff765a9ca4f5c86b1b0d98973ef90','422e3e98028141e648e3534b872dd2f56b2148e54147ac263eb70d99072ae4ec','093f17e760ce6757ed5c609443eeeba160c3f9b3e2c2976640718a56e9cac386');
INSERT INTO blocks VALUES(310248,'26c05bbcfef8bcd00d0967e804903d340c337b9d9f3a3e3e5a9773363c3e9275',310248000,NULL,NULL,'029884a5273466fa45cdfbd91ae3aaca50af0771d22f6b55af6367348c2802e2','9637b28a20672afa97b6ce4d9125ddb4d118c9293822eec9395f5e6a3ea48bd8','a2db1ab42412b423db701fdffa8c13b09fb4250bbbd4499b4cf6c68e77860f43');
INSERT INTO blocks VALUES(310249,'93f5a32167b07030d75400af321ca5009a2cf9fce0e97ea763b92593b8133617',310249000,NULL,NULL,'dc10674812c5249c693ab7b148d048439a0d77266014f3afc1810a6260838f02','3e4a115f5b640852bb1f69656524eee3af30b96ba9ddc37bd5fdd0703ed9f02b','a91c1fe3f13882039beb140343a97041560b1031dabc96e0b4dae6b67b201d3d');
INSERT INTO blocks VALUES(310250,'4364d780ef6a5e11c1bf2e36374e848dbbd8d041cde763f9a2f3b85f5bb017a2',310250000,NULL,NULL,'a0fd49b46ff0000e83d4c56281dfe2be1bbfc924c75969726754b05bf7107641','1da6ec6669eb7db1f3a6f2f781b588383cfa62e419840d73e0cc865221098d1f','544aa63e04d895468f887031da251daa0f006b6b7777442ee74471f3d43188bd');
INSERT INTO blocks VALUES(310251,'63a3897d988330d59b8876ff13aa9eac968de3807f1800b343bd246571f0dca7',310251000,NULL,NULL,'bdef6a6203d28d314dc087e539a9cdad19d123b605824f0a66f13bf5f72de9b8','65fe933e2ebbea7cd1991b6a1a3b670638a70e88acb228a2494f8eaafc428d67','23d2f963dc82ae402cd0e65408b78d64ef65aaf89f1e16527a1040d7c65379d0');
INSERT INTO blocks VALUES(310252,'768d65dfb67d6b976279cbfcf5927bb082fad08037bc0c72127fab0ebab7bc43',310252000,NULL,NULL,'8da11bec0d58b196ddb073d3aba0def98f01f83da654765fcae21cae6046214e','922eb35dd4c2fa84731dc388956ae26d5f6e395b67be2c5dbb1a199ef34b03d9','2c4140b54cd6e75de21bb3f9b72d372445e39aef8eb5706c5ec03fada946fc17');
INSERT INTO blocks VALUES(310253,'bc167428ff6b39acf39fa56f5ca83db24493d8dd2ada59b02b45f59a176dbe9e',310253000,NULL,NULL,'2efa2c5781899d213741e795ca62fbee9d3ddf53792ce002db7484adc66bfbd4','f9cd22900c49e751ce3876ab4186c32c34923b436f463d14fc705e704f69494c','8293539da6e9ae96312f2c37344c26b737e463141cb2312aa3f7cddd947a0976');
INSERT INTO blocks VALUES(310254,'ebda5a4932d24f6cf250ffbb9232913ae47af84d0f0317c12ae6506c05db26e0',310254000,NULL,NULL,'d062ec468e76421d3769a99eb3c8b2cbf4bf393d109ba13b3bce128613fff547','bed75acde91c332ba68fdb5e9ef687b045bc0692d7da12d1e671269e269df20b','f19a71dc1ca9b99afaad863b25c7f6caad6abb24413e6c74b29bdecf06684c8b');
INSERT INTO blocks VALUES(310255,'cf36803c1789a98e8524f7bcaff084101d4bc98593ef3c9b9ad1a75d2961f8f4',310255000,NULL,NULL,'5c531dc8a7461e9e7a2ead654509d76c9be3427b1d2b75c0ac7ae0e03126c49a','98fbd56c3099a16da3bd7112a8eda2a62ebe925522fdc024ea5857afa33cfb0f','074550e59056a8a6b2841a97f3e76248efca4fe7881522477a1a2b029beaea29');
INSERT INTO blocks VALUES(310256,'d0b4cf4e77cbbaee784767f3c75675ab1bf50e733db73fa337aa20edefdd5619',310256000,NULL,NULL,'8da9f0162e15e33e14e5e1e22c2fd847055a65b99eec519dd069a83bb9006b51','6a2e78bc9c385c136bfb5d66a89c31120408505770a85e369aad5bc25fa09a96','4609276774781b59c25cfacd307bdd1715afc90e2413a77a3da3f8396da48391');
INSERT INTO blocks VALUES(310257,'0f42e304acaa582130b496647aa41dcb6b76b5700f7c43dd74b8275c35565f34',310257000,NULL,NULL,'0cf6657db5f3145587a466c05f237289b639668d844abfd8d46430c090b54913','fb2833cba3b5748e6706ec947bad89ab2ddb120b2622ac9bab5732be6644ed9b','f0c971ba4e545bab8df9d677dd5530b8a05fef71d3d0be59f696e63b7288acfe');
INSERT INTO blocks VALUES(310258,'3a0156dd7512738a0a7adba8eeac1815fac224f49312f75b19a36afb744c579f',310258000,NULL,NULL,'e340defe4bd84e788f9c5b083849e6aa1d5c7f33123ebe62d7abe04b8a9e312e','20eff65b060e26e58d84d8cf0dcd02a88009ba77640650ee8db88b5e62ed6721','80855c46bf8b7f8576901be3551bca41699cfc287fc17719626b817dd4ae9a08');
INSERT INTO blocks VALUES(310259,'e5ed3cdaaf637dd7aa2a7db134253afe716ffdf153e05672df3159b71f8538a9',310259000,NULL,NULL,'03ca0cbce5a5b50988c19c0d4e754240f50821695dca767d1169f8c7f5c1fdcc','d76856becf6c4d07e2e728fab52e7ac7f27bfc46a14fd86081b0e916e4092542','3e52a0fadd5ab1397f8bace686ff610f139b1ffd6b8cdf40693a018232cfcc09');
INSERT INTO blocks VALUES(310260,'8717ddcc837032ad1dc0bb148ddc0f6a561ed0d483b81abb0c493c5c82ec33cd',310260000,NULL,NULL,'83a3b43e01f4f25ba05b527415baa3e8b8adba319628c245988136bd8fcdfcfe','a4dd3409b5ceb2d922d9d0431b708580802d29ef5c76744a85aae794a2e9075a','9b9b0c9ea62daa9bb5b68252ab65f64e07a610631b87c30653aa88105d402114');
INSERT INTO blocks VALUES(310261,'a2a9d8c28ea41df606e81bf99cddb84b593bf5ed1e68743d38d63a7b49a50232',310261000,NULL,NULL,'e61c12005d60870fee947fff469631ee540b1a0d6b8aa67614cfacc0a9f65ec0','565c4726c6f20395291c7a97b227e16f87006834033e60931f461c3d34b3d2fc','524530307b023146e228b955f162bb329f7c306f84c83dd5440b1afb6816dda5');
INSERT INTO blocks VALUES(310262,'e8ebcee80fbf5afb735db18419a68d61a5ffdde1b3f189e51967155c559ee4ce',310262000,NULL,NULL,'c21ac4906d435af5b9ef5576da6bce454f65ef16099b7ee03219a4ae1851bb91','9e11b8c72ce1683d0541599dd01b86b6cb50e882278c399c4ba91fd497e49330','f651bc0689d93f3335b9d9e97f12fe56731314179b5c14b3c36d707d547c55b0');
INSERT INTO blocks VALUES(310263,'f5a2d8d77ac9aac8f0c9218eecbb814e4dd0032ec764f15c11407072e037b3c2',310263000,NULL,NULL,'676f6c532ff23839fef228a9fac7719e77a3c20efdc17f3cb2d13035c78820e8','faa20750e26b9ed8a840c9965b87e5e8dbd0e3e20b177a157dc1a75862aa2190','09c459fa07d63da1557af83fc4469cc137caaccf62f237d3ffc7b2fdeab25f0b');
INSERT INTO blocks VALUES(310264,'ae968fb818cd631d3e3774d176c24ae6a035de4510b133f0a0dd135dc0ae7416',310264000,NULL,NULL,'258854505b1d3067bf360f3d0dcb369ed7a90fec8744578d3dde51a79db72c25','729029a26d5e2c11c181d3e28cec68e5b15f276f93402ab0356b247adb60b6eb','c12890bf746aefee2e262724b9facadfff6efadebb64c532bcf18d85a07caa5e');
INSERT INTO blocks VALUES(310265,'41b50a1dfd10119afd4f288c89aad1257b22471a7d2177facb328157ed6346a1',310265000,NULL,NULL,'72ab32c420a7dcac0e7c36c4d9ca81e237955b4d8bc57c87078ba292923ce98d','2ad62b44c340a1f6821ee25083c0089e5ec4ebf0ecaf5644b47a45c5f0901ed9','c7c757e0c4b287357018dbf3d027fac7957b1634ee7e79e112b1412a8c891fed');
INSERT INTO blocks VALUES(310266,'1c7c8fa2dc51e8f3cecd776435e68c10d0da238032ebba29cbd4e18b6c299431',310266000,NULL,NULL,'b81386d19aac285fee4e39a818cb0442e378372f7d55f92e6028b37f974e4a61','c1ad22cce0d16a411f6c55fdf9a6d5861941061f918201d861be839779219700','7c0d763d918adebe233db7a6ae12f3d3989c8b4eff41f370b629b2ed93a3c259');
INSERT INTO blocks VALUES(310267,'c0aa0f7d4b7bb6842bf9f86f1ff7f028831ee7e7e2d7e495cc85623e5ad39199',310267000,NULL,NULL,'ea8fef9e82e451d9650777b051f19fe5e34b8976f1bcc1880b6eebe5feda34d5','3c4753f9c2c24d99fcce0e09fab85168054cb6f30e3831c93a74a5d2eab779f4','6145eddf489594779f39dc25dd682cf61fabb3edca3dc07478487a6f48639847');
INSERT INTO blocks VALUES(310268,'b476840cc1ce090f6cf61d31a01807864e0a18dc117d60793d34df4f748189af',310268000,NULL,NULL,'1545d381812f0f0caa827a237f145838276fe058b05af4808615738ca9910bf1','b0352abf886e7800566a1de14355381e46797cc3e3aa2883c0cbb330bb16eeee','8eeefa23d7effec9fd3ec0ccd1261d85f4f51c36a41db4723931feda74bb9131');
INSERT INTO blocks VALUES(310269,'37460a2ed5ecbad3303fd73e0d9a0b7ba1ab91b552a022d5f300b4da1b14e21e',310269000,NULL,NULL,'fd9cf61ac6e1fba409e4220a141ed6c89c18c893c7a752af53d5f7608bc04a67','a8ca02baa8d6f501c427b33c0ebdc11ed52fef1274ebafb6708ccc5564701e50','643d23c877c75ee02fc74dbbb8822526ee1ba1461a31927bf44ed0c39985afed');
INSERT INTO blocks VALUES(310270,'a534f448972c42450ad7b7a7b91a084cf1e9ad08863107ef5abc2b2b4997395d',310270000,NULL,NULL,'1d34c8c0dfdb4733a7b589647abb0e6a08f8de93a5c86fbab786f6d9d1500785','733d5cc0b761dde95e8a41d7b1f1b7082c5e5120db9ef0e73bd211cea9a6e17e','4e88dc0c7b4d13853fd065ddbd0e403f8e0d843b370569778cc2975e02bc3a3b');
INSERT INTO blocks VALUES(310271,'67e6efb2226a2489d4c1d7fd5dd4c38531aca8e3d687062d2274aa5348363b0b',310271000,NULL,NULL,'cf38baabc6e8a082eba1bd8ca2f72af5eb01cb76bd3c9eb101b27080a3a70d17','7ee684e28d285e9bfb6b3d692ef6b0df19a900b1094555dc1b3657cf6c64dfa5','72c8ad82ac4a21aae6cefa568b428c1bd53df0bbd434f514113785b2d5ed593d');
INSERT INTO blocks VALUES(310272,'6015ede3e28e642cbcf60bc8d397d066316935adbce5d27673ea95e8c7b78eea',310272000,NULL,NULL,'2b2763fa5ab2962582c303062da8b8da7280274e615b3e37f93a32e44793ccc8','f4dc3ec8f5b1e4b66e5f8f990e80742fe085c795a13b70aa80598bf403462a35','bc66a9e7178fb9f3182b29b3dd6c17d01f35a4bc1a870b3122610594690198d9');
INSERT INTO blocks VALUES(310273,'625dad04c47f3f1d7f0794fe98d80122c7621284d0c3cf4a110a2e4f2153c96a',310273000,NULL,NULL,'ff9df73d4f92b7557c36f20d8f622923dda225a1ae2871e60f16ee2dfdf5b9d8','317003835c2458bbba1b33e67eef30361b08705437c5d1831116aebcedd5031b','c4383844418231b224137c69ea3f47b9f5285d47ee4b769e6ecc9cd400bdb78e');
INSERT INTO blocks VALUES(310274,'925266253df52bed8dc44148f22bbd85648840f83baee19a9c1ab0a4ce8003b6',310274000,NULL,NULL,'ece29ec2cd160d7634009f41cc2d0f13330d53ec6971c019d69dfa4367f86646','66f447a35275f46c99e5a33a8b219b5496a6d01da6380a810a2f2bdcf3e2a444','2f9cf03f177659762b7d4cc2f1312449d35da05c68d1cb97d9f893698f17e884');
INSERT INTO blocks VALUES(310275,'85adc228e31fb99c910e291e36e3c6eafdfd7dcaebf5609a6e017269a6c705c9',310275000,NULL,NULL,'23738d6d8dbf8b44b481f6c0eade991987c84e8025fe1f484c7acd3ead7f4163','98b2897237721945a76848e31000c7ee856369e97dc4ba852eb2106a3d4ef699','74b557a68fd9d7b14bf3065307ca9dc1d62775b51db50a999aa737ca808aea70');
INSERT INTO blocks VALUES(310276,'ba172f268e6d1a966075623814c8403796b4eab22ef9885345c7b59ab973cc77',310276000,NULL,NULL,'a241e1cb19bfbebb3bbb09c6471760b8379ddc73a67d69b4d84fd1d21dfb7034','e501bb4a2e516b6fd2db58ceb21071030685c2d6a209fa335b83454f5f452184','982a73bfe04785b5588eb5955813e93bdca7abca6b0aa4aa7abcda29b047c21e');
INSERT INTO blocks VALUES(310277,'c74bd3d505a05204eb020119b72a291a2684f5a849682632e4f24b73e9524f93',310277000,NULL,NULL,'0efa57fd462031a87831832a789ed7751aac5f6c19a23767555b3f7145d87532','1151896f6f42944457da1ed1ba753abccea231183233fe09de0f6807e7239849','4eaeb9e08b5efae0a31dd402632bead86849240391f01924413e91a40e99b23c');
INSERT INTO blocks VALUES(310278,'7945512bca68961325e5e1054df4d02ee87a0bc60ac4e1306be3d95479bada05',310278000,NULL,NULL,'0045189a4da126b22e91e4bc2a7ac37dc90ec0869b7fcbc927919fca4cce5259','58ab69bccce31097836c7774482ad1ef2b6c4cabcedfa6caeb94800b08fc2654','4d4a1a35b7a01a9c42f433780361077c7ecd1a9eae340e321ce90e15acd65394');
INSERT INTO blocks VALUES(310279,'1a9417f9adc7551b82a8c9e1e79c0639476ed9329e0233e7f0d6499618d04b4f',310279000,NULL,NULL,'442b7d4dee025b81c298ca0f6a5b9dbdf17ed0087fc36eab7f0671d5a19c9a2c','57ba0ef1425af1bff3d16c9e6ab3935026b31b4277ae854300c444a9880fe4d7','be648bc766be10459053a01713f2239d0c2d4f7e21508f2b1989b4f000839b74');
INSERT INTO blocks VALUES(310280,'bf2195835108e32903e4b57c8dd7e25b4d15dd96b4b000d3dbb62f609f800142',310280000,NULL,NULL,'38d7f98ae9cfb8e3938032dc33899e2e3e5a88e9037571cdddf8ed4709fc8225','373a8307e415ebf6d6d59a12987ecbfdd9a8d88b797e992b58989f8a0ba9e34c','330bafca024352d61a3e8ac19fee0db94e3915522b7fccf3f0d0a9e20ae2ec9a');
INSERT INTO blocks VALUES(310281,'4499b9f7e17fc1ecc7dc54c0c77e57f3dc2c9ea55593361acbea0e456be8830f',310281000,NULL,NULL,'51237cee3b85f1636e336259b115fad87acc830c71e13ca79e344efb7c308ecc','7ebe847c7834e67d1cb30b391fc6e6a6112ae36363bb1c5d21336ebd75b827cb','1ea1877908ba0390e0c691b7beb0d9094cb560144d060b1dee91835ebb40a5c7');
INSERT INTO blocks VALUES(310282,'51a29336aa32e5b121b40d4eba0beb0fd337c9f622dacb50372990e5f5134e6f',310282000,NULL,NULL,'73adccef91b5c738e8810d4781a38edf98d2aa0a8cb619d575e9bdeda979f1fb','90bab3479094bdb3537cd09201cf79236fd60785f36bcb2ebe473311b7e1eba8','27c954c8ffaf361e5066e552d6db9060b5ae1aab75d1b735032fb1a22aca1d14');
INSERT INTO blocks VALUES(310283,'df8565428e67e93a62147b440477386758da778364deb9fd0c81496e0321cf49',310283000,NULL,NULL,'5853e60a1b79d4f154cc1f3dc8b0a4d6130ac07784bac16f257f92b9ef294144','4cceb19e9fc99e004ab744bf6c1805d872eb997bca84256a66dae436ba0c135a','8b7282aa27690ab382c50b480db4c8270927bd8d0b3c97dd3638daa4ef1a85b1');
INSERT INTO blocks VALUES(310284,'f9d05d83d3fa7bb3f3c79b8c554301d20f12fbb953f82616ac4aad6e6cc0abe7',310284000,NULL,NULL,'ce33194cb67aa0a5facd788cc24706ef249bcecc95a9965f91065146b33e464b','6d43cf6b611e129ae32263ea7edb2ab93aaaee7405fdea34d14dba6f493b620f','193742b6b6f4898cb02682f30737d5c9d5f8ededd81aac2c447180071bf18bfe');
INSERT INTO blocks VALUES(310285,'8cef48dbc69cd0a07a5acd4f4190aa199ebce996c47e24ecc44f17de5e3c285a',310285000,NULL,NULL,'3af35e85e98aebe1a9c778570c730bf80e085a08ca707c1a5d44b50f2579e71c','ad7c1c8b935bf67e293b1bf9377325993b90e9d2578ca8df92ce057442b4c3f9','376c27c88fb1cbe35c59d38e12f9c3fd57ca28b7254fef8bb0418e8ac608bee2');
INSERT INTO blocks VALUES(310286,'d4e01fb028cc6f37497f2231ebf6c00125b12e5353e65bdbf5b2ce40691d47d0',310286000,NULL,NULL,'4b09b627adda46ee7cf7116102a330ba2aa1ce714b2fa133f7952af34a52ede9','4893c4484b5f64604e02d83f44439450e902918ae2e2769e467fa55bc3607c04','30719980f4ca155c7e57fcb7d9c4955cb0cf29b052ffd9f438e99dc567063fc9');
INSERT INTO blocks VALUES(310287,'a78514aa15a5096e4d4af3755e090390727cfa628168f1d35e8ac1d179fb51f4',310287000,NULL,NULL,'67786e4ffab15cb78c7bb44ef160d1e5d99b599eecb5ff4f906a6599d744d410','c8fa15aaaf6a99ef2b27c2bdf44d4858951a6a41a7d36e940c80adde29898e39','7f93718ce3dac86a902a365ac447af81488928a2f8e8f8d422ce6e82a1747856');
INSERT INTO blocks VALUES(310288,'2a5c5b3406a944a9ae2615f97064de9af5da07b0258d58c1d6949e95501249e7',310288000,NULL,NULL,'600716d2696160b3ba290636180f2afa24bf8d24435022b4539a4cc965c18dfc','fd15637788eea6326ccb51c695d25d86a3cbbad16e5f668a167dfff628cb2765','c75f4d577f80a5f85908bda41e689b9d5767ca6b8eeecce1d03da6118407a321');
INSERT INTO blocks VALUES(310289,'dda3dc28762969f5b068768d52ddf73f04674ffeddb1cc4f6a684961ecca8f75',310289000,NULL,NULL,'cd6d4b17759152edbf25fd72dce9b9126ea31a2bb1a5435636801e0ee4be1158','bccb06398f41b18c3675216ad5c9b96f4c7e7147fe72670c3f6b7b285a6a7cd8','fb42b5224d08bb998317898127beffa4624fd7b96b1345057e198f82e7832563');
INSERT INTO blocks VALUES(310290,'fe962fe98ce9f3ee1ed1e71dbffce93735d8004e7a9b95804fb456f18501a370',310290000,NULL,NULL,'04a9135f416dc041d3c1c0216a84fd780d133213c3369691fbf5e8848af9d14f','e6dba9676be853e5a3ad193ecb659428b0a7d45d7eba6caf0f9dcb6b19568b41','c3e310ba60744ef021982874ba069947e53e251038b311ff10e1f2bb84828495');
INSERT INTO blocks VALUES(310291,'1eeb72097fd0bce4c2377160926b25bf8166dfd6e99402570bf506e153e25aa2',310291000,NULL,NULL,'50f556e01b9e8c135b20187bf863839e651a0d0bf4cfd1008b446531776f7917','b3402cc3bd1f59fa036e13a85fc29870fb99dd0c24286d546a365ca82806dcee','3ed02cfed71a7eb9bacacf646d66ddb39c4d10111bba5bf639cb3423250baf80');
INSERT INTO blocks VALUES(310292,'9c87d12effe7e07dcaf3f71074c0a4f9f8a23c2ed49bf2634dc83e286ba3131d',310292000,NULL,NULL,'9d4bf4b1c5dba1132a9cbfd78c1d94cbaf15d7648da80c8bc1a8dce12a79eac0','a29b66365ac008cd69c4e41f01cc7e843b6a85e65e8f222be59cdffbc2ee2e24','27b9f97440133feade0190c0ca4f47bd94f1ed6397333556e90725130ed5a53e');
INSERT INTO blocks VALUES(310293,'bc18127444c7aebf0cdc5d9d30a3108b25dd3f29bf28d904176c986fa5433712',310293000,NULL,NULL,'a51a3f9af39175cc9d142eff67811307ad8f51cdd8161aaf0d98af9e2be28efa','935455c0ce71f70b94cca71df040a95493ec84d882088392ac0a72af122945e6','943c4560c10ff85696f48278f6d832e7cff46dfdffdb37bb7a0e0db792cff8ef');
INSERT INTO blocks VALUES(310294,'4d6ee08b06c8a11b88877b941282dc679e83712880591213fb51c2bf1838cd4d',310294000,NULL,NULL,'3e9858caa8e835295aa7e78505ea34ce0726e3f5f6cf9fbc6dc4393a28724a25','c29866fa0662ce2e237f5b75dd2cf990584f5f0b65a2e6369fc4e22cef38fe1b','4ecb683691108254115c326d4b205e0361c1f20d47510afa810262fd29e15b94');
INSERT INTO blocks VALUES(310295,'66b8b169b98858de4ceefcb4cbf3a89383e72180a86aeb2694d4f3467a654a53',310295000,NULL,NULL,'bf48715799c46d629641ba5b72405f6e6cf0500886da94fcc6fddd306a86b02a','024a1f0e3d0f6075f6c4a80f8a8924500d60f87b6618b96bf9feea24ec32f21b','052a62fd95fa15640f8872acefc9d0ed27fe96c34614eafba7a04eb2bd74e0cb');
INSERT INTO blocks VALUES(310296,'75ceb8b7377c650147612384601cf512e27db7b70503d816b392b941531b5916',310296000,NULL,NULL,'08e2361ae4b98387ee43fd7230ea8b296dee677b337f0e211527e3cf29a64e9b','bf3465e77be21ae585aa8b302511f1c97b765653236507fef6c174b3a3073598','c1805feb03f2c60d002fbc97ed3e2ce2f5980e18e687ee628a57a0fd52643d3d');
INSERT INTO blocks VALUES(310297,'d8ccb0c27b1ee885d882ab6314a294b2fb13068b877e35539a51caa46171b650',310297000,NULL,NULL,'cfefc3138983a33686dd1fc37f06fa1d7e01d9b218f7242cdd59005633c0ded8','f7f46e7bc5f87a7b42b2d343a1af4ca1a250e5f7eecef868839e96a29ce641c9','042f8dfc3ac34ef54a8b6ec36a7c3d78f201fe8509ee666ab43cf73b6b003b9d');
INSERT INTO blocks VALUES(310298,'8ca08f7c45e9de5dfc053183c3ee5fadfb1a85c9e5ca2570e2480ef05175547a',310298000,NULL,NULL,'25254257d6f6724161b2b73f94d28d3fd40594b4846699b8a2d5f45d205b1fec','0e719175cad11b12d51b584409f1820bf7692f1aee9dc26e339ed31d314fe960','d55b079b176e5b697175c67f0721ca524e05768dad5820d105b0965a931c552c');
INSERT INTO blocks VALUES(310299,'a1cdac6a49a5b71bf5802df800a97310bbf964d53e6464563e5490a0b6fef5e9',310299000,NULL,NULL,'756acb1055ec75df8fa70f80e23d75f2b47e75035bfd68802e68308785a2ee14','0a47530c45823b9ba1a5ff55162ffbcd0d9f8687a72f815573e70452a42cd016','4b087ad8c7aec5596cef8e73fced53207e5a43d807e50d72a6fc6d6df76b2cc1');
INSERT INTO blocks VALUES(310300,'395b0b4d289c02416af743d28fb7516486dea87844309ebef2663dc21b76dcb2',310300000,NULL,NULL,'e30027ca81176dc1e79a0ab3a5afbb839a3338dbe9ea6057aebcd383ed884c1d','638767cf00b7ef90de8bbad578587029caa329926562387eb16aae65b1281127','b5d9117f51ba64d3d5acc98cb4b57df2b2d34ba3e2ad892eb7a31668433d79a5');
INSERT INTO blocks VALUES(310301,'52f13163068f40428b55ccb8496653d0e63e3217ce1dbea8deda8407b7810e8a',310301000,NULL,NULL,'4c2bcffc796af76a2607a978289942241e63a6387e0a2ae8fc3d02c6b5519fb0','5b7656a563ed0b2fa94f5524fe821379061c17b70d14fbea47461667f5a93ddf','1a940aa2872a0298ff05148c19d711ce16a17d49836821736596e87e5ca028b4');
INSERT INTO blocks VALUES(310302,'ca03ebc1453dbb1b52c8cc1bc6b343d76ef4c1eaac321a0837c6028384b8d5aa',310302000,NULL,NULL,'a39fdd7f84d2f6e29b613a8a724bc0902d9abd2d6b4d2f46c3b0512928d69b3f','8a29cc63e82e6d2f1100a3ab435c3c2f51b843219aebac26c75bf1d5fdcaa4fb','d00f59d88c12fb980dc9da75354c004f3eedc4974660530f1bfe7c3f175fabd0');
INSERT INTO blocks VALUES(310303,'d4e6600c553f0f1e3c3af36dd9573352a25033920d7b1e9912e7daae3058dcca',310303000,NULL,NULL,'23f307ef560a02210f4aae5fe605c6d8af9317ab17f1e1ef0944038a3515da49','670d7a928cc4f8ebec30ebd750e17e837c1628a4f30741c48e46866871ec99c8','eafa19f36c14139cf75b8b782f33a12b6d0264e4084d1bb154c91a0621ccfc0e');
INSERT INTO blocks VALUES(310304,'b698b0c6cb64ca397b3616ce0c4297ca94b20a5332dcc2e2b85d43f5b69a4f1c',310304000,NULL,NULL,'6baa2ac646d3725fa01111959753844d22181cbbd1801cb12c4208be3709a3a3','20a4db6b3283cfb9f3087cad9826f2dd10943ce1cd9a830a2f5473ef5e8f578f','7f7b4839f508c12a4b77c2d6036b76eee8b94f1334eeed05409f0c9a32c1b7b3');
INSERT INTO blocks VALUES(310305,'cfba0521675f1e08aef4ecdbc2848fe031e47f8b41014bcd4b5934c1aa483c5b',310305000,NULL,NULL,'c366fd009860a090c632131eae9380820e512009bbbaa6f7bc5529afab7a88c1','ea788112095cc7743fa462a3ff3b3ccd6c83fe0d1dd6f4539e05ddcb74cd8dfd','4df35736684de0cbcf7fdef7fae9a4fdae7e15d8a1a2f913d94a7d7335c22031');
INSERT INTO blocks VALUES(310306,'a88a07c577a6f2f137f686036411a866cae27ff8af4e1dfb8290606780ec722a',310306000,NULL,NULL,'fd12969b828d689063b4885a0356fc17e5207794d1f5b6a17bdeb8d584815a79','0d4afe570d4f9a31aaa7be962d2a3d46cee62065b9db7682ccadafd5197bb2aa','cbfda8a71107724ae2384001aead065863b806fcfe76ed98470bddbd50b51951');
INSERT INTO blocks VALUES(310307,'bc5ccf771903eb94e336daf54b134459e1f9dd4465dec9eaa66a8ee0e76d426c',310307000,NULL,NULL,'e168094d31f56d36e4c3863fe719e6064b08ccc6f3c2adb490b1359360026aee','96d0bcef226b9eca1be7d951f0c907fb2ae6a802acdef0117b8fa51de4cd9fa4','891b2dcd029c69bc66daa1da68fb1bed08ec4c903190eb1386c3fdb4a71ad9d6');
INSERT INTO blocks VALUES(310308,'2291ffd9650760ff861660a70403252d078c677bb037a38e9d4a506b10ee2a30',310308000,NULL,NULL,'523b3bba7b02e2c4e588f21ed14b7b4f6630f887cc89f9361487b581d7e633b5','fb81b14fb42588bcd2c9d13d6979345cb056adbc66e67c703b4cdc68075c7368','b6a40c45d06acf0efd42e51df07a5b8aae4da8fc49d12438603db53d46fc0433');
INSERT INTO blocks VALUES(310309,'ca3ca8819aa3e5fc4238d80e5f06f74ca0c0980adbbf5e2be0076243e7731737',310309000,NULL,NULL,'effe1a68917014086da3bf8696f6c13f3cf2cb5cbd6c18b80ed622e476cff017','d3a77bd7d1ff106c2fbd9af359190235b3d985bda6da4eac555e26a4fb85b1ce','cf827f3417b8829dd7c7433dc5acc79f9ef97e56288a85aa735c4640baf37f31');
INSERT INTO blocks VALUES(310310,'07cd7252e3e172168e33a1265b396c3708ae43b761d02448add81e476b1bcb2c',310310000,NULL,NULL,'968fb8a7409531a27ffb52af484e7c1076f05b58f9a51bf9cf3d5a7d83b12002','8a8531cda006e292b23605328911e3dfffbdd5cfcd5cb70327a57d049392b42b','9495e3dcb5f5371d0825fb1ff9179c9ff7e7744bf8e574eaad29e60fba772eae');
INSERT INTO blocks VALUES(310311,'2842937eabfdd890e3f233d11c030bed6144b884d3a9029cd2252126221caf36',310311000,NULL,NULL,'8c69639a757d0195594fa1da3f6b35a0e8c62b8df7f95db81e26d496b8c9dd72','c3435b7de827b5c6d55d0d4e8a4eda75cb2543a1a1195743a709946be4e54403','0bb0e1396287f0ad4b487466147b98a89b7c8e5dc052500c0e8df076e1ba1feb');
INSERT INTO blocks VALUES(310312,'8168511cdfdc0018672bf22f3c6808af709430dd0757609abe10fcd0c3aabfd7',310312000,NULL,NULL,'8d839bac01b9aae5e554f691ae0ee42cee072f9367fcc2811d4b3f65640cfcad','b21b0d587617f2ee9f1cc160129a95f6188579c35afd0da561034dec593c3670','4f392ddecfb63697f584f8074361f067206b78591916e1155a357c63aa46c495');
INSERT INTO blocks VALUES(310313,'7c1b734c019c4f3e27e8d5cbee28e64aa6c66bb041d2a450e03537e3fac8e7e5',310313000,NULL,NULL,'1377f4255bfd7ff6638734733a4b8faec97fd62aeb954e42b477c875ccc50b73','be6229bf8b7052f6e8d8cef8b4d5143aea2d4e733e174ed401d801a05463ec3e','dc6451168f9b9b7565926cd36da4706d30fdec95f8ed3ceef4be935a029e8b37');
INSERT INTO blocks VALUES(310314,'1ce78314eee22e87ccae74ff129b1803115a953426a5b807f2c55fb10fb63dc8',310314000,NULL,NULL,'8ed80d44f0d6ad01a30611d94b91f735ef3a166cf0dfa7531492a3e4ac7c29f1','c89b9a65f7eb038e639232baf72b3d6a5b22aa2a0dcb68f31c66d1cf50f7e7b2','ef3a66a51b6fa24e1ee53b03909bfcb7f7ee24f19cd9ffe83c315ac776729097');
INSERT INTO blocks VALUES(310315,'bd356b1bce263f7933fb4b64cf8298d2f085ca1480975d6346a8f5dab0db72cb',310315000,NULL,NULL,'24b5905cf0d5349b7031870af9677916892e3292fa61455a75e84c1605a398ba','ad36056a4f97fa36a976eff124fea7c73ace7b318c0517ebe1649f236957f8c5','765da0f2c549ad5808ba6bae012b4a5485612ab0606210f6fd90219d79c696a1');
INSERT INTO blocks VALUES(310316,'ea9e5e747996c8d8741877afdcf296413126e2b45c693f3abdb602a5dae3fa44',310316000,NULL,NULL,'a191657253ca159739403f35417ef74637b053db49c7db62465fde4c54e69239','7dc279b31bc7381b8ff0398d40dd507a0eafed3778437daa3bedd1d7a8047e49','a50b390df2a89a0724baa5f0aa03d0b487d0482f9edc9a7fc93e6f067e0de0e1');
INSERT INTO blocks VALUES(310317,'aa8a533edd243f1484917951e45f0b7681446747cebcc54d43c78eda68134d63',310317000,NULL,NULL,'bf6d880b9fa42b0e38523c00c92a898093afd068450be504a0a56bafd69ed647','c601dbc1325315bbc57e845244a34398b6a25552094835e779102a96fa5b893e','97e51f83f0bf2a2f1493a28cabfb46770f0f84510bdb8147f73fa11571a6781b');
INSERT INTO blocks VALUES(310318,'c1be6c211fbad07a10b96ac7e6850a90c43ba2a38e05d53225d913cc2cf60b03',310318000,NULL,NULL,'6422eb2cab5937adb9ca2194c025d0dce63cd62e18d7ebd63220207957c942ee','79b39c0c2452e89d17f0f803cf2fa2362218ef14d076843d53e4d57042284b25','f1f23033e38e211b8d524cf13ef5377aec9737e849395b223b711cd2b278b811');
INSERT INTO blocks VALUES(310319,'f7fc6204a576c37295d0c65aac3d8202db94b6a4fa879fff63510d470dcefa71',310319000,NULL,NULL,'efb625496aa4365f5ac198a82833c880a60cd5f86d04689463216619cd7d96b8','ca4e754d75a4b8acfa58962721747da7e901d9b6956acc4203cf3bbe9c6e511a','4f09b94a242b31fefcb4b1891d0ed487da4384c467c76687b986d3a405c53842');
INSERT INTO blocks VALUES(310320,'fd34ebe6ba298ba423d860a62c566c05372521438150e8341c430116824e7e0b',310320000,NULL,NULL,'8c3938d7b3c0a822ebee67f1ecf21b1db6496e19471cf1f2cd00f30325d0c88a','cb8bc742c67e29c9b3108f9ce18ba757aec13257122fa6fb0851af0a6aa2f9ad','b523c43a005331509605a6da46d1b408072e33f4bc345c9eedf7743dc2e8c367');
INSERT INTO blocks VALUES(310321,'f74be89e9ceb0779f3c7f97c34fb97cd7c51942244cbc2018d17a3f423dd3ae5',310321000,NULL,NULL,'21e4c3a7afd02f183cbb69709fc6c006ab3d38fef3466de1a1870232d1c891bd','ee213a2928f6411088fa697bf488b74ab8f6ec9eadf2083f3812b1d381b52c96','34f842b03199ac6fba551d74d51a0f68052cc18970a94e4126e6da0a324c49b9');
INSERT INTO blocks VALUES(310322,'ce0b1afb355e6fd897e74b556a9441f202e3f2b524d1d88bc54e18f860b57668',310322000,NULL,NULL,'01b3b28c4d8eb796827267c06e6362206884e44f40c3f72d9b5c9d1e6cdfb29a','95cb768c2c295d9ea02fe8a1b5f632631531aa360e71f6c0d6659234cce8a561','d396eb32858e16351a65a50264c23e36d4e13acf985408fd70276f087295ac70');
INSERT INTO blocks VALUES(310323,'df82040c0cbd905e7991a88786090b93606168a7248c8b099d6b9c166c7e80fd',310323000,NULL,NULL,'a362da58df0d31eeaa93a25c91c17bec62f9cad6ff0c31420584ce293ecafdbc','daabcab776e7544cd7444b1e92ea429bb994a362f2e17ad900958d9eda6c5293','7dd3b1787df9cee7eb0e463ca98e4b376e656729682dc2df7aa8407cfa3dc37d');
INSERT INTO blocks VALUES(310324,'367d0ac107cbc7f93857d79e6fa96d47b1c98f88b3fdda97c51f9163e2366826',310324000,NULL,NULL,'d1b353ac97e000471c66df8ee04d7b0c25f7eead2414e5648cd2ef334881bad6','907808f66384f54b9faf9b1ffc081f5d6a8bf2eda67a80677217429d6930d333','633e54bbd9c020a752d7bc0986233ab352ecc39f9a8ef9c09e3a4c5482271455');
INSERT INTO blocks VALUES(310325,'60d50997f57a876b2f9291e1ae19c776df95b2e46c14fe6574fb0e4ce8021eac',310325000,NULL,NULL,'7734300dc764c67fde935dd4432396de4a31cedc2901f3fc70bf1576797cf7b0','468484a22f6fcce55cf0a331134f80fc8e506741eec64276117b42de7ec57ae6','ef9088032e1f719ba58b55bf71ae879e669f2ca9b934dd210d549ff29212f096');
INSERT INTO blocks VALUES(310326,'d6f210a1617e1a8eb819fc0e9ef06bd135e15ae65af407e7413f0901f5996573',310326000,NULL,NULL,'ebe859a722587fd456695c6a46af7f0bf54c03e940bdbb5424520a8c1fe70617','9762816a3a9a49065a7b833407b5c3e7e9544cf2a99b760734b99e5e8103b148','a634b752b0f3c63f937bff8768f796410899b81df5031d228eae0e5d38292ecc');
INSERT INTO blocks VALUES(310327,'9fa4076881b482d234c2085a93526b057ead3c73a6e73c1ed1cdee1a59af8adc',310327000,NULL,NULL,'8ced7a546ee2c746d4dc3f0ecd2fb4eaa62c65c4e98be74545d8de22c03526e6','da5895621bac6c9e6485314637555b9fc8e80f9c77e95de8f1585e38a051d252','13125b993f83e31e6d2d1c841500890ea939e40a1b96a2a065c6db504bd50260');
INSERT INTO blocks VALUES(310328,'c7ffd388714d8d0fc77e92d05145e6845c72e6bfd32aeb61845515eca2fa2daf',310328000,NULL,NULL,'bb5d3479e492f52a0b3b69d29852faefdff645f9b113eae82594f57e8aa40b5d','a6f200cfa31e08cbf2da8d988da56f173fb08bfddcf7fd1521ff9aaf18b3f531','55129099aaed092fc74842bcb214ea94a69734f710fef0bc4f5de808bb80d507');
INSERT INTO blocks VALUES(310329,'67fb2e77f8d77924c877a58c1af13e1e16b9df425340ed30e9816a9553fd5a30',310329000,NULL,NULL,'4ad2c9d802db762537be19143ef5eca474cd9f749bbbc661cb95bcf1dcb0b02b','3be3a9f31fcb4e04f7b367a9284a73f9508a67f2b0f35e95d69a141f6f40a114','3d63d34451eeb99186992241631d327db9fb16e915a857f4a891207e7b2a9e94');
INSERT INTO blocks VALUES(310330,'b62c222ad5a41084eb4d779e36f635c922ff8fe275df41a9259f9a54b9adcc0c',310330000,NULL,NULL,'4a9a6b59d56f6b7cf867095d939f9bddbf779141177feda470df3759b7d48be3','5c485e0c4e24f9b229e0379ddb400bebad8ac331e603a86a908c861241788777','16ed4746b6f9038d78f69b413ecdd8c9f760521f6e0c8ed8b64063ad8e20c02c');
INSERT INTO blocks VALUES(310331,'52fb4d803a141f02b12a603244801e2e555a2dffb13a76c93f9ce13f9cf9b21e',310331000,NULL,NULL,'c676b9c31e0e3d74d005ad0a52a18ba34688b6002da5d269bcea0f789a4f8e91','c577861cb50dc843056da3cdc37939142c6363f21b93905af9d5f5c1959af17a','36b88c8b06d3e613bbeaacedbcbd30ee3b2f7af48b5da0e3f5670c389350b380');
INSERT INTO blocks VALUES(310332,'201086b0aab856c8b9c7b57d40762e907746fea722dbed8efb518f4bfd0dfdf2',310332000,NULL,NULL,'cf0b702c03ecff4bda1254dd5e96ca580b69d5d02d1f233725fccbe1f5f32000','aad2f73db475aa18a41347dd275b72a8c86b699e76e8abf30860302ccea84f15','9ac169b01c751fcebd9b23adb54708e44ef3dcda981e2fcd4169c08296daf56f');
INSERT INTO blocks VALUES(310333,'b7476114e72d4a38d0bebb0b388444619c6f1b62f97b598fed2e1ec7cd08ee82',310333000,NULL,NULL,'b40359eb197db65549946d93a39b2a732e0694d21b8d0138b9bfce4f5a87ae5b','6e23c6bc804fc915a5910bf7fd2c953b5c66840104f89341af56dff33e83acc3','67365462ab48a6ac77ca0c3bd99ee3ac3a6aea40f59550cee8642f336997afa4');
INSERT INTO blocks VALUES(310334,'a39eb839c62b127287ea01dd087b2fc3ad59107ef012decae298e40c1dec52cd',310334000,NULL,NULL,'7cb471ec146f9ec1e4d1b93184ea641f7b8088807dedcd1c0be4ca5ba99e80e1','bd4545b4c244bee0ca3bbf778c98098c5bf4fb2dac454dab47631e6622a13fea','c941c16b7c1a120253fa30981f1fc5949070da5b169e614549004bc926985ce5');
INSERT INTO blocks VALUES(310335,'23bd6092da66032357b13b95206e6527a8d22e6637a097d696d7a96c8858cc89',310335000,NULL,NULL,'47de747ec20cbec96a6bc4b71f67ea827c7a5a1ab0d3541fd539efac7442d644','f6297e3d17764644e93d7c338188f8289b0d54a6e0b3f10191efc58f6ccd880b','71d047ef2b82e2e85abd0fde756466ceac39b8363aa460cdc074a701bd61f132');
INSERT INTO blocks VALUES(310336,'ec4b8d0968dbae28789be96ffa5a7e27c3846064683acd7c3eb86f1f0cc58199',310336000,NULL,NULL,'c216588e623d2b3d03499c7e9f817106b20a8c98765979987633f1e4e50d9594','f54283aa2cb3fff3cb905cc7a6e2cf7e09f6573445d0acca4d4fd7612d0a4b6d','73e2afe35ee1fed72f0f31a13af68b7ddf51cb94a6675051227f364c5abf240f');
INSERT INTO blocks VALUES(310337,'055247d24ba9860eb2eadf9ec7ea966b86794a0e3727e6ffbcba0af38f2bc34a',310337000,NULL,NULL,'a558b47328f54b79a5ad9f7737af0e4df07e13e20f150296370e111879c09c2e','2fe649a95b61a731ae6397661be083e91fbbb0bc0e4d4033776d41693df14365','d7ddb76eca4312f655a6f93ec1345a1fd3f6a84c33a92de51f64c9c419eb848a');
INSERT INTO blocks VALUES(310338,'97944272a7e86b716c6587d0da0d2094b6f7e29714daa00fec8677205a049bcd',310338000,NULL,NULL,'31bea50c6481fa982eace70df5fc13d2981f1af13962809e3492b493a0dd4905','74e81f48e069c6dcd12d0dbd73d58efecf4567323fcc91b530e8746372624892','27698f5872b5bd769f2e3a956c0b5991cb35b8cf11f231e872488016d5406d35');
INSERT INTO blocks VALUES(310339,'99d59ea38842e00c8ba156276582ff67c5fc8c3d3c6929246623d8f51239a052',310339000,NULL,NULL,'6605ca3db3c509fbc8574f2e10a3f981e2ff17b2812946ec8f2b1e49ba44f220','f0e825f62e0abd30212217d8e18ced1dcac37d42f0602675938e69f644430362','0d90bca5a050223eb9b491aeca61adfc792567257cd10ab23a14a245c84c2ca7');
INSERT INTO blocks VALUES(310340,'f7a193f14949aaae1167aebf7a6814c44712d2b19f6bf802e72be5f97dd7f5a0',310340000,NULL,NULL,'7db1ad1952cac2dda86fff6e5f939010bb30a1da26af438d354e17f423d5bf1f','fd3b903e4826565ea138e66544020ac30870e3610469e5c8aecd732af28f3059','94b5c5e9863b7ef7e2f956553a669e2780dbf8fde0a54fead97b9f54eabc59f1');
INSERT INTO blocks VALUES(310341,'6c468431e0169b7df175afd661bc21a66f6b4353160f7a6c9df513a6b1788a7f',310341000,NULL,NULL,'1a1eef01250d2c53a1b34a8ee5b1e8fce984c3d47d28c544c6e162493b51225b','0b32c949c02347231336c84f225d722ad48a9480d85f1661e477075cc0419c26','2822d2bc9b1e33a0a8828929ae72df8189d51beb033c2cde1dc9cef8dbd9cd1c');
INSERT INTO blocks VALUES(310342,'48669c2cb8e6bf2ca7f8e4846816d35396cbc88c349a8d1318ded0598a30edf7',310342000,NULL,NULL,'3c85c0b825985b04b42137da7e59fb3daaaf9e65b871b79390a4d8b31be5da92','0b146c22ae1a7677dc447c37a6e95583f8e5b7346b1f3276cfe60752c1419079','f1018864be278aa59ef01bad159bbf373d207d2e24936dd7605912b6d18e3308');
INSERT INTO blocks VALUES(310343,'41a1030c13ae11f5565e0045c73d15edc583a1ff6f3a8f5eac94ffcfaf759e11',310343000,NULL,NULL,'26f4ea323dd31b715c7a7f4ab8f1feabb199333a8494449ed538ff13215bb3b2','4aee9a05673e2b5e3e48c927a0dc7a430acdb58cd1a53704c3f083676a52ccf6','6ba87230750a339cfd08a88f73e4006616015284c62bcf54b05425d568012d03');
INSERT INTO blocks VALUES(310344,'97b74842207c7cd27160b23d74d7deb603882e4e5e61e2899c96a39b079b3977',310344000,NULL,NULL,'444314748cb1fa1c836b3b4de65c3920c7fe446741193e5f77843affe3bee908','f3c8dedfe5ebdfac06383173f1a013f7a7c58a9a41ce0d3ea9eb5781c13131b8','5d040711628cf9dfacae0c867c0976f936afbe16f456f1b5022dfcf611032e29');
INSERT INTO blocks VALUES(310345,'0bda7b13d1bc2ba4c3c72e0f27157067677595264d6430038f0b227118de8c65',310345000,NULL,NULL,'d1775816bb104187076be74e78e87fc6d367c3cb31d372329aec2b635002ca2e','bd38c4ea1f70d2f7cebd970d99a061eaf3ea696d813a0176e87ebf50b3de7619','233a1d4a1850fde2ff8c0c5815f91326faab3ae46593ba9d34520d5ed098559e');
INSERT INTO blocks VALUES(310346,'0635503844de474dd694ecbcfb93e578268f77a80230a29986dfa7eeade15b16',310346000,NULL,NULL,'3244eed1df8ec4ae0ddb04f9f6e59e54244ca3df10dc21fc89c99c74ba734781','e8cba1350735dd1ca83bc564677f377e2804efaa9abbae57db37720c4125a279','1c02dff0f441acb3a7d9114b0a9d7dbd2786dd0dcf15caec4aff029815549886');
INSERT INTO blocks VALUES(310347,'f3f6b7e7a27c8da4318f9f2f694f37aaa9255bbdad260cb46f319a4755a1a84d',310347000,NULL,NULL,'6fd1802c269750b69ec04df457d47cd6b44c261340ebd5b4da61f06ede6aa166','e08d3ab87e0f894426971601cdd93906bb514d52f38dbd39abf53fd6f1db76af','6826e5cbb57a0c7f7640e196bbda9fd642487ff46eddc66606ac1a293cb511cc');
INSERT INTO blocks VALUES(310348,'c912af0d57982701bcda4293ad1ff3456299fd9e4a1da939d8d94bcb86634412',310348000,NULL,NULL,'668330e80a23f499c0e91b01c4c51aab393813b840f81b6b672611e391699faf','5a07adfaeac8558dab67eb027db5af6349087abb6c0faef9eb9aca4e0f4db4aa','a57224522d52351236b6bbf189e3cd9a5201e5555100879ff6431d53e1e3edeb');
INSERT INTO blocks VALUES(310349,'ca911c788add2e16726f4e194137f595823092482e48ff8dd3bdbe56c203523c',310349000,NULL,NULL,'32b36035ac1684e93126657ecd9711feb689672f64cceb03d220a8089dfacf12','e2dfdc634fa8fe426b99bf8c68916f02a40312c4bebb834ee09a5ea7a1f56caf','3cda7fa32a7071dc0337192ada8d38618f13106f63bf1ab49daf38caaf1b07f3');
INSERT INTO blocks VALUES(310350,'c20d54368c4e558c44e2fbaa0765d3aecc8c9f01d456e3ff219508b5d06bd69d',310350000,NULL,NULL,'dbe70bf3b8e4b74ac25c1b6737b6a760e6a06a4f96ee83a5ca728c8501d4af05','b4d24235d2e11992169b70339c3ad5a84aed8b8b03051df04b6f71698c513bfd','2ba453f888a4938af4ba4b229bb816b1414f0d4f7f259d774b89c3afea798593');
INSERT INTO blocks VALUES(310351,'656bd69a59329dbea94b8b22cfdaaec8de9ab50204868f006494d78e7f88e26f',310351000,NULL,NULL,'89bb7ea865a221a3646f78ea774a7cf1e15e8d65b85ddcfbdf87773145904151','90e99fc71165d08d0fb71346b03bb68150a4e071834a622e201ef31c29d708ef','c1f9ae5689be7c233c1326e2feb3c3bbff7c14fc0f7b64226878e7314fdc0a78');
INSERT INTO blocks VALUES(310352,'fb97d2f766a23acb9644fef833e0257fdb74546e50d9e2303cf88d2e82b71a50',310352000,NULL,NULL,'fdbf27d576a72b046776be0e5c0a91d060619778aadef3df1d30f1a7785a0fdb','bbc4c09c8f08aa10b7d0233f7f1c9c1033ddc1ba81d982cdc7c29fe24a50df6d','0f18c4a6e7940f9b9f6a8d12c9aa785936ae53e3f344a4269d684ab98ad1580a');
INSERT INTO blocks VALUES(310353,'2d3e451f189fc2f29704b1b09820278dd1eeb347fef11352d7a680c9aecc13b8',310353000,NULL,NULL,'73429d323376209447edc6d2ddbfd51f0bcde21736ea6dad61dc96b6984a1fa1','12d4cee7cd7abf74267e759e617673b682107b512c687d44f88adc38054197ef','e629a6e4a03242625373ba2fecd497414de773f5abf4184eb7f5e229e56830b6');
INSERT INTO blocks VALUES(310354,'437d9635e1702247e0d9330347cc6e339e3678be89a760ba9bf79dd2cd8803e0',310354000,NULL,NULL,'b2bbcbb6a7db94b2a5681c6e380ac13480bb49c29a3fbb3c7c1eb740f70f8324','67cc4d429ba4ab0d166497b44c6c60cf9047cfc841437a2d3420f9bb32daf223','57c4dd38c6cfb775c71fc5103347e92da83b28625d08dd4203088a6813bfcfa0');
INSERT INTO blocks VALUES(310355,'ea80897a4f9167bfc775e4e43840d9ea6f839f3571c7ab4433f1e082f4bbe37d',310355000,NULL,NULL,'ccbd3ea41587c3c1d92f355979b49c5340a0a90060f07c228c22d6ff76b25579','54413fafcabfcabc42352d909a7b308c200d46ba15cfdb4b4c14de7044f1e03f','bf1c214b4b45e26657dea7e6aec7f8903cbad6a3da825270dee00f396d7bb515');
INSERT INTO blocks VALUES(310356,'68088305f7eba74c1d50458e5e5ca5a849f0b4a4e9935709d8ee56877b1b55c4',310356000,NULL,NULL,'06a95d39e110e40ba318320d50984096cbec88c680f426f721154555efc2561f','73986f0f4056644437c2cddb466711d36ca915d8d4330f917538da30b705080a','70a6473c3adf3b6506d323175926819517079538843d40acbded1934f9a9fd38');
INSERT INTO blocks VALUES(310357,'4572f7f4ad467ef78212e9e08fa2ce3f01f2acc28c0b8ca9d1479380726bab1f',310357000,NULL,NULL,'443f947352e853367d1c10d25771c7d78eec22fac19c5bace6f96b8f949e264b','cbcaf6d0e2dc462a871627aa1ba45dd540fd3b00f7aad0dae989fe33f9c38995','421a03d447aa2b8e53d89b0ec5dc49440f266654d99bd9428459cb25f625415e');
INSERT INTO blocks VALUES(310358,'d5eae5513f1264d00d8c83fe9271e984774526d89b03ecd78d62d4d95ec1dea6',310358000,NULL,NULL,'c2cd71dc9e7d5ccb5d5e9d6b55c47010c9db6a573d01820da1c8960970fd571f','5f904716d02d8ecccb6cf5769164e1ed1b23a59b2720c5385cff5ad55c5ffb1c','3ebe43c555aca9133dd702eda2690c93505735ff9d47f6cfad5e8261e253b1aa');
INSERT INTO blocks VALUES(310359,'4fa301160e7e0be18a33065475b1511e859475f390133857a803de0692a9b74f',310359000,NULL,NULL,'5b7646bafc6b11eb1554ea1e02221883043b435ae973c3678505fa2128aadfb7','1094d036016a07a1ded15c169753775274bebb5c2d54c18d2a71d8c54bcf1cf7','ebdc624ed63730a0bf143729f2402a2e548266c3da1e757f326db5d1cf1d15e6');
INSERT INTO blocks VALUES(310360,'cc852c3c20dbb58466f9a3c9f6df59ef1c3584f849272e100823a95b7a3c79f0',310360000,NULL,NULL,'b0e937568a47c244e3b29cfb3a5e7196c171acc1565c44020345c715b7774658','d79af4f4538a0a4d487309fc424c352502ebbf2b9dbf776d07c314e4632cc6c0','8bde0612565f32f04fb7f94f63d04789e7b0a84284f16eace8af47dddbaab499');
INSERT INTO blocks VALUES(310361,'636110c0af5c76ada1a19fa5cd012e3ee796723f8a7b3a5457d8cb81d6c57019',310361000,NULL,NULL,'fd5b67bb571f4e9c0c37c6a5c9e1181133c301e05f4f97a41bd827eda7a6db3c','517774ade9fac5a929096e2bd5168d04fe23b160ad16a0d68b6f02329fc394fc','749c76d1c20437c3dd239c16fb2f7706c971c2c78a59aa4f64856e688c2d3f31');
INSERT INTO blocks VALUES(310362,'6199591a598e9b2159adb828ab26d48c37c26b784f8467a6bb55d51d7b6390f2',310362000,NULL,NULL,'38382cc090b349809c4798c3c83b485f8ff682fd5b5b2568357d62ef30f7c046','f279b6c70b159ef7e286de95c21089350d2161b813a61c7b8ae3088a972ce76e','9b1a135f87d0de66724b6f58eb7e8c65a9ad902ae1215654e3d7c14b55262076');
INSERT INTO blocks VALUES(310363,'a31967b730f72da6ad20f563df18c081c13e3537ba7ea5ab5d01db40e02647e6',310363000,NULL,NULL,'82911a691937d87629bc14e5294f68a25ff2fc6512370db032834b85a623d5c3','d5a5fb3a7e7fc55dfb3088d90319100285416e3ed2a3d4a72c55ef68b32bb83c','0c673fff76019c44170f3f3ef6f2d3266cf0f58a5e7823952e519621433aa893');
INSERT INTO blocks VALUES(310364,'67025b6f69e33546f3309b229ea1ae22ed12b0544b48e202f5387e08d13be0c9',310364000,NULL,NULL,'cc362ce4c2142e539057430e2dd6402b985c62fefa4e4ad33afe1305f53af8a4','a7e25be2ee026c952f991f1f711b0673f49364a4466d64c6f614442b4149c8c7','cd56fa0031730c241d782d036ca5088f52ab2f6e38d86a2f89ec4326de815e72');
INSERT INTO blocks VALUES(310365,'b65b578ed93a85ea5f5005ec957765e2d41e741480adde6968315fe09784c409',310365000,NULL,NULL,'49e41f95f081b70e3f540fa22864cc4f229ceabfdfd54f2da112f1fd35466617','18d94e63a2fde56d3a70c963d2dacd75b10159bfb223e8bbb63c6cf0e3fd96b8','e30364b4b67cd74c3a0f2cd3a8b00eb344b1b41d9a4fe602b9beeae3c484d05c');
INSERT INTO blocks VALUES(310366,'a7843440b110ab26327672e3d65125a1b9efd838671422b6ede6c85890352440',310366000,NULL,NULL,'687c5f3e381d164499126ff90785e3635c825db3808267d4de2ec0e37cc7c597','802e824e9134af8ef57b892a7a4424d13734c7f51df703785f2fd217e17a6314','4dc309eccb8056255ce538f16b4c94d8ce5846c074288cf2a5dd16beb4c7fe3d');
INSERT INTO blocks VALUES(310367,'326c7e51165800a892b48909d105ff5ea572ff408d56d1623ad66d3dfeeb4f47',310367000,NULL,NULL,'d7fe976a4b2cca2e23d082a703ef4f4739e110ce1e0a373e76064f6186856ff7','76dc7646e026e2c5e7bf4a10774b909dd7c65b8ce5c47b19ca543a541a1b58e4','447f2560ec91fb7d44d5a3ace0d63f78df427323ce13a17ea94a66363f7da77c');
INSERT INTO blocks VALUES(310368,'f7bfee2feb32c2bfd998dc0f6bff5e5994a3131808b912d692c3089528b4e006',310368000,NULL,NULL,'97f0a0f9e6f355dd179aa2941412decc1b0a06de0dc14dce8538aed6e35d41ba','da73f3ed416815a0c208674d432b363945052605ea295d61b35d834e7518c5f4','c588b9418115d2a55ec06a7fd6740c867b18946722ec835fd5eeb45df0e11119');
INSERT INTO blocks VALUES(310369,'0f836b76eb06019a6bb01776e80bc10dac9fb77002262c80d6683fd42dbfc8da',310369000,NULL,NULL,'1b5d9ec9bd918c84a5f9b6882c94a739cc1ad1362dedfbdf7b2009fd42251d66','79d2554eaf2ec92877c52aa103bd2e9963b7890dd475ef57205d6594bafa422d','a634d6dc6f04dd4b6af6e16a8961c85f5fc674277842f36078c20d5b9c864ed1');
INSERT INTO blocks VALUES(310370,'9eb8f1f6cc0ed3d2a77c5b2c66965150c8ceb26d357b9844e19674d8221fef67',310370000,NULL,NULL,'578b039ed2b9a25e1c75ad9a5242c5962d6645616dc53fb08386602e40f14486','4704aa8e04be9ac775d3745ffbe8659ebfcbf6e6c97a93df77f01e44d13e1f3a','3677f80c984703d9c469cf2bfbfa087c966ee830631c2af954b83519b69ff06c');
INSERT INTO blocks VALUES(310371,'7404cb31a39887a9841c2c27309d8c50b88748ed5fa8a3e5ba4cc3fc18310154',310371000,NULL,NULL,'473d21b8218a2b02f7fa0d5daf114fa988e4a3d97c33aebe97e51a8d22252492','09e6518bc0b557392822696d55c58566bd1b0f825a5657b56749cbfa28e1070f','c45c30eec7cbafa94c9eb7e641de71ba186be573c15b09cae390e007134dc5e3');
INSERT INTO blocks VALUES(310372,'d3a790f6f5f85e2662a9d5fcd94a38bfe9f318ffd695f4770b6ea0770e1ae18d',310372000,NULL,NULL,'0c306eb25702d190ce32cac521b1fac9b8a7cbcf441fd74be8de2e002b4ce14c','bb63a6767982d0b4f9b42731d01297fb39e9442591ccb02240e9faf30fb37f4f','c16dcb78f81788c6cde8fc06655e5929fb5d80f9cfa2c5307765ba2bc50a0a8d');
INSERT INTO blocks VALUES(310373,'c192bec419937220c2705ce8a260ba0922940af116e10a2bc9db94f7497cf9c0',310373000,NULL,NULL,'48d14b17f9074ce1f75ab32581e8f6fe7d518ebd669af6508e5d986d97c92b3d','a09a9edf8613beb60390caa73cfcbb921ffc44fd2995384bcd8426b66651a67e','10a42aa533bcee483193ee29bb78b09fcefd02ac7d52e806436c99140bfc25e0');
INSERT INTO blocks VALUES(310374,'f541273d293a084509916c10aec0de40092c7695888ec7510f23e0c7bb405f8e',310374000,NULL,NULL,'aee93917f6fe0046069aaff48d5d1875a9c4451acec6562a377428bfb1184cd4','78620a46220bbabf5e22bb33847d5c1cda7653a73bd603595b55c2dda15530cd','edf0adc456dd3c783ed5ca0ea090ee3fdae2f79ddd5b6cdf2d88757c96d7ed86');
INSERT INTO blocks VALUES(310375,'da666e1886212e20c154aba9d6b617e471106ddc9b8c8a28e9860baf82a17458',310375000,NULL,NULL,'2b0d74911bba5c9530b69c04fec512fe4c5df25458e5237db884586a221fa30b','156f397a89d055cefb9122a85cc9e2c17c329bc9299f337a6eb42ee01c9ba7ef','7d90277911392eb5e0eec3112b875577f5a403cfbf9c19da345ffd18e0f63119');
INSERT INTO blocks VALUES(310376,'5dc483d7d1697eb823cba64bb8d6c0aded59d00ea37067de0caeebf3ea4ea7dc',310376000,NULL,NULL,'a6f84afe2845ba2fa4e5e7377b1d4474dbde6dfc9c4bed050e6d10cc80025e82','1fb3895f8c219e1bf6972c65f4a77fc9e64545dd370df74c009cac489422d101','dbfc0e018402296fd9d098e78a74b8b0ba236d25ce7920f6c4a699ac2066dd10');
INSERT INTO blocks VALUES(310377,'f8d1cac1fef3fa6e7ad1c44ff6ae2c6920985bad74e77a6868612ee81f16b0b3',310377000,NULL,NULL,'e006e13691719e4fce65e72c692d3affeae8ae465de2a3b285a1bed4eb518a70','f57543b893097c054f72de2492f34a7703afbbc95efa0abe21c08eb27ec4e62a','17b7a5fbc022e7dd456191fd0a307797acce5ac51ccab4a819785485b25acb47');
INSERT INTO blocks VALUES(310378,'fec994dd24e213aa78f166ca315c90cb74ee871295a252723dd269c13fc614ce',310378000,NULL,NULL,'607ffa4928577b82f275750353fcecc2e50098d227f18bb8ea95ac2bbb10eea6','bb790714de1eebe07bf6e6d76729b4cb7c0f9f49d9736fb239cdc909b7f51f32','97824b2b2588546d7884ef36d80d45388309a29dad9915027082d912cfd3c736');
INSERT INTO blocks VALUES(310379,'d86cdb36616976eafb054477058de5670a02194f3ee27911df1822ff1c26f19c',310379000,NULL,NULL,'9f17e8d662dbbfc12a56dc36172b3154bc9b05a87885d1411826481e1ca4f6ea','7035c2985473f8d95c0ae0ee6a4b946c5a2d33265a9c6820b3828c45655e597b','5cc824f159b92b7113dff9f4770c77b88d030427c35202706c781c74cbf11397');
INSERT INTO blocks VALUES(310380,'292dba1b887326f0719fe00caf9863afc613fc1643e041ba7678a325cf2b6aae',310380000,NULL,NULL,'d617e30e1a32ed1cf269a190fd4c843755413492827546a0b3ed14278f817532','e0aadb98a78de89a793cb71e13ea2f6be93f1c6bc1860e97c1a155d599ea2462','b8a9ed4c956f6ede6acda32a07148022d4435f06a3a4039c9325c0022fcef656');
INSERT INTO blocks VALUES(310381,'6726e0171d41e8b03e8c7a245ef69477b44506b651efe999e892e1e6d9d4cf38',310381000,NULL,NULL,'8af8d819f02927de4a74d3d37dcecf6e5124d53be37603764b1b1adad13b0d7a','dabe90a2ce8dbb4de0124c931150573466bd37415185ed9a97b997bd883a2c42','1d71c6b3502f6d7ce1f39e5db0db9c688959b14e7541c3857694f79fafe674dc');
INSERT INTO blocks VALUES(310382,'0be33004c34938cedd0901b03c95e55d91590aa2fec6c5f6e44aec5366a0e7d8',310382000,NULL,NULL,'809d5c20335bbefe8e4f3552e24b24d96f6ee4ab12f3bfc9e74898371cf69797','886a3a1632ccf179d4a8e0ec1fe4a6cd20d608b6f63c253a99f42e6ccf68d534','549102071adac878fab97c02b031b779fffb208a4fe79ce749fff2e3bc6d0e49');
INSERT INTO blocks VALUES(310383,'992ff9a3b2f4e303854514d4cad554ff333c1f3f84961aa5a6b570af44a74508',310383000,NULL,NULL,'d8ec301994a5333f8efe7cc547a833d26c6766deb0b39c4fc18d1bdb470ee903','fa25dc7da0418a0142ebad661d8cc59d1459c58a05c6ceb65c8fcfe509bacad5','fab09ba6ce86bf78c09256e0213450d2d2fda0abd103ffe6543f734bfbdcc13e');
INSERT INTO blocks VALUES(310384,'d518c696796401d77956d878cbdc247e207f03198eabc2749d61ebeadee87e5e',310384000,NULL,NULL,'fe47a03993cb9079a6e72810552d631fe838bcfaba3b34c73c9948af77266df2','bc0815472db26063bc55ce373569b0ff81a579f0d1f2311940cdd9d11dc9c547','fccc2776cde92546a923e6467acaa729ae92ca38a40798899e1db3fa95670aa9');
INSERT INTO blocks VALUES(310385,'2aa6a491a03a1a16adbc5f5e795c97ec338345cfdf10ff711ffb7ac3a0e26e28',310385000,NULL,NULL,'6114e98e0004cf0f9472fce6bfa6bb99ae38e57214c8b134f30da1d62399f6ef','705bf51a94d6a87d4cb8ef178f579c30c94ff986beb62330476980e0333f7d92','36ca02dea840d19dfd63749776cd33e16f53d86e0851b6dcebce118584794b12');
INSERT INTO blocks VALUES(310386,'9d19a754b48a180fd5ebb0ae63e96fa9f4a67e475aeefa41f8f4f8420e677eda',310386000,NULL,NULL,'4c52d59ade1bd2068e3b75b8b3cd1d23c6a94b6437f7966d10f5a07bf8f630ff','32a6072eff4c95e7c2f33b3cfcd9d1a42530638e81c8c6f6584498caea3fa154','dc0fb6c9fe2813668575aef5a13643d28f999d225319e248aa5f5b1edba1b495');
INSERT INTO blocks VALUES(310387,'b4cac00f59c626206e193575b3ba9bfddd83bbfc374ebeb2838acd25e34a6c2b',310387000,NULL,NULL,'327e9a842233568888998ec1456b6f78c093b47639707d44e6336b2bc18d955f','1e7a71aad9f1f639f9f8eac20c3140b0a68a6d6dc8e59774c4e6d49107a4aaea','c08f0ea4b81338211dcdf6c81f72811afd6c2f2b35313f3a89e3301b83801615');
INSERT INTO blocks VALUES(310388,'41a04637694ea47a57b76fb52d3e8cfe67ee28e3e8744218f652166abe833284',310388000,NULL,NULL,'6efaab188a5cae39ef547a804f61bcbc2be4881e0569f49d7622b407f6860401','d9c1c7c574c90e1778a9f4d624c0004490f4bc06ad3e33fa57b70ef1d76bab8c','c98cd3b3cd88e4e0aff9592144719edf80c7d6adf3cbb5a3074bb28d4253b5ed');
INSERT INTO blocks VALUES(310389,'3ec95ae011161c6752f308d28bde892b2846e96a96de164e5f3394744d0aa607',310389000,NULL,NULL,'89c686d5d973691a7281268c867f837b86b140a05f16f12302a3cdeb3b6a0ee9','4c0605a5d783db4dfda6da44cbe3d09a9557fbe27396ffa8818afb76be013769','4b89c72af72bee0e01a49293a3925a929bc5c182393b38e3e31cd37c4f38a450');
INSERT INTO blocks VALUES(310390,'f05a916c6be28909fa19d176e0232f704d8108f73083dded5365d05b306ddf1a',310390000,NULL,NULL,'2c4eceebb94d0c7a7702478d9547d1afbb42ab5ecb5ae6271a3f69942bd77e50','82f258492e7bbdc8b4a48e1b3ea743799d941b4f41c960cd7192f9aa6f016cfc','5e4255e5fa6cf5e3910e389174da972e92dbad2313ce448c2a007e66db1e7af5');
INSERT INTO blocks VALUES(310391,'fc26112b7fdd8aaf333645607dabc9781eac067d4468d63bb46628623e122952',310391000,NULL,NULL,'06397124ee2a1bcb9104899469394855d4ecccd1a08626d650bdf3169e227831','73d54d17eacd02a45434413572bd8f6ab38031e31beb05ebccdf9584377b3100','3b658359acd5e75c6072072a7b0893dd6ba5762ecb2b0e7457c8591e1eb79146');
INSERT INTO blocks VALUES(310392,'f7022ecab2f2179c398580460f50c643b10d4b6869e5519db6ef5d5a27d84a1d',310392000,NULL,NULL,'44974b5fec0be3a2958d39f2d6824a2e82733f873a404ec9887178c620843149','6e56034edf1c00eea3708e3c6814aa27e022eafd0f3f4d32dcf401c92307814e','708f697cd5e79020be455a387ab604a398deae8cd77356d7686948721b7a82b1');
INSERT INTO blocks VALUES(310393,'e6aeef89ab079721e7eae02f7b197acfb37c2de587d35a5cf4dd1e3c54d68308',310393000,NULL,NULL,'1863677c0e552344607b1af3eb8ef8f4fc6b2a73d63eebb3e9928302c887970f','97d6866c6087cd170aebd91e66bb74de451e07e441bb655a1b76809592bd6121','56df2eadead061ba276a7f6184ee3526524a69ad4570b34e7c966e3699a4cee9');
INSERT INTO blocks VALUES(310394,'2a944743c3beb3bf1b530bd6a210682a0a0e9b0e6a9ff938d9be856236779a6f',310394000,NULL,NULL,'3838ba6e84376ed8dffb3fee9b5928d903952c0d8a8ad41ab63a9651a1c8c770','9e442e335846e51ac2fc409601b8b7d4e5744598b1674bec7307cadc424d4852','a76474ee7daea6494bdab4642e04e0833ce6ed29414afb5f5486c1f9c4a29ba2');
INSERT INTO blocks VALUES(310395,'19eb891ce70b82db2f2745e1d60e0cf445363aaff4e96335f9014d92312d20e4',310395000,NULL,NULL,'872367d61f81cddeb555da5f9c4f46a8ac57c24629ab073094e407a4555a8555','6ab652ad1822e70e6b1aecc59b066f193f0357df3e422b0024871154621ed6b1','414254fa3abf04cba6d7692903bbff3cb68435fa10dceb1f8d33d23f84419bb8');
INSERT INTO blocks VALUES(310396,'aea407729ac8d8e9221efd9d70106d14df6aaf9f2f87dc6f490835a9caadf08e',310396000,NULL,NULL,'b9a9eaaf1cf6cfa4ae5b0f314812a9a2346209da0b7ce57e16010d2a01c0092a','3628f1d8295427d6f0b8fb1f406c14d25d2fd4b4e0c942f34bfb9f7188a41eb6','0d2cfea605b51ec4d298575d82449c51f597f5c076817ffbba407893cd409c76');
INSERT INTO blocks VALUES(310397,'7c429e56a19e884a8a77a759b52334a4b79404081b976270114043ba94d7985c',310397000,NULL,NULL,'b61f36bcc934a18fdccf7806d41482684ca129801d0b9ce7815dcd488fc49a66','dc3aa50f054392f55a71afa248d2d66d79c61f4b00706d41fc9ca17e38f281cb','da2d3d0fe608383f176435818d0dcf68926c90f565dd268924fec1c7ee0f80fa');
INSERT INTO blocks VALUES(310398,'55c046db86dee1d63c0e46e6df79b5b77dfd4ab2ff5da79e6360ce77dd98335e',310398000,NULL,NULL,'9446476e123e5dd354682c60591cab8b712c30df9080dde756246eef45e21df5','0cda903e3c1993cb52272896aab12c7c40cb73f9b012cf626654a447c8f8e439','adfbb0ac627ba88a9a0357b1ec8afa933220283f6cf6d1ffa56d673a515fd701');
INSERT INTO blocks VALUES(310399,'765abc449b3127d71ab971e0c2ae69c570284e0c5dacf4c3c07f2e4eca180e7a',310399000,NULL,NULL,'50d288bca09d446f56544fb1ec50d613bdf156488468ac92d433425a3cab0804','d30f04f294b986914247dbe779f5885ce9cf969d6d1711cb44df7aad1ad0aadf','41d628357e3f4aa86106eba62da93b7a226ef47c821aaadbff194e8725b528f0');
INSERT INTO blocks VALUES(310400,'925bc6f6f45fe2fb2d494e852aaf667d8623e5dae2e92fdffa80f15661f04218',310400000,NULL,NULL,'349a24fd446727bb1793ccf88fc569d20eb680c10e506fc25b281ce6ec3fd7bd','ecc1222fd6d221a251ab24c8da856bdeb5a0a9bbfbb1dffd3d182ea9e8d53742','8d98dd94fc1a09def54a13ab57706ee93c655290e5e7142aee265a69267ffa6b');
INSERT INTO blocks VALUES(310401,'f7b9af2e2cd16c478eed4a34021f2009944dbc9b757bf8fe4fc03f9d900e0351',310401000,NULL,NULL,'52c06b68cad19608420b73476a73b411d0327382b92bd454cadf1b8616eb17a5','94ebe0af7e0b24762a24c006e2206d4f484bb52b07eab32265cdd81b85ac6828','642cdb4fb0fffb02445d69f5270da0c1ecf300dfa00e04b48e581af84303562c');
INSERT INTO blocks VALUES(310402,'1404f1826cd93e1861dd92ca3f3b05c65e8578b88626577a3cbad1e771b96e44',310402000,NULL,NULL,'8bf64213a454c62dd4b0dcd7dfa298da0244a6aa7ae6fff98be6f49d50d259ab','3d15c917c31f4d0e91a13dec299cfb01f8d939e17c5e4a80606be2c980839fef','9d735ba65f5aa5910933381d164d6d361b74d9088f52e52f7ab7f2856a2e9086');
INSERT INTO blocks VALUES(310403,'f7426dbd4a0808148b5fc3eb66df4a8ad606c97888c175850f65099286c7581c',310403000,NULL,NULL,'fb2a365372522d1442792cb38e1a4167eda2612ef442c776749097a3d541a827','3d223403d3110bd58d9c125deb87fbc7f96dcb335df9f74dd4d674a6e9c19e7a','cb669e77e7b64e9dec77dd585f29d6ede9285735b9bc0f86003caf56a8156d00');
INSERT INTO blocks VALUES(310404,'401c327424b39a6d908f1a2f2202208a7893a5bedc2b9aff8e7eda0b64040040',310404000,NULL,NULL,'47f96d798df9cad17667be908ebb063ab9f79d947784a78189d247e626864a5f','02aeee8f882406e647f0c3589a0a5a4b1cbd17c173a4f53bf053a045752550d0','c37d3bfb1a982656316e0f97cce9868c1ed13e6e0d110b6f23a7a3c71ba99be1');
INSERT INTO blocks VALUES(310405,'4f6928561724e0f6aab2fc40719f591823ca7e57e42d1589a943f8c55400430a',310405000,NULL,NULL,'185780205a9ab241bb0656799fd0d5942c1e3e5854abd1d06573da550b04b096','3bc49aa0642bf8c7b08149a98753062dd4a7074479cc45c7790750a1c932415f','26f4bd57aedd2d6df87e76bb2cbcc0435aac11bd37e01d6e3c25fc9f835c3a9f');
INSERT INTO blocks VALUES(310406,'6784365c24e32a1dd59043f89283c7f4ac8ceb3ef75310414ded9903a9967b97',310406000,NULL,NULL,'367b9de2313c5f7fce0c2dc2b4a8e2bc059f6881bc924f7315e8e2ca61728a59','ff0e3687ea06860dcda7cc54c93e691098a60865f8f833100bde93e12086b309','3bf92bb0574a656573368fc4254202df912e14b70c7b3cbaf9c7e672f8f678d5');
INSERT INTO blocks VALUES(310407,'84396eb206e0ec366059d9e60aefdb381bca5082d58bffb3d2a7e7b6227fc01e',310407000,NULL,NULL,'2bdbd79575aa2ff52ba0cce3fc1a1aac6120d598a8ab0ff3925e1395e6cad2d1','8e587457d1b90afbe36b33f0a5773e267225383c5bd2ed6918c1dcf82086ce5a','8ab2a7516dd798832e76e56391fc74a3374f7cfda31fdf4242290d25dbea8f5f');
INSERT INTO blocks VALUES(310408,'4827c178805e2abae5cb6625605623b3260622b364b7b6be455060deaaec2cda',310408000,NULL,NULL,'fcd0edef8c4ae9517a6e793a2742c598de38c122829b7a7aa265310417ac92c3','d2dc558098d3bdb921ff92fad2f49b13577fe38eb4c7da33fcc47bea49cf049c','a96f3db98f890eeb5a6406df8e5668966edfce10531407985853a937aee0be8d');
INSERT INTO blocks VALUES(310409,'01a719656ad1140e975b2bdc8eebb1e7395905fd814b30690ab0a7abd4f76bba',310409000,NULL,NULL,'5b663c40873af21ebc721f2689e2c57a2c787fff579c58f033bba75910a64837','2d79e5aab5e2745305eec25b7b1bc6e8d0bfa5c4b52db0e947aa12aebe4d3927','c6107c6fbcd0f04381f9b6081604a5470e90a5bc8904ef688c5de2fcbe29e40c');
INSERT INTO blocks VALUES(310410,'247a0070ac1ab6a3bd3ec5e73f802d9fbdcfa7ee562eaeeb21193f487ec4d348',310410000,NULL,NULL,'93c5a33931b2a33933bc286d6987b34730c0677460e4875d5c032ae86c2e01f0','81cd72abe177f166715104b57b77746457a920d907cea211d2a482b7e3b2d604','377041b107a6d6793a4bbe2495cfd3054465ab374be2a999117a4ca64f96bf98');
INSERT INTO blocks VALUES(310411,'26cae3289bb171773e9e876faa3e45f0ccc992380bb4d00c3a01d087ef537ae2',310411000,NULL,NULL,'8d98498f89619a2e334e9ac69bf8ff37251af6431d9bb6d1ea8bbc404c5e560d','4d55522550129a6b10628948ac7c58f1015805c7fa295cfa5820b8c744f32ced','d8c0ee51f8ac90124daac1aa7232267c3abb12be968b47062a111eee9b92d280');
INSERT INTO blocks VALUES(310412,'ab84ad5a3df5cfdce9f90b8d251eb6f68b55e6976a980de6de5bcda148b0cd20',310412000,NULL,NULL,'a16a650c4b63ed783e7229980be1177da867c188a5039ed5c58b9717f6ccf634','b5a46d89683af4dca32fe5bff0ab65e83ef2a1838ac8065e48f48ccc2a087ffe','d56330bb03ec71e2dcc50040577536cac93ba860c95c5e7dc2917c4ebd7082de');
INSERT INTO blocks VALUES(310413,'21c33c9fd432343b549f0036c3620754565c3ad99f19f91f4e42344f10ec79bf',310413000,NULL,NULL,'768577c1a7c2cf2cc19cd8dbe823f1bdb8a222daee4c7ac7b5ead6633040c283','0fc6939adc728f46a770e08403ed48e8e979183eb80f5e0e280f9300eed22158','dfb3b439e7b07fae1d4a51952c43bd95215767aed27ae709f372f29c9f528903');
INSERT INTO blocks VALUES(310414,'8cff03c07fd2a899c3bcf6ac93e05840e00de3133da14a413e9807304db854b6',310414000,NULL,NULL,'906c491f164877c31002da41233c237d0d4a945a0072406a7b7d13df74be7eec','9579189905447fafd8bed181716c29cfe7a277c4625dd4f42ec28db150a30a74','90e1b3ba5306164560586c9b5b5e031b4b5f8a7559f7892773f2d413ae60135e');
INSERT INTO blocks VALUES(310415,'dd0facbd37cca09870f6054d95710d5d97528ed3d1faf2557914b61a1fc9c1cc',310415000,NULL,NULL,'d27f99b4a67dfc910d3b932f97b7299779f245e95f871140d3c90f13cc6e506e','d222221825fd5c62fdd2a08512a16213ecf1d2a120b5630c45c28dc69e9cdcc8','0afdd1afea5277ade54ed0219434bbc42e705d5ba1f3823319abe4cdfa3363cc');
INSERT INTO blocks VALUES(310416,'7302158055327843ded75203f7cf9320c8719b9d1a044207d2a97f09791a5b6b',310416000,NULL,NULL,'90fcd04c508a9821e0ba0ed36cd7cfadd1d3c95116e3f52ad69f98d3d14de571','f0faa7e1cbde7df58563a896d08aeb510c0262e89c310221ca61203df080a1d0','fc476355b2dbd8998d7e50145c3ea8454cc13273b339fcc9e6d87f0497997d3f');
INSERT INTO blocks VALUES(310417,'2fef6d72654cbd4ea08e0989c18c32f2fe22de70a4c2d863c1778086b0449002',310417000,NULL,NULL,'19cbb26c6d24df5b110a5aae9b53a911a61b2086dde926273a1b0f66c1049e6b','a488fb2673359eed37e685dc8bcd59f36d69d1e9b1d4498b58b9b34821802cbc','d28006350e0924a8d8bd02b67a1a8998083576c8f4bd5e0da69f6ef88290955d');
INSERT INTO blocks VALUES(310418,'fc27f87607fd57cb02ce54d83cec184cf7d196738f52a8eb9c91b1ea7d071509',310418000,NULL,NULL,'2dc971d2db4e92e2d5dcef124bf9cdad33c41a71d6ae3db80297cb2257911f0d','bc1d6861e3e09cd2827ceb24681a0d1e70dc01673189b98bd80c2d4e81cf7870','7599aef146edfe44ff80e20b6ab26b218f623a9661bbf0a791f43e40491ad253');
INSERT INTO blocks VALUES(310419,'9df404f5ce813fe6eb0541203c108bc7a0a2bac341a69d607c6641c140e21c8e',310419000,NULL,NULL,'7ad2bf141622a0db4b27b1f4dab4857d1595e3f746a4113992850a680ebf1f37','71ba5ac13dd8dec56e1e7e4513986f06400b9aa097db69f4eaaa3f2e132ba2ee','8074e2a666743851658831a6571153c68d3d9f0857a1be8267f160a9507a5810');
INSERT INTO blocks VALUES(310420,'138b3f1773159c0dd265a2d32dd2141202d174c2e52a4aeac3588224a3558372',310420000,NULL,NULL,'3602b26268d1bd3fc5f08f170e9767ff07c91f6976a1c342dc6b24f7ee98c509','e73718c06bc1b45dffbe1f07514fbe0529f39aef08010d00c7d1e08e6aeb0437','5c33ff6a7b3dbc8dfe0fd73cbf5d3de4bf96e7995a4c7bc1e3d353de70bb098e');
INSERT INTO blocks VALUES(310421,'71fe2b0e02c5cad8588636016483ddd97a4ef0737283b5fd4ab6ea5dc5c56b9a',310421000,NULL,NULL,'1c1facfa3852b33c173a08d06450335a2b230541c60973a154e8dd864f3c3c8b','31af39b5a45ef977bfdfa71b0c6d27dbcf364fe3411e81c4547854362a90a808','da3d614ddd8fe76c97970c8c386d3a9b4bf09b0a16d32406a8c473904e4feeec');
INSERT INTO blocks VALUES(310422,'cd40260541b9ed20abaac53b8f601d01cd972c34f28d91718854f1f3a4026158',310422000,NULL,NULL,'e788123aefd1129554fa2c166dbd06ce68f913730183ca73cf248c1f5284eba4','185e0fdbd2914aadf918e6d3db16c36cf602a009523cfdcd39a28f362b071d29','1d72864849262bbf605f638da302bcfc5fd0f706ec5e1fd62f978043252ea967');
INSERT INTO blocks VALUES(310423,'6ca0d6d246108b2df3de62a4dd454ff940e1945f194ba72566089f98ad72f4db',310423000,NULL,NULL,'ad445e5351af8739b2f74cbba8b44201c20ab55ad1db064402614fb97f35c375','3ef50ec8a5b3bd63486ee2064f855c457fbf2138aadde307369716bfa001d274','76f723b6ef30d75a0c92cfa14cc272f018f9726380fe2101ece6071a410a46e2');
INSERT INTO blocks VALUES(310424,'ed42fe6896e4ba9ded6ea352a1e7e02f3d786bfc9379780daba4e7aa049668ad',310424000,NULL,NULL,'e89872ed802fe4421844882958fe6384cf21a85a6dcf10db761e2bb4a77ed24e','155fdf08172705f79733f645039185bd0b98aa6e1e7d6d530e42120fe130ce10','27df242657170075a9e06ce3bb9722eaeb8f9c4822e0d83eda1992d74e2754a2');
INSERT INTO blocks VALUES(310425,'73f4be91e41a2ccd1c4d836a5cea28aea906ac9ede7773d9cd51dff5936f1ba7',310425000,NULL,NULL,'29e595e9ac7717013cfc8d12255496192234abbddd8a66762a5eaff0c49f3750','29a2cb76a4f1c485141ada25261d065099c28280919cd156cea4c81015c80834','bbd02ad059b704ae4c0e5b725625a883235e61310dde18200bf67bfe225a2619');
INSERT INTO blocks VALUES(310426,'9d28065325bb70b8e272f6bee3bc2cd5ea4ea4d36e293075096e204cb53dc415',310426000,NULL,NULL,'9b9509ce7b7bf380f4d030604810a755c71fabe27152be990997a6a9db37ff15','35cfff0433434b96a1f57f4c6c6c86eed76a1323cbe89c791d37df2c2d4ee4e8','b88c73738577b84f34a7ab01dfd4b18dc0ae6b4106a2262da1107db96f5ef553');
INSERT INTO blocks VALUES(310427,'d08e8bc7035bbf08ec91bf42839eccb3d7e489d68f85a0be426f95709a976a2a',310427000,NULL,NULL,'f1b834e2a380f1b9a78c592acbe78ec809220c620e15f296ab8d7ecea6cd392e','13805fff04451ca7f452b1077825bbada552848cda5d1bdb2b37c55c4fd1810d','5a686d71ea59a75515a7b47c9111ded4281e734b8332cee5198af63964efd56e');
INSERT INTO blocks VALUES(310428,'2eef4e1784ee12bcb13628f2c0dc7c008db6aaf55930d5de09513425f55658a2',310428000,NULL,NULL,'9e963a17fbc4a5c20d48094f1459959033520f92d7a8bc044b71bbffb8dd173d','bfe2ceb2c13be29268e3d14b542114e0b5a458daa22ecc81bbcf25342512b76a','880ece95c2fd90532abb39b3b56b7e566010fbacbd7b973fdc0f20dc528fb692');
INSERT INTO blocks VALUES(310429,'086bfbba799c6d66a39d90a810b8dd6753f2904a48e2c01590845adda214cf8d',310429000,NULL,NULL,'ac8cfd965b9c53f32731a3e0fcdb6df5746d646b02c88b5201a674125e37eed5','491cb9951b030a518182fbb4920ba8d61cac4ac3318d3a2bbb0feea3ca66d9b6','22f99988475a3a8b8566a0086ca88944b1d59308a172f91bf8c7167283fda662');
INSERT INTO blocks VALUES(310430,'870cf1829f84d1f29c231190205fe2e961738240fc16477c7de24da037763048',310430000,NULL,NULL,'33654e32dfd41ff3a5744b57fd2483a08a2b4729c18ca54c3ac5d95a1bf0ef21','1a90c5f0272fc16538cc5aa1034b214b883d06360287dbdb3a48e1dc0731cf85','ada5d86618f15904b131fbc279b6d868fe376ecd92ca2b2aeef590999cdb2718');
INSERT INTO blocks VALUES(310431,'20b72324e40ffc43a49569b560d6245c679e638b9d20404fc1e3386992d63648',310431000,NULL,NULL,'ba8837c811ae87981cc37cb49438d958fa58dfc5a95824040f2fd088465406d1','f3842cbaa9d77f8a073e9f07c965e516849856788e42c6a3dc463afb2b3d9564','a27482154e55267898cddc7fbc119780e19d765735f81bed51347f2cc521ec6c');
INSERT INTO blocks VALUES(310432,'c81811aca423aa2ccb3fd717b54a24a990611365c360667687dc723e9208ad93',310432000,NULL,NULL,'7864019cb0cbbcd895154421183d6acb932b1d64441103b913d52469f656655f','075ca8f015218c3159816a40ef6c46cc6d8c778591dbcd78d492708a6526d073','42c3991ef2cefe0e97c3b38edd02e0643a141426d6394b3186e92b36c8f5ebb2');
INSERT INTO blocks VALUES(310433,'997e4a145d638ad3dcdb2865f8b8fd95242cbc4a4359407791f421f129b1d725',310433000,NULL,NULL,'a6da92ef0df7d092de09f2f8d2c99ff65ad74e2a0bd2ea25f8335614372f5279','f87c7910ae615a05e5e1d49ff535d6d75414309404459a87c326ef7c3aed818f','30cd7136ac7ec17ef77491fe524416443fda7d9afdb396a91954dc8d28d0a059');
INSERT INTO blocks VALUES(310434,'61df9508e53a7fe477f063e0ff7e86fbb0aef80ff2ddedc556236a38f49ac4d8',310434000,NULL,NULL,'e288db28ac6a42822f85fd042f65b57378bc6cc2f8616edfa88143d7b1c9ddcc','6f4f554b96f7bf1613a166b0586f841d3a66639dbc3c8daa3cb2cef38dedb294','aaf3ac3a5a780aed116d8bc0fc539bdff42e84a1b1cf129e30c3d11d9086e867');
INSERT INTO blocks VALUES(310435,'f24cf5e1296952a47556ac80a455a2c45da5c0dc2b388b51d235a3f741793d5f',310435000,NULL,NULL,'e87af314e8d7a5f2315ccc559d7c2255c008ba63aff017696201db69344d423f','b16076cf0057e6b1f0b9ab16a2536910c81049040ed7ecffe76244f2f4ebd859','ad951fc6c157ece334f7da44a59f8e14056108bf5ddd96cba0dc0191d4414eae');
INSERT INTO blocks VALUES(310436,'a5e341ba92bdf9b3938691cd3aab87731eba5428bb61a804cecf9178c8da0c19',310436000,NULL,NULL,'82327b93bd3ffcdf797bc2f6470b9c8c5101e54b924ec5f141a31356aa8865c7','05eb45c27afaa60e0e2efe796e12ff7b1df102de8a355f88d131e8fe370c18e3','aa2257aa4aa6eab0d7c13c295f6e9e479403af1563fa51817114e647b2fabcd6');
INSERT INTO blocks VALUES(310437,'9e18d0ffff2cb464c664cefc76e32d35752c9e639045542a73746f5ec2f3b002',310437000,NULL,NULL,'70d86f9ef8df495474de06b94e1857693c73d9ca3528356b82553a52fdce0dda','fe1c9135019c152758e5bf6ce5b4e60b72a64779d506de91191b58ca89007a50','4a0039e686ec4f1a63b106ae8dcdaf0df7974855f873681e95feb0b65fb774a4');
INSERT INTO blocks VALUES(310438,'36be4b3470275ff5e23ed4be8f380d6e034eb827ebe9143218d6e4689ea5a9fc',310438000,NULL,NULL,'44b90478e32373205462f0fb212da636b31db6dfb99a2b56923beb97a3a64722','e9542b739553ee2c768c57a005bed8c5a2b7502118f5cb9d85e1da3ff2fe745a','df9acd4f9f632e594573bc52885358b7baaa99ecd70e7390940e0e3fc10498f7');
INSERT INTO blocks VALUES(310439,'4f2449fce22be0edb4d2aefac6f35ce5a47b871623d07c2a8c166363112b2877',310439000,NULL,NULL,'66b791b9deb7d2fc8b075f41d712e300ffa9c46ca9d6f4e7cec6429ca6a65163','0c3bd0e1e95c3937d18bf5a4048d7ac0ca104848f59015bfcafc45582f24dce7','082aaae22d71f16493210e3e1630c4bdeee15f21ebbbd7ca3b824c596633799c');
INSERT INTO blocks VALUES(310440,'89d6bd4cdac1cae08c704490406c41fbc5e1efa6c2d7f161e9175149175ef12a',310440000,NULL,NULL,'5baa10e1659182ba4511f87f08deda38d5de3501c63efd376604cc199140d27c','fddf3967a7ba3728f35b085d14072da3333d9e370b102a26f0d15f544fb6b4f7','7e77044a264e27a683234d0a5ce3904f1f3ade8832427f8d736737b6133bd4f2');
INSERT INTO blocks VALUES(310441,'2df1dc53d6481a1ce3a6fee51ad4adcce95f702606fee7c43feda4965cf9ee15',310441000,NULL,NULL,'2d490229fead1b15a8350da7bcc83c483dae06e4a2f574c6e8fde248acd449d6','8e31ff31033e5888008a2d108f489fd7bc6fe7a54f3a6987a17e36a120829ad5','4941860097c6d2e7e0811a3f636234331bfa5bcf5bd1a254198c6dd404db854d');
INSERT INTO blocks VALUES(310442,'50844c48722edb7681c5d0095c524113415106691e71db34acc44dbc6462bfec',310442000,NULL,NULL,'a3728bacfbdd289b7af24248b9bdacd5643bd5412bb993f5380278631eabb9e9','b75b1ef0b4251721c24d6885e6c8b9ea24d5b94d5c3ad3f1acf12c1a65316f72','2dfede24657bf20b8ac1f76902cc6298a62c5d9db003f34aad8ab55b55d91e58');
INSERT INTO blocks VALUES(310443,'edc940455632270b7deda409a3489b19b147be89c4d8f434c284e326b749c79a',310443000,NULL,NULL,'d829da764f6397b22a6b97ef396b363ef2cf071990df2dc9c0d03806db6a46b5','67507f84022024d761b084e0dc5bcf9120bd18550531cac1c9301f0ded4f729d','550f50ca729f2848e4810b03c1bb4fb9680b647bdc955f3e011d6bcb561be4a7');
INSERT INTO blocks VALUES(310444,'68c9efab28e78e0ef8d316239612f918408ce66be09e8c03428049a6ee3d32e4',310444000,NULL,NULL,'ef53249bf0f13e1f2073b815c8d8da3ab744b6d277b29ddbc0bd68bd006af34b','b77e3bb29dcd8255e03ceb599b319a3a48ed29b35991e26a6497273ccb89a1f6','0705e42de7257d4c16fda0c3b744576b6c94a60fbda400f23e7a9c35f2db5026');
INSERT INTO blocks VALUES(310445,'22a2e3896f1c56aefb2d27032a234ea38d93edf2b6331e72e7b4e3952f0234ef',310445000,NULL,NULL,'7e731cda90932b2b4844abdbc3ff60683173104e6c72ed81c65d9a17fd4872dc','00212e20f35e645f7e5d3e822a3c5815d7e5ce7a0f87d54a9da70b89e3427039','93ac6da582ac0a5af2607fc2d1912a00c6982d35742135d36e5f52032ee2842f');
INSERT INTO blocks VALUES(310446,'e8b0856eff3efce5f5114d6378a4e5c9e69e972825bc55cc00c26954cd1c8837',310446000,NULL,NULL,'db55bac8025e95a567ba984f36dcb09357aa3e9b8706bb594e669b628d4e7204','c9e333449bb4ea19f4ee17da1618dfcd79e80433e24f411cdfa551c3a89ed8c9','36ab784a8a2a2e8efc8328b5d9a96f127c4758306db46dfedf28e91782f28607');
INSERT INTO blocks VALUES(310447,'3f4bc894c0bc04ee24ed1e34849af9f719f55df50c8bc36dc059ec5fa0e1c8a8',310447000,NULL,NULL,'5cc4fa447cc291ffcce7be3c4f8fc70041bf8af5c2dd591136d4a449095d2570','6ec48edfdba37b2062599cb802d3c54b1bb4ef6849fb0f36d6f5ef3d994a38f9','9c3b3e150ab302109f06d271311b282b178209ec9c9e104e4c7c2f4bb4c133a5');
INSERT INTO blocks VALUES(310448,'6a6c7c07ba5b579abd81a7e888bd36fc0e02a2bcfb69dbfa061b1b64bfa1bd10',310448000,NULL,NULL,'ce49854f4493c163bc891888f920fbc6dd8855c30870beb757df69b33de52633','ed63e05f27c5d1fa9cf5b1f340d86c2f3c1f07b8136cdc05097c83c2d4c184ea','bb5da4ebd3c41560d1c5b9af8c18dda8022889b8408b9fb562b1de3ed6170923');
INSERT INTO blocks VALUES(310449,'9e256a436ff8dae9ff77ed4cac4c3bfbbf026681548265a1b62c771d9d8e0779',310449000,NULL,NULL,'84557595cf2067a95924119b8ed5fea114acd9ca1b0df4dbe4ae5181a739b5d1','11f314fd39b6ef68aa1e66ea1e5f11a587c11f7a3854de67956bddfe2f9d364e','2b02fc5a358568f962ae6e5fcd466883ffd519fb5169300184f24e92a48a34b2');
INSERT INTO blocks VALUES(310450,'2d9b2ccc3ad3a32910295d7f7f0d0e671b074494adc373fc49aa874d575e36a3',310450000,NULL,NULL,'0e3b252b73fb652f904780da9fc59d1081d712337a9b15cf1a56ea72fbe96c73','13832613928ad78482180fd662c783a272cfd98b95f21236d263969911c703a9','793cc32174ad20ececb290d66cd8c3293bdce17df5cfaf1b4db3085c2c482c53');
INSERT INTO blocks VALUES(310451,'55731a82b9b28b1aa82445a9e351c9df3a58420f1c2f6b1c9db1874483277296',310451000,NULL,NULL,'790eccd04e24e5f10f843d63bbdc1538cf1aabb0e8e6c862104be0ef845f603f','2647dd68f0eb594102e9229885b8ea5459087075a8811c36b1f4b434bcffc48e','208df0d4f7dd9747b9cf12fb2f1908851fb688277b7e42d4cfaf1889fef4213f');
INSERT INTO blocks VALUES(310452,'016abbaa1163348d8b6bc497cc487880d469f9300374a72ecb793a03d64572aa',310452000,NULL,NULL,'30962129b060b63050fe8f249592587d74cdabc4ebb5680230a280da880c8586','28db01ca59371d959cd10d08a308ff627fa0e0f9b19ad368cb9bab79e7c53285','af6ebc7e5645c332b5efe6e9097544329f33bfe4995fc79549536b521228c89c');
INSERT INTO blocks VALUES(310453,'610be2f49623d3fe8c86eacf3620347ed1dc53194bf01e77393b83541ba5d776',310453000,NULL,NULL,'56f4aa1086d8985a00cc295cf9618d976e69ba426b0c3d103bea6b47b58e4355','05d747aafec3f0a325938ea97d599f7743b95855a1bf11d4a9e7a8c866a5945f','2335ddeed0ebc56e7fed60072da4b9bf944cdada4a9ced5bee14d322bdc35f93');
INSERT INTO blocks VALUES(310454,'baea6ad71f16d05b37bb30ca881c73bc48fd931f4bf3ac908a28d7681e976ee9',310454000,NULL,NULL,'38d14a206003b812cbaf5f200235dbe12aa6a674e5f3379cb186a781cb5a5654','514f4a014e0521737cfefa3706c4b5d115afd2217b5042283a7d14713e74e3a3','69e7d9315670248c70e55b384be91257160250a85b699b43d8bd2fbd540dab0c');
INSERT INTO blocks VALUES(310455,'31a375541362b0037245816d50628b0428a28255ff6eddd3dd92ef0262a0a744',310455000,NULL,NULL,'b2ff303a67c05bc12fcdfdb774ea4ddc690434c3371428b3416d38105f265f28','094ff9720f563fa8ec0f9aaeb34726a94b4dee90614aa813077cec063e28e3a6','6567b13d6b83532d343495fa427d326be83780da82512840cade78b8ed2e49b4');
INSERT INTO blocks VALUES(310456,'5fee45c5019669a46a049142c0c4b6cf382e06127211e822f5f6f7320b6b50fa',310456000,NULL,NULL,'6cc16b442fd7758ed7bae9f50367fa60debdb5d81bffc5abccda044573aeaf15','1ef9b59e519577d520308a9e52d72ed791248d8542164ab1a5f8bdb56a1dac95','d8b8c9030377af3d87ef85d02e74862633cd01cfb30ef9558d496632dfa92e6e');
INSERT INTO blocks VALUES(310457,'9ce5a2673739be824552754ce60fd5098cf954729bb18be1078395f0c437cce9',310457000,NULL,NULL,'8fa0401d245b1b1e8b40760a54f331564d8597e242462ec412878e36a9b06800','5bc39dcbcc4189633fecc38734468b78f593a51ee0153d7e5ed8c944091e6eb4','2284f485788aa5d1edf2c342b139ff6404cd3a5b023a9ecbf41369a9c84b334b');
INSERT INTO blocks VALUES(310458,'deca40ba154ebc8c6268668b69a447e35ad292db4504d196e8a91abdc5312aac',310458000,NULL,NULL,'520f92700e31b8a35260a280ae11bf8668b0e09d34795a9d88678f2977e19f7c','3bfa531cc0774651e577ef9e853b15e6c216fe59890f411266aa9528001b41ba','bf9ca2a4c5cad74c1e4776a17577a55e16fd888c90be99870db46874dc014f07');
INSERT INTO blocks VALUES(310459,'839c15fa5eea10c91851e160a73a6a8ee273a31ab5385fe5bd71920cbc08b565',310459000,NULL,NULL,'d7f728b78228a914b8767a6caeaf2267e9dbd50490a27f6c23bd96060eab8ee0','290c0a0da007f2274d9ff770895296a1cdf9cee97fd5282a5926ac0f80e2cece','f7f205afb88b56fcbedc58837b4f0bffa74e87fb4eab10edec935b905199ebec');
INSERT INTO blocks VALUES(310460,'9b5f351a5c85aaaa737b6a55f20ebf04cafdf36013cdee73c4aaac376ad4562b',310460000,NULL,NULL,'33c2b4c6d22888448a2458ff2ce6a1cfae5e858acae2a57e4cc0232980f8fa4a','4006c9e62dcbfddb69c8f7252cf5733faf28b1eab8025d9fcebd46e382157eb5','c600e5cb1f29668ea3a90c1accfd4e5abcfd95fae03dfac3ce97dc6926b7460e');
INSERT INTO blocks VALUES(310461,'8131c823f11c22066362517f8c80d93bfc4c3b0a12890bdd51a0e5a043d26b7b',310461000,NULL,NULL,'22426912d3317922912326da552af284677c9b76b6416b6c056668f27ae4f19f','1e286bb2e406516f3b4fc4acdd009a244dc9bfb8758729e9de8e7a1531f5844f','88d34589394ba92eeb180d4a916a386d93d4132a885e0764e1e26d34fbc093fe');
INSERT INTO blocks VALUES(310462,'16f8fad8c21560b9d7f88c3b22293192c24f5264c964d2de303a0c742c27d146',310462000,NULL,NULL,'74225b62e696aaeafbd4d6db40b41081c7493d9cc44984729d8619ff9450ce32','8d4c387877d1f94e6f57c519859f2e6f12823a353f85f96659457248e26ae5a5','6fed027a14861117828e670a563cdfe0ddf73f490e109f0fff0b373c5b306854');
INSERT INTO blocks VALUES(310463,'bf919937d8d1b5d5f421b9f59e5893ecb9e77861c6ab6ffe6d2722f52483bd94',310463000,NULL,NULL,'b970979bfe0d44ae2f21f7d98bdcc4ae37287b93cad9fa51f32a62337ceba0c1','cfa312c5c6e64e81d16b0e907dbb249571914777e8c75d2fdf729156e4812020','076ffbec2bf2d8e48f28dbc11d6dcf8d6f1060faf54a5e4a48dcf120f1762e92');
INSERT INTO blocks VALUES(310464,'91f08dec994751a6057753945249e9c11964b98b654704e585d9239462bc6f60',310464000,NULL,NULL,'00007a158b003fcca20c9fcaa8d73a556f0206bc9a7ab3e5c566ea1bda8648cb','cd0db3a177551cdac87042514af4aa3295ee8fee0672b31618d42e399cc0dec0','7fc2d06f190b8935d26cf7d7db20f6da472e22f4271dfbdfab5c3d2d750cd1b6');
INSERT INTO blocks VALUES(310465,'5686aaff2718a688b9a69411e237912869699f756c3eb7bf7c3cf2b9e3756b3d',310465000,NULL,NULL,'09c407870b056db90148a9e4cb8ada003898ff28c584bec6a5be90514758a851','68223a33a00314041719932ae8c8e764af2f1372363c547ec0e77f271094e666','49bfd7890067953c28d27b6dbce22e4452ad4caa6bc57b6bc2f0ede4500a9d2c');
INSERT INTO blocks VALUES(310466,'8a68637850c014116da671bb544fb5deddda7682223055a58bdcf7b2e79501fc',310466000,NULL,NULL,'23bcfdbb44d8fc2ae6a86ea073ab080158014f04516b256a70d846399e7383cd','1af58039da700a27e9b4ffeb50a2e213bee2f5adb003dd507704528294f034ba','2c601aba06900f8593d648a6d05246107fe17427834139d5ae82c26bc3debaf6');
INSERT INTO blocks VALUES(310467,'d455a803e714bb6bd9e582edc34e624e7e3d80ee6c7b42f7207d763fff5c2bd3',310467000,NULL,NULL,'a43abeddb61ad99d57f208cb0c6cc3e0b05a200009e6d90641a2bc7aac707adf','30f088bb3c56165bfd3ca49c11ce8820be14357c87a6beae1f444e1a6e4a2b79','7ce4ef46f1a22f29e0ad22c90c23a22c120707754b45c486be562baf0142ef45');
INSERT INTO blocks VALUES(310468,'d84dfd2fcf6d8005aeeac01e03b287af788c81955612375510e37a4ab5766891',310468000,NULL,NULL,'fc909facd6ba38fa0908fd49a6e2f25bd8284de5265ef761497b8a2d595344b3','9f7e8291898b19deb90cdbe776e3f7b727d88932df101845d09954bc7e41a997','2823ced5e77ce189b4551a746f3392178fb0b0adda0f056ab87fe1ddff309cba');
INSERT INTO blocks VALUES(310469,'2fbbf2724f537d539b675acb6a479e530c7aac5f93b4045f4356ea4b0f8a8755',310469000,NULL,NULL,'09f0d1c9bde8cdd63544fbb5eab46c2954654d32f3736f9975cf860588aa65cf','489bfd2030c277fc3de457028d48153aad9c968ef2471d1a8cc52124a3641208','52da1c8ee356b6cce9b025ea7f13c2cb1b45e190023690cf8bf6a9354bfb0e24');
INSERT INTO blocks VALUES(310470,'ebb7c8e3fbe0b123a456d753b85b8c123ca3b315da14a00379ebd34784b28921',310470000,NULL,NULL,'41832b12459e778621b8f576e597b9f639390338605b30e5be28423b016b199a','728aacec5ed7cdaab2bf1a42d24a493714bec86b3029281494891234094195d9','c4b4a8d94edbfd5608e4e2d4449134654a30a2d9ee30e55ce76b2953763bf97c');
INSERT INTO blocks VALUES(310471,'fc6f8162c55ecffeaabb09f70f071fd0cb7a9ef1bccaafaf27fe9a936defb739',310471000,NULL,NULL,'bf701017153742cb597353349c90ec66f790f222dd98d617d98a0117f1de3274','7080c8125ee17b3a71df6e2a14c987a52d10488e532a8790428d263db968551d','f4985c8f8d9ecd9a4bc7b232972535dd6c71a4a175049354a03b1af4c5fedc75');
INSERT INTO blocks VALUES(310472,'57ee5dec5e95b3d9c65a21c407294a32ed538658a6910b16124f18020f16bdf7',310472000,NULL,NULL,'2a162bbd5a20f89a39156995658fd0c4715881bc130922d0edf95b60ece60b9c','9875e8a76a715922e79fae0f647d7aaeceeb8514bd00ffdbb95749233082ca2f','602c84c3f27588505c7df7a8fa16293737ab339e112fbb6d1218344a78fe42c9');
INSERT INTO blocks VALUES(310473,'33994c8f6d06134f886b47e14cb4b5af8fc0fd66e6bd60b3a71986622483e095',310473000,NULL,NULL,'1ce10996ec9e37d8ddc204f038542c6781da88d2d45bae1952a88ab993b81e88','4fadaa8626e414659df5f6c12da6f77c2a5916b965e4684a3d0710f77e7a9083','e07912451fbb39bb58561d67356df2ccad4fd364eaa7dc380c057172bf186b1a');
INSERT INTO blocks VALUES(310474,'312ee99e9526e9c240d76e3c3d1fe4c0a21f58156a15f2789605b3e7f7794a09',310474000,NULL,NULL,'5ae424c24ca30aad5aca8298a13ae9371f55b15bc789c7731d833c6e7c7cb04e','01544dc3286fe263ae976053fa8340d418132e49c8f5b8e8f3bde437cc568f0f','0d1c2e5667dd7d78970cb4f611d1eabf9a826a6959469ddc7b72eb3ac54b90a0');
INSERT INTO blocks VALUES(310475,'bb9289bcd79075962117aef1161b333dbc403efebd593d93fc315146a2f040eb',310475000,NULL,NULL,'b9b257efe76a36c340629ceb265822dd10449a08eadc69667a8ea05af5c052f8','892a296ab82ad78c446e29a2c9a725897614deeb2c482e28085dd6bcfff202cf','59b6f690505bf51131151344751c3c7fb61b1f5176c336aa9f1159e6433742e6');
INSERT INTO blocks VALUES(310476,'3712e1ebd195749e0dc92f32f7f451dd76f499bf16d709462309ce358a9370d0',310476000,NULL,NULL,'070c06b36f3a77c04fb4bcc3ab1045e95f198f3f970846e59c35db0d03cdaf2c','32ec7b494e2f7362e9ba0cdf45f42f1058b5fc4038fc74af41cc2b3d892a4b6e','e157780674e83b003ddab2eef48beafc4b849c9f5888cd51b4ae138c26008f42');
INSERT INTO blocks VALUES(310477,'7381973c554ac2bbdc849e8ea8c4a0ecbb46e7967d322446d0d83c3f9deab918',310477000,NULL,NULL,'4954596dd44d112fd0407c215be3c9534a348d6f708ae4a1e66527d1ac2830b1','a3ecce0ad877906d0d171436ddecaaf8227a007376404aeb4cee024e1e871b37','134a4c71167aa887576b045664c7f2706c9a27c55085e499561f10106a3005e5');
INSERT INTO blocks VALUES(310478,'c09ee871af7f2a611d43e6130aed171e301c23c5d1a29d183d40bf15898b4fa0',310478000,NULL,NULL,'d9cac2e29863569bc96aaf022437906a534968a17bf965c54bf59931cd92e590','97c10533b4599b79f61e4dbaeb313407e43bb27fb3fcd2192dad94525acfa4dc','d02fef3c91fc2f9d807b452625f17db5386853e9eb9c0433fb999923f9718dba');
INSERT INTO blocks VALUES(310479,'f3d691ce35f62df56d142160b6e2cdcba19d4995c01f802da6ce30bfe8d30030',310479000,NULL,NULL,'2e48a89a55b6f368745e1c022683e93c20bdd920011518f18fd936f2190ac5e0','168fc39fb2353017e110c7d97338aef0d1aec1c6df62463ab38b3de3165e498d','3f6bdb6f5c06b1df678fb2beecbbc30a6add9c35ea797bef466bd22abd4261d5');
INSERT INTO blocks VALUES(310480,'2694e89a62b3abd03a38dfd318c05eb5871f1be00a6e1bf06826fd54d142e681',310480000,NULL,NULL,'aa54124d86e74bebd14ea481ac2a5a5186236ffe214747f1af11ac370565525c','a07bcce1f494cbc33a33195548f1e91f20eadc288e2854a39bdabc43c84a777c','b35a48ba997443f6b475aa0e0e923eae55cb28638ed756ee5a5c640f8be5495c');
INSERT INTO blocks VALUES(310481,'db37d8f98630ebc61767736ae2c523e4e930095bf54259c01de4d36fd60b6f4a',310481000,NULL,NULL,'fbbe1266bb773e5a3f5b48e82566ff75bc74bfea9424f81f670952565db15c59','09e9faa545cda2bc125551002c85870cd92506d9a14f53cc2d49f5cd3de38e38','35a675ee5f0bd2906395e843868dc710e0327f52dd3d3d859b641ab81dffae84');
INSERT INTO blocks VALUES(310482,'2e27db87dfb6439c006637734e876cc662d1ca74c717756f90f0e535df0787d6',310482000,NULL,NULL,'bd28a97e90054319c4c301c3e99d68aaa5e1bf5a145a8f2c4529040bb8137209','040c3e8051a0cf4bb71e0095a9a8dcb32aee22a0c8afa7b34401daa35096ec8e','a5f050fd1cff90313bb0a0adfab0d7fc0896828d78b45117f8923937f31f09bb');
INSERT INTO blocks VALUES(310483,'013bac61f8e33c8d8d0f60f5e6a4ec3de9b16696703dea9802f64a258601c460',310483000,NULL,NULL,'fbbeacec99c9ed99a7fc37cdd5673fe8bdce08eba7fcb25b696e262af29ca5d8','f82520356d7c3426f4fa9ae0f02c5b8e39e6580b9fc5dd1faef30d5d9e0e6fb5','f76384f6ec9d0fb9afce509273af076b2dce5ce19b559e61fe3399d84df79294');
INSERT INTO blocks VALUES(310484,'7cac2b3630c31b592fa0497792bed58d3c41120c009471c348b16b5578b3aa2b',310484000,NULL,NULL,'310bc7c61c1325ee3f97e888658fd74e1fe4adccef4924abb6978150fe6f3dad','3bd5939133d86355d24dfb8edc363381a7164c190ca746b3cc012acbfe0cff6d','d06230bf6ccdd0e21cc5a0ec4b7d61895442cfdb0e595b6148641b925acb5294');
INSERT INTO blocks VALUES(310485,'eab5febc9668cd438178496417b22da5f77ceaed5bb6e01fc0f04bef1f5b4478',310485000,NULL,NULL,'b7f66db9ea5838b65286422d0cac262f6b81bbd5a7397adf7b8d85b21354dbcd','91a8a2ffc7327d99ad13d8cbb53800e08eceef4e440edae62f1eab2a47a538c3','0c0a603e69350e6a590cf99dec4285c1bf1031ee697a9fbd97b55bc89822b39c');
INSERT INTO blocks VALUES(310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,NULL,NULL,'0f829769e4da773089d7b05047a499db5f6d1b17795d4fba912882caee9813e0','2bcacaf3cfcbdfbc89d042a712af0168a714a3cab18c7f9d727f16103be875fa','53cb716251fc59d9db94d56ba74d6c51ba192edcb1494d49e6f86f50022b69fc');
INSERT INTO blocks VALUES(310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,NULL,NULL,'4b4d7a79843342e96e5d9d71bbc49690245b3098be75e7b86f273021d526216d','5ca8eb4cf467304bd819bbad7094167828fe8324b72076cacfe1786bd8d7cc05','c9ea2a5dafa1626bfc76a4dd56dd253ce37f51fda8d382f80d50f2998b29646d');
INSERT INTO blocks VALUES(310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,NULL,NULL,'2d7e59026ea4c8933e9c7474936931ca49d4af91f9b9985f3c76085fb3a69104','3166ff4dbd6af52c85ae9e167266d8dc60fbf459c60d95e0a38f67e4ed92bf82','3f15680d257665c2452f4a9e1c012bfb2867bd9ee416ace77aea7447b2c9740d');
INSERT INTO blocks VALUES(310489,'2efdb36f986b3e3ccc6cc9b0c1c3cdcb07429fb43cbc0cc3b6c87d1b33f258b6',310489000,NULL,NULL,'716354a370f344980e98785a444b56b21188bc699e7fbd0c877b6f2fabf35efc','36e8082d9c6517ef40b07b5a71368419329ae3747b6a9ac76cfe2dd129c4489d','c0ed3783768fde6e10d4df86c76f8b7b98c8c2d5b22a9e9ce570dd2142336de1');
INSERT INTO blocks VALUES(310490,'e2cb04b8a7368c95359c9d5ff33e64209200fb606de0d64b7c0f67bb1cb8d87c',310490000,NULL,NULL,'906a38f4256f50312891119c99721537992438af85421e317574ce1810e2b909','08f469539ff324d9ad36469a6b97384fc4f392985c40c78de0e7dd08bb2c8577','f92603527384ca14854c1e1932c76da8a858bab7054ddf558632263cb4f6f416');
INSERT INTO blocks VALUES(310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,NULL,NULL,'3114d8091cfcaa9944c6fab49d51950535c4ef269877d58c372ed80b2b472ec6','c9821370cca155443308b4a23eadb5cec3c6157b48731c69f417d5a92af7cfd5','98aeefdb75ce8e9e2f7869ab71290f8c4d5213a155962f81a625c9fb321380d6');
INSERT INTO blocks VALUES(310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,NULL,NULL,'98af18583618fdeed545347c013763d068e8294405d265911cc5e1bc420bc740','cbc69050e3a80403f904a9f71416ba0b084abf0ee92e88df30d5a516f36dcc16','95f91bb535d47904be0e277a244b2f696ee15ffcd38223254b3481fea055fba6');
INSERT INTO blocks VALUES(310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,NULL,NULL,'29119cd30a4733916fbfd0551506eaa16f7bb1bdfbdf8d17ac4e5bb20d1cb09c','144b773d9acfa5dc5d3b1d69eefcabe5baa05d79a2b813d4348734887a01f01f','764a5fb61c164442a2c5ea980e47c2ac8959fd8c00a529a0ac9581bc4759cf02');
INSERT INTO blocks VALUES(310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,NULL,NULL,'72d71bd72263699ea9f2b097ad141be5bc394f49d8b0b0a6b2ff6a87b0ee3919','3006e0354a72ade041b02181a27443b64badc86b1f7298bf9526d97a41557ae7','049549d0c1ce843c9b88888036dda90ce3c05bc92be70f95100d581791217497');
INSERT INTO blocks VALUES(310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,NULL,NULL,'5a7e5a36882466373d576bb5f4ccd1bc72ecaf548b9589baa803a7275a7a24cd','72da9781d907e74e842f96bbbd9b85b1b4873854f45ced4fd2ead284b8b2a956','cd6253f3d9694d952e3af4bb4c260593563e9a7bb4a0b34911466f63fe447986');
INSERT INTO blocks VALUES(310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,NULL,NULL,'7ac6121c624b634f44695172761830926afe76bb18c4cc9195773f3a26966941','07c4dd6f0bdcf0e2ab09070e26c11dd930722e955c7040b3b76c3817ffe5c508','84e5592a32aacd61c4c57c4bea5b03b2813c45e77954f2edefafe81d378c945a');
INSERT INTO blocks VALUES(310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,NULL,NULL,'28c6e92b2299b9cbbb5953f8b7ff3de0fe962d15642ba27e43faa64e1935e819','a386ec3bb2d453b55a61a7e6e46fb549ac904a004e37331057d010692b1a7830','dd87403f0eadeda345755fe2444f777427c7042dbec4fd3546d7ce7154861b14');
INSERT INTO blocks VALUES(310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,NULL,NULL,'5fe6cdb0828379bf240fad99c68bba34e1889bbc19605ce5c297b82352264414','c9dc04ff5da5491cc5693ee0247e6296110f6f2421543fa3e154847ff611e5b7','e1dd32efb1ea1bd9fdb0305ac96e079407b224675c366e7a93036eb1c8e8960b');
INSERT INTO blocks VALUES(310499,'1950e1a4d7fc820ed9603f6df6819c3c953c277c726340dec2a4253e261a1764',310499000,NULL,NULL,'b9fcbdafddd46fdda061f6e9f8744b426b6ca37e32b315df1098cbc7899ae9b9','7bd26b1595625179fe1b6f2150d2479e8c304ccd7c4643ecc616cafc25448356','9e03d05bd8a375690416b89ad8674fa8e528bda53cff41bd793d2f1f57a7017e');
INSERT INTO blocks VALUES(310500,'54aeaf47d5387964e2d51617bf3af50520a0449410e0d096cf8c2aa9dad5550b',310500000,NULL,NULL,'5ffefc7a2724be6bd697796bb82638ec913c5cbb73627153d1a13b48c7a6c02d','de162149a596f911ad90f45e77f93d571438fb9b417b0d5d12cdf09aab524544','0cd02f78ab16cbc1265c0d272ef5e612b31545c7f11621958746bfaf96d22014');
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
INSERT INTO burns VALUES(117,'89c728bbe0c53eb9de4774a1261dfd8895ed0a3364dd41c5a06172472a84cee5',310116,'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx',62000000,92999030129,'valid');
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
INSERT INTO credits VALUES(310116,'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx','XCP',92999030129,'burn','89c728bbe0c53eb9de4774a1261dfd8895ed0a3364dd41c5a06172472a84cee5');
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
INSERT INTO issuances VALUES(2,'9cd12fbcb360926dfbc6fc57c2e513a149a66fd12092453c2765bc89d725d57e',310001,'DIVISIBLE',100000000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Divisible asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(3,'2efe98f74b6d5963e271457253e6a1748a90992eb0531d60a615d3ccc3986b73',310002,'NODIVISIBLE',1000,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'No divisible asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(4,'4361d0ef173c245f3cc5053d5e2513ef9120e5e8abcdcf7c86e164becd53ceeb',310003,'CALLABLE',1000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Callable asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(5,'e73d6a9873df9f2264fe2d7f2da66e3a8975bce90d9ec285e79eb47348b41fe1',310004,'LOCKED',1000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Locked asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(6,'1aa86ffaf6e3bafbd00660ccb794267a9e95814406394d2f1d5dbd6d2ef01579',310005,'LOCKED',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Locked asset',0,1,'valid',NULL);
INSERT INTO issuances VALUES(17,'19cf9fd72fd7c1c766589c39cbba55cfd7495047d1773fa46e6b91c16ad85f93',310016,'MAXI',9223372036854775807,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Maximum quantity',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(110,'ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e',310109,'PAYTOSCRIPT',1000,0,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',0,0,0,0.0,'PSH issued asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(114,'5f66cb2a8f0a4605cf274a21daf0a61af10fdf3fdc5210e5bcf8f9f3d26b0bc9',310113,'LOCKEDPREV',1000,1,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',0,0,0,0.0,'Locked asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(115,'74aa7471cdb1b13162e0116dd0cbcc4022cbdbdadef0ee0c5b8d63e527e666fe',310114,'LOCKEDPREV',0,1,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',0,0,0,0.0,'Locked asset',0,1,'valid',NULL);
INSERT INTO issuances VALUES(116,'214edd39455a080e261e3c319f23d3fe5f064f48c044c0973811b6a85dd2990d',310115,'LOCKEDPREV',0,1,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',0,0,0,0.0,'changed',0,0,'valid',NULL);
INSERT INTO issuances VALUES(495,'4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5',310494,'DIVIDEND',100,1,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',0,0,0,0.0,'Test dividend',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(498,'076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f',310497,'PARENT',100000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Parent asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(499,'0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf',310498,'A95428956661682277',100000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Child of parent',25000000,0,'valid','PARENT.already.issued');
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
INSERT INTO messages VALUES(91,310116,'insert','credits','{"action": "burn", "address": "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx", "asset": "XCP", "block_index": 310116, "event": "89c728bbe0c53eb9de4774a1261dfd8895ed0a3364dd41c5a06172472a84cee5", "quantity": 92999030129}',0);
INSERT INTO messages VALUES(92,310116,'insert','burns','{"block_index": 310116, "burned": 62000000, "earned": 92999030129, "source": "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx", "status": "valid", "tx_hash": "89c728bbe0c53eb9de4774a1261dfd8895ed0a3364dd41c5a06172472a84cee5", "tx_index": 117}',0);
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
INSERT INTO sends VALUES(8,'95f1a544034d2814b7c484e4525891813fa9c10bb71f012f70602f99f31195ef',310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','DIVISIBLE',100000000,'valid',NULL);
INSERT INTO sends VALUES(9,'8d1e0fb12f2d7522615b11f81dcde1c58892f47e44b7f56b51f639440dbd4dbc',310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'valid',NULL);
INSERT INTO sends VALUES(13,'1acf929efa6296558b1335f3cf94bd7260979c531097e2c4d0efc3d333fa5568',310012,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',300000000,'valid',NULL);
INSERT INTO sends VALUES(14,'62dfaed0ee983d767b9aec98cc49d716b807281e9e8e5d5cd8c5207c0d2f15dd',310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','DIVISIBLE',1000000000,'valid',NULL);
INSERT INTO sends VALUES(15,'9bb2e42d2f4ab601b7e8f50364fb1caed9dc9e8dc9071f660804f559bef875ba',310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','NODIVISIBLE',5,'valid',NULL);
INSERT INTO sends VALUES(16,'62172989ab319f239125b4635102e593a01cb4e7ba70a42d533ed9c61fadcca4',310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','NODIVISIBLE',10,'valid',NULL);
INSERT INTO sends VALUES(111,'f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481',310110,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000,'valid',NULL);
INSERT INTO sends VALUES(482,'b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5',310481,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'valid',X'68656C6C6F');
INSERT INTO sends VALUES(483,'c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34',310482,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'valid',X'FADE0001');
INSERT INTO sends VALUES(496,'129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc',310495,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','DIVIDEND',10,'valid',NULL);
INSERT INTO sends VALUES(497,'1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6',310496,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','XCP',92945878046,'valid',NULL);
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
INSERT INTO transactions VALUES(117,'89c728bbe0c53eb9de4774a1261dfd8895ed0a3364dd41c5a06172472a84cee5',310116,'8495ba36b331473c4f3529681a118a4cc4fa4d51cd9b8dccb1f13e5ef841dd84',310116000,'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
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
INSERT INTO undolog VALUES(156,'DELETE FROM sends WHERE rowid=482');
INSERT INTO undolog VALUES(157,'UPDATE balances SET address=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',asset=''XCP'',quantity=199999990 WHERE rowid=7');
INSERT INTO undolog VALUES(158,'DELETE FROM debits WHERE rowid=27');
INSERT INTO undolog VALUES(159,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91950000000 WHERE rowid=1');
INSERT INTO undolog VALUES(160,'DELETE FROM credits WHERE rowid=28');
INSERT INTO undolog VALUES(161,'DELETE FROM sends WHERE rowid=483');
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
INSERT INTO undolog VALUES(184,'DELETE FROM issuances WHERE rowid=495');
INSERT INTO undolog VALUES(185,'DELETE FROM balances WHERE rowid=23');
INSERT INTO undolog VALUES(186,'DELETE FROM credits WHERE rowid=30');
INSERT INTO undolog VALUES(187,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''DIVIDEND'',quantity=100 WHERE rowid=23');
INSERT INTO undolog VALUES(188,'DELETE FROM debits WHERE rowid=31');
INSERT INTO undolog VALUES(189,'DELETE FROM balances WHERE rowid=24');
INSERT INTO undolog VALUES(190,'DELETE FROM credits WHERE rowid=31');
INSERT INTO undolog VALUES(191,'DELETE FROM sends WHERE rowid=496');
INSERT INTO undolog VALUES(192,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''XCP'',quantity=92945878046 WHERE rowid=22');
INSERT INTO undolog VALUES(193,'DELETE FROM debits WHERE rowid=32');
INSERT INTO undolog VALUES(194,'DELETE FROM balances WHERE rowid=25');
INSERT INTO undolog VALUES(195,'DELETE FROM credits WHERE rowid=32');
INSERT INTO undolog VALUES(196,'DELETE FROM sends WHERE rowid=497');
INSERT INTO undolog VALUES(197,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91950000000 WHERE rowid=1');
INSERT INTO undolog VALUES(198,'DELETE FROM debits WHERE rowid=33');
INSERT INTO undolog VALUES(199,'DELETE FROM assets WHERE rowid=11');
INSERT INTO undolog VALUES(200,'DELETE FROM issuances WHERE rowid=498');
INSERT INTO undolog VALUES(201,'DELETE FROM balances WHERE rowid=26');
INSERT INTO undolog VALUES(202,'DELETE FROM credits WHERE rowid=33');
INSERT INTO undolog VALUES(203,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91900000000 WHERE rowid=1');
INSERT INTO undolog VALUES(204,'DELETE FROM debits WHERE rowid=34');
INSERT INTO undolog VALUES(205,'DELETE FROM assets WHERE rowid=12');
INSERT INTO undolog VALUES(206,'DELETE FROM issuances WHERE rowid=499');
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
