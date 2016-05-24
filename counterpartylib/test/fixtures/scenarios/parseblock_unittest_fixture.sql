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
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',91950000000);
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
INSERT INTO balances VALUES('myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','XCP',92999138821);
INSERT INTO balances VALUES('munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','XCP',92999130460);
INSERT INTO balances VALUES('mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',92999122099);
INSERT INTO balances VALUES('2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',46449556859);
INSERT INTO balances VALUES('2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','PAYTOSCRIPT',1000);
INSERT INTO balances VALUES('2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000);
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
INSERT INTO bets VALUES(111,'81f8ba670b22980b15c944dcd478a274723659d768b0de73b014d06d214e5b90',310110,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',3,1388000200,10,10,10,10,0.0,5040,1000,311110,5000000,'open');
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
INSERT INTO blocks VALUES(310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,NULL,NULL,'f3e1d432b546670845393fae1465975aa99602a7648e0da125e6b8f4d55cbcac','0fc8b9a115ba49c78879c5d75b92bdccd2f5e398e8e8042cc9d0e4568cea9f53','88838f2cfc1eef675714adf7cfef07e7934a12ae60cfa75ca571888ef3d47b5c');
INSERT INTO blocks VALUES(310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,NULL,NULL,'6a91073b35d1151c0b9b93f7916d25e6650b82fe4a1b006851d69b1112cd2954','490572196d4b3d303697f55cc9bf8fe29a4ae659dfc51f63a6af37cb5593413b','0e5a1d103303445b9834b0a01d1179e522ff3389a861f0517b2ee061a9bc1c57');
INSERT INTO blocks VALUES(310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,NULL,NULL,'88eac1faa671a7ebc61f63782c4b74d42c813c19e410e240843440f4d4dbaa35','e944f6127f7d13409ace137a670d1503a5412488942fdf7e858fcd99b70e4c2a','d5e23e344547beb15ed6eb88f54504d2f4a8062279e0053a2c9c679655e1870c');
INSERT INTO blocks VALUES(310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,NULL,NULL,'93d430c0d7a680aad6fb162af200e95e177ba5d604df1e3cb0e086d3959538c3','d9ba1ab8640ac01642eacf28d3f618a222cc40377db418b1313d880ecb88bce8','c3371ad121359321f66af210da3f7d35b83d45074720a18cb305508ad5a60229');
INSERT INTO blocks VALUES(310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,NULL,NULL,'e85e5d82a20fe2e060a7c1f79dc182d3b2da28903b04302e6abe4a3f935ea373','acc9a12b365f51aa9efbe5612f812bf926ef8e5e3bf057c42877aeea1049ee49','ca4856a25799772f900671b7965ecdc36a09744654a1cd697f18969e22850b8a');
INSERT INTO blocks VALUES(310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,NULL,NULL,'c6c0f780ffa18de5a5e5afdf4fba5b6a17dce8d767d4b7a9fbbae2ad53ff4718','e9410f15a3b9c93d8416d57295d3a8e03d6313eb73fd2f00678d2f3a8f774e03','db34d651874da19cf2a4fcf50c44f4be7c6e40bc5a0574a46716f10c235b9c43');
INSERT INTO blocks VALUES(310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,NULL,NULL,'91458f37f5293fca71cddc6f14874670584e750aa68fbe577b22eac357c5f336','ed50224a1ca02397047900e5770da64a9eb6cb62b6b5b4e57f12d08c5b57ab93','c909c99a5218c152196071f4df6c3dfa2cfdaa70af26e3fc6a490a270ff29339');
INSERT INTO blocks VALUES(310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,NULL,NULL,'a8f0f81aebdf77ee1945c2199142696f2c74518f2bc1a45dcfd3cebcabec510c','1635973c36f5d7efc3becc95a2667c1bb808edc692ff28eaa5f5849b7cdb4286','fb670f2509a3384f1c75cfa89770da9f9315cbda733fd6cdb1db89e7bbc80608');
INSERT INTO blocks VALUES(310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,NULL,NULL,'df7cae2ef1885eb5916f821be0bb11c24c9cabdc6ccdc84866d60de6af972b94','e7dde4bb0a7aeab7df2cd3f8a39af3d64dd98ef64efbc253e4e6e05c0767f585','4e11197b5662b57b1e8b21d196f1d0bae927e36c4b4634539dd63b1df8b7aa99');
INSERT INTO blocks VALUES(310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,NULL,NULL,'1d8caac58a9e5a656a6631fe88be72dfb45dbc25c64d92558db268be01da6024','74b7425efb6832f9cd6ffea0ae5814f192bb6d00c36603700af7a240f878da95','fc53cd08e684798b74bb5b282b72ea18166a7ae83a64ff9b802ae3e3ea6c1d13');
INSERT INTO blocks VALUES(310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,NULL,NULL,'ab78a209c465104945458dba209c03409f839d4882a1bf416c504d26fd8b9c80','d4bdc625dead1b87056b74aa843ae9b47a1b61bb63aafc32a04137d5022d67e4','2398b32d34b43c20a0965532863ed3ddd21ee095268ba7d8933f31e417a3689e');
INSERT INTO blocks VALUES(310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,NULL,NULL,'5528fec20bfacc31dd43d7284bf1df33e033ec0ac12b14ed813a9dfea4f67741','205fad5e739d6736a483dde222d3fdfc0014a5af1fa1981e652a0fe948d883b3','3f9d7e91b4cfc760c5fa6805975002c258a48e2bc0a9e754bcc69be8e0cb74e5');
INSERT INTO blocks VALUES(310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,NULL,NULL,'fa66dc025cbb75b67a7d4c496141eb5f6f0cc42134433276c8a294c983453926','ff933c5dfc4364dc6fa3faa2d5da4096bd1261cc53f74a20af9e55a4dda2d08b','1993f3234c4025eab5bb95ac516594b99c4068b1352652f0327f4fa6c8684d17');
INSERT INTO blocks VALUES(310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,NULL,NULL,'442621791a488568ee9dee5d9131db3ce2f17d9d87b4f45dc8079606874823f8','337f673aa1457d390abc97512fbaa5590e4f5e06d663e82627f70fd23c558655','dbe86ee55a221aa0541367039bb0f51ccac45530dd78b0a9b0292b175cef6e56');
INSERT INTO blocks VALUES(310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,NULL,NULL,'8551367f346e50b15c6e0cca116d1697d3301725b73562f62d8e4c53581e7bd0','f1f9d937b2f6f2221055c9f967207accd58a388a33677fd7572c882ce2e65b0e','9e054d7d63e96da38b2bb4715a627e3f4f322b8d86a8ad569a9e2e780c036f46');
INSERT INTO blocks VALUES(310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,NULL,NULL,'29de016d6301c2c9be33c98d3ca3e5f2dd25d52fd344426d40e3b0126dea019a','e0051523f6891110c18a2250db797d39d6ffd917aeb446906f8059b293e20be6','98ac9ef994c9b058395d5726fb29303fb90ae1cb4130535c9a9525e61dda0702');
INSERT INTO blocks VALUES(310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,NULL,NULL,'32ffd4bdf9b1f8506a25b4d2affe792d1eccf322a9ab832ec71a934fea136db9','0c90d5431f84b4fd0739bfe750ddd2b65f1bfee26f3b576f2df5dc77537389ab','8588b5ccadd1f93f8bce990c723efb6118b90d4491cc7ada4cda296469f5a635');
INSERT INTO blocks VALUES(310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,NULL,NULL,'64aa58f7e48dfa10bb48ecf48571d832bb94027c7ac07be0d23d5379452ce03b','ee2aa8e8b5c16ff20dc4a37c5483c7b1b9498b3f77cab630c910e29540c3a4f9','a5b974e881ec4e947974f2441f5af722673d08e55dc3daa5d5e0a717080962bf');
INSERT INTO blocks VALUES(310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,NULL,NULL,'8d8f404bdc2fb6178286b2581cf8a23e6028d5d285091fa0e67e96e6da91f54e','be9eab485a9d7cba91072ae17389b123dc865fd84b70750f225c76dcdaac1f27','65f30e31bc64ea4f4a2cb6db890a5769b97b32e0bf3a992302b619bfac0af60e');
INSERT INTO blocks VALUES(310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,NULL,NULL,'945a8fd2f57cfd5ddab542291fb2e2813762806b806a3e65e688321fefe1986d','7f518d7dec7a31e52840d975a26c5d96d3a202d30d4977205fc14cf76b93dcf2','da444b5d4accf056c6fade57c38869d51a3d9ca102df5c937675398b4b6060b0');
INSERT INTO blocks VALUES(310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,NULL,NULL,'3393abc111ee337132103ca04b4f8745952cd03ddbd6efff58a589e00a48fa21','50cc106fcf8581a7d1ea0ccdc6c5251b6f36b6a64f12581ab77ab339bb112ec4','ee59a8bb5eafdaf12ad7c8e55a19060451a959b03a9fe0b23a5628f680b04b6e');
INSERT INTO blocks VALUES(310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,NULL,NULL,'d05fe9705db7b30e6ea6b18e9ae92ba794dd72f25b4e33daf4d46b3b609a02de','648f5633ea84b04f3c82873eb245f1632b00e61112a79632e4608be8915d80f9','1dfc96f94d02b90f20c16923937b21a5701ab03699f647bb08e0d1ae0258171b');
INSERT INTO blocks VALUES(310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,NULL,NULL,'c2b2b2c3bdd895c74f3ea22db3d9c66301578436b6fa9175ce0b242c4bfaccc5','26bf7bb14922abb270a25ae77abb45a09271deb901c22dc304b019d610f06f3d','5538c6d7b34b2b2e0c08106feeeea791542e1740ab8dd6fdd8be9cf4dfc17d83');
INSERT INTO blocks VALUES(310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,NULL,NULL,'fad5b61545d8ef317918f07df063554d4f321c0ebf462f759513212960bdf523','cb647a71c09e5bf06576afbd426ddf13e2151e819b07efb2929db444769e4531','9e420592fcb4ba1bb1fc537ef50f118992964090e525d62c6f47abbf65fd6329');
INSERT INTO blocks VALUES(310024,'b03042b4e18a222b4c8d1e9e1970d93e6e2a2d41686d227ff8ecf0a839223dc5',310024000,NULL,NULL,'61a71d0ac67eba15c63a531f797e6d68c83613489730bc2b4e4054094f63105a','b3990893e9f8f00cefb139c043815e301e951cb919c59e58644034b33551b480','1aa35c67d550dd3e39d6b1e99cee07decd694edba633db9295c72207d793cdc7');
INSERT INTO blocks VALUES(310025,'a872e560766832cc3b4f7f222228cb6db882ce3c54f6459f62c71d5cd6e90666',310025000,NULL,NULL,'f7d41404c3d1e57bbc390af958d1596212112068e4986954d11ff8abd13bc8e4','540d181af55b17757869eb48ef4050732f4bb8d7bb4667793e05770f33dd7f4a','23ddec44887f0d9d638316bcf4524e4a107f7b8f1c2739ebbd3dc160196d0524');
INSERT INTO blocks VALUES(310026,'6c96350f6f2f05810f19a689de235eff975338587194a36a70dfd0fcd490941a',310026000,NULL,NULL,'31530d7febb577d7588e12d10629fd82966df48a93a613a480879531d5dbd374','26a5ce353f383d9bf732d119bf947380fbf7cb7c10d9b65711da6d08f940b692','55fa2a20ec89af2c4cc82aba44c0028fbaf0f166f0cd2dc5c9d02d9e6f4b657f');
INSERT INTO blocks VALUES(310027,'d7acfac66df393c4482a14c189742c0571b89442eb7f817b34415a560445699e',310027000,NULL,NULL,'f54085346ae4608c57c55d321a413a00ffeb85499138559d7d05245f57cc0da3','21eb7db4dff69979f960b34b3d8632d417be2d9087399beaf50cf3a945c101e9','19d6fcff51a87f131362e8bd7f8bbd800e985cd54321ba8a233e3341bff64d11');
INSERT INTO blocks VALUES(310028,'02409fcf8fa06dafcb7f11e38593181d9c42cc9d5e2ddc304d098f990bd9530b',310028000,NULL,NULL,'a841b7f634fc24553d1c8cb2d66fc3103293dcfd297cb5bf241b0c5da84bd376','d8f78dad14405cbd461ccfcacbfdc544ca5e603df3d3021b58d5393560e0d56f','4359591ae7f06509856433c765a1ac49724211e941408c17f3cf28853758a13d');
INSERT INTO blocks VALUES(310029,'3c739fa8b40c118d5547ea356ee8d10ee2898871907643ec02e5db9d00f03cc6',310029000,NULL,NULL,'69d40c69b4989f7a59da99b56577b0651887d9422757e38d5410379f95fda641','ba57b2e4eb9132feaa3380491358c8706c44204f7f7a4f7f0060a3ff8a640b97','243c7e0f8a44221eeb8a0e448d7ba8bd8372e6c3a76a6e9b36ddada846d9e43e');
INSERT INTO blocks VALUES(310030,'d5071cddedf89765ee0fd58f209c1c7d669ba8ea66200a57587da8b189b9e4f5',310030000,NULL,NULL,'192fe51d3a7af659670a8899582c29aedf3a5608ca906b274ce986751dad2d7a','29663f45b5eae8b77bb8ec5351e0012efdf03a17fa5d132dd8da0f432acaf9e0','91193c1f216574251bed7b42946b450587bd765a4b5f4138924dde66e3fd9297');
INSERT INTO blocks VALUES(310031,'0b02b10f41380fff27c543ea8891ecb845bf7a003ac5c87e15932aff3bfcf689',310031000,NULL,NULL,'125784cdeba1e433b3411c368cdf676efb33021f51c26a8b2bd6ec00fe4f767d','fe36b2450774dfc7db346c45833fbd401d8a234ce87544cd9b373cbc4b79b61a','267edd0d998a1957ac14462b1a5af7055297ed1034e995123512c0d17654e6b7');
INSERT INTO blocks VALUES(310032,'66346be81e6ba04544f2ae643b76c2b7b1383f038fc2636e02e49dc7ec144074',310032000,NULL,NULL,'fa7832080a2b6ae8829794d70603351755fa4816f15a6e92716f83265daa59a4','258bea96c9e1d774eb0fedc7fe99a328b62ee26f557426d036147d1eea033e04','17d2cb78af47a0cb58a0191eacdce2b7c3f27d4ddc342fb11f619ecebc42ae94');
INSERT INTO blocks VALUES(310033,'999c65df9661f73e8c01f1da1afda09ac16788b72834f0ff5ea3d1464afb4707',310033000,NULL,NULL,'7b86f430bc44ad5d81a43b5a8ea118b458d995e3832d88bb74bc62429194e45c','ce67ed4dddf1582ac85c4825c5f9d059e6c64542e5d0fa6f489858008948a989','b3834107703858d2f18470e6d6f939d756c9e6a6407a40a78cec8636832749a2');
INSERT INTO blocks VALUES(310034,'f552edd2e0a648230f3668e72ddf0ddfb1e8ac0f4c190f91b89c1a8c2e357208',310034000,NULL,NULL,'1f2c5ac4375f77fb79612d343dd5fc4489cf94ff983fc05ba2009a9e390d6c06','4e7e92c9296993b9469c9388ba23e9a5696070ee7e42b09116e45c6078746d00','0ff41ea30f20b7bf90c66003f29d41bf7bd7c526881db0b645bc1a76911afb63');
INSERT INTO blocks VALUES(310035,'a13cbb016f3044207a46967a4ba1c87dab411f78c55c1179f2336653c2726ae2',310035000,NULL,NULL,'81cdae9b978935ad40a1032e7f22ddd7117b9c7580d6d7e4b7e20d1c875f5e63','98919ef5963b86630a60e75cef8b95f24508d65d29c534811a92ed5016cc14dd','7bf7cdcf88fde6747b8ad3477bb1ea645cfb95ff7d6cfeeab33c87eee54cf744');
INSERT INTO blocks VALUES(310036,'158648a98f1e1bd1875584ce8449eb15a4e91a99a923bbb24c4210135cef0c76',310036000,NULL,NULL,'ff02952dce15c249501d8485decad0ad9fe02fda766b7b83720806f726d02ee4','ef9adfbd23bebd3c047db6d82d7d0ca0479bd14fcfeb95b9a4ef6963d7294b99','623dd05dbd17d04175b720d8b1d37b9137f1ea83ddfb4c98ba2c91dfa5f4df46');
INSERT INTO blocks VALUES(310037,'563acfd6d991ce256d5655de2e9429975c8dceeb221e76d5ec6e9e24a2c27c07',310037000,NULL,NULL,'760e5a00feb6c8c4baf4421ad07be2af962bfcac7705b773484b449356d6c230','51cbb75a27acf3a67b54f6b64a4f4b86d511fe3d6fe29526fe26238e44a3bd4b','a8dfa56a89e1475996abb64ba1b4ccc878c44540b31bbdfd937b61db889d4dce');
INSERT INTO blocks VALUES(310038,'b44b4cad12431c32df27940e18d51f63897c7472b70950d18454edfd640490b2',310038000,NULL,NULL,'c79381c51fa93cc320d8bf19c943f98232a99446ac098ff66823cf691e0fa01c','cd45648e95377f9c8503ba747cd2a7312ac0c9108316eb5a77a06fb9fd0df474','7f15dd0f7c34494fc4c0a1fab509d3de57867acb7277a4e505cbdd0486457330');
INSERT INTO blocks VALUES(310039,'5fa1ae9c5e8a599247458987b006ad3a57f686df1f7cc240bf119e911b56c347',310039000,NULL,NULL,'7382f007315783c9a6ffd29bc0eaa62282c6ec72c5fff09322d6dea6b0ee3a96','ffe0bc6eeace43428a31476e259bf5dfe33c33f70c18001504f158d4be026b5c','cec197d33ac2efeb87943aa58e10272cf7bd662984a64929e18530e4c839f73b');
INSERT INTO blocks VALUES(310040,'7200ded406675453eadddfbb2d14c2a4526c7dc2b5de14bd48b29243df5e1aa3',310040000,NULL,NULL,'38d3b548be554a0ae92504244a88930b989ea6fefc9bc59c69b68ed560afee9a','3a96f2cea7c289afdd0b6c987bc0081a8726d08eb19bfe3eb9b518442324fe16','f972ad30b7564a70a05264cabff7dbdc6f43fcf97cc2c253031d7df804622135');
INSERT INTO blocks VALUES(310041,'5db592ff9ba5fac1e030cf22d6c13b70d330ba397f415340086ee7357143b359',310041000,NULL,NULL,'0c1c7aa19c015a67da214bf8a6ae3d77979a09de6a63621e320a28ceebdbf333','9f35a2e8a94c8a81ddedfc9b0178d7a07f42fee1221b6eca038edc16b4f32495','d98a7e2b0a03a6fe91fc8a5a51412d00b9130f0b1906238085fa917536998212');
INSERT INTO blocks VALUES(310042,'826fd4701ef2824e9559b069517cd3cb990aff6a4690830f78fc845ab77fa3e4',310042000,NULL,NULL,'9d20f77d4afff9179cffe46574f1b2dd23d2987142c943de05e411baee2dbf05','9ba21b4c3e4696a8558752ae8f24a407f19827a2973c34cc38289693ea8fe011','5b9e3fda69ff3d175c5871d2c26513b82479e30c3612bef95b03b4d9a64cf33b');
INSERT INTO blocks VALUES(310043,'2254a12ada208f1dd57bc17547ecaf3c44720323c47bc7d4b1262477cb7f3c51',310043000,NULL,NULL,'d818e5a1a5cb6c59771b63997a8737cdb041c3579de1ecd808a269f5d72a3abf','ea9ae316a3d419d8d383d8cd5879757e67825eaba0f0f22455bdee39be6b3986','16d9fdbb509f0abe6ad2824a85e059a01d733ecdbb3d02d3dc5f2172020b348a');
INSERT INTO blocks VALUES(310044,'3346d24118d8af0b3c6bcc42f8b85792e7a2e7036ebf6e4c25f4f6723c78e46b',310044000,NULL,NULL,'9de166ff18c5eec97b838292ae894ce18e5a890e8a841a294b2d14894c60a0d7','5ed66185648c567cd211fa03b6d887f21854c231743ad20885a83073bf68b1e2','597f45d7ce19813ff9473721f0897baac61e97d11608d1d6e209efddaa67dadd');
INSERT INTO blocks VALUES(310045,'7bba0ab243839e91ad1a45a762bf074011f8a9883074d68203c6d1b46fffde98',310045000,NULL,NULL,'bb3c0a260dc082534c95e894751e38e80de117b091bc0e34c66134d374b8db2d','638e948d625f063dfd65ebc57bb7d87ecfb5b99322ee3a1ab4fa0acb704f581f','c2c57a8b58f7b19acec45896093fff26c73994bb7b2a849e42a38d50ff7c8610');
INSERT INTO blocks VALUES(310046,'47db6788c38f2d6d712764979e41346b55e78cbb4969e0ef5c4336faf18993a6',310046000,NULL,NULL,'b4605c50ee3e5e2958c908e099563cf997e20932cc2370109ab50049e43723cf','8e4ef49f870af7dde396a108f4c1d5c4286a302a573c1bb1b6a45c423dc7cd2b','4dbab042d742d2548ce81853ae36a362faa304090b2fd8686793fae0e3090cf5');
INSERT INTO blocks VALUES(310047,'a9ccabcc2a098a7d25e4ab8bda7c4e66807eefa42e29890dcd88149a10de7075',310047000,NULL,NULL,'b840a7af6301c798c9a6670308a2684051ff8f3fb2e69bddaafa82cfd3d83186','1e61e70016a9c18765c2332d9b3e7a64e119a7dbf533256fc1b88f36c2404055','c1100a1111baa1ad9f7fb39c146b78b65c427741e91617fc1f1637a16bf62380');
INSERT INTO blocks VALUES(310048,'610bf3935a85b05a98556c55493c6de45bed4d7b3b6c8553a984718765796309',310048000,NULL,NULL,'6bd591d3336ea112789ad6675a9b1d8e1578fe42e44ca7f7be5557089d374c3f','ad6559d820513781cb3bd412c74bfd5575595078e42007573a0da9f208bf5aea','70dd3957cb5dc4ea2623bf5e1d474475d525e13159cff152b77bd7cce325e00e');
INSERT INTO blocks VALUES(310049,'4ad2761923ad49ad2b283b640f1832522a2a5d6964486b21591b71df6b33be3c',310049000,NULL,NULL,'04fe1e6631d503a9ee646584cda33857fac6eeca11fa60d442e09b2ed1380e5c','f14c6718b43729126cd3b7fe5b8b4dd27dcec04f379a30f69500f2f0b2f36715','dd5b8edb0019ca4157a3fea69f3c25d2c69b3eab62aa693e8972598a0022e9da');
INSERT INTO blocks VALUES(310050,'8cfeb60a14a4cec6e9be13d699694d49007d82a31065a17890383e262071e348',310050000,NULL,NULL,'dc73bfb66386f237f127f607a4522c0a8c650b6d0f76a87e30632938cf905155','2a118b6fc1b1c64b790e81895f58bca39a4ec73825f9c40a6e674b14da49e410','027181bdf4ce697b5ba2ad5fb2da0c7760ccc44805f7313fa32a6bcfc65bba56');
INSERT INTO blocks VALUES(310051,'b53c90385dd808306601350920c6af4beb717518493fd23b5c730eea078f33e6',310051000,NULL,NULL,'e4eea2d144c8f9c6dfe731efee419056de42f53108f83ebee503c9114b8e4192','a910be4cd65598d4b1031a0afb11644daf91338b7d5714ae5f0619ed1c02aa35','a1ae010bdf7178d602fdda887c947933af3e57f2bcb89b9a859f009468a3aee5');
INSERT INTO blocks VALUES(310052,'0acdacf4e4b6fca756479cb055191b367b1fa433aa558956f5f08fa5b7b394e2',310052000,NULL,NULL,'8d12b561e7cf87b0aabe000a93a57e5f31db75510b1e9feb19b4f557cc0e6604','736cf75895c6b0a0899baca213f46b5f1043ae6e774fd85c4e965363c58ad76d','f1af0e8b196a6f47d1b61cd550615b3d4bce1af8667a7668036851916da25b33');
INSERT INTO blocks VALUES(310053,'68348f01b6dc49b2cb30fe92ac43e527aa90d859093d3bf7cd695c64d2ef744f',310053000,NULL,NULL,'f47b81b3dfc522d9b601d1776fa2deef8543ca077cb0743556cd970bb119d640','b6176107f5ed5d22352b9fc00d444c4d62c177147018e9a3123a5ddf86113a92','9def6bd964910651ad1148c9e070b677df998e5fe2d89e0f7526f4b306e88036');
INSERT INTO blocks VALUES(310054,'a8b5f253df293037e49b998675620d5477445c51d5ec66596e023282bb9cd305',310054000,NULL,NULL,'df191ed877eb1856d6780a717c04d6925246cdee7dd6df74216ea983560d5a2b','22ed22ae4cabc3bf271243f79c3a4d2c42e5fe86978a9f860659b2037e69ea0b','f182aa045d7baaf72eb3a28f9488bc3d0adfcccb270f5a825e7ff72cb6895c34');
INSERT INTO blocks VALUES(310055,'4b069152e2dc82e96ed8a3c3547c162e8c3aceeb2a4ac07972f8321a535b9356',310055000,NULL,NULL,'4b0ab72111202b1f9a5add4bf9a812df203cb6761a8d16b5f7a8b9ed6f2b2476','fd10402625c50698b9db78754941b5f3961f19557c5cbdae9321e73a59da85af','f36a4fb85c64a4959a940ba247d5c945e33f41009ca6bbd776fe6c847b65f5f6');
INSERT INTO blocks VALUES(310056,'7603eaed418971b745256742f9d2ba70b2c2b2f69f61de6cc70e61ce0336f9d3',310056000,NULL,NULL,'8e76b5be6a94e1b50ba16fe265965d4cba01b792216485c54360052e78788f20','9137c235b9218da6194b0224675ac200ce37e57a280682875b64b614d998f1cd','735e35e38481317f7c6b8b948297ad669c422747f40e865601d38da6ed971d89');
INSERT INTO blocks VALUES(310057,'4a5fdc84f2d66ecb6ee3e3646aad20751ce8694e64e348d3c8aab09d33a3e411',310057000,NULL,NULL,'e14dde2bfbe4f9076b7ba548aad37269752858361af094b4be8b956c0a28b9c5','dae4bad204dcb46ea70311d316ad02fa49d9643608dd443861402705ffe7f7db','e7c7f03c38f40e3556a5baa91db4a738cdec7e564de52b39d82990b2d5fb98bb');
INSERT INTO blocks VALUES(310058,'a6eef3089896f0cae0bfe9423392e45c48f4efe4310b14d8cfbdb1fea613635f',310058000,NULL,NULL,'b986e5f6486ceac7f1af41b1da968e453cc19376d588d8e884439b51313d6e30','8dcaccbcaef1b98d192f0b8d62f5b371043d676401c2120be4eda65786fc68c7','ea8bae443c8df855e40e8bcff3dcfe618b1d46a1ec783b106c31e6424b10bfac');
INSERT INTO blocks VALUES(310059,'ab505de874c43f97c90be1c26a769e6c5cb140405c993b4a6cc7afc795f156a9',310059000,NULL,NULL,'da978ee5b06812ee42cda43e1d9943c4e34e9e940cb0461f0ed463b9299402d8','96de4dc34f8de9a895d1a45bfb1d72e887ac3c168f2759e9a27a892eb398d63b','81c4338c8e7197c802f1ad8716aedc5a359a50460d08ad29991f4be832ea68c3');
INSERT INTO blocks VALUES(310060,'974ad5fbef621e0a38eab811608dc9afaf10c8ecc85fed913075ba1a145e889b',310060000,NULL,NULL,'09ccea87988cc385b9d2580613581b90157f1366d27cd3dc1a4385e104430d15','0595e85b26408a75ce220d7afb0111085b2e90aff588a1c828ff389b4c256b4c','589d6d7e670f0c96db995c4acf20385ed3f14e078bc7ac7e8a36663be49602b9');
INSERT INTO blocks VALUES(310061,'35d267d21ad386e7b7632292af1c422b0310dde7ca49a82f9577525a29c138cf',310061000,NULL,NULL,'4caebeb5ab6468e116cc0cf137977649a15dd30d9b214a5081057a551174ec48','5e3a2cfbf7e322f28a3254c2af408baae0578e333ed178a80cf416580d5425c7','ce4a967dfa5f4db7c546fe6b75f8fc29dc823944788587ebb63b79bd03fcd086');
INSERT INTO blocks VALUES(310062,'b31a0054145319ef9de8c1cb19df5bcf4dc8a1ece20053aa494e5d3a00a2852f',310062000,NULL,NULL,'51cb3f1005127e3240721c47805d67a123afdc40084692a9cc2b3215cec99dc3','a8a4c0baa06a4304469c6b9fdeb4ba167e1b795226bf03b655ff759f0b7be9e5','0184f70bf24b7b95fe1eadab1b35cfd5971bafe03044204dd2726339d413ac34');
INSERT INTO blocks VALUES(310063,'0cbcbcd5b7f2dc288e3a34eab3d4212463a5a56e886804fb4f9f1cf929eadebe',310063000,NULL,NULL,'e12864a0f955320278c215897cf4f65e5c378e534294b0bb90ebd7e4b5efd4f7','d777885ff67ef99793a8cd4f4d159580efa194a505eeed1f46a7b003d74d3818','c8f710d147f338a3288556f9eebdd109a796daa60ef1ec60e53bfaa7ccbc79e0');
INSERT INTO blocks VALUES(310064,'e2db8065a195e85cde9ddb868a17d39893a60fb2b1255aa5f0c88729de7cbf30',310064000,NULL,NULL,'ee27c3b46aa890d18be950006879874a094ecddd086db195e032fb4fe12559f5','e6a5b1e0c2bdf548abd1826994529d5ec68310fd8a74e05ec5dde281de52ff9c','22cad399931fbb4c620c887b3dd0f0e5284e1ab45f74900b7c4706868ca2c936');
INSERT INTO blocks VALUES(310065,'8a7bc7a77c831ac4fd11b8a9d22d1b6a0661b07cef05c2e600c7fb683b861d2a',310065000,NULL,NULL,'d40dbc4b5faaf8918f9cae54e5a247e3904dc65994ce0f04f417c1a595404464','7ce3ffe967f502ba033d3d51165e754b77e6c4a28cc4e569f81cf0a817c1536d','e930bfd4b6eac1822485cfa3953c550525ad1d1a6ba5177677e481fcf24edfe6');
INSERT INTO blocks VALUES(310066,'b6959be51eb084747d301f7ccaf9e75f2292c9404633b1532e3692659939430d',310066000,NULL,NULL,'19f2b00477a6fae0e10f4693d949cb409b1ed74ad20dbd9aa4a7f1f17cb813ac','2da61818fd2c6fc3a15d998ba79482cb48c49f5a9f195ae4ddba291cac9b416d','e6de9d8f4d9c0a5ec3a51ab0f886f4fd35fd9cd8d1bb6afb2b615b58996bb26a');
INSERT INTO blocks VALUES(310067,'8b08eae98d7193c9c01863fac6effb9162bda010daeacf9e0347112f233b8577',310067000,NULL,NULL,'d72891c22fcea6c51496fc1777fa736ef5aba378320a1f718d597f8f9fea3c7d','72cb3676cfd73767e4499bb405f6e07ec421a39239754d75afd8c08cdb49ae45','2e750809d79b40966d2533d7d726cff2b802cc2678244d3e235508750ca838da');
INSERT INTO blocks VALUES(310068,'9280e7297ef6313341bc81787a36acfc9af58f83a415afff5e3154f126cf52b5',310068000,NULL,NULL,'5793e10b8329d3ac71aed6347dfcf61fc7b74ca162ad99918f5c20065f8d0746','07a593978e6f669c9b378ffd115c951da48fad08b55a7d5adb7ae96bef306061','1ed832c547e29ffa2cb45660129f32f56613d2fcc0d36dbaf3872ab47e77f582');
INSERT INTO blocks VALUES(310069,'486351f0655bf594ffaab1980cff17353b640b63e9c27239109addece189a6f7',310069000,NULL,NULL,'61040e7c1a58f41d708785347f4985c1fb522b6f947d3e14dacd91157e153ab7','4822a18f5a177a8a22f1b234c181389614489a33ebf3944b1107acdce0528bb3','6de08d8b4df6538298c2599a166548d12175ffa9a7db682df4111e03107bfd22');
INSERT INTO blocks VALUES(310070,'8739e99f4dee8bebf1332f37f49a125348b40b93b74fe35579dd52bfba4fa7e5',310070000,NULL,NULL,'ce115625fbda90a0f261b2c524108a7393078cb4c3f861d6d7846501c7960008','54364047ce52153883e68adef9b681266dd725f8e45af89b1dcff3c9edd525e3','5f53766a278e20f6eb70bf3b8786d4b3191a0f76358a97ad89a2dc901cb3ac16');
INSERT INTO blocks VALUES(310071,'7a099aa1bba0ead577f1e44f35263a1f115ed6a868c98d4dd71609072ae7f80b',310071000,NULL,NULL,'3c2d4d81e90a42a0c18e9c02b8a59f99e13f2a084ee66b4b1bd410077adc383d','08991b69e486f1032749e530eee24ffd2d849b1f46aa6ef2f2d5a5202fe06e97','be328287331db13c6a631277a635da9c87768946ac8380ae14fc2fbd5aec6303');
INSERT INTO blocks VALUES(310072,'7b17ecedc07552551b8129e068ae67cb176ca766ea3f6df74b597a94e3a7fc8a',310072000,NULL,NULL,'8a28e33306582346f1d965a0393621b4aa307f6614c84369064465f95a6c727e','e0cd2ae87966825b5f8ebd21c7629fec5ea6ae0f0964ed137f0776d2a1130696','85c6c68b477ddb33e954a67c3116e75da8012443888ca1638f471481de4c899f');
INSERT INTO blocks VALUES(310073,'ee0fe3cc9b3a48a2746b6090b63b442b97ea6055d48edcf4b2288396764c6943',310073000,NULL,NULL,'e6c5b393a21df54479c4cd8e991b37d877794166c19b9f61ad7e47eb34f63bdc','4b2ece53331a483fef54d87f0da7e6f712148c0f35388439b73f2aecedc57a12','994a079c0bb105d73fc0464453adef90844be7be0426ebc47bbad7bef29fed83');
INSERT INTO blocks VALUES(310074,'ceab38dfde01f711a187601731ad575d67cfe0b7dbc61dcd4f15baaef72089fb',310074000,NULL,NULL,'b2db452daf280f1cc5f02668d0cbd33732a2fe9f04307d9c072eba97c95acf5c','28a44c85c432e94d1e15ad9675d2927a983bcde0ad0cbfe47a7d87da00df9f66','252b3e5ce81eddfd53c6086a2aaf6630aa2fe15f3c55b364c4b8f586f4228eb0');
INSERT INTO blocks VALUES(310075,'ef547198c6e36d829f117cfd7077ccde45158e3c545152225fa24dba7a26847b',310075000,NULL,NULL,'09998443cf1cd79e193a7b09681ae07ea9a835458151a7f8c7d80a00c5d8e99a','398cf0362d19717ca11dd2a5f022a1ec94122f7bcfba0c4f25a793826b1a0892','6a6f7117e0c8814d4b6a7245b8e9719dbf727738c6efc5cd81aa7071dd50de53');
INSERT INTO blocks VALUES(310076,'3b0499c2e8e8f0252c7288d4ecf66efc426ca37aad3524424d14c8bc6f8b0d92',310076000,NULL,NULL,'a0be1e88f10b5214f7c12dd32d0742537072d5eb3e54f9abf57a8577f7756d7e','5a17953bd90e4ad629cc7c24098e50a5ea86e84a5796b5db5959c807e0f9eba6','f3bcb0d573f3e7505220ce606a9c6896ee1a32e71fcc6d138b4c86c7e5095a8f');
INSERT INTO blocks VALUES(310077,'d2adeefa9024ab3ff2822bc36acf19b6c647cea118cf15b86c6bc00c3322e7dd',310077000,NULL,NULL,'d41e39038756ee538d9438228512e31b4a524bbd05bc9b9034d603fd20e00f05','0491cd1f3f3c8a4b73d26a83aa18067ec31f868df96ed4667f8d4824a768a4d3','81928269ae8abf6fec03eb3775ba5b2292de5f14a0b75f780e705c973b88871f');
INSERT INTO blocks VALUES(310078,'f6c17115ef0efe489c562bcda4615892b4d4b39db0c9791fe193d4922bd82cd6',310078000,NULL,NULL,'996092432a2d94df1db34533aa7033e672fac73de5193a696c05ae7c30d75247','ebe0a3e1269a54e03ae9b7b8ad5f00a1e88b4bdbf2c7485ac1188eac31c0a4b1','ea1514429815a58d3b87a8358d2f7171db18db6a308b31a22c5dcfbcc36fff92');
INSERT INTO blocks VALUES(310079,'f2fbd2074d804e631db44cb0fb2e1db3fdc367e439c21ffc40d73104c4d7069c',310079000,NULL,NULL,'e3f536e930e39b421e3a0566eba6b8f5f781ad1ff48530a5671752fd3eaf35ac','8dca0f21abeff518ea5c6a0fff3f3c89e0d6b263a72adfd36cbf911a306080f1','70b5ccd472fe0afab81fd3cfd7a51a2f384e7c8bb03bf0b7e8b598c999893e42');
INSERT INTO blocks VALUES(310080,'42943b914d9c367000a78b78a544cc4b84b1df838aadde33fe730964a89a3a6c',310080000,NULL,NULL,'57122dc41d7de2bdc65002905617c357496432fa4d80af48f4ca69ba1332e634','0ebd79095ee1e751b4b694c04d31fe2246db4558ee9763504c9802c2a342e817','f8c3dcf3dc7daad074cc82a00eff3086bb6ef8cbe063245446d096b20dfce677');
INSERT INTO blocks VALUES(310081,'6554f9d307976249e7b7e260e08046b3b55d318f8b6af627fed5be3063f123c4',310081000,NULL,NULL,'3a0fc7b2f0396d257a0a5c5a313910cb4073e4c79ef8cf0d3cd12f494e563105','2eec4afed90d334123b8299d50c192db4b6b7ea0f4868734ea435e5f2cd7c901','4cc5061efa8f9165f844f5ce14b6dd0602f15027dfd64dff653f3785659e434e');
INSERT INTO blocks VALUES(310082,'4f1ef91b1dcd575f8ac2e66a67715500cbca154bd6f3b8148bb7015a6aa6c644',310082000,NULL,NULL,'e876c406f682ed6f0dbd6e4c97bac13409cd400b59e894eebeb3252be306494a','91c5071bbab5368e2338657982adb58c861546c0c0ba9fe9abd6b8b781e415ec','11d09e0d0361dedfb42e1c7a15bdb6a190967a5d59e833605bd6c4a145f6fceb');
INSERT INTO blocks VALUES(310083,'9b1f6fd6ff9b0dc4e37603cfb0625f49067c775b99e12492afd85392d3c8d850',310083000,NULL,NULL,'533fc3eea80caa46cf8fd62745c5d21d09f32b18eaca70283a4bd72924c2100a','bf0da4a320545ab08a86a86a81d5702f7d493e6c3173344dc19941c8a527f4c6','735ab4d3b9692aab21e75948c17a197d1395bb1ec579e450b7be53b389b3e7a1');
INSERT INTO blocks VALUES(310084,'1e0972523e80306441b9f4157f171716199f1428db2e818a7f7817ccdc8859e3',310084000,NULL,NULL,'e3fd22f2e1470246ca99c569d187934f4b7bbb1eedb9626696cbaf9e2b46253b','ebd03846d979ea8af53d9853c2b9ed94bc4a89c1d554cd5d5a2557bec8a127c4','a44994aad22375af3e1c2742179fb71538aa8401e478ada17328580f9675612e');
INSERT INTO blocks VALUES(310085,'c5b6e9581831e3bc5848cd7630c499bca26d9ece5156d36579bdb72d54817e34',310085000,NULL,NULL,'bf04750fe13f663adb12afd3a166636a4511bf94684a77217de1bd7ef9077d94','00e86699ae5a8450e0ebec24deb4932b27686e436c2cae3eca6428a7229edda4','99b298ffc6ac4a1d80fb65e89584a98987abf2b108051e48a233300a0ef90b32');
INSERT INTO blocks VALUES(310086,'080c1dc55a4ecf4824cf9840602498cfc35b5f84099f50b71b45cb63834c7a78',310086000,NULL,NULL,'a0e8403085ba63ba72432f27ce8125921ef24742f988ab7f85dd8e4309f27a2c','8db72da41c05d03d36307441dc8751f1907da2a60e209cb7ff47e99d7b22e88e','2e57b42191dda49cebd61f4146e0a5d47dafc75da5441e6db9fa43ca024dcefd');
INSERT INTO blocks VALUES(310087,'4ec8cb1c38b22904e8087a034a6406b896eff4dd28e7620601c6bddf82e2738c',310087000,NULL,NULL,'0861b02e980ad5958bd23ac02603b132efd72ee2a70dbb0415fa5d39cc524681','9c9e3ae63fbf9180a1d17a19f47f77817eacc0aec0c031bb13046accdde03799','d5eda98454ed499fb8a7f49c09d28f60ae20c2868f519af70303206e191f44f1');
INSERT INTO blocks VALUES(310088,'e945c815c433cbddd0bf8e66c5c23b51072483492acda98f5c2c201020a8c5b3',310088000,NULL,NULL,'d52cdaa449f63f6d3abc79080378855206f91a5db865dfaf37a5a2529ea6eb9a','0ea167598525f3a88c6ab4c8f5138a41ddd7fc8e13338fa24706b9a30337f223','255847fef16d7e0a5cb78205cbcdaa9734ef64485b395f3a661230d0d23436fe');
INSERT INTO blocks VALUES(310089,'0382437f895ef3e7e38bf025fd4f606fd44d4bbd6aea71dbdc4ed11a7cd46f33',310089000,NULL,NULL,'d15a7a60b8bf8618667863b3e31eaf6202664e5aebc16d1f7a337b857ac31f90','8257d7e04e5813b7e184ec5b9bdbaad39c779cadbaa31907a8b52ad8371b5d09','5bdf07ac766cc4bdbca99d449e6758d77a9e4c3b680ea0460967298c49091836');
INSERT INTO blocks VALUES(310090,'b756db71dc037b5a4582de354a3347371267d31ebda453e152f0a13bb2fae969',310090000,NULL,NULL,'68475dcfe8252c18501fd1fef2afa2a91d20b92cacbabb542c12f43403e66ea3','dacabdd06a6ad7c50a6789bde4cbfbf5cf3d85a1e3b5d3621e0e93cf743ccdf7','265c44182c4b94a6a94f00defb701b72151830dcdc39c105039f1b86735559cf');
INSERT INTO blocks VALUES(310091,'734a9aa485f36399d5efb74f3b9c47f8b5f6fd68c9967f134b14cfe7e2d7583c',310091000,NULL,NULL,'5d584f255e5bbebc32c78a30fa816e1203fe7d3454611bef9222cdfc91dfcb63','1b382e2152f884268b32811171913ac28e7a1d40b6eeb6423b6a807ff417052b','be4ed062b28aa5e249dac7823e60344b07fbe187121386d061dc244a8406343c');
INSERT INTO blocks VALUES(310092,'56386beb65f9228740d4ad43a1c575645f6daf59e0dd9f22551c59215b5e8c3d',310092000,NULL,NULL,'ef992ad033b047b7f6ab038604736f444da55be187834f8152b173cf535c68eb','d3a42c8de911e63c540c541aca141f057a06852f519e89491e25cda63480c442','3b63f70bc2d208d99717e630c93b508806b85d84c0b389c29226503e443d40ce');
INSERT INTO blocks VALUES(310093,'a74a2425f2f4be24bb5f715173e6756649e1cbf1b064aeb1ef60e0b94b418ddc',310093000,NULL,NULL,'9cdee996d0e67ac3f9f283151b428ac5f223b72590965f41f93adcece6b88f2a','5e36c495f7310dc1815a73ab767f53eb04fe517eecc36d8ac9eedc2c1dcf117e','b9be6b071b8a2626675a0b18e8d0b1024af4bf3ec19706c1176c17f87e3e9445');
INSERT INTO blocks VALUES(310094,'2a8f976f20c4e89ff01071915ac96ee35192d54df3a246bf61fd4a0cccfb5b23',310094000,NULL,NULL,'fa25dc3f15fb28718d788f85373555966251f54bc6ed1f4dd2244b438d27b281','296aeb138c815e74a0f41e87ff2f463ac32dc01dd3d24da6fbcdf47542319e6b','adefbc319f56c50c4afcb1fbe42d5dd3bef88531c07aa522509c090504498c79');
INSERT INTO blocks VALUES(310095,'bed0fa40c9981223fb40b3be8124ca619edc9dd34d0c907369477ea92e5d2cd2',310095000,NULL,NULL,'1ba8cd971f9a169d43b6de1a136cb8e6153649fde1f7a8e7fb2f7de926fdf8b2','17b1f9d5c3426a4edb4734657cba1713f9a56991bd1b78669142ace96327d357','373887ae39db4493a059faf7901de9504168045b7f83c9911a5446bcd0e35b3c');
INSERT INTO blocks VALUES(310096,'306aeec3db435fabffdf88c2f26ee83caa4c2426375a33daa2be041dbd27ea2f',310096000,NULL,NULL,'42c36df2c53d762b9b132e622f52b2fca99bc0370978463acd22cdf6469587a8','6d05d09010684842a6048d4a70e1b08e22515caf58bb41cdf4be8b0643e6a788','3a3601a55329b1175dc55d3c85574553dd2a3349602bccc97d8b36b0ac1e661e');
INSERT INTO blocks VALUES(310097,'13e8e16e67c7cdcc80d477491e554b43744f90e8e1a9728439a11fab42cefadf',310097000,NULL,NULL,'d96af5cf3f431535689653555c29f268c931f9fb271447aed050303d364f92a8','e713310f3b49ad5f4a7a33edeede88ebff816f891ad3b75a971d402c470adf92','1734705bf30b95def63d9eb7ba430ce2f3a09b64414db512cd88dd06c1c078fa');
INSERT INTO blocks VALUES(310098,'ca5bca4b5ec4fa6183e05176abe921cff884c4e20910fab55b603cef48dc3bca',310098000,NULL,NULL,'153c9ce12e8d9f9d10c4005fc9af158613480d38b2c6551fc49bc57380c229de','1300dfb9b2c5511a312714c5679e956df96f6556b217245a5af1696300b1183c','22e30bdadf26a27de152119217e8e34efb9551f8db1fb77b02d62cb0c741c351');
INSERT INTO blocks VALUES(310099,'3c4c2279cd7de0add5ec469648a845875495a7d54ebfb5b012dcc5a197b7992a',310099000,NULL,NULL,'49f33b269d717b56a399843cf4627449010133b47079134b9e299ac5386468ee','f8c5bf3169d6c75d82c17e0567207db18fa4326b173fa441f574cdd4910e41ab','c5ea44442beb863638bc18a58c4010a6d58a944ba347d989b24277a11bb79617');
INSERT INTO blocks VALUES(310100,'96925c05b3c7c80c716f5bef68d161c71d044252c766ca0e3f17f255764242cb',310100000,NULL,NULL,'c9e72f7db2950f0b0e6e8fa3bc47d37a0d643da6ec61b236f7224b63ac60467e','42c7cdc636cbd0905f3bc4479d1a9ef6e0a5905732ce78e6f3cd63ddb2c5f971','7f3efc399d7278404aaa1293c002c06eb242145e5c2615a96d3014e666c7e7f6');
INSERT INTO blocks VALUES(310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,NULL,NULL,'a4387c8c785a8407f2dda176a7e182617904e7ce00c695ea8aa2f9d0429d9e74','a30a1c534bb5a7fafd3f28af05d1655e9d2fa4a966e420716ca16f05cef355e2','840c0c140e7dc809919a4b6bd3b993bf5cd3973ad1f8894b8f92d41199ae6879');
INSERT INTO blocks VALUES(310102,'11e25883fd0479b78ddb1953ef67e3c3d1ffc82bd1f9e918a75c2194f7137f99',310102000,NULL,NULL,'fc81f97474f7b35ef92ba93de82d38650a28afd140d3320e6f6b62337cfd1e94','7166828ceb34a1c252e97efb04195e3e7713ae81eda55adf1a2b4b694ab05aed','a8fff4b3df42c88663463a3c9ef10879dfe5ed2762fafb257326f5ea5402d2b9');
INSERT INTO blocks VALUES(310103,'559a208afea6dd27b8bfeb031f1bd8f57182dcab6cf55c4089a6c49fb4744f17',310103000,NULL,NULL,'3a502a89a3b66438cd2b944f8951a78999ba18c5f5bc8abeafe373ae4625ed4a','0fdfd69cbe22d8b0bc67852b20d85447a7ac6e2b14e29255eb371035245cf3b0','ecc2cce93b12ef7282bba058bfaf5e10fad24a9cb45054d422cafcb18a39eb61');
INSERT INTO blocks VALUES(310104,'55b82e631b61d22a8524981ff3b5e3ab4ad7b732b7d1a06191064334b8f2dfd2',310104000,NULL,NULL,'74ab5df2cdd13b654c80ef12e460120c96ce30d4690a06671474235fb93fee4a','e8ca37976b91bb8408f00847a9206db31e5af88aed6ba08b5adad49a3f187e4d','7b9438b7db954879a3c675591cfa32f7ab90b01d0d53ba204310a4543b61b1e3');
INSERT INTO blocks VALUES(310105,'1d72cdf6c4a02a5f973e6eaa53c28e9e13014b4f5bb13f91621a911b27fe936a',310105000,NULL,NULL,'dcc1940370421712cc668dc401169a55dd7077a49feddfd70e9e455aa5893962','7e58c01102a7ddfdb8cc1c47a0ec0ac79e77ccf686e8194824deb6fd77447160','bed4dea5e3110c34583650c2d1f4f67bd4107f451a734219bc4f652139c9175b');
INSERT INTO blocks VALUES(310106,'9d39cbe8c8a5357fc56e5c2f95bf132382ddad14cbc8abd54e549d58248140ff',310106000,NULL,NULL,'6ec3678f9b647dc1ea3dfd0d76ffd240da9a94097ad29e48e7b327d6198f4f78','80e5ca0057cdb1040350bcb420d35433a91bc598da0dbfc8fa819a1efae69438','77a7b6ec2671214d1163f2fe235c08d339a174943b99d68f45aee9b21cb19544');
INSERT INTO blocks VALUES(310107,'51cc04005e49fa49e661946a0e147240b0e5aac174252c96481ab7ddd5487435',310107000,NULL,NULL,'8e3c2d75c7a81175405f39386e2367c7a655afb53d7cf5b5c2e7dd2c79a40d9e','16ce0464b5fb26942a40db47dcb2add4b9a112d155c474b57816cf2bbffe2346','d6bdbf92b29c84932d4efc2121d47970ed13eb68f52b93e2c00c0eaa703daa35');
INSERT INTO blocks VALUES(310108,'8f2d3861aa42f8e75dc14a23d6046bd89feef0d81996b6e1adc2a2828fbc8b34',310108000,NULL,NULL,'b00c403723eba6ffb5db3d9903fbaa8a04a783c61949b9220e2caece1a8b86eb','b21bb20c2c8487c16af58f50fd4a9c6486dc0737b4d30c8dce01aa4b4f6cc95f','22365ee686d134052d4ac17746b88bddd97c816c3c473dc1f1fbb7a33fe38092');
INSERT INTO blocks VALUES(310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,NULL,NULL,'69d2150543fe997a6685eac965283a3e7c9d3f9aa4eb2e08e8e4fe7a15054d26','f3fa226756ff6da1b729c7643364c3d813dea1ac80d9d727a14e5a96f4e18a46','7353c74a0277eaac360cfc9638820566fbff4e220fc8ec7b128e3af7c2b85540');
INSERT INTO blocks VALUES(310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,NULL,NULL,'0122bef9da908b66c64aae0057d2052e1333c7e71075aed739de6838f03802a8','9dfd85e6c3e910a365b5e3b23cf776a28cbd4c5efcfcb5432e224acb9badb90f','6abee86b883567ee1744692e6687bd01f5601867ac4c18f7a63fc1dd8d131f37');
INSERT INTO blocks VALUES(310111,'fde71b9756d5ba0b6d8b230ee885af01f9c4461a55dbde8678279166a21b20ae',310111000,NULL,NULL,'d3ff81444800b8c914171c58ef93c9e9ce87dbeab3b7bad16729685eb0e2e55e','13a85aa34683058eb5ca81f8324be84a43db8fb61bbb9770eabfc2951dcfe682','445ee50c42195b987d4c643e0ca8b2703b157cedcb14cc9ea2f844708ff33f70');
INSERT INTO blocks VALUES(310112,'5b06f69bfdde1083785cf68ebc2211b464839033c30a099d3227b490bf3ab251',310112000,NULL,NULL,'e316c6a4f4d1dcd800bb94f80dfcb66e9d8fc52927673c91865460b8a85aa84a','5d4c30fe73bf0ca36294348e7f3fc17efb7dc927e3f751dc849d0f1f829f8b6c','b463c8d5dc368ca4f24da5f6c8363e27946e0d4f031b27563b2976424e2354c0');
INSERT INTO blocks VALUES(310113,'63914cf376d3076b697b9234810dfc084ed5a885d5cd188dd5462560da25d5e7',310113000,NULL,NULL,'44ffb0b4be579060aa2a0fb574935764189ded92d31cc4ea94e4042734a9377a','02fc109dd334715665e42b05e71a0ae285f439efa9fcaeada7bb74173eb075a6','759fb63a313d1a19875ed234d3ad4e196d04fe675aa3c6629fd3e1ba595e3c23');
INSERT INTO blocks VALUES(310114,'24fc2dded4f811eff58b32cda85d90fb5773e81b9267e9a03c359bc730d82283',310114000,NULL,NULL,'a256d5377258011a8a4d887ba734094b7dcf2dc5fe99333069abaf71a7233948','b4ea8750047d8cc4cadc3603b72aa0f124ad9d7060afbd6cdbcfb9a35005f0b2','661bb8fd606aa6feec56d69109122214cfff7a943988fe74c294099fa11d39c0');
INSERT INTO blocks VALUES(310115,'a632d67ff5f832fe9c3c675f855f08a4969c6d78c0211e71b2a24fe04be5656a',310115000,NULL,NULL,'40e8739b957a2316bde9e5727b7f57427691850996a794c6fb6095e8510e88a7','2d86b118f56701af97418d688f81789cb8a446c5e33a17c46dc9e29bd90a809b','37a9ab59cc3202a7536e7e107e70a032e26b6669a6c8523410b3f598c0d3bbdf');
INSERT INTO blocks VALUES(310116,'8495ba36b331473c4f3529681a118a4cc4fa4d51cd9b8dccb1f13e5ef841dd84',310116000,NULL,NULL,'cddef956a174dc306823ac6c25d66f6b0df70918c90fb94bf6b0b0033443dad9','a3c70bd8ab076fe93a0de349e9730082c57d9c707bda9a864f2883e931e0f1a0','5d2d862efb669ddeac80ab381e74af2b2063f65f70f01cfb22f324e1fc6a4394');
INSERT INTO blocks VALUES(310117,'978a3eac44917b82d009332797e2b6fe64c7ce313c0f15bfd9b7bb68e4f35a71',310117000,NULL,NULL,'235c743e4857b7bffc03628ee42350b5bf550ed10bbcd9ed7e405ec17f30b67d','7557f0864fc5564847a1685cece27eadb7e97852a99ed11ba670ba6173aa0693','719a79c89c2ff6ac4fb8da880efa169ca2484406788e4c65d44e25ad7ba2a639');
INSERT INTO blocks VALUES(310118,'02487d8bd4dadabd06a44fdeb67616e6830c3556ec10faad40a42416039f4723',310118000,NULL,NULL,'5559796f49bc96fb1ca98a673a137f3c98ccbef8f9110d05b770ecb1cf805e37','5d0e169a9ffaef979f4fb24f2ffcaacbc0f27d67101d319755de30d4be9398ca','6388acf307ce0d24de02381e5c5e58a91de36294a23f89b761ddeafc800fab8a');
INSERT INTO blocks VALUES(310119,'6d6be3478c874c27f5d354c9375884089511b1aaaa3cc3421759d8e3aaeb5481',310119000,NULL,NULL,'576597cb241dfa9eada633311916072451225339aed38d1a481c82d5e2833fd5','4102a664c46e871d0d6cad3311734618d34e8596e1c60c04c5d9ceca2a36cd74','19ab35e6db4e2f297fafdcc21435066fa4a908820e0928850eae962f1f2fd886');
INSERT INTO blocks VALUES(310120,'2bba7fd459ea76fe54d6d7faf437c31af8253438d5685e803c71484c53887deb',310120000,NULL,NULL,'abb63a7c4edb99c71e21d1f634fb7e95d104e420133b2d216af99c0a367be94b','41b116baa321e6259961304c0ffb4d739375cdd193f9c1b0b35eb95a7b7043ba','0cbba98f1c595fde673383d6a954274a24e25369d42b80a06f7aabca0ba4ddb5');
INSERT INTO blocks VALUES(310121,'9b3ea991d6c2fe58906bdc75ba6a2095dcb7f00cfdd6108ac75c938f93c94ee7',310121000,NULL,NULL,'b72746feb9077aafae6737529b4c1f0552c20ae45edaa72c2df4bea3c018d532','75792c51d579cfeeb7abe1801a5ed722a660bd8cb6e05c5e7bce7e4377cd7323','e5ef433e0b34a7cb16fc4ea5b1c11f21f5f407b267aa42d34f7f2a627e2c2eb2');
INSERT INTO blocks VALUES(310122,'d31b927c46e8f9ba2ccfb02f11a72179e08474bdd1b60dd3dcfd2e91a9ea2932',310122000,NULL,NULL,'add1e878e00a20f8f357bc783cde6116665655b241d473f854f0808ddd9b73c8','dd513cd779510d01c149b5a2beeb724dde4088c70a5b8e9d3df18979bbd87331','4bcc21d31609b9b369feb0adc148f6283c1932286cbb0db71955a94080e4bbc2');
INSERT INTO blocks VALUES(310123,'be6d35019a923fcef1125a27387d27237755c136f4926c5eddbf150402ea2bbd',310123000,NULL,NULL,'d85015fd04e9cb0b6fffedeb2f925e2dcc80666528daaf98124ec3565e8d3cc0','e50918d0a73e2ddbbc672d2273164d38f59649bd86e7b0777699318872cd7e56','1c3d00366b748b5513927e84b69f4ef5b9a4db95cab2b2937212e46768869a55');
INSERT INTO blocks VALUES(310124,'0984b4a908f1a7dac9dcd94da1ee451e367cc6f3216ee8cdee15eae5d0700810',310124000,NULL,NULL,'156bd9f1502fb3eefb80646fc15df6a2855e0548c5d877dabb7d4660324609dd','59ed2dcff5657790a4fd893978fd84a7beb4b5565f0ffe6798df58d71ae83450','05636e4a9d364dc2ff4c4ba8cf90bfb7f9256655409f978adaff833b4332bfe0');
INSERT INTO blocks VALUES(310125,'cc28d39365904b2f91276d09fae040adb1bbbfd4d37d8c329fced276dc52c6a6',310125000,NULL,NULL,'d0b288be666bd1e4a7a6ace21c2b373330dd73348825f93cc46086cbbcd48a0f','3ab15d2f282fb9ef3a6332d5620517a34f5849e0470690d44f6ae079a3097755','ad3df5ff23ab0d1c5035203c8e2a09bd56df2a485b05dcaeda30be666bd6f608');
INSERT INTO blocks VALUES(310126,'c9d6c2bd3eeb87f3f1033a13de8255a56445341c920a6a0ee2fb030877106797',310126000,NULL,NULL,'c2c842ff8f74fdecd9604a947792420c1e8a16d9eae381a2bc9aaee9694f4067','428adf274c2bbf3ffa1522b1b4a3f7426cd93663630fc49971389efaf6a682d3','f73a99c9aea45eb3a8681d8fea6c40b5272727ee3d419d090abaab430e590c9c');
INSERT INTO blocks VALUES(310127,'c952f369e2b3317725b4b73ba1922b84af881bd59054be94406a5d9bbb106904',310127000,NULL,NULL,'d8cca33e7e524da7740a21d5958359a3e6a6f314251e5250f0bfa06bd16f358c','8be98a0195d897761ae4c474563c5ed384fd8171d52e90c8ca73c52eb2d641f0','8c17ef860c081f9af18c741871d7816841b24cba5b368198af6358ee6ce9c625');
INSERT INTO blocks VALUES(310128,'990b0d3575caf5909286b9701ece586338067fbd35357fec7d6a54c6a6120079',310128000,NULL,NULL,'5458f1a4d540dc33c0338b94b2ce0bd7a6398a9d3369de8f3ec6f7a8a690f753','4b1431f5ae1b5e1d00597c3ca6a91c062c3af587d274177f583201718b46c556','64b3b778e7c7700d4d837bd47104a0fc2253da7595f2b4f72f54236206c6846b');
INSERT INTO blocks VALUES(310129,'fa8a7d674a9a3e4b40053cf3b819385a71831eec2f119a0f0640c6870ca1dddc',310129000,NULL,NULL,'5e6d75061f2ea056056681fd3f856407249975a5a4a327bbf8bc20a96743fffc','b0cb3830fa61dbb8f74536b65bea6d9c8ebc60491a3c9ae92553e004240f0ca4','1801e2c98ce4ebdbe663fd04260ede504e8bc0f30963719d1a36c529dc9b9f50');
INSERT INTO blocks VALUES(310130,'d3046e8e8ab77a67bf0629a3bab0bea4975631d52099d2ddc9c9fa0860522721',310130000,NULL,NULL,'200b50c17c51fdb4275ec49e7300227a63ced6e3ff9292be49eb7b402d3db1b5','0cb26f3d94aa601e44e7c4c214d76c8b9ddf7fff51160eabc2e9d0c239de7d4c','9e1c1fb2ef54c8df23af36b46578835d5b0eb24d2146134feb7d27c05835facb');
INSERT INTO blocks VALUES(310131,'d6b4357496bc2c42b58a7d1260a3615bfdb86e2ce68cd20914ef3dd3c0cdd34d',310131000,NULL,NULL,'de1c49ab1e413b11cff49cb50b22b8ac76a1ad93a024beebc8f9ad0d959525d5','33a0818c9199d87e54254bbdf3d054fdecfde05a69883858e9409ddf8c9cbeb3','c313380b3fe3bf43a866f2941f23b7379d0b1abafd01b14eee7ce99331678838');
INSERT INTO blocks VALUES(310132,'1b95a691bf4abf92f0dde901e1152cc5bd87a792d4b42613655e4046a57ab818',310132000,NULL,NULL,'306d6f01cc778512334b73d66435983c57183e7c4f87c26f1166a7a83a36a155','2467ddf29135b39d7b27de3afe1ba7205f2c2afd62236c4bd8434e53b975acb2','7d80cbcf2ed39623c1e81e23a259303468f8572296a7b468a9799c86a14d2b91');
INSERT INTO blocks VALUES(310133,'1029c14051faabf90641371a82f9e2352eaa3d6b1da66737fcf447568ca4ec51',310133000,NULL,NULL,'e156b907295c14968c5fbe5e8fcc9fdc0415f3413a36a7ed737ea9e9f153e958','250e85b762d01dcce5b1bf768307f51c18ef29bc347e9885684dcd8e8634c561','271b4a3e21c33d0c75972a311ac51c641bf3e6bdbec174a8b9170c6bc9461353');
INSERT INTO blocks VALUES(310134,'1748478069b32162affa59105257d81ef9d78aee27c626e7b24d11beb2831398',310134000,NULL,NULL,'2528daefb0d2432358a70b10e11397535232c4fd2e69eacc77219c423df1d3f8','25fabe3201f4a9a85d17c8ef597b198eecfc10a7ae268bb521e1654ee4b6ccf9','eb55d435bbb00b8856a2a72af390750b78b4b753119c2f75d4f62a8c4569dd8e');
INSERT INTO blocks VALUES(310135,'d128d3469b1a5f8fb43e64b40f8a394945d1eb2f19ccbac2603f7044a4097e4f',310135000,NULL,NULL,'81b3a7fe120fd6f795536d275ac4b1621fea8a4d968b14a51a71ecee6944a819','dd19483b94ed440e636030a25f418db6382754a0cea8352b5d88fdcb4d1ee730','0b9364c92f320264fa6d75470a4f49759bd7a69a6c4fc3b4780768a6458a26ef');
INSERT INTO blocks VALUES(310136,'6ec490aaffe2c222a9d6876a18d1c3d385c742ff4c12d1334613a54042a543a5',310136000,NULL,NULL,'405c424434f5e9036d00704008be3793514d29a5bc619c6f5cdfd3c86326fd77','dca6c4ecd244b5fc1f0419c62dcf3945af0a1483a5d841235c98ba541ce3f6e1','02f79574415cf407b994c597eb763b2ba69ad56b215e8b4fefb99d27dbb40ae8');
INSERT INTO blocks VALUES(310137,'7b44f07e233498303a57e5350f366b767809f1a3426d57b1b754dc16aba76900',310137000,NULL,NULL,'7ee1d757a81c357ea0d18e59433d275a28f04f384baa35cbb874d75ec0182dad','1c51257d4aa23d1bfab6c37b83a0c271377ba7a4268d90322db6564326d9cc0b','e19c44bab7e4b019f02f41373ebc1c478d38ebcd5a11faa16b2c346aeeb9828e');
INSERT INTO blocks VALUES(310138,'d2d658ccbf9baa89c32659e8b6c25b640af4b9b2f28f9d40baae840206402ab5',310138000,NULL,NULL,'1306ff4026b302043a5f418cc64aa65a1e5da7ced92aef50ba9c5699509f9eec','26c7bbe19283f1db781f77831215b827f7e5710d4e244a4964b4229bf931d73a','ccf1a886844de378fd63119daa2e0875ae9a54f4a067cd01193a66dbf9f1ed6f');
INSERT INTO blocks VALUES(310139,'b2c6fb61f2ae0b9d75d18fce4c52a53b1d24772b1ad66c51ca51090210527d46',310139000,NULL,NULL,'ea081adf4304d85433da18652bdb032ac5916bc6a1b96410cf0ec51f87a5c519','9de8f98a927ee3d7cc761b036b270c87edb1941d3d740be596cba134fc13b652','3b734d3aa7b4cfca1fcb19c8c2b7e6a321e739f5ea1de7496f7e171700153ef7');
INSERT INTO blocks VALUES(310140,'edddddea90e07a466298219fd7f5a88975f1213289f7c434ed47152af6b68ebb',310140000,NULL,NULL,'96f0be399144ab67ac49b54f80ef596a5c508e0f052d35b07259aff88a559a0d','e8a73a351addb2c7366b23f3869d40d462098f0e05751a2f5c05af5fba352eac','dead042a85dfa72f0a4fa5fc6819054955aa0304bde38d166f47361ec6385e91');
INSERT INTO blocks VALUES(310141,'b5b71d2a271bd638561c56f4ffbe94d6086debaaa86bfeb02ef0d71339310709',310141000,NULL,NULL,'fed95d3c66979f94f4cf0ee075476b5a3e37d17285e1e84e2dcea837212ec8ce','b0dbec5abad01df3f925b1af2924736efb09e085c5ebcc0ec6514e29725b5bbf','0e32d89fb349053074122eb6009677b41369c2ae60527ca08063bd4ebc2b9c86');
INSERT INTO blocks VALUES(310142,'a98ae174c41ab8fc575d9c8d53d8e02d8e446b8c6c0d98a20ff234eba082b143',310142000,NULL,NULL,'d062c8df1d3bbbed10c67250e4273f47d9edadbeae329e91a0d9214d62e2dafc','b787e12f50542b32c298d3099940fbb78e11a258d2e21d3754dbd64cf739dad6','bd888dcdc31740ee85c185efe447978811f0845d5c6aac5e4617530b7378fc5a');
INSERT INTO blocks VALUES(310143,'8ba2f7feb302a5f9ec3e8c7fc718b02379df4698f6387d00858005b8f01e062f',310143000,NULL,NULL,'8b58427567f04bea48d8ef1643b1936731dfa1d44ab5ae8a0a725f5808e5cb25','b042f4032b7813f72c8f2aa572a912c69791ffd6e999ea4f091bc404f591aa1f','f29dee2fbbc5ed9ffa9d9385a3440ec82f65ac0cffc9ec0455477166a5fe4760');
INSERT INTO blocks VALUES(310144,'879ffa05ae6b24b236591c1f1537909179ed1245a27c5fdadd2218ab2193cdb9',310144000,NULL,NULL,'17fea61e6f803d990bfd78ae94f5482755577ffac62c56ae964a9ba4eba2a4e7','c30126e2c217e9edb751a483b8083e854c3f7e73a4641e3d0a4d1a941ee13ebd','368ffbf968479df15223addd5fd7c0c734219f29cbac345ea513f914fd15607d');
INSERT INTO blocks VALUES(310145,'175449ef0aa4580593ad4a7d0c5a9b117e1549ea772af00caa4ccdc9b1bf7a6e',310145000,NULL,NULL,'fc7745aaf59225dfd4055496462ef19352e31e7a681d5ddeee5d8d305914cd63','da92c561f482a749f06f48f0948e2bb83d43127f5ce7d339f46ce50a524a828a','1572bcf77fcb4612805756b7d99da59e3ca6823971f746ac3cb1a6d138290628');
INSERT INTO blocks VALUES(310146,'e954ab6a110455d745503f7cc8df9d92c1a800fafdd151e7b1912830a9cb7184',310146000,NULL,NULL,'b21400cea27ddadec8c336f757c1f250be59c2608323f5492cc40f0c2c54c086','d551ec07651780f1489bd4b7bc452d0433e2ceab5f9d6e881575be01f8a9ceda','5608bd672faa45f225a1fab81257ba5036093030d4876dd178b770a348a9d6ee');
INSERT INTO blocks VALUES(310147,'7650c95eba7bf1cad81575ed12f32a8cc36281a6f41bef13afe1dfc1b03a7e83',310147000,NULL,NULL,'47ed87885040679eaed04907a9adcbeb5fd23c3220d106cf991c692e56a47c85','5ca1c626d4d2fb690c096571c4fd445e8600908fdfb7effffe22850761298b3d','64ff611f24216a2e2f66c3df0925bf16829a552ffce6fdd72e09c7a460923695');
INSERT INTO blocks VALUES(310148,'77c29785877724be924f965215eb50ffe916e3b6b3a2beaea3e3ae4796545a7e',310148000,NULL,NULL,'f2b6fbf8a0d2d8ca5b7f837059d3d5d4e377606d715255ece9d66cedb1ebcb5b','1d9a19d4e289833332f60b3ab9913f3c99e6a6adc8e76031c1dd2772ec3f587f','558a0972908dcc70c2746c846e6f6b0e74583d9d91b669e514daf5775ef0878b');
INSERT INTO blocks VALUES(310149,'526b3c4a74c2663fc04ed5234c86974bffddb7235c8736d76860778c30207b3c',310149000,NULL,NULL,'7cf62dc8d0f09332900b3d3faeb973c75f60e7118ba2f5ec25f9a1d02e5373de','36fb69fa826d89979a513c26db9d10ed50828c082cb1c6d9b9e5658c623e948c','65871541309a9b6ff87204f0ad2fa901a80b9397697c605b4e8a6ae2ed155f32');
INSERT INTO blocks VALUES(310150,'cdd141f7463967dbeb78bf69dc1cd8e12489f58c4ea0a5dc9c5c01ec4fcea333',310150000,NULL,NULL,'773cd82211234feb848d9246f3e7da054bd0083d24aed81143cffc9c0dc00074','78ac88c098e8c99b2cd263425d771a34e23d2766a2537de57df2caafa35939bd','1e48019354e35dde9ca3af19f60d26bae24cb1638412d09131477e4664957694');
INSERT INTO blocks VALUES(310151,'a0f31cc6e12ec86e65e999e806ab3bfa18f4f1084e4aeb4fbd699b4fe284b330',310151000,NULL,NULL,'532dcd1eae2240e6117d592dbfde30600f391007daa8e233ff99cb26ebae995b','c4bbdfc5bf1b4c218fcbec435c48d2748270db58b60d2241a7ec309e2aea7082','1a723967347d84e38b5ba44aab308ce96f8684bb335030bded632c961dbaacbf');
INSERT INTO blocks VALUES(310152,'89c8cc3a0938c63a35e89d039aa84318a0fc4e13afac6beb849ac37140132c67',310152000,NULL,NULL,'2c5346c3aab989386ee49d27c30939760b6ff2eddad88147a715f0b4346f5c81','3b58ba76e625626f6fbe50f7e36daa3f4422542ccd4a0fe94afe9dfe4218a15d','497f2d14d5a44dde2c5737ec3ee24aaf0e182bc48ba6993ff0c732f381a05d92');
INSERT INTO blocks VALUES(310153,'d1121dfa68f4a1de4f97c123d2d2a41a102971a44b34927a78cd539ad8dca482',310153000,NULL,NULL,'2662192765845a97bc1bb97f4b8b0a1d8c73d6c4a57ba6a36062bd75094131cc','27da80084b6f2a224f59d4712c4d52ab27f7f593b9ba8fc6bbb83486036e5ad1','9fc6fe55eef8919fd8df56500ab919acc2506c2e411cc8537b26f1e598616275');
INSERT INTO blocks VALUES(310154,'ba982ea2e99d3bc5f574897c85485f89430ae38cf4ab49b7716ed466afa506d6',310154000,NULL,NULL,'662789c8199a23fd244f020fca7cf70af20e9792dd66801ac0cfe5a871279fc3','dee460f25dad1ed699b4ec383b5b15c444d8b5680c0846e98c8c061f66b47036','aae938884d27736f770e7c38baee5728a4fc31c5f515f13b10fdb6b6703553ce');
INSERT INTO blocks VALUES(310155,'cefb3b87c7b75a0eb8f062a0cde8e1073774ae035d176e9769fc87071c12d137',310155000,NULL,NULL,'6db116d18753ecb4c147346942c7cd41f3ddcd0b8b5300c8560c6cf2a1ff2b0e','d1be4f668cbeefd2b641d14f6d49d27639c0bd45d5b9c5e9d9d612aac83c5fd7','f741bb7e5ddab18cb8bc4d8b901579e80e33ba740386f533cbcba25609fb7c86');
INSERT INTO blocks VALUES(310156,'6e3811e65cb02434f9fde0445a7a2b03fe796041458737d0afcc52208f988a83',310156000,NULL,NULL,'18738df90f8ad63adfea0d45249c8c11e3429badec69f9d80e4d542ad78af26d','d11f97de17faa4b24c87e4376457e31fd7ada2b1f1e7c906eecdbfb8222b2aac','2a566e127f9fc69055fd6f5e6593131db1fffa0c9b0cdc376d921bdaa741f453');
INSERT INTO blocks VALUES(310157,'51dd192502fe797c55287b04c403cc63c087020a01c974a565dd4038db82f94a',310157000,NULL,NULL,'41d6b09f49e434e7cee1c174880a19624f796685d18cca88049572cc924240e6','fe90afb17679603d2c5adb52bb4e1f0746af6445f29553b21fd368d5af53a576','db7f04603e31884425282980ead72f9216514725f78b50fa6bb0c5751f354ca2');
INSERT INTO blocks VALUES(310158,'749395af0c3221b8652d31b4c4410c19b10404d941c7e78d765b865f853559d2',310158000,NULL,NULL,'4c436a14a5f2fb45f9525122d91559961c5ae92b182d1458f421d72b8689c555','ea2d119208c7f09ce604c9bb2e5a7473a291df79c0353913e0ee5aa386cff2b3','40ba35bc129a63e4e4879775328b9705b70dcdb846e01a06d775b0d8fa850699');
INSERT INTO blocks VALUES(310159,'fc0e9f7b6ae99080bc41625588cef73b59c8a9f7a21d7f9f1bf96192ba631c12',310159000,NULL,NULL,'9f3c424fdc6eaf4fc11fd4bf6d389af9aaf82dddeb378f050446ed0f191c415e','53a86af75eb6864b8a65b3cea3f2bd06811e9f284bfd16723a9662e40636f999','7c45d5a1e6f41dd0f10a3b8fa65b43aff0c2a0aa466a4e901630f0b123d89658');
INSERT INTO blocks VALUES(310160,'163a82beeba44b4cb83a31764047880455a94a03e859dc050da782ed89c5fa8b',310160000,NULL,NULL,'7a2c16fb611558b70b31f8f12c6d0ee08f0c04d6901f5e674984407400dc4f7c','e2e38c6ebe8032c74abf87335404eeaa33fe591a6b6c389d8f5fa05e356ced38','ff1d6b21ee071e23aa78b4963c141c8df7218058688353beed1ba2a55d46c217');
INSERT INTO blocks VALUES(310161,'609c983d412a23c693e666abdea3f672e256674bf9ee55df89b5d9777c9264d8',310161000,NULL,NULL,'b8566b51d69aaedc491add41ea3a4260406b04b8d417163c9122b6d46b23e043','b96b7ed38548d8e6daf18ad1dd2ee83ac0d50a8c91715aafc0b36373a1b633d0','9159d995724e8fbc70a850f29d3180a2b81129cdea2a31d41e0639907937b8d5');
INSERT INTO blocks VALUES(310162,'043e9645e019f0b6a019d54c5fef5eebee8ce2da1273a21283c517da126fc804',310162000,NULL,NULL,'8bc4f34f2ff6ee796a9ee54cc8e3374136a2226343ad506680ba94a04a74efdd','cf61abb7a30626608469ab0e70f7e4f289ffc9389d248e3070b7531dda3ac0a6','f3a68366d44f251ee2ae791bbdde2b51e5c4cab0f647703593635313c577f4e6');
INSERT INTO blocks VALUES(310163,'959e0a858a81922d2edf84d1fbb49d7c7e897a8f49f70bd5b066744b77836353',310163000,NULL,NULL,'d5b71a21ec5123be72bf29d699facd204140d1863ac22ef9973920a7f4fc0773','ac4df0f9c7ebcc195f9bcd0767e570d512512e4e62456992f8ab6789dc5bc8c4','6dfaa14023a3bea9616c11313db31145a810d1afc1c4e3f074d19f6f44f340ae');
INSERT INTO blocks VALUES(310164,'781b7188be61c98d864d75954cf412b2a181364cc1046de45266ccc8cdb730e2',310164000,NULL,NULL,'2f8c3ed867557c8cad28de08cf82fa2484ceb8f7d7cc26fd5c68e15019ac5f87','9cc11a659d79a6b6d80c08b1346ab0656182576ee3e1eb1de74df0a0a0ea6b68','b750d13450552720637e546b0a53dbeeb8b2639ed5954211f8566596c39252c1');
INSERT INTO blocks VALUES(310165,'a75081e4143fa95d4aa29618fea17fc3fabd85e84059cc45c96a73473fc32599',310165000,NULL,NULL,'eedb0e236cd48b9afe186b5c34002e4a17679ab7b10ed8c0854d2683ea7b4df0','3d0a290c6426a2a3f45704b20953905ae932a802853c5fe4ba8555ac17f9e20d','863cd06278876d3211c737ff844d72ddb2ea74083ab6c42cf5ba9ad855637212');
INSERT INTO blocks VALUES(310166,'a440d426adaa83fa9bb7e3d4a04b4fa06e896fc2813f5966941f1ad1f28cfb41',310166000,NULL,NULL,'392df958448612ffdfec7f6aea1d3fa37c6f15147be61667bca1f16ba101050f','cc92f5eb86c47f9f619da42050ee0a8245a05e9439be2845b131ccc4cf75e8eb','3fd5af43e6743f305215ad59ef9e508339768db5ed403f4ead96bbae40a362ed');
INSERT INTO blocks VALUES(310167,'ab4293dbea81fedacca1a0d5230fe85a230afc9490d895aa6963acc216125f66',310167000,NULL,NULL,'2d0a69eb324f085f3b36317d169902be8d4c40707c8afe2ee5dc56c104020990','f01e9e8094633c7a0da528d458215bd1dd2fa1b8cdd36eb0d88f05cc2874592b','3fe20033bae48f3800e0c350eae44d54aa3b547bf71817d9dbd428060784cd95');
INSERT INTO blocks VALUES(310168,'a12b36a88c2b0ed41f1419a29cc118fae4ecd2f70003de77848bf4a9b2b72dc9',310168000,NULL,NULL,'9339de42b016d558c571ed1b4a907a337995380951d1652c36cf9685d6d063d7','7e11b01be8b40a8fcf43ac137f9a6399a7d2ce8910fd32c7c4ccc2239f248ef4','be152d3fa57ee4a69cb170808380f71fdea72eea5c705487eb5963bbc1fb1fce');
INSERT INTO blocks VALUES(310169,'204809a85ead8ba63f981fc1db8ae95afe92015f003eaebbec166021867421f3',310169000,NULL,NULL,'b0cc29ba6075a4519388aa13b2ed8ac13e779414c50a2b0a048794065eccdc80','44a8fede87d8d6040710d9f1767eb4da7db78cc193e9ee4a9d8abc617772b0c5','65bcec84fe567bc9e50246762cb036ea55f2d96c05f1c8b29f00e7a89dc80c97');
INSERT INTO blocks VALUES(310170,'b38b0345a20a367dfe854e455e5752f63ac2d9be8de33eab264a29e87f94d119',310170000,NULL,NULL,'d342b3a0badabc8a47a15d695f7c877b54287645fd8df0d560177a57c7f0db3d','6d876507dc67f80d9c416a85c7a9450bec4daf9d741ae31bbcf0e653e369d144','97dd7d353baf8d99209dd0dfbdd91fbe086a305fe04aa7168e117073e137ac6e');
INSERT INTO blocks VALUES(310171,'b8ba5ae8d97900ce37dd451e8c6d8b3a0e2664bb1c103bf697355bf3b1de2d2d',310171000,NULL,NULL,'c994a2733d12b3e28523f9ff8edc162f54f9218565c8ea5d4d100441f0477d02','7b2ace486a880e1a04f53979745b86f445d8373ad06c175a125f3f0d87ca774f','570dad56e9f2ac7d919b21a1a57ab325844fb38dac53fc3d1dec83998aaca0bc');
INSERT INTO blocks VALUES(310172,'b17fda199c609ab4cc2d85194dd53fa51ba960212f3964a9d2fe2cfe0bb57055',310172000,NULL,NULL,'397248fb2a54f0570de5b24e9375263f3b54359727077a30227931c1052dd9b4','b45ca41848c037ba118382506b7781ec93f120694020a5a9710eb90bc84f202c','9704220bbfd226b834f000b8e59d3ace1bbf7d3a4777839b3f0a74a662e3e320');
INSERT INTO blocks VALUES(310173,'f2dcdc5ffc0aca2e71e6e0466391b388870229398a1f3c57dec646b806a65016',310173000,NULL,NULL,'66d5758c943c8332f1491005e13ee5a906a80e2af7ab8d37b236d309756def31','6f9a8f2c9f0b09ec2a6f1391712a632e64ef25a459ed8074637cdd2abae27cbc','431974fe033a14b9efccb0274c276674ce3def47d22e701a9028b4bc30b3e49f');
INSERT INTO blocks VALUES(310174,'fa6f46af9e3664353a473f6fffce56fa295e07985018bface8141b4bf7924679',310174000,NULL,NULL,'f45eb0d49b4498017519bafb08cb7e31b5e633391b1c748866a443df5004f53d','e70e878a9212a6c13350294e54f8d8e5b6fa1ef134966e0223eea89c09b137fc','934bc2812f1fc04b99925e14b4a74f2a5d5da5b6e9c3b1c51b8cb1f17084938d');
INSERT INTO blocks VALUES(310175,'f71e79fe5f03c3bc7f1360febc5d8f79fc2768ce0ff1872cf27a829b49017333',310175000,NULL,NULL,'5f9cd3d5d4d3d9dce35bd3e76f8530c7dc2992a97785149011a39f76dc9f3b88','79c2ce8a700669d53ddf31bd6a505cb73d53894c2f0a97c2ad968c5e68b2dc4d','c3f5e6f5d41edca53a5e6db34273963ed822fea88cd1e853d4ef9cd545ac2eba');
INSERT INTO blocks VALUES(310176,'67cd1d81f2998f615602346065e37f9ceb8916abb74b5762ead317d5e26453c6',310176000,NULL,NULL,'34471b4af7737e7024fc3762d0e37a98bf12b619fdb0a4ce110bd2950e3d3bc9','251f5713e1f9ce10503c2ca6860e76cc48cbb0fddd5949f9b5de63558eca14b7','51905c60dbfbf1be2dae138d1204f4f3b3f2ad4b0ddcf2a47e75576e216ec40e');
INSERT INTO blocks VALUES(310177,'6856b1971121b91c907aaf7aed286648a6074f0bd1f66bd55da2b03116192a52',310177000,NULL,NULL,'e1352b09b865ad48fe35f2a71ac1d1c188bf0f4ad7aa4ae37fd06027e556b2ba','e62d750d027fcce5e5ffa89e71fd6aed790354c6ae05901f9a5504fec424fe1a','c6b4b0d06ab58dc6603ca0d634a795328548453d19721ff01b83b3f0dad00099');
INSERT INTO blocks VALUES(310178,'8094fdc6e549c4fab18c62e4a9be5583990c4167721a7e72f46eaf1e4e04d816',310178000,NULL,NULL,'3b6ad6e8a04f803e70f6e366d16d30b2179d1624a93db041c33cf4c4d28dfcf6','8788036c3a5cc78c5c8db6d5f9cb37c63e37b69523388859080b51d87248ae7a','e38e117646c733d5160594fb2ebb3b12131f19dd58b24ceef04b1147a8aa4998');
INSERT INTO blocks VALUES(310179,'d1528027cd25a1530cdc32c4eaff3751a851c947ddc748d99a7d3026a5e581a7',310179000,NULL,NULL,'7f574d5c3d785d4070e92701956755101bd86949141b57fc4e585bd6bd2ad56d','ff8fece826dbd4f17b0b3c1ed00019dcdf038e37cdbd07114014a693de8b8a34','da35b56316b12e4c64cc895671122ee7e0548dd9c4a637b013c2a2b11c22c3ef');
INSERT INTO blocks VALUES(310180,'f2f401a5e3141a8387aaf9799e8fef92eb0fc68370dae1e27622893406d685c1',310180000,NULL,NULL,'9705d812c0cb4ca03e52ccb28a01522caef3cf41df45e7b52c32267a93517dae','bea542d7f56740d684c14cd08cd5bd2c464bb91431fc78a0381ba602f0808cd2','2a405a7d9a16c10330f96bb8143de48ff3a412c5eaf5dddaa6c6f885c710b2ee');
INSERT INTO blocks VALUES(310181,'bd59318cdba0e511487d1e4e093b146b0f362c875d35ab5251592b3d9fed7145',310181000,NULL,NULL,'808802d90ae3381feee9c5ed979e03970330135a60d9a270c719cecaf805764e','af19f8cc078522e248adfcf1cea5c131a38fbcd50c4c2cd2549e0ad269eb7899','7d7c4ff2e38a64484183812890d33d3f0989ef113bd88e07880027da130e8d0c');
INSERT INTO blocks VALUES(310182,'a7e66b4671a11af2743889a10b19d4af09ec873e2b8eb36949d710d22e1d768f',310182000,NULL,NULL,'3e8246c907b75b7dbbf1a07b044e7c146c6d802c52792ba26b0085e399653932','13cd29e89efebf0cb7368704ae07b06ab4051792d43ea6ab794cc73bcdc7b559','6dcaceefddf76502472820ce8e26e1ae15dc2ef7a7d59a99563dac9f9e9f9916');
INSERT INTO blocks VALUES(310183,'85318afb50dc77cf9edfef4d6192f7203415e93be43f19b15ca53e170b0477bb',310183000,NULL,NULL,'c830f4f39b35688655f8d3c3dd9314d1d8fe3a1aa2810ef4ec7cc51faac676b0','bac5d17a24d308806a3621d1f988cb742a157a4cf3ebf4942ceac4765e18a20a','ada96c522e1ef543a212282929eddee05ad70b49db8d586eda20c15dac855e0d');
INSERT INTO blocks VALUES(310184,'042a898e29c2ebf0fdbb4156d29d9ba1a5935e7ed707928cb21824c76dd53bfc',310184000,NULL,NULL,'499aa926aded967f6261ac213391b5498edb855c21ffadf25a0c5ff8378e9a91','bd7ee2fbaca3fa18299dd481fd6171057e2de0ddf400bebf86914c946ffbf4f0','4dc09ab17cbc664228f600f4f7808f0fdbcc78002a417ba3617db9551cd818a3');
INSERT INTO blocks VALUES(310185,'bd78c092ae353c78798482830c007aac1be07e9bc8e52855f620a3d48f46811f',310185000,NULL,NULL,'22798fe864fc015e0bcaeb760823342dbc7a9756d153cc428929b8945c6e6fe5','3981a3513166c4929b77c1d78a3dc656a173cb9a0033b13a85862f836a9cccb3','a302d45b041c8dc52a1f6cc1ab4c5450d822261e10ccb7e882cc5cb3d855f38a');
INSERT INTO blocks VALUES(310186,'e30a3a92cc2e5ad0133e5cee1f789a1a28bea620974f9ab8fa663da53e5bf707',310186000,NULL,NULL,'6593028cdf86b5f3e65509b22955212d2b3a649741e439791c72b7e3c8734ad3','9fcac132eea73019dbacb9f76d23b257815256596665b0b0d89a6e9f8f10b3c5','5e265e0c3ce7d01153ebb7911ae9940c66c3291cb54c01540fd841e67780fc5e');
INSERT INTO blocks VALUES(310187,'fc6402c86b66b6e953d23ed33d149faa0988fa90aa9f7434e2863e33da2f3414',310187000,NULL,NULL,'e49da111e3998fafb7929ce5f43fcb8de9b89aba6a06fab288ac8106e8c06c47','10198a6ec98bb82800d0d9d642cb716e89f62f877d245a026d0b5afd9c0ca286','3477071b5aa5dd524863d918a1f73909a4b59c590101ac9892ee128128831b9e');
INSERT INTO blocks VALUES(310188,'85694a80e534a53d921b5d2c6b789b747aa73bf5556b91eeed2df148e2ada917',310188000,NULL,NULL,'f36aab93a395bdb52168cca5be82b3d370073ac10a1eeda1e6769a2db96b8212','fc6ef0edfd3ab4c518a41c3ac7baa4cfd9f705085642cffe37c86f9670f83739','eb0d924354e77fe9accf8496cdf387642bec47183b329f821fbcdabde19a0bb9');
INSERT INTO blocks VALUES(310189,'7c036dadf19348348edbe0abe84861f03370415ed2fec991b9374dbb0ca19a06',310189000,NULL,NULL,'caefec27a1031498981b5d4f0329dbc766eaad6f8c4230f4434dbc0440877109','3512721c5ea6a9cf8a6f13daf01b334743be1f385e091fcf91bbbe09db466f33','b02825202d6c56d5ad489496aabc3b880decc0697a60fc19ed83324cdbc25b9c');
INSERT INTO blocks VALUES(310190,'d6ef65299fb9dfc165284015ff2b23804ffef0b5c8baf6e5fa631211a2edbd8d',310190000,NULL,NULL,'df92ef8478fd68d4774b3e8cb83ed1a069fbc5e3d666a5e8fa462013f1b890b8','e2d4f7c5afaa06f8f20ffccf9a1ecbb8c4ea7f58e396fd455e9900586e0559ad','86c223910229d505d37d5a862dd3b33f278422815727330e306f113145ac7014');
INSERT INTO blocks VALUES(310191,'5987ffecb8d4a70887a7ce2b7acb9a326f176cca3ccf270f6040219590329139',310191000,NULL,NULL,'87cd3ba6903bb0a5afa07255e569534845b926e6e3a1eeae7043ef15f695a788','637d4040525094225bed3f153a0e2d0bed48cc2f3ef283ae45f853d31840cbd8','026c524fc415a5cb5fb045ae04d797a8f6a486b730d560153a4d87dc5d1b4e41');
INSERT INTO blocks VALUES(310192,'31b7be43784f8cc2ce7bc982d29a48ff93ef95ba18f82380881c901c50cd0caa',310192000,NULL,NULL,'93831212bdb388f4e2db36ca5d6ccda6fba1c401db7ed046f1cffe261569e3ee','4389e451e1eb1302408ad2ff07ea56e79db0162bdcd9143bc4f91d2fa178e8cc','80a5058a409814c3ba14660209f617cbc12ecb0c5e17440b72a7d70aee8bcf3b');
INSERT INTO blocks VALUES(310193,'ff3bb9c107f3a6e138440dee2d60c65e342dfbf216e1872c7cdb45f2a4d8852a',310193000,NULL,NULL,'299f6e3d677e12c0f6d02b242ef82dce4e3c75402ffbee4f891ba777e160091a','cce73900ca7f59cc16b20ce2f3c0677e42f3b70753e4c9ac50a31eea60fbf13e','a9a668e3b8f30348b65feaaa8c1d5060c9d50645c95619c81193262150b9064e');
INSERT INTO blocks VALUES(310194,'d1d8f8c242a06005f59d3c4f85983f1fa5d5edcc65eb48e7b75ed7165558434a',310194000,NULL,NULL,'330c75c62d310d5214028311f19119b9aa3b413c1491067f8cf3567a1f37bae0','4880feec27f83efa1ef4ecf62c372ed3445ad464e5f7da172677b1d103a7e002','39108743cdf3e59cfce14b283f165f983ad2970f0c0b16dde7b8f25d5d8aa14b');
INSERT INTO blocks VALUES(310195,'0b2f1f57c9a7546faac835cbe43243473fa6533b6e4d8bf8d13b8e3c710faf53',310195000,NULL,NULL,'cb228e7c41f04f75bdb8a2a26e9848fd7f642176d4e3a6436bdeb61c102811be','bfdfd6bbfa5ece500515e62b53f4eef69debad0717b719e633169cf4e532ed94','22ef94602eb1adb86b72d38a998cf3a1ea6c6b5c96af8664bcdf0a4705173dc6');
INSERT INTO blocks VALUES(310196,'280e7f4c9d1457e116b27f6fc2b806d3787002fe285826e468e07f4a0e3bd2e6',310196000,NULL,NULL,'d336a7f2e3bcbb067abca699119cb0b3a7d8e1cfb2081c6ac93d3ae1183474c0','1607bdcc149a0684a9900fa41ace84d28b141ce051145f0669e957a5dd1204e8','ca40a111e119387e39a09a541af4edee1caa5fe2937cb37060b89c055152308b');
INSERT INTO blocks VALUES(310197,'68de4c7fd020395a407ef59ea267412bbd2f19b0a654f09c0dafbc7c9ada4467',310197000,NULL,NULL,'e1c14ab4ba11baa06f837c43575b058a38b7006c6ff272a0960f65d4232cd2ac','8cda89aca07b4aec42d43e1930997d38f5e1af14b97c0634505076f16d99a3ee','6f34aa6358f038572751f1ff9b873868e30788e726e9002e4e1fd581fb867496');
INSERT INTO blocks VALUES(310198,'30340d4b655879e82543773117d72017a546630ceac29f591d514f37dd5b1cc2',310198000,NULL,NULL,'03c1bbb6d2b19b199bc13c902541db2cfa8ae8c5198d8271d8699ae0a08bba0c','349415090a2f7b4c706c52a78b4fc75738671c0725462054ebddcc19a1386fe0','13fbff7ad9863f7461f7a7ab314227ca907f291086e49ffa0da52c26fa13ebb4');
INSERT INTO blocks VALUES(310199,'494ebe4ce57d53dc0f51e1281f7e335c7315a6a064e982c3852b7179052a4613',310199000,NULL,NULL,'7c998d1ebcd2fe1c91c9d8aa562bd934b67521b09abcb443b18e4bae4a3a5e93','aa87b8e5df5302e8b761a56ef09f349eb62eb4ab30e689b41000573e4e290aab','1d6899a111de587e35c1bc4b9234915a8f8ed2aa05e8f45cd3ab982bdd78ccb0');
INSERT INTO blocks VALUES(310200,'d5169d7b23c44e02a5322e91039ccc7959b558608cf164328cd63dbaf9c81a03',310200000,NULL,NULL,'12aa1d3ede45cfb999d785d21a19b20a0be4d51cf8ca7d78ecce47ef31334ebe','02a8e0b3bcde202d5b25f03fd15e9cf0a9c8ef21be59ad46a98b2305d3895ed3','da3ac0b650799fd2f73a5f5798325015003e4fce3fb0822e4507d3f53e844238');
INSERT INTO blocks VALUES(310201,'8842bf23ded504bb28765128c0097e1de47d135f01c5cf47680b3bcf5720ad95',310201000,NULL,NULL,'edb2ddade7ea48b2b5f57b57c8cdad714da2407c95e5776d080fd2af8e03214d','a381134b8f8a2c40f4e376dbb63efee2a2169e5852ec7752ddb4a08187feff0f','01a0aa14fa09d525694674ebf230aa8792c6f594c79d76ecbd75e2b2be30fec6');
INSERT INTO blocks VALUES(310202,'95fa18eecbc0905377a70b3ccd48636528d5131ccfa0126ed4639bc60d0003d8',310202000,NULL,NULL,'2dfba901292506aad81b75494c6526cb388e21df3edfaa75062e42c3c96c9912','e3d2fe74c451b50688264448ebd6d12a237505ebeee8840dd68fe0ad2bc2b619','38c2ece86a40f7607b90b19457983eb43d54a795409f4ec3abd0908a5f605bb4');
INSERT INTO blocks VALUES(310203,'ab15c43e5ac0b9d4bd7da5a14b8030b55b83d5d1855d9174364adbebf42432f8',310203000,NULL,NULL,'f19076b8896c2e9f702909caaaea599d941e9399301691dd1c620c6b6c01e3c5','9bdb8b60fd3a0ce82276845bf62d92f8bc46e495304dbe5cf354966969757bff','247f057ee393ddc4cf998162b7de4dd9c5b6f4397d58d1aaf0bd1b0597ff3386');
INSERT INTO blocks VALUES(310204,'18996fb47d68e7f4ae140dc1eb80df3e5aba513a344a949fd7c3b4f7cd4d64cb',310204000,NULL,NULL,'c2b4b4672f3567833f7689ee4a4f950255e68a3e8368772ab864828419065176','02c24695a15693bf13e3b6f2d735679aad12a30e39851f99efcfe1eaa2c86fb3','5d0240fc412899cfbae1158e81db82b4490372a871bd9e8a577e1f3e56b793f7');
INSERT INTO blocks VALUES(310205,'5363526ff34a35e018d1a18544ad865352a9abf4c801c50aa55742e71630c13a',310205000,NULL,NULL,'43b5ca2b4bcbfebc564cf99067b351e4d324875416c1e21aea828756e543b7de','c227c4595c9391d16bab66cfd17464a03adab8e651a5f5f43b733ef3afb96190','c6c9ed1622f195f57690112a7e2e11c006e056443851a424c295dd6dbfc482d5');
INSERT INTO blocks VALUES(310206,'0615d9fca5bdf694dca2b255fb9e9256f316aa6b8a9fc700aa63e769189b0518',310206000,NULL,NULL,'d2e360af76dab6744571ae5f9ceb21d2aaad9b42d1c87ab5ee9549507233648f','418a85792b65ecdad874512aabbbdb738a57aee0f21f85ba23ab7890a476d86f','cd2f1372b5a240149edd4bb89687146be7fdb4f1e0f35de5f4c921214709a594');
INSERT INTO blocks VALUES(310207,'533b4ece95c58d080f958b3982cbd4d964e95f789d0beffe4dd3c67c50f62585',310207000,NULL,NULL,'754504d3ac03899761a0d042496768cef714711afab73c76115ee62458b9b44b','518112b166fc08bddf26b191563fc95addbebd80fb99d388c8d0948688b7939d','546cf9c0d2fcdc2cfbfc5002f13822a99c252592b9345a634c60fe90f09a0ac2');
INSERT INTO blocks VALUES(310208,'26c1535b00852aec245bac47ad0167b3fa76f6e661fc96534b1c5e7fdc752f44',310208000,NULL,NULL,'cf81663f37d9c353a124bb2a3e1cdf51c8eb0078aa511ada856c8b71b801cb9e','70dfb49110af2bf7462a9365e6f7698540f42c7324f89fe94fcd268a706c0c3c','c5cee1eaa8b18c9bc9edf4ffc9e4fa3ed494584634745639b5c97f312cc00f65');
INSERT INTO blocks VALUES(310209,'23827b94762c64225d218fa3070a3ea1efce392e3a47a1663d894b8ff8a429bf',310209000,NULL,NULL,'c4200a6881e0ded18a9989140d29984c19d790527693a05be9c833318461cf42','e19b1d2cf13d2599d7e7d66780e01995f4ee56880f396f0785436c1c4c1b379e','257629581c3c3eebbb4444b48d42bb8dff1a9a8c96c4dbd7d01ae0e52a14c629');
INSERT INTO blocks VALUES(310210,'70b24078df58ecc8f7370b73229d39e52bbadcf539814deccb98948ebd86ccc0',310210000,NULL,NULL,'4ba5e58a7fc651cbc58cd1390021b8d279a5153f114c4c518f1c3b363054046a','d5aadcab9f765d51881a07bc7b0d7ba71abdaacd5074c03462836d969733a8ae','9dc693d1e6324369a91d263ea6bafe6d9a6ad463c3149262dd4f47c6549040f3');
INSERT INTO blocks VALUES(310211,'4acb44225e022e23c7fdea483db5b1f2e04069431a29c682604fe97d270c926d',310211000,NULL,NULL,'11b9e7cc6c428bbd840a8a3c2495b34a30067cbbc15589bf93eba016b477df36','1ea5160e7e967d9c11fb63d66a851395cdbdca26b68436f58a138e1443e73330','068d744cc77b085385c556a1fc1a77e6e9025b60de4d975788a6b76bf065bef7');
INSERT INTO blocks VALUES(310212,'6ef5229ec6ea926e99bf4467b0ed49d444eedb652cc792d2b8968b1e9f3b0547',310212000,NULL,NULL,'6409a0f2555b872a92be674d1d4c09a9069350f649fa73e7db367d49fffe7347','8a2df6bec91a0bbdad88c96e2bd6270b2e02f97fc4df943837e26f2819dea3ce','15a00810759c8b931d1f296b35cb2aa94d05c1cefd7e4fd33897563a66555d7f');
INSERT INTO blocks VALUES(310213,'17673a8aeff01a8cdc80528df2bd87cdd4a748fcb36d44f3a6d221a6cbddcbe7',310213000,NULL,NULL,'a7323e7ff6b0b41c30092fef6a6d2844a7671c4880aa050afd92ee690eb5e52a','5b56b4de107c3a76f91b33cb555ca9bf5e517b0c40ae164057351fd6cc6adf31','896f8783b44885d91570c629588bc277eacbbfc90e00531816608b28531094d6');
INSERT INTO blocks VALUES(310214,'4393b639990f6f7cd47b56da62c3470dcbb31ef37094b76f53829fc12d313454',310214000,NULL,NULL,'bb190b3cd299a892c05ec35beb187fd9ce925a84d9276f7da035d141c79cbfaf','637926aa42595208f834c8688e9d74dd7c2c2555dccac670e9eca29d9a928465','61e94ead9ae3d0752f3085e5276cad70449b0679b1cf7beb294a547110bac657');
INSERT INTO blocks VALUES(310215,'c26253deaf7e8df5d62b158ea4290fc9e92a4a689dadc36915650679743a74c7',310215000,NULL,NULL,'fb51d7881a295005a571902d0ad0be52ac2a69b6f5dbf2fe09607775940005a3','4746f0c3cfa7b98337c72d92e42bedbfd6b106eb2c3a45391b3a6be4707624e0','435f7aab2ffe8f43d60229e53ae43311c264292407a5f3648814c65f18a7b01a');
INSERT INTO blocks VALUES(310216,'6b77673d16911635a36fe55575d26d58cda818916ef008415fa58076eb15b524',310216000,NULL,NULL,'b920515215c8384cf04fd0341dece933924f778bfad4fb52a414a4301747a9fd','4e3505d68f732f47bcd879f9512a79f93e2a4ba33cfe827df428501c69e12e4d','7aa0f2eec827f467b061790cbc1e82bfff92ede81aa4eec0ba6826c2c873eaec');
INSERT INTO blocks VALUES(310217,'0e09244f49225d1115a2a0382365b5728adbf04f997067ea17df89e84f9c13a8',310217000,NULL,NULL,'5de885656c86c1a534c5c8b2f03c05b1e1c61d43e67051b8827b80ae7638c7a2','d3c3be7461a1d6f2c0eb0c5ac746dc0c7fb7b15de135107658b84a949f73719a','7dc11ba84119824027a783d5024d8f0dfec31e6a4d07e503efeb705c469ca5ee');
INSERT INTO blocks VALUES(310218,'3eb26381d8c93399926bb83c146847bfe0b69024220cb145fe6601f6dda957d9',310218000,NULL,NULL,'bdde3cafcabd6ebcd8fa892b631919081e43c9f90a0f4b0517ba4a0094789346','7b0a97780b267fd930c56b4b7b77bc99fc26dcaafecaf1fa27c0248707d658a2','fedd5a4082c288abe9785c217295d010cabf89c75e5f9889c818f0898329c749');
INSERT INTO blocks VALUES(310219,'60da40e38967aadf08696641d44ee5372586b884929974e1cbd5c347dc5befbf',310219000,NULL,NULL,'cd639a6b8b43be7a7fa6ae603abe3bb8b0ed4a257daeaa27e38566f74ac6bbec','3d5419b3c6d54396110ae5259c289babaef5686510b1f749f6d85323218de9ec','b7e2a97d04653e014359de17390923b95858b01d1a1448735f944f11174e234c');
INSERT INTO blocks VALUES(310220,'d78c428ac4d622ab4b4554aa87aeee013d58f428422b35b0ba0f736d491392ef',310220000,NULL,NULL,'50a93f2a30dc4638ee1a2fec501c03be0ef2260dff4fffed32c460fb9331276c','eb8b4e3f7e4ac862b08c41abb548b91800b0d28403fdc29a62df7c73cebc1106','bfed7cca7f1fd178054c5bb4189aceb678d3443a5756933c5287842f0bbb9d6a');
INSERT INTO blocks VALUES(310221,'cf5263e382afd268e6059b28dc5862285632efe8d36ba218930765e633d48f2d',310221000,NULL,NULL,'6c62946096ecb97d62135b6d1703d318672d47a57d20f0b546cd475b1fbed4be','e695af2efbb89a5947b474c6b93d8a7063795ee13e1c893d035c1e51416df3f4','e975aa36d4fa5bf4b07d1b1181298a101197f80c8171837cbfcdb52ad05bc831');
INSERT INTO blocks VALUES(310222,'1519f6ec801bf490282065f5299d631be6553af4b0883df344e7f7e5f49c4993',310222000,NULL,NULL,'0b55f261f42f9ed634acaf1a3fa54a84c8c2c53b0094aea83b8c6c47df41f808','7c5527d86bd39ccdd01db63a10c39a6bfba1fd17fe21ac0fbc52ff22d488e761','e28c00f7870e988df5d1cffe2adb119d3dbf6e87e382ae340a320ca188383959');
INSERT INTO blocks VALUES(310223,'af208e2029fa49c19aa4770e582e32e0802d0baac463b00393a7a668fa2ea047',310223000,NULL,NULL,'db80e32a9fa70ac3bda0a68ca6aa70d0d945641c4dc8a974618bcc3bd2323e71','e72bf35c1b082a421896265522c0071ff1abcbfa504e69b7fc05c42254bc6bee','9e4d05184450f6fa335882fc276e3fdda53ce0be6ec55be9b12a46a8a9d89439');
INSERT INTO blocks VALUES(310224,'5b57815583a5333b14beb50b4a35aeb108375492ee452feeeeb7c4a96cfd6e4c',310224000,NULL,NULL,'94251828d3eb2547f2ff3466d54dc779403540b3d295bb3a838c2c65dc47cbda','844bfb4ab85fc095ecbc8049aaf05de72a82db29840e5c08f6dcd95f6bcbdd2f','5d4a2be0a4c176c7ca12f34fed3e06e43b931fdaec795a2c4bd885fdcb035603');
INSERT INTO blocks VALUES(310225,'0c2992fc10b2ce8d6d08e018397d366c94231d3a05953e79f2db00605c82e41c',310225000,NULL,NULL,'0fa47a3e0c6c7a10af36dc052316e1a33139a05baec4ece20eb1d7a3b702b6ca','9c6950723a026c7a148ed91a044b0c2f747ed4c422751452842c7d9bebfe09e9','5ac77db6ee31157f95d5b19f1bd272af799f81ca66388267de84b85490f83fe1');
INSERT INTO blocks VALUES(310226,'b3f6cd212aee8c17ae964536852e7a53c69433bef01e212425a5e99ec0b7e1cb',310226000,NULL,NULL,'c825070506d055275302ee19f98f69e7ebd58e4f3d297b1b56026cd81ca6bb71','c180742d1057389449a43c3ac65e1fa1e4eb4a11c476db6cc35ba6e65c3ce6ee','69f4d88c570c78572bad9a2b005543a57988dce9dafff688f229b52dbee443e5');
INSERT INTO blocks VALUES(310227,'ea8386e130dd4e84669dc8b2ef5f4818e2f5f35403f2dc1696dba072af2bc552',310227000,NULL,NULL,'708f1b03edea6a7ba53b161c91d82c83e7fdaa39e28977cea342eb05395c9fba','4f9c8df3d88e846d17e1ae10d07a2e303e8beacbaf42cde5e88f3658cbc95c37','c53d44b2aa76fac76dbc0f9ec5be9f0ff0d47216d315d2bbc0390c5b12ade5b4');
INSERT INTO blocks VALUES(310228,'8ab465399d5feb5b7933f3e55539a2f53495277dd0780b7bf15f9338560efc7b',310228000,NULL,NULL,'26cd9f3486d1ab73536ad3237ad0b9ac550121ff6e9051d933b4c556394867ee','ccb6f87061952dfa4947606ab9a89ef1604bfd40e3a9d5a4a0d6aad3b104ee5c','06f189ddf3aaa8c630c56a64293676642360585ca9e9d56cf5ab44e706b521c2');
INSERT INTO blocks VALUES(310229,'d0ccca58f131c8a12ef375dc70951c3aa79c638b4c4d371c7f720c9c784f3297',310229000,NULL,NULL,'c4064516fdd94948922ebe20e834f3cad7fbcc44e8dd99b0c6ff1a80a41dd296','14a51d60c51a4eaba1636406fda07951af4a5009ee27893a2b2b033bb2d621cc','5a8bb3d22cba79db94403d9a2770df14c13a8299ffb1776553d26f20705803f6');
INSERT INTO blocks VALUES(310230,'f126b9318ad8e2d5812d3703ce083a43e179775615b03bd379dae5db46362f35',310230000,NULL,NULL,'919f82a675cc2747b52d53feda9bc3db70df0a626cfc6db7734282145997424d','bef660e91b9e17bc66e03f0b09ea5e0ff0f369413c80dc29fd934997521e6c29','4bf1c6f2a9034f3b182f40a1c34f408193d6c7b8f0b377b116c450944d4f4908');
INSERT INTO blocks VALUES(310231,'8667a5b933b6a43dab53858e76e4b9f24c3ac83d3f10b97bb20fde902abd4ceb',310231000,NULL,NULL,'b585efdca8b230d5d0477e27e33c46bdae4d4d13a320f72d48553718c82619ab','395fc6c465a93d977110ea86ce8300bc79889a50861ed1fa28921f5f8f5df6ff','9861a035fff8cf2c146f6e5268db362d4b8c0a82c818195a6c7e1d5ae4395bd7');
INSERT INTO blocks VALUES(310232,'813813cec50fd01b6d28277785f9e0ae81f3f0ca4cdee9c4a4415d3719c294e8',310232000,NULL,NULL,'61ae8d3c6bc169cfdafbd3a16c6b09588e7862c0d967c637bf7a81971f549484','07663fbe8dea7f523207e1ca91ff04901d9ab37160524353ad5a57b7098410ac','af1e0033d91b33e82d47ac72e5bc49fc042323898103777744db41c30574c498');
INSERT INTO blocks VALUES(310233,'79a443f726c2a7464817deb2c737a264c10488cac02c001fd1a4d1a76de411d6',310233000,NULL,NULL,'ec03482b84af2c4e39d4ae39cb7eb08f2ff44bbee9ddfbae8526f28f619014c7','6e712316bcebf7e1ae1e716886d60a825b7c2f9ed640551cc21c3a8e804e0021','65de5cc54d7027d0ea6bb158640461575bc1edea656a59745e6eaa0ce80d68b5');
INSERT INTO blocks VALUES(310234,'662e70a85ddc71d3feae92864315e63c2e1be0db715bb5d8432c21a0c14a63cd',310234000,NULL,NULL,'752d6e11a32e9773df8c8caf6c88dc976d1b2ee83bc7fe83ec92a13d906b3fb5','d47e5297be9a8926367882be26c7eb25181789ea9e91b0284a738beaf5dc9617','6305f9aac43a619fc4978715a9ac22fa1dbb9c35ca99b8b6386080064af2eea4');
INSERT INTO blocks VALUES(310235,'66915fa9ef2878c38eaf21c50df95d87669f63b40da7bdf30e3c72c6b1fba38e',310235000,NULL,NULL,'2623f294c75796eb33bf3bd54dd60cd1f388df5e2a2bd611925e0b4b2ae54034','21a7a85391363c0db0e4caa99d7c18812913e371f2fc552c83a88f4161218dfa','7425791fb2b588bf5344c8f513278970d21ac499c1ac2d246de245423553a4f4');
INSERT INTO blocks VALUES(310236,'d47fadd733c145ad1a3f4b00e03016697ad6e83b15bd6a781589a3a574de23e4',310236000,NULL,NULL,'4ab86ec570c3137acb69947799cff3e2b9ed259614988c414579eb2ba78db253','4892185f645d4a5bb90e7fb30b706404c6a7ff5808dbfc6b593949d567a4b6a1','26007ec1093afa7e41872ad711d6e601db3d6bb6a39199cc8e2aaba9ef9d9f58');
INSERT INTO blocks VALUES(310237,'2561400b16b93cfbb1eaba0f10dfaa1b06d70d9a4d560639d1bcc7759e012095',310237000,NULL,NULL,'b43837305599670c0351c467d42ee01dd2d4db9739e70956fb1e2c2ec29cae59','ef9c9d4df441101cbb585fa62d682a87bcd8c0062ec7e667e071de6b42bd0400','ea5588f26eeea388524c634e646cd5a94d0a0599bb34272a89633c321af3bbea');
INSERT INTO blocks VALUES(310238,'43420903497d2735dc3077f4d4a2227c29e6fc2fa1c8fd5d55e7ba88782d3d55',310238000,NULL,NULL,'d6ac59104a8bb1c9bdeff28e3d79aa227b2e36452bb393b2010c07c49989bb3f','2a54ac914c2f6a8824674b99c71705c901945589c8ae70e7ab42a56a49439a17','35c8d179a9ef79645e6d33df3b7e0ca6cbac4be5f923a094a4458ef72e1f4fe8');
INSERT INTO blocks VALUES(310239,'065efefe89eadd92ef1d12b092fd891690da79eec79f96b969fbaa9166cd6ef1',310239000,NULL,NULL,'6d324be1402bcecec8636efe1d296abeaf180ca3945cafd4640588abfc2fb622','d86a16e4a6385030fa3e81ed91e2db1ea58f90454a2056c03ffd716b029436d4','cd10d0efcf127e7beb31e6dffca342ea7d40dbab1bd28136936f5bfab7581334');
INSERT INTO blocks VALUES(310240,'50aac88bb1fa76530134b6826a6cc0d056b0f4c784f86744aae3cfc487eeeb26',310240000,NULL,NULL,'3d9a97e083b433c84bf35926f985fb39392e99eaa987093b5558c6d51c0c3257','36c5c33167e14bb08d1c2829be60f805b5585c983c47ddb76309ef5944da12eb','55e6bcf8dbd7847068e7b0e4ee96acb3852c906b07a785f5cc43e444b853f67e');
INSERT INTO blocks VALUES(310241,'792d50a3f8c22ddafe63fa3ba9a0a39dd0e358ba4e2ebcd853ca12941e85bee4',310241000,NULL,NULL,'744238a23bf617d1274d894e2d987ac2bd6554dff98ca81cd198928d918c3a4f','78d29de4047beab14fd41465029e15958318e7e51e33c5f7132dfd3f75e1a753','0d773304a4cc5ba6aac977a498028d931d42ec9694330b72e7b925a39dd5b3a3');
INSERT INTO blocks VALUES(310242,'85dda4f2d80069b72728c9e6af187e79f486254666604137533cbfe216c5ea93',310242000,NULL,NULL,'4a834e1435a3a530c130278639a452b963ed8ad682b7e4ba40bbef3c0884970f','6c2d4aa0174c6eba7e0bd44541ef68c1ae49d3b205f282b0952fb35dd26490f4','8d2d092e2f4c40040a08b1a0c81f9aba2679e3e36d86e7ff742148a8997c239b');
INSERT INTO blocks VALUES(310243,'a1f51c9370b0c1171b5be282b5b4892000d8e932d5d41963e28e5d55436ba1bd',310243000,NULL,NULL,'3c38948a1daaf2c44679c03c232d867524623c0af54c25c58ab80141629a3411','e44e0234507c96bb69b09e094ba29fcee37954b1fd51bc5b6ca078feae71e3f4','b932125712290391e6e42582cb26602ee308e433a6ddd7800ca93555c0ce30db');
INSERT INTO blocks VALUES(310244,'46e98809a8af5158ede4dfaa5949f5be35578712d59a9f4f1de995a6342c58df',310244000,NULL,NULL,'40e163a4b75a64a4373d781d42af8acb0a7357208facab4f670cc80bbc352288','d9ff99ac69918a17df81389308ef26e1c2d6776457a402004640e930f45df231','5bee58bb875ceaca1c333df4ae1311f6c3e3cb9a58f79dbfd2d01247e9f0620f');
INSERT INTO blocks VALUES(310245,'59f634832088aced78462dd164efd7081148062a63fd5b669af422f4fb55b7ae',310245000,NULL,NULL,'a80e1a21f48ebe40e4d1181fb5779c2aebd334a7480455720d8dc91420adc48e','cf619776679e897407267a429f094a1ade69078c9286d3389f10fd47477a64e9','1ee38374f744fcec77c5dea57d4444da3963b8841b5489acaef470fc723972e3');
INSERT INTO blocks VALUES(310246,'6f3d690448b1bd04aaf01cd2a8e7016d0618a61088f2b226b442360d02b2e4cd',310246000,NULL,NULL,'b3621966a7f1df8ba2e3150d9dc04e7c58784e05c09fbb47c0f94af6324d42d7','647519ab283d217020e4eaf0004a2f375fb96dabef7d1f61948a62886e1ee8a8','37725485a8158ffb291e456f3a34b269cee63e810f5971722eee94132eb4efe5');
INSERT INTO blocks VALUES(310247,'fce808e867645071dc8c198bc9a3757536948b972292f743b1e14d2d8283ed66',310247000,NULL,NULL,'16c29dfb1ada9a941e4d65651e6ba662eaf0d32446390014494811af709daaae','8f5bf743a672b266faac8af1457cbb8afe493024e1ac97f4be68ffdba9a19f3f','10ad8a93d1ef2adfd9db2e22e25e508c6389fa8daab46041d23352a1c7cadb39');
INSERT INTO blocks VALUES(310248,'26c05bbcfef8bcd00d0967e804903d340c337b9d9f3a3e3e5a9773363c3e9275',310248000,NULL,NULL,'46a1d502bb61030ab25f990e1d4776fc91074dd798fc6cbb86061fb5f0dc3279','574c4acdf7a88d62c265f29e89c0b533482f829ff0845b7b0454fc5a7252f7aa','b88a916dd2e8778c215adf0ccc68273a2e8874e309477259e2aa2683bba24511');
INSERT INTO blocks VALUES(310249,'93f5a32167b07030d75400af321ca5009a2cf9fce0e97ea763b92593b8133617',310249000,NULL,NULL,'bd30958dd32410059f89b5d1ed05dec1fa7d4a1ac5091a9c86d37438c1daaea3','3a4b45a25a46c5f74388792bdeaf863c754d4b5af639b6e4319dd7122f9435fa','153b31b9a0fe241a76e02880b9641e141da93e0c3fe384a3a27ec739c3339a5b');
INSERT INTO blocks VALUES(310250,'4364d780ef6a5e11c1bf2e36374e848dbbd8d041cde763f9a2f3b85f5bb017a2',310250000,NULL,NULL,'593844275ff962ef32ae358957dcd7c4578bc155bfd88cb6ba2cb6db7e4bdb73','bae842828674c39344c245d2c7e32a72c3efecc3cce6f490a6699bc79a4cfb92','fb26166ba2950b898372f5adb3eba1d7402b1064540777744aa7a2fb6a86a980');
INSERT INTO blocks VALUES(310251,'63a3897d988330d59b8876ff13aa9eac968de3807f1800b343bd246571f0dca7',310251000,NULL,NULL,'00790d2383678d2627b583eda36f39bde92883829b93d2628c741cf469cbc337','cc99f5a938ac658cfa17f2ff67024dc73c12dedec3bd573af0d79bfbad47d348','47a35e38f66d351c5403b180e16c957862612b2df8793187a8c54d3322e4583a');
INSERT INTO blocks VALUES(310252,'768d65dfb67d6b976279cbfcf5927bb082fad08037bc0c72127fab0ebab7bc43',310252000,NULL,NULL,'51238eda52d2c02906de13b4f240b2560234e6733a78658c9c810f3b0da7f1fd','b7222b648fd221690a594d0996cf2024fbf8a5022afe24e50cda9ed7b4d587ae','151dcb0b377e9b6d9c0338af49832122d8c03dcc9aeadb71a1eda0c8519949b2');
INSERT INTO blocks VALUES(310253,'bc167428ff6b39acf39fa56f5ca83db24493d8dd2ada59b02b45f59a176dbe9e',310253000,NULL,NULL,'78bb0b7368a4a11f6f6e82374640dff9a15212a34ab009842aa330557458412e','979d073b8eca2012bc5d50301f3d59b0c24563bd7c6615bfb466a318e3340a48','3952877a976cda1af11f309391febce8dacabca1074e8565769d8bd3bb30a459');
INSERT INTO blocks VALUES(310254,'ebda5a4932d24f6cf250ffbb9232913ae47af84d0f0317c12ae6506c05db26e0',310254000,NULL,NULL,'dd78d671bffc09ef422a2e78f8b86c09f9d857e9612b1012a4c1d34e9a904568','69274de821d2c841b3d3be6c3864accb7ca030c8371a7e866d716b95d1256854','a2e24d35e794db45cfd26bed007f3a5d298db6ad6b6e6dd9dcc26bb799ba7c20');
INSERT INTO blocks VALUES(310255,'cf36803c1789a98e8524f7bcaff084101d4bc98593ef3c9b9ad1a75d2961f8f4',310255000,NULL,NULL,'5e234216c346a42fa291f82db4a4bbd4067a191c5943bad6d289119e04f1a457','14f9be82c7498b7202865bbe6a12f77f225e2afbf08dd9aee2b1dc04ec6f2da4','26c4f17330b925c524b547ff3ae341632302834c6007934c4a0b82641bcbed1a');
INSERT INTO blocks VALUES(310256,'d0b4cf4e77cbbaee784767f3c75675ab1bf50e733db73fa337aa20edefdd5619',310256000,NULL,NULL,'fa2fd79c10830d09acf216e1d185848b6366f31bf61af06ca5ecf8983083404c','2a6b570e66b4f1d50a8d4a387c474836e1cc4bb430afbc4db888e0c8d9aa48ac','87896368f3f4918dfaa9d81a3f18ff712ce9e000e31b8df652f66c4f8649f272');
INSERT INTO blocks VALUES(310257,'0f42e304acaa582130b496647aa41dcb6b76b5700f7c43dd74b8275c35565f34',310257000,NULL,NULL,'9fbe93ef51bf55fe68323af3338accd41728dfd4cdb1da3d6871d599fb5d27ef','91494d87987cae032a049f9e35a8dce5681720c3a3386e331425ba2427584a52','e1d99863397a8a76834f87b0fbdb73c81996a0d5cd034591e134ebaff8ba931e');
INSERT INTO blocks VALUES(310258,'3a0156dd7512738a0a7adba8eeac1815fac224f49312f75b19a36afb744c579f',310258000,NULL,NULL,'200d17131d04a058c75c7a85b97e42fdc695854ee8d077f7b27fb20ec1412cf8','6c3d4b401155bbe0a31399a59c5503fb33edad39055571308e186718e880514e','1f9d60961a094261d8f418701f7ef371fc04391bc0881513ca815b55a6e5ab83');
INSERT INTO blocks VALUES(310259,'e5ed3cdaaf637dd7aa2a7db134253afe716ffdf153e05672df3159b71f8538a9',310259000,NULL,NULL,'912c9422436d2169c0b7ff383b8bc523c5365bc3c1158d86e5ec7987ddcb0401','0c1e588549f6bc9096e5ae831b9dd1c9dbc8fdc3589335404e58b3e4aa88e470','79c82fbdfcc3da84002e0c06fcc712a90f33820a8b69e703e292ccdd68647c36');
INSERT INTO blocks VALUES(310260,'8717ddcc837032ad1dc0bb148ddc0f6a561ed0d483b81abb0c493c5c82ec33cd',310260000,NULL,NULL,'931d3214d64e7daff87f5d70ac9e0dc1daebc1afc2334efd0512fdbad18cc4e1','128945a42adbf159159bb6fa3f361e014175d5cd56e7de38f0cefbac895d2171','e9a9e68a6e95428cb41ee0e00d6863f7e468a88621d947787cde2c73382380ab');
INSERT INTO blocks VALUES(310261,'a2a9d8c28ea41df606e81bf99cddb84b593bf5ed1e68743d38d63a7b49a50232',310261000,NULL,NULL,'8fa1c2a7587e206c18066a671a64256e8fa9941c2faea46156cc0ff31a1646e1','691d2a576a9460dadf213cef87a1aba27bed637dfd2692e1f678b12cd08012f1','4ea9b1985cd4b174d068ef0c34bfe2c6e46f5b2be3ab40b94958661c7dd138b5');
INSERT INTO blocks VALUES(310262,'e8ebcee80fbf5afb735db18419a68d61a5ffdde1b3f189e51967155c559ee4ce',310262000,NULL,NULL,'32c294546290e27a2433cf5c90da5c92e846ac95fb82f309c776c7cd9b5edfb1','a42855362f97d1ded6d7cb7839e5207bf4105298938c64d7e693adc3b5349100','94422adfed4e1d5ec56fff244dd87f74910135e1be72a2c9830d45a9ba81a680');
INSERT INTO blocks VALUES(310263,'f5a2d8d77ac9aac8f0c9218eecbb814e4dd0032ec764f15c11407072e037b3c2',310263000,NULL,NULL,'385ee6105c723c16f6e0f35f5d7bcff7cdd7241aefc05311f6c5a8ee6dc24cd7','a3a4ff4629cae2c132dee0b277fed3c93fbcc3f362f7b12dbc09d10d1cfd18ec','5ad7bee992501bca93ea1180b40bb44237d0fa3b2b6f124509d9d9b7844dfdc9');
INSERT INTO blocks VALUES(310264,'ae968fb818cd631d3e3774d176c24ae6a035de4510b133f0a0dd135dc0ae7416',310264000,NULL,NULL,'6effff8293e1002bbc4459708c08cc1728a8e98632a89fd94553b015eb6094d7','f2f67feb1d90294f16709d0d744cbfc459107983be22276055f92b432655fd07','00a0dbf7244529e0397ab56b5909e16534c7ceda926b4d318788811553c5b822');
INSERT INTO blocks VALUES(310265,'41b50a1dfd10119afd4f288c89aad1257b22471a7d2177facb328157ed6346a1',310265000,NULL,NULL,'ee29f9e1b9dba3251a27b526f53d79d7e98890afe0b6978f33fd1c4f57344d0e','7f5f60226206554a1ac3aadeb20333b0f1f8b4f1e977b45b13b00f9b470f57a3','12d030c50b6a7e5a0a007e8673169fc616d005a8898b7a3fdd4fbaf80bb9ac5b');
INSERT INTO blocks VALUES(310266,'1c7c8fa2dc51e8f3cecd776435e68c10d0da238032ebba29cbd4e18b6c299431',310266000,NULL,NULL,'b6044b3f0a9004c93506d02e75c4782bbe12b2c388efdcacd89c5760df42b557','2b50e834fa8b65afc20dd9d82d1884def03ca1433ebc4801f9f0a945fd91cbf0','41807f2d3392c8a49ce1deb5d7de59629650c3ae9158afe943bda6e5db2a13e9');
INSERT INTO blocks VALUES(310267,'c0aa0f7d4b7bb6842bf9f86f1ff7f028831ee7e7e2d7e495cc85623e5ad39199',310267000,NULL,NULL,'fb3f26ce8bd4aac1a02ba09c764d35f9cb56dba75f709f92422b01fdd7a4f49d','86f81fd38364df551c6e52e325aab29adad35c63f294e9099612fa8c0c4e1dbb','53df1455cf14c7ddf37ec361956186ff3e2848aa69ec83bfb662c3022a3c5132');
INSERT INTO blocks VALUES(310268,'b476840cc1ce090f6cf61d31a01807864e0a18dc117d60793d34df4f748189af',310268000,NULL,NULL,'48f730944343ac8abfa3f7a852075232c50c1677dc1237428375b252a0c89afe','51c21f3618540477e72705708e520737017cb9bd81e9cc93aa871a133c44f6a5','b4637b2945c5c4e0fdf2bb01f0986f7a0b38558fda4c56e041f7a57d4614bf99');
INSERT INTO blocks VALUES(310269,'37460a2ed5ecbad3303fd73e0d9a0b7ba1ab91b552a022d5f300b4da1b14e21e',310269000,NULL,NULL,'510ad44b41fc8021c0d1172b3dc6b2ced9018ed52f42f3d4956e988943b6e71d','3901eebabde2864d99fa9cb6962e77f28a885d688415cba71da8d76531a9202c','cdc4738730be4960ff5bebfcbb8698ef2a117b8733c549a0799fb855ca22bd36');
INSERT INTO blocks VALUES(310270,'a534f448972c42450ad7b7a7b91a084cf1e9ad08863107ef5abc2b2b4997395d',310270000,NULL,NULL,'31fdf38a3c5f9181bfd284d0d751093c1f41945fa8d7032575d934e2e2376fb1','58a7eb71d9c437ea4c14d01b69ac34a119903297f61d24b9be57132a8011a008','cad010a67aead2cd9ad522aab2728d7465c3d478f791051cfb5f87549bd57066');
INSERT INTO blocks VALUES(310271,'67e6efb2226a2489d4c1d7fd5dd4c38531aca8e3d687062d2274aa5348363b0b',310271000,NULL,NULL,'6195bcbd82a2b229910e6c8bf33f047caaa43e1de6e2eced813bdcce81057bcf','5720ad9f37984607c7682cc7601a93c39d19f9d59f0ad01a6b1894bcd2db5a1e','144e975a49281398d25b034482333d7f146ef2ed0c2bf0856393eaab1c10d164');
INSERT INTO blocks VALUES(310272,'6015ede3e28e642cbcf60bc8d397d066316935adbce5d27673ea95e8c7b78eea',310272000,NULL,NULL,'1e9f54fa5b4811dbe7ef7855b95cc095c9763e866038c51f80a7593bfe9d2f01','b2f381dfe89775e533bb321ed777e33b55b0599559642525dba48c395b9510f0','1ce4ef55f9d222481cfde1885c1acad02dd7da3c6260a2cd4694b0686243fb7b');
INSERT INTO blocks VALUES(310273,'625dad04c47f3f1d7f0794fe98d80122c7621284d0c3cf4a110a2e4f2153c96a',310273000,NULL,NULL,'04108d79e2e448ee634fc931495319591d5083e2d5d026145f00b3b1853c97c9','641dad6717f68796bd220b6256436aa22575c523fa30294c10013eaaece1c922','69a8e40350621395219eca6f6a8c815e196080e9bfab3b3e3e413c7756eac3c3');
INSERT INTO blocks VALUES(310274,'925266253df52bed8dc44148f22bbd85648840f83baee19a9c1ab0a4ce8003b6',310274000,NULL,NULL,'4ff9f4036369703d3b80fff33837fba9786c991a3a926619fc8bb7b3adc38a24','65e3080c5523593ebb30fb6f5c7ad7b33f2230363ab0106db62be331fc733545','a2b62b44b7f15e82b41659fdc9da2073d454b1320531a7e15f508c2f5b5d457c');
INSERT INTO blocks VALUES(310275,'85adc228e31fb99c910e291e36e3c6eafdfd7dcaebf5609a6e017269a6c705c9',310275000,NULL,NULL,'c613fccca1450f1868426b7c900452ca09b6c83589d72bf84c8afcc04b1fc0a2','21064dd8016d222de7fd4ae9fcdf2561341182e7eeb8a0ecf0cf073b94384dae','28622b719b8c3554039bcfad1e8003e5ac96d9aa7a238dc04d95c109c4937dea');
INSERT INTO blocks VALUES(310276,'ba172f268e6d1a966075623814c8403796b4eab22ef9885345c7b59ab973cc77',310276000,NULL,NULL,'0964596a5bc5e655abcbf7b7070288223e6f51d324ab56e9335430c3a62b02a8','3455fb7fb27ea9ca4436a707419c4f86a5b88291f3130adafb294260a5a40c79','5bed9b821b854b79011805acb993dbb3031948884d24c2fcf6b201d201292a98');
INSERT INTO blocks VALUES(310277,'c74bd3d505a05204eb020119b72a291a2684f5a849682632e4f24b73e9524f93',310277000,NULL,NULL,'d8c6969dd1f2609ddaeca194440cf7ed142d896553ad51f6e474d141a402daa5','72fee16765e7c018717870740b9e2b428dbd9f922ec5c06a0928817674018b15','4de17f31a98a33b3a6de987e4e38ab81d43dfb71ea2ed6f929bdb2ff044601e9');
INSERT INTO blocks VALUES(310278,'7945512bca68961325e5e1054df4d02ee87a0bc60ac4e1306be3d95479bada05',310278000,NULL,NULL,'71a060d923b31d6031b826bce24c95312acc68cb17a0b8569797f2422dffaf32','924b3a3f368c69553da898341bd646e15d6fee66b5933b7999f4137494276b8b','ca708ea8cc3e1ae373c9c070dc920739e84a8a4ad59355b7f59165ffae7ee8a0');
INSERT INTO blocks VALUES(310279,'1a9417f9adc7551b82a8c9e1e79c0639476ed9329e0233e7f0d6499618d04b4f',310279000,NULL,NULL,'5491e20db3b734e3bcb83d89fba3d3cdbd23e04a617cb61e344f67f5caf37ed0','2d46fd801b7b4d2aba0fc86acd046bbc3717163089d2e50c6ea8334f8219da90','ecb3176055542165ef893953e9e5f8ad580a7dea4b64b3e0fed46c8cb370738e');
INSERT INTO blocks VALUES(310280,'bf2195835108e32903e4b57c8dd7e25b4d15dd96b4b000d3dbb62f609f800142',310280000,NULL,NULL,'4dabdaca4e18c632095694a0dce232842e33c5464cac7c9fe1924cbebc270667','6f7e1ee1d0c9f427f8c419a01487f617f136bbd8288c7c880ad78b42f4fa09dc','997483c222a4124a86cec8573ec600dda54a80e7110ffcb37397abb5667db00d');
INSERT INTO blocks VALUES(310281,'4499b9f7e17fc1ecc7dc54c0c77e57f3dc2c9ea55593361acbea0e456be8830f',310281000,NULL,NULL,'dad6cea793dc8fd3d8c3ad04d054467e73b81603392729987c593f8ca67c3be2','6993ad9cd2739fd82a9a0bf6a52bc4fff5db3e73bff4018e0ad7b8a032806bab','5c2d7c59d097da4136a9da77752c64a6a3eafa852183f0948ba56e92369c693f');
INSERT INTO blocks VALUES(310282,'51a29336aa32e5b121b40d4eba0beb0fd337c9f622dacb50372990e5f5134e6f',310282000,NULL,NULL,'42b1f66568eab34aa3944b0eeebea5296d7475cc0748ae4926ddbab091de7903','83fc5e461a36355239e7ea6ad4a0289f895a61054c9d8b5ea18266b674fcd8c8','3a4e51ba670bf271ccec3883fa566f7f328ab2590e55da7623c5ee09c9b1535b');
INSERT INTO blocks VALUES(310283,'df8565428e67e93a62147b440477386758da778364deb9fd0c81496e0321cf49',310283000,NULL,NULL,'edfae1059d89469e4d8c9285bafe05968e62c35504ce5d5f09bca4bd8ac0b698','b2270d1b95731bb3589e68826a1d0a6e2525f2139d63f53eb9f08d0e32e490ae','af6ab6018c9ea72e93041bb7361d67c37b3a6a4837fcb31d7ee4b3a7eee8cc8e');
INSERT INTO blocks VALUES(310284,'f9d05d83d3fa7bb3f3c79b8c554301d20f12fbb953f82616ac4aad6e6cc0abe7',310284000,NULL,NULL,'2b9d8a4322352981f7033af84e111c94511ac9b87d7d2599cdf5f2814b45a42a','f62196f89142ee263a724ef15831229198b32b4fb6e5a86c6b17e33c12c63f64','ed208ff15f1ea0178774b015ea9083667fd305435ca7d3d7dceac2163b044a04');
INSERT INTO blocks VALUES(310285,'8cef48dbc69cd0a07a5acd4f4190aa199ebce996c47e24ecc44f17de5e3c285a',310285000,NULL,NULL,'63d6307a1f8d09526578c4b1776e51b40cfb5ad78d01dedd3e23d99f1efeda19','bd0bb16cb40b6cbe3fb89e18a6b5a09413babf5a2f66a890903fc815c8ca085f','710f9cd292c2a3df1c1388fa508f26a791a256f63ac13ebaae1361a43e27a96a');
INSERT INTO blocks VALUES(310286,'d4e01fb028cc6f37497f2231ebf6c00125b12e5353e65bdbf5b2ce40691d47d0',310286000,NULL,NULL,'a42dda85ec8530a307a1f9e7048d4384b229c2637305eee0368ab02957f5b31d','138db0b189be11fc0fd785e2d5e239c40cab9c658153388b118550bb08a87666','356386d17d5956d21b851d471346eaa2df84bb7c920c930443ab1b7074b6635b');
INSERT INTO blocks VALUES(310287,'a78514aa15a5096e4d4af3755e090390727cfa628168f1d35e8ac1d179fb51f4',310287000,NULL,NULL,'96bdbe4268d82b3b82d776eab32019393f5de5ec5ea2302c0c2a9aaa068fc2a5','f5c64c204c865edd37947d674dea71420081f7932473d1fd8ef4b41874939f34','7662d197291ef5cf41ebca0b906daa70f1ac3065d395e5494538b0940cf749e8');
INSERT INTO blocks VALUES(310288,'2a5c5b3406a944a9ae2615f97064de9af5da07b0258d58c1d6949e95501249e7',310288000,NULL,NULL,'0c96ab72568c907e27db628c30825012ea3ec633d3debe3256dbf4d3c95f81c5','b82dce4ca60d5b6794a051dd197dcba9f31e0d6212bfb9f69ff255c67fcc591d','42f8002f0ec65e88b334c24087411dff3103dd4e53aece0ca66b03cfbdf9519d');
INSERT INTO blocks VALUES(310289,'dda3dc28762969f5b068768d52ddf73f04674ffeddb1cc4f6a684961ecca8f75',310289000,NULL,NULL,'921af39c1d31264ba86b6e6ca54b8dbf40bfbee574c1278d78d686b20159f99c','b2beae31ca5103e76356f458d62e7e39f7226af6b4f279374ce3d61471755ec7','46294aa34f5361bc8c3b111a4ef6193bc6000694e03ce56a9be04cef93a9fccc');
INSERT INTO blocks VALUES(310290,'fe962fe98ce9f3ee1ed1e71dbffce93735d8004e7a9b95804fb456f18501a370',310290000,NULL,NULL,'743e6499fe6b1b82914457c8bc49c54abc0dbae277eccc0b7fcc203e86f89f6e','0ee48139e0e8d8956f9df64c2642198915eb90f6bd09d818ef89665d8cd9f035','aad522eef19f24d83ec5deb1dfecdd63f41d648017b60ff442fb5bf09179d53e');
INSERT INTO blocks VALUES(310291,'1eeb72097fd0bce4c2377160926b25bf8166dfd6e99402570bf506e153e25aa2',310291000,NULL,NULL,'194402bf041424fec8b63bd9b5851c5b0d04958b5851bc9fbcbcd9e683079e7a','f67e803116843ba53dd4a5603f2a79a5824a63ea77ce416c6daa604a0c894eec','d6ea0d2cf816740d8c5af584feaa800fa8478c400819f12277611631e3072fc5');
INSERT INTO blocks VALUES(310292,'9c87d12effe7e07dcaf3f71074c0a4f9f8a23c2ed49bf2634dc83e286ba3131d',310292000,NULL,NULL,'c8b7f8f3ef06df7a9c7eff346d2a9f0d1f1377c064c3b3c3bc2aebc845caee95','f10af60d6b71afc6e3b84dadef5c75dea456e29177b131f3c98b12b2ac104e2b','e4495bd2c4dad97a323202f0a7c01f9cf6fbee87dd14dcde1bd706c7fde876ab');
INSERT INTO blocks VALUES(310293,'bc18127444c7aebf0cdc5d9d30a3108b25dd3f29bf28d904176c986fa5433712',310293000,NULL,NULL,'0c9c8a8558e14645d818621e4a97c66cc9bc67023141c5bd00830436e5760fba','51efa3407adabf01a2a12725cdfac7ff2921b017985d293b3c815c7b59349ea0','32a40a07129b47cd2cc684704f2213af6dfc66e21b33c46ce7fbd9bf07d8669b');
INSERT INTO blocks VALUES(310294,'4d6ee08b06c8a11b88877b941282dc679e83712880591213fb51c2bf1838cd4d',310294000,NULL,NULL,'1cb04936a9ee72f465e4d6d4fd6f2ac99cacd74a510d74f017320dc7061c4b02','8adcd91788124dd0a31d18db9c2af84ddee5bb59bd77ce0d3577ad36b17d659f','7c47e7bbdd437518b4e194cd7aa4fce910fe40cd77bcdf939f754a0e1f7ce8ec');
INSERT INTO blocks VALUES(310295,'66b8b169b98858de4ceefcb4cbf3a89383e72180a86aeb2694d4f3467a654a53',310295000,NULL,NULL,'d7751796cf10b5a92ed9470cab6dc1d0e2a1853fd457fd913e58f5fd38771d2e','31acb517868e453817ca2ab96d4428aebf7f220b0561408f7cd114551a6de965','cb8a3aca5e9a5b691f92b6aa19fdebb9c0150f7d8bca0d4d224a016e1c29636a');
INSERT INTO blocks VALUES(310296,'75ceb8b7377c650147612384601cf512e27db7b70503d816b392b941531b5916',310296000,NULL,NULL,'e23e480658f3c900b36af8fde0bd00255b960ba1b65dbce45a773b4ae813ebcf','875150c978d964391e73f969e8a1bab8d9eb4eff5b6baf9a92736c97947a9379','f2ff7a610d810946863a9c2878a6214df0c94d54408f141e18717e3d3c4c6c57');
INSERT INTO blocks VALUES(310297,'d8ccb0c27b1ee885d882ab6314a294b2fb13068b877e35539a51caa46171b650',310297000,NULL,NULL,'802b11ed2d95f872d2fa557725a43b15fde5e7b550a3dbf229881090866ee577','3c2f073740a6649121f7fdfdf5056707b799d91d138d8dc0d523b020738628c0','96d9317ae06e87a1b4fd145aa38d5bd09161f77d3faa53ea36ef0a54596f5a32');
INSERT INTO blocks VALUES(310298,'8ca08f7c45e9de5dfc053183c3ee5fadfb1a85c9e5ca2570e2480ef05175547a',310298000,NULL,NULL,'d8d94f75f311d053b6cb52ef8ae295423c99f533351d78145614b4fbc69f6742','3ba9d82a37cd1d8f559e15a9dcaa3d2baa231c94883603d31626e6317dab9478','3021081ba3114686c09e2b4567337792d6343ce61b7de61d8cd6b6c2c4884797');
INSERT INTO blocks VALUES(310299,'a1cdac6a49a5b71bf5802df800a97310bbf964d53e6464563e5490a0b6fef5e9',310299000,NULL,NULL,'841a917e1aa259167a05c911d705a07bdcf980c9c5e831999923793a03a1d46c','eecd9c995959607724beaf4fabaa6f5e47750b8e3dce785960af3bab518df291','d7b198ece5045a7d27e573ff63f8fab72ae9a8bbf1d65ccd6960540322936a3e');
INSERT INTO blocks VALUES(310300,'395b0b4d289c02416af743d28fb7516486dea87844309ebef2663dc21b76dcb2',310300000,NULL,NULL,'3d74164b7ec33cbc0b3e372b21e025c79b35e99784a2d8ae359f2005972bd5d3','eae953e73fee53c425deb207d22ee12fec807138f76af23c0961553dd1a895a4','b9eca666b1c0c17c04d66bc323383d448457ebd4ffc4b5c6cb301183bad483d1');
INSERT INTO blocks VALUES(310301,'52f13163068f40428b55ccb8496653d0e63e3217ce1dbea8deda8407b7810e8a',310301000,NULL,NULL,'1adacb3d5e4701b0f1bc158dd5164dd770852c5520e850d6d9b9e63fd1e7c37c','ca47650ab1c2c6027bc02e990d3c045716e459055454bbd6b1de4fea68676abd','3a4d86ea3b029c6dcb70996c1d69d44ffcc590e1650bfa817c3f3c11d6074b36');
INSERT INTO blocks VALUES(310302,'ca03ebc1453dbb1b52c8cc1bc6b343d76ef4c1eaac321a0837c6028384b8d5aa',310302000,NULL,NULL,'587b7eb8bff455f2848380f870d20398ebae76e6a12acaafbac6e955d3c3380d','d39f7f1d69d150d352c100ad05c2a2883412f2b6ff6eea64a7f35677e58ce6c5','674dc054f146fa722d68bdc4cab0847788a426712547ced4ba6a8c70e2776b30');
INSERT INTO blocks VALUES(310303,'d4e6600c553f0f1e3c3af36dd9573352a25033920d7b1e9912e7daae3058dcca',310303000,NULL,NULL,'27120588c29741bbb4a802829d2b35d8b8b17e7b5cb49842faa0fefe05e99071','708dbd6aa0deab8731ab310298108004d79a9b985ca050bce3b763832d636b01','d146d5ba1233be90f880464cb6b0a03c626faebdae85c049fd5d1fb3f622dbf7');
INSERT INTO blocks VALUES(310304,'b698b0c6cb64ca397b3616ce0c4297ca94b20a5332dcc2e2b85d43f5b69a4f1c',310304000,NULL,NULL,'4a1d23a03c47c00574d3423f328c48d794ceadd2655cede15c5901d830c87589','543a9d8ccda7d7a8412fda3f5801253a16227a60e390a7a239e75501c4f3b0d1','e068507e93cbb52d394472137946db930121be0afb0cd7306f69410cd67fef4f');
INSERT INTO blocks VALUES(310305,'cfba0521675f1e08aef4ecdbc2848fe031e47f8b41014bcd4b5934c1aa483c5b',310305000,NULL,NULL,'7aac15d414e5ebcfaf63a9ac3bc05d2dde5ffc610d9bafc8ff2a210020f6d5ef','65139ed3b09fbe87bd7acbfba8a7bc62e20f33113dceb1bb3ca57c3fc63a5fe6','2c9e6aa5d021bef2a7b7f5b9ef2a4cff49cde5431762f421ca56667ce401ce34');
INSERT INTO blocks VALUES(310306,'a88a07c577a6f2f137f686036411a866cae27ff8af4e1dfb8290606780ec722a',310306000,NULL,NULL,'bc47cbbb42618bea636c422d824748d97d5bd4b4b75ab44d80ebeaa9b5fb309a','8d398d9f62005b806545dfe6aba603c79472900d87052951b21d44ac3acb7592','425c245a88c111fff644a8384d85b03a8a9cf137313978898ca8801c996f5120');
INSERT INTO blocks VALUES(310307,'bc5ccf771903eb94e336daf54b134459e1f9dd4465dec9eaa66a8ee0e76d426c',310307000,NULL,NULL,'02440bc84b5e8e1733d29e4524381c8ba25e38727d5f70d6246627761660f329','5c94dc7bf0111ceb8e13a132a239c504667dd2bc5e6363b1ac2473f0eff9e880','193f8fa4e4318581a7c4414d705184ed438ea2bf0441cdc9ea3220d85e52e542');
INSERT INTO blocks VALUES(310308,'2291ffd9650760ff861660a70403252d078c677bb037a38e9d4a506b10ee2a30',310308000,NULL,NULL,'44c5b13272847e19dd2cacf9a506145f9a1ac5792916eb98204bdb6772e7ab68','743a9980e68e2b7f6981a4f5d6a48bae4a33e157e7efbe9390aada56f97bf100','223899598252498f64d5af7b8a89631664403ada8bf4a7cc5013f5eb794c7182');
INSERT INTO blocks VALUES(310309,'ca3ca8819aa3e5fc4238d80e5f06f74ca0c0980adbbf5e2be0076243e7731737',310309000,NULL,NULL,'25ea894e3bb4f88ef9c8f86156a3980c0d638c20c69e8bc6365f913d1454c14b','8e4366a343e7dad641a826e5fd9ab5dc93343498bb5e454c620e26bb6039dad2','7a8f1b966215c256ca28bf277f6bd5a699b351884aad6d2b3e7bdcc094a2ada3');
INSERT INTO blocks VALUES(310310,'07cd7252e3e172168e33a1265b396c3708ae43b761d02448add81e476b1bcb2c',310310000,NULL,NULL,'94d123e1ef62d5063e363065d8d44f9ab7f22c59eaa35a2ce38177c7b7a8eea5','976c3ed18c88681103eef97a34fac96a83a6c4b6f45765d284d6be9da30ee6f6','fafab465cc2731fd694604c9fc800c97e760cce4add87e3f62b272151f8d4517');
INSERT INTO blocks VALUES(310311,'2842937eabfdd890e3f233d11c030bed6144b884d3a9029cd2252126221caf36',310311000,NULL,NULL,'3aa3b3f04dfcb85db112ec7f540a7f54b56ad7f749df3d0d1dc738ce25bc5728','62b395be742d80f1cd63dbd8e16fef7f585eeab6d7b8236aa207fd756d01ee07','56262f68eeb2e5812c581a0da898fa17109e01fb15713eec0607266b87d826d2');
INSERT INTO blocks VALUES(310312,'8168511cdfdc0018672bf22f3c6808af709430dd0757609abe10fcd0c3aabfd7',310312000,NULL,NULL,'44991a8afb1cb85a381557bd653b1015160842edb02266164460559a4ea9e529','13e154a14331158da9c1d432793bbf20f3f4f2eda3b8b8f75899babb2948e59b','f7a4860725fa0a77d51a4e75c6f24cc2b6da898f06324b5b1a2bf7b66e1d8306');
INSERT INTO blocks VALUES(310313,'7c1b734c019c4f3e27e8d5cbee28e64aa6c66bb041d2a450e03537e3fac8e7e5',310313000,NULL,NULL,'d7b21c8000a09ce9f26037c43073e2d7a596c68c954c5416d22454d3e89c8b70','4dcb343c09c2259c8d4636b8f36b6887e16253f734146052a4c46425e4c3bd63','b5aea38a0325d155d6ca41832185838afbbd047e19d1f97db069df4545b1edb1');
INSERT INTO blocks VALUES(310314,'1ce78314eee22e87ccae74ff129b1803115a953426a5b807f2c55fb10fb63dc8',310314000,NULL,NULL,'5c1ca6e4f014f1fa35870558ad52dd5252e6b54a02919546a03d4e6498370d44','60b9e6eca4ebc652621e1b3eea13b7b68a4129a1fbc87ee11040ffe48a171319','d452f95be0ba6def8627c74baca63899f1bad02945b651f30718c024d4c1c0e3');
INSERT INTO blocks VALUES(310315,'bd356b1bce263f7933fb4b64cf8298d2f085ca1480975d6346a8f5dab0db72cb',310315000,NULL,NULL,'ba3b14271b4899094ad98e0535979eed35dc2aad617d7996155251ddcb4d0e4e','cace213163730d9ae50b0a03410aaa91c94649029d7c9758e80b1c155bbd8c2b','bb85ed78962ec7838729b82b1074d66442d96503cc476576e5ca7889089db94a');
INSERT INTO blocks VALUES(310316,'ea9e5e747996c8d8741877afdcf296413126e2b45c693f3abdb602a5dae3fa44',310316000,NULL,NULL,'b33797e21d7654e1ca5cc08bca4a6bda9ae95f23094d42b789530b6cbd584b4a','1f8eba788ad489d3a8f429ba11c1209b12344e667514154b6b4f3b729a32c70f','aca80bf19ee4460703708b34cf7f7fc10930adab2f41c32aadfec2e087990e5c');
INSERT INTO blocks VALUES(310317,'aa8a533edd243f1484917951e45f0b7681446747cebcc54d43c78eda68134d63',310317000,NULL,NULL,'497a601664ea59cf1929096b129613ce3bbedc271ecfb33b364558e231d48649','b016074b98a80c376e1ac0b6abb37050ba8c5adc220500ab53fec4d69d672579','aae5044beba0fad04d3db46276bf338f58379f40cd0cceea87f9a1a27b4770ca');
INSERT INTO blocks VALUES(310318,'c1be6c211fbad07a10b96ac7e6850a90c43ba2a38e05d53225d913cc2cf60b03',310318000,NULL,NULL,'760dabe4684acb6c8638c56ee1387e4d6710f99adcae4cd9721da0c7decfe2bb','1ded5b631afa45a9741d19f0fe5ffc56cd0704820229038a9a34f08ef007c631','df69bf333a38e17636a34b9f52e8507e9c8014b670c882913ab9baa05a98cc4e');
INSERT INTO blocks VALUES(310319,'f7fc6204a576c37295d0c65aac3d8202db94b6a4fa879fff63510d470dcefa71',310319000,NULL,NULL,'e43bbfd0e56daf582c84a2286079fbd8aa661c149cc3a14d40d139a45fd7a19c','1265ae38381a217452aac22b1c4120ac47ea832bc41bc0b74532d855f5d64568','4f05a54522c888214c4fdad91067e81e8ce0eae541e64f12e953327334a766e9');
INSERT INTO blocks VALUES(310320,'fd34ebe6ba298ba423d860a62c566c05372521438150e8341c430116824e7e0b',310320000,NULL,NULL,'7f95ee77cee4a1c0de27a0e69d909d0c2cb8d5a5d76d6d92e8bfac58c3f148bf','b363dae617740b35e055388cf7d757f080fd2d06da104b32549ca131fd0b8505','f4daceb5ea97b59a6a1678f424c57efa7b6058fe7a66324587cdc4d97d26907c');
INSERT INTO blocks VALUES(310321,'f74be89e9ceb0779f3c7f97c34fb97cd7c51942244cbc2018d17a3f423dd3ae5',310321000,NULL,NULL,'9e2bc1247466f28c92ff287e9d5825f81e6b8b4063c70db23aacfde92f627417','6cac2fb61f71daa414c447a125d89160409035665a1d2dd25b8f3d070366d9b4','983a8895b839b5cdc5fe18ae49bf52603dd243ebf3fe2af90ebee9ff684c52ca');
INSERT INTO blocks VALUES(310322,'ce0b1afb355e6fd897e74b556a9441f202e3f2b524d1d88bc54e18f860b57668',310322000,NULL,NULL,'bca22d67b45b3bca60a0e4e1009d4ba86bbba96b0e37455e094eaf933f7d892d','db7acc11d109df150add468ddc7191c562d5c29e3e966df45e0fa76d91c9526c','fced0c8db03048472db1f78a34c5837f729ad0ab13826cf67bacd087b5bd4b97');
INSERT INTO blocks VALUES(310323,'df82040c0cbd905e7991a88786090b93606168a7248c8b099d6b9c166c7e80fd',310323000,NULL,NULL,'aa76c1d43196055cc6ae91e0afdb1105db0e5ea8b9f8d20298878900c07e8ec7','b2e19a45ca5b836fbc406f0ddb4dbdf9cd9e6ce3634a62afeecdb4f9909b00b1','53e446a9ee0b608a1fbfd4fb27f7a8ce74b73eec27ff6d87bfc052a331fa236d');
INSERT INTO blocks VALUES(310324,'367d0ac107cbc7f93857d79e6fa96d47b1c98f88b3fdda97c51f9163e2366826',310324000,NULL,NULL,'dbdc8005f1f6c45dce8e0450740c37f2d21e6f325e1c2279bf78094aa1098ebe','b28dda0a22b06b3b26c4ad0a51a176fdbcea49774f734c13bc3908942f624558','e3174a6eeb16ec056396e91e82be9e027444c6377b8faa486553e38a27c78bbe');
INSERT INTO blocks VALUES(310325,'60d50997f57a876b2f9291e1ae19c776df95b2e46c14fe6574fb0e4ce8021eac',310325000,NULL,NULL,'021f052a73f177bce172f220d3a1ab9aea5f325e32b3d2635905a0c95b4c6efa','aa003bd575cf774e59ced201b8a36bdcbf03fe9038bdd3b38263e0aafe4bdafc','8702bbc4d15e5eca4fe338bf966f322e02a0dbe52d9b24bbbfc77c422174071f');
INSERT INTO blocks VALUES(310326,'d6f210a1617e1a8eb819fc0e9ef06bd135e15ae65af407e7413f0901f5996573',310326000,NULL,NULL,'f90a81326133a303229276b553796e2f9d186f98ce897f759cadb19e6728090f','ba88c8c0a0220ff12a14604927f24405c2f927518fe05b0b1ed46bc3ca4760f9','d71bb07bdfd7949c38f4c15241e4e7e85ed2b5247fb70de118f305a50aa2381c');
INSERT INTO blocks VALUES(310327,'9fa4076881b482d234c2085a93526b057ead3c73a6e73c1ed1cdee1a59af8adc',310327000,NULL,NULL,'86aaa9593f09bb338fa1b0878f2522db223bf8262e491ae0b8e707f9796c5e05','7401fad658ad1f1ff9fc28a19a7272b4353ff35610302b2316118a46566e244b','1b205addb533adbc8d7bae6437a654cd91089bda92b68a3c08464ad9dac740ca');
INSERT INTO blocks VALUES(310328,'c7ffd388714d8d0fc77e92d05145e6845c72e6bfd32aeb61845515eca2fa2daf',310328000,NULL,NULL,'f4b59e29f0c89f18d045a800d098abfffbc9ad7ff200eeb47133605eb1a72b68','2b2759b90978f5978a0d50ccd6a5d829ea6bf8426ac2a40a3b222ef961e6642f','e17d07844a5c5dc7e2db874f8df3c47a298ad7d303722ebe58a86f06f0e576d8');
INSERT INTO blocks VALUES(310329,'67fb2e77f8d77924c877a58c1af13e1e16b9df425340ed30e9816a9553fd5a30',310329000,NULL,NULL,'dbd3510938ee45e99d8b7cac8b0d3e8a275dfc6b1c8e741e0320e4b2e4947fe5','3e688f34609a421583e323575860fb189619fc03619c05b4571eea73224a03b5','36494143892afe389879eaabd4227e2018ee09422deb8f54d9563869f41e61fa');
INSERT INTO blocks VALUES(310330,'b62c222ad5a41084eb4d779e36f635c922ff8fe275df41a9259f9a54b9adcc0c',310330000,NULL,NULL,'79f20326c0e49ea2b3c81e8d382754f311e3744b22b80140dc7ceed4da1fe09d','b174489a417a3714c5d53ca83d65d2914072d30ebdf0b9927eb92b1b9c2a4298','6969a54341405ac74fbf2b48975e3cbc22af1f112cf4123fec53fd506172dc0d');
INSERT INTO blocks VALUES(310331,'52fb4d803a141f02b12a603244801e2e555a2dffb13a76c93f9ce13f9cf9b21e',310331000,NULL,NULL,'41d2d69965cde1e0f97b7c14c33acbad592a6bd4882eed6aeb57127ed4ddb69d','f80844c120ce88eabc7021303f3dcef4f69eaf8a9ea34c81cbfae7c7c5405b3a','71e4b59d3873484df0f3d9117c122e82a51d1c012d8ac408bec539f28596237b');
INSERT INTO blocks VALUES(310332,'201086b0aab856c8b9c7b57d40762e907746fea722dbed8efb518f4bfd0dfdf2',310332000,NULL,NULL,'3def70343846a9776559707fb61437a53ffc5dac917f81ee3a12445ce69a9885','465ebdfebc5b1053d7802c195064e75cc965d5584257404f1649782cc1909edb','aa8634eb0954ef77af5dad848ae99c405bf2e3fb0686349e926de38b9c52a236');
INSERT INTO blocks VALUES(310333,'b7476114e72d4a38d0bebb0b388444619c6f1b62f97b598fed2e1ec7cd08ee82',310333000,NULL,NULL,'cc02e3e7327ddd3c192bdea2ee76728c0b0cb031fe130d5713c1ec9546ae5946','dcd4e8cc6c7b51e91fb38ccdde1f6f65c32a069b984833d37e2a8aedc8faead7','ca9fc67f53e288b47df9074f873fcf89db657228853a6198dfb291b50ad0a5e7');
INSERT INTO blocks VALUES(310334,'a39eb839c62b127287ea01dd087b2fc3ad59107ef012decae298e40c1dec52cd',310334000,NULL,NULL,'8a449270a6bfb33206c1d7eb02ca363cb405118e52359a1ed015c5660fcec8a8','6502d8f0327a107f1b1829a7744805e34214b2a3a91cc064f19582b735d88702','7961192f698ece5fe4d9511bf6ac4eaad3647f3f48015e9a82c2e26c14d3ca21');
INSERT INTO blocks VALUES(310335,'23bd6092da66032357b13b95206e6527a8d22e6637a097d696d7a96c8858cc89',310335000,NULL,NULL,'942c5c5ff6c24ce2bb18e065b24c39d1906ec381bba55cb9d905376ac87d2bdb','5416bc22304d2a8e7405489230b2943891802bf0fd53c4fbcba82437bd3b13cc','8fb7203606cea47cd7bed3f95387e26856f535e52fb63ff97e92cf0c5477e170');
INSERT INTO blocks VALUES(310336,'ec4b8d0968dbae28789be96ffa5a7e27c3846064683acd7c3eb86f1f0cc58199',310336000,NULL,NULL,'68a947f2ae4507e143c9ac84826318d4b630845f81548490f7b0c00a2330e990','c701854f139cdf42f46f866a785d8d5cc1e79de2647673577d63094d490aad29','7f8fa4e5563b0913cd3bd3ae2d813c491346a1dd949a775a40db56081fa95159');
INSERT INTO blocks VALUES(310337,'055247d24ba9860eb2eadf9ec7ea966b86794a0e3727e6ffbcba0af38f2bc34a',310337000,NULL,NULL,'4e1ca24a54f45b4cdc60be1348b3d5b81ee8acbd7c4f8cda86b8d2746694f17f','54a47e68f3ee1a6132010d51b565ba557f67eafc24d09daa5795738e373baefc','7c3c4c1190836c0a0d19238e14ec35ad49e254b923a17b05914fe30f804de108');
INSERT INTO blocks VALUES(310338,'97944272a7e86b716c6587d0da0d2094b6f7e29714daa00fec8677205a049bcd',310338000,NULL,NULL,'dafafbcf8cbefadc5596ba8b52bc6212f02f19de109f69dc412c2dbc569d5e8c','9f902cb194b7156989f83f0e2b2678f68d31bf6e8725ee445a856331e0ecd87c','e4f56d6b1b90943dbe8eeb58729dbc7b9e7cc8d8d80860a2d9082a0000799e54');
INSERT INTO blocks VALUES(310339,'99d59ea38842e00c8ba156276582ff67c5fc8c3d3c6929246623d8f51239a052',310339000,NULL,NULL,'e28e2a9c9f9476d0c23bba3c6d2e68f671aa20adf72199188a9c82160b0cbadb','2596ee7c84323246bbad496191da2db91b5bbcffd87a8988459a32a6db9516aa','704cc4c316d2a43404fcb7c40d2f93aab698b09c718f974e48d65b06d63ed76c');
INSERT INTO blocks VALUES(310340,'f7a193f14949aaae1167aebf7a6814c44712d2b19f6bf802e72be5f97dd7f5a0',310340000,NULL,NULL,'7171d5b8a9f07885a5fb6059e4ca31dc00863ebebcfc82836ed2af0deb39a48e','25215e36fcaff6ad3c41161ad1f36cc65799117b9c7b2b6bf19bca4387f789fd','08cdb47738fd2d361a9c017ce739d12bdb772a06f7ca05d88085f5ae0d7bc27a');
INSERT INTO blocks VALUES(310341,'6c468431e0169b7df175afd661bc21a66f6b4353160f7a6c9df513a6b1788a7f',310341000,NULL,NULL,'d350161fb4026c48acc21d9e66a2def972fbe543c46381a353de2d2fd8b6bcd4','b960556b46b3b90bd3020326dbb8cd45b0db0c989164d7a53aeba6afbd1f162c','f715f918570efcd15c981258f14b098fde1cd28a7434b99a43c77df71952c46a');
INSERT INTO blocks VALUES(310342,'48669c2cb8e6bf2ca7f8e4846816d35396cbc88c349a8d1318ded0598a30edf7',310342000,NULL,NULL,'6acbdd85b382016a93936385edf88ea1114706f2d326ca373ad508b653e5fd28','766708ec5b6fbbc99b12f3681768cbdc0e36566288ff7995105c1240d598fd6f','b4670bac7349874c3cb96f7dcfe7505d6d1d354a0b0645a17aeb3208374dc6f7');
INSERT INTO blocks VALUES(310343,'41a1030c13ae11f5565e0045c73d15edc583a1ff6f3a8f5eac94ffcfaf759e11',310343000,NULL,NULL,'68e26f1c578576a74ba6b63cda11695176b48c7a919beaab5496db142b247cab','2aab0ce672843e10187b60fe076e40fbb7b5d177d4abc32e8dda346facd0dab2','e9f7408942ea9b4b6c8a3059585004432e2d0a78fb6a72e86d7205c7081759c0');
INSERT INTO blocks VALUES(310344,'97b74842207c7cd27160b23d74d7deb603882e4e5e61e2899c96a39b079b3977',310344000,NULL,NULL,'2531f6b71ce2390aeeab26cbc8095aec7a76dc46db73149868d8a6209133780f','8c2029a2a858bf0c1e5b8a6e9e12141325b1a433858bd0b320dea5596b66e638','fd805e8a43eb3c0f877fc124cdc9d785a39122722bb844e2e70fd56821b8bbee');
INSERT INTO blocks VALUES(310345,'0bda7b13d1bc2ba4c3c72e0f27157067677595264d6430038f0b227118de8c65',310345000,NULL,NULL,'ecf8e55d01bec5ec8fc302451bc3e0d3a76d5d413ce354ed43e36eeef274cc14','ac507370a64dbf1ceb9805d544b4c45e5aff6a779500721d591719c7c654c7ca','80578f6b0ffbe82dc72a90949e327bba5a02ee42e49b9da71b21fcd7b152b8c2');
INSERT INTO blocks VALUES(310346,'0635503844de474dd694ecbcfb93e578268f77a80230a29986dfa7eeade15b16',310346000,NULL,NULL,'2149f9f24dd41e092555f29cf7ae1131cc53462e9f24de15720c0fd1a8a874f2','807a79b8e50b0586b62b943dd4ef5957e603c2f9810d20b04cb4edbdd245c9f3','42ba1f29760147a073151099f2844601957294fbfb894f6141fa49df28a3998e');
INSERT INTO blocks VALUES(310347,'f3f6b7e7a27c8da4318f9f2f694f37aaa9255bbdad260cb46f319a4755a1a84d',310347000,NULL,NULL,'f19aa2d83d53f128264cf432c9c313d89d2d91f09af8f2365ffc4bb0911abc5c','17e95183ab53b6679049235a180b61e3518a528a2965b48a7147d82b70fbb3ab','f6448fc487514d7f19be2a4245cbed770e5740d7a78963143fb474c82567e725');
INSERT INTO blocks VALUES(310348,'c912af0d57982701bcda4293ad1ff3456299fd9e4a1da939d8d94bcb86634412',310348000,NULL,NULL,'5ac2d42a9f7cbe6fe7ff53879d4ac316e93c00b005543c1575c3a72471765118','86b9adaf8457c471ec171a7913b20033852c2b77955364f099ec847f3c4219ee','d7d6d9072a03f37ac847ff27b8aff25aa207c8d94d97f80bae3236da6b6a29a5');
INSERT INTO blocks VALUES(310349,'ca911c788add2e16726f4e194137f595823092482e48ff8dd3bdbe56c203523c',310349000,NULL,NULL,'ea77bb132fcbdef8652894fc3c80a862ac4fb0daaa444213b61388285904bed8','817d90ae941f826bf140b2de158cb741788e7bee0373e1eff290a3de47e736da','09cbf1eab993890ee6784dabacd1d4e5e1a5ce116f5531e13c72a3af6a72d404');
INSERT INTO blocks VALUES(310350,'c20d54368c4e558c44e2fbaa0765d3aecc8c9f01d456e3ff219508b5d06bd69d',310350000,NULL,NULL,'af48f18af140a67943df6ce781e858631a4e7841c7f44facb644c93641145237','a0e5282d871e3a8702ad49bd974bd2b3cdb981c36a29e0bcbb3a87e22511ca6b','2975ff4ac83b16fcb7fe522953974560698379a2724024b36ec0c1036ca17339');
INSERT INTO blocks VALUES(310351,'656bd69a59329dbea94b8b22cfdaaec8de9ab50204868f006494d78e7f88e26f',310351000,NULL,NULL,'4ae931b01a138a0dd8e4d6479faac7961fe3148fd048c4daaa6720f907cbffb1','624e5af0577d758697891e2e66fff169dc02bfbb5bb11c2417e0215a650c42e2','c1c42221eed6b95df597a9d8cbb6409fa80f201220dcc29e33339d08186df231');
INSERT INTO blocks VALUES(310352,'fb97d2f766a23acb9644fef833e0257fdb74546e50d9e2303cf88d2e82b71a50',310352000,NULL,NULL,'d75ce96ca15ea976fbb89c93da04a0a7c2146abc01517663f97ad0fd15adefc7','807f9f02339701feeaed3227f45824d7ff80d3b93489ee4c31d93aea1a2c5275','445d1383cef51c44bff9c2ddc9dc59de19579de8dcd5b4eb3659e86da8d7e28b');
INSERT INTO blocks VALUES(310353,'2d3e451f189fc2f29704b1b09820278dd1eeb347fef11352d7a680c9aecc13b8',310353000,NULL,NULL,'c0830c03df4b203d5e17a9274643e614fcf6e6fb7216067cb4f41f874436d217','19d68b6c2d3f91e70a6a5a11c6760a2c659169b0dd9b151dcb34222119d46c2c','1fa3eafb0f69f0ef04ccca03c3f83c2ef4a6c0ab1f13c0972cd2a6f60b479000');
INSERT INTO blocks VALUES(310354,'437d9635e1702247e0d9330347cc6e339e3678be89a760ba9bf79dd2cd8803e0',310354000,NULL,NULL,'6f4d2524f4f976880e60e65aa631f8cdfa0b23fbeb3c41549c577b695b02fc34','2504b6a8832a50fb73f1468a046a2d8ba952dd47efd7813fd64ada9bd0339d3a','f5834f71384a373730267cf7d8cdaa6a9d2bb561bd8966d1bce1ea85b322a129');
INSERT INTO blocks VALUES(310355,'ea80897a4f9167bfc775e4e43840d9ea6f839f3571c7ab4433f1e082f4bbe37d',310355000,NULL,NULL,'dffc32456b12dd7dc4bbf95ab9f360d8abf4b2e705b2822728053709222f7e50','9c3dc9c0bbea622581c369fa2730968ce2360b8df1bf380b2eee45c57ab670c2','61c13bcc0727237d26d2dd043ea3f529b255240e9ccae3ffc64a9718e57d28f1');
INSERT INTO blocks VALUES(310356,'68088305f7eba74c1d50458e5e5ca5a849f0b4a4e9935709d8ee56877b1b55c4',310356000,NULL,NULL,'01c0a7d3388aaec2d2f713b930df5b716a899ccd25d3b7e3b4c21657be7923a8','2e44f8f5f814107c8e53186908391e00b97235137b564c79a4e6501605308e17','0d28ccb446bcc4a6cf6b1dc26f21b40160404c28093e6ee3ad4559e4e8d5fba0');
INSERT INTO blocks VALUES(310357,'4572f7f4ad467ef78212e9e08fa2ce3f01f2acc28c0b8ca9d1479380726bab1f',310357000,NULL,NULL,'4dd02f79c7ad6348031e564ead17921d1d112b6bf8c5f4308b52ef2511983683','16caeea5e552a4a583f574a2d3df06d3851fdd2c65b482352cc0de8965e6792e','675560408fda2bc2cf233817881afdd50f19e0a079227dcaa74626413372945e');
INSERT INTO blocks VALUES(310358,'d5eae5513f1264d00d8c83fe9271e984774526d89b03ecd78d62d4d95ec1dea6',310358000,NULL,NULL,'a2815a72842de9330b82b8901f18116f208c379657cf8610c3510dad19b64124','0e41315274bae74c9f309fb3daed2ff035317c7e7e5d6e00e81d2223a5d86b29','947c26e038e8f976092c10dd4ec965c0bb627261152928bdb5dcdf663f05d969');
INSERT INTO blocks VALUES(310359,'4fa301160e7e0be18a33065475b1511e859475f390133857a803de0692a9b74f',310359000,NULL,NULL,'23acd53757b9ce126a8817e2727a54a23b57246c92e6fda1f16fa4d5db378973','46d2a31cfb1e53c28451fced507fc1bb1d9861abee5c62281fcc3edf77f4e3cf','0402a423f8f8914ec0c516ad4e6f69caec7564ea9f0e1135b3e4396a9db01861');
INSERT INTO blocks VALUES(310360,'cc852c3c20dbb58466f9a3c9f6df59ef1c3584f849272e100823a95b7a3c79f0',310360000,NULL,NULL,'9325c1235f22738cd4897884005d5763db8b792930a968c1c6f75300f087e484','86130bd1bcc92ab8d41e85e5275eb90fdcbd531e42559caa4c079be7d34bf0d1','4848cb76e6cf48cb14f775e242702029b6287d90846dfb36dfb26cd2e7d1f3f8');
INSERT INTO blocks VALUES(310361,'636110c0af5c76ada1a19fa5cd012e3ee796723f8a7b3a5457d8cb81d6c57019',310361000,NULL,NULL,'30f7ec0f50ae1e4d4dcfbbebc789dfea4669c2a21a4d251550fd6696bce94952','c048226ba80b051eebee0b3b87077e1d7ef5778ae2e091a9c6f6f622414a6524','21559849db914946db625898c8f4a93b9c4da0ce4be756d61fd0f21633804dad');
INSERT INTO blocks VALUES(310362,'6199591a598e9b2159adb828ab26d48c37c26b784f8467a6bb55d51d7b6390f2',310362000,NULL,NULL,'6fccf61f9c49986937cb13205f4ccdca952fba67c1af89d8c05da51b11ad98a4','f627f8a22f662dbd32576a0f80ee0d27f022ed85642884a94e30a3fb09ab427a','cc96955093e814271a1db046d714b72301285fc97eb710010b6432dbe6b1e344');
INSERT INTO blocks VALUES(310363,'a31967b730f72da6ad20f563df18c081c13e3537ba7ea5ab5d01db40e02647e6',310363000,NULL,NULL,'74a243525a58bb5d1c051c10d1ddacfd307b69fdbb2da618e079322f3d317b61','f9374737abd39ce4da133edc62e2f5696f80f6be7f47ef000a67896d6d493d12','a678ff13b913f84704b29b36d8e3cfe54c625ce4ec3c2196dc1e62260a70ecce');
INSERT INTO blocks VALUES(310364,'67025b6f69e33546f3309b229ea1ae22ed12b0544b48e202f5387e08d13be0c9',310364000,NULL,NULL,'5a0b10220431a5d6777ef9e49ba6333c7026f04ae450d48a7273732e8cd55ffa','e8cf590674154680fde5ef8e4fadc0cfc8284cb13e2337deaa7b7129ed7e3898','27d9cd3394a30020e2c6a180db04ed5b101842e29517f88710f5d0b3a558bb09');
INSERT INTO blocks VALUES(310365,'b65b578ed93a85ea5f5005ec957765e2d41e741480adde6968315fe09784c409',310365000,NULL,NULL,'50e97232160d4b608299961f420a6218588c5650a8e45295a08f789a49b25d20','01e51c371a5b803d2ba8a178118d5e0fd7988534b8322addc5c506921fece259','6b36d50a01c982083d1274ec1a79704e4f9397a6cd7a07783e4c3dab61160b29');
INSERT INTO blocks VALUES(310366,'a7843440b110ab26327672e3d65125a1b9efd838671422b6ede6c85890352440',310366000,NULL,NULL,'4521f3e3fe9fc9254b0d66fb4cf24ac72c50808751791e5752195c0dfdb403fc','6d907b3905d214239f4a65cd03fd789c52603ae846130b281ebe25404c7ef296','a740e81e54466897093dcebbb6b724650cb65a25a8f598e180310ca9358a6ad2');
INSERT INTO blocks VALUES(310367,'326c7e51165800a892b48909d105ff5ea572ff408d56d1623ad66d3dfeeb4f47',310367000,NULL,NULL,'9b89619d958dab0246a3f2c8b8f402bbeb3a59637f492b7119a9a84bd939b661','10513e832ddcfdff88c6e832df4e7c6d9b0ad819535ab1a1c87b1be8d9528d3e','3b50879e9fecc95e755f8b3a0433fccd3436fad86007f7e6d83153b31e9d05d4');
INSERT INTO blocks VALUES(310368,'f7bfee2feb32c2bfd998dc0f6bff5e5994a3131808b912d692c3089528b4e006',310368000,NULL,NULL,'569a5946690bbc8251325d0569181b4c276eedbaee5885b816ebbef86d01e196','88b831011581fb86a2ef7509c8d77ed4de149be0a566db38062368908b9a7794','d3eb78b24aa6c8524412a47f0466d422b9f88bdd89d79566b16deb6971dd28b2');
INSERT INTO blocks VALUES(310369,'0f836b76eb06019a6bb01776e80bc10dac9fb77002262c80d6683fd42dbfc8da',310369000,NULL,NULL,'0ca340f24633d8884a88fbf3c7c9280c31460745dace8563b0b66ed382e0fa2f','21fae51d8aa9d7a97fa558e7f1bc134b3ee5ad434e0ab754a7eec10b097738d7','ea89ae6a4f4378de92cf7069e1ec5f1e34bdf0b03bc51c9d5662d92b9eb33b9a');
INSERT INTO blocks VALUES(310370,'9eb8f1f6cc0ed3d2a77c5b2c66965150c8ceb26d357b9844e19674d8221fef67',310370000,NULL,NULL,'290093d9212196ee4c03b9eac0245803158dba2948f158e2c74f8dc10ac09329','742e2f3934f4bd0a56ecac0a0dc7a64fb290068227abbc26c9e3b3ae14cdb8d0','923ad8a22cf3037723a0df818da724d03977dfc8e73022a3c5e9b9236ba0c845');
INSERT INTO blocks VALUES(310371,'7404cb31a39887a9841c2c27309d8c50b88748ed5fa8a3e5ba4cc3fc18310154',310371000,NULL,NULL,'fa6616279666c600602c38434c2b0fc9dfa1e551513e4144419efd45e0ee0462','e4b4a96c0176c38c3ab8eb2668b95b6bd65e4f6a5cbb85df501abc2282a39ec8','acc0cc165be662e07f439b4139d5f01a20d92232a0d8d245086bb2dd7f10361e');
INSERT INTO blocks VALUES(310372,'d3a790f6f5f85e2662a9d5fcd94a38bfe9f318ffd695f4770b6ea0770e1ae18d',310372000,NULL,NULL,'25d0ad708dfe99367db6dea83491440f2c30421a5a7c4fb024d0ed79cf59b1aa','57fb95ca0bc3e7bafbe4b1b28dfa64c9d8a20439915324400bf9dd5abf7d7902','f3788f6bca53c54bbaec169b45587760d9a9ef4d2744ccd3f62b078ee9f82021');
INSERT INTO blocks VALUES(310373,'c192bec419937220c2705ce8a260ba0922940af116e10a2bc9db94f7497cf9c0',310373000,NULL,NULL,'408be37b314e37b6192d85d81c706f9e25c0d7e5a5448a6ed6284d324f587054','f60bde492c471bb1ad02edb86c6f3a742fafefd43a8652404c05b346112f3805','a900d2ee4d1adcf1c33b1e47f173fa24bf02e6f6ac66d8e1c7e782ee1375d2e0');
INSERT INTO blocks VALUES(310374,'f541273d293a084509916c10aec0de40092c7695888ec7510f23e0c7bb405f8e',310374000,NULL,NULL,'3153feb773ab5352e9380d3faedf2f32f427dd35b5de78b52293abe855c1091d','d698b5af9ca1b44b299e1e83ef038156da398c2d5d34484e10a224998c278f7d','67d2c5f74b1688f695de25124a4139a096e6045aa889e09f2803f1f1bdcc67f7');
INSERT INTO blocks VALUES(310375,'da666e1886212e20c154aba9d6b617e471106ddc9b8c8a28e9860baf82a17458',310375000,NULL,NULL,'5364cf94d87ffdb49360513b1271c5f107a42830cc8ca70b4751045dbcf92eea','cfae0933bb6389c1922405050ad24c9ff7fc58d158f9d304ea89a15c7f6bc0d9','0bb651e36b9d2a55b6bcf38fca8703607f4687c1a619bc0874213de0496b536a');
INSERT INTO blocks VALUES(310376,'5dc483d7d1697eb823cba64bb8d6c0aded59d00ea37067de0caeebf3ea4ea7dc',310376000,NULL,NULL,'ad88937d28e8e5e24af4af424cb4004005d71b7d056d8d93b9f1eeddeeafe4f5','58c5fdb654c1f13ade7866fa762422af8e5ab63feb54fe10f919c75754ac876e','2304fafb86439fc22d5276fc287a131a7f3b301e62847a15406bea1f6a694097');
INSERT INTO blocks VALUES(310377,'f8d1cac1fef3fa6e7ad1c44ff6ae2c6920985bad74e77a6868612ee81f16b0b3',310377000,NULL,NULL,'0e30a4b710daab3563f7fb624dd4170e0026e60574742b57cb64cc03d621df15','23a56fbc7f6831f5d917ba536121f3697e7a77c14b353a6ad32b2327f0c0a435','15aaf9a0364bdd6de258c5b74eb8fb8832c56d2afa55ed72fef0a0b7ab786d13');
INSERT INTO blocks VALUES(310378,'fec994dd24e213aa78f166ca315c90cb74ee871295a252723dd269c13fc614ce',310378000,NULL,NULL,'7fd86de094040b85e820255f840b863f0725c53738d32952fdfc58beae9c6589','ad376ba1493c2e6d5d8cf4f4b73d5b41e1183a77e412a115360cba89b4afd566','a58cee93379f3902df8122fecba2c780bfbc9fa5c40ebe52a6bb0af8457167c5');
INSERT INTO blocks VALUES(310379,'d86cdb36616976eafb054477058de5670a02194f3ee27911df1822ff1c26f19c',310379000,NULL,NULL,'fd89c38a53a75eee1c46a3e29cfe1bdb4956cd9bf8de15b582f0bf0d90dfa13b','f265fee3edeeddcef40987342cf3b9d1123b60188a18cf9702075ce2db333b2a','d7f22622a736694ab07358c29816603ff419eb78687a26bbff3ee62c37b1d6e4');
INSERT INTO blocks VALUES(310380,'292dba1b887326f0719fe00caf9863afc613fc1643e041ba7678a325cf2b6aae',310380000,NULL,NULL,'2967d25d8d46df256d7bdd08a1f2dc77cb42af8adb2f53830d2d9abfb2981f99','8129bba2c448bfad0a38a5a628c94f53b5c67e55dd519ce5d6f115df9ba9468c','dbea604375d43e6c3f8b1d011f1b45c16d9e621ba283bbf2b6a8b46fa48e26a0');
INSERT INTO blocks VALUES(310381,'6726e0171d41e8b03e8c7a245ef69477b44506b651efe999e892e1e6d9d4cf38',310381000,NULL,NULL,'703a73971fe4f5d48ec8393c7e8dc8cc13374ab8a2d52c68988593c4de8817f2','aea2ed587070a6827acd4c8f138297f34d505e4648e7bb0973d9a78b86b07ae1','4550d61df7775fe12e555c4d34aa90715b65f6ae7b939f9ce5052cedea14fbb5');
INSERT INTO blocks VALUES(310382,'0be33004c34938cedd0901b03c95e55d91590aa2fec6c5f6e44aec5366a0e7d8',310382000,NULL,NULL,'198e36c164a6f40c76112501fa1c70327e3e005a042d1369faf0126f41d58d62','5b42f3c4a401c11bcbebd7dd3a64a63bc3773c28e2da33da49396e7e00188d2d','4b989366d4e4fa297ec580dd66f46219951d9e19b6a7092ff39815b57b1fa1db');
INSERT INTO blocks VALUES(310383,'992ff9a3b2f4e303854514d4cad554ff333c1f3f84961aa5a6b570af44a74508',310383000,NULL,NULL,'591cf03f57957fedb0522af2ca5fe111c5828157054f51a1b3fd9cf72b429a28','ea8a3bd805015b2e6f86027ad5811547d7d856e19790bfc066d1f451716b6ecb','a23674a7534c2aabc197f9b2d9898ccdf04c02ad08e2cd071a1684d32afc3c89');
INSERT INTO blocks VALUES(310384,'d518c696796401d77956d878cbdc247e207f03198eabc2749d61ebeadee87e5e',310384000,NULL,NULL,'5c911e05c1670a675082c98b242b80bc5ad3ddd105ae4d4bdb2cb6601e172a29','1ed883eddf6a9564443752adda986dc1f59d9d9a4c01fb38cb1402e7f2f01ee1','6b0c6e4025beb4069c7262f5d70f87674d4b34dea7e844cef486fd3970b9d992');
INSERT INTO blocks VALUES(310385,'2aa6a491a03a1a16adbc5f5e795c97ec338345cfdf10ff711ffb7ac3a0e26e28',310385000,NULL,NULL,'1944f881a1202cd4aad1cb089bd916386581b94c96002cdfa67a69d7b537324f','52d151977f6c0426df9594ff57a935a53c1b621b75f0dde7569d0a9eaea9c3f0','e98ae75a6e4c56582466eac2bd2e0983d6eb1e35e3658bff701553e87789d2c2');
INSERT INTO blocks VALUES(310386,'9d19a754b48a180fd5ebb0ae63e96fa9f4a67e475aeefa41f8f4f8420e677eda',310386000,NULL,NULL,'bf31cbeb8284aac77b6515ec7388d67e76e19ba79452b150a833c13c892c0ee8','4c9019e6161a77d73dc70fd540861ba9e7530fe0da68e368ec161526662e3551','9920d44be1afb894f3118983fbc5ace6145ce63fd2ef8125636c8bbba1ad887e');
INSERT INTO blocks VALUES(310387,'b4cac00f59c626206e193575b3ba9bfddd83bbfc374ebeb2838acd25e34a6c2b',310387000,NULL,NULL,'3f82211082a2d6981de51244bb0483eebfb3bcadfd48b80151fd1c89694e2b3b','3af1ef1e174899628b9b3112649a9ad9dbca82d17e8e249d363eecf2cc2a93c9','3ec322122d2043088798e93a9f30ee16d6f3d9c78816e64328feeb0ee17a17f3');
INSERT INTO blocks VALUES(310388,'41a04637694ea47a57b76fb52d3e8cfe67ee28e3e8744218f652166abe833284',310388000,NULL,NULL,'59c3a3c5648f18274642df5050b117d8031f10c46be63b5864f30ecec69f0c09','9ceb95e1f59bd5d578956438c4594b0432edf6d65117ff87e407188216739da4','f5e188423a5ee81bb2fd8c14e332f360e86e04e0e1bc74b0696224c99331c3a9');
INSERT INTO blocks VALUES(310389,'3ec95ae011161c6752f308d28bde892b2846e96a96de164e5f3394744d0aa607',310389000,NULL,NULL,'fbacb621beff1e0769d716ed51493afe97874941feb7787b5cc80916e3ed09ac','f689de4d65c1fe5fd81d74cbcf1049cea676b45d2f683c9e094fd64b52a51fde','aa0d748f03e6252d72101961c55ac0e61e3276f0576f844f627b9fcd3d55e57f');
INSERT INTO blocks VALUES(310390,'f05a916c6be28909fa19d176e0232f704d8108f73083dded5365d05b306ddf1a',310390000,NULL,NULL,'a2c398743a97092d8ea6875970fb1662470fb5918f09e50c132c29ee6fcc9b35','ed0830abdf7c3e7f73aca132871c3ddf18ee19c78261b5f4bf08e82783666adf','f23c09889c150ce6d42cd9c38d3e7d8e1a75caba471816f2be56b96d095baf53');
INSERT INTO blocks VALUES(310391,'fc26112b7fdd8aaf333645607dabc9781eac067d4468d63bb46628623e122952',310391000,NULL,NULL,'cb3842fc91685c97b6db5ab71e1586259c83c619ecd57dd653a213b5c4a9f9a1','f518b798fc0829f85fdcf84f3cfa3f01959490b9152dbc598ddb4a9d777b5022','2c512ccc3c224d546046abcc01f9a3e0b8bd676a8819be29cc75d3af520a113b');
INSERT INTO blocks VALUES(310392,'f7022ecab2f2179c398580460f50c643b10d4b6869e5519db6ef5d5a27d84a1d',310392000,NULL,NULL,'780ea5e6adc1e9ae328efe2ea25af76ae2e228c98b475b6337ed84e5924e3b95','2b390bf3a46aaeb84b8cbabe74d6cf5ecedbc7d2bca794849bc49485c59ee435','40772d0abdd25a951d9e2ff5a2333415b8657e3978236b44bebfd76506798619');
INSERT INTO blocks VALUES(310393,'e6aeef89ab079721e7eae02f7b197acfb37c2de587d35a5cf4dd1e3c54d68308',310393000,NULL,NULL,'6f61090175f1e398ae20dfcc41e5075327ccbd297c786c8a09a866a77836d429','5d83b842406891b8107855b810766c9dbe28cb81fca3620895bf3906916a262b','fa33a56727642bdbeea509575c77b6db838acec7f2b265ab80afeae0d2f78468');
INSERT INTO blocks VALUES(310394,'2a944743c3beb3bf1b530bd6a210682a0a0e9b0e6a9ff938d9be856236779a6f',310394000,NULL,NULL,'8cdcec6732f3d4f2da04edc5a59cbe67fbb27ea069efdc23e4bc92f055fe4223','65843d7165c46a3215317747d0dca836a1bbebd7a0f6a901492befff13e0601a','26d659fe4f6ff812f9d6e0bc5d978363a242dfacb3267a0a675749b42a440349');
INSERT INTO blocks VALUES(310395,'19eb891ce70b82db2f2745e1d60e0cf445363aaff4e96335f9014d92312d20e4',310395000,NULL,NULL,'291b2e82b5bf5ebee0ab534e53cc2a748429d7248ba1194a8f673552ff65cdea','7a2fefdb7861cc1da2bc098a9d8ad81958de7a9c2dbe3372ad3b22e5658241a9','b3d2fc4f937bfdd727c11568fb62eaba4489f522c3f5d691a7b1e83845b5d898');
INSERT INTO blocks VALUES(310396,'aea407729ac8d8e9221efd9d70106d14df6aaf9f2f87dc6f490835a9caadf08e',310396000,NULL,NULL,'9698aa62d90bffb57f7b8b92e4275dd6df0b53d5e539dbe3440cc8f885881e65','02cfbe29768cfeb569bd03124d9c1e5590e39c2d73dd516ad5d79eaae6acc2c7','da6ec3742d7f593fa6686ea8b12a4781abe3d5f9d7a668a10ce1089df81b732c');
INSERT INTO blocks VALUES(310397,'7c429e56a19e884a8a77a759b52334a4b79404081b976270114043ba94d7985c',310397000,NULL,NULL,'bcb427bbccd91cbce4402f5b9495d789a81e22fd80467f8023e33b98f487eda2','7f79e4b1c68bf12a2e9c79c4b2959c0324afeb4f65d01b5163fdef17efedd9e2','39618600d15443170de070eaddf793b37d08ff3bd0c0d7109b90fe39e9c57ba1');
INSERT INTO blocks VALUES(310398,'55c046db86dee1d63c0e46e6df79b5b77dfd4ab2ff5da79e6360ce77dd98335e',310398000,NULL,NULL,'3833e3ac7b7b74948268b6588ecb6b6752ab22138e0d2f477e3dbef12adab776','0c806e1c222a20258d4bf650bc8102fb4ced668e4c7c903d9687cc5d33b9a43a','d19f7a66db9e8bc3fa6982457a3246965b4572200186d854c8670792bc4559df');
INSERT INTO blocks VALUES(310399,'765abc449b3127d71ab971e0c2ae69c570284e0c5dacf4c3c07f2e4eca180e7a',310399000,NULL,NULL,'c15cf8452811e6df6f5438f8343f9a3421e75eb9aeed8e42eb0658e89c64dd51','cfefcbc6458992828a58c6515679241cb6ef8a29f81fba08728ec4eac058591e','5240de52f5a307f9b34b418c01924686c7c3aa4b5b5061a6e0e49ef9ce4fd648');
INSERT INTO blocks VALUES(310400,'925bc6f6f45fe2fb2d494e852aaf667d8623e5dae2e92fdffa80f15661f04218',310400000,NULL,NULL,'bd993e2a64b62f6c376e338e9beddaa0ac0501b39883506f2472e533bb19cbec','127b8f5305f048b7665efcf09f9c79c41866ff5966714080fcae4adae2e5124c','6c86e7949663443cfb4ba97ef2d7189cccc4647601fa64a5921d5715bc8cc833');
INSERT INTO blocks VALUES(310401,'f7b9af2e2cd16c478eed4a34021f2009944dbc9b757bf8fe4fc03f9d900e0351',310401000,NULL,NULL,'e6dd67cdf805c23e353ec25468f2ea830da46e4104dbc537e9e15a5acc1b28fe','8f918be21c29755fded50054a9eca335694ff6bd5d2fba330850009d4a7957ae','587a2517403b1060121d15f41f3b63dd5fbdf99af509f65f71645ee44f772e7d');
INSERT INTO blocks VALUES(310402,'1404f1826cd93e1861dd92ca3f3b05c65e8578b88626577a3cbad1e771b96e44',310402000,NULL,NULL,'6b19a39e68b8418c2eb1650bd1427438dfd65bf627bb6b50ae3a903c9169ff4f','6acd3ff098761435ec5a10dccf0af3319a0bafd553ce410d99fb04e1846c6cae','f97c3b4ca0f1c364b3903bafa2792ed7b1ac688223a798b52c90d69cbba2c6ad');
INSERT INTO blocks VALUES(310403,'f7426dbd4a0808148b5fc3eb66df4a8ad606c97888c175850f65099286c7581c',310403000,NULL,NULL,'bf22dd1b8b936a1eff32dea79c9cbffda251bc59ed2754f73c139155eeb2eae3','481dddf8abf7bca1d5643aea6951cfa456de5396529a51772f62943961a4e8c6','712a545b0b5c427afb92ea50e27b66bf7b706b0819ea95538d25fd5c045ef11a');
INSERT INTO blocks VALUES(310404,'401c327424b39a6d908f1a2f2202208a7893a5bedc2b9aff8e7eda0b64040040',310404000,NULL,NULL,'2dff8ef48ea2026e72bb327368bff21d40eb321ef8c9ab5552c6b9f40dadcefe','b685c3f68b9db2260654c787917ad88ebb9f4cb884ffe18d7f53fc11c76f1eea','30e696c21c11652db5a0f65064b8989dbf77d6b5b3e1a5e312313ec808d0692d');
INSERT INTO blocks VALUES(310405,'4f6928561724e0f6aab2fc40719f591823ca7e57e42d1589a943f8c55400430a',310405000,NULL,NULL,'35b2f3fb27f707493d53ab0eb8eb239891be2a050a1f7ea9fffeacc1b6e6056c','2b24596418543557a5cca9a927c2bfef992736308101cf23ff576804b713bf76','693d5173cf31683419894b3300ed5a45470d729ccb52dd62bdcb78bb7bb77b3d');
INSERT INTO blocks VALUES(310406,'6784365c24e32a1dd59043f89283c7f4ac8ceb3ef75310414ded9903a9967b97',310406000,NULL,NULL,'4a962a898f5795990de43cd3133a60b5b969ad366de6bca8d0b9fcb366759d1a','923996f98a5481f7c74e3ef12cc08de3c9087f71d4382e2fa007f51f697ec9cb','13a0ae7c29fce6e552eba4dcdec91323a18c55fc45e16601c90aa723d3facc08');
INSERT INTO blocks VALUES(310407,'84396eb206e0ec366059d9e60aefdb381bca5082d58bffb3d2a7e7b6227fc01e',310407000,NULL,NULL,'18e8aad129099c20f268ef8a3664253f8d444a24e3c4942369bbeb80fb76c862','a866c0f21a58a53aae6e5b1f87bacd16d352e5e3db58093526073763ab1cbcdb','887c75f0ace2277b5b138709cd74478eeb57c740c190b8da4b2b91974c0ff26d');
INSERT INTO blocks VALUES(310408,'4827c178805e2abae5cb6625605623b3260622b364b7b6be455060deaaec2cda',310408000,NULL,NULL,'b694511530b99c6a6d405871f2fde7470baef8e0a2545b598adce5c3b9234765','b78ea18000b133c089a883173a2b0fc8583c430230e7c396daefdea33d70e51a','85b67c778ef1499bd807877feeefe833139447cbe16fc1fbd0bb6bdfda54f2cb');
INSERT INTO blocks VALUES(310409,'01a719656ad1140e975b2bdc8eebb1e7395905fd814b30690ab0a7abd4f76bba',310409000,NULL,NULL,'cfc8dcee1ef668455b7c078698de8c164abcbfe7f6159fe206faeee7b0ec006a','3835c645460940fbea37ba725ab1f09e02cd84477ef4f150552beb224630094d','477352ca8083e32492afec8cd47828d5c1ec57681839b565ad0fbd1b1da04507');
INSERT INTO blocks VALUES(310410,'247a0070ac1ab6a3bd3ec5e73f802d9fbdcfa7ee562eaeeb21193f487ec4d348',310410000,NULL,NULL,'52eeb77c0ba4767d59e4ba0e243032c44ae83abea1fb407c2079e58e869d6437','af91062623106d9569372324ab92980bfc8ba014998eb76675e11818986757e2','10e51a6e8c08b0fa4c12fbcf47a05a075db0f63dbb1ac1e95bad4b8a78086562');
INSERT INTO blocks VALUES(310411,'26cae3289bb171773e9e876faa3e45f0ccc992380bb4d00c3a01d087ef537ae2',310411000,NULL,NULL,'10224812cf36a49d15040fb1a3ad3e580f4690e8309dda99713bade55f2299d4','b2d644fd7f5e7c022aaf5546eefe3b724d3545825bd2a0c9919d294897092563','0a1668d5b4e55c03efe27dba83240683e94b54af3f7bfecddf4a9c9854ce3232');
INSERT INTO blocks VALUES(310412,'ab84ad5a3df5cfdce9f90b8d251eb6f68b55e6976a980de6de5bcda148b0cd20',310412000,NULL,NULL,'2e095263dab63461abb4210a78c96ba09181cdb55fe67113edf6badd5da8a386','3cb82b28913f9800f8a3f00f3b5aa454b333cbf86bd663b5d817174ac71c9899','49d97791cd1323813453d9c0e522638f5b8ed8c90dfe82018ad3630815985795');
INSERT INTO blocks VALUES(310413,'21c33c9fd432343b549f0036c3620754565c3ad99f19f91f4e42344f10ec79bf',310413000,NULL,NULL,'5201dd7aaf4dd358441bbca3ec6785eb9f7bb36d25e9aca9e5cecf0e9391b7b3','1b69287fad65b0f27b723642c25301f71bded84abc7dffa2398f953394c2b9a8','a72fa58e9408bb4ed00a60ae07005a686eef7d8d0d554791f8daef121bce306b');
INSERT INTO blocks VALUES(310414,'8cff03c07fd2a899c3bcf6ac93e05840e00de3133da14a413e9807304db854b6',310414000,NULL,NULL,'95de8fbba49b748c4fa28565b47230dd294ac6b02906d1dd7aeea73126db9513','e3175518f536a193758deb0ab4d8668c0ac884f2861d1a5c24280ea024203298','7cfbd3345c807721fa9531fff24bc40ca3cd0b438dce9f9a57d810c71648f993');
INSERT INTO blocks VALUES(310415,'dd0facbd37cca09870f6054d95710d5d97528ed3d1faf2557914b61a1fc9c1cc',310415000,NULL,NULL,'53a7b4628a5273f5b893f64af2db6d66b5b9e4ffe5ae5076b274537245f53b6d','124c5ca5717fde6ede3541ac347325b1f7d935e552cb6e4bc57356386bd763d4','db1074c35815dfea8b84655af82c1824265ad6c6647b9430f617ddce4b07ddcb');
INSERT INTO blocks VALUES(310416,'7302158055327843ded75203f7cf9320c8719b9d1a044207d2a97f09791a5b6b',310416000,NULL,NULL,'f38e62a046767b352776b03cc9103137061d2ebc1365a6589e8604affd29ea84','1784a24ff02476720c0def7e911396aea1228d23d9a3bb0b20ac699b73ec91af','3a8913d68f944d7e2bb6eb4906499bb041a2d7ab96f30a08c648c652c7d67592');
INSERT INTO blocks VALUES(310417,'2fef6d72654cbd4ea08e0989c18c32f2fe22de70a4c2d863c1778086b0449002',310417000,NULL,NULL,'752734f6cb598502a13f567da58739e021aed45268f52c3a56aa94c77dbe4294','290b324c7d60e312c14afa9a6a6aa72cab014adfc1f8fc0586bee0eb570faa23','1bc97e4e6fbdaa86343fc9a94f13154d83a71e5defcc1baac9ea4e1d72f491b5');
INSERT INTO blocks VALUES(310418,'fc27f87607fd57cb02ce54d83cec184cf7d196738f52a8eb9c91b1ea7d071509',310418000,NULL,NULL,'778a0c66fa9454d466fda8bf21ac02b03d80e18380cc79bff8b481d7832977af','118d42b13141af0339ee3d48c6c97d84bf751491fadd65ce954bfe9b0c93e1ec','1fffa21c40db871990d562ec7080c9d2a46aa36efa6ddcb6a1f01cbd7e72ff76');
INSERT INTO blocks VALUES(310419,'9df404f5ce813fe6eb0541203c108bc7a0a2bac341a69d607c6641c140e21c8e',310419000,NULL,NULL,'1dd204b4df4f865718b1cffb54a452885c04a524c4f9cd6be0e92bcc937f49db','66ddadef87339bd049794266635e47a0fa7d0079768735e6d8f7bd7f62635ee2','738a6ee41f342dde7a6e767e5ecb6ae24a1134999a3bcb5ef23f0a32ba42c11d');
INSERT INTO blocks VALUES(310420,'138b3f1773159c0dd265a2d32dd2141202d174c2e52a4aeac3588224a3558372',310420000,NULL,NULL,'3b77f802ef867f0fd92f1dfff4f7c5ad074ed51f0ed2b1a5d39f1f44e6aa7ae5','b0adc013c08aacef6802131a6faa05ab1cc82873cae62e420d1f3c61dfc61976','a46301892d92761ca29e475ca377354c8b8b0e56595affdd95027f775c843203');
INSERT INTO blocks VALUES(310421,'71fe2b0e02c5cad8588636016483ddd97a4ef0737283b5fd4ab6ea5dc5c56b9a',310421000,NULL,NULL,'6d417941e380b66715edb4e74fb63026f35411ce7782afc0a6abd2f5d6193934','f161b0ef8e95eb735e66dc90e594a652dc3ea845a5d3152c4e6cb7d7ae6a1b95','28be8cb7033bad46a9a703a98e984954181218551c29cca2da3d3851126bb620');
INSERT INTO blocks VALUES(310422,'cd40260541b9ed20abaac53b8f601d01cd972c34f28d91718854f1f3a4026158',310422000,NULL,NULL,'593383ba8869cf5afef0a8bd1212a9a87e69ed1f79d24423f3e268b22038d865','c25c315280a0a0a8372fb8c6d2fd0f46d78a8942c071732feb0d9f63a47d987c','174a746cd965b0c0a5b209b3fcd8a8dec820aaa54c9296d745e0669b147a3509');
INSERT INTO blocks VALUES(310423,'6ca0d6d246108b2df3de62a4dd454ff940e1945f194ba72566089f98ad72f4db',310423000,NULL,NULL,'03ad9d534765ed15c02046dd7076f8d0f9332b987336f779a52ef7da5a63d2bc','ddc40d3b3f14271583070e2d4bb0fbb37d1fb16680cc259fe27cbabe4c3dbf64','4f29da85f07fc10b7efb8db3fc4e6ae21d4d7db3df459e61ae5fb58e2764e72f');
INSERT INTO blocks VALUES(310424,'ed42fe6896e4ba9ded6ea352a1e7e02f3d786bfc9379780daba4e7aa049668ad',310424000,NULL,NULL,'028be1a76113906628e18a5ac0b00db7d8769e2450f145653c3b5f117cce2d1d','44965ecde85c07503f2e8d48b152698a1ccea12cc3da279b8c4dc1412f414507','fb89a8e5739f8206973e843b3423153e57e9297bb96c5ab974bbac9ab7f4f3cb');
INSERT INTO blocks VALUES(310425,'73f4be91e41a2ccd1c4d836a5cea28aea906ac9ede7773d9cd51dff5936f1ba7',310425000,NULL,NULL,'83d4a7d8ffab3c5f6d2637ee98a2ed4bf9633f54a630a65c882190bab089bc2d','21d9f49fbd865e8579127f54e3751a79f60e95de0781d63c29f3935580f2af5d','b2efda7810e52e446a76821672f108eb7b6dacf772170e76c781aabbcfe08afc');
INSERT INTO blocks VALUES(310426,'9d28065325bb70b8e272f6bee3bc2cd5ea4ea4d36e293075096e204cb53dc415',310426000,NULL,NULL,'7642193a01f93b2511299f4a024138db83f9affa5e14145bd0a4ff0a12fe89b9','e15950c6062e715c258f6c0bd52ec7934118839de8a2d30f9b99a4fa36ffc758','32bdee15d380ed7052e890b83c15a477f62c375683feebfaf901605310454afd');
INSERT INTO blocks VALUES(310427,'d08e8bc7035bbf08ec91bf42839eccb3d7e489d68f85a0be426f95709a976a2a',310427000,NULL,NULL,'8e53bab070408894fa8b2b12a8628b2ae262567533f2a1c49dcb51e564d8baee','135341ad1173a32548c9ae2d51141d08b2b859fa809d7798e739e82f540b5495','6f5c02357ff5eeea49872ceaea917aa04db52ee7c0f77865b527502d2c95dd3d');
INSERT INTO blocks VALUES(310428,'2eef4e1784ee12bcb13628f2c0dc7c008db6aaf55930d5de09513425f55658a2',310428000,NULL,NULL,'f0af90a06b842c2d6646744b9c7e851e77cd73f27c1e97282aa3e774acb5206e','388ad2e27ea4d02aa3e1b2e61762f4ddd68653f448fbb038f318573191f68694','de00c0e3cf2dd3f904660d4ca578f277c3e23127d41c6643a836835c7432bfab');
INSERT INTO blocks VALUES(310429,'086bfbba799c6d66a39d90a810b8dd6753f2904a48e2c01590845adda214cf8d',310429000,NULL,NULL,'d96b15c84b51ab0ac9e7250232ec744bfea32aaa46b3202182bb1ba30637530a','60f39ff83d2d43e1f0e01deac6225a804dce79b5c24708af7f89872f4bb61b3e','8e899ee9d7e17c23442c022ec85cd45f87d7bafd6be4148765f7bfdedb44468a');
INSERT INTO blocks VALUES(310430,'870cf1829f84d1f29c231190205fe2e961738240fc16477c7de24da037763048',310430000,NULL,NULL,'5877f31065e08853d538bb8ff2ab3204d2e7c46003afd715c7ab7e3eba36171e','21935c9791e574de4d1cc47cd14640fba2292adcef045627bba733ee131356e6','bd15f568e91896c6eefc4d4b73ade5eaef94634e1c1c5ac917632f900b11e4de');
INSERT INTO blocks VALUES(310431,'20b72324e40ffc43a49569b560d6245c679e638b9d20404fc1e3386992d63648',310431000,NULL,NULL,'c7693ebfe358dcb264ac98eb74f0d35b8102bc49a189d678c4aa83b792b92b01','0b340977efe8de0ce3c40bc8afe5e2e4ac53d02acc4d394b5ba09a81401b7cbc','5d8c42a43e441232d31e4a7e78d35009a68c46ad5d9d4ead1650172dbfa74adb');
INSERT INTO blocks VALUES(310432,'c81811aca423aa2ccb3fd717b54a24a990611365c360667687dc723e9208ad93',310432000,NULL,NULL,'2e4118a5f40e5a2d4da07622568a61e52ecae05dacd3dd54364015666b9ddf0f','5300b6f6269b331fcdb2b2e6d989e1893356ba68c878e87a9e4d1af22b612eea','5532d9a9fcb13650b38910021dd6d3404e1a32e8d2da2c883b0fef0ac03d9b28');
INSERT INTO blocks VALUES(310433,'997e4a145d638ad3dcdb2865f8b8fd95242cbc4a4359407791f421f129b1d725',310433000,NULL,NULL,'4508c61899741ad3637f891664cd17e8d8dce2147ec22bbddd23d18be7d4f5d8','1f194dd792783689689ecf474c8d2153b55390b2e8963f1db7b62c846053288c','726beef240a4cbab89548dbf702328b40dfdb2710c81bc2287be7fa55d801b16');
INSERT INTO blocks VALUES(310434,'61df9508e53a7fe477f063e0ff7e86fbb0aef80ff2ddedc556236a38f49ac4d8',310434000,NULL,NULL,'222a7017a5159405dfa7ca716a368f84df446612b2e969ec775a56297f67c445','e51bc696e3c1c5ee8aaa9520397a14d90a28e1f0deac0d4b938d89cbc4f80484','997fb50b50258ed301da6bdf70d4c074f072b53e21292d1bd38cdb89da74b5c9');
INSERT INTO blocks VALUES(310435,'f24cf5e1296952a47556ac80a455a2c45da5c0dc2b388b51d235a3f741793d5f',310435000,NULL,NULL,'cf0f27b94a70b0dba7ee5391c51df323c154c767b21e7f18696cfb93e25e663e','98c6cd7e98fcefdba036098e65c94ff97e9f9f7cebaed77adbd3ac5aeb74a005','719f9462ed16078099a11699aab0eafb8ffcdbd4e61cbb3939d995a587abfcbe');
INSERT INTO blocks VALUES(310436,'a5e341ba92bdf9b3938691cd3aab87731eba5428bb61a804cecf9178c8da0c19',310436000,NULL,NULL,'15455076d1eb6681233124bd7f4fd59586a22067bb008d8132e31c0019f3990d','0c3d792feef0029c2d71200388d5091c0ba27f2c1bbd7245361b0da89ed54540','09004be309004451e900a5f434ad2489f702f8d8a4cd9f9cc6c943425e96ddaa');
INSERT INTO blocks VALUES(310437,'9e18d0ffff2cb464c664cefc76e32d35752c9e639045542a73746f5ec2f3b002',310437000,NULL,NULL,'03e6c21526a9e7ad688f8ee47638b2519b2a1ff0c47332da366a1077a9d93dae','e0190ab0dfba206394d2e46714a9b216acdcdae3de7e8d2def62f01d61689f9b','872a230b43a30fc4d32c1b496b53bca8f8e21344f912b24fcb036dd796aff445');
INSERT INTO blocks VALUES(310438,'36be4b3470275ff5e23ed4be8f380d6e034eb827ebe9143218d6e4689ea5a9fc',310438000,NULL,NULL,'dca613e290eaea92a4bde4f759fca67923568f0af3ece38c4165fe66787f5a61','f5df0fd21659ef8a625367390e7bc01bff5e0c204e48f0340bce936e89855f9c','3cea7c1bb0f470a67670374929080b4caf472378eeca0846b18f95c7cc7e0021');
INSERT INTO blocks VALUES(310439,'4f2449fce22be0edb4d2aefac6f35ce5a47b871623d07c2a8c166363112b2877',310439000,NULL,NULL,'9da932c8c4c9a12d536db15649b8b89df52be294f3a3b16692618d2af421c1b7','900d2bac7404305e34131b7cc7af7cd5a425a7cac4e041e812cf92a48bcf1d5a','8070cad30737fb2eb2a86cfea3d5d983d1258e1e9faf8b2fabb26e885fa42dce');
INSERT INTO blocks VALUES(310440,'89d6bd4cdac1cae08c704490406c41fbc5e1efa6c2d7f161e9175149175ef12a',310440000,NULL,NULL,'ac9f1ff2a3adffd79ea3b2b13289ea060d2fa1ed9656a61057d1802531737221','c9a7e247181a4a582b6a4f441e3c7842a50c24fcbb023c5955b4331a63ded98f','2fe75c16f5e31be44542be2c55719048f97d2511d42eb8e663469ae6110f3d0e');
INSERT INTO blocks VALUES(310441,'2df1dc53d6481a1ce3a6fee51ad4adcce95f702606fee7c43feda4965cf9ee15',310441000,NULL,NULL,'4513dbf40e2b572ccfdb857eb58d4008b82959d110c094961cc7587ca9672316','1bef6af7301d356db3a0a0699840295526ab4b4ea6b74eae66fcb00623d74c0a','adef36ee801b9df9da44685732f6b462c5a2d95caedea3154fd19e8963b99fd8');
INSERT INTO blocks VALUES(310442,'50844c48722edb7681c5d0095c524113415106691e71db34acc44dbc6462bfec',310442000,NULL,NULL,'e806ef15930bf2104b63bde714b397312052322dd034f0df727b738e05e1c753','234cb27362097e23ea22cbfc6c6ac9fdd86ecf2f878564b11b606a7b0301bd30','017022a6a683c5209690f37229969637a7d69e78220b9578ea7da8c4f59ec479');
INSERT INTO blocks VALUES(310443,'edc940455632270b7deda409a3489b19b147be89c4d8f434c284e326b749c79a',310443000,NULL,NULL,'3f6cf11776817de3eeece3f754656bba718ed2d9fd52034f8c49b27ab12bae8a','15f70c974e47f9c9c3ab368a6b7a8325a703596bbc0ad350767a3bbbdfa0e42c','d37df1724a90c8b22f0c55a75a482a02e3457610a9edf38dfa94dd3a7702fcbf');
INSERT INTO blocks VALUES(310444,'68c9efab28e78e0ef8d316239612f918408ce66be09e8c03428049a6ee3d32e4',310444000,NULL,NULL,'da23b14ec6cc706fbeec8e796522dab412bc72b96833ebe9eb799e72623129b0','b2569bc33def2519aa0fe8387b780868223e153e70a1a8286f7009d5587e3ca9','93d5a9ce5e3d61a8c230beaea85061d7ebf1bc1c9f73c0b5f8b3454bf483400f');
INSERT INTO blocks VALUES(310445,'22a2e3896f1c56aefb2d27032a234ea38d93edf2b6331e72e7b4e3952f0234ef',310445000,NULL,NULL,'50e9c4330e9f1fc6c563bf924064999f3e8feee2fe107884a95c913df2008da4','486678b60e77163a731e3862c517861f6503d190671accdf8732a4c854011b16','f8a285e0c829c3aa8222e10315729e706595dd2a35a92f4be0c4320a005e0b83');
INSERT INTO blocks VALUES(310446,'e8b0856eff3efce5f5114d6378a4e5c9e69e972825bc55cc00c26954cd1c8837',310446000,NULL,NULL,'1b6f3d210ff3f0b1c0342419467a17c0d34ea1eea4e99ecb5ddf5e280818a983','1a80e9746642ef175c6137add7105dd8f02751b697a470bc9e66d06e3e414994','a9909c6c3a746bd935ed2c75fb5efbbcecec3ecbbbd046bca7111dbd15c03707');
INSERT INTO blocks VALUES(310447,'3f4bc894c0bc04ee24ed1e34849af9f719f55df50c8bc36dc059ec5fa0e1c8a8',310447000,NULL,NULL,'d5d10b1d7843d4070508a79192c7b1bb92876e64acef659c01ffce3c5ba5cfc5','3922bad5813ea457b37f11ed3a030d4d82d3e8f90d7e7a4a1f2d2ae47edd57b9','7d2522185b8411ebc43590d6c57f05d840caa2274f55e0e763006ea2f47f1d95');
INSERT INTO blocks VALUES(310448,'6a6c7c07ba5b579abd81a7e888bd36fc0e02a2bcfb69dbfa061b1b64bfa1bd10',310448000,NULL,NULL,'488c8a4a6aa3850d0ea6c0f12ecf4cc9bf400aae8c4b5e4cc5589152abe5a90b','2f5e1bb8ce6bc2bd597196978c8b06e010307a1ea3b9dba54534c4d7aef1dadc','22be36291fc54ce66b8244e9447f15c9c8b88f9b3e408c934fdbf152f9bdfb2a');
INSERT INTO blocks VALUES(310449,'9e256a436ff8dae9ff77ed4cac4c3bfbbf026681548265a1b62c771d9d8e0779',310449000,NULL,NULL,'5f8b738744da401e84d1174587d7e2900278621f3497adb94115167218e3d68f','a166fd1937a728e4baeb3445f9a0c9230385dcc417ef978d73e8df1f90f16be5','3822e5e069d27452d2d048bb9a4770969d2b0ccf3a7078c2629b5cc5e8d08504');
INSERT INTO blocks VALUES(310450,'2d9b2ccc3ad3a32910295d7f7f0d0e671b074494adc373fc49aa874d575e36a3',310450000,NULL,NULL,'185dba1b235227514d6ba11bd279b9fb05607714831edbc854c3dad8d17ee11c','c86e3ae4d7c3196c2087c07bc00a6a1a267cac53a565adc3c8f78615f7786efc','8f6aab5165a3484c8fcf33e0abf0f8cf1c890fbed094ee88b584c135a7db0877');
INSERT INTO blocks VALUES(310451,'55731a82b9b28b1aa82445a9e351c9df3a58420f1c2f6b1c9db1874483277296',310451000,NULL,NULL,'605cbe563d57fd6cc0d05d40e6217703ef899c9e61bdef381cf996403a782808','98f262a61a8d667e13e9760e2cd4a7907a5bac88cbb86d9187a75c6dd4f7c272','c7f51a6d70b363c8f31f84ebfff438219fdd66042c6eeae684ab1a5102d95b8c');
INSERT INTO blocks VALUES(310452,'016abbaa1163348d8b6bc497cc487880d469f9300374a72ecb793a03d64572aa',310452000,NULL,NULL,'c3ccf7d83bde4f7b5777c902b809841ae0c4c2db098bcabdd1aff128ffc6fd5a','f3a239847bd03adf929dabbfe415cbcf49653ce5232f5e7b2cdb812843405e53','7e0d0b627d8e8c0af8a3adab77e095b4eccfea7531495d52879ee45481137076');
INSERT INTO blocks VALUES(310453,'610be2f49623d3fe8c86eacf3620347ed1dc53194bf01e77393b83541ba5d776',310453000,NULL,NULL,'3dac0390da1c50e05051eaa60ad2aacb0112adc54e0f0041a00db0a519333ebb','fa68b21a253bc37d1ef73d60bc0e75bb0ea1aee4b9e0f749d5bf145a97e6dbaa','f6a72de620a252800570ad8299199e5fcefa07383ec0116167d17e94c55d1ccf');
INSERT INTO blocks VALUES(310454,'baea6ad71f16d05b37bb30ca881c73bc48fd931f4bf3ac908a28d7681e976ee9',310454000,NULL,NULL,'8fea87fc079398499692f207ae111d25a034576c0f2407383a20bf73ffe66d06','a32792e99a5e89249b6efcf8d1e0266f8b2ede016ae051ab4f893c3426907446','15c9b9a381789982d2ae842a64a8da2fa8be04fffd0ed79309c83362129eaa8e');
INSERT INTO blocks VALUES(310455,'31a375541362b0037245816d50628b0428a28255ff6eddd3dd92ef0262a0a744',310455000,NULL,NULL,'ce885b73d40cb2ddb6ec6474bd94ab4470515679f54fb47fc5bca7a87d1ca261','e90037544412d31113afea6aeb9ebeb3cc037121188ab27ac35b02f9a6647bcf','5de24e777f310dbbf7f497aee435f1be53ad6a40eb0ad84a16f8c8d1ecc18cd7');
INSERT INTO blocks VALUES(310456,'5fee45c5019669a46a049142c0c4b6cf382e06127211e822f5f6f7320b6b50fa',310456000,NULL,NULL,'16693fd96eb42e01b5ccac8c4978a882a50ff534c33ef92d9eab923988be8093','6bf216ecc945a0b0bf1b24a7582acad80a162aa61b0c312c445d56fa37d705ca','38cab0b83d0d4a8e5a8e45ead5a1abdbb927db8532b5abaa9aef84a97db80b4a');
INSERT INTO blocks VALUES(310457,'9ce5a2673739be824552754ce60fd5098cf954729bb18be1078395f0c437cce9',310457000,NULL,NULL,'81c06ed2e28e3eb67497d2508ec8399558d4be177fdefc525b7cf8010546da82','d05cbfd0410887eecb0a934f70cca3918715838b665693679a7b1c5c8216710d','6fa742e8adb085d7dcbbf283d3a076d337dc38b740cb0f05096d9ef6040fc11e');
INSERT INTO blocks VALUES(310458,'deca40ba154ebc8c6268668b69a447e35ad292db4504d196e8a91abdc5312aac',310458000,NULL,NULL,'bb906ce3def50a1573ded94e2ee8cd278375318479682145a72a3b9cd67f18ec','662b8aaeda54f7d6ceb9fd035bb6314136a73a6109cd5b4446b5e2b3136986de','6fec1a92ceb84100c60339586b3e1f6931e504b82ea65edcc5e0479d265b51b4');
INSERT INTO blocks VALUES(310459,'839c15fa5eea10c91851e160a73a6a8ee273a31ab5385fe5bd71920cbc08b565',310459000,NULL,NULL,'874afd2de9bfa523ab45482e1d2ff2a9136af0bd5ade66d7943564c504ef944f','0e8d52952e2b1c5ad7b8c9d4ad40d6445e4beb6aedfc342bebc25f38eeeda3f0','ff9f2ce0b84623c503d5286b4bc60776956ff3713f85f1a88d8f55ffef26f824');
INSERT INTO blocks VALUES(310460,'9b5f351a5c85aaaa737b6a55f20ebf04cafdf36013cdee73c4aaac376ad4562b',310460000,NULL,NULL,'890e72732c1d57443213ee7a7270b3e2a7e9087522f57189ac61cd6dc852abfa','d90c73fed67903de8ee250009eedaebe4cc6cf23ae7898f05ea6651a4b7a5560','d40813983a195e940526e30de772447489d5a5fcbf39e4fa625694df3e14c9dd');
INSERT INTO blocks VALUES(310461,'8131c823f11c22066362517f8c80d93bfc4c3b0a12890bdd51a0e5a043d26b7b',310461000,NULL,NULL,'8627256f470d906d5c784ba257f4f7d29e0d81347c7566727aaa26afd0a9b251','0fd06fcb6e406d9391bdbcacc4676fa48764d1474c1d106ab5b76c2648c7ac8c','4511dc903b8bcd62b716c90bc6fcb94401bc5d628e9ce28339d2f50dab0d5b57');
INSERT INTO blocks VALUES(310462,'16f8fad8c21560b9d7f88c3b22293192c24f5264c964d2de303a0c742c27d146',310462000,NULL,NULL,'d1829d2db4718331aea74e59d3fcedc3f510aaab82f3f7f956087b32c040f63d','33e856351ddb0be6000d3ed5ac00ea6e0cb6b2654238f011b2861e427c82d5ee','c0933a0e9a2588feab8b9ce6b0be30eaad5345284ac7305712c0e38f60c7bd10');
INSERT INTO blocks VALUES(310463,'bf919937d8d1b5d5f421b9f59e5893ecb9e77861c6ab6ffe6d2722f52483bd94',310463000,NULL,NULL,'8b83bf9e263c69e8f731d90c9e6f92b66dd1652ea76390ceec58883f3ffe881e','6b25c1c6d2962465568912ff545f26c2cba237541b1d61bfe63dfc80210443ec','480d90b5a8d599b61d6909bd68503ac353ddb0f23c917b3f7a0c7d9bd63640e9');
INSERT INTO blocks VALUES(310464,'91f08dec994751a6057753945249e9c11964b98b654704e585d9239462bc6f60',310464000,NULL,NULL,'a93fbb5f298b41d3123312fe41ed8c5811410c32ac31062ff513c69a6ada8e53','64517f1a1b5de9e4337e9877997afd51330d592e775add282b2355f121af0bfa','0a7aed4fe48b1cb2b10d261489a11b7fffe6fc36be142360b1f9b86827aef44e');
INSERT INTO blocks VALUES(310465,'5686aaff2718a688b9a69411e237912869699f756c3eb7bf7c3cf2b9e3756b3d',310465000,NULL,NULL,'19ea9e27f997fcaa3c260bed12a628b55054b6f90d579ff3e41ab1cb29240778','ca0941cf3b2ab756995a4aaa5cdc338ad2fd772dc97f7a13be1b0f7c143625ff','eb7ec8a28ee035f4db2b89d6b62415d7c012f79b4c85aa53dda332b557496127');
INSERT INTO blocks VALUES(310466,'8a68637850c014116da671bb544fb5deddda7682223055a58bdcf7b2e79501fc',310466000,NULL,NULL,'90c850f7cfe700fdea8d8d60fa03f080861414ec372a7d920ca6d09217f82fda','3548e1dff4ffb3d536a608979b630858bbe61491df17c3cb839ca9ec68b0be55','0d76f7a48b4f8fa74cf3dc6af2e64f0fdab81c50255bf8f8107a9238f3ca6d79');
INSERT INTO blocks VALUES(310467,'d455a803e714bb6bd9e582edc34e624e7e3d80ee6c7b42f7207d763fff5c2bd3',310467000,NULL,NULL,'9f92428bfddcff24329af3b4c0b3200e8b4ae3065f9b6a8a6488e159abfe6854','cfd237041d5e1f51a14c218aa43c93723be51ae43462c5f372d18b7b5a88704b','3087783c8ca8db1283cbc32843d764d5cbf3930a58dcc2586cb057d73c0ce02a');
INSERT INTO blocks VALUES(310468,'d84dfd2fcf6d8005aeeac01e03b287af788c81955612375510e37a4ab5766891',310468000,NULL,NULL,'0cf6101033a96e6a90572ab21502314470c4b544bf21a902845861c413e1775f','419cb3c405c03ea386290dccbb3a6c4d1fdb21686f4e011c8508e06f4d4f6b15','147c6e25e88d673a0a9ebbfbcf5efa8ee59211dd3d6ef201327fc646440f34fc');
INSERT INTO blocks VALUES(310469,'2fbbf2724f537d539b675acb6a479e530c7aac5f93b4045f4356ea4b0f8a8755',310469000,NULL,NULL,'93f157cc43a6dc2df588c7cbddca37e55eddf5a94fcac82ebeec2d8d252a515f','29f921d4e098881d9271373624d07d8b2908a794c3889ebb16518ec2553bced5','de434aab0dd3ce50d0973d5da7e765c2d6dc1559ab6d25a2e268cb9f110c4144');
INSERT INTO blocks VALUES(310470,'ebb7c8e3fbe0b123a456d753b85b8c123ca3b315da14a00379ebd34784b28921',310470000,NULL,NULL,'d6ebcad8b1743d6dd898a522304594242eb063893c1d07baa893c076f6ccdc3e','17d4bd258f6a41f8854aac6c44ec707164c79c4e87293a808393ddd89a1cd639','d0d9c240a145bf8cb539793ed249056fe466cd74c315ef535d8aa735c843f4a5');
INSERT INTO blocks VALUES(310471,'fc6f8162c55ecffeaabb09f70f071fd0cb7a9ef1bccaafaf27fe9a936defb739',310471000,NULL,NULL,'e6003555728c70ecd67dc8de1248de291a2d3a5d9fed35d77fd0888b5c7a1997','32651f81738f3e22762139848d53523c5380ecac418afd498af7f4732c7a5ffd','2d0eccb2b159a46b00ced417068ca31812465c7c35402ccdf6b068eaf711808c');
INSERT INTO blocks VALUES(310472,'57ee5dec5e95b3d9c65a21c407294a32ed538658a6910b16124f18020f16bdf7',310472000,NULL,NULL,'dd553bc627b16f15cd618dd0504cd0ec04724610ff6ed44515957c997385c826','92220e916cf13dd40f25b6ee7f1881c6110e80154cceb042b80fdebd5168108c','7c6fe70f917cd8b899557c126618d569c4937e40daa049c0b52c133c7dec0ba5');
INSERT INTO blocks VALUES(310473,'33994c8f6d06134f886b47e14cb4b5af8fc0fd66e6bd60b3a71986622483e095',310473000,NULL,NULL,'9290c164b0b011d53eb80193285fcfd830e524183cce1be181a48f085601845e','92d85df10993d8adc353d451c9f5183b5741a0b9f2df4ff0035740b643efd272','8ee7cd495117f6886ad024aa072fb9da3ba9cfaf7c7b387082af7ad7f8247c29');
INSERT INTO blocks VALUES(310474,'312ee99e9526e9c240d76e3c3d1fe4c0a21f58156a15f2789605b3e7f7794a09',310474000,NULL,NULL,'7aba0609948218e622e3293760bfddaa1ac4669eeaac6ec897aef5ab1268774f','363af9372355a9c0e5bf1050a7ebe6caf3931f95bc6bf414581fab3b285acc12','4874a31bec3d8b8ba3a27d3c681f957d535083f492381d428b48efe6f891d312');
INSERT INTO blocks VALUES(310475,'bb9289bcd79075962117aef1161b333dbc403efebd593d93fc315146a2f040eb',310475000,NULL,NULL,'bf95d8500066d276cc48546cc2c29398e26511097cc658b21d6a537c2d8876d7','e3ea20f363baae83b3693e9705786987ba341fff160a66b2470d457e641c7514','d6833f7324d8f8f57ed2a9b71916f251f69fca560d497876e81bbe5eca096d5c');
INSERT INTO blocks VALUES(310476,'3712e1ebd195749e0dc92f32f7f451dd76f499bf16d709462309ce358a9370d0',310476000,NULL,NULL,'89d6256d5a7f5412a5eeb9b5551860b7ea26b096a2b8196b61d437ba7ee797f6','5d13c04813399129b1a97b403ca4158839d861da510f8fa00363277c1bf5bd20','dadfabb7b8a1d6ee976606cfbbefc151a6389db33eb3438d90df90b53a1f691c');
INSERT INTO blocks VALUES(310477,'7381973c554ac2bbdc849e8ea8c4a0ecbb46e7967d322446d0d83c3f9deab918',310477000,NULL,NULL,'31e4ee682d84213876eb8d85cb92d32688c4dd9110a9a90d74cfa275b50b8bec','949fc33974f7f08aecfebd2fe5dae5806e92c8e31cdbde66dc58388e6b9aedae','60aa8eb5eed39447a66f4b46f7222877b727e000fbc3e3469c6eb86fce716251');
INSERT INTO blocks VALUES(310478,'c09ee871af7f2a611d43e6130aed171e301c23c5d1a29d183d40bf15898b4fa0',310478000,NULL,NULL,'941bcbb6d7a89a86859fdc1516c0e64a1473b356f42846d2e8a353b08967fd46','b7339899e0a607a40a1b7acaa33eccda3a2b0724700c49a594f492c9bcc4b179','7d7d603bfd79dd5656ecd3feb3caa26cba3eb76485d1cb5b6ba926f987175213');
INSERT INTO blocks VALUES(310479,'f3d691ce35f62df56d142160b6e2cdcba19d4995c01f802da6ce30bfe8d30030',310479000,NULL,NULL,'8c271f55a292b69f95c50228be57e8a1a91b94998756abd8ce431e657fa4055c','23cb07dd05b283736b3492324e30f103980308fffc004e35c2005b3ecf24e306','e6a28f6a8190c4fbebb07e9a9b50163dc4deb1eef1f4f01c7b1a58c3d0f88b1e');
INSERT INTO blocks VALUES(310480,'2694e89a62b3abd03a38dfd318c05eb5871f1be00a6e1bf06826fd54d142e681',310480000,NULL,NULL,'aa0c833f96cce186008d339452e92d054edd67397c538baac239b10df8f9bcbb','0364f5e94735e03006e8e5d4eafa6abb114219a2772568c146514a895e1cf347','66c3f9a2996e7b2a1895435e28c603d2f6ff12eec59eea1614868969bfb26f03');
INSERT INTO blocks VALUES(310481,'db37d8f98630ebc61767736ae2c523e4e930095bf54259c01de4d36fd60b6f4a',310481000,NULL,NULL,'596ff1cd4069e7a0d62db64acfe1502ca4bfc6d3ac792794ad980c5f654f1a01','4daa9778a143e0031f38ac8d3e502f639bc1d3792beb55d2bb91753163a57dce','2d5ca929bca43c3ef97fa73c1ccd4ff974cf29ac5c23e2dc9906d5c058965832');
INSERT INTO blocks VALUES(310482,'2e27db87dfb6439c006637734e876cc662d1ca74c717756f90f0e535df0787d6',310482000,NULL,NULL,'bbc1ac936d3ea0f0ab911d79ec003e0ce0c20d6adf507dc5c94a773659b0b734','cab20ffd0fbe147d2618aa5b27410887fa24dfdd82e3e031d2470416669a3886','7576f10b9d6e36781c413ffda3a2d2c0d3f42b406763778b39af0866dc7a5f2e');
INSERT INTO blocks VALUES(310483,'013bac61f8e33c8d8d0f60f5e6a4ec3de9b16696703dea9802f64a258601c460',310483000,NULL,NULL,'008c287f38d96307ee4a71ea6a8f2c42a35dd54c4a834515d7a44ced43204845','93bdc34753af20c8f54d4b08d3b937cc0bbc061228b5458f1ea5b5252f625b35','86bcb62f6ee34c2c3fd96b497683c8a5264e06d626403e66030657385b34cf03');
INSERT INTO blocks VALUES(310484,'7cac2b3630c31b592fa0497792bed58d3c41120c009471c348b16b5578b3aa2b',310484000,NULL,NULL,'d7f3ec5feb14b12b410fa72344620e930037d15cdb36295fc68aa0f4087eb631','c012aa1548249b48d7894a5b06a8fe036db75518257f625402cedfb3fb32ee00','8ce20d8275ec4e09aaddc0eb8b7a761ca521a103c1728300ea0572c9d54ad864');
INSERT INTO blocks VALUES(310485,'eab5febc9668cd438178496417b22da5f77ceaed5bb6e01fc0f04bef1f5b4478',310485000,NULL,NULL,'10856cb1b7625aa217ea3009f10aa1e772a627e302f4191eaba5d332b8daea32','47bbebd943b632d3019d2f9b1c50c651c488d29d6ebba41abd8a0ee748cfcb9b','07eec7fbd56db1d8a2af5f0942996502431cd347b822aeb3e7cfb7a3028a97af');
INSERT INTO blocks VALUES(310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,NULL,NULL,'d4d08e6c5c0a9d491cd2c754047a78a566a86a0b4ef81c3037a9d438803a0fb6','503320cba6236f68bff31f0b887535a1c90758d76aebd904d1ac09eb0fc5740a','a643a0eb2f521d6150407cf64060e78ef4a886b9109a3326b0cc3e2357eb2c9f');
INSERT INTO blocks VALUES(310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,NULL,NULL,'37b3308d0f5d5c037146fbca2a472cec180913fe814f30259e4cb28a8ecd3e0d','d6e87ade03f005e30d63aa8d5c9437c33db5a87cf78f15ada9eb5cc94fb62a28','b09529b6aca9c685e9448952b7e8fd9eb0cf436583e9616384c436fda19aa244');
INSERT INTO blocks VALUES(310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,NULL,NULL,'e9281f40f19701d88dadb0d7793a38ffebf5c707f0041435c91959d1e160c954','57c13d1026f70205638c4133fe51969fe2e157cf7afb2eb679a781802f879da0','1fcda9ef641400ac70c304e2e2d2e419dee566476bfc5e797854507105eb16a6');
INSERT INTO blocks VALUES(310489,'2efdb36f986b3e3ccc6cc9b0c1c3cdcb07429fb43cbc0cc3b6c87d1b33f258b6',310489000,NULL,NULL,'6519c4ec7839051175d4d8bad6a090e39655562f501b8b5ec6c18cec4e89390a','8b74116c6dd0c4f39cff8ee229ba5d8d85ff7507075e4797d98c6f706037cbfa','b642a7f0606ec0819c98c13c6b23fab12890f16eb21c2a39222bbb17c4423960');
INSERT INTO blocks VALUES(310490,'e2cb04b8a7368c95359c9d5ff33e64209200fb606de0d64b7c0f67bb1cb8d87c',310490000,NULL,NULL,'0182945121de0b1dfe8191a4a537f8355f39d534191ca73604a9118953b6f752','d7394eb93626b7a28f7678373b906acb42d3429bb7fed821fca32522f38e2ce8','7c56959e2f158657c19f081b70a6e967b39ba9b68605bccfd2a38cf6bf7c6194');
INSERT INTO blocks VALUES(310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,NULL,NULL,'893cb9e084c543b25408dcb1ffb32fdd3118d87f514345fca1b2e9e58f78c269','3d59ef4aff97b00e0749acb6c99e3cf456c75b0ccd1cb2a2633d6e165b083fda','9331ee5e2080734f7d35e6956c0946abfe3897962bd4fe80375bc16b2ea4b69b');
INSERT INTO blocks VALUES(310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,NULL,NULL,'327460845c4d1aedcaaa9ca88590f5db8636160feb9a8b05af72e93779ae5ef5','f77a9acd00af83da431a12d8833d9523dcc328bac53e1b27f16f8d7ad70ac5ba','c9ebb688493c6bc97297c88e9b1dc359a0f997f64bec5eb775d3d2c2c548c939');
INSERT INTO blocks VALUES(310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,NULL,NULL,'8cadc59c041825d63d204d96961c8e1528b139c332d29c1720e7bade927563dc','8b33359ad2cf16ebeb9397601134564a92cc65105474f48e6e2ad04d398a208b','97579aa2be41424492d56a7abccfea78557f4ec2fa3fe5d3ebe97a3436d10964');
INSERT INTO blocks VALUES(310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,NULL,NULL,'e0437e31b052cfa676cc66867b29d874bb5fa64b7790db1d03b3cfc3ac13a919','afe0530059b72dffd17274c2b68a25e20cabe55fdab9ec7c147a9fcc6122aa85','0b09cb4589edc5cd517c8d6a28d52c6d3ad21c9faceea388db3116fb711ebe30');
INSERT INTO blocks VALUES(310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,NULL,NULL,'bbb8d2b712b9a2fd5faa6e4b4c9718b54330148bb4298b2b137ecd831f9707f6','f3418281bf0eece070da694e09adaf6fa04503e6ad241bf24f345077302ce005','c9931725fcb968af54dd7222b1b2b8763711c43754f0f37a14d40d7234bb9b42');
INSERT INTO blocks VALUES(310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,NULL,NULL,'f1320125f0078e7eb4286ff1f95165f95376e401d9b7fcf58c05141f2f823126','d87e774c37328b6bbed804d93e0bccd857e67d7c5e9d0aa353abd88dd6e4faa8','5644579629ebe94e1ce0ed6d7052a656521476c2b2d0165ee9bf8064840bfa1c');
INSERT INTO blocks VALUES(310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,NULL,NULL,'85e22a0037f0cf5fc7bb2580f31f86e99d96dd1016069fff83266370a2477b91','e676b9436513f0839cd3edf11ceaf3d8d33824f088ea42825f1963c7b4d28aeb','3119b671c3f59eb0fd40f8f8f9f935b9e7da4ef5b1f131812015c3fa6a578182');
INSERT INTO blocks VALUES(310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,NULL,NULL,'32d4377931603c5dc81e87332bde78fdb07e8430647f7e93cf977b400c1931ed','11bf9b9b28d6e9c88ade40468da50a404374cebe148a198707a2e8908b24771e','4277f970facb9e46be12b50d001886b070c134ae30ef8f1ff4b9fcebe5384d8c');
INSERT INTO blocks VALUES(310499,'1950e1a4d7fc820ed9603f6df6819c3c953c277c726340dec2a4253e261a1764',310499000,NULL,NULL,'865d2495f1c161f8795737735ac229b52196cc2b7dea0667e3215abbf15d3958','9b0351249c69f0ebb1db389ff0646a00faf5ad1d2ef37050b553927e0448786f','380e8fb4f443ce9b099f3acc3efa563f74b1f1bbb1f7af836561f30937813d42');
INSERT INTO blocks VALUES(310500,'54aeaf47d5387964e2d51617bf3af50520a0449410e0d096cf8c2aa9dad5550b',310500000,NULL,NULL,'a674c6086a81df1a586fe38cc060f94813823de229d72b574244a59c54aa2b47','0e7e6a886784bef71971202dc8278af324be95354f84cbbe9d71c5a4aeeed4f6','a25f20bc552321b0b13f69a88e607d18645b4411d5affd5e92b439fd2d7fe438');
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
INSERT INTO broadcasts VALUES(18,'9b70f9ad8c0d92ff27127d081169cebee68a776f4974e757de09a46e85682d66',310017,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000000,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(19,'f6548d72d0726bd869fdfdcf44766871f7ab721efda6ed7bce0d4c88b43bf1cf',310018,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',0,NULL,NULL,NULL,1,'valid');
INSERT INTO broadcasts VALUES(103,'18cbfca6cd776158c13245977b4eead061e6bdcea8118faa6996fb6d01b51d4e',310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000002,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(110,'d858c6855038048b1d5e31a34ceae2069d7c7bc311ca49d189ccbf44cee58031',310109,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',1388000002,1.0,5000000,'Unit Test',0,'valid');
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
INSERT INTO burns VALUES(107,'bcf44f53dc42ae50f3f0f2dc36ff16e432ddbc298f70ec143806cb58e53d4403',310106,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',31000000,46499556869,'valid');
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
INSERT INTO credits VALUES(310103,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','XCP',92999138821,'burn','6e96414550ec512d2272497e3e2cbc908ec472cc1b871d82f51a9a66af3cf148');
INSERT INTO credits VALUES(310104,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','XCP',92999130460,'burn','1f4e8d91b61fff6132ee060b80008f7739e8215282a5bd7c57fe088c056d9f72');
INSERT INTO credits VALUES(310105,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','XCP',92999122099,'burn','3152127f7b6645e8b066f6691aeed95fa38f404df85df1447c320b38a79240c6');
INSERT INTO credits VALUES(310106,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',46499556869,'burn','bcf44f53dc42ae50f3f0f2dc36ff16e432ddbc298f70ec143806cb58e53d4403');
INSERT INTO credits VALUES(310107,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','PAYTOSCRIPT',1000,'issuance','63145ad2bcc7030aabcfec42a5cce5dfe6829a5694fc0b3566406bb2fd8b6444');
INSERT INTO credits VALUES(310108,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000,'send','075b91828d0c7b0017f1b5876ef4909ba37db9bc2877588483d8a64bad2bd412');
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
INSERT INTO debits VALUES(310107,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',50000000,'issuance fee','63145ad2bcc7030aabcfec42a5cce5dfe6829a5694fc0b3566406bb2fd8b6444');
INSERT INTO debits VALUES(310108,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000,'send','075b91828d0c7b0017f1b5876ef4909ba37db9bc2877588483d8a64bad2bd412');
INSERT INTO debits VALUES(310110,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',10,'bet','81f8ba670b22980b15c944dcd478a274723659d768b0de73b014d06d214e5b90');
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
INSERT INTO issuances VALUES(108,'63145ad2bcc7030aabcfec42a5cce5dfe6829a5694fc0b3566406bb2fd8b6444',310107,'PAYTOSCRIPT',1000,0,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',0,0,0,0.0,'PSH issued asset',50000000,0,'valid');
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
INSERT INTO messages VALUES(63,310103,'insert','credits','{"action": "burn", "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "asset": "XCP", "block_index": 310103, "event": "6e96414550ec512d2272497e3e2cbc908ec472cc1b871d82f51a9a66af3cf148", "quantity": 92999138821}',0);
INSERT INTO messages VALUES(64,310103,'insert','burns','{"block_index": 310103, "burned": 62000000, "earned": 92999138821, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "tx_hash": "6e96414550ec512d2272497e3e2cbc908ec472cc1b871d82f51a9a66af3cf148", "tx_index": 104}',0);
INSERT INTO messages VALUES(65,310104,'insert','credits','{"action": "burn", "address": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b", "asset": "XCP", "block_index": 310104, "event": "1f4e8d91b61fff6132ee060b80008f7739e8215282a5bd7c57fe088c056d9f72", "quantity": 92999130460}',0);
INSERT INTO messages VALUES(66,310104,'insert','burns','{"block_index": 310104, "burned": 62000000, "earned": 92999130460, "source": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b", "status": "valid", "tx_hash": "1f4e8d91b61fff6132ee060b80008f7739e8215282a5bd7c57fe088c056d9f72", "tx_index": 105}',0);
INSERT INTO messages VALUES(67,310105,'insert','credits','{"action": "burn", "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "asset": "XCP", "block_index": 310105, "event": "3152127f7b6645e8b066f6691aeed95fa38f404df85df1447c320b38a79240c6", "quantity": 92999122099}',0);
INSERT INTO messages VALUES(68,310105,'insert','burns','{"block_index": 310105, "burned": 62000000, "earned": 92999122099, "source": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "status": "valid", "tx_hash": "3152127f7b6645e8b066f6691aeed95fa38f404df85df1447c320b38a79240c6", "tx_index": 106}',0);
INSERT INTO messages VALUES(69,310106,'insert','credits','{"action": "burn", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "XCP", "block_index": 310106, "event": "bcf44f53dc42ae50f3f0f2dc36ff16e432ddbc298f70ec143806cb58e53d4403", "quantity": 46499556869}',0);
INSERT INTO messages VALUES(70,310106,'insert','burns','{"block_index": 310106, "burned": 31000000, "earned": 46499556869, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "valid", "tx_hash": "bcf44f53dc42ae50f3f0f2dc36ff16e432ddbc298f70ec143806cb58e53d4403", "tx_index": 107}',0);
INSERT INTO messages VALUES(71,310107,'insert','debits','{"action": "issuance fee", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "XCP", "block_index": 310107, "event": "63145ad2bcc7030aabcfec42a5cce5dfe6829a5694fc0b3566406bb2fd8b6444", "quantity": 50000000}',0);
INSERT INTO messages VALUES(72,310107,'insert','issuances','{"asset": "PAYTOSCRIPT", "block_index": 310107, "call_date": 0, "call_price": 0.0, "callable": false, "description": "PSH issued asset", "divisible": false, "fee_paid": 50000000, "issuer": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "locked": false, "quantity": 1000, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "valid", "transfer": false, "tx_hash": "63145ad2bcc7030aabcfec42a5cce5dfe6829a5694fc0b3566406bb2fd8b6444", "tx_index": 108}',0);
INSERT INTO messages VALUES(73,310107,'insert','credits','{"action": "issuance", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "PAYTOSCRIPT", "block_index": 310107, "event": "63145ad2bcc7030aabcfec42a5cce5dfe6829a5694fc0b3566406bb2fd8b6444", "quantity": 1000}',0);
INSERT INTO messages VALUES(74,310108,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 310108, "event": "075b91828d0c7b0017f1b5876ef4909ba37db9bc2877588483d8a64bad2bd412", "quantity": 100000000}',0);
INSERT INTO messages VALUES(75,310108,'insert','credits','{"action": "send", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "DIVISIBLE", "block_index": 310108, "event": "075b91828d0c7b0017f1b5876ef4909ba37db9bc2877588483d8a64bad2bd412", "quantity": 100000000}',0);
INSERT INTO messages VALUES(76,310108,'insert','sends','{"asset": "DIVISIBLE", "block_index": 310108, "destination": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "075b91828d0c7b0017f1b5876ef4909ba37db9bc2877588483d8a64bad2bd412", "tx_index": 109}',0);
INSERT INTO messages VALUES(77,310109,'insert','broadcasts','{"block_index": 310109, "fee_fraction_int": 5000000, "locked": false, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "valid", "text": "Unit Test", "timestamp": 1388000002, "tx_hash": "d858c6855038048b1d5e31a34ceae2069d7c7bc311ca49d189ccbf44cee58031", "tx_index": 110, "value": 1.0}',0);
INSERT INTO messages VALUES(78,310110,'insert','debits','{"action": "bet", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "XCP", "block_index": 310110, "event": "81f8ba670b22980b15c944dcd478a274723659d768b0de73b014d06d214e5b90", "quantity": 10}',0);
INSERT INTO messages VALUES(79,310110,'insert','bets','{"bet_type": 3, "block_index": 310110, "counterwager_quantity": 10, "counterwager_remaining": 10, "deadline": 1388000200, "expiration": 1000, "expire_index": 311110, "fee_fraction_int": 5000000.0, "feed_address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "leverage": 5040, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "open", "target_value": 0.0, "tx_hash": "81f8ba670b22980b15c944dcd478a274723659d768b0de73b014d06d214e5b90", "tx_index": 111, "wager_quantity": 10, "wager_remaining": 10}',0);
INSERT INTO messages VALUES(80,310491,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310491, "event": "9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b", "quantity": 100000000}',0);
INSERT INTO messages VALUES(81,310491,'insert','orders','{"block_index": 310491, "expiration": 2000, "expire_index": 312491, "fee_provided": 10000, "fee_provided_remaining": 10000, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 800000, "get_remaining": 800000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b", "tx_index": 492}',0);
INSERT INTO messages VALUES(82,310492,'insert','orders','{"block_index": 310492, "expiration": 2000, "expire_index": 312492, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 800000, "give_remaining": 800000, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "tx_hash": "14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0", "tx_index": 493}',0);
INSERT INTO messages VALUES(83,310492,'update','orders','{"fee_provided_remaining": 10000, "fee_required_remaining": 892800, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b"}',0);
INSERT INTO messages VALUES(84,310492,'update','orders','{"fee_provided_remaining": 992800, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0"}',0);
INSERT INTO messages VALUES(85,310492,'insert','order_matches','{"backward_asset": "BTC", "backward_quantity": 800000, "block_index": 310492, "fee_paid": 7200, "forward_asset": "XCP", "forward_quantity": 100000000, "id": "9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b_14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0", "match_expire_index": 310512, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 310491, "tx0_expiration": 2000, "tx0_hash": "9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b", "tx0_index": 492, "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_block_index": 310492, "tx1_expiration": 2000, "tx1_hash": "14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0", "tx1_index": 493}',0);
INSERT INTO messages VALUES(86,310493,'insert','credits','{"action": "burn", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310493, "event": "d6adfa92e20b6211ff5fabb2f7a1c8b037168797984c94734c28e82e92d3b1d6", "quantity": 92995878046}',0);
INSERT INTO messages VALUES(87,310493,'insert','burns','{"block_index": 310493, "burned": 62000000, "earned": 92995878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "d6adfa92e20b6211ff5fabb2f7a1c8b037168797984c94734c28e82e92d3b1d6", "tx_index": 494}',0);
INSERT INTO messages VALUES(88,310494,'insert','debits','{"action": "issuance fee", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310494, "event": "084102fa0722f5520481f34eabc9f92232e4d1647b329b3fa58bffc8f91c5e4e", "quantity": 50000000}',0);
INSERT INTO messages VALUES(89,310494,'insert','issuances','{"asset": "DIVIDEND", "block_index": 310494, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Test dividend", "divisible": true, "fee_paid": 50000000, "issuer": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "locked": false, "quantity": 100, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "transfer": false, "tx_hash": "084102fa0722f5520481f34eabc9f92232e4d1647b329b3fa58bffc8f91c5e4e", "tx_index": 495}',0);
INSERT INTO messages VALUES(90,310494,'insert','credits','{"action": "issuance", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310494, "event": "084102fa0722f5520481f34eabc9f92232e4d1647b329b3fa58bffc8f91c5e4e", "quantity": 100}',0);
INSERT INTO messages VALUES(91,310495,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310495, "event": "9d3391348171201de9b5eb70ca80896b0ae166fd51237c843a90c1b4ccf8c602", "quantity": 10}',0);
INSERT INTO messages VALUES(92,310495,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "DIVIDEND", "block_index": 310495, "event": "9d3391348171201de9b5eb70ca80896b0ae166fd51237c843a90c1b4ccf8c602", "quantity": 10}',0);
INSERT INTO messages VALUES(93,310495,'insert','sends','{"asset": "DIVIDEND", "block_index": 310495, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 10, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "9d3391348171201de9b5eb70ca80896b0ae166fd51237c843a90c1b4ccf8c602", "tx_index": 496}',0);
INSERT INTO messages VALUES(94,310496,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310496, "event": "54f4c7b383ea19147e62d2be9f3e7f70b6c379baac15e8b4cf43f7c21578c1ef", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(95,310496,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "XCP", "block_index": 310496, "event": "54f4c7b383ea19147e62d2be9f3e7f70b6c379baac15e8b4cf43f7c21578c1ef", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(96,310496,'insert','sends','{"asset": "XCP", "block_index": 310496, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 92945878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "54f4c7b383ea19147e62d2be9f3e7f70b6c379baac15e8b4cf43f7c21578c1ef", "tx_index": 497}',0);
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
INSERT INTO sends VALUES(109,'075b91828d0c7b0017f1b5876ef4909ba37db9bc2877588483d8a64bad2bd412',310108,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','DIVISIBLE',100000000,'valid');
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
INSERT INTO transactions VALUES(1,'610b15f0c2d3845f124cc6026b6c212033de94218b25f89d5dbde47d11085a89',310000,'505d8d82c4ced7daddef7ed0b05ba12ecc664176887b938ef56c6af276f3b30c',310000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,10000,X'',1);
INSERT INTO transactions VALUES(2,'82e357fac0f41bc8c0c01e781ce96f0871bd3d6aaf57a8e99255d5e9d9fba554',310001,'3c9f6a9c6cac46a9273bd3db39ad775acd5bc546378ec2fb0587e06e112cc78e',310001000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'00000014000000A25BE34B66000000174876E800010000000000000000000F446976697369626C65206173736574',1);
INSERT INTO transactions VALUES(3,'6ecaeb544ce2f8a4a24d8d497ecba6ef7b71082a3f1cfdabc48726d5bc90fdca',310002,'fbb60f1144e1f7d4dc036a4a158a10ea6dea2ba6283a723342a49b8eb5cc9964',310002000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'000000140006CAD8DC7F0B6600000000000003E800000000000000000000124E6F20646976697369626C65206173736574',1);
INSERT INTO transactions VALUES(4,'a36a2d510757def22f0aa0f1cd1b4cf5e9bb160b051b83df25a101d5bb048928',310003,'d50825dcb32bcf6f69994d616eba18de7718d3d859497e80751b2cb67e333e8a',310003000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000001400000003C58E5C5600000000000003E8010000000000000000000E43616C6C61626C65206173736574',1);
INSERT INTO transactions VALUES(5,'044c9ac702136ee7839dc776cb7b43bbb9d5328415925a958679d801ac6c6b63',310004,'60cdc0ac0e3121ceaa2c3885f21f5789f49992ffef6e6ff99f7da80e36744615',310004000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000001400000000082C82E300000000000003E8010000000000000000000C4C6F636B6564206173736574',1);
INSERT INTO transactions VALUES(6,'bd919f9a31982a6dbc6253e38bfba0a367e24fbd65cf79575648f799b98849b4',310005,'8005c2926b7ecc50376642bc661a49108b6dc62636463a5c492b123e2184cd9a',310005000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000001400000000082C82E3000000000000000001000000000000000000044C4F434B',1);
INSERT INTO transactions VALUES(7,'074fa38a84a81c0ed7957484ebe73836104d3068f66b189e05a7cf0b95c737f3',310006,'bdad69d1669eace68b9f246de113161099d4f83322e2acf402c42defef3af2bb',310006000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000000A00000000000000010000000005F5E100000000A25BE34B660000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(8,'d21d82d8298d545b91e4467c287322d2399d8eb08af15bee68f58c4bcfa9a5f9',310007,'10a642b96d60091d08234d17dfdecf3025eca41e4fc8e3bbe71a91c5a457cb4b',310007000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,10000,X'00000000000000A25BE34B660000000005F5E100',1);
INSERT INTO transactions VALUES(9,'e64aac59d8759cde5785f3e1c4af448d95a152a30c76d97c114a3025e5ec118b',310008,'47d0e3acbdc6916aeae95e987f9cfa16209b3df1e67bb38143b3422b32322c33',310008000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,10000,X'0000000000000000000000010000000005F5E100',1);
INSERT INTO transactions VALUES(10,'a9f78534e7f340ba0f0d2ac1851a11a011ca7aa1262349eeba71add8777b162b',310009,'4d474992b141620bf3753863db7ee5e8af26cadfbba27725911f44fa657bc1c0',310009000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000000A00000000000000010000000005F5E100000000A25BE34B660000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(11,'b6db5c8412a58d9fa75bff41f8a7519353ffd4d359c7c8fa7ee1900bc05e4d9d',310010,'a58162dff81a32e6a29b075be759dbb9fa9b8b65303e69c78fb4d7b0acc37042',310010000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000000A00000000000000010000000005F5E100000000000000000000000000000F424007D000000000000DBBA0',1);
INSERT INTO transactions VALUES(12,'8a63e7a516d36c17ac32999222ac282ab94fb9c5ea30637cd06660b3139510f6',310011,'8042cc2ef293fd73d050f283fbd075c79dd4c49fdcca054dc0714fc3a50dc1bb',310011000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,1000000,X'0000000A000000000000000000000000000A2C2B00000000000000010000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(13,'d4428cf4082bc5fe8fed72673f956d351f269a308cf0d0d0b87f76dd3b6165f4',310012,'cdba329019d93a67b31b79d05f76ce1b7791d430ea0d6c1c2168fe78d2f67677',310012000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,10000,X'0000000000000000000000010000000011E1A300',1);
INSERT INTO transactions VALUES(14,'97aaf458fdbe3a8d7e57b4c238706419c001fc5810630c0c3cd2361821052a0d',310013,'0425e5e832e4286757dc0228cd505b8d572081007218abd3a0983a3bcd502a61',310013000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,10000,X'00000000000000A25BE34B66000000003B9ACA00',1);
INSERT INTO transactions VALUES(15,'29cd663b5e5b0801717e46891bc57e1d050680da0a803944623f6021151d2592',310014,'85b28d413ebda2968ed82ae53643677338650151b997ed1e4656158005b9f65f',310014000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5430,10000,X'000000000006CAD8DC7F0B660000000000000005',1);
INSERT INTO transactions VALUES(16,'b285ff2379716e92ab7b68ad4e68ba74a999dc9ca8c312c377231a89da7e9361',310015,'4cf77d688f18f0c68c077db882f62e49f31859dfa6144372457cd73b29223922',310015000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','1_mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc_mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns_2',7800,10000,X'000000000006CAD8DC7F0B66000000000000000A',1);
INSERT INTO transactions VALUES(17,'cd929bf57f5f26550a56ba40eecd258b684842777dfc434a46b65a86e924bf52',310016,'99dc7d2627efb4e5e618a53b9898b4ca39c70e98fe9bf39f68a6c980f5b64ef9',310016000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'000000140000000000033A3E7FFFFFFFFFFFFFFF01000000000000000000104D6178696D756D207175616E74697479',1);
INSERT INTO transactions VALUES(18,'9b70f9ad8c0d92ff27127d081169cebee68a776f4974e757de09a46e85682d66',310017,'8a4fedfbf734b91a5c5761a7bcb3908ea57169777a7018148c51ff611970e4a3',310017000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000001E52BB33003FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(19,'f6548d72d0726bd869fdfdcf44766871f7ab721efda6ed7bce0d4c88b43bf1cf',310018,'35c06f9e3de39e4e56ceb1d1a22008f52361c50dd0d251c0acbe2e3c2dba8ed3',310018000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','',0,10000,X'0000001E4CC552003FF000000000000000000000046C6F636B',1);
INSERT INTO transactions VALUES(20,'be15d34c959fde8f2baff8577d73d28c864e7684cc76ecba33e5d6d79ca6d6bd',310019,'114affa0c4f34b1ebf8e2778c9477641f60b5b9e8a69052158041d4c41893294',310019000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,10000,X'00000028000152BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(21,'90c1314847b1fe9b4520a3610dc98c71d39a1cb4b96edb9b02b6fed844a4b1e5',310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,10000,X'00000028000052BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(102,'ba0ef1dfbbc87df94e1d198b0e9e3c06301710d4aab3d85116cbc8199954644a',310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,10000,X'00000028000352BB33C8000000000000000A000000000000000A0000000000000000000013B0000003E8',1);
INSERT INTO transactions VALUES(103,'18cbfca6cd776158c13245977b4eead061e6bdcea8118faa6996fb6d01b51d4e',310102,'11e25883fd0479b78ddb1953ef67e3c3d1ffc82bd1f9e918a75c2194f7137f99',310102000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000001E52BB33023FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(104,'6e96414550ec512d2272497e3e2cbc908ec472cc1b871d82f51a9a66af3cf148',310103,'559a208afea6dd27b8bfeb031f1bd8f57182dcab6cf55c4089a6c49fb4744f17',310103000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,-99990000,X'',1);
INSERT INTO transactions VALUES(105,'1f4e8d91b61fff6132ee060b80008f7739e8215282a5bd7c57fe088c056d9f72',310104,'55b82e631b61d22a8524981ff3b5e3ab4ad7b732b7d1a06191064334b8f2dfd2',310104000,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,-99990000,X'',1);
INSERT INTO transactions VALUES(106,'3152127f7b6645e8b066f6691aeed95fa38f404df85df1447c320b38a79240c6',310105,'1d72cdf6c4a02a5f973e6eaa53c28e9e13014b4f5bb13f91621a911b27fe936a',310105000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,-99990000,X'',1);
INSERT INTO transactions VALUES(107,'bcf44f53dc42ae50f3f0f2dc36ff16e432ddbc298f70ec143806cb58e53d4403',310106,'9d39cbe8c8a5357fc56e5c2f95bf132382ddad14cbc8abd54e549d58248140ff',310106000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','mvCounterpartyXXXXXXXXXXXXXXW24Hef',31000000,10000,X'',1);
INSERT INTO transactions VALUES(108,'63145ad2bcc7030aabcfec42a5cce5dfe6829a5694fc0b3566406bb2fd8b6444',310107,'51cc04005e49fa49e661946a0e147240b0e5aac174252c96481ab7ddd5487435',310107000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','',0,10000,X'0000001400078A8FE2E5E44100000000000003E8000000000000000000001050534820697373756564206173736574',1);
INSERT INTO transactions VALUES(109,'075b91828d0c7b0017f1b5876ef4909ba37db9bc2877588483d8a64bad2bd412',310108,'8f2d3861aa42f8e75dc14a23d6046bd89feef0d81996b6e1adc2a2828fbc8b34',310108000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',5430,10000,X'00000000000000A25BE34B660000000005F5E100',1);
INSERT INTO transactions VALUES(110,'d858c6855038048b1d5e31a34ceae2069d7c7bc311ca49d189ccbf44cee58031',310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','',0,10000,X'0000001E52BB33023FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(111,'81f8ba670b22980b15c944dcd478a274723659d768b0de73b014d06d214e5b90',310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',5430,10000,X'00000028000352BB33C8000000000000000A000000000000000A0000000000000000000013B0000003E8',1);
INSERT INTO transactions VALUES(492,'9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b',310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,10000,X'0000000A00000000000000010000000005F5E100000000000000000000000000000C350007D000000000000DBBA0',1);
INSERT INTO transactions VALUES(493,'14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0',310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','',0,1000000,X'0000000A000000000000000000000000000C350000000000000000010000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(494,'d6adfa92e20b6211ff5fabb2f7a1c8b037168797984c94734c28e82e92d3b1d6',310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,10000,X'',1);
INSERT INTO transactions VALUES(495,'084102fa0722f5520481f34eabc9f92232e4d1647b329b3fa58bffc8f91c5e4e',310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','',0,10000,X'00000014000000063E985FFD0000000000000064010000000000000000000D54657374206469766964656E64',1);
INSERT INTO transactions VALUES(496,'9d3391348171201de9b5eb70ca80896b0ae166fd51237c843a90c1b4ccf8c602',310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj',5430,10000,X'00000000000000063E985FFD000000000000000A',1);
INSERT INTO transactions VALUES(497,'54f4c7b383ea19147e62d2be9f3e7f70b6c379baac15e8b4cf43f7c21578c1ef',310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj',5430,10000,X'00000000000000000000000100000015A4018C1E',1);
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
INSERT INTO undolog VALUES(131,'UPDATE balances SET address=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',asset=''XCP'',quantity=92050000000 WHERE rowid=1');
INSERT INTO undolog VALUES(132,'DELETE FROM debits WHERE rowid=22');
INSERT INTO undolog VALUES(133,'DELETE FROM orders WHERE rowid=5');
INSERT INTO undolog VALUES(134,'DELETE FROM orders WHERE rowid=6');
INSERT INTO undolog VALUES(135,'UPDATE orders SET tx_index=492,tx_hash=''9093cfde7b0d970844f7619ec07dc9313df4bf8e0fe42e7db8e17c022023360b'',block_index=310491,source=''mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc'',give_asset=''XCP'',give_quantity=100000000,give_remaining=100000000,get_asset=''BTC'',get_quantity=800000,get_remaining=800000,expiration=2000,expire_index=312491,fee_required=900000,fee_required_remaining=900000,fee_provided=10000,fee_provided_remaining=10000,status=''open'' WHERE rowid=5');
INSERT INTO undolog VALUES(136,'UPDATE orders SET tx_index=493,tx_hash=''14cc265394e160335493215c3276712da0cb1d77cd8ed9f284441641795fc7c0'',block_index=310492,source=''mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns'',give_asset=''BTC'',give_quantity=800000,give_remaining=800000,get_asset=''XCP'',get_quantity=100000000,get_remaining=100000000,expiration=2000,expire_index=312492,fee_required=0,fee_required_remaining=0,fee_provided=1000000,fee_provided_remaining=1000000,status=''open'' WHERE rowid=6');
INSERT INTO undolog VALUES(137,'DELETE FROM order_matches WHERE rowid=1');
INSERT INTO undolog VALUES(138,'DELETE FROM balances WHERE rowid=19');
INSERT INTO undolog VALUES(139,'DELETE FROM credits WHERE rowid=24');
INSERT INTO undolog VALUES(140,'DELETE FROM burns WHERE rowid=494');
INSERT INTO undolog VALUES(141,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''XCP'',quantity=92995878046 WHERE rowid=19');
INSERT INTO undolog VALUES(142,'DELETE FROM debits WHERE rowid=23');
INSERT INTO undolog VALUES(143,'DELETE FROM assets WHERE rowid=9');
INSERT INTO undolog VALUES(144,'DELETE FROM issuances WHERE rowid=495');
INSERT INTO undolog VALUES(145,'DELETE FROM balances WHERE rowid=20');
INSERT INTO undolog VALUES(146,'DELETE FROM credits WHERE rowid=25');
INSERT INTO undolog VALUES(147,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''DIVIDEND'',quantity=100 WHERE rowid=20');
INSERT INTO undolog VALUES(148,'DELETE FROM debits WHERE rowid=24');
INSERT INTO undolog VALUES(149,'DELETE FROM balances WHERE rowid=21');
INSERT INTO undolog VALUES(150,'DELETE FROM credits WHERE rowid=26');
INSERT INTO undolog VALUES(151,'DELETE FROM sends WHERE rowid=496');
INSERT INTO undolog VALUES(152,'UPDATE balances SET address=''mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH'',asset=''XCP'',quantity=92945878046 WHERE rowid=19');
INSERT INTO undolog VALUES(153,'DELETE FROM debits WHERE rowid=25');
INSERT INTO undolog VALUES(154,'DELETE FROM balances WHERE rowid=22');
INSERT INTO undolog VALUES(155,'DELETE FROM credits WHERE rowid=27');
INSERT INTO undolog VALUES(156,'DELETE FROM sends WHERE rowid=497');

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
INSERT INTO undolog_block VALUES(310487,131);
INSERT INTO undolog_block VALUES(310488,131);
INSERT INTO undolog_block VALUES(310489,131);
INSERT INTO undolog_block VALUES(310490,131);
INSERT INTO undolog_block VALUES(310491,131);
INSERT INTO undolog_block VALUES(310492,134);
INSERT INTO undolog_block VALUES(310493,138);
INSERT INTO undolog_block VALUES(310494,141);
INSERT INTO undolog_block VALUES(310495,147);
INSERT INTO undolog_block VALUES(310496,152);
INSERT INTO undolog_block VALUES(310497,157);
INSERT INTO undolog_block VALUES(310498,157);
INSERT INTO undolog_block VALUES(310499,157);
INSERT INTO undolog_block VALUES(310500,157);

-- For primary key autoincrements the next id to use is stored in
-- sqlite_sequence
DELETE FROM main.sqlite_sequence WHERE name='undolog';
INSERT INTO main.sqlite_sequence VALUES ('undolog', 156);

COMMIT TRANSACTION;
