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
INSERT INTO balances VALUES('mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',92999122099);
INSERT INTO balances VALUES('2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',46449556859);
INSERT INTO balances VALUES('2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','PAYTOSCRIPT',1000);
INSERT INTO balances VALUES('2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000);
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
INSERT INTO blocks VALUES(310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,NULL,NULL,'6a91073b35d1151c0b9b93f7916d25e6650b82fe4a1b006851d69b1112cd2954','525269b7af5e86ba014e1890b3f6847b9606124b5d2c5a848417b8ee2855cf87','e7960f802baa42195f3c71a9a70a17d2c9fc379df4a9d8cc46cb6f7a6f35fdeb');
INSERT INTO blocks VALUES(310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,NULL,NULL,'88eac1faa671a7ebc61f63782c4b74d42c813c19e410e240843440f4d4dbaa35','c4e691a954156084c2039a0f9c9168ef0ff8c88d0182523eef556e0b41e2bd1c','972bb572f5efc7c7547bb5539f40040bcfeb65fbe5f72fe0244c080994824a47');
INSERT INTO blocks VALUES(310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,NULL,NULL,'93d430c0d7a680aad6fb162af200e95e177ba5d604df1e3cb0e086d3959538c3','603d42f18c7c25f377761aa64b55a71330e48986677756b23d0e9ccef6f790fa','69bacf6c764844c284044bd9b7178a4d0521c3f26646f0ff3a2a7feb5a5fc3fd');
INSERT INTO blocks VALUES(310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,NULL,NULL,'e85e5d82a20fe2e060a7c1f79dc182d3b2da28903b04302e6abe4a3f935ea373','1eb57edfcdc5b1a432fb5513dd0d0d9ec5aac1103043e99e584ac37dffe84c84','3c40668d5a25b19d39d6e595bbf95b90fbb2dab1e589b5454c580e4c504a5527');
INSERT INTO blocks VALUES(310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,NULL,NULL,'c6c0f780ffa18de5a5e5afdf4fba5b6a17dce8d767d4b7a9fbbae2ad53ff4718','bbfc7943a35c5a9402f4071ee3bc48c1672fd7378d82afd1b8ff439c56649cc8','c3617413c004bfac5a3b0756a9cd13626308974f4452cd18987947f280acab55');
INSERT INTO blocks VALUES(310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,NULL,NULL,'91458f37f5293fca71cddc6f14874670584e750aa68fbe577b22eac357c5f336','a808bb9551efbfbc26d3063cee963a9c01958c02ca587af8767eb2b18690cc83','1e3b61f4b1e7aec36ccd1178ecc793e55d08b4f3b3924d5024047005ccdf491a');
INSERT INTO blocks VALUES(310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,NULL,NULL,'a8f0f81aebdf77ee1945c2199142696f2c74518f2bc1a45dcfd3cebcabec510c','969913e916e08a6ce17ad80089e8901beb8ff777e2fd8f0e146c44b40a7ae3da','86af9082d2e409fba6bd83cf4d3530617b584106740ba2210e9085a12aec8944');
INSERT INTO blocks VALUES(310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,NULL,NULL,'df7cae2ef1885eb5916f821be0bb11c24c9cabdc6ccdc84866d60de6af972b94','ba7a76d75158ed56b7c2222aaa9391d824ad0a92ba756ca83965540411708914','ae5469b42157534d4d44569bd95740a8819dda2bd99b93dc29fbd303793a9c1a');
INSERT INTO blocks VALUES(310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,NULL,NULL,'1d8caac58a9e5a656a6631fe88be72dfb45dbc25c64d92558db268be01da6024','9ceba654e61956137921a48d84210b8f07548b906cd0a5dc4d4763044f17d19e','53f66b2eab506f549336b4296b53c5d976941fc552290ec03a544247005f4422');
INSERT INTO blocks VALUES(310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,NULL,NULL,'ab78a209c465104945458dba209c03409f839d4882a1bf416c504d26fd8b9c80','507c214e078414fe33aa6910c702719013dd8c329d7f480743c976c8cbcf946f','4bf72fe925762544618fc4e91f4e8e28b234aef9a4f6a4a6b1250d7d1ebf5a93');
INSERT INTO blocks VALUES(310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,NULL,NULL,'5528fec20bfacc31dd43d7284bf1df33e033ec0ac12b14ed813a9dfea4f67741','dc152bde626e494fb6a5d60626c682b00902f358d5e1a5bce66dfd1af862fd1b','24e0f2b3e2b4ea115663eced4a8bfa8bed1a7461b233535c472e14254d5347a5');
INSERT INTO blocks VALUES(310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,NULL,NULL,'fa66dc025cbb75b67a7d4c496141eb5f6f0cc42134433276c8a294c983453926','c47e71e872dc7aa711bd7ec005c3513d03fb056ff5f1f32179dd7f69320d0401','23cca2e9884cfaea6b3e1070f84f58dbc91c0ac70484a55a3e8715321de9ed55');
INSERT INTO blocks VALUES(310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,NULL,NULL,'442621791a488568ee9dee5d9131db3ce2f17d9d87b4f45dc8079606874823f8','12e96dd5cba317e044fa8a9cd45cc9853da0c4e601a48e8368959040a989623d','f1e21df61fdbcfdbefaaa61ab6cb63ca760512f88140c8adee0b58994eaaf549');
INSERT INTO blocks VALUES(310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,NULL,NULL,'8551367f346e50b15c6e0cca116d1697d3301725b73562f62d8e4c53581e7bd0','a09303c3dbd30d1534f1967f911df8ff64ea14be670042dd3f46a8a1c917e560','56446075c39beca76e9c0642afda9b25117ef63aeae3a819f9ec7b21a0a47967');
INSERT INTO blocks VALUES(310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,NULL,NULL,'29de016d6301c2c9be33c98d3ca3e5f2dd25d52fd344426d40e3b0126dea019a','084891b00e117fbe7f5a11b41b329ab81666ce160ac58657dda59f9a58e968db','565f4f41c11e191efc0ecfd9f1437369255d47e90c9613c0c1adadb14bca98fb');
INSERT INTO blocks VALUES(310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,NULL,NULL,'32ffd4bdf9b1f8506a25b4d2affe792d1eccf322a9ab832ec71a934fea136db9','640fd8cab7ace14868fa5fe21c69cdca8e24e30fc3f0b51d50f0e037f7097a72','6b7d2e2c479cd94f3e3f2be378d7861091bc343bce842ae03ffa64aa5d2eaf2e');
INSERT INTO blocks VALUES(310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,NULL,NULL,'64aa58f7e48dfa10bb48ecf48571d832bb94027c7ac07be0d23d5379452ce03b','e96cc4b9a2f9b37812b1b01be1a3cf893a0f81ebdd0d3a9b4882534a833419f9','bf4c612fbf7a2c7a24035691e2f37ae0190d7e3552a0dfc69fb906d188e9250b');
INSERT INTO blocks VALUES(310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,NULL,NULL,'8d8f404bdc2fb6178286b2581cf8a23e6028d5d285091fa0e67e96e6da91f54e','8eaf9833d2f4c3df723d247657d29eeeb603c4413151a7eed2ff298d45760871','191cca102df41ba0f06c4de90dd57c9f56647b3b754c1db46257679659692fd6');
INSERT INTO blocks VALUES(310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,NULL,NULL,'945a8fd2f57cfd5ddab542291fb2e2813762806b806a3e65e688321fefe1986d','94d15ef45dbe625b6d789010819c688930138cd93a275212f7ed6f32f590ee29','e2f355d183889203c197deb1e2628cb4dc1a6ea887dd0bd6ab3d3edc098cc1dc');
INSERT INTO blocks VALUES(310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,NULL,NULL,'3393abc111ee337132103ca04b4f8745952cd03ddbd6efff58a589e00a48fa21','9fac8cc3be8d015bac54e374c6e2ce3d12fc8088ea611a6976cfb0f2520910ba','9c8e0222d30286b684cc49af9855d4a71945622053eb7c0ca28c997a0daf19df');
INSERT INTO blocks VALUES(310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,NULL,NULL,'d05fe9705db7b30e6ea6b18e9ae92ba794dd72f25b4e33daf4d46b3b609a02de','23fe774d44f7273ba280efdd2a98aad602a9247c1ac423a8107451b8f2137bc6','313038fbe1e8f6d24213aa215b445b22797d469eb70f8250615b0048583a8877');
INSERT INTO blocks VALUES(310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,NULL,NULL,'c2b2b2c3bdd895c74f3ea22db3d9c66301578436b6fa9175ce0b242c4bfaccc5','a9ab43f735417a96f0328ea7dd7af797dbb43995c53fa36fc2b56be10cf49d79','99af9104372354bcb7208beb7a599de1d6b2481a412919c4e49bd9f61d471b3c');
INSERT INTO blocks VALUES(310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,NULL,NULL,'fad5b61545d8ef317918f07df063554d4f321c0ebf462f759513212960bdf523','c9259febd6ae9a497cc82e43530ed4276532333dc209eb2056a4ef92f588cf88','fb52dd749c1c34af25a7d4507b6cbcb422c9763458bd7ae5e438c11b2b7496fe');
INSERT INTO blocks VALUES(310024,'b03042b4e18a222b4c8d1e9e1970d93e6e2a2d41686d227ff8ecf0a839223dc5',310024000,NULL,NULL,'61a71d0ac67eba15c63a531f797e6d68c83613489730bc2b4e4054094f63105a','287eba8fc2f22c2e5ebf0ee804850f79c68963c2fc4d28f0844dc81ff60b8db9','20abbae4a6bfaf66e7db67d356abb89df07a1f9d00b54716dfb8dd86866bf1b9');
INSERT INTO blocks VALUES(310025,'a872e560766832cc3b4f7f222228cb6db882ce3c54f6459f62c71d5cd6e90666',310025000,NULL,NULL,'f7d41404c3d1e57bbc390af958d1596212112068e4986954d11ff8abd13bc8e4','b82dbb5b0e9f372342cf759ce59d351ff5d069fd3a85f0bb82bb79c477cef586','031d41c78a079591e8170a38a54d354aab608cfd42d51ab5f8d8e02804c122e7');
INSERT INTO blocks VALUES(310026,'6c96350f6f2f05810f19a689de235eff975338587194a36a70dfd0fcd490941a',310026000,NULL,NULL,'31530d7febb577d7588e12d10629fd82966df48a93a613a480879531d5dbd374','d61eef548f4bd418414d191edfe39efb1ef1c3f526c43543548261b7f38b3cf6','262103f16aad9c136630946b98a41fdfe764e2d5fa56ec5e18735522197a9313');
INSERT INTO blocks VALUES(310027,'d7acfac66df393c4482a14c189742c0571b89442eb7f817b34415a560445699e',310027000,NULL,NULL,'f54085346ae4608c57c55d321a413a00ffeb85499138559d7d05245f57cc0da3','bf3c0498cbbb0be13f0382690cc714822a5581a95886c4d23e72d80194b05fd3','83e3adef845f37b3ac39da7b90fcbc6511ae21c6f4cbd1e662bda364ed7729df');
INSERT INTO blocks VALUES(310028,'02409fcf8fa06dafcb7f11e38593181d9c42cc9d5e2ddc304d098f990bd9530b',310028000,NULL,NULL,'a841b7f634fc24553d1c8cb2d66fc3103293dcfd297cb5bf241b0c5da84bd376','375a9366ef7a2ddb774e71600f28fc1836f4feb9ce6e204e1c10a1d7c4c22bef','1da170bc1a9cbc7cdfcafa64cb1f7c8e6ff3c961709947831dce26cb316d3188');
INSERT INTO blocks VALUES(310029,'3c739fa8b40c118d5547ea356ee8d10ee2898871907643ec02e5db9d00f03cc6',310029000,NULL,NULL,'69d40c69b4989f7a59da99b56577b0651887d9422757e38d5410379f95fda641','8deb8fa094a7c0ecc486bc28589edf66da1910b35bd3d2f3d2599741fefe17c8','f1571015d0a7e0f4b3a6f6b9b828eb8d928f4f1b588fdd5771dddb1b235e9aa1');
INSERT INTO blocks VALUES(310030,'d5071cddedf89765ee0fd58f209c1c7d669ba8ea66200a57587da8b189b9e4f5',310030000,NULL,NULL,'192fe51d3a7af659670a8899582c29aedf3a5608ca906b274ce986751dad2d7a','f3210c9464f6483a9ebf2f3250d47458e336da8af778bfa022d64f0cee27adc8','7654a752908ee1f16260d85d3e8dd64d71b4b764c4224d01df1abe822b535f86');
INSERT INTO blocks VALUES(310031,'0b02b10f41380fff27c543ea8891ecb845bf7a003ac5c87e15932aff3bfcf689',310031000,NULL,NULL,'125784cdeba1e433b3411c368cdf676efb33021f51c26a8b2bd6ec00fe4f767d','afb464e5efb79c0bc1460323cf94f08c3a69e58171bef210d0bbda5885ac6e6d','0bb49d8fd6f203ab4e501e7819e6e7970dc5a5f1ee3dcbb66792feb3242f5753');
INSERT INTO blocks VALUES(310032,'66346be81e6ba04544f2ae643b76c2b7b1383f038fc2636e02e49dc7ec144074',310032000,NULL,NULL,'fa7832080a2b6ae8829794d70603351755fa4816f15a6e92716f83265daa59a4','19dee3d0ab0acafa71af9cf3b6743a3584a554590cd6282cb2f2a6faa4b9289c','33f261639ab059706b0d995740d627b2155e9711f7e3c559839d81f14734d058');
INSERT INTO blocks VALUES(310033,'999c65df9661f73e8c01f1da1afda09ac16788b72834f0ff5ea3d1464afb4707',310033000,NULL,NULL,'7b86f430bc44ad5d81a43b5a8ea118b458d995e3832d88bb74bc62429194e45c','f5f612745dad69028ef02cb06600f2dfc41c8ae0c676ebb49a8688394a95c4a5','3c19ebb7060d6055ec04d5f1d4b732dad8df87068dba0abd97a340115c9f4c31');
INSERT INTO blocks VALUES(310034,'f552edd2e0a648230f3668e72ddf0ddfb1e8ac0f4c190f91b89c1a8c2e357208',310034000,NULL,NULL,'1f2c5ac4375f77fb79612d343dd5fc4489cf94ff983fc05ba2009a9e390d6c06','7baf7262763f5365a80e347d4f90359cc084c2e5215f72ca3ca4b56c9eedaf17','f11a09464c3a4ddd09e3ff15177b52368b2f1e4cdd7f5b81ace3ba2e42b7880f');
INSERT INTO blocks VALUES(310035,'a13cbb016f3044207a46967a4ba1c87dab411f78c55c1179f2336653c2726ae2',310035000,NULL,NULL,'81cdae9b978935ad40a1032e7f22ddd7117b9c7580d6d7e4b7e20d1c875f5e63','920075d57ba2b61e7bb50eea78e6264c437690db95aaad4a3600abc89068d8cd','bf77c44ba3aac13b70acc43b7c1d35912d65a0ebe3c8693bcecf49b53154a130');
INSERT INTO blocks VALUES(310036,'158648a98f1e1bd1875584ce8449eb15a4e91a99a923bbb24c4210135cef0c76',310036000,NULL,NULL,'ff02952dce15c249501d8485decad0ad9fe02fda766b7b83720806f726d02ee4','ed329fe2b819509af0b02c8a0a814d2d9b0beab1b5bb73bef34d8bf61350b60a','b4f6e58033d56a78c254892a086cd490ae94252b2851bdb8ae192ed32ba58dce');
INSERT INTO blocks VALUES(310037,'563acfd6d991ce256d5655de2e9429975c8dceeb221e76d5ec6e9e24a2c27c07',310037000,NULL,NULL,'760e5a00feb6c8c4baf4421ad07be2af962bfcac7705b773484b449356d6c230','a8ebc16699295d620859377e5b8c055cdc36409d3d92cbc8554b11e5fdb23032','0af0c4c6426e3ffea17a274eb3ebfda012e0253f726476b9640d066225d4214a');
INSERT INTO blocks VALUES(310038,'b44b4cad12431c32df27940e18d51f63897c7472b70950d18454edfd640490b2',310038000,NULL,NULL,'c79381c51fa93cc320d8bf19c943f98232a99446ac098ff66823cf691e0fa01c','a6094408a64b13aab8e951c9e8152d5ae9e5af4ef9a4430d13fee2711b50290e','72fabf345a23a07b122c92f94c7649e78fcc81eb77e09771de5d731fe8bf623a');
INSERT INTO blocks VALUES(310039,'5fa1ae9c5e8a599247458987b006ad3a57f686df1f7cc240bf119e911b56c347',310039000,NULL,NULL,'7382f007315783c9a6ffd29bc0eaa62282c6ec72c5fff09322d6dea6b0ee3a96','0be39038cfa93496e048608200d5cb722a2cab584497d93fed4bd99f2c785fda','4add4f777b69233c1fd5615aeeb33972b28213e33b03eb18acd3da2c1875bf48');
INSERT INTO blocks VALUES(310040,'7200ded406675453eadddfbb2d14c2a4526c7dc2b5de14bd48b29243df5e1aa3',310040000,NULL,NULL,'38d3b548be554a0ae92504244a88930b989ea6fefc9bc59c69b68ed560afee9a','f22afc907cb18eb1c9032a094301ad3beb2d53dddc181640cf2e32d51f499573','16be5d010a18088f8f0a168d4af5373465498634010f71b2d67c33734ec37098');
INSERT INTO blocks VALUES(310041,'5db592ff9ba5fac1e030cf22d6c13b70d330ba397f415340086ee7357143b359',310041000,NULL,NULL,'0c1c7aa19c015a67da214bf8a6ae3d77979a09de6a63621e320a28ceebdbf333','21658e8e065b244c2f4115a0d83254c94f146e3eb72de6f358d7971f1e360b11','a7d8c5fab81c77726673e281ccc258234d4938b918aa981a5c77dbf1e032f0fd');
INSERT INTO blocks VALUES(310042,'826fd4701ef2824e9559b069517cd3cb990aff6a4690830f78fc845ab77fa3e4',310042000,NULL,NULL,'9d20f77d4afff9179cffe46574f1b2dd23d2987142c943de05e411baee2dbf05','4e2aca95a9dc0406370179becf9e1708a8e7c25e8940c498aea4518017caa2c3','d205d2e00c9112a42e15f977f7391f4e400f2d513e755d4ed1fcbccf982da96f');
INSERT INTO blocks VALUES(310043,'2254a12ada208f1dd57bc17547ecaf3c44720323c47bc7d4b1262477cb7f3c51',310043000,NULL,NULL,'d818e5a1a5cb6c59771b63997a8737cdb041c3579de1ecd808a269f5d72a3abf','4fc3e4ca19de91120e81a0b67b67f9a62d660e81d591a73db421125589cccc79','5ac8d2a496731517515e9dab61e6dfa52e4986a7ca5f6ecd88e44c4ce86f1565');
INSERT INTO blocks VALUES(310044,'3346d24118d8af0b3c6bcc42f8b85792e7a2e7036ebf6e4c25f4f6723c78e46b',310044000,NULL,NULL,'9de166ff18c5eec97b838292ae894ce18e5a890e8a841a294b2d14894c60a0d7','eac4ae79110e45ba505f19651743301fbef5e5f38ffdf66fcf4437f96010ae45','a1c5fd144eebb5eabfc564394f77b1442e5b786e301b9b71b18ed34a239b6d37');
INSERT INTO blocks VALUES(310045,'7bba0ab243839e91ad1a45a762bf074011f8a9883074d68203c6d1b46fffde98',310045000,NULL,NULL,'bb3c0a260dc082534c95e894751e38e80de117b091bc0e34c66134d374b8db2d','bd4fc4b0f155c44d48f0e884cbaa52b54a96241f1e351a6c34b19ca0a80a93d4','b9af406e8f0d13877d6665056a963f4496d420c6802acb83e85cbe04f8e473a2');
INSERT INTO blocks VALUES(310046,'47db6788c38f2d6d712764979e41346b55e78cbb4969e0ef5c4336faf18993a6',310046000,NULL,NULL,'b4605c50ee3e5e2958c908e099563cf997e20932cc2370109ab50049e43723cf','7150590496ac405b231b4046ee79948e28496b1eb45a498b9faaa08752a0aebb','20f6074a703b5a157eb8aabcdf1d2a075e4cf110698827e53e8d353985da659b');
INSERT INTO blocks VALUES(310047,'a9ccabcc2a098a7d25e4ab8bda7c4e66807eefa42e29890dcd88149a10de7075',310047000,NULL,NULL,'b840a7af6301c798c9a6670308a2684051ff8f3fb2e69bddaafa82cfd3d83186','d3bb4e192aa08e803ef635b3ca0dfed044f5194814be3bda54cc8fb41baa37b0','f21b924c31e479a882c51e81ecb370272b18a0ad99f0f24c397dd7579c7318a9');
INSERT INTO blocks VALUES(310048,'610bf3935a85b05a98556c55493c6de45bed4d7b3b6c8553a984718765796309',310048000,NULL,NULL,'6bd591d3336ea112789ad6675a9b1d8e1578fe42e44ca7f7be5557089d374c3f','354db04818b10a6c51da8f8f011e97b2562ee25f6184db42909c5c0bfa15d28c','a0bb4204e9383d53b1bc9362fb19e659a2b735dff551fbb4eee326628b7e60a9');
INSERT INTO blocks VALUES(310049,'4ad2761923ad49ad2b283b640f1832522a2a5d6964486b21591b71df6b33be3c',310049000,NULL,NULL,'04fe1e6631d503a9ee646584cda33857fac6eeca11fa60d442e09b2ed1380e5c','5fd6643e9411ba810e86a41a00b0e1b28ff8bf6e1b205aa14e8279be0f7b141c','ed8710dbddd781e992cc320917e3f40ea61e7b52e6ea21aa102118feb3f773f9');
INSERT INTO blocks VALUES(310050,'8cfeb60a14a4cec6e9be13d699694d49007d82a31065a17890383e262071e348',310050000,NULL,NULL,'dc73bfb66386f237f127f607a4522c0a8c650b6d0f76a87e30632938cf905155','397fb2ac2122ed4f39eed86e0919f812125f4d9756aa3e7c1ff1db8b2ca375ec','000384f72b6523379d605a94cc92cc11676d0567715d09c7199eeaf5042b4c66');
INSERT INTO blocks VALUES(310051,'b53c90385dd808306601350920c6af4beb717518493fd23b5c730eea078f33e6',310051000,NULL,NULL,'e4eea2d144c8f9c6dfe731efee419056de42f53108f83ebee503c9114b8e4192','87760e8715387550659cdd4cf2408ae02684faa4757523938623a4addcba4ad2','5921b7b3ffe1efdbf04ff94110f3a95f820b54f8dada07fba3555b408a62fbf1');
INSERT INTO blocks VALUES(310052,'0acdacf4e4b6fca756479cb055191b367b1fa433aa558956f5f08fa5b7b394e2',310052000,NULL,NULL,'8d12b561e7cf87b0aabe000a93a57e5f31db75510b1e9feb19b4f557cc0e6604','22a4b4d8509b82736c91cedfe8125b48f80266b0573794bde61d4ecf0f4859cb','6db8e15b83bdd0ee42058e7784cd5b8fa70fa7e1ad0023015877d78819197c66');
INSERT INTO blocks VALUES(310053,'68348f01b6dc49b2cb30fe92ac43e527aa90d859093d3bf7cd695c64d2ef744f',310053000,NULL,NULL,'f47b81b3dfc522d9b601d1776fa2deef8543ca077cb0743556cd970bb119d640','457a19e9e93b52d40f765f8e0af185cb1364cd5044ee163e548100acbc33d40c','eedfca86ac27d107d2c82238e19973ff259123212e35986c3603224f3a1f817e');
INSERT INTO blocks VALUES(310054,'a8b5f253df293037e49b998675620d5477445c51d5ec66596e023282bb9cd305',310054000,NULL,NULL,'df191ed877eb1856d6780a717c04d6925246cdee7dd6df74216ea983560d5a2b','c74ac3e1dc49aba4c16fb37096d9508e209325c876892233413be4f2c327dd9a','cff5359922e8d195d88967c5718b5021cb6e8909d9b3804a1328566cac2315b9');
INSERT INTO blocks VALUES(310055,'4b069152e2dc82e96ed8a3c3547c162e8c3aceeb2a4ac07972f8321a535b9356',310055000,NULL,NULL,'4b0ab72111202b1f9a5add4bf9a812df203cb6761a8d16b5f7a8b9ed6f2b2476','8cb9fbfe1a3b76922dc6c37cc97addb2a13b9baf6e6b575ddd0962f70a06fea5','bb3825d3e7f8df38a014ff3e48a0611cae7371c857f6af3a4c433277614d5b6a');
INSERT INTO blocks VALUES(310056,'7603eaed418971b745256742f9d2ba70b2c2b2f69f61de6cc70e61ce0336f9d3',310056000,NULL,NULL,'8e76b5be6a94e1b50ba16fe265965d4cba01b792216485c54360052e78788f20','faaba869a0f9fac9501153a2f12948f966336fe3fcc9a430721b0e6515aacbae','f5c0053355ce8f2a13f48dca15f48ac8f10d93a0babbc74796b20b5310ea1d80');
INSERT INTO blocks VALUES(310057,'4a5fdc84f2d66ecb6ee3e3646aad20751ce8694e64e348d3c8aab09d33a3e411',310057000,NULL,NULL,'e14dde2bfbe4f9076b7ba548aad37269752858361af094b4be8b956c0a28b9c5','72be43050a4e5e900bdecce62811384869dba9c19e886f51fcc016e2752fb716','afee309a009ec1cab17a6726dad297ab4656289523ff55ce421a0876348159b8');
INSERT INTO blocks VALUES(310058,'a6eef3089896f0cae0bfe9423392e45c48f4efe4310b14d8cfbdb1fea613635f',310058000,NULL,NULL,'b986e5f6486ceac7f1af41b1da968e453cc19376d588d8e884439b51313d6e30','350b574b2f830754f2d1f64881c8571e3ede1eeea754dc5ff80feff68b0e561b','fb4a0d60654ef275432f4af2f6058f203b20474568da5341c780699a56d062e0');
INSERT INTO blocks VALUES(310059,'ab505de874c43f97c90be1c26a769e6c5cb140405c993b4a6cc7afc795f156a9',310059000,NULL,NULL,'da978ee5b06812ee42cda43e1d9943c4e34e9e940cb0461f0ed463b9299402d8','cbf59f906de785ec30fff7dc1789784eba33a5d77ef7024030e9c05fda74c349','5bb92d3d70dcb9285b7ad9c3841f6ed7871c4738610132cf8acf110996cc5b7b');
INSERT INTO blocks VALUES(310060,'974ad5fbef621e0a38eab811608dc9afaf10c8ecc85fed913075ba1a145e889b',310060000,NULL,NULL,'09ccea87988cc385b9d2580613581b90157f1366d27cd3dc1a4385e104430d15','52fa5760c080df1b0e94a61f0b15cd8955c35ff2832ada5f47733a3bc4c13ff9','77b322e29f5c3900603964b0f512e3d0bc1999f12c8348a9dad5ad59acc1733c');
INSERT INTO blocks VALUES(310061,'35d267d21ad386e7b7632292af1c422b0310dde7ca49a82f9577525a29c138cf',310061000,NULL,NULL,'4caebeb5ab6468e116cc0cf137977649a15dd30d9b214a5081057a551174ec48','552024ecbc8ab0655b966b54cd8548fd4210c3abfa24226f2b72ea57cf348351','ffc4141eca8a3c488866f0b585720c790945bb52ae6733d0f32781d944aef7d0');
INSERT INTO blocks VALUES(310062,'b31a0054145319ef9de8c1cb19df5bcf4dc8a1ece20053aa494e5d3a00a2852f',310062000,NULL,NULL,'51cb3f1005127e3240721c47805d67a123afdc40084692a9cc2b3215cec99dc3','cce80d7df130137af46a5120c1088c033f3afccefba081d62d3a4c778bd45189','65f777b76d359b278725f7e8a3d37d9efc5c741559ff83c6b805b48dfdbd2bd8');
INSERT INTO blocks VALUES(310063,'0cbcbcd5b7f2dc288e3a34eab3d4212463a5a56e886804fb4f9f1cf929eadebe',310063000,NULL,NULL,'e12864a0f955320278c215897cf4f65e5c378e534294b0bb90ebd7e4b5efd4f7','e327eaa4e7adb22198876ba3609bd49e511399c6230b4b7f9efdf6fb6730036f','610bc2756f47ea45c97c769f9cd03615d6d94f8d35e7276d9e30e538e92af0f9');
INSERT INTO blocks VALUES(310064,'e2db8065a195e85cde9ddb868a17d39893a60fb2b1255aa5f0c88729de7cbf30',310064000,NULL,NULL,'ee27c3b46aa890d18be950006879874a094ecddd086db195e032fb4fe12559f5','9ab0edfd31ade89f3404b269a767170dec889fd9f581fb71f482b185e5db951c','46ea14a9bac64f9def8f65371635386e7a29f5a8db041e2661d664f61df5c811');
INSERT INTO blocks VALUES(310065,'8a7bc7a77c831ac4fd11b8a9d22d1b6a0661b07cef05c2e600c7fb683b861d2a',310065000,NULL,NULL,'d40dbc4b5faaf8918f9cae54e5a247e3904dc65994ce0f04f417c1a595404464','b98f624646064a309c2b52b8d7d6f17fa158ed7832702ff09f24451d36cbfafe','a4809f3519ef7b5d8492b3f079210a9ac52dc27b53fe9fdb81c8d8fc9a5fd64f');
INSERT INTO blocks VALUES(310066,'b6959be51eb084747d301f7ccaf9e75f2292c9404633b1532e3692659939430d',310066000,NULL,NULL,'19f2b00477a6fae0e10f4693d949cb409b1ed74ad20dbd9aa4a7f1f17cb813ac','113233bcdc87eaa7b63708a65508ef8fff7d162a5d95c437bbcb450724dd2f0f','69e0769a96a691cc10f7ffa788614d5a0f4056879f6615c301422727ced7e76b');
INSERT INTO blocks VALUES(310067,'8b08eae98d7193c9c01863fac6effb9162bda010daeacf9e0347112f233b8577',310067000,NULL,NULL,'d72891c22fcea6c51496fc1777fa736ef5aba378320a1f718d597f8f9fea3c7d','c4a11e8713b7238e4185bb00471433ead63285612620e90f5db38cfe4ed9791b','22a7555bc97fbecae56cf5f4b5faaa3a36bbafc6bd1604af1bdf8bbc635b18ee');
INSERT INTO blocks VALUES(310068,'9280e7297ef6313341bc81787a36acfc9af58f83a415afff5e3154f126cf52b5',310068000,NULL,NULL,'5793e10b8329d3ac71aed6347dfcf61fc7b74ca162ad99918f5c20065f8d0746','56c9675b58061861d82ba7bbd791e5a46e9398891e56a8db6f96b1584ae6f3d2','f6fa8b09b039b8850a1c8cc62c87ebd095e13755965d9c83d932102a9c0f0d1b');
INSERT INTO blocks VALUES(310069,'486351f0655bf594ffaab1980cff17353b640b63e9c27239109addece189a6f7',310069000,NULL,NULL,'61040e7c1a58f41d708785347f4985c1fb522b6f947d3e14dacd91157e153ab7','d6b0c09259136a89a0f63f4f3951418800a0bd39621140e01bf91168deb792cb','41c54de0c046e72e3bc824afd99c3531630e0762547a5e54e453d6fcfd11b779');
INSERT INTO blocks VALUES(310070,'8739e99f4dee8bebf1332f37f49a125348b40b93b74fe35579dd52bfba4fa7e5',310070000,NULL,NULL,'ce115625fbda90a0f261b2c524108a7393078cb4c3f861d6d7846501c7960008','34ff6bde664ce4cf9c910d096f8c1c30dfe382786a9b0ef2cb2479a53c8d53ae','331e122587eb4e830a8f4957d45871929a62da9ad5b55a4418b3dd772677bf71');
INSERT INTO blocks VALUES(310071,'7a099aa1bba0ead577f1e44f35263a1f115ed6a868c98d4dd71609072ae7f80b',310071000,NULL,NULL,'3c2d4d81e90a42a0c18e9c02b8a59f99e13f2a084ee66b4b1bd410077adc383d','656be97560010c67c8d565d7196e9c1bf59d34809166ff6e85ae264707b209d8','fbb580e31dbf6b7ea7e368e831fdabea5b7e2a782dcad39fcbfe8a78a83ec94f');
INSERT INTO blocks VALUES(310072,'7b17ecedc07552551b8129e068ae67cb176ca766ea3f6df74b597a94e3a7fc8a',310072000,NULL,NULL,'8a28e33306582346f1d965a0393621b4aa307f6614c84369064465f95a6c727e','81f7d6ad6a83631e3ebef7bb8330a860926689d74b40aef00e18d281fddd4ca9','3b752054cbf8d18b58f45865365e9016a51165f7a2c51c9c1f6478a0a407cb8c');
INSERT INTO blocks VALUES(310073,'ee0fe3cc9b3a48a2746b6090b63b442b97ea6055d48edcf4b2288396764c6943',310073000,NULL,NULL,'e6c5b393a21df54479c4cd8e991b37d877794166c19b9f61ad7e47eb34f63bdc','e1cd4d3c5e48d0e5ddcee6012275b0091dad8e06392f34c33001d9078db93d00','e91ddced22534f173626257db383f98810cc25c907947abe6bbcf3d0bfb92b6b');
INSERT INTO blocks VALUES(310074,'ceab38dfde01f711a187601731ad575d67cfe0b7dbc61dcd4f15baaef72089fb',310074000,NULL,NULL,'b2db452daf280f1cc5f02668d0cbd33732a2fe9f04307d9c072eba97c95acf5c','01f4ba98e94997bdde84132b8211015ba87a916257bdf64ec1a8ec59ddab6633','d40ca4857209252ff87bdd7f749d381f7d5c449f6e49a796cb32ed355e97322f');
INSERT INTO blocks VALUES(310075,'ef547198c6e36d829f117cfd7077ccde45158e3c545152225fa24dba7a26847b',310075000,NULL,NULL,'09998443cf1cd79e193a7b09681ae07ea9a835458151a7f8c7d80a00c5d8e99a','964bfa042751c89833cdc86fcc11ec7f901620765e638a5de9f4112d6502d6a8','ce6ad3a804473d0cd25d6f3ab59d5368ba56377893d80a65c28d7869108f3e2e');
INSERT INTO blocks VALUES(310076,'3b0499c2e8e8f0252c7288d4ecf66efc426ca37aad3524424d14c8bc6f8b0d92',310076000,NULL,NULL,'a0be1e88f10b5214f7c12dd32d0742537072d5eb3e54f9abf57a8577f7756d7e','e6e54aac82405b35166046025b8e09a09b3d4446f5f54ff21c426cc487b4ec15','5757250a2395f2df2f74d21e9171e1b0897a1382c32aaf9a36fe103a282f1939');
INSERT INTO blocks VALUES(310077,'d2adeefa9024ab3ff2822bc36acf19b6c647cea118cf15b86c6bc00c3322e7dd',310077000,NULL,NULL,'d41e39038756ee538d9438228512e31b4a524bbd05bc9b9034d603fd20e00f05','b2a9632a3e65adeb998415c27b2ddada79bcd2d54f47dc5902be5d808a6e163b','d63dc93b30f2268e47e95b0618f5a20b507130ec3128b6c688d3584532362f3d');
INSERT INTO blocks VALUES(310078,'f6c17115ef0efe489c562bcda4615892b4d4b39db0c9791fe193d4922bd82cd6',310078000,NULL,NULL,'996092432a2d94df1db34533aa7033e672fac73de5193a696c05ae7c30d75247','9e9e669e345b703e63097101f18a9b904edcc5d6e19efd804a8bca910837a969','be01ee7281affeac27148d3c48522d57e5fcdf97aba7b49f923025df1cfa2ee1');
INSERT INTO blocks VALUES(310079,'f2fbd2074d804e631db44cb0fb2e1db3fdc367e439c21ffc40d73104c4d7069c',310079000,NULL,NULL,'e3f536e930e39b421e3a0566eba6b8f5f781ad1ff48530a5671752fd3eaf35ac','1af2b4d84fcd0a5a376016308d67d5fd5f6284910ff167f4697956650fed2562','0bd88e77ef18e063a18baa4d8ff8397617cb27e9c86e18a4d99fa4eb6c615327');
INSERT INTO blocks VALUES(310080,'42943b914d9c367000a78b78a544cc4b84b1df838aadde33fe730964a89a3a6c',310080000,NULL,NULL,'57122dc41d7de2bdc65002905617c357496432fa4d80af48f4ca69ba1332e634','2d1a8ddd7fa843c60b042408340e733936f335813353221305a8f297f111a3ba','91a02bbe620d3b16d412a02049501ec9369be0f9e0a091a481743bff8b331c84');
INSERT INTO blocks VALUES(310081,'6554f9d307976249e7b7e260e08046b3b55d318f8b6af627fed5be3063f123c4',310081000,NULL,NULL,'3a0fc7b2f0396d257a0a5c5a313910cb4073e4c79ef8cf0d3cd12f494e563105','c3bff01f18f88171e962ed98d19bd8a9929b92bf6ed0aaec2e5cb9aebdf7e368','fce5f848dca6aeab085ebbbb9e59540ad0d6d2734ad38cb2109f4058bacb9102');
INSERT INTO blocks VALUES(310082,'4f1ef91b1dcd575f8ac2e66a67715500cbca154bd6f3b8148bb7015a6aa6c644',310082000,NULL,NULL,'e876c406f682ed6f0dbd6e4c97bac13409cd400b59e894eebeb3252be306494a','73cf84ce14954d1776613cf1c89baf72575a3a963812b452ac5c6eb45374dcaf','0e0fe6ce52d3a0e15a2751f2420e77af8fe17a33a6e04db5ddb6b2d0b732acb0');
INSERT INTO blocks VALUES(310083,'9b1f6fd6ff9b0dc4e37603cfb0625f49067c775b99e12492afd85392d3c8d850',310083000,NULL,NULL,'533fc3eea80caa46cf8fd62745c5d21d09f32b18eaca70283a4bd72924c2100a','c3d05954bb5cce4ec513314f9b134a891b835453a21157cad5426f0f2045a029','c501cf325d91096ba48a3b49614482c83dbd70784fb4fa8094134da76893c05d');
INSERT INTO blocks VALUES(310084,'1e0972523e80306441b9f4157f171716199f1428db2e818a7f7817ccdc8859e3',310084000,NULL,NULL,'e3fd22f2e1470246ca99c569d187934f4b7bbb1eedb9626696cbaf9e2b46253b','f918f3dc7d57a5f1803628e594fb74ecfd257d7266bb3e1eab10902e804a501f','fcf10ef722de1685f98d7f7f241ab1f25efbc34709baedc8e27c2a9aee0df983');
INSERT INTO blocks VALUES(310085,'c5b6e9581831e3bc5848cd7630c499bca26d9ece5156d36579bdb72d54817e34',310085000,NULL,NULL,'bf04750fe13f663adb12afd3a166636a4511bf94684a77217de1bd7ef9077d94','141d459964a8cdff1df175c5f95d8ae6d3b0914facc07fcca1efabc9e44944b7','876ad693f61d8bfb1af6b8d45365ebe87c1f7f3bdf9d14e5cc13787e3240da37');
INSERT INTO blocks VALUES(310086,'080c1dc55a4ecf4824cf9840602498cfc35b5f84099f50b71b45cb63834c7a78',310086000,NULL,NULL,'a0e8403085ba63ba72432f27ce8125921ef24742f988ab7f85dd8e4309f27a2c','7d82c4b29150959468a06a75abbe93ae033a572e15dbc5585b5d2e6894055a3c','0aa4b912ba6749517633daab889a13122c01d36e736710a25139698c12c9a356');
INSERT INTO blocks VALUES(310087,'4ec8cb1c38b22904e8087a034a6406b896eff4dd28e7620601c6bddf82e2738c',310087000,NULL,NULL,'0861b02e980ad5958bd23ac02603b132efd72ee2a70dbb0415fa5d39cc524681','88a3c95a21246c744935d57a58626875231e3c459f0b742d934ec07aab8e0be7','6d12b4b4f45940d5053d0cc3163e40ab0a43009f0707b366d1605dd934b48680');
INSERT INTO blocks VALUES(310088,'e945c815c433cbddd0bf8e66c5c23b51072483492acda98f5c2c201020a8c5b3',310088000,NULL,NULL,'d52cdaa449f63f6d3abc79080378855206f91a5db865dfaf37a5a2529ea6eb9a','0f50bdd7a2186bd22f53c44203039f825142637053298a7f5ab06e5c2b3f2dd7','060e269b07f6ccb0821ec08971887365c7da319fa73fb258f75101fdd749296b');
INSERT INTO blocks VALUES(310089,'0382437f895ef3e7e38bf025fd4f606fd44d4bbd6aea71dbdc4ed11a7cd46f33',310089000,NULL,NULL,'d15a7a60b8bf8618667863b3e31eaf6202664e5aebc16d1f7a337b857ac31f90','67a00951bb0bae3143faac038292aa86ea4d1662690255be5cd661ff22fe1197','3bde444f7ec92b7b3e69309010ccfd5fb7f3b4cb39f911fe83df7df75857edcd');
INSERT INTO blocks VALUES(310090,'b756db71dc037b5a4582de354a3347371267d31ebda453e152f0a13bb2fae969',310090000,NULL,NULL,'68475dcfe8252c18501fd1fef2afa2a91d20b92cacbabb542c12f43403e66ea3','982e2d10e369e0520dbd1f16519fd27d98990e681f9d6ae9c854da85c9ff3f82','af42aadc3ad65e379eb0bd36f3920df3f47f3ab700c90532ec4ef66d08cf555c');
INSERT INTO blocks VALUES(310091,'734a9aa485f36399d5efb74f3b9c47f8b5f6fd68c9967f134b14cfe7e2d7583c',310091000,NULL,NULL,'5d584f255e5bbebc32c78a30fa816e1203fe7d3454611bef9222cdfc91dfcb63','787510e4ef984f61bdc07dbaefb36a0308d3428a6dc9b9a17aa4b1d534c7762a','601307eb6fe25fd9c76bd4e3d0e678bda726a885f85eab8f07777b246c558eb0');
INSERT INTO blocks VALUES(310092,'56386beb65f9228740d4ad43a1c575645f6daf59e0dd9f22551c59215b5e8c3d',310092000,NULL,NULL,'ef992ad033b047b7f6ab038604736f444da55be187834f8152b173cf535c68eb','fb2f02017b8b03323bb95aeefc89c2592e518117ca0d8e38a04758b72381e076','4ba069a945591636bc2952c7d409c4099452b1f7d4f913345090c7e7a67bddac');
INSERT INTO blocks VALUES(310093,'a74a2425f2f4be24bb5f715173e6756649e1cbf1b064aeb1ef60e0b94b418ddc',310093000,NULL,NULL,'9cdee996d0e67ac3f9f283151b428ac5f223b72590965f41f93adcece6b88f2a','3e4e53831b152827757b17e46e40a6c366d3a1984fd785a3f679646eb70c0ea7','91ac09f1118dacc035c87da65c46169f9f8365897c1722183333d1b5f6bcc17b');
INSERT INTO blocks VALUES(310094,'2a8f976f20c4e89ff01071915ac96ee35192d54df3a246bf61fd4a0cccfb5b23',310094000,NULL,NULL,'fa25dc3f15fb28718d788f85373555966251f54bc6ed1f4dd2244b438d27b281','4c2b346d98bbcd766ce3fd266bd611c33181053812710986034856857201ab1a','debddfbc08a23e91b10c559f545d4fe1b822763cb711b9ab3fa6a4dda57a24c9');
INSERT INTO blocks VALUES(310095,'bed0fa40c9981223fb40b3be8124ca619edc9dd34d0c907369477ea92e5d2cd2',310095000,NULL,NULL,'1ba8cd971f9a169d43b6de1a136cb8e6153649fde1f7a8e7fb2f7de926fdf8b2','d12f778a06bf45944a5d4521b73fbe6e0aaa3d5fdc1c689da03eed2ee72a2954','24fc9f9e48ba152f4da67bcdb84d41b7f033c91f2ac4278448ac88909473cb8c');
INSERT INTO blocks VALUES(310096,'306aeec3db435fabffdf88c2f26ee83caa4c2426375a33daa2be041dbd27ea2f',310096000,NULL,NULL,'42c36df2c53d762b9b132e622f52b2fca99bc0370978463acd22cdf6469587a8','d02c4857f575c413213e90be8528485521a0f538545c648cb742c7dc2e2bb864','bf56ed5dd782b2d67d12edb0a5dd9c2bb5aeaf56d9cd48aa04a2669743ee6394');
INSERT INTO blocks VALUES(310097,'13e8e16e67c7cdcc80d477491e554b43744f90e8e1a9728439a11fab42cefadf',310097000,NULL,NULL,'d96af5cf3f431535689653555c29f268c931f9fb271447aed050303d364f92a8','38669845e6dada8c991c1b2410d134e53d5e372636338d0f2255c9e58e4b7d86','7cedf9fb822bed4b9f5e160db51ba0ab45cec95d54f1e356475fb1db3babe4ec');
INSERT INTO blocks VALUES(310098,'ca5bca4b5ec4fa6183e05176abe921cff884c4e20910fab55b603cef48dc3bca',310098000,NULL,NULL,'153c9ce12e8d9f9d10c4005fc9af158613480d38b2c6551fc49bc57380c229de','2ba914748c9f07aebdb4bb1df5da75b193b1866eec3b78b6c7fdb193a01cb1f3','4c4b247ad4a58f8cf243fb136fa63bf73794d3bbb02c20f93725f1ffe32e1459');
INSERT INTO blocks VALUES(310099,'3c4c2279cd7de0add5ec469648a845875495a7d54ebfb5b012dcc5a197b7992a',310099000,NULL,NULL,'49f33b269d717b56a399843cf4627449010133b47079134b9e299ac5386468ee','5fc51c8a91b6ef1f2c54714dce5843ac6c24817940af8d4f6d9c5bf20313ff99','1dacf0a8fd17c1e30c05b2b407ec8352132748f95ef15072f3e4467b2a5d163d');
INSERT INTO blocks VALUES(310100,'96925c05b3c7c80c716f5bef68d161c71d044252c766ca0e3f17f255764242cb',310100000,NULL,NULL,'c9e72f7db2950f0b0e6e8fa3bc47d37a0d643da6ec61b236f7224b63ac60467e','2c615fc46c8206b2c6203a6c0ad2021ea47eed5ec9c9bba6302be8e796f8c8fa','3aaefc4008b110eee5ff08930b10fc95bab60fe39ee392dd464bc611f13d5b39');
INSERT INTO blocks VALUES(310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,NULL,NULL,'a4387c8c785a8407f2dda176a7e182617904e7ce00c695ea8aa2f9d0429d9e74','4d0729dd6b15b65f18b39c5d516b545625c4b335b5f57b55f73f951a693a0318','0f065db18a37be4ebb1a536b90b8577bcb426c0891db09751c413b9ee49d7f4c');
INSERT INTO blocks VALUES(310102,'11e25883fd0479b78ddb1953ef67e3c3d1ffc82bd1f9e918a75c2194f7137f99',310102000,NULL,NULL,'fc81f97474f7b35ef92ba93de82d38650a28afd140d3320e6f6b62337cfd1e94','28615d8d9f6bf4938894c69c193e68d4ec63fa4bbc2d5456e2124589060a401e','a1baa26548ba33b4096f65098b3f4fbfa28feb59273d4e581e7170326306d945');
INSERT INTO blocks VALUES(310103,'559a208afea6dd27b8bfeb031f1bd8f57182dcab6cf55c4089a6c49fb4744f17',310103000,NULL,NULL,'3a502a89a3b66438cd2b944f8951a78999ba18c5f5bc8abeafe373ae4625ed4a','2af8fec7cec78acd781ab86df43615faa422e0177ae40a68e9ea3b68cbbf1812','49e72646b2e6637d8e4e3400486aa2cccdbc7caf78163849a5fc6586d1f9e4a8');
INSERT INTO blocks VALUES(310104,'55b82e631b61d22a8524981ff3b5e3ab4ad7b732b7d1a06191064334b8f2dfd2',310104000,NULL,NULL,'74ab5df2cdd13b654c80ef12e460120c96ce30d4690a06671474235fb93fee4a','5c4ae56b6fa3a6e0296febd99ec8c19c31d7334b369a4be2a53cd6df3317d2ce','8ee5f4affa121821f873c8558ed106fb0187e29a1d27a870e25a9f026c5d4453');
INSERT INTO blocks VALUES(310105,'1d72cdf6c4a02a5f973e6eaa53c28e9e13014b4f5bb13f91621a911b27fe936a',310105000,NULL,NULL,'dcc1940370421712cc668dc401169a55dd7077a49feddfd70e9e455aa5893962','42e82586926cdb6cbbeb4348cf46f1b00af26ab2e7e1c9108c8d67d53174129f','bef47374c520ded8590e952da21e70efeb84df2b9a76a3abbc62adfb29087a07');
INSERT INTO blocks VALUES(310106,'9d39cbe8c8a5357fc56e5c2f95bf132382ddad14cbc8abd54e549d58248140ff',310106000,NULL,NULL,'6ec3678f9b647dc1ea3dfd0d76ffd240da9a94097ad29e48e7b327d6198f4f78','95c5e578476d33bd80da8856eece79efc1bc98bff2bd31e64b273a26216356a4','f4ed9338860a4b69ad71d584d8ff6313d14c0cd87d6511ea17a7f7e3523abd62');
INSERT INTO blocks VALUES(310107,'51cc04005e49fa49e661946a0e147240b0e5aac174252c96481ab7ddd5487435',310107000,NULL,NULL,'8e3c2d75c7a81175405f39386e2367c7a655afb53d7cf5b5c2e7dd2c79a40d9e','e276a78d716d80700a17cb27b9c9897c1e8d375f857e8b38fca7a9570e5a226d','e92230c326ffe07eda8569e8170b5dace5b4abddcad0542720aa8260103dd0d6');
INSERT INTO blocks VALUES(310108,'8f2d3861aa42f8e75dc14a23d6046bd89feef0d81996b6e1adc2a2828fbc8b34',310108000,NULL,NULL,'b00c403723eba6ffb5db3d9903fbaa8a04a783c61949b9220e2caece1a8b86eb','2457d86618bc13f9583cecd94efa29903190e325d8ab42fe679171665e1c6e16','a5b765a8eff891457c831ca572a2553c828910c56e5fd0c129ea060365e2fa70');
INSERT INTO blocks VALUES(310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,NULL,NULL,'69d2150543fe997a6685eac965283a3e7c9d3f9aa4eb2e08e8e4fe7a15054d26','d62ec98221fa465b615626166da8861984c0a71e72fba5687a94684dff8d9f49','dcfe4ae5c1a17e22f42c0c8603c349d82a5c2b9b3fb40adca64b34ec0baa8990');
INSERT INTO blocks VALUES(310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,NULL,NULL,'0122bef9da908b66c64aae0057d2052e1333c7e71075aed739de6838f03802a8','55c7ebc8d9599ff3e2490a7a3b442868854dc43fd6ad898e202822bf03c46de1','14a5b56b24e4d2f37e02ee174324a06b5d4b12e0eeb2ad7660c1fd2236f1f1f7');
INSERT INTO blocks VALUES(310111,'fde71b9756d5ba0b6d8b230ee885af01f9c4461a55dbde8678279166a21b20ae',310111000,NULL,NULL,'d3ff81444800b8c914171c58ef93c9e9ce87dbeab3b7bad16729685eb0e2e55e','8acd160c8309bd0f708a7ca996b509e3b9b5340f74b2dd70dcd01eeb55e019a4','e397c779ed9d5d39cddf4d9e107d79252bfa0659118582c98f703f2d2cc120cb');
INSERT INTO blocks VALUES(310112,'5b06f69bfdde1083785cf68ebc2211b464839033c30a099d3227b490bf3ab251',310112000,NULL,NULL,'e316c6a4f4d1dcd800bb94f80dfcb66e9d8fc52927673c91865460b8a85aa84a','bebeb03492a182e00b160b095819f1936ec94ac6f2a3de1130c401061718b50e','1d75fdef6c5cc7bbada63882377ea70acbbd5e2b8df7b21716cd65de7c45952f');
INSERT INTO blocks VALUES(310113,'63914cf376d3076b697b9234810dfc084ed5a885d5cd188dd5462560da25d5e7',310113000,NULL,NULL,'44ffb0b4be579060aa2a0fb574935764189ded92d31cc4ea94e4042734a9377a','b0b28e0130d444a90977554c494e3cf0f866f9de99c0a7c52ce4c2470e0851e7','5ee443ea6d369f66918034e5e61bc2ae3c4f0e9dd7823efa82b18e39f77e05e1');
INSERT INTO blocks VALUES(310114,'24fc2dded4f811eff58b32cda85d90fb5773e81b9267e9a03c359bc730d82283',310114000,NULL,NULL,'a256d5377258011a8a4d887ba734094b7dcf2dc5fe99333069abaf71a7233948','c4f62bd6dd4a2180988d523d7c6e6f8b406c72cd0295ac3e5eeb2908f12f14a3','1cf2a23917cdd90443e94a7626392f5ce55687cd9784cc5b35a40e0f342bb9b9');
INSERT INTO blocks VALUES(310115,'a632d67ff5f832fe9c3c675f855f08a4969c6d78c0211e71b2a24fe04be5656a',310115000,NULL,NULL,'40e8739b957a2316bde9e5727b7f57427691850996a794c6fb6095e8510e88a7','8954f97a405a1756beb3b22ae8f094850d45276f8029da0ae0e9c584b79c686b','417f6311a374cb49971c4d115b733b322a44bdd740617432f3b09f51a8dc9222');
INSERT INTO blocks VALUES(310116,'8495ba36b331473c4f3529681a118a4cc4fa4d51cd9b8dccb1f13e5ef841dd84',310116000,NULL,NULL,'cddef956a174dc306823ac6c25d66f6b0df70918c90fb94bf6b0b0033443dad9','cc6042bf844a2f7efdd44fc85f10561c3e9020399bf60305c448b52ec470c831','6265ce10459d5c8d2d9e32e121dc87474bc6648a6801b278c4679369050d10d7');
INSERT INTO blocks VALUES(310117,'978a3eac44917b82d009332797e2b6fe64c7ce313c0f15bfd9b7bb68e4f35a71',310117000,NULL,NULL,'235c743e4857b7bffc03628ee42350b5bf550ed10bbcd9ed7e405ec17f30b67d','a1b860a503728fd75fca1bb4637deb63aa10bc09d11370a4b278cd5a7a330a95','50f46a3cd8e38c8d5a297c546458fb985b2701e1f0b2618e7a89b03aaea3209f');
INSERT INTO blocks VALUES(310118,'02487d8bd4dadabd06a44fdeb67616e6830c3556ec10faad40a42416039f4723',310118000,NULL,NULL,'5559796f49bc96fb1ca98a673a137f3c98ccbef8f9110d05b770ecb1cf805e37','cc1f382f16574accea47f6adcec66ea32ddc9be09cb61e1079d3673b0565922f','b2daf966f871eda5d34937647f625152b3f1b04d3024bbf7bf1bff6bd654fa1a');
INSERT INTO blocks VALUES(310119,'6d6be3478c874c27f5d354c9375884089511b1aaaa3cc3421759d8e3aaeb5481',310119000,NULL,NULL,'576597cb241dfa9eada633311916072451225339aed38d1a481c82d5e2833fd5','3dcb5f5f62aff93fca8f8cc26382d3acf19dfbcda79fddf878d0a8d0d97fe44c','78e91e53c3644c851f2db5271b6ef388035516e851afa2097c07da1fd6ea9114');
INSERT INTO blocks VALUES(310120,'2bba7fd459ea76fe54d6d7faf437c31af8253438d5685e803c71484c53887deb',310120000,NULL,NULL,'abb63a7c4edb99c71e21d1f634fb7e95d104e420133b2d216af99c0a367be94b','33c3685f2d441ec088ee567f9f34f5d5b6cba9fb4e98f04d8d3bbe8a00d45aa1','1a67b0d6f8b6216e9dd4d8d90d12734a2de117bfa60511fb0cb49eba4defda91');
INSERT INTO blocks VALUES(310121,'9b3ea991d6c2fe58906bdc75ba6a2095dcb7f00cfdd6108ac75c938f93c94ee7',310121000,NULL,NULL,'b72746feb9077aafae6737529b4c1f0552c20ae45edaa72c2df4bea3c018d532','280d2e6a860a293d65a867c79ef6802ae8440e4e1efeff739c6138cd58fcdd49','1290eccc62ed66ec62d7a00cf512440f4b0be1b07894bb3b5d92bb38b015305e');
INSERT INTO blocks VALUES(310122,'d31b927c46e8f9ba2ccfb02f11a72179e08474bdd1b60dd3dcfd2e91a9ea2932',310122000,NULL,NULL,'add1e878e00a20f8f357bc783cde6116665655b241d473f854f0808ddd9b73c8','3340d0bf9186ebf2f9f418582adf0933b480a474f76c634ffcc35b1802c53878','1d2f9b17db93807bbaf77540053ce7b412e324888f176ac2548aa1a95af13364');
INSERT INTO blocks VALUES(310123,'be6d35019a923fcef1125a27387d27237755c136f4926c5eddbf150402ea2bbd',310123000,NULL,NULL,'d85015fd04e9cb0b6fffedeb2f925e2dcc80666528daaf98124ec3565e8d3cc0','0934a1743b23f90d202fa4a89abbc5bb6aba004a97828bde1f8c04f4d1faf1f6','a40f66771f8568131d09f12b99a713ea79dadf358fb3d3b3eb8b96178ff78edb');
INSERT INTO blocks VALUES(310124,'0984b4a908f1a7dac9dcd94da1ee451e367cc6f3216ee8cdee15eae5d0700810',310124000,NULL,NULL,'156bd9f1502fb3eefb80646fc15df6a2855e0548c5d877dabb7d4660324609dd','e20a3479cc61366ffd38e88c086ed5b7d6e23ab8bc4f6e69e4aad5eb0e113c01','b8cf8616db10cbf2b7451700a6146c9ba18c14d3125e95420502950f04ca87d9');
INSERT INTO blocks VALUES(310125,'cc28d39365904b2f91276d09fae040adb1bbbfd4d37d8c329fced276dc52c6a6',310125000,NULL,NULL,'d0b288be666bd1e4a7a6ace21c2b373330dd73348825f93cc46086cbbcd48a0f','8150ab9d81c15c308e3c366dcba99ca9cc58b73dc905e7f81de2ec4a612bfca3','d82680dc0757a2b7cb94c2cf598ec312a4ba8fd81098ff33a63fe2adbf533144');
INSERT INTO blocks VALUES(310126,'c9d6c2bd3eeb87f3f1033a13de8255a56445341c920a6a0ee2fb030877106797',310126000,NULL,NULL,'c2c842ff8f74fdecd9604a947792420c1e8a16d9eae381a2bc9aaee9694f4067','3825517661fd411883d4eeecf09b17dd6f9019f722497ac693ec8351e4b5d940','d5b1bd007592a2715167cfed2d9547059cc6c86de003bd61a7e82bc24237e678');
INSERT INTO blocks VALUES(310127,'c952f369e2b3317725b4b73ba1922b84af881bd59054be94406a5d9bbb106904',310127000,NULL,NULL,'d8cca33e7e524da7740a21d5958359a3e6a6f314251e5250f0bfa06bd16f358c','1bffbc31edc7c3d6eb4984c8cd5564809b0c3d79efeaf6d9899d01e907e08cbb','a3d9801f3582838ef863b2c3a92d2251070e9b6986e70d0a53063e8de63aea0e');
INSERT INTO blocks VALUES(310128,'990b0d3575caf5909286b9701ece586338067fbd35357fec7d6a54c6a6120079',310128000,NULL,NULL,'5458f1a4d540dc33c0338b94b2ce0bd7a6398a9d3369de8f3ec6f7a8a690f753','a7dd8c8cd3379ca0e8f718808517290bfa748946329cd24202a564a6f2a19294','0805b66ac40dd6b9ae855ad05b397033c00a217df953fca5ddf8ddd3612210ff');
INSERT INTO blocks VALUES(310129,'fa8a7d674a9a3e4b40053cf3b819385a71831eec2f119a0f0640c6870ca1dddc',310129000,NULL,NULL,'5e6d75061f2ea056056681fd3f856407249975a5a4a327bbf8bc20a96743fffc','3621848930fb760333d6ddaafad180ca3325d956694e06f95e4f32d35b4e4dd6','77fb6a83a957a3709022d77627112da2074231c68ad6fe89cb17f10a11dcab05');
INSERT INTO blocks VALUES(310130,'d3046e8e8ab77a67bf0629a3bab0bea4975631d52099d2ddc9c9fa0860522721',310130000,NULL,NULL,'200b50c17c51fdb4275ec49e7300227a63ced6e3ff9292be49eb7b402d3db1b5','55ac9a8fbf422e8325d48978d494977bd65c5dccf3e0791dab768cd063b0151e','ced80383f159ae368c1fa7330b79feb5f461d731dbb828ccb30e8c98f7bdb1e9');
INSERT INTO blocks VALUES(310131,'d6b4357496bc2c42b58a7d1260a3615bfdb86e2ce68cd20914ef3dd3c0cdd34d',310131000,NULL,NULL,'de1c49ab1e413b11cff49cb50b22b8ac76a1ad93a024beebc8f9ad0d959525d5','bd124264325d942e93e4c5ef7a42781e80759646e7d16b7cb695e05a447950ce','6c68866758ce64818ee4bd873485a03e3232d89982a344bacb90e8afc1bf60f2');
INSERT INTO blocks VALUES(310132,'1b95a691bf4abf92f0dde901e1152cc5bd87a792d4b42613655e4046a57ab818',310132000,NULL,NULL,'306d6f01cc778512334b73d66435983c57183e7c4f87c26f1166a7a83a36a155','25d99ba2dbf67020ef87060db52043a7220eb045e6b2275127ec899e8debbe9d','37bbe99f0f1ae8d1627b57c66505ca3634240f9c553269c4b0e35018f070f9cb');
INSERT INTO blocks VALUES(310133,'1029c14051faabf90641371a82f9e2352eaa3d6b1da66737fcf447568ca4ec51',310133000,NULL,NULL,'e156b907295c14968c5fbe5e8fcc9fdc0415f3413a36a7ed737ea9e9f153e958','28739a03a88cd526f24bbcd967439618a30e5337d1a58b083eca375ed065678b','41bfa2a39c8edb6c97f182061d95fd8b44fc875efd8c22afa0308b6018c3671b');
INSERT INTO blocks VALUES(310134,'1748478069b32162affa59105257d81ef9d78aee27c626e7b24d11beb2831398',310134000,NULL,NULL,'2528daefb0d2432358a70b10e11397535232c4fd2e69eacc77219c423df1d3f8','d20b6e54b2a8769c87e66568a2f59341459eb568ba1be1aeff5d433d5a68791f','13c228251bb26ac681452583eb30ac3f218ef34dfa3cfae63c964306957618f1');
INSERT INTO blocks VALUES(310135,'d128d3469b1a5f8fb43e64b40f8a394945d1eb2f19ccbac2603f7044a4097e4f',310135000,NULL,NULL,'81b3a7fe120fd6f795536d275ac4b1621fea8a4d968b14a51a71ecee6944a819','dc016cc08305226e1a156f6dda28dc89f233ed4755316fa09847da4b6afb4e77','50a43de00af591064960ea427e8b39cf439bddb4ee393be592cbda0cd44485c8');
INSERT INTO blocks VALUES(310136,'6ec490aaffe2c222a9d6876a18d1c3d385c742ff4c12d1334613a54042a543a5',310136000,NULL,NULL,'405c424434f5e9036d00704008be3793514d29a5bc619c6f5cdfd3c86326fd77','506c584ff143c0a0bf9183d4d0af450e996c696da528a84f7f4f9e080e6096cf','cac6354ecb8654649398dedeb19b4ff3b3eca8efc29e36f4e6da1139723462b7');
INSERT INTO blocks VALUES(310137,'7b44f07e233498303a57e5350f366b767809f1a3426d57b1b754dc16aba76900',310137000,NULL,NULL,'7ee1d757a81c357ea0d18e59433d275a28f04f384baa35cbb874d75ec0182dad','bb051bb111afd7b2a746610671c5a964ac77d171e8135ece17048ba4a1f40106','887130ba3f9f99b831e6f5dda6bcc07e619fbdc41fdf0aa05de6a0d7c41b4dc4');
INSERT INTO blocks VALUES(310138,'d2d658ccbf9baa89c32659e8b6c25b640af4b9b2f28f9d40baae840206402ab5',310138000,NULL,NULL,'1306ff4026b302043a5f418cc64aa65a1e5da7ced92aef50ba9c5699509f9eec','e237ec468236c8be5aa5f652a846edce53c1ec78725776613150539c421ed6e5','577fb8d265f2bf7f5a646f915ab2460a87684f237094673154c6631c40af33c3');
INSERT INTO blocks VALUES(310139,'b2c6fb61f2ae0b9d75d18fce4c52a53b1d24772b1ad66c51ca51090210527d46',310139000,NULL,NULL,'ea081adf4304d85433da18652bdb032ac5916bc6a1b96410cf0ec51f87a5c519','96e304793f026342d637b6fc3932770d8f1537dccbf6c02315411c25eade0ef2','ce38ce22330419683a7e3596296aa37bc5238eacd550bcc3c54fe8cddf14f821');
INSERT INTO blocks VALUES(310140,'edddddea90e07a466298219fd7f5a88975f1213289f7c434ed47152af6b68ebb',310140000,NULL,NULL,'96f0be399144ab67ac49b54f80ef596a5c508e0f052d35b07259aff88a559a0d','46289ec4fbcabeab3956b6ca7df4124fb4d589d01861c8f66d60d7fa4ed6c2b2','c58658bb3f5f009863ae93bfc32a827a94cbd9212017388d7f4ec29637159d64');
INSERT INTO blocks VALUES(310141,'b5b71d2a271bd638561c56f4ffbe94d6086debaaa86bfeb02ef0d71339310709',310141000,NULL,NULL,'fed95d3c66979f94f4cf0ee075476b5a3e37d17285e1e84e2dcea837212ec8ce','f15086837bbe30097389e473b99a54bead4bab06e8f38bc6e191345170744767','0b240c829310677817907a3b4fc7f5806b779c03760c1d032a562c3e88d7cdff');
INSERT INTO blocks VALUES(310142,'a98ae174c41ab8fc575d9c8d53d8e02d8e446b8c6c0d98a20ff234eba082b143',310142000,NULL,NULL,'d062c8df1d3bbbed10c67250e4273f47d9edadbeae329e91a0d9214d62e2dafc','e7e2086937d79397108ae7d903e842468b58c8e6cb1814492976f0d25e3d0aca','b1cdcb47b933bc74a7443702de1acd10055878fd8eb4091bfb26f5b9d090d56d');
INSERT INTO blocks VALUES(310143,'8ba2f7feb302a5f9ec3e8c7fc718b02379df4698f6387d00858005b8f01e062f',310143000,NULL,NULL,'8b58427567f04bea48d8ef1643b1936731dfa1d44ab5ae8a0a725f5808e5cb25','b1ed44f3000bda0afd54b46183a2b454aaae2c55bbec6a2e277a283064d3e541','d7f251e9d271dc22cf4c178f803e696643c874a8241af3a35e40f714a5dd441c');
INSERT INTO blocks VALUES(310144,'879ffa05ae6b24b236591c1f1537909179ed1245a27c5fdadd2218ab2193cdb9',310144000,NULL,NULL,'17fea61e6f803d990bfd78ae94f5482755577ffac62c56ae964a9ba4eba2a4e7','1b688b19a9dcf1a725b8747ee6eab7deab03a1fbd3e76047a172c2d7c2c54340','f7d742a67cd30e8bae2db2bf352e958872cdd1018591c0a76992f4711bf72acf');
INSERT INTO blocks VALUES(310145,'175449ef0aa4580593ad4a7d0c5a9b117e1549ea772af00caa4ccdc9b1bf7a6e',310145000,NULL,NULL,'fc7745aaf59225dfd4055496462ef19352e31e7a681d5ddeee5d8d305914cd63','68f02cf0ff105201361e46eec9eff5bfaf7246ec69267f6247442d943aaa2f4c','895b92712c4c51cd8b57a04ae8dda818772b8124ca1c094f5a485f8c16a8502e');
INSERT INTO blocks VALUES(310146,'e954ab6a110455d745503f7cc8df9d92c1a800fafdd151e7b1912830a9cb7184',310146000,NULL,NULL,'b21400cea27ddadec8c336f757c1f250be59c2608323f5492cc40f0c2c54c086','16c6fac57cc93baabebc72b9ae8f10e9184882a539dd0618d548d164aa6fdc57','d82debb85662856397e6fd8a72900d71a3c7d702187c1f1aca5f5faf59be925d');
INSERT INTO blocks VALUES(310147,'7650c95eba7bf1cad81575ed12f32a8cc36281a6f41bef13afe1dfc1b03a7e83',310147000,NULL,NULL,'47ed87885040679eaed04907a9adcbeb5fd23c3220d106cf991c692e56a47c85','3573996884654adba6e90b411635115ee096c8657c5ee93f963c3a8797e0c345','9577772de2cd32c9071f2d3fa4753115b088163dad943ca581481e5672869b68');
INSERT INTO blocks VALUES(310148,'77c29785877724be924f965215eb50ffe916e3b6b3a2beaea3e3ae4796545a7e',310148000,NULL,NULL,'f2b6fbf8a0d2d8ca5b7f837059d3d5d4e377606d715255ece9d66cedb1ebcb5b','d99464956518afa6624dc90f656d079802caa1c76eb2d9e772aa8970040e1e57','87097dcd7184644dffae712122826eb31106da11c88b06a22831b4c815a71503');
INSERT INTO blocks VALUES(310149,'526b3c4a74c2663fc04ed5234c86974bffddb7235c8736d76860778c30207b3c',310149000,NULL,NULL,'7cf62dc8d0f09332900b3d3faeb973c75f60e7118ba2f5ec25f9a1d02e5373de','52558ee553474563971226e34a885f407351bb8719984edcd02e1b61c0722de1','c5a0a65bd4d0ac87f483ddc5c99c4d3a1ff5a0e7b2e77748bd89bccf77ccf60c');
INSERT INTO blocks VALUES(310150,'cdd141f7463967dbeb78bf69dc1cd8e12489f58c4ea0a5dc9c5c01ec4fcea333',310150000,NULL,NULL,'773cd82211234feb848d9246f3e7da054bd0083d24aed81143cffc9c0dc00074','d168cbccee058337455508945ea9a6711fe53598f05ff778d0243a6082901217','d861ad114f6b45c106675dd5d62331b2201d56a2e32339210b9b380f6ed59ed2');
INSERT INTO blocks VALUES(310151,'a0f31cc6e12ec86e65e999e806ab3bfa18f4f1084e4aeb4fbd699b4fe284b330',310151000,NULL,NULL,'532dcd1eae2240e6117d592dbfde30600f391007daa8e233ff99cb26ebae995b','a8f58513b4f835e6df1bc73c9386f110139b630cb6ce821cbbf7879906b05375','91752e24d3996c96c854a31afcfa6fd7a2ac0c10352cf1d9d7055754de417703');
INSERT INTO blocks VALUES(310152,'89c8cc3a0938c63a35e89d039aa84318a0fc4e13afac6beb849ac37140132c67',310152000,NULL,NULL,'2c5346c3aab989386ee49d27c30939760b6ff2eddad88147a715f0b4346f5c81','cd2ea31d0c17a90542e41a95e5951a72188da346ad9e0b4f8a59803c2801c6b1','6a743c4d80af01e8cffb1a1dc7cc7a1d00364445aec522d308a62de8c8ae232f');
INSERT INTO blocks VALUES(310153,'d1121dfa68f4a1de4f97c123d2d2a41a102971a44b34927a78cd539ad8dca482',310153000,NULL,NULL,'2662192765845a97bc1bb97f4b8b0a1d8c73d6c4a57ba6a36062bd75094131cc','822c0b316f906feaca8d887616d7d9e6733830467125116a36ea614cffaf2667','e04de2090a6e9d211b4dbbbc94358b572e592fda4bbcf3a5a50eb04e519b81b3');
INSERT INTO blocks VALUES(310154,'ba982ea2e99d3bc5f574897c85485f89430ae38cf4ab49b7716ed466afa506d6',310154000,NULL,NULL,'662789c8199a23fd244f020fca7cf70af20e9792dd66801ac0cfe5a871279fc3','ceaad3f3d823756c6ca3d8b0d37a28dd66e0be3ce055a77227c7be775c4acc2d','5a7af0b7b7c8239ef5d433ef49afee210276b900546d555ebf6d36a75c43ba22');
INSERT INTO blocks VALUES(310155,'cefb3b87c7b75a0eb8f062a0cde8e1073774ae035d176e9769fc87071c12d137',310155000,NULL,NULL,'6db116d18753ecb4c147346942c7cd41f3ddcd0b8b5300c8560c6cf2a1ff2b0e','0b4fc5f22ea0590e213756446251a29dafa48f2196180641435494bdf6c91c40','338991d76a433c84b2c514ce88d28cd27876173acb2fb37069419fe544d10b50');
INSERT INTO blocks VALUES(310156,'6e3811e65cb02434f9fde0445a7a2b03fe796041458737d0afcc52208f988a83',310156000,NULL,NULL,'18738df90f8ad63adfea0d45249c8c11e3429badec69f9d80e4d542ad78af26d','212cd1752120cd9d1e6d1d7ed9ce630fbe7bdae613fbe42844c14d5785cc7041','a96ccdc64031fc0917c95c3a08014d2efee0f22f01db69cdc891c9380ef96d93');
INSERT INTO blocks VALUES(310157,'51dd192502fe797c55287b04c403cc63c087020a01c974a565dd4038db82f94a',310157000,NULL,NULL,'41d6b09f49e434e7cee1c174880a19624f796685d18cca88049572cc924240e6','817e88b61368c13c8baab10b50915bbb2924d9a29b3ba337545b2bbcb8667916','d47dbe4c0f91499cbab3e68565f3a7d001a695b41a06c9a97010b0d7b3073d4a');
INSERT INTO blocks VALUES(310158,'749395af0c3221b8652d31b4c4410c19b10404d941c7e78d765b865f853559d2',310158000,NULL,NULL,'4c436a14a5f2fb45f9525122d91559961c5ae92b182d1458f421d72b8689c555','6a416e11230f4090ab6845054ccbe7b89b9cba8be8d0cbb05270bac23d60ecd1','3aa603331aa64917f8ca6d7085a21cfce6e5714c34c47796b7dd7d955e464ef7');
INSERT INTO blocks VALUES(310159,'fc0e9f7b6ae99080bc41625588cef73b59c8a9f7a21d7f9f1bf96192ba631c12',310159000,NULL,NULL,'9f3c424fdc6eaf4fc11fd4bf6d389af9aaf82dddeb378f050446ed0f191c415e','c09974e9580781d4b7394f91788494e72ad520c5fa7a723b2c58cf58394646b2','7542cdab7f7731deec73b4ad7c85a42bdb86e7f0ea7283f043aa9c5a9d41c494');
INSERT INTO blocks VALUES(310160,'163a82beeba44b4cb83a31764047880455a94a03e859dc050da782ed89c5fa8b',310160000,NULL,NULL,'7a2c16fb611558b70b31f8f12c6d0ee08f0c04d6901f5e674984407400dc4f7c','3cecccf08fad7017fc9ef5263f41442acd80582ee629497e4922c2ab59b4d2d3','40bc3a42cc288b59872bcbbd7f7ed95811c808c91f1a13132201d320d57e247f');
INSERT INTO blocks VALUES(310161,'609c983d412a23c693e666abdea3f672e256674bf9ee55df89b5d9777c9264d8',310161000,NULL,NULL,'b8566b51d69aaedc491add41ea3a4260406b04b8d417163c9122b6d46b23e043','1b4021b536855c02f53d6978568498ae522d535bb93c1b49f4fafddfc3e181a4','9728ccc157ca1060241b8dc0477bae99dc0d651fcc0b4139e87f39609c7f4b48');
INSERT INTO blocks VALUES(310162,'043e9645e019f0b6a019d54c5fef5eebee8ce2da1273a21283c517da126fc804',310162000,NULL,NULL,'8bc4f34f2ff6ee796a9ee54cc8e3374136a2226343ad506680ba94a04a74efdd','def2a43b2dd235129d659b774b87772244b728e20eb28c4920c1e6d90219edb5','84e2e77f165e54c95a05737e459112a2c933f4ac4d92c71a91e7ffb28b61b78d');
INSERT INTO blocks VALUES(310163,'959e0a858a81922d2edf84d1fbb49d7c7e897a8f49f70bd5b066744b77836353',310163000,NULL,NULL,'d5b71a21ec5123be72bf29d699facd204140d1863ac22ef9973920a7f4fc0773','b39b92d81b3ddf616630f39153501346bec7a66836b52b9fcb0bd6ec13cd14ee','d4bd744876eaeb4f45c75ee910d7fee5110b38272628b2bc123c2b089541901b');
INSERT INTO blocks VALUES(310164,'781b7188be61c98d864d75954cf412b2a181364cc1046de45266ccc8cdb730e2',310164000,NULL,NULL,'2f8c3ed867557c8cad28de08cf82fa2484ceb8f7d7cc26fd5c68e15019ac5f87','ab8d10731e632f46a02b4f7d1d6af8215200a0d69d7810ed8f9d5b854e31999a','5be4815bbf9b5bd549fff2b5f723e20b4aabbc220a66b50758fc0e0d5b5de222');
INSERT INTO blocks VALUES(310165,'a75081e4143fa95d4aa29618fea17fc3fabd85e84059cc45c96a73473fc32599',310165000,NULL,NULL,'eedb0e236cd48b9afe186b5c34002e4a17679ab7b10ed8c0854d2683ea7b4df0','c2cf6dce26b10eda14cdb80a8b9d903aa7bc9d2f84a3e498f60913dc232100a5','edc1632b51b73ff4695e4fdd5af43645a631b2f0733900aaeb11386d7c5eb9b8');
INSERT INTO blocks VALUES(310166,'a440d426adaa83fa9bb7e3d4a04b4fa06e896fc2813f5966941f1ad1f28cfb41',310166000,NULL,NULL,'392df958448612ffdfec7f6aea1d3fa37c6f15147be61667bca1f16ba101050f','a7d2117f864753f3b37e622ba9abbf5a11a1792dbcac0519634e1d79b9a17453','edb18c0805b6452d7908edee2eacc747d3c8d4437431981f1e6b06c6efda7d62');
INSERT INTO blocks VALUES(310167,'ab4293dbea81fedacca1a0d5230fe85a230afc9490d895aa6963acc216125f66',310167000,NULL,NULL,'2d0a69eb324f085f3b36317d169902be8d4c40707c8afe2ee5dc56c104020990','621755993419e5b93965aa663ce88051c46571e535329f743a8ec3b08720ff25','2ef9ad2dcf6a8a069d22b115c1020581c7abef7219a433e1eb0275092c83eebf');
INSERT INTO blocks VALUES(310168,'a12b36a88c2b0ed41f1419a29cc118fae4ecd2f70003de77848bf4a9b2b72dc9',310168000,NULL,NULL,'9339de42b016d558c571ed1b4a907a337995380951d1652c36cf9685d6d063d7','df6a17f48aaecbbb93803fa4f05224518cedbef9dc70f33c2b56a044ebb50725','85033b31f4b25a54a976a05c93f73d12868a07aafc072aee916b08c435fb4477');
INSERT INTO blocks VALUES(310169,'204809a85ead8ba63f981fc1db8ae95afe92015f003eaebbec166021867421f3',310169000,NULL,NULL,'b0cc29ba6075a4519388aa13b2ed8ac13e779414c50a2b0a048794065eccdc80','10bbdde069daa1ea7c92bcfef1d6f39fa5a599ac8498305cff5e2ab84b0e0c3a','09015ad02d4f21c20bfb20bb15975ecf0c4f6b51678fc40cd0c26c13e108f2e4');
INSERT INTO blocks VALUES(310170,'b38b0345a20a367dfe854e455e5752f63ac2d9be8de33eab264a29e87f94d119',310170000,NULL,NULL,'d342b3a0badabc8a47a15d695f7c877b54287645fd8df0d560177a57c7f0db3d','b253f8b250b089916c8974a224e859c8997454363ab4253234e37adf3eac5965','a3a761501578b926604a5bf8e9a1f875c3073a2e5281d07848eca32368398134');
INSERT INTO blocks VALUES(310171,'b8ba5ae8d97900ce37dd451e8c6d8b3a0e2664bb1c103bf697355bf3b1de2d2d',310171000,NULL,NULL,'c994a2733d12b3e28523f9ff8edc162f54f9218565c8ea5d4d100441f0477d02','b5659fe1bd3e56a9d8b5a6d2808f17b17bfd6404602714a361052a80e59ecde6','347f27eacd109f87a63f99a658a3cc1a02080ea1d86c24820388feec36f218f0');
INSERT INTO blocks VALUES(310172,'b17fda199c609ab4cc2d85194dd53fa51ba960212f3964a9d2fe2cfe0bb57055',310172000,NULL,NULL,'397248fb2a54f0570de5b24e9375263f3b54359727077a30227931c1052dd9b4','46e2bc54c180d916c369b8b670eac86bc3885d5371d5f32315b1d16279d0f173','8bb9cfa13b16906d31ca1eb99f68811acfdb952832b02837608772a5946844ef');
INSERT INTO blocks VALUES(310173,'f2dcdc5ffc0aca2e71e6e0466391b388870229398a1f3c57dec646b806a65016',310173000,NULL,NULL,'66d5758c943c8332f1491005e13ee5a906a80e2af7ab8d37b236d309756def31','e709b8e1665b78340ceaca213798273c877b36a594167dbdc602589fb3cf0725','4051a03ee0fdc6efafbe8daf26f3b2f0e9c5574865ec84cddafefde229377835');
INSERT INTO blocks VALUES(310174,'fa6f46af9e3664353a473f6fffce56fa295e07985018bface8141b4bf7924679',310174000,NULL,NULL,'f45eb0d49b4498017519bafb08cb7e31b5e633391b1c748866a443df5004f53d','c7d44225d290aae154d8803e88b47ee907021fee949f2cbba60a39bfe501ef31','e86191d8fcce95eb8254f83a0d8c437d38b91c6909ecd3863c561316dd04060d');
INSERT INTO blocks VALUES(310175,'f71e79fe5f03c3bc7f1360febc5d8f79fc2768ce0ff1872cf27a829b49017333',310175000,NULL,NULL,'5f9cd3d5d4d3d9dce35bd3e76f8530c7dc2992a97785149011a39f76dc9f3b88','415f6a3f2520146998c06182803673b393e9d1a5ec9eff52c1a17c52c0e57768','162798f14788a8dfbf0054dd91d1546a354de35507e86379c945bcd8b7077f9e');
INSERT INTO blocks VALUES(310176,'67cd1d81f2998f615602346065e37f9ceb8916abb74b5762ead317d5e26453c6',310176000,NULL,NULL,'34471b4af7737e7024fc3762d0e37a98bf12b619fdb0a4ce110bd2950e3d3bc9','b4631afb39b6dbc4ee4e71627043d435585c0c8c159aa8b373f6f9b192571ab0','e0b173c62d2cf09e3cea5ae6f26d802536230a002f8aa073edcde510da84305f');
INSERT INTO blocks VALUES(310177,'6856b1971121b91c907aaf7aed286648a6074f0bd1f66bd55da2b03116192a52',310177000,NULL,NULL,'e1352b09b865ad48fe35f2a71ac1d1c188bf0f4ad7aa4ae37fd06027e556b2ba','b27421405f9c9cf4e2b08416b1f55c4939a72e39be492339ae75343feb864ccf','4c226a42be4f0570d5a7ad1b9fd5ea534c23c8ac328ecac637f7638c6a1cf3b7');
INSERT INTO blocks VALUES(310178,'8094fdc6e549c4fab18c62e4a9be5583990c4167721a7e72f46eaf1e4e04d816',310178000,NULL,NULL,'3b6ad6e8a04f803e70f6e366d16d30b2179d1624a93db041c33cf4c4d28dfcf6','8b69aa5632c2b766396ca943445fa52777abf7f29f8f5848ea91792092674f87','31d573e0483db1bdaf00013fef3e58ad3fa2eab38eeba1207092d1746cc7f220');
INSERT INTO blocks VALUES(310179,'d1528027cd25a1530cdc32c4eaff3751a851c947ddc748d99a7d3026a5e581a7',310179000,NULL,NULL,'7f574d5c3d785d4070e92701956755101bd86949141b57fc4e585bd6bd2ad56d','17640fd703cb7a033bdd3be305a71c9dbd6d8c213c5c1aad2442c5de55bf930a','b44f3c6cdca4eb800353f585084bc77226670423d345e077f475204808e8ee6e');
INSERT INTO blocks VALUES(310180,'f2f401a5e3141a8387aaf9799e8fef92eb0fc68370dae1e27622893406d685c1',310180000,NULL,NULL,'9705d812c0cb4ca03e52ccb28a01522caef3cf41df45e7b52c32267a93517dae','f890c5e42acd42292ecbaa687112332a75ddfa8ee6497e45e3db3dcc525a30b2','6fba57c9d8dd2ad907934c85aae35a18b7a80b6770a1f2d1b43e400f4216fd08');
INSERT INTO blocks VALUES(310181,'bd59318cdba0e511487d1e4e093b146b0f362c875d35ab5251592b3d9fed7145',310181000,NULL,NULL,'808802d90ae3381feee9c5ed979e03970330135a60d9a270c719cecaf805764e','0856fd78b755ec4d637001e0d766a97c17c1fdb7a3c792e4643ef171c270f552','5d6b24ac22ea0268ad525c28a029462da73c1597f60e59acb46ec2b7ab0c6319');
INSERT INTO blocks VALUES(310182,'a7e66b4671a11af2743889a10b19d4af09ec873e2b8eb36949d710d22e1d768f',310182000,NULL,NULL,'3e8246c907b75b7dbbf1a07b044e7c146c6d802c52792ba26b0085e399653932','6b4053c02b2249b94ca4a6340318f95cec3ad5d2f0caacb40902db1d24878322','5485a9cf68564b91ea6f6bade153b3ecfa9b7c726a159b9dffcfa9f47c2dcbb9');
INSERT INTO blocks VALUES(310183,'85318afb50dc77cf9edfef4d6192f7203415e93be43f19b15ca53e170b0477bb',310183000,NULL,NULL,'c830f4f39b35688655f8d3c3dd9314d1d8fe3a1aa2810ef4ec7cc51faac676b0','4db884ca08713dc3cdee78b12d082eb9412ce9b8cc1d54b6f0fad9f3277150ba','c45fc17b106e0d4b8238079cc81ed6435b4728ce35ad51b611c93c781f7b597d');
INSERT INTO blocks VALUES(310184,'042a898e29c2ebf0fdbb4156d29d9ba1a5935e7ed707928cb21824c76dd53bfc',310184000,NULL,NULL,'499aa926aded967f6261ac213391b5498edb855c21ffadf25a0c5ff8378e9a91','333345fc136ece0f8a0f670cce139d4b9d4c58e1d8568b4601f1b59690f6fa6e','88db88cba0b7ca3b99a1fc1d1e87da617b4e8ec634814758977436eb7262e3dc');
INSERT INTO blocks VALUES(310185,'bd78c092ae353c78798482830c007aac1be07e9bc8e52855f620a3d48f46811f',310185000,NULL,NULL,'22798fe864fc015e0bcaeb760823342dbc7a9756d153cc428929b8945c6e6fe5','6b3acf8aa791f6ecd50bab48a3473e00f7dd2566e826b644c5c9de41308ae85e','282de9590ebaf7812e2f9f46ea80cdff58e3a86d955ac9c83152b15826e6fd9a');
INSERT INTO blocks VALUES(310186,'e30a3a92cc2e5ad0133e5cee1f789a1a28bea620974f9ab8fa663da53e5bf707',310186000,NULL,NULL,'6593028cdf86b5f3e65509b22955212d2b3a649741e439791c72b7e3c8734ad3','d59359b0555b47dac06700e632c05bcda2e1e256461a97040f0002ec614b394a','c08db47844257c87c93aa18b8485b688a139724464d9957d25ef328989e8820c');
INSERT INTO blocks VALUES(310187,'fc6402c86b66b6e953d23ed33d149faa0988fa90aa9f7434e2863e33da2f3414',310187000,NULL,NULL,'e49da111e3998fafb7929ce5f43fcb8de9b89aba6a06fab288ac8106e8c06c47','1d8130b671fce2ff644c94e38f13159a3b465e2c41af4445fe777ded39519fbf','902181677350579bd51598328b6ddfffa7f453e3fa90fdd8a3ee2a3086c9bd16');
INSERT INTO blocks VALUES(310188,'85694a80e534a53d921b5d2c6b789b747aa73bf5556b91eeed2df148e2ada917',310188000,NULL,NULL,'f36aab93a395bdb52168cca5be82b3d370073ac10a1eeda1e6769a2db96b8212','482f5ebf790b8d1c2a0e9efaed63658d69565b07ce87552ea640415897d1a9ae','fb353218ca7749fa748916f6f36c615ead0327043de8ccebbab6a4efbed13446');
INSERT INTO blocks VALUES(310189,'7c036dadf19348348edbe0abe84861f03370415ed2fec991b9374dbb0ca19a06',310189000,NULL,NULL,'caefec27a1031498981b5d4f0329dbc766eaad6f8c4230f4434dbc0440877109','ebe7cd33508bb361c1293d1cdb78effbd2398f87eb5a7e425d3b3d6134a64717','066887724c2539c0b7c0527372673203c7dda94886cc49ad7dc03a946b33c4b6');
INSERT INTO blocks VALUES(310190,'d6ef65299fb9dfc165284015ff2b23804ffef0b5c8baf6e5fa631211a2edbd8d',310190000,NULL,NULL,'df92ef8478fd68d4774b3e8cb83ed1a069fbc5e3d666a5e8fa462013f1b890b8','aa90ec3541ef1ba0d849d8d204c98053bb93d8b11bf4737f4400078a32489fda','9f4103dac666336131f18c8b532dc168bd808a732c353eda54c627b372df752e');
INSERT INTO blocks VALUES(310191,'5987ffecb8d4a70887a7ce2b7acb9a326f176cca3ccf270f6040219590329139',310191000,NULL,NULL,'87cd3ba6903bb0a5afa07255e569534845b926e6e3a1eeae7043ef15f695a788','d20dd3e1186b556370ddc5176b766f600e1630fad3fa9d7313e4faf9b48f164d','e26399dedf8cd7da4fa14ec8b58083eedd23d17d546575f71731e8ce3e547a8f');
INSERT INTO blocks VALUES(310192,'31b7be43784f8cc2ce7bc982d29a48ff93ef95ba18f82380881c901c50cd0caa',310192000,NULL,NULL,'93831212bdb388f4e2db36ca5d6ccda6fba1c401db7ed046f1cffe261569e3ee','59d06c7027ceb04562fad3d6fe1d8673709fe90998c48daaf005c954cd2dcb49','7f5b52a0f00f080bee374f26d14754bc0835d173bae7954ad71108502951c9ce');
INSERT INTO blocks VALUES(310193,'ff3bb9c107f3a6e138440dee2d60c65e342dfbf216e1872c7cdb45f2a4d8852a',310193000,NULL,NULL,'299f6e3d677e12c0f6d02b242ef82dce4e3c75402ffbee4f891ba777e160091a','e074b7d80aacf71bfb98b3913a7d20a349b524b57e5a2fbf8dda5a86a07c0af4','7abee9b516b7858a799f90e6c15f17f1f65c1bb602e6fd10560b3f2ae15aa554');
INSERT INTO blocks VALUES(310194,'d1d8f8c242a06005f59d3c4f85983f1fa5d5edcc65eb48e7b75ed7165558434a',310194000,NULL,NULL,'330c75c62d310d5214028311f19119b9aa3b413c1491067f8cf3567a1f37bae0','fb06e5bcb28958fccc069b17226268cc1decee245ad96014cf6ad38a8085d3cb','ee1a8c0dc1aa20f609ef724560f89aa9abd18e423854c2278f60d514f07717d0');
INSERT INTO blocks VALUES(310195,'0b2f1f57c9a7546faac835cbe43243473fa6533b6e4d8bf8d13b8e3c710faf53',310195000,NULL,NULL,'cb228e7c41f04f75bdb8a2a26e9848fd7f642176d4e3a6436bdeb61c102811be','fcf33ffcd256f1ee0d1469e2f9ae1d89bd98e1bde4499273ddb66609723ea4dd','00eca406754fee6835bfa1546bfdcd98a1e5adefd13003af41228c0674a50daa');
INSERT INTO blocks VALUES(310196,'280e7f4c9d1457e116b27f6fc2b806d3787002fe285826e468e07f4a0e3bd2e6',310196000,NULL,NULL,'d336a7f2e3bcbb067abca699119cb0b3a7d8e1cfb2081c6ac93d3ae1183474c0','4b4915a6998796caf063d7c06cc16cd85f8a5fc7f9c0521e92653a4bf1e41d4f','50911db28ebd69c8ad20bb000b17a3b51c9f0450e6be27c12ba54ac91132f0b4');
INSERT INTO blocks VALUES(310197,'68de4c7fd020395a407ef59ea267412bbd2f19b0a654f09c0dafbc7c9ada4467',310197000,NULL,NULL,'e1c14ab4ba11baa06f837c43575b058a38b7006c6ff272a0960f65d4232cd2ac','c2d48bf30f80c4780a69fc8638f91f3d11db8a3ea001bb68d911dbb9a10c2578','58309dd7a230c547e75aa458eb621fa9b6c313bb80012423d4eda63b0bc3da09');
INSERT INTO blocks VALUES(310198,'30340d4b655879e82543773117d72017a546630ceac29f591d514f37dd5b1cc2',310198000,NULL,NULL,'03c1bbb6d2b19b199bc13c902541db2cfa8ae8c5198d8271d8699ae0a08bba0c','f0fba4f388a0056ad5dff215cbed6c4a09189c55e52c6db95e2594dacf3c4853','084a480d8047289bba3ba17c73ff0df9f3bd20363a601d6092eed4b40806ac37');
INSERT INTO blocks VALUES(310199,'494ebe4ce57d53dc0f51e1281f7e335c7315a6a064e982c3852b7179052a4613',310199000,NULL,NULL,'7c998d1ebcd2fe1c91c9d8aa562bd934b67521b09abcb443b18e4bae4a3a5e93','852d916924ef27e7c790b57031108ab754a82a514a576f859e86c2466b1fd78e','1dbf4d22139840449dadbdc40f2a71e0bef2ae760f5b39f65f869a6480ece852');
INSERT INTO blocks VALUES(310200,'d5169d7b23c44e02a5322e91039ccc7959b558608cf164328cd63dbaf9c81a03',310200000,NULL,NULL,'12aa1d3ede45cfb999d785d21a19b20a0be4d51cf8ca7d78ecce47ef31334ebe','c9989930345b37d7e580c78166be149f7c8f8116bef6c9b33a74574c2f0ca7ef','0a962925b48cf14cd754ffd0275e57ca322510dbc647bf5045c8d0f65aa8329e');
INSERT INTO blocks VALUES(310201,'8842bf23ded504bb28765128c0097e1de47d135f01c5cf47680b3bcf5720ad95',310201000,NULL,NULL,'edb2ddade7ea48b2b5f57b57c8cdad714da2407c95e5776d080fd2af8e03214d','9df2e7e1ec711b637e3181f072cfc3d65475374385efd49e0920e86ce03a02c1','5eb4ea454468f12e8d12dd705b67af708efe9d1bb86f2fb380b7b980d0cc5bbe');
INSERT INTO blocks VALUES(310202,'95fa18eecbc0905377a70b3ccd48636528d5131ccfa0126ed4639bc60d0003d8',310202000,NULL,NULL,'2dfba901292506aad81b75494c6526cb388e21df3edfaa75062e42c3c96c9912','ec20bf9a5590b1ef97febafcd7d52421284bd6e99203485c22f13f7d5e4dc723','0fc629e7643efcc0aa93915ace22b0722772336f1709c6b5e21c775d549f0393');
INSERT INTO blocks VALUES(310203,'ab15c43e5ac0b9d4bd7da5a14b8030b55b83d5d1855d9174364adbebf42432f8',310203000,NULL,NULL,'f19076b8896c2e9f702909caaaea599d941e9399301691dd1c620c6b6c01e3c5','1a4ab86d8e1de1719db14eef68b757d5bc0ffeae7dd9912f5f87b315de77a70f','5783db08f0c6e3e09e563fc3ad20588bd6339567ee245e035ebdeca55039d815');
INSERT INTO blocks VALUES(310204,'18996fb47d68e7f4ae140dc1eb80df3e5aba513a344a949fd7c3b4f7cd4d64cb',310204000,NULL,NULL,'c2b4b4672f3567833f7689ee4a4f950255e68a3e8368772ab864828419065176','07a8ecacdaa7c4f7e94671c9165f542c8d94f3a8b76f7de414bc728f3fd2d8c7','ba397e6564c1b2cb29df98d023ec9be5e7862bec3608459b260c6863e0a79cfa');
INSERT INTO blocks VALUES(310205,'5363526ff34a35e018d1a18544ad865352a9abf4c801c50aa55742e71630c13a',310205000,NULL,NULL,'43b5ca2b4bcbfebc564cf99067b351e4d324875416c1e21aea828756e543b7de','97c2d08f3af890bbef911d032142801a8988b0ec3ef24f17a80f341e689b8063','3a7893dd7978929fdb4f7f18774eeff3e9346b744f3e7d87f1998be3a5f8e229');
INSERT INTO blocks VALUES(310206,'0615d9fca5bdf694dca2b255fb9e9256f316aa6b8a9fc700aa63e769189b0518',310206000,NULL,NULL,'d2e360af76dab6744571ae5f9ceb21d2aaad9b42d1c87ab5ee9549507233648f','8ac31f78bb7d7686f41a00c88f534199703c9e0bac7f0ebc421ab094efcc72f8','0aa09dab1cf80dfbfc79ad28de9a85178576e64edf797b3130bb6a59d3c06af3');
INSERT INTO blocks VALUES(310207,'533b4ece95c58d080f958b3982cbd4d964e95f789d0beffe4dd3c67c50f62585',310207000,NULL,NULL,'754504d3ac03899761a0d042496768cef714711afab73c76115ee62458b9b44b','de3e3d0e6ea8b57e677857f5f8fa384b627e2e24954a0e9180ea3fb49b65fa83','a517315ecdbd0b57421d929f82b1b75e777333523e9dcbd73120d90c713bffff');
INSERT INTO blocks VALUES(310208,'26c1535b00852aec245bac47ad0167b3fa76f6e661fc96534b1c5e7fdc752f44',310208000,NULL,NULL,'cf81663f37d9c353a124bb2a3e1cdf51c8eb0078aa511ada856c8b71b801cb9e','895b2cf0de7a42db27c9749aa5293f176d1a0d45f30a31e498ca294fce06143f','b7a0150a9beea7312413954363e959ea88292115ae899517ba010fc44d1d564a');
INSERT INTO blocks VALUES(310209,'23827b94762c64225d218fa3070a3ea1efce392e3a47a1663d894b8ff8a429bf',310209000,NULL,NULL,'c4200a6881e0ded18a9989140d29984c19d790527693a05be9c833318461cf42','77cd41758134f06aa062f855b51565e8447d99b6422b26f455b3ff4de3ab15cb','b7df2cdd6278052a189da303f5cbc61701cc52bf594a25f117c8b75340775ab8');
INSERT INTO blocks VALUES(310210,'70b24078df58ecc8f7370b73229d39e52bbadcf539814deccb98948ebd86ccc0',310210000,NULL,NULL,'4ba5e58a7fc651cbc58cd1390021b8d279a5153f114c4c518f1c3b363054046a','d41bc30a0eef9c70ea68d5ca2361ab187b48206b175729bbf2a5ef68f8c83b69','a3646ba6f5e2ea1e17ad8067d1369c591c0fb98345799b57e917b2ca23ad1df4');
INSERT INTO blocks VALUES(310211,'4acb44225e022e23c7fdea483db5b1f2e04069431a29c682604fe97d270c926d',310211000,NULL,NULL,'11b9e7cc6c428bbd840a8a3c2495b34a30067cbbc15589bf93eba016b477df36','ad2c7a9b122a249b55f2e62bda3e079e2d79e3e917e584cedce9cdacf950bcaf','584954f0bfbcab07694d1928fd7ffded93bb8f246e4e9d0824d15df41d4b0d4f');
INSERT INTO blocks VALUES(310212,'6ef5229ec6ea926e99bf4467b0ed49d444eedb652cc792d2b8968b1e9f3b0547',310212000,NULL,NULL,'6409a0f2555b872a92be674d1d4c09a9069350f649fa73e7db367d49fffe7347','d11cf29c815f4d6173a5efcdcfcf3fa3075e16c15431d6025f44a1ce057ee7db','d1e35155bb0db00a658ee9115c50659a2e5c1f65760e5bd2572ed7088c9e3924');
INSERT INTO blocks VALUES(310213,'17673a8aeff01a8cdc80528df2bd87cdd4a748fcb36d44f3a6d221a6cbddcbe7',310213000,NULL,NULL,'a7323e7ff6b0b41c30092fef6a6d2844a7671c4880aa050afd92ee690eb5e52a','d79bc785f74135b11341fab57b8910a0b2a6c087902784e5c22a92d93fcf2da2','d3579daeab88ceabfb850240af687b3dcce8c658afcfab5edcab4df808054128');
INSERT INTO blocks VALUES(310214,'4393b639990f6f7cd47b56da62c3470dcbb31ef37094b76f53829fc12d313454',310214000,NULL,NULL,'bb190b3cd299a892c05ec35beb187fd9ce925a84d9276f7da035d141c79cbfaf','a82e1578809f5e89538e04516f88b91bf3d38ff81080c96cefe2ebd662810814','13ad38712813ad142c16daf071b06864f61bfa47bdb43e42f2292486c90e300e');
INSERT INTO blocks VALUES(310215,'c26253deaf7e8df5d62b158ea4290fc9e92a4a689dadc36915650679743a74c7',310215000,NULL,NULL,'fb51d7881a295005a571902d0ad0be52ac2a69b6f5dbf2fe09607775940005a3','83c4b02558f11ef48be7930e33d49cd500dea54e919a1c22e39a2fc36db32c07','bb8f2b5eec6ec7028116a31703a203b0a9b76689be7fe5fac15747c51b9ebb49');
INSERT INTO blocks VALUES(310216,'6b77673d16911635a36fe55575d26d58cda818916ef008415fa58076eb15b524',310216000,NULL,NULL,'b920515215c8384cf04fd0341dece933924f778bfad4fb52a414a4301747a9fd','4be58b7629c8abcda0715e7a430d7e43ced01e64b3bdfee32c78d5045cc6378a','db8093dc21095c75b8362a60a80368e81fe7e31dd453f320e15826093b2dfca5');
INSERT INTO blocks VALUES(310217,'0e09244f49225d1115a2a0382365b5728adbf04f997067ea17df89e84f9c13a8',310217000,NULL,NULL,'5de885656c86c1a534c5c8b2f03c05b1e1c61d43e67051b8827b80ae7638c7a2','d054665890e3405412dbd8e88b12efa206c136748972ce9deae75155e7271b2e','bff93dbde01dfff9cf484d00658e7e0385571e9815f2203d88367c5b1a50a6f9');
INSERT INTO blocks VALUES(310218,'3eb26381d8c93399926bb83c146847bfe0b69024220cb145fe6601f6dda957d9',310218000,NULL,NULL,'bdde3cafcabd6ebcd8fa892b631919081e43c9f90a0f4b0517ba4a0094789346','c5c27b1bb36aa8ef8526535a126c9897b02a909b6be53253c7bb76c60528ed57','34696d54241e122728b047d4bbf5588353027901f13bef733ee77f83e02ba7e6');
INSERT INTO blocks VALUES(310219,'60da40e38967aadf08696641d44ee5372586b884929974e1cbd5c347dc5befbf',310219000,NULL,NULL,'cd639a6b8b43be7a7fa6ae603abe3bb8b0ed4a257daeaa27e38566f74ac6bbec','7a7e2be61c7cee939482fd50486e2b06a794aa225a27d42515944e0491d336aa','ad1ab4f1375b6703d57d5758aa3df230806c30243041c2e0632efaeffc4d72a7');
INSERT INTO blocks VALUES(310220,'d78c428ac4d622ab4b4554aa87aeee013d58f428422b35b0ba0f736d491392ef',310220000,NULL,NULL,'50a93f2a30dc4638ee1a2fec501c03be0ef2260dff4fffed32c460fb9331276c','8521aaa29c753266731821a6e4bcf62374195ea6d0a161f1089928e359f3ccc0','204b5b5278581f10acb3f1cba99ec91ad59d55d93e2c6b7747e1885c2ddc4e99');
INSERT INTO blocks VALUES(310221,'cf5263e382afd268e6059b28dc5862285632efe8d36ba218930765e633d48f2d',310221000,NULL,NULL,'6c62946096ecb97d62135b6d1703d318672d47a57d20f0b546cd475b1fbed4be','9556c660b377082bed91fb4e6afba612aafd3e024bf8e0a801c5df11bf387492','78908b569b3aa9ecd77faf829b880b18cbe7ba9c8488775d5b5b6c66597bfaa5');
INSERT INTO blocks VALUES(310222,'1519f6ec801bf490282065f5299d631be6553af4b0883df344e7f7e5f49c4993',310222000,NULL,NULL,'0b55f261f42f9ed634acaf1a3fa54a84c8c2c53b0094aea83b8c6c47df41f808','bb5538df2d6ae6b39970875682f1946f29587e2e54a05f92adc7a49d5b74eb57','dad36c01874840f9fd53bf72c9c8f799eaa446dc44a6bc67a7b45d1681d03c72');
INSERT INTO blocks VALUES(310223,'af208e2029fa49c19aa4770e582e32e0802d0baac463b00393a7a668fa2ea047',310223000,NULL,NULL,'db80e32a9fa70ac3bda0a68ca6aa70d0d945641c4dc8a974618bcc3bd2323e71','e7706428bdb20c4f327ee9774ce91be242b73da5a76bebb43ffdbee0f21cdf1c','14afe2c7015e0adbc3cd92cd234f8545748f70cb18f79928e01acc3761ffc87a');
INSERT INTO blocks VALUES(310224,'5b57815583a5333b14beb50b4a35aeb108375492ee452feeeeb7c4a96cfd6e4c',310224000,NULL,NULL,'94251828d3eb2547f2ff3466d54dc779403540b3d295bb3a838c2c65dc47cbda','1b3f3739fc95b8aa7d76172c68cbf90e00a3bb12d931de9bd0a02f6c1becc8c4','41fcf1976f343d4bc02b2df6b88ea3822fd9a8617dd5ce734c37061c26b2cff3');
INSERT INTO blocks VALUES(310225,'0c2992fc10b2ce8d6d08e018397d366c94231d3a05953e79f2db00605c82e41c',310225000,NULL,NULL,'0fa47a3e0c6c7a10af36dc052316e1a33139a05baec4ece20eb1d7a3b702b6ca','c703afab6947b0ac319b3294fde5663bb1e45722bff8ef676dac1b0dc8b5e98b','db0a6891f7cf3165cdd31c8d5ea24d2faadc429123f69d7273a27849fddfebe5');
INSERT INTO blocks VALUES(310226,'b3f6cd212aee8c17ae964536852e7a53c69433bef01e212425a5e99ec0b7e1cb',310226000,NULL,NULL,'c825070506d055275302ee19f98f69e7ebd58e4f3d297b1b56026cd81ca6bb71','a95d836a45c97dd0dcc6740b556dfe4e50a1e9ca0c031fd11027fe4245bf925b','46ead5470bd6b4f524d3f86c0e060ec03a40cb008981ad20061b1e04352880d5');
INSERT INTO blocks VALUES(310227,'ea8386e130dd4e84669dc8b2ef5f4818e2f5f35403f2dc1696dba072af2bc552',310227000,NULL,NULL,'708f1b03edea6a7ba53b161c91d82c83e7fdaa39e28977cea342eb05395c9fba','93e95a176de1b875d618bf56d532b5fd24e31d144b07973658b756d5453a50d1','96f2c51800d6449c1c16ca845b9b6674fb64a9b7deb3bb1b9c614af1100c8864');
INSERT INTO blocks VALUES(310228,'8ab465399d5feb5b7933f3e55539a2f53495277dd0780b7bf15f9338560efc7b',310228000,NULL,NULL,'26cd9f3486d1ab73536ad3237ad0b9ac550121ff6e9051d933b4c556394867ee','0f8635b691b96af281f7d6147d76477e23e12741b64b1c7771683feae335f5af','e0aece304e2b9ea8d8d71de33d179b51c05ff73237b4908b55f9b48f6fedd747');
INSERT INTO blocks VALUES(310229,'d0ccca58f131c8a12ef375dc70951c3aa79c638b4c4d371c7f720c9c784f3297',310229000,NULL,NULL,'c4064516fdd94948922ebe20e834f3cad7fbcc44e8dd99b0c6ff1a80a41dd296','9ad1d9414a8ea564141bf53aef7ed0dab49a9f3db74ebd6d143a56bd9f334dd8','292d4518fb9b0ca55e07169d45490358e217353a50517b230c416d5bd7758de3');
INSERT INTO blocks VALUES(310230,'f126b9318ad8e2d5812d3703ce083a43e179775615b03bd379dae5db46362f35',310230000,NULL,NULL,'919f82a675cc2747b52d53feda9bc3db70df0a626cfc6db7734282145997424d','fd3353d636e738061861c80d431712279085ae59995790874fbff76f95f93026','e9f3ee42a65525d87b7c3db0544e3b34796b645e876f8b289f2d580837e46312');
INSERT INTO blocks VALUES(310231,'8667a5b933b6a43dab53858e76e4b9f24c3ac83d3f10b97bb20fde902abd4ceb',310231000,NULL,NULL,'b585efdca8b230d5d0477e27e33c46bdae4d4d13a320f72d48553718c82619ab','b77d23dca5ce4e8f82383584554b2ec57ffb9a4acc4c522b0ecdf7ace84faaee','e79fdad4c575b09581107e3e6aec0ba438db8db7e690eb6700ceff95a76ba407');
INSERT INTO blocks VALUES(310232,'813813cec50fd01b6d28277785f9e0ae81f3f0ca4cdee9c4a4415d3719c294e8',310232000,NULL,NULL,'61ae8d3c6bc169cfdafbd3a16c6b09588e7862c0d967c637bf7a81971f549484','ffa278fc896ff6268d002052246cd5f085ecb98e72377ecdd1345a21e047f2df','3511e6aebd200df871f715885f46b02064bc5d6f44ac4f21caf3b3f0d074a251');
INSERT INTO blocks VALUES(310233,'79a443f726c2a7464817deb2c737a264c10488cac02c001fd1a4d1a76de411d6',310233000,NULL,NULL,'ec03482b84af2c4e39d4ae39cb7eb08f2ff44bbee9ddfbae8526f28f619014c7','dab66f2713c4caf6d53016b4ea76a2c8e9ed6c135410e4de0f0246650a29f403','81ab8cc82ccfb85529d092937cb971e1fa30dacdc4abdd93fef4de8e1753eb56');
INSERT INTO blocks VALUES(310234,'662e70a85ddc71d3feae92864315e63c2e1be0db715bb5d8432c21a0c14a63cd',310234000,NULL,NULL,'752d6e11a32e9773df8c8caf6c88dc976d1b2ee83bc7fe83ec92a13d906b3fb5','e21ee5f76bcd14efe287f9330c50a1ba88a735d15a3635a8bba10fea40a3838d','0c1fa418f1d3a9b0e224425ad77991888e38f5290f753404a56246102da32b2e');
INSERT INTO blocks VALUES(310235,'66915fa9ef2878c38eaf21c50df95d87669f63b40da7bdf30e3c72c6b1fba38e',310235000,NULL,NULL,'2623f294c75796eb33bf3bd54dd60cd1f388df5e2a2bd611925e0b4b2ae54034','7ab6ef4007f7fc8213407c489900ded6cee41c110b89d21a98d06f5bc0842786','10b2eb4f14a846352ffa1cf48e40b6cca417b163c3493f1b174b44db6beca05f');
INSERT INTO blocks VALUES(310236,'d47fadd733c145ad1a3f4b00e03016697ad6e83b15bd6a781589a3a574de23e4',310236000,NULL,NULL,'4ab86ec570c3137acb69947799cff3e2b9ed259614988c414579eb2ba78db253','5ed4c36853e11ae7bfd78d5257b4a6220da6e50c3efe2efdb8227cfccaad18e3','0851c91410e8236bd9d5cbc25ad955196073e77ebabd3ef3387e4a2f6b97039a');
INSERT INTO blocks VALUES(310237,'2561400b16b93cfbb1eaba0f10dfaa1b06d70d9a4d560639d1bcc7759e012095',310237000,NULL,NULL,'b43837305599670c0351c467d42ee01dd2d4db9739e70956fb1e2c2ec29cae59','d6e7a0d936f94355f97a67852c32fb914cec2dbed3aa98b00298303eb38b7eb3','b16901347e4a99726fd53c33f513051445457a122273b6abf820f8a091063b3f');
INSERT INTO blocks VALUES(310238,'43420903497d2735dc3077f4d4a2227c29e6fc2fa1c8fd5d55e7ba88782d3d55',310238000,NULL,NULL,'d6ac59104a8bb1c9bdeff28e3d79aa227b2e36452bb393b2010c07c49989bb3f','d9987022409803a5c951f92de2319538d372a1a945530000a064a3a8cfd7d40a','5191ee6a6cac5487e758f51fbb0ed0efb3bf1b63a3bdedc1a050a956d6782819');
INSERT INTO blocks VALUES(310239,'065efefe89eadd92ef1d12b092fd891690da79eec79f96b969fbaa9166cd6ef1',310239000,NULL,NULL,'6d324be1402bcecec8636efe1d296abeaf180ca3945cafd4640588abfc2fb622','9b60a5ca377ef31819d0b275c4f0bfadc9ca44aa6093dc198817c3554f3a3733','762db08d03295110e5476d02aca25e15a515efa8f9a4d32cbf86f1a3dfd76665');
INSERT INTO blocks VALUES(310240,'50aac88bb1fa76530134b6826a6cc0d056b0f4c784f86744aae3cfc487eeeb26',310240000,NULL,NULL,'3d9a97e083b433c84bf35926f985fb39392e99eaa987093b5558c6d51c0c3257','2c57d3415cf8b2e025c75d1099f2199a1a1cebfff1909a035f7c2f7f4089ba0b','87a553d9a9fc2a561b7e97741b8ab4f1938e41d616d75894b0f57b50e6164665');
INSERT INTO blocks VALUES(310241,'792d50a3f8c22ddafe63fa3ba9a0a39dd0e358ba4e2ebcd853ca12941e85bee4',310241000,NULL,NULL,'744238a23bf617d1274d894e2d987ac2bd6554dff98ca81cd198928d918c3a4f','769d14f7937c90ad429c5cd0427b51bf67b41b9526c6419578c6cb9dc4692a7b','f2768981ee920953db08433aeae958ea3cef3a74edddb3169af3283d26f52f3b');
INSERT INTO blocks VALUES(310242,'85dda4f2d80069b72728c9e6af187e79f486254666604137533cbfe216c5ea93',310242000,NULL,NULL,'4a834e1435a3a530c130278639a452b963ed8ad682b7e4ba40bbef3c0884970f','7a6f29940592e0b8731ddaf592ae010e9c631e93ff9f874cf5c4d3399d1dc5a4','1d8d8a925b1edcc67774d633e077fc81a7524f9c841f7ad1c263b08ca521d824');
INSERT INTO blocks VALUES(310243,'a1f51c9370b0c1171b5be282b5b4892000d8e932d5d41963e28e5d55436ba1bd',310243000,NULL,NULL,'3c38948a1daaf2c44679c03c232d867524623c0af54c25c58ab80141629a3411','5b1be956d9685548fcf0a88fa9413b115e795567eb1d3796b853d10574279d65','303a89c24e7362628ec043875ca8adcc2d4977d4552b089f92c13ece37cf78ba');
INSERT INTO blocks VALUES(310244,'46e98809a8af5158ede4dfaa5949f5be35578712d59a9f4f1de995a6342c58df',310244000,NULL,NULL,'40e163a4b75a64a4373d781d42af8acb0a7357208facab4f670cc80bbc352288','de3202e843cc792b05429676b30be828a386b677582c871751c9d61804cebc58','38389dc125978d205d564ad80b34bd03874b26ee874e1275491a48ed51713498');
INSERT INTO blocks VALUES(310245,'59f634832088aced78462dd164efd7081148062a63fd5b669af422f4fb55b7ae',310245000,NULL,NULL,'a80e1a21f48ebe40e4d1181fb5779c2aebd334a7480455720d8dc91420adc48e','426f7b7a81575ea3548431e698da64380b5aa471ab463f3b54833360e6421baf','6880346d95d6cb6836371dd263dc669bf1fd298d639127224b65d37f9aa02770');
INSERT INTO blocks VALUES(310246,'6f3d690448b1bd04aaf01cd2a8e7016d0618a61088f2b226b442360d02b2e4cd',310246000,NULL,NULL,'b3621966a7f1df8ba2e3150d9dc04e7c58784e05c09fbb47c0f94af6324d42d7','400cc0ce487d0ff29c803b991e54fa82c01f59dcd8c56f295f6beb2023a45785','9a44874b9e8479696ac2158e7e575859b80292738ea9e51b47bb76c895df0ee3');
INSERT INTO blocks VALUES(310247,'fce808e867645071dc8c198bc9a3757536948b972292f743b1e14d2d8283ed66',310247000,NULL,NULL,'16c29dfb1ada9a941e4d65651e6ba662eaf0d32446390014494811af709daaae','f9aca3fa6b79da0cc717cec746fdb83cb5e952d09f184bfca222cd8015431f78','ec91d714481c56a7cfbce406781181a451b166c17305ec1d9c11de0f873bf21e');
INSERT INTO blocks VALUES(310248,'26c05bbcfef8bcd00d0967e804903d340c337b9d9f3a3e3e5a9773363c3e9275',310248000,NULL,NULL,'46a1d502bb61030ab25f990e1d4776fc91074dd798fc6cbb86061fb5f0dc3279','d901704ed0686ecef8a346de1fda44549b4481c00f641b8d96a108c3cb2f9cbc','b3534a764da3a8ef909fd7b5709eb24e7531f6d32163fa43cb6b5229da27e0de');
INSERT INTO blocks VALUES(310249,'93f5a32167b07030d75400af321ca5009a2cf9fce0e97ea763b92593b8133617',310249000,NULL,NULL,'bd30958dd32410059f89b5d1ed05dec1fa7d4a1ac5091a9c86d37438c1daaea3','0903d6f43d25ff151e10c57eacc4aa03f6d8fe5a82401743280272714c7446a3','e5209d5e3f1396ede0479cfbee4a7cdcbe170bf9cd69afac38319c58e65a0ca1');
INSERT INTO blocks VALUES(310250,'4364d780ef6a5e11c1bf2e36374e848dbbd8d041cde763f9a2f3b85f5bb017a2',310250000,NULL,NULL,'593844275ff962ef32ae358957dcd7c4578bc155bfd88cb6ba2cb6db7e4bdb73','6230167e97f9b002234568fc539b3e49baddf9dbaf6475d0676d9dfbdc168967','b6d9f8e1941b79bd0e7181ea44be02c473799de859de83be0a2a7fd50e69404c');
INSERT INTO blocks VALUES(310251,'63a3897d988330d59b8876ff13aa9eac968de3807f1800b343bd246571f0dca7',310251000,NULL,NULL,'00790d2383678d2627b583eda36f39bde92883829b93d2628c741cf469cbc337','e9e96859be9e3d614b7e9ba989baa63b041c07fb4fc6a8fa4445aa7f6b5752a6','a5a79855a3df03fceb2b1d35f349cdd714311c30e3343e5499569df66bae37a0');
INSERT INTO blocks VALUES(310252,'768d65dfb67d6b976279cbfcf5927bb082fad08037bc0c72127fab0ebab7bc43',310252000,NULL,NULL,'51238eda52d2c02906de13b4f240b2560234e6733a78658c9c810f3b0da7f1fd','1dff3b096b3e66db9a4a24c9d2bb1fa021b4b46cdf058dadbdb3b7721f24d070','7274d790b4d7ed56eb746d47b2898731bae578ccb4d4a1e3fbc9a1fafe396173');
INSERT INTO blocks VALUES(310253,'bc167428ff6b39acf39fa56f5ca83db24493d8dd2ada59b02b45f59a176dbe9e',310253000,NULL,NULL,'78bb0b7368a4a11f6f6e82374640dff9a15212a34ab009842aa330557458412e','b845de3fb51558eb79ada6a4af763979fd4ed29b132cbc9f16ac6b8e213b280b','77a7efe0f4b8f4d990920f02bef1ff3eda0b9f8cf241ffffb6f000d2ec4b6afd');
INSERT INTO blocks VALUES(310254,'ebda5a4932d24f6cf250ffbb9232913ae47af84d0f0317c12ae6506c05db26e0',310254000,NULL,NULL,'dd78d671bffc09ef422a2e78f8b86c09f9d857e9612b1012a4c1d34e9a904568','49171ea22ede2a32b77b8fec36c1b783db9537e30001a269488a86b6002ee7de','0c88a4b444574243bb6c1fcfba99eaf06a3b102e7ebf9a5b0ef8895db1fe435f');
INSERT INTO blocks VALUES(310255,'cf36803c1789a98e8524f7bcaff084101d4bc98593ef3c9b9ad1a75d2961f8f4',310255000,NULL,NULL,'5e234216c346a42fa291f82db4a4bbd4067a191c5943bad6d289119e04f1a457','91d072bda7db29d6b536037b947a67eb22e39f25a3e2a091b341e36296f354a3','6069faf648ff54074028590431a04808a67cc45fe419601a3e6551a977b1d819');
INSERT INTO blocks VALUES(310256,'d0b4cf4e77cbbaee784767f3c75675ab1bf50e733db73fa337aa20edefdd5619',310256000,NULL,NULL,'fa2fd79c10830d09acf216e1d185848b6366f31bf61af06ca5ecf8983083404c','edd7d1f7a35f38e59c389a8b71efb2cba32879768bd90ac0f0c0547bacf1bb10','22230c239bb2b9b7cda07e748c64df38a710d4f0fb335e1e4826f87cdc3ec2b4');
INSERT INTO blocks VALUES(310257,'0f42e304acaa582130b496647aa41dcb6b76b5700f7c43dd74b8275c35565f34',310257000,NULL,NULL,'9fbe93ef51bf55fe68323af3338accd41728dfd4cdb1da3d6871d599fb5d27ef','0947592071f2e01f1c8eb742de59a776813aa126a83aba80401a4afbaf6393cd','37bbfc1ce771b8f2047d7cec4a21c972955921f9f5cee52520f61655978c366f');
INSERT INTO blocks VALUES(310258,'3a0156dd7512738a0a7adba8eeac1815fac224f49312f75b19a36afb744c579f',310258000,NULL,NULL,'200d17131d04a058c75c7a85b97e42fdc695854ee8d077f7b27fb20ec1412cf8','faf9494da104b77a5e4abccfaafee936e375eba5f2547c4af78f8fac76d272c8','e4e802a2d95e966c47db0a4b91c4d83789dc463d6e09a607a37c8384fb9c385d');
INSERT INTO blocks VALUES(310259,'e5ed3cdaaf637dd7aa2a7db134253afe716ffdf153e05672df3159b71f8538a9',310259000,NULL,NULL,'912c9422436d2169c0b7ff383b8bc523c5365bc3c1158d86e5ec7987ddcb0401','74ae792a267ebc15db8c51d4f483f8f7fafabb2ecf21ab8fe98b67ba3a57cf9f','56408ca42f4bfdea9e3611ffa0598932586410e29b4846217bd837fe2136bf60');
INSERT INTO blocks VALUES(310260,'8717ddcc837032ad1dc0bb148ddc0f6a561ed0d483b81abb0c493c5c82ec33cd',310260000,NULL,NULL,'931d3214d64e7daff87f5d70ac9e0dc1daebc1afc2334efd0512fdbad18cc4e1','341f60bc001d262c94fe88d86374abd2adfdabe946851daaa824ad77c5c52189','222e11dd17e8fda768c999a011c96abef92ce738f42793cf75034dc4fc2890b1');
INSERT INTO blocks VALUES(310261,'a2a9d8c28ea41df606e81bf99cddb84b593bf5ed1e68743d38d63a7b49a50232',310261000,NULL,NULL,'8fa1c2a7587e206c18066a671a64256e8fa9941c2faea46156cc0ff31a1646e1','0dc4f78d2483d73c8d6c22e4676515bb4397347a0936e6dace5fda188a92af5f','ce2beddbb2c55a0d72a23dbc1780674ff5b13a7392348beeff14c2adca2a33e6');
INSERT INTO blocks VALUES(310262,'e8ebcee80fbf5afb735db18419a68d61a5ffdde1b3f189e51967155c559ee4ce',310262000,NULL,NULL,'32c294546290e27a2433cf5c90da5c92e846ac95fb82f309c776c7cd9b5edfb1','cff977ffa2d80ac2aceacbad7663545a2224c19bc74ac95b7526c3de4c59b934','762bdf2e573b52dbf11398d0a1a7ad1d580fafae4277dc02c30434c8109bcebe');
INSERT INTO blocks VALUES(310263,'f5a2d8d77ac9aac8f0c9218eecbb814e4dd0032ec764f15c11407072e037b3c2',310263000,NULL,NULL,'385ee6105c723c16f6e0f35f5d7bcff7cdd7241aefc05311f6c5a8ee6dc24cd7','8f043a418b242a028780986295118943b31c36d85de56a6126db0a3ae85ad9ee','33f2220abaca3458f8bde95b487accd249544b07ba364b2be1936e3044a51389');
INSERT INTO blocks VALUES(310264,'ae968fb818cd631d3e3774d176c24ae6a035de4510b133f0a0dd135dc0ae7416',310264000,NULL,NULL,'6effff8293e1002bbc4459708c08cc1728a8e98632a89fd94553b015eb6094d7','e11c7c8b0f12d48eaf01d0f80488f553cd828f25f4810acf7e4cde8e07b1cbf0','5b1c4af2e2d1c2cd2d344525db0aa57194adc9205258a7bc083a26c25a4acea1');
INSERT INTO blocks VALUES(310265,'41b50a1dfd10119afd4f288c89aad1257b22471a7d2177facb328157ed6346a1',310265000,NULL,NULL,'ee29f9e1b9dba3251a27b526f53d79d7e98890afe0b6978f33fd1c4f57344d0e','5e118440b7cb1792cfc0f2c407e07aa4b2bfc0b1fc82d136f163f442380ac655','cbf791eef000dc6b25c7575145d095b0b5d61c037d02f44ec0d8e7cb0db7f374');
INSERT INTO blocks VALUES(310266,'1c7c8fa2dc51e8f3cecd776435e68c10d0da238032ebba29cbd4e18b6c299431',310266000,NULL,NULL,'b6044b3f0a9004c93506d02e75c4782bbe12b2c388efdcacd89c5760df42b557','ebffee5b50de287eabcd3b6a6d33840b5d32591693b82561556eef4cad9caa65','6ec16da1c5941d6eed3299a6767e3605e1ee47ccd4ff14678ab58650b3a333e0');
INSERT INTO blocks VALUES(310267,'c0aa0f7d4b7bb6842bf9f86f1ff7f028831ee7e7e2d7e495cc85623e5ad39199',310267000,NULL,NULL,'fb3f26ce8bd4aac1a02ba09c764d35f9cb56dba75f709f92422b01fdd7a4f49d','f83331b0a8d2522e422046d8c9a662eca0b2fbf9c45fb1a2f42c9dac0e373c3d','405c65a9248bf4cf86ea04c1804448f67db8e2f2d8535e938941b1f25aaba1c5');
INSERT INTO blocks VALUES(310268,'b476840cc1ce090f6cf61d31a01807864e0a18dc117d60793d34df4f748189af',310268000,NULL,NULL,'48f730944343ac8abfa3f7a852075232c50c1677dc1237428375b252a0c89afe','22496f421b1230e7c5dbc6a634a0e6e7c254684596f58367470ff966c361e259','71a05a1da58ea2283006416f2a14624421160df4c3e314fd94fd016007854a54');
INSERT INTO blocks VALUES(310269,'37460a2ed5ecbad3303fd73e0d9a0b7ba1ab91b552a022d5f300b4da1b14e21e',310269000,NULL,NULL,'510ad44b41fc8021c0d1172b3dc6b2ced9018ed52f42f3d4956e988943b6e71d','ddb7a10dadb55a816449afe21f7c5747b5987f339c174af76f5c99734626d8b8','347df2c4fb5a1ffa2df7415e5df251ed757d1a5b1f36f6b1c29f2a1f01ed7407');
INSERT INTO blocks VALUES(310270,'a534f448972c42450ad7b7a7b91a084cf1e9ad08863107ef5abc2b2b4997395d',310270000,NULL,NULL,'31fdf38a3c5f9181bfd284d0d751093c1f41945fa8d7032575d934e2e2376fb1','f0de0f1669bda10c071b9fca4cd5924ea0d177fb88fdcd64540f34fb3c82c72a','b6ab1e3b5c9f3cf118059fd49e34fc7bb958f52bc0076e0c7b178040d8ec4550');
INSERT INTO blocks VALUES(310271,'67e6efb2226a2489d4c1d7fd5dd4c38531aca8e3d687062d2274aa5348363b0b',310271000,NULL,NULL,'6195bcbd82a2b229910e6c8bf33f047caaa43e1de6e2eced813bdcce81057bcf','d30c5079e54bf9bc7940cb7b21eef17a4733f0648e6c729ca154db39c1c5bf25','21cba6cb076b41a3c517099c521869e9a57e47fd1dcb4434038d03ce73b3d98b');
INSERT INTO blocks VALUES(310272,'6015ede3e28e642cbcf60bc8d397d066316935adbce5d27673ea95e8c7b78eea',310272000,NULL,NULL,'1e9f54fa5b4811dbe7ef7855b95cc095c9763e866038c51f80a7593bfe9d2f01','d19dad6950108fe8c1d2e86196ee31113faf7d5b7ac5ffefe36c26af5fb7f67e','0131ecaeeff3cdfe31bb26ca1ddf7171e119676ed11f7273833d0a411157f1aa');
INSERT INTO blocks VALUES(310273,'625dad04c47f3f1d7f0794fe98d80122c7621284d0c3cf4a110a2e4f2153c96a',310273000,NULL,NULL,'04108d79e2e448ee634fc931495319591d5083e2d5d026145f00b3b1853c97c9','47984a8b0e0010ef0fb215e666bc187a5b0a42ac25fbb865002cdf380a1d5c0d','071cc80c417105eb3dde873bd8592912ad94bcb9e48ca46b2691a5794fd549ec');
INSERT INTO blocks VALUES(310274,'925266253df52bed8dc44148f22bbd85648840f83baee19a9c1ab0a4ce8003b6',310274000,NULL,NULL,'4ff9f4036369703d3b80fff33837fba9786c991a3a926619fc8bb7b3adc38a24','d1c75dc802367cf517184d14064f053bbe598071be46ed75d4780213262f3a81','555479bb2fb7e79a34dd5fec22400cea72dec6774bc923f8824429b77759964a');
INSERT INTO blocks VALUES(310275,'85adc228e31fb99c910e291e36e3c6eafdfd7dcaebf5609a6e017269a6c705c9',310275000,NULL,NULL,'c613fccca1450f1868426b7c900452ca09b6c83589d72bf84c8afcc04b1fc0a2','9b6122b54435d5b3f2f8dcfa4a99362552f6cc1d2fc3278278789feafb2d2c97','eb3c0a96a3175739a74ac7a0667cb5efe59130d20ad72a3df8223408f6ee7af2');
INSERT INTO blocks VALUES(310276,'ba172f268e6d1a966075623814c8403796b4eab22ef9885345c7b59ab973cc77',310276000,NULL,NULL,'0964596a5bc5e655abcbf7b7070288223e6f51d324ab56e9335430c3a62b02a8','6dad9ebaeab54c9e1231f2395ca4005b876c7935c88f7a53f6ca8018d146e6cd','b97d08f8a6791dd13b516400951521db2902167968ea6c4187f45e3bcf970213');
INSERT INTO blocks VALUES(310277,'c74bd3d505a05204eb020119b72a291a2684f5a849682632e4f24b73e9524f93',310277000,NULL,NULL,'d8c6969dd1f2609ddaeca194440cf7ed142d896553ad51f6e474d141a402daa5','760609fe25e7ba4a3c82d193092b2a6562747a4267fd07184ec8fef2dea11867','daffbbb64d38db4b895da5e6e4473fb92d1ba54c993be00ebab0bab241ac0416');
INSERT INTO blocks VALUES(310278,'7945512bca68961325e5e1054df4d02ee87a0bc60ac4e1306be3d95479bada05',310278000,NULL,NULL,'71a060d923b31d6031b826bce24c95312acc68cb17a0b8569797f2422dffaf32','b3cce498f2dd9a1adba71e0f1e02cd269a4bb7814ebb574d56feb5f9fc777d51','6d1c255875367e13a3fc51a335409efb3531b6bfeb30589ac334787361179137');
INSERT INTO blocks VALUES(310279,'1a9417f9adc7551b82a8c9e1e79c0639476ed9329e0233e7f0d6499618d04b4f',310279000,NULL,NULL,'5491e20db3b734e3bcb83d89fba3d3cdbd23e04a617cb61e344f67f5caf37ed0','c31e1832909b72f921e2a8f3e3fe82b53745e7172fe89febb370134c4b2834a7','ed241f0461c2ca243f31cb1f2414a81cbc5e1e07769c580d426d19baa9897fa9');
INSERT INTO blocks VALUES(310280,'bf2195835108e32903e4b57c8dd7e25b4d15dd96b4b000d3dbb62f609f800142',310280000,NULL,NULL,'4dabdaca4e18c632095694a0dce232842e33c5464cac7c9fe1924cbebc270667','b02e2cacf5db54e7c2812a289001519307718d4f9f72e96d659d4f8ce7ce7555','863e5a1a75543372637f494afce11a3ef219728feee1dbea3910eb53a2d721ea');
INSERT INTO blocks VALUES(310281,'4499b9f7e17fc1ecc7dc54c0c77e57f3dc2c9ea55593361acbea0e456be8830f',310281000,NULL,NULL,'dad6cea793dc8fd3d8c3ad04d054467e73b81603392729987c593f8ca67c3be2','c8c19255bdc114171e021f09cf5cfd1b75f781848cf59a623da4e9f4b104bf23','7826ffdf721b728b600c1ed1a13644a93cad5442adc2b070c413a2eb46150a2e');
INSERT INTO blocks VALUES(310282,'51a29336aa32e5b121b40d4eba0beb0fd337c9f622dacb50372990e5f5134e6f',310282000,NULL,NULL,'42b1f66568eab34aa3944b0eeebea5296d7475cc0748ae4926ddbab091de7903','3db309ef4c76baa24b91654001c2c52a4761f9d26eb61ed67384ba68092694c6','16b2a80603ba3646e74e2fee3f34304c88936fd1c98451a674096142752a94b1');
INSERT INTO blocks VALUES(310283,'df8565428e67e93a62147b440477386758da778364deb9fd0c81496e0321cf49',310283000,NULL,NULL,'edfae1059d89469e4d8c9285bafe05968e62c35504ce5d5f09bca4bd8ac0b698','f4d3dc017661f563e1373dd60656c3c27e2c2fe518c3d36780a5de8a9a53392b','d1e2ece7caec384f40b50f091111729b176cedd33b12f6b758746666e4510191');
INSERT INTO blocks VALUES(310284,'f9d05d83d3fa7bb3f3c79b8c554301d20f12fbb953f82616ac4aad6e6cc0abe7',310284000,NULL,NULL,'2b9d8a4322352981f7033af84e111c94511ac9b87d7d2599cdf5f2814b45a42a','cff818ee153a737129a840db9d9af4919ab9be3777e683b9572b180b36b6e4f6','6083bc7abd9bd36107cd527e597854ec02c37eeaaed243e954d2708fe8031196');
INSERT INTO blocks VALUES(310285,'8cef48dbc69cd0a07a5acd4f4190aa199ebce996c47e24ecc44f17de5e3c285a',310285000,NULL,NULL,'63d6307a1f8d09526578c4b1776e51b40cfb5ad78d01dedd3e23d99f1efeda19','5d22a49e3aabf61b278d78803c9a577193a1b0708fcc4ec2de1704c259d56817','3dc405809b5ca93cb31de6266302d02fe2fd94f5566d839539501b21444fe30a');
INSERT INTO blocks VALUES(310286,'d4e01fb028cc6f37497f2231ebf6c00125b12e5353e65bdbf5b2ce40691d47d0',310286000,NULL,NULL,'a42dda85ec8530a307a1f9e7048d4384b229c2637305eee0368ab02957f5b31d','fc465573f0f46b4855fbb206869885498b6b65f3b5f79972df31e10485a5b2d1','bdb666d2a9ae167d6549dead8c852c41c97a0f087b74ea5ec539af12b90211f0');
INSERT INTO blocks VALUES(310287,'a78514aa15a5096e4d4af3755e090390727cfa628168f1d35e8ac1d179fb51f4',310287000,NULL,NULL,'96bdbe4268d82b3b82d776eab32019393f5de5ec5ea2302c0c2a9aaa068fc2a5','5c56b510d9d875a9a622a46a47daedcea35e3b321748782477ad06e2b8d86006','ee380c102251bedfc99642e42bdbd5e64079d55a1945d036db556041d1204d79');
INSERT INTO blocks VALUES(310288,'2a5c5b3406a944a9ae2615f97064de9af5da07b0258d58c1d6949e95501249e7',310288000,NULL,NULL,'0c96ab72568c907e27db628c30825012ea3ec633d3debe3256dbf4d3c95f81c5','d4ac89dd7158cb3ecb05728daa8005cb8e78aa20c197d6178cf78fb0f171e1ff','b76e59f11f8adffd721b5cc483e4c6e3e5c561c9562c0b226a560050a1b8cee2');
INSERT INTO blocks VALUES(310289,'dda3dc28762969f5b068768d52ddf73f04674ffeddb1cc4f6a684961ecca8f75',310289000,NULL,NULL,'921af39c1d31264ba86b6e6ca54b8dbf40bfbee574c1278d78d686b20159f99c','ba3b1e84522261c5f23e7a3987b3fe33f2ecaf8c1739c09bab99927e179080f6','9c463d0fed90c5f37bf6f22996042c6d2f7291570f67f232feb79df01deadb73');
INSERT INTO blocks VALUES(310290,'fe962fe98ce9f3ee1ed1e71dbffce93735d8004e7a9b95804fb456f18501a370',310290000,NULL,NULL,'743e6499fe6b1b82914457c8bc49c54abc0dbae277eccc0b7fcc203e86f89f6e','b51949183e3683e16fff3679443d4c199b5e08b678865ecd6f8b2e2ca54280ac','b1403fbf44c096349ca175727f711c369e359d94a5646a0b8612968738c74d4b');
INSERT INTO blocks VALUES(310291,'1eeb72097fd0bce4c2377160926b25bf8166dfd6e99402570bf506e153e25aa2',310291000,NULL,NULL,'194402bf041424fec8b63bd9b5851c5b0d04958b5851bc9fbcbcd9e683079e7a','0bd8e6f309b03ab7e9fc2a897f431e34c785c23851933b86a0a49ff92931410b','fe2a47e04418b88840a83234e82e0062d72eed28c969a73f13c2b491a1c24dfd');
INSERT INTO blocks VALUES(310292,'9c87d12effe7e07dcaf3f71074c0a4f9f8a23c2ed49bf2634dc83e286ba3131d',310292000,NULL,NULL,'c8b7f8f3ef06df7a9c7eff346d2a9f0d1f1377c064c3b3c3bc2aebc845caee95','9a1f3be3406d185165cf8497d4fe375235fc441926229a03df9f8b54508a3e3d','9950b8c4bc249c9692aa119a30122d25e2e98ea5e0510cfb511a4016671ada0f');
INSERT INTO blocks VALUES(310293,'bc18127444c7aebf0cdc5d9d30a3108b25dd3f29bf28d904176c986fa5433712',310293000,NULL,NULL,'0c9c8a8558e14645d818621e4a97c66cc9bc67023141c5bd00830436e5760fba','0daee5a235bae0c70fd6f8dc5fda2cbf854c79e5ee2cadcb7cf63f4e6cb03938','cb24f56f2e392abee3d5e334badbe98992ca457a893ae7404d27a94053e3befc');
INSERT INTO blocks VALUES(310294,'4d6ee08b06c8a11b88877b941282dc679e83712880591213fb51c2bf1838cd4d',310294000,NULL,NULL,'1cb04936a9ee72f465e4d6d4fd6f2ac99cacd74a510d74f017320dc7061c4b02','12c0c32d5a0b9ae7b9e2c1b1006ea7abb6109f16768ebfb5e4fc2640cd92cb87','4fb7bea0050d83e0a2be01740471a17f838e673029bc5d43e6403d2a9f703aa1');
INSERT INTO blocks VALUES(310295,'66b8b169b98858de4ceefcb4cbf3a89383e72180a86aeb2694d4f3467a654a53',310295000,NULL,NULL,'d7751796cf10b5a92ed9470cab6dc1d0e2a1853fd457fd913e58f5fd38771d2e','4d8f584983572828ec83c35613c266d753efb778a12f477f3eb9996ebfa8d0f0','f25119855fedd16be6137968ebd527e11ab2a9049ab5c1d4546c2a09a6cdedab');
INSERT INTO blocks VALUES(310296,'75ceb8b7377c650147612384601cf512e27db7b70503d816b392b941531b5916',310296000,NULL,NULL,'e23e480658f3c900b36af8fde0bd00255b960ba1b65dbce45a773b4ae813ebcf','d14cc8e1ed6ca44000ab619222b196fc70f33b86e9f40e28980477aae3f5d38b','8c9d78c55765d1b3cfccd7d4120c1cb0c36fe399c0d0ec15d29e251ddc0489c4');
INSERT INTO blocks VALUES(310297,'d8ccb0c27b1ee885d882ab6314a294b2fb13068b877e35539a51caa46171b650',310297000,NULL,NULL,'802b11ed2d95f872d2fa557725a43b15fde5e7b550a3dbf229881090866ee577','d1d6f6f61b98afeecd81659b0267777867d9ca9f92c0a8f38f523199d246bd5d','e60a9abdfbbf08aec6373986d8e265636d0cbfdd5771e60646442680e6c1c5f0');
INSERT INTO blocks VALUES(310298,'8ca08f7c45e9de5dfc053183c3ee5fadfb1a85c9e5ca2570e2480ef05175547a',310298000,NULL,NULL,'d8d94f75f311d053b6cb52ef8ae295423c99f533351d78145614b4fbc69f6742','490d14b721c0012a731404587779dca7aea2dd161b6f043fc90bf0125de92da3','f2e0ecd8e8fb6e5663565372f82788a66f836bcaff6506e51e8b1170abfb3ad0');
INSERT INTO blocks VALUES(310299,'a1cdac6a49a5b71bf5802df800a97310bbf964d53e6464563e5490a0b6fef5e9',310299000,NULL,NULL,'841a917e1aa259167a05c911d705a07bdcf980c9c5e831999923793a03a1d46c','20346144a01b87b8714b94d307b41c4ea0a71b57c64b3431a0127f1fe1e4cefb','0974ce508ddbee22316e245511d1936164a38ab7c8db54bdbbdf9c2b7b57f021');
INSERT INTO blocks VALUES(310300,'395b0b4d289c02416af743d28fb7516486dea87844309ebef2663dc21b76dcb2',310300000,NULL,NULL,'3d74164b7ec33cbc0b3e372b21e025c79b35e99784a2d8ae359f2005972bd5d3','fefe75cfc5b1f5d5f530ff2e22e5a42c579c7d7ef9fb89ccd3bee0a8cf6be57d','9daf0c52f16277e853b9340abd2f05e3f784d391a64f0c325ab1f9a3037ac3ea');
INSERT INTO blocks VALUES(310301,'52f13163068f40428b55ccb8496653d0e63e3217ce1dbea8deda8407b7810e8a',310301000,NULL,NULL,'1adacb3d5e4701b0f1bc158dd5164dd770852c5520e850d6d9b9e63fd1e7c37c','e8a081179fd19fc9c981f4b0a99cb46daa1c3f6b8c82c273e75b61226d63dd99','f32dc9b12943a9fc2faa1188f43c63bce642d1074aa814639e010baf5341fe04');
INSERT INTO blocks VALUES(310302,'ca03ebc1453dbb1b52c8cc1bc6b343d76ef4c1eaac321a0837c6028384b8d5aa',310302000,NULL,NULL,'587b7eb8bff455f2848380f870d20398ebae76e6a12acaafbac6e955d3c3380d','7d70ce80c4551a0a54280c9215b5125eeb1c7a0603a06acecaa99065ad60328c','4398811b654a671e81cf974d9bdc0598ff99a7b351a5aac0add0fc2738a893a5');
INSERT INTO blocks VALUES(310303,'d4e6600c553f0f1e3c3af36dd9573352a25033920d7b1e9912e7daae3058dcca',310303000,NULL,NULL,'27120588c29741bbb4a802829d2b35d8b8b17e7b5cb49842faa0fefe05e99071','f47bb6043cec1de58ed647f014e1fedde1bcfbac2d2d453e2bedb44dced6dd13','d556a26ce1d0d9ef767b825bb36edc1f1be04dd3d90b9dd513065f4fcce81a29');
INSERT INTO blocks VALUES(310304,'b698b0c6cb64ca397b3616ce0c4297ca94b20a5332dcc2e2b85d43f5b69a4f1c',310304000,NULL,NULL,'4a1d23a03c47c00574d3423f328c48d794ceadd2655cede15c5901d830c87589','c02a84128e604add7a25b38a63898a9336e1c43b1cd561b6b763347cdee0f2ca','f1969e38eb6c4785f12403916f3a17cdc48aadbb7ed60df2b0fd545d89ef9370');
INSERT INTO blocks VALUES(310305,'cfba0521675f1e08aef4ecdbc2848fe031e47f8b41014bcd4b5934c1aa483c5b',310305000,NULL,NULL,'7aac15d414e5ebcfaf63a9ac3bc05d2dde5ffc610d9bafc8ff2a210020f6d5ef','d87c9d0d5c3ccf9b7b2201e7db7a1a06831a69117f2b36c9682465a6d8a203e2','0422d114a8a73cb4cb852bcb404283b50457ff843d1b60de793335879e03738f');
INSERT INTO blocks VALUES(310306,'a88a07c577a6f2f137f686036411a866cae27ff8af4e1dfb8290606780ec722a',310306000,NULL,NULL,'bc47cbbb42618bea636c422d824748d97d5bd4b4b75ab44d80ebeaa9b5fb309a','b349672a304919087c68683750a083cc48d42623b1e423d52fa56f70b6f63d50','7462087a8500a4bcfae19148ec42c738c94726a7c5ed2c7324d895a3f6d90f03');
INSERT INTO blocks VALUES(310307,'bc5ccf771903eb94e336daf54b134459e1f9dd4465dec9eaa66a8ee0e76d426c',310307000,NULL,NULL,'02440bc84b5e8e1733d29e4524381c8ba25e38727d5f70d6246627761660f329','6f61e18499f5168c665b390a090080b1f0336e5f282a207a76587c0eacc0f879','89901934cf54cba38b7cb202ec8c9765cbd4840b872294bc814c3ac8d84d3864');
INSERT INTO blocks VALUES(310308,'2291ffd9650760ff861660a70403252d078c677bb037a38e9d4a506b10ee2a30',310308000,NULL,NULL,'44c5b13272847e19dd2cacf9a506145f9a1ac5792916eb98204bdb6772e7ab68','ebd52f0ffd2ac27d92310b8b44c4870db4cfd7c125eb4bbfc8850990f1c9bd16','e17e29a4d3e11f2f04b2a5111f50231c39c15de00ae51e380e3f2d8a89a69364');
INSERT INTO blocks VALUES(310309,'ca3ca8819aa3e5fc4238d80e5f06f74ca0c0980adbbf5e2be0076243e7731737',310309000,NULL,NULL,'25ea894e3bb4f88ef9c8f86156a3980c0d638c20c69e8bc6365f913d1454c14b','c71a35effdc581733d09b3c4b905263fddd48fd0385ff75c767c3597904d567d','71f2d426103e7c1e1bc7f60facf4583612ae7ee770ef96fc58cf3d6e30b6fe76');
INSERT INTO blocks VALUES(310310,'07cd7252e3e172168e33a1265b396c3708ae43b761d02448add81e476b1bcb2c',310310000,NULL,NULL,'94d123e1ef62d5063e363065d8d44f9ab7f22c59eaa35a2ce38177c7b7a8eea5','4d2cd806fbdd97363d0e042b4ebc7378933258244abf778fa0130d83e6693d53','9ed3a04b10bc8ce7868bd49bbaca4654011cbfdeab70b0aaf6fa592bd0504064');
INSERT INTO blocks VALUES(310311,'2842937eabfdd890e3f233d11c030bed6144b884d3a9029cd2252126221caf36',310311000,NULL,NULL,'3aa3b3f04dfcb85db112ec7f540a7f54b56ad7f749df3d0d1dc738ce25bc5728','f82843d2489b4c5da580e2ce12947d858fbcd928362a20fbb2f447fac105b223','01381c1621d881a26d8216424e2522d16e8af25aa34eac0043c823a6d5e83d62');
INSERT INTO blocks VALUES(310312,'8168511cdfdc0018672bf22f3c6808af709430dd0757609abe10fcd0c3aabfd7',310312000,NULL,NULL,'44991a8afb1cb85a381557bd653b1015160842edb02266164460559a4ea9e529','6ff85dfa4e70a0f10bd1a598d2f70edc49d0b0624b648c7edf01de2d4f009170','a5d6f23119383d669382b2ab7364388ca98b0890eee04baba0166b5f634ee231');
INSERT INTO blocks VALUES(310313,'7c1b734c019c4f3e27e8d5cbee28e64aa6c66bb041d2a450e03537e3fac8e7e5',310313000,NULL,NULL,'d7b21c8000a09ce9f26037c43073e2d7a596c68c954c5416d22454d3e89c8b70','cb82ad80b42dbed273ba7a4130cf324dd207b66bbe2dbe0c7e1696aa587b13f7','9e56c08858aa6fc8657197cd5fb77624677d054ad651cb99ad0b8b5196cb0a91');
INSERT INTO blocks VALUES(310314,'1ce78314eee22e87ccae74ff129b1803115a953426a5b807f2c55fb10fb63dc8',310314000,NULL,NULL,'5c1ca6e4f014f1fa35870558ad52dd5252e6b54a02919546a03d4e6498370d44','7976500abd59be3389cbbbdf2433d61b09b4ecaf9509b143b2a1670d89a05e48','4fe8162a34085c7c696cfc41677ebeae0041c04d9b268c21c098765c08030350');
INSERT INTO blocks VALUES(310315,'bd356b1bce263f7933fb4b64cf8298d2f085ca1480975d6346a8f5dab0db72cb',310315000,NULL,NULL,'ba3b14271b4899094ad98e0535979eed35dc2aad617d7996155251ddcb4d0e4e','2e33d28ab2af968aada2d35c4e5fbfae6c9fdb6789d75eb5f2cd604df71088aa','9304329162a1e849a916793eb29180f4b2735d595ca859f63b24002e4edceed8');
INSERT INTO blocks VALUES(310316,'ea9e5e747996c8d8741877afdcf296413126e2b45c693f3abdb602a5dae3fa44',310316000,NULL,NULL,'b33797e21d7654e1ca5cc08bca4a6bda9ae95f23094d42b789530b6cbd584b4a','bc1d74bc6cc697e4e91eab960f3c9a9c69dd1a18b03d60debe28a147cf443555','24d71ec511c02fdf97ded3280c54c8b2565b51c39d27086ee9b5a0aa2c97bf65');
INSERT INTO blocks VALUES(310317,'aa8a533edd243f1484917951e45f0b7681446747cebcc54d43c78eda68134d63',310317000,NULL,NULL,'497a601664ea59cf1929096b129613ce3bbedc271ecfb33b364558e231d48649','7deba75ec23e51f190292569bd8644d6566cd0dfeb69f053dab99f30d61d9123','9855c261888e6ba9e7b50682dd77a4bf17ea0ac207966bdfc5064eeb2dc245b4');
INSERT INTO blocks VALUES(310318,'c1be6c211fbad07a10b96ac7e6850a90c43ba2a38e05d53225d913cc2cf60b03',310318000,NULL,NULL,'760dabe4684acb6c8638c56ee1387e4d6710f99adcae4cd9721da0c7decfe2bb','354ab192a68d372f20aa6dd0fcb58ce5c5be4d0f0ddb73b9f8f42dea374d7a08','4e60ab641e7a3ceca2e4e9ea0284495e43d0fb5bdae5bf9467219e32366a01e7');
INSERT INTO blocks VALUES(310319,'f7fc6204a576c37295d0c65aac3d8202db94b6a4fa879fff63510d470dcefa71',310319000,NULL,NULL,'e43bbfd0e56daf582c84a2286079fbd8aa661c149cc3a14d40d139a45fd7a19c','15c4ccb51cae1388a224337eed622ef9dab825427dc5f917e1e8312f152b0af9','aae6d041343838f440c4fb311734a462f682e95ef9348bde2965ac9ab8fd4a80');
INSERT INTO blocks VALUES(310320,'fd34ebe6ba298ba423d860a62c566c05372521438150e8341c430116824e7e0b',310320000,NULL,NULL,'7f95ee77cee4a1c0de27a0e69d909d0c2cb8d5a5d76d6d92e8bfac58c3f148bf','0f3167bb060415797f34a86961be0816626616f3e673980c4e24b00bb4b55127','7ddf51facf86fd590fcf8e362a1af89e05d19ad3d59bb419fc024371cd7edcfd');
INSERT INTO blocks VALUES(310321,'f74be89e9ceb0779f3c7f97c34fb97cd7c51942244cbc2018d17a3f423dd3ae5',310321000,NULL,NULL,'9e2bc1247466f28c92ff287e9d5825f81e6b8b4063c70db23aacfde92f627417','cf4920a37fae89fbdece9b0c29e07e73cfe1f79b42aea145dfc2bb936165c5e1','52356a52ea7ffd1bc3d8c52c9a1d5f894a530be420fea853600572c21dc079cf');
INSERT INTO blocks VALUES(310322,'ce0b1afb355e6fd897e74b556a9441f202e3f2b524d1d88bc54e18f860b57668',310322000,NULL,NULL,'bca22d67b45b3bca60a0e4e1009d4ba86bbba96b0e37455e094eaf933f7d892d','d460ee5c501a1121b392cddc4d3236e4a01b78d6386629cf0a4a862c51436fdf','79d11a10eb7b40b72e6f39e8b573a0bc7f8c3a09a0ddf707a26363e70ed8e1aa');
INSERT INTO blocks VALUES(310323,'df82040c0cbd905e7991a88786090b93606168a7248c8b099d6b9c166c7e80fd',310323000,NULL,NULL,'aa76c1d43196055cc6ae91e0afdb1105db0e5ea8b9f8d20298878900c07e8ec7','06e1e96c73a029248389ccfde68b1e074048b3f4f295763e6b9519639007911d','33230b54faca469045bba82fb958955e784a545109a4127d32e1c65d74ce65de');
INSERT INTO blocks VALUES(310324,'367d0ac107cbc7f93857d79e6fa96d47b1c98f88b3fdda97c51f9163e2366826',310324000,NULL,NULL,'dbdc8005f1f6c45dce8e0450740c37f2d21e6f325e1c2279bf78094aa1098ebe','42121d8fe5bfdf76d08aec50e915a5513e27400b955faa90ae7623e761a80e52','d808d7850f5d60054f95cd053c427b65e1943cd40bd2b685a9fc0672cae4a783');
INSERT INTO blocks VALUES(310325,'60d50997f57a876b2f9291e1ae19c776df95b2e46c14fe6574fb0e4ce8021eac',310325000,NULL,NULL,'021f052a73f177bce172f220d3a1ab9aea5f325e32b3d2635905a0c95b4c6efa','90b21a46fb4a9ea93156c852211a3a956bcf506791e924eed5d570ef88f32cf2','c327c50e91e10d90a283c0b137213591e130ab773e844e9cef2c95b68756048f');
INSERT INTO blocks VALUES(310326,'d6f210a1617e1a8eb819fc0e9ef06bd135e15ae65af407e7413f0901f5996573',310326000,NULL,NULL,'f90a81326133a303229276b553796e2f9d186f98ce897f759cadb19e6728090f','9e397e5221f9a4e8eb2174e70844a51363f27015116c4fc0f5cd8c6087ad1612','716bb776c9e3110340f9d526f3febe4aa1ef60898155e53d5eeaf0878f9d7251');
INSERT INTO blocks VALUES(310327,'9fa4076881b482d234c2085a93526b057ead3c73a6e73c1ed1cdee1a59af8adc',310327000,NULL,NULL,'86aaa9593f09bb338fa1b0878f2522db223bf8262e491ae0b8e707f9796c5e05','e5cd0e8500377104f39f4001ac951d09361f687465558a3664d7db277317d1d1','75d824da19208347dcc9fcb24b60353f3744f9935debb1dfddfac6aff678e8c9');
INSERT INTO blocks VALUES(310328,'c7ffd388714d8d0fc77e92d05145e6845c72e6bfd32aeb61845515eca2fa2daf',310328000,NULL,NULL,'f4b59e29f0c89f18d045a800d098abfffbc9ad7ff200eeb47133605eb1a72b68','1f5193208a704455abe3e6ff62abb184d2a73651fae6d31b9c1603610654c238','10e6e6c268123b5b24156f238599a740525b1382a3d07d78a19f52c1d96f9a37');
INSERT INTO blocks VALUES(310329,'67fb2e77f8d77924c877a58c1af13e1e16b9df425340ed30e9816a9553fd5a30',310329000,NULL,NULL,'dbd3510938ee45e99d8b7cac8b0d3e8a275dfc6b1c8e741e0320e4b2e4947fe5','e578bffa5ff235646acfc42b305810b5c2cfbcefd8c84b6ba76951bff64291f8','37d9cd6d213dee949ffdd18160140efaf315413a85a7ed8386ee0346ebe3bb36');
INSERT INTO blocks VALUES(310330,'b62c222ad5a41084eb4d779e36f635c922ff8fe275df41a9259f9a54b9adcc0c',310330000,NULL,NULL,'79f20326c0e49ea2b3c81e8d382754f311e3744b22b80140dc7ceed4da1fe09d','64213e605566c7b5c234e94b8c99dee0e92b9cda97eb3869bacd3e7058619570','ee45e283425b677d3fddfd8237e3474c15d2f719cc773f312581e528df722172');
INSERT INTO blocks VALUES(310331,'52fb4d803a141f02b12a603244801e2e555a2dffb13a76c93f9ce13f9cf9b21e',310331000,NULL,NULL,'41d2d69965cde1e0f97b7c14c33acbad592a6bd4882eed6aeb57127ed4ddb69d','a487fe6d7784a6b013f1f7b4f49d2048285e955300f9135217f91b3c61f76769','9a852ea14fde386d015743dd17fc0e87b25d460aa9148455291c704aeaea4003');
INSERT INTO blocks VALUES(310332,'201086b0aab856c8b9c7b57d40762e907746fea722dbed8efb518f4bfd0dfdf2',310332000,NULL,NULL,'3def70343846a9776559707fb61437a53ffc5dac917f81ee3a12445ce69a9885','38e834a32d23da9afb4e9e9b1bbce021e312372d608bb3dbc793368367505018','bba27999465f7c41d734294f89d258703452db37d16f1e914ae66246dfd62bb1');
INSERT INTO blocks VALUES(310333,'b7476114e72d4a38d0bebb0b388444619c6f1b62f97b598fed2e1ec7cd08ee82',310333000,NULL,NULL,'cc02e3e7327ddd3c192bdea2ee76728c0b0cb031fe130d5713c1ec9546ae5946','af302e8424cb73820cf195694343da04ea238ac073225813d0ddeb7904faa9aa','5b21252d306556c8ee0c7636a8382ba0ec132f1a13e92520e47157e721d60d4f');
INSERT INTO blocks VALUES(310334,'a39eb839c62b127287ea01dd087b2fc3ad59107ef012decae298e40c1dec52cd',310334000,NULL,NULL,'8a449270a6bfb33206c1d7eb02ca363cb405118e52359a1ed015c5660fcec8a8','a7fbdfbd538218c773d8a42b087f5d4e10a040c50d3939b621e2fadeec336b3b','fbb0463378d52b56159b0d74fb12c52ecfec5e1be3eaebd9e452ba6007d737b6');
INSERT INTO blocks VALUES(310335,'23bd6092da66032357b13b95206e6527a8d22e6637a097d696d7a96c8858cc89',310335000,NULL,NULL,'942c5c5ff6c24ce2bb18e065b24c39d1906ec381bba55cb9d905376ac87d2bdb','93084a0c0f122e84e0ce04e75e7a24fc120ad1f548c3a1bf5460ab1201823183','dbcb063985801415ed57a5dfb48dc1000fa4e3aaa4fc2f644cabf7e441deeca1');
INSERT INTO blocks VALUES(310336,'ec4b8d0968dbae28789be96ffa5a7e27c3846064683acd7c3eb86f1f0cc58199',310336000,NULL,NULL,'68a947f2ae4507e143c9ac84826318d4b630845f81548490f7b0c00a2330e990','57ee8c64c14954889fee28ca6f6b97321abd8af02bfa18e74223fcf7d80eec0e','8b06259fcd6a52d1d780d01c1ef3c87868c1ee5db0c3f8cd9b85fb515e59c469');
INSERT INTO blocks VALUES(310337,'055247d24ba9860eb2eadf9ec7ea966b86794a0e3727e6ffbcba0af38f2bc34a',310337000,NULL,NULL,'4e1ca24a54f45b4cdc60be1348b3d5b81ee8acbd7c4f8cda86b8d2746694f17f','f3e537261f9fb3fa6be25c73c4db4e59bde515b2497bb8f7275c0bf153a2eeb5','7cd2f5cfe824410a80250acc51ab9f28c86208d199abafc8e1ccecb12e28750c');
INSERT INTO blocks VALUES(310338,'97944272a7e86b716c6587d0da0d2094b6f7e29714daa00fec8677205a049bcd',310338000,NULL,NULL,'dafafbcf8cbefadc5596ba8b52bc6212f02f19de109f69dc412c2dbc569d5e8c','0acd8b432bdf2cbe5229916ac0551e7a771660523ed701d05ba0ceeccd962071','3ad5af159537f08b729038500a2e7628fc41dfb149cc57dbe8239f0a21a810b9');
INSERT INTO blocks VALUES(310339,'99d59ea38842e00c8ba156276582ff67c5fc8c3d3c6929246623d8f51239a052',310339000,NULL,NULL,'e28e2a9c9f9476d0c23bba3c6d2e68f671aa20adf72199188a9c82160b0cbadb','2ba58e435f5d8750ebea258f39c398dafcd66a27fa1a19b6da92fe46ec330637','360bad1b6601f094772a454d481671b8f994ec9ede8a5aff8b844426fbd75120');
INSERT INTO blocks VALUES(310340,'f7a193f14949aaae1167aebf7a6814c44712d2b19f6bf802e72be5f97dd7f5a0',310340000,NULL,NULL,'7171d5b8a9f07885a5fb6059e4ca31dc00863ebebcfc82836ed2af0deb39a48e','909e4947f6d1edf062f01dce97e140afbc53c6854f77eccdcfe7654a888c232c','59e50e47fca7db2e9b5c957395ec26e19be832ced377ac847b3ab11ee6271b3f');
INSERT INTO blocks VALUES(310341,'6c468431e0169b7df175afd661bc21a66f6b4353160f7a6c9df513a6b1788a7f',310341000,NULL,NULL,'d350161fb4026c48acc21d9e66a2def972fbe543c46381a353de2d2fd8b6bcd4','a438ddb81b81d7645438995c76ad7f48b60c554fec87a8b6c36f46787bbe2328','d4d3299243a6ad34070c3cc3f197c7aabb7f027898894415b4bc7dd2baf7062f');
INSERT INTO blocks VALUES(310342,'48669c2cb8e6bf2ca7f8e4846816d35396cbc88c349a8d1318ded0598a30edf7',310342000,NULL,NULL,'6acbdd85b382016a93936385edf88ea1114706f2d326ca373ad508b653e5fd28','751cf34888844ef22f6b38d9363ae313c78cb54ddec7dd4436712d490ebb486e','558558be2d3f48fba574376c6d543c31d86116e4b460b7ae712bec608fa9a567');
INSERT INTO blocks VALUES(310343,'41a1030c13ae11f5565e0045c73d15edc583a1ff6f3a8f5eac94ffcfaf759e11',310343000,NULL,NULL,'68e26f1c578576a74ba6b63cda11695176b48c7a919beaab5496db142b247cab','29d20cde746e41887684a1a326a994e16eda7aba7b271111d1fb43322d3d28d1','7bbae83de2c04b41dd92f0d1f83f26716854329ef4afff551706cea840dcaee9');
INSERT INTO blocks VALUES(310344,'97b74842207c7cd27160b23d74d7deb603882e4e5e61e2899c96a39b079b3977',310344000,NULL,NULL,'2531f6b71ce2390aeeab26cbc8095aec7a76dc46db73149868d8a6209133780f','81e53e8fd3d78d775f64879be2c95dec84ad691985aa04388e2f2bbb990967ea','ba8df974dca8ecc7d7c5cf01d978d9a446009d3e877ecd01c8b17b095959a483');
INSERT INTO blocks VALUES(310345,'0bda7b13d1bc2ba4c3c72e0f27157067677595264d6430038f0b227118de8c65',310345000,NULL,NULL,'ecf8e55d01bec5ec8fc302451bc3e0d3a76d5d413ce354ed43e36eeef274cc14','6c78f417969e5c6bb9cebee6361489cdba13df22aa87b80b0b245f41d18652e8','95b3ab09c34514ddab22f49d4f0f3105948a4fa939ca383631ff207fc1dc204a');
INSERT INTO blocks VALUES(310346,'0635503844de474dd694ecbcfb93e578268f77a80230a29986dfa7eeade15b16',310346000,NULL,NULL,'2149f9f24dd41e092555f29cf7ae1131cc53462e9f24de15720c0fd1a8a874f2','fceb5b3c1190447a95f60815b508f27b0aca47d18c83979b2a9db04f9865c020','29715093741272c8853baa80893eada8675fe8d7d13e5d1005e01730d9205c8b');
INSERT INTO blocks VALUES(310347,'f3f6b7e7a27c8da4318f9f2f694f37aaa9255bbdad260cb46f319a4755a1a84d',310347000,NULL,NULL,'f19aa2d83d53f128264cf432c9c313d89d2d91f09af8f2365ffc4bb0911abc5c','8af5500cbf0f4be75fd178812bd6848e3d66752decc7f2b23c54bca2d4c0803f','b154fa389c42bc3e8bfda80d6e5f27379357cd163c950aa67158493c046e90ea');
INSERT INTO blocks VALUES(310348,'c912af0d57982701bcda4293ad1ff3456299fd9e4a1da939d8d94bcb86634412',310348000,NULL,NULL,'5ac2d42a9f7cbe6fe7ff53879d4ac316e93c00b005543c1575c3a72471765118','eafb8bd3a4d1e5d5caf5d1472729c2fdc010db65c8115eebf80985d2d547678a','b161f887b1fdc32985695c1fbf5c793808a615d6be6f62c2a7fbdad78d39f32f');
INSERT INTO blocks VALUES(310349,'ca911c788add2e16726f4e194137f595823092482e48ff8dd3bdbe56c203523c',310349000,NULL,NULL,'ea77bb132fcbdef8652894fc3c80a862ac4fb0daaa444213b61388285904bed8','18867b266f3228fe931013d09c5d12b9a15be681f69c7e315c2d3b781b221959','b0e436d70fbb6109b8a3c37dd89a2f91d1aba4224b076d223832fa3e7c426171');
INSERT INTO blocks VALUES(310350,'c20d54368c4e558c44e2fbaa0765d3aecc8c9f01d456e3ff219508b5d06bd69d',310350000,NULL,NULL,'af48f18af140a67943df6ce781e858631a4e7841c7f44facb644c93641145237','485efc4eaf3969edbdf3bf2b1dc2237d033da397555db105324e4bb097d69010','863da991e7af7cc13f2f309219e5af023830e27e5dd8492476c926d5939fabae');
INSERT INTO blocks VALUES(310351,'656bd69a59329dbea94b8b22cfdaaec8de9ab50204868f006494d78e7f88e26f',310351000,NULL,NULL,'4ae931b01a138a0dd8e4d6479faac7961fe3148fd048c4daaa6720f907cbffb1','e57cb9bcd553ae5fc81c99ee94e2b04a0bf0f08b2c66eba5ca0f398c4689e2ed','17a5c527ba628ea5a148e93bf308cf6ea8c0643d31cb7af03a8b58e1a2c562fc');
INSERT INTO blocks VALUES(310352,'fb97d2f766a23acb9644fef833e0257fdb74546e50d9e2303cf88d2e82b71a50',310352000,NULL,NULL,'d75ce96ca15ea976fbb89c93da04a0a7c2146abc01517663f97ad0fd15adefc7','0f08afea5d81a3e31940d0198a7ecd408fa2c174c1a2071299a1f7599da3a117','e0ce3a45e63df85c56443846015a79ac2f9eaaf805ccef726cccce755a99ef60');
INSERT INTO blocks VALUES(310353,'2d3e451f189fc2f29704b1b09820278dd1eeb347fef11352d7a680c9aecc13b8',310353000,NULL,NULL,'c0830c03df4b203d5e17a9274643e614fcf6e6fb7216067cb4f41f874436d217','5fee4663dd9e66d21355a7897905f0232ef743f4d3e37f269882ebcff7bb3acf','6f8f86e5d7c6a0d6a9ccaa61008dee25cb1b28538a2642ff75a3b23f1927ba83');
INSERT INTO blocks VALUES(310354,'437d9635e1702247e0d9330347cc6e339e3678be89a760ba9bf79dd2cd8803e0',310354000,NULL,NULL,'6f4d2524f4f976880e60e65aa631f8cdfa0b23fbeb3c41549c577b695b02fc34','daa370f28ced2be9b1bdb0d3a1a9ea1d581de9050c9bc5f3578835cda2db5b8b','5c240ae747ed68638a9d19102a12f1c7b5900c2b9ff5fcf289562bbd22304d2a');
INSERT INTO blocks VALUES(310355,'ea80897a4f9167bfc775e4e43840d9ea6f839f3571c7ab4433f1e082f4bbe37d',310355000,NULL,NULL,'dffc32456b12dd7dc4bbf95ab9f360d8abf4b2e705b2822728053709222f7e50','c0db94ff86232ba4a186bbc34f4ad691cc6094c954c50c7b589bc5569857e8b0','720ca2468a422bb9b98458c3d12a681b28a4f53380c1efcb7f9f459165b1d2ea');
INSERT INTO blocks VALUES(310356,'68088305f7eba74c1d50458e5e5ca5a849f0b4a4e9935709d8ee56877b1b55c4',310356000,NULL,NULL,'01c0a7d3388aaec2d2f713b930df5b716a899ccd25d3b7e3b4c21657be7923a8','9f71693705c6954fe0446353c705591c444e2f7dd4386dd8f858bafb3b206125','c6c91c1cef3edf5cfc2661eee6e632538b2cae1bdb3062bc67c071fa19426032');
INSERT INTO blocks VALUES(310357,'4572f7f4ad467ef78212e9e08fa2ce3f01f2acc28c0b8ca9d1479380726bab1f',310357000,NULL,NULL,'4dd02f79c7ad6348031e564ead17921d1d112b6bf8c5f4308b52ef2511983683','be20274de13d8b9bc3dded9b96ef029dab6f1a6a90b962a87cfe638874137674','6b96015e21800b5eb679dac56e3551ca346c5f0e5eda8424bc9a1c1551a04fc0');
INSERT INTO blocks VALUES(310358,'d5eae5513f1264d00d8c83fe9271e984774526d89b03ecd78d62d4d95ec1dea6',310358000,NULL,NULL,'a2815a72842de9330b82b8901f18116f208c379657cf8610c3510dad19b64124','2135d25f2fe8f36e2acef2dfb5bb3c1b48dae99269f7f51b15a7fa2553f01381','3eb3ace5d905bec995a739a5f83ce9333a19751472739504100ddb5908a113fd');
INSERT INTO blocks VALUES(310359,'4fa301160e7e0be18a33065475b1511e859475f390133857a803de0692a9b74f',310359000,NULL,NULL,'23acd53757b9ce126a8817e2727a54a23b57246c92e6fda1f16fa4d5db378973','f113f2ab4e981a64d97adf1ff605e5f53c2b36c4b386ca202d7bf5f2189f4b5e','8ec14624af5530502516ac97d6d2d97bd012ed4329a3f417aa3076f81ecd8464');
INSERT INTO blocks VALUES(310360,'cc852c3c20dbb58466f9a3c9f6df59ef1c3584f849272e100823a95b7a3c79f0',310360000,NULL,NULL,'9325c1235f22738cd4897884005d5763db8b792930a968c1c6f75300f087e484','bc63cdcfba561612f6730c4292e576090f89bcb9ea25f29ac26cdf0ef22750c1','9d5e6d03fb664a0cc94b11d8efef7992d13d0fee0ef9728066d9ffd3a6fae2c2');
INSERT INTO blocks VALUES(310361,'636110c0af5c76ada1a19fa5cd012e3ee796723f8a7b3a5457d8cb81d6c57019',310361000,NULL,NULL,'30f7ec0f50ae1e4d4dcfbbebc789dfea4669c2a21a4d251550fd6696bce94952','ece4df4830e6a9177ac3fe7b10a7b5fdfca5bb737df9809798a43e62bf05ba5a','c4dd2e75b1de57f36a5935f96c9ef5441374cee1112ae65651d2a05cd6c7bafd');
INSERT INTO blocks VALUES(310362,'6199591a598e9b2159adb828ab26d48c37c26b784f8467a6bb55d51d7b6390f2',310362000,NULL,NULL,'6fccf61f9c49986937cb13205f4ccdca952fba67c1af89d8c05da51b11ad98a4','e3cf8ba45d72d635d88828748cff5b8d807a3470cfd877d0b6a69204d2a818c1','6b2303187a2bdf95d824a116f78b5d26ee943478864d599fe137812f2b5a3721');
INSERT INTO blocks VALUES(310363,'a31967b730f72da6ad20f563df18c081c13e3537ba7ea5ab5d01db40e02647e6',310363000,NULL,NULL,'74a243525a58bb5d1c051c10d1ddacfd307b69fdbb2da618e079322f3d317b61','9c37fb5523824802a37c50dc8f5f2925daf867444142fff69be120fd4bfeb17c','bd0df483d08874b73cacee1363a6e120dc31bf4346bd6ec309507dbb63c59f8d');
INSERT INTO blocks VALUES(310364,'67025b6f69e33546f3309b229ea1ae22ed12b0544b48e202f5387e08d13be0c9',310364000,NULL,NULL,'5a0b10220431a5d6777ef9e49ba6333c7026f04ae450d48a7273732e8cd55ffa','08263909963c29064626233683fbb357a83a3e7e709f67e9a9b93e6820772be3','3cdedb9a7af47a8dd20aa3428ffc19d76ff9188b97dee1b23e002d8046b55b8f');
INSERT INTO blocks VALUES(310365,'b65b578ed93a85ea5f5005ec957765e2d41e741480adde6968315fe09784c409',310365000,NULL,NULL,'50e97232160d4b608299961f420a6218588c5650a8e45295a08f789a49b25d20','0164d4f96efbc4a9636f8d56af9151eeeac348cd4d9082dfe8ea84a19bef39b8','31c348e905705295d0767acc6622acbb1e1ffbbcf727d67f20efa1ac3b75c344');
INSERT INTO blocks VALUES(310366,'a7843440b110ab26327672e3d65125a1b9efd838671422b6ede6c85890352440',310366000,NULL,NULL,'4521f3e3fe9fc9254b0d66fb4cf24ac72c50808751791e5752195c0dfdb403fc','6ac5b135115c9810c15f4aea1837c941c2a88bf72b2d1c6c5b27bd77c8da955d','5484da74a1c9465996b6f052e6d2108c6bb7815477ecbeae83f86b0b4784a282');
INSERT INTO blocks VALUES(310367,'326c7e51165800a892b48909d105ff5ea572ff408d56d1623ad66d3dfeeb4f47',310367000,NULL,NULL,'9b89619d958dab0246a3f2c8b8f402bbeb3a59637f492b7119a9a84bd939b661','9b53a8bab2698283c2352d40fc0bd48cd6095ec8f656cb290bc17cedabd69933','4fc79bf6b7a622c75a0ad15a53f97be846906e4454933d62cb8cd6e2f5b9e8d3');
INSERT INTO blocks VALUES(310368,'f7bfee2feb32c2bfd998dc0f6bff5e5994a3131808b912d692c3089528b4e006',310368000,NULL,NULL,'569a5946690bbc8251325d0569181b4c276eedbaee5885b816ebbef86d01e196','e21e1739413cc564c5d152a6945168912b0ded7258180c98535d66fd207739fb','f56dcb5fa7da6b37743c3d0eebf60b1f9548b1028e1ac8d5467e27426c6df497');
INSERT INTO blocks VALUES(310369,'0f836b76eb06019a6bb01776e80bc10dac9fb77002262c80d6683fd42dbfc8da',310369000,NULL,NULL,'0ca340f24633d8884a88fbf3c7c9280c31460745dace8563b0b66ed382e0fa2f','916e88c245cde45db04bc6b6309a3ca8e0d58da76aec92265b63057679588a10','f070713b2f4d03430103cf324ac792d8aa3c8adafb6f1c434947c8c9ba1e3f20');
INSERT INTO blocks VALUES(310370,'9eb8f1f6cc0ed3d2a77c5b2c66965150c8ceb26d357b9844e19674d8221fef67',310370000,NULL,NULL,'290093d9212196ee4c03b9eac0245803158dba2948f158e2c74f8dc10ac09329','439ce884a12a502698627832eed35c2f808fc202251e80578adc85073760c517','4ca005b3025face6c3efcc5d9f020bb62ee2fd0e82dfe2b667fd8410a90c85be');
INSERT INTO blocks VALUES(310371,'7404cb31a39887a9841c2c27309d8c50b88748ed5fa8a3e5ba4cc3fc18310154',310371000,NULL,NULL,'fa6616279666c600602c38434c2b0fc9dfa1e551513e4144419efd45e0ee0462','70c053d718e6085cffe7b8df0455359420b813fc17a9ba58bed4938bd2993247','b85d3c622b2d1a5b117428c896f724aa6d5758a0302da1d75cf028e94a84e73b');
INSERT INTO blocks VALUES(310372,'d3a790f6f5f85e2662a9d5fcd94a38bfe9f318ffd695f4770b6ea0770e1ae18d',310372000,NULL,NULL,'25d0ad708dfe99367db6dea83491440f2c30421a5a7c4fb024d0ed79cf59b1aa','bcc0c3da21183eb567b8a0fafd7984aa42fa879b22d52ef530a38ec0c81f3bb1','0d35d2c3eeb1bd082f83c8f7ef3a4471dcd4a19ecedc980825a697bef3b743f8');
INSERT INTO blocks VALUES(310373,'c192bec419937220c2705ce8a260ba0922940af116e10a2bc9db94f7497cf9c0',310373000,NULL,NULL,'408be37b314e37b6192d85d81c706f9e25c0d7e5a5448a6ed6284d324f587054','eb3dd860874da50d846599fb5b1349afa82845341459b7751711683033912153','6ee1a193885e602271dea9f7ce892f5b0dcda132b368dda2eb7ab0b76c918418');
INSERT INTO blocks VALUES(310374,'f541273d293a084509916c10aec0de40092c7695888ec7510f23e0c7bb405f8e',310374000,NULL,NULL,'3153feb773ab5352e9380d3faedf2f32f427dd35b5de78b52293abe855c1091d','ff226314d75caf66a8ada25e48d360c39c6bbbc99e42100b85e06e7326412335','ac1c44ccc7619d7ebe1ce1e6d930fa9ba9a0ee004833adab891365d451e42554');
INSERT INTO blocks VALUES(310375,'da666e1886212e20c154aba9d6b617e471106ddc9b8c8a28e9860baf82a17458',310375000,NULL,NULL,'5364cf94d87ffdb49360513b1271c5f107a42830cc8ca70b4751045dbcf92eea','be1d157a819421d58552b5a77d4dbec17b0d0ae0f8ca5ad7f80431e167f3c469','3678cbd6c780e039e25a25399312a0fb742df12da9d61ae832bb7fbcb762a35e');
INSERT INTO blocks VALUES(310376,'5dc483d7d1697eb823cba64bb8d6c0aded59d00ea37067de0caeebf3ea4ea7dc',310376000,NULL,NULL,'ad88937d28e8e5e24af4af424cb4004005d71b7d056d8d93b9f1eeddeeafe4f5','487ed1341ba1492a515e816af4ccef7ec6f30e6768868c1913b9afec94742460','4c2c54c8882af7c38e64a06cc1f4d854f3436e5d0e989d03237c4b026b6a03a7');
INSERT INTO blocks VALUES(310377,'f8d1cac1fef3fa6e7ad1c44ff6ae2c6920985bad74e77a6868612ee81f16b0b3',310377000,NULL,NULL,'0e30a4b710daab3563f7fb624dd4170e0026e60574742b57cb64cc03d621df15','3555d0739e60b7056722413585ce9a328d867bdc7f783922eb998e13ab653811','4e9da862d37c2a5c56840f97a5b8a584209530336e0cfdf07f53d905029d03f3');
INSERT INTO blocks VALUES(310378,'fec994dd24e213aa78f166ca315c90cb74ee871295a252723dd269c13fc614ce',310378000,NULL,NULL,'7fd86de094040b85e820255f840b863f0725c53738d32952fdfc58beae9c6589','d9a555a8662bd0e507140e412f3c7c07315f7ec22801f8846d38e5fb56027cf4','2dbbefb23dcd7e1063c482db9931909bdf2f445c05a8c45823960bb05fe3b109');
INSERT INTO blocks VALUES(310379,'d86cdb36616976eafb054477058de5670a02194f3ee27911df1822ff1c26f19c',310379000,NULL,NULL,'fd89c38a53a75eee1c46a3e29cfe1bdb4956cd9bf8de15b582f0bf0d90dfa13b','d71456af3585572768196b1b1367ba7de14d2c38a06fe028b081b529efea64a3','c869566937579e4212a5c38c0c732b9d39de5d0b1c698ec9f4f7fe84bfade22b');
INSERT INTO blocks VALUES(310380,'292dba1b887326f0719fe00caf9863afc613fc1643e041ba7678a325cf2b6aae',310380000,NULL,NULL,'2967d25d8d46df256d7bdd08a1f2dc77cb42af8adb2f53830d2d9abfb2981f99','ca157084511a721faee7f09c3200c53f6d734434c2242517d16571e9205c2121','dd383394c02d74742da8b523f04029cc71add01d367bbf8218f9abe6b4b6cdf9');
INSERT INTO blocks VALUES(310381,'6726e0171d41e8b03e8c7a245ef69477b44506b651efe999e892e1e6d9d4cf38',310381000,NULL,NULL,'703a73971fe4f5d48ec8393c7e8dc8cc13374ab8a2d52c68988593c4de8817f2','015802a5cf5569f5b95be871f6111a2959f44d778428cf13cd7681ca7791266c','4e056def1739d0a74a12754cac7f1fdf533814118dca4f0c45d5a060e7990d34');
INSERT INTO blocks VALUES(310382,'0be33004c34938cedd0901b03c95e55d91590aa2fec6c5f6e44aec5366a0e7d8',310382000,NULL,NULL,'198e36c164a6f40c76112501fa1c70327e3e005a042d1369faf0126f41d58d62','59d4ebe6e94767fcb0613b4bd5a03808e166fece9e5839ee389b485a56854d9b','d6e1fb49b49ed25bfa06431825984120b9beba0158098a03f6333bc3c9fa21c5');
INSERT INTO blocks VALUES(310383,'992ff9a3b2f4e303854514d4cad554ff333c1f3f84961aa5a6b570af44a74508',310383000,NULL,NULL,'591cf03f57957fedb0522af2ca5fe111c5828157054f51a1b3fd9cf72b429a28','7eab946ed1c234df63267a17717ae2c5ba7d0b805fbcb2c54c0388114fcf8411','fbb4265a688cc652fe5dcff5e5ca040332435831b28348f2ce53a01fe3703e02');
INSERT INTO blocks VALUES(310384,'d518c696796401d77956d878cbdc247e207f03198eabc2749d61ebeadee87e5e',310384000,NULL,NULL,'5c911e05c1670a675082c98b242b80bc5ad3ddd105ae4d4bdb2cb6601e172a29','44c0ddc594379f6c5ed887137ff62bca8d0a3737413d621794911ef1b2976689','9802b7531db34c2dad745d14383a42b33e1ba198a8dca0e81814dbef09e22820');
INSERT INTO blocks VALUES(310385,'2aa6a491a03a1a16adbc5f5e795c97ec338345cfdf10ff711ffb7ac3a0e26e28',310385000,NULL,NULL,'1944f881a1202cd4aad1cb089bd916386581b94c96002cdfa67a69d7b537324f','c99ae037c9f1e59565b2d0c75132edd9bc57c62514efe95c63b1cf87820caf4f','ecb5eb0861540553936b53391aefbff9086c1b32b2a5ab64fbbdc973db96d79c');
INSERT INTO blocks VALUES(310386,'9d19a754b48a180fd5ebb0ae63e96fa9f4a67e475aeefa41f8f4f8420e677eda',310386000,NULL,NULL,'bf31cbeb8284aac77b6515ec7388d67e76e19ba79452b150a833c13c892c0ee8','17739c9a09de776ab3af34a8a79881142a88b167a0210c164adc12f54e37ff2b','0465696127c50a29615293f63ec59d35b55b0aec55e33695a1318c5c8cd3c288');
INSERT INTO blocks VALUES(310387,'b4cac00f59c626206e193575b3ba9bfddd83bbfc374ebeb2838acd25e34a6c2b',310387000,NULL,NULL,'3f82211082a2d6981de51244bb0483eebfb3bcadfd48b80151fd1c89694e2b3b','acf098cddb51901a67035ed7cdfbb8447f4829b295740c66283b0061f6f9b542','fe8bcf07c409e97cfc46aa0b1805c394d58cf0c56af125255ba4720ac6e7da7e');
INSERT INTO blocks VALUES(310388,'41a04637694ea47a57b76fb52d3e8cfe67ee28e3e8744218f652166abe833284',310388000,NULL,NULL,'59c3a3c5648f18274642df5050b117d8031f10c46be63b5864f30ecec69f0c09','a30f5c113686eb38c4b9f8c30617918222abfea1109f3ed9996214a799449f83','396f7385d1f88e9b2e5d3cbc88c5a8c644a13768d08289543c6c166adcbb4a1d');
INSERT INTO blocks VALUES(310389,'3ec95ae011161c6752f308d28bde892b2846e96a96de164e5f3394744d0aa607',310389000,NULL,NULL,'fbacb621beff1e0769d716ed51493afe97874941feb7787b5cc80916e3ed09ac','b3d0e621da438447839457af02cf4f34e6825f77a0c35d7dfa31e42602e83aed','c64f3b3c237806f39f0bf82c875bbf85b07b5ed497103528e24ddbd36a484b95');
INSERT INTO blocks VALUES(310390,'f05a916c6be28909fa19d176e0232f704d8108f73083dded5365d05b306ddf1a',310390000,NULL,NULL,'a2c398743a97092d8ea6875970fb1662470fb5918f09e50c132c29ee6fcc9b35','53346c85b849a9b9e53f4aa584f8b736a40ab04b11447fecbd518d4fc1a44e69','9a9006bf0be7806ea41c2ee3b85891582affd28e9cb54f1d97a38389552c6223');
INSERT INTO blocks VALUES(310391,'fc26112b7fdd8aaf333645607dabc9781eac067d4468d63bb46628623e122952',310391000,NULL,NULL,'cb3842fc91685c97b6db5ab71e1586259c83c619ecd57dd653a213b5c4a9f9a1','0350718a71dcd8294b7a643388294c7dfd864240775dfafd6fca4f7e33194b38','c80ab831971eca300323de277a5ebdfdf476a614381e84d027a1e427af3d392a');
INSERT INTO blocks VALUES(310392,'f7022ecab2f2179c398580460f50c643b10d4b6869e5519db6ef5d5a27d84a1d',310392000,NULL,NULL,'780ea5e6adc1e9ae328efe2ea25af76ae2e228c98b475b6337ed84e5924e3b95','2e1a0f82a2ef9f7162c4d04dc216f6987da9a760e27aa530efbf24fa6c6e8dce','159bb96de8fa3b5aeaeb24dc48c56e0c4b7359112fb6406f7e4af9be1d2b6a03');
INSERT INTO blocks VALUES(310393,'e6aeef89ab079721e7eae02f7b197acfb37c2de587d35a5cf4dd1e3c54d68308',310393000,NULL,NULL,'6f61090175f1e398ae20dfcc41e5075327ccbd297c786c8a09a866a77836d429','0ef43c8e9ae2103046ee6d16f874405af3cbeb36e7896989420c2de9c5bea96c','2fa5c345e0c78a2256b9244fad172c885b6e0e858217c0d7d937b4de255dc86d');
INSERT INTO blocks VALUES(310394,'2a944743c3beb3bf1b530bd6a210682a0a0e9b0e6a9ff938d9be856236779a6f',310394000,NULL,NULL,'8cdcec6732f3d4f2da04edc5a59cbe67fbb27ea069efdc23e4bc92f055fe4223','ee39062b144f42c30782a45aa1843bdd4567999510c0c62e17964b30bd4d08e4','e5e8457e15a8e11d38401083f2b1e5ebb943dc09d0ebc96ca5aa8c7c1c48706d');
INSERT INTO blocks VALUES(310395,'19eb891ce70b82db2f2745e1d60e0cf445363aaff4e96335f9014d92312d20e4',310395000,NULL,NULL,'291b2e82b5bf5ebee0ab534e53cc2a748429d7248ba1194a8f673552ff65cdea','fdb7c480e0cbb68ee71be396184e5e5ab41fa60f2f81b3e482834051ed3d6f8f','2770fc68cca9a6c2a0b2477cfa2a77f3b9bfaa6674d84e758ea4fde7b07eb2e1');
INSERT INTO blocks VALUES(310396,'aea407729ac8d8e9221efd9d70106d14df6aaf9f2f87dc6f490835a9caadf08e',310396000,NULL,NULL,'9698aa62d90bffb57f7b8b92e4275dd6df0b53d5e539dbe3440cc8f885881e65','10f3f5f89514ac776afca181750714e9b3e4f14409b242a08e2cd065cbcb9f54','343b84bdb19db3198dd66ed676c5d776339d2e1b239d4f273a655463ed0c113c');
INSERT INTO blocks VALUES(310397,'7c429e56a19e884a8a77a759b52334a4b79404081b976270114043ba94d7985c',310397000,NULL,NULL,'bcb427bbccd91cbce4402f5b9495d789a81e22fd80467f8023e33b98f487eda2','4f8f3a766845e4328f00d001640cd9d9ff4c623672298544559693395ad6c753','ee4a61bff082bb724eae07fc080b8d08f0cbbfdf9988d949f3cbd125ce79b7ed');
INSERT INTO blocks VALUES(310398,'55c046db86dee1d63c0e46e6df79b5b77dfd4ab2ff5da79e6360ce77dd98335e',310398000,NULL,NULL,'3833e3ac7b7b74948268b6588ecb6b6752ab22138e0d2f477e3dbef12adab776','ab0aa68023dbffa47ab25866edc7f1aa3df50e022cc55ecdf565ad5ebb29abb2','2cd8f3b00d58f68abec2650a263eb169cda7e497b73a4f46eb5cf602f9e75bdf');
INSERT INTO blocks VALUES(310399,'765abc449b3127d71ab971e0c2ae69c570284e0c5dacf4c3c07f2e4eca180e7a',310399000,NULL,NULL,'c15cf8452811e6df6f5438f8343f9a3421e75eb9aeed8e42eb0658e89c64dd51','dfb44efdb2e80193c53edfe5882d4d8995fdb016a245115d614a082d5e0a290f','1cde7b204ba6e784847c3c51f153550b33915006d7689c4500c5b1e79396c079');
INSERT INTO blocks VALUES(310400,'925bc6f6f45fe2fb2d494e852aaf667d8623e5dae2e92fdffa80f15661f04218',310400000,NULL,NULL,'bd993e2a64b62f6c376e338e9beddaa0ac0501b39883506f2472e533bb19cbec','1c74aa2904eeff12b1257a22a422ab429628925cc46303b0d5ca9039b824e6a1','ddbb5aa81fc6b76dd6828ea837f7887ef8f0d63ef5fcd721f7a0f263431cc916');
INSERT INTO blocks VALUES(310401,'f7b9af2e2cd16c478eed4a34021f2009944dbc9b757bf8fe4fc03f9d900e0351',310401000,NULL,NULL,'e6dd67cdf805c23e353ec25468f2ea830da46e4104dbc537e9e15a5acc1b28fe','33219c95ff8bf94049f35beacd2af9c618edb312a54727e7c9ec223e366d0472','5917ed866972ce3b326bdfd992c0afb76120b4e70f936dd86e7ebc24b17b2348');
INSERT INTO blocks VALUES(310402,'1404f1826cd93e1861dd92ca3f3b05c65e8578b88626577a3cbad1e771b96e44',310402000,NULL,NULL,'6b19a39e68b8418c2eb1650bd1427438dfd65bf627bb6b50ae3a903c9169ff4f','63599f9ceb3effb655fd85cf352f40108968053a1c73b3e439bc7a9e905aebf4','df2222c12c7cbc1ccfd18c08a9755b1cf2ed0cb0b95fdc2ef6d469b58f84c58d');
INSERT INTO blocks VALUES(310403,'f7426dbd4a0808148b5fc3eb66df4a8ad606c97888c175850f65099286c7581c',310403000,NULL,NULL,'bf22dd1b8b936a1eff32dea79c9cbffda251bc59ed2754f73c139155eeb2eae3','a3498583bdd179cedc8a9f61230e948856a544fea929122ee8978206fd343eff','7753b6a34d5cbcc950e2a44552ec0d460430365af95a90dc45da4efd5993bee0');
INSERT INTO blocks VALUES(310404,'401c327424b39a6d908f1a2f2202208a7893a5bedc2b9aff8e7eda0b64040040',310404000,NULL,NULL,'2dff8ef48ea2026e72bb327368bff21d40eb321ef8c9ab5552c6b9f40dadcefe','d17a531076e0a62e3f01a866d75fa8cc6b98e6c33416d09b3eaa5cfec879a938','b58de5667e738c40591bac014caf3d1bc2b4609d6cf1abfe7e3e8fa0d41e4218');
INSERT INTO blocks VALUES(310405,'4f6928561724e0f6aab2fc40719f591823ca7e57e42d1589a943f8c55400430a',310405000,NULL,NULL,'35b2f3fb27f707493d53ab0eb8eb239891be2a050a1f7ea9fffeacc1b6e6056c','f2a26650ef19bf87ce28ebec33f4d4fe601faef814b0392613a86f94675dca81','1713660d9d30019fa619a551e85291df0cd3a226f076903561c5b5afc4238dbc');
INSERT INTO blocks VALUES(310406,'6784365c24e32a1dd59043f89283c7f4ac8ceb3ef75310414ded9903a9967b97',310406000,NULL,NULL,'4a962a898f5795990de43cd3133a60b5b969ad366de6bca8d0b9fcb366759d1a','604d29fae8a52f6ba8cfbcf16ce44b78befd115ae48c2294397488da3d882662','022635b43116945a5166011c3ac93fceda7f8873bfbdf88ba981460c1641815c');
INSERT INTO blocks VALUES(310407,'84396eb206e0ec366059d9e60aefdb381bca5082d58bffb3d2a7e7b6227fc01e',310407000,NULL,NULL,'18e8aad129099c20f268ef8a3664253f8d444a24e3c4942369bbeb80fb76c862','f4e1288a6baf109f3fdd7a8d9423ce2f282ee42c0cb95acbfd477fcf9785aa05','6663ceab6bcbde6fe8a0da7dfb8879a40302c610289963ab280599fe55accde9');
INSERT INTO blocks VALUES(310408,'4827c178805e2abae5cb6625605623b3260622b364b7b6be455060deaaec2cda',310408000,NULL,NULL,'b694511530b99c6a6d405871f2fde7470baef8e0a2545b598adce5c3b9234765','ed4905bbf119adf89307632d9d6a396fc9864807bad0d54590eec85266f506cc','45bd0efc327804785eedc9701e0aafd735fba0f3546afd1b356501a09155ab49');
INSERT INTO blocks VALUES(310409,'01a719656ad1140e975b2bdc8eebb1e7395905fd814b30690ab0a7abd4f76bba',310409000,NULL,NULL,'cfc8dcee1ef668455b7c078698de8c164abcbfe7f6159fe206faeee7b0ec006a','abe609836792c5960b486c84af36eb55b2ceaf5654af412b72a9213d165cea2a','3a699f86ab6719f6b3c7e7bbe8f504bd7cfaec3a697b3680f8ae9d1baf981dcd');
INSERT INTO blocks VALUES(310410,'247a0070ac1ab6a3bd3ec5e73f802d9fbdcfa7ee562eaeeb21193f487ec4d348',310410000,NULL,NULL,'52eeb77c0ba4767d59e4ba0e243032c44ae83abea1fb407c2079e58e869d6437','48c99ff0097ae298a6c49fb5b48443957309169d220a0a282a9ff132e2fef9c0','142f4826a438b89f17402396b71a13534c70bae4c41affd78648848c654c475c');
INSERT INTO blocks VALUES(310411,'26cae3289bb171773e9e876faa3e45f0ccc992380bb4d00c3a01d087ef537ae2',310411000,NULL,NULL,'10224812cf36a49d15040fb1a3ad3e580f4690e8309dda99713bade55f2299d4','01ad472840427da6f11a0e775fff20b6dd670c800dbceae6483f77b2cb71131b','f4071794d30bd5017207241846afffa388e43af197c868a9e1dbbe57e3aaccb6');
INSERT INTO blocks VALUES(310412,'ab84ad5a3df5cfdce9f90b8d251eb6f68b55e6976a980de6de5bcda148b0cd20',310412000,NULL,NULL,'2e095263dab63461abb4210a78c96ba09181cdb55fe67113edf6badd5da8a386','bae546c161784cbf1a395c13c15c4c06e748ff3c3250904a99537c6cac602307','e9a37848daeda2298bd79b95d0dc436b56fe549f58073cb6e0c3e6eb8f297ff1');
INSERT INTO blocks VALUES(310413,'21c33c9fd432343b549f0036c3620754565c3ad99f19f91f4e42344f10ec79bf',310413000,NULL,NULL,'5201dd7aaf4dd358441bbca3ec6785eb9f7bb36d25e9aca9e5cecf0e9391b7b3','89e0959561512ac77bfa930692b8858feac0689b4fb650d457a644ead5888e06','b8d20a9bdacc3e16f15faf2b7d271e81f4aac5c4e0ed86a909ba20d5f40d88e0');
INSERT INTO blocks VALUES(310414,'8cff03c07fd2a899c3bcf6ac93e05840e00de3133da14a413e9807304db854b6',310414000,NULL,NULL,'95de8fbba49b748c4fa28565b47230dd294ac6b02906d1dd7aeea73126db9513','29147db8c1bfa90d50d0d00410ab9bf64dfc997a438e22ac590c679b3a1a37a9','5cf5cdebe2599ecf2448cac470683d711d7c974c8845459dc88e36e13a40ec25');
INSERT INTO blocks VALUES(310415,'dd0facbd37cca09870f6054d95710d5d97528ed3d1faf2557914b61a1fc9c1cc',310415000,NULL,NULL,'53a7b4628a5273f5b893f64af2db6d66b5b9e4ffe5ae5076b274537245f53b6d','05de14335c611dcaa45b7d819bae349df26ee5833e557895d958cca603b9a835','e3509c8fe401934f72531fc210b9f1b57285aacdcbbe1ab20ba12e01eccdaede');
INSERT INTO blocks VALUES(310416,'7302158055327843ded75203f7cf9320c8719b9d1a044207d2a97f09791a5b6b',310416000,NULL,NULL,'f38e62a046767b352776b03cc9103137061d2ebc1365a6589e8604affd29ea84','3556bf39adac2f45ec3179e9580ff4016b3548961a90593b452f6bde3b85ff3a','e02fd566cb870e5bb84a079610e1a2cb07157172e136c35bb0d000011f5118f8');
INSERT INTO blocks VALUES(310417,'2fef6d72654cbd4ea08e0989c18c32f2fe22de70a4c2d863c1778086b0449002',310417000,NULL,NULL,'752734f6cb598502a13f567da58739e021aed45268f52c3a56aa94c77dbe4294','211d496d0c9bb980b1706e321a4a5eb9ace33242f73b83ae6a5589dacf300079','61cad6960b30afac0bdf44e75a65633f74ee8115c755734ecd9adfc75e897889');
INSERT INTO blocks VALUES(310418,'fc27f87607fd57cb02ce54d83cec184cf7d196738f52a8eb9c91b1ea7d071509',310418000,NULL,NULL,'778a0c66fa9454d466fda8bf21ac02b03d80e18380cc79bff8b481d7832977af','48fea1645ef2a3460f34307df871dbb47270d50d21a9af0a2bd2a4fd00415f97','98e9760f0cb12153d08b8ae85fa75398cd835be05a2a751cfd2bfc5e3f54f327');
INSERT INTO blocks VALUES(310419,'9df404f5ce813fe6eb0541203c108bc7a0a2bac341a69d607c6641c140e21c8e',310419000,NULL,NULL,'1dd204b4df4f865718b1cffb54a452885c04a524c4f9cd6be0e92bcc937f49db','16a51fd5b1e93ac1daafa4684ebd6fd6dd532af49c00753fb6c11b94249eafcf','bd59013904d362d6b0aaeec28aed3b4587f80a4d66738db68effdbf23a772a10');
INSERT INTO blocks VALUES(310420,'138b3f1773159c0dd265a2d32dd2141202d174c2e52a4aeac3588224a3558372',310420000,NULL,NULL,'3b77f802ef867f0fd92f1dfff4f7c5ad074ed51f0ed2b1a5d39f1f44e6aa7ae5','8151917651ac68ac45f4e06be17ae7bf99722d723e0c1def80892d0c436321bf','8b9bc32a05b07aa0dcf2c83cfaa23521134060b074acd5527545dad5343171d1');
INSERT INTO blocks VALUES(310421,'71fe2b0e02c5cad8588636016483ddd97a4ef0737283b5fd4ab6ea5dc5c56b9a',310421000,NULL,NULL,'6d417941e380b66715edb4e74fb63026f35411ce7782afc0a6abd2f5d6193934','4d2447e6e2ab26af24ffa65422d94322e5df5e2cc58a095e0d1c4d4a0d39974c','509a59f7d63c253fc83d0ce1eb5a7f47cafbd967124a0104e12b6f8db4dba9da');
INSERT INTO blocks VALUES(310422,'cd40260541b9ed20abaac53b8f601d01cd972c34f28d91718854f1f3a4026158',310422000,NULL,NULL,'593383ba8869cf5afef0a8bd1212a9a87e69ed1f79d24423f3e268b22038d865','e8e595dcf8c240aea5bf232ac5aaa81f4c96badd9c63c2ab41688ee08283dd3d','71f6a72a125c0c003ca2700bf3cd0f64af447964db5e2dd9c546208c74cee67c');
INSERT INTO blocks VALUES(310423,'6ca0d6d246108b2df3de62a4dd454ff940e1945f194ba72566089f98ad72f4db',310423000,NULL,NULL,'03ad9d534765ed15c02046dd7076f8d0f9332b987336f779a52ef7da5a63d2bc','e6fdabbcbc72252dbd8f09493e80286ef1762fa25399e2c09a8d74c7bf5d73e3','8376b134cf228351324ead4605024ffaba07ba3a16ab44bf460b8e474ad0ac8f');
INSERT INTO blocks VALUES(310424,'ed42fe6896e4ba9ded6ea352a1e7e02f3d786bfc9379780daba4e7aa049668ad',310424000,NULL,NULL,'028be1a76113906628e18a5ac0b00db7d8769e2450f145653c3b5f117cce2d1d','e3feeffb779b390bb1cb37ef65ac4cbdeedf9f0c19cc58327a919b62009bb403','080d5e232ff5acfd492513800dc1f43240eebf995bb138a7620a0249fb940ec0');
INSERT INTO blocks VALUES(310425,'73f4be91e41a2ccd1c4d836a5cea28aea906ac9ede7773d9cd51dff5936f1ba7',310425000,NULL,NULL,'83d4a7d8ffab3c5f6d2637ee98a2ed4bf9633f54a630a65c882190bab089bc2d','fb49457d7dfd4674983952fd9a85c4ffeef07cb46fd2ef48a6ee3f42387974be','2a6cf8cf176efe8722dac10f66f21ae4af82d11fb534d1164a55e2f78b4d318a');
INSERT INTO blocks VALUES(310426,'9d28065325bb70b8e272f6bee3bc2cd5ea4ea4d36e293075096e204cb53dc415',310426000,NULL,NULL,'7642193a01f93b2511299f4a024138db83f9affa5e14145bd0a4ff0a12fe89b9','e0e5086fa5722cc5c1c8d74fe4d1cf0d7a5ea58bbb40f38473f4d3e20d1b5f06','e773d8668f1c744e5a2d90524d6f9c28feb30339966a8cc9415a723c331abb9c');
INSERT INTO blocks VALUES(310427,'d08e8bc7035bbf08ec91bf42839eccb3d7e489d68f85a0be426f95709a976a2a',310427000,NULL,NULL,'8e53bab070408894fa8b2b12a8628b2ae262567533f2a1c49dcb51e564d8baee','c9e1b8ed67e3c9266911d2a07c90d1af388a1fd118dd8e23e7fd575986e03785','d08a627ee0dcd25723182cf90980e097ea235e92ccd78930025a788826062702');
INSERT INTO blocks VALUES(310428,'2eef4e1784ee12bcb13628f2c0dc7c008db6aaf55930d5de09513425f55658a2',310428000,NULL,NULL,'f0af90a06b842c2d6646744b9c7e851e77cd73f27c1e97282aa3e774acb5206e','ed94f7c961e452f30fa8958f2b5d17ced3cbc56af0e161f178456f9231de47a1','c2f0b944c1941fdd4520d983aba66e3023524b997999d8c03e5706f32da0cd2a');
INSERT INTO blocks VALUES(310429,'086bfbba799c6d66a39d90a810b8dd6753f2904a48e2c01590845adda214cf8d',310429000,NULL,NULL,'d96b15c84b51ab0ac9e7250232ec744bfea32aaa46b3202182bb1ba30637530a','62e1436180263692b92ecd030cce5dd585ef0a1a6faed8a9f2f4785c6447a32f','3af09a8c283adb707e2a2dcd72f43dbf68dba17870565083cce83bf02d599b18');
INSERT INTO blocks VALUES(310430,'870cf1829f84d1f29c231190205fe2e961738240fc16477c7de24da037763048',310430000,NULL,NULL,'5877f31065e08853d538bb8ff2ab3204d2e7c46003afd715c7ab7e3eba36171e','0246e38b5e0dfa13782c3f7528355796efa8e740c261b71f86cacd1db81fef55','757e314884e9ca071295b737f41fa4a4f7c60f0d0adb1dbd978df5a6040736f9');
INSERT INTO blocks VALUES(310431,'20b72324e40ffc43a49569b560d6245c679e638b9d20404fc1e3386992d63648',310431000,NULL,NULL,'c7693ebfe358dcb264ac98eb74f0d35b8102bc49a189d678c4aa83b792b92b01','55ba14415919a297321d026e04a2b46a9ffe278fc4da093b05c3d7e7865b63a4','c1ed845264a1eb804419df9c386aae133ed4d621c0019ee9fc8bee55dff57c19');
INSERT INTO blocks VALUES(310432,'c81811aca423aa2ccb3fd717b54a24a990611365c360667687dc723e9208ad93',310432000,NULL,NULL,'2e4118a5f40e5a2d4da07622568a61e52ecae05dacd3dd54364015666b9ddf0f','7509e61357fc75ba2176586237c8e05cd22aac141c6e899be2c62809d5f7ebd7','3e1d55ab190e62b51bbad376bdf3126821def26a397e7923ddacb3f0bea232f5');
INSERT INTO blocks VALUES(310433,'997e4a145d638ad3dcdb2865f8b8fd95242cbc4a4359407791f421f129b1d725',310433000,NULL,NULL,'4508c61899741ad3637f891664cd17e8d8dce2147ec22bbddd23d18be7d4f5d8','1f1b18b11bc7e981bd74e0df4b91963a5bd10225ea545ae1e3577132dfc41ffd','dae097c0788d25631af996add4eaf3e16f24640f66bdfbefba4510984d7062be');
INSERT INTO blocks VALUES(310434,'61df9508e53a7fe477f063e0ff7e86fbb0aef80ff2ddedc556236a38f49ac4d8',310434000,NULL,NULL,'222a7017a5159405dfa7ca716a368f84df446612b2e969ec775a56297f67c445','c53c99a8154491d9a836a066383bcf58e70d6cd5e71613512bc1eed7b70a6de9','9fb3627dbc89161cc378021f294daeeabf42c5bae291ad54d2dfefb3046a8984');
INSERT INTO blocks VALUES(310435,'f24cf5e1296952a47556ac80a455a2c45da5c0dc2b388b51d235a3f741793d5f',310435000,NULL,NULL,'cf0f27b94a70b0dba7ee5391c51df323c154c767b21e7f18696cfb93e25e663e','c8bca0410fdfbb46cb9ffc162176cdf95fcb775e204424a9ddb0ec1d2f0db28f','ad3bb889d8e2184325fc96281e2ca1e53ed1fd07dc264e8d6462a18cadb538f2');
INSERT INTO blocks VALUES(310436,'a5e341ba92bdf9b3938691cd3aab87731eba5428bb61a804cecf9178c8da0c19',310436000,NULL,NULL,'15455076d1eb6681233124bd7f4fd59586a22067bb008d8132e31c0019f3990d','da7196d082c6622c7d940fba6336d05924f0301cd4d4b5e4307ca3d7d71e5485','c1c32601a348aa06ec7067d6a648218094bbcc69e1c33b57d22fdc77b954ca35');
INSERT INTO blocks VALUES(310437,'9e18d0ffff2cb464c664cefc76e32d35752c9e639045542a73746f5ec2f3b002',310437000,NULL,NULL,'03e6c21526a9e7ad688f8ee47638b2519b2a1ff0c47332da366a1077a9d93dae','17c6b597055007cbbac1e59c84ceef646f540febca7a050563c6e97f19df6a52','b6ebad365dc353ff4246e8e00832256e70dd87028f9a6844759bb6b8b2da4240');
INSERT INTO blocks VALUES(310438,'36be4b3470275ff5e23ed4be8f380d6e034eb827ebe9143218d6e4689ea5a9fc',310438000,NULL,NULL,'dca613e290eaea92a4bde4f759fca67923568f0af3ece38c4165fe66787f5a61','3c64c4aa659226e1023a62244b3b66a1013082d27094ccf2d5d2e25fe4e6c33a','dc3250f19e3a730354b0e69e175a622aeecf22451f255753801088c948179f7c');
INSERT INTO blocks VALUES(310439,'4f2449fce22be0edb4d2aefac6f35ce5a47b871623d07c2a8c166363112b2877',310439000,NULL,NULL,'9da932c8c4c9a12d536db15649b8b89df52be294f3a3b16692618d2af421c1b7','ff2de4f81b7958fa652bc4a08adf6d152292e35b27966cfcc457407940679725','5bf39031b06d444cab216428e6e76abd2817df7e2940611fa336abed13c1cfd3');
INSERT INTO blocks VALUES(310440,'89d6bd4cdac1cae08c704490406c41fbc5e1efa6c2d7f161e9175149175ef12a',310440000,NULL,NULL,'ac9f1ff2a3adffd79ea3b2b13289ea060d2fa1ed9656a61057d1802531737221','815f2e41812b9deb25711e01611daeddf31b7eb6ef7b988cbd864d0f1d22f332','ed451f4563c97a0c6fe236e8b6ba087c9e4130fd270cc1dfb8f3019cbbdb08ad');
INSERT INTO blocks VALUES(310441,'2df1dc53d6481a1ce3a6fee51ad4adcce95f702606fee7c43feda4965cf9ee15',310441000,NULL,NULL,'4513dbf40e2b572ccfdb857eb58d4008b82959d110c094961cc7587ca9672316','a27c634b837fbdbbd67f74a08f17cdf3aa1c12bce6ae7a99ea47f8287ce36fb9','7d405ae5324483eece7788c35652ff4f6df4ec30f832a0d958d92cd6cd415b72');
INSERT INTO blocks VALUES(310442,'50844c48722edb7681c5d0095c524113415106691e71db34acc44dbc6462bfec',310442000,NULL,NULL,'e806ef15930bf2104b63bde714b397312052322dd034f0df727b738e05e1c753','febbff9acd52ce4d2fe25167f29485b2702eef278971d7909765b15a887162b7','71bd811c2b7296e51f6e3059a0c19d74517d50acc53fd9111bd6ebb78f3375e2');
INSERT INTO blocks VALUES(310443,'edc940455632270b7deda409a3489b19b147be89c4d8f434c284e326b749c79a',310443000,NULL,NULL,'3f6cf11776817de3eeece3f754656bba718ed2d9fd52034f8c49b27ab12bae8a','131973051c4238b092f1305f5f9b778d4bc11a66313ad43fe3d47af0c00b71b2','247132e2058492d1370f1dab9bbc7e4c0e2f08a086b8ccf2f114c519d5ae4a5f');
INSERT INTO blocks VALUES(310444,'68c9efab28e78e0ef8d316239612f918408ce66be09e8c03428049a6ee3d32e4',310444000,NULL,NULL,'da23b14ec6cc706fbeec8e796522dab412bc72b96833ebe9eb799e72623129b0','c019c7b5a1909c4ccf97568985f8d23efc1b5b05f2aa82e47dde6b68597e2a33','21b76e0f0e3ff526f160f7123a2c301cca6c6de533e4adeb1b50fe74f63a53dc');
INSERT INTO blocks VALUES(310445,'22a2e3896f1c56aefb2d27032a234ea38d93edf2b6331e72e7b4e3952f0234ef',310445000,NULL,NULL,'50e9c4330e9f1fc6c563bf924064999f3e8feee2fe107884a95c913df2008da4','84d30dc2e5093ec3f79d0af9cb3c6025c72a890c093356d4c35cb8ba78368ab1','022c37e4a4beae6dd482123cf47f01beee2d0081ec96c373f76dbf57de96431d');
INSERT INTO blocks VALUES(310446,'e8b0856eff3efce5f5114d6378a4e5c9e69e972825bc55cc00c26954cd1c8837',310446000,NULL,NULL,'1b6f3d210ff3f0b1c0342419467a17c0d34ea1eea4e99ecb5ddf5e280818a983','50aa2301ab2dd3375095633ec3f3003ecffa68e0edd59c8132e30e9d2a492c01','642321ebeaa21dec338784e9c971a0cda3914881556c68f0e0360e310cba7032');
INSERT INTO blocks VALUES(310447,'3f4bc894c0bc04ee24ed1e34849af9f719f55df50c8bc36dc059ec5fa0e1c8a8',310447000,NULL,NULL,'d5d10b1d7843d4070508a79192c7b1bb92876e64acef659c01ffce3c5ba5cfc5','9d2d419e94667a2972624d1e18eb5fb06c0298867f21a321ac4e9eb25894f436','9af39f348e31648afa4f982b1ac3880de45dd82f067bbb28e03afd7a01b58dd7');
INSERT INTO blocks VALUES(310448,'6a6c7c07ba5b579abd81a7e888bd36fc0e02a2bcfb69dbfa061b1b64bfa1bd10',310448000,NULL,NULL,'488c8a4a6aa3850d0ea6c0f12ecf4cc9bf400aae8c4b5e4cc5589152abe5a90b','301aa8288d3241b6aa5dfa98e227dde2c902c8802f97771b685659c7d520fbe8','30b22ab51df1a93a674048780778460702dc3043bbc6f1b4c99608c389f8eafe');
INSERT INTO blocks VALUES(310449,'9e256a436ff8dae9ff77ed4cac4c3bfbbf026681548265a1b62c771d9d8e0779',310449000,NULL,NULL,'5f8b738744da401e84d1174587d7e2900278621f3497adb94115167218e3d68f','ee1f54f521e5544e8ef2990eaf40fde43ddff1e3d931ade1c7ec7b0330ad7174','8866116bf07d673547ed4c03a0c0ca914ea59806b51b87f0daa1d2d518bcbfe9');
INSERT INTO blocks VALUES(310450,'2d9b2ccc3ad3a32910295d7f7f0d0e671b074494adc373fc49aa874d575e36a3',310450000,NULL,NULL,'185dba1b235227514d6ba11bd279b9fb05607714831edbc854c3dad8d17ee11c','acff19b1c62420f9dd5e2918f5c25e01170d13b2400757a776e08b838154fba9','082fbd1cf15604afc9f0b3b614c01ec8d0ec6a85763e3f2c115b6f95b259a932');
INSERT INTO blocks VALUES(310451,'55731a82b9b28b1aa82445a9e351c9df3a58420f1c2f6b1c9db1874483277296',310451000,NULL,NULL,'605cbe563d57fd6cc0d05d40e6217703ef899c9e61bdef381cf996403a782808','08eb205f27bbd239d279f0a0db1d3c79190745fca45928e0a45ea8c88e486b99','2b562af5b070e07dbf441f0d8584b7606ecfa986b7909f4930a9a91360447430');
INSERT INTO blocks VALUES(310452,'016abbaa1163348d8b6bc497cc487880d469f9300374a72ecb793a03d64572aa',310452000,NULL,NULL,'c3ccf7d83bde4f7b5777c902b809841ae0c4c2db098bcabdd1aff128ffc6fd5a','10c94d8bb72576a4a30caa635cea812e482903cb7c7a0361d81b14bf89ac95c5','fb04f1523a7253368a2646e93df49789585991896fb3d7555adcefe78f299392');
INSERT INTO blocks VALUES(310453,'610be2f49623d3fe8c86eacf3620347ed1dc53194bf01e77393b83541ba5d776',310453000,NULL,NULL,'3dac0390da1c50e05051eaa60ad2aacb0112adc54e0f0041a00db0a519333ebb','8b5a4126ea2cfe4a3c0370a4ff16fd84ce21ef7433ca15bf802c90acf9295eea','b84475f33c5b7d74245586aa4c79df286097967bd2f75490822b9cf974f5c502');
INSERT INTO blocks VALUES(310454,'baea6ad71f16d05b37bb30ca881c73bc48fd931f4bf3ac908a28d7681e976ee9',310454000,NULL,NULL,'8fea87fc079398499692f207ae111d25a034576c0f2407383a20bf73ffe66d06','e0a6d769be014246e58c1aabc64303201c0d7dd0486a5a4aa8b52141baa80a1c','5f98eff5f8c0b0e6136037cd2da40dacddb0f773b275fc2c2cd485aacb1081af');
INSERT INTO blocks VALUES(310455,'31a375541362b0037245816d50628b0428a28255ff6eddd3dd92ef0262a0a744',310455000,NULL,NULL,'ce885b73d40cb2ddb6ec6474bd94ab4470515679f54fb47fc5bca7a87d1ca261','6282b40292a630e750f155361f8d6b22448463991ad2ac5852c05462192ab944','30a1b9484c51e7a112e36cd2d19f52da2d96d3e03e301db713afff5e35d2fb92');
INSERT INTO blocks VALUES(310456,'5fee45c5019669a46a049142c0c4b6cf382e06127211e822f5f6f7320b6b50fa',310456000,NULL,NULL,'16693fd96eb42e01b5ccac8c4978a882a50ff534c33ef92d9eab923988be8093','df8315fea6ae73ca16282d877e44bc9234676fdf469b711df547138c29a89190','535117267266e6d93c076552c943cdc3191792dbb301a05e49ecc9105d90fd78');
INSERT INTO blocks VALUES(310457,'9ce5a2673739be824552754ce60fd5098cf954729bb18be1078395f0c437cce9',310457000,NULL,NULL,'81c06ed2e28e3eb67497d2508ec8399558d4be177fdefc525b7cf8010546da82','f5d12e13a2fe512366d7934f3ad3b2001699fec790ea355d1200cc2d923c4a3a','ec404c357ffe16cc96c9b8b7583077969ad5ce68395489895778eff9c4577017');
INSERT INTO blocks VALUES(310458,'deca40ba154ebc8c6268668b69a447e35ad292db4504d196e8a91abdc5312aac',310458000,NULL,NULL,'bb906ce3def50a1573ded94e2ee8cd278375318479682145a72a3b9cd67f18ec','69eefa070b7ef046551e89446b96af27c8aef3b0f455018885dc6569b3c76d99','3ca09b76c355986fdf2c6f425112e1f19f69cc01dadde052a765efb9c7e35219');
INSERT INTO blocks VALUES(310459,'839c15fa5eea10c91851e160a73a6a8ee273a31ab5385fe5bd71920cbc08b565',310459000,NULL,NULL,'874afd2de9bfa523ab45482e1d2ff2a9136af0bd5ade66d7943564c504ef944f','abbf77fa5497af8edce1122ed28c4066f4c9b1c79b006473bb1a4bf6e324a4bb','41874e84c3a98cb4366306c9ece2f8402c13f087cf36c750fe918762bc7eb02f');
INSERT INTO blocks VALUES(310460,'9b5f351a5c85aaaa737b6a55f20ebf04cafdf36013cdee73c4aaac376ad4562b',310460000,NULL,NULL,'890e72732c1d57443213ee7a7270b3e2a7e9087522f57189ac61cd6dc852abfa','8d438347c55dc398bb0285829ae42ab937e55627885e6a89b1d2ca86dddfa1da','e7a889e8e9b96a87c6e2caea22655838c550ba01bb1efeeb4ae2f16dcc983ae9');
INSERT INTO blocks VALUES(310461,'8131c823f11c22066362517f8c80d93bfc4c3b0a12890bdd51a0e5a043d26b7b',310461000,NULL,NULL,'8627256f470d906d5c784ba257f4f7d29e0d81347c7566727aaa26afd0a9b251','d7f95468c65ab34b6d42fe1637ac98fbac811985fa81a1649b38d266b3e52053','3b44c17031939bc77489a3f7f4517dfb378a9b15ab8ad34da9ec162237178d90');
INSERT INTO blocks VALUES(310462,'16f8fad8c21560b9d7f88c3b22293192c24f5264c964d2de303a0c742c27d146',310462000,NULL,NULL,'d1829d2db4718331aea74e59d3fcedc3f510aaab82f3f7f956087b32c040f63d','4c06942b14c13386da46c23d88307a66c343638fda5c1b05fe6c7be669ea9a31','a4aa6de74cc22a45c993b13793983ce655f702ea011755b2cdf7e5e7a94751a5');
INSERT INTO blocks VALUES(310463,'bf919937d8d1b5d5f421b9f59e5893ecb9e77861c6ab6ffe6d2722f52483bd94',310463000,NULL,NULL,'8b83bf9e263c69e8f731d90c9e6f92b66dd1652ea76390ceec58883f3ffe881e','c837a03ea1a50288c3623015812f2cc87ccc045da8e2de7ba8e01c0194599f73','90c8d56da9b0ba82466bde97df6d4dedd0aad5a41359fd569004e61ab8011ccc');
INSERT INTO blocks VALUES(310464,'91f08dec994751a6057753945249e9c11964b98b654704e585d9239462bc6f60',310464000,NULL,NULL,'a93fbb5f298b41d3123312fe41ed8c5811410c32ac31062ff513c69a6ada8e53','93ac270e7703cd96c1a3822a3d48e2947528d9e6c4b44dd93eb7278b118ec371','3edc52d45d6091eae8d8c14fd9359168d2b8b8453bcba6002a7a51ca35e87188');
INSERT INTO blocks VALUES(310465,'5686aaff2718a688b9a69411e237912869699f756c3eb7bf7c3cf2b9e3756b3d',310465000,NULL,NULL,'19ea9e27f997fcaa3c260bed12a628b55054b6f90d579ff3e41ab1cb29240778','27bc497f7131e95d384869a8270fd78644be8736df0a4e1d16d7e07bee0f4377','fb2ddefb06546dc35b0340718bcddfdd2ccfe15c912026a1f4229a9f2005a60b');
INSERT INTO blocks VALUES(310466,'8a68637850c014116da671bb544fb5deddda7682223055a58bdcf7b2e79501fc',310466000,NULL,NULL,'90c850f7cfe700fdea8d8d60fa03f080861414ec372a7d920ca6d09217f82fda','aff9e7a84ecadd2aff5453cd668f9aa493d6c32910275155a09912a2f3519e05','95ef44ff864525094858a70216f293cf39d411967fcf4ae1a8eaeb552deb7882');
INSERT INTO blocks VALUES(310467,'d455a803e714bb6bd9e582edc34e624e7e3d80ee6c7b42f7207d763fff5c2bd3',310467000,NULL,NULL,'9f92428bfddcff24329af3b4c0b3200e8b4ae3065f9b6a8a6488e159abfe6854','a14416a0405f208c20b5bc5555d925f930ba1cf99410bf58c9bb42a46f18c0c3','8f20f4fc736c3daa165b3c228c6d7fa774da45f83a3afcf2a823939abf1b82c9');
INSERT INTO blocks VALUES(310468,'d84dfd2fcf6d8005aeeac01e03b287af788c81955612375510e37a4ab5766891',310468000,NULL,NULL,'0cf6101033a96e6a90572ab21502314470c4b544bf21a902845861c413e1775f','18d7f9691a278555077c1be67f84fad99c6d2b57ad22334b853317e99287567c','554594ef0ce8aeb304781a5d406f81137ff0880bcddd7900beb963ea58118427');
INSERT INTO blocks VALUES(310469,'2fbbf2724f537d539b675acb6a479e530c7aac5f93b4045f4356ea4b0f8a8755',310469000,NULL,NULL,'93f157cc43a6dc2df588c7cbddca37e55eddf5a94fcac82ebeec2d8d252a515f','9d85c386561c44b5b16fe018bae294c17a1771608d6f4bdfb6b1229348bb9dbc','6f10064a77811cb9fede5a5a761962aed8c32e739b8155c8d1974d78293f3d30');
INSERT INTO blocks VALUES(310470,'ebb7c8e3fbe0b123a456d753b85b8c123ca3b315da14a00379ebd34784b28921',310470000,NULL,NULL,'d6ebcad8b1743d6dd898a522304594242eb063893c1d07baa893c076f6ccdc3e','4634249a7400c6d727d73f5435f8ee6476fa340def5616d1f91c7f6dd14e6807','c2f03a3f39d559cdc3ba85b2058f1fc94bc029797e9c26208c03b9112a663aca');
INSERT INTO blocks VALUES(310471,'fc6f8162c55ecffeaabb09f70f071fd0cb7a9ef1bccaafaf27fe9a936defb739',310471000,NULL,NULL,'e6003555728c70ecd67dc8de1248de291a2d3a5d9fed35d77fd0888b5c7a1997','d62e872c323ebac5ae09eeffed73def26bf556b3ef300ee3cd3b699c6dc4e927','d593e87b8c5be925e7c9c64c4232fb1dedaeb0c468c241bae2975f4f9fa40372');
INSERT INTO blocks VALUES(310472,'57ee5dec5e95b3d9c65a21c407294a32ed538658a6910b16124f18020f16bdf7',310472000,NULL,NULL,'dd553bc627b16f15cd618dd0504cd0ec04724610ff6ed44515957c997385c826','fb25dc650468c33d57810143add6a386c910a653786490c2c58b0adc575fb8d4','f5d8dd7bc02f6e07c6fdd06cd3891faf8778c22346ae6d05c038f55aa176e089');
INSERT INTO blocks VALUES(310473,'33994c8f6d06134f886b47e14cb4b5af8fc0fd66e6bd60b3a71986622483e095',310473000,NULL,NULL,'9290c164b0b011d53eb80193285fcfd830e524183cce1be181a48f085601845e','2611bc1daf47f6e05fe48f7c5ed74358d5050dc084a764af2f70df1849042c41','3d0777f0aa748f19b423bc5c521f112a10f1d4970ac708a798587804eaba8f5c');
INSERT INTO blocks VALUES(310474,'312ee99e9526e9c240d76e3c3d1fe4c0a21f58156a15f2789605b3e7f7794a09',310474000,NULL,NULL,'7aba0609948218e622e3293760bfddaa1ac4669eeaac6ec897aef5ab1268774f','2121504a80fb11fc359e1f103300b0c00b00e833e36cfb05f1d628574bdde2d0','8472b2282f85d78bf83f158555210d41b42f8d98143bbc63bfead16056c4cd37');
INSERT INTO blocks VALUES(310475,'bb9289bcd79075962117aef1161b333dbc403efebd593d93fc315146a2f040eb',310475000,NULL,NULL,'bf95d8500066d276cc48546cc2c29398e26511097cc658b21d6a537c2d8876d7','3b883bcdbc918e68bf80e237a8537202e9e2fd2299a7a3ce004d3fad4db7288d','5795846733597968a011a0a3e9c62a54ce3070adc08de683102a3ffce4cfc99d');
INSERT INTO blocks VALUES(310476,'3712e1ebd195749e0dc92f32f7f451dd76f499bf16d709462309ce358a9370d0',310476000,NULL,NULL,'89d6256d5a7f5412a5eeb9b5551860b7ea26b096a2b8196b61d437ba7ee797f6','e6b565b52d97b45fa97aad87f67c983a7108fa0fa433dbb610e1617379d8048e','694a6c066f27419022056e0db9327303a9c8b788d15292ca29a72fdcc415952b');
INSERT INTO blocks VALUES(310477,'7381973c554ac2bbdc849e8ea8c4a0ecbb46e7967d322446d0d83c3f9deab918',310477000,NULL,NULL,'31e4ee682d84213876eb8d85cb92d32688c4dd9110a9a90d74cfa275b50b8bec','7bf535294c2fa6eb1128c9fab86f5319f068e1790d89fee15e05f9e4c14ff097','f27ae63f7170315ddbce3d0c1e0dc36200624f9b3ad55162b22ef1969525a415');
INSERT INTO blocks VALUES(310478,'c09ee871af7f2a611d43e6130aed171e301c23c5d1a29d183d40bf15898b4fa0',310478000,NULL,NULL,'941bcbb6d7a89a86859fdc1516c0e64a1473b356f42846d2e8a353b08967fd46','ab7cd6358f280ddb97cbe6a8d51e3818f84cb24665c0ea06827720f8c2b12e51','1c91412fbe1740ddbbfbd86837bda41b29b8cc66fbf4fd70dcf73030b546fcc3');
INSERT INTO blocks VALUES(310479,'f3d691ce35f62df56d142160b6e2cdcba19d4995c01f802da6ce30bfe8d30030',310479000,NULL,NULL,'8c271f55a292b69f95c50228be57e8a1a91b94998756abd8ce431e657fa4055c','7bff74b9ac8e1ebf1c7cbdcfab28b4e088261ea4a42b64ee2df131c67710e285','d845c133dba1cb37822e1a2b998e0a39990ce118aadc0abcf3c3b8dec3aa1d8b');
INSERT INTO blocks VALUES(310480,'2694e89a62b3abd03a38dfd318c05eb5871f1be00a6e1bf06826fd54d142e681',310480000,NULL,NULL,'aa0c833f96cce186008d339452e92d054edd67397c538baac239b10df8f9bcbb','066c727c391e574300fa7b223daad5c80ab2f580f250c802a32c40aa16163fae','f718927540a03706511fdd694f77ae795caa588ce93857c388a7883d4c4f41c5');
INSERT INTO blocks VALUES(310481,'db37d8f98630ebc61767736ae2c523e4e930095bf54259c01de4d36fd60b6f4a',310481000,NULL,NULL,'596ff1cd4069e7a0d62db64acfe1502ca4bfc6d3ac792794ad980c5f654f1a01','a249ad7745e74ad9d3501c712c74ce43d02fc78b5c872b15af1423fe2f02cf0a','5c4220651a860d7bb15c849c69bc1c73447ee7f7476082f7baf77fe65aae9f83');
INSERT INTO blocks VALUES(310482,'2e27db87dfb6439c006637734e876cc662d1ca74c717756f90f0e535df0787d6',310482000,NULL,NULL,'bbc1ac936d3ea0f0ab911d79ec003e0ce0c20d6adf507dc5c94a773659b0b734','ecfc753e4b7f4379799771fb1a0f5e12c6a4971b0d21f1b460f24189f9f375ab','76ae61200882816011bdcebb38e1023981e76e554d9aa53c89ecbeaddbd216ef');
INSERT INTO blocks VALUES(310483,'013bac61f8e33c8d8d0f60f5e6a4ec3de9b16696703dea9802f64a258601c460',310483000,NULL,NULL,'008c287f38d96307ee4a71ea6a8f2c42a35dd54c4a834515d7a44ced43204845','e45a4bf7dbb5eb5a90691bc4dfb8fb6186c055dd7216a759ba7ed29bca411cbc','6af8cefa6ef1b330637d1251332d3ac7e3ad19ae501520518431b453b21a0758');
INSERT INTO blocks VALUES(310484,'7cac2b3630c31b592fa0497792bed58d3c41120c009471c348b16b5578b3aa2b',310484000,NULL,NULL,'d7f3ec5feb14b12b410fa72344620e930037d15cdb36295fc68aa0f4087eb631','1bbf6a10f74ca3ba035c5506a78b37beda3e879fdf874dda2741c15e28bd86ed','336ce66d1c65da35931c41b01ad2e08e5647d95feac8a48d25b914ac0b7c053e');
INSERT INTO blocks VALUES(310485,'eab5febc9668cd438178496417b22da5f77ceaed5bb6e01fc0f04bef1f5b4478',310485000,NULL,NULL,'10856cb1b7625aa217ea3009f10aa1e772a627e302f4191eaba5d332b8daea32','6b2d637dba204ff18228dab2c5dbba696ec2bf2f9b1a06546511abadd48615b2','cf76515eae2d8f30017f3943e45a5d47401300453114740b9441913fc362ae3c');
INSERT INTO blocks VALUES(310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,NULL,NULL,'d4d08e6c5c0a9d491cd2c754047a78a566a86a0b4ef81c3037a9d438803a0fb6','a640f0b19cf14babf14d41982ff845aa3667dc32da886647ece043e185af1272','13254a30ebd0bfe4beec38a5ecd326b57f4e2a9ffbb3ee42c28415aa54548f42');
INSERT INTO blocks VALUES(310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,NULL,NULL,'bca482be2e942516ffc60a62ea7ea7e44158e8f9b72bb6e5dbe61cd740d300bf','6e3c4cca5f5682ee9a50b27b00c74ff5b1137f00b470cce718cdf3bdd60db931','b92a7c0d7be96f9f1f2725f0adc3d5ef1d7379c2e37b43d8cddc0d31ea1d9f1d');
INSERT INTO blocks VALUES(310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,NULL,NULL,'fd124a3f80b354ca106cd653717837f460b565aa5b4b40dc23ecd56b3b97b28b','6be825e503c2898fc40466eada5aac8eaac987fe89ad6a0540fc75ae491350b3','7fb427d9a9150cc57aac367370a4f6252c4b77a95f6030dd97cfa2fb1ed1fefe');
INSERT INTO blocks VALUES(310489,'2efdb36f986b3e3ccc6cc9b0c1c3cdcb07429fb43cbc0cc3b6c87d1b33f258b6',310489000,NULL,NULL,'dc544e57a124565269bbb4b2d9ae2102e6ed177196b07e02d55a9ac99611b752','c77bdae069a699918619ec7e41771ac9ca2b5d4851da48051a6e8abd20b24679','f94bb1369549d864c827449b9158cddc49e045f54f474740927e086bd756467c');
INSERT INTO blocks VALUES(310490,'e2cb04b8a7368c95359c9d5ff33e64209200fb606de0d64b7c0f67bb1cb8d87c',310490000,NULL,NULL,'8165de494fbcaee2f48f0ed7b671d5a7164b4e4e6198b5e1cd8f88850af150d7','1cd3d0e2d493e389cc741347b7f85b9de03e483835d003e9819e69b875d6dcdb','654bb48add9eea56a10982358030e4b2504b64b65c567f95a207ca072c3bf450');
INSERT INTO blocks VALUES(310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,NULL,NULL,'953105bd7e2e93c74ed3ed8b8717d7238d636a0cc4e50d152a1783aa5f320204','ef4ed30793dfeab8675b59339099f15b20f2ffcd27a0aec2a814f045acb11803','137979d62826edac8ba6198c8b4918c38d5825ad9a6673349fcd9c987144ac5f');
INSERT INTO blocks VALUES(310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,NULL,NULL,'1fed308916a5912e8b0166d5a27ce74e23ddddcfd3f7b99ed77a01ff398142e1','4561ad10b6ad1260660bf760a68f71404282b172313edfa9a650516d67e28a11','2e8e6a06ac0bffa6cdcabe0b18e3bd8e2dc7a5204d1e7753182c1bdcc1caa78e');
INSERT INTO blocks VALUES(310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,NULL,NULL,'c0136baee1305a5e5a933fa78f2f93cb40d06adf04540c94dab3c085208e1d25','03c56866a8ba773da7e464c24dad9ff10f2e0c294b2506d6685f2bf8e432fc29','fe28c0469627238bd247c6e49bd2f368d9e8c36bc26742843e284ba81ae7b99c');
INSERT INTO blocks VALUES(310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,NULL,NULL,'7e6e5551f8eaa241d3289fcae360170937aa4a35f2926611ab50793b7cbf1b30','f402360a582fa07b36e917b70c57595776a5ae507761dac55478dec2891d065b','e09ab3f1735a57f2eedbd1e1cb84d4087dfa54507720e8360c638f073c85ee28');
INSERT INTO blocks VALUES(310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,NULL,NULL,'0b40890a253248a31cf00d2f75abcbc9871318364ec224ce94cd5c6d29b15621','0eb91907781f309dbb7c0f725b8d708a9b3093b1fda190b1c7c8a0b515566fda','4df5b0ac6cacf112112e672dc6d0b8aeee3396073d63b10af829f97fff3bb3b1');
INSERT INTO blocks VALUES(310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,NULL,NULL,'88aaf1b7f8cce768bb3744e68017b52fa82999dc6ababf7c0cab9621f9ab4160','9bae96910778e0d6154b578a57c9607ba80cfdd37f50629c360d88d95cb4b178','f34e5e54e1b478c963ba88f0cdbfffe18d19c25d3406b4661a33ba367c4a2db1');
INSERT INTO blocks VALUES(310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,NULL,NULL,'e59e7a3224fc64320bc9b6fc3c3c4661cc9bc5664be9b9228e2dee585aef1c9c','132e6fb38039bdfc6e24be37cd83e45c56e2e06750058ab3f287a306df327d54','44478f7d80c0378e98767de6d1073eb330af6dbdc4f444353c8bf5a8ad9dd8ed');
INSERT INTO blocks VALUES(310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,NULL,NULL,'f4706664a1f25bba7cbd6066a363b8cdec56eb30fda7fcb14ba5edba4913b166','0e9ba9402410e0850184e21914a4cbcd16c4827bfc775cb2c2c5d3b377b8b2a8','4ad5cc83052297b7956b61b104604f73731d1da4f36cb7d383363f8c31dcaad9');
INSERT INTO blocks VALUES(310499,'1950e1a4d7fc820ed9603f6df6819c3c953c277c726340dec2a4253e261a1764',310499000,NULL,NULL,'f20bbd39329e3beeb339faa2342de45dcd59a6c032ea945ba10e5fa0b9b263c5','cd1341b9e783de5335f74f281b3ca402297612adb40e6664f92ed3fd820cf966','75eeb7bb1bcc8c9911fe509b9232c58fcfba249fe01ce83c1f448621d98178aa');
INSERT INTO blocks VALUES(310500,'54aeaf47d5387964e2d51617bf3af50520a0449410e0d096cf8c2aa9dad5550b',310500000,NULL,NULL,'d32f6e610de4c09918a4272f0904e3e5ed3638fbeb4088c877dfb9f51a1b62dc','09be91891f3cf71ca66734d798f3e54966a8ec00889c3d6dc9d75313585e5962','aae8c9d237cb5615fbd6429baa17406c0166bbf9338b18e7e9464a5aea572a20');
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
INSERT INTO broadcasts VALUES(489,'94f8d074561077cea511427c1ebf65243fcffd8a372afe904898a83aa86d1cca',310488,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',0,NULL,NULL,NULL,1,'valid');
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
INSERT INTO messages VALUES(80,310486,'insert','broadcasts','{"block_index": 310486, "fee_fraction_int": 5000000, "locked": false, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "096883e142a87377d3a4103f4702556e25824f1e23667aceb1690f66e1417062", "tx_index": 487, "value": 1.0}',0);
INSERT INTO messages VALUES(81,310487,'insert','debits','{"action": "bet", "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "asset": "XCP", "block_index": 310487, "event": "2447f6974033ac41c40b4598dfb73fc7479fd85bb9d01de2267b3f7842803275", "quantity": 9}',0);
INSERT INTO messages VALUES(82,310487,'insert','bets','{"bet_type": 1, "block_index": 310487, "counterwager_quantity": 9, "counterwager_remaining": 9, "deadline": 1388000001, "expiration": 100, "expire_index": 310587, "fee_fraction_int": 5000000.0, "feed_address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "leverage": 5040, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "open", "target_value": 0.0, "tx_hash": "2447f6974033ac41c40b4598dfb73fc7479fd85bb9d01de2267b3f7842803275", "tx_index": 488, "wager_quantity": 9, "wager_remaining": 9}',0);
INSERT INTO messages VALUES(83,310488,'insert','broadcasts','{"block_index": 310488, "fee_fraction_int": null, "locked": true, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": null, "timestamp": 0, "tx_hash": "94f8d074561077cea511427c1ebf65243fcffd8a372afe904898a83aa86d1cca", "tx_index": 489, "value": null}',0);
INSERT INTO messages VALUES(84,310491,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310491, "event": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09", "quantity": 100000000}',0);
INSERT INTO messages VALUES(85,310491,'insert','orders','{"block_index": 310491, "expiration": 2000, "expire_index": 312491, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 800000, "get_remaining": 800000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09", "tx_index": 492}',0);
INSERT INTO messages VALUES(86,310492,'insert','orders','{"block_index": 310492, "expiration": 2000, "expire_index": 312492, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 800000, "give_remaining": 800000, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "tx_hash": "2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4", "tx_index": 493}',0);
INSERT INTO messages VALUES(87,310492,'update','orders','{"fee_provided_remaining": 6800, "fee_required_remaining": 892800, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09"}',0);
INSERT INTO messages VALUES(88,310492,'update','orders','{"fee_provided_remaining": 992800, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4"}',0);
INSERT INTO messages VALUES(89,310492,'insert','order_matches','{"backward_asset": "BTC", "backward_quantity": 800000, "block_index": 310492, "fee_paid": 7200, "forward_asset": "XCP", "forward_quantity": 100000000, "id": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09_2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4", "match_expire_index": 310512, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 310491, "tx0_expiration": 2000, "tx0_hash": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09", "tx0_index": 492, "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_block_index": 310492, "tx1_expiration": 2000, "tx1_hash": "2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4", "tx1_index": 493}',0);
INSERT INTO messages VALUES(90,310493,'insert','credits','{"action": "burn", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310493, "event": "c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a", "quantity": 92995878046}',0);
INSERT INTO messages VALUES(91,310493,'insert','burns','{"block_index": 310493, "burned": 62000000, "earned": 92995878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a", "tx_index": 494}',0);
INSERT INTO messages VALUES(92,310494,'insert','debits','{"action": "issuance fee", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310494, "event": "4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5", "quantity": 50000000}',0);
INSERT INTO messages VALUES(93,310494,'insert','issuances','{"asset": "DIVIDEND", "asset_longname": null, "block_index": 310494, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Test dividend", "divisible": true, "fee_paid": 50000000, "issuer": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "locked": false, "quantity": 100, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "transfer": false, "tx_hash": "4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5", "tx_index": 495}',0);
INSERT INTO messages VALUES(94,310494,'insert','credits','{"action": "issuance", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310494, "event": "4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5", "quantity": 100}',0);
INSERT INTO messages VALUES(95,310495,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310495, "event": "129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc", "quantity": 10}',0);
INSERT INTO messages VALUES(96,310495,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "DIVIDEND", "block_index": 310495, "event": "129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc", "quantity": 10}',0);
INSERT INTO messages VALUES(97,310495,'insert','sends','{"asset": "DIVIDEND", "block_index": 310495, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 10, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc", "tx_index": 496}',0);
INSERT INTO messages VALUES(98,310496,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310496, "event": "1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(99,310496,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "XCP", "block_index": 310496, "event": "1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(100,310496,'insert','sends','{"asset": "XCP", "block_index": 310496, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 92945878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6", "tx_index": 497}',0);
INSERT INTO messages VALUES(101,310497,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310497, "event": "076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f", "quantity": 50000000}',0);
INSERT INTO messages VALUES(102,310497,'insert','issuances','{"asset": "PARENT", "asset_longname": null, "block_index": 310497, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Parent asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f", "tx_index": 498}',0);
INSERT INTO messages VALUES(103,310497,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "PARENT", "block_index": 310497, "event": "076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f", "quantity": 100000000}',0);
INSERT INTO messages VALUES(104,310498,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310498, "event": "0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf", "quantity": 25000000}',0);
INSERT INTO messages VALUES(105,310498,'insert','issuances','{"asset": "A95428956661682277", "asset_longname": "PARENT.already.issued", "block_index": 310498, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Child of parent", "divisible": true, "fee_paid": 25000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf", "tx_index": 499}',0);
INSERT INTO messages VALUES(106,310498,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "A95428956661682277", "block_index": 310498, "event": "0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf", "quantity": 100000000}',0);
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
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
INSERT INTO sends VALUES(8,'95f1a544034d2814b7c484e4525891813fa9c10bb71f012f70602f99f31195ef',310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','DIVISIBLE',100000000,'valid');
INSERT INTO sends VALUES(9,'8d1e0fb12f2d7522615b11f81dcde1c58892f47e44b7f56b51f639440dbd4dbc',310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'valid');
INSERT INTO sends VALUES(13,'1acf929efa6296558b1335f3cf94bd7260979c531097e2c4d0efc3d333fa5568',310012,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',300000000,'valid');
INSERT INTO sends VALUES(14,'62dfaed0ee983d767b9aec98cc49d716b807281e9e8e5d5cd8c5207c0d2f15dd',310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','DIVISIBLE',1000000000,'valid');
INSERT INTO sends VALUES(15,'9bb2e42d2f4ab601b7e8f50364fb1caed9dc9e8dc9071f660804f559bef875ba',310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','NODIVISIBLE',5,'valid');
INSERT INTO sends VALUES(16,'62172989ab319f239125b4635102e593a01cb4e7ba70a42d533ed9c61fadcca4',310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','NODIVISIBLE',10,'valid');
INSERT INTO sends VALUES(109,'f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481',310108,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000,'valid');
INSERT INTO sends VALUES(496,'129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc',310495,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','DIVIDEND',10,'valid');
INSERT INTO sends VALUES(497,'1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6',310496,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','XCP',92945878046,'valid');
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
INSERT INTO transactions VALUES(110,'510f6feb902159622d83f64eae590a4fec88989869a20caf5804c313aa5e0186',310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','',0,7025,X'0000001E52BB33023FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(111,'d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048',310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',5430,7875,X'00000028000352BB33C8000000000000000A000000000000000A0000000000000000000013B0000003E8',1);
INSERT INTO transactions VALUES(487,'096883e142a87377d3a4103f4702556e25824f1e23667aceb1690f66e1417062',310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','',0,6800,X'0000001E52BB33003FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(488,'2447f6974033ac41c40b4598dfb73fc7479fd85bb9d01de2267b3f7842803275',310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',5430,7650,X'00000028000152BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(489,'94f8d074561077cea511427c1ebf65243fcffd8a372afe904898a83aa86d1cca',310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','',0,6800,X'0000001E52BB33023FF000000000000000000000046C6F636B',1);
INSERT INTO transactions VALUES(492,'9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09',310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000000010000000005F5E100000000000000000000000000000C350007D000000000000DBBA0',1);
INSERT INTO transactions VALUES(493,'2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4',310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','',0,1000000,X'0000000A000000000000000000000000000C350000000000000000010000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(494,'c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a',310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
INSERT INTO transactions VALUES(495,'4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5',310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','',0,6800,X'00000014000000063E985FFD0000000000000064010000000000000000000D54657374206469766964656E64',1);
INSERT INTO transactions VALUES(496,'129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc',310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj',5430,7650,X'00000000000000063E985FFD000000000000000A',1);
INSERT INTO transactions VALUES(497,'1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6',310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj',5430,7650,X'00000000000000000000000100000015A4018C1E',1);
INSERT INTO transactions VALUES(498,'076ae3d8eeb7fb40d2ae27692340157c746d9832806766b0dac5adb1526dc78f',310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,7025,X'00000014000000000AA4097D0000000005F5E100010000000000000000000C506172656E74206173736574',1);
INSERT INTO transactions VALUES(499,'0abfce2662c05852fd8b181a60900678643cedad47b23a853b8c4eda82cb2cbf',310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,7025,X'0000001501530821671B10650000000005F5E10001108E90A57DBA9967C422E83080F22F0C684368696C64206F6620706172656E74',1);
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
INSERT INTO undolog VALUES(131,'DELETE FROM broadcasts WHERE rowid=487');
INSERT INTO undolog VALUES(132,'UPDATE balances SET address=''myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM'',asset=''XCP'',quantity=92999138821 WHERE rowid=13');
INSERT INTO undolog VALUES(133,'DELETE FROM debits WHERE rowid=22');
INSERT INTO undolog VALUES(134,'DELETE FROM bets WHERE rowid=5');
INSERT INTO undolog VALUES(135,'DELETE FROM broadcasts WHERE rowid=489');
INSERT INTO undolog VALUES(136,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92050000000 WHERE rowid=1');
INSERT INTO undolog VALUES(137,'DELETE FROM debits WHERE rowid=23');
INSERT INTO undolog VALUES(138,'DELETE FROM orders WHERE rowid=5');
INSERT INTO undolog VALUES(139,'DELETE FROM orders WHERE rowid=6');
INSERT INTO undolog VALUES(140,'UPDATE orders SET tx_index=492,tx_hash=''9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09'',block_index=310491,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''XCP'',give_quantity=100000000,give_remaining=100000000,get_asset=''BTC'',get_quantity=800000,get_remaining=800000,expiration=2000,expire_index=312491,fee_required=900000,fee_required_remaining=900000,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(141,'UPDATE orders SET tx_index=493,tx_hash=''2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4'',block_index=310492,source=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',give_asset=''BTC'',give_quantity=800000,give_remaining=800000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=2000,expire_index=312492,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=6');
INSERT INTO undolog VALUES(142,'DELETE FROM order_matches WHERE rowid=1');
INSERT INTO undolog VALUES(143,'DELETE FROM balances WHERE rowid=19');
INSERT INTO undolog VALUES(144,'DELETE FROM credits WHERE rowid=24');
INSERT INTO undolog VALUES(145,'DELETE FROM burns WHERE rowid=494');
INSERT INTO undolog VALUES(146,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''XCP'',quantity=92995878046 WHERE rowid=19');
INSERT INTO undolog VALUES(147,'DELETE FROM debits WHERE rowid=24');
INSERT INTO undolog VALUES(148,'DELETE FROM assets WHERE rowid=9');
INSERT INTO undolog VALUES(149,'DELETE FROM issuances WHERE rowid=495');
INSERT INTO undolog VALUES(150,'DELETE FROM balances WHERE rowid=20');
INSERT INTO undolog VALUES(151,'DELETE FROM credits WHERE rowid=25');
INSERT INTO undolog VALUES(152,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''DIVIDEND'',quantity=100 WHERE rowid=20');
INSERT INTO undolog VALUES(153,'DELETE FROM debits WHERE rowid=25');
INSERT INTO undolog VALUES(154,'DELETE FROM balances WHERE rowid=21');
INSERT INTO undolog VALUES(155,'DELETE FROM credits WHERE rowid=26');
INSERT INTO undolog VALUES(156,'DELETE FROM sends WHERE rowid=496');
INSERT INTO undolog VALUES(157,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''XCP'',quantity=92945878046 WHERE rowid=19');
INSERT INTO undolog VALUES(158,'DELETE FROM debits WHERE rowid=26');
INSERT INTO undolog VALUES(159,'DELETE FROM balances WHERE rowid=22');
INSERT INTO undolog VALUES(160,'DELETE FROM credits WHERE rowid=27');
INSERT INTO undolog VALUES(161,'DELETE FROM sends WHERE rowid=497');
INSERT INTO undolog VALUES(162,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91950000000 WHERE rowid=1');
INSERT INTO undolog VALUES(163,'DELETE FROM debits WHERE rowid=27');
INSERT INTO undolog VALUES(164,'DELETE FROM assets WHERE rowid=10');
INSERT INTO undolog VALUES(165,'DELETE FROM issuances WHERE rowid=498');
INSERT INTO undolog VALUES(166,'DELETE FROM balances WHERE rowid=23');
INSERT INTO undolog VALUES(167,'DELETE FROM credits WHERE rowid=28');
INSERT INTO undolog VALUES(168,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91900000000 WHERE rowid=1');
INSERT INTO undolog VALUES(169,'DELETE FROM debits WHERE rowid=28');
INSERT INTO undolog VALUES(170,'DELETE FROM assets WHERE rowid=11');
INSERT INTO undolog VALUES(171,'DELETE FROM issuances WHERE rowid=499');
INSERT INTO undolog VALUES(172,'DELETE FROM balances WHERE rowid=24');
INSERT INTO undolog VALUES(173,'DELETE FROM credits WHERE rowid=29');

-- Table  undolog_block
DROP TABLE IF EXISTS undolog_block;
CREATE TABLE undolog_block(
                        block_index INTEGER PRIMARY KEY,
                        first_undo_index INTEGER);
INSERT INTO undolog_block VALUES(310400,131);
INSERT INTO undolog_block VALUES(310401,131);
INSERT INTO undolog_block VALUES(310402,131);
INSERT INTO undolog_block VALUES(310403,131);
INSERT INTO undolog_block VALUES(310404,131);
INSERT INTO undolog_block VALUES(310405,131);
INSERT INTO undolog_block VALUES(310406,131);
INSERT INTO undolog_block VALUES(310407,131);
INSERT INTO undolog_block VALUES(310408,131);
INSERT INTO undolog_block VALUES(310409,131);
INSERT INTO undolog_block VALUES(310410,131);
INSERT INTO undolog_block VALUES(310411,131);
INSERT INTO undolog_block VALUES(310412,131);
INSERT INTO undolog_block VALUES(310413,131);
INSERT INTO undolog_block VALUES(310414,131);
INSERT INTO undolog_block VALUES(310415,131);
INSERT INTO undolog_block VALUES(310416,131);
INSERT INTO undolog_block VALUES(310417,131);
INSERT INTO undolog_block VALUES(310418,131);
INSERT INTO undolog_block VALUES(310419,131);
INSERT INTO undolog_block VALUES(310420,131);
INSERT INTO undolog_block VALUES(310421,131);
INSERT INTO undolog_block VALUES(310422,131);
INSERT INTO undolog_block VALUES(310423,131);
INSERT INTO undolog_block VALUES(310424,131);
INSERT INTO undolog_block VALUES(310425,131);
INSERT INTO undolog_block VALUES(310426,131);
INSERT INTO undolog_block VALUES(310427,131);
INSERT INTO undolog_block VALUES(310428,131);
INSERT INTO undolog_block VALUES(310429,131);
INSERT INTO undolog_block VALUES(310430,131);
INSERT INTO undolog_block VALUES(310431,131);
INSERT INTO undolog_block VALUES(310432,131);
INSERT INTO undolog_block VALUES(310433,131);
INSERT INTO undolog_block VALUES(310434,131);
INSERT INTO undolog_block VALUES(310435,131);
INSERT INTO undolog_block VALUES(310436,131);
INSERT INTO undolog_block VALUES(310437,131);
INSERT INTO undolog_block VALUES(310438,131);
INSERT INTO undolog_block VALUES(310439,131);
INSERT INTO undolog_block VALUES(310440,131);
INSERT INTO undolog_block VALUES(310441,131);
INSERT INTO undolog_block VALUES(310442,131);
INSERT INTO undolog_block VALUES(310443,131);
INSERT INTO undolog_block VALUES(310444,131);
INSERT INTO undolog_block VALUES(310445,131);
INSERT INTO undolog_block VALUES(310446,131);
INSERT INTO undolog_block VALUES(310447,131);
INSERT INTO undolog_block VALUES(310448,131);
INSERT INTO undolog_block VALUES(310449,131);
INSERT INTO undolog_block VALUES(310450,131);
INSERT INTO undolog_block VALUES(310451,131);
INSERT INTO undolog_block VALUES(310452,131);
INSERT INTO undolog_block VALUES(310453,131);
INSERT INTO undolog_block VALUES(310454,131);
INSERT INTO undolog_block VALUES(310455,131);
INSERT INTO undolog_block VALUES(310456,131);
INSERT INTO undolog_block VALUES(310457,131);
INSERT INTO undolog_block VALUES(310458,131);
INSERT INTO undolog_block VALUES(310459,131);
INSERT INTO undolog_block VALUES(310460,131);
INSERT INTO undolog_block VALUES(310461,131);
INSERT INTO undolog_block VALUES(310462,131);
INSERT INTO undolog_block VALUES(310463,131);
INSERT INTO undolog_block VALUES(310464,131);
INSERT INTO undolog_block VALUES(310465,131);
INSERT INTO undolog_block VALUES(310466,131);
INSERT INTO undolog_block VALUES(310467,131);
INSERT INTO undolog_block VALUES(310468,131);
INSERT INTO undolog_block VALUES(310469,131);
INSERT INTO undolog_block VALUES(310470,131);
INSERT INTO undolog_block VALUES(310471,131);
INSERT INTO undolog_block VALUES(310472,131);
INSERT INTO undolog_block VALUES(310473,131);
INSERT INTO undolog_block VALUES(310474,131);
INSERT INTO undolog_block VALUES(310475,131);
INSERT INTO undolog_block VALUES(310476,131);
INSERT INTO undolog_block VALUES(310477,131);
INSERT INTO undolog_block VALUES(310478,131);
INSERT INTO undolog_block VALUES(310479,131);
INSERT INTO undolog_block VALUES(310480,131);
INSERT INTO undolog_block VALUES(310481,131);
INSERT INTO undolog_block VALUES(310482,131);
INSERT INTO undolog_block VALUES(310483,131);
INSERT INTO undolog_block VALUES(310484,131);
INSERT INTO undolog_block VALUES(310485,131);
INSERT INTO undolog_block VALUES(310486,131);
INSERT INTO undolog_block VALUES(310487,132);
INSERT INTO undolog_block VALUES(310488,135);
INSERT INTO undolog_block VALUES(310489,136);
INSERT INTO undolog_block VALUES(310490,136);
INSERT INTO undolog_block VALUES(310491,136);
INSERT INTO undolog_block VALUES(310492,139);
INSERT INTO undolog_block VALUES(310493,143);
INSERT INTO undolog_block VALUES(310494,146);
INSERT INTO undolog_block VALUES(310495,152);
INSERT INTO undolog_block VALUES(310496,157);
INSERT INTO undolog_block VALUES(310497,162);
INSERT INTO undolog_block VALUES(310498,168);
INSERT INTO undolog_block VALUES(310499,174);
INSERT INTO undolog_block VALUES(310500,174);

-- For primary key autoincrements the next id to use is stored in
-- sqlite_sequence
DELETE FROM main.sqlite_sequence WHERE name='undolog';
INSERT INTO main.sqlite_sequence VALUES ('undolog', 173);

COMMIT TRANSACTION;
