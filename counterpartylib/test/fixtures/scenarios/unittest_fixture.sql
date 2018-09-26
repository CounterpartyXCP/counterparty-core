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
INSERT INTO balances VALUES('munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','XCP',92999130460);
INSERT INTO balances VALUES('mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',92949122099);
INSERT INTO balances VALUES('2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',46449556859);
INSERT INTO balances VALUES('2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','PAYTOSCRIPT',1000);
INSERT INTO balances VALUES('2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000);
INSERT INTO balances VALUES('mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','LOCKEDPREV',1000);
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
INSERT INTO blocks VALUES(310114,'24fc2dded4f811eff58b32cda85d90fb5773e81b9267e9a03c359bc730d82283',310114000,NULL,NULL,'3f13d45744d964c45dd30bba4ff7dae5ddc39c57988a2e3d12a456f461fb8f7e','bb9484e007dfd7dbee305e23fecabced6d628cb261f438d927be15573a2921c5','e3efee6303cc177f2527e9d34c94a6bc659b9eb04a502d5fa100d9cc18423136');
INSERT INTO blocks VALUES(310115,'a632d67ff5f832fe9c3c675f855f08a4969c6d78c0211e71b2a24fe04be5656a',310115000,NULL,NULL,'003a310c603c6850ea20f92894c6b8935e5017b1f8ddfa3084de0ed8c62d9be2','a2f7527bf244c7888a45aafa37ddbe5b87ffd20bba0b8e6bd688dcc417e5b6e5','154efe817638ff0c21fcd737478a30011ff09c28ef65641bb79ec76462162d47');
INSERT INTO blocks VALUES(310116,'8495ba36b331473c4f3529681a118a4cc4fa4d51cd9b8dccb1f13e5ef841dd84',310116000,NULL,NULL,'504a556d93589ff253956f950547dd5a035dec9b59202b4d7937fd39ec6db494','51378267268a090c05637900fe04e39b3e07841fa7cc5062903081ddb673bb61','bf5723da794b9cd809f728e82ec007bc4513ed3031091188c7562723fdaf3871');
INSERT INTO blocks VALUES(310117,'978a3eac44917b82d009332797e2b6fe64c7ce313c0f15bfd9b7bb68e4f35a71',310117000,NULL,NULL,'25fe3c08e96ea7831df195f305c5a15b20b95f3665baa264a99124849ec35b13','8e9a1650943ac978e250db84f7f28d48c971ae515e48d68fabcf887df9347e43','d5a6903889640c667689acd1cccfca31bb5e94b4f18acd4e7f28b7b355c8ee8f');
INSERT INTO blocks VALUES(310118,'02487d8bd4dadabd06a44fdeb67616e6830c3556ec10faad40a42416039f4723',310118000,NULL,NULL,'eb400efbcdf181ad8d283c66da17ce153cca30292f6aaae24055d5918b61e484','3f591753fb34b2bda012c83c9450b9f8c35b6de8518608dcead07a95948aac44','55d284294fa1330afa5c93c5d97ff84f56683ca16792ae6d1b22e73b9cf63dbe');
INSERT INTO blocks VALUES(310119,'6d6be3478c874c27f5d354c9375884089511b1aaaa3cc3421759d8e3aaeb5481',310119000,NULL,NULL,'4d74d5dfa8e59f7aa60e98bd018515df8487ecb3949c4533b96360ab2b4ee7ab','0f61b69ccc20387ae1f2582d8d684bd9f8fb6493d50452bafc21053c8212f65e','c3767c9e0fbb7fc706003892d4133c5221975f5ebf1b00d6e006428ddee79ad4');
INSERT INTO blocks VALUES(310120,'2bba7fd459ea76fe54d6d7faf437c31af8253438d5685e803c71484c53887deb',310120000,NULL,NULL,'ceb54e540508a0add1652f47f69f815870ca59ef00a313ab77180373aa3652f0','b2ad9ff7c300e3a6f2df370b6911758a796dc9c578075d62a4b7a5e1850ab71c','7b9e2480cd8a598d122400aded62eac6b5c2993fbb29b467ff3da7f8a806690b');
INSERT INTO blocks VALUES(310121,'9b3ea991d6c2fe58906bdc75ba6a2095dcb7f00cfdd6108ac75c938f93c94ee7',310121000,NULL,NULL,'9e752162f91b97b8c44117467355139377b6363042f5721da8938b69e2be9d42','76259d2c303c07a3704b4619296e784894089483001801bf45ff94cc150fecae','f9e30ebbbb8487f5461da69fbaa593534c54e05cce1628ce2291ffcd39ecc55c');
INSERT INTO blocks VALUES(310122,'d31b927c46e8f9ba2ccfb02f11a72179e08474bdd1b60dd3dcfd2e91a9ea2932',310122000,NULL,NULL,'2b51155aab8762435b5c2c4b9da4dff270b7dfcf1b4604f2e2495bda82e77b58','3a50b9ae82f99c0baa55a3cee0dcfeee4ff10d6d77b54e13e288d5d96c97996f','4b02d237e6d0537454b1145d3846073f3d0ee44cc2fb89b600fed8a882109963');
INSERT INTO blocks VALUES(310123,'be6d35019a923fcef1125a27387d27237755c136f4926c5eddbf150402ea2bbd',310123000,NULL,NULL,'c92a3e316c00a77cc11472c6bbfe1060e407ccb3d6dd11aa9f841e1c06afd681','27b5a65b43323812338ed41b3932c2a0a8463e273cfd25eec2ca98c8114846a4','9923e8cda75ab3d9abab61f9be0571a436013085df1d6b1bb0111e90e95e4264');
INSERT INTO blocks VALUES(310124,'0984b4a908f1a7dac9dcd94da1ee451e367cc6f3216ee8cdee15eae5d0700810',310124000,NULL,NULL,'73d2095a7d05c972030a16c450af5a07c3d272abb4e6e87e882a2659c172e2b9','55b697d98c012fe908888eae93a101c670e81a6757556a0261e4c0d4b9f4b747','37fd688ff212f61eca13b21582c0dd37f6b0124ce7819381093798a4d2630257');
INSERT INTO blocks VALUES(310125,'cc28d39365904b2f91276d09fae040adb1bbbfd4d37d8c329fced276dc52c6a6',310125000,NULL,NULL,'47d5157508fba2b92ef436326b66e8fb0b3d3b3d65e2a690a57432f0adcbbf68','74e5d02540a8b850a0b811906922ed33ace3cfb6de0e850fb353a76aaa02be78','972266363c74ab1623ffaa5f2d9d52b4a64d3e988b4943b31905f84f21eee5ea');
INSERT INTO blocks VALUES(310126,'c9d6c2bd3eeb87f3f1033a13de8255a56445341c920a6a0ee2fb030877106797',310126000,NULL,NULL,'00598320a057110b61720871011b61a7aa20e927e65d4629829d305884a9207a','3a4ba2a05d386c3f1f47930ad9a294eb20bb5602de1c620dfe28c72c00ed0d60','51c3e2f8d51a112969765f4bf1b195cce07393581edf984f332c2aaee730adad');
INSERT INTO blocks VALUES(310127,'c952f369e2b3317725b4b73ba1922b84af881bd59054be94406a5d9bbb106904',310127000,NULL,NULL,'917a2055bc88a29097ab436b98cdc9aa4f71208a9b2e9ece9e050490283b04de','9768e677ecd64f0b0778fb3bf1091c49db12c2083c31c7cf2011378385c3a48e','b2e3bbde017d674ad49da96eb8006eecbdd19bbcb0c0a63711e08b37be60f838');
INSERT INTO blocks VALUES(310128,'990b0d3575caf5909286b9701ece586338067fbd35357fec7d6a54c6a6120079',310128000,NULL,NULL,'8338cf7cda839614378a0a91aff8402db75b346aa0066db5d4d5e496bd86521b','7674405f20cc24f7459d7dd16a9616af0e719627f03a318a4098594db2e2055a','033b71bcddcc112f6b4887407cf29640a859ea4bcd419dc1c60d3ea69712eeab');
INSERT INTO blocks VALUES(310129,'fa8a7d674a9a3e4b40053cf3b819385a71831eec2f119a0f0640c6870ca1dddc',310129000,NULL,NULL,'a2331a207d0828403842d3fcdb60d39cae7dad3119c77f4ec90b68fef4e5e586','a23d4d41168d8cb8b7aafffc5e2807f7137412e4a8fb42a3c4c66efd53166012','1ac3f5c07ebd3c081076d60fdc1d4a5839382622f932db70f85215d9ce2e5547');
INSERT INTO blocks VALUES(310130,'d3046e8e8ab77a67bf0629a3bab0bea4975631d52099d2ddc9c9fa0860522721',310130000,NULL,NULL,'a57c1c71b271dc8e2a08b94a88ceaa18cfcefe323d0dae126bf6732aa708e7a6','c4e1f9f0c476a2b1f599d701b112ca6a15917f9731a0d59accf0fb5e92cd94ba','34da4feed428a1ec9c1e910c7e8348421955696be4244c79c20d223941a11371');
INSERT INTO blocks VALUES(310131,'d6b4357496bc2c42b58a7d1260a3615bfdb86e2ce68cd20914ef3dd3c0cdd34d',310131000,NULL,NULL,'1aad023e1a9d5f3d8d70b1f07e81fa93fa6528ef7a20221646b3a86deb5b51bc','a2774d6c3c0a8ec84792105bd11efbbd1313d2ef250ccab269d2575dafebf457','82d6bc06455985922622708c33bda1b7c2927a3747bfa928cec1985809bb937e');
INSERT INTO blocks VALUES(310132,'1b95a691bf4abf92f0dde901e1152cc5bd87a792d4b42613655e4046a57ab818',310132000,NULL,NULL,'f0ff245c007eb9c30d6a5ccc0c02a1df6a6cc099b741454cb966977db2014aab','236c21334e0c1ad1d90e2212f8f6cf977441153d1d0464ebec061a8a9517f2f8','02b3f28ecf7ee57c27c7d93f8a98cc447463a8cc87d05bcc08ae9611c99d868d');
INSERT INTO blocks VALUES(310133,'1029c14051faabf90641371a82f9e2352eaa3d6b1da66737fcf447568ca4ec51',310133000,NULL,NULL,'ca3690acba5c9dd882304ba87968b56188eda71321aad92fb05279d35e6a5480','02bc90c720e857552844020ec259c1dc1a2c410b1a0672fe6aec128ead0f2c38','8d7b836ce2f69fa0e067662d13295684943137ada70161f3a8b169a6af256c1e');
INSERT INTO blocks VALUES(310134,'1748478069b32162affa59105257d81ef9d78aee27c626e7b24d11beb2831398',310134000,NULL,NULL,'e169c35e4304cec1bc73be9953af300389025bc5d1128ab6893a166de371c1be','0f963d9b3daf3f6c885792208a379f960cd4293bffd1f3af6f50a6821efe55ed','5c6430065aab2a2f5dba6179c28cef87e483dd7555bd6202a7327709d8404799');
INSERT INTO blocks VALUES(310135,'d128d3469b1a5f8fb43e64b40f8a394945d1eb2f19ccbac2603f7044a4097e4f',310135000,NULL,NULL,'0c7f84b8d9d0919429afdb382bd3be932a37d7794016f2310be94359a563eaa2','8d9c27912f5434d1540888179f099186f7e333b5ac73b11e5bbc499bc2cb21cb','cc649699ec3aa156b61dc4c99b3a8bc41ccba9f5cbcd4a47c723c125eeb6565f');
INSERT INTO blocks VALUES(310136,'6ec490aaffe2c222a9d6876a18d1c3d385c742ff4c12d1334613a54042a543a5',310136000,NULL,NULL,'2a01df31bb8e687a20d3e8b1e8e014b9990fac043d5094d68916b8803e379159','48cbcd5022c9c71790ba6c88794e53381222c2492533516337f75f305e5e762f','827d56ff30525662a272b982d4f53bcbd1a91872284f976931b572e22e641fce');
INSERT INTO blocks VALUES(310137,'7b44f07e233498303a57e5350f366b767809f1a3426d57b1b754dc16aba76900',310137000,NULL,NULL,'39859f68840acb9aefd821f364d8cd75892ddfb3c339bddf7755789c21634942','90cf9bf439c99301f2458603d488b7a11abf7d8c96570fd358cf587c3d3b85d8','e0d7bbd1ec7ecde2a08fe17e6286394a2503fab751c5e31822b536ccda45c715');
INSERT INTO blocks VALUES(310138,'d2d658ccbf9baa89c32659e8b6c25b640af4b9b2f28f9d40baae840206402ab5',310138000,NULL,NULL,'8313c4e4e093da659df675f85a4155eb18c789da5dff73798d133f542d243f39','ebab65367088523b4d9600f2a937445d2df7427b388ee656ab0b9601a70473c4','1891fd75e3d68ea09cc3f623380ee1d13fed6368d7a6436d880dc271464bc946');
INSERT INTO blocks VALUES(310139,'b2c6fb61f2ae0b9d75d18fce4c52a53b1d24772b1ad66c51ca51090210527d46',310139000,NULL,NULL,'65f27b807effb595793f7bfb5b768bdef32e24eb31d5bbce9f29d0005855d27f','d2cad8d6852f58eb4d0ada6943d3daed8c46f63a1794c6c4930dcd7916b39d9d','eeeb3f2297e95a3c325928bc810bfd787ef8e0c0bd6ea230ccb59bf599c71b12');
INSERT INTO blocks VALUES(310140,'edddddea90e07a466298219fd7f5a88975f1213289f7c434ed47152af6b68ebb',310140000,NULL,NULL,'eedb0781e9e8f2aaadda09ba303831bc83c67731de3ff73299ab09167b307609','4a5242e00e4f30977bbfa4b282f8bd05a2fd510e6381997c1e92ee5a0c2e2ad2','3d04e3b882216cfa419e8ea0dee1e7d6a1d0feeef6530ebdb7b87a82324faf20');
INSERT INTO blocks VALUES(310141,'b5b71d2a271bd638561c56f4ffbe94d6086debaaa86bfeb02ef0d71339310709',310141000,NULL,NULL,'0c45cb2eb9cdd403b68a4aabd15b47b7698325c655d291efcef9976d87fd96ea','7e11ce0b1c158ffc75ece7a2bb98ba070d7136ec4be246e3ac50480583020a2f','5d3eeaf979a9900694cb62f6803ff75c6529967b05ef69963c235846d04d7ad1');
INSERT INTO blocks VALUES(310142,'a98ae174c41ab8fc575d9c8d53d8e02d8e446b8c6c0d98a20ff234eba082b143',310142000,NULL,NULL,'a6e6da227d652bb17b1bf05ca41f3e20416abd2a7e0106ed90a5fcb076f1f279','f2784d22fe775e7fd36ccbda11bca8fce86650a2fcc016886acdd1c21f07f341','6a6566bd2694368f49e184ce479f13a7ac2f168284413562334bd7fc656a5435');
INSERT INTO blocks VALUES(310143,'8ba2f7feb302a5f9ec3e8c7fc718b02379df4698f6387d00858005b8f01e062f',310143000,NULL,NULL,'b364874446f5314f28b97eec3da41d5c19129aa7d35dbec828e524cc0647cdd1','7aa4585cbcc3783c684ae816e4bab4f07c8f2dec4daabda4333dda65b15b7aa6','9c231e736078cd64980cc1c07d42cc8b3caa348f7e6732dd6b6f5dbe1da8c900');
INSERT INTO blocks VALUES(310144,'879ffa05ae6b24b236591c1f1537909179ed1245a27c5fdadd2218ab2193cdb9',310144000,NULL,NULL,'f5ec130ec024fb1e4f0da1f9b3948f6bd39749525d4c28c48a42baa03a546a01','5c2f52af0e391a1f27ec54be3164bc749624f2b2e4287c34e5287b3258ba4a07','60685a751192cfe546ee45497fac3e6aeeab5b540853cd379e74d04759a2e729');
INSERT INTO blocks VALUES(310145,'175449ef0aa4580593ad4a7d0c5a9b117e1549ea772af00caa4ccdc9b1bf7a6e',310145000,NULL,NULL,'ff49ad1c2c59ed93c9e99784974dd98680bfe1f7e89550e8d2cd0ef8e005df5d','d641a558e74c766f51fd14fb776192f09c64e30f52bce671e559b6c11eb534f1','400e2572901a771d0e25dc69fe12a74a0b5989f44194ce6e881be0d058c79a62');
INSERT INTO blocks VALUES(310146,'e954ab6a110455d745503f7cc8df9d92c1a800fafdd151e7b1912830a9cb7184',310146000,NULL,NULL,'e94b01b53c6e6c7f9b504b0095ab6bb17e3eb60579215d296e46bec829ca87d8','cd2a5ef91b645148ee709057e3cacba944bf6ac07d9f237dd734b8b395acf740','ac9f3cc258dacd23e6768b5bfce3948349d82166510b3a431821befad8159ed1');
INSERT INTO blocks VALUES(310147,'7650c95eba7bf1cad81575ed12f32a8cc36281a6f41bef13afe1dfc1b03a7e83',310147000,NULL,NULL,'a4886dd0063b7644b00bdf5f143c32134dfd9a5b12ae089bf2b4d382cc169e3d','44dd99a441923cb933695377f82df4166dffc3d56f2c28f4ce58c8fdc5d2fa52','cc3cc1ff19e74eb488d7278307d80e587290fb111824a3f3c53d65a58798fcbb');
INSERT INTO blocks VALUES(310148,'77c29785877724be924f965215eb50ffe916e3b6b3a2beaea3e3ae4796545a7e',310148000,NULL,NULL,'1009c6a8e364ca089dd439ca75af3dae8384639e4f2eb728f8b52da70a6758fd','73248f30d94292488ed8529aa4bc5e8996a0293715972e26579720c293ba38f7','9ec2e16f1a083784cedbf7427b11e1786fdc8a96b85c090f6d30bae274fa984a');
INSERT INTO blocks VALUES(310149,'526b3c4a74c2663fc04ed5234c86974bffddb7235c8736d76860778c30207b3c',310149000,NULL,NULL,'f82d9992361cadf0a4dcf1acee9e304128ec82f2a4c7044ee7a8323d55ca88f3','4dcffaad0ebb4a177b502bdd98e122b8a506edbfec4a973cc441439c5c024582','bab1f2a01cff2933bf2bc362f06ddb8d4e9df1e7acbc48036bb011d7053ebfb9');
INSERT INTO blocks VALUES(310150,'cdd141f7463967dbeb78bf69dc1cd8e12489f58c4ea0a5dc9c5c01ec4fcea333',310150000,NULL,NULL,'2ffb8f3837ed4217bbb30503d44c79c2135dd0965257d63d89c88e1b4cdf3cfb','50c2252994688df7a523be7827cd8156c17b0f3c2681ee01bd73b21cc80f0699','5b62894fb9b8a6429507bd1e81a5d0afedbb0ea98e4d9f20fc79cd3c64247294');
INSERT INTO blocks VALUES(310151,'a0f31cc6e12ec86e65e999e806ab3bfa18f4f1084e4aeb4fbd699b4fe284b330',310151000,NULL,NULL,'34e5b7feddf0fda711e0ce2e200bc991f242df573ca483bcc6358c99d7a66bc1','69f0becc05d00186fdcac72199f4c0ee3fc1c0110e367899708fea8c808a8c50','0ff52c214a54051c8915d0db2bb2219230b120348171c319d992489444b75b50');
INSERT INTO blocks VALUES(310152,'89c8cc3a0938c63a35e89d039aa84318a0fc4e13afac6beb849ac37140132c67',310152000,NULL,NULL,'7621df548acbb56da32176e78e11c47a2fbb9cab7d61eb231305c46df60162fd','b6241c0a536f2b31f01bf66dc800d36b311bfb3d5669e4031cf39ce9c3f969e0','ff6233d197e242dd340e138e2ce7bc250c965c5ea577d86611c9e980c1ee19d9');
INSERT INTO blocks VALUES(310153,'d1121dfa68f4a1de4f97c123d2d2a41a102971a44b34927a78cd539ad8dca482',310153000,NULL,NULL,'57800f738a686ccdbd665a163231d7f9f6bacecd8ecb6185c7e24cb914df89f0','2560326f4fe0baf7fdfd391d39440def0cadf4adb746fd85a9bf2de3dcb8aab6','89d0de650d381406bbf19e8731c97fa51957139d15633bb57b19da15de75d961');
INSERT INTO blocks VALUES(310154,'ba982ea2e99d3bc5f574897c85485f89430ae38cf4ab49b7716ed466afa506d6',310154000,NULL,NULL,'af9fba7e85b518c034828eb01b3d5bc4efb64baa2b224d232b8b251b30cdc0c4','2596e2abd48b6ea46858d4818702463a9c9ed10bea54ad6f6672a94130492a1e','042fac8859f8fe1534b83e2f51a87f21db156873108c38b17cac1752d6a0dbd9');
INSERT INTO blocks VALUES(310155,'cefb3b87c7b75a0eb8f062a0cde8e1073774ae035d176e9769fc87071c12d137',310155000,NULL,NULL,'b8ae81163ca3e00903a12edf9c563a06bb2b32a76566266ebecea73a5fce1c2c','a8ee6fba94acaf0eb309962fc5cd46f95706ae4ba83f45602740a93927d99ed6','2f661cd3ab02d9c76223872949e2bbafba15c718ca8dcfa9e5f21c5a91934ccb');
INSERT INTO blocks VALUES(310156,'6e3811e65cb02434f9fde0445a7a2b03fe796041458737d0afcc52208f988a83',310156000,NULL,NULL,'4928192c18507a12bef3736a2e86fd4d344a58727c1438df540ad7f501ea718f','b9c9b2bffc18e5532e655783bf6b25ad658fdd623b0eb1fe7abd7daf13d88393','06f0721653646ec365ce9da54926195d9365b5e424c6cbf98cd9208fe7625b27');
INSERT INTO blocks VALUES(310157,'51dd192502fe797c55287b04c403cc63c087020a01c974a565dd4038db82f94a',310157000,NULL,NULL,'ca5422b7c92e9adc13c0e5f8cd0ffcfde8a1cfac49b629a0159dae5841eb9e0f','993dd6359af8b304a69d5f2fc750127574ad014d2222dcb5fcb1974fab3a67b7','bce705d0f0bf11b5dc75846cec8557731307e259f64bd505d856e43e070e7a3f');
INSERT INTO blocks VALUES(310158,'749395af0c3221b8652d31b4c4410c19b10404d941c7e78d765b865f853559d2',310158000,NULL,NULL,'ec6759098f1071b7c8ada2c4564ebcea385fb4ca398763d3460a5edf4ceeadcc','2162efb696bcc7bbc8f388d703583d83cd99ae6b73f36ad88a9939101904a395','607cd4629f0410714f754532afb26e0101e172a05f16b492dea5af158d8bb072');
INSERT INTO blocks VALUES(310159,'fc0e9f7b6ae99080bc41625588cef73b59c8a9f7a21d7f9f1bf96192ba631c12',310159000,NULL,NULL,'3e518dc4a7f705a7fd2b68fe8b8cd58a43c421c09ba4b26ffb96f78f60871932','1e75f23275aab6fa6f5502efaf94e983807156006aaa181baa6679529f6c045a','97c41fb42a89a1e9d3eeffee0aeef1462e0a3a7a71247b3fbfe243d2e0c6e920');
INSERT INTO blocks VALUES(310160,'163a82beeba44b4cb83a31764047880455a94a03e859dc050da782ed89c5fa8b',310160000,NULL,NULL,'53f73e8774bcb1b2b6e709fbad8a819aac97f2871e70fb7f1b4fd87fd67a93ad','1264d2922e5673ec1645777fc52c68b0b068648b3e7a1a5aa9330054dcf539fd','f9f6593312018e5ce3aaeaec2e197d12b3efc26135aea9cec21910ecba2fdbe6');
INSERT INTO blocks VALUES(310161,'609c983d412a23c693e666abdea3f672e256674bf9ee55df89b5d9777c9264d8',310161000,NULL,NULL,'b992ef648e97ec4f1ba3e398938a3ec63f6befd5f7245e54b037738e06aa257f','2d7e64864e5d7d7008c465dd24f2a4f4a99b0ace7a40cb49660328cea870824b','df2ab27585d30cfb1f300099702d0a700d2903a2ba60fd7fcdabcef347ecf416');
INSERT INTO blocks VALUES(310162,'043e9645e019f0b6a019d54c5fef5eebee8ce2da1273a21283c517da126fc804',310162000,NULL,NULL,'e6fe77738a337044da1cd841bf5a4b6eec217b88db179968ca6b963023d67a90','17bbf4cacb3a097296932f9601c2f32caf3615f7eb2178da884d3e76080cfd44','86dfcd72afd53bb5ffec71ab36fa1ccbf20336a89182c3b843fcbb0f9518c9f6');
INSERT INTO blocks VALUES(310163,'959e0a858a81922d2edf84d1fbb49d7c7e897a8f49f70bd5b066744b77836353',310163000,NULL,NULL,'38b9183eb9778715377818872c7c23aa21c3d29fde02edad3dc998b2b0651806','4ecb94a3130b54307a6f95c7b0dea734a7977337f4d21be3fe2be6a59d8eb5b9','8598b3927c78060aefee8e15ad7efd65acc08e754d6ca77bf29cb64e81784bf8');
INSERT INTO blocks VALUES(310164,'781b7188be61c98d864d75954cf412b2a181364cc1046de45266ccc8cdb730e2',310164000,NULL,NULL,'ddfe4cb98919dd5e4286c8e45f7700dc2d76294b385747e9a0560f3028597b53','8e2790f3ea45802fa567eda38eb0da50b65cbd68798fc2838107b8c40c6bc9de','787c863f2306def9481c184e80a28e16b0cf56aa0786a8b1ec0be78a85aebb0b');
INSERT INTO blocks VALUES(310165,'a75081e4143fa95d4aa29618fea17fc3fabd85e84059cc45c96a73473fc32599',310165000,NULL,NULL,'cc007e261908328d4826c224d18a929664785a0ef05deaeeac969f15ef00363f','86193ed01f31aae8095b1ceabba306e31aa58891ef1172843dfddca84ba66c74','52b16855cafda70f0ef73e2bb99106f2bc3f5092d4264feb8884292281e1c152');
INSERT INTO blocks VALUES(310166,'a440d426adaa83fa9bb7e3d4a04b4fa06e896fc2813f5966941f1ad1f28cfb41',310166000,NULL,NULL,'65d95d78e13ac388dc1120019192fdbe7dc72e1a159e03c7995d76ff5ba27b20','363e9ae5c328ccf59aedf69a2fc5cb277a9956db140878d583ab28d879788011','1a1e240cb1ec7e498473f05f6f02d62e4fc6ce5e3d2ebfcd675e75d353421a1b');
INSERT INTO blocks VALUES(310167,'ab4293dbea81fedacca1a0d5230fe85a230afc9490d895aa6963acc216125f66',310167000,NULL,NULL,'807aea646d80619def575012572b23d8582aaf750dda8f21bdbfed825d51205b','05ca880442d6a93f31fe6c743fc8a856fcf81c2399a193c3179d2459f9614372','08472a013d4f5f43cde7469d906ff001add294fc27474838d661046e084637e6');
INSERT INTO blocks VALUES(310168,'a12b36a88c2b0ed41f1419a29cc118fae4ecd2f70003de77848bf4a9b2b72dc9',310168000,NULL,NULL,'164ced2cc32e2088096984cc3c96c6591fb2b06c1e656ab8c2c72fe27ddbd19b','5ce7f123a043a9a7ccea022f18b6c40b125cb54737e9b440de29ad43cf0c6b58','1e86b34ebf2d2564edf88cfbeb4c5587892729210ce4d28e57d958a607a6a4cb');
INSERT INTO blocks VALUES(310169,'204809a85ead8ba63f981fc1db8ae95afe92015f003eaebbec166021867421f3',310169000,NULL,NULL,'4ba0ce510b611f594bb0f081e112a572bbb62725ba08421c9edfcf434827ca8f','c323ee4e93a474dde41fdc8a5364d556646ec5b51c21d5ec67c4cc15905adf2a','7e4b03eacaffdc3fe002ed0662f1493311b537fd6c55a2ff85a480563e72fff8');
INSERT INTO blocks VALUES(310170,'b38b0345a20a367dfe854e455e5752f63ac2d9be8de33eab264a29e87f94d119',310170000,NULL,NULL,'2588810e6cb4b8bd2fa5308237e60ee1aa4f16e41792da492c896856189142a7','d6e54f2b5e13d9784c5fbf93ea6e2c01e41ac350ba30f900079cb1b6af9ddf8a','e6a4a69a552f4fc9e1fc1584066545acf14249801348127abf7543b9b1a8c567');
INSERT INTO blocks VALUES(310171,'b8ba5ae8d97900ce37dd451e8c6d8b3a0e2664bb1c103bf697355bf3b1de2d2d',310171000,NULL,NULL,'696594ce97c0a04167858eb2edec56e3c516d4b6b4916213b065765749022d87','8e498bea4b8018291202790ae837796cbb9db066634cc43ecb8b242f9eba1570','6ae78dfcc4ea2127a06116c9d1a6bf0fdbd477ecedc6e978dd14ad9d51ddddfd');
INSERT INTO blocks VALUES(310172,'b17fda199c609ab4cc2d85194dd53fa51ba960212f3964a9d2fe2cfe0bb57055',310172000,NULL,NULL,'1400101cf98eeb8737d008e8988f529f83fa06f8ca01b190ecd6fa5b47c66f23','6d6d52ecb0bf41134a9a266de10d48238cbfd663a8b954140785aa2693954b44','0d166f29ec9b064d255bf32e86c2638aa32c89146b5057a2f86632fc201f13aa');
INSERT INTO blocks VALUES(310173,'f2dcdc5ffc0aca2e71e6e0466391b388870229398a1f3c57dec646b806a65016',310173000,NULL,NULL,'f106047eae305202a8d01b45ce9c45f2bd18b10e1a36339f0007a48f4e29272c','ca1317980819327eb89364fff7dbe513d10f5448e17258bb154265c77a9679cf','fec0728a16139850cca4b62489f057c5574661952d2cc8e4e79eef6d7c48146e');
INSERT INTO blocks VALUES(310174,'fa6f46af9e3664353a473f6fffce56fa295e07985018bface8141b4bf7924679',310174000,NULL,NULL,'ad0f900a63fcad3986c815b17adef6042f68bc91f0c33ab8eba7a53613323ce9','6707f7105e6f91ebdcb3aaacdaab0caed40a813a54241956be72f7fd78f538fd','d2f43018b7b41470c4f4b1615acafbce9cd83ced2d3dc8a2e28be11dc5926534');
INSERT INTO blocks VALUES(310175,'f71e79fe5f03c3bc7f1360febc5d8f79fc2768ce0ff1872cf27a829b49017333',310175000,NULL,NULL,'65788c4f629fc0965b18a40b10a1ebf53d9136fb47f2c8464b389dd353f4309f','67d62de7e308982d20fd54ae4c580aa8f139b78fba203055e4bc940c7412205d','7041b6c167fe3bfc4e606d8d98ebd5c28683a001a13791f4ca483b7efba2c68e');
INSERT INTO blocks VALUES(310176,'67cd1d81f2998f615602346065e37f9ceb8916abb74b5762ead317d5e26453c6',310176000,NULL,NULL,'15a08a1c618f230830c72d0dbed192becefaf3585cebb5062a6b4b205ee2b481','c7d030c8f323f345416b7af6f258b8f7aea52898cc5ed3a982ae0e749e6b0d34','d138ad788322be6b7a76bf46257f901217d800f1db0c58bc9dbd9e324e3ec225');
INSERT INTO blocks VALUES(310177,'6856b1971121b91c907aaf7aed286648a6074f0bd1f66bd55da2b03116192a52',310177000,NULL,NULL,'0b0512fdc30745107fdc9091f2e7ee210a2f2b17585b568a0773392815dd5d81','c54f2cd62ce4b82512e2c2d7732a1ca65c5467c9d7c154ec804b4333dcaae461','8552474fb9d49f43a6d7482aa17f7bfdacbda93758adde6807e572f7f43eed9a');
INSERT INTO blocks VALUES(310178,'8094fdc6e549c4fab18c62e4a9be5583990c4167721a7e72f46eaf1e4e04d816',310178000,NULL,NULL,'c818d47767ded6a5feea6f3d1cdf7032233c9c6512f953d9a1d41adc6c0590af','e9c35ea6b7f37dd77e4c94cad58df952de61946ce0aacec654ed83f04c04328c','c17940faf911655e99d1a0984e51e518eda743bf5610d9e5c2c701e65a12ceb5');
INSERT INTO blocks VALUES(310179,'d1528027cd25a1530cdc32c4eaff3751a851c947ddc748d99a7d3026a5e581a7',310179000,NULL,NULL,'4a529193d4958118d8c0abf29977270b35bfd4eac407117b803e7b5b1a7f00f0','399e8fe62b7afc0bb6afd83b65e17b25e2ec4deb3e82199b884f2da6d16219d6','f4db51cc6809715971c7c0b042f846853ecedc900be9c1ea41a1afb7e0b5a36a');
INSERT INTO blocks VALUES(310180,'f2f401a5e3141a8387aaf9799e8fef92eb0fc68370dae1e27622893406d685c1',310180000,NULL,NULL,'c71712403f0dd36fe6c10a3dd8c3c28467edfcb64e551da9538bd3656154a94f','9b1e6a82df6776ed8768da0b7d70dcecab7983c69631d37750dc83d102ec645b','5f265a92cb1bf8666eacc6ae0b1b4280e4a9808a0e5a65237206c229fe2dfb3e');
INSERT INTO blocks VALUES(310181,'bd59318cdba0e511487d1e4e093b146b0f362c875d35ab5251592b3d9fed7145',310181000,NULL,NULL,'e36977719eeb9fc58519f42e9a7ca449441a51b5c9990095526541a762955611','230d582cdb8a5ed3173e44e800b7f65b98dd9d43532aeace87416f688697d292','27ee67cb284fd1e0517dd7d44a8e9138cdc1de0aa10b58e736299989b6bef3c4');
INSERT INTO blocks VALUES(310182,'a7e66b4671a11af2743889a10b19d4af09ec873e2b8eb36949d710d22e1d768f',310182000,NULL,NULL,'6531d74e8253356bf111c9abdf77b8360707cf0644c67b103269bc9c0c5a2ce2','22777f29a12ff97efe5025bf864132e3aa7dd25429d84073f5541dc33b8f169c','d1f99760fcaf13641d663f04929ad1b4a6d4c364a21dcf89df2fcf87bf420d33');
INSERT INTO blocks VALUES(310183,'85318afb50dc77cf9edfef4d6192f7203415e93be43f19b15ca53e170b0477bb',310183000,NULL,NULL,'1a167bce0f2c0ed2836438e076b40e35ce28bf8db3d80d14c0e77a8e2774791d','90cf0d78dd91e85963ebb95aae4fb3e36c7250d6920746bd2a1f99e50e95d808','5584f83b74d5eba10d2cd0468a1a4b5f8c134bf5dde2440389df4f2e1b939bc4');
INSERT INTO blocks VALUES(310184,'042a898e29c2ebf0fdbb4156d29d9ba1a5935e7ed707928cb21824c76dd53bfc',310184000,NULL,NULL,'404c415b5cb67fb13db373ae728b262519289be719ff092f5d3cc9baddbb99e1','f39a1a5cb12633d51229b49d651866ddc1c7fec64f8e8486ebe2063daad7d68f','e51e75e6c113d851db5626e80933b446ed43dc78f2def3cd436938799a34e879');
INSERT INTO blocks VALUES(310185,'bd78c092ae353c78798482830c007aac1be07e9bc8e52855f620a3d48f46811f',310185000,NULL,NULL,'0331e9514ba7a61ec212710209323c202bd2bca9aa7e700676a20cb228d379c5','2d1ea52693ef11f628cacca08975946070d011eef4b53387d0a2fefca989541a','1830388ce95f9d3aded3fe30835ae2b1c3e6ddcb3ad45f94a39366b848548b26');
INSERT INTO blocks VALUES(310186,'e30a3a92cc2e5ad0133e5cee1f789a1a28bea620974f9ab8fa663da53e5bf707',310186000,NULL,NULL,'360756b39282b6196f57004e18ce4c91ecd42b04ae73c140d3e4c7b02c7258f3','ce93dda0a6507226b6e3db6197619d8257c6b1c0bba90f952f42a0772cf09f8c','4b58d4a9d2ccb6c7904d9c946f88dec34a5e5ad17b67af824d209fa9cc4951cd');
INSERT INTO blocks VALUES(310187,'fc6402c86b66b6e953d23ed33d149faa0988fa90aa9f7434e2863e33da2f3414',310187000,NULL,NULL,'f5a63fadab02c25c5304430dd596f6c0aa8985fb94cd5ea3b84de91ac8cd5056','9868ec125c720a90c37911b36eaf014b42e63ab40b4a13d4a061e8a7015d1001','e56c991ba931867beb11e62c987ad0c7bc6ef61f5dccabcafbda69e5cc00fa82');
INSERT INTO blocks VALUES(310188,'85694a80e534a53d921b5d2c6b789b747aa73bf5556b91eeed2df148e2ada917',310188000,NULL,NULL,'bb822dfd0e5f422a4867ffaf3883451350d26b84ca6d88170f15cbaba2a4a49d','ced6c04daa2423cc0fd226d4ffbf770b19d32f987fc968475d9aa6159bfdb1f9','0e07c2a8dd4c5c7d14006b9c439c85cf54b8f9e1557820ab061467c694a0521c');
INSERT INTO blocks VALUES(310189,'7c036dadf19348348edbe0abe84861f03370415ed2fec991b9374dbb0ca19a06',310189000,NULL,NULL,'ab461fcabf083b8824565783687c05abe7fc952058f23b8cccc0b5c97d87d185','269fb2aa96d3af631902b3229e6fbdfce766d5107c8d293689f81b5ab345a341','2abed66933f6bda93f171db2deacccae67542faa4b9c99ff40e1cefaf348bf9f');
INSERT INTO blocks VALUES(310190,'d6ef65299fb9dfc165284015ff2b23804ffef0b5c8baf6e5fa631211a2edbd8d',310190000,NULL,NULL,'5e9113555f0343836ab84db97e1113e05e2cba347295cf83e5c3d555d6d97777','c70b1e3a86184a815c5893d97d4ebadb9e070402c4185d8f88232a0632d294df','2dff6daa6496f13c628e3d7b521464298ca077c946e0f58379d0ba68a5953043');
INSERT INTO blocks VALUES(310191,'5987ffecb8d4a70887a7ce2b7acb9a326f176cca3ccf270f6040219590329139',310191000,NULL,NULL,'f38edd56f48ffb97eb0552cf88fef2e73b57ae928b50693d878a8c14cc619052','83b09ed2b4c1980fa7759a46617b763829cb2561801e2b45498546e2ae5d35b1','fac2bc8ec18cf6595a47fcd60c9f098d2972fffe9265874d70901565c614b437');
INSERT INTO blocks VALUES(310192,'31b7be43784f8cc2ce7bc982d29a48ff93ef95ba18f82380881c901c50cd0caa',310192000,NULL,NULL,'5f27daa824e5cd7daff71ff5a0728f377d9d0dd12889c72f1d2269b3e2aaf108','9f579fc609353fa5196fd9846b0b60c9c40f23ae7e6b5344f0d34d7b4aaf84df','be8d944ba2a2fffd3d5e12b1a6774f5061efde58e07947197e946ccc7a9677ad');
INSERT INTO blocks VALUES(310193,'ff3bb9c107f3a6e138440dee2d60c65e342dfbf216e1872c7cdb45f2a4d8852a',310193000,NULL,NULL,'c785ceb24c561b04ae553a14baba70c76a0e4e77321e699567017f0585605e44','81b227e0f4053f06c80fda92b0fbafd69f0d0f23411442e8159a10b3cd4d58b5','bbb214428dbdb8a70d66a4bfa59fb5eb05f39509842a7745187b805af8fd3853');
INSERT INTO blocks VALUES(310194,'d1d8f8c242a06005f59d3c4f85983f1fa5d5edcc65eb48e7b75ed7165558434a',310194000,NULL,NULL,'5c048187731533856de6f4b976ca5ebc9a6e8f3bda12dd3978ca38cde889b581','fd4300c99277aaeb21804fadf86eb110835e53c95fd1846e8989084bceb34a52','a0ef9ada8691e9a60ac856fe3c4673a92afdf44da75d7ad208a6b4368e9f82df');
INSERT INTO blocks VALUES(310195,'0b2f1f57c9a7546faac835cbe43243473fa6533b6e4d8bf8d13b8e3c710faf53',310195000,NULL,NULL,'30a90c97ef3d35ff603ae8f2bcb6b9ac65d0e538d468160dbe10cecde2619088','02a9eb6d83c0b171f9d4021bc2cf24dbb642b9ae58b2c1e0b30ade1ab921d9aa','d24cab8c04878b4df9a0d1be6b131f8eea3d7aa1c6eefae96f22cbfeda67a6b5');
INSERT INTO blocks VALUES(310196,'280e7f4c9d1457e116b27f6fc2b806d3787002fe285826e468e07f4a0e3bd2e6',310196000,NULL,NULL,'2a82a903487e2336f5fb150eb10d21c9387d71083845e73ef08083cf8f5364d5','bcf3140114644227bdeb8ca81cfb641cb6bd5e6c036abf9adaea4df1c559fe22','d57fde7844d967424511c88425ceeb7977860e1e414eac5e349255e5ed8086e5');
INSERT INTO blocks VALUES(310197,'68de4c7fd020395a407ef59ea267412bbd2f19b0a654f09c0dafbc7c9ada4467',310197000,NULL,NULL,'607946360d60bf0456f8634dc32b82adc075a8aff5db846f3eda28d5533b917a','9dedc7716c12437840b38215e5b52a5b1f8f73ffd1ec9b344416e754a68c49c9','5eb3a3943bb872b6dd3641fddb9d5f9b143bc929971087ffb87d85d74cc914f8');
INSERT INTO blocks VALUES(310198,'30340d4b655879e82543773117d72017a546630ceac29f591d514f37dd5b1cc2',310198000,NULL,NULL,'2005b570cea6d4e9b30520d7607798b1e29f3b1d21b131d8724da343b381042c','5a4b73a578c195f2122cf89ee784c9f702ecbe9952305f33bae7aafdc4c2f4ee','aadce95c4604ba2a3fd658914cd30a13624206f8750362adc2c055a851806407');
INSERT INTO blocks VALUES(310199,'494ebe4ce57d53dc0f51e1281f7e335c7315a6a064e982c3852b7179052a4613',310199000,NULL,NULL,'9d7e0785b71e9afc7e7a8dd14f4cf2a1130e15e6f4bbebae09a2ab5ad4e00848','0c121c5261df651b397a4abf7c1b860480dd71d48cafb4dce4ec8ee8e13723d3','52e639f20fddc7ecfba9197a86254caf1d97e87aa6f998079f9a8ef764b9758d');
INSERT INTO blocks VALUES(310200,'d5169d7b23c44e02a5322e91039ccc7959b558608cf164328cd63dbaf9c81a03',310200000,NULL,NULL,'42774f29a47912b7dbe20d70f88c74826f40ed582a917a269dcfc733dfe10383','be26998e428eb48225920282004c5076e322c145c82d444ccbdbb36896050d79','4afc30cf66f88bd1b7b9b012d1638905ed938a252469e07256e7732d4614895c');
INSERT INTO blocks VALUES(310201,'8842bf23ded504bb28765128c0097e1de47d135f01c5cf47680b3bcf5720ad95',310201000,NULL,NULL,'45e70a1e8f8308056b9108d6d0cb640e0855b4b2de6ca1d41a56bd959c437ab6','816b7dead72a0a40d8a59843baec87b0ce2127dcf07a2460c2aee21d127d865f','3693c962a4f22a6238b84fcaae7f32df455578c3606cbb38e7647f181fc592e8');
INSERT INTO blocks VALUES(310202,'95fa18eecbc0905377a70b3ccd48636528d5131ccfa0126ed4639bc60d0003d8',310202000,NULL,NULL,'c0c4e5aa212718be88555ebf65902565a3618cbb0e55de70e7f8af0c8bd26b2f','cc81a00526f0f7d8f0e55ce3b32ea46624440e2501f1ef875fbd5d738070f6d7','7417dbad6769d13884d500e2dc6ad9dd901778f94ec033053ce7b748c89cdf9d');
INSERT INTO blocks VALUES(310203,'ab15c43e5ac0b9d4bd7da5a14b8030b55b83d5d1855d9174364adbebf42432f8',310203000,NULL,NULL,'009f4d5df046865ded147894ddbb47b2fe9670885f9cae92a734522313f4e649','8e57fc38e52afe7e91e0f4c7e401670c931407ea186ab22287cff4cec53a062a','d0359758445206f0c530fa59b3420f1684b20c683aedbe167ff975d975e6b927');
INSERT INTO blocks VALUES(310204,'18996fb47d68e7f4ae140dc1eb80df3e5aba513a344a949fd7c3b4f7cd4d64cb',310204000,NULL,NULL,'6ab50d6c9b1220f8100bb3cbc285eccc6414fe72b5af88079b6d1a0d9c143b01','0273d67333ec0becb3fc4d9967559265b90dc725cda9f066c134702540f07249','82e8038710190ffac073aa9172a003626e9714c0b080e1f6312770c070c6dafe');
INSERT INTO blocks VALUES(310205,'5363526ff34a35e018d1a18544ad865352a9abf4c801c50aa55742e71630c13a',310205000,NULL,NULL,'e88709d143fc7e3eb50d381a558e5c072224727b39836aa2de40429460dfbf06','3174b1ef143d484f81b17789b75011aa28d6130abeb4faee8e0439eac2ed1b72','6c5081566a25c838f34e4f473703f895b3bcf4f702a0bf151c76e414a4038ef8');
INSERT INTO blocks VALUES(310206,'0615d9fca5bdf694dca2b255fb9e9256f316aa6b8a9fc700aa63e769189b0518',310206000,NULL,NULL,'ad6737655915dc2f9b11a69bf4e351ff7712954d0167c590b516101521e6e507','83da4055db3084dd6593459d7f4af9909438352b530168fc2255e8ac90113071','45b50194ad553ce53aabf32aa404db4236671aef8f9243b5cd9dc06519256872');
INSERT INTO blocks VALUES(310207,'533b4ece95c58d080f958b3982cbd4d964e95f789d0beffe4dd3c67c50f62585',310207000,NULL,NULL,'d0077ccecdd051962f7a517b3e3f9c2052fb4f89b0fc21716f7f7e9e6934afad','e61aba832b1168cde305ce61e62bcf31721d44503c20bb3937fb4c610a80082b','09cd258f22ce34bfddd4e1321b70ab806c1125f0778380df30ed9a3665757632');
INSERT INTO blocks VALUES(310208,'26c1535b00852aec245bac47ad0167b3fa76f6e661fc96534b1c5e7fdc752f44',310208000,NULL,NULL,'931bc64d18ae09f966052d13a39b1efdae4a89db15b3088e4b30298d84a67f5e','0ed1e2a9a0016d901f2ebd03d45f380d1796f92795eba864f4c5003f363b888a','67f5d2ef75bb52d8671626cc778db96295842d54b8643a90db767e2fbe55f1d7');
INSERT INTO blocks VALUES(310209,'23827b94762c64225d218fa3070a3ea1efce392e3a47a1663d894b8ff8a429bf',310209000,NULL,NULL,'c7f5d305c426fc30e6996997badd05f707d01c3414f4147030c2696162e60124','996f912c35362229d6e65d7722889f7d61e14a53b7c3109bc319a4a2f68fd882','61b7eac27e64e4945935e8de3338d8a9b1bcbf2d3b0310c3c7536ccc0c73369d');
INSERT INTO blocks VALUES(310210,'70b24078df58ecc8f7370b73229d39e52bbadcf539814deccb98948ebd86ccc0',310210000,NULL,NULL,'ee0631d18a605578f56eaea5bf9c20f64be3e5156bfaf9b9363c96c6c75e6cec','9f46aa40f16807b909cb7d2bdc313bca6f9736c937a6de32985ceeaeb86c1bb9','f668ac2a9c7b1e7368a6f6cd5460663da49fd2d82414c46e7d3b68ab833d5d51');
INSERT INTO blocks VALUES(310211,'4acb44225e022e23c7fdea483db5b1f2e04069431a29c682604fe97d270c926d',310211000,NULL,NULL,'f90320e4148aff426f9c8cd19e87bf8159182cdd49c5af9e900f8ce2a2f58b11','db59777bfb7f3ee4d358565c7bac14a19593a36cbafce11f5addd6002b37de4d','7d3fcaf513281d1996888f15e8ad28ae66673969c953047b949fbc41ebc99c58');
INSERT INTO blocks VALUES(310212,'6ef5229ec6ea926e99bf4467b0ed49d444eedb652cc792d2b8968b1e9f3b0547',310212000,NULL,NULL,'81975507951171caaa717fe97add9f552ab08f0abb5ea4f1609df5da7b24555a','d126a4a109f532d44beaacf350991942cc923bc34baa431c30f22edf3c677cc3','0ff520b6ae8a57f4299f1ad0115dde8c784ecbbef4001011c86ec6178426abc9');
INSERT INTO blocks VALUES(310213,'17673a8aeff01a8cdc80528df2bd87cdd4a748fcb36d44f3a6d221a6cbddcbe7',310213000,NULL,NULL,'83a8322e6eccee50bcee5925fb9f82bbd82ab0fedee5c3d84dbb329021128c00','e90b4f3ff04f6875cd80582b36393a42276ef33661874447265a3797951d6262','4a6f9fddc6acbb36635f9f6a79c817bf69e5301534acd0e6fc582406d4b47660');
INSERT INTO blocks VALUES(310214,'4393b639990f6f7cd47b56da62c3470dcbb31ef37094b76f53829fc12d313454',310214000,NULL,NULL,'68891d1166a932ebab8184e6601a7de8f71d9ff574f182f56c799b71c345bf77','7762b4f7fc94a7bf61c55ab3f9a8b70c3ee1263aadad29a245be3636a028a89d','af6b8b61be01f0e8890d5f0071e04357356a42cb469cc7788542e2b59c6f8155');
INSERT INTO blocks VALUES(310215,'c26253deaf7e8df5d62b158ea4290fc9e92a4a689dadc36915650679743a74c7',310215000,NULL,NULL,'22f2a8bb5718b0cec91c2cdcdc1e5a66cfd94f4f3cdd3d8a39a16c1355d70186','de1c8e8229bb11334843980933f9431e4d2fceb6841b6b26c6178955c1e0ac3c','b28f4fe66b3958aa6cf32e30adf6b49db679d7331e1de7e4e679fdb427ed040c');
INSERT INTO blocks VALUES(310216,'6b77673d16911635a36fe55575d26d58cda818916ef008415fa58076eb15b524',310216000,NULL,NULL,'1dc2a584fc889bd242c8da62b59d4ae0a899ddeb707a4db8a7f8a8e51876a52e','e8334999dff2274be721d07e9b3ff74051d478382350ec469b624f86504783ed','38366eb5751e0c7b48da4a16de992b0e29dc2d3c818fb4a4ad03ed12d5f59166');
INSERT INTO blocks VALUES(310217,'0e09244f49225d1115a2a0382365b5728adbf04f997067ea17df89e84f9c13a8',310217000,NULL,NULL,'7249e3e878f6d9facb291cb86e5f9d55d20c82037a0a320c4444ca38a35abcf2','d5ff8a8fc883b49a8cc25d5942f0ddb758eb228f3b4504652cd6fe2c4bf3cc75','74fa00d2f039e348bfeca67d484fd8fc79a2faa020db8b3dfa6bf06bd3ec4ff6');
INSERT INTO blocks VALUES(310218,'3eb26381d8c93399926bb83c146847bfe0b69024220cb145fe6601f6dda957d9',310218000,NULL,NULL,'1068af475e231ddff4d5f8b71ce34e8c2ff89b11faefa1dced99d258dca38de3','2ac3e9b60ba7fe96e78690c70c99aa80d78f19acdbc43cee08647aff18e5e13c','560316d69c5aeaa235d5bc30275dd4b0e5e0c8ec405fe55eca8eeadf910b994d');
INSERT INTO blocks VALUES(310219,'60da40e38967aadf08696641d44ee5372586b884929974e1cbd5c347dc5befbf',310219000,NULL,NULL,'6dda3c0abda1530b0e177a758810a71d9413e4a174dec017138bbc8b67bea8fa','fbaaa4edf6087fc3012d9e4a31f692067b7051c6de1320ea13ea00b9c67df5ed','a487b4edb76fdcd1ac84dea1bc9c83542bbf5c35efcff25d57769a79b63f11b1');
INSERT INTO blocks VALUES(310220,'d78c428ac4d622ab4b4554aa87aeee013d58f428422b35b0ba0f736d491392ef',310220000,NULL,NULL,'0ba1a8c77f94bfdb2befec0b9f4e18d354832512a330ff79abfee3511a9cafab','9e6c6b84d57e45b186fb560e02c2868d6a5ed7798559a6776532827867050ddc','cbc09339a5bc22a22c45b0b160955bf6d7899a3c2a1083f06cd0c7b997d7832d');
INSERT INTO blocks VALUES(310221,'cf5263e382afd268e6059b28dc5862285632efe8d36ba218930765e633d48f2d',310221000,NULL,NULL,'f7bf67dc71b093354cb302f908de4cb1752848ab4eaa8906f1f502af3250be6f','095ace7cc997a0b3734f4317ae2b4b26232c3a2234d5d9fb70f3c36bc8974a52','be96106f87e2b0ce071f93b398b4bedbb9e7aa50fec59c19407fca94ce7c3eba');
INSERT INTO blocks VALUES(310222,'1519f6ec801bf490282065f5299d631be6553af4b0883df344e7f7e5f49c4993',310222000,NULL,NULL,'f0962fb3e47cf41c9b5a58feecc8d1fff19d5c3f6fdfeb7d8ec4e6e25bccba81','8b832ceaf16802ad51892caec97d08305e2b117a6edf79f579d0929003284ff8','ffb4c3d1e0b0e70c47e16bf81a54a9d4bd6a475d1901921ed99d9c62b3b21abc');
INSERT INTO blocks VALUES(310223,'af208e2029fa49c19aa4770e582e32e0802d0baac463b00393a7a668fa2ea047',310223000,NULL,NULL,'13ef65d8048c1ad8395518768d5e39afec9b5e1d16faa41b665097e536ff01af','a5cbb224f6b0102be0fd529566d614ce36e6c7602d6236ea5b3f18ccee39a1d5','df5c14fd54c5d90023b09902a5e84c910b3a75d6b4133fcc8a01bd0c0b213331');
INSERT INTO blocks VALUES(310224,'5b57815583a5333b14beb50b4a35aeb108375492ee452feeeeb7c4a96cfd6e4c',310224000,NULL,NULL,'827c7717cea7159141cc917f9361d7abd96da1220f4350cf99a27ebb01a77b50','c6c51d4071b6a1caf1079fb4421ca77a3efaddf2f5a5626c89dc402dec7a194f','f522eb8be28c76e7150f8bc2b36f10a8c3a2502b05ad6fa3a02c8c7a346a5efd');
INSERT INTO blocks VALUES(310225,'0c2992fc10b2ce8d6d08e018397d366c94231d3a05953e79f2db00605c82e41c',310225000,NULL,NULL,'edd944a6d97042e6241f8870011ed78094677363354638aedc572570abddb062','3ef79b26cc5291e0a629f211b8df4c9af6c77fdd97e33912091337d578333fa1','bb838d69ad6c2f733f12ef1bb3da4bde716e0825e654fa58bc7f1f65353b66d6');
INSERT INTO blocks VALUES(310226,'b3f6cd212aee8c17ae964536852e7a53c69433bef01e212425a5e99ec0b7e1cb',310226000,NULL,NULL,'9a6d2e87fa1455c1b64952fbb6332da034425ae2102dd79309c60f8fd09ed935','5721f0e3cda4b4da1e5c2457e929ef2e9b7fbc1c1352b20cf70defe21342261e','f23b6dc8580016802c33cfd35b32a9ffc753c51ac8788e4c93f68b451dbc94b6');
INSERT INTO blocks VALUES(310227,'ea8386e130dd4e84669dc8b2ef5f4818e2f5f35403f2dc1696dba072af2bc552',310227000,NULL,NULL,'db66a01dc7f560fc41f46f663fd5ec3b0f09b38bb67d76fb5ce12abda7467ade','1960c289238b592d33198ad9700d9ef84ad8156538278fcff2d39efeb121a70b','d987138dd941612f4c58e6d46fe4a832712a6792ca96f4b606f722a15ac0a87c');
INSERT INTO blocks VALUES(310228,'8ab465399d5feb5b7933f3e55539a2f53495277dd0780b7bf15f9338560efc7b',310228000,NULL,NULL,'003214d86f018fdcae66ce8d38ed2ce4ca679d8df17ed350cb2aeed97eee88d0','1a8757058a9272394d8ff8b581d9f203584a86e2797ca4526d45a6406dfd23d8','3d6a770b086e7d46c3ff738f3ee85b1de4bba224f60c50835795ff38a38df9ed');
INSERT INTO blocks VALUES(310229,'d0ccca58f131c8a12ef375dc70951c3aa79c638b4c4d371c7f720c9c784f3297',310229000,NULL,NULL,'caf60a45c7a715dd0465ae6934fd9303e0e7424a155429c09cf89b5b6c217d70','c6d375803b1e48cc99817e713dd6c245cb61e3afafe34f11232b675b951fa670','5ccd9e96c6cf0cd6192d5fd7d2db37438d15b209c11a5f8a77ced0c61f392c77');
INSERT INTO blocks VALUES(310230,'f126b9318ad8e2d5812d3703ce083a43e179775615b03bd379dae5db46362f35',310230000,NULL,NULL,'ef9063972188b2f0321fd58496df9f2bf3e1ca0c3b2d0998af35eb2d3e1db955','e58f5c8648a19ffd36c6fbd508c43f8bd46a1f26cf495cb903b6b944d1c0fb84','45e1e08767a37ca89b26c7f33f4c184d9d9d744d0dddc58e7df32b65343fdce1');
INSERT INTO blocks VALUES(310231,'8667a5b933b6a43dab53858e76e4b9f24c3ac83d3f10b97bb20fde902abd4ceb',310231000,NULL,NULL,'ba335032ab041a39073fe8c21b92111f9f4cdee35f4eaf5bbff9d04a605dbca2','0670a5e27e54a06c1a28f734ef2f149d42ab4a15e90664b2d2d0a13d92325f35','7f1d7cb35a0116dfc95a2140c8450d663fb579215e793b11fc1d18d857da56f6');
INSERT INTO blocks VALUES(310232,'813813cec50fd01b6d28277785f9e0ae81f3f0ca4cdee9c4a4415d3719c294e8',310232000,NULL,NULL,'b18358aac81a8c375c1491f1c5ce7ff5ce2350ba1e903e71ec5f4714f2e41f58','3ed265acef651ef91a9d85322d6a4d8062d00c7a1ce5de1ec882019d3ec17bc7','ebf7c77ec82311ac3af7599f8b7f63a5e0d11f0cea9e53516b11f7350b9fc732');
INSERT INTO blocks VALUES(310233,'79a443f726c2a7464817deb2c737a264c10488cac02c001fd1a4d1a76de411d6',310233000,NULL,NULL,'435f244541d517d3fe31d5960b19cae527a55251aded94bb807d62a59b8a7710','2861d200398ea8d9730b920e5ff4a9bb29c8ed3f28d644f6d2ef3c41b9aa5777','efcd3fa8d654f3c9241e520b75548f55b5ae753ddf527258f02de14372431858');
INSERT INTO blocks VALUES(310234,'662e70a85ddc71d3feae92864315e63c2e1be0db715bb5d8432c21a0c14a63cd',310234000,NULL,NULL,'265f35069cebf5977a28292b2e61608001607763942f0b31331ce114e20ebcb9','55d2ca5e9c526d5de767cf56b48b3aad45f6c5005771bcedc8a3b8db68a5f004','18f9a2ca76b925905cc7277cd1ae40bca55d27e80d77ec6105e13039fa926faf');
INSERT INTO blocks VALUES(310235,'66915fa9ef2878c38eaf21c50df95d87669f63b40da7bdf30e3c72c6b1fba38e',310235000,NULL,NULL,'7542feb6026ff79dcbbe714aaf7a88062e515a40aaf81864cd362d0a5c71759e','29dc677a987e9ef3c19f3f379529cc3b2f38f61f1101d489c337d107c24b25cf','b4d6b96903f0c7b724da7940e6124408d4648593e0f69e434ff16193f8b6d4ac');
INSERT INTO blocks VALUES(310236,'d47fadd733c145ad1a3f4b00e03016697ad6e83b15bd6a781589a3a574de23e4',310236000,NULL,NULL,'9a4cd5ae0a802196c8dd4eab876bc4f5775d1158e988d39f976d53938854ec2c','6ab4527df450ebfc00aa8ab9e5d8dcfbfd03fe194ec87d3ff4439c56f63a5a46','31023befa9729a380c34be0bd4eba42ac1b5f8fc2a09fb71bd67aa74ab4bf242');
INSERT INTO blocks VALUES(310237,'2561400b16b93cfbb1eaba0f10dfaa1b06d70d9a4d560639d1bcc7759e012095',310237000,NULL,NULL,'8646d41892d75377bde953c82f8b277153fce630431c2dd514d4add9816ceb24','22c0419eb990263c851f2695fd64940b32ea4e21ef3093605a03373c4b0f379d','dc7c7430708bc2a15aee153e6c954ba006a6c5cd6f5098a6b9804d72098794e9');
INSERT INTO blocks VALUES(310238,'43420903497d2735dc3077f4d4a2227c29e6fc2fa1c8fd5d55e7ba88782d3d55',310238000,NULL,NULL,'d707705e709fe1cbe130b05fd592e66548304eda228cc6c6830ebd03521a5a7c','70bfaec31126c21f0e3ee502d79658a4973551c7100d0c076f5f6010dce9a3ab','c1cb68351cbdda68ab184ed72ae8d64ba1418f3bd9a2555660bffe246d879035');
INSERT INTO blocks VALUES(310239,'065efefe89eadd92ef1d12b092fd891690da79eec79f96b969fbaa9166cd6ef1',310239000,NULL,NULL,'59c9efe2b890e674380c2993f32ae21e83fd89213e1bfa458b14cef8f20c79f7','c23d228733e0f53459ea6dac00189d1239cc86a230fbeafce3ce1d63b2177edc','32318b685e66a9ac14ed7a763e8e40b027fcb8a2c514d89376a594e86b2a1e4e');
INSERT INTO blocks VALUES(310240,'50aac88bb1fa76530134b6826a6cc0d056b0f4c784f86744aae3cfc487eeeb26',310240000,NULL,NULL,'75babbc3b184b76faadb514cf9aa79bb625d09ad37628a58419e222928c7a71c','943c64f555ebf999e634b49c69084b0efcaafaa5cb3e2ed927b5967c00c9560b','278f1d5b594362a28b0c51fa1b1d3c61add0694d76af9c615c72859fd93f6026');
INSERT INTO blocks VALUES(310241,'792d50a3f8c22ddafe63fa3ba9a0a39dd0e358ba4e2ebcd853ca12941e85bee4',310241000,NULL,NULL,'cd5a9f14474962434e830eac869a79284a3bdfbe7e77e5c1f240063c37435b85','f587a6613b3d94996c0fe193d7f7b392aed54dd69c124a67a8628506ceb1097c','77c2303a96589570ae85dc99e74540e58099cbacd72612de66f12afc0a0e9a53');
INSERT INTO blocks VALUES(310242,'85dda4f2d80069b72728c9e6af187e79f486254666604137533cbfe216c5ea93',310242000,NULL,NULL,'2619a027c0be321517360a1941629882377232b59eceb93be339dbd3bb92044c','a3ee8c8f5e8e369a227b89e0c1b4d8fa2d2126c1e93e37a86153d5711759b14c','00ff8da12a8543a8ffd1a5f31f19c4daa927fc3b97e8d0c91097d1b473453bde');
INSERT INTO blocks VALUES(310243,'a1f51c9370b0c1171b5be282b5b4892000d8e932d5d41963e28e5d55436ba1bd',310243000,NULL,NULL,'fde338fececbbb862b044a51084eef020b8e3b82860ca822cdb093a4c777d000','085f9fad7f8e31f0f4e240146f67e46619bae997f3a47308038683e07acf44c0','ce50fbb2a8837a21b80e98fc2be654526c1927ef6832c6a1f52ab88853664064');
INSERT INTO blocks VALUES(310244,'46e98809a8af5158ede4dfaa5949f5be35578712d59a9f4f1de995a6342c58df',310244000,NULL,NULL,'a25dcf2a8c97e089e79e047484d15ff6fc23e0d25096dafd2e434cce8f856fdf','17527874398a092d80b09c8b0644547dd286f604a6c1c58e03823f436226a9eb','1247078bc58cee3c36d60ead0d7537a6c28055330ab149d7b143cb7d02924f28');
INSERT INTO blocks VALUES(310245,'59f634832088aced78462dd164efd7081148062a63fd5b669af422f4fb55b7ae',310245000,NULL,NULL,'2114800e72a26d123b1ddc32b81f0e577514ce9806b2d0e902efeab23f40704c','7b522836e6f574d59052c7fd4beb450ba4376a3661705660b33794fe53a14fcd','cbfe9bba3c1b8701c411a649a884317fd816d88a8632ff1d1501ea03ecb1cac8');
INSERT INTO blocks VALUES(310246,'6f3d690448b1bd04aaf01cd2a8e7016d0618a61088f2b226b442360d02b2e4cd',310246000,NULL,NULL,'2a1336e1c535effe970f384c15b042374adc4b2f244c5a53bd1954c2f5d27301','b1ecd3ab9badf3db09395c114d047e07a2a042e26a756d7281edfd3f5c25b979','d1ec64648827c3eae61897675c059f34352200409c663c67b7fcef6a2c2b5057');
INSERT INTO blocks VALUES(310247,'fce808e867645071dc8c198bc9a3757536948b972292f743b1e14d2d8283ed66',310247000,NULL,NULL,'76d83848a7173164f2e8c142f72231ecd5cff512156817c91bb548b50f2ab9b3','a234aa4c1340ecd9afac752ea888f6fdfb5298d27ef007fd1328a06738a038aa','df7fdbf30a9dd2d33050ce72ccf497ead2b3433f736c65df1e987decc71053fd');
INSERT INTO blocks VALUES(310248,'26c05bbcfef8bcd00d0967e804903d340c337b9d9f3a3e3e5a9773363c3e9275',310248000,NULL,NULL,'22596847f2271ea266bddbeedf8a45b8b1ea863dd9c1cc38048f1ab4b5100cf2','2d16db343b27a197046ad77b0c000ec928f6da0d1db649f0856adbf6fe367cf5','ac641730bd60bb0311572d6c4b4897dcca051efe4643e1daecfff35166fffc19');
INSERT INTO blocks VALUES(310249,'93f5a32167b07030d75400af321ca5009a2cf9fce0e97ea763b92593b8133617',310249000,NULL,NULL,'4e3075ef055bb8d59e77e864128744992527f9fb9706cc7f1a8c25e53fb8a2ae','92330075ddde1b281d460fcf8674dfff29606fce3a01165dfdd82a060ee4b2ba','306bd8feefe22627ab6e100e433db0845563306a669e652c9c5eb30b76866058');
INSERT INTO blocks VALUES(310250,'4364d780ef6a5e11c1bf2e36374e848dbbd8d041cde763f9a2f3b85f5bb017a2',310250000,NULL,NULL,'eae535e747acde23509a76ce35d742a306d577374e2b46167170ac10b66c39ed','b8fe0f3b2ec6e06a89f0c6a638a28d7518ffd10fe7d160aacf2d2c51020330c0','1aecbb56222fb58c8a06cbdcc315dff139a70d377263a3504232bbd45d327559');
INSERT INTO blocks VALUES(310251,'63a3897d988330d59b8876ff13aa9eac968de3807f1800b343bd246571f0dca7',310251000,NULL,NULL,'ab28ea4415dade72be6372bb6d0874f541144bba55a67ee07f57b4fbf4f4307f','46e7cbcc5bf65a0465f7240c5c5d20521136cbcc53b8d77ab4f89ec3f4875b38','f6ea60ce44a828efacfbf7ebce8e2a4a798050e11597954285df3ceed575a4e1');
INSERT INTO blocks VALUES(310252,'768d65dfb67d6b976279cbfcf5927bb082fad08037bc0c72127fab0ebab7bc43',310252000,NULL,NULL,'068f39c98b6e11843edcc20264f68e18399d95a3bebec1e8f714f1d142d8bf57','679d9b8812dfd8405fe6cc6d8f2e02ff59dcd873fbd0f36ba08ed5e8b5a1d81d','316711cc08e559d1e454d92aacf04187cad4a09d2e836683245cfc16e6ea62b9');
INSERT INTO blocks VALUES(310253,'bc167428ff6b39acf39fa56f5ca83db24493d8dd2ada59b02b45f59a176dbe9e',310253000,NULL,NULL,'f8314c45b7e26111c2f11e94e3a2d53bd65d232e125081f85ed5338c5cd10e5e','5453b2dd8ffca13932ad685118327df3c05475e17c98ca0440e9f91d44db6528','dc733be04362a46a4cd1e3103b7fcf07f8103a092ccf70507ebb4f282202f449');
INSERT INTO blocks VALUES(310254,'ebda5a4932d24f6cf250ffbb9232913ae47af84d0f0317c12ae6506c05db26e0',310254000,NULL,NULL,'9ff85f0035f1aac1ca253700dea644084a1dc53d5cf36c9a7c24a3f517b4fa55','2de9886481c3c7a65dd6996e0fe116a5d84f4301cb29a4d078451d3996d86d18','072da2b4eeb349c89f3797716cbac341114e4cadde3936a2cd02d13c4c05b2dd');
INSERT INTO blocks VALUES(310255,'cf36803c1789a98e8524f7bcaff084101d4bc98593ef3c9b9ad1a75d2961f8f4',310255000,NULL,NULL,'c7d4d4645e5e9a9dd66100de877548a527986eff0bf88d0a4b988e482ec5acfb','4e626ccca70235a13c287fd8b4637fbc2cc9cd6c91d6952c0f9013f8bf830d43','f746325509e432bec8530212cd0489a2959dc8c2e6fa496ee14df493f93ff6e1');
INSERT INTO blocks VALUES(310256,'d0b4cf4e77cbbaee784767f3c75675ab1bf50e733db73fa337aa20edefdd5619',310256000,NULL,NULL,'e0025cf0b3137fe932d5a094f9b7f0d446eb1e8262e66451c38268f978578d36','849995e464e9a942f7287075bf715823f1961dcec2105374c01b827649bda3bb','c1413e00e8cfc5a4d7002fc71b19fd2907f070e0b2cdaae98bd3c9dadb18f008');
INSERT INTO blocks VALUES(310257,'0f42e304acaa582130b496647aa41dcb6b76b5700f7c43dd74b8275c35565f34',310257000,NULL,NULL,'93277629338b499795a2376f1c87ce8888c0f95c87fd9ba50e02c710708e350c','d56ad46ebffa76d044029f28df49aeb7ab9ff1892a388917399bdcc33eaf6085','64c2872609bbe96d33bb58efbf23e66919e661dcd03a2c945480658c16a2e078');
INSERT INTO blocks VALUES(310258,'3a0156dd7512738a0a7adba8eeac1815fac224f49312f75b19a36afb744c579f',310258000,NULL,NULL,'ec36c0a876de52c420f30d331da84989f02d19c2fe8a2004bdc97155540349f0','2d8e682cddf65a3438fd00ab4115a2ce6a4f703895541455794149d6f0a41501','3690c48b3652f89e695f8008bf54563c656bdf4d8fed0d74e20067a3d55b2ec0');
INSERT INTO blocks VALUES(310259,'e5ed3cdaaf637dd7aa2a7db134253afe716ffdf153e05672df3159b71f8538a9',310259000,NULL,NULL,'07514ac5a88e825faba98d26a4feb2f186fb5f278d1c9f9d90d4cb055f29a352','d12dd826321d8b697042fc1a9e59f2024830706a525ecbb26e65839272a450ba','f2b946956790878b2f0ac5205ae487f0d61ffef5abc5f8357674a4a3c80cea1a');
INSERT INTO blocks VALUES(310260,'8717ddcc837032ad1dc0bb148ddc0f6a561ed0d483b81abb0c493c5c82ec33cd',310260000,NULL,NULL,'9d99e75c2b0fda1fe5f5e696c182bf4414acd0f3b2a6f6477c3ac0ec9b84d4ec','37598e03d94f886cd03566346d9a345ff95b5f2c4006c2f0bd6df586461c8192','b69b8c0fa08403a5889ea8e5aca1ac10993cabbb877971e6fc3bb7cfc08c3641');
INSERT INTO blocks VALUES(310261,'a2a9d8c28ea41df606e81bf99cddb84b593bf5ed1e68743d38d63a7b49a50232',310261000,NULL,NULL,'8e57e8e4778250a493263b39b4ebb410f579c75a1a793961ff85d051686be25d','9bdea14b649b6febe518eda3eab3e49829d802871161d85efcc1fee9dc74c2b6','cd1fdaad84c6c16e3105879c7bf780b6b5002d140043aa1f5df1bc6499329583');
INSERT INTO blocks VALUES(310262,'e8ebcee80fbf5afb735db18419a68d61a5ffdde1b3f189e51967155c559ee4ce',310262000,NULL,NULL,'3429c9f182ab8b7d81833d6a203852fb11cd7056e47e05bcdd9daa9abdf60c26','bc750d2ba58817b20f8a04724d3b07967580593d76c7e00d708d403c9f07a944','cbfa7e276847288ccfcfb416d50ef238d006aa888ec64d7a7201b8c5b95b4f37');
INSERT INTO blocks VALUES(310263,'f5a2d8d77ac9aac8f0c9218eecbb814e4dd0032ec764f15c11407072e037b3c2',310263000,NULL,NULL,'16dc10d8a850cb37ebacea18995d05bc99ea3d647e943c666e77ce20e20c6b43','504f0a4146f235c8a3c03de4b380a37f8b3689e202b24a881248e7d95509bd05','edfc59d4c79c8caeae6cd3936b7f6e4e418d5ac40b7390abc71b97122127a73e');
INSERT INTO blocks VALUES(310264,'ae968fb818cd631d3e3774d176c24ae6a035de4510b133f0a0dd135dc0ae7416',310264000,NULL,NULL,'84061a8da010889e968caead05c0fd936271ad1eddcea62222cc7791d7b0d39d','5d096e19fd6eae7f8acb43af304b8c798a02e20f9bf221279b16dd506d06b7e0','86f4e4606baa3e259f370ad58352ada85882b5232f26ee7912ef88b79084894c');
INSERT INTO blocks VALUES(310265,'41b50a1dfd10119afd4f288c89aad1257b22471a7d2177facb328157ed6346a1',310265000,NULL,NULL,'5b145e0765ecf464efd8c370fc419f3b5c1cbc2a4450b0a02807b09a6f173d44','5d55cffd9bfde5c74b447ab12b2ec0d08d2a72ff40809e025e7188c247c48946','9eb6f5f6c11a729f181db28b6175407ad892a483ae0a4047232f7e9fe0399119');
INSERT INTO blocks VALUES(310266,'1c7c8fa2dc51e8f3cecd776435e68c10d0da238032ebba29cbd4e18b6c299431',310266000,NULL,NULL,'14c812e80e45bef98ceae64188cf3c216cd128c050ee12e03f4b0cefb79ac23c','fe24cf935939f03e96cf16677f952cf435ed5c1fbd2766813157cdd459b4c07c','43a253f27530c65eb3a778cf98d72d25a07c2d2217ed4b2bbf5e3a8bac82573c');
INSERT INTO blocks VALUES(310267,'c0aa0f7d4b7bb6842bf9f86f1ff7f028831ee7e7e2d7e495cc85623e5ad39199',310267000,NULL,NULL,'a459a0dd6ddf5144dba5dd5093521e50657b6976ffa32e4eba6369411dbfb3e6','2585bb9c86f5ee70b5532340c817d25bf6b010ca2a9b6db13901fa8cc8a1e665','2db277ccc05efe87d4e88a439a581cc0629dea5fbf81c617a132d9afb302d7b4');
INSERT INTO blocks VALUES(310268,'b476840cc1ce090f6cf61d31a01807864e0a18dc117d60793d34df4f748189af',310268000,NULL,NULL,'ff422dc280387da5e935176efd911a22289e95f1791841c97a3b76ff8542efab','c1cbb25bd896008f1d4a73d1a72fc74ac8a574bf4301c4769d8cf7f830036272','4c79e17ff2678d939b3a585f69dc5e31059f4ca3e585e8dc05a3ffff47aacf5b');
INSERT INTO blocks VALUES(310269,'37460a2ed5ecbad3303fd73e0d9a0b7ba1ab91b552a022d5f300b4da1b14e21e',310269000,NULL,NULL,'7b4b25fb03155c848a7f48a9489344a777ef51db5685c528ffc9a16cd2b67801','de31a18cf8b0d87dc1002524d91c732de29ede0afa5a180afecafb7d175e5c90','b047441e0d1ef3a778236067369f90072ee2c70847cdb00899e2228ad8cef44e');
INSERT INTO blocks VALUES(310270,'a534f448972c42450ad7b7a7b91a084cf1e9ad08863107ef5abc2b2b4997395d',310270000,NULL,NULL,'36c4770682a29435c08d89715709442b86ead2e22d592c1fa2f303d783fc7e83','8b4d6f53d3c1d91faf1699c9548507abc4c545e29131cbf6cbbce72d9db26f28','b1d6d8c355b266591417d1c40b4501298f704c94f9cd93443f4c29d31b270401');
INSERT INTO blocks VALUES(310271,'67e6efb2226a2489d4c1d7fd5dd4c38531aca8e3d687062d2274aa5348363b0b',310271000,NULL,NULL,'64ab8dc28aee2964ff27fea899641e31e1b9a0a500b2912df9a258dfd1c95880','bac251c2cd1359234a8ca0978bb41f92eecbdd90c2201c104b463b2a4aa9c262','777b6ee41412891964f47e6cfb7616423be446eb175d2e51d33a403275c221df');
INSERT INTO blocks VALUES(310272,'6015ede3e28e642cbcf60bc8d397d066316935adbce5d27673ea95e8c7b78eea',310272000,NULL,NULL,'1f25ecdf5f92e65a824742af27281fed636c37ab6fffc7ffdd183bc3e3349f04','0c0e1ac6a5a9300f813957e667d3362749d37e921e1754a226878d3cbab3eda8','3c0b3c0e2039e990a37ddfa6ca17e5f76158aa36652ac9b2ec851b04f714e8a4');
INSERT INTO blocks VALUES(310273,'625dad04c47f3f1d7f0794fe98d80122c7621284d0c3cf4a110a2e4f2153c96a',310273000,NULL,NULL,'9f6f4530f2782c2e492fd150bdbe5922acc5f547016fa06f6fd737414e501b20','e8e5118c70ee3da6a65db49df962712486dcfdc0b765f90d97212d9f008d0622','5722925b13218e6655f14fd09442227325d33f83757250808919e6c9465e7fee');
INSERT INTO blocks VALUES(310274,'925266253df52bed8dc44148f22bbd85648840f83baee19a9c1ab0a4ce8003b6',310274000,NULL,NULL,'612234f40ebf8b71cdc134a21b7a9a7b6a870475d22d72f8c43c42d76687bb00','c595b2ff2c97a7ed3c340f7fe2c73bfd1181165918a39f742cbc445d90df24a3','8a3bac2679bce62345c6658f0e9fd62686683f87fab6b3b0667d96e18707e7de');
INSERT INTO blocks VALUES(310275,'85adc228e31fb99c910e291e36e3c6eafdfd7dcaebf5609a6e017269a6c705c9',310275000,NULL,NULL,'677ff29a2e520bc537ea9ce2448aa9a58392b9fee445af0642b2d1d91eedebc9','15079985676b3a7d296f3ddf3440e538737c8de2c6161be0678d5c96d48271c1','419a45b80ae04fd243e032cb0a47d3b014aa1a1d3b5b1ecf0f885b15b424b8fe');
INSERT INTO blocks VALUES(310276,'ba172f268e6d1a966075623814c8403796b4eab22ef9885345c7b59ab973cc77',310276000,NULL,NULL,'3ea08fc9694bde31e0b3ff785b16dc102b5c3a9a0644a19d6e8c9cdca6f559ed','7ef549ace3cfe2cc1104beef4b233eb48236448e6e44d674c9f6ceace8f72c3d','41149bd61a24f2a6496df5590a578c9543fc1e90932892836ae14cbb03249e82');
INSERT INTO blocks VALUES(310277,'c74bd3d505a05204eb020119b72a291a2684f5a849682632e4f24b73e9524f93',310277000,NULL,NULL,'7a9ce45c47934006884de82e75aaaf46561f1fc2f9bbcaa7e84b150f23223979','d815fa0d5207644e67d89b158d3d20d7ab36ef0c8f15d8a4c0eb2a519e389f4a','b31414f8c2eec8ff623ab4de9f66968758adbed4fe76bbb38ca56bae8a0f11cf');
INSERT INTO blocks VALUES(310278,'7945512bca68961325e5e1054df4d02ee87a0bc60ac4e1306be3d95479bada05',310278000,NULL,NULL,'96352b94acf87d4ba0d2fea8840dec283c94644d6802f3f3185cc42542d7862f','8a9df9ec10516e39c8188863d9fc179d943abd477f6f2af1c0d4267a01a89739','469258548b641a81fa4b8b770505370ed962fc70b36356eac6e3119ef044f0c4');
INSERT INTO blocks VALUES(310279,'1a9417f9adc7551b82a8c9e1e79c0639476ed9329e0233e7f0d6499618d04b4f',310279000,NULL,NULL,'26375474618bf5f3e5b3fb4db0c49ba31c8acc0cc83bd9adaeadf9aac8d879f1','63d9daa41d6ac2bbfd709e12a7e16ccb390f08b295d5fef74916a175b59da954','5e6164b652832e291cfa8556bd2512d3af5857aca52c9e846690a511bd9f1b2f');
INSERT INTO blocks VALUES(310280,'bf2195835108e32903e4b57c8dd7e25b4d15dd96b4b000d3dbb62f609f800142',310280000,NULL,NULL,'14736d8f692cd45233e050b7ebb35fa3bc1cd8abd7b166d5c61ff34dba58a151','b08fb861f4e3fae81e80c4d4332192688f473eb621c459125db56a66cd927004','d410974b3d0b8fdb4795a3e38e74a902acbe9c2a840b94a1878c9c7afb45721a');
INSERT INTO blocks VALUES(310281,'4499b9f7e17fc1ecc7dc54c0c77e57f3dc2c9ea55593361acbea0e456be8830f',310281000,NULL,NULL,'57384a6b26f1079831f50921c6a25731398d54b8b61d8ad2395c2b565b08f2fb','0ee5f2cec3a2c001ff4d51c498b182782b9ac6149b0c2b9fba383ded8457746b','3945642da2a994efd8b277a3f057d44c2b0a3273f18d4c46406ff3ea7844d9c8');
INSERT INTO blocks VALUES(310282,'51a29336aa32e5b121b40d4eba0beb0fd337c9f622dacb50372990e5f5134e6f',310282000,NULL,NULL,'87f16a1b9cf6121dcacbfc458e68652c507bf1500c3a7711f82fd5735ee5121c','351c913ffd52168154c68db6c25d22b51d413adfe5015b6be409419894cccf11','639944c68cd521218bc8b02c9df28bb3dac48eacfd8ad14130026e562a02c7c2');
INSERT INTO blocks VALUES(310283,'df8565428e67e93a62147b440477386758da778364deb9fd0c81496e0321cf49',310283000,NULL,NULL,'4f5b6038bffe69d3b0476212249b8bb8540dab7857d2701d7856944695ddaee0','2df550d08ea5f6c5477533275a4595b2e876ab5ced7fb3250e43c635d92f4ea2','40d4b5724fedc7100db82bc653c636b6213b44e5e3e00a87b2076cf23ec42e93');
INSERT INTO blocks VALUES(310284,'f9d05d83d3fa7bb3f3c79b8c554301d20f12fbb953f82616ac4aad6e6cc0abe7',310284000,NULL,NULL,'5684fd8d132660de7950bc92c16923cd132b8d6740b6854bb25fe7b39e3ae5a8','1aad3d893e459b130e63c16d3abebcffe0d47c292058a66bc3209663db9bb0c5','6b2c22e38760f92192d9e54d556456ea321a8e2c7c9e5043e0c6855f767af66b');
INSERT INTO blocks VALUES(310285,'8cef48dbc69cd0a07a5acd4f4190aa199ebce996c47e24ecc44f17de5e3c285a',310285000,NULL,NULL,'b95155bcb4887d223bd04299f8d23b6a60a55a5fae699eca32539feba0f591ec','6cda730ef3e33a8ab8c9801f8ebfc9a599a38e9b3aad73a838f13cc50e383cf4','c9b4db69c98d51373ff68f9966b66ae2e1e6e978ad68b7edbba11f79f656d059');
INSERT INTO blocks VALUES(310286,'d4e01fb028cc6f37497f2231ebf6c00125b12e5353e65bdbf5b2ce40691d47d0',310286000,NULL,NULL,'21b716f473e1f2b98aa318e38b7515155cc5aa363e79c8d2c44d76e361111110','987c59e3591931f601941444e9bc93388d4758e6f91733e52378cbc2ce929226','6c491ae2fada837a95642acff1c7cf560279d6511c693e076e357a678354457e');
INSERT INTO blocks VALUES(310287,'a78514aa15a5096e4d4af3755e090390727cfa628168f1d35e8ac1d179fb51f4',310287000,NULL,NULL,'b87fb8fff4503de1b83ea34f770d4a1db27f4552844cc2b12cdd9290668b5c6c','abe5994257054408238df891add638be56c895341787151e685a28365b78acfa','7176c50a0d9b6313a7cbb58e62815b371352689beb3dbdc0248141bb637d06ff');
INSERT INTO blocks VALUES(310288,'2a5c5b3406a944a9ae2615f97064de9af5da07b0258d58c1d6949e95501249e7',310288000,NULL,NULL,'fbed8218feeab563055b348291798164f654542102febfe20fa0fbbc46be0395','9f8e448ce93932274ecc417e84480214c9cea0f0347a53956c7d2aaf769a317e','873073b82de1dd6c2bd74dfb615be415f7bec94f8bc0c0ead94ab568e7936e39');
INSERT INTO blocks VALUES(310289,'dda3dc28762969f5b068768d52ddf73f04674ffeddb1cc4f6a684961ecca8f75',310289000,NULL,NULL,'289098f22061f1dac72a8b28c5d5e1f001be0069f65b3f8f6992096f03006fe0','ecc5a76be8537cd7ef59d318baa7f5fb4ace2ff261a526b8d94b42439fe1f6bb','b29a27015bd0fcc1c82044e49f61a054863e91cb1ca270e1cfa69d672346d77d');
INSERT INTO blocks VALUES(310290,'fe962fe98ce9f3ee1ed1e71dbffce93735d8004e7a9b95804fb456f18501a370',310290000,NULL,NULL,'0d7318344e95ffb1d7dc8cb8c1e73aa1cb3c4e4724b40b7ba34dfee7b6f39f40','2d31a68f2122d9234276015b8b0b0a51609a43dddbc0ef9bdc15474988266055','4dd1a0310a89b73efb0664cd9968489431f38e3a312a2f8ef5da5409255a70ce');
INSERT INTO blocks VALUES(310291,'1eeb72097fd0bce4c2377160926b25bf8166dfd6e99402570bf506e153e25aa2',310291000,NULL,NULL,'9a6976c68d4bd161d6dd1d16c3b97523a1caab94eb8e9082f3c5c0ee79d9241e','747569ac8f3cb3bad01ef1c6bd0892ecfbeec424528f3c3a40c135209d7933ad','8b676540ae1d21928fd931940168a239a8ce2d8252bd43b679fb0db2bba50f0a');
INSERT INTO blocks VALUES(310292,'9c87d12effe7e07dcaf3f71074c0a4f9f8a23c2ed49bf2634dc83e286ba3131d',310292000,NULL,NULL,'83dfabf2c9d06daef8f6d203c1d04affe1dd7c90e17375d82f5f8c54b6fa1536','c5012657109188b4646a3ea956a7fc8ac1b62ce7120eedf1a525a103322a580e','df71e42ac75ec86c07cc5264d89d9ac5751d2e0cc07e696e48ddc00c83fa2ef2');
INSERT INTO blocks VALUES(310293,'bc18127444c7aebf0cdc5d9d30a3108b25dd3f29bf28d904176c986fa5433712',310293000,NULL,NULL,'636a86d1ba77cc4db59ca073d85df38570eb12a89373d8d32b8ed0fd27cccf7f','18c60b7693f01ab87751b4e0614b7a68e3746fd7db999e7231bf03b80f85e6fa','ef7332f0639631621e22f86bff665702324905c11bf49b062a8810880f46e43d');
INSERT INTO blocks VALUES(310294,'4d6ee08b06c8a11b88877b941282dc679e83712880591213fb51c2bf1838cd4d',310294000,NULL,NULL,'c831240fe0475055f71e79eacd1b1b5945789b97be29cbef71337fa4bb1d6867','0f35b8a4a13755eb9a539ce6238016c5d4766be1e4f2db204771dc5526d98d57','670b00b1583b9e55094dfbcff2ca241f8c6f164b1ef3217dc09718cec7f0efd5');
INSERT INTO blocks VALUES(310295,'66b8b169b98858de4ceefcb4cbf3a89383e72180a86aeb2694d4f3467a654a53',310295000,NULL,NULL,'ed8d39e43c4fcc3b304e74a8bf7e2cb572784fa86da5f3337c6c54b898713e58','b4cec141a9f93050b14474fa8f2a72548eba1c632529705d0b8b195ab44cbd17','f6a27ff7e19facf2ce6cca89c3290c9aa603f0ca13e28697365673c1b6307dd2');
INSERT INTO blocks VALUES(310296,'75ceb8b7377c650147612384601cf512e27db7b70503d816b392b941531b5916',310296000,NULL,NULL,'d5c19c60a0a32ac1c55da13fdaff4fd5acd0117af144d7871c7a70634a6e1e67','9cce2d3a9787c1968f7e4db3caffa6ef88acdcc4e191370178957ed7842f2f54','461efc6de4a2b0e567bf7559a3fa1065bcdd21cc0e4c1779489552035423799b');
INSERT INTO blocks VALUES(310297,'d8ccb0c27b1ee885d882ab6314a294b2fb13068b877e35539a51caa46171b650',310297000,NULL,NULL,'ede6d6afab39954b63576889597abd12ea14f8ff56a3a23b9df12a049e1b8a5d','65475dda3730c427bf573765234402be469c566b644e612c97566c2b098ff762','68755f13e9155701c571d8c4c6c813342f1d428ff79341d3a5a352ad0e9ca835');
INSERT INTO blocks VALUES(310298,'8ca08f7c45e9de5dfc053183c3ee5fadfb1a85c9e5ca2570e2480ef05175547a',310298000,NULL,NULL,'5b6eeca9b9c81e2565f7a27d2708abf3782de7a06db7e36f3ed6c871dd7808a5','8eee3fb2bae58f413e67c9b05db30c7103fda07dfef95a6d68f7020f6cc09c4c','73390c7086e7acc39d8717a2e1c2c880246810c6f134f6656d427ecd3ba38907');
INSERT INTO blocks VALUES(310299,'a1cdac6a49a5b71bf5802df800a97310bbf964d53e6464563e5490a0b6fef5e9',310299000,NULL,NULL,'edc9dde394fcb162a512c24769a36e875e7610ab0ecaa76ea758f55552fb4a85','11db925a0aa1549f8695e2dd1df05f638ae3a83d58c503bb9bd25b6c174b256d','c1f896a02922e53c3a8b08460e4338fdcc8123ec7237d1b63e4f686ec4e0c3b3');
INSERT INTO blocks VALUES(310300,'395b0b4d289c02416af743d28fb7516486dea87844309ebef2663dc21b76dcb2',310300000,NULL,NULL,'990e5d85433694ee1caddc379006a3bbaa68cf19dc29e1252609b0d2bd7514e9','4d5c026a2ce1fdb1321f1a03fd518a208acb51ebee2563c6fedc2da3afb3f2a9','f2c6029149e73220bc17d5386ce4ce4dbb00e0c8a047b69fd7a4930774a29340');
INSERT INTO blocks VALUES(310301,'52f13163068f40428b55ccb8496653d0e63e3217ce1dbea8deda8407b7810e8a',310301000,NULL,NULL,'1d356c48b53e5693feed94f6387e6904c5f63d764cde85c51beb0a6faa3cb24f','0bd3734add1bdad4d9fba0884acd8e481cd52cdac5552dac2235897c2dbc6d53','834015193b2c44a7eb7bddb609d440a4ad5f5f24bdcabf96e7d6105eaf8299f4');
INSERT INTO blocks VALUES(310302,'ca03ebc1453dbb1b52c8cc1bc6b343d76ef4c1eaac321a0837c6028384b8d5aa',310302000,NULL,NULL,'00ac9ccb045f4761a338d571e2237c6a7f3a4eaaf1e3027b5c9ff65d388f10c4','064143a4c5f7b6733f1aae474d3ed5847eab59cfb60aca62e6b1ec38b12a4e74','10b14d55cf9d3da76706fdf6dec58d6625531b0e7650034795726b05f57088a2');
INSERT INTO blocks VALUES(310303,'d4e6600c553f0f1e3c3af36dd9573352a25033920d7b1e9912e7daae3058dcca',310303000,NULL,NULL,'d9ad8988bf9e26c3d37ef309099609ab235ca9b0d5c66e1f0c827035bfa8df56','8241790f797946f429c746fdd4a801582f666881e32ac79fb3487c7ee67cce3e','4bef4efebdeac268358da2d45f698504e65e1034b2cec22db29a7e32614d6d15');
INSERT INTO blocks VALUES(310304,'b698b0c6cb64ca397b3616ce0c4297ca94b20a5332dcc2e2b85d43f5b69a4f1c',310304000,NULL,NULL,'f056bc4b76b8192ca245a0d9f896b50fe28a0fe331ee00cf309bc8dee5c118b7','e9cbcf382b9250004616a03362fb80f1cedab1ade1d9737b6a888d4806d8b6b7','5b65b6cd30643b8c176062a54964a7038c5dd63b4579b4423ac0c8b3bee7c8fa');
INSERT INTO blocks VALUES(310305,'cfba0521675f1e08aef4ecdbc2848fe031e47f8b41014bcd4b5934c1aa483c5b',310305000,NULL,NULL,'88fa4c3dfc77c625378043259ca995b2192306016dc415cc11450bf80c184876','69380d77d15be1a619ff57ed82f3d21fb49ec0fe35a284b2a02e75cfff184e74','883105df8499cc0abc6b23de1ed186a1473505e8bc3fb6295ac0fdccedfdcda4');
INSERT INTO blocks VALUES(310306,'a88a07c577a6f2f137f686036411a866cae27ff8af4e1dfb8290606780ec722a',310306000,NULL,NULL,'0f3ef0bea63f6062d79d2e4e7a2d22865aa3d519a012b2b3b48ab316a889e844','571292e36494e432963a8de5a0db25bd9117d09def186ab26e4ff6462a91d12f','739a1a4f7f1a2f980682b10997d618584f46dcbc0fe89e2ff83abea362bea451');
INSERT INTO blocks VALUES(310307,'bc5ccf771903eb94e336daf54b134459e1f9dd4465dec9eaa66a8ee0e76d426c',310307000,NULL,NULL,'d1472f4a9f3a539fe2df6ffd197c49d7fddabd66b704741ee74be0904b4e08a0','ed40b935e90d73e58c47d1797ec36f5f887c605b87c4ce57a311e202cab11952','6952ab498ac3d14fa371195e2a0144da4f46e6a90833e3e82dd4e2af3617792d');
INSERT INTO blocks VALUES(310308,'2291ffd9650760ff861660a70403252d078c677bb037a38e9d4a506b10ee2a30',310308000,NULL,NULL,'519fdeb75d3e294e08c4e2f43c712deaab1397c4ced9dd957e221d4845d50f6f','b55d69d893534094aa3ff736ebea5beb536b91594b30e73b5acba5678926fc91','9efc714a50c4feefcea1b7157a615ce8b566143cb784db188355521f08796189');
INSERT INTO blocks VALUES(310309,'ca3ca8819aa3e5fc4238d80e5f06f74ca0c0980adbbf5e2be0076243e7731737',310309000,NULL,NULL,'0d68bf10443e34c9b6705345f689ec09e6295e17418c49b55f97a15aa056022c','16b9efe5a5584ba180e421eed4c147e7c83425c63d9f1bf2d9accdd83429e421','a1c376ca2e2784edea5460d5536bfe32366a44bcc5afb240f17d380141fa8a0c');
INSERT INTO blocks VALUES(310310,'07cd7252e3e172168e33a1265b396c3708ae43b761d02448add81e476b1bcb2c',310310000,NULL,NULL,'04b031132dc1beb779950ef6a8b66fca2916536429f74d962d931b2c2072152d','46b8902bd79690f231881d9936031e514afff8365ed8ae6851b005f7b3a123db','1b818492245deb6e5bb00c04521611788425bad465690d5a21acb8fbda0c2927');
INSERT INTO blocks VALUES(310311,'2842937eabfdd890e3f233d11c030bed6144b884d3a9029cd2252126221caf36',310311000,NULL,NULL,'b8463562977acfaeb9a170211bab18a3e98563e84a5bd2246807aa6a673d177e','dabb6ebe0078670c1c7247db2a898c36101a75db2b05f4e9a58fc267ce50a9ff','deebf5fd1da5158117995faf89f4f073d80a83955550c8878e4b22be4a3e2371');
INSERT INTO blocks VALUES(310312,'8168511cdfdc0018672bf22f3c6808af709430dd0757609abe10fcd0c3aabfd7',310312000,NULL,NULL,'6e6c1abfa8f35f0ece42e8ecb062306aa524b2f26212ca57cc52a288ae6d03fb','2c9fb33c2e408ff4ab5ecd55e5d08f5c08e45042c5d17542f184275415bd9154','15189a19e900270a13fe68268e2a37fcb65686482f2da1b73fef603d4322470b');
INSERT INTO blocks VALUES(310313,'7c1b734c019c4f3e27e8d5cbee28e64aa6c66bb041d2a450e03537e3fac8e7e5',310313000,NULL,NULL,'443b440c67c7cb26d2dc0b312151f77e32a467093fdf32a9e8541cb5662b9b29','9f14413b35ec842064d2b0ca608da26665e1d2b7484dca08e08f1945fe12e385','6c164b340155b6b91e67e2e426a46104238fbd4e802e2c374a080898d56625a4');
INSERT INTO blocks VALUES(310314,'1ce78314eee22e87ccae74ff129b1803115a953426a5b807f2c55fb10fb63dc8',310314000,NULL,NULL,'64b33297f2da08e78bba546916fe830dcc25f24d2a312f6f1ebac078b5911a58','198285e3c4638c94510c8ded558a58e3e0ceedc18d63a13e3c526609b9a4be4a','9119c62c3f9c8362dab3240249fb61ab7882443f8da805b1fb0dc445374d6330');
INSERT INTO blocks VALUES(310315,'bd356b1bce263f7933fb4b64cf8298d2f085ca1480975d6346a8f5dab0db72cb',310315000,NULL,NULL,'d87d4c0e01fbf11b537f7700aa00c3efed226d91643404476ff4952c334eb76f','351ab344e00b8bf8056f83766fc4d14ee21fed2d79b77a5ed2be0918270d28c5','3572c5101999de47ac9a9b4a2ecc019f7c9e44ce63f90cf3424d1eb88a9bd773');
INSERT INTO blocks VALUES(310316,'ea9e5e747996c8d8741877afdcf296413126e2b45c693f3abdb602a5dae3fa44',310316000,NULL,NULL,'e6159cce7756feef45757dedf4c79b5d3af36bbe98370b81494115087b057acf','bfd27eaaae328175f3068d67f83d194357156300b55067ba37a5bbf6f3bd9bf7','e4d1d05cd5608f2a721403f66777ce19059389ff25fde6760b68f3acf1beb549');
INSERT INTO blocks VALUES(310317,'aa8a533edd243f1484917951e45f0b7681446747cebcc54d43c78eda68134d63',310317000,NULL,NULL,'9f7e36d2950685b6b5a67a5d0eb5f66e59a18056948f293447487387a539ad3b','9afb81731518754683b0ef568b18deb5a19e54521b45bef1184e90c05f1584eb','900d72c04c627cbb1828b02769ab0aa13d64ad61ac97df2f15608b6850154c8a');
INSERT INTO blocks VALUES(310318,'c1be6c211fbad07a10b96ac7e6850a90c43ba2a38e05d53225d913cc2cf60b03',310318000,NULL,NULL,'047ef3cd8ef77da63fda28aeccb214ef4bdbe396cfc65e6cf9b1c8ce5e24687f','6948de1fcb159afddc73f06ddcdbe2e20f57d49bde4ee68baaf01c6d2fcba420','84fdabb6342922ef028c4f5dc71be8193407eb09baa15b77491b2a8eb4d7e5cc');
INSERT INTO blocks VALUES(310319,'f7fc6204a576c37295d0c65aac3d8202db94b6a4fa879fff63510d470dcefa71',310319000,NULL,NULL,'5715fffa93cf27966679e99f2c932716b28c80de2026ca5b26bac972e49a442e','b2fc611dc5d6c0da04064eca88a83f1c47bde2b68bfda039ee9fadcef46a208f','800b6268cda5e24890eafea3e6fb1f4ca1184d07c3bba1ab5c7dc2988862fc43');
INSERT INTO blocks VALUES(310320,'fd34ebe6ba298ba423d860a62c566c05372521438150e8341c430116824e7e0b',310320000,NULL,NULL,'554a1059b9561c113a9c5c01d189b3ce74a694390533090b7384fc232289b0dc','09dc126b7ff8e75fa382e5766b12c6609a7a993d09ff3111ac21c804aab85f42','c38f6f2114d805e6be7ff684086262a179f1cc5be8b666c44c992c6dc296a5f0');
INSERT INTO blocks VALUES(310321,'f74be89e9ceb0779f3c7f97c34fb97cd7c51942244cbc2018d17a3f423dd3ae5',310321000,NULL,NULL,'2209638e8e987c390cc413120cb2653d2392ed2b28396f033d24833845da071a','35d20d65fa982dad6bfa1de1061f41e792cb833420a7746c13183a2d9c267307','78c54da32a329fa4b30ace4848b0d9312e5ead9060727cdb1452064eafcf542e');
INSERT INTO blocks VALUES(310322,'ce0b1afb355e6fd897e74b556a9441f202e3f2b524d1d88bc54e18f860b57668',310322000,NULL,NULL,'6acd4213d02d8543589141636c7989c3715c8f714157a6c058ec13adde66b6db','5cdcd5b6a05c4d626857c5b722f229b01fcb1f124780c530060d594fee544a20','3297eca9cd6686462b2e4929f21c34c24f2fe7d1013eb90331d61c7092407ddb');
INSERT INTO blocks VALUES(310323,'df82040c0cbd905e7991a88786090b93606168a7248c8b099d6b9c166c7e80fd',310323000,NULL,NULL,'044fe2d72ae5d88c7f90ab7399b801b78e00905a27a6566e74259b08859c8a9c','dd9732df45ef1b178453b0db17d2b1d8bc77098a9e61a850cb40f94d66e960e6','823253d15b236667713c308d65aff615523f54926496950801bf90725d6aa90c');
INSERT INTO blocks VALUES(310324,'367d0ac107cbc7f93857d79e6fa96d47b1c98f88b3fdda97c51f9163e2366826',310324000,NULL,NULL,'435b97607dd1439f235dc60411eed231ff9bba09be17f03113b9e59d44537bfa','b1638f673be308c49d353001b8dc51095d62fd658559c58598e71e51d89d8b8b','7c5914b231c883b9bca1c22c1254dc871d42c0d655b24e219a25000ddf99f5ab');
INSERT INTO blocks VALUES(310325,'60d50997f57a876b2f9291e1ae19c776df95b2e46c14fe6574fb0e4ce8021eac',310325000,NULL,NULL,'ca1201a7edfbe9edce6cce80bd6507a5b5bd7d8e09d24ff0502630260ccba1d5','9ea4d3a50bdea29a1b230f9e8eb011cbe8f079a4a8c22b8e16a7357e7c5fef64','a67d9069bfff5da49ac587f166d00359d9873c615a8989cf58393d77113faeb8');
INSERT INTO blocks VALUES(310326,'d6f210a1617e1a8eb819fc0e9ef06bd135e15ae65af407e7413f0901f5996573',310326000,NULL,NULL,'948ea2edc64ce5dbb03f9c6722a00ab53eba819832950bff1d690b5c70c04968','91feece7fad8bf1121bbbaac7aa173d6c841b1a272ad3b06cbf32176f12d118c','9e911f2e48daf32313a443264ad6ddbc1fde24a88fc672312b17a48ab6bd4b01');
INSERT INTO blocks VALUES(310327,'9fa4076881b482d234c2085a93526b057ead3c73a6e73c1ed1cdee1a59af8adc',310327000,NULL,NULL,'b09adfc57f20115851517b98eb97c8c5ad80297f85151e4dbaca6353201d1707','919d2adb7a4fd4f29a8a061b72ba1f72571adeb1b5d1d356bb831a71ba006ab6','920a3312fefb3cc62f2b4b470c14c87a3cdaa6e8c897dead0fa44cf03d080fd9');
INSERT INTO blocks VALUES(310328,'c7ffd388714d8d0fc77e92d05145e6845c72e6bfd32aeb61845515eca2fa2daf',310328000,NULL,NULL,'9627f2b5e5208834d5dbc1da351c8ad08470b52d71f047c80bdfed9621661f14','756aea7f20837a598ce1d746b79488c3d97a4bd9fbedbabf331b7b628e3737a4','779a6c22de848b9268449ef0cedc0ca8be3f68e93da779533b0a715fbe04a9be');
INSERT INTO blocks VALUES(310329,'67fb2e77f8d77924c877a58c1af13e1e16b9df425340ed30e9816a9553fd5a30',310329000,NULL,NULL,'82712bd1c280fc7abd85873a93592876419dabc8360ff331d23c54b3bfa9eb6a','6ca08600f787e45cc2c060adbff9cd2d3c355be3ab25f4a6c64f06aff03b5807','049ed064ca00fcadcc64a92c0cf0ddb740c8f620567207b7e3fff3c477f31181');
INSERT INTO blocks VALUES(310330,'b62c222ad5a41084eb4d779e36f635c922ff8fe275df41a9259f9a54b9adcc0c',310330000,NULL,NULL,'131af150751d0f50e48670b13e6436c94e29ac21d0f7a52590f0d198a8d4ea3b','8f760e7fe2edea2583a7356a5ff34785f645220b5d593df5d87a0c1dc023dcd1','343fc935b747be00710f6073ed5c41c9a83a481ce7971817a53469d44b9b5f76');
INSERT INTO blocks VALUES(310331,'52fb4d803a141f02b12a603244801e2e555a2dffb13a76c93f9ce13f9cf9b21e',310331000,NULL,NULL,'0de843d988da2e1be928468aa3a425dd8dc2a21e06fb7ceafda59a5fdaf59092','1e82c511e0349f57335be3679dd5a0a6cfda7e2c613b31458d55721b469aec50','79b429203eed2125b264a84044c06a17156ce48b771188f95f426a2b4295d0b9');
INSERT INTO blocks VALUES(310332,'201086b0aab856c8b9c7b57d40762e907746fea722dbed8efb518f4bfd0dfdf2',310332000,NULL,NULL,'0907ca32d9a8a11bafa124b6786563086ba0868c692ec9bb9dbb2dbcdca37c61','09704a38ecfdd96ecc21152040b30d8faa7e4fd0d9a3b441f59de7320d78b5bf','f85fc18bd8fb3406e0053eb4cf956617ca40d588f20a09583c2c68e8986c01e8');
INSERT INTO blocks VALUES(310333,'b7476114e72d4a38d0bebb0b388444619c6f1b62f97b598fed2e1ec7cd08ee82',310333000,NULL,NULL,'6b2805f5c8ce4b8a37ac3656d881d40b05b47cd977a5f0b21bf5f27db8acdec2','2b84350aa4222d8144fec19f36ecfd8d0c29d74e26db31952dc614f0e1d25a15','b73d2878291b5bb2c52364a78d965b3948af003bb0467cdb0c179be0de0e353b');
INSERT INTO blocks VALUES(310334,'a39eb839c62b127287ea01dd087b2fc3ad59107ef012decae298e40c1dec52cd',310334000,NULL,NULL,'62dd412081f9a5c69571c044f08e59788cefaa23539a8ad8d9fbcec375ec5b88','770f3eca8cce942720dcf2db0d60ab12090d3c64453fd6d883bd36c9b0c25b5a','017a6249d2dc32ba2c4dd726ff4701c62a505f43eb85c84ffe481f196a76b559');
INSERT INTO blocks VALUES(310335,'23bd6092da66032357b13b95206e6527a8d22e6637a097d696d7a96c8858cc89',310335000,NULL,NULL,'441152aa6b021a2c226823cfdb6803130b90844bc2c654c54f8dd9c2c944cdb3','eb215ab2e44c2ea90fc0a89287781e755883e45968f95f8fd28e2efbe801a8ee','6adffa8bd4bdda4d2ce26f292c7481694c2e80b619d1788a80042740ce784ee4');
INSERT INTO blocks VALUES(310336,'ec4b8d0968dbae28789be96ffa5a7e27c3846064683acd7c3eb86f1f0cc58199',310336000,NULL,NULL,'23a122673edab193c5a491b985b90cfa635866c7005d3065a318ec4b5d4db00b','e8f126593117042ab2f5282faa7ce6239b02491da310890cc9bd62c747961c59','b85bab199ef63a5fd7a85f84814b713aa8b392a3e038d03fa161591a4e122548');
INSERT INTO blocks VALUES(310337,'055247d24ba9860eb2eadf9ec7ea966b86794a0e3727e6ffbcba0af38f2bc34a',310337000,NULL,NULL,'27a13d3a3c20fc7e1fb7173e1cb87ff0fe2d20263b8d114e96746ec1d794d276','b76eef8b351a1308064d2d966cf8402e01fe17ee00f7c910acfaca1bef086eb8','1e9b9f347720ab0a719c8152d91c14a0da99d9a52b21c5242f2845f693d9e5be');
INSERT INTO blocks VALUES(310338,'97944272a7e86b716c6587d0da0d2094b6f7e29714daa00fec8677205a049bcd',310338000,NULL,NULL,'72f25d4cfd59822bc642c93b5b9b13627570f725a384438b61fdc88950434d80','1ffc2feca239eccdeabd52b7c8f67d465916c801cab58405f0de8ded6647a7d3','fdb799c7dffa078b7aa6d4c6701dddd3dfd43ccfead9d85e913f310366d7d679');
INSERT INTO blocks VALUES(310339,'99d59ea38842e00c8ba156276582ff67c5fc8c3d3c6929246623d8f51239a052',310339000,NULL,NULL,'b2262910025a114f8223d753af85ec2b98a3c90882360806759aec29bc99a5d9','e81a2c3a4370b02d6c5b02b882b7c9161eef5d1d8e75f6078b126689ba9b8d61','055a650b5c272b3430a85f2470716bf964c8ac3845b42755b6825fb3e2ac4483');
INSERT INTO blocks VALUES(310340,'f7a193f14949aaae1167aebf7a6814c44712d2b19f6bf802e72be5f97dd7f5a0',310340000,NULL,NULL,'373b59b3df76d498acb790a4a705e1d1e2eed6036490d22a5c1b6e8158e001c4','2d8d8b7452096849968a4caaf464df670bbb30b512c6d75cc1318529b80e8758','64f75a7834165b5ade386fc274683a4684f3ae579c561875d92c4969776f22f2');
INSERT INTO blocks VALUES(310341,'6c468431e0169b7df175afd661bc21a66f6b4353160f7a6c9df513a6b1788a7f',310341000,NULL,NULL,'3db007e663e9a961c879f834ebcd23dce8b3efae2074db1a708446b98e952c15','a67301ececb08983e663d1f19c04df735ccabf96c08e43896aafbcc85ac203c2','52931177d8b35eb860f6f29ec616310246926683da4fe7f4e019bb0f55f4d511');
INSERT INTO blocks VALUES(310342,'48669c2cb8e6bf2ca7f8e4846816d35396cbc88c349a8d1318ded0598a30edf7',310342000,NULL,NULL,'01d6ff3d6d09379532ec7ccc2cddcf802d931d7ded89fd7378f1f0f546e1bbb4','93f89fa9682a85aca6ff9043349dbe8e9b9f7302e209a701da8d0cffb5a3cd98','29ca21e4989a99cc9d457195e52dc9bb59188e7b826382a5e81c21c73a417b09');
INSERT INTO blocks VALUES(310343,'41a1030c13ae11f5565e0045c73d15edc583a1ff6f3a8f5eac94ffcfaf759e11',310343000,NULL,NULL,'9dcafdac205d44814fd3bde9b870d32766e36d85e78c0dbaf60146559ace15ee','94cee0ce5542048677ce98337d7112cb3a1e2e59fe2af6e6f9b0df83200b4311','0ca8d82eca3eaa7933176a03f84e127dbe98d030c0bbb54f6f93d34daf76b1fc');
INSERT INTO blocks VALUES(310344,'97b74842207c7cd27160b23d74d7deb603882e4e5e61e2899c96a39b079b3977',310344000,NULL,NULL,'277cca24bd46966d7415dc1c6b707f50b1dcb1f6dcc26322e02788cbb650ff0d','2cefd5dba14dd52c88482d2f9063ff1849671a16e2e234e7f3d171ec33aebe7f','a03e96d82c321b385d5c99f2ec60550f6166bdebd1aa5c466b2f5aa159111350');
INSERT INTO blocks VALUES(310345,'0bda7b13d1bc2ba4c3c72e0f27157067677595264d6430038f0b227118de8c65',310345000,NULL,NULL,'b9df35fcfae30c026d8f021a96090d7f1b2928e4f25700745902c7f8d0da4069','09a47a1a263ed4ca82658774f1384af42869107b8644166cd9ab26520e3664da','e70cdc8b180d2684d608c925e002e608252573636f23e8517ec78555e606f0f0');
INSERT INTO blocks VALUES(310346,'0635503844de474dd694ecbcfb93e578268f77a80230a29986dfa7eeade15b16',310346000,NULL,NULL,'0e2ae3a4d5b257ca24eaf15176e3e1b9424bad8026eddbd2ee4ec627d73a70be','705a970289eccf8861b50c32d48fae337ddb9565d871a661087e055eecc93d6d','4c85ae239829f158035ad6ba0c9faa7d143234da18fb252bfe9cf54c66ad77e2');
INSERT INTO blocks VALUES(310347,'f3f6b7e7a27c8da4318f9f2f694f37aaa9255bbdad260cb46f319a4755a1a84d',310347000,NULL,NULL,'294fff3ac9cd48f4e0e66ab746f6121e323ff776a86c0df560af0024ad831682','cfa3dea74ee5aacaf1d751214072124f835d459e4535e582701c4d3fd9379a5d','0507bca218b56498c6efd40366baaf9137b1596f6d3cf363a34bd8438fd6a5ee');
INSERT INTO blocks VALUES(310348,'c912af0d57982701bcda4293ad1ff3456299fd9e4a1da939d8d94bcb86634412',310348000,NULL,NULL,'12157e6ebe79a70d69408d061035c45ede1ee773f7e4bb7858fdbec5e4052425','62ee83cc4085c5f8302bbda4c55ac34634a5ff106080584d981c44d5cfa37a98','bad39370a6670d24891848ffeaee5026365c8161f5f438e3e5d39b7048c2e17b');
INSERT INTO blocks VALUES(310349,'ca911c788add2e16726f4e194137f595823092482e48ff8dd3bdbe56c203523c',310349000,NULL,NULL,'0cb69c8d250098e03acf86e6cdfade0e5d25571475856d8390fd63ddcdaffc9b','59c3774fe65096a2bc160a9b6fc1bb9a28d039ee43fa0b68e138d3c7cd1f8515','906f0df615116f9bd408b714f3a40ab4c5a7c6c444df51fdf6c281996b01f4d0');
INSERT INTO blocks VALUES(310350,'c20d54368c4e558c44e2fbaa0765d3aecc8c9f01d456e3ff219508b5d06bd69d',310350000,NULL,NULL,'e7403f90b730f64ebc274787572cfaf998f4831a75e8ad6acfbd4fe160ef1e9e','a500243f8d9e9a8cfee1a586abda4494f6ae5889599ae8255dddd50516950ec0','018011d7c45f01090e2e008cad527ea5fd8c87a02bc90d83767903a159cdf22e');
INSERT INTO blocks VALUES(310351,'656bd69a59329dbea94b8b22cfdaaec8de9ab50204868f006494d78e7f88e26f',310351000,NULL,NULL,'a92e00eae7d25de3e7cab06c525840070ce26f87eac1d3f6f038edff7dc347ec','efc3162e7acacc5d2359a9203709a20f577c200e654082a5d58c2d38cc3d4c22','263f1b6886197c409334f6f97222755323ebfe760936ec7f60f9a550c4dd8fc5');
INSERT INTO blocks VALUES(310352,'fb97d2f766a23acb9644fef833e0257fdb74546e50d9e2303cf88d2e82b71a50',310352000,NULL,NULL,'9e8c714e7e8b8dd35d35018dd06f3b0d740e4b313f956c8c188b4112943c70a2','29a9199e3c1e17ed1a6bc63d938e94cb1b411ad6652dbe2505e94d5a7ffc1ca4','0b694245898b11169914fd1dbe6a9341a46e12709490a0ded27b8cce4d03d512');
INSERT INTO blocks VALUES(310353,'2d3e451f189fc2f29704b1b09820278dd1eeb347fef11352d7a680c9aecc13b8',310353000,NULL,NULL,'148bba0d79a8f9f00cb46a742059b7577be21515a6b0c912704db715ab720188','76e7df06529a4c6769e58664abb08b43a3e771afcc98d9c21d46bcb4956b873e','6c027860da784090a51cf7407606df640bdc1e1361a68103e28f593d61d03838');
INSERT INTO blocks VALUES(310354,'437d9635e1702247e0d9330347cc6e339e3678be89a760ba9bf79dd2cd8803e0',310354000,NULL,NULL,'02566147570b8fbc5f2fec01182ae77d155f4b4417c54f906831a388084f5c54','7e63843e43366e3b486f88ffb1c8c922df1383c5f39577360ffdd44a9ea2bb9b','7496fc6153b5d898f6e54120a7ca020e2be3aba6a3b111dd840c80209d8f3ca7');
INSERT INTO blocks VALUES(310355,'ea80897a4f9167bfc775e4e43840d9ea6f839f3571c7ab4433f1e082f4bbe37d',310355000,NULL,NULL,'b7635f070eb39778f70aaf38c1b6067c8b8d013b4c811400e7b4ce1e6b99a8e5','8a9788a05376019a3f117504d33c830a688ec86afff346f16576d071e13f786c','2e5f620e7ce624f3f4c96f9ec484b92063aea18a4a4f81cd8474ff6bf504a9a3');
INSERT INTO blocks VALUES(310356,'68088305f7eba74c1d50458e5e5ca5a849f0b4a4e9935709d8ee56877b1b55c4',310356000,NULL,NULL,'01c17ec89649efbab959e6f8573ebf463127b946fac79f7e1d0c3d2ab43711a7','2353dd8e575437d7d1991ec04bbaacc278d54007b8c0ec1ed316d6ffc3b9e953','b6e51fa9bd40f4211b8f4a58e1aa0bb723192d3ed715b33feac57eb28bef3697');
INSERT INTO blocks VALUES(310357,'4572f7f4ad467ef78212e9e08fa2ce3f01f2acc28c0b8ca9d1479380726bab1f',310357000,NULL,NULL,'7492a4f460fcbf40163bc43b18cf88eb2bfeb91745b6d0c1c9bc2c8eb6967700','8f6b3851c67584b4a9061935814376a81862e518ed248886f9d04f6c37d2eb45','d637967046ce1cbdd403ba583108dabc6ad5afbfa86c5c94d37fba8ccf60de16');
INSERT INTO blocks VALUES(310358,'d5eae5513f1264d00d8c83fe9271e984774526d89b03ecd78d62d4d95ec1dea6',310358000,NULL,NULL,'4bad0ccfdf6f0a3fa513db46358a415a71e4ac8a82984df05f167f6d81c8ce21','835dd6fb35af6daaa29f49105aa990fe142618385e29e8d908ae6f4c175c910f','682da72f7b9c61b4c876904e74c5b2c840fb401e4d007412aa941e84cd08676d');
INSERT INTO blocks VALUES(310359,'4fa301160e7e0be18a33065475b1511e859475f390133857a803de0692a9b74f',310359000,NULL,NULL,'0c7c644e1edb3fc88d679da8ccc9011462d30eba7e54a84cdf9e8741ac6114a3','839003bda94ae8b5d9dc807e63e7afe062a0dbc1554161b8fca108d05b903174','9fa2a5b5a1d5ccf711628edbf341b575be0feca21eb02536d99ca827b6f9ed1f');
INSERT INTO blocks VALUES(310360,'cc852c3c20dbb58466f9a3c9f6df59ef1c3584f849272e100823a95b7a3c79f0',310360000,NULL,NULL,'af28473bb210131e54c0c14a9d02c6575f6439dfa1f161550d024e5b4846b15f','458db26967ac3fe240c0054f33d568148f5ef6307c979784596f8c9bda7eaf91','50eb15961f553dff9135001bc48a027d0eb665f34ed80aeadbd632674c3ce1dd');
INSERT INTO blocks VALUES(310361,'636110c0af5c76ada1a19fa5cd012e3ee796723f8a7b3a5457d8cb81d6c57019',310361000,NULL,NULL,'be09bb85d95e3d3c862523f71203b02e3a7103572bd913ca74eba356f090df8b','69f70934e8ea014aef53846ea9261d80c0a2d4cee7fdfa64acbd4505451d4d95','5cb498aee5240a13812a45f25211c48f783f144251fd51af65b603a64561837a');
INSERT INTO blocks VALUES(310362,'6199591a598e9b2159adb828ab26d48c37c26b784f8467a6bb55d51d7b6390f2',310362000,NULL,NULL,'e3020fec84d375059163332e89e53265f29ea77034be12491a2fd677f82bb220','07fd6afc1856f2bc945e8913413eefecdeaa174ba80d38f04e4986a331e9f1af','27633a7de1444aa099fd27ff85b26ad7af1cd2290c2b0116d572b346bbbd2f6e');
INSERT INTO blocks VALUES(310363,'a31967b730f72da6ad20f563df18c081c13e3537ba7ea5ab5d01db40e02647e6',310363000,NULL,NULL,'c7653d448694cb55b3cbbcd29bc19b6c2a7a9e1c243a4b1c738e937b730c5cac','1c25c90f1ec246edefb24c2601fadc47d9e7689d6b14e7a41edf204d1ba1b6b4','d07094b7884542552d0c0cb5e13156579a07b370b0f7ec3f1055bb71150e694d');
INSERT INTO blocks VALUES(310364,'67025b6f69e33546f3309b229ea1ae22ed12b0544b48e202f5387e08d13be0c9',310364000,NULL,NULL,'b62af35e4826ecb9e71fa321a85bd81f0b6dae43ba5c4a20a523b3c1c3c72c36','1b3a054d517def0f7e5f380099930a98c2b05115c454365cf3446977ad49dd43','3a9334914e4de87c10cc7e8a7341e4f3df99709a96f7c28ec4ed533cf9cac8b5');
INSERT INTO blocks VALUES(310365,'b65b578ed93a85ea5f5005ec957765e2d41e741480adde6968315fe09784c409',310365000,NULL,NULL,'001e207dca77f0124f059ab2110eaf39bcdcf40e5cf961b9083fc54fa1f18d43','e679011ae48bf1e1a805d9ff7572347da121fc4b3d8886eafbf3c29cfc0fa13c','e345ceec714766a7c43c6d93a6e34767f4043e03c8975a2f20efa87ed7f489ed');
INSERT INTO blocks VALUES(310366,'a7843440b110ab26327672e3d65125a1b9efd838671422b6ede6c85890352440',310366000,NULL,NULL,'19f15b9800aacf48ad823ef21fa90a9bb1968a7f92a5918bc12cd1f90359ce49','5848dab640c908da0af2a6417ee8deee3b7c5aa59f7c4b3f49d5149b80fc395a','a93fb79bae343e80e551af6914767c4570ce7b6bd890dd86f730dc938cd573de');
INSERT INTO blocks VALUES(310367,'326c7e51165800a892b48909d105ff5ea572ff408d56d1623ad66d3dfeeb4f47',310367000,NULL,NULL,'e4716e2c3e9fb93cfd6e836e7b9eb5d3bd9105271498e64af62c1ac978166829','a008e4af6c6a982b5e9381c70586e919c087c46b8b4ad2f4113ba831d192938c','318b97948807360cdb86b6386b6e51e923107dc3191e94955966fdda86b86347');
INSERT INTO blocks VALUES(310368,'f7bfee2feb32c2bfd998dc0f6bff5e5994a3131808b912d692c3089528b4e006',310368000,NULL,NULL,'b871ce9a0a4973f0bd3bf22fa9151a294e0541aad7f84a90790934281240da7f','527c7c3d901d44514c0fd183033b2695d1da15e371e0fed5b949949eb6a05169','2e70d67317d07d95f874da9388ddf9e7d0cbef7c118b0fd7d980b2122d66446c');
INSERT INTO blocks VALUES(310369,'0f836b76eb06019a6bb01776e80bc10dac9fb77002262c80d6683fd42dbfc8da',310369000,NULL,NULL,'d50628955fbff5c2bfcc72ab9021e237f76f63911ebdb676bb4504c48a47a25f','540d2c926046ab6cd0ec169cbcc6ef60c736ec6997abfa4651fccabe7e56cd96','7412f8d452f59717f9e43304a5da2c3bb87ba63f0e694f250e5c2461ebf082f2');
INSERT INTO blocks VALUES(310370,'9eb8f1f6cc0ed3d2a77c5b2c66965150c8ceb26d357b9844e19674d8221fef67',310370000,NULL,NULL,'bb96a5bd0fad66277699cf6fc1d7208d75d0fdab796972d6a34e2e91948c2f42','7147100febf53eecccc9cf57247ac147764f1e55568860d13a8d5b10b4931f0c','95d4d9096baca6cf3c3b0e41ef30354317ed8a9f01a1bdafbca19bb59af9c107');
INSERT INTO blocks VALUES(310371,'7404cb31a39887a9841c2c27309d8c50b88748ed5fa8a3e5ba4cc3fc18310154',310371000,NULL,NULL,'e3f229b345b31a14ab3659e5a254ab2cf9500a57d90f92d2fa442ae53629b477','86db1ad29d69ce6a8e66b0f8c705d23f82bffdd2978593598b4049560df8a3af','d968d3b003fd4edb22da5c706a58c0a962e212ad0b9400a73ce0ba7226c7c8c5');
INSERT INTO blocks VALUES(310372,'d3a790f6f5f85e2662a9d5fcd94a38bfe9f318ffd695f4770b6ea0770e1ae18d',310372000,NULL,NULL,'0415dce35d6303ab0614f794275cd39211cee16cbeef2f40763c065b9fad6030','7689e9ac40835d378c8323c5818222985663c4c8d72dc424abf8ec74cfdb37e6','f231a78322ae1942cac0df0b23ea7a52f09a439b9b1b3356b96810da707f72e5');
INSERT INTO blocks VALUES(310373,'c192bec419937220c2705ce8a260ba0922940af116e10a2bc9db94f7497cf9c0',310373000,NULL,NULL,'0cfa727f630450b6ef6c424cf57761e46a81529aee6e779bbd6eff36b65e7b86','e335759e4f8c2de36dc46d933ab7d40c44854f8cd13dd53ea753d64356fd1bcb','9eb0f5929f7076c46ed4df42026f05b56bb0d5f6e9326e4762fbea95893d7e01');
INSERT INTO blocks VALUES(310374,'f541273d293a084509916c10aec0de40092c7695888ec7510f23e0c7bb405f8e',310374000,NULL,NULL,'6b6fcb8a249725a523a4f160442576861de6d7469418ed0e5fa0f1bb1900ac75','a2a4fcbb5a1b3b0bc74da984ef193fb94e161f647356d2659fadd3c6d263d314','e113902be5ca589aff52d1f36ecaf3ce68b12af9dfe9b2ced936fc0d1b373a83');
INSERT INTO blocks VALUES(310375,'da666e1886212e20c154aba9d6b617e471106ddc9b8c8a28e9860baf82a17458',310375000,NULL,NULL,'03b0500e6c5bd8aa88d8f9f015b352d3d20c0dccea0d439d32fe84bcc0f72407','1ea1b2d3a9eb2563776e50cbb2d111f05ae93d5a842dce50f4865f91e80e05a8','b8305d4c64cd670dd828d2b13ad0f217b40f1eb46600979a936a57c1b04e1d32');
INSERT INTO blocks VALUES(310376,'5dc483d7d1697eb823cba64bb8d6c0aded59d00ea37067de0caeebf3ea4ea7dc',310376000,NULL,NULL,'31db550836e580aac36f66bfd9a9804cdce8408d66eefe4f7267d2ffc58b2cb3','73ace1a7c572d68d56bf3a4c017075f06ebbd8cd079b19cbcf0069c252d63408','af4d5f2080e253d0a67dd47d4e01826c97b149e2444049b153578c5ec54b1a81');
INSERT INTO blocks VALUES(310377,'f8d1cac1fef3fa6e7ad1c44ff6ae2c6920985bad74e77a6868612ee81f16b0b3',310377000,NULL,NULL,'ca2d362030e750f2efb5213cc5114365826e3b9a4b428db2da7b0ea648f5c5d4','3b65ab60e533851f64746f717ea8d41e6e12c069088b48e3a13ff4bf2bb47d00','49bb45c3bd24e8ed74f66931be0ee1806ccab69eef15074c2ecf9f51523993ae');
INSERT INTO blocks VALUES(310378,'fec994dd24e213aa78f166ca315c90cb74ee871295a252723dd269c13fc614ce',310378000,NULL,NULL,'6d3927b06fd6dbaf48e99a07d0b12d3eaecf3dab8acc8cf404ccb06b3fe820bc','ef1eb0711a5c94cdc9083ce328b91bda117aefdbcc272a325b3aa21ccbfcae56','290bd407c13818c6e43fa3bb3d05a4f1c2540b5438153b6a14c1d27eb63203f8');
INSERT INTO blocks VALUES(310379,'d86cdb36616976eafb054477058de5670a02194f3ee27911df1822ff1c26f19c',310379000,NULL,NULL,'c87576207c701a3f652d08973b4882e008042a4ce7f977a418ebd4ca2578486e','341468c205ab2d0219540cee5649401ae796591706cdc9ad2f75db27ba8ddadd','cc077d3f5429a41a052c1917642c05ebeaf33cb23e961ade4136e3cdb8951a3a');
INSERT INTO blocks VALUES(310380,'292dba1b887326f0719fe00caf9863afc613fc1643e041ba7678a325cf2b6aae',310380000,NULL,NULL,'42b94df76fc18a2257bfdacf7b37fcf280f9753d0e02be27fb7f5cbadc42f668','cd37f82cdb360a1f52fd3fd64bb5863d86a509daeed34c9e07ce2fd0627f7021','5eaa4c8459ae935e631fe54b08d4c2a08c03ef0b0b04b65efd8b4b3e4f44916e');
INSERT INTO blocks VALUES(310381,'6726e0171d41e8b03e8c7a245ef69477b44506b651efe999e892e1e6d9d4cf38',310381000,NULL,NULL,'957f3e749ae746f20aa21542c3cac0d0898cbf359cffebc53e60acfacaba77d3','7d8242ece96303300a0492f5c050908e32395de29d47269087605b659362204e','3e9551180d27b869dc911345d1977c8e6aa77c7f29a8a5fa555e2075cded4292');
INSERT INTO blocks VALUES(310382,'0be33004c34938cedd0901b03c95e55d91590aa2fec6c5f6e44aec5366a0e7d8',310382000,NULL,NULL,'491ad1dd4d8ad2672413f491cbd5256fca0e9eba6fee571cd90f123d3811fdfb','c766a4e410ea6c91a0b1c59387b3201d40b7e7bbaab77f76b0518ae714e04795','851cb051f7ecf47bda3092f049cc8dd6041e711eefe87e75820b0e9852407e42');
INSERT INTO blocks VALUES(310383,'992ff9a3b2f4e303854514d4cad554ff333c1f3f84961aa5a6b570af44a74508',310383000,NULL,NULL,'4ff64c543498929a68fdd10db91fe2189c8d3d40c48de39755bd3f61ed15358c','48ca97a2ba5b0cbf9b1e842bdf5a1ca35e309e6f32cae457ed432ca5f9b0d7bb','f728afcb08ffc459dcea0b518c36703835bc5caaa06fca0f812d95906e4e6e69');
INSERT INTO blocks VALUES(310384,'d518c696796401d77956d878cbdc247e207f03198eabc2749d61ebeadee87e5e',310384000,NULL,NULL,'fe347a206726793b37e48da9d0975eb275ae7b0ba126e925008c58ab5f74552a','729549c4183e26de4c5889e3d11ca02c57112c9ddf356a7e9627445c5ba75936','de3a9a803d735398835f3a95f004b98015b178c31127eb27333eed97d01f3353');
INSERT INTO blocks VALUES(310385,'2aa6a491a03a1a16adbc5f5e795c97ec338345cfdf10ff711ffb7ac3a0e26e28',310385000,NULL,NULL,'f1fffd59e8c6a76217ef27c784ff9780e3487b6b4e17f237a0fcce0fbf7820fc','df0a9c3d11101e9bfee37c854097a69e4ad991271738abf081d657f80fb45329','9003cf7f2de2cec85928069b0d1e942c42b69c55a9d52215e4d82b80e70ffebb');
INSERT INTO blocks VALUES(310386,'9d19a754b48a180fd5ebb0ae63e96fa9f4a67e475aeefa41f8f4f8420e677eda',310386000,NULL,NULL,'f9315f0bd24567ba66a37f6d281380adef1ced3012a8d7289ddca55c827208fe','27bfb6f0cc739e55b39a5b24346f35e1926a7b595addaffa6aed62dc4e9f3827','d02b1cbca75f99772e735a77de7ee27cf790a25594c69ade27528df2076d80d6');
INSERT INTO blocks VALUES(310387,'b4cac00f59c626206e193575b3ba9bfddd83bbfc374ebeb2838acd25e34a6c2b',310387000,NULL,NULL,'4ecfab9dfd562af4a8f7ad5ca76a144ef39d71c1e5ec01557359480d13585dce','341afa6012ab9587b474bec4d0e446e1b280f89b4e23e7212770ab06c9787e3b','84923a9271f353b018200758854aa1008c8d32000c1765519af82c4037cf8016');
INSERT INTO blocks VALUES(310388,'41a04637694ea47a57b76fb52d3e8cfe67ee28e3e8744218f652166abe833284',310388000,NULL,NULL,'320e5e43c4a16791b9d6082521532949ceb177b05958c9402e79a3fd0edd16ab','2a4d3224784a329f727d20e04f868d01bcd9557d63c7e2f905ffa7c6d5afd47d','f6529c7405b9ae2d369a7bf75d05b37f8c60ebd0905592b5c15b7bec6f909ae1');
INSERT INTO blocks VALUES(310389,'3ec95ae011161c6752f308d28bde892b2846e96a96de164e5f3394744d0aa607',310389000,NULL,NULL,'772b342bcbe1ac7e9f57d61d9f24693f3af2e080ecd71dc50abc8c535f44e548','a7a3e17f5c3ecc5b3d4317a0b216bd78b9f3b0e7c00904590d4e0f3909b871b9','c84fbc7fc24bd8e9ea5d2d996f94410103e3f266a8339f33a42c956da669ad0c');
INSERT INTO blocks VALUES(310390,'f05a916c6be28909fa19d176e0232f704d8108f73083dded5365d05b306ddf1a',310390000,NULL,NULL,'c36f59a10834eca1ecff19f27eb669ba4e7bffd14737b1e7d75e79ae60d6de1d','2ae3c2012e5f8f38f084b59f79f17f3a7af2e680d1cb694c7ff119a5963335cb','8420a94363316365ee8c2dfa728eafdbb3789a93ed92efa8ba18e32443ac659c');
INSERT INTO blocks VALUES(310391,'fc26112b7fdd8aaf333645607dabc9781eac067d4468d63bb46628623e122952',310391000,NULL,NULL,'2fa684ed14727106b6d981826882f8da19d3b45a4460dcaf42b548fbc888e619','137fe59a317ca7bc37634f996757dad1711e921e6d4a86d628db16efab6f73c6','0a850ab60055ebc98930b150e03ed9fbb3d5fd69677a4fcaac59abc393c26b24');
INSERT INTO blocks VALUES(310392,'f7022ecab2f2179c398580460f50c643b10d4b6869e5519db6ef5d5a27d84a1d',310392000,NULL,NULL,'1411ca5cc2cc8753c04d309a154f5795bab56297b7d777b90ec8b194c8934e5b','479c676ad931b229f51368c50baa7ce428d913d1992a323604df35707f4d1657','1414b4342fef7c06edf0a00c4b3b52a56af3cedc33916880ccd1a7e5191ffc3f');
INSERT INTO blocks VALUES(310393,'e6aeef89ab079721e7eae02f7b197acfb37c2de587d35a5cf4dd1e3c54d68308',310393000,NULL,NULL,'ededfe5e47ad23d19a1de45285885fa0ac6003e66fa894e90d881a768b860f33','856fed296a7d599df1e5ab3e4bac1240a95b629f5c16104fb93ab60536606008','f28795923da1a258b87bcc42f8b2b0a8c9361309f184a0fc2d63b1d093930fe3');
INSERT INTO blocks VALUES(310394,'2a944743c3beb3bf1b530bd6a210682a0a0e9b0e6a9ff938d9be856236779a6f',310394000,NULL,NULL,'c407b7b380f3af2eff7182a70179fe2926a0dfdfc02470c67a3f6a1455a57c7e','fcfb549795ae81f18f086a8a6f3fecfcd55864106e80ee4e7cc76b2ac1044500','f06d85ac8b667992687b2cce048b65af0283157b53ce84109fb072f3fdca78e0');
INSERT INTO blocks VALUES(310395,'19eb891ce70b82db2f2745e1d60e0cf445363aaff4e96335f9014d92312d20e4',310395000,NULL,NULL,'b7083be67ee9a11ed4ec0c871a420f26122d01ad620ae83920d7b1d57d7ccdf2','123b7ad9d3623f83cf62251f243f81d135a630db51d6318d486df21d7f89ce01','d43765e9e2aecd464b7529ba39f9f7d14001322bad8368dccb2afa43161865c2');
INSERT INTO blocks VALUES(310396,'aea407729ac8d8e9221efd9d70106d14df6aaf9f2f87dc6f490835a9caadf08e',310396000,NULL,NULL,'027d08ba8990c4d67fae099d7e41668e252fcba175d918c83669ef7fda465402','1d78b94a0135763a1162fcce77f2ed7ee668d2127cec1d7c79ec0e5d97467033','de41116e545f1a41bfd42ffa3fc487a97d38aaa8cdd4ba1033e24728d535c7ad');
INSERT INTO blocks VALUES(310397,'7c429e56a19e884a8a77a759b52334a4b79404081b976270114043ba94d7985c',310397000,NULL,NULL,'8709409d572babc0f8796506122189dc39af821fa2b306714c5594897fe6c617','b054d136045c9d31ece44f79c186145007299e565b2f69c5261025833968c9f2','f5a61c247363c365a2e590808b61516bc2d5461338394dd65deef48eb5f58685');
INSERT INTO blocks VALUES(310398,'55c046db86dee1d63c0e46e6df79b5b77dfd4ab2ff5da79e6360ce77dd98335e',310398000,NULL,NULL,'25f2bf6cb61ace8901184de9dce5d721e5abd5356d7a1dd5c3ec6f544945778f','90805e7563644023aac54e2df9c7de8e28474d038ffcad610bc461e43601df06','4d07b3d8c63c896718af9e3d845540c4ca09dd1611c67e085801201d2802d47f');
INSERT INTO blocks VALUES(310399,'765abc449b3127d71ab971e0c2ae69c570284e0c5dacf4c3c07f2e4eca180e7a',310399000,NULL,NULL,'c9ad6cc485706509f2702ddd725c8218fb51711658130a492dd457f43d2628cd','37d7a96c26f354793538e8d8902f3d988c042e33d10a26ffb975420af3dc1364','2596bfad4276a4356a7c21e87429963db67d5aee8dbd1272480cf3057e39471b');
INSERT INTO blocks VALUES(310400,'925bc6f6f45fe2fb2d494e852aaf667d8623e5dae2e92fdffa80f15661f04218',310400000,NULL,NULL,'47699a5f6feba6c4dee72640859df50fabe74fe82afd1d8a01d55324cdaf7daf','ae5f9af4e95baf4f2fcd9ace66bffe4f882abba23eec06fff10424dcce361451','9071a652dfd3c684974cba442b4b3b6c596341e9b9d01398ff8266a20eab0ce4');
INSERT INTO blocks VALUES(310401,'f7b9af2e2cd16c478eed4a34021f2009944dbc9b757bf8fe4fc03f9d900e0351',310401000,NULL,NULL,'7c72b293ae63858aaa34792a4a4656626125b7007c8b7e37f91ba6c54dab5294','e66d76c558c4e816a82486ac27039e395ab1309c33fb309b06ef7694c981e9e6','655ebc73dde46dea109e92d8122afcb66c27577a2af1d92d2be5ded17a6cd02a');
INSERT INTO blocks VALUES(310402,'1404f1826cd93e1861dd92ca3f3b05c65e8578b88626577a3cbad1e771b96e44',310402000,NULL,NULL,'cffbfb6e24c737132b2f9e9af751655e1c7711c40feca489c28706d09a32971a','2afc5a959a4253f6474d604d87e04e12dcba54f5c90ce1348d75b1848163ca88','8e127931ca235f4c3e4f36b2cae55fc0b08c174bf4098ae11ff76d49a3ed3683');
INSERT INTO blocks VALUES(310403,'f7426dbd4a0808148b5fc3eb66df4a8ad606c97888c175850f65099286c7581c',310403000,NULL,NULL,'7c2e4f57bf29a1b8179ff00121fdd03c53d6f350043b25a77ee5be2492b4a0ea','f3130b04996266c96757e8a735b2a20983f94384528e5e3f6c2806f81f4a1c96','1fa1712134e5b5c647f3bbd1c6b6456683a33bcc070923ea92afb7cac7595881');
INSERT INTO blocks VALUES(310404,'401c327424b39a6d908f1a2f2202208a7893a5bedc2b9aff8e7eda0b64040040',310404000,NULL,NULL,'0bc216028ff6f0de3212ef3f9452e6236ac76e318d923678113f0dd4db326cfe','f54c89059ec2336946f41efdf58b7a2b3c6b8746536421b88922f27abf089755','850342af9dec02518b91b387d67cb0f05e5ba95ce99064a38dfb1637a24f5534');
INSERT INTO blocks VALUES(310405,'4f6928561724e0f6aab2fc40719f591823ca7e57e42d1589a943f8c55400430a',310405000,NULL,NULL,'b8b260339e340da49674d2217a4178c2fc183f3fa0a17898e4d51c70c36540e5','7160f2a0c4ab309d5df7039f674ac2111d3a79179d0ae279971139300f5565f1','73cad67c6e3e8627139af861404ab03f2f7b6e20a6b4f44e39f3daccf00b36ab');
INSERT INTO blocks VALUES(310406,'6784365c24e32a1dd59043f89283c7f4ac8ceb3ef75310414ded9903a9967b97',310406000,NULL,NULL,'8b60b85abe87af29b7add953b47df4728685e61efdc517202ff27266c07f51be','445cc3f85e78fe3d9c423629b75cbb90868225ce819922aa5ccd762d3e9d5669','c6755882f1c8ac8fbfac03ee0f0ae7126a7f98aaa68a98d05b159d5772c927e8');
INSERT INTO blocks VALUES(310407,'84396eb206e0ec366059d9e60aefdb381bca5082d58bffb3d2a7e7b6227fc01e',310407000,NULL,NULL,'ced6bfa84dfe0c127b978539278c288512b138b455edfaa59b636158547462cf','ac6a66fdcc679bb0faa521bc679d6f9eff31a937b9b6d067543d45fa40ac62c0','7a11abb1832bac005635332edcf62eea91ef2f1df1d4c6b70f6716849f1dee43');
INSERT INTO blocks VALUES(310408,'4827c178805e2abae5cb6625605623b3260622b364b7b6be455060deaaec2cda',310408000,NULL,NULL,'21df39e3f2b521dbf4c56db49876caa9a5b775f14904c0bbdaaab5131a757333','7f8e45e6e5ab7a67be361f1a31c0e3795423c64fe84f21aff15452c5a44974e2','fa784806a8081d29bfd27610da72a346132fd74392ce3e948195ab6753697364');
INSERT INTO blocks VALUES(310409,'01a719656ad1140e975b2bdc8eebb1e7395905fd814b30690ab0a7abd4f76bba',310409000,NULL,NULL,'6dc8f78db038089957b80b10b82b5de040ae71e35f42d6768c7cab68212fdb07','d440227e361fd92ddcd094458ab940fe071201120a8db6b1e5030081d39d8f8d','d006fd9de577ca509f223cb1b9aa28fd27554eed4616b64f77488b7b1ec16029');
INSERT INTO blocks VALUES(310410,'247a0070ac1ab6a3bd3ec5e73f802d9fbdcfa7ee562eaeeb21193f487ec4d348',310410000,NULL,NULL,'70c2b3a68667d93ad9ea6fa30d1e460c93ae7bf29cc9f1c9c7d9ea1faf4e405e','cf84e6f8ef0037d5aebf31dc185b3a09048ecc2d8707d8733865b338830eab03','a0ad12a566fa11b64921a7420ec55028145fccf3ccd757c0fbee7ac7add17cbc');
INSERT INTO blocks VALUES(310411,'26cae3289bb171773e9e876faa3e45f0ccc992380bb4d00c3a01d087ef537ae2',310411000,NULL,NULL,'ff9dd691028e8d6496287b13fb553feaa53b5a06aedea4380c583f8d7e2c55e2','06f335a838831ed73315b4d2552a93b40366903a7a940e8d8283e4bef43a4a97','6b1a45b09cc7f9e795551ab5dfa5e3f4ac6b0f04b1f4dbba4d70a4b576288a40');
INSERT INTO blocks VALUES(310412,'ab84ad5a3df5cfdce9f90b8d251eb6f68b55e6976a980de6de5bcda148b0cd20',310412000,NULL,NULL,'650d987e2e0c17c1608cc26fdf2c25ee77254c6430f7d35dd5ab6769dbfcfdcf','2051fd27a616f16797442709c0106279f635aa26e385879d5638c9731bdcc9a1','cdb9d5c950f61be1300430931fe2ffd0abae98e43f68b8b98a721eba330d74cb');
INSERT INTO blocks VALUES(310413,'21c33c9fd432343b549f0036c3620754565c3ad99f19f91f4e42344f10ec79bf',310413000,NULL,NULL,'fa4773bbbf2f1388d21fbdbea0b886fd8ea6bc5c425d8244ea4ef2a1b58c9efc','db9da1c1848fdef5358b0cb472eece6bd6324522182ecd96895c2d947b4c98b8','a52a62e8a09a98725ad05fb75d0bd8c7ceda80432b20090f420c4758e6027314');
INSERT INTO blocks VALUES(310414,'8cff03c07fd2a899c3bcf6ac93e05840e00de3133da14a413e9807304db854b6',310414000,NULL,NULL,'8bc5f804dbec134d0ce32ccebd489586e688a2baeafe23dbf6331b8543aeef10','e1e3455656472cab93863601fa10a65aafe0efaddfb1066f64f8c5e983bff153','074e5a495505d984c5ef9255f62679c27ceca27ae2ba6225f232a36cd3fe7f51');
INSERT INTO blocks VALUES(310415,'dd0facbd37cca09870f6054d95710d5d97528ed3d1faf2557914b61a1fc9c1cc',310415000,NULL,NULL,'995ff5dcc44e8945823982098bb976a5cc57705fa10de7fabddd47b3c5ecae59','3126f88cb305ff71db6aa5478e7a838a97ae85974f73bf6bb3bd72c515f12bac','75a5b7f5be1c1c833bc72900ccd753d886766586878c000dcb9f7f88e407bc72');
INSERT INTO blocks VALUES(310416,'7302158055327843ded75203f7cf9320c8719b9d1a044207d2a97f09791a5b6b',310416000,NULL,NULL,'c7e9c253951cd812a237ca07730f308eaaed975e8256eb0ea1fe2c212fbd68f3','024ae6132d401ae65f0d299ac9294a2a31f0e2988708c3dee44a8038314a3d2b','1950b58ce42dadd5c800412f61b72ea62f2c574cd80585926877dc8681d32f75');
INSERT INTO blocks VALUES(310417,'2fef6d72654cbd4ea08e0989c18c32f2fe22de70a4c2d863c1778086b0449002',310417000,NULL,NULL,'717c2ce338e6b0bbb46148849e0bc897c5bd9e6764fc2e21c54e8edb0f0bd4be','439106ac57869e5327ea02bbbb382644b0c7ce18f2c347dd635e598b953f3c96','b1c74c6b3bdbee3d129d4983d4b6fddce584183de1a4a18ad11d626147d99feb');
INSERT INTO blocks VALUES(310418,'fc27f87607fd57cb02ce54d83cec184cf7d196738f52a8eb9c91b1ea7d071509',310418000,NULL,NULL,'4c4fa6366c8650b32e08166c413f599956e26a5fb0b8384c5ce092dcc4b7dc37','13ce8dfc748788334e76ccd21952987cf644678eea6448dce8af9a69a0fa2ef7','980e4a88af954ebed24c1b591d00828a5fbc03f178aee1038a2854d9c55f31b5');
INSERT INTO blocks VALUES(310419,'9df404f5ce813fe6eb0541203c108bc7a0a2bac341a69d607c6641c140e21c8e',310419000,NULL,NULL,'7ece8fe8032b013f315e576654f935f581461c6140eeb5e92f92b4119b6c9d1a','59eb674e9084262d78b87e42501429451a76aca0a0d61d4ace0ad28ddcfde9f5','7c1c5b27eb8ac3e779b8e49c134dcaccd0c559f0717b1d09644f23411e54c5a8');
INSERT INTO blocks VALUES(310420,'138b3f1773159c0dd265a2d32dd2141202d174c2e52a4aeac3588224a3558372',310420000,NULL,NULL,'ae18b56e04a0da3ec6854318dc18147d9c4583d2043f596264127bc5349ff3f0','3a55a28e4b4b81758b26191584e550dc185f0cd173121c8e2fa8cdfff8e85289','0649fce5ae3faca4bb7f955eb86e73fe89e71313dfae37ce30fb9232087d1da4');
INSERT INTO blocks VALUES(310421,'71fe2b0e02c5cad8588636016483ddd97a4ef0737283b5fd4ab6ea5dc5c56b9a',310421000,NULL,NULL,'d9e99f40b5da72183528f169e9916b8544186bde2cea7d9f7b4f63cf16f273c9','31735d5685031031a7a6191c561d7ec35f4c0e90f22920e09c7dacd219bdba19','707557af8a25dcd41c207054d2a2655adf40266d8ea73a6416cf1c7cb377cdaa');
INSERT INTO blocks VALUES(310422,'cd40260541b9ed20abaac53b8f601d01cd972c34f28d91718854f1f3a4026158',310422000,NULL,NULL,'4e3262899c82f10ff4b96eb0c22ad2e824a0b2529fdcdd30e09a5e6a0a76d25d','03ff26ba6ab21d09f6cd2e54e391bde384b96e27cab2486ae6e758d74f7708ee','2d02019be1799adf3abdacba5f3c9e1ed6aed82a1dfda62167e038c8e1dc2870');
INSERT INTO blocks VALUES(310423,'6ca0d6d246108b2df3de62a4dd454ff940e1945f194ba72566089f98ad72f4db',310423000,NULL,NULL,'265baceabcdeda3c1e81aacd24598ae40ac4dde6b05d8dc99bff500ec5314eac','4e2806b6b564f2fe2e93e6d27f277e83beb2095a0548a7a6a1051201ba733210','87976a43b73a79a5dac2b6b3760f281fa4aacbfb9b2a7b545fa2b7d31989956c');
INSERT INTO blocks VALUES(310424,'ed42fe6896e4ba9ded6ea352a1e7e02f3d786bfc9379780daba4e7aa049668ad',310424000,NULL,NULL,'4b748ee91d10ed9e7e801dd5e49968d61f6a6f5808915072d9b00751f27bbc55','3e5d6c8c8a8db4c439448e61ef07ceec981bd2d3bc4115b979c9de2b5ec6322b','99c1edee125d184808ade6e01b43dbde39871e4b5ed1b34010154b59c0ff91ae');
INSERT INTO blocks VALUES(310425,'73f4be91e41a2ccd1c4d836a5cea28aea906ac9ede7773d9cd51dff5936f1ba7',310425000,NULL,NULL,'51a04f59b5dbf8587f6721d7a5977434d4138dccef9856685fd850d9e772e0ab','7a283bde8565aecd072a409a6eb7e57199385bb2abbe2f069fa79c4e33c14386','9cb6d8ccbf2c78349b7ee70699b59bbf3b72c3ca070cf7c8392eba24d46d4b32');
INSERT INTO blocks VALUES(310426,'9d28065325bb70b8e272f6bee3bc2cd5ea4ea4d36e293075096e204cb53dc415',310426000,NULL,NULL,'e3bce2c09e9d571cc3510427681f04e4bf638d49abec026f2b668f4a4144d5e7','8834dd5bc4a67730ccb7a358a0ca42735589d13ba8793b91c3dcfbd0224f393c','4e997f6e3bbcef914153bf2fd84cd3b77feb9373804ffadab3b7e0026fd59418');
INSERT INTO blocks VALUES(310427,'d08e8bc7035bbf08ec91bf42839eccb3d7e489d68f85a0be426f95709a976a2a',310427000,NULL,NULL,'fdb5981ead4d3af07a0d096055d54804f50233bb1f2d89c130496ff680da3861','abc6bbe75d163728c7f136c9dbca099f50e88b5686beb191d130ef4a06d35d2b','aba89a7f314f619732fff0b15eed74056dc42e6eedf319b5afc0f15059f14d75');
INSERT INTO blocks VALUES(310428,'2eef4e1784ee12bcb13628f2c0dc7c008db6aaf55930d5de09513425f55658a2',310428000,NULL,NULL,'3a4ab14de3ed2fb5710d678984ac9e3e08fdeed1b9a6a0e9251373d9235895ce','538cc745d02e0030c501ebc169efe1cee8c41b6966ab50a04e1cf56c9668ad78','ea42101426f72afe4dcd1beb0e7595dcf340f0953941d3d6fdad156060b8cdbb');
INSERT INTO blocks VALUES(310429,'086bfbba799c6d66a39d90a810b8dd6753f2904a48e2c01590845adda214cf8d',310429000,NULL,NULL,'9eefabfa3e8ae8528b415cc735c35863a6d3036a39fb0385421f7e69daf4c525','66126c2f5d6431dba015932ef9e1b96efa03c0d9394d5180e65fb3f4f3ce69f3','2369cb8ca84ebc20f50101621c1bababcea464f383ba67298cfb6b7632146664');
INSERT INTO blocks VALUES(310430,'870cf1829f84d1f29c231190205fe2e961738240fc16477c7de24da037763048',310430000,NULL,NULL,'6cdb3a5b143bb69cea113010c13c01bd02481ef36b667ccbab433f0018004946','b440b750409c110e5a2ac3960b466e6116e545b13c41270bed13d39487f07fba','4261dcc8dcf2dea7b94cb390241b9f6641aec430df6f1728c06ca6f05992fa3a');
INSERT INTO blocks VALUES(310431,'20b72324e40ffc43a49569b560d6245c679e638b9d20404fc1e3386992d63648',310431000,NULL,NULL,'7b638814bb6f667b4162a12ac1209281be1188023dbcda9305f3ee3de593cbbf','e8762b8a57abde3210bf336a61308dc21cbf8057c47508f3dad5631874894285','03c88166aa2a771ac4317c8524044d04d6e9d70c4aec07ab99cb5186285b1fa8');
INSERT INTO blocks VALUES(310432,'c81811aca423aa2ccb3fd717b54a24a990611365c360667687dc723e9208ad93',310432000,NULL,NULL,'a07095755964ac8f82549f87c54b2b8c81868ade4bef88860013dc5b4d34c99a','e4d9b32705da763a1c11f3b53ea1431315df70944a1306c3b064bc670f460411','41fb3001a839d76b881be31b7fa75b1ac1709b07b47ae1ace83ef1181aebe198');
INSERT INTO blocks VALUES(310433,'997e4a145d638ad3dcdb2865f8b8fd95242cbc4a4359407791f421f129b1d725',310433000,NULL,NULL,'b929314b56bacee81e6cf7a5453d6b096810b234741226f5832e2f009d0d0837','ea804da476fd4d7cb518fe9bb4657996b2865b2b982220487c727e68805fa4e1','5da2fc55bb7b0728f3750ed926f7274e17c5a9d12b9bab344a1d4b0fa647ddcc');
INSERT INTO blocks VALUES(310434,'61df9508e53a7fe477f063e0ff7e86fbb0aef80ff2ddedc556236a38f49ac4d8',310434000,NULL,NULL,'9ab732622f26b15df97ea31a461d457fb177aba99a86030868a198de2cce7a1a','40a7771c399f60e72af0be9962d07d6b781d64ca54167fb2a3cbcb80a539e483','eb1c604ffe61840b351060397d89cb2ba1263c58f39f5f97c5136b83b517b19a');
INSERT INTO blocks VALUES(310435,'f24cf5e1296952a47556ac80a455a2c45da5c0dc2b388b51d235a3f741793d5f',310435000,NULL,NULL,'11d44c91e3c2187d0061a378ed8e9eca84f737b88854269ba4e6983a0093c98f','c6adab9353cd17c87121bac859cc8ef404f823c6ccf2818665b244fd75d315c6','ce022cd25eb226aac08bc1565a292a0abd2b17817120c2b471538f11e3ac2782');
INSERT INTO blocks VALUES(310436,'a5e341ba92bdf9b3938691cd3aab87731eba5428bb61a804cecf9178c8da0c19',310436000,NULL,NULL,'4dc6c5d20308e8b7215b2b021a7b9680f3d463cdf9ce73c7711f0aac7d85554b','135994a53ca9152caf648c5d5a89bda10f8d777cf43ef9006f9d430945df6cdb','fc77de97a11b71ff2787123b35bdd3f48daee8586f7677424b6094cb66509865');
INSERT INTO blocks VALUES(310437,'9e18d0ffff2cb464c664cefc76e32d35752c9e639045542a73746f5ec2f3b002',310437000,NULL,NULL,'4377f62837e0b4464b39c7e96d6c57ecca5ac9be4073301418b62a862c24970d','2476363088781f3951e79aaf262016d5e92e0692c1ad29ba65475968f3592718','194c4f508a98e1a4142069ad7bb76888321e8196a49b36345b4fd73a5172e5d7');
INSERT INTO blocks VALUES(310438,'36be4b3470275ff5e23ed4be8f380d6e034eb827ebe9143218d6e4689ea5a9fc',310438000,NULL,NULL,'2bf0cc340193b2aced958bc95247c464c14b13c1e9b605c557d367fa3b9679c3','a65445de25f7b4c4dbc297f0a5b2810cae8124b94a3285f0166b424765b62edf','759d81138a04117d77720039d06e8579021f9fcba6eef3228549bb101d413eb7');
INSERT INTO blocks VALUES(310439,'4f2449fce22be0edb4d2aefac6f35ce5a47b871623d07c2a8c166363112b2877',310439000,NULL,NULL,'fd02328b8b9f2e64f0e52153da0afeb3a0042cf00fdcd8f3e39b2798f9531e56','65bc1be4173d575f3bff8d058b49e4c36161e9939b66a18cd6dcd5f2aea86a2c','901e5b5e053f6c0224789996e8420ac9b4e5c210c3c8571b41cceadf2f0d0629');
INSERT INTO blocks VALUES(310440,'89d6bd4cdac1cae08c704490406c41fbc5e1efa6c2d7f161e9175149175ef12a',310440000,NULL,NULL,'97d6d6a14a57248b203a54529f285659e0d2a5558686867437e733aab4efe0ad','b59b2f232ed25f2b8dda21dc937a90c6a93b556588c3aaa7849b1cf92eb35cd0','824f84b4ba42427ef7aeff6c33ad704eaf4226155c221a6162866a27bc2d32a9');
INSERT INTO blocks VALUES(310441,'2df1dc53d6481a1ce3a6fee51ad4adcce95f702606fee7c43feda4965cf9ee15',310441000,NULL,NULL,'ef41d101beef77a0219dbbaa93c40360f349beacad07de223f4f289383ab5874','28ab7150f17510ae2cc6fd4bacf6f9fd8b906d884c4c4eabae87ed1b60f373ef','121dd90d101ffc3693e9d1023be9dd1a4f4fa5c70496a7b278cfaebf9bb9f4d6');
INSERT INTO blocks VALUES(310442,'50844c48722edb7681c5d0095c524113415106691e71db34acc44dbc6462bfec',310442000,NULL,NULL,'58cf85290a9ca6f56063351708d002ee583492e6eb8fa7f7731a815bb98f754a','6bf3c1a10e28dde34de04ef53e290663af1da3e7ba1b1e0dd908083c546fd14b','2917de906341f920265489f56015b227c69be76faa30579b4b3747eb7453c4fb');
INSERT INTO blocks VALUES(310443,'edc940455632270b7deda409a3489b19b147be89c4d8f434c284e326b749c79a',310443000,NULL,NULL,'9627f169702b3e6297b848aa2147425cea30b11a4341fe7114591beb6d9c46e0','fda46fb4295fa341a5b36066891ea0817ba60e9ca0f44de3298dabcdd83de2a2','57189d87bca011da43f42dc712fc47898fa4acbc7b900873285744d8a1dbec2b');
INSERT INTO blocks VALUES(310444,'68c9efab28e78e0ef8d316239612f918408ce66be09e8c03428049a6ee3d32e4',310444000,NULL,NULL,'be38c676cdc9c20ede41e34d9535669eb22b529c0796a594e09988d9f0c296e0','b932c19e5f04fafbf96151da95f2af5e2f6cbda535f4b746901a525cfcf0ab90','71a703dfed824a4f23293c3ccf86fa65bf442715da20ea8811ef4d0aaff02abd');
INSERT INTO blocks VALUES(310445,'22a2e3896f1c56aefb2d27032a234ea38d93edf2b6331e72e7b4e3952f0234ef',310445000,NULL,NULL,'c85b1e04c34e9c21e62542093b09392828660050e3fe37018d48fd092a3a6d01','3d04015e47242d665169b10c140f6ec1ce0120ff9e2623d5b44eafcbff513cc8','79bad211b4bcea498bfe35c5a2f7d697978960a92fa403feeecd74b561cf69d2');
INSERT INTO blocks VALUES(310446,'e8b0856eff3efce5f5114d6378a4e5c9e69e972825bc55cc00c26954cd1c8837',310446000,NULL,NULL,'9407b24d855cd17945afad1eb1ca1f8d87649bb299bf8bcb3c8d25885481494e','9c140b5e47700840945271cbfe0ebc4b6c66987aa02946a73d324da80fadc497','d67ab76918ce9b5a3fbaa9f3c0cf08db3f288c5027d78b518b53354289cb76c5');
INSERT INTO blocks VALUES(310447,'3f4bc894c0bc04ee24ed1e34849af9f719f55df50c8bc36dc059ec5fa0e1c8a8',310447000,NULL,NULL,'32572b745f9d947b1d69657815d6fd7fbbc3923bb9613de35044f64492bf64e3','39d20153f306fa6df0d14485c9bfb3e18c5d2f2cee231066dd7f1bcccead9391','c7023fe370154ce85ea24e4207f777f214c20eb06ca215dc83e89f68a2c5483e');
INSERT INTO blocks VALUES(310448,'6a6c7c07ba5b579abd81a7e888bd36fc0e02a2bcfb69dbfa061b1b64bfa1bd10',310448000,NULL,NULL,'9632438e83943c6160fc043ab0296e82e16f30ccb638a911dccaddb75916cded','46c0501df204e74cc3ae3e06ae574ace38557f3f47148f1aaf7bfb72dd13bedb','c77acd4cc063909ef6337acde73c9cfc58fce47712ed93d3e171179bb9f1fdd8');
INSERT INTO blocks VALUES(310449,'9e256a436ff8dae9ff77ed4cac4c3bfbbf026681548265a1b62c771d9d8e0779',310449000,NULL,NULL,'0955d1b60f486e870f7224014098235793b2fee3a4532dea306612526a678646','eec391665a5b3fe8c0ee58783c8f0d9972258307dbde10fa1664e2069322391d','96908aaf77ad76e35be9334d3c52dd3a03573fc4f9d2b06fbaddbec921c047d6');
INSERT INTO blocks VALUES(310450,'2d9b2ccc3ad3a32910295d7f7f0d0e671b074494adc373fc49aa874d575e36a3',310450000,NULL,NULL,'df180f4f22dc7325a5da2c86b1eb565170d2fec80bed2d6f1ef28a30cedb848e','bb3fcfdda704142f6c6369f813851d9cd6fedf501463af4d264777f3f4a1f5d9','d7f607dfba7e29a526e195054790dcdb2373332e5417b3598853d8f8d8ec0c65');
INSERT INTO blocks VALUES(310451,'55731a82b9b28b1aa82445a9e351c9df3a58420f1c2f6b1c9db1874483277296',310451000,NULL,NULL,'ea0ee01d40e1c5ba6298c7dd46e4da174c8701366452397884c561041a767fc2','0224227e9217098df0d5f439fd391af4a98c253e4f17d3dbd7c0434757a66eb8','91d413faa928d82938e130bfd9014c997a53a10e818bcddd869d2fa935d320ba');
INSERT INTO blocks VALUES(310452,'016abbaa1163348d8b6bc497cc487880d469f9300374a72ecb793a03d64572aa',310452000,NULL,NULL,'fb5a1fb0870df488cd3a4f34f76eb45d5ed5a8c20c749085c659a3042369c447','386a60c2ddea8f8ed9b65a5223769a539a91a7e9cce8707ca9b26217ed1aa59c','54d0565bb9e320c02df42b79c974b9b51fb065fc1c5d54f12aab4334fe9a9a33');
INSERT INTO blocks VALUES(310453,'610be2f49623d3fe8c86eacf3620347ed1dc53194bf01e77393b83541ba5d776',310453000,NULL,NULL,'14c2769930580dc461ab45b95937e9c4b9ee364b775c41920f15f042f0464c6e','c262170d5fc61331b2704912b9662ab993128b88e7ab73fb9a040465fda2532c','ef8f2767bf94c3642306de63feefdd249412573ba6fca15631ec96a253487be2');
INSERT INTO blocks VALUES(310454,'baea6ad71f16d05b37bb30ca881c73bc48fd931f4bf3ac908a28d7681e976ee9',310454000,NULL,NULL,'446b03e4578eaff70a5cd6806817967c8afe2dbab3872ad94ec4a4b98e341c37','2077fe0b8cb3a8fd64a625490361b2c67a002a245484ea3c4de6df8db9412ba9','baa03c7f721ea46ad7e8841b414721d5e91e7b0f9f71819c29fb5ed8d6667115');
INSERT INTO blocks VALUES(310455,'31a375541362b0037245816d50628b0428a28255ff6eddd3dd92ef0262a0a744',310455000,NULL,NULL,'b128ff308e4f67d56816165356d2aaff7d1268e0476d1df0d1ab0bb04dfdab96','053c16b73f189544c38d1d3a2f463a528edc01aa158cbfc836f0ffcfa8997ea9','440f8b32940f1feb2dc78ad4f11d14d3b921b779ebfab8ab72e66850dee5c5a4');
INSERT INTO blocks VALUES(310456,'5fee45c5019669a46a049142c0c4b6cf382e06127211e822f5f6f7320b6b50fa',310456000,NULL,NULL,'869d752cae5317cf7587720440e21cccbd8d9ba2e4e58241ddd2ca31e2a6214f','b68b63625459a8fe8e23158465cea9af67caea568ab3c99f5b202c884a3eb689','16bd6d64baac89e4cbf07977e749335cacdba5ecc86ce77359a0e7efb0571daa');
INSERT INTO blocks VALUES(310457,'9ce5a2673739be824552754ce60fd5098cf954729bb18be1078395f0c437cce9',310457000,NULL,NULL,'f224a5c2d6a4917cda8a3924259f2082621ead0bd6c5628e819e67c6975e7af7','164c56e4e4e01895f05b3da44652664e83039c0578e661d78a64901f0d19baa7','d6456e1f31d677a3aa7e05b47eafb3bb17c590e7c69bdf728a75617cfcdcf184');
INSERT INTO blocks VALUES(310458,'deca40ba154ebc8c6268668b69a447e35ad292db4504d196e8a91abdc5312aac',310458000,NULL,NULL,'0455e86e1977567d6c2b4bbde2021f8ac71cbd5c2ce6ffc832c10f5015d352e2','93900f33fb853194ecf7301b83224949b28a00938f3776f7a3f47f389f5e81b6','1bfc2cc1489208218f8cc8ba6b54c9eb8155efdfc8d55ff17bdff72741659a60');
INSERT INTO blocks VALUES(310459,'839c15fa5eea10c91851e160a73a6a8ee273a31ab5385fe5bd71920cbc08b565',310459000,NULL,NULL,'ecf659ed76dc25c82266cec096d96045a1246e59ec72891f8c9cac99e862ae4d','4472a84117cbc7f2377bbc90b010bfb4336c95b277a6b46e009ba9b087f29222','d1c57291af803f3cd8c54c24f740a5fae06aa59144119ca98b23837623d9424b');
INSERT INTO blocks VALUES(310460,'9b5f351a5c85aaaa737b6a55f20ebf04cafdf36013cdee73c4aaac376ad4562b',310460000,NULL,NULL,'0dbb64836d780c15570f0dcb9760fc9909589988e86d8f240af2f508b5c2a8d5','e8988d0d336f87010e7eb6ca9fd554ff703b37ae3e8e56dac9c3ac46d69002e5','424b28437a4267b86698b2d75db4a607f03909176786005c0e7b5f8f1f5af8dd');
INSERT INTO blocks VALUES(310461,'8131c823f11c22066362517f8c80d93bfc4c3b0a12890bdd51a0e5a043d26b7b',310461000,NULL,NULL,'590346a89bcec47460d1967953eac1f7fff3af2d6fb8a782c69e52199d00b6e2','87c09b4d0919c876e302806f663f25974b5c98fac29187ae000145469ab98995','3d377a4e0b067eb0b3258703e2616004ead4888719d10950eec34a65c8145a71');
INSERT INTO blocks VALUES(310462,'16f8fad8c21560b9d7f88c3b22293192c24f5264c964d2de303a0c742c27d146',310462000,NULL,NULL,'38d9646933e0b59e1df9405442deb9f673c835b699a0fd295e662e46b5e1352f','09ef8e97048baa4a5f5eab9b52e25245f1f751b8f02de8654b8187413ae1699f','1013da223b34f7616b1d3f29cbd03e2be4c7e4c9163087873023543206bdc2be');
INSERT INTO blocks VALUES(310463,'bf919937d8d1b5d5f421b9f59e5893ecb9e77861c6ab6ffe6d2722f52483bd94',310463000,NULL,NULL,'8e13ab55febadfb1673e5961c778c4c2909b6fdbeb89c065f6e730389ca4292d','4fcaf14122ea289004b4849cc69eaa7ef4e1ac0f039da58c7ec759700cc1a326','ac020218707aad81383e5ac0846d5a6732f98785d42279b71e9d533e4290c253');
INSERT INTO blocks VALUES(310464,'91f08dec994751a6057753945249e9c11964b98b654704e585d9239462bc6f60',310464000,NULL,NULL,'a6afaf024b80727cbd0e2a5c2fa610ef4866de58bc7cd84c26daaeed29be93fd','cf9ba4c2465d24572745f5f591c45367ba8502cfc4d72ca78680287677dd859b','ce4d5ff4f10e2ea0d05fb9618bd5853fd15413998d4d24474c97505f420f1fa7');
INSERT INTO blocks VALUES(310465,'5686aaff2718a688b9a69411e237912869699f756c3eb7bf7c3cf2b9e3756b3d',310465000,NULL,NULL,'2262a5955f9188c7c1f7c667f2f625b285b337755ca618e0c8908a39f08d172f','60e8a7ebf9e6f387c45363cc32b4a2c0bfc639e83d058cd94f7b178b2b36e319','27b7369a736ae9f482658ac731e8034d1a60050a82c78916505af15029d53556');
INSERT INTO blocks VALUES(310466,'8a68637850c014116da671bb544fb5deddda7682223055a58bdcf7b2e79501fc',310466000,NULL,NULL,'e24d9205df7f171f9e74feab6b6e8b4d051b7ec20f9c974648f7b841f1630677','58d90dbfa1b731a23cae4d0c89ae8471e1b73b359762aeb892360ac51fe3d5e4','80e60c51a5c3c9573cab51c2f999de68c28cbf450cabe1e3c542881cdd6f57ab');
INSERT INTO blocks VALUES(310467,'d455a803e714bb6bd9e582edc34e624e7e3d80ee6c7b42f7207d763fff5c2bd3',310467000,NULL,NULL,'0af8ccd0ad60bf6be7296b923e06f5c776c430a405c20040a7e93e3536bd8f01','c58ccbbdfb4faba48531a5135591a03c228273655ea11f0fbfc5621ff19dc9e5','278ff2a73d5afaa236851968abb802145132a1c538baf44c23d1d61f6a2b5e18');
INSERT INTO blocks VALUES(310468,'d84dfd2fcf6d8005aeeac01e03b287af788c81955612375510e37a4ab5766891',310468000,NULL,NULL,'2ac2ed5dd978febe153d90fd153a61554fa530b6105c72ce546d80f132b65b07','12f2768018fb10c892ef342f552ea08cf1f10b04a3c4204c74da3654fc580401','5c66bb74d3045c318651b2b0d398a241a30d7f4bb52f9e60743e3a7c0eb13733');
INSERT INTO blocks VALUES(310469,'2fbbf2724f537d539b675acb6a479e530c7aac5f93b4045f4356ea4b0f8a8755',310469000,NULL,NULL,'3c13fbc5afd18fdd4fb8391b4eae7a6d3a3ffdaa7ca6e1120c5f7ebcdf81a102','a1c8a4f6368658f265b8ec0157d5ebfb52305ad79e9dc9283aa2bca5cf01cd08','b7d79b528b44f4c8e9132438e79dacfd98d5055d117784a3128d318b0ef989dc');
INSERT INTO blocks VALUES(310470,'ebb7c8e3fbe0b123a456d753b85b8c123ca3b315da14a00379ebd34784b28921',310470000,NULL,NULL,'79bdea07779a75c4e71bac9e8ef8c9c5288c53a336fbc07bc8d34e9de40f49e7','5be12925b2c1f141f8db91cbb39e642e23c1106e01cc13ba38664687193e4195','26c0a2f58fcecb36aa8d31e0868cafdc4613bf77d180e31e961bd7b4c5f125d9');
INSERT INTO blocks VALUES(310471,'fc6f8162c55ecffeaabb09f70f071fd0cb7a9ef1bccaafaf27fe9a936defb739',310471000,NULL,NULL,'f4169128d3ad608d735e2d7da7d0a3c39d23440e7b830e843117000a3433260b','c95a34d08f43444f14cefd300baa4b728051709a773851862aa2c60b5a7ea7d8','2834e74379fa18e3e855e20cbc460ca91c89785f2e4489af56dbde6066711671');
INSERT INTO blocks VALUES(310472,'57ee5dec5e95b3d9c65a21c407294a32ed538658a6910b16124f18020f16bdf7',310472000,NULL,NULL,'bded1a4a0f0627ed784723396e84ef43d09851319ef7ee4d5c79d81109bb7ed2','5e8e56ab8a71e5de6540513725e8b42f6a8f6a92d429fcda7e21ba69fc599f6b','10bf3852bf8b178d04f58e529108d16a92563e82b53afbd7b3dfe570b3ce519f');
INSERT INTO blocks VALUES(310473,'33994c8f6d06134f886b47e14cb4b5af8fc0fd66e6bd60b3a71986622483e095',310473000,NULL,NULL,'6b9f42953bcb3fb52ae7119c169b1021f7f5fc831cd2c4b28aec01de6a4bc9c9','3bddd1b3c8f4162e329f61117646477feaf1837c239f7d954158856f65a9d359','817ca8f93b7851a4c4d36499016590fa0028aeeb0b2b154bb2104faf7c4ddf4d');
INSERT INTO blocks VALUES(310474,'312ee99e9526e9c240d76e3c3d1fe4c0a21f58156a15f2789605b3e7f7794a09',310474000,NULL,NULL,'e4a9560abfce777cece11bf5a6603f9e085cf4af169c57072b51aac20a338028','7647a71f73250fe4b923c24257f8223623894ec68531ce7d64948981999953e0','dbeeb7554364a8092a915bb48bc6d33d94d097eb0ba6354e36c867a17e2ca803');
INSERT INTO blocks VALUES(310475,'bb9289bcd79075962117aef1161b333dbc403efebd593d93fc315146a2f040eb',310475000,NULL,NULL,'a5bc14c4c0e20b6a752ad29158967e2b6025a54df004a81831b9019147ad00ad','737a40747551fcbb4af4449a4a20d0197b44b537c20733ac6488734ee97e1ad8','2c20cbb43566447ea1ddd30aec2a5439748ac18e440663153edbad3506c15b84');
INSERT INTO blocks VALUES(310476,'3712e1ebd195749e0dc92f32f7f451dd76f499bf16d709462309ce358a9370d0',310476000,NULL,NULL,'c1bdd7f0d0ee6ee179ef592536cba02c830af1b5baccd132edc506aa74b8a779','750101a6de334cf87ca0ec0375dc3e9d30e3d200cff4b19c6b66a2abb843d997','9d2873e4d2f6595f20c1bbc51a23c56ebf09f9b2ce41a60d874456dde707cee7');
INSERT INTO blocks VALUES(310477,'7381973c554ac2bbdc849e8ea8c4a0ecbb46e7967d322446d0d83c3f9deab918',310477000,NULL,NULL,'de8ea6f839023283913937958e5cbb1d697956f3b5c53ab430eae6c7279c5541','277687324afaca384240d00afa0abc35ffc10a53d66297c0762df275c80601c4','5755c188587d8de34f87c5c95db45b7435c44647fefed7335688b229474e1f3e');
INSERT INTO blocks VALUES(310478,'c09ee871af7f2a611d43e6130aed171e301c23c5d1a29d183d40bf15898b4fa0',310478000,NULL,NULL,'fefce7089eec1a6f7b148cfa63d1756da76340ba276977903f7114d52ad1f1c7','93c649df5d1ef34df032a98841b34ee512640c20aef5cf5f6b475a1eb28030a6','7feeae6f8eac8b2a4ef3778b7b037bfd17a55128cf0cf751b07c4f82af4abbb0');
INSERT INTO blocks VALUES(310479,'f3d691ce35f62df56d142160b6e2cdcba19d4995c01f802da6ce30bfe8d30030',310479000,NULL,NULL,'0b119c488c582eb33600d9816bbed211b4474c5d0bbdf4b1fe3db0b24e3bc56e','0fabaac8a2b6fe8cb7ec0abe31905d16cbce4ea4896e4303b1d6fc16c80c37bb','62ec9975d5f0f89b1573aa42cd37585154328af397b3097b4cf80ec4abf44a29');
INSERT INTO blocks VALUES(310480,'2694e89a62b3abd03a38dfd318c05eb5871f1be00a6e1bf06826fd54d142e681',310480000,NULL,NULL,'df402aaf62a3acd427b0a124f6c2d8df955162195f7bc2a911ad47b89c4fb8a6','bc9cdd27a56eff73399e6b32a0a31342da14faecd81a45a71631085975599622','7221ed6a42230158f1c6c17825c25b10b8cd509f6bd3b478e5f9e5529b49704c');
INSERT INTO blocks VALUES(310481,'db37d8f98630ebc61767736ae2c523e4e930095bf54259c01de4d36fd60b6f4a',310481000,NULL,NULL,'457a923c50f2061324717034b3024a90042f92a2bd979f9e487b20baf40fe3c0','943df97ef721e55142aada62653c6d25c31cdc58271beee2db9a3f7fbcfe5dd2','6960a35a6520ad4797a7496e67cb835ea2a651ed9e1c16082bc53cde721fc29d');
INSERT INTO blocks VALUES(310482,'2e27db87dfb6439c006637734e876cc662d1ca74c717756f90f0e535df0787d6',310482000,NULL,NULL,'6f5b3b3cbe5a74caa657c5509a7417396cea65fe879d3f0e45cc9d5fb19aa352','8d2df738c316dd707d0bba673673831bac947e8b9614e45c9fb0c0bc55403206','93dc74d8096370989112372f6664ec40e2fe61ac53260560e9b851429f346cbc');
INSERT INTO blocks VALUES(310483,'013bac61f8e33c8d8d0f60f5e6a4ec3de9b16696703dea9802f64a258601c460',310483000,NULL,NULL,'bec867793a3daab86f55ad7fc2dbf5ad610c6bbf69bf8910915e868679132f57','ab73013a4c6ca6aa71b19454a3c4c6f8006b2d74c8b530bcc857e4c57162a634','e25f744b96cb754789f2abcd2d6ab61282cc3f2131dae913d8836512a163e467');
INSERT INTO blocks VALUES(310484,'7cac2b3630c31b592fa0497792bed58d3c41120c009471c348b16b5578b3aa2b',310484000,NULL,NULL,'8f6994130f62c5544021b3fe2d23389dfb5b46a1fab22f7a234cb521ee63dd48','b764e044793e86b4e538a598b7908794a229efebdeb4d82d9c90dee59e52a590','b8b583f1e7b56cee7d155ef0bbe670d2b01d357305ba5c99b72d64716c1ee83f');
INSERT INTO blocks VALUES(310485,'eab5febc9668cd438178496417b22da5f77ceaed5bb6e01fc0f04bef1f5b4478',310485000,NULL,NULL,'2dfd8d8a781c5b219ca3615c4106fbe62b983f94dff851ed41fa77263d065f20','5bef6636fab87222d95111ac983977ca888edbbf0093cc4932a9d741af6affe1','f178e05bc9142d678d869dfe295d42807abc6c6a1868ed268b32efca6b0d45be');
INSERT INTO blocks VALUES(310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,NULL,NULL,'3fe205cac941ef675096e98b00d0c3522706876eb3bd391eda246d9fca16300a','c4c0bdd6826d8033e716f94427b87701d6d09bfa766cd0519ea16a63d651e6fb','027e25238830fb4d7230280e12896fd624a8b03a278a536fca424c0d2b6d8b97');
INSERT INTO blocks VALUES(310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,NULL,NULL,'c9ada9b029b1eb0dff4fd182c928529897eae2b4991b83bccfefa2cb25f09fcf','9873d36912cd6d0b5bac885ecf880d67267a2dee1008c0abb206ed155d55218c','542f011aa760ee14f4338a44bad17178258a6c7274cc1cc4afddfd21763fa8b9');
INSERT INTO blocks VALUES(310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,NULL,NULL,'f012e7facf0804377940ce7a7a6c7bb9adffb482051db24bb240d58b4fddbfe9','446f1ca55bc6a2747389b320fd591500da06ae34e21dde2199af07524531428c','13cf7556c5bd890d13a8ea728175621282164205477a18c3663cafefc10c767b');
INSERT INTO blocks VALUES(310489,'2efdb36f986b3e3ccc6cc9b0c1c3cdcb07429fb43cbc0cc3b6c87d1b33f258b6',310489000,NULL,NULL,'0ab4d6d32d686457de15a4a0bb01f513e350eefe656821d91172ea445778e0ca','7a11c0340626b6952acf8fc9c35ce4559f3a0b52983c120d1623fe32b7663213','560e3167a6f6c560a4f9b4b3210eb528437b59e532658b2d99164a2f4d1d97b0');
INSERT INTO blocks VALUES(310490,'e2cb04b8a7368c95359c9d5ff33e64209200fb606de0d64b7c0f67bb1cb8d87c',310490000,NULL,NULL,'570a9e34b40853024faaf8527d34669af322e54b67ad2e66a9ef7bba12286983','c932e0fbd1323e35fd31ed0c00b67718fef353cbef7347e83a06df09a21dbc50','7158734dacabf5dd1fcd96ed67ef9e531676574c5bd6ccf39f988a2d968e737f');
INSERT INTO blocks VALUES(310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,NULL,NULL,'289de263d4fa5d7e363faf096a57a322c0b3d14b6ae80c450dbe60d34f82761e','10f05c7dac1e4f8f20ab7a7e102c685ae814a96ba1258a6e13cffc8dcbce6fe5','ced975d9adcbe57b54363f82fa822d87803991aeeec0314f3b07376f85c92eac');
INSERT INTO blocks VALUES(310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,NULL,NULL,'b2419f9e3dafb374f8a5c28823189186d5297a33df9a640addcecf9743378407','b9214d0394bedd1ea84b617b564d0c26c2c4d6f827063631b0a86df7223e2d36','3548791fc79d8e627eeb7747f2a110fe87204431bd97f63a982ebe3f9c95e99f');
INSERT INTO blocks VALUES(310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,NULL,NULL,'21cd6be42df189de650fdfdd36348f972018d644f1b69ab996cde73d784ff1f2','2ecb8ee3ba0bbe72522dc8a2e0ac4b488cc8b88c8e7ce877b5789f50d6b6b04a','a8ca8d1168c401ed8413f1b9ebaa245f8c9ca840f07b15539d7e221a1cdf42d7');
INSERT INTO blocks VALUES(310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,NULL,NULL,'aa8b4bc71e2c5305e5bd490dd3a2c4e9481e77efbd9453980773c180a615326e','abbaf125fabda09d8a5ecc4e144824a1e467d28baa8f077d7aefc2c297933bfa','b93765d9d3c6fb6b5213a81c6fe8bb3a65e3027b4d634c34686bb767b5c23c18');
INSERT INTO blocks VALUES(310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,NULL,NULL,'73d42be271f55c98fe671c893c35e10f85fa58b1b6a9ae68bb2a464f7628b15d','74de34b26d08f40a7363cd14f2a80621ed620f432533776a8d1d2d232a9439fd','da60e27de6b93690ade8f329c0948ae9f7f8fb2a65c389bdc53a12fcbc1b3b1b');
INSERT INTO blocks VALUES(310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,NULL,NULL,'8693f06964a681b9e0f71d7c9a548e9bfd2d23e5037be0409ab1cfc5621b4bf8','330fde1864f82ac0e2eb3ea26474aee4a28001145a5f9be94381592552545dab','41e69196f1dc7a9f7e87410dd5e1419a6c9363509bdb93ae05b9b5867fa9c7df');
INSERT INTO blocks VALUES(310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,NULL,NULL,'b4ba26f036b9fd68b61aab880640b63241b3b919ac5e78252f3198a397f3fec4','bdf3a936b2c2466ce16b1f004ccd182a48bf566af686ff1369143c8be91f3f02','f86cab80b4ef9281ddc16cdf9e127b1baf328f3ceca3585c3df406338157591b');
INSERT INTO blocks VALUES(310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,NULL,NULL,'2d0a10d2c510c3eea6d9358fba17b01e44c68f70ef7203c1511e78483c1e156e','04e78dd4196e13f5c361dcd0a4802d44d53e5972bd013026cb23244eceedc2a0','6f61f023801edc1aa995a066255067963d0d8d2c6bd21b846fa24d76f2b6e5ea');
INSERT INTO blocks VALUES(310499,'1950e1a4d7fc820ed9603f6df6819c3c953c277c726340dec2a4253e261a1764',310499000,NULL,NULL,'bc743eea39dae9c37ef0e4f924522ae81da5f3da90db8949688e73a66172f9d0','47d10caa8849051e7cd9dcd06dbe283a293b0f93a5a73de06e83dcd330f035de','4163b7bd253af4a285a105d5ee2ecbcd02619842196cbdaec2452a24543e9429');
INSERT INTO blocks VALUES(310500,'54aeaf47d5387964e2d51617bf3af50520a0449410e0d096cf8c2aa9dad5550b',310500000,NULL,NULL,'41e15ee7eee432691970d1b62019a91593a64375772f792782f1beefd8bcd7f6','dafd6f7fe8f7f4f6e13aaeca079e41158e2602f637b9f10cbd6e390349c75c40','0221de4a932dad4b1178e233369dcf3f3b37e36634bcb84785dd9d8408a468f1');
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
INSERT INTO credits VALUES(310106,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',46499556869,'burn','93c6d2499a0536c31c77a3db3fc9fc8456fbd0726c45b8f716af16f938727a73');
INSERT INTO credits VALUES(310107,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','PAYTOSCRIPT',1000,'issuance','ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e');
INSERT INTO credits VALUES(310108,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000,'send','f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481');
INSERT INTO credits VALUES(310111,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','LOCKEDPREV',1000,'issuance','5f66cb2a8f0a4605cf274a21daf0a61af10fdf3fdc5210e5bcf8f9f3d26b0bc9');
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
INSERT INTO messages VALUES(87,310481,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310481, "event": "b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5", "quantity": 100000000}',0);
INSERT INTO messages VALUES(88,310481,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310481, "event": "b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5", "quantity": 100000000}',0);
INSERT INTO messages VALUES(89,310481,'insert','sends','{"asset": "XCP", "block_index": 310481, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "memo": "68656c6c6f", "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "b00bdf03402d81a2cbdbeac4b0df90cff5ab6bf9688f653383d49fe42b8422a5", "tx_index": 482}',0);
INSERT INTO messages VALUES(90,310482,'insert','debits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310482, "event": "c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34", "quantity": 100000000}',0);
INSERT INTO messages VALUES(91,310482,'insert','credits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310482, "event": "c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34", "quantity": 100000000}',0);
INSERT INTO messages VALUES(92,310482,'insert','sends','{"asset": "XCP", "block_index": 310482, "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "memo": "fade0001", "quantity": 100000000, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "valid", "tx_hash": "c8716524f33646b9af94d6f5e52494ff3b34466497094b1db2ab920e4f79bc34", "tx_index": 483}',0);
INSERT INTO messages VALUES(93,310486,'insert','broadcasts','{"block_index": 310486, "fee_fraction_int": 5000000, "locked": false, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "096883e142a87377d3a4103f4702556e25824f1e23667aceb1690f66e1417062", "tx_index": 487, "value": 1.0}',0);
INSERT INTO messages VALUES(94,310487,'insert','debits','{"action": "bet", "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "asset": "XCP", "block_index": 310487, "event": "2447f6974033ac41c40b4598dfb73fc7479fd85bb9d01de2267b3f7842803275", "quantity": 9}',0);
INSERT INTO messages VALUES(95,310487,'insert','bets','{"bet_type": 1, "block_index": 310487, "counterwager_quantity": 9, "counterwager_remaining": 9, "deadline": 1388000001, "expiration": 100, "expire_index": 310587, "fee_fraction_int": 5000000.0, "feed_address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "leverage": 5040, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "open", "target_value": 0.0, "tx_hash": "2447f6974033ac41c40b4598dfb73fc7479fd85bb9d01de2267b3f7842803275", "tx_index": 488, "wager_quantity": 9, "wager_remaining": 9}',0);
INSERT INTO messages VALUES(96,310488,'insert','broadcasts','{"block_index": 310488, "fee_fraction_int": 0, "locked": false, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": "options 0", "timestamp": 1388000002, "tx_hash": "9b1cad827c97c463c2b39cc9d550693c438010ef85a10ee04d3db8699193e906", "tx_index": 489, "value": 1.0}',0);
INSERT INTO messages VALUES(97,310488,'insert','replace','{"address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "block_index": 310488, "options": 0}',0);
INSERT INTO messages VALUES(98,310489,'insert','broadcasts','{"block_index": 310489, "fee_fraction_int": null, "locked": true, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": null, "timestamp": 0, "tx_hash": "9a39bade308462ec65be3c8420a0f2189b1d4e947d4c7950a37176de71de4f87", "tx_index": 490, "value": null}',0);
INSERT INTO messages VALUES(99,310490,'insert','broadcasts','{"block_index": 310490, "fee_fraction_int": 0, "locked": false, "source": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "status": "valid", "text": "options 1", "timestamp": 1388000004, "tx_hash": "4b233a74b9db14a8619ee8ec5558149e53ab033be31e803257f760aa9ef2f3b9", "tx_index": 491, "value": 1.0}',0);
INSERT INTO messages VALUES(100,310490,'insert','replace','{"address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "block_index": 310490, "options": 1}',0);
INSERT INTO messages VALUES(101,310491,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310491, "event": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09", "quantity": 100000000}',0);
INSERT INTO messages VALUES(102,310491,'insert','orders','{"block_index": 310491, "expiration": 2000, "expire_index": 312491, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 800000, "get_remaining": 800000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09", "tx_index": 492}',0);
INSERT INTO messages VALUES(103,310492,'insert','orders','{"block_index": 310492, "expiration": 2000, "expire_index": 312492, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 800000, "give_remaining": 800000, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "tx_hash": "2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4", "tx_index": 493}',0);
INSERT INTO messages VALUES(104,310492,'update','orders','{"fee_provided_remaining": 6800, "fee_required_remaining": 892800, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09"}',0);
INSERT INTO messages VALUES(105,310492,'update','orders','{"fee_provided_remaining": 992800, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4"}',0);
INSERT INTO messages VALUES(106,310492,'insert','order_matches','{"backward_asset": "BTC", "backward_quantity": 800000, "block_index": 310492, "fee_paid": 7200, "forward_asset": "XCP", "forward_quantity": 100000000, "id": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09_2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4", "match_expire_index": 310512, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 310491, "tx0_expiration": 2000, "tx0_hash": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09", "tx0_index": 492, "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_block_index": 310492, "tx1_expiration": 2000, "tx1_hash": "2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4", "tx1_index": 493}',0);
INSERT INTO messages VALUES(107,310493,'insert','credits','{"action": "burn", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310493, "event": "c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a", "quantity": 92995878046}',0);
INSERT INTO messages VALUES(108,310493,'insert','burns','{"block_index": 310493, "burned": 62000000, "earned": 92995878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a", "tx_index": 494}',0);
INSERT INTO messages VALUES(109,310494,'insert','debits','{"action": "issuance fee", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310494, "event": "4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5", "quantity": 50000000}',0);
INSERT INTO messages VALUES(110,310494,'insert','issuances','{"asset": "DIVIDEND", "asset_longname": null, "block_index": 310494, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Test dividend", "divisible": true, "fee_paid": 50000000, "issuer": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "locked": false, "quantity": 100, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "transfer": false, "tx_hash": "4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5", "tx_index": 495}',0);
INSERT INTO messages VALUES(111,310494,'insert','credits','{"action": "issuance", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310494, "event": "4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5", "quantity": 100}',0);
INSERT INTO messages VALUES(112,310495,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310495, "event": "129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc", "quantity": 10}',0);
INSERT INTO messages VALUES(113,310495,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "DIVIDEND", "block_index": 310495, "event": "129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc", "quantity": 10}',0);
INSERT INTO messages VALUES(114,310495,'insert','sends','{"asset": "DIVIDEND", "block_index": 310495, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 10, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc", "tx_index": 496}',0);
INSERT INTO messages VALUES(115,310496,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310496, "event": "1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(116,310496,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "XCP", "block_index": 310496, "event": "1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(117,310496,'insert','sends','{"asset": "XCP", "block_index": 310496, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 92945878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6", "tx_index": 497}',0);
INSERT INTO messages VALUES(118,310497,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310497, "event": "076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f", "quantity": 50000000}',0);
INSERT INTO messages VALUES(119,310497,'insert','issuances','{"asset": "PARENT", "asset_longname": null, "block_index": 310497, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Parent asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f", "tx_index": 498}',0);
INSERT INTO messages VALUES(120,310497,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "PARENT", "block_index": 310497, "event": "076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f", "quantity": 100000000}',0);
INSERT INTO messages VALUES(121,310498,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310498, "event": "0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf", "quantity": 25000000}',0);
INSERT INTO messages VALUES(122,310498,'insert','issuances','{"asset": "A95428956661682277", "asset_longname": "PARENT.already.issued", "block_index": 310498, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Child of parent", "divisible": true, "fee_paid": 25000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf", "tx_index": 499}',0);
INSERT INTO messages VALUES(123,310498,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "A95428956661682277", "block_index": 310498, "event": "0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf", "quantity": 100000000}',0);
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
INSERT INTO undolog VALUES(143,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92050000000 WHERE rowid=1');
INSERT INTO undolog VALUES(144,'DELETE FROM debits WHERE rowid=25');
INSERT INTO undolog VALUES(145,'UPDATE balances SET address=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',asset=''XCP'',quantity=99999990 WHERE rowid=7');
INSERT INTO undolog VALUES(146,'DELETE FROM credits WHERE rowid=25');
INSERT INTO undolog VALUES(147,'DELETE FROM sends WHERE rowid=482');
INSERT INTO undolog VALUES(148,'UPDATE balances SET address=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',asset=''XCP'',quantity=199999990 WHERE rowid=7');
INSERT INTO undolog VALUES(149,'DELETE FROM debits WHERE rowid=26');
INSERT INTO undolog VALUES(150,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91950000000 WHERE rowid=1');
INSERT INTO undolog VALUES(151,'DELETE FROM credits WHERE rowid=26');
INSERT INTO undolog VALUES(152,'DELETE FROM sends WHERE rowid=483');
INSERT INTO undolog VALUES(153,'DELETE FROM broadcasts WHERE rowid=487');
INSERT INTO undolog VALUES(154,'UPDATE balances SET address=''myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM'',asset=''XCP'',quantity=92999138821 WHERE rowid=13');
INSERT INTO undolog VALUES(155,'DELETE FROM debits WHERE rowid=27');
INSERT INTO undolog VALUES(156,'DELETE FROM bets WHERE rowid=5');
INSERT INTO undolog VALUES(157,'DELETE FROM broadcasts WHERE rowid=489');
INSERT INTO undolog VALUES(158,'DELETE FROM addresses WHERE rowid=1');
INSERT INTO undolog VALUES(159,'DELETE FROM broadcasts WHERE rowid=490');
INSERT INTO undolog VALUES(160,'DELETE FROM broadcasts WHERE rowid=491');
INSERT INTO undolog VALUES(161,'DELETE FROM addresses WHERE rowid=2');
INSERT INTO undolog VALUES(162,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92050000000 WHERE rowid=1');
INSERT INTO undolog VALUES(163,'DELETE FROM debits WHERE rowid=28');
INSERT INTO undolog VALUES(164,'DELETE FROM orders WHERE rowid=5');
INSERT INTO undolog VALUES(165,'DELETE FROM orders WHERE rowid=6');
INSERT INTO undolog VALUES(166,'UPDATE orders SET tx_index=492,tx_hash=''9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09'',block_index=310491,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''XCP'',give_quantity=100000000,give_remaining=100000000,get_asset=''BTC'',get_quantity=800000,get_remaining=800000,expiration=2000,expire_index=312491,fee_required=900000,fee_required_remaining=900000,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(167,'UPDATE orders SET tx_index=493,tx_hash=''2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4'',block_index=310492,source=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',give_asset=''BTC'',give_quantity=800000,give_remaining=800000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=2000,expire_index=312492,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=6');
INSERT INTO undolog VALUES(168,'DELETE FROM order_matches WHERE rowid=1');
INSERT INTO undolog VALUES(169,'DELETE FROM balances WHERE rowid=20');
INSERT INTO undolog VALUES(170,'DELETE FROM credits WHERE rowid=27');
INSERT INTO undolog VALUES(171,'DELETE FROM burns WHERE rowid=494');
INSERT INTO undolog VALUES(172,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''XCP'',quantity=92995878046 WHERE rowid=20');
INSERT INTO undolog VALUES(173,'DELETE FROM debits WHERE rowid=29');
INSERT INTO undolog VALUES(174,'DELETE FROM assets WHERE rowid=10');
INSERT INTO undolog VALUES(175,'DELETE FROM issuances WHERE rowid=495');
INSERT INTO undolog VALUES(176,'DELETE FROM balances WHERE rowid=21');
INSERT INTO undolog VALUES(177,'DELETE FROM credits WHERE rowid=28');
INSERT INTO undolog VALUES(178,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''DIVIDEND'',quantity=100 WHERE rowid=21');
INSERT INTO undolog VALUES(179,'DELETE FROM debits WHERE rowid=30');
INSERT INTO undolog VALUES(180,'DELETE FROM balances WHERE rowid=22');
INSERT INTO undolog VALUES(181,'DELETE FROM credits WHERE rowid=29');
INSERT INTO undolog VALUES(182,'DELETE FROM sends WHERE rowid=496');
INSERT INTO undolog VALUES(183,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''XCP'',quantity=92945878046 WHERE rowid=20');
INSERT INTO undolog VALUES(184,'DELETE FROM debits WHERE rowid=31');
INSERT INTO undolog VALUES(185,'DELETE FROM balances WHERE rowid=23');
INSERT INTO undolog VALUES(186,'DELETE FROM credits WHERE rowid=30');
INSERT INTO undolog VALUES(187,'DELETE FROM sends WHERE rowid=497');
INSERT INTO undolog VALUES(188,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91950000000 WHERE rowid=1');
INSERT INTO undolog VALUES(189,'DELETE FROM debits WHERE rowid=32');
INSERT INTO undolog VALUES(190,'DELETE FROM assets WHERE rowid=11');
INSERT INTO undolog VALUES(191,'DELETE FROM issuances WHERE rowid=498');
INSERT INTO undolog VALUES(192,'DELETE FROM balances WHERE rowid=24');
INSERT INTO undolog VALUES(193,'DELETE FROM credits WHERE rowid=31');
INSERT INTO undolog VALUES(194,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91900000000 WHERE rowid=1');
INSERT INTO undolog VALUES(195,'DELETE FROM debits WHERE rowid=33');
INSERT INTO undolog VALUES(196,'DELETE FROM assets WHERE rowid=12');
INSERT INTO undolog VALUES(197,'DELETE FROM issuances WHERE rowid=499');
INSERT INTO undolog VALUES(198,'DELETE FROM balances WHERE rowid=25');
INSERT INTO undolog VALUES(199,'DELETE FROM credits WHERE rowid=32');

-- Table  undolog_block
DROP TABLE IF EXISTS undolog_block;
CREATE TABLE undolog_block(
                        block_index INTEGER PRIMARY KEY,
                        first_undo_index INTEGER);
INSERT INTO undolog_block VALUES(310400,143);
INSERT INTO undolog_block VALUES(310401,143);
INSERT INTO undolog_block VALUES(310402,143);
INSERT INTO undolog_block VALUES(310403,143);
INSERT INTO undolog_block VALUES(310404,143);
INSERT INTO undolog_block VALUES(310405,143);
INSERT INTO undolog_block VALUES(310406,143);
INSERT INTO undolog_block VALUES(310407,143);
INSERT INTO undolog_block VALUES(310408,143);
INSERT INTO undolog_block VALUES(310409,143);
INSERT INTO undolog_block VALUES(310410,143);
INSERT INTO undolog_block VALUES(310411,143);
INSERT INTO undolog_block VALUES(310412,143);
INSERT INTO undolog_block VALUES(310413,143);
INSERT INTO undolog_block VALUES(310414,143);
INSERT INTO undolog_block VALUES(310415,143);
INSERT INTO undolog_block VALUES(310416,143);
INSERT INTO undolog_block VALUES(310417,143);
INSERT INTO undolog_block VALUES(310418,143);
INSERT INTO undolog_block VALUES(310419,143);
INSERT INTO undolog_block VALUES(310420,143);
INSERT INTO undolog_block VALUES(310421,143);
INSERT INTO undolog_block VALUES(310422,143);
INSERT INTO undolog_block VALUES(310423,143);
INSERT INTO undolog_block VALUES(310424,143);
INSERT INTO undolog_block VALUES(310425,143);
INSERT INTO undolog_block VALUES(310426,143);
INSERT INTO undolog_block VALUES(310427,143);
INSERT INTO undolog_block VALUES(310428,143);
INSERT INTO undolog_block VALUES(310429,143);
INSERT INTO undolog_block VALUES(310430,143);
INSERT INTO undolog_block VALUES(310431,143);
INSERT INTO undolog_block VALUES(310432,143);
INSERT INTO undolog_block VALUES(310433,143);
INSERT INTO undolog_block VALUES(310434,143);
INSERT INTO undolog_block VALUES(310435,143);
INSERT INTO undolog_block VALUES(310436,143);
INSERT INTO undolog_block VALUES(310437,143);
INSERT INTO undolog_block VALUES(310438,143);
INSERT INTO undolog_block VALUES(310439,143);
INSERT INTO undolog_block VALUES(310440,143);
INSERT INTO undolog_block VALUES(310441,143);
INSERT INTO undolog_block VALUES(310442,143);
INSERT INTO undolog_block VALUES(310443,143);
INSERT INTO undolog_block VALUES(310444,143);
INSERT INTO undolog_block VALUES(310445,143);
INSERT INTO undolog_block VALUES(310446,143);
INSERT INTO undolog_block VALUES(310447,143);
INSERT INTO undolog_block VALUES(310448,143);
INSERT INTO undolog_block VALUES(310449,143);
INSERT INTO undolog_block VALUES(310450,143);
INSERT INTO undolog_block VALUES(310451,143);
INSERT INTO undolog_block VALUES(310452,143);
INSERT INTO undolog_block VALUES(310453,143);
INSERT INTO undolog_block VALUES(310454,143);
INSERT INTO undolog_block VALUES(310455,143);
INSERT INTO undolog_block VALUES(310456,143);
INSERT INTO undolog_block VALUES(310457,143);
INSERT INTO undolog_block VALUES(310458,143);
INSERT INTO undolog_block VALUES(310459,143);
INSERT INTO undolog_block VALUES(310460,143);
INSERT INTO undolog_block VALUES(310461,143);
INSERT INTO undolog_block VALUES(310462,143);
INSERT INTO undolog_block VALUES(310463,143);
INSERT INTO undolog_block VALUES(310464,143);
INSERT INTO undolog_block VALUES(310465,143);
INSERT INTO undolog_block VALUES(310466,143);
INSERT INTO undolog_block VALUES(310467,143);
INSERT INTO undolog_block VALUES(310468,143);
INSERT INTO undolog_block VALUES(310469,143);
INSERT INTO undolog_block VALUES(310470,143);
INSERT INTO undolog_block VALUES(310471,143);
INSERT INTO undolog_block VALUES(310472,143);
INSERT INTO undolog_block VALUES(310473,143);
INSERT INTO undolog_block VALUES(310474,143);
INSERT INTO undolog_block VALUES(310475,143);
INSERT INTO undolog_block VALUES(310476,143);
INSERT INTO undolog_block VALUES(310477,143);
INSERT INTO undolog_block VALUES(310478,143);
INSERT INTO undolog_block VALUES(310479,143);
INSERT INTO undolog_block VALUES(310480,143);
INSERT INTO undolog_block VALUES(310481,143);
INSERT INTO undolog_block VALUES(310482,148);
INSERT INTO undolog_block VALUES(310483,153);
INSERT INTO undolog_block VALUES(310484,153);
INSERT INTO undolog_block VALUES(310485,153);
INSERT INTO undolog_block VALUES(310486,153);
INSERT INTO undolog_block VALUES(310487,154);
INSERT INTO undolog_block VALUES(310488,157);
INSERT INTO undolog_block VALUES(310489,159);
INSERT INTO undolog_block VALUES(310490,160);
INSERT INTO undolog_block VALUES(310491,162);
INSERT INTO undolog_block VALUES(310492,165);
INSERT INTO undolog_block VALUES(310493,169);
INSERT INTO undolog_block VALUES(310494,172);
INSERT INTO undolog_block VALUES(310495,178);
INSERT INTO undolog_block VALUES(310496,183);
INSERT INTO undolog_block VALUES(310497,188);
INSERT INTO undolog_block VALUES(310498,194);
INSERT INTO undolog_block VALUES(310499,200);
INSERT INTO undolog_block VALUES(310500,200);

-- For primary key autoincrements the next id to use is stored in
-- sqlite_sequence
DELETE FROM main.sqlite_sequence WHERE name='undolog';
INSERT INTO main.sqlite_sequence VALUES ('undolog', 199);

COMMIT TRANSACTION;
