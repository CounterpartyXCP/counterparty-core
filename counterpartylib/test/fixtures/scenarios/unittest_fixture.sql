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
INSERT INTO blocks VALUES(310106,'9d39cbe8c8a5357fc56e5c2f95bf132382ddad14cbc8abd54e549d58248140ff',310106000,NULL,NULL,'446153de1f26b20dfe815552e589ece5615cf5d908b7bef51bf007d72b7f7f09','446cf18383a776bd65854b6c931faa487d27d2e7e604f13be90c845e0d8bbcc8','7e1fe8d63842ae130b1cd7b98f32648a87c28c5c2aab7b2c781282dd58bde5b5');
INSERT INTO blocks VALUES(310107,'51cc04005e49fa49e661946a0e147240b0e5aac174252c96481ab7ddd5487435',310107000,NULL,NULL,'92dcf9c11401f3fb7f4f3b5f1f1a07a335ad64e8663e381115a0bcd6e12f19ac','cc1a6bd2668ede16e9241838c0e9bb3a8f9b597d577702fb4bf69228f10818e0','1d0b7f67d0a45a3c3aefc01e9e22d33eed2bab373dbad4ccaa1e447927f9f471');
INSERT INTO blocks VALUES(310108,'8f2d3861aa42f8e75dc14a23d6046bd89feef0d81996b6e1adc2a2828fbc8b34',310108000,NULL,NULL,'a5e784919ec9e336b886bff28006024c7a8714dcb6ee65c765b1f0ecf4c7cfdc','1c32c76ce3d92a46525a30bfa4f84258ba5d88317497b200cbff205727e7aaf0','a0de26c25ed3d75df39844df1d65b799c7a862c50705ba5545e0b9d707503bfb');
INSERT INTO blocks VALUES(310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,NULL,NULL,'492c26b26d6decd372da2e3f68550378753abb3a892ff9d16913ed249c783d03','0256a89fee240f90b8717639e187f459442b1a01e20e1df7789c0c4e8d3aaccc','f4b83c5b9981715ed1aab0fb6aa46d9f4e3426a69786fbb534de09e03593a109');
INSERT INTO blocks VALUES(310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,NULL,NULL,'415a8ec7dd0c715e96a03873a14a11eae00dfdc44a6c5fd5e71dd4e20226a925','0fc40c17c9c2a9a0c3d42713f2eb04a076657b5dbea6a98e7f6a1aff348853aa','c5d6dfd9c56076c99e981b9d8897d0124f1932701b8857154a91d126e700226b');
INSERT INTO blocks VALUES(310111,'fde71b9756d5ba0b6d8b230ee885af01f9c4461a55dbde8678279166a21b20ae',310111000,NULL,NULL,'c7687dc588fe9f2333320748b440c0acc8836d2931bf45af201c41a26052d31a','f9ebf35c1fb8c2110f5f034636140809ecac7b372f635263283f48b5f94d370f','a801ee4791c0ab386fce48366c5ad0d54b7c2aa887d07f4c022d34576cbc3b07');
INSERT INTO blocks VALUES(310112,'5b06f69bfdde1083785cf68ebc2211b464839033c30a099d3227b490bf3ab251',310112000,NULL,NULL,'8b20ff962d3bfc1adcb7ce451d4ed36200ea6ce26af0e81cbed021a42b016a28','58842973a4adb30d275b7bd8624007bd52199af5673b6bc10ef8d5ed1668ca95','f41dd8576b4d0b1edb3205afa7c5dec2d98420f6617c87e87f7e7bf6ff5f5bdd');
INSERT INTO blocks VALUES(310113,'63914cf376d3076b697b9234810dfc084ed5a885d5cd188dd5462560da25d5e7',310113000,NULL,NULL,'75956f57017068455bfb2ca74c0f196bba46f915a6c0f13c3c10f15ffaea7aa7','34710b421f1a9fbc4330c669ee8254e8edd1be00fe1556e12c0e66e78c4deae0','1daec76f9d8c35c836db1284459eb91d178e91f9986bffffa55c895b1d4c6157');
INSERT INTO blocks VALUES(310114,'24fc2dded4f811eff58b32cda85d90fb5773e81b9267e9a03c359bc730d82283',310114000,NULL,NULL,'aa66e5cb3d0291df7c10b706b57d7035a1857668bccea3fe2c82ce321d7dea5b','ff9da18634f1d912d7d1be0bdf7e7f2f8cfcabf77d5080b45f80d85e2e21e3e7','4fef3b57f4e0e0e5d27c3aa415a26d8323c5e510f26ef5dc5ae08026aa3cc190');
INSERT INTO blocks VALUES(310115,'a632d67ff5f832fe9c3c675f855f08a4969c6d78c0211e71b2a24fe04be5656a',310115000,NULL,NULL,'8538ae1f2c130e11eacd08a1fa0291cc0d13e6b0db09751544d1ada7ba3901bc','67185685e5efc111cc0476a64e9e6cd3b8a2fd759aa1a998fa0014b8c7954ba5','ab8dcabc31a66866a07806e3cc442945f4b8d9e8992f9e0a4fddbd4a782d3aed');
INSERT INTO blocks VALUES(310116,'8495ba36b331473c4f3529681a118a4cc4fa4d51cd9b8dccb1f13e5ef841dd84',310116000,NULL,NULL,'aa3ad995eb4e9ded4a6ad50f0dd57ee7f9cdd35701dacb4acd24d3abd3e4c052','26c01548888a125131facd3b04d64a80365127cbc42ef6ef9e840d0bb2493036','b952e9607668b9a32527da32fdc2dcfe8ea8f8e85904ff456478a5cc94e7a164');
INSERT INTO blocks VALUES(310117,'978a3eac44917b82d009332797e2b6fe64c7ce313c0f15bfd9b7bb68e4f35a71',310117000,NULL,NULL,'caf23031dec026208938ecf17f49093d958e4679913cb6c2df8e5bb73b4b7c91','13f2659fecab482e50a5a0803e505baefbb70d85e0c81f3a76f150a63889507f','3994f3dcb1c5c352fb838fbd3657fd2fb531a04d5b97e5adc67ad50f50c2e7fb');
INSERT INTO blocks VALUES(310118,'02487d8bd4dadabd06a44fdeb67616e6830c3556ec10faad40a42416039f4723',310118000,NULL,NULL,'28a3fdac1726aa67847eb08a92be10378378a356bb62294c65aae42cb1d3d566','55e23488ac9cf2129e66fc619342354776cb7b81728914c1288ff651855f9322','f87e12a9c2b77aadbf6203f2d9ea14c623ca2667684d5ea49f574ba33cbdfc98');
INSERT INTO blocks VALUES(310119,'6d6be3478c874c27f5d354c9375884089511b1aaaa3cc3421759d8e3aaeb5481',310119000,NULL,NULL,'158cb797a53b125c1b80c451101dad61a687b4d02f3dfda828968e76483d5c41','40ffc6c9e3691bd2278cbd6781b44533cc60d75b6e9e748fbd4745ed18474151','dcf586c9022fd78398447a720140c75bb222a821eb66f193a4a971545f38a5aa');
INSERT INTO blocks VALUES(310120,'2bba7fd459ea76fe54d6d7faf437c31af8253438d5685e803c71484c53887deb',310120000,NULL,NULL,'bc4f6183866ddfe32ef6023b820b3fddab7dcd01e83cae9e836128f574c51a7e','2ac09269e33157ea01386e48149fb5211f1337ed12a96c59d9cdec4d9c7ab714','52a58b8a6a9017f7811c8762c8805b188c6c031f3dfc2d861a30caec87a1c8c2');
INSERT INTO blocks VALUES(310121,'9b3ea991d6c2fe58906bdc75ba6a2095dcb7f00cfdd6108ac75c938f93c94ee7',310121000,NULL,NULL,'67e66f5657d5a0b89ecc31afe4999f3c6cb51e7dbd9af3341fc8dfba4dbd1ce6','214b112be8d34f5fbd2a6d28cfddaafee3e99f90f071b8f7409bc097cc844665','651f92a59d9599dd0b369642c394b248a787cc957889e476044fb5544b1ccdfb');
INSERT INTO blocks VALUES(310122,'d31b927c46e8f9ba2ccfb02f11a72179e08474bdd1b60dd3dcfd2e91a9ea2932',310122000,NULL,NULL,'fef8a7db8bdf67e29a98a6890787a40c9f8a30611fd3ab9e3c97f84d81ad9f45','03f986535a7c6c9a52a94dd9c34b0a8ff05f8845050cb551e653af4f1da3f85d','b1bf762e64d020a0ef4f0d3366338c6067aafb07ea5857beae3f7bc09475bed4');
INSERT INTO blocks VALUES(310123,'be6d35019a923fcef1125a27387d27237755c136f4926c5eddbf150402ea2bbd',310123000,NULL,NULL,'c14593cf0d7f875ad139e2dfd18ab0d3e3154edb417fc808e57bba8a3acf0d74','e08ba57267495cf305bb01e72f4e9037aa4987cd782ba95db56cc6a6bf378871','e0f724acb1ca21ac8f03d9126eff0b7b4c93b8a51b93f463ca15d13ea4cadc9a');
INSERT INTO blocks VALUES(310124,'0984b4a908f1a7dac9dcd94da1ee451e367cc6f3216ee8cdee15eae5d0700810',310124000,NULL,NULL,'7a7a6057611933bf492ab056cee862b996c520ad9f1eb8645863ab96cef9b8d8','363d70e06b54b993ee80ea2744312b045270dd1352ef470e5586cf818c97a934','f14048f0c0b36eb6823788271aa068112d9a16d843341a5993d4fa79028aebdf');
INSERT INTO blocks VALUES(310125,'cc28d39365904b2f91276d09fae040adb1bbbfd4d37d8c329fced276dc52c6a6',310125000,NULL,NULL,'30f855bc0ebe02d6444e15d76e9db501d871432a711cfd35b9c526bd5782cac1','7f545eb760f38c6577a8889abf35ed898ea842031d156fc59e43052a4aad9c34','a6b17884cfce93340a6818987ca6222ec6e569b6f4f3ad7870f79b3d74e1c05c');
INSERT INTO blocks VALUES(310126,'c9d6c2bd3eeb87f3f1033a13de8255a56445341c920a6a0ee2fb030877106797',310126000,NULL,NULL,'90899408484be4a4fb5a8229388069d86ad43c61aad85fab0a7380318d045a3a','aa60836d93dbe0a536d27df331d6b819d411964ed45b432599011d8c3a75631f','90d486fca604e216eaef285e9db1f802c2c231dd08b38db6728567616d4832ef');
INSERT INTO blocks VALUES(310127,'c952f369e2b3317725b4b73ba1922b84af881bd59054be94406a5d9bbb106904',310127000,NULL,NULL,'2aef2ba5d847b6e863b1d4ad3392705cc1b76fb2e05e2cc7e2a689578562e933','312fb1ebe003747e0d8989649199b22841dcf59fd1751f5dc47ffcbd06dc9108','7d9eceb01836f14a90f8f52519d8e981467e3f67a4ca50adc6c7c1d6989f8b8f');
INSERT INTO blocks VALUES(310128,'990b0d3575caf5909286b9701ece586338067fbd35357fec7d6a54c6a6120079',310128000,NULL,NULL,'e0ed32b31540c55cdd0052b82f336d9a2ece0d845cc1d08e30c0894d82130390','e39ccc5556ff952bb50c190b587bd72b3a2bb10dbb7b554f10d283699d9e94d5','18ee003e84b7c35d821698403492e4e317a2ebba1c7c9fd0a9b346ab28bb3fe3');
INSERT INTO blocks VALUES(310129,'fa8a7d674a9a3e4b40053cf3b819385a71831eec2f119a0f0640c6870ca1dddc',310129000,NULL,NULL,'b0096170a84d296729476a63c5068a874eb1248a967e693636d5a8f819e47f05','bdbb9d603dc9b4f537454cc3b10fd7154259c3f1565af56e3527979b2c85759f','a005f2b69be674d7d61eb309f6656f3c0748c11676df7afd4515241c4c994343');
INSERT INTO blocks VALUES(310130,'d3046e8e8ab77a67bf0629a3bab0bea4975631d52099d2ddc9c9fa0860522721',310130000,NULL,NULL,'777293e602005c15466ca4481a0f48400a7b0dc8e6e2badba3e148716bcb9687','26597e2362e4c32a123e15cf7b434ce48b4aad2a4d2031d95630b1ec5e858688','56aa35e952a65ed8005e76ceff851a7d933960e552247871ddbdf9412db3a303');
INSERT INTO blocks VALUES(310131,'d6b4357496bc2c42b58a7d1260a3615bfdb86e2ce68cd20914ef3dd3c0cdd34d',310131000,NULL,NULL,'0d872d2cb9bb3ece367cd7bc67d299fc423e70112922f0c0f275e322fbaa8f7e','2e10aef4e7d638b47ad73e79b9043b86871265da7df0340ad4701832946dc745','9f68defcc71d95b584ab2950ed428e0129ba0fcd4f2f9fa6489a956251a80388');
INSERT INTO blocks VALUES(310132,'1b95a691bf4abf92f0dde901e1152cc5bd87a792d4b42613655e4046a57ab818',310132000,NULL,NULL,'2a83a13b7de91abee9850540e8492d3b682cb6a6b6a991c8ddfd8f835258f2c0','50fc9dbe434fe9a95cdbfaf81d4f693fd7bf439b514b946b638f3a31db0dd53b','1a673245353482872c48da72fa3c3b35aa8c4d193db65c47b3d4034cda7ee445');
INSERT INTO blocks VALUES(310133,'1029c14051faabf90641371a82f9e2352eaa3d6b1da66737fcf447568ca4ec51',310133000,NULL,NULL,'02bb11b54aeb19bf75f02cb4f11ce58915a7ea9e259a890c983bd633d4467edd','e58023ce9ce1b7b76d224c8d4fdf82c9634451898e90a03e092cc877a64ecea7','93748b32e1fe9ed6166f006b43bf796616d9752c2af5062e9358754c026b8eb0');
INSERT INTO blocks VALUES(310134,'1748478069b32162affa59105257d81ef9d78aee27c626e7b24d11beb2831398',310134000,NULL,NULL,'9d8dcfc1a9ed2f8e43ace3fe96bc3538559f596162378c5d025d9b93735f1622','3a4b45178f8ac3b2afa6fc6bd15cd4624038948509c75b726da5d09e35b2a27f','62e85e14c3246691fa1d2403a060c8f742a22f71bbe11928b400f502025a484a');
INSERT INTO blocks VALUES(310135,'d128d3469b1a5f8fb43e64b40f8a394945d1eb2f19ccbac2603f7044a4097e4f',310135000,NULL,NULL,'846885b16eba83b5f82aa233d46fb033ce13c524a524f6dd743b66f93d0c73a0','b86b0a2a98d73c0ffa2666080b12dcc18a1194c9d123f0111af4e1227eb9bb48','cfabefebed69ccd281661a1b0fcd253883cd6c7610117859d41691aac7a05efc');
INSERT INTO blocks VALUES(310136,'6ec490aaffe2c222a9d6876a18d1c3d385c742ff4c12d1334613a54042a543a5',310136000,NULL,NULL,'b1df9aa1ef5099c736405247891b98b591005e1d46aded8734ca0962ef26fbac','5b54448919f98cae4982e69384dc8f15aa1da80c9307539188fca11a837216a9','8d9a0e751d81aae2e2f6b331299f826eab2724e7549b58a55d416d8d9bcb3322');
INSERT INTO blocks VALUES(310137,'7b44f07e233498303a57e5350f366b767809f1a3426d57b1b754dc16aba76900',310137000,NULL,NULL,'16ad5f32a5c87fa7ffb5108368a51a50a264cf37b83a4ac20d6bc8fe9b9472f1','53409ecb64d3fd03bc5233c57bce7423d6e47402a4b0f55977ad214772286241','8703b6bd28d604a57f17ccbebebc9a032ef7ae9d9def99fd737a260dec02a4ba');
INSERT INTO blocks VALUES(310138,'d2d658ccbf9baa89c32659e8b6c25b640af4b9b2f28f9d40baae840206402ab5',310138000,NULL,NULL,'e80ee8d6cd260263488006084164e02d6ecb72a92ba477d0f9696789ebbc09d1','a0cb31de975a1453e2c7f041f018a669e2c830defb38b3925c1c048b2d27fa06','4f5b8e1883628811892da03dc06c8dcb5b83be23d9a30aa13d21c2f31b7c0773');
INSERT INTO blocks VALUES(310139,'b2c6fb61f2ae0b9d75d18fce4c52a53b1d24772b1ad66c51ca51090210527d46',310139000,NULL,NULL,'d223ae28bf755b178b3bbb48e55dfbc353d58544b445051a38ad9c902a2b0e93','c0f1e55660a2cc20633b9512193daa52544745f11d5e1afee9d63f3de929ca20','36111619eb4e51ef12b083bf088aec65e5f0d5df6425575dfd40300c60a34543');
INSERT INTO blocks VALUES(310140,'edddddea90e07a466298219fd7f5a88975f1213289f7c434ed47152af6b68ebb',310140000,NULL,NULL,'7b3f67a5c3ce59beb1df6977e68cd952838a8c500f71beef71adbb7e4402358a','7db81c436569d691fff186a522b44be299e2233ec1e14455bfdd9c67a339f6de','4fc34a1674faa9a75c3b71a0701d95d1eb6aa091bb4e5d91c5a12fe7ed901e9b');
INSERT INTO blocks VALUES(310141,'b5b71d2a271bd638561c56f4ffbe94d6086debaaa86bfeb02ef0d71339310709',310141000,NULL,NULL,'a5ee51815dabf7378f7e7fd314c320668efbbc852651a8f3da946b11f2b45eb4','42b2f3c97182e6f4301444a0cefb6b9bc820f99a22a7c2cdf9743b5e965fa290','178592cc8571a05ed850ba51daab0e64f78c7980efc5b6051d17f19efd9aff83');
INSERT INTO blocks VALUES(310142,'a98ae174c41ab8fc575d9c8d53d8e02d8e446b8c6c0d98a20ff234eba082b143',310142000,NULL,NULL,'09306fded3fe8f9d0d4b1d6cb75cbc27ecb3837d86f360a501fdc879ff0cd9c7','3c3183f5ae911764c40395e045ebe693c88991737af0314321935598d9713c33','ae8b8d8c12d634a5b1b183374af5321f4b66d87151a268b15dcf2ae2999e9913');
INSERT INTO blocks VALUES(310143,'8ba2f7feb302a5f9ec3e8c7fc718b02379df4698f6387d00858005b8f01e062f',310143000,NULL,NULL,'4a8c9a864e7a2fb16d019b3146e111f20b679eb3f46b3edd29e9103e05b23f77','6c96725299469cbd6c7dc5001ff56963885355593a35901e4e7a62ff2e638ab1','78d14b4312c8557ff12b631f007749860a8e67cb841bc484535711e395c646ce');
INSERT INTO blocks VALUES(310144,'879ffa05ae6b24b236591c1f1537909179ed1245a27c5fdadd2218ab2193cdb9',310144000,NULL,NULL,'37d8d4beb1980194e3c205482d2af20ae43b314461e049134784cf1328d99186','5dd9e3a47a556e4f910cab8dd39c0adc3e7e39542aecfce9e4048074163da59a','6e895aa8a0fafc39f160058d188e53273401cda1d93e56c68125fd4e03f34ae8');
INSERT INTO blocks VALUES(310145,'175449ef0aa4580593ad4a7d0c5a9b117e1549ea772af00caa4ccdc9b1bf7a6e',310145000,NULL,NULL,'7c43bc2fb057e4fd87110206da7a9be11a9b288a6298be38cb30ec9fee55759f','243fd099fbb90d55b0bb6099c9f08a85bde95c275f338636e5473198109ab47a','66b598e222f021beaa5cd4274e272524f564fe0920a44a408a80b19c0990a937');
INSERT INTO blocks VALUES(310146,'e954ab6a110455d745503f7cc8df9d92c1a800fafdd151e7b1912830a9cb7184',310146000,NULL,NULL,'6fd152f102f3d601e43a5c6b6bb461bd3f8998ae8c69a1014e144fc58f0e97d0','0af12b8f8661bab286993a78533e59fb7563404915b49ff8ec824f3f05b5f10b','6199bce3399dd28d66abe3e2265b04eb5aefe51fb9639df62843276a96c20e75');
INSERT INTO blocks VALUES(310147,'7650c95eba7bf1cad81575ed12f32a8cc36281a6f41bef13afe1dfc1b03a7e83',310147000,NULL,NULL,'2b811f7b1d3c6e83d22d311ebdcfd0051a10da5147e31bc52092c39d53deade4','016601a215d3c1d72ee5df1d0d42404d8a43032b0e27f6ab187af8dabd427871','b638a653386ae4c1fb2419cfa974a73ce4df0520a51eaa0e587b7eb49f7ea5e5');
INSERT INTO blocks VALUES(310148,'77c29785877724be924f965215eb50ffe916e3b6b3a2beaea3e3ae4796545a7e',310148000,NULL,NULL,'76af113db9912aade7fdf3d8c3d8d0d4ca4258d7b62432d65cf42d65380dfd40','fbf30357de09e6dc04e9d280ba190a7a10cea29f78186b9790842d914dfd251c','a54418f31d29f4d4a9b729e930c1d733259bbef113afa79e00ad1a003a5dce4f');
INSERT INTO blocks VALUES(310149,'526b3c4a74c2663fc04ed5234c86974bffddb7235c8736d76860778c30207b3c',310149000,NULL,NULL,'293da1e0bb5c6d8eb3170f529abad1dcfc9d58891fe15920fc891db69bbd75c0','25cb870290473bafdc4c4cab71b5baa65410bc2f478f900d31fefb0f3e8bd10f','4ff83ba1ad6ae0f62f94c62575c6f78b9d50ea1a057ac5a324a2642770bfb2c9');
INSERT INTO blocks VALUES(310150,'cdd141f7463967dbeb78bf69dc1cd8e12489f58c4ea0a5dc9c5c01ec4fcea333',310150000,NULL,NULL,'9177138ab12a2623d9d5ad5a422e54125294d6c8a04e97d593d7804eb671ee85','2430ddc5a86f497ade9fc7b81e4f3b0197592abda62625430eb7845990db1280','02e5f147cb0c7cd9439c995122fb30f4e88638f4794eba398b8e3c938d1ddfac');
INSERT INTO blocks VALUES(310151,'a0f31cc6e12ec86e65e999e806ab3bfa18f4f1084e4aeb4fbd699b4fe284b330',310151000,NULL,NULL,'0b5aeb4ca08a68e19eaea89f7c0e3197cda855289d2e8e6a9f77bdc4b1236ab7','3d91bd8c3aa63bb43f31f363b353420a14067e723e3ef7be7cd848799ee494ff','462c1b14ad3bf1da879d16bd213e87ead40848bf9d74c48456f7ad11f5c23f5b');
INSERT INTO blocks VALUES(310152,'89c8cc3a0938c63a35e89d039aa84318a0fc4e13afac6beb849ac37140132c67',310152000,NULL,NULL,'86ca5a2198023beae56db05d16057d046d9cea1c0472b4a13901149a17f0b1c4','dbecdc0c12deb77970f70822ef8853f32821f3ee83ecd075bff0aafd57ae68cb','ff67acfd13a1dcdb994e53e962e0c3ead21544116fd4b9ba2eab7cf4b9bd1bdf');
INSERT INTO blocks VALUES(310153,'d1121dfa68f4a1de4f97c123d2d2a41a102971a44b34927a78cd539ad8dca482',310153000,NULL,NULL,'b543d4a729392e7e998402aaf1661e5245969b2e8dd738782be18cd2dbbb4518','a0614f19fb8fd4ead42e0c4639e7f1953a1416b8251b7a8b3c23fa2e7ab59d96','8304d958742f7776b7a6b9f8da4a2b2ae410411fb2dd02261a530cba94e97ad2');
INSERT INTO blocks VALUES(310154,'ba982ea2e99d3bc5f574897c85485f89430ae38cf4ab49b7716ed466afa506d6',310154000,NULL,NULL,'d6ea0a6a523abe73969ea51552934b494ac8e3464d1a0bb25b6c1ffeb93353ff','38c1344821b5b89633c4929f900dc25ad5d4983f5c1276fe0afef559c628c215','2ad93ee529c82e04a95abad5ce7a560bf280788e17e038435e2123d095e2dfdf');
INSERT INTO blocks VALUES(310155,'cefb3b87c7b75a0eb8f062a0cde8e1073774ae035d176e9769fc87071c12d137',310155000,NULL,NULL,'20b8b9bb0539f33cf4dcc9941576e4ef9a3b1f01f6cf4b390b36e39c3cb13cc3','091b8a9f8d292aacf6a775d02f22b35df34820bb5072ce1d90772caf231bc55c','d9eaca6826a35f50b3d7d5e12c7da00cd85f5838955a274922682a807a9d850f');
INSERT INTO blocks VALUES(310156,'6e3811e65cb02434f9fde0445a7a2b03fe796041458737d0afcc52208f988a83',310156000,NULL,NULL,'435b2a7ac21fc626549ec2cf4ad62575d97d923d138ab3183d0c7df757414e75','184947cda324f8dcce91e8dd89477cb2e992568913fcd8cb2df15975c1a26206','c367946c1bcf30770dc6d4cfd12abcaeadb92950eaf2ea13a69b3a509b18dafb');
INSERT INTO blocks VALUES(310157,'51dd192502fe797c55287b04c403cc63c087020a01c974a565dd4038db82f94a',310157000,NULL,NULL,'acf69f18f9fc30aee7bfe1b5882cb6a67a3854d248557838955d9238a5b8728f','701c65553360ece0a88b178bd4281a2e0b1dbc6e56e9fea48babe199ff644da9','4eedc3372932caf8dc25eb99aab8782e1760b2e1f51b639a96e4fe50c67c6dbd');
INSERT INTO blocks VALUES(310158,'749395af0c3221b8652d31b4c4410c19b10404d941c7e78d765b865f853559d2',310158000,NULL,NULL,'ce48e1cf32960df827aaf74ca6efe06c1a8c3688e6f7642b4d7790ce34b3c202','64e8819fc0b385e49a7b7c054ce10fa218a54366e3b1f190a61425839c16ebfc','424e8d4751fc03f4855f52334f6d17c1fe4549b3ba23fbe937950a07b835d257');
INSERT INTO blocks VALUES(310159,'fc0e9f7b6ae99080bc41625588cef73b59c8a9f7a21d7f9f1bf96192ba631c12',310159000,NULL,NULL,'dd4a228afb678097e20f6cfdf7301ef60ca5a6a13dba8de959803bd5c8daa96b','2ab8b975ae2cd63e709306e494e8270f755b1821883f178f7a8a9e500ebba052','361373041b350987ede3f6c0585eb2e018d27b98011c897568c9eaabc7dbbcd2');
INSERT INTO blocks VALUES(310160,'163a82beeba44b4cb83a31764047880455a94a03e859dc050da782ed89c5fa8b',310160000,NULL,NULL,'9aa9dd1753d04d592de0636e64316f6c14b677539882c2d01d8cf8c55a58a206','03321df7fb9e8188734cafd82eb5f8b1b0531a81f31771e26cadb650f3a1793a','467afb0a83bb41dcae6f59cdfd491113dce55f08e916065ac6587f05f69307e6');
INSERT INTO blocks VALUES(310161,'609c983d412a23c693e666abdea3f672e256674bf9ee55df89b5d9777c9264d8',310161000,NULL,NULL,'134b0a90c99cbd52610b69ca0e64aa1e8e8327ec0180114fb037ba3508f93198','355572171ccf7becd1c4648123ad45c70bdb074bccd27b3de586517a7016efb1','8701bce4fc3f5255e5d7d78af27c54bdc90a1017e79eb5bcbc55ce0346daa720');
INSERT INTO blocks VALUES(310162,'043e9645e019f0b6a019d54c5fef5eebee8ce2da1273a21283c517da126fc804',310162000,NULL,NULL,'b37828390afa54f0045f55d3ee64f96f6357c844ce411da36dce44f454661d4d','6e3c4f69c096ea1ddfb534eac9826348d3a99503ba643de6cbbcb0f3b8150dc1','7a5935d58efed162640630d3a9fa75d2b90d38e6b732cf88955da806afcbe3fd');
INSERT INTO blocks VALUES(310163,'959e0a858a81922d2edf84d1fbb49d7c7e897a8f49f70bd5b066744b77836353',310163000,NULL,NULL,'9a9d877bbc473ce845a3188265b1795c415d0efe7e25e3be628a1cc8f0b5a4e8','a90f7fa968836e6031e9ca74746290dbad039705a66d0370935d76bd32966ce8','3ae5736d54c096d0076bc91cc648ceb7a4eabd3e03054f1b7f3aa9232f64c5fe');
INSERT INTO blocks VALUES(310164,'781b7188be61c98d864d75954cf412b2a181364cc1046de45266ccc8cdb730e2',310164000,NULL,NULL,'4c5ad18492853f7a17975c13c43dfa0a9ab9d45ab8e06053ae3b60f515810268','a1021ba62f8b2f03a1df3063095903c7688d7898b4179b29fe5d4f183dfe9ba4','d179d99c581c18e3a4721eec5071d4dc49d9e88c1ee1bc742bf96a1c0771973a');
INSERT INTO blocks VALUES(310165,'a75081e4143fa95d4aa29618fea17fc3fabd85e84059cc45c96a73473fc32599',310165000,NULL,NULL,'fd421ae7fac129082be9188c327c47e1346eb3ae10d1dc90025b802684048e27','b98e24b514f0a6b600487f315897aa59b2703a5db4fdd67da1f27896c0b9ba7b','c096e104dde055a47a81a0afd4cc0e3001c338920faa2339cc4f20e3b63ce927');
INSERT INTO blocks VALUES(310166,'a440d426adaa83fa9bb7e3d4a04b4fa06e896fc2813f5966941f1ad1f28cfb41',310166000,NULL,NULL,'3c1abc1069309a607c36d94ec6a8b1a9c59793c10bfcb238663c2432dcf790f0','9ad10ffaa1137613230d7fce02a0f6772b1b5716185b51cb28b6299474314f86','bdbb01e05f411164abfa59d05de7e0625e8fae94153e4e6bd91213ffa131d3bc');
INSERT INTO blocks VALUES(310167,'ab4293dbea81fedacca1a0d5230fe85a230afc9490d895aa6963acc216125f66',310167000,NULL,NULL,'aeacfbf1bcbed38b8ccb0c931a071d266a7fe046f21bc6b678c4b40095579f78','a6a2e873447cd178e89cdecefe1d820c69a43f83161ec4d38cd2ecd7e9432791','0e83f9f5e3b4371fe39e7e5fee125415a81f956cf8d144704596c6cb104f16a2');
INSERT INTO blocks VALUES(310168,'a12b36a88c2b0ed41f1419a29cc118fae4ecd2f70003de77848bf4a9b2b72dc9',310168000,NULL,NULL,'2b2ced77684a82e17f4514193b6b8f718185e0dc7cccc3accb441f45727770a0','7eb6aad6aa2121e1392103bd13130d55ae9f275a81b8284fccc243e14c8f9c23','36f7f403ed23e7ef91fdddf68649314b18c5974b2aa7e68068e390b7bee1a7ac');
INSERT INTO blocks VALUES(310169,'204809a85ead8ba63f981fc1db8ae95afe92015f003eaebbec166021867421f3',310169000,NULL,NULL,'acd36c33c82b6b1dd9e7f5a0e131c1a86d49f0afb9c3da617ce1f560a97245d1','e262464fd56453a04cf2e24b6461c9ddaa6dfa99d5e42788e71554302453e102','6d024d124eef113de1cf2f1ab66fa9cc474b6b98bc1bdb2dbb734050e26c3a03');
INSERT INTO blocks VALUES(310170,'b38b0345a20a367dfe854e455e5752f63ac2d9be8de33eab264a29e87f94d119',310170000,NULL,NULL,'da12688a674d94ef9068f73fdb84d5dd7bdfa7b5ded75ee1304b7503f546da57','a9cd40de85e775241ea0af3686f8d64fee3faed814ef13f75ee12ad34fc373a0','846bb8d911b9cd14ebe43a09a23f4526a0a999e3aff8a23673451f60d8fbbeb3');
INSERT INTO blocks VALUES(310171,'b8ba5ae8d97900ce37dd451e8c6d8b3a0e2664bb1c103bf697355bf3b1de2d2d',310171000,NULL,NULL,'699c1860dac31e2f6659fa1c7ade8c5cdcafcc35c02207d66ab6fce41b171316','ff87a070d7f0c1cd8122deff88c0097b7126e7511c373e71cbe1f29f96f156be','4c91b4e3fcc77d9369b7f0b1a05ff5106367b12165ec58b8886c55efdcbbc4c4');
INSERT INTO blocks VALUES(310172,'b17fda199c609ab4cc2d85194dd53fa51ba960212f3964a9d2fe2cfe0bb57055',310172000,NULL,NULL,'a99f6967df817ed30316189995158560591558d896990b450b502089d6b21be1','10c45490f2dc80303e2c687153ab19d6494d3eef34c9645df2e753807a113a65','554117bca38c91f94fab7066086f3effa25478af7ebdaa7e300e3f2fa130b3ac');
INSERT INTO blocks VALUES(310173,'f2dcdc5ffc0aca2e71e6e0466391b388870229398a1f3c57dec646b806a65016',310173000,NULL,NULL,'3b6fb2f41dbdc369174bd995a2ee9fc445e834ec3702ac157c709baab9552b0e','5151c3166a846efb6f9fefe54af3b6ea714a1480e0eadd9f8242bed400e75567','732c1dfa6f8924012c3c95627da3ef68273388c5b3672121e5f41b8ee144ac7e');
INSERT INTO blocks VALUES(310174,'fa6f46af9e3664353a473f6fffce56fa295e07985018bface8141b4bf7924679',310174000,NULL,NULL,'6fcf2e453997a8d40625b08f831b40db474d62aacf1e48a80e09d12bf3390c8d','e94f9481b1531f16f9d8e7003de990d685a86adc2bc1ae056c4c14d71a6e1c78','b6f58d653debbffb08e49b21b97c904c81eaebff567a0c61b0ea4b9db4842bcf');
INSERT INTO blocks VALUES(310175,'f71e79fe5f03c3bc7f1360febc5d8f79fc2768ce0ff1872cf27a829b49017333',310175000,NULL,NULL,'1c3b1ae4508285d42a96afdf86c1bbf95580e5d21a2f3c4565bb2b3a2557e989','0cedb73171c296e671b2183a4a469d8f70822d338fa6cbe451605999d45f4118','8e895bdbbed5b99c258a663c586cb1fc31289151916348315acea3b612f7f05b');
INSERT INTO blocks VALUES(310176,'67cd1d81f2998f615602346065e37f9ceb8916abb74b5762ead317d5e26453c6',310176000,NULL,NULL,'e549069b2ab545f329d1851b979d0734732bc85e1fd455e6a33c72c936c15461','661a46ea2b41a79340032f90d7dc68ed16c8458ef0387d44bc52a1b6eb198245','6f3f3ef1bd4cf06342d5f17ff8d736e167b45073dd68a5f4b53b1f89f10fd7e5');
INSERT INTO blocks VALUES(310177,'6856b1971121b91c907aaf7aed286648a6074f0bd1f66bd55da2b03116192a52',310177000,NULL,NULL,'21e1a4f9ca768c5891f5fd35033840a599f33c5a453507b0c19b813ebb87e860','e0b1b3991e8455533e9db7ff31d009c5927dffab7fd16c7e28abe865d72096cb','75fd0b7555af0a4f569b46d331245aa3a53dc5d42f61712c21a1fb04b8a19239');
INSERT INTO blocks VALUES(310178,'8094fdc6e549c4fab18c62e4a9be5583990c4167721a7e72f46eaf1e4e04d816',310178000,NULL,NULL,'afc224fa2f213ce661118b599cbaf7f0fa049d140ecf5c41a9edb484d1eb7879','903a1c45586249e71d42fc78767a3a709f9fbf37826a0056ae7943937bd9955f','3a6e9404971038d61cff55a61b09ddda7bf25737d5d832fe84f9d067e2a51919');
INSERT INTO blocks VALUES(310179,'d1528027cd25a1530cdc32c4eaff3751a851c947ddc748d99a7d3026a5e581a7',310179000,NULL,NULL,'24ecfc8c70ed08c8ad2ca95171596adb07c27ba99181c8e2ee38923139857633','250dc0685a71b2b357788601b6e2339b18b0ea0662bb89d557b750e88b9813cf','3dfa07de3c103f61bc495df5a9f801acebfd5342ec32364adb0834bf3de78dab');
INSERT INTO blocks VALUES(310180,'f2f401a5e3141a8387aaf9799e8fef92eb0fc68370dae1e27622893406d685c1',310180000,NULL,NULL,'8907f853e2ec89be38d24f8b868dd73685de4d7393d8e6ec50aee4f5974fb860','33acf0c9eb5fb351718fba92fec4494a4ba4c3aefa33e6920d0d187fcbb9a0a6','f944678261e6e131dfdd1dd5ac75a82637fd68166709aa86f799dd5185e008d4');
INSERT INTO blocks VALUES(310181,'bd59318cdba0e511487d1e4e093b146b0f362c875d35ab5251592b3d9fed7145',310181000,NULL,NULL,'d46aa963e08100b67c89460ccc69bcc14be9765f492d417cc7008f0aae241638','1963817eb7ad1bcb7f66a03f944c9d701bd3962be8258feeb73fb5ed04b9612d','44c4362d9d797a6fd790f5cbc74507e98d8bfe14bf707593fcb225019f2022cc');
INSERT INTO blocks VALUES(310182,'a7e66b4671a11af2743889a10b19d4af09ec873e2b8eb36949d710d22e1d768f',310182000,NULL,NULL,'00ddb3e51f710f20dd6faf55b92f903c7e0c14ab569dd66e04f427c5717de2ea','9ff8fc33f477389b21bca31a334333f98dced7fbf788ba72b216f657cd11777c','da9604140514ccc69ca96ffe9dbc1d6284593e61a916951109771464e28f18a0');
INSERT INTO blocks VALUES(310183,'85318afb50dc77cf9edfef4d6192f7203415e93be43f19b15ca53e170b0477bb',310183000,NULL,NULL,'995e79598bec480ef6c802c424daf25ffe7f9fcf8589e51514ea899fef83b5a3','1dbb51a43269ace2ea32dae2a5c0a0e25b2e1a891aacd0331b864d677df5c766','217d9708d3e06ef0ced5c14ab7ee3a60eef183d76c3ab854b5b508f2b2944d33');
INSERT INTO blocks VALUES(310184,'042a898e29c2ebf0fdbb4156d29d9ba1a5935e7ed707928cb21824c76dd53bfc',310184000,NULL,NULL,'5ad000f4d715e43d5eefea6bdcb49ab24da02c0f12547430f974b833a6f4b4c2','1b40f41442987e7e032a2ba4b88f20d8b9d1958844390d6dc64733637827543c','c98aac59d4fbdd795098afaf144176713c0bc35efc02c2dd84806f2d3ac665c5');
INSERT INTO blocks VALUES(310185,'bd78c092ae353c78798482830c007aac1be07e9bc8e52855f620a3d48f46811f',310185000,NULL,NULL,'ddf542c98b23a9ec52a5f1713933dcf24040738cc51a418e6c8a43103c35dffc','38b625451d27b9cabaea3c834d2b69ce3236d66148bdfdc473e1bb2b40e8d1c0','1b574704fac9a0b7df849a5fb4441c8bc2e81d3c5e6cf67bcf6aa7cf3c6975c4');
INSERT INTO blocks VALUES(310186,'e30a3a92cc2e5ad0133e5cee1f789a1a28bea620974f9ab8fa663da53e5bf707',310186000,NULL,NULL,'81b977eb224932497e8bcea9dbab41935e4238e7deaf45d1d5d0265e34ccbffc','b3d0d1bd5627f658d87d720c4ea756037631a18de1d08ffc22c088eeef28de68','1dc5b4c37b874442a3f6593a525de3bebedfd1c01f3786c3110f2c6f04325fb5');
INSERT INTO blocks VALUES(310187,'fc6402c86b66b6e953d23ed33d149faa0988fa90aa9f7434e2863e33da2f3414',310187000,NULL,NULL,'d046b7811a3575e57c6854f52995e21de061a94693308956ee010dc4ffc49ef0','ebd1a69c953db81f7576a4b209e7690946a1cd911360e6c0aabc32d0f01f6dbc','15146f27cfe5434ba6f4d7e19afa34ce81853b118655222ac03ec1b31ab45805');
INSERT INTO blocks VALUES(310188,'85694a80e534a53d921b5d2c6b789b747aa73bf5556b91eeed2df148e2ada917',310188000,NULL,NULL,'1dd71724a3eb4bc335cc01d1f39a51b691220e13a612756cd6275a75da3c70b9','9ede79db99dddbf536b0e8babb7d116fd65cd015d3ae30b60bf76115a595dc34','d4d05fc6958d2195ed9039c2dcab25381b34747866b3c6c19d3278fe3a952009');
INSERT INTO blocks VALUES(310189,'7c036dadf19348348edbe0abe84861f03370415ed2fec991b9374dbb0ca19a06',310189000,NULL,NULL,'98333fe204dd15dd20f191c83ffe44c277bb507e37a7c0dfbbcf9e7d9ab860aa','954bc6a9e11528b2818ae2e1988fb8d54e1bbb30939cb78da2a935756b7adf74','469d34590105b07dc5108f3deca82179c4471a4ae58b90be8294ae7261eaa987');
INSERT INTO blocks VALUES(310190,'d6ef65299fb9dfc165284015ff2b23804ffef0b5c8baf6e5fa631211a2edbd8d',310190000,NULL,NULL,'6e626e1434df5247403d3c4f07da47fac127bf422b1854b996ae35434d23062e','e048eb76b2aeff1dd91e95d47a31f4fd6ad9860b9562c7ae58ab0fc967de1193','829f9a5befe1dd9af11216f2bbd7fc0c704f70becb403e44f92f8a286d427c7e');
INSERT INTO blocks VALUES(310191,'5987ffecb8d4a70887a7ce2b7acb9a326f176cca3ccf270f6040219590329139',310191000,NULL,NULL,'033cfc09074cb2cc9ca299c5aaea45ef156e084fd71b34b2725e6de3dfa24ca7','311d2946254d6ca4648a43f4523b47d0573d771860603233e121929314e18ae3','31de80beeb34430e8546cb73b0d2e9d5b0b9fc5a11b909631abf29f249de91a0');
INSERT INTO blocks VALUES(310192,'31b7be43784f8cc2ce7bc982d29a48ff93ef95ba18f82380881c901c50cd0caa',310192000,NULL,NULL,'4b8c3cad476dd7cbc2b06d6eed5322735a0ff6ef7aa8bb181e1a2316ebed02ff','f8b67bd44ba58d18323d5775ddca3dd8cddaa83c27ce74dd1ea00daf3a288608','a59f4fc3615041598c75837d27533c7875271fd4d850a76b449a8eed5100aae7');
INSERT INTO blocks VALUES(310193,'ff3bb9c107f3a6e138440dee2d60c65e342dfbf216e1872c7cdb45f2a4d8852a',310193000,NULL,NULL,'f2f28a997583861b81671f67ed6f7ff58e4370720fa971004ea53bc0eb801563','02bdab4fd6b684a21fdc7d30289eb235f446c380166117454017c8c0ab7aefe3','43c31e02169870c782476cd46d7ffa6b4f962023e0e2db93092aa434f3de0de1');
INSERT INTO blocks VALUES(310194,'d1d8f8c242a06005f59d3c4f85983f1fa5d5edcc65eb48e7b75ed7165558434a',310194000,NULL,NULL,'5288907148c38f523b5a35256df9af02d6c4839a0553db4d8dc4e5761e39222e','ec18f7533d65ca93c7f852e494b01949139acc7caed01ad6dea70ac41417cc01','f1993a9cd8a44137444ea523be4f4bd604df266b53c0d02d72b9786252fe9bd4');
INSERT INTO blocks VALUES(310195,'0b2f1f57c9a7546faac835cbe43243473fa6533b6e4d8bf8d13b8e3c710faf53',310195000,NULL,NULL,'d7f8c3999c777af3e1dedf5e9ddeaf729ae32ea275aee60714ce06409ccdba86','f80ed9e33adb5cc967b95de40b70b6d90e241d1c894e3c1aafcef493d90743c5','a90f1c54001ad0497d8de9d2dbaa7e21c5b1cfca1bf003646ab13b16c366593a');
INSERT INTO blocks VALUES(310196,'280e7f4c9d1457e116b27f6fc2b806d3787002fe285826e468e07f4a0e3bd2e6',310196000,NULL,NULL,'5448a096d62aa83c272832b35f2b8c0d68a625facc69080b5c06501a1236efcc','3733778c68417ca475f7ce757b968cdf7ecccd2821295f7894984a215f670a01','04ab33872252d1abdaa7b17d66d423f100fa0dd522e659141787e31e1804681b');
INSERT INTO blocks VALUES(310197,'68de4c7fd020395a407ef59ea267412bbd2f19b0a654f09c0dafbc7c9ada4467',310197000,NULL,NULL,'06f1e7f0cdb849749ebf7e9de0ea70659d9a11dcb92066a15fc8424beb859ed6','d11aff44bdc7cc503c4f191955645c31974fb20912a1bec1ee4e7d29db71a6c1','a63678f8eb3d6982a2088f37bfb67e34cc63c08a2939ecd674b98cc5c0e7aca2');
INSERT INTO blocks VALUES(310198,'30340d4b655879e82543773117d72017a546630ceac29f591d514f37dd5b1cc2',310198000,NULL,NULL,'aa4787f25ca1d5445a3931875ae2b94f1954ad0a80b51df0f3e6aa61efe4ed27','b7eacd24904a677a94cf0669ad42cc7a0c44cb3a2de3864befa6a6f712d5688c','9c2897a6bcb429e863be100041fab5af65ffd9eba1b844932a9fdd5ba26d834f');
INSERT INTO blocks VALUES(310199,'494ebe4ce57d53dc0f51e1281f7e335c7315a6a064e982c3852b7179052a4613',310199000,NULL,NULL,'0411db38f4af135aa93025a7f658c8a6697fed4cbef2b1e876cb99b3c5fef9b7','6fcd7bc47e3a0bde347928e75ebf92df5498cd8751cd458b0c5de7ab95c64307','0f68ec67c93bee0614c17a1bec334b0d958e555adcce4fd45480357ef5a6efd5');
INSERT INTO blocks VALUES(310200,'d5169d7b23c44e02a5322e91039ccc7959b558608cf164328cd63dbaf9c81a03',310200000,NULL,NULL,'b8ca174552a90f180250fa5bf7a93bc31c2f4e7034370595e3ccfebece62fa4e','3dea757f03cca14afddca3c0d0fb05d9c102443c8f4c2c229934c1941eb580d7','8a0b54bb7e1228ef0336f5f2962ca4e18f7d610da29647fee911006dc9d3bb87');
INSERT INTO blocks VALUES(310201,'8842bf23ded504bb28765128c0097e1de47d135f01c5cf47680b3bcf5720ad95',310201000,NULL,NULL,'d9249bc1ad0d9f0c7980549f49e772e8194e3d3229a73a2f31d904cf21f5fcf4','58e3eb6f7a2ab6c588563965154ce1ea3e2ca3c1a1978d5e3994268f2bef070a','689b3457cb6d7dfae96fafe9dde7d9402efe99d75789a08b26dc0bd5f22ef5ba');
INSERT INTO blocks VALUES(310202,'95fa18eecbc0905377a70b3ccd48636528d5131ccfa0126ed4639bc60d0003d8',310202000,NULL,NULL,'6e5c4761430cdea2c16f04dff0a1c2d17d6fa51a969a56922568902fd9718936','dfd19388ea193a8acbfb41ce5b56aa21d81ab7af40a179741777c69839f83a53','050addadadfa34047375207d10fc08ccffe796a570d8f426e9826fb27cc5d844');
INSERT INTO blocks VALUES(310203,'ab15c43e5ac0b9d4bd7da5a14b8030b55b83d5d1855d9174364adbebf42432f8',310203000,NULL,NULL,'fb23977bcfc5ae44fd7e9c3bbc196e2359993ff6edbd8844fcd04719285ee373','492dc816c35657f15e3f760a3b013a03174a78210862a263d807d981c1fe735e','afa977e6bbd28dbd2246e33e25788950e7b777d8642488e3dc0cd4f74d113d89');
INSERT INTO blocks VALUES(310204,'18996fb47d68e7f4ae140dc1eb80df3e5aba513a344a949fd7c3b4f7cd4d64cb',310204000,NULL,NULL,'df8a56d16661eb472365bcb1e0ee1d9f42868dcc5032c6c325821d6b418d4f5d','30011735efd2df839d79bee2dc1b7331300550e1471cb126824f920d20195432','75555a7020ffabf173e1c5e813e8406172f2d5bce6b2e54dbd65dd179f488172');
INSERT INTO blocks VALUES(310205,'5363526ff34a35e018d1a18544ad865352a9abf4c801c50aa55742e71630c13a',310205000,NULL,NULL,'7e080d0c1b18ab9eef06f3bb9968a84b21f564fce3593e181136c2bd65152ef2','6264be9b4f20806c266702fc782c3c4bde2028d8b9c64928bc3d1166ca56431a','e95b8ed2d5c2f593da9cef19ea802bbb5da9e492ee9b654f80bb8af6bb05cb84');
INSERT INTO blocks VALUES(310206,'0615d9fca5bdf694dca2b255fb9e9256f316aa6b8a9fc700aa63e769189b0518',310206000,NULL,NULL,'7e7279c004bd3225c2d3ab117f69e86b8b726b0831c537bd5171377fd871b54e','d93fc36f3a705daf775c027cdfe0f7265018185b784c438834f2ed7b8ec5fcd4','1f543a22d8fc7542955644e2fa7e2d82c93e17e6a52310e4a3f7ad4f85002b11');
INSERT INTO blocks VALUES(310207,'533b4ece95c58d080f958b3982cbd4d964e95f789d0beffe4dd3c67c50f62585',310207000,NULL,NULL,'d147259997fc13f032ad8e1a27eccb5a1ce564b1101aac26ea0983c60b4cb830','e0382d53f4e64e0feed5d2192477971f3fbfaa38f6d25ff7496847795d932080','76c7043ae51fbf2993cccafab65c50c13a5531346622f1619da4e4cf1a34a3d0');
INSERT INTO blocks VALUES(310208,'26c1535b00852aec245bac47ad0167b3fa76f6e661fc96534b1c5e7fdc752f44',310208000,NULL,NULL,'fe27ff63a6f8bda4e0e1876c729ae6f4512b32783cf325ee922517318acf57b3','2846ce623013bdd053174dc61950b68644196d649961e3a4292102b872ac86d5','66d683c6bb5a2215fb87d591ba666d0cd291c8a78c28b62b3857f720f02c7b42');
INSERT INTO blocks VALUES(310209,'23827b94762c64225d218fa3070a3ea1efce392e3a47a1663d894b8ff8a429bf',310209000,NULL,NULL,'99fc696f0d219dec99aaf4d77b8678a23eeb3f8f03bf52fedbe7b82792ac1cb7','be6fe35b17e5623e88e9a41d2d5311bf88bf389a2b00084308cf7c4a61e5273e','37b1652e6f572abf48737637ea151545617c1636842e4686752c59196941dca1');
INSERT INTO blocks VALUES(310210,'70b24078df58ecc8f7370b73229d39e52bbadcf539814deccb98948ebd86ccc0',310210000,NULL,NULL,'6d09a7cb18a210d192162f065a7a34baa0ea34e348781753259f300666e47ccb','61ecb42eef9198568374a4f24a674e713e52d27e2ab8e6e4448be3b9db24067e','40cddd6bbd43204031c5389c67bac773157efbbfc858d86acbc5c22fca7f96f2');
INSERT INTO blocks VALUES(310211,'4acb44225e022e23c7fdea483db5b1f2e04069431a29c682604fe97d270c926d',310211000,NULL,NULL,'d34fda69c1f1ed24035ee3d7fbe3248e75a7380de4efa64f50e29112e197ae3b','503166a6af641f563eda1f27cf419f6c7ff50e3b053ba9a56526eb81b6fceadd','3c5392f2adfe9f947b5db69305d5bdbe80290686176f62570e5f5b917b98c641');
INSERT INTO blocks VALUES(310212,'6ef5229ec6ea926e99bf4467b0ed49d444eedb652cc792d2b8968b1e9f3b0547',310212000,NULL,NULL,'07c7a2f835cafdb13e5c385a9abf37857f8ea590f4214a5c8b44983f26f32e32','5a57f720775c8460f3252f79b20895a99dcc4d41d11849ed0ab6792faad1241a','008f7c0bc31d3286c41125c3715f25fe74e5e05c5f35e8276aad27885c7034a6');
INSERT INTO blocks VALUES(310213,'17673a8aeff01a8cdc80528df2bd87cdd4a748fcb36d44f3a6d221a6cbddcbe7',310213000,NULL,NULL,'0be6909fe6522581cfdfdd35a9a37dc46e3b1255f7ec7fd552ac0b01002eb1a0','19e5cb9705d5abb63e1fe7f2e457702fa6f20f8ba36e80f08e0081e16e3c98cb','d631b5b0a9efb4ccc1a664fd07e1ff7d712879de01e54c2d67a16181e220009f');
INSERT INTO blocks VALUES(310214,'4393b639990f6f7cd47b56da62c3470dcbb31ef37094b76f53829fc12d313454',310214000,NULL,NULL,'ab1283d1f5834c4ea057534f47f0046cf1a6116d8185dd01860d3b4d40f521e7','6fee08511afa6b49afdb08fa86a498d2ed6f40367c2844b486a57fe3a4ff76e7','815c09e5318921cd02fd502838d8a9719e3d11073e39958aec8636a483a4ab2d');
INSERT INTO blocks VALUES(310215,'c26253deaf7e8df5d62b158ea4290fc9e92a4a689dadc36915650679743a74c7',310215000,NULL,NULL,'168475f6f5a869b45f86e41b4811f0012c256ebaa8c8b2933cc5635bbb18a1bf','2736a2b52ed665f1b233a16cc130bcb07d13d0ac2ae60e05037844f4e7415d1d','74b03eb7750c6e24abb56be15d1b0ad1372c36cc777455daf8b264705ebf8e0c');
INSERT INTO blocks VALUES(310216,'6b77673d16911635a36fe55575d26d58cda818916ef008415fa58076eb15b524',310216000,NULL,NULL,'36a883693e0c7eb8b0d592903efe0527aa36921c53b3081d2bfd8e70c4bcd778','aa8e64f33ee7d57d4bcb26ab5cf51a6a5b738c37c6867ec53c96d7ab54efe087','cc306f99c033266f7aae6ce7ecb01a04c8d003109ea2ce807dc42d622bfc866c');
INSERT INTO blocks VALUES(310217,'0e09244f49225d1115a2a0382365b5728adbf04f997067ea17df89e84f9c13a8',310217000,NULL,NULL,'e9b6505422e96e245bf4c1a51ee1eb98d5add95c19cde1904709abf01837cee7','f379421f6019459288adf5b1f654df90ae7dfbfe8ef37bd1a860cb28c4b1d789','bab602ddda8569f536de53ed5563d5c755e7e46f57021faafaa0df5ce6e20516');
INSERT INTO blocks VALUES(310218,'3eb26381d8c93399926bb83c146847bfe0b69024220cb145fe6601f6dda957d9',310218000,NULL,NULL,'fa5fa02a83035f8d9bc8f558301a40b2152b6f704f055c789775b654aadbd8ff','c26be59ab4aa6ceffcb7f57f061fc75d9f1a677c4c2ff1a45b87e959b729f44c','9d43dd93bc4aca373a43db9e41e8d6db749e6293ec94c3360cacccef305ebe15');
INSERT INTO blocks VALUES(310219,'60da40e38967aadf08696641d44ee5372586b884929974e1cbd5c347dc5befbf',310219000,NULL,NULL,'fd6450cd4c5e1917444019c6139357569827357d743513c83f820dd0b1e353a1','8f7b2ff55398a52239b12159b3fca0062c7e9ee085d23de754a46ea064089949','7e6059ff79ab6745ca26692c84b137255b783cf5dd1eb994b8c3202f6d5bd689');
INSERT INTO blocks VALUES(310220,'d78c428ac4d622ab4b4554aa87aeee013d58f428422b35b0ba0f736d491392ef',310220000,NULL,NULL,'cefb420d46d3482c700730b61b9cb93de6c71be0b8bcc0486cb834432ac5770b','8799e93db5965f8f14c9c067b666a561618d78bb6527e678aa57e320ee49bac9','6cd70a6c8d4e4d4cc7cfeb32919af53b38f6a2d715fa4e265826e9796539dd95');
INSERT INTO blocks VALUES(310221,'cf5263e382afd268e6059b28dc5862285632efe8d36ba218930765e633d48f2d',310221000,NULL,NULL,'d4e2511c559c3aea5f92d8cab0ccbd48a14711a54b86a13356c960b831358c3c','1a8717f0c184edffe3df54f954be7a651897f3371e563fafe355b0d1ef4d6370','68aa7a16c57ea421266a5be5efa870cafe98e2b46353004279d918908fa12be2');
INSERT INTO blocks VALUES(310222,'1519f6ec801bf490282065f5299d631be6553af4b0883df344e7f7e5f49c4993',310222000,NULL,NULL,'74756543b96ab06b93b57fc96c36933f97757be624125b63fc682d14a4648fc9','bfe8fa39369f180df7b5aff16705243dcb0a7d4c271467575972faf22acbd5dd','0aa7fe0e354aa00ee45173f5e567f52e2f9e5373fa94c550163ecfbbba2e2314');
INSERT INTO blocks VALUES(310223,'af208e2029fa49c19aa4770e582e32e0802d0baac463b00393a7a668fa2ea047',310223000,NULL,NULL,'5cf85815defc4ebb5cf9eba613ee1fc3365aec6db7a06ec3091b022adfd99752','9820fc571105a9687b239f058c23d51abe05e3e434ce901d5909272100857155','0b8afebe576cc7a7d859c9cf6dea21535fd3cbbd7955d15b903f581e5730a3fc');
INSERT INTO blocks VALUES(310224,'5b57815583a5333b14beb50b4a35aeb108375492ee452feeeeb7c4a96cfd6e4c',310224000,NULL,NULL,'80a377ec7f372b1fb354a8fa0f816f0424eecce346c46136357b3de8976b00d7','9ca9345b288f08b3c9c8f6ddf38ef5df5c78620d9bdedd6cba93c1d6ce70ffab','70b1428318e32ac0a61846cc2d76d3a8fd920ba48bd24afe49ce25943d8b40fc');
INSERT INTO blocks VALUES(310225,'0c2992fc10b2ce8d6d08e018397d366c94231d3a05953e79f2db00605c82e41c',310225000,NULL,NULL,'a8653217271d0181d697548b805e0e98855115dbc39a4ec5af697e4598dd2504','0e5882cc90a97fe64d586db8a458d430c5837d019b05e909d78f38bb68302563','3371ea4c598299e3e81fb2c910b3d574d326e0c2ca48c892ac82d15b32cb0a91');
INSERT INTO blocks VALUES(310226,'b3f6cd212aee8c17ae964536852e7a53c69433bef01e212425a5e99ec0b7e1cb',310226000,NULL,NULL,'e33ef1324f868d0ec5f7fd972e5ef77c8a9ca9a155f6859c4ebd6f9733c19160','e6c35b624cf947b3d8448d441d4021f443c6b0e8b655ec14d40c8cef89142fe3','4a383b17217a05cc59bf26bf92abc5f1b0554a9847113f57be4043c95b9b7496');
INSERT INTO blocks VALUES(310227,'ea8386e130dd4e84669dc8b2ef5f4818e2f5f35403f2dc1696dba072af2bc552',310227000,NULL,NULL,'ae3324201a1fed9fcc0847d4cb18bcdb92c6e826f2e4aa346bc33f67712a74c1','64c8803944cf0e8a07076bbbdb98fc5e7c2089a317e22578d5fa1ab07c6e22d9','6a25f3064ea50d43af0ea4f8979965dd7c3027da4f5e188c7c329d81bf1a4b0d');
INSERT INTO blocks VALUES(310228,'8ab465399d5feb5b7933f3e55539a2f53495277dd0780b7bf15f9338560efc7b',310228000,NULL,NULL,'19b6dd8993cd948e5b617fc8478c1a2be83dad4d27e5e52bba03583bfd36bfa3','2aa0a56523748d75bad9b90747ac9746d5dd1191dfa312889cb2a710156bafb1','6d27cbd2271cf4858d5a80a0b5afd75c874c6c17d8d30e54b9059d90ea109c6e');
INSERT INTO blocks VALUES(310229,'d0ccca58f131c8a12ef375dc70951c3aa79c638b4c4d371c7f720c9c784f3297',310229000,NULL,NULL,'d298bbe1429ed09717f634a03306fab5ccb8e4f462a48a8430bec80f1fabc664','fcbfbe5e2c5382810ed186c223d352194fb8a24325d665d3f4c2e312a9ed1c49','e3253066dd629eb9f542b862162881f30da30425e2239a96e5b10c76cc37b03c');
INSERT INTO blocks VALUES(310230,'f126b9318ad8e2d5812d3703ce083a43e179775615b03bd379dae5db46362f35',310230000,NULL,NULL,'bcbdd5d311342d71b78a073006f59fb8feaac00335bdfb5b4cf9738607fee091','e0435a74990fd82cd21e6d2ce035a910cc5489ba06c4e74a1f90e775f56227d4','b14484a3fa46a15973f61b32e17aaa2512bf1fd74f61d02e7059a5e12446cfe9');
INSERT INTO blocks VALUES(310231,'8667a5b933b6a43dab53858e76e4b9f24c3ac83d3f10b97bb20fde902abd4ceb',310231000,NULL,NULL,'8d7f44b4ce8cae60d95bb51afe2bf768c88acf6c4dc8f1cdf4eecf261f4d477a','1f51811dc569eae58f2a7c8bed28f2382ccb53004829e9fff41a6fcd18415df0','312a6c63e41fd881df761c47c02823bfe4da50b1341a145e264bc4dae594b457');
INSERT INTO blocks VALUES(310232,'813813cec50fd01b6d28277785f9e0ae81f3f0ca4cdee9c4a4415d3719c294e8',310232000,NULL,NULL,'d99a73a2b8e7b5a4f6897dea14c57a0d2d8bde04f10f875e8ab3dd8da35194f8','468f775f4bccc347b239a4f61facfcb23dce80936e185ee185792fd85f0b5bf3','67c9bdf6407fd115fd8e18337b32a8a901fda63a5a0114764ac91c4db513ed17');
INSERT INTO blocks VALUES(310233,'79a443f726c2a7464817deb2c737a264c10488cac02c001fd1a4d1a76de411d6',310233000,NULL,NULL,'bf8c9b9d46afab5a4fd0a02d040e3f96d56879a8103d152c2e2ece22f0166753','acde78c738d669ebf4cbc23ab4d25dbc8f0c1d8872944f8dca3b2b75c480010b','4d1dee6b94ff2e647e3e82d8d3afd775225705744ae0180d0a0b02359b5600fe');
INSERT INTO blocks VALUES(310234,'662e70a85ddc71d3feae92864315e63c2e1be0db715bb5d8432c21a0c14a63cd',310234000,NULL,NULL,'2e294ca044b35f2e9901de96ce330db197f5e03e96d4d19b3f83c2598223b501','a4414220498fa9b1004d2b49e08d94d9919265e040e6f600e8c4aa3fbc6f5959','7ea843b37355f63f1d6a561e3b84059058b89476f11f2fdfbb3d2e671837557c');
INSERT INTO blocks VALUES(310235,'66915fa9ef2878c38eaf21c50df95d87669f63b40da7bdf30e3c72c6b1fba38e',310235000,NULL,NULL,'54ff1dcd675e50f96a886038b2e7e78a3f5e233699887e75b06ed94ef0124866','09f2be8e94ba846c518cc6971ebd80c9e0d8869ef53be28ae62392c95751fe5b','e5badcaa391be5ad9a901998bea6b2ffd9bdea532f9f51a933222bf210cd88a0');
INSERT INTO blocks VALUES(310236,'d47fadd733c145ad1a3f4b00e03016697ad6e83b15bd6a781589a3a574de23e4',310236000,NULL,NULL,'3cf87c18e567eafa14fcd8146d0b183f87fd43a4f37ac9462d648ad3ee3f5f43','07b04e841bbf9f283d62b20923356e5ef89e9f6f4c6b7c82b13f795486cd90aa','5e88a7a60db08d1020a69b5e27b3cd9c84dec1c60f621d9e86cc758328550afb');
INSERT INTO blocks VALUES(310237,'2561400b16b93cfbb1eaba0f10dfaa1b06d70d9a4d560639d1bcc7759e012095',310237000,NULL,NULL,'dbee7786b16ba41c34a2bee1a4bf5e46178c76ed484171cc2c428217b14547c7','c65774d1657724878fa246354b77505f916ebb943ad6aef9ee00fede8e4fe6ee','5db3c68b3ee63ec58fcd5f602c54694b941c7a02c6ec9f68cccacacf65ce4e9c');
INSERT INTO blocks VALUES(310238,'43420903497d2735dc3077f4d4a2227c29e6fc2fa1c8fd5d55e7ba88782d3d55',310238000,NULL,NULL,'6b63e5897c43a9c76490072dc8a30579a09e8220a5cb4837d9919542e722630b','463258077a01d16ded4d642184528e1b39d8314af72e3b0cad24357b5c5109d6','900843067a068a46fe13fddcef23a9c7314076162124cf0473e1f55e0a44d260');
INSERT INTO blocks VALUES(310239,'065efefe89eadd92ef1d12b092fd891690da79eec79f96b969fbaa9166cd6ef1',310239000,NULL,NULL,'58849bc13e2ab88e94905aa4c2d4df3d9f1c4d33977d7127879d248e1ea95149','95f2148d4bd14b2111c70dbb39e18c9efcf6460ff952ac03c6dab5559b989e8e','ac91fd628cf069cd1b093d99f18fb7b38fcc496b0eb26ed76af74f61e9fc0403');
INSERT INTO blocks VALUES(310240,'50aac88bb1fa76530134b6826a6cc0d056b0f4c784f86744aae3cfc487eeeb26',310240000,NULL,NULL,'51df13287e12a0bc8157653cddd25bc6b2d41e5bdc62d3d91ac1d22781ec31a3','9d8d318f50717c84f262e34d0a0dc185e978b68ea4bbae1ffdc6bb3aee7134a8','8485698253303e73f09f7c1e59cea792c99b500fb548c3fa1e5553188e758eab');
INSERT INTO blocks VALUES(310241,'792d50a3f8c22ddafe63fa3ba9a0a39dd0e358ba4e2ebcd853ca12941e85bee4',310241000,NULL,NULL,'e2848ed74fe574a48436b450ab0c85258dd1c62d7d628c018a66bdd2083e23c4','2f6eadd879f7979f9f8eb28c6b14c89bf58224fa0b7592779a9d7f88aed90360','37322743a70ab7b0bdffeb03b1bf6616ecdda367b8e77c4d0ce9ee1ad1a9c5f8');
INSERT INTO blocks VALUES(310242,'85dda4f2d80069b72728c9e6af187e79f486254666604137533cbfe216c5ea93',310242000,NULL,NULL,'8f3ba5507225c66a9b6b9647f31a32b073ca37f4e5670cf09419e98e28cca497','afe115d3e88d78eb932c3d41e031644ccd0e541207306d1aef83b348d6328f3b','59df112c119cedda1b130e984b0b6d52d5833e53de02f47884ca75f7252d2076');
INSERT INTO blocks VALUES(310243,'a1f51c9370b0c1171b5be282b5b4892000d8e932d5d41963e28e5d55436ba1bd',310243000,NULL,NULL,'ac9e4d69c0aef577638f975b97b2c8e896d2f532c866a4de43f44b4485f2cc3f','3ba2d8f5f4a194c1ce4ec7ac607910d37ed6bbe13e345ee83316262cff979992','f6239961b3c27e254428fb4b5ba1d48c42aea2de6b2baf26ec5765d853fb97dd');
INSERT INTO blocks VALUES(310244,'46e98809a8af5158ede4dfaa5949f5be35578712d59a9f4f1de995a6342c58df',310244000,NULL,NULL,'da0816873e576b81cf91deae0195d3876232de9f5048be3e4ad3fd51ca649521','50d127345c60d6e91c08d715af0f4e2dda00c27f3b2d12652db92ffb9a552d54','710091d55d86a0f67fa24605643ed50d2d770ec1bc6a59cbaac7d01f9ff471d9');
INSERT INTO blocks VALUES(310245,'59f634832088aced78462dd164efd7081148062a63fd5b669af422f4fb55b7ae',310245000,NULL,NULL,'d2e88e67a78d3897c47523bd9f4e9a33a561faf3b20c5b08f49d735d4e053460','b859b60555a759b606183e93777303de7a6f6f436dc58ac2f67d8270b55d2cd9','31bffe85dc5f1c3a00d3ff4c59d5427c4f6cb06b58254b283e71f876b8056288');
INSERT INTO blocks VALUES(310246,'6f3d690448b1bd04aaf01cd2a8e7016d0618a61088f2b226b442360d02b2e4cd',310246000,NULL,NULL,'d6ecc4543bb89cc9b17198e1ec1bda12cd3f79c7662efd230eca089d9e0e64bc','42e2567bf24cbef0c62f912274aae12dd1a18ab36a1bfebd0fb9b929434816b4','34299eaf18f073c89561792d366bf26dd55ecf5763001dd00fc301c0ff992367');
INSERT INTO blocks VALUES(310247,'fce808e867645071dc8c198bc9a3757536948b972292f743b1e14d2d8283ed66',310247000,NULL,NULL,'8455ba326f0e4fcda984cb9f3f35d0211db9f912b7b2362db4212455d89f820d','94fb21cdae1f2a828106be069d11561593765c45a20ce079fac53036c42dfeab','ef1f0589d1740f7a9095d191886644c7e8f487d07f554f7078444947e4a6622e');
INSERT INTO blocks VALUES(310248,'26c05bbcfef8bcd00d0967e804903d340c337b9d9f3a3e3e5a9773363c3e9275',310248000,NULL,NULL,'dfec3b1b3d3b32d6c2df2810d2b3598b5ba398a5b2a04274be4675d8156ad57e','f70991efe6cf0eda7f382e87c0fa700356ea8871b881cfab120848eebe7382b3','a8e977e7728a04d77d0efd3f2566250f68a0ffece9f67dce0997e3585d632f87');
INSERT INTO blocks VALUES(310249,'93f5a32167b07030d75400af321ca5009a2cf9fce0e97ea763b92593b8133617',310249000,NULL,NULL,'7d6ed27a9f5a68a3fd93e60b52638ceac7dbc7396908cba3763040570ec37f66','bb581940c79c3f1ffb64192fd976526ab8de0fab7dd81e085c75382c90b2a017','8589c90a5e9b8c48eb306206dc55868559bd483ba7f288dc8dd89ad5172ea94a');
INSERT INTO blocks VALUES(310250,'4364d780ef6a5e11c1bf2e36374e848dbbd8d041cde763f9a2f3b85f5bb017a2',310250000,NULL,NULL,'44a70fe2a28e0b5051f21925171ebc5d4f007501bc5806263b4c49556dde4bff','7eb40f3df9a77cb9fc8c60041258d0cd98be6b3ddf897820249df2637082d4f3','c69aebbd697dd62cba3c1d7b3dc452a61252520107bcb04d32b551f3f9654a76');
INSERT INTO blocks VALUES(310251,'63a3897d988330d59b8876ff13aa9eac968de3807f1800b343bd246571f0dca7',310251000,NULL,NULL,'5e24a59c70e7e3fb346ebc4b8d7b10d5cd8bfc69c37086b2fcada71b00054006','07bbc5342b9b24a271b164f39914177a345a5bd375ee28cb58b33d10cc8fdffb','71503a1e7ce931123bccf53f9efc9684a197300250bf373dbe23b3419dd0ea96');
INSERT INTO blocks VALUES(310252,'768d65dfb67d6b976279cbfcf5927bb082fad08037bc0c72127fab0ebab7bc43',310252000,NULL,NULL,'0726906153b73645ebdda08dbc1b1951a3f2a44f7df9c411afd0c8e26c67a9ef','bd7f5b3f6a333d5cb08d71404d7310e0e6d5840763a94e9611b8efd74389949b','80f01a6c630a37df7b28cfcb375d44009a7d04191f3824efa63a9bf2256f5cee');
INSERT INTO blocks VALUES(310253,'bc167428ff6b39acf39fa56f5ca83db24493d8dd2ada59b02b45f59a176dbe9e',310253000,NULL,NULL,'e47aee44802f13aa6abc7fd1f62ff7cd6b9afb48fedc04d676fcd8e6eb58c492','feb1a5dfa6344f5de4346f78dff026d3d4c41b49c6fa25e9eca1f51376f9a493','987ee6c3913e3834893f033bee4e79b8c9e9c09a1de3cb4aef42f9a80ef6bcea');
INSERT INTO blocks VALUES(310254,'ebda5a4932d24f6cf250ffbb9232913ae47af84d0f0317c12ae6506c05db26e0',310254000,NULL,NULL,'50defce7d80b36ec9a94634061c3a1f80a4cc5db37e79cb142396e2597dbaf5a','21cad9e60eddbcaee197407651d91c347819009947cfe1bd3e3ba46589da29b8','e74f8c23c802609f7e3c8f66c830142938cfc68efafaecb2e663f8a59e524c49');
INSERT INTO blocks VALUES(310255,'cf36803c1789a98e8524f7bcaff084101d4bc98593ef3c9b9ad1a75d2961f8f4',310255000,NULL,NULL,'78c9f13a386a45570f721657cb94d4f1bf7f931187b920f564a4591e14552c4a','982cd52d7fc9b9c20cfa89871d823d04a90dba88fca5aba57a8196f23c95fccd','13b75ba0f70c5d9930553a4839d657d9e1259f7503e8453fbaf2c3859c34551c');
INSERT INTO blocks VALUES(310256,'d0b4cf4e77cbbaee784767f3c75675ab1bf50e733db73fa337aa20edefdd5619',310256000,NULL,NULL,'1f1c23e38a6c210f982a3ae712db3158c48abeb88512817ad7f1c2dfed752f38','b2a235c365e5c4bfdb620944ba2330c9afe5d736b35f9fbe795e60ef15202775','82314d2bd03106ce80784757615c1ac986bfa3e781d1da494723ccc5d3f3ef05');
INSERT INTO blocks VALUES(310257,'0f42e304acaa582130b496647aa41dcb6b76b5700f7c43dd74b8275c35565f34',310257000,NULL,NULL,'4b8bf73c34103892fcc3b23d2e03b32e1d608cb6992b313d0015f06dee592aaf','e654a71ab4baed938b575db7e7eaa889e5a345a3fccac6bce3bab4bdde569f71','31b40c608616164475bf45bfbbc70bf55e26db371aea17e3a6cce6953f39648f');
INSERT INTO blocks VALUES(310258,'3a0156dd7512738a0a7adba8eeac1815fac224f49312f75b19a36afb744c579f',310258000,NULL,NULL,'1a853dbfadeaf50085017bc9435ab7a415c948d2e40089ae46f2b9f76647c89c','fb800740371fd6c4b9ec2402d91f13c1acfcfa89df03e4f4a0f879bda0ca9bd0','3982f168c11aff849a962bb5b91f4c22c17de383f4d18be9a620200a470aa23a');
INSERT INTO blocks VALUES(310259,'e5ed3cdaaf637dd7aa2a7db134253afe716ffdf153e05672df3159b71f8538a9',310259000,NULL,NULL,'2fbe03ab90dc460408d83880684dacb0633e85c8d1559756e6f86ace29cd341d','31d48d1228c07a38bbe65083d84673eea6de1b7b5c8b4b657bb441b33ec0e267','6d694b5325bbeb5a27f3fbcfd284ce00c15090b75c93d23cf7609db0400c6114');
INSERT INTO blocks VALUES(310260,'8717ddcc837032ad1dc0bb148ddc0f6a561ed0d483b81abb0c493c5c82ec33cd',310260000,NULL,NULL,'3ab4122496374a55eff29d2034e1b6b5aed7589ae4c66329f1ca3e0499708590','4e0ae0deecf138dc9fedf2aff02cabaa519cbec33f61def63925764904dd8102','f2b6b28653f5d8dffd087cc7ea9abc185d06505c073a3451fb25b72f46bb510d');
INSERT INTO blocks VALUES(310261,'a2a9d8c28ea41df606e81bf99cddb84b593bf5ed1e68743d38d63a7b49a50232',310261000,NULL,NULL,'6ed574ae0aab6eb3f92a1716afee6ea37ef9e450e7b52d58d4186bb01e2b03b0','3f90660d2fc94e0173a938f3fafe28e7383ec8b4d9a520b0dacca71e852edaef','bcab11156405fbada26d5268a1f96b0600b7015abb5a775dd9a6731f68235cfb');
INSERT INTO blocks VALUES(310262,'e8ebcee80fbf5afb735db18419a68d61a5ffdde1b3f189e51967155c559ee4ce',310262000,NULL,NULL,'0312e3df37033157336d59c30db43a70e5b434a30cc4ed6b67d3e9f2fd2e2b5c','f8a197c3717ed76a7ee7b740499afa701a111d528b8e0b79a735d6ae1a0dc36f','af3eb867ad98d5b23c04f0d7a14159884d844ef726dfb26f1bbef94884caa53c');
INSERT INTO blocks VALUES(310263,'f5a2d8d77ac9aac8f0c9218eecbb814e4dd0032ec764f15c11407072e037b3c2',310263000,NULL,NULL,'9ee568b93b0fd24ca45108a015122532e16c70a387503542bd1cada92c79774f','54247b6929d9781ccf2155ae6648f01caa36f50a3ed447f0ceb4c0c6c0ca551b','9284c69b90e43f18e091ced413a3102457cdaa76f351caf079aa1c4672813243');
INSERT INTO blocks VALUES(310264,'ae968fb818cd631d3e3774d176c24ae6a035de4510b133f0a0dd135dc0ae7416',310264000,NULL,NULL,'aee48cdffbb6e982416782e96576e3746b609583e841d5d6c4e148b168aa9d58','3478331fe83cade51bff3ed63c3ec00dac000d168b6d7765e6f9698fc981300a','477c659765cc893bad0d3faffd3dfcf4e3fab0e8aa76a9db602136c6b042be52');
INSERT INTO blocks VALUES(310265,'41b50a1dfd10119afd4f288c89aad1257b22471a7d2177facb328157ed6346a1',310265000,NULL,NULL,'d19a7116623c82ffa1f9b275bf4e69d555592e1fd7463fa8480ad5d801e59674','97874c86218fda4ac84148dab6ca0511e50b6a3b40fe2f5dc6b5287b9ee03dad','e9e3fadea7e27069ce862a53a6cddafb565b7d20d370182807767942de81bb02');
INSERT INTO blocks VALUES(310266,'1c7c8fa2dc51e8f3cecd776435e68c10d0da238032ebba29cbd4e18b6c299431',310266000,NULL,NULL,'17f1b1bc913b14498f44ed71b99655eaa32ebb2d66cef20b83882e03f3d141e9','1427d2fefc98065d654027a8ea251c7a504d90c76470b2c3a1f79551e2703cd8','42a924171c096f58a12b2b5d529050e07e459d871bf89e402c5c1913725bfdcb');
INSERT INTO blocks VALUES(310267,'c0aa0f7d4b7bb6842bf9f86f1ff7f028831ee7e7e2d7e495cc85623e5ad39199',310267000,NULL,NULL,'cd2fbf09940b76f1e65dd646130b1908f19cb9858eea8ebda8caaa3bce59fe05','1d500f46a6ede3739d6e6ff433ca0114c4b0e9aa746ee9fe17441253831b0826','a12cb76d092ad78457145db48eade608b93a2d3dbf75ebaa7f7d0ff1d94ab3e9');
INSERT INTO blocks VALUES(310268,'b476840cc1ce090f6cf61d31a01807864e0a18dc117d60793d34df4f748189af',310268000,NULL,NULL,'4fa8d6ef979a8ea410b174029d0e2e2482e82fd9d19f5b43cb541adf47f061bc','7c41703c349251a9ab1898961997d4f198602bc61401b42520da6b092b5a50e0','da6e7d62ea848b4cbbef4ccec2103e6445e4621aa77e1ee90b3187441a1abd43');
INSERT INTO blocks VALUES(310269,'37460a2ed5ecbad3303fd73e0d9a0b7ba1ab91b552a022d5f300b4da1b14e21e',310269000,NULL,NULL,'e5f99ba407163e760c55c0ac5682ec2d62df829ed375fe19f98789dde73f4893','699f45c22b8e84247ae2724d3fb04a4455fb4ad4dd0e1f60c5fd0a37d63cae24','76839a0c822d3ecdf86cf919eab05e9fc43bac4cc3a830bf43d20084889417db');
INSERT INTO blocks VALUES(310270,'a534f448972c42450ad7b7a7b91a084cf1e9ad08863107ef5abc2b2b4997395d',310270000,NULL,NULL,'dd8f950db5a330ddb1acc8703749d03a5f70a0d63d82f2a6557ce23076ccf776','90d6ad75961dd0c85b08ed7d86ce5120b09ef6f722743eb6644d7f536b27497b','146cec25ae98161dbe98fee64adf3d063d48724cb20c6e1c438e2be7df57abe8');
INSERT INTO blocks VALUES(310271,'67e6efb2226a2489d4c1d7fd5dd4c38531aca8e3d687062d2274aa5348363b0b',310271000,NULL,NULL,'f6151034f9eb354f80314238fa5e3a4992e66b6a1cad72534655267daeb15d48','d3804a8ea367d5dbd130008d5bf77795f3c5977322206b247ce0bb55b47e59df','881d5fe2806e198f22db813037f1d843c70aa797ee0ced0eda868904f90f56a6');
INSERT INTO blocks VALUES(310272,'6015ede3e28e642cbcf60bc8d397d066316935adbce5d27673ea95e8c7b78eea',310272000,NULL,NULL,'73c45a2aec0336ae748c65c2f33c66bce579e83e587e287330c2e2dad492468d','9807a7f63d810100ec13723b67eb588360407cc25944013b55c4188f52a7a6cb','0f9c804e51815149ed8251c2f163e36fe50db5ef66afeaf70445e0da1bf27624');
INSERT INTO blocks VALUES(310273,'625dad04c47f3f1d7f0794fe98d80122c7621284d0c3cf4a110a2e4f2153c96a',310273000,NULL,NULL,'fc6fc1c397dc150c571c2755bac7308c37a2979a190a36cc5ded35283142474a','ef04755a3960923564f530bcc696487a8ab102fd7c480765c228b03a30eb0546','bda678ce3dfb09c9ee8652af9982dd4d76a530e94cd45e11f5ef50b9c608b1fa');
INSERT INTO blocks VALUES(310274,'925266253df52bed8dc44148f22bbd85648840f83baee19a9c1ab0a4ce8003b6',310274000,NULL,NULL,'5d1e9c31260431e19eaf8393144c00d759cdc5d0fa29219c8741b30bcb6ebed3','528269894ab6f9622d7ab3d9326be95815ce51e2371add7267bbcbd8a533f3e4','ddce11616460f6b9639d07c4c3176f061ae2a9e5a01ecfc73083be86abd5e868');
INSERT INTO blocks VALUES(310275,'85adc228e31fb99c910e291e36e3c6eafdfd7dcaebf5609a6e017269a6c705c9',310275000,NULL,NULL,'7af07336986c7943ba29d0468a38039c3d0b20957b72a77ce9596d922e974933','0b996623166203c58d4111ddfe171920e34423828e7ec1867f4e5f406875f109','9838ef38998b394393f400e22baad421a43eeeceaf428e58c1ac683d24646f79');
INSERT INTO blocks VALUES(310276,'ba172f268e6d1a966075623814c8403796b4eab22ef9885345c7b59ab973cc77',310276000,NULL,NULL,'c106a2cd7f1f0ee7d23baa36fda5ae469fa3ee2463da98a3073b8650a0970173','b93270ef182e2b74ed7b012c0ee4c62c2118e06860a5344c098ed72d08a46b94','187c817dca7c05a5d3d84f02fbd67d2ca1951d2654f6df20a3369a62149ef659');
INSERT INTO blocks VALUES(310277,'c74bd3d505a05204eb020119b72a291a2684f5a849682632e4f24b73e9524f93',310277000,NULL,NULL,'cf49e13ef3169beeb341c9a31f6032ed205c2f9ab40e43c01ca0ed582861df24','f27742403acb643d20f85257f8a23ff07b10cc6b29be1fa1511a73d0a0ce20a4','5af4d2fcc9d8e9cb18a3fdd9b0586110ebf38be3e3eb4bbfea06c27915f9bb4f');
INSERT INTO blocks VALUES(310278,'7945512bca68961325e5e1054df4d02ee87a0bc60ac4e1306be3d95479bada05',310278000,NULL,NULL,'7d20ec29ee1a9294f27c29d9c933add6de266779425169f74432b6f954f2b765','94da6da72dd0b948593566679b2590bb4c62d128f1c41de8a82d84006b388424','5341e83c3cee3f2eb2ff089538598fa42ffca23c177c35f2059dd41bb1fb6375');
INSERT INTO blocks VALUES(310279,'1a9417f9adc7551b82a8c9e1e79c0639476ed9329e0233e7f0d6499618d04b4f',310279000,NULL,NULL,'14613ebc4f0d4140a1e594d32986e825cb57d273345cb2cf3cef39765a4e5d2a','42f7a2fe8a11137736ce854322e423598297467bcd67994c39c7bbd30200be07','8d3e526af131f52fdb16f253e2d4bc3ab9649257b7ba5c1e59240a6127a0f558');
INSERT INTO blocks VALUES(310280,'bf2195835108e32903e4b57c8dd7e25b4d15dd96b4b000d3dbb62f609f800142',310280000,NULL,NULL,'eedef4534d5d4f9cf41f5c778a8ad29bee69f0f0b24743a39ba6f8344589359d','3cfd1f536e789105a352d3fb2355f62a2208384ceb02108115dbe5731d4b4f09','ed0bfdde58b3ad5659a2822e3b54df4f8a1ecd7a855b3b41e6a0c729c6b7a1e7');
INSERT INTO blocks VALUES(310281,'4499b9f7e17fc1ecc7dc54c0c77e57f3dc2c9ea55593361acbea0e456be8830f',310281000,NULL,NULL,'69bfbefc33d2e86d3d82df7a5a1f7711858f93538c9984583a99553fe5ee17ce','020b2010e2447e7296518c17f9af29011a5845c9de1933034bdbc6c1f1a5bdb6','50e80ba123152f52701b9cfd860545eae081740efdb6c9a523d66765602c918c');
INSERT INTO blocks VALUES(310282,'51a29336aa32e5b121b40d4eba0beb0fd337c9f622dacb50372990e5f5134e6f',310282000,NULL,NULL,'e16114c54d765521022a80105caa0b8be117fc5b9d36c254b8b925ae69f94d61','81d46b129b7e4baf4efd3b916e0d9630694934e3b18c30785ca01471c9fa0d5e','72d0594c993093b9bba7fd78fd7d23e46aaa7e1ae7346cc3ec9ff8e2258e164d');
INSERT INTO blocks VALUES(310283,'df8565428e67e93a62147b440477386758da778364deb9fd0c81496e0321cf49',310283000,NULL,NULL,'8bdcf055f1f77f121ff35d2b1e43886e6ea0ec2e42b29649da7b6366494a3e69','b5ee5ad6f93e1c97ab8000e75d220d9ee809675995d2776d146e161d2ce809e1','6d869689aec1bad4c5267de511daa6625abedb6d31b1e39486b5a55df44381f6');
INSERT INTO blocks VALUES(310284,'f9d05d83d3fa7bb3f3c79b8c554301d20f12fbb953f82616ac4aad6e6cc0abe7',310284000,NULL,NULL,'8b6831c3df9bffa272eeeac93ea367cf14c3442f34acd86397de7898112118fd','ba0d5bf325f446a6d45e63fde928b2cff2c36d53e9f6e76d6f65416239420cf3','4a221fb1de35754a732eaccfb6aa96c57bd9cc87c991327cca69f6319a597890');
INSERT INTO blocks VALUES(310285,'8cef48dbc69cd0a07a5acd4f4190aa199ebce996c47e24ecc44f17de5e3c285a',310285000,NULL,NULL,'138444888d3a790c8a0111da680243218301f1497e6df8f55fb484522ea82f2b','870a5b76f54d8ac924edbb69a9eed837f63f7672213b973c92c7e871bb6e0d5d','5720c1d8bdbb7349f551decc535a0a7222379c903d29f6a4aebf3d75c9a2738c');
INSERT INTO blocks VALUES(310286,'d4e01fb028cc6f37497f2231ebf6c00125b12e5353e65bdbf5b2ce40691d47d0',310286000,NULL,NULL,'87a28e638377e98f07f5006a3068c754a7e5a6ad6bf0b01660e68c37f5dd167e','c4a406e6e71205b07ef13a1137e5d18e074eececa4db2a317408969088c3b1c9','a10df076cef46f7c5b945144276f71a4bb9428d4331358096503b1750d93ea19');
INSERT INTO blocks VALUES(310287,'a78514aa15a5096e4d4af3755e090390727cfa628168f1d35e8ac1d179fb51f4',310287000,NULL,NULL,'c0e5a0b5a766b6492568db8ee5efb28d9eecac3923c049871785355a1ab66bc0','d6ad8972c4cf402725e053fc0eeb1c3dbcd6d305973148cbec6164c3aece2bf1','392c60f277bc7386aefadeac6c2f964ac3c79e33d755b2cbb4f60a8628db367b');
INSERT INTO blocks VALUES(310288,'2a5c5b3406a944a9ae2615f97064de9af5da07b0258d58c1d6949e95501249e7',310288000,NULL,NULL,'419f92c8bb6e5be33f8340f32380d6877b1f270fd8660814b00e5250b79bcbde','bba8c977c4c8b016c63d390b6ed878fe86d23e0ef01dc53f7501b1e71d23ed38','1788a32e1f23bc670638291a639a2eb951b0ddd1348c6583fa76414184a0c30c');
INSERT INTO blocks VALUES(310289,'dda3dc28762969f5b068768d52ddf73f04674ffeddb1cc4f6a684961ecca8f75',310289000,NULL,NULL,'f8dd8e467e0b2f3bc9705dac300ebbd69f32a115ee7a3506aac2578b9ef409f3','b2be10a80578933d0d55a231c5902323de4649a26a8c156a6a7b635ee0faa449','a34356bc6ce414ee199c46a5fba4992525db4abe7b4dd1395a4eb9743cedbddc');
INSERT INTO blocks VALUES(310290,'fe962fe98ce9f3ee1ed1e71dbffce93735d8004e7a9b95804fb456f18501a370',310290000,NULL,NULL,'7a0f8e32e857c99feb715b1f610cead2a3aa5e9d9d2e0859650891f8a69efedb','e9b42ecac581f8b95dab910dff387ac328dac8b07438e95d5490015ca919bc34','8b862175e50b184bce5a28e35238590dfb802710bb09fccbdab9bb490135979d');
INSERT INTO blocks VALUES(310291,'1eeb72097fd0bce4c2377160926b25bf8166dfd6e99402570bf506e153e25aa2',310291000,NULL,NULL,'53fc536ac789417c95cb020164592982b239b793ce70a93888243b6bf73fdb95','d9812f807d99f8510cdc5b1c7819b1520cc8d492944547c15ecc50ce61821a33','44163359d092e27c5be559453c3583543303111d917e7b8fa36bb153a9953cfa');
INSERT INTO blocks VALUES(310292,'9c87d12effe7e07dcaf3f71074c0a4f9f8a23c2ed49bf2634dc83e286ba3131d',310292000,NULL,NULL,'2d901c6f9fae51da0f46ca466c8811500738a8e88edbf4e24281d4f76b8d3f02','22397d93d2047c08ac3dba77d427c7a46ad04b2220b27b9414ce7649d91edf3e','1191b35f037389c0d6fb0ff1877ebf3393dd2f36f3468baedd283e2779f413ab');
INSERT INTO blocks VALUES(310293,'bc18127444c7aebf0cdc5d9d30a3108b25dd3f29bf28d904176c986fa5433712',310293000,NULL,NULL,'98c7a9bfdbd877b8fb2a055dcdc16da3b9391ad2fcbc5d6f0636d6f3dc3cd4a3','8bd8ab5aeb3286292cd41e33f8ec888455f96fa60f1aabcab5fd907136972e2d','551e7fbdc199fec1f33a084c8b9444ea7af39309b5f550a6ef3b31d613ec64f0');
INSERT INTO blocks VALUES(310294,'4d6ee08b06c8a11b88877b941282dc679e83712880591213fb51c2bf1838cd4d',310294000,NULL,NULL,'1b0954a46412d817b912e9d03c4cf97b01b2a1795502617761257d26b7988102','cccb8542602ad01c97d934c8c5bcda1d13f765b49f5015a57d76cb559a4d0ee3','73235541e274d4cc9b04c4ac42fb05fdb33a671c9ec5e29afe62ae03026eb9b5');
INSERT INTO blocks VALUES(310295,'66b8b169b98858de4ceefcb4cbf3a89383e72180a86aeb2694d4f3467a654a53',310295000,NULL,NULL,'964ae66af8efc956698cb9c91027d06129910cb7784df4b8c407c241401da437','973b826492434f49c6a2ff29d67d3b282c1f0874931bbd474bac8b165efcbc9d','ee193ff34a1860d15c3ba9cc18ea65fad61bb7b492812751b3ce54f3bcf03be7');
INSERT INTO blocks VALUES(310296,'75ceb8b7377c650147612384601cf512e27db7b70503d816b392b941531b5916',310296000,NULL,NULL,'7579d0e8a24edee123a95c97e2f079c6d115123568854f58a8cb9ec3881ac86f','e6378e4adeb53e751fa692100913962af592fd045acf52afd7ccba3e51ee0d28','4f1525b3327017eaad915f2c8908169ffc39675e8c3aec40bdf0ce76e9d95665');
INSERT INTO blocks VALUES(310297,'d8ccb0c27b1ee885d882ab6314a294b2fb13068b877e35539a51caa46171b650',310297000,NULL,NULL,'1cd152e5d90c17d782243a4b5690c6997ebdd18fffda0de838d2b2153f9fefd6','73eb76c842c26d3f86fa8278a833254ce9c21d29cd320caa91e1dd62ee99d65a','2f36877a00a84e537c2786e275f20f4f344b44b5947b11d78feb2eca16828b2b');
INSERT INTO blocks VALUES(310298,'8ca08f7c45e9de5dfc053183c3ee5fadfb1a85c9e5ca2570e2480ef05175547a',310298000,NULL,NULL,'9a16c344e1fc032d12eac114e4afa6fa20945601adbc03ebe89e23846eb98a80','66331cc733b5cd9a58b49e0677d2dbc40a3267dedb12316b5bb0794c672e3df2','32ed810deb73e43ee97491a55ddcd46d8f9f30b7e6e20fbbd1e7ef9ebb346fe3');
INSERT INTO blocks VALUES(310299,'a1cdac6a49a5b71bf5802df800a97310bbf964d53e6464563e5490a0b6fef5e9',310299000,NULL,NULL,'76c5103eabac42741d5cd208f6462e5a32d5238ad13136e226309248371119b6','78b75d69d922fc76e3f68c8769e887bce3a7052230a24c6d639c3ec4302e19dd','333dfb65d005a12f30e19d3e94f70ffecc3539466c54fe75433af54218c1b32b');
INSERT INTO blocks VALUES(310300,'395b0b4d289c02416af743d28fb7516486dea87844309ebef2663dc21b76dcb2',310300000,NULL,NULL,'601a8f873f583291fa78e692e7629a1a28e275ec7c8efb99a0fa056ca412b0f5','1e1fe75bddced1785c34f7c5d6ae21b69e0908bcf64e4a9c6f4c35f180dc6e2e','b9ae2c4d5d348ba4c992b050c8efcb2639b009dfb585157504decb0f0a1f3c94');
INSERT INTO blocks VALUES(310301,'52f13163068f40428b55ccb8496653d0e63e3217ce1dbea8deda8407b7810e8a',310301000,NULL,NULL,'25b262d2b2f14247c97db672a800973ab642e7fc6a2e827e5309820eaf70bf87','a58df4de0c6cb858784e2a5d6d657edfa13895236ba83c8be8d7cc3fca05983f','f60255d4d6607d6b9a15869d48e9200a4c727df1905dc4ac8898379869285703');
INSERT INTO blocks VALUES(310302,'ca03ebc1453dbb1b52c8cc1bc6b343d76ef4c1eaac321a0837c6028384b8d5aa',310302000,NULL,NULL,'a6e23fdfab6adb4e9c0493611b53182f1b7843adbe486df9426ff3895128e5e3','f7b5777cf1b41f1f25b70805bcdbba720909babbc86ea43a04f8d64b01dd0ed3','d288c96e00efb532aa5bc1f7954c4825d0fea0f2081f7c4964d28bf43de0996e');
INSERT INTO blocks VALUES(310303,'d4e6600c553f0f1e3c3af36dd9573352a25033920d7b1e9912e7daae3058dcca',310303000,NULL,NULL,'b6696821e957a4170b8cea8267b43fdee97c11f5caa8b462ba5f6b470ea08685','d3c109c34ba907b4ab96fe65e8ec6b2009ec41fb43d5716a1a1e97eebaacf3e3','875016552eec4b64b726f0ea5dd4209da6ddf8167c4ec1987ce2a500b0dd2130');
INSERT INTO blocks VALUES(310304,'b698b0c6cb64ca397b3616ce0c4297ca94b20a5332dcc2e2b85d43f5b69a4f1c',310304000,NULL,NULL,'b43e0464bfeccfc51de0165f337c347884903fae6907987b12fec15d74519029','541652eb22c9244529a018f4b48bb06472b128ba8201b1f40c8e4159c8a38185','833485f72f4a82a5203228092ab8e849f43e5c2c3e234bcf0029575e13256a95');
INSERT INTO blocks VALUES(310305,'cfba0521675f1e08aef4ecdbc2848fe031e47f8b41014bcd4b5934c1aa483c5b',310305000,NULL,NULL,'c625d1127221a5d6a68d3a3a0dabb0b7852c7cc79244baf309881e11cb2e12f8','15a34656d276b7978015816255fcbd5d78fcf47b5be0bf838d75049e97c9f7bd','da8f90b2e4a1d5678548f071162649a69c66b897053345ccfcad94608c6cf3de');
INSERT INTO blocks VALUES(310306,'a88a07c577a6f2f137f686036411a866cae27ff8af4e1dfb8290606780ec722a',310306000,NULL,NULL,'654e82984746411ef7eecda06d212f9b24ed5bf8727f36e4c3a264daaa9a206b','2b6bd08e7844a16546777a6b414281b6943e6d2d19ea9e236b1111863df5510a','822a7b223118b05695f1a3605afe7c124ef6e52cd56719a0092f2f5a457d2f98');
INSERT INTO blocks VALUES(310307,'bc5ccf771903eb94e336daf54b134459e1f9dd4465dec9eaa66a8ee0e76d426c',310307000,NULL,NULL,'265eeb3ab71d92f2ec88335f045164f7da10305c688d9e0ec7ce969317aced7b','14d644f240670db87ed30c33a2630337c839f18970663568c33f96b5d8bb0262','00d89bbfa238e844d347680358b1ef254dc2c4ed64acacdcfc87b0fa7ca4af62');
INSERT INTO blocks VALUES(310308,'2291ffd9650760ff861660a70403252d078c677bb037a38e9d4a506b10ee2a30',310308000,NULL,NULL,'c6bcc6e98db48cd1ca8d05fd70baf328d9e2c94a6e80d6623398fee16eea75c5','887821f63fe37c52df2ee3306e933257d6288674738c7e716c4feca41f48713a','ab16af9d9890ee54d401e4665a83c23873b638b23086211ea5c2659142b74b65');
INSERT INTO blocks VALUES(310309,'ca3ca8819aa3e5fc4238d80e5f06f74ca0c0980adbbf5e2be0076243e7731737',310309000,NULL,NULL,'2244d53f414d83fcdfc7138c7445f0fa287b529ace102a4f85e92c729f63c2cb','e374e983d813bcfa56b7913dd15efd3453de5ad7962bd9cf28e718ad57bd35e8','8912143e7d067bb1286feab8d40614298295f5651133af388e73bf856f7e6ef0');
INSERT INTO blocks VALUES(310310,'07cd7252e3e172168e33a1265b396c3708ae43b761d02448add81e476b1bcb2c',310310000,NULL,NULL,'63a8d8319641ceaff607e2b9b31086d3f7a8ee2ec0d0e0676f6952f9c01422a1','cac51e91acc8a224586bb4c9564b2c57831d164cc33095957607cf28e79a455c','5d243b1f0d6134ee85b73ac5fc5b4c1e81af7c5712b76d69c2005518a612bf8d');
INSERT INTO blocks VALUES(310311,'2842937eabfdd890e3f233d11c030bed6144b884d3a9029cd2252126221caf36',310311000,NULL,NULL,'c838121678e2cc8370883197385af029a32079cbd6ae09caf2206882612571ed','206088a8e32756433d38575f8569bb2b88db874827c891fce00caea00a43bc3e','b905ff01b463090ad194ac235becbcb8ab6e8678a8b5e3e0480b47ba7fecdc7a');
INSERT INTO blocks VALUES(310312,'8168511cdfdc0018672bf22f3c6808af709430dd0757609abe10fcd0c3aabfd7',310312000,NULL,NULL,'50376c3ecb12be6400457536d89978fdf11db0f5ab3884cae997b433b88e313b','9b052b607a03f3f7eb08aa39b2843d6eeba7892355d5bb484256a93dd7693f4e','60e9b603c8a697d2b81563c542288bfbc295511f0f05b2b5cf8a626e9c4e98b1');
INSERT INTO blocks VALUES(310313,'7c1b734c019c4f3e27e8d5cbee28e64aa6c66bb041d2a450e03537e3fac8e7e5',310313000,NULL,NULL,'667e05407638c94b1f5b316089064b57d6d6f41767d93c3e1e04b27fc0f480bb','a74cd7b85a99109695a7a37e2b98acaa3d29d1e49f70d87c7b20821aa2e77499','e4df33de4a8be25e21757526b41c793e595165a30a96043d7d9dd6664378de58');
INSERT INTO blocks VALUES(310314,'1ce78314eee22e87ccae74ff129b1803115a953426a5b807f2c55fb10fb63dc8',310314000,NULL,NULL,'f0c4d4ebd14beb1f9a4e15a1b74057e451d5c59d4b84a6dc22b075f6fc617207','98717f163cb7d3b537c6b9c4195df9f87d813ebdcc4ec18f1154571538c40343','353569343915364dabd13b2a1d134e39d027265b22fe60092721df039e5d929b');
INSERT INTO blocks VALUES(310315,'bd356b1bce263f7933fb4b64cf8298d2f085ca1480975d6346a8f5dab0db72cb',310315000,NULL,NULL,'fcc454d39d2174817578a1fca23839ceda6ea6dfcf08b4527f6d3416e0a84ab0','e41a699fb72a6c7f87a93a5603bcdba49ad244cbf77ebea548c25592fc90dff1','54853d2f31e5c7b3d3f2140082425d6c47fafdc4a956d58cb3b9165f83d2f62c');
INSERT INTO blocks VALUES(310316,'ea9e5e747996c8d8741877afdcf296413126e2b45c693f3abdb602a5dae3fa44',310316000,NULL,NULL,'32b3d37578677708f2ac871893e585f09ad850425f309ebd3137320cec1f8bfa','a664da2718c857f3bf70ae6cce4d6001afa84ef46a2d4ffe1308a37c20f20094','60f1c12be27b93f4fb5eaf4abd6a3548768c24af6a59aeef9c290344fb9dc0a3');
INSERT INTO blocks VALUES(310317,'aa8a533edd243f1484917951e45f0b7681446747cebcc54d43c78eda68134d63',310317000,NULL,NULL,'2a3a19b8439c63d57b5dab2eda2489792bbe096eb335514d79544707e5559273','75bab2485c6e6f88e6355771e73abc7b6223a3f25010387aeda46547e64a2c11','88cc06f3f0ab7dcaf7a7e44e537d1be904eb12c025123c26fddb3cfbbee073c5');
INSERT INTO blocks VALUES(310318,'c1be6c211fbad07a10b96ac7e6850a90c43ba2a38e05d53225d913cc2cf60b03',310318000,NULL,NULL,'41ef4d04d242da584e7e11d1e8faee4dcc7e64855cb7f218e6832a7167d001ef','224d2be21b9aa27d9bf3d84c5ab33bbc204143c8528e015f4b28a924ef801766','8fdcc7d03b613716dcb314ad5704f9024342f97ec70ade84cac27831117d7566');
INSERT INTO blocks VALUES(310319,'f7fc6204a576c37295d0c65aac3d8202db94b6a4fa879fff63510d470dcefa71',310319000,NULL,NULL,'f97f065b733e8fee8f1ea99333e28781039e0734e9ba3669ce515f18f8ddb2e0','7355932ff93c829f8da54305406045226a946ce5265048cf408cbece8096b995','88d177d58c4a2e5d60570ad029b75236d095b3e2e824a9af0690c0100e3518f9');
INSERT INTO blocks VALUES(310320,'fd34ebe6ba298ba423d860a62c566c05372521438150e8341c430116824e7e0b',310320000,NULL,NULL,'09b031505cd0eb21b3885160d872b145006e0b62f4b1c5af42d962775c896385','9dc63f869d0f587b1eb253a3be6a9240dd286dccfbb016a2808da685a7e5eab5','15a20058d912a4b67b642f8e41f3c301075ce0cef856fdd4642856c29cb33f2a');
INSERT INTO blocks VALUES(310321,'f74be89e9ceb0779f3c7f97c34fb97cd7c51942244cbc2018d17a3f423dd3ae5',310321000,NULL,NULL,'dcf127fa38dc283add0578d197b88154e3f7bda1a5f49a61a3568278f16837b4','a7dddb65d8fade906fb1a63be4a13462e478664c06b0db19fa2809cb8230cf51','207e9281555d110edd523e653b11c022d1da7903f34dcf0dd37deefecc4d60b6');
INSERT INTO blocks VALUES(310322,'ce0b1afb355e6fd897e74b556a9441f202e3f2b524d1d88bc54e18f860b57668',310322000,NULL,NULL,'f226ddfcb7f337961c6a808c25ecae33356fd0618a86cdfeb89adbcd8772c02c','509ad6b58186281966821483a734a6dc9429afd6147458cbb67a841a5eef7983','27db3b5361278dd014b597e6c69b809b1df450dfaf5c215d604fe26cc4025bcc');
INSERT INTO blocks VALUES(310323,'df82040c0cbd905e7991a88786090b93606168a7248c8b099d6b9c166c7e80fd',310323000,NULL,NULL,'46bcc12864b8c6f960fb29c0d55a1726e110976b4645a2ad3b44fd67fa499d57','66fcb97a584b432b9818f7af2f53dbe8a2f8c1638232c8de58735d19f6a9a35e','10024c2f83412f50bd8189a7eca7e976552763845778337c05b3a094028978e0');
INSERT INTO blocks VALUES(310324,'367d0ac107cbc7f93857d79e6fa96d47b1c98f88b3fdda97c51f9163e2366826',310324000,NULL,NULL,'3c91eb844b9ab773034ae44efbb4ade527c08b27c36ebcdb565550b127ec67e7','606de20621af7dbd920471c1c0ac93ca44ec0693f936cf776101a0179befc18c','cdaff39abad878a021b8eb78ee849474b007cb1ba27b281a8a9fd1e48cb8b4ae');
INSERT INTO blocks VALUES(310325,'60d50997f57a876b2f9291e1ae19c776df95b2e46c14fe6574fb0e4ce8021eac',310325000,NULL,NULL,'382804948f84cbbdb8daafa47b2d44e5df3024e99530c0dd9df73d045373e9fc','ad7bb720d08f14cd817b97c805242cd2f3e1862ca4b4f3292e9034d9e0e83a30','bac30f471bac449b75c6bd15699706c108420b90f6864c0efb10dc18bf63373d');
INSERT INTO blocks VALUES(310326,'d6f210a1617e1a8eb819fc0e9ef06bd135e15ae65af407e7413f0901f5996573',310326000,NULL,NULL,'9304789811891a30684635b90edc511a3bbeb3d9f079db4a3b3f18ae2316ef8f','1af0a1b4a70ef4f410667d357fd7257c3d320a4f4bac47b3cbd84833089b14e5','b50d0a79220cf4a3b8b9509c002ca9b3e781120e406eefe88b5e8738a2251c78');
INSERT INTO blocks VALUES(310327,'9fa4076881b482d234c2085a93526b057ead3c73a6e73c1ed1cdee1a59af8adc',310327000,NULL,NULL,'8cf48ac0eedf9f9a0fd8cd23fabc82ce3ff1224f541cde17af2301c5c115ecab','8814aededecc789fb93935a1fc104816864db06caee027eb3c5f7cfcdbb0ffa6','3a6148ac7d68bebe58ed17c070143b40151b840479fed148e99b1e159504df1c');
INSERT INTO blocks VALUES(310328,'c7ffd388714d8d0fc77e92d05145e6845c72e6bfd32aeb61845515eca2fa2daf',310328000,NULL,NULL,'10b597a4c8a636e7c845b531c383509100219f66480bbb8001d7c95fb7b0948c','dd57c73d81f6905c929a55d44614c54ddffc6f616941fa1c34196af6224da37b','588bba94628f512553afcc6a588cc53561ff10dfa815b1fe08ee9bf30a280258');
INSERT INTO blocks VALUES(310329,'67fb2e77f8d77924c877a58c1af13e1e16b9df425340ed30e9816a9553fd5a30',310329000,NULL,NULL,'f3af005b4e410ef1bfa50125e1df1c6b9e6a093f2716e40db5b3adf7139c4d13','67a3ba078488cf6931e83e46502261ee30e265cd04319653b9a775b7f7438cf2','dae5bf7a3d2d118cd20521513fab9a91c14160182fb880d334694721acd170cd');
INSERT INTO blocks VALUES(310330,'b62c222ad5a41084eb4d779e36f635c922ff8fe275df41a9259f9a54b9adcc0c',310330000,NULL,NULL,'c1c66320dfa965e11055f2aab6840e9d73112b4804e9d3df72b4c9640a869692','b9868356d9c7c2a38aad1d69f9cea6807f502cc349d5e24460cb67ab8d55a89a','b840f496b467889d347ec875ea79c686e39f3bcc584df0435bd1e7a79e2109ca');
INSERT INTO blocks VALUES(310331,'52fb4d803a141f02b12a603244801e2e555a2dffb13a76c93f9ce13f9cf9b21e',310331000,NULL,NULL,'e1b4fb775bc25a8b127372259ce8ec350de454c3804ada9941ae0ee1d8373bdf','7526acd6a36380028f065df3ff11b0de6c3c2b8aa088c77c6d95a201e504628c','dafdc97a929b8a7f8f9e8b10d7d285e4f59752b9ec6aa139d9ff51389b1f777a');
INSERT INTO blocks VALUES(310332,'201086b0aab856c8b9c7b57d40762e907746fea722dbed8efb518f4bfd0dfdf2',310332000,NULL,NULL,'9e7275f9676c02b158200cb06b6b3db0813a8b0f9fb7252665e0f84fce50554b','943ff230f175677bce18cfc29b945d64e81afd9392be10fb966fe551e9985ba9','712b83109101e97f5e512a7d51c940795936c5a36fc5209a94e715f7fde56d82');
INSERT INTO blocks VALUES(310333,'b7476114e72d4a38d0bebb0b388444619c6f1b62f97b598fed2e1ec7cd08ee82',310333000,NULL,NULL,'4ce1f3d01cc6861041bd5be38682925bed4dfa544fc85eca7ee4c536de74b12a','1b674034e37704179944655d1f3fb5bf8fdeca0cb586f1a482aaff7b54d45469','85337a7d63c93dc738e98fffb012a8e3ac1f38b0ffcf63fbffd7244b0616072b');
INSERT INTO blocks VALUES(310334,'a39eb839c62b127287ea01dd087b2fc3ad59107ef012decae298e40c1dec52cd',310334000,NULL,NULL,'6c3f3b7d691f610356452a43715db49f7e41cf3b1e8365abe7563d57ed347af6','474d9f3501e27067d04b16c0187d9000996e9e69a0bf18cc11e12156f6f7d102','650340030e7a48bacd234a8ff98780096fdc9e39482b023f677274a030ef8c44');
INSERT INTO blocks VALUES(310335,'23bd6092da66032357b13b95206e6527a8d22e6637a097d696d7a96c8858cc89',310335000,NULL,NULL,'83600789523495cdac6706a481e2dbcd1a56a58171917f97d88bb0cd81fe695f','08257b39afe8f1ccdd037800afffcf98a78e65e9d7d39d94f4da6d1303b20f43','01e8c16b1151bdfa366deeae4fc0a45ac410c83474325d9e681be4baa8b48b81');
INSERT INTO blocks VALUES(310336,'ec4b8d0968dbae28789be96ffa5a7e27c3846064683acd7c3eb86f1f0cc58199',310336000,NULL,NULL,'7e41a6d9a1565af5053c2fc4285144fc4f4c0c9ebe6e34e77d300b1fb82a8188','7a170ccf1ccd42a7a6dac9294205d1ed986a9bda094a4667ad38587f82b4ac76','0a39187f972769b585768a8db7dc514b3036f7df23e5f2a9b26ef70f63794c63');
INSERT INTO blocks VALUES(310337,'055247d24ba9860eb2eadf9ec7ea966b86794a0e3727e6ffbcba0af38f2bc34a',310337000,NULL,NULL,'d3bb0fa088463f81de8910843fd4dd1f35738a6c7868d36586c95e5a358bff7a','2dd3a7255a9585fb6639429723bae36fc120ee7276a82e9d556715c8758cad79','c5b2738cc1b620f1839f5b799450c581ad72e801ada74700046397e1a39995a4');
INSERT INTO blocks VALUES(310338,'97944272a7e86b716c6587d0da0d2094b6f7e29714daa00fec8677205a049bcd',310338000,NULL,NULL,'54f47078effb357fc12d74f8c50abecb0b18c3b6f870e98ebd006f771cf423dd','378e3f274b823c4c27a78b19cfa1cb183129eadc01dae1f917cd8c66b1be9613','0e1fe8edfa07df49fbd18c41037de8bda213d37fd35abba662a144f307393e84');
INSERT INTO blocks VALUES(310339,'99d59ea38842e00c8ba156276582ff67c5fc8c3d3c6929246623d8f51239a052',310339000,NULL,NULL,'ef3ec8d6b6de55aaf7a71820b7758942506b4d1517028f01c6cc48bc79ebffab','acb2dbebbb82c2e7035de2fa6b0f5a0cd5b40f9e341179baf08aa40fe8a82ed1','891b54b5fddc19083ad0f1b61bf5477426c03e7d505909258b9b36c33ead9642');
INSERT INTO blocks VALUES(310340,'f7a193f14949aaae1167aebf7a6814c44712d2b19f6bf802e72be5f97dd7f5a0',310340000,NULL,NULL,'f0ec836af61aa31b4c2dd1c1125769954fcfe684456e44cf75e63ce16677ff38','33ba0a618921bc6ec698e67bd69be36851a6bbe73d5c8f0dcc7020b033c6fa47','9ed90fdc539408cc0f0ca2e5f61d5fb1ba462234f28e560ad6960ddc359aa38a');
INSERT INTO blocks VALUES(310341,'6c468431e0169b7df175afd661bc21a66f6b4353160f7a6c9df513a6b1788a7f',310341000,NULL,NULL,'693c0ba212e3c11c56a548aca5fdab6b3696b0ea563126b7faeec4ac239c2b33','eec37062289ae01b5c58b051ff63ef8bbf19fd6afe22eefd9b7240071a11da8c','75e17050481d1524e70aaee5ab94eec161480898db18e3c0c60958fcd09c9fe3');
INSERT INTO blocks VALUES(310342,'48669c2cb8e6bf2ca7f8e4846816d35396cbc88c349a8d1318ded0598a30edf7',310342000,NULL,NULL,'9046770afa96e961ffd7097d93614bfdddd32e6de318966567dbc2cf25ee70a2','5c5223db5c41896b3791f22e97e6463ad3b84963d5a579993c6953562bba5a1b','713c1d477162725845ea6847f8ace50f3d42fd279d9ecba73736fed8b01763cd');
INSERT INTO blocks VALUES(310343,'41a1030c13ae11f5565e0045c73d15edc583a1ff6f3a8f5eac94ffcfaf759e11',310343000,NULL,NULL,'c89e5ac3f607b3ab5b56e96280454f604bac02685dfcdc59dfb965fec30e3d90','eefea2d34663596156c7b454314fdb1721793208756e1ba71208d87fd7226abf','c9960eade07a24bb8732d5cb862972784b60f4bdb601673c2b1f21d4a12324a3');
INSERT INTO blocks VALUES(310344,'97b74842207c7cd27160b23d74d7deb603882e4e5e61e2899c96a39b079b3977',310344000,NULL,NULL,'89bd57ea20751bef74520fdfba10efeadd0619ac963001c86a1a4d65b265cc1a','13a7f35e84ba5b0931fc61b4c87aa533100516d865392a99a3387bdd812e46e8','ca3f184a9378e71fc8a2368dd9a5cb74bd00a01a64bee39071e1cc77a1ac483e');
INSERT INTO blocks VALUES(310345,'0bda7b13d1bc2ba4c3c72e0f27157067677595264d6430038f0b227118de8c65',310345000,NULL,NULL,'6343d3c5cf86648bf1e454c81fb377c4c26e5f2a1f3df5be357b7ea736cee8b0','5bd7833aa29b8308696ee041b7814401e47a25b3d0257306b754959f21739a0f','f33701ce02d8677aa99f49e1ad42acc559acb3917c652818584d6faba049bd2d');
INSERT INTO blocks VALUES(310346,'0635503844de474dd694ecbcfb93e578268f77a80230a29986dfa7eeade15b16',310346000,NULL,NULL,'a68d5a7e0611c0a85dc3e01454072d7a8e3a2f5f09a42922267cd52ddafd07c4','a323436e74132d1011891edeb9afbd63c802987f7aef716b6d4ec268cbca5ab0','e6136779c8407b972e1e28e930a869fd0ee31847ed92ea4a24d1443877822f01');
INSERT INTO blocks VALUES(310347,'f3f6b7e7a27c8da4318f9f2f694f37aaa9255bbdad260cb46f319a4755a1a84d',310347000,NULL,NULL,'8cb8a30bda1c478620459cb80d13fb0cd7d3e006ed691e5ca83a054bbe8b9739','5afd88b073aff87b736915b8414eb9ba8b8fae28c4a199b4414f1bf60c933d60','5a53382f238b3acfa91b59b9c26d2b14444e381b053c08cda65a432f46b85725');
INSERT INTO blocks VALUES(310348,'c912af0d57982701bcda4293ad1ff3456299fd9e4a1da939d8d94bcb86634412',310348000,NULL,NULL,'6a8fffa25469cffdf5794e024b62c0887fb62b894bf33ed057c75a712220ccd7','24ed2d1de0a34cd01df11c1163618967100f6b846c664542d648387ff0d44812','1547ff9758bbea1d68b3c00219f1b8c2aa50d22c3b23790e856843756889616c');
INSERT INTO blocks VALUES(310349,'ca911c788add2e16726f4e194137f595823092482e48ff8dd3bdbe56c203523c',310349000,NULL,NULL,'f807bec9fe03ac49a338816880e83342db4dbdbc8aaf670caaaaa8d62828ff5c','954cfbd234ab93204c5684f3b8a2b78310302f3b4209fe50bcf90d6b228f5512','5e7149f61618b6aa64cb2c3c0dac40a5b6ac971f5fb75ff5dd244e03f4118f55');
INSERT INTO blocks VALUES(310350,'c20d54368c4e558c44e2fbaa0765d3aecc8c9f01d456e3ff219508b5d06bd69d',310350000,NULL,NULL,'54f5c0815e30408b834c4e48923937bf4512540c2b7047166ebaaf42f246b377','9c0e0f8baf6180ad04c8b62ca26f768f6ff0a85a7b64285dd83ceac3c0e7759d','76ce01b3124f5e33afff58ce1efcb628fabf1e93543d50578b1cab4f16108972');
INSERT INTO blocks VALUES(310351,'656bd69a59329dbea94b8b22cfdaaec8de9ab50204868f006494d78e7f88e26f',310351000,NULL,NULL,'a9cb273864fe735f5e3264cb6e50142225b7e7ff2e1d35b8da1410860febeacc','f75c7cfde6735d19ddf9baffd27b9265ab6ae31203e3783c3f3b0e4ab5f3a163','e263ee219e381b6802c1270c5c7f4a17301cd59c60b265cfe7c3acac7e0eaef3');
INSERT INTO blocks VALUES(310352,'fb97d2f766a23acb9644fef833e0257fdb74546e50d9e2303cf88d2e82b71a50',310352000,NULL,NULL,'247770ee363f17202a86f82800eb69980fea529b38859ff361ae8dd4d84dcf13','13b56a7daaae4dc1924808182243f9aa24261fd774a59fe91e727852a25f8517','090fb69690ace9351e7eebb7e7ce330c8697ca403c22247e3a42bd8d07e90e84');
INSERT INTO blocks VALUES(310353,'2d3e451f189fc2f29704b1b09820278dd1eeb347fef11352d7a680c9aecc13b8',310353000,NULL,NULL,'c423be2a59a0828404ee1c50775b97fb4d688443d3a767a6ff3feae25002b175','74317856bff6ab6fbb58772e8049ec95069490ad5b0f0d481d9dbf869b87ce88','b0cfd33fcb36b6612e36085d1a9d1ae71a8104d32f46fe65f5069ed6d9e2a0d2');
INSERT INTO blocks VALUES(310354,'437d9635e1702247e0d9330347cc6e339e3678be89a760ba9bf79dd2cd8803e0',310354000,NULL,NULL,'84045437802e63a041f43444caf0ac43c7fc99605709e8545890d150db0874b9','b4ce2575be83c8e08ca1073d5b26a7615cbd9ebf49b2c145330a3e437e4efd7d','fc988fbbb641a0ae41107468e6f972fb6b1834da207b4244c554252c08006c28');
INSERT INTO blocks VALUES(310355,'ea80897a4f9167bfc775e4e43840d9ea6f839f3571c7ab4433f1e082f4bbe37d',310355000,NULL,NULL,'cdab7e69db1fe0fe2ca254a699959bd55557b945091f667f1402c09e49d09ba6','303a8c2c40c51b98649828140445555c67fc8ecca765e9cf68340cadbbc3c140','f7b99a0eea23c65dfbbe8d96c9bddfd2fe0037b78771e15923859d1b3f20d31d');
INSERT INTO blocks VALUES(310356,'68088305f7eba74c1d50458e5e5ca5a849f0b4a4e9935709d8ee56877b1b55c4',310356000,NULL,NULL,'f9429664e122bb17705c5ec6442757d7d2cfefb0a32f2bbd62241fd1aa8ab7b8','2e599477d4bb2d2d8246c976eb84b141f9175eaffa6eef7622b9c421ba0dd1d0','8add831b187dcc789ef70aebd104dd0ea78221cdb6e240ae154cd17494712253');
INSERT INTO blocks VALUES(310357,'4572f7f4ad467ef78212e9e08fa2ce3f01f2acc28c0b8ca9d1479380726bab1f',310357000,NULL,NULL,'3f365e0bae6a611f0046285a25b11d94b175fe3033cfedb43d6477bad6b4bd98','4ae4651ae03f0ce1ae29e7456f532f8c2a700da392293a65377db9662069c2da','3b5cf16881e52d584bd01ca4e17171b342643536fba396decf0c3590a9bc4d84');
INSERT INTO blocks VALUES(310358,'d5eae5513f1264d00d8c83fe9271e984774526d89b03ecd78d62d4d95ec1dea6',310358000,NULL,NULL,'f48de23ac743aa1cd41433cd0a0a52a56e8a70552bed81f14db39f4bcabe71f9','5bc1e70090c8f863ad80f71046098cf8f6549fde6794839af69007d8da25e36e','09ba90c9bedd84968d045946a6793db163ee1d9f9afddbf3c93aa3be02948d5f');
INSERT INTO blocks VALUES(310359,'4fa301160e7e0be18a33065475b1511e859475f390133857a803de0692a9b74f',310359000,NULL,NULL,'63fd5945481666913e889762ade74f9676034083063a5fdb2207f08be086f6d3','912c3de4e861d46343055e423e42f6773696f328465a2d48c23e4c7dc60533ee','b05cd2141590835f8959b13b85529fabb78a003f0f328ef9b95128df3e29b31b');
INSERT INTO blocks VALUES(310360,'cc852c3c20dbb58466f9a3c9f6df59ef1c3584f849272e100823a95b7a3c79f0',310360000,NULL,NULL,'6150b03b0ece1adf25fbc740fddddd4a7d005f0803436f2fe898c137f30c222c','5491df5ecbd65fb26aae573feaae19528efe661d45552befd8ec32ef1971fe5f','13e1e6d02f94769074dcc969c6a6148ecd26c435cf471857d26303ab72bbc00e');
INSERT INTO blocks VALUES(310361,'636110c0af5c76ada1a19fa5cd012e3ee796723f8a7b3a5457d8cb81d6c57019',310361000,NULL,NULL,'df0538b77b7032009b0e783dd8634a2ae54a700566556e63d2f1bb030d3d457d','a583ded9f9eee5f05d6eaeb570550f7b2c4de9dba7b84514c27f12c642d2bbde','3ad2c320676b2cd8b0f11d808f119cf4b3d96b06af47877e98db60fdf3f0a787');
INSERT INTO blocks VALUES(310362,'6199591a598e9b2159adb828ab26d48c37c26b784f8467a6bb55d51d7b6390f2',310362000,NULL,NULL,'f279120b7176bb678d41226151565081f4d1b8e549ffffbb1a1ca84951e1ae26','a0d02d8e9d4cb5fe4a0a6199f1b69d913e1c814e9ffd1172b24d32ee003fc196','157d547f1e8714464c087c9b8ee3f53168139b5db16cd11994000a12957a4d0f');
INSERT INTO blocks VALUES(310363,'a31967b730f72da6ad20f563df18c081c13e3537ba7ea5ab5d01db40e02647e6',310363000,NULL,NULL,'0e97b9fe29846a62d0df5efc04f6c70bbc45ce65e69d1cb43a7dcaf18ce70923','a49dc9f7f1a207aed0dbb2b6340475bed8f3909c7d931dc3fb4f77498c77bb6d','e2c17efc2fe1f992cf7ea61a9e24493023e98bb6ad59659075f3fa11e8681b50');
INSERT INTO blocks VALUES(310364,'67025b6f69e33546f3309b229ea1ae22ed12b0544b48e202f5387e08d13be0c9',310364000,NULL,NULL,'2b3c10af6f49631dec98e72a51bbeb50cbb79f9238bbd0aa5b70087578196ab7','3415777bec3213e1fae711423d172f876af8ddac75b5e5be467c799126580100','ad7a70edb25843b1081435b9108bc1a56d6648142cb5bb5bc8a116e7478da2a9');
INSERT INTO blocks VALUES(310365,'b65b578ed93a85ea5f5005ec957765e2d41e741480adde6968315fe09784c409',310365000,NULL,NULL,'c9b0ccedcd178bae159aa3f4386829fda56c15cdc94141d8a1dbd88057157201','9242625cd0107b1e4cd9efed93d46dfc5c64a440e2795df49ea95ca87e32382f','ed9f6a856b4b85a94f62c99d1e70cc7a71dc81cf6a67a0587cf4f81fb57237e4');
INSERT INTO blocks VALUES(310366,'a7843440b110ab26327672e3d65125a1b9efd838671422b6ede6c85890352440',310366000,NULL,NULL,'668de8c7cc552d61afab359c982b95d22c36bfcb3d6e9c4fd7ea771e7c8a6f58','53f247a758703b85597211d699a0233db6bb50cc4e34940e6a34f862c2b8df39','8314ac37aa09fbe6e59774acfe93ec458fc6957700b17dbf7712df3eb8304d0b');
INSERT INTO blocks VALUES(310367,'326c7e51165800a892b48909d105ff5ea572ff408d56d1623ad66d3dfeeb4f47',310367000,NULL,NULL,'86de85c357c4f1471dbfbf4e4f5382cfa2bcdb630ba1d3a4605594e7ef1ed9aa','99c30f5fb46ef500b6ffcb97fa5b85b721e20021c1926041c78170f0c71f9035','7c25f0135d7652bc2871a915f03c97e58584cc6ca75d680e2c9f545ec8e70150');
INSERT INTO blocks VALUES(310368,'f7bfee2feb32c2bfd998dc0f6bff5e5994a3131808b912d692c3089528b4e006',310368000,NULL,NULL,'42538f8d70a984737503c085873c1d9b01af33ae5d6eef06e83bea29a420af56','7c2a057afd14ece5b7287bf89b06209adccd178e5166280d3558e2739cb55901','cb5edb6c963076c95ea77238e717fc63d388f814dd866b824f86667b0076cfe9');
INSERT INTO blocks VALUES(310369,'0f836b76eb06019a6bb01776e80bc10dac9fb77002262c80d6683fd42dbfc8da',310369000,NULL,NULL,'beccad01013cde27896c559c5cfbafc5d1f8ab5db962ff105672cb22f6b47b81','c9a591da480f08a788b034458d774b864e0139782fcbd7cf603527ae9939498c','9a751a79cf5ec9978ab4b3e5d69642aa8b9afb779141009b30e0d22b2744267b');
INSERT INTO blocks VALUES(310370,'9eb8f1f6cc0ed3d2a77c5b2c66965150c8ceb26d357b9844e19674d8221fef67',310370000,NULL,NULL,'5fb457661e43905cb27562d27a13c15a7b555d2951cd1c473e9ec2cf9041c1d2','c224affb55a2587b19201e11e6f2284b9d8246b02add0809a160f07f868a587b','b340d4f9018289604d5ac984d680571077b270105adec37316690f58545d0ef8');
INSERT INTO blocks VALUES(310371,'7404cb31a39887a9841c2c27309d8c50b88748ed5fa8a3e5ba4cc3fc18310154',310371000,NULL,NULL,'25ba26c48090e7e72af790ee962c67ae75e09851658a88e18efacdedee340d30','6d93fd3a508b5cc1d463d6593f74450e042d17b36e07ffb3d5e6a8ec2509f6fb','5a780fcb977f520878847914873fd290e370d0f6acfdb7f91529384e1a4b5d12');
INSERT INTO blocks VALUES(310372,'d3a790f6f5f85e2662a9d5fcd94a38bfe9f318ffd695f4770b6ea0770e1ae18d',310372000,NULL,NULL,'92859bc8c834c0a3f44366df3ff368b11f29545c53d0f01f9f5be28d58640952','a2f075d448aa60670ffe6026d79c1b2671e5f4b77e8b42ebc469ef31004b9d81','df49e0e470f79abed972671424722de6d4212bb13703847cfa8befba62d01f8c');
INSERT INTO blocks VALUES(310373,'c192bec419937220c2705ce8a260ba0922940af116e10a2bc9db94f7497cf9c0',310373000,NULL,NULL,'a455dbf7278bd131c1a77bc25057e1aa9564ed14bdf7667996965e19395addb8','6a7431b8f8eaed75c201022437e8609f3fa0cfc24e9a49c5b877304bb6b227a4','f637bb9da5d455b1f536e61e40a11f7e067d773bec8f5f38dfae8feab3d69ba3');
INSERT INTO blocks VALUES(310374,'f541273d293a084509916c10aec0de40092c7695888ec7510f23e0c7bb405f8e',310374000,NULL,NULL,'d83caa09dbea41f8cf6d0214c48a9f9202403dce15c0913f5f2c450998f6e84c','b33c0d7f21021360fcd2aca882efa55eaaabd4f40a16720cdee624416a9ef792','b3ddfc90812058bdea1580e86b241cf3b6810f2166abbcf2958380b27e5ed19f');
INSERT INTO blocks VALUES(310375,'da666e1886212e20c154aba9d6b617e471106ddc9b8c8a28e9860baf82a17458',310375000,NULL,NULL,'4d2906416e41e1cebeb3ab7b3d685a58da2c5b5cdbd7ede2524bc55a59418a2e','9da77e6b14db36040547b672a4165144effb093beee93f7be381610dc57185e5','a8fefa23b39599b96787c21c32ba077c1b382a6e2112295994f5fa3943ce23ce');
INSERT INTO blocks VALUES(310376,'5dc483d7d1697eb823cba64bb8d6c0aded59d00ea37067de0caeebf3ea4ea7dc',310376000,NULL,NULL,'5b6c2099ddc7f2002b7771e654980fd8dc57cb245c6013d78734a8eca4ed27d2','7e1dad1106d938804e8680440b5282132c338cb903ef30f742a744794cdf3c4f','675545b2690e2a136746d44b51b3aa6d1a424fec19eee83520eac41d8f65fe59');
INSERT INTO blocks VALUES(310377,'f8d1cac1fef3fa6e7ad1c44ff6ae2c6920985bad74e77a6868612ee81f16b0b3',310377000,NULL,NULL,'6a8ac8738cad94386d9abfede016309b1e9c2790481ca61dbb807808f90084e3','92cc55311c845de15432e7bd6a3610ee5b15256e7de334406bdf085ae4f76169','98349011140ce004b764aa9761a192df0e0568dd7414eced43165b19d8a15239');
INSERT INTO blocks VALUES(310378,'fec994dd24e213aa78f166ca315c90cb74ee871295a252723dd269c13fc614ce',310378000,NULL,NULL,'f86f2eeaae4948d1fa4dde64829d4b53c9090b088789dd2c681ba817bac9edd0','5207c2ad1b64cec475ea908181c00ec4ff73afe7e80abdc04272f7e392a87402','8ea1d02e442368db1f0a9ddebf060f01d867eefdac2d1c985b893c099ca4d50c');
INSERT INTO blocks VALUES(310379,'d86cdb36616976eafb054477058de5670a02194f3ee27911df1822ff1c26f19c',310379000,NULL,NULL,'3daf019c0162f13caa02bede117c16c7864e62a43b8477da925272285754c007','5c35155fdab2b878b452497f53a5826503a97ce42dba6eeb0470181b3bdf1138','5e7fdbbc6e118dce4e321f7f2871d92fd39b2392901cd11a74e7e788a359c066');
INSERT INTO blocks VALUES(310380,'292dba1b887326f0719fe00caf9863afc613fc1643e041ba7678a325cf2b6aae',310380000,NULL,NULL,'bd352fc23ad181821e497f4dd2564491b0d335088317bde324598466eb5ca665','1a2805c9ab10779d90d06b69d86ca5053f4310b297f12c66a3e4cd42f01ef6ec','e4ad1aacd8d82051ca8bbd0669d2296442091e5297ba770183baacbb81b2134c');
INSERT INTO blocks VALUES(310381,'6726e0171d41e8b03e8c7a245ef69477b44506b651efe999e892e1e6d9d4cf38',310381000,NULL,NULL,'badc6983fabb97a35a1c7648c90027f939a640482f763f7cf6d0b42ebdfd59e7','38b9951cba9af7c8104cbb32231db0aaf4bce8d152f0e848eb6c501daf78b172','32cc427bf91c37836cd25c838d2aea2a700a23e6ba4b1256d62812cb947d4d47');
INSERT INTO blocks VALUES(310382,'0be33004c34938cedd0901b03c95e55d91590aa2fec6c5f6e44aec5366a0e7d8',310382000,NULL,NULL,'fcabf3cc20e0733f2da9e0d7f532791df40e40739a9bc01a5a279fd7b038ece7','01a79a9b38b4e57fc325ebba9ea6e0b30bf684ebbe3052447a41486fb373a2bb','33d3bfdb69fc00ca9f87da15266c2a02cbe40226e0e019e260a10c2de12e4a5d');
INSERT INTO blocks VALUES(310383,'992ff9a3b2f4e303854514d4cad554ff333c1f3f84961aa5a6b570af44a74508',310383000,NULL,NULL,'c409b954d253a89290e3647d9800cd1bbbf00d9ae57353cfb8adb37415cd1d6d','e62168521902d5e71c7528a3cbd5c66e2e821a6e3395629359720f96536be8d8','978dccaa21b1200c966f3b32ea39a65776527e41e3e2898ef937e7a42d0529b8');
INSERT INTO blocks VALUES(310384,'d518c696796401d77956d878cbdc247e207f03198eabc2749d61ebeadee87e5e',310384000,NULL,NULL,'8a7c5c66cebc831a80d50038a51a294e350fcdac1cbc710d623d7bac987051a1','c76a5015b4b71ee0151daa95678e60c8c3cef81b8ab1c8a9f9f76037213898de','9c55fa91a2884bb56e038f56b6bfb781c95db7dab602e92a5c60fed4ae0cd21c');
INSERT INTO blocks VALUES(310385,'2aa6a491a03a1a16adbc5f5e795c97ec338345cfdf10ff711ffb7ac3a0e26e28',310385000,NULL,NULL,'bf0b603f6f9e206155cb9172b9f499745decb4cb9b9a752f420f9f0859cf18fa','428801cd80c357f93b5048bcf5572e1d7773f01f94fcfc64468307c1d10e412d','1619706bef42ac7c3fbe68d9ed3c692a77f9d57138ecfe6537bec25fc4a0bff9');
INSERT INTO blocks VALUES(310386,'9d19a754b48a180fd5ebb0ae63e96fa9f4a67e475aeefa41f8f4f8420e677eda',310386000,NULL,NULL,'7517290ee0e6074e43b5e924bc267ecd667b6470ea55d9fb78631a28ce648fbe','8ca0892a152ef91e0557d98a034d2f1f417c4622b85631c25e6506dd3aaa10e0','b4c10230b8831cf328b878d32559301587872eac7aaf653d1a32f31774b5fe75');
INSERT INTO blocks VALUES(310387,'b4cac00f59c626206e193575b3ba9bfddd83bbfc374ebeb2838acd25e34a6c2b',310387000,NULL,NULL,'d445d0248b0895490c991736c931da3fedf21f7d966a2817a66ffb3603143d8a','1dd5dc0e28c07e4fe858cd30a940e42aca1bcbd7e8d660318198191f9af7771e','29549031417b2965c7506678175130c6be239b52f1af2a480f19d55245104c28');
INSERT INTO blocks VALUES(310388,'41a04637694ea47a57b76fb52d3e8cfe67ee28e3e8744218f652166abe833284',310388000,NULL,NULL,'7c7e381de026372f3d96e4fd2478e157bdd75e3cc42bf11335be148febb77ccc','38a046bfb64daef741b82a74763d2b3e5c8ec1541b6870d37e194851244a880c','9e06ac48bc841acab332478df7c2530d11f8a495c3124a3c2d4897cb53b9e99f');
INSERT INTO blocks VALUES(310389,'3ec95ae011161c6752f308d28bde892b2846e96a96de164e5f3394744d0aa607',310389000,NULL,NULL,'6cf12f17775a06ac5436fa0a27a5fb81f905d64625f23d6ee68ad71d4c58ca55','b31c000852d233311e9102569a2bb5108fad1aa03f8ee385d6d10619117b2c3b','11b4f98e5865208ef16912d0a425663a967a1adbaf9fb1256c35502f8a641523');
INSERT INTO blocks VALUES(310390,'f05a916c6be28909fa19d176e0232f704d8108f73083dded5365d05b306ddf1a',310390000,NULL,NULL,'4d748830e701841a03abbc767c52c103ac74e35071b1ab3a11cde71b258fb1c5','c15318a94f33770580c692d334138e900e4101d21d7df014c49374b8f9d68f77','3c7e019ad977fde9a7a750ddc6f455b1693eabd805c5e8b874b657eb5e79a3a5');
INSERT INTO blocks VALUES(310391,'fc26112b7fdd8aaf333645607dabc9781eac067d4468d63bb46628623e122952',310391000,NULL,NULL,'2578a29ebc72ff46d051ed313137ba8db656228f99aba9c2594881aecf6c6748','dfa7e36c9562cb5b5499dda02aa866bb1c5b37af575f7c7e2ab946630f922415','d001a18c30423f5ac1f80670cfdda3b2af270fdda99f09db015d178205b994cc');
INSERT INTO blocks VALUES(310392,'f7022ecab2f2179c398580460f50c643b10d4b6869e5519db6ef5d5a27d84a1d',310392000,NULL,NULL,'20d92acfffc3fec918f8a4b3cc2397712887900e6fbf5d268ad00fc1fd1419b8','09675d737cae9c1ad5c10312a9995701bf5f7293f27aaca2947ec635eca166c6','222113dd990f2f7bb5b9b6ba365d590461a7cf6cb89ae00a7fd87a8799ecb3d0');
INSERT INTO blocks VALUES(310393,'e6aeef89ab079721e7eae02f7b197acfb37c2de587d35a5cf4dd1e3c54d68308',310393000,NULL,NULL,'e91ac8337f22aa9d0215a8b4d951d793e145fef0ac1368b01b2e50a7e1f694d5','d022a4368dce44e4e39297a025fd7d1aaafb7b46420d0872b57ad649037b3f7c','f4cc19ae59e78d864326b7e2fd271b16395966416bdad67d684431ab375d7cdb');
INSERT INTO blocks VALUES(310394,'2a944743c3beb3bf1b530bd6a210682a0a0e9b0e6a9ff938d9be856236779a6f',310394000,NULL,NULL,'900057ba338daf0a628de8d31f3ef8433c32181b49c96b12a9de396b5107c0fd','6211e6b0250d3833a4febfadd3b755fd67bd36a4cb1c65da2d552d74208a64db','e26f16f80291dff250bd8b46ab2750384811c529ad94549b628f44226a6583a3');
INSERT INTO blocks VALUES(310395,'19eb891ce70b82db2f2745e1d60e0cf445363aaff4e96335f9014d92312d20e4',310395000,NULL,NULL,'305ef8a186f7498d6c576d03808e0b1b875e32f42a252e96a87c9ef7030f78d6','82c88169c371b27aa41c8d8de13b0787adfeba1732ffe4c6e7ad0e0c1a4fae63','fd2319293e3c4413f6e4fa5ec11f4dab9b7a77bbb0b8a3d808f178be3695e467');
INSERT INTO blocks VALUES(310396,'aea407729ac8d8e9221efd9d70106d14df6aaf9f2f87dc6f490835a9caadf08e',310396000,NULL,NULL,'b2c4a2cf312ac262ab7d08d00f3165b656801d7fb06c6a32179355012c0cc9a0','b5979ee6b93d8cce98b9b6a81e3600e9795dd872cec1cad120bfeeb382b32571','0c210e0f1e5d8e7ee1dd20dcaea202ecc3f62071ce43c1b37daa18f5b7556db6');
INSERT INTO blocks VALUES(310397,'7c429e56a19e884a8a77a759b52334a4b79404081b976270114043ba94d7985c',310397000,NULL,NULL,'89b57997cfc2e66d48c32a97dc90b325f730797def4234dd6413214e9a644737','6e0e33e6aea507756ff756d25ffd0d3a8468b95a07b2caa222e1e611ba2ceb42','69ad5befba851b648ecfcdb1a16aa0bc28db893a54252c887a26943a7a574483');
INSERT INTO blocks VALUES(310398,'55c046db86dee1d63c0e46e6df79b5b77dfd4ab2ff5da79e6360ce77dd98335e',310398000,NULL,NULL,'ca281a6affc929ef06e922077782dc009d3cd4429cef0a154ef9f2bb4780d7db','6194d527f024442bd88c580ee369f661d4399f363f51fa47ab79481bd520cd56','f2df34fc236dccfb9a98ee5a9a9aa0c5e8b442da98c842bbf2a96f800fa1f9a3');
INSERT INTO blocks VALUES(310399,'765abc449b3127d71ab971e0c2ae69c570284e0c5dacf4c3c07f2e4eca180e7a',310399000,NULL,NULL,'c7f1b3f3a45ab4b5e6fd1514fff5147df1728f83d9878d67c23b6eef838774cd','c0b3cddbc80135f1b2794428db92c2931be32d21e56aedf617f3eb32b92168bc','56e6d11a70e08bd58082975298f4dfc55261207c4661ffd724b09f3d548afd71');
INSERT INTO blocks VALUES(310400,'925bc6f6f45fe2fb2d494e852aaf667d8623e5dae2e92fdffa80f15661f04218',310400000,NULL,NULL,'6a120883e8cef146589ff4d8b88711ab2f2a588aecab66d48cba48b863bc63db','998a807f98f482da3b5b1d48fb55fdc1048aee18d8c37c6bf70e421406864ac8','76111fcc7a174039f1a55226883cd754f8387e4b3e55227b88de4aada2264099');
INSERT INTO blocks VALUES(310401,'f7b9af2e2cd16c478eed4a34021f2009944dbc9b757bf8fe4fc03f9d900e0351',310401000,NULL,NULL,'5ffee837193607b2f993ebba717eee650af6ac0a66bf00faf5b7b27bb416fa2e','de5f1215ceecab9b37eb9a9d8f60290d878caf244e0f9bbeb53fb1708b05d85f','cb2cde2ebf97b2bacc1ab5ee318fd079e23048e152dc1d3532e003ddf14c8632');
INSERT INTO blocks VALUES(310402,'1404f1826cd93e1861dd92ca3f3b05c65e8578b88626577a3cbad1e771b96e44',310402000,NULL,NULL,'c8150cce5f0a7842acc466b5532dd4a057f9b214f9ad2fb2df4f27d2bfebffea','c8798ca79475bbcec77a87a8991de1e13bdcb41f03da2e59af67997fd997b13b','769157e0c988b1c6832b2fb09978751a319d720183e9b29ba3351a121dd57ae2');
INSERT INTO blocks VALUES(310403,'f7426dbd4a0808148b5fc3eb66df4a8ad606c97888c175850f65099286c7581c',310403000,NULL,NULL,'ada969109e576b8aae880710323e7dc03bc8b482a0389a3c40c5c69add556336','de3afa5d78c5cbb936bbbbbd041f3d1f3e9612e86161836a3a5920375e106a7d','03b0ee1d7103c9f06feb4df154fac28dede9fdbb5afda46dad3f032eeb1f2049');
INSERT INTO blocks VALUES(310404,'401c327424b39a6d908f1a2f2202208a7893a5bedc2b9aff8e7eda0b64040040',310404000,NULL,NULL,'a74bca383a199391814ebc47de497a9e57f9cdc4eda3002573ad4b30c265cb72','f13c69b86a839a975e022b78e9d7180a3591aba91aae26d714b3faf5ed7f1f6f','e6afac56e803579ef740591033a56a78e2ba27c4a570809723966b9f9e280836');
INSERT INTO blocks VALUES(310405,'4f6928561724e0f6aab2fc40719f591823ca7e57e42d1589a943f8c55400430a',310405000,NULL,NULL,'3363b4eb4905e20e8a395ef8c1ba89786a16a3ef598ab8ccd479a9ab1c884640','7056226addc65a012ec265e3af234aab8d2553a72e514c426b9849ccf3521571','68e36630b27fff90350e5dd282cfa3326255260a5dbd6f523107c22d1b08ce00');
INSERT INTO blocks VALUES(310406,'6784365c24e32a1dd59043f89283c7f4ac8ceb3ef75310414ded9903a9967b97',310406000,NULL,NULL,'5930187fcee1f83b807cfe9fffb51af826e79b351df0211a66dca64ae580ff37','fa2335c31fc465c4004ab6e9086d5289ff35caf0b06865bcaf8a3e34a7408e8b','54e73cee4dff2406836238bd2b955031b3da92effb02cbec09a06d04415f548e');
INSERT INTO blocks VALUES(310407,'84396eb206e0ec366059d9e60aefdb381bca5082d58bffb3d2a7e7b6227fc01e',310407000,NULL,NULL,'1f86c86c3d82e98273c206eb709e97cd505b04c154a9a25f89da20073daee4ef','629914e2dee7e239ac4e492ed0d051b58489c0dc3d2ee0d95387b1ed89670119','190e95ac47fc7ffd7a4e3932dee66aede51bc2e4ab5af007043007ec9d770432');
INSERT INTO blocks VALUES(310408,'4827c178805e2abae5cb6625605623b3260622b364b7b6be455060deaaec2cda',310408000,NULL,NULL,'3049ffc4696d9397c15cd23ee7c55bd70f1a35363df856757edfac0e03cf961a','c17f68a7e22dff03b7cbef012acfb0b23ce6e859f6d7bf891e4e9230cc23611e','1633ca0c797f6d420910f0566fc7d58d3d935b4d066f3c1999b967410fbab976');
INSERT INTO blocks VALUES(310409,'01a719656ad1140e975b2bdc8eebb1e7395905fd814b30690ab0a7abd4f76bba',310409000,NULL,NULL,'6ba59e31b6801438970ac09bcba5f0f930fc62c60ed6ee799d727efeaddbaa59','f5fd5383c55dfa3860a1259d90afcf99c30fe8325410b5d4cf497d7a3efa1e4c','83f97730cd6b4f8a3e5281e239434d7cffaba11eeebb47c02defd56378b30029');
INSERT INTO blocks VALUES(310410,'247a0070ac1ab6a3bd3ec5e73f802d9fbdcfa7ee562eaeeb21193f487ec4d348',310410000,NULL,NULL,'cc4b1601d69d0cbe97ea9a87cc521bb9d0c6fdb7a6174c02bb63bca3e8aad494','1bf95f82463379bd1ed15162ea4fafc0089d5c30783ce68836d23270091ae0d7','c785a3c5d0c57be5016fff606de81533ddd31b9d2cdba99b0fd58a0661efcec2');
INSERT INTO blocks VALUES(310411,'26cae3289bb171773e9e876faa3e45f0ccc992380bb4d00c3a01d087ef537ae2',310411000,NULL,NULL,'86c69ff6750569281265a3840b6549fcdd656a325a871ac453bd0d4c2fe93113','84eed676ccf7dac6064f3ef0e6062ddd2ba2ef73aaaa9050c15f850214fde24e','dc9c3ddeab8c1a03a1b9fa271857121f1bfc642cacb90f32bdabbe9aaee67278');
INSERT INTO blocks VALUES(310412,'ab84ad5a3df5cfdce9f90b8d251eb6f68b55e6976a980de6de5bcda148b0cd20',310412000,NULL,NULL,'850881ce58882741dfe81c563088b6523f5d82891a1262895a247b78aee4e6d6','c8967bb3601c9637e8beea65dcdd92f0f0981dfecf588135bbbac97771318604','b5ce9230c2ab626b4a6e6c43385db17d43694a6d4d335c46cd905c71cb36f910');
INSERT INTO blocks VALUES(310413,'21c33c9fd432343b549f0036c3620754565c3ad99f19f91f4e42344f10ec79bf',310413000,NULL,NULL,'5e23f26ee26f9889499bef4306187843145807d5b4d326621e4511cb46f99101','26ad1b371d0f5475e7865730515d7df084932200dd066c9c1b78b211fcbb67d0','351dc92dcb3c4d588d4528139e17cea442ba6292edc9740e7997b95b5f566598');
INSERT INTO blocks VALUES(310414,'8cff03c07fd2a899c3bcf6ac93e05840e00de3133da14a413e9807304db854b6',310414000,NULL,NULL,'ae425f4e6190737a1e67a4b189de5279040dfb3120d52c12178e046419abab69','3221818b47715797de0dc701d883ee7a3eb75dd064bae86b7c598173692c00c7','f9e95390b38ea293a46a4960eceb5b8aea855dc7306f289fb24a66aa8652c2cf');
INSERT INTO blocks VALUES(310415,'dd0facbd37cca09870f6054d95710d5d97528ed3d1faf2557914b61a1fc9c1cc',310415000,NULL,NULL,'70e969cbe962828dbd36fefe884bbd995fa8e7e0705e5b4077442ab04d9b3e9f','bcf9c3f528e15cc98c3b8b59c4e66fbf0717a2d82aa3751041a1219181817d10','e96e1415e09ad9b706f2c5a4c4ab6b9ce7130d78bcf4cec0834c6fa50fe464d4');
INSERT INTO blocks VALUES(310416,'7302158055327843ded75203f7cf9320c8719b9d1a044207d2a97f09791a5b6b',310416000,NULL,NULL,'7321b4104564c6d3208dcaa58a195b1e1e806ff14948f9bb7d22622c210e8a05','ed03f09b50691d812cca4ea4c486a63bef4821b7bb894d6af1e41ffaa12214ea','85a7d459b88cb972a575fa677dbde8f39ed9ef428b2daee6f28a1cfc0e9e1dbe');
INSERT INTO blocks VALUES(310417,'2fef6d72654cbd4ea08e0989c18c32f2fe22de70a4c2d863c1778086b0449002',310417000,NULL,NULL,'40f75ca8549f5bf6bb5601561054a7f90a3cc051e4e38f29519010cf268931b0','85013cea84bbcc6682aa184e7845334f93c259392e45e0033d88bad7388b633f','defce347366bf1c06b8780f0b6b29529ba91a5d8d2c77b1ebde92c668d57e6d4');
INSERT INTO blocks VALUES(310418,'fc27f87607fd57cb02ce54d83cec184cf7d196738f52a8eb9c91b1ea7d071509',310418000,NULL,NULL,'fa1f748145309c14264bc47a5cfb0eb1898c73a2dca24aed107f034f1d7cc1d5','86787e77f75db460a90c084d3cc73af678d31e1b793b56efc7abab462075f469','a927a28330eda9b648b53111af00b4ee64112fd910a1a4384138af612b29496e');
INSERT INTO blocks VALUES(310419,'9df404f5ce813fe6eb0541203c108bc7a0a2bac341a69d607c6641c140e21c8e',310419000,NULL,NULL,'671b2eed1b986e48f8717004e77718643eda316baec0a2cf855e059ef93a3366','1148ad3982d95081dd727a2c011abdfcf80257978860f93f46a6cd4c9cf37889','68d150c7c3cafcfc5ab116fb475839e85ef4171faad21931ebd231b78622348f');
INSERT INTO blocks VALUES(310420,'138b3f1773159c0dd265a2d32dd2141202d174c2e52a4aeac3588224a3558372',310420000,NULL,NULL,'63bf148563a504fb2cff82ca7501d1b5d59ccfa4ae881ebb8289e91b4f67ef7d','6d2b60c81ff94b53d3775c57c03b39021f29c05889d3911a0c0d1ddf0d6a116e','89578df8995692daccc19dc4fd92ed05edab2179c1135ff0adfe453361e6ffee');
INSERT INTO blocks VALUES(310421,'71fe2b0e02c5cad8588636016483ddd97a4ef0737283b5fd4ab6ea5dc5c56b9a',310421000,NULL,NULL,'ed4c1c20a25736299bc9e3a7db8f9be86c361a8555dfc433b76f71cf9710dbe1','f3ba6fdf4ee2e31e672538f566e2944211f844218cbe1b957ec353a9421d1882','dc45856e9bd353f06da789c4327ef6625456ede934654195a31388bd469293b8');
INSERT INTO blocks VALUES(310422,'cd40260541b9ed20abaac53b8f601d01cd972c34f28d91718854f1f3a4026158',310422000,NULL,NULL,'e2b1636c61fb4b5ee987a61d78a4bc39d59728b1d5b520e47293bfd026b69e0a','a8c707a2e5575c884a9caf9eb431b02d8b30641a077caa0910fd9326967c0b31','5ade903fe72c83774fa2e105b168cc0f43b1f355688c47a3e0f10ac8d6086756');
INSERT INTO blocks VALUES(310423,'6ca0d6d246108b2df3de62a4dd454ff940e1945f194ba72566089f98ad72f4db',310423000,NULL,NULL,'aa57b091e842b72bb16dfa198c81a6967618f5690f237c39c0289dede66c564b','1104bbeb418f3d3405a77444c73380bc013de09b9c331eee81500ce2770f91a6','d028d37f3622b94fed20aef50f28cfa37d4fbc3b447dfe8afaa661d0253f5102');
INSERT INTO blocks VALUES(310424,'ed42fe6896e4ba9ded6ea352a1e7e02f3d786bfc9379780daba4e7aa049668ad',310424000,NULL,NULL,'5083b1ca4dca0faf289a21cf2ab0e9c2f2fe517679054c7934b4245292e90c79','274721962249897bf01db95a86347283debb7f8aa064786529c317d600c91432','da35dfb55c4222609de580cc12fe054b977bfa316eb194530d0034d846b6f0ea');
INSERT INTO blocks VALUES(310425,'73f4be91e41a2ccd1c4d836a5cea28aea906ac9ede7773d9cd51dff5936f1ba7',310425000,NULL,NULL,'4c32ba8004826efdb1ce82c5ae20455bcae5c8c7de3a36ed639e4323e2c79817','18664982ec2eb9d08826604d0aeb91f83c86bb0867971870c3737d10ddd2238a','cde3fe01d19b38fd1c7a7caac16b72f2fd30e20c8aa02c773e5e4abf128da893');
INSERT INTO blocks VALUES(310426,'9d28065325bb70b8e272f6bee3bc2cd5ea4ea4d36e293075096e204cb53dc415',310426000,NULL,NULL,'341450a399413e5eec79a161ac7ba094ca60373b24dcb589bc5f3a4d1640867e','12a6ae0540b55c76d0f03dc4d76128fae65933e33af95a5a948c07f74addbbd8','08785435b67d72091ad8d06b680f3ad9ef0cedeb663e617d6d8c5f9e1f918847');
INSERT INTO blocks VALUES(310427,'d08e8bc7035bbf08ec91bf42839eccb3d7e489d68f85a0be426f95709a976a2a',310427000,NULL,NULL,'0e6967fd1d012db3d000628ef79493bd96a56eb06cbb869a7300b565d7ff9db3','76e3a6bf4332bbc334f98fc446bf4d0f6d41dd8ea3e5bb415f3ff1c31ea4503b','b7b66cddee1b07f44683bfd9172b3af287681fe56d982ca8856288933903ba95');
INSERT INTO blocks VALUES(310428,'2eef4e1784ee12bcb13628f2c0dc7c008db6aaf55930d5de09513425f55658a2',310428000,NULL,NULL,'042794232e0750b54e846774802cecf6d801488df86e074936b40d6c0f8b0a09','5298ceab47430b7a5cbf411153506bb3fe5159cfd478d8cf12751664544610a6','e5ef50d72745cfaac0b7d71dd1da190c4c129b65bb02d283a97407bd3ac6faff');
INSERT INTO blocks VALUES(310429,'086bfbba799c6d66a39d90a810b8dd6753f2904a48e2c01590845adda214cf8d',310429000,NULL,NULL,'3590dc920b66826c0ff9db2b8e826e4cffda724f58e0af6a419ed6ae6be39126','8f2a9ca3994d187f69574b4cdaa817d6186ea94b456b02a7d5613a24d94ff232','b0de21806d025078c949ba99ddfe860b2d39779e04ac41f71d9b137832f16f91');
INSERT INTO blocks VALUES(310430,'870cf1829f84d1f29c231190205fe2e961738240fc16477c7de24da037763048',310430000,NULL,NULL,'3dcb18cc1f24f2cc6efb11e19fd2372fb7f899e83fdbcf34b09b3a96e15d3fa7','6839ac7ae09b45a8edda53b34cb886939d50cc5939b0d80867ac9d7b044088e0','66b4637235d532c324ea50e81fc46a74ce798e66e13785031cb302daa8fe8a50');
INSERT INTO blocks VALUES(310431,'20b72324e40ffc43a49569b560d6245c679e638b9d20404fc1e3386992d63648',310431000,NULL,NULL,'e2f85fba381882f51acae84f50072d1b8b0609845e9a891390249079cee3f5d4','db8be881d4417972cb016d8eba3f4cf9c28c1ab24a61d2a9b0413170b88a6a5e','a06ba975f396c7aa21ec5fed644bc12c1a0f796b7eb12f900a4d9efd350ba849');
INSERT INTO blocks VALUES(310432,'c81811aca423aa2ccb3fd717b54a24a990611365c360667687dc723e9208ad93',310432000,NULL,NULL,'2bc7d3d968ff9ddf047bc56404dbe6af9db96d35eeac23fc16aa5836d96ee2a9','2fd036cc6fa5cdefafd86b5e47a61f5027e026105292242332e05185d9e8f3e2','9ec9da12a1de8341d5c3a45b97a6d3c258b537a3ae5344fe425206a8ef39ff0a');
INSERT INTO blocks VALUES(310433,'997e4a145d638ad3dcdb2865f8b8fd95242cbc4a4359407791f421f129b1d725',310433000,NULL,NULL,'9a47cc0d4aa26e88e29c20ea029b890e8a6e3f219bc421424c69ca4105167c75','4712d04d55030aded6e368381c880fcf02e8de6b2da70202b9998042fee48d6d','278435a478540c10335502f7efb2f375bdedd663ef67d84724d3e152bc9f027e');
INSERT INTO blocks VALUES(310434,'61df9508e53a7fe477f063e0ff7e86fbb0aef80ff2ddedc556236a38f49ac4d8',310434000,NULL,NULL,'54989e79b8799b14c297830e0c9a2e1a75b0848ae4a6f26685ff65f8a21d4f20','2415a7dbdda418eaaa06b9f1f4c3facc45f84c5e1e809dd35b3d08e7d040276e','8390bf7a52b0def9ce2be826ea4ed0f6f428e7bf2bcda1e64f8d4cf17bf9837f');
INSERT INTO blocks VALUES(310435,'f24cf5e1296952a47556ac80a455a2c45da5c0dc2b388b51d235a3f741793d5f',310435000,NULL,NULL,'18c4faec79430dce45aa2399d8f9bd9179e03971cc091c6883091ce01b049973','a94c0f012ba00b24c329f5e6f4183d75d9f0cb8572095b6fb209545514f4e901','b1a6d8375407bd9abba7fa434dd5b7a1a2615d23968ad9ea4e0f9a6a5d8f61b0');
INSERT INTO blocks VALUES(310436,'a5e341ba92bdf9b3938691cd3aab87731eba5428bb61a804cecf9178c8da0c19',310436000,NULL,NULL,'577ebc4535a06892967c8e8660477be108548733c578363d6f9ed0629f8961d7','5c9779fee323cd1c4fa5708c2f7a62e1e85c12d726ccb72c65ca48e661ce00ef','b1ed8817154cacade68dfd4a694a95f8ea671431903a08f29db1f4eaed263466');
INSERT INTO blocks VALUES(310437,'9e18d0ffff2cb464c664cefc76e32d35752c9e639045542a73746f5ec2f3b002',310437000,NULL,NULL,'4687b6b63670707115c3abc1abfdb936395d4cb48b1b573a2177dc9066cc842e','754ec0b9a9c1a22859366d2afd77ce670e574ab6eb1ef5c160318ad499b4c59e','1120d29a81f01046e7ea0b6b09d5933ce01a4ebe73a8c2d41af5c7ecd1ac77b0');
INSERT INTO blocks VALUES(310438,'36be4b3470275ff5e23ed4be8f380d6e034eb827ebe9143218d6e4689ea5a9fc',310438000,NULL,NULL,'8ac499665abab3d4e7b72fc530536817b124ab990b11b9501967c807a565584b','144da1c7a2429d502b474f3535d51ddb3df97a2c08af457709c2f8adf3a83d9d','5e319ee6317118461184732470efdb32a87a275a63b0fdeebd28a609c3c71ff8');
INSERT INTO blocks VALUES(310439,'4f2449fce22be0edb4d2aefac6f35ce5a47b871623d07c2a8c166363112b2877',310439000,NULL,NULL,'81c29e8f4e735fe4994476efc73f822caf55f5ab03aaeca153fa2c0995901275','6a75b986c4b5e6b999c3e3382a7943807620d0da9be04f63906e8d8293d355b8','cad62b09652e80e6c1c6f5a51f18fe35e47f427ea957b1443a450d6496699002');
INSERT INTO blocks VALUES(310440,'89d6bd4cdac1cae08c704490406c41fbc5e1efa6c2d7f161e9175149175ef12a',310440000,NULL,NULL,'cfe6ac925a65faa3a61384dc4b19e21a65008251959efafcee31f62a95a02640','d185d005250a193f63499304c0c184eac98972a821f1404706cf0e8d0cfa1945','5af9c8a898074a59d6fa86251fb3edc8553c0701de92c75af5cf29c6d36e0a14');
INSERT INTO blocks VALUES(310441,'2df1dc53d6481a1ce3a6fee51ad4adcce95f702606fee7c43feda4965cf9ee15',310441000,NULL,NULL,'7b3b43df60ab1cdf404921149e15a45d3157afada6f89679e765a595422b189f','41791ee475cdb0962fcbf27630a37b8705f03db657dd84421c87e48d9ff33142','93fe414b33017b45f723a656ae9ea4261dd8caf7c599e89af78fda36133f4a82');
INSERT INTO blocks VALUES(310442,'50844c48722edb7681c5d0095c524113415106691e71db34acc44dbc6462bfec',310442000,NULL,NULL,'9e02e1df0fb1ded567d8f38385a6a937905993ad3f8f41d90773bfd972371c56','23acc269592192c3a74a130e9338177ff8a53479779800dbafcb54e1338e897f','a38859bc1e9a030536bf7449eaea8b16794a8316fd75bfa15f3a6f55bbbc59ab');
INSERT INTO blocks VALUES(310443,'edc940455632270b7deda409a3489b19b147be89c4d8f434c284e326b749c79a',310443000,NULL,NULL,'989d0274e31987eda39074a4c5fbc82b05065a5703a5f3c66d1402664df0060c','5635374f3dba6884601e1e2134a948d1ce6cfca5a4bef4efb7aa81780e97f151','9eff3846f08a833809294a9f9f6e21d58421f16761996dd72240d1a4a44acadc');
INSERT INTO blocks VALUES(310444,'68c9efab28e78e0ef8d316239612f918408ce66be09e8c03428049a6ee3d32e4',310444000,NULL,NULL,'0fe1c73127aa2dc8a53e5922bb42947129847b1fa106969abcc0f136bcbfcef5','eee644ae160df4951b4192944a27d1e8cf5da8f0f35bb3c03eac0306e4042bfb','854c6551ba597b8994d8bc1b4d17277abdf9b4f17986d3d0471e4c88761f2653');
INSERT INTO blocks VALUES(310445,'22a2e3896f1c56aefb2d27032a234ea38d93edf2b6331e72e7b4e3952f0234ef',310445000,NULL,NULL,'ac909ed813f6e84e657ae3b28d84cda9021bce9358cd2a069b15ccce56362f39','b90655587ba48f90abf6da99fde3cea74a38e68fcdda49a6642678e8bed83b98','d8a109b56d2fb6b4ede3c0c1f4c0344734cbc3d64ddde711fa9b0bdaf6f3f948');
INSERT INTO blocks VALUES(310446,'e8b0856eff3efce5f5114d6378a4e5c9e69e972825bc55cc00c26954cd1c8837',310446000,NULL,NULL,'b3130a131688db35a6c9f5a395aedacd8bfcda22c306ae1e4028830bcf178ad3','ebf2ad9be6eef549d864b911e9ab9eb56ae9b4e1d08808ffa4352b2c202bb8e4','deee7976c6c402ec5272abb0d40f9c733f9aeda5d015352a4fa0618573624c5a');
INSERT INTO blocks VALUES(310447,'3f4bc894c0bc04ee24ed1e34849af9f719f55df50c8bc36dc059ec5fa0e1c8a8',310447000,NULL,NULL,'1664e8c45fa0435d6d8b72933e8e597c72476048a836eb860f85f6e1b632abe4','85a72c4372d166567fbcad21e0e226dabaea57bd5bd0cd17ab060c0e04384c15','b73188d8dc0d3264bb07ff622feb45a617ed20f727adaa349ac109c15ffa2b94');
INSERT INTO blocks VALUES(310448,'6a6c7c07ba5b579abd81a7e888bd36fc0e02a2bcfb69dbfa061b1b64bfa1bd10',310448000,NULL,NULL,'9492a1221dc276cb417971d7abebf09627a2b628512c68d942665658f50772ea','8a86e8bcebf5eef0a7edd0a97dd9d9444c53417cd381891b43ca13808aed5166','e7b847be1c16232f8da36e1c1b40dd00ddf3ed337616f48df8267762ba2d0475');
INSERT INTO blocks VALUES(310449,'9e256a436ff8dae9ff77ed4cac4c3bfbbf026681548265a1b62c771d9d8e0779',310449000,NULL,NULL,'58d7a4d4f500b31762043d44248b27790a379e2526d5a090d452a1d89a99b34b','6051368ebbf147ce73d80a53d13371bbddb71beeda3e704067f2b18b032af070','d30449e0d6e416b699e974aee12941679fcfc85be074390ffb6f589bbbf3effb');
INSERT INTO blocks VALUES(310450,'2d9b2ccc3ad3a32910295d7f7f0d0e671b074494adc373fc49aa874d575e36a3',310450000,NULL,NULL,'235b73ccdd6b4ce76f1babc4631619fec8f4165a26e5df4bee424d2edaacaf87','9bc6b2e88bb0e5c6ce14746a2d02be91e5c6f8d9481db6d6f1ea3f260abb166c','ac090d7ca781257be1dd9fb0e6ba5572a9a839c83db0fb9a6ef6e5e120ccba72');
INSERT INTO blocks VALUES(310451,'55731a82b9b28b1aa82445a9e351c9df3a58420f1c2f6b1c9db1874483277296',310451000,NULL,NULL,'0b91e1fd662d36816ed7507194f8cae5a0bfcf2d5f08a4bbc96c3394e8a52d6b','655e865d061555a1564224a3e67598d8d29aa4bd417bcadb33fafe68c66da043','8a9b8f61ed0d2e9c30b4cff42960461fa7cba45a03ca051b89e669e83a3ae4fe');
INSERT INTO blocks VALUES(310452,'016abbaa1163348d8b6bc497cc487880d469f9300374a72ecb793a03d64572aa',310452000,NULL,NULL,'facfafd171df17d80c4c37bb9eabfefb61f9dd6ccc69e6ff1f5afb5806d50a28','10adf6c52b40f7a8803a75f55975d92e4d2f47f1929858bedc1fb6613ee5d070','ddd162b9a8fb0918a17294dc9d2d7fd2377924666eb3a02128486fa44b514858');
INSERT INTO blocks VALUES(310453,'610be2f49623d3fe8c86eacf3620347ed1dc53194bf01e77393b83541ba5d776',310453000,NULL,NULL,'37d7d8db1351195e5a799445d230df2cc0041c2e34f35c50a934f6e74884aaaa','5df7cf6f175e9a93bd9b66db571ccd2806c8d286ac44cc8c109dce56fbff7c18','b45f751515eddda954206d42e01842962d7b5164dbabc8020d274a1f07de61c6');
INSERT INTO blocks VALUES(310454,'baea6ad71f16d05b37bb30ca881c73bc48fd931f4bf3ac908a28d7681e976ee9',310454000,NULL,NULL,'01d79cced9a1e21e86b105ac9a20b7770db78c664c66cca225eea23f68c228dd','6f2ed6be02952deb3935a66ba599cee84781638ea4050d4c0bc7d42a2e1dcd3a','4baf550e722be241ecaa6c1a2556a7a347f67f98128e5651df356ac21e6cf1c5');
INSERT INTO blocks VALUES(310455,'31a375541362b0037245816d50628b0428a28255ff6eddd3dd92ef0262a0a744',310455000,NULL,NULL,'ac019e21eceefeefff0f90f73f5eac416340b3f0012beaf9264332d21377e73f','34f0d70b14aced539a42f3b2136886a2c28744b4c34387bd5f9dceaee1fb7938','f3cee0b9b51776f29836634ae6de80cac25ca1547725689838ca99ebc33f2d51');
INSERT INTO blocks VALUES(310456,'5fee45c5019669a46a049142c0c4b6cf382e06127211e822f5f6f7320b6b50fa',310456000,NULL,NULL,'d177db72acd8196e8efeb0c036105162316208c582207f1d9f8d60f92f7281aa','049a25fee7bd9b76a46d16480f2428a99692c99174ef3f8c08044b24739f8721','c5da3997326011308dce381650878d39ba714e3dcc9ab38866dfbfffe05989b2');
INSERT INTO blocks VALUES(310457,'9ce5a2673739be824552754ce60fd5098cf954729bb18be1078395f0c437cce9',310457000,NULL,NULL,'98ec59be52a25312a01f4beed9453dcd2d8853650a0462a0c94dab34ca071b96','92940e49a49513e855e0e574e0bb3e572a6ed0783be5e8fa445c0124f3a3da1f','d658a78f3adc72787026dede45d6b23c77c78e58cfe8f31a6216c87317054717');
INSERT INTO blocks VALUES(310458,'deca40ba154ebc8c6268668b69a447e35ad292db4504d196e8a91abdc5312aac',310458000,NULL,NULL,'bffb43be7076d19d21c0b3e591389486da63cc83764df98b627442b9b89b5afd','3050f919d0e4c00deee76b891ffc8486fc3324d3a0bb496af55b0f2030089883','310460e0cae4ccc0da13ab266c21d8862a98e034cbf2b1a89f5683903268c4ec');
INSERT INTO blocks VALUES(310459,'839c15fa5eea10c91851e160a73a6a8ee273a31ab5385fe5bd71920cbc08b565',310459000,NULL,NULL,'37f2b35960170be831603daa9adf8e29cfa48b944355785e332af54560103837','86814b166033c625b4991431178f8f8af6901ec9838f046b9f593cdf76b700c8','dec17503b58b88ba6c28f734029bf26301aac46aa78c508c3cbfd7e911ff0ca6');
INSERT INTO blocks VALUES(310460,'9b5f351a5c85aaaa737b6a55f20ebf04cafdf36013cdee73c4aaac376ad4562b',310460000,NULL,NULL,'e517b733f527a4a2233e633224b6997477c9b8f5467d75c972c18763f2481789','1726c35a9778a0b071ede52462881355ff56a2f477bbc36bc76ddfd894def9a0','9ad74ec4bb8fe4bfd6f1b11da3e46c2300b88da59f6d5f56403cd3faab765425');
INSERT INTO blocks VALUES(310461,'8131c823f11c22066362517f8c80d93bfc4c3b0a12890bdd51a0e5a043d26b7b',310461000,NULL,NULL,'578adfbe61a549f75e2857cc5948d9c0ca07bc602837e89627273809e591a617','224993f2b68bb2ac542d770885dc93a1e5ccc3bad2543113e3ecf729ce8647f1','ea31d01a6fdb975d2536dae99d587eb038eed6a7e562be6370cb41f1d8aa89cd');
INSERT INTO blocks VALUES(310462,'16f8fad8c21560b9d7f88c3b22293192c24f5264c964d2de303a0c742c27d146',310462000,NULL,NULL,'328514ca76de0af23fd653c2e36ebb5793a6897cb2e71ebb55837f6f806cd0a6','e837c771e1dc66e59c91199396075c75a2fb53d8a23085f3bb82913834c55a8e','45614c3ae0762dd11633bf7c1edbe23e9d7ca489c21238b7a1de204ad4a44e43');
INSERT INTO blocks VALUES(310463,'bf919937d8d1b5d5f421b9f59e5893ecb9e77861c6ab6ffe6d2722f52483bd94',310463000,NULL,NULL,'9b910cb03aa788f20d12044ed64711d8455a8785ef66e46873e6dabfd8cff12e','6381d56d5008a018c12d062362918855896c91cf7883627115fd3ee54d41c78c','d5daa2be76b039f28ac9235804d7380cbd8c4cc15c3b8226623b54c91516c913');
INSERT INTO blocks VALUES(310464,'91f08dec994751a6057753945249e9c11964b98b654704e585d9239462bc6f60',310464000,NULL,NULL,'2fa5dc745b2f66e479da0787354560e27e2fb17cff09bf3c92f309e9423cea4f','0b1a9b4e7757069f2f351a541743c389d3efaddd2791fa69086bd2ed1779d440','61d792516da9a08d04cbb7443eff3562c81d3de64f1b6ef1bd840e7c81a1231c');
INSERT INTO blocks VALUES(310465,'5686aaff2718a688b9a69411e237912869699f756c3eb7bf7c3cf2b9e3756b3d',310465000,NULL,NULL,'5f8c8b34b4127ea7ace5597c3c1bbbe60b78aadf1ba1d5368a09e0f2d24d953f','771e054770448a9cbd77484b1ffdbccbb71b1b3b6a8844c7ff1cd1aa74a9ea00','e89684a1a8ac353fede50b32cac7d6b43738d3de02c4a45d1e722162369d9c4c');
INSERT INTO blocks VALUES(310466,'8a68637850c014116da671bb544fb5deddda7682223055a58bdcf7b2e79501fc',310466000,NULL,NULL,'ad2dd38170fc92eecb2949bb8de632975f8ac2c6586f263bfbe19f5b3afb0cac','84e97430af5029b3eb1ca76fb4fc1e57cdffc3dbaa65b601c3001e22f3d6c937','27eed7b5d19d87908294c0b9d8c46b317b2eef22e8a2ff56337d6f8060b73b21');
INSERT INTO blocks VALUES(310467,'d455a803e714bb6bd9e582edc34e624e7e3d80ee6c7b42f7207d763fff5c2bd3',310467000,NULL,NULL,'ed102aecd85f3f6a2c0e70deff510cb7c7dcb061c1b73c83783bbf36feff57f2','944b48d70fa027b880275a1be8e1cfdc1d9d4fb610798ebd4e6499bd4a177163','7dca2b46a3aa34a9a53d5bf893efe3eea48f66abb7d800d990cd7eb72da81561');
INSERT INTO blocks VALUES(310468,'d84dfd2fcf6d8005aeeac01e03b287af788c81955612375510e37a4ab5766891',310468000,NULL,NULL,'a6c9138102d129fc6f52522a6cb93d89ace3f3396ee8b8bcddb141185678107d','d887e7b7a1da87fda43fce08a787e5e02ac58949c4d0314aab15ff62a9692125','958f9711eb4f4dbbb4d558383c320297cb1d272b7e8185ca13d39af2f114d52f');
INSERT INTO blocks VALUES(310469,'2fbbf2724f537d539b675acb6a479e530c7aac5f93b4045f4356ea4b0f8a8755',310469000,NULL,NULL,'ca605be6343e8e34bee9b1279480dc926c8743de838253c51fe35d88fe51f225','83bddbc6200f0ae4f7bb89157addd32e3fa295212e2a65b073ca230a1c6a4c87','6c3ae20e85eab37b643f17e53e4a83a5be2529a261f4be856fe96587df10fdf6');
INSERT INTO blocks VALUES(310470,'ebb7c8e3fbe0b123a456d753b85b8c123ca3b315da14a00379ebd34784b28921',310470000,NULL,NULL,'2d8077790051f85fdb5892e4d28688243a455c682400f4e7d565796ba9078575','7fce41a2b491f220e4dceba25e84d9dadaf074adef68ae6c40129e4e3c3b9383','b61e9f8eef386b8ea1cdf6b0021ad1a454128ad7581df6315827f3b3083e2ebf');
INSERT INTO blocks VALUES(310471,'fc6f8162c55ecffeaabb09f70f071fd0cb7a9ef1bccaafaf27fe9a936defb739',310471000,NULL,NULL,'1670b4229a52d9f2d674be38ec48930f407d376d2a929319b2b83ff1a27c2dcc','791d056028085258a2d8ef58a4743c0c1f38e9b498b1f3e59a75000be9eaede3','d644b0fda33af73b7478208d33fa0fc01f1bad56b57dc98de6778a0fd2363b9e');
INSERT INTO blocks VALUES(310472,'57ee5dec5e95b3d9c65a21c407294a32ed538658a6910b16124f18020f16bdf7',310472000,NULL,NULL,'6ead8d5e552978d1bd5b15ef6e3a00b2f3ab0e78a1d9631494737ceeebeaf67c','18c993a27f80a74709096bff20243384d53d4246634c358a324cd8c291d28e43','cd94bae50c4127446d4f55d686e61a37ae88f89dad8024ef1f15cbc513dde372');
INSERT INTO blocks VALUES(310473,'33994c8f6d06134f886b47e14cb4b5af8fc0fd66e6bd60b3a71986622483e095',310473000,NULL,NULL,'be5ea6577538c6118843565ad64d9b428c40412c5aacb0558ce57961a3a222da','280f22e5b50e86c2e9b5d66c56b3518414b5a02858ef88e6f6602143738ec2d4','7a8fdfeaa01da2515f84eba74a053a41798760939269a5906d2c47fe0a7c0e4b');
INSERT INTO blocks VALUES(310474,'312ee99e9526e9c240d76e3c3d1fe4c0a21f58156a15f2789605b3e7f7794a09',310474000,NULL,NULL,'427db643d3100a02dcd8ec52e584b50b7f33c95eacb5e527644ec6ae9f8cea78','7422a142a8d4730f90122bbed3b26c165cc29be907d520844c3961c5970aeec1','8bdb7962ea8553d1d1f0b3a776d9676f3d5cd8e569ce1c52e8ddf687a262f6d9');
INSERT INTO blocks VALUES(310475,'bb9289bcd79075962117aef1161b333dbc403efebd593d93fc315146a2f040eb',310475000,NULL,NULL,'8aef3df780b591cbfa5abf10583fa08c6a9fe913a26ed00a7bb262ae49b5a19c','69caecb3c4c78be6e396d47e7dd005c68408849f382ac3ae9429daa3cbbaa44d','0515e606f915b49a3cdd5b18b6f318fd21aaeb4a1ec89af6f3120496453cb99d');
INSERT INTO blocks VALUES(310476,'3712e1ebd195749e0dc92f32f7f451dd76f499bf16d709462309ce358a9370d0',310476000,NULL,NULL,'49ad08b037568f474ec2ef5c6c2a65e96ab87c8d0138280fa01c58ec623cf46c','384c136be6b15ae46b0d4b774dde8952fde5daedbf06db4e4ba853fc8ca3a283','18ac031dceeac3a83805a65666e57c4bbed879e4c72b9a8f0dcb84707c1fdf8a');
INSERT INTO blocks VALUES(310477,'7381973c554ac2bbdc849e8ea8c4a0ecbb46e7967d322446d0d83c3f9deab918',310477000,NULL,NULL,'8efb10353eae5ec256acf724d2ed1191740e8d74da64f77ab435cea42538f1ae','28e4558090c289d5973fe0effa6dda01c18cf28e16167ab23dcbb9db39fc4fbb','5f525590ddfa1748874f4c0aa25486000e806cf465bf33e8c3d21ef4f7ad5c54');
INSERT INTO blocks VALUES(310478,'c09ee871af7f2a611d43e6130aed171e301c23c5d1a29d183d40bf15898b4fa0',310478000,NULL,NULL,'037a496419364989ebb97e7364215f6a790f80e7232692d2c2186ae208b48f9b','cbe589536c89caaa8a7c9b9a7d09f46a177e1eeb3e84cb0d97e850997b130f0d','b612f2ed9f07348da84b13e93ffc501e421fdb02eff9d611f9c69eaf243578a5');
INSERT INTO blocks VALUES(310479,'f3d691ce35f62df56d142160b6e2cdcba19d4995c01f802da6ce30bfe8d30030',310479000,NULL,NULL,'5424cbb3aa1a000366814fb8414a9241aebe56349bd05a10dcc8b89d46c94484','b6df34ca3c574b18637e5f89524598be17c6ca22edf129038936512599fa2455','4012d2f54bfa9ca054bcb9e5c071b823d25dcf21b742b6a1541ecad93d3bc469');
INSERT INTO blocks VALUES(310480,'2694e89a62b3abd03a38dfd318c05eb5871f1be00a6e1bf06826fd54d142e681',310480000,NULL,NULL,'85e7ae716668f124f3b6ca80a969ebd8b56392c4e94bc644fcb678ecaf8afa94','78d30d7dc9245cba8b35e35ea55e9099a1bfca117348bd8278261781c9582386','34aaa09c951cf55fb8f455ad796a50460cfdeb319c84b45d3df7f5d04698ddd4');
INSERT INTO blocks VALUES(310481,'db37d8f98630ebc61767736ae2c523e4e930095bf54259c01de4d36fd60b6f4a',310481000,NULL,NULL,'7a46d1ce392ed7ece3f5506f221ce9feb5c92e7a1bba1b9ef0ce7571f5f85ea2','21ba0653d5f4cebde982620bd8c23d0364d2eb6ba75d6f224ad70e05a140a7f4','53eee0afdbfd03131dfa2056fba757a973bd9d1758f31c285243996258298ab9');
INSERT INTO blocks VALUES(310482,'2e27db87dfb6439c006637734e876cc662d1ca74c717756f90f0e535df0787d6',310482000,NULL,NULL,'dcb41a29a41cf93cebc588e55efd94d774bfd59569e9838d4d24f6d0fe77d75f','dada1a93d460a14e887f98c3da2227509819e34befe59e2fc1bbb845f34b36a3','f30f7e2997a95b470b1f0c154136c19ae29449139535bb2ae76b27280dbebde7');
INSERT INTO blocks VALUES(310483,'013bac61f8e33c8d8d0f60f5e6a4ec3de9b16696703dea9802f64a258601c460',310483000,NULL,NULL,'8725ac94690efc501a622978f2c368d8b81362e5bb8e1512ad518629c0da160e','76e03b4891cc64c6b29249b353a055c17b7ce102e0330b193e06f75661551df4','b7ecea28cfb1557343a54e22b3bff3fa07b3ade7d029ac8e7e102b9fa5864e6c');
INSERT INTO blocks VALUES(310484,'7cac2b3630c31b592fa0497792bed58d3c41120c009471c348b16b5578b3aa2b',310484000,NULL,NULL,'170510c22462049c301e568f34e803e707fe8f1cd4cae594ea443062afe220a1','8b10b5a69f91e16dd0a5c9a0a15c589d6548fb435a162abb1f554f8f1558e98d','eb3a32a5552b864919d3e6202b716b165950a249a3d9ef435c9eae35f1abe95a');
INSERT INTO blocks VALUES(310485,'eab5febc9668cd438178496417b22da5f77ceaed5bb6e01fc0f04bef1f5b4478',310485000,NULL,NULL,'5e7252b1db07de62dc373cbbf5f50a2bcd106d17e9e86cb6454cef3263b80d68','318d9d2547884a989472ce68e05b81f53dd8437c9f54e5f290c3a5823d04786b','e810756875116e3316f77f2d954d6169e9bf03242b0481537e5159c90a6a8cd4');
INSERT INTO blocks VALUES(310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,NULL,NULL,'ca03e462a958cac268c725ca972097a78884fd74d48d9ae8d437bb5e4a9c3637','df9f7f852c848a1cdf6360e497cd35f157df51f260fe15f45dbe1b648fb79de0','62615c34a7ad972741219344ef01f179a65d7787e93a4d1daf2ff89327fef48a');
INSERT INTO blocks VALUES(310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,NULL,NULL,'cd076808fe1def56a9c8653071fa7472819a73aa5ca7124a8dc3b918a72658ec','6dcb84a174003921ff647e5e342af19419ae061ce9f9db7091dd12d7c98f495a','74b146c0aba4c548958a1687c141e8bed316d5fff595c8d7a2f4862f25666c15');
INSERT INTO blocks VALUES(310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,NULL,NULL,'10d3dc3a0050cc7bdcffa8e49c0f1f40103e19cbfab705c93edf4dcce53fcb04','4a165dc9054c33a65f1b4a7a56160bef6d3e1668f421b6ab08539841d28192d5','97c2dce2c8c11791d42fc0c651bbf63ee0916b744ff2428c9b102a8216d3af99');
INSERT INTO blocks VALUES(310489,'2efdb36f986b3e3ccc6cc9b0c1c3cdcb07429fb43cbc0cc3b6c87d1b33f258b6',310489000,NULL,NULL,'88a40894fdc2f663078b4a85df75207c2f67d2357f02f7cae34e8ec8ea8b4f8b','22d66598fdbf33bf21f0648fb3de444915c1a254a5fa89a6375640067e6543d7','4d8b43b3114591576790aaffe6f9ff1e5b2f2abc6857ef30f5655c6f59a4cf11');
INSERT INTO blocks VALUES(310490,'e2cb04b8a7368c95359c9d5ff33e64209200fb606de0d64b7c0f67bb1cb8d87c',310490000,NULL,NULL,'e3e54f0503381ce795baaba2ee9217f340b88a83e7e30c9482b240120b602f77','b2f8d2f603e7df250ee8c8d872001896950c70cada1bae552f3ceb1ba9982eb3','5d076c98c2a148824fc70cae18bf8d76c0e4cf626a6674d07cbce12aeb8012ed');
INSERT INTO blocks VALUES(310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,NULL,NULL,'afa15f23ab58d8e7d9201adc25f91e16ec65619efe9a007552db6184d51f87de','b7e72445ddf32cea70ce5b3a68c863963e569e7e9d8b741d4c95672ffda4b06f','ad499dbd6817cd293322cdf2d19ad19e32f4a9d2c477d06c631cbdda961c1ad4');
INSERT INTO blocks VALUES(310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,NULL,NULL,'e94f2dc7e0d8e15d81c44ce18b1bd19b54112386510e42b5b8a446731efaa563','35fb747fa8d3b865ab9069b77687d29527885c39e6ab5cea762fd5f55abd8c4c','dfccdceb39deb129713d20ca5aac8b78af7ec6c527f942ce30ce6e889eb64cff');
INSERT INTO blocks VALUES(310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,NULL,NULL,'18a9237d2ff197fce36fbe5ab11280aacf5ad97f6149aff9bb19693edc973657','555db01fb67bbf1067e2b3dc0addf05cad4a8e9a60221bdc03746b7fa3a7147a','539356208a984308345f1aa2bf94f98a43a07e4f584cf9db3c1ffef7b269f1b3');
INSERT INTO blocks VALUES(310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,NULL,NULL,'3a4bdf7ee155cee986f2b4fa4b1da63ca0933c2b242b36bdf442b3308a2fb091','38dd58f20121e0c7dfda49d2ba241e5b1b297ee9afb84f242e65e157a5acadfb','70bfd7881ffcdfb247bc25f320f1160209389af19d04f4dc38d8c8faceaf7b18');
INSERT INTO blocks VALUES(310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,NULL,NULL,'b48bcdad3120081198cc592cf8c20d0922341c51cfd9eb52ddae56c3d1cd549d','bcb22ba5ce79e1b2c486959797eb7ffeb317e1a114d8ee33696aba2927785c86','c9d767cc50b4cf1d1653c5277aba4d6a2b0474ec5dd17c60655fe3a3b4fa03d0');
INSERT INTO blocks VALUES(310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,NULL,NULL,'08ae15edda6f2caf121ffcdc88d059130a40f28294f4ecbc7ccbc86f337727d4','edb6f25c1d1494207538a9f9c20db2aecd4c1f7b68f8565d8cc34c89b1c91224','845af706ccc2592b90cc9a6f4a9cab5d3c9044c69931be8751faf447aacf4d74');
INSERT INTO blocks VALUES(310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,NULL,NULL,'c5f88552230801b43499dc04a881d691f6e81541b0250d015dcd08027038f966','43b38077ae45ad148cd8b930c60c4b0228c699ade727597c41266fe3da6fa7a3','fcd7475a7a551beb6f673c2e840e7eff9a6b86ee6db7796cceaee33083c1c69e');
INSERT INTO blocks VALUES(310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,NULL,NULL,'78b6aa075db207273dbbb29fbaf6b2b95151cd3cc90323898562dc60af23ab29','fb623d6f512278ef156dce4de5be7fdd661c1bb29de1d419985f2c94c26536ec','d9098149553dbd1d0958bc529959c91816e31fe04e97b5507cdc0c022145c34c');
INSERT INTO blocks VALUES(310499,'1950e1a4d7fc820ed9603f6df6819c3c953c277c726340dec2a4253e261a1764',310499000,NULL,NULL,'99c310f627b2dc12e666cabd7af3658921e21b00a10650287214cfaabeb08423','d6609fd808a32b84394d1a060add9e12138f948d0cd3a2d5190beadd52e77e29','bcee7f29facc599b0bd1e7c29014eb6f0114c6a9742a83395b059b9525e0ab60');
INSERT INTO blocks VALUES(310500,'54aeaf47d5387964e2d51617bf3af50520a0449410e0d096cf8c2aa9dad5550b',310500000,NULL,NULL,'398c9834454c2b8c803a83498992e5cd8f276308d72b54edaee56ac1fb27ce92','92ae06276ecb2cbb5d974c2974470cdb0a932c4bdb8dcc4b479c7c44c638c649','485b6dd30f0954f5932815470756d2cff2fa5507e6d5b6378d4358327018b0e9');
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
INSERT INTO credits VALUES(310102,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',9,'bet settled','18cbfca6cd776158c13245977b4eead061e6bdcea8118faa6996fb6d01b51d4e');
INSERT INTO credits VALUES(310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',9,'bet settled','18cbfca6cd776158c13245977b4eead061e6bdcea8118faa6996fb6d01b51d4e');
INSERT INTO credits VALUES(310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'feed fee','18cbfca6cd776158c13245977b4eead061e6bdcea8118faa6996fb6d01b51d4e');
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
