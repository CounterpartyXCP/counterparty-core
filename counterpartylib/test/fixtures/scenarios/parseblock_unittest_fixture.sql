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
                      block_index INTEGER);
INSERT INTO assets VALUES('0','BTC',NULL);
INSERT INTO assets VALUES('1','XCP',NULL);
INSERT INTO assets VALUES('697326324582','DIVISIBLE',310001);
INSERT INTO assets VALUES('1911882621324134','NODIVISIBLE',310002);
INSERT INTO assets VALUES('16199343190','CALLABLE',310003);
INSERT INTO assets VALUES('137134819','LOCKED',310004);
INSERT INTO assets VALUES('211518','MAXI',310016);
INSERT INTO assets VALUES('2122675428648001','PAYTOSCRIPT',310107);
INSERT INTO assets VALUES('26819977213','DIVIDEND',310494);
-- Triggers and indices on  assets
CREATE TRIGGER _assets_delete BEFORE DELETE ON assets BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO assets(rowid,asset_id,asset_name,block_index) VALUES('||old.rowid||','||quote(old.asset_id)||','||quote(old.asset_name)||','||quote(old.block_index)||')');
                            END;
CREATE TRIGGER _assets_insert AFTER INSERT ON assets BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM assets WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _assets_update AFTER UPDATE ON assets BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE assets SET asset_id='||quote(old.asset_id)||',asset_name='||quote(old.asset_name)||',block_index='||quote(old.block_index)||' WHERE rowid='||old.rowid);
                            END;
CREATE INDEX id_idx ON assets (asset_id);
CREATE INDEX name_idx ON assets (asset_name);

-- Table  balances
DROP TABLE IF EXISTS balances;
CREATE TABLE balances(
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER);
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',91949934602);
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
INSERT INTO balances VALUES('2NErxwfmefM47yQ7Mk4y7WCqmvNfW2bhzic','XCP',46499535967);
INSERT INTO balances VALUES('2MxHK9KY4zhTPoupLCyXgPJoN2GtCsFr7gK','XCP',46499531786);
INSERT INTO balances VALUES('2MuWaw3xAczwSL6DKY77kEP7JgAWiQdqFSy','XCP',46499527606);
INSERT INTO balances VALUES('2MtBCufaZs6NDoDfLfR5MGG3KtDzUG2Pmy8','XCP',46499523425);
INSERT INTO balances VALUES('2N3ACzPYimgijjPWhowmwPWzzY7XtvqbtRq','XCP',46499519245);
INSERT INTO balances VALUES('mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',0);
INSERT INTO balances VALUES('mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','DIVIDEND',90);
INSERT INTO balances VALUES('mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','DIVIDEND',10);
INSERT INTO balances VALUES('mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','XCP',92945878046);
INSERT INTO balances VALUES('tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt','XCP',0);
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
                      difficulty INTEGER,
                      gas_used INTEGER, ledger_hash TEXT, txlist_hash TEXT, messages_hash TEXT,
                      PRIMARY KEY (block_index, block_hash));
