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
INSERT INTO blocks VALUES(309999,'8b3bef249cb3b0fa23a4936c1249b6bd41daeadc848c8d2e409ea1cbc10adfe7',309999000,NULL,NULL,'3e2cd73017159fdc874453f227e9d0dc4dabba6d10e03458f3399f1d340c4ad1','3e2cd73017159fdc874453f227e9d0dc4dabba6d10e03458f3399f1d340c4ad1','3e2cd73017159fdc874453f227e9d0dc4dabba6d10e03458f3399f1d340c4ad1');
INSERT INTO blocks VALUES(310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,NULL,NULL,'f3e1d432b546670845393fae1465975aa99602a7648e0da125e6b8f4d55cbcac','618a3685c96778f3bbb71b6238959cc62e936f25461a33778e976c64afdf1865','0692da030e79edba303afe4d4b55ba6ec32b7806b156954168fb5b6aba626e93');
INSERT INTO blocks VALUES(310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,NULL,NULL,'6a91073b35d1151c0b9b93f7916d25e6650b82fe4a1b006851d69b1112cd2954','525269b7af5e86ba014e1890b3f6847b9606124b5d2c5a848417b8ee2855cf87','7d6d9a61ab3bab601341262a77d44fa65d57cd0d27dc277434536d5463739017');
INSERT INTO blocks VALUES(310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,NULL,NULL,'88eac1faa671a7ebc61f63782c4b74d42c813c19e410e240843440f4d4dbaa35','c4e691a954156084c2039a0f9c9168ef0ff8c88d0182523eef556e0b41e2bd1c','d0ac4572067fe66829985e385b5c615aabe15426f0ee1fbfa509f122e31e5d56');
INSERT INTO blocks VALUES(310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,NULL,NULL,'93d430c0d7a680aad6fb162af200e95e177ba5d604df1e3cb0e086d3959538c3','603d42f18c7c25f377761aa64b55a71330e48986677756b23d0e9ccef6f790fa','0db142f45b6fdb93971c0a77cb204efb6eecfb6b14f33cf9ded9b78050c6b62a');
INSERT INTO blocks VALUES(310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,NULL,NULL,'e85e5d82a20fe2e060a7c1f79dc182d3b2da28903b04302e6abe4a3f935ea373','1eb57edfcdc5b1a432fb5513dd0d0d9ec5aac1103043e99e584ac37dffe84c84','c9da32d33785e0e1358ac5e8f9a1c4899aa2415c83b31de0f3697d50dd0446ef');
INSERT INTO blocks VALUES(310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,NULL,NULL,'c6c0f780ffa18de5a5e5afdf4fba5b6a17dce8d767d4b7a9fbbae2ad53ff4718','bbfc7943a35c5a9402f4071ee3bc48c1672fd7378d82afd1b8ff439c56649cc8','ec24b9874bb7209163dfee7e0fd8f7023058c6afffcabea24376a805efaf5fad');
INSERT INTO blocks VALUES(310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,NULL,NULL,'91458f37f5293fca71cddc6f14874670584e750aa68fbe577b22eac357c5f336','a808bb9551efbfbc26d3063cee963a9c01958c02ca587af8767eb2b18690cc83','f0b4fd409e6f6d53daf6f6716d6d8abdec1a2aa2266a7ecc9f9c3e3e6123e3b7');
INSERT INTO blocks VALUES(310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,NULL,NULL,'a8f0f81aebdf77ee1945c2199142696f2c74518f2bc1a45dcfd3cebcabec510c','969913e916e08a6ce17ad80089e8901beb8ff777e2fd8f0e146c44b40a7ae3da','7e5244c1c41cd872265e0bff60140774a1d319da6639c77b4bcc75ce667782de');
INSERT INTO blocks VALUES(310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,NULL,NULL,'df7cae2ef1885eb5916f821be0bb11c24c9cabdc6ccdc84866d60de6af972b94','ba7a76d75158ed56b7c2222aaa9391d824ad0a92ba756ca83965540411708914','b66dc06e8d6af7d4c86495b585628fc3f2ed59528c92d0d929725db620c2a3a7');
INSERT INTO blocks VALUES(310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,NULL,NULL,'1d8caac58a9e5a656a6631fe88be72dfb45dbc25c64d92558db268be01da6024','9ceba654e61956137921a48d84210b8f07548b906cd0a5dc4d4763044f17d19e','38d77706e08839bd823c5855d7614cd2f7931c931e2ba3ce38ac7fef0da7635f');
INSERT INTO blocks VALUES(310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,NULL,NULL,'ab78a209c465104945458dba209c03409f839d4882a1bf416c504d26fd8b9c80','507c214e078414fe33aa6910c702719013dd8c329d7f480743c976c8cbcf946f','eebae2f0bd94db895f75244735074d36c398c77837b1de426855abe5b39e3f3d');
INSERT INTO blocks VALUES(310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,NULL,NULL,'5528fec20bfacc31dd43d7284bf1df33e033ec0ac12b14ed813a9dfea4f67741','dc152bde626e494fb6a5d60626c682b00902f358d5e1a5bce66dfd1af862fd1b','62d4d72e57b4896f87b653e64776650ab21a851ae3586ab68f9dac6113596232');
INSERT INTO blocks VALUES(310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,NULL,NULL,'fa66dc025cbb75b67a7d4c496141eb5f6f0cc42134433276c8a294c983453926','c47e71e872dc7aa711bd7ec005c3513d03fb056ff5f1f32179dd7f69320d0401','3a8b87a3ab47301560c02302ea07f34db2de41df5111d6801fd7749225fa0750');
INSERT INTO blocks VALUES(310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,NULL,NULL,'442621791a488568ee9dee5d9131db3ce2f17d9d87b4f45dc8079606874823f8','12e96dd5cba317e044fa8a9cd45cc9853da0c4e601a48e8368959040a989623d','3293ae929c8d056b856341c8e37195686669cd9ad0f6866fd93bec667e97dbbe');
INSERT INTO blocks VALUES(310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,NULL,NULL,'8551367f346e50b15c6e0cca116d1697d3301725b73562f62d8e4c53581e7bd0','a09303c3dbd30d1534f1967f911df8ff64ea14be670042dd3f46a8a1c917e560','c53e954c78a3ba9a3fd2ad3d3dc3d77b8eda430260f95ed8259f0ba510d0fb1d');
INSERT INTO blocks VALUES(310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,NULL,NULL,'29de016d6301c2c9be33c98d3ca3e5f2dd25d52fd344426d40e3b0126dea019a','084891b00e117fbe7f5a11b41b329ab81666ce160ac58657dda59f9a58e968db','a8872a866e5887ceb47c2d963b6cbb45b56e06dceb7545d4587c80a811e8fd45');
INSERT INTO blocks VALUES(310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,NULL,NULL,'32ffd4bdf9b1f8506a25b4d2affe792d1eccf322a9ab832ec71a934fea136db9','640fd8cab7ace14868fa5fe21c69cdca8e24e30fc3f0b51d50f0e037f7097a72','2a4e12ec8cf7f6cceb61fdece62cbf9dd507d8081d72e583e020a21735a4c361');
INSERT INTO blocks VALUES(310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,NULL,NULL,'64aa58f7e48dfa10bb48ecf48571d832bb94027c7ac07be0d23d5379452ce03b','e96cc4b9a2f9b37812b1b01be1a3cf893a0f81ebdd0d3a9b4882534a833419f9','cd7f977a1b9491a5bb5bc45b251486545b3b745b027e7f2d0e5849319644fdd3');
INSERT INTO blocks VALUES(310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,NULL,NULL,'8d8f404bdc2fb6178286b2581cf8a23e6028d5d285091fa0e67e96e6da91f54e','8eaf9833d2f4c3df723d247657d29eeeb603c4413151a7eed2ff298d45760871','bae7d0dfca3f39b6d13ff0635bab790ba203f892c2c4cd63377003397c821233');
INSERT INTO blocks VALUES(310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,NULL,NULL,'945a8fd2f57cfd5ddab542291fb2e2813762806b806a3e65e688321fefe1986d','94d15ef45dbe625b6d789010819c688930138cd93a275212f7ed6f32f590ee29','8fa4e22f67349114488d749d0b63b108962e38e399c6f4d4de5196282cfe6f27');
INSERT INTO blocks VALUES(310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,NULL,NULL,'3393abc111ee337132103ca04b4f8745952cd03ddbd6efff58a589e00a48fa21','9fac8cc3be8d015bac54e374c6e2ce3d12fc8088ea611a6976cfb0f2520910ba','c0168bac5f0190677dc95c107c1a2092c8dee55a0a1dc974d495e0b94b2e80b7');
INSERT INTO blocks VALUES(310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,NULL,NULL,'d05fe9705db7b30e6ea6b18e9ae92ba794dd72f25b4e33daf4d46b3b609a02de','23fe774d44f7273ba280efdd2a98aad602a9247c1ac423a8107451b8f2137bc6','8667218148fa90a2ae2e671dbd9e1a3175a317362607790b1549d7b2a981fd55');
INSERT INTO blocks VALUES(310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,NULL,NULL,'c2b2b2c3bdd895c74f3ea22db3d9c66301578436b6fa9175ce0b242c4bfaccc5','a9ab43f735417a96f0328ea7dd7af797dbb43995c53fa36fc2b56be10cf49d79','bf5b40aba223ad7ec36ce6c71cd7b245b6fa63669d6f66e4d3d94974fd9aec77');
INSERT INTO blocks VALUES(310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,NULL,NULL,'fad5b61545d8ef317918f07df063554d4f321c0ebf462f759513212960bdf523','c9259febd6ae9a497cc82e43530ed4276532333dc209eb2056a4ef92f588cf88','2fee13dc1e8ee7c98233e8edda767aabd2400c9dbd37aa4a4e57f1fef8d7b220');
INSERT INTO blocks VALUES(310024,'b03042b4e18a222b4c8d1e9e1970d93e6e2a2d41686d227ff8ecf0a839223dc5',310024000,NULL,NULL,'61a71d0ac67eba15c63a531f797e6d68c83613489730bc2b4e4054094f63105a','287eba8fc2f22c2e5ebf0ee804850f79c68963c2fc4d28f0844dc81ff60b8db9','094e27c327ad95e0c3de4b35fe2c7c01f1f35b30e06b3d8737cbd547dc15f7da');
INSERT INTO blocks VALUES(310025,'a872e560766832cc3b4f7f222228cb6db882ce3c54f6459f62c71d5cd6e90666',310025000,NULL,NULL,'f7d41404c3d1e57bbc390af958d1596212112068e4986954d11ff8abd13bc8e4','b82dbb5b0e9f372342cf759ce59d351ff5d069fd3a85f0bb82bb79c477cef586','435a8295b51e3e9a6146c0888ae250d046e3f8faddcf76e05a568abce8182c92');
INSERT INTO blocks VALUES(310026,'6c96350f6f2f05810f19a689de235eff975338587194a36a70dfd0fcd490941a',310026000,NULL,NULL,'31530d7febb577d7588e12d10629fd82966df48a93a613a480879531d5dbd374','d61eef548f4bd418414d191edfe39efb1ef1c3f526c43543548261b7f38b3cf6','20e70721b622e8df98d7f574f77d3eea04e9817fc04071a3f322f420e8168dfb');
INSERT INTO blocks VALUES(310027,'d7acfac66df393c4482a14c189742c0571b89442eb7f817b34415a560445699e',310027000,NULL,NULL,'f54085346ae4608c57c55d321a413a00ffeb85499138559d7d05245f57cc0da3','bf3c0498cbbb0be13f0382690cc714822a5581a95886c4d23e72d80194b05fd3','1c57b47e513efce185e5aa034edaf64d1f46362798f215ad15dbce55c366ccb4');
INSERT INTO blocks VALUES(310028,'02409fcf8fa06dafcb7f11e38593181d9c42cc9d5e2ddc304d098f990bd9530b',310028000,NULL,NULL,'a841b7f634fc24553d1c8cb2d66fc3103293dcfd297cb5bf241b0c5da84bd376','375a9366ef7a2ddb774e71600f28fc1836f4feb9ce6e204e1c10a1d7c4c22bef','8dd02a1b43f73bcf71cbb980ccbe2705b21c8cb49c888072ecd16b7d15b3f3a7');
INSERT INTO blocks VALUES(310029,'3c739fa8b40c118d5547ea356ee8d10ee2898871907643ec02e5db9d00f03cc6',310029000,NULL,NULL,'69d40c69b4989f7a59da99b56577b0651887d9422757e38d5410379f95fda641','8deb8fa094a7c0ecc486bc28589edf66da1910b35bd3d2f3d2599741fefe17c8','18fb6e5d473dc81b75a32e290e7ff317b45146b69517d7bac29c471218b2d183');
INSERT INTO blocks VALUES(310030,'d5071cddedf89765ee0fd58f209c1c7d669ba8ea66200a57587da8b189b9e4f5',310030000,NULL,NULL,'192fe51d3a7af659670a8899582c29aedf3a5608ca906b274ce986751dad2d7a','f3210c9464f6483a9ebf2f3250d47458e336da8af778bfa022d64f0cee27adc8','c479e7b5e988c6fbf845400699bc54204d069c71181bfcfaa5708b805ec1aabd');
INSERT INTO blocks VALUES(310031,'0b02b10f41380fff27c543ea8891ecb845bf7a003ac5c87e15932aff3bfcf689',310031000,NULL,NULL,'125784cdeba1e433b3411c368cdf676efb33021f51c26a8b2bd6ec00fe4f767d','afb464e5efb79c0bc1460323cf94f08c3a69e58171bef210d0bbda5885ac6e6d','9fad8cadf42b9616680a5708f80fc238979c1a71949b6e92e700b6d94d1b5d81');
INSERT INTO blocks VALUES(310032,'66346be81e6ba04544f2ae643b76c2b7b1383f038fc2636e02e49dc7ec144074',310032000,NULL,NULL,'fa7832080a2b6ae8829794d70603351755fa4816f15a6e92716f83265daa59a4','19dee3d0ab0acafa71af9cf3b6743a3584a554590cd6282cb2f2a6faa4b9289c','6ba65387df8b2cd9b65424532734981433f457549ced20ac294b30662037b34e');
INSERT INTO blocks VALUES(310033,'999c65df9661f73e8c01f1da1afda09ac16788b72834f0ff5ea3d1464afb4707',310033000,NULL,NULL,'7b86f430bc44ad5d81a43b5a8ea118b458d995e3832d88bb74bc62429194e45c','f5f612745dad69028ef02cb06600f2dfc41c8ae0c676ebb49a8688394a95c4a5','b46114b535e0fefeee67ddc54afdb4378a66a5de57a3465d4df7015afcf4d497');
INSERT INTO blocks VALUES(310034,'f552edd2e0a648230f3668e72ddf0ddfb1e8ac0f4c190f91b89c1a8c2e357208',310034000,NULL,NULL,'1f2c5ac4375f77fb79612d343dd5fc4489cf94ff983fc05ba2009a9e390d6c06','7baf7262763f5365a80e347d4f90359cc084c2e5215f72ca3ca4b56c9eedaf17','6078573ea84ffb759b20e7f0b359e315f39d7c21a00795bb942597a5df149f52');
INSERT INTO blocks VALUES(310035,'a13cbb016f3044207a46967a4ba1c87dab411f78c55c1179f2336653c2726ae2',310035000,NULL,NULL,'81cdae9b978935ad40a1032e7f22ddd7117b9c7580d6d7e4b7e20d1c875f5e63','920075d57ba2b61e7bb50eea78e6264c437690db95aaad4a3600abc89068d8cd','ca363aae83ec768844ae403c6164583e112abce585d7af4f2e32cae90d88afde');
INSERT INTO blocks VALUES(310036,'158648a98f1e1bd1875584ce8449eb15a4e91a99a923bbb24c4210135cef0c76',310036000,NULL,NULL,'ff02952dce15c249501d8485decad0ad9fe02fda766b7b83720806f726d02ee4','ed329fe2b819509af0b02c8a0a814d2d9b0beab1b5bb73bef34d8bf61350b60a','b5a41ad9ae91ae155269d2a2728156f224256d05174ec084ea4e128f022826d8');
INSERT INTO blocks VALUES(310037,'563acfd6d991ce256d5655de2e9429975c8dceeb221e76d5ec6e9e24a2c27c07',310037000,NULL,NULL,'760e5a00feb6c8c4baf4421ad07be2af962bfcac7705b773484b449356d6c230','a8ebc16699295d620859377e5b8c055cdc36409d3d92cbc8554b11e5fdb23032','5e8a48c62a98570d44b940f9971115819a23d0dff76b049dd558b98112befd33');
INSERT INTO blocks VALUES(310038,'b44b4cad12431c32df27940e18d51f63897c7472b70950d18454edfd640490b2',310038000,NULL,NULL,'c79381c51fa93cc320d8bf19c943f98232a99446ac098ff66823cf691e0fa01c','a6094408a64b13aab8e951c9e8152d5ae9e5af4ef9a4430d13fee2711b50290e','9cc050f47f38d78685c33d2b8ba196150d2f46b7c4c79c299b60cd2e27ce1880');
INSERT INTO blocks VALUES(310039,'5fa1ae9c5e8a599247458987b006ad3a57f686df1f7cc240bf119e911b56c347',310039000,NULL,NULL,'7382f007315783c9a6ffd29bc0eaa62282c6ec72c5fff09322d6dea6b0ee3a96','0be39038cfa93496e048608200d5cb722a2cab584497d93fed4bd99f2c785fda','6093b54bcedd3072495053e1c1d682ce0e9486ea74a34779e6c22e6d6fe023b7');
INSERT INTO blocks VALUES(310040,'7200ded406675453eadddfbb2d14c2a4526c7dc2b5de14bd48b29243df5e1aa3',310040000,NULL,NULL,'38d3b548be554a0ae92504244a88930b989ea6fefc9bc59c69b68ed560afee9a','f22afc907cb18eb1c9032a094301ad3beb2d53dddc181640cf2e32d51f499573','1ea1bfd30c34338234521a6bffee842c06a91b55db699e22e6e8b20ae97fb5b9');
INSERT INTO blocks VALUES(310041,'5db592ff9ba5fac1e030cf22d6c13b70d330ba397f415340086ee7357143b359',310041000,NULL,NULL,'0c1c7aa19c015a67da214bf8a6ae3d77979a09de6a63621e320a28ceebdbf333','21658e8e065b244c2f4115a0d83254c94f146e3eb72de6f358d7971f1e360b11','221d3835ae78ca489fac8db184cf12ca0e95f7923180efdc2604af7f207d06ae');
INSERT INTO blocks VALUES(310042,'826fd4701ef2824e9559b069517cd3cb990aff6a4690830f78fc845ab77fa3e4',310042000,NULL,NULL,'9d20f77d4afff9179cffe46574f1b2dd23d2987142c943de05e411baee2dbf05','4e2aca95a9dc0406370179becf9e1708a8e7c25e8940c498aea4518017caa2c3','86b05b67972322231404ccd7932fd8348a4d656a5a1a3955567b03c22cd99449');
INSERT INTO blocks VALUES(310043,'2254a12ada208f1dd57bc17547ecaf3c44720323c47bc7d4b1262477cb7f3c51',310043000,NULL,NULL,'d818e5a1a5cb6c59771b63997a8737cdb041c3579de1ecd808a269f5d72a3abf','4fc3e4ca19de91120e81a0b67b67f9a62d660e81d591a73db421125589cccc79','222280946f2aecfc75d22e1113ddd8d04ade72e2bc1ca4f27ecd088fd86c0bb6');
INSERT INTO blocks VALUES(310044,'3346d24118d8af0b3c6bcc42f8b85792e7a2e7036ebf6e4c25f4f6723c78e46b',310044000,NULL,NULL,'9de166ff18c5eec97b838292ae894ce18e5a890e8a841a294b2d14894c60a0d7','eac4ae79110e45ba505f19651743301fbef5e5f38ffdf66fcf4437f96010ae45','e4cd29a89a87655c711908ce82fc43ce415566f67b0aae8dc0170744434017d6');
INSERT INTO blocks VALUES(310045,'7bba0ab243839e91ad1a45a762bf074011f8a9883074d68203c6d1b46fffde98',310045000,NULL,NULL,'bb3c0a260dc082534c95e894751e38e80de117b091bc0e34c66134d374b8db2d','bd4fc4b0f155c44d48f0e884cbaa52b54a96241f1e351a6c34b19ca0a80a93d4','489cedfd075a9426eaf6a9bad78a7f47d1cc6a9bc6a7408af1234c52ae3a9107');
INSERT INTO blocks VALUES(310046,'47db6788c38f2d6d712764979e41346b55e78cbb4969e0ef5c4336faf18993a6',310046000,NULL,NULL,'b4605c50ee3e5e2958c908e099563cf997e20932cc2370109ab50049e43723cf','7150590496ac405b231b4046ee79948e28496b1eb45a498b9faaa08752a0aebb','2a305a560cf056b617ebcb434e3fb2881bb54fc0a14d7af229122eb0f394195e');
INSERT INTO blocks VALUES(310047,'a9ccabcc2a098a7d25e4ab8bda7c4e66807eefa42e29890dcd88149a10de7075',310047000,NULL,NULL,'b840a7af6301c798c9a6670308a2684051ff8f3fb2e69bddaafa82cfd3d83186','d3bb4e192aa08e803ef635b3ca0dfed044f5194814be3bda54cc8fb41baa37b0','daaf96b257861628e1eb312ed8ef3f21f3fe3392437f997679cb2d0a84c3da94');
INSERT INTO blocks VALUES(310048,'610bf3935a85b05a98556c55493c6de45bed4d7b3b6c8553a984718765796309',310048000,NULL,NULL,'6bd591d3336ea112789ad6675a9b1d8e1578fe42e44ca7f7be5557089d374c3f','354db04818b10a6c51da8f8f011e97b2562ee25f6184db42909c5c0bfa15d28c','af4d976f6d704d2bfb67ff752f21f04869e0bdcf9979e7446f16f97732d51c0c');
INSERT INTO blocks VALUES(310049,'4ad2761923ad49ad2b283b640f1832522a2a5d6964486b21591b71df6b33be3c',310049000,NULL,NULL,'04fe1e6631d503a9ee646584cda33857fac6eeca11fa60d442e09b2ed1380e5c','5fd6643e9411ba810e86a41a00b0e1b28ff8bf6e1b205aa14e8279be0f7b141c','145f24b8994175dea9a09c623eb569ad1050c8aa767a071107f497aaaadf20f7');
INSERT INTO blocks VALUES(310050,'8cfeb60a14a4cec6e9be13d699694d49007d82a31065a17890383e262071e348',310050000,NULL,NULL,'dc73bfb66386f237f127f607a4522c0a8c650b6d0f76a87e30632938cf905155','397fb2ac2122ed4f39eed86e0919f812125f4d9756aa3e7c1ff1db8b2ca375ec','310e93edc77e3b4276931f62e68f84c22e5cbc3f30f00c13c7ac678b161e6a68');
INSERT INTO blocks VALUES(310051,'b53c90385dd808306601350920c6af4beb717518493fd23b5c730eea078f33e6',310051000,NULL,NULL,'e4eea2d144c8f9c6dfe731efee419056de42f53108f83ebee503c9114b8e4192','87760e8715387550659cdd4cf2408ae02684faa4757523938623a4addcba4ad2','2731d67656665740f085d01b00a9b6a6aa6b7832ffdc9c3d6bfa6190287e464b');
INSERT INTO blocks VALUES(310052,'0acdacf4e4b6fca756479cb055191b367b1fa433aa558956f5f08fa5b7b394e2',310052000,NULL,NULL,'8d12b561e7cf87b0aabe000a93a57e5f31db75510b1e9feb19b4f557cc0e6604','22a4b4d8509b82736c91cedfe8125b48f80266b0573794bde61d4ecf0f4859cb','0dc665d8cc59fa339e73b0841b883958feaaa3b992b32c1916abd9ac7bb3866a');
INSERT INTO blocks VALUES(310053,'68348f01b6dc49b2cb30fe92ac43e527aa90d859093d3bf7cd695c64d2ef744f',310053000,NULL,NULL,'f47b81b3dfc522d9b601d1776fa2deef8543ca077cb0743556cd970bb119d640','457a19e9e93b52d40f765f8e0af185cb1364cd5044ee163e548100acbc33d40c','d0e1c733d5a59c230d2cbaa8a5c47ff1ff1d0a68492155080d67d1e561cdae3b');
INSERT INTO blocks VALUES(310054,'a8b5f253df293037e49b998675620d5477445c51d5ec66596e023282bb9cd305',310054000,NULL,NULL,'df191ed877eb1856d6780a717c04d6925246cdee7dd6df74216ea983560d5a2b','c74ac3e1dc49aba4c16fb37096d9508e209325c876892233413be4f2c327dd9a','24f9db34f8ad374294a8813942792111b1f92135cfd5e3d2213fe24371025791');
INSERT INTO blocks VALUES(310055,'4b069152e2dc82e96ed8a3c3547c162e8c3aceeb2a4ac07972f8321a535b9356',310055000,NULL,NULL,'4b0ab72111202b1f9a5add4bf9a812df203cb6761a8d16b5f7a8b9ed6f2b2476','8cb9fbfe1a3b76922dc6c37cc97addb2a13b9baf6e6b575ddd0962f70a06fea5','40eadc6e0944f30b44b1407b060c5f5f14530b7c0ad38e687ea5f452c9b441fa');
INSERT INTO blocks VALUES(310056,'7603eaed418971b745256742f9d2ba70b2c2b2f69f61de6cc70e61ce0336f9d3',310056000,NULL,NULL,'8e76b5be6a94e1b50ba16fe265965d4cba01b792216485c54360052e78788f20','faaba869a0f9fac9501153a2f12948f966336fe3fcc9a430721b0e6515aacbae','f6fbf27621a4e12d31a17fd357fa4d49d7df5c4648dae5ad2c5c9df6b0ba37da');
INSERT INTO blocks VALUES(310057,'4a5fdc84f2d66ecb6ee3e3646aad20751ce8694e64e348d3c8aab09d33a3e411',310057000,NULL,NULL,'e14dde2bfbe4f9076b7ba548aad37269752858361af094b4be8b956c0a28b9c5','72be43050a4e5e900bdecce62811384869dba9c19e886f51fcc016e2752fb716','dbd271e7b91f672c802b9417cbbd05798820a3d079848ff186f452627c6b4f86');
INSERT INTO blocks VALUES(310058,'a6eef3089896f0cae0bfe9423392e45c48f4efe4310b14d8cfbdb1fea613635f',310058000,NULL,NULL,'b986e5f6486ceac7f1af41b1da968e453cc19376d588d8e884439b51313d6e30','350b574b2f830754f2d1f64881c8571e3ede1eeea754dc5ff80feff68b0e561b','faf2b20f096ab897ded192e52443f6a3bfbfa2e0ad3cf0447f988d433f21c317');
INSERT INTO blocks VALUES(310059,'ab505de874c43f97c90be1c26a769e6c5cb140405c993b4a6cc7afc795f156a9',310059000,NULL,NULL,'da978ee5b06812ee42cda43e1d9943c4e34e9e940cb0461f0ed463b9299402d8','cbf59f906de785ec30fff7dc1789784eba33a5d77ef7024030e9c05fda74c349','8ae3f0ada1e603ee0c6fe026331de096b3e178f71eee148698b4fd4920e52e46');
INSERT INTO blocks VALUES(310060,'974ad5fbef621e0a38eab811608dc9afaf10c8ecc85fed913075ba1a145e889b',310060000,NULL,NULL,'09ccea87988cc385b9d2580613581b90157f1366d27cd3dc1a4385e104430d15','52fa5760c080df1b0e94a61f0b15cd8955c35ff2832ada5f47733a3bc4c13ff9','f618ddf627f615476bffe405076e283f9e4fcc0e84bebce142d94341578a55f2');
INSERT INTO blocks VALUES(310061,'35d267d21ad386e7b7632292af1c422b0310dde7ca49a82f9577525a29c138cf',310061000,NULL,NULL,'4caebeb5ab6468e116cc0cf137977649a15dd30d9b214a5081057a551174ec48','552024ecbc8ab0655b966b54cd8548fd4210c3abfa24226f2b72ea57cf348351','e2056aa174e1bbf484b600631a16d3c92b2485eb95ba2097fbd2e2a1472d136e');
INSERT INTO blocks VALUES(310062,'b31a0054145319ef9de8c1cb19df5bcf4dc8a1ece20053aa494e5d3a00a2852f',310062000,NULL,NULL,'51cb3f1005127e3240721c47805d67a123afdc40084692a9cc2b3215cec99dc3','cce80d7df130137af46a5120c1088c033f3afccefba081d62d3a4c778bd45189','88b877c5cd36151e92d12ac5cc343749836c9a71a4b283436931bfcedc6c721e');
INSERT INTO blocks VALUES(310063,'0cbcbcd5b7f2dc288e3a34eab3d4212463a5a56e886804fb4f9f1cf929eadebe',310063000,NULL,NULL,'e12864a0f955320278c215897cf4f65e5c378e534294b0bb90ebd7e4b5efd4f7','e327eaa4e7adb22198876ba3609bd49e511399c6230b4b7f9efdf6fb6730036f','004ead207744abef38d15756507e931a905e7b850956906e20ca82c76d5c0b25');
INSERT INTO blocks VALUES(310064,'e2db8065a195e85cde9ddb868a17d39893a60fb2b1255aa5f0c88729de7cbf30',310064000,NULL,NULL,'ee27c3b46aa890d18be950006879874a094ecddd086db195e032fb4fe12559f5','9ab0edfd31ade89f3404b269a767170dec889fd9f581fb71f482b185e5db951c','b3b25a24ae2b2621b0ce8462120f2d5a45b2e44ebbc767f19293207460718ba0');
INSERT INTO blocks VALUES(310065,'8a7bc7a77c831ac4fd11b8a9d22d1b6a0661b07cef05c2e600c7fb683b861d2a',310065000,NULL,NULL,'d40dbc4b5faaf8918f9cae54e5a247e3904dc65994ce0f04f417c1a595404464','b98f624646064a309c2b52b8d7d6f17fa158ed7832702ff09f24451d36cbfafe','551a58d57363c10d072fede959971f07d9731d1b6c7ffc8da45067ea127de6d9');
INSERT INTO blocks VALUES(310066,'b6959be51eb084747d301f7ccaf9e75f2292c9404633b1532e3692659939430d',310066000,NULL,NULL,'19f2b00477a6fae0e10f4693d949cb409b1ed74ad20dbd9aa4a7f1f17cb813ac','113233bcdc87eaa7b63708a65508ef8fff7d162a5d95c437bbcb450724dd2f0f','badcdb3239ca2a43b896a5f4bd23ac552171596ed381d00c67a3fa9a9cd8b3a6');
INSERT INTO blocks VALUES(310067,'8b08eae98d7193c9c01863fac6effb9162bda010daeacf9e0347112f233b8577',310067000,NULL,NULL,'d72891c22fcea6c51496fc1777fa736ef5aba378320a1f718d597f8f9fea3c7d','c4a11e8713b7238e4185bb00471433ead63285612620e90f5db38cfe4ed9791b','fe4e95fb131da7f701577c3cd09c4fdae3f4129bf0c914873f19abce26bf7d50');
INSERT INTO blocks VALUES(310068,'9280e7297ef6313341bc81787a36acfc9af58f83a415afff5e3154f126cf52b5',310068000,NULL,NULL,'5793e10b8329d3ac71aed6347dfcf61fc7b74ca162ad99918f5c20065f8d0746','56c9675b58061861d82ba7bbd791e5a46e9398891e56a8db6f96b1584ae6f3d2','0944ee6cb4741e1dc37baa3894283ce2160fe4485083095a5f6d1ee94b06625f');
INSERT INTO blocks VALUES(310069,'486351f0655bf594ffaab1980cff17353b640b63e9c27239109addece189a6f7',310069000,NULL,NULL,'61040e7c1a58f41d708785347f4985c1fb522b6f947d3e14dacd91157e153ab7','d6b0c09259136a89a0f63f4f3951418800a0bd39621140e01bf91168deb792cb','18bd2a9bc7532859d6067bfe2d6f36c969b886b2ddb129c8588553d7a69fce13');
INSERT INTO blocks VALUES(310070,'8739e99f4dee8bebf1332f37f49a125348b40b93b74fe35579dd52bfba4fa7e5',310070000,NULL,NULL,'ce115625fbda90a0f261b2c524108a7393078cb4c3f861d6d7846501c7960008','34ff6bde664ce4cf9c910d096f8c1c30dfe382786a9b0ef2cb2479a53c8d53ae','b82fce0cc22eac91d307c6b8ad25e63c43a97918db6444eaad486eac00454895');
INSERT INTO blocks VALUES(310071,'7a099aa1bba0ead577f1e44f35263a1f115ed6a868c98d4dd71609072ae7f80b',310071000,NULL,NULL,'3c2d4d81e90a42a0c18e9c02b8a59f99e13f2a084ee66b4b1bd410077adc383d','656be97560010c67c8d565d7196e9c1bf59d34809166ff6e85ae264707b209d8','f2d1f342c2b03fc2c496fdad1439a88c10ce5a5fe764389c7908436ce4f7a4ae');
INSERT INTO blocks VALUES(310072,'7b17ecedc07552551b8129e068ae67cb176ca766ea3f6df74b597a94e3a7fc8a',310072000,NULL,NULL,'8a28e33306582346f1d965a0393621b4aa307f6614c84369064465f95a6c727e','81f7d6ad6a83631e3ebef7bb8330a860926689d74b40aef00e18d281fddd4ca9','de2b60d3e20a67d77c01157288184c18de3842c4228ce8385de37cdafdefce56');
INSERT INTO blocks VALUES(310073,'ee0fe3cc9b3a48a2746b6090b63b442b97ea6055d48edcf4b2288396764c6943',310073000,NULL,NULL,'e6c5b393a21df54479c4cd8e991b37d877794166c19b9f61ad7e47eb34f63bdc','e1cd4d3c5e48d0e5ddcee6012275b0091dad8e06392f34c33001d9078db93d00','ae1d670e8ab56ff3272de2342f58f78e8ad8da8cc1722442a7e046357f394af2');
INSERT INTO blocks VALUES(310074,'ceab38dfde01f711a187601731ad575d67cfe0b7dbc61dcd4f15baaef72089fb',310074000,NULL,NULL,'b2db452daf280f1cc5f02668d0cbd33732a2fe9f04307d9c072eba97c95acf5c','01f4ba98e94997bdde84132b8211015ba87a916257bdf64ec1a8ec59ddab6633','8b45d0feca4e2e7e5b78bb4f4506d7417d70bac3f251b62ae1d6e2a8cb10a43c');
INSERT INTO blocks VALUES(310075,'ef547198c6e36d829f117cfd7077ccde45158e3c545152225fa24dba7a26847b',310075000,NULL,NULL,'09998443cf1cd79e193a7b09681ae07ea9a835458151a7f8c7d80a00c5d8e99a','964bfa042751c89833cdc86fcc11ec7f901620765e638a5de9f4112d6502d6a8','7abc58508457f719534f25dead04c1bc6446b6fbf116b44a6e41621a93d1dda5');
INSERT INTO blocks VALUES(310076,'3b0499c2e8e8f0252c7288d4ecf66efc426ca37aad3524424d14c8bc6f8b0d92',310076000,NULL,NULL,'a0be1e88f10b5214f7c12dd32d0742537072d5eb3e54f9abf57a8577f7756d7e','e6e54aac82405b35166046025b8e09a09b3d4446f5f54ff21c426cc487b4ec15','38d48e6779282e75cd2cd0aea2b2b8a6e2d58df0041b284111c2119649955f85');
INSERT INTO blocks VALUES(310077,'d2adeefa9024ab3ff2822bc36acf19b6c647cea118cf15b86c6bc00c3322e7dd',310077000,NULL,NULL,'d41e39038756ee538d9438228512e31b4a524bbd05bc9b9034d603fd20e00f05','b2a9632a3e65adeb998415c27b2ddada79bcd2d54f47dc5902be5d808a6e163b','c715818edc7ab4984aecefe6e67d6df440d583dfb73f164a7c3d60a6b2572c11');
INSERT INTO blocks VALUES(310078,'f6c17115ef0efe489c562bcda4615892b4d4b39db0c9791fe193d4922bd82cd6',310078000,NULL,NULL,'996092432a2d94df1db34533aa7033e672fac73de5193a696c05ae7c30d75247','9e9e669e345b703e63097101f18a9b904edcc5d6e19efd804a8bca910837a969','c378ab333aaf85ef167941f887b5d131c032b6d786644224be698fe41d9643e2');
INSERT INTO blocks VALUES(310079,'f2fbd2074d804e631db44cb0fb2e1db3fdc367e439c21ffc40d73104c4d7069c',310079000,NULL,NULL,'e3f536e930e39b421e3a0566eba6b8f5f781ad1ff48530a5671752fd3eaf35ac','1af2b4d84fcd0a5a376016308d67d5fd5f6284910ff167f4697956650fed2562','e4c84e00940ffb3426905b74d9b0236bc3471432047e9412a6bdee35607f869c');
INSERT INTO blocks VALUES(310080,'42943b914d9c367000a78b78a544cc4b84b1df838aadde33fe730964a89a3a6c',310080000,NULL,NULL,'57122dc41d7de2bdc65002905617c357496432fa4d80af48f4ca69ba1332e634','2d1a8ddd7fa843c60b042408340e733936f335813353221305a8f297f111a3ba','a5dd30f457a3647449b23322f02b21f53a6f111b313145c57732d7595f3ac816');
INSERT INTO blocks VALUES(310081,'6554f9d307976249e7b7e260e08046b3b55d318f8b6af627fed5be3063f123c4',310081000,NULL,NULL,'3a0fc7b2f0396d257a0a5c5a313910cb4073e4c79ef8cf0d3cd12f494e563105','c3bff01f18f88171e962ed98d19bd8a9929b92bf6ed0aaec2e5cb9aebdf7e368','cf4a58d5f2fc02c85d061aba626693b1ead2c28a842c920d69391ae0ada0b6f2');
INSERT INTO blocks VALUES(310082,'4f1ef91b1dcd575f8ac2e66a67715500cbca154bd6f3b8148bb7015a6aa6c644',310082000,NULL,NULL,'e876c406f682ed6f0dbd6e4c97bac13409cd400b59e894eebeb3252be306494a','73cf84ce14954d1776613cf1c89baf72575a3a963812b452ac5c6eb45374dcaf','2f74e57134ead659c763bdfe790544ef7fb814456d1eb307e43799ab83f28029');
INSERT INTO blocks VALUES(310083,'9b1f6fd6ff9b0dc4e37603cfb0625f49067c775b99e12492afd85392d3c8d850',310083000,NULL,NULL,'533fc3eea80caa46cf8fd62745c5d21d09f32b18eaca70283a4bd72924c2100a','c3d05954bb5cce4ec513314f9b134a891b835453a21157cad5426f0f2045a029','36a866b9b1b8ee74f51097fee8f4bc08a91d1027433add81d67d6930ee547242');
INSERT INTO blocks VALUES(310084,'1e0972523e80306441b9f4157f171716199f1428db2e818a7f7817ccdc8859e3',310084000,NULL,NULL,'e3fd22f2e1470246ca99c569d187934f4b7bbb1eedb9626696cbaf9e2b46253b','f918f3dc7d57a5f1803628e594fb74ecfd257d7266bb3e1eab10902e804a501f','4f764db0c4d8150ce3759852c7c5f23b3d7e44e4a5f1f735d000f5dfbdd81c6d');
INSERT INTO blocks VALUES(310085,'c5b6e9581831e3bc5848cd7630c499bca26d9ece5156d36579bdb72d54817e34',310085000,NULL,NULL,'bf04750fe13f663adb12afd3a166636a4511bf94684a77217de1bd7ef9077d94','141d459964a8cdff1df175c5f95d8ae6d3b0914facc07fcca1efabc9e44944b7','d58e8f831767ace095f093f1aa05dbbc10e6db4bed7459c237539018350fcba0');
INSERT INTO blocks VALUES(310086,'080c1dc55a4ecf4824cf9840602498cfc35b5f84099f50b71b45cb63834c7a78',310086000,NULL,NULL,'a0e8403085ba63ba72432f27ce8125921ef24742f988ab7f85dd8e4309f27a2c','7d82c4b29150959468a06a75abbe93ae033a572e15dbc5585b5d2e6894055a3c','0401a14c3f00f37f21b154ddf5a508f87499fca4926eeb1189401ad1c9123986');
INSERT INTO blocks VALUES(310087,'4ec8cb1c38b22904e8087a034a6406b896eff4dd28e7620601c6bddf82e2738c',310087000,NULL,NULL,'0861b02e980ad5958bd23ac02603b132efd72ee2a70dbb0415fa5d39cc524681','88a3c95a21246c744935d57a58626875231e3c459f0b742d934ec07aab8e0be7','5ffd8d11c1f3058cea6d637ac36fd1ff1f9cf1401caa8cae9c8ab79b4b1bb1c3');
INSERT INTO blocks VALUES(310088,'e945c815c433cbddd0bf8e66c5c23b51072483492acda98f5c2c201020a8c5b3',310088000,NULL,NULL,'d52cdaa449f63f6d3abc79080378855206f91a5db865dfaf37a5a2529ea6eb9a','0f50bdd7a2186bd22f53c44203039f825142637053298a7f5ab06e5c2b3f2dd7','566a2bed08455e13e489b46aacf6d19de3832007a9f1597d5716063794eb4ae5');
INSERT INTO blocks VALUES(310089,'0382437f895ef3e7e38bf025fd4f606fd44d4bbd6aea71dbdc4ed11a7cd46f33',310089000,NULL,NULL,'d15a7a60b8bf8618667863b3e31eaf6202664e5aebc16d1f7a337b857ac31f90','67a00951bb0bae3143faac038292aa86ea4d1662690255be5cd661ff22fe1197','6aad3c01f46a8b353147c09be66b272ee406061e418e957d55cd4f4cce2f59d5');
INSERT INTO blocks VALUES(310090,'b756db71dc037b5a4582de354a3347371267d31ebda453e152f0a13bb2fae969',310090000,NULL,NULL,'68475dcfe8252c18501fd1fef2afa2a91d20b92cacbabb542c12f43403e66ea3','982e2d10e369e0520dbd1f16519fd27d98990e681f9d6ae9c854da85c9ff3f82','072bf7b4d25109bb22fd930367cf8399f462c00ed7192c1be9a6c9ceee3f4da1');
INSERT INTO blocks VALUES(310091,'734a9aa485f36399d5efb74f3b9c47f8b5f6fd68c9967f134b14cfe7e2d7583c',310091000,NULL,NULL,'5d584f255e5bbebc32c78a30fa816e1203fe7d3454611bef9222cdfc91dfcb63','787510e4ef984f61bdc07dbaefb36a0308d3428a6dc9b9a17aa4b1d534c7762a','161737b7b1d30d48ac7032c40d9ee0da969cb52ff4b5d1b56038c301abbab803');
INSERT INTO blocks VALUES(310092,'56386beb65f9228740d4ad43a1c575645f6daf59e0dd9f22551c59215b5e8c3d',310092000,NULL,NULL,'ef992ad033b047b7f6ab038604736f444da55be187834f8152b173cf535c68eb','fb2f02017b8b03323bb95aeefc89c2592e518117ca0d8e38a04758b72381e076','0d532f1bf3e1bad16778788a55ac3370a0cd68725df34dc6543bbd2be9a61d8e');
INSERT INTO blocks VALUES(310093,'a74a2425f2f4be24bb5f715173e6756649e1cbf1b064aeb1ef60e0b94b418ddc',310093000,NULL,NULL,'9cdee996d0e67ac3f9f283151b428ac5f223b72590965f41f93adcece6b88f2a','3e4e53831b152827757b17e46e40a6c366d3a1984fd785a3f679646eb70c0ea7','702da793ec6d0e83b9586ffa7865762aebab1b0aa6ed816566527229791bb0d8');
INSERT INTO blocks VALUES(310094,'2a8f976f20c4e89ff01071915ac96ee35192d54df3a246bf61fd4a0cccfb5b23',310094000,NULL,NULL,'fa25dc3f15fb28718d788f85373555966251f54bc6ed1f4dd2244b438d27b281','4c2b346d98bbcd766ce3fd266bd611c33181053812710986034856857201ab1a','37dec20b2f3bcdbaebd437a0b846a78b5b06a32b4baefb21e6961387d5fa78f9');
INSERT INTO blocks VALUES(310095,'bed0fa40c9981223fb40b3be8124ca619edc9dd34d0c907369477ea92e5d2cd2',310095000,NULL,NULL,'1ba8cd971f9a169d43b6de1a136cb8e6153649fde1f7a8e7fb2f7de926fdf8b2','d12f778a06bf45944a5d4521b73fbe6e0aaa3d5fdc1c689da03eed2ee72a2954','bced52bc44aa6181a8435474dd89c41497e41225b8e5fd7515831abd0329a489');
INSERT INTO blocks VALUES(310096,'306aeec3db435fabffdf88c2f26ee83caa4c2426375a33daa2be041dbd27ea2f',310096000,NULL,NULL,'42c36df2c53d762b9b132e622f52b2fca99bc0370978463acd22cdf6469587a8','d02c4857f575c413213e90be8528485521a0f538545c648cb742c7dc2e2bb864','4a310d49f296ddccbfbee790a0ebd49e6787792fc78b4765393674cb47cc3217');
INSERT INTO blocks VALUES(310097,'13e8e16e67c7cdcc80d477491e554b43744f90e8e1a9728439a11fab42cefadf',310097000,NULL,NULL,'d96af5cf3f431535689653555c29f268c931f9fb271447aed050303d364f92a8','38669845e6dada8c991c1b2410d134e53d5e372636338d0f2255c9e58e4b7d86','ee41f81fab8c31d6628c081f4d197f54f6363ef95065c9ee848d9a0ab868e299');
INSERT INTO blocks VALUES(310098,'ca5bca4b5ec4fa6183e05176abe921cff884c4e20910fab55b603cef48dc3bca',310098000,NULL,NULL,'153c9ce12e8d9f9d10c4005fc9af158613480d38b2c6551fc49bc57380c229de','2ba914748c9f07aebdb4bb1df5da75b193b1866eec3b78b6c7fdb193a01cb1f3','b3ca95bf580e261e7a55448a90a5be18d1b0e849306819cdd35f12ab4cc37bb7');
INSERT INTO blocks VALUES(310099,'3c4c2279cd7de0add5ec469648a845875495a7d54ebfb5b012dcc5a197b7992a',310099000,NULL,NULL,'49f33b269d717b56a399843cf4627449010133b47079134b9e299ac5386468ee','5fc51c8a91b6ef1f2c54714dce5843ac6c24817940af8d4f6d9c5bf20313ff99','f843fef7cc2e27b068830c7eda33bf4d10f46c4e5d59aa3fd2bf5ddc86cfe6a9');
INSERT INTO blocks VALUES(310100,'96925c05b3c7c80c716f5bef68d161c71d044252c766ca0e3f17f255764242cb',310100000,NULL,NULL,'c9e72f7db2950f0b0e6e8fa3bc47d37a0d643da6ec61b236f7224b63ac60467e','2c615fc46c8206b2c6203a6c0ad2021ea47eed5ec9c9bba6302be8e796f8c8fa','f27001bafb97a9def7a792be16a013728de8f76c94f06e7969ae0f274be3f8ba');
INSERT INTO blocks VALUES(310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,NULL,NULL,'a4387c8c785a8407f2dda176a7e182617904e7ce00c695ea8aa2f9d0429d9e74','4d0729dd6b15b65f18b39c5d516b545625c4b335b5f57b55f73f951a693a0318','12ec2f178827ed383b8dd0664127486ddc4f76d8c5d81c5ccc30ea3548ad979a');
INSERT INTO blocks VALUES(310102,'11e25883fd0479b78ddb1953ef67e3c3d1ffc82bd1f9e918a75c2194f7137f99',310102000,NULL,NULL,'fc81f97474f7b35ef92ba93de82d38650a28afd140d3320e6f6b62337cfd1e94','28615d8d9f6bf4938894c69c193e68d4ec63fa4bbc2d5456e2124589060a401e','7e6caacf1ac036bc5688d16afdb2870bf0f489f75f6d93d5175238bdcac07648');
INSERT INTO blocks VALUES(310103,'559a208afea6dd27b8bfeb031f1bd8f57182dcab6cf55c4089a6c49fb4744f17',310103000,NULL,NULL,'3a502a89a3b66438cd2b944f8951a78999ba18c5f5bc8abeafe373ae4625ed4a','2af8fec7cec78acd781ab86df43615faa422e0177ae40a68e9ea3b68cbbf1812','3954227b270c78860e5013e2521f0014cc18dc8805e80031f0cd6842658cc52d');
INSERT INTO blocks VALUES(310104,'55b82e631b61d22a8524981ff3b5e3ab4ad7b732b7d1a06191064334b8f2dfd2',310104000,NULL,NULL,'74ab5df2cdd13b654c80ef12e460120c96ce30d4690a06671474235fb93fee4a','5c4ae56b6fa3a6e0296febd99ec8c19c31d7334b369a4be2a53cd6df3317d2ce','0975723acca6c6d4b290f87f7fe4d79a7579167661ce52e24080553d937ad85c');
INSERT INTO blocks VALUES(310105,'1d72cdf6c4a02a5f973e6eaa53c28e9e13014b4f5bb13f91621a911b27fe936a',310105000,NULL,NULL,'dcc1940370421712cc668dc401169a55dd7077a49feddfd70e9e455aa5893962','42e82586926cdb6cbbeb4348cf46f1b00af26ab2e7e1c9108c8d67d53174129f','836ee76d67461d84dd9da037e5e85fea396d546090c55e05bc23113422df6046');
INSERT INTO blocks VALUES(310106,'9d39cbe8c8a5357fc56e5c2f95bf132382ddad14cbc8abd54e549d58248140ff',310106000,NULL,NULL,'6ec3678f9b647dc1ea3dfd0d76ffd240da9a94097ad29e48e7b327d6198f4f78','95c5e578476d33bd80da8856eece79efc1bc98bff2bd31e64b273a26216356a4','380738e381e4f78d71d5b1690abf231b7a4aceb38bac335061f32a586cd026e7');
INSERT INTO blocks VALUES(310107,'51cc04005e49fa49e661946a0e147240b0e5aac174252c96481ab7ddd5487435',310107000,NULL,NULL,'8e3c2d75c7a81175405f39386e2367c7a655afb53d7cf5b5c2e7dd2c79a40d9e','e276a78d716d80700a17cb27b9c9897c1e8d375f857e8b38fca7a9570e5a226d','4136b812e047ee06dedcc7051254fe8b38c3e38cdf09b65d98019a8783a86913');
INSERT INTO blocks VALUES(310108,'8f2d3861aa42f8e75dc14a23d6046bd89feef0d81996b6e1adc2a2828fbc8b34',310108000,NULL,NULL,'b00c403723eba6ffb5db3d9903fbaa8a04a783c61949b9220e2caece1a8b86eb','2457d86618bc13f9583cecd94efa29903190e325d8ab42fe679171665e1c6e16','302fd90a45064b021441031e4475936fcf5babe3cc299a379360cca1169754a1');
INSERT INTO blocks VALUES(310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,NULL,NULL,'69d2150543fe997a6685eac965283a3e7c9d3f9aa4eb2e08e8e4fe7a15054d26','be3a68316ecfe79929298d5ecf8720629773749b26dc554c07ae7460475786f5','fc96423c6fef3e8fc5793fdaffb935f86af440875821eb5007389ace01f3f091');
INSERT INTO blocks VALUES(310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,NULL,NULL,'0122bef9da908b66c64aae0057d2052e1333c7e71075aed739de6838f03802a8','3bc5396ddea7546e85340cea71135139afe84b6fa657954ee847194112a20156','a14452df808257340a1cb9be222f7e71e162af6c62f2681ff5b0f087816bd081');
INSERT INTO blocks VALUES(310111,'fde71b9756d5ba0b6d8b230ee885af01f9c4461a55dbde8678279166a21b20ae',310111000,NULL,NULL,'31a0eef076aafda4f3c4085fd8416fb1835b84eee806ab08f66bbf34eb5c1ff5','3838600c146b930f84af830cc43843d5af5e89448cc10fa4c6c5d2aa90a57976','0e461b99418810528e5f1d19cbe06c97fc01c1264e83da12e2dd23b3193a70cb');
INSERT INTO blocks VALUES(310112,'5b06f69bfdde1083785cf68ebc2211b464839033c30a099d3227b490bf3ab251',310112000,NULL,NULL,'c90259a530010b8f10f76320964474b61588ad54d1bfa1ae16cb94505291cc37','f3985f5b8dbb6375781f2a1a704af9b15106e5595a3d034baa69b7196b91e75e','f5b3dc88342cb1757c2a838b140e46e1e164de3464337cd45edadf73fc1cb530');
INSERT INTO blocks VALUES(310113,'63914cf376d3076b697b9234810dfc084ed5a885d5cd188dd5462560da25d5e7',310113000,NULL,NULL,'17181d0f1fe3b0570671324665a2e111cc292bf2cd987d0e70dafcc338359c54','7fa05979acc03cc642049a006fb0a15808e66c35e0e7f9f10861f0c8cf230a20','198c5e193ec528143bdfa61f25e4d238a7bd6afc25a351452cfa303e57778f4b');
INSERT INTO blocks VALUES(310114,'24fc2dded4f811eff58b32cda85d90fb5773e81b9267e9a03c359bc730d82283',310114000,NULL,NULL,'b67067fa1d4e615db1dccad4292e50791a1aafecc062a6147d0c1755218b801e','6367666e81a0da6184418434f9a33bfdb4d769329cd59bb47a898af3ae73bdbb','e93dea3ad50dbea8a4e976bd662b94749df0fc4de7c3cdd433de8773072b309a');
INSERT INTO blocks VALUES(310115,'a632d67ff5f832fe9c3c675f855f08a4969c6d78c0211e71b2a24fe04be5656a',310115000,NULL,NULL,'558ba8b0cb8bcc40b9df17aba3f747f52d5367734bb1d94aa39b5361f8a6697d','3d098e9be87414d1cf40d517d333666e20b57d5d78bdfcbbfea8eb8a2e1e2fbc','56c1286a5ed43b139df8bc2d01d96a094e9aea168ffc631ea068ea4a216e77ff');
INSERT INTO blocks VALUES(310116,'8495ba36b331473c4f3529681a118a4cc4fa4d51cd9b8dccb1f13e5ef841dd84',310116000,NULL,NULL,'b23f0240f2d53cd0597f4fb6b1ebbfee5ee73470820ed2737f68cbeda80dc3a7','a9f659cf000721fb3139fd5f2aab1df44d9132986fed1d9ad8823fc75e2bffd8','43cebe2dafc478d630ea5d0df03a67acca6ea8ab5196de87a08137d8dc85ea30');
INSERT INTO blocks VALUES(310117,'978a3eac44917b82d009332797e2b6fe64c7ce313c0f15bfd9b7bb68e4f35a71',310117000,NULL,NULL,'c7601a4c0cbbd6da2eee3c70e039e32905ae6e1e191a8bb276fe3a916efb72e5','ea4ab10fb7ca354ec49474acbc8eb5c9db9f0292919cbb91ceb9751740cdf02c','83569392b56f5ea220d92153a01e58fc017bf8bc49b5694c4284f4719394d03e');
INSERT INTO blocks VALUES(310118,'02487d8bd4dadabd06a44fdeb67616e6830c3556ec10faad40a42416039f4723',310118000,NULL,NULL,'ad1309bfd4af39d24cd233cb5938d12636b3985dd1245bae46bb168b3d2c4819','af9bc648e43990a60819175f4fa92f533c3a5c865c1cbbfc2136d9fe9f772396','fd05ee29286f1b9c271ec157679a5cc602513c02392856049758630a0dd23a3e');
INSERT INTO blocks VALUES(310119,'6d6be3478c874c27f5d354c9375884089511b1aaaa3cc3421759d8e3aaeb5481',310119000,NULL,NULL,'828c183d6a1f63cd4558174e2f8ace847bc3547966f9b64be0e592c9a73f7d9b','8af67a5f2a78e042c4c01106b0568ec200545a4907fe6719c9fda10ee4d6c62a','91c8a458dbd18898e94e38bbb9b9c71852d1e3ea0208a42279c3288c14a17fa1');
INSERT INTO blocks VALUES(310120,'2bba7fd459ea76fe54d6d7faf437c31af8253438d5685e803c71484c53887deb',310120000,NULL,NULL,'72b5a7bf3eac316dee8269b8f3b2119da4985b51fbd7c0248de0fc2374dd253c','96ce8e6d3c2901f448d1a12efeb4c4b9a292345aedfd591dc7af54ae87dc5a23','6d68c70f96e37e600329c0395d3bae74427f59eb4ad793ad9809149b61684dfb');
INSERT INTO blocks VALUES(310121,'9b3ea991d6c2fe58906bdc75ba6a2095dcb7f00cfdd6108ac75c938f93c94ee7',310121000,NULL,NULL,'23143a81de5f5288f1b868f103efc57b4c6ca11a846dea8474a22d578ce7f27c','c8a352f208d90333ce4f7e1439bccfbc58060d456852bfb264fee470c4bca441','aedcaa0ae7aa9fccc815754f19e8f956550b8a3b9393c032f2e1a497255525e4');
INSERT INTO blocks VALUES(310122,'d31b927c46e8f9ba2ccfb02f11a72179e08474bdd1b60dd3dcfd2e91a9ea2932',310122000,NULL,NULL,'a0c14e0c9eb81800d71fcf7fc1b76dd1701002a189d4e8918786158d00097520','999018e7e147546f231ba2022dafc95117cb2a6d1d8156247e8760cea46778be','f8771287089bc4dfaee7078ed0743062cb1452e6c26fac7c56a878c2a85c6734');
INSERT INTO blocks VALUES(310123,'be6d35019a923fcef1125a27387d27237755c136f4926c5eddbf150402ea2bbd',310123000,NULL,NULL,'bbc4617672d00c09e648f3e2db715f00280497ac1e51f4f9981ff518cfa13952','76bcd9df3e79482e18210f2e2c7ac35377600e8cd17c5f0323eab38cc54c0780','0c8a0e3dabf7782f22cd7e82ad031c717f4fa82020a199445005f5f3236e91f5');
INSERT INTO blocks VALUES(310124,'0984b4a908f1a7dac9dcd94da1ee451e367cc6f3216ee8cdee15eae5d0700810',310124000,NULL,NULL,'f31c7801761d641372f7e8a8231fa5196cd1eb046c6df5f395a23a9b53c9e0d8','2ea7715e73830779a6d2ba8973a5e2a90858014399a6d6e5d361531cf74fce0f','4906f322e3a5ed4ba4a1cf01b259749912e779d378215f48f8d86f7d44e6dac6');
INSERT INTO blocks VALUES(310125,'cc28d39365904b2f91276d09fae040adb1bbbfd4d37d8c329fced276dc52c6a6',310125000,NULL,NULL,'92214632b0d871a4631ab8cf2ab235d2f621597c7e2df0ac0d5c300cf55ff13f','3bf12a585d163f79d713d39a296c411224ecf413f237193d53cb207ae528cd4b','fe6931ba2249a5a002e393b9b20e45427ce3b474f1c879a118efc928c745bc4a');
INSERT INTO blocks VALUES(310126,'c9d6c2bd3eeb87f3f1033a13de8255a56445341c920a6a0ee2fb030877106797',310126000,NULL,NULL,'eb45005da17fea0b8e40eead280d15b3e4ae2820f75ee989ac091a820319a0b1','b36a28dab6ec4fabec410048ed3b00c744ea61d8c4e3217716ad5a56d5cdcf8f','5fbbd25db00be776605d9052cfd41b1d785473696706c6698d66708b022449ba');
INSERT INTO blocks VALUES(310127,'c952f369e2b3317725b4b73ba1922b84af881bd59054be94406a5d9bbb106904',310127000,NULL,NULL,'bec794cfd3c3df48e75d7b434e5f1e9ae9a61838a26ba0aaca682242ec57cc08','fb7a19ba06050b9c60fe55f04ce94abc4fd3639c63d700976f914db125e59716','e9fe8415b74bb6f892d7d622f674952d8d62a974b182e2fbffa07f65ff7f6528');
INSERT INTO blocks VALUES(310128,'990b0d3575caf5909286b9701ece586338067fbd35357fec7d6a54c6a6120079',310128000,NULL,NULL,'29cc4086f7b801903e04e9164d68e2635dd7105ad22c12bfd8798082bbc12ca6','f1e32f8e1eae05d0505fc49162f9d4500ea0bc869a77514c278496eda24c422b','4f6409055b3b6daf86584fad0ed9ded45ca36e34cfccb7cd08d09f8357cf621f');
INSERT INTO blocks VALUES(310129,'fa8a7d674a9a3e4b40053cf3b819385a71831eec2f119a0f0640c6870ca1dddc',310129000,NULL,NULL,'39108dfb13330e237f32846d97dbd0ae5316be71279f6844a988156be5cf612b','b417796c79ecbe1f28f447a6267be896ad4a99d30dddafb1e8aefc1888be2f83','4f7b633b29cdff0fdc2e9e86d45a7229c5cb0bead53a63284012cecd2b9cab1b');
INSERT INTO blocks VALUES(310130,'d3046e8e8ab77a67bf0629a3bab0bea4975631d52099d2ddc9c9fa0860522721',310130000,NULL,NULL,'473618a86d2997055f0d1ae0511aa53562e2792bd106d98b88e44fd3c921b472','8c45ef6e406a7a63c4627dc095ea1380048df2d77e3e474e7c184b5931617bd8','9b6dfe603c68e7b963664db5675db0018397da4659af211049dd0e38d901d825');
INSERT INTO blocks VALUES(310131,'d6b4357496bc2c42b58a7d1260a3615bfdb86e2ce68cd20914ef3dd3c0cdd34d',310131000,NULL,NULL,'82d69cd65b178d450f12362b4ccb22e9ca7f55af13a773b97b68adc64f5eb67f','534b2e8176d23c21a808930c66c7380adc5ff8096e9d65ddba3495b596822144','4114c8f5e663d10684156b736ebd36c2a86d7463c8590adefdb675432b790ff9');
INSERT INTO blocks VALUES(310132,'1b95a691bf4abf92f0dde901e1152cc5bd87a792d4b42613655e4046a57ab818',310132000,NULL,NULL,'c5a46fd1d7e4c4691f25739582c38c4ea048d3280649efdb7bf13232600bae73','fcddefc8b8d5f3143d24a1aecd9a091dcd26c9817e713bbb9bccd16d4b464502','8a63fc32626197b506324186284d1a7e817744765464961518955fdbf988a24a');
INSERT INTO blocks VALUES(310133,'1029c14051faabf90641371a82f9e2352eaa3d6b1da66737fcf447568ca4ec51',310133000,NULL,NULL,'cb98331c582a00c7a0b0dd39f7cd2dd8e13544412f9cf02d8bce3a26aebdc082','742ace16b2a69de0ea7e9d3942439e96aa0a992930096d2fc983dc8ccd707542','9c4bb1f20aa6493fd3679bbeeef5e412ad684c8fce7d8c61d2dfaede577861c6');
INSERT INTO blocks VALUES(310134,'1748478069b32162affa59105257d81ef9d78aee27c626e7b24d11beb2831398',310134000,NULL,NULL,'77151a50cfe160e4ada0db15ee1f93942bea65ec3dc40014baae144505bf480a','467a802095dff7f5da7959fd3e9bdf81c271a213054d5df5c91edc954f9a3941','4d3ea20b4e676969dcfb742769cb0b41c03caec5782f68a78840192be5faf02c');
INSERT INTO blocks VALUES(310135,'d128d3469b1a5f8fb43e64b40f8a394945d1eb2f19ccbac2603f7044a4097e4f',310135000,NULL,NULL,'0a6f8cfcdcd8c031f9cca409e35df7b4c0e270d6da21ba5370735eaf05861ae2','5a5681af50503d371f37769105fdbaba6904a94875f8f428e429408c085dcf4e','96becc56326b45b6707f9fad3722f26bb4443c0f913c7c036b761ba9f4e3d6b7');
INSERT INTO blocks VALUES(310136,'6ec490aaffe2c222a9d6876a18d1c3d385c742ff4c12d1334613a54042a543a5',310136000,NULL,NULL,'ba9134ad59596bdf31b739d224553d266bf1162475eabab4281b0c0cf8f555fe','fc4428e576d554240af9190c42ca2aa7671ee818ced6b7b030a1113081704078','89123563bfa0b19b397020fdafb5c7bb0f47596e335eb4b3cd38cebe6d996ae4');
INSERT INTO blocks VALUES(310137,'7b44f07e233498303a57e5350f366b767809f1a3426d57b1b754dc16aba76900',310137000,NULL,NULL,'d33775f794381605ea6a544719ec87cc6ab33b67a2f86522ceefdadb50a2ce48','5cdddd60a2f15d7ce34c9b1093da368eb62dcc2919ee85609a9afff2670d2588','16ad82274ef1556a98ac6d59286edea4af95e61dc62fdfb7d7c83b2ed53d73fb');
INSERT INTO blocks VALUES(310138,'d2d658ccbf9baa89c32659e8b6c25b640af4b9b2f28f9d40baae840206402ab5',310138000,NULL,NULL,'0c7d27f8b6a3fffda184e486e28f3cc442ef813779527a1bda5cddf38db7e289','f296156b53dda95904f3487d2af3152925c17b3bd1b51189f2209bd9c451e148','68cc7b5a02606fdb5b407d4e5e78eb7a9ee6b74c58aebc9f08acdd994726e2c7');
INSERT INTO blocks VALUES(310139,'b2c6fb61f2ae0b9d75d18fce4c52a53b1d24772b1ad66c51ca51090210527d46',310139000,NULL,NULL,'b78473056f63b10882bc97ebb9640c4fc2c84607699be4240c6677c47c0b2aa5','869b3e272dc7ba38e6064a1afd86db72c7202f51310433ddca1b15bc05f0248a','d540b4413aa055e01a62c69c4a62ddb5370b2a1661551d47e51898a287681ac3');
INSERT INTO blocks VALUES(310140,'edddddea90e07a466298219fd7f5a88975f1213289f7c434ed47152af6b68ebb',310140000,NULL,NULL,'44a66d9ad302a859c4ae9b6647795e9b3dae40266577e8127506c13cc5f896e0','77e4ccee3b3e6f85433a235906b0952b8b527a806c866d70a2705de895b82114','ac4f0077ab12f31e7ab7fc10a2033f17c5657954b77ea2d45fccb7dbd8ac624c');
INSERT INTO blocks VALUES(310141,'b5b71d2a271bd638561c56f4ffbe94d6086debaaa86bfeb02ef0d71339310709',310141000,NULL,NULL,'e215dc1e0ed938e2c4fc1651c6eada3e935b3049b87ad2397e2c50c35f8ad580','e547817ff477a325880128761932be771bdac15980e8bcf360b8ec0312962b23','faf363107ace3d2e409eef707ef1727b7c0437d542f6c3775972cd1ae1b5a2dc');
INSERT INTO blocks VALUES(310142,'a98ae174c41ab8fc575d9c8d53d8e02d8e446b8c6c0d98a20ff234eba082b143',310142000,NULL,NULL,'f205d981e84819383c01b89e7785b93924609c6d2250a7505d1f7abaab1af18b','edeea9d44737ed61aacd0efb11fbb92d4122c5320d63215f46d82a81db202877','34839c0621efa2b3dc919370f95ebfc53b7423e8f6f8918abe46b18ab79cb60e');
INSERT INTO blocks VALUES(310143,'8ba2f7feb302a5f9ec3e8c7fc718b02379df4698f6387d00858005b8f01e062f',310143000,NULL,NULL,'9bcd807853f3b6e7a955e79027199b7ed8ae88783b420ce67b603e1729a746ca','5bfcdcc944c8e130c7b96e335995cbe19654fa7e1d65a7bbb70ae21274b9f854','43627ce27ade2e3a98b47ac4440351b1f2526402653d439ddce8705884410890');
INSERT INTO blocks VALUES(310144,'879ffa05ae6b24b236591c1f1537909179ed1245a27c5fdadd2218ab2193cdb9',310144000,NULL,NULL,'e659a7c4c87973aa291a233f2a01e7d6f87cc84d6d6b60aad44df4a499ecff3f','405723e108dbb10abebacdee0cb018208264bd2b493c2389619837f1983d1653','e26d55b4f11e707a876fd32be2fb4d6c147d459db8788b866645dc3591698ddf');
INSERT INTO blocks VALUES(310145,'175449ef0aa4580593ad4a7d0c5a9b117e1549ea772af00caa4ccdc9b1bf7a6e',310145000,NULL,NULL,'fe4dbe3741434f5a885c6584861d105464f7a0836920085dc7b4d6622bbf2d88','e333c18a993a1aef8f88a7e3dffc8ef9a3506e0bd0af40662a10e6a5e35670a7','db208e8d13f4ddd5bf9af0416064435485caa5b3a8b16faf475fa5f7a00eb23f');
INSERT INTO blocks VALUES(310146,'e954ab6a110455d745503f7cc8df9d92c1a800fafdd151e7b1912830a9cb7184',310146000,NULL,NULL,'4083570250f78aeff4528cd3f74bd1353b1dc301c3aedc27de9c2b85e171e7ea','7165be93bb9d5310e163759fa18e1936249f4454c59fe5bab140dd3b1910092c','c54045a5406c2b5d2d9dc6450e879ba0e6396ab5a6585223a1551ef13605fa08');
INSERT INTO blocks VALUES(310147,'7650c95eba7bf1cad81575ed12f32a8cc36281a6f41bef13afe1dfc1b03a7e83',310147000,NULL,NULL,'4e557b266a40b72a029b586fc8f3b0ca3483d29ee9437b23a5cef883dca7773e','ee8322a137f7d646520e3cbe3cb719d1f855225acf4360ae1c175dfc1441534a','7d1d82b4231cec9c60002d86b04887ccea3e46710c94fab5e39596952fa1f3cd');
INSERT INTO blocks VALUES(310148,'77c29785877724be924f965215eb50ffe916e3b6b3a2beaea3e3ae4796545a7e',310148000,NULL,NULL,'f20f3abcf224f97bb4a0fb5fc483e3ad1f9cfc8be0c9da43abfd2daf35df0632','4b43ef3472b59eddcc8f56a7e05bd503a99fc3684fc41d8d2fe38b1c77a172f7','2db99ceca8a83fd59b4493e05f34734dc05c14f012f392ea7a82b51053215f38');
INSERT INTO blocks VALUES(310149,'526b3c4a74c2663fc04ed5234c86974bffddb7235c8736d76860778c30207b3c',310149000,NULL,NULL,'1a46ca91bfdfd178748ba03e300faa0711d1545866dd5059bbd96b6909254257','35c3331bf13d9a3c0c3dc358d86446b4582a128759bb405dc87ebadc98435ede','d95b1c5fa327896a8f1e6ba0719be277bf59cc4dbe853a5df07c00808718f996');
INSERT INTO blocks VALUES(310150,'cdd141f7463967dbeb78bf69dc1cd8e12489f58c4ea0a5dc9c5c01ec4fcea333',310150000,NULL,NULL,'3c2bb960dc83bb47dd0ae69a0cca915d075e75b18a5ea836d027bb46e4890639','73804855054ee5c7ceb623f785de93ec288137cbf3afeaad7353085071533ad5','34683fdaab49251e787c08387a31a4a45067738d63bc2bd4ecd17a5219a177c5');
INSERT INTO blocks VALUES(310151,'a0f31cc6e12ec86e65e999e806ab3bfa18f4f1084e4aeb4fbd699b4fe284b330',310151000,NULL,NULL,'efd8b1a509ac8f9a37ba96e73dccb882c36a5574f6944abdd71b2c946ac4d1df','57262e8326c4816e93b3061398455b988a263bbbc80e74490cc3093fd2c7eb8c','82aa821786fadb1387fb9a7a67439841a31ba20cb8649957795e1e29db895ae3');
INSERT INTO blocks VALUES(310152,'89c8cc3a0938c63a35e89d039aa84318a0fc4e13afac6beb849ac37140132c67',310152000,NULL,NULL,'ba36d83a505ae912392635989e8cd7a823d67ec935c93b5de5205efb91ba770a','c8ef9c04f4b2bb984a34deced1e2e33257a4f90b20251a37011cb62f8eb22614','0c118a1302736ebb668a7a52fd42832ce2969e9467f8bc9718444e31fd48754c');
INSERT INTO blocks VALUES(310153,'d1121dfa68f4a1de4f97c123d2d2a41a102971a44b34927a78cd539ad8dca482',310153000,NULL,NULL,'53172c579f587686b596c1d5221af2d4fe6182a4e383956575c131a2ff8e047d','deedb63e75a000f6ee8d9ef273db8269d561b2341652f27f8cd5b49e0b652a4d','11d40a2924c5dab877b4b8ac6a9179ba50e7798bce0f010b6e1329bf62a40f6d');
INSERT INTO blocks VALUES(310154,'ba982ea2e99d3bc5f574897c85485f89430ae38cf4ab49b7716ed466afa506d6',310154000,NULL,NULL,'32e44d5c7aa461f1772be7992071f008822d74ac9bf2aa1ae372e9ecc90ca4cd','04666cbbfde58c137efef45eef27fd194287a541823b19169403ee44b33b47ce','9616340ab540f1a97273d24062d63dff6b41eeb16142427fce10d108d9af877e');
INSERT INTO blocks VALUES(310155,'cefb3b87c7b75a0eb8f062a0cde8e1073774ae035d176e9769fc87071c12d137',310155000,NULL,NULL,'9e5b38f739d03395b509dd151b459e11b8abe9aaf8de94a6dd30dd7240773ab0','7f06484d46029bd774c5ae39ebbfb503d11ced3c9d5398f20d904171f9b40866','4b6b1b8ddc5fa45aa2fdc5d47185805c3411a3fba861d2ca9137056df303fd8e');
INSERT INTO blocks VALUES(310156,'6e3811e65cb02434f9fde0445a7a2b03fe796041458737d0afcc52208f988a83',310156000,NULL,NULL,'22c8ba641ca4d31b68279720911449fcedc6d7e2d09ec1b1cd50e0ad2be93ddf','2239513eedcd9d1b61bd6b4984999cbc5af5d92cbfed761fd92da6d81bd08d32','7b23d03d0f9fce9fe5a8fc1dc3db3adb8343f83d0072e7f011c9821113ad8fb8');
INSERT INTO blocks VALUES(310157,'51dd192502fe797c55287b04c403cc63c087020a01c974a565dd4038db82f94a',310157000,NULL,NULL,'39504b3d7e0c11ec49a89f5e1f9f52a821bd6ebf7126d293f20fd8d168e50100','2f486b216b395779400aad5a6ef0442286232659bd28dc264ab57413cba31eb6','4ea5151f3059c2f2bd5706568112e798a55eba39c0a4e4dbdfbaa1fc61e3e749');
INSERT INTO blocks VALUES(310158,'749395af0c3221b8652d31b4c4410c19b10404d941c7e78d765b865f853559d2',310158000,NULL,NULL,'192109b7cc52402c0ff9e8922fce650378590c98c5bfff2c7a7fa3f706bc1a3d','6c8d7118e685ad5cab440cc806bd15492dfbd16ac1c3a32691ba649ce19aadf9','16a5ea4566b3fbe828adc6fdc6e558bedd0b8af16088d3c998978f80bfbb156e');
INSERT INTO blocks VALUES(310159,'fc0e9f7b6ae99080bc41625588cef73b59c8a9f7a21d7f9f1bf96192ba631c12',310159000,NULL,NULL,'accc7b0ef66745f51b87a0a9b6ede3692ef196008e582e2c504d0e8fd15bd73b','da7b96909cc52149cb2a0bb60a43b316e7551aebb75c0d59753354f33ae48ef8','13b7d513cffdc6ff1808689142cecbb28b40a5901d7e3aa3e8cbd11f208e586d');
INSERT INTO blocks VALUES(310160,'163a82beeba44b4cb83a31764047880455a94a03e859dc050da782ed89c5fa8b',310160000,NULL,NULL,'cdd98b6b18e7886eb478771ff58278e695d1791597110563d7de16c98142ec3d','06697e247242654b98917d38334dfbf6946d6d2792babc8a498a2357b9420582','57418cfb683ed5b673706059b2923df67e7e474821eddc1a533437ca78dd6115');
INSERT INTO blocks VALUES(310161,'609c983d412a23c693e666abdea3f672e256674bf9ee55df89b5d9777c9264d8',310161000,NULL,NULL,'fb42d97cfc317712b7bb95e0d96158e1b50e25e3a164d643f6a849353af1e6a9','80dc2ab4632ca1084b4bb9d0781183eb82a02e7878414e09535fa4b49d09352f','09153f9a58f6cd2fa8ec19c4d4276a188a466c3e2d38b46f714b04fa186a920e');
INSERT INTO blocks VALUES(310162,'043e9645e019f0b6a019d54c5fef5eebee8ce2da1273a21283c517da126fc804',310162000,NULL,NULL,'5ddd001a739b02324808238e5e63712e889bc0ccd43f329199662de558603109','22f5a77cd7a56bae37097dc4fcb21aea00e3996ff7f92e77a2c7357810a10440','bd8554db98106398dcd0f51dd3899306f14f49884412c494c5df373685e7f5e8');
INSERT INTO blocks VALUES(310163,'959e0a858a81922d2edf84d1fbb49d7c7e897a8f49f70bd5b066744b77836353',310163000,NULL,NULL,'86aa15eed28f5fd228c71329bced64b4ef2cd48ee9a47adcb807038320ebb202','5178074462210a313d2a5ad2ac4fdf1386d6839db26e56933a9e08e8f9032eef','f5a315259844deef9d087b493cd589b05f6386988c1a115480d37ac630ee4601');
INSERT INTO blocks VALUES(310164,'781b7188be61c98d864d75954cf412b2a181364cc1046de45266ccc8cdb730e2',310164000,NULL,NULL,'83d970051ddf7bfa39d100ff42bcaa7cc354740b8ef53872d18b5a705535a18d','83414cb0889ddf1f38f2286d41312d304e82755f90b26400084cee228f156dcd','4ad051e58415b02cabe8f14a0ac4520989dd5f086a68a7a8e6a0576bac2b4c33');
INSERT INTO blocks VALUES(310165,'a75081e4143fa95d4aa29618fea17fc3fabd85e84059cc45c96a73473fc32599',310165000,NULL,NULL,'9e497bb923d962891885a2d3a9c2eb0d074ca26ff45bd9af4bbc60926e0f924b','78ab03b3eba596ae00585fbffee7eadabe2b4cd7bea220f2a5c60eea39b19518','262cfdf5b9ddc0d9543847f397805daa2ae23349338c9dcaf7c87c52b108ae2a');
INSERT INTO blocks VALUES(310166,'a440d426adaa83fa9bb7e3d4a04b4fa06e896fc2813f5966941f1ad1f28cfb41',310166000,NULL,NULL,'0417eafc1c3bfdf9f54ebca6444e960dcd1fc126204d593dd1d08de23055d0e2','80a0a76697b041bc98074d0599465a1d150115682e20b3473673b8e5dc36c8fb','bf805598e1bb76215ab8691916d26caa43c4ecbaef4ec5747408c524db9e0d70');
INSERT INTO blocks VALUES(310167,'ab4293dbea81fedacca1a0d5230fe85a230afc9490d895aa6963acc216125f66',310167000,NULL,NULL,'c733abd319b6b9a59c23f3f24ba35e9fbe669b84c5550024c2c875bb5e185f72','d706247dd7f9fe077f6f71f1f96e07ff1814372418a71141610e5a00696dd08f','51e3ae3ea0eacbb1bf2ef16bd4a45e89fffb860b5f2106b08bc2f4c5b0709672');
INSERT INTO blocks VALUES(310168,'a12b36a88c2b0ed41f1419a29cc118fae4ecd2f70003de77848bf4a9b2b72dc9',310168000,NULL,NULL,'7a5567209465058f1ce41d25858e66d47e81398a3b924b302e254e0f328687f2','061cc683b0b12a4256c51afcb11e5760085a98860c4494ff0e1a60f7c8f22793','99f773e59f5bfaf805fb68edf9e793d4817bba3546e5f3f753c3f7758bef8851');
INSERT INTO blocks VALUES(310169,'204809a85ead8ba63f981fc1db8ae95afe92015f003eaebbec166021867421f3',310169000,NULL,NULL,'c446a7c7fa2b54cbb79ab56105a3d5f640fa86e1770e9baa0a21d3bc98e4a3ed','7d10a20faa7b2f0dd7d587961274aff9698eea97169a9413db532101b68cb163','98be90606cce43f5f37aabfee4949ff526785fe6c33f2683aba84b67de62b1d8');
INSERT INTO blocks VALUES(310170,'b38b0345a20a367dfe854e455e5752f63ac2d9be8de33eab264a29e87f94d119',310170000,NULL,NULL,'0b9355e7739d154013b649e12ca64c9767da377a9becea4cbfd92ade6769b0d0','cc1238c570a98292cd90251b8b0ebe055c289df977e4127e502c985830e4e05b','bfa3d235478c17bbd01120b6d1ead8c0dce49bae315ef622dca39c476e561dff');
INSERT INTO blocks VALUES(310171,'b8ba5ae8d97900ce37dd451e8c6d8b3a0e2664bb1c103bf697355bf3b1de2d2d',310171000,NULL,NULL,'0a28f6dc64798458009b1eeb4f234a8c8d982ca6107bf47e1992c31aeec8fda0','12e6a861ee477ea85658f3c652f63e552a35b9aa173aa2027a3fadc2dc80b207','1c68c50b213edc9004415481f6f2e308eb4f7a65d238187460e41f8580c9a460');
INSERT INTO blocks VALUES(310172,'b17fda199c609ab4cc2d85194dd53fa51ba960212f3964a9d2fe2cfe0bb57055',310172000,NULL,NULL,'d6c6ffee6656e63d3356bac4218955f81b4c34251d555e858f5bb194083be174','2c11113a0b4fa042631c066e52f217e4a6b92d1b8b0f8fc41e49c3d2ce7f7417','4ff64ceab7153b2e48ea1b8395941c35079dd832458c56d489177271aeac3fc7');
INSERT INTO blocks VALUES(310173,'f2dcdc5ffc0aca2e71e6e0466391b388870229398a1f3c57dec646b806a65016',310173000,NULL,NULL,'da74cea1a93deadf69f4bcafac16273fc94c55d1b11939d932c726d928c89895','03985cd608b58a89c692f39112898ab5804494d2af03a87bd40d4f01d3070d88','a4c8fa8d350bd5dbe26ecfb0c366d0cf4ceec4cd063545cc1eb927165021cee8');
INSERT INTO blocks VALUES(310174,'fa6f46af9e3664353a473f6fffce56fa295e07985018bface8141b4bf7924679',310174000,NULL,NULL,'6d6a98445845420cc7e4bcb60d2a0bad393090137bd2b648dca6f4565de16fab','9c778beedc829868abbcd4ca2fe146509643262d3c09e740dc50c486e4bece3d','d21e12779bda5d3ae370ee3c870f9891efec915823963438ce2c5bd7d4ca9327');
INSERT INTO blocks VALUES(310175,'f71e79fe5f03c3bc7f1360febc5d8f79fc2768ce0ff1872cf27a829b49017333',310175000,NULL,NULL,'8d86b8abfea247af0c407527a09c92fd0aeb9878edd5c53893237171afcd8990','ea560dc13a8d62933e67519589080122ee3aafee95c4328d4e025dbe0373730e','70290cc985ec6a2b3797df3edbf0c95d2a0f148bbf3368a9ea082bd7d4f35490');
INSERT INTO blocks VALUES(310176,'67cd1d81f2998f615602346065e37f9ceb8916abb74b5762ead317d5e26453c6',310176000,NULL,NULL,'1b23f99b5f15355c9db60ae33b41908cc5e5c51ef4f1e85fc2cdfe6744b05b2b','e0b5171406711359bf62cc189e0ac27d7b928bb40086980136007fb177992a9a','3df37e27550303617b465f76d08dbb95ac16cae99e498f5cb1df15fed91ade76');
INSERT INTO blocks VALUES(310177,'6856b1971121b91c907aaf7aed286648a6074f0bd1f66bd55da2b03116192a52',310177000,NULL,NULL,'9804730abfb72f4394aec4aa6df5e1b23e6d49a5d225bb956aeb605fb9145e70','ee0c8842fd3fdcbf316c268de8fa06536a2f0b21b769043817d682c83fbe9e56','c10f12ada556ba544882a02d1857018ad48e62b82c87f6c3d833040ef59f1b2f');
INSERT INTO blocks VALUES(310178,'8094fdc6e549c4fab18c62e4a9be5583990c4167721a7e72f46eaf1e4e04d816',310178000,NULL,NULL,'a32c031d3ea315152b5e44e75b01bf4715041eb2aef8b1285896ce95dbc64829','f02cdb3916ce309e32e6a69a3639d78d834631ed4565a68721191c266fb96d67','c321f10e4fd5590f7a0161ac9460ffdfbdfe43e0bc6531a3058734985386955d');
INSERT INTO blocks VALUES(310179,'d1528027cd25a1530cdc32c4eaff3751a851c947ddc748d99a7d3026a5e581a7',310179000,NULL,NULL,'a29114cd598b3ce52ad8abc047e1fda6deb925f3c382a3d295f8e4f9d848236a','49cb5c22281781951ac7d8ff3632ffbc70ae7e6031ade3e99af1cba44a2590e0','6cc56d25026a7bae1f61670f7629538b858486f17ba2f2e8bc9c726d743bb471');
INSERT INTO blocks VALUES(310180,'f2f401a5e3141a8387aaf9799e8fef92eb0fc68370dae1e27622893406d685c1',310180000,NULL,NULL,'d6d50f328fbfa7b7b66897805d013b0e5be3611c76c27986a1bcbaf6ab766926','e9e4d52d1611be8a551527088899bce0eaeb034a30af39812ff8926db60ca8b0','05da91aea7d8cc39d813d05fbe9bfac84c7080831512965137b076cdb4fd357b');
INSERT INTO blocks VALUES(310181,'bd59318cdba0e511487d1e4e093b146b0f362c875d35ab5251592b3d9fed7145',310181000,NULL,NULL,'ec174f40596ae4c6427a52d73858fb37713cab2028601ae5e866b1ea5b5e81ba','607748aa1bac2b717f68360e3a1c47f6fa4bed1585230c3775d1525104421c50','bff83cf8d692bf92d0d6cf0840d39270e35a8308f08c0eb1857aa2ed958a7ef4');
INSERT INTO blocks VALUES(310182,'a7e66b4671a11af2743889a10b19d4af09ec873e2b8eb36949d710d22e1d768f',310182000,NULL,NULL,'bdc51b3e849e30b9fa5f231914b4596702ffe2f16b39eb27635a8c7632a90e3c','9889fbb0f98cebf0b7ed9594c35711ee992641591043eca2daffbd65406a3e87','802a2e2067524a95f4c293cac7a5b21e12ca8569016324495794f488762f0fba');
INSERT INTO blocks VALUES(310183,'85318afb50dc77cf9edfef4d6192f7203415e93be43f19b15ca53e170b0477bb',310183000,NULL,NULL,'d5d1d220693a3c64cae5a4ceb9f2ba9e8224c20aefe78dba64cd2acf3ca345ac','b75e2455282f27935f000febe53bc0347770c06b22263008beef26c7a858156c','18a12d6ddfd55c61719ec3f3d05960d01086bf16f428e3a52f2ca4ab1c9d4259');
INSERT INTO blocks VALUES(310184,'042a898e29c2ebf0fdbb4156d29d9ba1a5935e7ed707928cb21824c76dd53bfc',310184000,NULL,NULL,'14b5ce9986d4a36197a5600628620799bc8673f5f976726688dbf6f18582c0df','4f81cc9906f9e719cdff7f427de31ffda7b6597c296062c0902a9e86a313a291','3dfe7a81e0e78de63cac492c43710642f8d965a4cfa719ae8f45580c29b54d59');
INSERT INTO blocks VALUES(310185,'bd78c092ae353c78798482830c007aac1be07e9bc8e52855f620a3d48f46811f',310185000,NULL,NULL,'b67ff58fe11d6309f60c1da47ccd1e369923c3e41e155971a9e0966082913090','3302b30ad20c8ed2f6cacda658f71d1c5051f750afbc53b2801fd322f58ae8c3','629f537cb4d21d463d8ea33f890ec8722ce151b64b4253c013baf78c83fa83f1');
INSERT INTO blocks VALUES(310186,'e30a3a92cc2e5ad0133e5cee1f789a1a28bea620974f9ab8fa663da53e5bf707',310186000,NULL,NULL,'abfb0e2a727db89976f17b1a3f63f230cb09ccd1cb07dd7f50fcdc7b35c289ed','efad66198233d749095d1f57020eb3371a3ca12e2addce95023c20b1ebe05124','fea50f3af85b254d353910f0ad5914830dbf6066bfab360ebef2eebd78f40204');
INSERT INTO blocks VALUES(310187,'fc6402c86b66b6e953d23ed33d149faa0988fa90aa9f7434e2863e33da2f3414',310187000,NULL,NULL,'e03d876d5a90f41a1255fa8e14e26e92e364c2d89c85ccc9bf9f0adec885b3b8','7e6c50a6e490b8d07beed92aa9c891af759faacb5dfa066bef38cf3da13862c4','f98834f9eaee1ce5228077bb279af7f4fd6e2657b651d8f59a2fd3976d49b3dc');
INSERT INTO blocks VALUES(310188,'85694a80e534a53d921b5d2c6b789b747aa73bf5556b91eeed2df148e2ada917',310188000,NULL,NULL,'0ea0b133e0427d12b211d90ef179ed1689abea4fe4ae18f0fef63b5caade6c89','b586ee8273fdcb50e45e162ff02b177e6a9988403c38eeaedefcc7465dc9a141','34feed368d22a2d2a516e6929e434e24ee62a023cd40a3f00220021c2d0ab2ac');
INSERT INTO blocks VALUES(310189,'7c036dadf19348348edbe0abe84861f03370415ed2fec991b9374dbb0ca19a06',310189000,NULL,NULL,'febec5d41d19208c0ff8c8bb39bb27d08f8254b19f8e2152cd9aedc3ef65f017','e0802e881417159a27c76a9927b42427240e5665479619f01f931e70813c4ace','43a4c8f69cc51eee56c04b024dfc5ed3cf2aaa354f9e6fa397bf0cf33d7abbf0');
INSERT INTO blocks VALUES(310190,'d6ef65299fb9dfc165284015ff2b23804ffef0b5c8baf6e5fa631211a2edbd8d',310190000,NULL,NULL,'ced69644dd310e50e6c178a63d3d9d303e519070c1f13e13f6da7db9f30bc750','4bae66bfc33fc2604ec7a5247db9b6316f0d7bd6ea17ff63d6797014feef8fc3','6c696136385ee73295c0cdbb8b281e2e672dcc938a776e58af04b9be5aed4f50');
INSERT INTO blocks VALUES(310191,'5987ffecb8d4a70887a7ce2b7acb9a326f176cca3ccf270f6040219590329139',310191000,NULL,NULL,'2da2e607453c9660fa5921ddda5869bff1e28aed9019c79e34f7f1573d5198f6','30779642e52529e3c7c56de43f26764f832cd75d00718326c0ea8f56f800ab8e','e8b019535b4aac8c5a1dc81f8a533ee888b7b6a43390a0419492d572be3aa483');
INSERT INTO blocks VALUES(310192,'31b7be43784f8cc2ce7bc982d29a48ff93ef95ba18f82380881c901c50cd0caa',310192000,NULL,NULL,'1796ee28da99a66e1d726cf04baf1b6ac3d9ea1b250915a9225cc61c23fbf537','48083131788e023cf2ec8ef305b74baad7dd5884510129f8f0c5964bdb0f628d','947a9f78df9a64d000c15e64b8bd454a27b3c3792233c46671a99a16a7c03831');
INSERT INTO blocks VALUES(310193,'ff3bb9c107f3a6e138440dee2d60c65e342dfbf216e1872c7cdb45f2a4d8852a',310193000,NULL,NULL,'89559dd6710738956e297e83d3494e44096120054cb04968172f83a41cdba8e3','eb3aa7e1fa3eeffdea424dd19e4af4e018943549cf9b196d1ad605bf1ea66669','63cb4cdea66bbe360a2afaa4d38bd99b0243fa7ddf6537911722f4c52bd63c89');
INSERT INTO blocks VALUES(310194,'d1d8f8c242a06005f59d3c4f85983f1fa5d5edcc65eb48e7b75ed7165558434a',310194000,NULL,NULL,'2197b5f7e6298bf96dc693b7ffe1c01bc744fda913e0431149bc8663a9c61e29','a971aa25196c7aa570963eb1f4135a3d1a875e2d51ba5248b849199639a5e120','9c6ed8241960147dd9f37438a15add267f1a9f50dcbde04a7b4d1348241c7f78');
INSERT INTO blocks VALUES(310195,'0b2f1f57c9a7546faac835cbe43243473fa6533b6e4d8bf8d13b8e3c710faf53',310195000,NULL,NULL,'5fc1ac149360e81065aca4bbf8a63e56a476656577b92736fc40a37895000445','1c7aa7797911f5aa3460ba41196713c8de55bb3801476bb875348d121bb1c4aa','c4144861c2d04e9eee1fdeb36b8f53389d4dd41ea31bc9a71d8d68cd11fd8fb3');
INSERT INTO blocks VALUES(310196,'280e7f4c9d1457e116b27f6fc2b806d3787002fe285826e468e07f4a0e3bd2e6',310196000,NULL,NULL,'8b9e74132dd1d4e710e4316113b1b4ab8528000cee59129f74e24bc2ab552899','d27379f618cce7d0db52522f7a72dae92caa553178a95a5fdb044533024980bc','fd59e851de83e244219a56d332cebb1cd816de95fed475608aeb989de24ff786');
INSERT INTO blocks VALUES(310197,'68de4c7fd020395a407ef59ea267412bbd2f19b0a654f09c0dafbc7c9ada4467',310197000,NULL,NULL,'09a3180bb504b3762a0cb0e65522c0a7e88bbf904552dde42f5704701aa87b17','8a071a72145c26ae2decb0eabcb3fa1f4efc196461608c2a631370ba8ea25167','1efbd6eec71267ac382127d23835d0ac2cb27382cd6c33494c5ef595bde7d949');
INSERT INTO blocks VALUES(310198,'30340d4b655879e82543773117d72017a546630ceac29f591d514f37dd5b1cc2',310198000,NULL,NULL,'11b05da2ca99b55d8903bd675af2e2ac20768a53b0822e624992e50f2471ebfd','40df6952a74eb06fd99a15a75aff86f266213a341d2f01c03e665c7e2c69b6f4','83a3f1960c71aaa6db05a730e6db0545c0e018782fbd9f380b1a57f338e331d7');
INSERT INTO blocks VALUES(310199,'494ebe4ce57d53dc0f51e1281f7e335c7315a6a064e982c3852b7179052a4613',310199000,NULL,NULL,'80c7de343998aae2b87016587cf27032803a6465fb816bc8aa915245d412c8b6','9cc10f74240b55e0014a063fb7ea2228ba517cdc33fe0bed2f61a8dd2b593ce3','341161b369524f89a670da66fa384ff7ff61b93bd22cc1b8de9203a126820162');
INSERT INTO blocks VALUES(310200,'d5169d7b23c44e02a5322e91039ccc7959b558608cf164328cd63dbaf9c81a03',310200000,NULL,NULL,'c45b641082b320c65f10e283a55da4eae6e6fed99c2bcbec4d6e5a560f727b26','1794e3bd5e8fb6e188e8965ab51f4072aea422e78f4ef20c195d7993b4bd89f5','3284d6f0177ed8b5b525375633449adc56a2cb08f0e75b27c9961ab4c0e9ed0e');
INSERT INTO blocks VALUES(310201,'8842bf23ded504bb28765128c0097e1de47d135f01c5cf47680b3bcf5720ad95',310201000,NULL,NULL,'247b389a08e28869b4a4e5e03eddd14db90913a9b1a8fa1bc9854d61d5b1128e','19c4571b93e78bf2a612d1410195e13c90606cc16e9d6ce4fd5a94af7d4b0492','b87abd1c6d9db6147030546ac6bc25fd189cc31dcf66f9a11959407f9f942753');
INSERT INTO blocks VALUES(310202,'95fa18eecbc0905377a70b3ccd48636528d5131ccfa0126ed4639bc60d0003d8',310202000,NULL,NULL,'da07891f68861cbde2f3b5b1c05ddc459c1e255c383205b7a2b18c1ce9778ff0','e7c4f067718f2d3a9a0446962527ef329efe911de261dfccf792100e95d63c0f','8d5513945cb2d68d80ca105f413b63e1a68aa2287d95e7182f2cb650939d3195');
INSERT INTO blocks VALUES(310203,'ab15c43e5ac0b9d4bd7da5a14b8030b55b83d5d1855d9174364adbebf42432f8',310203000,NULL,NULL,'17d09cd5d38668cfb960b0786c4784ad0929ba7b127721f470a9fd215c28da52','0cd5c8dcf1515931d97592f74f119356da7ec9e081dbacd78ceb98767efb0581','cbc09e4c6a11f90c447b4fc4ae75d2632ffb0b1c3e64192577d1fb71e891752b');
INSERT INTO blocks VALUES(310204,'18996fb47d68e7f4ae140dc1eb80df3e5aba513a344a949fd7c3b4f7cd4d64cb',310204000,NULL,NULL,'68ca95a7903b1818b6685c8ddb548462e942b8f3416bac3d2649fc3c0eaede9c','b95717267aa3645f4f8c392fa425db3a4e16d12b87c9dbbb184fa12288ceaeb2','0b4e85176fdf3a3462cb459fa06648d50c628a02b594beacab5d4c66da1f96b7');
INSERT INTO blocks VALUES(310205,'5363526ff34a35e018d1a18544ad865352a9abf4c801c50aa55742e71630c13a',310205000,NULL,NULL,'591b834d7cbb61a730655e09e0eaa5d8c82d378c07f996cdb5f43465e34daa42','74f27ea5b863dc565622b0eba6aa005dfa7301a6533b8d30b456a291ec0dc300','60b1a1faadcdf751506ba27309c8263fcbe2d10f6ebcc2ea9f05e5d0340b7816');
INSERT INTO blocks VALUES(310206,'0615d9fca5bdf694dca2b255fb9e9256f316aa6b8a9fc700aa63e769189b0518',310206000,NULL,NULL,'09b9424b3b948f120b8f1845c68f721f0a7db089ba79b316f9724a904abd8017','f09a1c41a3dd0fd70db7d67a573d708612265ec0becd5df24c0d782c6b30fb6b','5cab4c00c8515579522a6bdc034494c4056ba0ce54629e4e5d170876e3e3901e');
INSERT INTO blocks VALUES(310207,'533b4ece95c58d080f958b3982cbd4d964e95f789d0beffe4dd3c67c50f62585',310207000,NULL,NULL,'a8a3ce202e9b966c61dd5283b1fad484b25b59077f274646d53964fb05b99445','1456a6ee41bdc65530d0d4a2cc96f46b692fbaae5042f45c8e59b9ccf48b136c','5659d608d9131f1f612b5fa115bbf95840c14fb07cdae8ae349824ffe7c61b6d');
INSERT INTO blocks VALUES(310208,'26c1535b00852aec245bac47ad0167b3fa76f6e661fc96534b1c5e7fdc752f44',310208000,NULL,NULL,'7265c87968a88a489545ca0372fd16ddc9a545a185bdada3a2abfa41d76530b9','8ba4ff67365b2d96d70ecd192909d4623eb3d9087ee6a400b0f5ba60a4df2e76','57fae4769b254058052684eebcaf03d19ee09c46045596ca1917b39a9a83f00b');
INSERT INTO blocks VALUES(310209,'23827b94762c64225d218fa3070a3ea1efce392e3a47a1663d894b8ff8a429bf',310209000,NULL,NULL,'040fcd7d0e3fd9ebecff8b8a68e135f35b1b3be59ee304c3c2014ffbadd5aba4','6fce4e36c762f6d786618e4f79de5d27a4901bb5b9d2ec39875682d3c32cbaf4','e227f73724cc770cd0ce28a1c30f976a1a9bbb81b6544e40e54102f62f2e1144');
INSERT INTO blocks VALUES(310210,'70b24078df58ecc8f7370b73229d39e52bbadcf539814deccb98948ebd86ccc0',310210000,NULL,NULL,'4c3a88fe80d56be6599d353afda19537c8dea58f83bd71fc6c231c472cba6e44','e7200dd8121c4fdd899cc069ac26c6b1ed18d132e7263daa81b056dcd909d594','fbdca1cf438f08f520ad05b326591da645b20b6b3528b91dc965d2c5d3ecae61');
INSERT INTO blocks VALUES(310211,'4acb44225e022e23c7fdea483db5b1f2e04069431a29c682604fe97d270c926d',310211000,NULL,NULL,'a7deb783d45d6ece0781805487ff28934dffd2031573add06f89010c8fa79fc4','2c5e297de8107d97a9cc51d7ce4eaaa51105623e6c1de4fd8a06c85d57d3983c','8367b478b3792f05d071efa128db5303c4fd3193b0ac233e5f0159554eda20f5');
INSERT INTO blocks VALUES(310212,'6ef5229ec6ea926e99bf4467b0ed49d444eedb652cc792d2b8968b1e9f3b0547',310212000,NULL,NULL,'9368b8e180a0a64869ad5a9d7480293a0061def86835ca46258a8f2af354301b','38b41f41e4e0e36ea456f89cbee93bfdff3916b65ed826261b92dacf640c052d','afea3862d47f9328c437d45bb91ca316db09f665f575719a65ade9f611161790');
INSERT INTO blocks VALUES(310213,'17673a8aeff01a8cdc80528df2bd87cdd4a748fcb36d44f3a6d221a6cbddcbe7',310213000,NULL,NULL,'9433ea14d9a483d99d9f10a6728cb7f0b75d3198d5a1c474e6402cef756870d6','01d06df671b0b88536a7494459e3748db9ec2697ace25d925c6e6895272f6700','5b4fdfd00fe243012613047d0f4e479b4ef4194059bf3788afa455ed61f9ff88');
INSERT INTO blocks VALUES(310214,'4393b639990f6f7cd47b56da62c3470dcbb31ef37094b76f53829fc12d313454',310214000,NULL,NULL,'7d0345c68b071ebc66d31764e3c1d95b3cdf672d1613e5abb7ee76fa015f2229','d1eff34b2b601f307dc2c05b0e00e6ed9d352231a990f376dc9b94f503a5234e','0e007f7d03195da0bbf0b181e4aa2ad3d1067408b46e105b5afe1b40b544c818');
INSERT INTO blocks VALUES(310215,'c26253deaf7e8df5d62b158ea4290fc9e92a4a689dadc36915650679743a74c7',310215000,NULL,NULL,'99b993d90ae507896b6737ccfab8c6b10bc084e839e8d2d40c400e7ad94aef8f','2693cc8ef53c0ace85e073fba9bd1a495294d909d6fa3556f1865984445f5492','00013ecdd15a7860ef99b5a018a81150da2430777be1ad0dc2ab51eb6b15a9ed');
INSERT INTO blocks VALUES(310216,'6b77673d16911635a36fe55575d26d58cda818916ef008415fa58076eb15b524',310216000,NULL,NULL,'eff5a08a9e0180ce9e46a91f6c146537af5c5dd3f27c2cd2cc195fbf20714410','ef072d9c5c501cd2a21f2a0cf35fa659faea42ba7a9875580ecf116432036fe5','7fd615ac127bdb26729ee305cf86f2645e071e98ca9091dea35d08c32979c4b5');
INSERT INTO blocks VALUES(310217,'0e09244f49225d1115a2a0382365b5728adbf04f997067ea17df89e84f9c13a8',310217000,NULL,NULL,'6669a33b1f46637b716505fafe69a750d01c1a0a76507f405b1867ff514d06f7','dd39ccff337d0ea830ee9b3b9c0efe38d734263383f6284a2ea5b5b72e0eb5da','187d7bdc9b242dd9a7f6217374c12bbd85ce0ba79917226ab2689a6d3846233f');
INSERT INTO blocks VALUES(310218,'3eb26381d8c93399926bb83c146847bfe0b69024220cb145fe6601f6dda957d9',310218000,NULL,NULL,'7ed9d9c0e19b48b241efe69b5210cb63c8799b662532c56830f58090cb923951','ac26fe7ccb7be079503496d66ab30cd3018c1f788935bc4350b12e16882b33d1','eb78fc67cd65c07b1fc612f77257f8b090b7f1d02d0133d05a59bb9e54bf6679');
INSERT INTO blocks VALUES(310219,'60da40e38967aadf08696641d44ee5372586b884929974e1cbd5c347dc5befbf',310219000,NULL,NULL,'4228c1e87fef1c99cfbf5d07e707b54832612df7853ec9a0530bdff71cced8d7','dd932a4c49f5385c3cb56ec5fd7d3f5078edf6e38179cad6560f538d6dc3e4f4','dec31b21e380138fcdcae2b9dd08a955f8dfb5b97f7776b9eabe325c2a5ddb68');
INSERT INTO blocks VALUES(310220,'d78c428ac4d622ab4b4554aa87aeee013d58f428422b35b0ba0f736d491392ef',310220000,NULL,NULL,'614850f28d887d876f74bb6a8a141f3acfe292e8c497ee92edbbb91382971610','38b894033bc4531b4379084be86aba591c63d0eb2cf71f6b74d64f08852a4801','5652d3cf285d1c8e3fcbd3fe116b8bd68e015ba46ef5477e15eabc3915a36f66');
INSERT INTO blocks VALUES(310221,'cf5263e382afd268e6059b28dc5862285632efe8d36ba218930765e633d48f2d',310221000,NULL,NULL,'4029412bd7a8d2e082a448222287c1a402a57304809de3790216ddebeec0f804','6b095c66b94286b63f99030120322776bc755e4a8ac9f1d3f8b319af5f646c50','98ee8135891fd1816abf3a2fd6e955de632ef276325892573614a7cd2d918f90');
INSERT INTO blocks VALUES(310222,'1519f6ec801bf490282065f5299d631be6553af4b0883df344e7f7e5f49c4993',310222000,NULL,NULL,'57d5ae2e9a20ccf27eafeb39a868142b93135fbb226162e74d2ec13e0d8a1242','8bdac61282b0d140be292ecfc9590d0f17ef57d0c7e9ac9fe47082405ee945a7','09cb220ebacd6f51d9b2c49327d9c83b9448d6d13d6ed05e9dcfa9c3968aec7b');
INSERT INTO blocks VALUES(310223,'af208e2029fa49c19aa4770e582e32e0802d0baac463b00393a7a668fa2ea047',310223000,NULL,NULL,'8ddb59a6ba5d482dc470bffffa489d1a41c703932cd451248f963f8ef2912f87','1753a6a84a68f2896b0a057647d889cedc94d6734ab6ce4a2bc77ff53b1232b6','ae98770bc104d9ad27bfcc33194040dd2aefc0c373b20b946045ae9377a5540e');
INSERT INTO blocks VALUES(310224,'5b57815583a5333b14beb50b4a35aeb108375492ee452feeeeb7c4a96cfd6e4c',310224000,NULL,NULL,'7f628115f9319e8aa5233e3cb5bdfac389d7fdedf34b660644f3d9f6ce5aa791','eb2b51edbcd8416c12fe9496fa7f8ecceedd9decff98bec3f6b8b609424c5087','ce10202511d81e21b4d39c9dd0e953df3a2a41efc1cd8da8993abb6182a32f84');
INSERT INTO blocks VALUES(310225,'0c2992fc10b2ce8d6d08e018397d366c94231d3a05953e79f2db00605c82e41c',310225000,NULL,NULL,'2ee19ddabbd18e20e5416f2c14f4471c1c2ffa23fd18768f3edcd9e32ead4de8','2b4fcb200005f1e4d6914a85ac7f8b38c846f9b7af4b21617f43e1857c68f25b','72d24832a526bce8cf4434b80a6e7a3d4fe800fe0c773cc50385cd0ab452f000');
INSERT INTO blocks VALUES(310226,'b3f6cd212aee8c17ae964536852e7a53c69433bef01e212425a5e99ec0b7e1cb',310226000,NULL,NULL,'d998e2dd3276270cdb45bb00cd2872c2db9374452c29e34559b6474152dd669f','23f3e41f19f5e1c23521b0f558ee048cf770b1f60e43440db0bdebf4cddb7d9a','1331f7d77b3427ba2c9a4f99e0758e34d823edaa46faf87c56f8b8065b493e69');
INSERT INTO blocks VALUES(310227,'ea8386e130dd4e84669dc8b2ef5f4818e2f5f35403f2dc1696dba072af2bc552',310227000,NULL,NULL,'b326242b2921ce6dff797b110634acc19da685c7e0eb05d0b8922953c871bd3a','2107a01629627714229c98a83d32f82077e8084c69fc6dbf49c2463d5e57c11f','89d1ba00cf6e579b35bffe74c8592c0bd52b0169ef7d637f9d1fe3c83f10e0f4');
INSERT INTO blocks VALUES(310228,'8ab465399d5feb5b7933f3e55539a2f53495277dd0780b7bf15f9338560efc7b',310228000,NULL,NULL,'00f4bc8c3c92e02f9d76d48475408ed71220d413e8a908c00ff931b2f21efc14','7dae4309246ba01de7f32298f836fa7d1032bb16c71ef568baa65adada2e3ab3','8ab8feb00a6921223dac41404d2b59665b6d13fb3acd7dc002b4e5bec0008e94');
INSERT INTO blocks VALUES(310229,'d0ccca58f131c8a12ef375dc70951c3aa79c638b4c4d371c7f720c9c784f3297',310229000,NULL,NULL,'4429047d52bb9d1fada5fa2aab49beba326b7dd39c18a8886dba6fff76033773','b6a281c7e03d467766737c8fb4fc063a8bc498a2112e96fd503d97cd086b5cae','c6d8e159a28bb5cf66b72d132472c8a27d5b2b5f94f6acb13c78df3c4e5f4352');
INSERT INTO blocks VALUES(310230,'f126b9318ad8e2d5812d3703ce083a43e179775615b03bd379dae5db46362f35',310230000,NULL,NULL,'a54ffd210dd02de679061b743d3d72d6e665ab06e3c8eee226f41d699e019660','d3847bf37db257796b4eb3e3d27c8cd547badf2dd3feeb786b43beeebb92e1f9','60cdb1ec0939e673ee77c76224f4938326872d33c4056d3eafdc1e89f9f3498d');
INSERT INTO blocks VALUES(310231,'8667a5b933b6a43dab53858e76e4b9f24c3ac83d3f10b97bb20fde902abd4ceb',310231000,NULL,NULL,'54c041e58fd27f7a15ce3a3fca6e8f1718617178454b5b59ab56c31de8fd9294','4af54031aa9431d82cf2552ff1b1a26038923ab5faef5971c01aa3c1c3ab73b9','720ecf70fa9ae9e558d667d6114aad05c6155588a7374dc7f39d4f4848aac5a2');
INSERT INTO blocks VALUES(310232,'813813cec50fd01b6d28277785f9e0ae81f3f0ca4cdee9c4a4415d3719c294e8',310232000,NULL,NULL,'bcfb38ffd70750af483721347dc86ab824b469827f7bf6fb9a76e0a455e8d681','dfe77aaa9f7123c62f9c8173e4fb5d684c26066cc1cc3fc8b1a16b5da0b867f5','f83258f122772909bfe58c7c1044ba715e171232099cd050a3f0c077efa7f153');
INSERT INTO blocks VALUES(310233,'79a443f726c2a7464817deb2c737a264c10488cac02c001fd1a4d1a76de411d6',310233000,NULL,NULL,'412125ac6e888a35c10b2139ab0d714a1362fda6036a7c2f61868cf5505d78cf','519d1dc4f65b76cf8ec728420c9054cd8788b0f96de0b53059a49e299da50778','9b8d425b9c49fdf644fc4e6a0bcd960e39f46b649ca2edb4d1496fb5e52e34d1');
INSERT INTO blocks VALUES(310234,'662e70a85ddc71d3feae92864315e63c2e1be0db715bb5d8432c21a0c14a63cd',310234000,NULL,NULL,'dacde12b9b64e447ecf2f471de22b15cde1c9f79b0ac1fc589c5ecadf1b33b94','4d71427c6ed998ef1f6e7c538729b43eec62df8d9d1590d3730484b3303eb5da','e15046311dc28529ba76104b0902450a5a3bcc5fea1adb5c20bc6dfa17c189d8');
INSERT INTO blocks VALUES(310235,'66915fa9ef2878c38eaf21c50df95d87669f63b40da7bdf30e3c72c6b1fba38e',310235000,NULL,NULL,'b04fbf8874c6f2c42399325f802769fd5e48e4977efe5b38cf81c08afd987d4d','23e03af5f7c019e13836342ab2c1e21da92686be5d60d7e9ee64ffa6b4005b78','10c816b8cfa36532dc395abe324ce8a8cb901318fb26eb796ae7dcef3cd46811');
INSERT INTO blocks VALUES(310236,'d47fadd733c145ad1a3f4b00e03016697ad6e83b15bd6a781589a3a574de23e4',310236000,NULL,NULL,'28a5e3d2317b076eaa37f20046e12ce5288bbd1018176002345fa59c58486e04','e399549be71f5d1f80f57f1bb5b3f3d83bfcf53e84db30cd0bdbbd59e0d4074a','fcb3e2516dfecb0bd84d129f68a9119cbe1a27517fd99a146a79c0d12147f486');
INSERT INTO blocks VALUES(310237,'2561400b16b93cfbb1eaba0f10dfaa1b06d70d9a4d560639d1bcc7759e012095',310237000,NULL,NULL,'97a3690c7b2e009a2faf6069234b45351896223a8ad879dd53ca644111841a6a','1945b08a48ab84da61316798e3e6dfeb59f4023ec3c343a427d9d274351ab54a','efd6aadcf75d1521b1e8448753a60aa658521b7bbe6088ac9c26d354ba0a89fe');
INSERT INTO blocks VALUES(310238,'43420903497d2735dc3077f4d4a2227c29e6fc2fa1c8fd5d55e7ba88782d3d55',310238000,NULL,NULL,'f795b30c29cca17ff344d9e412549359f4a3b5667f295400110decfb302dc6f1','f6bdade1be2e5490a29de8819a562ef1ea8d8d4924b775ce116fa7d9583f375d','3775d23adeed86ba440e56746d92bc4dd233e98bc2808e372108b686c173cf0e');
INSERT INTO blocks VALUES(310239,'065efefe89eadd92ef1d12b092fd891690da79eec79f96b969fbaa9166cd6ef1',310239000,NULL,NULL,'6c1bb10a0396093699db894023296927c14cb213bf3e30c61ecdfbba4dda8ead','fb3e2ca114dc42746dad5feafbf907bf90dd90955b185964cf5cf3081be81b5e','295da02bcb32cd0178ee8cee3dfe11a4cfefb34dfb1954817ff34d4441c86ddc');
INSERT INTO blocks VALUES(310240,'50aac88bb1fa76530134b6826a6cc0d056b0f4c784f86744aae3cfc487eeeb26',310240000,NULL,NULL,'439af34c3d93070cfcc0b31ef5c09d30a2853b11c08d3e093eb10a195639addc','5c09baffbf5ba5c8e8c0210fff80b41de9d6e310257d9e82a9450a7127214787','906858d46eaeed97588b4870adcc15b193c89fce994a3095438429519739250b');
INSERT INTO blocks VALUES(310241,'792d50a3f8c22ddafe63fa3ba9a0a39dd0e358ba4e2ebcd853ca12941e85bee4',310241000,NULL,NULL,'ca47512d43e05c79c18a57a3ea52c34f5fd5c25ca25859fa45d003cf2e114386','e804518e8aee323d48773a15c9c3c16f806c9e4e6a5cb4715cdea571c00545cd','50f927f6271afc6f179d562625062c030e812a5bfd4d7653ac93191f17515fad');
INSERT INTO blocks VALUES(310242,'85dda4f2d80069b72728c9e6af187e79f486254666604137533cbfe216c5ea93',310242000,NULL,NULL,'5aa9ab70050143c497f02de6241d86744b72edbc3292d8206ad3efd179692990','dfd9dfd14f0a1adae66139acd58aeb284fbda7762add9f617c5c9e79c4160969','7a8747fd3fd45463632b0b320f89ab2c6459e7a704d0c8854c0e1a3c001f0593');
INSERT INTO blocks VALUES(310243,'a1f51c9370b0c1171b5be282b5b4892000d8e932d5d41963e28e5d55436ba1bd',310243000,NULL,NULL,'0e7307890e7621bde4544320e8a5e9a1e6d576ef999b34d3053abd5c478a2f69','2b93a6c5dab8f5916b9a92311737ba5cbb370653e2d0531117d668cf8447b59c','30211c1bec13b62aa62ca89caec9611f4281482f8bdf3e143f5a1c5d874b1c3e');
INSERT INTO blocks VALUES(310244,'46e98809a8af5158ede4dfaa5949f5be35578712d59a9f4f1de995a6342c58df',310244000,NULL,NULL,'c49b74cbe77d692ad808180fd79f5bf119979b5130183828393865a0b07f70dc','0b50e5ebfeac9ff1593c3162dde4db7fd5f01e56bb4d880e92f0c04b60e5e8eb','0d435bb9a5265292b5293944c2363a9db3860927d6f6d4806618b771fd087048');
INSERT INTO blocks VALUES(310245,'59f634832088aced78462dd164efd7081148062a63fd5b669af422f4fb55b7ae',310245000,NULL,NULL,'14c5adfd16869731464bca9505f39136090fa9a96374e724a79ea1ea482f42e4','c423b94a1c6bbd9867f042385514fa3f22d6400d6a7dfcf48ba1e38a5a67125d','dd52338c6e46c473e40a855f7eea2c1668fc78ad2516aae0dae976af33cdfca9');
INSERT INTO blocks VALUES(310246,'6f3d690448b1bd04aaf01cd2a8e7016d0618a61088f2b226b442360d02b2e4cd',310246000,NULL,NULL,'ffed3d4e32b44744f63f94dc4016e44386d90ce73dc59bec1fde4a4c639f5a93','4381be017428f8c66be92d0460e6c9ddee0f7f7b9794eb777adf3c4a7fc7b11c','60c66958fb1f9746ce6e5ced9fb610bfa35345178b153985fcb60bb4516c2307');
INSERT INTO blocks VALUES(310247,'fce808e867645071dc8c198bc9a3757536948b972292f743b1e14d2d8283ed66',310247000,NULL,NULL,'2d9fd0ce77ef91b47eccbbb07df3fbbf1939204c7ec6bef0757590222baeb3d1','0868bd00740d4096cf71e26b78b542e52461c053bba62f6951e4b60a1172a350','56a4bea4668dcd40a51892435263d633be22ff2f3b130862672cb764023f55e9');
INSERT INTO blocks VALUES(310248,'26c05bbcfef8bcd00d0967e804903d340c337b9d9f3a3e3e5a9773363c3e9275',310248000,NULL,NULL,'27a5588eb06f95386fc0260358447c270de52b3f27add5c5a8deb05eb80a75a9','92b9dea8c29e59e1467cb2e05f8558229b14752f96f4e315a16792b17c64903b','c025607a5696ba7a7c6e1efa0523121d800ffe302fbc353e41832b98cf6bc579');
INSERT INTO blocks VALUES(310249,'93f5a32167b07030d75400af321ca5009a2cf9fce0e97ea763b92593b8133617',310249000,NULL,NULL,'67f831e7d3708e9ec022c5f36d00b2a58b25ad8c4d1c06df3ecf68dd0177f189','e1b07f6b96b02ff92798186ec5c7697013e796be946dc90cb5e21cf9744ed4a4','d09e1fffe3162c4158f2f3f55c8453804334608bf616d9b3bfff5944f9b9ca4e');
INSERT INTO blocks VALUES(310250,'4364d780ef6a5e11c1bf2e36374e848dbbd8d041cde763f9a2f3b85f5bb017a2',310250000,NULL,NULL,'1b4370eef682191523be85c6196bbaaadf85b64588adbcd4a395a10eeeee7948','94c4682e6615ed5108e67846b956b964164e9e03576eff755d9a4ca533cf6c04','57aaeb1f24ae53e44b367555ce807717a317e350efda34975bd8c5ab41b5d667');
INSERT INTO blocks VALUES(310251,'63a3897d988330d59b8876ff13aa9eac968de3807f1800b343bd246571f0dca7',310251000,NULL,NULL,'93e3bab3e8db9f5e22e706ab8f2822abb79a5fd18f580c46223a9a46e285b2fe','5002b0db535704b74025ba5794ef9afb5ed3e0520046e096fde539cdce0373fc','94e215de5a638817c0bf81f0588e62ad841026c2dfa31428506858bb11fbecab');
INSERT INTO blocks VALUES(310252,'768d65dfb67d6b976279cbfcf5927bb082fad08037bc0c72127fab0ebab7bc43',310252000,NULL,NULL,'afe5210ec35d38fb4556ed358bd2d3ca8d5a61c20b1df91cb6b8a8ae51637da1','5d57812408d8d2213c1f08bf62ac70c49169e00c5445a284fd50d87aa1a12383','1b35b6150488a3413835162f0d532fcc1b951692f021b86f3e1a308a69467bf2');
INSERT INTO blocks VALUES(310253,'bc167428ff6b39acf39fa56f5ca83db24493d8dd2ada59b02b45f59a176dbe9e',310253000,NULL,NULL,'cdf601961c619db2f08cb30a31928e1d55d6fcc7e25608ce6d10619318f703aa','00184053174eb136a41bfd30500c90735516913f6a0a50e9305e1b96c907c144','2772f17f1a858ab543c1c84ec28c0d3d99d2be02f45bee2793ebc783db4f42bf');
INSERT INTO blocks VALUES(310254,'ebda5a4932d24f6cf250ffbb9232913ae47af84d0f0317c12ae6506c05db26e0',310254000,NULL,NULL,'aeeb6af3664da553571ed505255ee8ae6b7216a05eb4a1378be027c791bcd5da','77531f0c1c9180edde56fffe2c19ac9d289619168619a7591db6ac48a320c839','a1f65df416c73a10f0fb9546ea9440e95f6db47a99355297966dfdeb2cc839ad');
INSERT INTO blocks VALUES(310255,'cf36803c1789a98e8524f7bcaff084101d4bc98593ef3c9b9ad1a75d2961f8f4',310255000,NULL,NULL,'7e5fd9891eae9cb686a1d77f8a26ac467abf9444515f3ef3ff1fc7eea77ae077','71f509ae3cd313b25d03c153ef7b57e012ab18c2c3bcca1240f9bfb18f02f876','2955e7f415e4a24e6915e1f83295e32fed6d59625ded069e8382e9444099d891');
INSERT INTO blocks VALUES(310256,'d0b4cf4e77cbbaee784767f3c75675ab1bf50e733db73fa337aa20edefdd5619',310256000,NULL,NULL,'8638fb05c65c1aa75a05e16c779216086f3551c6057660836abdcac483381c25','5abf7b0c0885de417403efda95d6ec3af168413f095ad36b33fe5ee13803bf9f','0392ab778d7bd205654cbd8140a89c12d8096fb8cebf59415d0f3fb1c35cdc64');
INSERT INTO blocks VALUES(310257,'0f42e304acaa582130b496647aa41dcb6b76b5700f7c43dd74b8275c35565f34',310257000,NULL,NULL,'5d9213bceae70da7beec6fc585b547232da5463b17b280f6020178f99837f3ee','6c685bf8a58d4685688605f12ed8c679376496a128c483ede400168566d359a2','8a5dc5ecf0f8e4e6e4d0d0f5b27c88c2c65e0769215513216d357e2c291f2b8b');
INSERT INTO blocks VALUES(310258,'3a0156dd7512738a0a7adba8eeac1815fac224f49312f75b19a36afb744c579f',310258000,NULL,NULL,'87db5933fc8c6a241caf30e3d0d4830f762ce49c6d341790651ded692109c4da','b8fce7a1aa111285fa29065b0c7216c651fcc9e7c0943ec638109e5be4b11902','b60da1c294d499866ce7d9dc9bf1191c0a30fd6e04f88ec8accec277360bb94b');
INSERT INTO blocks VALUES(310259,'e5ed3cdaaf637dd7aa2a7db134253afe716ffdf153e05672df3159b71f8538a9',310259000,NULL,NULL,'8215683693671c96051a9d0ad33b9a39ce2f5d77618c4c6acdeeffbfb029d236','ba2f489f807a137e055a85566291dba9f05c82b499e04b857da7a3d04f81c3dd','7fe9201f6c179d9bc887cbb53940d78efdad7b72c40fd194f610196119a0c3a3');
INSERT INTO blocks VALUES(310260,'8717ddcc837032ad1dc0bb148ddc0f6a561ed0d483b81abb0c493c5c82ec33cd',310260000,NULL,NULL,'b0b63bce75c934da17e2ad1926c3a9c9700081065b406eb3679f73dea7478e30','ea15d2acdfdef767b10e31f556e6cb45093ec07080ab2ddb46d39461beee4a43','b6cbb25dfcd9299f5cdc68c6121d2bda36c34c1d705091b14f4387d7a1a2112a');
INSERT INTO blocks VALUES(310261,'a2a9d8c28ea41df606e81bf99cddb84b593bf5ed1e68743d38d63a7b49a50232',310261000,NULL,NULL,'0f7457334ac9b06dd42dfd1a5d6cfd8346a9603097180da9d596a1f64d99e849','488314a2f9c1d2e61c9e0901a6b86977fbf1f75c3a003d5ae6f25b6a18cc0e46','b9e2a3ea0c99db14fdade06b5e645c8240a1e269d8df388885b0bff76bd37e41');
INSERT INTO blocks VALUES(310262,'e8ebcee80fbf5afb735db18419a68d61a5ffdde1b3f189e51967155c559ee4ce',310262000,NULL,NULL,'0a871578f8f63d705f7b99bcde2a8843f1c12bdad5bcb85313438e2cea3712d4','69362eadf17f094188c41a8cf20d0a3872380dd00ed1e8733c58a98f3420f7bf','24d68bb9c01373bd17887a8c2370794c454cf0d143e3cac363bd4f3b14d0f34e');
INSERT INTO blocks VALUES(310263,'f5a2d8d77ac9aac8f0c9218eecbb814e4dd0032ec764f15c11407072e037b3c2',310263000,NULL,NULL,'4f7cc51fc0218453f1280a7f58dee4a5412a7d2d44c2c473ab35f56fda751fe2','a1dbed0ee1b7e39872fd42a1752147679bb651fdb6feae03010a4e8422d9fcae','162c5e8db221bb165be6c79a61fde42d7e63504f8395f9816760da2bc8c18afe');
INSERT INTO blocks VALUES(310264,'ae968fb818cd631d3e3774d176c24ae6a035de4510b133f0a0dd135dc0ae7416',310264000,NULL,NULL,'f7f739a4813e86655ac5bf4ffce24506504c7eade4b5202f03cd059b2ce9d9ac','e3fe27fb62ff0df89bacea46b407f8083481954214e1427740aa09eb5ca2bfad','15dab66a981eacbc501e9bbec1da3363c32125535e1743105ade2e2b62822231');
INSERT INTO blocks VALUES(310265,'41b50a1dfd10119afd4f288c89aad1257b22471a7d2177facb328157ed6346a1',310265000,NULL,NULL,'b2165b9bf43d717c115b5b6b5192295fdeb1159dfb53031011e8098213749842','d735ea73089a13e0ee3a323416c3da56cc495aadc1f9df446120c63701552443','ad0b51ef5fec233550f3217054a30c46ebe879b9aedd4ef6b1350027e47ad53a');
INSERT INTO blocks VALUES(310266,'1c7c8fa2dc51e8f3cecd776435e68c10d0da238032ebba29cbd4e18b6c299431',310266000,NULL,NULL,'38bc81474d73b6e235c6d597a28d23232acd8468d748ed16726a9203ed3c93f5','068c4d7166d7a40d9708ee60465fdf6c1035da740c50698b0820d747c4df4161','07f9d184a610a5a7cd510659bf61ce90355865b85eea9da5b1626f79aab59091');
INSERT INTO blocks VALUES(310267,'c0aa0f7d4b7bb6842bf9f86f1ff7f028831ee7e7e2d7e495cc85623e5ad39199',310267000,NULL,NULL,'cdc6224e982a2c7f6a169f6ad5bffa4c8682dd7a4d2a0a5cabfcb468f758278d','fa8d5bbfeea6805c5ba6085b3f482c6e5f529ead2464fe5fc8ca964875065437','e0375075841fa1e5be0531c7693b71186e59c5a482f6ca72a30f0f2aa81635c8');
INSERT INTO blocks VALUES(310268,'b476840cc1ce090f6cf61d31a01807864e0a18dc117d60793d34df4f748189af',310268000,NULL,NULL,'d89ec7f189d6316d560f81c86c60e67605e18561b73264609b14b7448535cd32','823daa27e4bb92b7ca781eb9b3a821c8c88390b1c9883b9dcd1487cf29300f6e','8e6132d23f2bc57c19f04bbf2a2b30505cfeeb0ef1901a6d8681bab5d57e9e29');
INSERT INTO blocks VALUES(310269,'37460a2ed5ecbad3303fd73e0d9a0b7ba1ab91b552a022d5f300b4da1b14e21e',310269000,NULL,NULL,'280ce9bc029ad98c17722eb5009478e5ef1e6e6d90d04c1c744ab7d3118e0691','8994c6c5549f07fbf64fa5f00482a2c00a0cffd340633d36d5a3e3915998da7e','f3e9745773e6dbf354a5d6be4a556b4901b077f029766a549c2b762dbab061d3');
INSERT INTO blocks VALUES(310270,'a534f448972c42450ad7b7a7b91a084cf1e9ad08863107ef5abc2b2b4997395d',310270000,NULL,NULL,'abca2bc8255f9a84772eed4538b46fb9e7cf5b3d6edbfb0ac3662bcad6aabce6','4195fd2587fb09f60e053763dea2ba6708724f74f46a21dbc3874925f613cd1d','eef0a8164753050425fe30d77ded09acb8cb8b007000fe674d202f11c0a58570');
INSERT INTO blocks VALUES(310271,'67e6efb2226a2489d4c1d7fd5dd4c38531aca8e3d687062d2274aa5348363b0b',310271000,NULL,NULL,'a0d0fad47891bc7f16c88110165b524bb8677a5d0ecc7c0fa4139e56762e65ed','a0f94d87aa01bcf5575592d39bda2d92fe7b0f89709ef0d4304a220dff9f2a1a','17de37559d0145e333bed080ec856fb7472a05fa9f09ee73d6b282938c48a923');
INSERT INTO blocks VALUES(310272,'6015ede3e28e642cbcf60bc8d397d066316935adbce5d27673ea95e8c7b78eea',310272000,NULL,NULL,'4b673e6e2b5d26c6a8dc6881986bbfaa7c18c0f6e5894a6b183139229863fbf7','01ff414cbca496fe38c3894658f94ff9f2f238de19fbd2b569ce0032260d77c5','4b206a60212a2a81b747926d7a8b21cdd76cc76071622b367cea148e5b447b03');
INSERT INTO blocks VALUES(310273,'625dad04c47f3f1d7f0794fe98d80122c7621284d0c3cf4a110a2e4f2153c96a',310273000,NULL,NULL,'b834722d833eaf488b8a28259de3a16ff1914f73b93689f953bcd23a05084341','c0e19d85af1d934958cd0320ed6297e35b633d2fa1374a8adb9082402bf292ec','404e55f024dbc6dae226bcd3f5f120299d81c5e44d824c355b43c0e33ebfdd39');
INSERT INTO blocks VALUES(310274,'925266253df52bed8dc44148f22bbd85648840f83baee19a9c1ab0a4ce8003b6',310274000,NULL,NULL,'e79ce81893b1b179cb46fc19c3f16ebf0f23dbd9f5d1b2b304db4321e5cd967f','66a5a03d6ee6666be7296f501d424dd85fdf2fec96b4c25c84502c0d64fb6159','1c881896d8007aa8233ee8833d2dd2c9c4e91e9b55e786b4fa0dc369f9505f3b');
INSERT INTO blocks VALUES(310275,'85adc228e31fb99c910e291e36e3c6eafdfd7dcaebf5609a6e017269a6c705c9',310275000,NULL,NULL,'c14d1662897e072c3ada82bd03b071f81723051586f60dee87ea4a8d66c08a12','31ca1cface2d82778ad3d92cd92ba147084d7f57baf66810e20a447be1f9a53c','9b2927add157d6d2fd3a0c144662610388caa32c326f57827d55becd311d960a');
INSERT INTO blocks VALUES(310276,'ba172f268e6d1a966075623814c8403796b4eab22ef9885345c7b59ab973cc77',310276000,NULL,NULL,'93fbdd2c91687b2ab64d76546fe4056897b090cfa8e775958b3727c4d34c760b','677aad0a2b1bb81e9ca203dc176201e2175da38c046629e258886db8e9fcb409','862b94cc58bed5518a2110f63dade68688b74728552a9f0d03c3438b8945c118');
INSERT INTO blocks VALUES(310277,'c74bd3d505a05204eb020119b72a291a2684f5a849682632e4f24b73e9524f93',310277000,NULL,NULL,'9601dfecbff9a416fbb55bc45653b27a2d02b49e59535ce27db44cdefbde5475','b8f8ae04f0ecd636354fc7c0079eb2aaa2c4e328168eef4beb20a016f4af161d','f89b587443ba65e4ecf86c459f6d10177f3864e985a1e19e6213e5e28e2dc120');
INSERT INTO blocks VALUES(310278,'7945512bca68961325e5e1054df4d02ee87a0bc60ac4e1306be3d95479bada05',310278000,NULL,NULL,'731d9d0e816b7469ffb9d3346d239c88676cd2bfcc6d9ce9b5b272f92bcbca4d','2c430e6c23b34bcbf091004690573a2d6fc242ad03353b3fe71a105c78ed70f2','662f8b5def657cdadefce05349f13e88f75a57255ab858a97ba74652b037561e');
INSERT INTO blocks VALUES(310279,'1a9417f9adc7551b82a8c9e1e79c0639476ed9329e0233e7f0d6499618d04b4f',310279000,NULL,NULL,'b3532e1dedac1585de0a039088303e03c01429d588ca3bf88107447edac4111e','c6f87ac7cedfb78124723110c56c52f74eb468a7d07a653982021bde997fa495','158ec575e94c692b3ed5281c1c63db4e0576b9d33ec947149961100603788a3d');
INSERT INTO blocks VALUES(310280,'bf2195835108e32903e4b57c8dd7e25b4d15dd96b4b000d3dbb62f609f800142',310280000,NULL,NULL,'4d33f58684a1f4599343845c857f5282c1424205aa9027f05a0acb67d0f8961c','8b830bfca2ea5ef5f6368a5b0fffefd2118ad099cea123766cca54bb3a0b9d66','abfd571c3dcd2c964b5aca779b314bc54e50b73628701034aa314cc65bf37765');
INSERT INTO blocks VALUES(310281,'4499b9f7e17fc1ecc7dc54c0c77e57f3dc2c9ea55593361acbea0e456be8830f',310281000,NULL,NULL,'855b6f20ed079cbbf462da17fcaf08dc1f578a744a84eebbe143675f12c4332c','c68c28c75b25cd1c56e678a1a66ab52baa79a567ae9e197745874aecaf6a6acc','980a44c9083e64192845a97cc475de05d4f30e271a465ab7fd2bf0ec3636bd04');
INSERT INTO blocks VALUES(310282,'51a29336aa32e5b121b40d4eba0beb0fd337c9f622dacb50372990e5f5134e6f',310282000,NULL,NULL,'d68f2ccf24644bf6ddb50d9feefaf31622923a33e5f6e666f5976c79088fe8e7','b545b519d91f07f02a2f745e079468406a8c4d5ed85e10712de6a6ca5745633b','23273c55754958c668bd909f57594a11e47601d697e959c84bbe4a4deeec6a5d');
INSERT INTO blocks VALUES(310283,'df8565428e67e93a62147b440477386758da778364deb9fd0c81496e0321cf49',310283000,NULL,NULL,'ad092a22d24107893e1b86a961ee775789d2f899c170c62d62bf2816801e0872','b912693c8977c24d5fbdae175045688c50fd545138521a1d3d7d879211ff9e71','bbf5bf3c24fab5a0baf7d0d5dfc358bc4e8696178e3cdabb26df220c00fc7662');
INSERT INTO blocks VALUES(310284,'f9d05d83d3fa7bb3f3c79b8c554301d20f12fbb953f82616ac4aad6e6cc0abe7',310284000,NULL,NULL,'dec3080fbb5b0d3aca99beb45408fb52f237266e447f151fb8be21b2f38e41d4','1015f4fc382066d6e872c198ec183fc20e8ca51ebf74c7acf5b94cd434794427','07aefa09f4f0181af594594c50a71eeff2ce004dc5c201626790f6cb7981c03d');
INSERT INTO blocks VALUES(310285,'8cef48dbc69cd0a07a5acd4f4190aa199ebce996c47e24ecc44f17de5e3c285a',310285000,NULL,NULL,'86040f7bd619eee3b9de0703ff0a7149c7454a5148a6d802582df1b0321306ef','852a5b1eac822e70ba2a27efa43f8f62b0aacb3ed1160a55d42f46f75ae44208','6ab8474ba60440e1c48e9640c758456b10c5cc2d6a706ca7ca82fd96f66a3621');
INSERT INTO blocks VALUES(310286,'d4e01fb028cc6f37497f2231ebf6c00125b12e5353e65bdbf5b2ce40691d47d0',310286000,NULL,NULL,'7ebf152a569705fc8fac4a12aa0dabb9afd16000a1a8c3917836357db3cae958','2dc8cb495a044d9c5b4b724471f679df30788f1b4537e6e7683f7f99a5d0c39d','7743ef0d2b0d8cd32d03ab909efb9b8b5c6fae1a17c24570deec5904dc62283f');
INSERT INTO blocks VALUES(310287,'a78514aa15a5096e4d4af3755e090390727cfa628168f1d35e8ac1d179fb51f4',310287000,NULL,NULL,'55067f42fbf4a87bf4243f88bb60af2e3be3e4b594ade3b4bbdd0113adac70b1','dbeaddb1016c5c61a0fb3308d956759efa4a9a31c6b2471e6e666408d3d61fd8','b14eb532228d7a020f20bcbdec070cdc1c9523419ff14cea27251fdcc59bc3c0');
INSERT INTO blocks VALUES(310288,'2a5c5b3406a944a9ae2615f97064de9af5da07b0258d58c1d6949e95501249e7',310288000,NULL,NULL,'c382f4f293b7a8e14f9050cc9e08bf3efbcbd1238668bee3e5ef9d2eec0e54c9','b238c3a8c309592b50a7cec44deb72e21b31d1073108f0882b11530555edf9e0','c33ffa45e79b2f0033011475c3c5acfe64293b9f8c6c520644f808c10663ff8a');
INSERT INTO blocks VALUES(310289,'dda3dc28762969f5b068768d52ddf73f04674ffeddb1cc4f6a684961ecca8f75',310289000,NULL,NULL,'902fb0fdb2ee978818ff2775db7ac9ad3c9b4539299f206ea720bb0086408a1e','77ac27c75f4d2b0e4fcbe5e3277bbfc3439b6524803dcd9c70a69b931c351ace','1ae25b38f4e6805cd0f63863d1d8017528022e78a25c28bf49e0ee035f17f154');
INSERT INTO blocks VALUES(310290,'fe962fe98ce9f3ee1ed1e71dbffce93735d8004e7a9b95804fb456f18501a370',310290000,NULL,NULL,'b69b14a48832720c64b5ff8f29fffbd117c11862fac1c93cd7335e923a5e6678','3d697c20d19a1ac601964fb3f8c9d937291453c957fb64f171308aadbf7813fc','6d9482306df568d929e64bc6a92aa47732ea26cb6b76f6ca18c99c6c27a0364f');
INSERT INTO blocks VALUES(310291,'1eeb72097fd0bce4c2377160926b25bf8166dfd6e99402570bf506e153e25aa2',310291000,NULL,NULL,'5e9cfc90b12dbd01fb8045b7dfe215bae95a76ec0bcb78a7a0682b83ee5c4438','6e17f9090d87cdec58b6bad634a7ad45559be3e12dbd8661f7f2bff6a9d72a6f','4e39ba6909d46497ac10e896c41cec427ff04e466ab972b3808fc46716987138');
INSERT INTO blocks VALUES(310292,'9c87d12effe7e07dcaf3f71074c0a4f9f8a23c2ed49bf2634dc83e286ba3131d',310292000,NULL,NULL,'1cda3389dc2d4f0517bf24258664925d56b95f3e5ade498dea0f5a375c48ec19','9b67a93e87adcaf74b178bc8359b78b622942ca8892209643fef7c389d3bfe88','52b9500566145af8cc0104ef250fb2b9f16c17c201b2bc55f5520af45d218a41');
INSERT INTO blocks VALUES(310293,'bc18127444c7aebf0cdc5d9d30a3108b25dd3f29bf28d904176c986fa5433712',310293000,NULL,NULL,'b966a9211d2a60f8ab509d318b456bf1ba4f4680f7eb7fbe8144d569c0124507','d668d6df7a98e109c6e9fc88ad8064f13445b000992eb4e3240e8de9ab6a85b5','3392c3339a6cf570c73642d9d2b4f48ceaa0577f7d20c8dc56edafcdb1e8db52');
INSERT INTO blocks VALUES(310294,'4d6ee08b06c8a11b88877b941282dc679e83712880591213fb51c2bf1838cd4d',310294000,NULL,NULL,'bc23c8c1a57ab6099ba111244faa50cfb2bea0fee8b0ff4d636ec84b71159cd7','64ee74239e24b6817d6350e820731c2f6c6162fe1520846a34b35e1c6596a67a','c44dcb3efde1b670ed3f8739b66b960bd8d627366bc00ecbcbed30de508dfea7');
INSERT INTO blocks VALUES(310295,'66b8b169b98858de4ceefcb4cbf3a89383e72180a86aeb2694d4f3467a654a53',310295000,NULL,NULL,'37d89dde31c22b28a945ee9a31599713d7911ad4e1539ce40fd8500eca3bbe7b','3ba4d09da171df6b878efa8167312bba77238282b52e87cb9cc615d0bd04ddbf','1c29bfe874068561fd3cf3b530b5499b006cf1f03837f9e9563251f71ff9bfe2');
INSERT INTO blocks VALUES(310296,'75ceb8b7377c650147612384601cf512e27db7b70503d816b392b941531b5916',310296000,NULL,NULL,'9c78603f612541ab910a857c93a9adeff5faff187042dffe88824d4812dc3c54','f76d3ad85bdfb158426826d9843e2855773e3c2d6f0e7d3e2eecd51cbeba4e0a','5c69eb5c44d5a3ee9f2efb4d636a6ce074bd3c1248f7df0e5e2b18d11f369db6');
INSERT INTO blocks VALUES(310297,'d8ccb0c27b1ee885d882ab6314a294b2fb13068b877e35539a51caa46171b650',310297000,NULL,NULL,'da67aab16effd61a9a55f6e73cd2e151b36c0acb0b813c387ea5a15f881406a9','6dcd4ef32549d9d8aa8ba592759f1d214fa4e583159ad34307430ce02e91abc0','1c7a1a8499ddc99f969b88915aad613160c54310f5804ec3d6439d72925ece3d');
INSERT INTO blocks VALUES(310298,'8ca08f7c45e9de5dfc053183c3ee5fadfb1a85c9e5ca2570e2480ef05175547a',310298000,NULL,NULL,'3805cb37be4090d575bb0f75a1aad50975f2656748b0b59ccd03dccf436ea00f','5221b42768a4a8adf42f502ed9bb74ba4e9277c9ac71a067be51e7e946721279','f7bfa497027b61bcd497dc04274ee9402c5e284001332ff5bdc9f9d1e1258dbe');
INSERT INTO blocks VALUES(310299,'a1cdac6a49a5b71bf5802df800a97310bbf964d53e6464563e5490a0b6fef5e9',310299000,NULL,NULL,'b2b1646a5b7df20bb1657b7a9945b3b85ed711543aeb53abe2cc2af7d9c6567a','2705f43caee10f6b2bdbc3f0741928a1736ff03f3087c1a10c913702c3577a58','72ce4196181d468747c774abb22907e193bac5eaf49021db9348533e14e51493');
INSERT INTO blocks VALUES(310300,'395b0b4d289c02416af743d28fb7516486dea87844309ebef2663dc21b76dcb2',310300000,NULL,NULL,'6128c4cf42c42ad9f74c309a680ed1370078b2488a1ecb170a50eb5b08b4e790','74058889c35701c2c12d0f0743a3515e16e39c83e9038102c8b9ed1894036de0','f17ac7cda3bb82d9f23ee923414c45aa8b5970bc39bfc4e12f3a2b2142587261');
INSERT INTO blocks VALUES(310301,'52f13163068f40428b55ccb8496653d0e63e3217ce1dbea8deda8407b7810e8a',310301000,NULL,NULL,'8066782bfc8f67fa95ff6c63a13e345465272ff82328e3f7dd2fabf1a6bbfeac','29f84c076616daeaf834fc903166f08008630c46892fbbcfc150425e206625af','5833fac236adecd31f084c0bf8d588150e77ec40e6de040fd8d8ddc8313005eb');
INSERT INTO blocks VALUES(310302,'ca03ebc1453dbb1b52c8cc1bc6b343d76ef4c1eaac321a0837c6028384b8d5aa',310302000,NULL,NULL,'e10f8b1fda1039deed31c95435b46f6b19f493d860b4a2eedb88dab270b511f1','0bc037fd747789266550b51edf941419aae1541de20fe010981056704db38c49','61815ae9bf23dd25ce2fc5437e9f9dd08439c56ed0acca11af1fd06dc8b58c01');
INSERT INTO blocks VALUES(310303,'d4e6600c553f0f1e3c3af36dd9573352a25033920d7b1e9912e7daae3058dcca',310303000,NULL,NULL,'79fdc00b3409bb4e280f66b433f5d2c8f08467e399bc299abad378960c77380d','a601d91beeb63e81ffe923a91c15667e7bc7916f2a0e5eb3d422288f11f48324','b2dc494466f2fbdb131bc238aadf16ac02308ad68c33a259f63de525d5d74b6e');
INSERT INTO blocks VALUES(310304,'b698b0c6cb64ca397b3616ce0c4297ca94b20a5332dcc2e2b85d43f5b69a4f1c',310304000,NULL,NULL,'3597237a25a8b9135a96853b2e0ce7c0a0c44250cda7684818cc0da6f4dd03b8','3d89ed4d1d53750e1624b59897bc2de997f3f3907a8757ea57cbe53e6637ae62','02fd4e2c04bac6b18c27101c1d553667a1a8d9a61fe864c3b8e12c466c99228c');
INSERT INTO blocks VALUES(310305,'cfba0521675f1e08aef4ecdbc2848fe031e47f8b41014bcd4b5934c1aa483c5b',310305000,NULL,NULL,'6e56948b7312126772c1ea63e0cf98ca05b4a6e38eafae533ccf48b59d549768','39763b924616344fdd2b99683ef80e767f9ac9dfbf9ebfa0b7fa5d671b931190','abb90b3773dc54ad26be38496fdf6ea20c0c8f1329d8f36b42f4233c2a43ff3f');
INSERT INTO blocks VALUES(310306,'a88a07c577a6f2f137f686036411a866cae27ff8af4e1dfb8290606780ec722a',310306000,NULL,NULL,'53da52d2e62d227319056915a85809815a88a2652429effce10ab75bdf4627a0','dfa8a6666a07852b5b3ded45ed1499146fd0e0026fb81fd4b86d7084453923b2','348de70f1df8e5a22cb36dd6c65543cfc7855a2b574d334ea307f415c540f159');
INSERT INTO blocks VALUES(310307,'bc5ccf771903eb94e336daf54b134459e1f9dd4465dec9eaa66a8ee0e76d426c',310307000,NULL,NULL,'c681f768d9e6f550f4b8f8fc40a22db05f2a0113c1d69fee6a4c98354df94857','0761a80b3a54b28ba252dd8436f566e1256240cc75544642576d2b45ff9c24f9','629ddeb7ec84c63e526262bad834c683976b429848afb6516ef2d52aa670aa50');
INSERT INTO blocks VALUES(310308,'2291ffd9650760ff861660a70403252d078c677bb037a38e9d4a506b10ee2a30',310308000,NULL,NULL,'72c9fb4a94420f9dceaff22f38e7824057466c6cdcf26c5d0f28793ea87d6f97','000cf20d630b20f619533712dc52664b1fbff93c514d572f945f88e00adfb563','6d88f84a152e715515b6a20238becb0800cd481f09039077114dd9e01860dca6');
INSERT INTO blocks VALUES(310309,'ca3ca8819aa3e5fc4238d80e5f06f74ca0c0980adbbf5e2be0076243e7731737',310309000,NULL,NULL,'66e60b5d6fa0c2df4f51fafed4ae913e96491842ee877b4436e8ee6f9ae9256c','22192028618c804c03ac498369ac51791c1a60c410e94767ae073bda1b9679c0','2008e65f4395d10b0f9e664b013920e14559c8de6f36b697b6f502f808c4315a');
INSERT INTO blocks VALUES(310310,'07cd7252e3e172168e33a1265b396c3708ae43b761d02448add81e476b1bcb2c',310310000,NULL,NULL,'6da8a63ba1c6719652f405f94f56f9fb7c01b4e14efb3fb64725128ff38b4d09','23bfaff9a0af98d8cce18c88fead36eb3aeb56bef7508bf8b9a0d91bbf347ec6','395654498c3a3fbb2b20536a8920abea234bf4de1a507b4ced1a8319a7299424');
INSERT INTO blocks VALUES(310311,'2842937eabfdd890e3f233d11c030bed6144b884d3a9029cd2252126221caf36',310311000,NULL,NULL,'bd416f7af4475b9df19005d181a87a9c035d1f0195b65eb416d8a84747390686','470b3db4407d7b3ac3858cf8944dc923e1eb0167cb789628ea2e2ae85b33b511','b9bc126f1dafdf8f3b69b59b4480c0cec2661fa9d6883f8a4d046dd523cca9c9');
INSERT INTO blocks VALUES(310312,'8168511cdfdc0018672bf22f3c6808af709430dd0757609abe10fcd0c3aabfd7',310312000,NULL,NULL,'2a4b5b1e4c0d13f2bcfc88623f6cca4ee2fb4d1c8be2ac2a56a7639ca28e39eb','28b9136cad98cc5682a44ce75bc525808f5bf6d97c074b5f1859e7ffee9e05dc','edf7c4fbd7e81e29cfdca8b481218a9a0dc9c229061cb339de4cfb269b7a7759');
INSERT INTO blocks VALUES(310313,'7c1b734c019c4f3e27e8d5cbee28e64aa6c66bb041d2a450e03537e3fac8e7e5',310313000,NULL,NULL,'af3e82d1281594f4c3d07de7f94925f72b60d82e68dac9e11de5dfdfec78e4d2','0ceb286ba71de0a00dbff921aca7e72ba26a75d2bd6556ae1cd67e9e1f7bb09c','670fc6a3708560fc2af09a4f9a3caa945b4175f8fc08f6efcf6b9a229602102c');
INSERT INTO blocks VALUES(310314,'1ce78314eee22e87ccae74ff129b1803115a953426a5b807f2c55fb10fb63dc8',310314000,NULL,NULL,'cc061bc7415f2f68db5dcdcdf4c20c4c6c5f83780e065a3b9e53e9709ececb07','735ebb102bdd8f4081b3f6eade31c6afe46fbb63150bd22ff23a19c9502bf86c','1cad7b4c02b482f0008fd6d6d7ee3337c2bac68174903bc23f3aad25a6605ded');
INSERT INTO blocks VALUES(310315,'bd356b1bce263f7933fb4b64cf8298d2f085ca1480975d6346a8f5dab0db72cb',310315000,NULL,NULL,'e141ee74bbf64d2573aa03b2a09c660b1523b10e6405aaf817aeee6ae11a6a96','df7dd4de1be3188321bae51a4d52e206ac7cde529ad39aa2ca0b603fcb760029','97a33eff74ea59e027f58cb915afdd02f1c5ed6b43aab778f89003555ae1b19a');
INSERT INTO blocks VALUES(310316,'ea9e5e747996c8d8741877afdcf296413126e2b45c693f3abdb602a5dae3fa44',310316000,NULL,NULL,'b8440ec2e1123412fa2a8030534f6d35a2ae1effaaefb85e9e63b9c62ae0113d','188f530010a38b4df27644f76236bbbe9977bf0299ba0d941a0a834c0f44dfa7','2b94a70e7fe4b35b42db711aa4ca649bd52c9654e30526bd4966ef84a979e810');
INSERT INTO blocks VALUES(310317,'aa8a533edd243f1484917951e45f0b7681446747cebcc54d43c78eda68134d63',310317000,NULL,NULL,'538519849e9ced8aaae7a239d94af88451653986f15ab69d283499fdf435cbac','7684655f8618cb3a7f1fff4684cb9f8fcf73041f2e3043c1920f3f8aba33043e','3a0b90f36d8d3028932eec0e0e427fdf4f8e425739dfc722e532c33904c52243');
INSERT INTO blocks VALUES(310318,'c1be6c211fbad07a10b96ac7e6850a90c43ba2a38e05d53225d913cc2cf60b03',310318000,NULL,NULL,'690600c7d47177ade62975cfd5a632875689bd1627bababb069aca769ae9e58d','a553c5e68d0b28a0e948b947f9cd90a77ceae39dd92d6890d5a7095c5aff36a9','3387457831f3ed8dfee51a3e2fe96eed9bd3eadec79b8de6dcf66f6c74aa69aa');
INSERT INTO blocks VALUES(310319,'f7fc6204a576c37295d0c65aac3d8202db94b6a4fa879fff63510d470dcefa71',310319000,NULL,NULL,'1fd15e66409abe2934dd922ca2028b4c2ecbd001f77e9047380cf5b55605ecc1','d15aa8abb6563820eaa4265f336648cc07956980bad058683febf4518076295e','f3fd330475ee5211975096253db2c063bb207a88c139de3db766c346d904b230');
INSERT INTO blocks VALUES(310320,'fd34ebe6ba298ba423d860a62c566c05372521438150e8341c430116824e7e0b',310320000,NULL,NULL,'e864c01bfec22c119a59c1a154c9d49711931c995d7df483e19c0a514da72baa','30e6e531336220d077fa28ed3887a12b3f6a81b0569f672f0895f5ef8602c655','0c554e76eaffc234d45aca26e34f8ecdfed06aecc88b6d504d3d94a06974997f');
INSERT INTO blocks VALUES(310321,'f74be89e9ceb0779f3c7f97c34fb97cd7c51942244cbc2018d17a3f423dd3ae5',310321000,NULL,NULL,'096086a9182ed81b8388e10981a6b01f2fce6ec3ec0c8a5b87da52b24df47e0b','970232a2ed12bb3530820b91420262da0403648c6c692643bfae7509c62d5712','34b65e8ae4ae392578b8cd919ff22efc5d96b3ddc91a45f21556c27207807341');
INSERT INTO blocks VALUES(310322,'ce0b1afb355e6fd897e74b556a9441f202e3f2b524d1d88bc54e18f860b57668',310322000,NULL,NULL,'82c13cc3c7ea87e59249bd2456c6c4a7d084dfa1158f5455fb2251f23731dddc','5f2c33d09902723a99d67a5cdfafe69e428d58bced708e3bda5fb4b5b6940d98','bdf2aaf5dd4cf1a4db17793e5ed950db4be2ccf0b0172bba5fdfb4b3633de27a');
INSERT INTO blocks VALUES(310323,'df82040c0cbd905e7991a88786090b93606168a7248c8b099d6b9c166c7e80fd',310323000,NULL,NULL,'8050520dde76b54978d0d54f31589b5c1d4d798a8aca0fd7836b5516e66f3dcd','0181a49d8cdf811023933580d94b7105c058d5e44b29d403b0d7552c32abbedb','515e92a5d295d1621d2da9f1d61411e490c6edd02cfe8941ff78669c67e18747');
INSERT INTO blocks VALUES(310324,'367d0ac107cbc7f93857d79e6fa96d47b1c98f88b3fdda97c51f9163e2366826',310324000,NULL,NULL,'3329279722a52d5179cafdfbbe031d016306b6a7eddbbea3903e59c761b74cba','0e0540952b51c04577d7603883b9a5a4de055d4a5b6ed42b7135aaba7641256c','3f2f8a5312cfa9028ed542de4fc024e49a2dff28fb95e8a1d1b1021cbe4235e0');
INSERT INTO blocks VALUES(310325,'60d50997f57a876b2f9291e1ae19c776df95b2e46c14fe6574fb0e4ce8021eac',310325000,NULL,NULL,'1070254673eaf1bb90f685e2fb9d05e9bba7f418da2b3b14f4f786ddaa4b8a30','094b5860d605095ebc32ed7ac03c26014f5ec8a0281a4a56aa7a203b9aeae7b0','9ec3a48d621e2b7bd56ae2560b4066785fcd0c93f041d80e2e6e73d3606df6c5');
INSERT INTO blocks VALUES(310326,'d6f210a1617e1a8eb819fc0e9ef06bd135e15ae65af407e7413f0901f5996573',310326000,NULL,NULL,'e202649e5bfe436c5d7ccf7f99a2b5a7cf9f65ba87d01f098b32206504c9955d','a2ab16ffe9876e724b2b4aa48009ccd3d447ce014a5686fceddae4f3a7f98db3','44674366afd91dd7c2487d494e19841bd6eb18e3ebb9b75ed7c8f58948dbede8');
INSERT INTO blocks VALUES(310327,'9fa4076881b482d234c2085a93526b057ead3c73a6e73c1ed1cdee1a59af8adc',310327000,NULL,NULL,'9ef3626eaba8b92a9f399894c80792a374dd3f08f062f5fb689571cabca2260d','5713b74a91c1d3630f5a43c61b07458a1a526eea708df32e42d30eb1aeda62a4','b290a640b4569e33b96548820c31ece2cc0fe749c21ba4257cfc798b65fd1d82');
INSERT INTO blocks VALUES(310328,'c7ffd388714d8d0fc77e92d05145e6845c72e6bfd32aeb61845515eca2fa2daf',310328000,NULL,NULL,'07a505327ad6bbc4c683bfc14560b521e1b8ebfcb162fbe293c2c69da7798ba4','2ef4a8c64440806257a372e1be8a8ee73cfd942dff2e36cc6fa0f4a330e0ab55','045687c3d32601f1f558375e7c0848c5e866b33c552079208c77bc2c371ccf4b');
INSERT INTO blocks VALUES(310329,'67fb2e77f8d77924c877a58c1af13e1e16b9df425340ed30e9816a9553fd5a30',310329000,NULL,NULL,'2620ba5a247ebd0295ee40efe7c8911bee66c3e18fd6fefc61a9d6a542dd2136','db3d1f911bbc11465429b7228097ba727a152db88095c754210a051c10bb147e','13b26b4c0c4422e8b5365bccdf156500ed4846f666b6146d781f9821eed4a000');
INSERT INTO blocks VALUES(310330,'b62c222ad5a41084eb4d779e36f635c922ff8fe275df41a9259f9a54b9adcc0c',310330000,NULL,NULL,'169eb0d3cbd0d261059426128664172facf85cdc2ac67360bc710a1a2862876b','a6cb52d8ee46c78c15a03e455d7f7862511b4366ab802b1b1a66ce57475af63f','b8c77c0f242a55f5b0ec594685068bcc4abdc827fc9d991b6812e23d4bacdc1d');
INSERT INTO blocks VALUES(310331,'52fb4d803a141f02b12a603244801e2e555a2dffb13a76c93f9ce13f9cf9b21e',310331000,NULL,NULL,'3d755a4ee7eb8eac0411ae456b181621345404e89e44bcdb6ffdbe62dd54766e','c3f130d3e9f5f07ada5e1045ee7ae4964048a07589eb506d12416ac6b8559fc7','0a395219d0ade51e43564042f6797ba1674f5b2f78ca286372aeacf02348070b');
INSERT INTO blocks VALUES(310332,'201086b0aab856c8b9c7b57d40762e907746fea722dbed8efb518f4bfd0dfdf2',310332000,NULL,NULL,'5be90c696ec52d15d0d3a2f083526919ab347e9e6aa4a570ea27d76ce6dc7fb9','ab5f23232efac88e2ffc08be7ed29dce1f21ef65fa007ed73bc86b8de462535b','b8701c79a0de173aba118c048cf6e649b2ccd53f109446540049b04d0f2698f8');
INSERT INTO blocks VALUES(310333,'b7476114e72d4a38d0bebb0b388444619c6f1b62f97b598fed2e1ec7cd08ee82',310333000,NULL,NULL,'ef9d3849d24683a39b59e54c1aae4c94b5851c24639b8a6b96259bd577a2ad74','dd0f93d9f4ae86681e964503c850fd4d621e8c629f3c8472ff0b4b7db5c23e49','a97eb9b1460e08b0f1deca0b454b5b3e79cead2376e9a6fe6f373577c89fccde');
INSERT INTO blocks VALUES(310334,'a39eb839c62b127287ea01dd087b2fc3ad59107ef012decae298e40c1dec52cd',310334000,NULL,NULL,'3c915aee8c756fb0a7179b7964e6eec1abcbd1041a1545460d38462364684958','0d4f43865f99cd718ab5fdfe49586c7721c458c7b42c8b62dc89c2c6ca01df21','9d594ee9859e47fc6ed61e40b228d241f96584657c561d6f6ab072c960ce3ce6');
INSERT INTO blocks VALUES(310335,'23bd6092da66032357b13b95206e6527a8d22e6637a097d696d7a96c8858cc89',310335000,NULL,NULL,'70bfef97c118317cbefe631aa022b1e0ffd056c096a6b2deff5ea13ab101c1f4','512d4d2b63c5ee10e575e2df2e7e22b096022005d7b021eaf5a97a298c9f1de2','cbf314f662036a95463648a11dedf7cf8609dfb88014ffb0d7c6d7a907b4a007');
INSERT INTO blocks VALUES(310336,'ec4b8d0968dbae28789be96ffa5a7e27c3846064683acd7c3eb86f1f0cc58199',310336000,NULL,NULL,'bd52821b02bb0570a870b950f6c0ea5546281bfe1138f2978c020f5421a8bd53','c3ce1981f25609de8b1cc2546d5297c0a101f3ac6f5a3e6f2c05979c8a9e8194','5149246c9c08c1284352c42012018d34f52546635e2f2bb56d8e722fee1024df');
INSERT INTO blocks VALUES(310337,'055247d24ba9860eb2eadf9ec7ea966b86794a0e3727e6ffbcba0af38f2bc34a',310337000,NULL,NULL,'4d998c7c5755d94c46fa7c6c7f7791c9258726d626b74eabab67626edbfe9532','abe6837f18aa7d06fe86f5fe25234ae03c1c846213718a44ea38055cc2e1d5ad','0b1bf4438154f83d4885242c307a7f6f08edf07bd4cca6077ad89ac48627c8fb');
INSERT INTO blocks VALUES(310338,'97944272a7e86b716c6587d0da0d2094b6f7e29714daa00fec8677205a049bcd',310338000,NULL,NULL,'3740697e86ec44204a339a8827c8887b5dea8e14de2a77da6e3a777518fd3d8a','04277a722331970faffadef27a71f6783e35f42664bdbeb3e51bffe9d86dab71','af67d3e157b0dcdb0a00e740a33589c9b516f381986423d0613fe449420ee137');
INSERT INTO blocks VALUES(310339,'99d59ea38842e00c8ba156276582ff67c5fc8c3d3c6929246623d8f51239a052',310339000,NULL,NULL,'7d96412a30a7648bec3fe11198ae04404097990502372423ad19834b7b19442f','22fab6e0d35d79d9540c4a69232ad7e86e20cb1c7e72a153be21484ab0bb01c5','d7fe2549a018431044952f20bc71b5a214204e18dec13e9ffd47913a65f00666');
INSERT INTO blocks VALUES(310340,'f7a193f14949aaae1167aebf7a6814c44712d2b19f6bf802e72be5f97dd7f5a0',310340000,NULL,NULL,'da74536dba0582713e235174e67108ac2a285e946366cda2fb7f51052296c6f6','8c1cc3bfcf72af860cbf9890c9949d4205050806dc65f4e0985d8f9cd68c16f2','5af50488e32b4a5dc197229fc54558dea588df17374ef52ce85c093467a46f6b');
INSERT INTO blocks VALUES(310341,'6c468431e0169b7df175afd661bc21a66f6b4353160f7a6c9df513a6b1788a7f',310341000,NULL,NULL,'cc1ebe14893ebcc3a13c61d7e4465f1be81f13626152e134ff51dddd1ae66a4b','af121465f8fac4f374f1cd693313dfa29ae628213b23e6b86c230294a79510ad','dab5fb272c91b17cbac945a985a34d722096ce8f219857aeca59fc5c97956f39');
INSERT INTO blocks VALUES(310342,'48669c2cb8e6bf2ca7f8e4846816d35396cbc88c349a8d1318ded0598a30edf7',310342000,NULL,NULL,'6b6de51e4d1ae0ff8ae523a3426a281f3a6a2c02631426eaac1e522b1d2bb98d','1feb75dff6303ad2dc559546a77ac500ba5c4ab51b306f91df90fbb83d34868e','a4b09cc7ee66f0147f953672d4e2d3084c14ed83a01f834720a30b4066ffea42');
INSERT INTO blocks VALUES(310343,'41a1030c13ae11f5565e0045c73d15edc583a1ff6f3a8f5eac94ffcfaf759e11',310343000,NULL,NULL,'cf6e941df1cec80904e2bb9aacae28a06071e4c5f0b2b11ed4e1b083ebdcc1e1','e1e0a84a53cc9cf7c077fc5e686608477c37201a66b27573215cdeb79f607237','1c819ae9344a01de9618d01ad1c5174117866c4020f79eca5dab89965ede3c6d');
INSERT INTO blocks VALUES(310344,'97b74842207c7cd27160b23d74d7deb603882e4e5e61e2899c96a39b079b3977',310344000,NULL,NULL,'dc429ab9d501a49f72f75a1d8def7f57ce4cb7f6025536796ef848ff2acf6956','7d4b0d64696245ab77935830dd0b34b8f67752f348dfbdabb84440f37037f74f','a19b96ec21361cdcaa0e085778868c9c562a8ae9cf877360eecb0a1bc07d00cd');
INSERT INTO blocks VALUES(310345,'0bda7b13d1bc2ba4c3c72e0f27157067677595264d6430038f0b227118de8c65',310345000,NULL,NULL,'005f9980d6fa7b9caf440c03077c1c2d09869c5e8966ff80881d2d614db066a9','80c0003f02797999f818e671fba50cd2cbea2ab293e5eb034f13cb47fe2b0e04','05947f0d07772e9f0465f799ecb108a049c71d53d74cacdf7e8a442b544d559d');
INSERT INTO blocks VALUES(310346,'0635503844de474dd694ecbcfb93e578268f77a80230a29986dfa7eeade15b16',310346000,NULL,NULL,'a35010d23486a48ba503bfd83f95ec182a5f0aab94790042f0bb22d24eda8cee','991b1e1029ef8fa922f9cdacbcd8bb28149ea9be91c4ce1b3a9bf07a1a2f7c35','122a3cbbf20e8aa0ab2f1e6991674c3cfffd2942b62c28517005109057267012');
INSERT INTO blocks VALUES(310347,'f3f6b7e7a27c8da4318f9f2f694f37aaa9255bbdad260cb46f319a4755a1a84d',310347000,NULL,NULL,'afe0f4147688b94a8f7f028228bd4438ae9ae32e8fc7484bd2d71d7e1e186b8d','3f11f36bf32fc665a145280ab750ac5660900219f900a78619becbf18f6a3411','337628b6bd4d1e26af929d89055cc6593f9115d35176f477d99e9b1820e7a5f4');
INSERT INTO blocks VALUES(310348,'c912af0d57982701bcda4293ad1ff3456299fd9e4a1da939d8d94bcb86634412',310348000,NULL,NULL,'c7383960d8a947aba3c1ba4157f96f2c1bcb8fa2b6238cddcc85941c24b6e20c','04248c6edddc41ef7592e1bfa4f7b6e1a07da21173056df5a752700290b01276','3d054c97bba2492a4f8b943f369a08f28c183a65e7f7fb20465034a824931cfa');
INSERT INTO blocks VALUES(310349,'ca911c788add2e16726f4e194137f595823092482e48ff8dd3bdbe56c203523c',310349000,NULL,NULL,'41066e93811deac0164ced956c8ecc2cf6ed49e831ab9b0f5f61b7bb97f5c583','d2110cb00ff1e621b5bb01fa39a1b811fbceeceeb4f29bcda647c84ee09ad8a2','a06ef7a09bb346f336ff3cfd5ab205e4b25162dff1d1eaaef11b3d6b8b6b754b');
INSERT INTO blocks VALUES(310350,'c20d54368c4e558c44e2fbaa0765d3aecc8c9f01d456e3ff219508b5d06bd69d',310350000,NULL,NULL,'d2343f590945ea41186ccb93ba6a1630b66b3216ad3978b43c1b5d105217cd6d','9fb3a5f5be0e3590ba9ea246f01528e076bfa2f0bfda1f31dd009744147734f6','6587a11923e4b8e4c954da2952eb71300a3842e030c03ebe6a14dd3bab708fb6');
INSERT INTO blocks VALUES(310351,'656bd69a59329dbea94b8b22cfdaaec8de9ab50204868f006494d78e7f88e26f',310351000,NULL,NULL,'290870196fbb96760c62cfa3d2072e7432b7f3fcb12f4a714150ee9bc9e95095','7385241c951cbf668ea5d0fb3e81605c99be9de34a1610749af7e6d0b5592601','6b4bbb4494db265b59c5a5cd6029b18edaf8cbaf2e1733280fda1213ca79bb48');
INSERT INTO blocks VALUES(310352,'fb97d2f766a23acb9644fef833e0257fdb74546e50d9e2303cf88d2e82b71a50',310352000,NULL,NULL,'8bd069ac4f828cac429fadec8a2aa2a024aa70d7b60274dee16879d4bc7142e2','23c83a795f22749ef29033d439bda687070dc9441861a178957fce351c92f1a5','acdc60516f06f91ec8a1040ecd683e00f1b273997667223284bc8711cf7e68d0');
INSERT INTO blocks VALUES(310353,'2d3e451f189fc2f29704b1b09820278dd1eeb347fef11352d7a680c9aecc13b8',310353000,NULL,NULL,'b8a1decbdb2898b426e05656cf5f9268c3071e4053596aabd9c05ce60a2f5002','c9b99f972df3427271c3711044558e108356501560d8e3ae8bfd0f62960bbba3','644a35fad091bef99ccfd446f12d95833ed74f28b6056c0ca6f6de7d33c64608');
INSERT INTO blocks VALUES(310354,'437d9635e1702247e0d9330347cc6e339e3678be89a760ba9bf79dd2cd8803e0',310354000,NULL,NULL,'9993fd327b1130d88e4ea98097e0f0b615bb446df61e2f324c0f43c1911d284a','993829ec56ff4ff0e9bed1eb51a0af38818d0577f941967d83ff3223a7dc76e8','a2652e0b6b33af03dbd9246232e24d521a8e45e35818a0e354ddcd08d5d23223');
INSERT INTO blocks VALUES(310355,'ea80897a4f9167bfc775e4e43840d9ea6f839f3571c7ab4433f1e082f4bbe37d',310355000,NULL,NULL,'092a56f3d256a130489149a622e4028b6c11e957c1a02987ddf6c6c940b80073','7c861a661cb54c9876eabab42528c33f4af90c9b33dafb217e8da9fc0f2f4c8b','83baff8fbed88c1bec947c396f7dfa1c62b642127c74470ef2df2bc1eb78793c');
INSERT INTO blocks VALUES(310356,'68088305f7eba74c1d50458e5e5ca5a849f0b4a4e9935709d8ee56877b1b55c4',310356000,NULL,NULL,'80abb322154f882e1fbbe90db2cf1b5317f382a90121cbb48695d3214f8385da','e22e1b40eb8eec58f917aaeb853554c22b4d28f47e1f360756ba7aba483460d9','1cf7dddecf1662fa13a02130c4f4dcac64f8df7de36c18dbd18270178092b4b1');
INSERT INTO blocks VALUES(310357,'4572f7f4ad467ef78212e9e08fa2ce3f01f2acc28c0b8ca9d1479380726bab1f',310357000,NULL,NULL,'9028916f4a48ea837f1f093341feba202d164772f4f16a9ada19076f93bf852c','291e351b27ac6ff635beefe0a009ad85b16f25c162af98625a30f991283b5618','6b2d70db0c081d166d4148dd90f77acc9a221f82db070e5e38a2a21468ffe8b4');
INSERT INTO blocks VALUES(310358,'d5eae5513f1264d00d8c83fe9271e984774526d89b03ecd78d62d4d95ec1dea6',310358000,NULL,NULL,'d93491f0d7de6431a39b6c5ecb4bc2a79b1ced7c497f4e3d42f7768284fc887f','c1a92119b52b572c67f7dd16339872f9346ae18ea064d78887fa19953c9e5414','e8b513bc7d8118475ab3fea88c8fc031e013828abd3455251785ae6096d0ae41');
INSERT INTO blocks VALUES(310359,'4fa301160e7e0be18a33065475b1511e859475f390133857a803de0692a9b74f',310359000,NULL,NULL,'1530f7991ddc34284d623fe3d84fc4c1a6e5d25309f46be2bccc9aa71dbfd58b','c8fbc990edad6b056d3d0e2aa6b5636eefaec567668ad24733a11f9ecc41bb37','b7df6ef7bef0d42e448e73a2643a3f0a40704fb635632e6c920f9bc0353b8408');
INSERT INTO blocks VALUES(310360,'cc852c3c20dbb58466f9a3c9f6df59ef1c3584f849272e100823a95b7a3c79f0',310360000,NULL,NULL,'56404b0c3d30bb481e40c0c76558a36702c740cb8725b7b7f0fcb5464b63d366','66385ec462f2ce7d80a29cfa2f37ec15b54753841afb6ab63eecc51d02280de3','a188561dc375e2830b0ade547141bdca3c6d2809b5847b26a596f6e5ec13027b');
INSERT INTO blocks VALUES(310361,'636110c0af5c76ada1a19fa5cd012e3ee796723f8a7b3a5457d8cb81d6c57019',310361000,NULL,NULL,'a27d13598203dd64dd5f523e9b425ffd79ca115ade6ff8bddeb0e58fc8b02d82','b075e3b5a3382de49361e7a04003d14a7a0c03b3a21f6ed63deb72255fd02341','50db1efc76b99d1ee1014b60cf1bcb0e2e9c9e1b075fb45663342aa3262d3efd');
INSERT INTO blocks VALUES(310362,'6199591a598e9b2159adb828ab26d48c37c26b784f8467a6bb55d51d7b6390f2',310362000,NULL,NULL,'ed942de3639b441b1a111e180b374acd9c97850dca0a654ce6dec1e61394e4be','56c627f734c54edabb03cd1c35a2f7a74722c99295971070c2faa6ef374bda32','00c22d223cf3a6dd361f07350d09bb9ea9d5bf22918aa43b8682f621282c1e2b');
INSERT INTO blocks VALUES(310363,'a31967b730f72da6ad20f563df18c081c13e3537ba7ea5ab5d01db40e02647e6',310363000,NULL,NULL,'de0ecfb30716e576de5270dffcbb6fe73464064e6c9351f88308fdc2dc56d6b0','31b0c9771f1bccd50294bf21f877b1e6c825ba94f18a882493664c3265532098','fc340107b6d6a233117b441737ebd59a7171f8bf6ac4b3747449df3782c39548');
INSERT INTO blocks VALUES(310364,'67025b6f69e33546f3309b229ea1ae22ed12b0544b48e202f5387e08d13be0c9',310364000,NULL,NULL,'e24edbbc4e3e131b551123b724f1b0873c030d27e18c0f0ec170dc6f55cd1e52','69f654cb758516d1dc119c9d0244f3afa48f2ea5d9b25124044f2667d3e5674f','06e05082ca2c8af837ff081f16491bd2d2eaceaac6d9e645e1e19a432efa6623');
INSERT INTO blocks VALUES(310365,'b65b578ed93a85ea5f5005ec957765e2d41e741480adde6968315fe09784c409',310365000,NULL,NULL,'6b9e66db961dd534fec94cec6a8064faacfe82e32434c22f565fa9b57b48770c','ebec88674b369a3c1d8e1d7afac0d2aa5fa287eeb0ff0d99522ad3899803b45e','6630282420a3059bd17c1018fd1d6161112da064effac17b19cea1656bd90b06');
INSERT INTO blocks VALUES(310366,'a7843440b110ab26327672e3d65125a1b9efd838671422b6ede6c85890352440',310366000,NULL,NULL,'9f0841e53849380f448378ab723a78fa24ea79d79dcd5672f569cd201fe9f3bb','28e499c816914ab0999863e7233b7fa84da5f4f6a5e71b7cf15809e199795c3f','bc8c436abe4a16875cefff3ad260c77d68f45f442ca659a379de91954c24dac3');
INSERT INTO blocks VALUES(310367,'326c7e51165800a892b48909d105ff5ea572ff408d56d1623ad66d3dfeeb4f47',310367000,NULL,NULL,'c5f166651893f28096d1d6b58388efc5ce962558a5106d913e68e6c0c6aaad9d','b2c233fe4bed1eae40632e0fde154aad2fa73a722b0cc5b7a9cbd7dc5cc23c60','7f3723f35d9c030be56aaf882c9ebbacce3a11613fb184b3047b392793acd52d');
INSERT INTO blocks VALUES(310368,'f7bfee2feb32c2bfd998dc0f6bff5e5994a3131808b912d692c3089528b4e006',310368000,NULL,NULL,'9e4fb8a0749e2113870feb26dd1f86314fbcdb550cdca7c4379a4137412ab750','f7892111bd9f72522f3fe3a9c1d5303684db7ab3da7fbb76fca82200090d5145','19924afba830d23dcdf54b8c7e33ede6ed05efc808a76c7629d3c8e2851fa7d1');
INSERT INTO blocks VALUES(310369,'0f836b76eb06019a6bb01776e80bc10dac9fb77002262c80d6683fd42dbfc8da',310369000,NULL,NULL,'25089fa1fad0616d4a389c5c05f5a61dbaac9a5ee5fe5e972aac7dc0a34efa70','77c1d646c8d940fcdcee9dd4716f20fca174bdd9422f91a36b967f9f250570aa','64d62ea5925d80a2c2626cee40badd28715059a4a65957e0ec0d18b779525f44');
INSERT INTO blocks VALUES(310370,'9eb8f1f6cc0ed3d2a77c5b2c66965150c8ceb26d357b9844e19674d8221fef67',310370000,NULL,NULL,'50ba9282f58f19010d88995e4ad103a92e219b0c18bda745c62e743083c68a01','5ccbc000680d44d5402696ef97a3dc42b67ca61366b66c45f703b5ff47b2f86d','eae59ec67260df1a114a61303945d87f1d345f7a2b50cf99c25395f03a9fdbde');
INSERT INTO blocks VALUES(310371,'7404cb31a39887a9841c2c27309d8c50b88748ed5fa8a3e5ba4cc3fc18310154',310371000,NULL,NULL,'c821de53cb7f7d5c8d64a7c0b3ad2ce15017c499d659957dcce12fba6c48755f','243ca24da1ed1d5bce75c0ab2c2e1a9a27cb3d082873a3221d7de0a09b6c6a9f','6b40ef8bab245438377983c0d0119688793c08d83ed599a84d0b818cd2096d51');
INSERT INTO blocks VALUES(310372,'d3a790f6f5f85e2662a9d5fcd94a38bfe9f318ffd695f4770b6ea0770e1ae18d',310372000,NULL,NULL,'4fc139104b0ee42c99f5808c06e238669c26f85d6545172bf41a6d5f151ddbf5','56abf948a80d9c74ea1d808250fa92c298f53fc693ff851e61d7b0411713792e','f6fc58f7e046f131400aa33be1a33065dd94acc530b284f94c29b8c7f64b1281');
INSERT INTO blocks VALUES(310373,'c192bec419937220c2705ce8a260ba0922940af116e10a2bc9db94f7497cf9c0',310373000,NULL,NULL,'9e35739a88b113d3c88b7b8491c985ba6dafb35170095462d286054a6d61244f','7e549253bd78a130afa0300b343ad7b4c70894eb91450067628f1cc5b8177831','8d059172c2c400b515ad00ddfdc891b3755b7077349ea0b60b591543ea0a8a38');
INSERT INTO blocks VALUES(310374,'f541273d293a084509916c10aec0de40092c7695888ec7510f23e0c7bb405f8e',310374000,NULL,NULL,'8a216385475c544cf6d52240f66e95c4064202467c1bfd6c13ae21d90fdfda9c','64a902e384e561dc748fde94bab31e756b7d949f644e6befe3146b02aede92bd','c4e29033fd7fdf190a66313d6be1c2c36fab18b54beaa821be90a117332fd4ec');
INSERT INTO blocks VALUES(310375,'da666e1886212e20c154aba9d6b617e471106ddc9b8c8a28e9860baf82a17458',310375000,NULL,NULL,'1c1ac076cba8f4c5ec85c4b94170a31be07d94b2a93c98265057ba31e18f946e','aba75e58ecac8fd4b4803433ca3b81e1029c5c45fa18d6137f72eeb0e195dc0e','4ed5989c9523da29e1c651a4065479fa67a5173362475544e6add31d8d448183');
INSERT INTO blocks VALUES(310376,'5dc483d7d1697eb823cba64bb8d6c0aded59d00ea37067de0caeebf3ea4ea7dc',310376000,NULL,NULL,'0fae94f342170fb1f775ee94c972e0231f3902b503246027b9a71e73e0a75d30','7bb8ba926d25fc3ded78f4d9f1149afb2d4512050c800621878f08773af89566','e11a56be3a4ea1e74bf35de5e2361fe7a74e15ef9a9b6346d4f4288e2a79e61b');
INSERT INTO blocks VALUES(310377,'f8d1cac1fef3fa6e7ad1c44ff6ae2c6920985bad74e77a6868612ee81f16b0b3',310377000,NULL,NULL,'a6c2a24498059d9be469e3d0282dfde5ff5d7030e34eaa219431b195f0849ed3','85aac194f03d98abc813b94c6a8a83caca0cc332035626dfd9ce4770dcb7b79e','acee6bc1db85efab23a2722279865e15fcabb54c52ef772b99b1a1e316a5ad19');
INSERT INTO blocks VALUES(310378,'fec994dd24e213aa78f166ca315c90cb74ee871295a252723dd269c13fc614ce',310378000,NULL,NULL,'ab359b444df54152479985691836ad83f50085cc526791ad8383d49d33619f0a','b2f24c035fb03d4f3a95fbc8139e6e0dd2cc3de72cc517484f7f667f34fdabfa','182eb4e5d5b6e878eabc6fb180774056ba81407a316c154d5402ff2513b12da4');
INSERT INTO blocks VALUES(310379,'d86cdb36616976eafb054477058de5670a02194f3ee27911df1822ff1c26f19c',310379000,NULL,NULL,'3aaf11af389e482390a66043acb0cbcdda51292c8e393f0c89666564413ebc94','67b13d59dcfbdac9a7206c7e5b5d43abb42232d626d7c9e6cf08dca9d7d5c32e','c7922d612383daa01535858e06ad5ba42d1f43232b1699f02f53abf0d674cb9f');
INSERT INTO blocks VALUES(310380,'292dba1b887326f0719fe00caf9863afc613fc1643e041ba7678a325cf2b6aae',310380000,NULL,NULL,'c9e87750aee19d8d383cccd6bb71652548161dd901379a581113d20871978732','398cd93af194333e68c728b97e17880aa8122ac7ec720c8627a201ef074c261e','5f79d521af689bdc2efe97d6d6e359eba125c3fd562edb7cdcd7884afa19ba89');
INSERT INTO blocks VALUES(310381,'6726e0171d41e8b03e8c7a245ef69477b44506b651efe999e892e1e6d9d4cf38',310381000,NULL,NULL,'bfa20b9be3938c8ffa00e769ea3bcb81475055c987ca08eac513c813bd1a8571','34f3ef6431c4385d0171b0d0753493461602624196bbbce328a8a06eff4fa04d','3ba23c5a432dc4365ab89689b86092084094982574c800dfbf08139363877bb0');
INSERT INTO blocks VALUES(310382,'0be33004c34938cedd0901b03c95e55d91590aa2fec6c5f6e44aec5366a0e7d8',310382000,NULL,NULL,'f736a782d846510ad32ffc368534e6b1966c7da89e6a746122b64ba5533426d2','75d49f961843c3ab97fe6db5a1257959c7db8d91c20934d63220023fcda27948','39c2037c16bc081ec8ee03e3d5553c3a23556b36c90f260fff8eb7b779a28792');
INSERT INTO blocks VALUES(310383,'992ff9a3b2f4e303854514d4cad554ff333c1f3f84961aa5a6b570af44a74508',310383000,NULL,NULL,'0b98c26f33db6d66ee0f86344247b1ed5b5b2ea3dd53e074dd4f0a64066e41f9','882d29c71516069e50fc75c47407a965ab884283204eb8a704f0ac7eaa569ea5','edb2bb7895d1f0c749ed5061227fa98633cacfb7ebff9f58c4f09899b8e35cd8');
INSERT INTO blocks VALUES(310384,'d518c696796401d77956d878cbdc247e207f03198eabc2749d61ebeadee87e5e',310384000,NULL,NULL,'51181d10e5a33aded1657f31dc48e055d091d49ef4514eb833479e2723b6547b','681c1f37c68548c1ddc98cfadf805725ad20423e1eabecdf6e1bab9337ddd86c','d23cec3cd506d2498df54bf7c1aa365cd18319934704080324ef6987847b31d2');
INSERT INTO blocks VALUES(310385,'2aa6a491a03a1a16adbc5f5e795c97ec338345cfdf10ff711ffb7ac3a0e26e28',310385000,NULL,NULL,'f1971e2badf2797cb498a8e92ae930514367da96fda214a5623ceb68fb2c5e02','8604ed15fa148cefafefe83a2ab0630d163ed11b1afbd685381d1b4c28593428','d9bc3e4ec79aa2660113cb6fece372e5ae0db378a7449c1cea693a3dbaed5f9f');
INSERT INTO blocks VALUES(310386,'9d19a754b48a180fd5ebb0ae63e96fa9f4a67e475aeefa41f8f4f8420e677eda',310386000,NULL,NULL,'55b11ca65e8ad9818ddfbdd2ef064f49b0c3d423906f6c2ad5f59264d7a6ddde','f5b80cb009542f7d09aa737536a57fed6ffb5d61830a0621e17e1e617eb22106','4bd2b789156ed86b18ee7d102ef3edf9ff24fe2c698e67e16bfb23e0b794b201');
INSERT INTO blocks VALUES(310387,'b4cac00f59c626206e193575b3ba9bfddd83bbfc374ebeb2838acd25e34a6c2b',310387000,NULL,NULL,'8602a4651e4f5c2e8853c43107dbbe6fbf917e9093aa55bead4b7ca001cacd56','3e32ab0762be69329eade35aa91b7d75d6487928a6a149d31335d47ed86b3cfc','30e7e652c8ffae06a32c2848d207580510ee0a9fda9cb55e44329c834999a48b');
INSERT INTO blocks VALUES(310388,'41a04637694ea47a57b76fb52d3e8cfe67ee28e3e8744218f652166abe833284',310388000,NULL,NULL,'84000a3278f3fd598a316b590acc64f6f14b21af02074870ea490d08f92a2f40','cd4318bfc454be43cf5b0fb3c2a078485fd8898170acd2673042eb4d355f5a68','16c4e12e355414576fc0360fedba55a07df07788d7b438921c48bd19cac287dd');
INSERT INTO blocks VALUES(310389,'3ec95ae011161c6752f308d28bde892b2846e96a96de164e5f3394744d0aa607',310389000,NULL,NULL,'4eed3e61d5896e42eaa2231c0dbdbeb2083053351466b01bcbe0c0973e784aa0','db533595c27e4317c79562f0c7be6adb13896aeeffe155aa4fff461833b2998f','e7634cb83d5725854e81aaf7368dfb4a0e8f4891ef827fb804871b2900417d93');
INSERT INTO blocks VALUES(310390,'f05a916c6be28909fa19d176e0232f704d8108f73083dded5365d05b306ddf1a',310390000,NULL,NULL,'4594159f86d4ddaa5caabe6038c22f4b3c1c3abfe6763cd28405ba50e5c98ab8','40a4f2a000ca344c00b89cb8cff10e96038dd0cb0631c3eee14ae39ef095b450','608a9698653fbb56225ac3d9c1e3f135f06e5f9fa1ec8e82a9d27dd98c45bc46');
INSERT INTO blocks VALUES(310391,'fc26112b7fdd8aaf333645607dabc9781eac067d4468d63bb46628623e122952',310391000,NULL,NULL,'02573a6e3b8664508ea8f70250dd36310597ca1ee65a6e724e58f2f9140fd7cb','bcaaf7948ffeb45fe774c5bd0f3e12582870b6aa44151942d3d7626c4a00bdc2','520e170f4fe2a09f49086c769b9ac74287abf633339eca56463a3cff6f490258');
INSERT INTO blocks VALUES(310392,'f7022ecab2f2179c398580460f50c643b10d4b6869e5519db6ef5d5a27d84a1d',310392000,NULL,NULL,'c20d2c7f133de91658cd2ae20f7393919aeaea53229d5810bc22976f0c765ad8','f3880da2cfde4e0065cd213888c4a6b6cdca5b056612279d383821deabccbfdb','8f8268463ece5a0a4372480206d1fd8bb7c0774f259727c6aaefd3f2008542fe');
INSERT INTO blocks VALUES(310393,'e6aeef89ab079721e7eae02f7b197acfb37c2de587d35a5cf4dd1e3c54d68308',310393000,NULL,NULL,'6aaea67706092057b8cf4a677ec075922085e9e8c89748e723d8ed3ef14c5ec6','1f86caeb82dff1d81112d960d9629af9ff5c241a45bfef25352fc3de8bc7aa7b','1d3c179fc6d71bc25cfd7b3159418094ab3d23d00d2ac6adc0b50b13e65a7fda');
INSERT INTO blocks VALUES(310394,'2a944743c3beb3bf1b530bd6a210682a0a0e9b0e6a9ff938d9be856236779a6f',310394000,NULL,NULL,'1c7a5456249c16eb3774923860024826fb9c2f781fc19acaaf413358c631d1fa','de5ac725e72caf9d7688518531ea967ac5cafe2621f57a9807c71426a2bcf89a','f596901aec89a1d2a714b91ae80a8ccb8b5e0712145938ca631eec2cbccb23ca');
INSERT INTO blocks VALUES(310395,'19eb891ce70b82db2f2745e1d60e0cf445363aaff4e96335f9014d92312d20e4',310395000,NULL,NULL,'05bc6cb26eb26f48a8ce1a8d32fed6b17f3d4de009607714f426774449019692','a03c4e5522772c64a4122a6d8d1d0d929afbfa45724a9dba8c9672fc359a52c4','a1b5144373d0a5be7d7c4121beeb1e5a214ddc7d079180d29db132721d0e6b8f');
INSERT INTO blocks VALUES(310396,'aea407729ac8d8e9221efd9d70106d14df6aaf9f2f87dc6f490835a9caadf08e',310396000,NULL,NULL,'266c2b8628061ee7081628137a3fd5858c5e29935c64ca1293adc13f00426dfa','c675df1032a8c3f273f065b27faa8ae458ae721b20d5a69ef48447657bffe720','f39b8d937307fea00f15530203365175f8f6ae1cb5239f254fa8b7f7aceeeab0');
INSERT INTO blocks VALUES(310397,'7c429e56a19e884a8a77a759b52334a4b79404081b976270114043ba94d7985c',310397000,NULL,NULL,'08d0a9d7471d1011301e8c4f7c865cf29d820d6e27cc111bd8223173abb7c16e','9732903b19bad7f7f21a8d4de7b052120b37523e18cb4a716eaf0e9628264410','97f52184f960ef2efe2f7b22395d2129465b2c4e27f02a2322de12e83af83c57');
INSERT INTO blocks VALUES(310398,'55c046db86dee1d63c0e46e6df79b5b77dfd4ab2ff5da79e6360ce77dd98335e',310398000,NULL,NULL,'4dc8dca962ad444beca1663cc549100b8e1354fa486450f011356712b8a4dc89','c72aeba4975a3f13e783b915b3fa0bc348cfffd64e77f659c78a2dfa26fb8e31','40daef8c5f7053802c1f82536434106303f073dd9c7bb4cbf6ea4909f6f43b2e');
INSERT INTO blocks VALUES(310399,'765abc449b3127d71ab971e0c2ae69c570284e0c5dacf4c3c07f2e4eca180e7a',310399000,NULL,NULL,'2567e22ec739e8c2e2c19592ad2f76237b2473ff74acab1fa8a5fe66a115b9aa','c1feaaf70a15ee7036164b669a59d2e85283e26f09131b1f509135aad26ac116','9b6467e131bbb8a7ee0a43afa3fcdcabea58d989278c0b3b4b2c48b92baf264e');
INSERT INTO blocks VALUES(310400,'925bc6f6f45fe2fb2d494e852aaf667d8623e5dae2e92fdffa80f15661f04218',310400000,NULL,NULL,'291be7d88b4b204ffdd405ec3d56723fac6be7939bdb43c72ee805cd0b1b6af1','f3a9295b9ad0fa5d83a90ec1452f9be35fa3bf7da5539d2080f8a37625acd781','a6d5418ac46cf689a402e5136280fa42036795a7876001d6fe80838dc7415e4e');
INSERT INTO blocks VALUES(310401,'f7b9af2e2cd16c478eed4a34021f2009944dbc9b757bf8fe4fc03f9d900e0351',310401000,NULL,NULL,'a0105009a7fb1d740b5390582a9002e2482ab3ead3605262280b1a1a1227242f','4755424c997b39622a98c50a1cc9b0a62ec3ca023c50019d8f93decb370a7a8a','e9567791d88558aadd683c7fa8319bbb9678b956d59193e36f773347073396c3');
INSERT INTO blocks VALUES(310402,'1404f1826cd93e1861dd92ca3f3b05c65e8578b88626577a3cbad1e771b96e44',310402000,NULL,NULL,'af7369adae73f4c2409b31eb89115140683a72ee002c7a429be374b49735146a','dca3fc0ec119d8f7186dffee71eb8ecd44d702ac8f34d469d00243e8bb891321','f905775134164656f6d01f65723201a092374ca399e28217daa1d9f8e225e4a9');
INSERT INTO blocks VALUES(310403,'f7426dbd4a0808148b5fc3eb66df4a8ad606c97888c175850f65099286c7581c',310403000,NULL,NULL,'3f2381b90a09ba7bae98f9d881b9b9955229a01faa94b53cde3aa51e39728134','ffc908f4a45bb6600155a2c86737a7c460b7089fc45b0afd7dd9f809681fcfea','6c2e022841ce36cbb4fcad37529602abf662d2181938c03ec400f42ddc831db4');
INSERT INTO blocks VALUES(310404,'401c327424b39a6d908f1a2f2202208a7893a5bedc2b9aff8e7eda0b64040040',310404000,NULL,NULL,'c52f5bf96a041a3ebf01697569f4d1b0686ad07d0860f46e98adca59fa10fcbd','4ab16349d078704fda01f75aff5ffead7a58156e32772e90c948012aaac6f66a','afa3d5e91d404961015b9150bb9217a6e93368fbb6ae946bd401e39cfae5bc8c');
INSERT INTO blocks VALUES(310405,'4f6928561724e0f6aab2fc40719f591823ca7e57e42d1589a943f8c55400430a',310405000,NULL,NULL,'47a36123ffd2eaa6205d6dbf80bf580c532aae086781924f18d7ecb2ce10d1fb','7e2821ec171757f1633d72e5c8b6d4d9bfd797a4b4fa48ed78e4d0be12423cd4','9cfa529af1ef18b1161192d8602d0b51c3a9bf21d25b69664c6679915d79f762');
INSERT INTO blocks VALUES(310406,'6784365c24e32a1dd59043f89283c7f4ac8ceb3ef75310414ded9903a9967b97',310406000,NULL,NULL,'4c3f345841accc0f723ae90b451a737dff5474e3658ae83429126d4976759292','e0a8e84cf6c4638b962beec2b4bf09ae6a5141ecaf42cc7109d789937400d05f','9d9f9c2955a3758104a848da006ac18031a26217190a090cb05cfe4ecedb1811');
INSERT INTO blocks VALUES(310407,'84396eb206e0ec366059d9e60aefdb381bca5082d58bffb3d2a7e7b6227fc01e',310407000,NULL,NULL,'b5773ee9de1c74b9bc11e34184b0b621c10fe379a6c9cf93aeace41501187c73','306262b95daecfa7dc75b24e427b9e9606ea18ec3912028a97f54bcb8e6072bf','346e6a2f496207e593ca16fca99ff2c10a5d07447345fe4326021a5c88457787');
INSERT INTO blocks VALUES(310408,'4827c178805e2abae5cb6625605623b3260622b364b7b6be455060deaaec2cda',310408000,NULL,NULL,'d1bc602174aef907eef01cc1510bfaa688703c4bfe0c235dc877718a7668e605','d0a28dca619c29c48872dc9450410e9d8b902306b508a812e560dfac4a0d4f42','5c67284bfd41e57cb531b9570dc81cd644e05a411bf99679c71fe996e51303df');
INSERT INTO blocks VALUES(310409,'01a719656ad1140e975b2bdc8eebb1e7395905fd814b30690ab0a7abd4f76bba',310409000,NULL,NULL,'b9aceb2b5e8c1fcaee6522688b67285c6e44f3308b5b0f2f61e254d997b92969','01fc355a0a67d73210320a730d6f0c4020463e6d0d971b67ad6db51a83dda483','0130d00354d01618c3845cf446f542b981dfd7d3c34b11f2dfebe3ab50c9d91a');
INSERT INTO blocks VALUES(310410,'247a0070ac1ab6a3bd3ec5e73f802d9fbdcfa7ee562eaeeb21193f487ec4d348',310410000,NULL,NULL,'eb292a3f803d3a9852adf9cadb48c1d8bb93cab02712df582d913d2081e1789f','4cde7d05ce21be7979aaf6b3bb87ccf63c53350606c98aac993da728754f2e6e','653fd8755ba4d53c98238ced634eabeabe56183364a99fcdef9f4d46171c1d3d');
INSERT INTO blocks VALUES(310411,'26cae3289bb171773e9e876faa3e45f0ccc992380bb4d00c3a01d087ef537ae2',310411000,NULL,NULL,'ee7aef26e5f59294bb5f316ef84d3852c6f404a7bd4868b2844b0766e415ca93','e156e6cf884c8a810d836f392cca5bed9a9b56dcc8fbc4ee258712be65b5833e','9a468fe0e0844f9696ca46e70c1db5c6cf5767f3ba699e1218fb1b34d0957556');
INSERT INTO blocks VALUES(310412,'ab84ad5a3df5cfdce9f90b8d251eb6f68b55e6976a980de6de5bcda148b0cd20',310412000,NULL,NULL,'057216567e37b67b3643c71b21a3c2049eab3abc170b9a2de31fc16fe335b315','e37406f3dd076e5f9ba86111ec8865490749a3bb3b2a534716604db28f1e5eb7','3a126d85ffc4949bc2763be8449e6c8228d906fdb93a7c6bf0fa0105deb4a934');
INSERT INTO blocks VALUES(310413,'21c33c9fd432343b549f0036c3620754565c3ad99f19f91f4e42344f10ec79bf',310413000,NULL,NULL,'79164a2c361d4af702ecb781fc4becac813390a2a1491660fad3aa5e756263bb','0cca5ee1da2e7150b3b40af177757fea1651aee39733d0dfd0694d4121776a53','44899237d1054720bfae60537b3b85217ade17083978e488e0a55b42c8d732d3');
INSERT INTO blocks VALUES(310414,'8cff03c07fd2a899c3bcf6ac93e05840e00de3133da14a413e9807304db854b6',310414000,NULL,NULL,'f6f28c655ddb89b51dae9b378cdce2945312a6bb63d91d642c068d6e7d40ae2a','5daf152f6bc8ffd2e5a5e58b790e65c0cf86e11583eb4639f7eb61c8b50201f8','ef707953302aae34d3c8467ff427722e87b333a323ca6d38be082fe4dfe7a2f7');
INSERT INTO blocks VALUES(310415,'dd0facbd37cca09870f6054d95710d5d97528ed3d1faf2557914b61a1fc9c1cc',310415000,NULL,NULL,'912308109aa37d7cf92ff7efae0a8153bb75681400b492e756979b32cd745087','3f90310bb3dae1af843718c4052caff68ecf2538b0df41d3b4eeab6d47d7d785','3cfaee47ae4516d8fe998714b49c699603a32f85abfe59a768134f9d1c2bb65d');
INSERT INTO blocks VALUES(310416,'7302158055327843ded75203f7cf9320c8719b9d1a044207d2a97f09791a5b6b',310416000,NULL,NULL,'73cffd1886dbece54c1b58decb2d33c16897e84ab3b9cb2223b39f48f4148a7e','4d0428931187ae9286ad4f86ea1cc1223c618cbbc7c65f0b738693ac27f34654','37b5c518a014da8bffa500bbe740f19fe6f83201b6b5148fc5f741080a91df52');
INSERT INTO blocks VALUES(310417,'2fef6d72654cbd4ea08e0989c18c32f2fe22de70a4c2d863c1778086b0449002',310417000,NULL,NULL,'467e4cedfcac0dc640bb1b71195d01af3077da0607f220ca2fd9ba926f1a9098','8a7a2a912a4bbc5227ab6b0ff890c4098a50c827f7300951406960a064f6dd5d','5987966956136076e22489e02525e6cc5fb226bd9fa92ff87fe2049e9f5fa05b');
INSERT INTO blocks VALUES(310418,'fc27f87607fd57cb02ce54d83cec184cf7d196738f52a8eb9c91b1ea7d071509',310418000,NULL,NULL,'ba22c06b1726a326a13436530136cefce880d7efd0cd13c549d04870534a2999','f715adb42392f3f5fee2aa6b37e935034a6cf155557912c8dd9ebf4e1fd2f998','ec1d853bc8e4334aac727326c0eb378886399988bb9cf9bb6f9d7ef354fccff0');
INSERT INTO blocks VALUES(310419,'9df404f5ce813fe6eb0541203c108bc7a0a2bac341a69d607c6641c140e21c8e',310419000,NULL,NULL,'f26458b93099c794d556517c13917b3ead28a3715ce00db3758a62abfddf2bd2','ccf1b40fa4af031d1fe333bba36c2ecd79cd7a230f10d58a727f2b8956414110','6abde6306f639c97182c867bbf248cbe7c83d8d4c0cb2be81ac8b3406058d8fa');
INSERT INTO blocks VALUES(310420,'138b3f1773159c0dd265a2d32dd2141202d174c2e52a4aeac3588224a3558372',310420000,NULL,NULL,'53f47f4514b597496269768af66ac2314efbb9ae998b2bf75b818bc96c7e9d32','08e2961784a1efd095bc5c2c5403a3ce787456176cfab2840830c30f45c96cdd','107fe412bed86be1c3d9fff90b8436cfe90b9df0472f4eaa414be1ac8626e2e7');
INSERT INTO blocks VALUES(310421,'71fe2b0e02c5cad8588636016483ddd97a4ef0737283b5fd4ab6ea5dc5c56b9a',310421000,NULL,NULL,'9868f2c24308d204025e164d010a5991e3916a18becc2db459eba50c4823efca','6fe1c2c9a5cfc01c26fd86c484eb2d2e19e0db837f9ad414b3d094201872ebfb','1c49f377dc5d94a115fe148c18fff96c1f9f3d673c35ff121f392fd86159f147');
INSERT INTO blocks VALUES(310422,'cd40260541b9ed20abaac53b8f601d01cd972c34f28d91718854f1f3a4026158',310422000,NULL,NULL,'19b9d47cbb24d230ded417d4c5888c2adf446d4582ac9702ecba9ddd82cc8447','7e8ed00bdc50dad236299708618f7d83288a35f2f6e4d224589c0699a42046a1','f9d248dcdc91a79696f4a8a817614e5e153ca4a0ba996f6040351fa711e82489');
INSERT INTO blocks VALUES(310423,'6ca0d6d246108b2df3de62a4dd454ff940e1945f194ba72566089f98ad72f4db',310423000,NULL,NULL,'32b5f7b5c089d78fadf01db543df7ee86be5f81fbfc1d3764e37901ddbf6b10d','9ff89e6c12aec8d7c87901fadcc1cfc00941792e068b0f45a9ce1ed75da67d9b','b7ae2a8343b1b9754f3f7de3bf1a8d8a9cac760e31e60b526988acc0bb889bb1');
INSERT INTO blocks VALUES(310424,'ed42fe6896e4ba9ded6ea352a1e7e02f3d786bfc9379780daba4e7aa049668ad',310424000,NULL,NULL,'f264db27edb8d279a06a00532dc0eee91cefd18e51dd529f695dbf45c47a393d','0bb0a71bd3d42a8517b1717f4958cedf8fa596624270bdd82e5bacdf2a667ecc','bbd55e981cb319242e747c44dcf14b87cba9d371667c3f9b114cf3c04b2cf5a0');
INSERT INTO blocks VALUES(310425,'73f4be91e41a2ccd1c4d836a5cea28aea906ac9ede7773d9cd51dff5936f1ba7',310425000,NULL,NULL,'b9d0bf7499069b1d5f0fc41dc2c9a87ed8d409f20953997e0afa5ebf813da666','dd84a6ac52937544b9f8dd26225edf50c3ac139b9ae5573c8ab7571f91720c7b','462e605b5ba4b1a698c1144d5afae3c1d488d72d9875afef1c00728dcc1b6609');
INSERT INTO blocks VALUES(310426,'9d28065325bb70b8e272f6bee3bc2cd5ea4ea4d36e293075096e204cb53dc415',310426000,NULL,NULL,'4217d05a98dd85e970fa23bb8fb1c584de5ec0b03141ce016e37403215c94e34','c00dbd97d0e7a988445f47963943fe85a9f802fa82b68d6d4a5d6d59abed17c9','95442cc75a11ab873b44fcfa411453625ec30a3fd3842a048a3fa8b7b5ea1e2a');
INSERT INTO blocks VALUES(310427,'d08e8bc7035bbf08ec91bf42839eccb3d7e489d68f85a0be426f95709a976a2a',310427000,NULL,NULL,'04952d709a35078dee7f26e45a0c8210dbccc7febc897060d63cd83e338e4b00','219b2cb81cd84232feca0a691cc86d8002c5b6ec5be753acf9e12cdf439e0efc','08656cd1dfea382bd2c755cee7dae0a158533fff5916675b03701cc98764e358');
INSERT INTO blocks VALUES(310428,'2eef4e1784ee12bcb13628f2c0dc7c008db6aaf55930d5de09513425f55658a2',310428000,NULL,NULL,'d8c5be42a09469c84c43b9c2f68ffbfd18bf645d5b8719522c54b1058464af8d','3c00ac87bde43658e82d2b710b2c23be42545f6a5be71e8059d0ab6993428a75','c9e2fd326dbf0ec5d43921f56c7c1a995744544c6fa7db053e4b076c853bac92');
INSERT INTO blocks VALUES(310429,'086bfbba799c6d66a39d90a810b8dd6753f2904a48e2c01590845adda214cf8d',310429000,NULL,NULL,'17793c83238e5b568e77e34a893150910ae6bcc8d72ccea5cd9654c80619bcc4','a1cf8f586494c0b23173cd6698222e24bb7008ade23690213f7367a9514b9e5b','0e5c4eb9947899d3a11480230c8fa3b889b6e12484c56007447689651dfed49d');
INSERT INTO blocks VALUES(310430,'870cf1829f84d1f29c231190205fe2e961738240fc16477c7de24da037763048',310430000,NULL,NULL,'53a55e5ceb0189aa074c15c8228d2be814cbf2735c6d141a982f7951f204e27a','e8be435d0e62389cbaf232f7725453a3f13505407d3942685b79f6b9672b2376','e44461078242483882c0a7a30db40b0e4d6eac15b1a6e4804c8eb982200e7d55');
INSERT INTO blocks VALUES(310431,'20b72324e40ffc43a49569b560d6245c679e638b9d20404fc1e3386992d63648',310431000,NULL,NULL,'b4a99fdf94fac7ce16d5c8fd93ab9a101fcea759ae1ac53813d71854fa925a3d','9d1ad7843721e14626624db9cc55718c419f6c83cb0ead2ba4ebd1d1fd98268b','5a00fc3a02b2751e3306cd0f69cfa76777091260c68e031a6ba2082a94331096');
INSERT INTO blocks VALUES(310432,'c81811aca423aa2ccb3fd717b54a24a990611365c360667687dc723e9208ad93',310432000,NULL,NULL,'c9a284383445510ca12a325e0ac4a513f74838e1ea80b6b26c8ccff8522fa3e3','9751e10ea08828552a9358199f9b3d20a90d0dc67261a09f06247175cd922259','a8b95ff0676713dfdcf3415c3ea94ab5d55a3a8d8e998d8e6669539c0c8f68d4');
INSERT INTO blocks VALUES(310433,'997e4a145d638ad3dcdb2865f8b8fd95242cbc4a4359407791f421f129b1d725',310433000,NULL,NULL,'86b55728ff2cc62bb265040cf7701ac1e24a20ff4ef81033f7583a6b44e8d446','42adcf84923cb5a078e6a17e0dea92a6fe52b405e5a38beb6b90c078680743f6','f16bbb496e847c737ada50bcf823b3e98fe3c5ab179ede700624e88bcdc8ceac');
INSERT INTO blocks VALUES(310434,'61df9508e53a7fe477f063e0ff7e86fbb0aef80ff2ddedc556236a38f49ac4d8',310434000,NULL,NULL,'094dc0625207e131b7e85ddd5f63b7fc4eaae1438a5b8c0f6e27858deaa56718','f2a20e22a5dc9dfc3efacd8c696b3fcb9dfe8802e149068a86fb2dba43dd906e','d510f5c3c2ffb128fe30dde64d2703f330a2d7568e6ed7b4694df65cfa37fe36');
INSERT INTO blocks VALUES(310435,'f24cf5e1296952a47556ac80a455a2c45da5c0dc2b388b51d235a3f741793d5f',310435000,NULL,NULL,'a1fc4db061f4a5e165466838808a1facee777d84dc9204694c609dfc00858797','7658b2faabe5c394c302e452e99ef2efe1addc91e4931754f124cb531816863b','da84b017c1c1e191f2d9f79eed69163647b572c4fb08a72e061cc76440adf004');
INSERT INTO blocks VALUES(310436,'a5e341ba92bdf9b3938691cd3aab87731eba5428bb61a804cecf9178c8da0c19',310436000,NULL,NULL,'2b179f51cd68988716e9341732f651e560c94342f371b1d9d9ce34961a2a3cad','09ba9f7a3f0dce7b160267a0cbc71a8b9cc700041fb97127e9363e56ed7f69fd','db345cebf0d19fc1d4ed993dfa405a149f59557c7df0b47852683f7c97ea415f');
INSERT INTO blocks VALUES(310437,'9e18d0ffff2cb464c664cefc76e32d35752c9e639045542a73746f5ec2f3b002',310437000,NULL,NULL,'40c923108f4c2ad42ab70e1da02c273bc3670b2028ab7f52644ce3882dc69a9b','a852b9f10dfa360a21f053646a13fa8d098bbb5757c174dbc57405e3a28edc8c','737cb14fc180cd3e6074d3acf079baa8c5c1e18f440e41975b68abec8788905d');
INSERT INTO blocks VALUES(310438,'36be4b3470275ff5e23ed4be8f380d6e034eb827ebe9143218d6e4689ea5a9fc',310438000,NULL,NULL,'2b00f1204f33edafdebc657b19bcc48148b6cdeeaff57f30858fe91330e7891a','6931ce8bebcff59a294688c0de55c1b1f9f1ba894c149c2994defed30c7ca005','a463fbc404e72cd8b1318c3acc19c4a32eac980d133d390598136f93336bc3fe');
INSERT INTO blocks VALUES(310439,'4f2449fce22be0edb4d2aefac6f35ce5a47b871623d07c2a8c166363112b2877',310439000,NULL,NULL,'80d559cca2469f07af74da39688dd60651f96e7460c6b64fe2e3a482c3724cc1','8b0bed0675118026129cdf7925f6c0a0587dfe642d916e737cb64ff02255d83d','5dedcef2b7a20d48fe61b268fc8decc62cf3b6fe90469b0ea3f0690c0eb3dc93');
INSERT INTO blocks VALUES(310440,'89d6bd4cdac1cae08c704490406c41fbc5e1efa6c2d7f161e9175149175ef12a',310440000,NULL,NULL,'47f9bc1e0a259a2988fb29f56fc44b5819263c7976da5b110899fabe8f1529eb','731171881ca5e63887adf5550deacf76af3ff4b2bbf5ed505d5464718015f40b','f128cc57a188b9d1de1ba078290eb681e7d20220e0dcd5e4391627b3ef249c8b');
INSERT INTO blocks VALUES(310441,'2df1dc53d6481a1ce3a6fee51ad4adcce95f702606fee7c43feda4965cf9ee15',310441000,NULL,NULL,'a74840929cfddc49ae74fb95904a7d969fdff7e2240c030dfa22bc88068874dd','57a1e2be65e1cc0b2a60b53ab28497ba7d7b48ef66a21149be916655dda42b36','a7665bd751af3ddb1e4128835ec2b122df36b77e6b24e7d05d1b423427bdad04');
INSERT INTO blocks VALUES(310442,'50844c48722edb7681c5d0095c524113415106691e71db34acc44dbc6462bfec',310442000,NULL,NULL,'aeca0d056c42da2efb049f894d5a9c6900e3705b1ad942094ba9c8a3f87cdd99','60aa0e6e60790a9998e6bd588cc13e22a0486fb5922c9022825ad278e133efe2','ff4bacedec68ce5e81dff5e073183d2351047173db23fca6f7d8d76c8cd1a5b4');
INSERT INTO blocks VALUES(310443,'edc940455632270b7deda409a3489b19b147be89c4d8f434c284e326b749c79a',310443000,NULL,NULL,'845368b4da60c29e53cb11d5c030bb24c1f08f77776193897670179f82901e98','215a435a456f0920e93fe1a8a376b8ed55166a2542971923ad984cfe87ebc5f8','86053fcc08fc53329ff18341af412505ebb5258d26e55508e075d4d0dc5f3686');
INSERT INTO blocks VALUES(310444,'68c9efab28e78e0ef8d316239612f918408ce66be09e8c03428049a6ee3d32e4',310444000,NULL,NULL,'e0d918728b0de8a75140e45da9a678b164204dcd7d918b988707d94f5c1dd151','e3041664f0b8693744bce0731bf7c6f5f32c8f1649bb218199eb1076c89def6b','4f395244f540bd142167bbe810b06fbd2ab170fb3fadcd93f8a436440d30f77d');
INSERT INTO blocks VALUES(310445,'22a2e3896f1c56aefb2d27032a234ea38d93edf2b6331e72e7b4e3952f0234ef',310445000,NULL,NULL,'eaecded6196fcd6669c0728f497e6099189a1e93c4ff777f2e97c4cc2af8af8c','5fe60e1d78b1765dec0366505e56f0ceb7de2ba74c077ab1373abfbdf42314d7','e15d332fce396556962639baca683e4543b3f05598a360888e09b70c75882d18');
INSERT INTO blocks VALUES(310446,'e8b0856eff3efce5f5114d6378a4e5c9e69e972825bc55cc00c26954cd1c8837',310446000,NULL,NULL,'1e5b6d1e80afdee85780f99caf956e636a5c1b13b092bb2dcc3aee3550276f7d','a1d89dedb85c97a80923b6069068f70a7d621bf3983daa1badbea366a03691be','50361a3b682b4f72dc9d0da124c201825fcc47f472829ceb8a67cd32ecce9eee');
INSERT INTO blocks VALUES(310447,'3f4bc894c0bc04ee24ed1e34849af9f719f55df50c8bc36dc059ec5fa0e1c8a8',310447000,NULL,NULL,'aeeba0674cd2708e3e2356f6cea65c25311f91f51eb74497d777867a67fceb41','8688de924ab21d3977ffd6d96de5d42e8ee5c1bc1f0de147eb5d70f227e17911','fb343defd962fa86672fd235fc290b3a28dd61e6ee81b7beaf05dc7942ae33da');
INSERT INTO blocks VALUES(310448,'6a6c7c07ba5b579abd81a7e888bd36fc0e02a2bcfb69dbfa061b1b64bfa1bd10',310448000,NULL,NULL,'0f3b562766d70bdb856e3922341bbf8a9145ce8c735c48ab0277a3bdceac4af3','8b4675d6b40e5534c81310e73cc96d4afc90ca9766c63de8e24a016a7343e3d8','db91cdc4e32ccea9d9769c0a17c7fc83b6aec8e9bf24f6f03a3adf9b7272e3de');
INSERT INTO blocks VALUES(310449,'9e256a436ff8dae9ff77ed4cac4c3bfbbf026681548265a1b62c771d9d8e0779',310449000,NULL,NULL,'0fba0e8bc0e960e574c0c145c7d84333f587cc325a6d00762522fb2632c8f4db','0b76d34f009bdc677797abd1260aac0af016331db2a519c119108706deacabd7','7a8ceca159969a72258b662670f8e2639fbd3cfce071126030b170de52813f8d');
INSERT INTO blocks VALUES(310450,'2d9b2ccc3ad3a32910295d7f7f0d0e671b074494adc373fc49aa874d575e36a3',310450000,NULL,NULL,'210e7518c6af38dfdecc6145aa49027052b642139f2061cc0dd588496794162b','b90ccfef1131775973af8006c3bba68490371eabaf85ac8d77cf93c37eced058','d0bb8e230df28c225007e8cc02b4ccd046f45d62f63d93736c0e96bbe8751987');
INSERT INTO blocks VALUES(310451,'55731a82b9b28b1aa82445a9e351c9df3a58420f1c2f6b1c9db1874483277296',310451000,NULL,NULL,'36c0f7b7a37f43f854746b85542ce336b456770d52c7de4da34136d571142ca6','64fd2c609ff9f83550738d4e3202177432a17382c4ef59fba2bdbbef3e95843f','b87b6b3bfc27066ab3518073547b6a46fa5740c0e0d6d5d17946a6032f81001d');
INSERT INTO blocks VALUES(310452,'016abbaa1163348d8b6bc497cc487880d469f9300374a72ecb793a03d64572aa',310452000,NULL,NULL,'8bcc41ab66349796286d7fc3ce711e21a3fc41447bdf35f7999121b57ee2b7e8','c4e477c6fa675103e219f04103ec792aab21f541ef4122bf7efeff560b80c3c1','01d17918dc3055fa9fea9d63210fefc6a314df35495f2da24a9e19b173eeed0b');
INSERT INTO blocks VALUES(310453,'610be2f49623d3fe8c86eacf3620347ed1dc53194bf01e77393b83541ba5d776',310453000,NULL,NULL,'41ffc315b37bb126e4e3c406f74273507d1de9ca2dc17e343c2520604addd4c1','d24460986ce18e9b010bf23f722780260c8b014799728506fc67a1bbf100fc48','73bb3e63ae4725e09545f08b4dcf7d55c55abbe43ae51a1e110cf3459234698d');
INSERT INTO blocks VALUES(310454,'baea6ad71f16d05b37bb30ca881c73bc48fd931f4bf3ac908a28d7681e976ee9',310454000,NULL,NULL,'a095b949a722270f1a16fa581648b78d798aa06f8bd067de49b837312fe097cd','5a8060662293862cce81e8345323892e564354d5acac92dbf50f37b4c938fe72','ebf9443710587a3bf7aa3baad7cc89bf834d4f039af215eb56dfb83c3d11e59d');
INSERT INTO blocks VALUES(310455,'31a375541362b0037245816d50628b0428a28255ff6eddd3dd92ef0262a0a744',310455000,NULL,NULL,'a5126463cb7cdc481b74ac766728ed9091dca126f2f7eaf88a76dc76457ebe27','da300ea926a12d12cc44e90c09e88bc868948c9103e01a6ed7fef8841590bccc','ce6a96250090811c537ed0c6b0ae5782d433a230a241c1d68e53b34ab3a02245');
INSERT INTO blocks VALUES(310456,'5fee45c5019669a46a049142c0c4b6cf382e06127211e822f5f6f7320b6b50fa',310456000,NULL,NULL,'78b3172922072acd9f4c550ff0e7edef0309fc3d1b34de92e38143756a441cb3','fc14bd555697033837603271815ed8f9ad0bfcbe4e48cafa5e275bf60bc33a33','c0bde32e153d3a48fdef383d7395fb9cb00792c53288829d33673327f171a2c6');
INSERT INTO blocks VALUES(310457,'9ce5a2673739be824552754ce60fd5098cf954729bb18be1078395f0c437cce9',310457000,NULL,NULL,'edbf3c914b1375401c7983656bd6ba233dcf608caf1749968b694944c7d78186','50bbb876a28a06433b0ff95e75fe922437e270c6a2e4328c7081effca9ae4dd4','daedf2fc43be20550571c93969fd2ba1be340f6b31c6aa5c354e64c2c4ff963b');
INSERT INTO blocks VALUES(310458,'deca40ba154ebc8c6268668b69a447e35ad292db4504d196e8a91abdc5312aac',310458000,NULL,NULL,'2a3e7f367c918dbdc88473dc033fd120e91a725a14a9ab954da3e89363b1ef8c','e68bb43cc112fd8735960c23b9b64de7aed680b01064440e545ea963a3d4c672','6bfc781c9290f8971e1650171b6d25b7863eb5fe2029b6576bcf3efdb73e9dcd');
INSERT INTO blocks VALUES(310459,'839c15fa5eea10c91851e160a73a6a8ee273a31ab5385fe5bd71920cbc08b565',310459000,NULL,NULL,'d4ba61a1c3c10cd9624ef8a19443f107ca8e509340aecaaf878155b5828379ea','3cf02e116665225412ca78bebc50f6b063f0ce19930407321623b029ae380b80','0433f5d340a3e3a26c74ecf1df0ae7aff2156f15675698602d0fee50c28f2e64');
INSERT INTO blocks VALUES(310460,'9b5f351a5c85aaaa737b6a55f20ebf04cafdf36013cdee73c4aaac376ad4562b',310460000,NULL,NULL,'6cd93ea7c06779479a6787b10b5545da35f2d3db5ee1d0bc4a24e4d185680ba5','71f3693b89432d61e3e95ae00d34a149f6f76f795dd42ab1e3d30f9e6753dfa3','8749fcdf7cbeba16af2896048010f52417e470a3abc6d244c1cdd737f547a345');
INSERT INTO blocks VALUES(310461,'8131c823f11c22066362517f8c80d93bfc4c3b0a12890bdd51a0e5a043d26b7b',310461000,NULL,NULL,'52855573f3bc904473f46638364cdcf5ec389b8d8b0e91cd98e2de1b9c620b12','d7b62ca88045a3c855c4481d65b14658d12431dbce4381ccd79f74a03cd41ea2','4ae1c7fd0e31f5bb82a416e49ef27781274bcb38a0e1d62e18f7e433642ed429');
INSERT INTO blocks VALUES(310462,'16f8fad8c21560b9d7f88c3b22293192c24f5264c964d2de303a0c742c27d146',310462000,NULL,NULL,'ece53c5afc99252beed86cb9271abd1e00e8f490b75914c61929d285b1302082','7fccaa9f913697bdc64ffb22a48007aff91cc196392a3c4660ae311a2edccc05','6fc36d591e84ede78a88c514706b9fd4eabbdcdabb4662f16a5ce03bd3635f62');
INSERT INTO blocks VALUES(310463,'bf919937d8d1b5d5f421b9f59e5893ecb9e77861c6ab6ffe6d2722f52483bd94',310463000,NULL,NULL,'e0816cb9fc14de7844ed169e13c2013c243f2e5b96c3bad811a74fa8f2dcc73d','37d4f2316c1f2e5d7cc79f3ef91890245dc23a10d962d1ab128adbf259208541','900aebc84df96dc9ca48bb6d685d42e955b339f04c9580eac715c6e6ecfe5aa5');
INSERT INTO blocks VALUES(310464,'91f08dec994751a6057753945249e9c11964b98b654704e585d9239462bc6f60',310464000,NULL,NULL,'5b05e1d946966ae552b11cebd7d8baf081e1ce32210bd8b2082706a633ea2e67','b7a7f51fac4bd316ced2fad0731b3eab499ab7007c741a3548fa99f78b265b13','30aafd36fe35bf2a1b1d6f417b5511f1407a6c4ab44ff9210214c7762a8d21da');
INSERT INTO blocks VALUES(310465,'5686aaff2718a688b9a69411e237912869699f756c3eb7bf7c3cf2b9e3756b3d',310465000,NULL,NULL,'8619f76403307075417ef00c6e42c9b025e3f43b5816b35e6d7976b30091b005','aa4dbb8e24366e7af96ac216b6dfcaaca061c7604c7651077833d303d3d94741','99c735016c7b3d94ffc08bb06b1168d37827fc594e0097b02174349bcb546038');
INSERT INTO blocks VALUES(310466,'8a68637850c014116da671bb544fb5deddda7682223055a58bdcf7b2e79501fc',310466000,NULL,NULL,'a3b47eeb0d1c64e6fd53a19218f4a585732aa243216a5ea709496688320aa75a','42f710ea9df16f7c1b69ff7b723999bd2438f44f740e03cf1046f05c7a8e193a','396c8efa37be24484a1b527d8b6d1b2500b79328c423bba6a02dc39fce4673cb');
INSERT INTO blocks VALUES(310467,'d455a803e714bb6bd9e582edc34e624e7e3d80ee6c7b42f7207d763fff5c2bd3',310467000,NULL,NULL,'82c58a8a8ee9ae0c2fc6126f317224b4bfec0407f6b69b897231ae5cc4586eed','0cf2972363f169e3d9c2f86ee9ef53119aebbd2ca464e43adea7dee63c888034','aa915a7aebefef342e40730949deb2aa528f4534053ad7e37f45b7233f91e258');
INSERT INTO blocks VALUES(310468,'d84dfd2fcf6d8005aeeac01e03b287af788c81955612375510e37a4ab5766891',310468000,NULL,NULL,'b7780744100c38d47449746d3969801d027c574f8d3a610910fa260b2464f3e9','4ba8d57302b44e69e0ac35458f2cf18c62949a68f9e9cb0cc605ed9587a18854','c989a6941af17a80ffd4ee74e9f973ccd461d5b01a6eee7508e25b368aaa207c');
INSERT INTO blocks VALUES(310469,'2fbbf2724f537d539b675acb6a479e530c7aac5f93b4045f4356ea4b0f8a8755',310469000,NULL,NULL,'903a48d73b33e16df940f5f3bbcb051f0fa7fca50a9fdbc84fbeaaa538a69f18','e6a16abe1393263223b7bc46bab475c756eddec7a290b60d72422920e307e184','f8ebd30033d8c19209797d7cd830e1f6ec145f77c2f5c9b5bf85067ab0d6a4b0');
INSERT INTO blocks VALUES(310470,'ebb7c8e3fbe0b123a456d753b85b8c123ca3b315da14a00379ebd34784b28921',310470000,NULL,NULL,'d4b7cfd47924fae5118ab3f346be66d49ac5a077cb64c665078ea348745a18f4','9cc5e3fb8758bdc64c3e476b3008ebc5ea7a004f71b96165b7a5039fca9c8b92','280b5e743361c865d190ba279cb03866e7e54a8f395d33efbcfe930a24b53e46');
INSERT INTO blocks VALUES(310471,'fc6f8162c55ecffeaabb09f70f071fd0cb7a9ef1bccaafaf27fe9a936defb739',310471000,NULL,NULL,'cdcdac73dbc9eef131b7583b0d412eeacd3dc1f4984e9a22633cc876c5a5debd','1ff4f10c3cae91194f904aa2b9a30832918dc391c1749622ca837c496b8beb72','04335ace3c6265724caba80b13555ef7f6524e830f4807138cb2c1a62eea40c7');
INSERT INTO blocks VALUES(310472,'57ee5dec5e95b3d9c65a21c407294a32ed538658a6910b16124f18020f16bdf7',310472000,NULL,NULL,'9df3773d9f2b06f41c30123ec87e1516ca6e4652c1ae380bc9a9b49cd92ca19c','585a96ab202e67c517a5abd91dfd5fabc8cd8c57d20eec7b88a2e5bc61f2b918','4437a7ad56c3c499bd98ea0b71410bccd9422b938ae575d37ca3245fd6c71518');
INSERT INTO blocks VALUES(310473,'33994c8f6d06134f886b47e14cb4b5af8fc0fd66e6bd60b3a71986622483e095',310473000,NULL,NULL,'12b9dae89f3cc6c714135698bdf4e4518967a3438f31fc7e01bb7e2778763ac3','0009ece736cf259d4df476ed30ba51b5ca25d58c0b4e48771078a8e0aaf92dcb','2695844180028e49dc5387a9d8369d0eb0f6f259331049bbebdfee09f85fe88f');
INSERT INTO blocks VALUES(310474,'312ee99e9526e9c240d76e3c3d1fe4c0a21f58156a15f2789605b3e7f7794a09',310474000,NULL,NULL,'36c816730823a86edb9a67f8916bd7436bd50787a4eb941134e570a304d9cb81','951b2405746bb49754f75b6884614f34f8f82baec09852425afc12706f775759','9c4c2d86a0f700f01ab1828ad86ba36160311914b0c6c9efc027a512df9ff4e1');
INSERT INTO blocks VALUES(310475,'bb9289bcd79075962117aef1161b333dbc403efebd593d93fc315146a2f040eb',310475000,NULL,NULL,'7a08adc49c7aff8e86965518b8e8a31964c912131d9b3cabba224ea43ce20b16','55bb251e66cf206b56a3f1e71333895ce0620ea8646d71480d60a87ef9dd3249','06e7d489f83e9f1c1db69dca5e70b16ea73c6d731d0f66bd219218562215b017');
INSERT INTO blocks VALUES(310476,'3712e1ebd195749e0dc92f32f7f451dd76f499bf16d709462309ce358a9370d0',310476000,NULL,NULL,'2d608210df09b70d6f845ba2ed99a48c041b4038ad519e7cada03bca90be11df','badb2f40b94bfa02fed5caddd1cb5a29179f827dbc945ea4c6c4e65439da353d','56d34f5049d410e4d7f9823589a879a6036a9c737fefd3839c1829c0610771d7');
INSERT INTO blocks VALUES(310477,'7381973c554ac2bbdc849e8ea8c4a0ecbb46e7967d322446d0d83c3f9deab918',310477000,NULL,NULL,'6988e1c558eab63b16de834f5838264ebd1065ba768cb41c9eac4618fed7e28d','a3b289e2f9d07785f39f76b7dff51085883daabdb29d0bb821305d7afb65e853','8debec47f32479e59684b97ed99d5e1fe2663d1e85175b606c7917efd3ae9532');
INSERT INTO blocks VALUES(310478,'c09ee871af7f2a611d43e6130aed171e301c23c5d1a29d183d40bf15898b4fa0',310478000,NULL,NULL,'5435f60ba80dd08018d8634353590babc60cf45c29c9f533858cc6b92dd5e2f2','97fe6ad1943162cbd3436291534c97d74f393ade53998b0f4696b306adfcdd5e','1cf2dfc03c387f8cc2e5bdcada6ebbeecb9d9c58275e0620aed907c1bc656e14');
INSERT INTO blocks VALUES(310479,'f3d691ce35f62df56d142160b6e2cdcba19d4995c01f802da6ce30bfe8d30030',310479000,NULL,NULL,'fbe6f79c90aced135ccc9056e316a76622b0643bf5447cee84bc0fff9c82a2d4','fc1035c43a59a01c0ed4850e8e7e1b8355de67052e346d54c43cd0175c2baba7','5b34471d2555c0339f5d99d61870eb495b694597adceeacb36ecb8107bd17a62');
INSERT INTO blocks VALUES(310480,'2694e89a62b3abd03a38dfd318c05eb5871f1be00a6e1bf06826fd54d142e681',310480000,NULL,NULL,'ea770919fc30bdbff527c8e12f4b4c51d7bced69e81e0aea801645c1e586678b','dcfc3781c7b68fe370f3f63f8158c0fdca0e0b0fb18ce6f6c64b95a9aed9a7bb','25ab7a5dd7364b3798eae34adf6b877cf99ff79e2b9d8ff151c903f811402ded');
INSERT INTO blocks VALUES(310481,'db37d8f98630ebc61767736ae2c523e4e930095bf54259c01de4d36fd60b6f4a',310481000,NULL,NULL,'86614d79c35709f9a166eae9cf610a6a9f2f9c39b8bd8bc2bb419977b3abad53','1c5b0bc607edd92328420227ece16e5e2cba29b0cab4e1c10999ee525a8eed85','7129981d5c28874f45fd0a88d054aac0087d8c2b19b20a2d25af864624f05847');
INSERT INTO blocks VALUES(310482,'2e27db87dfb6439c006637734e876cc662d1ca74c717756f90f0e535df0787d6',310482000,NULL,NULL,'e2e6a0029a01a1487b76a2bcb9fb59aa8f4d445b64fb329dff3be731ada3e547','af2fc44ca616c0302c164218252df885c216fd3614a1991ac2e8a1ef48aea0a6','6540a0649849867cf60ec76ce89a303c670c9eb393c2afbd30a7b4f9db12563c');
INSERT INTO blocks VALUES(310483,'013bac61f8e33c8d8d0f60f5e6a4ec3de9b16696703dea9802f64a258601c460',310483000,NULL,NULL,'1da64dfe3bd7696e8a3f194c8a7efa26479ebd092b8a7c50c93f78dcacd61412','5b3673071b1d7d312e44c07d2f3eecb41936b10e66e1e33db18a5bd2c1c5b6a5','99d03d204cd0a813f7b1e8111873bce0b0a88e5afd2fa28d48c5a1d1453f8ec8');
INSERT INTO blocks VALUES(310484,'7cac2b3630c31b592fa0497792bed58d3c41120c009471c348b16b5578b3aa2b',310484000,NULL,NULL,'4bc5ae3209a1b836f4ebacf043b08480854226debfdf7c5d51d38478f06ee5a8','d3fc3618a827898b2af9d4c8bf223ad9ce484b4f5400ac3adadfc44d11d3305d','a327e6141826d5fcf361dad36ab6bcb0aeb07a197cf6fa401fe088956f4521b9');
INSERT INTO blocks VALUES(310485,'eab5febc9668cd438178496417b22da5f77ceaed5bb6e01fc0f04bef1f5b4478',310485000,NULL,NULL,'3dc38c7f546df648bca32cf500b03b447f6419796e7adede280222db9f671bc0','8b52b20629fc49638f5fa4c0216736d893ad81528fe2ee627821100b11ff8946','d14fd92433caa6df5f67da8112ec5e7904045ff6730c6279fa93ef271e72da90');
INSERT INTO blocks VALUES(310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,NULL,NULL,'1a00f8df853c076b595bf0c71ae87a10325abb7ad7a6110170fc907b269a4a7a','321422bdb1074b30f9630e72c52396aa99fddb6e01b11e7db4ffa7250b054f5b','4331df76044f34bc7d12272e85ea2a89e82400a0b842803423b88d6ff86ec1d0');
INSERT INTO blocks VALUES(310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,NULL,NULL,'960268f650fad8e09644dd29ca710f982563646d928208ce6c1657ea17e0be2d','c523712cddc00cfa24eb49662f5eb50ec2b21f8bf46778047a4f62d962f300c9','caac61037893805ee97a700a53b78ceedac29dfa87267b267f089003f594ad22');
INSERT INTO blocks VALUES(310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,NULL,NULL,'9fb8ae2dcf8867e5162364b78592cfb6db84a8deb31555412265b9d560f7a500','2ac69fffeae9d337bf1c030feef954335646dbdae1dee03514eb4cd4b965ddb0','a8fff64be9a5745286f04b30344b43cf3b097bc56a50699d4ea01cd1877041c2');
INSERT INTO blocks VALUES(310489,'2efdb36f986b3e3ccc6cc9b0c1c3cdcb07429fb43cbc0cc3b6c87d1b33f258b6',310489000,NULL,NULL,'38da5c7438b53439db34b4d240cda0e8dcbc16ba0666606122546537b55eb0d7','a4429bd1191a6e6d3f189bf9ad059955fe049f8f3605761f14c90a8f5082156b','ae1c4297e0df19762117fdea88b715bd03dcfbee87b8abcfa473f3ec80daaf1c');
INSERT INTO blocks VALUES(310490,'e2cb04b8a7368c95359c9d5ff33e64209200fb606de0d64b7c0f67bb1cb8d87c',310490000,NULL,NULL,'dae78d3312fa91d3af291f04cf02827decba9a9433b4b9cecab757f3141120f7','3463446cb904e7c544671b6f14eebe661aadfab6a96b92d468a2726b8c350165','8abaef865cadc2096ea099f8831405a22d7994b8ae212dfb4e067690f6eb653c');
INSERT INTO blocks VALUES(310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,NULL,NULL,'e70fe57e120410c053ba1db138e9e90a246d20cfac8898fc06216aa75f511b6d','e421b1229e61f31ffa1c5b736da47fd140e4e89876dca0c6a1374583257ac218','a5770f446c9437af98184f5cf39c1dd8a2055755c4c38a9d0c81b95fbc62e0d1');
INSERT INTO blocks VALUES(310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,NULL,NULL,'2c76819b23cfcfdd6a42bdcede15cb90609629f4043ec711660ec54c3b0160c7','93ba3913dcdbf4233ad7d6d6316cdbb98e026a85f961e6137262a0c11ed933a3','64670f8ee29984cd46dbe6e81fa7df7188c824caf12d557098c21b3dad0eb2d5');
INSERT INTO blocks VALUES(310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,NULL,NULL,'6874c405ea0ad3c1c6bf83dbcfb70a63d24728b9527649f15404760359ab724e','b247593d2f7c0794e781bae6ba47b00f6c4807e0c80cdec53ab0349c8837463c','455a154e6857c119c182d711ebf497023dc622115e9b54df23e0104f6fbedf0c');
INSERT INTO blocks VALUES(310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,NULL,NULL,'10924b71e836afaf6d54030dca85f8ed39cf039023ce5adc48cbb5d1c5d15076','455244c45c57d3782407f7c0d24cab93a5a015cdbbf9071816c6fe59add1652f','d02bb39787d8aebc9214efeb463f6f81df2073c42caa7ed97da5be124c97d508');
INSERT INTO blocks VALUES(310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,NULL,NULL,'468a16b160862ffb3d6211c95c837bdce190c863e5e9a22628ebbeef469ec019','72d8959a21656d0029fa39d5be7a7c7b7ecc8501288a7b2a567b848ed7d2f450','582cee9990f1e03c1b8e10efc038ae0c5d448b98d903c60e35df19ef0af458fc');
INSERT INTO blocks VALUES(310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,NULL,NULL,'2c30cc384954faeb07f565b483503d555677e4580ee5560623f88857d9d52dd7','b444bbf574b5a7bee09bc46bf47819aeafea8b208a7a120a26ca9c63392e28de','54d2de4aef0a8e431e2981e0bb490d33c19d085c8cddc38d060bc42f0741cb64');
INSERT INTO blocks VALUES(310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,NULL,NULL,'036bfddac9d52271617196b3e51418ea5232d4ec8f21b26da0697ef6b37af6cd','f61c7f4e4c6352ffb5869c7ab1b1890ce1e71cc3583cb150301d8d0eef96875e','de8b995e1b4b10f8ea5001c2aca579cec485fd7fc0a452bc99819c6b9b3f1ce9');
INSERT INTO blocks VALUES(310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,NULL,NULL,'1f9ae1ab93d1fd4cebef5377eaa525c5c6e0c4a3c292e0b3cbbd43b9ce095db8','2d561e8694cd4d53187e19fd600b49f0628673b9c6eab0b2a670e5856066c050','581c52fd4fd04c0bf0bbd8533fb45c831e2dc9da99fa8da24a299aee0fb937b5');
INSERT INTO blocks VALUES(310499,'1950e1a4d7fc820ed9603f6df6819c3c953c277c726340dec2a4253e261a1764',310499000,NULL,NULL,'e6a8fc9cb4c5c0cc395c2eed8ac5cca60f4147729aa04003eb561492eb7c0e5a','366ae4935a7cc031371ad679c72c9638ea6b434095d401ae6aa63ee8c1585448','830776c6e0188a7740f5e9d9c52d123a8f366dc47ba30b8016ce1a4b18a7b92c');
INSERT INTO blocks VALUES(310500,'54aeaf47d5387964e2d51617bf3af50520a0449410e0d096cf8c2aa9dad5550b',310500000,NULL,NULL,'076b520e5dbee43fe4b278ca77cacbeea1c781a667691ba39f38de9850e0331f','29de5482305a7aa40238ed9b11f7d17b0aedfd2f2c56f1b10d3d2efb32f0414d','19d1844accdf2a633b400c686804dde51d9ff196207d7836011b676774cb207b');
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
