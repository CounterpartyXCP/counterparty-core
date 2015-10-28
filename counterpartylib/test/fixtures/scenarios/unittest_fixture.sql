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
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',91950000000);
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',98900000000);
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
INSERT INTO balances VALUES('mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',0);
INSERT INTO balances VALUES('mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','DIVIDEND',90);
INSERT INTO balances VALUES('mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','DIVIDEND',10);
INSERT INTO balances VALUES('mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','XCP',92945878046);
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
INSERT INTO bet_match_resolutions VALUES('be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd_90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5',1,310102,'1',9,9,NULL,NULL,0);
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
INSERT INTO bet_matches VALUES('be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd_90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5',20,'be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',21,'90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',1,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000001,0.0,5040,9,9,310019,310020,310020,100,100,310119,5000000,'settled');
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
INSERT INTO bets VALUES(20,'be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd',310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000001,9,0,9,0,0.0,5040,100,310119,5000000,'filled');
INSERT INTO bets VALUES(21,'90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5',310020,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1388000001,9,0,9,0,0.0,5040,100,310120,5000000,'filled');
INSERT INTO bets VALUES(102,'ba0ef1dfbbc87df94e1d198b0e9e3c06301710d4aab3d85116cbc8199954644a',310101,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',3,1388000200,10,10,10,10,0.0,5040,1000,311101,5000000,'open');
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
INSERT INTO blocks VALUES(309999,'4b5b541fe4ea8e9f9470af202bb6597a368e47cb82afe6f5cee42d8324f667640c580cb69dce4808dfb530b8d698db315d190792647c83be6a7446511950834a',309999000,NULL,NULL,NULL,NULL,NULL);
INSERT INTO blocks VALUES(310000,'2ee5123266f21fb8f65495c281a368e1b9f93b6c411986e06efc895a8d82467683e6ea5d863714b23582c1c59576650d07c405a8d9bf0d088ee65621178b259d',310000000,NULL,NULL,'f3e1d432b546670845393fae1465975aa99602a7648e0da125e6b8f4d55cbcac','0fc8b9a115ba49c78879c5d75b92bdccd2f5e398e8e8042cc9d0e4568cea9f53','88838f2cfc1eef675714adf7cfef07e7934a12ae60cfa75ca571888ef3d47b5c');
INSERT INTO blocks VALUES(310001,'03a9a24e190a996364217761558e380b94ae9792b8b4dcaa92b6c58d80b9f8f7fcf9a34037be4cd6ad5e0c039b511cccc40c3438a5067822e3cd309f06519612',310001000,NULL,NULL,'6a91073b35d1151c0b9b93f7916d25e6650b82fe4a1b006851d69b1112cd2954','490572196d4b3d303697f55cc9bf8fe29a4ae659dfc51f63a6af37cb5593413b','0e5a1d103303445b9834b0a01d1179e522ff3389a861f0517b2ee061a9bc1c57');
INSERT INTO blocks VALUES(310002,'d574e4fee71454532c0207f27b9c46f07c5c2e20f43829ddeee8f798053413ac6e0d1b9ad2259a0370fe08581fab3e950ce629db5fadd823251254bf606a05bd',310002000,NULL,NULL,'88eac1faa671a7ebc61f63782c4b74d42c813c19e410e240843440f4d4dbaa35','e944f6127f7d13409ace137a670d1503a5412488942fdf7e858fcd99b70e4c2a','d5e23e344547beb15ed6eb88f54504d2f4a8062279e0053a2c9c679655e1870c');
INSERT INTO blocks VALUES(310003,'44392d9d661459ba31140c59e7d8bcd16b071c864c59f65e2edd9e3c16d598e81aaba40f11019a379bfc6d7811e0265fbb8b276d99cdea7f739fb736f433052a',310003000,NULL,NULL,'93d430c0d7a680aad6fb162af200e95e177ba5d604df1e3cb0e086d3959538c3','d9ba1ab8640ac01642eacf28d3f618a222cc40377db418b1313d880ecb88bce8','c3371ad121359321f66af210da3f7d35b83d45074720a18cb305508ad5a60229');
INSERT INTO blocks VALUES(310004,'58c6f6fbf77a64a5e0df123b1258ae6c3e6d4e21901cc942aeb67b1332422c71e1e7e996c5d4f403159ce5ca3863b7ec7ef8281bbbce5960e258492872055fb5',310004000,NULL,NULL,'e85e5d82a20fe2e060a7c1f79dc182d3b2da28903b04302e6abe4a3f935ea373','acc9a12b365f51aa9efbe5612f812bf926ef8e5e3bf057c42877aeea1049ee49','ca4856a25799772f900671b7965ecdc36a09744654a1cd697f18969e22850b8a');
INSERT INTO blocks VALUES(310005,'348a1b690661597ee6e950446e7a1deb8bef7906c0e98a78ab4d0fe799fac5f3007dcd648ff0c61da35b19cf99f16f3028e10ba206968475d741fa8a86c4a7ae',310005000,NULL,NULL,'c6c0f780ffa18de5a5e5afdf4fba5b6a17dce8d767d4b7a9fbbae2ad53ff4718','e9410f15a3b9c93d8416d57295d3a8e03d6313eb73fd2f00678d2f3a8f774e03','db34d651874da19cf2a4fcf50c44f4be7c6e40bc5a0574a46716f10c235b9c43');
INSERT INTO blocks VALUES(310006,'9d31b774b633c35635b71669c07880b521880cee9298b6aba44752ec1734cd2aa26b3bed95409d874e68685636a31a038b784d3e085525ab8c26f7e3b7ba3676',310006000,NULL,NULL,'91458f37f5293fca71cddc6f14874670584e750aa68fbe577b22eac357c5f336','ed50224a1ca02397047900e5770da64a9eb6cb62b6b5b4e57f12d08c5b57ab93','c909c99a5218c152196071f4df6c3dfa2cfdaa70af26e3fc6a490a270ff29339');
INSERT INTO blocks VALUES(310007,'41007a4ed39e7df941059c3db6b24b74c1913b80e0fd38d0073a5b121880fd0f7e98989d8d70766957919371fdaf4e5b44125f9f7c449c3b6bea298253075fe3',310007000,NULL,NULL,'a8f0f81aebdf77ee1945c2199142696f2c74518f2bc1a45dcfd3cebcabec510c','1635973c36f5d7efc3becc95a2667c1bb808edc692ff28eaa5f5849b7cdb4286','fb670f2509a3384f1c75cfa89770da9f9315cbda733fd6cdb1db89e7bbc80608');
INSERT INTO blocks VALUES(310008,'aa28e5948d1158f318393846b4ef67e53ca4c4b047ed8b06eb861db29914e9f1dfe11a8b73aa2225519843661a61e9038cb347015be916c5a44222ed71b8b604',310008000,NULL,NULL,'df7cae2ef1885eb5916f821be0bb11c24c9cabdc6ccdc84866d60de6af972b94','e7dde4bb0a7aeab7df2cd3f8a39af3d64dd98ef64efbc253e4e6e05c0767f585','4e11197b5662b57b1e8b21d196f1d0bae927e36c4b4634539dd63b1df8b7aa99');
INSERT INTO blocks VALUES(310009,'550d7d84590c6e4e7caed4e722151f7e110dc39bf3f54f719babfe89775095abb2d2454014b4cb01fb1e0a7e91639559ce17e096be5178b5c2ca5b22ad41b33a',310009000,NULL,NULL,'1d8caac58a9e5a656a6631fe88be72dfb45dbc25c64d92558db268be01da6024','74b7425efb6832f9cd6ffea0ae5814f192bb6d00c36603700af7a240f878da95','fc53cd08e684798b74bb5b282b72ea18166a7ae83a64ff9b802ae3e3ea6c1d13');
INSERT INTO blocks VALUES(310010,'477c4a3445e32cd0c8ef67c808ac6a6362ebc953c396e2d5c0d7e4f185becd15fa99bd7635358dbb3b5a92e9f03b7fa2dda8d4714e181ec4552b279df3ba81f0',310010000,NULL,NULL,'ab78a209c465104945458dba209c03409f839d4882a1bf416c504d26fd8b9c80','d4bdc625dead1b87056b74aa843ae9b47a1b61bb63aafc32a04137d5022d67e4','2398b32d34b43c20a0965532863ed3ddd21ee095268ba7d8933f31e417a3689e');
INSERT INTO blocks VALUES(310011,'05f81b5c1b067b647894014cea65558826be42cca20a6cccb8623d80059182b77da00922539c59a0a7b63f6f011ca0f564fada0451e891644728b874c65267b9',310011000,NULL,NULL,'5528fec20bfacc31dd43d7284bf1df33e033ec0ac12b14ed813a9dfea4f67741','205fad5e739d6736a483dde222d3fdfc0014a5af1fa1981e652a0fe948d883b3','3f9d7e91b4cfc760c5fa6805975002c258a48e2bc0a9e754bcc69be8e0cb74e5');
INSERT INTO blocks VALUES(310012,'e9d898aae43fc103110e4935cabf01b6016571b1af82e27af04b57c12302b05eab217f075ac3344b0a422e76b8c762c119cb290c867bb6eed432994ec28af027',310012000,NULL,NULL,'fa66dc025cbb75b67a7d4c496141eb5f6f0cc42134433276c8a294c983453926','ff933c5dfc4364dc6fa3faa2d5da4096bd1261cc53f74a20af9e55a4dda2d08b','1993f3234c4025eab5bb95ac516594b99c4068b1352652f0327f4fa6c8684d17');
INSERT INTO blocks VALUES(310013,'2251b497007459321f72cda82681d07d131dd81cc29137b18c534bbb09271678f4497d0316ffac262f021f901078926dee11c791a3524ad850ee948474abd3b5',310013000,NULL,NULL,'442621791a488568ee9dee5d9131db3ce2f17d9d87b4f45dc8079606874823f8','337f673aa1457d390abc97512fbaa5590e4f5e06d663e82627f70fd23c558655','dbe86ee55a221aa0541367039bb0f51ccac45530dd78b0a9b0292b175cef6e56');
INSERT INTO blocks VALUES(310014,'f98fb331e66361507190a1cb1df81b814d24517e7f219029c068b649c9b8a75703770369ebafd864d104225d6fe1fbf13705d1a37a819b04fb151ed390d7bcf8',310014000,NULL,NULL,'8551367f346e50b15c6e0cca116d1697d3301725b73562f62d8e4c53581e7bd0','f1f9d937b2f6f2221055c9f967207accd58a388a33677fd7572c882ce2e65b0e','9e054d7d63e96da38b2bb4715a627e3f4f322b8d86a8ad569a9e2e780c036f46');
INSERT INTO blocks VALUES(310015,'7c25469d6b4fed0e8bb9e4325994c4de1737570fece605b4ca388be6921406b64a395dc519b33c0dff4f93930b32737a941bbb850e31f2ebcd2caba520bc2820',310015000,NULL,NULL,'29de016d6301c2c9be33c98d3ca3e5f2dd25d52fd344426d40e3b0126dea019a','e0051523f6891110c18a2250db797d39d6ffd917aeb446906f8059b293e20be6','98ac9ef994c9b058395d5726fb29303fb90ae1cb4130535c9a9525e61dda0702');
INSERT INTO blocks VALUES(310016,'9f1c56677b369099f059cc145b98f2e3f8895631cdf0f72b7fe76fd953ab68c202329848dfb53f8146552876eba37f50ed02da34f23447f518449bf0ac0cc29e',310016000,NULL,NULL,'32ffd4bdf9b1f8506a25b4d2affe792d1eccf322a9ab832ec71a934fea136db9','0c90d5431f84b4fd0739bfe750ddd2b65f1bfee26f3b576f2df5dc77537389ab','8588b5ccadd1f93f8bce990c723efb6118b90d4491cc7ada4cda296469f5a635');
INSERT INTO blocks VALUES(310017,'4c02945de20ccdc874ae21bf56aea2f40a029c17b81fcf602b367bdbc286f9ec0cacab35fc07ac60aefa4a96a586aed20129ad66d45ab87697704d731e06b40d',310017000,NULL,NULL,'64aa58f7e48dfa10bb48ecf48571d832bb94027c7ac07be0d23d5379452ce03b','ee2aa8e8b5c16ff20dc4a37c5483c7b1b9498b3f77cab630c910e29540c3a4f9','a5b974e881ec4e947974f2441f5af722673d08e55dc3daa5d5e0a717080962bf');
INSERT INTO blocks VALUES(310018,'6a26d120314af1710052c8f8f78453f944a146039679c781e04ddbb5a2d010927726fa6f81d3e01fc1fcc3363c06e8e1a81a35636684c4dbcd51edf561a9c0fc',310018000,NULL,NULL,'8d8f404bdc2fb6178286b2581cf8a23e6028d5d285091fa0e67e96e6da91f54e','be9eab485a9d7cba91072ae17389b123dc865fd84b70750f225c76dcdaac1f27','65f30e31bc64ea4f4a2cb6db890a5769b97b32e0bf3a992302b619bfac0af60e');
INSERT INTO blocks VALUES(310019,'592e775a9259b1a5a7b0d7c2e028ff320783e7b49243ed6a20ece89a72964f3af4ed129698c4a143ad682a1493f982c5f8193d3b0e36b3df43964520409beb7a',310019000,NULL,NULL,'945a8fd2f57cfd5ddab542291fb2e2813762806b806a3e65e688321fefe1986d','7f518d7dec7a31e52840d975a26c5d96d3a202d30d4977205fc14cf76b93dcf2','da444b5d4accf056c6fade57c38869d51a3d9ca102df5c937675398b4b6060b0');
INSERT INTO blocks VALUES(310020,'87fac74eef20e6121d9a66c90481f801a10d636976a6a6e7cf42fc38cc104a470e1b4cab3f9670be86c93ec1a407a1b464599121df6c8109ec7247b25c7efc62',310020000,NULL,NULL,'3393abc111ee337132103ca04b4f8745952cd03ddbd6efff58a589e00a48fa21','50cc106fcf8581a7d1ea0ccdc6c5251b6f36b6a64f12581ab77ab339bb112ec4','ee59a8bb5eafdaf12ad7c8e55a19060451a959b03a9fe0b23a5628f680b04b6e');
INSERT INTO blocks VALUES(310021,'68a4f307918e2f39fb393e5ad6a7e2fb2e35ab5043402ce37e984de670579682af5c7ef98637478bc0efeb579dc9aaca7f199116b390c452ceedca420909355d',310021000,NULL,NULL,'d05fe9705db7b30e6ea6b18e9ae92ba794dd72f25b4e33daf4d46b3b609a02de','648f5633ea84b04f3c82873eb245f1632b00e61112a79632e4608be8915d80f9','1dfc96f94d02b90f20c16923937b21a5701ab03699f647bb08e0d1ae0258171b');
INSERT INTO blocks VALUES(310022,'5052fbeb009f77f5629fb701a2e4a379ef6c5591a87ab4d2315c8b79fc8821301b21f146150b2af542eddd82e8e94bc021dd1a9ef8e837891248ab68f4afa7d0',310022000,NULL,NULL,'c2b2b2c3bdd895c74f3ea22db3d9c66301578436b6fa9175ce0b242c4bfaccc5','26bf7bb14922abb270a25ae77abb45a09271deb901c22dc304b019d610f06f3d','5538c6d7b34b2b2e0c08106feeeea791542e1740ab8dd6fdd8be9cf4dfc17d83');
INSERT INTO blocks VALUES(310023,'1aab02bbb1a7450d612af368e571d955812f9a376e9f7f80c8eb8296ec40ebfa964f5c9b5e56d4e0cc2d584b38c3280c2b8b2ac272ac00f4d0bffd5348006b4c',310023000,NULL,NULL,'fad5b61545d8ef317918f07df063554d4f321c0ebf462f759513212960bdf523','cb647a71c09e5bf06576afbd426ddf13e2151e819b07efb2929db444769e4531','9e420592fcb4ba1bb1fc537ef50f118992964090e525d62c6f47abbf65fd6329');
INSERT INTO blocks VALUES(310024,'232fc55d72da13e22bb39e10cf9bdc29a634f1c6d13c598f8a1886fc6adde9f0db1ec92afc8f2e7e099ad1d225277067c9beebb14116168bcc961d43cc0a5b88',310024000,NULL,NULL,'61a71d0ac67eba15c63a531f797e6d68c83613489730bc2b4e4054094f63105a','b3990893e9f8f00cefb139c043815e301e951cb919c59e58644034b33551b480','1aa35c67d550dd3e39d6b1e99cee07decd694edba633db9295c72207d793cdc7');
INSERT INTO blocks VALUES(310025,'39e5551cc35f579114d5a36f841b8aa487e8277ede3b03bfe73f31b16ffc92d8a9535c485518839f3a1f5789222f234e3ac59e67f949ebb2f86044e72296a4fe',310025000,NULL,NULL,'f7d41404c3d1e57bbc390af958d1596212112068e4986954d11ff8abd13bc8e4','540d181af55b17757869eb48ef4050732f4bb8d7bb4667793e05770f33dd7f4a','23ddec44887f0d9d638316bcf4524e4a107f7b8f1c2739ebbd3dc160196d0524');
INSERT INTO blocks VALUES(310026,'dd6f9e911867c1680a777ed34699914cae82576da2f3fe064cec0f77af56f3af2b9309a9e56195f3a63897446e7cc37ebfa8257aa4758e81fcf70d9b12d77bbe',310026000,NULL,NULL,'31530d7febb577d7588e12d10629fd82966df48a93a613a480879531d5dbd374','26a5ce353f383d9bf732d119bf947380fbf7cb7c10d9b65711da6d08f940b692','55fa2a20ec89af2c4cc82aba44c0028fbaf0f166f0cd2dc5c9d02d9e6f4b657f');
INSERT INTO blocks VALUES(310027,'9adde4402993118c8963435b66b5cd74676459f5aec1f4098ded4e99592879c8072b1603611ccb10fa2f1e7e88e087f812553796839664f2a3ed510c4aed9337',310027000,NULL,NULL,'f54085346ae4608c57c55d321a413a00ffeb85499138559d7d05245f57cc0da3','21eb7db4dff69979f960b34b3d8632d417be2d9087399beaf50cf3a945c101e9','19d6fcff51a87f131362e8bd7f8bbd800e985cd54321ba8a233e3341bff64d11');
INSERT INTO blocks VALUES(310028,'158e01a36be6070d70d4f5723fca07d5a49fa057b32c651893df7bf1c5752a41444ddb9499d11fdfdaa7b5a63070f9294a55e1a6a4e751ed154b5330dc10111e',310028000,NULL,NULL,'a841b7f634fc24553d1c8cb2d66fc3103293dcfd297cb5bf241b0c5da84bd376','d8f78dad14405cbd461ccfcacbfdc544ca5e603df3d3021b58d5393560e0d56f','4359591ae7f06509856433c765a1ac49724211e941408c17f3cf28853758a13d');
INSERT INTO blocks VALUES(310029,'fcd8b3ff5ebaa56426855b262003f15cc0602e452db1ec6c9bc475388553d4766503fc6cde9290903fff1dd94652676b826a229031ee7cb56f69a6d633895fac',310029000,NULL,NULL,'69d40c69b4989f7a59da99b56577b0651887d9422757e38d5410379f95fda641','ba57b2e4eb9132feaa3380491358c8706c44204f7f7a4f7f0060a3ff8a640b97','243c7e0f8a44221eeb8a0e448d7ba8bd8372e6c3a76a6e9b36ddada846d9e43e');
INSERT INTO blocks VALUES(310030,'b49587ccb88b99aa75b91045c596f731a16ce7523207ae0cfd2b2400898576943ae0969a28c5500d20d72a33c9a79b5fc3f5840bd550846d272462cd66fcc259',310030000,NULL,NULL,'192fe51d3a7af659670a8899582c29aedf3a5608ca906b274ce986751dad2d7a','29663f45b5eae8b77bb8ec5351e0012efdf03a17fa5d132dd8da0f432acaf9e0','91193c1f216574251bed7b42946b450587bd765a4b5f4138924dde66e3fd9297');
INSERT INTO blocks VALUES(310031,'7a898e085dea5f59d75df0d4b5dd1a8b12c269d1eaef4e8c78938294abef4813e858c6e6f7bba2e5918a853f71decb610ce80fe3da936587396c44086eed86c8',310031000,NULL,NULL,'125784cdeba1e433b3411c368cdf676efb33021f51c26a8b2bd6ec00fe4f767d','fe36b2450774dfc7db346c45833fbd401d8a234ce87544cd9b373cbc4b79b61a','267edd0d998a1957ac14462b1a5af7055297ed1034e995123512c0d17654e6b7');
INSERT INTO blocks VALUES(310032,'d5778cdb9b17207d9caffc0190842356895364e0c5e6247f02c2fb91d4dcde85becbc7958f07b9c99a9833f45599a0c175a8a3b026ec879467142eff3e3c1457',310032000,NULL,NULL,'fa7832080a2b6ae8829794d70603351755fa4816f15a6e92716f83265daa59a4','258bea96c9e1d774eb0fedc7fe99a328b62ee26f557426d036147d1eea033e04','17d2cb78af47a0cb58a0191eacdce2b7c3f27d4ddc342fb11f619ecebc42ae94');
INSERT INTO blocks VALUES(310033,'ecc0f5ba6c110a32e76689e934d9101617db692d61600ebfe32b500fecd78dcf75bd5712de67e59b99d5b16d9eaaa8378a46a73a35fb10f8821bf75a173507b0',310033000,NULL,NULL,'7b86f430bc44ad5d81a43b5a8ea118b458d995e3832d88bb74bc62429194e45c','ce67ed4dddf1582ac85c4825c5f9d059e6c64542e5d0fa6f489858008948a989','b3834107703858d2f18470e6d6f939d756c9e6a6407a40a78cec8636832749a2');
INSERT INTO blocks VALUES(310034,'75ece066b260c4843383467558849588e5ce1f1634da9bea7c9c0e1821150a386baf940a2624b4c0c3fc4bc4996bf97f545fa61a4ec90c57ca5127c1ccdbec84',310034000,NULL,NULL,'1f2c5ac4375f77fb79612d343dd5fc4489cf94ff983fc05ba2009a9e390d6c06','4e7e92c9296993b9469c9388ba23e9a5696070ee7e42b09116e45c6078746d00','0ff41ea30f20b7bf90c66003f29d41bf7bd7c526881db0b645bc1a76911afb63');
INSERT INTO blocks VALUES(310035,'0c8e6a86abf191a1bad2897dcc7aad3e5a5c1439799c55c95f435eb6fb9e50ac892d58d1a9c9424009d0730fd59ecb202de2e1c155d5fc70a8da9868946caa51',310035000,NULL,NULL,'81cdae9b978935ad40a1032e7f22ddd7117b9c7580d6d7e4b7e20d1c875f5e63','98919ef5963b86630a60e75cef8b95f24508d65d29c534811a92ed5016cc14dd','7bf7cdcf88fde6747b8ad3477bb1ea645cfb95ff7d6cfeeab33c87eee54cf744');
INSERT INTO blocks VALUES(310036,'4011ea78ccc04ca2ee8d6bf0b14eef82bfa9456869415a8126f2bee5a1bf961c8436571c00fe20e82c78bee44159e0a3523736123c641b871d271642e8f7ef1b',310036000,NULL,NULL,'ff02952dce15c249501d8485decad0ad9fe02fda766b7b83720806f726d02ee4','ef9adfbd23bebd3c047db6d82d7d0ca0479bd14fcfeb95b9a4ef6963d7294b99','623dd05dbd17d04175b720d8b1d37b9137f1ea83ddfb4c98ba2c91dfa5f4df46');
INSERT INTO blocks VALUES(310037,'7f94ef56feec97124f1e6f04b862fed49ae7c179ee143701cf0eec922b5d39932831274f5528d8d9b0e8e115236cfca7f2d78da21db5596565314e625300ef49',310037000,NULL,NULL,'760e5a00feb6c8c4baf4421ad07be2af962bfcac7705b773484b449356d6c230','51cbb75a27acf3a67b54f6b64a4f4b86d511fe3d6fe29526fe26238e44a3bd4b','a8dfa56a89e1475996abb64ba1b4ccc878c44540b31bbdfd937b61db889d4dce');
INSERT INTO blocks VALUES(310038,'e7c42cc00226117b58f818813df49a64af8ca6352a8490a2894676aba647c1bc8d4ae58bb883b710348233879c841da83eda54d35c5ec279f8a2e1ccba8a4264',310038000,NULL,NULL,'c79381c51fa93cc320d8bf19c943f98232a99446ac098ff66823cf691e0fa01c','cd45648e95377f9c8503ba747cd2a7312ac0c9108316eb5a77a06fb9fd0df474','7f15dd0f7c34494fc4c0a1fab509d3de57867acb7277a4e505cbdd0486457330');
INSERT INTO blocks VALUES(310039,'1efd67747830ff43e4cb5f2837d40789a0a781a79c5de4a7966ef64101c39169c28b7eb78481c4b92d14d997be3bbc7f5c6a6a8af8c729825c0e6a07fc6fbeea',310039000,NULL,NULL,'7382f007315783c9a6ffd29bc0eaa62282c6ec72c5fff09322d6dea6b0ee3a96','ffe0bc6eeace43428a31476e259bf5dfe33c33f70c18001504f158d4be026b5c','cec197d33ac2efeb87943aa58e10272cf7bd662984a64929e18530e4c839f73b');
INSERT INTO blocks VALUES(310040,'0afea7365138d9d478c1a57003d66b1998e462cfe57a9a3a1a9360f5e305e9e639387f6849770c33995e1126cefa8ed66faf8a8af03e5c0853191091978d04b1',310040000,NULL,NULL,'38d3b548be554a0ae92504244a88930b989ea6fefc9bc59c69b68ed560afee9a','3a96f2cea7c289afdd0b6c987bc0081a8726d08eb19bfe3eb9b518442324fe16','f972ad30b7564a70a05264cabff7dbdc6f43fcf97cc2c253031d7df804622135');
INSERT INTO blocks VALUES(310041,'a332959f882f2a2846237e5ce8874beddc8e28c551f7d5be885c79b1d4650c5ff3c9855069302643e9315390e2dc1e7e072e7f90afecd5fe4f3f14b31f38caf3',310041000,NULL,NULL,'0c1c7aa19c015a67da214bf8a6ae3d77979a09de6a63621e320a28ceebdbf333','9f35a2e8a94c8a81ddedfc9b0178d7a07f42fee1221b6eca038edc16b4f32495','d98a7e2b0a03a6fe91fc8a5a51412d00b9130f0b1906238085fa917536998212');
INSERT INTO blocks VALUES(310042,'ee6c4eafabbae31087db301639be2c8d82b31a3004ed19a30a3c6faafdef5c0a363ae91e97c4cc88254bfb0d16213816e610da28233ee3775969dbeba213ea2e',310042000,NULL,NULL,'9d20f77d4afff9179cffe46574f1b2dd23d2987142c943de05e411baee2dbf05','9ba21b4c3e4696a8558752ae8f24a407f19827a2973c34cc38289693ea8fe011','5b9e3fda69ff3d175c5871d2c26513b82479e30c3612bef95b03b4d9a64cf33b');
INSERT INTO blocks VALUES(310043,'1fd0b3a1241e5435a39f816d44b6a009780a37e2a131fa7be8423875f81defa4b571a0c9b89cc335c2698dbd66f55fa333bb80e20fa2ed03d9c3e8c95276d05c',310043000,NULL,NULL,'d818e5a1a5cb6c59771b63997a8737cdb041c3579de1ecd808a269f5d72a3abf','ea9ae316a3d419d8d383d8cd5879757e67825eaba0f0f22455bdee39be6b3986','16d9fdbb509f0abe6ad2824a85e059a01d733ecdbb3d02d3dc5f2172020b348a');
INSERT INTO blocks VALUES(310044,'8074ad14f920e3bcdfe75f606c3a261e14275b3ec48d8678841492f633feb1a25c48c729e10d192e59d52b1ed5bc10185b2d0636835b05b3962e4be08b06f194',310044000,NULL,NULL,'9de166ff18c5eec97b838292ae894ce18e5a890e8a841a294b2d14894c60a0d7','5ed66185648c567cd211fa03b6d887f21854c231743ad20885a83073bf68b1e2','597f45d7ce19813ff9473721f0897baac61e97d11608d1d6e209efddaa67dadd');
INSERT INTO blocks VALUES(310045,'edbfe164803ccbc044c2d602e6ee85546a00d478e5ec3a9475a487cfcd7deef64155b201530367be15262f05ae77a8270ac8dfed18355302a01bc37d0d1d98ea',310045000,NULL,NULL,'bb3c0a260dc082534c95e894751e38e80de117b091bc0e34c66134d374b8db2d','638e948d625f063dfd65ebc57bb7d87ecfb5b99322ee3a1ab4fa0acb704f581f','c2c57a8b58f7b19acec45896093fff26c73994bb7b2a849e42a38d50ff7c8610');
INSERT INTO blocks VALUES(310046,'c1d7a9dc0c93554dacedb41e6f4e7d97b7cf23a9706e6052b7c583233632b4f3cb8596e5b59b6957413ea1da603c2fe125eacf6b2257fb2ae48de3652893eb22',310046000,NULL,NULL,'b4605c50ee3e5e2958c908e099563cf997e20932cc2370109ab50049e43723cf','8e4ef49f870af7dde396a108f4c1d5c4286a302a573c1bb1b6a45c423dc7cd2b','4dbab042d742d2548ce81853ae36a362faa304090b2fd8686793fae0e3090cf5');
INSERT INTO blocks VALUES(310047,'86c6061e10d6032dd6051842afb28b6121ba443e4ace7ebcc213258fbd8aa86136ea03f5c3eafe13e560b9589871011f786bf204cc8ac6a419c263f138ddf72c',310047000,NULL,NULL,'b840a7af6301c798c9a6670308a2684051ff8f3fb2e69bddaafa82cfd3d83186','1e61e70016a9c18765c2332d9b3e7a64e119a7dbf533256fc1b88f36c2404055','c1100a1111baa1ad9f7fb39c146b78b65c427741e91617fc1f1637a16bf62380');
INSERT INTO blocks VALUES(310048,'41f80924d6d10e6ff29f9926dcc1bc644a30d87657975c22165d4c54f8c30938b9bec93e24e7033bff0ad7e6540bec0ae0c3333c7f54499c7809c450cdf91451',310048000,NULL,NULL,'6bd591d3336ea112789ad6675a9b1d8e1578fe42e44ca7f7be5557089d374c3f','ad6559d820513781cb3bd412c74bfd5575595078e42007573a0da9f208bf5aea','70dd3957cb5dc4ea2623bf5e1d474475d525e13159cff152b77bd7cce325e00e');
INSERT INTO blocks VALUES(310049,'51e01a7614ad99af02c4171df920803ed9a88ff9a47254f0d0faf521f5f806b840bf88a311c54a08edbb9fc2f152214bb930f1b8368245c8cd263473b79f808b',310049000,NULL,NULL,'04fe1e6631d503a9ee646584cda33857fac6eeca11fa60d442e09b2ed1380e5c','f14c6718b43729126cd3b7fe5b8b4dd27dcec04f379a30f69500f2f0b2f36715','dd5b8edb0019ca4157a3fea69f3c25d2c69b3eab62aa693e8972598a0022e9da');
INSERT INTO blocks VALUES(310050,'c719b9e1f31934a3bf53ed8f8a4f59ad22f3d0481008f4a7116f31cbfcd2b71ebf296f8a6890f522c72303d63c6f6b76b802f5b93808620f3b6ff515155ea73f',310050000,NULL,NULL,'dc73bfb66386f237f127f607a4522c0a8c650b6d0f76a87e30632938cf905155','2a118b6fc1b1c64b790e81895f58bca39a4ec73825f9c40a6e674b14da49e410','027181bdf4ce697b5ba2ad5fb2da0c7760ccc44805f7313fa32a6bcfc65bba56');
INSERT INTO blocks VALUES(310051,'e88246311bb74b66ad0f97fe2f5734e0c68d0329f05a389c35ef8a8575e8c078b92b401bccdf84f2950fd884cf0c22e2079594050292b01ffc69c8e779150ac6',310051000,NULL,NULL,'e4eea2d144c8f9c6dfe731efee419056de42f53108f83ebee503c9114b8e4192','a910be4cd65598d4b1031a0afb11644daf91338b7d5714ae5f0619ed1c02aa35','a1ae010bdf7178d602fdda887c947933af3e57f2bcb89b9a859f009468a3aee5');
INSERT INTO blocks VALUES(310052,'1c7e09c9d97f26b1be51752c372a88ff5b5da358c76002a42647916b5e27d8e0f75effc92c15f034a75cab7ca8d8a9ec34c64f1fbfe8690c585cafc553add37d',310052000,NULL,NULL,'8d12b561e7cf87b0aabe000a93a57e5f31db75510b1e9feb19b4f557cc0e6604','736cf75895c6b0a0899baca213f46b5f1043ae6e774fd85c4e965363c58ad76d','f1af0e8b196a6f47d1b61cd550615b3d4bce1af8667a7668036851916da25b33');
INSERT INTO blocks VALUES(310053,'60ed831a77cedc82909d871edc4e6525de5669cc238f7b9010336b4f5c80f4eb29fc8f8f05cb9a41db4e1311f437015c8bb02b214b69cf04f909e14868ccb66f',310053000,NULL,NULL,'f47b81b3dfc522d9b601d1776fa2deef8543ca077cb0743556cd970bb119d640','b6176107f5ed5d22352b9fc00d444c4d62c177147018e9a3123a5ddf86113a92','9def6bd964910651ad1148c9e070b677df998e5fe2d89e0f7526f4b306e88036');
INSERT INTO blocks VALUES(310054,'0871d6f27552c73bda0f3a9f2557d87b89a0589ed5da70ed84a42dd89456a877d24e0e439953fff2123f110100aaf350755afe5ba6ccbe4f01b1965528e1b39f',310054000,NULL,NULL,'df191ed877eb1856d6780a717c04d6925246cdee7dd6df74216ea983560d5a2b','22ed22ae4cabc3bf271243f79c3a4d2c42e5fe86978a9f860659b2037e69ea0b','f182aa045d7baaf72eb3a28f9488bc3d0adfcccb270f5a825e7ff72cb6895c34');
INSERT INTO blocks VALUES(310055,'3edee52236cc6d3fcf0c9e108ca28515924cbfa3b9ab8d6f2ce59b1f234558ba3d50c88381fc53f0d607e67dfa8cf497f45f32def36c5a444233a0edaa649987',310055000,NULL,NULL,'4b0ab72111202b1f9a5add4bf9a812df203cb6761a8d16b5f7a8b9ed6f2b2476','fd10402625c50698b9db78754941b5f3961f19557c5cbdae9321e73a59da85af','f36a4fb85c64a4959a940ba247d5c945e33f41009ca6bbd776fe6c847b65f5f6');
INSERT INTO blocks VALUES(310056,'bd46235733652f0ae9e77cd97e22a371fb6778c023c98e49684616eee72b64696b1376ebfcc8e897ceb18d8415b08d5d8b27bb788bb1f6de3b8baf985e2f5c0b',310056000,NULL,NULL,'8e76b5be6a94e1b50ba16fe265965d4cba01b792216485c54360052e78788f20','9137c235b9218da6194b0224675ac200ce37e57a280682875b64b614d998f1cd','735e35e38481317f7c6b8b948297ad669c422747f40e865601d38da6ed971d89');
INSERT INTO blocks VALUES(310057,'91e818ef3f1425e86d13808bcb5cb4125205d61f8d063f21cd37a445269ad14f96bdc18283a12ddde8d6775bc55b2ff91c7910fd7d512ee242dde68d8d4f1520',310057000,NULL,NULL,'e14dde2bfbe4f9076b7ba548aad37269752858361af094b4be8b956c0a28b9c5','dae4bad204dcb46ea70311d316ad02fa49d9643608dd443861402705ffe7f7db','e7c7f03c38f40e3556a5baa91db4a738cdec7e564de52b39d82990b2d5fb98bb');
INSERT INTO blocks VALUES(310058,'ab68270f350c7c11d62cfe38e0b20c6763c770f9d9dbbfaa16cff8ab3d746a9b71047d4fde90c7705688b7f36ed3479a9718fb1a455cdedb5bf97309e3344e3a',310058000,NULL,NULL,'b986e5f6486ceac7f1af41b1da968e453cc19376d588d8e884439b51313d6e30','8dcaccbcaef1b98d192f0b8d62f5b371043d676401c2120be4eda65786fc68c7','ea8bae443c8df855e40e8bcff3dcfe618b1d46a1ec783b106c31e6424b10bfac');
INSERT INTO blocks VALUES(310059,'d08b01ec4f2055eed65363e748f638470b4e989c815ba93395c139de56eb925e577bf05c46a1cf2051a238a2ce1c62bb137583d12d9b5a30e3d1fe2118e50009',310059000,NULL,NULL,'da978ee5b06812ee42cda43e1d9943c4e34e9e940cb0461f0ed463b9299402d8','96de4dc34f8de9a895d1a45bfb1d72e887ac3c168f2759e9a27a892eb398d63b','81c4338c8e7197c802f1ad8716aedc5a359a50460d08ad29991f4be832ea68c3');
INSERT INTO blocks VALUES(310060,'76cc352a0973bd5cee8255c511eff6cc34a554d636ef61ab3ef6621dd0eaab17b3032e5ade33c8712b1d45960ba779974e79998b0b7738b6815ac93d2eb8181d',310060000,NULL,NULL,'09ccea87988cc385b9d2580613581b90157f1366d27cd3dc1a4385e104430d15','0595e85b26408a75ce220d7afb0111085b2e90aff588a1c828ff389b4c256b4c','589d6d7e670f0c96db995c4acf20385ed3f14e078bc7ac7e8a36663be49602b9');
INSERT INTO blocks VALUES(310061,'80a038ba3f297cfc699d7be560b9be58d8a88f4b127468e22d5d633b6b3e359430d738c20f7c5182a435bcc1a49a056e84ce705ccc504405bb70700030f86260',310061000,NULL,NULL,'4caebeb5ab6468e116cc0cf137977649a15dd30d9b214a5081057a551174ec48','5e3a2cfbf7e322f28a3254c2af408baae0578e333ed178a80cf416580d5425c7','ce4a967dfa5f4db7c546fe6b75f8fc29dc823944788587ebb63b79bd03fcd086');
INSERT INTO blocks VALUES(310062,'9fb37033c32405d7e00ff9b69272079af198e9960fbddb8dbba542b7b6911ceb833868bad3759566a7a2736b9d719ca82690627d83491ed40467e6b18830a711',310062000,NULL,NULL,'51cb3f1005127e3240721c47805d67a123afdc40084692a9cc2b3215cec99dc3','a8a4c0baa06a4304469c6b9fdeb4ba167e1b795226bf03b655ff759f0b7be9e5','0184f70bf24b7b95fe1eadab1b35cfd5971bafe03044204dd2726339d413ac34');
INSERT INTO blocks VALUES(310063,'807f83f652635dd041b0e46222d9a136099f478a5159c501735eb3a64b32d664250ec44f4668df72b1f2b8ce34ff2e1c260b6fcd87febebcc44e99faa098cd7c',310063000,NULL,NULL,'e12864a0f955320278c215897cf4f65e5c378e534294b0bb90ebd7e4b5efd4f7','d777885ff67ef99793a8cd4f4d159580efa194a505eeed1f46a7b003d74d3818','c8f710d147f338a3288556f9eebdd109a796daa60ef1ec60e53bfaa7ccbc79e0');
INSERT INTO blocks VALUES(310064,'cdfd286ed7373f1a2b525d37a903df4ac53788422414fa5fa5b408dc04d11991b3bb3c7dc7be3bc98d65c31265c01abd59f6c9f4cf6cb25c8da4a28fcc74f576',310064000,NULL,NULL,'ee27c3b46aa890d18be950006879874a094ecddd086db195e032fb4fe12559f5','e6a5b1e0c2bdf548abd1826994529d5ec68310fd8a74e05ec5dde281de52ff9c','22cad399931fbb4c620c887b3dd0f0e5284e1ab45f74900b7c4706868ca2c936');
INSERT INTO blocks VALUES(310065,'e971d529b30e42e87f399558d975181220fadc9b160b37dc5fe82752be193de9c7022dc509061f99158c7e585799f336ea3dd8fe63d55b57772af676e91108c8',310065000,NULL,NULL,'d40dbc4b5faaf8918f9cae54e5a247e3904dc65994ce0f04f417c1a595404464','7ce3ffe967f502ba033d3d51165e754b77e6c4a28cc4e569f81cf0a817c1536d','e930bfd4b6eac1822485cfa3953c550525ad1d1a6ba5177677e481fcf24edfe6');
INSERT INTO blocks VALUES(310066,'0758bfcf08b5a8eb40e4937fd84fc69458338483a8471865b38fa252d8644be6c22962996b80aa3fb37db97f2e2a213049c9cb356d8564d26fb1ad5de14ccef8',310066000,NULL,NULL,'19f2b00477a6fae0e10f4693d949cb409b1ed74ad20dbd9aa4a7f1f17cb813ac','2da61818fd2c6fc3a15d998ba79482cb48c49f5a9f195ae4ddba291cac9b416d','e6de9d8f4d9c0a5ec3a51ab0f886f4fd35fd9cd8d1bb6afb2b615b58996bb26a');
INSERT INTO blocks VALUES(310067,'359caeb095b44b88cb86676c4a94ac830211c31e25c326c9c75e3ac60c5f28c1ee7387fc46ac6ba2946a6ce41a067637047ac4effb32777dd9f694ef1aa88ef2',310067000,NULL,NULL,'d72891c22fcea6c51496fc1777fa736ef5aba378320a1f718d597f8f9fea3c7d','72cb3676cfd73767e4499bb405f6e07ec421a39239754d75afd8c08cdb49ae45','2e750809d79b40966d2533d7d726cff2b802cc2678244d3e235508750ca838da');
INSERT INTO blocks VALUES(310068,'2f1264342a2fd66c9493f2fa062cb8477ef86f72c532149ffd45353fca250a9985c027d7ccee2e646c96533196f6dd60ef9bcb12b3f156dbe71edbd088418487',310068000,NULL,NULL,'5793e10b8329d3ac71aed6347dfcf61fc7b74ca162ad99918f5c20065f8d0746','07a593978e6f669c9b378ffd115c951da48fad08b55a7d5adb7ae96bef306061','1ed832c547e29ffa2cb45660129f32f56613d2fcc0d36dbaf3872ab47e77f582');
INSERT INTO blocks VALUES(310069,'b08114be39f1ba70cbf72cf9ac4b008d8582dce4d4d7c789e7da57eb264fab24fdeceae387dbb23d5dc0c73f8faa013c5a499ee8d2761b959128c9694802230e',310069000,NULL,NULL,'61040e7c1a58f41d708785347f4985c1fb522b6f947d3e14dacd91157e153ab7','4822a18f5a177a8a22f1b234c181389614489a33ebf3944b1107acdce0528bb3','6de08d8b4df6538298c2599a166548d12175ffa9a7db682df4111e03107bfd22');
INSERT INTO blocks VALUES(310070,'5f1384e1063f3c21946d063c75dcb43a6ddc4642eac6f79eee0a80ea99320bf8b26ecf86b1e79889e1c733cd278219e76315130a30b440d84cd288be58bf3853',310070000,NULL,NULL,'ce115625fbda90a0f261b2c524108a7393078cb4c3f861d6d7846501c7960008','54364047ce52153883e68adef9b681266dd725f8e45af89b1dcff3c9edd525e3','5f53766a278e20f6eb70bf3b8786d4b3191a0f76358a97ad89a2dc901cb3ac16');
INSERT INTO blocks VALUES(310071,'c80b492818257e806e4fbe093c89c7965275aa8e36d1bb888d1f79a059e95dadc40273e59de99eb8d80c5e8e1445509d8baee4c733d2c470598620f3048cfafd',310071000,NULL,NULL,'3c2d4d81e90a42a0c18e9c02b8a59f99e13f2a084ee66b4b1bd410077adc383d','08991b69e486f1032749e530eee24ffd2d849b1f46aa6ef2f2d5a5202fe06e97','be328287331db13c6a631277a635da9c87768946ac8380ae14fc2fbd5aec6303');
INSERT INTO blocks VALUES(310072,'64a311227b25fe4606729312295546a9ade70637e896cdd8321257c0b173e38701be1e5bfefbdd2cf1eb908d5076f2b464c8664281cca6a9d9bfd715ca085a93',310072000,NULL,NULL,'8a28e33306582346f1d965a0393621b4aa307f6614c84369064465f95a6c727e','e0cd2ae87966825b5f8ebd21c7629fec5ea6ae0f0964ed137f0776d2a1130696','85c6c68b477ddb33e954a67c3116e75da8012443888ca1638f471481de4c899f');
INSERT INTO blocks VALUES(310073,'acc6dfdc3cf0651092a08818eed4eeaf9abfd322f1e46bec97e6a8ce96317612d4f3873e194310f1335da4ac225ed92b1a59237cde4fe1d2049be6a2b66c1f1d',310073000,NULL,NULL,'e6c5b393a21df54479c4cd8e991b37d877794166c19b9f61ad7e47eb34f63bdc','4b2ece53331a483fef54d87f0da7e6f712148c0f35388439b73f2aecedc57a12','994a079c0bb105d73fc0464453adef90844be7be0426ebc47bbad7bef29fed83');
INSERT INTO blocks VALUES(310074,'a00f647aa4b5d9142500fdc7da95b47c60c0affa3275cab56a875b1e082fa8037b3c32e6a002f92010c2d8bc1abaad10c2373fbd246b59e69af1e97df5c3a3f2',310074000,NULL,NULL,'b2db452daf280f1cc5f02668d0cbd33732a2fe9f04307d9c072eba97c95acf5c','28a44c85c432e94d1e15ad9675d2927a983bcde0ad0cbfe47a7d87da00df9f66','252b3e5ce81eddfd53c6086a2aaf6630aa2fe15f3c55b364c4b8f586f4228eb0');
INSERT INTO blocks VALUES(310075,'53035b827f91f83e75adef2f62607377fcffcd185902cb742a72d751e4d57e0432562fe92b0cc6f7221ecbe53ced6aea685ba2383dd9e2a78fce462778b75010',310075000,NULL,NULL,'09998443cf1cd79e193a7b09681ae07ea9a835458151a7f8c7d80a00c5d8e99a','398cf0362d19717ca11dd2a5f022a1ec94122f7bcfba0c4f25a793826b1a0892','6a6f7117e0c8814d4b6a7245b8e9719dbf727738c6efc5cd81aa7071dd50de53');
INSERT INTO blocks VALUES(310076,'98867155f362ec51c5d01c1ee81fec7c0fd5bf08892df7e78140ca21c443c084876793d528480ef54ea1e185fe435869dd7dd284119b92f4a3f63d05173a6580',310076000,NULL,NULL,'a0be1e88f10b5214f7c12dd32d0742537072d5eb3e54f9abf57a8577f7756d7e','5a17953bd90e4ad629cc7c24098e50a5ea86e84a5796b5db5959c807e0f9eba6','f3bcb0d573f3e7505220ce606a9c6896ee1a32e71fcc6d138b4c86c7e5095a8f');
INSERT INTO blocks VALUES(310077,'2f9ac5c43c034f11cf28d62fb787f8c109662e4187b8af0d7dbd81b524f474ba9f4ab6bb6a36ce44003839ba82f7018065499543c9e3b4b1be0e96b9d56cd9d7',310077000,NULL,NULL,'d41e39038756ee538d9438228512e31b4a524bbd05bc9b9034d603fd20e00f05','0491cd1f3f3c8a4b73d26a83aa18067ec31f868df96ed4667f8d4824a768a4d3','81928269ae8abf6fec03eb3775ba5b2292de5f14a0b75f780e705c973b88871f');
INSERT INTO blocks VALUES(310078,'5e535d532426974fe1c45ebc463ec7a93fc3625a5da33119975481c4c98ec8ad81ab13fcb7e8943ae4fb26b41aeaa7ca0f50fa22d16c7d18e5deb3820e96df1e',310078000,NULL,NULL,'996092432a2d94df1db34533aa7033e672fac73de5193a696c05ae7c30d75247','ebe0a3e1269a54e03ae9b7b8ad5f00a1e88b4bdbf2c7485ac1188eac31c0a4b1','ea1514429815a58d3b87a8358d2f7171db18db6a308b31a22c5dcfbcc36fff92');
INSERT INTO blocks VALUES(310079,'e41a51db594c3e7919b4aac63e6100a092461b81518721da953a476986f5bf8e29085cfe6a08ec452fa547b704c4c4eca957ae193c27281dfa7f113a0f6df941',310079000,NULL,NULL,'e3f536e930e39b421e3a0566eba6b8f5f781ad1ff48530a5671752fd3eaf35ac','8dca0f21abeff518ea5c6a0fff3f3c89e0d6b263a72adfd36cbf911a306080f1','70b5ccd472fe0afab81fd3cfd7a51a2f384e7c8bb03bf0b7e8b598c999893e42');
INSERT INTO blocks VALUES(310080,'fa67febda99884d857fb9bba17476225a600f76535a9431d21c261662434b85b9b4d4ce3cb591d043f80ebe0adaf9263e0a368d949d291e14778b46d07dabe91',310080000,NULL,NULL,'57122dc41d7de2bdc65002905617c357496432fa4d80af48f4ca69ba1332e634','0ebd79095ee1e751b4b694c04d31fe2246db4558ee9763504c9802c2a342e817','f8c3dcf3dc7daad074cc82a00eff3086bb6ef8cbe063245446d096b20dfce677');
INSERT INTO blocks VALUES(310081,'98a5ce8fe941cef091735620c3119d97a382b9c80cc1764d1d30c94300037d0e519063378746b7edbfc60aa506fc04ebd539ada353534b7a5b3d621dec791da9',310081000,NULL,NULL,'3a0fc7b2f0396d257a0a5c5a313910cb4073e4c79ef8cf0d3cd12f494e563105','2eec4afed90d334123b8299d50c192db4b6b7ea0f4868734ea435e5f2cd7c901','4cc5061efa8f9165f844f5ce14b6dd0602f15027dfd64dff653f3785659e434e');
INSERT INTO blocks VALUES(310082,'7702f9604bf3efed6578761f4c52de99779c7c42d7543774d425a4c3537befbd2e7181355f8a1130d3d8ad9ff3bbeaaca4e26cfaefff15e575ac4b2eb19b7051',310082000,NULL,NULL,'e876c406f682ed6f0dbd6e4c97bac13409cd400b59e894eebeb3252be306494a','91c5071bbab5368e2338657982adb58c861546c0c0ba9fe9abd6b8b781e415ec','11d09e0d0361dedfb42e1c7a15bdb6a190967a5d59e833605bd6c4a145f6fceb');
INSERT INTO blocks VALUES(310083,'f190eca1a75147eeec93cf96f106e346b908fc47e6a363093d5b229901bd58fb34fc8db82a8feb2d3dcbeac0c901ce98378f7e1dec0ff7aea7235c6d822a62b0',310083000,NULL,NULL,'533fc3eea80caa46cf8fd62745c5d21d09f32b18eaca70283a4bd72924c2100a','bf0da4a320545ab08a86a86a81d5702f7d493e6c3173344dc19941c8a527f4c6','735ab4d3b9692aab21e75948c17a197d1395bb1ec579e450b7be53b389b3e7a1');
INSERT INTO blocks VALUES(310084,'d15e3c53c8bad6d8a4dcbb870b622505e4dabe8b3d3b7ffac8aa4976cdcefc91fc13c1c1a1700d7417e829310f9826fbc82307636fc3f95bcce561a8dd8f7ea0',310084000,NULL,NULL,'e3fd22f2e1470246ca99c569d187934f4b7bbb1eedb9626696cbaf9e2b46253b','ebd03846d979ea8af53d9853c2b9ed94bc4a89c1d554cd5d5a2557bec8a127c4','a44994aad22375af3e1c2742179fb71538aa8401e478ada17328580f9675612e');
INSERT INTO blocks VALUES(310085,'464aeb24455523d820981afe0f284487ec0a36b1388182f88388370811c394bc18686bfe2b8429f7d37569070f13e95952e877b7a84000c6c0e769e5e76cf437',310085000,NULL,NULL,'bf04750fe13f663adb12afd3a166636a4511bf94684a77217de1bd7ef9077d94','00e86699ae5a8450e0ebec24deb4932b27686e436c2cae3eca6428a7229edda4','99b298ffc6ac4a1d80fb65e89584a98987abf2b108051e48a233300a0ef90b32');
INSERT INTO blocks VALUES(310086,'0c1d3e5b62d04ec82124010d58d052a0a2f9dfb71684580d0c5a8d37e286768f5eb4ce31dd4a677bbbf199d47ee843ec864deae51f4b2ca29d765015748b5742',310086000,NULL,NULL,'a0e8403085ba63ba72432f27ce8125921ef24742f988ab7f85dd8e4309f27a2c','8db72da41c05d03d36307441dc8751f1907da2a60e209cb7ff47e99d7b22e88e','2e57b42191dda49cebd61f4146e0a5d47dafc75da5441e6db9fa43ca024dcefd');
INSERT INTO blocks VALUES(310087,'799dd8fedf7036eca0b8298ac48c295690d12f9c71aa98727c927a6cb0224c62433ab878dff483f6d2754bde36f06fce594bdb06559c1d1a0a51848bfb395419',310087000,NULL,NULL,'0861b02e980ad5958bd23ac02603b132efd72ee2a70dbb0415fa5d39cc524681','9c9e3ae63fbf9180a1d17a19f47f77817eacc0aec0c031bb13046accdde03799','d5eda98454ed499fb8a7f49c09d28f60ae20c2868f519af70303206e191f44f1');
INSERT INTO blocks VALUES(310088,'8e1e809b86f3fbde2cabe6510052084ec68d7857c34f8dd334c99e8aeecf32ac1669f2789aa41acf3f33119c5d0aeafed03d8288765c178174a8db27887c22aa',310088000,NULL,NULL,'d52cdaa449f63f6d3abc79080378855206f91a5db865dfaf37a5a2529ea6eb9a','0ea167598525f3a88c6ab4c8f5138a41ddd7fc8e13338fa24706b9a30337f223','255847fef16d7e0a5cb78205cbcdaa9734ef64485b395f3a661230d0d23436fe');
INSERT INTO blocks VALUES(310089,'9803c2ce201e643165ba86a8a739ec73a05f29d23237d8d2de56f46f417be665785871d0d36cd3146f999d0252635b9ae8a3dd86f597b1cb59cf6879e116b5be',310089000,NULL,NULL,'d15a7a60b8bf8618667863b3e31eaf6202664e5aebc16d1f7a337b857ac31f90','8257d7e04e5813b7e184ec5b9bdbaad39c779cadbaa31907a8b52ad8371b5d09','5bdf07ac766cc4bdbca99d449e6758d77a9e4c3b680ea0460967298c49091836');
INSERT INTO blocks VALUES(310090,'1ea5f2b04b763909ad541951a0d21078be9d08e6bd7a23499ea69fa4ee8a67f02791404da26f6b64ed5bfc0bed66c28e4e98b703d7466f96311c5c838ab6d9c2',310090000,NULL,NULL,'68475dcfe8252c18501fd1fef2afa2a91d20b92cacbabb542c12f43403e66ea3','dacabdd06a6ad7c50a6789bde4cbfbf5cf3d85a1e3b5d3621e0e93cf743ccdf7','265c44182c4b94a6a94f00defb701b72151830dcdc39c105039f1b86735559cf');
INSERT INTO blocks VALUES(310091,'09f4ee2e18880732c0ac4f58e012ff8fe9223899aeae5e051c9796439d98570637670e0cf50c0727e3017287f268466368c550fdbd3bd210387615af76c0a515',310091000,NULL,NULL,'5d584f255e5bbebc32c78a30fa816e1203fe7d3454611bef9222cdfc91dfcb63','1b382e2152f884268b32811171913ac28e7a1d40b6eeb6423b6a807ff417052b','be4ed062b28aa5e249dac7823e60344b07fbe187121386d061dc244a8406343c');
INSERT INTO blocks VALUES(310092,'ae270aca6bf2998680fd12abfdbd158ee5bfb8131fddbe54f5466c6f7a7ff114517a253f8756e13c2bde73e9b851ad2b24ce06bac2086ce3e240331bae518a2c',310092000,NULL,NULL,'ef992ad033b047b7f6ab038604736f444da55be187834f8152b173cf535c68eb','d3a42c8de911e63c540c541aca141f057a06852f519e89491e25cda63480c442','3b63f70bc2d208d99717e630c93b508806b85d84c0b389c29226503e443d40ce');
INSERT INTO blocks VALUES(310093,'2c950816e8a2e9c29fac064891a58465f30a62197864d549f856157c223a1f78f1e39f753e792f64b48c500d77e47602093941df590450d21da55758f81a659d',310093000,NULL,NULL,'9cdee996d0e67ac3f9f283151b428ac5f223b72590965f41f93adcece6b88f2a','5e36c495f7310dc1815a73ab767f53eb04fe517eecc36d8ac9eedc2c1dcf117e','b9be6b071b8a2626675a0b18e8d0b1024af4bf3ec19706c1176c17f87e3e9445');
INSERT INTO blocks VALUES(310094,'c7eda9512bcac5c3b73e17923afdce541011780a51f2f59338bd91f539b223655a64a2680972f32e340a268ee6dca4caf0ea6ed8ad02a3840e5ca7075c6cc69b',310094000,NULL,NULL,'fa25dc3f15fb28718d788f85373555966251f54bc6ed1f4dd2244b438d27b281','296aeb138c815e74a0f41e87ff2f463ac32dc01dd3d24da6fbcdf47542319e6b','adefbc319f56c50c4afcb1fbe42d5dd3bef88531c07aa522509c090504498c79');
INSERT INTO blocks VALUES(310095,'4ff3aa594932ca9e13370bd1a9fcaf0d07dcd6c28949afda5fff201a876e77331c483f93c8fc7295d3c8eb0d4ed3d4f53d062e17e87789392db93bec453cf1d2',310095000,NULL,NULL,'1ba8cd971f9a169d43b6de1a136cb8e6153649fde1f7a8e7fb2f7de926fdf8b2','17b1f9d5c3426a4edb4734657cba1713f9a56991bd1b78669142ace96327d357','373887ae39db4493a059faf7901de9504168045b7f83c9911a5446bcd0e35b3c');
INSERT INTO blocks VALUES(310096,'7f6ebf5b7e09d78febea9dce370ca98e1a00cd911b6ee8b4c1f46c3ee5e54754040ae2e5443d5e53ff2af3b615b08063111b4876e034ef31c9ec0f5e75695772',310096000,NULL,NULL,'42c36df2c53d762b9b132e622f52b2fca99bc0370978463acd22cdf6469587a8','6d05d09010684842a6048d4a70e1b08e22515caf58bb41cdf4be8b0643e6a788','3a3601a55329b1175dc55d3c85574553dd2a3349602bccc97d8b36b0ac1e661e');
INSERT INTO blocks VALUES(310097,'e44698e52e70ebb58d3d004f8eb4943aada1835e5ae673ae54f5a62231df0f0fc3a68ece57823e624b4f365ce199d50e35ec15619e508f8cbf71134d82facefb',310097000,NULL,NULL,'d96af5cf3f431535689653555c29f268c931f9fb271447aed050303d364f92a8','e713310f3b49ad5f4a7a33edeede88ebff816f891ad3b75a971d402c470adf92','1734705bf30b95def63d9eb7ba430ce2f3a09b64414db512cd88dd06c1c078fa');
INSERT INTO blocks VALUES(310098,'031441b70e39a3d6dcf5a532eddb405d5abd8d723029ca8be3cfe400f0e4fb012a63d859e610eb48c7e41c4e80768e877321e92f8ff406e700d8c161e8a3f4d2',310098000,NULL,NULL,'153c9ce12e8d9f9d10c4005fc9af158613480d38b2c6551fc49bc57380c229de','1300dfb9b2c5511a312714c5679e956df96f6556b217245a5af1696300b1183c','22e30bdadf26a27de152119217e8e34efb9551f8db1fb77b02d62cb0c741c351');
INSERT INTO blocks VALUES(310099,'2456675ed07aaa79602718040e1f29e546938bec8a15b26492dbfd58d5388ea21ff3440ff29138f4e2cfb47662ea3e4e50476f7280c0e58b51b53bc08c014fc2',310099000,NULL,NULL,'49f33b269d717b56a399843cf4627449010133b47079134b9e299ac5386468ee','f8c5bf3169d6c75d82c17e0567207db18fa4326b173fa441f574cdd4910e41ab','c5ea44442beb863638bc18a58c4010a6d58a944ba347d989b24277a11bb79617');
INSERT INTO blocks VALUES(310100,'b9b9a79de83063df4410925030cc3710aad6999f8ca9955305b477dda2e3777293c7ddd7c4eb6e9c3f2aec2e23e2415d0037dfcaf61a52b351ca564f2cf1556d',310100000,NULL,NULL,'c9e72f7db2950f0b0e6e8fa3bc47d37a0d643da6ec61b236f7224b63ac60467e','42c7cdc636cbd0905f3bc4479d1a9ef6e0a5905732ce78e6f3cd63ddb2c5f971','7f3efc399d7278404aaa1293c002c06eb242145e5c2615a96d3014e666c7e7f6');
INSERT INTO blocks VALUES(310101,'e8a8ebd85a460cf5987683360a1c77e6728b4e59027220f8eceda05c720bc38c91f6193bc43739da026cd28f340e1a10b9900bfa3eed11f88339147c61b65504',310101000,NULL,NULL,'a4387c8c785a8407f2dda176a7e182617904e7ce00c695ea8aa2f9d0429d9e74','a30a1c534bb5a7fafd3f28af05d1655e9d2fa4a966e420716ca16f05cef355e2','840c0c140e7dc809919a4b6bd3b993bf5cd3973ad1f8894b8f92d41199ae6879');
INSERT INTO blocks VALUES(310102,'767209a2b49c4e2aef6ef3fae88ff8bb450266a5dc303bbaf1c8bfb6b86cf835053b6a4906ae343265125f8d3b773c5bd4111451410b18954ad76c8a9aff2046',310102000,NULL,NULL,'fc81f97474f7b35ef92ba93de82d38650a28afd140d3320e6f6b62337cfd1e94','7166828ceb34a1c252e97efb04195e3e7713ae81eda55adf1a2b4b694ab05aed','a8fff4b3df42c88663463a3c9ef10879dfe5ed2762fafb257326f5ea5402d2b9');
INSERT INTO blocks VALUES(310103,'e9041ceed8f1db239510cc8d28e5abc3f2c781097b184faae934b577b78c54435a4205ee895ccabd5c5e06ff3b19c17a0a6f5f124a95d34b3d06d1444afb996a',310103000,NULL,NULL,'50285876cb1c048acee297639814d5d3f2f2db06e2f34a25d7d6606f308132ac','5d617a3801edadecf207884670d507ff8a61358e206342a38aa98750e24e1036','5f62f4324dfe10ce37f981235d0ea19b4ce8c041d5588419b2043469132460a7');
INSERT INTO blocks VALUES(310104,'04faacf3df57c1af43f1211679d90f0cb6a3de4620323226a87e134392d4b8f7fc5d15f4342bee5bff0f206a64183c706d751bdace2b68c0107e237d77bb0ebb',310104000,NULL,NULL,'2f4177b798bd91cc47b0d102d3edbbdefc06e6f100c7328b93825f6395491936','5e5c8a0b177d207d56af3196749d289d3469d4194c8278e96d4244677322b1fd','126ad9aa03d4a2689c01e8c0cbd13164ad5c7f35a300448c38b325bdbd62dd36');
INSERT INTO blocks VALUES(310105,'673579ef7bc7828b4427a7144355901327f4cd6e14a8ee356caa1a556eb15f88d6f8f599556590f9f00979dc4d4cde4ff5ea7e2ae683e2a14706fc03aed8ecbc',310105000,NULL,NULL,'60b52c5be60b3a8e957505c2f8ab127d03ad0acdd7843e057f6a1d6e9e199c9b','99de630712bad8bd066573630142d58fc323a8d41789caceff3bbe63d4f597fd','fd80135cdc1ba583ff051ef3f39d231e12a0b6cf832d05948056f855b18f5cdb');
INSERT INTO blocks VALUES(310106,'8dc95e1d0fbe11694812b71d390ec5ca5058fb64d34e2805273d5d71286865371dd1ec0584e6ba1fc0b9b09f1d43f9529ac67f134fe30685f1962abeb88fcfa1',310106000,NULL,NULL,'68bcaecabf43259d9642d0b7fdd975ae483994ddefe0ee2a9727342e7bfa57dd','8b2f4d6f303e70ce8bb79f0ba8e5aa74a48590af12b5afa7135f3aacd127edec','fe99ae42f3b414a8547ad4cd9881b134ab0107576f480a9d83e7d7a15b082423');
INSERT INTO blocks VALUES(310107,'535b56c056428600fa79bd68d4476504453f02fda130fe45b3f7994298801cf0791cb1a858c3d3b90780941a64e5e788e828032268e3e94134a7fc05fc5b7c8a',310107000,NULL,NULL,'1595c8a860df11015a9f8a0e86a801aeb76365349d560a4d69c2c0087c3de8eb','92fb68cfe3320f5fc603fd907390c5e0071bb4f16dbed59413116caaba2eba3d','e3608b9de4f469197d683dd40d5214f1cfb30898c55f59845689366eb7ac07a9');
INSERT INTO blocks VALUES(310108,'ede71647f0714fceb0edf6ccf71302ab49c3f2ef88e6729bf71a158515213aa97a5226eda7cc90763b5e8a876107f5e2db0ba2897d384acf830068ac0d7db43d',310108000,NULL,NULL,'f2edc40693e64face5b4a8f2c03250d3ada7e83dfef4547a5e8e6686fa9c9322','297ea5b8af42d9fee9d2a225b29d95c5f86b23c417be7e3d8266957e0f867e0e','3ed7d71fa9ed3c6febc57ce77b4215a9a6ded79547d6679c1811b46da1498d61');
INSERT INTO blocks VALUES(310109,'fc403195b5fbfe288fa26dcb56442157451584ea556d0897f9d29abf3f94542d6f6604e48e2f647c56c5fec222b037e0f4589851935c106ae167982189f37459',310109000,NULL,NULL,'b7e60fb74dd33a1c6a8fc37de0086d0b8e13aa584ab7c08fd07a57d71a63d948','86459ddf886458392a406b5e2f3bd448791734c6faccc5a3993ac6cec48d0191','351b95252f0c653bccf431af37b86fed4bbd9f9e844a88f9d23d179d6a8e13b7');
INSERT INTO blocks VALUES(310110,'707c243a03e691b170b6838183e2a5a710b77c30db606babf8e347454e99452eb50e0798723a5ae3ae1c87e7e417cd1b8a5d6478905add9dfd1e2358f33160ae',310110000,NULL,NULL,'c8a0e7ed4db94945d656d37a9ce31e46eac770b593715457a521ce46042908b7','21a83804f3733b0ecca81cf4680f2cf393acdac69f4cac6e3a8fa64c83b33030','e4837d1509f334f8f8a3305e32532e2fbe0e803fcb0636775714c4637957c921');
INSERT INTO blocks VALUES(310111,'b423715bbc02048a92a2621b4edcabc2570780739d4f7e9ec1f584cae4ba76b945e4cf094542dae1699dd411a4e1d5eacee9506eb91e04fdaa98404c8e4a2b8d',310111000,NULL,NULL,'da87e7604524fa8d0308596517070f25ecabd279e47340f642112c11b9cc7f58','e19137287c625c605cbcb8952bf91821464f1dbc037ebffdcc21faa47ca7e07c','a3b3c46876ba9c1473f21ee4fa15d76e54644c2f32fc7bd157266a3d02be2fd8');
INSERT INTO blocks VALUES(310112,'6760a191b0e17b1bd256baec1b67d9f140c7c27a69bfd942fc2afab8f48ec22b4df69f90a71d10d1788b0ccc4899ad9a63e469f8f53f59cb62cb6a16139acdc3',310112000,NULL,NULL,'8719b5cc3e2442e7bede6852618e191f26fa476327aa248fef9bcb27a44a3874','936a6717ee5b757db21c163b058dc76731cd2acd723bb39d998f7d5a856e3e1d','6c293c327dbe9244b04d39adf93312daff7f074f6f9e8adf84a9468318e7759c');
INSERT INTO blocks VALUES(310113,'cf77b91f1337ff1dc93d7aaf73d7ef331dc2535be1de5658976dde55c9a94ab0feac585aef5e3ac026d2e6c5549f559506c2fcb2ae21ff5449606680288aa497',310113000,NULL,NULL,'3409b2de0bfd4fc52ad931d57ccba44889309bdfde1833d38fe9915ef552013d','130393705aebb18a192ddff70100a66c72b21e5fa32cfba6433148d430ede392','4c86ba3ab8e7ca407e5b18040bb66ad44d9a8558f2693bb40d28724db5c16ff3');
INSERT INTO blocks VALUES(310114,'8c68200b083c884df430e76d42c61d47dac48bca18654ccd47b038a8d7d9e33b2f441b1999ac8d1ac682f20b87fa9b8755baf5a4db166fdced6a3fce0fe789b9',310114000,NULL,NULL,'0f4efd49964de17725552654b6063928df579ec1e1986c9124a54e8d4e0c98be','144dd62b45cc391dd2208ca6a703f627992621a6f19801cf5530ece471f576cc','3ee42b8f448479a861ee6bbaa0b10dec199f9f307a2df243f12785db45079dbc');
INSERT INTO blocks VALUES(310115,'2370375d3fec89376c52e133138e9841c075ae5eaf3fcd794ae1499f7d72e1f93bae1858173de978c00f98610c442a7704686d38e9db4ede80b3f6fee2df4f43',310115000,NULL,NULL,'611b758634e50af9c037f1a3c21678ac1a5d94802d67c145bb807cda15225514','40a82af6cd8b2d9f3c8e65d694880d5826933508a30adf7d240a3734327075a6','bbc9175fe7f9a431235d011ea4b9e88be91af2656b2e61acb2b2e1111b32d746');
INSERT INTO blocks VALUES(310116,'cfce2e6c2f8b60cc702ed60cf97c9b7d98098d114b4d752152746015d19232e8f11bf72d7cdaa8cc243ed6121324c11867efdcb46bed4751e3cf9310a39c7b3f',310116000,NULL,NULL,'372293c02caa349b31391fea027d4ef8bfcaad4620d526d49a1cccfd71bd2c47','dca637038bbfd2128ef7b9669eb451bf5953f0e930046a4c4319549acf16951e','0fb619b170fd9d7e40f455247dba95f14825fceb1f4258b79649a6e5900efc80');
INSERT INTO blocks VALUES(310117,'3d1a44b687914daf4356fcf281d86d03750fa8f6a8a2a6141361c5eab4ef4bbfc2346edc1f2fba57a9a41470a0b27886e476538cf32f189ade32b865f42a47dd',310117000,NULL,NULL,'32663c1ffa4932c7dfc798a44c770dd5404ff54508fab8e5520d049c80af762c','479711671517f82293c2955917279a903c41d080cf4dac9efee3cc945ce85a18','9db9092f1b37795aad9fd6244d92b416267e8c989b76d627687d4e0629dd4ace');
INSERT INTO blocks VALUES(310118,'8c5d5deb80a1636d08cfe600073fb827c7bdb08b8482b0a44efb9b281a4a6936abb870788de2684eb33eb2ea2b815b16ad2231294785b3022da6d410f7b52bac',310118000,NULL,NULL,'6014fba2935eb347989d901aebdb08d94b1128a541601c60dd765af3a83925a4','6ba76001d0ffb7d99ab6dd078efdc6fa4307b5cc2b7108c72e8bb3fa5dcfec59','b977855f6ba7fbd80e8523ebf7fa0223083b5a30c28bc7aac0072baaadd23f3f');
INSERT INTO blocks VALUES(310119,'8b21c9a1e6ab073acbe81e671626b89a7695ebc08a3e78c52a151794b5fc11f4803fea6423656acee2f39f6bb57626658448c7ab20058c526b6925e551ecab29',310119000,NULL,NULL,'123e7fd13386f58e965487c1f02789d2df944f38f3b84baec8b5fa0d4c96f876','cfc8afbc9ea992eb0af43f0398662a6edfa9a7b9c32d82ff936d9eb14377ffd2','dcaa3a9287294ecd6f321836a796bf323e047dd8cec6beee28859e36c51712c7');
INSERT INTO blocks VALUES(310120,'661cf8375cf1935d65ec4ea62279c9e22a7ac258698618736f533570c82e54a84f5f287081a9659b3dd37355c836b2ab1b7e6a53b489f908218cf04ffc8e487c',310120000,NULL,NULL,'a7cfc95ed962e2f608fb9e6bedf9c7c904568825bb3227046ccf1d52b3253f22','681dbca7e619153f7250a6d3ddaff7bd6a8fefbdae435c21fc51834ee2f9e0db','cd03a764193c809b7e5016779e689deff40c9ad453b3340567be0083553fcf5f');
INSERT INTO blocks VALUES(310121,'8e1e3aabb4996360c54be971cc22407124cac14d9790ae67a9b970c1ad8ba878c985f44e0c97f5a768a6b2b60a683aeeac9912da0f8331be3fa8376b75da2389',310121000,NULL,NULL,'415b95b597fa4e153fab2dbe1304d5634ad23c4f5063f6e12ed7abbccdb6138b','2ee83879143fe6f0213c8698d1d5d79861b2a4658ed5b1494d375f745c2dc463','842a11e0c4b37cd968a1b8ba6efb531ca06bbfa9347e6c8d9259bee0c7c75032');
INSERT INTO blocks VALUES(310122,'dc61724d1d78c8d74afe0303fe265a53d006f5d13359866a24fc3118981f7b1640b74f095962a18e06b52a0c42f06607a967c279445797b0d3cf98e8bdeab57c',310122000,NULL,NULL,'297fc828ba0734acfd70aba14a201091a28738170a99c03a01c168028badc212','0c73a3707838b62b501dc3f91d5fff079ee49860aef25278f06b855a12246897','04a86a3b90dd5eb068e35f46ddbfb211c9574b6b12be04b2fb213dab20126280');
INSERT INTO blocks VALUES(310123,'90ff89086d736fa73eef455380343e90a24de73f6a83e2c4c348f15cc716c213b17d056f04618dee8bd817abc0f796fb1b491f7e662ea8245b13c7246c492d14',310123000,NULL,NULL,'decd6f91693ea6d079474775a5ca5d06bf63197a446ffeee19e7b5c566a173f0','154ef56bfa7d1d50b23f2e4edad60a4ec278190621b0eeef1906d7bcdb9a10d1','b31bdf54441a066a7b3e56fa4d931fbe04404eb09a230614e133fe2a66b599a2');
INSERT INTO blocks VALUES(310124,'066a44937852001930b432e453c19ca9f2cd5f4264c012ddd83b99a4c48a55458ab7468c4531268cd61333ded71de3a022f9bcdcc60360db650aa84b2ada07b9',310124000,NULL,NULL,'2645b9ffeb7ed58eb9c493ca65818b677af49035766e29461824c0bca0b0437d','1448a71979d9a1f187b7ba41cc2cc6bec669a3da500d885f326b2d948dc4f0b7','416a7626e707e993881d8898ba4d571a8bcbd860dcd5abf80f1f7d87765df6f9');
INSERT INTO blocks VALUES(310125,'8685a21db54d31658faa3da162af3f2b55ce57ed8ef63986a481b6ea81d0ae7754a9f5d85f08c84dc15039fbb0d3e8e9384304ac72f45be96ddc6963da53918c',310125000,NULL,NULL,'4d935e16516ab5c76fe0a09f65671d5998da4e0417cff5bfa9a5caf1b0b536b7','250d8ae36bd00bfa56b1ace80f87cfa7545dccd5cb5009cca41cc0c446f297e8','397e572b90f1ff8ea662683fc61201ffc2d9f359d334b291160fe3622c8ee862');
INSERT INTO blocks VALUES(310126,'00c5864e2defa283e09b07f5a58f3821372fb58c704506931b8674d45e4d00d5c216404ad13c5bd08c76f1fe1755300246a9edf5aba309cc23f410529c2dd6a9',310126000,NULL,NULL,'f9a7ea34e1d161b3cdcbdcfccbfe33f0c8e3e57fd9cd219faf3054f7025fb8b2','408de4c7b54798b12109a6a7c7e0c15923b374ce9f300f1c0299d885384bfe22','64a3f9d8179def8fefdfe4eeb5aec40a12033b49404810d1d202f02df185bc71');
INSERT INTO blocks VALUES(310127,'05c44407d5900c1193f814ac29f41fd240da577ef0fafee0cedef102651997d3339530f754f24b9abddd1fdc4e315852b4c2b67cfe59332dc0fb35304940fd43',310127000,NULL,NULL,'d84e9d9e58c697ce2fcb2b7ef46a7fbd18d55741a10c6bcdfaf697450e1b7914','4440290f98c314841b86773815ecb54a0837da4c00ebe0c33b97b31ecbb69a52','5312fe4d3b32c66109c14dee8ece16994e9548cc6d077d8d931386328dacc2f2');
INSERT INTO blocks VALUES(310128,'e1b24508763706d437cfb5ba878b8feb327e652a34d32fde7dee5c161d03db781ef69ba700eca3daf4c9ecaf2ec3070c63dc80fe86e8897193582f6dddd6be66',310128000,NULL,NULL,'9ff2e2a46c7359ab09dad26e572753773d280055bbab8c27aea7cec17d742bbd','29e05b381f788de0b9c3dbaf07c1c66d3560e7bedaebcfd9e3e1915eaa7f2bde','8dba2be3bb96c87dc720e57a05d90e23b078b283d14c3fb4af3f27ae494cfc89');
INSERT INTO blocks VALUES(310129,'2bb7be63310fb6325779d84abfc2f37441503fa24bb46096d9a47a9c987f6ebd1f140eb9e870d7c12f67dd6ccec90658f0e06b117219817d98827ede56e626b5',310129000,NULL,NULL,'350ea107cb071540aef7373ec620da64c43bd7c0ccbba9172fa70ea4671331be','155b6f03c6fba0f2791bda6b35f27a039ba31497d3fdb5fcce649f200244b2bf','facb2dbe3ffe41bc8c0bc7422dce0becfb7bfa1bb237ae4593698d974da9b78b');
INSERT INTO blocks VALUES(310130,'a869a7a7316f58d3fb10b828072264388b4d7ad2f71891370154c5161ac20a5e8abf36c675ae7ca8b6ea139f55cf1c0aa026d27ab5d262df8e487765a0a9f3c9',310130000,NULL,NULL,'4631e8c68553e27c53d251548010881d22da3552054519ded362bcc795507816','f5ab01d0f55e94be41d8922a08c26110558f5577604e63618ada4bb180f2d0da','c18cc87a9742c059a8bc4f114c0e99f15bd134ba6de4d99c6de7f0b583022f45');
INSERT INTO blocks VALUES(310131,'d919955cfb962b787fb3c77c95afc59a746425655e7b01ea346f29096d0cca2c3f26c25e638495bdbf1e8bb8c97be42ad7ce100dad91c95d83d332ec35502002',310131000,NULL,NULL,'b36bd17007d01138fd21232e5b28c5d1a65797ee44aa3c69d0b5f57d7083edfe','5f7f70f9eb5492500076360882915618e90e2bc0d8f00374ac5986374ffe42fd','611b6725c73ce8bbc71a2126abc6f690921eea8625f9050eaf871bdab428272c');
INSERT INTO blocks VALUES(310132,'de02d99d9e7bcf88968650db048896e433675d9cc53954763f706077efd5d21e70c9eec6eaea72b1fb65aae5a678753591bb7f27d12155d69485596a3acc8f3b',310132000,NULL,NULL,'019081a5bc7799327498800caecefbaac93b25dc4d5accbb414f52ac07be9ed3','0f15212eeb7174c6064d600fdf654aa80ab27b15cff17c727bbf4240cbcdf1be','001239938f4ad23839d8a3e2c3231ce3fa1a5f40ad89e3ca1e99e37b8a30aa9f');
INSERT INTO blocks VALUES(310133,'2498bdecb642839b80d981a4467fc36e80b2643d046120c4cc58c2bcca6b9238ce44f47a053840bf2e58d59cf228e7220d5c13e3a59215dfc2e2e1910c112a4c',310133000,NULL,NULL,'680beac496a8c9bc8a0c3e759520d98bbc70ce8fce6bb604b06322b7290664d7','b558855ca7e76314a130d6972fd0bcbb5c592c3ef2c8c9af995095aa008dca42','ef7d205aa82483ec490f926bb730bde859914a216aacb95a891d0a5d230296a5');
INSERT INTO blocks VALUES(310134,'ea78c1a509f2bde4e35d71fb8527ef51011c0eefbc9c4908f05aedfc3d2ac01b325c008fc91d17950b0a63da9caf78acb4a4a4c13130257eedd1ae2c34e690d9',310134000,NULL,NULL,'ddf167abd0c3c26fb9396f5529d4a47c4e49f06c41a776ae84cf5d5ab6b1567f','09889fc7d7dd6f25e3931bcb0015c9bfb2d278544e0bc40d3cabc42b822c9d2c','547959b115ea470b55ecb1c6607fbbd778de4bad4f8df3d4f7f6a3c319f9e3c9');
INSERT INTO blocks VALUES(310135,'1dbf8ea76d2e70177df10b87e84e32e76fced9ffbbb38af8f732802206b9b02efc05992ba59c9bc1e811a5179bb865711c32870751098de5c99d274bf47e949f',310135000,NULL,NULL,'65f748b0a423d97bc89aeab605a03da21f9c27605411d95e54320e63a712c97e','a3ac603731b3e2f9f42302c43561d4d8105a6b9e8759a6ee085c89bb881fc070','b99388d63fda67067d13a7a5386aa2827e92f0991c1c845cb3954bb302d1986b');
INSERT INTO blocks VALUES(310136,'96ea9a0098329dd191730a435fd65931bc05837f39cb646faa7a2e04dce0d1f0850fad36f3ed2d706dcaf00c5093cf7379e04d7d5670b0d6c50f1e2529acc361',310136000,NULL,NULL,'f843ec0797185d73b40ab899f97e0c9a59ae2abc6f1d45caa73df92d5e2107f7','de07b19ba3dd398654a2ee5d9324c70680be9c30f1ea0277ca01285761b3791d','2b9a9467b6a6005cf1fb7b9931e55c4a545e3d51a14ca0fa94822361949202cd');
INSERT INTO blocks VALUES(310137,'54f0ef3b50020802da23000635c8a238227d56227a80133a3fa1b345c8e08e28591d762359291a535c07dae86e9f35ad5d0176288368443200d598163290a93e',310137000,NULL,NULL,'1f995d9ced1e2fb1a34375c8524b99a867b70224a12dd1b15761b91980d47af6','3da298cab46962c8cea5bca37d28e4f5120ae9124e92f6d2bd665512a90613d4','d120f057234531443848e8a008c12de155c558b86d9959bfa82ef6f6fe7c7313');
INSERT INTO blocks VALUES(310138,'f464f647b3f7071ec8a09c53de3a37a001350341ee5d8740cb7596dc2c8d792dc85f7c03bf812a55fe37af26941c43f58d2bab04ae9a50c23c87d570978f355b',310138000,NULL,NULL,'5019440451492eec1db4004c66f73d483d32117d7aca68159927fb9bb1b4e7ef','553eb79a29bfffde748c3782641e9a9b54b49f6a5d8322c5092e0156d1ed315b','ecdc0133515aad82bed060f9b090b1905205c5ae8d8f92eadee585fc21d93ced');
INSERT INTO blocks VALUES(310139,'1d5937ceeeaa617ef90100a4401df06f217fec6eb52d11656d14ece57f5849aa88485ee1131ea0ea31843d74f87ec219bbea3f848c16e44d974c816f8345c499',310139000,NULL,NULL,'3673bf0e36456421f586a1d4134181fdb7c32cfb31476a2f165b1e590b524a88','34317bb3d0de3aee4e045318a47d80e010e081d40d8355359ef96458b6e2842d','4bc9d8b4178f586731fe2eb456789ca31328f39ab70e72c4891651f50ec6c7dd');
INSERT INTO blocks VALUES(310140,'5bf90aa9395f3e9fd7af5843c775588acb46d9965c5257fe26090d065a52097c06d7600b583e692bbbe178424ef535c32cffba0736834cbc51c5baf6465e9d40',310140000,NULL,NULL,'92b1c9c109669efba2edeec44399e265b864e8320fed9485c4f871c5d092387c','6db283326ce33e8f39bc1504904ddb25587ea98459c68ed1ec26c227e6fa87c3','510bcecdc5b8c61223df983bb109ac53fb7e5d168b31fe15e4cf91d0ac4411e5');
INSERT INTO blocks VALUES(310141,'303f84dcdeda12d009bd30efc4217571aa5ccf1367e49227d7c2819deb5ebcfc0d83c663f57af992b272950b055cb3ba7373249974fc38ed4e59d83777e9d8ac',310141000,NULL,NULL,'6c0bea76bedb7faabea0463ec76dfc4241d6b51c0c7102725e4f38ec2a44c3fc','fb04822396be8284bf5d8f40912365e897e967751631194e7620fc957346e27f','d433728e6082d480da1df890220b2fae5bb6bb029b8392c7398d969803b3046a');
INSERT INTO blocks VALUES(310142,'6eef8799c1dd3c4f156a6dfcf70855a2c10a6b3c16344430dd06b67e6051932878df8b2a16fcdcb60090e2c190fc7d6c8b1081fac1878aa98f1db892827053e0',310142000,NULL,NULL,'0b2af2774fcd42b584010d4c0b988a89e4f83de16f24fe4c77fcc286709974d6','596e19dcf45a0ce3de37e6e5341df3354adada357a60392866d695851060ffa4','ca55231343f270e64e3ca3e047c67f5366d36181462d104de9575ada24b84bca');
INSERT INTO blocks VALUES(310143,'3eaba6739208d14d04cfabaf5361374f0bac8d5deb773a4aa50011469774738874043a1da8942ec4f48e1b3536092fe1327fa9402ec36a217711e1bb7b50d689',310143000,NULL,NULL,'d5672f5b4fea2e7737fd3dc86c6a1f99ad58c91fcb9d38b9cac5cc7f2ad5e58d','f68f1c74d925f4eb1c7eb258fd370bb3a9993f7d0e45ccb2ee4bc277d0669382','964e6c43dea81ab8ffa8cbe40fc843077b97d83415120c53ea7147b978a5b882');
INSERT INTO blocks VALUES(310144,'f8fe4cedec10f1cfa4424aa5cb722754f2b6f21adbfea88043599c29ab8eef0f1f52da1fa4b407351b1e95409f1c50111779ce2a01f150e85090d446f630dd51',310144000,NULL,NULL,'6bbf339ceac07da5ff909151ff651a9556d871a8d7bd2c04bece2cbf27759dbf','bf3dea005ef76f4ef7c378a056d61d744f82a8391066ea328e395cb678912cd2','b36546ffddf13a4bb619b5dee69ab3074b861dce8a015c0ce3b71cdb53e771a8');
INSERT INTO blocks VALUES(310145,'60f5c7eb2cdecd1e75424bddafaeca4c15ae395e768077553912205fb74a377152bca81c3d292f8e2c8e5abff910a191732a25c718fef277de5f7fd0a59e6744',310145000,NULL,NULL,'f59459b714c3af36e01a5ac0d8f0bffbfe16b7942d2372cc6af49f2e6376dd10','59f196cefd5ccb6e2d4118c744842b83fa79f11371b59739e7f98d4dd23f9872','8c39ddef35635f0fcecffda78809d945d2998644d22cdb10efd2d116aff48534');
INSERT INTO blocks VALUES(310146,'708e9415393bdc3fca510385f3ea35724dff9d7012b29098dcdbc214b9dcf4fc0b6bb7a14672ebc11277db95c551b100f8f162c7ac9050154732df38fba5240d',310146000,NULL,NULL,'b4495ec857e025870148463304d2935c6cda662b14f3008a2ab109278ca8a38f','e961dc0990aae2ea1ee1f40192b47951038d30dcb4329772364e6e1c9db5b58f','63cb64b6f993deab630c610c23002d7edfb7a5f3421f9fcf02c29df8c8a53452');
INSERT INTO blocks VALUES(310147,'322084a62e15e0aadb94fc07c01e5252a974294af9f523ed94c5d9afbfd8770d5b800c7ca0a6aa5b277da934bd1a3386bbded20fe1a085c0ae91d67e8e9b64bb',310147000,NULL,NULL,'fc4cd5ebda3e7e858b6588f81cd1ad677ea6131a296786cfaca7924e8de6c667','1a8483890464bd64f90cf7488948ed337875a16898b423d9f437c9f1c284c7bd','7040f90e03f6084a658233f29f99bf1d9b25b92bd6828d71299e9f442e1f221c');
INSERT INTO blocks VALUES(310148,'a03009d380ee9920791b73e265b1652a69eafe3b08602add482a98e92ebb131c0f4937f60f18d1c493d3c45414d233bc6fb4e5e458cb336618152009138e31a2',310148000,NULL,NULL,'22d0016ce629072b8ee6cae18f61e597795cfedbe60f0725c1b75dfe204721b7','ea91c39d23a9aa0c40924a9ca59ea6f4a596a1793ae109bfc625a61d07271d84','8e7b49b54d1dcfbb6ddbe2f96faf578ae58defed5912de551483e808be13e38d');
INSERT INTO blocks VALUES(310149,'0ba00c363d56bdc60ed508e68b824b6bb6eb0f86d78a045322c7c0abad9446a2201a0a59bd4ceeb40938327338ca7cc3522f3368afe0bd229c53d4e60f18a6a5',310149000,NULL,NULL,'0d6190f80f0cb96c782bf952fcf3aaa06dd6497dc962a81f9b054922e08fc9d2','59ba823219846b440fe56f0a14a30be8ec5f740751254d5f72e17e7007f89b7f','1992bde6cb5d40f27ba6958aafed6dded7ebf7e370b0aaf2d72f1802eb5bbd61');
INSERT INTO blocks VALUES(310150,'9e97e9550e3e69eac03e376dca3f8faed4b5df2f357d3aa76700c53a8ff5d8b3c965285530ed791673ff7e266408c810b2497665615f43fcc472d01835d9f042',310150000,NULL,NULL,'f2bb0a4c1cd4058811305772ed5d1b2c03cd80a9d63480deb138570dba72b294','135274be69adb66587eef8cd1d9c339543920894fba13a11c96036f67b62610d','d9eb20c045e18ce3524095a6ac9ac994dfddf005838b2dec77a2c93fccc2c415');
INSERT INTO blocks VALUES(310151,'e9da3fce9845e6ee5ef6ca0648122f1e7267df82cf4f0a4476e65c4abd718ba753f3198b9bb1f38e70b57f6c7144a6f0eb0eb56fcbce8c2ed35fab312bb505a3',310151000,NULL,NULL,'524526603ea2b1b8c7b70ef3b95d88be368105b641b7e7617b1b50cb525d5fd6','c5925a14ee0bf45d8d172a09b66398d6abeb8f8a318ba667b969b7397c93a426','b1d2d4614da428c95267e49a44ef8ea4144df28da5610c7e6a9a4fd927287210');
INSERT INTO blocks VALUES(310152,'87d5946810235203ee616481806c302b6d72c5674348930060210486b39197b607b847e39e6ccaefb5bc302852570dd87bdecc9541b4c7377e6895197baeea13',310152000,NULL,NULL,'79dd15e3d503074370f26584a37fdd608e79ba77d84ce521a87ae827cde22cef','0786c088f54a918c6b66d6fe901ee3463ee922edb3f4d85a10a891701d2e141d','67aed7214e270df4b64c9e24caa2b612a8fd8528cd559d3ba0164f4d5bedf0fe');
INSERT INTO blocks VALUES(310153,'bd1637edbe45b12514c3594f115b698a8976d61d258684a456d86705ca73b667b6bc4a5cc9a371ef339d673c6fa794d6fdae5fba232019dcdf0c140baf4a9bf3',310153000,NULL,NULL,'ab1f3b8bb47d6ae46de6cb4b2a2e40777ea4fa20eb79d26d9f4f9672158880a7','e417193bdf72adec7bcbcacb970682025f1050e56c1104b91880756ac653cf56','af4de68c8e13e694fbd752abc01a4e95cb5d728bd541e14343312e73c7056905');
INSERT INTO blocks VALUES(310154,'3686d7e3810f1c46e94c53edad82e1fe6ed5eaed7b9f7da557e32afe8f81c7056910a279a054eeabf2b94dfb571b829eed22fbcacc011e75f601e2027aff698f',310154000,NULL,NULL,'969c0086bf8b3b918d0a973fad2bc5ecad99ba2e0db795b8fd32ea3a7588a5bd','c866d11a8e3217c3db8461bc5b7e506ac5e0f5142d1bfc70f726b9a445ed4239','caef5e8a9190086ad6ec437362b01842f339ead68ada33268c61c07b2ccc7be1');
INSERT INTO blocks VALUES(310155,'59ca58cb030c16691117086d2c4e4f2424516e6d870b7d0f105934be4ddb150b19fd0fe4a721d6097ea1fe0859c9f497cfe1ea4db2ec5956604e0b7f8b4a7468',310155000,NULL,NULL,'cb4ea27c93dce9e1f3b2b88b92373387b8f6e8cc1736b2cdec01b8958d97df58','e442d9b751daff2c2b6e1d5e7edc555b2c095a7cd1be2d02b9b6bc4ac4323c63','ff6ede4516735e9f7fff5d1a8385ab63d432e4dc154d1167670a710ba9857a70');
INSERT INTO blocks VALUES(310156,'4e5da453a9a40861e30fc696c06d9aa3860f4c6d45111335c7d1aa392987474dee457afee82b4a2e365f288e0731fc1428eecfae945d2ac68a357dae20768d34',310156000,NULL,NULL,'7cb63fb95d7b13f982db61f9521f3a733b2340bae0dd657817be7883ad41b1d5','1a43017d8d2a85512f700b105c489f586b15a744fcc18481bc85fc5ee60e3f76','64699968c75db45ef6a5aa3d8fd470d7acd300ec2e77afe0ae761f7f70fe8878');
INSERT INTO blocks VALUES(310157,'758237bef754b704930978e24052d286e2af5d029fb19f84be5a5277b7ed4f9b6d281021567807955237e3629a0e44d7524eb5a998c598191f8ab61d4b5bce9c',310157000,NULL,NULL,'83fa538be81f9b2b4c51e5d73f1ead40cc86bfed3ec2e47397cf8bb6ff4f2b96','c474e6af509ce9b683dacd7f42fa4a62195eabe91bbfc1bf73ae02cdf55eb865','556a1fdd1f61e3c528c478b588575236166a2588ee4f63a46b2b6dad3eb9506e');
INSERT INTO blocks VALUES(310158,'8fd95962fc5e96c28e590cc4abb6070abd4e041d9dbd1670626de27de3fe6a85cc38919065f6f99bbd46335bea510029f68b8a0ac6ed5377beb469b7e5788c72',310158000,NULL,NULL,'8c498a628e52735bf0d581344998d8a9de1a5d4ac3fde0594c54c5f9cd3524df','532a4c6262b4c969bde08692f68ff3424265ddc22f77180f6787452c36e94169','c337cbbb6d489038cfa60d392370a8c79a3b2aee081a0f312b6953b92b8cff2e');
INSERT INTO blocks VALUES(310159,'2f2a14b6bcba2e16e8ef9eedc73c48d5f0b1cbf5754aefe2da5e0c973b884a79054a127eaf78da9e4588b4e7437ba37ffc41ccac22752f00e9d36fbae929ab70',310159000,NULL,NULL,'ff76e36679804ca2c3d25a8e19f7ee2838aa742d595fb80101dc84196fd97d15','9af9dedc3a374ecaae8823fd52a691930085379b79da382608f08d67666ae312','38df4ca3bd563b24f6c9511c173feef427c6f6eac19540ce72bacab4b093fd27');
INSERT INTO blocks VALUES(310160,'4425734ddb4e0c8c9d8a90a46888a460dae3fa6583cba2f1347c40c349afb8fe47029517fb885ade0257342e04cedacd75f38dcb93aa19e3f0b33253b1a98543',310160000,NULL,NULL,'4b50fc91c45c5437e71c4580b50841ebf39305ebb70bddb957aa9d46ca439961','f4479fedb450272ef8a002c58c787abcc0d33fcbef6a546d5afc777b9f4e8748','927801c6007152ac54b9f06b4efcd68a50d9e0d022da85987c526895916dda49');
INSERT INTO blocks VALUES(310161,'cc122bcb43f2fcafe55d479da7ab9df488491c6568c97478f93df352d46559675da2d7f627d17d9401d84ba83fd10a8a3f14129aeb1f4a1d2958f1b5a7859a4f',310161000,NULL,NULL,'3d8612bcfc411ff28de1de4dab6be30d40fdad9f39356f6e514ad94d9e52cdab','0ef42e042ba9b810c5d0143f1be5c1d8130fb534208bfb755f887a234712ea94','96d3405ce6e9550901b65449f984e7d2e3d55293e55800246d08ffbfa647a31b');
INSERT INTO blocks VALUES(310162,'0fceec7b98ba84ed354d29cf23599eeb4036fbeab3cd9bbd840b5967acde98a1d7f0c36399d289713f46ca01e3ba06b5972fa120ed41ea427e24658d134ab69f',310162000,NULL,NULL,'ca8f76a157110ac519fa9dc3c62efb5857c8e06ee6e82a34e1cef9d891e516c1','f5afdda121ede9ab369a013748255a3476d9198b709053549591206eabced217','5e9d1734020cc798bedbac1bedfee6d8ca76fd502cb707ad79c51eb1dbb258d8');
INSERT INTO blocks VALUES(310163,'7f7ef65a3fa9aba6073617be75c6a9f1373f12c43cb0c73902c6f3a4fe9754ad9d85afaa2bf6aade7db1b485dcb615b6e6ad0d45ba57cf1efce4efaf185b2b82',310163000,NULL,NULL,'9a317ae30082742bcf5f6a5f47844d73dbfbd9bb7abe61810b8bfc813d647c1c','c16782017fe1b3d66677f32706cbe54a347222047caf57a43b80c91bdbca3e52','8ca0835ab46769dabaaa5a921e524acdf62b44b1f15bdb4068c733173f81142c');
INSERT INTO blocks VALUES(310164,'e20bc6e0d1d487b51b568a76a700ad4859e049359ba7ba0fab39fd4a9a5410b2f15e810078d6fa29e1b0a5ed78ac02d01c7d6bead371b15bf4f05b63646a4a80',310164000,NULL,NULL,'7e2301d1076e2c6701ebc91f2d9aa99ef534d372c58c19d0abca3ed745ddbd3b','e56b25808003958af31bfd48e40af1c5d0e8eb7ec8697f62faf4b379cf51ebf9','d4570791f6feefd06ec6ad9e0f67a1de34bbf3288cf2fc72d8c156ea3fe8a5e8');
INSERT INTO blocks VALUES(310165,'23aa93aa7a33542c0bbc31111aaf1e00dd180d41130030d1b288579285cc2dd5b27458a82d5da4c1dc9a4a5705fb7592c9d790977dd15c8b884e2bd09d9255e0',310165000,NULL,NULL,'3c6e077f4028bef0f269f96b5913eb527f09cc687dd5500228ec4eef14295f39','7109931b12b9ee0874b102854b4a3e644dc8194deba085b4e836db0248478d0e','115b434c7461b2d97741f9ad8199254e2cec32cc7b5c4167219f6de5af758f92');
INSERT INTO blocks VALUES(310166,'b58b320bb57889504edd100b9ca9cbef6f4723f0c4ac8aab2641f9fcdf7a6f1638ec7f1c96b0b83f2f0b5873a229f7e41ccaac6c3e61055ca5022c0f0308f239',310166000,NULL,NULL,'d1855f833aaa4a73eadb8cdfb19e673c4bf4cfa5bb9415154ba56d6244f29705','bd54dc4ff10d7d8b9cbda1ffacfa607b84182c5945da064aa56fbd281d05d37a','f70984f786c84f80f066343e4cdcc13aa94a8ffad7ff79dac566092a6fb92c3d');
INSERT INTO blocks VALUES(310167,'9736af165bd0226d12623876d64ba05717572dd0a895fd2d2dff80653fdbe7c54b7c6fccbd40f771170786e3567b4646b3ce4e89e3432ec00762ec0d939c82e3',310167000,NULL,NULL,'e79f05a7830739ce38804d33991cfe427f9967ef4cb43eac2fca5984113dd7b0','52298add13558895afba2beb64be144cd227db5c0b62334fd4eddbf6e34133fb','a9b28bea36658ff2667ab06c937f2e09524178edfecbb019233345f1563df647');
INSERT INTO blocks VALUES(310168,'d76456c23e4128704d18f4889bf93c185ede9e8794df8d0d97c37cd31e4b60dcf67e9af24bda5fb90dc7c435ecf4d8f546f8b4e4821dd9484e1c0a133e9b301c',310168000,NULL,NULL,'8489d41bf8405dc1dbfcbb7c7d7ad633b3363bae588f55f071fa5f2a5905d61b','21c56515d2ab6b7961741ac34d9336581cefc0924af3dfda85f6d5f3d417fe4b','564696c45d722cec3aedefabfe44e4046c87b163e6595eb06091d154453b99e4');
INSERT INTO blocks VALUES(310169,'2935a3409924b7776310bf9ea8f4a1afd7d9e4a372f01853711897fbb13a9681309ec0b9e957c9b812db31f0c85fbb82d833fc019fe14aa3e9bbe4883d37d4a5',310169000,NULL,NULL,'d797a574db268c5cdb49ce82c119f0b4fa47c5a16ab885658551bec0d474d74b','819a829de1f6cec0503a2a04b490fa07734521a852510b36108049a0316241c0','e844e38e765dee1e2d366d41126345d284d9cf6a237f7f1a4a8ccdd7eb432d9b');
INSERT INTO blocks VALUES(310170,'6bbfba4a0f9dc4b64562d47756dd77cb1c0594b5b174a30c7878ddd04f86647ac3d5818de71c4872a5d49495ebb48ed322f10f6af147d8193b803b9a3c8e2fec',310170000,NULL,NULL,'f0d1cd54771c4337007f5dd6ed82e6ec768d3493b11296a6209433cd9d24b261','74c29c8d54bf59afe770682f2a3d157d016cb446f09bf2ef36b2b5a881beb2f0','c295ed915f61d06b1550196f8f31d1251e9494fadc19ee6ceb38d94bf4f65807');
INSERT INTO blocks VALUES(310171,'45fa574fa3aa1e16abf5453bd88b82630b4b5f4429d56d74c8f93d292dc2f0c9ff20a05f820ddc4e3f985e31af5dbea95d5f829a6d4386e98323923d8c72d30d',310171000,NULL,NULL,'6a5c5d6f8aed44c8c9f7ec17b9e1d9b607d28b6e6387b99a8881555e5dbc1dc9','932a95826d6febb11c9868991faceb01456f24cbdfc92ec85346de9f4f13920a','c682c3f3207c01bdcb67e14b15c080cc99a2d055c3d20772ccac7f1e0c44026e');
INSERT INTO blocks VALUES(310172,'a6831f67f7dc90ec04e6fd9c89f50b90d4c9648a6f33e2b1af610ca7cc1ad53899915f340301add4be3c1f7e732b8dc4018ef64110fb78dee317e44830cc6db9',310172000,NULL,NULL,'1380f7dc2ac1110fd1bcd6a90cfcf77d857a74c80f4f2f7db4f4f652cd31b092','f59d130316cb19aede6ac1f15a3e2fa3662d5bb7b2cf97dfa0e5728b02857c8e','ef33f2bf000d4e4b2c28454376b77825202afe9a957e116960e049ab7df29ddb');
INSERT INTO blocks VALUES(310173,'ed8b2adfe3f5416001083066381ef1360b0365feaa824d2f59138c361c452ef71c9b9af88f333585b1b8ccd1324260025e1df26cafd5bfe9f89c257ce80b8ddf',310173000,NULL,NULL,'f31ba3629afceba8e6fdab368a4194f74c50bfc4ac128024fbb2f009f97443b4','036d4a631294618d34bf51d1d607756b79fa29a892fb098865a2288121be1e51','ceeacd83da594a5d2731a099167f2f597caf8d7507df3a8ea1eeeb36dbcbe2ab');
INSERT INTO blocks VALUES(310174,'74155b1ccb11f56e2ca34161456ac38512fdc720445ebcf3458cc77abbd13c63e32517e2f13be3d6896d9c33c747941cc587f41bdc07d2b0d76117e390d001d9',310174000,NULL,NULL,'5940d1aa7c3b96ab4164ce4260c26280d0b6f2a3f332428bbb0cbc23d4093302','ce075b5d983200ce8f3c6282a0e6e4d854f229ea5a193cb3844881eadfffa4d1','cd79ab9259b37a05aa1e8c73bbb05079899cce7adbd2242c485f716d9dd6e717');
INSERT INTO blocks VALUES(310175,'8e8da7a1e5dcb00385f5297e3c0b624a42d44caefaa48b3a643794e280589ab0ac46ea723912ee8aaadf061441a4c467b2ff82ca6ddeb623fe49e0acb60bc9fd',310175000,NULL,NULL,'0171b02202065eb95eac5746a1aeb893125bd91440ac815aa398657dd51a61b9','93f154edf75f74097820b1ef943166c3f8ce9887c41ae523e50fa6389f734224','745d974edcfa2eed536770035e5d34d8084dc4042f7cc8bd09138ff9b6dd082a');
INSERT INTO blocks VALUES(310176,'d1cd1ca90ba240b81ef4db29767adc7b58e62c5c06c5dea7a34fa6756c46f1a95e93b405137bf4f058c1281c3ef236a3fa9ae9446b74a25a1a23e16f6b2cbcf5',310176000,NULL,NULL,'77c93221175d5364f7d22c7cf41ade1dc2f2a7c5478f77106bee45e6dceff9f0','f809b03907a30f4b2238603b6e6d22bb20010167cd0bd303b6d20350712c8f1b','a91bee997a863bb5415c85e79a3608ded472c3d990b884a3afb4a6102cf56ec0');
INSERT INTO blocks VALUES(310177,'9bc86b3392ce570794748043c352bb9c2d60e1b6f29c464c4f1bebab322fe2cb5f686edb5e19951b1ba1ff9a81a15de45bf8a8a898a7557f7d45802daef0ff14',310177000,NULL,NULL,'20713ebe9f30de0de99e17bebbdc42c51b44de992549fa7098a912ff8eec6236','10bc7dc12f16cfc56acf5374fc68af848f57f77f63fe715acbfaff3a7a96bb30','93a2be29edb774d76f544a9a494c8f9efaf848de5e6c61abd3a8851e26bb7a15');
INSERT INTO blocks VALUES(310178,'3d807be2f0841df7dadc78f0d9cafbacf474a7566c97923b854b2d55e877d3794653595ea2694cfffd99f2a7625d595fba7b6ed9b364b2a5c65e2759f6bbea19',310178000,NULL,NULL,'a36ff0c5f4ca0613266e070af8e7211b14a5d511425b9939a07553b64d65b172','fb02bb94bafe2552e8e15d22a47fe6139d6328dc0499691936a1f1fde131af06','b5ede512cb96618098e5f7089ff94a52fcc53e3ff7ff6e4696890e996aec8ae2');
INSERT INTO blocks VALUES(310179,'de1875d9f78a6a73d5952eebddfb453ef5c3cc84424f94c3e159cc6978f5e616f4e34f172f5721848689dd7dae71610cc4b116163689a03638899e015ee573ef',310179000,NULL,NULL,'a0a7a2fc8b8e2c9abf0f796afc76ce74d40d8050c05e645d6bafaded866321cd','b0ba3d61c038d57428995c1786bc26567be9c36f090f1d956644f75aad813859','33a166dc9e8c9fb5626b85ed478d9ed32abf345230acda8fb404ad88ab9c1779');
INSERT INTO blocks VALUES(310180,'8d0c1e2d34d331834a636d883d3fed640c169ded8b81a25bedaec7dd57247f0ce5ea81016d704c7350d38736193ec92f21ad70f6bdc24ffcfabd9a5da9392ec1',310180000,NULL,NULL,'2bd835263203369d14bc9ed07451897e520ed32765ec4544fc2836d1e8dc9b1c','c1b6f0edf189d43512bb2b61e545df686b1c44dedec8382f81ef6329555a4634','683d2008eccafd1d5dc9c3cfef9247d7a89d76a5aba3a7f606001f8f73c3101c');
INSERT INTO blocks VALUES(310181,'5772e61ad3e5a11ced755cc9b7f7f9221800766eab5aa3c8611c213b88d6dcb5ab678a09d5c1ac3a247e5bd5e6645ce7c83a961485d65241c54f12e69160ecf5',310181000,NULL,NULL,'99db3bf9fc3a7a594d8c258e15501083e9b52331b60cc12de8dd63edbed3cf68','2697f8c2e014b2c48adfd69958e10e0c9ce8a92867cfb02f8ddf4ea53cc9c526','7574f8beb6d8bc1e099b798c90425699acfd359373fb34d384debc1549507309');
INSERT INTO blocks VALUES(310182,'cf5773ed1716c6e92f4c53464cb77ee2c77484f34599905d74f9fccbd4069f5cd7038a6fb2b8d3cb1eac5812e09d69ff0c5fb96fc2c788b3d855d334e9545523',310182000,NULL,NULL,'ac7b50c8df9af45eee7781f4b986208e62e42f7e3803b84cae4615c5483ca5f9','70f3da4fa0cfd8050e85176cfd172263e2ff20a9888826afb3620caeba5371f1','09b778bdf6009a10af79f8760c22e630aa6859f65ab8e79621d935fb59a7bae1');
INSERT INTO blocks VALUES(310183,'37b17271fcd06d1dc0d93746d05e8db21fd43a056680aadc0a2c5503d8abb328f749c0ce126e8733eb1c1dd1be1c33afc8da39e3249560b0ead9ff05736c4dc6',310183000,NULL,NULL,'784da7bdd3dba038bc620e389576c1e688c1a2b7b70cc04e12f272c4e37697ea','3b7c587981a00039cdf9230a308909f7cfa3be7946193cdb963270c086e03ab4','01314f59665bb2862fdfb2fb6d6e69aeb307700a7adec436e90332676c5376b5');
INSERT INTO blocks VALUES(310184,'561300bad5e3a41a6b280f608000b1895e85f229eb80f8d945f56198af5f89ce4c675fb82048e90881610ef9ba76de64ef4cabb599dd8013a2b9fe805573670c',310184000,NULL,NULL,'9e9fbda21f99aed30b698bc1d791fcda550f41f63c6664497d12f26139424ef2','516c3c5b76f9d7014dc67c1bfe8c87c5234cfed4f4e494b114306d0475582174','700dc0085a53cbf679e4fe8269d882ccc0be3a04c764d4428eadabf4f9851399');
INSERT INTO blocks VALUES(310185,'b5c464b7c4fe640907ddbba48d37e07fcd09d7e0d3c51649886c8fe5592378745c0f7584a188fa042be11731e3acf542058a5ffc9527dd2f278e025383779035',310185000,NULL,NULL,'11de442e150da4cf9bb3fcba5accca4e92d8c2e48c279f5599c323252bcbeabd','61ecac30d6391cb489ed9b40532d73065054322ec390d8efb492e057d6da1a7f','c4438d9048b72dc6d98077395af9a44f1de777376fe983ec95247d23f8871331');
INSERT INTO blocks VALUES(310186,'22ebef88212b43581eb11c01293fe45dd576db2eafd53c6cfc0cb85271745415bd04b38f528428b736d2ef9b9d1714e3fb495fcc4334a1699d481c3b1d380ab2',310186000,NULL,NULL,'608d0d03a1326142859dda87bc11495ad6aa5156ff5b9abdfeac4ec6f5672ab9','5fa93924fbce523aeac4bd09f042f61cf00844715f73d7b70ae09eea2131a90e','6b9cf7b863275aacf9a034e89c8562264e72e9f87cb45b006b17418945f89993');
INSERT INTO blocks VALUES(310187,'94a43b55b4565483540f7802db450c22fc0ba45951629d69d47eced2d49661881ee5fc1a5b756bf9d8e38fd0029fa6c830827793cd9b41bf05da2a8105b54a13',310187000,NULL,NULL,'b60ca3666e4d9bcab7e199e14256a38a72e32065e5c02c6b45dab7b72b72f38d','a40a89c0d3343bb62d7c0ead37f57dddae6cf698e692f5409cd1acc6cf7a7767','8f07487946e1c8ef416d1c9beb257c0a50d8c5d3136a4f433a6a79e28b4c1672');
INSERT INTO blocks VALUES(310188,'1f09285262e790ece05ee3e305d5e5a8e6ed5c7a5b37a31769d0fa554184601b67d853fdca17d08f54ef2708695eace84225d184162ca1d9375ecfb9fc01433b',310188000,NULL,NULL,'5ba4b2ba0e581b876d6eced9cd9c7db21b6538c7dcfd771b60c1c615c72dc298','9f3fac23fb72745d84d619f8927f0a10fae8cf4f51106953193cfea28e8b1985','6e73ab8e275cb0664b2fe5a05d1ff2c413d0df8466cdf8f7ea9282d6b9626854');
INSERT INTO blocks VALUES(310189,'bb30ef3877932419706f2479fb7ffe9ef0e01f5159ac70cc783bb06755c1d81dafb8fa0ca98bbdd89fee9747146e91df626f0102a0882dba413e4356da7c4999',310189000,NULL,NULL,'fc61e932b28a7b1b543a8f5c1f430916fe9b531f6a192db049b58a662186644e','3c61e84ff754329353abcdc0c0f9029f45daf4b30ffe0297f61ee61cdfb7f1ba','3d95e6a299c7a527212eeadc0eb69552b1318a5219c259322c9c77f003906cfc');
INSERT INTO blocks VALUES(310190,'31407bb2cee22fe9724e3eb9a56d6c8f0162384875df882f1d72e3d008882893ad1d596f45b7cc76949b72fed973f1a5652bbd2910f95d729699929fa05bc637',310190000,NULL,NULL,'904e67d8dbdb85c3512964ee234e02fb30d21f16d1c29b25a9c95246a61dd986','b91b579da60d58f1de5817606bee017c5bc3a2addac36b984f7abe299165f3ab','9a9e7102b7813859556d43fbf6d8179541d33d3b1c0c1f8a611a58525632ec25');
INSERT INTO blocks VALUES(310191,'2dcb942dadda125ae31f3cf53a162393136b761f95879d359956b38bd9126b93885d43a4099b4039000ed8aa633c2398463b3a40cfddd0c51600a10a3e100a41',310191000,NULL,NULL,'05b8262afc4bdd3fa7aa7ecbadeca91b8418ac970f242f4bd71c97d700f49058','e436f272e5b6cb823cbe1154f3a47965dbcb434ab888849635ccb63706c8c87d','1c5274353078451e7ccaadc30ce97b87784d3aa239ef99fb65fb3cb3d759d734');
INSERT INTO blocks VALUES(310192,'7c16e6fe516ac5ad6f1c65dd08411e0bd33d20b892d65e95e118c4b8241e8e478735a55a29f20fc7ee8ee1c27ba709243bdda8dfc00d1021f7e4a0a0cca3d3d3',310192000,NULL,NULL,'e3032726235bd6e645df8af2ce78f2639c06b085d12ac7be0feac02e74d2d30d','cdcc66a7797c5f26bd49b84df7138554bea4557e5f0334a4db370e20af57d939','2e619ea00a030c6bdbc4a81c8bfd9f55ac6925e7d6c049820ac9dc1e7034f4fd');
INSERT INTO blocks VALUES(310193,'b129b90017dfa34a36d8251cb731ba1fbc1067ed7e7d1da6aa6090637a4192ce5132b3eaf929b6df4b080e1db431f14af30ad86aa659e227f78c49dbc2c0183e',310193000,NULL,NULL,'9303d95bda4b30a8fb3c9e0573ebac3aba615d9334d6d8d5c6bf89b7876e314e','80bfc37c2966cf7a2fd1c0d636fb69802f56d3d7ffcc66512c173adac0649cb3','32755e6b81f86e31783d850a92a9ee9c2874ce70a65f8c306cec3e0308a53738');
INSERT INTO blocks VALUES(310194,'fe365596112e833d1febe8dfb7e043186c77b7d46ede329406b728c70bcbdcd69307667b52ada5786ddeab4ac4abdf2124f8b44a7f89b2bbc47d48f437d2ec9e',310194000,NULL,NULL,'8e9f7270157fd7aaa228aced55c861dbe4e9881801e69b0a76f3973566f0e709','2f5b1f7154abe60818099ffc396a91eae2095bbf30d166064a6369d1716ebf6f','2beea4a330e0f4ab547c97f20f7573a69d09f68772d610a48cd686cdd70f17a0');
INSERT INTO blocks VALUES(310195,'ce0238d5868d08018c8c7e2a60ed09e62bf43d68e3c93270ec0764a8d545795b2fddd0f65d1ae65148f40a0719e70870b2260e44e6d6b34651d9462f6cc22a9c',310195000,NULL,NULL,'34869517c1e286af93d3747b9128a01a8e9839b1d905b55814f861a9ae08e6a7','ee054d56897c594333498179165aacf4a4520d642afc1aa4b8dfd8b538e6887c','36b26407b551bf8844194924e3ea12b02c312138245dc457bfa16e3cb9c85f10');
INSERT INTO blocks VALUES(310196,'2cac341fa2f3168c883fbb847491f27137e1dd57c6954ab1ca8987439b8a380ddeed89f0ec48c72b50388b32fb9949cdd7f91b5cf1699a079411b5853dcdc21e',310196000,NULL,NULL,'9e19191b268f9304013abf6cfa456a7f2a17d4cdf9484d1354413190ebd16120','3442d6d0307049821fc76c5a21175d01139a97aba5f3d7241cba9b92ee582d24','938d4253e4fc987c93de53706b6ab94a602560f841a91b100201d247b34e0d84');
INSERT INTO blocks VALUES(310197,'76baa8066e0367c896c42ca413351ede2d01956cf2928e8db2b49532e883cf33f001aa407ba509d207ce1e10b04a89238ccfa34a96aabf8ef5769e7124d9d5e1',310197000,NULL,NULL,'64b0d2e8aa809b582c95ac77bfbe27b579634ccdc3c3b8f44ea329c62e90709d','2b6089abcc355ae5dd7b42f05e1a11cb9ab49d0ee1762b40b6bb2c0ed7a3221a','15d723377ba753d73c56f553875e764532e66694633964e47e020b30c2b9f05f');
INSERT INTO blocks VALUES(310198,'5954538999fc757ad73102fc86f4abfd466561da28e2954d9d0d740b2d0120280541676fdb318d5b9523df9817ecac15825159d08094df9e067f34febba96025',310198000,NULL,NULL,'4762a9263273c383e3717ff05034f93c70007f9cab027b55a81150ad303f9bcf','bdb8e2a20ebca1a854cf8cbf22a6d77031f0880f27f9701da28fcc70a8d417ac','f36cf74a30b9fe3aca57fd05d6328b4bd95ca1610a200a9de954ae4d53e338b3');
INSERT INTO blocks VALUES(310199,'8bb67d60026078805a12980af74fd68b56a904ad1bc2b808341140be6d4159f2d9e682ff7a07265512b5f93db0596a54711c968f371389c8905a195badd4729a',310199000,NULL,NULL,'e5362af0451d4f421929a6ab0448806bcb8663452395419625559fc8d79d9a10','e5903ab0448d068cd1a31a821e2f7aac22380848f1d6846047ac43eb255a3d1a','7b4f087569fe4363f3565d569bd96e3e6ba00a60f852facc4133a02846e0ac99');
INSERT INTO blocks VALUES(310200,'b4d68ee6ff2024e7ffe45cafb9273412e2a3f94ea97edd856830540e1b14e87dfe6888ca25328ffb7cce4652099f86519cd872f1c11c7ae937c4594b24b65643',310200000,NULL,NULL,'03ed55fdb18e1f389ce6197b41697f6622548846b82d0e40d7eb212e6ef8a289','78478e2d17da343f399d041de8b22f8f4abc3cae4712affd300e128201f72ddf','4ee06f25fbd8d14c591f7aeafeba3f08cfbc88ed824677df909b02faeb53f07f');
INSERT INTO blocks VALUES(310201,'22d1f267fdbac9449388f06214fa56a8f066f503a54b3debc0c05337acfce63eff64d70fb57485f2d4f0de22151eb723512ba94b527dccca3163be3660289388',310201000,NULL,NULL,'5128f58d06587b45770ff1d166f465e443f17f17bfceaf4b10405814b2525fb1','5006b7edb47a19be5fc0fb3d842482df229b175149a92c2617f61dea62becedb','dfc0ddfe69503e3bd9012225f31dbfeb09ca511186bf848f8ad39bd089e76bc2');
INSERT INTO blocks VALUES(310202,'47c65196973497b90b18e79b5d56de56cf05955204b5d1c793b10749c2200c3a32251201fde07de08f41c5ddc50d94807a41fd21d8c843b06f3ef4fb7f8a0694',310202000,NULL,NULL,'c733fda3f54a22df1e65ca68f7cd28d6ff68eb354c7deaade2c35d52bccdfe4e','db0a9884e5a3c2e92f53608fe1f151ee00489c9aa36c940d5ae2a230f500d475','47210fef582e19bfece755596b13d591e199e22a207311bb9131497c4d4dff4f');
INSERT INTO blocks VALUES(310203,'4e4a1b5ece42b2d9f736ca168fab5e748bd25bf04a6befe529195596435df3bf5c79f3d007a342e396216ceefccee86fcd8f2c6fc6220ffe05faeb5bb799533c',310203000,NULL,NULL,'f276bd596f87b7f695803deb8865cc08bd54ea302312e80b1be44e683995e432','7a3e971dd869a1adb66d20fe3c01ca710d99aa82674a2ef0ed40d316d6dd96cd','ffb703f3b2c799d4beb9e7fb2d82d0835b10172a0cf90be3a919310ed9bfa9b8');
INSERT INTO blocks VALUES(310204,'a24b71e73847bb71fa295126b7a5469a4edd3666e1b8ae7aa116b176e0aa6d3e0f1cd802a4223e21484c76e258d310964f772609f02b368ff86eab0dc75ef249',310204000,NULL,NULL,'3b6fc2b69c2e8b44848430b7694868b50c81908fa4af1fadf97c753ba601e2f5','368f8d29a905be3586d86f0e75827d5762e1acf5f6a8ee7c96470be51121417f','6276a9b45ebb34c12b5d3059d1fc238384e0eb30ad364bb38269595e86a9e299');
INSERT INTO blocks VALUES(310205,'a72464e94281917ed2ab5a9d6b4a2c2aecf7f75c6ff2f0b99965920ffb131d8cc0950f7c555dca580cda03c39d5ef2db92159bf755c7589ddc639395774d92ea',310205000,NULL,NULL,'7127e570d17cf4118f788d24cd0012a356e59da4a8216a17e9b00cead2e05b3b','0ddff2d6f21b69cb5192c439bd1c635ba1f919f59f89527c360ed1d4fbcd7d1f','3f29e1393c601ab45367ee7ae4370c6b04a9c3b1f2114c6c8b15a55913ad59cb');
INSERT INTO blocks VALUES(310206,'01cede99fdc8e82a0e368b2da8b68fb55ac1eb73e38a2bd2a6e307bf60f2bd48689a9b1beb995ba2807bcbc40d68cf99233d7c02da0e63e12dbe2920bcee5a32',310206000,NULL,NULL,'b0b2ee04460f145bf13dfa0c8607d72b74d0234027b1e9a6cb3022d361b7400d','cb94fce19ba4d272c152fa2ed6a901c99ce143e4df72b9ed26d0a0983bd6306e','847fbda7bd34c44a3eaf762eed37db759e904cde22a7b4f1e579af3130822b4a');
INSERT INTO blocks VALUES(310207,'88d4ff20997e03629ccaced0196caa97ab4b77184c74017ceaeb6fb389042b988dc9a699b4fa2f34834eb7f944f712ddee8f9a8b2d1d2c06f0d8c168c68807bb',310207000,NULL,NULL,'cb58cd8ec1f8180c3aea689ccd3a4a66afb9056d6ca53ff1612c5461fef73a42','3798d7d5c5939c13a0555f53df63f63d3b09c0f44bc30c250d3b9d3747b96edf','ce3d62315bdf2f90e55c6457ea792d7a2b4e91dffe1fbe3b7958c0e1ca868d8c');
INSERT INTO blocks VALUES(310208,'d0df3a97325c0945024e56247937403a623b103da35b0ea2ccea010874723c8dbc9d84472bf71d8d0508875dffdc02037ee49b7aa66e827fe67e5f1d0986bcae',310208000,NULL,NULL,'a459f75c3478e0e33652aa3fdb617cd89b8fd0dbc1c724432b29da8da7fe66eb','01b630774b292faf9ef9961fa46174ff0f2efb3ebb850c27d7da341c0c8059b6','19b042449d2a832ae29b8e720746940a96c1f22bddf63d31d803fab7b6090053');
INSERT INTO blocks VALUES(310209,'27ab1588eb066b1dd2f7e3e7fb063a9c9aa1f619dc2de468655477924c0efb98ba887527b103a5f684c7a00ccf8e1f47a3dff2442b6dde641344c29118771dd1',310209000,NULL,NULL,'79b88540b246af97dd76be187f54182e79252fbab6aa907b8b8a834ccbbf7449','97d96f5194fbb451a1f0cf46d2b77cd29eca234281669b4a6f66ae901b03394a','60c410f9589bcaaf5148ad800ad7496fb9ee27ee5bf33fa0d487431d39c1860a');
INSERT INTO blocks VALUES(310210,'83f1b51b0533b378caccf1c10c24d28f73b337f2565adf1b98be45ad0a41791c54423366af21e62be4b7c162bf00f520272e1d8d9f1ef559796cf77f12cb972d',310210000,NULL,NULL,'c4f37298d362ace7f05ad632c005c463c19f201bf21cbd4437fcaa154082f120','136e4d7e85043d299a4ea803f39caaf59251f029eab77657b04952a55e721dec','65579430d81276b56ca2e6f6680d40b4dd41fc04a74c3582ce978dfea151dcac');
INSERT INTO blocks VALUES(310211,'3a9056c07772171c06ec205a69c4b9d696237a31df08da36b0ae6450c572b51cab86c482f5438adf5f6ed205f25b85b5cf917251992126a1f3bb45c5a46dae53',310211000,NULL,NULL,'4b27d0723fde4ed5a66aa0b7a24f7b07f66fd06a39df1f562c325329ed2bd472','96ab6386f0cc38160d72a391020ce1ec78af42f2e232f83ea5dc8d1e247c155e','358aa03c5526f4d25b34042bd807e874dc6cf59fb6b52941dafa2bdd6f802117');
INSERT INTO blocks VALUES(310212,'33d04a1b268568ad87bc3b1eefcec805e49ad6422687372c8df9573167be5a59ff175390db4e4be3b70ebc3aa80b0d97ece4ff231544e8eb2b851c29c5453256',310212000,NULL,NULL,'288ed0b8e8499697bbd46381dbfe073e20d20b1743bbf46c10cc7e69335b93c1','4ec51a10f136f75288d43882a7a9143982f280647fb8af0a7bb7f9b950c9f328','31e60cebf8fcf14da197bd96c5f356cc9316271efb581b4b3939a1f178d888dd');
INSERT INTO blocks VALUES(310213,'3c11510c4b3889cc5ec632b1a35bfbc6c926dbc2e1192fc35e6a1086bd1843833efa11e8a3e01e2b52b5a4f605d56c493c26096453b3b55ce624b998835cf3d2',310213000,NULL,NULL,'2faaa650d666de4b1a6610eb179eb410224fcf93f039705d8abfe0ebe6f4c0f7','ade0813c68e0d67da84c43759ca92346a534c96ab9e325bf586f70bd7e7b60dc','c10812c7a10eec377baafbfcf5652a3d4228ef24ff5ba5ec235033ce382036a7');
INSERT INTO blocks VALUES(310214,'6b6498938c5b75c479219197b56bbfcd0bcdafe8c53f44c9253ae6ba7c1cdf32fa787f59b631066a6f64f4d581af1fd28e4a5bfea96f914b95c1512f979ff029',310214000,NULL,NULL,'1cf803688f289a059ce507f32898104f38cf4bc82aa656edf46210747ec5fef8','f525ccba61fddcc001859c0082ebd0a78117f75a9d922d3df9fa112b9f7648eb','d902ed7c51193bce2c97f9609c8a4e03a5f7789d94752d2df175223045a77382');
INSERT INTO blocks VALUES(310215,'72bfe8c51a45f0653315cf109218374fbbe1b58f9a8939c9a9547ba629993f78d0ab8fddf2ff5bb4b3ac5b02e6b12a73dacddfa5a6c226157ccd2c5c63bc07d6',310215000,NULL,NULL,'3a3778415456be854a4504f80a69f6e85c5dbb95986a3055960cee8b8db8786e','a65e453655c4535da4790bf92a5deeba4a505766b29a0f057a42fb0b9cd37583','80d32c6e4a56e9fdd3108fd37a6a970bd61b126dd728ea34d1b7e1da748ddbff');
INSERT INTO blocks VALUES(310216,'bb5034d8b3bbf63b4ba38cd0df331a67b6a2a4acf7c3b1f308525fa77507e1934f248e0c14f4121f29d34513093ea93d2ab1a0ad69f816683401042512f24112',310216000,NULL,NULL,'d1cf1288d819681345a4a683ccf31c6efc3369efb5a712ad27bab7f0be38858e','bf9b0adc9ec86604ec8acfe0ec3a2eaa4443405b4a19c3a68e374d535311e493','11c2e121b6a22a53b848029bc360d245146d85ab25d8eddccdd9d60f0188f2a7');
INSERT INTO blocks VALUES(310217,'aeedfa4625369164f54f43fab4fa144340162fa576556f9273817d9f6fcf1c19f649027e7761685b677e604fb80439fec1febe92a87320737e20358ab33b1266',310217000,NULL,NULL,'bdbecfd5ffa86a4750004c4938b0948b9a5b06c0197fa1de005d1a1d2c5bc3b2','26dd905c129a2159fdc365ab50d5151afe93857a2e6027ef09317c9cfb785994','dee4857c7a876f4b0f89ebb7d8b4cac5a168e526af5457e2866bb077882fcd36');
INSERT INTO blocks VALUES(310218,'3c7eb28c3fed2eb7213917ece79fca110f658ac69589355d0af33263f8717033ed4e3d20fab5e3819354b546a7c2fca5e91c1073a642094d6379ce02e46ca1e1',310218000,NULL,NULL,'ece3946cc4592eaa621b4a9e78f126801363422d7b98a3c94147ad3df82c402f','d26a11321fa0d48c31a6edc747bb37c34270dda62d872aa0bf25272e4933e2ac','e18b5fc99665a490beed1c92ef2d3068db7b113531caae5355a19b40a0804196');
INSERT INTO blocks VALUES(310219,'17cbc2da6b36886d537c8ed24a713f490784aabe27e5657d0204768cc54e63db12d85ceb7050e080200ad014d4150abe7c5c74142f3c1c21d53bd774b5343e08',310219000,NULL,NULL,'43e046f8ab72366a0d57c8210beae244ce38460747a94350e748703499258a5b','ee53ebd0ffe108910111b574f760a3e3ded3886aff964696a9310c521fc09149','88dd9186da42c896ba043c6f865434bdb16347d05c352941a91c7a827efbc7d2');
INSERT INTO blocks VALUES(310220,'7b20b32736c01aac271311bcc87f09166ddda5a2e639f159ec939d015d0d6331114aa2af76dad0c088ca917d4ee689d3a6b151e9aca0039cfd5798e65cf59123',310220000,NULL,NULL,'1ed3f5a4fc1133ad8472ffea3d58b0260225cfd0fff2dda34331e50cdbf24aed','511779b188f136f9733a4e826655322b5fe4abc913a73382a93eaeaaae741cf5','6e53f973acceff00c24ebf1ea5a4682a38456170aebe44b97cb29a07e6cc6577');
INSERT INTO blocks VALUES(310221,'2372d0adb62b755932693ea604b85e2ef86965ef740f1bbf6e226a1f2a9d03589d478f5309e1dea13de5265852f42bcaf2a532052bfb8ad8d34c85816da56983',310221000,NULL,NULL,'d40a27d961d97bbd6cb936b5b3b9cb7bae42642518c6c7277eeb8368e99f7105','59fde5b8de157a462ea0d7263e9395a9a869109617dfbe918c1bec5ae6383c50','089e0ba9a4ebe4b866c1372fd4cc7a29099c69309ccec94d65893d0f2a5f9420');
INSERT INTO blocks VALUES(310222,'f95edc9fe371af69326b4c9307e979e09e75c50e64133e32609675c711b28d2ac8ceeba2a0d0a9add615add1dae229610e0ce330c240d502f1daa10a5830f664',310222000,NULL,NULL,'dd12f43130c1d61f95a87cc2f27e0ff371369c8c6e21809dc463e301508bfa03','bf60260f120cad897a05cbb468b7fed4c51030b99d68870cf1eaca50309c99d4','db261f1836e58c436c949ea1441d91aad72a5909e01b1b033470c7322bb46bec');
INSERT INTO blocks VALUES(310223,'f3738a31552dae2252726d3a3bb654720752b8c9a73450104e25ad9f37a78cde5e570969863b7e026fcdbbc19ab731ce3627ae1bd5942aebda24f751bf53838c',310223000,NULL,NULL,'15bbe2f2e375ffacd6e6793f4b3c4d633afc45123382e1257c2b56ec0df2c627','7ebb60228d0d6040a9ada1e7e78a94cac3ca1417956e5fbdd5960dd70c83fbdf','2d72ac16b05542f7bae9e86cbdb9b89cb23244aa86a6f3bbba19bfdc17da2590');
INSERT INTO blocks VALUES(310224,'2df029abfe5ae4e19763b54a85b6a30afdf4d81e6a851c9092b5ad39228d63c43da52f494361beefaa89ea263715886150e387c2785c8bffac01b50c794394e5',310224000,NULL,NULL,'fdcc07cd83bb1161da89f2de8c2efec3e392a9d0dce1d6d96300d9e321c96065','60e8b895881c74920795a1db3f340a94d327437e4518e85b4f34ff4cd0afa95e','08023e1066156048c7b89b9f2ab257bb3cb31cd5da657f02bf7e1ae3b1602a35');
INSERT INTO blocks VALUES(310225,'2f1d3b02f51273ebb3b1f978cedf12171e60b68b4467c8a782e1812c836ff78f387aa5cc60f18c17fe69cf5acc8ecbd6f858a3de1ba0ba3f22bba112bbd512de',310225000,NULL,NULL,'ea59e37b093cfbc983b4b9ebda0a7831291b958609c3ba62d09c9b0f0520a1d7','725641d805da8e3c0fba12d4dedf9969736e2692b14c88e1d46697788831df8a','5e57e2e1990a2aae2ac93323fb93505c31dc7d992028dc4e932b0008a7994c42');
INSERT INTO blocks VALUES(310226,'1bd7bf5cdd75ff504e27576a94d0a60349c6d536fc9907e2b9d93878818c51f5d3966b50963933477c04003946df7bc38d9907ac077f11516133648d9b513f1c',310226000,NULL,NULL,'b54306f56fdb8ccbccd3df44d31c347b3de34ca3f805d62b3ed228a2181607ea','c974411a57440462a6db6f1c84fc6d21eea91efb84628dd6254371d724d611e5','ff1853a1823122711b4486b00152201eedaa4fbd768f1051cede4062cb251902');
INSERT INTO blocks VALUES(310227,'182587860a17a44392b7071876cf5f0d722ff68b97fc67529dba4c4cdc00ce27efab52dd90da13c988e94c97abca5086703f27a349a4a5270229ba522d6813b8',310227000,NULL,NULL,'1fd36f7f2fe817d1a44520e5e45af20f7ec377370b97becebd93317e43e88cc1','574b0047624f09c68a628594efa748c63c95d8abd41b7a2d5b189d37e4754fdf','30363455d1fcd57f36d9e8183b61d12bdcda0d9cf6302500909b2fdf81e6a118');
INSERT INTO blocks VALUES(310228,'ab47961393a0c8b3f86793e9a25f879f5200ab75f6fad587065e4f0b8ef3a51fd16f42dde4bbae0c250c967db4040a8470606404bea230c3d1f6dba4588af861',310228000,NULL,NULL,'f79faa6904ae01da682c01472d66cb74aa5a9731488795c701cd1e31506ebf48','bd43ee863d42f622dcc548254986e4a444589ecb80025a823271293679afcb92','4e125cecf14687574c387978303b19b55a88cbff72e7c6e8a39d506a28184831');
INSERT INTO blocks VALUES(310229,'922ddf34d83b9f4acc670e0b1c9cc2561950f20c3d5654e43198fbd11c86407fc41c934216e8714b519d2692f32b79c89c8be85c637f0136b8a462bd4f728ac1',310229000,NULL,NULL,'b40eb2dc7218da49c89be50790de513e1cae2d9968bc9f69a3f16d23b3b242b4','77f04a2134ac639f23e8380a9aa3abf5b72fb898a2403a8aaf415e7c5e7de948','8714d445926dd62c37d2bc6d9d9dcfe50e663a0344f0db6f20ab8dde477a04cd');
INSERT INTO blocks VALUES(310230,'08a1b604821ee7cbe963abc42c1dc8ce9273af94501537e7ef19e90cf504b61a80a99ec7952db4db85fd7832129d593126a1bc52b8ef30e6a52591b37e9413a0',310230000,NULL,NULL,'26da160618d6ad99a69541667c9d534cc038c6301c9606eb9bef0c4dd3c6b519','bc5399da95794fd6833977de566932de7063c64ebac1f97f977e5d1ea655a05a','738ffbb230f82e1f8a87696d0b0ded2453604e39bd72afcdd4b425cc56378f74');
INSERT INTO blocks VALUES(310231,'67ebe4bc3acab4936f1ced7bc5191928fe87d0713c27c58c56880368bf3efd48374eb223eef7d2f91fcc6a135a0a817185c464604d50780cf8c4a80f7a18d927',310231000,NULL,NULL,'258742372456c75715fd58fb0be4b3648e9833e719886e9d12151d4f5fa24040','ad8e29a07cb54848ddcfd68dd78ab79902634d48637adeaad94078a639b7f838','5e7b131fbbef95ea07c4c0774e122e2969c9f73ef714972febeb2a6f9019d8db');
INSERT INTO blocks VALUES(310232,'4b5c090aca519eb1296c14a778e317e464b49299241547340dcb808f0129e239cfb6469efab40c60a9c7eeb9aa02c341b953b69b324eb9d60ac0b6fbf1958000',310232000,NULL,NULL,'3229e891210a62408bf1e1bf0c7e1f80ef70a0a5aed224cb1371476fc410aca2','e8e90ee5ca87f0c47a9ad94664b70981ab97a8d1b1cc2e5f085bb3f33ddcb7bb','ae357efa6e706be3c7628f2b98c29aaf943b8f2c7fbcc742816aabd598fe7f74');
INSERT INTO blocks VALUES(310233,'bf2d86cfad06136613e4257547021208ae35e8d2613b9ecbfc5ad079f63a983f47d09741327180168cd1dc30dbc42c073df223786aee9d9fd1f2a158b83b696b',310233000,NULL,NULL,'7e7247480e77116cd9b8bf0537a1f7e096b2e98a93297ae9049555c07f8201a9','d460a7f754f9cfa6f3e4759845262db80aed1dfc9395265aa52c6e69a3decb84','4643305ed4664b7c412e86e1e06a1eed0f87e858c895e4276e1713fe5a1e1142');
INSERT INTO blocks VALUES(310234,'f136ca58bf14198246cbda783a439b2dd2524d51baf195630902a7b783be0286da4aebaab9c7073ee2b700b0fea21740a2d9842731a2018b357473190ac49969',310234000,NULL,NULL,'1c6bed14e9f00f7caee4a1e7781e7dfcfc94a3a301c55594631a55d4455e0c57','9d444311e1155db9f89cb9b27eb48b5eb82fbc3592351d0e5ba246392dfe8910','31c361636ba87b8e5325b9cb09396a32a9cd66efedd60ff8293677ebdbadbec4');
INSERT INTO blocks VALUES(310235,'74bcaf9b0288fd96e527194252a8ff070351fc002b732ce00f7f09b37e7a93792e257bf847d4df70a61d43dd7d577d0140d121c0e088d1bf92fa4d4c79180a41',310235000,NULL,NULL,'f93e43a85e0631e74fcdae0be5779eb4fb72ff9d26457106c85b0c83ba1dbd25','af512a8a424fc255faf9f06291ec4461f54b918270a1b1c7c0f0963128eaeff3','4249cd6494c48cf4b0b58ffeb4e0cfef8d9925f147b3880637520e60671c5fe9');
INSERT INTO blocks VALUES(310236,'d53cd57cca5e8d747b0c6a5d45eac66aaad1da1c9b3a93b12ac39d356ba2675c70fb00cd3c0e927fa08950c3d77034175daf5a550171a1ace7b3adb798e6c0ab',310236000,NULL,NULL,'f96581cb4c7a4974a8c5f3461984300a3400a26474d6b96e8b1c100d3db7e398','217da12b7c2e4724441b84d12bab916f02170495008e07d0ea4d3fdd4abd9b0e','e274a816073f39285c35e7f3135e190227b59877a7cd6fd29d75dc7731b2c341');
INSERT INTO blocks VALUES(310237,'4ed36172ec27d2c496e9eb816c65eb6846f87683b5fb444543f6ffafaf29a37ce441644c4e7f1a2bca673cfdf3df4581c88f1d7a140fba4bb6700cd4407f2aa8',310237000,NULL,NULL,'33a210a097a5f599e476e68f6a80133d6f89a47e5f23db0ad89ac6f01ff3bd3b','f5512b0008ac0cd28e14c7a955651ce5fb4a19f7be7b2b9c36138bdca53fa505','6c028a0e241aa6ba248ce0b0460f60a41673867bac90568250883a09c978e7bb');
INSERT INTO blocks VALUES(310238,'55f9a7790e1576c56242c2559cdb867260fca89c3b82fdd5ef239095be1b7756dfb09e47054f5ff561415377936f93b2f65ec6d4a70fea51a39b4a8e7268ab09',310238000,NULL,NULL,'3606de5c472b831b5294600c5faba354752915de37d968056776df8d162d185f','601ae6e536506bf7159adeae60038cdc6427eda39f177cf69c467997150a3387','53f08122a77929ecc920bd8929f8affb099a5a28e2d95ed4129ac30533a0a48b');
INSERT INTO blocks VALUES(310239,'6f3b9c52fe2462522690bf39312a5fe8a459c249cb3b843a752b252a96315f3523659ed40a96032137f599357f94d209a244debe80bdaaccab844225a134ef68',310239000,NULL,NULL,'ec68a1711acb6019cb460ef1473ce3674df4735cf1c186d0309b21ded6fc357b','4492495266e6198e5019ff01fcd96248f4f3a82955b14f3a001441407c805535','db1ec33ae3e9065310fd2a9c7d2170ef8c61ce27a32913df00c3b2a79809327c');
INSERT INTO blocks VALUES(310240,'6bbe056f8f605bd968aab01d94b6e2be82b2f7cc15e13a251bc9a82950bac50e709311e178b7535a8b35f8fb070fd2f1b62dd61c374e3760b1a12798ab7b4b43',310240000,NULL,NULL,'e96d9d2b8e995c7eced2f3b6a56ede041e1e98672f4bc324d87f581abc33062d','e59503288fdd3b45aa01413f85d8799d48085ce6a937d3736d2faf2d5dcbe37f','b180e7d932d332539377d376f245c6a305d6dcfd51663b0c97b6bebc80eb8672');
INSERT INTO blocks VALUES(310241,'bc3487d59c2e60184d7ec9f0725d8feaef0be333fafbbf57ffe11246dd2a93941904c81982223aabff1ef880c9b3df069080d4d2d1d2752c87c91ec12731f607',310241000,NULL,NULL,'930f13fc1b46a221fc407dd8b427a71a4b5dfcc2ae0cf95102d3a5a9b003f305','0772f3787427a1a974a30c3d4aa64dedc4063e428781d1d64fe826dccd7a16d1','54934fb2b40985473debae3a1143cad1ff3a94043f1c27a6d4b718deb3f1b151');
INSERT INTO blocks VALUES(310242,'f0ba89baf895b948dd31fa699904e3892581b8bb76a707fb966d42d51414f9a0a2ef6911d27c1ce923518f2d2a9f11818c311ea491ea840f0e8af5d7477f2bde',310242000,NULL,NULL,'182edd5d1b38b172606cf77139902a53a811f378fc6fee07849a891c4f735a0f','dfdfaecfa51d18114123dfe1eaf2ec47faca90983b2dd9aebe09602cca3d7dc2','ce4b72877aeae1822c59d591054a6106272f72bc5d35215c744e84be83d892a7');
INSERT INTO blocks VALUES(310243,'955811a1c33ac336f66727d94915d47d1c4d41b719336803209603ad7b710f15150e4b03cac6d615a10006e98e31040e7aba63f1c738fd334d991f49863e3227',310243000,NULL,NULL,'0175d0f10c24030f50787abce9a6c59f00abb2a60b1f96b79da5f314a1e56e91','d697391b5157de3c0cbb45288f3df2f1b571a2b7179103376d6d30762b5bbdf3','10abde1edc22cac8b0056298256965415d51faa601286de0047e3e35d8f01bb6');
INSERT INTO blocks VALUES(310244,'6cc52646a6c05bc90de8289a26c4c7c66f5eb60a5f779df14710fe40ccc4d2b1e862e2a340b5cff39774313fe31005f374e6cf061671a846d490a344db6e7b2c',310244000,NULL,NULL,'4057ca34486fc7db5e13da6b7a1ae9b52c5644cf5cffdb9bb83f0fb855077a4d','56122ab77b1161502941b7de9e6aff3866348f3a3540de2a5394c25a15ba1dcf','618ba6f6976d438e0af2d54cce5c7228afee5e66a7aab835fc19892c71fb755b');
INSERT INTO blocks VALUES(310245,'8ea22989a2a25de3c02b6bbbc3f91dc33d1736f54bd863e142fd9d6014947cba0c6b359c26fb2ab2fc74b5ea3c9cd7b1726784496cfe84eeb7bca76f49afa55e',310245000,NULL,NULL,'4783bb33a99c17519ad675c0a16698ccec658d6150510ca2407b3e6cfbd0c1c9','3aef15ce708545460f81a73fc514359ac5e0cf175cf0f29de12c13fa344a4386','64f8ab362d21dbe7548691c16bf4710ab8038f1b048a0ee454723cdfdafb471f');
INSERT INTO blocks VALUES(310246,'b0a724456a7dd399f9bed9381bd98e97b547b7a87bee766b4c357fc492f576213dec71320d67e12ae7fa36f9ffceefb8ac86ceb491a5ce60db97b85de9149e05',310246000,NULL,NULL,'e95b7ff1c7016e76016a042054f4b873c2ecd7e05cb8104b6518ddb5d28fff3f','cf4317c89a38d9ad7bb713cd310c9381e1fcf4eff841a40f2ed6b4805efaa7a6','fe854ad5b521e36378ecadba15af2230fd0cd80a0e97365c5a99df3aa944696e');
INSERT INTO blocks VALUES(310247,'26ae1dd58e1cf9ad6c79c6bc68f274fac5674d3747e027187d805f0e44276fd4f35fe820b02e1bd134fe614bbf7cba80c52df87349c1bf580cb45c75f6f0591f',310247000,NULL,NULL,'ff66b089db686295f017c9265bd0ca9d9bf179e23117b5cb81f541b89632ec2f','f957599cd217bea344ef4b962b62e884d1db7732417d9cfbe6780f882ac81eef','185bc05b8d2590213790da550c4c072d71b3f1ccd776aed1263b772a200b7a0c');
INSERT INTO blocks VALUES(310248,'9e5b5d0e1037fa3a3200cc7f5f0e271d838b475098df768cd25c944a400543762f8302fc0f1c88c67293c6836c394a9b6f32508d6f18c9f01dd7404fe5cb32af',310248000,NULL,NULL,'437ca35a0f136a546c0fe0baa5c3ceac9a35c37b0b1001f24567ec36ad3df74d','68de58943ff06511e3061acd88f3d21416547a79dd5a19f041d23b57538b51c0','3b88c7ed6974d900feecf62f29121fda6ae8f5c61058355defd356a56c6e34e0');
INSERT INTO blocks VALUES(310249,'d97148dcc24a8c83c7421819c5606b86e3c44447a1be95dd476bf7eea92407d77e61700961d3d7c807f433264d2494294db860ac6cf5488bc91e35807fb7804a',310249000,NULL,NULL,'09c6219087ac545a6c706ed76d0ba5dab18a1b54bd5d4a4c5241fbbd4d508f60','cdae51c9673ae09bd6c1420b0134ff2097fe1c154408589a4dad8cb75aeaa627','8b6637de51ee21dbc8b93ef3c9e922e7c31d3dbed0cf729c8dc97f25d8e40507');
INSERT INTO blocks VALUES(310250,'3218c6bfa75b8c8df54b58e4c0553a4bea06879676a057d7b6504460a8cb2b4edc9847f39a039ce5d0f66fabd057ecffe8d64232e4e8eb9a57f75363d5b0a7df',310250000,NULL,NULL,'a60f5f5d99cda30fd1b4f074581886a81f16b2d71668e02a14448912c97577e1','af144c96a1777cbc75e5d8ff7f1658a42ce20a961a7e78507c7794ca73be1606','a4900f1203ba1d6a050621cc2855e9c32b5fbeb18230d69c3c42a610edab1345');
INSERT INTO blocks VALUES(310251,'46010924ea340c67922d408342cd922d8094a24c6ab72179dfe1bc23fe8ad68faca91a05aed2d511757928fac92c2f30149d4469e6624a9ba7dfac76c9df2239',310251000,NULL,NULL,'1184e3088447515125577247f56e76dfe7a5acbf8e5b83707fb0979c59fdeebe','4c2ee79a8b0579ffee69bbcafaa029aef0260217c63c4a2bb3423289686581ce','ad6a59bb5f6847ba637b4557be4e9bb826b1f63d31cc103c2c68f61f6016b1f7');
INSERT INTO blocks VALUES(310252,'88c50d377c25aa2ea34c0c3245777abf590ac77cd651210d8f31f2b30262918852f37c97b41c9168e397f1ea3e7162f506b5186c03f715fde36a9c2218bec173',310252000,NULL,NULL,'7958f4fdbc92022ee93a4c51c80740a58c4a3154bcd29fd47afdb5481e89ed2b','d28756cf85e7aaa530c6fb3f9fbdea6a0a342137bf92ed29379d120c00bea7f6','9df7911cffb16a63739181b9917206ad85c3fad9d6d9325a555430288f49f2de');
INSERT INTO blocks VALUES(310253,'73b2496752d1bb6b927cc2069ef7d9004440fc9492012ecb8b71a50b58e43b92b6d3994a2e9d726292b62e43eaea092b023fd4b770f3fa59afb3187c85c131d9',310253000,NULL,NULL,'35658d25e987878d476dc10a3cc22cefbe51dda0f2db19d665bdd0c8a6c4677a','98044c6964b891ded1fb2f3f5c115737f806a30907623cee355017515996b9bc','77e9911363deb8b506137347231990b38c6724e26fbcbcf30b975f3dabeb8fe3');
INSERT INTO blocks VALUES(310254,'270bd129114e55c6c6b601c2451ce5a7747e1f3039223580a32190a5fd95badb75b25f619791d084d9c8a2efa80e4247cdf3dcc9caa19f2b3dc761d73436e83d',310254000,NULL,NULL,'8bbd126421ea1b8efa454759a20c462f8878cfb0381dc4e7d08335dde626c960','871c79ad66e5689bf5192c11f4a99f43932ce9f947f5f1ec7ec77eddffaeb49e','635b94ee5df8418180b22647db74b108ec697fa25ae05cd968ca0519a2f2f80e');
INSERT INTO blocks VALUES(310255,'a15afb7fdcb15cbf453184be9cc3190be765ac149f6ad7ac967ba60cc21ba09df24cac96ae343361b262fe7b9a39cd76fffaba7a2c08bae7a7bd15d501ec225d',310255000,NULL,NULL,'49c62e5e793199570c728f9e8200c7de7e3e41394f170a8efbac4ae51df076ae','354a0a16628d3e50adc3839ee65f58484324a2c5697e0f2b21a20f122dc2d3c7','8ccb6f8216d77f3ee8a3f5b42166c40ec601a093a5b38b125e6bfe14fb1681c9');
INSERT INTO blocks VALUES(310256,'7bcf35ff91943eb983e9f7f65ad5de5b6c07959e3858617b79cb791658f0acb13c0c29fc29d333e6094c0c1cbaf73ad32ecd5fa85602e4e25ab8ad785473ba83',310256000,NULL,NULL,'65d869f1cead6d70b2f305f2291c9cb1250cc9c659107d865cb5e05dac2911c5','284375d9d61a09c9f6ad7c06c5c6ff6874775409969e933ee7025e46ebbb0c0f','4f7f9e14981bcebab1c6a27317000ac7f33bb4006daa62e717916d8890fb6a8e');
INSERT INTO blocks VALUES(310257,'f5e3467145f08e361d51dcc095569f28e189ee9be38b5eb0bf200b28a833e455a3de484211dc2517a17853399e5c471279cbbbddf75d2d28ab952ba3ce71d882',310257000,NULL,NULL,'0219d21421a6e981fd97c3b60b376518888433e68c35f3c9f4c7a4695f2fadf2','4e45d9d0ad06a9a6053b3c754bdd39b3371a5829b0106f309216b5efac458075','8b4b292962a347b5b70a21b5ca866f1fc5c1e188e4f4485798f701b68b7285e4');
INSERT INTO blocks VALUES(310258,'818e2679cf7bee8ea493eb9d043f9b169f99648b23731ecd362ac7aacccb1da8614c1e031f24389139ec174d7d6258a9f0334b0d17c1e2bcc9a46eda665b7267',310258000,NULL,NULL,'35862b884c6cbcb58ae164fabbeae5d84bd4723a3e03fa4c856fa18507f9a16c','c19b724c6e4806fd2eb6d7d50e1943cd0c8ba8c359cbd79a929b739f88bc508f','72835ed4250062466366a91583e7ed54d0bd344181fc20c4a25482b3d2f13380');
INSERT INTO blocks VALUES(310259,'8fc5d3af60bd9fb172f605d0c03ccfb5c154abca814f7dc2f0b594f5f418c110e525d3392c1d59104988c377e3e92c3d0a2ddb67f6cd06de5d78050889a63595',310259000,NULL,NULL,'ab8dcf49658e7313fe4b5fd61d586140dc216617f6d6addd080c7738c8bb6742','f787eae47a0a4de90f4afe4d2c80b37e4330926cfc7d71e9b5cef34d9d53787e','6bb37bfee998d0209e1ae32e784f961bb6c68f59b0e7fb36114272fc626ac6f0');
INSERT INTO blocks VALUES(310260,'bbacf422d763e74663cddea4aef9cf7bdbb74d456961182e04814e76dd6c57d768c12fb65b8decb364d2463aeefae9f8afb87b99b99b8c076dda14a5a5e7e7b7',310260000,NULL,NULL,'10a141940ca8a26eba65dcd52610aaf9c37cfd93c0164362be4967587c92402e','b15f573a7c7f92cb4f0ce24c918f536951ea96ab5f9dd9289b60b357f9da7c0d','34c332a2291337180bacfc59fd55fe4c98b5b27e732f8100ebca572adff8a3bd');
INSERT INTO blocks VALUES(310261,'b38e530ac6aada95885f3bb1aab84dbf151173d2194af388db751975f4e9ee4c7c3da2677a8dcfb98eab4da72760785ae5c404a6a6c1f61ab8e759b9ca6dd12a',310261000,NULL,NULL,'4cce3a62b5dec179db066aa4bb08fa220c2dad254f9d3f300a1270afb02ca3c4','f31e6373d51afa724954c8cfc9f6576ee0e99d8250b22f2a273c15d8d7becfbd','81bc44d934e49259ead9caf7757614b03d0c724f01a47d14d3a9e7b3239b8bfc');
INSERT INTO blocks VALUES(310262,'329a9a235bb3084b2f8899d39a12e3a1916faed8aa28a2df7b7aca72c89903d3a8d697a58ed6488ae5a2f029d650acef7ab0f091095d62ce1cfb6b4b32aa23d4',310262000,NULL,NULL,'ce621290435059489ad2e8cf8f7370c0e0f4d166ad85585de5b22c9b561f86aa','100254b3c1443133186c95bb4a24502eeaa4b0ef6a76e0dd3ef09d9ced7924b0','11eaf89dbba780842cf0435498cc849e964582ad6b60db34a0c5c4aa5900d15f');
INSERT INTO blocks VALUES(310263,'43cee48f0e0d9852ee3b828eac3f6bc14428cb57fbb8348db963c21b7427eb03aeac1462650a80c97eeb74654e9773c9b789ad9a12b88f62da06a77821410174',310263000,NULL,NULL,'32493ca0355985eaf9a1f6c991e6f9c297ba66bcb366ba47d0b0daf1f4774ee2','69efb3be92eb06f591662ce86b859a28ba987b8f5816ffc58cfca3986010c48b','7b07e5e3fa7fce6b495e2b512bf7e6bfa192d1b21d1b1dd18b720a329fbb8c04');
INSERT INTO blocks VALUES(310264,'be354373852f06ac45faa0e3650eb6f9afaa836c224c7737d81bcf5f79786dd3eb775bf8980078b89ad81003dc9b261afdf0c2152e6d8de4e285c2962b384cb0',310264000,NULL,NULL,'629babed71c01de679890ececa138c3f3b9dee8084db1842a94f5ab436ca843e','532297b46f2cdf12a7deb779f963393cf51081da1d5a328cc3dd4141175c53f4','32198653af30dc06cd29f6783c72fb0e33a6a61d473d38055fcae1ce364d793c');
INSERT INTO blocks VALUES(310265,'6d967f14cb8425c0396d58de9aaf681a337fdbd4ace6a33a32f9c5523360c119962a868832e264f24ffbed3cf8172982f876abebb2908faeb46352b9263f97cf',310265000,NULL,NULL,'5f792949854ac9167ba81d40101e4188a8aa52572d8dd22f0757938e3010f84e','0eb5b39f65305f8c5bf188dce02386cd93dbb2e7db782eaa8817930ece5727a8','96f23fcb2aa945b88436e197168a91907ffb77a1141e51b879889f0affe16c74');
INSERT INTO blocks VALUES(310266,'4e350363a67c4de925636f42e82623183e13432dd41a0169a0a48f3e5ec330a809a75d6e6bba3b5468d3fbefd1636815e6ee37086770d0a317acec3498c99213',310266000,NULL,NULL,'a0744228401fd6ffb07c95283bc5a36fdf0dce2d8af4a49e3ac8ea7ffe2a66be','e4c4b9007ede120cfe4dcdc53bad3c18056769bcfa19d34b2480c238c0d622c7','1870cfa3e66c970569aeed11bcd7755bf09d65651001ae7a8c87ed4154268480');
INSERT INTO blocks VALUES(310267,'578d02e8840ddd4cb36a8e7e32fe9424e7dfb027a8320b63d2ef57b682368af5748cf901aa2f5b0f4c2ea5981bbfa8fe1ea7dc2865590256af92f20da7a14d9f',310267000,NULL,NULL,'566847ce270b2826e73cd392d4f6b84f7b82225491769b8805138a366ac5b822','5001d5f149e826fb034cabc69fe060a809006f92ac29a8e4b84418bb571075f5','8fc0cdc7f7cf6d9b232ab8e9402b5c046ef1ee94c76c8e79260a63499952dc83');
INSERT INTO blocks VALUES(310268,'ac55ff8b1c52daf132aad739c9ba8171cb224f0f97db6e449d13a40e59e7c99fef6451ab6fb88994024cfa8d12038eb60ec026f26e470b72d8988e3d7e82c0ca',310268000,NULL,NULL,'4421557fd4a79dfd846c8a82abb6a04ff824de564095147d627d4573b60c249c','49fa5415d3fc9705a399e3f3bb28e8e815d474f2b2215cb5b70ece1737c2fb53','fd6677c1f72ed34d82ff55fa6b8ac2aa2fd4b318f77d93f63916e29605f2bc56');
INSERT INTO blocks VALUES(310269,'b6bbcfdd4921a7996cbb23215ea7b7ab4a9a2e113d764ccbe918c7fab37993328304f5ec154b98f2d82f6d310ab48227143dc4e81c50802c02e0f34f97b425e6',310269000,NULL,NULL,'b7b70373b1a5e7161233a53b72ab3fb5fe3028c7d893810242ed3866f0a5aabe','8d1985456f2adb94545562f80334a9e51bc40e8f7d5648c4d20ee8096e531a6e','289044dc6560ef6adb7cb49c49f0b8ccafd0c6b26ce0e358eb4c2f1a478d2171');
INSERT INTO blocks VALUES(310270,'0b120e8e68a0636ce794708b4d5196869c8d3da2635731d97c79bd5a5eb4badbac8348cbe34941a424b923cecc0a493d1e69002e75724a700a82a9e93af7526a',310270000,NULL,NULL,'0aaf95aa71244cd26f0f7fdcdf1362b2191a1ea477c4af767c64e46ae01d034d','50a791b328fbff7ec14f39def915ee7df6bf39d3e991e797f8df0abe55c5d39d','6fa32bf6545720c7a02e6c006a51fb917510e56aff889453b124d20bd521e88f');
INSERT INTO blocks VALUES(310271,'d77c39d4ed0f1859bd78d5edec895dc30421471d55f306a1e98ba5d05e1e4b9182e0b5ab3cc3b398763d92051664ef21c542548e6d7adf5cfba4d5778ade6d45',310271000,NULL,NULL,'e1a3f61c70a63d21372d6a67eed6c3c1359ab6bef66e6837cc3311f95e2bb0b3','647d4824139971b327ca21d3bb6dcc3d256c1f189492dd1b2e2ca610989f8287','4e39612a86b743b5afc44f911199444a3301139887406b07f506205490b71575');
INSERT INTO blocks VALUES(310272,'054faab4b88bad25e7e1fea77551755a598b487ccc231a81a0ad9336fe09501c2f6424bccfb7c3247157d580fb7ff00fc484ec4c2688e377a1c20c99652ec677',310272000,NULL,NULL,'9c7e82ebf8133530cf5973dd38a66644f98456283685f961a81f9014fa43ede3','f19c5d33158753410815472690b4a8b72283b01a1ec0d177a6702f45016ea106','cfd458506c83dfabe0a05c71276c2414cf8c65a359f29fcf9582f143df1f8c60');
INSERT INTO blocks VALUES(310273,'a171bb8d6586c3aef696cfe9fd9e48ddcbc658744a8097edeffbef5f40f98d8298d7edb2f70cc47adb3b6e492babdad1ea4dea67a717e8817a3c37c8ca0461a2',310273000,NULL,NULL,'2c82340afe5212379ae020e699561e66ddc8500e7dd3637fd17f41fa6586ed56','a368975af923cf075ff62881c471f1d3941d8afcee706c027e521e1d8feb1298','8757150b8c0d62784bbf3edd83b84cd1e710b862a8911ea9b6d5a9a8fec9ec1c');
INSERT INTO blocks VALUES(310274,'73b557dca209f386ea939ac0a9d98e0b876980773a7444be789fda03ae6c3ef9c50acc34639639ed6acdcf37e9cc1056d074edcdf058823338191c8ceab4ea21',310274000,NULL,NULL,'b8cd24cea71526b2ca4e9f662cad4f0e97137b66c6d7aef2ae2f88577ae7f5ec','4e398ba742c401e47ef2819f70703cc3e80218ce20e0b2836fda2527959ad585','f5cdaf57ad44f3fd24e1df9efb641c62a73e8e5a1f730b51a72bf340c310a389');
INSERT INTO blocks VALUES(310275,'86cfd8be8a981a153d5ba5cf3558b28dfc3f9d260d9a652bc5a07c7588d33af90c6bca26c708de6d66da96f758d948e7c218418a323dcf12c50f2ae30ffddeeb',310275000,NULL,NULL,'1f20895988731cfdf6cfee6b48c4d818e9d92de4b499d64ac0d544cd697f75f9','efaf2eeab197af21fb1b604523ed0a38c39771cce8e1527bfec1fa39dee7cc53','084be1bd1ab41ac2e0da9e0bcbbd826357d2976a8a91c2586d11ead6866634e1');
INSERT INTO blocks VALUES(310276,'826cce42a9d98206e34cb23fd88de3a762e4efb646bfc2b3a6b4a65083dc3ccf3048311bd14f82cb41135c6c3201355e402d6f900ca2e8074e74c1bf0fad626e',310276000,NULL,NULL,'db1b7c53bac38ac84debcc5e5323bfc5e963ba08cb2552fdf3bee85df53e825e','9df790e7e3e655b324d6c90162d15cd67599f617a2f3fb0fe236a5381b33da36','9086c6e7976b80305832949a9cfdf76e3f8fb14e1e0d4b708e9504e2a6032fc0');
INSERT INTO blocks VALUES(310277,'02add916255878e70769652c6484317acfa5821ab020b71919b0d8ec04fcedd8a1c63b9e8db069eee33865d88d39ad312d100f6d923cbe8cd73bc512a3725491',310277000,NULL,NULL,'5880c35722b508c937733c42c671742ea7dc5dcbaa3a2b62f7ff56fcf998ad61','f28463cafb5f041c5752fae8159f30df1d41b7f373a079bd552c7d7481a4f8f6','83bcc3642912eeaf30e6f672c8e75fa9439829f49f41be84ff4988493b554003');
INSERT INTO blocks VALUES(310278,'467e9bcdcb93dc76a0aaee92ff7fd9a9a490acb90fa3b2e6b92183dd2d7880e8375b6d1114d96677642b6c7787f1fd6987a71fc2607c0b1e86b3a9d3f32bb761',310278000,NULL,NULL,'d0cd0346c31811775eff9a399a12e8816ee4233c0ad778435585b6d14782e2ea','734db4a2d2fca8530912b477e9fe2d4367ff1568418e48137df4f667b4de3d89','13059a1ba551b4b20aa794cb45ed8aa89e8d6b290fbe174b0a50aea8c394db03');
INSERT INTO blocks VALUES(310279,'220b0e071375f422d443725458be76bf1d2547e07b70dad68ce98f16654ff5c0cc28da1101aab72203df390ed67bb63599df1b730190f58258fd5f172236e36e',310279000,NULL,NULL,'a7e3e88d12c5a576601bd2b846f754640fb8e0d94ac8e9fd20c2313c3848c8e0','0d47efec8ba2b5633b0805511b7808cb362deffca530c4d41b9c12276c928c2a','2e3529c6a7b79c18076565dc338543bf7d09704791557eaa6e5866c99d75b277');
INSERT INTO blocks VALUES(310280,'afea20e259ff60c16506213fa23f6a5847006ee596a36631e6ef71ed53bb226002822ea5e284ffc526b25f51dedcdd62e645aa9d19e59c7644cd996c50c0764c',310280000,NULL,NULL,'176854afa4d5935b7db4959f304cc9fd83505c8e3b3701e8160cf573faaea391','376f23986339b518b01eb451c0490bc9d27ffccd709592eb31016a0026ba877e','9efc02182be1fc8ea3a05c4bb7db7f75bf3de0f2cc41375c376ade2f5cb89e26');
INSERT INTO blocks VALUES(310281,'5566dd842f5804cd5ab2449032bbd1957a8faca05005ce257a1b4faf9065d9aeaaee29245f2689ecb521801b316959b0ec164ed36cd61c368ddaa8f906bafc42',310281000,NULL,NULL,'958447a7f63a86c7886c2110a6a71c93acfdfd76aabcf9990a241be32bc1099a','403a01240cf96a9b4a79daf6a56bab407f074eabe520d3d69b72a51f22539f45','f8849f477e6430529fc9b0e71e61b0f131f6a41590c13432cf746701901728da');
INSERT INTO blocks VALUES(310282,'c7db06d41663e0575d55683a2209f9682a97f4a089393581821cd7a986667a30675162782c61c731b611facfdce51d7dc561d0d0e486932560f0e2a799f8d411',310282000,NULL,NULL,'1025a782b34092c1e6841249c10051d928fdf6bb5dc82d4951f4bb56b9f511b8','d9ca3186f013e7c0128e85888604b98459e6f54eb97a79872672b11375ee848d','decef01a3cbd16b335e4170355f5ed4a6e17087bf04b7b0c7daef7eebd1b31a1');
INSERT INTO blocks VALUES(310283,'6e856dfa84f3539d85735c94ae99b764db91b44b6999503b42819e40b25bcffcc6c9985999618af8c55ee1589ac50030830abf8a65bba9642d0637813a5ec7bd',310283000,NULL,NULL,'d5f31bc845cd2682c05cd3e47cc56393a92a588ee926925e6470fd3823b59a87','0fb0db721b79415069e3115ffcf247e508cd621b2a6f718d9c37c976a55212f4','7ee22eded124c67645b426c95ee66bdb37e452e1d068f9ba0441531477bcdc73');
INSERT INTO blocks VALUES(310284,'fe98f7af8ab0181da5d10499189d8757c75c69736169729972d061022656a03b79df21666abd106a6b62a52c96f061a49eaacc2b15f7ec7ba392e2e1d46742be',310284000,NULL,NULL,'2e975e588eda94f9c74630e9b487b2b3e45b63d380a97e0159caff25a1d2583a','6d82731a2c99f42b409af12c5fa8db943a369524a42b8109005cd29d0c6acc17','b7d52b6474270f302321def3195a979144b92ce00f66d8bf6193bab0130a3652');
INSERT INTO blocks VALUES(310285,'7a9695623926cff36e00a90465d0c727c155d3cd7c8bc28ab4b5930bdc841743c9a8e9e5e36ba0f0bf915b5722306b9d7ff53a93720bde94efeb8ae2ef42593e',310285000,NULL,NULL,'546d2ef0b0c48f198320d7502cdaedc6ed99f3995a5675859315c18af7e5b974','865c578067adc109852212a6186c68944ddf091235b392b25d997f5667a4274e','bf7386b7f59ab74f4ebff613b136151bc69a45f6bd13b9b4fd2d44506c38687a');
INSERT INTO blocks VALUES(310286,'2624ae522f1100520fb3dc295edfcae32e82f3e6b9db20d37949f26eba5d78bc94cd8d13624a0a87e045e963415aa2c7db7e243cf1f7beaa4a998501b02fab21',310286000,NULL,NULL,'14026939a69ba9891bf3182af62b595d69d5ca2429a756c4a02704a569892fc4','36b62021c9d29ef6e4b60f932c5894d816ff165766baa98d7002a4f4f6ba69a0','b8710498a59d1f9e055f2560eee2e8740fbdabbddd523c42129896826685a698');
INSERT INTO blocks VALUES(310287,'9214a0d94987dadff791b0558d5c16b9c9165d9bde2954d6e8d235ba3069726be601283d34061f818f130f46e94fa786c4d422a83a539c811d915220fad3dafa',310287000,NULL,NULL,'8e62e11e98045bf993985314619a39bbba33344c7064e2e0586e1c4c97eca996','8a4a557901771a60a6aefee5fad90a8f1f1ef5dcf027c5e0dfa26585bc71d341','6e1f04ba1fa0c8f7809c6bd6e0caddd3d3648814d4f3f7927431f09a746d9c96');
INSERT INTO blocks VALUES(310288,'a4d7a0e721a4a7ab788f26845026d5de724d036ef9023745415f8b93214c7bcb47562d18a7bad38e121513093675fe36673d156293f3fc5627af25a70c69d161',310288000,NULL,NULL,'3ceae60a8746bba071804327b59039f4e05dc8a93efb0488bb0f63723752e608','7b364546f45426f881f00991e22bf78162d8ea51f9a05e24c2c08970c88ed25c','ae85513128cdab0bd06b878c67d9e822a6305e98c58ffc5e9e72029d699a5a11');
INSERT INTO blocks VALUES(310289,'6f959963ac7d132fa919eda3c2e485b9447723b048675bd38e0107ab57295a5a0af1d97c1310d4f527690a5919e77d4bedc3ea45ed51974ca7072a31d5166610',310289000,NULL,NULL,'9c39bdb94c83336f0621ef31de2ee0b1c1fe7dc9e3b8f55c7a462cb1b9cbf85d','bce3b84b9c1a03eb6ef62fa09be46ae654e66877f61b1d0cbaeecbfb35d9b8e8','504854b3f55614e908c77fb23da0f04144c7eff46a22756752465406e8993ddd');
INSERT INTO blocks VALUES(310290,'6a3ba0d21e789f852b724811d69a5d89024ec6854b7b75cbbb7c6dd9ea2c4fbc5a3437fb76a01b4d20545bcdd4ad06a2285ba1bfa5099aa6fd0a877a413dedb8',310290000,NULL,NULL,'353ecb23317d063d38c991f59c6d251ccc125772b337731e1c920fabb4c7ef4e','0c2d7dc6256de1d3f57cf985a63a89e88d16815e8bc082ee0657d0dbe429106a','7b24dbc01842104674cf0fbfd583f262e5bdada3a4940882b1aa8419086380be');
INSERT INTO blocks VALUES(310291,'1ce62e1e518527fdd1b698ac4b42cc6712d539c55a748b2d37b1f942c013b90077abc059f6b78650e3834ce9ffb14cfe9a3e6f42ccfe1eff6f170390940c925d',310291000,NULL,NULL,'abb9ae3b7898b06a04e32b6afed2d73969d8695bf5edc8f1f4ffc5c3305fc265','1407eaaedddc66d52ed3f1ca08edafbe6e54592dd8e3c8cc9540120abdb251bd','07d1b56240fe5e65190c0df3caac73ae94bade535ff69dc7a06fafaa0ae04e11');
INSERT INTO blocks VALUES(310292,'4073408de52fea7571ff4d12b63503805d67cf130f794659fbed6342b0dd8f53c2822e320db58fc45dc54bf0e8010c9dd24c62d38052c2cf8cf8c2411e86177b',310292000,NULL,NULL,'4a835540235710ce8332553b36ccc2660641ecc77c0ef3544556b5a245432c22','213ca4e0d0eb9d3b1f374f10c5f354ceb369a9fc8b16250e8eb8f95d609aa5c7','b48ae26806cde1e209b8fa60b8a34ce9fab4a8f8af463e08f18c9ad04e577b66');
INSERT INTO blocks VALUES(310293,'003486f9100cfb991b673a59380125d9536c5242eecaa36dd1ff339e96c26d4856c8acd845e478c7fc1139c9f177baffd6502ed7247000d944ccd05ab6048811',310293000,NULL,NULL,'0d48561327963e3289cb014bc8bd3e31b67830fa17af5207bf51c6a972baf13e','226abfd242d387d4ab4678f96eaf4d905c633be1bba450093e3e73f5ede02d7b','f23f7465d77be1046f16030dec3f65ab499fef51c2aa6b0dfbe11758cfb1196c');
INSERT INTO blocks VALUES(310294,'b2b303fa6d9a561c08511745e8a0c1d31b7774d93d9f79773622c40ecb0b8617e55bd9fcf663c21c598567597327b4bb7af66b4de6bc924d5b168777e4f7c626',310294000,NULL,NULL,'e57fdc0d4546e43423291b1c24a53ad1f99ef7b8f081b209d23670324e2531fd','e546fce20e02ff3ebc372489dad7fab2b8d460bca0e5918594d45f94cb674251','0ac56f1fff088d81804a5d291bdba4218dcb663c4ea52e8c970b41397ead2897');
INSERT INTO blocks VALUES(310295,'4f8623f4cbdd3d19c8c104468f4446b9a2740e2edd8ca76b824eed95bcb98037a4d2b8b10dd46b57e4c0ab4e6f463d8a2c21d51b87096ddcbee70413eabe6c23',310295000,NULL,NULL,'0bb2c6bba3f1f3f6232120ccbe990d7018541b961ccd6f166d74abbaf01cf241','3090746437bbe3fd1e8dad314ebafc614ed72735837f0793259acc85a87b95d7','50e2e31a27c61dc3eb48431cb8f1fee28a707e80c9bcd43b9d8fad7bd55c1b9c');
INSERT INTO blocks VALUES(310296,'6dd021fe0c238c4a9cbad9f27b1fe6f24239c9857542d4d4829d6658a472d0066b622ed36e5bcf85a50eb028805cdea878797633bc89434080e974b370d2515d',310296000,NULL,NULL,'b96fd45d76b04aaddd912181102ca3330c7dc932c81cea47347003037ed3bd61','30c098710862215f1bad56077235ad9b9a4aaf9892b07575f20d9eaf0c17b034','3d16e0b2d2508510ea3207c36afd183aded4224a3ff8786ece3ff5d5aed5e523');
INSERT INTO blocks VALUES(310297,'3925f11e402b0e127d943c5703b3db99bf2c1ca4e7877fe578f42c38b92a13ec115f911b732ee5edc5ae9d80c7690e4ec9b254468e3a2d438c722dfee4bca75e',310297000,NULL,NULL,'f62c6ea55816dda1d0b623e815f65f64128fd1657636693b6237673fdee6fc8c','16107a4b4d95760399a12447e58fbef2a001a2dac6a7940fcc1d15a22870fcd8','0a0cb84b4e80b2b8c581332f9ec1733bc69f5b5b3f0efdf9bbc4ca509cb7ca14');
INSERT INTO blocks VALUES(310298,'5d32d690b68831edc24bcff96f1b6129a22b3b977a1fc4775cfd038a76a812bc0b0d41ec58be6f7df61043128d0346179004b11a0e5b4b979efc5babf699e102',310298000,NULL,NULL,'4d86f761899d6de42a19a05715411b86d356101820dfa895eea322eda2aeff01','861acf47de2a3fd5e17144ac30686c9c8ede27ac6266142b275c7d8be15fbd33','e83ae7168699d5bc52a363855bb25352f622c5e36fca9a6381dbc1efedec08c5');
INSERT INTO blocks VALUES(310299,'1f5018a44c7217b036e1f5efa7c12fb3145989bf61c9b0b0cf0ac8141ac676d2f1c5b8c2c40578c90cd5a6ea218c55a71775e8c52b81d98786606754fd4a130e',310299000,NULL,NULL,'97baf7fb00b6b113ef17d0c2bf90d64ba9d2e8979292ebdad8ba3b3a0572d685','b69cd01c1d54f47e7cda1ec9179e136376caf7808ac68bc9eeba3ebd7a627570','ae91d0a82ff148b7c5fedfe04400b186cea0e7dcfbe7e0d67e88e6c9b5dba79f');
INSERT INTO blocks VALUES(310300,'bbb7d684bb01cf40cf1bd412676278f0fb99c2d85b89de148e8958513a121519f54ded1b032190176324cfc89e4a59723c94ddecd8cf12c8a0480a49a2461f99',310300000,NULL,NULL,'8f04048330d845e28ec76794c77142e375c48a24cc92c36691e23b17f18942e2','306a71cfbe953ef0bf3e39292d037c99d44533b74359f1d0c8dd39396276ab3f','d68fcb39552eef938a3ed520e0503396c3beb6ed98d510536f30c788f27a3623');
INSERT INTO blocks VALUES(310301,'92a853ea11ef50c188fa6009d019f8cea56d19f636c9118fcf8b24b98f9aef68fbe37a1ee00e39b3ae20204fd189180e1227279847925edd736de60d1cc44310',310301000,NULL,NULL,'5c7465a387d59e6b36c2d4d898c2a9af14935576d5e1e49aab644f6c47f63e2e','2228d901656f076517a8679451622a2ff435bd1a60ae2be82f0fddec058ac8ef','d8adb6cfba36e7b04a392bee022cc27923bd7dc59110c57f1b3b3eb15e874e44');
INSERT INTO blocks VALUES(310302,'87a23b0e57a3eb9cb2e2dae0c2215756b7e59d3e845a95d58ab216b3feb01d7474a3258dedffdfba55b84fd4c7a686879f24a99a24cf981fe14a0bf5571d63a6',310302000,NULL,NULL,'d04df48c93f1a8b3404fa4b0e5e57e2bb5ca82dbe5edbf387b549e54931ffba4','837c4d1e0b5f6ecea737d4db0755c9400f8eb4006c4ffa1d80531be2260b2d5e','2505ab3e65106751643bc782d7cff8417e89196fc0500d013974071c9aa1a2eb');
INSERT INTO blocks VALUES(310303,'0a2826fddd606c82bb20943be515f94e78f75fd316b78daeeb0ce17f4fe8459dc4e191ebdb2ecf6367f64f07f8f9ddb1390198f5233203df06225767151834a4',310303000,NULL,NULL,'f030950bb4537423aa80b427cffb38760b063a7a93cd76ded4691b69519c777d','03c09adeb92e074ff88fda0da2135448a9388197677b9f9542132483d7deee70','a26a7c7562fc8cae929bbd9830a5d4ed986cc7c8aba66b9d720782ca0dde9f53');
INSERT INTO blocks VALUES(310304,'21dafb9130b529fd2ba53c761f1636bf89a97dfddfd333e60260062e5112bc0e326f015e6a82e2d7cdc743752349bfa2cc5fafd914a65c09c74451ec79b17ad1',310304000,NULL,NULL,'a072dc20ae2822cf605325a2edfb9327a21ca88ad0d53d1999c95f114bee0fa2','2157d40d22f8e8b36fba5be9fd56054c4a1aee1fa08cd584e7c16c46722b9aa4','85f090d3aeb8fabb3c93542a0dc89d73094ceef83c449375db248e3c0ea53ce1');
INSERT INTO blocks VALUES(310305,'d9cb2851ce7293829a5c4461a4c1fcd4bbab46012b449224f21e10d64fc7bde8d8f09847c236f2edcc7d8054e8b0672727de121fcfec1022eb1cac832a252f26',310305000,NULL,NULL,'341fe1d12fa9a0d95ee6d11584d712cca0a5fac538495d3d1c9eb97f00035399','15f95844a9d6eb86fd2987d75cfdce46487805b71c973ba8550f3f8ec7d47d9f','86589daf82ff9a5e296380783b463c4badaac61d4093b4cf8a6a58e176392513');
INSERT INTO blocks VALUES(310306,'58cd7308a7f9938dee45f72fb9a559fb9c6b1a4937d08df694dceff41b2ff2eaa3a1d58677a1c000002f13e4e9842233ff99d035e1bd2d11b986923ec70e96f1',310306000,NULL,NULL,'a69f93568718fdd561734f3edc1bd4ef0eabfabe4ab14c2bfebbf48c48f74fea','824ce9d2ebc46010bbe359086f9f96e545689048ebb711432d3607081900af4b','e43dda233cc237797af5013c4b8d206767b24170fc83cc3fe22a64764c0a094e');
INSERT INTO blocks VALUES(310307,'962e842a8722d72b9a24eb689ffd9740bad6a522c214e3b007775321459e9f1164a7323868bf7a8444413510dafa902769d3a5b209434ca1dd4d4f557bda14cc',310307000,NULL,NULL,'9314491a39076f0c90f7b30cd1ab53e812b27d6b1dcb8c8a33f3e5c21aaaa940','b3a5a6f102c86d3420ac016e8ab14f158d3220287b1ed05e556143d9b7827ee6','0d6978325503560106e49e0961728139183411be1ba5e29f224258436df07a40');
INSERT INTO blocks VALUES(310308,'cab1dadfbd7dd20cb6d6856929efd60afa460eab4fb1901a04578553494871800c7573a406ce1551cfd51a4511506bdc0e1666470a39df282180776820419d7c',310308000,NULL,NULL,'d5b8b8005bd1affa52dfbfc6d0298eb6d77a7b72a3c373622cd6a81e8080070e','9468de103b962a9fd666076e35eade6898e5e2c4d5bf28c0dce99e8242578938','d70e7cbc7a2f9b1cc6b8f442a810c529d806f9ae19b7f9546deb1561f6a8e37c');
INSERT INTO blocks VALUES(310309,'026906f0aef4615af04b5f9752676e4e478b571b0b80066fa5d949e5b9341a8e693afce2c1ee50d244024de6e73d06372d26a1b370b7d4f8b2049481cb9f40db',310309000,NULL,NULL,'e76012e82587e6489d8bdc89fe71d82b3f33029a231b6f12952a7d7863564597','e8c3922f1cbe44b921bd54cbecd14af530de6f77df1b5a9d1bbcd336ce49dc3b','1a4f6957d83a746ede368baeffc01b19d4b7f21d1236961696fdb3c6abba19c3');
INSERT INTO blocks VALUES(310310,'64a3783438a14dc900c87edbf5a67e8b6ea58772ed60a90b580b602be8765ce5e22255c582c485c82e530d4bc2c0d085a1a468981d6dce03e85bf1db50c03517',310310000,NULL,NULL,'8509c6c2ecc37ab6d767efbe60fc280fb21e9e85c3a2621a6f40d956fced092a','02509a218579c1eee8039e830f8e76a2a3d276ad7bd21e382d4608bea4ca8b24','bbdc1981883b920c85ffe3cfdd6984caab22283409f9134b99cec855c31048ed');
INSERT INTO blocks VALUES(310311,'9d6787ec7e78e5ef1da4e0c01cefc94476d6d94105537cc3632a07ea60645397968292f7d2cfbabc12abd299d61b9a4b25bb88fa55850a94e123e6ad2fd2d7c2',310311000,NULL,NULL,'f8e5d4d25ed83efc2652035aa1328c7f1039899243d5ada5d7a7f20e17aaabb1','5c88c1847302c4ebd819cc4c2cb40d187258eef855acc68ea62d200ae94da762','10f0ba46e9769ae7070eddf6167d005d91f44c321a40f9b05c149c7311f848e7');
INSERT INTO blocks VALUES(310312,'c699c622fa8fd4d10cc80fd2db029660fa6d9d65e00e5ef2023bd5f9f377d2dcdfd7f474601c202380f2fbcdcfa39f0e238a4db516ca470ab112bde1614a10e0',310312000,NULL,NULL,'bc1321bd891f288473357503a5e802f3c058707921f9b8273e99d0c1520395f9','de0a3ef76c6c5df481517e4df6bcbfd57993ce3235c2fd1561373ef379c69ab5','d07737f2ffd9e72e9ea226dd6b510957d38d24b3175d2cc9acd98bcdca0c0c68');
INSERT INTO blocks VALUES(310313,'67b5753aeacc18b7d7f08ed314ea0a8c85f4f2c53d1c632d4320c5e55f493ab6491f3b023a779cb214bc52b49d8899a0060f2bf9a0c9ca242d69715e1f80838a',310313000,NULL,NULL,'fbc0133c202c76d1000675c208271632da3c77fdac51ba7b2481b6f2d66a8eb9','0bbc3905b2d3148bf979b747eaddcbd9cc612af60ec905f3459ecd543748d64d','8e70851161018c34d2ec97b4a640c093f247fac023944cccaa2d41091d12113a');
INSERT INTO blocks VALUES(310314,'8c7e3bcdfb8b5468c68460626322ef21ccb05d5b4fccfa63fbba41ecc0988abf5672a884378abb8ce7bb35e6cccdd63765a9d052a575d30ada5b3fec51a61aba',310314000,NULL,NULL,'5a206c364125175f8426a40d4fa7aadd61ca7c6d830779c05368ce0b987f608f','db5b9421110ec0470b68bdf06aab04d58562c5f1cf115d3802742b6c627cd3f0','df06149e2c8816c6e169fed5a12bacf4558bbb3f3bf768d5c324ef24485e167f');
INSERT INTO blocks VALUES(310315,'2859914ed7ee244fb079ef25ee5a7eb922d41e085a8b53b9c604a84946252f7c2c5d3bfccde6001f6fa94acdb4512cad4fd80d5042553ee8d5bb939412fc04a9',310315000,NULL,NULL,'47c40bc774b9a63ac98d8816599f73ba2080ac97bbbbcbb471160d733e9fdb49','a4603a3af6edae899ccac56f525d66375b3299f9530b91d4303694704f158dc0','ec84c0f6f773d96a921176aac17d9547580446194c878be1025e146009805d47');
INSERT INTO blocks VALUES(310316,'04cbbb66c280fb3043cf43031476502548e11ded92f8b076220b3190a33ca0ed88faecdeb31be0f6859138cfd0b7acd750ee9632eeaa0ee66772232b397fcbd1',310316000,NULL,NULL,'fbda94e4e64565f2ca985ee25cde6c5a18b52a48170ac6893490589c58b47973','6762f4ad699f285fdb83c5c57b5925d66502dab921d38c746331b7dbbfc6ad69','42cc9541b07d44c014117442d531aaa9ce461dd201d583bebddb0d972890dbbd');
INSERT INTO blocks VALUES(310317,'b44e94194c4cbc3b2c49d5232d8a2f52a09abd88c80f731ac4c36da0e02e8cdb8859db0324c9e7ae52c0c209bda99e4fbbf5d584cb50353073eb27f655d83511',310317000,NULL,NULL,'0f16b565468f483fad01444caf1c213ba3b7118d5f1582c7b16ce9fd6eb082c3','5011efd1f89f9bbcb137eb842b4936b52e00a2d7c653cb108ccb1251e0747e93','56ff2569776edd6dbc162b486114d6272367e3f3e2a7ef65b1329e0094854a04');
INSERT INTO blocks VALUES(310318,'aeb7f90cd47f67a38e54cf219fdf6ba2d345f8f1b1c24f0b0eec974f5568c071f55558640702d14c8e5594ec964708b2bdb0557864e3966dddc47f13501a9ef9',310318000,NULL,NULL,'e549c1eb9749c82bf996eb3feae7aa8bb9410570536e425ada2e523218da81fe','ba62b63d383b63311891777df944cab9337230b70411577e97a2a16e754cf9e4','abc0300e8fbc86538a1d0ea1873e3688fb1152a1728b6b02c7c482c7787f7fa2');
INSERT INTO blocks VALUES(310319,'c7cfc236341db1e9ae171105bcd69f4bed9e104c677fccd496c10351aab2e2dfe4b930e552237aed674615320d33fa4dfac209aa63411ae03fb9392fbe0b7fcc',310319000,NULL,NULL,'c48370aea8cd8d41eea740935d123a1444165befb6bb2538813285cc4773931e','e4091caa2e67c9ed19abf6ca6f54c5f5a697570988716ef3481d73705c3510bc','c39283e98b0eff6ca4e0da9584762dae000bb57da0aefc888fb1c1936f798a49');
INSERT INTO blocks VALUES(310320,'c107f8fdb811b81a405891e79ab4f409c122f706c254e161cccb95db3e2aba5f5c7e8c11b1ff055578710b0209a311a1b011b9761ffcaea53e3756ce3d994ccf',310320000,NULL,NULL,'61ed224a2d6be69f7d037e3c0c4ea2764b2de8d539b23a4be10a5e84e5a5004c','783cfb9a1f824ed2daada3193af2cd35e9a9b2134dc837fd850e1bded5e66f83','a15a65576860023a72e86a6fb57ffc00fe07aa2600158ce0247fba325e4268ef');
INSERT INTO blocks VALUES(310321,'75ed1256404389d1f448b33b47ce03e5e8fd7c62f1284a1ee841018937d9f20286875901aaee85775af6139d65ce8aff852702e3ff050e1552d4f53a1e265d7f',310321000,NULL,NULL,'e2cc35deb245a3825ea2488c3853ecd68baffc4da3d94b33ffe43ea941067c7f','61bf753979bebbd5b3e3123576a401d56b3574143853f46ae4c99cdd20e89e86','0be77c6872d21a1b720cbc7b71ff7c3f19fec122b4cfe630bfacc47791559d65');
INSERT INTO blocks VALUES(310322,'aca61058dc56a84d01999d58a29ec73c0f3fe5ef815ffb02c8acb69b24bacc7a729e3fa56734d7f8ced53f8891f78cc6e411f79814cb03648eaa04cd30b9098e',310322000,NULL,NULL,'827387e8fb2cf54899781a55c84f7eb3a2539343480ff8a615b07c25935c7ec9','cbed9103cc4ccc86f78fe002c1a673e3e969433f47d38bc002108ebd42523fbe','3a8a011e24154f8efc0e0aeb827726493c57cf9334de292b07230b5489da77d8');
INSERT INTO blocks VALUES(310323,'d5c93c1a33425cb40d77f511da1da7d18b4f8378cd491003054734b03ea0d82ac185d356ba05d2bdcab6cf073b8fb53ead8abda263cdd1e6f4c0ae3d2c1f2012',310323000,NULL,NULL,'de9cedcf03ea4b60828d395e8b68ffdfc32bea926da480811dcfd7293e1c52bf','ad33f9d0e2b28246711b9366acdcbe9630a3d7fe27fcd4269de0e1556d963886','42b99a583bdb81745788b9114adfd122f1b9fc8a13095f8f47703ff182e8ecea');
INSERT INTO blocks VALUES(310324,'629cf11346e7c18b683776a3856fe13f6059b62d646eb51a4a7716d28291b0f85834c00cb06e9e9714aa3c4cfc0ac69480b3e28a1fabc87071947dc96a3d7336',310324000,NULL,NULL,'7e09caddaed5d5422a096d2ccd817676563979a6f3de9d194791db8d0377d109','d37797252df51ed5f22dc21336f6cb1f3b514a0800043598993cd1e95fc958e8','836ce7834c9a099b2845ecb3565d7221aec3597db3c286099494832d7e57a736');
INSERT INTO blocks VALUES(310325,'a85d6412e13acaf7f4b673c9f7b1b1ac0dd5d7db9f2b0293082bbb6e9afd5b7ccafe219d7bbac7b6080819225bf85a8e92090f256f93d2a02c50a2b397366f52',310325000,NULL,NULL,'45909f7adfc3e406217c42ab735278f88fbbc84d2d1a5f5879e8cf4e05486a75','534dad26c3589ecafcbe0631f8ec2e6b99ed748c57689f263d45ef2e49e129d3','59c46f74a3c5d5929e1bb25fd5774b217e40ff3d2889daa4742041f6bd149f3e');
INSERT INTO blocks VALUES(310326,'8322e11f2c93306a455b7c03ed9e39d4516d22e3c23360e9cf3ee9ad88b4d3e8c2090aeaf74101e98ede9b037a63b252bf60eeda20649a6b92b4ff2723701289',310326000,NULL,NULL,'81526e57807aebdd803e8d77bc6360420c7b7f71f22def7e9aeb70123df084d3','c01bc31916ccce1af06b3e1485dc858f5849cb1f2bbf567dd7722568c8e32525','4e10c6582e82111d71cf8a28f7248e61c9dfce9c614eba85b7ec07b435e079e1');
INSERT INTO blocks VALUES(310327,'b664bf99ef0dfc4305aaf124f26c8551a9e30a7919e77153e31e9ea27fee6b151388db1ab1473ed2adfb01d861ae7e2441fc40683f0fbf271ba41bb3f46dab64',310327000,NULL,NULL,'c3c701162746d225aa82250da96f62322954c46338a219edf3ce385abec0b819','915707931e615486ef359b650c9618847eb6c7a524efb7739421b82ac5e93b58','f5317ef59c5272686ef56fd8a6331c9544cb81be9d6cc4338be86c4c903c0e28');
INSERT INTO blocks VALUES(310328,'e3ab8f0999cd157c21828ed63db6b223ea237afee4bdfc7f7b3a5e4e8c75309278e40be942a2e24f123304c95a176721dbc6cb9e7e8b2d07503e81f1d7a9c179',310328000,NULL,NULL,'a40bce2d46d26d17ee4c2ed47fc90dcab96b2a96f65cb7b91c053bb61523c5c7','3e97110938c5ee3bbed03877a8d152897b8c2f7af6b9227c31fe0cc31f6b27a1','bffccc04999a6347dcfe9c37284662ac8a1e2ac358f5bf98580a3148f3e58eae');
INSERT INTO blocks VALUES(310329,'69963cf15f2fe78c41c2b9c7970bf203a201abb695cfba9f35c69288dc7b19e4f5045012cd004c47f03243fef05fc96d759b0cb82bae76af051372415f660e7e',310329000,NULL,NULL,'c735d27db7fca3e7de3ff94a0030bc85073e30603bb13c02041570777fb1fd53','1a219f7c9fcefad2cca46b055f9c374df7c688dfdc02ecf55036445de2df62bd','839f7d160a571dbb537bf6892fdbf9e83e85d458aaa876fa70b41414b2ca000b');
INSERT INTO blocks VALUES(310330,'b746a968e4cb45f34bd4638d6ec4fa211ee9cbf08db6fcecaa45c66910ff46c73f43b73bf038792e9311f3ba37e1557d66744c2549e3aa95544dbebe2eb726d5',310330000,NULL,NULL,'31ad07b6b402ed9ad0dabd98568ff48901b46ce0931000360d224891957dade3','1450e3c98ba3c3229720d1b23b9d204903ad5a3d3b5058777aac2d1085b3a6b3','7ce527b3226cf363b6aa0b5cd5e765c3657cb27d0d7911a623942fd0b45349df');
INSERT INTO blocks VALUES(310331,'d384a46aa6d7163491bc05d8faf83de0fb77c8fd5258f5e31a25c8d798344dce82274998b0696d71a062854fd1fb12afac38f3e53ba2c65ab15834998478419f',310331000,NULL,NULL,'7a01bb23254b01ea74c081342dfc921e1a9e8005aaaed47f836c29e3a21e1600','d570620748fd4cf830b9ec39ccfef2c4f75034cd9915f0db760ba5f59f956b72','5abc494a9461102c912fce41b9926433720d0e065aad458bea0ade5a0d87239d');
INSERT INTO blocks VALUES(310332,'260d20c3df6ebc9f43279fc0e67ca125b56111870e24366018d3917e2ef9f3301a14506edb8503d12e5f149802a26cf4faa279ed967208c0c7e87fa5b10948ab',310332000,NULL,NULL,'9d759c2ae93f7de6be80769d01375484b6d60e9246cc2b12d462df6f39fe72bd','358c991e52937e6c766eb7b79ee23f19577494027e4dc941fbf3492aff3c2002','50bbb969d3032674d03a08d4710d15aa553e00f7c75c27289750683487df9dd7');
INSERT INTO blocks VALUES(310333,'7e32479c3a014b1ff8531f8184a88b172bafc495fffa7ab00b3de68c6d93bd58389ea3d2ec185a1e12d79ce8f9e2fb15c46041eed58514566827466913b7faf2',310333000,NULL,NULL,'c4c916c32af88b7bb6e2b49f28ece2a3cd87bb7adc085770b2aba51cb12dbae8','c786335a3de9f19d6f3a104cca8cbb17bb53f36a54f5f48d31814a778aedf2f8','662320d80c31e7514b940a0c7d685d0cd2e6a1fa2ed60936d1e6b5c4abac34f8');
INSERT INTO blocks VALUES(310334,'c142261b2b8d7991e382268b545f65bf5cdc0894fa205b53c5db06f0120930b8edd76cbe4cb0f4a2209daba3877d1d5803c2f8a8a48b53e0835cee2e840a78d6',310334000,NULL,NULL,'4d6f2dac7f9cbed3009d4371655e4e9bb302ed7ff0a0041563d3082d3e06f78c','b1ef21714a98b0e6580557c2513dfdf057c18504afe135917be1e791588d3db1','d041d82a71a9f0d011a75a10d8b1a504575113ea7aab19f71a311067013955c6');
INSERT INTO blocks VALUES(310335,'7dbb2ae1f0cbba1408f32b46a7815776ad7d03b41dd81be92bca10df442a97f9a0dd68044d30bdaba363e3b0404ed2d17fafdb733ea49a5838980f8d9b3a8083',310335000,NULL,NULL,'fba281647910dc85b4a2a54c7f4a72974f73ccf0ad56a0e25ccc8b9d98f04710','a2e8c00abb5ccf48948298674deb353f80ca85cb12bc3450e5421a0b58801ab7','a10b96dcd92ce05f9964cf3cc177b46825840e87ffddb7d9c23c966ddaf0870c');
INSERT INTO blocks VALUES(310336,'d911d0bfba2d67c5642f7f178a11b48e38450f623d5eb6d7141396a61b16df08ec1904fd1c90ef869b11e5949b1b7140f97927523b8f4b3dad3bf5ad873eb74e',310336000,NULL,NULL,'fb262fd3dfe989f4efd61d27b54578c8dcdd66d42303b9d82773eb52eecb8647','1ce5e7d91fa62baa5c5ba2f31809f2179f31f51017f43c65e7ac6649340a595c','e64e7f1ed43067cedd585b8e5fa67f62e7cede86e1b848df2e36bd624021b865');
INSERT INTO blocks VALUES(310337,'364654dc81278c0924a693cea958e57a39dc62d998d4c954ef104deb7928d82ef87e39e3ace43f19d6781486b2968e2edefecdddab42e40166cd3cf79444e6d9',310337000,NULL,NULL,'c4e7787fbac34530388091a4e8690c538fb3a6302ac0728c4c6e4d8af62da333','f0558c596a6e83237a47cf7d02f372a6e86b709316e4a321ab03977d21f50813','0beb39d3e6639bcbe2cec1160b915c20c82e8512e45f2f102193db61c17c3d78');
INSERT INTO blocks VALUES(310338,'46bd830f13fd29e0cb8b06b4f0f2f54ff732f84dabda71def256133400c0b5910383634d66033673385b6c46bcfb3760251cb5e23d376d339639d1ecdb492f28',310338000,NULL,NULL,'68bd59cea6028c2d5b4590135cae9bf75209a38b965c98999c1f749cd5f324d6','d1e89ea140c5fe546082bda432f7ef015a8907fe04a12bccfd87650aee6891c5','4e8495f609e468d34411dc15c4c8578fec261d72e13ef25c22c3dc9d9f9bdf60');
INSERT INTO blocks VALUES(310339,'3edeff265209629eea69034cd577f087edd41c0f539a7c4f6a9ff46ef029420e5fe7da23e6e0b8938dee3f29335cad78f158d1f6ad23d4c72f7032ed99ad047f',310339000,NULL,NULL,'b1a8cbd3d40b82f47293ceb512ca1ffd2a676a2aa7b994c420d1aad59368aa0a','8dd1537ecd982b003bd8993c533dc78a5c8fa16810a96fe01a27bce8bef2b882','f7439f3f7bc8bb27af06a6bb06f3c8834d5c4c831adbe46d26c7719193c13fdc');
INSERT INTO blocks VALUES(310340,'3c71c95332c52d5c9ce2c097fd8a61639827320d899ee9dddcf9f5a7d420c73fc920a639e858ed4a3bdcf778f10978eaa3b4d6ba7e4825520c4af8da026cfa51',310340000,NULL,NULL,'ffc61e8584f33f33c039b3f1485e68a6750f008cd9b7838d434ad634c2be10a9','c2f6f9df1afb8db38cc02ac93d3508106a3b225892563860a2a81605636ebaf0','976fca0a1e976241bb21759fab758c1fcbc9f341dcf47cebe6441c43d1ccd442');
INSERT INTO blocks VALUES(310341,'ada94808b0a11f385f968331b6917b1afd7d34bf30ca89e3ecb23e0352df87afe5f60467146afca1077b13fe85020ee3734277f7df8681fb9c774cc6882d2bb0',310341000,NULL,NULL,'a8752c515bbbb2830f4cf2746481667eb60ad86e851a2448b10f1fde63bee61b','8fa91830a887efbd4d30ca3e02d65192732a04211ad513d98fe326408af16faf','8932af9579a436f2f379f55ea2348435c4aeeb382822eedca1dd91110a41ffb4');
INSERT INTO blocks VALUES(310342,'833c612be8daa3b6e7d9d73b9d9297916a89f358d6f4afa82697e66ba54fed08a4a2fd154919bf5541a89d18d0dac651f86f04e889a44ae9517e6d7dd763ab80',310342000,NULL,NULL,'9a6f422e26b483b349a0c6c8bab8fc3fdab2d7d5c3e7b7309d3731c5e6d1984a','5ab483a3ec29ca3c3fc7e90e1b6a5a095f66ea8269f84f9d893f94120431d501','66941a9b025660ef329635d8cb34e8c5c1a355e4e6e2f43c0db73cf7e52fc060');
INSERT INTO blocks VALUES(310343,'1208824c70f96ddf20e9b71a941817095224228cbb455c44acd57ada445c407632a764bb2101c732faf95d7feab818bcce1c52b58e300e6112f54e20841ff0ef',310343000,NULL,NULL,'45168163dd48c6bbb4ab980c006a670e3f3dae837bd5ac002cd5906a4c9962f8','8c7d34e6384a033a28ae2b2f7882fe361bb66c7146abdbee7aa143beed9128a0','43538a11d2f59b2bf0971806bb32b1fa7eb7afa984aad4014a3098db70f7121e');
INSERT INTO blocks VALUES(310344,'19cb4aa3aae81fb95f3239ef756551b2828163bc6072cb866826914a71cd9ec17ca8a9802d99e4f3c17ae7407426eb92a0c91440905bc98522ef0eb04a2ed117',310344000,NULL,NULL,'f65d0e8118bcde43c83b373e2a6e2e77a79f45403419261459816ccaec906c54','33660c024e77a50b104051122e93707bab50542892e8a9999b35fea6fcead466','5bd9510b44bd0d4c5d3e52bc70c9cedf2803f42830c4da2294d0cb716b48a55a');
INSERT INTO blocks VALUES(310345,'47ad8225454f301c2c8321674c74da1f6e4a9de85e62c58154b12e19242119933fdbc0508d273afa328be196d338b8c49c70346e8df9b16ecb1f41b420370e54',310345000,NULL,NULL,'63fd9d15293fbb7f0df40e9d409c664666fe4d90e7caff4df390dbbcfc2e1c08','a9d80411af62788cf78abe1f747fcd7e6e8963a9afa53aa7c31e5904cae72ce1','bbd98209081f513dcccfc4520bf12c0b71d3ddb126d8fead8ef1e13426b9db8c');
INSERT INTO blocks VALUES(310346,'5e8941c8d243d0de80626f1c45d7bdc8aa9fb785f9befb89b650f391ba377bed233041eba3149a1aa4803199e6113b52ab77484991e59c7bc4861a148f1cf757',310346000,NULL,NULL,'d942543bbfd124d0ab7f81a68626f9f0bae856a98af770d115aed2188d7b70f5','b3cc3000564f2e0c961018d6bcc21837dce50269918ca33693aba7173271b235','1f715cf61a883aeb67c2732db972164c87be99fb8c66f2267c01e4f548b21fc6');
INSERT INTO blocks VALUES(310347,'24b6e5a724028b8a70724e34a1481c7015f0868acd440b495e1c9c82c794d9800c92ff333e5fb95cbd2eba89046ad3e4d88ee4076f76dc6c88d173699d1e24c1',310347000,NULL,NULL,'3a732fbfc1dfb38cd2532caafc4811a10a3212198793c25caf901861d8d4ec28','d6cabee31de55cb9ece18697c5a3e7829118299c201d8e8e8d07a1f87be17037','ac6f4816555b9ecd8f53dbe9377a31ee2f648d529121284f67092159cd87b4eb');
INSERT INTO blocks VALUES(310348,'9e08f4bc97dd6b16dd5c3da853e32f669015248dc1e4648e8b85bdd548692de814f409a44830a70b9eebe66650b424b900f722cea1043b0cd2ba99373d7181f5',310348000,NULL,NULL,'93f52642f948b9b377ea9547f622b8ba8057c0796f0e7b95550e9f48eac6a6db','9d25cfce0c8b0448b9684488ea75dc51cea9fb8ee18494f0c845824c80e2716b','ba5d030790f0e264f59f60742d6aa94fd742d8a7b30185c8ee914ba6d9891b82');
INSERT INTO blocks VALUES(310349,'448b9ed8b0a0dd53b3c0b8604e87660339c5a0a731eeb4e80e35823890a7b90a2e273292fdfc2e83101079afa51931a21c643b3d7254c00eabd1142e3cd29631',310349000,NULL,NULL,'07e388c32dafdb18e87b08ce4cc2ac2c749f99d910b9862510434cf52999eb16','d2547daf8582372923848cf5fd6b5e31e8ad2c0836074aa59729f76fa865ffe7','41aca0596ced67d25b90e841fceda75116235de81c929eef154edf40f5ba65d2');
INSERT INTO blocks VALUES(310350,'9f226e675f14d9b6785e7414ba517a9d7771788a31622caa87331aafe444e8792b4f63767e2175b1e32be8cd6efe8060c4182fd08f9a7adb149b15f18e07ec1b',310350000,NULL,NULL,'3776966b5b9004d24622aabde1f3d44733ee14ef1a689086e88d12266fce74fd','59b105e1fa5a84a097ffc8404d4d92811a7c823ca95316929a19d6279380b93d','6aac3c73e4196e9cc4f1d6cfb7564b53733823f0cbdfcf8f124f463388872b6d');
INSERT INTO blocks VALUES(310351,'7317ea5af2ca4c8fdf5ef475c806a5304e852cd3569f816eac95bc8376673cfe3cb2afb701ad27fcd14e4dd448fb82697e48ceb8b3534d62b5a94b636b37653f',310351000,NULL,NULL,'5e4ee5d27eb6c272446cb77dffc02b65932388e621f34fea300b97ad2dd16b66','b289ac50f9a37f071d9c7191466a789887434cebd7592fe7743412970f519b8f','b2c030395de72d82f87a130b87da4e2d08fb72fea4bb066299c9e86517eb4f7b');
INSERT INTO blocks VALUES(310352,'dfc4070624c84471fc34914f4872491490f3c2a64e65de043d0cd1aba28a3deab42dde9a9df8ce1aa134c5c2f17f03ad25f8c876eb8a98e576e8f6f230adc1ed',310352000,NULL,NULL,'bbab44cbe51536f1ec13b4e37c3280602a980acf9c5d538e9a21b1df86910501','1e199f79a8e6b737f6ebf8182672519d95f654234d06b0faf74c48b07fb4229b','a8f16409b4a3dd1b3dfa2148a0925b4e19637ea9ee7d358693f86e90fc1fdf41');
INSERT INTO blocks VALUES(310353,'5313469980e89dfbe92fd25f59bd9bad29ab5891d25b9cc35addc939979865e059a8746d97db3ab028cf0438ae4cd0bb78d68f1c9cf0e49fb979bace604be536',310353000,NULL,NULL,'c3160bf2d886b0234b764e1827435118a37338a9d50089576ae85c1a54b0e073','77f1ede251fc42dc6ca00450ba359bfad21c337115b69a1ef975956577ce3ac1','2d045ccdede7ef81b2b9fd2a889164bda98008787f41f68c678e2456581fd1f3');
INSERT INTO blocks VALUES(310354,'c226d792f6687bb7024364b57f526c531337ad302b0e64dba5eed4406a197f61fa1ac86b5750d82363623f41c10d73ce4e68efe32a95026b17467b69a384ad5c',310354000,NULL,NULL,'0a308d499b19e57f95ae347227ee07536dcd1378b829f391002f7afda04e877d','c0af2177742629561b3ff92366d38c7a1b280217e4cf8b85670efaf72ae44e39','d7b1b735587d86658b3cd432712441c805bd37df6860e8f86ce842a3e5b9ae23');
INSERT INTO blocks VALUES(310355,'47d20eaeeaaa017276b343a2410e0219882f00d3f37a2cde895ed6533c76e270b5d1baed267bed633341a9f151ea1926b11c12c98e8b4f3ffb82855fed4587e8',310355000,NULL,NULL,'84a8b5dbcbc4e91bc2847f12d6c6306c99f5a8c46a72eb2b0359b385c3227e65','6056fd94bc45303cfb9844084393298e1bf39e29d0c2e5c8bbde8511a1e4b23d','6abcb3b897000b0cb741f7707fd72080bde085169c4b5db6ba66c0ba1748af1c');
INSERT INTO blocks VALUES(310356,'ec372a0c5286fd32359a4b230b2591c5a042a6b8198f50e48a9f7cbee29a94133c63e998c9cbd761a16e310c61cff3d7d6c3fdb31c0017952d9c9f0e0b227634',310356000,NULL,NULL,'35e8c4c8139e25d42c51de36c8af0d9e7aa1154678a5c0b3a7869d15cdcb9be9','062bc005d2fec224139df983099dd8b388d51e5fb811aeaee1270af74f121c16','06dea542cb71c372477563cc032cd2b19584279c9fa692a2cf3a2b4a0090d3ee');
INSERT INTO blocks VALUES(310357,'77521e4246cef326f9225905a2f0ec39d9ca03010ffab5e2069d09fdd429bb46397434401ca205a3dd1fd2551f7b51509e4175a4ec99f050a23fae87aee444db',310357000,NULL,NULL,'b2dbe2dbcf65d59b910f6481adf3341b37f4676f6364e91156564399b0608853','9cfdadeb5dfb557f57107fb3a9131379fab07643c3e89d77a8b8692d13b48288','9ea49c752db3ada9c0a531413cc03b5b04094f2561182ea31219dab81690ad5b');
INSERT INTO blocks VALUES(310358,'11cf33c1a299fb202ee558810c60435613199de51d6ee5a0bd950df50a2d2aeb2b56c338f06f53cb242ab71633f783f3f77a2485cc8d0bb0dd25e213e3b19237',310358000,NULL,NULL,'dc919576e1b19881a3e61a2d2d8dfbf0485b5c741592e1daa1b5f51dec066032','9e295d2be29fb8ae13edd94644007378eb74e9290534ccb06ee79199b4cf54e4','8f5d35cd2ce6c96175f4f530986f4742f93308a87f5c58a6591bf5bda392f233');
INSERT INTO blocks VALUES(310359,'c2f314e6b8bfe22b3fc958f311a3ad60bd65973ff0afd65aff5b4656b112601642db654c8e520ca7ea9d020a1321045e0366ace5475aeda8a09ac2c1f7e46062',310359000,NULL,NULL,'5b7ac1266db77cc82638808031ad99a0542d051464a66541978cda0cd57d213b','e1080ccd12cd0d980ca3a520de47644b579e0e9b20d67c11cedd12b651535342','036569a8ae3340a134313dc16b8f4ddca49561a93dcf06f5f91b5b779351fcde');
INSERT INTO blocks VALUES(310360,'bda2c508410f604760a474c0829ddebd39f7e1a3bf642483d0850dd66fa3142a8cbbf6e6d1812808b07edf4f179709fd321b0967b88830e2ba3f474bd5d04867',310360000,NULL,NULL,'e3e38805ceda787929bacc4f12912484ce3123fec6b3435be9630afc978df507','b0e363d4d3927888af3302011261e154c0725ff874373c85f5a837a92a4d3d39','f7ad3956eefd2e3ff3aa963f3e351f0c7f999ec1ebb5c528e154d6e07f2d33a7');
INSERT INTO blocks VALUES(310361,'0e8aa5e61551f54429774c27dda7665ac746e04ffad7ea7fc30d0c10eb914325c98fa6b09398d9ac0137862787182fb1f8f45d2e840ecd7ec53634ad8c6afa37',310361000,NULL,NULL,'4a729a3062f9c4a5e59edbaf9eaab5dfc6dd6957d433eb197a8faa2c4ccbba39','12e814c7a5c84173931b1ff165c40e3efd2e46d18f9410a02d6be1ba26e2d71d','945621f3f4b7865adf2d858cfe000d2c05e22b06172dd3cbebe71c8acc2a7a97');
INSERT INTO blocks VALUES(310362,'4cccd2754c6eaade8dd5a60a0b1a0a39d80e5348cbff18dea4e2b66ab5c20af9c59a7b737d7ee7ac3b01e0c94e18f797ed9976ed0aa97b3a312f345a02a05b9b',310362000,NULL,NULL,'8cbfb77476de2f0febe51a75dcb480fa33ba29e2b571b9c58228db3e6db72a07','e554c64a645476b6e99d5370e011e03f1674750a4ea10390978d00b608215137','2e471005757b89ab42b74a54c950291133b201e784be03552f3ae3ea8112e51a');
INSERT INTO blocks VALUES(310363,'12389822986bf132977ffb72385c92c151bc3e8655b89e33126ffad603486885c7d6395e34bc49f75fd8b6f91994c4af72124fb0ade2b7cf578848bae9767bb6',310363000,NULL,NULL,'68015b85b629a9cc7a06ec61e1c8d2fd69ab3a51ba87aa56cdf2ebba9cff702e','633c6c63cd1423ad3518994f81769bd43aaffde1cfddd2aeaa54916a9643660b','9c5cdc7d0ee39d93b1bf096009d22266963a2058dc0373a062252f51dfbc8e1f');
INSERT INTO blocks VALUES(310364,'7edbf5c584ea6177755aa9440b6c2c2f3b651f089fff837a61f853813343c7c7b585eb49f0131e2ed98ffd64a41f0df345d8a3e814070f5cf02dab28b38bacc1',310364000,NULL,NULL,'ffc330a0ace2ce2d3d023710de435f3cdbe09b014896523f349fa1419230cba7','6489988b64451ff0f9c74936b61542408c282dd1ec9c38b6620250a543b07c13','7da4661063ac5f911cc13d3843e7d7f50e8e866b8f3758c1a7f52342ce5e3f0f');
INSERT INTO blocks VALUES(310365,'240660b1ade55a1d5f64e0e9d4f14c751cd2aba9afa64877b03c192bb4a487e91e009180f1e904302adafadb196377114de3fa3b9f207efdcd0c279118e60dfa',310365000,NULL,NULL,'05f368b11d900cd02c89b9f8a1c5f6a9be094249a20daf646773c8be6f65281a','8c2de11066f1e96f078e55c408611c2038986127e0e2ee58e140d3cdaf95a1b7','8396a6ca180a33a14f156ae1d633c721402d3ba038755c9cd6d86e8362659f52');
INSERT INTO blocks VALUES(310366,'499cdd62e3fef786e15aa7c87b27b2325c98a845c1b31e41c4246c98280be4202b05d41f3463bd972ba855da9f05c7a2a308c3a614b6d088a5ca40b27e50e3ab',310366000,NULL,NULL,'ad04a99493f319ac0d281bfee6e65d14b28742e16ba0e425f9c0a59d2be9e14f','0a5e9c3ae3f33e00b56d838e1bf624bab9199b0478433a85396dd3e5b4968d32','0e461ba6b134e062f6a9b689d7ba1e26340020f7ac69abeb9be16f7c6b80ba08');
INSERT INTO blocks VALUES(310367,'78b3a4e982e90a6e977e7d6044c6de1ae6e5c7a4116b912fd2923006380767e842c73dfa45f63144fc3e368b9979c7dcf71e34db2438fb18126eeaa71495baaf',310367000,NULL,NULL,'90d05f51a155bb424c4b8d29f411ace10a598482d3d5ad19a6cf1cdb791ddd61','7fd2d7c2c5b91f9934f2de59d21f3034104cd0fe8a629c5b4f027fbc8b531486','a5f46c1bfe962cbf93d912cbf865064c091ec9a24fa13f100766c6876272d97b');
INSERT INTO blocks VALUES(310368,'6d09a2f66be5a338d44a8905a5eee901d359f6c8a0fa4b8a2369e0db591fa87b7920b99c438310657a40c40f3cf8d5f04ade22c935b78f65ce3bd06a7675443a',310368000,NULL,NULL,'8793fd7ae785686380a05e653344ffeab785f5b381cbc01847c5ab167f48fbd6','3da372abaae6f5dd02b7b5fbcbd17612ef7fabf6fa30b565900c177f92c18ac1','568db0bf9835023cadde548896c79257b341b5aee92651f3febb4bf6cdf085f0');
INSERT INTO blocks VALUES(310369,'d0d27d889910164f21902561ccbcb5e5b1e585a98b2a45f773a6c63249c7708eda6c755aaf2733245d0d388abde416485f7cfc028358258c65b07756831133d8',310369000,NULL,NULL,'e24f9f02eb23a43732a11afd23a18c2a3bf9197fa13899e9aab2c440ece44bba','f3ba3191596b62cdef58aafd32d67db2ec281d8cb152d3a09270a27195c1848d','681256871f7ef035b2f20c36e09933513f665d3c2d0c992021dd92b25c94dcc8');
INSERT INTO blocks VALUES(310370,'33ceb941d59a7c205b7eba6c6f66bfce2beaba82f919e2917805e0ef41187095b21d7f44f30ed35c410663de6b2424be9bdd061be9435a79f163876364d51d43',310370000,NULL,NULL,'a7805469a067364652e1a9c320ae2f17469f4614e3da557bb2a2ca43242b9503','058cc9dc15fbfe509fa0a43792f71dd6c5ebff7cf6cfd585c158096979af5941','824911e098d60b2dcc42d2894c5d752ac9f13b4ab0f4c5de44d2f7534cb4b16f');
INSERT INTO blocks VALUES(310371,'74dbadcf2a24eff2d8f91b2e897d8a3cb9917dfb0b91ee9e1f998cb5516e8b53acf934a6629d71953f2adeda6162d62c66321b513539d355ccd51c3b574f77aa',310371000,NULL,NULL,'8aa871c80e4d857ff218477019d59b80470351764a4180ef0fdc801afa73889e','050b4c5cd34b48f09fdf1a7a1a2eb07348790218906f07f075114fddf98b45a7','15d3fe5982e9eb05cf3b626a0917996a7659293849c5dee07c449d612db35ebc');
INSERT INTO blocks VALUES(310372,'96f13cdece65d8f565b8da23404826730a46f2c1dfc80dc0a91c90e151538a274994efa7748572ce780eadf6494b6be935b84bad037b6f6c8e3e4dda7162d22d',310372000,NULL,NULL,'ca8f0b5090b1117f100fcb4c0450b7f009821c6e4fe60bec4b8a34b3654b7d0e','3eb056f5139bef9390c3ffad866c17abb01197ad1e528616cf4aa5ecfb2e3f53','3dac3ceb372fd2fa98e7f8dc9658de222f941cea29204322ee49c5b096721b13');
INSERT INTO blocks VALUES(310373,'a217d3e988ccd8860da329ef66cac433b4d4a2ad2f4e142a5c181c2f413f6a7c9fe66296deaa6dade5afc5b450c9f4ab885f03632691f4a7de3dadfb5d294cbf',310373000,NULL,NULL,'03f9b1dae801437f5750ac65d28416d5739c1607b87c8532496a362e4b82a093','1f75ae10410babc16d5d595c702e7a61d956a190994efcd5a95655b9f6303108','d894a2e7571b9e8092e1ea59f2186b0e7257cd018d8e90c381f0941643a3d4fe');
INSERT INTO blocks VALUES(310374,'b9758db7828f0545cadde8e918d2e433810d8b1320d8f955b370dc81be6c1064eda35126895a5ebc47c153b5416b6eaa6f24e670d7b4f9d0f4ad8022393db3e7',310374000,NULL,NULL,'7ebfc17d7e90016ffd72f8ef36bca790f0b187ae221d8da6882703e3d87f87fe','d8e9507b2f1403e804008a8efd749a6d680eafeea8d4412b4c370dcb533fa081','c6973cff5d4f63bb3901f5b48cddd2bc40ce9653a049b942a336a180c23e2342');
INSERT INTO blocks VALUES(310375,'3fe27307afbf4fc82b05404d5a6e22fbc18a6572c65b45bd302630312e0f645003efc695e15b8422a05ed551e56ba1485bfc6901db8b6bbf067832cae2f1a2af',310375000,NULL,NULL,'4c725da6025cc3e38616a494c9f7155f96fb53bdb93a8b20c750ef0e1759fcf4','e70b882a7b0fb694d4d51269791195384265498a19cb556d78ea261707c1c535','80f91b38d640bf7bc0ed68db1fe344ff477e14a20d6e95de20611eee2b4affb4');
INSERT INTO blocks VALUES(310376,'d913919e375a0eb085b0adf68fa926f8bda220a4237259a95da4bcf9a67c7aebe1e09ae23874d4cd3463a2248677d46ed0deb5127d328a2ecdc99b21dbf95e6e',310376000,NULL,NULL,'360671e42863b78b67fe6574ebdda4e0e9045220b8dc7ad7b37ac92fe6f1ff12','51aaa1e56eeac02718a50f8f3d065a394d9ad531619acd3c1e3f0e88bd180f2d','2018808772f8340739d4e18bff3ed158895c87c7d5b32cda66c91a843cb13a2f');
INSERT INTO blocks VALUES(310377,'701c2380f56df14a7f6c7133f3e094b23c3ff653bd2adc6265577fe0c3493b051a93fbea95235d29dff8b66a9dd6851e75c022d3f02b879b84771604091e7e37',310377000,NULL,NULL,'3b27b0467e5725482f54aec3132f20098658aaa1c21099ed75df1140a49f99a0','22be4bc9ffcef4e49b4d1ba8d5d2880005e43a60f5c85970b43f0d38207870a8','7ebc3a103989aca5ef5032db8d430de0d7b1215857e6f99cb1467258f851712f');
INSERT INTO blocks VALUES(310378,'d7fece17c659c0ec86f31fedbd029944708556d47bcdf9913193bfd90906edba5a925bcc8b03f4df67310f778a80167c2ce8ba8fb7959d3af6d17f5bff608e27',310378000,NULL,NULL,'2af4b05ea39dc350ee48687f9461703856395b323b54c0ce3a164e41a5f47908','b67c9a326de0c1e331ee6e31cb79af2c2b1bb958b54509f764f1fbeb3999f106','87c0f6ff672f7e2d80deba1c35405dc2f9a248c3b495b3d10ca2d3838614f0fa');
INSERT INTO blocks VALUES(310379,'e35a25ecb6f50f9f4009ebdd87f9e76f40fbab78c5417aa0a11ac765bb4adb614eea926ff7558cc5fb6194c075dfd95eaf2ee35f543dce4ccf72273a016c1084',310379000,NULL,NULL,'d7868a70bfb8f374b611e2e54b6807793ef5d6edbb56537c3d0a6dc68d631e2f','cd7c08e37395906f5d39e9322d40a24e2e7522852801d7c40d91211af0d54a15','acbed688b999d69a9024549c6e999e5746a29662be0f05755536af2913319c58');
INSERT INTO blocks VALUES(310380,'3e1a363381091400bb31dffe611e251598a7c7d0c5f8c14a06c8487b2cc0cc31a111112c3fabf2e23c705425f531cc91f21ff7baf4e7e015ce5ad884bc3556ff',310380000,NULL,NULL,'d85a7a9fb4a8c7901f6cfcde29d86fd88ed3546385912a20d4d105bab7072292','f3a29c6e6fffdf736bbf7b82e56632263011ac6652271945b88e37bbcc4333e8','98c82f9a675ad17aaa04ab28a2c395cc7ebe912a4d330039d5177fe37006d9c8');
INSERT INTO blocks VALUES(310381,'7c09b5350b292b8ec7a9492e50647a0fac1a1c9daaaf76c7c2f588d17058333598422a6b09f6b43e65ce1c274741c970e76f2367cd7341f31fe5df3aea6fffee',310381000,NULL,NULL,'6e9325ba81cb530639467b7b44bdac429cf5d9ce6e93f98358b27c19e805a39e','58e9321a7fee049567217bda4c636593b0269bccc7b95152b785cdf7829adbc0','29e964c7b02b2fa4e580c2f97061ee1ce66f96492e7ebfad201270988aa28cc4');
INSERT INTO blocks VALUES(310382,'c0f7e693943d7ef303f8a8f0b82b42c05d16bac9a51ee748d7356fe2495756f4c8b83fe9848ed65d6063d79ba5180c9a0635e9dd1e09f2978c7015d688a71bb0',310382000,NULL,NULL,'ee5dd20d3b157c699645577a70216552f5056d8eb61c6b86fb2e7dd0296657bd','5bb7fac712b2e8fa3537b92af72daf038446d9256871833297a358167763b682','4a4bf8a143be3b2124c16463ee26bd598b5aa3d242deb7157bc806f86568700b');
INSERT INTO blocks VALUES(310383,'024f27890e9c28b78b0a9f57c36057f9a3a6878d7d1312b71d0e6dd97b2acba0c171ec3da6da1a7564b182764000f4ce0e1368abd82796730f5fab763897558b',310383000,NULL,NULL,'5d00aae5504b5cfb914586b0f5e2b6e7b7cc91641bb66c071a274d671219af69','5ebe5aac3d2c6bfc67010bc0d7d0c4a6e9622b2bb70154cf0b17a014324650fd','f1a3584682101f1dade6ab7652a07225af62e01ed8340d3d937a8ab9c7ebf526');
INSERT INTO blocks VALUES(310384,'ef45b046e85b9aa1ae2e5108421d2f77cd2a167d45c8239307666e23b00042f09057c840be9f0802c4a1971fc6d33dc072e8fdd552802859902c94ba9a0616f7',310384000,NULL,NULL,'8428585f88a1d285b57e504faf4c4dd88d8897be449b466ea5bba95d949f0331','2b3f6409ab2a0c222c71dc639ae385ee134107a91d1284c3e490e3ee0b691715','7ccf2c6cf3c4b432180ffcabb23af371f68a78e98eed448ca432e9d8e5b2c338');
INSERT INTO blocks VALUES(310385,'e6e3f4b7435f96e5972f807fbcbdef20e46045572a235c1a653c97d33a88fc31e0169e491070619cfcf98e28614148f6b880481535710829131251018343f477',310385000,NULL,NULL,'2cfe98ebcab4044eeca3899b660b35712f92a6986a351f9c18e7381b9d299b3b','bc3c310df0b4f275c593577779a036c72f02eeb53e5930c987f37ba90639df57','8afba754a078a3c91bc62d1add01e661165210e39da42354fa736926435394e7');
INSERT INTO blocks VALUES(310386,'f1bcfb020a9b17722d2a304089806f267ee67561f5c33f8c932d0d2430faedcd7504d98db47e5f996834fac46935c47bbdba8eadf178d52ba8d5c828c08aa000',310386000,NULL,NULL,'8203ef47b05b82e4ba54e6d13a3f24109ed768cbd6be83ffc46588771a61c1ad','e63e7085645c56c1c0f3c9233a59269e3ef2d67aa2ab84f24d780f8e4b7978fa','745b138551c62c8d3bcda5d9e74106c3f542b398c1b3192fef4b739d4e103ddc');
INSERT INTO blocks VALUES(310387,'97324080fe0f8ab79d717f3348bdd82add208d261f2d04e78a43818122d08ae8d2eca18b16b26e9b5862c0272beb751a62898048caab736438408c3fce109fe7',310387000,NULL,NULL,'463ffd4433818af6b653826edb6c6601fe9dbc88fd03e866994869aeeba73b4c','0ea9bd5a89422d127a34dded9482488135cd8dde7cb13ae6066fbbe427958902','1207ca1df83d63870d206d40d11fbe98567e7a081fec23b4de507d0847b88574');
INSERT INTO blocks VALUES(310388,'bafb9f69a8253e308e91876d280a71ada97cd903ca04f14adbc32163d166632a19c3fb3773c9b126faad96b21675ea8c216ab7930146a532da10269286b3f675',310388000,NULL,NULL,'31e769bca4fbde150567b47848ba32a5d3a891df22f40de389c7730afd59bd45','91ea768e29a6ce3547625f8a3a908234b84177b0ead0be98bbbefef288ea4e15','a9974d686a83a913f09e990ceaaed992e0ec22138226f61de5f324954f305113');
INSERT INTO blocks VALUES(310389,'48b9a51e1dadc6af9cbd9ef618681c97471cabe25207b174f93a749b3d42db15446ca78b489a92eda8596bd5a237fe2765aa0e747bd062714b0e84b5d9fef4ee',310389000,NULL,NULL,'246132652c8f3f96f65c1543aef241c35a1591e28968857c042df1ac9313fc80','a3927c2dae423742476c92df2d53956d6e1be5385b33cc38f20fe351b0f9c391','1c19dd6ae5dd9387d3e93da41d9879e797c95bbb70a218b3ad51aba312b45bf9');
INSERT INTO blocks VALUES(310390,'a4c7793a1ec95d4bdef82e29bb92d1068d46bf9fc542c67b0e8eab9e7795fdb0041d38f6c14517f2dd8ef0f1afcb51658215e08fc8a4261cc3a8f0ebccba7f28',310390000,NULL,NULL,'b0fccc9577731f10669d0108cf3ec1830ce2f25565037e1c69fa8b2a5f4b5f60','89090632f780c51b031f921531ef4385f62d854afa36632d6187c3afadaf1efd','63a080ca9680adda67c541d86a3db214d5ca90c16819ef89a6fc6bd03acb3e39');
INSERT INTO blocks VALUES(310391,'0cdc2a768515be5cec8f1ac0bf90f1cbe328f112654363b53adc4a3c71d4ef4a24fe76e911a38327ce9476ff1739d3a0cfeb87650878eb50d7756a335dcbc0f1',310391000,NULL,NULL,'90c5d0350f77bd8421b072dfee1b3e92f3f30cf63b12b03f9e040450dc84adcd','1d21b32ae6e21c23b00ea4feb30fb2aa3b5f8f3cc317d7c6cb672d9a51118058','3d94b9bb7b6b707a364c3e23df85c6f0acb35fa36f8e1746c38f8840dfbf1b03');
INSERT INTO blocks VALUES(310392,'8d3026550633fb3c192d35fe9eb34a336a375b702d24814232f5fd9a306aca9c5c88b62844eb6de4ed9070b938ef959d7c06c5b57e09c1028a130de8a66b73d0',310392000,NULL,NULL,'4525c898515bf3bd39c708d139dd02232fc148cd70e3e8394d3da10c3665c8a7','1ef40f3e2dece2c9a1ccb16ed9ccdf39af966ed124c3b0c2c1036f8233a2dbee','cd6ddec1098c0924cb87fd542009cced4dd90519cd52028992471d1229624d52');
INSERT INTO blocks VALUES(310393,'ce1565e85d22327c9167ebe6340ff3455dfbe588df356612bcf064083ad551ada2013ff7855f738d50d788338e8fae7beb9be34a87496e2e113084b16cdd3a60',310393000,NULL,NULL,'eaf7ab1eead9a9614206232f96ab46cf9cb6f52524538ef2ffcca6b6b5dab4ab','86afc9c6876def8af62d29f296dcf92c9a6088deba00781ac0d8cebfbf81a023','a983a38a301170b74bf2947eb092e051bd7be4cec9d4b8dad0c8c6f1bc5abac0');
INSERT INTO blocks VALUES(310394,'ecfcdafd1924ac35b2a8a2cd794d4a7118107f8481c3efc2c3128eea5b5016f16c19354323fe2830b49972b947156199319a440f0fe1d2646cc9d2be6d160e32',310394000,NULL,NULL,'e6e6cc3704199203289b18ef24079e1773807108d1341f40041c536cc11fe9d6','3325dec29e72358041f609fc1bb908e9e484936f05be8630666bf0249b32ab65','0cbcc037f20121583b1dd7a33dec4f91df4b9633495b06a1fadfd71068fc7414');
INSERT INTO blocks VALUES(310395,'49f82bb1b6373d11807a41b870bf863d023b02aa9290fa89af227a2ecd7f68692753260cd95fdbfc3a215886f72a59433c48b98e0e63c67072e7978128b8ed60',310395000,NULL,NULL,'4c58e40bb867b6e0e0fc45a29403a4249712199b4f2cac22caff841a8abba76e','4bd781b48c5d12a21c27e9f79ee7dfa385e2a9d3a12549882cf347d15ff3036b','0a6a19ef4d73817ec6126d49f9932dc8711f499d8b604e025c51aefc6f4ac175');
INSERT INTO blocks VALUES(310396,'78130540890de0b675b37bde2aee28c8fd4ea1678de7afd80b1149be1f25b7cd8b8a43a7f5529136708b6345dfef6f2068edf5fc84636ab2445c2f3a7191e7ba',310396000,NULL,NULL,'648cc21c3fb2889b8fefb729a3e57f91b735fab80779a474df924831c8ed2ede','5554a486d29e8485d3f27853f480d27985427917949703d6232ff82f2fe9e294','42eb3d4d4157a229d84fec73e39ae1418a8947da58a7f26c3d6c762e3532665d');
INSERT INTO blocks VALUES(310397,'d93c2331ebc27c05ef1edf7f5283ba6b936271da24894dd753ab8b9a5866276a075eb5daeaf707869e9422339730bdffe04c702b964eae6df7fa92b161743ec9',310397000,NULL,NULL,'8f2d1c2b26c257c66452051a11c32652b15d25e80ece5d2fdc156aeb5394ac9d','6df3ad3f32ef30524e164ba1a4fee926a17326bbaca48c513733fdf6d24b9419','0e1248862d0368517a617c50b625d81ccc9a0e6174d4666b80b39576cb12e0e4');
INSERT INTO blocks VALUES(310398,'3cf66db0bf703924efa0b1a509c51545ce0cb71bb75be55899a5e866392de3cb79fdc3bdcaaf9984a9d4f2e790d4c2d3f326dcd80075e321b34f90def7467014',310398000,NULL,NULL,'20b058d31265018c23e0542cfeee954f1d1fb31f807372f8baffbc034fd8a089','9847af8f1d444bbe4c29babcb98f06881933f689e6790c4306ba9fb76cf91922','0563d136b2a48a9f0ec255bb44cef5ae7b5bf885834f39cae427ad93ea629668');
INSERT INTO blocks VALUES(310399,'a85d0e1aad11babf4868b07ae9af70e31ddf4759b4678a714aa0cab6d42c6e27fbe10c7b7126eeb9b4a67e499dc48905c487c96f89fb1ae81783c7293c783d3f',310399000,NULL,NULL,'7aece3c5e8529ca2f6f84f50c2d4ea59d60dbdec7af62d60468789a5df465d96','37483676b1fc48fbbb66b795bff698bf84c1be065298d4ecdac62238a8a6a1d5','4d38a6430e8151fd9cf21eb6115a604f0da71e56c156f27d8d06acdb01a72de0');
INSERT INTO blocks VALUES(310400,'174d8e6c08617f64c726d4ceadc20b3465efe775c3dfeac4cfa0cc4216168ee9e3c3d7da993c9c5c71073c7c5b51a4df17f9ece110bc7edd55dd5c8ca756ce7a',310400000,NULL,NULL,'a910ecbc1897cd5355777a5b7b62c28528c91e574b6cf390fc113959136abf5f','98753e966ab4766f643872acbc2daa5983d475b4bb3aebb83c781e1ced932b77','ff89f5986cb99e3ef3400cac6ea21750eab1f2bb1c9959b40712876e1f277b31');
INSERT INTO blocks VALUES(310401,'f0590b3f199a1db947a38a4955992e6e263cff84cec984ff1a980317815d855fecfdc4eed6969fea08825a28b49a9f84946b617b33b75745c2576729c467ed5a',310401000,NULL,NULL,'1e610ba9240bd69f660af1fa4482e44795b0ec90964d191ff3ad48ba35868c85','c29595f2dec05bc10cd262bb8d7581b1cb17b3adb5d8cffacb066b247fcad65b','b88e43699ffacaf0513c121f36f678dbe8cfecb328bd3789a83f721110b68298');
INSERT INTO blocks VALUES(310402,'6709c9d903466d14d29ff6940f2a9778027cd368520f4ef2d457d9e5d5c52af845a3312acc25fb92176f0e4902d8985f5419b22da23f2120de3f684f483b7c83',310402000,NULL,NULL,'4836dfe6ead791a765d476833e9c0cf52b28f239dc82fcfb60035b020854a308','f7a470af801e3a8d154120c8bbc98a4143f058a117ab025e46906e944c0b277a','c4fcb304fe2883f10fa1a857170e7f993aabfc82f6edd99f7eac5720049d7180');
INSERT INTO blocks VALUES(310403,'ed36a12306f191a5f796e3604e814618396ee773e41bd534eba4534fabb9632f3db522fe0422aca404792181c62df1b596ba445eb7ae414441d4fbe2c04b62c4',310403000,NULL,NULL,'45fb7051f740347f70d15b7a26cfaef7be3b8d9c1444c34feb2335bc271aea19','e5395597166dd1d11cc6e69c9ec8ab749eff830568e9283319925fb5acd5ecbb','b719c7a0318ddcd7985f1097c6f8960400858f31e4d9c10a7902ce6b4dffaaf9');
INSERT INTO blocks VALUES(310404,'6bebdb83a225957a55b436775844eb69c0dd529bfc5c2ebb9088a784886c8abc1abcca7c49518bb5a6a9eceeacec2a28c9b89d41f4a7725e3caa325a773e0288',310404000,NULL,NULL,'bf4bc964c00c90bccd53cc2fbeba3a35e5e4c366c9598e95c13aceab36e57f1a','17012da64482ebd3a074791d68590413b74b1e96e69b777b47c5461722e9a6dc','96de574670a5c0dbad17ef483c766d831afe47dabbf9c7aff660b4a92c3e2252');
INSERT INTO blocks VALUES(310405,'6b015ebd2c2986f6df13a8feef2427d8b03a4bf8bb197eb2053d5c21370096e8ea57256008961472d8ad195d56f7adfa8b5b295d4916bb45562a853104334e34',310405000,NULL,NULL,'3149b9edc664edf89b5a5463920190a4427b99a32525686446099d4fe36d837a','87b1a3d02a6023fac8cbdfb9c237e8154e393ab82b98e2661239662908ce54b6','3d936dbfdf69357622c1917335b2a1bff99b0a22ce79aa50b6eeacef57bc7063');
INSERT INTO blocks VALUES(310406,'87467554696f2c8af1366cfb993410b81e17e5551e963483f7c2922d7805d1732cf141cc42ec0e5e0042a82e37512e24786f6e39274f2c8d096ba95d55bf2bb3',310406000,NULL,NULL,'89c1120f4508a5b7fc4d8f949047a9ed50e303c535fa6b0143f8a849a33a46da','f4a1bfa3c1560d29d81675dfbed2e35de8fa00ec7470594cd08acee9d8fcc7c9','fc920437809e6f7bfa71802ff7e7c00812b3b251e12a6148f0344d9ec10ae63d');
INSERT INTO blocks VALUES(310407,'b3ffb46bb9ea5e1203b393bbee2f84bccbbca85bafec4a8df1626e75f66b65f612c1d53fe71d73b961e157c7b3e3e78e25a312286ee529da6c8820ec1112b5aa',310407000,NULL,NULL,'d510f3b40b496ad5a8bb4eb176fe25f2bd1ae21c63a1ced8128814dfd946448e','fa6a22f8847e200ccb04b980d09a126c4ce5261927ece5ebe5871edbf5878122','1781af5f2248ff13015315f627bfc6aa089f63fee2e559bce11eb4f659d6e1be');
INSERT INTO blocks VALUES(310408,'7bbff3b39407329f9994849099b89a9624fdbbf5711e1eb83e508aab11416b35f759e1dfb640ccf4f59f1bf9d2e8eeec393db74c0b82e46673eb002fb0901019',310408000,NULL,NULL,'e936fd6dc98c7c46d2473b412b01402381fed2fcf115e03b9b0b8efb84867df3','54d18abbc37e28ac58af90554ef172f51993a0209bbc7fa20be067c44dbdc97d','4e04fd28cf086b0331e8ec4058d43dd246db519facec2023b1acbeec1cecd077');
INSERT INTO blocks VALUES(310409,'1e0cba7207f81d1fd5b5ba2791e53db73a0b410f43b8a767e6b89277f95519ebe776705ba0debe97ce2b447c6685832664eb0a695c157a668a9e03ec34ead8ba',310409000,NULL,NULL,'85a8bef0d9cd0c598c80cbf385207565eb33738e802a55b05ebe3c2735b992b0','f218212e69548526689399226f39155d28fa56c8ebf51c7b187cd629bafa3ecb','8caf8e27f8c6f3d47cecf60fd13950b65fbbcf2cf5e7684022236a427ec8fda2');
INSERT INTO blocks VALUES(310410,'43da7d9f0a402caeff43c5f43f4dbddd28a0a4df6180fb3bedd96eb471df18896096e0b602a18e513991549337b525325ce4b3b3a5dd22168a14a1208b700a73',310410000,NULL,NULL,'311d85f12d3d6715d2cf27fed172c142f5098119f93b5e30bd4ed6b2bf6f5154','4db180a5b21b197109edc136b0fefe09c774362c2f7ecb8c65a8afde853014cb','23303dca9a790f0603dd0c133695c816a08e6d2979e5a18643ffccf3f611f3d9');
INSERT INTO blocks VALUES(310411,'b687c747443e2b9ae6fbc145dd896cbe0047b557a8fc205286d463ede5c585b20f7f5fae438d7fad4a9914d233f554ecf586dc772ad9ab96fd8b1232415b885b',310411000,NULL,NULL,'9166bd61a0e11fe8163a202ad97c4aca90a796760ba7725dbe62d13f855cdc4d','5cde6f320aadacfe2cd5c8e5ead0882180e70500d77ffbd6115c62e6513b7e81','792a25c2dacef5aec0f8062fed98d86f24f8714db57b07b0badf8d05a62166c3');
INSERT INTO blocks VALUES(310412,'22f5f22b1a3655a4a8356c614875b24e57afed7b81f448b0f082b1007c67a75afe7c84a6662bfd407167edafd4fb90fc68c2898af9bc9faf9b2a2f7823366fc6',310412000,NULL,NULL,'48e9e531b64a1f0a7e78b13fce9720e2f8f2d19d2a32f19af89a89ff10cbeca5','9d2c6249f5e75345ec1d2587be2472eef3504b25090044fce6253ebc57c1912f','12fc064ca8b05d32fdabee273419d5c5024a3e08504900ad7300e8e8e3c6c88a');
INSERT INTO blocks VALUES(310413,'9d334a498eca94282d6630fcd88d18a2392888a0f8029c1216602e345116b7cfdeca4362115fc8e2f01acb8c961eddb12cf4b090a956e06d6a04ac0233989811',310413000,NULL,NULL,'4d77881be95bb653a8e9de8300927532db96dd36500ed84f656ab5419a1c5f43','f1688013427a7bbc1f446b7e548e70954d4b4383d79e59523bf0ee3bf1ee9970','5ea6fc8852ebd11e7c7fbb7f6dfc6b4f52f2395f37bf7ffb5f771456621c364d');
INSERT INTO blocks VALUES(310414,'7782b386cd92d0fcf9f4179e6486e38cb938cbb300a7b1d11689a91dc36a682e9e17318c50c5759d3f14599c2454211de6b8e119759dbfd779340cf0e012b4ec',310414000,NULL,NULL,'2b17a08751adf7a9bbfc3291164c5d3e14714f879051648a3135a210793f0122','24aeb61df63b11c68a3f401086eb3f535a384ea71cd8ccc4144b67a9fb578497','13088f0edfd7d4efcb1ecf7ffe7fdfadc2be23fbbacf2e7e2233e8de5d357fb1');
INSERT INTO blocks VALUES(310415,'9a13274c2d5cfd7a99cb883ff2138300747e82f5bc26511651a46bb2b973864ae9dca8bd40a7187604b935bd5607909c3aa18568609bd3042f95a9315004ade3',310415000,NULL,NULL,'c2bfd47d762fe39b7bdcab83a7453a8af6e93ebf46c73f82bc3b8575247e3964','4dcebb0545c96ca8f0d0c41ae5426dab53c66904b177e09e78ab3650d28d576e','ba69be176d156e32b635ce9fda8a078b4629706329647342aaaa57897fced6ec');
INSERT INTO blocks VALUES(310416,'6c58b891a05d796a69a56b0be77df4174809ea3ca82d1ffa40b95dfdbcbf8f06afa8e9c75b744bfa1dfebad0a3bbedb842c959757b2e884d72533942de971de1',310416000,NULL,NULL,'fbd7cbe6416d91a092c34ba0bff5d4a59cbb61e4ca038172f06a9d12e3ec1e9f','b36d7ec0777f7e745420281c92f911b5f3534a2d142fb20ad361bebe3e231100','4c6438223d9a6a0b65dd421751ca94900d9dffbaf13d93321736ab211d26f700');
INSERT INTO blocks VALUES(310417,'da307e407cb38d53bc7e9a8ed9ff477ab9addc5a029e4e024d8975f2a705f0b3872e102a92cb7d183154229306f72cf58156093ffa339f404c67f8be3d988ed2',310417000,NULL,NULL,'98a639ab6d2a44e0c68cd2b2aa8d2148b6045a5e04c76597ed0f13526699bf3d','b27e55bf20210b579435a3468092fc50625e02fcb8eef24a39f0cd453617380e','5535b0badf4cd1dfaab600c2a2db7d9df22ec6e6350cad30b85e03dc7fd8d2d5');
INSERT INTO blocks VALUES(310418,'576bceb5b89ae12f7e493f50906cfb4e6773008474b2cbbb9cb94d90a2de8638ef1d5504e010913a886d75a4cea1c7d4c1f494227a2856d9f4d0ecd3125c06f8',310418000,NULL,NULL,'7d0cab64f8c51c6d9ffe47cbf00959d95d5792c8f87472d1df3d44a4f932808a','b01d8455729acd3c374f0c465f523f5ce3135168266a326fbba69a345518dfb3','5467cafc92f887d1b56d5b8085d82e6356c2c248444ec228f4d3196ff16781b7');
INSERT INTO blocks VALUES(310419,'0e82af01444fea6b8429d63eae0feda27f0504b8f5632e1121e17ef42d24dba60ef17efda48308beffd5f6d6b70a58abe10fa6b85b8e10db8a17e8572d6ff5df',310419000,NULL,NULL,'86eb1f816a450a4c2cc5b5ccb0b0e3508d978860992bd225d69362917cdc3060','e36984b506e514534cfe0cbb0e5737df08a39dab20a0d2543f26473bc5432b3d','875c782bf8f3691cefab880f77931f0badbb849c952c50316a48db02270f83ca');
INSERT INTO blocks VALUES(310420,'1056f8418f3ee73e2e3ae70f039789eaa32ddde1df728715e6e8698551d857aa309b7be1b26534e8954a398cfc7321716083e89826ffb41897bccf5f943055d7',310420000,NULL,NULL,'f47b001406204c26a7e65ed316db21deb0e5d96dea122985617bffe511fa3fc4','f0cf4105557de33e610a451ab88dc643e2a2a3669c17d6fb479a700ce66d4db2','915297975c8c44e07b173681550862e5ba74e90914d38827aa59282029e52135');
INSERT INTO blocks VALUES(310421,'15ec5f098545ce28a31d2a6b57f63d3674675576e44995f98d0183f47e4abf84a7f5047ab912521e81f4e1d3e7ca8cb97139742879c505ae40c6cd561709ce94',310421000,NULL,NULL,'1c12fde4834b9eb73ddd0c594e203e3c5ab6358450cc094bf265b328639af2f6','16a1a11da081ded581ffaedcdf14110ba745d4f6f7c0bfc3700a274c8418b07f','a39ae7a843ee9d058d6865e0747cdabd09bd97b756c47d23f74e76b0309cf9e3');
INSERT INTO blocks VALUES(310422,'ffe47629dec44292e515f6fe62761595ca13bdbedbb2d9d53f43c200de013ef8816f333a3506b827148da7634365a335e408b6fc559df2bc658ad13d90cc9ed7',310422000,NULL,NULL,'1e8cea92b0e9f9acebb7dafa6c5873338af005dfde8650c2d12c4d8353c79d16','a3780d02391c5955320175e21adab054e31677ec861a62b0da6fa23e079e1180','1f8d07d057202730b04c28054cd980cd71ae6c295ace694fec1121b28e37f425');
INSERT INTO blocks VALUES(310423,'34cf9b59257fce62659ae3f5ff57a6f3f5a3d4e34429cdb856ea1cc7b587ae115523ffa33df176f41b3e224c218aabc3af8176e0d25c73eebe1bb0f3cb3ce60c',310423000,NULL,NULL,'65de78ae1ceb535fe5a6ac21cea482b04632929553f9184edb969babef7a144d','8058b4ed9fcd27736eb3591c40d4d17d590419a4af59313b5d427a1ed6e46bb6','3ece1fca10ac96b07d0db58a9367140d100dfd3b9ed1528f641abddc8527d095');
INSERT INTO blocks VALUES(310424,'cdd558c1a30cbf860697d8bffe867e38fbacb89a587e565a0c05b99ed90fa4871bb63c19241693f10955187fc9d30e798bb7734307bea6435196ccc79a1c3134',310424000,NULL,NULL,'d5c2b2564637af9bf7152d7d545ce7dc2ee7ea4be09ca280ad288d18fa0e656e','7eab0e382478916b72a9b4bc3f82e7912fa420227811d4cade02e3aa7397ef66','f8afb6e048ebca7e7c98ff5e1bb71973aa3ebbe3fd5d8270445cc6b2f502342b');
INSERT INTO blocks VALUES(310425,'7d291169b734dcb983bb98080ddd3c0b47698a4820ef8d6cb86152a7858412459623407abe935b3e362af8b5ccfc9fcd91628d48ea2032d11222b115385ec1ec',310425000,NULL,NULL,'cb45b5fcafc43330bd16d299750c55ca4a3da74b292939f1b7d6a5d9eb27d2ae','6a29e1a1afad6bb4143d90385d8fe25c5f0fbd70f56871eba44f78b3f4c6b208','029a7e609dd859ddc5bde420f014456b802b5f5b7a19afe29cc6d5caeb5c906f');
INSERT INTO blocks VALUES(310426,'e260192e2d708287d5642aae40af7ea517546d0cf9856c8b83abd61005bfa2f4a89d8d335c33c59a5c53160c195053f2b9126e78a185914316c2787301dc484a',310426000,NULL,NULL,'ad658fd9d44a6647fad5b60aba7634df551fe3110bb55da35e74d52cc1b535a7','56e96a5239fe27abbe1d5010ca64c5233ffe3ef174f338525e3a54ae0dc9dddc','1ba89847a21452d50470e6788d1b6ddd66ac9401d7ba203f72084cb4c84fdbb8');
INSERT INTO blocks VALUES(310427,'5fea24eab54b2be6ab3c00b04d11b3d0873aef4ad9f6b5828dd7d2879b24d1cc5ef8e8cc0b9642d08862584c2b0cae6ae5eb38eb6aef38f1035618b0146ea076',310427000,NULL,NULL,'a799d2c8ac8b5922710ccb8de174c954ab24a589f94a3700cdcc8956231f496b','a6a46461d70d8c0804e518121e41deeb20773dcc9e596f670ccd390e767a4986','d1de2391c012c1016c6eb260697ad68bca6d6f8e58a3b85fb3b9f618401b652c');
INSERT INTO blocks VALUES(310428,'a18394d49c5f7bd594255e8d051544740139a07319dba9daa6b2753eeac8a5803e12f401e01a822b27959797b4c28434d0cd632c193d37d894ef940165859a47',310428000,NULL,NULL,'3558a6fec0eeccdb48898c639fefced5a7745f7f90673cff0c00f96550902daf','9ce0409f5be9e0b4830e8f04afad7d0dfe8696baed72dc4e3c15a57ffdcfa66f','1ca8cf81234612fc3e72d257c24431be2e06adcee4aaadaa8b83ccd15d019f17');
INSERT INTO blocks VALUES(310429,'1b101a7ab8ad7d785f703bf1731c53bc2b4e4860ce5fa9cb0bb32b35d263a0614a31585bb4ef3c57e8ed8e9d58747928a7919d60a982cff97ce6e127322795e1',310429000,NULL,NULL,'c1967c2dbba9eaca32d97b0233bf320a3218efde1e91af16207afb967efdad21','036d737726d6694fb852faa4fe20ad94b78f4e302633746f63015f92c0a9214e','93dd89e69fc8f1acdd25825fce16f8b3e95ac5f8e814467a0dba23d7391bb426');
INSERT INTO blocks VALUES(310430,'441f2780e43d35c8abd6e36384c9ee1104e9c64a98efba58016a439a3165c9e67d7f8dab3cb8b7a58803103a5433fc6a1f416c1de00ead3de354acc818d832cc',310430000,NULL,NULL,'41bffb02fe8b5890bcb19eacac09f45fb0eb8bee5f2af37dde40eb54a3cdb1e3','b8d94f645e9da70ce036efeb42efcc36ba0e1bcad7fa062077aff8d480a66982','43bb753d33f34c5e732b2d33af675c62698846dcf5bfca61857ddcd5041d32cd');
INSERT INTO blocks VALUES(310431,'70797615910255131a48c8f57dd0187ea1985d7de08546d96fa4b4202e127a0e8195aa76ce7cf2370b1b40ed5f576262b785a4f5b2b117cd5bd22c32ab670cdf',310431000,NULL,NULL,'bc48c639b24b0894db7b172f7a5ccc3f9b61a195422e8fcb3f2157aab79a2230','f67b19c5644274d98d86f891b88bf4be3fc11112e810af606ec4a67ca82c94b7','3ceaa75cb694e093b0dba0ecf99449a3ffa06afc9c4434f459f3bc75e6e22ded');
INSERT INTO blocks VALUES(310432,'d1d2d773866ee4381232e8393f4fdbace8d8c0119436cbb9275b895d6bfd6756dc19d2aef78bbc1464ebfb681ec3d893638b869d8c0cf23a75162ca3c837ba8f',310432000,NULL,NULL,'fb087173aadeeae847d3bca40b64beb07fb73afc2d1f7b05b129cdbb0ddd36ca','4b03616486459f2e3e0680fd03278f82c667bede9e2b541f83439e4d7f9f385e','51eac1f9563b2dfbc7e70f93f7c6688b3f935a8af6d6bff7b7e689705342cb0f');
INSERT INTO blocks VALUES(310433,'67984d7f40300c9747a2efbdbb0e1447d4642eb42865562f27ec3d3db786e18f4a496cbb14ad8ffb039f655733b56cc3705c23425f584dfcaa81c91c36514d75',310433000,NULL,NULL,'55215cd2cbfc7c0e721c9866f8b279c6f174893a002a4ac8df874a77e71d3e24','0d8542fc4f42320a0e0c8a9354a6f0318d7440765a480a63fe934c6db3d4f8e4','992cb574021f1a9054581fba06a2c3315e62575ceb8e6d0edc6af0c1a44895c7');
INSERT INTO blocks VALUES(310434,'6f30d7a69d792655279266c10f45dc984fcc907d91475f2e6b8321220eb78f9a7a8e4ae2b9fc8d8c5e3f25abd144ef1338e12eeab4b9901f11812f15a64fbde2',310434000,NULL,NULL,'61c41703a9be927fb3067ad797c5a321209f8d3e3d9cba852f814328897234fc','af85943c890caa6ad31e0602e6a1f9ca20b6fa9e7ba4cae6e81b31044d0fd71a','c47e19517b0f8414adda755ed07a143bdaf4a8306f848de7b0b0be898b35f228');
INSERT INTO blocks VALUES(310435,'a9a0b163b028a20dca6bb5564eff523668f42b46c1eea48175cbda13315093ffe6e6445979c05fd90814a65ee8e01ce509c5242e09d957278ad7b81d25797a38',310435000,NULL,NULL,'055cf8752aa7d9c73e1def5439bd40f7f80133bc40ebb08218023a907d8327a6','8ec9167a4bce69696a0cad2bd3b9eb88649dec9354071da26623fdec2ec24358','361d260f477751cb0e026feeb2fb4169dc85f3bc736d1d52ce0c4b70d5adf6e5');
INSERT INTO blocks VALUES(310436,'c8ed150b76f2b615232a6fba7b0d9ae5fb28b33c300dac84fb7bf2ad0755a26fd8b2a911df2d329a47a0c488e13df0cccc7ef8ecf48aae995ba0c03f08b1c068',310436000,NULL,NULL,'529644fb52102161b9d7928122ea4f10103041d0bfdf4a1dc8c8b3b37a0a84fa','856ecd5df8206a0f73dbc81ca23c61c864cafd8b80763cf24d9918c7df669aa7','6705056dc5753b1c7d9691a1b5dac6c9c8989c83040612865f41043f727e79df');
INSERT INTO blocks VALUES(310437,'f6d7615d1e012db1bcc2eea1b80f39f8ba569e8d0f8840118795f8c2de1a91a2fde2731cfe29ff8c779ad1b40809bbb80372befd54327b5ffeb60ad67437f77e',310437000,NULL,NULL,'bb84484177a01ee663ccb3ae51c67afdcc39ad9338e5a074de3111ef05b4a5e7','5b488f185a4fe46a6146d0ac048fb4cbf1bd0e7ad5feffa4b282643617b5869e','bdac04243a5170f41f174e593ed8e34ba3ac50b88f713d18cbfc0a21020c2572');
INSERT INTO blocks VALUES(310438,'ff7dc5d5837d765686f0f08fa01425a3525d6077761240cdd5cc3f31ba43d0c96c99e5550b7b0af2129a0dbf8d9bcf06e34de16fe9b95450ec08dfb365ec4e1d',310438000,NULL,NULL,'e3b5fb6d1c1b1732659c2d4796dc75ed31b31e6767b1496b853851b772975bc9','09db7d9446ca9e4c15b9a2f962c899624041c526fa64c5a25c59d95b9e4d9430','73e8e764fff2ca83da4bfb6a5f617d040fc232095d8858c2928d0852716081ad');
INSERT INTO blocks VALUES(310439,'53a29572310a9beb0a93920f4f53ecc518a39318947ab914bbacd10f8eb3f34ddc9744006c487cb9a3a4db8afede9c8555719bde20be8decdd97dd32917c7fc0',310439000,NULL,NULL,'fb959c2880b4b2330ef34a7d62bcc08d7a4892d53388e4cdecb21fecd2918068','e7871b577c3d5a9d48d2d203a2fad80a2021cf852a5112db608a7878d40ad8c6','b5f59b9d4c5f90c3851718c2dd0eb86628f55e83465a62bfbb1d72eeecd0f720');
INSERT INTO blocks VALUES(310440,'27be90ecbfdd8f865e1641a461a898e84e83515ac047622edfe7ead4a02fe0eb5e10f8fefeccfb0b5858e1b3fc9a963da9a08ba90793c7925f0889608727375f',310440000,NULL,NULL,'42291314818a4c1c2ef74f3303a7c34624345ba848c4ddbfffe7348029387be0','deaa1ddd466cc25c303c2b1bd8f0c1005901b06d1d87c96a628ef2b0bc6fd7ce','fba461795a814432f7a62a9775f5c0564505823cd3b22452ece1d358d94b3765');
INSERT INTO blocks VALUES(310441,'c90612bc5b434c515ee28b0e4fa24a21fa8f52e4a4e9b0b5bdebb70cdc8a0b8a9b71f4387fd0c06b92b9015486a46dd7a655676dc177efcfb18a5eb7e78f8101',310441000,NULL,NULL,'1b6a282bdc186f51eba4628fb9112a9a702a1db7ac1ecc0d175ea14f1d03c099','ccdd49254fcf8e49d359dc6eada66371ae688ba8f2d532cdd262300f1c44c334','14fcd8994cd59608357ec7599285ebdbd42ff146052a5262b47ef1f7570cc1f5');
INSERT INTO blocks VALUES(310442,'67765b8cbc19080cf9c5c7585c1445f338cc0f5c9fc9b99607b28326811e589e065db8b0e13af320f2287384f26902db67461992fb2777ba9d56f6c84037ce2a',310442000,NULL,NULL,'3fdb2fac5960007515bb54f0d29679ce8775326cd965da8b8a2af63a3c794091','7208622add175727462017b336d77b19395bc01f3cfd7d02d279d242cdbdeeb3','5bc1293aadda01b78e1ab4a981b8d3cf475cc715dbbd0c1505893c45dbeb4667');
INSERT INTO blocks VALUES(310443,'a8f6260ac5bffff343cc564ba7408a59f2ca854cd9789e9c267279df5fab33950c077e3a7e7f0c3c15f6a81e88314a149a0338555b67de2487d61b4d41d0d58d',310443000,NULL,NULL,'8a887fba4dff578b2c3fd1fb9e012d3be61bc80be217d5e99bcd24a2f790cf5c','7c83bb451d02953e3815b96937d70c289db15f9379027ca2f42411fd38d7f1cf','a3718e99d9cee4f4959f64e5558d366b67858c23a88be0b65c032785a6170862');
INSERT INTO blocks VALUES(310444,'95ea73d35c08423022903aa5c07d1f3f3b09395b278fd389ba9863f3072bc50dcc0c23b0b294688a4e6d7a17abcb41d2da63fe35b94aba0578c3cf36b14a358b',310444000,NULL,NULL,'8e1c7d08cfcd3423c3bb08a5c60525b2a97f84e07b55b73d4841d23b4ca6f248','5c10f7d506e7f678322224b72fc373c746fd243bbe9937bea8692b1455291902','ba30cae77421c4e291b00fdab0d2462dca52ff8bdd1a6520b4dffe796d0cb8d7');
INSERT INTO blocks VALUES(310445,'1c98890928c4de0b4dc1c6e0cccf01d0c921dd5203e45e0dc2f1cf3e6ea7a339629d8a8f67552723db1913a7e7fd2aa4c78bdba4faf0f32c161fd852d9246eb2',310445000,NULL,NULL,'807322938507478d9cea774942240adb39094a5b4fb1f7125e94bf9e8acfd593','46406a97cf162e349afd180c4ae26823a535206f8a8c0819eff9f6bdef5661dc','e77eb8ca3a4b66de6daf5197971623b6d32a7c5bdcd13464121ab726e8101bb7');
INSERT INTO blocks VALUES(310446,'8e3e0565eb0ce9d14227549ba219124d0f7a4f03288b84fa0ff808ee3f3099275ab84c7aec8afbb0b192c090a9f0507aa36a1e5145a05c82cf01dcb496b7a702',310446000,NULL,NULL,'9258b305b2a347ba6252ced52f772890b073a916de709810feece5a5548007f8','9e515f7c1d96ceb2dcdc3338e927edf1542fc8ade0657707f31f6bc4ddd9cc7d','79b3f59d76376068269932761a22cba8bebd183774027da5b373303b26724dc6');
INSERT INTO blocks VALUES(310447,'ce5557423db4ee33640d2c3d8b937fce3b13be6bb52ed271e861abd1ab330891b581f2969c3f8e1e485d426682ad90f6101913302a51e87eaca308e27983653f',310447000,NULL,NULL,'5516ec73e14aaaa561951c4d689a158f6ebfbe528e923fed67e99208809160b8','69de4f813ae7021bd8e4a26cf28e8764fb0c10c47e0ef4bd3ef13ab6e3ad4d4a','e9950ae4f75dcb42bf7ff15db77fc7641fb7e4566d8a9495936b831374629bed');
INSERT INTO blocks VALUES(310448,'bea6b820378cedea8f9b80e03060bb3b27fff3e03d39e246a69bf742d39d85a676a1e2cf9c1af8ffffd2fc8b514948673620a12a17fdefc4dbae372c0fdf1fc7',310448000,NULL,NULL,'457a9384601eeb2d36c6a96b930b387886833ef4f68be5f0424c319557cb5351','f7ab356e18788a909ba3a23e06f01b4f47f1a7f908a3fe45302ded6d1e536975','abb3f82f96db60a217d28041e716a2dcee310925257f6bc6aa48d399db7d5fc8');
INSERT INTO blocks VALUES(310449,'827f02554733bd9cc66150beb2971a093599e471766c8df7e795c2feb4c6805d7078b6ddfc71c2007f190130297bb4771d0cb5acc95e79ea17fe9323f6fc3f1e',310449000,NULL,NULL,'c659308366412b6e660f81920e1180088d5e0087bdb01420a99498a645143684','fc61242dbac8829ae87c441c9cf9e9aa624f0e35243075b1cad55a8f3762868d','93dc75a0c0747bec205682f76e8b8294ed084cca33c5990086b9831198498557');
INSERT INTO blocks VALUES(310450,'d2eaeff1ed36dfb25526165d84bb408dc3e3c78656da7949def5f5820fe952fab17658863002e5bcf2b3f0453754a32cc9795beaa4a4ce515a68ec567db75c9b',310450000,NULL,NULL,'d3aaf1f7e356a51d2069c93e22ad8ce61c6a474b710c70a5758b006f0e442680','17c9ee474e8d6015a6c947502e4efe2a57cf8479ba07d2e073093b1fcd69c480','b7d75fb6debbc77fc7b4fa11d84372d1c4564bb1835fc01e7eb66f6e1267c402');
INSERT INTO blocks VALUES(310451,'b99ae820d877b82d457cad56ecc061a8b380d027e4bbb40399ac6bbd9ee5f3b7490ca94c6ef64eaaa21ebc3c65f9bdfa681d9ebf734146e4b8500af3c35923cc',310451000,NULL,NULL,'6c42429424444b4f21497e6c7bb0c09760f613f1e40c584b16722defbd1d74f4','7f54ff698ba75354f7b9e78d8fa93e29ef24d90c9843fbd822e6a1518eeb5094','a864664be6ce9385664d677a326cf5739fee2adb781661766c2ed810a4dfa1c7');
INSERT INTO blocks VALUES(310452,'87af378fcd50ee3e6fbdfe41d32b18062b04794d3849ef6d89292e1a9f4edfb9faedc966b8bc84004c50190aed5e2a7062315bf2a3e473dd1dae8f1745419c9c',310452000,NULL,NULL,'367cc59fc4f746d05916e0af8a3f49d9f4b73a5aba8f8955942d608a326b22e6','205a552176e748028e39576a85b555cfe09f888dd3e2b3e9fd8edc1913ab4f1d','09ba487791b38d6a7b90d08967e17d4210038f74f3939b7dcb628f92892ad033');
INSERT INTO blocks VALUES(310453,'39d3266caf86330e14d8098e7cf3a250c141ef2155d6e076119dd569bcd3cfbd30c1b54ec23adc7539d667699fc183e63dac64f43db02821c641633270e30bee',310453000,NULL,NULL,'3a7bb8f97dd555853b330df6d7857e1932e2869d131434cd60401ddbaa0d2ee2','4b57c8a6638add6c72aa1b62d5a402716fcfebf76838c45f616ebbdd4c26da35','d967feca7c6d6537f61a0e09650c7c00c6b4ab3589070e2906d1988fcce766f2');
INSERT INTO blocks VALUES(310454,'453655d834123bf3701e7fbededaefc369536e4ab68476aa860b25f91cacedc740643bf23a411f66ddff983507e388085ec4d12e92071f9e7affc68d05f0f207',310454000,NULL,NULL,'6e16ba5a26add5e1d3f60ec807f873300c8acfee04e03b6e1dd41ef956f91a04','46c816b4a69dcf3eed2725908b5f662daa629e0e334a8340d7aab5091b57fb53','0c75daa6e7c6ef929efb5d61de0cf532062c519abae7573c52c0e02e8b965252');
INSERT INTO blocks VALUES(310455,'8cf0d0c5cc245c62c93d65f012207110f0599d5101c030c339286d1b1ee47d6ac62cdda6e594b812af3a6499ac6bed676e6e9b5cc78f6fa6fd454b078882fede',310455000,NULL,NULL,'83f9c7dbc14dabcd6ac3806803606a447c7ef54ff2b59a92d981e7944a6ac37a','4d360719192dc217413c32aa2febd9ec3744d5e34cee0908ffe5f8b91f10276f','1d97d6704fd505d874f0e2ee2d554c122499c67e8715e536297f34224104256c');
INSERT INTO blocks VALUES(310456,'e9c44fc9b8b02cc15bbd278ed2eebe4b0a5d8acd4e5ade20114f6bf7c98b759c1cf8b4bd82a9768edbc84804d4852890e13cf68b51409ece90b7173517566d37',310456000,NULL,NULL,'bce1b7af45bb8cded67151f80e7aed34fb92da11797bf23620fb9e8f45dd9ec3','1eb6bea266989b28528048d96b8203a497f8dc4c1aa230157104db4b18db7a67','8f440c2b239fdb217e41976cadb6e218b041f8cec138bd62e813da30227acfb9');
INSERT INTO blocks VALUES(310457,'227e805c488c604445dbd1ac0b23441119d9111cfb891a9d4e4b5e6b3aee8df51c502976dd53831b0dda68ba51f0762987253ee9752dc2f504c0ac8858bde665',310457000,NULL,NULL,'20a4a8879391af0798a9c9bacf67279b270cb05132272985d6399505789f7524','51e7557dd58fbbac0aaddec765cfb81f52f9cd16aa9ea8d57f0bd904ae676f6f','ce10f37816e15830bb125981cbef9fa91068587a9e59e2575bbe41223d079e09');
INSERT INTO blocks VALUES(310458,'564b0e3c71938bae220b18c82d7efbd2b9cc4d04b8afbdddbff3a9786d998ec875eabc22fa71ce7b5ea9556da9ae415db6925b1dab816d6667efdac1ea9b6fd3',310458000,NULL,NULL,'2672de5bf484fd89ad0f32020212b26fb2e479817e3a92fe07238e19b582a8d7','5ed5c094da585d9f757bb073057309ac8eee406180e60bc52f573c8b888b048f','40ea122172f9266367d0479f561ecf405f6899f261b8dc9d7827a11987883ec0');
INSERT INTO blocks VALUES(310459,'255c3bb3d2c5102cccd491053a3cb801fa30f6d19e14f6d1dad787e6c8f6493a98437be8bb18b64190dcfe20fbd6131231e1f1a33c299b28c8bb78dcd8dc28e4',310459000,NULL,NULL,'0eec9192a0d512cde33c7a0c27d39c5db8ab00d18f25c25912dd552a30f497d2','2a56c14d5f38f019ec4a81eae709a20bbac0583627aed6f5ab24430b71ba6ad7','16496cd4e9a33425d429f2fe0c1219d223fec945106419e255f59757a537feb3');
INSERT INTO blocks VALUES(310460,'526dee0281cffcffb609a0512950269f7561bef8195041a2f1a901304e106f76e621f6c11fa5b8dcb8e3395b3133687e716f18f31f5a79747a649c067287cd2e',310460000,NULL,NULL,'7cee9c189d1724a3b7e19e28ea59e1ad21b659fa0ffc346dbf1e9acf2c23362b','4a127874eff7267fc19235ad8b66035f64d2d79324e3f6c39e529db9ad7c467e','f66d51d7c776bb27b22e9a88bad58dbefb4aab42088678c8c43c04f52db56c13');
INSERT INTO blocks VALUES(310461,'6d8efaf9519038da95dea69cfa10b80dfd70374253d830ae26f403a5af772b6b97db546b8ed1cba7306b5a9711bff65ad96b306ca441e6e8c7ec9ecc5b1fcb6b',310461000,NULL,NULL,'da7c9090f13a1a4f020bdc7181d7c1251ac2ece654a51046086675f4fa57650f','731cd17cbeff8f976db2c0da8683298b42eae9fb748086de2bfddc6b3d0fd9d5','7a2d5a49e237232fbed5a1468e4a9a2f7d85e13dc3eab2d012cc29c6777af51f');
INSERT INTO blocks VALUES(310462,'499256a2d3fcf5f55cf6c5cef4019977dd3363e0b3d4e2b720c4074d54774d3152843833b43ebbb95d524ef1d650ea0993e5835e24ae9879256438604af93dea',310462000,NULL,NULL,'b25ba679640db9702ea513568c0df0b0fff23d298bcef2cdf530df79a259c69d','3fe7ae9019184a77eef062247db0be5fb39174964bc61a90851952b680006876','2dff52fc101a780f43bdc234338bf2889293efe80cbd308c45e6ae20448c7a8c');
INSERT INTO blocks VALUES(310463,'9acd0066d56a388ad521a8e3f04226009a47653eed7ad34ef5eb37a43398deba496f6e451e35829d2d51860b8cb0b2b3f8e74c7849f416a5fda39adfc4de75cf',310463000,NULL,NULL,'456b82c0ff4da1ad0db800af5255f199a119083fdb4a0e9db76e060d46643f7b','f9be6d5fe322674fa856dccb343e63239eb812434e99a31e9ed97342e0948a53','c03960553ef58be52aae1281c6acad23b98684a106ef5850118a3ec73db32288');
INSERT INTO blocks VALUES(310464,'5790232ef73149532b55970e89ec58b781c7673a0faf7d972a45a2c4caa8f05ed6aad51cff4c33b9e5ae4a54355770d9d02421fdae0ed5da66a99f0d2ac8ed09',310464000,NULL,NULL,'679753064753cfd09e21ae9b73d9a6130e62fbdd45db9cdcf714250f779e0dd0','fd9dc4a1ac0cf342f29c8e11d2a2e1228e7b688d8c679ca2a30b98f94e01222b','7e5148361917c55429004d172ff6aa0821d1dbedb840a98b8f928d1ee0bddf19');
INSERT INTO blocks VALUES(310465,'9bcb8cc611f27f7576503f00d8839c784c4fcb95d0ad30282ff7e6c5aa27b0641c43369211043aa2fd8664922d5c226718478803120a06e2ea171a1a5b0663bb',310465000,NULL,NULL,'e861fc0a9aa1735a4e1993ffb042963a12409095e2b247c241117fa7a5a82b60','5e42ed27efc1883dc35d42962fc7461dba7883859527df1794a6cc666a84b82d','5cdecb384a3491f7d0fcc168be9127be02ea32326c43b90fc01ff3b16a612dac');
INSERT INTO blocks VALUES(310466,'0acabdaaac52332db83e63d5d7202a9f94d6e9184c693a4dc3c20f297142faeb634fef2f8b8c4fb29997fb7e0760a16f63c08aefb0bebcd7c4e0cb533331a6e3',310466000,NULL,NULL,'7f41af8b6fbc5e5bc8b62e763193c2407669e556d85a24d285f56d1d18601e5f','ebdeb7fff17ebfbf1e43e160eafddaa8e733483582cd7fc730df35273c2168e3','728c6008c81acd9b5c6b40afd0bc2d53140d44ba92d34c4b303c61a3e4d0c69f');
INSERT INTO blocks VALUES(310467,'bd5e4e06e5b188c11dd3f4ad36e34d8029c3fdb9e91d83ccbe312e9f0a904fda44fe0f594b3498bb8165b0d7c3ec7616a8deab38b9e3c183d1750a81133813c7',310467000,NULL,NULL,'2f001cd4163ebf72778e24711d4311149b2d86d87370d97fb8890a99d7e959f4','b36bc5db60fb8c82c7db865858bfc2ef47ae1763ddaba409b1a85b527bf2586f','7cfc42296ecf6405324bfebbc81622e2ab4fd72f2c47432fe0584acadd206538');
INSERT INTO blocks VALUES(310468,'0a6013242d3cc444bde42c36b753210897e5f23a8faf9d920e178b1158454af0028148ad673f3b03f330fc7f9611966cd9f60c404967756f1d1558866c58ac17',310468000,NULL,NULL,'5d4368682e7a6ebd8afe448fa89f339cd0cb99454be154d60b7f53cb417b2016','729bc03b1c4a3a338ffcb546d327b924288de5187d4ec8385c99394c325f8e86','19f62ce7e13f739d9cd06dd0f05d4fc357a475c34131505d27e501a08c86eb89');
INSERT INTO blocks VALUES(310469,'63d6779e475713b55fcaebda8335a2e4705e53b30a432061b489fd5b02a6a5c32d1591ae0416f5baa886aa3ee407dd9e79b6fd8032f90e895714964bd5bef2f5',310469000,NULL,NULL,'16ea50049b80b012f7620875a004592cd1d3aecd1d1932453072c616ae1c8794','5f8ca35cbee9aae8d32a5c1a4681d4553e5f9e224f54dd9945f759bdb67bc57e','45d2c4993624c8f0409358e5dc1192025841bea0af8a5e72c7d18590fe1f7a75');
INSERT INTO blocks VALUES(310470,'34d879d68d928ef3a0be963de412685a9742b45df51ea6ffc8d5e64d892514a845501e0296911467adda8afbe053372952c17017198f579049b914126594a19c',310470000,NULL,NULL,'9719e4ade80636f6d6a2474dfe8d5b354d97816d41406e4fbf929e23e70b400e','134aa7fd8dac9920387b02c609cff9d65558c46d7303f0758c1fc5f1c43c799b','ab4f685a4d59daa2064667be35320364b25ea0a6ff15ec70318ba2c0e41291b2');
INSERT INTO blocks VALUES(310471,'933f3f1c5f0817256b05cb1d94b8f4bca9690446feb3b7e5ca11ceb44531a7d9f8b259bdff3406ded3844c5d30381b6bf346de7f2384a59a49982634e23d31eb',310471000,NULL,NULL,'2aaf6155cb2a3cd4e5ddb8b34c0ad7e2df3dbef61bfdca807341b81e6876adfb','7964aa518457f7f67290de0133fb3724eb32b813412492dd7892c70e29d7d0b2','25e5e2408664cbfdcb76cf26ebbef0368fdd60177d92ffe98f7f0ee1dc9dcc1a');
INSERT INTO blocks VALUES(310472,'56e16b8298be638e21122615b2343d7c67de861523db614331e27e3753c8db24b9edd51ad26f58d44747737cd1635d1341ca680c0e60c0bd8aacaf50acd18a3e',310472000,NULL,NULL,'b38a0b8c5ca40fc6f0669060c982fc789eb6c12b0fb06590cd27d0cd21201d12','6d9e2953e9ee0bdaea7edcff99f59326ec19c0402927cf703176abd231a9fa32','4822f1fa11e997e98d35402b29015560060a6659a03c288b5bfcea864f4fdbc2');
INSERT INTO blocks VALUES(310473,'c9958774653eb8e2dc39d119c69b4c5a0cd833ca3833a8314c63625e05ff48d15ff72f0b0445e5e2b3db087e6020dbd0caf4efe3c48414b8d3c7d3b1136755c2',310473000,NULL,NULL,'f0849d4e9132476dda63c1faafdc9785e92d8683853375807f431cff9ffdd5aa','34a6f5f2fcb3cd2b984548a87a4471c523d7fc0d1abba740c883a49260bbba4b','6360572b33058e32a729bb697d46ef27df4c7450aa743ce8cec053286039881f');
INSERT INTO blocks VALUES(310474,'cf5e7afa76b87d266035e00ec6d8332d006e3804ccaf8e6d8bdf601fbcb0db2e8e74c831b2cc6efa649e19814dbbda8b84245a4bc5a3cb781215b856b3b3d850',310474000,NULL,NULL,'1302db156727d87fa0bbfcb59a48f7fab1d5ce957eb32795c7b7b8d4e749cb42','598420ffff1dde2fd42b3b89b0067aa72015a0e34e96888e675a7a2290e25c52','c58cf33d91cbc0d0e18a5ca59be6788a484b58896b8cbb4cc0c0725629b220d2');
INSERT INTO blocks VALUES(310475,'0269ce6005cc2f9bbbc0df2558bf402e967e36b929f687210d0cdd41b56c7e83b624d5f1dc31312ae8d9cd15e979f6445ec13ddf2b736d19396a4bd1a8b3069a',310475000,NULL,NULL,'f919d0d889ce778a8d86759bd90c729e6e85e3d53635172852d9a2322c0d59c5','574d5fa4c8ebc0dc4586b2b900457b47a9e05b35d356c5e231867380d5a383c6','9f2b0b4249e783a06ead3578b6dcb26d3e8ff6c66205c3717dd11d1e6a6c4b70');
INSERT INTO blocks VALUES(310476,'36ca5650ada15ea2d14ffdc6aebe9895b41205978a5332c52e32653cec6041a3a9ae573ce9e4b712d15130000fc2d934cb5dab39900586b9da08424c3188e4e9',310476000,NULL,NULL,'e11b2ea57f435335f373c47f263b995c2dade309ccefc8caacbb7032f1c411ae','e2ea63934367d68749271800ff11103e015fea79f9ca34e417b34eb8417ffe66','d1238c54dcad42509ae121c108ab0fb2df85f383d36fc70b389cb6516d0d43ce');
INSERT INTO blocks VALUES(310477,'02b67d7d7112074f51820057ba6231bdca7e4fb3da334078f1bc810286e37bf132ad723509e7ede6ab836a2527939fe8149fe61d6483fc71220c06758a81106f',310477000,NULL,NULL,'19cf7eeeac376d99139a0c9cc78475a5cd8e5f1f5e3d5aaf76182e82a0ec2e5f','706700cbca21209cf3b1fcf4da40bc39fc28f8c26aa0edcef8a02393d5309155','a5270887ba45416a62d77d53ecdbdab3e1e2f57ac276e50b7d7ab5110ffe5103');
INSERT INTO blocks VALUES(310478,'4e715719b479407cd8cf4cbf7b68c158fb0a4741bfdf8925acdab8014501e9cb0a9591f459106339877fbb67ef54a0414d5ed71666cbbdd4211333a2cb5a9139',310478000,NULL,NULL,'0534a3e13f65286d47372dad200527bf3ab3f59d8d0f7fb5baa634ebc7d6a5dd','7f1453d8c628b70a0964da31034e292b9baecf2ae71bea5dd201af56ab377c38','68f589d9bc36ff822f9dbebed4d811c5dfb770891c73724d1e8ba8ed7a3be8d8');
INSERT INTO blocks VALUES(310479,'17fb547b6100f5fa1a23d938e869dc6bd0bbc11f363ed67b27166ec682a8128a5ef646753e01df6b043577bc03fd233d1d2122b3cfd320c97ebd238fc26ac295',310479000,NULL,NULL,'492870e75ea7b75ad244975fe620d20e3a96c78ff62bf6e9f3619c0ade5d3089','1520cc3a2d43c1961034aca4876e39d5b5677ff84e17d407773c858ecae242c0','8a6997013c5648a5ec82bacd4ee55c3864bb7fc44668c7461615b4ebc271920d');
INSERT INTO blocks VALUES(310480,'4fb45d941467e6bce88e2aca15c620291c255d12f9395aa03c507e270d3c85c4f6686eccc2f2ec53183bf4956b5c754428d6bf30b15298c5e9fd1a6609961522',310480000,NULL,NULL,'70144d13f9fd46522e10f55970aea9248bd668f345c500d88b67ed24e94f9425','06033144debcbfd695987102bb057c2f986125cca7864b65458b43130ff2f30d','d3fdf0527a9c4494cdb0e9b7ec2a93575eb5f397b1192b886b41cd653019a227');
INSERT INTO blocks VALUES(310481,'8a8d4a92453604438c38fbfe49b8f36a2bfef0e05c01a7fd4703a4ac24a49ebe8ed3545572560067056532f56ceafe4c8fcd3843b0e02933d03f3ae217a612b1',310481000,NULL,NULL,'26a80593e7acbba2cd3b9a48faa9967aee15cd3d2fad90554940ccb7146f94ea','cb2f01e5d5fa16a96a641081a7874a59f35471890d97251b9f5cda605ee094f3','4c860c046e9cbbe55ca86b2673fb4eb7e6d76647afeaaf68b4acf02fe6efea0e');
INSERT INTO blocks VALUES(310482,'c69b79ac29c827a95204e93894e31ba1a2bea5ec36b803d66ce5918e8c3675aa3afecc015249f65863f71bcfe30d14103017f323b7229f1c74d5979bd1b5b075',310482000,NULL,NULL,'bfef7f297903ad7dc3e7a467a5f2932cc5a18eaff90abf7652e27e109423a2c6','62ae71d7537022b8c0f2f90e67698b423a2a2c31fadb4c697b0b819b778dac09','5849db3958a532506ec844ca89ae8ef4acad36422e1814e8c348e24e69a1813d');
INSERT INTO blocks VALUES(310483,'ff2fb1f86c4c126187292c27c8c5cc16c8192b5118302840de294c26708571c4ca647ce3a58a15641f9f26996a6c42103f1fad72ce7c6d6432eb5978bfb2941d',310483000,NULL,NULL,'4ed93678732dfa77472f501180218bee25242ddef88fc864c95ddd4e34a27d48','ee9b96554dd1d29fc004db9a59e5652556a9ffcf04310b944b198d73a1dc834b','d2457aee2fcec850b8e5325579e65f37d2da0ecf733a7b04cabefe48c8aa361a');
INSERT INTO blocks VALUES(310484,'72ff0b152e7a8e3b03d43a6d2eb6c25c2b55c67acec1950af50bec882dcb28456d60ca80772d4f5293efc2dbbbd3f8d4eff5437318bbbaaff86aca00c74f369e',310484000,NULL,NULL,'cb4b2c5feb2ca5b3262e7b339777727260cf99000d8501ada6428edd50ce7c68','c5e4021eb1ef3ccf5916990f746525245bd9da99302578d85d70b198e8dff2e2','f2bece47b140e4171086c232f51016958f11541df764c386cd3890764f45a318');
INSERT INTO blocks VALUES(310485,'c18768c9be05414ede83933b6914e92ec4db3f9cd6dcf5934d6e515d01bb8da3e6eecfa9ce139b8b8126d0164405ff3b94ee23561581f6ab5e2be848d36ec552',310485000,NULL,NULL,'e2d690cdfbea187b9d2cec7384983711df5bce173033d0dcea835dc8434442af','c1cbd195d6f774014f0ead0e827d0ff811a25ec1c414166c6bfb22858ed7e714','5ffec40997fb54f324ab664a7a01332008c2652454ce4fd6135d97b39cb9d144');
INSERT INTO blocks VALUES(310486,'438e29ae1f2dd687adf04bcba05256db1ff5053c16db174837a5abd79394572cd73fff18b5a474d00d25d07a4b9bab4407d9a79a5f8cf7e60f8cb96e8a2c3c3c',310486000,NULL,NULL,'8fc1feebd2c3ddcf938559b962d7598183b65f33a028290b8e202347598070b2','3ceb0d5747384609d65b65f710276d5238c8f4a6f0e0e1efe8e1a1d745d0c0da','6f4e5a7ba65beff1d446ae703cbc4dfde478058c772108284ae534dcb3add061');
INSERT INTO blocks VALUES(310487,'7a36971ca18df8dabd367528c3d6d1773de803fd7a22754876ecc70e9350e61a2af1f0bd1ccf00715e8c4613a6f2919dcb3382fb0988c236d484f9c5386991b1',310487000,NULL,NULL,'61f4b265b1edbbb0060f6df34529c3bd174ee48a57b366ab2f77c8e1535337fb','067af47d07aac44cbb76dfdf14d5c10a93a260f6ee48e2bd19139a3daa369936','321b4e8bf4d2b26760b0ddecc7804c8caef1a5b36f5fd079a0df09b9d294e973');
INSERT INTO blocks VALUES(310488,'4ed375b4cb5a66ada5db18a0b55c27a494a91475fbe911a1615ef66f0ef0b4e349f8ee6a1ae2ef9a55a7d9e5d136635e589481833901513825e4f27af16cfeaa',310488000,NULL,NULL,'53bfde4087b958b5a60efaace64231bc2f1e0325bd6a54f68b84308619c452df','633593b0834f807be895270870ec6ce831af0baaeea30d983cc8c5f03ed58035','259938bd576affd429ad9316522283da745ca6b9b21c707c2bb01b361854ed30');
INSERT INTO blocks VALUES(310489,'b294daac549dc33a5a26a1ec076d0484b9b73a0623bef8d14980520b5520bca0bed4d95896f29ba77ad6f5212e5ea7ff49a892564cbf5a351b4e4d771cc3ead1',310489000,NULL,NULL,'d2766e8ed22a3ca3bd4c5e63ba30c96f334731998676b56d1089d18bef485dd0','4b165163528e4ffb70f5225d047954a7b5c17092e4135b2a43e10bd7a985c3c8','2fa70c479ba07b34e483be47896115e12fb1a16070e38445813a9fda9cc96903');
INSERT INTO blocks VALUES(310490,'fc18260b36da30e7f7bef925d04c3fa86a8f390f11a64eb6e9731a1aedca69258e0a4cf5bf5e0bfd9876e8118e4711f36183c346397635c0af770c6abdcfe2e1',310490000,NULL,NULL,'1655992d6b3e6cacc0083c5fd06f2dfb7423dfa6cd3cf92a8fb2ffcb979c7ebd','1863a10ea13ccc956b639fca55848a0cec9efdb6e0e13ed256f8ccf888dc1acb','054a1a971b55753107a6acac4a067bffc6967b6c5640b1417ec43001bd49c762');
INSERT INTO blocks VALUES(310491,'bf454daa85f5aa7766a92d2740421d2a69af7dde2a5209852e318ff4c5a2f48409a6c1df9fa33d2bdbef9ddc3c77118f6982b4fe00bf99f4fecbf767ef33fc71',310491000,NULL,NULL,'8da4c161f6c5650369daa319f4edf45bd58e6614db2bf613a9c8cbe02596675a','abdfe0c75d69c927e1765c181695b349340c1da138582179e2f68fe66b238b76','b13e3abd705e1332c8132dce2ec156705bebbd5248cacb79e567451a48fb0ad7');
INSERT INTO blocks VALUES(310492,'7a5dd1618ae6b4bb553d4edc16af2447313c443aa6e31d15a2ae7322bfce7d88160f825ff99dd8429d5fbcf5f2f904e2d486e8fdc2753ba8f6f058390afad447',310492000,NULL,NULL,'ca71ac9c4464875766436ff940d2af6be20929de105f370f4078b95328f32191','edb90cf1c624d038b7073bc3a7f988eb6c5fb92202b24b22497b05b58446bd08','a5411e46b5e085420e8a46e69a318fac3ecf19bf5438ee9a97e641cc074085a8');
INSERT INTO blocks VALUES(310493,'e5695fcf012cfc974506f8b9c6b97f3d2aca71dcaf89a5191fd69d56459a7c7d4fde0f50ca105fe249b13e40556aa98d9fbc4f56c98dabbca3ff9dbc45df2521',310493000,NULL,NULL,'5340836d1a821f2377795fd02dc8522435909c79ea57555b3142e813552c870b','de45428749938d663089c199095ae03adc20161ae8f3feb95eb961dff9dbf2ca','21af99f2d8ae3b614f436804c13c7acedc47285df79e164383c88a927731430e');
INSERT INTO blocks VALUES(310494,'5ea4dd62da28162e1829870fbfab1dc6028d01cac7e541bffa6696059705e33e27d266855fa60ace8ffa9c7bc6612dee1b0e4612e4d78575c847c91b2d3b217c',310494000,NULL,NULL,'41572c2a0cbb35a810d663abc35be401af43f2d37d7a7eaa1338b6e56d8c2503','0a9a1d84675e21eba68665d55bdb7de2b716a52c42a4989804a6b9eb71a8fcc7','00a19847277cb50943467aa1eafe9308c68561cfd9bde761287ddc10af87ce2f');
INSERT INTO blocks VALUES(310495,'14a4d161b11a33ae7890e835206e0bab161693bea0c4647d59ead2d2c437157f3b0178db71a244c0fbc8c7d56de89bd825aa36d1e8b3b62f972e1867b9160a20',310495000,NULL,NULL,'6582f6853e7ee7fd8bcbb5e2f394c90dec4dee452290793014856044a51887ab','589c25c622a4300d6f93d8a6c52dd86c0c849d938b3771acb052095cd40f1431','f4eed2f2cad803d606bc78f74b3c3ba1953133e2556c0c920c6912bc9a9e3803');
INSERT INTO blocks VALUES(310496,'54967ea8d512b2b886a8e5106016df7f323169118a410af02dcdf9352e97b75ca8041441fd4b6af5ea09fff163f0d0e6d2f7a07518da27e6c367216110f316a6',310496000,NULL,NULL,'25fa04fe398499ce6b54e649d2e94617c9054bfa7fd49714c3b4fea38ae1131e','4e36080b9d2c88ff6fef79d9a7c26e880c16b956a6c35116b17f48cb0dcab3b7','aae0749afd7015016e30985b5393dfae50a312f526d885fcc528dd3cfad1a93e');
INSERT INTO blocks VALUES(310497,'366924d489bc84a6b70b134ca2c613cd30e4fbea73f4995249c115938fe49d508e34d463f5a7c26f169be6c013575ff05aa1896a6286611f2f17811fc297eb67',310497000,NULL,NULL,'595f4fefa2680f102b8e61f3ab12dd457d04c581b602bb1784084ddb6584b2b0','18f64b95c4fa5a09f0a7861816de2e1202080f90152cd7853ab027412c9a8543','af5e3584bbeb969dba7e53970b5e2e353e1f35d4b5361644ab1666af6a94d096');
INSERT INTO blocks VALUES(310498,'5a09832472a10eae9b36467b9c39991a47a88f8167e9f51d5a8c227fd226f1ef17c8052852c09cb4fb1899bade89510f5e20abe94e972e5f94d8feeaa5d3b291',310498000,NULL,NULL,'3722905ce8c723c613b67c83f1e3ad27753a7fc2309fa6a83a15a0ed8030bfb6','0e566e6a0a3ef5804e6969f9693e3e7059433508a7cce7d4ffcd6bb923672701','dec369ddcc24d8a92dfbc713e0868ee4532d931d5965bb977fe135fd4ad499a9');
INSERT INTO blocks VALUES(310499,'dce6fcf2b12dc112411e1a4a526d0ad34b23b8b2db7c9be729bc9ee152c95717a9f48808df0bc5224f99f50089c8c1201d33bce505d8eb90a17260c71b4b2f73',310499000,NULL,NULL,'53f4a2f595f8b92646ca904015958a52a6d2e67dbe91f1b30881623b47665267','a4e5a37dea61e486f85dcb5e390f630b5b5e575f4a25c0b019abda89b0dfe27e','965d94d6d035d06083ba947dff37d047871f4365525f0537fb4a6d4ad2c21890');
INSERT INTO blocks VALUES(310500,'59092152cea93e29cdd1c2c7f54730cd2c609871a5083ebc50d59b368f90b25ef2586608da40f790e23c0ee53d8a5b1e13af627b3946c1a7fbb39ab617d5afc9',310500000,NULL,NULL,'bc2a2e09a881d5e382904ee20025c7b0c50006a445ac4635d4282234212429a1','7a345ce55acea2b33aeefd37dcc20bbf8dd6cd98b6b0a4f0697c001f854af85a','73581237adaf4842a9fba69241f2989588427488b3833ed371bc8ca239187b63');
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
INSERT INTO broadcasts VALUES(18,'9b70f9ad8c0d92ff27127d081169cebee68a776f4974e757de09a46e85682d66',310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000000,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(19,'f6548d72d0726bd869fdfdcf44766871f7ab721efda6ed7bce0d4c88b43bf1cf',310018,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',0,NULL,NULL,NULL,1,'valid');
INSERT INTO broadcasts VALUES(103,'18cbfca6cd776158c13245977b4eead061e6bdcea8118faa6996fb6d01b51d4e',310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000002,1.0,5000000,'Unit Test',0,'valid');
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
INSERT INTO burns VALUES(1,'610b15f0c2d3845f124cc6026b6c212033de94218b25f89d5dbde47d11085a89',310000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',62000000,93000000000,'valid');
INSERT INTO burns VALUES(494,'d6adfa92e20b6211ff5fabb2f7a1c8b037168797984c94734c28e82e92d3b1d6',310493,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',62000000,92995878046,'valid');
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
INSERT INTO credits VALUES(310000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',93000000000,'burn','610b15f0c2d3845f124cc6026b6c212033de94218b25f89d5dbde47d11085a89');
INSERT INTO credits VALUES(310001,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000000,'issuance','82e357fac0f41bc8c0c01e781ce96f0871bd3d6aaf57a8e99255d5e9d9fba554');
INSERT INTO credits VALUES(310002,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','NODIVISIBLE',1000,'issuance','6ecaeb544ce2f8a4a24d8d497ecba6ef7b71082a3f1cfdabc48726d5bc90fdca');
INSERT INTO credits VALUES(310003,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','CALLABLE',1000,'issuance','a36a2d510757def22f0aa0f1cd1b4cf5e9bb160b051b83df25a101d5bb048928');
INSERT INTO credits VALUES(310004,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','LOCKED',1000,'issuance','044c9ac702136ee7839dc776cb7b43bbb9d5328415925a958679d801ac6c6b63');
INSERT INTO credits VALUES(310007,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','DIVISIBLE',100000000,'send','d21d82d8298d545b91e4467c287322d2399d8eb08af15bee68f58c4bcfa9a5f9');
INSERT INTO credits VALUES(310008,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'send','e64aac59d8759cde5785f3e1c4af448d95a152a30c76d97c114a3025e5ec118b');
INSERT INTO credits VALUES(310012,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',300000000,'send','d4428cf4082bc5fe8fed72673f956d351f269a308cf0d0d0b87f76dd3b6165f4');
INSERT INTO credits VALUES(310013,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','DIVISIBLE',1000000000,'send','97aaf458fdbe3a8d7e57b4c238706419c001fc5810630c0c3cd2361821052a0d');
INSERT INTO credits VALUES(310014,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','NODIVISIBLE',5,'send','29cd663b5e5b0801717e46891bc57e1d050680da0a803944623f6021151d2592');
INSERT INTO credits VALUES(310015,'1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','NODIVISIBLE',10,'send','b285ff2379716e92ab7b68ad4e68ba74a999dc9ca8c312c377231a89da7e9361');
INSERT INTO credits VALUES(310016,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','MAXI',9223372036854775807,'issuance','cd929bf57f5f26550a56ba40eecd258b684842777dfc434a46b65a86e924bf52');
INSERT INTO credits VALUES(310020,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5');
INSERT INTO credits VALUES(310020,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',0,'filled','90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5');
INSERT INTO credits VALUES(310102,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',9,'bet settled','18cbfca6cd776158c13245977b4eead061e6bdcea8118faa6996fb6d01b51d4e');
INSERT INTO credits VALUES(310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',9,'bet settled','18cbfca6cd776158c13245977b4eead061e6bdcea8118faa6996fb6d01b51d4e');
INSERT INTO credits VALUES(310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'feed fee','18cbfca6cd776158c13245977b4eead061e6bdcea8118faa6996fb6d01b51d4e');
INSERT INTO credits VALUES(310493,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',92995878046,'burn','d6adfa92e20b6211ff5fabb2f7a1c8b037168797984c94734c28e82e92d3b1d6');
INSERT INTO credits VALUES(310494,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','DIVIDEND',100,'issuance','084102fa0722f5520481f34eabc9f92232e4d1647b329b3fa58bffc8f91c5e4e');
INSERT INTO credits VALUES(310495,'mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','DIVIDEND',10,'send','9d3391348171201de9b5eb70ca80896b0ae166fd51237c843a90c1b4ccf8c602');
INSERT INTO credits VALUES(310496,'mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','XCP',92945878046,'send','54f4c7b383ea19147e62d2be9f3e7f70b6c379baac15e8b4cf43f7c21578c1ef');
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
INSERT INTO debits VALUES(310001,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','82e357fac0f41bc8c0c01e781ce96f0871bd3d6aaf57a8e99255d5e9d9fba554');
INSERT INTO debits VALUES(310002,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','6ecaeb544ce2f8a4a24d8d497ecba6ef7b71082a3f1cfdabc48726d5bc90fdca');
INSERT INTO debits VALUES(310003,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','a36a2d510757def22f0aa0f1cd1b4cf5e9bb160b051b83df25a101d5bb048928');
INSERT INTO debits VALUES(310004,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','044c9ac702136ee7839dc776cb7b43bbb9d5328415925a958679d801ac6c6b63');
INSERT INTO debits VALUES(310005,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'issuance fee','bd919f9a31982a6dbc6253e38bfba0a367e24fbd65cf79575648f799b98849b4');
INSERT INTO debits VALUES(310006,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','074fa38a84a81c0ed7957484ebe73836104d3068f66b189e05a7cf0b95c737f3');
INSERT INTO debits VALUES(310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000,'send','d21d82d8298d545b91e4467c287322d2399d8eb08af15bee68f58c4bcfa9a5f9');
INSERT INTO debits VALUES(310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'send','e64aac59d8759cde5785f3e1c4af448d95a152a30c76d97c114a3025e5ec118b');
INSERT INTO debits VALUES(310009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','a9f78534e7f340ba0f0d2ac1851a11a011ca7aa1262349eeba71add8777b162b');
INSERT INTO debits VALUES(310010,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','b6db5c8412a58d9fa75bff41f8a7519353ffd4d359c7c8fa7ee1900bc05e4d9d');
INSERT INTO debits VALUES(310012,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',300000000,'send','d4428cf4082bc5fe8fed72673f956d351f269a308cf0d0d0b87f76dd3b6165f4');
INSERT INTO debits VALUES(310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',1000000000,'send','97aaf458fdbe3a8d7e57b4c238706419c001fc5810630c0c3cd2361821052a0d');
INSERT INTO debits VALUES(310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','NODIVISIBLE',5,'send','29cd663b5e5b0801717e46891bc57e1d050680da0a803944623f6021151d2592');
INSERT INTO debits VALUES(310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','NODIVISIBLE',10,'send','b285ff2379716e92ab7b68ad4e68ba74a999dc9ca8c312c377231a89da7e9361');
INSERT INTO debits VALUES(310016,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','cd929bf57f5f26550a56ba40eecd258b684842777dfc434a46b65a86e924bf52');
INSERT INTO debits VALUES(310019,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',9,'bet','be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd');
INSERT INTO debits VALUES(310020,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',9,'bet','90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5');
INSERT INTO debits VALUES(310101,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',10,'bet','ba0ef1dfbbc87df94e1d198b0e9e3c06301710d4aab3d85116cbc8199954644a');
INSERT INTO debits VALUES(310491,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b');
INSERT INTO debits VALUES(310494,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',50000000,'issuance fee','084102fa0722f5520481f34eabc9f92232e4d1647b329b3fa58bffc8f91c5e4e');
INSERT INTO debits VALUES(310495,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','DIVIDEND',10,'send','9d3391348171201de9b5eb70ca80896b0ae166fd51237c843a90c1b4ccf8c602');
INSERT INTO debits VALUES(310496,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',92945878046,'send','54f4c7b383ea19147e62d2be9f3e7f70b6c379baac15e8b4cf43f7c21578c1ef');
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
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));
INSERT INTO issuances VALUES(2,'82e357fac0f41bc8c0c01e781ce96f0871bd3d6aaf57a8e99255d5e9d9fba554',310001,'DIVISIBLE',100000000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Divisible asset',50000000,0,'valid');
INSERT INTO issuances VALUES(3,'6ecaeb544ce2f8a4a24d8d497ecba6ef7b71082a3f1cfdabc48726d5bc90fdca',310002,'NODIVISIBLE',1000,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'No divisible asset',50000000,0,'valid');
INSERT INTO issuances VALUES(4,'a36a2d510757def22f0aa0f1cd1b4cf5e9bb160b051b83df25a101d5bb048928',310003,'CALLABLE',1000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Callable asset',50000000,0,'valid');
INSERT INTO issuances VALUES(5,'044c9ac702136ee7839dc776cb7b43bbb9d5328415925a958679d801ac6c6b63',310004,'LOCKED',1000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Locked asset',50000000,0,'valid');
INSERT INTO issuances VALUES(6,'bd919f9a31982a6dbc6253e38bfba0a367e24fbd65cf79575648f799b98849b4',310005,'LOCKED',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Locked asset',0,1,'valid');
INSERT INTO issuances VALUES(17,'cd929bf57f5f26550a56ba40eecd258b684842777dfc434a46b65a86e924bf52',310016,'MAXI',9223372036854775807,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Maximum quantity',50000000,0,'valid');
INSERT INTO issuances VALUES(495,'084102fa0722f5520481f34eabc9f92232e4d1647b329b3fa58bffc8f91c5e4e',310494,'DIVIDEND',100,1,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',0,0,0,0.0,'Test dividend',50000000,0,'valid');
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
INSERT INTO messages VALUES(0,310000,'insert','credits','{"action": "burn", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310000, "event": "610b15f0c2d3845f124cc6026b6c212033de94218b25f89d5dbde47d11085a89", "quantity": 93000000000}',0);
INSERT INTO messages VALUES(1,310000,'insert','burns','{"block_index": 310000, "burned": 62000000, "earned": 93000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "610b15f0c2d3845f124cc6026b6c212033de94218b25f89d5dbde47d11085a89", "tx_index": 1}',0);
INSERT INTO messages VALUES(2,310001,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310001, "event": "82e357fac0f41bc8c0c01e781ce96f0871bd3d6aaf57a8e99255d5e9d9fba554", "quantity": 50000000}',0);
INSERT INTO messages VALUES(3,310001,'insert','issuances','{"asset": "DIVISIBLE", "block_index": 310001, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Divisible asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "82e357fac0f41bc8c0c01e781ce96f0871bd3d6aaf57a8e99255d5e9d9fba554", "tx_index": 2}',0);
INSERT INTO messages VALUES(4,310001,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 310001, "event": "82e357fac0f41bc8c0c01e781ce96f0871bd3d6aaf57a8e99255d5e9d9fba554", "quantity": 100000000000}',0);
INSERT INTO messages VALUES(5,310002,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310002, "event": "6ecaeb544ce2f8a4a24d8d497ecba6ef7b71082a3f1cfdabc48726d5bc90fdca", "quantity": 50000000}',0);
INSERT INTO messages VALUES(6,310002,'insert','issuances','{"asset": "NODIVISIBLE", "block_index": 310002, "call_date": 0, "call_price": 0.0, "callable": false, "description": "No divisible asset", "divisible": false, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "6ecaeb544ce2f8a4a24d8d497ecba6ef7b71082a3f1cfdabc48726d5bc90fdca", "tx_index": 3}',0);
INSERT INTO messages VALUES(7,310002,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "NODIVISIBLE", "block_index": 310002, "event": "6ecaeb544ce2f8a4a24d8d497ecba6ef7b71082a3f1cfdabc48726d5bc90fdca", "quantity": 1000}',0);
INSERT INTO messages VALUES(8,310003,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310003, "event": "a36a2d510757def22f0aa0f1cd1b4cf5e9bb160b051b83df25a101d5bb048928", "quantity": 50000000}',0);
INSERT INTO messages VALUES(9,310003,'insert','issuances','{"asset": "CALLABLE", "block_index": 310003, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Callable asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "a36a2d510757def22f0aa0f1cd1b4cf5e9bb160b051b83df25a101d5bb048928", "tx_index": 4}',0);
INSERT INTO messages VALUES(10,310003,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "CALLABLE", "block_index": 310003, "event": "a36a2d510757def22f0aa0f1cd1b4cf5e9bb160b051b83df25a101d5bb048928", "quantity": 1000}',0);
INSERT INTO messages VALUES(11,310004,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310004, "event": "044c9ac702136ee7839dc776cb7b43bbb9d5328415925a958679d801ac6c6b63", "quantity": 50000000}',0);
INSERT INTO messages VALUES(12,310004,'insert','issuances','{"asset": "LOCKED", "block_index": 310004, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Locked asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "044c9ac702136ee7839dc776cb7b43bbb9d5328415925a958679d801ac6c6b63", "tx_index": 5}',0);
INSERT INTO messages VALUES(13,310004,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "LOCKED", "block_index": 310004, "event": "044c9ac702136ee7839dc776cb7b43bbb9d5328415925a958679d801ac6c6b63", "quantity": 1000}',0);
INSERT INTO messages VALUES(14,310005,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310005, "event": "bd919f9a31982a6dbc6253e38bfba0a367e24fbd65cf79575648f799b98849b4", "quantity": 0}',0);
INSERT INTO messages VALUES(15,310005,'insert','issuances','{"asset": "LOCKED", "block_index": 310005, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Locked asset", "divisible": true, "fee_paid": 0, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": true, "quantity": 0, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "bd919f9a31982a6dbc6253e38bfba0a367e24fbd65cf79575648f799b98849b4", "tx_index": 6}',0);
INSERT INTO messages VALUES(16,310006,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310006, "event": "074fa38a84a81c0ed7957484ebe73836104d3068f66b189e05a7cf0b95c737f3", "quantity": 100000000}',0);
INSERT INTO messages VALUES(17,310006,'insert','orders','{"block_index": 310006, "expiration": 2000, "expire_index": 312006, "fee_provided": 10000, "fee_provided_remaining": 10000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "DIVISIBLE", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "074fa38a84a81c0ed7957484ebe73836104d3068f66b189e05a7cf0b95c737f3", "tx_index": 7}',0);
INSERT INTO messages VALUES(18,310007,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 310007, "event": "d21d82d8298d545b91e4467c287322d2399d8eb08af15bee68f58c4bcfa9a5f9", "quantity": 100000000}',0);
INSERT INTO messages VALUES(19,310007,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "DIVISIBLE", "block_index": 310007, "event": "d21d82d8298d545b91e4467c287322d2399d8eb08af15bee68f58c4bcfa9a5f9", "quantity": 100000000}',0);
INSERT INTO messages VALUES(20,310007,'insert','sends','{"asset": "DIVISIBLE", "block_index": 310007, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "d21d82d8298d545b91e4467c287322d2399d8eb08af15bee68f58c4bcfa9a5f9", "tx_index": 8}',0);
INSERT INTO messages VALUES(21,310008,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310008, "event": "e64aac59d8759cde5785f3e1c4af448d95a152a30c76d97c114a3025e5ec118b", "quantity": 100000000}',0);
INSERT INTO messages VALUES(22,310008,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310008, "event": "e64aac59d8759cde5785f3e1c4af448d95a152a30c76d97c114a3025e5ec118b", "quantity": 100000000}',0);
INSERT INTO messages VALUES(23,310008,'insert','sends','{"asset": "XCP", "block_index": 310008, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "e64aac59d8759cde5785f3e1c4af448d95a152a30c76d97c114a3025e5ec118b", "tx_index": 9}',0);
INSERT INTO messages VALUES(24,310009,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310009, "event": "a9f78534e7f340ba0f0d2ac1851a11a011ca7aa1262349eeba71add8777b162b", "quantity": 100000000}',0);
INSERT INTO messages VALUES(25,310009,'insert','orders','{"block_index": 310009, "expiration": 2000, "expire_index": 312009, "fee_provided": 10000, "fee_provided_remaining": 10000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "DIVISIBLE", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "a9f78534e7f340ba0f0d2ac1851a11a011ca7aa1262349eeba71add8777b162b", "tx_index": 10}',0);
INSERT INTO messages VALUES(26,310010,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310010, "event": "b6db5c8412a58d9fa75bff41f8a7519353ffd4d359c7c8fa7ee1900bc05e4d9d", "quantity": 100000000}',0);
INSERT INTO messages VALUES(27,310010,'insert','orders','{"block_index": 310010, "expiration": 2000, "expire_index": 312010, "fee_provided": 10000, "fee_provided_remaining": 10000, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 1000000, "get_remaining": 1000000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "b6db5c8412a58d9fa75bff41f8a7519353ffd4d359c7c8fa7ee1900bc05e4d9d", "tx_index": 11}',0);
INSERT INTO messages VALUES(28,310011,'insert','orders','{"block_index": 310011, "expiration": 2000, "expire_index": 312011, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 666667, "give_remaining": 666667, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "8a63e7a516d36c17ac32999222ac282ab94fb9c5ea30637cd06660b3139510f6", "tx_index": 12}',0);
INSERT INTO messages VALUES(29,310012,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310012, "event": "d4428cf4082bc5fe8fed72673f956d351f269a308cf0d0d0b87f76dd3b6165f4", "quantity": 300000000}',0);
INSERT INTO messages VALUES(30,310012,'insert','credits','{"action": "send", "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "XCP", "block_index": 310012, "event": "d4428cf4082bc5fe8fed72673f956d351f269a308cf0d0d0b87f76dd3b6165f4", "quantity": 300000000}',0);
INSERT INTO messages VALUES(31,310012,'insert','sends','{"asset": "XCP", "block_index": 310012, "destination": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "quantity": 300000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "d4428cf4082bc5fe8fed72673f956d351f269a308cf0d0d0b87f76dd3b6165f4", "tx_index": 13}',0);
INSERT INTO messages VALUES(32,310013,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 310013, "event": "97aaf458fdbe3a8d7e57b4c238706419c001fc5810630c0c3cd2361821052a0d", "quantity": 1000000000}',0);
INSERT INTO messages VALUES(33,310013,'insert','credits','{"action": "send", "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "DIVISIBLE", "block_index": 310013, "event": "97aaf458fdbe3a8d7e57b4c238706419c001fc5810630c0c3cd2361821052a0d", "quantity": 1000000000}',0);
INSERT INTO messages VALUES(34,310013,'insert','sends','{"asset": "DIVISIBLE", "block_index": 310013, "destination": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "quantity": 1000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "97aaf458fdbe3a8d7e57b4c238706419c001fc5810630c0c3cd2361821052a0d", "tx_index": 14}',0);
INSERT INTO messages VALUES(35,310014,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "NODIVISIBLE", "block_index": 310014, "event": "29cd663b5e5b0801717e46891bc57e1d050680da0a803944623f6021151d2592", "quantity": 5}',0);
INSERT INTO messages VALUES(36,310014,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "NODIVISIBLE", "block_index": 310014, "event": "29cd663b5e5b0801717e46891bc57e1d050680da0a803944623f6021151d2592", "quantity": 5}',0);
INSERT INTO messages VALUES(37,310014,'insert','sends','{"asset": "NODIVISIBLE", "block_index": 310014, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 5, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "29cd663b5e5b0801717e46891bc57e1d050680da0a803944623f6021151d2592", "tx_index": 15}',0);
INSERT INTO messages VALUES(38,310015,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "NODIVISIBLE", "block_index": 310015, "event": "b285ff2379716e92ab7b68ad4e68ba74a999dc9ca8c312c377231a89da7e9361", "quantity": 10}',0);
INSERT INTO messages VALUES(39,310015,'insert','credits','{"action": "send", "address": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "asset": "NODIVISIBLE", "block_index": 310015, "event": "b285ff2379716e92ab7b68ad4e68ba74a999dc9ca8c312c377231a89da7e9361", "quantity": 10}',0);
INSERT INTO messages VALUES(40,310015,'insert','sends','{"asset": "NODIVISIBLE", "block_index": 310015, "destination": "1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2", "quantity": 10, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "b285ff2379716e92ab7b68ad4e68ba74a999dc9ca8c312c377231a89da7e9361", "tx_index": 16}',0);
INSERT INTO messages VALUES(41,310016,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310016, "event": "cd929bf57f5f26550a56ba40eecd258b684842777dfc434a46b65a86e924bf52", "quantity": 50000000}',0);
INSERT INTO messages VALUES(42,310016,'insert','issuances','{"asset": "MAXI", "block_index": 310016, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Maximum quantity", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 9223372036854775807, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "cd929bf57f5f26550a56ba40eecd258b684842777dfc434a46b65a86e924bf52", "tx_index": 17}',0);
INSERT INTO messages VALUES(43,310016,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "MAXI", "block_index": 310016, "event": "cd929bf57f5f26550a56ba40eecd258b684842777dfc434a46b65a86e924bf52", "quantity": 9223372036854775807}',0);
INSERT INTO messages VALUES(44,310017,'insert','broadcasts','{"block_index": 310017, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "9b70f9ad8c0d92ff27127d081169cebee68a776f4974e757de09a46e85682d66", "tx_index": 18, "value": 1.0}',0);
INSERT INTO messages VALUES(45,310018,'insert','broadcasts','{"block_index": 310018, "fee_fraction_int": null, "locked": true, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "text": null, "timestamp": 0, "tx_hash": "f6548d72d0726bd869fdfdcf44766871f7ab721efda6ed7bce0d4c88b43bf1cf", "tx_index": 19, "value": null}',0);
INSERT INTO messages VALUES(46,310019,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310019, "event": "be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd", "quantity": 9}',0);
INSERT INTO messages VALUES(47,310019,'insert','bets','{"bet_type": 1, "block_index": 310019, "counterwager_quantity": 9, "counterwager_remaining": 9, "deadline": 1388000001, "expiration": 100, "expire_index": 310119, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd", "tx_index": 20, "wager_quantity": 9, "wager_remaining": 9}',0);
INSERT INTO messages VALUES(48,310020,'insert','debits','{"action": "bet", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310020, "event": "90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5", "quantity": 9}',0);
INSERT INTO messages VALUES(49,310020,'insert','bets','{"bet_type": 0, "block_index": 310020, "counterwager_quantity": 9, "counterwager_remaining": 9, "deadline": 1388000001, "expiration": 100, "expire_index": 310120, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "target_value": 0.0, "tx_hash": "90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5", "tx_index": 21, "wager_quantity": 9, "wager_remaining": 9}',0);
INSERT INTO messages VALUES(50,310020,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310020, "event": "90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5", "quantity": 0}',0);
INSERT INTO messages VALUES(51,310020,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(52,310020,'insert','credits','{"action": "filled", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310020, "event": "90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5", "quantity": 0}',0);
INSERT INTO messages VALUES(53,310020,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(54,310020,'insert','bet_matches','{"backward_quantity": 9, "block_index": 310020, "deadline": 1388000001, "fee_fraction_int": 5000000, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 9, "id": "be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd_90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5", "initial_value": 1.0, "leverage": 5040, "match_expire_index": 310119, "status": "pending", "target_value": 0.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 1, "tx0_block_index": 310019, "tx0_expiration": 100, "tx0_hash": "be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd", "tx0_index": 20, "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_bet_type": 0, "tx1_block_index": 310020, "tx1_expiration": 100, "tx1_hash": "90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5", "tx1_index": 21}',0);
INSERT INTO messages VALUES(55,310101,'insert','debits','{"action": "bet", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310101, "event": "ba0ef1dfbbc87df94e1d198b0e9e3c06301710d4aab3d85116cbc8199954644a", "quantity": 10}',0);
INSERT INTO messages VALUES(56,310101,'insert','bets','{"bet_type": 3, "block_index": 310101, "counterwager_quantity": 10, "counterwager_remaining": 10, "deadline": 1388000200, "expiration": 1000, "expire_index": 311101, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "target_value": 0.0, "tx_hash": "ba0ef1dfbbc87df94e1d198b0e9e3c06301710d4aab3d85116cbc8199954644a", "tx_index": 102, "wager_quantity": 10, "wager_remaining": 10}',0);
INSERT INTO messages VALUES(57,310102,'insert','broadcasts','{"block_index": 310102, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000002, "tx_hash": "18cbfca6cd776158c13245977b4eead061e6bdcea8118faa6996fb6d01b51d4e", "tx_index": 103, "value": 1.0}',0);
INSERT INTO messages VALUES(58,310102,'insert','credits','{"action": "bet settled", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310102, "event": "18cbfca6cd776158c13245977b4eead061e6bdcea8118faa6996fb6d01b51d4e", "quantity": 9}',0);
INSERT INTO messages VALUES(59,310102,'insert','credits','{"action": "bet settled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310102, "event": "18cbfca6cd776158c13245977b4eead061e6bdcea8118faa6996fb6d01b51d4e", "quantity": 9}',0);
INSERT INTO messages VALUES(60,310102,'insert','credits','{"action": "feed fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310102, "event": "18cbfca6cd776158c13245977b4eead061e6bdcea8118faa6996fb6d01b51d4e", "quantity": 0}',0);
INSERT INTO messages VALUES(61,310102,'insert','bet_match_resolutions','{"bear_credit": 9, "bet_match_id": "be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd_90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5", "bet_match_type_id": 1, "block_index": 310102, "bull_credit": 9, "escrow_less_fee": null, "fee": 0, "settled": true, "winner": null}',0);
INSERT INTO messages VALUES(62,310102,'update','bet_matches','{"bet_match_id": "be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd_90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5", "status": "settled"}',0);
INSERT INTO messages VALUES(63,310491,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310491, "event": "9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b", "quantity": 100000000}',0);
INSERT INTO messages VALUES(64,310491,'insert','orders','{"block_index": 310491, "expiration": 2000, "expire_index": 312491, "fee_provided": 10000, "fee_provided_remaining": 10000, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 800000, "get_remaining": 800000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b", "tx_index": 492}',0);
INSERT INTO messages VALUES(65,310492,'insert','orders','{"block_index": 310492, "expiration": 2000, "expire_index": 312492, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 800000, "give_remaining": 800000, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "tx_hash": "14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0", "tx_index": 493}',0);
INSERT INTO messages VALUES(66,310492,'update','orders','{"fee_provided_remaining": 10000, "fee_required_remaining": 892800, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b"}',0);
INSERT INTO messages VALUES(67,310492,'update','orders','{"fee_provided_remaining": 992800, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0"}',0);
INSERT INTO messages VALUES(68,310492,'insert','order_matches','{"backward_asset": "BTC", "backward_quantity": 800000, "block_index": 310492, "fee_paid": 7200, "forward_asset": "XCP", "forward_quantity": 100000000, "id": "9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b_14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0", "match_expire_index": 310512, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 310491, "tx0_expiration": 2000, "tx0_hash": "9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b", "tx0_index": 492, "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_block_index": 310492, "tx1_expiration": 2000, "tx1_hash": "14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0", "tx1_index": 493}',0);
INSERT INTO messages VALUES(69,310493,'insert','credits','{"action": "burn", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310493, "event": "d6adfa92e20b6211ff5fabb2f7a1c8b037168797984c94734c28e82e92d3b1d6", "quantity": 92995878046}',0);
INSERT INTO messages VALUES(70,310493,'insert','burns','{"block_index": 310493, "burned": 62000000, "earned": 92995878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "d6adfa92e20b6211ff5fabb2f7a1c8b037168797984c94734c28e82e92d3b1d6", "tx_index": 494}',0);
INSERT INTO messages VALUES(71,310494,'insert','debits','{"action": "issuance fee", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310494, "event": "084102fa0722f5520481f34eabc9f92232e4d1647b329b3fa58bffc8f91c5e4e", "quantity": 50000000}',0);
INSERT INTO messages VALUES(72,310494,'insert','issuances','{"asset": "DIVIDEND", "block_index": 310494, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Test dividend", "divisible": true, "fee_paid": 50000000, "issuer": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "locked": false, "quantity": 100, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "transfer": false, "tx_hash": "084102fa0722f5520481f34eabc9f92232e4d1647b329b3fa58bffc8f91c5e4e", "tx_index": 495}',0);
INSERT INTO messages VALUES(73,310494,'insert','credits','{"action": "issuance", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310494, "event": "084102fa0722f5520481f34eabc9f92232e4d1647b329b3fa58bffc8f91c5e4e", "quantity": 100}',0);
INSERT INTO messages VALUES(74,310495,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310495, "event": "9d3391348171201de9b5eb70ca80896b0ae166fd51237c843a90c1b4ccf8c602", "quantity": 10}',0);
INSERT INTO messages VALUES(75,310495,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "DIVIDEND", "block_index": 310495, "event": "9d3391348171201de9b5eb70ca80896b0ae166fd51237c843a90c1b4ccf8c602", "quantity": 10}',0);
INSERT INTO messages VALUES(76,310495,'insert','sends','{"asset": "DIVIDEND", "block_index": 310495, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 10, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "9d3391348171201de9b5eb70ca80896b0ae166fd51237c843a90c1b4ccf8c602", "tx_index": 496}',0);
INSERT INTO messages VALUES(77,310496,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310496, "event": "54f4c7b383ea19147e62d2be9f3e7f70b6c379baac15e8b4cf43f7c21578c1ef", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(78,310496,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "XCP", "block_index": 310496, "event": "54f4c7b383ea19147e62d2be9f3e7f70b6c379baac15e8b4cf43f7c21578c1ef", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(79,310496,'insert','sends','{"asset": "XCP", "block_index": 310496, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 92945878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "54f4c7b383ea19147e62d2be9f3e7f70b6c379baac15e8b4cf43f7c21578c1ef", "tx_index": 497}',0);
-- Triggers and indices on  messages
CREATE TRIGGER _messages_delete BEFORE DELETE ON messages BEGIN
                            INSERT INTO undolog VALUES(NULL, 'INSERT INTO messages(rowid,message_index,block_index,command,category,bindings,timestamp) VALUES('||old.rowid||','||quote(old.message_index)||','||quote(old.block_index)||','||quote(old.command)||','||quote(old.category)||','||quote(old.bindings)||','||quote(old.timestamp)||')');
                            END;
CREATE TRIGGER _messages_insert AFTER INSERT ON messages BEGIN
                            INSERT INTO undolog VALUES(NULL, 'DELETE FROM messages WHERE rowid='||new.rowid);
                            END;
CREATE TRIGGER _messages_update AFTER UPDATE ON messages BEGIN
                            INSERT INTO undolog VALUES(NULL, 'UPDATE messages SET message_index='||quote(old.message_index)||',block_index='||quote(old.block_index)||',command='||quote(old.command)||',category='||quote(old.category)||',bindings='||quote(old.bindings)||',timestamp='||quote(old.timestamp)||' WHERE rowid='||old.rowid);
                            END;
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
INSERT INTO order_matches VALUES('9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b_14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0',492,'9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',493,'14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'BTC',800000,310491,310492,310492,2000,2000,310512,7200,'pending');
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
INSERT INTO orders VALUES(7,'074fa38a84a81c0ed7957484ebe73836104d3068f66b189e05a7cf0b95c737f3',310006,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,100000000,'DIVISIBLE',100000000,100000000,2000,312006,0,0,10000,10000,'open');
INSERT INTO orders VALUES(10,'a9f78534e7f340ba0f0d2ac1851a11a011ca7aa1262349eeba71add8777b162b',310009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,100000000,'DIVISIBLE',100000000,100000000,2000,312009,0,0,10000,10000,'open');
INSERT INTO orders VALUES(11,'b6db5c8412a58d9fa75bff41f8a7519353ffd4d359c7c8fa7ee1900bc05e4d9d',310010,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,100000000,'BTC',1000000,1000000,2000,312010,900000,900000,10000,10000,'open');
INSERT INTO orders VALUES(12,'8a63e7a516d36c17ac32999222ac282ab94fb9c5ea30637cd06660b3139510f6',310011,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BTC',666667,666667,'XCP',100000000,100000000,2000,312011,0,0,1000000,1000000,'open');
INSERT INTO orders VALUES(492,'9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b',310491,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,0,'BTC',800000,0,2000,312491,900000,892800,10000,10000,'open');
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
INSERT INTO sends VALUES(8,'d21d82d8298d545b91e4467c287322d2399d8eb08af15bee68f58c4bcfa9a5f9',310007,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','DIVISIBLE',100000000,'valid');
INSERT INTO sends VALUES(9,'e64aac59d8759cde5785f3e1c4af448d95a152a30c76d97c114a3025e5ec118b',310008,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'valid');
INSERT INTO sends VALUES(13,'d4428cf4082bc5fe8fed72673f956d351f269a308cf0d0d0b87f76dd3b6165f4',310012,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','XCP',300000000,'valid');
INSERT INTO sends VALUES(14,'97aaf458fdbe3a8d7e57b4c238706419c001fc5810630c0c3cd2361821052a0d',310013,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','DIVISIBLE',1000000000,'valid');
INSERT INTO sends VALUES(15,'29cd663b5e5b0801717e46891bc57e1d050680da0a803944623f6021151d2592',310014,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','NODIVISIBLE',5,'valid');
INSERT INTO sends VALUES(16,'b285ff2379716e92ab7b68ad4e68ba74a999dc9ca8c312c377231a89da7e9361',310015,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2','NODIVISIBLE',10,'valid');
INSERT INTO sends VALUES(496,'9d3391348171201de9b5eb70ca80896b0ae166fd51237c843a90c1b4ccf8c602',310495,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','DIVIDEND',10,'valid');
INSERT INTO sends VALUES(497,'54f4c7b383ea19147e62d2be9f3e7f70b6c379baac15e8b4cf43f7c21578c1ef',310496,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj','XCP',92945878046,'valid');
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
INSERT INTO transactions VALUES(1,'610b15f0c2d3845f124cc6026b6c212033de94218b25f89d5dbde47d11085a89',310000,'2ee5123266f21fb8f65495c281a368e1b9f93b6c411986e06efc895a8d82467683e6ea5d863714b23582c1c59576650d07c405a8d9bf0d088ee65621178b259d',310000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,10000,X'',1);
INSERT INTO transactions VALUES(2,'82e357fac0f41bc8c0c01e781ce96f0871bd3d6aaf57a8e99255d5e9d9fba554',310001,'03a9a24e190a996364217761558e380b94ae9792b8b4dcaa92b6c58d80b9f8f7fcf9a34037be4cd6ad5e0c039b511cccc40c3438a5067822e3cd309f06519612',310001000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'00000014000000A25BE34B66000000174876E800010000000000000000000F446976697369626C65206173736574',1);
INSERT INTO transactions VALUES(3,'6ecaeb544ce2f8a4a24d8d497ecba6ef7b71082a3f1cfdabc48726d5bc90fdca',310002,'d574e4fee71454532c0207f27b9c46f07c5c2e20f43829ddeee8f798053413ac6e0d1b9ad2259a0370fe08581fab3e950ce629db5fadd823251254bf606a05bd',310002000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'000000140006CAD8DC7F0B6600000000000003E800000000000000000000124E6F20646976697369626C65206173736574',1);
INSERT INTO transactions VALUES(4,'a36a2d510757def22f0aa0f1cd1b4cf5e9bb160b051b83df25a101d5bb048928',310003,'44392d9d661459ba31140c59e7d8bcd16b071c864c59f65e2edd9e3c16d598e81aaba40f11019a379bfc6d7811e0265fbb8b276d99cdea7f739fb736f433052a',310003000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000001400000003C58E5C5600000000000003E8010000000000000000000E43616C6C61626C65206173736574',1);
INSERT INTO transactions VALUES(5,'044c9ac702136ee7839dc776cb7b43bbb9d5328415925a958679d801ac6c6b63',310004,'58c6f6fbf77a64a5e0df123b1258ae6c3e6d4e21901cc942aeb67b1332422c71e1e7e996c5d4f403159ce5ca3863b7ec7ef8281bbbce5960e258492872055fb5',310004000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000001400000000082C82E300000000000003E8010000000000000000000C4C6F636B6564206173736574',1);
INSERT INTO transactions VALUES(6,'bd919f9a31982a6dbc6253e38bfba0a367e24fbd65cf79575648f799b98849b4',310005,'348a1b690661597ee6e950446e7a1deb8bef7906c0e98a78ab4d0fe799fac5f3007dcd648ff0c61da35b19cf99f16f3028e10ba206968475d741fa8a86c4a7ae',310005000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000001400000000082C82E3000000000000000001000000000000000000044C4F434B',1);
INSERT INTO transactions VALUES(7,'074fa38a84a81c0ed7957484ebe73836104d3068f66b189e05a7cf0b95c737f3',310006,'9d31b774b633c35635b71669c07880b521880cee9298b6aba44752ec1734cd2aa26b3bed95409d874e68685636a31a038b784d3e085525ab8c26f7e3b7ba3676',310006000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000000A00000000000000010000000005F5E100000000A25BE34B660000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(8,'d21d82d8298d545b91e4467c287322d2399d8eb08af15bee68f58c4bcfa9a5f9',310007,'41007a4ed39e7df941059c3db6b24b74c1913b80e0fd38d0073a5b121880fd0f7e98989d8d70766957919371fdaf4e5b44125f9f7c449c3b6bea298253075fe3',310007000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,10000,X'00000000000000A25BE34B660000000005F5E100',1);
INSERT INTO transactions VALUES(9,'e64aac59d8759cde5785f3e1c4af448d95a152a30c76d97c114a3025e5ec118b',310008,'aa28e5948d1158f318393846b4ef67e53ca4c4b047ed8b06eb861db29914e9f1dfe11a8b73aa2225519843661a61e9038cb347015be916c5a44222ed71b8b604',310008000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,10000,X'0000000000000000000000010000000005F5E100',1);
INSERT INTO transactions VALUES(10,'a9f78534e7f340ba0f0d2ac1851a11a011ca7aa1262349eeba71add8777b162b',310009,'550d7d84590c6e4e7caed4e722151f7e110dc39bf3f54f719babfe89775095abb2d2454014b4cb01fb1e0a7e91639559ce17e096be5178b5c2ca5b22ad41b33a',310009000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000000A00000000000000010000000005F5E100000000A25BE34B660000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(11,'b6db5c8412a58d9fa75bff41f8a7519353ffd4d359c7c8fa7ee1900bc05e4d9d',310010,'477c4a3445e32cd0c8ef67c808ac6a6362ebc953c396e2d5c0d7e4f185becd15fa99bd7635358dbb3b5a92e9f03b7fa2dda8d4714e181ec4552b279df3ba81f0',310010000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000000A00000000000000010000000005F5E100000000000000000000000000000F424007D000000000000DBBA0',1);
INSERT INTO transactions VALUES(12,'8a63e7a516d36c17ac32999222ac282ab94fb9c5ea30637cd06660b3139510f6',310011,'05f81b5c1b067b647894014cea65558826be42cca20a6cccb8623d80059182b77da00922539c59a0a7b63f6f011ca0f564fada0451e891644728b874c65267b9',310011000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,1000000,X'0000000A000000000000000000000000000A2C2B00000000000000010000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(13,'d4428cf4082bc5fe8fed72673f956d351f269a308cf0d0d0b87f76dd3b6165f4',310012,'e9d898aae43fc103110e4935cabf01b6016571b1af82e27af04b57c12302b05eab217f075ac3344b0a422e76b8c762c119cb290c867bb6eed432994ec28af027',310012000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,10000,X'0000000000000000000000010000000011E1A300',1);
INSERT INTO transactions VALUES(14,'97aaf458fdbe3a8d7e57b4c238706419c001fc5810630c0c3cd2361821052a0d',310013,'2251b497007459321f72cda82681d07d131dd81cc29137b18c534bbb09271678f4497d0316ffac262f021f901078926dee11c791a3524ad850ee948474abd3b5',310013000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,10000,X'00000000000000A25BE34B66000000003B9ACA00',1);
INSERT INTO transactions VALUES(15,'29cd663b5e5b0801717e46891bc57e1d050680da0a803944623f6021151d2592',310014,'f98fb331e66361507190a1cb1df81b814d24517e7f219029c068b649c9b8a75703770369ebafd864d104225d6fe1fbf13705d1a37a819b04fb151ed390d7bcf8',310014000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,10000,X'000000000006CAD8DC7F0B660000000000000005',1);
INSERT INTO transactions VALUES(16,'b285ff2379716e92ab7b68ad4e68ba74a999dc9ca8c312c377231a89da7e9361',310015,'7c25469d6b4fed0e8bb9e4325994c4de1737570fece605b4ca388be6921406b64a395dc519b33c0dff4f93930b32737a941bbb850e31f2ebcd2caba520bc2820',310015000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,10000,X'000000000006CAD8DC7F0B66000000000000000A',1);
INSERT INTO transactions VALUES(17,'cd929bf57f5f26550a56ba40eecd258b684842777dfc434a46b65a86e924bf52',310016,'9f1c56677b369099f059cc145b98f2e3f8895631cdf0f72b7fe76fd953ab68c202329848dfb53f8146552876eba37f50ed02da34f23447f518449bf0ac0cc29e',310016000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'000000140000000000033A3E7FFFFFFFFFFFFFFF01000000000000000000104D6178696D756D207175616E74697479',1);
INSERT INTO transactions VALUES(18,'9b70f9ad8c0d92ff27127d081169cebee68a776f4974e757de09a46e85682d66',310017,'4c02945de20ccdc874ae21bf56aea2f40a029c17b81fcf602b367bdbc286f9ec0cacab35fc07ac60aefa4a96a586aed20129ad66d45ab87697704d731e06b40d',310017000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000001E52BB33003FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(19,'f6548d72d0726bd869fdfdcf44766871f7ab721efda6ed7bce0d4c88b43bf1cf',310018,'6a26d120314af1710052c8f8f78453f944a146039679c781e04ddbb5a2d010927726fa6f81d3e01fc1fcc3363c06e8e1a81a35636684c4dbcd51edf561a9c0fc',310018000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','',0,10000,X'0000001E4CC552003FF000000000000000000000046C6F636B',1);
INSERT INTO transactions VALUES(20,'be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd',310019,'592e775a9259b1a5a7b0d7c2e028ff320783e7b49243ed6a20ece89a72964f3af4ed129698c4a143ad682a1493f982c5f8193d3b0e36b3df43964520409beb7a',310019000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,10000,X'00000028000152BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(21,'90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5',310020,'87fac74eef20e6121d9a66c90481f801a10d636976a6a6e7cf42fc38cc104a470e1b4cab3f9670be86c93ec1a407a1b464599121df6c8109ec7247b25c7efc62',310020000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,10000,X'00000028000052BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(102,'ba0ef1dfbbc87df94e1d198b0e9e3c06301710d4aab3d85116cbc8199954644a',310101,'e8a8ebd85a460cf5987683360a1c77e6728b4e59027220f8eceda05c720bc38c91f6193bc43739da026cd28f340e1a10b9900bfa3eed11f88339147c61b65504',310101000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,10000,X'00000028000352BB33C8000000000000000A000000000000000A0000000000000000000013B0000003E8',1);
INSERT INTO transactions VALUES(103,'18cbfca6cd776158c13245977b4eead061e6bdcea8118faa6996fb6d01b51d4e',310102,'767209a2b49c4e2aef6ef3fae88ff8bb450266a5dc303bbaf1c8bfb6b86cf835053b6a4906ae343265125f8d3b773c5bd4111451410b18954ad76c8a9aff2046',310102000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000001E52BB33023FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(492,'9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b',310491,'bf454daa85f5aa7766a92d2740421d2a69af7dde2a5209852e318ff4c5a2f48409a6c1df9fa33d2bdbef9ddc3c77118f6982b4fe00bf99f4fecbf767ef33fc71',310491000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000000A00000000000000010000000005F5E100000000000000000000000000000C350007D000000000000DBBA0',1);
INSERT INTO transactions VALUES(493,'14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0',310492,'7a5dd1618ae6b4bb553d4edc16af2447313c443aa6e31d15a2ae7322bfce7d88160f825ff99dd8429d5fbcf5f2f904e2d486e8fdc2753ba8f6f058390afad447',310492000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','',0,1000000,X'0000000A000000000000000000000000000C350000000000000000010000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(494,'d6adfa92e20b6211ff5fabb2f7a1c8b037168797984c94734c28e82e92d3b1d6',310493,'e5695fcf012cfc974506f8b9c6b97f3d2aca71dcaf89a5191fd69d56459a7c7d4fde0f50ca105fe249b13e40556aa98d9fbc4f56c98dabbca3ff9dbc45df2521',310493000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,10000,X'',1);
INSERT INTO transactions VALUES(495,'084102fa0722f5520481f34eabc9f92232e4d1647b329b3fa58bffc8f91c5e4e',310494,'5ea4dd62da28162e1829870fbfab1dc6028d01cac7e541bffa6696059705e33e27d266855fa60ace8ffa9c7bc6612dee1b0e4612e4d78575c847c91b2d3b217c',310494000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','',0,10000,X'00000014000000063E985FFD0000000000000064010000000000000000000D54657374206469766964656E64',1);
INSERT INTO transactions VALUES(496,'9d3391348171201de9b5eb70ca80896b0ae166fd51237c843a90c1b4ccf8c602',310495,'14a4d161b11a33ae7890e835206e0bab161693bea0c4647d59ead2d2c437157f3b0178db71a244c0fbc8c7d56de89bd825aa36d1e8b3b62f972e1867b9160a20',310495000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj',5430,10000,X'00000000000000063E985FFD000000000000000A',1);
INSERT INTO transactions VALUES(497,'54f4c7b383ea19147e62d2be9f3e7f70b6c379baac15e8b4cf43f7c21578c1ef',310496,'54967ea8d512b2b886a8e5106016df7f323169118a410af02dcdf9352e97b75ca8041441fd4b6af5ea09fff163f0d0e6d2f7a07518da27e6c367216110f316a6',310496000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj',5430,10000,X'00000000000000000000000100000015A4018C1E',1);
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
INSERT INTO undolog VALUES(167,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92050000000 WHERE rowid=1');
INSERT INTO undolog VALUES(168,'DELETE FROM messages WHERE rowid=63');
INSERT INTO undolog VALUES(169,'DELETE FROM debits WHERE rowid=19');
INSERT INTO undolog VALUES(170,'DELETE FROM messages WHERE rowid=64');
INSERT INTO undolog VALUES(171,'DELETE FROM orders WHERE rowid=5');
INSERT INTO undolog VALUES(172,'DELETE FROM messages WHERE rowid=65');
INSERT INTO undolog VALUES(173,'DELETE FROM orders WHERE rowid=6');
INSERT INTO undolog VALUES(174,'UPDATE orders SET tx_index=492,tx_hash=''9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b'',block_index=310491,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''XCP'',give_quantity=100000000,give_remaining=100000000,get_asset=''BTC'',get_quantity=800000,get_remaining=800000,expiration=2000,expire_index=312491,fee_required=900000,fee_required_remaining=900000,fee_provided=10000,fee_provided_remaining=10000,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(175,'DELETE FROM messages WHERE rowid=66');
INSERT INTO undolog VALUES(176,'UPDATE orders SET tx_index=493,tx_hash=''14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0'',block_index=310492,source=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',give_asset=''BTC'',give_quantity=800000,give_remaining=800000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=2000,expire_index=312492,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=6');
INSERT INTO undolog VALUES(177,'DELETE FROM messages WHERE rowid=67');
INSERT INTO undolog VALUES(178,'DELETE FROM messages WHERE rowid=68');
INSERT INTO undolog VALUES(179,'DELETE FROM order_matches WHERE rowid=1');
INSERT INTO undolog VALUES(180,'DELETE FROM balances WHERE rowid=13');
INSERT INTO undolog VALUES(181,'DELETE FROM messages WHERE rowid=69');
INSERT INTO undolog VALUES(182,'DELETE FROM credits WHERE rowid=18');
INSERT INTO undolog VALUES(183,'DELETE FROM messages WHERE rowid=70');
INSERT INTO undolog VALUES(184,'DELETE FROM burns WHERE rowid=494');
INSERT INTO undolog VALUES(185,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''XCP'',quantity=92995878046 WHERE rowid=13');
INSERT INTO undolog VALUES(186,'DELETE FROM messages WHERE rowid=71');
INSERT INTO undolog VALUES(187,'DELETE FROM debits WHERE rowid=20');
INSERT INTO undolog VALUES(188,'DELETE FROM assets WHERE rowid=8');
INSERT INTO undolog VALUES(189,'DELETE FROM messages WHERE rowid=72');
INSERT INTO undolog VALUES(190,'DELETE FROM issuances WHERE rowid=495');
INSERT INTO undolog VALUES(191,'DELETE FROM balances WHERE rowid=14');
INSERT INTO undolog VALUES(192,'DELETE FROM messages WHERE rowid=73');
INSERT INTO undolog VALUES(193,'DELETE FROM credits WHERE rowid=19');
INSERT INTO undolog VALUES(194,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''DIVIDEND'',quantity=100 WHERE rowid=14');
INSERT INTO undolog VALUES(195,'DELETE FROM messages WHERE rowid=74');
INSERT INTO undolog VALUES(196,'DELETE FROM debits WHERE rowid=21');
INSERT INTO undolog VALUES(197,'DELETE FROM balances WHERE rowid=15');
INSERT INTO undolog VALUES(198,'DELETE FROM messages WHERE rowid=75');
INSERT INTO undolog VALUES(199,'DELETE FROM credits WHERE rowid=20');
INSERT INTO undolog VALUES(200,'DELETE FROM messages WHERE rowid=76');
INSERT INTO undolog VALUES(201,'DELETE FROM sends WHERE rowid=496');
INSERT INTO undolog VALUES(202,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''XCP'',quantity=92945878046 WHERE rowid=13');
INSERT INTO undolog VALUES(203,'DELETE FROM messages WHERE rowid=77');
INSERT INTO undolog VALUES(204,'DELETE FROM debits WHERE rowid=22');
INSERT INTO undolog VALUES(205,'DELETE FROM balances WHERE rowid=16');
INSERT INTO undolog VALUES(206,'DELETE FROM messages WHERE rowid=78');
INSERT INTO undolog VALUES(207,'DELETE FROM credits WHERE rowid=21');
INSERT INTO undolog VALUES(208,'DELETE FROM messages WHERE rowid=79');
INSERT INTO undolog VALUES(209,'DELETE FROM sends WHERE rowid=497');

-- Table  undolog_block
DROP TABLE IF EXISTS undolog_block;
CREATE TABLE undolog_block(
                        block_index INTEGER PRIMARY KEY,
                        first_undo_index INTEGER);
INSERT INTO undolog_block VALUES(310400,167);
INSERT INTO undolog_block VALUES(310401,167);
INSERT INTO undolog_block VALUES(310402,167);
INSERT INTO undolog_block VALUES(310403,167);
INSERT INTO undolog_block VALUES(310404,167);
INSERT INTO undolog_block VALUES(310405,167);
INSERT INTO undolog_block VALUES(310406,167);
INSERT INTO undolog_block VALUES(310407,167);
INSERT INTO undolog_block VALUES(310408,167);
INSERT INTO undolog_block VALUES(310409,167);
INSERT INTO undolog_block VALUES(310410,167);
INSERT INTO undolog_block VALUES(310411,167);
INSERT INTO undolog_block VALUES(310412,167);
INSERT INTO undolog_block VALUES(310413,167);
INSERT INTO undolog_block VALUES(310414,167);
INSERT INTO undolog_block VALUES(310415,167);
INSERT INTO undolog_block VALUES(310416,167);
INSERT INTO undolog_block VALUES(310417,167);
INSERT INTO undolog_block VALUES(310418,167);
INSERT INTO undolog_block VALUES(310419,167);
INSERT INTO undolog_block VALUES(310420,167);
INSERT INTO undolog_block VALUES(310421,167);
INSERT INTO undolog_block VALUES(310422,167);
INSERT INTO undolog_block VALUES(310423,167);
INSERT INTO undolog_block VALUES(310424,167);
INSERT INTO undolog_block VALUES(310425,167);
INSERT INTO undolog_block VALUES(310426,167);
INSERT INTO undolog_block VALUES(310427,167);
INSERT INTO undolog_block VALUES(310428,167);
INSERT INTO undolog_block VALUES(310429,167);
INSERT INTO undolog_block VALUES(310430,167);
INSERT INTO undolog_block VALUES(310431,167);
INSERT INTO undolog_block VALUES(310432,167);
INSERT INTO undolog_block VALUES(310433,167);
INSERT INTO undolog_block VALUES(310434,167);
INSERT INTO undolog_block VALUES(310435,167);
INSERT INTO undolog_block VALUES(310436,167);
INSERT INTO undolog_block VALUES(310437,167);
INSERT INTO undolog_block VALUES(310438,167);
INSERT INTO undolog_block VALUES(310439,167);
INSERT INTO undolog_block VALUES(310440,167);
INSERT INTO undolog_block VALUES(310441,167);
INSERT INTO undolog_block VALUES(310442,167);
INSERT INTO undolog_block VALUES(310443,167);
INSERT INTO undolog_block VALUES(310444,167);
INSERT INTO undolog_block VALUES(310445,167);
INSERT INTO undolog_block VALUES(310446,167);
INSERT INTO undolog_block VALUES(310447,167);
INSERT INTO undolog_block VALUES(310448,167);
INSERT INTO undolog_block VALUES(310449,167);
INSERT INTO undolog_block VALUES(310450,167);
INSERT INTO undolog_block VALUES(310451,167);
INSERT INTO undolog_block VALUES(310452,167);
INSERT INTO undolog_block VALUES(310453,167);
INSERT INTO undolog_block VALUES(310454,167);
INSERT INTO undolog_block VALUES(310455,167);
INSERT INTO undolog_block VALUES(310456,167);
INSERT INTO undolog_block VALUES(310457,167);
INSERT INTO undolog_block VALUES(310458,167);
INSERT INTO undolog_block VALUES(310459,167);
INSERT INTO undolog_block VALUES(310460,167);
INSERT INTO undolog_block VALUES(310461,167);
INSERT INTO undolog_block VALUES(310462,167);
INSERT INTO undolog_block VALUES(310463,167);
INSERT INTO undolog_block VALUES(310464,167);
INSERT INTO undolog_block VALUES(310465,167);
INSERT INTO undolog_block VALUES(310466,167);
INSERT INTO undolog_block VALUES(310467,167);
INSERT INTO undolog_block VALUES(310468,167);
INSERT INTO undolog_block VALUES(310469,167);
INSERT INTO undolog_block VALUES(310470,167);
INSERT INTO undolog_block VALUES(310471,167);
INSERT INTO undolog_block VALUES(310472,167);
INSERT INTO undolog_block VALUES(310473,167);
INSERT INTO undolog_block VALUES(310474,167);
INSERT INTO undolog_block VALUES(310475,167);
INSERT INTO undolog_block VALUES(310476,167);
INSERT INTO undolog_block VALUES(310477,167);
INSERT INTO undolog_block VALUES(310478,167);
INSERT INTO undolog_block VALUES(310479,167);
INSERT INTO undolog_block VALUES(310480,167);
INSERT INTO undolog_block VALUES(310481,167);
INSERT INTO undolog_block VALUES(310482,167);
INSERT INTO undolog_block VALUES(310483,167);
INSERT INTO undolog_block VALUES(310484,167);
INSERT INTO undolog_block VALUES(310485,167);
INSERT INTO undolog_block VALUES(310486,167);
INSERT INTO undolog_block VALUES(310487,167);
INSERT INTO undolog_block VALUES(310488,167);
INSERT INTO undolog_block VALUES(310489,167);
INSERT INTO undolog_block VALUES(310490,167);
INSERT INTO undolog_block VALUES(310491,167);
INSERT INTO undolog_block VALUES(310492,172);
INSERT INTO undolog_block VALUES(310493,180);
INSERT INTO undolog_block VALUES(310494,185);
INSERT INTO undolog_block VALUES(310495,194);
INSERT INTO undolog_block VALUES(310496,202);
INSERT INTO undolog_block VALUES(310497,210);
INSERT INTO undolog_block VALUES(310498,210);
INSERT INTO undolog_block VALUES(310499,210);
INSERT INTO undolog_block VALUES(310500,210);

-- For primary key autoincrements the next id to use is stored in
-- sqlite_sequence
DELETE FROM main.sqlite_sequence WHERE name='undolog';
INSERT INTO main.sqlite_sequence VALUES ('undolog', 209);

COMMIT TRANSACTION;
