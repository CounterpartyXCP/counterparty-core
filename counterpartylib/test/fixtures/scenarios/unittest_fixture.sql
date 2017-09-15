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
INSERT INTO blocks VALUES(310111,'fde71b9756d5ba0b6d8b230ee885af01f9c4461a55dbde8678279166a21b20ae',310111000,NULL,NULL,'31a0eef076aafda4f3c4085fd8416fb1835b84eee806ab08f66bbf34eb5c1ff5','26f6a11189102fdbb04da5a17d4cdab18dd32761e6b6980ba8be1f261cd0b332','cec44e5ef00fd13394367f640a704661a23b1cfc18d818532d1a7964305cb167');
INSERT INTO blocks VALUES(310112,'5b06f69bfdde1083785cf68ebc2211b464839033c30a099d3227b490bf3ab251',310112000,NULL,NULL,'c90259a530010b8f10f76320964474b61588ad54d1bfa1ae16cb94505291cc37','310394523eb12236649997b91099d045b2346cd8670b88b1d57903193b3e7393','ce8df7804485e9bd3e9aca7725d862f3ee3b7fe87c4a58f2bccc64dc47479ef3');
INSERT INTO blocks VALUES(310113,'63914cf376d3076b697b9234810dfc084ed5a885d5cd188dd5462560da25d5e7',310113000,NULL,NULL,'17181d0f1fe3b0570671324665a2e111cc292bf2cd987d0e70dafcc338359c54','8618fc2f243d455e50d227f9a467209c0057cb03b463212c774aa9c58319f430','ee486558620ecad13ffb10d5cf3a44eb245b130c7d964d1796a04f6dbb7bc6ad');
INSERT INTO blocks VALUES(310114,'24fc2dded4f811eff58b32cda85d90fb5773e81b9267e9a03c359bc730d82283',310114000,NULL,NULL,'b67067fa1d4e615db1dccad4292e50791a1aafecc062a6147d0c1755218b801e','1175790b0dfc3a91160b8f6091a5ac72663ca899c1ec99134c0782865fd449ae','69a88f93215fa6500f0ecd1dd463fd2748ec5bdfa923543e78a2f1cfb94ff739');
INSERT INTO blocks VALUES(310115,'a632d67ff5f832fe9c3c675f855f08a4969c6d78c0211e71b2a24fe04be5656a',310115000,NULL,NULL,'558ba8b0cb8bcc40b9df17aba3f747f52d5367734bb1d94aa39b5361f8a6697d','269d227c58023a03121d85fd711b3bde714158faa8daaa8dec7eaced100e84b4','58100d742b900f1b72e5ecd92ebe42c181cddc577b0e7852c4eceed767263017');
INSERT INTO blocks VALUES(310116,'8495ba36b331473c4f3529681a118a4cc4fa4d51cd9b8dccb1f13e5ef841dd84',310116000,NULL,NULL,'b23f0240f2d53cd0597f4fb6b1ebbfee5ee73470820ed2737f68cbeda80dc3a7','6e6338456786e44e9c75428e3169511a9725ea0092551cfd4cf8f37121891340','35feb959d595ba359286232b80164462fd3e4271a5c89f7df20cc4f851ba539f');
INSERT INTO blocks VALUES(310117,'978a3eac44917b82d009332797e2b6fe64c7ce313c0f15bfd9b7bb68e4f35a71',310117000,NULL,NULL,'c7601a4c0cbbd6da2eee3c70e039e32905ae6e1e191a8bb276fe3a916efb72e5','3ed2eba25f8b62ac9dc3b2d5a5afc83ef402536376763014f4918515b29b910d','b6a3e014f5f3f163fcbd361c5fb6c1222124918fe3eb9aa2e88396531a81e979');
INSERT INTO blocks VALUES(310118,'02487d8bd4dadabd06a44fdeb67616e6830c3556ec10faad40a42416039f4723',310118000,NULL,NULL,'ad1309bfd4af39d24cd233cb5938d12636b3985dd1245bae46bb168b3d2c4819','b2766212ddd2d2a550726ce5e9591667e29fcd3121ac5589441cb9183f0d3b18','581258878b9a8316a00fed7d8ed9ed1639357685258a16beaff724bcec817cfd');
INSERT INTO blocks VALUES(310119,'6d6be3478c874c27f5d354c9375884089511b1aaaa3cc3421759d8e3aaeb5481',310119000,NULL,NULL,'828c183d6a1f63cd4558174e2f8ace847bc3547966f9b64be0e592c9a73f7d9b','2987f77ccdc1a56c2354d5bd3faeb86d9ef2952d4ee3a39c8b6d11ba7abf564e','0f9642984643eb7875fa48ad09e9886c07505cf4091eaef78968eb8f70e97be4');
INSERT INTO blocks VALUES(310120,'2bba7fd459ea76fe54d6d7faf437c31af8253438d5685e803c71484c53887deb',310120000,NULL,NULL,'72b5a7bf3eac316dee8269b8f3b2119da4985b51fbd7c0248de0fc2374dd253c','18d47d8ae633a299baa553034c19543fa65bea97de8712c7df0e4bbf41aa2f22','a083b173cfa50251948ee855de14cdef4665d8c8ea7df51ed82b8453efa775d1');
INSERT INTO blocks VALUES(310121,'9b3ea991d6c2fe58906bdc75ba6a2095dcb7f00cfdd6108ac75c938f93c94ee7',310121000,NULL,NULL,'23143a81de5f5288f1b868f103efc57b4c6ca11a846dea8474a22d578ce7f27c','1bbc4455afafb516523744987bcac33e77485810235ca7ddab34853edfd4910b','114de18ca46c41c725d02324f17021443ad8ef6f3e9e3cec2eb9bab2071c282e');
INSERT INTO blocks VALUES(310122,'d31b927c46e8f9ba2ccfb02f11a72179e08474bdd1b60dd3dcfd2e91a9ea2932',310122000,NULL,NULL,'a0c14e0c9eb81800d71fcf7fc1b76dd1701002a189d4e8918786158d00097520','db8180015e43797004a99286bc2c04b4ab582ceb9362dc7298e5919ee5a5b481','5db35456aa07c9da23515aa17df6c2c12ba56828e05ba5272394ba286deebe2c');
INSERT INTO blocks VALUES(310123,'be6d35019a923fcef1125a27387d27237755c136f4926c5eddbf150402ea2bbd',310123000,NULL,NULL,'bbc4617672d00c09e648f3e2db715f00280497ac1e51f4f9981ff518cfa13952','cd541f780f20c21726b8be19c5bea6971cfb2a02525067cb512063fa5e8d3240','e75a500b2eb72b3794a73eb3de97ea49d825f5ebd9e56676a2080aeb2ec2e589');
INSERT INTO blocks VALUES(310124,'0984b4a908f1a7dac9dcd94da1ee451e367cc6f3216ee8cdee15eae5d0700810',310124000,NULL,NULL,'f31c7801761d641372f7e8a8231fa5196cd1eb046c6df5f395a23a9b53c9e0d8','8385504af29128ca412033f1e4914e548d3a7c63d12d8a886290ec4782915846','adea48f1842f1b6cfb739afb6f38bbdbd0fde0a44e75e9c3f8f14fcd4a521d39');
INSERT INTO blocks VALUES(310125,'cc28d39365904b2f91276d09fae040adb1bbbfd4d37d8c329fced276dc52c6a6',310125000,NULL,NULL,'92214632b0d871a4631ab8cf2ab235d2f621597c7e2df0ac0d5c300cf55ff13f','9f7ffdd060d1bc0edf479e36567bd5102ffc24f0f4161fde24c508f82ecddf2c','bc03a148bb0ee98512e8edb6c10f8456b52d9ca27cacbee955d17d88c2ff63a8');
INSERT INTO blocks VALUES(310126,'c9d6c2bd3eeb87f3f1033a13de8255a56445341c920a6a0ee2fb030877106797',310126000,NULL,NULL,'eb45005da17fea0b8e40eead280d15b3e4ae2820f75ee989ac091a820319a0b1','edd717a5470a1511dbe3bed559a880d633be0f6708531c664f615855ca607595','9386d0d69c7b312e77f83958fa4e78a35282c1069f8cfaefee9a8230d4d4d472');
INSERT INTO blocks VALUES(310127,'c952f369e2b3317725b4b73ba1922b84af881bd59054be94406a5d9bbb106904',310127000,NULL,NULL,'bec794cfd3c3df48e75d7b434e5f1e9ae9a61838a26ba0aaca682242ec57cc08','ec0f63d6c07cae5f1312ae34a4e71c1876c578a75a6b98ba788d812ec04f99f3','171d231f51efcf64d1cdcf3c4b242c2d7ceef7009c9164b66561b25bc0928de0');
INSERT INTO blocks VALUES(310128,'990b0d3575caf5909286b9701ece586338067fbd35357fec7d6a54c6a6120079',310128000,NULL,NULL,'29cc4086f7b801903e04e9164d68e2635dd7105ad22c12bfd8798082bbc12ca6','9990efb81cc3ba0b2c032882951863bed8aa63fad0ceeb2d748c1a3e8516518a','7c4e8f54199062788789ecfdf082d35b2fee70999a4e8defe7f7e5947044fc00');
INSERT INTO blocks VALUES(310129,'fa8a7d674a9a3e4b40053cf3b819385a71831eec2f119a0f0640c6870ca1dddc',310129000,NULL,NULL,'39108dfb13330e237f32846d97dbd0ae5316be71279f6844a988156be5cf612b','3fc16d07aa25a25eb89969e58b7c9be137d7b2d456aeaf53fc66081e9d219b1c','d7aabf7ba145f69f8a19b02f5c6875914b0b75c7bbc1a28e16f5ad8746cd5c08');
INSERT INTO blocks VALUES(310130,'d3046e8e8ab77a67bf0629a3bab0bea4975631d52099d2ddc9c9fa0860522721',310130000,NULL,NULL,'473618a86d2997055f0d1ae0511aa53562e2792bd106d98b88e44fd3c921b472','2f56e0c04a026e4efe67bb4506b905d5f9b16210d305aa0ae2419d2939fe3a72','66659a1789489669bb0f2a150e97be883918ba2f2f2ea0d9155cd3d047517de9');
INSERT INTO blocks VALUES(310131,'d6b4357496bc2c42b58a7d1260a3615bfdb86e2ce68cd20914ef3dd3c0cdd34d',310131000,NULL,NULL,'82d69cd65b178d450f12362b4ccb22e9ca7f55af13a773b97b68adc64f5eb67f','204c03f1c079280d90796cf9cc68b15fa7e982eea4b400e9e6cb4feb9c4de58d','e55bdf6d3d71fe20e281e0e79864a88d829746a9c7f9e7412a4f57b5769cd5ec');
INSERT INTO blocks VALUES(310132,'1b95a691bf4abf92f0dde901e1152cc5bd87a792d4b42613655e4046a57ab818',310132000,NULL,NULL,'c5a46fd1d7e4c4691f25739582c38c4ea048d3280649efdb7bf13232600bae73','c0299a6e666a020f09212c4af539cc22596099332c430e8c1f72cf291a1acc2f','404374e0a06758cbc78a9636112cf10a429c5cb9e9776e1d859b9b35e45e5bc5');
INSERT INTO blocks VALUES(310133,'1029c14051faabf90641371a82f9e2352eaa3d6b1da66737fcf447568ca4ec51',310133000,NULL,NULL,'cb98331c582a00c7a0b0dd39f7cd2dd8e13544412f9cf02d8bce3a26aebdc082','2c142f4d45b4c94eda7444b601ffcb168655451185b317c436d52d277a69dd9a','b532d949d951616f9b4145368301ab820b223aca75eff83574eeb2ea5ce57bf6');
INSERT INTO blocks VALUES(310134,'1748478069b32162affa59105257d81ef9d78aee27c626e7b24d11beb2831398',310134000,NULL,NULL,'77151a50cfe160e4ada0db15ee1f93942bea65ec3dc40014baae144505bf480a','e60d5577e43932675ed72b7617ef627f2442a06080d2360dfc8b1ac75b9222bc','1c8032c1add383e3982c4cc760e0dea6f0115f2f68bd906277bfc9e099f1dcfd');
INSERT INTO blocks VALUES(310135,'d128d3469b1a5f8fb43e64b40f8a394945d1eb2f19ccbac2603f7044a4097e4f',310135000,NULL,NULL,'0a6f8cfcdcd8c031f9cca409e35df7b4c0e270d6da21ba5370735eaf05861ae2','05746c667d4f4f4fdcbeec700ca6642cca15579936be99f88151a1131a70985a','a1ac2870941de666dcf4dbf2e87a3a496ce27cb9ee7747fa74d7c17fae11cad7');
INSERT INTO blocks VALUES(310136,'6ec490aaffe2c222a9d6876a18d1c3d385c742ff4c12d1334613a54042a543a5',310136000,NULL,NULL,'ba9134ad59596bdf31b739d224553d266bf1162475eabab4281b0c0cf8f555fe','405d88f7cf4b465f98e9afc661251d3fcc0083c985e6a42ec75c448296438b59','b793d6d00512948417153cea4f7b26762c80be447534bec169129eee7d9b8b13');
INSERT INTO blocks VALUES(310137,'7b44f07e233498303a57e5350f366b767809f1a3426d57b1b754dc16aba76900',310137000,NULL,NULL,'d33775f794381605ea6a544719ec87cc6ab33b67a2f86522ceefdadb50a2ce48','cd7400e5ee06f1a6d3a37d49acc9ccd9adafac24b3ea778b4b9cb20d6311f176','25a88d0bee6271e849d594635e605dd93e63a955ac9726444b043cb4e680804d');
INSERT INTO blocks VALUES(310138,'d2d658ccbf9baa89c32659e8b6c25b640af4b9b2f28f9d40baae840206402ab5',310138000,NULL,NULL,'0c7d27f8b6a3fffda184e486e28f3cc442ef813779527a1bda5cddf38db7e289','dca7f183943e639af5c8d2a5bd7e97b4564ab71ccc0d0b14ee6a6e76912a5b01','c0b2bf0c542e340b835ec569c986ef01646adeea69f2a895393358baa0998f85');
INSERT INTO blocks VALUES(310139,'b2c6fb61f2ae0b9d75d18fce4c52a53b1d24772b1ad66c51ca51090210527d46',310139000,NULL,NULL,'b78473056f63b10882bc97ebb9640c4fc2c84607699be4240c6677c47c0b2aa5','2381d88bb614ce5a55e9aa812e0d8fefa5d3f58c6f0c92ed3d130186e14d61d2','1755a53e8233fb8c2e5d05c99dfe9f90c55be0ec9453bcf23739aa4f5a7c2d9d');
INSERT INTO blocks VALUES(310140,'edddddea90e07a466298219fd7f5a88975f1213289f7c434ed47152af6b68ebb',310140000,NULL,NULL,'44a66d9ad302a859c4ae9b6647795e9b3dae40266577e8127506c13cc5f896e0','ee050a1fad14b45cabb98f30ae9806dc3cfa575b988efe2e4feab2ffec09512d','559bad0cd6f1cd15b53259e4092cdf54fe471faab0a5f2da92c1992776719039');
INSERT INTO blocks VALUES(310141,'b5b71d2a271bd638561c56f4ffbe94d6086debaaa86bfeb02ef0d71339310709',310141000,NULL,NULL,'e215dc1e0ed938e2c4fc1651c6eada3e935b3049b87ad2397e2c50c35f8ad580','222c6512c97c14340dbe0a7c68b0bd84554a30ef92d1a969bbfa0896cb9e2293','1adcd7b2a7bf48d0e150d69d1b6690341b031e4e2322ec2e2a527e118d05f467');
INSERT INTO blocks VALUES(310142,'a98ae174c41ab8fc575d9c8d53d8e02d8e446b8c6c0d98a20ff234eba082b143',310142000,NULL,NULL,'f205d981e84819383c01b89e7785b93924609c6d2250a7505d1f7abaab1af18b','e4e4bedb588519fe1b2033bad85d6248eae01a851a80bf782ad1f02457ea8458','d3245bb36796b283cd0e879555b9f2af2581bac9e06aab9c49f4084189325926');
INSERT INTO blocks VALUES(310143,'8ba2f7feb302a5f9ec3e8c7fc718b02379df4698f6387d00858005b8f01e062f',310143000,NULL,NULL,'9bcd807853f3b6e7a955e79027199b7ed8ae88783b420ce67b603e1729a746ca','98fa18bbb0bf21454f5d0e5a027f8dab971435138656c6801f1fa3cceb8a852d','7160c249b116cd29dfb6f714e73568d2ae2d9fc24a7a0519ed8043c7e94794ad');
INSERT INTO blocks VALUES(310144,'879ffa05ae6b24b236591c1f1537909179ed1245a27c5fdadd2218ab2193cdb9',310144000,NULL,NULL,'e659a7c4c87973aa291a233f2a01e7d6f87cc84d6d6b60aad44df4a499ecff3f','7fc4ce5450f8421db4c800316ab61678ceda5d9f73216a298361fdd2eb9fab6c','0e95ff8e377140630395dc14e3806d84851faf7d0310c661af5d00c21aa32a5f');
INSERT INTO blocks VALUES(310145,'175449ef0aa4580593ad4a7d0c5a9b117e1549ea772af00caa4ccdc9b1bf7a6e',310145000,NULL,NULL,'fe4dbe3741434f5a885c6584861d105464f7a0836920085dc7b4d6622bbf2d88','d070db69d8bca4beb5e18e8c888e24c7a2210fb8d29fe70bdf1eb1d80e692e3b','1a18c8e9a24e11cdd567e1df44849c2c4885dbad0ad3c98354baac25d8911b2a');
INSERT INTO blocks VALUES(310146,'e954ab6a110455d745503f7cc8df9d92c1a800fafdd151e7b1912830a9cb7184',310146000,NULL,NULL,'4083570250f78aeff4528cd3f74bd1353b1dc301c3aedc27de9c2b85e171e7ea','d539b52371513ac9350b4c7a297d6c5efb48db1b4a0b7a2ec1a338cee57b6e6c','40e3fa16b6d2dc13515c62fa256ecb1b419ffb09687f3f9c239bc3b9ab1013f0');
INSERT INTO blocks VALUES(310147,'7650c95eba7bf1cad81575ed12f32a8cc36281a6f41bef13afe1dfc1b03a7e83',310147000,NULL,NULL,'4e557b266a40b72a029b586fc8f3b0ca3483d29ee9437b23a5cef883dca7773e','ac9b133b0449db659a74791ddd7e0232e04f1f677aec4d1b21cd47957d0d5c3a','859971a5a30496950d30d5b0eda8f6612035d51f378e66507cf80ac76207777f');
INSERT INTO blocks VALUES(310148,'77c29785877724be924f965215eb50ffe916e3b6b3a2beaea3e3ae4796545a7e',310148000,NULL,NULL,'f20f3abcf224f97bb4a0fb5fc483e3ad1f9cfc8be0c9da43abfd2daf35df0632','c348f259dc5f5b7d12373ef554242c9b00a1f37b4b3a6289ade84e2726d6725c','2b46fb1819999a07308a449159956a85318f88837dab5b69b58217b4f2854d58');
INSERT INTO blocks VALUES(310149,'526b3c4a74c2663fc04ed5234c86974bffddb7235c8736d76860778c30207b3c',310149000,NULL,NULL,'1a46ca91bfdfd178748ba03e300faa0711d1545866dd5059bbd96b6909254257','61596104df8d764a62ffb6463bb872148fd3dfdb44480ee378561e75cee84f04','95058f9a8ba2da31cc468b4f799bef64449b9d1d79defc02bed9911b15450062');
INSERT INTO blocks VALUES(310150,'cdd141f7463967dbeb78bf69dc1cd8e12489f58c4ea0a5dc9c5c01ec4fcea333',310150000,NULL,NULL,'3c2bb960dc83bb47dd0ae69a0cca915d075e75b18a5ea836d027bb46e4890639','63594fbf9cd4b9f658f4d42e4655cce037a5e8fc8c80da687da5023f80822886','f6124d0878d7071823e29ebb99aba12fc6144f7a2e181c16363b94080b43e4a4');
INSERT INTO blocks VALUES(310151,'a0f31cc6e12ec86e65e999e806ab3bfa18f4f1084e4aeb4fbd699b4fe284b330',310151000,NULL,NULL,'efd8b1a509ac8f9a37ba96e73dccb882c36a5574f6944abdd71b2c946ac4d1df','3c01269331023b4b721827decb9cb6605b9c4074cd6fc7d23d6739fe903eb574','c64859d5402b1b8b18bab8f92674b6b8553860df40f2a121d12802c179f2a060');
INSERT INTO blocks VALUES(310152,'89c8cc3a0938c63a35e89d039aa84318a0fc4e13afac6beb849ac37140132c67',310152000,NULL,NULL,'ba36d83a505ae912392635989e8cd7a823d67ec935c93b5de5205efb91ba770a','d1c13499cfd8809f4caab59f33142f6efeb8decebb2c0282e4eefd2d00a72e35','f5b4dc54db508b214820fcd326a08389b1885aea950bde98f4226bea4d4455c2');
INSERT INTO blocks VALUES(310153,'d1121dfa68f4a1de4f97c123d2d2a41a102971a44b34927a78cd539ad8dca482',310153000,NULL,NULL,'53172c579f587686b596c1d5221af2d4fe6182a4e383956575c131a2ff8e047d','909c2d0e1bae8cd6a7678cdd3d2cdae3c8243ff03dd7beaad1757b2d0c4e44df','a6716406296b5ff675ac833d7e895dccea15446125f4582b2077fbe99093a936');
INSERT INTO blocks VALUES(310154,'ba982ea2e99d3bc5f574897c85485f89430ae38cf4ab49b7716ed466afa506d6',310154000,NULL,NULL,'32e44d5c7aa461f1772be7992071f008822d74ac9bf2aa1ae372e9ecc90ca4cd','377bab6b0d1498be3e3791260b139f53970de81b6e68580fc06c2480841d48cb','0f79331448eaf1f608a9a00493b6d58057f599dbfd11062d7202d2b0bc89b353');
INSERT INTO blocks VALUES(310155,'cefb3b87c7b75a0eb8f062a0cde8e1073774ae035d176e9769fc87071c12d137',310155000,NULL,NULL,'9e5b38f739d03395b509dd151b459e11b8abe9aaf8de94a6dd30dd7240773ab0','5e142a0ed7a1b149565b2b82b0bbf76eb5d09fff0a4431301cca7cf22a3d0506','0414115b9a2e94ad2153de81e9c9a6e4f814e991f228d2dbd51a7f881f2569bf');
INSERT INTO blocks VALUES(310156,'6e3811e65cb02434f9fde0445a7a2b03fe796041458737d0afcc52208f988a83',310156000,NULL,NULL,'22c8ba641ca4d31b68279720911449fcedc6d7e2d09ec1b1cd50e0ad2be93ddf','5f14ab0b740fd2d16be3d7cc919582bf887acf68f0667a27c3b2445eb693fda4','fc1c564be0b2ba52b6900dde987bb5cee9b0350ea40fd679ad3ee5f438b57eb7');
INSERT INTO blocks VALUES(310157,'51dd192502fe797c55287b04c403cc63c087020a01c974a565dd4038db82f94a',310157000,NULL,NULL,'39504b3d7e0c11ec49a89f5e1f9f52a821bd6ebf7126d293f20fd8d168e50100','d53ab2bb1a24070d091b7f428d7123d0c9c1bbb422594d67a1273e45cace2b12','a8a8e6116dc4707e4fd8e862841d0cff9fd2948175989fdb914c9de09ad884c1');
INSERT INTO blocks VALUES(310158,'749395af0c3221b8652d31b4c4410c19b10404d941c7e78d765b865f853559d2',310158000,NULL,NULL,'192109b7cc52402c0ff9e8922fce650378590c98c5bfff2c7a7fa3f706bc1a3d','c50956e1f2de48373775b7df90265df6f715c083d30e1fb3a7959431c3cc652b','a1a51c5a79960fb79955c3645ed146cc168142c4048f358e3bbaabc3d3524eed');
INSERT INTO blocks VALUES(310159,'fc0e9f7b6ae99080bc41625588cef73b59c8a9f7a21d7f9f1bf96192ba631c12',310159000,NULL,NULL,'accc7b0ef66745f51b87a0a9b6ede3692ef196008e582e2c504d0e8fd15bd73b','a1ae4717f1473d9197404641352ea07b0d548efbd0ad2aaacc42675ecde6199a','f68feb9aacb273d280dae4a1d63871a117910d82503f368aab4dc75eb92bfb08');
INSERT INTO blocks VALUES(310160,'163a82beeba44b4cb83a31764047880455a94a03e859dc050da782ed89c5fa8b',310160000,NULL,NULL,'cdd98b6b18e7886eb478771ff58278e695d1791597110563d7de16c98142ec3d','c4027a0c6b79d09fd4c1cc7ff9317a6deb3ef9d69de668633d5e4999a236c9f6','d41253acb6af3bfdc530de2f7d4381fb5c4dcb2dfcbf2b41917053272d123ea6');
INSERT INTO blocks VALUES(310161,'609c983d412a23c693e666abdea3f672e256674bf9ee55df89b5d9777c9264d8',310161000,NULL,NULL,'fb42d97cfc317712b7bb95e0d96158e1b50e25e3a164d643f6a849353af1e6a9','13d6253a2448994cb40feae12091ed01cd1f3e780ad8ddca7c5176616fa8cdde','8e2f617f960f9ad3217c81b0353c893679a9dc897d23c22d7125dbab26a20586');
INSERT INTO blocks VALUES(310162,'043e9645e019f0b6a019d54c5fef5eebee8ce2da1273a21283c517da126fc804',310162000,NULL,NULL,'5ddd001a739b02324808238e5e63712e889bc0ccd43f329199662de558603109','c6e2d4eac8408a5a7410e4761adae8b812f402daf60ded121612c07d9145c04f','9a88d009ad6c245090c34947911f32fb57d2599703227bc3322bd7f26ddf6f3c');
INSERT INTO blocks VALUES(310163,'959e0a858a81922d2edf84d1fbb49d7c7e897a8f49f70bd5b066744b77836353',310163000,NULL,NULL,'86aa15eed28f5fd228c71329bced64b4ef2cd48ee9a47adcb807038320ebb202','21e6000991845a02a882f5b98b00320f2b9c469fa1c37d5f445cac51da0019de','9fd8bbef26dc4894f13b24efea83ed2fe7f4e8b18c648b9976b0cd69a2552cc4');
INSERT INTO blocks VALUES(310164,'781b7188be61c98d864d75954cf412b2a181364cc1046de45266ccc8cdb730e2',310164000,NULL,NULL,'83d970051ddf7bfa39d100ff42bcaa7cc354740b8ef53872d18b5a705535a18d','5af21d3a2e1f4fc4d509b8868263f951829d86d6e5805c7b1c3447af9157aadd','555e026c17e9d47fecb675b5be2185c12bfc7f75cb5dd01ed41e37298b128d86');
INSERT INTO blocks VALUES(310165,'a75081e4143fa95d4aa29618fea17fc3fabd85e84059cc45c96a73473fc32599',310165000,NULL,NULL,'9e497bb923d962891885a2d3a9c2eb0d074ca26ff45bd9af4bbc60926e0f924b','f1775bb1d31b1e71f8fc5d27b9edf1a032cf2efc5851b2e4b229aefd9a78f75c','fc47012cf8f8b9bfb35c696f5265f418f0ae3035d0a3e1ed70885735fac9b8f9');
INSERT INTO blocks VALUES(310166,'a440d426adaa83fa9bb7e3d4a04b4fa06e896fc2813f5966941f1ad1f28cfb41',310166000,NULL,NULL,'0417eafc1c3bfdf9f54ebca6444e960dcd1fc126204d593dd1d08de23055d0e2','9908396b85595b8b3025fb3c000718e82376d8fdd62c1afc9655f28e35c7f717','e249d715b6b56e2295cdd54030abf8ab5517ee001ff8ac1b3b84b9e2dc6b77de');
INSERT INTO blocks VALUES(310167,'ab4293dbea81fedacca1a0d5230fe85a230afc9490d895aa6963acc216125f66',310167000,NULL,NULL,'c733abd319b6b9a59c23f3f24ba35e9fbe669b84c5550024c2c875bb5e185f72','c2c7b3c3535545454630f88c4c2804e1f59ceca7745a074023355e8ea86c9c85','7017a17f4a0f27b008829c651b29766d23571be888371be800225d67bc947727');
INSERT INTO blocks VALUES(310168,'a12b36a88c2b0ed41f1419a29cc118fae4ecd2f70003de77848bf4a9b2b72dc9',310168000,NULL,NULL,'7a5567209465058f1ce41d25858e66d47e81398a3b924b302e254e0f328687f2','09cca8be8e645dda23293de15fbc91acd2c9340b13b947a4849351302b944c74','c0a619f956146f50b3d07ad23146243651e020c99549328e282572c9d1a6790e');
INSERT INTO blocks VALUES(310169,'204809a85ead8ba63f981fc1db8ae95afe92015f003eaebbec166021867421f3',310169000,NULL,NULL,'c446a7c7fa2b54cbb79ab56105a3d5f640fa86e1770e9baa0a21d3bc98e4a3ed','a6cb52d8cb945e512129dfdaec80474e7e5317ec206b49a9738f27808f6d442d','10d1a975f3bc3e9fccb9278bb2df33622e91696c740c469e9b1bd40857768378');
INSERT INTO blocks VALUES(310170,'b38b0345a20a367dfe854e455e5752f63ac2d9be8de33eab264a29e87f94d119',310170000,NULL,NULL,'0b9355e7739d154013b649e12ca64c9767da377a9becea4cbfd92ade6769b0d0','24398eb96ad51c826ab81ba18a2a32d8cf45c99b6ec509424d35e4b41d53fec3','a4a3a591b1cfd1bad15ae613fc3d912d310a125d968b126bc04e1ee511546019');
INSERT INTO blocks VALUES(310171,'b8ba5ae8d97900ce37dd451e8c6d8b3a0e2664bb1c103bf697355bf3b1de2d2d',310171000,NULL,NULL,'0a28f6dc64798458009b1eeb4f234a8c8d982ca6107bf47e1992c31aeec8fda0','13de23ff6a5c43c3788e4aabfbb7763472b916b4820e535970f70b0e6d3cc5f2','1dabf87aa814268119448ad9c6d315f6c62f89e26acfdf3a0dfa83484560bc41');
INSERT INTO blocks VALUES(310172,'b17fda199c609ab4cc2d85194dd53fa51ba960212f3964a9d2fe2cfe0bb57055',310172000,NULL,NULL,'d6c6ffee6656e63d3356bac4218955f81b4c34251d555e858f5bb194083be174','51e629d5d1bdab47400bd5956b0d6e8e2f6839e388a310601094508ab9069be2','dbcb5cae27d17ce4cc193bf5b8018125db573bc10f80bc0915507768aab4a9f7');
INSERT INTO blocks VALUES(310173,'f2dcdc5ffc0aca2e71e6e0466391b388870229398a1f3c57dec646b806a65016',310173000,NULL,NULL,'da74cea1a93deadf69f4bcafac16273fc94c55d1b11939d932c726d928c89895','a48e0937b5b8b85d9755efa5587d608b792bf89d8e357b9a65823ed6917cbe51','67dea85e0b8fbb3856e00773d1568b576041ee4d4f9d03ab94699e0e1215053c');
INSERT INTO blocks VALUES(310174,'fa6f46af9e3664353a473f6fffce56fa295e07985018bface8141b4bf7924679',310174000,NULL,NULL,'6d6a98445845420cc7e4bcb60d2a0bad393090137bd2b648dca6f4565de16fab','816ccaa22a97d6c3861ef9081c75e960f9eb54b65dc5e0656b52f6ea0cc122b8','828693f4fccca619d8ad3924b5e4674400100d5b01b8ca33320fc16927d0d016');
INSERT INTO blocks VALUES(310175,'f71e79fe5f03c3bc7f1360febc5d8f79fc2768ce0ff1872cf27a829b49017333',310175000,NULL,NULL,'8d86b8abfea247af0c407527a09c92fd0aeb9878edd5c53893237171afcd8990','2ca8ce9eee953d46d14ef9e2b1e86bbe7150768b11b02ead17753f8edec96bfa','479cbcef341d1a3874c2af4bab21e077eda2b8153b4550ee66843f507d4c396c');
INSERT INTO blocks VALUES(310176,'67cd1d81f2998f615602346065e37f9ceb8916abb74b5762ead317d5e26453c6',310176000,NULL,NULL,'1b23f99b5f15355c9db60ae33b41908cc5e5c51ef4f1e85fc2cdfe6744b05b2b','799a36d64042cf0f9bdc06ec69b367fcf6a002416e603e4ee143089798b17ff2','9573c1b919738fc0946b7aea83ec19cc549261d71212cdb6e46b2c81d063fa00');
INSERT INTO blocks VALUES(310177,'6856b1971121b91c907aaf7aed286648a6074f0bd1f66bd55da2b03116192a52',310177000,NULL,NULL,'9804730abfb72f4394aec4aa6df5e1b23e6d49a5d225bb956aeb605fb9145e70','a9f2836ca931b00ae85282a8c1157e343a0897d76e10c6f646ae58aac74cdb57','7ed5c99e4790a23590766293e59c5b1c07e8f98ff938b8edf0c566952bcccf8b');
INSERT INTO blocks VALUES(310178,'8094fdc6e549c4fab18c62e4a9be5583990c4167721a7e72f46eaf1e4e04d816',310178000,NULL,NULL,'a32c031d3ea315152b5e44e75b01bf4715041eb2aef8b1285896ce95dbc64829','614edad6f13d070e6cfe84376ac5e9105417fd475d2d52922c962807c947e0f7','e51341257ca619ed2e01887ece25cadd6f9adb18db27d29cbedec7abcd6ab689');
INSERT INTO blocks VALUES(310179,'d1528027cd25a1530cdc32c4eaff3751a851c947ddc748d99a7d3026a5e581a7',310179000,NULL,NULL,'a29114cd598b3ce52ad8abc047e1fda6deb925f3c382a3d295f8e4f9d848236a','6d4a8a27791180be340077152f159a5532496ddf4620c1b6c6fa700ca0a04a25','d7999852b71520a4a6e2f687c9fa9ff5da3362f2e419c8c23edf5af2e4e21faa');
INSERT INTO blocks VALUES(310180,'f2f401a5e3141a8387aaf9799e8fef92eb0fc68370dae1e27622893406d685c1',310180000,NULL,NULL,'d6d50f328fbfa7b7b66897805d013b0e5be3611c76c27986a1bcbaf6ab766926','da96fb6931fce8fe257fe7da8a6e67b33fccb559a219089fd04361e4a42c5cef','b5135c0dd7d0869353b7c5eaba5f7ac6a9fe36cb2956962b78aa5bcc526e60ea');
INSERT INTO blocks VALUES(310181,'bd59318cdba0e511487d1e4e093b146b0f362c875d35ab5251592b3d9fed7145',310181000,NULL,NULL,'ec174f40596ae4c6427a52d73858fb37713cab2028601ae5e866b1ea5b5e81ba','524d18e82c4e359443e2af33a02416e435e6b0fae062520284135fd4ba786366','59bcebf43f81ccda5b2d01870c48e059d1d992d18cf760647b59ce637e98d0eb');
INSERT INTO blocks VALUES(310182,'a7e66b4671a11af2743889a10b19d4af09ec873e2b8eb36949d710d22e1d768f',310182000,NULL,NULL,'bdc51b3e849e30b9fa5f231914b4596702ffe2f16b39eb27635a8c7632a90e3c','ac5df5d34c0cd84a6efe492b42c67975f40b08886347aa7fbc93f92e4f3c34dc','e4845ef520f6500c3fe5c9c96099149609e1eaeffd290fc934b43c1257d85f90');
INSERT INTO blocks VALUES(310183,'85318afb50dc77cf9edfef4d6192f7203415e93be43f19b15ca53e170b0477bb',310183000,NULL,NULL,'d5d1d220693a3c64cae5a4ceb9f2ba9e8224c20aefe78dba64cd2acf3ca345ac','8702b18df443e4624f2c40c7d72c1c0862b197e9f33e2b23da0c6931f2ed24f8','c90c5c191dcdc9147924a18a21748312105f0a090bd398aa2d134f5cc7e11c5b');
INSERT INTO blocks VALUES(310184,'042a898e29c2ebf0fdbb4156d29d9ba1a5935e7ed707928cb21824c76dd53bfc',310184000,NULL,NULL,'14b5ce9986d4a36197a5600628620799bc8673f5f976726688dbf6f18582c0df','168ee6ffbae390c4f527fb03f0b8d5334018e9f8e3a05b5270840d218bf08b82','a391e71b8145f1b714adb83437ec307364d7f00bdd1bcfac61b4b68be285cb3b');
INSERT INTO blocks VALUES(310185,'bd78c092ae353c78798482830c007aac1be07e9bc8e52855f620a3d48f46811f',310185000,NULL,NULL,'b67ff58fe11d6309f60c1da47ccd1e369923c3e41e155971a9e0966082913090','832a991210bdba163ad758778fd7a677f083785ad3ca3fb7c869c69382a3486e','581b3598c52a1f0be0895b1eb527bbeefd4f74b8721adc117a4f2949e467215a');
INSERT INTO blocks VALUES(310186,'e30a3a92cc2e5ad0133e5cee1f789a1a28bea620974f9ab8fa663da53e5bf707',310186000,NULL,NULL,'abfb0e2a727db89976f17b1a3f63f230cb09ccd1cb07dd7f50fcdc7b35c289ed','234301020e656239189e40d59811f7e634fc963d7f3c0c7bb256f0d337b1c4da','5f1e61e9a5771fb2924f91c8c4e12e7cdc9ec7a05aeaf524f861014053d47047');
INSERT INTO blocks VALUES(310187,'fc6402c86b66b6e953d23ed33d149faa0988fa90aa9f7434e2863e33da2f3414',310187000,NULL,NULL,'e03d876d5a90f41a1255fa8e14e26e92e364c2d89c85ccc9bf9f0adec885b3b8','a0260545c6819157e7b0c334d24de32e13352fad7bcc14a6c007b1016551c89f','325d1dc07ace547b97d3dd72a9cca7132d8a9586222f4b77029771d975ede847');
INSERT INTO blocks VALUES(310188,'85694a80e534a53d921b5d2c6b789b747aa73bf5556b91eeed2df148e2ada917',310188000,NULL,NULL,'0ea0b133e0427d12b211d90ef179ed1689abea4fe4ae18f0fef63b5caade6c89','ce8173036fcfcc077c02ff99a35bc7f0034ececc471820cc312377c012ad4442','c6a0413a69b4f8587b60715c5154af240607756f01cb9cd3f3e0ab7576461075');
INSERT INTO blocks VALUES(310189,'7c036dadf19348348edbe0abe84861f03370415ed2fec991b9374dbb0ca19a06',310189000,NULL,NULL,'febec5d41d19208c0ff8c8bb39bb27d08f8254b19f8e2152cd9aedc3ef65f017','d805c45e1f3f925d9504b53c5c122dd696101026077f26343fc42cfd81596024','86644768761c09233f01514af8900e6f361f5aa68d045ef6ff4887056551fbd1');
INSERT INTO blocks VALUES(310190,'d6ef65299fb9dfc165284015ff2b23804ffef0b5c8baf6e5fa631211a2edbd8d',310190000,NULL,NULL,'ced69644dd310e50e6c178a63d3d9d303e519070c1f13e13f6da7db9f30bc750','eb48aeeba2c96dbe2054589a37ce90b2eefee7f687a360a0bc4decc7612c32c2','753a803a06c8eb185db72fa2f67934c88388c02b6912dd90332acd165bd03f66');
INSERT INTO blocks VALUES(310191,'5987ffecb8d4a70887a7ce2b7acb9a326f176cca3ccf270f6040219590329139',310191000,NULL,NULL,'2da2e607453c9660fa5921ddda5869bff1e28aed9019c79e34f7f1573d5198f6','86e398118ce5df20a989a2dd20f1dcce16d0d9ec27fa7f7ff55648c62a9f9aa8','d36e7fe12e67f16a5b8c6ff2f163d8f7f4b0a7e6cac04c88ac542c48a2d139d4');
INSERT INTO blocks VALUES(310192,'31b7be43784f8cc2ce7bc982d29a48ff93ef95ba18f82380881c901c50cd0caa',310192000,NULL,NULL,'1796ee28da99a66e1d726cf04baf1b6ac3d9ea1b250915a9225cc61c23fbf537','cfe87767193752985816cd50d1bd74b6d4116a932a8a2d8a9c5aea79229fc82f','57f6d9d00e0ab16a20b08a5b1f2354d4f6eb98ea4d449e6224d45b69b1b80d5f');
INSERT INTO blocks VALUES(310193,'ff3bb9c107f3a6e138440dee2d60c65e342dfbf216e1872c7cdb45f2a4d8852a',310193000,NULL,NULL,'89559dd6710738956e297e83d3494e44096120054cb04968172f83a41cdba8e3','1f58ead825bd7a85b233c7ecc9121b545f80cbeb483015405819f3989c68b8f1','fcb6aeb57526ae673d4674c9f59fb07816d885b02eaf99b1837eab8498850944');
INSERT INTO blocks VALUES(310194,'d1d8f8c242a06005f59d3c4f85983f1fa5d5edcc65eb48e7b75ed7165558434a',310194000,NULL,NULL,'2197b5f7e6298bf96dc693b7ffe1c01bc744fda913e0431149bc8663a9c61e29','b897586108a075d23482ba3a6152f73e34b0896ae4954b2e72e64193c5457cc0','82b77cc71dd212c90c5df4eb268a85011a46b9ec4380f8d4659b793e3b8677fb');
INSERT INTO blocks VALUES(310195,'0b2f1f57c9a7546faac835cbe43243473fa6533b6e4d8bf8d13b8e3c710faf53',310195000,NULL,NULL,'5fc1ac149360e81065aca4bbf8a63e56a476656577b92736fc40a37895000445','6fc35eb4a3b22f4c1caf1dbdde1f8432df402ffb562ee28ec00dd1b7a06809a7','7b5de731775689bf505e3792e7e03013426070d306553fc84cf4e6fd9f6fceca');
INSERT INTO blocks VALUES(310196,'280e7f4c9d1457e116b27f6fc2b806d3787002fe285826e468e07f4a0e3bd2e6',310196000,NULL,NULL,'8b9e74132dd1d4e710e4316113b1b4ab8528000cee59129f74e24bc2ab552899','9c6908216b53a457dc063bf58cbcd8d3fff617de0fd3944c1b74b5a072cadc38','1a9779bfc908df6b13f01833d7f1ddcf95e1146ee47389857c5842a69af749ad');
INSERT INTO blocks VALUES(310197,'68de4c7fd020395a407ef59ea267412bbd2f19b0a654f09c0dafbc7c9ada4467',310197000,NULL,NULL,'09a3180bb504b3762a0cb0e65522c0a7e88bbf904552dde42f5704701aa87b17','975f480946b389b39d6c8d7713ecc016d9ee516accec17d6d7136763d180e033','14e7a2747460a5a169c72f3e1b2ce5a9fb5efbd61ed7cc3e2ec7da4e7869b7d3');
INSERT INTO blocks VALUES(310198,'30340d4b655879e82543773117d72017a546630ceac29f591d514f37dd5b1cc2',310198000,NULL,NULL,'11b05da2ca99b55d8903bd675af2e2ac20768a53b0822e624992e50f2471ebfd','34783577504bb7ec1ecb525884e408b4d0ea6ae84ff3c5960afd66a2f0fa3963','37b2ea71e212fd7782b484aa6c211c9d8898aeda70c4261123ecc990312fb1e3');
INSERT INTO blocks VALUES(310199,'494ebe4ce57d53dc0f51e1281f7e335c7315a6a064e982c3852b7179052a4613',310199000,NULL,NULL,'80c7de343998aae2b87016587cf27032803a6465fb816bc8aa915245d412c8b6','701a2330b660b1766c13ccf96291dc0323173af5a730c98b2d266d5d56b0dd39','9ae5eff260d0ff4c39dc7d76b042b53d70d181ade6440d1b124be6a591fa491e');
INSERT INTO blocks VALUES(310200,'d5169d7b23c44e02a5322e91039ccc7959b558608cf164328cd63dbaf9c81a03',310200000,NULL,NULL,'c45b641082b320c65f10e283a55da4eae6e6fed99c2bcbec4d6e5a560f727b26','a40b88a5da10f304f874c38f6541f2ea14dae5582ddee25bf67cb21044d2c1b2','0916788edce5352806d5e17e23063a6d1e86b642462629013b384ca6a1af3dd3');
INSERT INTO blocks VALUES(310201,'8842bf23ded504bb28765128c0097e1de47d135f01c5cf47680b3bcf5720ad95',310201000,NULL,NULL,'247b389a08e28869b4a4e5e03eddd14db90913a9b1a8fa1bc9854d61d5b1128e','fb8e3f78e839cdbd5dc1936224e03cca0a893f9ff5152e62f764acc72d7ac6ab','c47071dcbd52551a8c9ca31743ee45768bca17a739b38a1b65fd85053b2b66e3');
INSERT INTO blocks VALUES(310202,'95fa18eecbc0905377a70b3ccd48636528d5131ccfa0126ed4639bc60d0003d8',310202000,NULL,NULL,'da07891f68861cbde2f3b5b1c05ddc459c1e255c383205b7a2b18c1ce9778ff0','7db4e6b54aa5a4065d457493fb61992b86183edfdea2d2b420ccd61004dae900','c2f3b811efa45ffbf0c4b0465114ff4383ae7b5bc1957a6e1cd277e95d375b14');
INSERT INTO blocks VALUES(310203,'ab15c43e5ac0b9d4bd7da5a14b8030b55b83d5d1855d9174364adbebf42432f8',310203000,NULL,NULL,'17d09cd5d38668cfb960b0786c4784ad0929ba7b127721f470a9fd215c28da52','0a8959af448f03ec93aa233511dfda54819b4f8c5c7d010fb2a0e1da0e671bc4','ffd950eec39dc9931cc8784af8c8f1d994f93ea4ffe68e121c01a75df72cb9a1');
INSERT INTO blocks VALUES(310204,'18996fb47d68e7f4ae140dc1eb80df3e5aba513a344a949fd7c3b4f7cd4d64cb',310204000,NULL,NULL,'68ca95a7903b1818b6685c8ddb548462e942b8f3416bac3d2649fc3c0eaede9c','c160b1cd35de44f75633b29f6e457c588d94c9af6abd5da208b58a8bbf18b0e9','f178bdff0462efd77009ec95aa1ec452b090d0e62688f55d26eb6a48414823e5');
INSERT INTO blocks VALUES(310205,'5363526ff34a35e018d1a18544ad865352a9abf4c801c50aa55742e71630c13a',310205000,NULL,NULL,'591b834d7cbb61a730655e09e0eaa5d8c82d378c07f996cdb5f43465e34daa42','213a554a13489c25fc0c0c3ceaf60c48b919f12f8f24e9696e4ad532a44cffad','bec62ae6bb93284e7ceda5ccf5e16e412b94ac1e17a110508871b5e3db678dae');
INSERT INTO blocks VALUES(310206,'0615d9fca5bdf694dca2b255fb9e9256f316aa6b8a9fc700aa63e769189b0518',310206000,NULL,NULL,'09b9424b3b948f120b8f1845c68f721f0a7db089ba79b316f9724a904abd8017','333f1d42b9a1cc07b65e18c78d3efd4d88c2b499d78239bd26f6872a48d17361','009efebb1defa44178a9057c8ccea69df3afca57e53931d104110635ec132351');
INSERT INTO blocks VALUES(310207,'533b4ece95c58d080f958b3982cbd4d964e95f789d0beffe4dd3c67c50f62585',310207000,NULL,NULL,'a8a3ce202e9b966c61dd5283b1fad484b25b59077f274646d53964fb05b99445','4a5a0756a8eac1ec1d521ba1438948c6e49a28326c7f4b8690fb14e4039250d7','d8371c11f79129b6b9e8c1a14fa61b95a934d34a756c85c365c106c2a80dc14f');
INSERT INTO blocks VALUES(310208,'26c1535b00852aec245bac47ad0167b3fa76f6e661fc96534b1c5e7fdc752f44',310208000,NULL,NULL,'7265c87968a88a489545ca0372fd16ddc9a545a185bdada3a2abfa41d76530b9','2b34add92fb24d3504afd7ec3b45ab29601a119c11b2460a603050a93369a515','acd5e7f7ba36ecb13d48cb62347cf61deced00ba450a3f2c7a6ac23cf273964b');
INSERT INTO blocks VALUES(310209,'23827b94762c64225d218fa3070a3ea1efce392e3a47a1663d894b8ff8a429bf',310209000,NULL,NULL,'040fcd7d0e3fd9ebecff8b8a68e135f35b1b3be59ee304c3c2014ffbadd5aba4','ce9751b3fd56560499d7b574fc91213d68048e9fcbedc53addc8c6cc068e59c9','6df8da8406b44486c62b8f531a3de7004f7c61a6bc352897aa37d68cfbcb7a34');
INSERT INTO blocks VALUES(310210,'70b24078df58ecc8f7370b73229d39e52bbadcf539814deccb98948ebd86ccc0',310210000,NULL,NULL,'4c3a88fe80d56be6599d353afda19537c8dea58f83bd71fc6c231c472cba6e44','63ca2cd2f40dda15d8696aa7b337d8bfa78f326ec68048a295f1f455114c8128','e1227e210ab6719fdc26f17de9465bd4a294240600910601bc2258e56275d64f');
INSERT INTO blocks VALUES(310211,'4acb44225e022e23c7fdea483db5b1f2e04069431a29c682604fe97d270c926d',310211000,NULL,NULL,'a7deb783d45d6ece0781805487ff28934dffd2031573add06f89010c8fa79fc4','9493bbf2ae95d327ac392968fef737edd427ed1ab248a38fd01e5a1c1f18c334','27153002f0ae1db5fc91e8f4f00e0dfe10ba92b2b260b6f64ebfe4ac440c1891');
INSERT INTO blocks VALUES(310212,'6ef5229ec6ea926e99bf4467b0ed49d444eedb652cc792d2b8968b1e9f3b0547',310212000,NULL,NULL,'9368b8e180a0a64869ad5a9d7480293a0061def86835ca46258a8f2af354301b','4cb97d7bf3ca36bcac5138860a48b53786b140c22152df08a4a68fcf3e67d113','6c4bd95b49c0829965971eda5a83781e0142ef49a9f15c155fa5a2cd4e4d4da5');
INSERT INTO blocks VALUES(310213,'17673a8aeff01a8cdc80528df2bd87cdd4a748fcb36d44f3a6d221a6cbddcbe7',310213000,NULL,NULL,'9433ea14d9a483d99d9f10a6728cb7f0b75d3198d5a1c474e6402cef756870d6','664bea23eb650eba2c413fb6c104186e5141f6afbf7da4a7e09c7c2a97e7e9e8','99a7af4640e98a16090d39de596d0de48469445720aa85ef5348ae1ec9d95eaf');
INSERT INTO blocks VALUES(310214,'4393b639990f6f7cd47b56da62c3470dcbb31ef37094b76f53829fc12d313454',310214000,NULL,NULL,'7d0345c68b071ebc66d31764e3c1d95b3cdf672d1613e5abb7ee76fa015f2229','942424b9ec1305292100b82d5cfc0de7c8473d1a733479d98ed3657cf9b3290c','24f215c4b34434e4f208e0568467398413ce4974b845b5dc624133f5ac12a8fd');
INSERT INTO blocks VALUES(310215,'c26253deaf7e8df5d62b158ea4290fc9e92a4a689dadc36915650679743a74c7',310215000,NULL,NULL,'99b993d90ae507896b6737ccfab8c6b10bc084e839e8d2d40c400e7ad94aef8f','3f56ac1224598d65c2e5970ca68d963f4f74c7fbd114f128e3d7415b5e65dbcf','f43a5e4096fdca3c8d2b18e2b8db4cd3b33dd80803cbd577c171f7b30e16d7bc');
INSERT INTO blocks VALUES(310216,'6b77673d16911635a36fe55575d26d58cda818916ef008415fa58076eb15b524',310216000,NULL,NULL,'eff5a08a9e0180ce9e46a91f6c146537af5c5dd3f27c2cd2cc195fbf20714410','45e937582a0a3262d56df58639b8603fd39d6830c484d865ccf87e106065bc87','b94d5583af56f5d9119a9b1131a811ff77ece04aa548ea75517cdb6ecd14ea9b');
INSERT INTO blocks VALUES(310217,'0e09244f49225d1115a2a0382365b5728adbf04f997067ea17df89e84f9c13a8',310217000,NULL,NULL,'6669a33b1f46637b716505fafe69a750d01c1a0a76507f405b1867ff514d06f7','6daddd8e571dcefebc6e8d54949d1d21bf214975964a08427461d7ff800909eb','e181465c237067cda2f6481854ff5f7f74cdfd161df832aeaa73338afcca9d3a');
INSERT INTO blocks VALUES(310218,'3eb26381d8c93399926bb83c146847bfe0b69024220cb145fe6601f6dda957d9',310218000,NULL,NULL,'7ed9d9c0e19b48b241efe69b5210cb63c8799b662532c56830f58090cb923951','4d53e1ba01028ae6b0d0706c12b35e9e3f26f1c0a4bff89f28fb1f1b1cf55615','0e73dc9d14f1d17679a94d59821669ea3b3908868837b97753c0c439e7ea66b6');
INSERT INTO blocks VALUES(310219,'60da40e38967aadf08696641d44ee5372586b884929974e1cbd5c347dc5befbf',310219000,NULL,NULL,'4228c1e87fef1c99cfbf5d07e707b54832612df7853ec9a0530bdff71cced8d7','aeb14766350f205e15284a4d8434a4b5c66c22bd13f078a36ad196742eadff8a','deed4bbcf285a2400b034695ecc017fbcdf6a937258925e946f7e11b94052017');
INSERT INTO blocks VALUES(310220,'d78c428ac4d622ab4b4554aa87aeee013d58f428422b35b0ba0f736d491392ef',310220000,NULL,NULL,'614850f28d887d876f74bb6a8a141f3acfe292e8c497ee92edbbb91382971610','c6a8f7df5e58f15ecda215ebfce63d7010ed621e794730623a868858d0260026','f46434e5d1e0c2a5117767dd3a4bb0fcc08828d5cfa6c454eb8504332440f02b');
INSERT INTO blocks VALUES(310221,'cf5263e382afd268e6059b28dc5862285632efe8d36ba218930765e633d48f2d',310221000,NULL,NULL,'4029412bd7a8d2e082a448222287c1a402a57304809de3790216ddebeec0f804','a1fd4d9a01b4b716099587c0609751c3e35be84abdc834bf5dd23d9accd532cd','7401a7af17999de570ff7590dadf5ad46b60264276f18ce22948b12dec1d2b2b');
INSERT INTO blocks VALUES(310222,'1519f6ec801bf490282065f5299d631be6553af4b0883df344e7f7e5f49c4993',310222000,NULL,NULL,'57d5ae2e9a20ccf27eafeb39a868142b93135fbb226162e74d2ec13e0d8a1242','dcb3d1a603438e7a8f304cf82457dcd08999a9ee2d3f39934d20290cf7dbe1b1','19f46b4de4069e4224094f2d21eec4f7a115c0d149373925a7d600386716a3af');
INSERT INTO blocks VALUES(310223,'af208e2029fa49c19aa4770e582e32e0802d0baac463b00393a7a668fa2ea047',310223000,NULL,NULL,'8ddb59a6ba5d482dc470bffffa489d1a41c703932cd451248f963f8ef2912f87','29bf9d082795f57903380922e798cb96abf5764ce2828108945ff5562d5f4104','b7925e896ab390567ae53380d1c384a06b4456506e070a0528121cadb5922419');
INSERT INTO blocks VALUES(310224,'5b57815583a5333b14beb50b4a35aeb108375492ee452feeeeb7c4a96cfd6e4c',310224000,NULL,NULL,'7f628115f9319e8aa5233e3cb5bdfac389d7fdedf34b660644f3d9f6ce5aa791','21f68a2d3a483d53021b0e1dc53af6dfd2a4b227dcebf2c9aa85de09958432ee','bce204d53b466849620fa7feef1ab09bf6d335f9059e7cfafcdf9085fb2b708b');
INSERT INTO blocks VALUES(310225,'0c2992fc10b2ce8d6d08e018397d366c94231d3a05953e79f2db00605c82e41c',310225000,NULL,NULL,'2ee19ddabbd18e20e5416f2c14f4471c1c2ffa23fd18768f3edcd9e32ead4de8','14fd8d099a10dfaab2fa4e81c72de8c642664a6f64a6685d808e88ab3551fc72','fe05218a5038cf46a3566d92d312311718e3657949c91c99afeb84e38c2700dd');
INSERT INTO blocks VALUES(310226,'b3f6cd212aee8c17ae964536852e7a53c69433bef01e212425a5e99ec0b7e1cb',310226000,NULL,NULL,'d998e2dd3276270cdb45bb00cd2872c2db9374452c29e34559b6474152dd669f','22b26488277a6137f0cfe8402c861e662780dd73cdfa54a9516191c9036a4161','421b20d3c7205f0a7ed7b7acb71b8509f03570730a092e893ed90d9380152d9c');
INSERT INTO blocks VALUES(310227,'ea8386e130dd4e84669dc8b2ef5f4818e2f5f35403f2dc1696dba072af2bc552',310227000,NULL,NULL,'b326242b2921ce6dff797b110634acc19da685c7e0eb05d0b8922953c871bd3a','aef3a383f47aa92d945e1d0d5d704ba9bcfb0fdf3c64004599ea23f7c086d6dc','2a64b87d3bfd44594c09dbd7a2592d9e257253d49fa7490933ab74096224d74a');
INSERT INTO blocks VALUES(310228,'8ab465399d5feb5b7933f3e55539a2f53495277dd0780b7bf15f9338560efc7b',310228000,NULL,NULL,'00f4bc8c3c92e02f9d76d48475408ed71220d413e8a908c00ff931b2f21efc14','d1ae96992882ea88b2a728d80f939ffcf1c2d3ae7195a6c1e32e26ad6f05080f','792a9eeeb18b6b8637faaf0ab91d35948713b53283f27e552eca92b7150aff23');
INSERT INTO blocks VALUES(310229,'d0ccca58f131c8a12ef375dc70951c3aa79c638b4c4d371c7f720c9c784f3297',310229000,NULL,NULL,'4429047d52bb9d1fada5fa2aab49beba326b7dd39c18a8886dba6fff76033773','1c5833a796e2e144cc92278b3b2d3383beda487f3f81c9665e0ba16423976e59','55ba63eeab12df971c86252dc2a9b340e6494c452b3a5aa307101746b70c5dfe');
INSERT INTO blocks VALUES(310230,'f126b9318ad8e2d5812d3703ce083a43e179775615b03bd379dae5db46362f35',310230000,NULL,NULL,'a54ffd210dd02de679061b743d3d72d6e665ab06e3c8eee226f41d699e019660','f2e9967ee3eb18858efc2a9f50e41b08649f7d8f80a6275404f46204bd0d49b8','6e8c28c4bbf3d3aea5bd35d94ac008c35ebeceaa17415739fe85a5ff83edaf63');
INSERT INTO blocks VALUES(310231,'8667a5b933b6a43dab53858e76e4b9f24c3ac83d3f10b97bb20fde902abd4ceb',310231000,NULL,NULL,'54c041e58fd27f7a15ce3a3fca6e8f1718617178454b5b59ab56c31de8fd9294','1d5a7e1184a2d249207a31dcf711b601c45d612adff8de54b751654890253ad1','6b3c5259286f45c89ec3b9e65570dd86d63c4bf9b46433277b4148a40a79e9ef');
INSERT INTO blocks VALUES(310232,'813813cec50fd01b6d28277785f9e0ae81f3f0ca4cdee9c4a4415d3719c294e8',310232000,NULL,NULL,'bcfb38ffd70750af483721347dc86ab824b469827f7bf6fb9a76e0a455e8d681','e746047b0a2deb71ae3cdc856cc659a8d42c01dd2895bb42430aa656b9af5188','7a593c44b088abec136c726a1df9c33f8316e06a205fd8603265b9071eb5e584');
INSERT INTO blocks VALUES(310233,'79a443f726c2a7464817deb2c737a264c10488cac02c001fd1a4d1a76de411d6',310233000,NULL,NULL,'412125ac6e888a35c10b2139ab0d714a1362fda6036a7c2f61868cf5505d78cf','a43b7330f08dcd1f0bf5401bc107795c2ad421b1e1f9e1c0d82ebbb88d8d1315','d11d58cdd699a8b2dd9e28b3e3e87d46f05d23afd28a1fd928f2d4dc741c7196');
INSERT INTO blocks VALUES(310234,'662e70a85ddc71d3feae92864315e63c2e1be0db715bb5d8432c21a0c14a63cd',310234000,NULL,NULL,'dacde12b9b64e447ecf2f471de22b15cde1c9f79b0ac1fc589c5ecadf1b33b94','4322afd5805effa1b040deb51220d69068d38c912f718fa697d944c8e552bf54','00850a15e9ade0ea131a4479441237acad29299fc472a6aeee7aa9ad74620a5d');
INSERT INTO blocks VALUES(310235,'66915fa9ef2878c38eaf21c50df95d87669f63b40da7bdf30e3c72c6b1fba38e',310235000,NULL,NULL,'b04fbf8874c6f2c42399325f802769fd5e48e4977efe5b38cf81c08afd987d4d','c0140cad7a95e15f9cd4039082df1b495e7a7f519f4904def0c3ee5e2fd151bb','8475e42945e796fe682966d7058cfd4a551927f279ea7847c79781278472ebb1');
INSERT INTO blocks VALUES(310236,'d47fadd733c145ad1a3f4b00e03016697ad6e83b15bd6a781589a3a574de23e4',310236000,NULL,NULL,'28a5e3d2317b076eaa37f20046e12ce5288bbd1018176002345fa59c58486e04','2dd73467597566addc18366ea276c7f2cafd5c8735771771e36aeb11f754b6e0','1a05d91bec8f70fad9f738615ae71434d1692321c6800bcaa6d3a3ff5d43c418');
INSERT INTO blocks VALUES(310237,'2561400b16b93cfbb1eaba0f10dfaa1b06d70d9a4d560639d1bcc7759e012095',310237000,NULL,NULL,'97a3690c7b2e009a2faf6069234b45351896223a8ad879dd53ca644111841a6a','abb8d31a97e911cbd2f7097e34fe05d533004321e598434ebb199d3b66a2b8f4','c507f203dc6d3081f52e845b9722c0998f7dac67cb71d2875f4fb0e385dbeb59');
INSERT INTO blocks VALUES(310238,'43420903497d2735dc3077f4d4a2227c29e6fc2fa1c8fd5d55e7ba88782d3d55',310238000,NULL,NULL,'f795b30c29cca17ff344d9e412549359f4a3b5667f295400110decfb302dc6f1','4aef4a889298e9e8080ce3c89a7258ecfe05a9cb7926cd2a2294261682e75a1b','c863e12b0f77a13a8a321f83896c27723bcbfdf7cc68ab32083620b6dd8a47e1');
INSERT INTO blocks VALUES(310239,'065efefe89eadd92ef1d12b092fd891690da79eec79f96b969fbaa9166cd6ef1',310239000,NULL,NULL,'6c1bb10a0396093699db894023296927c14cb213bf3e30c61ecdfbba4dda8ead','ff962c868b2ac1e23e1bc1b8aa6ffa0954974d151db09d9f0a0450fe9c0a4c43','2d05a7c6a57540c6e6674e1b439c02ebd56d4b152226a5899a6891b043a3b641');
INSERT INTO blocks VALUES(310240,'50aac88bb1fa76530134b6826a6cc0d056b0f4c784f86744aae3cfc487eeeb26',310240000,NULL,NULL,'439af34c3d93070cfcc0b31ef5c09d30a2853b11c08d3e093eb10a195639addc','bf60ad67b84e87bfb316a30c3ae364528de346b4f70e2ce2b2dacc269da08f03','cdf2cd988975835fc5a125b64df5778298112d66a033dc7b18177e87d7b078a3');
INSERT INTO blocks VALUES(310241,'792d50a3f8c22ddafe63fa3ba9a0a39dd0e358ba4e2ebcd853ca12941e85bee4',310241000,NULL,NULL,'ca47512d43e05c79c18a57a3ea52c34f5fd5c25ca25859fa45d003cf2e114386','7691bf20872446734a340820b189146d3f84e965ef7ae3fc9316f9202a8ae806','48b5c1051a2f2f17c44f77992730b3be932e166280ad94e00de4f0efc2f77721');
INSERT INTO blocks VALUES(310242,'85dda4f2d80069b72728c9e6af187e79f486254666604137533cbfe216c5ea93',310242000,NULL,NULL,'5aa9ab70050143c497f02de6241d86744b72edbc3292d8206ad3efd179692990','b0ccd619eeb508d754066ae2bfb3f010fb84b810487d5034f8d127fefead3faf','2e8354db20db02df3cbcda4543a0d2aa3aaa1c4aabd1531160d577003e9f0339');
INSERT INTO blocks VALUES(310243,'a1f51c9370b0c1171b5be282b5b4892000d8e932d5d41963e28e5d55436ba1bd',310243000,NULL,NULL,'0e7307890e7621bde4544320e8a5e9a1e6d576ef999b34d3053abd5c478a2f69','deaf11b82cab770a5d7d8f7f9c70e8ca0dd063c2e01479318ea53be99b08c6d7','a59c52e7c640c3de344ee525dbb5210a80e7701a8961f396debc38adefb69ad8');
INSERT INTO blocks VALUES(310244,'46e98809a8af5158ede4dfaa5949f5be35578712d59a9f4f1de995a6342c58df',310244000,NULL,NULL,'c49b74cbe77d692ad808180fd79f5bf119979b5130183828393865a0b07f70dc','db6fbdfd5445e56e03579f29c1f853000a21d02f1d45a557038576b685631349','95244036f62b1f56b6c77bbdf35f6102428e581302374c7832c05c4ba86961d7');
INSERT INTO blocks VALUES(310245,'59f634832088aced78462dd164efd7081148062a63fd5b669af422f4fb55b7ae',310245000,NULL,NULL,'14c5adfd16869731464bca9505f39136090fa9a96374e724a79ea1ea482f42e4','55452294e2e9e44da195df3f05e1eb8c798490bed73a9d9310c281b465b1ed02','fa558fc79488710d6212e8abfe06a4b843fbf3fc27d825958d6e7220b568cfb6');
INSERT INTO blocks VALUES(310246,'6f3d690448b1bd04aaf01cd2a8e7016d0618a61088f2b226b442360d02b2e4cd',310246000,NULL,NULL,'ffed3d4e32b44744f63f94dc4016e44386d90ce73dc59bec1fde4a4c639f5a93','f562e5488788298a62dbfe50f9c442d1c5f7aa64ab35b64d804030a9f5280b19','a9fa15a71ff80804da5f55e1db902bc0c4a6dd7b28f602e7cbd88294e58dc27d');
INSERT INTO blocks VALUES(310247,'fce808e867645071dc8c198bc9a3757536948b972292f743b1e14d2d8283ed66',310247000,NULL,NULL,'2d9fd0ce77ef91b47eccbbb07df3fbbf1939204c7ec6bef0757590222baeb3d1','f1780dc2c4201ff174b4f695a1ff46676778b9c89bc505fb046bf4c5e48c1654','b14666ec6ba3a583fbc6580cd589ae57a071d37c9a279ef907a5f7bbc7f93ac4');
INSERT INTO blocks VALUES(310248,'26c05bbcfef8bcd00d0967e804903d340c337b9d9f3a3e3e5a9773363c3e9275',310248000,NULL,NULL,'27a5588eb06f95386fc0260358447c270de52b3f27add5c5a8deb05eb80a75a9','153dc02c9ed7f00a6895f6939a81e5d8536e3bb33b61c3edeae682fab240ce27','8b6dc5dd0e4820d208bb3bf97e7da3814c8f508e98c8165e379895a2583e7000');
INSERT INTO blocks VALUES(310249,'93f5a32167b07030d75400af321ca5009a2cf9fce0e97ea763b92593b8133617',310249000,NULL,NULL,'67f831e7d3708e9ec022c5f36d00b2a58b25ad8c4d1c06df3ecf68dd0177f189','88b72ec66bcbe260a327cac04376c6326b3414c8dd7e80b49319ca16a3a63545','08b21a4481ee83d319aa196a03bee4fd43630a6c4e0dc4614cd1c4d010664279');
INSERT INTO blocks VALUES(310250,'4364d780ef6a5e11c1bf2e36374e848dbbd8d041cde763f9a2f3b85f5bb017a2',310250000,NULL,NULL,'1b4370eef682191523be85c6196bbaaadf85b64588adbcd4a395a10eeeee7948','f63d4fcd835777a0cb4ecd34d4396527d11cff609510f29a4870fd52b7610a97','c92be237f0a579883090578244e2733daf81b0f76154b5d3bb29abcd386696ab');
INSERT INTO blocks VALUES(310251,'63a3897d988330d59b8876ff13aa9eac968de3807f1800b343bd246571f0dca7',310251000,NULL,NULL,'93e3bab3e8db9f5e22e706ab8f2822abb79a5fd18f580c46223a9a46e285b2fe','3d4276024fe3802ae02a6a38853f12902f44290cc18ba1754504794dfd5f1104','67923d5fe8070af3f47985adfa5abc374c5544c0f4dfbfdb662db12645fb5624');
INSERT INTO blocks VALUES(310252,'768d65dfb67d6b976279cbfcf5927bb082fad08037bc0c72127fab0ebab7bc43',310252000,NULL,NULL,'afe5210ec35d38fb4556ed358bd2d3ca8d5a61c20b1df91cb6b8a8ae51637da1','0c8f83ab4cb30b7d5e474a10644f8b9ec88dfe3960575fe527bab293d24e7fec','5734ac011b3882800b3da28ceeab9beb47766a000a2fd526612e0904cccf27ad');
INSERT INTO blocks VALUES(310253,'bc167428ff6b39acf39fa56f5ca83db24493d8dd2ada59b02b45f59a176dbe9e',310253000,NULL,NULL,'cdf601961c619db2f08cb30a31928e1d55d6fcc7e25608ce6d10619318f703aa','083e26631177e3d22d680a489ded88c6ae48ec394e3c152f9881befcd0fdb1e9','8dff4f101d7a1bcfcca7eb60566bc4f675dd8b7718143796b2c7c2ab33fb145f');
INSERT INTO blocks VALUES(310254,'ebda5a4932d24f6cf250ffbb9232913ae47af84d0f0317c12ae6506c05db26e0',310254000,NULL,NULL,'aeeb6af3664da553571ed505255ee8ae6b7216a05eb4a1378be027c791bcd5da','353e2283cf89b5e2f1f4ae046c887c05fd58770c5e05718305ae4048bfba5e55','f86e24f737a1242acc43e1d7f625b88193c982aa593717ec5152bc5a6ba1915f');
INSERT INTO blocks VALUES(310255,'cf36803c1789a98e8524f7bcaff084101d4bc98593ef3c9b9ad1a75d2961f8f4',310255000,NULL,NULL,'7e5fd9891eae9cb686a1d77f8a26ac467abf9444515f3ef3ff1fc7eea77ae077','67f645a3c37d28eea78eaebc8a3f1388431df76eb8dd1362df8b9d68587ce50a','8314f605ed29406bf0aae88d873f9f1efe85ffc6457e83fa026eb195455ea928');
INSERT INTO blocks VALUES(310256,'d0b4cf4e77cbbaee784767f3c75675ab1bf50e733db73fa337aa20edefdd5619',310256000,NULL,NULL,'8638fb05c65c1aa75a05e16c779216086f3551c6057660836abdcac483381c25','1621ef3bfe8f5b7c52792fab4380543a8fc499c5365f05a18bf54f65926ed737','7087d467b98852714e557805dbd04ff97baba2edd73ec29e46e27b27b21d82ed');
INSERT INTO blocks VALUES(310257,'0f42e304acaa582130b496647aa41dcb6b76b5700f7c43dd74b8275c35565f34',310257000,NULL,NULL,'5d9213bceae70da7beec6fc585b547232da5463b17b280f6020178f99837f3ee','d80251c737017c8dc96f72111326ad04c6c36ed098ef515e1ccb9eb56825f3fc','deab5080a740c3a21a71af35d99f5dfcf5e29ffdffb8f2ef190521ea4eef0c32');
INSERT INTO blocks VALUES(310258,'3a0156dd7512738a0a7adba8eeac1815fac224f49312f75b19a36afb744c579f',310258000,NULL,NULL,'87db5933fc8c6a241caf30e3d0d4830f762ce49c6d341790651ded692109c4da','ae0fe2c3c08613b721808f1c2d99f6c663801cb3e124c22afac999e8775317b4','c1b09470de1787a229720eb84df646847d8b5059a09394268bb4416eb9d276a0');
INSERT INTO blocks VALUES(310259,'e5ed3cdaaf637dd7aa2a7db134253afe716ffdf153e05672df3159b71f8538a9',310259000,NULL,NULL,'8215683693671c96051a9d0ad33b9a39ce2f5d77618c4c6acdeeffbfb029d236','42f4340b9b4dff05eab99eb89fe34a557797312cf2dc04a5eca7337109a9bda0','b15b2ebfaf18f285cb38fcb3fdaef857014952784a37f0c5ed688bfc43bb4340');
INSERT INTO blocks VALUES(310260,'8717ddcc837032ad1dc0bb148ddc0f6a561ed0d483b81abb0c493c5c82ec33cd',310260000,NULL,NULL,'b0b63bce75c934da17e2ad1926c3a9c9700081065b406eb3679f73dea7478e30','5a4b82bb0e87dfa22076b436e03b1d00574dfd8c8ffef3aba68c9b9cdf26d511','84f69b620f0653a5341fbfa7e2936a491a43de0d55955a5d33700adbde1bc752');
INSERT INTO blocks VALUES(310261,'a2a9d8c28ea41df606e81bf99cddb84b593bf5ed1e68743d38d63a7b49a50232',310261000,NULL,NULL,'0f7457334ac9b06dd42dfd1a5d6cfd8346a9603097180da9d596a1f64d99e849','cdc6717c45ed510481751b1ed18d0f04b3e00332f9e6bd01af9db05094c2bf09','fa6dfcd07223b69c16224da0b9dca031f598cf0c0dd07d365f944399b5f95608');
INSERT INTO blocks VALUES(310262,'e8ebcee80fbf5afb735db18419a68d61a5ffdde1b3f189e51967155c559ee4ce',310262000,NULL,NULL,'0a871578f8f63d705f7b99bcde2a8843f1c12bdad5bcb85313438e2cea3712d4','00a4cb18a832f4e8c72a3d216a577b83d40b63b70b15b41549952d0980df3a93','7df23b09af927d426204ede5be704f0e5511c8969c78376885b14d261f8c92f9');
INSERT INTO blocks VALUES(310263,'f5a2d8d77ac9aac8f0c9218eecbb814e4dd0032ec764f15c11407072e037b3c2',310263000,NULL,NULL,'4f7cc51fc0218453f1280a7f58dee4a5412a7d2d44c2c473ab35f56fda751fe2','2e15b49f44f7b3f0bb2cea772ae669490b1afa2110f5cb6fd2c7295730bb1ada','209d5d6d7e0d3de435d2822fa916a6d225a1fee5256ae0230ea131642df4adcc');
INSERT INTO blocks VALUES(310264,'ae968fb818cd631d3e3774d176c24ae6a035de4510b133f0a0dd135dc0ae7416',310264000,NULL,NULL,'f7f739a4813e86655ac5bf4ffce24506504c7eade4b5202f03cd059b2ce9d9ac','a5de9941ecbf5a522ccc3744d2ac230f5b96a29d44cc3b95bde641923a0fcff3','a9c4ecf0db101cb4e8b114ec994a3b6cf67eeee662425b172e6f56c395aeb718');
INSERT INTO blocks VALUES(310265,'41b50a1dfd10119afd4f288c89aad1257b22471a7d2177facb328157ed6346a1',310265000,NULL,NULL,'b2165b9bf43d717c115b5b6b5192295fdeb1159dfb53031011e8098213749842','7ee8c6758021c7807200a74ece7c42646277e16e4026fc67b2b042c2ca5da95b','d8b3d6f2ee11d73fe65a35ba1cddb4ac0ac501bae4b1d4c154cb59fbda79230f');
INSERT INTO blocks VALUES(310266,'1c7c8fa2dc51e8f3cecd776435e68c10d0da238032ebba29cbd4e18b6c299431',310266000,NULL,NULL,'38bc81474d73b6e235c6d597a28d23232acd8468d748ed16726a9203ed3c93f5','e7f49edb197f8c494332acef3293fa53369233b09ef5c01860f3a4776123c9b8','d6de91236820d36606358562463c7eb249dd597b48233afdba73560475f7e891');
INSERT INTO blocks VALUES(310267,'c0aa0f7d4b7bb6842bf9f86f1ff7f028831ee7e7e2d7e495cc85623e5ad39199',310267000,NULL,NULL,'cdc6224e982a2c7f6a169f6ad5bffa4c8682dd7a4d2a0a5cabfcb468f758278d','36e2f9c3b2ab6e8dc7cf7cd00ddaf0f0cee43f420ef5cff5ca51e0e6fde031ec','dd20cbf1e5f0246a49061642552b40e318f48d7fa82ecb6cf16ba36650048232');
INSERT INTO blocks VALUES(310268,'b476840cc1ce090f6cf61d31a01807864e0a18dc117d60793d34df4f748189af',310268000,NULL,NULL,'d89ec7f189d6316d560f81c86c60e67605e18561b73264609b14b7448535cd32','1e1f23865595477cfcd20b6a660e788cdba01fbaf805d282dc66c27a54398576','3e3760fb9b6f082983a15c03c7acc363a762593479b5440404eb7391e9509d7e');
INSERT INTO blocks VALUES(310269,'37460a2ed5ecbad3303fd73e0d9a0b7ba1ab91b552a022d5f300b4da1b14e21e',310269000,NULL,NULL,'280ce9bc029ad98c17722eb5009478e5ef1e6e6d90d04c1c744ab7d3118e0691','cfd3fb1d7a30c602433159a9bd969ca53d61814df74e302b6bacc8a7b26d91d9','b2d8b1fc39a9c151d27175a01864a4daf70b854c7c37985ffc84a457a42e4eac');
INSERT INTO blocks VALUES(310270,'a534f448972c42450ad7b7a7b91a084cf1e9ad08863107ef5abc2b2b4997395d',310270000,NULL,NULL,'abca2bc8255f9a84772eed4538b46fb9e7cf5b3d6edbfb0ac3662bcad6aabce6','f3895862431bbdcc6c6da23e58148564cb7a0fd0f4441a527162db5a74b32266','e03aff5bf1f2b4a7d8ff235f2f5a9c5237dd600f0ca58e805494b2e065fef3b7');
INSERT INTO blocks VALUES(310271,'67e6efb2226a2489d4c1d7fd5dd4c38531aca8e3d687062d2274aa5348363b0b',310271000,NULL,NULL,'a0d0fad47891bc7f16c88110165b524bb8677a5d0ecc7c0fa4139e56762e65ed','b8bc751122265ce49815abe787cb7794cf88d140344273c815e53b0040d8f097','775a46d1fc7260e39abf2c749492d02a803e522e384cd0e9b40c6041223c6892');
INSERT INTO blocks VALUES(310272,'6015ede3e28e642cbcf60bc8d397d066316935adbce5d27673ea95e8c7b78eea',310272000,NULL,NULL,'4b673e6e2b5d26c6a8dc6881986bbfaa7c18c0f6e5894a6b183139229863fbf7','6367d4b1c208b0f4d19b4a5456790643cb0b6ae6f01d692144df7d62cc487aa1','0bcb468da7f6784a9ecbe5ec78d8101f4d1fd350c61f71b434f9dcb75ed1eb1c');
INSERT INTO blocks VALUES(310273,'625dad04c47f3f1d7f0794fe98d80122c7621284d0c3cf4a110a2e4f2153c96a',310273000,NULL,NULL,'b834722d833eaf488b8a28259de3a16ff1914f73b93689f953bcd23a05084341','eb240a62e43431e7d4562da181c39d91a9661cc780a44e2964200a1f200f9b22','a786393de57445b22dcbf8e25edd1fb7f906fe847361a84beaf2b4b8e4e84994');
INSERT INTO blocks VALUES(310274,'925266253df52bed8dc44148f22bbd85648840f83baee19a9c1ab0a4ce8003b6',310274000,NULL,NULL,'e79ce81893b1b179cb46fc19c3f16ebf0f23dbd9f5d1b2b304db4321e5cd967f','f6f8062bc9d80953baef0e307282de3d4bb30a704ed38cc2c503f3d9736d559d','b7111dd0bbfa7da6b48dd67c3368fffbe15e1674304d5b48e24021cda5adf54b');
INSERT INTO blocks VALUES(310275,'85adc228e31fb99c910e291e36e3c6eafdfd7dcaebf5609a6e017269a6c705c9',310275000,NULL,NULL,'c14d1662897e072c3ada82bd03b071f81723051586f60dee87ea4a8d66c08a12','315abd5a20c0a265810cfa02c32a2fbf338f1023da5ad3f4c9782edf891a72d2','b2a687ca0d1b4a64be046c2ad880911f8381988683a776bd09d24e614d3bc69b');
INSERT INTO blocks VALUES(310276,'ba172f268e6d1a966075623814c8403796b4eab22ef9885345c7b59ab973cc77',310276000,NULL,NULL,'93fbdd2c91687b2ab64d76546fe4056897b090cfa8e775958b3727c4d34c760b','a7a1c058ebb361992a14c2cbd97e4fe1366781349667d1bff792814e2678ff53','9f95aee9243eaf79685137d8e7edd4816847b92921b7e587e6267bb5330891e8');
INSERT INTO blocks VALUES(310277,'c74bd3d505a05204eb020119b72a291a2684f5a849682632e4f24b73e9524f93',310277000,NULL,NULL,'9601dfecbff9a416fbb55bc45653b27a2d02b49e59535ce27db44cdefbde5475','ab9c31611ef73f7b50a23ba5c8a249ec14c2ce624f121d4fbb6b18899013fcf9','da72a938f68f4bceadcd1bff207e06a9dbc199c17a2aa2203d290aa9705971b6');
INSERT INTO blocks VALUES(310278,'7945512bca68961325e5e1054df4d02ee87a0bc60ac4e1306be3d95479bada05',310278000,NULL,NULL,'731d9d0e816b7469ffb9d3346d239c88676cd2bfcc6d9ce9b5b272f92bcbca4d','0a2ff40de1f267caa294f24466c74a5b31c35eca63a6a53beb08a9d495580c4d','c62a1d27dd5fbb2ae7ba70ff32895497faa3d06fb285e6f310b6fd8f4a52b41c');
INSERT INTO blocks VALUES(310279,'1a9417f9adc7551b82a8c9e1e79c0639476ed9329e0233e7f0d6499618d04b4f',310279000,NULL,NULL,'b3532e1dedac1585de0a039088303e03c01429d588ca3bf88107447edac4111e','9829a2a0468bc1202d88bf4113e83d816f70678e91d88b8f7e6f5a99bda19cfa','a8c0e56a9d0dbf79fde4fc1c25feed4146ddba3caf65f33e741de1eaa02bce8d');
INSERT INTO blocks VALUES(310280,'bf2195835108e32903e4b57c8dd7e25b4d15dd96b4b000d3dbb62f609f800142',310280000,NULL,NULL,'4d33f58684a1f4599343845c857f5282c1424205aa9027f05a0acb67d0f8961c','56add85a965e96d738861b0ff973335f7f8cf7443dddf905df6388b77b0988de','556d882205fe35503b15384f30e96750cec1ae8f86005a4a6836946ebb61b374');
INSERT INTO blocks VALUES(310281,'4499b9f7e17fc1ecc7dc54c0c77e57f3dc2c9ea55593361acbea0e456be8830f',310281000,NULL,NULL,'855b6f20ed079cbbf462da17fcaf08dc1f578a744a84eebbe143675f12c4332c','b0173749ed0eb4e89bd65bb86f98943d52cfc95c69e93538e5db005e78efe5df','93d65c94febe96e241d3fa642c4302d3e8bdc884e4ab17e2e62f5e9d5bb51e77');
INSERT INTO blocks VALUES(310282,'51a29336aa32e5b121b40d4eba0beb0fd337c9f622dacb50372990e5f5134e6f',310282000,NULL,NULL,'d68f2ccf24644bf6ddb50d9feefaf31622923a33e5f6e666f5976c79088fe8e7','30c590bc9ef702538fac0cbb63a970aa38e07b39c42f2084c9faf5761ba64bab','462becd09313b22f6bcc3cfe5b1653c3f94c1108578877f9157980adca677e2a');
INSERT INTO blocks VALUES(310283,'df8565428e67e93a62147b440477386758da778364deb9fd0c81496e0321cf49',310283000,NULL,NULL,'ad092a22d24107893e1b86a961ee775789d2f899c170c62d62bf2816801e0872','e45e426cf49b5b5d2bbf3587983a09f6c0fbf00608e32c84d0ff617c51cdac21','a6953576300ca682becda0c48049b91350836deef1dea553e439eb6c3f11b47f');
INSERT INTO blocks VALUES(310284,'f9d05d83d3fa7bb3f3c79b8c554301d20f12fbb953f82616ac4aad6e6cc0abe7',310284000,NULL,NULL,'dec3080fbb5b0d3aca99beb45408fb52f237266e447f151fb8be21b2f38e41d4','d47d8be9c3da9e28cfe2ceba16d65c65ffa4f3965168d50b7d80e2a9ba81cbbb','32d9f27c6704fdd95cd415a454f792768454349c760d5b427cd02a01295a89dd');
INSERT INTO blocks VALUES(310285,'8cef48dbc69cd0a07a5acd4f4190aa199ebce996c47e24ecc44f17de5e3c285a',310285000,NULL,NULL,'86040f7bd619eee3b9de0703ff0a7149c7454a5148a6d802582df1b0321306ef','2c501448acc583c8b33a8a5a59417adc6a9deb30f2a70ecd5a2ec9a18cf4f33a','0b221e37f1a4e69f0c3818cdf3d8487edc63659e5c45fd9268929d6bd5b351b8');
INSERT INTO blocks VALUES(310286,'d4e01fb028cc6f37497f2231ebf6c00125b12e5353e65bdbf5b2ce40691d47d0',310286000,NULL,NULL,'7ebf152a569705fc8fac4a12aa0dabb9afd16000a1a8c3917836357db3cae958','3032a9b5141008666703b4a047502b3f2b69ac3cf2fd6bfd6698832d501a4c60','4949acf6bd7685983b565d4c4775065800e176f1a1df6e722e570d683ef8a6bf');
INSERT INTO blocks VALUES(310287,'a78514aa15a5096e4d4af3755e090390727cfa628168f1d35e8ac1d179fb51f4',310287000,NULL,NULL,'55067f42fbf4a87bf4243f88bb60af2e3be3e4b594ade3b4bbdd0113adac70b1','002e627c19b6d87877d6daa36dc5df2abf07ea86645d24d097af3668ec32fef1','79a291128186df1d26dd3632552872df9a00f267ab7251460a1240330dee2398');
INSERT INTO blocks VALUES(310288,'2a5c5b3406a944a9ae2615f97064de9af5da07b0258d58c1d6949e95501249e7',310288000,NULL,NULL,'c382f4f293b7a8e14f9050cc9e08bf3efbcbd1238668bee3e5ef9d2eec0e54c9','069adb9c9c660aafb2afef00cabc435c688cc2f36a96a91b6c9ab16f1ac27a7f','044b0c08777e49dd8bbf16a69946212e6010b6cb47561b9f34b6ed06df91ac1d');
INSERT INTO blocks VALUES(310289,'dda3dc28762969f5b068768d52ddf73f04674ffeddb1cc4f6a684961ecca8f75',310289000,NULL,NULL,'902fb0fdb2ee978818ff2775db7ac9ad3c9b4539299f206ea720bb0086408a1e','6cd84645529cb82419db36a21e207e7b299fa2a8278afd960803fef5b9a7cd64','4631e06e02e1fcbac479d090b2b7b324b95e30ec3f07c1c1fd80e7db2cc0388b');
INSERT INTO blocks VALUES(310290,'fe962fe98ce9f3ee1ed1e71dbffce93735d8004e7a9b95804fb456f18501a370',310290000,NULL,NULL,'b69b14a48832720c64b5ff8f29fffbd117c11862fac1c93cd7335e923a5e6678','8ccad423c88583a70465321b2979b292b357e041693ee5766072e000209ea4ee','c2fdf9e66874d16bbe2b9aa3e5e9b4d88702d338083bb018b8b2ee56c965afac');
INSERT INTO blocks VALUES(310291,'1eeb72097fd0bce4c2377160926b25bf8166dfd6e99402570bf506e153e25aa2',310291000,NULL,NULL,'5e9cfc90b12dbd01fb8045b7dfe215bae95a76ec0bcb78a7a0682b83ee5c4438','e567ce02af7dc05061cc5898c68f3be423160d8fb18bb13aa6cef0f62f246dda','bf065d2c23e43fd62ae58ad7c8a5bf98d495fe8c67da3fd5a3cee2abbfecaad5');
INSERT INTO blocks VALUES(310292,'9c87d12effe7e07dcaf3f71074c0a4f9f8a23c2ed49bf2634dc83e286ba3131d',310292000,NULL,NULL,'1cda3389dc2d4f0517bf24258664925d56b95f3e5ade498dea0f5a375c48ec19','1ab19185a4a9ec166983c07f6a743a16f001dc6b5e6c6e2a85a55739c061f7fa','51bae58499846d179ec923058a7aaf6a4ee98f3c08b6f3a59106ffc260de82f4');
INSERT INTO blocks VALUES(310293,'bc18127444c7aebf0cdc5d9d30a3108b25dd3f29bf28d904176c986fa5433712',310293000,NULL,NULL,'b966a9211d2a60f8ab509d318b456bf1ba4f4680f7eb7fbe8144d569c0124507','4b85a916dbf93a7637c66a15dd896ad9eef871477609521d02b8923d84364caf','1bda9c945d394fd537ecefad373839d4d2d0ce1a3c0cb89f201435a97a59734b');
INSERT INTO blocks VALUES(310294,'4d6ee08b06c8a11b88877b941282dc679e83712880591213fb51c2bf1838cd4d',310294000,NULL,NULL,'bc23c8c1a57ab6099ba111244faa50cfb2bea0fee8b0ff4d636ec84b71159cd7','8598727464afda96709370788049afca3880b95a449b74a215e488b27fd5f2d7','647e1c14385b6db4325ca80606ca52cc026f41e086c963a59799a7f957df8b60');
INSERT INTO blocks VALUES(310295,'66b8b169b98858de4ceefcb4cbf3a89383e72180a86aeb2694d4f3467a654a53',310295000,NULL,NULL,'37d89dde31c22b28a945ee9a31599713d7911ad4e1539ce40fd8500eca3bbe7b','a96c17e2cc3bad3ffee9f83986e96f399920a7f1a9d32d538e65312deadadecf','ddaa6e8c1bb00090dcfec75ed9652175be7b34fee5d134be87b9ec68ab539f27');
INSERT INTO blocks VALUES(310296,'75ceb8b7377c650147612384601cf512e27db7b70503d816b392b941531b5916',310296000,NULL,NULL,'9c78603f612541ab910a857c93a9adeff5faff187042dffe88824d4812dc3c54','e5c97bf63c0641dd40595ae0e6083acf35a4df4db89010efd099c4cdaffd7591','c4a6f8e315acf602d20593d9ff1e446eefac9a81b7d20ff2d64453ce2d042155');
INSERT INTO blocks VALUES(310297,'d8ccb0c27b1ee885d882ab6314a294b2fb13068b877e35539a51caa46171b650',310297000,NULL,NULL,'da67aab16effd61a9a55f6e73cd2e151b36c0acb0b813c387ea5a15f881406a9','60135bb4ba48c2402bc766fc7fc9b0c3d5fd665228684f0cc8003015dfbebc1e','a653fd54df442229cd75d0a4c549bc4b0868445fdfff1b50e5a2b86a7050ac29');
INSERT INTO blocks VALUES(310298,'8ca08f7c45e9de5dfc053183c3ee5fadfb1a85c9e5ca2570e2480ef05175547a',310298000,NULL,NULL,'3805cb37be4090d575bb0f75a1aad50975f2656748b0b59ccd03dccf436ea00f','1d673ae2f85e3a5d757ae17d258301cd87ba753166c4061da94a48acf1df77df','12491e2a2a939634f48d215714264a533069770a5ae1aa384be19f2006042a06');
INSERT INTO blocks VALUES(310299,'a1cdac6a49a5b71bf5802df800a97310bbf964d53e6464563e5490a0b6fef5e9',310299000,NULL,NULL,'b2b1646a5b7df20bb1657b7a9945b3b85ed711543aeb53abe2cc2af7d9c6567a','b8af510d7a811d74e439cc9173c2f2f35d65fcd1c377b6e41a39cc69facd92ce','6f56a5dd0d8814f4d8fe1fa0778606b4d0b7c0e3469093fb50351b222062ed3c');
INSERT INTO blocks VALUES(310300,'395b0b4d289c02416af743d28fb7516486dea87844309ebef2663dc21b76dcb2',310300000,NULL,NULL,'6128c4cf42c42ad9f74c309a680ed1370078b2488a1ecb170a50eb5b08b4e790','56c4057e37d3fb4162e14fbd6f983b52235139ab6bb8cf642ab239ce2b6c5744','eb6f8e61d9ab65af9e9d7a5887932de73eb4b78a7b2f8cd77fd628a27b96c20a');
INSERT INTO blocks VALUES(310301,'52f13163068f40428b55ccb8496653d0e63e3217ce1dbea8deda8407b7810e8a',310301000,NULL,NULL,'8066782bfc8f67fa95ff6c63a13e345465272ff82328e3f7dd2fabf1a6bbfeac','682ef22263edb33039a0b7e2f0b3f05067607ca4afa04e0a02f43842150552ff','dce8a22cc3aed50fb8d625f0323fa393a48840a85188f915b74cb42e2015e912');
INSERT INTO blocks VALUES(310302,'ca03ebc1453dbb1b52c8cc1bc6b343d76ef4c1eaac321a0837c6028384b8d5aa',310302000,NULL,NULL,'e10f8b1fda1039deed31c95435b46f6b19f493d860b4a2eedb88dab270b511f1','e1edfd178a4173d29b019a4bfbb9c9ac4e9b4da3dc19679a433256510669e5f5','cc3e3f9d57889f1c3aa206f6e5ccc7b9d3d58f1bc6f718a2461b9e86b93205dc');
INSERT INTO blocks VALUES(310303,'d4e6600c553f0f1e3c3af36dd9573352a25033920d7b1e9912e7daae3058dcca',310303000,NULL,NULL,'79fdc00b3409bb4e280f66b433f5d2c8f08467e399bc299abad378960c77380d','b0f216210667847b839b0f249c7751d60df2da068d76802eb71f37c7b4730b74','643742ab4302fe19ab3c9881ed38deb43ad75d4330c3fd4b7e6632f81e038046');
INSERT INTO blocks VALUES(310304,'b698b0c6cb64ca397b3616ce0c4297ca94b20a5332dcc2e2b85d43f5b69a4f1c',310304000,NULL,NULL,'3597237a25a8b9135a96853b2e0ce7c0a0c44250cda7684818cc0da6f4dd03b8','2b26e335fec2756d3946d559c624d37d8142cea5ea121d4629c9021c35840f34','9a0db04c8859af593cdaf7294df4e0bdb673ebb551e5b3bcbae53a5e00b92e2b');
INSERT INTO blocks VALUES(310305,'cfba0521675f1e08aef4ecdbc2848fe031e47f8b41014bcd4b5934c1aa483c5b',310305000,NULL,NULL,'6e56948b7312126772c1ea63e0cf98ca05b4a6e38eafae533ccf48b59d549768','2ee3b58816204493262bcd3801c838d9a2cc3b6ee33bf5f36b7ffed95fa89c2e','59db164e7be0b6cc5a086d2960d07ff69f295a2dd03204019da8478b4a99a1df');
INSERT INTO blocks VALUES(310306,'a88a07c577a6f2f137f686036411a866cae27ff8af4e1dfb8290606780ec722a',310306000,NULL,NULL,'53da52d2e62d227319056915a85809815a88a2652429effce10ab75bdf4627a0','82d669a7a7ac4224a3e82ccae083b263f1308542d18998510d598df3bb3a968c','df0e87a2564878c9829cc1a38a5e312dd4b2b36734b3b56830b8f0e658178fea');
INSERT INTO blocks VALUES(310307,'bc5ccf771903eb94e336daf54b134459e1f9dd4465dec9eaa66a8ee0e76d426c',310307000,NULL,NULL,'c681f768d9e6f550f4b8f8fc40a22db05f2a0113c1d69fee6a4c98354df94857','a795152ad68b007582b7f84433d660b8115b4540616826cd226be7eaa09ae515','bbafac23f6dbb814cb8cec4416dd2c153816f39902e95f587d9110de452c3610');
INSERT INTO blocks VALUES(310308,'2291ffd9650760ff861660a70403252d078c677bb037a38e9d4a506b10ee2a30',310308000,NULL,NULL,'72c9fb4a94420f9dceaff22f38e7824057466c6cdcf26c5d0f28793ea87d6f97','dad1223bf17d9b875fa443009918f39303d3cdb42398297fd20f7b3bcc2f0f56','153c02185be86cf0aceb2c6cc5210fb127695409c2cbe06cc156d08b91ae98b2');
INSERT INTO blocks VALUES(310309,'ca3ca8819aa3e5fc4238d80e5f06f74ca0c0980adbbf5e2be0076243e7731737',310309000,NULL,NULL,'66e60b5d6fa0c2df4f51fafed4ae913e96491842ee877b4436e8ee6f9ae9256c','21b1c25859dc9733e66b58e5adf3fb168812c096191c2b1fd9cff7ab8ffde31f','f27ed7e9425e637b10b433bd719d39309685c46ed7ca83c7308865c71fe3ea6c');
INSERT INTO blocks VALUES(310310,'07cd7252e3e172168e33a1265b396c3708ae43b761d02448add81e476b1bcb2c',310310000,NULL,NULL,'6da8a63ba1c6719652f405f94f56f9fb7c01b4e14efb3fb64725128ff38b4d09','2fb2d32fe2def3c92f5d23fe3caff99d57aa93e574559424a17dc69c05c03135','d8300c356f6b1acd4642739ac3bafa191effbedffc5f998d31aeb2c771492605');
INSERT INTO blocks VALUES(310311,'2842937eabfdd890e3f233d11c030bed6144b884d3a9029cd2252126221caf36',310311000,NULL,NULL,'bd416f7af4475b9df19005d181a87a9c035d1f0195b65eb416d8a84747390686','331f1366cc9cd0e7342a2d4aca6d09cf7cc5d5a65f5d36ae6a8e25dc23e87f3c','58689701cd88c1b721263c960db141bab8a743b5b89a90c0c9b2483c65f7f1b0');
INSERT INTO blocks VALUES(310312,'8168511cdfdc0018672bf22f3c6808af709430dd0757609abe10fcd0c3aabfd7',310312000,NULL,NULL,'2a4b5b1e4c0d13f2bcfc88623f6cca4ee2fb4d1c8be2ac2a56a7639ca28e39eb','f995c3b4ad3f9326b306f974dd768f2a146ceaa08c3d44ce3e496f65e694be84','472d3d9a52b0d4e930ded3da52261937b922ff8086c0749dd70cac6f9d12f3da');
INSERT INTO blocks VALUES(310313,'7c1b734c019c4f3e27e8d5cbee28e64aa6c66bb041d2a450e03537e3fac8e7e5',310313000,NULL,NULL,'af3e82d1281594f4c3d07de7f94925f72b60d82e68dac9e11de5dfdfec78e4d2','d629a4cfd5a3418447048fc68cbc893f34e5cb7bb93757f2be62c8c38422900a','68f12deea49090ebf875ef68b2e899dfa2b30f45b0c0f4655e494be0732a30c9');
INSERT INTO blocks VALUES(310314,'1ce78314eee22e87ccae74ff129b1803115a953426a5b807f2c55fb10fb63dc8',310314000,NULL,NULL,'cc061bc7415f2f68db5dcdcdf4c20c4c6c5f83780e065a3b9e53e9709ececb07','26a81aa8134c10d66cb4b86f4981d3fbd1a47ba7407034ac6daf8c3d5c8d587f','27ea8b4eaf3b98a2cfb9354e6474eb287d993e3d26209c111b424c7d2888ece4');
INSERT INTO blocks VALUES(310315,'bd356b1bce263f7933fb4b64cf8298d2f085ca1480975d6346a8f5dab0db72cb',310315000,NULL,NULL,'e141ee74bbf64d2573aa03b2a09c660b1523b10e6405aaf817aeee6ae11a6a96','222763992824970b909a8e571633cbd0c01a73b80f2a1a0890bb5842e456c83f','62841d321574d5336fc9df396f3a4e05284e364f7f4138855ac936916970f7fc');
INSERT INTO blocks VALUES(310316,'ea9e5e747996c8d8741877afdcf296413126e2b45c693f3abdb602a5dae3fa44',310316000,NULL,NULL,'b8440ec2e1123412fa2a8030534f6d35a2ae1effaaefb85e9e63b9c62ae0113d','fee0caba70900885a769148ed74583d08d0d2afbc1dbaca273f40b604064b212','356ea26f2bd37d2cce9bfcefa6b488cc4f7639e5ac51735740669bcb110d9286');
INSERT INTO blocks VALUES(310317,'aa8a533edd243f1484917951e45f0b7681446747cebcc54d43c78eda68134d63',310317000,NULL,NULL,'538519849e9ced8aaae7a239d94af88451653986f15ab69d283499fdf435cbac','8f1b04ff57c888b73591a9e89b10745b7f58d1c149383599a9303575a3c87fff','084519893cc900aad7a2684972876e3e799448e1a5c284d0a91336a4ceb9fabb');
INSERT INTO blocks VALUES(310318,'c1be6c211fbad07a10b96ac7e6850a90c43ba2a38e05d53225d913cc2cf60b03',310318000,NULL,NULL,'690600c7d47177ade62975cfd5a632875689bd1627bababb069aca769ae9e58d','f4cb219a6c13002e8dc8b3491e4cd006f164d8a053b0be0eacb968ec37a1fea1','443554bbea9074f97138ac46519cdc9630a27e2b6519e9fe4e6bb781946c7a92');
INSERT INTO blocks VALUES(310319,'f7fc6204a576c37295d0c65aac3d8202db94b6a4fa879fff63510d470dcefa71',310319000,NULL,NULL,'1fd15e66409abe2934dd922ca2028b4c2ecbd001f77e9047380cf5b55605ecc1','93fc8d0888c4c26706574cb5e83036c4c01483055aa766f137e2bd55bc54c022','baa6331fc05b312a2df826eb023a41a15b70a5caaa609562b557aef684b0368a');
INSERT INTO blocks VALUES(310320,'fd34ebe6ba298ba423d860a62c566c05372521438150e8341c430116824e7e0b',310320000,NULL,NULL,'e864c01bfec22c119a59c1a154c9d49711931c995d7df483e19c0a514da72baa','a634ab53aa2a660ef4043041b1bfb969a68a44ebdb0217db026c82eddd5eac66','fa8aca805d0e0034c5b80bb89f86314aa9dcb479d4daddf8017c7e4612fdf20d');
INSERT INTO blocks VALUES(310321,'f74be89e9ceb0779f3c7f97c34fb97cd7c51942244cbc2018d17a3f423dd3ae5',310321000,NULL,NULL,'096086a9182ed81b8388e10981a6b01f2fce6ec3ec0c8a5b87da52b24df47e0b','568fe1b224f3ef56d7bbec7c0d3bbdbe2da3322db29232db99c0dd697429574d','7a7dc7bcdca4d39686a5a137ba119d968d2879d4d5f4c9f3dd9901c8fb7a7ce3');
INSERT INTO blocks VALUES(310322,'ce0b1afb355e6fd897e74b556a9441f202e3f2b524d1d88bc54e18f860b57668',310322000,NULL,NULL,'82c13cc3c7ea87e59249bd2456c6c4a7d084dfa1158f5455fb2251f23731dddc','7a1421011f74f6d8b4a33442cfd2ddc558ed12bd526887197d1f81cc6b4a129b','cbf81c0c199bfa5ccafcff6eacee30de414ce265291f406aafa508ecbf125862');
INSERT INTO blocks VALUES(310323,'df82040c0cbd905e7991a88786090b93606168a7248c8b099d6b9c166c7e80fd',310323000,NULL,NULL,'8050520dde76b54978d0d54f31589b5c1d4d798a8aca0fd7836b5516e66f3dcd','1fb31c3596cc6361fefb07e695cbacbb3fe899208cda10380ee62077cd34f537','37c90dade24e2b70f2afdf67fcb4698041902d677a4b372dd518380b2bd6aa4f');
INSERT INTO blocks VALUES(310324,'367d0ac107cbc7f93857d79e6fa96d47b1c98f88b3fdda97c51f9163e2366826',310324000,NULL,NULL,'3329279722a52d5179cafdfbbe031d016306b6a7eddbbea3903e59c761b74cba','3a9ac4ec0527373e07a1b5ba0e8e46df5a9812546011efad0c68b69e145c79f2','7bc6f2a518e615b3c38fcc587eb104007a36c6129c256dd44f47964d5f645973');
INSERT INTO blocks VALUES(310325,'60d50997f57a876b2f9291e1ae19c776df95b2e46c14fe6574fb0e4ce8021eac',310325000,NULL,NULL,'1070254673eaf1bb90f685e2fb9d05e9bba7f418da2b3b14f4f786ddaa4b8a30','fce78cfbb3ffa4893f7f33bd976cc6e4c80a3d7d00848f1ac6f931576ac0fdc0','fcfb2979c7f5673470d73873831c23023b5fc05621276954cbabdd50873ce5c7');
INSERT INTO blocks VALUES(310326,'d6f210a1617e1a8eb819fc0e9ef06bd135e15ae65af407e7413f0901f5996573',310326000,NULL,NULL,'e202649e5bfe436c5d7ccf7f99a2b5a7cf9f65ba87d01f098b32206504c9955d','f7e7625adfe7f9d79d93e868de99927caf867790b2dac557783fb0bcab22653b','fe59e348a7eb539731a6b913bb720527220f01f3ccc326a3ff36b663edc195d6');
INSERT INTO blocks VALUES(310327,'9fa4076881b482d234c2085a93526b057ead3c73a6e73c1ed1cdee1a59af8adc',310327000,NULL,NULL,'9ef3626eaba8b92a9f399894c80792a374dd3f08f062f5fb689571cabca2260d','634456e5650cb1bbd0009fdec5b8abb3a14c73c19130da4705b840a20b9ab3b9','a5ba5dc4bc83e4192e4d7fa51fad0109627f346920afb04f11324e1c7c7ab446');
INSERT INTO blocks VALUES(310328,'c7ffd388714d8d0fc77e92d05145e6845c72e6bfd32aeb61845515eca2fa2daf',310328000,NULL,NULL,'07a505327ad6bbc4c683bfc14560b521e1b8ebfcb162fbe293c2c69da7798ba4','bc6ceb45463de6393ae250e9ae5a3822c47185a926fdb8331d9e13b8a0c69c99','bbe1e4810db6211310bdc65e32abf5ad9902c4465c514a56a3dc98796d240490');
INSERT INTO blocks VALUES(310329,'67fb2e77f8d77924c877a58c1af13e1e16b9df425340ed30e9816a9553fd5a30',310329000,NULL,NULL,'2620ba5a247ebd0295ee40efe7c8911bee66c3e18fd6fefc61a9d6a542dd2136','627f893169cb416de98d0c205e90022be526e7d61c256b54bd48217772ab1e9d','1a2fdf6b53ae151a65ca7b0401f2c6f01902710a96225a7b57343f4d4c7418de');
INSERT INTO blocks VALUES(310330,'b62c222ad5a41084eb4d779e36f635c922ff8fe275df41a9259f9a54b9adcc0c',310330000,NULL,NULL,'169eb0d3cbd0d261059426128664172facf85cdc2ac67360bc710a1a2862876b','c095e883513d136a30650f8a8e488c5b415db6711ed927f041a88e7a37aa280a','ee94ecbddf29132b11ce265f708026df61d94aeeea4e470197f407ca37c6a978');
INSERT INTO blocks VALUES(310331,'52fb4d803a141f02b12a603244801e2e555a2dffb13a76c93f9ce13f9cf9b21e',310331000,NULL,NULL,'3d755a4ee7eb8eac0411ae456b181621345404e89e44bcdb6ffdbe62dd54766e','2f8d271e9300a06f503d69adec06f4fc9643a51a072a75dcf203fa1a0b6e0ca8','9766c99dccbdfe1f09da031c3858c67f29365620f9a3a50088417b52e47888f5');
INSERT INTO blocks VALUES(310332,'201086b0aab856c8b9c7b57d40762e907746fea722dbed8efb518f4bfd0dfdf2',310332000,NULL,NULL,'5be90c696ec52d15d0d3a2f083526919ab347e9e6aa4a570ea27d76ce6dc7fb9','79d2a997e0574ac510d4dcd247bd9a9b383794da4820fc39ec16d9859094c0ee','6abe830d224a07d91833c458c6f1280a0b86268713ac2dfbc1021d223a318d30');
INSERT INTO blocks VALUES(310333,'b7476114e72d4a38d0bebb0b388444619c6f1b62f97b598fed2e1ec7cd08ee82',310333000,NULL,NULL,'ef9d3849d24683a39b59e54c1aae4c94b5851c24639b8a6b96259bd577a2ad74','772fc4b9104187f95bd3b10c6707edd730fdf5c4352a3e23e516af27abc4c4d2','e88e480e3ddaeb5d62399bcc8503b4f718ac8f8aa77c55a2d5e122be245ec79c');
INSERT INTO blocks VALUES(310334,'a39eb839c62b127287ea01dd087b2fc3ad59107ef012decae298e40c1dec52cd',310334000,NULL,NULL,'3c915aee8c756fb0a7179b7964e6eec1abcbd1041a1545460d38462364684958','4a1f4079b81111b603b71aba1b92192532caa8113f220fc148b7c8ddd184799b','60b53d12227a3a7b67f8ee75ac1799f4622be19725b8221ee41ec75700ea4794');
INSERT INTO blocks VALUES(310335,'23bd6092da66032357b13b95206e6527a8d22e6637a097d696d7a96c8858cc89',310335000,NULL,NULL,'70bfef97c118317cbefe631aa022b1e0ffd056c096a6b2deff5ea13ab101c1f4','e108af17aeb733547bf755f27053c37b5d88d9355b0888ef5c431fbe8fbc6446','d4a79d0890bd4c18ed4518d0ec17ad917dd1e087c83a72640bfba7b1a439f460');
INSERT INTO blocks VALUES(310336,'ec4b8d0968dbae28789be96ffa5a7e27c3846064683acd7c3eb86f1f0cc58199',310336000,NULL,NULL,'bd52821b02bb0570a870b950f6c0ea5546281bfe1138f2978c020f5421a8bd53','3ccb7d53bd6da83084a1096c9bda063986825810406eb1483af5d5bf5d9783b2','46841dea0d3a8beeda6140e3874fbe5d63a2078dc1f62741d69843de66d449a6');
INSERT INTO blocks VALUES(310337,'055247d24ba9860eb2eadf9ec7ea966b86794a0e3727e6ffbcba0af38f2bc34a',310337000,NULL,NULL,'4d998c7c5755d94c46fa7c6c7f7791c9258726d626b74eabab67626edbfe9532','d4079b8a52f1309d4617b18a3302680651f639207d77d44ab95d028c0181e924','c8c3bb38ca8931904ba68fa373ad5237d4f6b8bc51b653d0d22107f921385dab');
INSERT INTO blocks VALUES(310338,'97944272a7e86b716c6587d0da0d2094b6f7e29714daa00fec8677205a049bcd',310338000,NULL,NULL,'3740697e86ec44204a339a8827c8887b5dea8e14de2a77da6e3a777518fd3d8a','98d4e0e65033af00481c8b3e5813049d0bb36a86da79bb2bcc2b4ce8d8860a1b','c1b92f698804e03425dc387cd9db1c1551a4e811c8df38ece4686f92fc9af1b1');
INSERT INTO blocks VALUES(310339,'99d59ea38842e00c8ba156276582ff67c5fc8c3d3c6929246623d8f51239a052',310339000,NULL,NULL,'7d96412a30a7648bec3fe11198ae04404097990502372423ad19834b7b19442f','fbb0a96a28aac15a45d19b2d941c0e2e755da619cf52bad6db5817d68ceaf7bc','169930044f97fe94a6c47e3458ec1f5b9f4697d8e4059e3e0ed9e16a2966f49b');
INSERT INTO blocks VALUES(310340,'f7a193f14949aaae1167aebf7a6814c44712d2b19f6bf802e72be5f97dd7f5a0',310340000,NULL,NULL,'da74536dba0582713e235174e67108ac2a285e946366cda2fb7f51052296c6f6','41ecb9a3d5e2c3e9e6dc4ec7f0589d6c85cc3ab6d79c1a0c2e892ba2ccddbace','f283522441d0eac748bf4caa560898e30ee48c37672671da813781784faa5d82');
INSERT INTO blocks VALUES(310341,'6c468431e0169b7df175afd661bc21a66f6b4353160f7a6c9df513a6b1788a7f',310341000,NULL,NULL,'cc1ebe14893ebcc3a13c61d7e4465f1be81f13626152e134ff51dddd1ae66a4b','03f11162bf0b983792c9121a9cfa46d69370f5871db3ba17f63093f1ad0d362c','6c4b168a886d1d93118a2fa27f73acf3be8ec30851e2d33285373ef11874248c');
INSERT INTO blocks VALUES(310342,'48669c2cb8e6bf2ca7f8e4846816d35396cbc88c349a8d1318ded0598a30edf7',310342000,NULL,NULL,'6b6de51e4d1ae0ff8ae523a3426a281f3a6a2c02631426eaac1e522b1d2bb98d','2059c682d529381d7db8c7afdab7fbfa12e0babe6aa9d82fe03332669e644ca8','60a311413723886d612b00517f0256cf8a95a802074a382d8d37e40ff01ed7e1');
INSERT INTO blocks VALUES(310343,'41a1030c13ae11f5565e0045c73d15edc583a1ff6f3a8f5eac94ffcfaf759e11',310343000,NULL,NULL,'cf6e941df1cec80904e2bb9aacae28a06071e4c5f0b2b11ed4e1b083ebdcc1e1','ae8e3fbf2f743e51ddd2185288c857fe4288c392227df4f8299d395429728621','b9908fc92e98eeafce2dc83258099c301e3d2ebf80bd76cd3e7da3ad02ae3fa7');
INSERT INTO blocks VALUES(310344,'97b74842207c7cd27160b23d74d7deb603882e4e5e61e2899c96a39b079b3977',310344000,NULL,NULL,'dc429ab9d501a49f72f75a1d8def7f57ce4cb7f6025536796ef848ff2acf6956','154e21c486263b082a24b9f26ba25bc5bb3df02121e26ae952a99aced980ab00','4f9656bca13d5f018ceafead63c43fb8c897052cda92c5462feb842e8c74de1e');
INSERT INTO blocks VALUES(310345,'0bda7b13d1bc2ba4c3c72e0f27157067677595264d6430038f0b227118de8c65',310345000,NULL,NULL,'005f9980d6fa7b9caf440c03077c1c2d09869c5e8966ff80881d2d614db066a9','659bebaf82be572f29a408eed496cf759e852c7b5155bcf6cc190ea646e38763','9732ace5f5ed61e90516e9bdf4301844a210a74c047126fb1d5551b41cf975ca');
INSERT INTO blocks VALUES(310346,'0635503844de474dd694ecbcfb93e578268f77a80230a29986dfa7eeade15b16',310346000,NULL,NULL,'a35010d23486a48ba503bfd83f95ec182a5f0aab94790042f0bb22d24eda8cee','4bb3546b88fd26230f11df29904a298d90a6b97629513feb0b0c432616f95819','17a61fc3315c1a19860699f86788eb8d311012cd7ef545364a3cb7942ff8ee27');
INSERT INTO blocks VALUES(310347,'f3f6b7e7a27c8da4318f9f2f694f37aaa9255bbdad260cb46f319a4755a1a84d',310347000,NULL,NULL,'afe0f4147688b94a8f7f028228bd4438ae9ae32e8fc7484bd2d71d7e1e186b8d','3863a8c1ff57721ece83f162d51386f5eb099fc84d0d61c5c096c39c520036ee','8e3fe90f4700c11a58d6469c048eedda7cc2f6ad9ff2beaa62d5a9de97a11eed');
INSERT INTO blocks VALUES(310348,'c912af0d57982701bcda4293ad1ff3456299fd9e4a1da939d8d94bcb86634412',310348000,NULL,NULL,'c7383960d8a947aba3c1ba4157f96f2c1bcb8fa2b6238cddcc85941c24b6e20c','51df8b3627043bfb38840dccf55ffb0366b07da70b385afdd25b69238a45d714','f877b54a86f352e904bcb164a4cf22c2b053b4d0c4d492de989171dd8e4cc3db');
INSERT INTO blocks VALUES(310349,'ca911c788add2e16726f4e194137f595823092482e48ff8dd3bdbe56c203523c',310349000,NULL,NULL,'41066e93811deac0164ced956c8ecc2cf6ed49e831ab9b0f5f61b7bb97f5c583','edf2fc7b43a01689db50e81e649c9d485b327cc5f7840bef8da2b147d985e640','e27cf4b68ccd413fd9a670dc01a4567313e79dd06e234f9531850ac5e61dfddd');
INSERT INTO blocks VALUES(310350,'c20d54368c4e558c44e2fbaa0765d3aecc8c9f01d456e3ff219508b5d06bd69d',310350000,NULL,NULL,'d2343f590945ea41186ccb93ba6a1630b66b3216ad3978b43c1b5d105217cd6d','61b1a062834cc60267214b342b1d033f9da4b21ebb62b9ee0a081e63cf3d5ec5','f967d94e8818139b2f4db0593e917647d9de969466890e2ac3495003564c71c5');
INSERT INTO blocks VALUES(310351,'656bd69a59329dbea94b8b22cfdaaec8de9ab50204868f006494d78e7f88e26f',310351000,NULL,NULL,'290870196fbb96760c62cfa3d2072e7432b7f3fcb12f4a714150ee9bc9e95095','b4482a25d7e93f585c11e0977e8b4815196209ead96e7ecf92084ce5fea9055e','2fcee084cb68cd0a6cfe1bfb8c51df8de44592482bbcd94d41ed8f56b44411e4');
INSERT INTO blocks VALUES(310352,'fb97d2f766a23acb9644fef833e0257fdb74546e50d9e2303cf88d2e82b71a50',310352000,NULL,NULL,'8bd069ac4f828cac429fadec8a2aa2a024aa70d7b60274dee16879d4bc7142e2','aa7c0a6ea64693ad9ec0acfb50ea24677234a3ff0206c2de27c17a44919bb12b','b2f4f30d088c609668bb5c724354be01080072a12abe14b555d5b44aee48fbe0');
INSERT INTO blocks VALUES(310353,'2d3e451f189fc2f29704b1b09820278dd1eeb347fef11352d7a680c9aecc13b8',310353000,NULL,NULL,'b8a1decbdb2898b426e05656cf5f9268c3071e4053596aabd9c05ce60a2f5002','6d1e68384c3d9be6b3fd53265a323e64a520a822692f0d99943a4bd3c80354e8','82e2095ad6b3773c5345e70732e521f4aadada3f770484306303a4058ea88ff1');
INSERT INTO blocks VALUES(310354,'437d9635e1702247e0d9330347cc6e339e3678be89a760ba9bf79dd2cd8803e0',310354000,NULL,NULL,'9993fd327b1130d88e4ea98097e0f0b615bb446df61e2f324c0f43c1911d284a','c0e30bd067cf1399cf13a4895a0b0b85ecf1328fa336035a969af9810cf7bb2e','c044f728b6e1b675ae15eeff1f27f3db8b49577856e8d216048db47f5a06eeb2');
INSERT INTO blocks VALUES(310355,'ea80897a4f9167bfc775e4e43840d9ea6f839f3571c7ab4433f1e082f4bbe37d',310355000,NULL,NULL,'092a56f3d256a130489149a622e4028b6c11e957c1a02987ddf6c6c940b80073','41b8f24c6db2573e1057effbcea49037333ca06a7a829dae5eef28dd825f2445','e1ef4e243822dc29849b129ce8c51e0dee5b89b24b5582dceb60bdb3bc5aa2e4');
INSERT INTO blocks VALUES(310356,'68088305f7eba74c1d50458e5e5ca5a849f0b4a4e9935709d8ee56877b1b55c4',310356000,NULL,NULL,'80abb322154f882e1fbbe90db2cf1b5317f382a90121cbb48695d3214f8385da','25327caf637945015e893c0c23a9829a9b97b886331ce30423a9c49f51f9f145','4ed86d659ba257e93a70389af5c6e2ebbae98e23edc75cca06b1a38e2e161eae');
INSERT INTO blocks VALUES(310357,'4572f7f4ad467ef78212e9e08fa2ce3f01f2acc28c0b8ca9d1479380726bab1f',310357000,NULL,NULL,'9028916f4a48ea837f1f093341feba202d164772f4f16a9ada19076f93bf852c','aa750dfb534bd76c08ca82a10b79956f3cdf4c2854bd4b55e69cd7029efb06ec','04a51329ca8b1eda6d5d63f78803111b7df523214d67128a3c7561245bbfdcfd');
INSERT INTO blocks VALUES(310358,'d5eae5513f1264d00d8c83fe9271e984774526d89b03ecd78d62d4d95ec1dea6',310358000,NULL,NULL,'d93491f0d7de6431a39b6c5ecb4bc2a79b1ced7c497f4e3d42f7768284fc887f','fafc6c2c215fb060ff09d50c7a6c517bb85eb65faf54340e785ae98459a09008','616eb615e0254d78030676884157373d78120d0b72bba66f2acc4a175e1e2413');
INSERT INTO blocks VALUES(310359,'4fa301160e7e0be18a33065475b1511e859475f390133857a803de0692a9b74f',310359000,NULL,NULL,'1530f7991ddc34284d623fe3d84fc4c1a6e5d25309f46be2bccc9aa71dbfd58b','ec306e433b014fc09469a03cdbc7e6fd54ee3305ff0eefa825deab1450d1a28d','b005d88da022ab88bf34d0ceedb99fd9413897c4d3cbf2b235d3140b0c712201');
INSERT INTO blocks VALUES(310360,'cc852c3c20dbb58466f9a3c9f6df59ef1c3584f849272e100823a95b7a3c79f0',310360000,NULL,NULL,'56404b0c3d30bb481e40c0c76558a36702c740cb8725b7b7f0fcb5464b63d366','e1e10f4f647285132df60032766778ccb429ce85d11e11bf20b6d3294661c8f7','394d744cf291ad42e2d4a3f950b488388e4532f26326151380aa0ec4e170d6f9');
INSERT INTO blocks VALUES(310361,'636110c0af5c76ada1a19fa5cd012e3ee796723f8a7b3a5457d8cb81d6c57019',310361000,NULL,NULL,'a27d13598203dd64dd5f523e9b425ffd79ca115ade6ff8bddeb0e58fc8b02d82','9ef857419c0c3b119614093b3b9b96495cf91ffbad7368ca8f75573e5ab625dc','70c2ccac019fdd172c34437d110107b198758cead7051056f4a5c6949d8678ad');
INSERT INTO blocks VALUES(310362,'6199591a598e9b2159adb828ab26d48c37c26b784f8467a6bb55d51d7b6390f2',310362000,NULL,NULL,'ed942de3639b441b1a111e180b374acd9c97850dca0a654ce6dec1e61394e4be','08c32248c90affef8a67dd25ab19b97b318c40408ef7f9812cfc11da90cb4282','b883be9f43672d6c4422cab79d6dfff7d946cdefd4c657b5f8abb5fd4401dd57');
INSERT INTO blocks VALUES(310363,'a31967b730f72da6ad20f563df18c081c13e3537ba7ea5ab5d01db40e02647e6',310363000,NULL,NULL,'de0ecfb30716e576de5270dffcbb6fe73464064e6c9351f88308fdc2dc56d6b0','e121d96a0171515b0acc7d66ea93153e89ddce900b71afd630640a4849968d2c','667273d2d942d95c99e657f18613801734691582abbe5d9600fcac51cba9c93a');
INSERT INTO blocks VALUES(310364,'67025b6f69e33546f3309b229ea1ae22ed12b0544b48e202f5387e08d13be0c9',310364000,NULL,NULL,'e24edbbc4e3e131b551123b724f1b0873c030d27e18c0f0ec170dc6f55cd1e52','052acd2be8f42f2c9195f858e0afe203af92601c027a1fc9965830f0e37ad436','adecc1d0efc560ea3b854693ec3c1fd81f1bbefe4cededc2967e2876c7939e63');
INSERT INTO blocks VALUES(310365,'b65b578ed93a85ea5f5005ec957765e2d41e741480adde6968315fe09784c409',310365000,NULL,NULL,'6b9e66db961dd534fec94cec6a8064faacfe82e32434c22f565fa9b57b48770c','fdbb1c46dc62e1aadcda80ef91d0a5bba67ac27cb20cdbf4da71272cffebad8b','5b4b4c87a26918aec828afd7c7d8d76e483f12a2d858003e878325db6c37cc9c');
INSERT INTO blocks VALUES(310366,'a7843440b110ab26327672e3d65125a1b9efd838671422b6ede6c85890352440',310366000,NULL,NULL,'9f0841e53849380f448378ab723a78fa24ea79d79dcd5672f569cd201fe9f3bb','24aea631e6696d6011c180e4b08404d0ac7e6c6d542832e7c7cf54d36e972a13','cb833ccc0de0ffb6512b52fa29cfa95041ea61d258a1b38ef7c3721ee493c7f7');
INSERT INTO blocks VALUES(310367,'326c7e51165800a892b48909d105ff5ea572ff408d56d1623ad66d3dfeeb4f47',310367000,NULL,NULL,'c5f166651893f28096d1d6b58388efc5ce962558a5106d913e68e6c0c6aaad9d','92737346724cf6ef7f0044cc023f2fbb6554897a97464aa398065dcdaf9a0c31','55673030b9ecca2bd68a8983defb310468ffb8a0fa389849f3f88eb3ff9fd5e3');
INSERT INTO blocks VALUES(310368,'f7bfee2feb32c2bfd998dc0f6bff5e5994a3131808b912d692c3089528b4e006',310368000,NULL,NULL,'9e4fb8a0749e2113870feb26dd1f86314fbcdb550cdca7c4379a4137412ab750','383f0c23438d8fbbc5748562f5e50d11e41b0dfc52cd0917eeb84a31455c5d91','0e71792a147abf5bea9d1e55b8562d9ef5f29277ce41e4efb58b0fc4ea110fbc');
INSERT INTO blocks VALUES(310369,'0f836b76eb06019a6bb01776e80bc10dac9fb77002262c80d6683fd42dbfc8da',310369000,NULL,NULL,'25089fa1fad0616d4a389c5c05f5a61dbaac9a5ee5fe5e972aac7dc0a34efa70','789929c9898c0793d12dd386db6915c6fdaecdd2029cdb190ef029f7ed18a6ef','836cc54f6802bd60d0fb825c6634e34ecc66cd8015fd118e75f835b3e56c0c53');
INSERT INTO blocks VALUES(310370,'9eb8f1f6cc0ed3d2a77c5b2c66965150c8ceb26d357b9844e19674d8221fef67',310370000,NULL,NULL,'50ba9282f58f19010d88995e4ad103a92e219b0c18bda745c62e743083c68a01','014e571592d08f3330fda9c3180214b48a1a8201b600e9101697bf247236ad1d','8d08f25b3d4edfd7337dcbcb404ed50a670eaf751c54f834c452e3b3f59c52c7');
INSERT INTO blocks VALUES(310371,'7404cb31a39887a9841c2c27309d8c50b88748ed5fa8a3e5ba4cc3fc18310154',310371000,NULL,NULL,'c821de53cb7f7d5c8d64a7c0b3ad2ce15017c499d659957dcce12fba6c48755f','d20fed9385f376b522be3715d5a7c5d5954eb6fa54500e7ea2fa83e99e4b6b6a','541a1664a6e440b77a526984ea710b87d728a06b1412c199e0021d9feeebd8c2');
INSERT INTO blocks VALUES(310372,'d3a790f6f5f85e2662a9d5fcd94a38bfe9f318ffd695f4770b6ea0770e1ae18d',310372000,NULL,NULL,'4fc139104b0ee42c99f5808c06e238669c26f85d6545172bf41a6d5f151ddbf5','58ef6c1d7f88f3d441f24b339d877fdae92afb700ebfcc95e3f72f0f0c5009bc','651513198911f39a50c292565c7a462081567f31aa6d84cdc4dc216e75c4245a');
INSERT INTO blocks VALUES(310373,'c192bec419937220c2705ce8a260ba0922940af116e10a2bc9db94f7497cf9c0',310373000,NULL,NULL,'9e35739a88b113d3c88b7b8491c985ba6dafb35170095462d286054a6d61244f','c98b9bd675de15cf49ef26b7036ac987d3dceb211ad3f08684e7e66fb9ce8f01','0f46eef01ee4a730fc842b20ba118c854f7d031b106459e76d695efd45ea0fd0');
INSERT INTO blocks VALUES(310374,'f541273d293a084509916c10aec0de40092c7695888ec7510f23e0c7bb405f8e',310374000,NULL,NULL,'8a216385475c544cf6d52240f66e95c4064202467c1bfd6c13ae21d90fdfda9c','3a6932a09e9e51b6f372b33a2bc8322db76c5e68b74de8533f72ee1caacda1af','3fab879579b5e6432a69219b2221ce3e8ed96e0d21581980e7a8a812abbc0dcf');
INSERT INTO blocks VALUES(310375,'da666e1886212e20c154aba9d6b617e471106ddc9b8c8a28e9860baf82a17458',310375000,NULL,NULL,'1c1ac076cba8f4c5ec85c4b94170a31be07d94b2a93c98265057ba31e18f946e','919416c461999ce2ca31b72e46abda59dffc4090ba023a87fc3a14769cc6ae19','07aec946ae2a559751dd466fcfcc533831dc266f0c17965a38613c59a8a175e2');
INSERT INTO blocks VALUES(310376,'5dc483d7d1697eb823cba64bb8d6c0aded59d00ea37067de0caeebf3ea4ea7dc',310376000,NULL,NULL,'0fae94f342170fb1f775ee94c972e0231f3902b503246027b9a71e73e0a75d30','0e661689792030d17600a3df53cf6f30bf65ec7aee5c0820f89b04e465211e56','512acab560c832687e066c82f10d4d24de99dbfe4a8cea30520ac59255b83c3d');
INSERT INTO blocks VALUES(310377,'f8d1cac1fef3fa6e7ad1c44ff6ae2c6920985bad74e77a6868612ee81f16b0b3',310377000,NULL,NULL,'a6c2a24498059d9be469e3d0282dfde5ff5d7030e34eaa219431b195f0849ed3','72e290536ec42c060607d8cc72a55d0015bda7ec01caff3e0b8041db17e232fe','5a41aa2e159414dafaaba486e614f3e0ca713acbf48140d63d721f4398c7773e');
INSERT INTO blocks VALUES(310378,'fec994dd24e213aa78f166ca315c90cb74ee871295a252723dd269c13fc614ce',310378000,NULL,NULL,'ab359b444df54152479985691836ad83f50085cc526791ad8383d49d33619f0a','1778ce965e3fa0fc8c5b7370a03d5a72bc1a461a4b1beaf368fdcf1f0fa2435f','2807bf965f3a5ce2e4678ac34539f88863e7c14e5f525af1a85c73c548dbcca6');
INSERT INTO blocks VALUES(310379,'d86cdb36616976eafb054477058de5670a02194f3ee27911df1822ff1c26f19c',310379000,NULL,NULL,'3aaf11af389e482390a66043acb0cbcdda51292c8e393f0c89666564413ebc94','de726c1c76818b5f63e0428c153f9ec49960683f3b9fcb6abe2fe242222285af','6d42c2a929eb005445b63a454bd0e3d636d4e19d2a782cb80b98f8202ea21940');
INSERT INTO blocks VALUES(310380,'292dba1b887326f0719fe00caf9863afc613fc1643e041ba7678a325cf2b6aae',310380000,NULL,NULL,'c9e87750aee19d8d383cccd6bb71652548161dd901379a581113d20871978732','bb39fed82b7cfdf92fcef7e006681fc96dfe8269b7bb545fbfdea198ddb97bc2','cc1beb1f19866679f627d0f459054d687ce9797ff883059a1652efc85ca81130');
INSERT INTO blocks VALUES(310381,'6726e0171d41e8b03e8c7a245ef69477b44506b651efe999e892e1e6d9d4cf38',310381000,NULL,NULL,'bfa20b9be3938c8ffa00e769ea3bcb81475055c987ca08eac513c813bd1a8571','6b4987991a04a9aef4aa3e8279bd4b3cbcb95b837f5f62f9f4c877727bbec7ec','86fceb9e8e04f13e0b7a8101a7b22b4e237c3b430e45730c206c824dca4fd798');
INSERT INTO blocks VALUES(310382,'0be33004c34938cedd0901b03c95e55d91590aa2fec6c5f6e44aec5366a0e7d8',310382000,NULL,NULL,'f736a782d846510ad32ffc368534e6b1966c7da89e6a746122b64ba5533426d2','a9c78856454f8f7b19ecd08b1284f6a91b731d3a1cc13f1ac3f823ff1b3ff9d8','3d15908f8d0dddd33c563f3462b97bace42fb5e530c5d298d9b2ac9330e7610f');
INSERT INTO blocks VALUES(310383,'992ff9a3b2f4e303854514d4cad554ff333c1f3f84961aa5a6b570af44a74508',310383000,NULL,NULL,'0b98c26f33db6d66ee0f86344247b1ed5b5b2ea3dd53e074dd4f0a64066e41f9','a3cba3c31f7a166681d21b0a957548b9589229d556ea8b2c6bcef67117c03646','b67ed79d6701c1c21bb8e98754db62819e31e16a17a005df9b48c9928805114e');
INSERT INTO blocks VALUES(310384,'d518c696796401d77956d878cbdc247e207f03198eabc2749d61ebeadee87e5e',310384000,NULL,NULL,'51181d10e5a33aded1657f31dc48e055d091d49ef4514eb833479e2723b6547b','7b86e8afcb3f7c56c5eed1e47736a716934fa71b17ef282da2fabd4f71f76f2e','7a90aceef947a8edec78869ac2ac4a83a468786f77297d10f1bb257f19887cf0');
INSERT INTO blocks VALUES(310385,'2aa6a491a03a1a16adbc5f5e795c97ec338345cfdf10ff711ffb7ac3a0e26e28',310385000,NULL,NULL,'f1971e2badf2797cb498a8e92ae930514367da96fda214a5623ceb68fb2c5e02','1e37827c54b2e065db0971af3511fef64390c1ecc59c2aceb04fcb85b19d98aa','ab0d75884e897a654d63470056d4a753b80a1b7f6c467a552baf920ce0fd1691');
INSERT INTO blocks VALUES(310386,'9d19a754b48a180fd5ebb0ae63e96fa9f4a67e475aeefa41f8f4f8420e677eda',310386000,NULL,NULL,'55b11ca65e8ad9818ddfbdd2ef064f49b0c3d423906f6c2ad5f59264d7a6ddde','b7f01907abcae9cbbf30dc3644d0b668acaf2513488943eac8b5cf0dd8b8a6df','388dca8a8347c58eb0d8861e0ff82ef25fd1d0bc29a2a6b2334ee6b3c823452b');
INSERT INTO blocks VALUES(310387,'b4cac00f59c626206e193575b3ba9bfddd83bbfc374ebeb2838acd25e34a6c2b',310387000,NULL,NULL,'8602a4651e4f5c2e8853c43107dbbe6fbf917e9093aa55bead4b7ca001cacd56','89ca7478a6e29c89466fac682658d394a7eeac623bc6632738e755bc87a47298','635cacd90be524b431fce3c75171b4ed498d58da6c025f3a6a593b590cabe888');
INSERT INTO blocks VALUES(310388,'41a04637694ea47a57b76fb52d3e8cfe67ee28e3e8744218f652166abe833284',310388000,NULL,NULL,'84000a3278f3fd598a316b590acc64f6f14b21af02074870ea490d08f92a2f40','182e4300ac257a312e03da43fa57e45d344503e42df0eca78aff7c44fe60b8ae','04292901c7174d14f3baf876c32d45d77cfdaf8fcef873d706fe0c45684078af');
INSERT INTO blocks VALUES(310389,'3ec95ae011161c6752f308d28bde892b2846e96a96de164e5f3394744d0aa607',310389000,NULL,NULL,'4eed3e61d5896e42eaa2231c0dbdbeb2083053351466b01bcbe0c0973e784aa0','ecba21d9ca4d52ed80e17b0a59c2b129e49195654b47d4c94c2ade21fd6cba64','91e9e360449f73170d364940befdb66216f10aadf11e1f8347a91b195590b40f');
INSERT INTO blocks VALUES(310390,'f05a916c6be28909fa19d176e0232f704d8108f73083dded5365d05b306ddf1a',310390000,NULL,NULL,'4594159f86d4ddaa5caabe6038c22f4b3c1c3abfe6763cd28405ba50e5c98ab8','7e5172cc0b91befad390e8b4df240016866b6f6107c648eca2f602d2a560db40','6d01c2a38eceb1cbda41a2c6ef2d1c9ebecea3a4fbb62597d2c768e8d2d40386');
INSERT INTO blocks VALUES(310391,'fc26112b7fdd8aaf333645607dabc9781eac067d4468d63bb46628623e122952',310391000,NULL,NULL,'02573a6e3b8664508ea8f70250dd36310597ca1ee65a6e724e58f2f9140fd7cb','c8d058d00e4f693eb82ac0a4e4e2a11ec186c472bc22b03da07bea911cfd0586','d73c12cf37876df064af3331e8a29dade110abba329eb1cf478b32eaa12f7591');
INSERT INTO blocks VALUES(310392,'f7022ecab2f2179c398580460f50c643b10d4b6869e5519db6ef5d5a27d84a1d',310392000,NULL,NULL,'c20d2c7f133de91658cd2ae20f7393919aeaea53229d5810bc22976f0c765ad8','73b46de4d9df614bfeb509789ecc38397029d4e88e195cceef8e1c23e47215c1','ab86fda06df2134ea566c761a7e58712835640852e3a9ba513e8b027de9a2f36');
INSERT INTO blocks VALUES(310393,'e6aeef89ab079721e7eae02f7b197acfb37c2de587d35a5cf4dd1e3c54d68308',310393000,NULL,NULL,'6aaea67706092057b8cf4a677ec075922085e9e8c89748e723d8ed3ef14c5ec6','8e08dd483c33ee56939b5cee3eb3b0851cecf4cd64d2b0928e1ea1e10ed22112','541b042c3ff595c9811900a7b391f7c37337526e30c934e7efe809f898fd890b');
INSERT INTO blocks VALUES(310394,'2a944743c3beb3bf1b530bd6a210682a0a0e9b0e6a9ff938d9be856236779a6f',310394000,NULL,NULL,'1c7a5456249c16eb3774923860024826fb9c2f781fc19acaaf413358c631d1fa','4773ea3c0085f7d7b18dd86ab4ee1db45f08436c0dabd24977a2ebad59dcba1b','ab2c59b71845ab27e107824ebab06efe802e8499e3fd9bbc8e13537311a400d2');
INSERT INTO blocks VALUES(310395,'19eb891ce70b82db2f2745e1d60e0cf445363aaff4e96335f9014d92312d20e4',310395000,NULL,NULL,'05bc6cb26eb26f48a8ce1a8d32fed6b17f3d4de009607714f426774449019692','5fcd9d6ade21cd5ae8fd8c019d5b7bcdcce589433b3684c348a7e1edf01572cc','a12273df2b56167d53454817a5ea5c469712f2cd00637d38705997f471551b5c');
INSERT INTO blocks VALUES(310396,'aea407729ac8d8e9221efd9d70106d14df6aaf9f2f87dc6f490835a9caadf08e',310396000,NULL,NULL,'266c2b8628061ee7081628137a3fd5858c5e29935c64ca1293adc13f00426dfa','4c92b1dd714230a69fc80001b60237fc2f30a4d96b8b2af509716553c35ebba9','fd75377722fde5b492ae95f6696b9d88bfcde4373c73739c8cdc5ff221a98ff6');
INSERT INTO blocks VALUES(310397,'7c429e56a19e884a8a77a759b52334a4b79404081b976270114043ba94d7985c',310397000,NULL,NULL,'08d0a9d7471d1011301e8c4f7c865cf29d820d6e27cc111bd8223173abb7c16e','112d847eba197820647359fc98398014f20a8bb4a93292bb368782e74aaba9fb','f6478842355b7462e4a0f747c19be4067add3a73bf9735d880f032345c841ab7');
INSERT INTO blocks VALUES(310398,'55c046db86dee1d63c0e46e6df79b5b77dfd4ab2ff5da79e6360ce77dd98335e',310398000,NULL,NULL,'4dc8dca962ad444beca1663cc549100b8e1354fa486450f011356712b8a4dc89','03ef6b9a2a6cf79cb90ba67809224902abe57bb04287ed2a3a413cac7380437a','4e60650deb304fe3bb17a3112d3e3c47c99a0d85a910e2989c71863c10431433');
INSERT INTO blocks VALUES(310399,'765abc449b3127d71ab971e0c2ae69c570284e0c5dacf4c3c07f2e4eca180e7a',310399000,NULL,NULL,'2567e22ec739e8c2e2c19592ad2f76237b2473ff74acab1fa8a5fe66a115b9aa','157d0e65b186b18bf47ae3aa5b0a0b242911f13179d14f6d9cf48179eeda4469','ae808c12677e50da9aa684b908f2dd80d1b17c234c1f42b068761b2977c056cf');
INSERT INTO blocks VALUES(310400,'925bc6f6f45fe2fb2d494e852aaf667d8623e5dae2e92fdffa80f15661f04218',310400000,NULL,NULL,'291be7d88b4b204ffdd405ec3d56723fac6be7939bdb43c72ee805cd0b1b6af1','d78c6965c3a8068480b3ac3c64cc4dd29378494a404926307ad5266580870a77','4983659d6720d1fc9f6cf9394e23ad377dc3caba0ae9096c2e1665e79458e001');
INSERT INTO blocks VALUES(310401,'f7b9af2e2cd16c478eed4a34021f2009944dbc9b757bf8fe4fc03f9d900e0351',310401000,NULL,NULL,'a0105009a7fb1d740b5390582a9002e2482ab3ead3605262280b1a1a1227242f','ffd905afa06fdda836761365a85ee38c5b7bfac9e350ef31f1f2d43ba308073b','785fc4b2805aefaa5e6d5c49034e430821c16d9c2bb01302fc97a723d64e1a4a');
INSERT INTO blocks VALUES(310402,'1404f1826cd93e1861dd92ca3f3b05c65e8578b88626577a3cbad1e771b96e44',310402000,NULL,NULL,'af7369adae73f4c2409b31eb89115140683a72ee002c7a429be374b49735146a','c3e603509e8a80ad801eaa52a54c15d9849c69785b9bcfc38b74b893bb4774dd','c64478ed19e2db51ce8d17239b3abbe39ed58aa840c41fe68754b16ae1dbdded');
INSERT INTO blocks VALUES(310403,'f7426dbd4a0808148b5fc3eb66df4a8ad606c97888c175850f65099286c7581c',310403000,NULL,NULL,'3f2381b90a09ba7bae98f9d881b9b9955229a01faa94b53cde3aa51e39728134','4231de04256249b365e3e587cb1515e351a1190f09c1af9b4050607936bdc477','c4331edb67b4c0762bec23e4603e96548d8e0aa5223a74a7a32da1ef1d05e38b');
INSERT INTO blocks VALUES(310404,'401c327424b39a6d908f1a2f2202208a7893a5bedc2b9aff8e7eda0b64040040',310404000,NULL,NULL,'c52f5bf96a041a3ebf01697569f4d1b0686ad07d0860f46e98adca59fa10fcbd','fb5a3a3aa91e8d0b76b9e3a6bba0a03f6d6ee268789f21d847400d2d6e4032ef','abd2e2d3640f6afa28438c488abe6a7451be734d54854f2d82a679beaa3ea6cd');
INSERT INTO blocks VALUES(310405,'4f6928561724e0f6aab2fc40719f591823ca7e57e42d1589a943f8c55400430a',310405000,NULL,NULL,'47a36123ffd2eaa6205d6dbf80bf580c532aae086781924f18d7ecb2ce10d1fb','48c8552ef5869759114131b84fb7be7f35b35ac8d9c5d58cfd121b220f255780','6a8d882b5bd4d441fe2ebf3958460c0c128f23e228a411951c61f90eeb47b6a7');
INSERT INTO blocks VALUES(310406,'6784365c24e32a1dd59043f89283c7f4ac8ceb3ef75310414ded9903a9967b97',310406000,NULL,NULL,'4c3f345841accc0f723ae90b451a737dff5474e3658ae83429126d4976759292','9c0ab71725755bdb8c3f49fc3ffb338c85a5d87ed8fecc022abf8928b025933d','fa04bdd8a75f356d40d6dc6eb6218edf1605deea3084176e09ce5c056167eab4');
INSERT INTO blocks VALUES(310407,'84396eb206e0ec366059d9e60aefdb381bca5082d58bffb3d2a7e7b6227fc01e',310407000,NULL,NULL,'b5773ee9de1c74b9bc11e34184b0b621c10fe379a6c9cf93aeace41501187c73','235d6a23075c9c38abb248aaf4b9340316239fa07e253f915418b7907ae6babc','c6afeea979ed304cc574801b699c14d2e11cae60053f1392ce664d055489cdc7');
INSERT INTO blocks VALUES(310408,'4827c178805e2abae5cb6625605623b3260622b364b7b6be455060deaaec2cda',310408000,NULL,NULL,'d1bc602174aef907eef01cc1510bfaa688703c4bfe0c235dc877718a7668e605','5649d9a4d0a227a4c6bb92e62f1bf6f2c2b79f7b03f895e6335b697540ca3409','1c09f535970ed8e618b2b5766c110aa9ef9e1d727855b49c2242f3bf95611b59');
INSERT INTO blocks VALUES(310409,'01a719656ad1140e975b2bdc8eebb1e7395905fd814b30690ab0a7abd4f76bba',310409000,NULL,NULL,'b9aceb2b5e8c1fcaee6522688b67285c6e44f3308b5b0f2f61e254d997b92969','0a3087925cdbeb14275f493c698ec374140775a3662deef8ecfdb4565eb0c30d','dfc05b36ccb95de40a58f607dce4eb5b5e736fe87c25876a089f0bfa84ab9479');
INSERT INTO blocks VALUES(310410,'247a0070ac1ab6a3bd3ec5e73f802d9fbdcfa7ee562eaeeb21193f487ec4d348',310410000,NULL,NULL,'eb292a3f803d3a9852adf9cadb48c1d8bb93cab02712df582d913d2081e1789f','40c5716721fcaa007bf8b792fc7e5bfc7e3422d8d9c44143bc65ccf51a4c2011','9d6972f37590cf3e6675382487fc0b96a861d8fe82f736c3d6e2e5f9b7c1587e');
INSERT INTO blocks VALUES(310411,'26cae3289bb171773e9e876faa3e45f0ccc992380bb4d00c3a01d087ef537ae2',310411000,NULL,NULL,'ee7aef26e5f59294bb5f316ef84d3852c6f404a7bd4868b2844b0766e415ca93','b90d3c565d3f88d00ca186d9730dd15c685221713ea808ef572f533fcddffa3b','687e1dea75970c9333df198fdceed97ca302da55bf98778772315e389683c202');
INSERT INTO blocks VALUES(310412,'ab84ad5a3df5cfdce9f90b8d251eb6f68b55e6976a980de6de5bcda148b0cd20',310412000,NULL,NULL,'057216567e37b67b3643c71b21a3c2049eab3abc170b9a2de31fc16fe335b315','3664195a6a450cc831edd540b619ed2e1d2d6ff551bdaee99bc364f7b01e9a6d','af4ac89e9ca997d17a43d15c6a8169ce844b720df358120c2a7e8ed145e6fdcb');
INSERT INTO blocks VALUES(310413,'21c33c9fd432343b549f0036c3620754565c3ad99f19f91f4e42344f10ec79bf',310413000,NULL,NULL,'79164a2c361d4af702ecb781fc4becac813390a2a1491660fad3aa5e756263bb','827639370cd203472892165adcebd0585f26952103c7aeab16f4c06a29c898e5','095a4132d14bd95172314f35a7d2e696667bfd7fd15e19bedc9b1795218c6cb1');
INSERT INTO blocks VALUES(310414,'8cff03c07fd2a899c3bcf6ac93e05840e00de3133da14a413e9807304db854b6',310414000,NULL,NULL,'f6f28c655ddb89b51dae9b378cdce2945312a6bb63d91d642c068d6e7d40ae2a','48311e876a18d19bfec0ac29586528cb154ed675ebf7523dcd0fe7d19d9cb0a6','210b1ed92cfea33a03bd7a66b55d71831838a036f5ab325e965ee2b0346394bb');
INSERT INTO blocks VALUES(310415,'dd0facbd37cca09870f6054d95710d5d97528ed3d1faf2557914b61a1fc9c1cc',310415000,NULL,NULL,'912308109aa37d7cf92ff7efae0a8153bb75681400b492e756979b32cd745087','90362524eb50c11f471e2dd4cd3a1cacb60e3a0dbd41aa131f94b46fcf4213f4','09da32a17751579766a35977fffc9ee0cb90aa26a317fea4793feabef1305456');
INSERT INTO blocks VALUES(310416,'7302158055327843ded75203f7cf9320c8719b9d1a044207d2a97f09791a5b6b',310416000,NULL,NULL,'73cffd1886dbece54c1b58decb2d33c16897e84ab3b9cb2223b39f48f4148a7e','473250bdb534d22fbc9d1c4c51aa7c9ff6e2f879769fbcdceee0277d90419646','2d5339bbb21be1dc7d415858bf3adc62b44ca5e6c1173b2c7a74ec59d1d1bd88');
INSERT INTO blocks VALUES(310417,'2fef6d72654cbd4ea08e0989c18c32f2fe22de70a4c2d863c1778086b0449002',310417000,NULL,NULL,'467e4cedfcac0dc640bb1b71195d01af3077da0607f220ca2fd9ba926f1a9098','a9793e3322b8e2fb08af78774a3e1ccb106385636ab00c9314b05e161d00a98a','e265a3742ad98f95f61983e029f70321f80c273f3fa891fa653188637ae6d264');
INSERT INTO blocks VALUES(310418,'fc27f87607fd57cb02ce54d83cec184cf7d196738f52a8eb9c91b1ea7d071509',310418000,NULL,NULL,'ba22c06b1726a326a13436530136cefce880d7efd0cd13c549d04870534a2999','8526831923bb81a27466997f567023445ca1520c40e5a438888d6b4f363469b4','9280cbc3c13dfd49763c118da6f98d4a93d1afc44a8e0aaf0d1db22d846e03f8');
INSERT INTO blocks VALUES(310419,'9df404f5ce813fe6eb0541203c108bc7a0a2bac341a69d607c6641c140e21c8e',310419000,NULL,NULL,'f26458b93099c794d556517c13917b3ead28a3715ce00db3758a62abfddf2bd2','59c8c89654c33936b20ba70c4f218aaaf531a11c20e303b1d98a78d133578027','00e5e6b2b8673b24c51ae1fc51219016c745b7c4f5cb8d09b56a701c273c4927');
INSERT INTO blocks VALUES(310420,'138b3f1773159c0dd265a2d32dd2141202d174c2e52a4aeac3588224a3558372',310420000,NULL,NULL,'53f47f4514b597496269768af66ac2314efbb9ae998b2bf75b818bc96c7e9d32','07b1c43f2c0afa70648ba2cb0b09c4688d492531702fbb4491291a2e9d1f6716','1a1bbce467cecbdae41f7b98d247b36a2eb09d978f26b985b35a6f16533cf5c7');
INSERT INTO blocks VALUES(310421,'71fe2b0e02c5cad8588636016483ddd97a4ef0737283b5fd4ab6ea5dc5c56b9a',310421000,NULL,NULL,'9868f2c24308d204025e164d010a5991e3916a18becc2db459eba50c4823efca','ece1d536563d7a8711f7b6626f586deeff343f89bea746e6bd222f6934f6fbd0','19c1588dc5aa225c470305ec0849aa9e453b23ba347b022e56b240892643ddde');
INSERT INTO blocks VALUES(310422,'cd40260541b9ed20abaac53b8f601d01cd972c34f28d91718854f1f3a4026158',310422000,NULL,NULL,'19b9d47cbb24d230ded417d4c5888c2adf446d4582ac9702ecba9ddd82cc8447','37a34e7c3361160e67fcdbeb4eaadf772d3d5b25ba9516cfc43189d898a8ee66','75f739ac6cc92d738b3dead11e4acdf6b31c25c9e665eb1f6e490e377eb26d38');
INSERT INTO blocks VALUES(310423,'6ca0d6d246108b2df3de62a4dd454ff940e1945f194ba72566089f98ad72f4db',310423000,NULL,NULL,'32b5f7b5c089d78fadf01db543df7ee86be5f81fbfc1d3764e37901ddbf6b10d','5d19d24d6668b50c446b056709ea9df2054bd8b5cd7663bc0acc7a946a09f4ff','a85f2e151d1abc442abedfaedaafc23ee967c986b2e1a4d65ce39ebeca5411ce');
INSERT INTO blocks VALUES(310424,'ed42fe6896e4ba9ded6ea352a1e7e02f3d786bfc9379780daba4e7aa049668ad',310424000,NULL,NULL,'f264db27edb8d279a06a00532dc0eee91cefd18e51dd529f695dbf45c47a393d','210f48acb57029bb5a342721a26c3b85d147123fe9ec27cb6cb19c448158182b','abaa650167f33673c65b792655f2f4781c2967865ddb6c60b2cec48f34168466');
INSERT INTO blocks VALUES(310425,'73f4be91e41a2ccd1c4d836a5cea28aea906ac9ede7773d9cd51dff5936f1ba7',310425000,NULL,NULL,'b9d0bf7499069b1d5f0fc41dc2c9a87ed8d409f20953997e0afa5ebf813da666','e6eacb54888b2e050ce64b3849e54153f0d21ead412bd264d5619be40feab719','3e8522270049a0ae7ec8cc6cc6bbbe4f518d3e5ff819c279d123d8269796b042');
INSERT INTO blocks VALUES(310426,'9d28065325bb70b8e272f6bee3bc2cd5ea4ea4d36e293075096e204cb53dc415',310426000,NULL,NULL,'4217d05a98dd85e970fa23bb8fb1c584de5ec0b03141ce016e37403215c94e34','e0fdbbc79636ed7c3a709c1ea688e7d9737d7635e5863623a9a3af327adca509','05c3db6faa177ab3406c5b1ef690619dc818596a676effb93272836fc17f718f');
INSERT INTO blocks VALUES(310427,'d08e8bc7035bbf08ec91bf42839eccb3d7e489d68f85a0be426f95709a976a2a',310427000,NULL,NULL,'04952d709a35078dee7f26e45a0c8210dbccc7febc897060d63cd83e338e4b00','b45a86c7ece8f1205c7fdc36dbe51f99a64fbee9411281a25e318686fde8fa8a','cf3187d74f22b6a0962c0d4a6aada2b33baf71680d52187a5cec9c020fba6f98');
INSERT INTO blocks VALUES(310428,'2eef4e1784ee12bcb13628f2c0dc7c008db6aaf55930d5de09513425f55658a2',310428000,NULL,NULL,'d8c5be42a09469c84c43b9c2f68ffbfd18bf645d5b8719522c54b1058464af8d','e4156c765f2c4d54419d35cb0fc08b824f438c8bcea665494970c6049617f5bb','9cd361610a7aa8303ba4e308d0a073b057c6668a1c3c27c62aa4d9a47a4aeed2');
INSERT INTO blocks VALUES(310429,'086bfbba799c6d66a39d90a810b8dd6753f2904a48e2c01590845adda214cf8d',310429000,NULL,NULL,'17793c83238e5b568e77e34a893150910ae6bcc8d72ccea5cd9654c80619bcc4','1683e26e50136f44dced0f78ac42ac5febc80d34862987ee69b1dfce3c134c29','f6a5b162ed58e894286d9b5efef2b3e62cf8903bf4175d4dfc7158bcd78cc6b7');
INSERT INTO blocks VALUES(310430,'870cf1829f84d1f29c231190205fe2e961738240fc16477c7de24da037763048',310430000,NULL,NULL,'53a55e5ceb0189aa074c15c8228d2be814cbf2735c6d141a982f7951f204e27a','18716967de4053b38528ef26811bccf0f444850c69d82a9876a386d31aa257d8','9b25b4e1ad067b1ebd27f3054f3d505d4a4def0c626d0a487652e708388d8246');
INSERT INTO blocks VALUES(310431,'20b72324e40ffc43a49569b560d6245c679e638b9d20404fc1e3386992d63648',310431000,NULL,NULL,'b4a99fdf94fac7ce16d5c8fd93ab9a101fcea759ae1ac53813d71854fa925a3d','352afa4369592f8c4fc40744982448dd32ddc461681040d0a3ba4a17e49b86c8','2cfc0061c875f6ec554707ecdf3f477db71fb99ec1c54e6130e4e6cf5ccc1d26');
INSERT INTO blocks VALUES(310432,'c81811aca423aa2ccb3fd717b54a24a990611365c360667687dc723e9208ad93',310432000,NULL,NULL,'c9a284383445510ca12a325e0ac4a513f74838e1ea80b6b26c8ccff8522fa3e3','33f30235fed4e5dd6799863ddaaecdc3051062bfbf71a0f7dd9267b1958a9b02','74433d2c14e6b7062b335c4975f23e24b2e026d869aea916e49dc8e807c6f3a0');
INSERT INTO blocks VALUES(310433,'997e4a145d638ad3dcdb2865f8b8fd95242cbc4a4359407791f421f129b1d725',310433000,NULL,NULL,'86b55728ff2cc62bb265040cf7701ac1e24a20ff4ef81033f7583a6b44e8d446','3aa1d658c2d3a150eb33e2ded038cb3a4b317fd17aaea69ff1f7a7cc4836f70f','c0151e58f1643863e3f8031e90f1a78fd7928113184a463a6d8f5a2387ce16b1');
INSERT INTO blocks VALUES(310434,'61df9508e53a7fe477f063e0ff7e86fbb0aef80ff2ddedc556236a38f49ac4d8',310434000,NULL,NULL,'094dc0625207e131b7e85ddd5f63b7fc4eaae1438a5b8c0f6e27858deaa56718','49e14cc1d380b1275696aa67260cbbb28df5d5d67bc68414f4e86443e5476a57','9d6b77447a382f4522c858d99aab7702ad130d8c069a5d6865660df4ae446082');
INSERT INTO blocks VALUES(310435,'f24cf5e1296952a47556ac80a455a2c45da5c0dc2b388b51d235a3f741793d5f',310435000,NULL,NULL,'a1fc4db061f4a5e165466838808a1facee777d84dc9204694c609dfc00858797','5754d537fb23dc9fba9bcd62128307a64a12825ea4aaee0c5b188c5710c6d2a0','37efef19fec81d0574485f5b98c73c1dc8fd0c5214f4c7fcfe8913e4ca32e2de');
INSERT INTO blocks VALUES(310436,'a5e341ba92bdf9b3938691cd3aab87731eba5428bb61a804cecf9178c8da0c19',310436000,NULL,NULL,'2b179f51cd68988716e9341732f651e560c94342f371b1d9d9ce34961a2a3cad','178538427696d0ebf5e73a9e49599c2d48c08f2106a0811292a629b3268e511b','4bb0d22bbbe5519902fc9dee9dc88c9e429a883d49ac960db4bc20501e66f57f');
INSERT INTO blocks VALUES(310437,'9e18d0ffff2cb464c664cefc76e32d35752c9e639045542a73746f5ec2f3b002',310437000,NULL,NULL,'40c923108f4c2ad42ab70e1da02c273bc3670b2028ab7f52644ce3882dc69a9b','ee8e40e4a555dd131f72222372c4eb4116384b1d64795218d32af0f0dd8d5682','7436cd5f2893765dbaa74141f8410da96bbb48ccba19a1a13371f42f84166429');
INSERT INTO blocks VALUES(310438,'36be4b3470275ff5e23ed4be8f380d6e034eb827ebe9143218d6e4689ea5a9fc',310438000,NULL,NULL,'2b00f1204f33edafdebc657b19bcc48148b6cdeeaff57f30858fe91330e7891a','3cb12b440356b920f8d5c6d0b5c551db44bbed2fcecbc287fd56e2d90a786fb8','e367b84eb345fdc5cce835187483d8be0a0a9f5421d36cfd1fd0455f6df3ba74');
INSERT INTO blocks VALUES(310439,'4f2449fce22be0edb4d2aefac6f35ce5a47b871623d07c2a8c166363112b2877',310439000,NULL,NULL,'80d559cca2469f07af74da39688dd60651f96e7460c6b64fe2e3a482c3724cc1','4747e9738cbb8ae7e51ede0e24e1374fb722752e36d45fd76d3fc20c8cd02d4a','1c2ad2b15cf5a47b440263681a7e3392bd1af4697f0d1ec2753e354ed2e7473f');
INSERT INTO blocks VALUES(310440,'89d6bd4cdac1cae08c704490406c41fbc5e1efa6c2d7f161e9175149175ef12a',310440000,NULL,NULL,'47f9bc1e0a259a2988fb29f56fc44b5819263c7976da5b110899fabe8f1529eb','6b0a8eb9760f835bf12d3055d6c9d102b085ca326200638339eced06171f9133','d57a8e9fba383694fcb6dd47ab85c6f2b115784edbd9a705a297d2ce8265ad34');
INSERT INTO blocks VALUES(310441,'2df1dc53d6481a1ce3a6fee51ad4adcce95f702606fee7c43feda4965cf9ee15',310441000,NULL,NULL,'a74840929cfddc49ae74fb95904a7d969fdff7e2240c030dfa22bc88068874dd','8be9fbf19c3497b388439a5966ee5e392d51d32a7a58d8ddb3a6c4b49361f4ca','e8f0ebd969f994b32b19c723413b50dea94c83d0ddbbe29f29001065b8725bfd');
INSERT INTO blocks VALUES(310442,'50844c48722edb7681c5d0095c524113415106691e71db34acc44dbc6462bfec',310442000,NULL,NULL,'aeca0d056c42da2efb049f894d5a9c6900e3705b1ad942094ba9c8a3f87cdd99','721ce2becd12ae70b70326f84faceb73037a181a3e98c27d15ff481a887e9946','377f66a57877685b3cfee19b2925cca1f2be4f4522090c673eab25e8e422d2bf');
INSERT INTO blocks VALUES(310443,'edc940455632270b7deda409a3489b19b147be89c4d8f434c284e326b749c79a',310443000,NULL,NULL,'845368b4da60c29e53cb11d5c030bb24c1f08f77776193897670179f82901e98','17a14946207acb9c7a18c86f36cb851b6689ddfd67d86a2eaa51c082a316c008','85070d7d435db9dd8977715f857418330112ea7168725f664ef6c6bbd3b30327');
INSERT INTO blocks VALUES(310444,'68c9efab28e78e0ef8d316239612f918408ce66be09e8c03428049a6ee3d32e4',310444000,NULL,NULL,'e0d918728b0de8a75140e45da9a678b164204dcd7d918b988707d94f5c1dd151','8d64424f6a788819a3af71334b4dacfcf4ca19fef8b39e5dd0c22d8762222b81','9a8b575b06af89bc9e43eee498bcb58e7fba4b33890307533540d9c93274c23c');
INSERT INTO blocks VALUES(310445,'22a2e3896f1c56aefb2d27032a234ea38d93edf2b6331e72e7b4e3952f0234ef',310445000,NULL,NULL,'eaecded6196fcd6669c0728f497e6099189a1e93c4ff777f2e97c4cc2af8af8c','92cbe8310a04344899cb14892abe0ed006c70df91911e4a1057cb924101728bd','83ff4a44619353fac588b87406282df74cac18da43344744d6f2aeb5a2703397');
INSERT INTO blocks VALUES(310446,'e8b0856eff3efce5f5114d6378a4e5c9e69e972825bc55cc00c26954cd1c8837',310446000,NULL,NULL,'1e5b6d1e80afdee85780f99caf956e636a5c1b13b092bb2dcc3aee3550276f7d','11fba1332970672c12c1235b652f23040826c27b595e582a9580442c4ef28891','d73ded224d437c919c6c94446ba45c8891992162d03979fd5aa2efb326ab5414');
INSERT INTO blocks VALUES(310447,'3f4bc894c0bc04ee24ed1e34849af9f719f55df50c8bc36dc059ec5fa0e1c8a8',310447000,NULL,NULL,'aeeba0674cd2708e3e2356f6cea65c25311f91f51eb74497d777867a67fceb41','95b58a9c409f05a54c41404ce98c3a0c973b1927a8ff33f0a20e9182f73c2f8c','e4e6ed375ca2ea719f611818fc835dfe82bd77262914e9915768bf32a7c411cf');
INSERT INTO blocks VALUES(310448,'6a6c7c07ba5b579abd81a7e888bd36fc0e02a2bcfb69dbfa061b1b64bfa1bd10',310448000,NULL,NULL,'0f3b562766d70bdb856e3922341bbf8a9145ce8c735c48ab0277a3bdceac4af3','863c89e0cb0f2e68d0651ac6898886a159a8b096ad2bbb1de0e804b478589ffa','917f1cb03aa66b66760bda9e8b5383808249b455d9ab2d64e93a440844f8ece8');
INSERT INTO blocks VALUES(310449,'9e256a436ff8dae9ff77ed4cac4c3bfbbf026681548265a1b62c771d9d8e0779',310449000,NULL,NULL,'0fba0e8bc0e960e574c0c145c7d84333f587cc325a6d00762522fb2632c8f4db','5782fca56989bf43b83225055729c0be4f993e9f264304e25da74736faae4b93','fad2b4ef6693a96b95eb1abc70d647cca6653f2c3d17634a061b6bb0019dc519');
INSERT INTO blocks VALUES(310450,'2d9b2ccc3ad3a32910295d7f7f0d0e671b074494adc373fc49aa874d575e36a3',310450000,NULL,NULL,'210e7518c6af38dfdecc6145aa49027052b642139f2061cc0dd588496794162b','b574f1271f63c07cc829c09ffc6b9e53cd60b6e2227975fed0cca589f458f131','5d0bdabc44b1a3c22a65bbdfc6505ee676cd458024dc52529dde8588092473d2');
INSERT INTO blocks VALUES(310451,'55731a82b9b28b1aa82445a9e351c9df3a58420f1c2f6b1c9db1874483277296',310451000,NULL,NULL,'36c0f7b7a37f43f854746b85542ce336b456770d52c7de4da34136d571142ca6','fe9910927abc2d3be562f82c05fb17c2a105a0441f2f70573aed063c65b4fdc1','0963e33ac46e7baed2006fec21f6b8de051f883fb49fe9fd913cccc4ccf539cc');
INSERT INTO blocks VALUES(310452,'016abbaa1163348d8b6bc497cc487880d469f9300374a72ecb793a03d64572aa',310452000,NULL,NULL,'8bcc41ab66349796286d7fc3ce711e21a3fc41447bdf35f7999121b57ee2b7e8','aeafdf004b2025f65c105b1490aa8a614865c8b6cdfc8136bfb0caf9b5355142','3329b51df07c296f7577fc659b8e24e98acc02aa8e95205cfa9043516fce2099');
INSERT INTO blocks VALUES(310453,'610be2f49623d3fe8c86eacf3620347ed1dc53194bf01e77393b83541ba5d776',310453000,NULL,NULL,'41ffc315b37bb126e4e3c406f74273507d1de9ca2dc17e343c2520604addd4c1','e7adb1a1a71d2bbdce8fe0c67ae3f9702c422b1e10d33cca454ccee872900fa6','416c46f1b94219742929ff77f0acae6d3925f33c5deaf7ba443c3a0cf38963b4');
INSERT INTO blocks VALUES(310454,'baea6ad71f16d05b37bb30ca881c73bc48fd931f4bf3ac908a28d7681e976ee9',310454000,NULL,NULL,'a095b949a722270f1a16fa581648b78d798aa06f8bd067de49b837312fe097cd','2fe0e22f4d2eaf944933f51de785a0144d4e0147767cf1879082c0aa197e4481','5da614ce7d52205eadb5ff65d455e0879559aad7dbbfb5d547a177c18ac52e60');
INSERT INTO blocks VALUES(310455,'31a375541362b0037245816d50628b0428a28255ff6eddd3dd92ef0262a0a744',310455000,NULL,NULL,'a5126463cb7cdc481b74ac766728ed9091dca126f2f7eaf88a76dc76457ebe27','98d72a4a5ba76cf026c034b10ddba261d491f822222fbe332e98acf79ae75308','f6c5fc8a8d1237162130465ddfaa91e451be0258ad3fff7e1474d41af03f792b');
INSERT INTO blocks VALUES(310456,'5fee45c5019669a46a049142c0c4b6cf382e06127211e822f5f6f7320b6b50fa',310456000,NULL,NULL,'78b3172922072acd9f4c550ff0e7edef0309fc3d1b34de92e38143756a441cb3','738c604aac2d22f58b1037da43584ac347b96d04f66c910ed47415c956bc54df','492767ca9de9b16b7e167d60843cf6b2ff242bd50366896920f3d38c7aedb5a2');
INSERT INTO blocks VALUES(310457,'9ce5a2673739be824552754ce60fd5098cf954729bb18be1078395f0c437cce9',310457000,NULL,NULL,'edbf3c914b1375401c7983656bd6ba233dcf608caf1749968b694944c7d78186','08bccecc0dbe68389f8a4e2f2d935aef09feae8e89f1014c87d377b411fda574','7eab83c051d8fa52853750c2cbe59fa7ada61cd7136724075875b140bb98f566');
INSERT INTO blocks VALUES(310458,'deca40ba154ebc8c6268668b69a447e35ad292db4504d196e8a91abdc5312aac',310458000,NULL,NULL,'2a3e7f367c918dbdc88473dc033fd120e91a725a14a9ab954da3e89363b1ef8c','ade7771c7068486baed3132b77449cf8469593166a092082b5c13540b60986c8','48a9436d280d48abf87487dff77a8c60aab5bbec507c12b4fa91eb6b91eeeb38');
INSERT INTO blocks VALUES(310459,'839c15fa5eea10c91851e160a73a6a8ee273a31ab5385fe5bd71920cbc08b565',310459000,NULL,NULL,'d4ba61a1c3c10cd9624ef8a19443f107ca8e509340aecaaf878155b5828379ea','1bcb64effb358b60c2dbf4bce24db14ef2eff98ef876219db9659ecd9657ce38','ab4f816f225bfe6634cf15ec635c12026a1148a28706eef2c378a207e022e54c');
INSERT INTO blocks VALUES(310460,'9b5f351a5c85aaaa737b6a55f20ebf04cafdf36013cdee73c4aaac376ad4562b',310460000,NULL,NULL,'6cd93ea7c06779479a6787b10b5545da35f2d3db5ee1d0bc4a24e4d185680ba5','311b9d6c2b23dd6c87f5763ef51b74278053796cdbda0d50779e517ea1514062','03e3a12ddb0f3109821cde18199e15b5c5a578a1e6b3dc7c06b33956797c4a97');
INSERT INTO blocks VALUES(310461,'8131c823f11c22066362517f8c80d93bfc4c3b0a12890bdd51a0e5a043d26b7b',310461000,NULL,NULL,'52855573f3bc904473f46638364cdcf5ec389b8d8b0e91cd98e2de1b9c620b12','c46484679ffa6646d073c69205e3519b2e21396d169de4813d265609d6ac495d','05bbeeea0f9999b29559923f83b77528ddef98c1f97ccdc3b807113046608fed');
INSERT INTO blocks VALUES(310462,'16f8fad8c21560b9d7f88c3b22293192c24f5264c964d2de303a0c742c27d146',310462000,NULL,NULL,'ece53c5afc99252beed86cb9271abd1e00e8f490b75914c61929d285b1302082','25a752349532900bc4a64903b62a54e491d38d8d6911423578cb57778461099e','b62dd2b9bd7b838b5828faa53016b004264dce234a7db8b6872f09b20bd94154');
INSERT INTO blocks VALUES(310463,'bf919937d8d1b5d5f421b9f59e5893ecb9e77861c6ab6ffe6d2722f52483bd94',310463000,NULL,NULL,'e0816cb9fc14de7844ed169e13c2013c243f2e5b96c3bad811a74fa8f2dcc73d','de9eedbd0def055cd85f54b1f703954dc2f09ab964e526d14d9480bcd777d683','edad4d43eec7e61c443a4d34f2673c39a8a2017ca7578b162cd6e37c5d0abb0f');
INSERT INTO blocks VALUES(310464,'91f08dec994751a6057753945249e9c11964b98b654704e585d9239462bc6f60',310464000,NULL,NULL,'5b05e1d946966ae552b11cebd7d8baf081e1ce32210bd8b2082706a633ea2e67','8177bec5ce53b19398c395b0d3c2b1b658d68844c811f08b20f93d0039c45af3','e3474fe8d998297d8e950a11a2e40a53baa281ca893fc498869991df88700861');
INSERT INTO blocks VALUES(310465,'5686aaff2718a688b9a69411e237912869699f756c3eb7bf7c3cf2b9e3756b3d',310465000,NULL,NULL,'8619f76403307075417ef00c6e42c9b025e3f43b5816b35e6d7976b30091b005','b0ae01260321beab2d7e2298d1f7f6103bb975a84c1fcbab95eb466cc12906b0','1a4ad20b2618fa2879c37be49e489d2c26d7bc8439aebd3f0781f0da2faa1eff');
INSERT INTO blocks VALUES(310466,'8a68637850c014116da671bb544fb5deddda7682223055a58bdcf7b2e79501fc',310466000,NULL,NULL,'a3b47eeb0d1c64e6fd53a19218f4a585732aa243216a5ea709496688320aa75a','807b229e0a67e767f56be80cf82fe05ad884e86bf3fc58022ed38c2f529b53a6','107ffd620fe2e4c8e8965d6f5b5301f1ce10f664a035bd249552460d64f26a7b');
INSERT INTO blocks VALUES(310467,'d455a803e714bb6bd9e582edc34e624e7e3d80ee6c7b42f7207d763fff5c2bd3',310467000,NULL,NULL,'82c58a8a8ee9ae0c2fc6126f317224b4bfec0407f6b69b897231ae5cc4586eed','82b2aefec73d3c7a80a9749bffd6eb637e079f0cd6b2db6d934082f18b3d14bd','af225f799fdffeb7c943bb0d6ae1e297b4bc7282bbf7acfa164686b71e50c2ea');
INSERT INTO blocks VALUES(310468,'d84dfd2fcf6d8005aeeac01e03b287af788c81955612375510e37a4ab5766891',310468000,NULL,NULL,'b7780744100c38d47449746d3969801d027c574f8d3a610910fa260b2464f3e9','f6d7eeada387b7288d44e62dd9f193c01892850164d621204aed996b9e052a48','72a134c93183c5f1ede8dbd2fd24c8d37eee7d93273bb190bdf2f1527f7f9b8a');
INSERT INTO blocks VALUES(310469,'2fbbf2724f537d539b675acb6a479e530c7aac5f93b4045f4356ea4b0f8a8755',310469000,NULL,NULL,'903a48d73b33e16df940f5f3bbcb051f0fa7fca50a9fdbc84fbeaaa538a69f18','2812172c4c6b2921890c06333b36020fd2f50187987ab0c3b378a7f6615f3eb1','3d340f36ec5a6e40b5c357113a026e7ce8dafd38742bb75c9f8d1acc25368687');
INSERT INTO blocks VALUES(310470,'ebb7c8e3fbe0b123a456d753b85b8c123ca3b315da14a00379ebd34784b28921',310470000,NULL,NULL,'d4b7cfd47924fae5118ab3f346be66d49ac5a077cb64c665078ea348745a18f4','76c11f8ba87594a217641c869b9018d64acdf1c1e3ff77bc6ef6ac4d0e4e0fa8','3a43b911cbfdcace91ce6f83bf3e614a81ef7b40128b995c389d4ff22349c729');
INSERT INTO blocks VALUES(310471,'fc6f8162c55ecffeaabb09f70f071fd0cb7a9ef1bccaafaf27fe9a936defb739',310471000,NULL,NULL,'cdcdac73dbc9eef131b7583b0d412eeacd3dc1f4984e9a22633cc876c5a5debd','1bc449467d2d156afd65325548e7b4984c04f6bc2dc774f3135aaaf9ca01f3cf','75ee2b7cfeb8295c7f5ca6f3a4ce30e8fc3767c05c9e85d208beca5f554c5e03');
INSERT INTO blocks VALUES(310472,'57ee5dec5e95b3d9c65a21c407294a32ed538658a6910b16124f18020f16bdf7',310472000,NULL,NULL,'9df3773d9f2b06f41c30123ec87e1516ca6e4652c1ae380bc9a9b49cd92ca19c','cd4fdc66fe86b2fd7bdee6fc58c3f9834de03e9be439aed2526386ed12e7f8ed','319bdfdb1837d3250f015d5b1f1926edb3e07a43a07d3fe6951ff50bfc96454d');
INSERT INTO blocks VALUES(310473,'33994c8f6d06134f886b47e14cb4b5af8fc0fd66e6bd60b3a71986622483e095',310473000,NULL,NULL,'12b9dae89f3cc6c714135698bdf4e4518967a3438f31fc7e01bb7e2778763ac3','76051a82a5551f733432b097d7288f7512d9d8a5cb14a05785592df400e80147','9e7fa36969a39b706b8011f722c42882e55fa0bf5d92f4efe7754190d19973ba');
INSERT INTO blocks VALUES(310474,'312ee99e9526e9c240d76e3c3d1fe4c0a21f58156a15f2789605b3e7f7794a09',310474000,NULL,NULL,'36c816730823a86edb9a67f8916bd7436bd50787a4eb941134e570a304d9cb81','12f23b997ea7cdb05b1ce1532735a9af5030e7427369bc90336491b89b37d090','fb8f5c21481e3c9ef3c145b73609a9b566a6c3f765807da4f08f24297282dba5');
INSERT INTO blocks VALUES(310475,'bb9289bcd79075962117aef1161b333dbc403efebd593d93fc315146a2f040eb',310475000,NULL,NULL,'7a08adc49c7aff8e86965518b8e8a31964c912131d9b3cabba224ea43ce20b16','862f8b32a6ce641e66c95c93252a9d9a52be46793ca3da08652c0287a1a32d14','2a35468a3eb0655dab729fe3787deedffa244af8c4d5c222031f412d188e34ab');
INSERT INTO blocks VALUES(310476,'3712e1ebd195749e0dc92f32f7f451dd76f499bf16d709462309ce358a9370d0',310476000,NULL,NULL,'2d608210df09b70d6f845ba2ed99a48c041b4038ad519e7cada03bca90be11df','a7d3e429ac2c903dbf40aa2902b72eea677dd6cc02cbddaa6ab65a5efdcf4de8','858fe80e57e0b5d961b8963b31082b69e1017b69e30e3f0b9d2f8a355e945359');
INSERT INTO blocks VALUES(310477,'7381973c554ac2bbdc849e8ea8c4a0ecbb46e7967d322446d0d83c3f9deab918',310477000,NULL,NULL,'6988e1c558eab63b16de834f5838264ebd1065ba768cb41c9eac4618fed7e28d','5de5d17f1d09f5c0beefeaf32b3d974230f0cd4f98fae2b45322ad7cb31ede21','8cb17a53e6274327ad4d06e367cf3ff96531da93d00973ef036423ec239f3550');
INSERT INTO blocks VALUES(310478,'c09ee871af7f2a611d43e6130aed171e301c23c5d1a29d183d40bf15898b4fa0',310478000,NULL,NULL,'5435f60ba80dd08018d8634353590babc60cf45c29c9f533858cc6b92dd5e2f2','810995e566feb56cf31dc85a52ce6a6a0a9e372932db9c5208cf35d323ff10bf','a4ea5bc868b8a6d63cdda2fd13b11495b978a6d08fbff4ebc06c4a22151a44bd');
INSERT INTO blocks VALUES(310479,'f3d691ce35f62df56d142160b6e2cdcba19d4995c01f802da6ce30bfe8d30030',310479000,NULL,NULL,'fbe6f79c90aced135ccc9056e316a76622b0643bf5447cee84bc0fff9c82a2d4','e4e42b19169ee1c4748b8bf86b6754c6ad4ed98fe00bdd513c2355675b22721b','80c07a230dfef3be493b7293627860b341da94cedb4da204e8dfec722b4df6ed');
INSERT INTO blocks VALUES(310480,'2694e89a62b3abd03a38dfd318c05eb5871f1be00a6e1bf06826fd54d142e681',310480000,NULL,NULL,'ea770919fc30bdbff527c8e12f4b4c51d7bced69e81e0aea801645c1e586678b','a2b1f3e1f8dcab5111c61334d3373171842e5095ac55831a9cbaaeac79ea0c61','11b1992dc0e39c220b607cada978345847d93341ad56ec63d7b279300b31fb70');
INSERT INTO blocks VALUES(310481,'db37d8f98630ebc61767736ae2c523e4e930095bf54259c01de4d36fd60b6f4a',310481000,NULL,NULL,'86614d79c35709f9a166eae9cf610a6a9f2f9c39b8bd8bc2bb419977b3abad53','85486cefb5859786a31b8e7bae6173dd7e6b47708094fa8f04e52a5c224f2a9a','f76bf6bb1157704e5f454ce826bf7e7a261f0370e3538bfbf722e5595f55d3c5');
INSERT INTO blocks VALUES(310482,'2e27db87dfb6439c006637734e876cc662d1ca74c717756f90f0e535df0787d6',310482000,NULL,NULL,'e2e6a0029a01a1487b76a2bcb9fb59aa8f4d445b64fb329dff3be731ada3e547','7b8590b822867a9064725a102d496b4787b81ed0ace37aa87817bc198b33e209','d7ffdb73381a5322a1889cd624ccffe09b9660e12be78acacd366db19a09f5ab');
INSERT INTO blocks VALUES(310483,'013bac61f8e33c8d8d0f60f5e6a4ec3de9b16696703dea9802f64a258601c460',310483000,NULL,NULL,'1da64dfe3bd7696e8a3f194c8a7efa26479ebd092b8a7c50c93f78dcacd61412','1ad0c1e5cf375be7c97f63c0d28e2ee5a53ec3f94e0edcc50f6f84f8d30e2f71','e3ef42d65e8d579f1591d6e461a0a169939623e9bceb13c20f0354e675da5e40');
INSERT INTO blocks VALUES(310484,'7cac2b3630c31b592fa0497792bed58d3c41120c009471c348b16b5578b3aa2b',310484000,NULL,NULL,'4bc5ae3209a1b836f4ebacf043b08480854226debfdf7c5d51d38478f06ee5a8','081aec7b08b62b393f5229ffb2a601d0b919b72edca57c130f80567a28bbd5f7','f82098ae6cea6210307c917515046b73c0bdb1f2bd765d0d2b1b1cfa48c96bbb');
INSERT INTO blocks VALUES(310485,'eab5febc9668cd438178496417b22da5f77ceaed5bb6e01fc0f04bef1f5b4478',310485000,NULL,NULL,'3dc38c7f546df648bca32cf500b03b447f6419796e7adede280222db9f671bc0','347bf54199bb807d4a9269f99f18014191913c3e18fa90b53a698821acca2458','46cb40c6ca3dfc0f65e56d44b68d01717319d47e65251cf91842cdca27846735');
INSERT INTO blocks VALUES(310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,NULL,NULL,'1a00f8df853c076b595bf0c71ae87a10325abb7ad7a6110170fc907b269a4a7a','eeef482cfddf265f85cdfdbae2bd822b018239afc3b826dbc8d16ab463f76a4e','2a7e9e0776ea82dedd3094d7075584e645ed79e2fd54bead6d285f3c5cdf69e1');
INSERT INTO blocks VALUES(310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,NULL,NULL,'960268f650fad8e09644dd29ca710f982563646d928208ce6c1657ea17e0be2d','cfaf136d219d153716826fd289ea53f0d3bfd0a61c761ade1ba6c8e83685200a','a36328bfd426346922f7ed777007055f1b85537377bc3cb47171168e49a18dc9');
INSERT INTO blocks VALUES(310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,NULL,NULL,'9fb8ae2dcf8867e5162364b78592cfb6db84a8deb31555412265b9d560f7a500','9656e8bcd4fbe87c638158a39b99c1f54f614168e2fef57a292024d8ec83bbf4','81958eb5ad2dd1ec336c8d11af94b35861529ecc2efb24c83c4baa105c9a018f');
INSERT INTO blocks VALUES(310489,'2efdb36f986b3e3ccc6cc9b0c1c3cdcb07429fb43cbc0cc3b6c87d1b33f258b6',310489000,NULL,NULL,'38da5c7438b53439db34b4d240cda0e8dcbc16ba0666606122546537b55eb0d7','303bde8a40dcd5ec7ab0badb12edd38bd86578f931b960107512636e24da5cfc','b108ad18da52176c252afba3e2cbcd12770110bfcdcb57f63dcc15167bee65ba');
INSERT INTO blocks VALUES(310490,'e2cb04b8a7368c95359c9d5ff33e64209200fb606de0d64b7c0f67bb1cb8d87c',310490000,NULL,NULL,'dae78d3312fa91d3af291f04cf02827decba9a9433b4b9cecab757f3141120f7','1b9d40526fc79bc9ecf0bbe30e35e55176e52c085cb5e98414ce9a02004ce619','581b5ff45e88099e36252bd6862538106610497bb5d1ac1db0dd755cb4d7f50f');
INSERT INTO blocks VALUES(310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,NULL,NULL,'e70fe57e120410c053ba1db138e9e90a246d20cfac8898fc06216aa75f511b6d','975d43ed821cced1142f0b2ce575ec9830f3ab046f6156a34da6cb512f213047','bedd3bcdb2f673fe9e176c1967afe0b95fe5a66f4e42c4f4c73203e431a9f6bf');
INSERT INTO blocks VALUES(310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,NULL,NULL,'2c76819b23cfcfdd6a42bdcede15cb90609629f4043ec711660ec54c3b0160c7','5a900a8d816f4fc7d39b73d05a9ec6d03e81b84f3ebac8fb79a419b64d17fc3e','152800621b537cc23cd71f9d61520087d0d17e9a9b26619cb01227c4424e37e5');
INSERT INTO blocks VALUES(310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,NULL,NULL,'6874c405ea0ad3c1c6bf83dbcfb70a63d24728b9527649f15404760359ab724e','b36c9378c44466494c76eeed5cdb432a3ae86d01ea8eda8b8aa9e2c0195f804c','9c6a34eb06ebc90056b8b211304595ca1387614db70f58b3e9d20a4a27eff6cf');
INSERT INTO blocks VALUES(310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,NULL,NULL,'10924b71e836afaf6d54030dca85f8ed39cf039023ce5adc48cbb5d1c5d15076','7a053c4f69bfb63e47d0023128fd678aecc754c2da16436208680cf2cf5dbb4f','ff27d85fbc8512fc4211b28b21c9097d2b5f923a11de0600d51a43859d447daf');
INSERT INTO blocks VALUES(310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,NULL,NULL,'468a16b160862ffb3d6211c95c837bdce190c863e5e9a22628ebbeef469ec019','a9133b35d3c8b6be972262442ad180f3aa1b5bbc793a4df9442124712c718015','0b00eb6d36b427129a3c1edcb66b612c231a7274555aa571bf31f13a101e7b72');
INSERT INTO blocks VALUES(310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,NULL,NULL,'2c30cc384954faeb07f565b483503d555677e4580ee5560623f88857d9d52dd7','edc3d08a637e834fc81e3414e4ddc17d4483da23f316f193600ca402de7a5789','1070466ae43348c719f2307e426e8eee2b9b1877a13c2a2f76adbc0d394bbe08');
INSERT INTO blocks VALUES(310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,NULL,NULL,'036bfddac9d52271617196b3e51418ea5232d4ec8f21b26da0697ef6b37af6cd','15811e2fd65f39d93b75ceb843e599de8dcfb1883a38b7e535a6c5c3729f178e','050b008ff19efe8d4384c78ac38ed8e7fac8eccb00dda42692638c27a77afe13');
INSERT INTO blocks VALUES(310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,NULL,NULL,'1f9ae1ab93d1fd4cebef5377eaa525c5c6e0c4a3c292e0b3cbbd43b9ce095db8','ccf8ddb21e2e2eac860a7f5e4f769e9f1698125f94e2b4cae6d233eec2dc587d','59603c18487cd7bffd3b30d628602e383c3a11674bc734df58aae55759a76fe7');
INSERT INTO blocks VALUES(310499,'1950e1a4d7fc820ed9603f6df6819c3c953c277c726340dec2a4253e261a1764',310499000,NULL,NULL,'e6a8fc9cb4c5c0cc395c2eed8ac5cca60f4147729aa04003eb561492eb7c0e5a','dd3302322e1eb83330e61be0465a5ee846b86641a0897752eebf11d1bd90dbd5','3598c2f5b37e0cca85a823f2ceee3b6d490058f8d924e63d62092683cf609ee4');
INSERT INTO blocks VALUES(310500,'54aeaf47d5387964e2d51617bf3af50520a0449410e0d096cf8c2aa9dad5550b',310500000,NULL,NULL,'076b520e5dbee43fe4b278ca77cacbeea1c781a667691ba39f38de9850e0331f','0c99a68fe09ec53a1a1687e050ffb1aeee7331d8069ba119a465fcdd7686ad7b','8d732fac7d787e85276d93c9284cdf6b9d9b990abd430685c51da50a072120d2');
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
INSERT INTO broadcasts VALUES(489,'19ffc80e150a6c23bf8f0470a05b1a174fe4845eafd7aedd969b25384c61e9a3',310488,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',1388000002,1.0,0,'options 0',0,'valid');
INSERT INTO broadcasts VALUES(490,'baecfb24773f385a86194dce64b380bf3460174b376bdc16e4045483721e18e3',310489,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',0,NULL,NULL,NULL,1,'valid');
INSERT INTO broadcasts VALUES(491,'51bd28ebd25e4e57b96da2e0be7e73c14b10153d616fc54646668c1b5a376d81',310490,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',1388000004,1.0,0,'options 1',0,'valid');
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
INSERT INTO credits VALUES(310111,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','LOCKEDPREV',1000,'issuance','fd6320f6a59b69a154ca376ea67e9b0ac49b5ff178e1442d8048cd29f7989031');
INSERT INTO credits VALUES(310481,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'send','e864d7881d5c6a57b650dd507096275647eb32c05e3a27815869133a79a9db6f');
INSERT INTO credits VALUES(310482,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'send','b9ad301585a4f779a15adb7c357215918a22a0c32d78f1fc622122dce2ba46c2');
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
INSERT INTO debits VALUES(310111,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',50000000,'issuance fee','fd6320f6a59b69a154ca376ea67e9b0ac49b5ff178e1442d8048cd29f7989031');
INSERT INTO debits VALUES(310112,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',0,'issuance fee','b431644c7de3f9abd6390119013c26d94a974e154b9d724623239305a31ce46f');
INSERT INTO debits VALUES(310113,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',0,'issuance fee','bec2fed840c77cd7ef57690ed52e8963e39eb6f2f9051ddcda48fddbc908c7d9');
INSERT INTO debits VALUES(310481,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'send','e864d7881d5c6a57b650dd507096275647eb32c05e3a27815869133a79a9db6f');
INSERT INTO debits VALUES(310482,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'send','b9ad301585a4f779a15adb7c357215918a22a0c32d78f1fc622122dce2ba46c2');
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
INSERT INTO issuances VALUES(112,'fd6320f6a59b69a154ca376ea67e9b0ac49b5ff178e1442d8048cd29f7989031',310111,'LOCKEDPREV',1000,1,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',0,0,0,0.0,'Locked asset',50000000,0,'valid',NULL);
INSERT INTO issuances VALUES(113,'b431644c7de3f9abd6390119013c26d94a974e154b9d724623239305a31ce46f',310112,'LOCKEDPREV',0,1,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',0,0,0,0.0,'Locked asset',0,1,'valid',NULL);
INSERT INTO issuances VALUES(114,'bec2fed840c77cd7ef57690ed52e8963e39eb6f2f9051ddcda48fddbc908c7d9',310113,'LOCKEDPREV',0,1,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',0,0,0,0.0,'changed',0,0,'valid',NULL);
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
INSERT INTO messages VALUES(80,310111,'insert','debits','{"action": "issuance fee", "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "asset": "XCP", "block_index": 310111, "event": "fd6320f6a59b69a154ca376ea67e9b0ac49b5ff178e1442d8048cd29f7989031", "quantity": 50000000}',0);
INSERT INTO messages VALUES(81,310111,'insert','issuances','{"asset": "LOCKEDPREV", "asset_longname": null, "block_index": 310111, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Locked asset", "divisible": true, "fee_paid": 50000000, "issuer": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "locked": false, "quantity": 1000, "source": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "status": "valid", "transfer": false, "tx_hash": "fd6320f6a59b69a154ca376ea67e9b0ac49b5ff178e1442d8048cd29f7989031", "tx_index": 112}',0);
INSERT INTO messages VALUES(82,310111,'insert','credits','{"action": "issuance", "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "asset": "LOCKEDPREV", "block_index": 310111, "event": "fd6320f6a59b69a154ca376ea67e9b0ac49b5ff178e1442d8048cd29f7989031", "quantity": 1000}',0);
INSERT INTO messages VALUES(83,310112,'insert','debits','{"action": "issuance fee", "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "asset": "XCP", "block_index": 310112, "event": "b431644c7de3f9abd6390119013c26d94a974e154b9d724623239305a31ce46f", "quantity": 0}',0);
INSERT INTO messages VALUES(84,310112,'insert','issuances','{"asset": "LOCKEDPREV", "asset_longname": null, "block_index": 310112, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Locked asset", "divisible": true, "fee_paid": 0, "issuer": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "locked": true, "quantity": 0, "source": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "status": "valid", "transfer": false, "tx_hash": "b431644c7de3f9abd6390119013c26d94a974e154b9d724623239305a31ce46f", "tx_index": 113}',0);
INSERT INTO messages VALUES(85,310113,'insert','debits','{"action": "issuance fee", "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "asset": "XCP", "block_index": 310113, "event": "bec2fed840c77cd7ef57690ed52e8963e39eb6f2f9051ddcda48fddbc908c7d9", "quantity": 0}',0);
INSERT INTO messages VALUES(86,310113,'insert','issuances','{"asset": "LOCKEDPREV", "asset_longname": null, "block_index": 310113, "call_date": 0, "call_price": 0.0, "callable": false, "description": "changed", "divisible": true, "fee_paid": 0, "issuer": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "locked": false, "quantity": 0, "source": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "status": "valid", "transfer": false, "tx_hash": "bec2fed840c77cd7ef57690ed52e8963e39eb6f2f9051ddcda48fddbc908c7d9", "tx_index": 114}',0);
INSERT INTO messages VALUES(87,310481,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310481, "event": "e864d7881d5c6a57b650dd507096275647eb32c05e3a27815869133a79a9db6f", "quantity": 100000000}',0);
INSERT INTO messages VALUES(88,310481,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310481, "event": "e864d7881d5c6a57b650dd507096275647eb32c05e3a27815869133a79a9db6f", "quantity": 100000000}',0);
INSERT INTO messages VALUES(89,310481,'insert','sends','{"asset": "XCP", "block_index": 310481, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "memo": "68656c6c6f", "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "e864d7881d5c6a57b650dd507096275647eb32c05e3a27815869133a79a9db6f", "tx_index": 482}',0);
INSERT INTO messages VALUES(90,310482,'insert','debits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310482, "event": "b9ad301585a4f779a15adb7c357215918a22a0c32d78f1fc622122dce2ba46c2", "quantity": 100000000}',0);
INSERT INTO messages VALUES(91,310482,'insert','credits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310482, "event": "b9ad301585a4f779a15adb7c357215918a22a0c32d78f1fc622122dce2ba46c2", "quantity": 100000000}',0);
INSERT INTO messages VALUES(92,310482,'insert','sends','{"asset": "XCP", "block_index": 310482, "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "memo": "fade0001", "quantity": 100000000, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "valid", "tx_hash": "b9ad301585a4f779a15adb7c357215918a22a0c32d78f1fc622122dce2ba46c2", "tx_index": 483}',0);
INSERT INTO messages VALUES(93,310486,'insert','broadcasts','{"block_index": 310486, "fee_fraction_int": 5000000, "locked": false, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "81a5d20db79a4b620221ba646fec2699b4e4d1c854bb4022b0550bd7d274a5b8", "tx_index": 487, "value": 1.0}',0);
INSERT INTO messages VALUES(94,310487,'insert','debits','{"action": "bet", "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "asset": "XCP", "block_index": 310487, "event": "c9cfc39f98307a845d1d27d4a9ad66b19e0c38f59be14ed0c4b9d4ec15cb0940", "quantity": 9}',0);
INSERT INTO messages VALUES(95,310487,'insert','bets','{"bet_type": 1, "block_index": 310487, "counterwager_quantity": 9, "counterwager_remaining": 9, "deadline": 1388000001, "expiration": 100, "expire_index": 310587, "fee_fraction_int": 5000000.0, "feed_address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "leverage": 5040, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "open", "target_value": 0.0, "tx_hash": "c9cfc39f98307a845d1d27d4a9ad66b19e0c38f59be14ed0c4b9d4ec15cb0940", "tx_index": 488, "wager_quantity": 9, "wager_remaining": 9}',0);
INSERT INTO messages VALUES(96,310488,'insert','broadcasts','{"block_index": 310488, "fee_fraction_int": 0, "locked": false, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": "options 0", "timestamp": 1388000002, "tx_hash": "19ffc80e150a6c23bf8f0470a05b1a174fe4845eafd7aedd969b25384c61e9a3", "tx_index": 489, "value": 1.0}',0);
INSERT INTO messages VALUES(97,310488,'insert','replace','{"address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "block_index": 310488, "options": 0}',0);
INSERT INTO messages VALUES(98,310489,'insert','broadcasts','{"block_index": 310489, "fee_fraction_int": null, "locked": true, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": null, "timestamp": 0, "tx_hash": "baecfb24773f385a86194dce64b380bf3460174b376bdc16e4045483721e18e3", "tx_index": 490, "value": null}',0);
INSERT INTO messages VALUES(99,310490,'insert','broadcasts','{"block_index": 310490, "fee_fraction_int": 0, "locked": false, "source": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "status": "valid", "text": "options 1", "timestamp": 1388000004, "tx_hash": "51bd28ebd25e4e57b96da2e0be7e73c14b10153d616fc54646668c1b5a376d81", "tx_index": 491, "value": 1.0}',0);
INSERT INTO messages VALUES(100,310490,'insert','replace','{"address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "block_index": 310490, "options": 1}',0);
INSERT INTO messages VALUES(101,310491,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310491, "event": "301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7", "quantity": 100000000}',0);
INSERT INTO messages VALUES(102,310491,'insert','orders','{"block_index": 310491, "expiration": 2000, "expire_index": 312491, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 800000, "get_remaining": 800000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7", "tx_index": 492}',0);
INSERT INTO messages VALUES(103,310492,'insert','orders','{"block_index": 310492, "expiration": 2000, "expire_index": 312492, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 800000, "give_remaining": 800000, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "tx_hash": "14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0", "tx_index": 493}',0);
INSERT INTO messages VALUES(104,310492,'update','orders','{"fee_provided_remaining": 6800, "fee_required_remaining": 892800, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7"}',0);
INSERT INTO messages VALUES(105,310492,'update','orders','{"fee_provided_remaining": 992800, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0"}',0);
INSERT INTO messages VALUES(106,310492,'insert','order_matches','{"backward_asset": "BTC", "backward_quantity": 800000, "block_index": 310492, "fee_paid": 7200, "forward_asset": "XCP", "forward_quantity": 100000000, "id": "301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7_14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0", "match_expire_index": 310512, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 310491, "tx0_expiration": 2000, "tx0_hash": "301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7", "tx0_index": 492, "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_block_index": 310492, "tx1_expiration": 2000, "tx1_hash": "14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0", "tx1_index": 493}',0);
INSERT INTO messages VALUES(107,310493,'insert','credits','{"action": "burn", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310493, "event": "0d88550e8361676614215372d3482d7749ddfe81d12fff58ce80a598dd0d368d", "quantity": 92995878046}',0);
INSERT INTO messages VALUES(108,310493,'insert','burns','{"block_index": 310493, "burned": 62000000, "earned": 92995878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "0d88550e8361676614215372d3482d7749ddfe81d12fff58ce80a598dd0d368d", "tx_index": 494}',0);
INSERT INTO messages VALUES(109,310494,'insert','debits','{"action": "issuance fee", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310494, "event": "89f7e46840b55a8134ca6950f804862a5a89fbc07dfa223300a07daeaad9719f", "quantity": 50000000}',0);
INSERT INTO messages VALUES(110,310494,'insert','issuances','{"asset": "DIVIDEND", "asset_longname": null, "block_index": 310494, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Test dividend", "divisible": true, "fee_paid": 50000000, "issuer": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "locked": false, "quantity": 100, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "transfer": false, "tx_hash": "89f7e46840b55a8134ca6950f804862a5a89fbc07dfa223300a07daeaad9719f", "tx_index": 495}',0);
INSERT INTO messages VALUES(111,310494,'insert','credits','{"action": "issuance", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310494, "event": "89f7e46840b55a8134ca6950f804862a5a89fbc07dfa223300a07daeaad9719f", "quantity": 100}',0);
INSERT INTO messages VALUES(112,310495,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310495, "event": "3c3e750a0a8f27fba67480957f85907f22a52d45385132d73d7fdc1c8e38107d", "quantity": 10}',0);
INSERT INTO messages VALUES(113,310495,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "DIVIDEND", "block_index": 310495, "event": "3c3e750a0a8f27fba67480957f85907f22a52d45385132d73d7fdc1c8e38107d", "quantity": 10}',0);
INSERT INTO messages VALUES(114,310495,'insert','sends','{"asset": "DIVIDEND", "block_index": 310495, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 10, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "3c3e750a0a8f27fba67480957f85907f22a52d45385132d73d7fdc1c8e38107d", "tx_index": 496}',0);
INSERT INTO messages VALUES(115,310496,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310496, "event": "478048dcdaca3e8010fc50a75511f6ed8fc1a770a4fab5c339a1c15c3633971f", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(116,310496,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "XCP", "block_index": 310496, "event": "478048dcdaca3e8010fc50a75511f6ed8fc1a770a4fab5c339a1c15c3633971f", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(117,310496,'insert','sends','{"asset": "XCP", "block_index": 310496, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 92945878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "478048dcdaca3e8010fc50a75511f6ed8fc1a770a4fab5c339a1c15c3633971f", "tx_index": 497}',0);
INSERT INTO messages VALUES(118,310497,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310497, "event": "b1a5f2dd0e4c14a093ba5353f8944fa6ccd64f21b7626b5e225deea9f6cc7470", "quantity": 50000000}',0);
INSERT INTO messages VALUES(119,310497,'insert','issuances','{"asset": "PARENT", "asset_longname": null, "block_index": 310497, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Parent asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "b1a5f2dd0e4c14a093ba5353f8944fa6ccd64f21b7626b5e225deea9f6cc7470", "tx_index": 498}',0);
INSERT INTO messages VALUES(120,310497,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "PARENT", "block_index": 310497, "event": "b1a5f2dd0e4c14a093ba5353f8944fa6ccd64f21b7626b5e225deea9f6cc7470", "quantity": 100000000}',0);
INSERT INTO messages VALUES(121,310498,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310498, "event": "2aabeff2dd379ed8d9d1400adcf6f7a375cad02aafc9de1268054839a5110d16", "quantity": 25000000}',0);
INSERT INTO messages VALUES(122,310498,'insert','issuances','{"asset": "A95428956661682277", "asset_longname": "PARENT.already.issued", "block_index": 310498, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Child of parent", "divisible": true, "fee_paid": 25000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "2aabeff2dd379ed8d9d1400adcf6f7a375cad02aafc9de1268054839a5110d16", "tx_index": 499}',0);
INSERT INTO messages VALUES(123,310498,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "A95428956661682277", "block_index": 310498, "event": "2aabeff2dd379ed8d9d1400adcf6f7a375cad02aafc9de1268054839a5110d16", "quantity": 100000000}',0);
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
                      status TEXT, memo BLOB,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
INSERT INTO sends VALUES(8,'bdb55efb18b339207aa6483329a803fda6248e8bcf68b819708445d2c719f43d',310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','DIVISIBLE',100000000,'valid',NULL);
INSERT INTO sends VALUES(9,'663e6e10810403876bf8d5c1bc8715a44c82bfb4a2e5e98fa63ab65fc04cc55b',310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'valid',NULL);
INSERT INTO sends VALUES(13,'631f6b5166129fd3d69dbd4a8096707d61942acb55fd2100547a39d53bd8b5b6',310012,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',300000000,'valid',NULL);
INSERT INTO sends VALUES(14,'c91791d284a75383678ee71817775bbdfa7e22ffbbc561dbe782614121e625a5',310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','DIVISIBLE',1000000000,'valid',NULL);
INSERT INTO sends VALUES(15,'c3875a3cc9c8c967f8ff0accbc37f728e0bb038672c2cb19325ddb6bdb53465d',310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','NODIVISIBLE',5,'valid',NULL);
INSERT INTO sends VALUES(16,'f74ffb36b1ca86e0dc9305f31671c3866817fe575463cc8b982174a19f349746',310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','NODIVISIBLE',10,'valid',NULL);
INSERT INTO sends VALUES(109,'5776bcda35a58d001e71552bc6fd2de3764495ce50f16b3b806a986935ca5520',310108,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000,'valid',NULL);
INSERT INTO sends VALUES(482,'e864d7881d5c6a57b650dd507096275647eb32c05e3a27815869133a79a9db6f',310481,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'valid',X'68656C6C6F');
INSERT INTO sends VALUES(483,'b9ad301585a4f779a15adb7c357215918a22a0c32d78f1fc622122dce2ba46c2',310482,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'valid',X'FADE0001');
INSERT INTO sends VALUES(496,'3c3e750a0a8f27fba67480957f85907f22a52d45385132d73d7fdc1c8e38107d',310495,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','DIVIDEND',10,'valid',NULL);
INSERT INTO sends VALUES(497,'478048dcdaca3e8010fc50a75511f6ed8fc1a770a4fab5c339a1c15c3633971f',310496,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','XCP',92945878046,'valid',NULL);
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
INSERT INTO transactions VALUES(112,'fd6320f6a59b69a154ca376ea67e9b0ac49b5ff178e1442d8048cd29f7989031',310111,'fde71b9756d5ba0b6d8b230ee885af01f9c4461a55dbde8678279166a21b20ae',310111000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','',0,-99993200,X'00000014000038FEDF6D2C6900000000000003E8010000000000000000000C4C6F636B6564206173736574',1);
INSERT INTO transactions VALUES(113,'b431644c7de3f9abd6390119013c26d94a974e154b9d724623239305a31ce46f',310112,'5b06f69bfdde1083785cf68ebc2211b464839033c30a099d3227b490bf3ab251',310112000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','',0,-99993200,X'00000014000038FEDF6D2C69000000000000000001000000000000000000044C4F434B',1);
INSERT INTO transactions VALUES(114,'bec2fed840c77cd7ef57690ed52e8963e39eb6f2f9051ddcda48fddbc908c7d9',310113,'63914cf376d3076b697b9234810dfc084ed5a885d5cd188dd5462560da25d5e7',310113000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','',0,-99993200,X'00000014000038FEDF6D2C69000000000000000001000000000000000000076368616E676564',1);
INSERT INTO transactions VALUES(482,'e864d7881d5c6a57b650dd507096275647eb32c05e3a27815869133a79a9db6f',310481,'db37d8f98630ebc61767736ae2c523e4e930095bf54259c01de4d36fd60b6f4a',310481000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,7025,X'0000000200000000000000010000000005F5E1006F8D6AE8A3B381663118B4E1EFF4CFC7D0954DD6EC68656C6C6F',1);
INSERT INTO transactions VALUES(483,'b9ad301585a4f779a15adb7c357215918a22a0c32d78f1fc622122dce2ba46c2',310482,'2e27db87dfb6439c006637734e876cc662d1ca74c717756f90f0e535df0787d6',310482000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','',0,7025,X'0000000200000000000000010000000005F5E1006F4838D8B3588C4C7BA7C1D06F866E9B3739C63037FADE0001',1);
INSERT INTO transactions VALUES(487,'81a5d20db79a4b620221ba646fec2699b4e4d1c854bb4022b0550bd7d274a5b8',310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','',0,-99993200,X'0000001E52BB33003FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(488,'c9cfc39f98307a845d1d27d4a9ad66b19e0c38f59be14ed0c4b9d4ec15cb0940',310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',5430,-99992350,X'00000028000152BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(489,'19ffc80e150a6c23bf8f0470a05b1a174fe4845eafd7aedd969b25384c61e9a3',310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','',0,-99993200,X'0000001E52BB33023FF000000000000000000000096F7074696F6E732030',1);
INSERT INTO transactions VALUES(490,'baecfb24773f385a86194dce64b380bf3460174b376bdc16e4045483721e18e3',310489,'2efdb36f986b3e3ccc6cc9b0c1c3cdcb07429fb43cbc0cc3b6c87d1b33f258b6',310489000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','',0,-99993200,X'0000001E52BB33033FF000000000000000000000046C6F636B',1);
INSERT INTO transactions VALUES(491,'51bd28ebd25e4e57b96da2e0be7e73c14b10153d616fc54646668c1b5a376d81',310490,'e2cb04b8a7368c95359c9d5ff33e64209200fb606de0d64b7c0f67bb1cb8d87c',310490000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','',0,-99993200,X'0000001E52BB33043FF000000000000000000000096F7074696F6E732031',1);
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
INSERT INTO undolog VALUES(166,'UPDATE orders SET tx_index=492,tx_hash=''301207b62ade0707eeab94a413cb7b6be1886de25b22854e953861789385e5e7'',block_index=310491,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''XCP'',give_quantity=100000000,give_remaining=100000000,get_asset=''BTC'',get_quantity=800000,get_remaining=800000,expiration=2000,expire_index=312491,fee_required=900000,fee_required_remaining=900000,fee_provided=6800,fee_provided_remaining=6800,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(167,'UPDATE orders SET tx_index=493,tx_hash=''14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0'',block_index=310492,source=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',give_asset=''BTC'',give_quantity=800000,give_remaining=800000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=2000,expire_index=312492,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=6');
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
