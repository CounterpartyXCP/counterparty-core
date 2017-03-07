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
INSERT INTO bet_match_resolutions VALUES('bf4cbb16b58a03c1f715e7dacf49f20bd184d9f197756b7977135241fd708cb3_0590f213f0549ecf353969f9ec8140b6ecd4b67f9d2912cd58ec6b4b1b756a20',1,310102,'1',9,9,NULL,NULL,0);
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
INSERT INTO bet_matches VALUES('bf4cbb16b58a03c1f715e7dacf49f20bd184d9f197756b7977135241fd708cb3_0590f213f0549ecf353969f9ec8140b6ecd4b67f9d2912cd58ec6b4b1b756a20',20,'bf4cbb16b58a03c1f715e7dacf49f20bd184d9f197756b7977135241fd708cb3','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',21,'0590f213f0549ecf353969f9ec8140b6ecd4b67f9d2912cd58ec6b4b1b756a20','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',1,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000001,0.0,5040,9,9,310019,310020,310020,100,100,310119,5000000,'settled');
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
INSERT INTO bets VALUES(20,'bf4cbb16b58a03c1f715e7dacf49f20bd184d9f197756b7977135241fd708cb3',310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000001,9,0,9,0,0.0,5040,100,310119,5000000,'filled');
INSERT INTO bets VALUES(21,'0590f213f0549ecf353969f9ec8140b6ecd4b67f9d2912cd58ec6b4b1b756a20',310020,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1388000001,9,0,9,0,0.0,5040,100,310120,5000000,'filled');
INSERT INTO bets VALUES(102,'01e52b7501ff34946978d395da5b6b03032bc6a4336b007a4fe0456a19a334b1',310101,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',3,1388000200,10,10,10,10,0.0,5040,1000,311101,5000000,'open');
INSERT INTO bets VALUES(111,'0c690d46bef903922354520c8c8626ab5bfd45da1ca211d65f16aeef9b5f3300',310110,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',3,1388000200,10,10,10,10,0.0,5040,1000,311110,5000000,'open');
INSERT INTO bets VALUES(488,'c9cfc39f98307a845d1d27d4a9ad66b19e0c38f59be14ed0c4b9d4ec15cb0940',310487,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',1,1388000001,9,9,9,9,0.0,5040,100,310587,5000000,'open');
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
INSERT INTO blocks VALUES(310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,NULL,NULL,'f3e1d432b546670845393fae1465975aa99602a7648e0da125e6b8f4d55cbcac','74baad601b5f5e83ccc034b12956183c3b4c96973be90b1f65625f1d289a4486','91be11aea0c9cafc4b843a064d95cd2addf128675d6a371b090f60cd7e38aa67');
INSERT INTO blocks VALUES(310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,NULL,NULL,'6a91073b35d1151c0b9b93f7916d25e6650b82fe4a1b006851d69b1112cd2954','4d65eef6f755f385f7e7a2b6d54af2a3913e3ae5351b9d1d041e255cae642dd6','df5ee56ea976969bd1094fad84fa28d8fca47985852c3bf7a5500425a5c67b37');
INSERT INTO blocks VALUES(310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,NULL,NULL,'88eac1faa671a7ebc61f63782c4b74d42c813c19e410e240843440f4d4dbaa35','ebef3c39a3ef17c8bb6fe71baaa3d789e724a965f8bcdffde0b5c6732fe147b2','18b987071de500d9c6f74de3c39b6d5213b3e5b9450300530de5837ebf677c1f');
INSERT INTO blocks VALUES(310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,NULL,NULL,'93d430c0d7a680aad6fb162af200e95e177ba5d604df1e3cb0e086d3959538c3','ff2022228adab65e780f942f146e8dc80e4cc41e5ec76961edd93ba9922d0d89','7eb1fe3d9d2ec76789846f0906b8554d3b70dcf7253679dd164ad9d8655a863d');
INSERT INTO blocks VALUES(310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,NULL,NULL,'e85e5d82a20fe2e060a7c1f79dc182d3b2da28903b04302e6abe4a3f935ea373','121f59e0317ea12bc0981c063af4396fd151b37c9b2b539e8f2f3fb61f8922f3','2a67741fd440544cb49caad9bfeefd360679cef63b16d75e84464f1afcb98a4c');
INSERT INTO blocks VALUES(310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,NULL,NULL,'c6c0f780ffa18de5a5e5afdf4fba5b6a17dce8d767d4b7a9fbbae2ad53ff4718','17d8c8b71ea7c38756fc261a5dda52cc4e7473ba79d747d4d915024286689c08','9942c7149f08b62b3c533955f96d5185e906076134fe79a1d16a911ef05c4d6a');
INSERT INTO blocks VALUES(310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,NULL,NULL,'91458f37f5293fca71cddc6f14874670584e750aa68fbe577b22eac357c5f336','ac92a8199f71c785556845e0d563c3f7648f396bbfab309291c2f4eec830d51f','de2a62ca13965edeb280be268c8cd5fe91b6f1e320255a16fbd937fdbe87babf');
INSERT INTO blocks VALUES(310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,NULL,NULL,'a8f0f81aebdf77ee1945c2199142696f2c74518f2bc1a45dcfd3cebcabec510c','4607a3974a626c2bdb436ff03d9c90452a34664bbf67abb56849d760a6cb70d5','2704504fa35263d19b34237a1a3e78c3a0ed78644273bedc2ed8bc59714f39fe');
INSERT INTO blocks VALUES(310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,NULL,NULL,'df7cae2ef1885eb5916f821be0bb11c24c9cabdc6ccdc84866d60de6af972b94','5d11c74d7df09a6bb273f2205f055df566aff4a0582a8cb5f15d53525984b71a','cfe3b6f89068aa3391f0da3b6616d1b6c8722f92112530b967aba346e7532832');
INSERT INTO blocks VALUES(310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,NULL,NULL,'1d8caac58a9e5a656a6631fe88be72dfb45dbc25c64d92558db268be01da6024','e356d687418402221eded06bf6bd31e9aa2e8fd8a7e579d6269c847fae1493f0','fcffd37fc8ceeebc7592b701c0d89636f871b48fdc31c2c755e455c5dcc619b9');
INSERT INTO blocks VALUES(310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,NULL,NULL,'ab78a209c465104945458dba209c03409f839d4882a1bf416c504d26fd8b9c80','d5af008bd36f1b9bd906f73c8bb4e6149f399e2f774065d141df2d84486c1740','2a883ab3c88c0e3f337958b1e3d179c5aa47f4f4e32e74bf81d23ed179270fc9');
INSERT INTO blocks VALUES(310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,NULL,NULL,'5528fec20bfacc31dd43d7284bf1df33e033ec0ac12b14ed813a9dfea4f67741','d2da2a6daefb52fd311779b4d13a9fe90c05c429523124448000c7a42e0da473','8e76e4eaf0699364ab1e2bcef542814951175c4652ca02b1cd070698ec626361');
INSERT INTO blocks VALUES(310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,NULL,NULL,'fa66dc025cbb75b67a7d4c496141eb5f6f0cc42134433276c8a294c983453926','b01527f92384080e2fe9b4e2b035481d0e7e6cd292df759759bad486b462031b','7e4d03c7c85b0f6526badcda8f4612c328c93f107ce1f4648dbc4c3e61ccc277');
INSERT INTO blocks VALUES(310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,NULL,NULL,'442621791a488568ee9dee5d9131db3ce2f17d9d87b4f45dc8079606874823f8','69d4e8b38bd9554e44167a6fedf607ebb64b92994bed6f3715a17ca5c3b057cf','c3b8ef2499a87cefc09184ea74d87ae72800fbe7554d4c6de5e432bae5f1537f');
INSERT INTO blocks VALUES(310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,NULL,NULL,'8551367f346e50b15c6e0cca116d1697d3301725b73562f62d8e4c53581e7bd0','d4dc85d3ce6e85331f543adce0c831d3443b8e0ab3f908386ec75f87af3c604e','669b43f631d6fe70bd7ab7a953c6d406a200e4b912cb02daa2e179acc0a7a858');
INSERT INTO blocks VALUES(310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,NULL,NULL,'29de016d6301c2c9be33c98d3ca3e5f2dd25d52fd344426d40e3b0126dea019a','fb08e5f45dc7d0db3f06b5a9ff17c55cac3fd7acd2a2a3cda16cdad817a8dc13','ed8ed54994ec337e9f4e8c4b8ea77d99e35426351447550ec04cbe4aeab635ff');
INSERT INTO blocks VALUES(310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,NULL,NULL,'32ffd4bdf9b1f8506a25b4d2affe792d1eccf322a9ab832ec71a934fea136db9','3c595d930338d69d0a4a24fea7f76d06e121537006308f2d9952c96b3dd6f7a5','4ec05dc69f568c30a2f96e4de3b40b1254c3f80fc46b2a3ead0b57e73fa3a27c');
INSERT INTO blocks VALUES(310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,NULL,NULL,'64aa58f7e48dfa10bb48ecf48571d832bb94027c7ac07be0d23d5379452ce03b','33c4f0f7d012cc883e6855192418d44b0d6362f0e8385c58d3b29e38e11ad4f5','672b38c21ba28df4995b9756f5cc1026c8e610b1c6408ebdc7e02a32f0a84108');
INSERT INTO blocks VALUES(310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,NULL,NULL,'8d8f404bdc2fb6178286b2581cf8a23e6028d5d285091fa0e67e96e6da91f54e','a3b47149a48ea7806af6700450dace91c844b35a5fc965e80363bc488f8f291a','3d1b8034ef58154cec64ac0e4426eb0ced026452dd04dc6fcc4d519cd652cb58');
INSERT INTO blocks VALUES(310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,NULL,NULL,'945a8fd2f57cfd5ddab542291fb2e2813762806b806a3e65e688321fefe1986d','376eaece628d0d143068bcd4b9758b00f2593c088561fae41cbf699fa0ff8c78','f14fd8d96d878cda891af99a42ab60fea5be9e4d6ead5857899e3b5c2035137b');
INSERT INTO blocks VALUES(310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,NULL,NULL,'3393abc111ee337132103ca04b4f8745952cd03ddbd6efff58a589e00a48fa21','d106c2f5d11108635114f7ae1cb2f2344862cd4aa1ba00ccbbca16415585d8e5','04ac11dc991279914a56bb3f1197aa5d23ecd659034bf0da8bc4dfcecded806a');
INSERT INTO blocks VALUES(310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,NULL,NULL,'d05fe9705db7b30e6ea6b18e9ae92ba794dd72f25b4e33daf4d46b3b609a02de','53e120529d08250d3bd2864c0eadcb74ec2701fdc344090b559aaa71922d4b7d','a26ba90254574ca69e9f88902f15089494f2d057094c4d854e99e04fe155709b');
INSERT INTO blocks VALUES(310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,NULL,NULL,'c2b2b2c3bdd895c74f3ea22db3d9c66301578436b6fa9175ce0b242c4bfaccc5','826a59af916650a450553f3fa9231675e05d333547de79f836476b173ab0a7ee','b67e92b0db294b47d02a555a8e1a4caac331e60d484fb8ebaf2b323d23e65535');
INSERT INTO blocks VALUES(310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,NULL,NULL,'fad5b61545d8ef317918f07df063554d4f321c0ebf462f759513212960bdf523','b081eda1522024a7afe4b6dc55862290baf0206d16d11dbab2cbf46a992def8e','29937b440ee0279bb32429228f3a8d2c046a68f1fad2fce9aa6ff97c0fce7ee7');
INSERT INTO blocks VALUES(310024,'b03042b4e18a222b4c8d1e9e1970d93e6e2a2d41686d227ff8ecf0a839223dc5',310024000,NULL,NULL,'61a71d0ac67eba15c63a531f797e6d68c83613489730bc2b4e4054094f63105a','25bb22188b3257d5261d68d9b9c79e78e66ac43d2dcc5d6ba63485af016428fb','844b5753c47ba776e8d0bb9e998cd173bffc76342472d0c9fd426323d325b061');
INSERT INTO blocks VALUES(310025,'a872e560766832cc3b4f7f222228cb6db882ce3c54f6459f62c71d5cd6e90666',310025000,NULL,NULL,'f7d41404c3d1e57bbc390af958d1596212112068e4986954d11ff8abd13bc8e4','5453dfe7f74da7b5f16374afdce06dec72362b038d4a62a25fdf25ec83a77684','d4174157406d47c26f88184c1618bbdfd29b0ce237770deca6bef738a95b31fe');
INSERT INTO blocks VALUES(310026,'6c96350f6f2f05810f19a689de235eff975338587194a36a70dfd0fcd490941a',310026000,NULL,NULL,'31530d7febb577d7588e12d10629fd82966df48a93a613a480879531d5dbd374','5d047cd100f02ed6a2ee97ce863c4507f643989f9ee0b82829199cbbe576ff5d','16b805f1912181272f8a3fe5886982f3bc151c2e02becdd861b0f62a0b259f32');
INSERT INTO blocks VALUES(310027,'d7acfac66df393c4482a14c189742c0571b89442eb7f817b34415a560445699e',310027000,NULL,NULL,'f54085346ae4608c57c55d321a413a00ffeb85499138559d7d05245f57cc0da3','5aef98d6593f66407d00ad6b68df8370c8302af714ea437d4ce8d18187fa4480','0dfe1bb9956a2248b43540b8e6c8018432a87a6413715f41f044143110c0598b');
INSERT INTO blocks VALUES(310028,'02409fcf8fa06dafcb7f11e38593181d9c42cc9d5e2ddc304d098f990bd9530b',310028000,NULL,NULL,'a841b7f634fc24553d1c8cb2d66fc3103293dcfd297cb5bf241b0c5da84bd376','f8a333c8068d0204af84e0279c6c26d77ef1a5041712ecea21e54c031cc66b08','f371128316cdac199576c9dc8c6940c22439b678beb04315bb38abb61ce42630');
INSERT INTO blocks VALUES(310029,'3c739fa8b40c118d5547ea356ee8d10ee2898871907643ec02e5db9d00f03cc6',310029000,NULL,NULL,'69d40c69b4989f7a59da99b56577b0651887d9422757e38d5410379f95fda641','f122e080859292ee2047d1170f444a2c1f955cf525ddfb2a132a929982fe4d3a','2d914ae2a075f7a18324e6a1239a5b3a9801ad3753f0d6caddaac1956351b968');
INSERT INTO blocks VALUES(310030,'d5071cddedf89765ee0fd58f209c1c7d669ba8ea66200a57587da8b189b9e4f5',310030000,NULL,NULL,'192fe51d3a7af659670a8899582c29aedf3a5608ca906b274ce986751dad2d7a','bde6cbe1e34b4289b9d1496fc3506adf875353463a70b9807c04f853f7613962','e23b3e9acfcdcae1bf1cf07991033676e1437d71b0f915bd1ec868ca813e3d57');
INSERT INTO blocks VALUES(310031,'0b02b10f41380fff27c543ea8891ecb845bf7a003ac5c87e15932aff3bfcf689',310031000,NULL,NULL,'125784cdeba1e433b3411c368cdf676efb33021f51c26a8b2bd6ec00fe4f767d','68886690a5cf84b126cfc1a9757a6dc0eae19e94f2bb1fabb936bf832acb9196','db46abf9b33f8f967e17ee585a14f121adb53ed14bd52bbc1212e583305fa57d');
INSERT INTO blocks VALUES(310032,'66346be81e6ba04544f2ae643b76c2b7b1383f038fc2636e02e49dc7ec144074',310032000,NULL,NULL,'fa7832080a2b6ae8829794d70603351755fa4816f15a6e92716f83265daa59a4','27a27439231ae96d1e39da5f6ab92c1de816c14d1a2b63add0a16f98a2a1f907','18b508e36c234e262abc6e7afb0e523d8e922809201c15b518c8ad70f57593bd');
INSERT INTO blocks VALUES(310033,'999c65df9661f73e8c01f1da1afda09ac16788b72834f0ff5ea3d1464afb4707',310033000,NULL,NULL,'7b86f430bc44ad5d81a43b5a8ea118b458d995e3832d88bb74bc62429194e45c','8ce45a2289547f08fe7c3f11bfdd29a6faed27dc3b2cb93feac745c5bbda0dae','d68e5e6e850fa2c807486d8285aded4262b9cf5a53f167545208cfb7f5d93b6b');
INSERT INTO blocks VALUES(310034,'f552edd2e0a648230f3668e72ddf0ddfb1e8ac0f4c190f91b89c1a8c2e357208',310034000,NULL,NULL,'1f2c5ac4375f77fb79612d343dd5fc4489cf94ff983fc05ba2009a9e390d6c06','28145f55fd46f1a5651a074fce7a70a38a69fc21db478baae50e647065bfe82c','5796c4adc0e37c4348249eb2e525aee43e57f98289ae681d739742c93bcc92d4');
INSERT INTO blocks VALUES(310035,'a13cbb016f3044207a46967a4ba1c87dab411f78c55c1179f2336653c2726ae2',310035000,NULL,NULL,'81cdae9b978935ad40a1032e7f22ddd7117b9c7580d6d7e4b7e20d1c875f5e63','5cdb185be4ea354143d27756e5f59fdfb856fec6aa13dbec7c6e0221e21dace2','d31e823dd258968d0558a1d783919333eef5b18c2179f3b71b77a36dc4e26c70');
INSERT INTO blocks VALUES(310036,'158648a98f1e1bd1875584ce8449eb15a4e91a99a923bbb24c4210135cef0c76',310036000,NULL,NULL,'ff02952dce15c249501d8485decad0ad9fe02fda766b7b83720806f726d02ee4','106ee8a12ae955011b4996e21681077e241b6fe8fa28b58a6fa9089986b97684','d0649b6138e04173aba6abecc43bf4cf6d766a8d152627a1be578e3b89d5e2cd');
INSERT INTO blocks VALUES(310037,'563acfd6d991ce256d5655de2e9429975c8dceeb221e76d5ec6e9e24a2c27c07',310037000,NULL,NULL,'760e5a00feb6c8c4baf4421ad07be2af962bfcac7705b773484b449356d6c230','859f7c4c732b813902a3079c49fe5b282a9080dc6b803a633210ee985098af36','de8bfdb4d38c71d92144cc2041957bf0f59e9a39c5a42e9a491d8ad120a921c4');
INSERT INTO blocks VALUES(310038,'b44b4cad12431c32df27940e18d51f63897c7472b70950d18454edfd640490b2',310038000,NULL,NULL,'c79381c51fa93cc320d8bf19c943f98232a99446ac098ff66823cf691e0fa01c','b95227bde36dbdfbb2086097be6d6c594b8b3a30ddaa003637c290867164c447','4769e662f58d5ef019d792c6a66ce70a62a935b8bbf11d902ac5ec52aa8a2f3e');
INSERT INTO blocks VALUES(310039,'5fa1ae9c5e8a599247458987b006ad3a57f686df1f7cc240bf119e911b56c347',310039000,NULL,NULL,'7382f007315783c9a6ffd29bc0eaa62282c6ec72c5fff09322d6dea6b0ee3a96','b11d01b941be48bc7c8d415effac01b523745d64955132d8f158eca6d4e630ce','8d793f8d0664b8facfbe43c3d5e151c1a83a1ed424bbf066ddf6cdcad08378bf');
INSERT INTO blocks VALUES(310040,'7200ded406675453eadddfbb2d14c2a4526c7dc2b5de14bd48b29243df5e1aa3',310040000,NULL,NULL,'38d3b548be554a0ae92504244a88930b989ea6fefc9bc59c69b68ed560afee9a','89d6692c86fbfd4108a044325974e56161cb06b7ae45e81ca388ec48d8e4885c','0b075aa875911e615d92a48bc88b5f548c6a6159fd7df76cc533754d71740f00');
INSERT INTO blocks VALUES(310041,'5db592ff9ba5fac1e030cf22d6c13b70d330ba397f415340086ee7357143b359',310041000,NULL,NULL,'0c1c7aa19c015a67da214bf8a6ae3d77979a09de6a63621e320a28ceebdbf333','6a72509aa2e70ff1e627bb2d3bf2aa9a0dc38f23d90c5ee0dd528cd3cc3ca4ab','dbcdce22ab8558b1a31f1cc004bd70cda1f7adfeb116090fb955590d6db98849');
INSERT INTO blocks VALUES(310042,'826fd4701ef2824e9559b069517cd3cb990aff6a4690830f78fc845ab77fa3e4',310042000,NULL,NULL,'9d20f77d4afff9179cffe46574f1b2dd23d2987142c943de05e411baee2dbf05','de5bbd242c57d0fcd47e6fecd09649fae552b6ad254f6ef31d09da4956381d1f','5dd912f25db412d08223d2e58cdd5e23c6190bbc070d2e18af24fa288afe4ae9');
INSERT INTO blocks VALUES(310043,'2254a12ada208f1dd57bc17547ecaf3c44720323c47bc7d4b1262477cb7f3c51',310043000,NULL,NULL,'d818e5a1a5cb6c59771b63997a8737cdb041c3579de1ecd808a269f5d72a3abf','804cf264069c71258a5834ac9995c7028fb0848dc1c0816e4f258b53ab7d16b1','aca75b7c37058ac3a11e54a6e8338505661a76c96d5283966504276ad1ffe3b8');
INSERT INTO blocks VALUES(310044,'3346d24118d8af0b3c6bcc42f8b85792e7a2e7036ebf6e4c25f4f6723c78e46b',310044000,NULL,NULL,'9de166ff18c5eec97b838292ae894ce18e5a890e8a841a294b2d14894c60a0d7','564bedfc5cd770a558d5756c517fd6bbc73445b747825e86eb84f0ab9f675a55','993c1f0fe553bc1f8d2d677d40adecb3e1c124c2f7a80aee497f70f677f42722');
INSERT INTO blocks VALUES(310045,'7bba0ab243839e91ad1a45a762bf074011f8a9883074d68203c6d1b46fffde98',310045000,NULL,NULL,'bb3c0a260dc082534c95e894751e38e80de117b091bc0e34c66134d374b8db2d','aebd7d8cc02e5b795dcdb09450e3113e18fd8673665a86a06c19f8870d521a01','bd7575b6da116f17c371129b52633a92103765a02e1fdd85aa205e21d13eb6bb');
INSERT INTO blocks VALUES(310046,'47db6788c38f2d6d712764979e41346b55e78cbb4969e0ef5c4336faf18993a6',310046000,NULL,NULL,'b4605c50ee3e5e2958c908e099563cf997e20932cc2370109ab50049e43723cf','bb51a374f1e97797e8bbd82c8938a8333f202ede2656f4ebc737fd4c852062ad','de7c24ce6ade6623d9cc2485e9b49ef124b4398293f383e80c2d10076756ca2a');
INSERT INTO blocks VALUES(310047,'a9ccabcc2a098a7d25e4ab8bda7c4e66807eefa42e29890dcd88149a10de7075',310047000,NULL,NULL,'b840a7af6301c798c9a6670308a2684051ff8f3fb2e69bddaafa82cfd3d83186','31a0605b811d08b5ed47d83a56390b8b3be76879862497e8795eca1037700062','18d73fe3ea50d819b71adc6a68d12b9508d9c2d0c7bde8e3f3034a7c85a0f853');
INSERT INTO blocks VALUES(310048,'610bf3935a85b05a98556c55493c6de45bed4d7b3b6c8553a984718765796309',310048000,NULL,NULL,'6bd591d3336ea112789ad6675a9b1d8e1578fe42e44ca7f7be5557089d374c3f','f4fdb98332e7b8c19166b3fd01a8f8cf9e03325848b700d9a7522c91cf0735e4','78b0e0708c94e76b7a2cfa62cf43c9548e6e8175baae4aa6fc4dcb9372c9ab00');
INSERT INTO blocks VALUES(310049,'4ad2761923ad49ad2b283b640f1832522a2a5d6964486b21591b71df6b33be3c',310049000,NULL,NULL,'04fe1e6631d503a9ee646584cda33857fac6eeca11fa60d442e09b2ed1380e5c','3b511a4c23092109f4633d2500e5d4cba09978e53e0ef3341625783547727262','cee3345fc609ba9cede4f91d1500f0ece115288921fd61e6673194f3ce13db2f');
INSERT INTO blocks VALUES(310050,'8cfeb60a14a4cec6e9be13d699694d49007d82a31065a17890383e262071e348',310050000,NULL,NULL,'dc73bfb66386f237f127f607a4522c0a8c650b6d0f76a87e30632938cf905155','dfaccc66d4e468c6d33d1543a5a69adfcf2fc0c9d2d5b39afc38895c9714d994','1de9908421424016755b07963c2ab2e849410ab145d7444e8438aa9c8e2f935e');
INSERT INTO blocks VALUES(310051,'b53c90385dd808306601350920c6af4beb717518493fd23b5c730eea078f33e6',310051000,NULL,NULL,'e4eea2d144c8f9c6dfe731efee419056de42f53108f83ebee503c9114b8e4192','8a3173e17ebe757a2429f6e9a8d59fe96d225ba8d355bbf7a44d5f9c40e69ddf','8892e39c0ce9ccc3323b266dc9d32f2c0353b3f29f53dac9a890f90b313ce090');
INSERT INTO blocks VALUES(310052,'0acdacf4e4b6fca756479cb055191b367b1fa433aa558956f5f08fa5b7b394e2',310052000,NULL,NULL,'8d12b561e7cf87b0aabe000a93a57e5f31db75510b1e9feb19b4f557cc0e6604','2bb61472fe7bda94c4c91f522c45e5f58201f753981c51653d923290bb31934c','0d627af4f0fb6aa94cef7a7892f84bca76eee227a975ac31487f295d48982102');
INSERT INTO blocks VALUES(310053,'68348f01b6dc49b2cb30fe92ac43e527aa90d859093d3bf7cd695c64d2ef744f',310053000,NULL,NULL,'f47b81b3dfc522d9b601d1776fa2deef8543ca077cb0743556cd970bb119d640','2e1fce95ee73276a6c8ffc7bb7aae1eabe753c622960b971a6b5fc010ac8369e','b3d8c92340ea0cf55fd8a8770483fbb4a7a8acaacd3aaef35cb48379c6e46bd9');
INSERT INTO blocks VALUES(310054,'a8b5f253df293037e49b998675620d5477445c51d5ec66596e023282bb9cd305',310054000,NULL,NULL,'df191ed877eb1856d6780a717c04d6925246cdee7dd6df74216ea983560d5a2b','8591d342b1ff9680974b058b921b6ee146a7d719b71101dc6c857a074dc1efc8','83175ca4adae384b7e2e1ebe8106cfb9bdf52a4d4f1b5442dc0b41e0976f7d30');
INSERT INTO blocks VALUES(310055,'4b069152e2dc82e96ed8a3c3547c162e8c3aceeb2a4ac07972f8321a535b9356',310055000,NULL,NULL,'4b0ab72111202b1f9a5add4bf9a812df203cb6761a8d16b5f7a8b9ed6f2b2476','de9d9ed5dfa010e806c52a8aab93d3669c5800113d804b861d6c2d23e4d03a2d','430de2d54ab490531718c9690760ee75587f9fe1c83c578a0e3f2149adfe9934');
INSERT INTO blocks VALUES(310056,'7603eaed418971b745256742f9d2ba70b2c2b2f69f61de6cc70e61ce0336f9d3',310056000,NULL,NULL,'8e76b5be6a94e1b50ba16fe265965d4cba01b792216485c54360052e78788f20','75b53038c068251447bbbf5fcccbe2d91fdee3645658c7b0240715e09aca5835','aa10e673d981c3292041713b6959de6e968f8138e063d95bc6160513a74258fb');
INSERT INTO blocks VALUES(310057,'4a5fdc84f2d66ecb6ee3e3646aad20751ce8694e64e348d3c8aab09d33a3e411',310057000,NULL,NULL,'e14dde2bfbe4f9076b7ba548aad37269752858361af094b4be8b956c0a28b9c5','2ba6267a2f69a0f5764a2d84b24ead805d1eb8c6b521edd9af8a04e17a862dbe','7e864a378b943e2fa4071181aa045c94f8a17a3a4110c84ecd5969547ee3b1ae');
INSERT INTO blocks VALUES(310058,'a6eef3089896f0cae0bfe9423392e45c48f4efe4310b14d8cfbdb1fea613635f',310058000,NULL,NULL,'b986e5f6486ceac7f1af41b1da968e453cc19376d588d8e884439b51313d6e30','2af5bbe77603975352dc2e8a222e8f60b8943640ab9d4c100698c16329c957a6','2897c69dd0a55d908eae1584d6526d4a782cf04d0fabc1197ef9ad3d880b89c9');
INSERT INTO blocks VALUES(310059,'ab505de874c43f97c90be1c26a769e6c5cb140405c993b4a6cc7afc795f156a9',310059000,NULL,NULL,'da978ee5b06812ee42cda43e1d9943c4e34e9e940cb0461f0ed463b9299402d8','30cacb7388eb996da46d023ec09aa488607d5c6f30d4411bc6a9364e5d764943','984ac7cfd12725a3a386b1a65912507488887e3a0485166ea70f8daf79b23db3');
INSERT INTO blocks VALUES(310060,'974ad5fbef621e0a38eab811608dc9afaf10c8ecc85fed913075ba1a145e889b',310060000,NULL,NULL,'09ccea87988cc385b9d2580613581b90157f1366d27cd3dc1a4385e104430d15','51d78f09ff93897481e4a758b9a9ba9b96354fa284c3f01af9007d814db97327','b9c6d66be76193a30ccb6da722ee233a849f4d8fc9ced2169953ec35a47d9e74');
INSERT INTO blocks VALUES(310061,'35d267d21ad386e7b7632292af1c422b0310dde7ca49a82f9577525a29c138cf',310061000,NULL,NULL,'4caebeb5ab6468e116cc0cf137977649a15dd30d9b214a5081057a551174ec48','3c624e0d7d220ad0666ffa0362b928140deea0b9ebd68f75c261c575f2c08234','a9247d661576f55115269d22fbe3f78afd1c7b705ec52980336423b879d6e8dd');
INSERT INTO blocks VALUES(310062,'b31a0054145319ef9de8c1cb19df5bcf4dc8a1ece20053aa494e5d3a00a2852f',310062000,NULL,NULL,'51cb3f1005127e3240721c47805d67a123afdc40084692a9cc2b3215cec99dc3','299a92a1ac92debe1a86f69bfd1a299b8bec5f0aff9651856d2d495a50415664','fccbce0dc968131f98dfd3c3ff51871b58d01877caafaa3af75e7f11b9a8c1a8');
INSERT INTO blocks VALUES(310063,'0cbcbcd5b7f2dc288e3a34eab3d4212463a5a56e886804fb4f9f1cf929eadebe',310063000,NULL,NULL,'e12864a0f955320278c215897cf4f65e5c378e534294b0bb90ebd7e4b5efd4f7','6fb5e5b279bf37f68925682ecad8f0e1073ed006d049954c21b8e7e5a4667186','77ade687c595b59a3ccb783057ba840333a9e59953d41c094bfe0541ff806b3c');
INSERT INTO blocks VALUES(310064,'e2db8065a195e85cde9ddb868a17d39893a60fb2b1255aa5f0c88729de7cbf30',310064000,NULL,NULL,'ee27c3b46aa890d18be950006879874a094ecddd086db195e032fb4fe12559f5','bb3a53231dce223dc4dcbcf67f5c56c53f9fd9d23fdc97a43a47abb5fbec222b','49e5f8e885bc8b9675b5f1e3e87d48a549bc44ad21f8d350b5a02093caf3ec17');
INSERT INTO blocks VALUES(310065,'8a7bc7a77c831ac4fd11b8a9d22d1b6a0661b07cef05c2e600c7fb683b861d2a',310065000,NULL,NULL,'d40dbc4b5faaf8918f9cae54e5a247e3904dc65994ce0f04f417c1a595404464','b0ec4c4d421023f4d5b60fa6dcc85e926a9d2df7c4bc477518c6974c38c59292','b04886c28e4b2a902bc2444117674868421749de33e3ee28031395ee5caa3214');
INSERT INTO blocks VALUES(310066,'b6959be51eb084747d301f7ccaf9e75f2292c9404633b1532e3692659939430d',310066000,NULL,NULL,'19f2b00477a6fae0e10f4693d949cb409b1ed74ad20dbd9aa4a7f1f17cb813ac','be86db5e91d08200eeccdb2e29753ec8145cf356adf9cc3efc2e451c6aa50b3d','8c6affd2cb9e9049b5a8557f58cb947ff8a15e1ad9ec82ba47a95e1eea80e62b');
INSERT INTO blocks VALUES(310067,'8b08eae98d7193c9c01863fac6effb9162bda010daeacf9e0347112f233b8577',310067000,NULL,NULL,'d72891c22fcea6c51496fc1777fa736ef5aba378320a1f718d597f8f9fea3c7d','73beb3900a2bea9f6427322005c1d4021a82faca64b8dd8cb461714846800936','ee959a28953c6ddf86b0784a3442fbbd6e63b4ae1f99845a58fe952a7b214b2e');
INSERT INTO blocks VALUES(310068,'9280e7297ef6313341bc81787a36acfc9af58f83a415afff5e3154f126cf52b5',310068000,NULL,NULL,'5793e10b8329d3ac71aed6347dfcf61fc7b74ca162ad99918f5c20065f8d0746','1afd4dd2bb8c3e13748c97e2015065fa46286cb9e2b284579278d9d45ab830ba','5325e0f0e3bfaeb220112aa1195f8c4a8967f3e6b14d04f70804ad7f34583f1f');
INSERT INTO blocks VALUES(310069,'486351f0655bf594ffaab1980cff17353b640b63e9c27239109addece189a6f7',310069000,NULL,NULL,'61040e7c1a58f41d708785347f4985c1fb522b6f947d3e14dacd91157e153ab7','bd81b055fcc5aac0894eaea3f4bebb6ca816b81f62f94417c793c97a8eb03d1b','8e18dce34eafc683975d2332bf5f5a95588b471e95a585dd0b6273fb7f5cfdfd');
INSERT INTO blocks VALUES(310070,'8739e99f4dee8bebf1332f37f49a125348b40b93b74fe35579dd52bfba4fa7e5',310070000,NULL,NULL,'ce115625fbda90a0f261b2c524108a7393078cb4c3f861d6d7846501c7960008','d77d33692b84741b01edc701b94b7c18487a0842d2e9e35715e247ae1ed17b96','6f68105083ef2cf39b6ebac41bac98db1b2e7919e626bd4b8c653d4884baf880');
INSERT INTO blocks VALUES(310071,'7a099aa1bba0ead577f1e44f35263a1f115ed6a868c98d4dd71609072ae7f80b',310071000,NULL,NULL,'3c2d4d81e90a42a0c18e9c02b8a59f99e13f2a084ee66b4b1bd410077adc383d','c9c0d3df9a273085902be23c5a84ea4f352d9c759f6e4dda06198d92c605c693','02e0ab7965b6feacce52ff40c508d875da826dc36d4fbc62c0b36cbccf9f9037');
INSERT INTO blocks VALUES(310072,'7b17ecedc07552551b8129e068ae67cb176ca766ea3f6df74b597a94e3a7fc8a',310072000,NULL,NULL,'8a28e33306582346f1d965a0393621b4aa307f6614c84369064465f95a6c727e','cea0b70d923de81f184fc28fd346ffe9105c0b303b345a278bfb6fb930950b0f','5162082a97eca6133a105cdc7bdd9180a042785936c8f3140d17e0973bf96a01');
INSERT INTO blocks VALUES(310073,'ee0fe3cc9b3a48a2746b6090b63b442b97ea6055d48edcf4b2288396764c6943',310073000,NULL,NULL,'e6c5b393a21df54479c4cd8e991b37d877794166c19b9f61ad7e47eb34f63bdc','4e6230d9a8f67b575198e41be226f2975af47fd413b7c5937b56119e5414c0a7','36b3beec80907c81c729c71a60f55f5e6ebc550cdcaab286fa08f3a32b96cc23');
INSERT INTO blocks VALUES(310074,'ceab38dfde01f711a187601731ad575d67cfe0b7dbc61dcd4f15baaef72089fb',310074000,NULL,NULL,'b2db452daf280f1cc5f02668d0cbd33732a2fe9f04307d9c072eba97c95acf5c','8383ea77813db9b32b9f84f4f0bd67afdee03912a27550a496726aaec65f42c2','e04d73ddcf70357b2b5a957b553032f070bbe306c29844bd3b4bd2ea18b80d4c');
INSERT INTO blocks VALUES(310075,'ef547198c6e36d829f117cfd7077ccde45158e3c545152225fa24dba7a26847b',310075000,NULL,NULL,'09998443cf1cd79e193a7b09681ae07ea9a835458151a7f8c7d80a00c5d8e99a','1c8ad126a1d661562ea41fff197d968f966f698bbcbd636be6e9b9ddaddf70a6','7ff6d31cc3747a9b8f56777251a269c10ee680d822525dd78a729b774cc8f199');
INSERT INTO blocks VALUES(310076,'3b0499c2e8e8f0252c7288d4ecf66efc426ca37aad3524424d14c8bc6f8b0d92',310076000,NULL,NULL,'a0be1e88f10b5214f7c12dd32d0742537072d5eb3e54f9abf57a8577f7756d7e','d4778d09a0cb21f4904e82e6e972ff9d0254bff08a9cd70ad8fe961977286933','9660ca1e04dfa3e10161ee869cc36a699b76b790c34894e3c6aae8bf1f868ded');
INSERT INTO blocks VALUES(310077,'d2adeefa9024ab3ff2822bc36acf19b6c647cea118cf15b86c6bc00c3322e7dd',310077000,NULL,NULL,'d41e39038756ee538d9438228512e31b4a524bbd05bc9b9034d603fd20e00f05','3b34fe46eed2a06ac89af1a9b8f29274612016b5acd29f3d3c31926f176efdc2','d3a194cb5f35354dc5b91c6bbc153df161c9247b0b977bca730879cda8e309b2');
INSERT INTO blocks VALUES(310078,'f6c17115ef0efe489c562bcda4615892b4d4b39db0c9791fe193d4922bd82cd6',310078000,NULL,NULL,'996092432a2d94df1db34533aa7033e672fac73de5193a696c05ae7c30d75247','8335b6dce6641d4a6a42deabc6fa5fc026950187cbb8baea9e6c241f5dfeeac0','9f90eaadf1a9a9f1c35654a5a8091cef6e94f48eaf8798f32040f8cb03af5907');
INSERT INTO blocks VALUES(310079,'f2fbd2074d804e631db44cb0fb2e1db3fdc367e439c21ffc40d73104c4d7069c',310079000,NULL,NULL,'e3f536e930e39b421e3a0566eba6b8f5f781ad1ff48530a5671752fd3eaf35ac','980a8b2617bef99ecac373139455c429571203d86e4ed4eb6f1021548574c671','dbdc45ceb0c18375f4e6a9818d33defb8925e565ba05487923dbe98aa54b38ec');
INSERT INTO blocks VALUES(310080,'42943b914d9c367000a78b78a544cc4b84b1df838aadde33fe730964a89a3a6c',310080000,NULL,NULL,'57122dc41d7de2bdc65002905617c357496432fa4d80af48f4ca69ba1332e634','54fbda6b18541272b0b80011120f92d9e2309091b7a1bba61b509e982dbd5d4b','5d577000f92aa6dc7e2296b5f0669b61d3a2cc375d7d01f545817968c25261c4');
INSERT INTO blocks VALUES(310081,'6554f9d307976249e7b7e260e08046b3b55d318f8b6af627fed5be3063f123c4',310081000,NULL,NULL,'3a0fc7b2f0396d257a0a5c5a313910cb4073e4c79ef8cf0d3cd12f494e563105','43bc4dfb8b09f7dea0786dbec5021d228f6e42ff04efd0de0877cd074fd59102','42b37b4345b019636b0e3a82e7009983d42965a0c75ae74d8151aea51f244dd2');
INSERT INTO blocks VALUES(310082,'4f1ef91b1dcd575f8ac2e66a67715500cbca154bd6f3b8148bb7015a6aa6c644',310082000,NULL,NULL,'e876c406f682ed6f0dbd6e4c97bac13409cd400b59e894eebeb3252be306494a','ccbf98c416092d1bed96d4f6fdb8c0061f738e2335c838dae50afb7dc1f3217c','c1dd4277b7d3720c9438430794cd6866ed7fbbb50940f096818ad680e227f35c');
INSERT INTO blocks VALUES(310083,'9b1f6fd6ff9b0dc4e37603cfb0625f49067c775b99e12492afd85392d3c8d850',310083000,NULL,NULL,'533fc3eea80caa46cf8fd62745c5d21d09f32b18eaca70283a4bd72924c2100a','17182d62608dd447343da7c4549a974301985bc9a888cd79bf2b62b7e1fe2644','29373a882425f7b5ac13d4c4f20a2836e14be12f70ea2d2beade84c105ff1b6e');
INSERT INTO blocks VALUES(310084,'1e0972523e80306441b9f4157f171716199f1428db2e818a7f7817ccdc8859e3',310084000,NULL,NULL,'e3fd22f2e1470246ca99c569d187934f4b7bbb1eedb9626696cbaf9e2b46253b','98bc81538460bc09e1569e7ec9bec21e85e1b56aa3482669ec39d22ff0b3751f','711eccd65124af826e57f851f4b84258f3f21a2a521a25d1663b9d08707220d5');
INSERT INTO blocks VALUES(310085,'c5b6e9581831e3bc5848cd7630c499bca26d9ece5156d36579bdb72d54817e34',310085000,NULL,NULL,'bf04750fe13f663adb12afd3a166636a4511bf94684a77217de1bd7ef9077d94','efc30059c33bbadeb940e90a886b1487eadda89003051ef6dc9d553baf13f6cd','7edd8a3f51e80a93fa78210840ff3350b6c9b73db2e54d7ef3e975ddf9803b31');
INSERT INTO blocks VALUES(310086,'080c1dc55a4ecf4824cf9840602498cfc35b5f84099f50b71b45cb63834c7a78',310086000,NULL,NULL,'a0e8403085ba63ba72432f27ce8125921ef24742f988ab7f85dd8e4309f27a2c','b7ba9b95123603ffcc2ebb8f1a9d2ffac18a4ae7eb5cf82fa4e78d1af2e4c871','3fc550a1f7a0b618255537cb060730dcdd8184cb5d5dd9fe91ec22d714dc6553');
INSERT INTO blocks VALUES(310087,'4ec8cb1c38b22904e8087a034a6406b896eff4dd28e7620601c6bddf82e2738c',310087000,NULL,NULL,'0861b02e980ad5958bd23ac02603b132efd72ee2a70dbb0415fa5d39cc524681','093d08b704d2d26a34204f38aef4e2bf7a54c8ee8eef2c0576cb7a4c40cd6f7e','3e0e4cefbaca82a0150097c2821497c56ccd1353548c5969d287b1620bac5851');
INSERT INTO blocks VALUES(310088,'e945c815c433cbddd0bf8e66c5c23b51072483492acda98f5c2c201020a8c5b3',310088000,NULL,NULL,'d52cdaa449f63f6d3abc79080378855206f91a5db865dfaf37a5a2529ea6eb9a','b0197fcd81949cbfe4ba586a88de930946a78b1b6c00d168006904b59ced841c','4051e93ffa0290da2f8d8931dcf52d233afbdca59e7362e7c6abc29101a17f59');
INSERT INTO blocks VALUES(310089,'0382437f895ef3e7e38bf025fd4f606fd44d4bbd6aea71dbdc4ed11a7cd46f33',310089000,NULL,NULL,'d15a7a60b8bf8618667863b3e31eaf6202664e5aebc16d1f7a337b857ac31f90','99db7662b56114ee0b01d6947feebb19dffc0afcfa50d44885566c979e8b2603','76eb113f6b4c3edd05da46332d5a2e6eaf4dce88f95a7686a5df1b46d8c101db');
INSERT INTO blocks VALUES(310090,'b756db71dc037b5a4582de354a3347371267d31ebda453e152f0a13bb2fae969',310090000,NULL,NULL,'68475dcfe8252c18501fd1fef2afa2a91d20b92cacbabb542c12f43403e66ea3','80731a5f85b5975b3fb00c4c69024fb06e940c8fa75d1e54fee3a4f1564107ee','c825b7273885d13bd649c5ce725049b1ccd158b124bd9a5eaf3234a19c43e47b');
INSERT INTO blocks VALUES(310091,'734a9aa485f36399d5efb74f3b9c47f8b5f6fd68c9967f134b14cfe7e2d7583c',310091000,NULL,NULL,'5d584f255e5bbebc32c78a30fa816e1203fe7d3454611bef9222cdfc91dfcb63','8e39bbc5703444d459c2b3bf47445bf3ef75c46a4b545227e3f3a15f5222e75d','f6778243a7d45c5b710beb332c12c60c1985baf072843e7632ca7141954ff90d');
INSERT INTO blocks VALUES(310092,'56386beb65f9228740d4ad43a1c575645f6daf59e0dd9f22551c59215b5e8c3d',310092000,NULL,NULL,'ef992ad033b047b7f6ab038604736f444da55be187834f8152b173cf535c68eb','d1f2b50d51edcd8a11c908be8d8bc209ee969058a89be0aaab4a6497cfd4c748','575b0e27b20f17aa593d8ad8ece5a95bd108149dfe21c4d3f3ebf88ad9cd6dcf');
INSERT INTO blocks VALUES(310093,'a74a2425f2f4be24bb5f715173e6756649e1cbf1b064aeb1ef60e0b94b418ddc',310093000,NULL,NULL,'9cdee996d0e67ac3f9f283151b428ac5f223b72590965f41f93adcece6b88f2a','bc9e7d4a6571026f1f615c01166699691eb432bea53551d65b8a4fae8124fa04','01e6d084f7fe094981dd7d88c59c14ed0e7cc0dbba2dbc6f5eeadf7e1fcea838');
INSERT INTO blocks VALUES(310094,'2a8f976f20c4e89ff01071915ac96ee35192d54df3a246bf61fd4a0cccfb5b23',310094000,NULL,NULL,'fa25dc3f15fb28718d788f85373555966251f54bc6ed1f4dd2244b438d27b281','49221457596119fcbed057bedc2f12b28e5cb7ff47ecbf1f22b1a6caec53568a','68a104f8828c40e4e1da8284f877c1ad848ebc438129895a4f9161523466d0ba');
INSERT INTO blocks VALUES(310095,'bed0fa40c9981223fb40b3be8124ca619edc9dd34d0c907369477ea92e5d2cd2',310095000,NULL,NULL,'1ba8cd971f9a169d43b6de1a136cb8e6153649fde1f7a8e7fb2f7de926fdf8b2','154fcce14c624c0286d5dfc827217df0343ed56d0a58426680b7bad9b3d31c62','15e85372ba92a14a0170386cdd32a3cbf150b07622d3985313899bafc0e841b6');
INSERT INTO blocks VALUES(310096,'306aeec3db435fabffdf88c2f26ee83caa4c2426375a33daa2be041dbd27ea2f',310096000,NULL,NULL,'42c36df2c53d762b9b132e622f52b2fca99bc0370978463acd22cdf6469587a8','cac3e695b6b1c4f7e658ec8fa2f0dcbd76e237fdcd1e94b3412b4b7cc2021d2b','1855ce8cc1e75d99175073a1ffd497021d3286ee4f705f94c9d9bf4b94a33a6b');
INSERT INTO blocks VALUES(310097,'13e8e16e67c7cdcc80d477491e554b43744f90e8e1a9728439a11fab42cefadf',310097000,NULL,NULL,'d96af5cf3f431535689653555c29f268c931f9fb271447aed050303d364f92a8','6c8cbc6e34c3898e1767c5bbb49853e349adb2a3a666da95e356a92c9945df63','9a0db97b964616d717e2dec12071ed9b7421a1ba868e6c645ab093c169f797db');
INSERT INTO blocks VALUES(310098,'ca5bca4b5ec4fa6183e05176abe921cff884c4e20910fab55b603cef48dc3bca',310098000,NULL,NULL,'153c9ce12e8d9f9d10c4005fc9af158613480d38b2c6551fc49bc57380c229de','213b649e82eaf8bde0ae1d61bb03a785b77212a7024a6dbbced9f372f423e777','63b22aad2fb1d8e20cdbdf963aa767c5bd6a02b5d1db2d1852fb5ac4b2dc17f3');
INSERT INTO blocks VALUES(310099,'3c4c2279cd7de0add5ec469648a845875495a7d54ebfb5b012dcc5a197b7992a',310099000,NULL,NULL,'49f33b269d717b56a399843cf4627449010133b47079134b9e299ac5386468ee','17a0243d598c7b17735ecb6f6425ef4d51e3f298491bc76fb4f190e8cc26e0b1','98e4290b537674b70ec9a8f8e4893e02cf3589f52761ad27b3f518891095545d');
INSERT INTO blocks VALUES(310100,'96925c05b3c7c80c716f5bef68d161c71d044252c766ca0e3f17f255764242cb',310100000,NULL,NULL,'c9e72f7db2950f0b0e6e8fa3bc47d37a0d643da6ec61b236f7224b63ac60467e','0da377b05ee306cb8befd839437fbc72c53e7b0385b2fde5374d2cf1f29b87ac','7f4af309e283366e574b5968c93aa543c648e01a0ecbfad9cca4c2a282b960ca');
INSERT INTO blocks VALUES(310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,NULL,NULL,'a4387c8c785a8407f2dda176a7e182617904e7ce00c695ea8aa2f9d0429d9e74','a001d1cbb846423540c59778e3d6830d801994838b526a50bbdf7fb797e00e27','b582489dfed070914a5bd2b891acde198ea6fe13e15062c45fc77c1009fa2326');
INSERT INTO blocks VALUES(310102,'11e25883fd0479b78ddb1953ef67e3c3d1ffc82bd1f9e918a75c2194f7137f99',310102000,NULL,NULL,'fc81f97474f7b35ef92ba93de82d38650a28afd140d3320e6f6b62337cfd1e94','213e8d4d5c74487348f757cad74f6bb4ab661bbb266b70340411a56ff193bfcd','83632211471226fe6088f5c4023cdc67432e5d1c74d39cd03db968b8a335f96e');
INSERT INTO blocks VALUES(310103,'559a208afea6dd27b8bfeb031f1bd8f57182dcab6cf55c4089a6c49fb4744f17',310103000,NULL,NULL,'3a502a89a3b66438cd2b944f8951a78999ba18c5f5bc8abeafe373ae4625ed4a','cf04379c7da902c9f6f95655c88f637d6fe2aa41bad6cddbd47835b94bd1b3ab','d52a2f411cc766c9cb5998890ecaeab3276f6d6766aa3a1b175b71e811f43b49');
INSERT INTO blocks VALUES(310104,'55b82e631b61d22a8524981ff3b5e3ab4ad7b732b7d1a06191064334b8f2dfd2',310104000,NULL,NULL,'74ab5df2cdd13b654c80ef12e460120c96ce30d4690a06671474235fb93fee4a','2f0a0d597741bdb9d9125c28d79b552297e90abd40166373e23e878162097bc2','a0de4676fb6d08e88057663149796d0593e1e351615ac8545bd779ee002077da');
INSERT INTO blocks VALUES(310105,'1d72cdf6c4a02a5f973e6eaa53c28e9e13014b4f5bb13f91621a911b27fe936a',310105000,NULL,NULL,'dcc1940370421712cc668dc401169a55dd7077a49feddfd70e9e455aa5893962','ffef0b5c68ea2a259d1bb107e2df2a9065b818c52ab2b7e2328c826d400c6742','a5d1877c949490f60c5e319f56325ca149d309cad9fafef995e6b6b3850be666');
INSERT INTO blocks VALUES(310106,'9d39cbe8c8a5357fc56e5c2f95bf132382ddad14cbc8abd54e549d58248140ff',310106000,NULL,NULL,'6ec3678f9b647dc1ea3dfd0d76ffd240da9a94097ad29e48e7b327d6198f4f78','3977bf04c5dc9c78cb6a69e3937e3323780de4b66ceafec3e71e892296af58d0','d6f01087b3bb99abe06d5c08efd2472bfdd1415927957121e07588c7495b20b3');
INSERT INTO blocks VALUES(310107,'51cc04005e49fa49e661946a0e147240b0e5aac174252c96481ab7ddd5487435',310107000,NULL,NULL,'8e3c2d75c7a81175405f39386e2367c7a655afb53d7cf5b5c2e7dd2c79a40d9e','81bd8b1ba8dffe65e2d7a591754d442095b03fc77287b9a347c0c05e776b3317','034dad11b664451f976de24d1be1404d78cc295492ef8b7a9506219ff09091d3');
INSERT INTO blocks VALUES(310108,'8f2d3861aa42f8e75dc14a23d6046bd89feef0d81996b6e1adc2a2828fbc8b34',310108000,NULL,NULL,'b00c403723eba6ffb5db3d9903fbaa8a04a783c61949b9220e2caece1a8b86eb','b1581a3d2a8340e7a9dff140046b6047a82aa8eb2ab2720cf2674d0bec9ebd48','1a11c34c02d351d8937ebcc75aed21fb220d56b2077f10d0265e4e156bd91115');
INSERT INTO blocks VALUES(310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,NULL,NULL,'69d2150543fe997a6685eac965283a3e7c9d3f9aa4eb2e08e8e4fe7a15054d26','25eeb18ee893e76cd28de354996db63ce0f528195ea8a9e6a0d695049519708d','094fc1610fc2b261a0914fb4b2f4cb48d9bdb5dffea71a5d87f32962951fe4f2');
INSERT INTO blocks VALUES(310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,NULL,NULL,'0122bef9da908b66c64aae0057d2052e1333c7e71075aed739de6838f03802a8','6603c3dcb9a7998780659653b76aac813da55a712353da79663d0fcff58c072d','da0e3d6717bcb567bf202b6505d414a7a2d73ccba6e0d377a9d2615619964919');
INSERT INTO blocks VALUES(310111,'fde71b9756d5ba0b6d8b230ee885af01f9c4461a55dbde8678279166a21b20ae',310111000,NULL,NULL,'d3ff81444800b8c914171c58ef93c9e9ce87dbeab3b7bad16729685eb0e2e55e','69f05c093322f9a57c639e3850c2619f902e014b9d42a12f209dc5e5e953c08a','19f2f9aaf652a1d884cdeb2138acedcb0517ad2f17a05b358f6a023723bb85a6');
INSERT INTO blocks VALUES(310112,'5b06f69bfdde1083785cf68ebc2211b464839033c30a099d3227b490bf3ab251',310112000,NULL,NULL,'e316c6a4f4d1dcd800bb94f80dfcb66e9d8fc52927673c91865460b8a85aa84a','bd6a896192618568d91e112bae2e185e753774665f89b5bf990af19d6ff0eb87','f98a59995a7ab7ef2e065a312bf71401abc6691651a91c52583e17343b76473c');
INSERT INTO blocks VALUES(310113,'63914cf376d3076b697b9234810dfc084ed5a885d5cd188dd5462560da25d5e7',310113000,NULL,NULL,'44ffb0b4be579060aa2a0fb574935764189ded92d31cc4ea94e4042734a9377a','3b474b117daa66427b0b8b3aea5563daa0971496768d21ad3bc8da0bf2da2cfd','055d8bc4f224f5ec20ad9ea1c5613f60acbb609b03b651ab513352adc6f2b1eb');
INSERT INTO blocks VALUES(310114,'24fc2dded4f811eff58b32cda85d90fb5773e81b9267e9a03c359bc730d82283',310114000,NULL,NULL,'a256d5377258011a8a4d887ba734094b7dcf2dc5fe99333069abaf71a7233948','bcf9dd2db4e422cd5d8b5c7ac2bf51509a19821d89c8ff69e8b9ea3610d9c637','ba3959a20134579f50cb09e2a5c8ebbf1e5d2968c59b6fd385371f0461021630');
INSERT INTO blocks VALUES(310115,'a632d67ff5f832fe9c3c675f855f08a4969c6d78c0211e71b2a24fe04be5656a',310115000,NULL,NULL,'40e8739b957a2316bde9e5727b7f57427691850996a794c6fb6095e8510e88a7','15fbb959d0d921b9d09c7be3c35877022178436c86b301f618e521ca6ab9f613','60db1b113eb6096a86b46571324925b054578eeac9d43db42043edb1202000d5');
INSERT INTO blocks VALUES(310116,'8495ba36b331473c4f3529681a118a4cc4fa4d51cd9b8dccb1f13e5ef841dd84',310116000,NULL,NULL,'cddef956a174dc306823ac6c25d66f6b0df70918c90fb94bf6b0b0033443dad9','0a101677e5253f68c533d795f08b8dee434d4cd86c46625dc38b0b4130dca45b','7b47b5f0e44b5deb022c640fcd762fb0bda0cef448c4fd253ae7aa9cbcc3b9d6');
INSERT INTO blocks VALUES(310117,'978a3eac44917b82d009332797e2b6fe64c7ce313c0f15bfd9b7bb68e4f35a71',310117000,NULL,NULL,'235c743e4857b7bffc03628ee42350b5bf550ed10bbcd9ed7e405ec17f30b67d','dad820b3d323aa3ebb162db543fea7b5eac72c0c78b1d009369d7f1f02507b6a','44178391d1bdd72f1aa70f0587195f6251e3dde175f8030dbadd12faa4a50351');
INSERT INTO blocks VALUES(310118,'02487d8bd4dadabd06a44fdeb67616e6830c3556ec10faad40a42416039f4723',310118000,NULL,NULL,'5559796f49bc96fb1ca98a673a137f3c98ccbef8f9110d05b770ecb1cf805e37','f23519a251d4ba00fcbdfc4246f62d8a90d559f58b36e4d651bef968ce3f4029','7eeb7a65bd81f02e6c286625d853f2f653862de554b26b3ff46b2c9ec439334e');
INSERT INTO blocks VALUES(310119,'6d6be3478c874c27f5d354c9375884089511b1aaaa3cc3421759d8e3aaeb5481',310119000,NULL,NULL,'576597cb241dfa9eada633311916072451225339aed38d1a481c82d5e2833fd5','150116b996df1ced9b230a02a8762e285e27f29fcc04865fa9e7671b4412696e','11de570f5be4a32aa6be0e6db1dcb0410a5960880d13ca17569fd15117b0362f');
INSERT INTO blocks VALUES(310120,'2bba7fd459ea76fe54d6d7faf437c31af8253438d5685e803c71484c53887deb',310120000,NULL,NULL,'abb63a7c4edb99c71e21d1f634fb7e95d104e420133b2d216af99c0a367be94b','af68c65ec1d87d63c34de0895b60164b42898fcd9a2b7a0df0ee0e5c51830bc1','040e09e09ccef462abe59b6aac94688235d17f8d1d90e20899e97f0a5acfee57');
INSERT INTO blocks VALUES(310121,'9b3ea991d6c2fe58906bdc75ba6a2095dcb7f00cfdd6108ac75c938f93c94ee7',310121000,NULL,NULL,'b72746feb9077aafae6737529b4c1f0552c20ae45edaa72c2df4bea3c018d532','723a92ba4bf242046d78e78090b65e27459641071c8b01b50a22178118578cdc','a198d0bcc2a79b8cc98a60ee3833d3f365e6edccca8018f2a5416b00c36b93e4');
INSERT INTO blocks VALUES(310122,'d31b927c46e8f9ba2ccfb02f11a72179e08474bdd1b60dd3dcfd2e91a9ea2932',310122000,NULL,NULL,'add1e878e00a20f8f357bc783cde6116665655b241d473f854f0808ddd9b73c8','47738b1631b02241f32cc0d116ffbb71a84ab0478accf0b57ca6e62fa5dd4ad0','1822d2d05bb0779a132f0e2eafbc8947bc2fed79d8c9ccbc40f3510bb2adcbdb');
INSERT INTO blocks VALUES(310123,'be6d35019a923fcef1125a27387d27237755c136f4926c5eddbf150402ea2bbd',310123000,NULL,NULL,'d85015fd04e9cb0b6fffedeb2f925e2dcc80666528daaf98124ec3565e8d3cc0','a8ee8383aa3412bd27a86553058c32a6906803a4f5d9049523bde8dc45eac323','64ddd854745aa2fe9c4a9db119e4acdbe4a5eefe39f0cd020528842e28c97920');
INSERT INTO blocks VALUES(310124,'0984b4a908f1a7dac9dcd94da1ee451e367cc6f3216ee8cdee15eae5d0700810',310124000,NULL,NULL,'156bd9f1502fb3eefb80646fc15df6a2855e0548c5d877dabb7d4660324609dd','dcdfaae48a8c51709f62889b4b8938f1b1f5d8c6e377824055f27555fe0a1237','1947ed8825cda79328d78601b8a57a6a2dcf0f2944938b6a2d2e006ced081af6');
INSERT INTO blocks VALUES(310125,'cc28d39365904b2f91276d09fae040adb1bbbfd4d37d8c329fced276dc52c6a6',310125000,NULL,NULL,'d0b288be666bd1e4a7a6ace21c2b373330dd73348825f93cc46086cbbcd48a0f','0532f73277d01088a095e56d2d583af1f694b2dd37ba96d65d1e7977b52bbb6b','8713d58394b20d38fc34a4e821a39f4c3aac44bcaee9e20b2ed1b7214ec26482');
INSERT INTO blocks VALUES(310126,'c9d6c2bd3eeb87f3f1033a13de8255a56445341c920a6a0ee2fb030877106797',310126000,NULL,NULL,'c2c842ff8f74fdecd9604a947792420c1e8a16d9eae381a2bc9aaee9694f4067','19e9c4457c206fcfe9e56fc4fe3a354bc380dcafc7115370b1605723b0c5aa08','3467c4e9dae55dff65638489518920cd1547b826fe0a8d408c50fcc5fa9e2e26');
INSERT INTO blocks VALUES(310127,'c952f369e2b3317725b4b73ba1922b84af881bd59054be94406a5d9bbb106904',310127000,NULL,NULL,'d8cca33e7e524da7740a21d5958359a3e6a6f314251e5250f0bfa06bd16f358c','4afb2da250d76a69eef32abbaa0f82d74084b89a43e3fc77892f7a27278339b0','ae83226b058d38c15964a039abe645a7349368fb30a81606e03b71f1c47d55dc');
INSERT INTO blocks VALUES(310128,'990b0d3575caf5909286b9701ece586338067fbd35357fec7d6a54c6a6120079',310128000,NULL,NULL,'5458f1a4d540dc33c0338b94b2ce0bd7a6398a9d3369de8f3ec6f7a8a690f753','da626e315425b107b777c80296a9b89fd82f6c23bd8bacd01818521b7a4fd7df','31a0ce1aeef9ae74d6e38f7331bd59cc7946663c464dd634d0420b626b70b888');
INSERT INTO blocks VALUES(310129,'fa8a7d674a9a3e4b40053cf3b819385a71831eec2f119a0f0640c6870ca1dddc',310129000,NULL,NULL,'5e6d75061f2ea056056681fd3f856407249975a5a4a327bbf8bc20a96743fffc','858813daf9fbe59c9e38eaf3dab25d0ab113fdee1ec66854254c209f1b0810f6','e71e608123c7efa4696db06cbb7276d36ff5fd1d7b8c10f89dfe03827d446dd5');
INSERT INTO blocks VALUES(310130,'d3046e8e8ab77a67bf0629a3bab0bea4975631d52099d2ddc9c9fa0860522721',310130000,NULL,NULL,'200b50c17c51fdb4275ec49e7300227a63ced6e3ff9292be49eb7b402d3db1b5','7f104d132ff1bf82861359d176daa1da84da92338469db44470624c4f254c0a9','db478a1086e1219302a67b9a7c6dfc3e3b2d22c7df9ad3d01bb7000286472a11');
INSERT INTO blocks VALUES(310131,'d6b4357496bc2c42b58a7d1260a3615bfdb86e2ce68cd20914ef3dd3c0cdd34d',310131000,NULL,NULL,'de1c49ab1e413b11cff49cb50b22b8ac76a1ad93a024beebc8f9ad0d959525d5','1fbf7f0e23fe98c7765f7f700dd33724667aa1704b5d0d08e8582c9956ee31dc','038ef305f962b2c7315131149925c2e8001542ebc54e2b9c03fe4857ba110aeb');
INSERT INTO blocks VALUES(310132,'1b95a691bf4abf92f0dde901e1152cc5bd87a792d4b42613655e4046a57ab818',310132000,NULL,NULL,'306d6f01cc778512334b73d66435983c57183e7c4f87c26f1166a7a83a36a155','5fde901a2f436b0af486dfb949fcee235ac8142139878a1c1842b597413b4e37','af27afc0616d59cbc639a4a78cd546121bf1a6e682cd53891ae2f9fdbfc9c193');
INSERT INTO blocks VALUES(310133,'1029c14051faabf90641371a82f9e2352eaa3d6b1da66737fcf447568ca4ec51',310133000,NULL,NULL,'e156b907295c14968c5fbe5e8fcc9fdc0415f3413a36a7ed737ea9e9f153e958','42e316aba3bad1c9bb66a6830d906fa330b28303069fed56e1a49775ab522cc9','83b7e6209d7d60a288c7c97738654343c8c744b89e947d3659bea7db804c83c5');
INSERT INTO blocks VALUES(310134,'1748478069b32162affa59105257d81ef9d78aee27c626e7b24d11beb2831398',310134000,NULL,NULL,'2528daefb0d2432358a70b10e11397535232c4fd2e69eacc77219c423df1d3f8','0692b545fd5f2d3041ae9a684565028e5b06ca9c411ab6317e245f3cfe0c93e3','ef7ba73ebf0e55d03c75f7e43f3062310ca73e438d840e2aa40ad17e3e2a54f3');
INSERT INTO blocks VALUES(310135,'d128d3469b1a5f8fb43e64b40f8a394945d1eb2f19ccbac2603f7044a4097e4f',310135000,NULL,NULL,'81b3a7fe120fd6f795536d275ac4b1621fea8a4d968b14a51a71ecee6944a819','5740d89f48c7a191e7537065a2bfeb3e4f4f970d518993d18558d1637519a096','67e6712df07f17a4a02c4848c92d61e8de2aa787a0de6cf187183cffaaaca8d7');
INSERT INTO blocks VALUES(310136,'6ec490aaffe2c222a9d6876a18d1c3d385c742ff4c12d1334613a54042a543a5',310136000,NULL,NULL,'405c424434f5e9036d00704008be3793514d29a5bc619c6f5cdfd3c86326fd77','f75142b1f6d0b7d6f6580d6df56e9fb2972d22d659219612665c1e570a48c6a6','d058c8074f5703b0a95a0bccb56101296f6999f6130c9a952cb8c22408b696fc');
INSERT INTO blocks VALUES(310137,'7b44f07e233498303a57e5350f366b767809f1a3426d57b1b754dc16aba76900',310137000,NULL,NULL,'7ee1d757a81c357ea0d18e59433d275a28f04f384baa35cbb874d75ec0182dad','8a3adc908db2e9838586dfaf5072d74541efa3cfc59eade8bd404354a6adf585','c263977d92c925cda49155be011f5e914ec74e3034eb9dfa8fc22112767a9e21');
INSERT INTO blocks VALUES(310138,'d2d658ccbf9baa89c32659e8b6c25b640af4b9b2f28f9d40baae840206402ab5',310138000,NULL,NULL,'1306ff4026b302043a5f418cc64aa65a1e5da7ced92aef50ba9c5699509f9eec','cdb89ee1172f1780d11084a7c9db5fc46acaf8700f6cb847193b6d1184a32652','aef3a61e3dbc4baf20b5eb776b6459120fad1a7f9660d9659d340dd599aeacca');
INSERT INTO blocks VALUES(310139,'b2c6fb61f2ae0b9d75d18fce4c52a53b1d24772b1ad66c51ca51090210527d46',310139000,NULL,NULL,'ea081adf4304d85433da18652bdb032ac5916bc6a1b96410cf0ec51f87a5c519','d1dffd434ece3a1b5461fc897a6e39cfbbe53ba69d1e8ae1aa10b95257eb84e1','406486ddc4f985180b93ff782183930c400c860ca4be962ccc6a6aa8637d9887');
INSERT INTO blocks VALUES(310140,'edddddea90e07a466298219fd7f5a88975f1213289f7c434ed47152af6b68ebb',310140000,NULL,NULL,'96f0be399144ab67ac49b54f80ef596a5c508e0f052d35b07259aff88a559a0d','b3aa57b7eb0e9c0adea1a820d4458d7170989f97bfe8ad23dd2e30567b67f6d1','08d71bfa2a841924a97cf800e9a8766d6b704990a81d8fff59f0b2ed0ab350a5');
INSERT INTO blocks VALUES(310141,'b5b71d2a271bd638561c56f4ffbe94d6086debaaa86bfeb02ef0d71339310709',310141000,NULL,NULL,'fed95d3c66979f94f4cf0ee075476b5a3e37d17285e1e84e2dcea837212ec8ce','a54493df2b15e9bc42a995f552e2b94199b1dc6b59b4114f0bb08ccc484409a8','2aaee786f040a1d0e9d7e8477f3415c1b284c5bac282918d6bea39496209e231');
INSERT INTO blocks VALUES(310142,'a98ae174c41ab8fc575d9c8d53d8e02d8e446b8c6c0d98a20ff234eba082b143',310142000,NULL,NULL,'d062c8df1d3bbbed10c67250e4273f47d9edadbeae329e91a0d9214d62e2dafc','320e438e5c6af19ccde29d9eb1ab07764a36a9130aef732be1a456dd3d79901c','7b134ca5d73a6664d327cfd7be182e4262a87279f8d591d05e71819848080cd7');
INSERT INTO blocks VALUES(310143,'8ba2f7feb302a5f9ec3e8c7fc718b02379df4698f6387d00858005b8f01e062f',310143000,NULL,NULL,'8b58427567f04bea48d8ef1643b1936731dfa1d44ab5ae8a0a725f5808e5cb25','4253fe96ac291b1d427c3964099139bdfd505b36f52bdd236ff9144c9102b356','6fcf6bb91f5d37346afb9be0f759e23ccfeac032a3de1a1d00e9149921c103bd');
INSERT INTO blocks VALUES(310144,'879ffa05ae6b24b236591c1f1537909179ed1245a27c5fdadd2218ab2193cdb9',310144000,NULL,NULL,'17fea61e6f803d990bfd78ae94f5482755577ffac62c56ae964a9ba4eba2a4e7','2253019767b48b1b9934394466c8b1ceb81968ef8993c1f196a036428653a242','197c822cc7f0a4479d96876fb4698aa09372f58441ba61caaf13d3ea8b2a53e3');
INSERT INTO blocks VALUES(310145,'175449ef0aa4580593ad4a7d0c5a9b117e1549ea772af00caa4ccdc9b1bf7a6e',310145000,NULL,NULL,'fc7745aaf59225dfd4055496462ef19352e31e7a681d5ddeee5d8d305914cd63','03cecddf300693e1bfbef77f042b1d44251ebc2a86f271a9c2fc4ccdc5b60fc4','d0135d0911d021ad9643330c6671d1b734027fbe4c1b85836327f1b20e042eeb');
INSERT INTO blocks VALUES(310146,'e954ab6a110455d745503f7cc8df9d92c1a800fafdd151e7b1912830a9cb7184',310146000,NULL,NULL,'b21400cea27ddadec8c336f757c1f250be59c2608323f5492cc40f0c2c54c086','2550fc62060d93a47e15366b6e17b88eeaf2772445d84454f944ca934ff6cccc','a100f3e722b7f4b47d2d9fae8e141740de2b1efc8cf423d5f2868294e2852843');
INSERT INTO blocks VALUES(310147,'7650c95eba7bf1cad81575ed12f32a8cc36281a6f41bef13afe1dfc1b03a7e83',310147000,NULL,NULL,'47ed87885040679eaed04907a9adcbeb5fd23c3220d106cf991c692e56a47c85','90d7e130f61d1c62034f158821336a391be63f612d03c09da93889eca87c2fc6','2079f828be308c0159211181cedd1507432b882386b1d3d440cdf3a0123d21a6');
INSERT INTO blocks VALUES(310148,'77c29785877724be924f965215eb50ffe916e3b6b3a2beaea3e3ae4796545a7e',310148000,NULL,NULL,'f2b6fbf8a0d2d8ca5b7f837059d3d5d4e377606d715255ece9d66cedb1ebcb5b','eb285ae626436be20614a5716e8c25a0fc6718fc39b73e1530a5f37400fd49b9','2df8ba75555ba67ad802cf5b2a0797ae07ce662b2238f1c31b25a0bde66420ec');
INSERT INTO blocks VALUES(310149,'526b3c4a74c2663fc04ed5234c86974bffddb7235c8736d76860778c30207b3c',310149000,NULL,NULL,'7cf62dc8d0f09332900b3d3faeb973c75f60e7118ba2f5ec25f9a1d02e5373de','2b5c362691fa3613e25ac678f5df994c8c03cf203d0742819a583b67c9268200','844b262a703e7a7efd3fb29044c16ee120bea715c1acbad98ecbdb8049bfe584');
INSERT INTO blocks VALUES(310150,'cdd141f7463967dbeb78bf69dc1cd8e12489f58c4ea0a5dc9c5c01ec4fcea333',310150000,NULL,NULL,'773cd82211234feb848d9246f3e7da054bd0083d24aed81143cffc9c0dc00074','f910f48ad0bd49b2751d609012f3f67323c07f7999bfc5afde4ba3c25e2bbbb0','b73c7990ffc904df84b0af59be4a502f0495084fdeafe047b4705d8d842a5fdd');
INSERT INTO blocks VALUES(310151,'a0f31cc6e12ec86e65e999e806ab3bfa18f4f1084e4aeb4fbd699b4fe284b330',310151000,NULL,NULL,'532dcd1eae2240e6117d592dbfde30600f391007daa8e233ff99cb26ebae995b','6e7efc6bf4f12bfeebe705b9576078720e1b601d3a5ff4447bd4833a55fede87','aa819d1fb040f0e54cb8b935c67819eb832673916c0febd63c53dcb891da13ac');
INSERT INTO blocks VALUES(310152,'89c8cc3a0938c63a35e89d039aa84318a0fc4e13afac6beb849ac37140132c67',310152000,NULL,NULL,'2c5346c3aab989386ee49d27c30939760b6ff2eddad88147a715f0b4346f5c81','3aecccb73627c660416b9fa976bcbdd2fe38560be564e4a0e74928fac8f8e037','8084c39baa120bd2b90f8aa7bf78f06a48149243790982c4664a9511db9ed6c9');
INSERT INTO blocks VALUES(310153,'d1121dfa68f4a1de4f97c123d2d2a41a102971a44b34927a78cd539ad8dca482',310153000,NULL,NULL,'2662192765845a97bc1bb97f4b8b0a1d8c73d6c4a57ba6a36062bd75094131cc','d54aa10a6e62ef97d9f4e3f7fdd44b8bc50659d862ee6d10f65583be4bf9d071','02441b4805c7648515366afb003ba420953ca18cae04faee7fa64424fa52ac3c');
INSERT INTO blocks VALUES(310154,'ba982ea2e99d3bc5f574897c85485f89430ae38cf4ab49b7716ed466afa506d6',310154000,NULL,NULL,'662789c8199a23fd244f020fca7cf70af20e9792dd66801ac0cfe5a871279fc3','9c168983fb8675153e3bc183769f630bcbc7e1691838882288ab6834aeccb999','3d2f31fa1eb98f0a27b89cee420df180b3c6d8eeee6b9ceb1208fc581082502d');
INSERT INTO blocks VALUES(310155,'cefb3b87c7b75a0eb8f062a0cde8e1073774ae035d176e9769fc87071c12d137',310155000,NULL,NULL,'6db116d18753ecb4c147346942c7cd41f3ddcd0b8b5300c8560c6cf2a1ff2b0e','72705584451eca6b5145a1d94a58a9cf78d9fef5714f6556dd67109ff3152a20','af3a8a36c92f62b9e059b15620e4580c3d2afb35191ed025b3b207ac5b3238d4');
INSERT INTO blocks VALUES(310156,'6e3811e65cb02434f9fde0445a7a2b03fe796041458737d0afcc52208f988a83',310156000,NULL,NULL,'18738df90f8ad63adfea0d45249c8c11e3429badec69f9d80e4d542ad78af26d','cc6e184dad545bdff83a9aa13c5773835f17341cbbd9c40568277a3f4b5cefa5','2068ad85ed15bcc6cc54e5496018e53112e2ea9470379cac9de97e7a415d1412');
INSERT INTO blocks VALUES(310157,'51dd192502fe797c55287b04c403cc63c087020a01c974a565dd4038db82f94a',310157000,NULL,NULL,'41d6b09f49e434e7cee1c174880a19624f796685d18cca88049572cc924240e6','d9f0a97531ed7c7ae170af77baebe7b0b0d14c4a8f9532968010284ee595b07f','55ce7300f4aeda4714485523414f7b29402b86b689bf88947ed4c0d02b19dca2');
INSERT INTO blocks VALUES(310158,'749395af0c3221b8652d31b4c4410c19b10404d941c7e78d765b865f853559d2',310158000,NULL,NULL,'4c436a14a5f2fb45f9525122d91559961c5ae92b182d1458f421d72b8689c555','20054e9b240c44cbdb8b882af4a306e73cc0e21c4598f48e6c8a3be9e524a7f7','20541a85051776901e86ac1e3784bf2caa641b6527a70bbc5fdd0290c3687173');
INSERT INTO blocks VALUES(310159,'fc0e9f7b6ae99080bc41625588cef73b59c8a9f7a21d7f9f1bf96192ba631c12',310159000,NULL,NULL,'9f3c424fdc6eaf4fc11fd4bf6d389af9aaf82dddeb378f050446ed0f191c415e','0edfb8d9e694603056f0043f0c0db7555b2feafea4d36ae48930b60cf2e35ee1','0998018958ccbe27553fc6d787bfda762917693565d5f69424dd4f305eb9ec01');
INSERT INTO blocks VALUES(310160,'163a82beeba44b4cb83a31764047880455a94a03e859dc050da782ed89c5fa8b',310160000,NULL,NULL,'7a2c16fb611558b70b31f8f12c6d0ee08f0c04d6901f5e674984407400dc4f7c','d946523b8aca5206958ae6074d64d6abf2c5dbc7c9e769a4b566f2351e5b1547','f86618abceb86a10718495f59e860b1c15eb9bddfd8bf980e284ac9a66202037');
INSERT INTO blocks VALUES(310161,'609c983d412a23c693e666abdea3f672e256674bf9ee55df89b5d9777c9264d8',310161000,NULL,NULL,'b8566b51d69aaedc491add41ea3a4260406b04b8d417163c9122b6d46b23e043','06c5d32aa57559c283de12e0dc11722ba1e15bfabad168f3cff2d595cb62bf1c','31fbabb7961f93eb9dbb434ab1cf2885e8e24d22790b52cac17ba95435010472');
INSERT INTO blocks VALUES(310162,'043e9645e019f0b6a019d54c5fef5eebee8ce2da1273a21283c517da126fc804',310162000,NULL,NULL,'8bc4f34f2ff6ee796a9ee54cc8e3374136a2226343ad506680ba94a04a74efdd','91c87f992fc1173fd73e616190772658003384e19970472cb80fe5c27be5c9fc','534eb58882ac5197c465f6e2b9144aba799e96b19d420b46cca59c8dbba9d3e3');
INSERT INTO blocks VALUES(310163,'959e0a858a81922d2edf84d1fbb49d7c7e897a8f49f70bd5b066744b77836353',310163000,NULL,NULL,'d5b71a21ec5123be72bf29d699facd204140d1863ac22ef9973920a7f4fc0773','ab93853e0c7d89ce3d822fb19a0f9a449f4ac4f74cf7c83020c1d1d23d3a22ea','b9c0e840e2dbd7940d14e0d14c0d85f16cf98ea8345264f7c33b53567ae89d06');
INSERT INTO blocks VALUES(310164,'781b7188be61c98d864d75954cf412b2a181364cc1046de45266ccc8cdb730e2',310164000,NULL,NULL,'2f8c3ed867557c8cad28de08cf82fa2484ceb8f7d7cc26fd5c68e15019ac5f87','2876c52439e39f0bd0b7e4590463c6ecfec0a6dd9e5a1242843aa40cec3704f1','617a5b8b1713ff69903354ce8e04fe8527005773d472f797cc372e92ec281b27');
INSERT INTO blocks VALUES(310165,'a75081e4143fa95d4aa29618fea17fc3fabd85e84059cc45c96a73473fc32599',310165000,NULL,NULL,'eedb0e236cd48b9afe186b5c34002e4a17679ab7b10ed8c0854d2683ea7b4df0','928e20e71e8a1b6b84c679ade89e1492ea96b29db3f6a61bf426cc55299bfc2e','5fead5a3091f07234dd39c64fcf99fed21ee89e93ac28bb4e0655fd7f8b9beb1');
INSERT INTO blocks VALUES(310166,'a440d426adaa83fa9bb7e3d4a04b4fa06e896fc2813f5966941f1ad1f28cfb41',310166000,NULL,NULL,'392df958448612ffdfec7f6aea1d3fa37c6f15147be61667bca1f16ba101050f','b508c9fcaed026fb7168c1b3e01d2c73c9d4c51c9f5259b47b5f84b34cb08301','9dc61b2b3285517f3a9b4b5fac5a0b9c60ff2971ae6ffaf958528655bc5f9806');
INSERT INTO blocks VALUES(310167,'ab4293dbea81fedacca1a0d5230fe85a230afc9490d895aa6963acc216125f66',310167000,NULL,NULL,'2d0a69eb324f085f3b36317d169902be8d4c40707c8afe2ee5dc56c104020990','758ec7e9ab90f4c4def801b618ae43422d21c7339eb10accdba751e13217fd06','3202a72776a9b288976aff92aa1d427193d6f34d19ce7d177a96cb394af18864');
INSERT INTO blocks VALUES(310168,'a12b36a88c2b0ed41f1419a29cc118fae4ecd2f70003de77848bf4a9b2b72dc9',310168000,NULL,NULL,'9339de42b016d558c571ed1b4a907a337995380951d1652c36cf9685d6d063d7','0f1ff8d92f75048330ca8869e384ecdb646f6c68c4c598911377e8c03f000dd4','e2bc3809831f93b3cd5af8bda30fa07265a4a72c1367d89dba28a48c77119eca');
INSERT INTO blocks VALUES(310169,'204809a85ead8ba63f981fc1db8ae95afe92015f003eaebbec166021867421f3',310169000,NULL,NULL,'b0cc29ba6075a4519388aa13b2ed8ac13e779414c50a2b0a048794065eccdc80','843b0fa5f19a8afc352d7c7182c392cfd0422bc40743ecb3b267d0b1cec64c6b','905f9768e6455b5d786bc9b772420c1121fe66769e7a61089926aa32b6e87121');
INSERT INTO blocks VALUES(310170,'b38b0345a20a367dfe854e455e5752f63ac2d9be8de33eab264a29e87f94d119',310170000,NULL,NULL,'d342b3a0badabc8a47a15d695f7c877b54287645fd8df0d560177a57c7f0db3d','2271b50ddecea1bc23bf912540465398ecb666e08f84eeed013a2b0abda38237','36029de470b6e5ea5ca1a7e9db9dbe112ad71652f7f2da44bdad07b1646ec958');
INSERT INTO blocks VALUES(310171,'b8ba5ae8d97900ce37dd451e8c6d8b3a0e2664bb1c103bf697355bf3b1de2d2d',310171000,NULL,NULL,'c994a2733d12b3e28523f9ff8edc162f54f9218565c8ea5d4d100441f0477d02','c4909e9223719f3f12c9eeb8ec13088af51397fdf9c06049f98e9715960da766','551326b72fd52fd857dea5f26091d3e860e89d08d043c0620543e098d53840a0');
INSERT INTO blocks VALUES(310172,'b17fda199c609ab4cc2d85194dd53fa51ba960212f3964a9d2fe2cfe0bb57055',310172000,NULL,NULL,'397248fb2a54f0570de5b24e9375263f3b54359727077a30227931c1052dd9b4','5d2f14e26b6a71a4de5f83fb1fb8f7a2f2d49de94d17c4486e5af2d4365de61b','c32111be15f383c42fc77bdecf8720cfb04b041c222c3f475f111b9ac88b4e88');
INSERT INTO blocks VALUES(310173,'f2dcdc5ffc0aca2e71e6e0466391b388870229398a1f3c57dec646b806a65016',310173000,NULL,NULL,'66d5758c943c8332f1491005e13ee5a906a80e2af7ab8d37b236d309756def31','f98df1878ac834d648131140ce60dc8677d5607cbe9b26bbc401371c39e356eb','9641785b3a63b2c4d9e628817c43ea90bd8ae1f6bbbed609f24f1d1f1fd6326b');
INSERT INTO blocks VALUES(310174,'fa6f46af9e3664353a473f6fffce56fa295e07985018bface8141b4bf7924679',310174000,NULL,NULL,'f45eb0d49b4498017519bafb08cb7e31b5e633391b1c748866a443df5004f53d','adfe9de033633d97213257b6be049c15472c92b8e1d06bfec77b1d023493bf4e','62bce8b8068f71b230f823cba150e4e50312eb803755576eb57c33f6924d5201');
INSERT INTO blocks VALUES(310175,'f71e79fe5f03c3bc7f1360febc5d8f79fc2768ce0ff1872cf27a829b49017333',310175000,NULL,NULL,'5f9cd3d5d4d3d9dce35bd3e76f8530c7dc2992a97785149011a39f76dc9f3b88','1185d8ad080ea769025a93c0dbdfaa9c277a4e034a25fa9256b84cc52ec79f67','6f8e9fdc536a441320559a8b930ae75535c5a0bfb200b4a7f8adce8e907e866e');
INSERT INTO blocks VALUES(310176,'67cd1d81f2998f615602346065e37f9ceb8916abb74b5762ead317d5e26453c6',310176000,NULL,NULL,'34471b4af7737e7024fc3762d0e37a98bf12b619fdb0a4ce110bd2950e3d3bc9','cac87537495f514d3d3fc05163dbd4bb70f4d654972078a5e245870b84738375','e1bc350ec7572a1e9cf269b235da3b9d7950971e4119c3b3820cc31131eef7d4');
INSERT INTO blocks VALUES(310177,'6856b1971121b91c907aaf7aed286648a6074f0bd1f66bd55da2b03116192a52',310177000,NULL,NULL,'e1352b09b865ad48fe35f2a71ac1d1c188bf0f4ad7aa4ae37fd06027e556b2ba','20e628d262872ecb51ad133773a4a4c513e33e46ea6aa783a5deac729d15d01d','c2de366618c0fb1aa473e731e8d92f897237d71a9c6eea27091748302ea12012');
INSERT INTO blocks VALUES(310178,'8094fdc6e549c4fab18c62e4a9be5583990c4167721a7e72f46eaf1e4e04d816',310178000,NULL,NULL,'3b6ad6e8a04f803e70f6e366d16d30b2179d1624a93db041c33cf4c4d28dfcf6','7af1832274ba715b2fb06ed6b9c0075850ab38d2da8586d16c3b9dd89eb3c61e','09635e60f88166606fba92971819d14f28d15bc5bfa866bd44113264c00adfc4');
INSERT INTO blocks VALUES(310179,'d1528027cd25a1530cdc32c4eaff3751a851c947ddc748d99a7d3026a5e581a7',310179000,NULL,NULL,'7f574d5c3d785d4070e92701956755101bd86949141b57fc4e585bd6bd2ad56d','4a5376ed760c7cb359e2f4cc87b67df714b9551251d876b067e304ef5f3ee8a0','03f4f25cf0c7df4b74b8ce0faa5aaac3bff2a50e873869380b32bf3539b6805a');
INSERT INTO blocks VALUES(310180,'f2f401a5e3141a8387aaf9799e8fef92eb0fc68370dae1e27622893406d685c1',310180000,NULL,NULL,'9705d812c0cb4ca03e52ccb28a01522caef3cf41df45e7b52c32267a93517dae','d69a83e3594dadfbab585d9029aa680905b73b38361bf75e2d7cacdf294c2a29','4c5556fb93ef932fb3ebc94595cb9bef71d9e34abec0fd8bac3ef486972ae172');
INSERT INTO blocks VALUES(310181,'bd59318cdba0e511487d1e4e093b146b0f362c875d35ab5251592b3d9fed7145',310181000,NULL,NULL,'808802d90ae3381feee9c5ed979e03970330135a60d9a270c719cecaf805764e','49653500b7db7ae8c706d1adb17616edd32708b652f18d32f99b4672c79e381a','4ea0c89f494f65ae99ab535221b8b24203ccd2e4685d7515e2700a5a08dda80e');
INSERT INTO blocks VALUES(310182,'a7e66b4671a11af2743889a10b19d4af09ec873e2b8eb36949d710d22e1d768f',310182000,NULL,NULL,'3e8246c907b75b7dbbf1a07b044e7c146c6d802c52792ba26b0085e399653932','77b651213c9f96b0dcedb9fea053d81136614e96adbdc344b584361f6d60a7d5','dde63bf8aa29fc5467ca47ffa4a8db10a30dc506eff041b9029e32aa6466df31');
INSERT INTO blocks VALUES(310183,'85318afb50dc77cf9edfef4d6192f7203415e93be43f19b15ca53e170b0477bb',310183000,NULL,NULL,'c830f4f39b35688655f8d3c3dd9314d1d8fe3a1aa2810ef4ec7cc51faac676b0','95301a4a14b9d8e0800ecf147e273d85a63a355a7c0cdc9f3caec52b0d58f3da','3ee3f88a6668e9a64203287eb58552a170d68dcfcba625689ae06595a6b17982');
INSERT INTO blocks VALUES(310184,'042a898e29c2ebf0fdbb4156d29d9ba1a5935e7ed707928cb21824c76dd53bfc',310184000,NULL,NULL,'499aa926aded967f6261ac213391b5498edb855c21ffadf25a0c5ff8378e9a91','3fdad1d557aec53603e858918af91fc98dd98c9286c7868333b19377aa076787','da67c43356bda316d21f4215a3486ae92397b4e46d7c2a2e36d154a1406bbce4');
INSERT INTO blocks VALUES(310185,'bd78c092ae353c78798482830c007aac1be07e9bc8e52855f620a3d48f46811f',310185000,NULL,NULL,'22798fe864fc015e0bcaeb760823342dbc7a9756d153cc428929b8945c6e6fe5','5f38051d600419ca5f85f0271f2aeba79ea3b769943a32976f05189efe01f3a6','c45e68a28754ab22ea98e5910c31cfb75696b782a9356331f69060d8646cb6b9');
INSERT INTO blocks VALUES(310186,'e30a3a92cc2e5ad0133e5cee1f789a1a28bea620974f9ab8fa663da53e5bf707',310186000,NULL,NULL,'6593028cdf86b5f3e65509b22955212d2b3a649741e439791c72b7e3c8734ad3','676d4908b2453f2d68ad818d47dc8b07c60cf9e68835ae8f35d2fd6365016bd2','9536b231287be111a8e47563508a1ba61582c80f7019fe6808803a99516c864b');
INSERT INTO blocks VALUES(310187,'fc6402c86b66b6e953d23ed33d149faa0988fa90aa9f7434e2863e33da2f3414',310187000,NULL,NULL,'e49da111e3998fafb7929ce5f43fcb8de9b89aba6a06fab288ac8106e8c06c47','a654c645f51f5e5cb0d7f0e25bb197ba4780d226cc4cdb0ab62578c55740ea20','4872b2b309f6d69d0c784710420a81a4f8b35e845367fc45b0bec09adcf21508');
INSERT INTO blocks VALUES(310188,'85694a80e534a53d921b5d2c6b789b747aa73bf5556b91eeed2df148e2ada917',310188000,NULL,NULL,'f36aab93a395bdb52168cca5be82b3d370073ac10a1eeda1e6769a2db96b8212','5d1dd21d72bbf1dddd1d5134365f2e13265e39f6c5692d90d25a90bec91b5ee4','aaa8fb9992f61164cda0ab61a4fc905bb90868069d8e317de1ec0192cd458006');
INSERT INTO blocks VALUES(310189,'7c036dadf19348348edbe0abe84861f03370415ed2fec991b9374dbb0ca19a06',310189000,NULL,NULL,'caefec27a1031498981b5d4f0329dbc766eaad6f8c4230f4434dbc0440877109','735af93eebac59e8a90644aca946397313a0bb97fc0f2655af3ce21d9daeeeee','b9f48a2cab3da128622e1945748b5a8d16ba10a77088ea2c9388acadf61286db');
INSERT INTO blocks VALUES(310190,'d6ef65299fb9dfc165284015ff2b23804ffef0b5c8baf6e5fa631211a2edbd8d',310190000,NULL,NULL,'df92ef8478fd68d4774b3e8cb83ed1a069fbc5e3d666a5e8fa462013f1b890b8','6fa2a02cb56358a675470bf16d58c168ce04ddc39c42eb3c45ff50377cee56d0','54d4f977d6a8f4e662241874ecd653eb0f2377e460fb51c472b72e75717216c7');
INSERT INTO blocks VALUES(310191,'5987ffecb8d4a70887a7ce2b7acb9a326f176cca3ccf270f6040219590329139',310191000,NULL,NULL,'87cd3ba6903bb0a5afa07255e569534845b926e6e3a1eeae7043ef15f695a788','eb36c7896e7406f088b78c982f416e3bc7c76fe7bb72dd080d0638f98e71d277','cf102f41764da1cc6c4419c115f7148b425eb64bc4e69b0bfc7eca9667f53e78');
INSERT INTO blocks VALUES(310192,'31b7be43784f8cc2ce7bc982d29a48ff93ef95ba18f82380881c901c50cd0caa',310192000,NULL,NULL,'93831212bdb388f4e2db36ca5d6ccda6fba1c401db7ed046f1cffe261569e3ee','4ef486f1e2d14770720eb71900d3c82c67698c3a7943163016a2dfb813b0a71f','88440ee4830ad2213119bce204c77fdd880a875c3af1765bca277c9fa51a8a1b');
INSERT INTO blocks VALUES(310193,'ff3bb9c107f3a6e138440dee2d60c65e342dfbf216e1872c7cdb45f2a4d8852a',310193000,NULL,NULL,'299f6e3d677e12c0f6d02b242ef82dce4e3c75402ffbee4f891ba777e160091a','a809bef702b7f47dc103391c34c813b52d852e81c9853f00cd5ed43dc08e0fa2','30e28dd835f8603b4416cb06984ae035002721891d310bb5838c96586bf04e7f');
INSERT INTO blocks VALUES(310194,'d1d8f8c242a06005f59d3c4f85983f1fa5d5edcc65eb48e7b75ed7165558434a',310194000,NULL,NULL,'330c75c62d310d5214028311f19119b9aa3b413c1491067f8cf3567a1f37bae0','244a5998b9cddcff0a2b76205310c4925414918dd24e34b358a883a6afa4b735','e20eb59fdf279cad1dc7ab0843a4765c346705a941268de8af3b6dabf6095284');
INSERT INTO blocks VALUES(310195,'0b2f1f57c9a7546faac835cbe43243473fa6533b6e4d8bf8d13b8e3c710faf53',310195000,NULL,NULL,'cb228e7c41f04f75bdb8a2a26e9848fd7f642176d4e3a6436bdeb61c102811be','67ed1b5908b9386b2e7070967eef3d178a184b39229a0b5178656c91bda856fe','234394c4cf74fb1ff70302d35314fa35aa0a71ec4a5708b759689a79b49f6085');
INSERT INTO blocks VALUES(310196,'280e7f4c9d1457e116b27f6fc2b806d3787002fe285826e468e07f4a0e3bd2e6',310196000,NULL,NULL,'d336a7f2e3bcbb067abca699119cb0b3a7d8e1cfb2081c6ac93d3ae1183474c0','f8744801fb101e88cceec9d7f89554aa00b3bfc820dd874ce2cab1b60c626f3c','0b025afdf3338cc28f176641baab27793ea9c9d09b905d2cdbec21ff2b9e3641');
INSERT INTO blocks VALUES(310197,'68de4c7fd020395a407ef59ea267412bbd2f19b0a654f09c0dafbc7c9ada4467',310197000,NULL,NULL,'e1c14ab4ba11baa06f837c43575b058a38b7006c6ff272a0960f65d4232cd2ac','8583c92f3a3cdd0f2d84375167346ddc42634224a79ae5992836f7686f916d86','448020845fc9c04be9d67dda908792a3f4d1bfe99e78286bb600b7bdbc775443');
INSERT INTO blocks VALUES(310198,'30340d4b655879e82543773117d72017a546630ceac29f591d514f37dd5b1cc2',310198000,NULL,NULL,'03c1bbb6d2b19b199bc13c902541db2cfa8ae8c5198d8271d8699ae0a08bba0c','cc675533ae6f9bc261ad7648601e2742cca3ae7a032fce1fdd0daf9dae112ff6','a5b6df3eb90df6a7c8c61d9b735a02f4139bff9f11ec93e9e7b6e168940bacd9');
INSERT INTO blocks VALUES(310199,'494ebe4ce57d53dc0f51e1281f7e335c7315a6a064e982c3852b7179052a4613',310199000,NULL,NULL,'7c998d1ebcd2fe1c91c9d8aa562bd934b67521b09abcb443b18e4bae4a3a5e93','a5b2e7f8b6e9c76c4849eb8ffa35aa853316873a1614ee743548cf8e4a1a438b','4ff8cdf3b9aff0733e4ae895d83d24bb2ecde2a0aa610bdb0aa5b66342f6a7b5');
INSERT INTO blocks VALUES(310200,'d5169d7b23c44e02a5322e91039ccc7959b558608cf164328cd63dbaf9c81a03',310200000,NULL,NULL,'12aa1d3ede45cfb999d785d21a19b20a0be4d51cf8ca7d78ecce47ef31334ebe','8eae4432d43eb9f697c5a7bbe6be83cc00e2eb0587d59531b21930c94b8aa4af','ef1a86668071c8f8e6dc35b0cb4eb375d8dea4d3067a70a38aacebc24f5fff3d');
INSERT INTO blocks VALUES(310201,'8842bf23ded504bb28765128c0097e1de47d135f01c5cf47680b3bcf5720ad95',310201000,NULL,NULL,'edb2ddade7ea48b2b5f57b57c8cdad714da2407c95e5776d080fd2af8e03214d','335860dea0c8c02d7d54a8fe401c833126b6735cc9a0a9d99137030b1ee77ad4','dc228483222636acae3e07ecadda57951791ebf5eb1dee143b930ec78dd2c11b');
INSERT INTO blocks VALUES(310202,'95fa18eecbc0905377a70b3ccd48636528d5131ccfa0126ed4639bc60d0003d8',310202000,NULL,NULL,'2dfba901292506aad81b75494c6526cb388e21df3edfaa75062e42c3c96c9912','566e07a84f68e5a38cfc1ed3721fbab8d808a5c69550a54161cfb07d57a2a62b','aa3e49fd57c6b9c034072f8d7dff02c9209730b8793a06db1cd20bda3d2bda86');
INSERT INTO blocks VALUES(310203,'ab15c43e5ac0b9d4bd7da5a14b8030b55b83d5d1855d9174364adbebf42432f8',310203000,NULL,NULL,'f19076b8896c2e9f702909caaaea599d941e9399301691dd1c620c6b6c01e3c5','9e1dc7b545db50007f2149c47500f30e4d60112e3aba2a18516b351116279dc1','015ce4f019ebf1a05cd59a622658a6ef09b46f7f37517cedb36159503f5aed6f');
INSERT INTO blocks VALUES(310204,'18996fb47d68e7f4ae140dc1eb80df3e5aba513a344a949fd7c3b4f7cd4d64cb',310204000,NULL,NULL,'c2b4b4672f3567833f7689ee4a4f950255e68a3e8368772ab864828419065176','d10c9f9f6bf0ec94e40abd5ad457390e37d64eea21dbf6c894b5e3371b6f71e2','3d1fd9d3cd0e635dca07e4bf387bd95ffa7c2b04cbcf292ea02d0157e9b8629c');
INSERT INTO blocks VALUES(310205,'5363526ff34a35e018d1a18544ad865352a9abf4c801c50aa55742e71630c13a',310205000,NULL,NULL,'43b5ca2b4bcbfebc564cf99067b351e4d324875416c1e21aea828756e543b7de','63e907ab2762a722d056cea714cde8240f8923d79d10892fbbb01d7784d252f8','34fa8c5089f77c5e293a0600898352557327093725b875d6f40bc3e1704b28e8');
INSERT INTO blocks VALUES(310206,'0615d9fca5bdf694dca2b255fb9e9256f316aa6b8a9fc700aa63e769189b0518',310206000,NULL,NULL,'d2e360af76dab6744571ae5f9ceb21d2aaad9b42d1c87ab5ee9549507233648f','dba4fa5b1ae410d689ed939363c8d4f256ce802a9cb6a7825f6c540d88de8142','6be16dc13a140a0be9c6f6b300968f2685ac5d3c32099029a73b31895d9f33de');
INSERT INTO blocks VALUES(310207,'533b4ece95c58d080f958b3982cbd4d964e95f789d0beffe4dd3c67c50f62585',310207000,NULL,NULL,'754504d3ac03899761a0d042496768cef714711afab73c76115ee62458b9b44b','38765235760030b835ff6ff7a3955b0278bc9938436488df74319097351677b2','68963c58e06e3f5df14d12cc90f174db12d72bd6331e973ae5830ce7f4cf6d58');
INSERT INTO blocks VALUES(310208,'26c1535b00852aec245bac47ad0167b3fa76f6e661fc96534b1c5e7fdc752f44',310208000,NULL,NULL,'cf81663f37d9c353a124bb2a3e1cdf51c8eb0078aa511ada856c8b71b801cb9e','2a3db59148a30a922be89c26239650caf9d04e40f8510a55e3a5cf83a135111e','fcec82c9740e8bc1dedc211021a2411f13de9edcecbce3468313ca1baa11a543');
INSERT INTO blocks VALUES(310209,'23827b94762c64225d218fa3070a3ea1efce392e3a47a1663d894b8ff8a429bf',310209000,NULL,NULL,'c4200a6881e0ded18a9989140d29984c19d790527693a05be9c833318461cf42','0c4f899db904e51311ed7d6ea310b0abe2babaa0143d16ba2e2bda3aa92b88ac','971f7373ff07f50ef9f4db4b58f1c3093360fe59222a8a7684b50192a1e0afad');
INSERT INTO blocks VALUES(310210,'70b24078df58ecc8f7370b73229d39e52bbadcf539814deccb98948ebd86ccc0',310210000,NULL,NULL,'4ba5e58a7fc651cbc58cd1390021b8d279a5153f114c4c518f1c3b363054046a','21fcf108bc0ca48a032189913152f8904ef1c50501edfbceb211e6af075a2889','bf6f4b684aeb0b6324748b61fb9a67aef8d4c7ed206aa3af521ee0542b968dd8');
INSERT INTO blocks VALUES(310211,'4acb44225e022e23c7fdea483db5b1f2e04069431a29c682604fe97d270c926d',310211000,NULL,NULL,'11b9e7cc6c428bbd840a8a3c2495b34a30067cbbc15589bf93eba016b477df36','49c1e95593ad4b2c5fa78e4315759c24eb748006979e1fe1c9da10a2f3ed38d1','9abf8242d8b16d32156c8b74af07d798dee9363fbbcd20f1df7a90e8f9a842fe');
INSERT INTO blocks VALUES(310212,'6ef5229ec6ea926e99bf4467b0ed49d444eedb652cc792d2b8968b1e9f3b0547',310212000,NULL,NULL,'6409a0f2555b872a92be674d1d4c09a9069350f649fa73e7db367d49fffe7347','7c140485d7367c1da3e7ab7de2eb5e3c6a650da6461a092c79f7e0ca97ded18d','ddb3f7f7874feb1a0ba5c8bf118fb24646109cae5deea04e2c880c0203394ac6');
INSERT INTO blocks VALUES(310213,'17673a8aeff01a8cdc80528df2bd87cdd4a748fcb36d44f3a6d221a6cbddcbe7',310213000,NULL,NULL,'a7323e7ff6b0b41c30092fef6a6d2844a7671c4880aa050afd92ee690eb5e52a','8c03ed54e2e5ebf9814fb05e0a8cbc347b7f5d2f516751c2276adfdd9fc00816','d5ef5931c0f21f8e7361eeaf146b37e71e01d144e4b17aed0b844e2b2a2343aa');
INSERT INTO blocks VALUES(310214,'4393b639990f6f7cd47b56da62c3470dcbb31ef37094b76f53829fc12d313454',310214000,NULL,NULL,'bb190b3cd299a892c05ec35beb187fd9ce925a84d9276f7da035d141c79cbfaf','8cf09ba036d8a3c418bc5aca2a667a0da5e69a3146e4f53abf1b1eee4b1653a2','98d0c05b771a3e093fb96612b714b38110de79e328744894a0e40df092bf0eda');
INSERT INTO blocks VALUES(310215,'c26253deaf7e8df5d62b158ea4290fc9e92a4a689dadc36915650679743a74c7',310215000,NULL,NULL,'fb51d7881a295005a571902d0ad0be52ac2a69b6f5dbf2fe09607775940005a3','b46dce2332d4b3d06f73d8bd1dfaf2e6072c220c32c6ac3f0db24a6fabe3cfa0','ef1211be037daa9deb4ad344b9e650e393e483022ac5552d5dd51d68e542f54c');
INSERT INTO blocks VALUES(310216,'6b77673d16911635a36fe55575d26d58cda818916ef008415fa58076eb15b524',310216000,NULL,NULL,'b920515215c8384cf04fd0341dece933924f778bfad4fb52a414a4301747a9fd','fe836786e2cf1b5424c7be3897edb487dda99624a96e1e14d1856e065517850b','3bf5921af178698881b274f9719f8d2ec49cf9dbeb51d71e96fe52f6c7e0e07a');
INSERT INTO blocks VALUES(310217,'0e09244f49225d1115a2a0382365b5728adbf04f997067ea17df89e84f9c13a8',310217000,NULL,NULL,'5de885656c86c1a534c5c8b2f03c05b1e1c61d43e67051b8827b80ae7638c7a2','4e1e9712a30688890df5940ec5d0279bf332e12d4e98431235372ccd96a4af94','a10b1bea4812a38bd7bc6816396b1644167418f98107515c16398a3ccab3bdee');
INSERT INTO blocks VALUES(310218,'3eb26381d8c93399926bb83c146847bfe0b69024220cb145fe6601f6dda957d9',310218000,NULL,NULL,'bdde3cafcabd6ebcd8fa892b631919081e43c9f90a0f4b0517ba4a0094789346','57c7e9c753cae56715eb32b60600e222cdf402de21da890c3a364ceac1483e04','9ac9d89ddad29f3a7bff97c3b17ba85af2759834414da85e0cadb527a99f07b7');
INSERT INTO blocks VALUES(310219,'60da40e38967aadf08696641d44ee5372586b884929974e1cbd5c347dc5befbf',310219000,NULL,NULL,'cd639a6b8b43be7a7fa6ae603abe3bb8b0ed4a257daeaa27e38566f74ac6bbec','832f72af3d8c5cf744904abb777043bf71ed84a9f717806e5e87712153c0c43e','a0a18f90e2bda930efeb39a10c76a00fb121673030d22912f1937abf10edf51a');
INSERT INTO blocks VALUES(310220,'d78c428ac4d622ab4b4554aa87aeee013d58f428422b35b0ba0f736d491392ef',310220000,NULL,NULL,'50a93f2a30dc4638ee1a2fec501c03be0ef2260dff4fffed32c460fb9331276c','0021a62984209918e6f6f636f68bcc7156a3f9267ec2c694123335bf8dc17c78','09ea10cb9bbce67f0488f202459ad0952759112dadf01de90730caa1c8f4adef');
INSERT INTO blocks VALUES(310221,'cf5263e382afd268e6059b28dc5862285632efe8d36ba218930765e633d48f2d',310221000,NULL,NULL,'6c62946096ecb97d62135b6d1703d318672d47a57d20f0b546cd475b1fbed4be','b75bfebca807f91dd09dc558fb56fbd3134da5a62def6741a704ebe24413c1ed','0a51d20c73718c1440e20b781fa9b2d3f8c8aa99b791a415821d686773074922');
INSERT INTO blocks VALUES(310222,'1519f6ec801bf490282065f5299d631be6553af4b0883df344e7f7e5f49c4993',310222000,NULL,NULL,'0b55f261f42f9ed634acaf1a3fa54a84c8c2c53b0094aea83b8c6c47df41f808','231fc4cb204080945eb3ff9ad99033d4df4446e7cebe459de04fcbc6a47cdb60','2ec57cd75ccbe2bf1961b1b77c61e28de43715406ff8ff772fe57e8190de5ab1');
INSERT INTO blocks VALUES(310223,'af208e2029fa49c19aa4770e582e32e0802d0baac463b00393a7a668fa2ea047',310223000,NULL,NULL,'db80e32a9fa70ac3bda0a68ca6aa70d0d945641c4dc8a974618bcc3bd2323e71','89a41860cb208b53cc7a29db20f623c2f64673fbae2e475baa3a48497cae4001','cc5ca92feeed23fbb0acd3afc7216341058ef337ce9e3205da2d0f5db8ecda38');
INSERT INTO blocks VALUES(310224,'5b57815583a5333b14beb50b4a35aeb108375492ee452feeeeb7c4a96cfd6e4c',310224000,NULL,NULL,'94251828d3eb2547f2ff3466d54dc779403540b3d295bb3a838c2c65dc47cbda','eac9c78456bc1a90218399a3ec706fc238bb9700fe8afffd73aa86d4a573bad0','b657c852131c7219c4c6049ac6041c05be27c7f1c304af6b4c1d58eff8fbf9d1');
INSERT INTO blocks VALUES(310225,'0c2992fc10b2ce8d6d08e018397d366c94231d3a05953e79f2db00605c82e41c',310225000,NULL,NULL,'0fa47a3e0c6c7a10af36dc052316e1a33139a05baec4ece20eb1d7a3b702b6ca','c5221e8e6a8da105cc3c534b78bfc453050d727a953455ed608d83cd271507f3','ca81052c96c5d958e155bd53e3a99155d812908c2556c650ad7ceb59783cd004');
INSERT INTO blocks VALUES(310226,'b3f6cd212aee8c17ae964536852e7a53c69433bef01e212425a5e99ec0b7e1cb',310226000,NULL,NULL,'c825070506d055275302ee19f98f69e7ebd58e4f3d297b1b56026cd81ca6bb71','1a4889dd1ba96138ee5fb2f4ff51d230e004476fd44fc3c42c314564b7556262','8e1e66b8929272f168afa8aa557b60d28b0a0de0a328608a29065abb9c0e1ff7');
INSERT INTO blocks VALUES(310227,'ea8386e130dd4e84669dc8b2ef5f4818e2f5f35403f2dc1696dba072af2bc552',310227000,NULL,NULL,'708f1b03edea6a7ba53b161c91d82c83e7fdaa39e28977cea342eb05395c9fba','fa5cca2715124c9c727b075eb1df2b03b5b389c16c081f4d56102826a18ba396','9073bc1da82c2d1adf205691ab5572e995ca4e19b6ab22e626df4722c76f7a0e');
INSERT INTO blocks VALUES(310228,'8ab465399d5feb5b7933f3e55539a2f53495277dd0780b7bf15f9338560efc7b',310228000,NULL,NULL,'26cd9f3486d1ab73536ad3237ad0b9ac550121ff6e9051d933b4c556394867ee','a2856433d49d2c701803f35426fd0dc94a23082f09b96010e7a9a44e8b53c1c5','e072b130d13ac7f02ebfc93afd898ef368120f7815d0aece2a42af9503036b64');
INSERT INTO blocks VALUES(310229,'d0ccca58f131c8a12ef375dc70951c3aa79c638b4c4d371c7f720c9c784f3297',310229000,NULL,NULL,'c4064516fdd94948922ebe20e834f3cad7fbcc44e8dd99b0c6ff1a80a41dd296','23cb2fe5f344531d3691800fbed2b67be8e1181cd370d183350f2ad58ff745b7','cde27b7d88de4f90ae0fa7fbd1b303429fcb404e2d32af9db04047de3dd72f38');
INSERT INTO blocks VALUES(310230,'f126b9318ad8e2d5812d3703ce083a43e179775615b03bd379dae5db46362f35',310230000,NULL,NULL,'919f82a675cc2747b52d53feda9bc3db70df0a626cfc6db7734282145997424d','cf70d7407525cff185cdc9180b93e827ec5895aadb08805f92444d3431a0187c','aa34b166e110466bd9f933e998f126db0f03a66ff0196cae322431da3b34faee');
INSERT INTO blocks VALUES(310231,'8667a5b933b6a43dab53858e76e4b9f24c3ac83d3f10b97bb20fde902abd4ceb',310231000,NULL,NULL,'b585efdca8b230d5d0477e27e33c46bdae4d4d13a320f72d48553718c82619ab','5f4f6e7c46bc6a14ef8e8885b9bf1bcc22824e6fda1aef52f1415a590e2506e5','901793e015d4e91b8c591e19d3b9a5fdf5b997454d6c955b126ea8503a29a9c0');
INSERT INTO blocks VALUES(310232,'813813cec50fd01b6d28277785f9e0ae81f3f0ca4cdee9c4a4415d3719c294e8',310232000,NULL,NULL,'61ae8d3c6bc169cfdafbd3a16c6b09588e7862c0d967c637bf7a81971f549484','1f8246a33c946e304abfc26abbdb6e7aaac4677a84d18759e4dfa5edbe4fe81a','6cd758df9cbe112e610a616291e39b132287afab3b9118928555149867f90577');
INSERT INTO blocks VALUES(310233,'79a443f726c2a7464817deb2c737a264c10488cac02c001fd1a4d1a76de411d6',310233000,NULL,NULL,'ec03482b84af2c4e39d4ae39cb7eb08f2ff44bbee9ddfbae8526f28f619014c7','bdbf2efdca16a3c3c2db74c2c88826f7ba59eac2a54b9079782ff5f374480af0','039125d34aad5dd51537a7c44f41317ee4541aa74860a9891eef22de9b2ebaf2');
INSERT INTO blocks VALUES(310234,'662e70a85ddc71d3feae92864315e63c2e1be0db715bb5d8432c21a0c14a63cd',310234000,NULL,NULL,'752d6e11a32e9773df8c8caf6c88dc976d1b2ee83bc7fe83ec92a13d906b3fb5','d86f323b1a7b46fe35fc008664016e77988965fdac276f6ba51178d72c8a061a','8ae5ab9cda60fcadfbe182aca9fda0c068eb0756670fb0cedc8a78dfe9719d98');
INSERT INTO blocks VALUES(310235,'66915fa9ef2878c38eaf21c50df95d87669f63b40da7bdf30e3c72c6b1fba38e',310235000,NULL,NULL,'2623f294c75796eb33bf3bd54dd60cd1f388df5e2a2bd611925e0b4b2ae54034','4bf4f8d245651ad2302c2a971e008a0f928ee35429e31b1f77182cb832d2a561','54ad9b94e6f578a260ab535125358364512caa5aa2d4ad8f93dacef3960b51df');
INSERT INTO blocks VALUES(310236,'d47fadd733c145ad1a3f4b00e03016697ad6e83b15bd6a781589a3a574de23e4',310236000,NULL,NULL,'4ab86ec570c3137acb69947799cff3e2b9ed259614988c414579eb2ba78db253','552211dcbcbc5d6234aa86816b091f88f3fc3981f0888e8f9be0a9e32e123a43','7dcb94a1f67bacf1235cac149bf4b019193b80fce95b98fa43a4a0f08c5b0f86');
INSERT INTO blocks VALUES(310237,'2561400b16b93cfbb1eaba0f10dfaa1b06d70d9a4d560639d1bcc7759e012095',310237000,NULL,NULL,'b43837305599670c0351c467d42ee01dd2d4db9739e70956fb1e2c2ec29cae59','1993fd076164c89880b6004bd6303839e37c4ba5ce84397f67e9cc973ca30a79','2275274c4463869f9a55a6b32b73ee3ac56df15ed12c9e77ec1a4472fbbf427e');
INSERT INTO blocks VALUES(310238,'43420903497d2735dc3077f4d4a2227c29e6fc2fa1c8fd5d55e7ba88782d3d55',310238000,NULL,NULL,'d6ac59104a8bb1c9bdeff28e3d79aa227b2e36452bb393b2010c07c49989bb3f','96c3a7379c7b53b863b5cfebb6315970dddd9647a2dc91367b5edc715e2c91fa','2c87fe60e5a38ff7caa54a7948083e4eae3acdb665b4ff4aa09cc7571dc185db');
INSERT INTO blocks VALUES(310239,'065efefe89eadd92ef1d12b092fd891690da79eec79f96b969fbaa9166cd6ef1',310239000,NULL,NULL,'6d324be1402bcecec8636efe1d296abeaf180ca3945cafd4640588abfc2fb622','c1efda95cba13e27cd955420f6c6f5dfb7eecbd368b33889d3cdb3e4a6488399','1493d626186fd610e77f500b3b698fd2dcdc70f2c03bc839f8c641b5ea43dcd5');
INSERT INTO blocks VALUES(310240,'50aac88bb1fa76530134b6826a6cc0d056b0f4c784f86744aae3cfc487eeeb26',310240000,NULL,NULL,'3d9a97e083b433c84bf35926f985fb39392e99eaa987093b5558c6d51c0c3257','93d8fddb1c032488b31ec40d00d701cc5b735fa199b1e170dcc602a54b309e2f','1282ecc742fc08377037ef949c32c2e2909ba48686e5a8302dc35bc3a54cf047');
INSERT INTO blocks VALUES(310241,'792d50a3f8c22ddafe63fa3ba9a0a39dd0e358ba4e2ebcd853ca12941e85bee4',310241000,NULL,NULL,'744238a23bf617d1274d894e2d987ac2bd6554dff98ca81cd198928d918c3a4f','baff46e4030baad92ef195bccf43343af3b50ed95cbb8553128b5d91a270b4a7','94bbcfa064ec1142b2fe31ca044d9ccc5ea757cb15ea9bbeebbf6a0f9c7b555a');
INSERT INTO blocks VALUES(310242,'85dda4f2d80069b72728c9e6af187e79f486254666604137533cbfe216c5ea93',310242000,NULL,NULL,'4a834e1435a3a530c130278639a452b963ed8ad682b7e4ba40bbef3c0884970f','cd697392c1581ecaa925f400f87292aa3dade8d96f505ba4251e83a99484949a','3cfc7ed7f19d16d0d3b0a04db5b9049f42ef64bd58f288ea4f055f398641bcb5');
INSERT INTO blocks VALUES(310243,'a1f51c9370b0c1171b5be282b5b4892000d8e932d5d41963e28e5d55436ba1bd',310243000,NULL,NULL,'3c38948a1daaf2c44679c03c232d867524623c0af54c25c58ab80141629a3411','4b6d687d4954ea417bf2a499aa68e1ae358306810c67ba33f26ac6613d579b4b','c3b6789859f894f7554af21aca9a909e2e8513aaa5ab6890caa843d894ef5014');
INSERT INTO blocks VALUES(310244,'46e98809a8af5158ede4dfaa5949f5be35578712d59a9f4f1de995a6342c58df',310244000,NULL,NULL,'40e163a4b75a64a4373d781d42af8acb0a7357208facab4f670cc80bbc352288','4b6fb1997d0dd405e80c7827ea2ee44f9b63e39826173edaf9f6b52e52b7f421','d42fddd00c31f1a1b151f2bb719c4e1e60d458c85b1e78c9a7a146bf28921061');
INSERT INTO blocks VALUES(310245,'59f634832088aced78462dd164efd7081148062a63fd5b669af422f4fb55b7ae',310245000,NULL,NULL,'a80e1a21f48ebe40e4d1181fb5779c2aebd334a7480455720d8dc91420adc48e','ff807ded2b6d84137ba2bf970b2e98b129a6b04e9315094e1dd44d5a7a00bb5d','04926d7ebab5278deb2d3a844677b4b107e57a8be3a965af38d2dc7956abe92c');
INSERT INTO blocks VALUES(310246,'6f3d690448b1bd04aaf01cd2a8e7016d0618a61088f2b226b442360d02b2e4cd',310246000,NULL,NULL,'b3621966a7f1df8ba2e3150d9dc04e7c58784e05c09fbb47c0f94af6324d42d7','e7f15bbe48b50349709b7eb971b13650a3423aefa6becff8257fce26216578ad','0349e6876114d4913b451596e3be7fdc3a2232779c5c3779bf5c442868306d7b');
INSERT INTO blocks VALUES(310247,'fce808e867645071dc8c198bc9a3757536948b972292f743b1e14d2d8283ed66',310247000,NULL,NULL,'16c29dfb1ada9a941e4d65651e6ba662eaf0d32446390014494811af709daaae','9c37b9716af731244b523f027a90b54c9d1dc82d3108d063bfbcc26682e6b275','4a013d11d3e834df927848c267fe9ba14e2e11cf568aaa5eedfe1fad7b9b2902');
INSERT INTO blocks VALUES(310248,'26c05bbcfef8bcd00d0967e804903d340c337b9d9f3a3e3e5a9773363c3e9275',310248000,NULL,NULL,'46a1d502bb61030ab25f990e1d4776fc91074dd798fc6cbb86061fb5f0dc3279','24cd607abd94c5850a81db7c2a061b0a86d7dfabff22627b29777d15e36b1430','3aea6afe719356e85b5edb93aa2a0ec4364e9477136c5d93a2b1d58516f419cf');
INSERT INTO blocks VALUES(310249,'93f5a32167b07030d75400af321ca5009a2cf9fce0e97ea763b92593b8133617',310249000,NULL,NULL,'bd30958dd32410059f89b5d1ed05dec1fa7d4a1ac5091a9c86d37438c1daaea3','8d1e9c074f74f50cc6e2a4a14d2eb090ad53c043fa6493c78ec7d8d8c64cc959','718a0ef139b2f6581d3b1162e26e36ea803ae4889010e3dc066270dbd876e284');
INSERT INTO blocks VALUES(310250,'4364d780ef6a5e11c1bf2e36374e848dbbd8d041cde763f9a2f3b85f5bb017a2',310250000,NULL,NULL,'593844275ff962ef32ae358957dcd7c4578bc155bfd88cb6ba2cb6db7e4bdb73','9f575bee20703ead3ef944badbdc7db20e4a59d976bec5b38e533a03782deea2','f11b196c86911d64af71f445a9b3730400e00a5c3c7a68b6d1202d45aa4c6444');
INSERT INTO blocks VALUES(310251,'63a3897d988330d59b8876ff13aa9eac968de3807f1800b343bd246571f0dca7',310251000,NULL,NULL,'00790d2383678d2627b583eda36f39bde92883829b93d2628c741cf469cbc337','a820281f4a25259c46a5881c71681f52b06325ca38a310e1d41aeba66444cfa1','deb37739d5d50d13d41888d93cb966db5d146e7de07ba5ff585b7da85b2bcd13');
INSERT INTO blocks VALUES(310252,'768d65dfb67d6b976279cbfcf5927bb082fad08037bc0c72127fab0ebab7bc43',310252000,NULL,NULL,'51238eda52d2c02906de13b4f240b2560234e6733a78658c9c810f3b0da7f1fd','e3516bb49e6ab745c5ab5788d22b00c68c164b82f382021ea3e2ab4cd2c3d383','7b387c69872daffafd3b10951c85b7d535fbdc8424c85e57d479232b2ebc37ed');
INSERT INTO blocks VALUES(310253,'bc167428ff6b39acf39fa56f5ca83db24493d8dd2ada59b02b45f59a176dbe9e',310253000,NULL,NULL,'78bb0b7368a4a11f6f6e82374640dff9a15212a34ab009842aa330557458412e','d3e6559a29b3943a98742c53fd70c0433602d408482d45c138bbec683dbdba41','ca64e6dcd3ad5e29c1dcdd2a34eb6ae2f052f0fbcf63323190412382df35bf33');
INSERT INTO blocks VALUES(310254,'ebda5a4932d24f6cf250ffbb9232913ae47af84d0f0317c12ae6506c05db26e0',310254000,NULL,NULL,'dd78d671bffc09ef422a2e78f8b86c09f9d857e9612b1012a4c1d34e9a904568','347c6d84ed3bf8a45709a894f466470a7ab78137434c3983c845d57bd9ff86c5','0955963e11b446508aa43990d232f4ccc753dba6465c924391bf3d706e8800e2');
INSERT INTO blocks VALUES(310255,'cf36803c1789a98e8524f7bcaff084101d4bc98593ef3c9b9ad1a75d2961f8f4',310255000,NULL,NULL,'5e234216c346a42fa291f82db4a4bbd4067a191c5943bad6d289119e04f1a457','285aed22911f06d67a74f41d65ecd683609378870f7c2e5e52221ca41d1c2bfe','a8b36a74c9c9410d28f8a9820615695a769a6ddd168b1ed14f72dcacef6090b1');
INSERT INTO blocks VALUES(310256,'d0b4cf4e77cbbaee784767f3c75675ab1bf50e733db73fa337aa20edefdd5619',310256000,NULL,NULL,'fa2fd79c10830d09acf216e1d185848b6366f31bf61af06ca5ecf8983083404c','d728b1029381e25d265a095764bf246743fffc429ebe9b0a0702bcac03fc6a75','1ffb7100e3314b6971623e79db56a2fe9fb1d923fd3546f078af4e4cd9b4062a');
INSERT INTO blocks VALUES(310257,'0f42e304acaa582130b496647aa41dcb6b76b5700f7c43dd74b8275c35565f34',310257000,NULL,NULL,'9fbe93ef51bf55fe68323af3338accd41728dfd4cdb1da3d6871d599fb5d27ef','e3656d17557fa0740eb5f0df6c2c5ca47b2e372247d2150bdb142bc3c80757d7','f68766a11febefa0bed651ac30b066e9d8219de4e382262f1db825b4728ed323');
INSERT INTO blocks VALUES(310258,'3a0156dd7512738a0a7adba8eeac1815fac224f49312f75b19a36afb744c579f',310258000,NULL,NULL,'200d17131d04a058c75c7a85b97e42fdc695854ee8d077f7b27fb20ec1412cf8','11332c3705a137c703d33b1ae9b718653f908838dc6665f0494fbd0b381b2c33','9d4a9f59d8dde91386fefbd37dc94195208e51280e5a04bcd925704625dbbc4c');
INSERT INTO blocks VALUES(310259,'e5ed3cdaaf637dd7aa2a7db134253afe716ffdf153e05672df3159b71f8538a9',310259000,NULL,NULL,'912c9422436d2169c0b7ff383b8bc523c5365bc3c1158d86e5ec7987ddcb0401','6071a7d3e081d9716b7ba62a7a831af37a1c95d3f7d409ecca25c93262a46632','981ef61a4061e2e1216dc1db5bb4c5a9f5064d418f92f4c420837c7356713f88');
INSERT INTO blocks VALUES(310260,'8717ddcc837032ad1dc0bb148ddc0f6a561ed0d483b81abb0c493c5c82ec33cd',310260000,NULL,NULL,'931d3214d64e7daff87f5d70ac9e0dc1daebc1afc2334efd0512fdbad18cc4e1','e0e002d54ac62569a6b80117d7238e02ff4b68b28c2a9c9da469d4dfbf98fdf3','ee6843b33d467fec7293f4b4e8343a11db37d3b465e4174d03d3f7cee868ea3d');
INSERT INTO blocks VALUES(310261,'a2a9d8c28ea41df606e81bf99cddb84b593bf5ed1e68743d38d63a7b49a50232',310261000,NULL,NULL,'8fa1c2a7587e206c18066a671a64256e8fa9941c2faea46156cc0ff31a1646e1','143a214f08d4deb72d845aa0828e9bead729e5eac041538cfbd6c3c738ada415','320072a35543fd7762b31d45f6a1ccab543f147fd8c007b7339b0ade945dee99');
INSERT INTO blocks VALUES(310262,'e8ebcee80fbf5afb735db18419a68d61a5ffdde1b3f189e51967155c559ee4ce',310262000,NULL,NULL,'32c294546290e27a2433cf5c90da5c92e846ac95fb82f309c776c7cd9b5edfb1','180e900f5826a7e6cd0b36ae6a88b626cc98254ed4e5e23f21bdfc6b99b28dca','db5852021486988957796c9a0e11c0c35c44b6e6a56a468b6f556196ad0ee0d7');
INSERT INTO blocks VALUES(310263,'f5a2d8d77ac9aac8f0c9218eecbb814e4dd0032ec764f15c11407072e037b3c2',310263000,NULL,NULL,'385ee6105c723c16f6e0f35f5d7bcff7cdd7241aefc05311f6c5a8ee6dc24cd7','d52f1b96d317d524b454cde60a366c8e8ca3d87fb6c4866f45ea2f843c74b546','7da8079b400984cb6fb7c364074b754547d6e0228a8bd858fdebc95eeb38d96a');
INSERT INTO blocks VALUES(310264,'ae968fb818cd631d3e3774d176c24ae6a035de4510b133f0a0dd135dc0ae7416',310264000,NULL,NULL,'6effff8293e1002bbc4459708c08cc1728a8e98632a89fd94553b015eb6094d7','52d53494a1bee4eafe824698f1787fbf2e4ee19e0a8288a105095b2612308c7f','a247b892c165aaf1db6a6c75043673bf0c7b5b48b16a604c5730ef2771e9c829');
INSERT INTO blocks VALUES(310265,'41b50a1dfd10119afd4f288c89aad1257b22471a7d2177facb328157ed6346a1',310265000,NULL,NULL,'ee29f9e1b9dba3251a27b526f53d79d7e98890afe0b6978f33fd1c4f57344d0e','f5f4bb5cfed9cd3bf0d94adbbc6704b2fb430f98dd7943db78cdfb41deb22008','5f73e224cfa7e26cc4746998120d670fffce68a3f10b440efe40cd5379d9d1b0');
INSERT INTO blocks VALUES(310266,'1c7c8fa2dc51e8f3cecd776435e68c10d0da238032ebba29cbd4e18b6c299431',310266000,NULL,NULL,'b6044b3f0a9004c93506d02e75c4782bbe12b2c388efdcacd89c5760df42b557','848d103bfb80f4d13d6182c00c348a3557182d6b0f209bf67888cd82dfefab42','2c64c145aa422684b0553a6ee859a46d185d257ca0a9000c488699f509ddf863');
INSERT INTO blocks VALUES(310267,'c0aa0f7d4b7bb6842bf9f86f1ff7f028831ee7e7e2d7e495cc85623e5ad39199',310267000,NULL,NULL,'fb3f26ce8bd4aac1a02ba09c764d35f9cb56dba75f709f92422b01fdd7a4f49d','eeecc3170c5147efe9bde74b02302713f01fa22260dce87bd8a8e0c2ecb7c9c6','857b84e661b7065c391b336752ffc0b25516fafdbef733916354f7d3dd2ab632');
INSERT INTO blocks VALUES(310268,'b476840cc1ce090f6cf61d31a01807864e0a18dc117d60793d34df4f748189af',310268000,NULL,NULL,'48f730944343ac8abfa3f7a852075232c50c1677dc1237428375b252a0c89afe','32af15fe3d58d304271f2aa0399bc8cb4783e7a5aa74f65501eb59bb972072b8','34bf6305410ef4f6db6ca612331e505ad8d9522fa39531265a81a59bf86cf196');
INSERT INTO blocks VALUES(310269,'37460a2ed5ecbad3303fd73e0d9a0b7ba1ab91b552a022d5f300b4da1b14e21e',310269000,NULL,NULL,'510ad44b41fc8021c0d1172b3dc6b2ced9018ed52f42f3d4956e988943b6e71d','e4d4cbdba02cd2deddb6893ceda25a9cb2565a9e064f0c15388f0b5f38e381c5','948eefc8253e67ca5b3bd4ebfdda6e152a8e12425ee976c7ed263b58f2aead4c');
INSERT INTO blocks VALUES(310270,'a534f448972c42450ad7b7a7b91a084cf1e9ad08863107ef5abc2b2b4997395d',310270000,NULL,NULL,'31fdf38a3c5f9181bfd284d0d751093c1f41945fa8d7032575d934e2e2376fb1','f1a595152a308a87a3fe0696900c2cb783b3229993e580b26c44bd4a14930005','f00ea75d8a0b01773e3956ce2f806513f2c423f189d83a06331af89a124ae333');
INSERT INTO blocks VALUES(310271,'67e6efb2226a2489d4c1d7fd5dd4c38531aca8e3d687062d2274aa5348363b0b',310271000,NULL,NULL,'6195bcbd82a2b229910e6c8bf33f047caaa43e1de6e2eced813bdcce81057bcf','10cee355190a87292e77e710fd487c16e8cbf152396e9c6c267e8876bd76595f','182bafb2cb7cd8c6f28a064987e5f3816dd188fec98fbcdd0e250123ae420a38');
INSERT INTO blocks VALUES(310272,'6015ede3e28e642cbcf60bc8d397d066316935adbce5d27673ea95e8c7b78eea',310272000,NULL,NULL,'1e9f54fa5b4811dbe7ef7855b95cc095c9763e866038c51f80a7593bfe9d2f01','6f12d24e91d40e81fde06fd2e6bebbfcf3c25c56ad7692984679c61e704e2bb9','4abc969c74b7fcb1b2fda29047019e7483d22ca85615f0eeafdea646160ef640');
INSERT INTO blocks VALUES(310273,'625dad04c47f3f1d7f0794fe98d80122c7621284d0c3cf4a110a2e4f2153c96a',310273000,NULL,NULL,'04108d79e2e448ee634fc931495319591d5083e2d5d026145f00b3b1853c97c9','d3f2a48707c85b99ec411cd7edf61a02ecbd94790926658a99abbe3b6046b267','b3cee919ce4590b91ca104799d815bb12b2255abab9b4ebeb433c76f9152c54f');
INSERT INTO blocks VALUES(310274,'925266253df52bed8dc44148f22bbd85648840f83baee19a9c1ab0a4ce8003b6',310274000,NULL,NULL,'4ff9f4036369703d3b80fff33837fba9786c991a3a926619fc8bb7b3adc38a24','fd37f8f34dfa572f725f260604a675b44d06e30b5c82e28285074aea2d262cdb','3afdc294e577bef6bb3b912f4faf84e271d56581b33b4c3418cc043a9823c210');
INSERT INTO blocks VALUES(310275,'85adc228e31fb99c910e291e36e3c6eafdfd7dcaebf5609a6e017269a6c705c9',310275000,NULL,NULL,'c613fccca1450f1868426b7c900452ca09b6c83589d72bf84c8afcc04b1fc0a2','5693c3f5d39ccf0382c77c46ae60761cff173f8405801c41b16490d48daf7fa0','eb9437d0d29a11dfbb7d87e01b1767baa052f8b5139d0bd9833bfc9623f506a1');
INSERT INTO blocks VALUES(310276,'ba172f268e6d1a966075623814c8403796b4eab22ef9885345c7b59ab973cc77',310276000,NULL,NULL,'0964596a5bc5e655abcbf7b7070288223e6f51d324ab56e9335430c3a62b02a8','103fe7ec85a32623864412d7b682cf4df08ed9b71a4470da15abc08d08e5254b','6e9c0a0db9f40bb0e2751c6a4593c122e165b2b984eef43c7fa9ee869829e23f');
INSERT INTO blocks VALUES(310277,'c74bd3d505a05204eb020119b72a291a2684f5a849682632e4f24b73e9524f93',310277000,NULL,NULL,'d8c6969dd1f2609ddaeca194440cf7ed142d896553ad51f6e474d141a402daa5','edc247d310c0961fc94b1c57cefa983725d2dfdea5053d428a862614b79ab426','d408461f8fd1a2e4817fcc43f71572b9d7c8428dcfdc770d089e07db7bae88fd');
INSERT INTO blocks VALUES(310278,'7945512bca68961325e5e1054df4d02ee87a0bc60ac4e1306be3d95479bada05',310278000,NULL,NULL,'71a060d923b31d6031b826bce24c95312acc68cb17a0b8569797f2422dffaf32','8261e870e126b09b40939f4bd71557c822dac91c836c3957d8413be2695ca649','e7e41ddd975d68bc1210a7e507df4088d7197bea941cffdf0be38e61ca0789d3');
INSERT INTO blocks VALUES(310279,'1a9417f9adc7551b82a8c9e1e79c0639476ed9329e0233e7f0d6499618d04b4f',310279000,NULL,NULL,'5491e20db3b734e3bcb83d89fba3d3cdbd23e04a617cb61e344f67f5caf37ed0','909e619efbaa4b134e49a68463c1dd2daa7fcbc13f07bff09c40dc43359cb229','caec931c56a26bda1c461ec69ea20364f97575a419b1856779a790e91718c823');
INSERT INTO blocks VALUES(310280,'bf2195835108e32903e4b57c8dd7e25b4d15dd96b4b000d3dbb62f609f800142',310280000,NULL,NULL,'4dabdaca4e18c632095694a0dce232842e33c5464cac7c9fe1924cbebc270667','93e93a709f9e8b1f22736cf39a9a662595225aeb373b4bce2f1bb52a97ac2ad1','48282853fc7847cbf31c3e5ee5e26f211ad7b0f7c5641dc65f4d325e3d7b709b');
INSERT INTO blocks VALUES(310281,'4499b9f7e17fc1ecc7dc54c0c77e57f3dc2c9ea55593361acbea0e456be8830f',310281000,NULL,NULL,'dad6cea793dc8fd3d8c3ad04d054467e73b81603392729987c593f8ca67c3be2','f45508781b6ab0c1c067dd95521cf3879dfca8dbea9f582abcb9fce6c7661e21','be15485e9099a12962ea02d00f726c2a5dbbc1f3a8f72441f944be4ee9882ace');
INSERT INTO blocks VALUES(310282,'51a29336aa32e5b121b40d4eba0beb0fd337c9f622dacb50372990e5f5134e6f',310282000,NULL,NULL,'42b1f66568eab34aa3944b0eeebea5296d7475cc0748ae4926ddbab091de7903','a7743d87487a0fb19b03523fce2435e9ce7b025e5a6fd31dcb0f3b491e3ec235','bebfade13a72c7cced49516b3ef5d23432339f4ff5a7bd9437288faea474d8ca');
INSERT INTO blocks VALUES(310283,'df8565428e67e93a62147b440477386758da778364deb9fd0c81496e0321cf49',310283000,NULL,NULL,'edfae1059d89469e4d8c9285bafe05968e62c35504ce5d5f09bca4bd8ac0b698','ba30d31fc21d20c2a34246c2d22faa127f628adcc59f22830fdd4e4b8e79894c','adb0a85ca9d7eb15a94c8bda1227cbe6b561a89c54f1629d3f7c84dd1721f565');
INSERT INTO blocks VALUES(310284,'f9d05d83d3fa7bb3f3c79b8c554301d20f12fbb953f82616ac4aad6e6cc0abe7',310284000,NULL,NULL,'2b9d8a4322352981f7033af84e111c94511ac9b87d7d2599cdf5f2814b45a42a','3001da76eb43e4fe4374363f80e36d6f71771026f67484256d75e10a1611e72a','448f67b07e255d20c0c37e043f6d401f82458688a3fa26b547c06417643e719d');
INSERT INTO blocks VALUES(310285,'8cef48dbc69cd0a07a5acd4f4190aa199ebce996c47e24ecc44f17de5e3c285a',310285000,NULL,NULL,'63d6307a1f8d09526578c4b1776e51b40cfb5ad78d01dedd3e23d99f1efeda19','fa733681884d9acfe7335814e1052a2816a5a7555dd6c7fc5ce793a7bb9c5f7e','0207ee6bf093a86833d8bca3dd39e08f8c3887db7d12378ac5e8a23d86198cad');
INSERT INTO blocks VALUES(310286,'d4e01fb028cc6f37497f2231ebf6c00125b12e5353e65bdbf5b2ce40691d47d0',310286000,NULL,NULL,'a42dda85ec8530a307a1f9e7048d4384b229c2637305eee0368ab02957f5b31d','2994ed9066fe2beb7fb54695110ba7af3d4e07b5dfcbbc3e47b904d6d2ba1687','1457e14139e39788ccdd0d36db5180835c213784ea2285ffe0ac2c44668d98a5');
INSERT INTO blocks VALUES(310287,'a78514aa15a5096e4d4af3755e090390727cfa628168f1d35e8ac1d179fb51f4',310287000,NULL,NULL,'96bdbe4268d82b3b82d776eab32019393f5de5ec5ea2302c0c2a9aaa068fc2a5','188591960258569a9a48f065ce671c94c7c49d92380ffaf34f46d94bec610224','57d43dbc70100d0e626fdaf4c29f8c8acebec73a9ece1108c20e7317c169ef9d');
INSERT INTO blocks VALUES(310288,'2a5c5b3406a944a9ae2615f97064de9af5da07b0258d58c1d6949e95501249e7',310288000,NULL,NULL,'0c96ab72568c907e27db628c30825012ea3ec633d3debe3256dbf4d3c95f81c5','df8c7aaf5fce92383ec51693fd8c1f0d0777d2e13ab52bbc8f96ac6f9f93b403','11c842353627ac9c2aa8c660fe29d5b1fcaceaff52d85a3cd22fa50e57ae7d72');
INSERT INTO blocks VALUES(310289,'dda3dc28762969f5b068768d52ddf73f04674ffeddb1cc4f6a684961ecca8f75',310289000,NULL,NULL,'921af39c1d31264ba86b6e6ca54b8dbf40bfbee574c1278d78d686b20159f99c','b586b0a560c7f08105161d4f6a12aa77324756df5ba1b75d0fd2dd586e8081ea','4396eb84eb2d3897e2dbc809db5f6b28f52e7676012f3201900f3bd1db6e5f66');
INSERT INTO blocks VALUES(310290,'fe962fe98ce9f3ee1ed1e71dbffce93735d8004e7a9b95804fb456f18501a370',310290000,NULL,NULL,'743e6499fe6b1b82914457c8bc49c54abc0dbae277eccc0b7fcc203e86f89f6e','310fa81069fe0876486244f72df6ac477adb61a99abc18a8f2cd5341a2cf3936','edbfa7453d28c9bec9d96e586417ccd25eafa113836b07f5bdb4034bbbf3e85a');
INSERT INTO blocks VALUES(310291,'1eeb72097fd0bce4c2377160926b25bf8166dfd6e99402570bf506e153e25aa2',310291000,NULL,NULL,'194402bf041424fec8b63bd9b5851c5b0d04958b5851bc9fbcbcd9e683079e7a','550292d8b84723925cb1ca2a878a9bc0ede54ea407ac9ee55ec79a82edbf4d07','7f8d9826c71094dc265cf7e978b7d679b495590c158bcab173c611878208501d');
INSERT INTO blocks VALUES(310292,'9c87d12effe7e07dcaf3f71074c0a4f9f8a23c2ed49bf2634dc83e286ba3131d',310292000,NULL,NULL,'c8b7f8f3ef06df7a9c7eff346d2a9f0d1f1377c064c3b3c3bc2aebc845caee95','9849ec5de020a99b6de9ae1ec6229be89a2d1570ff12d3fed8362d439735b061','d84894e5fb935eab5eb07228594701b6828c53a30bbaaeccb406839783e53622');
INSERT INTO blocks VALUES(310293,'bc18127444c7aebf0cdc5d9d30a3108b25dd3f29bf28d904176c986fa5433712',310293000,NULL,NULL,'0c9c8a8558e14645d818621e4a97c66cc9bc67023141c5bd00830436e5760fba','16ec140d5ea486353a3dfd90db5b8aa267b2afdf4942efa4fa3cfd55f992cc87','7a7385791ee9d68ede3b0ec08757c15235e33f53742385e1530db1b97d1b6c61');
INSERT INTO blocks VALUES(310294,'4d6ee08b06c8a11b88877b941282dc679e83712880591213fb51c2bf1838cd4d',310294000,NULL,NULL,'1cb04936a9ee72f465e4d6d4fd6f2ac99cacd74a510d74f017320dc7061c4b02','313bac8361352d84d819af1e8f0d829b24cf4597d465387c7cbb4ab47885815f','8410881052f81829882edbb468b115a519796942189ebb52ad5384e61dc74123');
INSERT INTO blocks VALUES(310295,'66b8b169b98858de4ceefcb4cbf3a89383e72180a86aeb2694d4f3467a654a53',310295000,NULL,NULL,'d7751796cf10b5a92ed9470cab6dc1d0e2a1853fd457fd913e58f5fd38771d2e','ae2844c1ac75c081a6a5a4e0cb376548db82fbedbce5862d2354d86d82f3dd68','326a9b643b60e41b1ed8cdc4a10488c75746a0ad557f8c31bf3e54d7739dff4f');
INSERT INTO blocks VALUES(310296,'75ceb8b7377c650147612384601cf512e27db7b70503d816b392b941531b5916',310296000,NULL,NULL,'e23e480658f3c900b36af8fde0bd00255b960ba1b65dbce45a773b4ae813ebcf','049ce899cc14dcea3fdd9db0fe83e9269a4decbc175aed7798f7ebfe8ff9289d','a6500ba4ed851478862993f4e6f4d04b5e21b86dd1d3ed06676a1c01a5d8a5f6');
INSERT INTO blocks VALUES(310297,'d8ccb0c27b1ee885d882ab6314a294b2fb13068b877e35539a51caa46171b650',310297000,NULL,NULL,'802b11ed2d95f872d2fa557725a43b15fde5e7b550a3dbf229881090866ee577','00b83b4cdc9e6d3d1619df731f784a95e5eaf9e0cd5d1deb3b4cc453690b204f','fafdfa2f11e7bfd8a33045702d5951005f7cb2bb0c6602806af8ba94701be307');
INSERT INTO blocks VALUES(310298,'8ca08f7c45e9de5dfc053183c3ee5fadfb1a85c9e5ca2570e2480ef05175547a',310298000,NULL,NULL,'d8d94f75f311d053b6cb52ef8ae295423c99f533351d78145614b4fbc69f6742','7011ac3982db11d076a9bd725d16463a88fb5f65aba1cd88b02689533afb2a12','a939e13315bd36c15014d9bbd91ff42b1d885aee63beed3ce7fd6522980d8c3c');
INSERT INTO blocks VALUES(310299,'a1cdac6a49a5b71bf5802df800a97310bbf964d53e6464563e5490a0b6fef5e9',310299000,NULL,NULL,'841a917e1aa259167a05c911d705a07bdcf980c9c5e831999923793a03a1d46c','9b2696ba22575fb01ae41a5318a43c0de01ec724242004c8dea0f27d14d084cc','dda365dd697b4cc61388ca3ee678851e720bb0558955ad1e34f6065e806d0628');
INSERT INTO blocks VALUES(310300,'395b0b4d289c02416af743d28fb7516486dea87844309ebef2663dc21b76dcb2',310300000,NULL,NULL,'3d74164b7ec33cbc0b3e372b21e025c79b35e99784a2d8ae359f2005972bd5d3','f239f9323dab453b855993576b6f58f5e4c95c9effc2c65de4c154cd089319d4','5d99140bc3103ecbbea88861e8408df3dc42c7eb99623f16457d353c61fa0cd9');
INSERT INTO blocks VALUES(310301,'52f13163068f40428b55ccb8496653d0e63e3217ce1dbea8deda8407b7810e8a',310301000,NULL,NULL,'1adacb3d5e4701b0f1bc158dd5164dd770852c5520e850d6d9b9e63fd1e7c37c','4b163eb8ce1b2b5e615f919f46cb69fdbcc9efe62df00cf831503d49fe9c5133','1f9a5bc3399c4debbbc38e2574bfde389482d693022bf4269c4e0902cec682db');
INSERT INTO blocks VALUES(310302,'ca03ebc1453dbb1b52c8cc1bc6b343d76ef4c1eaac321a0837c6028384b8d5aa',310302000,NULL,NULL,'587b7eb8bff455f2848380f870d20398ebae76e6a12acaafbac6e955d3c3380d','5682a78c67fdb4a249b2db569fae33cfb2d4ada49b4d0e76483ca33d70e43023','a4625d9b638a4dd7d18051657dec2f81609344d3cfa7ec3861a6cd74df0c20fb');
INSERT INTO blocks VALUES(310303,'d4e6600c553f0f1e3c3af36dd9573352a25033920d7b1e9912e7daae3058dcca',310303000,NULL,NULL,'27120588c29741bbb4a802829d2b35d8b8b17e7b5cb49842faa0fefe05e99071','8f83fca14209c4df5852e4b0b4af893d5d5337272cd056095580a117a765bb43','57dc7f22699e69c291a7bf382e5e7456ccc9509629156caad2ca1a375c5c39aa');
INSERT INTO blocks VALUES(310304,'b698b0c6cb64ca397b3616ce0c4297ca94b20a5332dcc2e2b85d43f5b69a4f1c',310304000,NULL,NULL,'4a1d23a03c47c00574d3423f328c48d794ceadd2655cede15c5901d830c87589','e29b9d18c6d67b099589dabe1f0ef1123b086676077402f0d9fc1f59b087fa2c','fbd001ce2351830ecf1797b97a3d55828bb130839513e42bba1c59159d62b6e3');
INSERT INTO blocks VALUES(310305,'cfba0521675f1e08aef4ecdbc2848fe031e47f8b41014bcd4b5934c1aa483c5b',310305000,NULL,NULL,'7aac15d414e5ebcfaf63a9ac3bc05d2dde5ffc610d9bafc8ff2a210020f6d5ef','a0f65f46e49355829160907330d69c021e3c340f528fb601c229a89cab136648','83ed8482d9ad518a939c49d7f987b1c47788f68edfd58b312d80e53f9c2285e1');
INSERT INTO blocks VALUES(310306,'a88a07c577a6f2f137f686036411a866cae27ff8af4e1dfb8290606780ec722a',310306000,NULL,NULL,'bc47cbbb42618bea636c422d824748d97d5bd4b4b75ab44d80ebeaa9b5fb309a','42aa806cdc4fe31e368df09aa43818f8211b3784c832890d967c145734cdc6bc','51d4622ed0398172cbc08c80fd9240be3e6ec25f3975e50f401b94778c44f256');
INSERT INTO blocks VALUES(310307,'bc5ccf771903eb94e336daf54b134459e1f9dd4465dec9eaa66a8ee0e76d426c',310307000,NULL,NULL,'02440bc84b5e8e1733d29e4524381c8ba25e38727d5f70d6246627761660f329','d6a84e45192d51c7a0403b5facf40bd4a8e943d66668edbf74bc7b3dd9b4b64b','6a0b53a1a195140fe8ac6e4afca65a965e30b228b8355edfdb8e30d4e381874b');
INSERT INTO blocks VALUES(310308,'2291ffd9650760ff861660a70403252d078c677bb037a38e9d4a506b10ee2a30',310308000,NULL,NULL,'44c5b13272847e19dd2cacf9a506145f9a1ac5792916eb98204bdb6772e7ab68','848156d904d2bcf73766f568d763e2a23410f945b75bf393a6e2cf4a99e9cfff','7cca63000797859925d03d473ead4455628d7b066bb2a23eda99f84dbfa6141c');
INSERT INTO blocks VALUES(310309,'ca3ca8819aa3e5fc4238d80e5f06f74ca0c0980adbbf5e2be0076243e7731737',310309000,NULL,NULL,'25ea894e3bb4f88ef9c8f86156a3980c0d638c20c69e8bc6365f913d1454c14b','c2067a62113da38c5591b03ea086c2e9ede0c27decf270cc9f868af412127964','fd17c92ecaa1f7af157fa367c1718d7e1f47f7d849aec5044528304fbb5c8689');
INSERT INTO blocks VALUES(310310,'07cd7252e3e172168e33a1265b396c3708ae43b761d02448add81e476b1bcb2c',310310000,NULL,NULL,'94d123e1ef62d5063e363065d8d44f9ab7f22c59eaa35a2ce38177c7b7a8eea5','7adc782a56e980d6fef0f2da605c62df89e29f38ed2ac1279015277ed7e7c77e','992b1f2c272242a69e456ad46c960380d9afa579813da11c815244422ed4a12e');
INSERT INTO blocks VALUES(310311,'2842937eabfdd890e3f233d11c030bed6144b884d3a9029cd2252126221caf36',310311000,NULL,NULL,'3aa3b3f04dfcb85db112ec7f540a7f54b56ad7f749df3d0d1dc738ce25bc5728','f39818195893cb7fc5694b1d28dfdc21d34770b3b4b8403097a77d6e374689c7','7d0cd3e1b745cd670a4ee689b47e5a1adc4002f66248edb7ef485347a976bf7a');
INSERT INTO blocks VALUES(310312,'8168511cdfdc0018672bf22f3c6808af709430dd0757609abe10fcd0c3aabfd7',310312000,NULL,NULL,'44991a8afb1cb85a381557bd653b1015160842edb02266164460559a4ea9e529','581f730755209cdb0f67e28fb33a9ce8274356ec9082253b294dea5f1743252f','c608669568c2dd33ca1304b95c11d6e163a4cb73f207bca35db95b7ef9b462c3');
INSERT INTO blocks VALUES(310313,'7c1b734c019c4f3e27e8d5cbee28e64aa6c66bb041d2a450e03537e3fac8e7e5',310313000,NULL,NULL,'d7b21c8000a09ce9f26037c43073e2d7a596c68c954c5416d22454d3e89c8b70','35e22f7874e4d539b3031d9e2bb48d40223807bd56d0d077df5933796f1d9a29','4cbd7b39940d43cfc9812c72071273cb35c2f25afe4f354239ccbc3f6a796985');
INSERT INTO blocks VALUES(310314,'1ce78314eee22e87ccae74ff129b1803115a953426a5b807f2c55fb10fb63dc8',310314000,NULL,NULL,'5c1ca6e4f014f1fa35870558ad52dd5252e6b54a02919546a03d4e6498370d44','5cb3e99a30f66906069fa852580f792b6e86ae4ea63208be3ee033285c30b687','54073ef4e5e40ec0e706632d77720e48cc6589590b2a2af177e5da0d1607ed03');
INSERT INTO blocks VALUES(310315,'bd356b1bce263f7933fb4b64cf8298d2f085ca1480975d6346a8f5dab0db72cb',310315000,NULL,NULL,'ba3b14271b4899094ad98e0535979eed35dc2aad617d7996155251ddcb4d0e4e','8b143251aa16118d99b6ed606aaa2c03f012022137418d2b3cdebce4891ff0ca','209f6bc43482da94c42c2984d1d4bb2c461db6afbc8c11381d9aedec2f125db7');
INSERT INTO blocks VALUES(310316,'ea9e5e747996c8d8741877afdcf296413126e2b45c693f3abdb602a5dae3fa44',310316000,NULL,NULL,'b33797e21d7654e1ca5cc08bca4a6bda9ae95f23094d42b789530b6cbd584b4a','281d9c4a1f7ecc088e9c736c6d0d5154eb36e0d2496bde4d856fecbfe539ef17','a808e19882c3fa0b4533c9894217708f06a4543db4a33a32d02287c40bc48d6c');
INSERT INTO blocks VALUES(310317,'aa8a533edd243f1484917951e45f0b7681446747cebcc54d43c78eda68134d63',310317000,NULL,NULL,'497a601664ea59cf1929096b129613ce3bbedc271ecfb33b364558e231d48649','7286531aa97637c5b40e78b295f744bfe080d8b19f750915289e67ffc24d2631','989bed3cf0a294e8981f8054552a20adff284f7b5214fc88f993fbe7684ac515');
INSERT INTO blocks VALUES(310318,'c1be6c211fbad07a10b96ac7e6850a90c43ba2a38e05d53225d913cc2cf60b03',310318000,NULL,NULL,'760dabe4684acb6c8638c56ee1387e4d6710f99adcae4cd9721da0c7decfe2bb','d7f566c40c660ec6827955fb8fd850592309f34a68af7e598283ce92bd2f5ba2','60d0aac29e131b5441e3cfa908d1775b437f89e6908be645bcf781b3f48989f6');
INSERT INTO blocks VALUES(310319,'f7fc6204a576c37295d0c65aac3d8202db94b6a4fa879fff63510d470dcefa71',310319000,NULL,NULL,'e43bbfd0e56daf582c84a2286079fbd8aa661c149cc3a14d40d139a45fd7a19c','38e8e10aecb6ddfdbef44c7a55bdd0b3086caffb10ab102c576b56502579c001','3ec45c5919be1b10c526105bf95a23b3b3bf7c0c9316044bd4a5b6d527049262');
INSERT INTO blocks VALUES(310320,'fd34ebe6ba298ba423d860a62c566c05372521438150e8341c430116824e7e0b',310320000,NULL,NULL,'7f95ee77cee4a1c0de27a0e69d909d0c2cb8d5a5d76d6d92e8bfac58c3f148bf','f1fa00adfccf971d830bc750d4f3def0a3764cc1cc3c443b777a0c87e06edd3c','c5475d5edf51aad3e7a9744cf9809c94a9f62f2f473c323fd5163ce6487b2300');
INSERT INTO blocks VALUES(310321,'f74be89e9ceb0779f3c7f97c34fb97cd7c51942244cbc2018d17a3f423dd3ae5',310321000,NULL,NULL,'9e2bc1247466f28c92ff287e9d5825f81e6b8b4063c70db23aacfde92f627417','c06a18281701c703f657e59149b381726815cb316be2db62923e0c8753155667','882ccab46960ec2d557d35d81e623ec26024acfe79275c093e43ea123f6213b1');
INSERT INTO blocks VALUES(310322,'ce0b1afb355e6fd897e74b556a9441f202e3f2b524d1d88bc54e18f860b57668',310322000,NULL,NULL,'bca22d67b45b3bca60a0e4e1009d4ba86bbba96b0e37455e094eaf933f7d892d','80fa56faef8fe06c9fde71f7d92889f660f8047e67dad0473a805f9d6e9f40a3','56d049d3f33a90daf72932cd76ef95fd64fe9cfeeda97b264b1c4ccf7e16772b');
INSERT INTO blocks VALUES(310323,'df82040c0cbd905e7991a88786090b93606168a7248c8b099d6b9c166c7e80fd',310323000,NULL,NULL,'aa76c1d43196055cc6ae91e0afdb1105db0e5ea8b9f8d20298878900c07e8ec7','04cb2857e00cd3e7b29ddfe3fa6b7a1b20c5e6aaacdeb5e1832c90d03d9197a1','16b754b7353f7fc56e13cb6855153d6b56a14972ad63f5851c20d14125874a4f');
INSERT INTO blocks VALUES(310324,'367d0ac107cbc7f93857d79e6fa96d47b1c98f88b3fdda97c51f9163e2366826',310324000,NULL,NULL,'dbdc8005f1f6c45dce8e0450740c37f2d21e6f325e1c2279bf78094aa1098ebe','e847945e834fb8160630dbb474f862383f0dc842591129f48b2dc4667ddb3140','55b3c735c1ef821fa52e564242dbc62b71969586caad8c084e27c12e6ba39cc5');
INSERT INTO blocks VALUES(310325,'60d50997f57a876b2f9291e1ae19c776df95b2e46c14fe6574fb0e4ce8021eac',310325000,NULL,NULL,'021f052a73f177bce172f220d3a1ab9aea5f325e32b3d2635905a0c95b4c6efa','ef454deb45729804987d08003d5b017819a718cad003f1cca5880da1d358f293','e139091fee8b0f6b9a32747bb2c4c98fea37aa44c661310a8a56fc5400cdbc18');
INSERT INTO blocks VALUES(310326,'d6f210a1617e1a8eb819fc0e9ef06bd135e15ae65af407e7413f0901f5996573',310326000,NULL,NULL,'f90a81326133a303229276b553796e2f9d186f98ce897f759cadb19e6728090f','0ce171d63174c312c8e0f5ead35ec68288242f1ca905eebaec31477b370aa3ff','5ed5e8fa33f4c359851718ba3e7a79f726ad66337fae7c09d8b6e6a2f1178744');
INSERT INTO blocks VALUES(310327,'9fa4076881b482d234c2085a93526b057ead3c73a6e73c1ed1cdee1a59af8adc',310327000,NULL,NULL,'86aaa9593f09bb338fa1b0878f2522db223bf8262e491ae0b8e707f9796c5e05','0d8104b205af81cfacf83187fc645d360405e89564a8a3bf6eae012a379ae3fe','99fdeb4ba4a3bf6bdbd3afed9477f4cdea42f03ef7d0b0459ab7a25e8dd13c4b');
INSERT INTO blocks VALUES(310328,'c7ffd388714d8d0fc77e92d05145e6845c72e6bfd32aeb61845515eca2fa2daf',310328000,NULL,NULL,'f4b59e29f0c89f18d045a800d098abfffbc9ad7ff200eeb47133605eb1a72b68','9e6eb37449242996420c113fe764a88dfa7fca3df2014ad4ace889e54ee3e6d3','15ed1b620692c12d70ee828cf49f0633415f15d53e5ed8e7305ff05471a0af8f');
INSERT INTO blocks VALUES(310329,'67fb2e77f8d77924c877a58c1af13e1e16b9df425340ed30e9816a9553fd5a30',310329000,NULL,NULL,'dbd3510938ee45e99d8b7cac8b0d3e8a275dfc6b1c8e741e0320e4b2e4947fe5','33737e371edd4c752c9518e8ea270e85868f9551515b7917b633e08824c4cfc6','47b02a5c2e41d317845e0a7198006dbdd9ce1591058479e443c95480a363916e');
INSERT INTO blocks VALUES(310330,'b62c222ad5a41084eb4d779e36f635c922ff8fe275df41a9259f9a54b9adcc0c',310330000,NULL,NULL,'79f20326c0e49ea2b3c81e8d382754f311e3744b22b80140dc7ceed4da1fe09d','15b4db6749ceb350893028b708104f33592f9caf0f664a6187f626c880e03829','beb60d80c3756fed497e9da6c6b080b9170fb265dcaea5064538628ce157951f');
INSERT INTO blocks VALUES(310331,'52fb4d803a141f02b12a603244801e2e555a2dffb13a76c93f9ce13f9cf9b21e',310331000,NULL,NULL,'41d2d69965cde1e0f97b7c14c33acbad592a6bd4882eed6aeb57127ed4ddb69d','7f7abe58da81e3574c9d6844cbce864dd493d240a02b2229c48de1926e9e783d','329f0c7b6cf532074f087590acbea8ea6f34959de63a02dc6ba53165a96d1f2f');
INSERT INTO blocks VALUES(310332,'201086b0aab856c8b9c7b57d40762e907746fea722dbed8efb518f4bfd0dfdf2',310332000,NULL,NULL,'3def70343846a9776559707fb61437a53ffc5dac917f81ee3a12445ce69a9885','c830a2692d0831692739a435455af5cf898ce1cdf6b3ae8dad083ac8099a39e6','d2687455d2873bb055770d3930285073d99a568aa6aefe92519a8b52bff6b311');
INSERT INTO blocks VALUES(310333,'b7476114e72d4a38d0bebb0b388444619c6f1b62f97b598fed2e1ec7cd08ee82',310333000,NULL,NULL,'cc02e3e7327ddd3c192bdea2ee76728c0b0cb031fe130d5713c1ec9546ae5946','2aacc81aedfbfbe1e66cc28e00296366860127b42ba11edbff1a7ae056916d1c','7bd5c9ca4093c1a508364cca13888add7cc8a536c04ccf85151bfdf5a744bc18');
INSERT INTO blocks VALUES(310334,'a39eb839c62b127287ea01dd087b2fc3ad59107ef012decae298e40c1dec52cd',310334000,NULL,NULL,'8a449270a6bfb33206c1d7eb02ca363cb405118e52359a1ed015c5660fcec8a8','67a6f929bb76e82581a07d0a47eb8935bc8c2a7a19f199cf6d339d6451223947','7841ce5a1601d1a34d942b3aeedbc3c6371164479cb7e9ed4131784788478ac8');
INSERT INTO blocks VALUES(310335,'23bd6092da66032357b13b95206e6527a8d22e6637a097d696d7a96c8858cc89',310335000,NULL,NULL,'942c5c5ff6c24ce2bb18e065b24c39d1906ec381bba55cb9d905376ac87d2bdb','c9e7930a347e891fb2e9810e98524660f8e4e4ae6a38c05f11f0b3b5aa7d193a','26de767160798459fb321229cc0d3c8690db468728a8f52ecef65028c427f84a');
INSERT INTO blocks VALUES(310336,'ec4b8d0968dbae28789be96ffa5a7e27c3846064683acd7c3eb86f1f0cc58199',310336000,NULL,NULL,'68a947f2ae4507e143c9ac84826318d4b630845f81548490f7b0c00a2330e990','584e2bd8e4d44fa8848bbcfe2c431f46704e532634e7e64fa0fd256fc3b92efe','e568371e3f82f15059d8c9ffb5161bd9e1d690389ebd44254aa1e4003a97b155');
INSERT INTO blocks VALUES(310337,'055247d24ba9860eb2eadf9ec7ea966b86794a0e3727e6ffbcba0af38f2bc34a',310337000,NULL,NULL,'4e1ca24a54f45b4cdc60be1348b3d5b81ee8acbd7c4f8cda86b8d2746694f17f','85bd497bc8202a48cfe90b8bbad4cb1db762393a8e237c4f26f3f8ead25647df','67b3cdba22364cfbf56860c42bbb3eb29349801a3e7ff8f7a1645d226a5af732');
INSERT INTO blocks VALUES(310338,'97944272a7e86b716c6587d0da0d2094b6f7e29714daa00fec8677205a049bcd',310338000,NULL,NULL,'dafafbcf8cbefadc5596ba8b52bc6212f02f19de109f69dc412c2dbc569d5e8c','c0be7aa8f096df79c42cc902a86cc7ce356439c878d2d543171cbf361161f586','757dcb7fd7dd24a0f82f11bdbc29347002968bbd30ec7e2f54b11b284ce7cea8');
INSERT INTO blocks VALUES(310339,'99d59ea38842e00c8ba156276582ff67c5fc8c3d3c6929246623d8f51239a052',310339000,NULL,NULL,'e28e2a9c9f9476d0c23bba3c6d2e68f671aa20adf72199188a9c82160b0cbadb','1f577b621b2373883e5d8977ccf87519642fc7169ac9b3199611ea5472f28af4','0bcf2e61e37a0872f362ea9496825999d88986197c3a2d731b7deecd3c2b412a');
INSERT INTO blocks VALUES(310340,'f7a193f14949aaae1167aebf7a6814c44712d2b19f6bf802e72be5f97dd7f5a0',310340000,NULL,NULL,'7171d5b8a9f07885a5fb6059e4ca31dc00863ebebcfc82836ed2af0deb39a48e','d981fc5f715b6d81dd53571d9d81443a96994084d5423921b505cf0010e85e0c','31ad6308cb985124a6cb4e214aeafd7df00fc935aecfae63f912dc83364acf4e');
INSERT INTO blocks VALUES(310341,'6c468431e0169b7df175afd661bc21a66f6b4353160f7a6c9df513a6b1788a7f',310341000,NULL,NULL,'d350161fb4026c48acc21d9e66a2def972fbe543c46381a353de2d2fd8b6bcd4','1f4aa12865e42fac9d568aaf5482baeb8084d87e441b69000f2ebf504ef98f46','56542f60deb2a96798f818a4d5eb7d886dcb927f324771731ce5868b1223c392');
INSERT INTO blocks VALUES(310342,'48669c2cb8e6bf2ca7f8e4846816d35396cbc88c349a8d1318ded0598a30edf7',310342000,NULL,NULL,'6acbdd85b382016a93936385edf88ea1114706f2d326ca373ad508b653e5fd28','dac61cdab5820e00c7b0a3e77ba34f5b46dfcbb6b6741dbb8f7e9ab2764253a7','6d84c4343d8aa4fe7621932b8ef3c0f088a9b6f1931e0e30baaf97bd6a2e0590');
INSERT INTO blocks VALUES(310343,'41a1030c13ae11f5565e0045c73d15edc583a1ff6f3a8f5eac94ffcfaf759e11',310343000,NULL,NULL,'68e26f1c578576a74ba6b63cda11695176b48c7a919beaab5496db142b247cab','a249e8a58099cb771a66645d67003009e17f7b985b44b432bfb61f54352909ae','e1daa0fd34683b6996fe91191d1d64529666ec5432fa6d468af9980057795a06');
INSERT INTO blocks VALUES(310344,'97b74842207c7cd27160b23d74d7deb603882e4e5e61e2899c96a39b079b3977',310344000,NULL,NULL,'2531f6b71ce2390aeeab26cbc8095aec7a76dc46db73149868d8a6209133780f','8310f0b38d444e17be4bbd67661169e27f45bd153f18fe04182769459adbde27','3cddf5cd83de775d49f41dd46913c87f527811e055f00b9b07049823fd0f5a14');
INSERT INTO blocks VALUES(310345,'0bda7b13d1bc2ba4c3c72e0f27157067677595264d6430038f0b227118de8c65',310345000,NULL,NULL,'ecf8e55d01bec5ec8fc302451bc3e0d3a76d5d413ce354ed43e36eeef274cc14','d472788741d00082d8060ef55d735f86f2bbd44a4534355285442a32b00b64ef','83d18a93680eb2586cff97a290aac3cc5558d52546a752bf2ace77d1feb83941');
INSERT INTO blocks VALUES(310346,'0635503844de474dd694ecbcfb93e578268f77a80230a29986dfa7eeade15b16',310346000,NULL,NULL,'2149f9f24dd41e092555f29cf7ae1131cc53462e9f24de15720c0fd1a8a874f2','511e791e86c88815dd667ee4cb16dc382930970d6536d27673214c1f8352fbcf','a1881e85d886eb3d7b98434a5beeb5491eb76e77ea68ce755708b42b0f01df76');
INSERT INTO blocks VALUES(310347,'f3f6b7e7a27c8da4318f9f2f694f37aaa9255bbdad260cb46f319a4755a1a84d',310347000,NULL,NULL,'f19aa2d83d53f128264cf432c9c313d89d2d91f09af8f2365ffc4bb0911abc5c','3f7fec3cb6550da1cbcf6b22b3dfda157ae4adf3c1e5b934bc2c57575a017f41','14f4ba619c48b9b081bba5bbd5c4176497a4b7773fe3e7f79920d89b8317d602');
INSERT INTO blocks VALUES(310348,'c912af0d57982701bcda4293ad1ff3456299fd9e4a1da939d8d94bcb86634412',310348000,NULL,NULL,'5ac2d42a9f7cbe6fe7ff53879d4ac316e93c00b005543c1575c3a72471765118','7f2a31aca18c00c4dadf3d1022acad179316fee3cb23477420ec208f9d19e449','14da4197b76655f608665f4f732eb73de4ddd5e685b73cfa4208b5af60aeef29');
INSERT INTO blocks VALUES(310349,'ca911c788add2e16726f4e194137f595823092482e48ff8dd3bdbe56c203523c',310349000,NULL,NULL,'ea77bb132fcbdef8652894fc3c80a862ac4fb0daaa444213b61388285904bed8','d1426d3c1c8bd7dc187e21866c153aaba4e73e3e2cc58f62389a117041909695','b23f773bfbbcc961726564eb0181a877d32da2aec01f4c74fc50c0447f1ed491');
INSERT INTO blocks VALUES(310350,'c20d54368c4e558c44e2fbaa0765d3aecc8c9f01d456e3ff219508b5d06bd69d',310350000,NULL,NULL,'af48f18af140a67943df6ce781e858631a4e7841c7f44facb644c93641145237','c2533cc27feaa06079123973b4de5c8ceddb11aed9a705d2dfe831b9200a00d1','984147f6f89529c135b0d7f5acb65c437d6d3e124cf8cb26eb00352c6b5e0b19');
INSERT INTO blocks VALUES(310351,'656bd69a59329dbea94b8b22cfdaaec8de9ab50204868f006494d78e7f88e26f',310351000,NULL,NULL,'4ae931b01a138a0dd8e4d6479faac7961fe3148fd048c4daaa6720f907cbffb1','fecbbea8d0c6b7f0a251d8920436b8c95f0ea10f821aa40e9c2f8dfea7707284','e14cf56d8d1499cc733d429f8dc9b4a1336a10e4e9cbb8feb6208d10bd70d32c');
INSERT INTO blocks VALUES(310352,'fb97d2f766a23acb9644fef833e0257fdb74546e50d9e2303cf88d2e82b71a50',310352000,NULL,NULL,'d75ce96ca15ea976fbb89c93da04a0a7c2146abc01517663f97ad0fd15adefc7','7e056208896cce2657186a6d5d761b9920cd857dbb329793806c87bab1e37688','bb51d16f6590904295d95a7bbc9861835b6e4b0124cc71f4c34073ca9df8e9b1');
INSERT INTO blocks VALUES(310353,'2d3e451f189fc2f29704b1b09820278dd1eeb347fef11352d7a680c9aecc13b8',310353000,NULL,NULL,'c0830c03df4b203d5e17a9274643e614fcf6e6fb7216067cb4f41f874436d217','c0a552261f4c5c1e98937d94d1f7c5cfe0b39e3f611528a0cf95fcda473a614d','b67fe86c18c597991202bcc0c15112ed9738bcb3bfeab8b88783b6abe796da20');
INSERT INTO blocks VALUES(310354,'437d9635e1702247e0d9330347cc6e339e3678be89a760ba9bf79dd2cd8803e0',310354000,NULL,NULL,'6f4d2524f4f976880e60e65aa631f8cdfa0b23fbeb3c41549c577b695b02fc34','01a33d76871ef52b9d06a7ae986880cd2a38a18f58c8ac09aa207a0fb3651f00','453059a5df36dde84da851a8cc852683ed290107c55d01ebcdb2b5a05b510624');
INSERT INTO blocks VALUES(310355,'ea80897a4f9167bfc775e4e43840d9ea6f839f3571c7ab4433f1e082f4bbe37d',310355000,NULL,NULL,'dffc32456b12dd7dc4bbf95ab9f360d8abf4b2e705b2822728053709222f7e50','92fd2fddda848700bdcc122b6823da8c05b37ba9ab3937493be57815b97fde79','609e5f5300a697b7bbb2c954566643ab59702a55671affa4f44e5300e1d4e91b');
INSERT INTO blocks VALUES(310356,'68088305f7eba74c1d50458e5e5ca5a849f0b4a4e9935709d8ee56877b1b55c4',310356000,NULL,NULL,'01c0a7d3388aaec2d2f713b930df5b716a899ccd25d3b7e3b4c21657be7923a8','388ef7e14580ccf93ae292f05ccf1da1b183be94bf51574244599640c75b5e12','2d56c777e81786fdc0fe4b86637ff161c6e09f6a09b058ac3156c2b1c9d4e6f6');
INSERT INTO blocks VALUES(310357,'4572f7f4ad467ef78212e9e08fa2ce3f01f2acc28c0b8ca9d1479380726bab1f',310357000,NULL,NULL,'4dd02f79c7ad6348031e564ead17921d1d112b6bf8c5f4308b52ef2511983683','78c37c839325a09b0a7e34b04b8d1c2dd6bdf6b311a8d1c2411999a492334017','e9caa25043de1b209c9c8a57def07b185a11c3cf3b892ccf12ca870d10c58a90');
INSERT INTO blocks VALUES(310358,'d5eae5513f1264d00d8c83fe9271e984774526d89b03ecd78d62d4d95ec1dea6',310358000,NULL,NULL,'a2815a72842de9330b82b8901f18116f208c379657cf8610c3510dad19b64124','475bbd1206e7e6bd8d36009c5fb7cd50e2eb4b6fc902034feee204318cefbe4b','28113ffc00d8358591fa9a343e062803d1197638d66407e645a27020cf3e6827');
INSERT INTO blocks VALUES(310359,'4fa301160e7e0be18a33065475b1511e859475f390133857a803de0692a9b74f',310359000,NULL,NULL,'23acd53757b9ce126a8817e2727a54a23b57246c92e6fda1f16fa4d5db378973','2b8b198fc2d7765ea336bbbe0aa979997a1861e1da8dd4121c4154d2bc1f56f2','a6ffb319aee3cb727e3534330344a635f7fdb14cacebbf2c5d69ca13f1d1314f');
INSERT INTO blocks VALUES(310360,'cc852c3c20dbb58466f9a3c9f6df59ef1c3584f849272e100823a95b7a3c79f0',310360000,NULL,NULL,'9325c1235f22738cd4897884005d5763db8b792930a968c1c6f75300f087e484','56dc378e4725b9a940264cee9ab2ff915cb89d6577293982e4a93f4d2ef06da4','b1b95ebd8cb5bd8b662bda69d2dd2a098c4149fc2cb831d6a1dfdc869f672d5e');
INSERT INTO blocks VALUES(310361,'636110c0af5c76ada1a19fa5cd012e3ee796723f8a7b3a5457d8cb81d6c57019',310361000,NULL,NULL,'30f7ec0f50ae1e4d4dcfbbebc789dfea4669c2a21a4d251550fd6696bce94952','a2632f0ff6eb59a1fae532cb86b2df6703e38cf21d3786a5a1d3fc2dfc0c43b0','dd651fb6371d5380bf96ada6c963e7fdc3a21821ce6e6a7d6fb4dbd8b85e3316');
INSERT INTO blocks VALUES(310362,'6199591a598e9b2159adb828ab26d48c37c26b784f8467a6bb55d51d7b6390f2',310362000,NULL,NULL,'6fccf61f9c49986937cb13205f4ccdca952fba67c1af89d8c05da51b11ad98a4','ce61fa6c0ed9e3a544d051b5a4f31ff847daa3635417626d54542ec550ef1f22','f71a431fcad0405a703318b002a17f18c30900742084d6d839d7bc165b64efcf');
INSERT INTO blocks VALUES(310363,'a31967b730f72da6ad20f563df18c081c13e3537ba7ea5ab5d01db40e02647e6',310363000,NULL,NULL,'74a243525a58bb5d1c051c10d1ddacfd307b69fdbb2da618e079322f3d317b61','3660af72d71326d1541392d382927a3fb1ad1a0f6a3a4e80685df90342953833','aa8fe671c647af7d8ad1eb3d7b5318efcb3c377466efa3e82e85b8c1cea725e0');
INSERT INTO blocks VALUES(310364,'67025b6f69e33546f3309b229ea1ae22ed12b0544b48e202f5387e08d13be0c9',310364000,NULL,NULL,'5a0b10220431a5d6777ef9e49ba6333c7026f04ae450d48a7273732e8cd55ffa','3a5e3be80eb02dfea0435e991d2cf1f75d27b992a8ecf3edcaacefa127079107','a17c654a0a9f85b30ed8842056d2cb35add8d430a89352c85a862a2e19d66ed6');
INSERT INTO blocks VALUES(310365,'b65b578ed93a85ea5f5005ec957765e2d41e741480adde6968315fe09784c409',310365000,NULL,NULL,'50e97232160d4b608299961f420a6218588c5650a8e45295a08f789a49b25d20','d47095d112e553994c71b51c59110c965cde360d1a643d25692c307d1e60000f','9bd1598b17a05251035016b7f713061355677efbf15479cb8835cc8474aef874');
INSERT INTO blocks VALUES(310366,'a7843440b110ab26327672e3d65125a1b9efd838671422b6ede6c85890352440',310366000,NULL,NULL,'4521f3e3fe9fc9254b0d66fb4cf24ac72c50808751791e5752195c0dfdb403fc','5be7691b99fa36950aa3f6726e9bb23a0b73ba0c010546519ece5390df8e29a0','cc3eff4a17ec38ba1b0d0b729fcaaa96ce4ab4d4667c4fa46a93a9fcae862c8d');
INSERT INTO blocks VALUES(310367,'326c7e51165800a892b48909d105ff5ea572ff408d56d1623ad66d3dfeeb4f47',310367000,NULL,NULL,'9b89619d958dab0246a3f2c8b8f402bbeb3a59637f492b7119a9a84bd939b661','8d2062a005839cacc501977b73db0a5b7c43dff6aa3f02f260d964a70b7e0d80','e4af4dd5ebc9d39c2ca2d32ff7fa8209fcef7e9aff95e32cb15dc69dae27ce9e');
INSERT INTO blocks VALUES(310368,'f7bfee2feb32c2bfd998dc0f6bff5e5994a3131808b912d692c3089528b4e006',310368000,NULL,NULL,'569a5946690bbc8251325d0569181b4c276eedbaee5885b816ebbef86d01e196','4af91e1926d4dc3f2ad368229e6a69eb6b022c701609d5320ae01e58175feb9d','4f56c9b69ef9cf2bd79573197f3c1e2d0b3d21f1ebd48a609be654ebafe737ae');
INSERT INTO blocks VALUES(310369,'0f836b76eb06019a6bb01776e80bc10dac9fb77002262c80d6683fd42dbfc8da',310369000,NULL,NULL,'0ca340f24633d8884a88fbf3c7c9280c31460745dace8563b0b66ed382e0fa2f','9614871f179218bff19c61b5570552a727b73f32dced9e2a63b00f06c90f9062','944bcb7e57adddd694fb27274a76e99c1a56e5395ba0edc10ad5c1cef7a65bb0');
INSERT INTO blocks VALUES(310370,'9eb8f1f6cc0ed3d2a77c5b2c66965150c8ceb26d357b9844e19674d8221fef67',310370000,NULL,NULL,'290093d9212196ee4c03b9eac0245803158dba2948f158e2c74f8dc10ac09329','25bcc99601431f79892965c1cc951ad2367f69f5f5be85f86f01a141b7577838','feb794e9d335e20eba96b0442a64232faa5f7638f94a0842050c9f1fe15c2004');
INSERT INTO blocks VALUES(310371,'7404cb31a39887a9841c2c27309d8c50b88748ed5fa8a3e5ba4cc3fc18310154',310371000,NULL,NULL,'fa6616279666c600602c38434c2b0fc9dfa1e551513e4144419efd45e0ee0462','b95c18f3efb346da44a68c9f8939c6455f7d969ecb7882b361d04e2a2ee60454','62d1609b755c0d43a0b239054a088d4fab36163cb851781a8f9c5be13a4673ef');
INSERT INTO blocks VALUES(310372,'d3a790f6f5f85e2662a9d5fcd94a38bfe9f318ffd695f4770b6ea0770e1ae18d',310372000,NULL,NULL,'25d0ad708dfe99367db6dea83491440f2c30421a5a7c4fb024d0ed79cf59b1aa','8c41d68efe879ac63654a6736f3787d13fadb9086514798fe19bbd239b7f4c1b','6118308ab90a6c4b13a47ab87c52f1bcafd87de83055d5b7e6f4eb1f9b60dca6');
INSERT INTO blocks VALUES(310373,'c192bec419937220c2705ce8a260ba0922940af116e10a2bc9db94f7497cf9c0',310373000,NULL,NULL,'408be37b314e37b6192d85d81c706f9e25c0d7e5a5448a6ed6284d324f587054','fea7acd7bb546f2781629ca86f352c3c0028902250b3efbe2114af3ee7a0752a','3b9d6904cb4eea845a7f46718369bde68b46f6538673232bce2e1565a3b8d83d');
INSERT INTO blocks VALUES(310374,'f541273d293a084509916c10aec0de40092c7695888ec7510f23e0c7bb405f8e',310374000,NULL,NULL,'3153feb773ab5352e9380d3faedf2f32f427dd35b5de78b52293abe855c1091d','974aeef137239e09cfba44cf5095727c6b1badd16fcb8349dc3b97a984110783','b3b88d324065787c5f72a730fe1ed141c6dd799afd0188934fc02675515601a3');
INSERT INTO blocks VALUES(310375,'da666e1886212e20c154aba9d6b617e471106ddc9b8c8a28e9860baf82a17458',310375000,NULL,NULL,'5364cf94d87ffdb49360513b1271c5f107a42830cc8ca70b4751045dbcf92eea','4bfdf1d0a2616210697081eb2054e45415c7b62091fee5d2694f1cc1c631a179','6932a9706715e4492faf6b8cbd0d5186db7f1b4334389b366b868623315c04aa');
INSERT INTO blocks VALUES(310376,'5dc483d7d1697eb823cba64bb8d6c0aded59d00ea37067de0caeebf3ea4ea7dc',310376000,NULL,NULL,'ad88937d28e8e5e24af4af424cb4004005d71b7d056d8d93b9f1eeddeeafe4f5','bf594b6cc778c9f7938582903796781f16b4a24fffb29b4d6444eb6447d7baa8','ffdbe2c2b154683e464069158fd0caf76ec3653932ddb36a5cf8067616c80274');
INSERT INTO blocks VALUES(310377,'f8d1cac1fef3fa6e7ad1c44ff6ae2c6920985bad74e77a6868612ee81f16b0b3',310377000,NULL,NULL,'0e30a4b710daab3563f7fb624dd4170e0026e60574742b57cb64cc03d621df15','fe52b818d8da5167616d4d7d17416ba4e429985fdd9b3622e99c1fd35e0c6249','7510e0d45e5127e0877d84dc64e70d5a639755bba4435240545bb4f32821a5bd');
INSERT INTO blocks VALUES(310378,'fec994dd24e213aa78f166ca315c90cb74ee871295a252723dd269c13fc614ce',310378000,NULL,NULL,'7fd86de094040b85e820255f840b863f0725c53738d32952fdfc58beae9c6589','838798ab799f64a338f82f2eaf0ea097979735287a6a809b6ae94787060786b2','8e94b42654a397ab99f812594a82986046648b3a4c686e36285f4ffb7ad15ee5');
INSERT INTO blocks VALUES(310379,'d86cdb36616976eafb054477058de5670a02194f3ee27911df1822ff1c26f19c',310379000,NULL,NULL,'fd89c38a53a75eee1c46a3e29cfe1bdb4956cd9bf8de15b582f0bf0d90dfa13b','a81033b6edd163214cf04fce5c23a561777298f9f84d0ef58167529ce8e75900','ac51120109d5ea5f948eef21c8a9094a607b417fa3842c0070cd2767012763b7');
INSERT INTO blocks VALUES(310380,'292dba1b887326f0719fe00caf9863afc613fc1643e041ba7678a325cf2b6aae',310380000,NULL,NULL,'2967d25d8d46df256d7bdd08a1f2dc77cb42af8adb2f53830d2d9abfb2981f99','10fed0bf2c76e1f8dd3e2f6dbf327692626981ea4f209422f4682c706367d743','b169a6c24e3cb8dc675e5f483e832a49b9ceea0076a91548ff6c037be2d4f78f');
INSERT INTO blocks VALUES(310381,'6726e0171d41e8b03e8c7a245ef69477b44506b651efe999e892e1e6d9d4cf38',310381000,NULL,NULL,'703a73971fe4f5d48ec8393c7e8dc8cc13374ab8a2d52c68988593c4de8817f2','bab78dc7c392c2cab100a38e07524a6bd077e7bd4085e232e757519f082efdbe','266427f6b5978d5127f6868b150dca27353be27ba38b5fb5e3a1e93663b853d8');
INSERT INTO blocks VALUES(310382,'0be33004c34938cedd0901b03c95e55d91590aa2fec6c5f6e44aec5366a0e7d8',310382000,NULL,NULL,'198e36c164a6f40c76112501fa1c70327e3e005a042d1369faf0126f41d58d62','21298b4b4ff4def5b3f9e4f540abf3dec182e36b3c4f22d745637d5024bb6d7a','8e6d97b28699c3b7fa4ff9e4d60b82236aa4b76f5b85e0f7b86ca5eff61d7ef2');
INSERT INTO blocks VALUES(310383,'992ff9a3b2f4e303854514d4cad554ff333c1f3f84961aa5a6b570af44a74508',310383000,NULL,NULL,'591cf03f57957fedb0522af2ca5fe111c5828157054f51a1b3fd9cf72b429a28','dfacec0e11a4dd8f9b873edbffa63e029c2b1cf283863ff3fa9d92e4d3e00248','7069d01645587c1168ea4659a1dd46120032bef765a86d2a9433f7236a945f1e');
INSERT INTO blocks VALUES(310384,'d518c696796401d77956d878cbdc247e207f03198eabc2749d61ebeadee87e5e',310384000,NULL,NULL,'5c911e05c1670a675082c98b242b80bc5ad3ddd105ae4d4bdb2cb6601e172a29','414af70d5810c9aef5db490b7114d001678403ec3c2974e7610190714516cd57','4dc2be57e87bd768e40e5696a2a10ec5df853ee3a535fff0a12530bf9eae29ab');
INSERT INTO blocks VALUES(310385,'2aa6a491a03a1a16adbc5f5e795c97ec338345cfdf10ff711ffb7ac3a0e26e28',310385000,NULL,NULL,'1944f881a1202cd4aad1cb089bd916386581b94c96002cdfa67a69d7b537324f','b1e38996c79306f4aa2bad7e6d8ac776600ce55cc286cd0e08c7b2ed7d3ad5e4','98f7e5b11772078dfd34d32878b9d37b3f2bf59cb86ac20553595e05d4b6de3d');
INSERT INTO blocks VALUES(310386,'9d19a754b48a180fd5ebb0ae63e96fa9f4a67e475aeefa41f8f4f8420e677eda',310386000,NULL,NULL,'bf31cbeb8284aac77b6515ec7388d67e76e19ba79452b150a833c13c892c0ee8','df02b0ed953fc7b21fd7fb12a941026ac991213471e930be559f2715a27814b5','c0df0f840aeaaa40357294332a94cca9edaad42edec8c77936f28ac011b15599');
INSERT INTO blocks VALUES(310387,'b4cac00f59c626206e193575b3ba9bfddd83bbfc374ebeb2838acd25e34a6c2b',310387000,NULL,NULL,'3f82211082a2d6981de51244bb0483eebfb3bcadfd48b80151fd1c89694e2b3b','76644359226a72dcbe79044e08eb467200f1c6752dc958f2b954c13454706393','fddfad42ce007c7c7cb579d8725c916b39bfe38501f50d5538b82aa91f43fc45');
INSERT INTO blocks VALUES(310388,'41a04637694ea47a57b76fb52d3e8cfe67ee28e3e8744218f652166abe833284',310388000,NULL,NULL,'59c3a3c5648f18274642df5050b117d8031f10c46be63b5864f30ecec69f0c09','ba1dbd0744b899b9284e5a5abf8ee3d72eda1f7e7193466387d507b0fa0df960','9a395a2027a9fa192f6a0177c57df9fed9afe238f56f1894627af40d22778397');
INSERT INTO blocks VALUES(310389,'3ec95ae011161c6752f308d28bde892b2846e96a96de164e5f3394744d0aa607',310389000,NULL,NULL,'fbacb621beff1e0769d716ed51493afe97874941feb7787b5cc80916e3ed09ac','0fa26b9e27317baf8709191960faa2c523c8ad087b87ba3a299d40a4d0093b1d','591427c91481dc38c2a4d683117897bd5ced59d6271f023951c5602bb8d5b623');
INSERT INTO blocks VALUES(310390,'f05a916c6be28909fa19d176e0232f704d8108f73083dded5365d05b306ddf1a',310390000,NULL,NULL,'a2c398743a97092d8ea6875970fb1662470fb5918f09e50c132c29ee6fcc9b35','04ff3f7c79738e5fa2edee88e750782ee3d7d3d05cb88d9b49c8bd727b9657db','0af277433812116f0c41629a9f696d9ebe4564a89cdf6f799d263bee22ab5010');
INSERT INTO blocks VALUES(310391,'fc26112b7fdd8aaf333645607dabc9781eac067d4468d63bb46628623e122952',310391000,NULL,NULL,'cb3842fc91685c97b6db5ab71e1586259c83c619ecd57dd653a213b5c4a9f9a1','4b01d331e247b3bd9b7f668e986e15aa9e915f083d6644033ad702a289667d5c','3589d4c32501a7bc96491bfa6d8754e8c2e9beec9399e1faaffdeedc2ea28baa');
INSERT INTO blocks VALUES(310392,'f7022ecab2f2179c398580460f50c643b10d4b6869e5519db6ef5d5a27d84a1d',310392000,NULL,NULL,'780ea5e6adc1e9ae328efe2ea25af76ae2e228c98b475b6337ed84e5924e3b95','a3f18833d9974b1a51313660865d19524994b0d8238b0a1b9a620e72d6c0810e','6425d33031a3588aa69370b47d68bbe270fd5f48ad20545ba35eefd13e28e07e');
INSERT INTO blocks VALUES(310393,'e6aeef89ab079721e7eae02f7b197acfb37c2de587d35a5cf4dd1e3c54d68308',310393000,NULL,NULL,'6f61090175f1e398ae20dfcc41e5075327ccbd297c786c8a09a866a77836d429','5734ba63b11700f61121912de03d8946d66500cf908196a62716de1c2f2117da','4b3a1372a4f9276026e50aac6c1f2f2807aa78b83ac76246e73ad60c2e5164bc');
INSERT INTO blocks VALUES(310394,'2a944743c3beb3bf1b530bd6a210682a0a0e9b0e6a9ff938d9be856236779a6f',310394000,NULL,NULL,'8cdcec6732f3d4f2da04edc5a59cbe67fbb27ea069efdc23e4bc92f055fe4223','dc0f8b012f64fc86090a31f876d3f2ab83740f36fbf698cefd9b0fac43e344bc','3eb1196089d48210d9d41b992172f377dd4e25009d496146628d6955c3817d9f');
INSERT INTO blocks VALUES(310395,'19eb891ce70b82db2f2745e1d60e0cf445363aaff4e96335f9014d92312d20e4',310395000,NULL,NULL,'291b2e82b5bf5ebee0ab534e53cc2a748429d7248ba1194a8f673552ff65cdea','a077ecf593a9288d000660e49acd5c6dc758871105f4bfb8925426bf9b9bd1ed','a8e65423db7928ac7a400f98c988e7fa89e0b9149b305d5958741e6781009a3d');
INSERT INTO blocks VALUES(310396,'aea407729ac8d8e9221efd9d70106d14df6aaf9f2f87dc6f490835a9caadf08e',310396000,NULL,NULL,'9698aa62d90bffb57f7b8b92e4275dd6df0b53d5e539dbe3440cc8f885881e65','a0322490129026ef11f1c3d3f59d864d6706e781a7f4e55c9f9e4e05126721da','0cfe4fd90421236219e868b7e1a3e25703e2edd3dc5d057df9662fc1a7b0a7d6');
INSERT INTO blocks VALUES(310397,'7c429e56a19e884a8a77a759b52334a4b79404081b976270114043ba94d7985c',310397000,NULL,NULL,'bcb427bbccd91cbce4402f5b9495d789a81e22fd80467f8023e33b98f487eda2','f6d50e312f03939ee4e70ad9bee763d7ff9fc471ceaa0718af93a0e3c5845cdd','75f9a576bcdd234cd7fb725b49ac409f846fcee88fdeea22194b9f483295ddd3');
INSERT INTO blocks VALUES(310398,'55c046db86dee1d63c0e46e6df79b5b77dfd4ab2ff5da79e6360ce77dd98335e',310398000,NULL,NULL,'3833e3ac7b7b74948268b6588ecb6b6752ab22138e0d2f477e3dbef12adab776','0912cc5be337cf4ee21095fea0f9079d548f3eea97e39f127844d47d3008416b','66eac21652221aca2b132f341cbdac6f6c9839f8a46b5ec5a55b33f99d9b83d0');
INSERT INTO blocks VALUES(310399,'765abc449b3127d71ab971e0c2ae69c570284e0c5dacf4c3c07f2e4eca180e7a',310399000,NULL,NULL,'c15cf8452811e6df6f5438f8343f9a3421e75eb9aeed8e42eb0658e89c64dd51','7820b00e830795a7063773adbf06f2b0dda63241403f8ab3706924ba453636c3','942e40508081ec8a34f07891aadd503e1e29951fa6377287330ed637655271ab');
INSERT INTO blocks VALUES(310400,'925bc6f6f45fe2fb2d494e852aaf667d8623e5dae2e92fdffa80f15661f04218',310400000,NULL,NULL,'bd993e2a64b62f6c376e338e9beddaa0ac0501b39883506f2472e533bb19cbec','a1bb923921b4d926ac53422904f56662d0d2785805bc6d0c028b3b6ca1f2b6a9','5144fdc39df08a25b2005ae96a1adb838839c6a30c082630fcc74d0b5bcdd0e2');
INSERT INTO blocks VALUES(310401,'f7b9af2e2cd16c478eed4a34021f2009944dbc9b757bf8fe4fc03f9d900e0351',310401000,NULL,NULL,'e6dd67cdf805c23e353ec25468f2ea830da46e4104dbc537e9e15a5acc1b28fe','b1b616edced1ef0dcfd82c344ab67611773a9da6884f43bc2f16919f06cbe06d','9c310a6fc9336bda016e6dda718852e99fc2532457578d929c899ab7299e4ab3');
INSERT INTO blocks VALUES(310402,'1404f1826cd93e1861dd92ca3f3b05c65e8578b88626577a3cbad1e771b96e44',310402000,NULL,NULL,'6b19a39e68b8418c2eb1650bd1427438dfd65bf627bb6b50ae3a903c9169ff4f','eb1c5c4bb3ef92a04f2a7db9651cb3bae71a4c943065e6a85d5bbef1192c30bf','88ca30558e4398c066f785b01fb30fc638a0c90c8987f95eab4cd12bf312de8d');
INSERT INTO blocks VALUES(310403,'f7426dbd4a0808148b5fc3eb66df4a8ad606c97888c175850f65099286c7581c',310403000,NULL,NULL,'bf22dd1b8b936a1eff32dea79c9cbffda251bc59ed2754f73c139155eeb2eae3','4fd95df50d4e25fcd557e1649087a3a11222b34cf5ce58b46e8e3759e50b44dc','b9c851715ee84363ce86e5a816ac5016a2ca87012a82e6daf7570eda26a006ba');
INSERT INTO blocks VALUES(310404,'401c327424b39a6d908f1a2f2202208a7893a5bedc2b9aff8e7eda0b64040040',310404000,NULL,NULL,'2dff8ef48ea2026e72bb327368bff21d40eb321ef8c9ab5552c6b9f40dadcefe','46ac8262f523ec802a06e75d84536cdfd123a83d80dd34f18f65dd4ae9f5a898','47ce421e0c55ae11de4c0af6a97b26f5f8acb1b611f71a0d7a714a7e41dc6b74');
INSERT INTO blocks VALUES(310405,'4f6928561724e0f6aab2fc40719f591823ca7e57e42d1589a943f8c55400430a',310405000,NULL,NULL,'35b2f3fb27f707493d53ab0eb8eb239891be2a050a1f7ea9fffeacc1b6e6056c','5047b3532d561041585569f2f78c705fe5bf82224638c7c003d6649e0bcdbe37','9fdc08b89a53f84156478144ffbe4f30287564cfbd2cc3b251900c6fe1aea9a7');
INSERT INTO blocks VALUES(310406,'6784365c24e32a1dd59043f89283c7f4ac8ceb3ef75310414ded9903a9967b97',310406000,NULL,NULL,'4a962a898f5795990de43cd3133a60b5b969ad366de6bca8d0b9fcb366759d1a','76c4cdf8c23d972118ff1e241f8443d97ca3dc2ad895a2b546b5a07f95a7ff1a','87f9909663f81e7f58445b73afe29152d0fd464d25d23d2b4ed249f5d7108d5d');
INSERT INTO blocks VALUES(310407,'84396eb206e0ec366059d9e60aefdb381bca5082d58bffb3d2a7e7b6227fc01e',310407000,NULL,NULL,'18e8aad129099c20f268ef8a3664253f8d444a24e3c4942369bbeb80fb76c862','5c02b69c2f886cb7c2366626dbbacb652831c3812977224324e1f8ea7cfe0a6a','3a85ec60cc6d88829e6ce647fcfc4ad0255a3b449807a97cac5c9e0bad0efd68');
INSERT INTO blocks VALUES(310408,'4827c178805e2abae5cb6625605623b3260622b364b7b6be455060deaaec2cda',310408000,NULL,NULL,'b694511530b99c6a6d405871f2fde7470baef8e0a2545b598adce5c3b9234765','63262cb6d164a96be4b758262e7203cd2bf98d21fa8852afbb08d4c7d50c68e6','7d3e9f510407d7875451eeca2bc40d7bc3ff10b98379b4d573ab8187cef619df');
INSERT INTO blocks VALUES(310409,'01a719656ad1140e975b2bdc8eebb1e7395905fd814b30690ab0a7abd4f76bba',310409000,NULL,NULL,'cfc8dcee1ef668455b7c078698de8c164abcbfe7f6159fe206faeee7b0ec006a','2562238857b61b5b81bc41b0f3b5d386f6a3b72e17d8c41714787911c5478dc2','3afc907190a1a32f905ef407ee10e939ce65d6a95a6208f9e589a0dfa475110c');
INSERT INTO blocks VALUES(310410,'247a0070ac1ab6a3bd3ec5e73f802d9fbdcfa7ee562eaeeb21193f487ec4d348',310410000,NULL,NULL,'52eeb77c0ba4767d59e4ba0e243032c44ae83abea1fb407c2079e58e869d6437','62d8f4a2d78c81bf0b65cddc01f8930e80dfb25cc7615dbafc547a2ca09bd802','8d57dbf4266d189382a3230b43c77a8ad17b78726217daa2b6adfb278ac1e649');
INSERT INTO blocks VALUES(310411,'26cae3289bb171773e9e876faa3e45f0ccc992380bb4d00c3a01d087ef537ae2',310411000,NULL,NULL,'10224812cf36a49d15040fb1a3ad3e580f4690e8309dda99713bade55f2299d4','3cc1ca4187358a1c7cc6c594b1b3dcbf384e6c30e6f64a8b3fed00b457cd638d','d7cd046188a882fb2798ddab803c2f559fd64d5682699733211c11dc690a48b7');
INSERT INTO blocks VALUES(310412,'ab84ad5a3df5cfdce9f90b8d251eb6f68b55e6976a980de6de5bcda148b0cd20',310412000,NULL,NULL,'2e095263dab63461abb4210a78c96ba09181cdb55fe67113edf6badd5da8a386','249e076e1ceba57422522a03647f0d6658c0a20b6a0e6cafe18d3f523b70fd65','dd03babaa235703e85ca8e7ed42ecd46a8463c636d8fcc36099f5ffe93909f9f');
INSERT INTO blocks VALUES(310413,'21c33c9fd432343b549f0036c3620754565c3ad99f19f91f4e42344f10ec79bf',310413000,NULL,NULL,'5201dd7aaf4dd358441bbca3ec6785eb9f7bb36d25e9aca9e5cecf0e9391b7b3','04206364ef4756d0e68a4c86e27de74dfd77eb99fb6c87acaabf158a8fff32b1','96d41de529ceb9f30bff907ca3065ba3b0ab076f484ac86cdd29988f4b3a8513');
INSERT INTO blocks VALUES(310414,'8cff03c07fd2a899c3bcf6ac93e05840e00de3133da14a413e9807304db854b6',310414000,NULL,NULL,'95de8fbba49b748c4fa28565b47230dd294ac6b02906d1dd7aeea73126db9513','cf6c6730e186821c35c5109800162d1ecccbf1c25497d6b420134a07ba01c83b','0dc67782b91f676f2c6a86c44a87bef2f03e7d18ebf050a3bb7376eff8ea96de');
INSERT INTO blocks VALUES(310415,'dd0facbd37cca09870f6054d95710d5d97528ed3d1faf2557914b61a1fc9c1cc',310415000,NULL,NULL,'53a7b4628a5273f5b893f64af2db6d66b5b9e4ffe5ae5076b274537245f53b6d','032d3e0e1d1da68f2892be69e0c8081201f0f8a97ef20421af43f6c2136616fc','3051bdcaabcfb835f972c1e7b9d22ce168bd3eb5d5422464647747e9c2ce4242');
INSERT INTO blocks VALUES(310416,'7302158055327843ded75203f7cf9320c8719b9d1a044207d2a97f09791a5b6b',310416000,NULL,NULL,'f38e62a046767b352776b03cc9103137061d2ebc1365a6589e8604affd29ea84','ad2b76b518c5ecd61611a2ef2c579f4e5bf6d961df63c2305904f80049124b68','b96dc85fc2eaed6b86ae71dc96f6d362b41df095ba057146ea8b7b44a744da45');
INSERT INTO blocks VALUES(310417,'2fef6d72654cbd4ea08e0989c18c32f2fe22de70a4c2d863c1778086b0449002',310417000,NULL,NULL,'752734f6cb598502a13f567da58739e021aed45268f52c3a56aa94c77dbe4294','1b76759eaedd7c0e7d6f917860af8b46431d3bbe7ef23bacbc8385c5dea5e902','2af93b5935418ce4a3e682309e7e51e0d3d2b255f282f200b16083e2a865b8f4');
INSERT INTO blocks VALUES(310418,'fc27f87607fd57cb02ce54d83cec184cf7d196738f52a8eb9c91b1ea7d071509',310418000,NULL,NULL,'778a0c66fa9454d466fda8bf21ac02b03d80e18380cc79bff8b481d7832977af','001d9da5e4404b8c75a6c30c7aa43a87545a51dfc11031eb182600fceb91ff57','3f07619c70d5c9d0fab02f355c38329ad137e76e8c6ac8e73989d799efecf8f0');
INSERT INTO blocks VALUES(310419,'9df404f5ce813fe6eb0541203c108bc7a0a2bac341a69d607c6641c140e21c8e',310419000,NULL,NULL,'1dd204b4df4f865718b1cffb54a452885c04a524c4f9cd6be0e92bcc937f49db','df2f612fc0175f8c0adb1d8714006515a3f4b703fa80286e7a162eac9ed8801e','66c3a769d265d39bbdec675e345dcf4b76f9b6ad04398dceb877c071384db138');
INSERT INTO blocks VALUES(310420,'138b3f1773159c0dd265a2d32dd2141202d174c2e52a4aeac3588224a3558372',310420000,NULL,NULL,'3b77f802ef867f0fd92f1dfff4f7c5ad074ed51f0ed2b1a5d39f1f44e6aa7ae5','a995a8bd6a60220d10b788e0019729f5db4aa955a09e54ee5f3edec136521feb','01632c3e627fae351849a0a4dffdb576a56daa1b890ee701ea3bf7466065d4f3');
INSERT INTO blocks VALUES(310421,'71fe2b0e02c5cad8588636016483ddd97a4ef0737283b5fd4ab6ea5dc5c56b9a',310421000,NULL,NULL,'6d417941e380b66715edb4e74fb63026f35411ce7782afc0a6abd2f5d6193934','4352d1c118121536f47d486a310df12a048a8d270ef0f9dbd5a81da95491f957','b89940be1b2cf8beebb86017e41b286b0bdf010224a41ab37113777d098d231f');
INSERT INTO blocks VALUES(310422,'cd40260541b9ed20abaac53b8f601d01cd972c34f28d91718854f1f3a4026158',310422000,NULL,NULL,'593383ba8869cf5afef0a8bd1212a9a87e69ed1f79d24423f3e268b22038d865','efa5cb3ae6f6a8e3ed3ccf6cac5b1da77b02767f8205a308891d3ba5490d37fe','89d67fc3e8fde089bd36ee48fbb017e1ef97585f3ff8be5ef27e3aa3a533cd11');
INSERT INTO blocks VALUES(310423,'6ca0d6d246108b2df3de62a4dd454ff940e1945f194ba72566089f98ad72f4db',310423000,NULL,NULL,'03ad9d534765ed15c02046dd7076f8d0f9332b987336f779a52ef7da5a63d2bc','0079097fc31a4b5bccee4df1da65c4d6fe43b61579270834caacc5c331a03ce5','45ec3f6b7450bdd1611a610dd1dadd1cad608d6711ca177892f372433c77991b');
INSERT INTO blocks VALUES(310424,'ed42fe6896e4ba9ded6ea352a1e7e02f3d786bfc9379780daba4e7aa049668ad',310424000,NULL,NULL,'028be1a76113906628e18a5ac0b00db7d8769e2450f145653c3b5f117cce2d1d','41e88cf662a0116cea8734aadaf3600d4581307b2373c9af0cbc07bae9fcabbe','9a7b112ea0b06bc4225814f9c9888e7ae158cde835143cbb9d84b6e0dd9b6bad');
INSERT INTO blocks VALUES(310425,'73f4be91e41a2ccd1c4d836a5cea28aea906ac9ede7773d9cd51dff5936f1ba7',310425000,NULL,NULL,'83d4a7d8ffab3c5f6d2637ee98a2ed4bf9633f54a630a65c882190bab089bc2d','b1ad3493f6c3fd1e301b3f4c8acba226bb8e619f9c62fd9f043900091d777898','0413730f30f1033d156285f2ce8c5bbc4c720563ec9d5d7e985a84a9a8ec45a2');
INSERT INTO blocks VALUES(310426,'9d28065325bb70b8e272f6bee3bc2cd5ea4ea4d36e293075096e204cb53dc415',310426000,NULL,NULL,'7642193a01f93b2511299f4a024138db83f9affa5e14145bd0a4ff0a12fe89b9','7ac9691658275c9a589fdee955dd7ac3b4fdd250a7dcafdf765333bb463e9e9a','e02fabc12520da45bfcbc2cd49190f9f12e8f699cb560cc6a264df09df71b488');
INSERT INTO blocks VALUES(310427,'d08e8bc7035bbf08ec91bf42839eccb3d7e489d68f85a0be426f95709a976a2a',310427000,NULL,NULL,'8e53bab070408894fa8b2b12a8628b2ae262567533f2a1c49dcb51e564d8baee','fc4474311217b2d4233d5e9a73583056c8a5c73f2fc07470b645d8c40e7989a3','0c73daf7698d3bcb6ee5cdaa8e5abb943e82780259c66c0e8781b86b98d351ee');
INSERT INTO blocks VALUES(310428,'2eef4e1784ee12bcb13628f2c0dc7c008db6aaf55930d5de09513425f55658a2',310428000,NULL,NULL,'f0af90a06b842c2d6646744b9c7e851e77cd73f27c1e97282aa3e774acb5206e','e9f81f4c1c56afc3890d241ebfc68c2b6c97f7e26e823c1f40a78c87d85529de','96b125cdbea991ce2f7b0800c711fa4958bbc1e0f5fc594736acf029927709bc');
INSERT INTO blocks VALUES(310429,'086bfbba799c6d66a39d90a810b8dd6753f2904a48e2c01590845adda214cf8d',310429000,NULL,NULL,'d96b15c84b51ab0ac9e7250232ec744bfea32aaa46b3202182bb1ba30637530a','9680d98e9d05346600e229183bae5d1a60b19db3cf78654693d0f7d5128d308a','a5f5aa75a7e6b3d9259ba7aff8de9467446bb206944ce5c55fc5ccbcf12e05e5');
INSERT INTO blocks VALUES(310430,'870cf1829f84d1f29c231190205fe2e961738240fc16477c7de24da037763048',310430000,NULL,NULL,'5877f31065e08853d538bb8ff2ab3204d2e7c46003afd715c7ab7e3eba36171e','667e7a665e5e6cec671d8fbc89ce32050c54165d88bf5b21230566d43ca2d88f','62ea58da97e7c122e97d3f782494a27fb5fa50041338219aa2827727cc910214');
INSERT INTO blocks VALUES(310431,'20b72324e40ffc43a49569b560d6245c679e638b9d20404fc1e3386992d63648',310431000,NULL,NULL,'c7693ebfe358dcb264ac98eb74f0d35b8102bc49a189d678c4aa83b792b92b01','ebed29c75b0c47e7163ba4e61562094324b705afe95cc18ca7c9ed30daf5377d','db55fa9e4c1e5475e078eb41bd967a66d16d4f250e758d371799ad4c4444a4e5');
INSERT INTO blocks VALUES(310432,'c81811aca423aa2ccb3fd717b54a24a990611365c360667687dc723e9208ad93',310432000,NULL,NULL,'2e4118a5f40e5a2d4da07622568a61e52ecae05dacd3dd54364015666b9ddf0f','db4b7d468467f580951669529f6f4c59a2bab576e75a84264a93012078acdac0','8911e6f8aa5627e15eb8a0406040927cab0d18a4d116ae3b2fcc771e0e84ffb1');
INSERT INTO blocks VALUES(310433,'997e4a145d638ad3dcdb2865f8b8fd95242cbc4a4359407791f421f129b1d725',310433000,NULL,NULL,'4508c61899741ad3637f891664cd17e8d8dce2147ec22bbddd23d18be7d4f5d8','b6e253bbca1b18da791d2b54cf24ea63fe5e3fbf3946e2ca5065613767d44c2c','c42057935f8f1b48753dc22740d1e487f8355a1ca6334587782e41bfd2a0599d');
INSERT INTO blocks VALUES(310434,'61df9508e53a7fe477f063e0ff7e86fbb0aef80ff2ddedc556236a38f49ac4d8',310434000,NULL,NULL,'222a7017a5159405dfa7ca716a368f84df446612b2e969ec775a56297f67c445','1eb4d2801ebcc73026bb2f4b5044fd71add2d3881da0736d7b3cad8de4e5fc46','9f0aa373d6cc6c0cbbb991bf233fb0b21b02f0d0ee7a6746907e87e1651f0adf');
INSERT INTO blocks VALUES(310435,'f24cf5e1296952a47556ac80a455a2c45da5c0dc2b388b51d235a3f741793d5f',310435000,NULL,NULL,'cf0f27b94a70b0dba7ee5391c51df323c154c767b21e7f18696cfb93e25e663e','80d8194c1b2b178d624a468eec7060d5f36d7d14193f308b992f78d484f09ac7','8a234a2b0116f680209cc2263c24b59eb045cc7576687c7f7972b44ac6709637');
INSERT INTO blocks VALUES(310436,'a5e341ba92bdf9b3938691cd3aab87731eba5428bb61a804cecf9178c8da0c19',310436000,NULL,NULL,'15455076d1eb6681233124bd7f4fd59586a22067bb008d8132e31c0019f3990d','147605c4e569f476c00be051cae4b2227f77a657a5e0daa94d1e82546798defc','98c7b91c3f072484e3070f0f92bf150ebfe967587a0765475f459b84c5b5a0b2');
INSERT INTO blocks VALUES(310437,'9e18d0ffff2cb464c664cefc76e32d35752c9e639045542a73746f5ec2f3b002',310437000,NULL,NULL,'03e6c21526a9e7ad688f8ee47638b2519b2a1ff0c47332da366a1077a9d93dae','11be334c5a163a4bf599f07b4d3d86235c8a6f28bafa85cc0ff7481d37fabdbf','f7eadef4dea9397d75e8ebe409c80ecec8ef47c5567c6c5809982c0567db91fd');
INSERT INTO blocks VALUES(310438,'36be4b3470275ff5e23ed4be8f380d6e034eb827ebe9143218d6e4689ea5a9fc',310438000,NULL,NULL,'dca613e290eaea92a4bde4f759fca67923568f0af3ece38c4165fe66787f5a61','ee9c7e9d478396be3026b65bc534ecedebe01c03f2635d4438910c61d1ed81c6','6ca818001b18ea4b55052fd6c06bd9c9a2070051f7554ad15c359433bd6966ee');
INSERT INTO blocks VALUES(310439,'4f2449fce22be0edb4d2aefac6f35ce5a47b871623d07c2a8c166363112b2877',310439000,NULL,NULL,'9da932c8c4c9a12d536db15649b8b89df52be294f3a3b16692618d2af421c1b7','2e0e70846f3c4fc0bfd3c1a2d24adfa74bf13977b4fa2ee6323102bac986fede','6ffec5902156ebbea2728350df5b6436b408c1d81452e59bc70d5525b4417eda');
INSERT INTO blocks VALUES(310440,'89d6bd4cdac1cae08c704490406c41fbc5e1efa6c2d7f161e9175149175ef12a',310440000,NULL,NULL,'ac9f1ff2a3adffd79ea3b2b13289ea060d2fa1ed9656a61057d1802531737221','deabd0f65f93300b7b08f4cc531ed187d894f9626213242596e7a04e46da23bb','f8826e03c73e471f93860ad57b1f236b83df5e8fb021d59d4aec39ccc915732d');
INSERT INTO blocks VALUES(310441,'2df1dc53d6481a1ce3a6fee51ad4adcce95f702606fee7c43feda4965cf9ee15',310441000,NULL,NULL,'4513dbf40e2b572ccfdb857eb58d4008b82959d110c094961cc7587ca9672316','383a55b28c1e94b0729384087e703ad4154fca98bb5bb27c5b4b64a6b27e62e4','8f741f51763f7f407ef0b08ad52aa50c64fe514e6bae9d860345e7c10d35e292');
INSERT INTO blocks VALUES(310442,'50844c48722edb7681c5d0095c524113415106691e71db34acc44dbc6462bfec',310442000,NULL,NULL,'e806ef15930bf2104b63bde714b397312052322dd034f0df727b738e05e1c753','97e1dac425dd49a63fe0849a668cc203b78adc0887d224b220b70a6a73b1b4cf','d886ce2ee113314afdd86622689ae628cd22f484e4fc6e44d9318224ad2985cf');
INSERT INTO blocks VALUES(310443,'edc940455632270b7deda409a3489b19b147be89c4d8f434c284e326b749c79a',310443000,NULL,NULL,'3f6cf11776817de3eeece3f754656bba718ed2d9fd52034f8c49b27ab12bae8a','d3725a194c59f80244bc8cce9a5f8793a2d0eaeb20d474c476abdb54d573bf1d','93793f559badd92669de168e3a858623b70935113919bff6e91b239279131ec4');
INSERT INTO blocks VALUES(310444,'68c9efab28e78e0ef8d316239612f918408ce66be09e8c03428049a6ee3d32e4',310444000,NULL,NULL,'da23b14ec6cc706fbeec8e796522dab412bc72b96833ebe9eb799e72623129b0','f4802f0658cbc4edfc480454ebaf9558b9c2cd1ab4814d94a50668ff35f76d86','0b164f52241185116e2893912c5209337876deee658096ceba55cb139e6be31a');
INSERT INTO blocks VALUES(310445,'22a2e3896f1c56aefb2d27032a234ea38d93edf2b6331e72e7b4e3952f0234ef',310445000,NULL,NULL,'50e9c4330e9f1fc6c563bf924064999f3e8feee2fe107884a95c913df2008da4','2cb79398652f003d23fe16829a75cd6db923b3ea5a201ecc7b56aa2b8c03a89c','56d2a8ecff64efb74adc05a7116fadbe54d44409a01e04e8d8c513303ca6aecf');
INSERT INTO blocks VALUES(310446,'e8b0856eff3efce5f5114d6378a4e5c9e69e972825bc55cc00c26954cd1c8837',310446000,NULL,NULL,'1b6f3d210ff3f0b1c0342419467a17c0d34ea1eea4e99ecb5ddf5e280818a983','804243055bcfd3a685b2044ff54399ab02a4a4b55daeb8fdcdfc0b79fafc0532','7def00446aa7edafb1a81657c81af00b34a6060367585cc49176336f35ba23c6');
INSERT INTO blocks VALUES(310447,'3f4bc894c0bc04ee24ed1e34849af9f719f55df50c8bc36dc059ec5fa0e1c8a8',310447000,NULL,NULL,'d5d10b1d7843d4070508a79192c7b1bb92876e64acef659c01ffce3c5ba5cfc5','6ee6fd4a3b0f91fd035842a84747adf04f5fc6f90990ba9f578e93390cac3ff8','98ad29fba8cf0ada3927330954d262b3f188d872613b86c02a524c20d8e7bbf6');
INSERT INTO blocks VALUES(310448,'6a6c7c07ba5b579abd81a7e888bd36fc0e02a2bcfb69dbfa061b1b64bfa1bd10',310448000,NULL,NULL,'488c8a4a6aa3850d0ea6c0f12ecf4cc9bf400aae8c4b5e4cc5589152abe5a90b','c417c9a605d65a7783455e2b101080c31b43a33391091c3c22b2091cbe27c703','1acf4360bbbb9c516af72b737e9a8ac12bf03afb5f0db7815f7ffe76c76d3ba7');
INSERT INTO blocks VALUES(310449,'9e256a436ff8dae9ff77ed4cac4c3bfbbf026681548265a1b62c771d9d8e0779',310449000,NULL,NULL,'5f8b738744da401e84d1174587d7e2900278621f3497adb94115167218e3d68f','f14a876e510eb1fdff039f10857997df214413f82131d77e2d194f456c9e9909','75fad3a0493aaf330fb868b5d761dfd05de40a379a5ce57318e4d12afb4250f0');
INSERT INTO blocks VALUES(310450,'2d9b2ccc3ad3a32910295d7f7f0d0e671b074494adc373fc49aa874d575e36a3',310450000,NULL,NULL,'185dba1b235227514d6ba11bd279b9fb05607714831edbc854c3dad8d17ee11c','9d090d98a5d3f07327228bab844e877094d441450b8cf021c0521a93b8919a09','b590e9e271e11ebd1476e82b4d43466cb7205d166c5b3606536e5a3718cca34b');
INSERT INTO blocks VALUES(310451,'55731a82b9b28b1aa82445a9e351c9df3a58420f1c2f6b1c9db1874483277296',310451000,NULL,NULL,'605cbe563d57fd6cc0d05d40e6217703ef899c9e61bdef381cf996403a782808','a315567243779fcd0e9609b2432fc7b0f09e34a23b2d92e13719bac19e9b03c5','314b99bbec702f994d068c3a5dc64499e8f064d7476a18386eba185e9a351d14');
INSERT INTO blocks VALUES(310452,'016abbaa1163348d8b6bc497cc487880d469f9300374a72ecb793a03d64572aa',310452000,NULL,NULL,'c3ccf7d83bde4f7b5777c902b809841ae0c4c2db098bcabdd1aff128ffc6fd5a','278d44c50cb873f5cc823ea760f1bea0feae6ba4d2fb56fdf9f60349b6d6751e','ff7fe86252266315aefb023c367f9ed6a8881d314fe977941865e702c8bcd346');
INSERT INTO blocks VALUES(310453,'610be2f49623d3fe8c86eacf3620347ed1dc53194bf01e77393b83541ba5d776',310453000,NULL,NULL,'3dac0390da1c50e05051eaa60ad2aacb0112adc54e0f0041a00db0a519333ebb','dae001141e51a31613db7d78a6741ede73b73ebad8b31db878cecabfa631d865','117176450122e151bff6d05af5ecd08a83a226e35071f63653e91e326ac51f80');
INSERT INTO blocks VALUES(310454,'baea6ad71f16d05b37bb30ca881c73bc48fd931f4bf3ac908a28d7681e976ee9',310454000,NULL,NULL,'8fea87fc079398499692f207ae111d25a034576c0f2407383a20bf73ffe66d06','594102ebfac5247e05271ce891bbde26ac0e34e4839f44db05d3aaa182aca17d','34e7c7602b7c292d16963a3f8d8d8a66bcd1e3b2c1ffe63b9d8e192f131ed5c6');
INSERT INTO blocks VALUES(310455,'31a375541362b0037245816d50628b0428a28255ff6eddd3dd92ef0262a0a744',310455000,NULL,NULL,'ce885b73d40cb2ddb6ec6474bd94ab4470515679f54fb47fc5bca7a87d1ca261','41f24088165c89c4d4b8cedd149e71484b3fbe604c27c3e785fecf42bed28be6','6dc7bc30dfcb10e0849b7dad4eac61db6fb5b18e872165bc676870e4ff45c94a');
INSERT INTO blocks VALUES(310456,'5fee45c5019669a46a049142c0c4b6cf382e06127211e822f5f6f7320b6b50fa',310456000,NULL,NULL,'16693fd96eb42e01b5ccac8c4978a882a50ff534c33ef92d9eab923988be8093','b53d1776fabe37571b6198a8371b9398c21135d08982ddff0f933214a0fdd8ad','49307ac8ff61e19653865b978b4deda137f96d05b9e87e7d1bfce53d47071dde');
INSERT INTO blocks VALUES(310457,'9ce5a2673739be824552754ce60fd5098cf954729bb18be1078395f0c437cce9',310457000,NULL,NULL,'81c06ed2e28e3eb67497d2508ec8399558d4be177fdefc525b7cf8010546da82','e7228b77fb5fb5dcc57579a9c87b7480d64b45c61ee8f057e78f316d6849092f','19869b30c1ecf8b496ea9ccc87ab0df945bbd0ac37206e7a311c9dd6137b4241');
INSERT INTO blocks VALUES(310458,'deca40ba154ebc8c6268668b69a447e35ad292db4504d196e8a91abdc5312aac',310458000,NULL,NULL,'bb906ce3def50a1573ded94e2ee8cd278375318479682145a72a3b9cd67f18ec','7aa7609987efdef5de1a35c438b8d81e0e5a98a78aada6c2f3fe66d9ff966b8e','bdb7de8782eb5067c90f26eeb81fb7586dc6d67c729c509dbcdb25780c1b5b3e');
INSERT INTO blocks VALUES(310459,'839c15fa5eea10c91851e160a73a6a8ee273a31ab5385fe5bd71920cbc08b565',310459000,NULL,NULL,'874afd2de9bfa523ab45482e1d2ff2a9136af0bd5ade66d7943564c504ef944f','340ed23b222282cfd1e6698d1bef9c4fe922ee57b09ba21a03b4a627c4f2d23f','eeb627aa3a1e6cfedf2df6243ca925222832518a8f2a0ee2396fd1a1028f6d39');
INSERT INTO blocks VALUES(310460,'9b5f351a5c85aaaa737b6a55f20ebf04cafdf36013cdee73c4aaac376ad4562b',310460000,NULL,NULL,'890e72732c1d57443213ee7a7270b3e2a7e9087522f57189ac61cd6dc852abfa','ac5eddb3e535135c726ce72c8c068f33a676ebb2f0bf64efe56a3f6139d588e9','058167e32c829fe75b0e831a85c98a487b6581e74a2f2cfbed5b1f561690487d');
INSERT INTO blocks VALUES(310461,'8131c823f11c22066362517f8c80d93bfc4c3b0a12890bdd51a0e5a043d26b7b',310461000,NULL,NULL,'8627256f470d906d5c784ba257f4f7d29e0d81347c7566727aaa26afd0a9b251','d95fa5d2144914f74b7615f3fdf2c11cf7cc38056c6904bf6fb87840f4e9c0fd','b1790c48c0e5bb3da408a4af30737ef4e15a135a0223e7b26a27c766b4863931');
INSERT INTO blocks VALUES(310462,'16f8fad8c21560b9d7f88c3b22293192c24f5264c964d2de303a0c742c27d146',310462000,NULL,NULL,'d1829d2db4718331aea74e59d3fcedc3f510aaab82f3f7f956087b32c040f63d','b923bbe8609df87870bd5c1e234b4d5ca0489398f23950182f94676fb304e2ca','b73bca36c840f13df43052e21b345128278b9b1e1440741ea31959e494174126');
INSERT INTO blocks VALUES(310463,'bf919937d8d1b5d5f421b9f59e5893ecb9e77861c6ab6ffe6d2722f52483bd94',310463000,NULL,NULL,'8b83bf9e263c69e8f731d90c9e6f92b66dd1652ea76390ceec58883f3ffe881e','6422f4e0fe4876c227f49e0be9d2484bd7b8024cfeeb8915e0e566418c7c9064','fc2a402e849b9a23b864262146af3f1eef6a90809074e088e38f67bbd0a67406');
INSERT INTO blocks VALUES(310464,'91f08dec994751a6057753945249e9c11964b98b654704e585d9239462bc6f60',310464000,NULL,NULL,'a93fbb5f298b41d3123312fe41ed8c5811410c32ac31062ff513c69a6ada8e53','866cf29d450ce95ab6ced2c9cb244054216a67e58289202782195cc74dee7a05','e09f51564ce899046a3c4d8248c7e6011898d7c74fd3f1f66f0f7a8f5b35ff46');
INSERT INTO blocks VALUES(310465,'5686aaff2718a688b9a69411e237912869699f756c3eb7bf7c3cf2b9e3756b3d',310465000,NULL,NULL,'19ea9e27f997fcaa3c260bed12a628b55054b6f90d579ff3e41ab1cb29240778','334a3659ea86d989f1b7f011953c34f121eefd7d2c8ea4c91b79624286f073c1','912883779d065bc70fddee958ee8ab34ab1aa3c08bc94432592f7c618bef43e0');
INSERT INTO blocks VALUES(310466,'8a68637850c014116da671bb544fb5deddda7682223055a58bdcf7b2e79501fc',310466000,NULL,NULL,'90c850f7cfe700fdea8d8d60fa03f080861414ec372a7d920ca6d09217f82fda','31343ef316be0c470ff1a65bd4623526ba38939277b6fc6c2bbb370ce7b7e6d9','26a7daa1438548751a41d2fafd48dfb71555429d524dd9efaa734017eef5257a');
INSERT INTO blocks VALUES(310467,'d455a803e714bb6bd9e582edc34e624e7e3d80ee6c7b42f7207d763fff5c2bd3',310467000,NULL,NULL,'9f92428bfddcff24329af3b4c0b3200e8b4ae3065f9b6a8a6488e159abfe6854','adc2b25c6d1438dc29199374b661ba8e72603ca243175ebaa669a44e6787b570','81d3804695b373175ee71a98a940569d041a2646e2c35a256927ebbf7dbbe424');
INSERT INTO blocks VALUES(310468,'d84dfd2fcf6d8005aeeac01e03b287af788c81955612375510e37a4ab5766891',310468000,NULL,NULL,'0cf6101033a96e6a90572ab21502314470c4b544bf21a902845861c413e1775f','f51f43834ab8bc1d585c78d2fdd47ff1022d7a4e80f7e6f4175ce9acdc6adab0','f33331afeb81fe0a0f09578e7083e775a7cfef949805a3f4733ea51f71a45fb0');
INSERT INTO blocks VALUES(310469,'2fbbf2724f537d539b675acb6a479e530c7aac5f93b4045f4356ea4b0f8a8755',310469000,NULL,NULL,'93f157cc43a6dc2df588c7cbddca37e55eddf5a94fcac82ebeec2d8d252a515f','2d1f52e1f7462e6ad199c1ee6ebc6525ba48eeda4b56b71428991d2048b23c18','6f95a2cf3634c8ca015b7a52629e2b9f5a7d4552279d1dceabdb8a76a419b4ed');
INSERT INTO blocks VALUES(310470,'ebb7c8e3fbe0b123a456d753b85b8c123ca3b315da14a00379ebd34784b28921',310470000,NULL,NULL,'d6ebcad8b1743d6dd898a522304594242eb063893c1d07baa893c076f6ccdc3e','9f65e026ab546f05ffc0513e9411cb464fad893933da0c40bbdd4e012775cd6b','0d34ed7059e46282809ebb67b818369088f98abc62ae73c911cd19efb559bca8');
INSERT INTO blocks VALUES(310471,'fc6f8162c55ecffeaabb09f70f071fd0cb7a9ef1bccaafaf27fe9a936defb739',310471000,NULL,NULL,'e6003555728c70ecd67dc8de1248de291a2d3a5d9fed35d77fd0888b5c7a1997','644d93aee805104d0e7732e4be06b727ba4c1b03e3b716bd9658498ab3959f87','9f620fb8845ecdc2d72f1093070717aad17760d8bb008def7ebb7a1035b1e61b');
INSERT INTO blocks VALUES(310472,'57ee5dec5e95b3d9c65a21c407294a32ed538658a6910b16124f18020f16bdf7',310472000,NULL,NULL,'dd553bc627b16f15cd618dd0504cd0ec04724610ff6ed44515957c997385c826','91ed2a626070fe511b2a90d48fbf3ec134d1bbcdd8e985421036e7b3104f52eb','a95d4565aa8e98860f052c12fd1c5f8c1699382340b9f9f2c21e7591bbd916ad');
INSERT INTO blocks VALUES(310473,'33994c8f6d06134f886b47e14cb4b5af8fc0fd66e6bd60b3a71986622483e095',310473000,NULL,NULL,'9290c164b0b011d53eb80193285fcfd830e524183cce1be181a48f085601845e','9692fa7e19d175543ad8d53522266397aa0d44476069b9644312dbae4b4e6869','493a2696a1b569b6f1f9654b0c6e2f08490ba59dcee5e4a06d65229bce2ef067');
INSERT INTO blocks VALUES(310474,'312ee99e9526e9c240d76e3c3d1fe4c0a21f58156a15f2789605b3e7f7794a09',310474000,NULL,NULL,'7aba0609948218e622e3293760bfddaa1ac4669eeaac6ec897aef5ab1268774f','458cabe9504f9cf493a9815aabfd974574ee599ea050f4f16f12010201d186d0','084ee45d5b707747ffca730053faf838d09f310d961063e27b4f7cd07a245a09');
INSERT INTO blocks VALUES(310475,'bb9289bcd79075962117aef1161b333dbc403efebd593d93fc315146a2f040eb',310475000,NULL,NULL,'bf95d8500066d276cc48546cc2c29398e26511097cc658b21d6a537c2d8876d7','f2da34f53148b03bd6ced8a51fb225bafe872c18cd13bf8a6eed29f7b2137742','96d7227db1b1cfad5d3f27ddfc9918df9a56eb8ec9e2d9124aaebeb26b955cf6');
INSERT INTO blocks VALUES(310476,'3712e1ebd195749e0dc92f32f7f451dd76f499bf16d709462309ce358a9370d0',310476000,NULL,NULL,'89d6256d5a7f5412a5eeb9b5551860b7ea26b096a2b8196b61d437ba7ee797f6','aa63b2f948a1e3637f5cc9d2c6f572b7c14fbed98b563171594cf1baaa0d1b36','4bf78927a41c016f6b667147e8ecd6965919cd9ae1dc3335213e0aa9ba3d106d');
INSERT INTO blocks VALUES(310477,'7381973c554ac2bbdc849e8ea8c4a0ecbb46e7967d322446d0d83c3f9deab918',310477000,NULL,NULL,'31e4ee682d84213876eb8d85cb92d32688c4dd9110a9a90d74cfa275b50b8bec','656a2e4672faa65fc57e52915aab2ca2aa145bb1f411ffb2f55d7ddb8f173117','61ad8129da03fa869231bdab5f444e3dd3a4e25bbe205deef5d8790a8d800f64');
INSERT INTO blocks VALUES(310478,'c09ee871af7f2a611d43e6130aed171e301c23c5d1a29d183d40bf15898b4fa0',310478000,NULL,NULL,'941bcbb6d7a89a86859fdc1516c0e64a1473b356f42846d2e8a353b08967fd46','bc67e45d0b4687159c426827cb50588918fd3274a0824bb26203105a843249e5','40463c91834db7e86dc5376d201d6d6cd0e41c30fc8d3392e35f2053331760dd');
INSERT INTO blocks VALUES(310479,'f3d691ce35f62df56d142160b6e2cdcba19d4995c01f802da6ce30bfe8d30030',310479000,NULL,NULL,'8c271f55a292b69f95c50228be57e8a1a91b94998756abd8ce431e657fa4055c','dff4101f248a75e7bca1a560113854f2c45012e2299084ebb23b0f17348862aa','2a9a254f03d7147b32c7f43a623c8c17e0dd8d5a89dff2191fefadd87232ad85');
INSERT INTO blocks VALUES(310480,'2694e89a62b3abd03a38dfd318c05eb5871f1be00a6e1bf06826fd54d142e681',310480000,NULL,NULL,'aa0c833f96cce186008d339452e92d054edd67397c538baac239b10df8f9bcbb','7f44b12ef4363504909c0e6c3e0bb63fd379dc1df4036e5dbc288436d098a135','b72101712a6941aaf39314e7dc2d83ece969a32f758ac8aaa570423a32ffce8a');
INSERT INTO blocks VALUES(310481,'db37d8f98630ebc61767736ae2c523e4e930095bf54259c01de4d36fd60b6f4a',310481000,NULL,NULL,'596ff1cd4069e7a0d62db64acfe1502ca4bfc6d3ac792794ad980c5f654f1a01','6be7792252080dd2c8d9ea9a71095367b449775e79915946daf18f79eb867f7d','d90514b23442bd256d4473dff7810530dd478765f2a6b92778f4a7d0dd0afcdf');
INSERT INTO blocks VALUES(310482,'2e27db87dfb6439c006637734e876cc662d1ca74c717756f90f0e535df0787d6',310482000,NULL,NULL,'bbc1ac936d3ea0f0ab911d79ec003e0ce0c20d6adf507dc5c94a773659b0b734','1781a2e9f1f85a9f0ab09f5b70229cb29e84715afdfd99aef7a8f7874e18496f','d380bb9627ea84dc76bac8a9ce075011a729785fd27e08578ba35eb60d2e736f');
INSERT INTO blocks VALUES(310483,'013bac61f8e33c8d8d0f60f5e6a4ec3de9b16696703dea9802f64a258601c460',310483000,NULL,NULL,'008c287f38d96307ee4a71ea6a8f2c42a35dd54c4a834515d7a44ced43204845','a1c4561e0864927a67e39db85f714f814e765951745f8edf9d3a30b851bad0c0','d2f70f143b62475796ea2859564661e08621f9fd2b5362e14964ec29069f2020');
INSERT INTO blocks VALUES(310484,'7cac2b3630c31b592fa0497792bed58d3c41120c009471c348b16b5578b3aa2b',310484000,NULL,NULL,'d7f3ec5feb14b12b410fa72344620e930037d15cdb36295fc68aa0f4087eb631','07d28aea0aff8e1af48d8ff78d96e251073d440d5ae509d8746e93038a0d28d7','66f400b3dfc689470f89d62572ec47927ff6a7b95382688f8d97c92142e0b9fc');
INSERT INTO blocks VALUES(310485,'eab5febc9668cd438178496417b22da5f77ceaed5bb6e01fc0f04bef1f5b4478',310485000,NULL,NULL,'10856cb1b7625aa217ea3009f10aa1e772a627e302f4191eaba5d332b8daea32','05d8d1c15db16116948feb8f2be5d2e659b731aa9a9849c788c65cfcb201b3e0','160f4b28ca567c322949ce541aaa1550bde75dc8295a3f543140ee47ced53e5e');
INSERT INTO blocks VALUES(310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,NULL,NULL,'d4d08e6c5c0a9d491cd2c754047a78a566a86a0b4ef81c3037a9d438803a0fb6','92fe5ce8461dda58d1041c365d4e614adfa435dc3fbfdda79dbac0c44fc9befb','80560de680c411dc6113ea736ba8e534e946a03024a343bf022ad7cca4fda276');
INSERT INTO blocks VALUES(310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,NULL,NULL,'bca482be2e942516ffc60a62ea7ea7e44158e8f9b72bb6e5dbe61cd740d300bf','ac5aa8b3546c558cc497e74cdc2bc6d0efd6a57108ed015c7e50e4d85f2bf770','786ca1a396b18625ac47e6bffc324c46176a996170a1897ff0efcbffeb62f572');
INSERT INTO blocks VALUES(310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,NULL,NULL,'fd124a3f80b354ca106cd653717837f460b565aa5b4b40dc23ecd56b3b97b28b','be4496de2384fb2de18384b7f5070ede95f80a84a8bb5e1cee57228ac4e5d09c','d226e6b1a7801f9205277536d0f21702464c8bc3b29f3ea8a3048576b3321fd3');
INSERT INTO blocks VALUES(310489,'2efdb36f986b3e3ccc6cc9b0c1c3cdcb07429fb43cbc0cc3b6c87d1b33f258b6',310489000,NULL,NULL,'dc544e57a124565269bbb4b2d9ae2102e6ed177196b07e02d55a9ac99611b752','249764c86ac9f60590f08e1ac3b24021a44e246635947346e78cf4640ce2fa19','3ce99116781fc9670a2f22d5368fec2de450639941167f0b0187eccf602568db');
INSERT INTO blocks VALUES(310490,'e2cb04b8a7368c95359c9d5ff33e64209200fb606de0d64b7c0f67bb1cb8d87c',310490000,NULL,NULL,'8165de494fbcaee2f48f0ed7b671d5a7164b4e4e6198b5e1cd8f88850af150d7','b45c06b6680f7e5f6d7bafec1986bb98d64f002fc063f797cd6619e39d6a60e8','1cf9a7a63e85b909993c3b893bd0e8d54ba6c2e19b3a5fb8f6873c3ee4816756');
INSERT INTO blocks VALUES(310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,NULL,NULL,'953105bd7e2e93c74ed3ed8b8717d7238d636a0cc4e50d152a1783aa5f320204','6cd351d240c2222911605d94637d2dc9527b54eb4cd090459ecb3293b3fb4377','e08a9aabdae34e9f5799e1d617da707e75a177c3cf72e4ccb1cea843ff6374f1');
INSERT INTO blocks VALUES(310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,NULL,NULL,'1fed308916a5912e8b0166d5a27ce74e23ddddcfd3f7b99ed77a01ff398142e1','99043b364fd7496c2c647118a862c636e7a7cc1e70d9dbd9525c98695432db90','c6df9314d70e80f573235e5c311659a6c2ba9e87feea58231439bc373516de10');
INSERT INTO blocks VALUES(310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,NULL,NULL,'c0136baee1305a5e5a933fa78f2f93cb40d06adf04540c94dab3c085208e1d25','b03ea0bfe1386b97591a673159153e92cc3d87137ccbcdec29e0129dde68a689','a85dbd1d997d9a0bcd066da06703626c3a502a915e321686699d0b8e516827eb');
INSERT INTO blocks VALUES(310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,NULL,NULL,'7e6e5551f8eaa241d3289fcae360170937aa4a35f2926611ab50793b7cbf1b30','d6bdcdab339aac9fb029aa351e4215285feb1b6319802adc450246ebd3a652b2','ecebc7728d1ddbe2aa24162164601e18c1fa5b5dbc5488b7fc848ac52c8f74c4');
INSERT INTO blocks VALUES(310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,NULL,NULL,'0b40890a253248a31cf00d2f75abcbc9871318364ec224ce94cd5c6d29b15621','c68488911b197d3ea7d166ae35b5ff31172b4eb595b009fc49f87c194e0722a4','b5ef7e836597581012fc07017e81de9e5ade6771ba42e49347f3a5028da69ee8');
INSERT INTO blocks VALUES(310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,NULL,NULL,'88aaf1b7f8cce768bb3744e68017b52fa82999dc6ababf7c0cab9621f9ab4160','35f46ed15bd0f1d6fd30c535cab7d75ee749f1d031a4cd2284e437f7ac8287a4','f08d19ea353d141c9508b76dd19cd16305105b0e8fa8790f84488234d46594c2');
INSERT INTO blocks VALUES(310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,NULL,NULL,'e59e7a3224fc64320bc9b6fc3c3c4661cc9bc5664be9b9228e2dee585aef1c9c','d686b0e1d9707f748d0c638d9957c214a7213037b8ce5d50bf86ae74b276e4ca','4a1d9a1a15b7454c2ed37c015fe610f0e21d389a13177275a506bc60d0d67bd1');
INSERT INTO blocks VALUES(310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,NULL,NULL,'f4706664a1f25bba7cbd6066a363b8cdec56eb30fda7fcb14ba5edba4913b166','3829028994c606357448ec2ef4839343fbe1a9dba141c346f51639f31b395dde','774f5a9ae200d5d7bca9b8b401d92fbf03a8efa2aa2167f314584fd384ff4bb0');
INSERT INTO blocks VALUES(310499,'1950e1a4d7fc820ed9603f6df6819c3c953c277c726340dec2a4253e261a1764',310499000,NULL,NULL,'f20bbd39329e3beeb339faa2342de45dcd59a6c032ea945ba10e5fa0b9b263c5','819aa98fda7703cbee8117833863527f5a3fce8d1ac4dae2db789eaae005b93a','e401cb171e2f8e178ae251c815334ce5a94bf7d0eecda189054e980eb7aa6781');
INSERT INTO blocks VALUES(310500,'54aeaf47d5387964e2d51617bf3af50520a0449410e0d096cf8c2aa9dad5550b',310500000,NULL,NULL,'d32f6e610de4c09918a4272f0904e3e5ed3638fbeb4088c877dfb9f51a1b62dc','d204b411e22b29b4fc30de13d2c458397b6d20a761de355862b96abba7b6d55e','eaa37453f6a910d4c8d5f304a0db162a9604790caa2b11341ea682ebbdaeaf55');
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
INSERT INTO broadcasts VALUES(18,'c23815ab2f8fa0ff8a43bb35cb8e4249fa7986a45b0b761b8fa654876772f8bd',310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000000,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(19,'badb232b510fc70d33b241ed591d448848a424a9669b600f7e3b47454726c977',310018,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',0,NULL,NULL,NULL,1,'valid');
INSERT INTO broadcasts VALUES(103,'da14c69e2e3363b069527d936ed82e5aaff61c3060df97b0f3a4eb8af47454f0',310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000002,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(110,'ba3fe575883978cb0b79969b2f3c5268ef7b2fc7a90f6461d3ed33fbc30c90b3',310109,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',1388000002,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(487,'81a5d20db79a4b620221ba646fec2699b4e4d1c854bb4022b0550bd7d274a5b8',310486,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',1388000000,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(489,'b61f2f7e43e6696ca5b804e9c21e61616257b561e69d3cc6cf45af1e1cac3deb',310488,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',0,NULL,NULL,NULL,1,'valid');
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
INSERT INTO burns VALUES(1,'77f08141941118b414589e9affe2b15dea5dbe8139a52cd26083f25c1f87c6eb',310000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',62000000,93000000000,'valid');
INSERT INTO burns VALUES(104,'72a78ce826f2a0a78a811366d419a1585c93b207f29be48aa09eec00a2088a90',310103,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',62000000,92999138821,'valid');
INSERT INTO burns VALUES(105,'f0fc998a26684434405080655b8af2dec39c25544e5da36e60fe8711bd2f95ec',310104,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b',62000000,92999130460,'valid');
INSERT INTO burns VALUES(106,'cbdc121b6134889a6b6809c9f4134b9d3ed26cca35401efe1f512eab49e32284',310105,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',62000000,92999122099,'valid');
INSERT INTO burns VALUES(107,'9ef49fc15392479177a27cdb04734d984e52a04b2453d8f83bcfbbcb5aaf0dfa',310106,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',31000000,46499556869,'valid');
INSERT INTO burns VALUES(494,'0d88550e8361676614215372d3482d7749ddfe81d12fff58ce80a598dd0d368d',310493,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',62000000,92995878046,'valid');
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
INSERT INTO credits VALUES(310000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',93000000000,'burn','77f08141941118b414589e9affe2b15dea5dbe8139a52cd26083f25c1f87c6eb');
INSERT INTO credits VALUES(310001,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000000,'issuance','a68768e0a44a119cb48124b3f11f2a03e2f738a86a539aa9beb93596092d1edf');
INSERT INTO credits VALUES(310002,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','NODIVISIBLE',1000,'issuance','25e8108a67011db1a409e52fc3d73511d08a5078ad73e06b7dfefb90a8b6a70f');
INSERT INTO credits VALUES(310003,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','CALLABLE',1000,'issuance','227d51e90a5921551dff2554d81439718718afbd0b9a7efd2d8ec713497bdf3d');
INSERT INTO credits VALUES(310004,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','LOCKED',1000,'issuance','b5c6258164bca06c567dfe0b26b156812c34819c6ff538f9c1ee01bd071a3203');
INSERT INTO credits VALUES(310007,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','DIVISIBLE',100000000,'send','bdb55efb18b339207aa6483329a803fda6248e8bcf68b819708445d2c719f43d');
INSERT INTO credits VALUES(310008,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'send','663e6e10810403876bf8d5c1bc8715a44c82bfb4a2e5e98fa63ab65fc04cc55b');
INSERT INTO credits VALUES(310012,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',300000000,'send','631f6b5166129fd3d69dbd4a8096707d61942acb55fd2100547a39d53bd8b5b6');
INSERT INTO credits VALUES(310013,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','DIVISIBLE',1000000000,'send','c91791d284a75383678ee71817775bbdfa7e22ffbbc561dbe782614121e625a5');
INSERT INTO credits VALUES(310014,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','NODIVISIBLE',5,'send','c3875a3cc9c8c967f8ff0accbc37f728e0bb038672c2cb19325ddb6bdb53465d');
INSERT INTO credits VALUES(310015,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','NODIVISIBLE',10,'send','f74ffb36b1ca86e0dc9305f31671c3866817fe575463cc8b982174a19f349746');
INSERT INTO credits VALUES(310016,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','MAXI',9223372036854775807,'issuance','f6dbe255b8028a2917fff031b6d203d0822e71583432c6ba1509713db8f6dee6');
INSERT INTO credits VALUES(310020,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','0590f213f0549ecf353969f9ec8140b6ecd4b67f9d2912cd58ec6b4b1b756a20');
INSERT INTO credits VALUES(310020,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',0,'filled','0590f213f0549ecf353969f9ec8140b6ecd4b67f9d2912cd58ec6b4b1b756a20');
INSERT INTO credits VALUES(310102,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',9,'bet settled','da14c69e2e3363b069527d936ed82e5aaff61c3060df97b0f3a4eb8af47454f0');
INSERT INTO credits VALUES(310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',9,'bet settled','da14c69e2e3363b069527d936ed82e5aaff61c3060df97b0f3a4eb8af47454f0');
INSERT INTO credits VALUES(310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'feed fee','da14c69e2e3363b069527d936ed82e5aaff61c3060df97b0f3a4eb8af47454f0');
INSERT INTO credits VALUES(310103,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','XCP',92999138821,'burn','72a78ce826f2a0a78a811366d419a1585c93b207f29be48aa09eec00a2088a90');
INSERT INTO credits VALUES(310104,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','XCP',92999130460,'burn','f0fc998a26684434405080655b8af2dec39c25544e5da36e60fe8711bd2f95ec');
INSERT INTO credits VALUES(310105,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',92999122099,'burn','cbdc121b6134889a6b6809c9f4134b9d3ed26cca35401efe1f512eab49e32284');
INSERT INTO credits VALUES(310106,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',46499556869,'burn','9ef49fc15392479177a27cdb04734d984e52a04b2453d8f83bcfbbcb5aaf0dfa');
INSERT INTO credits VALUES(310107,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','PAYTOSCRIPT',1000,'issuance','89ed806602d4e0c260a88c76b1bfcc0c17c993b04678da155369525f854c9105');
INSERT INTO credits VALUES(310108,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000,'send','5776bcda35a58d001e71552bc6fd2de3764495ce50f16b3b806a986935ca5520');
INSERT INTO credits VALUES(310493,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',92995878046,'burn','0d88550e8361676614215372d3482d7749ddfe81d12fff58ce80a598dd0d368d');
INSERT INTO credits VALUES(310494,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','DIVIDEND',100,'issuance','89f7e46840b55a8134ca6950f804862a5a89fbc07dfa223300a07daeaad9719f');
INSERT INTO credits VALUES(310495,'mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','DIVIDEND',10,'send','3c3e750a0a8f27fba67480957f85907f22a52d45385132d73d7fdc1c8e38107d');
INSERT INTO credits VALUES(310496,'mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','XCP',92945878046,'send','478048dcdaca3e8010fc50a75511f6ed8fc1a770a4fab5c339a1c15c3633971f');
INSERT INTO credits VALUES(310497,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','PARENT',100000000,'issuance','b1a5f2dd0e4c14a093ba5353f8944fa6ccd64f21b7626b5e225deea9f6cc7470');
INSERT INTO credits VALUES(310498,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','A95428956661682277',100000000,'issuance','2aabeff2dd379ed8d9d1400adcf6f7a375cad02aafc9de1268054839a5110d16');
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
INSERT INTO debits VALUES(310001,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','a68768e0a44a119cb48124b3f11f2a03e2f738a86a539aa9beb93596092d1edf');
INSERT INTO debits VALUES(310002,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','25e8108a67011db1a409e52fc3d73511d08a5078ad73e06b7dfefb90a8b6a70f');
INSERT INTO debits VALUES(310003,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','227d51e90a5921551dff2554d81439718718afbd0b9a7efd2d8ec713497bdf3d');
INSERT INTO debits VALUES(310004,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','b5c6258164bca06c567dfe0b26b156812c34819c6ff538f9c1ee01bd071a3203');
INSERT INTO debits VALUES(310005,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'issuance fee','84e607982e4aae1edbc0f1a02171e06ba335e30817779425ce570e26af2b5316');
INSERT INTO debits VALUES(310006,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','969baaf1c366379930e994259ec1bbc4129a06ddd7e1393f431dcee2c279c798');
INSERT INTO debits VALUES(310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000,'send','bdb55efb18b339207aa6483329a803fda6248e8bcf68b819708445d2c719f43d');
INSERT INTO debits VALUES(310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'send','663e6e10810403876bf8d5c1bc8715a44c82bfb4a2e5e98fa63ab65fc04cc55b');
INSERT INTO debits VALUES(310009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','bf97aaeecda40cc1842da334c232526a5eea7219239bf03205a7fc19eaa82992');
INSERT INTO debits VALUES(310010,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','9a2ca3ff0e914c37ff63235b2679301f15da2621d717744befc7b8e21227ef87');
INSERT INTO debits VALUES(310012,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',300000000,'send','631f6b5166129fd3d69dbd4a8096707d61942acb55fd2100547a39d53bd8b5b6');
INSERT INTO debits VALUES(310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',1000000000,'send','c91791d284a75383678ee71817775bbdfa7e22ffbbc561dbe782614121e625a5');
INSERT INTO debits VALUES(310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','NODIVISIBLE',5,'send','c3875a3cc9c8c967f8ff0accbc37f728e0bb038672c2cb19325ddb6bdb53465d');
INSERT INTO debits VALUES(310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','NODIVISIBLE',10,'send','f74ffb36b1ca86e0dc9305f31671c3866817fe575463cc8b982174a19f349746');
INSERT INTO debits VALUES(310016,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','f6dbe255b8028a2917fff031b6d203d0822e71583432c6ba1509713db8f6dee6');
INSERT INTO debits VALUES(310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',9,'bet','bf4cbb16b58a03c1f715e7dacf49f20bd184d9f197756b7977135241fd708cb3');
INSERT INTO debits VALUES(310020,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',9,'bet','0590f213f0549ecf353969f9ec8140b6ecd4b67f9d2912cd58ec6b4b1b756a20');
INSERT INTO debits VALUES(310101,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',10,'bet','01e52b7501ff34946978d395da5b6b03032bc6a4336b007a4fe0456a19a334b1');
INSERT INTO debits VALUES(310107,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',50000000,'issuance fee','89ed806602d4e0c260a88c76b1bfcc0c17c993b04678da155369525f854c9105');
INSERT INTO debits VALUES(310108,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000,'send','5776bcda35a58d001e71552bc6fd2de3764495ce50f16b3b806a986935ca5520');
INSERT INTO debits VALUES(310110,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',10,'bet','0c690d46bef903922354520c8c8626ab5bfd45da1ca211d65f16aeef9b5f3300');
INSERT INTO debits VALUES(310487,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','XCP',9,'bet','c9cfc39f98307a845d1d27d4a9ad66b19e0c38f59be14ed0c4b9d4ec15cb0940');
INSERT INTO debits VALUES(310491,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7');
INSERT INTO debits VALUES(310494,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',50000000,'issuance fee','89f7e46840b55a8134ca6950f804862a5a89fbc07dfa223300a07daeaad9719f');
INSERT INTO debits VALUES(310495,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','DIVIDEND',10,'send','3c3e750a0a8f27fba67480957f85907f22a52d45385132d73d7fdc1c8e38107d');
INSERT INTO debits VALUES(310496,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',92945878046,'send','478048dcdaca3e8010fc50a75511f6ed8fc1a770a4fab5c339a1c15c3633971f');
INSERT INTO debits VALUES(310497,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','b1a5f2dd0e4c14a093ba5353f8944fa6ccd64f21b7626b5e225deea9f6cc7470');
INSERT INTO debits VALUES(310498,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',25000000,'issuance fee','2aabeff2dd379ed8d9d1400adcf6f7a375cad02aafc9de1268054839a5110d16');
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
INSERT INTO issuances VALUES(2,'a68768e0a44a119cb48124b3f11f2a03e2f738a86a539aa9beb93596092d1edf',310001,'DIVISIBLE',100000000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Divisible asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(3,'25e8108a67011db1a409e52fc3d73511d08a5078ad73e06b7dfefb90a8b6a70f',310002,'NODIVISIBLE',1000,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'No divisible asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(4,'227d51e90a5921551dff2554d81439718718afbd0b9a7efd2d8ec713497bdf3d',310003,'CALLABLE',1000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Callable asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(5,'b5c6258164bca06c567dfe0b26b156812c34819c6ff538f9c1ee01bd071a3203',310004,'LOCKED',1000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Locked asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(6,'84e607982e4aae1edbc0f1a02171e06ba335e30817779425ce570e26af2b5316',310005,'LOCKED',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Locked asset',0,1,'valid',NULL);
INSERT INTO issuances VALUES(17,'f6dbe255b8028a2917fff031b6d203d0822e71583432c6ba1509713db8f6dee6',310016,'MAXI',9223372036854775807,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Maximum quantity',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(108,'89ed806602d4e0c260a88c76b1bfcc0c17c993b04678da155369525f854c9105',310107,'PAYTOSCRIPT',1000,0,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',0,0,0,0.0,'PSH issued asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(495,'89f7e46840b55a8134ca6950f804862a5a89fbc07dfa223300a07daeaad9719f',310494,'DIVIDEND',100,1,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',0,0,0,0.0,'Test dividend',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(498,'b1a5f2dd0e4c14a093ba5353f8944fa6ccd64f21b7626b5e225deea9f6cc7470',310497,'PARENT',100000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Parent asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(499,'2aabeff2dd379ed8d9d1400adcf6f7a375cad02aafc9de1268054839a5110d16',310498,'A95428956661682277',100000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Child of parent',25000000,0,'valid','PARENT.already.issued');
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
INSERT INTO messages VALUES(0,310000,'insert','credits','{"action": "burn", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310000, "event": "77f08141941118b414589e9affe2b15dea5dbe8139a52cd26083f25c1f87c6eb", "quantity": 93000000000}',0);
INSERT INTO messages VALUES(1,310000,'insert','burns','{"block_index": 310000, "burned": 62000000, "earned": 93000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "77f08141941118b414589e9affe2b15dea5dbe8139a52cd26083f25c1f87c6eb", "tx_index": 1}',0);
INSERT INTO messages VALUES(2,310001,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310001, "event": "a68768e0a44a119cb48124b3f11f2a03e2f738a86a539aa9beb93596092d1edf", "quantity": 50000000}',0);
INSERT INTO messages VALUES(3,310001,'insert','issuances','{"asset": "DIVISIBLE", "asset_longname": null, "block_index": 310001, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Divisible asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "a68768e0a44a119cb48124b3f11f2a03e2f738a86a539aa9beb93596092d1edf", "tx_index": 2}',0);
INSERT INTO messages VALUES(4,310001,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 310001, "event": "a68768e0a44a119cb48124b3f11f2a03e2f738a86a539aa9beb93596092d1edf", "quantity": 100000000000}',0);
INSERT INTO messages VALUES(5,310002,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310002, "event": "25e8108a67011db1a409e52fc3d73511d08a5078ad73e06b7dfefb90a8b6a70f", "quantity": 50000000}',0);
INSERT INTO messages VALUES(6,310002,'insert','issuances','{"asset": "NODIVISIBLE", "asset_longname": null, "block_index": 310002, "call_date": 0, "call_price": 0.0, "callable": false, "description": "No divisible asset", "divisible": false, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "25e8108a67011db1a409e52fc3d73511d08a5078ad73e06b7dfefb90a8b6a70f", "tx_index": 3}',0);
INSERT INTO messages VALUES(7,310002,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "NODIVISIBLE", "block_index": 310002, "event": "25e8108a67011db1a409e52fc3d73511d08a5078ad73e06b7dfefb90a8b6a70f", "quantity": 1000}',0);
INSERT INTO messages VALUES(8,310003,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310003, "event": "227d51e90a5921551dff2554d81439718718afbd0b9a7efd2d8ec713497bdf3d", "quantity": 50000000}',0);
INSERT INTO messages VALUES(9,310003,'insert','issuances','{"asset": "CALLABLE", "asset_longname": null, "block_index": 310003, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Callable asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "227d51e90a5921551dff2554d81439718718afbd0b9a7efd2d8ec713497bdf3d", "tx_index": 4}',0);
INSERT INTO messages VALUES(10,310003,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "CALLABLE", "block_index": 310003, "event": "227d51e90a5921551dff2554d81439718718afbd0b9a7efd2d8ec713497bdf3d", "quantity": 1000}',0);
INSERT INTO messages VALUES(11,310004,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310004, "event": "b5c6258164bca06c567dfe0b26b156812c34819c6ff538f9c1ee01bd071a3203", "quantity": 50000000}',0);
INSERT INTO messages VALUES(12,310004,'insert','issuances','{"asset": "LOCKED", "asset_longname": null, "block_index": 310004, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Locked asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "b5c6258164bca06c567dfe0b26b156812c34819c6ff538f9c1ee01bd071a3203", "tx_index": 5}',0);
INSERT INTO messages VALUES(13,310004,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "LOCKED", "block_index": 310004, "event": "b5c6258164bca06c567dfe0b26b156812c34819c6ff538f9c1ee01bd071a3203", "quantity": 1000}',0);
INSERT INTO messages VALUES(14,310005,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310005, "event": "84e607982e4aae1edbc0f1a02171e06ba335e30817779425ce570e26af2b5316", "quantity": 0}',0);
INSERT INTO messages VALUES(15,310005,'insert','issuances','{"asset": "LOCKED", "asset_longname": null, "block_index": 310005, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Locked asset", "divisible": true, "fee_paid": 0, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": true, "quantity": 0, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "84e607982e4aae1edbc0f1a02171e06ba335e30817779425ce570e26af2b5316", "tx_index": 6}',0);
INSERT INTO messages VALUES(16,310006,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310006, "event": "969baaf1c366379930e994259ec1bbc4129a06ddd7e1393f431dcee2c279c798", "quantity": 100000000}',0);
INSERT INTO messages VALUES(17,310006,'insert','orders','{"block_index": 310006, "expiration": 2000, "expire_index": 312006, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "DIVISIBLE", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "969baaf1c366379930e994259ec1bbc4129a06ddd7e1393f431dcee2c279c798", "tx_index": 7}',0);
INSERT INTO messages VALUES(18,310007,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 310007, "event": "bdb55efb18b339207aa6483329a803fda6248e8bcf68b819708445d2c719f43d", "quantity": 100000000}',0);
INSERT INTO messages VALUES(19,310007,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "DIVISIBLE", "block_index": 310007, "event": "bdb55efb18b339207aa6483329a803fda6248e8bcf68b819708445d2c719f43d", "quantity": 100000000}',0);
INSERT INTO messages VALUES(20,310007,'insert','sends','{"asset": "DIVISIBLE", "block_index": 310007, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "bdb55efb18b339207aa6483329a803fda6248e8bcf68b819708445d2c719f43d", "tx_index": 8}',0);
INSERT INTO messages VALUES(21,310008,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310008, "event": "663e6e10810403876bf8d5c1bc8715a44c82bfb4a2e5e98fa63ab65fc04cc55b", "quantity": 100000000}',0);
INSERT INTO messages VALUES(22,310008,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310008, "event": "663e6e10810403876bf8d5c1bc8715a44c82bfb4a2e5e98fa63ab65fc04cc55b", "quantity": 100000000}',0);
INSERT INTO messages VALUES(23,310008,'insert','sends','{"asset": "XCP", "block_index": 310008, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "663e6e10810403876bf8d5c1bc8715a44c82bfb4a2e5e98fa63ab65fc04cc55b", "tx_index": 9}',0);
INSERT INTO messages VALUES(24,310009,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310009, "event": "bf97aaeecda40cc1842da334c232526a5eea7219239bf03205a7fc19eaa82992", "quantity": 100000000}',0);
INSERT INTO messages VALUES(25,310009,'insert','orders','{"block_index": 310009, "expiration": 2000, "expire_index": 312009, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "DIVISIBLE", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "bf97aaeecda40cc1842da334c232526a5eea7219239bf03205a7fc19eaa82992", "tx_index": 10}',0);
INSERT INTO messages VALUES(26,310010,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310010, "event": "9a2ca3ff0e914c37ff63235b2679301f15da2621d717744befc7b8e21227ef87", "quantity": 100000000}',0);
INSERT INTO messages VALUES(27,310010,'insert','orders','{"block_index": 310010, "expiration": 2000, "expire_index": 312010, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 1000000, "get_remaining": 1000000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "9a2ca3ff0e914c37ff63235b2679301f15da2621d717744befc7b8e21227ef87", "tx_index": 11}',0);
INSERT INTO messages VALUES(28,310011,'insert','orders','{"block_index": 310011, "expiration": 2000, "expire_index": 312011, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 666667, "give_remaining": 666667, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "8a63e7a516d36c17ac32999222ac282ab94fb9c5ea30637cd06660b3139510f6", "tx_index": 12}',0);
INSERT INTO messages VALUES(29,310012,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310012, "event": "631f6b5166129fd3d69dbd4a8096707d61942acb55fd2100547a39d53bd8b5b6", "quantity": 300000000}',0);
INSERT INTO messages VALUES(30,310012,'insert','credits','{"action": "send", "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310012, "event": "631f6b5166129fd3d69dbd4a8096707d61942acb55fd2100547a39d53bd8b5b6", "quantity": 300000000}',0);
INSERT INTO messages VALUES(31,310012,'insert','sends','{"asset": "XCP", "block_index": 310012, "destination": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "quantity": 300000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "631f6b5166129fd3d69dbd4a8096707d61942acb55fd2100547a39d53bd8b5b6", "tx_index": 13}',0);
INSERT INTO messages VALUES(32,310013,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 310013, "event": "c91791d284a75383678ee71817775bbdfa7e22ffbbc561dbe782614121e625a5", "quantity": 1000000000}',0);
INSERT INTO messages VALUES(33,310013,'insert','credits','{"action": "send", "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "DIVISIBLE", "block_index": 310013, "event": "c91791d284a75383678ee71817775bbdfa7e22ffbbc561dbe782614121e625a5", "quantity": 1000000000}',0);
INSERT INTO messages VALUES(34,310013,'insert','sends','{"asset": "DIVISIBLE", "block_index": 310013, "destination": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "quantity": 1000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "c91791d284a75383678ee71817775bbdfa7e22ffbbc561dbe782614121e625a5", "tx_index": 14}',0);
INSERT INTO messages VALUES(35,310014,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "NODIVISIBLE", "block_index": 310014, "event": "c3875a3cc9c8c967f8ff0accbc37f728e0bb038672c2cb19325ddb6bdb53465d", "quantity": 5}',0);
INSERT INTO messages VALUES(36,310014,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "NODIVISIBLE", "block_index": 310014, "event": "c3875a3cc9c8c967f8ff0accbc37f728e0bb038672c2cb19325ddb6bdb53465d", "quantity": 5}',0);
INSERT INTO messages VALUES(37,310014,'insert','sends','{"asset": "NODIVISIBLE", "block_index": 310014, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 5, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "c3875a3cc9c8c967f8ff0accbc37f728e0bb038672c2cb19325ddb6bdb53465d", "tx_index": 15}',0);
INSERT INTO messages VALUES(38,310015,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "NODIVISIBLE", "block_index": 310015, "event": "f74ffb36b1ca86e0dc9305f31671c3866817fe575463cc8b982174a19f349746", "quantity": 10}',0);
INSERT INTO messages VALUES(39,310015,'insert','credits','{"action": "send", "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "NODIVISIBLE", "block_index": 310015, "event": "f74ffb36b1ca86e0dc9305f31671c3866817fe575463cc8b982174a19f349746", "quantity": 10}',0);
INSERT INTO messages VALUES(40,310015,'insert','sends','{"asset": "NODIVISIBLE", "block_index": 310015, "destination": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "quantity": 10, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "f74ffb36b1ca86e0dc9305f31671c3866817fe575463cc8b982174a19f349746", "tx_index": 16}',0);
INSERT INTO messages VALUES(41,310016,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310016, "event": "f6dbe255b8028a2917fff031b6d203d0822e71583432c6ba1509713db8f6dee6", "quantity": 50000000}',0);
INSERT INTO messages VALUES(42,310016,'insert','issuances','{"asset": "MAXI", "asset_longname": null, "block_index": 310016, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Maximum quantity", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 9223372036854775807, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "f6dbe255b8028a2917fff031b6d203d0822e71583432c6ba1509713db8f6dee6", "tx_index": 17}',0);
INSERT INTO messages VALUES(43,310016,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "MAXI", "block_index": 310016, "event": "f6dbe255b8028a2917fff031b6d203d0822e71583432c6ba1509713db8f6dee6", "quantity": 9223372036854775807}',0);
INSERT INTO messages VALUES(44,310017,'insert','broadcasts','{"block_index": 310017, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "c23815ab2f8fa0ff8a43bb35cb8e4249fa7986a45b0b761b8fa654876772f8bd", "tx_index": 18, "value": 1.0}',0);
INSERT INTO messages VALUES(45,310018,'insert','broadcasts','{"block_index": 310018, "fee_fraction_int": null, "locked": true, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "text": null, "timestamp": 0, "tx_hash": "badb232b510fc70d33b241ed591d448848a424a9669b600f7e3b47454726c977", "tx_index": 19, "value": null}',0);
INSERT INTO messages VALUES(46,310019,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310019, "event": "bf4cbb16b58a03c1f715e7dacf49f20bd184d9f197756b7977135241fd708cb3", "quantity": 9}',0);
INSERT INTO messages VALUES(47,310019,'insert','bets','{"bet_type": 1, "block_index": 310019, "counterwager_quantity": 9, "counterwager_remaining": 9, "deadline": 1388000001, "expiration": 100, "expire_index": 310119, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "bf4cbb16b58a03c1f715e7dacf49f20bd184d9f197756b7977135241fd708cb3", "tx_index": 20, "wager_quantity": 9, "wager_remaining": 9}',0);
INSERT INTO messages VALUES(48,310020,'insert','debits','{"action": "bet", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310020, "event": "0590f213f0549ecf353969f9ec8140b6ecd4b67f9d2912cd58ec6b4b1b756a20", "quantity": 9}',0);
INSERT INTO messages VALUES(49,310020,'insert','bets','{"bet_type": 0, "block_index": 310020, "counterwager_quantity": 9, "counterwager_remaining": 9, "deadline": 1388000001, "expiration": 100, "expire_index": 310120, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "target_value": 0.0, "tx_hash": "0590f213f0549ecf353969f9ec8140b6ecd4b67f9d2912cd58ec6b4b1b756a20", "tx_index": 21, "wager_quantity": 9, "wager_remaining": 9}',0);
INSERT INTO messages VALUES(50,310020,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310020, "event": "0590f213f0549ecf353969f9ec8140b6ecd4b67f9d2912cd58ec6b4b1b756a20", "quantity": 0}',0);
INSERT INTO messages VALUES(51,310020,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "bf4cbb16b58a03c1f715e7dacf49f20bd184d9f197756b7977135241fd708cb3", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(52,310020,'insert','credits','{"action": "filled", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310020, "event": "0590f213f0549ecf353969f9ec8140b6ecd4b67f9d2912cd58ec6b4b1b756a20", "quantity": 0}',0);
INSERT INTO messages VALUES(53,310020,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "0590f213f0549ecf353969f9ec8140b6ecd4b67f9d2912cd58ec6b4b1b756a20", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(54,310020,'insert','bet_matches','{"backward_quantity": 9, "block_index": 310020, "deadline": 1388000001, "fee_fraction_int": 5000000, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 9, "id": "bf4cbb16b58a03c1f715e7dacf49f20bd184d9f197756b7977135241fd708cb3_0590f213f0549ecf353969f9ec8140b6ecd4b67f9d2912cd58ec6b4b1b756a20", "initial_value": 1.0, "leverage": 5040, "match_expire_index": 310119, "status": "pending", "target_value": 0.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 1, "tx0_block_index": 310019, "tx0_expiration": 100, "tx0_hash": "bf4cbb16b58a03c1f715e7dacf49f20bd184d9f197756b7977135241fd708cb3", "tx0_index": 20, "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_bet_type": 0, "tx1_block_index": 310020, "tx1_expiration": 100, "tx1_hash": "0590f213f0549ecf353969f9ec8140b6ecd4b67f9d2912cd58ec6b4b1b756a20", "tx1_index": 21}',0);
INSERT INTO messages VALUES(55,310101,'insert','debits','{"action": "bet", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310101, "event": "01e52b7501ff34946978d395da5b6b03032bc6a4336b007a4fe0456a19a334b1", "quantity": 10}',0);
INSERT INTO messages VALUES(56,310101,'insert','bets','{"bet_type": 3, "block_index": 310101, "counterwager_quantity": 10, "counterwager_remaining": 10, "deadline": 1388000200, "expiration": 1000, "expire_index": 311101, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "target_value": 0.0, "tx_hash": "01e52b7501ff34946978d395da5b6b03032bc6a4336b007a4fe0456a19a334b1", "tx_index": 102, "wager_quantity": 10, "wager_remaining": 10}',0);
INSERT INTO messages VALUES(57,310102,'insert','broadcasts','{"block_index": 310102, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000002, "tx_hash": "da14c69e2e3363b069527d936ed82e5aaff61c3060df97b0f3a4eb8af47454f0", "tx_index": 103, "value": 1.0}',0);
INSERT INTO messages VALUES(58,310102,'insert','credits','{"action": "bet settled", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310102, "event": "da14c69e2e3363b069527d936ed82e5aaff61c3060df97b0f3a4eb8af47454f0", "quantity": 9}',0);
INSERT INTO messages VALUES(59,310102,'insert','credits','{"action": "bet settled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310102, "event": "da14c69e2e3363b069527d936ed82e5aaff61c3060df97b0f3a4eb8af47454f0", "quantity": 9}',0);
INSERT INTO messages VALUES(60,310102,'insert','credits','{"action": "feed fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310102, "event": "da14c69e2e3363b069527d936ed82e5aaff61c3060df97b0f3a4eb8af47454f0", "quantity": 0}',0);
INSERT INTO messages VALUES(61,310102,'insert','bet_match_resolutions','{"bear_credit": 9, "bet_match_id": "bf4cbb16b58a03c1f715e7dacf49f20bd184d9f197756b7977135241fd708cb3_0590f213f0549ecf353969f9ec8140b6ecd4b67f9d2912cd58ec6b4b1b756a20", "bet_match_type_id": 1, "block_index": 310102, "bull_credit": 9, "escrow_less_fee": null, "fee": 0, "settled": true, "winner": null}',0);
INSERT INTO messages VALUES(62,310102,'update','bet_matches','{"bet_match_id": "bf4cbb16b58a03c1f715e7dacf49f20bd184d9f197756b7977135241fd708cb3_0590f213f0549ecf353969f9ec8140b6ecd4b67f9d2912cd58ec6b4b1b756a20", "status": "settled"}',0);
INSERT INTO messages VALUES(63,310103,'insert','credits','{"action": "burn", "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "asset": "XCP", "block_index": 310103, "event": "72a78ce826f2a0a78a811366d419a1585c93b207f29be48aa09eec00a2088a90", "quantity": 92999138821}',0);
INSERT INTO messages VALUES(64,310103,'insert','burns','{"block_index": 310103, "burned": 62000000, "earned": 92999138821, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "tx_hash": "72a78ce826f2a0a78a811366d419a1585c93b207f29be48aa09eec00a2088a90", "tx_index": 104}',0);
INSERT INTO messages VALUES(65,310104,'insert','credits','{"action": "burn", "address": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b", "asset": "XCP", "block_index": 310104, "event": "f0fc998a26684434405080655b8af2dec39c25544e5da36e60fe8711bd2f95ec", "quantity": 92999130460}',0);
INSERT INTO messages VALUES(66,310104,'insert','burns','{"block_index": 310104, "burned": 62000000, "earned": 92999130460, "source": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b", "status": "valid", "tx_hash": "f0fc998a26684434405080655b8af2dec39c25544e5da36e60fe8711bd2f95ec", "tx_index": 105}',0);
INSERT INTO messages VALUES(67,310105,'insert','credits','{"action": "burn", "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "asset": "XCP", "block_index": 310105, "event": "cbdc121b6134889a6b6809c9f4134b9d3ed26cca35401efe1f512eab49e32284", "quantity": 92999122099}',0);
INSERT INTO messages VALUES(68,310105,'insert','burns','{"block_index": 310105, "burned": 62000000, "earned": 92999122099, "source": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "status": "valid", "tx_hash": "cbdc121b6134889a6b6809c9f4134b9d3ed26cca35401efe1f512eab49e32284", "tx_index": 106}',0);
INSERT INTO messages VALUES(69,310106,'insert','credits','{"action": "burn", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "XCP", "block_index": 310106, "event": "9ef49fc15392479177a27cdb04734d984e52a04b2453d8f83bcfbbcb5aaf0dfa", "quantity": 46499556869}',0);
INSERT INTO messages VALUES(70,310106,'insert','burns','{"block_index": 310106, "burned": 31000000, "earned": 46499556869, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "valid", "tx_hash": "9ef49fc15392479177a27cdb04734d984e52a04b2453d8f83bcfbbcb5aaf0dfa", "tx_index": 107}',0);
INSERT INTO messages VALUES(71,310107,'insert','debits','{"action": "issuance fee", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "XCP", "block_index": 310107, "event": "89ed806602d4e0c260a88c76b1bfcc0c17c993b04678da155369525f854c9105", "quantity": 50000000}',0);
INSERT INTO messages VALUES(72,310107,'insert','issuances','{"asset": "PAYTOSCRIPT", "asset_longname": null, "block_index": 310107, "call_date": 0, "call_price": 0.0, "callable": false, "description": "PSH issued asset", "divisible": false, "fee_paid": 50000000, "issuer": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "locked": false, "quantity": 1000, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "valid", "transfer": false, "tx_hash": "89ed806602d4e0c260a88c76b1bfcc0c17c993b04678da155369525f854c9105", "tx_index": 108}',0);
INSERT INTO messages VALUES(73,310107,'insert','credits','{"action": "issuance", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "PAYTOSCRIPT", "block_index": 310107, "event": "89ed806602d4e0c260a88c76b1bfcc0c17c993b04678da155369525f854c9105", "quantity": 1000}',0);
INSERT INTO messages VALUES(74,310108,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 310108, "event": "5776bcda35a58d001e71552bc6fd2de3764495ce50f16b3b806a986935ca5520", "quantity": 100000000}',0);
INSERT INTO messages VALUES(75,310108,'insert','credits','{"action": "send", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "DIVISIBLE", "block_index": 310108, "event": "5776bcda35a58d001e71552bc6fd2de3764495ce50f16b3b806a986935ca5520", "quantity": 100000000}',0);
INSERT INTO messages VALUES(76,310108,'insert','sends','{"asset": "DIVISIBLE", "block_index": 310108, "destination": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "5776bcda35a58d001e71552bc6fd2de3764495ce50f16b3b806a986935ca5520", "tx_index": 109}',0);
INSERT INTO messages VALUES(77,310109,'insert','broadcasts','{"block_index": 310109, "fee_fraction_int": 5000000, "locked": false, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "valid", "text": "Unit Test", "timestamp": 1388000002, "tx_hash": "ba3fe575883978cb0b79969b2f3c5268ef7b2fc7a90f6461d3ed33fbc30c90b3", "tx_index": 110, "value": 1.0}',0);
INSERT INTO messages VALUES(78,310110,'insert','debits','{"action": "bet", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "XCP", "block_index": 310110, "event": "0c690d46bef903922354520c8c8626ab5bfd45da1ca211d65f16aeef9b5f3300", "quantity": 10}',0);
INSERT INTO messages VALUES(79,310110,'insert','bets','{"bet_type": 3, "block_index": 310110, "counterwager_quantity": 10, "counterwager_remaining": 10, "deadline": 1388000200, "expiration": 1000, "expire_index": 311110, "fee_fraction_int": 5000000.0, "feed_address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "leverage": 5040, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "open", "target_value": 0.0, "tx_hash": "0c690d46bef903922354520c8c8626ab5bfd45da1ca211d65f16aeef9b5f3300", "tx_index": 111, "wager_quantity": 10, "wager_remaining": 10}',0);
INSERT INTO messages VALUES(80,310486,'insert','broadcasts','{"block_index": 310486, "fee_fraction_int": 5000000, "locked": false, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "81a5d20db79a4b620221ba646fec2699b4e4d1c854bb4022b0550bd7d274a5b8", "tx_index": 487, "value": 1.0}',0);
INSERT INTO messages VALUES(81,310487,'insert','debits','{"action": "bet", "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "asset": "XCP", "block_index": 310487, "event": "c9cfc39f98307a845d1d27d4a9ad66b19e0c38f59be14ed0c4b9d4ec15cb0940", "quantity": 9}',0);
INSERT INTO messages VALUES(82,310487,'insert','bets','{"bet_type": 1, "block_index": 310487, "counterwager_quantity": 9, "counterwager_remaining": 9, "deadline": 1388000001, "expiration": 100, "expire_index": 310587, "fee_fraction_int": 5000000.0, "feed_address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "leverage": 5040, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "open", "target_value": 0.0, "tx_hash": "c9cfc39f98307a845d1d27d4a9ad66b19e0c38f59be14ed0c4b9d4ec15cb0940", "tx_index": 488, "wager_quantity": 9, "wager_remaining": 9}',0);
INSERT INTO messages VALUES(83,310488,'insert','broadcasts','{"block_index": 310488, "fee_fraction_int": null, "locked": true, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": null, "timestamp": 0, "tx_hash": "b61f2f7e43e6696ca5b804e9c21e61616257b561e69d3cc6cf45af1e1cac3deb", "tx_index": 489, "value": null}',0);
INSERT INTO messages VALUES(84,310491,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310491, "event": "301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7", "quantity": 100000000}',0);
INSERT INTO messages VALUES(85,310491,'insert','orders','{"block_index": 310491, "expiration": 2000, "expire_index": 312491, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 800000, "get_remaining": 800000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7", "tx_index": 492}',0);
INSERT INTO messages VALUES(86,310492,'insert','orders','{"block_index": 310492, "expiration": 2000, "expire_index": 312492, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 800000, "give_remaining": 800000, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "tx_hash": "14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0", "tx_index": 493}',0);
INSERT INTO messages VALUES(87,310492,'update','orders','{"fee_provided_remaining": 6800, "fee_required_remaining": 892800, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7"}',0);
INSERT INTO messages VALUES(88,310492,'update','orders','{"fee_provided_remaining": 992800, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0"}',0);
INSERT INTO messages VALUES(89,310492,'insert','order_matches','{"backward_asset": "BTC", "backward_quantity": 800000, "block_index": 310492, "fee_paid": 7200, "forward_asset": "XCP", "forward_quantity": 100000000, "id": "301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7_14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0", "match_expire_index": 310512, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 310491, "tx0_expiration": 2000, "tx0_hash": "301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7", "tx0_index": 492, "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_block_index": 310492, "tx1_expiration": 2000, "tx1_hash": "14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0", "tx1_index": 493}',0);
INSERT INTO messages VALUES(90,310493,'insert','credits','{"action": "burn", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310493, "event": "0d88550e8361676614215372d3482d7749ddfe81d12fff58ce80a598dd0d368d", "quantity": 92995878046}',0);
INSERT INTO messages VALUES(91,310493,'insert','burns','{"block_index": 310493, "burned": 62000000, "earned": 92995878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "0d88550e8361676614215372d3482d7749ddfe81d12fff58ce80a598dd0d368d", "tx_index": 494}',0);
INSERT INTO messages VALUES(92,310494,'insert','debits','{"action": "issuance fee", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310494, "event": "89f7e46840b55a8134ca6950f804862a5a89fbc07dfa223300a07daeaad9719f", "quantity": 50000000}',0);
INSERT INTO messages VALUES(93,310494,'insert','issuances','{"asset": "DIVIDEND", "asset_longname": null, "block_index": 310494, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Test dividend", "divisible": true, "fee_paid": 50000000, "issuer": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "locked": false, "quantity": 100, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "transfer": false, "tx_hash": "89f7e46840b55a8134ca6950f804862a5a89fbc07dfa223300a07daeaad9719f", "tx_index": 495}',0);
INSERT INTO messages VALUES(94,310494,'insert','credits','{"action": "issuance", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310494, "event": "89f7e46840b55a8134ca6950f804862a5a89fbc07dfa223300a07daeaad9719f", "quantity": 100}',0);
INSERT INTO messages VALUES(95,310495,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310495, "event": "3c3e750a0a8f27fba67480957f85907f22a52d45385132d73d7fdc1c8e38107d", "quantity": 10}',0);
INSERT INTO messages VALUES(96,310495,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "DIVIDEND", "block_index": 310495, "event": "3c3e750a0a8f27fba67480957f85907f22a52d45385132d73d7fdc1c8e38107d", "quantity": 10}',0);
INSERT INTO messages VALUES(97,310495,'insert','sends','{"asset": "DIVIDEND", "block_index": 310495, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 10, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "3c3e750a0a8f27fba67480957f85907f22a52d45385132d73d7fdc1c8e38107d", "tx_index": 496}',0);
INSERT INTO messages VALUES(98,310496,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310496, "event": "478048dcdaca3e8010fc50a75511f6ed8fc1a770a4fab5c339a1c15c3633971f", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(99,310496,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "XCP", "block_index": 310496, "event": "478048dcdaca3e8010fc50a75511f6ed8fc1a770a4fab5c339a1c15c3633971f", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(100,310496,'insert','sends','{"asset": "XCP", "block_index": 310496, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 92945878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "478048dcdaca3e8010fc50a75511f6ed8fc1a770a4fab5c339a1c15c3633971f", "tx_index": 497}',0);
INSERT INTO messages VALUES(101,310497,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310497, "event": "b1a5f2dd0e4c14a093ba5353f8944fa6ccd64f21b7626b5e225deea9f6cc7470", "quantity": 50000000}',0);
INSERT INTO messages VALUES(102,310497,'insert','issuances','{"asset": "PARENT", "asset_longname": null, "block_index": 310497, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Parent asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "b1a5f2dd0e4c14a093ba5353f8944fa6ccd64f21b7626b5e225deea9f6cc7470", "tx_index": 498}',0);
INSERT INTO messages VALUES(103,310497,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "PARENT", "block_index": 310497, "event": "b1a5f2dd0e4c14a093ba5353f8944fa6ccd64f21b7626b5e225deea9f6cc7470", "quantity": 100000000}',0);
INSERT INTO messages VALUES(104,310498,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310498, "event": "2aabeff2dd379ed8d9d1400adcf6f7a375cad02aafc9de1268054839a5110d16", "quantity": 25000000}',0);
INSERT INTO messages VALUES(105,310498,'insert','issuances','{"asset": "A95428956661682277", "asset_longname": "PARENT.already.issued", "block_index": 310498, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Child of parent", "divisible": true, "fee_paid": 25000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "2aabeff2dd379ed8d9d1400adcf6f7a375cad02aafc9de1268054839a5110d16", "tx_index": 499}',0);
INSERT INTO messages VALUES(106,310498,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "A95428956661682277", "block_index": 310498, "event": "2aabeff2dd379ed8d9d1400adcf6f7a375cad02aafc9de1268054839a5110d16", "quantity": 100000000}',0);
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
INSERT INTO order_matches VALUES('301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7_14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0',492,'301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',493,'14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'BTC',800000,310491,310492,310492,2000,2000,310512,7200,'pending');
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
INSERT INTO orders VALUES(7,'969baaf1c366379930e994259ec1bbc4129a06ddd7e1393f431dcee2c279c798',310006,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,100000000,'DIVISIBLE',100000000,100000000,2000,312006,0,0,6800,6800,'open');
INSERT INTO orders VALUES(10,'bf97aaeecda40cc1842da334c232526a5eea7219239bf03205a7fc19eaa82992',310009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,100000000,'DIVISIBLE',100000000,100000000,2000,312009,0,0,6800,6800,'open');
INSERT INTO orders VALUES(11,'9a2ca3ff0e914c37ff63235b2679301f15da2621d717744befc7b8e21227ef87',310010,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,100000000,'BTC',1000000,1000000,2000,312010,900000,900000,6800,6800,'open');
INSERT INTO orders VALUES(12,'8a63e7a516d36c17ac32999222ac282ab94fb9c5ea30637cd06660b3139510f6',310011,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BTC',666667,666667,'XCP',100000000,100000000,2000,312011,0,0,1000000,1000000,'open');
INSERT INTO orders VALUES(492,'301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7',310491,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,0,'BTC',800000,0,2000,312491,900000,892800,6800,6800,'open');
INSERT INTO orders VALUES(493,'14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0',310492,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BTC',800000,0,'XCP',100000000,0,2000,312492,0,0,1000000,992800,'open');
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
INSERT INTO sends VALUES(8,'bdb55efb18b339207aa6483329a803fda6248e8bcf68b819708445d2c719f43d',310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','DIVISIBLE',100000000,'valid');
INSERT INTO sends VALUES(9,'663e6e10810403876bf8d5c1bc8715a44c82bfb4a2e5e98fa63ab65fc04cc55b',310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'valid');
INSERT INTO sends VALUES(13,'631f6b5166129fd3d69dbd4a8096707d61942acb55fd2100547a39d53bd8b5b6',310012,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',300000000,'valid');
INSERT INTO sends VALUES(14,'c91791d284a75383678ee71817775bbdfa7e22ffbbc561dbe782614121e625a5',310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','DIVISIBLE',1000000000,'valid');
INSERT INTO sends VALUES(15,'c3875a3cc9c8c967f8ff0accbc37f728e0bb038672c2cb19325ddb6bdb53465d',310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','NODIVISIBLE',5,'valid');
INSERT INTO sends VALUES(16,'f74ffb36b1ca86e0dc9305f31671c3866817fe575463cc8b982174a19f349746',310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','NODIVISIBLE',10,'valid');
INSERT INTO sends VALUES(109,'5776bcda35a58d001e71552bc6fd2de3764495ce50f16b3b806a986935ca5520',310108,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000,'valid');
INSERT INTO sends VALUES(496,'3c3e750a0a8f27fba67480957f85907f22a52d45385132d73d7fdc1c8e38107d',310495,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','DIVIDEND',10,'valid');
INSERT INTO sends VALUES(497,'478048dcdaca3e8010fc50a75511f6ed8fc1a770a4fab5c339a1c15c3633971f',310496,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','XCP',92945878046,'valid');
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
INSERT INTO transactions VALUES(1,'77f08141941118b414589e9affe2b15dea5dbe8139a52cd26083f25c1f87c6eb',310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
INSERT INTO transactions VALUES(2,'a68768e0a44a119cb48124b3f11f2a03e2f738a86a539aa9beb93596092d1edf',310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'00000014000000A25BE34B66000000174876E800010000000000000000000F446976697369626C65206173736574',1);
INSERT INTO transactions VALUES(3,'25e8108a67011db1a409e52fc3d73511d08a5078ad73e06b7dfefb90a8b6a70f',310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'000000140006CAD8DC7F0B6600000000000003E800000000000000000000124E6F20646976697369626C65206173736574',1);
INSERT INTO transactions VALUES(4,'227d51e90a5921551dff2554d81439718718afbd0b9a7efd2d8ec713497bdf3d',310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001400000003C58E5C5600000000000003E8010000000000000000000E43616C6C61626C65206173736574',1);
INSERT INTO transactions VALUES(5,'b5c6258164bca06c567dfe0b26b156812c34819c6ff538f9c1ee01bd071a3203',310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001400000000082C82E300000000000003E8010000000000000000000C4C6F636B6564206173736574',1);
INSERT INTO transactions VALUES(6,'84e607982e4aae1edbc0f1a02171e06ba335e30817779425ce570e26af2b5316',310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001400000000082C82E3000000000000000001000000000000000000044C4F434B',1);
INSERT INTO transactions VALUES(7,'969baaf1c366379930e994259ec1bbc4129a06ddd7e1393f431dcee2c279c798',310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000000010000000005F5E100000000A25BE34B660000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(8,'bdb55efb18b339207aa6483329a803fda6248e8bcf68b819708445d2c719f43d',310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,7650,X'00000000000000A25BE34B660000000005F5E100',1);
INSERT INTO transactions VALUES(9,'663e6e10810403876bf8d5c1bc8715a44c82bfb4a2e5e98fa63ab65fc04cc55b',310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,7650,X'0000000000000000000000010000000005F5E100',1);
INSERT INTO transactions VALUES(10,'bf97aaeecda40cc1842da334c232526a5eea7219239bf03205a7fc19eaa82992',310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000000010000000005F5E100000000A25BE34B660000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(11,'9a2ca3ff0e914c37ff63235b2679301f15da2621d717744befc7b8e21227ef87',310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000000010000000005F5E100000000000000000000000000000F424007D000000000000DBBA0',1);
INSERT INTO transactions VALUES(12,'8a63e7a516d36c17ac32999222ac282ab94fb9c5ea30637cd06660b3139510f6',310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,1000000,X'0000000A000000000000000000000000000A2C2B00000000000000010000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(13,'631f6b5166129fd3d69dbd4a8096707d61942acb55fd2100547a39d53bd8b5b6',310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,7650,X'0000000000000000000000010000000011E1A300',1);
INSERT INTO transactions VALUES(14,'c91791d284a75383678ee71817775bbdfa7e22ffbbc561dbe782614121e625a5',310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,7650,X'00000000000000A25BE34B66000000003B9ACA00',1);
INSERT INTO transactions VALUES(15,'c3875a3cc9c8c967f8ff0accbc37f728e0bb038672c2cb19325ddb6bdb53465d',310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,7650,X'000000000006CAD8DC7F0B660000000000000005',1);
INSERT INTO transactions VALUES(16,'f74ffb36b1ca86e0dc9305f31671c3866817fe575463cc8b982174a19f349746',310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,7650,X'000000000006CAD8DC7F0B66000000000000000A',1);
INSERT INTO transactions VALUES(17,'f6dbe255b8028a2917fff031b6d203d0822e71583432c6ba1509713db8f6dee6',310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'000000140000000000033A3E7FFFFFFFFFFFFFFF01000000000000000000104D6178696D756D207175616E74697479',1);
INSERT INTO transactions VALUES(18,'c23815ab2f8fa0ff8a43bb35cb8e4249fa7986a45b0b761b8fa654876772f8bd',310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001E52BB33003FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(19,'badb232b510fc70d33b241ed591d448848a424a9669b600f7e3b47454726c977',310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','',0,6800,X'0000001E4CC552003FF000000000000000000000046C6F636B',1);
INSERT INTO transactions VALUES(20,'bf4cbb16b58a03c1f715e7dacf49f20bd184d9f197756b7977135241fd708cb3',310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000152BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(21,'0590f213f0549ecf353969f9ec8140b6ecd4b67f9d2912cd58ec6b4b1b756a20',310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000052BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(102,'01e52b7501ff34946978d395da5b6b03032bc6a4336b007a4fe0456a19a334b1',310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000352BB33C8000000000000000A000000000000000A0000000000000000000013B0000003E8',1);
INSERT INTO transactions VALUES(103,'da14c69e2e3363b069527d936ed82e5aaff61c3060df97b0f3a4eb8af47454f0',310102,'11e25883fd0479b78ddb1953ef67e3c3d1ffc82bd1f9e918a75c2194f7137f99',310102000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000001E52BB33023FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(104,'72a78ce826f2a0a78a811366d419a1585c93b207f29be48aa09eec00a2088a90',310103,'559a208afea6dd27b8bfeb031f1bd8f57182dcab6cf55c4089a6c49fb4744f17',310103000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,-99994375,X'',1);
INSERT INTO transactions VALUES(105,'f0fc998a26684434405080655b8af2dec39c25544e5da36e60fe8711bd2f95ec',310104,'55b82e631b61d22a8524981ff3b5e3ab4ad7b732b7d1a06191064334b8f2dfd2',310104000,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,-99994375,X'',1);
INSERT INTO transactions VALUES(106,'cbdc121b6134889a6b6809c9f4134b9d3ed26cca35401efe1f512eab49e32284',310105,'1d72cdf6c4a02a5f973e6eaa53c28e9e13014b4f5bb13f91621a911b27fe936a',310105000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,-99994375,X'',1);
INSERT INTO transactions VALUES(107,'9ef49fc15392479177a27cdb04734d984e52a04b2453d8f83bcfbbcb5aaf0dfa',310106,'9d39cbe8c8a5357fc56e5c2f95bf132382ddad14cbc8abd54e549d58248140ff',310106000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','mvCounterpartyXXXXXXXXXXXXXXW24Hef',31000000,5625,X'',1);
INSERT INTO transactions VALUES(108,'89ed806602d4e0c260a88c76b1bfcc0c17c993b04678da155369525f854c9105',310107,'51cc04005e49fa49e661946a0e147240b0e5aac174252c96481ab7ddd5487435',310107000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','',0,6800,X'0000001400078A8FE2E5E44100000000000003E8000000000000000000001050534820697373756564206173736574',1);
INSERT INTO transactions VALUES(109,'5776bcda35a58d001e71552bc6fd2de3764495ce50f16b3b806a986935ca5520',310108,'8f2d3861aa42f8e75dc14a23d6046bd89feef0d81996b6e1adc2a2828fbc8b34',310108000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',5430,7650,X'00000000000000A25BE34B660000000005F5E100',1);
INSERT INTO transactions VALUES(110,'ba3fe575883978cb0b79969b2f3c5268ef7b2fc7a90f6461d3ed33fbc30c90b3',310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','',0,7025,X'0000001E52BB33023FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(111,'0c690d46bef903922354520c8c8626ab5bfd45da1ca211d65f16aeef9b5f3300',310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',5430,7875,X'00000028000352BB33C8000000000000000A000000000000000A0000000000000000000013B0000003E8',1);
INSERT INTO transactions VALUES(487,'81a5d20db79a4b620221ba646fec2699b4e4d1c854bb4022b0550bd7d274a5b8',310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','',0,-99993200,X'0000001E52BB33003FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(488,'c9cfc39f98307a845d1d27d4a9ad66b19e0c38f59be14ed0c4b9d4ec15cb0940',310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',5430,-99992350,X'00000028000152BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(489,'b61f2f7e43e6696ca5b804e9c21e61616257b561e69d3cc6cf45af1e1cac3deb',310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','',0,-99993200,X'0000001E52BB33023FF000000000000000000000046C6F636B',1);
INSERT INTO transactions VALUES(492,'301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7',310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000000010000000005F5E100000000000000000000000000000C350007D000000000000DBBA0',1);
INSERT INTO transactions VALUES(493,'14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0',310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','',0,1000000,X'0000000A000000000000000000000000000C350000000000000000010000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(494,'0d88550e8361676614215372d3482d7749ddfe81d12fff58ce80a598dd0d368d',310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
INSERT INTO transactions VALUES(495,'89f7e46840b55a8134ca6950f804862a5a89fbc07dfa223300a07daeaad9719f',310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','',0,6800,X'00000014000000063E985FFD0000000000000064010000000000000000000D54657374206469766964656E64',1);
INSERT INTO transactions VALUES(496,'3c3e750a0a8f27fba67480957f85907f22a52d45385132d73d7fdc1c8e38107d',310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj',5430,7650,X'00000000000000063E985FFD000000000000000A',1);
INSERT INTO transactions VALUES(497,'478048dcdaca3e8010fc50a75511f6ed8fc1a770a4fab5c339a1c15c3633971f',310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj',5430,7650,X'00000000000000000000000100000015A4018C1E',1);
INSERT INTO transactions VALUES(498,'b1a5f2dd0e4c14a093ba5353f8944fa6ccd64f21b7626b5e225deea9f6cc7470',310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,7025,X'00000014000000000AA4097D0000000005F5E100010000000000000000000C506172656E74206173736574',1);
INSERT INTO transactions VALUES(499,'2aabeff2dd379ed8d9d1400adcf6f7a375cad02aafc9de1268054839a5110d16',310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,7025,X'0000001501530821671B10650000000005F5E10001108E90A57DBA9967C422E83080F22F0C684368696C64206F6620706172656E74',1);
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
INSERT INTO undolog VALUES(140,'UPDATE orders SET tx_index=492,tx_hash=''301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7'',block_index=310491,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''XCP'',give_quantity=100000000,give_remaining=100000000,get_asset=''BTC'',get_quantity=800000,get_remaining=800000,expiration=2000,expire_index=312491,fee_required=900000,fee_required_remaining=900000,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(141,'UPDATE orders SET tx_index=493,tx_hash=''14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0'',block_index=310492,source=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',give_asset=''BTC'',give_quantity=800000,give_remaining=800000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=2000,expire_index=312492,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=6');
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