INSERT INTO blocks VALUES(309999,'8b3bef249cb3b0fa23a4936c1249b6bd41daeadc848c8d2e409ea1cbc10adfe7',309999000,NULL,NULL,NULL,'3e2cd73017159fdc874453f227e9d0dc4dabba6d10e03458f3399f1d340c4ad1','3e2cd73017159fdc874453f227e9d0dc4dabba6d10e03458f3399f1d340c4ad1','3e2cd73017159fdc874453f227e9d0dc4dabba6d10e03458f3399f1d340c4ad1');
INSERT INTO blocks VALUES(310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,NULL,NULL,NULL,'f3e1d432b546670845393fae1465975aa99602a7648e0da125e6b8f4d55cbcac','74baad601b5f5e83ccc034b12956183c3b4c96973be90b1f65625f1d289a4486','91be11aea0c9cafc4b843a064d95cd2addf128675d6a371b090f60cd7e38aa67');
INSERT INTO blocks VALUES(310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,NULL,NULL,NULL,'6a91073b35d1151c0b9b93f7916d25e6650b82fe4a1b006851d69b1112cd2954','4d65eef6f755f385f7e7a2b6d54af2a3913e3ae5351b9d1d041e255cae642dd6','df5ee56ea976969bd1094fad84fa28d8fca47985852c3bf7a5500425a5c67b37');
INSERT INTO blocks VALUES(310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,NULL,NULL,NULL,'88eac1faa671a7ebc61f63782c4b74d42c813c19e410e240843440f4d4dbaa35','ebef3c39a3ef17c8bb6fe71baaa3d789e724a965f8bcdffde0b5c6732fe147b2','18b987071de500d9c6f74de3c39b6d5213b3e5b9450300530de5837ebf677c1f');
INSERT INTO blocks VALUES(310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,NULL,NULL,NULL,'93d430c0d7a680aad6fb162af200e95e177ba5d604df1e3cb0e086d3959538c3','ff2022228adab65e780f942f146e8dc80e4cc41e5ec76961edd93ba9922d0d89','7eb1fe3d9d2ec76789846f0906b8554d3b70dcf7253679dd164ad9d8655a863d');
INSERT INTO blocks VALUES(310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,NULL,NULL,NULL,'e85e5d82a20fe2e060a7c1f79dc182d3b2da28903b04302e6abe4a3f935ea373','121f59e0317ea12bc0981c063af4396fd151b37c9b2b539e8f2f3fb61f8922f3','2a67741fd440544cb49caad9bfeefd360679cef63b16d75e84464f1afcb98a4c');
INSERT INTO blocks VALUES(310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,NULL,NULL,NULL,'c6c0f780ffa18de5a5e5afdf4fba5b6a17dce8d767d4b7a9fbbae2ad53ff4718','17d8c8b71ea7c38756fc261a5dda52cc4e7473ba79d747d4d915024286689c08','9942c7149f08b62b3c533955f96d5185e906076134fe79a1d16a911ef05c4d6a');
INSERT INTO blocks VALUES(310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,NULL,NULL,NULL,'91458f37f5293fca71cddc6f14874670584e750aa68fbe577b22eac357c5f336','ac92a8199f71c785556845e0d563c3f7648f396bbfab309291c2f4eec830d51f','de2a62ca13965edeb280be268c8cd5fe91b6f1e320255a16fbd937fdbe87babf');
INSERT INTO blocks VALUES(310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,NULL,NULL,NULL,'a8f0f81aebdf77ee1945c2199142696f2c74518f2bc1a45dcfd3cebcabec510c','4607a3974a626c2bdb436ff03d9c90452a34664bbf67abb56849d760a6cb70d5','2704504fa35263d19b34237a1a3e78c3a0ed78644273bedc2ed8bc59714f39fe');
INSERT INTO blocks VALUES(310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,NULL,NULL,NULL,'df7cae2ef1885eb5916f821be0bb11c24c9cabdc6ccdc84866d60de6af972b94','5d11c74d7df09a6bb273f2205f055df566aff4a0582a8cb5f15d53525984b71a','cfe3b6f89068aa3391f0da3b6616d1b6c8722f92112530b967aba346e7532832');
INSERT INTO blocks VALUES(310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,NULL,NULL,NULL,'1d8caac58a9e5a656a6631fe88be72dfb45dbc25c64d92558db268be01da6024','e356d687418402221eded06bf6bd31e9aa2e8fd8a7e579d6269c847fae1493f0','fcffd37fc8ceeebc7592b701c0d89636f871b48fdc31c2c755e455c5dcc619b9');
INSERT INTO blocks VALUES(310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,NULL,NULL,NULL,'ab78a209c465104945458dba209c03409f839d4882a1bf416c504d26fd8b9c80','d5af008bd36f1b9bd906f73c8bb4e6149f399e2f774065d141df2d84486c1740','2a883ab3c88c0e3f337958b1e3d179c5aa47f4f4e32e74bf81d23ed179270fc9');
INSERT INTO blocks VALUES(310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,NULL,NULL,NULL,'5528fec20bfacc31dd43d7284bf1df33e033ec0ac12b14ed813a9dfea4f67741','d2da2a6daefb52fd311779b4d13a9fe90c05c429523124448000c7a42e0da473','8e76e4eaf0699364ab1e2bcef542814951175c4652ca02b1cd070698ec626361');
INSERT INTO blocks VALUES(310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,NULL,NULL,NULL,'fa66dc025cbb75b67a7d4c496141eb5f6f0cc42134433276c8a294c983453926','b01527f92384080e2fe9b4e2b035481d0e7e6cd292df759759bad486b462031b','7e4d03c7c85b0f6526badcda8f4612c328c93f107ce1f4648dbc4c3e61ccc277');
INSERT INTO blocks VALUES(310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,NULL,NULL,NULL,'442621791a488568ee9dee5d9131db3ce2f17d9d87b4f45dc8079606874823f8','69d4e8b38bd9554e44167a6fedf607ebb64b92994bed6f3715a17ca5c3b057cf','c3b8ef2499a87cefc09184ea74d87ae72800fbe7554d4c6de5e432bae5f1537f');
INSERT INTO blocks VALUES(310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,NULL,NULL,NULL,'8551367f346e50b15c6e0cca116d1697d3301725b73562f62d8e4c53581e7bd0','d4dc85d3ce6e85331f543adce0c831d3443b8e0ab3f908386ec75f87af3c604e','669b43f631d6fe70bd7ab7a953c6d406a200e4b912cb02daa2e179acc0a7a858');
INSERT INTO blocks VALUES(310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,NULL,NULL,NULL,'29de016d6301c2c9be33c98d3ca3e5f2dd25d52fd344426d40e3b0126dea019a','fb08e5f45dc7d0db3f06b5a9ff17c55cac3fd7acd2a2a3cda16cdad817a8dc13','ed8ed54994ec337e9f4e8c4b8ea77d99e35426351447550ec04cbe4aeab635ff');
INSERT INTO blocks VALUES(310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,NULL,NULL,NULL,'32ffd4bdf9b1f8506a25b4d2affe792d1eccf322a9ab832ec71a934fea136db9','3c595d930338d69d0a4a24fea7f76d06e121537006308f2d9952c96b3dd6f7a5','4ec05dc69f568c30a2f96e4de3b40b1254c3f80fc46b2a3ead0b57e73fa3a27c');
INSERT INTO blocks VALUES(310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,NULL,NULL,NULL,'64aa58f7e48dfa10bb48ecf48571d832bb94027c7ac07be0d23d5379452ce03b','33c4f0f7d012cc883e6855192418d44b0d6362f0e8385c58d3b29e38e11ad4f5','672b38c21ba28df4995b9756f5cc1026c8e610b1c6408ebdc7e02a32f0a84108');
INSERT INTO blocks VALUES(310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,NULL,NULL,NULL,'8d8f404bdc2fb6178286b2581cf8a23e6028d5d285091fa0e67e96e6da91f54e','a3b47149a48ea7806af6700450dace91c844b35a5fc965e80363bc488f8f291a','3d1b8034ef58154cec64ac0e4426eb0ced026452dd04dc6fcc4d519cd652cb58');
INSERT INTO blocks VALUES(310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,NULL,NULL,NULL,'945a8fd2f57cfd5ddab542291fb2e2813762806b806a3e65e688321fefe1986d','376eaece628d0d143068bcd4b9758b00f2593c088561fae41cbf699fa0ff8c78','f14fd8d96d878cda891af99a42ab60fea5be9e4d6ead5857899e3b5c2035137b');
INSERT INTO blocks VALUES(310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,NULL,NULL,NULL,'3393abc111ee337132103ca04b4f8745952cd03ddbd6efff58a589e00a48fa21','d106c2f5d11108635114f7ae1cb2f2344862cd4aa1ba00ccbbca16415585d8e5','04ac11dc991279914a56bb3f1197aa5d23ecd659034bf0da8bc4dfcecded806a');
INSERT INTO blocks VALUES(310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,NULL,NULL,NULL,'d05fe9705db7b30e6ea6b18e9ae92ba794dd72f25b4e33daf4d46b3b609a02de','53e120529d08250d3bd2864c0eadcb74ec2701fdc344090b559aaa71922d4b7d','a26ba90254574ca69e9f88902f15089494f2d057094c4d854e99e04fe155709b');
INSERT INTO blocks VALUES(310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,NULL,NULL,NULL,'c2b2b2c3bdd895c74f3ea22db3d9c66301578436b6fa9175ce0b242c4bfaccc5','826a59af916650a450553f3fa9231675e05d333547de79f836476b173ab0a7ee','b67e92b0db294b47d02a555a8e1a4caac331e60d484fb8ebaf2b323d23e65535');
INSERT INTO blocks VALUES(310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,NULL,NULL,NULL,'fad5b61545d8ef317918f07df063554d4f321c0ebf462f759513212960bdf523','b081eda1522024a7afe4b6dc55862290baf0206d16d11dbab2cbf46a992def8e','29937b440ee0279bb32429228f3a8d2c046a68f1fad2fce9aa6ff97c0fce7ee7');
INSERT INTO blocks VALUES(310024,'b03042b4e18a222b4c8d1e9e1970d93e6e2a2d41686d227ff8ecf0a839223dc5',310024000,NULL,NULL,NULL,'61a71d0ac67eba15c63a531f797e6d68c83613489730bc2b4e4054094f63105a','25bb22188b3257d5261d68d9b9c79e78e66ac43d2dcc5d6ba63485af016428fb','844b5753c47ba776e8d0bb9e998cd173bffc76342472d0c9fd426323d325b061');
INSERT INTO blocks VALUES(310025,'a872e560766832cc3b4f7f222228cb6db882ce3c54f6459f62c71d5cd6e90666',310025000,NULL,NULL,NULL,'f7d41404c3d1e57bbc390af958d1596212112068e4986954d11ff8abd13bc8e4','5453dfe7f74da7b5f16374afdce06dec72362b038d4a62a25fdf25ec83a77684','d4174157406d47c26f88184c1618bbdfd29b0ce237770deca6bef738a95b31fe');
INSERT INTO blocks VALUES(310026,'6c96350f6f2f05810f19a689de235eff975338587194a36a70dfd0fcd490941a',310026000,NULL,NULL,NULL,'31530d7febb577d7588e12d10629fd82966df48a93a613a480879531d5dbd374','5d047cd100f02ed6a2ee97ce863c4507f643989f9ee0b82829199cbbe576ff5d','16b805f1912181272f8a3fe5886982f3bc151c2e02becdd861b0f62a0b259f32');
INSERT INTO blocks VALUES(310027,'d7acfac66df393c4482a14c189742c0571b89442eb7f817b34415a560445699e',310027000,NULL,NULL,NULL,'f54085346ae4608c57c55d321a413a00ffeb85499138559d7d05245f57cc0da3','5aef98d6593f66407d00ad6b68df8370c8302af714ea437d4ce8d18187fa4480','0dfe1bb9956a2248b43540b8e6c8018432a87a6413715f41f044143110c0598b');
INSERT INTO blocks VALUES(310028,'02409fcf8fa06dafcb7f11e38593181d9c42cc9d5e2ddc304d098f990bd9530b',310028000,NULL,NULL,NULL,'a841b7f634fc24553d1c8cb2d66fc3103293dcfd297cb5bf241b0c5da84bd376','f8a333c8068d0204af84e0279c6c26d77ef1a5041712ecea21e54c031cc66b08','f371128316cdac199576c9dc8c6940c22439b678beb04315bb38abb61ce42630');
INSERT INTO blocks VALUES(310029,'3c739fa8b40c118d5547ea356ee8d10ee2898871907643ec02e5db9d00f03cc6',310029000,NULL,NULL,NULL,'69d40c69b4989f7a59da99b56577b0651887d9422757e38d5410379f95fda641','f122e080859292ee2047d1170f444a2c1f955cf525ddfb2a132a929982fe4d3a','2d914ae2a075f7a18324e6a1239a5b3a9801ad3753f0d6caddaac1956351b968');
INSERT INTO blocks VALUES(310030,'d5071cddedf89765ee0fd58f209c1c7d669ba8ea66200a57587da8b189b9e4f5',310030000,NULL,NULL,NULL,'192fe51d3a7af659670a8899582c29aedf3a5608ca906b274ce986751dad2d7a','bde6cbe1e34b4289b9d1496fc3506adf875353463a70b9807c04f853f7613962','e23b3e9acfcdcae1bf1cf07991033676e1437d71b0f915bd1ec868ca813e3d57');
INSERT INTO blocks VALUES(310031,'0b02b10f41380fff27c543ea8891ecb845bf7a003ac5c87e15932aff3bfcf689',310031000,NULL,NULL,NULL,'125784cdeba1e433b3411c368cdf676efb33021f51c26a8b2bd6ec00fe4f767d','68886690a5cf84b126cfc1a9757a6dc0eae19e94f2bb1fabb936bf832acb9196','db46abf9b33f8f967e17ee585a14f121adb53ed14bd52bbc1212e583305fa57d');
INSERT INTO blocks VALUES(310032,'66346be81e6ba04544f2ae643b76c2b7b1383f038fc2636e02e49dc7ec144074',310032000,NULL,NULL,NULL,'fa7832080a2b6ae8829794d70603351755fa4816f15a6e92716f83265daa59a4','27a27439231ae96d1e39da5f6ab92c1de816c14d1a2b63add0a16f98a2a1f907','18b508e36c234e262abc6e7afb0e523d8e922809201c15b518c8ad70f57593bd');
INSERT INTO blocks VALUES(310033,'999c65df9661f73e8c01f1da1afda09ac16788b72834f0ff5ea3d1464afb4707',310033000,NULL,NULL,NULL,'7b86f430bc44ad5d81a43b5a8ea118b458d995e3832d88bb74bc62429194e45c','8ce45a2289547f08fe7c3f11bfdd29a6faed27dc3b2cb93feac745c5bbda0dae','d68e5e6e850fa2c807486d8285aded4262b9cf5a53f167545208cfb7f5d93b6b');
INSERT INTO blocks VALUES(310034,'f552edd2e0a648230f3668e72ddf0ddfb1e8ac0f4c190f91b89c1a8c2e357208',310034000,NULL,NULL,NULL,'1f2c5ac4375f77fb79612d343dd5fc4489cf94ff983fc05ba2009a9e390d6c06','28145f55fd46f1a5651a074fce7a70a38a69fc21db478baae50e647065bfe82c','5796c4adc0e37c4348249eb2e525aee43e57f98289ae681d739742c93bcc92d4');
INSERT INTO blocks VALUES(310035,'a13cbb016f3044207a46967a4ba1c87dab411f78c55c1179f2336653c2726ae2',310035000,NULL,NULL,NULL,'81cdae9b978935ad40a1032e7f22ddd7117b9c7580d6d7e4b7e20d1c875f5e63','5cdb185be4ea354143d27756e5f59fdfb856fec6aa13dbec7c6e0221e21dace2','d31e823dd258968d0558a1d783919333eef5b18c2179f3b71b77a36dc4e26c70');
INSERT INTO blocks VALUES(310036,'158648a98f1e1bd1875584ce8449eb15a4e91a99a923bbb24c4210135cef0c76',310036000,NULL,NULL,NULL,'ff02952dce15c249501d8485decad0ad9fe02fda766b7b83720806f726d02ee4','106ee8a12ae955011b4996e21681077e241b6fe8fa28b58a6fa9089986b97684','d0649b6138e04173aba6abecc43bf4cf6d766a8d152627a1be578e3b89d5e2cd');
INSERT INTO blocks VALUES(310037,'563acfd6d991ce256d5655de2e9429975c8dceeb221e76d5ec6e9e24a2c27c07',310037000,NULL,NULL,NULL,'760e5a00feb6c8c4baf4421ad07be2af962bfcac7705b773484b449356d6c230','859f7c4c732b813902a3079c49fe5b282a9080dc6b803a633210ee985098af36','de8bfdb4d38c71d92144cc2041957bf0f59e9a39c5a42e9a491d8ad120a921c4');
INSERT INTO blocks VALUES(310038,'b44b4cad12431c32df27940e18d51f63897c7472b70950d18454edfd640490b2',310038000,NULL,NULL,NULL,'c79381c51fa93cc320d8bf19c943f98232a99446ac098ff66823cf691e0fa01c','b95227bde36dbdfbb2086097be6d6c594b8b3a30ddaa003637c290867164c447','4769e662f58d5ef019d792c6a66ce70a62a935b8bbf11d902ac5ec52aa8a2f3e');
INSERT INTO blocks VALUES(310039,'5fa1ae9c5e8a599247458987b006ad3a57f686df1f7cc240bf119e911b56c347',310039000,NULL,NULL,NULL,'7382f007315783c9a6ffd29bc0eaa62282c6ec72c5fff09322d6dea6b0ee3a96','b11d01b941be48bc7c8d415effac01b523745d64955132d8f158eca6d4e630ce','8d793f8d0664b8facfbe43c3d5e151c1a83a1ed424bbf066ddf6cdcad08378bf');
INSERT INTO blocks VALUES(310040,'7200ded406675453eadddfbb2d14c2a4526c7dc2b5de14bd48b29243df5e1aa3',310040000,NULL,NULL,NULL,'38d3b548be554a0ae92504244a88930b989ea6fefc9bc59c69b68ed560afee9a','89d6692c86fbfd4108a044325974e56161cb06b7ae45e81ca388ec48d8e4885c','0b075aa875911e615d92a48bc88b5f548c6a6159fd7df76cc533754d71740f00');
INSERT INTO blocks VALUES(310041,'5db592ff9ba5fac1e030cf22d6c13b70d330ba397f415340086ee7357143b359',310041000,NULL,NULL,NULL,'0c1c7aa19c015a67da214bf8a6ae3d77979a09de6a63621e320a28ceebdbf333','6a72509aa2e70ff1e627bb2d3bf2aa9a0dc38f23d90c5ee0dd528cd3cc3ca4ab','dbcdce22ab8558b1a31f1cc004bd70cda1f7adfeb116090fb955590d6db98849');
INSERT INTO blocks VALUES(310042,'826fd4701ef2824e9559b069517cd3cb990aff6a4690830f78fc845ab77fa3e4',310042000,NULL,NULL,NULL,'9d20f77d4afff9179cffe46574f1b2dd23d2987142c943de05e411baee2dbf05','de5bbd242c57d0fcd47e6fecd09649fae552b6ad254f6ef31d09da4956381d1f','5dd912f25db412d08223d2e58cdd5e23c6190bbc070d2e18af24fa288afe4ae9');
INSERT INTO blocks VALUES(310043,'2254a12ada208f1dd57bc17547ecaf3c44720323c47bc7d4b1262477cb7f3c51',310043000,NULL,NULL,NULL,'d818e5a1a5cb6c59771b63997a8737cdb041c3579de1ecd808a269f5d72a3abf','804cf264069c71258a5834ac9995c7028fb0848dc1c0816e4f258b53ab7d16b1','aca75b7c37058ac3a11e54a6e8338505661a76c96d5283966504276ad1ffe3b8');
INSERT INTO blocks VALUES(310044,'3346d24118d8af0b3c6bcc42f8b85792e7a2e7036ebf6e4c25f4f6723c78e46b',310044000,NULL,NULL,NULL,'9de166ff18c5eec97b838292ae894ce18e5a890e8a841a294b2d14894c60a0d7','564bedfc5cd770a558d5756c517fd6bbc73445b747825e86eb84f0ab9f675a55','993c1f0fe553bc1f8d2d677d40adecb3e1c124c2f7a80aee497f70f677f42722');
INSERT INTO blocks VALUES(310045,'7bba0ab243839e91ad1a45a762bf074011f8a9883074d68203c6d1b46fffde98',310045000,NULL,NULL,NULL,'bb3c0a260dc082534c95e894751e38e80de117b091bc0e34c66134d374b8db2d','aebd7d8cc02e5b795dcdb09450e3113e18fd8673665a86a06c19f8870d521a01','bd7575b6da116f17c371129b52633a92103765a02e1fdd85aa205e21d13eb6bb');
INSERT INTO blocks VALUES(310046,'47db6788c38f2d6d712764979e41346b55e78cbb4969e0ef5c4336faf18993a6',310046000,NULL,NULL,NULL,'b4605c50ee3e5e2958c908e099563cf997e20932cc2370109ab50049e43723cf','bb51a374f1e97797e8bbd82c8938a8333f202ede2656f4ebc737fd4c852062ad','de7c24ce6ade6623d9cc2485e9b49ef124b4398293f383e80c2d10076756ca2a');
INSERT INTO blocks VALUES(310047,'a9ccabcc2a098a7d25e4ab8bda7c4e66807eefa42e29890dcd88149a10de7075',310047000,NULL,NULL,NULL,'b840a7af6301c798c9a6670308a2684051ff8f3fb2e69bddaafa82cfd3d83186','31a0605b811d08b5ed47d83a56390b8b3be76879862497e8795eca1037700062','18d73fe3ea50d819b71adc6a68d12b9508d9c2d0c7bde8e3f3034a7c85a0f853');
INSERT INTO blocks VALUES(310048,'610bf3935a85b05a98556c55493c6de45bed4d7b3b6c8553a984718765796309',310048000,NULL,NULL,NULL,'6bd591d3336ea112789ad6675a9b1d8e1578fe42e44ca7f7be5557089d374c3f','f4fdb98332e7b8c19166b3fd01a8f8cf9e03325848b700d9a7522c91cf0735e4','78b0e0708c94e76b7a2cfa62cf43c9548e6e8175baae4aa6fc4dcb9372c9ab00');
INSERT INTO blocks VALUES(310049,'4ad2761923ad49ad2b283b640f1832522a2a5d6964486b21591b71df6b33be3c',310049000,NULL,NULL,NULL,'04fe1e6631d503a9ee646584cda33857fac6eeca11fa60d442e09b2ed1380e5c','3b511a4c23092109f4633d2500e5d4cba09978e53e0ef3341625783547727262','cee3345fc609ba9cede4f91d1500f0ece115288921fd61e6673194f3ce13db2f');
INSERT INTO blocks VALUES(310050,'8cfeb60a14a4cec6e9be13d699694d49007d82a31065a17890383e262071e348',310050000,NULL,NULL,NULL,'dc73bfb66386f237f127f607a4522c0a8c650b6d0f76a87e30632938cf905155','dfaccc66d4e468c6d33d1543a5a69adfcf2fc0c9d2d5b39afc38895c9714d994','1de9908421424016755b07963c2ab2e849410ab145d7444e8438aa9c8e2f935e');
INSERT INTO blocks VALUES(310051,'b53c90385dd808306601350920c6af4beb717518493fd23b5c730eea078f33e6',310051000,NULL,NULL,NULL,'e4eea2d144c8f9c6dfe731efee419056de42f53108f83ebee503c9114b8e4192','8a3173e17ebe757a2429f6e9a8d59fe96d225ba8d355bbf7a44d5f9c40e69ddf','8892e39c0ce9ccc3323b266dc9d32f2c0353b3f29f53dac9a890f90b313ce090');
INSERT INTO blocks VALUES(310052,'0acdacf4e4b6fca756479cb055191b367b1fa433aa558956f5f08fa5b7b394e2',310052000,NULL,NULL,NULL,'8d12b561e7cf87b0aabe000a93a57e5f31db75510b1e9feb19b4f557cc0e6604','2bb61472fe7bda94c4c91f522c45e5f58201f753981c51653d923290bb31934c','0d627af4f0fb6aa94cef7a7892f84bca76eee227a975ac31487f295d48982102');
INSERT INTO blocks VALUES(310053,'68348f01b6dc49b2cb30fe92ac43e527aa90d859093d3bf7cd695c64d2ef744f',310053000,NULL,NULL,NULL,'f47b81b3dfc522d9b601d1776fa2deef8543ca077cb0743556cd970bb119d640','2e1fce95ee73276a6c8ffc7bb7aae1eabe753c622960b971a6b5fc010ac8369e','b3d8c92340ea0cf55fd8a8770483fbb4a7a8acaacd3aaef35cb48379c6e46bd9');
INSERT INTO blocks VALUES(310054,'a8b5f253df293037e49b998675620d5477445c51d5ec66596e023282bb9cd305',310054000,NULL,NULL,NULL,'df191ed877eb1856d6780a717c04d6925246cdee7dd6df74216ea983560d5a2b','8591d342b1ff9680974b058b921b6ee146a7d719b71101dc6c857a074dc1efc8','83175ca4adae384b7e2e1ebe8106cfb9bdf52a4d4f1b5442dc0b41e0976f7d30');
INSERT INTO blocks VALUES(310055,'4b069152e2dc82e96ed8a3c3547c162e8c3aceeb2a4ac07972f8321a535b9356',310055000,NULL,NULL,NULL,'4b0ab72111202b1f9a5add4bf9a812df203cb6761a8d16b5f7a8b9ed6f2b2476','de9d9ed5dfa010e806c52a8aab93d3669c5800113d804b861d6c2d23e4d03a2d','430de2d54ab490531718c9690760ee75587f9fe1c83c578a0e3f2149adfe9934');
INSERT INTO blocks VALUES(310056,'7603eaed418971b745256742f9d2ba70b2c2b2f69f61de6cc70e61ce0336f9d3',310056000,NULL,NULL,NULL,'8e76b5be6a94e1b50ba16fe265965d4cba01b792216485c54360052e78788f20','75b53038c068251447bbbf5fcccbe2d91fdee3645658c7b0240715e09aca5835','aa10e673d981c3292041713b6959de6e968f8138e063d95bc6160513a74258fb');
INSERT INTO blocks VALUES(310057,'4a5fdc84f2d66ecb6ee3e3646aad20751ce8694e64e348d3c8aab09d33a3e411',310057000,NULL,NULL,NULL,'e14dde2bfbe4f9076b7ba548aad37269752858361af094b4be8b956c0a28b9c5','2ba6267a2f69a0f5764a2d84b24ead805d1eb8c6b521edd9af8a04e17a862dbe','7e864a378b943e2fa4071181aa045c94f8a17a3a4110c84ecd5969547ee3b1ae');
INSERT INTO blocks VALUES(310058,'a6eef3089896f0cae0bfe9423392e45c48f4efe4310b14d8cfbdb1fea613635f',310058000,NULL,NULL,NULL,'b986e5f6486ceac7f1af41b1da968e453cc19376d588d8e884439b51313d6e30','2af5bbe77603975352dc2e8a222e8f60b8943640ab9d4c100698c16329c957a6','2897c69dd0a55d908eae1584d6526d4a782cf04d0fabc1197ef9ad3d880b89c9');
INSERT INTO blocks VALUES(310059,'ab505de874c43f97c90be1c26a769e6c5cb140405c993b4a6cc7afc795f156a9',310059000,NULL,NULL,NULL,'da978ee5b06812ee42cda43e1d9943c4e34e9e940cb0461f0ed463b9299402d8','30cacb7388eb996da46d023ec09aa488607d5c6f30d4411bc6a9364e5d764943','984ac7cfd12725a3a386b1a65912507488887e3a0485166ea70f8daf79b23db3');
INSERT INTO blocks VALUES(310060,'974ad5fbef621e0a38eab811608dc9afaf10c8ecc85fed913075ba1a145e889b',310060000,NULL,NULL,NULL,'09ccea87988cc385b9d2580613581b90157f1366d27cd3dc1a4385e104430d15','51d78f09ff93897481e4a758b9a9ba9b96354fa284c3f01af9007d814db97327','b9c6d66be76193a30ccb6da722ee233a849f4d8fc9ced2169953ec35a47d9e74');
INSERT INTO blocks VALUES(310061,'35d267d21ad386e7b7632292af1c422b0310dde7ca49a82f9577525a29c138cf',310061000,NULL,NULL,NULL,'4caebeb5ab6468e116cc0cf137977649a15dd30d9b214a5081057a551174ec48','3c624e0d7d220ad0666ffa0362b928140deea0b9ebd68f75c261c575f2c08234','a9247d661576f55115269d22fbe3f78afd1c7b705ec52980336423b879d6e8dd');
INSERT INTO blocks VALUES(310062,'b31a0054145319ef9de8c1cb19df5bcf4dc8a1ece20053aa494e5d3a00a2852f',310062000,NULL,NULL,NULL,'51cb3f1005127e3240721c47805d67a123afdc40084692a9cc2b3215cec99dc3','299a92a1ac92debe1a86f69bfd1a299b8bec5f0aff9651856d2d495a50415664','fccbce0dc968131f98dfd3c3ff51871b58d01877caafaa3af75e7f11b9a8c1a8');
INSERT INTO blocks VALUES(310063,'0cbcbcd5b7f2dc288e3a34eab3d4212463a5a56e886804fb4f9f1cf929eadebe',310063000,NULL,NULL,NULL,'e12864a0f955320278c215897cf4f65e5c378e534294b0bb90ebd7e4b5efd4f7','6fb5e5b279bf37f68925682ecad8f0e1073ed006d049954c21b8e7e5a4667186','77ade687c595b59a3ccb783057ba840333a9e59953d41c094bfe0541ff806b3c');
INSERT INTO blocks VALUES(310064,'e2db8065a195e85cde9ddb868a17d39893a60fb2b1255aa5f0c88729de7cbf30',310064000,NULL,NULL,NULL,'ee27c3b46aa890d18be950006879874a094ecddd086db195e032fb4fe12559f5','bb3a53231dce223dc4dcbcf67f5c56c53f9fd9d23fdc97a43a47abb5fbec222b','49e5f8e885bc8b9675b5f1e3e87d48a549bc44ad21f8d350b5a02093caf3ec17');
INSERT INTO blocks VALUES(310065,'8a7bc7a77c831ac4fd11b8a9d22d1b6a0661b07cef05c2e600c7fb683b861d2a',310065000,NULL,NULL,NULL,'d40dbc4b5faaf8918f9cae54e5a247e3904dc65994ce0f04f417c1a595404464','b0ec4c4d421023f4d5b60fa6dcc85e926a9d2df7c4bc477518c6974c38c59292','b04886c28e4b2a902bc2444117674868421749de33e3ee28031395ee5caa3214');
INSERT INTO blocks VALUES(310066,'b6959be51eb084747d301f7ccaf9e75f2292c9404633b1532e3692659939430d',310066000,NULL,NULL,NULL,'19f2b00477a6fae0e10f4693d949cb409b1ed74ad20dbd9aa4a7f1f17cb813ac','be86db5e91d08200eeccdb2e29753ec8145cf356adf9cc3efc2e451c6aa50b3d','8c6affd2cb9e9049b5a8557f58cb947ff8a15e1ad9ec82ba47a95e1eea80e62b');
INSERT INTO blocks VALUES(310067,'8b08eae98d7193c9c01863fac6effb9162bda010daeacf9e0347112f233b8577',310067000,NULL,NULL,NULL,'d72891c22fcea6c51496fc1777fa736ef5aba378320a1f718d597f8f9fea3c7d','73beb3900a2bea9f6427322005c1d4021a82faca64b8dd8cb461714846800936','ee959a28953c6ddf86b0784a3442fbbd6e63b4ae1f99845a58fe952a7b214b2e');
INSERT INTO blocks VALUES(310068,'9280e7297ef6313341bc81787a36acfc9af58f83a415afff5e3154f126cf52b5',310068000,NULL,NULL,NULL,'5793e10b8329d3ac71aed6347dfcf61fc7b74ca162ad99918f5c20065f8d0746','1afd4dd2bb8c3e13748c97e2015065fa46286cb9e2b284579278d9d45ab830ba','5325e0f0e3bfaeb220112aa1195f8c4a8967f3e6b14d04f70804ad7f34583f1f');
INSERT INTO blocks VALUES(310069,'486351f0655bf594ffaab1980cff17353b640b63e9c27239109addece189a6f7',310069000,NULL,NULL,NULL,'61040e7c1a58f41d708785347f4985c1fb522b6f947d3e14dacd91157e153ab7','bd81b055fcc5aac0894eaea3f4bebb6ca816b81f62f94417c793c97a8eb03d1b','8e18dce34eafc683975d2332bf5f5a95588b471e95a585dd0b6273fb7f5cfdfd');
INSERT INTO blocks VALUES(310070,'8739e99f4dee8bebf1332f37f49a125348b40b93b74fe35579dd52bfba4fa7e5',310070000,NULL,NULL,NULL,'ce115625fbda90a0f261b2c524108a7393078cb4c3f861d6d7846501c7960008','d77d33692b84741b01edc701b94b7c18487a0842d2e9e35715e247ae1ed17b96','6f68105083ef2cf39b6ebac41bac98db1b2e7919e626bd4b8c653d4884baf880');
INSERT INTO blocks VALUES(310071,'7a099aa1bba0ead577f1e44f35263a1f115ed6a868c98d4dd71609072ae7f80b',310071000,NULL,NULL,NULL,'3c2d4d81e90a42a0c18e9c02b8a59f99e13f2a084ee66b4b1bd410077adc383d','c9c0d3df9a273085902be23c5a84ea4f352d9c759f6e4dda06198d92c605c693','02e0ab7965b6feacce52ff40c508d875da826dc36d4fbc62c0b36cbccf9f9037');
INSERT INTO blocks VALUES(310072,'7b17ecedc07552551b8129e068ae67cb176ca766ea3f6df74b597a94e3a7fc8a',310072000,NULL,NULL,NULL,'8a28e33306582346f1d965a0393621b4aa307f6614c84369064465f95a6c727e','cea0b70d923de81f184fc28fd346ffe9105c0b303b345a278bfb6fb930950b0f','5162082a97eca6133a105cdc7bdd9180a042785936c8f3140d17e0973bf96a01');
INSERT INTO blocks VALUES(310073,'ee0fe3cc9b3a48a2746b6090b63b442b97ea6055d48edcf4b2288396764c6943',310073000,NULL,NULL,NULL,'e6c5b393a21df54479c4cd8e991b37d877794166c19b9f61ad7e47eb34f63bdc','4e6230d9a8f67b575198e41be226f2975af47fd413b7c5937b56119e5414c0a7','36b3beec80907c81c729c71a60f55f5e6ebc550cdcaab286fa08f3a32b96cc23');
INSERT INTO blocks VALUES(310074,'ceab38dfde01f711a187601731ad575d67cfe0b7dbc61dcd4f15baaef72089fb',310074000,NULL,NULL,NULL,'b2db452daf280f1cc5f02668d0cbd33732a2fe9f04307d9c072eba97c95acf5c','8383ea77813db9b32b9f84f4f0bd67afdee03912a27550a496726aaec65f42c2','e04d73ddcf70357b2b5a957b553032f070bbe306c29844bd3b4bd2ea18b80d4c');
INSERT INTO blocks VALUES(310075,'ef547198c6e36d829f117cfd7077ccde45158e3c545152225fa24dba7a26847b',310075000,NULL,NULL,NULL,'09998443cf1cd79e193a7b09681ae07ea9a835458151a7f8c7d80a00c5d8e99a','1c8ad126a1d661562ea41fff197d968f966f698bbcbd636be6e9b9ddaddf70a6','7ff6d31cc3747a9b8f56777251a269c10ee680d822525dd78a729b774cc8f199');
INSERT INTO blocks VALUES(310076,'3b0499c2e8e8f0252c7288d4ecf66efc426ca37aad3524424d14c8bc6f8b0d92',310076000,NULL,NULL,NULL,'a0be1e88f10b5214f7c12dd32d0742537072d5eb3e54f9abf57a8577f7756d7e','d4778d09a0cb21f4904e82e6e972ff9d0254bff08a9cd70ad8fe961977286933','9660ca1e04dfa3e10161ee869cc36a699b76b790c34894e3c6aae8bf1f868ded');
INSERT INTO blocks VALUES(310077,'d2adeefa9024ab3ff2822bc36acf19b6c647cea118cf15b86c6bc00c3322e7dd',310077000,NULL,NULL,NULL,'d41e39038756ee538d9438228512e31b4a524bbd05bc9b9034d603fd20e00f05','3b34fe46eed2a06ac89af1a9b8f29274612016b5acd29f3d3c31926f176efdc2','d3a194cb5f35354dc5b91c6bbc153df161c9247b0b977bca730879cda8e309b2');
INSERT INTO blocks VALUES(310078,'f6c17115ef0efe489c562bcda4615892b4d4b39db0c9791fe193d4922bd82cd6',310078000,NULL,NULL,NULL,'996092432a2d94df1db34533aa7033e672fac73de5193a696c05ae7c30d75247','8335b6dce6641d4a6a42deabc6fa5fc026950187cbb8baea9e6c241f5dfeeac0','9f90eaadf1a9a9f1c35654a5a8091cef6e94f48eaf8798f32040f8cb03af5907');
INSERT INTO blocks VALUES(310079,'f2fbd2074d804e631db44cb0fb2e1db3fdc367e439c21ffc40d73104c4d7069c',310079000,NULL,NULL,NULL,'e3f536e930e39b421e3a0566eba6b8f5f781ad1ff48530a5671752fd3eaf35ac','980a8b2617bef99ecac373139455c429571203d86e4ed4eb6f1021548574c671','dbdc45ceb0c18375f4e6a9818d33defb8925e565ba05487923dbe98aa54b38ec');
INSERT INTO blocks VALUES(310080,'42943b914d9c367000a78b78a544cc4b84b1df838aadde33fe730964a89a3a6c',310080000,NULL,NULL,NULL,'57122dc41d7de2bdc65002905617c357496432fa4d80af48f4ca69ba1332e634','54fbda6b18541272b0b80011120f92d9e2309091b7a1bba61b509e982dbd5d4b','5d577000f92aa6dc7e2296b5f0669b61d3a2cc375d7d01f545817968c25261c4');
INSERT INTO blocks VALUES(310081,'6554f9d307976249e7b7e260e08046b3b55d318f8b6af627fed5be3063f123c4',310081000,NULL,NULL,NULL,'3a0fc7b2f0396d257a0a5c5a313910cb4073e4c79ef8cf0d3cd12f494e563105','43bc4dfb8b09f7dea0786dbec5021d228f6e42ff04efd0de0877cd074fd59102','42b37b4345b019636b0e3a82e7009983d42965a0c75ae74d8151aea51f244dd2');
INSERT INTO blocks VALUES(310082,'4f1ef91b1dcd575f8ac2e66a67715500cbca154bd6f3b8148bb7015a6aa6c644',310082000,NULL,NULL,NULL,'e876c406f682ed6f0dbd6e4c97bac13409cd400b59e894eebeb3252be306494a','ccbf98c416092d1bed96d4f6fdb8c0061f738e2335c838dae50afb7dc1f3217c','c1dd4277b7d3720c9438430794cd6866ed7fbbb50940f096818ad680e227f35c');
INSERT INTO blocks VALUES(310083,'9b1f6fd6ff9b0dc4e37603cfb0625f49067c775b99e12492afd85392d3c8d850',310083000,NULL,NULL,NULL,'533fc3eea80caa46cf8fd62745c5d21d09f32b18eaca70283a4bd72924c2100a','17182d62608dd447343da7c4549a974301985bc9a888cd79bf2b62b7e1fe2644','29373a882425f7b5ac13d4c4f20a2836e14be12f70ea2d2beade84c105ff1b6e');
INSERT INTO blocks VALUES(310084,'1e0972523e80306441b9f4157f171716199f1428db2e818a7f7817ccdc8859e3',310084000,NULL,NULL,NULL,'e3fd22f2e1470246ca99c569d187934f4b7bbb1eedb9626696cbaf9e2b46253b','98bc81538460bc09e1569e7ec9bec21e85e1b56aa3482669ec39d22ff0b3751f','711eccd65124af826e57f851f4b84258f3f21a2a521a25d1663b9d08707220d5');
INSERT INTO blocks VALUES(310085,'c5b6e9581831e3bc5848cd7630c499bca26d9ece5156d36579bdb72d54817e34',310085000,NULL,NULL,NULL,'bf04750fe13f663adb12afd3a166636a4511bf94684a77217de1bd7ef9077d94','efc30059c33bbadeb940e90a886b1487eadda89003051ef6dc9d553baf13f6cd','7edd8a3f51e80a93fa78210840ff3350b6c9b73db2e54d7ef3e975ddf9803b31');
INSERT INTO blocks VALUES(310086,'080c1dc55a4ecf4824cf9840602498cfc35b5f84099f50b71b45cb63834c7a78',310086000,NULL,NULL,NULL,'a0e8403085ba63ba72432f27ce8125921ef24742f988ab7f85dd8e4309f27a2c','b7ba9b95123603ffcc2ebb8f1a9d2ffac18a4ae7eb5cf82fa4e78d1af2e4c871','3fc550a1f7a0b618255537cb060730dcdd8184cb5d5dd9fe91ec22d714dc6553');
INSERT INTO blocks VALUES(310087,'4ec8cb1c38b22904e8087a034a6406b896eff4dd28e7620601c6bddf82e2738c',310087000,NULL,NULL,NULL,'0861b02e980ad5958bd23ac02603b132efd72ee2a70dbb0415fa5d39cc524681','093d08b704d2d26a34204f38aef4e2bf7a54c8ee8eef2c0576cb7a4c40cd6f7e','3e0e4cefbaca82a0150097c2821497c56ccd1353548c5969d287b1620bac5851');
INSERT INTO blocks VALUES(310088,'e945c815c433cbddd0bf8e66c5c23b51072483492acda98f5c2c201020a8c5b3',310088000,NULL,NULL,NULL,'d52cdaa449f63f6d3abc79080378855206f91a5db865dfaf37a5a2529ea6eb9a','b0197fcd81949cbfe4ba586a88de930946a78b1b6c00d168006904b59ced841c','4051e93ffa0290da2f8d8931dcf52d233afbdca59e7362e7c6abc29101a17f59');
INSERT INTO blocks VALUES(310089,'0382437f895ef3e7e38bf025fd4f606fd44d4bbd6aea71dbdc4ed11a7cd46f33',310089000,NULL,NULL,NULL,'d15a7a60b8bf8618667863b3e31eaf6202664e5aebc16d1f7a337b857ac31f90','99db7662b56114ee0b01d6947feebb19dffc0afcfa50d44885566c979e8b2603','76eb113f6b4c3edd05da46332d5a2e6eaf4dce88f95a7686a5df1b46d8c101db');
INSERT INTO blocks VALUES(310090,'b756db71dc037b5a4582de354a3347371267d31ebda453e152f0a13bb2fae969',310090000,NULL,NULL,NULL,'68475dcfe8252c18501fd1fef2afa2a91d20b92cacbabb542c12f43403e66ea3','80731a5f85b5975b3fb00c4c69024fb06e940c8fa75d1e54fee3a4f1564107ee','c825b7273885d13bd649c5ce725049b1ccd158b124bd9a5eaf3234a19c43e47b');
INSERT INTO blocks VALUES(310091,'734a9aa485f36399d5efb74f3b9c47f8b5f6fd68c9967f134b14cfe7e2d7583c',310091000,NULL,NULL,NULL,'5d584f255e5bbebc32c78a30fa816e1203fe7d3454611bef9222cdfc91dfcb63','8e39bbc5703444d459c2b3bf47445bf3ef75c46a4b545227e3f3a15f5222e75d','f6778243a7d45c5b710beb332c12c60c1985baf072843e7632ca7141954ff90d');
INSERT INTO blocks VALUES(310092,'56386beb65f9228740d4ad43a1c575645f6daf59e0dd9f22551c59215b5e8c3d',310092000,NULL,NULL,NULL,'ef992ad033b047b7f6ab038604736f444da55be187834f8152b173cf535c68eb','d1f2b50d51edcd8a11c908be8d8bc209ee969058a89be0aaab4a6497cfd4c748','575b0e27b20f17aa593d8ad8ece5a95bd108149dfe21c4d3f3ebf88ad9cd6dcf');
INSERT INTO blocks VALUES(310093,'a74a2425f2f4be24bb5f715173e6756649e1cbf1b064aeb1ef60e0b94b418ddc',310093000,NULL,NULL,NULL,'9cdee996d0e67ac3f9f283151b428ac5f223b72590965f41f93adcece6b88f2a','bc9e7d4a6571026f1f615c01166699691eb432bea53551d65b8a4fae8124fa04','01e6d084f7fe094981dd7d88c59c14ed0e7cc0dbba2dbc6f5eeadf7e1fcea838');
INSERT INTO blocks VALUES(310094,'2a8f976f20c4e89ff01071915ac96ee35192d54df3a246bf61fd4a0cccfb5b23',310094000,NULL,NULL,NULL,'fa25dc3f15fb28718d788f85373555966251f54bc6ed1f4dd2244b438d27b281','49221457596119fcbed057bedc2f12b28e5cb7ff47ecbf1f22b1a6caec53568a','68a104f8828c40e4e1da8284f877c1ad848ebc438129895a4f9161523466d0ba');
INSERT INTO blocks VALUES(310095,'bed0fa40c9981223fb40b3be8124ca619edc9dd34d0c907369477ea92e5d2cd2',310095000,NULL,NULL,NULL,'1ba8cd971f9a169d43b6de1a136cb8e6153649fde1f7a8e7fb2f7de926fdf8b2','154fcce14c624c0286d5dfc827217df0343ed56d0a58426680b7bad9b3d31c62','15e85372ba92a14a0170386cdd32a3cbf150b07622d3985313899bafc0e841b6');
INSERT INTO blocks VALUES(310096,'306aeec3db435fabffdf88c2f26ee83caa4c2426375a33daa2be041dbd27ea2f',310096000,NULL,NULL,NULL,'42c36df2c53d762b9b132e622f52b2fca99bc0370978463acd22cdf6469587a8','cac3e695b6b1c4f7e658ec8fa2f0dcbd76e237fdcd1e94b3412b4b7cc2021d2b','1855ce8cc1e75d99175073a1ffd497021d3286ee4f705f94c9d9bf4b94a33a6b');
INSERT INTO blocks VALUES(310097,'13e8e16e67c7cdcc80d477491e554b43744f90e8e1a9728439a11fab42cefadf',310097000,NULL,NULL,NULL,'d96af5cf3f431535689653555c29f268c931f9fb271447aed050303d364f92a8','6c8cbc6e34c3898e1767c5bbb49853e349adb2a3a666da95e356a92c9945df63','9a0db97b964616d717e2dec12071ed9b7421a1ba868e6c645ab093c169f797db');
INSERT INTO blocks VALUES(310098,'ca5bca4b5ec4fa6183e05176abe921cff884c4e20910fab55b603cef48dc3bca',310098000,NULL,NULL,NULL,'153c9ce12e8d9f9d10c4005fc9af158613480d38b2c6551fc49bc57380c229de','213b649e82eaf8bde0ae1d61bb03a785b77212a7024a6dbbced9f372f423e777','63b22aad2fb1d8e20cdbdf963aa767c5bd6a02b5d1db2d1852fb5ac4b2dc17f3');
INSERT INTO blocks VALUES(310099,'3c4c2279cd7de0add5ec469648a845875495a7d54ebfb5b012dcc5a197b7992a',310099000,NULL,NULL,NULL,'49f33b269d717b56a399843cf4627449010133b47079134b9e299ac5386468ee','17a0243d598c7b17735ecb6f6425ef4d51e3f298491bc76fb4f190e8cc26e0b1','98e4290b537674b70ec9a8f8e4893e02cf3589f52761ad27b3f518891095545d');
INSERT INTO blocks VALUES(310100,'96925c05b3c7c80c716f5bef68d161c71d044252c766ca0e3f17f255764242cb',310100000,NULL,NULL,NULL,'c9e72f7db2950f0b0e6e8fa3bc47d37a0d643da6ec61b236f7224b63ac60467e','0da377b05ee306cb8befd839437fbc72c53e7b0385b2fde5374d2cf1f29b87ac','7f4af309e283366e574b5968c93aa543c648e01a0ecbfad9cca4c2a282b960ca');
INSERT INTO blocks VALUES(310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,NULL,NULL,NULL,'a4387c8c785a8407f2dda176a7e182617904e7ce00c695ea8aa2f9d0429d9e74','a001d1cbb846423540c59778e3d6830d801994838b526a50bbdf7fb797e00e27','b582489dfed070914a5bd2b891acde198ea6fe13e15062c45fc77c1009fa2326');
INSERT INTO blocks VALUES(310102,'11e25883fd0479b78ddb1953ef67e3c3d1ffc82bd1f9e918a75c2194f7137f99',310102000,NULL,NULL,NULL,'fc81f97474f7b35ef92ba93de82d38650a28afd140d3320e6f6b62337cfd1e94','213e8d4d5c74487348f757cad74f6bb4ab661bbb266b70340411a56ff193bfcd','83632211471226fe6088f5c4023cdc67432e5d1c74d39cd03db968b8a335f96e');
INSERT INTO blocks VALUES(310103,'559a208afea6dd27b8bfeb031f1bd8f57182dcab6cf55c4089a6c49fb4744f17',310103000,NULL,NULL,NULL,'3a502a89a3b66438cd2b944f8951a78999ba18c5f5bc8abeafe373ae4625ed4a','cf04379c7da902c9f6f95655c88f637d6fe2aa41bad6cddbd47835b94bd1b3ab','d52a2f411cc766c9cb5998890ecaeab3276f6d6766aa3a1b175b71e811f43b49');
INSERT INTO blocks VALUES(310104,'55b82e631b61d22a8524981ff3b5e3ab4ad7b732b7d1a06191064334b8f2dfd2',310104000,NULL,NULL,NULL,'74ab5df2cdd13b654c80ef12e460120c96ce30d4690a06671474235fb93fee4a','2f0a0d597741bdb9d9125c28d79b552297e90abd40166373e23e878162097bc2','a0de4676fb6d08e88057663149796d0593e1e351615ac8545bd779ee002077da');
INSERT INTO blocks VALUES(310105,'1d72cdf6c4a02a5f973e6eaa53c28e9e13014b4f5bb13f91621a911b27fe936a',310105000,NULL,NULL,NULL,'dcc1940370421712cc668dc401169a55dd7077a49feddfd70e9e455aa5893962','ffef0b5c68ea2a259d1bb107e2df2a9065b818c52ab2b7e2328c826d400c6742','a5d1877c949490f60c5e319f56325ca149d309cad9fafef995e6b6b3850be666');
INSERT INTO blocks VALUES(310106,'9d39cbe8c8a5357fc56e5c2f95bf132382ddad14cbc8abd54e549d58248140ff',310106000,NULL,NULL,NULL,'6ec3678f9b647dc1ea3dfd0d76ffd240da9a94097ad29e48e7b327d6198f4f78','3977bf04c5dc9c78cb6a69e3937e3323780de4b66ceafec3e71e892296af58d0','d6f01087b3bb99abe06d5c08efd2472bfdd1415927957121e07588c7495b20b3');
INSERT INTO blocks VALUES(310107,'51cc04005e49fa49e661946a0e147240b0e5aac174252c96481ab7ddd5487435',310107000,NULL,NULL,NULL,'8e3c2d75c7a81175405f39386e2367c7a655afb53d7cf5b5c2e7dd2c79a40d9e','81bd8b1ba8dffe65e2d7a591754d442095b03fc77287b9a347c0c05e776b3317','034dad11b664451f976de24d1be1404d78cc295492ef8b7a9506219ff09091d3');
INSERT INTO blocks VALUES(310108,'8f2d3861aa42f8e75dc14a23d6046bd89feef0d81996b6e1adc2a2828fbc8b34',310108000,NULL,NULL,NULL,'b00c403723eba6ffb5db3d9903fbaa8a04a783c61949b9220e2caece1a8b86eb','b1581a3d2a8340e7a9dff140046b6047a82aa8eb2ab2720cf2674d0bec9ebd48','1a11c34c02d351d8937ebcc75aed21fb220d56b2077f10d0265e4e156bd91115');
INSERT INTO blocks VALUES(310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,NULL,NULL,NULL,'69d2150543fe997a6685eac965283a3e7c9d3f9aa4eb2e08e8e4fe7a15054d26','25eeb18ee893e76cd28de354996db63ce0f528195ea8a9e6a0d695049519708d','094fc1610fc2b261a0914fb4b2f4cb48d9bdb5dffea71a5d87f32962951fe4f2');
INSERT INTO blocks VALUES(310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,NULL,NULL,NULL,'0122bef9da908b66c64aae0057d2052e1333c7e71075aed739de6838f03802a8','6603c3dcb9a7998780659653b76aac813da55a712353da79663d0fcff58c072d','da0e3d6717bcb567bf202b6505d414a7a2d73ccba6e0d377a9d2615619964919');
INSERT INTO blocks VALUES(310111,'fde71b9756d5ba0b6d8b230ee885af01f9c4461a55dbde8678279166a21b20ae',310111000,NULL,NULL,NULL,'49a00fd428f32aeceb007f369ea525cc441d8d9a61dc8363827267be369a4246','12038e87f418c8a19ceae70e28379a5dbc4a4081f8c7b5b85fa434c35e59cb21','041e25012835f8b6016214f1bcaa9872b814760600a7b8331328ef259a304889');
INSERT INTO blocks VALUES(310112,'5b06f69bfdde1083785cf68ebc2211b464839033c30a099d3227b490bf3ab251',310112000,NULL,NULL,NULL,'73408dbef654d26d0fed995ab45086900457c0cff0bf6d4742009b07cb28dc5f','b043344cef181c06a0c1d0acb465fe21ccf6e400493d896eef6525a1444391f1','975828b72f9ef713d7cf21fc3ca98f5e7566b4551983bc1416df2b40565f76bb');
INSERT INTO blocks VALUES(310113,'63914cf376d3076b697b9234810dfc084ed5a885d5cd188dd5462560da25d5e7',310113000,NULL,NULL,NULL,'b6fd4640dab07208f13edcb93e3e2ef3b3d8a0fff82414cc5c08003a368d6e26','54ddbc604c22d9718b992776e7f95b971f0c33be919558ee2e21a2d347ae75ed','0cde4d6705ab91ee985d246302aeecf3205ee59c3e657a36f8234bd22e6948fd');
INSERT INTO blocks VALUES(310114,'24fc2dded4f811eff58b32cda85d90fb5773e81b9267e9a03c359bc730d82283',310114000,NULL,NULL,NULL,'15331b1af6f2d4afaa5baf698095eeba47676362602de1c4cd1ca3db354f9d44','89fd952c90e099232c8b6fec0f1695e4aa438e342d1f62f9e243e0c8a8dc22a5','11518dfc4af425c1d24f11b33b32fe24e80f3424269b09dae4eea1a8e312ac87');
INSERT INTO blocks VALUES(310115,'a632d67ff5f832fe9c3c675f855f08a4969c6d78c0211e71b2a24fe04be5656a',310115000,NULL,NULL,NULL,'562301bb223a9faaa0dcdb385945972f69b98cdb80df6febacaf20e91bd1424b','a2045e0b6f0674bbcd7c82cb20d058d8375a984a86fe41c505c644925609e964','2569120103555a1944d924092e67d5a3d9c1334e6959eda0d77782f533f2248d');
INSERT INTO blocks VALUES(310116,'8495ba36b331473c4f3529681a118a4cc4fa4d51cd9b8dccb1f13e5ef841dd84',310116000,NULL,NULL,NULL,'39109781867b10ccce6685654f980d112ee059c2ee254974493b6deae66e4c8d','74b53f81fe3c6cf74f74da7f6750284441734d9eca1f4f394404198f79cf9a39','9888e72a0f37a18791eabc5ad31d1b665f30f6d418559c8b265742196c09d30c');
INSERT INTO blocks VALUES(310117,'978a3eac44917b82d009332797e2b6fe64c7ce313c0f15bfd9b7bb68e4f35a71',310117000,NULL,NULL,NULL,'e5e53e9dbd584b9de353d4ecb2a041696aaa74e3fb8d010da4c0a9d152bba637','74f7cf3d1b70df28476741a73dab5301e87a542c031ead38df87446fd742f850','a38d9673284d6f9e435eef2074eb501d936bad1b3f57b77e2209da053bb1df2e');
INSERT INTO blocks VALUES(310118,'02487d8bd4dadabd06a44fdeb67616e6830c3556ec10faad40a42416039f4723',310118000,NULL,NULL,NULL,'a09a163e6df773016c858fd511d86801450c8f3d39ea042c1d9d080bcb22de57','a0ad27e38781d68213c3855ab2afbd9a131653470505aab5410e2ea4d2242af9','78fd7cad1e80495ba274951037fc5b3b1b73374e9117f79cb2f2d21184467c4d');
INSERT INTO blocks VALUES(310119,'6d6be3478c874c27f5d354c9375884089511b1aaaa3cc3421759d8e3aaeb5481',310119000,NULL,NULL,NULL,'3e7f98bcfe526a5d40afd5be9f18be23b51df00d44c77bd474e24d2a301f58b1','e31b1dfae4ae85378d58bafa70f740379acc855a6363e39ef507d5670ce7fc23','c06b631a3ac7f44728027f81626ba8786a32bd92e3f94e5daf4f6a92dd256433');
INSERT INTO blocks VALUES(310120,'2bba7fd459ea76fe54d6d7faf437c31af8253438d5685e803c71484c53887deb',310120000,NULL,NULL,NULL,'e25a095976c634d8fc304d1c99a57dff996791d169eae79b07be56672d07b89a','aa75357847f0e5ccb3b97b19cfe7b9fdabf72131a6d9919cad7bc75a3f95437e','5034c0bb2e61ed21c7058479529a2950ea9ce866114604b8dfc7503c71f4a64f');
INSERT INTO blocks VALUES(310121,'9b3ea991d6c2fe58906bdc75ba6a2095dcb7f00cfdd6108ac75c938f93c94ee7',310121000,NULL,NULL,NULL,'a304e244fa62d8d5aa2e1cc5794ac6937dda877dd7a9b001a76caa5940bf15d0','8073ac96a5021c24e2c207980fc34d74a9d28640fb1a7ff9f523db12f7d3fb6f','34acf7677a631bf0ecf267e627c76c98fd891ff3c1dc2ba4ef30c76d14ee0232');
INSERT INTO blocks VALUES(310122,'d31b927c46e8f9ba2ccfb02f11a72179e08474bdd1b60dd3dcfd2e91a9ea2932',310122000,NULL,NULL,NULL,'8f5d2e4c877106dadf95774ae5998bc5a82ccf664c4bcbbf19ae00d99ea8fb48','4ed9679060dc714e8876202384c26723e82cae040f6b7dec6ec8f4ed948ef806','264b768c9e61dfa37779f3a912b96cb3a629a94c4d221bfaf8a9ce75e5d03632');
INSERT INTO blocks VALUES(310123,'be6d35019a923fcef1125a27387d27237755c136f4926c5eddbf150402ea2bbd',310123000,NULL,NULL,NULL,'3813de1076710a8e0a119d9e88d9c4a6a2d8699a41f6f65f569192eea7813e30','8e687b485e23db1ca44af88f852f349489080c15253dc2b0043e3b90bc6086ae','bdb03411ba48233c1afb0510826e4430bbc5a3a31aed7436bf4c3938e9a8d39e');
INSERT INTO blocks VALUES(310124,'0984b4a908f1a7dac9dcd94da1ee451e367cc6f3216ee8cdee15eae5d0700810',310124000,NULL,NULL,NULL,'7d334bac66f0649fb0c0847b5b63b726c9df5244f95629663068ed1304aad32c','48e4993a0e013e68d94a2bde7ef6b2ad15ba807359624a19ba51abbb43f52d14','0f459b2449ac94e110a540339c9dac6fb298e60129b80d67926e80ec07b1f642');
INSERT INTO blocks VALUES(310125,'cc28d39365904b2f91276d09fae040adb1bbbfd4d37d8c329fced276dc52c6a6',310125000,NULL,NULL,NULL,'b79349c4e0c45f841e5a22ef7da535c90e7028553af7071ab77e374f0311619f','0334b46f19b20f5202b513c6bc14ff28dff4f6e875f340fa31ea8c59bb5794ee','5757c7148bda668d4221e8b09138264b5588ecf5c428bbd27602109e45921cc6');
INSERT INTO blocks VALUES(310126,'c9d6c2bd3eeb87f3f1033a13de8255a56445341c920a6a0ee2fb030877106797',310126000,NULL,NULL,NULL,'90ca9c1a8c1202fe4576ff16d960150e054cc13a25a9599fccc1ea2cd1e2f9fa','0b8b5ce8eab6030a38b917e4c74e9bedda2f2bc2f7615cd24b8c0ab660a64a76','e32fd1df8ffda61c7f2ecf31ff39e4b9f91a38c849838e8334baeb422732d406');
INSERT INTO blocks VALUES(310127,'c952f369e2b3317725b4b73ba1922b84af881bd59054be94406a5d9bbb106904',310127000,NULL,NULL,NULL,'9ed16371f64c8df47f177c4682a24b82e97f3698ef8e341994666b43b81bcec0','2ac1ac3d6b5c33bbb30fd99f530b97d2a35af8b10fc431703c00b9e3854191c3','c757d0ff0a71b0ae3e9304bde6a0ee15cb5e1d81db796efe71500b4de3c8402f');
INSERT INTO blocks VALUES(310128,'990b0d3575caf5909286b9701ece586338067fbd35357fec7d6a54c6a6120079',310128000,NULL,NULL,NULL,'1eb4c64df114ca9e1847ff41982ccbe99de25e603705f4151f2223dad7cee244','9951afbc38f51e0044aa9a21076b5b3accfb105908486bc1e6536682e0a5ae00','7ae0eb05cf0b9ef9374f9cf1ef5687266f4861349a990af22b9f57ff3b890418');
INSERT INTO blocks VALUES(310129,'fa8a7d674a9a3e4b40053cf3b819385a71831eec2f119a0f0640c6870ca1dddc',310129000,NULL,NULL,NULL,'a523fcc05b2286044ecddbc5fd3645c0dbd67eca6b37d1701aa3d6b3b85f25c1','82aa07a40825f202d0117c6c682f81e0c53011f02e5e02da603b3dd0f4fee491','680ee322b492f6ebcda9e16c9cd2f3e4c09d985d890f62661a8e2eebaeb7ec23');
INSERT INTO blocks VALUES(310130,'d3046e8e8ab77a67bf0629a3bab0bea4975631d52099d2ddc9c9fa0860522721',310130000,NULL,NULL,NULL,'cd73a5511a2ef2c8d3215ffaf1624cc83f37b3373195664def993f78aaa3ad8a','0b66f50d5fe337d33a3f83b87e719f6c2e59c51bdb8283807333221f0f6905ad','ec2579137acabcf9ae35dedbdbc22c581b23ae94413d351b598c9c37d7967e2c');
INSERT INTO blocks VALUES(310131,'d6b4357496bc2c42b58a7d1260a3615bfdb86e2ce68cd20914ef3dd3c0cdd34d',310131000,NULL,NULL,NULL,'e3f13eb9a391cd60c52f20e332d4c4df2ce638dd43782f5cd70aa53f15193dc0','7e9625ee6032cdd9bff04b924ef7615162a8a45643393665e9fafb7d8ea53f9f','4ff3608e1b3931e603b8d7c28b327bfdf0617d8fcdd7067d3c50063f54060bdb');
INSERT INTO blocks VALUES(310132,'1b95a691bf4abf92f0dde901e1152cc5bd87a792d4b42613655e4046a57ab818',310132000,NULL,NULL,NULL,'175add2996fbc421ff96db0155f06811f180828a028cf8c318fff27b4a2ae616','e1171bdf4439b5e3afb3e915c19b3aaedc45a825ee3f1b7b9a6ef6a7bb5eb332','11c32049e39adfc489e109335d8be4b0ebac3dfe5a772b8aed60dd965b075c2e');
INSERT INTO blocks VALUES(310133,'1029c14051faabf90641371a82f9e2352eaa3d6b1da66737fcf447568ca4ec51',310133000,NULL,NULL,NULL,'393fa3d964c240a640a5d97e9eaabdfe0888f5416f442b8208e91ed2db960d0d','bbfde7e489c39767a78bfd31c2b910a6c583f1aff340797a72d7fac055e4df1e','32b111d8643c5987933ff1eab795ad1c3096d98b9abe47b52d02fce50212eaa3');
INSERT INTO blocks VALUES(310134,'1748478069b32162affa59105257d81ef9d78aee27c626e7b24d11beb2831398',310134000,NULL,NULL,NULL,'f3755c96cf0047f55f8bafe73b3b7630570b07388925160be2994888e5fae26f','10883ebba1695a2e9c83f7e7a2ef76b8d89dc1bfad9efec6be3a93d99a262f8e','9385dfbda4f251ee6d70f90a424584434554f6b382f604fcc6735e79bb4b861e');
INSERT INTO blocks VALUES(310135,'d128d3469b1a5f8fb43e64b40f8a394945d1eb2f19ccbac2603f7044a4097e4f',310135000,NULL,NULL,NULL,'bbf124080daed02dbec9fda618453d4e3acbe4962ff7cc240b2f4ba169ec2ff6','4b8dbf4dc9a4d3fc59fa3d7408f4252297287b263a6b2dafbf4abb4025720103','4bee9d96877ef748f38e7c3b9dd13536d25c45f1656e5dbb387c900d8b7d96dc');
INSERT INTO blocks VALUES(310136,'6ec490aaffe2c222a9d6876a18d1c3d385c742ff4c12d1334613a54042a543a5',310136000,NULL,NULL,NULL,'c94ecd45423dc47d9d9973460ca5d759052b628fc3fc296ca8742667707f4939','726c8f91647427d5d0815059daabedd58619e2e0d6a6e42bec04fdedaebef06f','10afb689221ac9cf8bdcd153ed2a917100af25983b8d256f26311402617b815b');
INSERT INTO blocks VALUES(310137,'7b44f07e233498303a57e5350f366b767809f1a3426d57b1b754dc16aba76900',310137000,NULL,NULL,NULL,'dfcd8b6ffd670cfcc4c8d7af5c3f28c0bf31ff5e50c051fef482f08e546e0883','255090c1591bca2763e5cb4395363d9c2919271e0601150da01c52f8b859912b','41df4e22edbd85cc21cacfeded21d17ffc209dc2c19b47fb81a5366fc6a36e55');
INSERT INTO blocks VALUES(310138,'d2d658ccbf9baa89c32659e8b6c25b640af4b9b2f28f9d40baae840206402ab5',310138000,NULL,NULL,NULL,'93fe7b414d911ed3dd965f64359cab2bb7c6bf4793d082d6138e985c89ea2a90','f00d57367d1dc6bbd6efcb4cb4e99b329bf8335a5c801776db9349eadab8c1bf','a83db05104e873002431636719cbb3be30f8d6a246f42c9984d43c6d3cffd16e');
INSERT INTO blocks VALUES(310139,'b2c6fb61f2ae0b9d75d18fce4c52a53b1d24772b1ad66c51ca51090210527d46',310139000,NULL,NULL,NULL,'335ac735f34eeebcae004d360be600db736b036724a05ee1157a784de23ff2be','11fdb458a6db0dd19a3302cc772c916bf93da8c9112bf4d8123f9a05c3846363','80dc85ac719a2969e73d99b7412d2e3a5d65f3d0b993935de18e6ceda9fb64e9');
INSERT INTO blocks VALUES(310140,'edddddea90e07a466298219fd7f5a88975f1213289f7c434ed47152af6b68ebb',310140000,NULL,NULL,NULL,'c9a8dfd86f9065fd1777ec3a33adbba93f54dff190232c5e2d3259533b731049','acadefcc9ee917b8d67418cd53d39b854800975f21a3eff11ab546c044cf78c1','c76748659fa539f41c03fe4a74855216f8becbf31e187983c7720726c9fe4685');
INSERT INTO blocks VALUES(310141,'b5b71d2a271bd638561c56f4ffbe94d6086debaaa86bfeb02ef0d71339310709',310141000,NULL,NULL,NULL,'25b9fe20b7cd9febbd95935520eb9a14028e0b68f30680c8c24c2c4334b0efca','a0bc91ba96b620d1b38d9450d511fd411d477397b1c4ddf4c238fae51797bb73','88794ece65e9fd3ba3fb333dd319ed4c286e139c7b366fc272a662d849fc5e02');
INSERT INTO blocks VALUES(310142,'a98ae174c41ab8fc575d9c8d53d8e02d8e446b8c6c0d98a20ff234eba082b143',310142000,NULL,NULL,NULL,'7afb2942121f5964cdedc562436fecee13fa2da5bf1cf7c9f804c12fceafcd14','e4c4e48888d8584e7a76bc0b0991c2149b2fbbaf68f1a5eed5bfc9cef9490223','38609825e3a06a9b43746502cb3fd2f95a7e6cb4d7ecf82f5a33a1c73be024b6');
INSERT INTO blocks VALUES(310143,'8ba2f7feb302a5f9ec3e8c7fc718b02379df4698f6387d00858005b8f01e062f',310143000,NULL,NULL,NULL,'6aaf41ab7b1df44ea8af8eaaa3db022693bf7d28e54fd7f8b76bb8d5ef7460b5','ec0869cb46af48fcf7ee50ba70e6d4ded8251e46cec725e2c364355d74791e00','50dab5fff5c98200ad61d1747195a149a2a4a051948f180289576ffac3e568d5');
INSERT INTO blocks VALUES(310144,'879ffa05ae6b24b236591c1f1537909179ed1245a27c5fdadd2218ab2193cdb9',310144000,NULL,NULL,NULL,'717c58bfc0b8902f88226c3e9435ca0c86858ae7c508242164627d287f5b1c54','00129d696bc6bd3ee6dca89e53a071ae7817b0ef0d8c4948b4556e9cec02e37d','b8990a4895b220422d7ab80541a1eb80b2169c765700f4b9c2cfdc30b115c561');
INSERT INTO blocks VALUES(310145,'175449ef0aa4580593ad4a7d0c5a9b117e1549ea772af00caa4ccdc9b1bf7a6e',310145000,NULL,NULL,NULL,'eb40cfa9c75acf9283e431b44992016f494b7c57cfeae335b4bc15a508ac6440','7c71603d8d9193440d104a7d7c3b0808abe3905b8682dab0df86df5e676c16a0','dfd30ffee6c24915963b4186947825f97fbc0f7abc80bf482761609e28e9871c');
INSERT INTO blocks VALUES(310146,'e954ab6a110455d745503f7cc8df9d92c1a800fafdd151e7b1912830a9cb7184',310146000,NULL,NULL,NULL,'10605c98a2fcc410635882ed1bbb7dd8756141e4f94ad639060f60a378e6a45f','a8f457ea4cfb7d4af8770ad5f35a272100f502e0368f38e3ed25c7d50519e9d8','40b4fe4bb2a78ccc15a94209a4cc3ec1ca3f169a351736f03ea146600fbeeabb');
INSERT INTO blocks VALUES(310147,'7650c95eba7bf1cad81575ed12f32a8cc36281a6f41bef13afe1dfc1b03a7e83',310147000,NULL,NULL,NULL,'32a9701b3dc584e3d58d42a92a17e8b4731737d98e820e0a365235c5a9b9664b','5cb602849537ce934110513258319b3546e8d5bd2c42aebea2bd0fdee5f99597','fc9231443bb32853718ba0bd0b94e463f4d00ac6c49065e1efa77c3dd184d700');
INSERT INTO blocks VALUES(310148,'77c29785877724be924f965215eb50ffe916e3b6b3a2beaea3e3ae4796545a7e',310148000,NULL,NULL,NULL,'3227e65ff7d650e6885c37706a3ac684544b1baf02b7376bf41b24c3893b6889','a6bfc6477437573cf471ab7f434a4a9058de19c544eae5d04c9147bf2215f8ca','e71cc6955a6e73514ecee1d34a9cc65a7dec81a55229fdc48da2430daded672d');
INSERT INTO blocks VALUES(310149,'526b3c4a74c2663fc04ed5234c86974bffddb7235c8736d76860778c30207b3c',310149000,NULL,NULL,NULL,'b26750b694cadf38f1ef4ba4385e5b1c6e3202b73ac1e5441c9e7b74df2c73e8','7e509c51902182045a4abc0877d5b286fb093ae8d4cdf3bc7c1818b372c2bf9f','cce0d019c67277ed94437a2de0d1aa8e8e2ee7479ffaead2d6f5d5a424b26565');
INSERT INTO blocks VALUES(310150,'cdd141f7463967dbeb78bf69dc1cd8e12489f58c4ea0a5dc9c5c01ec4fcea333',310150000,NULL,NULL,NULL,'6a5b436343532db31c6b4e3221fd95046cce95d557de06e1437e6aa9e41409e8','aab3678db5a612ddab772932aa0d51fdbba91093d3380fc9f17d78b1056f2ad1','8041dc3795b560432ab487db5624f8c530a742cf4afee995ea78b8de58cabd87');
INSERT INTO blocks VALUES(310151,'a0f31cc6e12ec86e65e999e806ab3bfa18f4f1084e4aeb4fbd699b4fe284b330',310151000,NULL,NULL,NULL,'6947ff7d212a91e7d0e970c66b7be7e5004f16c5f61b6588289e4dada52a006a','16bb1b62e8e94d3c4098a7f75e7cebfca5723cd1299447532eacc8478234657d','6b5e0d098fb89cace81be2f8658f2040831cf9adf7095c063f2c3082931dd502');
INSERT INTO blocks VALUES(310152,'89c8cc3a0938c63a35e89d039aa84318a0fc4e13afac6beb849ac37140132c67',310152000,NULL,NULL,NULL,'3a1688883d46660a06743efe028298314e675c7697f4c21111efa11e96feaf12','f5ff0becf2809d031359e134f594044f5c847c7b0011552c3f6399b6e4a1af99','46a10b854737a49cfcc7173fac0c4bc15a5ce49b9d6449c7779d399777240e0f');
INSERT INTO blocks VALUES(310153,'d1121dfa68f4a1de4f97c123d2d2a41a102971a44b34927a78cd539ad8dca482',310153000,NULL,NULL,NULL,'4b591678e9855c12439f3e99183c059cc9c241d77c2efa8fe9a7d8eb5ab19aa8','d89357705aafe9c6a99e8ebae5c328df41eff393d54e89d603f28788f5572f64','c64a5a07190cbfe52f6495c662958876f26b746217c709ede40e3fc0761f9d3c');
INSERT INTO blocks VALUES(310154,'ba982ea2e99d3bc5f574897c85485f89430ae38cf4ab49b7716ed466afa506d6',310154000,NULL,NULL,NULL,'72bdc66f2cf451dc725ef21c5c28b341ecf4740b9c77fd504ee71fa23ffd15b2','0d2ba86e439a423f833a6aa5d0bf5935d39ae257542b53b1e5652e0b8b0f780d','2f7b78204f4c87201308e254175b8c023ea188429ae1dea44d04e28d30402b56');
INSERT INTO blocks VALUES(310155,'cefb3b87c7b75a0eb8f062a0cde8e1073774ae035d176e9769fc87071c12d137',310155000,NULL,NULL,NULL,'f58ff397780084f773480020d27c2bbe673513a415726fc2264ee0ab0816ca5c','ace2d0004e21f5752c9e721b443b90495d64a0272ef6d8b3f9ad8710a49a2bb4','da52bcf7661075ad99083f4d797364633cbc3eb4eee5574bb507fe6619577400');
INSERT INTO blocks VALUES(310156,'6e3811e65cb02434f9fde0445a7a2b03fe796041458737d0afcc52208f988a83',310156000,NULL,NULL,NULL,'93075637621806c58d42eb4193333e1020f45fdc57afc9993d9ce450a40e69ca','54bb1c92abaf6040b3cda464047aeadd3de7f3921157f43c99fe3243c1785670','ca8224359d710501667a63260e047596119cf0891185d09f7a2d7f5edc4413ca');
INSERT INTO blocks VALUES(310157,'51dd192502fe797c55287b04c403cc63c087020a01c974a565dd4038db82f94a',310157000,NULL,NULL,NULL,'057d4334e3b111703f2dd2740ec020ac4ac6fd9add0f84eea9db0c5af74cae9c','264ddbe0dabc3fbb4741381276eb268fc91dfefb5aa4e468a84ce995197f3030','2daa87bcb9a6d2124709604758bf4344259cb3cf62733d3a71798526285dd634');
INSERT INTO blocks VALUES(310158,'749395af0c3221b8652d31b4c4410c19b10404d941c7e78d765b865f853559d2',310158000,NULL,NULL,NULL,'3a4f70478ff21cdd2d0f9ad2029973938a4a87991f97120e146609f99b9e064d','515b180c6b0af11289294cd091065c06f09af88a25e3ca18abdded1691955f87','cb6ada5f90203e8056d681303d8394a6cdceba555ade502f4d8da8e50c467b8c');
INSERT INTO blocks VALUES(310159,'fc0e9f7b6ae99080bc41625588cef73b59c8a9f7a21d7f9f1bf96192ba631c12',310159000,NULL,NULL,NULL,'11a7b4768cda67f24fbe27de17d6b0b1fde09343f410e01bd0e7d076228f79e8','a8883eebeb2e32692cea0e4723b69fe49d542d7f8ce8b5a3d62d748506fb115b','ddcf97f58fdda149c46cfdec46334b6389836a585892643f9025236019163ed8');
INSERT INTO blocks VALUES(310160,'163a82beeba44b4cb83a31764047880455a94a03e859dc050da782ed89c5fa8b',310160000,NULL,NULL,NULL,'b591faf523005850e8ab2d6811e0d33946bc61217e64970248aca9b49d76713d','201fa3d7f9f1238e817e48e7d30ee210ccb8c03dfdd32c57aabfbc9cc7b73016','8768c863ae971de7d6ccd02bce1e30e986261ff024f4b380bd2ffb32f9d0091a');
INSERT INTO blocks VALUES(310161,'609c983d412a23c693e666abdea3f672e256674bf9ee55df89b5d9777c9264d8',310161000,NULL,NULL,NULL,'5d94813c1e85f4fa737713692228d0b249072b33fe0ae0a398a04d13e342ac0d','2cd52fdeb1203be1a13dcc1fb87c9d889442e9d08cc881b555098f0678c6070e','17070eb4910876cc80e08982fd8387a14e2771d464dbf6429cb3a12475a6e445');
INSERT INTO blocks VALUES(310162,'043e9645e019f0b6a019d54c5fef5eebee8ce2da1273a21283c517da126fc804',310162000,NULL,NULL,NULL,'905b5396c4a515f86d50450b7c43592c59f64607687ab81e77d12bf037705295','070c8276c80bdda16905459e9673d02acf5e6c0515c970fbd5059134b1b7c479','af5e69fa709b4df326b5c17036278843048dcaf17ff502e2c64088f7f61948b8');
INSERT INTO blocks VALUES(310163,'959e0a858a81922d2edf84d1fbb49d7c7e897a8f49f70bd5b066744b77836353',310163000,NULL,NULL,NULL,'26eaabfa4161b015b5e0cfe0443a825f4dd43a85b23f21c662a7036690fb321d','2be1f74609e3e353ad5873d153d71f0aeecb25c6c1186c608a46ddebf695f76a','6c9790deba97a95ae05d215a641a6f8122548b30e8351ecc66233579e2250bae');
INSERT INTO blocks VALUES(310164,'781b7188be61c98d864d75954cf412b2a181364cc1046de45266ccc8cdb730e2',310164000,NULL,NULL,NULL,'90074162137a93a03d448e5be94bfaa8a43d75dbefd52bb0f07a48cb4ee8fe43','df11b73f2c88049df698d327bcdaa8a817bfa8b7d84f92e6d986cba602d04649','dff0ebaec964dbe864556195120131a939798a000e8f4c314ab0ebf2bd924906');
INSERT INTO blocks VALUES(310165,'a75081e4143fa95d4aa29618fea17fc3fabd85e84059cc45c96a73473fc32599',310165000,NULL,NULL,NULL,'7c445a931cc89fc43f805158ee3823564eff2d958091a81808f02ff8a1a04257','37e04cb4360283f172f69ff6a5a6f208b75f88e86cf4cf81417dd93e3a317b95','4c40d791f6067d1f213e5594ca0a226f6937addd2660f4fa7a3e933b83f50ebd');
INSERT INTO blocks VALUES(310166,'a440d426adaa83fa9bb7e3d4a04b4fa06e896fc2813f5966941f1ad1f28cfb41',310166000,NULL,NULL,NULL,'d34476bf79559a798ccb7d1a80e73b0f168144c8a3eeb36c3b45d38983b45d6d','73c122df4e159d31adb274aa57788504f033fc2f58c43fc20d27e65d3005a799','068c230d42f46c762eb5eaabea3b3413e10d90aeb370854c8d19297669ccb6a9');
INSERT INTO blocks VALUES(310167,'ab4293dbea81fedacca1a0d5230fe85a230afc9490d895aa6963acc216125f66',310167000,NULL,NULL,NULL,'6ee3309b40e4188a804db76f66cb7ff7c50a958d2c33f4301787bd529658b401','fde85ad6eca8c4b26abf4528ed0b367fbd5edfd087759faa9ab4dc719036db14','3de56b17a1735c92a3d3f1629f2af5b6863c1a695103f1430f8dfd5df20f3013');
INSERT INTO blocks VALUES(310168,'a12b36a88c2b0ed41f1419a29cc118fae4ecd2f70003de77848bf4a9b2b72dc9',310168000,NULL,NULL,NULL,'25b984b1ffc627c1582cba862a70c624f581a48f73aef2f89f80df9f2a7a5fd1','3cbca0798f63e5a00854eda9aa2c07ec35e32f7ba6f0b0e6c9f947fc640b641a','bb8aa90e31b9e3b2ba069f91f83f71f1dd2fb9aff15b6d27e57533f79b678060');
INSERT INTO blocks VALUES(310169,'204809a85ead8ba63f981fc1db8ae95afe92015f003eaebbec166021867421f3',310169000,NULL,NULL,NULL,'e054b79e5599090c2ddc25b60f837f49a3dd6fa90601474e8e0e1def648573dc','585a289583b9df6ca540d51109cfc714820a81d3db44e2d3da9902e697379dc2','d5afd341c8de85d29d0a875ca2e0ed1d1e4620d8aca22dc5711bf4d45ce99a33');
INSERT INTO blocks VALUES(310170,'b38b0345a20a367dfe854e455e5752f63ac2d9be8de33eab264a29e87f94d119',310170000,NULL,NULL,NULL,'4cb925e241cd4453262eed678698f9c1c04ff561d7e54e682cd81f0f51d7ee33','6d4c5b2996870e670118877d58f589b98fb8e6a60113a67893a3120a377eda7a','379c1874778736d8ebc2278037d20387aff5483fc57adffe30eed0977753100e');
INSERT INTO blocks VALUES(310171,'b8ba5ae8d97900ce37dd451e8c6d8b3a0e2664bb1c103bf697355bf3b1de2d2d',310171000,NULL,NULL,NULL,'0fa196cd2a72c789a553354981e978a8e4199315c0b82e9cd1456be4d6e2a616','e3d9f6a436f1d8997b7f6c2d5e90ef85c7cba753b4e53199c52f9c1d3d3b1454','3be29c1fbe46440e760695ccc30ad808cc0af18cb991e34afa88db818ef4f2fa');
INSERT INTO blocks VALUES(310172,'b17fda199c609ab4cc2d85194dd53fa51ba960212f3964a9d2fe2cfe0bb57055',310172000,NULL,NULL,NULL,'0bb767b81670c4664e7747c6da3fcf9f44617fac4e15d35856bdb1b50dc01d09','35b0d6eb148a0c8208699244e973c461e4ee9f86846a5f67c4098b1a79ef3639','239a8477a81e689dee87f6e5680cd5b69315c9983ca0e52ad21c9b535ee9512c');
INSERT INTO blocks VALUES(310173,'f2dcdc5ffc0aca2e71e6e0466391b388870229398a1f3c57dec646b806a65016',310173000,NULL,NULL,NULL,'9151c76d6400ca1304cc90e095ae983df1b85768974ce971b0c81f56bad72017','d0f2da76f0fe2978c57a449ac4e44f3fb7389486d9cc1430eaf83ded5c3925fb','225787b74c1b95dd12fc306083b015982dae42b8bd322b366ca6fdc8c6b3fd4c');
INSERT INTO blocks VALUES(310174,'fa6f46af9e3664353a473f6fffce56fa295e07985018bface8141b4bf7924679',310174000,NULL,NULL,NULL,'f545b71cc2d3c54aed1aa76e805945ba6d60eae338fe908fbcef736997ab94cd','0529da9f861b796cc4555505804e1ce5e235b324d6b3e8f3c156a46ef4bfe57b','42e3c1b2d1a49767d8bdc1eca820950a3deb8d007384d7bfc6b0b902698146e4');
INSERT INTO blocks VALUES(310175,'f71e79fe5f03c3bc7f1360febc5d8f79fc2768ce0ff1872cf27a829b49017333',310175000,NULL,NULL,NULL,'b79792b98a1eef9c454965845e4e5f4d02fafeca8c8f7a37530b684918cec450','f66a6d132c93dba9e7a3f253721130157ad9f67960b1bcdf58326795ac866414','ad374054bb7cf5b7f3fd25d4ace98131597418cbd111d64af9454bd24e8328d2');
INSERT INTO blocks VALUES(310176,'67cd1d81f2998f615602346065e37f9ceb8916abb74b5762ead317d5e26453c6',310176000,NULL,NULL,NULL,'af9451c4142114c57be6dc3db5513fdf2af6d3eb570d60c980daca879c070f3a','2734a0d6945bd68bcf2487970c7fab2d6a83953103017c2c1d63db228d5c9ed3','3cba7753c5528aa336819560a288c9a0485d895d6ebe3d8bbbcb416f5dd02d6f');
INSERT INTO blocks VALUES(310177,'6856b1971121b91c907aaf7aed286648a6074f0bd1f66bd55da2b03116192a52',310177000,NULL,NULL,NULL,'77298849ddd8003f5783258af3f726c5d1a302389907c295ba5ca95933ba268d','8058e2e626b0eff32d58cb032fb8fab9d9f8bf9e0f057b793222c50a1c3967b8','4fc63ac404bfa0e246c5da39d11a8ef028f54c9a956d1bef627b3266685d5bb7');
INSERT INTO blocks VALUES(310178,'8094fdc6e549c4fab18c62e4a9be5583990c4167721a7e72f46eaf1e4e04d816',310178000,NULL,NULL,NULL,'a3e9f78a0a4fa92e039c5e502393627088c28bd8d719ea62067cbbe99abc64ee','bf9273d02a6c755dafa085a1a6e3921fa8880e45bc1ffdb7faa0730fa8efc042','fab3a64a9fdd5b80825cbf7a8865ffc3e9c17620ef451fff91b3f04f162ee838');
INSERT INTO blocks VALUES(310179,'d1528027cd25a1530cdc32c4eaff3751a851c947ddc748d99a7d3026a5e581a7',310179000,NULL,NULL,NULL,'51bbf86a836b4ba49c529d9c9736f07bbcc5205e9e589dd140c70c5df5730f54','81702ee1712254d68afd11da28466c122e353712edf78eeb7ee2712955131e49','e69ea415440deefd52e3d1250a111404e4c8045098b973229cafdea48e8974a3');
INSERT INTO blocks VALUES(310180,'f2f401a5e3141a8387aaf9799e8fef92eb0fc68370dae1e27622893406d685c1',310180000,NULL,NULL,NULL,'a9f269c4a96bda14fa9c790ab4e5fdfcb89849c101fb0d7f4c9b18bdc9311191','bbe6df478f181855a8deffb9ee1dc7d3b59d9117cb6311e746b45ad2fef2960c','22feab3f64c60eb340bfdac5b4b7e3376137baba542f1b9294650baf376b0c69');
INSERT INTO blocks VALUES(310181,'bd59318cdba0e511487d1e4e093b146b0f362c875d35ab5251592b3d9fed7145',310181000,NULL,NULL,NULL,'887cb900501f161553cd1b60fb22a61ffad2277b7e609fa7dc5bb36bead1ceec','57e8426cedbdf19328795a20cc530046572a45e1982abf99f09ec824b261b1a6','52329750236f8c4a9deb14f76b3eb3fb209f352d390d5ff3e2be57fa3aba068d');
INSERT INTO blocks VALUES(310182,'a7e66b4671a11af2743889a10b19d4af09ec873e2b8eb36949d710d22e1d768f',310182000,NULL,NULL,NULL,'a4c3f61d53da17890c6a7cb8c7433dc92a82cb8793059f3dbd82d44418e15473','7b6701b23a4499e145e99cf5bda4d70b6690bc7108cf63cf62516d13d2b6a9cf','95c9f752082e74b77cef9a25184128db1cf7be95ddc72084f6db1039bbf25cd6');
INSERT INTO blocks VALUES(310183,'85318afb50dc77cf9edfef4d6192f7203415e93be43f19b15ca53e170b0477bb',310183000,NULL,NULL,NULL,'634b4a3c4fcf2a1dbee7c62224ae64b9c7edb49b94d8735cd4a31f99ff2422ee','fe196e4c9d24d8b284197e7639aafa44c9456b42f5ee7097124fa5d8cb0c1cbc','cffcf632a8837ce1f7ff998b9bf5bddd52507b178ae8f18942d7f688fc730461');
INSERT INTO blocks VALUES(310184,'042a898e29c2ebf0fdbb4156d29d9ba1a5935e7ed707928cb21824c76dd53bfc',310184000,NULL,NULL,NULL,'bc9bb15c1df31ea471db00abe6e4b85ac512b6c20d975eec6dee06ef2fd949c5','cb171fb0bbdd5d3116d72168e6cb3d6f5fa75e45153c243bf3a5047d6b69bf5a','219bcbe7431ad75480debb0a0fb05ef8fb625afc8304ef3a16fda32b93565a83');
INSERT INTO blocks VALUES(310185,'bd78c092ae353c78798482830c007aac1be07e9bc8e52855f620a3d48f46811f',310185000,NULL,NULL,NULL,'c1a987ad2c752252992439c8f953d0f26002fedc10076e77fc08b6025028f9ff','1de444a38bd25f8622ea8eb392cf130f1a477a13d7ca13dab898349687b962c2','66b60e116ee6b1f829876f0cfccbc2fc6e4bc6a455c2a016017291e0f5ed773f');
INSERT INTO blocks VALUES(310186,'e30a3a92cc2e5ad0133e5cee1f789a1a28bea620974f9ab8fa663da53e5bf707',310186000,NULL,NULL,NULL,'ee30eaf6b3c727b97875c894cfc9d2a8d05464dd6221e53e0a205b48a8306bb4','652b8c4dc5cfacdfe06df75e7ee856ee20046ab17cd02ac31cb00e2228a9db8c','430136c24f279c5a1694d235bc9ee465045c83ca45962260c7bdb509b9e51e71');
INSERT INTO blocks VALUES(310187,'fc6402c86b66b6e953d23ed33d149faa0988fa90aa9f7434e2863e33da2f3414',310187000,NULL,NULL,NULL,'7d8e198708743486fc8243e462332e46ab865f923e6f6b2bd34afd99f0cca437','45432baf2bbeafa393eb7ec645805c8060fad0541f3fc17cd9dd9feee3d26a37','e70fb413c855122f3bab226bf023ca05a937285a5bf20f73f227bc359a6e4414');
INSERT INTO blocks VALUES(310188,'85694a80e534a53d921b5d2c6b789b747aa73bf5556b91eeed2df148e2ada917',310188000,NULL,NULL,NULL,'80f5d9581e0f4a1a7e7a8fd5f45c9fea0bed23dad4e6fa814230fade21e39105','a513b34f4783e993f65c58f41a8bf746de47da567ff3a4299e25d8dc9e345b5c','1a55a4ea56b8e8d5f8581cfed61cd7b8b7a1e858f4b5caeb8e8bbe4ae3eec75a');
INSERT INTO blocks VALUES(310189,'7c036dadf19348348edbe0abe84861f03370415ed2fec991b9374dbb0ca19a06',310189000,NULL,NULL,NULL,'3972971eb0caff6e12dbfd1eb9289758bb9e4ace842eb724a7125ab07fc80037','ecf9eb623f3f47afc77456b3d5eed0c82b023e2d3e01326d85d2805c4a45906c','7a756836483c681162538ec64c2418bf1bed28fe0dc7f81d0d40d8b0489cd0ad');
INSERT INTO blocks VALUES(310190,'d6ef65299fb9dfc165284015ff2b23804ffef0b5c8baf6e5fa631211a2edbd8d',310190000,NULL,NULL,NULL,'d02ff3b61e694a968992b86bef4cfb5381363dae5154a44362f11f2ecb0a490c','36e7389ee373eba10c47167030eeb5f02112906ec8e732f55882fdfb1a4d04c5','137c6969c953ef4f38210dee396b4eea19c7e90cbf40be0bf6e13065d1a78fdd');
INSERT INTO blocks VALUES(310191,'5987ffecb8d4a70887a7ce2b7acb9a326f176cca3ccf270f6040219590329139',310191000,NULL,NULL,NULL,'00fab2b75433646fd888aeed3f911a52d57f5136b28eabb575d2e280955022be','0e86a6460314c1f8ed49f50e80fab5f157773c2f9dfe80025eef828604d47af1','a3ed1accc4c6dd974aade16c58f63836a78fa93eaa5b4bf1d8771cf8c77a1946');
INSERT INTO blocks VALUES(310192,'31b7be43784f8cc2ce7bc982d29a48ff93ef95ba18f82380881c901c50cd0caa',310192000,NULL,NULL,NULL,'f42b1a405982fa5bab215d519a5e96cac547b8d4de71d13b1fe041aaaafdb8ac','9314b45863dee95017a307b8b0f0118e1f12ad330a0922707cf3c72357af315f','73896dc3e0afadac3e6411e6d43c952be8543e505bc5bef52e3729b4468dae40');
INSERT INTO blocks VALUES(310193,'ff3bb9c107f3a6e138440dee2d60c65e342dfbf216e1872c7cdb45f2a4d8852a',310193000,NULL,NULL,NULL,'f069a44fb76bdee924db74972c3bc520af73c6ad783765cbca0d36f10d79f294','52458e57665c59e9377b6f04932867ca4fe3429b6ceb577de17f252215b82975','d9f42c0dabf152fccce881c3832c5baf548b0a17e828bb8be1ec4c14fe67c311');
INSERT INTO blocks VALUES(310194,'d1d8f8c242a06005f59d3c4f85983f1fa5d5edcc65eb48e7b75ed7165558434a',310194000,NULL,NULL,NULL,'ff4fcf843c83e1cb9fa464cee503c9260d0b0184628b110edc2fb83854e3af09','a5b79f2bb44445493d0f7de3b743c26faf3c0597ddab1237218049325c88c251','a28ae86af02ccd11f03cc6b35a95988cb516a241b06613c08f566d89f00db751');
INSERT INTO blocks VALUES(310195,'0b2f1f57c9a7546faac835cbe43243473fa6533b6e4d8bf8d13b8e3c710faf53',310195000,NULL,NULL,NULL,'f3aa882a02683e7318041cadc811abe01ef362edbb48a5415ee640e8259c2aa9','51020d71d595dc193bcc6f630e98466f740a23ba21e9ab2d777f6ac7cf88216f','c7cc496bcdd42156fbcbbdb10a87e0c2aa856a1dabb533a7663c71f4b5c02946');
INSERT INTO blocks VALUES(310196,'280e7f4c9d1457e116b27f6fc2b806d3787002fe285826e468e07f4a0e3bd2e6',310196000,NULL,NULL,NULL,'05152803d10945b2a00e21a50baa0fb83659b1cc5d3917d590eca5671b86b873','3aec1668c8087f736687ce4ef05a2c1041692ac6c88d2ad2922ae1cd54a7918e','74766a1056efb2967bb2d2147fe7ef48e95a2e74f3bf8dcb5b733ada9d190cf6');
INSERT INTO blocks VALUES(310197,'68de4c7fd020395a407ef59ea267412bbd2f19b0a654f09c0dafbc7c9ada4467',310197000,NULL,NULL,NULL,'31dccc3d527891f01dc26e528bdd03558b74217ff4147ac251b8ea48af6a325e','81ba5ee69e162588fb8ebb6872b339c7a106d710f2fc0144b98b61f4ca26b724','a55298a67d1c84982dc1b4369aaaf93da41e93625ae9fcfade296cb2695da03b');
INSERT INTO blocks VALUES(310198,'30340d4b655879e82543773117d72017a546630ceac29f591d514f37dd5b1cc2',310198000,NULL,NULL,NULL,'8e9c4c52542a43023b37184f43f5fbdfcd27b9e3659316d283c600b6e6b0dc4f','3976c927ed0b58c103c80b512b091905099e846202f6f4632c6898609ebd2916','21112a82b262cb6f9e1e032ef505aad0be4f7eaa7797dd3acf8dba768e6ef74b');
INSERT INTO blocks VALUES(310199,'494ebe4ce57d53dc0f51e1281f7e335c7315a6a064e982c3852b7179052a4613',310199000,NULL,NULL,NULL,'cab393e0c3e510cc36e31c014e618e8affe68d19febeb28d480a492eb2bf912a','70339b11fe25b30e1da2e73f72aad7e4a313f7aa907b820d68874b95806c35fc','d6b0b03984def7f67e9853561f4698de06bb64ddb8ad2b4c3e8bfa07b2211a5f');
INSERT INTO blocks VALUES(310200,'d5169d7b23c44e02a5322e91039ccc7959b558608cf164328cd63dbaf9c81a03',310200000,NULL,NULL,NULL,'7b61228da5311040b2ef7c85313b6c55c54be29fa7259d5a2bb73606dc50875b','d75573161450078447af57b1f9ec3a145d361da766ec5515bf216f11fdca017a','d1a947ff01008499e8a7d248e02db853d5b1fc61a246dcf036ce66a969de057e');
INSERT INTO blocks VALUES(310201,'8842bf23ded504bb28765128c0097e1de47d135f01c5cf47680b3bcf5720ad95',310201000,NULL,NULL,NULL,'fd12ecb7ab66d9764fc967f40d9218a19570088eb59fe1858e3d4d0356dc0e3a','c015b47abd2c38c6af826c4271236a126c638980420bc1e502ae26a0e278ca40','f0cf816cd05f9e92cab6c1907441c2e553fdacc2781c81561f52977df446ff8a');
INSERT INTO blocks VALUES(310202,'95fa18eecbc0905377a70b3ccd48636528d5131ccfa0126ed4639bc60d0003d8',310202000,NULL,NULL,NULL,'cfadba271fed9b619b0eb069a79f6c513ad7fa95716dc64552bd91c807919de2','f9fd30c3843d4e0323ae8387b278b8142dd8e98546d60b15138d11c9fbfbfffc','2229864c757571529adb0f7d0f821a23c333684afcb72e875a0b1187c7da011e');
INSERT INTO blocks VALUES(310203,'ab15c43e5ac0b9d4bd7da5a14b8030b55b83d5d1855d9174364adbebf42432f8',310203000,NULL,NULL,NULL,'c9942ff7c2da747b65bc1fcc9df641e8806d2cdb6974eb6745f2bae362b41c66','4558d494c769b5cd51169c5517d6358ea69f1af9555cc59e779a0e38f0fefdd1','a02b3b263bfe83f5322b8d15f4b14a3cccaceaf23c30241d9c25420e79ef4419');
INSERT INTO blocks VALUES(310204,'18996fb47d68e7f4ae140dc1eb80df3e5aba513a344a949fd7c3b4f7cd4d64cb',310204000,NULL,NULL,NULL,'32fdf80d61a7a0acf9884c13857c1aadb625ac921c3933429cbd40745ed86b7f','607f4a7c9552afe1c2ef646fd2449d4bd37d560c273a62a9d3cf08c0a63bddac','173d594fb0b016a4a7a83cd8d208d926203b3538c13596fb2dbc16d5b9d4650d');
INSERT INTO blocks VALUES(310205,'5363526ff34a35e018d1a18544ad865352a9abf4c801c50aa55742e71630c13a',310205000,NULL,NULL,NULL,'1c3611f3d6868c7b222a0b1b5676a3b01c8ae0a8f91cc9b73f504fb7b1a24bd3','cae32e7030f87758d83dfc02f16b8418f85a1dd8eb9ab9fdf8e8d90729bc33c0','5381db3cd36f32359971ab35803de7ea84fb80eb79979834b43ad7c8b35c1d5d');
INSERT INTO blocks VALUES(310206,'0615d9fca5bdf694dca2b255fb9e9256f316aa6b8a9fc700aa63e769189b0518',310206000,NULL,NULL,NULL,'78ca99307956e3073a10e6c76ca4384e11d4ba886af31132352b30aaf24c4ae8','b82589ab2ac48db5652085fe549c8e109c9dc540ecd6ebfb8248cdb97f5c050f','cd14d8811908c2778ea2b71b46cf41ec0a7372b3378fe6547c007dea126910ab');
INSERT INTO blocks VALUES(310207,'533b4ece95c58d080f958b3982cbd4d964e95f789d0beffe4dd3c67c50f62585',310207000,NULL,NULL,NULL,'29b8a02219bf25dc65c29b87fdb173746f1e106fccf71b495d927b665d9e3c1d','1e6f49ec106cfb5fa5480688c2ddb9fec19cbf7a83b27896b525ddfffa094b10','ec65c6af8ecf30f23ada339ded6530c79c8f4871dec710bab1bfb16ab67ddc08');
INSERT INTO blocks VALUES(310208,'26c1535b00852aec245bac47ad0167b3fa76f6e661fc96534b1c5e7fdc752f44',310208000,NULL,NULL,NULL,'91145d36f28a38ff8b0e315551c5e71a2e43cb31672cbb2ecd780c8c211b6f11','f2681ccbb821ef7223cd39b0c13936e6ec3220085f66be0dc0c1f3777f5a3748','ba3b8897ffe0eb296c37ea5cea67108c7ba39aa00bea4329c78ae8eebb96275b');
INSERT INTO blocks VALUES(310209,'23827b94762c64225d218fa3070a3ea1efce392e3a47a1663d894b8ff8a429bf',310209000,NULL,NULL,NULL,'fac90d149fb0e7e65e3eb14d6a01f57a74d565b55447796badca8413ffb77fac','3922642227e87cfaf8a06adbf28e9cdcca154e5cdf238406424fb8068a539a4f','1d56d849acafee3b00dbb8330a581ece59b7eaa2d3ac0d5f697d2dfd1eefd146');
INSERT INTO blocks VALUES(310210,'70b24078df58ecc8f7370b73229d39e52bbadcf539814deccb98948ebd86ccc0',310210000,NULL,NULL,NULL,'146f2a9e034c04cff72bfde399c22558cb9ac98c102e3848c98f43d69741eef1','bbc640d6756a2a6b844717b1e33dca1c9f7492202e81412880e3dda239800f77','460f96a7a8887a981ffd303b89a92c7b919d17600b0c8180d91ba26a46f17c5a');
INSERT INTO blocks VALUES(310211,'4acb44225e022e23c7fdea483db5b1f2e04069431a29c682604fe97d270c926d',310211000,NULL,NULL,NULL,'0c6632ae436a364448d61c93cf6bda4013cd6ce627ec65a78cd87fcfec43d652','ce4c22db89356eb123818ed278d4759c22a24a26ce2b1ce0c1645d1a10cc486c','df573c573b0c1d9a598ba705b9880a57066cb2fd6a25fc3270e90360af7cfd3b');
INSERT INTO blocks VALUES(310212,'6ef5229ec6ea926e99bf4467b0ed49d444eedb652cc792d2b8968b1e9f3b0547',310212000,NULL,NULL,NULL,'d25dc77993f6c70c4ce3ea3fe9afa0af15f2acac6aa9386f1650ac0172168608','278ebbb2d26ffbd0cd1c207a79071d5c61dd9a8caf31f8f289f96870e0ce222c','61ce4372896076e2df2f172848ef61f440aa7a8c18edeb8eacac2b4105ee055e');
INSERT INTO blocks VALUES(310213,'17673a8aeff01a8cdc80528df2bd87cdd4a748fcb36d44f3a6d221a6cbddcbe7',310213000,NULL,NULL,NULL,'3d8ac279db5de79ab234d7876799ad80122d8402cf7a88d8add471d010d4c91b','d83baa71265eff5fb5becf09f014328916d436a7debbfd5af059e1b3e544bd63','2892c468d10ec5272a002884e939896f75b7abeb903a961dba94eea0137a0011');
INSERT INTO blocks VALUES(310214,'4393b639990f6f7cd47b56da62c3470dcbb31ef37094b76f53829fc12d313454',310214000,NULL,NULL,NULL,'4cf64fb7f09d2a08908be10ce759521c0a7516ec51967d00d577d835bd11c868','0bc1517b1464a31b93f5d5f0ba26d0e97509a76f9076a4af39338f437fde482d','17e4538b8a3b0b6047f839fd102e1e628574e064809e4ccbbf4874df07e492ce');
INSERT INTO blocks VALUES(310215,'c26253deaf7e8df5d62b158ea4290fc9e92a4a689dadc36915650679743a74c7',310215000,NULL,NULL,NULL,'3a07090bfb9aa6ca5fda5368e085576aa8848b433d0f94e8e620644766165e17','229859b33fbbe2955d0507593e7150f1d7cfda19c80f530d68bf99e5b59fe0f7','db4a110251186dbfb7be0e0c844881fc018df05b16beaa86b8b0c69262088d0c');
INSERT INTO blocks VALUES(310216,'6b77673d16911635a36fe55575d26d58cda818916ef008415fa58076eb15b524',310216000,NULL,NULL,NULL,'3279edd0d5778fbae35a5ef72e46bfe788bc57a102b3c6624c716d54e8b93637','db6e1c7c9b9fd1add781aa937717399fbf81ef0007f27466095363432510093b','db0f4ff21f4190686ab7b940e6d44e688c20a44ea55f91878d466e68f18e3497');
INSERT INTO blocks VALUES(310217,'0e09244f49225d1115a2a0382365b5728adbf04f997067ea17df89e84f9c13a8',310217000,NULL,NULL,NULL,'e6415e6fb4607dd941b8c4fd976a451db686882cdd58ee8541c86010b11bdb79','f0180d31c15066849ac6baf1e7d919f219649a06be3b261832a4b1463f8285ac','9be92219c1da91b15489bbe8a8bee15c54ddee61bd638f64fe9ff8ca405e4093');
INSERT INTO blocks VALUES(310218,'3eb26381d8c93399926bb83c146847bfe0b69024220cb145fe6601f6dda957d9',310218000,NULL,NULL,NULL,'74f4bb7e4cecab2e9e4bd7fad3a09efc55f30dea74fb03e2d8d7634aad3543e7','0886d0423dbdec31d96128791113be78998e6cb04d74849bb14a21b70006744e','71cbb37d39fdb0383a8d78013f6c7cc50ce53a738ee8c41767688219cfbc3cfd');
INSERT INTO blocks VALUES(310219,'60da40e38967aadf08696641d44ee5372586b884929974e1cbd5c347dc5befbf',310219000,NULL,NULL,NULL,'fc800fa313a1bfd0a3f5ae0a5adcbf6703d55914a74001c8225336f345a51222','69e4ada906bc5e8512ee1a25be6880f73a85d93cce7b458b59eea34864f5596c','04708cc3888d913efffd0cdfb483cf44ba8b1fe0673a4ead78ee938995e9ee7f');
INSERT INTO blocks VALUES(310220,'d78c428ac4d622ab4b4554aa87aeee013d58f428422b35b0ba0f736d491392ef',310220000,NULL,NULL,NULL,'4976b3c2f2820f5dd3736f0b16fd341a8f1e34bb83ac4d09586c6706e212c5cb','ee1f3b253f3b111b35a2b3dfc9432b3458ffb8182726ba62ed428ef5eb0a91a8','7350b957fa5c2b846d3b1150483d26a91ebac530991b15853a60b15d18ab6e2e');
INSERT INTO blocks VALUES(310221,'cf5263e382afd268e6059b28dc5862285632efe8d36ba218930765e633d48f2d',310221000,NULL,NULL,NULL,'d82ef083b71e343b047053a101c22d8a5e891c0ed71e1aded4a2e94043d662b0','c0c4a0271fd72245ad6b13a8ed9a18406dc8f48399aaa9ade96ed940ffa58412','f83536f38156957c9cc8ebe4c173941e5de4944fe3a99044ad923b3bb4e9023d');
INSERT INTO blocks VALUES(310222,'1519f6ec801bf490282065f5299d631be6553af4b0883df344e7f7e5f49c4993',310222000,NULL,NULL,NULL,'b61bcbc3003c46a07db65d40ffebc26e7872f302fb9b7a34db084684bd1affe4','3b7ec2e9ad2bd18fdce84ce4c78062cb3444ce428fea78047a243a67199ebd23','3d821de7d872f71c61c5055da952e2379f71241d960d1e8d0a5f8dbff75dbcc5');
INSERT INTO blocks VALUES(310223,'af208e2029fa49c19aa4770e582e32e0802d0baac463b00393a7a668fa2ea047',310223000,NULL,NULL,NULL,'66261293acf439c5ca9084615df434b3aa864559777d4d2506c9085a1a091a2f','75c1b53b5f7c65003011859b9c686f8f3967bb3cd0ce4c7b02c899a44177d2cc','865eba1fc6c3b80c75add405534d652564e238199609dca40d7c12c1cbe77e4d');
INSERT INTO blocks VALUES(310224,'5b57815583a5333b14beb50b4a35aeb108375492ee452feeeeb7c4a96cfd6e4c',310224000,NULL,NULL,NULL,'8c7a7cc828904b8d2656cfb3eac72fb0f92b50659d2a916cdc51a0ffd669c38b','8101e30d101a6d7711ce1fc3ad69d1d7c8ac8798c2831bcc0c7d4e52eb9c2a50','f2c448e92e27074ebce27a44cc72e9831361277a2cfb65f2c0cdb5339d643260');
INSERT INTO blocks VALUES(310225,'0c2992fc10b2ce8d6d08e018397d366c94231d3a05953e79f2db00605c82e41c',310225000,NULL,NULL,NULL,'b3c7a28c09dd001083dfad4762949bf603d49146f94ef6b00d152abc9c483e43','ad19cde785b437d969f675499396fd0bd34831e62622e0a2b2783591912083be','d9c830d331d1c8f3be1a9fdac4eb748cb94700593b035b9356adea1d3732d8fc');
INSERT INTO blocks VALUES(310226,'b3f6cd212aee8c17ae964536852e7a53c69433bef01e212425a5e99ec0b7e1cb',310226000,NULL,NULL,NULL,'26e7074b4d9ecb78a89a6957eb55e1f95a32694f774ccde5555a9c72b7c4d609','c14aef2fdb20ee64ffc5c2433bc607130bee2ce0871fa102d2bf4ebe03e452d6','dee42709baea7fdae888235d0a8ce11756fb79a2fa1b65ad1253e4d3872ae50a');
INSERT INTO blocks VALUES(310227,'ea8386e130dd4e84669dc8b2ef5f4818e2f5f35403f2dc1696dba072af2bc552',310227000,NULL,NULL,NULL,'8fd6eeb53bf25eb67b73b009a1da7c2d84b47dc2656f1c8f917d857e5e01d4db','80ecf473dea7ed194557f3e94c8957815925a44e7b1a32fcee98f243f66d9135','bdc2927f66b0dffedf2706b15dcb4c6c4fae09e4e90963f455c282ccf33409e3');
INSERT INTO blocks VALUES(310228,'8ab465399d5feb5b7933f3e55539a2f53495277dd0780b7bf15f9338560efc7b',310228000,NULL,NULL,NULL,'e88c682a2eef4ccbfee2b150097590b4761c689634ed8d3a3ee3d263dc64f434','3ce630152129156e46d80d55664bbed0fb3cfa2dabe8a6b1a40f88d4862ed8dd','6de6cd5a576e0651d3407e2d3258034491d36dab02424c46e7f1aa7a48c7ac46');
INSERT INTO blocks VALUES(310229,'d0ccca58f131c8a12ef375dc70951c3aa79c638b4c4d371c7f720c9c784f3297',310229000,NULL,NULL,NULL,'d7bb51d98ce602a7370e392cb34311a749c4c0d71a2f221ccfaef2197ffe7040','0713d4bca5f6c68eaa332b1a881335d30f4d9cb14db1776e80afe05e47fbc48c','2227dc8159eb4e2ddfe277f09669a33cf2d0665969c489e3fe0f47e01646f960');
INSERT INTO blocks VALUES(310230,'f126b9318ad8e2d5812d3703ce083a43e179775615b03bd379dae5db46362f35',310230000,NULL,NULL,NULL,'58825b187b2abf1587fc14fd2c7934455c71a61e09ca11ad84465d123893ed38','85808271515837cd2e50d8c893ecccd0101574fc7852cc20737812064a485733','3997104ee3fcd7536f772ecfbfd9309efbd11e243efa0157f5d6e3fc168c9904');
INSERT INTO blocks VALUES(310231,'8667a5b933b6a43dab53858e76e4b9f24c3ac83d3f10b97bb20fde902abd4ceb',310231000,NULL,NULL,NULL,'954586ad9f7d12b2963d641d3f022f4f4b83225af36d043cb4f27bf5d1a58df4','d8c5046819d2247e439a307b20d789bddec99835d915299b575c543f98c95b23','a15aa5a14520c570d8f675eb11ac5638a447da91034c874d89f1e6ae4faa0a75');
INSERT INTO blocks VALUES(310232,'813813cec50fd01b6d28277785f9e0ae81f3f0ca4cdee9c4a4415d3719c294e8',310232000,NULL,NULL,NULL,'ef5d71bbbaafcf0f3345a622d63a61b4fc0557ceee8d65e530f694872533034b','6b313d6608fb27a1ab2c5e42b2bdc2355a17ff572cbcd6cadd4c866246db0809','7423c60e54cf51ca7bbbc277c56787fdf6956ac34d3f31f6de0d67863ee1f2d6');
INSERT INTO blocks VALUES(310233,'79a443f726c2a7464817deb2c737a264c10488cac02c001fd1a4d1a76de411d6',310233000,NULL,NULL,NULL,'02849ed8e8b81985630681931966fe1d6175c1aeaed24eb4a0da299b2668af75','fea77eddb3c6526f88a92abb75746cdb7597a7836722cf1a827c5a8b7b270993','63515acc792089ce17faea80cf86127d77a904d8294ad1a943c349ea9177b2a8');
INSERT INTO blocks VALUES(310234,'662e70a85ddc71d3feae92864315e63c2e1be0db715bb5d8432c21a0c14a63cd',310234000,NULL,NULL,NULL,'67b47e3aa5cba82a7c0865b5192d1272f059479ba731ef6d2a70ff5c6fdb9cce','c9c637a04e41dc05acf8bf1d1b262eda753ba5971c7086a71d8af62115d5cf22','792d5d7f94c70c71706f7c3fb6f375e7485c6309ae5210fabb319c4444887474');
INSERT INTO blocks VALUES(310235,'66915fa9ef2878c38eaf21c50df95d87669f63b40da7bdf30e3c72c6b1fba38e',310235000,NULL,NULL,NULL,'96a3a8dfa5fe65f408a49c1d6e905ffc6b29f5bd407f17f780b102756921da07','4fbe9f2e1bdf5eadb728cd11c9a0bce9b90965c47e3aded1bdc205c275d108ff','1b18e0d246339eefb944942cffae12db9e443bcdc1157a4f4cd0d3adfed2c564');
INSERT INTO blocks VALUES(310236,'d47fadd733c145ad1a3f4b00e03016697ad6e83b15bd6a781589a3a574de23e4',310236000,NULL,NULL,NULL,'2289a09072646b03fc42423a05589760b0230837e3d25a10fe53e19edc4950e4','50d23ab2c670ff03b0c933fd172765f454938f69a708d7ec6c2a3ae0dd638531','08aad408958639a49fecfabd0ab1184a3f7f6a7145b016fdc72ec6d2f58d8e96');
INSERT INTO blocks VALUES(310237,'2561400b16b93cfbb1eaba0f10dfaa1b06d70d9a4d560639d1bcc7759e012095',310237000,NULL,NULL,NULL,'c2d27a61710e905dd38c2b27b341b2174d8911ed5b49bb12b9d852ad5e46f8ae','92378762c0a6229b3221fe878b533d2cfe8a30a0735c52459d848379b830bba6','f1ea1e94c862e6cb81131b299a1ff5af3941d1f26c9119ecae3a17b69bcab5a1');
INSERT INTO blocks VALUES(310238,'43420903497d2735dc3077f4d4a2227c29e6fc2fa1c8fd5d55e7ba88782d3d55',310238000,NULL,NULL,NULL,'800079b1e0e0c5a506b846bcf05f345d3b28ff00f513a46e8a35bfd2dccb0a4c','d77b1cbac7a4be0c0a6df3cdc1d9a55e90b9ce331205b1837be9fc2ad49bd590','d6ab1aabd077d588c2878a19d9a887ec4dee9a41d9c724d6ca316c7e9ee5d60c');
INSERT INTO blocks VALUES(310239,'065efefe89eadd92ef1d12b092fd891690da79eec79f96b969fbaa9166cd6ef1',310239000,NULL,NULL,NULL,'4ba81599850b4182174a2b48537b9550cb6946b36f3ed97f583c546664cc4d97','d803263db24c509d5e3e3db2e02850ab5355b7b8686c3cde553de32d4b95906c','7d391109772672c3f8b982d77cf4849125102b466fce82be1160ae67c1d137f2');
INSERT INTO blocks VALUES(310240,'50aac88bb1fa76530134b6826a6cc0d056b0f4c784f86744aae3cfc487eeeb26',310240000,NULL,NULL,NULL,'eca3433d2de70414a2c2fc0df4d76126e191bc399267f4bec0aefe356b29ed28','efff192125b4bd898d8f601caf48b020c95704af33cbf5f21fa3d1c6ee7f5c52','bc0d69d2c4bcd0ecf1ab7869ca10d1af4a6ea89552ad26191d20c7e49ec2ddc3');
INSERT INTO blocks VALUES(310241,'792d50a3f8c22ddafe63fa3ba9a0a39dd0e358ba4e2ebcd853ca12941e85bee4',310241000,NULL,NULL,NULL,'deae1463a7ff2333252a38ecbe34339610d08bf74a4f39481836197cad7a0993','083b81abda0d029da7d89a7136857a1fb46a5d8c062c78235472875eae2f469f','050906763fb6ff68367e29339fa10acc30b896880545aa60db7a6d9ae69b9c54');
INSERT INTO blocks VALUES(310242,'85dda4f2d80069b72728c9e6af187e79f486254666604137533cbfe216c5ea93',310242000,NULL,NULL,NULL,'9735c5f48bb72c767a15a084503deaef6d181716c363c742c7deb8295b9371b6','c0aff7cd45b049a0d68821ddff15780317a8e67e63883e39cbc8de233e0c4067','69229792f6f0844634de4580d5964ab4b273b415c7eac26d8043b645636b1d61');
INSERT INTO blocks VALUES(310243,'a1f51c9370b0c1171b5be282b5b4892000d8e932d5d41963e28e5d55436ba1bd',310243000,NULL,NULL,NULL,'de180d4b1d0fb242892d598f6605bc37bc2498cc83bd2c00a3faff3635da3c0d','51be5475f153c9a4b27bec14b419b4e7be895406bcf6a219531eba60583f9abb','077325625bc153709d0be8521956a5204c611e083f2d0d5a9794483f0d51e33e');
INSERT INTO blocks VALUES(310244,'46e98809a8af5158ede4dfaa5949f5be35578712d59a9f4f1de995a6342c58df',310244000,NULL,NULL,NULL,'cf25e806d81219a85aaf88720e1b3d4a8fc34f9a9d6232f1cbd85ea91b5266c9','c7978c01758e0b4060b4b88855e5531117ff087d7f006786dde4cea04e42dac8','a04743ae59331aeb2b12de81a09ac6fa4f44080cf1f9eeb1e4a1d895d9141bea');
INSERT INTO blocks VALUES(310245,'59f634832088aced78462dd164efd7081148062a63fd5b669af422f4fb55b7ae',310245000,NULL,NULL,NULL,'c8305530d270f86739b072d1055a05dbddd4cd00ab0816d71c3e5588d24a8b5a','6340a542a183a79b004ba2ccbc452c3298f69940eb84553c595fad090f1c979b','a99843641b625d0b7e829d5cc97ef1cebbdc89beea91a17893eb3a0a9b55fcd2');
INSERT INTO blocks VALUES(310246,'6f3d690448b1bd04aaf01cd2a8e7016d0618a61088f2b226b442360d02b2e4cd',310246000,NULL,NULL,NULL,'407b2831164bc76e0703b2a60f814089c11c0796a41c3add7bc03af27b9609c9','fefa891e4afad22ee19657f8e713af6a2a0d689f7e03b4c6b65918e2432f853f','733cc1f7b72e844347bf775bed8ffb235f8dccedd4b005aceaa058ba755835b8');
INSERT INTO blocks VALUES(310247,'fce808e867645071dc8c198bc9a3757536948b972292f743b1e14d2d8283ed66',310247000,NULL,NULL,NULL,'5808d42df00241b3488ea04d57ee7e016271182f964baab2423d565dc8f821f2','72759e1a225e7a90076e47d4253108ed903cf2a3d21d4b2d5b163b92ab8e4347','1fb2b48c3a5234e5c718e26684afc828d204607eb9c4090b1e31786db546aa38');
INSERT INTO blocks VALUES(310248,'26c05bbcfef8bcd00d0967e804903d340c337b9d9f3a3e3e5a9773363c3e9275',310248000,NULL,NULL,NULL,'2419344d0fdbb18de193606fcc3eea27cbf42ddd952a775ff9d0d780b7654753','8bf38dfdd6cfa299feb6712572ad6c096e6b7cc145055f9c6eccab32e63ff782','09e312a6a0c32b2fc83ebcf5b41737e5cfb3928c0260b597fad0c52e418ef212');
INSERT INTO blocks VALUES(310249,'93f5a32167b07030d75400af321ca5009a2cf9fce0e97ea763b92593b8133617',310249000,NULL,NULL,NULL,'cd4d93b693f6f1e1738eb5803aee8184788a956314dafed400d0fbe55620d5df','11e89ac0bf41c7dea0d52d9e165cb4a1a16f51ebe6c8aefca479bcaec7f99155','9d655ed37028edff0413330264a3148933c8a1f246976d400ee339686616a75f');
INSERT INTO blocks VALUES(310250,'4364d780ef6a5e11c1bf2e36374e848dbbd8d041cde763f9a2f3b85f5bb017a2',310250000,NULL,NULL,NULL,'5319a19281e9aa09e924b46f9c2a52bc763b558cb7f371364c9b116908372698','20893fd11ac6334eefce215e745c25334dbeccc84e8b629a01ee5e8c88298f1c','6da3d59e3742058167a550c7096e7f3cf12b3c1e23e373eded403e17b9b86ec3');
INSERT INTO blocks VALUES(310251,'63a3897d988330d59b8876ff13aa9eac968de3807f1800b343bd246571f0dca7',310251000,NULL,NULL,NULL,'64fe9beb6e1c561e04b90d9d0471f3ac2ddd081dd3868eb79f7473d2efe1387f','95a2919ac72df74b0460c237eb5f434833057b7da7936fbb63c1a423f124cf71','ff7c7f45871ba72aa07d06e8f28d0cdff4a93d29fee115f928fcfbc436e9e9f6');
INSERT INTO blocks VALUES(310252,'768d65dfb67d6b976279cbfcf5927bb082fad08037bc0c72127fab0ebab7bc43',310252000,NULL,NULL,NULL,'46ea5e52f793e0c0672de2c0fd2e2b41d00e5da4709b63baa9adcdca9f0745b4','63938f3b9a717190f0eb2ae8fc414054ee603f70f84cbb56c57e2ecdaccb789d','81a8f8150192002e75d15729fc322c716b04e5763d0cf57b900dbb162a1f0d8c');
INSERT INTO blocks VALUES(310253,'bc167428ff6b39acf39fa56f5ca83db24493d8dd2ada59b02b45f59a176dbe9e',310253000,NULL,NULL,NULL,'1797e6db408d515539a0d69cc19ca1da997e3688ed2be418e5836400e18af1c2','3579a2e1594055582c8f232547281777bff851261c7c7fc7527370d61ab7d109','3b584d4ed17c855bbdda5d609d38be9f8e2a90cc77b458a0dc05f5a402c1fa9f');
INSERT INTO blocks VALUES(310254,'ebda5a4932d24f6cf250ffbb9232913ae47af84d0f0317c12ae6506c05db26e0',310254000,NULL,NULL,NULL,'1c54c434ef59433b38426c8fba5ff03892fc3518fcb9e359f5dd1cdae8fbd194','7de294ce5400d867e0845f8b299b0160d80c3d8a9da4fd1595875e427e23e222','6f3e9a63fffe7b6a6502d0df1db231a15b1b2819bac668c76450108118585f2b');
INSERT INTO blocks VALUES(310255,'cf36803c1789a98e8524f7bcaff084101d4bc98593ef3c9b9ad1a75d2961f8f4',310255000,NULL,NULL,NULL,'2808133770115272675732bb831888d82065c8a730f42914062b08095418e3b4','c2b17ead5cd68476e3e5d969e1b07f891fd68d9d9e28339ff97f0e9452311abc','74dd2961d99de07bddabb2390947ae397278216b8116cebbc7d854f4f0ccd8cc');
INSERT INTO blocks VALUES(310256,'d0b4cf4e77cbbaee784767f3c75675ab1bf50e733db73fa337aa20edefdd5619',310256000,NULL,NULL,NULL,'f40222743997fb5c4821444a6258e1e92d265029abcfd8e319079e3df5da0637','23707bca071a426666719dce1b9fa7ecb94c7ab6458b6b2472d081d14ba573d6','0a41786f93dfe07fd4d31ea16ac7f4f275879d6f417198ebaf483885639d3c58');
INSERT INTO blocks VALUES(310257,'0f42e304acaa582130b496647aa41dcb6b76b5700f7c43dd74b8275c35565f34',310257000,NULL,NULL,NULL,'74a291b880874c8f500ee7e63840f18a8863c485167ef41127dae6439d64f5dd','580477235156702ebfe07be3a032be993b56f407f9e7d834c92f4006174f0a7b','e2fe3f70c9d1cca2aa9462f371dbecf01c88afce37e5305df8d65e8f1000c264');
INSERT INTO blocks VALUES(310258,'3a0156dd7512738a0a7adba8eeac1815fac224f49312f75b19a36afb744c579f',310258000,NULL,NULL,NULL,'91dfcf3baf1f0c05aadd889d1a2687140bdaaf578047ef749f38ece49be67709','5f35d9dddb89605cf13af1f9163cb932c7d5b6b9507237895b52835975420c3b','0b91583acf1b7ef2117f35d901f0a2f72684ad097f56c3e9b4b5b852edbde96a');
INSERT INTO blocks VALUES(310259,'e5ed3cdaaf637dd7aa2a7db134253afe716ffdf153e05672df3159b71f8538a9',310259000,NULL,NULL,NULL,'a7e6b3fc791782c845af4b7c5a29cb5f101a1f261e8212dd5d5863d0673fe127','99a03fdc27896b0797e461f74806b346f8e6b6e50190306a496a10454f4a22fa','a09efe6f71d2e63969ea71f3b6be1936429ada4e69c87fd74345b9c5daf0b51a');
INSERT INTO blocks VALUES(310260,'8717ddcc837032ad1dc0bb148ddc0f6a561ed0d483b81abb0c493c5c82ec33cd',310260000,NULL,NULL,NULL,'e9f8810dd65908cca25a48d6334df0d77a291b555083d7f59e88a1ec93e93d36','694b31315a201356f6deb42c919f7fec03be6dc4cd0846749fbbbcc8d56c3f60','f36e53c6965cd560d0a9bec4fee222f4a3be6923fe366707d064c999643bf505');
INSERT INTO blocks VALUES(310261,'a2a9d8c28ea41df606e81bf99cddb84b593bf5ed1e68743d38d63a7b49a50232',310261000,NULL,NULL,NULL,'d2b1996b809a707b18af884a98b9be050092bc7ed7c548edfc49df1de3bea6a4','ca9079002a2a41b58e56bf5612650c2a0a7131433f46804ffdc66665e5da8590','71cd969cd20145ed2f22f94e36be04e69074affc402ad2397749bf39558ce618');
INSERT INTO blocks VALUES(310262,'e8ebcee80fbf5afb735db18419a68d61a5ffdde1b3f189e51967155c559ee4ce',310262000,NULL,NULL,NULL,'1b0a40e7362936b513b9a8efa0d74caecffed98d9f97af28e6c681eb8b618c85','6aae7da4e08e28231021c8568d3f1fbb62e9da991d0def9660f318a398384c36','fb592f7c4ce9af2e597ebc188f365fc37dd7769f35593467f0a7ae0289c99e92');
INSERT INTO blocks VALUES(310263,'f5a2d8d77ac9aac8f0c9218eecbb814e4dd0032ec764f15c11407072e037b3c2',310263000,NULL,NULL,NULL,'4445d775feb66988988ff0df319dcf036f50025e17bd18c771b37daf28a3f40a','595f8ac9ff96130dbfc43cec1632879e3cc66b22773ab132e71e52e4b7e0ecd6','e8325f6d093eb9ac8a0c1531e6655da59ba6ee88886d363fefde1f217bd47486');
INSERT INTO blocks VALUES(310264,'ae968fb818cd631d3e3774d176c24ae6a035de4510b133f0a0dd135dc0ae7416',310264000,NULL,NULL,NULL,'2c8d5f9c2975584d4dacb8c73eca0cbbdc55f5c1cfab53c4ed04e516ddf65ddd','a0a50707f10937bdd7b39e0506a168ecc8795fab3b6222822e2973c285f27e4c','3e87abf0d28ccba63cf4364d6698b3955051862d49dd18d97001b9340383b30c');
INSERT INTO blocks VALUES(310265,'41b50a1dfd10119afd4f288c89aad1257b22471a7d2177facb328157ed6346a1',310265000,NULL,NULL,NULL,'0914b4d4ec66beb147d03691504a784ed9837f31e9e81d378e6213a07cbdbc2e','584daaa205587b8228c155c52a0215d1f372aeb9419499d4a82dc9ef26e403f7','f48368427599d4d0eb2c4c6a3da7e39d768d234027c1c24437cdbfc791d86905');
INSERT INTO blocks VALUES(310266,'1c7c8fa2dc51e8f3cecd776435e68c10d0da238032ebba29cbd4e18b6c299431',310266000,NULL,NULL,NULL,'53859e2c9a3471ac9a8eff9cae2d7d8f96ef85a8ff74087a5d5fa5d58d6c4813','e293f4c17a9d346324863f0d339869eaa5654829861bbd197ffd1b83a087d869','df5bdf1bed8e6adaddb61466ae75258be607ffd8a9af307f7e3460c5f8fa20e5');
INSERT INTO blocks VALUES(310267,'c0aa0f7d4b7bb6842bf9f86f1ff7f028831ee7e7e2d7e495cc85623e5ad39199',310267000,NULL,NULL,NULL,'22dff6aa2dfd6130e40a4deea4c41a0a7c99af00aec76a5576ed51782a7cb2e9','7bf0aab24cb8ee02880bee0d64f44c03af4b354f6f91d809ddc7cf6fa9f79844','5c46477b3ed2c2b7568328f341d12871460694ec832af3ca98d83cb8cc702138');
INSERT INTO blocks VALUES(310268,'b476840cc1ce090f6cf61d31a01807864e0a18dc117d60793d34df4f748189af',310268000,NULL,NULL,NULL,'ce3dfbbeb86df484b6769b327dde277e3ac9b5c277a743806a84e4edb89b255d','b4701e4ad2d23f34b30fcd3092425bae72417eb36ad80d2b2f095680f6fd5d23','1aefdca9a068e7683131420feb127ec157543b8319c1e1f19c1351356258639a');
INSERT INTO blocks VALUES(310269,'37460a2ed5ecbad3303fd73e0d9a0b7ba1ab91b552a022d5f300b4da1b14e21e',310269000,NULL,NULL,NULL,'b98d7bce7f9f6b47b84fc00fb6527c560589cbf8362195f32a2784b73f30ec35','062e5a95c673550cf29f306d9b1a3591d512831d798258523381f9b413ce9167','09a4190665d4cb3330ae86bd14c9ca69137a76d5aa9df9db6cb2fda07a6004e1');
INSERT INTO blocks VALUES(310270,'a534f448972c42450ad7b7a7b91a084cf1e9ad08863107ef5abc2b2b4997395d',310270000,NULL,NULL,NULL,'b3ce8b9a5afe3d7984ea85b9375511064d7e184a1b0c972ed9fb681daf24e6c5','b376c773a88ed58292ced75ce430151f0feb49a5d0448f163ed3924f26195807','1b02e740cccb5bc49382af5ba47e23ecd7d883eb405bb6c42ced5d06f9270613');
INSERT INTO blocks VALUES(310271,'67e6efb2226a2489d4c1d7fd5dd4c38531aca8e3d687062d2274aa5348363b0b',310271000,NULL,NULL,NULL,'a2ed29e5e0951f0575d3184f370211eb283a8a872392c629e9324e8035eb6b10','ffef8b5222babcf0ef6b536519e610d57bce3656f0c518f12e02120851e95520','edbf57a017a4e3c496f433faeabe0aeece4c1a36d2c0504959ee3c656eb56cd9');
INSERT INTO blocks VALUES(310272,'6015ede3e28e642cbcf60bc8d397d066316935adbce5d27673ea95e8c7b78eea',310272000,NULL,NULL,NULL,'5288189c50847ad09e39ca27247397854527497fc550bbf0c898c12f5ae159bc','24e427fb2a3b01df74046c0b7f2647aa22f893425dd2e4de1bfba087c4364170','2dfee8d487d434539a607e7a7fe21ce1880e385f64afb598f215c6d9df430c8f');
INSERT INTO blocks VALUES(310273,'625dad04c47f3f1d7f0794fe98d80122c7621284d0c3cf4a110a2e4f2153c96a',310273000,NULL,NULL,NULL,'326a772f7b1a59aa67892453799ec9934b7b7917d4ef8269e223d6d85341937f','a804e71fc85ff9fc7de7525b5eb8d313d7cfd4536f5b68f233a0decad34bb05c','e8510944ac406c983140714a502db588186f24fc5ffa403419742d73dfd94c27');
INSERT INTO blocks VALUES(310274,'925266253df52bed8dc44148f22bbd85648840f83baee19a9c1ab0a4ce8003b6',310274000,NULL,NULL,NULL,'b7f25c3d8a5012379d23c7d49663017075fa878cfca9ac5037cb7d9f633d730e','9886b2a662003f2e0bc4a8cae4589c236e384fe8ced52547ab69b69f341a57d5','95ae641b40b4709531a23396b53b065f82ea8adb55866e5575069d21d1bca174');
INSERT INTO blocks VALUES(310275,'85adc228e31fb99c910e291e36e3c6eafdfd7dcaebf5609a6e017269a6c705c9',310275000,NULL,NULL,NULL,'1666080f97d21b30446c3204b65395514635a10010a7f71783c3d3b2d4e509ea','b56335830741bfe8e82cdae86981ed595ee9365cf9eda8ad1315c867bc9a9fc2','4d630b4680d2da571d941700d4e96b25f7c1fb88ba8f5304ecfb1ae024a27c51');
INSERT INTO blocks VALUES(310276,'ba172f268e6d1a966075623814c8403796b4eab22ef9885345c7b59ab973cc77',310276000,NULL,NULL,NULL,'17bb86c1a5bb40e04e0940670d9292aed6a00180a25565863a7443ab9a09b765','45b055166211919960665eebc90f4a189d807fe245e8888e2b5ffd9c48c371b5','f3204f8daa24ddb1a6f72c8353b062fbed55e91d7ae5133d7550d8265266e112');
INSERT INTO blocks VALUES(310277,'c74bd3d505a05204eb020119b72a291a2684f5a849682632e4f24b73e9524f93',310277000,NULL,NULL,NULL,'703092fe9e558dd14107c4a143dcc9ca3f469d5b7c3a46d76fde941caa509f4f','dd3c28f31e74219d8d380ed7a50c2295d302808f0c068d1280041ca30a0fa7f4','0bde471a10023a02a8190e128a752391596608d29165a98694f57beb9e6c02b6');
INSERT INTO blocks VALUES(310278,'7945512bca68961325e5e1054df4d02ee87a0bc60ac4e1306be3d95479bada05',310278000,NULL,NULL,NULL,'d176b0490cc412bcfd94e75266293813f79f95c7404e16533ef7759b60cff3ff','1b2458e1a171f613a6b8081b8a489f2f30d71423161e5bc5c01b3b137ffab582','5aabc7d7113a1a0e74f18ea8c40440abc13d4bd09beee57da20bcf5b313dacf7');
INSERT INTO blocks VALUES(310279,'1a9417f9adc7551b82a8c9e1e79c0639476ed9329e0233e7f0d6499618d04b4f',310279000,NULL,NULL,NULL,'2580d7548c7ec6a950558982c43a68e3efdbac90629a68180781de3830269f0d','c3ac51c53c13f6910578f557e76c64e04cb109184b9e76c8a83e994b2de7e1c6','b7743bb250ab3330c2498eaa5fbb19bc9dba431b95345f89c6f4bcc259c98355');
INSERT INTO blocks VALUES(310280,'bf2195835108e32903e4b57c8dd7e25b4d15dd96b4b000d3dbb62f609f800142',310280000,NULL,NULL,NULL,'eb6de37cbd68c647d0708a1b3e2cbab25f3c662938ccff2928cb0ba76bbb5833','0bc2f5e7ac5f5230ec0424c234642ffe13d9e34a45a2ff1d28f5589ea98ce528','656a355df2de06ac362a684d150cf437cfb1a263602bfd3e0fc80dc3eba4f40e');
INSERT INTO blocks VALUES(310281,'4499b9f7e17fc1ecc7dc54c0c77e57f3dc2c9ea55593361acbea0e456be8830f',310281000,NULL,NULL,NULL,'6efb2c5a9125be05b50749ddb6221833d511fff46a5b6e5f243328d6e2159ab3','073879e9642f4f3612db8528097a0171f291e17b02dd8426a938dd204c75ec82','1cbb850603b104424b2f57035d26840ccd5b25fa55a50417ef7a2ca41e77d76d');
INSERT INTO blocks VALUES(310282,'51a29336aa32e5b121b40d4eba0beb0fd337c9f622dacb50372990e5f5134e6f',310282000,NULL,NULL,NULL,'043249ad9d32f6b68eefb16f44884394783d9302c6d82660b7f2cf47afcc9119','e93b4f26a9012d96c671906c0249b98c7a130880b0ac3c3c7a0a89c4fbf202de','ea8a0c570cedd7febb3fb60139d1fa5d823b0f483e42d563adfc2b26eba2e67c');
INSERT INTO blocks VALUES(310283,'df8565428e67e93a62147b440477386758da778364deb9fd0c81496e0321cf49',310283000,NULL,NULL,NULL,'39662bebc3ad8981e19e3132249cd1f2efcae8265e44a9b38020d8a330a27cf6','46695d1e2c6e61da484dec26a6c8d3acc7e8e0756cd637fd731983740cc9a545','3cc272d96d81fef1b26a56ea204c19fd6a9f1a99a2c33392b0ba12a518217d90');
INSERT INTO blocks VALUES(310284,'f9d05d83d3fa7bb3f3c79b8c554301d20f12fbb953f82616ac4aad6e6cc0abe7',310284000,NULL,NULL,NULL,'e97651e32f6295a9d830123a01a1e102bd860f764cb374badb3072546ee357f8','4fd549b08956641ef0baca5975831dfe5c49b9461fbfbbfbfe31f065bcbd03ee','492a4a254db9f5c729d903e9c1bca9c3a0736b3b5be314632bc5369a688158c3');
INSERT INTO blocks VALUES(310285,'8cef48dbc69cd0a07a5acd4f4190aa199ebce996c47e24ecc44f17de5e3c285a',310285000,NULL,NULL,NULL,'c005dc18ba700b41e9b34ae58418c2efbd22b371bde0248072e9d692f9fed384','b4f283ee0cf6bb75b570c54d34b3a5c289f1822921d2a6cf96c7fc763f103733','8ec214233c84719783b53414836cd27c38aa6dc7670851b817b424220024e177');
INSERT INTO blocks VALUES(310286,'d4e01fb028cc6f37497f2231ebf6c00125b12e5353e65bdbf5b2ce40691d47d0',310286000,NULL,NULL,NULL,'18cdb86005b9bb31b49f6de8c361c492032e095edb49027c3e9011a226a45bba','9d28275f6fb523c56d5732b7695229ec7d4c044d7ef0f1be0c19f267422c24b8','7330a5e594b85fb403d2ef7355ce21c4d93b34933f19d4709050632e3ba4cf27');
INSERT INTO blocks VALUES(310287,'a78514aa15a5096e4d4af3755e090390727cfa628168f1d35e8ac1d179fb51f4',310287000,NULL,NULL,NULL,'b3677e8f7784cf7a99f77e5bb0736c5314bea402e0ca569f560d72263733dd85','184a2416555ac2b70e9b2dd1043e0091fbf7f65d6a74180b22e5b90ba0a4443c','eea3f54e04896f911f13fe1d8b7498f7d4599da472dcbe30ec1d6e5930e07f5e');
INSERT INTO blocks VALUES(310288,'2a5c5b3406a944a9ae2615f97064de9af5da07b0258d58c1d6949e95501249e7',310288000,NULL,NULL,NULL,'20dcdb8f60f5422d87d2a9aaef2c7a2be0129d1cc2970abdf3de58a49b8d44eb','5162844fde85a3f19fd9f1f2408cfe7497ec36031052bced38ecafae078cf0de','df9e35fe85cfc823a4eda29b406be96c09a5fce62c757769a1da47731c769ec1');
INSERT INTO blocks VALUES(310289,'dda3dc28762969f5b068768d52ddf73f04674ffeddb1cc4f6a684961ecca8f75',310289000,NULL,NULL,NULL,'c820558d4a3cb65d96e95ba74006e2a3b063922be55cc5c78a9e5f34a8c445b6','b256f603d4cd01ada8365486bfe72d87e47f492fd434f7d1d5c83e2f6e6ad78c','04df70b93a084a1016e62e9edc40274cdbcbbee9fac0b67594f16d45c6fe471f');
INSERT INTO blocks VALUES(310290,'fe962fe98ce9f3ee1ed1e71dbffce93735d8004e7a9b95804fb456f18501a370',310290000,NULL,NULL,NULL,'db903504d83e44ac46c0561221df4c1bf0ed51d506f8066d6f01445aa36c67a5','d939d979ca89980da602ee69b37f27b3aca61860660c952a203fa8fe88a7fb69','bfdb3808d9802d61cba5b189e2cd845def3523e034cb985b6767f1e468b17bc2');
INSERT INTO blocks VALUES(310291,'1eeb72097fd0bce4c2377160926b25bf8166dfd6e99402570bf506e153e25aa2',310291000,NULL,NULL,NULL,'3e53f1beaf583837ebc76d56e4862ec9b2597dc82fbbbdedcfe9fb960c468de7','e8d677c8c3f89a148f11a6f36ed58c7636619ce041e22121c971474abbd5af97','dda7ff41fc251a0750ddffda29b6a1e368eb50d2036cda8a9e7de499c444ffef');
INSERT INTO blocks VALUES(310292,'9c87d12effe7e07dcaf3f71074c0a4f9f8a23c2ed49bf2634dc83e286ba3131d',310292000,NULL,NULL,NULL,'91e4eee91748acbeee8247e37bcecb6168e790f6b6032449a436109f705aed8f','1b1d67733aba9d4d31aaaccb6c7cee5e2d361ba02dae3887b83cc101a9362b85','2c7eda596848a8549c2589480cffb3389541ebca4cb32fbd81ffe05b48e05d79');
INSERT INTO blocks VALUES(310293,'bc18127444c7aebf0cdc5d9d30a3108b25dd3f29bf28d904176c986fa5433712',310293000,NULL,NULL,NULL,'35755f137dd851474d798e61b3fa4dc2d565ba0329fece8ad71ad78658fe120f','2f7f118d5d5dc094f77dabf1683b8eadc4ee926ab744b7e105eabb295d8b4197','251ec2c2ef30d1d92b0b11b16d0f2a11082ea18816d1db2091fd71c8de117e8d');
INSERT INTO blocks VALUES(310294,'4d6ee08b06c8a11b88877b941282dc679e83712880591213fb51c2bf1838cd4d',310294000,NULL,NULL,NULL,'535d5bde54417c4f0ed98bc998c7bb7abfabddaf0a193319c06cc974e7955001','e1876930be15c848649bc58008ae1501bc6916b4e7c4a4083f89597c99a87aa5','c61118aea6c34dd5d546bea5b5d02da10005356f8cc7a1c4796c0fba28629ad0');
INSERT INTO blocks VALUES(310295,'66b8b169b98858de4ceefcb4cbf3a89383e72180a86aeb2694d4f3467a654a53',310295000,NULL,NULL,NULL,'8ff21ed6845982f42b6c9f93f8cbeaaf1934a9f8d4b2c4f41fef08ccb1a89850','3d92b716f2f486b3e95ec27944afff00e81174fa1a606193c332f67f6f089e7d','7bb26bf6ff0b811d40718eb58d7ea84e454ec5c4699e15696d51116cbc75ac9d');
INSERT INTO blocks VALUES(310296,'75ceb8b7377c650147612384601cf512e27db7b70503d816b392b941531b5916',310296000,NULL,NULL,NULL,'9468a0b9bc705231b01f5c5e14e778375ec34e7fb8558ebc9d6d07788dd2b32f','3557ceac4555bf57e0731db4db670e1911fd028e54fcb2651c6293eb37f8e6b3','7d1360c848bef093c1c2a62500a29c43fb0654336aae875984c2db8f4c7b2bf2');
INSERT INTO blocks VALUES(310297,'d8ccb0c27b1ee885d882ab6314a294b2fb13068b877e35539a51caa46171b650',310297000,NULL,NULL,NULL,'d855c48650c2e46901dbaf2df3f00b323a566e06110c750d8c723db91e32b6f0','1106faffe667084f2670e3ef4f8dbbfcc262e6c6d02e879e65b8ebc967c97b19','c87c3458cec15631c2f5562f8c3780d560cc11d08cbf1763d306a41e51bfb974');
INSERT INTO blocks VALUES(310298,'8ca08f7c45e9de5dfc053183c3ee5fadfb1a85c9e5ca2570e2480ef05175547a',310298000,NULL,NULL,NULL,'ca4e2ea33dc2d897e2838ff0279aca492636b642c89b462068b57978ea48e27f','0c0638497699ae0c1c6134c9c3ba320ef404f1468156858bdec655218c7b1ff6','26a46034c5714b4abbce12a9773fa987ad4f867153515c1518f88915dba7b6f2');
INSERT INTO blocks VALUES(310299,'a1cdac6a49a5b71bf5802df800a97310bbf964d53e6464563e5490a0b6fef5e9',310299000,NULL,NULL,NULL,'a3d4f631f2c769816b65ec9db6fd78f3397bf49c707a3b0d8cf2a5b77a684a03','9664da6d954b9b059a7d772c427bfef1b912e41398151f920a712c2c3837a122','96e4bb307f9aeee26971c9dc1cd9753540034a201ee5534edcd1a9cd5b3fa48a');
INSERT INTO blocks VALUES(310300,'395b0b4d289c02416af743d28fb7516486dea87844309ebef2663dc21b76dcb2',310300000,NULL,NULL,NULL,'c0090723301266d95eccd90acf77920b244b138addb027e2ae6fd315f8d1bb31','526729f188c66675821a9d699f8e1a4d4d22edd3558e098dcef543ef33714550','739f66ac0515146a8b8add578b6c2425ad3df9fb9135cfc1e61babe9f31f2d7f');
INSERT INTO blocks VALUES(310301,'52f13163068f40428b55ccb8496653d0e63e3217ce1dbea8deda8407b7810e8a',310301000,NULL,NULL,NULL,'376a13034edbbffc439002dc3a90496d4a6710160ed350a69f4c55baf32b18c3','e62c6287c6a9e6b93017c535027d4de1efcc0cf10b2dac8ae5f0ac6f2d8afd31','1a8f2bdb3414bd3ae04938fef37f8dbd57a60b020a7773d7c27310faa21d4485');
INSERT INTO blocks VALUES(310302,'ca03ebc1453dbb1b52c8cc1bc6b343d76ef4c1eaac321a0837c6028384b8d5aa',310302000,NULL,NULL,NULL,'c4ebfd5ec7be8bc51ac85da284ca6c8781ce503eef39eaaa564ddee8c3affb42','3424a635ec34639c53e8680a8fcde3c8dbad61668579a9bef14e6261feca5fd5','d2ab069dd2d76b1ae50da5ec9144ff60afc85979b53130c42ab8f08ea9579748');
INSERT INTO blocks VALUES(310303,'d4e6600c553f0f1e3c3af36dd9573352a25033920d7b1e9912e7daae3058dcca',310303000,NULL,NULL,NULL,'88762e51ec2eb29cb13bea580a43e83ec7420880692b203a5681d35a1901ca31','0c74ffb4da42e7f36a1de88fccd723ee4adea2476c379e25e1c81e8ce5b66175','5b5af13cdc49f5ef86d1aac50991555a1ec860a8b0c9ea6fbf8abda09fa4b5ff');
INSERT INTO blocks VALUES(310304,'b698b0c6cb64ca397b3616ce0c4297ca94b20a5332dcc2e2b85d43f5b69a4f1c',310304000,NULL,NULL,NULL,'f37b00dc668dd5f2d6bfb8a43ba7be5c44eb56a5fce2350db8a08f279bb66624','dbb72e9fe3812f93e6f869641920da89ff7b12cd82551df638793aaa9379dada','101ae8c84d1cbe128bd84388d1c93d177f7512b48e3d95eccecb5bf35c92c8d1');
INSERT INTO blocks VALUES(310305,'cfba0521675f1e08aef4ecdbc2848fe031e47f8b41014bcd4b5934c1aa483c5b',310305000,NULL,NULL,NULL,'a36130c09c6139ce5b7d0c82a6ada0749ede6d9d71ca0d9e2b774bd669643f7d','67190c230d09691c7c9cf7d3cbfc75621ffb5643476773034dcaf08b089e6dc9','b41112a6f0d207afb72c5cf76177ed81c39a34c7a3ab463cdbdcc63e377ccd01');
INSERT INTO blocks VALUES(310306,'a88a07c577a6f2f137f686036411a866cae27ff8af4e1dfb8290606780ec722a',310306000,NULL,NULL,NULL,'110fa18f3fd486d666f45771ffc105d7b0c3f18e4fb07ed4fe3e7575d9ed8443','d0c63da50a0dba541f9fe33b04ada7fba0034a2801758b53ee3495e6d7ea1739','ba819ceda2f9182719bd37cec1b0900a86bc190223f0b6f78cc6fdf8c3fb02eb');
INSERT INTO blocks VALUES(310307,'bc5ccf771903eb94e336daf54b134459e1f9dd4465dec9eaa66a8ee0e76d426c',310307000,NULL,NULL,NULL,'b33c611404fe967862e1e0d691ad43cbc096f5006d406b4a23b9c11ac2d7542c','89c4a9c2f42915f6f4051378f9a9da5327b23df5b62f0e2f3afb6c59c4d302be','52df1bcf55ae2ffc2591a00cd908ae4656f2b44d6653b2456426a3415b944ae3');
INSERT INTO blocks VALUES(310308,'2291ffd9650760ff861660a70403252d078c677bb037a38e9d4a506b10ee2a30',310308000,NULL,NULL,NULL,'ba8ea1ae3189e93e6773a0fe13c9d29b0902fcb9c482de67248f517ca87a3dac','da133060aa8aee73422ebc882f2fd9d3685cbbf3206095feae1cedf00ae9cdd8','e48cd2561cbabbd18606e18cc9ab1a17db8a75295785dbe9489672980811bcb4');
INSERT INTO blocks VALUES(310309,'ca3ca8819aa3e5fc4238d80e5f06f74ca0c0980adbbf5e2be0076243e7731737',310309000,NULL,NULL,NULL,'88f3c3cadb65d7eb1291ccbe36c4b7b4b18eec7e6aa6f93d8c9258ba4e1d560b','feeea0cf85df7606e8dae1914806e32ac6f93adb27aa269a11f59e1b677cc8c3','4edba33820d9aa95e372da064bc30980a8321b4ccf3925f4be6d42e6935cd715');
INSERT INTO blocks VALUES(310310,'07cd7252e3e172168e33a1265b396c3708ae43b761d02448add81e476b1bcb2c',310310000,NULL,NULL,NULL,'8665a267059f149bb4298565fdc4b7defbcab94ec77c1ccaa084a0ff6f2321cc','3ae4b3bcc58bf2971af1bdb60e35f633fff8c50f88b885761cb4190697b195ea','34e0532829e49f902b0f04451363dd41850e5b9f08b2ad4512f7870181384d6d');
INSERT INTO blocks VALUES(310311,'2842937eabfdd890e3f233d11c030bed6144b884d3a9029cd2252126221caf36',310311000,NULL,NULL,NULL,'8d772254a0f43a24b9219e95b8fbce3a801754464e6901ca557f2b72653a471e','1b262f2d86a40c706e37d3c7d786887ec7989a343138ca1954ddfe68c4db5841','36cd3a52ddfd05852cbbd311de293f2a88d4b1c5f5e1978e573a9005df08d77c');
INSERT INTO blocks VALUES(310312,'8168511cdfdc0018672bf22f3c6808af709430dd0757609abe10fcd0c3aabfd7',310312000,NULL,NULL,NULL,'9a6252c72e6a6630846dedcc7b2b51d9a6f638fb0241c6cb9c34f48627e4d726','664fe0d09d6df172d5486f36f5e4a75a680849d01db0ca14fa2e6e7f93dc8795','c9c75577cdf0c30490108a029572c9f692d6186fc0b34c16b650d90211e3a930');
INSERT INTO blocks VALUES(310313,'7c1b734c019c4f3e27e8d5cbee28e64aa6c66bb041d2a450e03537e3fac8e7e5',310313000,NULL,NULL,NULL,'440eca6c58025f81d4cca5ef926b7ca5f354d8c08e1b4bbc1725f47814128d6e','5623488b49c4bbc1a43a25a775e6611f8c75acd3ddb33d08d72285ead451c969','8d429db83085859ef82c4b874aec19ebdfd799fefebfe7666e7da35e31b9a86c');
INSERT INTO blocks VALUES(310314,'1ce78314eee22e87ccae74ff129b1803115a953426a5b807f2c55fb10fb63dc8',310314000,NULL,NULL,NULL,'d24e8e1205736f823a5f29d13c024c1b1eb5cab66fda71967d99c2708ea0141a','264a6463aa1e1e8f855a37c86c0de9275079eea3c6616f98df0e8e0ac20a99f0','3b944d7adbb0d69f3727a9e8a1c96759ccd22f239ecd89750c8d493845cddd33');
INSERT INTO blocks VALUES(310315,'bd356b1bce263f7933fb4b64cf8298d2f085ca1480975d6346a8f5dab0db72cb',310315000,NULL,NULL,NULL,'7c07db23dc986ccaf97db5b053ad189a3862254cb73dec501b1b03b838d7ac77','3ad8025175e200f552653026cf032ba1805d65b39ab9de794c21f3024aa7f149','87bacb614554a5eb789c236e4c16d40544ad49a0092c14e036b0b033252ffe5e');
INSERT INTO blocks VALUES(310316,'ea9e5e747996c8d8741877afdcf296413126e2b45c693f3abdb602a5dae3fa44',310316000,NULL,NULL,NULL,'e183e0c60c42f1f520022ded234a9f50e2cb57df9726581bf596c96dab91f795','5b78b883bf6c1cb7a62a11c9c3d268373a6bc74ba8c11d383c0e280e92d629c5','677ec81deef27366e9e77f969db620155637891bea8d8abdb56753a72442a2eb');
INSERT INTO blocks VALUES(310317,'aa8a533edd243f1484917951e45f0b7681446747cebcc54d43c78eda68134d63',310317000,NULL,NULL,NULL,'6a33c2be830e3ac06df692af2efa568a0d49a5a7882a22c8cf0b045b67e1ee74','19f8403ede14503654ab429f9d8e9d77ae26afab22d0fc39c57388e4f98d5531','aa4d1c0566776ad83cffb800e54b0a0b969a23dc442af5043459893ff025b483');
INSERT INTO blocks VALUES(310318,'c1be6c211fbad07a10b96ac7e6850a90c43ba2a38e05d53225d913cc2cf60b03',310318000,NULL,NULL,NULL,'877f781c82ccd73d4237e160093e3abfe2c833276f1d57e0259f01dfb2be7039','904a2455603b30f378863383717f2669a9141ff7d273696bf121810aef1b5086','8b0563302dc0598e715c6f44dc3cae2f82bb26921d67537b945947680dae3c81');
INSERT INTO blocks VALUES(310319,'f7fc6204a576c37295d0c65aac3d8202db94b6a4fa879fff63510d470dcefa71',310319000,NULL,NULL,NULL,'298013ab024f9e5d0af4129822aa8832389ef22835a73180f32672b4580bafb5','6eb94143dc43a772d03a1346e0e472ed1fde11183fcfcc4e392c9650b2e2c168','5f967b0a9e33f5b307efe98cd2440aff2b491419fa86ccbc14dd0b885dfeb5ec');
INSERT INTO blocks VALUES(310320,'fd34ebe6ba298ba423d860a62c566c05372521438150e8341c430116824e7e0b',310320000,NULL,NULL,NULL,'55707216af7f0980fc936796cdf087023dc474bc9f7023cfb9560e1f048dd25c','f51b792c0ecbb8b98d44d173a7c2e0a12104a8448cfc2b4377f8e313dc82fb92','d20fe97db7c57a67615dc496991eee7b2fd6f30b089e0a2e7a0f2451b90d8af1');
INSERT INTO blocks VALUES(310321,'f74be89e9ceb0779f3c7f97c34fb97cd7c51942244cbc2018d17a3f423dd3ae5',310321000,NULL,NULL,NULL,'0d9bcb9af2c1926394015084b9a1a0459bfd23c47ab288c4ceac1f027e25934a','b27baa49c03eda485db4e2c77e091d3c30c93a1b9c9b220ff4bfeff516ac4bb9','5822ac1b96ae59a8fc5c5976fd85f4ae9e147fa12b8f82aeb20fa4c0d1d3ed5a');
INSERT INTO blocks VALUES(310322,'ce0b1afb355e6fd897e74b556a9441f202e3f2b524d1d88bc54e18f860b57668',310322000,NULL,NULL,NULL,'0aefbe8fcbbc360492f28403649f55727ad5c81e352ee7f6dfbe53d86c03fb7d','4cdae0e81c07d04c1e597c70b6d5c8438c66dda76b3e6875ccea922f8d89ebdd','0e5425084f94afafd43946da7e29e5d10204edbabee933998bf34bdf4aed5470');
INSERT INTO blocks VALUES(310323,'df82040c0cbd905e7991a88786090b93606168a7248c8b099d6b9c166c7e80fd',310323000,NULL,NULL,NULL,'10f6493b7db81dc79d7c4a144d4271fd34fa56f3f0fa344539820cb34e715a10','862e4b7eb3991ebc87c0e568daea910eab71b9c8131932df7de9c9208f7ab4a5','d1b5f6b215b6fa34624bc4604315fd0678e12498ecb402f6a05687d7d48104bb');
INSERT INTO blocks VALUES(310324,'367d0ac107cbc7f93857d79e6fa96d47b1c98f88b3fdda97c51f9163e2366826',310324000,NULL,NULL,NULL,'9a8db9e76aa41f40faa4347723b17a270ae0d1f84aec14e866d51ea5d984e086','5f320baf8aef01aac4d9d04683bc5b4e94188fe1f2b729fa7d65b8e85f9343c6','39c3dc03c94d68e6d6454f786f0019624e44a674c579e246001b75163ef942ca');
INSERT INTO blocks VALUES(310325,'60d50997f57a876b2f9291e1ae19c776df95b2e46c14fe6574fb0e4ce8021eac',310325000,NULL,NULL,NULL,'faa2771c6ea9bf5074b0c744a0661a813579341b0e48444b82e540cefd1a8eeb','d24a78fe887b6466e3e0c644087b9a8b41113746d942c213cba3bcf0ef11ee92','4210e0cdddf1d259aea5507eddc66d36fce7e6409d7f6f08cd606963b1135bdd');
INSERT INTO blocks VALUES(310326,'d6f210a1617e1a8eb819fc0e9ef06bd135e15ae65af407e7413f0901f5996573',310326000,NULL,NULL,NULL,'b3eb081c0ca021940c4c061240c36b85550711298ca5844193d8ebc73e0749bf','4a1147c7e058d297759d5345b37d2073473a62dcbb80e60fa4c80f869794894e','72518641ff6d6d9f97e54d1d413097b9a542bcf47643893f12b86d2b4f89f8ee');
INSERT INTO blocks VALUES(310327,'9fa4076881b482d234c2085a93526b057ead3c73a6e73c1ed1cdee1a59af8adc',310327000,NULL,NULL,NULL,'ded3fdec1c72b23cb11748daf3e6af0b9ecc373dd9770c424cc9078b8a450943','559efa8fcaeb8e7e0caf2b5c74c278d4ec6129d4e42fcff633ce39f0f8bd9379','aaa59266e28769ea34d5842b790935086188beaeef22c77cf73de7088af3510f');
INSERT INTO blocks VALUES(310328,'c7ffd388714d8d0fc77e92d05145e6845c72e6bfd32aeb61845515eca2fa2daf',310328000,NULL,NULL,NULL,'72e05b11ddc3e1fc1bc4877c50c42a04033cc3838ea75b0f32bde654e9fdb906','56e492e0d4b442aeb453956c078132c927419c76f95f377d43089b5ff7436634','f74298b6cc2da7a91466b66709ef14112aa446856ab1a218c5e4076ce0a86c55');
INSERT INTO blocks VALUES(310329,'67fb2e77f8d77924c877a58c1af13e1e16b9df425340ed30e9816a9553fd5a30',310329000,NULL,NULL,NULL,'08d8c594c5dddbb2ef7b74bd0c9d8bc1ec02f4eaf9a3f59dc75e4cebf35a6ee6','837c840b4cda3c976fdb317d4fe6f40fafae1db0c10dbaf4fc53b1e7c123bdb3','05f879be65642d5cc60f1299ea13323266c2d91d92b1012ccc10d20cd9d51843');
INSERT INTO blocks VALUES(310330,'b62c222ad5a41084eb4d779e36f635c922ff8fe275df41a9259f9a54b9adcc0c',310330000,NULL,NULL,NULL,'9b6ee31cbc341922d9b33ad0036f3d477f9360bcb5f7eb76e4566e68decf69e7','34e85f971f543e519d049d4140cef2dc2d1476bf1908e218f47c3c848d4d6e0d','ee54c1e12cf5f94a3ebb6850dda73ca8da4ad96f04186e63a332daa767514d72');
INSERT INTO blocks VALUES(310331,'52fb4d803a141f02b12a603244801e2e555a2dffb13a76c93f9ce13f9cf9b21e',310331000,NULL,NULL,NULL,'ddee3a21b8f5352bfd4775d0ceb7f768ed6da57d3a2cb0ae62d167f5251e67bb','62dd1a4a00899e87089b35c3f92c89d812073d3c0a621b53568851e0aed75363','f734c6e96af68ca55d2ce99db4738b1548bf1079071f1a2123aefb431313f7db');
INSERT INTO blocks VALUES(310332,'201086b0aab856c8b9c7b57d40762e907746fea722dbed8efb518f4bfd0dfdf2',310332000,NULL,NULL,NULL,'3322f6fb1f630381a5d7e117c5c41ae3e9a10444491237786144c5df6e2ceef3','591cef1896519111bf7c7b5ddad1e55eb9ad107227631ce56e805da5cafdfe4f','753c93ca4d94e1bae3fa534ce7a495fd8742c54aa7449b4cb1357274f4549368');
INSERT INTO blocks VALUES(310333,'b7476114e72d4a38d0bebb0b388444619c6f1b62f97b598fed2e1ec7cd08ee82',310333000,NULL,NULL,NULL,'4001093a7eda1203aee28b13848219bd2f3a10b2c426350e60822a269b5204a2','2bf189dc7a66b8da7c8d2afdad5d820380936690ad2da9ad75b3a6fa3ad7b509','1921bd3c283301f17cd9718d56fa9ed981952dbab8b45d3bcd407bb572ecae6a');
INSERT INTO blocks VALUES(310334,'a39eb839c62b127287ea01dd087b2fc3ad59107ef012decae298e40c1dec52cd',310334000,NULL,NULL,NULL,'a6e1ed9d51dd39b883be6cbb5da567d68edcfe3b9c75bd85193f72ddb1bde0ae','247bcd2ba2690e5518be955715aebd8bb03e5b11a8613ae7010a4043bbba3072','592ee9d6e7d3b898d03d6053a90ea255c7dfd3a73ef21833f4e671f26838d9f0');
INSERT INTO blocks VALUES(310335,'23bd6092da66032357b13b95206e6527a8d22e6637a097d696d7a96c8858cc89',310335000,NULL,NULL,NULL,'7edeb01196e6c638854563aded7516a1766e379dd2de4b61152a90aebed66dd1','9ef7bc5860828dd14b8fc7405e129292be71d78140878e93e85e57046e2af094','3c7cf5636ba005ba0bf16433856906f08d9cd674f0999727f942fbe0598b21f2');
INSERT INTO blocks VALUES(310336,'ec4b8d0968dbae28789be96ffa5a7e27c3846064683acd7c3eb86f1f0cc58199',310336000,NULL,NULL,NULL,'43cf591cd1fb8d45fa1d23734db5b171d9e44cab3a84e0a6819016ff6c193a34','90e659de061407c7302b0bc9020a9a66703620486b79cbc80f6599fa026abd5b','9712aa6a4126069ca79adb6982c8b53ff687dc1f33d8abbeb42fc362de989f82');
INSERT INTO blocks VALUES(310337,'055247d24ba9860eb2eadf9ec7ea966b86794a0e3727e6ffbcba0af38f2bc34a',310337000,NULL,NULL,NULL,'749f63c66007f6a6123f3d1d19b996806dbcc4e91508966ed646fbd233197f61','dc2d129414a6ed36fca5df66f20df9561015bde9f8bf7517a9e49601c827e6cf','c777d246bfc62a25f03f92e69d671f1ed6cb0b9396212236c57f644e447fa60b');
INSERT INTO blocks VALUES(310338,'97944272a7e86b716c6587d0da0d2094b6f7e29714daa00fec8677205a049bcd',310338000,NULL,NULL,NULL,'324d4c347a2efe522bd46ac767b1dd01c9f083b280b96b48613b48e9585b191e','59825906bfd16e71d5cd7a51333d721db91220f5939ba99d92f1d4beccd52866','c642f061797aa47fdd61b20f1de91616f746dfc419d5b23dcd6f2dfcf86203f6');
INSERT INTO blocks VALUES(310339,'99d59ea38842e00c8ba156276582ff67c5fc8c3d3c6929246623d8f51239a052',310339000,NULL,NULL,NULL,'34838c6b0c318859c371c6d9afaa201e705f0ee7ffee8e329ab661366311ee7a','4ceec5ca6fdd4b9dca9f632c3f82a97e370243ea3874d0d35813e480063724c4','8f9aaf8679351905a6d62340d0385fa76ef17f2bd710f1af94bcfda6cfd9a1a3');
INSERT INTO blocks VALUES(310340,'f7a193f14949aaae1167aebf7a6814c44712d2b19f6bf802e72be5f97dd7f5a0',310340000,NULL,NULL,NULL,'76ceb5c6fd2b4501ce477ad52a4a49ec355dde237efd1288169a906b393c21fb','9fa96c7e456650402353f416c3bce35e7bda6e618f1e3f3a3d69672af4d3745e','f4e6fcba5fe9aad557732a99c6a039306449070e30780bf67cd5ad2044c613a1');
INSERT INTO blocks VALUES(310341,'6c468431e0169b7df175afd661bc21a66f6b4353160f7a6c9df513a6b1788a7f',310341000,NULL,NULL,NULL,'0dca195d9452ecfe99ba4b004593169f5e9d7ff642f763d8c7c29c66b1530d25','0d84e51d53b9b44b658dfd96220ae2e811e467bab5d75c829594aa7e49bbb3bd','90c9f3d7f9cc89f50d76fff2d6ac09d0ae313ad7fc7a03de335d64f7658eda8a');
INSERT INTO blocks VALUES(310342,'48669c2cb8e6bf2ca7f8e4846816d35396cbc88c349a8d1318ded0598a30edf7',310342000,NULL,NULL,NULL,'b1c4b3d952312722b800004b164be3887bb6aeaaa5b1f1806010163822f5dcda','5f64fa837dade09d847c929d96808de2d89e6b78c36fdedc227fabe0610b5430','e76c2e29771c73263f961a4e86b42a56377a1be5aae752259475e8242f18145e');
INSERT INTO blocks VALUES(310343,'41a1030c13ae11f5565e0045c73d15edc583a1ff6f3a8f5eac94ffcfaf759e11',310343000,NULL,NULL,NULL,'588ce285ad77be2d19b952e680cb80a5057a171486a19cc3dd95e9d04c9791da','d1aea00b85487ce94cc249483d2d59127bc3ff2f80be18dca3e8fedb90500793','50a89fc4c2b325f872b21879d7231815e32a316a60b69beea92bb8ca7783abaf');
INSERT INTO blocks VALUES(310344,'97b74842207c7cd27160b23d74d7deb603882e4e5e61e2899c96a39b079b3977',310344000,NULL,NULL,NULL,'2f041a1ffa32fc71059363a6cb05ce114494b70f647104cc607c5179eee73a71','026174c0156bf36722a69303cffbd17f9347505eeffb2a00542a732eddfa6bb2','3f8a494d7b462ac7fe80910ab5f2febd070430ae654b6400225f93c31772fecf');
INSERT INTO blocks VALUES(310345,'0bda7b13d1bc2ba4c3c72e0f27157067677595264d6430038f0b227118de8c65',310345000,NULL,NULL,NULL,'8720a996d018b40ddc5fe864a5d63a48dad2898af31fa78b7245383fd1bb8e7c','492bdba0a163e64231a914a3a6d18048a7b5026ef6993d91104d862355ebb94c','26dd7c5711f678b0f7726a7fab74c5679d29ae82f3778c846a6ada0f6eb6ceb4');
INSERT INTO blocks VALUES(310346,'0635503844de474dd694ecbcfb93e578268f77a80230a29986dfa7eeade15b16',310346000,NULL,NULL,NULL,'fec1526f1dbfa0a922c8033e17e846603a850bf7aad3ff1240b7a70369182ca2','bf308fcf44151151054acbea6a8a79e860eb3bc5edc0ada7e4f0a5f0111eae35','1e8903c2ffece0422807ddba783078978ccb6e2c40bc71b11034bd957d00a685');
INSERT INTO blocks VALUES(310347,'f3f6b7e7a27c8da4318f9f2f694f37aaa9255bbdad260cb46f319a4755a1a84d',310347000,NULL,NULL,NULL,'3804fa3247d7d7120a2665fe67e4fc112c7c8facb350ed3045b0ca559574dc7e','2c6111d464c9304d2d6c6beda44763e158fbdc275fafca27d131fa8144be90cd','34f52fda720755fbd6438b329716209701957ed04227a43e24c9855708118483');
INSERT INTO blocks VALUES(310348,'c912af0d57982701bcda4293ad1ff3456299fd9e4a1da939d8d94bcb86634412',310348000,NULL,NULL,NULL,'93d5afb5e720e51e03fd41d8d59b9b3ed39cfc26b5a1d1f72f9d0cac04d032f8','a3c0dc21f68efe78757e4224bc8deede78206ed8bc6f4d125eea314cd1ab6449','5792c2087f1e475cd693bfefb19a5f2faef5fb083a49415524aa8b2b0190528e');
INSERT INTO blocks VALUES(310349,'ca911c788add2e16726f4e194137f595823092482e48ff8dd3bdbe56c203523c',310349000,NULL,NULL,NULL,'bccec5d21da7fea5e86783bd1d5f1e0b4179e5c516c9627cc42ed2c947364686','34c112b6d1373fe33f2dc957b1444dd2872515728952938f8dbbec4e924c11f7','3b0ea1b889ca4164b985b22c575c3b4588134b80bbc04f4ce7ce4ce1020ad43f');
INSERT INTO blocks VALUES(310350,'c20d54368c4e558c44e2fbaa0765d3aecc8c9f01d456e3ff219508b5d06bd69d',310350000,NULL,NULL,NULL,'ddecf0a91cd8840592ff96991eae197a321434c08db42fc494f73acb54eb9fc4','719be7abde1df10e0a354f43bf584de687b50b87baeb4dcb3e38ab9ba917ed02','175780e3972193ab730a51e605e70fed0149ec50627241be92624fa1b5a31099');
INSERT INTO blocks VALUES(310351,'656bd69a59329dbea94b8b22cfdaaec8de9ab50204868f006494d78e7f88e26f',310351000,NULL,NULL,NULL,'0019d2635f1aef82664167af1e42f4369c32e4849ec5aa05240a1b7356f0057c','6896d8fb34dbd503043965bb41cd5f86fd561877bbf095fc5b2fd2913686445f','69db52973bbf5d50966d2e6a473cb4da65558982a3b8c32cd41074f550d900fc');
INSERT INTO blocks VALUES(310352,'fb97d2f766a23acb9644fef833e0257fdb74546e50d9e2303cf88d2e82b71a50',310352000,NULL,NULL,NULL,'cee47b9373e9ec971475e619d9d501682ae66d413e1a7be2abed422cd64334cf','955ecc4099fd9f8c6e04316081a59579712934135c19ce23ab74735205af5abe','e43eeb4f1eb08234164025a9a3b75d920d2dccb65915422fa55aca465ea57d61');
INSERT INTO blocks VALUES(310353,'2d3e451f189fc2f29704b1b09820278dd1eeb347fef11352d7a680c9aecc13b8',310353000,NULL,NULL,NULL,'11d2a53f0681e2639ac5bd838faecfb6128ba695362e406fbabdb82bfcaa7c8e','2464ae8c39ced1643759b8484bf09d1e7a93104db0a8cfca30ff06bac4f9cb38','5e54f828819f675a09c08d38d9d6fa32422aba52fa46d2537163963b0f379250');
INSERT INTO blocks VALUES(310354,'437d9635e1702247e0d9330347cc6e339e3678be89a760ba9bf79dd2cd8803e0',310354000,NULL,NULL,NULL,'281dd8cf9ad38b1ba0c282dac1badab4a82d7a9a01f77c4760cd7bbbd4051dfb','986c26517c357b6596924f46918cb57420d217860c3eee1a800769e25fe6a2b2','887a1a5728cdcf1aa912da4d22170a953bd7f800d22d29e63f9fbcbfee52980d');
INSERT INTO blocks VALUES(310355,'ea80897a4f9167bfc775e4e43840d9ea6f839f3571c7ab4433f1e082f4bbe37d',310355000,NULL,NULL,NULL,'db15f8e6c227d8c0e8d3f878d60321218395c7119e54151fbef1152d968a072c','3c596b9203bdb61d60617f772eccccf14c2126039651ce93ef5e2ab1d124ca9d','536003b3f72caee7f483c2acc0b10196abc1fa1dc4426275339ee855240b4e06');
INSERT INTO blocks VALUES(310356,'68088305f7eba74c1d50458e5e5ca5a849f0b4a4e9935709d8ee56877b1b55c4',310356000,NULL,NULL,NULL,'1e373e04c64571460e44cb1165fdfd51b6350c5df7a1317b2a7948447d5cc708','1797ab3ba5e45f5257ec979277e396762fd756089c965950995c674a4140c41a','69c68848d75aa7ca9648fb5d014683b2bc9c18e7542dbe39b67ca097a49ed058');
INSERT INTO blocks VALUES(310357,'4572f7f4ad467ef78212e9e08fa2ce3f01f2acc28c0b8ca9d1479380726bab1f',310357000,NULL,NULL,NULL,'58cd6ef79035c7569c8764b81c9fedaa5620b0513e43a419e86fe705ec71fb68','7a82ddc77c5fb35d387b2f8c61513c2c337018de33f3903abb867238d8f722d9','169a1067a87531cd73e8f88c380ca84a4c60e2450f4918e85ce642ba49510c56');
INSERT INTO blocks VALUES(310358,'d5eae5513f1264d00d8c83fe9271e984774526d89b03ecd78d62d4d95ec1dea6',310358000,NULL,NULL,NULL,'eaa444585bb2126e654637774110f9ca4f35bee1163769158ef2985058cefaf2','b9ed148e747a36d1aea756deeaf4c279ba57e4a7f04d0500f59b73072b05d587','8d37e177e75d346fa07b355210fa64994eac0f2564ecbb4be0e89360068bd332');
INSERT INTO blocks VALUES(310359,'4fa301160e7e0be18a33065475b1511e859475f390133857a803de0692a9b74f',310359000,NULL,NULL,NULL,'77615fc1864a7c00a0e57b5e56168ebdd2fe976edc8bb671cee03d83b63a90e8','0859714ddb17bb283214917d542972a244610048da0a455f4386d4b3031302ce','ab1d11dd12a6ddbb114ed375f2f3f77a0e0d434a60f4cfb8cdb90175cd85eaf5');
INSERT INTO blocks VALUES(310360,'cc852c3c20dbb58466f9a3c9f6df59ef1c3584f849272e100823a95b7a3c79f0',310360000,NULL,NULL,NULL,'669a2f294a4476dbf36ddb4b1ffa70e6122f7caac55eff817f237503a2acd92b','5a1d95dae24d778c3e3e65abc7feb12aae0c784fcbdd433b213ecef28aefad2e','f05447b8aefafee0b52b6d7daf8f95b9d67d647f0124012bc9eb6b816e9edce8');
INSERT INTO blocks VALUES(310361,'636110c0af5c76ada1a19fa5cd012e3ee796723f8a7b3a5457d8cb81d6c57019',310361000,NULL,NULL,NULL,'9b23a898da3045a8fdf77a3cbf135aad5708b7e3657314213ce8582e320700df','5f044ac1fd6bba9106dd9caf9d0bab2cf9f78f01b564cf1cfbb7731e711640f3','bceab3000d1952e4210b4e0c01893f0ee6780a1b57bd73176e5a3803e4b4a4d3');
INSERT INTO blocks VALUES(310362,'6199591a598e9b2159adb828ab26d48c37c26b784f8467a6bb55d51d7b6390f2',310362000,NULL,NULL,NULL,'cb238b47765a3473797dae6708e7cab32ba2a980a8570fb5ff515d48507b0d97','79e1a515bca5fdff5934949e31354d939b91b1effcd0652eba1888c608ac9c88','5b51e22aa5d99dacabd23f045d323b9d124f457119c7ed681ccd8aaa6aceefc7');
INSERT INTO blocks VALUES(310363,'a31967b730f72da6ad20f563df18c081c13e3537ba7ea5ab5d01db40e02647e6',310363000,NULL,NULL,NULL,'6f83e7b9ea958f4e3d7ccbf9b3af0da1a848f0e8886133bd957f310cada0a861','d1402f1e725aa514ce30a1d82d7c036b9d666bf2f8067a137cf99cb66cb99946','73d4a1f42d9da23b56c9cf2d32d97861f1aef615f36de7e1158667fb81311f49');
INSERT INTO blocks VALUES(310364,'67025b6f69e33546f3309b229ea1ae22ed12b0544b48e202f5387e08d13be0c9',310364000,NULL,NULL,NULL,'a87709a66198d1565d149187d73165ee39e0267f8bb7ab5d13f52386482f2777','425e685128462b348973a941c9d69f4845b49c5ecb8da0c16bad4669831ae2e7','bdd4eb541b30042d63937e330e2b9cc480a3e63ca59d13cf9b7bcb0f96d28d75');
INSERT INTO blocks VALUES(310365,'b65b578ed93a85ea5f5005ec957765e2d41e741480adde6968315fe09784c409',310365000,NULL,NULL,NULL,'982429a22bf73e8f3bd94840cc566452dbb9f454c56cf8191ac2fff6c7343200','5a05ebae560177cecf140d6d2bdca4d73013991e96c5a05a735aea04b7d548a4','b4272f0e28109720418964acf71ba7d5153c1a368edec75605aa50aa5d84e5e6');
INSERT INTO blocks VALUES(310366,'a7843440b110ab26327672e3d65125a1b9efd838671422b6ede6c85890352440',310366000,NULL,NULL,NULL,'15417eebc2316ca67e65f0c558379558f676dba8a871df7b3623dc49e766d90e','f40f6341d6c9db18457c4741306f797ca7f3cd2edf66afc3bbabc29a53275645','10d47329be9109fd01ff626e20d7598c1a541a2ea23dcc2a8e24a73982ef96ab');
INSERT INTO blocks VALUES(310367,'326c7e51165800a892b48909d105ff5ea572ff408d56d1623ad66d3dfeeb4f47',310367000,NULL,NULL,NULL,'90c90c7fe15080a7555edff81722a2a098a98f729f5601268c0d9099819038af','cd76c8dfdc07dd3364c073e630c8e8024cda83deb0ce3254f188f05a488e0f60','5912697af0404151cc97f80443f9b65c40551ff64ece769d3a1ed56f587c4443');
INSERT INTO blocks VALUES(310368,'f7bfee2feb32c2bfd998dc0f6bff5e5994a3131808b912d692c3089528b4e006',310368000,NULL,NULL,NULL,'d75e38cb63a8671e5d194f7d97f2ce17610af78362de915c78ffbe1bb729d427','cff1e64d21d4de56a237124902eadbbc793dc132091cebf5e73d494ad5d8600e','957ab14e9449e514815eedc818c8b1e3ccf9d937e573df0bac202e1e28bce431');
INSERT INTO blocks VALUES(310369,'0f836b76eb06019a6bb01776e80bc10dac9fb77002262c80d6683fd42dbfc8da',310369000,NULL,NULL,NULL,'214b069ef126eef6bf0b8034f33d875319d6c80880536bb8252213b6d0900baf','e052c0fef9b3910b8fcc04a5b2873533f7982e74bcb5382d25fadaf715f7d2d3','648d9c99324e891fa8045ed04d4356a9ff9a3885938483fedd9127bef9a491a8');
INSERT INTO blocks VALUES(310370,'9eb8f1f6cc0ed3d2a77c5b2c66965150c8ceb26d357b9844e19674d8221fef67',310370000,NULL,NULL,NULL,'1f6ccbc328e77b4626670a5fa82223416e1784fe923af730127b49f1df0bf76a','cab5b5933cc7dab9e4a937ba97d7585ddaff1b1220b8be2b4be64d1625f7e8af','d3337f89c95f3d731a26016f19f84117b9b583b2461a685f498165a4b6b848ad');
INSERT INTO blocks VALUES(310371,'7404cb31a39887a9841c2c27309d8c50b88748ed5fa8a3e5ba4cc3fc18310154',310371000,NULL,NULL,NULL,'8dd1339935722bbdee4bd7dbe6498591ac3af644beea552928c031e9a5dbbf32','fad680f8e1b8564539901e7a110278c12d9f3e605cba8d43501fc026e019cd07','983a8d61910b3428719bf27e249e37a5827402de88dddae8c1fcadb4f5c92535');
INSERT INTO blocks VALUES(310372,'d3a790f6f5f85e2662a9d5fcd94a38bfe9f318ffd695f4770b6ea0770e1ae18d',310372000,NULL,NULL,NULL,'18fb2bac0b957001dac0c092e45a33ae9d06168043e43badb060aef366944fbf','8461f0f70726de01b582951745760c4f9a992543393f8b1993b3911b2877eef2','cddca1b5193c1f846d22d998bd54b15e45c947a5c6cfcbffd01a7fc711151d9a');
INSERT INTO blocks VALUES(310373,'c192bec419937220c2705ce8a260ba0922940af116e10a2bc9db94f7497cf9c0',310373000,NULL,NULL,NULL,'0acb7e2582d37220d568cdbcf09beb6f4637ba4da17fb5c00533e42f1ddf0366','d15bb9e8d1102f412ed073b2b31f3c1a393675a36a18c984d5e2bcbfaae6fdcc','5f54ac16f287c033e672fd47284f093a1429258cd6a5e072391edbf9b901766c');
INSERT INTO blocks VALUES(310374,'f541273d293a084509916c10aec0de40092c7695888ec7510f23e0c7bb405f8e',310374000,NULL,NULL,NULL,'c80b89d13d7971b83336cb7cc9d6622139e43254dcab7d319bf8a329d63f7aac','dac68f160c590f98ac8ac9663610c2d434e3a3adc8c1d0cb196bf63135f40fda','27addbcc8cd057da9c41d6c8b664a990eb2f7fd0646a2e776d4bad566673dbf4');
INSERT INTO blocks VALUES(310375,'da666e1886212e20c154aba9d6b617e471106ddc9b8c8a28e9860baf82a17458',310375000,NULL,NULL,NULL,'ae8d342e6e186c7945aa773a478408490c110d2afb7b679949161a637cafd4b5','2202225f11a35ad3091a735fc525afd78fc763b21293d1b4b01d1352b6463ce8','f69d870d7a2bc8a5e5c1c56d08bf9614b261e267efd81d110989f768dbda9f99');
INSERT INTO blocks VALUES(310376,'5dc483d7d1697eb823cba64bb8d6c0aded59d00ea37067de0caeebf3ea4ea7dc',310376000,NULL,NULL,NULL,'25f715d963eee9f4f8800a1830d8a7a5609def4f33041c20acd3f983db694eeb','600d5e13d195e0cbe7b59a1b6892c670e9522d89be9c56a798f7d0f12c10f87c','0bb1876db6d02608720dad58997de174aed54f5e390ed5acedf589ac6a5f5ecd');
INSERT INTO blocks VALUES(310377,'f8d1cac1fef3fa6e7ad1c44ff6ae2c6920985bad74e77a6868612ee81f16b0b3',310377000,NULL,NULL,NULL,'c62cff169f7f2155ca6dded47b524a096f87b81a5a5c106636380eb1241b6e21','26125bb2b31a07813dd4740764526bdab75a09c0ee6abac7cb38bf1551397b29','de7190e1b01a83b5b1c938d7d42061dc2b8b0f5d8002a7a95e4988d105c2c484');
INSERT INTO blocks VALUES(310378,'fec994dd24e213aa78f166ca315c90cb74ee871295a252723dd269c13fc614ce',310378000,NULL,NULL,NULL,'a5dfc28ca0035167397b5ddab0e156ec5a02d652a24d3e8e3dbb7e169a51ba3c','155de955546b7aa2ffd1c69c91e4ba7f049c768ff3404bceef7345476ac2a900','c8623fdae7ca479d1af7de0eaa91703b18144ece895b680a822e4c6cbb8f410b');
INSERT INTO blocks VALUES(310379,'d86cdb36616976eafb054477058de5670a02194f3ee27911df1822ff1c26f19c',310379000,NULL,NULL,NULL,'3107008545f57d800b107701c54d49fd95f1525e6c76262ce406f2eb7cfdc771','f8267bfee54171a109439a57a260e9ad2ee64b439e370d7cd4d56922448e5689','a912e2993e10e349bff90c64cc3f57befe4cf43d2c7d0756fef73fd826417180');
INSERT INTO blocks VALUES(310380,'292dba1b887326f0719fe00caf9863afc613fc1643e041ba7678a325cf2b6aae',310380000,NULL,NULL,NULL,'3f88611786e9738be4552f3bf4ce0050b05dee888f1c735fbf7c34e30af88cb2','b2e71d9d402de657b3e12145d200df325d071f638f5ea2c2fe17213086103c89','6c89ccac0695fb914d20876582285b3d2f73acd584bcc7f1c8c0110e84c4359c');
INSERT INTO blocks VALUES(310381,'6726e0171d41e8b03e8c7a245ef69477b44506b651efe999e892e1e6d9d4cf38',310381000,NULL,NULL,NULL,'df5bc90a416fbe33b4a55093f3c060d829f5e6ea8adfa1e2ae99c335155496c7','3902b7226ef6f041eb7aa9b6bba126855025aa1ca8b5ee0041667f8bb92d9d7c','690494e6d769148bbb11f5a24273686d79d51c9711e13d58b8e22c9cd1952e73');
INSERT INTO blocks VALUES(310382,'0be33004c34938cedd0901b03c95e55d91590aa2fec6c5f6e44aec5366a0e7d8',310382000,NULL,NULL,NULL,'a6344217e46a40bf64800fc701b04580161365dddd47e740f86bbe6ae7d2d742','b22a2d07db7bcf04ea3afe16597edf3364eddaaf795b0ef8b2a7e3f751c49dbe','dff3bfe14e8b95b42dc8e1d65622208c0954289c4d05c43499fa8ed36979eedc');
INSERT INTO blocks VALUES(310383,'992ff9a3b2f4e303854514d4cad554ff333c1f3f84961aa5a6b570af44a74508',310383000,NULL,NULL,NULL,'6ddf32ddc00ae2ed22a9dc5cb02b1ddeaa69c5aa83142b8311a9f17971946581','0771ee792a45f542acadfddf61edcd46beea998f1a183fef2fbd8de4c4fabfa7','b60a2ae79464baae05300b8df90c2c5266d52e10032d5f9bd7024a766377fd0c');
INSERT INTO blocks VALUES(310384,'d518c696796401d77956d878cbdc247e207f03198eabc2749d61ebeadee87e5e',310384000,NULL,NULL,NULL,'cf2300a0d6a8216b2780b1e2ee92ad1aa486942f7ef61acbbf06b19db9f3f69b','c4aa4c6cec46c3c731a3ed6c5764367529b10489ed8b53b878145e0e0e06482a','c639fd782b0a8960b860eee445782bd2f355f8990fafa2e711241b64af8cafc7');
INSERT INTO blocks VALUES(310385,'2aa6a491a03a1a16adbc5f5e795c97ec338345cfdf10ff711ffb7ac3a0e26e28',310385000,NULL,NULL,NULL,'fdfd857fee94bc4e89a9875d4d3b2b1c899eeaf81bb4f39171446a0ea5815218','175f7a6d8a0ece0202431e9609b7ddb25e32633c37acc5141d1cb07575e67f34','0bb155edab9909910e5bba4bee476e155dda789584bb2eaa599dae24b4637ed7');
INSERT INTO blocks VALUES(310386,'9d19a754b48a180fd5ebb0ae63e96fa9f4a67e475aeefa41f8f4f8420e677eda',310386000,NULL,NULL,NULL,'67bbcaf62c11a615a22300d54aae23453121feaadc2e39ad304db71b9ca21ecc','fbaa93a3722406622788b4f60875042cdb58f6a44cbaa4834022fcbf4b187ce0','a548fb0cb0f4d604243356158ab9cc750095adbd50745c1db5830be6ed10f93c');
INSERT INTO blocks VALUES(310387,'b4cac00f59c626206e193575b3ba9bfddd83bbfc374ebeb2838acd25e34a6c2b',310387000,NULL,NULL,NULL,'89889413f4197bb04082441392507ec7fced3f9874a33ddd6f224955aeca886c','db4094ba6f6395b848acc0c27d0fb1bd67d1d753330dc1dfd1724a2da0dc64fc','d8ad3a4d6c0bedb5157dc5781d9c870171aef96bf4e77f8d7451204337924cb6');
INSERT INTO blocks VALUES(310388,'41a04637694ea47a57b76fb52d3e8cfe67ee28e3e8744218f652166abe833284',310388000,NULL,NULL,NULL,'820823452aa537c5206fa669f0ddb463f5def137d1cedd5abac709cfc98aa98d','264bcc4885d1d8179d945cf51758c54376c2725665badeec1b61cf9840ea85e6','77158f53d8a096bde15fa55653998f4cb3331f400a3a9b6ec527d39c14611c3d');
INSERT INTO blocks VALUES(310389,'3ec95ae011161c6752f308d28bde892b2846e96a96de164e5f3394744d0aa607',310389000,NULL,NULL,NULL,'87fe9116a210473ccd5a97932b5121f20d02d6a97c5572c581aee6fff9000cb4','ebdca6320db683741a4406a0541f0f566f212ed888c3723df909d4fe85d6ba1b','2eb826001c02e0654a40eaebe572f729d45074d25478db4e6638f5626443bda6');
INSERT INTO blocks VALUES(310390,'f05a916c6be28909fa19d176e0232f704d8108f73083dded5365d05b306ddf1a',310390000,NULL,NULL,NULL,'6d8c78064901f68dc72a25685e16ecae08b3e2e0e8e0e60b43f047a0bd4b8911','23b96fafc761a30f98e7c7a973ec188e45ffa5a37f4e7ffd57ed85a48100d017','c9a73a15c6965aa0706e543af54cc0f5fd56dece57b61eef56e1b19e1e52ac4b');
INSERT INTO blocks VALUES(310391,'fc26112b7fdd8aaf333645607dabc9781eac067d4468d63bb46628623e122952',310391000,NULL,NULL,NULL,'a6f4fcdc7efa13e148c1e2c3a25afc09719029c8c7d922fe934b73cc85f46ef2','b324f323525aa379e2cb72535267ab8d464ac40c9cac1a94f48f33ff478e2677','2f3534d283b4a0854da067a810d71bfcb8d51b9a682d5071c76434e6af3d3b45');
INSERT INTO blocks VALUES(310392,'f7022ecab2f2179c398580460f50c643b10d4b6869e5519db6ef5d5a27d84a1d',310392000,NULL,NULL,NULL,'a67dac1c26b21157286170c2e8387548fdf859f6fe22d1ba5ac6fe9a65f66caa','de58f4bde45d21f56c2dd2e6911fca09f8858b1f45487134715b5675bdf9dc7f','9d17de0510c40c5a44e9cfc5495eae787fb16074c56831893018f9b791eb1f0f');
INSERT INTO blocks VALUES(310393,'e6aeef89ab079721e7eae02f7b197acfb37c2de587d35a5cf4dd1e3c54d68308',310393000,NULL,NULL,NULL,'a3b80640bce1588169ba8f7eba0858a60fa6298f3a2385ae2d5714939e17459e','09f2386af7069b5888e986dde76123be4abee30acd660282a7e861c8dc95dafe','c5bf467983552344737e7f59b8ad4885ac012c8a95eec58d396d619882be8b83');
INSERT INTO blocks VALUES(310394,'2a944743c3beb3bf1b530bd6a210682a0a0e9b0e6a9ff938d9be856236779a6f',310394000,NULL,NULL,NULL,'3aec7605ad12d221d1f8f35adc91ee91f299d6e6efc89b788d3f7227b0e4231f','b4b9d858f15749f478e8c02e3dd88d34716d961e0d4722b93b89b437b619aff4','a2d86db8cbb849c4957144f979e2156961367022f816144d6dc3b2b7e2483239');
INSERT INTO blocks VALUES(310395,'19eb891ce70b82db2f2745e1d60e0cf445363aaff4e96335f9014d92312d20e4',310395000,NULL,NULL,NULL,'715ff16f4933841f834f7b8b36c8a455a70f6f961862e133fe7445e5bfbd230e','cd8e8dc7109b3f24c67ecf91c548b7cc8dabe6071a89fde4d2b42e11ae3c5e7c','4838d849cb48ef13a93997b528abf4c72acdabe4d144ff4cf04c525496c6b224');
INSERT INTO blocks VALUES(310396,'aea407729ac8d8e9221efd9d70106d14df6aaf9f2f87dc6f490835a9caadf08e',310396000,NULL,NULL,NULL,'d88406041b0f13710482140b0b635ff30cc4ec8c6ec46d12a30976c1352f8d21','4d418a96f0ecff6d0901a4c6e174c07a7f41689977922b63ba28d505aa1f250a','2b25ea890877a4954bc638ab1a95f682945081ba27f4a4c3f5f2729bbd35a2b2');
INSERT INTO blocks VALUES(310397,'7c429e56a19e884a8a77a759b52334a4b79404081b976270114043ba94d7985c',310397000,NULL,NULL,NULL,'39ed9d594577c9571a77ef316d7fe91d94b2a2c954b47577590a2ab165b607d4','55bb9b12ad24f56c2348fbf5339998007ce27a0167fe2266d858d785043e665e','a2ad29c50e0ede256ca9a2d75d3b05b6e2bdd30ad8252251d834aae56a3a3bb8');
INSERT INTO blocks VALUES(310398,'55c046db86dee1d63c0e46e6df79b5b77dfd4ab2ff5da79e6360ce77dd98335e',310398000,NULL,NULL,NULL,'be553449f5341c77d7d9c9c255fa08f210473f0bd9f838f0e250ed70525d53bf','beaabcf6b5a9691e79e8806d34af0170c315c109dbf31ff7a57ddc397b4f2592','3b7f73fa62eb1cf678b2916130575584596b12964eee6a8db58d13f21e531794');
INSERT INTO blocks VALUES(310399,'765abc449b3127d71ab971e0c2ae69c570284e0c5dacf4c3c07f2e4eca180e7a',310399000,NULL,NULL,NULL,'432d5c679bae31b847f77dce7d2978c162be041008fb63cffefe59c4b3a265ac','96df86126b2bf6a993f0dcc413a89e61f29a23cbf7c29fbd62bd0545f49235aa','157788749883d33275d1eb96d845e360e69396b79779ee8dea979679aa9ea4d8');
INSERT INTO blocks VALUES(310400,'925bc6f6f45fe2fb2d494e852aaf667d8623e5dae2e92fdffa80f15661f04218',310400000,NULL,NULL,NULL,'8f6c063178ad42157f392ace980809c937133893db3367570e31132b80cf219a','5622e8f1d755f714fea2cbf6b6b12761850586d91cbd04dbbd71ba8acbbe8219','d5843cddf7a0f36b98b6b83d1a4b8cca4c3fcd130b6afe1fadae4a13599386a9');
INSERT INTO blocks VALUES(310401,'f7b9af2e2cd16c478eed4a34021f2009944dbc9b757bf8fe4fc03f9d900e0351',310401000,NULL,NULL,NULL,'b06734f71df86a53120569da530e86566dfc23979fea9c1363b708b7b2682f9a','c641fe5370b09ac69b49144ec7993d75f6659f0e9cdd251999abd309730a0347','a80cf04a4798fbd334f4222e9ff79dde7cae1ec78d3d1fd85aeaa92ea7f4c3e9');
INSERT INTO blocks VALUES(310402,'1404f1826cd93e1861dd92ca3f3b05c65e8578b88626577a3cbad1e771b96e44',310402000,NULL,NULL,NULL,'dffb8cc3f37f91953d672f01a852c6341467e16fbb3e24b8f05d2a5bc63490b4','6a972dda792853f6ebe7da80cf0854951ecf070568c66da47b41c8af69043100','2d05e337e3868009b1aa37b931939120fb1b47dcc7b0f7e5c0fa00d9966e2600');
INSERT INTO blocks VALUES(310403,'f7426dbd4a0808148b5fc3eb66df4a8ad606c97888c175850f65099286c7581c',310403000,NULL,NULL,NULL,'61d8c0760c23c1d6361683a8da86960f110944617e85c31a6f648684708d6795','888a71838c9758484f5281e2b92388b59c0dccdccbbe43254fa12e2d5bd93212','067af3eb61ce0edad7692a79f3c197cfb330084bf8dcce8d6a2675b4adc49b55');
INSERT INTO blocks VALUES(310404,'401c327424b39a6d908f1a2f2202208a7893a5bedc2b9aff8e7eda0b64040040',310404000,NULL,NULL,NULL,'74f1c60ba258c93248c249b6f1414580f40b8918adef544245130be2635323ba','ce8537bf1a48385d09ecffc0f74bd4b7799892f9e874055352c77d4b144a65ea','50a1f59f0d3d0b5bfb495df31d93f07ba35caa501e4a961354693f9da53f6570');
INSERT INTO blocks VALUES(310405,'4f6928561724e0f6aab2fc40719f591823ca7e57e42d1589a943f8c55400430a',310405000,NULL,NULL,NULL,'1bb06b27338f4df1d60159498b4807373764d2146a528afc08e259d776f300c1','b4ae68e5b3788533c41e8bd1694e04d55cc1dc5e59dd2d2cf6467ee5e56ee624','31d6798f39184ef7c1629a280c0a4096200e670bf2e10e54bd8679b91af50a69');
INSERT INTO blocks VALUES(310406,'6784365c24e32a1dd59043f89283c7f4ac8ceb3ef75310414ded9903a9967b97',310406000,NULL,NULL,NULL,'e7f696733bf3ed66aebfb47692aeb36030795a87d9a1ca6989b2b4e1e5ce1d27','89e2af1863d6940605004a5aa37f11462ddb8a6b89af6c6c18783f095129c531','647b9f0ad8daae3d8d026f0a3515b8ae47a27b8f5ea5220d9d90edb03d6cc7d7');
INSERT INTO blocks VALUES(310407,'84396eb206e0ec366059d9e60aefdb381bca5082d58bffb3d2a7e7b6227fc01e',310407000,NULL,NULL,NULL,'87fccacd80a335d55428b08d31174b866f31cde2c57580cb202118d0d4dff0cb','28be214618152ceb3c74ae221173fa465c2b2343ba5c19121dcac0fbfee5c237','f39d50d3ac1dc62971ffb8153904ea52192cd4636fc2dbb497dbc991ee70e195');
INSERT INTO blocks VALUES(310408,'4827c178805e2abae5cb6625605623b3260622b364b7b6be455060deaaec2cda',310408000,NULL,NULL,NULL,'3438e31df1840ea10235cc098ea4eb990057245e7f8639f647f21336ac63bf4d','338da0226f960c7ebbde395b937aacf78724808ba18572a5a6de62ac7b12f42a','ff155ee236efb4effe8c662013fbf90f3be6829dbe0bc60e2f1ffab257cc3d4c');
INSERT INTO blocks VALUES(310409,'01a719656ad1140e975b2bdc8eebb1e7395905fd814b30690ab0a7abd4f76bba',310409000,NULL,NULL,NULL,'59c9587691db1f8ca417b00fed6f5c2894435cf63f6f010dbc1d9e0d2de4e458','7e6d46a971eeb67d63d49b5ddda221a1b2f162f69785f75b2ce2011427b6a3af','7237f256499934fd1e5170d8f705ca4e678e7ce1c9a92a93ff198ddd68b0d42f');
INSERT INTO blocks VALUES(310410,'247a0070ac1ab6a3bd3ec5e73f802d9fbdcfa7ee562eaeeb21193f487ec4d348',310410000,NULL,NULL,NULL,'e5aeed9eb34a401ec15242b0f083c266124f9a8548d4997c76e697a8e2843dd0','657b76df9c1c9396d299f452964dc8831ff3cabe1c847305aefa655adefba9e9','7f2f32f5063ef64447398389ffe197795fe68c166773b75761df02c2ea6dce30');
INSERT INTO blocks VALUES(310411,'26cae3289bb171773e9e876faa3e45f0ccc992380bb4d00c3a01d087ef537ae2',310411000,NULL,NULL,NULL,'1c0f8795e47e049e6891535c03b1939d2b5029fb1d2eafbc1e4a3ad37c99c941','619f50f1399fff1b28f1404da1751162f59ffe2fe1f2cdf3a11d5b96405c6d5a','476680d96ed203f1f56e4e42f5af9ae1d82bf4cbe9b374bb5489ae53c55b99c9');
INSERT INTO blocks VALUES(310412,'ab84ad5a3df5cfdce9f90b8d251eb6f68b55e6976a980de6de5bcda148b0cd20',310412000,NULL,NULL,NULL,'ce11f7c594a173a63f7f3a905b70cd917129b425ebe5c94cffe1487b2b3dc5d4','cbb77d5c88f9f9bcf3993794dde6e3beb215a18e0ff8f154b3b92a263e9eead3','c9a388fb1975ccb50aabe4c0c209916760b83a3e7d9456394f8c56dc58ac1dd7');
INSERT INTO blocks VALUES(310413,'21c33c9fd432343b549f0036c3620754565c3ad99f19f91f4e42344f10ec79bf',310413000,NULL,NULL,NULL,'77822cd8e249115b3a4e1e9d0cdef1c30ffb32964e69d1fe53626cbaeb7acfef','81026bc74b1a3af368882a50360a6cf6713b8987991d0e8ffa1828865ecbb288','7f30b1abb6feb96ad5e5cc4235f8edf0390ccbcb8d2818ca5f8b0628fa067867');
INSERT INTO blocks VALUES(310414,'8cff03c07fd2a899c3bcf6ac93e05840e00de3133da14a413e9807304db854b6',310414000,NULL,NULL,NULL,'15a39ea07fef73359313f44bcb1cd5606cca7eb0226667e8d7cf8b69af80f741','27cdea2af207978e4cec729267fd1fac8383173d86593aa403359bb098065789','1901010e5c93ad99e7bf97d4a03c808415e36e1b82c96d68810a73c4a28431f9');
INSERT INTO blocks VALUES(310415,'dd0facbd37cca09870f6054d95710d5d97528ed3d1faf2557914b61a1fc9c1cc',310415000,NULL,NULL,NULL,'01d84dab96e4f7278d7013d7b264c39d1267aea911c061a451a388fd5a8a7460','fb78bc353da49138a4ed84f3e6db59b2ad46f535a657974179fca9543779f7af','a2688b8907d73f92074d54c6177c05325357696836818015584610334f0a1f01');
INSERT INTO blocks VALUES(310416,'7302158055327843ded75203f7cf9320c8719b9d1a044207d2a97f09791a5b6b',310416000,NULL,NULL,NULL,'5ffd0e606ef0195a91e174ca48b8b7c3e447f36dd74fd297d037b170b6f9c261','cadd410a525997e7ce70f863b480789a51ab801ca793ff9897daeb8daf96ec63','f2a7c7f3ddf6f773fcc5cdcc60dd4d6c3ef183e52db95c44ed4bc201eaa5ee8b');
INSERT INTO blocks VALUES(310417,'2fef6d72654cbd4ea08e0989c18c32f2fe22de70a4c2d863c1778086b0449002',310417000,NULL,NULL,NULL,'63669be809045af99a6ae980448971fa4ee432b109791b15a3b1c1f6c7acbbfb','d62e97473bd7c79a6ab4181338a1c885d6b80ba09be53e0c186fd50b1b2948e8','761f50ca3a64e2b9a7f65fd6c2777818891c165f0c5cf512bfa91306851aa599');
INSERT INTO blocks VALUES(310418,'fc27f87607fd57cb02ce54d83cec184cf7d196738f52a8eb9c91b1ea7d071509',310418000,NULL,NULL,NULL,'81ac9cb4f53d248a7d374db1e1331f7fd7698cfa944b14adf57896abfbdb31da','82555ba92400e2d7d16ff8d3065f32d4fe0810b9ef78e8ae631d78096343cb9b','937cb76e2619f5f01f1c119c2a0ea42aa51ccd04ab079656b1c8b965ff1755df');
INSERT INTO blocks VALUES(310419,'9df404f5ce813fe6eb0541203c108bc7a0a2bac341a69d607c6641c140e21c8e',310419000,NULL,NULL,NULL,'abb3174335c261291bd016f24c28aaa66ffe1931d970b7dbb43013bcd84fe134','ad817116b62c0ef2829689694917932fd1539cd3209b386abdc64b071ba72d88','1942de2905a1467ca0079c7138f99811b0767a4c82838fc4f483643968e9d54e');
INSERT INTO blocks VALUES(310420,'138b3f1773159c0dd265a2d32dd2141202d174c2e52a4aeac3588224a3558372',310420000,NULL,NULL,NULL,'2ebfd088ed241e16bdba1ca78ba9319aca92a4d545d92669f8b383b8d7bc5021','7cadb66aebd141d488d7e6fc43cd35b66c9c6d5f7d63123e90a4cc379ddf2ba3','ff2a198f2e7906462ad8582832e3ede02e7b647222713497f4e9bb6bd0c5a9fc');
INSERT INTO blocks VALUES(310421,'71fe2b0e02c5cad8588636016483ddd97a4ef0737283b5fd4ab6ea5dc5c56b9a',310421000,NULL,NULL,NULL,'e45e8a448ded22c75923d4f6fae84120335901ab9940b6bd8f512265cb67418c','86a2e1b2723194ac78b0feeccc6086f08de3fae5a2aaeb68b938ff6a91e748a6','f9e4da343270100c120bb9f2fc4fdfff08e6363fd6556d60eb9b6ea45600af51');
INSERT INTO blocks VALUES(310422,'cd40260541b9ed20abaac53b8f601d01cd972c34f28d91718854f1f3a4026158',310422000,NULL,NULL,NULL,'70565726eea7665538a523f340ad9f3d12af040d432632740c1675d1a8c9ccc8','90fd435b4a59fad2ee2c7c5db75e743bf9147205eca8191afee976812dc5e1cf','4491e0ee4c7983686ce268daeadbd152036109f2fcb17895027896a5f43cf9a9');
INSERT INTO blocks VALUES(310423,'6ca0d6d246108b2df3de62a4dd454ff940e1945f194ba72566089f98ad72f4db',310423000,NULL,NULL,NULL,'6d53ef17c5892f92a9a5c78cf650bc17b49420aeb89620d139a1bacf4aa34c19','c5d8bb4beaa33f9715685fb38c7496f5a59a531e21294f00d8a1998aae802bc0','3accf0ea86713429f23a5a831551bd74e165e97488da3edbdbf26a5ed221045d');
INSERT INTO blocks VALUES(310424,'ed42fe6896e4ba9ded6ea352a1e7e02f3d786bfc9379780daba4e7aa049668ad',310424000,NULL,NULL,NULL,'c5732349a5763f5e185b2ff8d1841fa7b58b8fb730320d15b836c53bc51ceae3','83241ebce273ca176bd34cc75d3700591d6ba16b5963943c1c3a7834a4b81b0a','a2b7d3bdfbc1176a74233985c650b86c2cd86adbdcc53426d82eedfb15080c46');
INSERT INTO blocks VALUES(310425,'73f4be91e41a2ccd1c4d836a5cea28aea906ac9ede7773d9cd51dff5936f1ba7',310425000,NULL,NULL,NULL,'3d6db950468de908f2e73eb490b25e34bdd2b7d63dc3dd32fce15156675d7841','24b610f34f07d0e197e2bcd7576811697733711ef111b60712b6db382bc1aa31','fab67b63341ca153ecd2954b0979d819c0bd49358ba3511ac49feb3e8884900e');
INSERT INTO blocks VALUES(310426,'9d28065325bb70b8e272f6bee3bc2cd5ea4ea4d36e293075096e204cb53dc415',310426000,NULL,NULL,NULL,'1fc75ed22228dabd177300c04eec73fcb3377a0bcf4dece290fed431adab816e','7991d47d932f72504e71f0abcffe2911ea3f3a36e86955f53d81c2ef8c2e8892','fe8e9be0f8b7da416908f5c765ed2ed9bcfcc7b4904cf42d78ad7867e76c1675');
INSERT INTO blocks VALUES(310427,'d08e8bc7035bbf08ec91bf42839eccb3d7e489d68f85a0be426f95709a976a2a',310427000,NULL,NULL,NULL,'e03e3d3f09b20d9f7ade3a280e13e8f890e74630f7010396fc06c06aabc4b66a','eb49b93abb42d96c694fe6e9364db420de99f5102f6c487ec6670347ae1966c1','4f9da101bb869835dcf080df772783718297fc5b5a16eebda0782dd053178856');
INSERT INTO blocks VALUES(310428,'2eef4e1784ee12bcb13628f2c0dc7c008db6aaf55930d5de09513425f55658a2',310428000,NULL,NULL,NULL,'01b6beea649bda23dafacff5cd50d56a23bcb07d5b8535b79bca7edac8043310','f56a535f5968c5d4318d03b8648998098555c53f56d2ef0a48ac24245500b935','30116bf6b727d96860fbc9381b2a576d580d98345ffdbfe9d46f6d9278872823');
INSERT INTO blocks VALUES(310429,'086bfbba799c6d66a39d90a810b8dd6753f2904a48e2c01590845adda214cf8d',310429000,NULL,NULL,NULL,'dcd9535ec484caa0a279c7fa66eafe8956c391ac55668d79562ce7e45b0db36a','7f1a2a98ecc8ace2ce9fae785d1efd1c22764623f4de256069ca9edd25c7448c','72bb503553db5c07d9b4d2fcce13aec0d7ccbd9c5347f575c49ee696e03f1cab');
INSERT INTO blocks VALUES(310430,'870cf1829f84d1f29c231190205fe2e961738240fc16477c7de24da037763048',310430000,NULL,NULL,NULL,'17491f7169e0c6817482c191d92e725558dd14ff0f37646c81e0d6811b9c219f','78a4500d9d5d49b846ce8b463834f8f7189804cee37e4b91f381cca0f8d0c32f','6c9b516941552ec22be46579dd0e6750a1fd5158686bcfc65ae4f4381530f160');
INSERT INTO blocks VALUES(310431,'20b72324e40ffc43a49569b560d6245c679e638b9d20404fc1e3386992d63648',310431000,NULL,NULL,NULL,'18b01aea53a2313aa15d8073afbba5f63c351832755f47e2fe16dc022c7e3e7f','3a739167d407f7b36783b1d78dc97f66767ff2c970f1a02f06d21006ab82c03a','0d881362b3eeada387ca7ddaaade5f6458d79c20eb0853346330376263c28c29');
INSERT INTO blocks VALUES(310432,'c81811aca423aa2ccb3fd717b54a24a990611365c360667687dc723e9208ad93',310432000,NULL,NULL,NULL,'97729b62f8a227c3fb2d8c3780a245ccac651ad4cbd1e3bd0901d73358cd8e51','ef9bfaf5233640de8bac43d14aa426c504e96feb4aa6a9e4d2c9618d42362d84','fb419a1946f5858a3f244fb7995b9317e9285f18f50873e480412ce91c8a860e');
INSERT INTO blocks VALUES(310433,'997e4a145d638ad3dcdb2865f8b8fd95242cbc4a4359407791f421f129b1d725',310433000,NULL,NULL,NULL,'30a35c4a7cd8bc979708de88d4a649d4ff235ac841a76f6c8b85955234f8d749','352c90e65b388102c13def048faf451dbad1b25d9b32e8646180b1afee5b4fdf','0ed441a897e6f7ee60d36a72bb11961f34783ee29c4bcc3bb3dabcdf52e09311');
INSERT INTO blocks VALUES(310434,'61df9508e53a7fe477f063e0ff7e86fbb0aef80ff2ddedc556236a38f49ac4d8',310434000,NULL,NULL,NULL,'956cbd8f189c3dee0a979f5974eef98aca9f8b847219a7ea23bde27ec255d692','4888e8c6bd29b377bb8827705aae15db9eb649ffc20af2b107cc590fad96bbe6','35de6fc1c6c913e0bc8f577b96711180f989600fdc27491a82c6d8ff32c0605e');
INSERT INTO blocks VALUES(310435,'f24cf5e1296952a47556ac80a455a2c45da5c0dc2b388b51d235a3f741793d5f',310435000,NULL,NULL,NULL,'ae68433bd3583347dab1c204b00fcc0696c544704edc69b025ecca2c822e538e','4701fe9667b9e18be6559bac37b72d0a48ac2a2101173c3f87f7b7425572ba1e','c96b98cd991fc5c1d287e5a78fb9614240e5a5cf5105dfd9444927642994a4f0');
INSERT INTO blocks VALUES(310436,'a5e341ba92bdf9b3938691cd3aab87731eba5428bb61a804cecf9178c8da0c19',310436000,NULL,NULL,NULL,'a176b67b01219d1dcfa486e1024eb8ec395d0b8b094f9d50104bb44f9c8771ff','2f80439c582faf40f61eb80496790804da7b12b1352f658e1d5178a827b3f92f','429caad37519108635665da217c84d1e63502c7693cae3a9a05478d0a1c6e046');
INSERT INTO blocks VALUES(310437,'9e18d0ffff2cb464c664cefc76e32d35752c9e639045542a73746f5ec2f3b002',310437000,NULL,NULL,NULL,'182ed8f1e3ca5e36ee668822c50c346bcb451887b5f79df1de0ee200f15df13f','fe45c57bfeea01d75340f0db2ab542f506d2357da16766f0c52a4c0541150e05','d272940f2e9a7ce94bc74ac5eadb5f8d88c954edbad78c3dd88cadfd11ebc4ce');
INSERT INTO blocks VALUES(310438,'36be4b3470275ff5e23ed4be8f380d6e034eb827ebe9143218d6e4689ea5a9fc',310438000,NULL,NULL,NULL,'1832ab829b5f7e566e459c70313b4565d8b4959cd5badb1eeb6b7b8d6f01613d','a84053cede785c3c7bae80196411236929b96c0dc121a0ff240a33fc98126ab0','e312cdf7999352dc6127c51bfdc03a3ad03b66648d747691ad73817d6dec19cf');
INSERT INTO blocks VALUES(310439,'4f2449fce22be0edb4d2aefac6f35ce5a47b871623d07c2a8c166363112b2877',310439000,NULL,NULL,NULL,'667be63e95ec565ebc3aeebff75ef0a27d56a52e2670b18fea4d62d370a01e6c','2b55b8e89b18000021b3b5dd09aab4396b8656248981f05cae3a16bae6a8aaed','815205dcb5c0269db4a98ae5aa7bfa107d587d686383b78af31e9c6eff9a7c8f');
INSERT INTO blocks VALUES(310440,'89d6bd4cdac1cae08c704490406c41fbc5e1efa6c2d7f161e9175149175ef12a',310440000,NULL,NULL,NULL,'4d65883e103c04c8a1b005a1648d1d7bfb56b28f099f80cb228e6abc57df6bea','7caaa1fbf87ea2889bc6a9afc82b50fa3d39dd1b2e9ddf0292176c52d3c8144f','f01d1883b562f7c06bbbbd81b4215fea2a6c84e3ef536927f3ff6bd053eeb7ce');
INSERT INTO blocks VALUES(310441,'2df1dc53d6481a1ce3a6fee51ad4adcce95f702606fee7c43feda4965cf9ee15',310441000,NULL,NULL,NULL,'8f8f20d91a52ca1116992d9d7a0fd97a2a28342a1108f0c51dbb24969b54bafc','48acccf91d2a66fbb6186416cf9d72010a88e6095be174fd86110a0e578d355d','f734b3ceaf2c0fa7607a6ab52f89d038fb1ad2406a7460b3ed2e75a3b5270585');
INSERT INTO blocks VALUES(310442,'50844c48722edb7681c5d0095c524113415106691e71db34acc44dbc6462bfec',310442000,NULL,NULL,NULL,'7757f02d557766a1c1d929812679543332d86806a6216f964d565821eb597a12','897424a4b61b00ea07a925b73ecfb0d533e9fe0ac7e17a525b12109bd48f7c36','dd73393fe53d179da73502606e93415e5b86b51dc5c407d5e38a5e6570f38e86');
INSERT INTO blocks VALUES(310443,'edc940455632270b7deda409a3489b19b147be89c4d8f434c284e326b749c79a',310443000,NULL,NULL,NULL,'9b32167f665fa89a66d17c133cf80c564d5ffcb4c0f2bd0ba30eb225e436cd2a','8ec2e3ac98217ad91ee5676d7757567812adc0097d5049968d1f9c66d25a9353','1105f81e248a71767af91b66afc1cb337a00a62f39218fdab2367b1e75c8bd2b');
INSERT INTO blocks VALUES(310444,'68c9efab28e78e0ef8d316239612f918408ce66be09e8c03428049a6ee3d32e4',310444000,NULL,NULL,NULL,'47dde77ca364a1a9a2ec6525604a2349c4fe33dcd76bd66ed76ef90d1744414a','a7e7bb7aca810ae4c43da5d4f1e938e88152dab0dc41faf5e8be73b606b5843a','c7819156125e95c9f51df7987817ef1e79e07ce9ad4177ffabe17b0e081095c0');
INSERT INTO blocks VALUES(310445,'22a2e3896f1c56aefb2d27032a234ea38d93edf2b6331e72e7b4e3952f0234ef',310445000,NULL,NULL,NULL,'46277ceffb0accefc2eed95b03dd3fdbb01f8e662a312e27a4614a3719980ec0','625425cafb8180a7813d7179da2c9c944ab08a20d22a756189d01bce16514bf4','8ad55bb98b2ae30057f9c4e2013422b519f2fce4a8ae6528b0cc5389e7500658');
INSERT INTO blocks VALUES(310446,'e8b0856eff3efce5f5114d6378a4e5c9e69e972825bc55cc00c26954cd1c8837',310446000,NULL,NULL,NULL,'435aa37198d776e7e0003ce7dd64890154e4d3261ee3e2bd97068377885ea347','5e00033564bd8e7fcffe68646c17b746ad82ebe941e1ef41cbc37b2f2015ff64','4dbad28fe664e1a51e5601a1e087f2e17ca13d78b74edbd8d54a1b9656386aa3');
INSERT INTO blocks VALUES(310447,'3f4bc894c0bc04ee24ed1e34849af9f719f55df50c8bc36dc059ec5fa0e1c8a8',310447000,NULL,NULL,NULL,'1c42d44641a097a76374b060f39159863b9069a60fc972a81e8bb59a2e3afd87','d1cb4138decc4874ee9e37d5d41c6ea72b5e4a27b416afd00f63830a110a37a3','63315e3aab360dbae38c72e98d96ffe624eca044686255629b2ff1a407f123ae');
INSERT INTO blocks VALUES(310448,'6a6c7c07ba5b579abd81a7e888bd36fc0e02a2bcfb69dbfa061b1b64bfa1bd10',310448000,NULL,NULL,NULL,'e9cb4077acee9d563f1022adbf32b0d1e92847ee02ff7dae79b81a7a6045fb5e','c3c66fd79842ee4a370689d529e375caf742a48d6a5a03de0953b1122e39f601','b39f41590d926c9cf3f13e7d3e28c5729068ef977812e48a88bb16220c253f0a');
INSERT INTO blocks VALUES(310449,'9e256a436ff8dae9ff77ed4cac4c3bfbbf026681548265a1b62c771d9d8e0779',310449000,NULL,NULL,NULL,'b4dedfe28732974e9f149049086e76cf057d14a0dd5d264a1d02f333b94070b0','9eb3d1e3b10036768de18b3520e52d0a1a2a0410ba2eccf950b33188cffca876','6064473b7f9d4f5e36d6b161c0e0ff629d1f5ddfa87a0add89bb4b0b9056efd2');
INSERT INTO blocks VALUES(310450,'2d9b2ccc3ad3a32910295d7f7f0d0e671b074494adc373fc49aa874d575e36a3',310450000,NULL,NULL,NULL,'3d0012dfe1d6a563b8d2a0a4fd18ee1939587af0b6428ef04dee6261bde30a7d','675fad80cecc5f5d3111a9981c926e4c77872d59ec5129c13acc6442c0456d4f','6d06ab26750e5cbc9b5d137e0a07879b053dfcafaa3da5e70f9107e0a45caa9b');
INSERT INTO blocks VALUES(310451,'55731a82b9b28b1aa82445a9e351c9df3a58420f1c2f6b1c9db1874483277296',310451000,NULL,NULL,NULL,'7ed8711c14c820389cdf0217840261810c68f5c86ab02a914ee08f2bc8cc6899','7eed7986d985f15b357a49c88abeb306b84f3d28a748034cbf33b75e32c89fcc','f3fbbc5cb3bd44985a61d95f5ef50a262dfa846897ac2468038bacdd4101f751');
INSERT INTO blocks VALUES(310452,'016abbaa1163348d8b6bc497cc487880d469f9300374a72ecb793a03d64572aa',310452000,NULL,NULL,NULL,'3ed98a8b9a889735c67fc1af09cb29212673572744ee8d88ef95de30f2c871f2','43bed119ee7a24e7d24ebf3a9175def505ad82ae72792b45294ffd0baefdf6de','8b762e44de29ee3236fe20fd933460156c462ce18833cf68bdd1e3b98e979693');
INSERT INTO blocks VALUES(310453,'610be2f49623d3fe8c86eacf3620347ed1dc53194bf01e77393b83541ba5d776',310453000,NULL,NULL,NULL,'69c19605b20ae9faae06256378aa6129d835d370fb61bd6e785500ac4f26b3a0','b20b890e76aa0f5ca2fbb77aaf09c491fab56989fd0e0ae7b19b92d87aec15e7','53ffbeca4e60358f9d169aec4ea79dd151d0e1b9ef867965d6ba29e3d9b4a102');
INSERT INTO blocks VALUES(310454,'baea6ad71f16d05b37bb30ca881c73bc48fd931f4bf3ac908a28d7681e976ee9',310454000,NULL,NULL,NULL,'24deded98d9b7b5494f13c5d338ba10bae326fa0e7466faf55f3ca69b63d85da','b5f7e30a38fb15953ff4045b7ba445b08323a8210708f66380839cc10efdd80e','fbfb961e9dd0964ab5909b494fb08b2ec26cd16a109e285553498fd18c5a149e');
INSERT INTO blocks VALUES(310455,'31a375541362b0037245816d50628b0428a28255ff6eddd3dd92ef0262a0a744',310455000,NULL,NULL,NULL,'f5826972a4f1dc2de05b5e685999c9f2235ceae0c5c8ee9da7500ba25c5cac02','9b0128ff045589a8f9c2b42d945decc5a9d8504226a46348ca810d866e728e1d','ccf78ea10a0a7b35adecd22bcc6efc788394bb8ad05f417f163a7ff5361cd44f');
INSERT INTO blocks VALUES(310456,'5fee45c5019669a46a049142c0c4b6cf382e06127211e822f5f6f7320b6b50fa',310456000,NULL,NULL,NULL,'6c5c5c43ee4eb0e752aea078bfde101dfcf2c8abbf11ee111f797f10f31b2f51','9cb065f1ddc3873ab873daa7f57ac80b7c861602c05ef987b59dbb05b7d25ed8','478888394fbc7b012cbb5c67e0b4023f3a0360467cfdd6f52883e105b0c75bfe');
INSERT INTO blocks VALUES(310457,'9ce5a2673739be824552754ce60fd5098cf954729bb18be1078395f0c437cce9',310457000,NULL,NULL,NULL,'ff89139dcd62b8a6a1ee33db7ef83da11254437edb3b987bdbf783e4fed71ba4','1594db9ff239167650e5254daf98e434027f41d4825ea65a975731b906f82527','04d3c33ac6bb7eb6d8375be1d28debaf07f96361a8891e6f0112f6f4685fa2a5');
INSERT INTO blocks VALUES(310458,'deca40ba154ebc8c6268668b69a447e35ad292db4504d196e8a91abdc5312aac',310458000,NULL,NULL,NULL,'9c71f5d3aecc3e9229371450e7380fae96c5c9f676a0453f631997ffadfb6169','74f8eb036644c5534d31560393b658e80257b124cd7af26568bb148514a2ba6d','49eea6724c01fca2ee8c8f23d03b06a9682e441ec757a2da0bf8b73d4c9c47d4');
INSERT INTO blocks VALUES(310459,'839c15fa5eea10c91851e160a73a6a8ee273a31ab5385fe5bd71920cbc08b565',310459000,NULL,NULL,NULL,'1cee8c2482b113e5dafdf9c805a933c5ad819c07ad60857f0d37893ecd9cc04c','c5e0c1270a4fec8ecf1d449cdc95417a84f7f3e1c046ffb9a3e35b286292ba2a','ee8d54060e28ef05549a6ce692b74f1a22f8e6a0c5a7f615b2ada5f52fe979f0');
INSERT INTO blocks VALUES(310460,'9b5f351a5c85aaaa737b6a55f20ebf04cafdf36013cdee73c4aaac376ad4562b',310460000,NULL,NULL,NULL,'f373c849ca43515b9ed9d995bbcc8541a2f4c29223f9a735bfc3501455abb214','6a2785d7be26b85f0d8cdd5e5c76b81861799623eda6b284a988230d2ecf27f5','3274d3ef2e302a0402ea9ada0e97f47886c163a02858519e23dc1d71f1644809');
INSERT INTO blocks VALUES(310461,'8131c823f11c22066362517f8c80d93bfc4c3b0a12890bdd51a0e5a043d26b7b',310461000,NULL,NULL,NULL,'4372bdefd4ada06d245a599d3c7dde2713ee64be7be686874b4fe77fdccc06ad','98303e9216d02847e962256693e6596afe5951965cf85a9a0f4a45632ea5e0ec','2375f8a283e6b69ab39ada61ccdf4a6c5fd70e4009f4e4698fec7a3ab37a4fe8');
INSERT INTO blocks VALUES(310462,'16f8fad8c21560b9d7f88c3b22293192c24f5264c964d2de303a0c742c27d146',310462000,NULL,NULL,NULL,'9dc773538c6726a27813415b6f39851622b8125e9ed495fde887a1a9134559d1','b38da37058bfbc3aa1e9556c0cf6575740e07b951abeee160e774c2c7e08296b','acbc50dd1724147bff11ad0c551bba617d25172c1f6a33f90ea9886cdf611711');
INSERT INTO blocks VALUES(310463,'bf919937d8d1b5d5f421b9f59e5893ecb9e77861c6ab6ffe6d2722f52483bd94',310463000,NULL,NULL,NULL,'13d44adfa5e402d96ca4ce10b6882246b009e5eb030cb93b3d73c9deddae7869','a20adc2a414101f2d8929ac7c378ab5a357c5c496b1cca542dd0546c4ef9c473','22f59dcf35c6dd1f442c930193e59e71109eebd3483ff9371c19b79ced2914b5');
INSERT INTO blocks VALUES(310464,'91f08dec994751a6057753945249e9c11964b98b654704e585d9239462bc6f60',310464000,NULL,NULL,NULL,'accfbec346fd492aa13fd081f1d958e0888132c03ead001ef0f4988bcd89a981','16fcce06c83b712640e06e67b7f5dc4b3f352fac7286e826904aceba1f7a6338','9d808e5c51764a3a6ce8b650068aef2397da16fb97f029659699f087beb9c80e');
INSERT INTO blocks VALUES(310465,'5686aaff2718a688b9a69411e237912869699f756c3eb7bf7c3cf2b9e3756b3d',310465000,NULL,NULL,NULL,'6175eda46dea8329770f5ea2678d974cd2499d98da7847e021890a2dd9d253b6','b38c9ae0c08db0308c97194a8c95f54bc93d3b3ea62a8b3da99a9f36264ddb5e','0ed8c27cd51aa9f5e49df0d17fa4552f618fd7f85d847cbf4b51e429d851403e');
INSERT INTO blocks VALUES(310466,'8a68637850c014116da671bb544fb5deddda7682223055a58bdcf7b2e79501fc',310466000,NULL,NULL,NULL,'c6faf47ca22a5439549d68cf7b3cb07fe74e61ce797e9ee9a7fb02606bed74d5','db53d5b0eab1df24725337ac1c9dc0800c63097350c6edd7ebc930017538bb07','192a19c1df641e879c6e5af8829ab12a1439222d3a4c65aa45a307aa6ee529e4');
INSERT INTO blocks VALUES(310467,'d455a803e714bb6bd9e582edc34e624e7e3d80ee6c7b42f7207d763fff5c2bd3',310467000,NULL,NULL,NULL,'1b2a055c2cdf9e04ffc01c07333b92dacbb0bd1183f6dee7949f15e6e61320e0','e8b262acb40e0c769ff896cef74dadf0cb2af295b2e670ddecd7c9bee9432d44','60966f1e317db79b9d877e74ae12da98dc9e2dcb6ce5a1eff9de01e6697da05d');
INSERT INTO blocks VALUES(310468,'d84dfd2fcf6d8005aeeac01e03b287af788c81955612375510e37a4ab5766891',310468000,NULL,NULL,NULL,'81cbdb0322d871ff77a62a872c8b3156dbeff722898aecfc39089e858797f22b','7dd3c1774611a665fbf02cbc14b21f5395a95ca8e7a8a5f393699aaa7851ba2d','a20bc1befba9b7c4d0bea818cfc65529ad218807af09dc774561c9a0cea177dc');
INSERT INTO blocks VALUES(310469,'2fbbf2724f537d539b675acb6a479e530c7aac5f93b4045f4356ea4b0f8a8755',310469000,NULL,NULL,NULL,'a3e98e698c0911a960bc4a62f5fc86910cb91945d3ea70ef46ebef4c63f8c899','46a2f2205b03ab05bccc014dafc7c9ef86ec4f94d1d60593cb34f8b2dc07ef44','8d56eb5f5631ca2e0046b746e508f9b674a48a9d9aff5a8db6ab1b8b8a946726');
INSERT INTO blocks VALUES(310470,'ebb7c8e3fbe0b123a456d753b85b8c123ca3b315da14a00379ebd34784b28921',310470000,NULL,NULL,NULL,'222e79ab551a0290b03edb4352ea106933be7e1e6267c6fb1412ea41a3bc3b2a','b3ac1da0d971407def6eed788a55ad7a2571deed303b3518004707e1a4fb805e','f554ccb3ad7c51a60e5f9f7a3f2a47bc9fb778b08cb059a03abde53d0ed09acc');
INSERT INTO blocks VALUES(310471,'fc6f8162c55ecffeaabb09f70f071fd0cb7a9ef1bccaafaf27fe9a936defb739',310471000,NULL,NULL,NULL,'6428475cd3f9e0aa9e78ce6277fa1ce6260dc4606c0fdfc8e9dac2c2372f2c1b','e691e1b1a40c7779a9b0889d73bb23256ba61aa40d314e7d9be14869da6eef5b','30a5277a01c0aeaa6ca784718d547ce9ef44bdaaff670d51584ade8aace2eb6c');
INSERT INTO blocks VALUES(310472,'57ee5dec5e95b3d9c65a21c407294a32ed538658a6910b16124f18020f16bdf7',310472000,NULL,NULL,NULL,'e3735e965492d5fc21e55184d9b4ec9d4ac351cca9ff48996d27615fa4f4eb26','af99413d489407779cb8c095aaf4e761ed62bb029fadfc054cc65c370c04b55d','dcf79ee0ef8ff3cbe1f89f6d863726a72d20223f0900dae1c15a2aa52afdaa19');
INSERT INTO blocks VALUES(310473,'33994c8f6d06134f886b47e14cb4b5af8fc0fd66e6bd60b3a71986622483e095',310473000,NULL,NULL,NULL,'91681ecc240321d9a993d1ef2fe96683c2a2b422a386d8d6d7bee097586dda1f','f446a3d7221abbfa8c497230e61bdd1e94117500a77159599923bed6dd46ea36','b555e7ba1321297d7e6a8f90bb534223c4a73f25fadbdb19befcec4e9be54c5e');
INSERT INTO blocks VALUES(310474,'312ee99e9526e9c240d76e3c3d1fe4c0a21f58156a15f2789605b3e7f7794a09',310474000,NULL,NULL,NULL,'d1b1617cbefa77058a54724b31f562659539d2b090e8413d223114ba39d86baf','a60beb3361b591a62a6ccefa4affb93fe6b704b7bb29e8ee3484feff5f263ed7','336ab99edc0e1db03578718de276f0600ac10fe6e07b0d96bcda1e1678e9cc3c');
INSERT INTO blocks VALUES(310475,'bb9289bcd79075962117aef1161b333dbc403efebd593d93fc315146a2f040eb',310475000,NULL,NULL,NULL,'a69a43e1c10f43aa5c99786975f22d0ffeb0dd887b3797b60c9bb46af335e4a0','10fcf0c999d3ac9350d890b532e2521e90879dcf5c10c7be8b816e93776a36ca','277591962b40f6cc2aae2af940a1c46464084a6c02998355b58c8a72b468b2c2');
INSERT INTO blocks VALUES(310476,'3712e1ebd195749e0dc92f32f7f451dd76f499bf16d709462309ce358a9370d0',310476000,NULL,NULL,NULL,'48e08da9422f219e0de9aa8f51429b7cbc201d2688cd10496d5ca6f72bde0cdf','44a6dda3932f9f189f2613b9487df9a6ed3d607370aa46bc984c2cc7a5f2e2ae','c020766d1174d4fbdf77e8a2fb1116c4c34fdb20a25f2c3a9f50828e63e45ff9');
INSERT INTO blocks VALUES(310477,'7381973c554ac2bbdc849e8ea8c4a0ecbb46e7967d322446d0d83c3f9deab918',310477000,NULL,NULL,NULL,'ce5de32a36f77790f78d61db909f9c3f1a89fa4c2570ba581ebf5cf34d257078','75f63e1e645bdd81e930d59db7b2228ecbb3b94b5531f92ef012a0a6f2d99d34','3c2e057f08aa2696e263a54cc1284128635ac8b3924b1e66a1a1c0cfeaff389f');
INSERT INTO blocks VALUES(310478,'c09ee871af7f2a611d43e6130aed171e301c23c5d1a29d183d40bf15898b4fa0',310478000,NULL,NULL,NULL,'301d513916767fb41f6db7c4e4cc5076524c0380f223299abcf1d18c852efd2b','18423aca513b97c30c0188d51b5c09ebaebefce452e840d64ef9200b0387a66c','68763ea638bf02527367ca486a640c167284aec53fe7f9691eb595838a0ec7ac');
INSERT INTO blocks VALUES(310479,'f3d691ce35f62df56d142160b6e2cdcba19d4995c01f802da6ce30bfe8d30030',310479000,NULL,NULL,NULL,'a2b9af196c911d46976055777ae44d5bea2a2d5880e0857e4b269fdb080aa145','29bf6714fe1616b1d8902abac66bc8939b595e2b6ad3b32b5a12c21131717c38','ab90b3f3ad8fb36446307a3dd3d8b8d95ea91bbdc3179ec3dafe44917e9aa62f');
INSERT INTO blocks VALUES(310480,'2694e89a62b3abd03a38dfd318c05eb5871f1be00a6e1bf06826fd54d142e681',310480000,NULL,NULL,NULL,'2d7dcddce93ae6719c07997988ff3b6b3accae9d2a39af2f7df7dd131c0719cb','aa2c399f837eedb4db8a475bb5e14765762ff8b3f8cf305e7c94268971f5cbd6','3066c017aa446f5b51bddd48ad8c9f4e6d7bebedeb0241f1953579a97155e49c');
INSERT INTO blocks VALUES(310481,'db37d8f98630ebc61767736ae2c523e4e930095bf54259c01de4d36fd60b6f4a',310481000,NULL,NULL,NULL,'6b1d597125249716a6a95d79ad3c3a47ac85cf2b1a383bb18527ea88d2dd3f20','bdf0de8e03b2f32e8c5900cb445a0ffb90d5dd79192a5c79fdb1cb943f433da4','2a70bab9624b08f06df324ab4e955f8d4ab8175a96a4ad63581d2d516d210312');
INSERT INTO blocks VALUES(310482,'2e27db87dfb6439c006637734e876cc662d1ca74c717756f90f0e535df0787d6',310482000,NULL,NULL,NULL,'13af0448767c1433d97b16201979cc535d99c419506424d2adcba2655ae767b3','30f29169aed8bcfd9cceb1a07899c1483ceb2bfd8d5b506d4f68da4ae475036d','9cbf8f78d68d83998b9061c7e0c0da3cc70d9ba6f9a6612e658815cf7e660200');
INSERT INTO blocks VALUES(310483,'013bac61f8e33c8d8d0f60f5e6a4ec3de9b16696703dea9802f64a258601c460',310483000,NULL,NULL,NULL,'504c854523a9f46bb764d835a7c99fedbfd2d61c877942df2de63d952fcea8cd','30a61999d757f6ed2fe3b97d732a69b9804387519809506915b897818a7adc3f','21fc00123673dd31e2837f72eb1f38d34f53c933ac8e924cf68a1ee27847fe59');
INSERT INTO blocks VALUES(310484,'7cac2b3630c31b592fa0497792bed58d3c41120c009471c348b16b5578b3aa2b',310484000,NULL,NULL,NULL,'6e078db0beb6e6e299e8c4c3a8281545f6a9bb67c9b4eb4331afdb2e08ddc8ef','09f07b28653ed128c8f677924c38590126911272fe09558e9ab73f20e6775586','986ce0f76371f3cae0034f13acb011e4f7f26fbfa1a9b1436cad7238e93e34e7');
INSERT INTO blocks VALUES(310485,'eab5febc9668cd438178496417b22da5f77ceaed5bb6e01fc0f04bef1f5b4478',310485000,NULL,NULL,NULL,'876f3856e1e5deff81d6382934e54d12ad7b50f67c1ad4c9b7788cddb2319f10','b3e3d29bcc94a72f4d068e1d2be944955d8a072d8f52552bdf5fdd7c8815f6b1','9bffc117439a093188daff657334aabb64bfb3e2adbbeee11e10f19fe4023668');
INSERT INTO blocks VALUES(310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,NULL,NULL,NULL,'b997b5ade6db680b9bf79eefced8716469ac7747172e8d9d49fb60b461eff52f','d15b34e406f8c0ca37ffb85e47557491e50b1e0e3454a5ce489cd8c37e2837a6','1f20064b04b2b9346bfc2c00bf991b37e97cd475d0515474a6da6d1ef6aee13a');
INSERT INTO blocks VALUES(310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,NULL,NULL,NULL,'7d038612f6b37723f4bfcd693cb1030645ddd871a16247ac2e09767ad6947003','3b213de0406ab78e76ee2c0a0b04c5cdcabe458850db8b35197b3e95a9bdc7ca','6f407dab77e0339517bccba51f6f65ba4f47b8ce81244c5ca4a20a0c387ba9a9');
INSERT INTO blocks VALUES(310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,NULL,NULL,NULL,'9133f0077a7151dc853945da334875f2edf7767b7022770d4c60f8c9ef0bd695','bb33f153dc0d0f44b7dc4d2dda056a981a92ebd165781615f4ad1df7f488a8c5','a97c07095e7e61f3d23fb90676bf86d60092b0bf2663ee0cb6bd731c45799021');
INSERT INTO blocks VALUES(310489,'2efdb36f986b3e3ccc6cc9b0c1c3cdcb07429fb43cbc0cc3b6c87d1b33f258b6',310489000,NULL,NULL,NULL,'c9c9d6b4236dc67dc83b142e5e261913a2fe7c4823b12a39f33fa690b24e1ef0','a6284d5312c579bbf6e6116e9e1679726f53285387880f2613283d9a9f43cf0b','8b219976db5f5bb8cfea4810d064295f4b52996e359d6897f2c452365ac7c561');
INSERT INTO blocks VALUES(310490,'e2cb04b8a7368c95359c9d5ff33e64209200fb606de0d64b7c0f67bb1cb8d87c',310490000,NULL,NULL,NULL,'78919c36fc4c647dafc059a4c2f3703bd31d1f94fa8e1bb41b8a18e799fc3ecf','99e70dce16c67594e9316526db421368e97e05384a43cd512000886d381d9f05','bf6298c7a4322458d87e0df5acb88b16e96771c9a0511ec2a1645cd27adf55d1');
INSERT INTO blocks VALUES(310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,NULL,NULL,NULL,'4b82fbc8d11438acd725688dc59a27bb63980ced34932abc490b1999d5f05159','d90c6b25feeb6d09b70d798de987e374709cdfb4cc897a9c75d7e03291df8d42','5430d10e783ffe0643b2e1bfea31ab3222b0ed7c828f7fa93562434e3a580377');
INSERT INTO blocks VALUES(310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,NULL,NULL,NULL,'6a70190778a623c7d9aba859401e0b69b83c72cc2053ff66269a8a035a7b77e7','38235ac6960412bdc9149a49f519cf92d35e7191a4727f36e2ae255ee0cee2ba','10aa01cfc38be32312a6a4de3bf683963da8be839808caa927d12119c94fffee');
INSERT INTO blocks VALUES(310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,NULL,NULL,NULL,'1d2d984d29ff9edb5f08ecd51f6924dcc4679a3e8a2e8abdc7f201f18b98a7e8','267ca5e9ec9ec6137ddaf48a315f2147173c758c1c3f8c10c9408a9e1593b40d','855376003af5901c96877a49ab38d86fcc8e0815ccc2b7ed1703e701c8a04581');
INSERT INTO blocks VALUES(310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,NULL,NULL,NULL,'ca781ade3b1e3c6e1d5a36c409ca1f8325df929de637e7f0955300ddcf49f21f','70c5c699fc432c480e91358be116c6c2c2253f49da54c598264fe28ba45b8a94','2a5d7d276462c629e07228471966aa88818251ffe3c00ce64ce7ec72d7c57870');
INSERT INTO blocks VALUES(310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,NULL,NULL,NULL,'2b4535c4bdcf9bb502fb96cd2b2e6793e5beff2bcb40599843f84bdfa291e973','76e2e1e67dc7db37f5d9a43c35b4e38b7d47104ecc456ece5bb03f5f8e39cf83','dbb2af42cffc9d84f5e8c85a7c5d551aa2bc19836a7abbf662c5772ad3f9a0df');
INSERT INTO blocks VALUES(310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,NULL,NULL,NULL,'031c7a47106a1358af4d46312d18906bf7183bb72a0fa7d3292d4f123a1c3135','ed9838dbb0e9fb1d86ebe79d59376c6c73ece72d1498a1f530f66531654d556a','2ea41cc7d30258960d7b07367a6c0767028341aa45c536e63d7481bb5aaf3b51');
INSERT INTO blocks VALUES(310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,NULL,NULL,65398,'5002c1eeb94b674bb85460c4ec773553dc674724fa9f47fdf33587b02afb226c','ce6913e963958986e1486f6b45b55e994728536aa429b89f5c77f47f47301aac','167cd99e75cb854c4fe8624dfda24d8cdf09d7683a8c44ceca52b0b0dbf3ec55');
INSERT INTO blocks VALUES(310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,NULL,NULL,NULL,'637215270b20611f8408a2b56b253b13b59efb57b31bf0437769969912cd7695','fa96971525bd0057318d85d9c7aadf8a17e877f24223badc7f343afbecb77ba8','d5734c0a5724ad34baf679918e2bfabf4db28685b340508756af0c17702899de');
INSERT INTO blocks VALUES(310499,'1950e1a4d7fc820ed9603f6df6819c3c953c277c726340dec2a4253e261a1764',310499000,NULL,NULL,NULL,'ff20db6f28481d8d2f8bb390144e0ef7b617b05bf7eec43263226a809158f3f5','923c0709a24eab1ec3cc5a4be57be259297b1a68f7c568c6a938839e9764074b','c1a92dfd7738864bada51e01d51f97f541cb38bb723d94290d82664cf0b40f0b');
INSERT INTO blocks VALUES(310500,'54aeaf47d5387964e2d51617bf3af50520a0449410e0d096cf8c2aa9dad5550b',310500000,NULL,NULL,NULL,'3e4a48f0fc339a4f598b248722475c95e4e8aeef929fe0c4714a5a072c7ac45f','380251e6c99e8e8ed1da784ccbb915870c179339eaf0a3bfb722401d8d600f3a','8aabaf8ff0f6b0578c9552c69db0620aaede36dc7737d696a43d695e0804403a');
INSERT INTO blocks VALUES(310501,'9d9019d15a1d878f2c39c7e3de4340a043a4a31aebb298acdf8e913284ae26ba',310501000,NULL,NULL,NULL,NULL,NULL,NULL);
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
INSERT INTO burns VALUES(112,'710cab2ca813d8f2a6e4ba9f05eee67b1130777d3c67d42cc5a6b5d94a4b709e',310111,'2NErxwfmefM47yQ7Mk4y7WCqmvNfW2bhzic',31000000,46499535967,'valid');
INSERT INTO burns VALUES(113,'470ab0d2b7fb45cbdbe4fbba6d76325b1b1f5525f4f6be7dc995dd93b0999caf',310112,'2MxHK9KY4zhTPoupLCyXgPJoN2GtCsFr7gK',31000000,46499531786,'valid');
INSERT INTO burns VALUES(114,'5cea665ad64adf6b81a3b67bccd8720f1ecc8641418314449961fe856b195e5b',310113,'2MuWaw3xAczwSL6DKY77kEP7JgAWiQdqFSy',31000000,46499527606,'valid');
INSERT INTO burns VALUES(115,'0785e6e3dd8ec67452315d7c6bed311effc9ec9ee4eb638d88c425df72da794b',310114,'2MtBCufaZs6NDoDfLfR5MGG3KtDzUG2Pmy8',31000000,46499523425,'valid');
INSERT INTO burns VALUES(116,'ab0c8f04a595637650a80ee32e2f1ef4c311871278b6b66cc14ca7da9606dc45',310115,'2N3ACzPYimgijjPWhowmwPWzzY7XtvqbtRq',31000000,46499519245,'valid');
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
                      tx_index INTEGER,
                      tx_hash TEXT,
                      block_index INTEGER,
                      source TEXT,
                      code BLOB,
                      nonce INTEGER,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
