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
INSERT INTO assets VALUES('2122675428648001','PAYTOSCRIPT',310107,NULL);
INSERT INTO assets VALUES('62667321322601','LOCKEDPREV',310111,NULL);
INSERT INTO assets VALUES('26819977213','DIVIDEND',310494,NULL);
INSERT INTO assets VALUES('178522493','PARENT',310498,NULL);
INSERT INTO assets VALUES('95428956661682277','A95428956661682277',310499,'PARENT.already.issued');
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
INSERT INTO balances VALUES('munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','XCP',92999130460);
INSERT INTO balances VALUES('mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',92949122099);
INSERT INTO balances VALUES('2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',46449556859);
INSERT INTO balances VALUES('2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','PAYTOSCRIPT',1000);
INSERT INTO balances VALUES('2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000);
INSERT INTO balances VALUES('mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','LOCKEDPREV',1000);
INSERT INTO balances VALUES('tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx','XCP',92999046851);
INSERT INTO balances VALUES('mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',0);
INSERT INTO balances VALUES('mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','DIVIDEND',90);
INSERT INTO balances VALUES('mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','DIVIDEND',10);
INSERT INTO balances VALUES('mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','XCP',92945878046);
INSERT INTO balances VALUES('mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK','XCP',14999330);
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
INSERT INTO bets VALUES(111,'d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048',310110,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',3,1388000200,10,10,10,10,0.0,5040,1000,311110,5000000,'open');
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
INSERT INTO blocks VALUES(310106,'9d39cbe8c8a5357fc56e5c2f95bf132382ddad14cbc8abd54e549d58248140ff',310106000,NULL,NULL,'d49f0cfa46290fb0eb33f6b73cb1980793c83485320ff3141f11d45fb49cee29','0a283ccbb091d9daa57d8e93f7b154cd2d107f787d9abac4a4a104006c16816b','d8c87a21277791e6bf3f65c41844255d7cf7d20316c2242928268262215699a8');
INSERT INTO blocks VALUES(310107,'51cc04005e49fa49e661946a0e147240b0e5aac174252c96481ab7ddd5487435',310107000,NULL,NULL,'132ef9ebe794cb906b4388fc31012430b6a16cb95ad0ba86349a6c2c33463e51','265c50d0de46d77ce17a09652f43fc6a429172305065d10a9e4c858c682a16c8','3f83622bfd23e97d78f8114fbaf6ee30b48c2b302315370ea38270efbd2f955b');
INSERT INTO blocks VALUES(310108,'8f2d3861aa42f8e75dc14a23d6046bd89feef0d81996b6e1adc2a2828fbc8b34',310108000,NULL,NULL,'72731e113610e4efaf913f6dd6c82123b186b425dfbfd83a714bbabcbe36c2af','b1065712d12ccbb2e69767118e8745afa4597ad7925430be3ad6876c0638022f','5027355b27fe751689f591f9ff05a031f392ae1781ba02c8fcabbe0d907221f5');
INSERT INTO blocks VALUES(310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,NULL,NULL,'a4e5d740e49ff272c01420a242d7e83c113c6b9d0390dc13225695039f7598c6','cf9ba10a4ab0dba408d2d29ce9c37104bf974ca42c2eb16438c507886cc6036b','908f9c64e0262c1674def0113281e379b6e842c9d75ed122e18de553c670b191');
INSERT INTO blocks VALUES(310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,NULL,NULL,'00abde058f2273cf86f762cb5e1ef6c5e02ac1a5f87571943ea57fec6b70293b','5f46727c759d42535165b753349a9e8d13d9fb7697d63ddbf215fa27cbfaa23a','384473b58b3d674cbb9f1018e16893a67370b8ebaae554be83a4af2647cb387b');
INSERT INTO blocks VALUES(310111,'fde71b9756d5ba0b6d8b230ee885af01f9c4461a55dbde8678279166a21b20ae',310111000,NULL,NULL,'e615ef33450db7aef8eed75c56edaa7bbe9fb0f91af49e42af4e6476d9eb29cc','584f08a10c9772e4614d6791438bd09879b0498bb01769e3604cda0c2960fdc3','1a7ec32a1a74387ac1c3a4a307576fb45b0f6171ec75c2306dddb50defad188b');
INSERT INTO blocks VALUES(310112,'5b06f69bfdde1083785cf68ebc2211b464839033c30a099d3227b490bf3ab251',310112000,NULL,NULL,'05a1de6473741c181768ce40f404e4763a16aaaee39eebaecbfab228fb6844c5','0cde9cd13f3026b499b40c943bea535779d428046649dfa8a20c1c2e41a78c24','d097be93f4d6818df488bba8c4a713ca00de723aa6caeda7ce4ada8d33989b90');
INSERT INTO blocks VALUES(310113,'63914cf376d3076b697b9234810dfc084ed5a885d5cd188dd5462560da25d5e7',310113000,NULL,NULL,'a43e07f9ec1f3da74ee64c1867bbd31d2d09d219972af3ac75330afedc89e514','6513f2b84d1baef4b8127b3cec1783885afa2e42462be5028a1e1db56fac11f7','9a35d93eb8df973841ab363d970148398a41d10c1cf740c0a07803105be74610');
INSERT INTO blocks VALUES(310114,'24fc2dded4f811eff58b32cda85d90fb5773e81b9267e9a03c359bc730d82283',310114000,NULL,NULL,'21798ec4617479c55052c009b7afe58f6658c99862d1cc64267ddf3281f456c2','671958ba1054ee24eac09d30cbdec087b1a5afcd056835673828bc9c095b5650','63adb47f26d4025455910ee273ad939bdfad8a99b8effcf4a40fbe870113501a');
INSERT INTO blocks VALUES(310115,'a632d67ff5f832fe9c3c675f855f08a4969c6d78c0211e71b2a24fe04be5656a',310115000,NULL,NULL,'4ac28d6233acc530fa512f549645850d32971b42cb029dd0f741ac3924eb3a2c','ba2fd92103395bab5330da93f4ad4825eb3799526ce328413e40eb01de1e87a2','e9be81444fff180eb35e55f0d4fbe523d8d251b2b9103a3783b6171ec04a70ea');
INSERT INTO blocks VALUES(310116,'8495ba36b331473c4f3529681a118a4cc4fa4d51cd9b8dccb1f13e5ef841dd84',310116000,NULL,NULL,'681776d658e1f35034b3f9a3c3251103d279220a57e9e83ce0157a0c7638726c','838ace5e3f2607a7780026a0da349a23498436f628a01543c5f51b0d1f058247','a3cc4994bf6548e7aba5a6676e6ff8bb5d128fefd047e8d3be8ea407102bc66c');
INSERT INTO blocks VALUES(310117,'978a3eac44917b82d009332797e2b6fe64c7ce313c0f15bfd9b7bb68e4f35a71',310117000,NULL,NULL,'c74e9fa242438ac84cdeeb55da4726a4515923a4ba2c9195ff043853858c2436','37dd5026cc9c853d6aed10d0c61f58a39634196a99234a171f708c9f83e51347','769cfb409f0cfba96eb24e413fca023d1767126ba69f0b46d617f1ebb4974fee');
INSERT INTO blocks VALUES(310118,'02487d8bd4dadabd06a44fdeb67616e6830c3556ec10faad40a42416039f4723',310118000,NULL,NULL,'b90a4cde9bbb0c1c2a4431d3b48ee3ebb2633c9149de6367215683497a12a3de','0119fa086b90616a8f6e7a2c970b2aed619ea9b5b81ef37210328769a9f93041','8cff098e5292d62650871e662be18cf802e6848d6c63e352a53f7263f9f34984');
INSERT INTO blocks VALUES(310119,'6d6be3478c874c27f5d354c9375884089511b1aaaa3cc3421759d8e3aaeb5481',310119000,NULL,NULL,'986db9129e3889e468cf2c6bf98723264da70fce0120340c5bafe0f1b1eafe25','761c9a705dabb4cc4eace587d7f6b7972813535473270362fc83858cc3c2884e','1b677505d5e9ad2f7819a9c1bcb7ee5fddfdda8a2da37f122b07af405a7166c6');
INSERT INTO blocks VALUES(310120,'2bba7fd459ea76fe54d6d7faf437c31af8253438d5685e803c71484c53887deb',310120000,NULL,NULL,'c7ff67b8dc5f0de7fb3974a3b32ee443630d8f9c2a399921ad40aaf4e9e7bb74','f282fcb6cf32fc1238a09e93ea3a85e20ae915f42ec2b200c4a968d490b9cd1a','d961bf86e89f05341c1d0aa6eb36a6702c6a9af5e602bfaa6404efe35099f33d');
INSERT INTO blocks VALUES(310121,'9b3ea991d6c2fe58906bdc75ba6a2095dcb7f00cfdd6108ac75c938f93c94ee7',310121000,NULL,NULL,'f2c1699b832a6e41fda60344fc79da4be56e225b6b7a708faf3b766b3c09306c','0e4524589b09c6beee2a517848712abb57527e80a74d43f03e8c90bf25700454','31a575bd57150e55d49a97728379e46453717845fa058cf3cb4bac936ef05682');
INSERT INTO blocks VALUES(310122,'d31b927c46e8f9ba2ccfb02f11a72179e08474bdd1b60dd3dcfd2e91a9ea2932',310122000,NULL,NULL,'bba0a7e337f11d9a1384c50ddc9b4cc44b223499dcfe6f29ec741178d63c3367','0c0f104a88731b2afbcbe0a6971d3d9ad7aed786664cdc683babc9cdf2c9a239','55c4e5d7993de48bec0ead18fbb3a76204f731c1b247cb08bd9c7c54845fba1b');
INSERT INTO blocks VALUES(310123,'be6d35019a923fcef1125a27387d27237755c136f4926c5eddbf150402ea2bbd',310123000,NULL,NULL,'39d569dc3fbee02ed36730f73cd2aab4ddb737040e88914b458cba6056a92d11','5b1b3462b62c12da109e5ea44b0b2f6fb5fa07551da99921910a7debb2074df1','bbb7f0ed43baa6424ce037eb9998eac1b3eb75dc9235f8ee394ed2884da85432');
INSERT INTO blocks VALUES(310124,'0984b4a908f1a7dac9dcd94da1ee451e367cc6f3216ee8cdee15eae5d0700810',310124000,NULL,NULL,'84394bfc697233ef36e2d06ffa4625f2cbe9e0b57852e124d31209b15be20077','73ef4c7ed3dbcf9c7ec41001ffd519623835f2370c7162eed91ab52f91487ccf','c7ecd20bfd7f7bddc2128c547df5f9188e115f3d5adfbd269e6a3c9c5c220e6f');
INSERT INTO blocks VALUES(310125,'cc28d39365904b2f91276d09fae040adb1bbbfd4d37d8c329fced276dc52c6a6',310125000,NULL,NULL,'db6212933746ed9586c272f4ec8035aca9929ea21faaea9d1edcae6369818345','223554c384803922d19b23cd8da7772aeb186a50263b2eae48289dd21bee93d1','a496ee745536c4d45fbc47e4883d2b0e879fc07c8742d5204152f2bcbc7e653d');
INSERT INTO blocks VALUES(310126,'c9d6c2bd3eeb87f3f1033a13de8255a56445341c920a6a0ee2fb030877106797',310126000,NULL,NULL,'99dfa101c761327d53b4eddf522a6cd24f48aed1be6e8eca728b057ff43b989d','b5bf6c12334d02ad72c5586f6f5437943bae701e754d5a6e6d8b6441bc07dedd','9a5f3a3738973225ba23b6231229e6e0430e46ac72bba6a2461ce626036f3221');
INSERT INTO blocks VALUES(310127,'c952f369e2b3317725b4b73ba1922b84af881bd59054be94406a5d9bbb106904',310127000,NULL,NULL,'8fcbaf6bf15193e562a34fcd747dd9a00b1fa6ebe895bc6e5b5eefa9f55d6902','3ed29bbfc34b1fa6f1893280778ee30862a5488893b7cf17a17b56cfdd9c99dd','f1d6331a8a6b55c14e77daef70c0b669b515da6edd97052751b2442b5a0bd20e');
INSERT INTO blocks VALUES(310128,'990b0d3575caf5909286b9701ece586338067fbd35357fec7d6a54c6a6120079',310128000,NULL,NULL,'99161e67ce21f4680e235b46734348cdad6eeee58f7b560609fb076413f6dd54','655d5b6dbb489f090c7e57e59b086538a597a9217041bbbcdade2164f0d8fe60','7f7700fb94d17c7b3a786f714676b6806859b1ea5116a3bdd6ca2bb257edec7d');
INSERT INTO blocks VALUES(310129,'fa8a7d674a9a3e4b40053cf3b819385a71831eec2f119a0f0640c6870ca1dddc',310129000,NULL,NULL,'214f527b85983eaef595953f249df2204e28a1285063dcf0599f9539d0d8fb72','c40644a81a5c3664b7794ebb652d881f0df5a31c2b834b3553fd76c3f3ed4dfa','8b5be8a0678cfc8ec56dfb9d9b5519c6116affcd07d84a58c42490c91f292769');
INSERT INTO blocks VALUES(310130,'d3046e8e8ab77a67bf0629a3bab0bea4975631d52099d2ddc9c9fa0860522721',310130000,NULL,NULL,'26c91379b15ddd7c4d237bf065cce00c4aaa9a098b544648912ed5bece6299ef','2b0c93cabf7a885f7d986a15471a798149ac24c8e4f2ef9dabf6b8e1b0366d11','98906dace6e5b84e8cb5db2e763d2c9d45672b48ca2ef3723b5df28c180492b9');
INSERT INTO blocks VALUES(310131,'d6b4357496bc2c42b58a7d1260a3615bfdb86e2ce68cd20914ef3dd3c0cdd34d',310131000,NULL,NULL,'c3c187f3db2a6f62c8d86add9f4af38b19fb0a5329a7d14708e252d4396c8cea','d0b792b9d885f7b3c07977e8fb7a4781b237b4a2715e309b64104a45b37373fc','1a4646bf46e65342770de7fae4f72c042b9d1bd4b13b04d204e51528b7f4ebb7');
INSERT INTO blocks VALUES(310132,'1b95a691bf4abf92f0dde901e1152cc5bd87a792d4b42613655e4046a57ab818',310132000,NULL,NULL,'fb4f3db154cad6ae420c63e354ec7bc7dfe0c23fb073bd5e9a16dd11ac20f5d2','01f9f6223130a77a4cfb4221e17ed20d6613c13673b58f251e4f3ff0a85b8a50','60cb1a439642d1dbf3088dda34c60f62eadf9614626547cabe34218aa8ff1a99');
INSERT INTO blocks VALUES(310133,'1029c14051faabf90641371a82f9e2352eaa3d6b1da66737fcf447568ca4ec51',310133000,NULL,NULL,'3c773989e0b44e6591ce0326c8ec00f1801ff484662b563144230fbc63a353d6','03b72d4b2f7307d71a2376ffb6abe8a04b49c0c647e9342f18450172a49163ea','c799fe7e157101d84e5b15bfa701b4f5a23f0f74bd7929990d06b756368b31c2');
INSERT INTO blocks VALUES(310134,'1748478069b32162affa59105257d81ef9d78aee27c626e7b24d11beb2831398',310134000,NULL,NULL,'7511bbd260bf40510a781231f1edaf8f9cbbce2e733930c095609e3dbf6d2646','781fad3355f6f62148fc48f2655ebdeec941551f025f1c0f468d80f62e07cbd6','29b3cb5a45d85ed906b19e732c2f4a99b50a71ddd23c13e325c069fe9005edb8');
INSERT INTO blocks VALUES(310135,'d128d3469b1a5f8fb43e64b40f8a394945d1eb2f19ccbac2603f7044a4097e4f',310135000,NULL,NULL,'e34736521c0f27006221daff4ab4d9d210a332f5418f4b56756a1ddc4f0e511a','12c3cce482ea3e6666e891ba3926657c9df87cd2a3858984a9fe9d0dc1b0a242','990a2c35cfaa3fe0071384eb33426fb0ad8d2c0520be640f09b1522a08de3504');
INSERT INTO blocks VALUES(310136,'6ec490aaffe2c222a9d6876a18d1c3d385c742ff4c12d1334613a54042a543a5',310136000,NULL,NULL,'80aea568a6cf12d5a254afbe3b42354c4d342de1e0e836a40c5990e6037af940','10fe0bc3e6b40123e5fe72bc455c82212a5cc8167775c24d5bc9f0b28ba664f7','1ac10fb94623f28f854b5c6f91d0c8973ee90b602f43f89bf0b403cf8beb66bb');
INSERT INTO blocks VALUES(310137,'7b44f07e233498303a57e5350f366b767809f1a3426d57b1b754dc16aba76900',310137000,NULL,NULL,'83509e2394c2d8c58f8e71c48930cc53fd4f5fb918336c265ec04e14c0ef56c0','b2992b05b52f66ed2c306bb0bc40d05e3b7958453af0c7dea30785e568822857','3e77bad99fbbb616f36582be04dffbe74490057e760a6f9525f0cc1cf96fa744');
INSERT INTO blocks VALUES(310138,'d2d658ccbf9baa89c32659e8b6c25b640af4b9b2f28f9d40baae840206402ab5',310138000,NULL,NULL,'ec326eaeb574ffb23796f9a967295695115ac5d6760223bfd7540e663e01c2ad','2df3b4a9f736b538d0bf91167dee0a0560a54c02bfbbf772b2491ce4ec9525e0','8e6f8908399a8fba88ec4e1d636ab3ed5491ae9493f10c07c0f88d7a5a4da288');
INSERT INTO blocks VALUES(310139,'b2c6fb61f2ae0b9d75d18fce4c52a53b1d24772b1ad66c51ca51090210527d46',310139000,NULL,NULL,'7118e5da63441aedb15fb91f34f7c591c3466a4e416308f568f811f6e99940cb','22acecb17077621115f473b153e8b1e6e5346600e50dc1b54884a1921221cf2e','13b75b6619a0f2e389192a561ca84ca410a84c6c8de6a58d4d78274d3d2fd383');
INSERT INTO blocks VALUES(310140,'edddddea90e07a466298219fd7f5a88975f1213289f7c434ed47152af6b68ebb',310140000,NULL,NULL,'cac8240523d8cd3880406e7c7c8787d95d09b7b1bfbcdb7b3f903eb5a805c3a2','4b3fadd4f2e40193243435638fd5e70e08a41bc88542e76bf643b58ca3fcdd56','3620f49524f85ae4c4ae8351ca2f143b5a3fad068e00684bc765b4ca065e1968');
INSERT INTO blocks VALUES(310141,'b5b71d2a271bd638561c56f4ffbe94d6086debaaa86bfeb02ef0d71339310709',310141000,NULL,NULL,'789436b4b0e68a5e2a99b5b9567a7aae1faa8751291466faea5bedb52d265f49','803b0a8c25cc343e8e8c0acddb3576fc7ea23eaa0b370cf3b6e1b7dffffda862','5a16111be04e12729a39289a4df243ff9c159186f5b6651dddbe47505936b0ac');
INSERT INTO blocks VALUES(310142,'a98ae174c41ab8fc575d9c8d53d8e02d8e446b8c6c0d98a20ff234eba082b143',310142000,NULL,NULL,'28778315da6da55e4677a0fd780154f8245edf88a52f0db9f78ab311b33fff00','859e2af1a3909a2865e10f134bcd511c85e11e741698dd20aa23e7423a5aab39','5d5a6b85a7293f0debd22f987ae7211918c555454f8bd137cf08bb9fe1493a83');
INSERT INTO blocks VALUES(310143,'8ba2f7feb302a5f9ec3e8c7fc718b02379df4698f6387d00858005b8f01e062f',310143000,NULL,NULL,'76beaa18337f4b86599d38c95060eb4d117fadf595d24feb1deb346383e55f9c','78a29717ed7003fcd3e52c4a98fdf88abe4c86ffeed64caafb081204630d13fe','ceb69817751ca9ea5b337137b21b286300991b1e73b367932c870835203e6cb2');
INSERT INTO blocks VALUES(310144,'879ffa05ae6b24b236591c1f1537909179ed1245a27c5fdadd2218ab2193cdb9',310144000,NULL,NULL,'e655301bfb464825b692bb610c95f74ac6b3b1f9192a9fb12da36cc09d91daef','f9f25cb10ed399f0c1ca2a04db26fcf9cb15cb49c657b3c656ae1032ba456d3c','cc02cd6001f63e1e24968c860f9fb62ff2eac0273248796ab1563e2b40079059');
INSERT INTO blocks VALUES(310145,'175449ef0aa4580593ad4a7d0c5a9b117e1549ea772af00caa4ccdc9b1bf7a6e',310145000,NULL,NULL,'cc3af71e07130266e53e68fbeac90b5a8dc220cc7f5096c850a127091c1ef672','7e949120f19c24a401aacf5b44202b0dea17ceba3363c79a66386f2d6d3da345','aa38e4b60401df893904cfe58e2d1f1260358584e5f5188413c24295a90793bd');
INSERT INTO blocks VALUES(310146,'e954ab6a110455d745503f7cc8df9d92c1a800fafdd151e7b1912830a9cb7184',310146000,NULL,NULL,'ac6e90e21e31e218fb444c0724da8599428a668472f210b9f3b03f98c7dd6d58','faa7ba8ee04db4999d8badcb629b1de77477d57ac001fefc4c71c2df1d7ff723','a158d563419ab41fc18fdc20411bd96ddf78e056e6ff453e23508e6884dbb732');
INSERT INTO blocks VALUES(310147,'7650c95eba7bf1cad81575ed12f32a8cc36281a6f41bef13afe1dfc1b03a7e83',310147000,NULL,NULL,'e3f5ca98928e41b561c06b1f46c01532b6cbc5870d34dfc44b8a53b52782a272','47757b0e9f44eb525a27f3339d470e5e13850dba2363dd355cd3e683a2e80f07','57f4e7113e4ccb6ea037f1175937b7f8392eee05b4155971587df7a26e408009');
INSERT INTO blocks VALUES(310148,'77c29785877724be924f965215eb50ffe916e3b6b3a2beaea3e3ae4796545a7e',310148000,NULL,NULL,'62f2e3a4c2bf052343ad6353e0c9e13ccd3c3402af45b9d0da04625c47993d6f','11cc6606b17d521c9bc0bdbbbfc67b55d86b28292e54cebe6c06f020751cac09','7bd055d31cc30f70687bacd91ff1872e1085b9829d0ddd4dd51f4ceaacfe05e8');
INSERT INTO blocks VALUES(310149,'526b3c4a74c2663fc04ed5234c86974bffddb7235c8736d76860778c30207b3c',310149000,NULL,NULL,'efd080b51b16f48fab42cba656408f7f8ca9d65e0d90c6a2f4024dc3ced1f660','16241db323d01e2974268a470ff9538851df5f500877457a14f879f1a3fc0afa','1df78bce78158999c7848debf3f5bf9bcf6cf5726d4ef7b1fbe5ad324c90acb0');
INSERT INTO blocks VALUES(310150,'cdd141f7463967dbeb78bf69dc1cd8e12489f58c4ea0a5dc9c5c01ec4fcea333',310150000,NULL,NULL,'bd98261b5759a22e7f81b696b7013a45b027b0f11a287925f53f72149b88f6bf','0e31a850ad61184d5a3083952bc7e8c0418a27af3e1bda49ccb155b64d9beb43','05599086816b26c199e90dde3550e6869bc84b7183583fc0a9be5d8ccbcc2611');
INSERT INTO blocks VALUES(310151,'a0f31cc6e12ec86e65e999e806ab3bfa18f4f1084e4aeb4fbd699b4fe284b330',310151000,NULL,NULL,'a832471b5cdc67aa53bcc0846301fbf67ea94fd6e4e05123672850449c5a833e','371536db2e40b86299aeb73da0787aa7cfac30e7d857502e8549c94167bbe27c','a653d58822e27af471a0c59ab05bd92c69d29cb21e6df0597b36e8a78a6eb8e2');
INSERT INTO blocks VALUES(310152,'89c8cc3a0938c63a35e89d039aa84318a0fc4e13afac6beb849ac37140132c67',310152000,NULL,NULL,'9f356be6399ffef139cca39686f359c8da45279333601380701cc881125da511','2b0a0f2d6618cee846276fff033d524d9f16fb5f5bfd1bceee0eca7a779939da','c8082984ad6f98de13f49cbdcac7f8e9e409203d689b08e3a9c2a91156f45de5');
INSERT INTO blocks VALUES(310153,'d1121dfa68f4a1de4f97c123d2d2a41a102971a44b34927a78cd539ad8dca482',310153000,NULL,NULL,'36bf894215ea0fd3edfc72cd3cf83438111fe4cb63e35ba334c57e1861844ff0','f01946c9bc40aa8a971cbb703d5c3b82e26768d4c07eb141bd472f42b6b0821c','07d52b59be2f76e2c5f6d0b385ebfc2bae49e3da5ce68ecbb00559712ec7f869');
INSERT INTO blocks VALUES(310154,'ba982ea2e99d3bc5f574897c85485f89430ae38cf4ab49b7716ed466afa506d6',310154000,NULL,NULL,'cca2771a492e762bd8ce98afc0f2727439e157ad0357c6c6811d31a003700dce','9ee5cb808c1fd6e992ff8e97f52185945cb27e58020b0b4ae78b2ca4fcaa57e1','30dc587c4d74251613ab52d6785959b9eb1f5758e64bde8762c370073d88083d');
INSERT INTO blocks VALUES(310155,'cefb3b87c7b75a0eb8f062a0cde8e1073774ae035d176e9769fc87071c12d137',310155000,NULL,NULL,'d3da45cfc2139ab7fc3c2e483204edc783655f0410fc63a101d5322865317c23','0398046a0df607ac8900dac40aea270dded61a5efa617cf1c61989abfa9fd4dc','bc8caf33d1effc4d34cc0b1ba879bac4e8482d926e19eab749526127e89aec4c');
INSERT INTO blocks VALUES(310156,'6e3811e65cb02434f9fde0445a7a2b03fe796041458737d0afcc52208f988a83',310156000,NULL,NULL,'e28cada7e2bce41ae35cd7db3313762af3cb894858722119f4b4c16c30953dbd','4415e9d5c32123ba6ac37e10ba797fc7bff55221b6f3308eb06add4d2c6cdcf1','2206cc8e605cc88175e3c0784fea84f21d2ffbc682a3b9ebf1243880b149f0d4');
INSERT INTO blocks VALUES(310157,'51dd192502fe797c55287b04c403cc63c087020a01c974a565dd4038db82f94a',310157000,NULL,NULL,'3941fed81133f2f9e294946923baada93e7d7f1338955ca94e43925c678b7bef','777feca91b9d1f62feb3aa2624435ba43efe6f8c57d0bc6cca3c2eb26f80a1da','4939225709095cb67c57cea0ddef235f1adc541833434398ef9a89bdfdc08a30');
INSERT INTO blocks VALUES(310158,'749395af0c3221b8652d31b4c4410c19b10404d941c7e78d765b865f853559d2',310158000,NULL,NULL,'1d5f36b660c6953a98d21eb7c05e360b7b86d6936fd6456d1ce57bde2235c62e','75bd94c258d36d3f98776b7f755fad9cdb166e3a600f0ad62162fd866c545247','124034dcdaad15ba0c03c0e4ece79664712fbfeffeceba1cff579f49dfcfc5b9');
INSERT INTO blocks VALUES(310159,'fc0e9f7b6ae99080bc41625588cef73b59c8a9f7a21d7f9f1bf96192ba631c12',310159000,NULL,NULL,'b4255637e7ccad7fa9b183fee626477b80108717a9d81b1de31d06138dbd72a7','5ad5f475c95bcad7dc3fe23ced85d93080ec910b8a70254cd24746ca567829fd','931ac63ae44f9ef0cf367f0b92d49beacbe23ff9747fa690301695317db2f3a8');
INSERT INTO blocks VALUES(310160,'163a82beeba44b4cb83a31764047880455a94a03e859dc050da782ed89c5fa8b',310160000,NULL,NULL,'e7cbd7cd557dfceae7fa02f115f43783f99f56a6ce5a560a7a1c94b47dd320bc','8df92560455b6b9fe31b7f71f0e8033a00f12da994d8bd2e9df1d8b085828735','d47be81ee6188d3048a6ceb986afd41b7d67454f0906e9447e3c3e6d295b1cb5');
INSERT INTO blocks VALUES(310161,'609c983d412a23c693e666abdea3f672e256674bf9ee55df89b5d9777c9264d8',310161000,NULL,NULL,'f92bcbdf6853f0b61f05e2ee3a1e1abbd64ddb0a0e930af77a301c456eebfff9','594a7eb7f61605a61d4ac0ed74efff45df423d566ba3f66714be0abc9f076131','1ef0c092b95a1d6ed81e5322f387ccadfd298456cd7257c507b881db37b62bfd');
INSERT INTO blocks VALUES(310162,'043e9645e019f0b6a019d54c5fef5eebee8ce2da1273a21283c517da126fc804',310162000,NULL,NULL,'5b66567952d1ce4b0c9d3071a5ab9b1d219b60e3cde3dd7acfc7b59445a42f56','81c546649d8e9991349a7f819f23336e98cdff087011456dd0ec23b38d0bf191','3448bc0fee982689a24bf62be7e3124b3d64cf7cc99778ec835f73a7d09e1bdb');
INSERT INTO blocks VALUES(310163,'959e0a858a81922d2edf84d1fbb49d7c7e897a8f49f70bd5b066744b77836353',310163000,NULL,NULL,'68dadf50573d5054ee315947adefc381d4843b283fa95c9bd60695f5ad492f60','eaacaf41c124df14719ebf4113a2cf03c8c1e5049d10d840f6e661ec4070d5f0','3c4a2fd7517500f7079f9da60167309fcb2cf23873a04dc53e9de5c932654100');
INSERT INTO blocks VALUES(310164,'781b7188be61c98d864d75954cf412b2a181364cc1046de45266ccc8cdb730e2',310164000,NULL,NULL,'757e4fc6e9bb3972770b120ef82f037fed9753fb5f14a9ae316332ef4d2a3458','f5ce47ae711bf85c87a035718b0869f5f2e052351821b6f666cd174858cd0c07','be304030f24d71d4f264002d692110bbf11318712d99c25e7401c3ed0849d93b');
INSERT INTO blocks VALUES(310165,'a75081e4143fa95d4aa29618fea17fc3fabd85e84059cc45c96a73473fc32599',310165000,NULL,NULL,'7af4ee45e514220ae8009045fae1e5ed341bb297671e5c8e631746db35e48f13','501bea75f09d4da35c248373829cdc7435bb3ded7f1fd4bb51bca1a58fc4538a','f247ef06e8bdf0e0595254f18bae3a560e42237355d7b64d965951d81b95a35c');
INSERT INTO blocks VALUES(310166,'a440d426adaa83fa9bb7e3d4a04b4fa06e896fc2813f5966941f1ad1f28cfb41',310166000,NULL,NULL,'543a3f939edc7a0a9dcf9dcfe70977e9a5aa1c7cda2f25ed81e6ece65c5c9324','9a8413894cdb2c31483abc1ff242ac68b91da9b86b1ec3720a0c90f159599ced','ededb54aad522d3f4f8e6c8e974e47cbee9b027d1f1ea23391031f6381e303ad');
INSERT INTO blocks VALUES(310167,'ab4293dbea81fedacca1a0d5230fe85a230afc9490d895aa6963acc216125f66',310167000,NULL,NULL,'5df2f9b14badf6d22dea91bc7edca6a345dc54a1d92f3f53d038fe0d030e34e5','89acda33c95c62d507420e5f6c8a9303b3cd81ab771105f9b80d24e92f83c44c','ff73eb9a782e27dc7ed3bebb10568d0695e8e3686b3484db1b01bbc79d291e2e');
INSERT INTO blocks VALUES(310168,'a12b36a88c2b0ed41f1419a29cc118fae4ecd2f70003de77848bf4a9b2b72dc9',310168000,NULL,NULL,'4eee95fc1330810ebe409e0500d733aa30d0f163d69d94ab9f94ce48c4129dc8','17d58c87c965cec1bfd763b02f2092f8a263f6b93524ebf763d370fe4a6bac33','d1802c0a9f8f4ce4803edf8345172aee88a9a02b11b1212f7d39862e756fb9a1');
INSERT INTO blocks VALUES(310169,'204809a85ead8ba63f981fc1db8ae95afe92015f003eaebbec166021867421f3',310169000,NULL,NULL,'3ee7677b3f9dacfef3a7f676bad04ab32295728e01c0eea7aaf422d0091e6955','ba969e74798c21df02879e59533e450f7551cf906072a72d54d25d7cdb3c3f93','c2ea7cc357315f8b53c3ad6677d9c8ceb3f285cf7c380438ea2e64d3d69e32ea');
INSERT INTO blocks VALUES(310170,'b38b0345a20a367dfe854e455e5752f63ac2d9be8de33eab264a29e87f94d119',310170000,NULL,NULL,'9cdc8907521f45d42977b9c846cc0acc6b71cb974dba9c4298e1cdcf73a0a599','0e9706265a3bec91d66da3ef2827466238ca7fa5c5e529f08c65012b1b9186b1','869ef8b567433a3991e1d4955d2ea03b4af7b6813b3baecc210a9a07a43b5954');
INSERT INTO blocks VALUES(310171,'b8ba5ae8d97900ce37dd451e8c6d8b3a0e2664bb1c103bf697355bf3b1de2d2d',310171000,NULL,NULL,'2b37f5f3baec5e9eb58e8a0066586904890fd9d6fedc7fbb05230fb7c265aafd','7ed25416fec66a6d32d140cf3cb15fce5f35c447da4f47db3e98b33d633a3517','46abfe3787b3fced3ad26f46c625367cca8f710bb25e6f897b4655d94321644c');
INSERT INTO blocks VALUES(310172,'b17fda199c609ab4cc2d85194dd53fa51ba960212f3964a9d2fe2cfe0bb57055',310172000,NULL,NULL,'edd0325a4442d6aa0266058cc0b94d67537314c8ed577dacd236824b202853a7','7b704f3eb4ae43265560a7b78a7a341ff67af4e1a7932e9a21205244482cabd2','d6d417a42077135ca77a7e7db85769d84222ba8633a18086e66caabe0f08f651');
INSERT INTO blocks VALUES(310173,'f2dcdc5ffc0aca2e71e6e0466391b388870229398a1f3c57dec646b806a65016',310173000,NULL,NULL,'fc983ff27bbb4c6646959a133e18a31db548cdfd6d12c206f3c3dc88963e103b','cf54b63d2638e1e1130f4b96862068070664eff053791ef93371c32dc656547f','6f06e6de5585e49a4bf6e9dd6c664069e49d21bf1c8ed4d5b048614001ef2736');
INSERT INTO blocks VALUES(310174,'fa6f46af9e3664353a473f6fffce56fa295e07985018bface8141b4bf7924679',310174000,NULL,NULL,'ea9c2bf02bc53c61000ba450a3782b1795bea172c35c1ecbcaf8f5e9285c61b0','4b7d71e5699e310769a5a78b2c666a4bb48655e355279c168375fe3e779376c3','6084b28cf78a39a3bb7b4d969a47d7ab4da1d846221b310abd32768144466b0a');
INSERT INTO blocks VALUES(310175,'f71e79fe5f03c3bc7f1360febc5d8f79fc2768ce0ff1872cf27a829b49017333',310175000,NULL,NULL,'c12bf8cadcb48059560222b5c4da6dc0c8200564baa193c078f31712694a2b1e','8535374dc27335189e5548318cd305faffbd8e89bd2e15f31df1bff329eeefab','a1a76787ab139a136c77a4a2c7ec2835159d6285f7769fb0c7fbcafb8d6894c0');
INSERT INTO blocks VALUES(310176,'67cd1d81f2998f615602346065e37f9ceb8916abb74b5762ead317d5e26453c6',310176000,NULL,NULL,'e3adda311a6a57de96328b68d8bf0bc947f6fd23838a8ed9ca376c9f65c5f96f','c1329f6e82259d564d435d891ee1ea3ac79ae536aa28ca62a2a157a7c9eebc13','aaa30a1bdb68db89c81437225578050f77717f006c3250e1f6b97e42d5e95055');
INSERT INTO blocks VALUES(310177,'6856b1971121b91c907aaf7aed286648a6074f0bd1f66bd55da2b03116192a52',310177000,NULL,NULL,'c30076951159c4add7f7c4758120881768485fa6ba79e1f74fdd704d6f1bcf1f','6f02895f41287b50f7b3cb593ed6a6bd86893aafe52c193067a0346492c6dd26','48c405cdcb2dacdbc54b19f86d5d84896dc9f93c155b9adc388eee471d52e850');
INSERT INTO blocks VALUES(310178,'8094fdc6e549c4fab18c62e4a9be5583990c4167721a7e72f46eaf1e4e04d816',310178000,NULL,NULL,'dd0e9dc90b9c78a332f77ca11d7690aa1c84c0e043789b304f462fde04357842','8100e5126ca125e10350e52b261bc05e51c4411106ef81947e538a36d24cd3e1','41cb9453f7288ccb79f94f8c36e76b32b88e6669b191cd75e50f06012e9528d9');
INSERT INTO blocks VALUES(310179,'d1528027cd25a1530cdc32c4eaff3751a851c947ddc748d99a7d3026a5e581a7',310179000,NULL,NULL,'73a115a8c829d809be09a7bac40cc1c137438dae760380d3934e516d30583f15','422ec1069eb08a55f2fc46009e87addf5bcbc0d4a62b1bf67fab50e40483c44a','0f731d12cd134083509061dafcc00a8485205408493e91893af1c62fcbbee32c');
INSERT INTO blocks VALUES(310180,'f2f401a5e3141a8387aaf9799e8fef92eb0fc68370dae1e27622893406d685c1',310180000,NULL,NULL,'b8b6851bcc55d5ee1ff76b2aef90089927f8a7261e4552c533ed0e3f59bdafa8','a23ee88ddbfcea15d08a2b9b27bf923bfcf7acbf102a27ebf681edb09c3152b2','3ba8f5ea1ff767be917f16f28f26298c21eaeb33218d9f6d0fdbcf641ff57006');
INSERT INTO blocks VALUES(310181,'bd59318cdba0e511487d1e4e093b146b0f362c875d35ab5251592b3d9fed7145',310181000,NULL,NULL,'6087d0ff58bf7a6fa9a4f5ba872230bf961f3c74242075baaa3294ddec543b50','2546dc565dd74e72e7c229cb9db1aaf9aaf3b413b5dbc5345b976b16b09e9e63','37183b5fbb613c454777f1ad9278b07cd7db9bf9e7ffacc1a88d4e81a61808c8');
INSERT INTO blocks VALUES(310182,'a7e66b4671a11af2743889a10b19d4af09ec873e2b8eb36949d710d22e1d768f',310182000,NULL,NULL,'9aefa5b4465be6678cf3dcab463b3a3f07ea41e50382c12ab484d2f3fe227c92','8234df864d84841b22a123908c1d4c0ba7c80dadc55417efbbc1f3b395c330e1','7c12098c52e76ddcf65c05fa98d2dc153de0a8935d53c6a6d55f57a7d8ee0269');
INSERT INTO blocks VALUES(310183,'85318afb50dc77cf9edfef4d6192f7203415e93be43f19b15ca53e170b0477bb',310183000,NULL,NULL,'81b635f67de058c247c26c9e3900f7d4c2058cbff30136edf44774e07926eeb4','d89499773e82dc20f5a6eae54ef37205dcd990a5a5b76ff9ecee7625cf245181','f0efc017cae31f7a34df530f777771915f6e81da8927516332cd281efbe7408a');
INSERT INTO blocks VALUES(310184,'042a898e29c2ebf0fdbb4156d29d9ba1a5935e7ed707928cb21824c76dd53bfc',310184000,NULL,NULL,'0eee879cb2f5dc03d95a0330013e9acd0e2660e7cda89c77845b2ef4705d356b','43b88d01422bee4d3d5efff7f6908fa31b73a3718aeee3c950678fcd1a09c96f','97b2007135b3fd0d04493326f4612e2683ec1ef37c13a46da8d9ab0ed6432960');
INSERT INTO blocks VALUES(310185,'bd78c092ae353c78798482830c007aac1be07e9bc8e52855f620a3d48f46811f',310185000,NULL,NULL,'bfd50b39a427b5b468e51d67b066074b4075a81e6ddf85c376f9d894a2f389e1','20e869298747c3eeb32f95bd31afa633898b4d8e34aab6bc31a89a51e25142bc','eb1f88cc16686755a6a522cbb96343249e6775aae7bc6189fe87d8fce4818310');
INSERT INTO blocks VALUES(310186,'e30a3a92cc2e5ad0133e5cee1f789a1a28bea620974f9ab8fa663da53e5bf707',310186000,NULL,NULL,'2d877ee04db3922eb5b47e91d9c00a3e3993ee902aab3ef9dfb5e7c75d47e355','3b7ff2b965e847bdb7cbb941970dd191501dde4b776920d480568d35527a4a7a','e06ad39dc9c586da5e9e2e364092300836d3a8c64b98898c64a1641f860e53e7');
INSERT INTO blocks VALUES(310187,'fc6402c86b66b6e953d23ed33d149faa0988fa90aa9f7434e2863e33da2f3414',310187000,NULL,NULL,'dfda31dd51bcc568bb9b6b215bce731b04c5c64d58f8f9f4149635218fc86af3','86222e7e97c7f8c44f72d996e290cd7e082420f975a3d21c85cf08c2c7ce28af','e1ff6f912d8e4406eb5b1f070ee944682fff2522af1b953ca05d3f32a8bcc864');
INSERT INTO blocks VALUES(310188,'85694a80e534a53d921b5d2c6b789b747aa73bf5556b91eeed2df148e2ada917',310188000,NULL,NULL,'f3970384b9ad59174484fcb89924e680c4583723bea58b93c86d1a52a174f3a9','b990bede91744bee382fe9c6fe6ce9d45f50fe66366874c0e146df118a4562f1','7a2999bbc62f5e52d29467937e13e6817ebafe779c575ab3d7516c3171653676');
INSERT INTO blocks VALUES(310189,'7c036dadf19348348edbe0abe84861f03370415ed2fec991b9374dbb0ca19a06',310189000,NULL,NULL,'a41c7ff72b6715f521f19dec03718c9f09a749d2b3eca4a70a03cc251d3e1206','7b5a8f6080afcd574d8d1bd18e5fa226850c77b399b29aa65135225b69c7b250','cc9ad4dab70185b6479c997e64b5e921ba99911ccbe0c31a2ec39c7862231322');
INSERT INTO blocks VALUES(310190,'d6ef65299fb9dfc165284015ff2b23804ffef0b5c8baf6e5fa631211a2edbd8d',310190000,NULL,NULL,'9785947dc49f24e99633ff16eb8a06df8d718680faefa079c59cf6c5692a522c','02f1b5ab934c2fadef3715b0e20e31ba97e60512b2a784fe25fa403574a70de9','a4dbe275fe09b7741d22d3a5ebf5a5239745eacce8794524925459726bf336f4');
INSERT INTO blocks VALUES(310191,'5987ffecb8d4a70887a7ce2b7acb9a326f176cca3ccf270f6040219590329139',310191000,NULL,NULL,'b94f32b60946dffb594d95c77c3b1e93c80ec97046478b8eaebf1a3e3bf38d6b','2924f2704ec267d9b49f1e754db0f8805c88820f898ff0407c0659da2ff884ec','9e9bc78ff659329315def62f0b932470b91d51ead9fc28877a05024cedb42c50');
INSERT INTO blocks VALUES(310192,'31b7be43784f8cc2ce7bc982d29a48ff93ef95ba18f82380881c901c50cd0caa',310192000,NULL,NULL,'71d94396abe8df50e6bf704a95befa564fedebad5ca9a325ccabb33af35cde26','974afa62b43150c74c60c257c66cacd623be72ababef72877bcc0cff10cf04f0','23ddb4f61682815865e9c1cf728b681fc6d7b66d10b513f81ed2c679e3a28e09');
INSERT INTO blocks VALUES(310193,'ff3bb9c107f3a6e138440dee2d60c65e342dfbf216e1872c7cdb45f2a4d8852a',310193000,NULL,NULL,'3f97f95a0f71844f358de1b6bbd61b88d41de52de14368bcca335d8350783adb','da9abde03a2a5a984efb4633758077530339cc7d66522b988c59c98ace4ba91a','66d63b478a15302ff10fb2faa35d7023d98195ee419a6d86ee7ba2b5b274c715');
INSERT INTO blocks VALUES(310194,'d1d8f8c242a06005f59d3c4f85983f1fa5d5edcc65eb48e7b75ed7165558434a',310194000,NULL,NULL,'cfa48069d88f7ab7fc67d7ff9587fbddccb9548d9983023ae559c057fabc1c4b','8768877970307ddb2058dfc8c1c44850c0e19e009528b27800569fa868b5523b','5d3776de206e832b7710e85da0b6b1cd2526b8724db224f191cd911e864bad01');
INSERT INTO blocks VALUES(310195,'0b2f1f57c9a7546faac835cbe43243473fa6533b6e4d8bf8d13b8e3c710faf53',310195000,NULL,NULL,'5e6ed1a5a1297aca307ab120cc87a3fae478e20844d003fc064f33aae4d5858c','450f740efbf0cfb53dccd8f9ec2396402a404f8b36ad4df0fb493421911e8870','d8bef15e9caf4c7eabf3350c0a95b9b3bcb21f8066019cabd6d66f3547bf3eff');
INSERT INTO blocks VALUES(310196,'280e7f4c9d1457e116b27f6fc2b806d3787002fe285826e468e07f4a0e3bd2e6',310196000,NULL,NULL,'88f1aebaf21a6d25b53d66808e9bd17d8c34c72f32aacbaf884afbf48c9b58ed','116b3a4304f08d047baf55985eb009da6099b0b43f9ca9a57104604d04530784','f033344f0f5a233a91874c95327a22f889feae3a21dae4932707819dc288b634');
INSERT INTO blocks VALUES(310197,'68de4c7fd020395a407ef59ea267412bbd2f19b0a654f09c0dafbc7c9ada4467',310197000,NULL,NULL,'1411b054d9af06c230753aa686c2d65199af1aaee0fb527afafd46a1e4b78a4d','30b82435736ec8c545028c1f9767da4b8273b00e7bf3274f65d4d80e318d2d54','e26fd91690649ea3fd1de26059341d2e6bb1751857b1cab99e41f4f0a00f800b');
INSERT INTO blocks VALUES(310198,'30340d4b655879e82543773117d72017a546630ceac29f591d514f37dd5b1cc2',310198000,NULL,NULL,'2d244b182e728dc54f87b8b16a335574614c51fa5466efa815e7b64f4f9f3356','471f93ee9d82ef821e832b143f941ebd0c06b3d7ac010df342b47c6ac0c6192b','a3e4e7175bef0165a4a889f01b43d94db27bbf727d2fa68330417b79a42f262b');
INSERT INTO blocks VALUES(310199,'494ebe4ce57d53dc0f51e1281f7e335c7315a6a064e982c3852b7179052a4613',310199000,NULL,NULL,'9b03fb88c0f48fc8497f8c1f1e05b1f6cb098a317c1350c5e35c8fe98b012d7f','6cf9c6ffbb64b80d27d6803532657eaebc163b8cec4c6daa75b1c02c1c89f543','2ad2887851826891f9ac917ce0f925fc6c981ce7dbfaa6a9a09a7f8850dd0132');
INSERT INTO blocks VALUES(310200,'d5169d7b23c44e02a5322e91039ccc7959b558608cf164328cd63dbaf9c81a03',310200000,NULL,NULL,'083e013e5c43b772477c5215829e26c36cdc3f572bba7ec8ed48fe048a118c64','07959b2e6a22587d00f58843a46f634a23f6b590d98a9f893ff20babd32aa04d','6e648e78f39acfe00dba4dd1f1e18fbfe0f4816a9925b7e792d23f4912f058a3');
INSERT INTO blocks VALUES(310201,'8842bf23ded504bb28765128c0097e1de47d135f01c5cf47680b3bcf5720ad95',310201000,NULL,NULL,'92fa9809cd87bee813f6a66bc9d18a1979bfd22fb0f570bd86b9503045b44e1a','106a1b35e57486c07488aa4e87eee504486121ad4a5e4adbb2597b5ee46c3801','abccfa86a99743068a9cce2425c6cd5b5700c874366e265c07dac9277cc32250');
INSERT INTO blocks VALUES(310202,'95fa18eecbc0905377a70b3ccd48636528d5131ccfa0126ed4639bc60d0003d8',310202000,NULL,NULL,'21d62a6b343fdd1b701a04be84b8a26ec91a43299ec1b813281ede71a3bc4cab','074a07a8e8013acad07a7aa267f1a785ae58cf478f0fef3ea1f9a87c2f3459a4','afe4ea6c155b31d3cc15910f2f72ff12b13c3b6420d2b31d55befa045174f8c0');
INSERT INTO blocks VALUES(310203,'ab15c43e5ac0b9d4bd7da5a14b8030b55b83d5d1855d9174364adbebf42432f8',310203000,NULL,NULL,'51faaec9285f0a825c279a18c5e52025b2a953fe6484d7cdc9c82759e52e47ee','1c8e22359eeba6011d05eb7174faad25333ff6045c704e949bfd8aed672112ce','bfba2a293ab7521628e0ff8f16c0046d794fe07526679973d76dc0efd4ad46c1');
INSERT INTO blocks VALUES(310204,'18996fb47d68e7f4ae140dc1eb80df3e5aba513a344a949fd7c3b4f7cd4d64cb',310204000,NULL,NULL,'0e7954809b3dd8f79085f6cef85e9db4c07c7f8946c2d6bd7b2c3cf4d5f8b5e2','5593b09baa3806c052e495fac1bf2794713a74e8c0d4a963806115ad28ed69af','36135da3b0344bcf9a0a0979a3fb83b84622149dc8833f58e03f9b2f3eec2459');
INSERT INTO blocks VALUES(310205,'5363526ff34a35e018d1a18544ad865352a9abf4c801c50aa55742e71630c13a',310205000,NULL,NULL,'fbfce872a117f6c01a0287625c6e9fee06fa49502ce9bc149ef3c391b4767b01','a126f43ede3897a2cfefe0eefb6abeffa24abecc832ac73af93d81f41c5e6836','2780acb94d98a34949be725e91011ff5cdb4372e3c2c2180b10e51520370ac12');
INSERT INTO blocks VALUES(310206,'0615d9fca5bdf694dca2b255fb9e9256f316aa6b8a9fc700aa63e769189b0518',310206000,NULL,NULL,'a8351b5125e03d657c1913f17f392659e92cc5db48d803f8f8088bf5582aab6d','6c2eabc7e461837c706c02a00844b8a0391c4397e6391209b0787d0f7385c8a4','ec82e9d208b334042f3b3f9863ea99990fe19df0a52c29f9958346b2a2ddc1d1');
INSERT INTO blocks VALUES(310207,'533b4ece95c58d080f958b3982cbd4d964e95f789d0beffe4dd3c67c50f62585',310207000,NULL,NULL,'afe40bbf65c62b0ee23dd76c83703e47c4dacd818626ac6ade4ee7ffdfd42e4f','772a89a5e4cd4738594662470e87eb8aeb1bd5978a0e8d42df14ca689f6239ad','e47156eec63fdbe264d408e562206c2e94892a93cc7061573bed15823b363925');
INSERT INTO blocks VALUES(310208,'26c1535b00852aec245bac47ad0167b3fa76f6e661fc96534b1c5e7fdc752f44',310208000,NULL,NULL,'fe56f24fc02d3f254b9fcd29da354ced0091feafa4edbb517a76b47a44802cda','d5df8982430661ab99decbaa9719f4acd9377c8c6965b12aa9e57bff60a391a6','b7fb45b7a2d0a1403c73d238893f12cd13a78cc1b5684fcb0dd6693a8a4c7720');
INSERT INTO blocks VALUES(310209,'23827b94762c64225d218fa3070a3ea1efce392e3a47a1663d894b8ff8a429bf',310209000,NULL,NULL,'fe52a4d3fac24defbf2c4b84972ec7a6e930efe6cbe8664c540a0fe3fbeebedd','98ea9c609059a779807c1efba29dd985799b0f436302b683eb5a532d886ccbeb','f34fd1c15787a6d44308734100ac056301e606a0a4e020729c1012a3c428fd26');
INSERT INTO blocks VALUES(310210,'70b24078df58ecc8f7370b73229d39e52bbadcf539814deccb98948ebd86ccc0',310210000,NULL,NULL,'a3751fb54e905c3fa6c274ea9e0d18b8ba336bd45e035f47f13a6017dbabf0eb','b1b4a8665f1c85db8fdb977ec16b24e0763d1a47851fc09bd03be83682d4955e','619e7de495038cfe64d47adeb255e0b9fa3cc3872542059d084c9d6c086c9550');
INSERT INTO blocks VALUES(310211,'4acb44225e022e23c7fdea483db5b1f2e04069431a29c682604fe97d270c926d',310211000,NULL,NULL,'7c164930f60d58dd25b665cf5614e9970cafddb7058559de2a8ac3ea1301caea','a0cdd3b6f9cceebb0bf23c7e1a338855e7dae2f06b62e2209061f67b0d016643','2ad78ee536a4568b6e6356031d7c42fec24f4a455e1412af3601bf89e153c11f');
INSERT INTO blocks VALUES(310212,'6ef5229ec6ea926e99bf4467b0ed49d444eedb652cc792d2b8968b1e9f3b0547',310212000,NULL,NULL,'57480882cdc243b3e737ec1e01ce83fbf00ddfe02f1d4e2d7b4525d39d9397ee','797ae04a956be998e58487197df74c42e0730ae7ebed4e371b600f5a9cf26593','702a40b08b784d298909d090a1b92cda5340aa82b711544d072f20f9a6a6680b');
INSERT INTO blocks VALUES(310213,'17673a8aeff01a8cdc80528df2bd87cdd4a748fcb36d44f3a6d221a6cbddcbe7',310213000,NULL,NULL,'af7647d35b3dcc105c98b29e7c4e2fbd34395783ef58e44522c1dd0c600d0d38','3df447d4fbea8bb48603df40c7a91f0c29062029d621981da8e13269481ca964','9deed6ba5c4ff87bded8b2c5c3aca16ec739b28ed0ac4cc3c7919e64bd578ee6');
INSERT INTO blocks VALUES(310214,'4393b639990f6f7cd47b56da62c3470dcbb31ef37094b76f53829fc12d313454',310214000,NULL,NULL,'a64fba121409846cb36a99194ce3a44423129bf72db5f5d2d1e4942ecb5f6ba1','ea0dffce528e4f330b333cce2255e64569331630654cfa62c0504392fe56bf13','63c6573f6d78a8331ceafc0cb4c7f5e8a1d71bdc2a643f22e8d28bf71a9666e7');
INSERT INTO blocks VALUES(310215,'c26253deaf7e8df5d62b158ea4290fc9e92a4a689dadc36915650679743a74c7',310215000,NULL,NULL,'4eedbd751e13d2d04ec7ff44791d0020f1c410fc0d1b344adf6ee0cc3b40db8e','8f577b87b10a28ea38747604352ba5ff7e0ac0ce1802713bebcfeaf09eb18d11','a331e70242b42249da638e2d1a83a30978228e25db9ce3e67a71356c3dd97a46');
INSERT INTO blocks VALUES(310216,'6b77673d16911635a36fe55575d26d58cda818916ef008415fa58076eb15b524',310216000,NULL,NULL,'7ddc42f86abe7fcb0d1c19307034583c32712fadbba4f51651403287cd28b1f1','7eefd737163277ad7df721dee15092f397a1d8c715861f022aa4ce36dbb45c0e','11c25ab40e663ae964502a0d55068c76565b718691ce90bf6bc43053ded26b86');
INSERT INTO blocks VALUES(310217,'0e09244f49225d1115a2a0382365b5728adbf04f997067ea17df89e84f9c13a8',310217000,NULL,NULL,'554b5440b9bdf72cdcd42e75351e8c04f0d2911d858bc39821c0a0e78820e6b5','08dbbf0d88866eb1c5a9a57c77a4355bf3a34f1a02b4ff9900630dd8d01dc75c','1f21d18d083743ae14d8b0feec39b117a686bbd723c7817962bf4c3e464064ec');
INSERT INTO blocks VALUES(310218,'3eb26381d8c93399926bb83c146847bfe0b69024220cb145fe6601f6dda957d9',310218000,NULL,NULL,'763c3cbcf60a49efd412d04accfd5aac28cf9119128079740ad2d13070fad6fb','cecc38c935fe6c4c793e729c8b051426636c4634cd89e754cbb123380fd3e10f','54e2f922ea7c8903f267c7248440744aaa3563b03c7d7f98b0a9d0587f9a4785');
INSERT INTO blocks VALUES(310219,'60da40e38967aadf08696641d44ee5372586b884929974e1cbd5c347dc5befbf',310219000,NULL,NULL,'51e18f4b6c4693f95a31d80c25b34963c3cc18da263cefd2cc2b838c6611a3e6','ce32b8d839223e34bea37cc41e50c6bcaa4509dc4a0f1a96ca4a63c52cb314d4','ff1f88e398684502e58b8ca5a73f44e0cc2f7bcb63b1726b8dcc0631f7809518');
INSERT INTO blocks VALUES(310220,'d78c428ac4d622ab4b4554aa87aeee013d58f428422b35b0ba0f736d491392ef',310220000,NULL,NULL,'abf25fe38cd86494dd70347779aead711bc8ac9e81a61d0638d5e0e062d72ddc','08e41a977e4a8f6253cbbcd9e82372c64a2782478eb62b88c528e569d62e7fcc','15ba369ddfda0afcb6482a31caa11b728508f1da36be1a0ce55a67621d902a3a');
INSERT INTO blocks VALUES(310221,'cf5263e382afd268e6059b28dc5862285632efe8d36ba218930765e633d48f2d',310221000,NULL,NULL,'12731f8738350747432c552015a6c730c1f47d93cebd2bfd49a95911f0f64870','54ecf0d01eb8d28b8c9ec75f1ad3c1e1555a8d3dc617c11f985c451890780b61','04255272fb39d7f14aa372711d38e412f7d67850b1e8d35bfbf7ed3285b56e23');
INSERT INTO blocks VALUES(310222,'1519f6ec801bf490282065f5299d631be6553af4b0883df344e7f7e5f49c4993',310222000,NULL,NULL,'3d3acdb4d392834e7b2b7a8f6a0b72704dcdb60155d79c4d3e407139df0e8754','71ce6002225ca48225a59d21b07c90e665f94cb971fe3addf63d6563d3529aea','cb71ff0b347696538e3f997b971ac006060b96af5257e5e67ebd6847a614adc7');
INSERT INTO blocks VALUES(310223,'af208e2029fa49c19aa4770e582e32e0802d0baac463b00393a7a668fa2ea047',310223000,NULL,NULL,'cb27248e139bbe0e19f2643f185b3716b128fe8f4834f75771ce8877d6bc796a','942280c6be975a0747c59fe54b4b8f936ba425a357da4b0bd9683d709420729b','2a4bd36a9cfc48103078c24f278300216cc5aa05ccaa2a69403391cdc026c0fd');
INSERT INTO blocks VALUES(310224,'5b57815583a5333b14beb50b4a35aeb108375492ee452feeeeb7c4a96cfd6e4c',310224000,NULL,NULL,'d85b4aca19db03ac7d4715c7e4c99ddcb0147a29754d6ba2b1bfc14fb859d777','434cf2b684b3f4d79270af1d61ebfbcd67427cedf5bdbb38c3464c33403048e0','445f93a9e55fe1deb9fc41f861ef58cf1b5b79602149192cb6d332d3dbeff39b');
INSERT INTO blocks VALUES(310225,'0c2992fc10b2ce8d6d08e018397d366c94231d3a05953e79f2db00605c82e41c',310225000,NULL,NULL,'2f2d743332603d187b3c60df541ff6dc4db6f2643ada8ea74ee1bbae63311ede','5a2105f681bddf9d4ed7515c9a7a99ee9df246fd0667c9a942332676fab4f20e','5534cbfd375db3db0e67c7f9e0aee6c9bf8a96f210b36a5167a337fa81771aa1');
INSERT INTO blocks VALUES(310226,'b3f6cd212aee8c17ae964536852e7a53c69433bef01e212425a5e99ec0b7e1cb',310226000,NULL,NULL,'aeabdbebcabffde5d4c2948a6fd23ad45682a5ac3c0f4efcdf6e2ff7c3efa047','783b2b2f7ff005a866c5a76966e15ede685f6c7365d7f4bf0cd4768411513cbe','6ddca30db81fa9bc79a922cdf5eb0b6b063d0fc52ab8b3a65ca50ce8f516733e');
INSERT INTO blocks VALUES(310227,'ea8386e130dd4e84669dc8b2ef5f4818e2f5f35403f2dc1696dba072af2bc552',310227000,NULL,NULL,'64ce8ab1105e7b18bd409466ea8349db3ff923c870a7f770591d958de839d578','53614ddf1b34430c76dc734d28d402307af33be96855c02b9d2ea4fdda018004','caa27f9a084df49abe73039a348a19df8273cf1f3ecf327e94d7a1a9c98ee2cd');
INSERT INTO blocks VALUES(310228,'8ab465399d5feb5b7933f3e55539a2f53495277dd0780b7bf15f9338560efc7b',310228000,NULL,NULL,'d8de23bf2da33d9283fa566009a6d483d309715a580c89362057369a761f5359','b781d86affa3a9067966134bb594d385553cd84c6d511705994ec9fd18dec6b4','cb0dd4aac002f1bfa64b25349b28fa54ca0dc2e02ed0cf185f8f0dd6ba3bb6f9');
INSERT INTO blocks VALUES(310229,'d0ccca58f131c8a12ef375dc70951c3aa79c638b4c4d371c7f720c9c784f3297',310229000,NULL,NULL,'14af0329dd715d6e46ed341b0d9bf1cc27df9ddbfd66a3d9bf8a21f67379b821','6583532fa45e7dc043dda56cc8baacc7eb68bfc7d759ec3ac51474f309432a50','34842f931043a474843df16c7de1436f7c6f2099500b13f59f616bd8ae799be4');
INSERT INTO blocks VALUES(310230,'f126b9318ad8e2d5812d3703ce083a43e179775615b03bd379dae5db46362f35',310230000,NULL,NULL,'011cb00aad1f3de9ceb931c44e75882d895566a3db5eca6bfbad9b83f9dbe34e','5cc086c6445360709b613f8c783d7b34ba3023328bb50a34cd425f5cbe7ab7e8','bce64e25c7074e587b4b1a5b50c0ab69f87c7d82ce46f1eece8294295f376d90');
INSERT INTO blocks VALUES(310231,'8667a5b933b6a43dab53858e76e4b9f24c3ac83d3f10b97bb20fde902abd4ceb',310231000,NULL,NULL,'7cd32dfad9d990033b60f61a2db2b15871a3ac80667133f61ceb83731d940ee4','a267cfe4beb9423c9c4f0ae219aec06b8501d431cb6d1e52ad1969499e8c84b9','ff05abaa9a77925b07354b0b3b7ef7758641638cef93f1b1d01a43a20d6b03e3');
INSERT INTO blocks VALUES(310232,'813813cec50fd01b6d28277785f9e0ae81f3f0ca4cdee9c4a4415d3719c294e8',310232000,NULL,NULL,'a35d9ae612eb82f15ed0e9661f70516c856388e04524b1edebd44a085fc5b9b3','b0467a93e29d3690d9b77ab561d9fb5e9ad29cc8025d29b320a3e499dab18f84','d3dba31aed1c57a4282a92ff32c96c69c5179ae44553440f7f03dc63251c791c');
INSERT INTO blocks VALUES(310233,'79a443f726c2a7464817deb2c737a264c10488cac02c001fd1a4d1a76de411d6',310233000,NULL,NULL,'64c113fee5a96e865eeec651c4c19db59f380175624b41e4293a7c5249e07c21','fdb9b6b330666406b0972e36ea4028685c30eb90dd1db695e1a7d5786671f7bc','8edc9615d9a83b2931deb4f20e09c6ebacd82662e5b8593b162fb7352e1f6e2c');
INSERT INTO blocks VALUES(310234,'662e70a85ddc71d3feae92864315e63c2e1be0db715bb5d8432c21a0c14a63cd',310234000,NULL,NULL,'3e717b506377869ac2d1ce761cff561cb7f92b36f0dcd673aaca5872941ea62f','a5af145f87828fd8087a2e459792aec8c5ce9630b6cccc2767d01b0827d889c0','d38958eacd7ea10e21392f8304c18b5d0adf6ebf3c06215e222b33cd579264e8');
INSERT INTO blocks VALUES(310235,'66915fa9ef2878c38eaf21c50df95d87669f63b40da7bdf30e3c72c6b1fba38e',310235000,NULL,NULL,'98cdae83348e154003e0f996a2a15b29a01f8b8f13913287ffb08216b6593db5','c635979140e5c7ac3fffdd46cb18e0583950b6c3d29141c1add96f122b21ca37','f54227c6362700dd84608eecad00b1ea430e49bf207d0fa3f33d16dc82cf19f3');
INSERT INTO blocks VALUES(310236,'d47fadd733c145ad1a3f4b00e03016697ad6e83b15bd6a781589a3a574de23e4',310236000,NULL,NULL,'698ab5d57ef541b74baa783d053729b4ad93b82fd499e9d698df5be5e7000e10','c262d15ac2ef93d552a261e02f601112927150d9d6e1702feb2c4f8e36f34ed5','7dffb8b3e9ba2bd43742e2facb198b62efb4fd29aa2fc1ea0fa85f16e389048e');
INSERT INTO blocks VALUES(310237,'2561400b16b93cfbb1eaba0f10dfaa1b06d70d9a4d560639d1bcc7759e012095',310237000,NULL,NULL,'a8fee2002ddd2c3ac0fe61d69fe22be2d66f692a7e345027ebdae5d8bc4cdc28','ebb39bc4a1ce186863058aea92a4279898148c2550fd5bbddcc196ea4a6ab3cd','ef0dd1e8c3c05a8b1fdbb658037bfac3d1e26475d973b20b3f2f2ca2228ed221');
INSERT INTO blocks VALUES(310238,'43420903497d2735dc3077f4d4a2227c29e6fc2fa1c8fd5d55e7ba88782d3d55',310238000,NULL,NULL,'ce36465c6c89501b2ce6dcbb7be22425d2beea494a76163b3d6a6f42bdadf048','c371257316ce55427e98f3b95220ca18dfcceb2c159f619e3b378e6eb880a807','a9f826e0902970cf781ba6681e14333f5b573d2e2b3573d5b43f4d2c8f6dfe56');
INSERT INTO blocks VALUES(310239,'065efefe89eadd92ef1d12b092fd891690da79eec79f96b969fbaa9166cd6ef1',310239000,NULL,NULL,'416e6c05a922be676e3a177b9df3530fd9e396eb08a8fd7abe75ce6a38570579','fae0ddf524c32ed0a8af9601fce82f82494004dc5797d0ff2c7a308e1fc3dfed','2f7bcaa74e0b5427a26211f415519aa07a48af16f89dc77b793206ca2c222097');
INSERT INTO blocks VALUES(310240,'50aac88bb1fa76530134b6826a6cc0d056b0f4c784f86744aae3cfc487eeeb26',310240000,NULL,NULL,'949974286eaaac0b97a4be7b59632ca7c8cbf867af182c9eb385e128c4c95e3e','860a2f96b7cb7e5c9d8830b6a6d4d3c1907303b0153e325e6cde85526522818b','7ac6d34902f04ffd4dadee7ccba998e94b553c2ace1d92f8b509bc3213d71e4a');
INSERT INTO blocks VALUES(310241,'792d50a3f8c22ddafe63fa3ba9a0a39dd0e358ba4e2ebcd853ca12941e85bee4',310241000,NULL,NULL,'8913a4aa63332294fac88fbe4b7ee706eb22081d4d99d43daac70a351e7ece23','e7e5e8696c7c52571b7b721ec471d852f0e0dd293d8e0f1b45daa54e6906ef47','e13742897c7ce9558cea3bd506bba968558d57f643b48726fdd16745ef51c988');
INSERT INTO blocks VALUES(310242,'85dda4f2d80069b72728c9e6af187e79f486254666604137533cbfe216c5ea93',310242000,NULL,NULL,'8f1b181a509ab2857b06ccc23aef0027055973be686a4d265e800acfcf5b87ab','d8046fd6eb413818cebfea75b9b3fa0f4d7fefb31be921457975c519cc3cf6fb','6073bd949adbdd20a681f2368e57a600730275ea5cd5912cd96053034b767f71');
INSERT INTO blocks VALUES(310243,'a1f51c9370b0c1171b5be282b5b4892000d8e932d5d41963e28e5d55436ba1bd',310243000,NULL,NULL,'e5ee8b2d614dca565c44d8c47841eaf83ef975da3469c54d5b4a0d8eab79abb0','f415df5f8182e1586886b44f652b9c333fca9055ef7ed78fbb37841007a0a9f6','db4b78709ccd6004d50c9ec018582bb753a8a89d416af9f4852162e759891ac6');
INSERT INTO blocks VALUES(310244,'46e98809a8af5158ede4dfaa5949f5be35578712d59a9f4f1de995a6342c58df',310244000,NULL,NULL,'452445ad65215590c7df72bd8fd7379113541559287f5342ccd27b80afee5fb7','13f686af2b712fe4cea4f6147fca88b8c827c97417c0724daf6212ba38df1a7b','bfdbd2b6aebb001ba62f2447f6aaec0e050831044db300f9520f6556a39d9f0a');
INSERT INTO blocks VALUES(310245,'59f634832088aced78462dd164efd7081148062a63fd5b669af422f4fb55b7ae',310245000,NULL,NULL,'7cc905ca12d65450baeffc187ca353ddd39961fb64357cee5cc3a836ca48ffe6','e84a453658e6c545ea1b12d752144aff533f9b8a2eada459c48f8e5b7c11ef41','c0361ba8960f79aa8fa76947d37bf9685ae9a1e4ae8dff7627601c8cd3842fe0');
INSERT INTO blocks VALUES(310246,'6f3d690448b1bd04aaf01cd2a8e7016d0618a61088f2b226b442360d02b2e4cd',310246000,NULL,NULL,'adefdd89b7753e7f7256addd703a07b687958832a9f54b7bb3f513e8085c0a09','96bb2ca11f60e1ee9ee3351c4b2eac540566877c7b7c7d2bf273f5cfd486b828','a77b1cd4aae77733326647ac665a70e3f0ea6ba89f9928dba4b2624a1fd89e39');
INSERT INTO blocks VALUES(310247,'fce808e867645071dc8c198bc9a3757536948b972292f743b1e14d2d8283ed66',310247000,NULL,NULL,'07e493bcf950955f6734715aee325c048606e794fa5e50556ab1393d80951e85','e1b77ee20ca02149493f23343de8aee74425facf2a48693d3d405bcbe57a3ac6','76a320e3db5c9d5a5279029a9aa075abfea650961c3eb9cdc73da46f888ec7eb');
INSERT INTO blocks VALUES(310248,'26c05bbcfef8bcd00d0967e804903d340c337b9d9f3a3e3e5a9773363c3e9275',310248000,NULL,NULL,'6980fb3988505e2ebbe55af2108b1fe07b73d54a229937a60dd3d5d0178b5099','0d02f58d1efe8c2f79c6522e2a8c32afaf83f0e4b2f824c816d429b8508c529f','769b359cc89c192f1560e7a1a84efe0cdb031a582ab797d798dc4826826cc0dc');
INSERT INTO blocks VALUES(310249,'93f5a32167b07030d75400af321ca5009a2cf9fce0e97ea763b92593b8133617',310249000,NULL,NULL,'6c5b1d48f75898f84fd80f1669ee496e3bcbb219c5f8a7e848589cc1760d1259','20407732bfac0347d6101097d36535416a6185c77f24ddebbd0a28230b51471f','fbee1f6f4b16146f1116c5ff9f67fb947497c5993eb8da68e06754a10530c414');
INSERT INTO blocks VALUES(310250,'4364d780ef6a5e11c1bf2e36374e848dbbd8d041cde763f9a2f3b85f5bb017a2',310250000,NULL,NULL,'5cf3fd14a41b6721ea9b5a13de513e40b072be9af84fb94b348d4cf3ee9fef4b','393663004eab7123cc72d2965657146c7d7fa0bd0d5d082023987ba3c690deb7','2bc62fc037d3962b3e87185aca10dfb1544f4224108e4fac804e29e9a79de8d5');
INSERT INTO blocks VALUES(310251,'63a3897d988330d59b8876ff13aa9eac968de3807f1800b343bd246571f0dca7',310251000,NULL,NULL,'e7df094c10bdeab347c52a9621337aa633188be1ddd6876eb0231ac5c696191f','8b9100f14da182b09eaa7b9608cb61ebac32cf00b9091268ca16912d47283ae3','f2985bf9dd471ad20d4d4ea054982b54d68234777622bc7d552b525ebe82a2f5');
INSERT INTO blocks VALUES(310252,'768d65dfb67d6b976279cbfcf5927bb082fad08037bc0c72127fab0ebab7bc43',310252000,NULL,NULL,'f38f6c79a8c61cce799ef455b3d5a2e748d0f58cd6a466cf858b5fa20089adda','ed1f80b7e1709652f6b7f42050dc86bf0224cd4974ab7b02f36eb5c01aa6cdf4','80b2433e2b277e5a59e7d19310007b17db618d2840977f8114eaaae8ae33b105');
INSERT INTO blocks VALUES(310253,'bc167428ff6b39acf39fa56f5ca83db24493d8dd2ada59b02b45f59a176dbe9e',310253000,NULL,NULL,'280281bfcd6d35b3a6d35821fc9a9db7be591fc9cd5ef250b1b5a6de7253b9a4','62d3de7d0e6cb26ac461c4c95c1483c81456bfe6634dfeab51c3a8553662405f','a0e17a50aabb3511a2ad4d8b7e5d93f96d7dccf03f986aadc25e2b01103ed3a0');
INSERT INTO blocks VALUES(310254,'ebda5a4932d24f6cf250ffbb9232913ae47af84d0f0317c12ae6506c05db26e0',310254000,NULL,NULL,'ed3857ae6cf9fb7cef2af88b4f59be0aa4c9eeade9e86bf2907df7d99fc68fb1','ab5c44304b777043a60c0310eae04dae167cdea8a39c499cfc34df60952dd81f','1ad3d7d6ed11d153740325be9bc0222d4638ad0c9602cc1caba2f631d875745f');
INSERT INTO blocks VALUES(310255,'cf36803c1789a98e8524f7bcaff084101d4bc98593ef3c9b9ad1a75d2961f8f4',310255000,NULL,NULL,'d587ef63d570242d5708352fd7a2080a1ccc9a4745db686422feaeda8efd8816','3971da04f84112a6ca9a4fae78c83501c3655eb374f346ce266ea1bff6ba0bd5','4ad9dac503dfc949e2c0a5fe437d2f8bb8cbe2cf1d7f37f106ec9d09084a7a3a');
INSERT INTO blocks VALUES(310256,'d0b4cf4e77cbbaee784767f3c75675ab1bf50e733db73fa337aa20edefdd5619',310256000,NULL,NULL,'6e1efa8d8e96d70fbc9b6ad39bc6fe0850d2b5a029a7efd2dbce45677d84cdf8','2ef0a10bcf79915e01c7354a0e051fdacf9276ccb78404c334d105b7baf6547d','e96e490699db46ff91393830dfe4e58b053244e104dcedb0fc4281e21c20299e');
INSERT INTO blocks VALUES(310257,'0f42e304acaa582130b496647aa41dcb6b76b5700f7c43dd74b8275c35565f34',310257000,NULL,NULL,'4e300f307405c0870f349c7eaf87f187572c496ea61afca4e2223a6134c62325','bd96d419b8557819014b066c110a59eb152a80b355282e42bd49e82fc189dd79','518debc30bf0c9da2bc12adab7cace8006ac3b52cc7673cb9155033b2851a3b0');
INSERT INTO blocks VALUES(310258,'3a0156dd7512738a0a7adba8eeac1815fac224f49312f75b19a36afb744c579f',310258000,NULL,NULL,'256232e708893674c2a9f6d6ee0c7d1e028b7f3faf5a08338a9140e83a6bd6e6','73b15fdf797fb37fe02f95f364d069fe8c9cb498286843c59af7d605ec9e457c','730cded6deded896579eb6763c5bd845ca0c29d3c8b21137a36a4815248690bd');
INSERT INTO blocks VALUES(310259,'e5ed3cdaaf637dd7aa2a7db134253afe716ffdf153e05672df3159b71f8538a9',310259000,NULL,NULL,'2ce77baaa8fc5f0e8c6ef29cea56d0530d01e794955a1c9c1c1c19f547b915dd','ea087284ae813eaab2dae48cce674d0cb867c4bab3bfcfdafa7aa89a26a8ad31','86cdb1348e866ec6edd2a614e812fc015fbaae2258809df36aba9d34a9fa3b76');
INSERT INTO blocks VALUES(310260,'8717ddcc837032ad1dc0bb148ddc0f6a561ed0d483b81abb0c493c5c82ec33cd',310260000,NULL,NULL,'8f4417329c663d52b8b942daac4f521b23076bf9cae8ee2d4cf48855616a067b','c66c59cf8584e6d0f28dabe755c98a8830840ff607fee5f61e6fc5752955be6e','0fcd487ae8c900356e391495cff8b9adef558a3e3d01a654718385f4668f1e36');
INSERT INTO blocks VALUES(310261,'a2a9d8c28ea41df606e81bf99cddb84b593bf5ed1e68743d38d63a7b49a50232',310261000,NULL,NULL,'b4260af51ff93ef585bb33237f9ae8225f55fbd60b360ed35512d4bdbce37c89','6101edaec0379b4c76e6a38118bdf4b294525ba00c493caee9c448c1d919f2e2','d78e85722a9b6ab21f2202d290aef79eeb879819b8201694b5c793f6f060a787');
INSERT INTO blocks VALUES(310262,'e8ebcee80fbf5afb735db18419a68d61a5ffdde1b3f189e51967155c559ee4ce',310262000,NULL,NULL,'327f9cb1abc187756d12b9ff6ce0d4be370bacd83360b742f534e4f9b4ad25ca','937a0ee1938ea0579a909e81aba2bddc1c2f3b1e75663b4a1e9e7de57ad474c3','019cbaa34d7847b39a951fa2a2a3188622d6c477524d851271837a1315404b3e');
INSERT INTO blocks VALUES(310263,'f5a2d8d77ac9aac8f0c9218eecbb814e4dd0032ec764f15c11407072e037b3c2',310263000,NULL,NULL,'b6c030594bb4710f743df6332a3a379b844218926043357e22dd00cb79fdec8c','6e536f62386a334cf36ad849db7d4fe4afa00c6f910c154f67fa40b82da358f2','8f60f4282732300a5493044844d1d87841260940033aebe5693ec6a8f87b2ee1');
INSERT INTO blocks VALUES(310264,'ae968fb818cd631d3e3774d176c24ae6a035de4510b133f0a0dd135dc0ae7416',310264000,NULL,NULL,'3743ff2feddde494ec5443ebfdb28c619cdc068e30eb223e54ce9bb1a59b1608','5a4455c8e0b6d4fd960afd3443401a155f8e64c863ee949e086e0e51426cfcbb','959f562bce4aa6b4df492ffb05ad364afbe5b962d086cb57a99136d5d4c52c25');
INSERT INTO blocks VALUES(310265,'41b50a1dfd10119afd4f288c89aad1257b22471a7d2177facb328157ed6346a1',310265000,NULL,NULL,'9c7ae8991fd590761ae627dd7b468101bbac0caf4a31259abc35b47cf229eb27','778f3ba9468e09ebbdebd56b020f4e40945d57302c46d2b7f06df85ba0f053c3','7a52e2404c35b196f7b215379c7b286392604fc444565b3d147d0f0fcb5b0ed0');
INSERT INTO blocks VALUES(310266,'1c7c8fa2dc51e8f3cecd776435e68c10d0da238032ebba29cbd4e18b6c299431',310266000,NULL,NULL,'74e6851a3e26691929688479dda18ad2b96d7f4163afcf52f2396b4d327778f9','5010e6598e9466434733134f0040898806a9ea7e781c78205e03be1ee7ef8c41','f1b108599e38aebcaecb3f812f4e1b74c0e5995d0d0744dfc606c16a9a98600c');
INSERT INTO blocks VALUES(310267,'c0aa0f7d4b7bb6842bf9f86f1ff7f028831ee7e7e2d7e495cc85623e5ad39199',310267000,NULL,NULL,'3a78fcff3b8666cf3cfbffb3ecb4e27861c90892a030a2733f861795f1a374ba','9aee11615b99fc4436311c7f74c1dce750d2415ae4e48c6f075e0d4b498ba65f','2c49f7ab6f4e96687776791e8c939820506b895ebc6fe3979ba12057fffca771');
INSERT INTO blocks VALUES(310268,'b476840cc1ce090f6cf61d31a01807864e0a18dc117d60793d34df4f748189af',310268000,NULL,NULL,'a67a5672ed0d6a83b7bfd14691ffdc2be8d6c0df92be40d5102287c890d24e27','89bbf06594181fbf5a04484b1c101c2ee2abb9f36db3bd8ec4cae58fe175563f','0d32e0bb86a703ebcea8667497689f46bf746a4612b9f2be14f99dab8300e400');
INSERT INTO blocks VALUES(310269,'37460a2ed5ecbad3303fd73e0d9a0b7ba1ab91b552a022d5f300b4da1b14e21e',310269000,NULL,NULL,'04c0d04300a2ac0d13bf99f85b3d7c3301738aafc980152a2891c7cf6d270d1d','5df62c83d2f3dc5c119eef97a2ca35803615ca5f2375644a9500d4745e9a59ea','b133d660e068d4b67c58d7de3330001a2f0bf3c729fa0d8e7c39f37274bdbce5');
INSERT INTO blocks VALUES(310270,'a534f448972c42450ad7b7a7b91a084cf1e9ad08863107ef5abc2b2b4997395d',310270000,NULL,NULL,'a3576140e611c950aa6c12046848a91510bd05e784a5fad3cc0db560173a95af','0ba73fc2542e62319f06b0b39f7cf9d43f328877e4b8fffb470de5d7ca550f95','4de6b8ccafcfa084244f1e9ddadae637618975da109d433bd515b031e2c19b98');
INSERT INTO blocks VALUES(310271,'67e6efb2226a2489d4c1d7fd5dd4c38531aca8e3d687062d2274aa5348363b0b',310271000,NULL,NULL,'e5d3073c2c5048e7952add614bfe0e0385a247a0b1be04b3df27ff18ffe40490','1136fa2a521facb3e194a1dbf81e8aacd85292e30c8072d9a55e437c270a65c6','bf4821009170fa1d71e7db77cd6350695ffe288bb8ecdf4ae8abf9659ad2ce38');
INSERT INTO blocks VALUES(310272,'6015ede3e28e642cbcf60bc8d397d066316935adbce5d27673ea95e8c7b78eea',310272000,NULL,NULL,'813fff8b62689aac8789d18b21bbc444742265eccbef9e91c93641b6a593a74d','05a6c1b76e5a19aed667a2f1ac52cb8bf457e96908cbcbddb2361bbf56a40ac1','065cd719e087b171ead76e44fea471c9082065cdba0c816ae73f5e7337a8a651');
INSERT INTO blocks VALUES(310273,'625dad04c47f3f1d7f0794fe98d80122c7621284d0c3cf4a110a2e4f2153c96a',310273000,NULL,NULL,'2854556c311d905838a321482e96950a4094e81ae7f00f0e583580ae04bc0979','73bc0dab60bc144d4250d473cce7481e46376edeb295b81d0f470432a5b3e5a5','0d849598975d639f2e00d935faee43a53541ad85d2741672679445eb55408241');
INSERT INTO blocks VALUES(310274,'925266253df52bed8dc44148f22bbd85648840f83baee19a9c1ab0a4ce8003b6',310274000,NULL,NULL,'f009a44641a56705b968f69820f13912663fe35fb7c7e037b5525207b1cf0e21','c0d05a61da35b7e0f2d9ef399b932ec0e6277ba6148f78f8b732d942d0b0d2ae','4db63e84ebca1eb2fbcafb8c5416c0cf7ca2c155801d147bafeb154c4436078d');
INSERT INTO blocks VALUES(310275,'85adc228e31fb99c910e291e36e3c6eafdfd7dcaebf5609a6e017269a6c705c9',310275000,NULL,NULL,'459b257b176f96a694489c6234e44cc7765953dcd212c51ecd9feba4dbe9b3a6','04d1d8bbf4b49530dbcdf27a8144c60bb2d277936f268c8aa01f0efc023343ab','76bb69f22c2becdb6144161504b3cceb601fec7cb45dcbca93ef01c78ff901cf');
INSERT INTO blocks VALUES(310276,'ba172f268e6d1a966075623814c8403796b4eab22ef9885345c7b59ab973cc77',310276000,NULL,NULL,'5bde2f1a8a941a61f2ccc626f4e621a11e5e31cc300c83fcf93f8bfaa9a0d498','fe768c053dc39e7693d857a3d12320d03ea1094710d7f9a872f53b5e78febb37','2fcaf9e6bb807e51f4204f29ffe56028dbe3876346f6864dfab2f85c149affd8');
INSERT INTO blocks VALUES(310277,'c74bd3d505a05204eb020119b72a291a2684f5a849682632e4f24b73e9524f93',310277000,NULL,NULL,'80a03004f37d62384be88066fd355870e02816ea9a05ec383295ac306bb4d66e','29e4250217b3cea2458faea3ead15f5ac57aa7f01ff960c7d4f12fc51804d736','56d7633eaa6afd1653ff77b0dcacff94099e4ed9f4aef53197770d264ec45a0a');
INSERT INTO blocks VALUES(310278,'7945512bca68961325e5e1054df4d02ee87a0bc60ac4e1306be3d95479bada05',310278000,NULL,NULL,'5df93e0ad2c8befa1ff6b0ba502b817d9e3d95edd1fd4c6340af29f5e3d9fde2','9ff965b6107cdb86994e1be08ebaed2cb156b05d184112def7c0a3a875073084','bc047bfd84a90302f7f11b918ac68d12be09ebd5afab4e72e727a315e67c4156');
INSERT INTO blocks VALUES(310279,'1a9417f9adc7551b82a8c9e1e79c0639476ed9329e0233e7f0d6499618d04b4f',310279000,NULL,NULL,'9c7c15a3186ae71f1f9425ddc176d206774986a4cd7965a81ccaf24594f4f1ab','901375782c57350e64a863013d075c216b588962c90ba1978fad44d3ee12b0b4','ffe7c37c7743ebe7bfc100ca45f17eb5963a8451a4a70153e21b6ac608147ec7');
INSERT INTO blocks VALUES(310280,'bf2195835108e32903e4b57c8dd7e25b4d15dd96b4b000d3dbb62f609f800142',310280000,NULL,NULL,'0a519af939a27c5b9a9967469aaa869bfa5b25f31296c7968ac7730cc6bc2b5d','2711c65d4427afb4e19bd45ced861bffbce942d003e23dcd1f8109ea5cdd34e4','94efa71e6638c2d13dd8ffb9c8a8a9cb3821cdbb785f1c321ae00c98c6f4645a');
INSERT INTO blocks VALUES(310281,'4499b9f7e17fc1ecc7dc54c0c77e57f3dc2c9ea55593361acbea0e456be8830f',310281000,NULL,NULL,'0d6403a7175160d59cbd800bb37abb40c30ebd8052a52b0ad9d699ad69f54f82','a5fc8f9caf06773e5474a151a00fe7c55a15cb949c5fdc6958c156adf47d07e3','962ebd675c08a68a5578503fd75b1d68faafd3c9b31f0bf2edac7759fd2098c5');
INSERT INTO blocks VALUES(310282,'51a29336aa32e5b121b40d4eba0beb0fd337c9f622dacb50372990e5f5134e6f',310282000,NULL,NULL,'5b7e6bde1bb5d2728abc0d568e2614003557ca486fadf0825e73084780046e4b','cea8a652c878ed0cb5bd866c8cf8e112a471c6243b510f60dd9243ce711d06c1','e5b3cf6e6171898a657cb4ae965ef4d0f48e023a6912b47e219809c4789ef480');
INSERT INTO blocks VALUES(310283,'df8565428e67e93a62147b440477386758da778364deb9fd0c81496e0321cf49',310283000,NULL,NULL,'34af318ac9652cfac10199dc8d00ba5093b474e4197168da94f20674da2c57ff','0f5fc7db4c3b3766b821ba317afbeb7fd2206b5aafd79d6437010ded54aa56ab','3074ea29a0ae7668d3bba5215ee11c7980b67fc54677c3b635d6710b3db7bfa1');
INSERT INTO blocks VALUES(310284,'f9d05d83d3fa7bb3f3c79b8c554301d20f12fbb953f82616ac4aad6e6cc0abe7',310284000,NULL,NULL,'ae7b4736df32bbdc674d09b41033e1f0effddfdbc7c947ed828e486ff7b4b9c6','22a98783c32e8009adf5f31a8f460f26a0ed61555680b2c94b0d371e8e823bb9','6b1007e85a5c26004a38cfe63bd8a76323ac61ab5612c77fe5b5e322ea02f497');
INSERT INTO blocks VALUES(310285,'8cef48dbc69cd0a07a5acd4f4190aa199ebce996c47e24ecc44f17de5e3c285a',310285000,NULL,NULL,'64294f95ef33989a570d14ea88a00ae1a23a1baec8e44bfcfe225c1af2320a13','20844f78d13c4bec787d80eefba45213146ebdfdc1f43f698810a6b2ea834997','af251323ad00f7437b0892b57715c6f3f1240679eefef62dbe914ee065363869');
INSERT INTO blocks VALUES(310286,'d4e01fb028cc6f37497f2231ebf6c00125b12e5353e65bdbf5b2ce40691d47d0',310286000,NULL,NULL,'4961c91d7f95aba377df73022fc234a6736518deeaed0277a4be3d3ed7fc5af1','12877a7cb6d7023242909e2cb7b4617c5e914bc2559072770e931d8bcf46e151','920f4ab35a23511d62cdebeaafcd7d82eba2bc785f46ca70616379b323dc3791');
INSERT INTO blocks VALUES(310287,'a78514aa15a5096e4d4af3755e090390727cfa628168f1d35e8ac1d179fb51f4',310287000,NULL,NULL,'53c8e94ba9a4bd64ab08b732600391942d9d5c19fd9094d7a39c04e13715c553','ce88cbd33175ffae118b9a60878a3a31513d2f40b01147bde5c9fb290a2def95','4de300c267111e4d2c70c7cfeffd053edce741304845b59e8568c23342d7c85c');
INSERT INTO blocks VALUES(310288,'2a5c5b3406a944a9ae2615f97064de9af5da07b0258d58c1d6949e95501249e7',310288000,NULL,NULL,'a1f826de0c985c6a92f04bcea45d9a6d77facf430934df5d5eacc98be58e935f','53eab59b3de0ea1b1d1721973224836b237ba736471b1537a435beda2db7247c','0b3af1407cc9548184db3d1d464ff8a624061ce980a3a1ac4eb7d75291ccca50');
INSERT INTO blocks VALUES(310289,'dda3dc28762969f5b068768d52ddf73f04674ffeddb1cc4f6a684961ecca8f75',310289000,NULL,NULL,'cc330e1037b4caba640b3aecd85a5d0dd763e83c0151783c202305ccef37d34a','02784eece6af547a89d0542398a19971a839b637451b0790660902b94edc71d2','317612b1bd16ed22db3664573471c4996966739ec038da967d1468083799143a');
INSERT INTO blocks VALUES(310290,'fe962fe98ce9f3ee1ed1e71dbffce93735d8004e7a9b95804fb456f18501a370',310290000,NULL,NULL,'cdab513e4ea3ba72c284a13ec6a329bd8eccdb9bf8f95e8208edc4626fd664ad','9e0807b04bd32c1af96a7f9f6db79c7d5e9d3fb35125045ab7a4f2a34b43174a','ca44187c88f32339f32fa65e0698220934bf8c0e2944f680bf08d964bf6bece0');
INSERT INTO blocks VALUES(310291,'1eeb72097fd0bce4c2377160926b25bf8166dfd6e99402570bf506e153e25aa2',310291000,NULL,NULL,'85bc414dec7e85bf09930742c7a0fb3f8adbe5486eb95855dffebf0f15843b2a','8bac96f117c6c7ac3681723f06bdb03ae10be3a1ccd10fd0a40299fa03c0aafc','f09450bb74d1a01d007649affe6f868e6fb7abce270b89951d43eaac0a639ceb');
INSERT INTO blocks VALUES(310292,'9c87d12effe7e07dcaf3f71074c0a4f9f8a23c2ed49bf2634dc83e286ba3131d',310292000,NULL,NULL,'07ac810fdbde0d68c11a321d199358f245833d7c3e3d2ddc16d06cb671c795e9','570e2473a4810c83c3582d1ba96e56c9a7a8661b873e1b0d559034e87136a3e4','3f76e200faa576a5d169d17a428a2044448234a13d6905c65c1adfbbb90591f8');
INSERT INTO blocks VALUES(310293,'bc18127444c7aebf0cdc5d9d30a3108b25dd3f29bf28d904176c986fa5433712',310293000,NULL,NULL,'f98b2f0fe71edc3c9f9aa4de3abd05a589d34336ce74c1a5a0e8fb93b519302f','e2f4c1147801b68cf15f6d2502e9e35aa28e10bf318b8d8356e0c73c56594228','ceff297fa4ddf8c0fe37f3bf6e33099826fcfa51f691404522fd49bd5c93c80e');
INSERT INTO blocks VALUES(310294,'4d6ee08b06c8a11b88877b941282dc679e83712880591213fb51c2bf1838cd4d',310294000,NULL,NULL,'446cd2195bcde095a91292dd530d5966cc99fec212a05d55ab3e1ed194a7a8b1','f1be31497c76378383fca8b18ea61372727ede3cf21cfa5d6eb0f157ecd2d0e8','46ce4c52256a6ae93cbe55a48f2231ab503d715a92404b6f530efbe9ed434dae');
INSERT INTO blocks VALUES(310295,'66b8b169b98858de4ceefcb4cbf3a89383e72180a86aeb2694d4f3467a654a53',310295000,NULL,NULL,'80230911176a943c7cc82848a95c9efe7a6bf1f57e9c72fdc6ee36f554ac4399','282103d93579b44be7470a319a4e7aa4d7744039e3ecafac8e7917715bd862c2','4cbc48358751e02e1f8264b768d29eb816379752c768b8dd26b6b0cfc5f3ce39');
INSERT INTO blocks VALUES(310296,'75ceb8b7377c650147612384601cf512e27db7b70503d816b392b941531b5916',310296000,NULL,NULL,'52f7b42b85013db5f4ea1a469c857c91aff559e3383496ba3096578339400cb0','d37c10a02e3ffd78a3cbd9a4785eacf9f9f34a82e82df734774e08e0b65600d7','03ee62395803dc763fb89a27b22eac7b02b8671307ad6b2530a16f127ce2bf9f');
INSERT INTO blocks VALUES(310297,'d8ccb0c27b1ee885d882ab6314a294b2fb13068b877e35539a51caa46171b650',310297000,NULL,NULL,'acba4d2a5602234ff5e49d8ba8a0aa9cb53449d89902796a0cbfbfaf94616fc9','8837bc0bb024c350745ce2353c122538896bbfee1f00fc0df62339623f2f1701','335b955d7ce7ee9cf0d782383f1ee8ae285d9a21c549abc231bc4b98d32ffa1f');
INSERT INTO blocks VALUES(310298,'8ca08f7c45e9de5dfc053183c3ee5fadfb1a85c9e5ca2570e2480ef05175547a',310298000,NULL,NULL,'e13bd83871c5a16108beb1bae052bb3a8a47154a813dbc198e3d9680b1be6dc1','5bc5913dd2e74fe0d211971a99f725410d1ca4113cbc2e63683b4285a2fcd881','04906adfc493ee8c37e5e9e355c0455167d7de86843ed5d790edd413c1d0bd8f');
INSERT INTO blocks VALUES(310299,'a1cdac6a49a5b71bf5802df800a97310bbf964d53e6464563e5490a0b6fef5e9',310299000,NULL,NULL,'6492ff12ebf7593373ef73cc9acb811a68edf47423831a0b47bcedc11389fcc5','20dfb56fb9b35dd5850d9f95c1acbf5014856797debdcbf6b6b0da0e2501ae0d','a691510440afa7cdf4a9dd0028902c90436f08f905a0abc115747eb296ba6e1a');
INSERT INTO blocks VALUES(310300,'395b0b4d289c02416af743d28fb7516486dea87844309ebef2663dc21b76dcb2',310300000,NULL,NULL,'d6def16bed84ad614b98534fc9cd9e51d0a120a064d43cd5349a6637e8fb34b3','71cc0573f8205ddda127c32dd13ca7f66eb4361ef236018f0426f7f6e48b9e7f','0b33eca86a9505e0bc573910be8dc6fd3a5adeb6bca886591273080b5b2aa273');
INSERT INTO blocks VALUES(310301,'52f13163068f40428b55ccb8496653d0e63e3217ce1dbea8deda8407b7810e8a',310301000,NULL,NULL,'77683142e6e98bcbb8db52599669c11ee0d47bdec13cc25333b647e1866b5295','e17578832058f19cfc31a70f776ff3c2d0422c81d06cd4b18df980f5e83cb10e','2a295474aac2f19629cc2c03738595efae79264083fcf5b7d819a6a3286c4cf1');
INSERT INTO blocks VALUES(310302,'ca03ebc1453dbb1b52c8cc1bc6b343d76ef4c1eaac321a0837c6028384b8d5aa',310302000,NULL,NULL,'c369edede5cb6181b302125688deb4ef190fe2e7791c93b273955bd7fd92823f','9a737afaefcfec2a2824fac7ffc802086591d20a8be8b44eb0e875100edb142c','3c6fecc15b9450eff68fb882649364a794650fdb42a9b7a2244469a21848a945');
INSERT INTO blocks VALUES(310303,'d4e6600c553f0f1e3c3af36dd9573352a25033920d7b1e9912e7daae3058dcca',310303000,NULL,NULL,'fc655330aaaaa98e4dc7bf8931409f7e095d9924becaa38e06da6adf20d0f0b5','55d900cf68dddf02a3268f373d74ecce04bf679cab9a6d8ec8b4fbd63ad9daff','4cddd1ebad7b895aa023918baa9b6bc0981c54d192f09d9fd36837005b87ee63');
INSERT INTO blocks VALUES(310304,'b698b0c6cb64ca397b3616ce0c4297ca94b20a5332dcc2e2b85d43f5b69a4f1c',310304000,NULL,NULL,'2802d54f673c6c42280d4ecb71781f023f4ee42e517a9de1c305ca0f5dee7c90','3f272e2939b223f71611b0a4a688c88070151ac2b055d1508f2e8784cde65732','319f06c6a2cb5757e7ff6cc05512e53365f0cb2ef0c0e429c46ebd457674e41d');
INSERT INTO blocks VALUES(310305,'cfba0521675f1e08aef4ecdbc2848fe031e47f8b41014bcd4b5934c1aa483c5b',310305000,NULL,NULL,'8aff2a2d909b8d1efa7d0592e42b2305d7fc73e5030a3bdedea77fb0f3ff112f','6db7f708d3f1a58836039f2a6762fbdb5e65ae9f11b483cb636baf9172437f0c','a8d67f5057c250762e7ebe74d965ca4fd0fbf0ab2b17a42a14888ad918f8e516');
INSERT INTO blocks VALUES(310306,'a88a07c577a6f2f137f686036411a866cae27ff8af4e1dfb8290606780ec722a',310306000,NULL,NULL,'6ef39a3d3ff618f5e7618401452254fc76753bab9f2dd3d6d09ae9f22af281ce','f631ac791308703d6092974555cb534cf4cdfe7de9d378b3790323491ff42f1f','4e820796c39c8b8c1998278533e5c07f55119eca31bf4d1c0df068c4184c3ce8');
INSERT INTO blocks VALUES(310307,'bc5ccf771903eb94e336daf54b134459e1f9dd4465dec9eaa66a8ee0e76d426c',310307000,NULL,NULL,'dac1fbe600b5421bf4573f7474ebeda2de88a8cd0c2feb20d07c2b86c905cc50','365f78cd0d1b5c7690acebaeae7e9150aab88eb61beae0cada8fb42e87f4dd15','dc60941a6fdedcde66c3a01bce8bec9c7ccc0b2fe41f55310b9342fcff041ebf');
INSERT INTO blocks VALUES(310308,'2291ffd9650760ff861660a70403252d078c677bb037a38e9d4a506b10ee2a30',310308000,NULL,NULL,'d72cda4e90e19cc4c48619bbc7243ac666aba541254f13dfffd869af9cd31294','a39b214b01319e31d1707047b0b66956b038a5dc1f5f4210b41598d5d8beeb50','ff72f0e2dffb4f4ebd525527c7474f42c75e9e3bc75cfb936059d01739736f94');
INSERT INTO blocks VALUES(310309,'ca3ca8819aa3e5fc4238d80e5f06f74ca0c0980adbbf5e2be0076243e7731737',310309000,NULL,NULL,'9da1b5c1d1bc7d574021cbe9cd77904430a87f465126a169733608d2c502804e','6c431b4a238d6fb1c5293b9df749e8574c8f6c077e69c02e8a7755fa70ea1399','332ea39d9b87e425ff4755e112d2c81af0f025b61017518fe12e3f7d7996be42');
INSERT INTO blocks VALUES(310310,'07cd7252e3e172168e33a1265b396c3708ae43b761d02448add81e476b1bcb2c',310310000,NULL,NULL,'a1502ea8b564d2e1336f1d8aac8115dd2e221438930f6bbe7c74de8cba68081c','13fd480794431f7bd625638b8bcf2e8ccfbc4887eac324a05377ab6363df5a77','0f21a5ee0f0c689560e84d171387ca15c84b233dcfcf39d7c026975db37ca23b');
INSERT INTO blocks VALUES(310311,'2842937eabfdd890e3f233d11c030bed6144b884d3a9029cd2252126221caf36',310311000,NULL,NULL,'4b19ee25ba1d43ec5c12d04cbe7c39bd5b6325ed2f9bbabfcfa89cfc35f38257','ad399f830e2212120cb444e4c4566117e2c70a2077db83b8ae84cbdb77870e1e','403d648f7593b7f129cf5a75c0f693c33c399f62cad20bc4f52913700feea0ef');
INSERT INTO blocks VALUES(310312,'8168511cdfdc0018672bf22f3c6808af709430dd0757609abe10fcd0c3aabfd7',310312000,NULL,NULL,'9be462cbb7cb2092b598adf335b0701e296ab6da281d37f2f2d2ebe0f21e3db4','a21955dde20f9008652dda08f963f724b5aafebe8f895d564b6c5bf426868d98','4c02b2cd113fd3191c309bd0cd20d953bb1b22adaf1b36c21b4ac718ad4adaef');
INSERT INTO blocks VALUES(310313,'7c1b734c019c4f3e27e8d5cbee28e64aa6c66bb041d2a450e03537e3fac8e7e5',310313000,NULL,NULL,'e122a6ee8ce797db8e8175f3ed0e2619fc2ece2395a027e9512a7a03d310ffad','e6dea44b37376be7a82f3c1faf5893210bb5906c6d647e1785df7a418b0bcff3','ec7956b14523fa78b254f9f99dd434ca776d74874f25e5537607a6eb7d7ec560');
INSERT INTO blocks VALUES(310314,'1ce78314eee22e87ccae74ff129b1803115a953426a5b807f2c55fb10fb63dc8',310314000,NULL,NULL,'1656afb1c7eb5ab0f00fa44cea36cd4034d45baa6d2e150e221d58bfbedb6a1b','524a910d1bd2edcbae5bf1eaafb85a780566d3899b4c725710eaf8ec85f69f60','0928a6967a14a074392ada84a48e2391d460d5a8bb72983bc5be9f112487a07e');
INSERT INTO blocks VALUES(310315,'bd356b1bce263f7933fb4b64cf8298d2f085ca1480975d6346a8f5dab0db72cb',310315000,NULL,NULL,'408810e936d68270808b7107d5b8d214c00f96363450d1fb2fad2b2d55833ca9','fce8af6d998d93308d81050810f09afe92b9281fb4c158a33aca9ccf82ae0b00','0119da84badea5e5da5c9fd7cfe1b07426c15b617b866f6294bd9dd7eaf53dc5');
INSERT INTO blocks VALUES(310316,'ea9e5e747996c8d8741877afdcf296413126e2b45c693f3abdb602a5dae3fa44',310316000,NULL,NULL,'03cdd66a29b6711ba89bec3b4847c9d1e4c8733c86ffb937dbb07aca46051787','f9f76ca8e9e35f19076f82e51e1370b5fad5e5c315afe4a659189c5940785e1e','10e26c376078b5ffcaeddcbd16a5db5120026f3bb8be184c43be74792290ec72');
INSERT INTO blocks VALUES(310317,'aa8a533edd243f1484917951e45f0b7681446747cebcc54d43c78eda68134d63',310317000,NULL,NULL,'3d3facea897507c8fb4c5a79d57cf26b37514d81473e959d44c82262833e1d55','cf592c0d4dbc42e55d97e03eced056c7a213fa48f93befe0591bf9860fd60f91','438df65d288b9271677657274d3f1dc4be258b90ffc547831623606f2abbaae5');
INSERT INTO blocks VALUES(310318,'c1be6c211fbad07a10b96ac7e6850a90c43ba2a38e05d53225d913cc2cf60b03',310318000,NULL,NULL,'34b4ab25b13f3ee080fe31a47007093ef39bdccf92d6ee01fdbdae03f4cf9e3f','2385f006f8ca03cf855b46c52ff64779a86ef2656893aa156f7410b016caa7ac','2e69142c528de4d149745c76adb1b792a2b150860e1edba08357ac48b427e9c0');
INSERT INTO blocks VALUES(310319,'f7fc6204a576c37295d0c65aac3d8202db94b6a4fa879fff63510d470dcefa71',310319000,NULL,NULL,'b9816eb778747e74b959708f3a616acdebfb33074bb1938fc6a596bd8e7c5fab','beff12c2ac761c101ea976cdd95ee325a01040c3a1831d883d2e86a65b942958','4de1c1472c96a964c699b77897e270878dfadada2a104aa8611860defaaddb20');
INSERT INTO blocks VALUES(310320,'fd34ebe6ba298ba423d860a62c566c05372521438150e8341c430116824e7e0b',310320000,NULL,NULL,'ee79de2cea33b09c8be4a091597799afed4f672e3e1e559e092db5ae54cb0210','a342b4e6afbf6b0103e403329d43cd835cd43285c11911976f01ef100517ec91','70b27aac814b727659e84c446baa600022ff9a05a5aa18df0c940f9ab5ff9f2a');
INSERT INTO blocks VALUES(310321,'f74be89e9ceb0779f3c7f97c34fb97cd7c51942244cbc2018d17a3f423dd3ae5',310321000,NULL,NULL,'f6b1aaaacd5b7a0d3a94c6f3615defb86606c5d2ba40254312891b6767d5d90e','0dedacb198b9fc16b6ae6ce5946a5e4897371195e123190575599739a51cf08d','37a5f7a87484e0a1c2639b4d3c2dfb6d1eb630af962bbab7271340461ebfac9a');
INSERT INTO blocks VALUES(310322,'ce0b1afb355e6fd897e74b556a9441f202e3f2b524d1d88bc54e18f860b57668',310322000,NULL,NULL,'e5476830fd295046a1deb551e3ff40fee68d1f38e84f29b6598b61f09ee8d2e3','ffed526b39d10249e73bd46f825e872b7945dfb5ae45d79935301de4c429239b','18e064c1ef068c65023067fb1fc6a9495a99c85402dcc724bc47f9aa9eacf9b4');
INSERT INTO blocks VALUES(310323,'df82040c0cbd905e7991a88786090b93606168a7248c8b099d6b9c166c7e80fd',310323000,NULL,NULL,'a1c59846e8080becf6b1ec76a15438bdd9c9c9f7ecb05a3d2926359f8d967c71','921beba46c0d213feac3dbd9b509c5c4cde1044ac78fe2366b901f8394e2e681','fe6d0df71ee25699fc5535c7077d3b21cdc677d4617b5d9d53dfb64d138eead2');
INSERT INTO blocks VALUES(310324,'367d0ac107cbc7f93857d79e6fa96d47b1c98f88b3fdda97c51f9163e2366826',310324000,NULL,NULL,'cff7ae2fd2f99843ce4f1a855a05022f2353804c66e4ed46278d5d7e7cecb068','e04b441f64a07ac6c620ecea4103c3980ec590daa105afa8db074db47bf5d3a1','ee328cfd39604c14211b93a54cd36cbb5d5e34d6609b0c1a3eaa880ba4deaa2e');
INSERT INTO blocks VALUES(310325,'60d50997f57a876b2f9291e1ae19c776df95b2e46c14fe6574fb0e4ce8021eac',310325000,NULL,NULL,'ec56088a672ec41d0a4c553c85b2c22a5723f91f9200c23b22716f72966917ad','f6a5724c5831e8c7b7148cd8bba50a884d6619936a3a5ab5bce0698c03b55499','5c40f68ffd0990e48be02ff11ea21fda17de4a3eec0261d46cdc36c481db8858');
INSERT INTO blocks VALUES(310326,'d6f210a1617e1a8eb819fc0e9ef06bd135e15ae65af407e7413f0901f5996573',310326000,NULL,NULL,'47037d6a4a84861b381d1fbcd561369fdf2043ecab8c9dbea74f74bb5ebe9b34','956df749d8b1f8aa21e7a5715179a237ad179c709a76a9177606858183ab4acc','1ace89060325e888849feaadf43bbcc5e7b575b23bb45e83d214826fa0eebd70');
INSERT INTO blocks VALUES(310327,'9fa4076881b482d234c2085a93526b057ead3c73a6e73c1ed1cdee1a59af8adc',310327000,NULL,NULL,'a2a79c33e50529d294e03ab6dc10ae5fa411ec5aa27038f427ae4ea0572f2dc5','4e0bb1f008188bfab6c3cf26946de70142a0e517579a756fdd63d772f6e7214c','2a5e8162ea8b0bec56637b07552b2e44b74c6e992855c03427e1d9f299261818');
INSERT INTO blocks VALUES(310328,'c7ffd388714d8d0fc77e92d05145e6845c72e6bfd32aeb61845515eca2fa2daf',310328000,NULL,NULL,'f78350bb36fed400e42d34f502f009375e12f0093cf22b4903b5de4e612d5f68','d93f849050f203d8f7c12454736254a8f617f736993097d36f7584bd853b11b5','5595007d55d8669c12f204804db8a6cf91aeecae9014140cea3b5697102189ed');
INSERT INTO blocks VALUES(310329,'67fb2e77f8d77924c877a58c1af13e1e16b9df425340ed30e9816a9553fd5a30',310329000,NULL,NULL,'5862237b81d817702d2bfbcff34ed537da3a0bf52f41ac310b6db03d21679206','adbeda106b5a07351577faf29ac304676d530fa22364bfec1c4e2d503148db10','72630676d88682ffa1a438af0580035f081b74466662c5aa3165651e0b96dd83');
INSERT INTO blocks VALUES(310330,'b62c222ad5a41084eb4d779e36f635c922ff8fe275df41a9259f9a54b9adcc0c',310330000,NULL,NULL,'cc1cc00e2fd25628b722d2dc3da73323e21c25b398bfbbf5ece3374501246344','abf1e30b1db246c6b599cf92fe4b480e08f87d2448b8edce7577de3c6f3ad126','706ce8df679d2d4af220e30e8605f01c8b8c10f3ae5c60efebc10afd3088f839');
INSERT INTO blocks VALUES(310331,'52fb4d803a141f02b12a603244801e2e555a2dffb13a76c93f9ce13f9cf9b21e',310331000,NULL,NULL,'39ee9b4abca5bbacd4c03c5fa3625b4316a75fa33e6e30f8e830f2665923b694','42ac38fdb89f8bc3a600523372722a0ddb4e737baa80d5e06f26cc5aa9d66e38','7fdcac588751c5eb42d269a3b1972fc2311d74efb7e12f6a5a08309e42e72c0a');
INSERT INTO blocks VALUES(310332,'201086b0aab856c8b9c7b57d40762e907746fea722dbed8efb518f4bfd0dfdf2',310332000,NULL,NULL,'274522dc1217c7e26e9467f45f97061ec6c73178b6bd44b5ec5b0921587920e6','195916e219fa240273e7f9b49ef067f652bfbe37cee6d8ed069a0a2b154a8376','fc2b659a9125241326adda4a6c8897418244656979036bba3b50866916357ca4');
INSERT INTO blocks VALUES(310333,'b7476114e72d4a38d0bebb0b388444619c6f1b62f97b598fed2e1ec7cd08ee82',310333000,NULL,NULL,'09a1205729225cf01e75fd1178f61e057e52aaede307923353b63a400c23ee2d','a5e2548cd8c9d3ab2bfa8a77fa59ab9ed7ad01c8679162f4274fb293473566c8','1e30a5de9c88e892a3508b9c818ce88d387845124a32751a7865026d30db6772');
INSERT INTO blocks VALUES(310334,'a39eb839c62b127287ea01dd087b2fc3ad59107ef012decae298e40c1dec52cd',310334000,NULL,NULL,'cb33beb445f1e21723fdaaac67dd962c0e0b6891927707bfcf2261212e17851e','1eb724f83b82967a93236a6908fcacb174e0206db28d1c0ddaa4e3547f5e1375','0327b839a31c71ae425e59bdc6b33999ac118e2ced61b16c22037f88828c7b60');
INSERT INTO blocks VALUES(310335,'23bd6092da66032357b13b95206e6527a8d22e6637a097d696d7a96c8858cc89',310335000,NULL,NULL,'7c590ef2a7ac8d01e592464b8e8efff84c2b436a792c2ff08773085cc80621dc','ca8fc6bbc704957065b2c8cdb826c95939e58633e347e140d1041bbf8c7b5181','cc6cdda3957f92eb75a476f07fabe33d441a2dd021b889cfae44eeff6eb08596');
INSERT INTO blocks VALUES(310336,'ec4b8d0968dbae28789be96ffa5a7e27c3846064683acd7c3eb86f1f0cc58199',310336000,NULL,NULL,'3b3ac53a952b9281644b3abeea4102ab14264ddc57d3dbdc74a9ae4bd8a7b4cf','b40f5c09d571cbc23e441a631b66490140456d3c10b54302a4da8cd72e50b506','8578861eeb078506acca97e7918c04657764b7fd26fbadeab81adf91eafd4495');
INSERT INTO blocks VALUES(310337,'055247d24ba9860eb2eadf9ec7ea966b86794a0e3727e6ffbcba0af38f2bc34a',310337000,NULL,NULL,'76eb8834438a82fd5372cb9d58de2352e5879a034abac9c10f021fbd1c5f48f0','35582ebc60c425c0f300d2c9cb236d62a85cb53cc25ea20a656d02597d2d4be4','72ae781129203417a80cff0012445d3090857e3f0d701a23a76575c0eba2224b');
INSERT INTO blocks VALUES(310338,'97944272a7e86b716c6587d0da0d2094b6f7e29714daa00fec8677205a049bcd',310338000,NULL,NULL,'090fc0842501494f9128d5021917009430669680977fcb7b82338939348d2593','735fb233928bc0416bd76df4bf4a471512f78e9306fc325ad03f1ec50a7a6776','8cf303fc4ace8dee072004ec0a5c59517feb6a251d4e61ed1a5d536ccfcc510d');
INSERT INTO blocks VALUES(310339,'99d59ea38842e00c8ba156276582ff67c5fc8c3d3c6929246623d8f51239a052',310339000,NULL,NULL,'3f16df2e2b3affce65451697b5a81d826a872d606427750e5c566e7e4b11606a','dc56560e823e3f2b486659017098231bb933606e5e72bd56d25dd0cfb790583c','c7f143701cb1f887f5c1490fdec3043ec00bb828fa88b3d3144b7e0d9757c83c');
INSERT INTO blocks VALUES(310340,'f7a193f14949aaae1167aebf7a6814c44712d2b19f6bf802e72be5f97dd7f5a0',310340000,NULL,NULL,'bd95fb5706f7c42297a4b8c82190bb73ae28f39d823519d290e322afc770b733','15231f638cb6324cc1839eaf91d95ef72bc6d0f3c694319031d07f41c18c3dd4','82f752416d367c5f3606c501fb6685bcbfcc3e3d1eed51953c04788d6b69c1be');
INSERT INTO blocks VALUES(310341,'6c468431e0169b7df175afd661bc21a66f6b4353160f7a6c9df513a6b1788a7f',310341000,NULL,NULL,'836204688683e359de6af01c9be1bc5d62634fbf5a566007582edb23282b879b','a0b95a584b900e60d90feaa7e786f4c24b990e9600072df7d046e27ccf0431e0','f77b092dd300d8891582466de52029db6e484077498d6b0ce517c92301e08e00');
INSERT INTO blocks VALUES(310342,'48669c2cb8e6bf2ca7f8e4846816d35396cbc88c349a8d1318ded0598a30edf7',310342000,NULL,NULL,'9db2eb47b30cf9b12babbd24861bedcb24bd3134ac9f0d2a470d02321fdca314','6ef6bf0fa8197226c8389f1da18168177467594ef3c97fc6cfe315e2d786f153','be697f6c849ebef746c3b9660d002faf05cab420cd03e7a13003e40741c12b8d');
INSERT INTO blocks VALUES(310343,'41a1030c13ae11f5565e0045c73d15edc583a1ff6f3a8f5eac94ffcfaf759e11',310343000,NULL,NULL,'0808a87154926a5d9611b55dc9af9c01fb4a85598a6b4c3964d496ad4dab5002','4da48930217b449e7ce03debb297a7dff36d8646208e6e6239a06650aac8f579','2dde88467b643effa255651e28973e03909f0fc838f92ec8b02bd574a700813a');
INSERT INTO blocks VALUES(310344,'97b74842207c7cd27160b23d74d7deb603882e4e5e61e2899c96a39b079b3977',310344000,NULL,NULL,'a4cc9c612557adc0e256fa39547deb0ad260800d981f68dddff70e3a495b89ec','cd03f96f49828f64925385a9451235eaf79e3685422f18d14de906cfbb1a121c','ac7dfac09d8062602b5f5600aa53f804f632af0c602c6e283f2944acbed81187');
INSERT INTO blocks VALUES(310345,'0bda7b13d1bc2ba4c3c72e0f27157067677595264d6430038f0b227118de8c65',310345000,NULL,NULL,'3c47f9790d91486bcc60b12e71f13c91c105d6dbe012b711f3c769d643728dcf','5eed36e46d34f72ef6707009cf3c2962f2d464101f9d328d422eb9c7b621426d','34b2b517ed75947eb9038f15d8d439112fd8fdd6d4969e1e8e89e78ed1f3110d');
INSERT INTO blocks VALUES(310346,'0635503844de474dd694ecbcfb93e578268f77a80230a29986dfa7eeade15b16',310346000,NULL,NULL,'35b13c833c1a269de6d8ada30189605520f9b1824e61c2c77b66fdb1c095a9b2','55b6d1fcf1e3d9ccb3aa42641b08bddc1091f12575dd7f49453b39c6b3ee9282','3a7f68fab06d8b77378e3257805b0fc26d8b34de29f3b438219b98ed626f8df1');
INSERT INTO blocks VALUES(310347,'f3f6b7e7a27c8da4318f9f2f694f37aaa9255bbdad260cb46f319a4755a1a84d',310347000,NULL,NULL,'48e137263ab8a1a5af0381df91fbbea98c8829b04ed03767962719988a069c4d','85d695d4c72af6dba35f093c6c1737735fea7bfc1d9f775a72d64dca30e02e7b','ef4527cb00271c687573e84605b6090fa42fa23a90cfee27a7b8ed82dd79caed');
INSERT INTO blocks VALUES(310348,'c912af0d57982701bcda4293ad1ff3456299fd9e4a1da939d8d94bcb86634412',310348000,NULL,NULL,'00240251543016158be742f86820320e0b4e865e05ba560da0ae6d400452e94f','23848beca6eece71d052881e0ed9c9fee89175dcb286c6cb0de4ae9bc320e083','82836531cc3354efcdd511e884f2f65b932ff0ac1b25b2f3f17b486e7d45bd7d');
INSERT INTO blocks VALUES(310349,'ca911c788add2e16726f4e194137f595823092482e48ff8dd3bdbe56c203523c',310349000,NULL,NULL,'d5603d388cd9765a6399e4fc5c772217286a7ff8f9391334bfa0013bb71d6e7d','5a7f052b30891119ff98d43e9e36729b594ed6096d8f12c89052cacc0537f6e4','1a46a8d3e36f1fd23a0a9a37f877cd0ad8adfabea41320feeaed3ce1ec8aa724');
INSERT INTO blocks VALUES(310350,'c20d54368c4e558c44e2fbaa0765d3aecc8c9f01d456e3ff219508b5d06bd69d',310350000,NULL,NULL,'fa0b523979958f4f1470b55a817ab8f0cbd7fbd7f56834368e08cbc4051ac990','6eb4d2dad1e48967ae1d8e59682e31603cbd6ff65979bc8776f8334a84a87059','a9b6dccb28505101198fe9f4b5d3e9ebace594873c28addae17e21f9995308eb');
INSERT INTO blocks VALUES(310351,'656bd69a59329dbea94b8b22cfdaaec8de9ab50204868f006494d78e7f88e26f',310351000,NULL,NULL,'6ff90fbc11277a7d01d50325701587d7e6683fa79d2eccefdb534429baeb3010','d768a1311a2b966785fa1fdc07dedc4dd27a54ad21d9683c216854dcc501af8b','b3bcb6be2a17bc9cb24f3a6591edcb01c1fc9030467c90adb03c6d86a2adfab3');
INSERT INTO blocks VALUES(310352,'fb97d2f766a23acb9644fef833e0257fdb74546e50d9e2303cf88d2e82b71a50',310352000,NULL,NULL,'511d7d3e58ae795749232b5c232b9d0c6eb85a2e11f266cf9ca571c1de5ebff0','9eaf76ac97d4527d6d161491c6db2edc125f8b220f272e794fe63071c93c9ced','72e79ac7886744df64d2cdd4e4454550a2d7a77c589d4f4a2224d2b78fd0011b');
INSERT INTO blocks VALUES(310353,'2d3e451f189fc2f29704b1b09820278dd1eeb347fef11352d7a680c9aecc13b8',310353000,NULL,NULL,'b13fc97c5374356ff6af97531e3c5244cdb603dd39abc6b519a1cba1d64fd9de','15aa0c5b62902055368cf42789cfaa9eba429c501ca04a76b452868074cfa70e','2af59d17ecb533404c1705cc08720138484886e8fe3c3056f2214c90ff3777df');
INSERT INTO blocks VALUES(310354,'437d9635e1702247e0d9330347cc6e339e3678be89a760ba9bf79dd2cd8803e0',310354000,NULL,NULL,'1e0ed98d7b9410cb4ffc4186ee68702a3374515f5f45e196a5d1cf306e80304f','d072ac31e76262f06f355506d37fa8bd927cccc79a8544a7b2d3af375a8f4c23','1a2c989be91514db2839d8777234a0cbfdbffee1d68a75d839d85f8abda4e34a');
INSERT INTO blocks VALUES(310355,'ea80897a4f9167bfc775e4e43840d9ea6f839f3571c7ab4433f1e082f4bbe37d',310355000,NULL,NULL,'3b8439155b8d130281181868704e13fa4fe704e85cc2056e6e71c02afdafe1a5','ccd62c6549d5bb8fa9b21d4879697c4df92992d02fa20cd4024c7a96526f7d6e','f7319c5d79997760cbd89a3e6cb9d651fb92ce21ce5e763d165d720c3b989bad');
INSERT INTO blocks VALUES(310356,'68088305f7eba74c1d50458e5e5ca5a849f0b4a4e9935709d8ee56877b1b55c4',310356000,NULL,NULL,'3437e0c1e8e21d5129f6005b54b8373f952a0c0e15da099c6ae8328f1a901ce0','d995b1731cfc22dee2850d79167c611a30901b61fc57c5c155c17a964064ffdd','2463f471d3de664e49f165b19b25e461987d74cf998bc93225fd97a1ae0f54e3');
INSERT INTO blocks VALUES(310357,'4572f7f4ad467ef78212e9e08fa2ce3f01f2acc28c0b8ca9d1479380726bab1f',310357000,NULL,NULL,'3f8f0db7a1c72eb209f106ba432ae5a6f65ac8939944fa1d810ce8c080e2faba','c252432e3b289f820d03058fa65d8ef2ac60b0ff730e051c1935a8738b7037b9','ae4a872fc6e9a8c495b853df3a161e31179a475139f539ae190392be6315e821');
INSERT INTO blocks VALUES(310358,'d5eae5513f1264d00d8c83fe9271e984774526d89b03ecd78d62d4d95ec1dea6',310358000,NULL,NULL,'dff98a2f7a4586ea74a141d9c491460db184912a24bf959bfd9abc6a90ac26a9','6dce5ea12ca24cac98c18bbf0e20583f2f08c2c125cb1b7189a52b418a387e3e','14a53d744c44cda2cd79a9408517cc1a7c004a26a4b33812c1504a8128d04ad2');
INSERT INTO blocks VALUES(310359,'4fa301160e7e0be18a33065475b1511e859475f390133857a803de0692a9b74f',310359000,NULL,NULL,'a12bf6d9333a97e215624fca1bc07ab009d9a783892afb966823bb33cc275b66','9599309e36aee7814e8a4522e6d587de0eac87f8eb61a0c03bcc492ea598c963','d7bbd743251b55e734f92b8bbf9702016e6d5934bad2216d4ea0e3be8710f4c6');
INSERT INTO blocks VALUES(310360,'cc852c3c20dbb58466f9a3c9f6df59ef1c3584f849272e100823a95b7a3c79f0',310360000,NULL,NULL,'2b645d665d35f61010c32dca2ac9ab1907b80a8593706fb92cf0b30318858024','7de2329165599c0bb496aa0f7283ca7e288a9d43b1bfe896b94613e4c1f5971c','0d6c3e68044c4b0df0d71a4117ba6033d3f37a824c9d2b6dfe069620284e82db');
INSERT INTO blocks VALUES(310361,'636110c0af5c76ada1a19fa5cd012e3ee796723f8a7b3a5457d8cb81d6c57019',310361000,NULL,NULL,'d9a7f6d488b26f4f62d4deb9c5549d65b46fba757a8412325f4977d3a9b11f57','47b6b1529fcd4c1015c7f7981dca6d90772829ad4fc6de713fea606962e09432','60a063acb22f0697b8129431f1cfe6959035d27e2bfc0475c093fcd2e1a3b764');
INSERT INTO blocks VALUES(310362,'6199591a598e9b2159adb828ab26d48c37c26b784f8467a6bb55d51d7b6390f2',310362000,NULL,NULL,'4cbeefeded55a35f0f05627883efdbd7ebd8b3ac587ce3090faa670160e40a4f','1132e543b38d294ad658dc914f2347b4c501dc0d2be2710147c54b0e2baeeef9','18fcd9180da58a9977957ecf1427c40d2064178b5b5434634e50be01893e1082');
INSERT INTO blocks VALUES(310363,'a31967b730f72da6ad20f563df18c081c13e3537ba7ea5ab5d01db40e02647e6',310363000,NULL,NULL,'4818962803e3903a35613fbc4629134314d920ec384d6ee6a8b4c4bd9c7ab62e','ddd3b7ea05e06e2a49e9099be0589d6ae3800e68c1645f438a04615aedf43a24','cf20ffc1b9076eed8af58134787cdc8fdf3ac96b40966fe953ea749170df334f');
INSERT INTO blocks VALUES(310364,'67025b6f69e33546f3309b229ea1ae22ed12b0544b48e202f5387e08d13be0c9',310364000,NULL,NULL,'06e2ab58ca25d43b19d642ee716fad2db132a7f2b265748a2a9c59e3d1b55343','c06848a2e25666f6415484740d599c7e70bea52a9217b921952b70db9082cae2','33cb88ccccd7513ed676a7b3cc880d3bf9f54274fd56512e97498bb61ff401f5');
INSERT INTO blocks VALUES(310365,'b65b578ed93a85ea5f5005ec957765e2d41e741480adde6968315fe09784c409',310365000,NULL,NULL,'16c65b41a79b1925fcad19a4813a3c91708c9a6c7f0d73da17564423599dfe4c','efcaf71d9625bfd94de7f701d38cb82bb382d82d76678bc79897db4fdd027ac9','2e9fc15565d0c551d58d927cb6fecfb283647c416c07046c22c2a8581edc7f2b');
INSERT INTO blocks VALUES(310366,'a7843440b110ab26327672e3d65125a1b9efd838671422b6ede6c85890352440',310366000,NULL,NULL,'d3f1b30d471fda3d85d0b96f9f7ae69c3b27f1d72fcabd44109256ebcdb5e003','1866f7265f4ffacb7faad949374dc3acefb27b3d30b740a6dec0409b860f3b26','429737889095518acf59b57e8a4070f4b0ae4955b8adc4da4934b60c9b54abac');
INSERT INTO blocks VALUES(310367,'326c7e51165800a892b48909d105ff5ea572ff408d56d1623ad66d3dfeeb4f47',310367000,NULL,NULL,'f6f47d6780181736c6d048fad0a10cbf0a8f2a818f139892c5e3792e93819cbc','ea66c2a5bc9e4718c87d27cd5e2ad19426e52f4ae52bfc0b6ae5f35ba262777e','425f8f76f407f07c73d7f5a57906183bc3ab3ec8d3d197222d2b29a1ac786cfc');
INSERT INTO blocks VALUES(310368,'f7bfee2feb32c2bfd998dc0f6bff5e5994a3131808b912d692c3089528b4e006',310368000,NULL,NULL,'e5b1f0c494ffcbd58c730ede272847acaca8809f268f7c3488785bf257456f3f','4a2a6b7f4ce47f434ebd682d441ac5ffcdb131189837e3bdcb1b80cce7690bd0','719702c2f81b0d56ca2510dec5f106d1b36896c4a93d0032c26044c76de01c8c');
INSERT INTO blocks VALUES(310369,'0f836b76eb06019a6bb01776e80bc10dac9fb77002262c80d6683fd42dbfc8da',310369000,NULL,NULL,'a147b65fa9a271898192d2c6b3915681c37ed841a34a49207091361e152a1863','697da7b77248c895eee72b39e0b8fa1a9478afed0996df98a8422c36ef262f32','7e0040682139609c0c1aa1794a0ad603adab624032360e4a868486431446d13e');
INSERT INTO blocks VALUES(310370,'9eb8f1f6cc0ed3d2a77c5b2c66965150c8ceb26d357b9844e19674d8221fef67',310370000,NULL,NULL,'3cac5995b12ffaf25fdecdb2a5748fa25382cc2a1a6e1ab149285e65f3ba467b','893d930f4788fe1b06eb605ae06d0cc674e6be5856450f6791b7d0cacbd16e2e','eeee94d6bc8822e8001a24b42b6bb79d35d0e6e2fcc706d5c771e13d6eb874d4');
INSERT INTO blocks VALUES(310371,'7404cb31a39887a9841c2c27309d8c50b88748ed5fa8a3e5ba4cc3fc18310154',310371000,NULL,NULL,'9570a9f54a776fd7659b999e6fc637496a04c634d4ca5100fbcf74363ccaa131','9f9f3c117c5979631ba3f2de560e380145087ec983827c55a5c75be47726069d','187adcf5b73edf375edcf8678fb2629ea5bcad6b7ea261ac1184579a50ed6ad4');
INSERT INTO blocks VALUES(310372,'d3a790f6f5f85e2662a9d5fcd94a38bfe9f318ffd695f4770b6ea0770e1ae18d',310372000,NULL,NULL,'20d8421c0fc435e6978931a2b28a366ecd8b7a12a69316a16287fce1b1be3845','77f2cf11ef2a8dde058b2c61ae2a7fbf911297834e5d0d2fe7334b8d39f3787c','242472d27261ff3a52fe955f81d22c45d5af7a62ec848902181cdad38c1c3059');
INSERT INTO blocks VALUES(310373,'c192bec419937220c2705ce8a260ba0922940af116e10a2bc9db94f7497cf9c0',310373000,NULL,NULL,'bd8a26da13aa9712a7199a9ecf01f68df403ccd939c0cc86e5260f661fd9eb3e','117e92980d29b58c48beabeba375a5a1aedacfb8fa065bd90148e06181e6cc1f','305813c86256eb6dc2f076f405076db74f646fd15679222a7ff997ef07871d67');
INSERT INTO blocks VALUES(310374,'f541273d293a084509916c10aec0de40092c7695888ec7510f23e0c7bb405f8e',310374000,NULL,NULL,'5af8a7f224a4ef0e575d12e97f5fc6584b57c6e09daaa38cab7cc1d9cb65fc8d','54a46e9ab1320b7c095c555761fdf81e2426c1c227e5699c56f8e8a4dacf337f','384715e17b8fe5a8950b5b9df7c27a3ccadd28cb935affc85d80d475de81c90b');
INSERT INTO blocks VALUES(310375,'da666e1886212e20c154aba9d6b617e471106ddc9b8c8a28e9860baf82a17458',310375000,NULL,NULL,'57bfdf423d01e3a691493f417fa314167215cfb3f5b9325c2bd6b2c6ae0a878f','0f0ff234d7318e013b2db0bfa25d4d90defab4a7554e319cbf6affc8979826de','3d332e191f65d40010325ed0c1d2a8e21e7f654dfa30a45f4bcf28746de6a77f');
INSERT INTO blocks VALUES(310376,'5dc483d7d1697eb823cba64bb8d6c0aded59d00ea37067de0caeebf3ea4ea7dc',310376000,NULL,NULL,'246c2263172a209213732d4a14a83ad8b2df6618fd0ba4c48e3353765739a8dc','6ac4322e9a8e04a371f8721f9c4f248a6aaaa9a25044a2498313ae7071b30417','5b56bfcc200d039ba1710641d87d05a858a0ec246c7984e4e97bd4c6f5c4c7c1');
INSERT INTO blocks VALUES(310377,'f8d1cac1fef3fa6e7ad1c44ff6ae2c6920985bad74e77a6868612ee81f16b0b3',310377000,NULL,NULL,'86962a72d910f9e832b0aa43db00bcd9f301d755e4ae19af5567111bb67ea71f','75a1a29e0e8e1928ae5133abc42363573405e1516d19e361b47bae5246ba7f81','83267d3353eb602b67ec015bf3e2595e090b0c59ace2fcd09e670e882e0cdf0f');
INSERT INTO blocks VALUES(310378,'fec994dd24e213aa78f166ca315c90cb74ee871295a252723dd269c13fc614ce',310378000,NULL,NULL,'50d79cd0b607f0ad4d765a98565ce3f9c83b48bf68509021a2763679a454fb9a','4efaa2dd6b4fd3c7910796695a4b60514742c8e2b106979bb4800a24b0c3bda7','0ae9235ce7d94cfe219590de9644588fa29d5edbe21eab39472bdaf5aa9dc589');
INSERT INTO blocks VALUES(310379,'d86cdb36616976eafb054477058de5670a02194f3ee27911df1822ff1c26f19c',310379000,NULL,NULL,'b54e67479c97d1577b35a38f857684e649ec1bd24db769022348501050d0c776','f6d21cd41c252534419b0491ef80cc0069a5bb066a54585e0d7b0e3d52f2bbe3','adc0d7d34d3c99d7cfa79b973c3250c292b083ca3f91cadb92652dc4f688d303');
INSERT INTO blocks VALUES(310380,'292dba1b887326f0719fe00caf9863afc613fc1643e041ba7678a325cf2b6aae',310380000,NULL,NULL,'7736f892d065fee8ca6d3895b24489be4a166bdb19c822c75ac2675e752d6c4c','787d9b2c054c1a5390f8ce027c0d5fcc25fe5db8eb4c654cf068911874be6ca6','112d00eed00c35ff29780eb9afafed5d4252508f5014964e82c4f977f8ff848d');
INSERT INTO blocks VALUES(310381,'6726e0171d41e8b03e8c7a245ef69477b44506b651efe999e892e1e6d9d4cf38',310381000,NULL,NULL,'2e5115bf1197d1d3a85d3d3858a1e24d87424e1d1325863754ff583fe6512e98','7419d8926491bf27f696db32d71d5b4967beed54724bf6dbf9159e97a5a11b83','b9b84f08496ae05af12e6220b8e20a5f87fca2decbfaffaf24ccb9098f8375a3');
INSERT INTO blocks VALUES(310382,'0be33004c34938cedd0901b03c95e55d91590aa2fec6c5f6e44aec5366a0e7d8',310382000,NULL,NULL,'3ea2583708cd2ce4f2720e085be7b28587da6b066196788f9fd853e1d20f14e0','736af9fe58a2ce2ea278e4072930521f3ebcc2a89f323d908d02a4f8aa5b7d69','caf15f1167c1ea66564d32d24a44b8f054ce9234cffac4f106a06c36ad9eb94a');
INSERT INTO blocks VALUES(310383,'992ff9a3b2f4e303854514d4cad554ff333c1f3f84961aa5a6b570af44a74508',310383000,NULL,NULL,'0bec4be27ab6b1737579504ea971ceebfcd4676aebd1a1672c2ba4554253f08c','a1ddd5b95f04ae7acc6a4f54d3088a85d8d909ed69ae77454dc3acc49de5ca31','eaeed8dc7d64a9307b2c0ed2ec20550e6e6b708a9121483c2b69856599d80508');
INSERT INTO blocks VALUES(310384,'d518c696796401d77956d878cbdc247e207f03198eabc2749d61ebeadee87e5e',310384000,NULL,NULL,'65f2dc7b56144cc51d3e8c36328677023a1b397fb94e4dee36a3670308526653','e523760f1ab6f7bb3772667bb4e0b5c438ad15cc039c2391252eba07ea51783a','b91e661904f22f48ce3ec1652afc707df6ec4d147285102508fded0352bb60a2');
INSERT INTO blocks VALUES(310385,'2aa6a491a03a1a16adbc5f5e795c97ec338345cfdf10ff711ffb7ac3a0e26e28',310385000,NULL,NULL,'644e2f4e87057958e141253044e02ae62f75d0f1c2c1708b9e233e035b4e6d0e','0c98620ac7d8e29aacdaf22103ded41db220527aa6121ea9e90816083b7e6085','032b7f01fd1d70f393bc1f0b617045e7068d046859eb403563edc4ae6416ceb8');
INSERT INTO blocks VALUES(310386,'9d19a754b48a180fd5ebb0ae63e96fa9f4a67e475aeefa41f8f4f8420e677eda',310386000,NULL,NULL,'8949ac7272110729a89c1153778382e09850be612dd80644185f12be232cbc41','00d31347ca9c75c7774c45812145e0a2e899a0665f99f6112ea6bba79247ce31','1fbc3ec27d1444e4eacfbe7edfaac3c1dc9437b4a3f6b6f70efe9b6625c86551');
INSERT INTO blocks VALUES(310387,'b4cac00f59c626206e193575b3ba9bfddd83bbfc374ebeb2838acd25e34a6c2b',310387000,NULL,NULL,'3e7725edcf3205caf4942d4ddbe044c6ec65484e9d99b7effc1e60bab186b8b5','44bf84570cab7d5b9385cfaa047bc5d056b5d7bf7fd2adc3826401c5eeb144da','0113d001528942d649de7c85fe97210ab21934f10be24b14d0b7e2df0b909e29');
INSERT INTO blocks VALUES(310388,'41a04637694ea47a57b76fb52d3e8cfe67ee28e3e8744218f652166abe833284',310388000,NULL,NULL,'db3883bc66c4f2180f5e1bdb8bd1ffe2f5ad0942e53a92495cfcd4afadefe300','0a780e48dd2014fca0659fc63feae45a0c8a209d63f1e30c0473f14db4f3daa8','499e14d7fce6302e40714e82a26d042ade0370fec4210d4ed118dcf4df7bd367');
INSERT INTO blocks VALUES(310389,'3ec95ae011161c6752f308d28bde892b2846e96a96de164e5f3394744d0aa607',310389000,NULL,NULL,'2dac157db6a935d3c8cff14763e1807f66268465d9c8668d51a63a6a8f9fe3d5','6739df132851d00a91b94c9aa76ba01792493c352d450f91ba124b0653523cfe','8ff46a4bf569c94220fc970c0386cb0bddb60f968155b8647779b355dec24e7d');
INSERT INTO blocks VALUES(310390,'f05a916c6be28909fa19d176e0232f704d8108f73083dded5365d05b306ddf1a',310390000,NULL,NULL,'69f057e18f1f91d3fe00bf5933d8e647116a263a6f27e83a9fde9867467863db','bf4d9cba46372e206959afb01043622e1e753c69e77b65386f0015169e93d2d8','397cec6c4a3b33e5c0802358c18f5551120c4488039d1b6f436a3f3cf1a78a83');
INSERT INTO blocks VALUES(310391,'fc26112b7fdd8aaf333645607dabc9781eac067d4468d63bb46628623e122952',310391000,NULL,NULL,'20b8f8976285f4a3e1c55b9aec443b643864ec7d8b1c84326451922d2f978ee4','7f955221b1773ffb1906cfaa103fdf18d563330ba1ecd4ba45b769d2b1b1c69b','aeb4fb5f854766a1c52e385570a2abe57ca6ae622a4b4d9e76770c8840069e37');
INSERT INTO blocks VALUES(310392,'f7022ecab2f2179c398580460f50c643b10d4b6869e5519db6ef5d5a27d84a1d',310392000,NULL,NULL,'4e971d95ab6f0abcc2a8b115254ccda36f7470de8925de690a08ef9e88188517','2d688a8471e8bd45a8c65fdfb133348f3df265e114420d1ac6250ed82eb8204d','6b98f1ad4f913db51457808d8d790e390d50f9019dfc59216c69f83c788f426f');
INSERT INTO blocks VALUES(310393,'e6aeef89ab079721e7eae02f7b197acfb37c2de587d35a5cf4dd1e3c54d68308',310393000,NULL,NULL,'2dde962cbeb8c40a56437f268f118387e9d7d606485cc808bfcea48af0b6b086','351f4e8088d5779797c33352ad2ba98ff3292df801ae845d425f29d97a5f65b3','8e351e3f7cf0e5125ff3d6020d07a51b5b45a2baef19423da6130d6087066c0d');
INSERT INTO blocks VALUES(310394,'2a944743c3beb3bf1b530bd6a210682a0a0e9b0e6a9ff938d9be856236779a6f',310394000,NULL,NULL,'2d96f5447be8c7cc5b3547583f4962b0cc015d0af620d4ef55ad4942b8a634e6','d6d89c66aaaf31155fd743133b30d2ca841a0a930b75f9150ad0bca686942bc8','0f4f0902e2126a0875f7a08ff6e5b589ae0c3cf899ac1bd93244402c05a3557e');
INSERT INTO blocks VALUES(310395,'19eb891ce70b82db2f2745e1d60e0cf445363aaff4e96335f9014d92312d20e4',310395000,NULL,NULL,'b73409ecff1ada428791ee4c0fd7b8cdfd498c6d30c19eea2b8c5cd77e4d5ca6','58dd772a0af3c11c6c64bf67b76a34191a3dc7d0fd2bee78a6c363319c128699','2d4529fb82aca024f327712a412dad483b7341acda81db15d57a87010a6644e1');
INSERT INTO blocks VALUES(310396,'aea407729ac8d8e9221efd9d70106d14df6aaf9f2f87dc6f490835a9caadf08e',310396000,NULL,NULL,'1d522a66c922956f35c920086d5648e0667da03e9e4d1523a43636286b5f9f12','ac175a81b259e866021e78722e567e4749aec7177efccb1fe50812c6a8abb074','3a540076ecbc7f2fb8f1963662b9bb9c4d62d5c58ec4718ca3471fcc6470fa2a');
INSERT INTO blocks VALUES(310397,'7c429e56a19e884a8a77a759b52334a4b79404081b976270114043ba94d7985c',310397000,NULL,NULL,'a769e886df155438b3064e2f9d96bc7b4cb2184c5f7f78630bddda1e7eb95115','8979c1ee64f1f36a129e47a7ab7e2e0af1d8ee03434af02b143fb1492d73e551','9a5f5145aaa0b18ae08d65c7f11950e6407d64967a73dcbae377491cf099fb7f');
INSERT INTO blocks VALUES(310398,'55c046db86dee1d63c0e46e6df79b5b77dfd4ab2ff5da79e6360ce77dd98335e',310398000,NULL,NULL,'fef09b729926d6fc1b252ace3106f6dde383c7bcdcf3eb0407f71f179cab4832','06e2407040b70d36e90e6c0bce71cf2bb020adcf558f1306bb020df9f7919c88','10caf22ce68ab4cb6ce828413691ae0bc86a4ddb5e56576d570668176523d758');
INSERT INTO blocks VALUES(310399,'765abc449b3127d71ab971e0c2ae69c570284e0c5dacf4c3c07f2e4eca180e7a',310399000,NULL,NULL,'594dacbd169e0d0e6dcef68010e1455416b3db2faab8dd3d290bd67ee475ca14','32ce9ed96e4904ee4a07ef47125d06504060f00b2e44a75c4bafb3da61fafe6d','35127d23214a7026fc2e66bc43bc208376e8f8e57481bd0926a0cf67df0032ea');
INSERT INTO blocks VALUES(310400,'925bc6f6f45fe2fb2d494e852aaf667d8623e5dae2e92fdffa80f15661f04218',310400000,NULL,NULL,'d204145f1d15074601bed94562253a2d86c367b29fb370271ea347d04941c7b1','c3d69aede8e82ea9f871dadcb8f43156fad80aa97f3a9a1ce664dce7d701ed1f','7a4551f1d54435dd604200e1b5f8dbbe5451f969a2fa045f61635676dffb4d4f');
INSERT INTO blocks VALUES(310401,'f7b9af2e2cd16c478eed4a34021f2009944dbc9b757bf8fe4fc03f9d900e0351',310401000,NULL,NULL,'4a1f7efe7621776a912ba6c219d451e825714dbe4733f299450954bac6274ea6','d1cf341a1cd24ef86ffade1896dcecea263ec76662b2c6392ac17a473e278c8b','327fe6bd6c8afc82ff7a17191bfad0e3b1f8261e9e3f2a57f6813b56f8d1e0ec');
INSERT INTO blocks VALUES(310402,'1404f1826cd93e1861dd92ca3f3b05c65e8578b88626577a3cbad1e771b96e44',310402000,NULL,NULL,'d1ce3e3ca8b1b54f9d9adfb4c7814bd1b933fd70f649771bdd1b08573f6d0497','2d328698b957a09810d3a33dc740901ce656cf44954f82a188a612c836945048','cf3dca4f4fbea0be8e371520e2c8c37601f2d403c8a7faff70d40a7e45f1ee7b');
INSERT INTO blocks VALUES(310403,'f7426dbd4a0808148b5fc3eb66df4a8ad606c97888c175850f65099286c7581c',310403000,NULL,NULL,'15f62182cae68d29639781b35a8ee17a80bb03b2201dae4e127e0482189a6761','348f7f4a6091315e355dadfa92317f0d61a0a9ef782da08d5a548fcb0aee0233','632999103d9da1cfafc3a0467057904e6b062f4b998bfba1268b1382843f7896');
INSERT INTO blocks VALUES(310404,'401c327424b39a6d908f1a2f2202208a7893a5bedc2b9aff8e7eda0b64040040',310404000,NULL,NULL,'73d90c2b9da1335549750cdfce65e7d7d4516680a3d0585db0c5a00303f3e28b','9c7cd83063a580a1547ad9eac909a139ae297c5cb87cac489f8ecfe7412157e6','65a3173a8430889082d2280b1082c1ed0d737c39e7fddaa4e0ea2dc3f7e44635');
INSERT INTO blocks VALUES(310405,'4f6928561724e0f6aab2fc40719f591823ca7e57e42d1589a943f8c55400430a',310405000,NULL,NULL,'4dc6e275834d94141657964dde24f97bd427f673f92ce65f1bffa9861956522d','acce2a05f98b6b874818091c3483d5c55db0ff5d8d9322b7184218444e0dcbf0','38766fb2a7be766ae35c057e4982234f468f318ce7c667a5f1cf49303014284f');
INSERT INTO blocks VALUES(310406,'6784365c24e32a1dd59043f89283c7f4ac8ceb3ef75310414ded9903a9967b97',310406000,NULL,NULL,'ae7383ac29d5d7d04ad4092e6fae2d2b0314dd8e1df5878006a46fe892790cfb','7de5a338b09e7280b0c5b0530d1ae65b084fd33e1413892b65254343707d5c8b','6b044fb3400618d02e8f1436453737a8bd08a3f2352b23bfce928fd2568ae271');
INSERT INTO blocks VALUES(310407,'84396eb206e0ec366059d9e60aefdb381bca5082d58bffb3d2a7e7b6227fc01e',310407000,NULL,NULL,'aae589f1e90477e4ddeec559de0e486b2a569a6dc91ac59c23ac704d17d2f98c','8f7fbbfd36be23abce355ab9239f274f21f156bf891a4b90f632f0138ca78093','30799de9f0cef912a7891c854fb706aefe1b58e641b8eaf4eec2afe820bb9557');
INSERT INTO blocks VALUES(310408,'4827c178805e2abae5cb6625605623b3260622b364b7b6be455060deaaec2cda',310408000,NULL,NULL,'e433b17f212d431be23e16fe6dbe6ff165b43a1b7d70ca448722e1afa2960af2','7320a9f95ae22780d1de11e8a892d3c6ac516f2d24e3b3be775d8eb8c6406758','343c516cdad631668ec3a0ee4c5a735e974fde52a8c68e61333c2f539ff25a7d');
INSERT INTO blocks VALUES(310409,'01a719656ad1140e975b2bdc8eebb1e7395905fd814b30690ab0a7abd4f76bba',310409000,NULL,NULL,'354065afd0b8df082ba640fa62a6cb71b428b949e0dbbf5fb592214d99cc1bbf','6723e192d261b40f1dc7d500855a08f4351589e4fef4d23f1d2c022672df6ea7','92e638844e05deb8a4c460aae72e8a78d978e3bacd325327a9b378df9faa60b4');
INSERT INTO blocks VALUES(310410,'247a0070ac1ab6a3bd3ec5e73f802d9fbdcfa7ee562eaeeb21193f487ec4d348',310410000,NULL,NULL,'2945932273b1325685347d7d139b20941b7431d92edb349fe7a7e0774504ce88','c9b864c6d982b27a4b591d2dc2be0f0b52cc1653cc3f01c8cb47bfeb13fa730d','33fd60d5e6e9a7f409fdcda2aa65b7a47ef9586e7bc41bb4d1dded7badb99e0e');
INSERT INTO blocks VALUES(310411,'26cae3289bb171773e9e876faa3e45f0ccc992380bb4d00c3a01d087ef537ae2',310411000,NULL,NULL,'3e758c94e47770e8a5a71a1cd1d5ed8ae9295a2bd5c6dc7e87a10947390a484e','d8b2daebd522880de31dfccda6267a1677112a2bf8349ba451bbbe2255dc660f','fa5c3093ac2ab9202bdc3755f2ba10355544f3ac825d65270a0171ddafc8cebd');
INSERT INTO blocks VALUES(310412,'ab84ad5a3df5cfdce9f90b8d251eb6f68b55e6976a980de6de5bcda148b0cd20',310412000,NULL,NULL,'0bcf8d963d6b6ad70134c7e0d0da4c7bf98bc4948a027ce9933ba0104859c315','b371c5bee51b30ea1865d4a04d4675a4a7494e7356851d8bae72875653a61fc8','48e305fefa6793305f8615e82f7c67ab3780c51eb9e99f5d689399eb5941755b');
INSERT INTO blocks VALUES(310413,'21c33c9fd432343b549f0036c3620754565c3ad99f19f91f4e42344f10ec79bf',310413000,NULL,NULL,'72caec3b3c1554a91fd7345df72b84c00d282307bd018ca209133d65e4a4c1e4','5b98805b8826e834dbb10185c82c55155783c3058fb5976f2041bbdc5a3835d6','422f443d595b9b29f1b4aee77f0e741e25d1fa05c87fbdebb4e8d0b0a93553ca');
INSERT INTO blocks VALUES(310414,'8cff03c07fd2a899c3bcf6ac93e05840e00de3133da14a413e9807304db854b6',310414000,NULL,NULL,'a1685b84f518b322f33de2a324ea8055c7121231396eadc0dc2dd22da3e9f4f8','31d9f1e102c4831ec36d9732ee97efcf0d4d41e40d411ed6ba3a18e72dd79ceb','5413440135f0e920f5f61ba9763e9140459afec8b54c4b1b41e02cf67c234be4');
INSERT INTO blocks VALUES(310415,'dd0facbd37cca09870f6054d95710d5d97528ed3d1faf2557914b61a1fc9c1cc',310415000,NULL,NULL,'3f8327e338de830465ff0ad71c88b982508910e9bed5a83cab020c26b12dbf1c','8b2379d893063786a38c078075a7c6499c59c84a01798d76588a20c6e562eb01','2ccc295bc5d5e7faa3ec4d561100c319999d099d90cc1a03e545ca817ca2b5cf');
INSERT INTO blocks VALUES(310416,'7302158055327843ded75203f7cf9320c8719b9d1a044207d2a97f09791a5b6b',310416000,NULL,NULL,'9aa32163452427a2753f1a870d140fc0951fa4634b0724b784cc968a42d07c34','88b05fe2c0cbe4b0452dc855c9c379b42c13761079b3c0a76bedd9bc27292d24','a339792410007384e9eee0f7de1b77734349d5991c5112cf5c09019ac3fde63c');
INSERT INTO blocks VALUES(310417,'2fef6d72654cbd4ea08e0989c18c32f2fe22de70a4c2d863c1778086b0449002',310417000,NULL,NULL,'1f2f520098954651c9f79fc3c71b3080e8041516d13832d1fe1898b8ee46ff5d','8e9bf3bd3c6f43038e61908c44da51ec407a4c762af2278e1952b8c8df5a355c','e57e2ac9363412a586d5ba63e42b2be9660d1762f60c8e8e191ec780b6dd11f9');
INSERT INTO blocks VALUES(310418,'fc27f87607fd57cb02ce54d83cec184cf7d196738f52a8eb9c91b1ea7d071509',310418000,NULL,NULL,'2bc118bb5a099b7e4a53cbb35003cb4ecca5118e057b0f1af2190c2fd8d7582a','c9445b9564df0f835e622ffd038a1b209a6cc474ec5bb314f518940392355483','1e44f2e66edd34c564898da25e325dcf87643541fb5941eb6a1e173ee21f2456');
INSERT INTO blocks VALUES(310419,'9df404f5ce813fe6eb0541203c108bc7a0a2bac341a69d607c6641c140e21c8e',310419000,NULL,NULL,'1218c4c2731968c86deae301d5ee98ba37264dc9fe10354588ce024b7a2a33c9','a9972bcb695272e4e2a7d849c02bdd040f7478e4fcf1007785fb09ecb45c7c5d','db2a584547198ec7f2c0505be22091052e6e8f2f9805883b1f60388d3a6116e5');
INSERT INTO blocks VALUES(310420,'138b3f1773159c0dd265a2d32dd2141202d174c2e52a4aeac3588224a3558372',310420000,NULL,NULL,'567ee43b85e3762bb845da12b38556b703ef8549e573be8424fc6eb002047fc9','fffe760f5a37f25dd8dbb2d25ede16996f2eb6747e0598dd11bf435fa2c24d64','968fd1a0501d11849d901a12f3d31afe56f03349871b3ff2ff35066c72ffc99f');
INSERT INTO blocks VALUES(310421,'71fe2b0e02c5cad8588636016483ddd97a4ef0737283b5fd4ab6ea5dc5c56b9a',310421000,NULL,NULL,'0329544770c737f6b0e45de8cedb14e009a808d909d901a8fbaee7be6d800461','6e8da08043d241f218d5ed31b75228e0de881dbe1995b6154c1cf0a849e42cd8','8e515d6fc0f802c4c2ddb0ecc72d898464626380a901d81fec918767f737104c');
INSERT INTO blocks VALUES(310422,'cd40260541b9ed20abaac53b8f601d01cd972c34f28d91718854f1f3a4026158',310422000,NULL,NULL,'842c0b53fd7a3bd10764c2d2f297d9499d9c1c6c2f9d567ac926d8af1ee32256','5acf468c216cd047d4928186e8635c2a4c1e22862a53852bbe453e45c4210ce8','6a967f9c78d4f68dcbdcd559d2adaece269279a9495a2c2334fd301246ec15d8');
INSERT INTO blocks VALUES(310423,'6ca0d6d246108b2df3de62a4dd454ff940e1945f194ba72566089f98ad72f4db',310423000,NULL,NULL,'38d5032ab49ed6c2e589c5e16b74cc93b3d6b829ba42dfc2de662bcdda561d57','aba9c0adb20a31bce3aae5901628df79ec0fe8b92bead4885346ef6eb3b2a2f6','2e4777c9aeff324c627574da05e69a788d4ea9cdac264ea24e62414036370d63');
INSERT INTO blocks VALUES(310424,'ed42fe6896e4ba9ded6ea352a1e7e02f3d786bfc9379780daba4e7aa049668ad',310424000,NULL,NULL,'bfd8608fff8e1513a3d7e947da938070f9c413fe3863cd371f8b5c10a7e43408','1f349837627d63b5618dca721175eaa1ce9602b4be630ad54c45a262009d8fb9','161030a93097ba8b614bed9833c7635038f135c82ebb8013e36c7a75e98858a3');
INSERT INTO blocks VALUES(310425,'73f4be91e41a2ccd1c4d836a5cea28aea906ac9ede7773d9cd51dff5936f1ba7',310425000,NULL,NULL,'b2ed71a556dc11d16e23f02a3306c182a18edcb96a74566c7cabf56d4aa7871b','625a7bc826b7149e64a2c5a99f36592701c2cebcfbed163e662406e1541536bd','b49a896c6021a35beb9c5e618f43a08844a6f527ebc91fb0d0cd4c86f0bacc1a');
INSERT INTO blocks VALUES(310426,'9d28065325bb70b8e272f6bee3bc2cd5ea4ea4d36e293075096e204cb53dc415',310426000,NULL,NULL,'d5b636a99db2361eba3b18e7d3a219fda60cdc900402bfdd229da9eaf5975011','9f6971d011fedeea1db03618e8249fcfbd282bbc6edd9bf0ce9a6dd888ee082f','7c6b927ae750198330c21e51657fbd411cb534ac90d40999696d3b058db43d32');
INSERT INTO blocks VALUES(310427,'d08e8bc7035bbf08ec91bf42839eccb3d7e489d68f85a0be426f95709a976a2a',310427000,NULL,NULL,'9a09477fd9a1740bbefc865213a00dc1cc3c9e98d01ed8a847029011aa8b51b5','da4c8d383edf273eb61130fbcabdf7c49d8482c227015aa95d5fa0fb86059e56','09000fafa90971fd456f5c80c1342fc875bb6e6ff61e5bde4a106e2fab335d93');
INSERT INTO blocks VALUES(310428,'2eef4e1784ee12bcb13628f2c0dc7c008db6aaf55930d5de09513425f55658a2',310428000,NULL,NULL,'a9498161b5a992c4295a7fffd358168308d59b659e596ace6e76515424c78d77','f5203d3d7dbed70cabd9f4f8481ab3c8e6745a62e77f8a9fc7b9a3aa024818ec','2f3e3082687992e33906cfbcb0d5777498c2dd2ef6bead27c20993683dbf0d5a');
INSERT INTO blocks VALUES(310429,'086bfbba799c6d66a39d90a810b8dd6753f2904a48e2c01590845adda214cf8d',310429000,NULL,NULL,'d5fdea6a8636b3e0394ac4e5b60f5234410c1ba372c6f795ba3cfe93c2ccdcf9','721cc1d3f46cac105130e4d7702a484dc9d00aca2ef66d7ee43c97d8a2a2404c','91fa9733f9c6fbb71ffcaa9cc7fc4a48881fd3551259ff21e2aaf055b218c00e');
INSERT INTO blocks VALUES(310430,'870cf1829f84d1f29c231190205fe2e961738240fc16477c7de24da037763048',310430000,NULL,NULL,'d092d77234bbb535d9afc76e98ec076a99995310572165ddbfbff6c03ce18156','5fae159b58db010b33554803a41a8f7a9f1a9c3f5fdda1e52fe8f597f050e17f','599afcc2474b9570b212ac0f6692db189af9993aa7970f77b66a3bdf8f112bf1');
INSERT INTO blocks VALUES(310431,'20b72324e40ffc43a49569b560d6245c679e638b9d20404fc1e3386992d63648',310431000,NULL,NULL,'f4fb118e11a9eb5668592120104bc91de1247a4cfb66b9b1894b12079b921441','9803152a705c9e476c3339fde3f896b94d7075f412657f8a1aba7f3a2b669b26','288e21a82b9e5d64c3ddfff4647922351dfb72f1c72121f446fcf4cde62039f8');
INSERT INTO blocks VALUES(310432,'c81811aca423aa2ccb3fd717b54a24a990611365c360667687dc723e9208ad93',310432000,NULL,NULL,'0342d25136f616d095a04c43d45dcf61cf8a849e7c62252955c8e3c00ebbd95e','0248380e6d1d2808367d4596d34ed01cac1ca2e4e9e05fb8e938a1a15c6c5f7a','c9261d7b1cc85de0a1a0526cd6463a60f7f685db79b598a505ce3ad2d8913b30');
INSERT INTO blocks VALUES(310433,'997e4a145d638ad3dcdb2865f8b8fd95242cbc4a4359407791f421f129b1d725',310433000,NULL,NULL,'27810fe714fadab9753f1943313215ec94911bb471529906d05f797f6df03355','335be849d871447166f3770a192d674aee71ce14416564bfd130369cf1e3f0e5','04642cb06b8c0d57cf9ae84698bebfdc04b041b3338943e0b00e79579718dee4');
INSERT INTO blocks VALUES(310434,'61df9508e53a7fe477f063e0ff7e86fbb0aef80ff2ddedc556236a38f49ac4d8',310434000,NULL,NULL,'55914ba0e23931ab20d8d0f1c9d418483cae843d63623ed4dab0efbf4a63ed51','617ee7829598aafa19606c9d2ece45b8304419c19aaffb5ea3a666d13ae1cde7','f4dff6144179cc98d66588a2e3912e097410e95291009e894e9c5427247adc96');
INSERT INTO blocks VALUES(310435,'f24cf5e1296952a47556ac80a455a2c45da5c0dc2b388b51d235a3f741793d5f',310435000,NULL,NULL,'f91788d0b1ce98ee1bb77402c2ba7f811963b59f9b7cd453d5ffd4b11afa70cd','fb384ddfa8aa4c770a6c7034682b25ed3a27c6bb14e4454c6d12c083a378d747','f485e7e5b4502aa984a9400304141184a3ee03509cf96e307102966a9b731132');
INSERT INTO blocks VALUES(310436,'a5e341ba92bdf9b3938691cd3aab87731eba5428bb61a804cecf9178c8da0c19',310436000,NULL,NULL,'8fa2b8d3473d04190813b15086b4dbd1ef49e66d3a1e44ab7c8d21a0f27ba3c6','7500916e54a9ad4d1ba71b2b4be4d500bdd628c21e9cb883124cde0254d6b19f','31f143327cadbfe3203867a084843d2eb24258a2e8b992dc7ee4ba8ebc8be8ae');
INSERT INTO blocks VALUES(310437,'9e18d0ffff2cb464c664cefc76e32d35752c9e639045542a73746f5ec2f3b002',310437000,NULL,NULL,'d4e95e0080c8dc865ee4466bd5ece6346d7787f3ae0fe9ec07d11b2af4a008d6','4f4769315a73a48e6761fd051a078cfca4b3761709ae0fe124f8d51cf598b16d','ec3382c51fecf6847fb6891b848d3fa9ff15cfbe70a89e7333d74e96702f3ca0');
INSERT INTO blocks VALUES(310438,'36be4b3470275ff5e23ed4be8f380d6e034eb827ebe9143218d6e4689ea5a9fc',310438000,NULL,NULL,'6186f278cb567142ea20d12cc4a53ca83e9ef0a239cb93ef3e982f56b7ae8e40','2b73f265906e2e629925d4efb10b379b45ca2c74dedeb5a770f8de70f0eb856b','23daf42699a5149f172c1342db5ef8b73e7d5da0c187d7f44e8a458800c90b2e');
INSERT INTO blocks VALUES(310439,'4f2449fce22be0edb4d2aefac6f35ce5a47b871623d07c2a8c166363112b2877',310439000,NULL,NULL,'e666638fc51df873d86df1565a0f1adeca0732ace5658b6711e770158b8dcfe7','fc9855e79a0acfc58662b1538bbca24a6270a03a93587d4a336d4cd38c466154','3a199ce8bb3fcce45c39efd286587654346b2aabe1f651a25815899c93dcc64e');
INSERT INTO blocks VALUES(310440,'89d6bd4cdac1cae08c704490406c41fbc5e1efa6c2d7f161e9175149175ef12a',310440000,NULL,NULL,'bd0856bdbb67266753cf0fffe0b2e4b8654ea783dcd1753831540a310bfae63d','794af9bac60f06ac5a2ae8ca1b47410dbf2af164872fb140d9bc7bccccc55f28','e6ddd0d5764e86ec702a69eb083cad26434388875a9c5d9141b3953ad1cb39a3');
INSERT INTO blocks VALUES(310441,'2df1dc53d6481a1ce3a6fee51ad4adcce95f702606fee7c43feda4965cf9ee15',310441000,NULL,NULL,'24c5660f7cf90c00cd3986aa12fe9d1b33bbb9dc9fa081d6f8d363e5270baf6e','d06c669a6dc421aeb2838525eb56ea141a979d98d3b6e1df6f9e17f8bbfc317a','dde017ab1653efa01c3cf723f4bf65355bedb198969e552d7d708ff80f70651a');
INSERT INTO blocks VALUES(310442,'50844c48722edb7681c5d0095c524113415106691e71db34acc44dbc6462bfec',310442000,NULL,NULL,'8c4820309e958e207260ce12014591dbda9fdcad89ee9c7a7c9bb0ce7e087c9e','7547abc4bbc754fbf3b45334a1f1ae7920fd1b5a2d5e0aa575eb415cc5bae8ba','388d617668afb674bc3ae68d766f2bc29762aa0fc894c5b4f0a323cf67b934da');
INSERT INTO blocks VALUES(310443,'edc940455632270b7deda409a3489b19b147be89c4d8f434c284e326b749c79a',310443000,NULL,NULL,'5419512fab4d3b621a6edb744001480a7a9aaf89a40adba981ef26ec42b0da60','8c7f7058a98e40686e701a9c46e58cd3e9c05f6f86db0008b95a44dbb432dd68','641d03762670f8538ea55c44b0683c5d1e0d6ef6b5a67eeb7289ee50d05822ba');
INSERT INTO blocks VALUES(310444,'68c9efab28e78e0ef8d316239612f918408ce66be09e8c03428049a6ee3d32e4',310444000,NULL,NULL,'828386cae70cc974d0fd6db6ab380a41df2da55b79c68a055a06714c7f576574','83231bed7b6f97fd11406bf092a05f58940b4da30f4b36165ebf46c4f648eedf','ebe9c13f864fc955ce020783f4548bb677785aaee66b5c247677a622b4c42137');
INSERT INTO blocks VALUES(310445,'22a2e3896f1c56aefb2d27032a234ea38d93edf2b6331e72e7b4e3952f0234ef',310445000,NULL,NULL,'ca1b44bb35bb65c4ac8f0bb165c9d50d3ab111554f47775044cb6da18fdca2c4','1988f337e952bf034289c8aa159fd2421d9b15fbe9a6cfc7b9de06b7d0f931e7','4bedaa6c069c8f03b0c25fd7cce46a9f3c07fe5999baa2c7fcc3c22d574cac1a');
INSERT INTO blocks VALUES(310446,'e8b0856eff3efce5f5114d6378a4e5c9e69e972825bc55cc00c26954cd1c8837',310446000,NULL,NULL,'77c7052f13cd91bbb8972832834a8c2f9d34ca4fabab0a300672a2ca0dff5dfd','d94e1c17866ea84ff69ec635b9848c474d68ed3aac406da5bdb23a56c3d19bf0','18a2447813df383f2661932cd915d80f9ebdc8d0ee9cc806617f483ef825ff04');
INSERT INTO blocks VALUES(310447,'3f4bc894c0bc04ee24ed1e34849af9f719f55df50c8bc36dc059ec5fa0e1c8a8',310447000,NULL,NULL,'0573c0ec0bf25608431f7473ae46de3b6540e4a5fbe118f71dc29fbe86b735f6','3524d4682219fd70ace9271c978949cebcafd97890a1f751521e1158bbeb0b83','2c9045e01bf06fb82c088b79204a04a8e873140a668d4ca3f2934123a3e709eb');
INSERT INTO blocks VALUES(310448,'6a6c7c07ba5b579abd81a7e888bd36fc0e02a2bcfb69dbfa061b1b64bfa1bd10',310448000,NULL,NULL,'330a4ceec58bf419438aa9233765be6210bfcb84f9852499c11be016c6544f57','2b81b15014a659b4f8c34a05e3a627cc4bc774319584356a189f88dbc152daf9','fcbedabd97530727c941801841d3088b4adc30e343782e0e43b166a392c0ac7e');
INSERT INTO blocks VALUES(310449,'9e256a436ff8dae9ff77ed4cac4c3bfbbf026681548265a1b62c771d9d8e0779',310449000,NULL,NULL,'58b87b3180b67c8898b11af876a47de0177f64ad0e9a7a64eace0f7718b4e0e2','6e2c4adc0da8575090891384fce747c515117e439d3902244ae50c3ea87aa31d','4d8534af60d6d1817001fa4d44d94de2cf121287c99ebe2062dbc75f3a8bd4ca');
INSERT INTO blocks VALUES(310450,'2d9b2ccc3ad3a32910295d7f7f0d0e671b074494adc373fc49aa874d575e36a3',310450000,NULL,NULL,'4d39010f458759588b546cf0f2e68c9a90a7f96d28ee7d6b36483cee3342be09','4a87bc449d306f6e05929362741470de4d329c4d14966edd52b7ceee8617895c','78821881f33c789fbd8d14eaf60169f91c217320f25e3cebd147024d6588c5ac');
INSERT INTO blocks VALUES(310451,'55731a82b9b28b1aa82445a9e351c9df3a58420f1c2f6b1c9db1874483277296',310451000,NULL,NULL,'41ad3029e170a97cf75b6916623cb9641772210f5a868b43517d4f280ce7ed11','8fc78f36557bf7da88d79b5945158940d487ff8280c43c617f970451cd4667f4','1dfe24f8abf9e4e14c670cc4cedfc38012eb8cd640d0eb30dc384752eb3fb079');
INSERT INTO blocks VALUES(310452,'016abbaa1163348d8b6bc497cc487880d469f9300374a72ecb793a03d64572aa',310452000,NULL,NULL,'d2d51ea2138ac797a15d4af40c85c421303c521737499306f8e17e22c3fd08b8','e0fca3127007426e772b7babbfbd254139b8ccf5a51909e8fd186c8e1488c053','173e4474568f4152412f2c89e4eafd55b7fabe248455220b1f4d13684d763f48');
INSERT INTO blocks VALUES(310453,'610be2f49623d3fe8c86eacf3620347ed1dc53194bf01e77393b83541ba5d776',310453000,NULL,NULL,'453ffd4e5ee7c513006c5b63132301ded2df689dcdb674d74f83fbb64e2d1139','0cf686dea1e394a173dabfdc773b3072ef5875f52247c294842a782decde2fa7','accc22ca034dd1feb31fc67d248421cabb803c9c40d9fc03df8dfe1433523c39');
INSERT INTO blocks VALUES(310454,'baea6ad71f16d05b37bb30ca881c73bc48fd931f4bf3ac908a28d7681e976ee9',310454000,NULL,NULL,'6b13730eb22d347b59d19d86a0a1616a0cd21c63325298317fafa6b729ca08b0','bd8f5380976796c506dc9c496e8433cd371d7eb1309b481941cf25abb3e97b78','6009dd6a37ea153407957c624f76037b77aaf9c7229e4e019933b6b45e48a68b');
INSERT INTO blocks VALUES(310455,'31a375541362b0037245816d50628b0428a28255ff6eddd3dd92ef0262a0a744',310455000,NULL,NULL,'b65941c2d0b731c3a2ca30f0f366b25ea3ba429b0f432a2ecc22759dc1929337','077c1619cae4e8a7296f77a1cdea56a5b7a5ce07880a7b31cfbc1b754bfc8ae5','ac7b4abbb5f20a960325a06594567d0f7473711349a2d3d7d0da051a75e10623');
INSERT INTO blocks VALUES(310456,'5fee45c5019669a46a049142c0c4b6cf382e06127211e822f5f6f7320b6b50fa',310456000,NULL,NULL,'bd42e5a288d5a9f6867f6905724f7dc9598efe07fa0a6dbb0c720b73ca701c64','610bbd2b8cb68140068f126c624ba3cb24c33d9c10a240a65c780b4b29b143d0','6f511e6f6d12048f8369a2e31d79d4bbae2a4f6bd30d555b8d4f9304c59282ba');
INSERT INTO blocks VALUES(310457,'9ce5a2673739be824552754ce60fd5098cf954729bb18be1078395f0c437cce9',310457000,NULL,NULL,'c86d64d9b9b94496066ade46f87121f4b23b4d687f35ca2434e7a4ab05c40198','a5f12ff24229374193a54a02925efa6fbf677f02d04d0d74f52fdaf5a7152436','599e22ad2d045ea848fbb38540759a2b460caee11331aac5842d108454780607');
INSERT INTO blocks VALUES(310458,'deca40ba154ebc8c6268668b69a447e35ad292db4504d196e8a91abdc5312aac',310458000,NULL,NULL,'696844d3edba3ddd3fc5ed61a6501af23c5c2035f4335b194211636585529336','f58176fe773315e775d7d2a91d22b66c17d3d14f4a2d9f99c70ad1082b2e745a','e0d7b7397f56cd6cccf43e6c6c38919b4a62171f82d8c6e635572fc78ff9cb3d');
INSERT INTO blocks VALUES(310459,'839c15fa5eea10c91851e160a73a6a8ee273a31ab5385fe5bd71920cbc08b565',310459000,NULL,NULL,'742bac014aecd3ac8e3bbc49501e1ba0d83ae699bbb1ac8d3ce13fe3d1c9edb7','cdff8046df82f595fe240651204691ca34a180591be0df95fe5248b40e6086a8','54c7f36d8b8e99442d180ea3490af5b796a5b681df7f54bf978bf51ef6ef8010');
INSERT INTO blocks VALUES(310460,'9b5f351a5c85aaaa737b6a55f20ebf04cafdf36013cdee73c4aaac376ad4562b',310460000,NULL,NULL,'93bfc2301ad68d281b8432e8223c4e1b8a7c95192e26a58a93da3a84bd3aade1','00e537c8f53bfed84ef8b4830331b45596694e99757bab51188ee7dc753421cf','6426c9998e1ce94c7035a2bcf6e3547db3dd3240678e43afaa94efe57e76cf84');
INSERT INTO blocks VALUES(310461,'8131c823f11c22066362517f8c80d93bfc4c3b0a12890bdd51a0e5a043d26b7b',310461000,NULL,NULL,'436048b99ca1ab769a575cb039f71c844ef35932affaba3a4c023937439866a4','b9e6dd4d3c65e75beacf4463ab1702c7e6f8568c04d8941c12a6091e51134a46','90c9384a15749ab952ce5fb1a0e7f2d9d0d653de42e0211147dc3fa51231aa53');
INSERT INTO blocks VALUES(310462,'16f8fad8c21560b9d7f88c3b22293192c24f5264c964d2de303a0c742c27d146',310462000,NULL,NULL,'191aca9cd06939f2b2f3c59af69d24576dcfd917d6bf2d542a4d64179d49e41d','433e2c08b501569a8acabed164093a4e5b2a52de9df7d335d7267b3072321200','939745132e9f8a606fd94207598cff69e2ccbbce5e046086a837d8a83caded8d');
INSERT INTO blocks VALUES(310463,'bf919937d8d1b5d5f421b9f59e5893ecb9e77861c6ab6ffe6d2722f52483bd94',310463000,NULL,NULL,'0da7c8cf3734c6557f89a227d3b31afbd20bd9a2ef1503c24d5570f6c0a7fb0c','ddf3bac9e4d38aa209dcdfa7d73e9e8e9bf1c7c74a32cfd77df3ccf1bee44c3b','84ee0748089193b325acdf1e8bf334e52c87ff5981c3ea0ef69f652dd31d067b');
INSERT INTO blocks VALUES(310464,'91f08dec994751a6057753945249e9c11964b98b654704e585d9239462bc6f60',310464000,NULL,NULL,'a6ca8107a50bc01ba89c4f15990cda9aedfb588fac0d1179931dd32f031f5a94','d691e687f2151b9af3b53a57c301ec677c77a797afed611f893c98cfcc0042fc','d4ba1544bda8333c363523d3c852320937b2940a3071b2ce8fc40c619b00abc5');
INSERT INTO blocks VALUES(310465,'5686aaff2718a688b9a69411e237912869699f756c3eb7bf7c3cf2b9e3756b3d',310465000,NULL,NULL,'0e296031e66b4123897c5c586b46bcc03bd6686c06b370cffc73a8ddc36191ad','e37115a63246a02a401542a07aba60613def724f5dc75ffbb9874bad7ab289f0','b4bd4a6d21b63895d0b95d20af913f598605e13b2601181d68bd5607459d705d');
INSERT INTO blocks VALUES(310466,'8a68637850c014116da671bb544fb5deddda7682223055a58bdcf7b2e79501fc',310466000,NULL,NULL,'81dd993fa6cdd1c0f5448439cbc0a8a68abd28a23b61ea0615f4e3b6885e5227','6e7dab14d24785cf5b8ccfdf22bac62be9b1a64b0c7cdb1d55681c133ead52f6','24650eee9c4051cea3424eef7273b398470764c6cfc6f9c16adc872923cebad1');
INSERT INTO blocks VALUES(310467,'d455a803e714bb6bd9e582edc34e624e7e3d80ee6c7b42f7207d763fff5c2bd3',310467000,NULL,NULL,'5b663fe2b00fe4b32f9280bef61639f6d7ca626769453da3d6f1b8aab9c2424b','d0b8bc9445f92e191fd9f56065486cb7e8fa5f01bf86ed345615aed2af3b56ee','ab5312b48266568dfc8c22e9b475fc9796a1b444656a1598c7ee86db3c653135');
INSERT INTO blocks VALUES(310468,'d84dfd2fcf6d8005aeeac01e03b287af788c81955612375510e37a4ab5766891',310468000,NULL,NULL,'d334aec0de91b9d97591647639937d711b7999e9affbc27bd56170ba655beebd','ce6ad1f0047a576a0f9252be64d1fad1b3d5c01c92975d715b1d6a61eb76bb26','9d4d0f811a1019a8da676b34d87bfec378afc1f1dc754ff9b18658c882c466c3');
INSERT INTO blocks VALUES(310469,'2fbbf2724f537d539b675acb6a479e530c7aac5f93b4045f4356ea4b0f8a8755',310469000,NULL,NULL,'62245a496d48429015b955274c286e9e5b2680c92a5bd1ca506efacb4a988bf0','5599ebaf565594c6cdb3043700147f13bf0fab6095ab246344014c48ba7cff10','f9c926086ecc51eb4787370c9e58cd75dd42198f9dbdeaef2e787eed8cae707e');
INSERT INTO blocks VALUES(310470,'ebb7c8e3fbe0b123a456d753b85b8c123ca3b315da14a00379ebd34784b28921',310470000,NULL,NULL,'fb3c36d774bf3787faa212872cd6796bbe3ec79f465ba0f777191571591e163b','019bf3f9ca5bfc59f0516ce7f19df8fca6fb78576a36a8f9a019cf83288383cb','d113fa70540ad31bd906126f48e375315a3b8203c2962447990b70ed911e482e');
INSERT INTO blocks VALUES(310471,'fc6f8162c55ecffeaabb09f70f071fd0cb7a9ef1bccaafaf27fe9a936defb739',310471000,NULL,NULL,'31fe43bad6c7dd70667fbaab09b493be9930d7b49eee572022a22fbfae759c57','67f8dffec1031821dc4d1f0ae9ddf3be40c0a6fea667ea320f2937a8909ed40d','d177b72e8e03a75e2838080d9edac62ec5081defa23d79bf6e75865f82202ce4');
INSERT INTO blocks VALUES(310472,'57ee5dec5e95b3d9c65a21c407294a32ed538658a6910b16124f18020f16bdf7',310472000,NULL,NULL,'8795262ed4d3b215aef6a1cf8e2800baff99d48acb42265d2665786ad7f28d49','c6889577160d5218e817ba1a1fe39207d0b4259436f0db96a467eaff89c5be3c','9963be2c95bc29cd2765e880de6d3af3114bc5d8a5b0cb1f3ec2deba9c34fba0');
INSERT INTO blocks VALUES(310473,'33994c8f6d06134f886b47e14cb4b5af8fc0fd66e6bd60b3a71986622483e095',310473000,NULL,NULL,'c7bb8e7034781f80988e783b2f67a932aad02f8aadb68e683c2508a2c3d10671','a13e8e5b88c62c4c8584c5426d93e492605a0ae7fb31d889889f61218e11f625','f0f5e2a092e33ad8e5514fd3b8f7f27e76c94cb199fa3962e87f67a9879130dd');
INSERT INTO blocks VALUES(310474,'312ee99e9526e9c240d76e3c3d1fe4c0a21f58156a15f2789605b3e7f7794a09',310474000,NULL,NULL,'f025b8027c4a1669ef83ab3bf1ea3e9101dd7ab351fba1a115685a8fdc392895','f51700debc578916956961e7c9f409b8c2698d19514d2d3ba9d096bdcd17c809','d9c2175a5230bc1911bbe622a0b45cd783a148938345420af1332cc15e1c9f7b');
INSERT INTO blocks VALUES(310475,'bb9289bcd79075962117aef1161b333dbc403efebd593d93fc315146a2f040eb',310475000,NULL,NULL,'f56fa99b7dfccd5a462a9a0253e86b6af40f266c29deafad12d7c400852795d7','125fe7a056f8ebcbcf7e46027b82559f3c50d4c698e6503ae092bb2e7b5c88d7','d28e67f11909678b615b9ead91417a1bc17915edbeacbca620ce3cb50dabc9d3');
INSERT INTO blocks VALUES(310476,'3712e1ebd195749e0dc92f32f7f451dd76f499bf16d709462309ce358a9370d0',310476000,NULL,NULL,'ed0550fcb05ffc2762aea2bf6b448d94dd660c78521a05c0dc0d47556ec20e80','30531d675ecc87a218b9f2d22a7fccf187e67a2ee3ae98a8e9c63f5ed1214dab','98783f1ede2e59d0e3221edfa8dd7a0b5d17b15d85489e1992f575ae089a5856');
INSERT INTO blocks VALUES(310477,'7381973c554ac2bbdc849e8ea8c4a0ecbb46e7967d322446d0d83c3f9deab918',310477000,NULL,NULL,'dead88757da701a5f395594c86f3dbf7638f2c5383f0964273014d34ad6cc805','b3c54183dec99b33b7883a8fb9c349ee3c3cf7cd1c5ca726f4a24752ee3c3fa1','83ff309a43b163b771a0fe6c822d1db8a30907eb4010b2a8cfde0d6d4b888b03');
INSERT INTO blocks VALUES(310478,'c09ee871af7f2a611d43e6130aed171e301c23c5d1a29d183d40bf15898b4fa0',310478000,NULL,NULL,'f74e92b14fa4e74ab3f20be260cfe05bc927f4c470eb7e035a9d2485b95b33ab','1f8ba03270400dd87340ceca83cdbb09d5a9c22e6e156c9d6c3e0506ca60aaf8','ce5e0dba1797f0cc7575a97a74b847c8da2a2399e3452975286c61bdc321d0d0');
INSERT INTO blocks VALUES(310479,'f3d691ce35f62df56d142160b6e2cdcba19d4995c01f802da6ce30bfe8d30030',310479000,NULL,NULL,'3fd82fa85a22bd48c928fb64da2d61b48ad29d457d73768f49ea511e8b85ec3e','a7c76cbcb8cad1fc691cbf84bc239b981441e7c34895d4fdff8540e34603dc9a','db5f6b44439849d30ec2d201db780d1bd495fca45b020cb72335dfc685553648');
INSERT INTO blocks VALUES(310480,'2694e89a62b3abd03a38dfd318c05eb5871f1be00a6e1bf06826fd54d142e681',310480000,NULL,NULL,'841a5fcfce7c514678732bd7be4f7181b65128994c3589c960abaaf52c0550b2','cd61f14725991d63ca5ceaec1c9b40bce5f982e3fcbf8c58d972cce77ed754e4','15e74aacc22a51571388ed89de66c05aa37500e19c28494033004e002e5d4979');
INSERT INTO blocks VALUES(310481,'db37d8f98630ebc61767736ae2c523e4e930095bf54259c01de4d36fd60b6f4a',310481000,NULL,NULL,'e0d70b26255b1b124538766c9594f7b7b649edfc372b0e14258b581a312c7a5a','d2e757fc7bf40a002a2fbb123e00d06c4d953721c818adda30e0f59f153a3762','2d6d4213d97f2c032d1ecda02fd750f25967bc3f554a10aca253cfc9c879dd8c');
INSERT INTO blocks VALUES(310482,'2e27db87dfb6439c006637734e876cc662d1ca74c717756f90f0e535df0787d6',310482000,NULL,NULL,'b97c4e2768d457d0a79a52b45f744d88975c6527e6b93c5898610ab133820c5b','c34c3c81800ed9098f696cdce5f426882bc7ac90d5c60b048a239a6709be7e9c','d8b56463202ef69ca5a6c77aae0b90087a158e70afe2634613bc34200e802321');
INSERT INTO blocks VALUES(310483,'013bac61f8e33c8d8d0f60f5e6a4ec3de9b16696703dea9802f64a258601c460',310483000,NULL,NULL,'181d20f6bd11c022cb61c2204eb624df3599e3b37931fab445fec0d682c0bc35','37bd6d3ca3bbb45df7c17a923ea7996ce64d2f7f952259ab57f53359d19b36e7','facec4058786f8adbd3b9c9a7deaa5062c58c420d3dc3724c787b84d82e2ea63');
INSERT INTO blocks VALUES(310484,'7cac2b3630c31b592fa0497792bed58d3c41120c009471c348b16b5578b3aa2b',310484000,NULL,NULL,'95cdbb5d9550b5b7e3ae2d1167378808a9eb51d25e31a25a6eb473272484ba51','ac28e400e7a31cfc3f2cbb67d2faed857fa47a7e7a63b209b3a5e596db25ead5','be1443a7d93a1e21b9659bb3f156cd982624159c2f4286689f3aceb820dd95da');
INSERT INTO blocks VALUES(310485,'eab5febc9668cd438178496417b22da5f77ceaed5bb6e01fc0f04bef1f5b4478',310485000,NULL,NULL,'cfa4aa1e1b915e41bdd5565e70cc46aa8ad2e5fde150ae22b68fe0cd054a7498','796079d46d2339edf869e328d1728a62f650652a87b4922dfc6ba665fb63cea3','291fac5ce7068fb54e9d2fcf240cedd9f6d7627f2ee836b9cdfde7e731bd384c');
INSERT INTO blocks VALUES(310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,NULL,NULL,'f15bae62406e8f23b783e1d193eed0865094ee808d16d7029e95d4ece8161f20','43773d81c16ff20e2b2dcc49f8e065d3fbb25cf7878340515d7bc953428b1ae9','47d72366fa6e2affe73f6e177df74c5190c47114d2c8bfcff63b91ee9cad7e4c');
INSERT INTO blocks VALUES(310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,NULL,NULL,'c6f1250bd99cb57f9404b7dc6cdb3e5e0a914aac4454fc85a6554659e1776577','b82dee6f8d0d4c814be86b665aec2059acc99c53c57f1394b6a59dcf9d6bb81c','e696a9de9acd5f7aa6b9b818b4ee6897caf24160cc2913bedd733b8954a9338c');
INSERT INTO blocks VALUES(310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,NULL,NULL,'436fbe70442df62ec83896978e3caf8dd067277d0019e2872874055a497e22d1','2b662e815e6b77d6e18b3a3a89d68632bd8ccca61ed01e4f1452b904a8c9976a','52450e582d9336f11704f89541ccac038bf1bbbc1faa2a8df59e5aea384d4ce6');
INSERT INTO blocks VALUES(310489,'2efdb36f986b3e3ccc6cc9b0c1c3cdcb07429fb43cbc0cc3b6c87d1b33f258b6',310489000,NULL,NULL,'21b44b705c75b3b46063aa97335869f71c64e0d5a425d33ef6921acb798520a0','24a61d98ecd90c803e45532e974ca168d3cdfc1b84ba861d5ea35f23c423c6a7','01ae5aaf2e9f002f1c366a49c2aafac316a4b2d93ccbae319547108d8d2a2748');
INSERT INTO blocks VALUES(310490,'e2cb04b8a7368c95359c9d5ff33e64209200fb606de0d64b7c0f67bb1cb8d87c',310490000,NULL,NULL,'ce7e5163a0c49d8cab5f2a81ef50c10c6e221c7eac87a274767451a22415ef1d','57575dcc45b237e1e608b1cb6539792e8134ac2cf5dcc3ce156af3512556fa40','f04f5301844e03dfb03f132df148de3751492232470094505b270db8c146c8f9');
INSERT INTO blocks VALUES(310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,NULL,NULL,'0179c21789f8a3eed1d7acec5efd8945d93a84004f22d35ae3d98313007b4c6c','4391764d05f4fb659d72e77909b697c5c76c882c3ada8ffb27880fa31444051e','298e2137e6d48e70fe2d7434822e6e3ba488af51588880633b17dd1551e19024');
INSERT INTO blocks VALUES(310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,NULL,NULL,'c6ec61d411477811b35149d32bf60976b1fff64f025099c69927a3be90680226','bb38437e9e4d5c787ce4d3c6ffb36650fff5d3731ed1e5db6857c64aaf600a0f','3b6a89e14a16927e7e63a02c8407e42696c866bc5b0b31b35c65cd148eb9483e');
INSERT INTO blocks VALUES(310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,NULL,NULL,'f9ceed959576e1f997b58e61985eff79c41ac907bee882dee5f16e5ebafac144','661afe00aae8fa3d666a489a885841b74ff952edd8b7847f70fb486899e5da66','5bbb53035959f8da4a3bbebd1e7bfe48b27cf21f43e8a4233ccca163a7bc2847');
INSERT INTO blocks VALUES(310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,NULL,NULL,'71db0986f0c599c001eebccd4fb29fba53d903a8a9741adee2c88b2df6c5b5f2','09682ec0df092d0e36a27ca350e552624f1b9a0948785fd3762289f96e73ab90','2565911b2a669c194ec29e5e1587b4cfc30b1688b0a1f041d71d16e844b32adc');
INSERT INTO blocks VALUES(310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,NULL,NULL,'1757f8d920b6d1d086d94b3ccfdf5076cd0f7cba0879f108def569fd76969bd3','ce06c05713568613a9bf82911fcbb8419ef67f70a46e996090aaca4c9aee0f2e','e38510ba232a6fa4c924214debd599dadcf4550209390238666989810a7fa0ce');
INSERT INTO blocks VALUES(310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,NULL,NULL,'cbf1cec7d3415a9b2c3ab6090af0730a46f2ee6e369a0bdf4f41cf437880400c','939ef0fda0d6cf1eedec412182beca88492a798d895d50e24152b20981806a9f','e47b04310e087b8a7ab6b2d15ec7826a3ae98fedaf6afe1b2dd48bb27b332858');
INSERT INTO blocks VALUES(310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,NULL,NULL,'7858106bdc551021c5f2e07ed8dd8e5239a5e8074a53c50eb77cda0c8fd47169','182aa35a2b3940e28e1fc0fc9cc0e43d89b2393e06575f94b448fa063c614527','cb83888b1bd209e5cf470b637eaaedd5adef1256629285f1a48dfad90c2da072');
INSERT INTO blocks VALUES(310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,NULL,NULL,'1cad164291ec7dc0653df419fc67cf3824c71d1529529af33147a5f187b8ecfa','c1dadfb05673cae46d5c57e328a2dae77bcae059b8f49e997bd0fbaaa17de7a1','3843289a8553d312f1162e3a29c7b15bf3bdb0aaee3395cdb6ab4bcf9b87ddc8');
INSERT INTO blocks VALUES(310499,'1950e1a4d7fc820ed9603f6df6819c3c953c277c726340dec2a4253e261a1764',310499000,NULL,NULL,'6f29e1dddd8b8cb5b742b41b6934cdc661d55186c491cca6ac4e235b03a939cb','8f732d1154a0cd8884c1ef654d7f7ab0227254c11892102227b335e5208d33cd','890ee7b986cafe7ea9022a683c29cddafd82d243d76ede2b42628cc97a527bda');
INSERT INTO blocks VALUES(310500,'54aeaf47d5387964e2d51617bf3af50520a0449410e0d096cf8c2aa9dad5550b',310500000,NULL,NULL,'b0d5e233fb154faa5f368b7ca1b7234da632efe54ef4dca0bf1093adeed6c3bf','a3c16865afa0fdfb40454429457e8a8ea02354e9168693640d48525626f8f138','57eb696f4b0946270518b5cf83324420a45c3740c2d997224a1015ee8e90c64e');
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
INSERT INTO broadcasts VALUES(110,'510f6feb902159622d83f64eae590a4fec88989869a20caf5804c313aa5e0186',310109,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',1388000002,1.0,5000000,'Unit Test',0,'valid');
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
INSERT INTO burns VALUES(107,'93c6d2499a0536c31c77a3db3fc9fc8456fbd0726c45b8f716af16f938727a73',310106,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',31000000,46499556869,'valid');
INSERT INTO burns VALUES(115,'89c728bbe0c53eb9de4774a1261dfd8895ed0a3364dd41c5a06172472a84cee5',310114,'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx',62000000,92999046851,'valid');
INSERT INTO burns VALUES(494,'c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a',310493,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',62000000,92995878046,'valid');
INSERT INTO burns VALUES(498,'bbf0b9f6992755a3e371fb0c0b72f6828831e81c6f7ada6f95ba1104fb901ac3',310497,'mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK',10000,14999330,'valid');
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
INSERT INTO credits VALUES(310106,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',46499556869,'burn','93c6d2499a0536c31c77a3db3fc9fc8456fbd0726c45b8f716af16f938727a73');
INSERT INTO credits VALUES(310107,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','PAYTOSCRIPT',1000,'issuance','ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e');
INSERT INTO credits VALUES(310108,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000,'send','f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481');
INSERT INTO credits VALUES(310111,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','LOCKEDPREV',1000,'issuance','5f66cb2a8f0a4605cf274a21daf0a61af10fdf3fdc5210e5bcf8f9f3d26b0bc9');
INSERT INTO credits VALUES(310114,'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx','XCP',92999046851,'burn','89c728bbe0c53eb9de4774a1261dfd8895ed0a3364dd41c5a06172472a84cee5');
INSERT INTO credits VALUES(310481,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'send','b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5');
INSERT INTO credits VALUES(310482,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'send','c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34');
INSERT INTO credits VALUES(310493,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',92995878046,'burn','c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a');
INSERT INTO credits VALUES(310494,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','DIVIDEND',100,'issuance','4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5');
INSERT INTO credits VALUES(310495,'mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','DIVIDEND',10,'send','129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc');
INSERT INTO credits VALUES(310496,'mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','XCP',92945878046,'send','1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6');
INSERT INTO credits VALUES(310497,'mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK','XCP',14999330,'burn','bbf0b9f6992755a3e371fb0c0b72f6828831e81c6f7ada6f95ba1104fb901ac3');
INSERT INTO credits VALUES(310498,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','PARENT',100000000,'issuance','076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f');
INSERT INTO credits VALUES(310499,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','A95428956661682277',100000000,'issuance','0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf');
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
INSERT INTO debits VALUES(310107,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',50000000,'issuance fee','ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e');
INSERT INTO debits VALUES(310108,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000,'send','f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481');
INSERT INTO debits VALUES(310110,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',10,'bet','d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048');
INSERT INTO debits VALUES(310111,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',50000000,'issuance fee','5f66cb2a8f0a4605cf274a21daf0a61af10fdf3fdc5210e5bcf8f9f3d26b0bc9');
INSERT INTO debits VALUES(310112,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',0,'issuance fee','74aa7471cdb1b13162e0116dd0cbcc4022cbdbdadef0ee0c5b8d63e527e666fe');
INSERT INTO debits VALUES(310113,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',0,'issuance fee','214edd39455a080e261e3c319f23d3fe5f064f48c044c0973811b6a85dd2990d');
INSERT INTO debits VALUES(310481,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'send','b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5');
INSERT INTO debits VALUES(310482,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'send','c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34');
INSERT INTO debits VALUES(310487,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','XCP',9,'bet','2447f6974033ac41c40b4598dfb73fc7479fd85bb9d01de2267b3f7842803275');
INSERT INTO debits VALUES(310491,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09');
INSERT INTO debits VALUES(310494,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',50000000,'issuance fee','4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5');
INSERT INTO debits VALUES(310495,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','DIVIDEND',10,'send','129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc');
INSERT INTO debits VALUES(310496,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',92945878046,'send','1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6');
INSERT INTO debits VALUES(310498,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f');
INSERT INTO debits VALUES(310499,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',25000000,'issuance fee','0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf');
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
INSERT INTO issuances VALUES(108,'ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e',310107,'PAYTOSCRIPT',1000,0,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',0,0,0,0.0,'PSH issued asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(112,'5f66cb2a8f0a4605cf274a21daf0a61af10fdf3fdc5210e5bcf8f9f3d26b0bc9',310111,'LOCKEDPREV',1000,1,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',0,0,0,0.0,'Locked asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(113,'74aa7471cdb1b13162e0116dd0cbcc4022cbdbdadef0ee0c5b8d63e527e666fe',310112,'LOCKEDPREV',0,1,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',0,0,0,0.0,'Locked asset',0,1,'valid',NULL);
INSERT INTO issuances VALUES(114,'214edd39455a080e261e3c319f23d3fe5f064f48c044c0973811b6a85dd2990d',310113,'LOCKEDPREV',0,1,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',0,0,0,0.0,'changed',0,0,'valid',NULL);
INSERT INTO issuances VALUES(495,'4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5',310494,'DIVIDEND',100,1,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',0,0,0,0.0,'Test dividend',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(499,'076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f',310498,'PARENT',100000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Parent asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(500,'0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf',310499,'A95428956661682277',100000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Child of parent',25000000,0,'valid','PARENT.already.issued');
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
INSERT INTO messages VALUES(69,310106,'insert','credits','{"action": "burn", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "XCP", "block_index": 310106, "event": "93c6d2499a0536c31c77a3db3fc9fc8456fbd0726c45b8f716af16f938727a73", "quantity": 46499556869}',0);
INSERT INTO messages VALUES(70,310106,'insert','burns','{"block_index": 310106, "burned": 31000000, "earned": 46499556869, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "valid", "tx_hash": "93c6d2499a0536c31c77a3db3fc9fc8456fbd0726c45b8f716af16f938727a73", "tx_index": 107}',0);
INSERT INTO messages VALUES(71,310107,'insert','debits','{"action": "issuance fee", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "XCP", "block_index": 310107, "event": "ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e", "quantity": 50000000}',0);
INSERT INTO messages VALUES(72,310107,'insert','issuances','{"asset": "PAYTOSCRIPT", "asset_longname": null, "block_index": 310107, "call_date": 0, "call_price": 0.0, "callable": false, "description": "PSH issued asset", "divisible": false, "fee_paid": 50000000, "issuer": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "locked": false, "quantity": 1000, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "valid", "transfer": false, "tx_hash": "ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e", "tx_index": 108}',0);
INSERT INTO messages VALUES(73,310107,'insert','credits','{"action": "issuance", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "PAYTOSCRIPT", "block_index": 310107, "event": "ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e", "quantity": 1000}',0);
INSERT INTO messages VALUES(74,310108,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 310108, "event": "f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481", "quantity": 100000000}',0);
INSERT INTO messages VALUES(75,310108,'insert','credits','{"action": "send", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "DIVISIBLE", "block_index": 310108, "event": "f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481", "quantity": 100000000}',0);
INSERT INTO messages VALUES(76,310108,'insert','sends','{"asset": "DIVISIBLE", "block_index": 310108, "destination": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481", "tx_index": 109}',0);
INSERT INTO messages VALUES(77,310109,'insert','broadcasts','{"block_index": 310109, "fee_fraction_int": 5000000, "locked": false, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "valid", "text": "Unit Test", "timestamp": 1388000002, "tx_hash": "510f6feb902159622d83f64eae590a4fec88989869a20caf5804c313aa5e0186", "tx_index": 110, "value": 1.0}',0);
INSERT INTO messages VALUES(78,310110,'insert','debits','{"action": "bet", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "XCP", "block_index": 310110, "event": "d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048", "quantity": 10}',0);
INSERT INTO messages VALUES(79,310110,'insert','bets','{"bet_type": 3, "block_index": 310110, "counterwager_quantity": 10, "counterwager_remaining": 10, "deadline": 1388000200, "expiration": 1000, "expire_index": 311110, "fee_fraction_int": 5000000.0, "feed_address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "leverage": 5040, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "open", "target_value": 0.0, "tx_hash": "d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048", "tx_index": 111, "wager_quantity": 10, "wager_remaining": 10}',0);
INSERT INTO messages VALUES(80,310111,'insert','debits','{"action": "issuance fee", "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "asset": "XCP", "block_index": 310111, "event": "5f66cb2a8f0a4605cf274a21daf0a61af10fdf3fdc5210e5bcf8f9f3d26b0bc9", "quantity": 50000000}',0);
INSERT INTO messages VALUES(81,310111,'insert','issuances','{"asset": "LOCKEDPREV", "asset_longname": null, "block_index": 310111, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Locked asset", "divisible": true, "fee_paid": 50000000, "issuer": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "locked": false, "quantity": 1000, "source": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "status": "valid", "transfer": false, "tx_hash": "5f66cb2a8f0a4605cf274a21daf0a61af10fdf3fdc5210e5bcf8f9f3d26b0bc9", "tx_index": 112}',0);
INSERT INTO messages VALUES(82,310111,'insert','credits','{"action": "issuance", "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "asset": "LOCKEDPREV", "block_index": 310111, "event": "5f66cb2a8f0a4605cf274a21daf0a61af10fdf3fdc5210e5bcf8f9f3d26b0bc9", "quantity": 1000}',0);
INSERT INTO messages VALUES(83,310112,'insert','debits','{"action": "issuance fee", "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "asset": "XCP", "block_index": 310112, "event": "74aa7471cdb1b13162e0116dd0cbcc4022cbdbdadef0ee0c5b8d63e527e666fe", "quantity": 0}',0);
INSERT INTO messages VALUES(84,310112,'insert','issuances','{"asset": "LOCKEDPREV", "asset_longname": null, "block_index": 310112, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Locked asset", "divisible": true, "fee_paid": 0, "issuer": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "locked": true, "quantity": 0, "source": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "status": "valid", "transfer": false, "tx_hash": "74aa7471cdb1b13162e0116dd0cbcc4022cbdbdadef0ee0c5b8d63e527e666fe", "tx_index": 113}',0);
INSERT INTO messages VALUES(85,310113,'insert','debits','{"action": "issuance fee", "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "asset": "XCP", "block_index": 310113, "event": "214edd39455a080e261e3c319f23d3fe5f064f48c044c0973811b6a85dd2990d", "quantity": 0}',0);
INSERT INTO messages VALUES(86,310113,'insert','issuances','{"asset": "LOCKEDPREV", "asset_longname": null, "block_index": 310113, "call_date": 0, "call_price": 0.0, "callable": false, "description": "changed", "divisible": true, "fee_paid": 0, "issuer": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "locked": false, "quantity": 0, "source": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "status": "valid", "transfer": false, "tx_hash": "214edd39455a080e261e3c319f23d3fe5f064f48c044c0973811b6a85dd2990d", "tx_index": 114}',0);
INSERT INTO messages VALUES(87,310114,'insert','credits','{"action": "burn", "address": "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx", "asset": "XCP", "block_index": 310114, "event": "89c728bbe0c53eb9de4774a1261dfd8895ed0a3364dd41c5a06172472a84cee5", "quantity": 92999046851}',0);
INSERT INTO messages VALUES(88,310114,'insert','burns','{"block_index": 310114, "burned": 62000000, "earned": 92999046851, "source": "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx", "status": "valid", "tx_hash": "89c728bbe0c53eb9de4774a1261dfd8895ed0a3364dd41c5a06172472a84cee5", "tx_index": 115}',0);
INSERT INTO messages VALUES(89,310481,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310481, "event": "b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5", "quantity": 100000000}',0);
INSERT INTO messages VALUES(90,310481,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310481, "event": "b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5", "quantity": 100000000}',0);
INSERT INTO messages VALUES(91,310481,'insert','sends','{"asset": "XCP", "block_index": 310481, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "memo": "68656c6c6f", "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5", "tx_index": 482}',0);
INSERT INTO messages VALUES(92,310482,'insert','debits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310482, "event": "c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34", "quantity": 100000000}',0);
INSERT INTO messages VALUES(93,310482,'insert','credits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310482, "event": "c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34", "quantity": 100000000}',0);
INSERT INTO messages VALUES(94,310482,'insert','sends','{"asset": "XCP", "block_index": 310482, "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "memo": "fade0001", "quantity": 100000000, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "valid", "tx_hash": "c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34", "tx_index": 483}',0);
INSERT INTO messages VALUES(95,310486,'insert','broadcasts','{"block_index": 310486, "fee_fraction_int": 5000000, "locked": false, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "096883e142a87377d3a4103f4702556e25824f1e23667aceb1690f66e1417062", "tx_index": 487, "value": 1.0}',0);
INSERT INTO messages VALUES(96,310487,'insert','debits','{"action": "bet", "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "asset": "XCP", "block_index": 310487, "event": "2447f6974033ac41c40b4598dfb73fc7479fd85bb9d01de2267b3f7842803275", "quantity": 9}',0);
INSERT INTO messages VALUES(97,310487,'insert','bets','{"bet_type": 1, "block_index": 310487, "counterwager_quantity": 9, "counterwager_remaining": 9, "deadline": 1388000001, "expiration": 100, "expire_index": 310587, "fee_fraction_int": 5000000.0, "feed_address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "leverage": 5040, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "open", "target_value": 0.0, "tx_hash": "2447f6974033ac41c40b4598dfb73fc7479fd85bb9d01de2267b3f7842803275", "tx_index": 488, "wager_quantity": 9, "wager_remaining": 9}',0);
INSERT INTO messages VALUES(98,310488,'insert','broadcasts','{"block_index": 310488, "fee_fraction_int": 0, "locked": false, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": "options 0", "timestamp": 1388000002, "tx_hash": "9b1cad827c97c463c2b39cc9d550693c438010ef85a10ee04d3db8699193e906", "tx_index": 489, "value": 1.0}',0);
INSERT INTO messages VALUES(99,310488,'insert','replace','{"address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "block_index": 310488, "options": 0}',0);
INSERT INTO messages VALUES(100,310489,'insert','broadcasts','{"block_index": 310489, "fee_fraction_int": null, "locked": true, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": null, "timestamp": 0, "tx_hash": "9a39bade308462ec65be3c8420a0f2189b1d4e947d4c7950a37176de71de4f87", "tx_index": 490, "value": null}',0);
INSERT INTO messages VALUES(101,310490,'insert','broadcasts','{"block_index": 310490, "fee_fraction_int": 0, "locked": false, "source": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "status": "valid", "text": "options 1", "timestamp": 1388000004, "tx_hash": "4b233a74b9db14a8619ee8ec5558149e53ab033be31e803257f760aa9ef2f3b9", "tx_index": 491, "value": 1.0}',0);
INSERT INTO messages VALUES(102,310490,'insert','replace','{"address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "block_index": 310490, "options": 1}',0);
INSERT INTO messages VALUES(103,310491,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310491, "event": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09", "quantity": 100000000}',0);
INSERT INTO messages VALUES(104,310491,'insert','orders','{"block_index": 310491, "expiration": 2000, "expire_index": 312491, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 800000, "get_remaining": 800000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09", "tx_index": 492}',0);
INSERT INTO messages VALUES(105,310492,'insert','orders','{"block_index": 310492, "expiration": 2000, "expire_index": 312492, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 800000, "give_remaining": 800000, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "tx_hash": "2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4", "tx_index": 493}',0);
INSERT INTO messages VALUES(106,310492,'update','orders','{"fee_provided_remaining": 6800, "fee_required_remaining": 892800, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09"}',0);
INSERT INTO messages VALUES(107,310492,'update','orders','{"fee_provided_remaining": 992800, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4"}',0);
INSERT INTO messages VALUES(108,310492,'insert','order_matches','{"backward_asset": "BTC", "backward_quantity": 800000, "block_index": 310492, "fee_paid": 7200, "forward_asset": "XCP", "forward_quantity": 100000000, "id": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09_2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4", "match_expire_index": 310512, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 310491, "tx0_expiration": 2000, "tx0_hash": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09", "tx0_index": 492, "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_block_index": 310492, "tx1_expiration": 2000, "tx1_hash": "2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4", "tx1_index": 493}',0);
INSERT INTO messages VALUES(109,310493,'insert','credits','{"action": "burn", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310493, "event": "c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a", "quantity": 92995878046}',0);
INSERT INTO messages VALUES(110,310493,'insert','burns','{"block_index": 310493, "burned": 62000000, "earned": 92995878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a", "tx_index": 494}',0);
INSERT INTO messages VALUES(111,310494,'insert','debits','{"action": "issuance fee", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310494, "event": "4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5", "quantity": 50000000}',0);
INSERT INTO messages VALUES(112,310494,'insert','issuances','{"asset": "DIVIDEND", "asset_longname": null, "block_index": 310494, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Test dividend", "divisible": true, "fee_paid": 50000000, "issuer": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "locked": false, "quantity": 100, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "transfer": false, "tx_hash": "4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5", "tx_index": 495}',0);
INSERT INTO messages VALUES(113,310494,'insert','credits','{"action": "issuance", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310494, "event": "4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5", "quantity": 100}',0);
INSERT INTO messages VALUES(114,310495,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310495, "event": "129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc", "quantity": 10}',0);
INSERT INTO messages VALUES(115,310495,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "DIVIDEND", "block_index": 310495, "event": "129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc", "quantity": 10}',0);
INSERT INTO messages VALUES(116,310495,'insert','sends','{"asset": "DIVIDEND", "block_index": 310495, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 10, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc", "tx_index": 496}',0);
INSERT INTO messages VALUES(117,310496,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310496, "event": "1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(118,310496,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "XCP", "block_index": 310496, "event": "1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(119,310496,'insert','sends','{"asset": "XCP", "block_index": 310496, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 92945878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6", "tx_index": 497}',0);
INSERT INTO messages VALUES(120,310497,'insert','credits','{"action": "burn", "address": "mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK", "asset": "XCP", "block_index": 310497, "event": "bbf0b9f6992755a3e371fb0c0b72f6828831e81c6f7ada6f95ba1104fb901ac3", "quantity": 14999330}',0);
INSERT INTO messages VALUES(121,310497,'insert','burns','{"block_index": 310497, "burned": 10000, "earned": 14999330, "source": "mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK", "status": "valid", "tx_hash": "bbf0b9f6992755a3e371fb0c0b72f6828831e81c6f7ada6f95ba1104fb901ac3", "tx_index": 498}',0);
INSERT INTO messages VALUES(122,310498,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310498, "event": "076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f", "quantity": 50000000}',0);
INSERT INTO messages VALUES(123,310498,'insert','issuances','{"asset": "PARENT", "asset_longname": null, "block_index": 310498, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Parent asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f", "tx_index": 499}',0);
INSERT INTO messages VALUES(124,310498,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "PARENT", "block_index": 310498, "event": "076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f", "quantity": 100000000}',0);
INSERT INTO messages VALUES(125,310499,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310499, "event": "0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf", "quantity": 25000000}',0);
INSERT INTO messages VALUES(126,310499,'insert','issuances','{"asset": "A95428956661682277", "asset_longname": "PARENT.already.issued", "block_index": 310499, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Child of parent", "divisible": true, "fee_paid": 25000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf", "tx_index": 500}',0);
INSERT INTO messages VALUES(127,310499,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "A95428956661682277", "block_index": 310499, "event": "0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf", "quantity": 100000000}',0);
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
INSERT INTO sends VALUES(109,'f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481',310108,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000,'valid',NULL);
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
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
-- Triggers and indices on  sweeps
CREATE TRIGGER _sweeps_delete BEFORE DELETE ON sweeps BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO sweeps(rowid,tx_index,tx_hash,block_index,source,destination,flags,status,memo) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.source)||','||quote(old.destination)||','||quote(old.flags)||','||quote(old.status)||','||quote(old.memo)||')');
                            END;
CREATE TRIGGER _sweeps_insert AFTER INSERT ON sweeps BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM sweeps WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _sweeps_update AFTER UPDATE ON sweeps BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE sweeps SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',source='||quote(old.source)||',destination='||quote(old.destination)||',flags='||quote(old.flags)||',status='||quote(old.status)||',memo='||quote(old.memo)||' WHERE rowid='||old.rowid);
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
INSERT INTO transactions VALUES(107,'93c6d2499a0536c31c77a3db3fc9fc8456fbd0726c45b8f716af16f938727a73',310106,'9d39cbe8c8a5357fc56e5c2f95bf132382ddad14cbc8abd54e549d58248140ff',310106000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','mvCounterpartyXXXXXXXXXXXXXXW24Hef',31000000,5625,X'',1);
INSERT INTO transactions VALUES(108,'ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e',310107,'51cc04005e49fa49e661946a0e147240b0e5aac174252c96481ab7ddd5487435',310107000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','',0,6800,X'0000001400078A8FE2E5E44100000000000003E8000000000000000000001050534820697373756564206173736574',1);
INSERT INTO transactions VALUES(109,'f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481',310108,'8f2d3861aa42f8e75dc14a23d6046bd89feef0d81996b6e1adc2a2828fbc8b34',310108000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',5430,7650,X'00000000000000A25BE34B660000000005F5E100',1);
INSERT INTO transactions VALUES(110,'510f6feb902159622d83f64eae590a4fec88989869a20caf5804c313aa5e0186',310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','',0,5975,X'0000001E52BB33023FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(111,'d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048',310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',5430,7124,X'00000028000352BB33C8000000000000000A000000000000000A0000000000000000000013B0000003E8',1);
INSERT INTO transactions VALUES(112,'5f66cb2a8f0a4605cf274a21daf0a61af10fdf3fdc5210e5bcf8f9f3d26b0bc9',310111,'fde71b9756d5ba0b6d8b230ee885af01f9c4461a55dbde8678279166a21b20ae',310111000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','',0,6800,X'00000014000038FEDF6D2C6900000000000003E8010000000000000000000C4C6F636B6564206173736574',1);
INSERT INTO transactions VALUES(113,'74aa7471cdb1b13162e0116dd0cbcc4022cbdbdadef0ee0c5b8d63e527e666fe',310112,'5b06f69bfdde1083785cf68ebc2211b464839033c30a099d3227b490bf3ab251',310112000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','',0,6800,X'00000014000038FEDF6D2C69000000000000000001000000000000000000044C4F434B',1);
INSERT INTO transactions VALUES(114,'214edd39455a080e261e3c319f23d3fe5f064f48c044c0973811b6a85dd2990d',310113,'63914cf376d3076b697b9234810dfc084ed5a885d5cd188dd5462560da25d5e7',310113000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','',0,6800,X'00000014000038FEDF6D2C69000000000000000001000000000000000000076368616E676564',1);
INSERT INTO transactions VALUES(115,'89c728bbe0c53eb9de4774a1261dfd8895ed0a3364dd41c5a06172472a84cee5',310114,'24fc2dded4f811eff58b32cda85d90fb5773e81b9267e9a03c359bc730d82283',310114000,'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
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
INSERT INTO transactions VALUES(498,'bbf0b9f6992755a3e371fb0c0b72f6828831e81c6f7ada6f95ba1104fb901ac3',310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,'mrPk7hTeZWjjSCrMTC2ET4SAUThQt7C4uK','mvCounterpartyXXXXXXXXXXXXXXW24Hef',10000,5625,X'',1);
INSERT INTO transactions VALUES(499,'076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f',310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6300,X'00000014000000000AA4097D0000000005F5E100010000000000000000000C506172656E74206173736574',1);
INSERT INTO transactions VALUES(500,'0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf',310499,'1950e1a4d7fc820ed9603f6df6819c3c953c277c726340dec2a4253e261a1764',310499000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6550,X'0000001501530821671B10650000000005F5E10001108E90A57DBA9967C422E83080F22F0C684368696C64206F6620706172656E74',1);
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
INSERT INTO undolog VALUES(146,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92050000000 WHERE rowid=1');
INSERT INTO undolog VALUES(147,'DELETE FROM debits WHERE rowid=25');
INSERT INTO undolog VALUES(148,'UPDATE balances SET address=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',asset=''XCP'',quantity=99999990 WHERE rowid=7');
INSERT INTO undolog VALUES(149,'DELETE FROM credits WHERE rowid=26');
INSERT INTO undolog VALUES(150,'DELETE FROM sends WHERE rowid=482');
INSERT INTO undolog VALUES(151,'UPDATE balances SET address=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',asset=''XCP'',quantity=199999990 WHERE rowid=7');
INSERT INTO undolog VALUES(152,'DELETE FROM debits WHERE rowid=26');
INSERT INTO undolog VALUES(153,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91950000000 WHERE rowid=1');
INSERT INTO undolog VALUES(154,'DELETE FROM credits WHERE rowid=27');
INSERT INTO undolog VALUES(155,'DELETE FROM sends WHERE rowid=483');
INSERT INTO undolog VALUES(156,'DELETE FROM broadcasts WHERE rowid=487');
INSERT INTO undolog VALUES(157,'UPDATE balances SET address=''myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM'',asset=''XCP'',quantity=92999138821 WHERE rowid=13');
INSERT INTO undolog VALUES(158,'DELETE FROM debits WHERE rowid=27');
INSERT INTO undolog VALUES(159,'DELETE FROM bets WHERE rowid=5');
INSERT INTO undolog VALUES(160,'DELETE FROM broadcasts WHERE rowid=489');
INSERT INTO undolog VALUES(161,'DELETE FROM addresses WHERE rowid=1');
INSERT INTO undolog VALUES(162,'DELETE FROM broadcasts WHERE rowid=490');
INSERT INTO undolog VALUES(163,'DELETE FROM broadcasts WHERE rowid=491');
INSERT INTO undolog VALUES(164,'DELETE FROM addresses WHERE rowid=2');
INSERT INTO undolog VALUES(165,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92050000000 WHERE rowid=1');
INSERT INTO undolog VALUES(166,'DELETE FROM debits WHERE rowid=28');
INSERT INTO undolog VALUES(167,'DELETE FROM orders WHERE rowid=5');
INSERT INTO undolog VALUES(168,'DELETE FROM orders WHERE rowid=6');
INSERT INTO undolog VALUES(169,'UPDATE orders SET tx_index=492,tx_hash=''9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09'',block_index=310491,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''XCP'',give_quantity=100000000,give_remaining=100000000,get_asset=''BTC'',get_quantity=800000,get_remaining=800000,expiration=2000,expire_index=312491,fee_required=900000,fee_required_remaining=900000,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(170,'UPDATE orders SET tx_index=493,tx_hash=''2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4'',block_index=310492,source=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',give_asset=''BTC'',give_quantity=800000,give_remaining=800000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=2000,expire_index=312492,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=6');
INSERT INTO undolog VALUES(171,'DELETE FROM order_matches WHERE rowid=1');
INSERT INTO undolog VALUES(172,'DELETE FROM balances WHERE rowid=21');
INSERT INTO undolog VALUES(173,'DELETE FROM credits WHERE rowid=28');
INSERT INTO undolog VALUES(174,'DELETE FROM burns WHERE rowid=494');
INSERT INTO undolog VALUES(175,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''XCP'',quantity=92995878046 WHERE rowid=21');
INSERT INTO undolog VALUES(176,'DELETE FROM debits WHERE rowid=29');
INSERT INTO undolog VALUES(177,'DELETE FROM assets WHERE rowid=10');
INSERT INTO undolog VALUES(178,'DELETE FROM issuances WHERE rowid=495');
INSERT INTO undolog VALUES(179,'DELETE FROM balances WHERE rowid=22');
INSERT INTO undolog VALUES(180,'DELETE FROM credits WHERE rowid=29');
INSERT INTO undolog VALUES(181,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''DIVIDEND'',quantity=100 WHERE rowid=22');
INSERT INTO undolog VALUES(182,'DELETE FROM debits WHERE rowid=30');
INSERT INTO undolog VALUES(183,'DELETE FROM balances WHERE rowid=23');
INSERT INTO undolog VALUES(184,'DELETE FROM credits WHERE rowid=30');
INSERT INTO undolog VALUES(185,'DELETE FROM sends WHERE rowid=496');
INSERT INTO undolog VALUES(186,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''XCP'',quantity=92945878046 WHERE rowid=21');
INSERT INTO undolog VALUES(187,'DELETE FROM debits WHERE rowid=31');
INSERT INTO undolog VALUES(188,'DELETE FROM balances WHERE rowid=24');
INSERT INTO undolog VALUES(189,'DELETE FROM credits WHERE rowid=31');
INSERT INTO undolog VALUES(190,'DELETE FROM sends WHERE rowid=497');
INSERT INTO undolog VALUES(191,'DELETE FROM balances WHERE rowid=25');
INSERT INTO undolog VALUES(192,'DELETE FROM credits WHERE rowid=32');
INSERT INTO undolog VALUES(193,'DELETE FROM burns WHERE rowid=498');
INSERT INTO undolog VALUES(194,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91950000000 WHERE rowid=1');
INSERT INTO undolog VALUES(195,'DELETE FROM debits WHERE rowid=32');
INSERT INTO undolog VALUES(196,'DELETE FROM assets WHERE rowid=11');
INSERT INTO undolog VALUES(197,'DELETE FROM issuances WHERE rowid=499');
INSERT INTO undolog VALUES(198,'DELETE FROM balances WHERE rowid=26');
INSERT INTO undolog VALUES(199,'DELETE FROM credits WHERE rowid=33');
INSERT INTO undolog VALUES(200,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91900000000 WHERE rowid=1');
INSERT INTO undolog VALUES(201,'DELETE FROM debits WHERE rowid=33');
INSERT INTO undolog VALUES(202,'DELETE FROM assets WHERE rowid=12');
INSERT INTO undolog VALUES(203,'DELETE FROM issuances WHERE rowid=500');
INSERT INTO undolog VALUES(204,'DELETE FROM balances WHERE rowid=27');
INSERT INTO undolog VALUES(205,'DELETE FROM credits WHERE rowid=34');

-- Table  undolog_block
DROP TABLE IF EXISTS undolog_block;
CREATE TABLE undolog_block(
                        block_index INTEGER PRIMARY KEY,
                        first_undo_index INTEGER);
INSERT INTO undolog_block VALUES(310400,146);
INSERT INTO undolog_block VALUES(310401,146);
INSERT INTO undolog_block VALUES(310402,146);
INSERT INTO undolog_block VALUES(310403,146);
INSERT INTO undolog_block VALUES(310404,146);
INSERT INTO undolog_block VALUES(310405,146);
INSERT INTO undolog_block VALUES(310406,146);
INSERT INTO undolog_block VALUES(310407,146);
INSERT INTO undolog_block VALUES(310408,146);
INSERT INTO undolog_block VALUES(310409,146);
INSERT INTO undolog_block VALUES(310410,146);
INSERT INTO undolog_block VALUES(310411,146);
INSERT INTO undolog_block VALUES(310412,146);
INSERT INTO undolog_block VALUES(310413,146);
INSERT INTO undolog_block VALUES(310414,146);
INSERT INTO undolog_block VALUES(310415,146);
INSERT INTO undolog_block VALUES(310416,146);
INSERT INTO undolog_block VALUES(310417,146);
INSERT INTO undolog_block VALUES(310418,146);
INSERT INTO undolog_block VALUES(310419,146);
INSERT INTO undolog_block VALUES(310420,146);
INSERT INTO undolog_block VALUES(310421,146);
INSERT INTO undolog_block VALUES(310422,146);
INSERT INTO undolog_block VALUES(310423,146);
INSERT INTO undolog_block VALUES(310424,146);
INSERT INTO undolog_block VALUES(310425,146);
INSERT INTO undolog_block VALUES(310426,146);
INSERT INTO undolog_block VALUES(310427,146);
INSERT INTO undolog_block VALUES(310428,146);
INSERT INTO undolog_block VALUES(310429,146);
INSERT INTO undolog_block VALUES(310430,146);
INSERT INTO undolog_block VALUES(310431,146);
INSERT INTO undolog_block VALUES(310432,146);
INSERT INTO undolog_block VALUES(310433,146);
INSERT INTO undolog_block VALUES(310434,146);
INSERT INTO undolog_block VALUES(310435,146);
INSERT INTO undolog_block VALUES(310436,146);
INSERT INTO undolog_block VALUES(310437,146);
INSERT INTO undolog_block VALUES(310438,146);
INSERT INTO undolog_block VALUES(310439,146);
INSERT INTO undolog_block VALUES(310440,146);
INSERT INTO undolog_block VALUES(310441,146);
INSERT INTO undolog_block VALUES(310442,146);
INSERT INTO undolog_block VALUES(310443,146);
INSERT INTO undolog_block VALUES(310444,146);
INSERT INTO undolog_block VALUES(310445,146);
INSERT INTO undolog_block VALUES(310446,146);
INSERT INTO undolog_block VALUES(310447,146);
INSERT INTO undolog_block VALUES(310448,146);
INSERT INTO undolog_block VALUES(310449,146);
INSERT INTO undolog_block VALUES(310450,146);
INSERT INTO undolog_block VALUES(310451,146);
INSERT INTO undolog_block VALUES(310452,146);
INSERT INTO undolog_block VALUES(310453,146);
INSERT INTO undolog_block VALUES(310454,146);
INSERT INTO undolog_block VALUES(310455,146);
INSERT INTO undolog_block VALUES(310456,146);
INSERT INTO undolog_block VALUES(310457,146);
INSERT INTO undolog_block VALUES(310458,146);
INSERT INTO undolog_block VALUES(310459,146);
INSERT INTO undolog_block VALUES(310460,146);
INSERT INTO undolog_block VALUES(310461,146);
INSERT INTO undolog_block VALUES(310462,146);
INSERT INTO undolog_block VALUES(310463,146);
INSERT INTO undolog_block VALUES(310464,146);
INSERT INTO undolog_block VALUES(310465,146);
INSERT INTO undolog_block VALUES(310466,146);
INSERT INTO undolog_block VALUES(310467,146);
INSERT INTO undolog_block VALUES(310468,146);
INSERT INTO undolog_block VALUES(310469,146);
INSERT INTO undolog_block VALUES(310470,146);
INSERT INTO undolog_block VALUES(310471,146);
INSERT INTO undolog_block VALUES(310472,146);
INSERT INTO undolog_block VALUES(310473,146);
INSERT INTO undolog_block VALUES(310474,146);
INSERT INTO undolog_block VALUES(310475,146);
INSERT INTO undolog_block VALUES(310476,146);
INSERT INTO undolog_block VALUES(310477,146);
INSERT INTO undolog_block VALUES(310478,146);
INSERT INTO undolog_block VALUES(310479,146);
INSERT INTO undolog_block VALUES(310480,146);
INSERT INTO undolog_block VALUES(310481,146);
INSERT INTO undolog_block VALUES(310482,151);
INSERT INTO undolog_block VALUES(310483,156);
INSERT INTO undolog_block VALUES(310484,156);
INSERT INTO undolog_block VALUES(310485,156);
INSERT INTO undolog_block VALUES(310486,156);
INSERT INTO undolog_block VALUES(310487,157);
INSERT INTO undolog_block VALUES(310488,160);
INSERT INTO undolog_block VALUES(310489,162);
INSERT INTO undolog_block VALUES(310490,163);
INSERT INTO undolog_block VALUES(310491,165);
INSERT INTO undolog_block VALUES(310492,168);
INSERT INTO undolog_block VALUES(310493,172);
INSERT INTO undolog_block VALUES(310494,175);
INSERT INTO undolog_block VALUES(310495,181);
INSERT INTO undolog_block VALUES(310496,186);
INSERT INTO undolog_block VALUES(310497,191);
INSERT INTO undolog_block VALUES(310498,194);
INSERT INTO undolog_block VALUES(310499,200);
INSERT INTO undolog_block VALUES(310500,206);

-- For primary key autoincrements the next id to use is stored in
-- sqlite_sequence
DELETE FROM main.sqlite_sequence WHERE name='undolog';
INSERT INTO main.sqlite_sequence VALUES ('undolog', 205);

COMMIT TRANSACTION;
