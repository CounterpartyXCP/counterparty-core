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
INSERT INTO balances VALUES('myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','XCP',92999138821);
INSERT INTO balances VALUES('munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','XCP',92999130460);
INSERT INTO balances VALUES('mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',92999122099);
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
INSERT INTO blocks VALUES(310017,'4c02945de20ccdc874ae21bf56aea2f40a029c17b81fcf602b367bdbc286f9ec0cacab35fc07ac60aefa4a96a586aed20129ad66d45ab87697704d731e06b40d',310017000,NULL,NULL,'64aa58f7e48dfa10bb48ecf48571d832bb94027c7ac07be0d23d5379452ce03b','2245fdefd4c9dace945f1f6a093e772aeb4ff8258dfc67001b3b8f3d419a566f','0414e1a2c836e1c9984343593bd7243178e14402110d7a9f885e3257a6a1f32d');
INSERT INTO blocks VALUES(310018,'6a26d120314af1710052c8f8f78453f944a146039679c781e04ddbb5a2d010927726fa6f81d3e01fc1fcc3363c06e8e1a81a35636684c4dbcd51edf561a9c0fc',310018000,NULL,NULL,'8d8f404bdc2fb6178286b2581cf8a23e6028d5d285091fa0e67e96e6da91f54e','7d4011ee71a6729cd5f7119221e2108f1aee5be382aa045f502de797380f1950','60d8283509f00a5c99b615890d0145c2d8c27970b5d39a9b363c83ff6ce26ac5');
INSERT INTO blocks VALUES(310019,'592e775a9259b1a5a7b0d7c2e028ff320783e7b49243ed6a20ece89a72964f3af4ed129698c4a143ad682a1493f982c5f8193d3b0e36b3df43964520409beb7a',310019000,NULL,NULL,'945a8fd2f57cfd5ddab542291fb2e2813762806b806a3e65e688321fefe1986d','85bfb6ef4e5e6bc851706d98aaf1faf24c64b64318e1259ceccae097887f02fe','d519a9da5d40e1df8c11630da37a5912d364eff219de79c4a2db87b8d13d1e66');
INSERT INTO blocks VALUES(310020,'87fac74eef20e6121d9a66c90481f801a10d636976a6a6e7cf42fc38cc104a470e1b4cab3f9670be86c93ec1a407a1b464599121df6c8109ec7247b25c7efc62',310020000,NULL,NULL,'3393abc111ee337132103ca04b4f8745952cd03ddbd6efff58a589e00a48fa21','631826c927db119760a26931336224c9a70564abc9ba506f8875521f4140a63e','a04dc8227c2684d09998282737974f11cde2e489eac487ecbcde71b50b79ddf6');
INSERT INTO blocks VALUES(310021,'68a4f307918e2f39fb393e5ad6a7e2fb2e35ab5043402ce37e984de670579682af5c7ef98637478bc0efeb579dc9aaca7f199116b390c452ceedca420909355d',310021000,NULL,NULL,'d05fe9705db7b30e6ea6b18e9ae92ba794dd72f25b4e33daf4d46b3b609a02de','8f3ca590213c6ca655ffc82424783961df9828e91fc54d472735da984a686709','3942b16bd79e421cd5f63421c51ced2528ddd25022823c35d7841b3ed237cf93');
INSERT INTO blocks VALUES(310022,'5052fbeb009f77f5629fb701a2e4a379ef6c5591a87ab4d2315c8b79fc8821301b21f146150b2af542eddd82e8e94bc021dd1a9ef8e837891248ab68f4afa7d0',310022000,NULL,NULL,'c2b2b2c3bdd895c74f3ea22db3d9c66301578436b6fa9175ce0b242c4bfaccc5','3834d76ca0ed78361981d700e85220acf0f45e6cb7a598d946bffae6843d1aeb','beb5b92cd2cc5fc79bbc5f07e41b59b7451017c2ed509c1a014da011cf63a1fe');
INSERT INTO blocks VALUES(310023,'1aab02bbb1a7450d612af368e571d955812f9a376e9f7f80c8eb8296ec40ebfa964f5c9b5e56d4e0cc2d584b38c3280c2b8b2ac272ac00f4d0bffd5348006b4c',310023000,NULL,NULL,'fad5b61545d8ef317918f07df063554d4f321c0ebf462f759513212960bdf523','77bd21226b8e42c26e95f65a3508fc69039c0d48298d4255865e5002dad4b3d2','0638dca3d86647bf7a5d469d50a2c0bec5bd8e56ba74cd503aaf44985b33060e');
INSERT INTO blocks VALUES(310024,'232fc55d72da13e22bb39e10cf9bdc29a634f1c6d13c598f8a1886fc6adde9f0db1ec92afc8f2e7e099ad1d225277067c9beebb14116168bcc961d43cc0a5b88',310024000,NULL,NULL,'61a71d0ac67eba15c63a531f797e6d68c83613489730bc2b4e4054094f63105a','26cf2d4591d86355b018c05443ef3dd51b5e37d1120768e7e6400b6ec3f5cf45','a1a8237c2a7fbbcbb958b7f7c01d3f5d5df6d0fc59ba48dd6e2047c6bd36d2c3');
INSERT INTO blocks VALUES(310025,'39e5551cc35f579114d5a36f841b8aa487e8277ede3b03bfe73f31b16ffc92d8a9535c485518839f3a1f5789222f234e3ac59e67f949ebb2f86044e72296a4fe',310025000,NULL,NULL,'f7d41404c3d1e57bbc390af958d1596212112068e4986954d11ff8abd13bc8e4','571e7941f9ffb3fee0deba438f4908e42afe32ee1989832446328ddce2e0bb7a','f72f1eb8504318793cf86786e6e3db0e7cbfd67846dd8841edc224c43bb614ed');
INSERT INTO blocks VALUES(310026,'dd6f9e911867c1680a777ed34699914cae82576da2f3fe064cec0f77af56f3af2b9309a9e56195f3a63897446e7cc37ebfa8257aa4758e81fcf70d9b12d77bbe',310026000,NULL,NULL,'31530d7febb577d7588e12d10629fd82966df48a93a613a480879531d5dbd374','fbcff8969422a26145502301d05611d83bef3607ee4d91cf6f135a4b2a156110','6d9bc4104350a2b832c27ad8eb36a5bf2c20ad833a165d7f2081a10cfd7febcb');
INSERT INTO blocks VALUES(310027,'9adde4402993118c8963435b66b5cd74676459f5aec1f4098ded4e99592879c8072b1603611ccb10fa2f1e7e88e087f812553796839664f2a3ed510c4aed9337',310027000,NULL,NULL,'f54085346ae4608c57c55d321a413a00ffeb85499138559d7d05245f57cc0da3','65689a8c3387ecf9131a702d1859be1cd07ce0bcd07a506024df3ff07eaff189','0ebcd48da1e844be37e2fc985d0fdc4076cb574634b5ecd328c9405a7063c411');
INSERT INTO blocks VALUES(310028,'158e01a36be6070d70d4f5723fca07d5a49fa057b32c651893df7bf1c5752a41444ddb9499d11fdfdaa7b5a63070f9294a55e1a6a4e751ed154b5330dc10111e',310028000,NULL,NULL,'a841b7f634fc24553d1c8cb2d66fc3103293dcfd297cb5bf241b0c5da84bd376','686da3ffaabd8bf68173c6e14eb9a5c32da5f49a35ca440c63d846daba1d38b7','73587ae2c87790755ecf4920311b1dcfe88768f9509a29338b9bb2408ae44d38');
INSERT INTO blocks VALUES(310029,'fcd8b3ff5ebaa56426855b262003f15cc0602e452db1ec6c9bc475388553d4766503fc6cde9290903fff1dd94652676b826a229031ee7cb56f69a6d633895fac',310029000,NULL,NULL,'69d40c69b4989f7a59da99b56577b0651887d9422757e38d5410379f95fda641','404f8800501fa0140076a3455ef0161c5b6b7a9cbab9a215d061d46fb175f40b','23deb6bbadd47f3c0cd65ab272a5175edd3cdda345cf50ea9e2fe45c39e7db29');
INSERT INTO blocks VALUES(310030,'b49587ccb88b99aa75b91045c596f731a16ce7523207ae0cfd2b2400898576943ae0969a28c5500d20d72a33c9a79b5fc3f5840bd550846d272462cd66fcc259',310030000,NULL,NULL,'192fe51d3a7af659670a8899582c29aedf3a5608ca906b274ce986751dad2d7a','50693583487ca6b190ed0b90a15e6fc37736bc5c369a171d737ca0a3106d8809','e91bbaaebbae3578625fa04a91bfef75b9cd1c0f9a6882bc88bee15c55ae3cd8');
INSERT INTO blocks VALUES(310031,'7a898e085dea5f59d75df0d4b5dd1a8b12c269d1eaef4e8c78938294abef4813e858c6e6f7bba2e5918a853f71decb610ce80fe3da936587396c44086eed86c8',310031000,NULL,NULL,'125784cdeba1e433b3411c368cdf676efb33021f51c26a8b2bd6ec00fe4f767d','256be133cc35e6c96dbcbaf8f99112c147bf236a4b2122d3cce91da4ba3850a4','8003f86c0ce8202d3d455b986530a01a683dca2d112d7aa7c281810cb260f10d');
INSERT INTO blocks VALUES(310032,'d5778cdb9b17207d9caffc0190842356895364e0c5e6247f02c2fb91d4dcde85becbc7958f07b9c99a9833f45599a0c175a8a3b026ec879467142eff3e3c1457',310032000,NULL,NULL,'fa7832080a2b6ae8829794d70603351755fa4816f15a6e92716f83265daa59a4','c2223246cfcf4eaf5c45364af01e558ce6eaa61c1643c5abfb65ca8eaa4bd3c5','067b20c148bffba5040024f255f97a76ecc600cbe8abf5b66dddb144f8cf327e');
INSERT INTO blocks VALUES(310033,'ecc0f5ba6c110a32e76689e934d9101617db692d61600ebfe32b500fecd78dcf75bd5712de67e59b99d5b16d9eaaa8378a46a73a35fb10f8821bf75a173507b0',310033000,NULL,NULL,'7b86f430bc44ad5d81a43b5a8ea118b458d995e3832d88bb74bc62429194e45c','b9292a03be801f2d50ab7d6d98662aa28bbe15d420e88939e430f426860fab37','742f2cd86da84bf19a4f6cffd8e715bf7fd67d919b91fd21971810d5c09e28c7');
INSERT INTO blocks VALUES(310034,'75ece066b260c4843383467558849588e5ce1f1634da9bea7c9c0e1821150a386baf940a2624b4c0c3fc4bc4996bf97f545fa61a4ec90c57ca5127c1ccdbec84',310034000,NULL,NULL,'1f2c5ac4375f77fb79612d343dd5fc4489cf94ff983fc05ba2009a9e390d6c06','daa9e1ef8fdd8eb99766e08e4f141b610a4e83b1a8d1b922865afd66ddf881b4','4d0c21b4c48f241fe3f1841f0a24b66807d6f3c110de84afc12d6180db4c56a3');
INSERT INTO blocks VALUES(310035,'0c8e6a86abf191a1bad2897dcc7aad3e5a5c1439799c55c95f435eb6fb9e50ac892d58d1a9c9424009d0730fd59ecb202de2e1c155d5fc70a8da9868946caa51',310035000,NULL,NULL,'81cdae9b978935ad40a1032e7f22ddd7117b9c7580d6d7e4b7e20d1c875f5e63','14bf53c0f500c2d3f4562ec327414dfcf5907c2ee479fbe233b8da79e1285a25','53583fd46555c8722cc4325e2311da4c4551c598cc2eccf0005daa350553d8c7');
INSERT INTO blocks VALUES(310036,'4011ea78ccc04ca2ee8d6bf0b14eef82bfa9456869415a8126f2bee5a1bf961c8436571c00fe20e82c78bee44159e0a3523736123c641b871d271642e8f7ef1b',310036000,NULL,NULL,'ff02952dce15c249501d8485decad0ad9fe02fda766b7b83720806f726d02ee4','219be4989beff2cc24c0b384741d8023673ad111600b46e883684a7cafc46dea','7c448a1b709d2b8a38c87feec6f54df7b622fd11494767e8e6db04150c6796a7');
INSERT INTO blocks VALUES(310037,'7f94ef56feec97124f1e6f04b862fed49ae7c179ee143701cf0eec922b5d39932831274f5528d8d9b0e8e115236cfca7f2d78da21db5596565314e625300ef49',310037000,NULL,NULL,'760e5a00feb6c8c4baf4421ad07be2af962bfcac7705b773484b449356d6c230','bb4126e979600e52dc602a41edafbc5ef2bccc31cd82e93cf188b4ce35ff94ce','c2a60634b94f43301baba949f678769e682f42fb485dc1b054bcc759eb65ff93');
INSERT INTO blocks VALUES(310038,'e7c42cc00226117b58f818813df49a64af8ca6352a8490a2894676aba647c1bc8d4ae58bb883b710348233879c841da83eda54d35c5ec279f8a2e1ccba8a4264',310038000,NULL,NULL,'c79381c51fa93cc320d8bf19c943f98232a99446ac098ff66823cf691e0fa01c','a14f3e43c8d60430d64fea2029449108e7da9e7644642835056e6a362f3fa2af','8c31a2c69ad333d9f82e1581d2bf3d542798be1dca1042b8a7d4ffe8c076fa18');
INSERT INTO blocks VALUES(310039,'1efd67747830ff43e4cb5f2837d40789a0a781a79c5de4a7966ef64101c39169c28b7eb78481c4b92d14d997be3bbc7f5c6a6a8af8c729825c0e6a07fc6fbeea',310039000,NULL,NULL,'7382f007315783c9a6ffd29bc0eaa62282c6ec72c5fff09322d6dea6b0ee3a96','bf63525869d4c37e86cb22a566d66297097646999f392c1c5a674133421e739f','a213c559b4152bc09238b6b00cc5facdafcf94faeadcc1b23a260f9cb4a6187f');
INSERT INTO blocks VALUES(310040,'0afea7365138d9d478c1a57003d66b1998e462cfe57a9a3a1a9360f5e305e9e639387f6849770c33995e1126cefa8ed66faf8a8af03e5c0853191091978d04b1',310040000,NULL,NULL,'38d3b548be554a0ae92504244a88930b989ea6fefc9bc59c69b68ed560afee9a','5a174ee1dcf1be5e485d6660349f3e1d49f20e34b00e2119826b50c407cef98f','1e62818d1acf0e6b39b9c0c50dbda3fa526a4e138a73a6d08053be78eca6b194');
INSERT INTO blocks VALUES(310041,'a332959f882f2a2846237e5ce8874beddc8e28c551f7d5be885c79b1d4650c5ff3c9855069302643e9315390e2dc1e7e072e7f90afecd5fe4f3f14b31f38caf3',310041000,NULL,NULL,'0c1c7aa19c015a67da214bf8a6ae3d77979a09de6a63621e320a28ceebdbf333','e9fe3a5713d286f89f8d2819a64067fdf02e51f435698510849dd6509086d61c','c35c02f825df5f824d285b251fd23fa303d41d0206a318f7d60be601a02b1bf1');
INSERT INTO blocks VALUES(310042,'ee6c4eafabbae31087db301639be2c8d82b31a3004ed19a30a3c6faafdef5c0a363ae91e97c4cc88254bfb0d16213816e610da28233ee3775969dbeba213ea2e',310042000,NULL,NULL,'9d20f77d4afff9179cffe46574f1b2dd23d2987142c943de05e411baee2dbf05','711936e7bb039308fd3ecc1ea1f97a3671d5a4a75127076f5fafee076f25241a','63afc696f60b22dd3664a4eaa06fceb5fe620f99201b2953bc15f62d12406fbc');
INSERT INTO blocks VALUES(310043,'1fd0b3a1241e5435a39f816d44b6a009780a37e2a131fa7be8423875f81defa4b571a0c9b89cc335c2698dbd66f55fa333bb80e20fa2ed03d9c3e8c95276d05c',310043000,NULL,NULL,'d818e5a1a5cb6c59771b63997a8737cdb041c3579de1ecd808a269f5d72a3abf','3e3513f44a41a33723d3ff9f45c1d78f5a955d0c64ec7443e988475c2427e9ff','3b67df29dbe127893470e42f0d9b5dc7b49bad26084e794408e14a5e529e3607');
INSERT INTO blocks VALUES(310044,'8074ad14f920e3bcdfe75f606c3a261e14275b3ec48d8678841492f633feb1a25c48c729e10d192e59d52b1ed5bc10185b2d0636835b05b3962e4be08b06f194',310044000,NULL,NULL,'9de166ff18c5eec97b838292ae894ce18e5a890e8a841a294b2d14894c60a0d7','bad4edd93c56a27bc5484412c97c2de26536d4289ca20474762b1c89b4237f2e','a95d5e3424e214f9224bf46b6a33ca2744b0bcc9a23db14c58736646f9a0400e');
INSERT INTO blocks VALUES(310045,'edbfe164803ccbc044c2d602e6ee85546a00d478e5ec3a9475a487cfcd7deef64155b201530367be15262f05ae77a8270ac8dfed18355302a01bc37d0d1d98ea',310045000,NULL,NULL,'bb3c0a260dc082534c95e894751e38e80de117b091bc0e34c66134d374b8db2d','61ec5baf9867410a7de247ff462900934dbedfedc8de0c5701626ad4d72a58ef','c7f3c11c6db91f2c0c5321a8b5f1b3c9ad027e551391996a237824bdd6bbe6d1');
INSERT INTO blocks VALUES(310046,'c1d7a9dc0c93554dacedb41e6f4e7d97b7cf23a9706e6052b7c583233632b4f3cb8596e5b59b6957413ea1da603c2fe125eacf6b2257fb2ae48de3652893eb22',310046000,NULL,NULL,'b4605c50ee3e5e2958c908e099563cf997e20932cc2370109ab50049e43723cf','570865d6e371aea4b0e3fa5112a8af24417c216fc30c66300f34a274a9652437','96699fba0e9090d2acdb7bd206b68de939302d85a295ce09673ba851b0e8839c');
INSERT INTO blocks VALUES(310047,'86c6061e10d6032dd6051842afb28b6121ba443e4ace7ebcc213258fbd8aa86136ea03f5c3eafe13e560b9589871011f786bf204cc8ac6a419c263f138ddf72c',310047000,NULL,NULL,'b840a7af6301c798c9a6670308a2684051ff8f3fb2e69bddaafa82cfd3d83186','2fff393abe806829bf1d3df6b49ced18efae64893ba0bf4d6484d1fb26f29327','5cf8d7090966c3a707e758c83d5dc386d39a5e73f0683d8e0e916894aa07a067');
INSERT INTO blocks VALUES(310048,'41f80924d6d10e6ff29f9926dcc1bc644a30d87657975c22165d4c54f8c30938b9bec93e24e7033bff0ad7e6540bec0ae0c3333c7f54499c7809c450cdf91451',310048000,NULL,NULL,'6bd591d3336ea112789ad6675a9b1d8e1578fe42e44ca7f7be5557089d374c3f','c3da2466d91c82f54649e6560d4a2dd74d345f75648d7e38d5598324f3a4eac4','78ea6727c7bf2c09f74147f036802f3de11999dd0bfd1332e02f9e32c644690d');
INSERT INTO blocks VALUES(310049,'51e01a7614ad99af02c4171df920803ed9a88ff9a47254f0d0faf521f5f806b840bf88a311c54a08edbb9fc2f152214bb930f1b8368245c8cd263473b79f808b',310049000,NULL,NULL,'04fe1e6631d503a9ee646584cda33857fac6eeca11fa60d442e09b2ed1380e5c','132db39f545eedb3cd0e83555a4b52abfd02ec6cef3dc4f72be61f72093fc236','ac2fdd741649e03175f33702b196d2b7cbb46ecd832cab23119e35f325ee93d9');
INSERT INTO blocks VALUES(310050,'c719b9e1f31934a3bf53ed8f8a4f59ad22f3d0481008f4a7116f31cbfcd2b71ebf296f8a6890f522c72303d63c6f6b76b802f5b93808620f3b6ff515155ea73f',310050000,NULL,NULL,'dc73bfb66386f237f127f607a4522c0a8c650b6d0f76a87e30632938cf905155','508de490992238321c7925c75b5a86eebcfe5cde6d15bbf4b8dcaa53e44f42a5','660802f67e21a845d9c41e311e2e3d574ca05003e21c6704919da1a757598909');
INSERT INTO blocks VALUES(310051,'e88246311bb74b66ad0f97fe2f5734e0c68d0329f05a389c35ef8a8575e8c078b92b401bccdf84f2950fd884cf0c22e2079594050292b01ffc69c8e779150ac6',310051000,NULL,NULL,'e4eea2d144c8f9c6dfe731efee419056de42f53108f83ebee503c9114b8e4192','155033aa7dd5fb7a2a47c6242aeefa1cc00cd4b686741bcef297adbe238e2907','f475e82b7bb8d4eb0734377995152b188c08110cc759a10f23b031a9b97c6ba7');
INSERT INTO blocks VALUES(310052,'1c7e09c9d97f26b1be51752c372a88ff5b5da358c76002a42647916b5e27d8e0f75effc92c15f034a75cab7ca8d8a9ec34c64f1fbfe8690c585cafc553add37d',310052000,NULL,NULL,'8d12b561e7cf87b0aabe000a93a57e5f31db75510b1e9feb19b4f557cc0e6604','4865fabbd6bcb45a221948bddeadf9340fe2f42e922deea81b9aa629e5c597ae','5c6fcc3cc90ad574cb3d1bb1f61e631b5e65fe7ff376902bb3b37a1fc97c28aa');
INSERT INTO blocks VALUES(310053,'60ed831a77cedc82909d871edc4e6525de5669cc238f7b9010336b4f5c80f4eb29fc8f8f05cb9a41db4e1311f437015c8bb02b214b69cf04f909e14868ccb66f',310053000,NULL,NULL,'f47b81b3dfc522d9b601d1776fa2deef8543ca077cb0743556cd970bb119d640','1aa121c179b4d79c43ee453ab1f32b09f93adc1ffa1ca6163a8e3b48b0ca754b','1671adea63911dec5da052fc18e0684c3f116f8276953100f99d06c19687a020');
INSERT INTO blocks VALUES(310054,'0871d6f27552c73bda0f3a9f2557d87b89a0589ed5da70ed84a42dd89456a877d24e0e439953fff2123f110100aaf350755afe5ba6ccbe4f01b1965528e1b39f',310054000,NULL,NULL,'df191ed877eb1856d6780a717c04d6925246cdee7dd6df74216ea983560d5a2b','0154c346cd42ff13a8d69b6eae15e63a47710f6e75f476dddc7fdcfe75ebf02a','3c9869aabb8597902c7031d9a45d12d2958d3c3d86c364217f66d0d926aa3ce0');
INSERT INTO blocks VALUES(310055,'3edee52236cc6d3fcf0c9e108ca28515924cbfa3b9ab8d6f2ce59b1f234558ba3d50c88381fc53f0d607e67dfa8cf497f45f32def36c5a444233a0edaa649987',310055000,NULL,NULL,'4b0ab72111202b1f9a5add4bf9a812df203cb6761a8d16b5f7a8b9ed6f2b2476','666917cd57a3353c5f73542f656149ef9fb66d7903148ce07a7743f6960c8b86','33656efe6cb5050daf7135aba83465f5b780f9fd9e45c5ffd1643dd1cb15d566');
INSERT INTO blocks VALUES(310056,'bd46235733652f0ae9e77cd97e22a371fb6778c023c98e49684616eee72b64696b1376ebfcc8e897ceb18d8415b08d5d8b27bb788bb1f6de3b8baf985e2f5c0b',310056000,NULL,NULL,'8e76b5be6a94e1b50ba16fe265965d4cba01b792216485c54360052e78788f20','cda01ee025e217294113d1717fad9b5a61cc513b9851134e6a6cdbc3de4aa11e','557a73066f4cdc9d08e7dd00f00fd4235337709352288edf80902f7c187c33fd');
INSERT INTO blocks VALUES(310057,'91e818ef3f1425e86d13808bcb5cb4125205d61f8d063f21cd37a445269ad14f96bdc18283a12ddde8d6775bc55b2ff91c7910fd7d512ee242dde68d8d4f1520',310057000,NULL,NULL,'e14dde2bfbe4f9076b7ba548aad37269752858361af094b4be8b956c0a28b9c5','c2a8bbb1bc2b56337735db8e7a9e3fa1a239e8b990ff0794073d4e3a179099fd','5a40ed919716d38590b7596f61f32904f5412a536f9d62e05b38b38dbde25d02');
INSERT INTO blocks VALUES(310058,'ab68270f350c7c11d62cfe38e0b20c6763c770f9d9dbbfaa16cff8ab3d746a9b71047d4fde90c7705688b7f36ed3479a9718fb1a455cdedb5bf97309e3344e3a',310058000,NULL,NULL,'b986e5f6486ceac7f1af41b1da968e453cc19376d588d8e884439b51313d6e30','82ef2230fd608356811926a70f729ccc8c5979435d8e2a392bb1734ba3dec388','e192856f917f929a02fdffa1d2210833df4706c5b8f9462d85009ff8ed960cfc');
INSERT INTO blocks VALUES(310059,'d08b01ec4f2055eed65363e748f638470b4e989c815ba93395c139de56eb925e577bf05c46a1cf2051a238a2ce1c62bb137583d12d9b5a30e3d1fe2118e50009',310059000,NULL,NULL,'da978ee5b06812ee42cda43e1d9943c4e34e9e940cb0461f0ed463b9299402d8','deef0927a0b6535a566c187321eb1af4fecf75170ccbff489c9ebfe9eb59668e','4284bbdee01d8a711be6002f9f654c5b9da77f3b030a078973b913afa2434217');
INSERT INTO blocks VALUES(310060,'76cc352a0973bd5cee8255c511eff6cc34a554d636ef61ab3ef6621dd0eaab17b3032e5ade33c8712b1d45960ba779974e79998b0b7738b6815ac93d2eb8181d',310060000,NULL,NULL,'09ccea87988cc385b9d2580613581b90157f1366d27cd3dc1a4385e104430d15','779bea86757f118e73cfad578b2df2c6dc049a4cbf69f512beb841a523053c97','99c7b4f1a6113b9b6d958a53a0e2b62107d5533c97f1cd7fde5857a408d0ee36');
INSERT INTO blocks VALUES(310061,'80a038ba3f297cfc699d7be560b9be58d8a88f4b127468e22d5d633b6b3e359430d738c20f7c5182a435bcc1a49a056e84ce705ccc504405bb70700030f86260',310061000,NULL,NULL,'4caebeb5ab6468e116cc0cf137977649a15dd30d9b214a5081057a551174ec48','1f59f8684150286b5d6e4d1123f95e7a0aebc89be2a8c2cf82457ae7bc25d4ed','0d636c66bc0d22d664ebc894850f0ee98b2e4b39a41a245ac117b5a3b5c8ccb5');
INSERT INTO blocks VALUES(310062,'9fb37033c32405d7e00ff9b69272079af198e9960fbddb8dbba542b7b6911ceb833868bad3759566a7a2736b9d719ca82690627d83491ed40467e6b18830a711',310062000,NULL,NULL,'51cb3f1005127e3240721c47805d67a123afdc40084692a9cc2b3215cec99dc3','a5ef74091aff86a5f486ded28123e2cc583386fc5d2743fdb69687b06aad9d3b','35d1caa4113fc3975fc8cd201d7782f30b9653d69f5cc9cfd60caa659672c126');
INSERT INTO blocks VALUES(310063,'807f83f652635dd041b0e46222d9a136099f478a5159c501735eb3a64b32d664250ec44f4668df72b1f2b8ce34ff2e1c260b6fcd87febebcc44e99faa098cd7c',310063000,NULL,NULL,'e12864a0f955320278c215897cf4f65e5c378e534294b0bb90ebd7e4b5efd4f7','9d6918b9c534fa83a7e701249220265fea8a0f49ff6d2a643ca404d2b60fe391','ff5064490dd9836b6446fa9c7ed88490b7fbc8575964d82da96a4837f6bd7406');
INSERT INTO blocks VALUES(310064,'cdfd286ed7373f1a2b525d37a903df4ac53788422414fa5fa5b408dc04d11991b3bb3c7dc7be3bc98d65c31265c01abd59f6c9f4cf6cb25c8da4a28fcc74f576',310064000,NULL,NULL,'ee27c3b46aa890d18be950006879874a094ecddd086db195e032fb4fe12559f5','9f2146f3d52cc428fe85d237f7c47e05d6e55c2b59dfb448eadde903b81b8f67','5a8c520b6618cdc1b140776467aeea0a8928cbfe0a69d218d626ef6e536c7393');
INSERT INTO blocks VALUES(310065,'e971d529b30e42e87f399558d975181220fadc9b160b37dc5fe82752be193de9c7022dc509061f99158c7e585799f336ea3dd8fe63d55b57772af676e91108c8',310065000,NULL,NULL,'d40dbc4b5faaf8918f9cae54e5a247e3904dc65994ce0f04f417c1a595404464','0cfac9f73fda41c505382566fdb8d3e9baa0830775ba582a9896e5590afa15d9','74d200ab405c726efd0cf9fa19e5cf3a2ba479ed22fa9352765ef32c61f712bf');
INSERT INTO blocks VALUES(310066,'0758bfcf08b5a8eb40e4937fd84fc69458338483a8471865b38fa252d8644be6c22962996b80aa3fb37db97f2e2a213049c9cb356d8564d26fb1ad5de14ccef8',310066000,NULL,NULL,'19f2b00477a6fae0e10f4693d949cb409b1ed74ad20dbd9aa4a7f1f17cb813ac','2b5d733cb49d95e4cadbbf89123b5e649195191c87008f973f2e74e948bc1fd6','2546db110695b318366bf92c69d79dc3af6f60d26f17856d66ddbe0bcc3cc795');
INSERT INTO blocks VALUES(310067,'359caeb095b44b88cb86676c4a94ac830211c31e25c326c9c75e3ac60c5f28c1ee7387fc46ac6ba2946a6ce41a067637047ac4effb32777dd9f694ef1aa88ef2',310067000,NULL,NULL,'d72891c22fcea6c51496fc1777fa736ef5aba378320a1f718d597f8f9fea3c7d','dfb47a854b84bf5d03f1f9a3a32a86a14a0968d3c3bc2a4d1daa4a281d248ef5','fb83cee4e4ca5ac3619b2269ff52186eceafa255dabbe6c4617c48e1434b0865');
INSERT INTO blocks VALUES(310068,'2f1264342a2fd66c9493f2fa062cb8477ef86f72c532149ffd45353fca250a9985c027d7ccee2e646c96533196f6dd60ef9bcb12b3f156dbe71edbd088418487',310068000,NULL,NULL,'5793e10b8329d3ac71aed6347dfcf61fc7b74ca162ad99918f5c20065f8d0746','af58e9d5e25e9396f5f447107cd3bb5ff7f7c3af6939802f7d8c05cc7596db05','b7291f17ff8b96f3275b376d8af8d9a329d27c7f912b8f6d40026366213ccc10');
INSERT INTO blocks VALUES(310069,'b08114be39f1ba70cbf72cf9ac4b008d8582dce4d4d7c789e7da57eb264fab24fdeceae387dbb23d5dc0c73f8faa013c5a499ee8d2761b959128c9694802230e',310069000,NULL,NULL,'61040e7c1a58f41d708785347f4985c1fb522b6f947d3e14dacd91157e153ab7','bae2ba15fcd4bfad6b951bd51e3d45b024d0a54b2870b38b40b83aa509a49c74','fd023690f4fa7b02f8c0f0256d7c96a20745cec05edb4c749e4e4471f11f73f4');
INSERT INTO blocks VALUES(310070,'5f1384e1063f3c21946d063c75dcb43a6ddc4642eac6f79eee0a80ea99320bf8b26ecf86b1e79889e1c733cd278219e76315130a30b440d84cd288be58bf3853',310070000,NULL,NULL,'ce115625fbda90a0f261b2c524108a7393078cb4c3f861d6d7846501c7960008','a52ecf92a361b78921a93a75c66cc47a431dfa3e034216c4c3bc2ba18b3f0879','b668a217c4c2d3ef5d7361e6c5a7af29e09bfad17f56578e3fa5f387e7a595ae');
INSERT INTO blocks VALUES(310071,'c80b492818257e806e4fbe093c89c7965275aa8e36d1bb888d1f79a059e95dadc40273e59de99eb8d80c5e8e1445509d8baee4c733d2c470598620f3048cfafd',310071000,NULL,NULL,'3c2d4d81e90a42a0c18e9c02b8a59f99e13f2a084ee66b4b1bd410077adc383d','f0b383e90fe967c4968364bb9a2a4eb8697c5e710deb460d91f5c3a31502118b','033153d1799bfbbaab0734b44d6ad2d920e257323339d02f3963a365bfbfbbf3');
INSERT INTO blocks VALUES(310072,'64a311227b25fe4606729312295546a9ade70637e896cdd8321257c0b173e38701be1e5bfefbdd2cf1eb908d5076f2b464c8664281cca6a9d9bfd715ca085a93',310072000,NULL,NULL,'8a28e33306582346f1d965a0393621b4aa307f6614c84369064465f95a6c727e','7fa72c72e6e2c1d508ce55a97cf27e9f85cebbfd5d020bc6de2bce7d8a7d632e','d21f7905f6e9bb791f35f8b9e49019e8a136433e7d47bd0cf2b0e9e2f598f298');
INSERT INTO blocks VALUES(310073,'acc6dfdc3cf0651092a08818eed4eeaf9abfd322f1e46bec97e6a8ce96317612d4f3873e194310f1335da4ac225ed92b1a59237cde4fe1d2049be6a2b66c1f1d',310073000,NULL,NULL,'e6c5b393a21df54479c4cd8e991b37d877794166c19b9f61ad7e47eb34f63bdc','630e908a8f9ec8ca8dab6d57609864ff4a075fd542ace484cbbe0c2d5e0b2957','b9e9b713e1c7b4fc826de4bea275a3290a5dabfb2666e3ef59d517017845c6cd');
INSERT INTO blocks VALUES(310074,'a00f647aa4b5d9142500fdc7da95b47c60c0affa3275cab56a875b1e082fa8037b3c32e6a002f92010c2d8bc1abaad10c2373fbd246b59e69af1e97df5c3a3f2',310074000,NULL,NULL,'b2db452daf280f1cc5f02668d0cbd33732a2fe9f04307d9c072eba97c95acf5c','14b8c80ef303c4cc1d3e8306e070b1ad175eac4b07b7bda3f707df3b26a8b276','90052eb53b5080f636f62f2bdaf084311052a20954fc496ffe61c3759bd36ae1');
INSERT INTO blocks VALUES(310075,'53035b827f91f83e75adef2f62607377fcffcd185902cb742a72d751e4d57e0432562fe92b0cc6f7221ecbe53ced6aea685ba2383dd9e2a78fce462778b75010',310075000,NULL,NULL,'09998443cf1cd79e193a7b09681ae07ea9a835458151a7f8c7d80a00c5d8e99a','cadd429f121e3db8042feaa576dd5e2d17901751d121ba58c2ebc52eb63617e6','50dbf3286729c6780d9d17d1c6a37cbc7734634abf4dac224608e525708c56b2');
INSERT INTO blocks VALUES(310076,'98867155f362ec51c5d01c1ee81fec7c0fd5bf08892df7e78140ca21c443c084876793d528480ef54ea1e185fe435869dd7dd284119b92f4a3f63d05173a6580',310076000,NULL,NULL,'a0be1e88f10b5214f7c12dd32d0742537072d5eb3e54f9abf57a8577f7756d7e','8bc9ef084f72e8b0f898099a058373151af5b4cdd0c461d720be3c98c32bfdde','c315a4c0ddc3db5eeb538846764530efd2f72809fe43d87079d572b968dfb497');
INSERT INTO blocks VALUES(310077,'2f9ac5c43c034f11cf28d62fb787f8c109662e4187b8af0d7dbd81b524f474ba9f4ab6bb6a36ce44003839ba82f7018065499543c9e3b4b1be0e96b9d56cd9d7',310077000,NULL,NULL,'d41e39038756ee538d9438228512e31b4a524bbd05bc9b9034d603fd20e00f05','b5636cac38df975a0a80215a5c65c06532ef45d0973130db2de9cc11af84b63a','604ff1372e28cd7bd2f615cd8c7ff37ab4f68341bc6292db72671f9c9060a219');
INSERT INTO blocks VALUES(310078,'5e535d532426974fe1c45ebc463ec7a93fc3625a5da33119975481c4c98ec8ad81ab13fcb7e8943ae4fb26b41aeaa7ca0f50fa22d16c7d18e5deb3820e96df1e',310078000,NULL,NULL,'996092432a2d94df1db34533aa7033e672fac73de5193a696c05ae7c30d75247','54c00267b16bf5f307cbd1063115c15fe7d9261ed66c70b59fed53d6e76db985','0d5532d826c63cf5ac97c37f02c8c1bfb6074c5c429ed1c31638109fe85648a5');
INSERT INTO blocks VALUES(310079,'e41a51db594c3e7919b4aac63e6100a092461b81518721da953a476986f5bf8e29085cfe6a08ec452fa547b704c4c4eca957ae193c27281dfa7f113a0f6df941',310079000,NULL,NULL,'e3f536e930e39b421e3a0566eba6b8f5f781ad1ff48530a5671752fd3eaf35ac','a6264d89f9a7756cd7f360983c3a14759b5bc12d75de7a50eddd84c7eb638f52','ab7e582e5f76c82039aa274cf30ccc653d5052166a251d3d89f119756ed663ea');
INSERT INTO blocks VALUES(310080,'fa67febda99884d857fb9bba17476225a600f76535a9431d21c261662434b85b9b4d4ce3cb591d043f80ebe0adaf9263e0a368d949d291e14778b46d07dabe91',310080000,NULL,NULL,'57122dc41d7de2bdc65002905617c357496432fa4d80af48f4ca69ba1332e634','393b27ee74b2c2df487e071790079d2f6ea51dbd80a9d4bfa182239d3e3cd16c','909dc5243777cebf90fc2dab219bb2c441ce2d1b64540224ecdecaaf69b14c9e');
INSERT INTO blocks VALUES(310081,'98a5ce8fe941cef091735620c3119d97a382b9c80cc1764d1d30c94300037d0e519063378746b7edbfc60aa506fc04ebd539ada353534b7a5b3d621dec791da9',310081000,NULL,NULL,'3a0fc7b2f0396d257a0a5c5a313910cb4073e4c79ef8cf0d3cd12f494e563105','bfc8d7695121ff8cffb824f79b7a93c04b34fd75fe89774c0d2338b9640f87ba','d5adcfb9dbcb3a714a167358228fa035b21bb109e83a3ef2b1fb840bee02cf37');
INSERT INTO blocks VALUES(310082,'7702f9604bf3efed6578761f4c52de99779c7c42d7543774d425a4c3537befbd2e7181355f8a1130d3d8ad9ff3bbeaaca4e26cfaefff15e575ac4b2eb19b7051',310082000,NULL,NULL,'e876c406f682ed6f0dbd6e4c97bac13409cd400b59e894eebeb3252be306494a','aa79eed670c6b330d059826a39a2184af3793110ccfab4cc9fa9a305625f44dd','d9402d33bcb4e9e968ec7afdb80661a80bb42d669e4f40172618d9a989c4fb32');
INSERT INTO blocks VALUES(310083,'f190eca1a75147eeec93cf96f106e346b908fc47e6a363093d5b229901bd58fb34fc8db82a8feb2d3dcbeac0c901ce98378f7e1dec0ff7aea7235c6d822a62b0',310083000,NULL,NULL,'533fc3eea80caa46cf8fd62745c5d21d09f32b18eaca70283a4bd72924c2100a','82281d75680515ecc21da4d12e3a9841f60d74168f27cf98b1598dddfc472c75','7715bcc13b9533291209987dfb15e7e4e364625e1479f93b87bf2dc60385b509');
INSERT INTO blocks VALUES(310084,'d15e3c53c8bad6d8a4dcbb870b622505e4dabe8b3d3b7ffac8aa4976cdcefc91fc13c1c1a1700d7417e829310f9826fbc82307636fc3f95bcce561a8dd8f7ea0',310084000,NULL,NULL,'e3fd22f2e1470246ca99c569d187934f4b7bbb1eedb9626696cbaf9e2b46253b','1229f55195fcc7b15b6f7402b47a2592bb4bad4e337afb47fafde2b78d85e635','e7fa6f4db315de38f7df578f9fe97765192772d23651107965db5c850ecba930');
INSERT INTO blocks VALUES(310085,'464aeb24455523d820981afe0f284487ec0a36b1388182f88388370811c394bc18686bfe2b8429f7d37569070f13e95952e877b7a84000c6c0e769e5e76cf437',310085000,NULL,NULL,'bf04750fe13f663adb12afd3a166636a4511bf94684a77217de1bd7ef9077d94','c614476b2d89ff0981fb20f2a1c967cde09d9bcd4a5205fc864526632356d6dc','e154ca86e3f15525795813cf64c01ae41636cb341364523212546ccd64a0f869');
INSERT INTO blocks VALUES(310086,'0c1d3e5b62d04ec82124010d58d052a0a2f9dfb71684580d0c5a8d37e286768f5eb4ce31dd4a677bbbf199d47ee843ec864deae51f4b2ca29d765015748b5742',310086000,NULL,NULL,'a0e8403085ba63ba72432f27ce8125921ef24742f988ab7f85dd8e4309f27a2c','dfb06c466dca07d78d264b13447a58b92a774e3eb042f184284ef59466a8db40','dc15e819de89cc98204b4e2337d97f980acd513aa9b3046d2857f272fa92905f');
INSERT INTO blocks VALUES(310087,'799dd8fedf7036eca0b8298ac48c295690d12f9c71aa98727c927a6cb0224c62433ab878dff483f6d2754bde36f06fce594bdb06559c1d1a0a51848bfb395419',310087000,NULL,NULL,'0861b02e980ad5958bd23ac02603b132efd72ee2a70dbb0415fa5d39cc524681','0be4d70193c707ed36f4cca3d1192f60ccf61fa02c2e03edab2b85dde87a7ae1','5ee3817289cf190268ba9e236ee4923ce94eb1693e0a0f0cc56f351835992d37');
INSERT INTO blocks VALUES(310088,'8e1e809b86f3fbde2cabe6510052084ec68d7857c34f8dd334c99e8aeecf32ac1669f2789aa41acf3f33119c5d0aeafed03d8288765c178174a8db27887c22aa',310088000,NULL,NULL,'d52cdaa449f63f6d3abc79080378855206f91a5db865dfaf37a5a2529ea6eb9a','dd2604bc476e175c2de299325984a3635b0a804707ff369f4af42c56d2ccec39','7fa930327b1ba20a4d8ca6ebc97bac6b9f04e9f9f279abd82d09e2450489c2a3');
INSERT INTO blocks VALUES(310089,'9803c2ce201e643165ba86a8a739ec73a05f29d23237d8d2de56f46f417be665785871d0d36cd3146f999d0252635b9ae8a3dd86f597b1cb59cf6879e116b5be',310089000,NULL,NULL,'d15a7a60b8bf8618667863b3e31eaf6202664e5aebc16d1f7a337b857ac31f90','0adf95ed638c7ef263970b932bfcfb4042b21ea4bfe357209ae60be5a3d82bc9','05fa6e2e52df432742e548f4238665351a77792e5a415ab42a4df3f35fd10d2b');
INSERT INTO blocks VALUES(310090,'1ea5f2b04b763909ad541951a0d21078be9d08e6bd7a23499ea69fa4ee8a67f02791404da26f6b64ed5bfc0bed66c28e4e98b703d7466f96311c5c838ab6d9c2',310090000,NULL,NULL,'68475dcfe8252c18501fd1fef2afa2a91d20b92cacbabb542c12f43403e66ea3','88a0d5d9922071dfa2bb7469e79b80996eeecbdca87ffae79f1a3b3cb2532644','9180069c41e39cdc6ba517cd26dfc0d31bc604f4a00d5d25eb860fd9c2d06228');
INSERT INTO blocks VALUES(310091,'09f4ee2e18880732c0ac4f58e012ff8fe9223899aeae5e051c9796439d98570637670e0cf50c0727e3017287f268466368c550fdbd3bd210387615af76c0a515',310091000,NULL,NULL,'5d584f255e5bbebc32c78a30fa816e1203fe7d3454611bef9222cdfc91dfcb63','4dc5bb1f5093f66e2e605cf182cf8aaff59d8100f1bf0c31510f69e26203239b','30f0c845f19aa2ed6f08c591685fe481721404ce88e7378c8bcd1877e65aa043');
INSERT INTO blocks VALUES(310092,'ae270aca6bf2998680fd12abfdbd158ee5bfb8131fddbe54f5466c6f7a7ff114517a253f8756e13c2bde73e9b851ad2b24ce06bac2086ce3e240331bae518a2c',310092000,NULL,NULL,'ef992ad033b047b7f6ab038604736f444da55be187834f8152b173cf535c68eb','e29fd141b0f4e852f3bbfeb6ebd7e2b524c5e64b92e943df9d839a5e94d58e66','1ed08e5d65ee82864e94595bda086d35fb4b09d274f2d3e6350de7c8f176cf13');
INSERT INTO blocks VALUES(310093,'2c950816e8a2e9c29fac064891a58465f30a62197864d549f856157c223a1f78f1e39f753e792f64b48c500d77e47602093941df590450d21da55758f81a659d',310093000,NULL,NULL,'9cdee996d0e67ac3f9f283151b428ac5f223b72590965f41f93adcece6b88f2a','83085da2e280216d215113c8d0501b5430f12669978ff1a76a97281ed4b5a185','40e9478b896351a1f96ee7b5aa5cc66cab6fa4090865da664bb72d57625c9f4e');
INSERT INTO blocks VALUES(310094,'c7eda9512bcac5c3b73e17923afdce541011780a51f2f59338bd91f539b223655a64a2680972f32e340a268ee6dca4caf0ea6ed8ad02a3840e5ca7075c6cc69b',310094000,NULL,NULL,'fa25dc3f15fb28718d788f85373555966251f54bc6ed1f4dd2244b438d27b281','2a589f4f1b237fb4c1d10d96a906c4096cc5015eb67a7f8ddb5829e0e54e5118','e25315796724d19f977c34e7df8d79d5ce37f5f049e716707b446266b34a6b00');
INSERT INTO blocks VALUES(310095,'4ff3aa594932ca9e13370bd1a9fcaf0d07dcd6c28949afda5fff201a876e77331c483f93c8fc7295d3c8eb0d4ed3d4f53d062e17e87789392db93bec453cf1d2',310095000,NULL,NULL,'1ba8cd971f9a169d43b6de1a136cb8e6153649fde1f7a8e7fb2f7de926fdf8b2','e050ec0b7fb40811c6116e00d856c3a154a123e232529555638bd568cc52718a','efe3ef53018f15699edb6a0641c18d554be6de54515661f6cc9d5631afb73c27');
INSERT INTO blocks VALUES(310096,'7f6ebf5b7e09d78febea9dce370ca98e1a00cd911b6ee8b4c1f46c3ee5e54754040ae2e5443d5e53ff2af3b615b08063111b4876e034ef31c9ec0f5e75695772',310096000,NULL,NULL,'42c36df2c53d762b9b132e622f52b2fca99bc0370978463acd22cdf6469587a8','fe388e8afd5cfb1d71d2598eabe92c3228f077a9f7d1f9d5797c3bd92c4ae20c','ffda88255061efe326d020d04a66f795b08387b20d288f08c6d16406a3727046');
INSERT INTO blocks VALUES(310097,'e44698e52e70ebb58d3d004f8eb4943aada1835e5ae673ae54f5a62231df0f0fc3a68ece57823e624b4f365ce199d50e35ec15619e508f8cbf71134d82facefb',310097000,NULL,NULL,'d96af5cf3f431535689653555c29f268c931f9fb271447aed050303d364f92a8','ede2f1267a2e6cdf40b96a1acde27c941fc0c40b2be395f123bb870a475aadc9','8d04bccea146efbe2b2b609e2edb6ada0c58f00c1cf021ac036cd159d5800f53');
INSERT INTO blocks VALUES(310098,'031441b70e39a3d6dcf5a532eddb405d5abd8d723029ca8be3cfe400f0e4fb012a63d859e610eb48c7e41c4e80768e877321e92f8ff406e700d8c161e8a3f4d2',310098000,NULL,NULL,'153c9ce12e8d9f9d10c4005fc9af158613480d38b2c6551fc49bc57380c229de','501914325b77493e2268d1602edb6f94072737d21c64acd7d951475a14ff6d72','90bb0b550e23c36c9d4ee03e252b9633887daf3500fd83aead3b9aeb6584d7ad');
INSERT INTO blocks VALUES(310099,'2456675ed07aaa79602718040e1f29e546938bec8a15b26492dbfd58d5388ea21ff3440ff29138f4e2cfb47662ea3e4e50476f7280c0e58b51b53bc08c014fc2',310099000,NULL,NULL,'49f33b269d717b56a399843cf4627449010133b47079134b9e299ac5386468ee','bc6c92f66de834fb846accffd7bc69cb58f45d1b86c77678c787513969186cec','cb99554f9b8f29ecfa7b235ee688836c4c9234fd8747e83ad8fa7893003c4dc7');
INSERT INTO blocks VALUES(310100,'b9b9a79de83063df4410925030cc3710aad6999f8ca9955305b477dda2e3777293c7ddd7c4eb6e9c3f2aec2e23e2415d0037dfcaf61a52b351ca564f2cf1556d',310100000,NULL,NULL,'c9e72f7db2950f0b0e6e8fa3bc47d37a0d643da6ec61b236f7224b63ac60467e','a6f950b3b2128f5f314a31f4ef15be609228cc880a9b1b3b44683cb98e4e1456','a80d0857e71d248595573adc41dc714476ad684ba2daadf036f043bbf24b8fe2');
INSERT INTO blocks VALUES(310101,'e8a8ebd85a460cf5987683360a1c77e6728b4e59027220f8eceda05c720bc38c91f6193bc43739da026cd28f340e1a10b9900bfa3eed11f88339147c61b65504',310101000,NULL,NULL,'a4387c8c785a8407f2dda176a7e182617904e7ce00c695ea8aa2f9d0429d9e74','0430e52300a5384f49f68f3e01aef253d410e036bd6ef80f887137cff0213023','8aea76d63d711e0ab4bb05317bb09339e89ca0ed766a4660ba3cdd6b897daa02');
INSERT INTO blocks VALUES(310102,'767209a2b49c4e2aef6ef3fae88ff8bb450266a5dc303bbaf1c8bfb6b86cf835053b6a4906ae343265125f8d3b773c5bd4111451410b18954ad76c8a9aff2046',310102000,NULL,NULL,'fc81f97474f7b35ef92ba93de82d38650a28afd140d3320e6f6b62337cfd1e94','9cdcc9c9d1d0e13c1a47ed22e3d02e978dd321a512287bab4f7fb6840eb0949f','405c8cd46a4ffc6a9772405bcfb36bfe2dc27c35bcb87cfc5a90c1964a803c28');
INSERT INTO blocks VALUES(310103,'e9041ceed8f1db239510cc8d28e5abc3f2c781097b184faae934b577b78c54435a4205ee895ccabd5c5e06ff3b19c17a0a6f5f124a95d34b3d06d1444afb996a',310103000,NULL,NULL,'3a502a89a3b66438cd2b944f8951a78999ba18c5f5bc8abeafe373ae4625ed4a','a0d6d7a48517803a17824c63645608111eaac2c3665fc33bf5f758fc79d99381','b35f89584951358aba6733919c0ed0a9519ebbbf7878a0cfe79a8358a92c0e22');
INSERT INTO blocks VALUES(310104,'04faacf3df57c1af43f1211679d90f0cb6a3de4620323226a87e134392d4b8f7fc5d15f4342bee5bff0f206a64183c706d751bdace2b68c0107e237d77bb0ebb',310104000,NULL,NULL,'74ab5df2cdd13b654c80ef12e460120c96ce30d4690a06671474235fb93fee4a','5d56a8116690ccebb6bcbc43fbe3a25b515bee1359564a48e48040871d51ae57','07c4d540bff06264271fb56d819cac5cdea0817eb682e0f399e53e8e64869f30');
INSERT INTO blocks VALUES(310105,'673579ef7bc7828b4427a7144355901327f4cd6e14a8ee356caa1a556eb15f88d6f8f599556590f9f00979dc4d4cde4ff5ea7e2ae683e2a14706fc03aed8ecbc',310105000,NULL,NULL,'dcc1940370421712cc668dc401169a55dd7077a49feddfd70e9e455aa5893962','b91da76a0c87e592ebfe9dcc09410b198c25fb44bcc6af20cfb3d545630737b3','b7a65be2c3719db6d69efd5660a3fdacff9ea6d0c3cd7a4dbcaab01f46d3227b');
INSERT INTO blocks VALUES(310106,'8dc95e1d0fbe11694812b71d390ec5ca5058fb64d34e2805273d5d71286865371dd1ec0584e6ba1fc0b9b09f1d43f9529ac67f134fe30685f1962abeb88fcfa1',310106000,NULL,NULL,'446153de1f26b20dfe815552e589ece5615cf5d908b7bef51bf007d72b7f7f09','926ff4c2d9e43ec20528fd9810286c1dd15579f5336221b0dafec6a55e7a4eb7','625dd16d181b7a6f3aacfd298bf82d54384f047167f62dcdc90e9df0cd59f8be');
INSERT INTO blocks VALUES(310107,'535b56c056428600fa79bd68d4476504453f02fda130fe45b3f7994298801cf0791cb1a858c3d3b90780941a64e5e788e828032268e3e94134a7fc05fc5b7c8a',310107000,NULL,NULL,'92dcf9c11401f3fb7f4f3b5f1f1a07a335ad64e8663e381115a0bcd6e12f19ac','1e5e2253bcf9a3dab3ae580babde93ecf13fcea20d21fd0d8f445574f84988ba','1fdfbad93be23f96d955c33a97cb2ea3aa71bc5f200d40f5ffdca2ed1d279ab5');
INSERT INTO blocks VALUES(310108,'ede71647f0714fceb0edf6ccf71302ab49c3f2ef88e6729bf71a158515213aa97a5226eda7cc90763b5e8a876107f5e2db0ba2897d384acf830068ac0d7db43d',310108000,NULL,NULL,'a5e784919ec9e336b886bff28006024c7a8714dcb6ee65c765b1f0ecf4c7cfdc','5f9caec8daf5d4cc1ea20fe945e8c5732893307fb7fa5faf865acff674d61c21','307126ffecad00ab6f86174f23160fbc7e8f1f53ff4cb6689192a3d1818a7336');
INSERT INTO blocks VALUES(310109,'fc403195b5fbfe288fa26dcb56442157451584ea556d0897f9d29abf3f94542d6f6604e48e2f647c56c5fec222b037e0f4589851935c106ae167982189f37459',310109000,NULL,NULL,'492c26b26d6decd372da2e3f68550378753abb3a892ff9d16913ed249c783d03','e6948ae21e15cf7804126f340e3a45fd0a9d44e69fd59ac1c9513014c4cea48e','fcd912d4a325994832792da83902fc97f0ba5d36bf5faf605c23ac4d9ddff10d');
INSERT INTO blocks VALUES(310110,'707c243a03e691b170b6838183e2a5a710b77c30db606babf8e347454e99452eb50e0798723a5ae3ae1c87e7e417cd1b8a5d6478905add9dfd1e2358f33160ae',310110000,NULL,NULL,'415a8ec7dd0c715e96a03873a14a11eae00dfdc44a6c5fd5e71dd4e20226a925','97211b75e32c29d82f149b79160214b0ca2ffc2c2487cd450b9c3d65bd19ed37','763a5c43dbb90ea427bc9ae02667da355c7dd6dc12e07e324491634484f445d9');
INSERT INTO blocks VALUES(310111,'b423715bbc02048a92a2621b4edcabc2570780739d4f7e9ec1f584cae4ba76b945e4cf094542dae1699dd411a4e1d5eacee9506eb91e04fdaa98404c8e4a2b8d',310111000,NULL,NULL,'c7687dc588fe9f2333320748b440c0acc8836d2931bf45af201c41a26052d31a','aac31694e2b886e5418f22781abd89f9d8aa6d9f6920f7135bacee87fbc8bd4f','167d8721a06c4f63b7914c7b3afd559a7bded90097bf3371e22ebfa98d93d842');
INSERT INTO blocks VALUES(310112,'6760a191b0e17b1bd256baec1b67d9f140c7c27a69bfd942fc2afab8f48ec22b4df69f90a71d10d1788b0ccc4899ad9a63e469f8f53f59cb62cb6a16139acdc3',310112000,NULL,NULL,'8b20ff962d3bfc1adcb7ce451d4ed36200ea6ce26af0e81cbed021a42b016a28','1e66692c90d829243e257cdf129dc76dcf7d054866676fb8b8ccc29d33aa5a97','75985d4f3d35569355d78994f376da76f0baccd9b5c99189ab48cb1d2c590113');
INSERT INTO blocks VALUES(310113,'cf77b91f1337ff1dc93d7aaf73d7ef331dc2535be1de5658976dde55c9a94ab0feac585aef5e3ac026d2e6c5549f559506c2fcb2ae21ff5449606680288aa497',310113000,NULL,NULL,'75956f57017068455bfb2ca74c0f196bba46f915a6c0f13c3c10f15ffaea7aa7','ee58fa759bcbe6a999c376ddba6caf14103fce302edd8f1fc95a1745afe8e5c5','3d2ddea2d27a30a077b3771917cd2d85cf4fd6ee1b535a62f5796dd125e18007');
INSERT INTO blocks VALUES(310114,'8c68200b083c884df430e76d42c61d47dac48bca18654ccd47b038a8d7d9e33b2f441b1999ac8d1ac682f20b87fa9b8755baf5a4db166fdced6a3fce0fe789b9',310114000,NULL,NULL,'aa66e5cb3d0291df7c10b706b57d7035a1857668bccea3fe2c82ce321d7dea5b','4b8eb73c374abbbbb610975910db90c6b483d0d81897e96d596575c6adaf9ca2','f97be11c020bf4eda25605a9cc92e26ca05e3855dd697a397983a3fef7b998bf');
INSERT INTO blocks VALUES(310115,'2370375d3fec89376c52e133138e9841c075ae5eaf3fcd794ae1499f7d72e1f93bae1858173de978c00f98610c442a7704686d38e9db4ede80b3f6fee2df4f43',310115000,NULL,NULL,'8538ae1f2c130e11eacd08a1fa0291cc0d13e6b0db09751544d1ada7ba3901bc','ed40ebb96d7ae84be399dbccca63fda625f989587807e90b3e279222e8b1fe4f','f99e94db611bd39cc0c1e83a3458a2b438b4ffdddf30b5b33ae919b6d8db2590');
INSERT INTO blocks VALUES(310116,'cfce2e6c2f8b60cc702ed60cf97c9b7d98098d114b4d752152746015d19232e8f11bf72d7cdaa8cc243ed6121324c11867efdcb46bed4751e3cf9310a39c7b3f',310116000,NULL,NULL,'aa3ad995eb4e9ded4a6ad50f0dd57ee7f9cdd35701dacb4acd24d3abd3e4c052','36723bf17f7b7c1ea0268c4bd2501c7ff03262e786b8c6eb0cc0f7095fe301f8','aa79b3b51ead47e1377e6fd03e8632ac2f2b832a8aeb77f428341a994101dda4');
INSERT INTO blocks VALUES(310117,'3d1a44b687914daf4356fcf281d86d03750fa8f6a8a2a6141361c5eab4ef4bbfc2346edc1f2fba57a9a41470a0b27886e476538cf32f189ade32b865f42a47dd',310117000,NULL,NULL,'caf23031dec026208938ecf17f49093d958e4679913cb6c2df8e5bb73b4b7c91','e2e89cbbf7c611303a34723aff5d7809dbef74d57228a5130b527b1e2a9d2f0a','aad81afd60651ce2edd0c579f35ded9beabbb165c72ac4c6be7a5824549b746b');
INSERT INTO blocks VALUES(310118,'8c5d5deb80a1636d08cfe600073fb827c7bdb08b8482b0a44efb9b281a4a6936abb870788de2684eb33eb2ea2b815b16ad2231294785b3022da6d410f7b52bac',310118000,NULL,NULL,'28a3fdac1726aa67847eb08a92be10378378a356bb62294c65aae42cb1d3d566','6134358c4529b82a0440283b6164ab04adc7df6756beb506e260829342947972','9ccddc88e83ec96693462a459a98a25d3a8d3699a28af6ddc568bf98d6229b78');
INSERT INTO blocks VALUES(310119,'8b21c9a1e6ab073acbe81e671626b89a7695ebc08a3e78c52a151794b5fc11f4803fea6423656acee2f39f6bb57626658448c7ab20058c526b6925e551ecab29',310119000,NULL,NULL,'158cb797a53b125c1b80c451101dad61a687b4d02f3dfda828968e76483d5c41','b806e124a9aa88373417b56917ecfb45d4b60baddbe9900c917951c8b33551d0','b3fcd8fa0433d7eb9a80854ee1f7f1cd5dc240605b837e0e88fa3f52e48783d7');
INSERT INTO blocks VALUES(310120,'661cf8375cf1935d65ec4ea62279c9e22a7ac258698618736f533570c82e54a84f5f287081a9659b3dd37355c836b2ab1b7e6a53b489f908218cf04ffc8e487c',310120000,NULL,NULL,'bc4f6183866ddfe32ef6023b820b3fddab7dcd01e83cae9e836128f574c51a7e','202f520937c3c78d2386b041e0b004bc2599cca2c36f02696e9d4007123c3009','a3c4710908c238cbf75a12530c28c201eb93d9322e929569ef47fddb160d708a');
INSERT INTO blocks VALUES(310121,'8e1e3aabb4996360c54be971cc22407124cac14d9790ae67a9b970c1ad8ba878c985f44e0c97f5a768a6b2b60a683aeeac9912da0f8331be3fa8376b75da2389',310121000,NULL,NULL,'67e66f5657d5a0b89ecc31afe4999f3c6cb51e7dbd9af3341fc8dfba4dbd1ce6','61e678e4edd8e2217ed676f8cfe9724fb81cf8d9be84d1439795398fb8ed9ce3','83b62e41fceb483f622b7c09fabd24a98dd217723a7fe4a584c15a3f2fce4b4d');
INSERT INTO blocks VALUES(310122,'dc61724d1d78c8d74afe0303fe265a53d006f5d13359866a24fc3118981f7b1640b74f095962a18e06b52a0c42f06607a967c279445797b0d3cf98e8bdeab57c',310122000,NULL,NULL,'fef8a7db8bdf67e29a98a6890787a40c9f8a30611fd3ab9e3c97f84d81ad9f45','7603bacbac6d2e5e7a7ecff3fa23aaf0fd467c282feab0d3017a352fbe2d1fb0','7f168d1e67305b091a212089e1ec4aed2699925762e2045062f5c117942e5d9c');
INSERT INTO blocks VALUES(310123,'90ff89086d736fa73eef455380343e90a24de73f6a83e2c4c348f15cc716c213b17d056f04618dee8bd817abc0f796fb1b491f7e662ea8245b13c7246c492d14',310123000,NULL,NULL,'c14593cf0d7f875ad139e2dfd18ab0d3e3154edb417fc808e57bba8a3acf0d74','db9aa1ef894030d392ab42a24a32c810fd5b23b22a2ae5a10be7c9c0d33d3411','dd511fc39864f4acfd7e0121473c5e7339b8a3aa82b8c38484f9639077070f28');
INSERT INTO blocks VALUES(310124,'066a44937852001930b432e453c19ca9f2cd5f4264c012ddd83b99a4c48a55458ab7468c4531268cd61333ded71de3a022f9bcdcc60360db650aa84b2ada07b9',310124000,NULL,NULL,'7a7a6057611933bf492ab056cee862b996c520ad9f1eb8645863ab96cef9b8d8','b3ffefb525dec48f38eeb027c4d1d28de06ee68a1edfbe8a9a31f1014cd51e56','def93b5d932e96dc9becddbf40ecff0e76f1f6c646e47a574d4e30f12a45bb69');
INSERT INTO blocks VALUES(310125,'8685a21db54d31658faa3da162af3f2b55ce57ed8ef63986a481b6ea81d0ae7754a9f5d85f08c84dc15039fbb0d3e8e9384304ac72f45be96ddc6963da53918c',310125000,NULL,NULL,'30f855bc0ebe02d6444e15d76e9db501d871432a711cfd35b9c526bd5782cac1','bf8b0a76f9209ae4f5b17e42eabda929b9acf5847b74f3a69c21e19c66d3ca1e','ecafd53caf2f16929d1fff8f8729b0adf6ef087dc59e6ec5a677e60a62262c76');
INSERT INTO blocks VALUES(310126,'00c5864e2defa283e09b07f5a58f3821372fb58c704506931b8674d45e4d00d5c216404ad13c5bd08c76f1fe1755300246a9edf5aba309cc23f410529c2dd6a9',310126000,NULL,NULL,'90899408484be4a4fb5a8229388069d86ad43c61aad85fab0a7380318d045a3a','5d0c8155fdb05bf6e0ca3b09ab6d63336639699cd8bd30588b474df332e06e67','3414bd50bd7d811f4ad5f3c37e4ceb0053aa25d6f588b5866cc7092cd2f14e46');
INSERT INTO blocks VALUES(310127,'05c44407d5900c1193f814ac29f41fd240da577ef0fafee0cedef102651997d3339530f754f24b9abddd1fdc4e315852b4c2b67cfe59332dc0fb35304940fd43',310127000,NULL,NULL,'2aef2ba5d847b6e863b1d4ad3392705cc1b76fb2e05e2cc7e2a689578562e933','999cd5541e25c90dfce2d162215be5fc280d0103caf222a9cac82e47a9e41389','b866661d2f339ea7ced4c74d58efb18e80084a1ca9d802ec4ecd46bb40406934');
INSERT INTO blocks VALUES(310128,'e1b24508763706d437cfb5ba878b8feb327e652a34d32fde7dee5c161d03db781ef69ba700eca3daf4c9ecaf2ec3070c63dc80fe86e8897193582f6dddd6be66',310128000,NULL,NULL,'e0ed32b31540c55cdd0052b82f336d9a2ece0d845cc1d08e30c0894d82130390','0b6e5ad04c3f6ae1ae78d38c1aa8bbf7705ce318bb812ed10944cf95f55beebe','34eec9c5b9322d690e551b4992f8a9476cc0da2a50e7f1ebcf4222e69530bb83');
INSERT INTO blocks VALUES(310129,'2bb7be63310fb6325779d84abfc2f37441503fa24bb46096d9a47a9c987f6ebd1f140eb9e870d7c12f67dd6ccec90658f0e06b117219817d98827ede56e626b5',310129000,NULL,NULL,'b0096170a84d296729476a63c5068a874eb1248a967e693636d5a8f819e47f05','86481420a27f6c504fc77133919cfeb71a5cb20f787c562bdffdf811aae03688','ecbc38b7603748d6b09092d864c2fadc5dda34b2a70973a1913c1f0c4d7cf00f');
INSERT INTO blocks VALUES(310130,'a869a7a7316f58d3fb10b828072264388b4d7ad2f71891370154c5161ac20a5e8abf36c675ae7ca8b6ea139f55cf1c0aa026d27ab5d262df8e487765a0a9f3c9',310130000,NULL,NULL,'777293e602005c15466ca4481a0f48400a7b0dc8e6e2badba3e148716bcb9687','5a4235b10eb10f0002a898502a3259c2919dedf752ed29fdc8a74bcbb6c2f7ee','4f36c4c0b7dd26b20bde7217dee2820625269c0a7ec87c0d9d41f683aa5582a4');
INSERT INTO blocks VALUES(310131,'d919955cfb962b787fb3c77c95afc59a746425655e7b01ea346f29096d0cca2c3f26c25e638495bdbf1e8bb8c97be42ad7ce100dad91c95d83d332ec35502002',310131000,NULL,NULL,'0d872d2cb9bb3ece367cd7bc67d299fc423e70112922f0c0f275e322fbaa8f7e','a1cb26c2175c57b6fc0b16e98e21d462e5b1e77be72ed3d64a8c17583305fcea','557d58587808750caf594c35ea1a3eda8137d75084ee4d207457bc3fa13b83e2');
INSERT INTO blocks VALUES(310132,'de02d99d9e7bcf88968650db048896e433675d9cc53954763f706077efd5d21e70c9eec6eaea72b1fb65aae5a678753591bb7f27d12155d69485596a3acc8f3b',310132000,NULL,NULL,'2a83a13b7de91abee9850540e8492d3b682cb6a6b6a991c8ddfd8f835258f2c0','fcff5c635b7ee10e060bcc729be5ce36cf9a27d23625afbf2e5c739e6bfc7550','46986deaf6f8b363a35d1032da1224e937b8410a9ee7fbcd23d2ce060ce1c49f');
INSERT INTO blocks VALUES(310133,'2498bdecb642839b80d981a4467fc36e80b2643d046120c4cc58c2bcca6b9238ce44f47a053840bf2e58d59cf228e7220d5c13e3a59215dfc2e2e1910c112a4c',310133000,NULL,NULL,'02bb11b54aeb19bf75f02cb4f11ce58915a7ea9e259a890c983bd633d4467edd','cf59cb54fcc51ae150a1171433f1db4388e65f2d72452597433115f01aabcb97','7f166ec11dac53900f7c3d4a01dfb206eca642059c256f331e981cb3c1c4a2ad');
INSERT INTO blocks VALUES(310134,'ea78c1a509f2bde4e35d71fb8527ef51011c0eefbc9c4908f05aedfc3d2ac01b325c008fc91d17950b0a63da9caf78acb4a4a4c13130257eedd1ae2c34e690d9',310134000,NULL,NULL,'9d8dcfc1a9ed2f8e43ace3fe96bc3538559f596162378c5d025d9b93735f1622','25e51e7ea856ca8f776c1ede58c98ac8a93508aad2742bdd74f639a57e4df977','92c7679d0e92926bf81176a249b13a6c1cac9d16677725a7108098617970bb23');
INSERT INTO blocks VALUES(310135,'1dbf8ea76d2e70177df10b87e84e32e76fced9ffbbb38af8f732802206b9b02efc05992ba59c9bc1e811a5179bb865711c32870751098de5c99d274bf47e949f',310135000,NULL,NULL,'846885b16eba83b5f82aa233d46fb033ce13c524a524f6dd743b66f93d0c73a0','f24f86de07860fccce25ac6faa2dc3db9ea277ac48584842e389b8697102d864','0702d57f1388c6369e490babd261b6bd8aa4c9fc88f8ddc0c5254af041ac6a4e');
INSERT INTO blocks VALUES(310136,'96ea9a0098329dd191730a435fd65931bc05837f39cb646faa7a2e04dce0d1f0850fad36f3ed2d706dcaf00c5093cf7379e04d7d5670b0d6c50f1e2529acc361',310136000,NULL,NULL,'b1df9aa1ef5099c736405247891b98b591005e1d46aded8734ca0962ef26fbac','514c6d1c1a9d39eaaa65ccb5baf9761ee05c86cf255ecd5380b223370b98e4c0','20fde97a5c29e06fe59bbd8bcaabd3b6e4c1df76d78a160ff914b7a17875bc28');
INSERT INTO blocks VALUES(310137,'54f0ef3b50020802da23000635c8a238227d56227a80133a3fa1b345c8e08e28591d762359291a535c07dae86e9f35ad5d0176288368443200d598163290a93e',310137000,NULL,NULL,'16ad5f32a5c87fa7ffb5108368a51a50a264cf37b83a4ac20d6bc8fe9b9472f1','fc2be230cc5f8047f6251034e3f3060c068921179f167678a8e663c25a796070','79e8c688f264d00d04b404adad83f7234d21f0343da9630781ae081ceade174c');
INSERT INTO blocks VALUES(310138,'f464f647b3f7071ec8a09c53de3a37a001350341ee5d8740cb7596dc2c8d792dc85f7c03bf812a55fe37af26941c43f58d2bab04ae9a50c23c87d570978f355b',310138000,NULL,NULL,'e80ee8d6cd260263488006084164e02d6ecb72a92ba477d0f9696789ebbc09d1','981c44ac55ad48e3c77b922c2159eb4393c899cc1d068d16398a06154ebf76b3','4796e89b93e9d6be7a5a19770c578979e57d38e425df9d370ad6f22cb8d888e5');
INSERT INTO blocks VALUES(310139,'1d5937ceeeaa617ef90100a4401df06f217fec6eb52d11656d14ece57f5849aa88485ee1131ea0ea31843d74f87ec219bbea3f848c16e44d974c816f8345c499',310139000,NULL,NULL,'d223ae28bf755b178b3bbb48e55dfbc353d58544b445051a38ad9c902a2b0e93','9e5b760f6b40b8a11775e8438474d045b3466a1e8bbe6c846a2729156a5c23a7','2d963a0bed68cd493852a5a161e486209db451a906b25d6a0ca292073264db45');
INSERT INTO blocks VALUES(310140,'5bf90aa9395f3e9fd7af5843c775588acb46d9965c5257fe26090d065a52097c06d7600b583e692bbbe178424ef535c32cffba0736834cbc51c5baf6465e9d40',310140000,NULL,NULL,'7b3f67a5c3ce59beb1df6977e68cd952838a8c500f71beef71adbb7e4402358a','29fd1e4035477e6bbc1e852d25f6d133d01a9141e4158153305cf87d715e0871','fac62a4b11cf93723aba3a8361dde16b4abbb504ab92c54a50b53cf482a4aa44');
INSERT INTO blocks VALUES(310141,'303f84dcdeda12d009bd30efc4217571aa5ccf1367e49227d7c2819deb5ebcfc0d83c663f57af992b272950b055cb3ba7373249974fc38ed4e59d83777e9d8ac',310141000,NULL,NULL,'a5ee51815dabf7378f7e7fd314c320668efbbc852651a8f3da946b11f2b45eb4','a2091c98186d75756f20194ac104a93b55083c8b2aa670b384f7ccc70b44d0e3','0551fd669025ff6e576b21f150d6891667a65886f5c9a8bc5b03223e806c8e70');
INSERT INTO blocks VALUES(310142,'6eef8799c1dd3c4f156a6dfcf70855a2c10a6b3c16344430dd06b67e6051932878df8b2a16fcdcb60090e2c190fc7d6c8b1081fac1878aa98f1db892827053e0',310142000,NULL,NULL,'09306fded3fe8f9d0d4b1d6cb75cbc27ecb3837d86f360a501fdc879ff0cd9c7','59d764bfbeaf78fef39b3427fdd48f7938e61846af5d4b4dc7e65b2211d20861','508e1238012ba5775a8db576ad687a6eb7bc855867bfd612088a37c5dbcc8fdc');
INSERT INTO blocks VALUES(310143,'3eaba6739208d14d04cfabaf5361374f0bac8d5deb773a4aa50011469774738874043a1da8942ec4f48e1b3536092fe1327fa9402ec36a217711e1bb7b50d689',310143000,NULL,NULL,'4a8c9a864e7a2fb16d019b3146e111f20b679eb3f46b3edd29e9103e05b23f77','ee94349b51ff4b95a864693f6479e786603b07d008c37a81f72a269cc0fb3d51','35cafebe01cbec5475d0d4714f6ac5587235a14e8a4e06abc7f6541716dded49');
INSERT INTO blocks VALUES(310144,'f8fe4cedec10f1cfa4424aa5cb722754f2b6f21adbfea88043599c29ab8eef0f1f52da1fa4b407351b1e95409f1c50111779ce2a01f150e85090d446f630dd51',310144000,NULL,NULL,'37d8d4beb1980194e3c205482d2af20ae43b314461e049134784cf1328d99186','7bda64007c96773d2b004af6db0fc6dc1c9bfed71ebcfda6e17a2f08fb0e575a','a8f6443ae74d5fc854703391d4585e7df832b6eaceb58b902a2e9d1e2b6505dd');
INSERT INTO blocks VALUES(310145,'60f5c7eb2cdecd1e75424bddafaeca4c15ae395e768077553912205fb74a377152bca81c3d292f8e2c8e5abff910a191732a25c718fef277de5f7fd0a59e6744',310145000,NULL,NULL,'7c43bc2fb057e4fd87110206da7a9be11a9b288a6298be38cb30ec9fee55759f','69f66a2491a64c349d9de01fda419c8dd58d3283cf16a687767581e76b4eb35f','8c8b1691f06f880b4060266da577f7e51b7bca811e8f02df7d3218964dfd59d1');
INSERT INTO blocks VALUES(310146,'708e9415393bdc3fca510385f3ea35724dff9d7012b29098dcdbc214b9dcf4fc0b6bb7a14672ebc11277db95c551b100f8f162c7ac9050154732df38fba5240d',310146000,NULL,NULL,'6fd152f102f3d601e43a5c6b6bb461bd3f8998ae8c69a1014e144fc58f0e97d0','1d6f92fd7366cdb26a2beb4e2becf98828210a234add190efca04ba01216ae80','48286059daa4c9c89580ccb44adc71591fc6333f2ae8126e663040f5aa357fc5');
INSERT INTO blocks VALUES(310147,'322084a62e15e0aadb94fc07c01e5252a974294af9f523ed94c5d9afbfd8770d5b800c7ca0a6aa5b277da934bd1a3386bbded20fe1a085c0ae91d67e8e9b64bb',310147000,NULL,NULL,'2b811f7b1d3c6e83d22d311ebdcfd0051a10da5147e31bc52092c39d53deade4','eef34ef5089e933af11ca4aca4e8a147f600d36c13ff2362392c32289153d81c','54246d92d20720a3281db8a75c5c26b80a31cbf7e4254e6c3228a5fdde74da46');
INSERT INTO blocks VALUES(310148,'a03009d380ee9920791b73e265b1652a69eafe3b08602add482a98e92ebb131c0f4937f60f18d1c493d3c45414d233bc6fb4e5e458cb336618152009138e31a2',310148000,NULL,NULL,'76af113db9912aade7fdf3d8c3d8d0d4ca4258d7b62432d65cf42d65380dfd40','5738aa1b1243563b18a46b8fb7de610f03701adcec9aedbfc457704fb3a5d4da','163c15b99562cb9c6af1e9c485b5bca81c60c7e6ad9331af6536bc4deaf4cc17');
INSERT INTO blocks VALUES(310149,'0ba00c363d56bdc60ed508e68b824b6bb6eb0f86d78a045322c7c0abad9446a2201a0a59bd4ceeb40938327338ca7cc3522f3368afe0bd229c53d4e60f18a6a5',310149000,NULL,NULL,'293da1e0bb5c6d8eb3170f529abad1dcfc9d58891fe15920fc891db69bbd75c0','0302da9aa30b400b58ad90af814e17f4d54c7df57f52de91676ab8cba4ec9fc6','fb877f9f938bd70fb6029f724338eebc25270f12e9966fa047e8420225a7abd5');
INSERT INTO blocks VALUES(310150,'9e97e9550e3e69eac03e376dca3f8faed4b5df2f357d3aa76700c53a8ff5d8b3c965285530ed791673ff7e266408c810b2497665615f43fcc472d01835d9f042',310150000,NULL,NULL,'9177138ab12a2623d9d5ad5a422e54125294d6c8a04e97d593d7804eb671ee85','36feb453c9c0a0be04636c772d52e96a1ccc3ddec5d371a1c741879d3171f5fb','3a2b0b1a9b0806028f921dddc48517566c37a4993ce6f946a0209cf90c5c3df3');
INSERT INTO blocks VALUES(310151,'e9da3fce9845e6ee5ef6ca0648122f1e7267df82cf4f0a4476e65c4abd718ba753f3198b9bb1f38e70b57f6c7144a6f0eb0eb56fcbce8c2ed35fab312bb505a3',310151000,NULL,NULL,'0b5aeb4ca08a68e19eaea89f7c0e3197cda855289d2e8e6a9f77bdc4b1236ab7','4703336180b04e75138273a61400c4dac4a3eccf470a80ddaec0eff8702816f9','b943d7145fa5bd70991c84785d5241c70aae38cfec6837589d626a7e159fcbfc');
INSERT INTO blocks VALUES(310152,'87d5946810235203ee616481806c302b6d72c5674348930060210486b39197b607b847e39e6ccaefb5bc302852570dd87bdecc9541b4c7377e6895197baeea13',310152000,NULL,NULL,'86ca5a2198023beae56db05d16057d046d9cea1c0472b4a13901149a17f0b1c4','3bf39e3a5d0142c97745fcbe33672fb6e417dc84437b000f8289d05a754390e4','05c30abfc7d61c15798eaa0bc0859ad0375456643b0825e9c56c101258366b38');
INSERT INTO blocks VALUES(310153,'bd1637edbe45b12514c3594f115b698a8976d61d258684a456d86705ca73b667b6bc4a5cc9a371ef339d673c6fa794d6fdae5fba232019dcdf0c140baf4a9bf3',310153000,NULL,NULL,'b543d4a729392e7e998402aaf1661e5245969b2e8dd738782be18cd2dbbb4518','c75dfb11e73d70be092a88b17abe16c24e2422f49ca9abb403935588f0a436a1','8591194ede0d1bb566e5e5b74b7a0d1c90cb9eb05bd8466439a99eb2581b8cfd');
INSERT INTO blocks VALUES(310154,'3686d7e3810f1c46e94c53edad82e1fe6ed5eaed7b9f7da557e32afe8f81c7056910a279a054eeabf2b94dfb571b829eed22fbcacc011e75f601e2027aff698f',310154000,NULL,NULL,'d6ea0a6a523abe73969ea51552934b494ac8e3464d1a0bb25b6c1ffeb93353ff','394ec64e6122321eeca7b71d24808b9a05faf88110451cf6bb7ddf30f62e55b4','e1d2889d12a5c20c00e68c90574f29dbb0ce470bff5ccdf8704a704aa4c79812');
INSERT INTO blocks VALUES(310155,'59ca58cb030c16691117086d2c4e4f2424516e6d870b7d0f105934be4ddb150b19fd0fe4a721d6097ea1fe0859c9f497cfe1ea4db2ec5956604e0b7f8b4a7468',310155000,NULL,NULL,'20b8b9bb0539f33cf4dcc9941576e4ef9a3b1f01f6cf4b390b36e39c3cb13cc3','67e39089d50aa14d6eb7b53c0df27169b02df37045ef0ea180fb535a18e1ecb3','fc80ed2adb37348bc643d9c1cca9e7e3ae47eef9bd4be3ccfe7f3f957f411e87');
INSERT INTO blocks VALUES(310156,'4e5da453a9a40861e30fc696c06d9aa3860f4c6d45111335c7d1aa392987474dee457afee82b4a2e365f288e0731fc1428eecfae945d2ac68a357dae20768d34',310156000,NULL,NULL,'435b2a7ac21fc626549ec2cf4ad62575d97d923d138ab3183d0c7df757414e75','5c7e254de20fe66b22e4f552531089b7909ff9a09b4cc07af973294be0eadfa0','67552a3764d064382dfce266106d32d74d1790b22d0d1cac933f90416d98c050');
INSERT INTO blocks VALUES(310157,'758237bef754b704930978e24052d286e2af5d029fb19f84be5a5277b7ed4f9b6d281021567807955237e3629a0e44d7524eb5a998c598191f8ab61d4b5bce9c',310157000,NULL,NULL,'acf69f18f9fc30aee7bfe1b5882cb6a67a3854d248557838955d9238a5b8728f','975d0e155b136e3a2ec22009167f70656f7749b4e527427e48081e65eb3985ae','d8c0478e893302abe1f65c6a12809fcda46f56a75a1cc28942ddbb2fc45a8c67');
INSERT INTO blocks VALUES(310158,'8fd95962fc5e96c28e590cc4abb6070abd4e041d9dbd1670626de27de3fe6a85cc38919065f6f99bbd46335bea510029f68b8a0ac6ed5377beb469b7e5788c72',310158000,NULL,NULL,'ce48e1cf32960df827aaf74ca6efe06c1a8c3688e6f7642b4d7790ce34b3c202','ebade773a4e132302123e1f65fef8181d0584f3bb536a513b79424e5d1113eba','3451d8d18fbd1a504d46023dc699a965889b5ed2bb274a1fab368df5a84312dc');
INSERT INTO blocks VALUES(310159,'2f2a14b6bcba2e16e8ef9eedc73c48d5f0b1cbf5754aefe2da5e0c973b884a79054a127eaf78da9e4588b4e7437ba37ffc41ccac22752f00e9d36fbae929ab70',310159000,NULL,NULL,'dd4a228afb678097e20f6cfdf7301ef60ca5a6a13dba8de959803bd5c8daa96b','33e9d6eef3e54ccab42019abf7ec3fb2a10653938a03710e443af31a78ac8b60','782d99ce7cf09c3b61672ef955052e6e96edd62c7d10eb3d322aed2dd9da52a5');
INSERT INTO blocks VALUES(310160,'4425734ddb4e0c8c9d8a90a46888a460dae3fa6583cba2f1347c40c349afb8fe47029517fb885ade0257342e04cedacd75f38dcb93aa19e3f0b33253b1a98543',310160000,NULL,NULL,'9aa9dd1753d04d592de0636e64316f6c14b677539882c2d01d8cf8c55a58a206','b8fb9e2c28e603320b671d5e82721ba897ae1b7be4e3467af4ff496f92d2ab43','111723497ff4ab46dca204f71c8b90e5dfdb6a4d42e0269b4d4a2f784b13b9de');
INSERT INTO blocks VALUES(310161,'cc122bcb43f2fcafe55d479da7ab9df488491c6568c97478f93df352d46559675da2d7f627d17d9401d84ba83fd10a8a3f14129aeb1f4a1d2958f1b5a7859a4f',310161000,NULL,NULL,'134b0a90c99cbd52610b69ca0e64aa1e8e8327ec0180114fb037ba3508f93198','b229be60ab0e7fd4ece638c5d25013ad5525c95c1e428b6f1a12cda5df74bc9b','679311c44519fc3d65d312960e92ccacd15a6aee686fc86d62a6bcb413eaf122');
INSERT INTO blocks VALUES(310162,'0fceec7b98ba84ed354d29cf23599eeb4036fbeab3cd9bbd840b5967acde98a1d7f0c36399d289713f46ca01e3ba06b5972fa120ed41ea427e24658d134ab69f',310162000,NULL,NULL,'b37828390afa54f0045f55d3ee64f96f6357c844ce411da36dce44f454661d4d','43127895fa3947e2917122e37fbc377dfb1d39e4972f6300dcc37db5cc901c8c','8bb135631e3277d90d1e32395ead132c96d7721a8882b48586d4ac36d4701442');
INSERT INTO blocks VALUES(310163,'7f7ef65a3fa9aba6073617be75c6a9f1373f12c43cb0c73902c6f3a4fe9754ad9d85afaa2bf6aade7db1b485dcb615b6e6ad0d45ba57cf1efce4efaf185b2b82',310163000,NULL,NULL,'9a9d877bbc473ce845a3188265b1795c415d0efe7e25e3be628a1cc8f0b5a4e8','33fb45da33a1173ac7b233f84cefaf2cb7cbf024bd472629d63bfbda94b893f7','3fa91c12a808b66a5fc58569db55a8fbc7e3a12110a8316ce8fbc1006bb87940');
INSERT INTO blocks VALUES(310164,'e20bc6e0d1d487b51b568a76a700ad4859e049359ba7ba0fab39fd4a9a5410b2f15e810078d6fa29e1b0a5ed78ac02d01c7d6bead371b15bf4f05b63646a4a80',310164000,NULL,NULL,'4c5ad18492853f7a17975c13c43dfa0a9ab9d45ab8e06053ae3b60f515810268','d93c373454f5e2f7eedc9a3b53a0af06d0e7c7090236249a29e8d1856ce7bf02','c00900e45d7c5725e3d63ccbf2694a0e8fcb82b6f871f5be3565b48c6df34554');
INSERT INTO blocks VALUES(310165,'23aa93aa7a33542c0bbc31111aaf1e00dd180d41130030d1b288579285cc2dd5b27458a82d5da4c1dc9a4a5705fb7592c9d790977dd15c8b884e2bd09d9255e0',310165000,NULL,NULL,'fd421ae7fac129082be9188c327c47e1346eb3ae10d1dc90025b802684048e27','827e118040d3a47f158fd45d1e4f5aad995df4a53482f710351831a57fb04337','c34807806861d037d13add98119bcd45c6381797880262fadf830e0cf5961ce2');
INSERT INTO blocks VALUES(310166,'b58b320bb57889504edd100b9ca9cbef6f4723f0c4ac8aab2641f9fcdf7a6f1638ec7f1c96b0b83f2f0b5873a229f7e41ccaac6c3e61055ca5022c0f0308f239',310166000,NULL,NULL,'3c1abc1069309a607c36d94ec6a8b1a9c59793c10bfcb238663c2432dcf790f0','e99b9979887d6ea5cba3b4f385f6c2bb4922c467b0e061326af7168ca39319aa','4c343c51672b9eda60a94c56db12bda8d1db9393fc8abffa04781af0b7609c4a');
INSERT INTO blocks VALUES(310167,'9736af165bd0226d12623876d64ba05717572dd0a895fd2d2dff80653fdbe7c54b7c6fccbd40f771170786e3567b4646b3ce4e89e3432ec00762ec0d939c82e3',310167000,NULL,NULL,'aeacfbf1bcbed38b8ccb0c931a071d266a7fe046f21bc6b678c4b40095579f78','efa64595bb88d22814a3183637bc781dbd767cfb9212a2246d5eb62f7af6ca64','bbcf00d76c928e9ffb01e65e76b7dbe4accf9d3bdbd24cab70446e041311b93a');
INSERT INTO blocks VALUES(310168,'d76456c23e4128704d18f4889bf93c185ede9e8794df8d0d97c37cd31e4b60dcf67e9af24bda5fb90dc7c435ecf4d8f546f8b4e4821dd9484e1c0a133e9b301c',310168000,NULL,NULL,'2b2ced77684a82e17f4514193b6b8f718185e0dc7cccc3accb441f45727770a0','f4d7fc472b17cd4b2b95a9d3c22376cda10cd5351b2fb02a8d65925ade5232b6','70491d2c459f0aea08ec207577aebb2bd5d26da85a241dae77c1e242fecd28f5');
INSERT INTO blocks VALUES(310169,'2935a3409924b7776310bf9ea8f4a1afd7d9e4a372f01853711897fbb13a9681309ec0b9e957c9b812db31f0c85fbb82d833fc019fe14aa3e9bbe4883d37d4a5',310169000,NULL,NULL,'acd36c33c82b6b1dd9e7f5a0e131c1a86d49f0afb9c3da617ce1f560a97245d1','34fed66b4e4172afdea8ac5038b79d5feec5a49fc06dddd40f75a42cbe25e3f6','4a7fecb2e2f08bf3d65f4a54cb410167ceb7f1fd96b84e25578187c303ed6e35');
INSERT INTO blocks VALUES(310170,'6bbfba4a0f9dc4b64562d47756dd77cb1c0594b5b174a30c7878ddd04f86647ac3d5818de71c4872a5d49495ebb48ed322f10f6af147d8193b803b9a3c8e2fec',310170000,NULL,NULL,'da12688a674d94ef9068f73fdb84d5dd7bdfa7b5ded75ee1304b7503f546da57','8b4aa60b99da89db7c53374000ab1a7f2260827fc509ec83d8f732a5f286cf13','f38da1fbadc70089b000b4e1227a5228708102b64a6475cb54746c38cfec2c42');
INSERT INTO blocks VALUES(310171,'45fa574fa3aa1e16abf5453bd88b82630b4b5f4429d56d74c8f93d292dc2f0c9ff20a05f820ddc4e3f985e31af5dbea95d5f829a6d4386e98323923d8c72d30d',310171000,NULL,NULL,'699c1860dac31e2f6659fa1c7ade8c5cdcafcc35c02207d66ab6fce41b171316','efadab5d4fc89a85d78a4f9024f7531f7e5b00d837f86169408e5b745a1068a2','283a60bded2e53ae89c6baccf0f6b6be3a9fb2bff28b3c3f15931bd1a3b363c4');
INSERT INTO blocks VALUES(310172,'a6831f67f7dc90ec04e6fd9c89f50b90d4c9648a6f33e2b1af610ca7cc1ad53899915f340301add4be3c1f7e732b8dc4018ef64110fb78dee317e44830cc6db9',310172000,NULL,NULL,'a99f6967df817ed30316189995158560591558d896990b450b502089d6b21be1','508f1b365240d17ec984d410ba6a99bae63914ab7c4c221ec6ff83e32cb7008b','dbd570bd7c0c711bb77412250867b72695d2937404af85003fe6279a89e0f932');
INSERT INTO blocks VALUES(310173,'ed8b2adfe3f5416001083066381ef1360b0365feaa824d2f59138c361c452ef71c9b9af88f333585b1b8ccd1324260025e1df26cafd5bfe9f89c257ce80b8ddf',310173000,NULL,NULL,'3b6fb2f41dbdc369174bd995a2ee9fc445e834ec3702ac157c709baab9552b0e','a56cdcf6e42f9d1ba61d2cc180d52b74190f6e8d06ad1c7bd3e8f99810955a5c','3f80cfd2e819f73809fdb3117682c5cfa229d3ec1bb8c0f871ddb06cdd6bf16c');
INSERT INTO blocks VALUES(310174,'74155b1ccb11f56e2ca34161456ac38512fdc720445ebcf3458cc77abbd13c63e32517e2f13be3d6896d9c33c747941cc587f41bdc07d2b0d76117e390d001d9',310174000,NULL,NULL,'6fcf2e453997a8d40625b08f831b40db474d62aacf1e48a80e09d12bf3390c8d','1225e8c361af3a0810135bfc95179ea5f57c3b19c31db2801cd34fc5666ee304','ecd810d0391ea1d2f7af9bec58211c1096ca3996d84b385da0aef9fd3552c6a8');
INSERT INTO blocks VALUES(310175,'8e8da7a1e5dcb00385f5297e3c0b624a42d44caefaa48b3a643794e280589ab0ac46ea723912ee8aaadf061441a4c467b2ff82ca6ddeb623fe49e0acb60bc9fd',310175000,NULL,NULL,'1c3b1ae4508285d42a96afdf86c1bbf95580e5d21a2f3c4565bb2b3a2557e989','79f7f94c0bcbeb80ee29aa322cd4438e5fbed1af6dd7bc13e0cb9dbda0737e82','d62ebbce0c7790ba39885c1aae3f75b5520c776e47f436d4debac50b49604888');
INSERT INTO blocks VALUES(310176,'d1cd1ca90ba240b81ef4db29767adc7b58e62c5c06c5dea7a34fa6756c46f1a95e93b405137bf4f058c1281c3ef236a3fa9ae9446b74a25a1a23e16f6b2cbcf5',310176000,NULL,NULL,'e549069b2ab545f329d1851b979d0734732bc85e1fd455e6a33c72c936c15461','6fdeacde2ae57a71c74aaa60d0ed478e2c1fd782dd2495b868ce2cd5615e121f','c4c2001eb5fb38436cef81bb098ba1faf720df33143c067170ec1043cf3845a2');
INSERT INTO blocks VALUES(310177,'9bc86b3392ce570794748043c352bb9c2d60e1b6f29c464c4f1bebab322fe2cb5f686edb5e19951b1ba1ff9a81a15de45bf8a8a898a7557f7d45802daef0ff14',310177000,NULL,NULL,'21e1a4f9ca768c5891f5fd35033840a599f33c5a453507b0c19b813ebb87e860','43db2f6ce936d93de9dc1ef0ff4830c9f28551f2ff3f1cb4c7c817033f8b8ccd','66c2061593083c365ada662fd54e51d25e7d857636c5d01bc6901f251aa548d5');
INSERT INTO blocks VALUES(310178,'3d807be2f0841df7dadc78f0d9cafbacf474a7566c97923b854b2d55e877d3794653595ea2694cfffd99f2a7625d595fba7b6ed9b364b2a5c65e2759f6bbea19',310178000,NULL,NULL,'afc224fa2f213ce661118b599cbaf7f0fa049d140ecf5c41a9edb484d1eb7879','c62cacc520bd3890e72e31399f2bc613140e7d7ed6bac56980e61b17d7fb3633','2d7997d808d762eb8adce864a9322821451c4f1c695942c2850f3935fcf08ab2');
INSERT INTO blocks VALUES(310179,'de1875d9f78a6a73d5952eebddfb453ef5c3cc84424f94c3e159cc6978f5e616f4e34f172f5721848689dd7dae71610cc4b116163689a03638899e015ee573ef',310179000,NULL,NULL,'24ecfc8c70ed08c8ad2ca95171596adb07c27ba99181c8e2ee38923139857633','e4cc86c5ea3bffc73e72333f15eec6e6dad149a4d417a20a817f854b6169879f','bd195258f529159b4c3db96618b9e9ab5b7d64cc48cc3247b9b28445f152e423');
INSERT INTO blocks VALUES(310180,'8d0c1e2d34d331834a636d883d3fed640c169ded8b81a25bedaec7dd57247f0ce5ea81016d704c7350d38736193ec92f21ad70f6bdc24ffcfabd9a5da9392ec1',310180000,NULL,NULL,'8907f853e2ec89be38d24f8b868dd73685de4d7393d8e6ec50aee4f5974fb860','be3dd8cf51a6fbd2a5c2171207dac321c4ec1df6f20051b2d1623e4655af17bb','a9ee6e721a1c582f4c3baa32bbe4adeee335aaec6c3babd4fef72b480e6a2a8f');
INSERT INTO blocks VALUES(310181,'5772e61ad3e5a11ced755cc9b7f7f9221800766eab5aa3c8611c213b88d6dcb5ab678a09d5c1ac3a247e5bd5e6645ce7c83a961485d65241c54f12e69160ecf5',310181000,NULL,NULL,'d46aa963e08100b67c89460ccc69bcc14be9765f492d417cc7008f0aae241638','2a4c8f9943cfa77c0fd535046b569f43527f94423691ca5a48f5484fb2547f10','400544f6fcbd9c8f6976ac59c89cc206858cb5da65ee792728d75a8fbdf6eb0c');
INSERT INTO blocks VALUES(310182,'cf5773ed1716c6e92f4c53464cb77ee2c77484f34599905d74f9fccbd4069f5cd7038a6fb2b8d3cb1eac5812e09d69ff0c5fb96fc2c788b3d855d334e9545523',310182000,NULL,NULL,'00ddb3e51f710f20dd6faf55b92f903c7e0c14ab569dd66e04f427c5717de2ea','20adfa018513c2dc9a43ef2432180e99c15321bc7a0363dc0f29211d6df81d6d','83b349c43ee391e2e0bddbcdad72134572c164e579a664ae00dd653eb7647e3a');
INSERT INTO blocks VALUES(310183,'37b17271fcd06d1dc0d93746d05e8db21fd43a056680aadc0a2c5503d8abb328f749c0ce126e8733eb1c1dd1be1c33afc8da39e3249560b0ead9ff05736c4dc6',310183000,NULL,NULL,'995e79598bec480ef6c802c424daf25ffe7f9fcf8589e51514ea899fef83b5a3','af62246b88bedb5005203b279bf8e60be86472226e0fbef6a3a02dc7496c2a2a','96556be13a34aa6de8dddefda71275db22e57f9e6fc3db632adfc7d5fc1445a5');
INSERT INTO blocks VALUES(310184,'561300bad5e3a41a6b280f608000b1895e85f229eb80f8d945f56198af5f89ce4c675fb82048e90881610ef9ba76de64ef4cabb599dd8013a2b9fe805573670c',310184000,NULL,NULL,'5ad000f4d715e43d5eefea6bdcb49ab24da02c0f12547430f974b833a6f4b4c2','0b062c5eed8f4e9d89000673b9aafac2adbef11d6059699c1ee3cc9e5c250f62','af4d7157753ef9f78add9a0c96a7edac63ebab98dccf6588197379a45aae133d');
INSERT INTO blocks VALUES(310185,'b5c464b7c4fe640907ddbba48d37e07fcd09d7e0d3c51649886c8fe5592378745c0f7584a188fa042be11731e3acf542058a5ffc9527dd2f278e025383779035',310185000,NULL,NULL,'ddf542c98b23a9ec52a5f1713933dcf24040738cc51a418e6c8a43103c35dffc','2d2ad54c9adc382514eab07217e11be43cd48302c68a133daf605f751a846564','f398562102351c8ad61f33b9ccfe5fe596e04f2cf6a9478579d0362db0e0b9bc');
INSERT INTO blocks VALUES(310186,'22ebef88212b43581eb11c01293fe45dd576db2eafd53c6cfc0cb85271745415bd04b38f528428b736d2ef9b9d1714e3fb495fcc4334a1699d481c3b1d380ab2',310186000,NULL,NULL,'81b977eb224932497e8bcea9dbab41935e4238e7deaf45d1d5d0265e34ccbffc','07894aab7aa98a32cb8f2a94300aac3402c3d1dd910127b87d4086e20bf30b35','a483aa9d6c118eab1538cfa9b83ef560ad5bea4e4ca1fd0f9eef5b0f478d6bc2');
INSERT INTO blocks VALUES(310187,'94a43b55b4565483540f7802db450c22fc0ba45951629d69d47eced2d49661881ee5fc1a5b756bf9d8e38fd0029fa6c830827793cd9b41bf05da2a8105b54a13',310187000,NULL,NULL,'d046b7811a3575e57c6854f52995e21de061a94693308956ee010dc4ffc49ef0','3c0c5e330b352e6be122c89602ecc8d6bf00be8dffe1eb8e072b457c3eff9b0f','4e1407488c1be709eb0027f77fe71b4ec853e8524e6e7ff7058f1f227cfd6e73');
INSERT INTO blocks VALUES(310188,'1f09285262e790ece05ee3e305d5e5a8e6ed5c7a5b37a31769d0fa554184601b67d853fdca17d08f54ef2708695eace84225d184162ca1d9375ecfb9fc01433b',310188000,NULL,NULL,'1dd71724a3eb4bc335cc01d1f39a51b691220e13a612756cd6275a75da3c70b9','eb8b4e55ca2f97b0470c2541cad5e864d4192b3f88805c8d49df7f8720d9f410','d4c2cd015895c55903ffee37c5fa707f66ca869e36f561ebdc173b3118526940');
INSERT INTO blocks VALUES(310189,'bb30ef3877932419706f2479fb7ffe9ef0e01f5159ac70cc783bb06755c1d81dafb8fa0ca98bbdd89fee9747146e91df626f0102a0882dba413e4356da7c4999',310189000,NULL,NULL,'98333fe204dd15dd20f191c83ffe44c277bb507e37a7c0dfbbcf9e7d9ab860aa','92f7728e15b85c3ea52d57faaa74d6a3766f205cc356acae6d7f0e1548a79ee3','a5b47f474dd14553717371b3b330bcbe1c9b26537b1b4c51a4d83fde07ad9b15');
INSERT INTO blocks VALUES(310190,'31407bb2cee22fe9724e3eb9a56d6c8f0162384875df882f1d72e3d008882893ad1d596f45b7cc76949b72fed973f1a5652bbd2910f95d729699929fa05bc637',310190000,NULL,NULL,'6e626e1434df5247403d3c4f07da47fac127bf422b1854b996ae35434d23062e','3e2bb0045aff2ea574ddaa55deb650dab052e81058ac628d8f794585d827e6c0','7c97b7a59ec4bc5d34248173a33e75ce6a90d8a4f5d49f44eefa8c9029c87909');
INSERT INTO blocks VALUES(310191,'2dcb942dadda125ae31f3cf53a162393136b761f95879d359956b38bd9126b93885d43a4099b4039000ed8aa633c2398463b3a40cfddd0c51600a10a3e100a41',310191000,NULL,NULL,'033cfc09074cb2cc9ca299c5aaea45ef156e084fd71b34b2725e6de3dfa24ca7','831f9a7922a76cfc1015fda8499d59f2a0fd135b8f6f5c0c72e5874925551a1c','9ffd1610925305db9c46ac51c44934fc441b326aaa1a797ad3670c01919571b7');
INSERT INTO blocks VALUES(310192,'7c16e6fe516ac5ad6f1c65dd08411e0bd33d20b892d65e95e118c4b8241e8e478735a55a29f20fc7ee8ee1c27ba709243bdda8dfc00d1021f7e4a0a0cca3d3d3',310192000,NULL,NULL,'4b8c3cad476dd7cbc2b06d6eed5322735a0ff6ef7aa8bb181e1a2316ebed02ff','a1670d6239b085ae7292b00ffcb8da4cf85bba216a73dc229d7609e216d16610','b88d6838821306138975ece78c63bd23a542a88632360b434f60afde81a447bf');
INSERT INTO blocks VALUES(310193,'b129b90017dfa34a36d8251cb731ba1fbc1067ed7e7d1da6aa6090637a4192ce5132b3eaf929b6df4b080e1db431f14af30ad86aa659e227f78c49dbc2c0183e',310193000,NULL,NULL,'f2f28a997583861b81671f67ed6f7ff58e4370720fa971004ea53bc0eb801563','f46256d0f8faad408b345b597b2da698c49c2de1288f5bffc36a5fd5767817dc','ea2a04438a95204a08057faa1c021c587b85869731d17b77fcefe11aef6d99b3');
INSERT INTO blocks VALUES(310194,'fe365596112e833d1febe8dfb7e043186c77b7d46ede329406b728c70bcbdcd69307667b52ada5786ddeab4ac4abdf2124f8b44a7f89b2bbc47d48f437d2ec9e',310194000,NULL,NULL,'5288907148c38f523b5a35256df9af02d6c4839a0553db4d8dc4e5761e39222e','06daa6c22ddb839a3080c64d005d9f707e530da4d184d26b0b9cdc0397f8834b','e7511ad2317196d3ff7471b6c2066d916d16d41e2253a60b74c70f8904c87185');
INSERT INTO blocks VALUES(310195,'ce0238d5868d08018c8c7e2a60ed09e62bf43d68e3c93270ec0764a8d545795b2fddd0f65d1ae65148f40a0719e70870b2260e44e6d6b34651d9462f6cc22a9c',310195000,NULL,NULL,'d7f8c3999c777af3e1dedf5e9ddeaf729ae32ea275aee60714ce06409ccdba86','276f5f7df89fdeb4358ec8258c83e9f71e9476fb36686be8fced0ddd91d2b830','2ac73804d8950fcfb17bf81d28a37d1632edebb11e3bbd7845bc4dc7dc0de787');
INSERT INTO blocks VALUES(310196,'2cac341fa2f3168c883fbb847491f27137e1dd57c6954ab1ca8987439b8a380ddeed89f0ec48c72b50388b32fb9949cdd7f91b5cf1699a079411b5853dcdc21e',310196000,NULL,NULL,'5448a096d62aa83c272832b35f2b8c0d68a625facc69080b5c06501a1236efcc','5874b6736216bfab2ff62fee4faac6c444b79a3e17be6f032fdb8e2f6f78b56c','7813e2e3e39f9e06171460cc0f2ba9847b038c036950b5161b1c32e1490c6733');
INSERT INTO blocks VALUES(310197,'76baa8066e0367c896c42ca413351ede2d01956cf2928e8db2b49532e883cf33f001aa407ba509d207ce1e10b04a89238ccfa34a96aabf8ef5769e7124d9d5e1',310197000,NULL,NULL,'06f1e7f0cdb849749ebf7e9de0ea70659d9a11dcb92066a15fc8424beb859ed6','b2a18d9ada43629af407303216a22885f9443881724a98e7cf52a020b5c2fd03','481095f9a0a6177337262cc7fe3e8b5c020a2d338e57c9e91431fc1468b9b5f7');
INSERT INTO blocks VALUES(310198,'5954538999fc757ad73102fc86f4abfd466561da28e2954d9d0d740b2d0120280541676fdb318d5b9523df9817ecac15825159d08094df9e067f34febba96025',310198000,NULL,NULL,'aa4787f25ca1d5445a3931875ae2b94f1954ad0a80b51df0f3e6aa61efe4ed27','27141be84fbfec587cc9b8cfec2066854112864b40f6238742ed0d4e3bc6cc75','751ed79593cd9ad9dd987832c14e4796e64f6a96ac78fd2a64f42db3c07df6b6');
INSERT INTO blocks VALUES(310199,'8bb67d60026078805a12980af74fd68b56a904ad1bc2b808341140be6d4159f2d9e682ff7a07265512b5f93db0596a54711c968f371389c8905a195badd4729a',310199000,NULL,NULL,'0411db38f4af135aa93025a7f658c8a6697fed4cbef2b1e876cb99b3c5fef9b7','6a78f4f1e54cd5a4b8d3fe1c385fc39cc6629cafffd4d3e23ae0259c5b00e88a','6dde8dccae3b902f7023f4568010c2ff730eb0a4d37a0db72bb30db56c26a06c');
INSERT INTO blocks VALUES(310200,'b4d68ee6ff2024e7ffe45cafb9273412e2a3f94ea97edd856830540e1b14e87dfe6888ca25328ffb7cce4652099f86519cd872f1c11c7ae937c4594b24b65643',310200000,NULL,NULL,'b8ca174552a90f180250fa5bf7a93bc31c2f4e7034370595e3ccfebece62fa4e','0e84b0412adbfc2da5de93af7e73c928ab9af163dde3ef43330dfbb9e2235b0f','9f0b15253ae7623860e01e4659074c18e23970b8072cca4a2b498cae11afe713');
INSERT INTO blocks VALUES(310201,'22d1f267fdbac9449388f06214fa56a8f066f503a54b3debc0c05337acfce63eff64d70fb57485f2d4f0de22151eb723512ba94b527dccca3163be3660289388',310201000,NULL,NULL,'d9249bc1ad0d9f0c7980549f49e772e8194e3d3229a73a2f31d904cf21f5fcf4','3c248168f82b915a79e463f9df301246e2ff817095f8acb12a194f8758e64914','a28db0d066add3a1755edb14a7476769501a9a87aa24fcd3fa53e4cc501310d6');
INSERT INTO blocks VALUES(310202,'47c65196973497b90b18e79b5d56de56cf05955204b5d1c793b10749c2200c3a32251201fde07de08f41c5ddc50d94807a41fd21d8c843b06f3ef4fb7f8a0694',310202000,NULL,NULL,'6e5c4761430cdea2c16f04dff0a1c2d17d6fa51a969a56922568902fd9718936','1e384a6479af54261cb3e251982ba989bd11526ed373a32566bddeb67d563f91','1ccb04787e4b86b4c7329b57fc0da9492cd7583008386a2cf1a53b15eda633a2');
INSERT INTO blocks VALUES(310203,'4e4a1b5ece42b2d9f736ca168fab5e748bd25bf04a6befe529195596435df3bf5c79f3d007a342e396216ceefccee86fcd8f2c6fc6220ffe05faeb5bb799533c',310203000,NULL,NULL,'fb23977bcfc5ae44fd7e9c3bbc196e2359993ff6edbd8844fcd04719285ee373','86b50b1fe570005595a1a72c8104be6da811767c43bcd587822759fbb242493c','ff5bfbb682bcbbe5386cfe5b24942ddba5c06c611aa04ad6872acf0a8ad3b050');
INSERT INTO blocks VALUES(310204,'a24b71e73847bb71fa295126b7a5469a4edd3666e1b8ae7aa116b176e0aa6d3e0f1cd802a4223e21484c76e258d310964f772609f02b368ff86eab0dc75ef249',310204000,NULL,NULL,'df8a56d16661eb472365bcb1e0ee1d9f42868dcc5032c6c325821d6b418d4f5d','a82b363bb0998f11242af32afb8bc0f9c141100cce770d02253c2c2216854143','d0469e3990f1d9bd0636ddf45dd2544d1be486b92f2759a413128e3f676c6204');
INSERT INTO blocks VALUES(310205,'a72464e94281917ed2ab5a9d6b4a2c2aecf7f75c6ff2f0b99965920ffb131d8cc0950f7c555dca580cda03c39d5ef2db92159bf755c7589ddc639395774d92ea',310205000,NULL,NULL,'7e080d0c1b18ab9eef06f3bb9968a84b21f564fce3593e181136c2bd65152ef2','4e7bc3ecc32bff9ce9327db77435140392e593da614499720c96972c838fbf2e','7adb848964a9247591d4306fd082e82a9b9b6e9bb21a4621e16eb580d33c847e');
INSERT INTO blocks VALUES(310206,'01cede99fdc8e82a0e368b2da8b68fb55ac1eb73e38a2bd2a6e307bf60f2bd48689a9b1beb995ba2807bcbc40d68cf99233d7c02da0e63e12dbe2920bcee5a32',310206000,NULL,NULL,'7e7279c004bd3225c2d3ab117f69e86b8b726b0831c537bd5171377fd871b54e','90c9a444c582bb83af98dd1d42b4eb04e0a1ebccd2f78da2adf7d46b2832f41c','54e154307c1b10cce0367a61613aafb9d979c6e509fa2409ecb97625f58e8b22');
INSERT INTO blocks VALUES(310207,'88d4ff20997e03629ccaced0196caa97ab4b77184c74017ceaeb6fb389042b988dc9a699b4fa2f34834eb7f944f712ddee8f9a8b2d1d2c06f0d8c168c68807bb',310207000,NULL,NULL,'d147259997fc13f032ad8e1a27eccb5a1ce564b1101aac26ea0983c60b4cb830','119639ca0057185c43c10d5fd9d94dd2b0bfd30bb6dec25d48feb56194b4fd1b','7d41c734e720275c10b627aac9b36ea60478076f62a223f9a126b3494f4dd3b2');
INSERT INTO blocks VALUES(310208,'d0df3a97325c0945024e56247937403a623b103da35b0ea2ccea010874723c8dbc9d84472bf71d8d0508875dffdc02037ee49b7aa66e827fe67e5f1d0986bcae',310208000,NULL,NULL,'fe27ff63a6f8bda4e0e1876c729ae6f4512b32783cf325ee922517318acf57b3','bf7988a63d8ac94f4ac63afec462dc20236b9755b63d7bf3bdc9c457ca2d956a','15be3deac7f6b48646d9b8b78e379558d3c4e17f167a134ee7b764bd731c5bad');
INSERT INTO blocks VALUES(310209,'27ab1588eb066b1dd2f7e3e7fb063a9c9aa1f619dc2de468655477924c0efb98ba887527b103a5f684c7a00ccf8e1f47a3dff2442b6dde641344c29118771dd1',310209000,NULL,NULL,'99fc696f0d219dec99aaf4d77b8678a23eeb3f8f03bf52fedbe7b82792ac1cb7','94034c2bb996661a760e218f37feb0a768487bac9fee120841089e74109d962f','2182ff9721f9b9756ece384594f52d39be7a4071ab6e07e5e812cea76e6bca4d');
INSERT INTO blocks VALUES(310210,'83f1b51b0533b378caccf1c10c24d28f73b337f2565adf1b98be45ad0a41791c54423366af21e62be4b7c162bf00f520272e1d8d9f1ef559796cf77f12cb972d',310210000,NULL,NULL,'6d09a7cb18a210d192162f065a7a34baa0ea34e348781753259f300666e47ccb','c7d6f03edb7257972121b0989af0dc11ffa3340ab7e48fc29304386ffc8326f0','415fa9effc7e18e54a904ff6519051528166a1d01cc9535f15a756b6d8c64cc4');
INSERT INTO blocks VALUES(310211,'3a9056c07772171c06ec205a69c4b9d696237a31df08da36b0ae6450c572b51cab86c482f5438adf5f6ed205f25b85b5cf917251992126a1f3bb45c5a46dae53',310211000,NULL,NULL,'d34fda69c1f1ed24035ee3d7fbe3248e75a7380de4efa64f50e29112e197ae3b','21d2be40f42cc0281ba67cab6d01712881486abdb723c2da41a86474c2cdaad7','09dd5cc77a0f2de43492051e6557ca00033a8ad7fffd0cc7427c08ea56745c94');
INSERT INTO blocks VALUES(310212,'33d04a1b268568ad87bc3b1eefcec805e49ad6422687372c8df9573167be5a59ff175390db4e4be3b70ebc3aa80b0d97ece4ff231544e8eb2b851c29c5453256',310212000,NULL,NULL,'07c7a2f835cafdb13e5c385a9abf37857f8ea590f4214a5c8b44983f26f32e32','87a243132ff39364fbc713876f3cf5929a397e2b3c59ab294e5d44c80a50f1af','ec8bb28a0b66d585976c586653f3a3eb890eed8903e1a0ccdfaabef6a51a3455');
INSERT INTO blocks VALUES(310213,'3c11510c4b3889cc5ec632b1a35bfbc6c926dbc2e1192fc35e6a1086bd1843833efa11e8a3e01e2b52b5a4f605d56c493c26096453b3b55ce624b998835cf3d2',310213000,NULL,NULL,'0be6909fe6522581cfdfdd35a9a37dc46e3b1255f7ec7fd552ac0b01002eb1a0','8af61a9dacc318ca5ea3165c5cfad2c73b7e8329031a5bbe546fc4aa425ba24f','cf56d14a0de8a91fa4ab75ead29836a60a8b6e415e6260c4ac777062e6f77bc4');
INSERT INTO blocks VALUES(310214,'6b6498938c5b75c479219197b56bbfcd0bcdafe8c53f44c9253ae6ba7c1cdf32fa787f59b631066a6f64f4d581af1fd28e4a5bfea96f914b95c1512f979ff029',310214000,NULL,NULL,'ab1283d1f5834c4ea057534f47f0046cf1a6116d8185dd01860d3b4d40f521e7','366fa9a5b880ff8d1bc3c636df1565af9ef80c3826ed464fcedba3e95d78090c','29eac2610acab217905af27fea2d0c92047583cad04ffe80e4d7212ffabfe851');
INSERT INTO blocks VALUES(310215,'72bfe8c51a45f0653315cf109218374fbbe1b58f9a8939c9a9547ba629993f78d0ab8fddf2ff5bb4b3ac5b02e6b12a73dacddfa5a6c226157ccd2c5c63bc07d6',310215000,NULL,NULL,'168475f6f5a869b45f86e41b4811f0012c256ebaa8c8b2933cc5635bbb18a1bf','d5d3e97b4e507eedbab059261f9b77889231760da383c5788b181ebfe269fc41','a12268e33f351dba96b775d88e6c7fab25f9fa6da10d1c0f31590acf49f65113');
INSERT INTO blocks VALUES(310216,'bb5034d8b3bbf63b4ba38cd0df331a67b6a2a4acf7c3b1f308525fa77507e1934f248e0c14f4121f29d34513093ea93d2ab1a0ad69f816683401042512f24112',310216000,NULL,NULL,'36a883693e0c7eb8b0d592903efe0527aa36921c53b3081d2bfd8e70c4bcd778','d7287ce4eaaff67af48f2f29f904e2d39387f36eccb1ab2c0608dabfe6f20655','e25affcfd736f75849b28b513a4011947b1712dff2ed1399ea28d658bd46cabd');
INSERT INTO blocks VALUES(310217,'aeedfa4625369164f54f43fab4fa144340162fa576556f9273817d9f6fcf1c19f649027e7761685b677e604fb80439fec1febe92a87320737e20358ab33b1266',310217000,NULL,NULL,'e9b6505422e96e245bf4c1a51ee1eb98d5add95c19cde1904709abf01837cee7','dee97dd10aa55e3185db95fae05dea2a8dcdaa9f6fc73e6937d2466e3db4cea7','b2d56835b4facb93fe1989469c438fbe23b24565a7ad50b48b48de956de1f1e2');
INSERT INTO blocks VALUES(310218,'3c7eb28c3fed2eb7213917ece79fca110f658ac69589355d0af33263f8717033ed4e3d20fab5e3819354b546a7c2fca5e91c1073a642094d6379ce02e46ca1e1',310218000,NULL,NULL,'fa5fa02a83035f8d9bc8f558301a40b2152b6f704f055c789775b654aadbd8ff','840f781f9006c228a0ec6ffdb9b142beabac3894fe6faaeb806d3adbdc3ea3e5','8a107c883cc01ab126b8dfd240157ec80febbb8b33368562469c739db695b225');
INSERT INTO blocks VALUES(310219,'17cbc2da6b36886d537c8ed24a713f490784aabe27e5657d0204768cc54e63db12d85ceb7050e080200ad014d4150abe7c5c74142f3c1c21d53bd774b5343e08',310219000,NULL,NULL,'fd6450cd4c5e1917444019c6139357569827357d743513c83f820dd0b1e353a1','5f8706ce670742adba40f3c9bf12487ce5019cf06256197e7f2dd68fb9f5c501','c52c7ea2648ff8846133498d128414c6a55b0d24f45f46c2a9d603777092e964');
INSERT INTO blocks VALUES(310220,'7b20b32736c01aac271311bcc87f09166ddda5a2e639f159ec939d015d0d6331114aa2af76dad0c088ca917d4ee689d3a6b151e9aca0039cfd5798e65cf59123',310220000,NULL,NULL,'cefb420d46d3482c700730b61b9cb93de6c71be0b8bcc0486cb834432ac5770b','70ca5c6f1eae887192dc1884858784716b1c6f3ed1bdb9b5fa798ba54a11ad5d','c8fe9b4782d3c621f4e401e5ee072c6bf592c450c49ea5fe0a42bae96fed00ef');
INSERT INTO blocks VALUES(310221,'2372d0adb62b755932693ea604b85e2ef86965ef740f1bbf6e226a1f2a9d03589d478f5309e1dea13de5265852f42bcaf2a532052bfb8ad8d34c85816da56983',310221000,NULL,NULL,'d4e2511c559c3aea5f92d8cab0ccbd48a14711a54b86a13356c960b831358c3c','d04529ff2cbbeeeefbbe3e54bbc1bc456f3dd0c6829d9b2b66be7e0eeee81292','d648aeefe66f5572cc448e8f72744594251316da23bb631c3e24bcafc219c8d1');
INSERT INTO blocks VALUES(310222,'f95edc9fe371af69326b4c9307e979e09e75c50e64133e32609675c711b28d2ac8ceeba2a0d0a9add615add1dae229610e0ce330c240d502f1daa10a5830f664',310222000,NULL,NULL,'74756543b96ab06b93b57fc96c36933f97757be624125b63fc682d14a4648fc9','32e51fba8571048ab35c2e351500f088659e7dd13e71f8d3ddaed30161e1a421','c47cefebedf7c59c9c6be716e52ffda2f39be0f5a9393ad09f5ae3b186eff1ce');
INSERT INTO blocks VALUES(310223,'f3738a31552dae2252726d3a3bb654720752b8c9a73450104e25ad9f37a78cde5e570969863b7e026fcdbbc19ab731ce3627ae1bd5942aebda24f751bf53838c',310223000,NULL,NULL,'5cf85815defc4ebb5cf9eba613ee1fc3365aec6db7a06ec3091b022adfd99752','a96624eb9a4a2f765e092666c1a2f801219795eb0b09b0431165bd1c11f2644e','146b847cba0328fcdea6e76e99b3045839f7e5ca9a6acdaec2c2b25257f864a1');
INSERT INTO blocks VALUES(310224,'2df029abfe5ae4e19763b54a85b6a30afdf4d81e6a851c9092b5ad39228d63c43da52f494361beefaa89ea263715886150e387c2785c8bffac01b50c794394e5',310224000,NULL,NULL,'80a377ec7f372b1fb354a8fa0f816f0424eecce346c46136357b3de8976b00d7','965aaea2287c6fef4ef91284f562b25c1d4650f5d6acfe77802a3d246fcfb0ba','b4b5dafe5f977f129e349d8be9ca590061de6bcffff3ee435e914ed6293c5768');
INSERT INTO blocks VALUES(310225,'2f1d3b02f51273ebb3b1f978cedf12171e60b68b4467c8a782e1812c836ff78f387aa5cc60f18c17fe69cf5acc8ecbd6f858a3de1ba0ba3f22bba112bbd512de',310225000,NULL,NULL,'a8653217271d0181d697548b805e0e98855115dbc39a4ec5af697e4598dd2504','2b2e45665ac61506dd2265ebafea34bac90caf77a44d11de2d198ec8b6c21ddb','58ea9a84220c77fc0e243a76245e5dacd5be7f92a59647ff32385de2a81f246f');
INSERT INTO blocks VALUES(310226,'1bd7bf5cdd75ff504e27576a94d0a60349c6d536fc9907e2b9d93878818c51f5d3966b50963933477c04003946df7bc38d9907ac077f11516133648d9b513f1c',310226000,NULL,NULL,'e33ef1324f868d0ec5f7fd972e5ef77c8a9ca9a155f6859c4ebd6f9733c19160','2f9b9f3fde3510e8e36d6d16873f5f52fe727b271a15442b2a149c1efb87847f','46689056fcd19da273747017732470c0aa9a211a2d71b0e1a83f747f358332bb');
INSERT INTO blocks VALUES(310227,'182587860a17a44392b7071876cf5f0d722ff68b97fc67529dba4c4cdc00ce27efab52dd90da13c988e94c97abca5086703f27a349a4a5270229ba522d6813b8',310227000,NULL,NULL,'ae3324201a1fed9fcc0847d4cb18bcdb92c6e826f2e4aa346bc33f67712a74c1','4b62e56da9f252bd0d6635d50d7ef41ca9f05aa0b8f817fe7aab4f98be5a8b9e','d10b51f24f758cc7687139185b2172202b84c48429dc99c87d6f41d0d4c0250a');
INSERT INTO blocks VALUES(310228,'ab47961393a0c8b3f86793e9a25f879f5200ab75f6fad587065e4f0b8ef3a51fd16f42dde4bbae0c250c967db4040a8470606404bea230c3d1f6dba4588af861',310228000,NULL,NULL,'19b6dd8993cd948e5b617fc8478c1a2be83dad4d27e5e52bba03583bfd36bfa3','10814a678ccb7745dd8d6c2f84d244998e21d6464616fc1fa6a9f2fb6be76f96','af6369d7a9766ed6bb9411905bbeced3114f2e3cb072d0ca2323550818c1af43');
INSERT INTO blocks VALUES(310229,'922ddf34d83b9f4acc670e0b1c9cc2561950f20c3d5654e43198fbd11c86407fc41c934216e8714b519d2692f32b79c89c8be85c637f0136b8a462bd4f728ac1',310229000,NULL,NULL,'d298bbe1429ed09717f634a03306fab5ccb8e4f462a48a8430bec80f1fabc664','7e34b60d70aa06fad4761cf3b675143215d8e7fee66d76c10b571143b68af5b7','4201b136d5256d5e52aada9962c444e482e5665d4e31766e982786c047d91c6d');
INSERT INTO blocks VALUES(310230,'08a1b604821ee7cbe963abc42c1dc8ce9273af94501537e7ef19e90cf504b61a80a99ec7952db4db85fd7832129d593126a1bc52b8ef30e6a52591b37e9413a0',310230000,NULL,NULL,'bcbdd5d311342d71b78a073006f59fb8feaac00335bdfb5b4cf9738607fee091','9b9247a1ae89ade82b09efba089a07394b4cd268b445e35511d6dfb569e7fe8f','03709841862e5ce4275e8eab49bb9af537acec053b762239d348e32b1a9d7f05');
INSERT INTO blocks VALUES(310231,'67ebe4bc3acab4936f1ced7bc5191928fe87d0713c27c58c56880368bf3efd48374eb223eef7d2f91fcc6a135a0a817185c464604d50780cf8c4a80f7a18d927',310231000,NULL,NULL,'8d7f44b4ce8cae60d95bb51afe2bf768c88acf6c4dc8f1cdf4eecf261f4d477a','0b2b84691d2c326d7d991ea6c045fef4b38d99251eb898a2f9a3fa6bc390bdd5','91159a14cffe22a8f3eb0ce4f560125e741a66efa4f84aee121eeb2c6a072a16');
INSERT INTO blocks VALUES(310232,'4b5c090aca519eb1296c14a778e317e464b49299241547340dcb808f0129e239cfb6469efab40c60a9c7eeb9aa02c341b953b69b324eb9d60ac0b6fbf1958000',310232000,NULL,NULL,'d99a73a2b8e7b5a4f6897dea14c57a0d2d8bde04f10f875e8ab3dd8da35194f8','1b2e340d74306dc0dfc732910e9f53bcd2eb6f23a4ec87e9c0c7d20be0f85137','271a07721627cc1cb213bd09999520899314835b337d90e1c866f787ed7eb4af');
INSERT INTO blocks VALUES(310233,'bf2d86cfad06136613e4257547021208ae35e8d2613b9ecbfc5ad079f63a983f47d09741327180168cd1dc30dbc42c073df223786aee9d9fd1f2a158b83b696b',310233000,NULL,NULL,'bf8c9b9d46afab5a4fd0a02d040e3f96d56879a8103d152c2e2ece22f0166753','f6c5c7d356a97da9a307b07780945826874deb7c043d875ace6a1274cb739d10','a2cf1e2393529a24f4342790176a853ad05ca962daef2bc701f5e5c22c0318b6');
INSERT INTO blocks VALUES(310234,'f136ca58bf14198246cbda783a439b2dd2524d51baf195630902a7b783be0286da4aebaab9c7073ee2b700b0fea21740a2d9842731a2018b357473190ac49969',310234000,NULL,NULL,'2e294ca044b35f2e9901de96ce330db197f5e03e96d4d19b3f83c2598223b501','6143651cb4a57d1fb60083248f4c63bc30ae36f41aa89066339094b4512b1bec','c4c86d046c041c4c74b33f3aec544506611edca18b100a65a66acc61d84f0b79');
INSERT INTO blocks VALUES(310235,'74bcaf9b0288fd96e527194252a8ff070351fc002b732ce00f7f09b37e7a93792e257bf847d4df70a61d43dd7d577d0140d121c0e088d1bf92fa4d4c79180a41',310235000,NULL,NULL,'54ff1dcd675e50f96a886038b2e7e78a3f5e233699887e75b06ed94ef0124866','f8c7512a0aca197aef06285591f2cbb2d9d57fb869b9408be56567f48f3b11bd','7e468d6ce694addff0dfca3956ae26628cb495c7d76f0788bf0fa6f51c6e18c8');
INSERT INTO blocks VALUES(310236,'d53cd57cca5e8d747b0c6a5d45eac66aaad1da1c9b3a93b12ac39d356ba2675c70fb00cd3c0e927fa08950c3d77034175daf5a550171a1ace7b3adb798e6c0ab',310236000,NULL,NULL,'3cf87c18e567eafa14fcd8146d0b183f87fd43a4f37ac9462d648ad3ee3f5f43','f573bd00be51b6df466b944e4e287c01c40db1846711ffeee0b3e5c2ceba82df','6be1dd447e6ccfc6cae3a00bb82283c62a36f3a51aabbb8e55df0aef231b0ad5');
INSERT INTO blocks VALUES(310237,'4ed36172ec27d2c496e9eb816c65eb6846f87683b5fb444543f6ffafaf29a37ce441644c4e7f1a2bca673cfdf3df4581c88f1d7a140fba4bb6700cd4407f2aa8',310237000,NULL,NULL,'dbee7786b16ba41c34a2bee1a4bf5e46178c76ed484171cc2c428217b14547c7','aa7b913995906a3238df75495fe16ffd5c6d40258e827bc3eead9f3f911214a9','b20bc9d77b923ccf648ccfabd7a44007335793e8fc49fbdfcf3b983f540458c9');
INSERT INTO blocks VALUES(310238,'55f9a7790e1576c56242c2559cdb867260fca89c3b82fdd5ef239095be1b7756dfb09e47054f5ff561415377936f93b2f65ec6d4a70fea51a39b4a8e7268ab09',310238000,NULL,NULL,'6b63e5897c43a9c76490072dc8a30579a09e8220a5cb4837d9919542e722630b','92df27639ad7bf4a2d45ed2d4a0465dd9faa53aff318e2de14800bb20c48e9ea','d7c34ed47c4ed99a13895d00c90ad63849363ba5639fdaf356654ff64235199d');
INSERT INTO blocks VALUES(310239,'6f3b9c52fe2462522690bf39312a5fe8a459c249cb3b843a752b252a96315f3523659ed40a96032137f599357f94d209a244debe80bdaaccab844225a134ef68',310239000,NULL,NULL,'58849bc13e2ab88e94905aa4c2d4df3d9f1c4d33977d7127879d248e1ea95149','a41c913e7df38d6e1b0cc98850fe62042e0710e6f10f952b6cf6ec4f24f3a359','468e51b5a4a90bb2f4928c689b4c7186d365146557b47ebe3a8d9979546e7948');
INSERT INTO blocks VALUES(310240,'6bbe056f8f605bd968aab01d94b6e2be82b2f7cc15e13a251bc9a82950bac50e709311e178b7535a8b35f8fb070fd2f1b62dd61c374e3760b1a12798ab7b4b43',310240000,NULL,NULL,'51df13287e12a0bc8157653cddd25bc6b2d41e5bdc62d3d91ac1d22781ec31a3','179330ee78147a571cf22e2fe3fa6fd15d776a2bfd537dbb57f7baab989bd11a','24184a2bc56c43b9841f635fc2a606a9daec38dda6023db537a1e211672cdacd');
INSERT INTO blocks VALUES(310241,'bc3487d59c2e60184d7ec9f0725d8feaef0be333fafbbf57ffe11246dd2a93941904c81982223aabff1ef880c9b3df069080d4d2d1d2752c87c91ec12731f607',310241000,NULL,NULL,'e2848ed74fe574a48436b450ab0c85258dd1c62d7d628c018a66bdd2083e23c4','5283aacdaabc81c205e1426f90301d9fac310affae18a8d3057297c6dcfa6f9c','269affce421ed8ad4b2d1d57f767a9ca5845a16998647e8aaf58cd7af008b117');
INSERT INTO blocks VALUES(310242,'f0ba89baf895b948dd31fa699904e3892581b8bb76a707fb966d42d51414f9a0a2ef6911d27c1ce923518f2d2a9f11818c311ea491ea840f0e8af5d7477f2bde',310242000,NULL,NULL,'8f3ba5507225c66a9b6b9647f31a32b073ca37f4e5670cf09419e98e28cca497','12c13253ece6ea2242db8f7e7fbd0c9b56fc9376f643e1f9c2b06301091a66f3','b19279e115630f2d19eec63971c6c7a8d897a1f00f5f534ba763b74b1c582d31');
INSERT INTO blocks VALUES(310243,'955811a1c33ac336f66727d94915d47d1c4d41b719336803209603ad7b710f15150e4b03cac6d615a10006e98e31040e7aba63f1c738fd334d991f49863e3227',310243000,NULL,NULL,'ac9e4d69c0aef577638f975b97b2c8e896d2f532c866a4de43f44b4485f2cc3f','7583dd1e4f2e91e196a01a61847d19c9c18517c3a21f2f09c0d3ea28fede4e07','9c2df4a16244edd0bc7f146fe26d15e6462e9832d80a8bea58ba76e817284662');
INSERT INTO blocks VALUES(310244,'6cc52646a6c05bc90de8289a26c4c7c66f5eb60a5f779df14710fe40ccc4d2b1e862e2a340b5cff39774313fe31005f374e6cf061671a846d490a344db6e7b2c',310244000,NULL,NULL,'da0816873e576b81cf91deae0195d3876232de9f5048be3e4ad3fd51ca649521','7aeb35810781fd6477654555dd24293739e8bdac13c765917fa80a0f760a64fc','03d7f91906c92613fec097b3a9b5154044613ee8eefc2bb7bff84ae9f7b8a8b4');
INSERT INTO blocks VALUES(310245,'8ea22989a2a25de3c02b6bbbc3f91dc33d1736f54bd863e142fd9d6014947cba0c6b359c26fb2ab2fc74b5ea3c9cd7b1726784496cfe84eeb7bca76f49afa55e',310245000,NULL,NULL,'d2e88e67a78d3897c47523bd9f4e9a33a561faf3b20c5b08f49d735d4e053460','67658e8c68606ac35688e5ed4669a67edc3c5baf98bf44ba17f1b69f74bd18dc','af8d0657a4863f25dcf04444a800547a3ec2f1e0d583212c593653c19f6b8953');
INSERT INTO blocks VALUES(310246,'b0a724456a7dd399f9bed9381bd98e97b547b7a87bee766b4c357fc492f576213dec71320d67e12ae7fa36f9ffceefb8ac86ceb491a5ce60db97b85de9149e05',310246000,NULL,NULL,'d6ecc4543bb89cc9b17198e1ec1bda12cd3f79c7662efd230eca089d9e0e64bc','c330c2c6f3104c8dd3f51166b2eeddc4a44219a800e802b4513934bc593ae7b7','74c7cb17ef8936c06f66afdf5d149536d9f401a4e6368efc0dc1c978a6815f42');
INSERT INTO blocks VALUES(310247,'26ae1dd58e1cf9ad6c79c6bc68f274fac5674d3747e027187d805f0e44276fd4f35fe820b02e1bd134fe614bbf7cba80c52df87349c1bf580cb45c75f6f0591f',310247000,NULL,NULL,'8455ba326f0e4fcda984cb9f3f35d0211db9f912b7b2362db4212455d89f820d','498f16d45b72f93279f24756837fb15051eec54e23ef05cd2da4d9447401412a','424505620ba8109eb0eb2e37012f36fc357e1baa22fe1be52203583b83cf8bce');
INSERT INTO blocks VALUES(310248,'9e5b5d0e1037fa3a3200cc7f5f0e271d838b475098df768cd25c944a400543762f8302fc0f1c88c67293c6836c394a9b6f32508d6f18c9f01dd7404fe5cb32af',310248000,NULL,NULL,'dfec3b1b3d3b32d6c2df2810d2b3598b5ba398a5b2a04274be4675d8156ad57e','bf383eeffe072853aee2e66cdf76ad9ef6d592b2e053595805afe671ca3ea5e8','c7b2b5eff3c8ccd37c20fea52dedfe69793d4d87e5cdeb451f0a5a2f66f9888c');
INSERT INTO blocks VALUES(310249,'d97148dcc24a8c83c7421819c5606b86e3c44447a1be95dd476bf7eea92407d77e61700961d3d7c807f433264d2494294db860ac6cf5488bc91e35807fb7804a',310249000,NULL,NULL,'7d6ed27a9f5a68a3fd93e60b52638ceac7dbc7396908cba3763040570ec37f66','ff0a11a9192c1eb61b15f2d6bfc389a847bf80a3c94c9de81f55c63598999990','653b6063fcf6055d1a8746c600f62068a3e27fe883b8d9f54fcd12fa0390bb42');
INSERT INTO blocks VALUES(310250,'3218c6bfa75b8c8df54b58e4c0553a4bea06879676a057d7b6504460a8cb2b4edc9847f39a039ce5d0f66fabd057ecffe8d64232e4e8eb9a57f75363d5b0a7df',310250000,NULL,NULL,'44a70fe2a28e0b5051f21925171ebc5d4f007501bc5806263b4c49556dde4bff','4d1a5d29b5080cfb597fd650e103bbd9d052b9d8c1ad862fdf51260ded699b81','60196c07d21a50c108aa83da35e4fa67c1d085711973f145abae5e7e4f902d9e');
INSERT INTO blocks VALUES(310251,'46010924ea340c67922d408342cd922d8094a24c6ab72179dfe1bc23fe8ad68faca91a05aed2d511757928fac92c2f30149d4469e6624a9ba7dfac76c9df2239',310251000,NULL,NULL,'5e24a59c70e7e3fb346ebc4b8d7b10d5cd8bfc69c37086b2fcada71b00054006','d1237497e70751cbde3f9a9d4f137cb010b4e535fb3f0f01701b7ec20be41f5e','bcf0e417167e3ce8d471934049a26db660d377f67ee7255bd9ac72c013100c42');
INSERT INTO blocks VALUES(310252,'88c50d377c25aa2ea34c0c3245777abf590ac77cd651210d8f31f2b30262918852f37c97b41c9168e397f1ea3e7162f506b5186c03f715fde36a9c2218bec173',310252000,NULL,NULL,'0726906153b73645ebdda08dbc1b1951a3f2a44f7df9c411afd0c8e26c67a9ef','f1b26d368c429cbf66de1c27501b8f38e0eb72f168a705666896a1250ce1f749','c683deb42f96f60994ce31ea0de5c6bdb05435459cd17f586557dc82a447c4f0');
INSERT INTO blocks VALUES(310253,'73b2496752d1bb6b927cc2069ef7d9004440fc9492012ecb8b71a50b58e43b92b6d3994a2e9d726292b62e43eaea092b023fd4b770f3fa59afb3187c85c131d9',310253000,NULL,NULL,'e47aee44802f13aa6abc7fd1f62ff7cd6b9afb48fedc04d676fcd8e6eb58c492','5d1c605ce7622e2f9b455a238abe11ac9dd394a2cbae143e49f041b3b0d91a7b','332fb4a26dfb932e91af7f63e02f717ad2b088a89f0c775246d09c8926be86b5');
INSERT INTO blocks VALUES(310254,'270bd129114e55c6c6b601c2451ce5a7747e1f3039223580a32190a5fd95badb75b25f619791d084d9c8a2efa80e4247cdf3dcc9caa19f2b3dc761d73436e83d',310254000,NULL,NULL,'50defce7d80b36ec9a94634061c3a1f80a4cc5db37e79cb142396e2597dbaf5a','91bdd75baab492a0693ccedf8db42667795c8fc813ec581bebd003ce8d3206e4','ba65b884024c5e32406404f260babe255e9b2f052dde17f64dfdc7fe9cab9c19');
INSERT INTO blocks VALUES(310255,'a15afb7fdcb15cbf453184be9cc3190be765ac149f6ad7ac967ba60cc21ba09df24cac96ae343361b262fe7b9a39cd76fffaba7a2c08bae7a7bd15d501ec225d',310255000,NULL,NULL,'78c9f13a386a45570f721657cb94d4f1bf7f931187b920f564a4591e14552c4a','f748bfcae6020d88c1748879bce17270efd7cf39923cbb30ae4a9be9d8a85226','57e7da17003f465018ed610caad7394538597c734db7dcd52fd155e2019969b2');
INSERT INTO blocks VALUES(310256,'7bcf35ff91943eb983e9f7f65ad5de5b6c07959e3858617b79cb791658f0acb13c0c29fc29d333e6094c0c1cbaf73ad32ecd5fa85602e4e25ab8ad785473ba83',310256000,NULL,NULL,'1f1c23e38a6c210f982a3ae712db3158c48abeb88512817ad7f1c2dfed752f38','ce9b3750e0e2f5c34a9abaf727899d2fb55a31aa7070ea7ea52050161634b8e6','1e4253693990338f2c690f577abd0162146baa9cc8b7f5822d62e658149a4479');
INSERT INTO blocks VALUES(310257,'f5e3467145f08e361d51dcc095569f28e189ee9be38b5eb0bf200b28a833e455a3de484211dc2517a17853399e5c471279cbbbddf75d2d28ab952ba3ce71d882',310257000,NULL,NULL,'4b8bf73c34103892fcc3b23d2e03b32e1d608cb6992b313d0015f06dee592aaf','950536461543727c169e91ad20bfbebb8a38163c3d423b51cdbff4691f9abe02','27ae298f567695cc60cd7e60abf9753b7ba9d3db4d0815bbbae291b250c43de4');
INSERT INTO blocks VALUES(310258,'818e2679cf7bee8ea493eb9d043f9b169f99648b23731ecd362ac7aacccb1da8614c1e031f24389139ec174d7d6258a9f0334b0d17c1e2bcc9a46eda665b7267',310258000,NULL,NULL,'1a853dbfadeaf50085017bc9435ab7a415c948d2e40089ae46f2b9f76647c89c','a8537b45d20991504f09e8b34a653737f80d4b22d5a5e60bc8112eae28cd9f96','26c540405a813f56337ab67769f547546963a56cc748d7e76ad323ef964eb905');
INSERT INTO blocks VALUES(310259,'8fc5d3af60bd9fb172f605d0c03ccfb5c154abca814f7dc2f0b594f5f418c110e525d3392c1d59104988c377e3e92c3d0a2ddb67f6cd06de5d78050889a63595',310259000,NULL,NULL,'2fbe03ab90dc460408d83880684dacb0633e85c8d1559756e6f86ace29cd341d','0eaa7f55d1ca4d496f2fa1b3f27483e544edfe951147e0a93c674d52a3bb9ede','cee0b80824d83f614d9525e24cdc64bfdf156c39e7f867934b08691b78fe41cc');
INSERT INTO blocks VALUES(310260,'bbacf422d763e74663cddea4aef9cf7bdbb74d456961182e04814e76dd6c57d768c12fb65b8decb364d2463aeefae9f8afb87b99b99b8c076dda14a5a5e7e7b7',310260000,NULL,NULL,'3ab4122496374a55eff29d2034e1b6b5aed7589ae4c66329f1ca3e0499708590','b42747b919e69caf8324188aea9112973763979c592737f7ff00c0bd97f32bd3','a6cb4148688cdc41a0b09e4f937f78ff1763083ab870c4b53ccd4fabb32dda66');
INSERT INTO blocks VALUES(310261,'b38e530ac6aada95885f3bb1aab84dbf151173d2194af388db751975f4e9ee4c7c3da2677a8dcfb98eab4da72760785ae5c404a6a6c1f61ab8e759b9ca6dd12a',310261000,NULL,NULL,'6ed574ae0aab6eb3f92a1716afee6ea37ef9e450e7b52d58d4186bb01e2b03b0','3447bd72a4d50e4dbd528ac279592f15dd21a6403a30901af9f6d882a31f221d','1320242420a6ca36e8f862ceafe258f20f7567850f0252f357f273202215bd21');
INSERT INTO blocks VALUES(310262,'329a9a235bb3084b2f8899d39a12e3a1916faed8aa28a2df7b7aca72c89903d3a8d697a58ed6488ae5a2f029d650acef7ab0f091095d62ce1cfb6b4b32aa23d4',310262000,NULL,NULL,'0312e3df37033157336d59c30db43a70e5b434a30cc4ed6b67d3e9f2fd2e2b5c','a12449d32660a5284f8ed8169fcd643508d4b62ecc6e85af5567a1137b4ee3e7','b3a2bc31fae551cbe411fc5b800eaf8ffc5e7d4d64b0e4f41d78fa183dfc19d8');
INSERT INTO blocks VALUES(310263,'43cee48f0e0d9852ee3b828eac3f6bc14428cb57fbb8348db963c21b7427eb03aeac1462650a80c97eeb74654e9773c9b789ad9a12b88f62da06a77821410174',310263000,NULL,NULL,'9ee568b93b0fd24ca45108a015122532e16c70a387503542bd1cada92c79774f','090a9c4a5b216308f84be39ffa8e229a6c35b4a69b32c7303fb46c3d4be3f515','cbde7fcd523bac43acbc4448c3c6e4aabc9716ff18896fa70becfd9aa6d8c2b0');
INSERT INTO blocks VALUES(310264,'be354373852f06ac45faa0e3650eb6f9afaa836c224c7737d81bcf5f79786dd3eb775bf8980078b89ad81003dc9b261afdf0c2152e6d8de4e285c2962b384cb0',310264000,NULL,NULL,'aee48cdffbb6e982416782e96576e3746b609583e841d5d6c4e148b168aa9d58','3fa5d5e4e8136ef1871d7b3a8c1ebc8a47f0674e813fa591269f7e4ef69bbeca','d20021d4a65721899f5c3f873737eb4f735d0c7e2365146f72e92de1dc2b9759');
INSERT INTO blocks VALUES(310265,'6d967f14cb8425c0396d58de9aaf681a337fdbd4ace6a33a32f9c5523360c119962a868832e264f24ffbed3cf8172982f876abebb2908faeb46352b9263f97cf',310265000,NULL,NULL,'d19a7116623c82ffa1f9b275bf4e69d555592e1fd7463fa8480ad5d801e59674','fcb3453a6c18853b42ddebc8a9f498152dd8ea22b8f296d950de9b38aac5bcc1','c1ebbae53be333a672186c72d897f91a9995722884e04aee2005af4698ed4d58');
INSERT INTO blocks VALUES(310266,'4e350363a67c4de925636f42e82623183e13432dd41a0169a0a48f3e5ec330a809a75d6e6bba3b5468d3fbefd1636815e6ee37086770d0a317acec3498c99213',310266000,NULL,NULL,'17f1b1bc913b14498f44ed71b99655eaa32ebb2d66cef20b83882e03f3d141e9','487ee7fe3cccd6c508ccd98e54d8edf3a68bd831cfa16c32e400638c591b18ba','8a4ecc93848d6a598cabed27fbd3fca899eb0bd0dc772442feef67ced58b03f2');
INSERT INTO blocks VALUES(310267,'578d02e8840ddd4cb36a8e7e32fe9424e7dfb027a8320b63d2ef57b682368af5748cf901aa2f5b0f4c2ea5981bbfa8fe1ea7dc2865590256af92f20da7a14d9f',310267000,NULL,NULL,'cd2fbf09940b76f1e65dd646130b1908f19cb9858eea8ebda8caaa3bce59fe05','da35c54dfe5cc7909a85fc233df9f82a362be6414397baa7a55caae934d6322a','29865cdf3fd6da677495a102a44f63d9d034b2423eb70a0e50f37e8f4e9c76c9');
INSERT INTO blocks VALUES(310268,'ac55ff8b1c52daf132aad739c9ba8171cb224f0f97db6e449d13a40e59e7c99fef6451ab6fb88994024cfa8d12038eb60ec026f26e470b72d8988e3d7e82c0ca',310268000,NULL,NULL,'4fa8d6ef979a8ea410b174029d0e2e2482e82fd9d19f5b43cb541adf47f061bc','1a932062a0acd1b2d2febfe0d3c4606cc63bdb6ab0990ff94545388c9c4f68b8','8ae1557a9015ac48f385e87c5d74185e58ecaf3c11f8489c20955085d355f5ed');
INSERT INTO blocks VALUES(310269,'b6bbcfdd4921a7996cbb23215ea7b7ab4a9a2e113d764ccbe918c7fab37993328304f5ec154b98f2d82f6d310ab48227143dc4e81c50802c02e0f34f97b425e6',310269000,NULL,NULL,'e5f99ba407163e760c55c0ac5682ec2d62df829ed375fe19f98789dde73f4893','b749f553af4daf68fa68927f3272becc40482a12b45467e0124b6c5aa076d8cc','06cac5b6e2bdfb70210169ef40ebbbe9bc92832b056d3dfd393976ee25dbc701');
INSERT INTO blocks VALUES(310270,'0b120e8e68a0636ce794708b4d5196869c8d3da2635731d97c79bd5a5eb4badbac8348cbe34941a424b923cecc0a493d1e69002e75724a700a82a9e93af7526a',310270000,NULL,NULL,'dd8f950db5a330ddb1acc8703749d03a5f70a0d63d82f2a6557ce23076ccf776','7e8a432203aabbcc30b2746db397bc33df6c466040be56dcb7f4d43ae02800f7','acc5e6c7ad44e8c31fb90a687d228432ded68a5a6b36adecc70a3a0ea1e4c750');
INSERT INTO blocks VALUES(310271,'d77c39d4ed0f1859bd78d5edec895dc30421471d55f306a1e98ba5d05e1e4b9182e0b5ab3cc3b398763d92051664ef21c542548e6d7adf5cfba4d5778ade6d45',310271000,NULL,NULL,'f6151034f9eb354f80314238fa5e3a4992e66b6a1cad72534655267daeb15d48','e3abe5ce9feb0d840a7533970bbff56cef8390beede40e742f5c208d231887cf','5c006e3be2009665145895d9bfaec4459c2b7050f2dec80ab9b5dfc33cbdba63');
INSERT INTO blocks VALUES(310272,'054faab4b88bad25e7e1fea77551755a598b487ccc231a81a0ad9336fe09501c2f6424bccfb7c3247157d580fb7ff00fc484ec4c2688e377a1c20c99652ec677',310272000,NULL,NULL,'73c45a2aec0336ae748c65c2f33c66bce579e83e587e287330c2e2dad492468d','3a40f5be17d6a831af7995d00d13c3a2cc7cd2ff7cacf5d3dfbe6974efa12807','a4d00f65fb941d7bc186a9e041ffd071b2ea60a380dff1a44b2effd0b9363cff');
INSERT INTO blocks VALUES(310273,'a171bb8d6586c3aef696cfe9fd9e48ddcbc658744a8097edeffbef5f40f98d8298d7edb2f70cc47adb3b6e492babdad1ea4dea67a717e8817a3c37c8ca0461a2',310273000,NULL,NULL,'fc6fc1c397dc150c571c2755bac7308c37a2979a190a36cc5ded35283142474a','ca17696ac88528be889721111e1852ce0623b46a17f435215795e57d54ab90fb','75a535ae314ba0eb7d647a95a28a9eddaf5afcff59d52691dbdf9e7c6b2a5744');
INSERT INTO blocks VALUES(310274,'73b557dca209f386ea939ac0a9d98e0b876980773a7444be789fda03ae6c3ef9c50acc34639639ed6acdcf37e9cc1056d074edcdf058823338191c8ceab4ea21',310274000,NULL,NULL,'5d1e9c31260431e19eaf8393144c00d759cdc5d0fa29219c8741b30bcb6ebed3','2f8c83d4fcba856887dc58f5b9a68497f5f07abbc29a612ff86412c1309334ce','7593cc124c7ba4c5fd5b1ee5471e4a70645628f27cf18424adfd661bec37ad1a');
INSERT INTO blocks VALUES(310275,'86cfd8be8a981a153d5ba5cf3558b28dfc3f9d260d9a652bc5a07c7588d33af90c6bca26c708de6d66da96f758d948e7c218418a323dcf12c50f2ae30ffddeeb',310275000,NULL,NULL,'7af07336986c7943ba29d0468a38039c3d0b20957b72a77ce9596d922e974933','fce08c7f3a531ee905486b6a34acbdd039af475a114b9591db7f998fc89d0711','633d86058493dbe379df7e578fdcf6e786c4427b4063ea50cd36d31fdab39b3c');
INSERT INTO blocks VALUES(310276,'826cce42a9d98206e34cb23fd88de3a762e4efb646bfc2b3a6b4a65083dc3ccf3048311bd14f82cb41135c6c3201355e402d6f900ca2e8074e74c1bf0fad626e',310276000,NULL,NULL,'c106a2cd7f1f0ee7d23baa36fda5ae469fa3ee2463da98a3073b8650a0970173','412328c48bd54c1c0aff03f83adf53716fcfdcb8beb901b284caa171b844650c','0835da67ae668d1f991096b0a7850eb5fd9703dd0f8e72620bca9e1849f47dc3');
INSERT INTO blocks VALUES(310277,'02add916255878e70769652c6484317acfa5821ab020b71919b0d8ec04fcedd8a1c63b9e8db069eee33865d88d39ad312d100f6d923cbe8cd73bc512a3725491',310277000,NULL,NULL,'cf49e13ef3169beeb341c9a31f6032ed205c2f9ab40e43c01ca0ed582861df24','8790921ba4df8de3aef9448902e3404cefffbf50c970061eb1ba92d78d45ed11','486dbbba1622fee42006a63d835d0e2b37e2c7f74cc7a0d684b99f6bf40798a3');
INSERT INTO blocks VALUES(310278,'467e9bcdcb93dc76a0aaee92ff7fd9a9a490acb90fa3b2e6b92183dd2d7880e8375b6d1114d96677642b6c7787f1fd6987a71fc2607c0b1e86b3a9d3f32bb761',310278000,NULL,NULL,'7d20ec29ee1a9294f27c29d9c933add6de266779425169f74432b6f954f2b765','af08fa3db178df7fc8b7332bf04108f87ae62a2825adebbc531a47924bd7ffb3','33dec018c3c3556d01d84521ac35f09f6dee04d46518bbc0b08781a9c3fa6d53');
INSERT INTO blocks VALUES(310279,'220b0e071375f422d443725458be76bf1d2547e07b70dad68ce98f16654ff5c0cc28da1101aab72203df390ed67bb63599df1b730190f58258fd5f172236e36e',310279000,NULL,NULL,'14613ebc4f0d4140a1e594d32986e825cb57d273345cb2cf3cef39765a4e5d2a','1136cbfc54643216971a1b628c259470f4a20b8ec9ea2f001aeeae8264553553','451db6270292914b4b8a459952b9909b3c77033980eaa3cdef32a05865af8976');
INSERT INTO blocks VALUES(310280,'afea20e259ff60c16506213fa23f6a5847006ee596a36631e6ef71ed53bb226002822ea5e284ffc526b25f51dedcdd62e645aa9d19e59c7644cd996c50c0764c',310280000,NULL,NULL,'eedef4534d5d4f9cf41f5c778a8ad29bee69f0f0b24743a39ba6f8344589359d','19347a8354a3763f921fb161cf345d5acdc2a78c1d04e489f8179d6cc306af8f','cc36b2ff05156d7eeb366aa32dbe1c206063395ca00094e312b0987b9050e77f');
INSERT INTO blocks VALUES(310281,'5566dd842f5804cd5ab2449032bbd1957a8faca05005ce257a1b4faf9065d9aeaaee29245f2689ecb521801b316959b0ec164ed36cd61c368ddaa8f906bafc42',310281000,NULL,NULL,'69bfbefc33d2e86d3d82df7a5a1f7711858f93538c9984583a99553fe5ee17ce','2a84366912e5d0b6a669f19826adf69746e8267ba29b8de6f75fab0c36f5a065','fa54d03a20b9aa7f7c6487f07ff0f17d50bf7e334a5bd010db9f52b4355ae501');
INSERT INTO blocks VALUES(310282,'c7db06d41663e0575d55683a2209f9682a97f4a089393581821cd7a986667a30675162782c61c731b611facfdce51d7dc561d0d0e486932560f0e2a799f8d411',310282000,NULL,NULL,'e16114c54d765521022a80105caa0b8be117fc5b9d36c254b8b925ae69f94d61','2c6b063ada04a6b8c996f1ad7ae03b680621ef740d2f9b405bd0ca4d89790012','78c1171f317ee73b44e18302438ef5f5af1dbddac16cf7de17f7b3006c62dd26');
INSERT INTO blocks VALUES(310283,'6e856dfa84f3539d85735c94ae99b764db91b44b6999503b42819e40b25bcffcc6c9985999618af8c55ee1589ac50030830abf8a65bba9642d0637813a5ec7bd',310283000,NULL,NULL,'8bdcf055f1f77f121ff35d2b1e43886e6ea0ec2e42b29649da7b6366494a3e69','2e248568a62f8a21d749e1abc703dd5a5ca10eb23e3c0ebe33d262facfb8ae02','5022437a544a2896f94a67bc56841c6a3ca292cb54932a9351be4ae9a37486d1');
INSERT INTO blocks VALUES(310284,'fe98f7af8ab0181da5d10499189d8757c75c69736169729972d061022656a03b79df21666abd106a6b62a52c96f061a49eaacc2b15f7ec7ba392e2e1d46742be',310284000,NULL,NULL,'8b6831c3df9bffa272eeeac93ea367cf14c3442f34acd86397de7898112118fd','15665e02ef8c15cad39625a262260fbd13e1848997ab3eb2a725d25772c2fa18','41f6bbedcf7e88c46ee7ce277274165023efc4a37025e3c7c2b2ad5fc78e410e');
INSERT INTO blocks VALUES(310285,'7a9695623926cff36e00a90465d0c727c155d3cd7c8bc28ab4b5930bdc841743c9a8e9e5e36ba0f0bf915b5722306b9d7ff53a93720bde94efeb8ae2ef42593e',310285000,NULL,NULL,'138444888d3a790c8a0111da680243218301f1497e6df8f55fb484522ea82f2b','9b22391167add5ffb033401926af2aa79d8c240163e3f462fb9510baf0e69601','73f1e612b07e3109731a5a264db0c1ce41bb4dca059abd0fa6a2f3bd343358bc');
INSERT INTO blocks VALUES(310286,'2624ae522f1100520fb3dc295edfcae32e82f3e6b9db20d37949f26eba5d78bc94cd8d13624a0a87e045e963415aa2c7db7e243cf1f7beaa4a998501b02fab21',310286000,NULL,NULL,'87a28e638377e98f07f5006a3068c754a7e5a6ad6bf0b01660e68c37f5dd167e','939bffefcb61d136f610efb2fb140653fdf7dd1768fe7a03586693c1efb59480','ec441a252191ae3b0ed2feb0524820d1acba6cc2106fd4030c7cd5a00a700883');
INSERT INTO blocks VALUES(310287,'9214a0d94987dadff791b0558d5c16b9c9165d9bde2954d6e8d235ba3069726be601283d34061f818f130f46e94fa786c4d422a83a539c811d915220fad3dafa',310287000,NULL,NULL,'c0e5a0b5a766b6492568db8ee5efb28d9eecac3923c049871785355a1ab66bc0','106ef704f35a8b29bf6d34db7d071d061ef2809c21690de85776abb95650394d','d3764adbd717df6ff0f3144fd4812e7f88c87998575c2625f887bdbdb9706e99');
INSERT INTO blocks VALUES(310288,'a4d7a0e721a4a7ab788f26845026d5de724d036ef9023745415f8b93214c7bcb47562d18a7bad38e121513093675fe36673d156293f3fc5627af25a70c69d161',310288000,NULL,NULL,'419f92c8bb6e5be33f8340f32380d6877b1f270fd8660814b00e5250b79bcbde','3f914569dc7c1c90df311368cd4d8228b9dd54c17a4b17175c39acc0a107da8e','dff18911c8c3d12c3e431735e00d1039244eb1773a916591996969c5c18bd7ef');
INSERT INTO blocks VALUES(310289,'6f959963ac7d132fa919eda3c2e485b9447723b048675bd38e0107ab57295a5a0af1d97c1310d4f527690a5919e77d4bedc3ea45ed51974ca7072a31d5166610',310289000,NULL,NULL,'f8dd8e467e0b2f3bc9705dac300ebbd69f32a115ee7a3506aac2578b9ef409f3','f7bd2756cee86f7f2886947e49fbc033a88140bad9a510539d099d50293c0ebe','fe8dc4e0237e41e1b0ecb590aff9ee94149aa01ce2678210b565cd8b1e487bc2');
INSERT INTO blocks VALUES(310290,'6a3ba0d21e789f852b724811d69a5d89024ec6854b7b75cbbb7c6dd9ea2c4fbc5a3437fb76a01b4d20545bcdd4ad06a2285ba1bfa5099aa6fd0a877a413dedb8',310290000,NULL,NULL,'7a0f8e32e857c99feb715b1f610cead2a3aa5e9d9d2e0859650891f8a69efedb','b3d755a6265d588e583af22fc9e1d421890387fa2fa0bc53bcecebf5fff8049f','59f737361ce9ebb94eea6e5180f8c3ac9117ea9caa4ca562506b54fc9ba49694');
INSERT INTO blocks VALUES(310291,'1ce62e1e518527fdd1b698ac4b42cc6712d539c55a748b2d37b1f942c013b90077abc059f6b78650e3834ce9ffb14cfe9a3e6f42ccfe1eff6f170390940c925d',310291000,NULL,NULL,'53fc536ac789417c95cb020164592982b239b793ce70a93888243b6bf73fdb95','74b38ef83780f2dd13c68cb40da4a006a8c2766a5e3f0da3e86288da3141e192','2e6e122cadb2ab77e1524ab4c6cd3054dc8c981c97695bedb836fed632a2ac49');
INSERT INTO blocks VALUES(310292,'4073408de52fea7571ff4d12b63503805d67cf130f794659fbed6342b0dd8f53c2822e320db58fc45dc54bf0e8010c9dd24c62d38052c2cf8cf8c2411e86177b',310292000,NULL,NULL,'2d901c6f9fae51da0f46ca466c8811500738a8e88edbf4e24281d4f76b8d3f02','dbc84dfcfb1357ae1331d10172ff92255aa0ecb830b7d332075fb6c73ae1082c','93b23bcf021b0fb29e75f08ce0ae49e79f50979c6c52a5635073f36cd71eb55d');
INSERT INTO blocks VALUES(310293,'003486f9100cfb991b673a59380125d9536c5242eecaa36dd1ff339e96c26d4856c8acd845e478c7fc1139c9f177baffd6502ed7247000d944ccd05ab6048811',310293000,NULL,NULL,'98c7a9bfdbd877b8fb2a055dcdc16da3b9391ad2fcbc5d6f0636d6f3dc3cd4a3','bf181f06bb0e141dc5ee7ce7cba918baf03b486c08c63801896af942dba91044','83bbded1391a8e112f1001b13f027b99269b66bea22ace207b8390b867dc443a');
INSERT INTO blocks VALUES(310294,'b2b303fa6d9a561c08511745e8a0c1d31b7774d93d9f79773622c40ecb0b8617e55bd9fcf663c21c598567597327b4bb7af66b4de6bc924d5b168777e4f7c626',310294000,NULL,NULL,'1b0954a46412d817b912e9d03c4cf97b01b2a1795502617761257d26b7988102','026fa319ebb0516904d394e285f900d0d12d766be9a96e7f47b609650ad63440','c2f956de660c851bfd4d59d90450957f88bc8afad4cfd49ae1bc332ce09e60b5');
INSERT INTO blocks VALUES(310295,'4f8623f4cbdd3d19c8c104468f4446b9a2740e2edd8ca76b824eed95bcb98037a4d2b8b10dd46b57e4c0ab4e6f463d8a2c21d51b87096ddcbee70413eabe6c23',310295000,NULL,NULL,'964ae66af8efc956698cb9c91027d06129910cb7784df4b8c407c241401da437','3d5ea99250787bcce0d1b1533bb46507abbd2754e9fad7903e6bda837146a360','06a5e680d1da346dc837d7742f45d270072a60452bdab4974a2a648d8758b4de');
INSERT INTO blocks VALUES(310296,'6dd021fe0c238c4a9cbad9f27b1fe6f24239c9857542d4d4829d6658a472d0066b622ed36e5bcf85a50eb028805cdea878797633bc89434080e974b370d2515d',310296000,NULL,NULL,'7579d0e8a24edee123a95c97e2f079c6d115123568854f58a8cb9ec3881ac86f','94a4384532b7de7a5f5122ac1e43b966f424c5b273121815c0f0a82475440dc7','07e1b1d4bca32fee21f7a0506dd62981989213184a1278f1df70aadbf2f5c777');
INSERT INTO blocks VALUES(310297,'3925f11e402b0e127d943c5703b3db99bf2c1ca4e7877fe578f42c38b92a13ec115f911b732ee5edc5ae9d80c7690e4ec9b254468e3a2d438c722dfee4bca75e',310297000,NULL,NULL,'1cd152e5d90c17d782243a4b5690c6997ebdd18fffda0de838d2b2153f9fefd6','34adff8491b9ccf0c3de5feea6632697c2260c0358123330787daffd6868d79c','8a28e07f513c2a53e4f195e47f2b17ca63f1bde7ddc61d05790da56b373730ae');
INSERT INTO blocks VALUES(310298,'5d32d690b68831edc24bcff96f1b6129a22b3b977a1fc4775cfd038a76a812bc0b0d41ec58be6f7df61043128d0346179004b11a0e5b4b979efc5babf699e102',310298000,NULL,NULL,'9a16c344e1fc032d12eac114e4afa6fa20945601adbc03ebe89e23846eb98a80','32fe435c94aea3f8f2397a11a62360671f2ebe5655eda74dd85747c7be4d6de3','74177e2046a1f9372d8faee80476d6ba34763c73225baeb5f3a41080dcc8011e');
INSERT INTO blocks VALUES(310299,'1f5018a44c7217b036e1f5efa7c12fb3145989bf61c9b0b0cf0ac8141ac676d2f1c5b8c2c40578c90cd5a6ea218c55a71775e8c52b81d98786606754fd4a130e',310299000,NULL,NULL,'76c5103eabac42741d5cd208f6462e5a32d5238ad13136e226309248371119b6','00d073c6c1b2617e4b9583cd1b796de672088deef6804509ba2b060781ad92b0','d6e1444a856342d6c05ddd04d11fa2ea7c5e12153ae3613981b120bb08307bbc');
INSERT INTO blocks VALUES(310300,'bbb7d684bb01cf40cf1bd412676278f0fb99c2d85b89de148e8958513a121519f54ded1b032190176324cfc89e4a59723c94ddecd8cf12c8a0480a49a2461f99',310300000,NULL,NULL,'601a8f873f583291fa78e692e7629a1a28e275ec7c8efb99a0fa056ca412b0f5','cd8efbdb46901cbca7500e882ea4557fb2d303b38627d1c2f8b341f98abf07b4','f19f8c6444914c063133fb2cde5fff30cebde0dc3ca04f7cb99592f3ef891d66');
INSERT INTO blocks VALUES(310301,'92a853ea11ef50c188fa6009d019f8cea56d19f636c9118fcf8b24b98f9aef68fbe37a1ee00e39b3ae20204fd189180e1227279847925edd736de60d1cc44310',310301000,NULL,NULL,'25b262d2b2f14247c97db672a800973ab642e7fc6a2e827e5309820eaf70bf87','11fe82f692fdca58a127c169f600f36596f79c8525cc9d021750cd2f19a22696','2a2cb9a27a9c6e603847ccdb30d674b562acc1447b79ed45de57a6987ae633af');
INSERT INTO blocks VALUES(310302,'87a23b0e57a3eb9cb2e2dae0c2215756b7e59d3e845a95d58ab216b3feb01d7474a3258dedffdfba55b84fd4c7a686879f24a99a24cf981fe14a0bf5571d63a6',310302000,NULL,NULL,'a6e23fdfab6adb4e9c0493611b53182f1b7843adbe486df9426ff3895128e5e3','afcd93f1696bba201d10e18c0f1e03d234b78340eb0be97e4451b226dab8939f','3d9ba2f0e3d965eee4bf8e15b322d0ca0f87f3d7afcc5be421a143c18cfee33c');
INSERT INTO blocks VALUES(310303,'0a2826fddd606c82bb20943be515f94e78f75fd316b78daeeb0ce17f4fe8459dc4e191ebdb2ecf6367f64f07f8f9ddb1390198f5233203df06225767151834a4',310303000,NULL,NULL,'b6696821e957a4170b8cea8267b43fdee97c11f5caa8b462ba5f6b470ea08685','9d0eb23dc34bf7421cb58f2080504226b5d0522c581033006dd7ad2a8ed6bfa1','00942e3a1daf9443863136953dafd1864f7ce4753824bef25aa8a49fa6617a03');
INSERT INTO blocks VALUES(310304,'21dafb9130b529fd2ba53c761f1636bf89a97dfddfd333e60260062e5112bc0e326f015e6a82e2d7cdc743752349bfa2cc5fafd914a65c09c74451ec79b17ad1',310304000,NULL,NULL,'b43e0464bfeccfc51de0165f337c347884903fae6907987b12fec15d74519029','f9576eeaa9ec7288a4a56e6b192f982ae4fe66c0e3f7472d7b40d110e51c5809','e8d6bbc7899e14432eb0d954b0c97525ad860a173b1b568af57ea2457f37816b');
INSERT INTO blocks VALUES(310305,'d9cb2851ce7293829a5c4461a4c1fcd4bbab46012b449224f21e10d64fc7bde8d8f09847c236f2edcc7d8054e8b0672727de121fcfec1022eb1cac832a252f26',310305000,NULL,NULL,'c625d1127221a5d6a68d3a3a0dabb0b7852c7cc79244baf309881e11cb2e12f8','b52190557f39acb5d7795368e1e02714a839540c69b1b90f7f99c908d5f90f51','5c96521be89539b572b7dfdff44e070bee20241eae612d3141873f6eb00cc4c3');
INSERT INTO blocks VALUES(310306,'58cd7308a7f9938dee45f72fb9a559fb9c6b1a4937d08df694dceff41b2ff2eaa3a1d58677a1c000002f13e4e9842233ff99d035e1bd2d11b986923ec70e96f1',310306000,NULL,NULL,'654e82984746411ef7eecda06d212f9b24ed5bf8727f36e4c3a264daaa9a206b','7b864c176bc1b2753ec5628ea28a417c08de46591b7ed127d26de1d7acc3bd93','1ab8dd3976017fe301ac36a68f4ff47ea30dfcd2f715b927e20772f946138d10');
INSERT INTO blocks VALUES(310307,'962e842a8722d72b9a24eb689ffd9740bad6a522c214e3b007775321459e9f1164a7323868bf7a8444413510dafa902769d3a5b209434ca1dd4d4f557bda14cc',310307000,NULL,NULL,'265eeb3ab71d92f2ec88335f045164f7da10305c688d9e0ec7ce969317aced7b','99c3f6ec3fcd90e8e9184b394627735b0ab0578d15cfc4feef361b22133d97a0','8a93a475c5c7b459016ebc2035af63fc6295a07ee5c4b1affa6665e18f947b37');
INSERT INTO blocks VALUES(310308,'cab1dadfbd7dd20cb6d6856929efd60afa460eab4fb1901a04578553494871800c7573a406ce1551cfd51a4511506bdc0e1666470a39df282180776820419d7c',310308000,NULL,NULL,'c6bcc6e98db48cd1ca8d05fd70baf328d9e2c94a6e80d6623398fee16eea75c5','6bcca2d959c6bc6acc56df0ac5d997c50bdd39d5a543f7076bebad50c037660b','9c9f2d0c106cad3b97fad2ceeca3f2295213bb94c136f8250b5aefbbc70ee882');
INSERT INTO blocks VALUES(310309,'026906f0aef4615af04b5f9752676e4e478b571b0b80066fa5d949e5b9341a8e693afce2c1ee50d244024de6e73d06372d26a1b370b7d4f8b2049481cb9f40db',310309000,NULL,NULL,'2244d53f414d83fcdfc7138c7445f0fa287b529ace102a4f85e92c729f63c2cb','ebfb899b0f6b21735cc38fb008b608511b70d7f9267f060b76a1ec2e0b38e9b0','9f09008c256c9866fbdf7af255c2be2f76148e1b625a223ec11d3e9d149d4fdf');
INSERT INTO blocks VALUES(310310,'64a3783438a14dc900c87edbf5a67e8b6ea58772ed60a90b580b602be8765ce5e22255c582c485c82e530d4bc2c0d085a1a468981d6dce03e85bf1db50c03517',310310000,NULL,NULL,'63a8d8319641ceaff607e2b9b31086d3f7a8ee2ec0d0e0676f6952f9c01422a1','cf0bc239a301b9c9fae62ab581d927a3ac774107360744959dcd72f59fe178d2','0d2a7caa46511280b5c5c7115870820b5050508aa6551b43a7e34ce4b969e1e9');
INSERT INTO blocks VALUES(310311,'9d6787ec7e78e5ef1da4e0c01cefc94476d6d94105537cc3632a07ea60645397968292f7d2cfbabc12abd299d61b9a4b25bb88fa55850a94e123e6ad2fd2d7c2',310311000,NULL,NULL,'c838121678e2cc8370883197385af029a32079cbd6ae09caf2206882612571ed','e28dbb7d338a594f6d3cee5d54faed6c2ca5bc99347fa33f74e829e09e942d3c','75d393e93ad67b3df10cb371d415fe2a686085ee261390f667697b38fe5bf0bb');
INSERT INTO blocks VALUES(310312,'c699c622fa8fd4d10cc80fd2db029660fa6d9d65e00e5ef2023bd5f9f377d2dcdfd7f474601c202380f2fbcdcfa39f0e238a4db516ca470ab112bde1614a10e0',310312000,NULL,NULL,'50376c3ecb12be6400457536d89978fdf11db0f5ab3884cae997b433b88e313b','2659a9ea59a3a683b3da236e595225187e5e7ec441126440c589529d07556ee1','adb81ccfedd7a4ae965c1ef4df375f4c433d9ffada8452bc2f4ba0ec37cb2c4a');
INSERT INTO blocks VALUES(310313,'67b5753aeacc18b7d7f08ed314ea0a8c85f4f2c53d1c632d4320c5e55f493ab6491f3b023a779cb214bc52b49d8899a0060f2bf9a0c9ca242d69715e1f80838a',310313000,NULL,NULL,'667e05407638c94b1f5b316089064b57d6d6f41767d93c3e1e04b27fc0f480bb','6fb3bddffbd388aa03d42218c83936fc8466e59c17621507f82402a1aaa1b3e2','4e0d0ec24e5a221b9cfa509e26e74297a6f18262a9a197adb35be0fc9b80f1c6');
INSERT INTO blocks VALUES(310314,'8c7e3bcdfb8b5468c68460626322ef21ccb05d5b4fccfa63fbba41ecc0988abf5672a884378abb8ce7bb35e6cccdd63765a9d052a575d30ada5b3fec51a61aba',310314000,NULL,NULL,'f0c4d4ebd14beb1f9a4e15a1b74057e451d5c59d4b84a6dc22b075f6fc617207','d619c128a2e6c90b284e9a276732a16cc1102164a65b017f557c4f030bde8a95','efd27df38cc4dbcfa0b68e8fafde80401e3473d738ab88a738c4fc4f59947be0');
INSERT INTO blocks VALUES(310315,'2859914ed7ee244fb079ef25ee5a7eb922d41e085a8b53b9c604a84946252f7c2c5d3bfccde6001f6fa94acdb4512cad4fd80d5042553ee8d5bb939412fc04a9',310315000,NULL,NULL,'fcc454d39d2174817578a1fca23839ceda6ea6dfcf08b4527f6d3416e0a84ab0','0c046690a92c6a21e73ee069c3d589f28c89c9bbfca20a615128655a5340fc74','48561df1e97f7acf39cef1b4e44c7dd55130b53a14c462a350b2d16af930fcc5');
INSERT INTO blocks VALUES(310316,'04cbbb66c280fb3043cf43031476502548e11ded92f8b076220b3190a33ca0ed88faecdeb31be0f6859138cfd0b7acd750ee9632eeaa0ee66772232b397fcbd1',310316000,NULL,NULL,'32b3d37578677708f2ac871893e585f09ad850425f309ebd3137320cec1f8bfa','dc3ff817b59e6cee61c72d14474a9b47d64734846e46377936943e30a1946e0e','eb78e881d8d4c7c4603eb75abc642c947a04e8789101ead9cc61051263927f42');
INSERT INTO blocks VALUES(310317,'b44e94194c4cbc3b2c49d5232d8a2f52a09abd88c80f731ac4c36da0e02e8cdb8859db0324c9e7ae52c0c209bda99e4fbbf5d584cb50353073eb27f655d83511',310317000,NULL,NULL,'2a3a19b8439c63d57b5dab2eda2489792bbe096eb335514d79544707e5559273','ea618c5b3f674f3fa88eefdcd36be21427f5b01a99b6abc7f9c48abb7453f205','c79abbf10f53041858563f0849e291fc2eced0cb0fe6efafd4317e397853d784');
INSERT INTO blocks VALUES(310318,'aeb7f90cd47f67a38e54cf219fdf6ba2d345f8f1b1c24f0b0eec974f5568c071f55558640702d14c8e5594ec964708b2bdb0557864e3966dddc47f13501a9ef9',310318000,NULL,NULL,'41ef4d04d242da584e7e11d1e8faee4dcc7e64855cb7f218e6832a7167d001ef','c60c1e69e2aba83e59064e850e246dd891f859aee0289ba3a4254008194eda61','703784719b61714f7939ef78fa7154ef9d09f2565a1baf56b66ad78e8e7721dc');
INSERT INTO blocks VALUES(310319,'c7cfc236341db1e9ae171105bcd69f4bed9e104c677fccd496c10351aab2e2dfe4b930e552237aed674615320d33fa4dfac209aa63411ae03fb9392fbe0b7fcc',310319000,NULL,NULL,'f97f065b733e8fee8f1ea99333e28781039e0734e9ba3669ce515f18f8ddb2e0','d843c20b5ac6ac23172d8a2de206caefafca218a40877607140d02d6da9f7c4a','a60dfc5f4450b65e3e0b14343ebbbdaf012e1403e71ef4cf55c4c1c36e1b1b19');
INSERT INTO blocks VALUES(310320,'c107f8fdb811b81a405891e79ab4f409c122f706c254e161cccb95db3e2aba5f5c7e8c11b1ff055578710b0209a311a1b011b9761ffcaea53e3756ce3d994ccf',310320000,NULL,NULL,'09b031505cd0eb21b3885160d872b145006e0b62f4b1c5af42d962775c896385','a8a9fe38bbdff0eed1ce95ee80bbd49c3dca26a3e9dedfd8d51d035a5f478fd7','fc376c85f36eb00341ac238577af33ca16f4163037fa4acd8cb1e71b92cff439');
INSERT INTO blocks VALUES(310321,'75ed1256404389d1f448b33b47ce03e5e8fd7c62f1284a1ee841018937d9f20286875901aaee85775af6139d65ce8aff852702e3ff050e1552d4f53a1e265d7f',310321000,NULL,NULL,'dcf127fa38dc283add0578d197b88154e3f7bda1a5f49a61a3568278f16837b4','561fc471da66b82976e00ba138c84298e370c17ed5605f57af8c70712215bbc6','f6027e800822502f07cc64de2caf001091b05d0d622d89d7b3b0c8c0c6c479c6');
INSERT INTO blocks VALUES(310322,'aca61058dc56a84d01999d58a29ec73c0f3fe5ef815ffb02c8acb69b24bacc7a729e3fa56734d7f8ced53f8891f78cc6e411f79814cb03648eaa04cd30b9098e',310322000,NULL,NULL,'f226ddfcb7f337961c6a808c25ecae33356fd0618a86cdfeb89adbcd8772c02c','7eb4c9b9232b36c5535b93629a89bc4c4a1809153ff65997468e47d3be0354ae','889c3cb69995041f242a9e4da5303ce4c87106a8034fbc7dfbd1dfaa73deaf14');
INSERT INTO blocks VALUES(310323,'d5c93c1a33425cb40d77f511da1da7d18b4f8378cd491003054734b03ea0d82ac185d356ba05d2bdcab6cf073b8fb53ead8abda263cdd1e6f4c0ae3d2c1f2012',310323000,NULL,NULL,'46bcc12864b8c6f960fb29c0d55a1726e110976b4645a2ad3b44fd67fa499d57','ffe6d4e036e275e5d285ba53b4d90c74d1c997aaa5bb6a760f2e658038f095e5','55188aa68f9665472c441b000479167c23197937d30c41c4067aa16fceeb9ab4');
INSERT INTO blocks VALUES(310324,'629cf11346e7c18b683776a3856fe13f6059b62d646eb51a4a7716d28291b0f85834c00cb06e9e9714aa3c4cfc0ac69480b3e28a1fabc87071947dc96a3d7336',310324000,NULL,NULL,'3c91eb844b9ab773034ae44efbb4ade527c08b27c36ebcdb565550b127ec67e7','2d52e37a81de7a43b08c60cdaac9583094b02a231415b5af4cef8518e6144ad1','5cdebf96ca7afd20ddf56f1bcc326686a8cfe856c49d6470682c7cd0b44781c8');
INSERT INTO blocks VALUES(310325,'a85d6412e13acaf7f4b673c9f7b1b1ac0dd5d7db9f2b0293082bbb6e9afd5b7ccafe219d7bbac7b6080819225bf85a8e92090f256f93d2a02c50a2b397366f52',310325000,NULL,NULL,'382804948f84cbbdb8daafa47b2d44e5df3024e99530c0dd9df73d045373e9fc','286276b61bae7c54bfb8798bd9382e3cbda30caee15eb693d6f47b24437ee6cb','e366dde8a52e2e6d7aee5888cb3719f2da645518f7fdc72b36ed4c933186b3f6');
INSERT INTO blocks VALUES(310326,'8322e11f2c93306a455b7c03ed9e39d4516d22e3c23360e9cf3ee9ad88b4d3e8c2090aeaf74101e98ede9b037a63b252bf60eeda20649a6b92b4ff2723701289',310326000,NULL,NULL,'9304789811891a30684635b90edc511a3bbeb3d9f079db4a3b3f18ae2316ef8f','78f88933942670648e6e07ffb71d87b235e878206be680a4e9885b8897642428','cd602e2a503db88d2e51da7de5278704b2764cafc1533ec72a8a1243dd9e0361');
INSERT INTO blocks VALUES(310327,'b664bf99ef0dfc4305aaf124f26c8551a9e30a7919e77153e31e9ea27fee6b151388db1ab1473ed2adfb01d861ae7e2441fc40683f0fbf271ba41bb3f46dab64',310327000,NULL,NULL,'8cf48ac0eedf9f9a0fd8cd23fabc82ce3ff1224f541cde17af2301c5c115ecab','56d53b5d6297e0928d45fa54c2aedcc94fdbba558075a5a1fd0f9cced4039ece','9b0b207941b0f60924634fee419b9a7678239481eb972687de34817c5cbbaf92');
INSERT INTO blocks VALUES(310328,'e3ab8f0999cd157c21828ed63db6b223ea237afee4bdfc7f7b3a5e4e8c75309278e40be942a2e24f123304c95a176721dbc6cb9e7e8b2d07503e81f1d7a9c179',310328000,NULL,NULL,'10b597a4c8a636e7c845b531c383509100219f66480bbb8001d7c95fb7b0948c','d6185bd23c44d037984e6c7167a7b1a643eb774ffcd07d0d398ea6ff3b93271d','6cf7d6f0ef51a02aea3308803fcbda402452f204c44722925f2e3d57802e69d5');
INSERT INTO blocks VALUES(310329,'69963cf15f2fe78c41c2b9c7970bf203a201abb695cfba9f35c69288dc7b19e4f5045012cd004c47f03243fef05fc96d759b0cb82bae76af051372415f660e7e',310329000,NULL,NULL,'f3af005b4e410ef1bfa50125e1df1c6b9e6a093f2716e40db5b3adf7139c4d13','cb35856897d8454aa611b4622da14b3e7ab74a1eb15b42d714c1fd7b00deefce','8cc1760d3162bff20064ef4e4ebfc0d30c66da06e0edbccecc65d2ab944df002');
INSERT INTO blocks VALUES(310330,'b746a968e4cb45f34bd4638d6ec4fa211ee9cbf08db6fcecaa45c66910ff46c73f43b73bf038792e9311f3ba37e1557d66744c2549e3aa95544dbebe2eb726d5',310330000,NULL,NULL,'c1c66320dfa965e11055f2aab6840e9d73112b4804e9d3df72b4c9640a869692','6cb06080137ec7d04d27fc2c8bdbf00ffc5f1d88a118b6781bede9d8c9af9681','2d4dea82a6ca12dbc11815140ba06b4be5f58d17d2aed4c2258df97ee2031d82');
INSERT INTO blocks VALUES(310331,'d384a46aa6d7163491bc05d8faf83de0fb77c8fd5258f5e31a25c8d798344dce82274998b0696d71a062854fd1fb12afac38f3e53ba2c65ab15834998478419f',310331000,NULL,NULL,'e1b4fb775bc25a8b127372259ce8ec350de454c3804ada9941ae0ee1d8373bdf','12f7b7eac900d55f64c442b4a7ecfefc24dc4e31d8d124befc943b14f200f39d','9be6984c7a627d8b07a3adc330d08b94117c6c312638851356920315f1946af8');
INSERT INTO blocks VALUES(310332,'260d20c3df6ebc9f43279fc0e67ca125b56111870e24366018d3917e2ef9f3301a14506edb8503d12e5f149802a26cf4faa279ed967208c0c7e87fa5b10948ab',310332000,NULL,NULL,'9e7275f9676c02b158200cb06b6b3db0813a8b0f9fb7252665e0f84fce50554b','1abe13c8b9e8e1c5bce8a1dd5c8551874bdc6bab7334f72c46bba750cd11b80b','4e35a7883aed8884719a1ef7904b6e7a92702b8ea21510d1795e4972f096170a');
INSERT INTO blocks VALUES(310333,'7e32479c3a014b1ff8531f8184a88b172bafc495fffa7ab00b3de68c6d93bd58389ea3d2ec185a1e12d79ce8f9e2fb15c46041eed58514566827466913b7faf2',310333000,NULL,NULL,'4ce1f3d01cc6861041bd5be38682925bed4dfa544fc85eca7ee4c536de74b12a','6c35a2bb825ad8bb8587b5a18d245dead4dbf41d6c002a7750298f95c888e2df','2a4c3c747c020c59333aae33e964d0b4321ca3df85261ab8a7098ca6fb5f8a69');
INSERT INTO blocks VALUES(310334,'c142261b2b8d7991e382268b545f65bf5cdc0894fa205b53c5db06f0120930b8edd76cbe4cb0f4a2209daba3877d1d5803c2f8a8a48b53e0835cee2e840a78d6',310334000,NULL,NULL,'6c3f3b7d691f610356452a43715db49f7e41cf3b1e8365abe7563d57ed347af6','13d9bf520c0e98826c0cab24762058f4fbac8b126566f0f1aed3ea63f40b753c','9be1d713a2df26a8985047c2097152008546034ecd09835ce51fdeeac1788beb');
INSERT INTO blocks VALUES(310335,'7dbb2ae1f0cbba1408f32b46a7815776ad7d03b41dd81be92bca10df442a97f9a0dd68044d30bdaba363e3b0404ed2d17fafdb733ea49a5838980f8d9b3a8083',310335000,NULL,NULL,'83600789523495cdac6706a481e2dbcd1a56a58171917f97d88bb0cd81fe695f','470de360f54aac7c84ce3df7078fb94c1f65c5d04731310bfd771102a6de2f8a','f10cd5513625a690d30f60f424139290b5b97edb2c278e1c91fb8ee71d8566b9');
INSERT INTO blocks VALUES(310336,'d911d0bfba2d67c5642f7f178a11b48e38450f623d5eb6d7141396a61b16df08ec1904fd1c90ef869b11e5949b1b7140f97927523b8f4b3dad3bf5ad873eb74e',310336000,NULL,NULL,'7e41a6d9a1565af5053c2fc4285144fc4f4c0c9ebe6e34e77d300b1fb82a8188','6e3cf8d0a07e1b08482d7feaa49a711c4976b370bfffff3073ec42e3d679fb56','063decf34bab6345ae30b08d220efbc51a132f490dfcd1ce6ca1664d50dd4407');
INSERT INTO blocks VALUES(310337,'364654dc81278c0924a693cea958e57a39dc62d998d4c954ef104deb7928d82ef87e39e3ace43f19d6781486b2968e2edefecdddab42e40166cd3cf79444e6d9',310337000,NULL,NULL,'d3bb0fa088463f81de8910843fd4dd1f35738a6c7868d36586c95e5a358bff7a','261050cd49259263f084dc7109f360d5fe84e768ec51d4e345fe758de1e41303','7710570e5d11908d0dd6a8f67d29dd708ef5cd53caf9a1b67bab154c7438f31a');
INSERT INTO blocks VALUES(310338,'46bd830f13fd29e0cb8b06b4f0f2f54ff732f84dabda71def256133400c0b5910383634d66033673385b6c46bcfb3760251cb5e23d376d339639d1ecdb492f28',310338000,NULL,NULL,'54f47078effb357fc12d74f8c50abecb0b18c3b6f870e98ebd006f771cf423dd','0556b2b46ed1ea3d33cb61afeaac61951c1ddd96747146b6940d33bd6b33185f','066fb17204211d496520d251cd75f7c5993181970d5d983a09430912c46df066');
INSERT INTO blocks VALUES(310339,'3edeff265209629eea69034cd577f087edd41c0f539a7c4f6a9ff46ef029420e5fe7da23e6e0b8938dee3f29335cad78f158d1f6ad23d4c72f7032ed99ad047f',310339000,NULL,NULL,'ef3ec8d6b6de55aaf7a71820b7758942506b4d1517028f01c6cc48bc79ebffab','65f125e587658ab35d404d2f095b7fcc4f0dd00065f42925b6d69504b503eb02','5431ba5021e060921b2ef9a2711fad0f8fa2e89b0afc3bc58752a86d280f60d1');
INSERT INTO blocks VALUES(310340,'3c71c95332c52d5c9ce2c097fd8a61639827320d899ee9dddcf9f5a7d420c73fc920a639e858ed4a3bdcf778f10978eaa3b4d6ba7e4825520c4af8da026cfa51',310340000,NULL,NULL,'f0ec836af61aa31b4c2dd1c1125769954fcfe684456e44cf75e63ce16677ff38','5586c1a2d0b27fc8be021a707dd6fe58361da06e57044dabfb688332462b39fa','f09dc16d0f6ca38c69891c200019ea3c4060566982896f500f41a7a84037e331');
INSERT INTO blocks VALUES(310341,'ada94808b0a11f385f968331b6917b1afd7d34bf30ca89e3ecb23e0352df87afe5f60467146afca1077b13fe85020ee3734277f7df8681fb9c774cc6882d2bb0',310341000,NULL,NULL,'693c0ba212e3c11c56a548aca5fdab6b3696b0ea563126b7faeec4ac239c2b33','4680a63050c5db0478f9cc207924d966c348403f58e0bcebda210e2e22687ad1','fa02df1281f3c4eaafa81b131673c53923dfd9ccba49d71ad5dcdea06e98a4bf');
INSERT INTO blocks VALUES(310342,'833c612be8daa3b6e7d9d73b9d9297916a89f358d6f4afa82697e66ba54fed08a4a2fd154919bf5541a89d18d0dac651f86f04e889a44ae9517e6d7dd763ab80',310342000,NULL,NULL,'9046770afa96e961ffd7097d93614bfdddd32e6de318966567dbc2cf25ee70a2','c95fca02980c69ad94a27b803d5f79257ef15b248c7fd2c7ed7e57107ff17256','e9c063f40581df5a9ae3af288380ae22318795a38194c61eaac0c5395575a17e');
INSERT INTO blocks VALUES(310343,'1208824c70f96ddf20e9b71a941817095224228cbb455c44acd57ada445c407632a764bb2101c732faf95d7feab818bcce1c52b58e300e6112f54e20841ff0ef',310343000,NULL,NULL,'c89e5ac3f607b3ab5b56e96280454f604bac02685dfcdc59dfb965fec30e3d90','62eec676f53fb97bd266ec2da031435c289c5ce829964268a55abd312a2681c8','a8fe2a6ae22c426b1f446604e84b01a70c68e79834737534abbd131f9a1f4fd2');
INSERT INTO blocks VALUES(310344,'19cb4aa3aae81fb95f3239ef756551b2828163bc6072cb866826914a71cd9ec17ca8a9802d99e4f3c17ae7407426eb92a0c91440905bc98522ef0eb04a2ed117',310344000,NULL,NULL,'89bd57ea20751bef74520fdfba10efeadd0619ac963001c86a1a4d65b265cc1a','1c3e853b776cee89377a4e395d1b00dc922ba98f43c752627f8e51b5c90484d1','4565b4d762a12c18c711ab8d3158cd1d7171704689d33311aae576d2d0e1cd4d');
INSERT INTO blocks VALUES(310345,'47ad8225454f301c2c8321674c74da1f6e4a9de85e62c58154b12e19242119933fdbc0508d273afa328be196d338b8c49c70346e8df9b16ecb1f41b420370e54',310345000,NULL,NULL,'6343d3c5cf86648bf1e454c81fb377c4c26e5f2a1f3df5be357b7ea736cee8b0','ad07673df96bafc385ad28360af4734263fefdae5415899217ee2e6ac21c851f','f81e4291fa66baa83a8beb2b405d36d27ad8fef38ce521127b8296605914b0d4');
INSERT INTO blocks VALUES(310346,'5e8941c8d243d0de80626f1c45d7bdc8aa9fb785f9befb89b650f391ba377bed233041eba3149a1aa4803199e6113b52ab77484991e59c7bc4861a148f1cf757',310346000,NULL,NULL,'a68d5a7e0611c0a85dc3e01454072d7a8e3a2f5f09a42922267cd52ddafd07c4','4e79f58a4cff0fcc4f2b8a572be7ab63af79aeb26f76623bbfc0d85f8473d896','7e4f49e12e50ad36e56d2e8d97baa751cbd568b61017fc261339a7b7dfbf4e8d');
INSERT INTO blocks VALUES(310347,'24b6e5a724028b8a70724e34a1481c7015f0868acd440b495e1c9c82c794d9800c92ff333e5fb95cbd2eba89046ad3e4d88ee4076f76dc6c88d173699d1e24c1',310347000,NULL,NULL,'8cb8a30bda1c478620459cb80d13fb0cd7d3e006ed691e5ca83a054bbe8b9739','d6c537e8856f3080246cfee960f4ce6f90574555ecb86c12cfb47c72020e444a','3268c85bd425191cd3a04a07b97739ba05419248cb17710db6fb1f4bae0f77e4');
INSERT INTO blocks VALUES(310348,'9e08f4bc97dd6b16dd5c3da853e32f669015248dc1e4648e8b85bdd548692de814f409a44830a70b9eebe66650b424b900f722cea1043b0cd2ba99373d7181f5',310348000,NULL,NULL,'6a8fffa25469cffdf5794e024b62c0887fb62b894bf33ed057c75a712220ccd7','29f3511b2de1c036b980df38c415aee64b1ac6e61d6a5d7c47be8cde2d949fe4','994b45e868b8d9d2b37f6645004fb3fcb5e98af71f9b6bc095f5e0a2c01132cc');
INSERT INTO blocks VALUES(310349,'448b9ed8b0a0dd53b3c0b8604e87660339c5a0a731eeb4e80e35823890a7b90a2e273292fdfc2e83101079afa51931a21c643b3d7254c00eabd1142e3cd29631',310349000,NULL,NULL,'f807bec9fe03ac49a338816880e83342db4dbdbc8aaf670caaaaa8d62828ff5c','5c2f521285bc416616d2dff3e0c3639a547292d7efa32ec4a91e2e76ea5694db','6be8cc3225c267550296535fc726ccaafb94e25fef24afe478b410be5f3a410a');
INSERT INTO blocks VALUES(310350,'9f226e675f14d9b6785e7414ba517a9d7771788a31622caa87331aafe444e8792b4f63767e2175b1e32be8cd6efe8060c4182fd08f9a7adb149b15f18e07ec1b',310350000,NULL,NULL,'54f5c0815e30408b834c4e48923937bf4512540c2b7047166ebaaf42f246b377','07f96a80a178b68faa5cea2a25827ef0737c311dd7512cad92c1e82d5ecf82fc','f411f4cce4dd85d77546d6f9704eb8e17d00d023c2c4c0d4b57985554a28176f');
INSERT INTO blocks VALUES(310351,'7317ea5af2ca4c8fdf5ef475c806a5304e852cd3569f816eac95bc8376673cfe3cb2afb701ad27fcd14e4dd448fb82697e48ceb8b3534d62b5a94b636b37653f',310351000,NULL,NULL,'a9cb273864fe735f5e3264cb6e50142225b7e7ff2e1d35b8da1410860febeacc','1af4ccba49186c873fbc14b6ef41b6a97d1e812021c9a0615d9516740c5d1726','20067625eeaacf7b6a652766b19ec451c37ed276d1ebf5a756260f8e69919c2f');
INSERT INTO blocks VALUES(310352,'dfc4070624c84471fc34914f4872491490f3c2a64e65de043d0cd1aba28a3deab42dde9a9df8ce1aa134c5c2f17f03ad25f8c876eb8a98e576e8f6f230adc1ed',310352000,NULL,NULL,'247770ee363f17202a86f82800eb69980fea529b38859ff361ae8dd4d84dcf13','22ea30ec6ff6b4ef652dde05f3cf873533ac4e4a43bce64e9adf5b86d1ef56be','7c7c6b790b5ae77a626ec26e7b3dbc2b22cee4024f664ba979828ecbd93cea4d');
INSERT INTO blocks VALUES(310353,'5313469980e89dfbe92fd25f59bd9bad29ab5891d25b9cc35addc939979865e059a8746d97db3ab028cf0438ae4cd0bb78d68f1c9cf0e49fb979bace604be536',310353000,NULL,NULL,'c423be2a59a0828404ee1c50775b97fb4d688443d3a767a6ff3feae25002b175','74bb5aa5c6f454d2d8805f35fffcdb947ff0783369a4d21acfdefee3b9ebaf7e','b697c27023bb74817a67bad9ccdb99b3ccba6e50633dead059b9bfedb1f153c1');
INSERT INTO blocks VALUES(310354,'c226d792f6687bb7024364b57f526c531337ad302b0e64dba5eed4406a197f61fa1ac86b5750d82363623f41c10d73ce4e68efe32a95026b17467b69a384ad5c',310354000,NULL,NULL,'84045437802e63a041f43444caf0ac43c7fc99605709e8545890d150db0874b9','7c2cbad5034a2ee4d4c3ce5ed20ab445a1da49403122c67796462f01bdbf61a7','dcc3d5c2c95adf5dd6077ecadf8eac79167993585bd352d0214040c28622f3ab');
INSERT INTO blocks VALUES(310355,'47d20eaeeaaa017276b343a2410e0219882f00d3f37a2cde895ed6533c76e270b5d1baed267bed633341a9f151ea1926b11c12c98e8b4f3ffb82855fed4587e8',310355000,NULL,NULL,'cdab7e69db1fe0fe2ca254a699959bd55557b945091f667f1402c09e49d09ba6','5c48c2e70536ffd5cdfa00cb02293b1173ab4b591ce1ccb917c56788f48c6b64','8f33f72933efcec3538f302e38c4344c1440d37c208f2bdbf3513145d6653e05');
INSERT INTO blocks VALUES(310356,'ec372a0c5286fd32359a4b230b2591c5a042a6b8198f50e48a9f7cbee29a94133c63e998c9cbd761a16e310c61cff3d7d6c3fdb31c0017952d9c9f0e0b227634',310356000,NULL,NULL,'f9429664e122bb17705c5ec6442757d7d2cfefb0a32f2bbd62241fd1aa8ab7b8','4b72437b720289bbdc5c17c11e51c912bcdfa5842e322dbcd64b9a7e3c6de9a5','0bc8a8b3a487318f6a5524cdddfebf224c8fbef0bb7f9d1cfae4ad2d612cb14c');
INSERT INTO blocks VALUES(310357,'77521e4246cef326f9225905a2f0ec39d9ca03010ffab5e2069d09fdd429bb46397434401ca205a3dd1fd2551f7b51509e4175a4ec99f050a23fae87aee444db',310357000,NULL,NULL,'3f365e0bae6a611f0046285a25b11d94b175fe3033cfedb43d6477bad6b4bd98','2729ad5e8b5c8284796490dfbdb1d9a91c1befa748961ee8fef41e078781b551','63ed9500612db0a5c19e84f65581e340f11a638d6d6c5b0216f6f71cc04b1163');
INSERT INTO blocks VALUES(310358,'11cf33c1a299fb202ee558810c60435613199de51d6ee5a0bd950df50a2d2aeb2b56c338f06f53cb242ab71633f783f3f77a2485cc8d0bb0dd25e213e3b19237',310358000,NULL,NULL,'f48de23ac743aa1cd41433cd0a0a52a56e8a70552bed81f14db39f4bcabe71f9','0c0d77b86c2f488d2eb072fc27808303892d202474166969751b8c1a41a106c7','918072c43fc9043930d996e5bc2a85662a48b5b7c07a33e371b3fc2b2c916359');
INSERT INTO blocks VALUES(310359,'c2f314e6b8bfe22b3fc958f311a3ad60bd65973ff0afd65aff5b4656b112601642db654c8e520ca7ea9d020a1321045e0366ace5475aeda8a09ac2c1f7e46062',310359000,NULL,NULL,'63fd5945481666913e889762ade74f9676034083063a5fdb2207f08be086f6d3','9a5a385f4aa8317d2f545881a3ebb959d22580bf151f16c1d9672d169470f1dc','3055c456769ce78ae3a52b3105b96784c15d4abb64bb52a97a3a881f6f622000');
INSERT INTO blocks VALUES(310360,'bda2c508410f604760a474c0829ddebd39f7e1a3bf642483d0850dd66fa3142a8cbbf6e6d1812808b07edf4f179709fd321b0967b88830e2ba3f474bd5d04867',310360000,NULL,NULL,'6150b03b0ece1adf25fbc740fddddd4a7d005f0803436f2fe898c137f30c222c','f742e68c21b492546dccff6bb3a91fc3f84e10ac30938a33cd08b9c4141b88a1','7c6afac17056e8bacaeca8d5090d8f7706767c7e25adad04eebf2ade3a40670b');
INSERT INTO blocks VALUES(310361,'0e8aa5e61551f54429774c27dda7665ac746e04ffad7ea7fc30d0c10eb914325c98fa6b09398d9ac0137862787182fb1f8f45d2e840ecd7ec53634ad8c6afa37',310361000,NULL,NULL,'df0538b77b7032009b0e783dd8634a2ae54a700566556e63d2f1bb030d3d457d','7c05a1233aa9bfa48ab33aedbd96be0d85c1514f2970084d1eb3a769131ec6ca','9cb7e545a3614b3be9bda9ded8767309d4df4221253940ad8aa85dbcce95fe86');
INSERT INTO blocks VALUES(310362,'4cccd2754c6eaade8dd5a60a0b1a0a39d80e5348cbff18dea4e2b66ab5c20af9c59a7b737d7ee7ac3b01e0c94e18f797ed9976ed0aa97b3a312f345a02a05b9b',310362000,NULL,NULL,'f279120b7176bb678d41226151565081f4d1b8e549ffffbb1a1ca84951e1ae26','a28086946c03b3946f768c0c6f971e172f7f63da21754777c49315a3883a7105','9d2281391d30c6a8c94082a400ec1d38c9ed2330346e8c7e475b2fff8994a452');
INSERT INTO blocks VALUES(310363,'12389822986bf132977ffb72385c92c151bc3e8655b89e33126ffad603486885c7d6395e34bc49f75fd8b6f91994c4af72124fb0ade2b7cf578848bae9767bb6',310363000,NULL,NULL,'0e97b9fe29846a62d0df5efc04f6c70bbc45ce65e69d1cb43a7dcaf18ce70923','07d4b0ef34864665ad0d6732f72cdd0db8d592224a5e24cc48453e43e661056a','564e7d51ed3b8b679267b1e8897853687a827f57879af79d9654e5635db6f3a6');
INSERT INTO blocks VALUES(310364,'7edbf5c584ea6177755aa9440b6c2c2f3b651f089fff837a61f853813343c7c7b585eb49f0131e2ed98ffd64a41f0df345d8a3e814070f5cf02dab28b38bacc1',310364000,NULL,NULL,'2b3c10af6f49631dec98e72a51bbeb50cbb79f9238bbd0aa5b70087578196ab7','f65559961b5a2be3190891df78d336c57802d459755f04aba0a6558ab65b8cb7','b0d0a3860cf6037f0808342cb3b4b8c059c3e131406e5f64d10fee9df22a4a67');
INSERT INTO blocks VALUES(310365,'240660b1ade55a1d5f64e0e9d4f14c751cd2aba9afa64877b03c192bb4a487e91e009180f1e904302adafadb196377114de3fa3b9f207efdcd0c279118e60dfa',310365000,NULL,NULL,'c9b0ccedcd178bae159aa3f4386829fda56c15cdc94141d8a1dbd88057157201','e130507306e8d10c3e21b5d5f9ffeb6ee2ce010d89ceca474f417fe15663979a','76c3918ce36068f23e30bba6c3e8dbc4c9bbee9a5e95cf3cb1636fc3012bcaa3');
INSERT INTO blocks VALUES(310366,'499cdd62e3fef786e15aa7c87b27b2325c98a845c1b31e41c4246c98280be4202b05d41f3463bd972ba855da9f05c7a2a308c3a614b6d088a5ca40b27e50e3ab',310366000,NULL,NULL,'668de8c7cc552d61afab359c982b95d22c36bfcb3d6e9c4fd7ea771e7c8a6f58','69df8a75109bc7d54fa57298b3b3d7ee0ce60518f25ba90038ce2408bd637246','d1008cb8f1b65d0fc36f97e6ead1dc1b6ac7a8236155ce076053695650707ac4');
INSERT INTO blocks VALUES(310367,'78b3a4e982e90a6e977e7d6044c6de1ae6e5c7a4116b912fd2923006380767e842c73dfa45f63144fc3e368b9979c7dcf71e34db2438fb18126eeaa71495baaf',310367000,NULL,NULL,'86de85c357c4f1471dbfbf4e4f5382cfa2bcdb630ba1d3a4605594e7ef1ed9aa','41d9f84d9bffb1c6c12229a9e1a38f7bd5494acd5958fff1d2d823ae2c27cacf','7269a9e910b7e915a78c4970c5d7477971a1094e7790975e713c253b2ec4f653');
INSERT INTO blocks VALUES(310368,'6d09a2f66be5a338d44a8905a5eee901d359f6c8a0fa4b8a2369e0db591fa87b7920b99c438310657a40c40f3cf8d5f04ade22c935b78f65ce3bd06a7675443a',310368000,NULL,NULL,'42538f8d70a984737503c085873c1d9b01af33ae5d6eef06e83bea29a420af56','b35ea6fa234067d9d68856228fa6eeca5b083f8315196f97da83c9cc7af80827','2ef34ef7fefa7c566528db3f1ea5ac7405be64b5a04362ae3ce620461e988277');
INSERT INTO blocks VALUES(310369,'d0d27d889910164f21902561ccbcb5e5b1e585a98b2a45f773a6c63249c7708eda6c755aaf2733245d0d388abde416485f7cfc028358258c65b07756831133d8',310369000,NULL,NULL,'beccad01013cde27896c559c5cfbafc5d1f8ab5db962ff105672cb22f6b47b81','4c1b0d6593edcce999c2e49f97f00ad29549bbb433911735a47105efc3086ef3','90362c5516793e306d2833bbe8fd3cf8f87b4515bee0f12dea15f5f25da6e0b4');
INSERT INTO blocks VALUES(310370,'33ceb941d59a7c205b7eba6c6f66bfce2beaba82f919e2917805e0ef41187095b21d7f44f30ed35c410663de6b2424be9bdd061be9435a79f163876364d51d43',310370000,NULL,NULL,'5fb457661e43905cb27562d27a13c15a7b555d2951cd1c473e9ec2cf9041c1d2','11c7659261292c0770df901a45a8ed467367235c412b473837ff5de96f251d2f','db6f6ace7b057c124ea424bee7f95a4f6902c8ba699cf69cc6e3859014ec8c6d');
INSERT INTO blocks VALUES(310371,'74dbadcf2a24eff2d8f91b2e897d8a3cb9917dfb0b91ee9e1f998cb5516e8b53acf934a6629d71953f2adeda6162d62c66321b513539d355ccd51c3b574f77aa',310371000,NULL,NULL,'25ba26c48090e7e72af790ee962c67ae75e09851658a88e18efacdedee340d30','1c80e8ad9e2080e8f33c70e207dca107cbaaef3e1004ee3b39d7bd8b4b079eb5','1655a18b41a21e9ed0b7479cf5e276854fb125fce1626bae0aff3ae5043baf43');
INSERT INTO blocks VALUES(310372,'96f13cdece65d8f565b8da23404826730a46f2c1dfc80dc0a91c90e151538a274994efa7748572ce780eadf6494b6be935b84bad037b6f6c8e3e4dda7162d22d',310372000,NULL,NULL,'92859bc8c834c0a3f44366df3ff368b11f29545c53d0f01f9f5be28d58640952','f8448df149fc3fd90cb6302242923e6a1fc4504c559573df50fea18952362d78','22aa5c52c0eafc9e7995bfbf8363cc1a6fde2e7b17dbae0df6ab68fa9e516dac');
INSERT INTO blocks VALUES(310373,'a217d3e988ccd8860da329ef66cac433b4d4a2ad2f4e142a5c181c2f413f6a7c9fe66296deaa6dade5afc5b450c9f4ab885f03632691f4a7de3dadfb5d294cbf',310373000,NULL,NULL,'a455dbf7278bd131c1a77bc25057e1aa9564ed14bdf7667996965e19395addb8','cc5ba70b254fc7c89591e4abd2c51f4be3639d1bcf5fb2679ad7bd979d8bea7c','7d2683fd756cc7a7305d04211f1cd50f29efef1fce7cfc79c6a86daea4c6495c');
INSERT INTO blocks VALUES(310374,'b9758db7828f0545cadde8e918d2e433810d8b1320d8f955b370dc81be6c1064eda35126895a5ebc47c153b5416b6eaa6f24e670d7b4f9d0f4ad8022393db3e7',310374000,NULL,NULL,'d83caa09dbea41f8cf6d0214c48a9f9202403dce15c0913f5f2c450998f6e84c','73af2f74ae4848838a445ed3645e14925fea1bfa4b1c8d1254e5c3a78e9191c8','f30a8fc9be6d46cd4245ee014015e606a7eb57cef8517cd129bd66df8635118b');
INSERT INTO blocks VALUES(310375,'3fe27307afbf4fc82b05404d5a6e22fbc18a6572c65b45bd302630312e0f645003efc695e15b8422a05ed551e56ba1485bfc6901db8b6bbf067832cae2f1a2af',310375000,NULL,NULL,'4d2906416e41e1cebeb3ab7b3d685a58da2c5b5cdbd7ede2524bc55a59418a2e','d5bb508ea67e253dcb7482516a216a97bd13c67317b497faaa0a7af5b6fe51e0','f4305860c1814ab39d8ad52abccfcafa1f469e9cb6bd1e5812ad3769ac14cf9f');
INSERT INTO blocks VALUES(310376,'d913919e375a0eb085b0adf68fa926f8bda220a4237259a95da4bcf9a67c7aebe1e09ae23874d4cd3463a2248677d46ed0deb5127d328a2ecdc99b21dbf95e6e',310376000,NULL,NULL,'5b6c2099ddc7f2002b7771e654980fd8dc57cb245c6013d78734a8eca4ed27d2','ecb6da94eb6cb2d8b651ffd278a89fbc5273d8125a2e4c7a13b517090aabe368','4192a08c280ddcbc049742e48283ba5c786dee592a82a319dc58de7d69cad052');
INSERT INTO blocks VALUES(310377,'701c2380f56df14a7f6c7133f3e094b23c3ff653bd2adc6265577fe0c3493b051a93fbea95235d29dff8b66a9dd6851e75c022d3f02b879b84771604091e7e37',310377000,NULL,NULL,'6a8ac8738cad94386d9abfede016309b1e9c2790481ca61dbb807808f90084e3','4e8647bb99246268d934beccc60f8a399b8ee6ed38f135b700bf61799b04fd4f','1c29739669ef0d219a0953395a987a4cb17345a754a1460fcc0051d0e24cb3ca');
INSERT INTO blocks VALUES(310378,'d7fece17c659c0ec86f31fedbd029944708556d47bcdf9913193bfd90906edba5a925bcc8b03f4df67310f778a80167c2ce8ba8fb7959d3af6d17f5bff608e27',310378000,NULL,NULL,'f86f2eeaae4948d1fa4dde64829d4b53c9090b088789dd2c681ba817bac9edd0','99e418c3fdb00814232007033568228de8077191268d3d2233d34f3cc178980b','88e6958941738a0423d604ea5d8ecf09b1c28f7a360e7a44722e542948ce592f');
INSERT INTO blocks VALUES(310379,'e35a25ecb6f50f9f4009ebdd87f9e76f40fbab78c5417aa0a11ac765bb4adb614eea926ff7558cc5fb6194c075dfd95eaf2ee35f543dce4ccf72273a016c1084',310379000,NULL,NULL,'3daf019c0162f13caa02bede117c16c7864e62a43b8477da925272285754c007','c609f40cdaa9b3697895862ef4675c62c3dee5df24a575cde8cf16447e3ce4fa','8cbcf000ad1cb50d1403e4f26ba6cf942ff63f773980d6174b2d5b3bb5b482cd');
INSERT INTO blocks VALUES(310380,'3e1a363381091400bb31dffe611e251598a7c7d0c5f8c14a06c8487b2cc0cc31a111112c3fabf2e23c705425f531cc91f21ff7baf4e7e015ce5ad884bc3556ff',310380000,NULL,NULL,'bd352fc23ad181821e497f4dd2564491b0d335088317bde324598466eb5ca665','f5b80329c9c005e3ba89264b9eec914e0865b2cc77694f6b103d02f544d355eb','54576181698bec32786bd57ca015a9f12ad30f03415b9bde3c738d7647b14852');
INSERT INTO blocks VALUES(310381,'7c09b5350b292b8ec7a9492e50647a0fac1a1c9daaaf76c7c2f588d17058333598422a6b09f6b43e65ce1c274741c970e76f2367cd7341f31fe5df3aea6fffee',310381000,NULL,NULL,'badc6983fabb97a35a1c7648c90027f939a640482f763f7cf6d0b42ebdfd59e7','e4613ac525fa2b45b3479d8f878e6e4856876385fd5eee0ff1e8b2f010fdbc03','845497620c2e28df15aa16332616830fb41d2cb944710906972760d6e0667de5');
INSERT INTO blocks VALUES(310382,'c0f7e693943d7ef303f8a8f0b82b42c05d16bac9a51ee748d7356fe2495756f4c8b83fe9848ed65d6063d79ba5180c9a0635e9dd1e09f2978c7015d688a71bb0',310382000,NULL,NULL,'fcabf3cc20e0733f2da9e0d7f532791df40e40739a9bc01a5a279fd7b038ece7','a81ef0b9cc53e5af3011032ee92a0389e2b117fef9fc80d5839eb0dbd2e20353','0be68fcc81727f962de37e0ba4ca2fedd2998b626017126a405c0b6a97a4a310');
INSERT INTO blocks VALUES(310383,'024f27890e9c28b78b0a9f57c36057f9a3a6878d7d1312b71d0e6dd97b2acba0c171ec3da6da1a7564b182764000f4ce0e1368abd82796730f5fab763897558b',310383000,NULL,NULL,'c409b954d253a89290e3647d9800cd1bbbf00d9ae57353cfb8adb37415cd1d6d','7fcc1c3f370698241b3e0b2dfb96655e66dc065347a4240c7ef4f514d9e0839a','fe9b4cfac5140bb1faf4a97e07646834ce6851b8f03d30fdc06b0e8ac98f9ce4');
INSERT INTO blocks VALUES(310384,'ef45b046e85b9aa1ae2e5108421d2f77cd2a167d45c8239307666e23b00042f09057c840be9f0802c4a1971fc6d33dc072e8fdd552802859902c94ba9a0616f7',310384000,NULL,NULL,'8a7c5c66cebc831a80d50038a51a294e350fcdac1cbc710d623d7bac987051a1','8a0ad8bc1302a241807c6893d38172c7da6a4605b45e8d4c46d5912d3baf794c','4d0d2c7cec7e5172faf4cb1c6f932326ff87caff06e75a05f34067bb2c148cd5');
INSERT INTO blocks VALUES(310385,'e6e3f4b7435f96e5972f807fbcbdef20e46045572a235c1a653c97d33a88fc31e0169e491070619cfcf98e28614148f6b880481535710829131251018343f477',310385000,NULL,NULL,'bf0b603f6f9e206155cb9172b9f499745decb4cb9b9a752f420f9f0859cf18fa','69d632143f08eb662cd43dde5be7477e8b1c809348d7fe58e7418fccbd8fe671','68b01d5c69511acef01e205d14c14f79a161db78ff8e84ced81da6e10579d015');
INSERT INTO blocks VALUES(310386,'f1bcfb020a9b17722d2a304089806f267ee67561f5c33f8c932d0d2430faedcd7504d98db47e5f996834fac46935c47bbdba8eadf178d52ba8d5c828c08aa000',310386000,NULL,NULL,'7517290ee0e6074e43b5e924bc267ecd667b6470ea55d9fb78631a28ce648fbe','4759f74d83e2f86da764e010460dd4c8a7e4254e641b36e54c0713917bb15b9c','1a763bc4367c937a00220294d6a8858d5197dfde90b0887340309aad4abc2d27');
INSERT INTO blocks VALUES(310387,'97324080fe0f8ab79d717f3348bdd82add208d261f2d04e78a43818122d08ae8d2eca18b16b26e9b5862c0272beb751a62898048caab736438408c3fce109fe7',310387000,NULL,NULL,'d445d0248b0895490c991736c931da3fedf21f7d966a2817a66ffb3603143d8a','fe2c3026007c4825961838788123eafff5238be2a6dcdba6173ecc62a7f67828','709adb4393ea01152ebf408a361eb27a3fceaf177936d33abe075378d9e7e0d9');
INSERT INTO blocks VALUES(310388,'bafb9f69a8253e308e91876d280a71ada97cd903ca04f14adbc32163d166632a19c3fb3773c9b126faad96b21675ea8c216ab7930146a532da10269286b3f675',310388000,NULL,NULL,'7c7e381de026372f3d96e4fd2478e157bdd75e3cc42bf11335be148febb77ccc','de573febc049003c58964d6c9d65463acfc30e427d0e0d1e3b6737c03cb3c909','54a6daf616456880db5e92e98df8472c5621580e8d69be55c3e86a5e6d49f6c7');
INSERT INTO blocks VALUES(310389,'48b9a51e1dadc6af9cbd9ef618681c97471cabe25207b174f93a749b3d42db15446ca78b489a92eda8596bd5a237fe2765aa0e747bd062714b0e84b5d9fef4ee',310389000,NULL,NULL,'6cf12f17775a06ac5436fa0a27a5fb81f905d64625f23d6ee68ad71d4c58ca55','7d91caaaac44779e505987b102b02db0f81762fd5cdd3e0567b91cd132cb07c6','b01dabca0313e80cabfb1a178062e70ed47fd1fb6239e8499e160bc59d1770e6');
INSERT INTO blocks VALUES(310390,'a4c7793a1ec95d4bdef82e29bb92d1068d46bf9fc542c67b0e8eab9e7795fdb0041d38f6c14517f2dd8ef0f1afcb51658215e08fc8a4261cc3a8f0ebccba7f28',310390000,NULL,NULL,'4d748830e701841a03abbc767c52c103ac74e35071b1ab3a11cde71b258fb1c5','d34c674b9dd62b4321acedccd83bf84f10c38457da234d343f03bac74d37903e','1cc9709572deb43483a9dfce9ee47444ec7b0f4c9a5881f0edec81af8a3c5296');
INSERT INTO blocks VALUES(310391,'0cdc2a768515be5cec8f1ac0bf90f1cbe328f112654363b53adc4a3c71d4ef4a24fe76e911a38327ce9476ff1739d3a0cfeb87650878eb50d7756a335dcbc0f1',310391000,NULL,NULL,'2578a29ebc72ff46d051ed313137ba8db656228f99aba9c2594881aecf6c6748','4c3a7b5c3614cf29d4c65286229e1918b9f6c0f06bde7a6537be80c6bf4a9f02','e5066da65559c4253b43e6aabbb2ca73266441238ad7c46a61b79a8c1f3f3ab4');
INSERT INTO blocks VALUES(310392,'8d3026550633fb3c192d35fe9eb34a336a375b702d24814232f5fd9a306aca9c5c88b62844eb6de4ed9070b938ef959d7c06c5b57e09c1028a130de8a66b73d0',310392000,NULL,NULL,'20d92acfffc3fec918f8a4b3cc2397712887900e6fbf5d268ad00fc1fd1419b8','f780a0f8be17d1a20df0177ca2e5c1f776369f50d1fb8945e3a7890064c3f588','826ce1666fdcdf385f7a04782fb864ea74e047f747ea0c08f2ea652fb28fbea0');
INSERT INTO blocks VALUES(310393,'ce1565e85d22327c9167ebe6340ff3455dfbe588df356612bcf064083ad551ada2013ff7855f738d50d788338e8fae7beb9be34a87496e2e113084b16cdd3a60',310393000,NULL,NULL,'e91ac8337f22aa9d0215a8b4d951d793e145fef0ac1368b01b2e50a7e1f694d5','ee0994a73e1843db47fa22984cbf9c18316b891beb5d6eb868a9103f761e11e4','7c62233dda097741a749b569e34a212ef0ccf92d3ac26d7214f29a470db47b00');
INSERT INTO blocks VALUES(310394,'ecfcdafd1924ac35b2a8a2cd794d4a7118107f8481c3efc2c3128eea5b5016f16c19354323fe2830b49972b947156199319a440f0fe1d2646cc9d2be6d160e32',310394000,NULL,NULL,'900057ba338daf0a628de8d31f3ef8433c32181b49c96b12a9de396b5107c0fd','9878428a713785784c55549d2373fd8060ebdf09230951d33b194ea5dad5cd58','efa5244b2274737f3cebdd721bd014d68480061c3378fc2b253c341e831175ec');
INSERT INTO blocks VALUES(310395,'49f82bb1b6373d11807a41b870bf863d023b02aa9290fa89af227a2ecd7f68692753260cd95fdbfc3a215886f72a59433c48b98e0e63c67072e7978128b8ed60',310395000,NULL,NULL,'305ef8a186f7498d6c576d03808e0b1b875e32f42a252e96a87c9ef7030f78d6','775723119c32e3e6ddc5a6b7fee3a86b091e3cd4727b1af2f7623c169deae33d','9cca4aacd81ad1c67845b4ebf6fa42760c78c738622ac98e1758ffec110e9df1');
INSERT INTO blocks VALUES(310396,'78130540890de0b675b37bde2aee28c8fd4ea1678de7afd80b1149be1f25b7cd8b8a43a7f5529136708b6345dfef6f2068edf5fc84636ab2445c2f3a7191e7ba',310396000,NULL,NULL,'b2c4a2cf312ac262ab7d08d00f3165b656801d7fb06c6a32179355012c0cc9a0','4b9306d812ad2782b0017f5f6a5f1c6f112afa06d878c872ba882f959bd81aaf','9f8ad4179d9690e2bf27b1fb4ce1cd28bc72a7a4f75307967988a668d98346a2');
INSERT INTO blocks VALUES(310397,'d93c2331ebc27c05ef1edf7f5283ba6b936271da24894dd753ab8b9a5866276a075eb5daeaf707869e9422339730bdffe04c702b964eae6df7fa92b161743ec9',310397000,NULL,NULL,'89b57997cfc2e66d48c32a97dc90b325f730797def4234dd6413214e9a644737','c37ffea33e2374934397f28597d22518797a45c69be65a022f98bcc48ee45c4b','f5ffce281b433f057b18415747532d077a7d60742cadfa408b72526e8753a4db');
INSERT INTO blocks VALUES(310398,'3cf66db0bf703924efa0b1a509c51545ce0cb71bb75be55899a5e866392de3cb79fdc3bdcaaf9984a9d4f2e790d4c2d3f326dcd80075e321b34f90def7467014',310398000,NULL,NULL,'ca281a6affc929ef06e922077782dc009d3cd4429cef0a154ef9f2bb4780d7db','0d8750fc96b75bdc462cef2c5ac070a196b9404d6b03bf435c58134e0b66c47e','cdce39c51e51302941fe4402af40d926e5e396fe241ae43aa60fb9fbe0535715');
INSERT INTO blocks VALUES(310399,'a85d0e1aad11babf4868b07ae9af70e31ddf4759b4678a714aa0cab6d42c6e27fbe10c7b7126eeb9b4a67e499dc48905c487c96f89fb1ae81783c7293c783d3f',310399000,NULL,NULL,'c7f1b3f3a45ab4b5e6fd1514fff5147df1728f83d9878d67c23b6eef838774cd','32a522859b1c5322e31d09f213f4ef16b7bcf426e6105d9feb80855073ca7b60','a6a9a0196b43c8da13b5d11b09f88d742be069ddb41be4eaf8c4fa4d299d52e6');
INSERT INTO blocks VALUES(310400,'174d8e6c08617f64c726d4ceadc20b3465efe775c3dfeac4cfa0cc4216168ee9e3c3d7da993c9c5c71073c7c5b51a4df17f9ece110bc7edd55dd5c8ca756ce7a',310400000,NULL,NULL,'6a120883e8cef146589ff4d8b88711ab2f2a588aecab66d48cba48b863bc63db','cd4cd93d7653313974bf61da0a17a0f3e280a949b9ed3a405f3a1fb5d46f37d7','4eebdbef2c5b94d5bb39baaf271b1aa87727c992c55d17d9314e3466c0d1d89c');
INSERT INTO blocks VALUES(310401,'f0590b3f199a1db947a38a4955992e6e263cff84cec984ff1a980317815d855fecfdc4eed6969fea08825a28b49a9f84946b617b33b75745c2576729c467ed5a',310401000,NULL,NULL,'5ffee837193607b2f993ebba717eee650af6ac0a66bf00faf5b7b27bb416fa2e','999321572e7fe12372c54be591bf97893cf157dc2aa283f8583153e196d4c5fb','71f240b162d14c9f78b0f93252ffb95dd9e61c2eb028e2440091176d05e6a60f');
INSERT INTO blocks VALUES(310402,'6709c9d903466d14d29ff6940f2a9778027cd368520f4ef2d457d9e5d5c52af845a3312acc25fb92176f0e4902d8985f5419b22da23f2120de3f684f483b7c83',310402000,NULL,NULL,'c8150cce5f0a7842acc466b5532dd4a057f9b214f9ad2fb2df4f27d2bfebffea','ec5b032da3b01a50bf94bdf6d3773a79028e7a6564f7dd0997f205664d8e5a78','092d88d8f1b290f7e6a557d08d5fc81e221d12dcb1f9a1e2d011e85b1e5aa779');
INSERT INTO blocks VALUES(310403,'ed36a12306f191a5f796e3604e814618396ee773e41bd534eba4534fabb9632f3db522fe0422aca404792181c62df1b596ba445eb7ae414441d4fbe2c04b62c4',310403000,NULL,NULL,'ada969109e576b8aae880710323e7dc03bc8b482a0389a3c40c5c69add556336','a230d1f4e84101608947dda5c8b0c205fe4df2ecd2e518d9d6fcd973abc8f2c4','a93f236b49ee508e635d7572aac24bb6f5b05b376d052fff11d352bd931b9570');
INSERT INTO blocks VALUES(310404,'6bebdb83a225957a55b436775844eb69c0dd529bfc5c2ebb9088a784886c8abc1abcca7c49518bb5a6a9eceeacec2a28c9b89d41f4a7725e3caa325a773e0288',310404000,NULL,NULL,'a74bca383a199391814ebc47de497a9e57f9cdc4eda3002573ad4b30c265cb72','45afbfc811dd38f41ea403c08b7ef146443a8047a25521417cc5bc8093d0eaf9','7bcf672340da79d4aa5bad42ce0ff01b9d4beed4bbed41eea761593dfb850da2');
INSERT INTO blocks VALUES(310405,'6b015ebd2c2986f6df13a8feef2427d8b03a4bf8bb197eb2053d5c21370096e8ea57256008961472d8ad195d56f7adfa8b5b295d4916bb45562a853104334e34',310405000,NULL,NULL,'3363b4eb4905e20e8a395ef8c1ba89786a16a3ef598ab8ccd479a9ab1c884640','627040680fae0f4dd90419d10a423603a337f0608cb90b0d3badc72c7ad6fdc9','3f4238106891fef4049622eee3c413fe6b9d323a5bd741f9b905c8f0f8cd582f');
INSERT INTO blocks VALUES(310406,'87467554696f2c8af1366cfb993410b81e17e5551e963483f7c2922d7805d1732cf141cc42ec0e5e0042a82e37512e24786f6e39274f2c8d096ba95d55bf2bb3',310406000,NULL,NULL,'5930187fcee1f83b807cfe9fffb51af826e79b351df0211a66dca64ae580ff37','e67df49a5aeda3fd424f5785fc20208dccf9f411567599489c3e55d67adee743','4fd89289a2e92dcdb8f28333f4886afed7d02954aa778dcd95272862ee5267ea');
INSERT INTO blocks VALUES(310407,'b3ffb46bb9ea5e1203b393bbee2f84bccbbca85bafec4a8df1626e75f66b65f612c1d53fe71d73b961e157c7b3e3e78e25a312286ee529da6c8820ec1112b5aa',310407000,NULL,NULL,'1f86c86c3d82e98273c206eb709e97cd505b04c154a9a25f89da20073daee4ef','ac68789125a92c4af7c4aaf8568f225c52e5b6372af37f76199f9256aebcfc60','c5a3d48160051680a99c6edf51c2aae730d0b5bf7e1b9faa872744762790b993');
INSERT INTO blocks VALUES(310408,'7bbff3b39407329f9994849099b89a9624fdbbf5711e1eb83e508aab11416b35f759e1dfb640ccf4f59f1bf9d2e8eeec393db74c0b82e46673eb002fb0901019',310408000,NULL,NULL,'3049ffc4696d9397c15cd23ee7c55bd70f1a35363df856757edfac0e03cf961a','a656af37c7d930e353065866c8991402a76ffeaf22fff1cea5f7a1b6dd2cb9d8','9d8240860301e4f58abd63ac0e178824adaecded4c065556621e0e79b4e6e01c');
INSERT INTO blocks VALUES(310409,'1e0cba7207f81d1fd5b5ba2791e53db73a0b410f43b8a767e6b89277f95519ebe776705ba0debe97ce2b447c6685832664eb0a695c157a668a9e03ec34ead8ba',310409000,NULL,NULL,'6ba59e31b6801438970ac09bcba5f0f930fc62c60ed6ee799d727efeaddbaa59','69437ce6f7c5dba0180004741cfe65f82f5da8c504987e9b308daff5f5ec2923','59407b61571703f1e0a699932c49185738d0781946c55e4112d5286d875e993c');
INSERT INTO blocks VALUES(310410,'43da7d9f0a402caeff43c5f43f4dbddd28a0a4df6180fb3bedd96eb471df18896096e0b602a18e513991549337b525325ce4b3b3a5dd22168a14a1208b700a73',310410000,NULL,NULL,'cc4b1601d69d0cbe97ea9a87cc521bb9d0c6fdb7a6174c02bb63bca3e8aad494','dd0a3da3004b223a856990b7be08852ce082dde5265fb30cd08786b39098292e','dc1fc599c8cbada13bb580e354099a0dc53caa98b41124cb7d8001de99d135f1');
INSERT INTO blocks VALUES(310411,'b687c747443e2b9ae6fbc145dd896cbe0047b557a8fc205286d463ede5c585b20f7f5fae438d7fad4a9914d233f554ecf586dc772ad9ab96fd8b1232415b885b',310411000,NULL,NULL,'86c69ff6750569281265a3840b6549fcdd656a325a871ac453bd0d4c2fe93113','fe55f0d7487bd082d4993f8d56e98afc7e6a223584fdd8176f2be8992931b979','5e15af45055a59b1ad50147d3fd26dc546350b362f8ab09193c830d83d7a958c');
INSERT INTO blocks VALUES(310412,'22f5f22b1a3655a4a8356c614875b24e57afed7b81f448b0f082b1007c67a75afe7c84a6662bfd407167edafd4fb90fc68c2898af9bc9faf9b2a2f7823366fc6',310412000,NULL,NULL,'850881ce58882741dfe81c563088b6523f5d82891a1262895a247b78aee4e6d6','04fb538c351f4e052871e62b422267e5943f97e84a08df9e64e9f4de9eacb387','93a92501d88b1b08710e90c23124909f82f43116dbfa4c635bd2df3b21401747');
INSERT INTO blocks VALUES(310413,'9d334a498eca94282d6630fcd88d18a2392888a0f8029c1216602e345116b7cfdeca4362115fc8e2f01acb8c961eddb12cf4b090a956e06d6a04ac0233989811',310413000,NULL,NULL,'5e23f26ee26f9889499bef4306187843145807d5b4d326621e4511cb46f99101','1d87d8e1db6b4d274fde1df658ad10302853f2b0b04fb026af0cbbcdb2afb40a','0037f12d1b45eba11d6e0747a00ef8521e16121cd11ebc15b7372b7a76104c2c');
INSERT INTO blocks VALUES(310414,'7782b386cd92d0fcf9f4179e6486e38cb938cbb300a7b1d11689a91dc36a682e9e17318c50c5759d3f14599c2454211de6b8e119759dbfd779340cf0e012b4ec',310414000,NULL,NULL,'ae425f4e6190737a1e67a4b189de5279040dfb3120d52c12178e046419abab69','20fd258f17143375ae6e9a17760ff35e591eca2bc945c4bcf0e265e0a7c17d01','47842139750ef26e345f5dcd3220b99296256ccbb78b01a0e57e500b2a3b6da6');
INSERT INTO blocks VALUES(310415,'9a13274c2d5cfd7a99cb883ff2138300747e82f5bc26511651a46bb2b973864ae9dca8bd40a7187604b935bd5607909c3aa18568609bd3042f95a9315004ade3',310415000,NULL,NULL,'70e969cbe962828dbd36fefe884bbd995fa8e7e0705e5b4077442ab04d9b3e9f','2b7eb8fe47b5518a7f1350d581045bbc01fb3d76f072e79ae4b0e306e1936e0e','1fde8589a646e5f0fe64f41bad60d5d5b2441fe8b1ba04bf85967575590df6ad');
INSERT INTO blocks VALUES(310416,'6c58b891a05d796a69a56b0be77df4174809ea3ca82d1ffa40b95dfdbcbf8f06afa8e9c75b744bfa1dfebad0a3bbedb842c959757b2e884d72533942de971de1',310416000,NULL,NULL,'7321b4104564c6d3208dcaa58a195b1e1e806ff14948f9bb7d22622c210e8a05','ea5dcab4bb76695c67008a637b4b83ab9ec94996b2d49fb31457c57e9c9ced6e','e043b059e53d5bf7309e755118713afeab545d60830aa0f73883a89cda9a9899');
INSERT INTO blocks VALUES(310417,'da307e407cb38d53bc7e9a8ed9ff477ab9addc5a029e4e024d8975f2a705f0b3872e102a92cb7d183154229306f72cf58156093ffa339f404c67f8be3d988ed2',310417000,NULL,NULL,'40f75ca8549f5bf6bb5601561054a7f90a3cc051e4e38f29519010cf268931b0','c216bf8ee5630c2a59990b52fc8c085f6cbe3d83e9e34e3cbd6a127ec2043b44','6ea554e6b844270554fdcead68215c73cb7584e3668f35c1d631fa2435acca78');
INSERT INTO blocks VALUES(310418,'576bceb5b89ae12f7e493f50906cfb4e6773008474b2cbbb9cb94d90a2de8638ef1d5504e010913a886d75a4cea1c7d4c1f494227a2856d9f4d0ecd3125c06f8',310418000,NULL,NULL,'fa1f748145309c14264bc47a5cfb0eb1898c73a2dca24aed107f034f1d7cc1d5','ab2d1a660ae6b76277d0d501e616799a0a0125fb596452a4cb6a8533efe7d49f','1669ceb65113ca4763ec6860c896f2d6f3ea4b7d629bc8c0f00ff24ae27e39cb');
INSERT INTO blocks VALUES(310419,'0e82af01444fea6b8429d63eae0feda27f0504b8f5632e1121e17ef42d24dba60ef17efda48308beffd5f6d6b70a58abe10fa6b85b8e10db8a17e8572d6ff5df',310419000,NULL,NULL,'671b2eed1b986e48f8717004e77718643eda316baec0a2cf855e059ef93a3366','c556814e2113fcddf3ea14ea97afae8fff8ede4135ac58da3527f5ab29fb36b9','86de91efb10c8e804fd3a3dd388900ba3d9201919004e79d1013fba36ea31601');
INSERT INTO blocks VALUES(310420,'1056f8418f3ee73e2e3ae70f039789eaa32ddde1df728715e6e8698551d857aa309b7be1b26534e8954a398cfc7321716083e89826ffb41897bccf5f943055d7',310420000,NULL,NULL,'63bf148563a504fb2cff82ca7501d1b5d59ccfa4ae881ebb8289e91b4f67ef7d','29f5878562a00275207909f3b6d2dd88169abe408d92f7493b6a93260e14fc9c','550a70a7e3d4f29e443d913dbced4d4cac8fef50f1def7639910a974fc29c21b');
INSERT INTO blocks VALUES(310421,'15ec5f098545ce28a31d2a6b57f63d3674675576e44995f98d0183f47e4abf84a7f5047ab912521e81f4e1d3e7ca8cb97139742879c505ae40c6cd561709ce94',310421000,NULL,NULL,'ed4c1c20a25736299bc9e3a7db8f9be86c361a8555dfc433b76f71cf9710dbe1','a0aff041c09cd97cc891ad97dbccbd52ab044626fca5ef76c6906876b0c6a18f','e5ea05c79d5903a3fbdf28d9e0d1d44844414c78af5f7641df8820b3b73b861d');
INSERT INTO blocks VALUES(310422,'ffe47629dec44292e515f6fe62761595ca13bdbedbb2d9d53f43c200de013ef8816f333a3506b827148da7634365a335e408b6fc559df2bc658ad13d90cc9ed7',310422000,NULL,NULL,'e2b1636c61fb4b5ee987a61d78a4bc39d59728b1d5b520e47293bfd026b69e0a','163791aa2c460cc9e7aed5526d2c9ffb308405e27560baa86d25a504a310dc09','c4f851e10c1c1d4e3fd4ffdfdc91924265c91362c0ff92bd8aa446c9fd0d8c67');
INSERT INTO blocks VALUES(310423,'34cf9b59257fce62659ae3f5ff57a6f3f5a3d4e34429cdb856ea1cc7b587ae115523ffa33df176f41b3e224c218aabc3af8176e0d25c73eebe1bb0f3cb3ce60c',310423000,NULL,NULL,'aa57b091e842b72bb16dfa198c81a6967618f5690f237c39c0289dede66c564b','b107e3c19db5640598535db5c3fe23e1950d33408eea5279517de3c139032446','a64d7409028dbef5d50cd1eb2a19049ec8e6374507054eb86ec9d8a83b69a05c');
INSERT INTO blocks VALUES(310424,'cdd558c1a30cbf860697d8bffe867e38fbacb89a587e565a0c05b99ed90fa4871bb63c19241693f10955187fc9d30e798bb7734307bea6435196ccc79a1c3134',310424000,NULL,NULL,'5083b1ca4dca0faf289a21cf2ab0e9c2f2fe517679054c7934b4245292e90c79','2a9c3777b8358102f0759bf501caa1055fe81c8b73dccafa0aa46dc8fe983bf9','73e7e60410d3272e748851e1da505f8eb64efbd4490c3a5b9af675c5069797c5');
INSERT INTO blocks VALUES(310425,'7d291169b734dcb983bb98080ddd3c0b47698a4820ef8d6cb86152a7858412459623407abe935b3e362af8b5ccfc9fcd91628d48ea2032d11222b115385ec1ec',310425000,NULL,NULL,'4c32ba8004826efdb1ce82c5ae20455bcae5c8c7de3a36ed639e4323e2c79817','d6207cfac7c6a1a370f06a1e86478576020612d7fc429be541738bba18ff15e2','1769623abfc5ec4dfd48e9f88c2f8af6c38d98307d6b333d41363462ea9fa3bd');
INSERT INTO blocks VALUES(310426,'e260192e2d708287d5642aae40af7ea517546d0cf9856c8b83abd61005bfa2f4a89d8d335c33c59a5c53160c195053f2b9126e78a185914316c2787301dc484a',310426000,NULL,NULL,'341450a399413e5eec79a161ac7ba094ca60373b24dcb589bc5f3a4d1640867e','dd85e36dc50fdd0d6adb91c67e99f78e223e8764e863575970cad3cb9e7b4d38','73966f574c1a2c975f3321c95734b862ba2b68f0e08b9f790e65d151d59ba59f');
INSERT INTO blocks VALUES(310427,'5fea24eab54b2be6ab3c00b04d11b3d0873aef4ad9f6b5828dd7d2879b24d1cc5ef8e8cc0b9642d08862584c2b0cae6ae5eb38eb6aef38f1035618b0146ea076',310427000,NULL,NULL,'0e6967fd1d012db3d000628ef79493bd96a56eb06cbb869a7300b565d7ff9db3','e59a6d9c9cd53a8e29ed538b19de72afaa926cfc70ee22fddacf8446ba3eae7d','4d4ed4ae8844414c97f36d39666952ce71c683a2998cc10edaebae138c7ecbe6');
INSERT INTO blocks VALUES(310428,'a18394d49c5f7bd594255e8d051544740139a07319dba9daa6b2753eeac8a5803e12f401e01a822b27959797b4c28434d0cd632c193d37d894ef940165859a47',310428000,NULL,NULL,'042794232e0750b54e846774802cecf6d801488df86e074936b40d6c0f8b0a09','1c35d6a62755cc21f34219be73729d31e48644aeb8561ef81e098126883f4ec3','13f8972160cf2b3f86a78fe8c2d2b2a98b9bc0e26a12e25844c77b2ec6d8bbd8');
INSERT INTO blocks VALUES(310429,'1b101a7ab8ad7d785f703bf1731c53bc2b4e4860ce5fa9cb0bb32b35d263a0614a31585bb4ef3c57e8ed8e9d58747928a7919d60a982cff97ce6e127322795e1',310429000,NULL,NULL,'3590dc920b66826c0ff9db2b8e826e4cffda724f58e0af6a419ed6ae6be39126','931e2ebfd7b23378e3e1de6e74e8dc48bbd53fe15b5bd3423b8ad2ae32017092','594e36118d9f86e8b2643d3ec6140ba46aa073a9bd14fb818b3395c9d790fc34');
INSERT INTO blocks VALUES(310430,'441f2780e43d35c8abd6e36384c9ee1104e9c64a98efba58016a439a3165c9e67d7f8dab3cb8b7a58803103a5433fc6a1f416c1de00ead3de354acc818d832cc',310430000,NULL,NULL,'3dcb18cc1f24f2cc6efb11e19fd2372fb7f899e83fdbcf34b09b3a96e15d3fa7','efb8d6436b57b9c6dea680dcaa66aa546fda7b11d940e56453040834e4b796f7','2f53f08f2892706a385c108f92efafbadecc24631a67d1d9330ccadf0b9ccbe3');
INSERT INTO blocks VALUES(310431,'70797615910255131a48c8f57dd0187ea1985d7de08546d96fa4b4202e127a0e8195aa76ce7cf2370b1b40ed5f576262b785a4f5b2b117cd5bd22c32ab670cdf',310431000,NULL,NULL,'e2f85fba381882f51acae84f50072d1b8b0609845e9a891390249079cee3f5d4','3ce95daea21314e172604f546f3297a07b98352a0018333bf73ef9b5c795d52a','658c2cd5d0183f358ec1853b1662a8e6bf2ced04a09d213fa74b907d0f3d15b9');
INSERT INTO blocks VALUES(310432,'d1d2d773866ee4381232e8393f4fdbace8d8c0119436cbb9275b895d6bfd6756dc19d2aef78bbc1464ebfb681ec3d893638b869d8c0cf23a75162ca3c837ba8f',310432000,NULL,NULL,'2bc7d3d968ff9ddf047bc56404dbe6af9db96d35eeac23fc16aa5836d96ee2a9','1e20ce7ac1f7eecf64c99016c1efe2754e9020d4a96b4823016de2aadba9cf8c','43a4fb09e9efcec080ae3d1282f1ef898f4668fd1210dce3a013b57cf260576a');
INSERT INTO blocks VALUES(310433,'67984d7f40300c9747a2efbdbb0e1447d4642eb42865562f27ec3d3db786e18f4a496cbb14ad8ffb039f655733b56cc3705c23425f584dfcaa81c91c36514d75',310433000,NULL,NULL,'9a47cc0d4aa26e88e29c20ea029b890e8a6e3f219bc421424c69ca4105167c75','dc3c869948330fbc6dd47f49ffc78224dc905d4e6de5137bf9948086f88b2e25','b4751a38b9014ffc7adaeada5609c09767bc62a37369adea11c01a6dae251e43');
INSERT INTO blocks VALUES(310434,'6f30d7a69d792655279266c10f45dc984fcc907d91475f2e6b8321220eb78f9a7a8e4ae2b9fc8d8c5e3f25abd144ef1338e12eeab4b9901f11812f15a64fbde2',310434000,NULL,NULL,'54989e79b8799b14c297830e0c9a2e1a75b0848ae4a6f26685ff65f8a21d4f20','32c9822b59fcd1a1b55839e91bc43c1d78eb2a3b5d30bda596ba3eebba481da1','5c1101b30e228b48cfa9a11d658b0522c0bdbe78d37b8961e364b795b0c71b06');
INSERT INTO blocks VALUES(310435,'a9a0b163b028a20dca6bb5564eff523668f42b46c1eea48175cbda13315093ffe6e6445979c05fd90814a65ee8e01ce509c5242e09d957278ad7b81d25797a38',310435000,NULL,NULL,'18c4faec79430dce45aa2399d8f9bd9179e03971cc091c6883091ce01b049973','ee0afe76addb7c92333408f1ee898b71605116c54227717e4088c7df5f5eb14b','09ea6ecaf78c9bf23f6b2f9269d209c297674826c2a6bc05019cb06c2d41c5db');
INSERT INTO blocks VALUES(310436,'c8ed150b76f2b615232a6fba7b0d9ae5fb28b33c300dac84fb7bf2ad0755a26fd8b2a911df2d329a47a0c488e13df0cccc7ef8ecf48aae995ba0c03f08b1c068',310436000,NULL,NULL,'577ebc4535a06892967c8e8660477be108548733c578363d6f9ed0629f8961d7','45efa2bb39e3197226ad376150b635ba4947f4d9ed9c02f7350035c85301e10a','e6b8838c34ce92585d9257b001f51f0d671af134ab6690ea8d0be74f95d1bfff');
INSERT INTO blocks VALUES(310437,'f6d7615d1e012db1bcc2eea1b80f39f8ba569e8d0f8840118795f8c2de1a91a2fde2731cfe29ff8c779ad1b40809bbb80372befd54327b5ffeb60ad67437f77e',310437000,NULL,NULL,'4687b6b63670707115c3abc1abfdb936395d4cb48b1b573a2177dc9066cc842e','4a315ac74eb6507a719326b2778e8728c5597a585a52663c304d2a6d9e5aeb32','a8fccbca937e1e70fcab67299233cfb43d435da0301be08654ae358daedc576b');
INSERT INTO blocks VALUES(310438,'ff7dc5d5837d765686f0f08fa01425a3525d6077761240cdd5cc3f31ba43d0c96c99e5550b7b0af2129a0dbf8d9bcf06e34de16fe9b95450ec08dfb365ec4e1d',310438000,NULL,NULL,'8ac499665abab3d4e7b72fc530536817b124ab990b11b9501967c807a565584b','e14b1e041bc8dcd6810629d8e353128dd965be0a3b48c52fd610ac5cafa58bcf','7a4ebdf986c36d8f17d65adcf21a0ceee508b9f285db8a363a49126381fe9e66');
INSERT INTO blocks VALUES(310439,'53a29572310a9beb0a93920f4f53ecc518a39318947ab914bbacd10f8eb3f34ddc9744006c487cb9a3a4db8afede9c8555719bde20be8decdd97dd32917c7fc0',310439000,NULL,NULL,'81c29e8f4e735fe4994476efc73f822caf55f5ab03aaeca153fa2c0995901275','6c55d75d86c9e2836fdca6e8370c94176f5cadfc0272782cfea9f84cf8600911','ff5320d6c327b241e5ff51f331ba17a9e4e0667a376b55fcb459c45a6fb8af33');
INSERT INTO blocks VALUES(310440,'27be90ecbfdd8f865e1641a461a898e84e83515ac047622edfe7ead4a02fe0eb5e10f8fefeccfb0b5858e1b3fc9a963da9a08ba90793c7925f0889608727375f',310440000,NULL,NULL,'cfe6ac925a65faa3a61384dc4b19e21a65008251959efafcee31f62a95a02640','9beeebd7c5aaeeacb6ec42d37e4c0274809a47a174eb50f837bdcc4d33cf3740','b760dbc328ead9d8de87f67b8bd9da039d6da332e644c09e269459a947f907ba');
INSERT INTO blocks VALUES(310441,'c90612bc5b434c515ee28b0e4fa24a21fa8f52e4a4e9b0b5bdebb70cdc8a0b8a9b71f4387fd0c06b92b9015486a46dd7a655676dc177efcfb18a5eb7e78f8101',310441000,NULL,NULL,'7b3b43df60ab1cdf404921149e15a45d3157afada6f89679e765a595422b189f','396c730e2c3556cacd6800558e3d6c0cdda4db66e64908cd9a158b5c718f6f89','f3f9325cdfa0d538a91d49ec36df2c786c18254429bb191eadf51f9b78b5b1c0');
INSERT INTO blocks VALUES(310442,'67765b8cbc19080cf9c5c7585c1445f338cc0f5c9fc9b99607b28326811e589e065db8b0e13af320f2287384f26902db67461992fb2777ba9d56f6c84037ce2a',310442000,NULL,NULL,'9e02e1df0fb1ded567d8f38385a6a937905993ad3f8f41d90773bfd972371c56','f79706cb47231c9d164b6d4269f9bc53d0baa7e6f52733d1c27ffa29919f401c','7ed8ebcd50777b9c75c0e12b928db608e9329eba4a1be414b96269e8ad59808f');
INSERT INTO blocks VALUES(310443,'a8f6260ac5bffff343cc564ba7408a59f2ca854cd9789e9c267279df5fab33950c077e3a7e7f0c3c15f6a81e88314a149a0338555b67de2487d61b4d41d0d58d',310443000,NULL,NULL,'989d0274e31987eda39074a4c5fbc82b05065a5703a5f3c66d1402664df0060c','60c0c08b4af27713fb5e514f7b3bad908b43536b58d074afa256a6e297c058e2','a37c542cef0b7fbe9e7351e55343af193ae199118939b1ea2954bde64154d1be');
INSERT INTO blocks VALUES(310444,'95ea73d35c08423022903aa5c07d1f3f3b09395b278fd389ba9863f3072bc50dcc0c23b0b294688a4e6d7a17abcb41d2da63fe35b94aba0578c3cf36b14a358b',310444000,NULL,NULL,'0fe1c73127aa2dc8a53e5922bb42947129847b1fa106969abcc0f136bcbfcef5','46b494554e8ca1c873911fd63fe7d2d142d32e1d48d8573ef50fa11109a207a8','6d04c25382a00d0606e17de5c9628bc769a124bb3d50000bb32f367f32b58e8e');
INSERT INTO blocks VALUES(310445,'1c98890928c4de0b4dc1c6e0cccf01d0c921dd5203e45e0dc2f1cf3e6ea7a339629d8a8f67552723db1913a7e7fd2aa4c78bdba4faf0f32c161fd852d9246eb2',310445000,NULL,NULL,'ac909ed813f6e84e657ae3b28d84cda9021bce9358cd2a069b15ccce56362f39','634ce04e45fae9c1b15f8b637296331cbc9e79f3e1e71194dc742bc36bca5c23','efbe032df34769f27c7ac39e5f59e0225f61cad7209decda35193e6b4b85506d');
INSERT INTO blocks VALUES(310446,'8e3e0565eb0ce9d14227549ba219124d0f7a4f03288b84fa0ff808ee3f3099275ab84c7aec8afbb0b192c090a9f0507aa36a1e5145a05c82cf01dcb496b7a702',310446000,NULL,NULL,'b3130a131688db35a6c9f5a395aedacd8bfcda22c306ae1e4028830bcf178ad3','3927635a4513cb85c307536a44f32ec75aafe458f7198f94e885e43034783100','d54ab6aad3b7c15e413cdbd031894c89e3a8668c81119ccc4115fd0f5e6e6bc9');
INSERT INTO blocks VALUES(310447,'ce5557423db4ee33640d2c3d8b937fce3b13be6bb52ed271e861abd1ab330891b581f2969c3f8e1e485d426682ad90f6101913302a51e87eaca308e27983653f',310447000,NULL,NULL,'1664e8c45fa0435d6d8b72933e8e597c72476048a836eb860f85f6e1b632abe4','0ec3300b8c32a800d127336e23c7fc58db52a16c0d105e316e11543c234c80b4','d39f760c29d5b58771a0dea8ae5cd621633cc2fdbeac3a038257303814a78d9c');
INSERT INTO blocks VALUES(310448,'bea6b820378cedea8f9b80e03060bb3b27fff3e03d39e246a69bf742d39d85a676a1e2cf9c1af8ffffd2fc8b514948673620a12a17fdefc4dbae372c0fdf1fc7',310448000,NULL,NULL,'9492a1221dc276cb417971d7abebf09627a2b628512c68d942665658f50772ea','b87b500ebffa629704d1199c0406503fa4585837a16c1d5456d8bd5533ad618c','1540571e8a2fbb5152b940c827b67000c7ce48a7cd37d870f47a586c4142eeeb');
INSERT INTO blocks VALUES(310449,'827f02554733bd9cc66150beb2971a093599e471766c8df7e795c2feb4c6805d7078b6ddfc71c2007f190130297bb4771d0cb5acc95e79ea17fe9323f6fc3f1e',310449000,NULL,NULL,'58d7a4d4f500b31762043d44248b27790a379e2526d5a090d452a1d89a99b34b','babd940ee9dc69405352ac537d51cd794e69326ddb37fdf220b197dcc833a9ac','13612e0728c920d15b267104d9a5cb0150a67c7cf1c0a33996d78304412f684b');
INSERT INTO blocks VALUES(310450,'d2eaeff1ed36dfb25526165d84bb408dc3e3c78656da7949def5f5820fe952fab17658863002e5bcf2b3f0453754a32cc9795beaa4a4ce515a68ec567db75c9b',310450000,NULL,NULL,'235b73ccdd6b4ce76f1babc4631619fec8f4165a26e5df4bee424d2edaacaf87','ee6c4c93bce8e8749859d101787999bc75859cfcbf1fdc0b295252b9ff693e36','61ebf468278b8a58c734fd48a1549d89a46213c7283f2ce356cafb984b7fb133');
INSERT INTO blocks VALUES(310451,'b99ae820d877b82d457cad56ecc061a8b380d027e4bbb40399ac6bbd9ee5f3b7490ca94c6ef64eaaa21ebc3c65f9bdfa681d9ebf734146e4b8500af3c35923cc',310451000,NULL,NULL,'0b91e1fd662d36816ed7507194f8cae5a0bfcf2d5f08a4bbc96c3394e8a52d6b','45f290956c99d8d98f011df0b580705bc5b2d655535b6c54bb524b494a9e7cf4','b8e1f0cc559472a633c2801af5eea292bb98af0bd80363c32a47803cc6fe6b39');
INSERT INTO blocks VALUES(310452,'87af378fcd50ee3e6fbdfe41d32b18062b04794d3849ef6d89292e1a9f4edfb9faedc966b8bc84004c50190aed5e2a7062315bf2a3e473dd1dae8f1745419c9c',310452000,NULL,NULL,'facfafd171df17d80c4c37bb9eabfefb61f9dd6ccc69e6ff1f5afb5806d50a28','1398907f95b62e2b72f954a8ad6074d8755874616e2d9ade17b248dfb976bda1','3a93c46f8ccdce33dd83123ffd2e6ebec7786bff05606d33d4087ec6012c2510');
INSERT INTO blocks VALUES(310453,'39d3266caf86330e14d8098e7cf3a250c141ef2155d6e076119dd569bcd3cfbd30c1b54ec23adc7539d667699fc183e63dac64f43db02821c641633270e30bee',310453000,NULL,NULL,'37d7d8db1351195e5a799445d230df2cc0041c2e34f35c50a934f6e74884aaaa','233f9e44b7d7557515a6ce26d21c93332591c38887e5edfb99639dd953671359','69ca81db756d60372ac7d8c3fb833dcbdb82b93eb1d15750d916355123dbfd9d');
INSERT INTO blocks VALUES(310454,'453655d834123bf3701e7fbededaefc369536e4ab68476aa860b25f91cacedc740643bf23a411f66ddff983507e388085ec4d12e92071f9e7affc68d05f0f207',310454000,NULL,NULL,'01d79cced9a1e21e86b105ac9a20b7770db78c664c66cca225eea23f68c228dd','04ef731b2afea97d0d2b914e46b68d1066e154e37edd0834846b3d8ad8debedc','250bfdb6fa2559bf7f7e98118fc26d07589009dfdf60eb1c67e2251ef66cd511');
INSERT INTO blocks VALUES(310455,'8cf0d0c5cc245c62c93d65f012207110f0599d5101c030c339286d1b1ee47d6ac62cdda6e594b812af3a6499ac6bed676e6e9b5cc78f6fa6fd454b078882fede',310455000,NULL,NULL,'ac019e21eceefeefff0f90f73f5eac416340b3f0012beaf9264332d21377e73f','786a1ac8e6bf92e203e55907dd8d0b593ed1cd03e7af74bc25179ecc36da8822','c7608d3e1d71bcb7f3d53c535e4bc36cd08cfbb69e1ed6f6af2b08bc72c5ff8a');
INSERT INTO blocks VALUES(310456,'e9c44fc9b8b02cc15bbd278ed2eebe4b0a5d8acd4e5ade20114f6bf7c98b759c1cf8b4bd82a9768edbc84804d4852890e13cf68b51409ece90b7173517566d37',310456000,NULL,NULL,'d177db72acd8196e8efeb0c036105162316208c582207f1d9f8d60f92f7281aa','3691a859035e148e727c157f2bc6973a5507d0bb280c74c1a60f5d0baad455b7','da5ad385390c6852ac0afc8ac22307a00b82d3f44ee0a63413093579d6eb2554');
INSERT INTO blocks VALUES(310457,'227e805c488c604445dbd1ac0b23441119d9111cfb891a9d4e4b5e6b3aee8df51c502976dd53831b0dda68ba51f0762987253ee9752dc2f504c0ac8858bde665',310457000,NULL,NULL,'98ec59be52a25312a01f4beed9453dcd2d8853650a0462a0c94dab34ca071b96','11cb69d910e4fa98d81d8835f0f26608f27ad3a3b178d8669617148b49b6e1df','57e13ba989b12c672629ae94ba15001566077c30fab3213360895c88d12e3c90');
INSERT INTO blocks VALUES(310458,'564b0e3c71938bae220b18c82d7efbd2b9cc4d04b8afbdddbff3a9786d998ec875eabc22fa71ce7b5ea9556da9ae415db6925b1dab816d6667efdac1ea9b6fd3',310458000,NULL,NULL,'bffb43be7076d19d21c0b3e591389486da63cc83764df98b627442b9b89b5afd','66aefdd8c1c19016b0a1fdeb2d1dd7191d308ce05d5bf2ba6728c87251baeecd','90019a69e2c7d50712e796ca061d02fc4c34e8bb80a3b8a2cc751eb04bd9bbf9');
INSERT INTO blocks VALUES(310459,'255c3bb3d2c5102cccd491053a3cb801fa30f6d19e14f6d1dad787e6c8f6493a98437be8bb18b64190dcfe20fbd6131231e1f1a33c299b28c8bb78dcd8dc28e4',310459000,NULL,NULL,'37f2b35960170be831603daa9adf8e29cfa48b944355785e332af54560103837','b3d43124ecc00e12d2f81702677475ba3063998ffdb68393193e1108cb104e59','23563f89d1eafbd2c3929dc4b09d68eeee9ff11c0dcd1fe831dc78015b8c51a1');
INSERT INTO blocks VALUES(310460,'526dee0281cffcffb609a0512950269f7561bef8195041a2f1a901304e106f76e621f6c11fa5b8dcb8e3395b3133687e716f18f31f5a79747a649c067287cd2e',310460000,NULL,NULL,'e517b733f527a4a2233e633224b6997477c9b8f5467d75c972c18763f2481789','2a3a463ee051d96b409ce38c6306c4f8ac121e66d8516feb763be8e7f4c4b186','a5521909b10cea85ed901c7f394a0b6f882f0653e1f8f3e846909c08d9e3b4a2');
INSERT INTO blocks VALUES(310461,'6d8efaf9519038da95dea69cfa10b80dfd70374253d830ae26f403a5af772b6b97db546b8ed1cba7306b5a9711bff65ad96b306ca441e6e8c7ec9ecc5b1fcb6b',310461000,NULL,NULL,'578adfbe61a549f75e2857cc5948d9c0ca07bc602837e89627273809e591a617','58bfb3bc6b70b86799d9957ebfb42de74abd4b654ef4a42d59e6f9828f9a363e','c47a4c68f416bcc4f6204a3ccc14169b9a53f75e0af15224e9bba66e7b498e8f');
INSERT INTO blocks VALUES(310462,'499256a2d3fcf5f55cf6c5cef4019977dd3363e0b3d4e2b720c4074d54774d3152843833b43ebbb95d524ef1d650ea0993e5835e24ae9879256438604af93dea',310462000,NULL,NULL,'328514ca76de0af23fd653c2e36ebb5793a6897cb2e71ebb55837f6f806cd0a6','98bcc3b7eb015f8f505cfb79b0158da57fa2f0f4154ff024835cb259cdbd1d7c','2a8fe81c79058a6e8e476271fac1c1b33c4fa3e327b8b5f0e1599253a4c92e2e');
INSERT INTO blocks VALUES(310463,'9acd0066d56a388ad521a8e3f04226009a47653eed7ad34ef5eb37a43398deba496f6e451e35829d2d51860b8cb0b2b3f8e74c7849f416a5fda39adfc4de75cf',310463000,NULL,NULL,'9b910cb03aa788f20d12044ed64711d8455a8785ef66e46873e6dabfd8cff12e','85c3cf6651c414f1ec29a4ce9656b775df41efb2ecc469ebbeff04e03b111daa','f50b8e2f3718c518b249d6613091c39cc0e3f4965270e897221f6e1bd74a892d');
INSERT INTO blocks VALUES(310464,'5790232ef73149532b55970e89ec58b781c7673a0faf7d972a45a2c4caa8f05ed6aad51cff4c33b9e5ae4a54355770d9d02421fdae0ed5da66a99f0d2ac8ed09',310464000,NULL,NULL,'2fa5dc745b2f66e479da0787354560e27e2fb17cff09bf3c92f309e9423cea4f','37a634feb2567ec19a4fd8c1b71bafde439fe3736b6abc9fe16e284b7ce2d619','d5a3fd7d01662b23db8cb575cd0b48f05603f0febb8a8b953fe624f8c1d54c7d');
INSERT INTO blocks VALUES(310465,'9bcb8cc611f27f7576503f00d8839c784c4fcb95d0ad30282ff7e6c5aa27b0641c43369211043aa2fd8664922d5c226718478803120a06e2ea171a1a5b0663bb',310465000,NULL,NULL,'5f8c8b34b4127ea7ace5597c3c1bbbe60b78aadf1ba1d5368a09e0f2d24d953f','cdc5c6d7cbac8ef6d753fa201c638eadd12e1dac0f0620dd311236b7743a7dac','11cb3e472a4774151aaabf98f9f903ffef7897c7d7a410f272c39a1682875d63');
INSERT INTO blocks VALUES(310466,'0acabdaaac52332db83e63d5d7202a9f94d6e9184c693a4dc3c20f297142faeb634fef2f8b8c4fb29997fb7e0760a16f63c08aefb0bebcd7c4e0cb533331a6e3',310466000,NULL,NULL,'ad2dd38170fc92eecb2949bb8de632975f8ac2c6586f263bfbe19f5b3afb0cac','cd80e17fa4e8f009f1a254996450caabf966d0cfb4791a208ac6e2898f1a4992','1c783bb479ef03f0008ee179177f5161014dab5559f272d6a7a312f40a85aab5');
INSERT INTO blocks VALUES(310467,'bd5e4e06e5b188c11dd3f4ad36e34d8029c3fdb9e91d83ccbe312e9f0a904fda44fe0f594b3498bb8165b0d7c3ec7616a8deab38b9e3c183d1750a81133813c7',310467000,NULL,NULL,'ed102aecd85f3f6a2c0e70deff510cb7c7dcb061c1b73c83783bbf36feff57f2','875d7b700b53dd5f73f8d34ecb894d57ffcae3992671e962bd087c9b167c91ec','b7789e5a07caee904b351a4607a096bcb05ff3d71a046e6cf96aacee973a7246');
INSERT INTO blocks VALUES(310468,'0a6013242d3cc444bde42c36b753210897e5f23a8faf9d920e178b1158454af0028148ad673f3b03f330fc7f9611966cd9f60c404967756f1d1558866c58ac17',310468000,NULL,NULL,'a6c9138102d129fc6f52522a6cb93d89ace3f3396ee8b8bcddb141185678107d','b67829dbf4904efbdf094e3e691dd1b7cd0584ac4ab91069f4718da0f3bc1f17','d16eb6f41210216bdf6079b8ca73fd7fa0671a4bd25f93e3a31a1327840668dc');
INSERT INTO blocks VALUES(310469,'63d6779e475713b55fcaebda8335a2e4705e53b30a432061b489fd5b02a6a5c32d1591ae0416f5baa886aa3ee407dd9e79b6fd8032f90e895714964bd5bef2f5',310469000,NULL,NULL,'ca605be6343e8e34bee9b1279480dc926c8743de838253c51fe35d88fe51f225','a95df501035cf65c1c622997026007a1bc94490c320376e6e72276129da0769f','ce678283dda64a300ada21826dc2ae6886dff0fa5945caa65ceaa1b8909e3853');
INSERT INTO blocks VALUES(310470,'34d879d68d928ef3a0be963de412685a9742b45df51ea6ffc8d5e64d892514a845501e0296911467adda8afbe053372952c17017198f579049b914126594a19c',310470000,NULL,NULL,'2d8077790051f85fdb5892e4d28688243a455c682400f4e7d565796ba9078575','c116a2586f540c30109779e79cb8047218f4f263a5c76df2b734551506b4ebb7','fac76d022c8285c1b3691427e953c058bb78d8acdb4a63ef11d0097a9042994a');
INSERT INTO blocks VALUES(310471,'933f3f1c5f0817256b05cb1d94b8f4bca9690446feb3b7e5ca11ceb44531a7d9f8b259bdff3406ded3844c5d30381b6bf346de7f2384a59a49982634e23d31eb',310471000,NULL,NULL,'1670b4229a52d9f2d674be38ec48930f407d376d2a929319b2b83ff1a27c2dcc','e7c552332a3dc324d5fc4eefc709f4d28ff351bf161b93efbbeaa117c154d291','dc6021f82233a60d09845ae24397a7aeb8f6626cf04373c6e4e2fa4e1f9ef72d');
INSERT INTO blocks VALUES(310472,'56e16b8298be638e21122615b2343d7c67de861523db614331e27e3753c8db24b9edd51ad26f58d44747737cd1635d1341ca680c0e60c0bd8aacaf50acd18a3e',310472000,NULL,NULL,'6ead8d5e552978d1bd5b15ef6e3a00b2f3ab0e78a1d9631494737ceeebeaf67c','80621473cb5cfea115b78538782bfc33892943273f0b1c5531b8a8035e860734','835b0a5a8ab2453374eeb24aa1b6010c7c7e3543b78029188ad0c53bcb4a6514');
INSERT INTO blocks VALUES(310473,'c9958774653eb8e2dc39d119c69b4c5a0cd833ca3833a8314c63625e05ff48d15ff72f0b0445e5e2b3db087e6020dbd0caf4efe3c48414b8d3c7d3b1136755c2',310473000,NULL,NULL,'be5ea6577538c6118843565ad64d9b428c40412c5aacb0558ce57961a3a222da','3285221dd861b4ff2e49864a4c24d13b6b29cea46d660a107353627fdfc55fd1','ad09bd4222d9d9426bce061dc79e61dc0f2abf1bade90e7808c964cbeb42e878');
INSERT INTO blocks VALUES(310474,'cf5e7afa76b87d266035e00ec6d8332d006e3804ccaf8e6d8bdf601fbcb0db2e8e74c831b2cc6efa649e19814dbbda8b84245a4bc5a3cb781215b856b3b3d850',310474000,NULL,NULL,'427db643d3100a02dcd8ec52e584b50b7f33c95eacb5e527644ec6ae9f8cea78','5fa3fe024c8c012910c6374ba5bc309501a1cea140a91e9cef5ea205ad8f02af','3f1c0b9295983f0e5211b2355e573fca050cdb1427e71c262e3473f5cdde71aa');
INSERT INTO blocks VALUES(310475,'0269ce6005cc2f9bbbc0df2558bf402e967e36b929f687210d0cdd41b56c7e83b624d5f1dc31312ae8d9cd15e979f6445ec13ddf2b736d19396a4bd1a8b3069a',310475000,NULL,NULL,'8aef3df780b591cbfa5abf10583fa08c6a9fe913a26ed00a7bb262ae49b5a19c','1927a3e97e0ab0e3eb7dbee90722ce659554264617dc725b494d0edf2c2b6072','56b46f8d66a7cb746e70f9adb7366a7a8a110d3f498b24419298e649876e45c6');
INSERT INTO blocks VALUES(310476,'36ca5650ada15ea2d14ffdc6aebe9895b41205978a5332c52e32653cec6041a3a9ae573ce9e4b712d15130000fc2d934cb5dab39900586b9da08424c3188e4e9',310476000,NULL,NULL,'49ad08b037568f474ec2ef5c6c2a65e96ab87c8d0138280fa01c58ec623cf46c','6c3b75d5c15d0388c38f33bc51c09443ce6b47c435e203916d7467cd3c0cb528','fd79b565f3ad1412287cb24a409c9127a236ba199492c0b05bba851cac3d4b9f');
INSERT INTO blocks VALUES(310477,'02b67d7d7112074f51820057ba6231bdca7e4fb3da334078f1bc810286e37bf132ad723509e7ede6ab836a2527939fe8149fe61d6483fc71220c06758a81106f',310477000,NULL,NULL,'8efb10353eae5ec256acf724d2ed1191740e8d74da64f77ab435cea42538f1ae','7fb98a71e1be8ef7a6697f06435141ade99ec344149d2e5c6ac93c7f91c1fd78','fd28a0eb746f760a3fbe11ecb3ad9cff0b83759c0f3c357dcc0e0bd5fb25f6ef');
INSERT INTO blocks VALUES(310478,'4e715719b479407cd8cf4cbf7b68c158fb0a4741bfdf8925acdab8014501e9cb0a9591f459106339877fbb67ef54a0414d5ed71666cbbdd4211333a2cb5a9139',310478000,NULL,NULL,'037a496419364989ebb97e7364215f6a790f80e7232692d2c2186ae208b48f9b','5059ffe8197fcd295e3e37e8395434edd1069213bfe5d54d53410fe5d0756efe','c1782dc4e86f608f62a45647e662007b45520f2ec86f6c7551a9cbaff683065f');
INSERT INTO blocks VALUES(310479,'17fb547b6100f5fa1a23d938e869dc6bd0bbc11f363ed67b27166ec682a8128a5ef646753e01df6b043577bc03fd233d1d2122b3cfd320c97ebd238fc26ac295',310479000,NULL,NULL,'5424cbb3aa1a000366814fb8414a9241aebe56349bd05a10dcc8b89d46c94484','f4bbbe490f22673338d91a2b6aec647faa6b115bbe52f992f93847285aff037b','07461e22ef10b2ce7df664cb7fb8eef8b5501abf7109183bfc203e00f4db4480');
INSERT INTO blocks VALUES(310480,'4fb45d941467e6bce88e2aca15c620291c255d12f9395aa03c507e270d3c85c4f6686eccc2f2ec53183bf4956b5c754428d6bf30b15298c5e9fd1a6609961522',310480000,NULL,NULL,'85e7ae716668f124f3b6ca80a969ebd8b56392c4e94bc644fcb678ecaf8afa94','b6e132472755313b60ac899b7fa9ef39ac6d05065a0801e412644eff85d15917','2c354b188f0e7bd3c2e6e3c7fb9b13249f19ed140c880232d9175ab8f13b42c3');
INSERT INTO blocks VALUES(310481,'8a8d4a92453604438c38fbfe49b8f36a2bfef0e05c01a7fd4703a4ac24a49ebe8ed3545572560067056532f56ceafe4c8fcd3843b0e02933d03f3ae217a612b1',310481000,NULL,NULL,'7a46d1ce392ed7ece3f5506f221ce9feb5c92e7a1bba1b9ef0ce7571f5f85ea2','986e5e11e044a9c043c47692ce4cea519b5cef9f4e115b7f8f2ac7c7be184d30','0e8c2e48a2600f256f7a0c544e0fdf8616a5ea345e4afbbc076fab344eabd3ba');
INSERT INTO blocks VALUES(310482,'c69b79ac29c827a95204e93894e31ba1a2bea5ec36b803d66ce5918e8c3675aa3afecc015249f65863f71bcfe30d14103017f323b7229f1c74d5979bd1b5b075',310482000,NULL,NULL,'dcb41a29a41cf93cebc588e55efd94d774bfd59569e9838d4d24f6d0fe77d75f','1f3a0bf6358129e9c36839a7b09ea81029bd2061d7ca12d766f68ec08f4f965b','7fef04d9ee87f04b8a321320064ebc186892dd49288b7ed8831b13462a900ccd');
INSERT INTO blocks VALUES(310483,'ff2fb1f86c4c126187292c27c8c5cc16c8192b5118302840de294c26708571c4ca647ce3a58a15641f9f26996a6c42103f1fad72ce7c6d6432eb5978bfb2941d',310483000,NULL,NULL,'8725ac94690efc501a622978f2c368d8b81362e5bb8e1512ad518629c0da160e','12a320097769247854dca71c33cb0430efc7154de74f933ac7d50926c7e1fdfa','52ce2a3df8c19147da4fac274190daf42c0731e3d062f4392bd0bfb9c5879bcb');
INSERT INTO blocks VALUES(310484,'72ff0b152e7a8e3b03d43a6d2eb6c25c2b55c67acec1950af50bec882dcb28456d60ca80772d4f5293efc2dbbbd3f8d4eff5437318bbbaaff86aca00c74f369e',310484000,NULL,NULL,'170510c22462049c301e568f34e803e707fe8f1cd4cae594ea443062afe220a1','b426e92786007d314cf35f491840e7cd7fc7d479fac4c8ea6d632e877246bd1f','efd8e60fcfa173ba376f52af799dffe52790e0d3ee245d444f3702bced7f14c5');
INSERT INTO blocks VALUES(310485,'c18768c9be05414ede83933b6914e92ec4db3f9cd6dcf5934d6e515d01bb8da3e6eecfa9ce139b8b8126d0164405ff3b94ee23561581f6ab5e2be848d36ec552',310485000,NULL,NULL,'5e7252b1db07de62dc373cbbf5f50a2bcd106d17e9e86cb6454cef3263b80d68','d0e143b5f18a387fad25465a22a910aeea827fe18656ecddc8d686df992f84cb','589dc7e0c1d9945679a41318feb076da5682081c01257617dddf0fbc6ef76b76');
INSERT INTO blocks VALUES(310486,'438e29ae1f2dd687adf04bcba05256db1ff5053c16db174837a5abd79394572cd73fff18b5a474d00d25d07a4b9bab4407d9a79a5f8cf7e60f8cb96e8a2c3c3c',310486000,NULL,NULL,'ca03e462a958cac268c725ca972097a78884fd74d48d9ae8d437bb5e4a9c3637','5cc17595bea103a66b66049784363caca677f4bafe54c43b0a46630096070069','81ec821bba240c1538ddd3b367ab904f8e3569037ad77dd60c4f133cf5dec05f');
INSERT INTO blocks VALUES(310487,'7a36971ca18df8dabd367528c3d6d1773de803fd7a22754876ecc70e9350e61a2af1f0bd1ccf00715e8c4613a6f2919dcb3382fb0988c236d484f9c5386991b1',310487000,NULL,NULL,'cd076808fe1def56a9c8653071fa7472819a73aa5ca7124a8dc3b918a72658ec','a127d8949fe4a0957a2a1e41dfd05c01c80b5347668ab532a75ca8cc9eee7795','ecd3e36b1e2952151f1d16efea866aefd76fa28dc2cd013fe81770f7a5090505');
INSERT INTO blocks VALUES(310488,'4ed375b4cb5a66ada5db18a0b55c27a494a91475fbe911a1615ef66f0ef0b4e349f8ee6a1ae2ef9a55a7d9e5d136635e589481833901513825e4f27af16cfeaa',310488000,NULL,NULL,'10d3dc3a0050cc7bdcffa8e49c0f1f40103e19cbfab705c93edf4dcce53fcb04','a97d32595f49bdc1a2a286b540e041e69d72211863cfa75d3b16affd52109456','dae9dcc48cdc59e6568313ba0768c5b9948efe318035e665740215788f0a59e0');
INSERT INTO blocks VALUES(310489,'b294daac549dc33a5a26a1ec076d0484b9b73a0623bef8d14980520b5520bca0bed4d95896f29ba77ad6f5212e5ea7ff49a892564cbf5a351b4e4d771cc3ead1',310489000,NULL,NULL,'88a40894fdc2f663078b4a85df75207c2f67d2357f02f7cae34e8ec8ea8b4f8b','39afdca48c823607385e1daa4200c7d0243b245fabbb61b0d37521fc5054de6d','b27df3b850542f937f887a1f9445b8f764a2e380f7ec56ded0a4144a6606571d');
INSERT INTO blocks VALUES(310490,'fc18260b36da30e7f7bef925d04c3fa86a8f390f11a64eb6e9731a1aedca69258e0a4cf5bf5e0bfd9876e8118e4711f36183c346397635c0af770c6abdcfe2e1',310490000,NULL,NULL,'e3e54f0503381ce795baaba2ee9217f340b88a83e7e30c9482b240120b602f77','aa201f0ae9af047e2adee1f811056c2a17d695bcc189447e71d5cb56dc83733e','c418ae0c72e93a1ce965150e839896972dab8fe2d28f5de33d524bda638bada3');
INSERT INTO blocks VALUES(310491,'bf454daa85f5aa7766a92d2740421d2a69af7dde2a5209852e318ff4c5a2f48409a6c1df9fa33d2bdbef9ddc3c77118f6982b4fe00bf99f4fecbf767ef33fc71',310491000,NULL,NULL,'afa15f23ab58d8e7d9201adc25f91e16ec65619efe9a007552db6184d51f87de','b609dbddd35f36b80ad2dcb690a914d72fdc5d263ac39bf10f9a629730e3379a','1aaf56b12f8f2c4a935bdf69c7ec81daeb23299ffda44bb04253f6adbeb13420');
INSERT INTO blocks VALUES(310492,'7a5dd1618ae6b4bb553d4edc16af2447313c443aa6e31d15a2ae7322bfce7d88160f825ff99dd8429d5fbcf5f2f904e2d486e8fdc2753ba8f6f058390afad447',310492000,NULL,NULL,'e94f2dc7e0d8e15d81c44ce18b1bd19b54112386510e42b5b8a446731efaa563','0793a48dc28bfc3243fc2348940bf3db8a1f25c714e742084b7e8a4eafd431e2','7ce7ec2e581b72a5e93fc4cd726be15d59c3d50a671e5746cfab15836042e977');
INSERT INTO blocks VALUES(310493,'e5695fcf012cfc974506f8b9c6b97f3d2aca71dcaf89a5191fd69d56459a7c7d4fde0f50ca105fe249b13e40556aa98d9fbc4f56c98dabbca3ff9dbc45df2521',310493000,NULL,NULL,'18a9237d2ff197fce36fbe5ab11280aacf5ad97f6149aff9bb19693edc973657','7bfa5fb2d5dc8ed753139f484d4ac52406d82371903e9f0b03a85c5344287d00','7421f5b172bf78aeec16bcd1dbc87cb3dd7b7b3b692efad223c32d5c9e1bd5a2');
INSERT INTO blocks VALUES(310494,'5ea4dd62da28162e1829870fbfab1dc6028d01cac7e541bffa6696059705e33e27d266855fa60ace8ffa9c7bc6612dee1b0e4612e4d78575c847c91b2d3b217c',310494000,NULL,NULL,'3a4bdf7ee155cee986f2b4fa4b1da63ca0933c2b242b36bdf442b3308a2fb091','e81a02af8afee6117d8889b17facd2b6ac07b765ad272b1d7e83121a09c6412a','cd3f6ad289decf60c4f73763141389dfa86888f4573963831923dcb9fe7d402a');
INSERT INTO blocks VALUES(310495,'14a4d161b11a33ae7890e835206e0bab161693bea0c4647d59ead2d2c437157f3b0178db71a244c0fbc8c7d56de89bd825aa36d1e8b3b62f972e1867b9160a20',310495000,NULL,NULL,'b48bcdad3120081198cc592cf8c20d0922341c51cfd9eb52ddae56c3d1cd549d','da1b265a1929813af14a5761de630941138241a4b7172a3d5ef7574e23f2929f','6a8ce704032352cbeeea7b41f48c12c87b90c1db55306d8afa3b9b582e42ed14');
INSERT INTO blocks VALUES(310496,'54967ea8d512b2b886a8e5106016df7f323169118a410af02dcdf9352e97b75ca8041441fd4b6af5ea09fff163f0d0e6d2f7a07518da27e6c367216110f316a6',310496000,NULL,NULL,'08ae15edda6f2caf121ffcdc88d059130a40f28294f4ecbc7ccbc86f337727d4','1fa0bd8169e0c7ad4c2930f64405f4c3cb5014d0a4794be2dd93f2f61606db33','e6ed4bc38cd0b3e345863fd3a5bf55fc4d6aa77072b396bdccb707fea5861a3f');
INSERT INTO blocks VALUES(310497,'366924d489bc84a6b70b134ca2c613cd30e4fbea73f4995249c115938fe49d508e34d463f5a7c26f169be6c013575ff05aa1896a6286611f2f17811fc297eb67',310497000,NULL,NULL,'c5f88552230801b43499dc04a881d691f6e81541b0250d015dcd08027038f966','82ae38bd9fb1fe5657c0fb4ee0bc2a17fdba3b7f810f7d0372275a448e5b1409','cb5976a3e256f67411dd4f3577243e981219ce656363eb313983012998ca85bd');
INSERT INTO blocks VALUES(310498,'5a09832472a10eae9b36467b9c39991a47a88f8167e9f51d5a8c227fd226f1ef17c8052852c09cb4fb1899bade89510f5e20abe94e972e5f94d8feeaa5d3b291',310498000,NULL,NULL,'78b6aa075db207273dbbb29fbaf6b2b95151cd3cc90323898562dc60af23ab29','a75e8515864a8a54e4972814b141dfaf67c4b1cd80a507f4fda4c0256057e78f','b4b5e8c01deddd25db054391b025088fd249d29a5c84912bb9c263d5a5f59f6a');
INSERT INTO blocks VALUES(310499,'dce6fcf2b12dc112411e1a4a526d0ad34b23b8b2db7c9be729bc9ee152c95717a9f48808df0bc5224f99f50089c8c1201d33bce505d8eb90a17260c71b4b2f73',310499000,NULL,NULL,'99c310f627b2dc12e666cabd7af3658921e21b00a10650287214cfaabeb08423','872ebad52af15dfc3b3b13ba5f93fc135c54eb22ce788e5ca841e816623f9ef7','c73d9e197169333fc02a77fe7fa8266cfda289b872d65defc533778691c7d1bc');
INSERT INTO blocks VALUES(310500,'59092152cea93e29cdd1c2c7f54730cd2c609871a5083ebc50d59b368f90b25ef2586608da40f790e23c0ee53d8a5b1e13af627b3946c1a7fbb39ab617d5afc9',310500000,NULL,NULL,'398c9834454c2b8c803a83498992e5cd8f276308d72b54edaee56ac1fb27ce92','7f9fb08e8ff811c3ff17ca29ab1f7f1de5c7d3507ea91a59fac931936b7014ac','a4660b512f52c28f7875d97411227ed721ca30860ce9ff0ae633850c472f210a');
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
INSERT INTO broadcasts VALUES(18,'3369be793bff1ec8bb0ad342bf5ce5c24a9298c4cb5660b0c41a32d6fb06babe',310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000000,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(19,'88c74d84fd6121123b092877283a5e4e1aca4f59d18d643c8347ed756020a846',310018,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',0,NULL,NULL,NULL,1,'valid');
INSERT INTO broadcasts VALUES(103,'d5879170168ed84a20ff86bfdb2ca7d9b74bdbf1c39b9a606cacc34429be9364',310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000002,1.0,5000000,'Unit Test',0,'valid');
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
INSERT INTO burns VALUES(104,'6e96414550ec512d2272497e3e2cbc908ec472cc1b871d82f51a9a66af3cf148',310103,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',62000000,92999138821,'valid');
INSERT INTO burns VALUES(105,'1f4e8d91b61fff6132ee060b80008f7739e8215282a5bd7c57fe088c056d9f72',310104,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b',62000000,92999130460,'valid');
INSERT INTO burns VALUES(106,'3152127f7b6645e8b066f6691aeed95fa38f404df85df1447c320b38a79240c6',310105,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42',62000000,92999122099,'valid');
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
INSERT INTO credits VALUES(310102,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',9,'bet settled','d5879170168ed84a20ff86bfdb2ca7d9b74bdbf1c39b9a606cacc34429be9364');
INSERT INTO credits VALUES(310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',9,'bet settled','d5879170168ed84a20ff86bfdb2ca7d9b74bdbf1c39b9a606cacc34429be9364');
INSERT INTO credits VALUES(310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'feed fee','d5879170168ed84a20ff86bfdb2ca7d9b74bdbf1c39b9a606cacc34429be9364');
INSERT INTO credits VALUES(310103,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','XCP',92999138821,'burn','6e96414550ec512d2272497e3e2cbc908ec472cc1b871d82f51a9a66af3cf148');
INSERT INTO credits VALUES(310104,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','XCP',92999130460,'burn','1f4e8d91b61fff6132ee060b80008f7739e8215282a5bd7c57fe088c056d9f72');
INSERT INTO credits VALUES(310105,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',92999122099,'burn','3152127f7b6645e8b066f6691aeed95fa38f404df85df1447c320b38a79240c6');
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
INSERT INTO messages VALUES(44,310017,'insert','broadcasts','{"block_index": 310017, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "3369be793bff1ec8bb0ad342bf5ce5c24a9298c4cb5660b0c41a32d6fb06babe", "tx_index": 18, "value": 1.0}',0);
INSERT INTO messages VALUES(45,310018,'insert','broadcasts','{"block_index": 310018, "fee_fraction_int": null, "locked": true, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "text": null, "timestamp": 0, "tx_hash": "88c74d84fd6121123b092877283a5e4e1aca4f59d18d643c8347ed756020a846", "tx_index": 19, "value": null}',0);
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
INSERT INTO messages VALUES(57,310102,'insert','broadcasts','{"block_index": 310102, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000002, "tx_hash": "d5879170168ed84a20ff86bfdb2ca7d9b74bdbf1c39b9a606cacc34429be9364", "tx_index": 103, "value": 1.0}',0);
INSERT INTO messages VALUES(58,310102,'insert','credits','{"action": "bet settled", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310102, "event": "d5879170168ed84a20ff86bfdb2ca7d9b74bdbf1c39b9a606cacc34429be9364", "quantity": 9}',0);
INSERT INTO messages VALUES(59,310102,'insert','credits','{"action": "bet settled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310102, "event": "d5879170168ed84a20ff86bfdb2ca7d9b74bdbf1c39b9a606cacc34429be9364", "quantity": 9}',0);
INSERT INTO messages VALUES(60,310102,'insert','credits','{"action": "feed fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310102, "event": "d5879170168ed84a20ff86bfdb2ca7d9b74bdbf1c39b9a606cacc34429be9364", "quantity": 0}',0);
INSERT INTO messages VALUES(61,310102,'insert','bet_match_resolutions','{"bear_credit": 9, "bet_match_id": "be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd_90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5", "bet_match_type_id": 1, "block_index": 310102, "bull_credit": 9, "escrow_less_fee": null, "fee": 0, "settled": true, "winner": null}',0);
INSERT INTO messages VALUES(62,310102,'update','bet_matches','{"bet_match_id": "be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd_90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5", "status": "settled"}',0);
INSERT INTO messages VALUES(63,310103,'insert','credits','{"action": "burn", "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "asset": "XCP", "block_index": 310103, "event": "6e96414550ec512d2272497e3e2cbc908ec472cc1b871d82f51a9a66af3cf148", "quantity": 92999138821}',0);
INSERT INTO messages VALUES(64,310103,'insert','burns','{"block_index": 310103, "burned": 62000000, "earned": 92999138821, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "tx_hash": "6e96414550ec512d2272497e3e2cbc908ec472cc1b871d82f51a9a66af3cf148", "tx_index": 104}',0);
INSERT INTO messages VALUES(65,310104,'insert','credits','{"action": "burn", "address": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b", "asset": "XCP", "block_index": 310104, "event": "1f4e8d91b61fff6132ee060b80008f7739e8215282a5bd7c57fe088c056d9f72", "quantity": 92999130460}',0);
INSERT INTO messages VALUES(66,310104,'insert','burns','{"block_index": 310104, "burned": 62000000, "earned": 92999130460, "source": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b", "status": "valid", "tx_hash": "1f4e8d91b61fff6132ee060b80008f7739e8215282a5bd7c57fe088c056d9f72", "tx_index": 105}',0);
INSERT INTO messages VALUES(67,310105,'insert','credits','{"action": "burn", "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "asset": "XCP", "block_index": 310105, "event": "3152127f7b6645e8b066f6691aeed95fa38f404df85df1447c320b38a79240c6", "quantity": 92999122099}',0);
INSERT INTO messages VALUES(68,310105,'insert','burns','{"block_index": 310105, "burned": 62000000, "earned": 92999122099, "source": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "status": "valid", "tx_hash": "3152127f7b6645e8b066f6691aeed95fa38f404df85df1447c320b38a79240c6", "tx_index": 106}',0);
INSERT INTO messages VALUES(69,310491,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310491, "event": "9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b", "quantity": 100000000}',0);
INSERT INTO messages VALUES(70,310491,'insert','orders','{"block_index": 310491, "expiration": 2000, "expire_index": 312491, "fee_provided": 10000, "fee_provided_remaining": 10000, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 800000, "get_remaining": 800000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b", "tx_index": 492}',0);
INSERT INTO messages VALUES(71,310492,'insert','orders','{"block_index": 310492, "expiration": 2000, "expire_index": 312492, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 800000, "give_remaining": 800000, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "tx_hash": "14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0", "tx_index": 493}',0);
INSERT INTO messages VALUES(72,310492,'update','orders','{"fee_provided_remaining": 10000, "fee_required_remaining": 892800, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b"}',0);
INSERT INTO messages VALUES(73,310492,'update','orders','{"fee_provided_remaining": 992800, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0"}',0);
INSERT INTO messages VALUES(74,310492,'insert','order_matches','{"backward_asset": "BTC", "backward_quantity": 800000, "block_index": 310492, "fee_paid": 7200, "forward_asset": "XCP", "forward_quantity": 100000000, "id": "9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b_14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0", "match_expire_index": 310512, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 310491, "tx0_expiration": 2000, "tx0_hash": "9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b", "tx0_index": 492, "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_block_index": 310492, "tx1_expiration": 2000, "tx1_hash": "14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0", "tx1_index": 493}',0);
INSERT INTO messages VALUES(75,310493,'insert','credits','{"action": "burn", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310493, "event": "d6adfa92e20b6211ff5fabb2f7a1c8b037168797984c94734c28e82e92d3b1d6", "quantity": 92995878046}',0);
INSERT INTO messages VALUES(76,310493,'insert','burns','{"block_index": 310493, "burned": 62000000, "earned": 92995878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "d6adfa92e20b6211ff5fabb2f7a1c8b037168797984c94734c28e82e92d3b1d6", "tx_index": 494}',0);
INSERT INTO messages VALUES(77,310494,'insert','debits','{"action": "issuance fee", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310494, "event": "084102fa0722f5520481f34eabc9f92232e4d1647b329b3fa58bffc8f91c5e4e", "quantity": 50000000}',0);
INSERT INTO messages VALUES(78,310494,'insert','issuances','{"asset": "DIVIDEND", "block_index": 310494, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Test dividend", "divisible": true, "fee_paid": 50000000, "issuer": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "locked": false, "quantity": 100, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "transfer": false, "tx_hash": "084102fa0722f5520481f34eabc9f92232e4d1647b329b3fa58bffc8f91c5e4e", "tx_index": 495}',0);
INSERT INTO messages VALUES(79,310494,'insert','credits','{"action": "issuance", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310494, "event": "084102fa0722f5520481f34eabc9f92232e4d1647b329b3fa58bffc8f91c5e4e", "quantity": 100}',0);
INSERT INTO messages VALUES(80,310495,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310495, "event": "9d3391348171201de9b5eb70ca80896b0ae166fd51237c843a90c1b4ccf8c602", "quantity": 10}',0);
INSERT INTO messages VALUES(81,310495,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "DIVIDEND", "block_index": 310495, "event": "9d3391348171201de9b5eb70ca80896b0ae166fd51237c843a90c1b4ccf8c602", "quantity": 10}',0);
INSERT INTO messages VALUES(82,310495,'insert','sends','{"asset": "DIVIDEND", "block_index": 310495, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 10, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "9d3391348171201de9b5eb70ca80896b0ae166fd51237c843a90c1b4ccf8c602", "tx_index": 496}',0);
INSERT INTO messages VALUES(83,310496,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310496, "event": "54f4c7b383ea19147e62d2be9f3e7f70b6c379baac15e8b4cf43f7c21578c1ef", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(84,310496,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "XCP", "block_index": 310496, "event": "54f4c7b383ea19147e62d2be9f3e7f70b6c379baac15e8b4cf43f7c21578c1ef", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(85,310496,'insert','sends','{"asset": "XCP", "block_index": 310496, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 92945878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "54f4c7b383ea19147e62d2be9f3e7f70b6c379baac15e8b4cf43f7c21578c1ef", "tx_index": 497}',0);
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
INSERT INTO transactions VALUES(18,'3369be793bff1ec8bb0ad342bf5ce5c24a9298c4cb5660b0c41a32d6fb06babe',310017,'4c02945de20ccdc874ae21bf56aea2f40a029c17b81fcf602b367bdbc286f9ec0cacab35fc07ac60aefa4a96a586aed20129ad66d45ab87697704d731e06b40d',310017000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000001E52BB33003FF0000000000000004C4B40556E69742054657374',1);
INSERT INTO transactions VALUES(19,'88c74d84fd6121123b092877283a5e4e1aca4f59d18d643c8347ed756020a846',310018,'6a26d120314af1710052c8f8f78453f944a146039679c781e04ddbb5a2d010927726fa6f81d3e01fc1fcc3363c06e8e1a81a35636684c4dbcd51edf561a9c0fc',310018000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','',0,10000,X'0000001E4CC552003FF0000000000000000000006C6F636B',1);
INSERT INTO transactions VALUES(20,'be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd',310019,'592e775a9259b1a5a7b0d7c2e028ff320783e7b49243ed6a20ece89a72964f3af4ed129698c4a143ad682a1493f982c5f8193d3b0e36b3df43964520409beb7a',310019000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,10000,X'00000028000152BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(21,'90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5',310020,'87fac74eef20e6121d9a66c90481f801a10d636976a6a6e7cf42fc38cc104a470e1b4cab3f9670be86c93ec1a407a1b464599121df6c8109ec7247b25c7efc62',310020000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,10000,X'00000028000052BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(102,'ba0ef1dfbbc87df94e1d198b0e9e3c06301710d4aab3d85116cbc8199954644a',310101,'e8a8ebd85a460cf5987683360a1c77e6728b4e59027220f8eceda05c720bc38c91f6193bc43739da026cd28f340e1a10b9900bfa3eed11f88339147c61b65504',310101000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,10000,X'00000028000352BB33C8000000000000000A000000000000000A0000000000000000000013B0000003E8',1);
INSERT INTO transactions VALUES(103,'d5879170168ed84a20ff86bfdb2ca7d9b74bdbf1c39b9a606cacc34429be9364',310102,'767209a2b49c4e2aef6ef3fae88ff8bb450266a5dc303bbaf1c8bfb6b86cf835053b6a4906ae343265125f8d3b773c5bd4111451410b18954ad76c8a9aff2046',310102000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000001E52BB33023FF0000000000000004C4B40556E69742054657374',1);
INSERT INTO transactions VALUES(104,'6e96414550ec512d2272497e3e2cbc908ec472cc1b871d82f51a9a66af3cf148',310103,'e9041ceed8f1db239510cc8d28e5abc3f2c781097b184faae934b577b78c54435a4205ee895ccabd5c5e06ff3b19c17a0a6f5f124a95d34b3d06d1444afb996a',310103000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,-99990000,X'',1);
INSERT INTO transactions VALUES(105,'1f4e8d91b61fff6132ee060b80008f7739e8215282a5bd7c57fe088c056d9f72',310104,'04faacf3df57c1af43f1211679d90f0cb6a3de4620323226a87e134392d4b8f7fc5d15f4342bee5bff0f206a64183c706d751bdace2b68c0107e237d77bb0ebb',310104000,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,-99990000,X'',1);
INSERT INTO transactions VALUES(106,'3152127f7b6645e8b066f6691aeed95fa38f404df85df1447c320b38a79240c6',310105,'673579ef7bc7828b4427a7144355901327f4cd6e14a8ee356caa1a556eb15f88d6f8f599556590f9f00979dc4d4cde4ff5ea7e2ae683e2a14706fc03aed8ecbc',310105000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,-99990000,X'',1);
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
INSERT INTO undolog VALUES(113,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92050000000 WHERE rowid=1');
INSERT INTO undolog VALUES(114,'DELETE FROM debits WHERE rowid=19');
INSERT INTO undolog VALUES(115,'DELETE FROM orders WHERE rowid=5');
INSERT INTO undolog VALUES(116,'DELETE FROM orders WHERE rowid=6');
INSERT INTO undolog VALUES(117,'UPDATE orders SET tx_index=492,tx_hash=''9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b'',block_index=310491,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''XCP'',give_quantity=100000000,give_remaining=100000000,get_asset=''BTC'',get_quantity=800000,get_remaining=800000,expiration=2000,expire_index=312491,fee_required=900000,fee_required_remaining=900000,fee_provided=10000,fee_provided_remaining=10000,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(118,'UPDATE orders SET tx_index=493,tx_hash=''14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0'',block_index=310492,source=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',give_asset=''BTC'',give_quantity=800000,give_remaining=800000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=2000,expire_index=312492,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=6');
INSERT INTO undolog VALUES(119,'DELETE FROM order_matches WHERE rowid=1');
INSERT INTO undolog VALUES(120,'DELETE FROM balances WHERE rowid=16');
INSERT INTO undolog VALUES(121,'DELETE FROM credits WHERE rowid=21');
INSERT INTO undolog VALUES(122,'DELETE FROM burns WHERE rowid=494');
INSERT INTO undolog VALUES(123,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''XCP'',quantity=92995878046 WHERE rowid=16');
INSERT INTO undolog VALUES(124,'DELETE FROM debits WHERE rowid=20');
INSERT INTO undolog VALUES(125,'DELETE FROM assets WHERE rowid=8');
INSERT INTO undolog VALUES(126,'DELETE FROM issuances WHERE rowid=495');
INSERT INTO undolog VALUES(127,'DELETE FROM balances WHERE rowid=17');
INSERT INTO undolog VALUES(128,'DELETE FROM credits WHERE rowid=22');
INSERT INTO undolog VALUES(129,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''DIVIDEND'',quantity=100 WHERE rowid=17');
INSERT INTO undolog VALUES(130,'DELETE FROM debits WHERE rowid=21');
INSERT INTO undolog VALUES(131,'DELETE FROM balances WHERE rowid=18');
INSERT INTO undolog VALUES(132,'DELETE FROM credits WHERE rowid=23');
INSERT INTO undolog VALUES(133,'DELETE FROM sends WHERE rowid=496');
INSERT INTO undolog VALUES(134,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''XCP'',quantity=92945878046 WHERE rowid=16');
INSERT INTO undolog VALUES(135,'DELETE FROM debits WHERE rowid=22');
INSERT INTO undolog VALUES(136,'DELETE FROM balances WHERE rowid=19');
INSERT INTO undolog VALUES(137,'DELETE FROM credits WHERE rowid=24');
INSERT INTO undolog VALUES(138,'DELETE FROM sends WHERE rowid=497');

-- Table  undolog_block
DROP TABLE IF EXISTS undolog_block;
CREATE TABLE undolog_block(
                        block_index INTEGER PRIMARY KEY,
                        first_undo_index INTEGER);
INSERT INTO undolog_block VALUES(310400,113);
INSERT INTO undolog_block VALUES(310401,113);
INSERT INTO undolog_block VALUES(310402,113);
INSERT INTO undolog_block VALUES(310403,113);
INSERT INTO undolog_block VALUES(310404,113);
INSERT INTO undolog_block VALUES(310405,113);
INSERT INTO undolog_block VALUES(310406,113);
INSERT INTO undolog_block VALUES(310407,113);
INSERT INTO undolog_block VALUES(310408,113);
INSERT INTO undolog_block VALUES(310409,113);
INSERT INTO undolog_block VALUES(310410,113);
INSERT INTO undolog_block VALUES(310411,113);
INSERT INTO undolog_block VALUES(310412,113);
INSERT INTO undolog_block VALUES(310413,113);
INSERT INTO undolog_block VALUES(310414,113);
INSERT INTO undolog_block VALUES(310415,113);
INSERT INTO undolog_block VALUES(310416,113);
INSERT INTO undolog_block VALUES(310417,113);
INSERT INTO undolog_block VALUES(310418,113);
INSERT INTO undolog_block VALUES(310419,113);
INSERT INTO undolog_block VALUES(310420,113);
INSERT INTO undolog_block VALUES(310421,113);
INSERT INTO undolog_block VALUES(310422,113);
INSERT INTO undolog_block VALUES(310423,113);
INSERT INTO undolog_block VALUES(310424,113);
INSERT INTO undolog_block VALUES(310425,113);
INSERT INTO undolog_block VALUES(310426,113);
INSERT INTO undolog_block VALUES(310427,113);
INSERT INTO undolog_block VALUES(310428,113);
INSERT INTO undolog_block VALUES(310429,113);
INSERT INTO undolog_block VALUES(310430,113);
INSERT INTO undolog_block VALUES(310431,113);
INSERT INTO undolog_block VALUES(310432,113);
INSERT INTO undolog_block VALUES(310433,113);
INSERT INTO undolog_block VALUES(310434,113);
INSERT INTO undolog_block VALUES(310435,113);
INSERT INTO undolog_block VALUES(310436,113);
INSERT INTO undolog_block VALUES(310437,113);
INSERT INTO undolog_block VALUES(310438,113);
INSERT INTO undolog_block VALUES(310439,113);
INSERT INTO undolog_block VALUES(310440,113);
INSERT INTO undolog_block VALUES(310441,113);
INSERT INTO undolog_block VALUES(310442,113);
INSERT INTO undolog_block VALUES(310443,113);
INSERT INTO undolog_block VALUES(310444,113);
INSERT INTO undolog_block VALUES(310445,113);
INSERT INTO undolog_block VALUES(310446,113);
INSERT INTO undolog_block VALUES(310447,113);
INSERT INTO undolog_block VALUES(310448,113);
INSERT INTO undolog_block VALUES(310449,113);
INSERT INTO undolog_block VALUES(310450,113);
INSERT INTO undolog_block VALUES(310451,113);
INSERT INTO undolog_block VALUES(310452,113);
INSERT INTO undolog_block VALUES(310453,113);
INSERT INTO undolog_block VALUES(310454,113);
INSERT INTO undolog_block VALUES(310455,113);
INSERT INTO undolog_block VALUES(310456,113);
INSERT INTO undolog_block VALUES(310457,113);
INSERT INTO undolog_block VALUES(310458,113);
INSERT INTO undolog_block VALUES(310459,113);
INSERT INTO undolog_block VALUES(310460,113);
INSERT INTO undolog_block VALUES(310461,113);
INSERT INTO undolog_block VALUES(310462,113);
INSERT INTO undolog_block VALUES(310463,113);
INSERT INTO undolog_block VALUES(310464,113);
INSERT INTO undolog_block VALUES(310465,113);
INSERT INTO undolog_block VALUES(310466,113);
INSERT INTO undolog_block VALUES(310467,113);
INSERT INTO undolog_block VALUES(310468,113);
INSERT INTO undolog_block VALUES(310469,113);
INSERT INTO undolog_block VALUES(310470,113);
INSERT INTO undolog_block VALUES(310471,113);
INSERT INTO undolog_block VALUES(310472,113);
INSERT INTO undolog_block VALUES(310473,113);
INSERT INTO undolog_block VALUES(310474,113);
INSERT INTO undolog_block VALUES(310475,113);
INSERT INTO undolog_block VALUES(310476,113);
INSERT INTO undolog_block VALUES(310477,113);
INSERT INTO undolog_block VALUES(310478,113);
INSERT INTO undolog_block VALUES(310479,113);
INSERT INTO undolog_block VALUES(310480,113);
INSERT INTO undolog_block VALUES(310481,113);
INSERT INTO undolog_block VALUES(310482,113);
INSERT INTO undolog_block VALUES(310483,113);
INSERT INTO undolog_block VALUES(310484,113);
INSERT INTO undolog_block VALUES(310485,113);
INSERT INTO undolog_block VALUES(310486,113);
INSERT INTO undolog_block VALUES(310487,113);
INSERT INTO undolog_block VALUES(310488,113);
INSERT INTO undolog_block VALUES(310489,113);
INSERT INTO undolog_block VALUES(310490,113);
INSERT INTO undolog_block VALUES(310491,113);
INSERT INTO undolog_block VALUES(310492,116);
INSERT INTO undolog_block VALUES(310493,120);
INSERT INTO undolog_block VALUES(310494,123);
INSERT INTO undolog_block VALUES(310495,129);
INSERT INTO undolog_block VALUES(310496,134);
INSERT INTO undolog_block VALUES(310497,139);
INSERT INTO undolog_block VALUES(310498,139);
INSERT INTO undolog_block VALUES(310499,139);
INSERT INTO undolog_block VALUES(310500,139);

-- For primary key autoincrements the next id to use is stored in
-- sqlite_sequence
DELETE FROM main.sqlite_sequence WHERE name='undolog';
INSERT INTO main.sqlite_sequence VALUES ('undolog', 138);

COMMIT TRANSACTION;