INSERT INTO contracts VALUES('tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt',498,'f7708dbe7c0047b1465d79ac630652e46ab325a90713cef731ab23e63afeba8d',310497,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',X'606060405260E060020A6000350463CC572CF98114601A575B005B6024356004350A6060908152602090F3',0);
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
INSERT INTO credits VALUES(310111,'2NErxwfmefM47yQ7Mk4y7WCqmvNfW2bhzic','XCP',46499535967,'burn','710cab2ca813d8f2a6e4ba9f05eee67b1130777d3c67d42cc5a6b5d94a4b709e');
INSERT INTO credits VALUES(310112,'2MxHK9KY4zhTPoupLCyXgPJoN2GtCsFr7gK','XCP',46499531786,'burn','470ab0d2b7fb45cbdbe4fbba6d76325b1b1f5525f4f6be7dc995dd93b0999caf');
INSERT INTO credits VALUES(310113,'2MuWaw3xAczwSL6DKY77kEP7JgAWiQdqFSy','XCP',46499527606,'burn','5cea665ad64adf6b81a3b67bccd8720f1ecc8641418314449961fe856b195e5b');
INSERT INTO credits VALUES(310114,'2MtBCufaZs6NDoDfLfR5MGG3KtDzUG2Pmy8','XCP',46499523425,'burn','0785e6e3dd8ec67452315d7c6bed311effc9ec9ee4eb638d88c425df72da794b');
INSERT INTO credits VALUES(310115,'2N3ACzPYimgijjPWhowmwPWzzY7XtvqbtRq','XCP',46499519245,'burn','ab0c8f04a595637650a80ee32e2f1ef4c311871278b6b66cc14ca7da9606dc45');
INSERT INTO credits VALUES(310493,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',92995878046,'burn','0d88550e8361676614215372d3482d7749ddfe81d12fff58ce80a598dd0d368d');
INSERT INTO credits VALUES(310494,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','DIVIDEND',100,'issuance','89f7e46840b55a8134ca6950f804862a5a89fbc07dfa223300a07daeaad9719f');
INSERT INTO credits VALUES(310495,'mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','DIVIDEND',10,'send','3c3e750a0a8f27fba67480957f85907f22a52d45385132d73d7fdc1c8e38107d');
INSERT INTO credits VALUES(310496,'mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','XCP',92945878046,'send','478048dcdaca3e8010fc50a75511f6ed8fc1a770a4fab5c339a1c15c3633971f');
INSERT INTO credits VALUES(310497,'tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt','XCP',0,'transfer value','f7708dbe7c0047b1465d79ac630652e46ab325a90713cef731ab23e63afeba8d');
INSERT INTO credits VALUES(310497,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',934602,'startgas','f7708dbe7c0047b1465d79ac630652e46ab325a90713cef731ab23e63afeba8d');
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
INSERT INTO debits VALUES(310497,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',1000000,'startgas','f7708dbe7c0047b1465d79ac630652e46ab325a90713cef731ab23e63afeba8d');
INSERT INTO debits VALUES(310497,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'transfer value','f7708dbe7c0047b1465d79ac630652e46ab325a90713cef731ab23e63afeba8d');
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
INSERT INTO executions VALUES(498,'f7708dbe7c0047b1465d79ac630652e46ab325a90713cef731ab23e63afeba8d',310497,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,1,1000000,65398,934602,0,X'6060604052602B8060106000396000F3606060405260E060020A6000350463CC572CF98114601A575B005B6024356004350A6060908152602090F3','tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt','valid');
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
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
INSERT INTO issuances VALUES(2,'a68768e0a44a119cb48124b3f11f2a03e2f738a86a539aa9beb93596092d1edf',310001,'DIVISIBLE',100000000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Divisible asset',50000000,0,'valid');
INSERT INTO issuances VALUES(3,'25e8108a67011db1a409e52fc3d73511d08a5078ad73e06b7dfefb90a8b6a70f',310002,'NODIVISIBLE',1000,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'No divisible asset',50000000,0,'valid');
INSERT INTO issuances VALUES(4,'227d51e90a5921551dff2554d81439718718afbd0b9a7efd2d8ec713497bdf3d',310003,'CALLABLE',1000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Callable asset',50000000,0,'valid');
INSERT INTO issuances VALUES(5,'b5c6258164bca06c567dfe0b26b156812c34819c6ff538f9c1ee01bd071a3203',310004,'LOCKED',1000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Locked asset',50000000,0,'valid');
INSERT INTO issuances VALUES(6,'84e607982e4aae1edbc0f1a02171e06ba335e30817779425ce570e26af2b5316',310005,'LOCKED',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Locked asset',0,1,'valid');
INSERT INTO issuances VALUES(17,'f6dbe255b8028a2917fff031b6d203d0822e71583432c6ba1509713db8f6dee6',310016,'MAXI',9223372036854775807,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Maximum quantity',50000000,0,'valid');
INSERT INTO issuances VALUES(108,'89ed806602d4e0c260a88c76b1bfcc0c17c993b04678da155369525f854c9105',310107,'PAYTOSCRIPT',1000,0,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',0,0,0,0.0,'PSH issued asset',50000000,0,'valid');
INSERT INTO issuances VALUES(495,'89f7e46840b55a8134ca6950f804862a5a89fbc07dfa223300a07daeaad9719f',310494,'DIVIDEND',100,1,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',0,0,0,0.0,'Test dividend',50000000,0,'valid');
-- Triggers and indices on  issuances
CREATE TRIGGER _issuances_delete BEFORE DELETE ON issuances BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO issuances(rowid,tx_index,tx_hash,block_index,asset,quantity,divisible,source,issuer,transfer,callable,call_date,call_price,description,fee_paid,locked,status) VALUES('||old.rowid||','||quote(old.tx_index)||','||quote(old.tx_hash)||','||quote(old.block_index)||','||quote(old.asset)||','||quote(old.quantity)||','||quote(old.divisible)||','||quote(old.source)||','||quote(old.issuer)||','||quote(old.transfer)||','||quote(old.callable)||','||quote(old.call_date)||','||quote(old.call_price)||','||quote(old.description)||','||quote(old.fee_paid)||','||quote(old.locked)||','||quote(old.status)||')');
                            END;
CREATE TRIGGER _issuances_insert AFTER INSERT ON issuances BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM issuances WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _issuances_update AFTER UPDATE ON issuances BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE issuances SET tx_index='||quote(old.tx_index)||',tx_hash='||quote(old.tx_hash)||',block_index='||quote(old.block_index)||',asset='||quote(old.asset)||',quantity='||quote(old.quantity)||',divisible='||quote(old.divisible)||',source='||quote(old.source)||',issuer='||quote(old.issuer)||',transfer='||quote(old.transfer)||',callable='||quote(old.callable)||',call_date='||quote(old.call_date)||',call_price='||quote(old.call_price)||',description='||quote(old.description)||',fee_paid='||quote(old.fee_paid)||',locked='||quote(old.locked)||',status='||quote(old.status)||' WHERE rowid='||old.rowid);
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
INSERT INTO messages VALUES(3,310001,'insert','issuances','{"asset": "DIVISIBLE", "block_index": 310001, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Divisible asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "a68768e0a44a119cb48124b3f11f2a03e2f738a86a539aa9beb93596092d1edf", "tx_index": 2}',0);
INSERT INTO messages VALUES(4,310001,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 310001, "event": "a68768e0a44a119cb48124b3f11f2a03e2f738a86a539aa9beb93596092d1edf", "quantity": 100000000000}',0);
INSERT INTO messages VALUES(5,310002,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310002, "event": "25e8108a67011db1a409e52fc3d73511d08a5078ad73e06b7dfefb90a8b6a70f", "quantity": 50000000}',0);
INSERT INTO messages VALUES(6,310002,'insert','issuances','{"asset": "NODIVISIBLE", "block_index": 310002, "call_date": 0, "call_price": 0.0, "callable": false, "description": "No divisible asset", "divisible": false, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "25e8108a67011db1a409e52fc3d73511d08a5078ad73e06b7dfefb90a8b6a70f", "tx_index": 3}',0);
INSERT INTO messages VALUES(7,310002,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "NODIVISIBLE", "block_index": 310002, "event": "25e8108a67011db1a409e52fc3d73511d08a5078ad73e06b7dfefb90a8b6a70f", "quantity": 1000}',0);
INSERT INTO messages VALUES(8,310003,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310003, "event": "227d51e90a5921551dff2554d81439718718afbd0b9a7efd2d8ec713497bdf3d", "quantity": 50000000}',0);
INSERT INTO messages VALUES(9,310003,'insert','issuances','{"asset": "CALLABLE", "block_index": 310003, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Callable asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "227d51e90a5921551dff2554d81439718718afbd0b9a7efd2d8ec713497bdf3d", "tx_index": 4}',0);
INSERT INTO messages VALUES(10,310003,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "CALLABLE", "block_index": 310003, "event": "227d51e90a5921551dff2554d81439718718afbd0b9a7efd2d8ec713497bdf3d", "quantity": 1000}',0);
INSERT INTO messages VALUES(11,310004,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310004, "event": "b5c6258164bca06c567dfe0b26b156812c34819c6ff538f9c1ee01bd071a3203", "quantity": 50000000}',0);
INSERT INTO messages VALUES(12,310004,'insert','issuances','{"asset": "LOCKED", "block_index": 310004, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Locked asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "b5c6258164bca06c567dfe0b26b156812c34819c6ff538f9c1ee01bd071a3203", "tx_index": 5}',0);
INSERT INTO messages VALUES(13,310004,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "LOCKED", "block_index": 310004, "event": "b5c6258164bca06c567dfe0b26b156812c34819c6ff538f9c1ee01bd071a3203", "quantity": 1000}',0);
INSERT INTO messages VALUES(14,310005,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310005, "event": "84e607982e4aae1edbc0f1a02171e06ba335e30817779425ce570e26af2b5316", "quantity": 0}',0);
INSERT INTO messages VALUES(15,310005,'insert','issuances','{"asset": "LOCKED", "block_index": 310005, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Locked asset", "divisible": true, "fee_paid": 0, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": true, "quantity": 0, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "84e607982e4aae1edbc0f1a02171e06ba335e30817779425ce570e26af2b5316", "tx_index": 6}',0);
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
INSERT INTO messages VALUES(42,310016,'insert','issuances','{"asset": "MAXI", "block_index": 310016, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Maximum quantity", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 9223372036854775807, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "f6dbe255b8028a2917fff031b6d203d0822e71583432c6ba1509713db8f6dee6", "tx_index": 17}',0);
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
INSERT INTO messages VALUES(72,310107,'insert','issuances','{"asset": "PAYTOSCRIPT", "block_index": 310107, "call_date": 0, "call_price": 0.0, "callable": false, "description": "PSH issued asset", "divisible": false, "fee_paid": 50000000, "issuer": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "locked": false, "quantity": 1000, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "valid", "transfer": false, "tx_hash": "89ed806602d4e0c260a88c76b1bfcc0c17c993b04678da155369525f854c9105", "tx_index": 108}',0);
INSERT INTO messages VALUES(73,310107,'insert','credits','{"action": "issuance", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "PAYTOSCRIPT", "block_index": 310107, "event": "89ed806602d4e0c260a88c76b1bfcc0c17c993b04678da155369525f854c9105", "quantity": 1000}',0);
INSERT INTO messages VALUES(74,310108,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 310108, "event": "5776bcda35a58d001e71552bc6fd2de3764495ce50f16b3b806a986935ca5520", "quantity": 100000000}',0);
INSERT INTO messages VALUES(75,310108,'insert','credits','{"action": "send", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "DIVISIBLE", "block_index": 310108, "event": "5776bcda35a58d001e71552bc6fd2de3764495ce50f16b3b806a986935ca5520", "quantity": 100000000}',0);
INSERT INTO messages VALUES(76,310108,'insert','sends','{"asset": "DIVISIBLE", "block_index": 310108, "destination": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "5776bcda35a58d001e71552bc6fd2de3764495ce50f16b3b806a986935ca5520", "tx_index": 109}',0);
INSERT INTO messages VALUES(77,310109,'insert','broadcasts','{"block_index": 310109, "fee_fraction_int": 5000000, "locked": false, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "valid", "text": "Unit Test", "timestamp": 1388000002, "tx_hash": "ba3fe575883978cb0b79969b2f3c5268ef7b2fc7a90f6461d3ed33fbc30c90b3", "tx_index": 110, "value": 1.0}',0);
INSERT INTO messages VALUES(78,310110,'insert','debits','{"action": "bet", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "XCP", "block_index": 310110, "event": "0c690d46bef903922354520c8c8626ab5bfd45da1ca211d65f16aeef9b5f3300", "quantity": 10}',0);
INSERT INTO messages VALUES(79,310110,'insert','bets','{"bet_type": 3, "block_index": 310110, "counterwager_quantity": 10, "counterwager_remaining": 10, "deadline": 1388000200, "expiration": 1000, "expire_index": 311110, "fee_fraction_int": 5000000.0, "feed_address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "leverage": 5040, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "open", "target_value": 0.0, "tx_hash": "0c690d46bef903922354520c8c8626ab5bfd45da1ca211d65f16aeef9b5f3300", "tx_index": 111, "wager_quantity": 10, "wager_remaining": 10}',0);
INSERT INTO messages VALUES(80,310111,'insert','credits','{"action": "burn", "address": "2NErxwfmefM47yQ7Mk4y7WCqmvNfW2bhzic", "asset": "XCP", "block_index": 310111, "event": "710cab2ca813d8f2a6e4ba9f05eee67b1130777d3c67d42cc5a6b5d94a4b709e", "quantity": 46499535967}',0);
INSERT INTO messages VALUES(81,310111,'insert','burns','{"block_index": 310111, "burned": 31000000, "earned": 46499535967, "source": "2NErxwfmefM47yQ7Mk4y7WCqmvNfW2bhzic", "status": "valid", "tx_hash": "710cab2ca813d8f2a6e4ba9f05eee67b1130777d3c67d42cc5a6b5d94a4b709e", "tx_index": 112}',0);
INSERT INTO messages VALUES(82,310112,'insert','credits','{"action": "burn", "address": "2MxHK9KY4zhTPoupLCyXgPJoN2GtCsFr7gK", "asset": "XCP", "block_index": 310112, "event": "470ab0d2b7fb45cbdbe4fbba6d76325b1b1f5525f4f6be7dc995dd93b0999caf", "quantity": 46499531786}',0);
INSERT INTO messages VALUES(83,310112,'insert','burns','{"block_index": 310112, "burned": 31000000, "earned": 46499531786, "source": "2MxHK9KY4zhTPoupLCyXgPJoN2GtCsFr7gK", "status": "valid", "tx_hash": "470ab0d2b7fb45cbdbe4fbba6d76325b1b1f5525f4f6be7dc995dd93b0999caf", "tx_index": 113}',0);
INSERT INTO messages VALUES(84,310113,'insert','credits','{"action": "burn", "address": "2MuWaw3xAczwSL6DKY77kEP7JgAWiQdqFSy", "asset": "XCP", "block_index": 310113, "event": "5cea665ad64adf6b81a3b67bccd8720f1ecc8641418314449961fe856b195e5b", "quantity": 46499527606}',0);
INSERT INTO messages VALUES(85,310113,'insert','burns','{"block_index": 310113, "burned": 31000000, "earned": 46499527606, "source": "2MuWaw3xAczwSL6DKY77kEP7JgAWiQdqFSy", "status": "valid", "tx_hash": "5cea665ad64adf6b81a3b67bccd8720f1ecc8641418314449961fe856b195e5b", "tx_index": 114}',0);
INSERT INTO messages VALUES(86,310114,'insert','credits','{"action": "burn", "address": "2MtBCufaZs6NDoDfLfR5MGG3KtDzUG2Pmy8", "asset": "XCP", "block_index": 310114, "event": "0785e6e3dd8ec67452315d7c6bed311effc9ec9ee4eb638d88c425df72da794b", "quantity": 46499523425}',0);
INSERT INTO messages VALUES(87,310114,'insert','burns','{"block_index": 310114, "burned": 31000000, "earned": 46499523425, "source": "2MtBCufaZs6NDoDfLfR5MGG3KtDzUG2Pmy8", "status": "valid", "tx_hash": "0785e6e3dd8ec67452315d7c6bed311effc9ec9ee4eb638d88c425df72da794b", "tx_index": 115}',0);
INSERT INTO messages VALUES(88,310115,'insert','credits','{"action": "burn", "address": "2N3ACzPYimgijjPWhowmwPWzzY7XtvqbtRq", "asset": "XCP", "block_index": 310115, "event": "ab0c8f04a595637650a80ee32e2f1ef4c311871278b6b66cc14ca7da9606dc45", "quantity": 46499519245}',0);
INSERT INTO messages VALUES(89,310115,'insert','burns','{"block_index": 310115, "burned": 31000000, "earned": 46499519245, "source": "2N3ACzPYimgijjPWhowmwPWzzY7XtvqbtRq", "status": "valid", "tx_hash": "ab0c8f04a595637650a80ee32e2f1ef4c311871278b6b66cc14ca7da9606dc45", "tx_index": 116}',0);
INSERT INTO messages VALUES(90,310486,'insert','broadcasts','{"block_index": 310486, "fee_fraction_int": 5000000, "locked": false, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "81a5d20db79a4b620221ba646fec2699b4e4d1c854bb4022b0550bd7d274a5b8", "tx_index": 487, "value": 1.0}',0);
INSERT INTO messages VALUES(91,310487,'insert','debits','{"action": "bet", "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "asset": "XCP", "block_index": 310487, "event": "c9cfc39f98307a845d1d27d4a9ad66b19e0c38f59be14ed0c4b9d4ec15cb0940", "quantity": 9}',0);
INSERT INTO messages VALUES(92,310487,'insert','bets','{"bet_type": 1, "block_index": 310487, "counterwager_quantity": 9, "counterwager_remaining": 9, "deadline": 1388000001, "expiration": 100, "expire_index": 310587, "fee_fraction_int": 5000000.0, "feed_address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "leverage": 5040, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "open", "target_value": 0.0, "tx_hash": "c9cfc39f98307a845d1d27d4a9ad66b19e0c38f59be14ed0c4b9d4ec15cb0940", "tx_index": 488, "wager_quantity": 9, "wager_remaining": 9}',0);
INSERT INTO messages VALUES(93,310488,'insert','broadcasts','{"block_index": 310488, "fee_fraction_int": null, "locked": true, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": null, "timestamp": 0, "tx_hash": "b61f2f7e43e6696ca5b804e9c21e61616257b561e69d3cc6cf45af1e1cac3deb", "tx_index": 489, "value": null}',0);
INSERT INTO messages VALUES(94,310491,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310491, "event": "301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7", "quantity": 100000000}',0);
INSERT INTO messages VALUES(95,310491,'insert','orders','{"block_index": 310491, "expiration": 2000, "expire_index": 312491, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 800000, "get_remaining": 800000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7", "tx_index": 492}',0);
INSERT INTO messages VALUES(96,310492,'insert','orders','{"block_index": 310492, "expiration": 2000, "expire_index": 312492, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 800000, "give_remaining": 800000, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "tx_hash": "14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0", "tx_index": 493}',0);
INSERT INTO messages VALUES(97,310492,'update','orders','{"fee_provided_remaining": 6800, "fee_required_remaining": 892800, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7"}',0);
INSERT INTO messages VALUES(98,310492,'update','orders','{"fee_provided_remaining": 992800, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0"}',0);
INSERT INTO messages VALUES(99,310492,'insert','order_matches','{"backward_asset": "BTC", "backward_quantity": 800000, "block_index": 310492, "fee_paid": 7200, "forward_asset": "XCP", "forward_quantity": 100000000, "id": "301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7_14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0", "match_expire_index": 310512, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 310491, "tx0_expiration": 2000, "tx0_hash": "301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7", "tx0_index": 492, "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_block_index": 310492, "tx1_expiration": 2000, "tx1_hash": "14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0", "tx1_index": 493}',0);
INSERT INTO messages VALUES(100,310493,'insert','credits','{"action": "burn", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310493, "event": "0d88550e8361676614215372d3482d7749ddfe81d12fff58ce80a598dd0d368d", "quantity": 92995878046}',0);
INSERT INTO messages VALUES(101,310493,'insert','burns','{"block_index": 310493, "burned": 62000000, "earned": 92995878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "0d88550e8361676614215372d3482d7749ddfe81d12fff58ce80a598dd0d368d", "tx_index": 494}',0);
INSERT INTO messages VALUES(102,310494,'insert','debits','{"action": "issuance fee", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310494, "event": "89f7e46840b55a8134ca6950f804862a5a89fbc07dfa223300a07daeaad9719f", "quantity": 50000000}',0);
INSERT INTO messages VALUES(103,310494,'insert','issuances','{"asset": "DIVIDEND", "block_index": 310494, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Test dividend", "divisible": true, "fee_paid": 50000000, "issuer": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "locked": false, "quantity": 100, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "transfer": false, "tx_hash": "89f7e46840b55a8134ca6950f804862a5a89fbc07dfa223300a07daeaad9719f", "tx_index": 495}',0);
INSERT INTO messages VALUES(104,310494,'insert','credits','{"action": "issuance", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310494, "event": "89f7e46840b55a8134ca6950f804862a5a89fbc07dfa223300a07daeaad9719f", "quantity": 100}',0);
INSERT INTO messages VALUES(105,310495,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310495, "event": "3c3e750a0a8f27fba67480957f85907f22a52d45385132d73d7fdc1c8e38107d", "quantity": 10}',0);
INSERT INTO messages VALUES(106,310495,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "DIVIDEND", "block_index": 310495, "event": "3c3e750a0a8f27fba67480957f85907f22a52d45385132d73d7fdc1c8e38107d", "quantity": 10}',0);
INSERT INTO messages VALUES(107,310495,'insert','sends','{"asset": "DIVIDEND", "block_index": 310495, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 10, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "3c3e750a0a8f27fba67480957f85907f22a52d45385132d73d7fdc1c8e38107d", "tx_index": 496}',0);
INSERT INTO messages VALUES(108,310496,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310496, "event": "478048dcdaca3e8010fc50a75511f6ed8fc1a770a4fab5c339a1c15c3633971f", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(109,310496,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "XCP", "block_index": 310496, "event": "478048dcdaca3e8010fc50a75511f6ed8fc1a770a4fab5c339a1c15c3633971f", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(110,310496,'insert','sends','{"asset": "XCP", "block_index": 310496, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 92945878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "478048dcdaca3e8010fc50a75511f6ed8fc1a770a4fab5c339a1c15c3633971f", "tx_index": 497}',0);
INSERT INTO messages VALUES(111,310497,'insert','nonces','{"address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "nonce": 1}',0);
INSERT INTO messages VALUES(112,310497,'insert','debits','{"action": "startgas", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310497, "event": "f7708dbe7c0047b1465d79ac630652e46ab325a90713cef731ab23e63afeba8d", "quantity": 1000000}',0);
INSERT INTO messages VALUES(113,310497,'insert','contracts','{"block_index": 310497, "code": "", "contract_id": "tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt", "nonce": 0, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx_hash": "f7708dbe7c0047b1465d79ac630652e46ab325a90713cef731ab23e63afeba8d", "tx_index": 498}',0);
INSERT INTO messages VALUES(114,310497,'insert','debits','{"action": "transfer value", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310497, "event": "f7708dbe7c0047b1465d79ac630652e46ab325a90713cef731ab23e63afeba8d", "quantity": 0}',0);
INSERT INTO messages VALUES(115,310497,'insert','credits','{"action": "transfer value", "address": "tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt", "asset": "XCP", "block_index": 310497, "event": "f7708dbe7c0047b1465d79ac630652e46ab325a90713cef731ab23e63afeba8d", "quantity": 0}',0);
INSERT INTO messages VALUES(116,310497,'insert','credits','{"action": "startgas", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310497, "event": "f7708dbe7c0047b1465d79ac630652e46ab325a90713cef731ab23e63afeba8d", "quantity": 934602}',0);
INSERT INTO messages VALUES(117,310497,'insert','executions','{"block_index": 310497, "contract_id": null, "gas_cost": 65398, "gas_remained": 934602, "gasprice": 1, "output": "tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt", "payload": "6060604052602b8060106000396000f3606060405260e060020a6000350463cc572cf98114601a575b005b6024356004350a6060908152602090f3", "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "startgas": 1000000, "status": "valid", "tx_hash": "f7708dbe7c0047b1465d79ac630652e46ab325a90713cef731ab23e63afeba8d", "tx_index": 498, "value": 0}',0);
-- Triggers and indices on  messages
CREATE INDEX block_index_message_index_idx ON messages (block_index, message_index);

-- Table  nonces
DROP TABLE IF EXISTS nonces;
CREATE TABLE nonces(
                      address TEXT PRIMARY KEY,
                      nonce INTEGER);
INSERT INTO nonces VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1);
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
                      PRIMARY KEY(contract_id, `key`),
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
INSERT INTO transactions VALUES(112,'710cab2ca813d8f2a6e4ba9f05eee67b1130777d3c67d42cc5a6b5d94a4b709e',310111,'fde71b9756d5ba0b6d8b230ee885af01f9c4461a55dbde8678279166a21b20ae',310111000,'2NErxwfmefM47yQ7Mk4y7WCqmvNfW2bhzic','mvCounterpartyXXXXXXXXXXXXXXW24Hef',31000000,5625,X'',1);
INSERT INTO transactions VALUES(113,'470ab0d2b7fb45cbdbe4fbba6d76325b1b1f5525f4f6be7dc995dd93b0999caf',310112,'5b06f69bfdde1083785cf68ebc2211b464839033c30a099d3227b490bf3ab251',310112000,'2MxHK9KY4zhTPoupLCyXgPJoN2GtCsFr7gK','mvCounterpartyXXXXXXXXXXXXXXW24Hef',31000000,5625,X'',1);
INSERT INTO transactions VALUES(114,'5cea665ad64adf6b81a3b67bccd8720f1ecc8641418314449961fe856b195e5b',310113,'63914cf376d3076b697b9234810dfc084ed5a885d5cd188dd5462560da25d5e7',310113000,'2MuWaw3xAczwSL6DKY77kEP7JgAWiQdqFSy','mvCounterpartyXXXXXXXXXXXXXXW24Hef',31000000,5625,X'',1);
INSERT INTO transactions VALUES(115,'0785e6e3dd8ec67452315d7c6bed311effc9ec9ee4eb638d88c425df72da794b',310114,'24fc2dded4f811eff58b32cda85d90fb5773e81b9267e9a03c359bc730d82283',310114000,'2MtBCufaZs6NDoDfLfR5MGG3KtDzUG2Pmy8','mvCounterpartyXXXXXXXXXXXXXXW24Hef',31000000,5625,X'',1);
INSERT INTO transactions VALUES(116,'ab0c8f04a595637650a80ee32e2f1ef4c311871278b6b66cc14ca7da9606dc45',310115,'a632d67ff5f832fe9c3c675f855f08a4969c6d78c0211e71b2a24fe04be5656a',310115000,'2N3ACzPYimgijjPWhowmwPWzzY7XtvqbtRq','mvCounterpartyXXXXXXXXXXXXXXW24Hef',31000000,5625,X'',1);
INSERT INTO transactions VALUES(487,'81a5d20db79a4b620221ba646fec2699b4e4d1c854bb4022b0550bd7d274a5b8',310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','',0,-99993200,X'0000001E52BB33003FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(488,'c9cfc39f98307a845d1d27d4a9ad66b19e0c38f59be14ed0c4b9d4ec15cb0940',310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',5430,-99992350,X'00000028000152BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(489,'b61f2f7e43e6696ca5b804e9c21e61616257b561e69d3cc6cf45af1e1cac3deb',310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','',0,-99993200,X'0000001E52BB33023FF000000000000000000000046C6F636B',1);
INSERT INTO transactions VALUES(492,'301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7',310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000000010000000005F5E100000000000000000000000000000C350007D000000000000DBBA0',1);
INSERT INTO transactions VALUES(493,'14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0',310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','',0,1000000,X'0000000A000000000000000000000000000C350000000000000000010000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(494,'0d88550e8361676614215372d3482d7749ddfe81d12fff58ce80a598dd0d368d',310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
INSERT INTO transactions VALUES(495,'89f7e46840b55a8134ca6950f804862a5a89fbc07dfa223300a07daeaad9719f',310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','',0,6800,X'00000014000000063E985FFD0000000000000064010000000000000000000D54657374206469766964656E64',1);
INSERT INTO transactions VALUES(496,'3c3e750a0a8f27fba67480957f85907f22a52d45385132d73d7fdc1c8e38107d',310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj',5430,7650,X'00000000000000063E985FFD000000000000000A',1);
INSERT INTO transactions VALUES(497,'478048dcdaca3e8010fc50a75511f6ed8fc1a770a4fab5c339a1c15c3633971f',310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj',5430,7650,X'00000000000000000000000100000015A4018C1E',1);
INSERT INTO transactions VALUES(498,'f7708dbe7c0047b1465d79ac630652e46ab325a90713cef731ab23e63afeba8d',310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,8825,X'00000067000000000000000100000000000F424000000000000000003B6060604052602B8060106000396000F3606060405260E060020A6000350463CC572CF98114601A575B005B6024356004350A6060908152602090F3',1);
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
INSERT INTO undolog VALUES(146,'DELETE FROM broadcasts WHERE rowid=487');
INSERT INTO undolog VALUES(147,'UPDATE balances SET address=''myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM'',asset=''XCP'',quantity=92999138821 WHERE rowid=13');
INSERT INTO undolog VALUES(148,'DELETE FROM debits WHERE rowid=22');
INSERT INTO undolog VALUES(149,'DELETE FROM bets WHERE rowid=5');
INSERT INTO undolog VALUES(150,'DELETE FROM broadcasts WHERE rowid=489');
INSERT INTO undolog VALUES(151,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92050000000 WHERE rowid=1');
INSERT INTO undolog VALUES(152,'DELETE FROM debits WHERE rowid=23');
INSERT INTO undolog VALUES(153,'DELETE FROM orders WHERE rowid=5');
INSERT INTO undolog VALUES(154,'DELETE FROM orders WHERE rowid=6');
INSERT INTO undolog VALUES(155,'UPDATE orders SET tx_index=492,tx_hash=''301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7'',block_index=310491,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''XCP'',give_quantity=100000000,give_remaining=100000000,get_asset=''BTC'',get_quantity=800000,get_remaining=800000,expiration=2000,expire_index=312491,fee_required=900000,fee_required_remaining=900000,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(156,'UPDATE orders SET tx_index=493,tx_hash=''14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0'',block_index=310492,source=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',give_asset=''BTC'',give_quantity=800000,give_remaining=800000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=2000,expire_index=312492,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=6');
INSERT INTO undolog VALUES(157,'DELETE FROM order_matches WHERE rowid=1');
INSERT INTO undolog VALUES(158,'DELETE FROM balances WHERE rowid=24');
INSERT INTO undolog VALUES(159,'DELETE FROM credits WHERE rowid=29');
INSERT INTO undolog VALUES(160,'DELETE FROM burns WHERE rowid=494');
INSERT INTO undolog VALUES(161,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''XCP'',quantity=92995878046 WHERE rowid=24');
INSERT INTO undolog VALUES(162,'DELETE FROM debits WHERE rowid=24');
INSERT INTO undolog VALUES(163,'DELETE FROM assets WHERE rowid=9');
INSERT INTO undolog VALUES(164,'DELETE FROM issuances WHERE rowid=495');
INSERT INTO undolog VALUES(165,'DELETE FROM balances WHERE rowid=25');
INSERT INTO undolog VALUES(166,'DELETE FROM credits WHERE rowid=30');
INSERT INTO undolog VALUES(167,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''DIVIDEND'',quantity=100 WHERE rowid=25');
INSERT INTO undolog VALUES(168,'DELETE FROM debits WHERE rowid=25');
INSERT INTO undolog VALUES(169,'DELETE FROM balances WHERE rowid=26');
INSERT INTO undolog VALUES(170,'DELETE FROM credits WHERE rowid=31');
INSERT INTO undolog VALUES(171,'DELETE FROM sends WHERE rowid=496');
INSERT INTO undolog VALUES(172,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''XCP'',quantity=92945878046 WHERE rowid=24');
INSERT INTO undolog VALUES(173,'DELETE FROM debits WHERE rowid=26');
INSERT INTO undolog VALUES(174,'DELETE FROM balances WHERE rowid=27');
INSERT INTO undolog VALUES(175,'DELETE FROM credits WHERE rowid=32');
INSERT INTO undolog VALUES(176,'DELETE FROM sends WHERE rowid=497');
INSERT INTO undolog VALUES(177,'DELETE FROM nonces WHERE rowid=1');
INSERT INTO undolog VALUES(178,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91950000000 WHERE rowid=1');
INSERT INTO undolog VALUES(179,'DELETE FROM debits WHERE rowid=27');
INSERT INTO undolog VALUES(180,'DELETE FROM contracts WHERE rowid=1');
INSERT INTO undolog VALUES(181,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91949000000 WHERE rowid=1');
INSERT INTO undolog VALUES(182,'DELETE FROM debits WHERE rowid=28');
INSERT INTO undolog VALUES(183,'DELETE FROM balances WHERE rowid=28');
INSERT INTO undolog VALUES(184,'DELETE FROM credits WHERE rowid=33');
INSERT INTO undolog VALUES(185,'UPDATE contracts SET contract_id=''tXsNynQTeMkCQVBKMVnHwov1rTjpUYdVSt'',tx_index=498,tx_hash=''f7708dbe7c0047b1465d79ac630652e46ab325a90713cef731ab23e63afeba8d'',block_index=310497,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',code=X'''',nonce=0 WHERE rowid=1');
INSERT INTO undolog VALUES(186,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=91949000000 WHERE rowid=1');
INSERT INTO undolog VALUES(187,'DELETE FROM credits WHERE rowid=34');
INSERT INTO undolog VALUES(188,'DELETE FROM executions WHERE rowid=1');

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
INSERT INTO undolog_block VALUES(310482,146);
INSERT INTO undolog_block VALUES(310483,146);
INSERT INTO undolog_block VALUES(310484,146);
INSERT INTO undolog_block VALUES(310485,146);
INSERT INTO undolog_block VALUES(310486,146);
INSERT INTO undolog_block VALUES(310487,147);
INSERT INTO undolog_block VALUES(310488,150);
INSERT INTO undolog_block VALUES(310489,151);
INSERT INTO undolog_block VALUES(310490,151);
INSERT INTO undolog_block VALUES(310491,151);
INSERT INTO undolog_block VALUES(310492,154);
INSERT INTO undolog_block VALUES(310493,158);
INSERT INTO undolog_block VALUES(310494,161);
INSERT INTO undolog_block VALUES(310495,167);
INSERT INTO undolog_block VALUES(310496,172);
INSERT INTO undolog_block VALUES(310497,177);
INSERT INTO undolog_block VALUES(310498,189);
INSERT INTO undolog_block VALUES(310499,189);
INSERT INTO undolog_block VALUES(310500,189);

-- For primary key autoincrements the next id to use is stored in
-- sqlite_sequence
DELETE FROM main.sqlite_sequence WHERE name='undolog';
INSERT INTO main.sqlite_sequence VALUES ('undolog', 188);

COMMIT TRANSACTION;
