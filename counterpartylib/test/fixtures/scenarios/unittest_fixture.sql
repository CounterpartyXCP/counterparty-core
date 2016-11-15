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
INSERT INTO bet_match_resolutions VALUES('c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d_85c91b9de7c50d74ef9177c748162b99084ca844f3eff48405c2c7918ef78035',1,310102,'1',9,9,NULL,NULL,0);
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
INSERT INTO bet_matches VALUES('c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d_85c91b9de7c50d74ef9177c748162b99084ca844f3eff48405c2c7918ef78035',20,'c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',21,'85c91b9de7c50d74ef9177c748162b99084ca844f3eff48405c2c7918ef78035','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',1,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000001,0.0,5040,9,9,310019,310020,310020,100,100,310119,5000000,'settled');
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
INSERT INTO bets VALUES(21,'85c91b9de7c50d74ef9177c748162b99084ca844f3eff48405c2c7918ef78035',310020,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1388000001,9,0,9,0,0.0,5040,100,310120,5000000,'filled');
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
INSERT INTO blocks VALUES(310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,NULL,NULL,'3393abc111ee337132103ca04b4f8745952cd03ddbd6efff58a589e00a48fa21','b0e3aff20a8f7a1c3ad6c53a5636815a494357912faeee861263b9ec59558f71','01f25c6f12f3c7291bd7391df2fff63660a030b8bb08d37d0d243ab4aace3b09');
INSERT INTO blocks VALUES(310021,'7c2460bb32c5749c856486393239bf7a0ac789587ac71f32e7237910da8097f2',310021000,NULL,NULL,'d05fe9705db7b30e6ea6b18e9ae92ba794dd72f25b4e33daf4d46b3b609a02de','e3b426cb9cac5c5297bb0ae6518ae31347e0d09fb3d690f559bce0f2b51f2ec5','1c7618686e81323beb743d30a60c6d7f8e61d607b610b12449ece6c6bddb1d5b');
INSERT INTO blocks VALUES(310022,'44435f9a99a0aa12a9bfabdc4cb8119f6ea6a6e1350d2d65445fb66a456db5fc',310022000,NULL,NULL,'c2b2b2c3bdd895c74f3ea22db3d9c66301578436b6fa9175ce0b242c4bfaccc5','56fdbd02e2230da9daf06b69402c4be4d1084a45097c7c92c904975afca96d2a','5a900a151523e219cfe74e05671d81f1defa5735718e22a604b8a3da58babc46');
INSERT INTO blocks VALUES(310023,'d8cf5bec1bbcab8ca4f495352afde3b6572b7e1d61b3976872ebb8e9d30ccb08',310023000,NULL,NULL,'fad5b61545d8ef317918f07df063554d4f321c0ebf462f759513212960bdf523','3f267a12eabd1bcab090898242adb1f254aaffacc3af575e8eeb231d9b240533','859b377ef6852bb1defe60aa9c0041ce61d08771bf96f0326ff3984b0515c62d');
INSERT INTO blocks VALUES(310024,'b03042b4e18a222b4c8d1e9e1970d93e6e2a2d41686d227ff8ecf0a839223dc5',310024000,NULL,NULL,'61a71d0ac67eba15c63a531f797e6d68c83613489730bc2b4e4054094f63105a','fd88fc3c9e9225e434a0dcfa7c56cd39d6753b9a045f934ae3ffd84af94618e5','167d1b5108d5c2c70545877c5c081dac4b94233996d1b8cb855324c4f6dec7df');
INSERT INTO blocks VALUES(310025,'a872e560766832cc3b4f7f222228cb6db882ce3c54f6459f62c71d5cd6e90666',310025000,NULL,NULL,'f7d41404c3d1e57bbc390af958d1596212112068e4986954d11ff8abd13bc8e4','b9773180aa064a66f7d3f6ff9f54b698847f4723fa67a47086f8d9dfc96e2da9','373436bb047587fec822bfa05902a78cb964e6c2bfdd3b3e01e99b6b877fc1c5');
INSERT INTO blocks VALUES(310026,'6c96350f6f2f05810f19a689de235eff975338587194a36a70dfd0fcd490941a',310026000,NULL,NULL,'31530d7febb577d7588e12d10629fd82966df48a93a613a480879531d5dbd374','50821659994e9917fe36b6c8fbb69cc2204e9f135334b6dcb71e0ded64c26104','5cce19d2bafb9b8ebf7a4abead8823e923ffc7b23dc20dbedb08a7ef4f8b161f');
INSERT INTO blocks VALUES(310027,'d7acfac66df393c4482a14c189742c0571b89442eb7f817b34415a560445699e',310027000,NULL,NULL,'f54085346ae4608c57c55d321a413a00ffeb85499138559d7d05245f57cc0da3','86754371ba34bd801fc8d92462dbdf4f8ff437c5c1156f01f53f68a942323484','f56e67e95a511289637c93d69ec6dbdbaa8ea739e72b99ed4ae76dcea8cb9509');
INSERT INTO blocks VALUES(310028,'02409fcf8fa06dafcb7f11e38593181d9c42cc9d5e2ddc304d098f990bd9530b',310028000,NULL,NULL,'a841b7f634fc24553d1c8cb2d66fc3103293dcfd297cb5bf241b0c5da84bd376','ef69ba6f1ee8af8a76595497d223336c04b1329eb5cd230536589b9343dc1806','5e8503f055cc28f29a125728e8ac160307563aa5d21c45f9c737e2d912bb02d8');
INSERT INTO blocks VALUES(310029,'3c739fa8b40c118d5547ea356ee8d10ee2898871907643ec02e5db9d00f03cc6',310029000,NULL,NULL,'69d40c69b4989f7a59da99b56577b0651887d9422757e38d5410379f95fda641','2de123c9096ac925e4b508cf2d97981e071c02ceb0b29280667ec0109d022f9a','f9fd4627308a060b4870c9a7293db33bc4bb4ea18a06441b091bfb1daa00d207');
INSERT INTO blocks VALUES(310030,'d5071cddedf89765ee0fd58f209c1c7d669ba8ea66200a57587da8b189b9e4f5',310030000,NULL,NULL,'192fe51d3a7af659670a8899582c29aedf3a5608ca906b274ce986751dad2d7a','22ecf7b3de15f3e78bdc3353463251544203d5eb51d51e3a53b41147bd188933','02a3b3ed8b7513e5cf1b08c454ac08ed70abd451b3e8f772bcb382cfaf8ff3fc');
INSERT INTO blocks VALUES(310031,'0b02b10f41380fff27c543ea8891ecb845bf7a003ac5c87e15932aff3bfcf689',310031000,NULL,NULL,'125784cdeba1e433b3411c368cdf676efb33021f51c26a8b2bd6ec00fe4f767d','df1a9846248d226be7c8b57fb399e256f0ccf4df45f552e76b5e4b10c150cb2e','5d8aa8418c9088364035c30e1f2c4a7da5c013f7c5f2cc1d72028c2232ffc519');
INSERT INTO blocks VALUES(310032,'66346be81e6ba04544f2ae643b76c2b7b1383f038fc2636e02e49dc7ec144074',310032000,NULL,NULL,'fa7832080a2b6ae8829794d70603351755fa4816f15a6e92716f83265daa59a4','78d07710b6dfcd15b389f794d4f2861ab738b211cd1476ce5fdc7d776e38e9ff','fcc78b63b47bd189a8db0cec41f641cb224c35bbb6c0eeb82dd3ef7439d1d0ff');
INSERT INTO blocks VALUES(310033,'999c65df9661f73e8c01f1da1afda09ac16788b72834f0ff5ea3d1464afb4707',310033000,NULL,NULL,'7b86f430bc44ad5d81a43b5a8ea118b458d995e3832d88bb74bc62429194e45c','05c9116d7d79822881948729e7434868d9c37326d0ba2727af22406efe0eb50d','8f12fa1f1d52cab08b8922af30e172d5bf56934ec3afa17a4aa299105bd36120');
INSERT INTO blocks VALUES(310034,'f552edd2e0a648230f3668e72ddf0ddfb1e8ac0f4c190f91b89c1a8c2e357208',310034000,NULL,NULL,'1f2c5ac4375f77fb79612d343dd5fc4489cf94ff983fc05ba2009a9e390d6c06','4f1bd661ff4bc3763ebbe57a9f235d336ed064e784467f9cda3768060b4a2164','5c85962e54dd7a0f1ff4859bba261a8593cdd078a21b914031f86f6d35cc4239');
INSERT INTO blocks VALUES(310035,'a13cbb016f3044207a46967a4ba1c87dab411f78c55c1179f2336653c2726ae2',310035000,NULL,NULL,'81cdae9b978935ad40a1032e7f22ddd7117b9c7580d6d7e4b7e20d1c875f5e63','4c5019d7f9ba6433692406fba4b274561ef58d9c7eaa5e5f07476e5344997cc5','7bb551db2bbe0592495d33e7090a6b8b0cbcfe1f08b824fc12e5d2d8de9c964c');
INSERT INTO blocks VALUES(310036,'158648a98f1e1bd1875584ce8449eb15a4e91a99a923bbb24c4210135cef0c76',310036000,NULL,NULL,'ff02952dce15c249501d8485decad0ad9fe02fda766b7b83720806f726d02ee4','a011920efee3ce43e53972c6726ee94623880fe6f0dc67389ada8b28f3356e81','2e95174c16bb924f955f3834af26d666b090b5991dd67862334aa38689f31773');
INSERT INTO blocks VALUES(310037,'563acfd6d991ce256d5655de2e9429975c8dceeb221e76d5ec6e9e24a2c27c07',310037000,NULL,NULL,'760e5a00feb6c8c4baf4421ad07be2af962bfcac7705b773484b449356d6c230','2686009a36edcecb925ddf05bfe7fe2880eb970ec1f19bb11255b5c2aa7eb5b2','aac22e315efe333bae2d987ce82f5ac1b40f3055d7dcc73155c375a294760a01');
INSERT INTO blocks VALUES(310038,'b44b4cad12431c32df27940e18d51f63897c7472b70950d18454edfd640490b2',310038000,NULL,NULL,'c79381c51fa93cc320d8bf19c943f98232a99446ac098ff66823cf691e0fa01c','3319502330393689cbcd027ddf24f4ad8c80ae0bc98f17d3f49a1e9cf78259fc','95e2ec53a20d6c86bbeb84b162c4b7d7e036ceec1ca2e8cdff3521fbcf337220');
INSERT INTO blocks VALUES(310039,'5fa1ae9c5e8a599247458987b006ad3a57f686df1f7cc240bf119e911b56c347',310039000,NULL,NULL,'7382f007315783c9a6ffd29bc0eaa62282c6ec72c5fff09322d6dea6b0ee3a96','788be45e08cf9654e0c0ca136f7ff4550e7f0334de9506193c98713b1b4b9c8f','9ec877e1e84a08a13234aa798af71004705cb925ca71dbf3baa614caa1b5de08');
INSERT INTO blocks VALUES(310040,'7200ded406675453eadddfbb2d14c2a4526c7dc2b5de14bd48b29243df5e1aa3',310040000,NULL,NULL,'38d3b548be554a0ae92504244a88930b989ea6fefc9bc59c69b68ed560afee9a','a2acea73e2341736396c21d1e20f22c56f9e5a400a04a3fb0f0d34d6a2c067cd','c2dae4cbc1916649b8a88dfefe78d17c9dd91f8ddedb73a336ac6f770c06d21f');
INSERT INTO blocks VALUES(310041,'5db592ff9ba5fac1e030cf22d6c13b70d330ba397f415340086ee7357143b359',310041000,NULL,NULL,'0c1c7aa19c015a67da214bf8a6ae3d77979a09de6a63621e320a28ceebdbf333','e14a4f117bd91679934727b53a11874551961d3059aefe1b53d1bed957d1fe78','43f344fc6b696b6d9318cbfd48cda51eda46258d300919d9a08235a4fd543aad');
INSERT INTO blocks VALUES(310042,'826fd4701ef2824e9559b069517cd3cb990aff6a4690830f78fc845ab77fa3e4',310042000,NULL,NULL,'9d20f77d4afff9179cffe46574f1b2dd23d2987142c943de05e411baee2dbf05','8f54037ca08ee2845732739b95a14d06ac4817a336e32873ee17cf2a72850e4d','d499a66e0de783c179b7c7814d1e675a1dd498f995c1d1e20bebfff4f42b5915');
INSERT INTO blocks VALUES(310043,'2254a12ada208f1dd57bc17547ecaf3c44720323c47bc7d4b1262477cb7f3c51',310043000,NULL,NULL,'d818e5a1a5cb6c59771b63997a8737cdb041c3579de1ecd808a269f5d72a3abf','df4f8d519445cfd6810d2faf79781c471c7df69effe19bcb03f7470b2d80cd97','64bd507dbca1ca1c61854f2c249d4186e7edb02f7eb5ded1e9b328dab6948a54');
INSERT INTO blocks VALUES(310044,'3346d24118d8af0b3c6bcc42f8b85792e7a2e7036ebf6e4c25f4f6723c78e46b',310044000,NULL,NULL,'9de166ff18c5eec97b838292ae894ce18e5a890e8a841a294b2d14894c60a0d7','4b925882df5e929f665170281e01a0bc203098a2a1d5f04cd911b4bcada295a9','2fb8cd579124ce9e7a510c65957c32227693ffd5914f2de8207c176ba5a8ac50');
INSERT INTO blocks VALUES(310045,'7bba0ab243839e91ad1a45a762bf074011f8a9883074d68203c6d1b46fffde98',310045000,NULL,NULL,'bb3c0a260dc082534c95e894751e38e80de117b091bc0e34c66134d374b8db2d','6a7e10538ad41da9ec95f39f6a1a417fcd176800de8cf76e821a942030f6a446','c0ad91a2a5d05e5f557752da666d912cd8c2a5d5cefbad10c173e75bdff083c3');
INSERT INTO blocks VALUES(310046,'47db6788c38f2d6d712764979e41346b55e78cbb4969e0ef5c4336faf18993a6',310046000,NULL,NULL,'b4605c50ee3e5e2958c908e099563cf997e20932cc2370109ab50049e43723cf','a3d26063ce71cc4ba225f1448f2338e5f8f86ed6c1465f45b5ee5cfc76e219eb','5bb81a3b2f2fe9da98d9cfaf08f8219644b57a9f7050c52109720f439786bf72');
INSERT INTO blocks VALUES(310047,'a9ccabcc2a098a7d25e4ab8bda7c4e66807eefa42e29890dcd88149a10de7075',310047000,NULL,NULL,'b840a7af6301c798c9a6670308a2684051ff8f3fb2e69bddaafa82cfd3d83186','8df3804787f786f79cfa1abfe7e38b7f5b69811e64d39c908fa2d20f1cdee401','efba7a19b5140ef29ae4b33f9e34aeadfc366871dadd11b39c971aaf741ca5f7');
INSERT INTO blocks VALUES(310048,'610bf3935a85b05a98556c55493c6de45bed4d7b3b6c8553a984718765796309',310048000,NULL,NULL,'6bd591d3336ea112789ad6675a9b1d8e1578fe42e44ca7f7be5557089d374c3f','81f0be1e29ac5baa6b3faa34a060b46f248972009ad467f08d3e7016a0fa499d','2a311c2b7e5053916420f92e3445e83f1105ecb7034a2b9ffe233230f82cbca5');
INSERT INTO blocks VALUES(310049,'4ad2761923ad49ad2b283b640f1832522a2a5d6964486b21591b71df6b33be3c',310049000,NULL,NULL,'04fe1e6631d503a9ee646584cda33857fac6eeca11fa60d442e09b2ed1380e5c','28a995918a248f8024c0f917d0f0aba643a7c5082c12a88d40e06683bc9aed2c','84729943a0ad9a6792ee52e62d6bc484a344538e8ff164ddb80c062d8c43a0dc');
INSERT INTO blocks VALUES(310050,'8cfeb60a14a4cec6e9be13d699694d49007d82a31065a17890383e262071e348',310050000,NULL,NULL,'dc73bfb66386f237f127f607a4522c0a8c650b6d0f76a87e30632938cf905155','e08bdfc4bd121b98679335a9254d82bab754a90a7851c8c3c615ffa9e5438391','523fdff1416e816b0e70bc630e3331e72556898b77e2cd9dc4382d36f4ba9cec');
INSERT INTO blocks VALUES(310051,'b53c90385dd808306601350920c6af4beb717518493fd23b5c730eea078f33e6',310051000,NULL,NULL,'e4eea2d144c8f9c6dfe731efee419056de42f53108f83ebee503c9114b8e4192','7fd073cb62615bf0e6020e23d5d49643c654c8360aaf80c41bf9e93f50e5b3ae','65e5dc4221c4e8da04caa540082afe924bf0ce9f0080f8d062e73b19f601181b');
INSERT INTO blocks VALUES(310052,'0acdacf4e4b6fca756479cb055191b367b1fa433aa558956f5f08fa5b7b394e2',310052000,NULL,NULL,'8d12b561e7cf87b0aabe000a93a57e5f31db75510b1e9feb19b4f557cc0e6604','637b520252ddc509c873ea6dd389a759c522d17982d88e592ace041551366838','74daa3b43243f82ccc91bb28bc90c34cf278eb88888a7c271c917af2d863dd79');
INSERT INTO blocks VALUES(310053,'68348f01b6dc49b2cb30fe92ac43e527aa90d859093d3bf7cd695c64d2ef744f',310053000,NULL,NULL,'f47b81b3dfc522d9b601d1776fa2deef8543ca077cb0743556cd970bb119d640','e07dfe0fbda1997d035e9b90ce0627939ca87780464ee883d000affa055b9218','4e293b33642acf1a4c5951655c059a89fce9a66c51b99c39033b9eebbab8d68c');
INSERT INTO blocks VALUES(310054,'a8b5f253df293037e49b998675620d5477445c51d5ec66596e023282bb9cd305',310054000,NULL,NULL,'df191ed877eb1856d6780a717c04d6925246cdee7dd6df74216ea983560d5a2b','59c0dada86cf22483943bdaebc30980624c69bca78aa8daa5f015940d384951d','7e7ff9e4b93d816bc4280f22359c3240fdaafc7dc933de15e268a5dbeb1cdaf3');
INSERT INTO blocks VALUES(310055,'4b069152e2dc82e96ed8a3c3547c162e8c3aceeb2a4ac07972f8321a535b9356',310055000,NULL,NULL,'4b0ab72111202b1f9a5add4bf9a812df203cb6761a8d16b5f7a8b9ed6f2b2476','363fe9a5e693674be7a0100d48331afc51303f8924e42bcae345d323332e0a04','5c492504ad49c579bab592ec8b1e93fd265c5ace4312610b36f69b13d28687d0');
INSERT INTO blocks VALUES(310056,'7603eaed418971b745256742f9d2ba70b2c2b2f69f61de6cc70e61ce0336f9d3',310056000,NULL,NULL,'8e76b5be6a94e1b50ba16fe265965d4cba01b792216485c54360052e78788f20','efe697778ab7171b90ab7bc494d986a4e644f308a56407d8fc71df5c670054a4','71632418309a85533701951b3a22d36bd81227eb323265589afd46870aca0868');
INSERT INTO blocks VALUES(310057,'4a5fdc84f2d66ecb6ee3e3646aad20751ce8694e64e348d3c8aab09d33a3e411',310057000,NULL,NULL,'e14dde2bfbe4f9076b7ba548aad37269752858361af094b4be8b956c0a28b9c5','8e9e892712870b386ede18158a0b26493ef748f022c4df637643416229345da3','3b8f360ee4b13f968d78b76349cecad27a2fa7341eaa0c7343c3190b56bd8850');
INSERT INTO blocks VALUES(310058,'a6eef3089896f0cae0bfe9423392e45c48f4efe4310b14d8cfbdb1fea613635f',310058000,NULL,NULL,'b986e5f6486ceac7f1af41b1da968e453cc19376d588d8e884439b51313d6e30','3029de1649fe95e49f57b6899ffd98e61a64eb8ce10a8b5a500049e365eff006','6f0c96f5d55fa6405c643918d5f1dc0afa433e50e98f7d180cecc9438c4270a9');
INSERT INTO blocks VALUES(310059,'ab505de874c43f97c90be1c26a769e6c5cb140405c993b4a6cc7afc795f156a9',310059000,NULL,NULL,'da978ee5b06812ee42cda43e1d9943c4e34e9e940cb0461f0ed463b9299402d8','c5bf914bcd66b98880bf35ed258fa17998ef5e52e3d9f45dd60c11e8946e2b7d','701b3670ee64f199671fa5e36243bbf3de81c5da554e67429a175df0d38225f0');
INSERT INTO blocks VALUES(310060,'974ad5fbef621e0a38eab811608dc9afaf10c8ecc85fed913075ba1a145e889b',310060000,NULL,NULL,'09ccea87988cc385b9d2580613581b90157f1366d27cd3dc1a4385e104430d15','a6d026aee8dab8e7c1956b269ce4107b7e2366f7c590de81e2deddfb9e91e9e6','30280dc678a5ff478fe633a2328b277f8f528e1f8a3b6e9939b7ae9adca337ff');
INSERT INTO blocks VALUES(310061,'35d267d21ad386e7b7632292af1c422b0310dde7ca49a82f9577525a29c138cf',310061000,NULL,NULL,'4caebeb5ab6468e116cc0cf137977649a15dd30d9b214a5081057a551174ec48','4160b0bb8ebaec8fd009d35a5e28769e7263cd7b6a37aaa3bc02a4daaee858c0','40f7f4afc4eaff0b370e5cf491f179dfccdd2f383decf63b60f605277b3fc6ed');
INSERT INTO blocks VALUES(310062,'b31a0054145319ef9de8c1cb19df5bcf4dc8a1ece20053aa494e5d3a00a2852f',310062000,NULL,NULL,'51cb3f1005127e3240721c47805d67a123afdc40084692a9cc2b3215cec99dc3','e2d1091a82e0453370c0b51b61bf669a835dbe2af55e24b5764d2d61ccef9463','515acb7db23714d490836036d43c431ff60a5b0c548f66a50bd649d865744d9f');
INSERT INTO blocks VALUES(310063,'0cbcbcd5b7f2dc288e3a34eab3d4212463a5a56e886804fb4f9f1cf929eadebe',310063000,NULL,NULL,'e12864a0f955320278c215897cf4f65e5c378e534294b0bb90ebd7e4b5efd4f7','a3cc75422bd5afb960701c7921bd1714ad37d3a46fa8d43e40ef91d96293abe6','46a737b0da76ec82b392acf819c6b7aab3b1181f1ad10863cd46381dfd89a67b');
INSERT INTO blocks VALUES(310064,'e2db8065a195e85cde9ddb868a17d39893a60fb2b1255aa5f0c88729de7cbf30',310064000,NULL,NULL,'ee27c3b46aa890d18be950006879874a094ecddd086db195e032fb4fe12559f5','ba3cbb5b9386858bd1d76327e6b875cc2115c3d5e7aa1c84853050e9ff474408','fca8b9c676851cca3ebdd3e9e3b425a62706b8c238f33d1eaa8f19f2c39ebc3c');
INSERT INTO blocks VALUES(310065,'8a7bc7a77c831ac4fd11b8a9d22d1b6a0661b07cef05c2e600c7fb683b861d2a',310065000,NULL,NULL,'d40dbc4b5faaf8918f9cae54e5a247e3904dc65994ce0f04f417c1a595404464','4b540b07c18bc72f3ef74221ca74c63b4be953d2dbb8543988106ab2a670fe81','9ddd31a35ca17fe450e3b004313317b4d68aef4d3624b2a0a19a83ac006dac9b');
INSERT INTO blocks VALUES(310066,'b6959be51eb084747d301f7ccaf9e75f2292c9404633b1532e3692659939430d',310066000,NULL,NULL,'19f2b00477a6fae0e10f4693d949cb409b1ed74ad20dbd9aa4a7f1f17cb813ac','871e655c915b2737750ff68604d5fe486132be497cf135fee6ee454c11ece0cc','e97ae109c6e0fb9bed8c952b2721a7b923ec7fd0e056300b4c11e0c83ee7c9b8');
INSERT INTO blocks VALUES(310067,'8b08eae98d7193c9c01863fac6effb9162bda010daeacf9e0347112f233b8577',310067000,NULL,NULL,'d72891c22fcea6c51496fc1777fa736ef5aba378320a1f718d597f8f9fea3c7d','04464cdad731a6e0e7fa460ba70f1df8750d46cfc96c74300a9d0ccfaad5651d','5dcf0636b10293f255b5db9fbe11f4a87dc71b0a063b880c58ae86740e5cd69c');
INSERT INTO blocks VALUES(310068,'9280e7297ef6313341bc81787a36acfc9af58f83a415afff5e3154f126cf52b5',310068000,NULL,NULL,'5793e10b8329d3ac71aed6347dfcf61fc7b74ca162ad99918f5c20065f8d0746','2327f3e394aad31a7c5b76aecd8fc055789328f793d635cf67ed9ef32bd86f02','93aacce0efc3971f45e1b82f601fd76a4749b49c56b8625703af29a9cce67fa3');
INSERT INTO blocks VALUES(310069,'486351f0655bf594ffaab1980cff17353b640b63e9c27239109addece189a6f7',310069000,NULL,NULL,'61040e7c1a58f41d708785347f4985c1fb522b6f947d3e14dacd91157e153ab7','37f1fce5ef7de162444e6480e26e62739668b959c74ab4e96e129739143fe08f','d1fb177a80d04c5ea285ed4f23f08a96a259c1e591f6ab29ee58f22d06831802');
INSERT INTO blocks VALUES(310070,'8739e99f4dee8bebf1332f37f49a125348b40b93b74fe35579dd52bfba4fa7e5',310070000,NULL,NULL,'ce115625fbda90a0f261b2c524108a7393078cb4c3f861d6d7846501c7960008','f8a12a7dfac6770978de591a0625c0e7a54985f23633ae63e4bdf78c899ba9d3','fd65a28804f2d7a0703dd4040cf69653f40e3dde62c96ca55a212568654d5ef8');
INSERT INTO blocks VALUES(310071,'7a099aa1bba0ead577f1e44f35263a1f115ed6a868c98d4dd71609072ae7f80b',310071000,NULL,NULL,'3c2d4d81e90a42a0c18e9c02b8a59f99e13f2a084ee66b4b1bd410077adc383d','29bd97dfc552587d609c61afc08281841e7e05027078fd3a1e0e15adff6de283','d40e1423cbc5f53d0466fe1c2bc00c0216a3ff6c60575a61edd734f071dd507b');
INSERT INTO blocks VALUES(310072,'7b17ecedc07552551b8129e068ae67cb176ca766ea3f6df74b597a94e3a7fc8a',310072000,NULL,NULL,'8a28e33306582346f1d965a0393621b4aa307f6614c84369064465f95a6c727e','61081fbc21d9ae367fb4521e0c44562faeb391ba762e7a5f164daf4b203d4c14','4f049a01ec77eaa2f6dc9ce95bc3cefd201f78bd2a3c6fc2ebb88da83541da94');
INSERT INTO blocks VALUES(310073,'ee0fe3cc9b3a48a2746b6090b63b442b97ea6055d48edcf4b2288396764c6943',310073000,NULL,NULL,'e6c5b393a21df54479c4cd8e991b37d877794166c19b9f61ad7e47eb34f63bdc','43e1a898de6885782cd0900e22ca33d6dd6d2caea7b69aabf24cd092365a1e3e','2f13ed59fa313d9f6f72805d465b932cab9fb2409ca7f0d3ed0ea43fdc2a79d9');
INSERT INTO blocks VALUES(310074,'ceab38dfde01f711a187601731ad575d67cfe0b7dbc61dcd4f15baaef72089fb',310074000,NULL,NULL,'b2db452daf280f1cc5f02668d0cbd33732a2fe9f04307d9c072eba97c95acf5c','7bcb30727c33f58718f6ef60320e8766f5d4e2828dbdeb696fec74733078b831','08343378a27ee5c131576c3de472bf0dd35376523ceb3195dbfee266276cbfa8');
INSERT INTO blocks VALUES(310075,'ef547198c6e36d829f117cfd7077ccde45158e3c545152225fa24dba7a26847b',310075000,NULL,NULL,'09998443cf1cd79e193a7b09681ae07ea9a835458151a7f8c7d80a00c5d8e99a','f2626e496d768acf9575bc56e3e4ac46cf33b68d4e77fb67c1516f5b349c05b6','a35b9d49a8032c28623bd097bf3718dfe1592ccfd6d9109f32ddbdc38a03563f');
INSERT INTO blocks VALUES(310076,'3b0499c2e8e8f0252c7288d4ecf66efc426ca37aad3524424d14c8bc6f8b0d92',310076000,NULL,NULL,'a0be1e88f10b5214f7c12dd32d0742537072d5eb3e54f9abf57a8577f7756d7e','1391b1cb7801a78522ec99fde21341ce6f5250e2a8ffb70450ceaad98714dacb','5d5d6da3722e6187f1bc8d951447fa1c63816d3cd9c76e227b47fa18fcb8beb1');
INSERT INTO blocks VALUES(310077,'d2adeefa9024ab3ff2822bc36acf19b6c647cea118cf15b86c6bc00c3322e7dd',310077000,NULL,NULL,'d41e39038756ee538d9438228512e31b4a524bbd05bc9b9034d603fd20e00f05','c4a3c711d8768957f6ddb96056abddffb026b88b21c3f2ca5049f14ed0eb7317','73098d0ae9da3da17bdc61995d070f730bd2c1e2720d13f7504684cd71177cd8');
INSERT INTO blocks VALUES(310078,'f6c17115ef0efe489c562bcda4615892b4d4b39db0c9791fe193d4922bd82cd6',310078000,NULL,NULL,'996092432a2d94df1db34533aa7033e672fac73de5193a696c05ae7c30d75247','4eb22ff54d6c22726db5cbcf3529bb3a311662a0bae4e63d4cf70f1280dbd0c2','ea1cef21ee4f9247624a7347e51c33dc2929c05622c08d103059da836bf7f319');
INSERT INTO blocks VALUES(310079,'f2fbd2074d804e631db44cb0fb2e1db3fdc367e439c21ffc40d73104c4d7069c',310079000,NULL,NULL,'e3f536e930e39b421e3a0566eba6b8f5f781ad1ff48530a5671752fd3eaf35ac','67f8c7faffa47ce85f1500395f323278b642afbd55343d76a1209ae46ba60aa9','2526016bd21556066e92e966d687b29b12d309ba559f889ce611c1a8892286e7');
INSERT INTO blocks VALUES(310080,'42943b914d9c367000a78b78a544cc4b84b1df838aadde33fe730964a89a3a6c',310080000,NULL,NULL,'57122dc41d7de2bdc65002905617c357496432fa4d80af48f4ca69ba1332e634','051e36d523a5729c72c480892942adfa552a5509d5e8e3f32552865439bd2680','44556e10aec095fd153f55b09d70f2b626451b10f86238cb3cd9ab8c6e6df79b');
INSERT INTO blocks VALUES(310081,'6554f9d307976249e7b7e260e08046b3b55d318f8b6af627fed5be3063f123c4',310081000,NULL,NULL,'3a0fc7b2f0396d257a0a5c5a313910cb4073e4c79ef8cf0d3cd12f494e563105','4e73f5b812285a117fb1724547cb6d2dd551f98158c6eecc0ff338522a5147a4','60225dd7b91025b63fa92fbdd86afea4313ccf8de70f507c193e4a12d5364636');
INSERT INTO blocks VALUES(310082,'4f1ef91b1dcd575f8ac2e66a67715500cbca154bd6f3b8148bb7015a6aa6c644',310082000,NULL,NULL,'e876c406f682ed6f0dbd6e4c97bac13409cd400b59e894eebeb3252be306494a','d98af322cec35eb24d81c8efed4c25f3aeaae9e1716864f399cd70f27572c59c','ca7d9d478186da0255f42f30114b70414b1bb84233bcd8f85476b11ef589f6df');
INSERT INTO blocks VALUES(310083,'9b1f6fd6ff9b0dc4e37603cfb0625f49067c775b99e12492afd85392d3c8d850',310083000,NULL,NULL,'533fc3eea80caa46cf8fd62745c5d21d09f32b18eaca70283a4bd72924c2100a','45d5ed16c56749ec00ecb9dbb5a1aa7c3baedb8cd393bf73dd83f7c2ec8a80a5','d8153a1901b64e97751b7e36c96d811602f6ad317771c16fd1b8ea2f801593b3');
INSERT INTO blocks VALUES(310084,'1e0972523e80306441b9f4157f171716199f1428db2e818a7f7817ccdc8859e3',310084000,NULL,NULL,'e3fd22f2e1470246ca99c569d187934f4b7bbb1eedb9626696cbaf9e2b46253b','888d4cc0710c5e42e9f85e524f7b7f9991859b76acd4472d612f2940de33213f','2268cf619f684e7d7eb6c43442cd5af42fd718a9fb683057d515dbcf19973181');
INSERT INTO blocks VALUES(310085,'c5b6e9581831e3bc5848cd7630c499bca26d9ece5156d36579bdb72d54817e34',310085000,NULL,NULL,'bf04750fe13f663adb12afd3a166636a4511bf94684a77217de1bd7ef9077d94','a6436bf5619196a903b24a4ac9aefd0013b0f23986a577722778448c2691f8c2','e000ef5b7e38f9026311be42e251a2d6911a2c8fb9df47f612cacb1c45c4cb66');
INSERT INTO blocks VALUES(310086,'080c1dc55a4ecf4824cf9840602498cfc35b5f84099f50b71b45cb63834c7a78',310086000,NULL,NULL,'a0e8403085ba63ba72432f27ce8125921ef24742f988ab7f85dd8e4309f27a2c','3d88814fcbdd39759764817a17e0051bc2a23b5d0a78366a6d313ae350ffd154','2cdd08f86507a5f49ac69b6daf73a54d1252f7009f92aa0022afb37c2739c29e');
INSERT INTO blocks VALUES(310087,'4ec8cb1c38b22904e8087a034a6406b896eff4dd28e7620601c6bddf82e2738c',310087000,NULL,NULL,'0861b02e980ad5958bd23ac02603b132efd72ee2a70dbb0415fa5d39cc524681','3e71e813fa194c698a5978095f606ec2153330b0332744a6f227a677af970b12','61492cb747535c0a6cda8c7b8fa7ad8cde42384c1f5ecf74a7f6b821f4c9f9a9');
INSERT INTO blocks VALUES(310088,'e945c815c433cbddd0bf8e66c5c23b51072483492acda98f5c2c201020a8c5b3',310088000,NULL,NULL,'d52cdaa449f63f6d3abc79080378855206f91a5db865dfaf37a5a2529ea6eb9a','6ba9446d36ecfe691320d94aa9dd469317bedf1c9eeb5762f82de7d8e1bd522d','c376e92dc4369559009cebb3c3f338003665f4ab34679d490e9357df6dab1680');
INSERT INTO blocks VALUES(310089,'0382437f895ef3e7e38bf025fd4f606fd44d4bbd6aea71dbdc4ed11a7cd46f33',310089000,NULL,NULL,'d15a7a60b8bf8618667863b3e31eaf6202664e5aebc16d1f7a337b857ac31f90','1e4c60e21f2df627f612b9a1755eeb2255d0cb9e5de0d670ba8793916a719ed6','1d613176515df59c83ad0238b4596c4b90e0846deca2146f93b10d8b651a4c9e');
INSERT INTO blocks VALUES(310090,'b756db71dc037b5a4582de354a3347371267d31ebda453e152f0a13bb2fae969',310090000,NULL,NULL,'68475dcfe8252c18501fd1fef2afa2a91d20b92cacbabb542c12f43403e66ea3','5002cc65575acba04d81583a103ed133b0917e7cc7f643c6a5648e7a12d10951','76404437de298c63915a73e0124bd40e8aab0cf7022d12f83e99521ae53bf443');
INSERT INTO blocks VALUES(310091,'734a9aa485f36399d5efb74f3b9c47f8b5f6fd68c9967f134b14cfe7e2d7583c',310091000,NULL,NULL,'5d584f255e5bbebc32c78a30fa816e1203fe7d3454611bef9222cdfc91dfcb63','ae6b7bb14e5e468171bff1ef7f3f119c545a524fa54542c4fd295f3b17e935fa','835d619574b04776fdf163a266193c49400a9c7f5f68a3fd26b6202393053616');
INSERT INTO blocks VALUES(310092,'56386beb65f9228740d4ad43a1c575645f6daf59e0dd9f22551c59215b5e8c3d',310092000,NULL,NULL,'ef992ad033b047b7f6ab038604736f444da55be187834f8152b173cf535c68eb','31ca4f3f91508f7807effc296fbae8c18dcba78315b09834f49367b8372db23e','50accd682707a39be758364a6f1a913d7369aaf10fdf7ffe4d17d018b9374693');
INSERT INTO blocks VALUES(310093,'a74a2425f2f4be24bb5f715173e6756649e1cbf1b064aeb1ef60e0b94b418ddc',310093000,NULL,NULL,'9cdee996d0e67ac3f9f283151b428ac5f223b72590965f41f93adcece6b88f2a','c459ca672b453578c6923acc83cda5a1a2b1435c6072143b3efef2036255e49a','136276a9c23144884ec9cf9922aa50a1bfe038832a622bde4c84e79fd429419d');
INSERT INTO blocks VALUES(310094,'2a8f976f20c4e89ff01071915ac96ee35192d54df3a246bf61fd4a0cccfb5b23',310094000,NULL,NULL,'fa25dc3f15fb28718d788f85373555966251f54bc6ed1f4dd2244b438d27b281','1c7f2c4de5c3fb2f6347151cec8552c3a332dd47b7bff67abbac3cbdb378ff08','707cec8a3e60df9da4255b52a106e304fc6b70490be39a23fce80a79498e63cd');
INSERT INTO blocks VALUES(310095,'bed0fa40c9981223fb40b3be8124ca619edc9dd34d0c907369477ea92e5d2cd2',310095000,NULL,NULL,'1ba8cd971f9a169d43b6de1a136cb8e6153649fde1f7a8e7fb2f7de926fdf8b2','532796a61355d2c59b8821ee79fb6878becd4fa11f58ca64b3a53673bf6b8bbf','e4b3149c207250286abd2e0cda843b256cdb5a58037b6e9a20a897563f245c60');
INSERT INTO blocks VALUES(310096,'306aeec3db435fabffdf88c2f26ee83caa4c2426375a33daa2be041dbd27ea2f',310096000,NULL,NULL,'42c36df2c53d762b9b132e622f52b2fca99bc0370978463acd22cdf6469587a8','f429790ca1b602d0fc243deea21a0715695c0d3af4b9db83a0a214101f35fbd8','650bcdf9be1b798f91c7722aff784ff5e634fdfd7865b40aa96c9b25ac8239d4');
INSERT INTO blocks VALUES(310097,'13e8e16e67c7cdcc80d477491e554b43744f90e8e1a9728439a11fab42cefadf',310097000,NULL,NULL,'d96af5cf3f431535689653555c29f268c931f9fb271447aed050303d364f92a8','7ef364d12e5be3972125f16be1990a0a119d9919a216b935349f41eca5e3e1b3','efda6d63ccb24915587be6621af854ff01e7e6f4a7bdda1cb910cec02f691fcd');
INSERT INTO blocks VALUES(310098,'ca5bca4b5ec4fa6183e05176abe921cff884c4e20910fab55b603cef48dc3bca',310098000,NULL,NULL,'153c9ce12e8d9f9d10c4005fc9af158613480d38b2c6551fc49bc57380c229de','fdfe4864ff57c09da3eba3b1cda39ed8a10060af19427e5329b1614d45061edc','4c76a412fc1a941a1f44c0b250b12041a31e04d3b081b92ff70e8a96a0523e3c');
INSERT INTO blocks VALUES(310099,'3c4c2279cd7de0add5ec469648a845875495a7d54ebfb5b012dcc5a197b7992a',310099000,NULL,NULL,'49f33b269d717b56a399843cf4627449010133b47079134b9e299ac5386468ee','8a20452363a53b33dce9edda05eae4520e2a45fa16cfd6d1c5cfd49bfb5f3d06','4bf4ef0664039f64c8e733c6090497857cbd0cfa193c02dfc234ae059d78e62f');
INSERT INTO blocks VALUES(310100,'96925c05b3c7c80c716f5bef68d161c71d044252c766ca0e3f17f255764242cb',310100000,NULL,NULL,'c9e72f7db2950f0b0e6e8fa3bc47d37a0d643da6ec61b236f7224b63ac60467e','e26a7eb301dde09d8b5d91713020068657f7fbe968fdeabd2bd9dad3b7a320bd','92848f967b7349ab801d5eb523c8e151b70cb98742212858310156807d29c961');
INSERT INTO blocks VALUES(310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,NULL,NULL,'a4387c8c785a8407f2dda176a7e182617904e7ce00c695ea8aa2f9d0429d9e74','8cdadfd0cfb782de7336f3c37f5709c36aadd92c37c7197a23b98cf683b5244b','5d0114d5f40cf286dc65a6a70842c3f2ee29ac7d3974f2ffbdce81fa05e7ccad');
INSERT INTO blocks VALUES(310102,'11e25883fd0479b78ddb1953ef67e3c3d1ffc82bd1f9e918a75c2194f7137f99',310102000,NULL,NULL,'fc81f97474f7b35ef92ba93de82d38650a28afd140d3320e6f6b62337cfd1e94','41dab00814c2a1bf2ebeb43f9ac4ebd98e4ad794e9ccb5ad99cebea5883b1473','81912fc49461a93de42a4f894113dcd0ff915e91018ae18a1a329e3497530a1d');
INSERT INTO blocks VALUES(310103,'559a208afea6dd27b8bfeb031f1bd8f57182dcab6cf55c4089a6c49fb4744f17',310103000,NULL,NULL,'3a502a89a3b66438cd2b944f8951a78999ba18c5f5bc8abeafe373ae4625ed4a','39dd5b62473f3d545601773b63dcdf786f9d64acca30f6184877d52d1ea74feb','9160172f261354266d04d7a00070bcf23afbe6f21257f8b8c26d756bcf2a5f9c');
INSERT INTO blocks VALUES(310104,'55b82e631b61d22a8524981ff3b5e3ab4ad7b732b7d1a06191064334b8f2dfd2',310104000,NULL,NULL,'74ab5df2cdd13b654c80ef12e460120c96ce30d4690a06671474235fb93fee4a','5eb789a8ad1819a04be9c35b684c2facd12d85cdcec5910dbccfb8ccf021e612','faa50f4b958985d7b4fe8007f89605c8fea261d3295ae8da02083e6e533a1916');
INSERT INTO blocks VALUES(310105,'1d72cdf6c4a02a5f973e6eaa53c28e9e13014b4f5bb13f91621a911b27fe936a',310105000,NULL,NULL,'dcc1940370421712cc668dc401169a55dd7077a49feddfd70e9e455aa5893962','1a43d6da49c4a4431fd503f8023a6b67d78c29440d6b0b41fced2529b5a340d2','28ab5d8661be4756482bcf70bea364577afdca6247d21edadcb76d3d2585bc22');
INSERT INTO blocks VALUES(310106,'9d39cbe8c8a5357fc56e5c2f95bf132382ddad14cbc8abd54e549d58248140ff',310106000,NULL,NULL,'6ec3678f9b647dc1ea3dfd0d76ffd240da9a94097ad29e48e7b327d6198f4f78','ddbc8453beb495367170859bab43cb04c35894a34e64898221f49e5ad1d272f5','a0f419908cf206da4d418bf2cc05292f00ad8182a126756d57ab4f8f048c9fa1');
INSERT INTO blocks VALUES(310107,'51cc04005e49fa49e661946a0e147240b0e5aac174252c96481ab7ddd5487435',310107000,NULL,NULL,'8e3c2d75c7a81175405f39386e2367c7a655afb53d7cf5b5c2e7dd2c79a40d9e','7cda7d3c4b0afe9225ee432a2cc233128469fd23d7ae1fc6582d146a2cb41676','6944fb8b3829e13c678cba40258ee2207f4ac852e1c23fe25ed608aa7e7337bc');
INSERT INTO blocks VALUES(310108,'8f2d3861aa42f8e75dc14a23d6046bd89feef0d81996b6e1adc2a2828fbc8b34',310108000,NULL,NULL,'b00c403723eba6ffb5db3d9903fbaa8a04a783c61949b9220e2caece1a8b86eb','dcc025d5458f25abbe09365c656f0205b4ee2ae56036b1a0473d7e6dde3203e7','abc1835b2f77d71f9c5bd64022cad34875fbed8911a2618ca9995834fcaa5688');
INSERT INTO blocks VALUES(310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,NULL,NULL,'69d2150543fe997a6685eac965283a3e7c9d3f9aa4eb2e08e8e4fe7a15054d26','2e89259cff51d211ce162f9b832c5dd2b7bd24961a2840e7532166037a2e5f1d','02f0aad0bc488317045540a48cef58edfd1da903749cf760e65629b5d8068fb8');
INSERT INTO blocks VALUES(310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,NULL,NULL,'0122bef9da908b66c64aae0057d2052e1333c7e71075aed739de6838f03802a8','88a1f1bface7d4b12b44e2ed80dbd9b0d4333f28cd38a215468820abf54dbaf1','23ca8fe531c538df098f12bf68a96208c216780bd11837162ba0b68b195ded2d');
INSERT INTO blocks VALUES(310111,'fde71b9756d5ba0b6d8b230ee885af01f9c4461a55dbde8678279166a21b20ae',310111000,NULL,NULL,'d3ff81444800b8c914171c58ef93c9e9ce87dbeab3b7bad16729685eb0e2e55e','4f0d236f55bba4e2a4cd7b2225ddf71023731bf12b3b96f341a491a08efc09dc','c6593b9420bc665f4dd0c0eb8918bdd21d5c73d02530d6f725015e51856fcda7');
INSERT INTO blocks VALUES(310112,'5b06f69bfdde1083785cf68ebc2211b464839033c30a099d3227b490bf3ab251',310112000,NULL,NULL,'e316c6a4f4d1dcd800bb94f80dfcb66e9d8fc52927673c91865460b8a85aa84a','3ebbf5f0ade2a173d428f15227625cc1824263f72df0a613dfe47918b2cc4107','0103f7f578463361f86ad2926b438da986952326b1a3f7698b869232fa5ed1ed');
INSERT INTO blocks VALUES(310113,'63914cf376d3076b697b9234810dfc084ed5a885d5cd188dd5462560da25d5e7',310113000,NULL,NULL,'44ffb0b4be579060aa2a0fb574935764189ded92d31cc4ea94e4042734a9377a','1fded7711a5a8ea045331477cfe8242ed784b17f3789b62dbf451fdd99c3736d','9d4f75a794634edf8ed30e2d1c0e08de5d53cd2cc92b0009d5553d93bc45483f');
INSERT INTO blocks VALUES(310114,'24fc2dded4f811eff58b32cda85d90fb5773e81b9267e9a03c359bc730d82283',310114000,NULL,NULL,'a256d5377258011a8a4d887ba734094b7dcf2dc5fe99333069abaf71a7233948','ff22203f133e819065585bd8f484d45b6d2b38ec08ed7581772ac01157f4361f','491577f0763a52228e78bc44b0fe3fd761e6a8c5c1e9edca975c0d70b82e9dd8');
INSERT INTO blocks VALUES(310115,'a632d67ff5f832fe9c3c675f855f08a4969c6d78c0211e71b2a24fe04be5656a',310115000,NULL,NULL,'40e8739b957a2316bde9e5727b7f57427691850996a794c6fb6095e8510e88a7','8e1a3d773018e887ada57e8fb0c79349f9c48e0b73335b9a4f0f5658410b32e6','ba9982c77fb09761f7ee2b362035a26a14fb612b483967c26620a07ab7d579c6');
INSERT INTO blocks VALUES(310116,'8495ba36b331473c4f3529681a118a4cc4fa4d51cd9b8dccb1f13e5ef841dd84',310116000,NULL,NULL,'cddef956a174dc306823ac6c25d66f6b0df70918c90fb94bf6b0b0033443dad9','770b2dab7ab32be08141ff0ac35aa2eef234dce6b85f0551ddabc8ad04285d5f','656ffacfcb29ccbefc991f8b65fe55898d998fe0a292e52c0d9e6bb577350013');
INSERT INTO blocks VALUES(310117,'978a3eac44917b82d009332797e2b6fe64c7ce313c0f15bfd9b7bb68e4f35a71',310117000,NULL,NULL,'235c743e4857b7bffc03628ee42350b5bf550ed10bbcd9ed7e405ec17f30b67d','6a6f00e717818866991e7cc585c03b6ea11994d3c6818b831dab7e12931daf22','3d40d59aa589c4fad7b94f1067277145cefe403543c4380a93ba225d8dfecfbd');
INSERT INTO blocks VALUES(310118,'02487d8bd4dadabd06a44fdeb67616e6830c3556ec10faad40a42416039f4723',310118000,NULL,NULL,'5559796f49bc96fb1ca98a673a137f3c98ccbef8f9110d05b770ecb1cf805e37','1bea4169929ec44a0e4b94709903ae90ea51990888c4e6301cf6e259c9319db3','e0c4b08b717c2eeec5b2d8d537898acb146400c717c22c3b218c094f9d0bd57a');
INSERT INTO blocks VALUES(310119,'6d6be3478c874c27f5d354c9375884089511b1aaaa3cc3421759d8e3aaeb5481',310119000,NULL,NULL,'576597cb241dfa9eada633311916072451225339aed38d1a481c82d5e2833fd5','52bdb3564608ef312607fa6ad01ce11a290090d149ef135c32d9004411c462ad','9f2fd08b4485236563b3ff553f660562183541c777e40416a86c594b7baf9732');
INSERT INTO blocks VALUES(310120,'2bba7fd459ea76fe54d6d7faf437c31af8253438d5685e803c71484c53887deb',310120000,NULL,NULL,'abb63a7c4edb99c71e21d1f634fb7e95d104e420133b2d216af99c0a367be94b','2ede3c82beda456856f08f54a82c4d598e4d50ba3f3e61112fff91415a11a1ab','746bf43284789ef596ad7cb787e784178db02bcf8f44bd27aa8ca7b788644bca');
INSERT INTO blocks VALUES(310121,'9b3ea991d6c2fe58906bdc75ba6a2095dcb7f00cfdd6108ac75c938f93c94ee7',310121000,NULL,NULL,'b72746feb9077aafae6737529b4c1f0552c20ae45edaa72c2df4bea3c018d532','7800d65ac6d5ee0ba88171257c1ccb7b71d1087e430f09ad7fb41dc129e20ff3','cdaa29bffe9d76cfb35a251066b0791cef56e35e2555503f85bafb6a233aa676');
INSERT INTO blocks VALUES(310122,'d31b927c46e8f9ba2ccfb02f11a72179e08474bdd1b60dd3dcfd2e91a9ea2932',310122000,NULL,NULL,'add1e878e00a20f8f357bc783cde6116665655b241d473f854f0808ddd9b73c8','1d355bd39c3eb28a286ab81cf16aed5ef2daebc65a7d0ccf38b5e086f6a05a59','683a3689e73eaf7c3bf883287ee22ae468edebbe947a686bf48502f9633bc5ed');
INSERT INTO blocks VALUES(310123,'be6d35019a923fcef1125a27387d27237755c136f4926c5eddbf150402ea2bbd',310123000,NULL,NULL,'d85015fd04e9cb0b6fffedeb2f925e2dcc80666528daaf98124ec3565e8d3cc0','04050d7f0cc637b5339934f5aef65580a60875584164ef9191e606a590034d45','49358fa8a04a8eb19fa12a289b942a84390b99249830a185a0da65f6e3c8ab11');
INSERT INTO blocks VALUES(310124,'0984b4a908f1a7dac9dcd94da1ee451e367cc6f3216ee8cdee15eae5d0700810',310124000,NULL,NULL,'156bd9f1502fb3eefb80646fc15df6a2855e0548c5d877dabb7d4660324609dd','0fa9496fa8daf470f33b498fee4b1064a646104cd800be0f5dcd84e0f4acdff4','9709604bee5011f083eb7b0a1656f917748a0d38803b784c269ec0355910d4db');
INSERT INTO blocks VALUES(310125,'cc28d39365904b2f91276d09fae040adb1bbbfd4d37d8c329fced276dc52c6a6',310125000,NULL,NULL,'d0b288be666bd1e4a7a6ace21c2b373330dd73348825f93cc46086cbbcd48a0f','c2e93435382cab249330ecc7a448ad2da7e45032b1ceb21da958ad76eb035cff','2626cc8efe3d10afeb76b7cbda4bceb291cf6dbeb9e367e823dcde3ddaf5b39c');
INSERT INTO blocks VALUES(310126,'c9d6c2bd3eeb87f3f1033a13de8255a56445341c920a6a0ee2fb030877106797',310126000,NULL,NULL,'c2c842ff8f74fdecd9604a947792420c1e8a16d9eae381a2bc9aaee9694f4067','264a055d55ff2728f0a980356c4ea406232eb67e50798007711fd0ea78f2fa18','31a0059fc3e7542c738f9771ff05927998c0607d142450c7c2e01add730efbd0');
INSERT INTO blocks VALUES(310127,'c952f369e2b3317725b4b73ba1922b84af881bd59054be94406a5d9bbb106904',310127000,NULL,NULL,'d8cca33e7e524da7740a21d5958359a3e6a6f314251e5250f0bfa06bd16f358c','f50602efb3ca235787004095d976b9deec22a05463d5cb0167f086c1a3524913','abf2ce594e6017d06c4721f20069b20b2c614ece42a43398742ae4a6d02a989b');
INSERT INTO blocks VALUES(310128,'990b0d3575caf5909286b9701ece586338067fbd35357fec7d6a54c6a6120079',310128000,NULL,NULL,'5458f1a4d540dc33c0338b94b2ce0bd7a6398a9d3369de8f3ec6f7a8a690f753','6b8cc7539925446ff827d66573c64ea60e474ddefccd36eb880d0c2a1f4526a7','b5072439976ee2985e6d59388b73cda2d2adaf8538fece839a029648534cd2c6');
INSERT INTO blocks VALUES(310129,'fa8a7d674a9a3e4b40053cf3b819385a71831eec2f119a0f0640c6870ca1dddc',310129000,NULL,NULL,'5e6d75061f2ea056056681fd3f856407249975a5a4a327bbf8bc20a96743fffc','23bfee769d8b1d4de88f8dae3c0c54770d6b13f5563f91a40348000e5af4dd0a','aaa73642a4fad02a6ad828c5057ac5985b63d6c37565cabb5e1d90dc89875472');
INSERT INTO blocks VALUES(310130,'d3046e8e8ab77a67bf0629a3bab0bea4975631d52099d2ddc9c9fa0860522721',310130000,NULL,NULL,'200b50c17c51fdb4275ec49e7300227a63ced6e3ff9292be49eb7b402d3db1b5','ce95a9b73237abf28fd83ded171238b04c0cb25a3e4c39ef43d133ee1dae2271','dd63747b3411784e7a2a2fa4d682f251c1d9806b4c436b84105c703952772d45');
INSERT INTO blocks VALUES(310131,'d6b4357496bc2c42b58a7d1260a3615bfdb86e2ce68cd20914ef3dd3c0cdd34d',310131000,NULL,NULL,'de1c49ab1e413b11cff49cb50b22b8ac76a1ad93a024beebc8f9ad0d959525d5','5adcc594661d4c625e38db642f0139129d4c66986954c65593eebc234c4a83e9','0664ba48efa34696621dd0b40dc7d72212cf3b66b1ee3e604ac4380fb8553131');
INSERT INTO blocks VALUES(310132,'1b95a691bf4abf92f0dde901e1152cc5bd87a792d4b42613655e4046a57ab818',310132000,NULL,NULL,'306d6f01cc778512334b73d66435983c57183e7c4f87c26f1166a7a83a36a155','70439383698f1bd361f5c4c59e82c536ecfaa4833fa1f1fd6d873a371d14bffa','d383009179bbcb72dd75f8d5a5c45f5de1c038ac103a3df9d05721952fc6e1d1');
INSERT INTO blocks VALUES(310133,'1029c14051faabf90641371a82f9e2352eaa3d6b1da66737fcf447568ca4ec51',310133000,NULL,NULL,'e156b907295c14968c5fbe5e8fcc9fdc0415f3413a36a7ed737ea9e9f153e958','b2161c14ca3419150c35acac808452d57c20d3ec567dd4c6f33f33d125a572ac','17fec0058496042aeb6c7d0675047838481393bd93ff95360a3a2ead5a726ada');
INSERT INTO blocks VALUES(310134,'1748478069b32162affa59105257d81ef9d78aee27c626e7b24d11beb2831398',310134000,NULL,NULL,'2528daefb0d2432358a70b10e11397535232c4fd2e69eacc77219c423df1d3f8','7e3d1f09cf495ed429463f4d83c2947ba783a65096221dddc39db05150b1ac5b','bb1637b8f74f200c80db11bdadd677c3d96fe80b5a0d9db86013da51ab292d91');
INSERT INTO blocks VALUES(310135,'d128d3469b1a5f8fb43e64b40f8a394945d1eb2f19ccbac2603f7044a4097e4f',310135000,NULL,NULL,'81b3a7fe120fd6f795536d275ac4b1621fea8a4d968b14a51a71ecee6944a819','40788759c3bb8e9cff45a2822cb0937733478ab8dd791b44a83bad1b0100c869','b6060171adfb215a276bfcbe44cc004a0437c11830325c7ef89cdbc91b30d0a6');
INSERT INTO blocks VALUES(310136,'6ec490aaffe2c222a9d6876a18d1c3d385c742ff4c12d1334613a54042a543a5',310136000,NULL,NULL,'405c424434f5e9036d00704008be3793514d29a5bc619c6f5cdfd3c86326fd77','6b24f5938d4fda8188915c68e8ec5f49c14ae1f7b5b5b6d8592796f9c2ce39b5','561a368cd212c042db03486bced7af154f2632e4a8e0647e3755e3de818faeb1');
INSERT INTO blocks VALUES(310137,'7b44f07e233498303a57e5350f366b767809f1a3426d57b1b754dc16aba76900',310137000,NULL,NULL,'7ee1d757a81c357ea0d18e59433d275a28f04f384baa35cbb874d75ec0182dad','4214d6c80e53b900fd09a5a67551c24fc898c97eca81f6dedff63fcb15413c25','db188c3be478a701bc9faa6ead2f87cbc18237e79eb6b8316e1ec74db2da721d');
INSERT INTO blocks VALUES(310138,'d2d658ccbf9baa89c32659e8b6c25b640af4b9b2f28f9d40baae840206402ab5',310138000,NULL,NULL,'1306ff4026b302043a5f418cc64aa65a1e5da7ced92aef50ba9c5699509f9eec','1b2c2b3bd63a473f6b71ada71fefb8ff192b503e0379f92ffe9547dfb4f1d768','a93b235e1d6579deb793784c3320b561e12a8212f70dbae3c73acb7ecdc9f46b');
INSERT INTO blocks VALUES(310139,'b2c6fb61f2ae0b9d75d18fce4c52a53b1d24772b1ad66c51ca51090210527d46',310139000,NULL,NULL,'ea081adf4304d85433da18652bdb032ac5916bc6a1b96410cf0ec51f87a5c519','bdba69450f322a16547c14832b47dc8160ac50ee8f1e20a4220be166ce77b475','2fde7cd29462759dc41eef4430ba206cc9508fdbbaaeb81a29faa70c0d8cd4be');
INSERT INTO blocks VALUES(310140,'edddddea90e07a466298219fd7f5a88975f1213289f7c434ed47152af6b68ebb',310140000,NULL,NULL,'96f0be399144ab67ac49b54f80ef596a5c508e0f052d35b07259aff88a559a0d','1e12d691734e603fa7791fa189970bba99e7297b513c544ebfdff4b976ea7a22','36ad34ea9fba0dd02bf67bed2cf2c37bb8f997916121dcca8b88386150fb055b');
INSERT INTO blocks VALUES(310141,'b5b71d2a271bd638561c56f4ffbe94d6086debaaa86bfeb02ef0d71339310709',310141000,NULL,NULL,'fed95d3c66979f94f4cf0ee075476b5a3e37d17285e1e84e2dcea837212ec8ce','ad384a2bec62e7bc85144f3b51f705196efa3e2b6f138170619f1d16ea661847','477670beda8050b2c77165f35c72d2ec0a3bf19866bfecc796679fedac39355a');
INSERT INTO blocks VALUES(310142,'a98ae174c41ab8fc575d9c8d53d8e02d8e446b8c6c0d98a20ff234eba082b143',310142000,NULL,NULL,'d062c8df1d3bbbed10c67250e4273f47d9edadbeae329e91a0d9214d62e2dafc','e170b58488eedf8002e0168c7f8618f012b64d6d85d4df4ea2b44d3a537a60bf','230f0fa8e67ffebb2e9a43dcbb2d81db3d494201245ceb36cec8a7e9ec91f03e');
INSERT INTO blocks VALUES(310143,'8ba2f7feb302a5f9ec3e8c7fc718b02379df4698f6387d00858005b8f01e062f',310143000,NULL,NULL,'8b58427567f04bea48d8ef1643b1936731dfa1d44ab5ae8a0a725f5808e5cb25','e486fdcfba49e630f54f3c09cb18c8fea22f6bb98f654667fb576ff52313f3ce','9e1e1db59bbc90223fde2ff4de498c92045ca969a6589a0b07eec2c0dc341595');
INSERT INTO blocks VALUES(310144,'879ffa05ae6b24b236591c1f1537909179ed1245a27c5fdadd2218ab2193cdb9',310144000,NULL,NULL,'17fea61e6f803d990bfd78ae94f5482755577ffac62c56ae964a9ba4eba2a4e7','39fde4e8ae9c262b0bb8ac5ad340102cd3465fa5b5de05690308068e08ccf0d6','1cad3201e856f1e3b9167eb81e7f86ad54f2a14f5134b8030ba7eeaff39e044a');
INSERT INTO blocks VALUES(310145,'175449ef0aa4580593ad4a7d0c5a9b117e1549ea772af00caa4ccdc9b1bf7a6e',310145000,NULL,NULL,'fc7745aaf59225dfd4055496462ef19352e31e7a681d5ddeee5d8d305914cd63','23dca89507777bca61420d1f350a68db1967bbc0030386224390c16c4796f5c2','7dac785c2a5974e7885b8d24dccadb3dcc3e1599ec063827bfa2be7832778fc8');
INSERT INTO blocks VALUES(310146,'e954ab6a110455d745503f7cc8df9d92c1a800fafdd151e7b1912830a9cb7184',310146000,NULL,NULL,'b21400cea27ddadec8c336f757c1f250be59c2608323f5492cc40f0c2c54c086','a8bf494cb29355a99c8c8003db54c98744afeb693542ab2d41607ce40cd7af43','f307f880018d75b36383bc59d89d4de1872934e90e72641a70cec06c65c195c1');
INSERT INTO blocks VALUES(310147,'7650c95eba7bf1cad81575ed12f32a8cc36281a6f41bef13afe1dfc1b03a7e83',310147000,NULL,NULL,'47ed87885040679eaed04907a9adcbeb5fd23c3220d106cf991c692e56a47c85','7d979e542261f9d57f81f9f39e2a73e90305fc69b7e5d0077730841bc6a0b8ce','8ca7f08eb3249f304fe469b95df9d9f4446a56c326d2f287ce7a200be3acbf89');
INSERT INTO blocks VALUES(310148,'77c29785877724be924f965215eb50ffe916e3b6b3a2beaea3e3ae4796545a7e',310148000,NULL,NULL,'f2b6fbf8a0d2d8ca5b7f837059d3d5d4e377606d715255ece9d66cedb1ebcb5b','47706370525533575101412ba0b93cae85b7790da171526b1682700fe89ddc98','4eea79d57a6701dd9de82dd0f9fa461110aa5333c9d1df56bae740b0f55e31fe');
INSERT INTO blocks VALUES(310149,'526b3c4a74c2663fc04ed5234c86974bffddb7235c8736d76860778c30207b3c',310149000,NULL,NULL,'7cf62dc8d0f09332900b3d3faeb973c75f60e7118ba2f5ec25f9a1d02e5373de','e86425cdbec0c5e8f19928b55fac3abc26732e2f2aea90bee57b23c044e9c4d3','f4cb6715741533e1dfccd7d5d96d2892bc14cf17c002e9f0b5a6d1a489cd89f0');
INSERT INTO blocks VALUES(310150,'cdd141f7463967dbeb78bf69dc1cd8e12489f58c4ea0a5dc9c5c01ec4fcea333',310150000,NULL,NULL,'773cd82211234feb848d9246f3e7da054bd0083d24aed81143cffc9c0dc00074','c665e43699ce5b964d64d64462dc84051834af59d41001fc6d6e1493e78cf7a4','9745503202d6619b15596bbd84ecf0627416fcd61676768bbd6b9a7235f4ad79');
INSERT INTO blocks VALUES(310151,'a0f31cc6e12ec86e65e999e806ab3bfa18f4f1084e4aeb4fbd699b4fe284b330',310151000,NULL,NULL,'532dcd1eae2240e6117d592dbfde30600f391007daa8e233ff99cb26ebae995b','f4f9e2153a7b3c6ed729581f78f0e3938e872deb4e6c2a526d7b0f827885e5f9','b37474d551253694d70127cd5eb60988506051b5011748ec46fddaf275338bff');
INSERT INTO blocks VALUES(310152,'89c8cc3a0938c63a35e89d039aa84318a0fc4e13afac6beb849ac37140132c67',310152000,NULL,NULL,'2c5346c3aab989386ee49d27c30939760b6ff2eddad88147a715f0b4346f5c81','a731c54e3045f1dbfcdb6e09858bacd93995c3c1bbdae7fb53a0c2d0f6ba48b5','d6d139c844d3fb2a07f449f659c74afea6530c6bda5da967dbb8735f6f4b7890');
INSERT INTO blocks VALUES(310153,'d1121dfa68f4a1de4f97c123d2d2a41a102971a44b34927a78cd539ad8dca482',310153000,NULL,NULL,'2662192765845a97bc1bb97f4b8b0a1d8c73d6c4a57ba6a36062bd75094131cc','93dc9d19c3d49834abba7188d569e5d10d6c4e4624857214f491a9317c8d7f76','3416dbf1e54d388758299092cf7c4ebb03cc389ca27447b97c3898e3ee850c0a');
INSERT INTO blocks VALUES(310154,'ba982ea2e99d3bc5f574897c85485f89430ae38cf4ab49b7716ed466afa506d6',310154000,NULL,NULL,'662789c8199a23fd244f020fca7cf70af20e9792dd66801ac0cfe5a871279fc3','e50b6f2825e36cabfff180d12e4378f7da86c7a1bc53a3596e33669090379f7b','0bdbbc3fc107a9838ae5995d846df2610fbf460796494cb142b5723f0c96767d');
INSERT INTO blocks VALUES(310155,'cefb3b87c7b75a0eb8f062a0cde8e1073774ae035d176e9769fc87071c12d137',310155000,NULL,NULL,'6db116d18753ecb4c147346942c7cd41f3ddcd0b8b5300c8560c6cf2a1ff2b0e','39fd09582d12a179d9ce90e85827745b0ceb5aa5896d8126643dc06d0816abd4','cd3c3367173f76e7283890df1a305f241cd4aac84e29980b4a0e2f237db1a2de');
INSERT INTO blocks VALUES(310156,'6e3811e65cb02434f9fde0445a7a2b03fe796041458737d0afcc52208f988a83',310156000,NULL,NULL,'18738df90f8ad63adfea0d45249c8c11e3429badec69f9d80e4d542ad78af26d','fb5d6b24dd9e066574851741747b7cbdaada0d76948c6c654add33d32df854a0','30d6fa9d952c87d669f1c653a5e456e8a75c8f8ec55b6fc4d7e255e7735fabf8');
INSERT INTO blocks VALUES(310157,'51dd192502fe797c55287b04c403cc63c087020a01c974a565dd4038db82f94a',310157000,NULL,NULL,'41d6b09f49e434e7cee1c174880a19624f796685d18cca88049572cc924240e6','4f81bd847d27aff759aefbbf7821cdf9eb572e2fd0e648eb5831a4a4490b26a3','5a27bca42c7aa58b170aa4cf441f118660648a4a003c88c93b26dbc1b4afd5b7');
INSERT INTO blocks VALUES(310158,'749395af0c3221b8652d31b4c4410c19b10404d941c7e78d765b865f853559d2',310158000,NULL,NULL,'4c436a14a5f2fb45f9525122d91559961c5ae92b182d1458f421d72b8689c555','40763aead3bd12062705deae164b7a6de3812e31459e6fe4867224d5048137c3','ffa8789ad9eb23a60aa26cbbab77fc76c9626271238baaefaf538b99de054bd1');
INSERT INTO blocks VALUES(310159,'fc0e9f7b6ae99080bc41625588cef73b59c8a9f7a21d7f9f1bf96192ba631c12',310159000,NULL,NULL,'9f3c424fdc6eaf4fc11fd4bf6d389af9aaf82dddeb378f050446ed0f191c415e','a0f77d535477a3a1ca2cfdf7bf93b1c8d50ad089c0709ff62f6ee799e09ac830','11ad1bb9dd08ad50a5325ef5273986ab4ddc7c78686637a185f9c708b2c27971');
INSERT INTO blocks VALUES(310160,'163a82beeba44b4cb83a31764047880455a94a03e859dc050da782ed89c5fa8b',310160000,NULL,NULL,'7a2c16fb611558b70b31f8f12c6d0ee08f0c04d6901f5e674984407400dc4f7c','dcffcdf2c43732b81ae5ebde41dc3629beb96f7321471154832152532c8b9344','5fe68cb9f1335f92a8e4e133ba240ae1d90f6953ab49f018bcfd42d7fd459544');
INSERT INTO blocks VALUES(310161,'609c983d412a23c693e666abdea3f672e256674bf9ee55df89b5d9777c9264d8',310161000,NULL,NULL,'b8566b51d69aaedc491add41ea3a4260406b04b8d417163c9122b6d46b23e043','2f8b535723aca39f668fd122280ff6f322bd9b1adac17991b30714c7cf89f84e','db0264964f22d5010587f47e0886fb36dd3c3cd53faf2ba13372760ae025e792');
INSERT INTO blocks VALUES(310162,'043e9645e019f0b6a019d54c5fef5eebee8ce2da1273a21283c517da126fc804',310162000,NULL,NULL,'8bc4f34f2ff6ee796a9ee54cc8e3374136a2226343ad506680ba94a04a74efdd','1d32263c7d7604458a1b1b2dad17d63557bfbe2d829c12dd137c29010b44f0a5','14f509677862fe1ec8022e2b3cd2fb821491114df69dd25711034e72a2cee706');
INSERT INTO blocks VALUES(310163,'959e0a858a81922d2edf84d1fbb49d7c7e897a8f49f70bd5b066744b77836353',310163000,NULL,NULL,'d5b71a21ec5123be72bf29d699facd204140d1863ac22ef9973920a7f4fc0773','45c0ec7fed4d566bcb542bb6af1bf17c74e653a6a80810cd81b93697352f5bbc','9e7c63ba224642e9da722d3189f4cc564330342fed7bf96c5cd89e11e8eba3a6');
INSERT INTO blocks VALUES(310164,'781b7188be61c98d864d75954cf412b2a181364cc1046de45266ccc8cdb730e2',310164000,NULL,NULL,'2f8c3ed867557c8cad28de08cf82fa2484ceb8f7d7cc26fd5c68e15019ac5f87','5909c9282f198e255261540da90e6eb92efb5ef10fec1963808b15038baf5219','c4f5b82d3869b63af6851ae453160fa0eec6c774fc70c43db019e87e1ae457db');
INSERT INTO blocks VALUES(310165,'a75081e4143fa95d4aa29618fea17fc3fabd85e84059cc45c96a73473fc32599',310165000,NULL,NULL,'eedb0e236cd48b9afe186b5c34002e4a17679ab7b10ed8c0854d2683ea7b4df0','4df14e82bec6ba17843865579d866065edbf193d29a8f53e5bf8a2f5c3b2765b','1706c2f11e44de3fb44a18db10d9a289139fd7a907b33c1b505fdf3510ad54b0');
INSERT INTO blocks VALUES(310166,'a440d426adaa83fa9bb7e3d4a04b4fa06e896fc2813f5966941f1ad1f28cfb41',310166000,NULL,NULL,'392df958448612ffdfec7f6aea1d3fa37c6f15147be61667bca1f16ba101050f','820b1c0f5577bf101835012c7d71d087ce0b647e63cd905c3b0963b09c448b15','6d1950d9e020d1c272fe05a30f77dcd586d01bfdd3cd6f4665de1376e8c318b8');
INSERT INTO blocks VALUES(310167,'ab4293dbea81fedacca1a0d5230fe85a230afc9490d895aa6963acc216125f66',310167000,NULL,NULL,'2d0a69eb324f085f3b36317d169902be8d4c40707c8afe2ee5dc56c104020990','58a79028a8009b55705bb998dd850cf9c31767064b9f4205d3edf0912102da63','c588db39c50788843d968bb40f46aa5e12491e18ad0047f7e0e6da9125f198dc');
INSERT INTO blocks VALUES(310168,'a12b36a88c2b0ed41f1419a29cc118fae4ecd2f70003de77848bf4a9b2b72dc9',310168000,NULL,NULL,'9339de42b016d558c571ed1b4a907a337995380951d1652c36cf9685d6d063d7','22f3ceb4195cc9282af8ee3263aa9bc9d09c356af6b95462599be0ec036ae326','c94227a3aff5de78b5846958b99e0f89bcb8eca34135932d8939aeb0a345bbda');
INSERT INTO blocks VALUES(310169,'204809a85ead8ba63f981fc1db8ae95afe92015f003eaebbec166021867421f3',310169000,NULL,NULL,'b0cc29ba6075a4519388aa13b2ed8ac13e779414c50a2b0a048794065eccdc80','af44248e845fb2fec12f9013c373fab41e154e1e0a72a8fbe91421346fb9b6b2','20f75579d5a0ef4e744fba9a7f5a1fc71167355bddbbc44883fe467ccd000744');
INSERT INTO blocks VALUES(310170,'b38b0345a20a367dfe854e455e5752f63ac2d9be8de33eab264a29e87f94d119',310170000,NULL,NULL,'d342b3a0badabc8a47a15d695f7c877b54287645fd8df0d560177a57c7f0db3d','f987e01464f8c352e6e7a1ffda15e7b1e0d00329f6b68dd82c794a5a38d598ee','1cda8fcaf553064fc5c88eedb9983a48f1d8b351b1541b9287d6f7af75aed419');
INSERT INTO blocks VALUES(310171,'b8ba5ae8d97900ce37dd451e8c6d8b3a0e2664bb1c103bf697355bf3b1de2d2d',310171000,NULL,NULL,'c994a2733d12b3e28523f9ff8edc162f54f9218565c8ea5d4d100441f0477d02','c69d4b7c5d1d2fc7fb163cb9333fec5687783183f47369cea1af8c407f80fd22','ce60051119ac47847906facb48bda368dafc9638165ab9a07a8c7f60f2f1e49b');
INSERT INTO blocks VALUES(310172,'b17fda199c609ab4cc2d85194dd53fa51ba960212f3964a9d2fe2cfe0bb57055',310172000,NULL,NULL,'397248fb2a54f0570de5b24e9375263f3b54359727077a30227931c1052dd9b4','73fa163401c89d63632aacf4469f027245dd296af01ab62f8d6b053d065fa988','66588d059b9c4f9a0fe177ce7b0a98794c97d5a412db1f96f6d730db276f12cb');
INSERT INTO blocks VALUES(310173,'f2dcdc5ffc0aca2e71e6e0466391b388870229398a1f3c57dec646b806a65016',310173000,NULL,NULL,'66d5758c943c8332f1491005e13ee5a906a80e2af7ab8d37b236d309756def31','17a4bba8bab33e8a4c2db074f21304f27656f8593ac3f4d10ca91d92552b8385','83a502840f1117fd9ead4df79f88ebb00011d4a0e7e6e4bd3d3eeabf7d1ef168');
INSERT INTO blocks VALUES(310174,'fa6f46af9e3664353a473f6fffce56fa295e07985018bface8141b4bf7924679',310174000,NULL,NULL,'f45eb0d49b4498017519bafb08cb7e31b5e633391b1c748866a443df5004f53d','89f84d919f6e92f7c4e7d02bfb88b761d3ade8705e3373bed837d803038b4231','2b5492f5719bff64b954a34c1cda9d7b19028bac293d91afbc93b42e057c85d0');
INSERT INTO blocks VALUES(310175,'f71e79fe5f03c3bc7f1360febc5d8f79fc2768ce0ff1872cf27a829b49017333',310175000,NULL,NULL,'5f9cd3d5d4d3d9dce35bd3e76f8530c7dc2992a97785149011a39f76dc9f3b88','a154a7af57c6e1185312c88b3d0b4260cd87b8dfcdec822a65f1ba72a93fa409','c3b6e96097a76836768ac447d5f4a726c910cabc7303da6fd769b788a06a4b69');
INSERT INTO blocks VALUES(310176,'67cd1d81f2998f615602346065e37f9ceb8916abb74b5762ead317d5e26453c6',310176000,NULL,NULL,'34471b4af7737e7024fc3762d0e37a98bf12b619fdb0a4ce110bd2950e3d3bc9','326979e86616ab6114f89216e04887cac6a5a791e8f6dfb6e5aadbe81d8f28bd','137faa5fd73e9fb81449fca200cd0939d34e47f227ad58b5e24fe3e22edce7dc');
INSERT INTO blocks VALUES(310177,'6856b1971121b91c907aaf7aed286648a6074f0bd1f66bd55da2b03116192a52',310177000,NULL,NULL,'e1352b09b865ad48fe35f2a71ac1d1c188bf0f4ad7aa4ae37fd06027e556b2ba','d608cad1320140a5606fbb11cf9fd485443e7c64cbb5ee329eef7711483f294a','1512448668fdbfd95dbd6da9977959e01111448524553a7f56aa22e1861817aa');
INSERT INTO blocks VALUES(310178,'8094fdc6e549c4fab18c62e4a9be5583990c4167721a7e72f46eaf1e4e04d816',310178000,NULL,NULL,'3b6ad6e8a04f803e70f6e366d16d30b2179d1624a93db041c33cf4c4d28dfcf6','fca27e0b6b4f22a597f87f4fad7d775e30076f60dace8d109b6459185fad62e9','6a78834933fe1d3774a4b3ea00135a63422305b19536d11c7b005a915afa7c13');
INSERT INTO blocks VALUES(310179,'d1528027cd25a1530cdc32c4eaff3751a851c947ddc748d99a7d3026a5e581a7',310179000,NULL,NULL,'7f574d5c3d785d4070e92701956755101bd86949141b57fc4e585bd6bd2ad56d','123ff92d2f12eed51e9c9c30e523bf14ce939ca80c2d79ddf11f1613b8bd2031','74d4160357b7b83673f0a6ed84457db3cbf6cf7f7180770ba2f72daf1081e128');
INSERT INTO blocks VALUES(310180,'f2f401a5e3141a8387aaf9799e8fef92eb0fc68370dae1e27622893406d685c1',310180000,NULL,NULL,'9705d812c0cb4ca03e52ccb28a01522caef3cf41df45e7b52c32267a93517dae','563f4d82786b1e9ff05d6746146bb2d7840c813e3cd159d0ceacbcb5c2d419d4','c618053964c802190497783738945bd3ae13521fa68e2754f34c2b2e57e33477');
INSERT INTO blocks VALUES(310181,'bd59318cdba0e511487d1e4e093b146b0f362c875d35ab5251592b3d9fed7145',310181000,NULL,NULL,'808802d90ae3381feee9c5ed979e03970330135a60d9a270c719cecaf805764e','5359099d2044a1629b3913947288ef49d4a01a7c7683085481a774713fc1fecb','3568c0d585ebe4e942708b39ae6ea2fc55b6c360c921e33785ca82d19a4a4c89');
INSERT INTO blocks VALUES(310182,'a7e66b4671a11af2743889a10b19d4af09ec873e2b8eb36949d710d22e1d768f',310182000,NULL,NULL,'3e8246c907b75b7dbbf1a07b044e7c146c6d802c52792ba26b0085e399653932','2c7675e19002c6cb7c4facf18da6c4fb6a0be26bf54df3cc22184f34165de0aa','1737326f0fa2626507df4ba9eccfea65109e2e528f8d8c7c937c079b297e8f26');
INSERT INTO blocks VALUES(310183,'85318afb50dc77cf9edfef4d6192f7203415e93be43f19b15ca53e170b0477bb',310183000,NULL,NULL,'c830f4f39b35688655f8d3c3dd9314d1d8fe3a1aa2810ef4ec7cc51faac676b0','d1695fe25e0bda2ff1227cd7b6d2348d7841ab7c1b654a0d40e833eef5d90e56','7c174eb4979872ce47e5c21d71c09a1963e8418d810ca08909750027ff0d1fba');
INSERT INTO blocks VALUES(310184,'042a898e29c2ebf0fdbb4156d29d9ba1a5935e7ed707928cb21824c76dd53bfc',310184000,NULL,NULL,'499aa926aded967f6261ac213391b5498edb855c21ffadf25a0c5ff8378e9a91','c95934e571e4df7bf31bcfdd93624283c92ac84df4b7746cf1ae1f6bdaf49319','b16dbb7f970a25d5d02594c1c3e91b4529463f3e9378686bce77b2fd91a0231b');
INSERT INTO blocks VALUES(310185,'bd78c092ae353c78798482830c007aac1be07e9bc8e52855f620a3d48f46811f',310185000,NULL,NULL,'22798fe864fc015e0bcaeb760823342dbc7a9756d153cc428929b8945c6e6fe5','c983af9b67bbb41704a388ca3a3f4dc00b0c910d392659331ec7b3c3c37e445d','e520a8beffd2f3b8fca441106d025aabf6436aecf5e30b8ad6d5ed3b9aa82387');
INSERT INTO blocks VALUES(310186,'e30a3a92cc2e5ad0133e5cee1f789a1a28bea620974f9ab8fa663da53e5bf707',310186000,NULL,NULL,'6593028cdf86b5f3e65509b22955212d2b3a649741e439791c72b7e3c8734ad3','a4bb6dc0ff28efd54cde1badb729923cd32bb5492f0cef7f96f03c2c80a85d09','3f7124984c85e79b00e47b6ec57f87c8a793cad83bd820fc34da07c8f9b46055');
INSERT INTO blocks VALUES(310187,'fc6402c86b66b6e953d23ed33d149faa0988fa90aa9f7434e2863e33da2f3414',310187000,NULL,NULL,'e49da111e3998fafb7929ce5f43fcb8de9b89aba6a06fab288ac8106e8c06c47','70724d51bc82caf55acb5c6c7cc4103a2ad6cd2460a2d663ab4f47cf5dab12a0','2147cf823cb79dbf784fbffe1f69e729227bb8936d3b453423c5a1b9b74bada1');
INSERT INTO blocks VALUES(310188,'85694a80e534a53d921b5d2c6b789b747aa73bf5556b91eeed2df148e2ada917',310188000,NULL,NULL,'f36aab93a395bdb52168cca5be82b3d370073ac10a1eeda1e6769a2db96b8212','ca9a9a8ae2cf518a990de9643be950e7d58e30ae67000b39b17d4fdd86cf10d3','95e432ce7b5490c4561cf6c5b31f1dffe4d13118207c62aa9ba83bf93d0c9558');
INSERT INTO blocks VALUES(310189,'7c036dadf19348348edbe0abe84861f03370415ed2fec991b9374dbb0ca19a06',310189000,NULL,NULL,'caefec27a1031498981b5d4f0329dbc766eaad6f8c4230f4434dbc0440877109','e1fd02cb80a41ad7257054ce4d35f81ecf9067cdf13c1bbfc6f64663225fcebd','813d24c6c047e0ce3e26d905219b1085ae158066574742d7f82f84f16f8b1a53');
INSERT INTO blocks VALUES(310190,'d6ef65299fb9dfc165284015ff2b23804ffef0b5c8baf6e5fa631211a2edbd8d',310190000,NULL,NULL,'df92ef8478fd68d4774b3e8cb83ed1a069fbc5e3d666a5e8fa462013f1b890b8','86c78d88ef46a4d1d6e8311f3e32a1fbc2e9d4a5e108970c45d4e4f278c41688','c46e4f3699d50ab425506e8e88406c5f961cfc0f4ab85af9c4e2d782cd32e623');
INSERT INTO blocks VALUES(310191,'5987ffecb8d4a70887a7ce2b7acb9a326f176cca3ccf270f6040219590329139',310191000,NULL,NULL,'87cd3ba6903bb0a5afa07255e569534845b926e6e3a1eeae7043ef15f695a788','4426b1f43dd71773ec3e032303a5061146723745bbe074a440a85ca2850132e2','a593745aaccf535183d76edc0b530e62117184958704c0b249ec909ddf9e0be1');
INSERT INTO blocks VALUES(310192,'31b7be43784f8cc2ce7bc982d29a48ff93ef95ba18f82380881c901c50cd0caa',310192000,NULL,NULL,'93831212bdb388f4e2db36ca5d6ccda6fba1c401db7ed046f1cffe261569e3ee','1c141acea29c5740767db445def1cf5c1e0233f698ab46eddea4084201f7a337','ef56e08fc01d89f378d8454279d184fbece2f024b3f74b4caad73fdce4fe3528');
INSERT INTO blocks VALUES(310193,'ff3bb9c107f3a6e138440dee2d60c65e342dfbf216e1872c7cdb45f2a4d8852a',310193000,NULL,NULL,'299f6e3d677e12c0f6d02b242ef82dce4e3c75402ffbee4f891ba777e160091a','1969c5abf0ea09d2718f6f5b870b088d77ffa22a8aa8ce16f2d0ef7ee5a0ea2e','3761b2fdd1719b8dbe1fb12a16f071279cd5a344fa5885cd44abae7ae3957dba');
INSERT INTO blocks VALUES(310194,'d1d8f8c242a06005f59d3c4f85983f1fa5d5edcc65eb48e7b75ed7165558434a',310194000,NULL,NULL,'330c75c62d310d5214028311f19119b9aa3b413c1491067f8cf3567a1f37bae0','93028c349de4c628b579a7df51c0c69c774042146f898d784df822c8e5aacb5c','215e73a3921b8bc550c00e27d6bd62fd4ffa2e0c7271d9ecb683cc5f392451e4');
INSERT INTO blocks VALUES(310195,'0b2f1f57c9a7546faac835cbe43243473fa6533b6e4d8bf8d13b8e3c710faf53',310195000,NULL,NULL,'cb228e7c41f04f75bdb8a2a26e9848fd7f642176d4e3a6436bdeb61c102811be','90e549fbf182fcfe2691f72a5d84fc4c7c6e7441aaf9fe46ce41abde71190d37','92e5e5a0cd58bb2991df4a44f78d440212546110bbdb516916d9c5dced8c6476');
INSERT INTO blocks VALUES(310196,'280e7f4c9d1457e116b27f6fc2b806d3787002fe285826e468e07f4a0e3bd2e6',310196000,NULL,NULL,'d336a7f2e3bcbb067abca699119cb0b3a7d8e1cfb2081c6ac93d3ae1183474c0','5dc0e0e5b5b6dcb5ca46feff6d05cf60492ba185252f975f61d1525d6e18c13b','129bc3265cddd3a49cc83fab32fc55036164fdab01e283e93ddd2ee90998708b');
INSERT INTO blocks VALUES(310197,'68de4c7fd020395a407ef59ea267412bbd2f19b0a654f09c0dafbc7c9ada4467',310197000,NULL,NULL,'e1c14ab4ba11baa06f837c43575b058a38b7006c6ff272a0960f65d4232cd2ac','2d1c255783f8f158b07d4beebc87006454ef4d971efcb3be013d3f0b06c95036','8046eb1b818a942639d633890bbdfcffa5aded343eeea1c30a505b959315fccd');
INSERT INTO blocks VALUES(310198,'30340d4b655879e82543773117d72017a546630ceac29f591d514f37dd5b1cc2',310198000,NULL,NULL,'03c1bbb6d2b19b199bc13c902541db2cfa8ae8c5198d8271d8699ae0a08bba0c','e4b2a633a988660bd3b7028997db6e6deabcda857c0f45ff90210359c4e4a341','8a953e3af8e921a2a231602c83b913726697cd236a26a08049f686b625d8b1cc');
INSERT INTO blocks VALUES(310199,'494ebe4ce57d53dc0f51e1281f7e335c7315a6a064e982c3852b7179052a4613',310199000,NULL,NULL,'7c998d1ebcd2fe1c91c9d8aa562bd934b67521b09abcb443b18e4bae4a3a5e93','c649cb0e521af4eef3470b015aebce30e1550646543ca1290e8881881b377697','4e74938cb9a609311f9dc6db2cd320a3658e51514ba3601006f6073e6980de22');
INSERT INTO blocks VALUES(310200,'d5169d7b23c44e02a5322e91039ccc7959b558608cf164328cd63dbaf9c81a03',310200000,NULL,NULL,'12aa1d3ede45cfb999d785d21a19b20a0be4d51cf8ca7d78ecce47ef31334ebe','b4cb70dda6330c4de6bf942ae9db86a0e4d1c2d2eb1d8c865ce3f91f93eb1bbd','ab597a2a18b64c4e36d2ceb2701d51f4a331a22934beb497c72115e2de25ed55');
INSERT INTO blocks VALUES(310201,'8842bf23ded504bb28765128c0097e1de47d135f01c5cf47680b3bcf5720ad95',310201000,NULL,NULL,'edb2ddade7ea48b2b5f57b57c8cdad714da2407c95e5776d080fd2af8e03214d','beed949f9c7d40f0fde2b16cfaf82bd30516a089b8fa1906a241a522f3de71ee','9ed44100ed7ded24627da0e328a3f73e090db05c759410cabde10a90169a2914');
INSERT INTO blocks VALUES(310202,'95fa18eecbc0905377a70b3ccd48636528d5131ccfa0126ed4639bc60d0003d8',310202000,NULL,NULL,'2dfba901292506aad81b75494c6526cb388e21df3edfaa75062e42c3c96c9912','8372f99c5089ad8588a5ac498d43e2c285a3a4c033e4555530732b09e1e36f0b','ec036e3a078693ef19df99fa0504a6c1dc3ca05c0699caf4ed92ce381fc2e0a6');
INSERT INTO blocks VALUES(310203,'ab15c43e5ac0b9d4bd7da5a14b8030b55b83d5d1855d9174364adbebf42432f8',310203000,NULL,NULL,'f19076b8896c2e9f702909caaaea599d941e9399301691dd1c620c6b6c01e3c5','19cd07ad9ec3df1f1e3c6aabdee3079f3929b345497224c2165d160bdc69dcb8','08054c7bcd54dfb0a12a21d05a13d25961fb7925e3a623bee69e1453131a771d');
INSERT INTO blocks VALUES(310204,'18996fb47d68e7f4ae140dc1eb80df3e5aba513a344a949fd7c3b4f7cd4d64cb',310204000,NULL,NULL,'c2b4b4672f3567833f7689ee4a4f950255e68a3e8368772ab864828419065176','38fb0801db73b46e12ed28ca2fb358bbd6efd9644bb2249864e5c34acf492d22','8bc8c1886dd826d72349028ff4ec4d38c5f6866de478d3744662a9d4f0e1f672');
INSERT INTO blocks VALUES(310205,'5363526ff34a35e018d1a18544ad865352a9abf4c801c50aa55742e71630c13a',310205000,NULL,NULL,'43b5ca2b4bcbfebc564cf99067b351e4d324875416c1e21aea828756e543b7de','34bbbe1be6b1fbcc61f6da34c5ad99ed6c5143f3a2d4a4fa63eb186dd94e4dc9','6a32303767e28fbedd4f463b8666c2fc7f7aa2bd9c79be976d81d95cd9663fa3');
INSERT INTO blocks VALUES(310206,'0615d9fca5bdf694dca2b255fb9e9256f316aa6b8a9fc700aa63e769189b0518',310206000,NULL,NULL,'d2e360af76dab6744571ae5f9ceb21d2aaad9b42d1c87ab5ee9549507233648f','c333a62844425fbc5b5863e64416f445f1a02f6e1ed143d4500c48172ec83779','e7481f61b8ed5a148b818ed889a635f2e28a6705bcccb6102375553a0d7ea52f');
INSERT INTO blocks VALUES(310207,'533b4ece95c58d080f958b3982cbd4d964e95f789d0beffe4dd3c67c50f62585',310207000,NULL,NULL,'754504d3ac03899761a0d042496768cef714711afab73c76115ee62458b9b44b','14a71263a6285346e279edb0f03ec61fef0fd04b9c1fd5233bb2356346c9b098','6764b10b34ac046bf3b0d8e629370c252ac13740ca7bb3baf2ce1ccac85d516d');
INSERT INTO blocks VALUES(310208,'26c1535b00852aec245bac47ad0167b3fa76f6e661fc96534b1c5e7fdc752f44',310208000,NULL,NULL,'cf81663f37d9c353a124bb2a3e1cdf51c8eb0078aa511ada856c8b71b801cb9e','1693039374de82c74d37d5db10cdbeebf7a1ac9f8e395653c782d0fa88d1d98d','46be13f262caa86783f77c77a9a9ce8a1a8fae866640730672a2201eedf82b00');
INSERT INTO blocks VALUES(310209,'23827b94762c64225d218fa3070a3ea1efce392e3a47a1663d894b8ff8a429bf',310209000,NULL,NULL,'c4200a6881e0ded18a9989140d29984c19d790527693a05be9c833318461cf42','155ec14eaed33cc8248431bf6130e2cffffb4d2c9d007b435ba50fd723252843','f319ed6cad45b02d4733fe38cd6e717a1a2537dd0b36d82cd9365bab1332a7ae');
INSERT INTO blocks VALUES(310210,'70b24078df58ecc8f7370b73229d39e52bbadcf539814deccb98948ebd86ccc0',310210000,NULL,NULL,'4ba5e58a7fc651cbc58cd1390021b8d279a5153f114c4c518f1c3b363054046a','f271d9d31d08a0d143691c631e2b0b728def4d10e8c8ec3b5248093f7b6b4038','b0af00babd815532671a70d2b49a7d3987dba4f357280107a3cb07022d268569');
INSERT INTO blocks VALUES(310211,'4acb44225e022e23c7fdea483db5b1f2e04069431a29c682604fe97d270c926d',310211000,NULL,NULL,'11b9e7cc6c428bbd840a8a3c2495b34a30067cbbc15589bf93eba016b477df36','f08357aceb0028485f9f4c3952c858cfe37c62137e4b938a00acc3e879a7abf5','c454db71aaac850d41b136884120bd8f4736f115d45c4ea97d2f04ecd75d8b60');
INSERT INTO blocks VALUES(310212,'6ef5229ec6ea926e99bf4467b0ed49d444eedb652cc792d2b8968b1e9f3b0547',310212000,NULL,NULL,'6409a0f2555b872a92be674d1d4c09a9069350f649fa73e7db367d49fffe7347','f2a61d27660a0324354e67b60a9ecda378c86e30ffa9ea4af9ce7b1847073118','825a1e828d9150112689b0cd578eba6e8fac8d4e38ade9f76b31640a688e08dc');
INSERT INTO blocks VALUES(310213,'17673a8aeff01a8cdc80528df2bd87cdd4a748fcb36d44f3a6d221a6cbddcbe7',310213000,NULL,NULL,'a7323e7ff6b0b41c30092fef6a6d2844a7671c4880aa050afd92ee690eb5e52a','c53aa7a0f9121a0db250eec54772201cba2104f010b02dd5eb3df1e8e4276ad9','57487c06679b3dedbc5aea869e4186bd0eb9bce597c67b93f5511f5e97df55cb');
INSERT INTO blocks VALUES(310214,'4393b639990f6f7cd47b56da62c3470dcbb31ef37094b76f53829fc12d313454',310214000,NULL,NULL,'bb190b3cd299a892c05ec35beb187fd9ce925a84d9276f7da035d141c79cbfaf','04626fb0dde53fa59f108527c4d256f03ca252b8f9ba84ebef87a4a6aeb85069','cf0a0ecddbec7d1df1be97a56d602f17b5aa528f8e7e33e1747cdaf54e1305bb');
INSERT INTO blocks VALUES(310215,'c26253deaf7e8df5d62b158ea4290fc9e92a4a689dadc36915650679743a74c7',310215000,NULL,NULL,'fb51d7881a295005a571902d0ad0be52ac2a69b6f5dbf2fe09607775940005a3','cb3ce0886084e7833e805aa02277a87665a8ff79240c7255b2e882915b71085f','c28af3c715eaae609bc5f9b34c10f0f65f6eaa06ff9fbbf4efe4561fff641a3e');
INSERT INTO blocks VALUES(310216,'6b77673d16911635a36fe55575d26d58cda818916ef008415fa58076eb15b524',310216000,NULL,NULL,'b920515215c8384cf04fd0341dece933924f778bfad4fb52a414a4301747a9fd','38f008b6685fffe78162326f1671a81a25fb81fe90c6975b1da43642a7a64f37','2706eebe6859e7c99acfe677aa40a9a6ed0bca4aac60fef9b0ad199fc7e73cce');
INSERT INTO blocks VALUES(310217,'0e09244f49225d1115a2a0382365b5728adbf04f997067ea17df89e84f9c13a8',310217000,NULL,NULL,'5de885656c86c1a534c5c8b2f03c05b1e1c61d43e67051b8827b80ae7638c7a2','6e48451bd6d33eb2fe28e2fcb03bdf05e7d934d2e5b7b114d9ee181e69e88233','93cfc87af4ea31feef042d5038058a9185ae202c3b2b569f0a3ac184167b22ee');
INSERT INTO blocks VALUES(310218,'3eb26381d8c93399926bb83c146847bfe0b69024220cb145fe6601f6dda957d9',310218000,NULL,NULL,'bdde3cafcabd6ebcd8fa892b631919081e43c9f90a0f4b0517ba4a0094789346','c0c1a9fb87479d6af2dc9982b55093ba2ff3437fa872825674c30f51afce4bf5','e08072bafbb58c7127b3515e99e6366fafa4d1f8df9f54af9e49dc1e2095a351');
INSERT INTO blocks VALUES(310219,'60da40e38967aadf08696641d44ee5372586b884929974e1cbd5c347dc5befbf',310219000,NULL,NULL,'cd639a6b8b43be7a7fa6ae603abe3bb8b0ed4a257daeaa27e38566f74ac6bbec','a21bc36cc31394a62e0159d7d8fa2d5804a4658e6db2a78ea60f70ed574cbfa3','de9b0e4e318d4952262d799cfc33ee691488f0bd2b677b8a62cde9cd95b54f95');
INSERT INTO blocks VALUES(310220,'d78c428ac4d622ab4b4554aa87aeee013d58f428422b35b0ba0f736d491392ef',310220000,NULL,NULL,'50a93f2a30dc4638ee1a2fec501c03be0ef2260dff4fffed32c460fb9331276c','d6cc9e98d21024b4fee3cb075a779174b8b5fe13b93a64aac6e4f3bf9fb9aae5','6ac98e14049533678bc195dc2b89ca7a3334470666d9dc764acf75697fba0b44');
INSERT INTO blocks VALUES(310221,'cf5263e382afd268e6059b28dc5862285632efe8d36ba218930765e633d48f2d',310221000,NULL,NULL,'6c62946096ecb97d62135b6d1703d318672d47a57d20f0b546cd475b1fbed4be','2bdbe37dfb30e48a725426957fd8389b6eb00c820540a1c451c67e9b28c3e301','47a4a33b0a6e26f3a33e4f4a9bd9dded3e890d344ca3d8df460ff52687767ce1');
INSERT INTO blocks VALUES(310222,'1519f6ec801bf490282065f5299d631be6553af4b0883df344e7f7e5f49c4993',310222000,NULL,NULL,'0b55f261f42f9ed634acaf1a3fa54a84c8c2c53b0094aea83b8c6c47df41f808','0a7abb130567c00e6136e7c4c5f9a069cc42c35a67698bde5d1f669af8f84d2d','476db71e417d3d924f2b06a501d189d3f47d815b4714829a8513a60487785937');
INSERT INTO blocks VALUES(310223,'af208e2029fa49c19aa4770e582e32e0802d0baac463b00393a7a668fa2ea047',310223000,NULL,NULL,'db80e32a9fa70ac3bda0a68ca6aa70d0d945641c4dc8a974618bcc3bd2323e71','492d88ebd01f80169a294e25d96bdd0fc072242f9fa3d16ec9338c3b4f9e040e','b6db2d2c87905dbf54b89ea5fa4fd4b863254f83376303c7a495a42aa4312b64');
INSERT INTO blocks VALUES(310224,'5b57815583a5333b14beb50b4a35aeb108375492ee452feeeeb7c4a96cfd6e4c',310224000,NULL,NULL,'94251828d3eb2547f2ff3466d54dc779403540b3d295bb3a838c2c65dc47cbda','e2a3490fb825ea514aed13409f369b0c955f5e53f5911ce05b3f95b0331dd232','689143f32581927ecc39fea2473912321141dadf121243059a774a71721637e4');
INSERT INTO blocks VALUES(310225,'0c2992fc10b2ce8d6d08e018397d366c94231d3a05953e79f2db00605c82e41c',310225000,NULL,NULL,'0fa47a3e0c6c7a10af36dc052316e1a33139a05baec4ece20eb1d7a3b702b6ca','ec2435a74dc8798540cc8a26a2f048d996aac8c192a739be5963008caa64fb2d','3240345773d0fde77d4256d4fca501047c19702d6e7d88ef1d1b768160dad769');
INSERT INTO blocks VALUES(310226,'b3f6cd212aee8c17ae964536852e7a53c69433bef01e212425a5e99ec0b7e1cb',310226000,NULL,NULL,'c825070506d055275302ee19f98f69e7ebd58e4f3d297b1b56026cd81ca6bb71','571511ee0183507f1a01e997a755cf06b9aa58e2ddb2451fdb380bfb8f90add4','7f9b7eedf0a36bd8f89189a573939fa01e7488192c0441a6bc448cc870fcea50');
INSERT INTO blocks VALUES(310227,'ea8386e130dd4e84669dc8b2ef5f4818e2f5f35403f2dc1696dba072af2bc552',310227000,NULL,NULL,'708f1b03edea6a7ba53b161c91d82c83e7fdaa39e28977cea342eb05395c9fba','ab4a7e9ba0077c4a0a06e5918de92de01bf8a4eed8774d88072db78fefe2d834','f58d71a812009a9af408e9d38abfc8d2e115cb892cbbd674e272cea4b96a71a7');
INSERT INTO blocks VALUES(310228,'8ab465399d5feb5b7933f3e55539a2f53495277dd0780b7bf15f9338560efc7b',310228000,NULL,NULL,'26cd9f3486d1ab73536ad3237ad0b9ac550121ff6e9051d933b4c556394867ee','eb073b0f5c0f4550bc7a2bd03f2730d8bfe19d484926f222dbdac5ea510d1771','4150c03b748c3ee52ab482ef0f3da11a3df918b197bb3b7ef4a708d485971c27');
INSERT INTO blocks VALUES(310229,'d0ccca58f131c8a12ef375dc70951c3aa79c638b4c4d371c7f720c9c784f3297',310229000,NULL,NULL,'c4064516fdd94948922ebe20e834f3cad7fbcc44e8dd99b0c6ff1a80a41dd296','1c5b341f751e4ba09edca0b8e2c5bb4928ca046c9fdd89d956ce09c03031d0ca','7857d215b550dced55911cbc9fa6b41fb58176fae2665fd1ada4a81c85cf7822');
INSERT INTO blocks VALUES(310230,'f126b9318ad8e2d5812d3703ce083a43e179775615b03bd379dae5db46362f35',310230000,NULL,NULL,'919f82a675cc2747b52d53feda9bc3db70df0a626cfc6db7734282145997424d','3219ba515fb1eceda95a5c61cb2eae3bd002ff169e8779e65c47a13a12f72006','f6ac61b97c054e2da0dd7283f37a8f66ec8ae7e5106a55a3f6f76e3a65697461');
INSERT INTO blocks VALUES(310231,'8667a5b933b6a43dab53858e76e4b9f24c3ac83d3f10b97bb20fde902abd4ceb',310231000,NULL,NULL,'b585efdca8b230d5d0477e27e33c46bdae4d4d13a320f72d48553718c82619ab','53dd33c3347162f83072025444c52061e8d0bb2dfb5a78a6e28f5a4b7dbf3599','27f2618ad8f99c679609b3dc926e8ca0b8a4df8bf77dba29f19a73b394bca2e6');
INSERT INTO blocks VALUES(310232,'813813cec50fd01b6d28277785f9e0ae81f3f0ca4cdee9c4a4415d3719c294e8',310232000,NULL,NULL,'61ae8d3c6bc169cfdafbd3a16c6b09588e7862c0d967c637bf7a81971f549484','48f265496b0a3d402399e707de644e1d3f85901f4d1bc8be2cfb9ea905733749','8b98157f4ecc6d7084ec7d16f2342404b79b8273f1c018c1895852cb334a57c8');
INSERT INTO blocks VALUES(310233,'79a443f726c2a7464817deb2c737a264c10488cac02c001fd1a4d1a76de411d6',310233000,NULL,NULL,'ec03482b84af2c4e39d4ae39cb7eb08f2ff44bbee9ddfbae8526f28f619014c7','694b696ac29e22003e174fb67169977f9f096bd1f97123b8cdadce76a386b71f','614c2bc05975478b9b9272038ed6479b2639fcabf2bed47b960981a714ab1e39');
INSERT INTO blocks VALUES(310234,'662e70a85ddc71d3feae92864315e63c2e1be0db715bb5d8432c21a0c14a63cd',310234000,NULL,NULL,'752d6e11a32e9773df8c8caf6c88dc976d1b2ee83bc7fe83ec92a13d906b3fb5','57dab41f9b2d431fee06a26b72f5bcb78f70ba26ab70845623baf0f2ff013b21','a1d2b4e9b1b8d7686e09ab15a2be13520eae3c7f508511efa53585e16bff28ea');
INSERT INTO blocks VALUES(310235,'66915fa9ef2878c38eaf21c50df95d87669f63b40da7bdf30e3c72c6b1fba38e',310235000,NULL,NULL,'2623f294c75796eb33bf3bd54dd60cd1f388df5e2a2bd611925e0b4b2ae54034','7403e059eba339f37b909d0b1dd876d3d41c410f8404293e752a4b3818c410d0','cac309ad345a2a7ecacd68ad522385f93e5803d926e94d2273177264d18ebb8e');
INSERT INTO blocks VALUES(310236,'d47fadd733c145ad1a3f4b00e03016697ad6e83b15bd6a781589a3a574de23e4',310236000,NULL,NULL,'4ab86ec570c3137acb69947799cff3e2b9ed259614988c414579eb2ba78db253','056dd0fce011d613d395f657acda2715bcbb466a9aa048169b2142a8ec220b63','171fdc422f011c41693b2467947cee05e9ceb8d2959df98661cfc8bbae70fc1b');
INSERT INTO blocks VALUES(310237,'2561400b16b93cfbb1eaba0f10dfaa1b06d70d9a4d560639d1bcc7759e012095',310237000,NULL,NULL,'b43837305599670c0351c467d42ee01dd2d4db9739e70956fb1e2c2ec29cae59','9bcfa3fb41ee1e3a3078c16e5f85957d97f2b82846370701ab2fa1746214286f','575e5014b6df6d04d103f99f8470ae035607a291e3621962f17c2969208d9ab8');
INSERT INTO blocks VALUES(310238,'43420903497d2735dc3077f4d4a2227c29e6fc2fa1c8fd5d55e7ba88782d3d55',310238000,NULL,NULL,'d6ac59104a8bb1c9bdeff28e3d79aa227b2e36452bb393b2010c07c49989bb3f','2d83720452da80b3a92d7740ce322b3f70efaa2a38a47963fa5d9b82bb40dee7','44974684dceb572decc26493c044211221df2727ed001e8e72695906a0da73e1');
INSERT INTO blocks VALUES(310239,'065efefe89eadd92ef1d12b092fd891690da79eec79f96b969fbaa9166cd6ef1',310239000,NULL,NULL,'6d324be1402bcecec8636efe1d296abeaf180ca3945cafd4640588abfc2fb622','b8c3319e90072ee7e92c6c165e8ceb3169c366d80fa72928033ef92a7a5e98d9','12743c1b022d34accbcd65602e25a299ad1cd23562d4b323c8deb1315b77788c');
INSERT INTO blocks VALUES(310240,'50aac88bb1fa76530134b6826a6cc0d056b0f4c784f86744aae3cfc487eeeb26',310240000,NULL,NULL,'3d9a97e083b433c84bf35926f985fb39392e99eaa987093b5558c6d51c0c3257','ccd2dd2a9d996d834d5e3d278796cfc2a6553cfceefc3b7c5731e1572a96065d','9d0084387af0c15d7382c07b71f109ed1efcf46a1328e7c45a8918ecaf41c2f9');
INSERT INTO blocks VALUES(310241,'792d50a3f8c22ddafe63fa3ba9a0a39dd0e358ba4e2ebcd853ca12941e85bee4',310241000,NULL,NULL,'744238a23bf617d1274d894e2d987ac2bd6554dff98ca81cd198928d918c3a4f','99821b1a2cf4b080e8887d5ea166dd80b52c0e91ee6415360b567316b25007b8','950e00bdb8379a69a6d2bf274632851360822c8a31b9b4c8c94d47977ef98485');
INSERT INTO blocks VALUES(310242,'85dda4f2d80069b72728c9e6af187e79f486254666604137533cbfe216c5ea93',310242000,NULL,NULL,'4a834e1435a3a530c130278639a452b963ed8ad682b7e4ba40bbef3c0884970f','f92537d665bb9ad5a5c6864730d1a3e9d1090d1e69badee8267a2084565b1f67','60c943bdf41d7090d374096ab7dab91b4709f4af5646a7283d6963e934a71815');
INSERT INTO blocks VALUES(310243,'a1f51c9370b0c1171b5be282b5b4892000d8e932d5d41963e28e5d55436ba1bd',310243000,NULL,NULL,'3c38948a1daaf2c44679c03c232d867524623c0af54c25c58ab80141629a3411','e31b417bd9ea4f23af65b775b61593055e7d0503954f764800a92df205af53f7','9879813097205c937dee9713b8f73e1fcac7fced5243b301354d0c53b2bc8097');
INSERT INTO blocks VALUES(310244,'46e98809a8af5158ede4dfaa5949f5be35578712d59a9f4f1de995a6342c58df',310244000,NULL,NULL,'40e163a4b75a64a4373d781d42af8acb0a7357208facab4f670cc80bbc352288','56fc2e47c84ad20acf8df41c8deeb54fcb6f231b5b253e935c26d7c1cfa748e5','dfc0241d7a2a7967e571e4bc77365531c02bab3e104ecc970671ff3b428b9555');
INSERT INTO blocks VALUES(310245,'59f634832088aced78462dd164efd7081148062a63fd5b669af422f4fb55b7ae',310245000,NULL,NULL,'a80e1a21f48ebe40e4d1181fb5779c2aebd334a7480455720d8dc91420adc48e','ab4651fb7078ddde0bb56c035e70ae5de40d32163c4251f82c665e1f33c495d5','3f5f50dd2c4ccd4d46c70f6c59546e1cae1b1bfe7e0b9f433180e953fe3aa976');
INSERT INTO blocks VALUES(310246,'6f3d690448b1bd04aaf01cd2a8e7016d0618a61088f2b226b442360d02b2e4cd',310246000,NULL,NULL,'b3621966a7f1df8ba2e3150d9dc04e7c58784e05c09fbb47c0f94af6324d42d7','affa09c0761d36dd065aef1d15369a1cfccc80b136a44a7cbec747f4f4012625','20ad5f65c97bde67c641217f0efd752638b719ea3f53dc96f9a73964e944f56c');
INSERT INTO blocks VALUES(310247,'fce808e867645071dc8c198bc9a3757536948b972292f743b1e14d2d8283ed66',310247000,NULL,NULL,'16c29dfb1ada9a941e4d65651e6ba662eaf0d32446390014494811af709daaae','22a6159b192c99370be546b90f5fb3787f1885e4c8ac9e40715fced3bcdfc555','4dfe172bb8a74056921fc9a6ea2df3ca88e76a342398675487fa049b451fea3c');
INSERT INTO blocks VALUES(310248,'26c05bbcfef8bcd00d0967e804903d340c337b9d9f3a3e3e5a9773363c3e9275',310248000,NULL,NULL,'46a1d502bb61030ab25f990e1d4776fc91074dd798fc6cbb86061fb5f0dc3279','6e4d37d871bcb5780e76082ca6101fc728f918f012fc81eef5d1a2fb36b9b82f','8b507df27aa2cf22f92b8c3c458af8147ecba4153ade9d9d9475be3481335bb4');
INSERT INTO blocks VALUES(310249,'93f5a32167b07030d75400af321ca5009a2cf9fce0e97ea763b92593b8133617',310249000,NULL,NULL,'bd30958dd32410059f89b5d1ed05dec1fa7d4a1ac5091a9c86d37438c1daaea3','e7a8eaf1fa1cc34e84f6361d63c5c16f5ab94bdacb07b0d37c47ab252d84dd2a','8653abf6aa05c3c8ef91374ea753d270dbcd0e24cfbe8889ecaff572f22d46b9');
INSERT INTO blocks VALUES(310250,'4364d780ef6a5e11c1bf2e36374e848dbbd8d041cde763f9a2f3b85f5bb017a2',310250000,NULL,NULL,'593844275ff962ef32ae358957dcd7c4578bc155bfd88cb6ba2cb6db7e4bdb73','7b449e60732197d41203abe6a86c445161e478a33f0ab67658931f9bdbe6d225','907ec7bda39a91dc039bb37790f22cc5867370e62ba07f22b8ebdf6b4cb81b73');
INSERT INTO blocks VALUES(310251,'63a3897d988330d59b8876ff13aa9eac968de3807f1800b343bd246571f0dca7',310251000,NULL,NULL,'00790d2383678d2627b583eda36f39bde92883829b93d2628c741cf469cbc337','caf1f135de84332898001c642c6b23f58ed6445ac1a4cc438c3bdaa8cc120c55','3f22b2d661edcebeecf60b8411daef78db789875c2df1dc6cbcba2de9792be32');
INSERT INTO blocks VALUES(310252,'768d65dfb67d6b976279cbfcf5927bb082fad08037bc0c72127fab0ebab7bc43',310252000,NULL,NULL,'51238eda52d2c02906de13b4f240b2560234e6733a78658c9c810f3b0da7f1fd','9110af87aaaa66faddc7315ad572d479227177f4752daffc9eeb5326007c4d76','38f93ead0866acc0e96b3ea140661f2ce0bf25afca404128031763e90ac207ed');
INSERT INTO blocks VALUES(310253,'bc167428ff6b39acf39fa56f5ca83db24493d8dd2ada59b02b45f59a176dbe9e',310253000,NULL,NULL,'78bb0b7368a4a11f6f6e82374640dff9a15212a34ab009842aa330557458412e','29a1f57e43564c72f68f9a7e89ac5c717b4029b5dc8067d49a52f67f9b9524ef','08d80894df88c46053d14437f32af70b84885527120a762b94959b3444cc6d80');
INSERT INTO blocks VALUES(310254,'ebda5a4932d24f6cf250ffbb9232913ae47af84d0f0317c12ae6506c05db26e0',310254000,NULL,NULL,'dd78d671bffc09ef422a2e78f8b86c09f9d857e9612b1012a4c1d34e9a904568','1c990a8631f25577b8d9583c6df7c0ebf2858a472a24e2eac592f1c21e10e856','fd2558dbc45eab42a1ac67e57c6f85b772d646199332789740b2b5d3ca43479f');
INSERT INTO blocks VALUES(310255,'cf36803c1789a98e8524f7bcaff084101d4bc98593ef3c9b9ad1a75d2961f8f4',310255000,NULL,NULL,'5e234216c346a42fa291f82db4a4bbd4067a191c5943bad6d289119e04f1a457','43f2569e2527856ce3e9ed8da8f1f0d8b0acd674b803f03b468e670f6d97dac1','9d1db522e7e208e720197b9e7c8ec947edc7f0258fbb8c197919e263deef93fa');
INSERT INTO blocks VALUES(310256,'d0b4cf4e77cbbaee784767f3c75675ab1bf50e733db73fa337aa20edefdd5619',310256000,NULL,NULL,'fa2fd79c10830d09acf216e1d185848b6366f31bf61af06ca5ecf8983083404c','bbbb035c0c134b270bb6c436c5e54665f92c82154715708cfefba11f50b8790c','5c0527936e1598246b31846b28d3726bbb0fc92ee728974c054d04658b3d28aa');
INSERT INTO blocks VALUES(310257,'0f42e304acaa582130b496647aa41dcb6b76b5700f7c43dd74b8275c35565f34',310257000,NULL,NULL,'9fbe93ef51bf55fe68323af3338accd41728dfd4cdb1da3d6871d599fb5d27ef','1423e6a8b603c891ba9abe87c7b855fbbe5aa583243436945e7d269f43c23919','b49ab5b4546b42c4959128097aa04d1e6de47493615f3b7c3207f59473c265ef');
INSERT INTO blocks VALUES(310258,'3a0156dd7512738a0a7adba8eeac1815fac224f49312f75b19a36afb744c579f',310258000,NULL,NULL,'200d17131d04a058c75c7a85b97e42fdc695854ee8d077f7b27fb20ec1412cf8','a6f71bd27045b1b2bd1198aca8708b9ac5121372b4a0f130e26ac8b92dca5015','5aea7f0be2f270c885357d38ee77340e3e8c56604da92f23ba2fb7cfa4c483cd');
INSERT INTO blocks VALUES(310259,'e5ed3cdaaf637dd7aa2a7db134253afe716ffdf153e05672df3159b71f8538a9',310259000,NULL,NULL,'912c9422436d2169c0b7ff383b8bc523c5365bc3c1158d86e5ec7987ddcb0401','68dade8ed5e6217a9fd70bf1d4661cbc1e6f9b58ffd4b5822c73dce2fd947ec9','9951bfd897b50685e30eb8004363036a2252ce8bb9e0ab72a48d512a14f2485f');
INSERT INTO blocks VALUES(310260,'8717ddcc837032ad1dc0bb148ddc0f6a561ed0d483b81abb0c493c5c82ec33cd',310260000,NULL,NULL,'931d3214d64e7daff87f5d70ac9e0dc1daebc1afc2334efd0512fdbad18cc4e1','c47867b6b622b3163fad7394d64e1323d07f81b75b8b4ed1e5d415d211da7ceb','b3bc35c5e118f690b2e5de4c2480f6bdd4b9871070e826f9e1b85584316a4caa');
INSERT INTO blocks VALUES(310261,'a2a9d8c28ea41df606e81bf99cddb84b593bf5ed1e68743d38d63a7b49a50232',310261000,NULL,NULL,'8fa1c2a7587e206c18066a671a64256e8fa9941c2faea46156cc0ff31a1646e1','4580e9fcca78577cdd09c54674c5cf334f93fa2429194f09ec490674c9a76e14','9f217c5cc7872a245e2e5605a31942a2b54bb1a4dd5a3b90fbbe2ae82f708d81');
INSERT INTO blocks VALUES(310262,'e8ebcee80fbf5afb735db18419a68d61a5ffdde1b3f189e51967155c559ee4ce',310262000,NULL,NULL,'32c294546290e27a2433cf5c90da5c92e846ac95fb82f309c776c7cd9b5edfb1','e5923cbd0e8b8f3916ebb7c943c66fe9d3bc502921ba2c09010b700d8d4017c4','706f852fd96309132adb1f8e0249970f81efbe28150b2c0176c55926067dffbd');
INSERT INTO blocks VALUES(310263,'f5a2d8d77ac9aac8f0c9218eecbb814e4dd0032ec764f15c11407072e037b3c2',310263000,NULL,NULL,'385ee6105c723c16f6e0f35f5d7bcff7cdd7241aefc05311f6c5a8ee6dc24cd7','bb9162f7c22a80b50140c36070a6fa95f55449ea3c0559feeb6877e9d567b29e','f989e9607bbaba661d812542bb6603698d199ae35a24a1f1b02deeeca34430e3');
INSERT INTO blocks VALUES(310264,'ae968fb818cd631d3e3774d176c24ae6a035de4510b133f0a0dd135dc0ae7416',310264000,NULL,NULL,'6effff8293e1002bbc4459708c08cc1728a8e98632a89fd94553b015eb6094d7','d2bc998ed04b245d21774ace4385bef1e281fc079b4de23ed108c460248dac56','2c81dd6c6bc57d40f36d4c7bedba39d4932d501dd1f0abb7618fea68f014019e');
INSERT INTO blocks VALUES(310265,'41b50a1dfd10119afd4f288c89aad1257b22471a7d2177facb328157ed6346a1',310265000,NULL,NULL,'ee29f9e1b9dba3251a27b526f53d79d7e98890afe0b6978f33fd1c4f57344d0e','c3a33ccb0e89274121d200b2d755b7bb58f110380ee80cc51d051ed3eef27a51','adfaf13d1b525798a4977d073573833604dc1261b8fafcb355f9cfc6bb4c38b1');
INSERT INTO blocks VALUES(310266,'1c7c8fa2dc51e8f3cecd776435e68c10d0da238032ebba29cbd4e18b6c299431',310266000,NULL,NULL,'b6044b3f0a9004c93506d02e75c4782bbe12b2c388efdcacd89c5760df42b557','69c0d5d29f67a8b92dc0dcf98325a19aabe6bb1ec5283f41065850d6f18e7173','1c63b5fda8d5869b5e126852246d58a761a1ec9a692f8c234934d330959b8a5b');
INSERT INTO blocks VALUES(310267,'c0aa0f7d4b7bb6842bf9f86f1ff7f028831ee7e7e2d7e495cc85623e5ad39199',310267000,NULL,NULL,'fb3f26ce8bd4aac1a02ba09c764d35f9cb56dba75f709f92422b01fdd7a4f49d','a9b2388dc4bc18cd7d4e2a93148e065d09e59706dfd6deddd546283b709201ca','2a93ea1d3005f2f11690a2e8646abf557d67a8cf68fa1d0d47a5968b84d029fa');
INSERT INTO blocks VALUES(310268,'b476840cc1ce090f6cf61d31a01807864e0a18dc117d60793d34df4f748189af',310268000,NULL,NULL,'48f730944343ac8abfa3f7a852075232c50c1677dc1237428375b252a0c89afe','cd7ed831ec82d62d0b75688a19e65ee42ba638f3eab0c453438b600d8ce50d4e','13b83d9b00eb224dc7c2c21a045f9e3e3671dee1b5e9bc36cb58dbcfd3422a40');
INSERT INTO blocks VALUES(310269,'37460a2ed5ecbad3303fd73e0d9a0b7ba1ab91b552a022d5f300b4da1b14e21e',310269000,NULL,NULL,'510ad44b41fc8021c0d1172b3dc6b2ced9018ed52f42f3d4956e988943b6e71d','2309d5756ab2606437195efda5ba1bf2d640200eb709c840abea6a13393e7fc5','c36af69f434ccf3a5061dde133b510456931830701c0af3ff2efd73b053ed8c6');
INSERT INTO blocks VALUES(310270,'a534f448972c42450ad7b7a7b91a084cf1e9ad08863107ef5abc2b2b4997395d',310270000,NULL,NULL,'31fdf38a3c5f9181bfd284d0d751093c1f41945fa8d7032575d934e2e2376fb1','c9c32658a86d2c48e4efb78418d2c7e24ed84e6de7e6694b4acd57dd1ab71499','31a4a0b27da75be37fd210d20212903dcf5355e3ff52a0b4450d716afc8a1a6b');
INSERT INTO blocks VALUES(310271,'67e6efb2226a2489d4c1d7fd5dd4c38531aca8e3d687062d2274aa5348363b0b',310271000,NULL,NULL,'6195bcbd82a2b229910e6c8bf33f047caaa43e1de6e2eced813bdcce81057bcf','6d5cc302c32033a77b4d8b2b6519daf2b44f193dac76f6840927af5cb6df5e65','c21a8868ec0af263ae89b77891dde1b24690b63c217616133d5c504c957bca25');
INSERT INTO blocks VALUES(310272,'6015ede3e28e642cbcf60bc8d397d066316935adbce5d27673ea95e8c7b78eea',310272000,NULL,NULL,'1e9f54fa5b4811dbe7ef7855b95cc095c9763e866038c51f80a7593bfe9d2f01','1efb9ff578179d65b3bee8c17e3cbff7e29b1e8022e8092846be7516b44b62da','32b93f4ea786fcbd265bc6a544214c97cf1656b4d700e2d66cf33513371c86a9');
INSERT INTO blocks VALUES(310273,'625dad04c47f3f1d7f0794fe98d80122c7621284d0c3cf4a110a2e4f2153c96a',310273000,NULL,NULL,'04108d79e2e448ee634fc931495319591d5083e2d5d026145f00b3b1853c97c9','205d3fbe93aa88b931b4e42f3def22e26cbe1ee8c5bdeb29814470e8eda6073a','43388e15fcfaa05e74fd6257589ca7816af9360b4ee7fd826ba95a2e96cf527e');
INSERT INTO blocks VALUES(310274,'925266253df52bed8dc44148f22bbd85648840f83baee19a9c1ab0a4ce8003b6',310274000,NULL,NULL,'4ff9f4036369703d3b80fff33837fba9786c991a3a926619fc8bb7b3adc38a24','69bf5619ad4f5f1567d77929a2e74a2c630d5297cc98da3668c2e18159c125b1','97fd8a5742e567a70186b043fa86b0c426e8b6d21ba9437f21a58de1e57ef8e3');
INSERT INTO blocks VALUES(310275,'85adc228e31fb99c910e291e36e3c6eafdfd7dcaebf5609a6e017269a6c705c9',310275000,NULL,NULL,'c613fccca1450f1868426b7c900452ca09b6c83589d72bf84c8afcc04b1fc0a2','2da1e08f031c076fc813eaa65c83329cc8e3b2d6e933cca8f1d8c7e8c7ec8441','100b3f9f48aec5d21969ee770135b1684bcb057bf1bb0848a2d82f95d34aa6a0');
INSERT INTO blocks VALUES(310276,'ba172f268e6d1a966075623814c8403796b4eab22ef9885345c7b59ab973cc77',310276000,NULL,NULL,'0964596a5bc5e655abcbf7b7070288223e6f51d324ab56e9335430c3a62b02a8','89b0897955551351dae7ee110fc0c29ee5461a07fc68773f121fa7570a17607b','b1f5da79623f607901352dfb6e53ae1c269d4df619ce03ea1f1118605354347e');
INSERT INTO blocks VALUES(310277,'c74bd3d505a05204eb020119b72a291a2684f5a849682632e4f24b73e9524f93',310277000,NULL,NULL,'d8c6969dd1f2609ddaeca194440cf7ed142d896553ad51f6e474d141a402daa5','03ab0c4e11beb53eaa0ea8d88acc05232fb0e7a76b99ad96ca28d3a0b67d9d9e','9622e45126874db9d73a36338bc3c429da997845f07576ba37675f154d705b0c');
INSERT INTO blocks VALUES(310278,'7945512bca68961325e5e1054df4d02ee87a0bc60ac4e1306be3d95479bada05',310278000,NULL,NULL,'71a060d923b31d6031b826bce24c95312acc68cb17a0b8569797f2422dffaf32','c4e9e638bc35e137a99d904ef652d16dfad37d8883f5457e011d5319e434bca6','4e7a828ae6b1b139511d0c32ad26897ea60853abfaebc1586a1a465add512a88');
INSERT INTO blocks VALUES(310279,'1a9417f9adc7551b82a8c9e1e79c0639476ed9329e0233e7f0d6499618d04b4f',310279000,NULL,NULL,'5491e20db3b734e3bcb83d89fba3d3cdbd23e04a617cb61e344f67f5caf37ed0','a2c187ce056f43a7d6c868538ea3d40ddd18ff8efbd97d29935c4d777c723f08','dc8a5ae63a6d007ddc9f5c24fa386831444c5149833436475724b38b6f72b1a0');
INSERT INTO blocks VALUES(310280,'bf2195835108e32903e4b57c8dd7e25b4d15dd96b4b000d3dbb62f609f800142',310280000,NULL,NULL,'4dabdaca4e18c632095694a0dce232842e33c5464cac7c9fe1924cbebc270667','bc9586d930b8d1ac642b875b5ab319052678f81bbcca117444aac68ba19afdec','5c0bdf822751ef24391dd7ac1cf78d5a0d40e266e4cd3490e7262dbec118dde4');
INSERT INTO blocks VALUES(310281,'4499b9f7e17fc1ecc7dc54c0c77e57f3dc2c9ea55593361acbea0e456be8830f',310281000,NULL,NULL,'dad6cea793dc8fd3d8c3ad04d054467e73b81603392729987c593f8ca67c3be2','f42240bef5829c734891eef46aa4eda5a9eb11b1e61b4a45d49ea6b5ae89d330','988687b5d68279c178b73ecd23477d817c636695d28bd97e68dbe528f3e0ad91');
INSERT INTO blocks VALUES(310282,'51a29336aa32e5b121b40d4eba0beb0fd337c9f622dacb50372990e5f5134e6f',310282000,NULL,NULL,'42b1f66568eab34aa3944b0eeebea5296d7475cc0748ae4926ddbab091de7903','7729f9f170dfc2487690c62f565afcf98703c2bcad4a9602706b6ff8993f2ddd','2c3a7740d61a859a049f6e1208b37e237267afd8a3503f667fea1aba6962266a');
INSERT INTO blocks VALUES(310283,'df8565428e67e93a62147b440477386758da778364deb9fd0c81496e0321cf49',310283000,NULL,NULL,'edfae1059d89469e4d8c9285bafe05968e62c35504ce5d5f09bca4bd8ac0b698','2b83e4aec5fa15efb81aa40b1062f845e5fd7c76f92f25afe14c7c7cc289e26d','59021374081d6c0473812420225a134a1a8cbf9d4f865781bb033762d016c0c4');
INSERT INTO blocks VALUES(310284,'f9d05d83d3fa7bb3f3c79b8c554301d20f12fbb953f82616ac4aad6e6cc0abe7',310284000,NULL,NULL,'2b9d8a4322352981f7033af84e111c94511ac9b87d7d2599cdf5f2814b45a42a','8097c671edadfbecbedb11c1c948f38f18730cf5989cbea11f93aa0729591022','d8cc12a6ee6e39830d3f1798d8a2fd554d63694a6f1a354f649bf330f0e3c106');
INSERT INTO blocks VALUES(310285,'8cef48dbc69cd0a07a5acd4f4190aa199ebce996c47e24ecc44f17de5e3c285a',310285000,NULL,NULL,'63d6307a1f8d09526578c4b1776e51b40cfb5ad78d01dedd3e23d99f1efeda19','4e2cf36af2c392b7caa8666dd438a353beb83a2ede8eac71d5f7d9f4798e9790','a5b630d048abf4db7f2381a7935be2136b9ff517648edadde36b3c761ffcd749');
INSERT INTO blocks VALUES(310286,'d4e01fb028cc6f37497f2231ebf6c00125b12e5353e65bdbf5b2ce40691d47d0',310286000,NULL,NULL,'a42dda85ec8530a307a1f9e7048d4384b229c2637305eee0368ab02957f5b31d','88e86aaee0a7fc0d3e9d897d83fa848fc065e8714f6b0cf602b3b180f2751219','cbba849b94cb61efba4968199c90249759e9146c3e7e4ed8ede374c1ec68c896');
INSERT INTO blocks VALUES(310287,'a78514aa15a5096e4d4af3755e090390727cfa628168f1d35e8ac1d179fb51f4',310287000,NULL,NULL,'96bdbe4268d82b3b82d776eab32019393f5de5ec5ea2302c0c2a9aaa068fc2a5','e113db6d6384d0ace5149b9897b7fed7d98c9e971c95667ea2b422763b1593a8','a243bb0249cf65689a6bcf4d301a3df6c22a49481f5992b13115ae98fe427b31');
INSERT INTO blocks VALUES(310288,'2a5c5b3406a944a9ae2615f97064de9af5da07b0258d58c1d6949e95501249e7',310288000,NULL,NULL,'0c96ab72568c907e27db628c30825012ea3ec633d3debe3256dbf4d3c95f81c5','35379f1ee69f2dece8a3b70434a4c2d15b3f6608edfd707e0b40aead9267477f','adb70b00b3c7c9e3e9834048df5ca022c167858731b055091e21ef0df1a03ba3');
INSERT INTO blocks VALUES(310289,'dda3dc28762969f5b068768d52ddf73f04674ffeddb1cc4f6a684961ecca8f75',310289000,NULL,NULL,'921af39c1d31264ba86b6e6ca54b8dbf40bfbee574c1278d78d686b20159f99c','ff29f4cf027d684fd94cfb324f2a843932f0f68cf4bc0d23a4bccba4b5ba02fe','2092ee8276cfe940e232de3891e5af396809656e70d1b7747bd73bfa80c2a8ea');
INSERT INTO blocks VALUES(310290,'fe962fe98ce9f3ee1ed1e71dbffce93735d8004e7a9b95804fb456f18501a370',310290000,NULL,NULL,'743e6499fe6b1b82914457c8bc49c54abc0dbae277eccc0b7fcc203e86f89f6e','446c7e150742d7b66cb2300690b796ac0347b7ff4855a7e51e3444c54425a31b','3e505165a502c3892dd46e2a72fdfc5c9cac5fe6c545065c88dc0cf5ede18a2d');
INSERT INTO blocks VALUES(310291,'1eeb72097fd0bce4c2377160926b25bf8166dfd6e99402570bf506e153e25aa2',310291000,NULL,NULL,'194402bf041424fec8b63bd9b5851c5b0d04958b5851bc9fbcbcd9e683079e7a','7d8c7d34d884b22d6f64e14e4395b5a07d6f9aff02eb4d24201a0d717e7e5604','f851d85b177265ae177de6085e1e1161e794de259babcc3d96fe803062049787');
INSERT INTO blocks VALUES(310292,'9c87d12effe7e07dcaf3f71074c0a4f9f8a23c2ed49bf2634dc83e286ba3131d',310292000,NULL,NULL,'c8b7f8f3ef06df7a9c7eff346d2a9f0d1f1377c064c3b3c3bc2aebc845caee95','b2d6cebf4f0018b8615b8591261feac73fefdf7369974a4ecbf072ec6cb38fa9','e57975aadd3eb48d7f9c2c6281c059522733e437ecd74e42de44ae28c616a511');
INSERT INTO blocks VALUES(310293,'bc18127444c7aebf0cdc5d9d30a3108b25dd3f29bf28d904176c986fa5433712',310293000,NULL,NULL,'0c9c8a8558e14645d818621e4a97c66cc9bc67023141c5bd00830436e5760fba','13a9f7e4926f7538ab4273194ee36b1319802df07fb6a92bebab8965feb0139e','a307eb9c7bb283a462d39704a8fd990c0c14a398169b77866a13f56435581fe6');
INSERT INTO blocks VALUES(310294,'4d6ee08b06c8a11b88877b941282dc679e83712880591213fb51c2bf1838cd4d',310294000,NULL,NULL,'1cb04936a9ee72f465e4d6d4fd6f2ac99cacd74a510d74f017320dc7061c4b02','66c1dcb12f948fa3eb97a1517839e5efa169cf2194112f1de978fe9ed6671609','4510c13dbf7c8e384b7ada6beca490a9d693a2fd8c378ebbfdf34ec874d9eb13');
INSERT INTO blocks VALUES(310295,'66b8b169b98858de4ceefcb4cbf3a89383e72180a86aeb2694d4f3467a654a53',310295000,NULL,NULL,'d7751796cf10b5a92ed9470cab6dc1d0e2a1853fd457fd913e58f5fd38771d2e','84fb6323d88aefbadecfa52b67378c955989f71e44c46ed2cc197f6dc3089ac2','e9770319ffa105b89ab5a044bdddb61d9ab00031d1a32db8b55141b116e65681');
INSERT INTO blocks VALUES(310296,'75ceb8b7377c650147612384601cf512e27db7b70503d816b392b941531b5916',310296000,NULL,NULL,'e23e480658f3c900b36af8fde0bd00255b960ba1b65dbce45a773b4ae813ebcf','94456a288a87914eeb423f75a92899c94ecd7aa7995a2ba7fdfae363a0b05d41','accfca7cdf1d738f1546ff3c8dd7773bf371ed19d4a554efe89563d5de85b7d5');
INSERT INTO blocks VALUES(310297,'d8ccb0c27b1ee885d882ab6314a294b2fb13068b877e35539a51caa46171b650',310297000,NULL,NULL,'802b11ed2d95f872d2fa557725a43b15fde5e7b550a3dbf229881090866ee577','37c7f7e9279ca9c45560100b6cf836b35cd524cd7ce076cfd626e17e6ed8ac8e','327ec798e34eb1fccf216adcb2220a0abba0618886be9323ab0d796c1cbe8f74');
INSERT INTO blocks VALUES(310298,'8ca08f7c45e9de5dfc053183c3ee5fadfb1a85c9e5ca2570e2480ef05175547a',310298000,NULL,NULL,'d8d94f75f311d053b6cb52ef8ae295423c99f533351d78145614b4fbc69f6742','fda4182f434b82c94bbb1e993a7ff3d08223d375e0a857e0c66e61897f29b399','2e642746f09833b23b1ddd8fc59915ae1e7eec09e1a1a35b7654686d6fdab4e7');
INSERT INTO blocks VALUES(310299,'a1cdac6a49a5b71bf5802df800a97310bbf964d53e6464563e5490a0b6fef5e9',310299000,NULL,NULL,'841a917e1aa259167a05c911d705a07bdcf980c9c5e831999923793a03a1d46c','104ec26bcd14acbd4361657c943ebe143d54c6150586463f95227c9e080688e5','fa03abe7b7eaf81c61435adc31b3ffa013fa2662faacbc781ea041f25bdb282d');
INSERT INTO blocks VALUES(310300,'395b0b4d289c02416af743d28fb7516486dea87844309ebef2663dc21b76dcb2',310300000,NULL,NULL,'3d74164b7ec33cbc0b3e372b21e025c79b35e99784a2d8ae359f2005972bd5d3','416d7c450e0e4c442da5d5c8b1c99455fc1e069a6a92c8bd17a6aa1fcfbabec0','44670f19f61f71540fe19bc7789a8040bc6abe14c8ab72683d3b039eca22888d');
INSERT INTO blocks VALUES(310301,'52f13163068f40428b55ccb8496653d0e63e3217ce1dbea8deda8407b7810e8a',310301000,NULL,NULL,'1adacb3d5e4701b0f1bc158dd5164dd770852c5520e850d6d9b9e63fd1e7c37c','cb3216932d0dc61ae9feb7dc630544721d3c743a416a73cc9b805239ff5a8f4b','b723ad78d587291029f9bd70fc18b1a4d57b2d70fcb9a39b4ebac4878ce0a10c');
INSERT INTO blocks VALUES(310302,'ca03ebc1453dbb1b52c8cc1bc6b343d76ef4c1eaac321a0837c6028384b8d5aa',310302000,NULL,NULL,'587b7eb8bff455f2848380f870d20398ebae76e6a12acaafbac6e955d3c3380d','433a7d03bdceaf01ff8af345835d5576c0890436ceed748d1827805bcf99e6e1','57e6b8739948f935aaa4dc21d014a02c5bec76f32eee6426b8fae42deec4af33');
INSERT INTO blocks VALUES(310303,'d4e6600c553f0f1e3c3af36dd9573352a25033920d7b1e9912e7daae3058dcca',310303000,NULL,NULL,'27120588c29741bbb4a802829d2b35d8b8b17e7b5cb49842faa0fefe05e99071','d6bf0fbb86aaa88443f01fcd7c6b1329ec1d2a8184750a9e5157ebd68b46fb59','6544fabaf855154772275f0f0e1fa0559a90aab2a89e2f4f9758dc9c33790960');
INSERT INTO blocks VALUES(310304,'b698b0c6cb64ca397b3616ce0c4297ca94b20a5332dcc2e2b85d43f5b69a4f1c',310304000,NULL,NULL,'4a1d23a03c47c00574d3423f328c48d794ceadd2655cede15c5901d830c87589','671226807e071bfd8a11eda7d13146332ffe4f5b170415c155046fed71e48869','9b1a7bc7b62892c8d80ffce7792142b89d1a44a86624741656fb107619523391');
INSERT INTO blocks VALUES(310305,'cfba0521675f1e08aef4ecdbc2848fe031e47f8b41014bcd4b5934c1aa483c5b',310305000,NULL,NULL,'7aac15d414e5ebcfaf63a9ac3bc05d2dde5ffc610d9bafc8ff2a210020f6d5ef','8b70feb9a4e9046b3fb3f2cf36333a9960a6d773cde6970fcd3b3a8a97a3e2b9','be237fde1b66e96f2f9c76863f78060b1543e15acd6eb7d0807381502d93f52a');
INSERT INTO blocks VALUES(310306,'a88a07c577a6f2f137f686036411a866cae27ff8af4e1dfb8290606780ec722a',310306000,NULL,NULL,'bc47cbbb42618bea636c422d824748d97d5bd4b4b75ab44d80ebeaa9b5fb309a','f315b2161bf4bec69ea901822c4e0bb96337d64144ae43187e7e4d11f2f3554c','e77995c642b2c5035147c2bfd7cc3197f76bf25048a0aca78bfafab177dbd39b');
INSERT INTO blocks VALUES(310307,'bc5ccf771903eb94e336daf54b134459e1f9dd4465dec9eaa66a8ee0e76d426c',310307000,NULL,NULL,'02440bc84b5e8e1733d29e4524381c8ba25e38727d5f70d6246627761660f329','99ba6b18880fa9ce2a4277c8f44fbff8e5f8b6b1ccd5ace55ad04013360b121a','a891629e82ade2c31536057b606a73de78a4d8f721c5cb79f2b2497aea9afd4b');
INSERT INTO blocks VALUES(310308,'2291ffd9650760ff861660a70403252d078c677bb037a38e9d4a506b10ee2a30',310308000,NULL,NULL,'44c5b13272847e19dd2cacf9a506145f9a1ac5792916eb98204bdb6772e7ab68','0c32d07232d6fe62cdcde0004e6d2113f353c8c118dc56ecb054fceb7e938a02','b31d9a91358ca68e22da632c0f59e8a86ee04a5d19e785aa54d50e48d3c7a9e3');
INSERT INTO blocks VALUES(310309,'ca3ca8819aa3e5fc4238d80e5f06f74ca0c0980adbbf5e2be0076243e7731737',310309000,NULL,NULL,'25ea894e3bb4f88ef9c8f86156a3980c0d638c20c69e8bc6365f913d1454c14b','28efa39eae495682a8b7daf716b025055109605ee223f0b39a3ef47bd9d38cde','a453098d13f99858412ff200ac8940ba4d32eb3516683e12eb8b231708660c7c');
INSERT INTO blocks VALUES(310310,'07cd7252e3e172168e33a1265b396c3708ae43b761d02448add81e476b1bcb2c',310310000,NULL,NULL,'94d123e1ef62d5063e363065d8d44f9ab7f22c59eaa35a2ce38177c7b7a8eea5','acdf7e89cab583d828bfdf16e1ea8569d7072b82b058e56d24d333399c03909f','a1450e1db21e38045a9f11b52c7da1d1c34f4737902f6642366afb02ab518da8');
INSERT INTO blocks VALUES(310311,'2842937eabfdd890e3f233d11c030bed6144b884d3a9029cd2252126221caf36',310311000,NULL,NULL,'3aa3b3f04dfcb85db112ec7f540a7f54b56ad7f749df3d0d1dc738ce25bc5728','75fff7cd4ea69cd32f3421a8c6022bda8c4d254d90430fced9de74e6d548a372','9d6d9619e4af890456b6a0ee02db1ccdd747ffb2ad72040570eebf7d78f13b20');
INSERT INTO blocks VALUES(310312,'8168511cdfdc0018672bf22f3c6808af709430dd0757609abe10fcd0c3aabfd7',310312000,NULL,NULL,'44991a8afb1cb85a381557bd653b1015160842edb02266164460559a4ea9e529','2e2e48165c82bbc21681509fb9ed19afff5be3cf14ac659e13f098dd2039b6a2','6624f1fd6095f265a26d4eb143da9f3a8dd64d778d03a86caf646de8005e2fa5');
INSERT INTO blocks VALUES(310313,'7c1b734c019c4f3e27e8d5cbee28e64aa6c66bb041d2a450e03537e3fac8e7e5',310313000,NULL,NULL,'d7b21c8000a09ce9f26037c43073e2d7a596c68c954c5416d22454d3e89c8b70','e9555db9621f75933698957c229df55a8ac26247e2285acfba9777786b604ca7','941491f3acb9de0bfe8a7b15a8ab6f81030c9f1028b93c2d294faba0a3817980');
INSERT INTO blocks VALUES(310314,'1ce78314eee22e87ccae74ff129b1803115a953426a5b807f2c55fb10fb63dc8',310314000,NULL,NULL,'5c1ca6e4f014f1fa35870558ad52dd5252e6b54a02919546a03d4e6498370d44','26edc96738ea9900127ec6b046bbdf9c6a9853c71c08707a9930137eaef5264f','d76c1451dbe3083bf4d2d29c66902667c24cf4c9f7d885fedbacabc09e5d16b3');
INSERT INTO blocks VALUES(310315,'bd356b1bce263f7933fb4b64cf8298d2f085ca1480975d6346a8f5dab0db72cb',310315000,NULL,NULL,'ba3b14271b4899094ad98e0535979eed35dc2aad617d7996155251ddcb4d0e4e','f60d8fa10649384e2c403d364fce19709f0816a2f703a0de605abe0cab47128d','6b1a983d3c6c81a47edaae5285473136aa6ab9c30dd5f38304f84543b8c3eeb5');
INSERT INTO blocks VALUES(310316,'ea9e5e747996c8d8741877afdcf296413126e2b45c693f3abdb602a5dae3fa44',310316000,NULL,NULL,'b33797e21d7654e1ca5cc08bca4a6bda9ae95f23094d42b789530b6cbd584b4a','e4516b4574b3445239c7eab612a73b413f385addfc9afa24e817636bd354e784','731a9f584ae9c7dc947fc2df7bfe5eb22918733562d347869a02d197d7438097');
INSERT INTO blocks VALUES(310317,'aa8a533edd243f1484917951e45f0b7681446747cebcc54d43c78eda68134d63',310317000,NULL,NULL,'497a601664ea59cf1929096b129613ce3bbedc271ecfb33b364558e231d48649','623ab11092958ad33a2b30622b6a28b7fb3951ea0afbe945cffe90fb6927f3ca','dbda9faec3307557deb319b99b2e7a96e05ab982beea0ecfc83e2393a2e19d63');
INSERT INTO blocks VALUES(310318,'c1be6c211fbad07a10b96ac7e6850a90c43ba2a38e05d53225d913cc2cf60b03',310318000,NULL,NULL,'760dabe4684acb6c8638c56ee1387e4d6710f99adcae4cd9721da0c7decfe2bb','c11908dc94ddcb9534c090255f9144236778c90c3f8defafe7d1219543c780b0','556e39fe8f10e66167498076b66ab7e161245ffc87de41391c18bdf1851e4159');
INSERT INTO blocks VALUES(310319,'f7fc6204a576c37295d0c65aac3d8202db94b6a4fa879fff63510d470dcefa71',310319000,NULL,NULL,'e43bbfd0e56daf582c84a2286079fbd8aa661c149cc3a14d40d139a45fd7a19c','a58f51465178fc211969bfba47af01ab92da3fcd8d502d6213d8065675e1e06c','aecc59f3d692e1ec2d84143bc9dd7717a4f34611e1f3bd851164a3eaf991e9c2');
INSERT INTO blocks VALUES(310320,'fd34ebe6ba298ba423d860a62c566c05372521438150e8341c430116824e7e0b',310320000,NULL,NULL,'7f95ee77cee4a1c0de27a0e69d909d0c2cb8d5a5d76d6d92e8bfac58c3f148bf','d4bb0c63c19fbeacf38f4dadd191565855a2a8179ec9788559ea02cb152dd6a7','b9893f3148691144fd9b301d6c0fb16ca3d6743ab809de063638834ca55d0d8f');
INSERT INTO blocks VALUES(310321,'f74be89e9ceb0779f3c7f97c34fb97cd7c51942244cbc2018d17a3f423dd3ae5',310321000,NULL,NULL,'9e2bc1247466f28c92ff287e9d5825f81e6b8b4063c70db23aacfde92f627417','e56bdc017b64a01dd5e5fcb205cd62366626e270d6272ebfa44de6df3551aca1','7a9be9d4714c550e6b19b08ede9198c4095564e34c2bafbdf79c0b697a7c3537');
INSERT INTO blocks VALUES(310322,'ce0b1afb355e6fd897e74b556a9441f202e3f2b524d1d88bc54e18f860b57668',310322000,NULL,NULL,'bca22d67b45b3bca60a0e4e1009d4ba86bbba96b0e37455e094eaf933f7d892d','608d6f4bddca5fccf8a1f07bc1e14d57418e4163ec275fb96f54ef3f60c3e82b','e671a8e8e12c06977d8820f9f7da53f858443e286394ad7592779e9a630648c1');
INSERT INTO blocks VALUES(310323,'df82040c0cbd905e7991a88786090b93606168a7248c8b099d6b9c166c7e80fd',310323000,NULL,NULL,'aa76c1d43196055cc6ae91e0afdb1105db0e5ea8b9f8d20298878900c07e8ec7','dd2dfd68b9de033f7a8b304e95fe3f42b3f308ac8f6fa3b69405d0a8f9bebd40','996a49ab32a15ae2deb95cd017dc9718704e7cf9222dcc5169e9ee7a50852c66');
INSERT INTO blocks VALUES(310324,'367d0ac107cbc7f93857d79e6fa96d47b1c98f88b3fdda97c51f9163e2366826',310324000,NULL,NULL,'dbdc8005f1f6c45dce8e0450740c37f2d21e6f325e1c2279bf78094aa1098ebe','d2e046ed519ea862f98b9f22d13ed677b40a04b12c2c6d7ea1d2e1fc8eb36b03','b187ae70a31e97f3abab14f01d6868482a962b83577c3298980f11cfa46b3b4f');
INSERT INTO blocks VALUES(310325,'60d50997f57a876b2f9291e1ae19c776df95b2e46c14fe6574fb0e4ce8021eac',310325000,NULL,NULL,'021f052a73f177bce172f220d3a1ab9aea5f325e32b3d2635905a0c95b4c6efa','985d1d2a9d957a1648c603b2a483ac7bb986d0a7697862c6556d2a174ac9bc2f','ddb82c014ed7affa45759928bb190f4d85607704058c36872bf122754aa0a92f');
INSERT INTO blocks VALUES(310326,'d6f210a1617e1a8eb819fc0e9ef06bd135e15ae65af407e7413f0901f5996573',310326000,NULL,NULL,'f90a81326133a303229276b553796e2f9d186f98ce897f759cadb19e6728090f','827eb2a4c611560b5e9cd97fd27c8a0fc3804938a9a086d4e3482a17a5de1a09','4eb005006e7a1d9b1bb54d4ca6f74ac4b68b67247f9be0b42bbac0440741fbb4');
INSERT INTO blocks VALUES(310327,'9fa4076881b482d234c2085a93526b057ead3c73a6e73c1ed1cdee1a59af8adc',310327000,NULL,NULL,'86aaa9593f09bb338fa1b0878f2522db223bf8262e491ae0b8e707f9796c5e05','b117f5689a267803c65683d19dd8445c3bf2ba0821a49f1c5329b8a2d6f375b3','c7fc876193594ffa20929695f419ff7627daee2c5664b3d726b53147db19e851');
INSERT INTO blocks VALUES(310328,'c7ffd388714d8d0fc77e92d05145e6845c72e6bfd32aeb61845515eca2fa2daf',310328000,NULL,NULL,'f4b59e29f0c89f18d045a800d098abfffbc9ad7ff200eeb47133605eb1a72b68','2aef27017627db08fee205cbcc5be4fe3a3eeddcf7d240bd1a5298036c562842','a59588cfb66331ae285d45e2ffb2c173daef7ee3a750b913bea13a9368ac2076');
INSERT INTO blocks VALUES(310329,'67fb2e77f8d77924c877a58c1af13e1e16b9df425340ed30e9816a9553fd5a30',310329000,NULL,NULL,'dbd3510938ee45e99d8b7cac8b0d3e8a275dfc6b1c8e741e0320e4b2e4947fe5','4e8530c5fb31201dd82f6a41e479fa22a7965db87779aa67c67b5d74c6d4e084','55f5814f5623933408abcff391de9cd2d4e0763f18bc979564a0b27d3952fb6d');
INSERT INTO blocks VALUES(310330,'b62c222ad5a41084eb4d779e36f635c922ff8fe275df41a9259f9a54b9adcc0c',310330000,NULL,NULL,'79f20326c0e49ea2b3c81e8d382754f311e3744b22b80140dc7ceed4da1fe09d','219880fddf308cdf767d912ca5fe59b634a75c25cf7cdea1048017d41f0f7769','6da6a4f87f40fba16c1ad3dfab233fd92026ee259026f49a584e3c64ed41ca5e');
INSERT INTO blocks VALUES(310331,'52fb4d803a141f02b12a603244801e2e555a2dffb13a76c93f9ce13f9cf9b21e',310331000,NULL,NULL,'41d2d69965cde1e0f97b7c14c33acbad592a6bd4882eed6aeb57127ed4ddb69d','03551537fcf1eae3990cf62878c4e9b9c4e8a5ccf3aa7f4aa62b0be77ac97f04','c9d3a0cf7502c7f00a667ea999d96ccf0be98aaf41bd87e421030a3988ce35c0');
INSERT INTO blocks VALUES(310332,'201086b0aab856c8b9c7b57d40762e907746fea722dbed8efb518f4bfd0dfdf2',310332000,NULL,NULL,'3def70343846a9776559707fb61437a53ffc5dac917f81ee3a12445ce69a9885','7738d6d0aef243611238600fbc0ee5b4bcca6b89d0959e1b59f98a02bdfe4abf','22a98b3ffdd619d2b25e25f3ddec14364b96b4e8d1ae0a7044e14556d7dabf33');
INSERT INTO blocks VALUES(310333,'b7476114e72d4a38d0bebb0b388444619c6f1b62f97b598fed2e1ec7cd08ee82',310333000,NULL,NULL,'cc02e3e7327ddd3c192bdea2ee76728c0b0cb031fe130d5713c1ec9546ae5946','27de25debb0273d1c297087f37568674f6d507e9cb0467773ccc3e716b2cc0a3','db9d254c0ef6a2c4541423d4f0dce8721c0e7213d948301afac19f5036bfa72a');
INSERT INTO blocks VALUES(310334,'a39eb839c62b127287ea01dd087b2fc3ad59107ef012decae298e40c1dec52cd',310334000,NULL,NULL,'8a449270a6bfb33206c1d7eb02ca363cb405118e52359a1ed015c5660fcec8a8','35885ea4c92c4a28127d32ca3f23bfab54c40b38267fac2e1eaa6a233c3419bd','d3a9ac5ede667afef34bb289c708b59b1bb721dbe55acd854d7ad9395db5744c');
INSERT INTO blocks VALUES(310335,'23bd6092da66032357b13b95206e6527a8d22e6637a097d696d7a96c8858cc89',310335000,NULL,NULL,'942c5c5ff6c24ce2bb18e065b24c39d1906ec381bba55cb9d905376ac87d2bdb','e657f49a8193f8c8052586f1f5eb6ed07267820d556e70d9da98ba79643c2f87','2078bd866c8b00567b4ea7ab6630a99c5608616666782881cc92a174a6c49787');
INSERT INTO blocks VALUES(310336,'ec4b8d0968dbae28789be96ffa5a7e27c3846064683acd7c3eb86f1f0cc58199',310336000,NULL,NULL,'68a947f2ae4507e143c9ac84826318d4b630845f81548490f7b0c00a2330e990','37a67e7a39c5e6beec81f3c37c7d20568ae2612e396ba65bdc66720b079c87b2','c59aa3036a0dab8b6d569037f16973d1953e500c176608233c474024597a2bea');
INSERT INTO blocks VALUES(310337,'055247d24ba9860eb2eadf9ec7ea966b86794a0e3727e6ffbcba0af38f2bc34a',310337000,NULL,NULL,'4e1ca24a54f45b4cdc60be1348b3d5b81ee8acbd7c4f8cda86b8d2746694f17f','3846e1fadb5a06fce19e59b2e7dad8c6437fbd9aa3712bf180ccf80c08a14bc3','101db78fe05e80b9a9a966ea0f50267222a22fc615fef0e224d1233cb3dcb669');
INSERT INTO blocks VALUES(310338,'97944272a7e86b716c6587d0da0d2094b6f7e29714daa00fec8677205a049bcd',310338000,NULL,NULL,'dafafbcf8cbefadc5596ba8b52bc6212f02f19de109f69dc412c2dbc569d5e8c','343942b074d7c9609c84974f42e1b52a635fb9df0a22b228c4a69a76f5a09868','1204613eaa26c7a796fe73330a77c179754844406b449a7cba675b3ee897b089');
INSERT INTO blocks VALUES(310339,'99d59ea38842e00c8ba156276582ff67c5fc8c3d3c6929246623d8f51239a052',310339000,NULL,NULL,'e28e2a9c9f9476d0c23bba3c6d2e68f671aa20adf72199188a9c82160b0cbadb','04db4465310ff676eeaf8512795d0c9373ea801e1e426a8c4342ce2a91974e59','77fcefce275a43d24449988c65d5cf8b92f36a03eaeb1db73bca48b8944e5bca');
INSERT INTO blocks VALUES(310340,'f7a193f14949aaae1167aebf7a6814c44712d2b19f6bf802e72be5f97dd7f5a0',310340000,NULL,NULL,'7171d5b8a9f07885a5fb6059e4ca31dc00863ebebcfc82836ed2af0deb39a48e','f79ef3dbb6694af0a30d8bbeeb29aa18b577db55a5ce9fa3b7826e77225c7740','480cd9f4c65e75a606e22a0b5bcc389075d9008428281edffd485519aafaed47');
INSERT INTO blocks VALUES(310341,'6c468431e0169b7df175afd661bc21a66f6b4353160f7a6c9df513a6b1788a7f',310341000,NULL,NULL,'d350161fb4026c48acc21d9e66a2def972fbe543c46381a353de2d2fd8b6bcd4','53145bf7a7a5bc08b7e186efc4371dfc90b23a8a98ffa9f417487fdf7d262b27','72b661bcb054fdbcaf66e5f0645356a85135c54378209d50f55127213440af6c');
INSERT INTO blocks VALUES(310342,'48669c2cb8e6bf2ca7f8e4846816d35396cbc88c349a8d1318ded0598a30edf7',310342000,NULL,NULL,'6acbdd85b382016a93936385edf88ea1114706f2d326ca373ad508b653e5fd28','93751b63aeb49e4b2972ac5a7c578379b683aae7f9905871e4629ae01417a7b9','080da2a2b3f7072c2a81195f54786ff71e00c1299a71e80fa435b07ec4bfac52');
INSERT INTO blocks VALUES(310343,'41a1030c13ae11f5565e0045c73d15edc583a1ff6f3a8f5eac94ffcfaf759e11',310343000,NULL,NULL,'68e26f1c578576a74ba6b63cda11695176b48c7a919beaab5496db142b247cab','b83fa5c0711df32fab35a821e6982fcc3d74c7cc59af451e444666226ea37a7a','bc31ee8f0497703696d38407217526239e532c7222a4cd99e3d602f1206b6951');
INSERT INTO blocks VALUES(310344,'97b74842207c7cd27160b23d74d7deb603882e4e5e61e2899c96a39b079b3977',310344000,NULL,NULL,'2531f6b71ce2390aeeab26cbc8095aec7a76dc46db73149868d8a6209133780f','10e488ee12926ffc27973a45f717eb1aed3cfa9a97b1468a08c10f08c1fb0348','0d7aad551f3d326d383ab7cbac02273dc5d0759840139025777193ec55354dad');
INSERT INTO blocks VALUES(310345,'0bda7b13d1bc2ba4c3c72e0f27157067677595264d6430038f0b227118de8c65',310345000,NULL,NULL,'ecf8e55d01bec5ec8fc302451bc3e0d3a76d5d413ce354ed43e36eeef274cc14','84750f89e348096164c05d7849453f945001947c9e2f4877fd3144756d92d6fb','ef1e82864698b4278b4d6a8a1aeacb1914af124538437d3707d31e39b24a0bb6');
INSERT INTO blocks VALUES(310346,'0635503844de474dd694ecbcfb93e578268f77a80230a29986dfa7eeade15b16',310346000,NULL,NULL,'2149f9f24dd41e092555f29cf7ae1131cc53462e9f24de15720c0fd1a8a874f2','e448b2412093fe64ea8b0eb62413e73c7c8c3c0cbb5db0978c24d76139a40ed3','051a81e6c5832bbbbb0719394fb539ce0b960e5b826a8e79527e4e3855d59d5d');
INSERT INTO blocks VALUES(310347,'f3f6b7e7a27c8da4318f9f2f694f37aaa9255bbdad260cb46f319a4755a1a84d',310347000,NULL,NULL,'f19aa2d83d53f128264cf432c9c313d89d2d91f09af8f2365ffc4bb0911abc5c','ddec9219567f76f27aceb058f755089dbacbb5ba10763da1add60feeb5ff1811','df53f4de896fbb1ad5236fd1411d1defd94bf792f54caa136abfa316b29df2c8');
INSERT INTO blocks VALUES(310348,'c912af0d57982701bcda4293ad1ff3456299fd9e4a1da939d8d94bcb86634412',310348000,NULL,NULL,'5ac2d42a9f7cbe6fe7ff53879d4ac316e93c00b005543c1575c3a72471765118','4db67b20ab204b27d09207f44100f885aa69cf21461e4515ae92bff6bea729ff','d4db1e7d2070273d974dcf2812b8f119b0106695a995a7ac32428cd40229b2ba');
INSERT INTO blocks VALUES(310349,'ca911c788add2e16726f4e194137f595823092482e48ff8dd3bdbe56c203523c',310349000,NULL,NULL,'ea77bb132fcbdef8652894fc3c80a862ac4fb0daaa444213b61388285904bed8','68e7a81d292a16bb63fba9f098aece6c815a04eedc205da8bf93c7f9ba9868e8','ebf97e54668131a0c9e0304dcfc823295bf02cbb47fc28c47e2041efdd76e966');
INSERT INTO blocks VALUES(310350,'c20d54368c4e558c44e2fbaa0765d3aecc8c9f01d456e3ff219508b5d06bd69d',310350000,NULL,NULL,'af48f18af140a67943df6ce781e858631a4e7841c7f44facb644c93641145237','ac40cd74e35dde1bae93b17b520ea9e31d6bf98e771d7805e0e03c6291d0842c','cebaef3b007b51e8421bd7ebe359f233e1fb17469860cbcb6af89f8ba402c34a');
INSERT INTO blocks VALUES(310351,'656bd69a59329dbea94b8b22cfdaaec8de9ab50204868f006494d78e7f88e26f',310351000,NULL,NULL,'4ae931b01a138a0dd8e4d6479faac7961fe3148fd048c4daaa6720f907cbffb1','32cfa33ea247fbf3f6c5a38856e68472a21e03ed457572e7c9bbb7acd06605c3','e2bae29270f0b183081b5fd651c89a4d83515435e803ef43e36141379dae5204');
INSERT INTO blocks VALUES(310352,'fb97d2f766a23acb9644fef833e0257fdb74546e50d9e2303cf88d2e82b71a50',310352000,NULL,NULL,'d75ce96ca15ea976fbb89c93da04a0a7c2146abc01517663f97ad0fd15adefc7','4388224824d89f2df5e8e9d6dd8159889a16a298fc8e9fa6d31f88113dff8908','d78e77afefc919237a169a3b5561d78adae33fc0fe33023fe545192754f9a322');
INSERT INTO blocks VALUES(310353,'2d3e451f189fc2f29704b1b09820278dd1eeb347fef11352d7a680c9aecc13b8',310353000,NULL,NULL,'c0830c03df4b203d5e17a9274643e614fcf6e6fb7216067cb4f41f874436d217','da2e402c1e6f459a5a17ebec0ab6cfdda13262f1cf056e114def6be0f8732fba','47fb402f0aafacb249d32be94e311ad92d8f903d1c5a5b6ddabcc763b84717c0');
INSERT INTO blocks VALUES(310354,'437d9635e1702247e0d9330347cc6e339e3678be89a760ba9bf79dd2cd8803e0',310354000,NULL,NULL,'6f4d2524f4f976880e60e65aa631f8cdfa0b23fbeb3c41549c577b695b02fc34','949fddd58e22a188962248ec4a5ef68ae7a1300420dedf99853201ac469f2a3b','a586ddb82de6c032938546c8f433e784a4263ec44edb829b458dabe9a4613241');
INSERT INTO blocks VALUES(310355,'ea80897a4f9167bfc775e4e43840d9ea6f839f3571c7ab4433f1e082f4bbe37d',310355000,NULL,NULL,'dffc32456b12dd7dc4bbf95ab9f360d8abf4b2e705b2822728053709222f7e50','1f869f939107ab1322ab496192b416987add4be0cdc68c819dc9cd7385e84c60','76520bd45caee6a3668ade7d1e2e201f82c579908f23e3d92a10910067275bb4');
INSERT INTO blocks VALUES(310356,'68088305f7eba74c1d50458e5e5ca5a849f0b4a4e9935709d8ee56877b1b55c4',310356000,NULL,NULL,'01c0a7d3388aaec2d2f713b930df5b716a899ccd25d3b7e3b4c21657be7923a8','5bafd0e6998b5c2f68b05414c5f47dbfe2b1106c5a58b34e47a6c842c7d94dbb','5921bfda134a120c05e7241536241762eba1d640ba937c10e39bf73970cd6fbd');
INSERT INTO blocks VALUES(310357,'4572f7f4ad467ef78212e9e08fa2ce3f01f2acc28c0b8ca9d1479380726bab1f',310357000,NULL,NULL,'4dd02f79c7ad6348031e564ead17921d1d112b6bf8c5f4308b52ef2511983683','4ba256fdd135ee038536dd65582a6547d6ad3bb991d0460636d80c7708363a3e','cb81d8600d6d1707900b8655fecb40e541a1d1b1d5f57b8c08184ad243ad61e2');
INSERT INTO blocks VALUES(310358,'d5eae5513f1264d00d8c83fe9271e984774526d89b03ecd78d62d4d95ec1dea6',310358000,NULL,NULL,'a2815a72842de9330b82b8901f18116f208c379657cf8610c3510dad19b64124','8a29aeb9d01e1e80c5345943552a6e3b829e2a4229c92eb215ce64a7c987d847','d0cdc67e6779064679eedf799dcae46ed3a114d2034d13f5486ca979b4d3c56b');
INSERT INTO blocks VALUES(310359,'4fa301160e7e0be18a33065475b1511e859475f390133857a803de0692a9b74f',310359000,NULL,NULL,'23acd53757b9ce126a8817e2727a54a23b57246c92e6fda1f16fa4d5db378973','5e5d48d2b0c0250abf9099823f69e973a21a7235455080b7dac431d57ff28ce1','20b84d2c98b27f6dc0b274b97b33b2f55e0ba940074f2d5ddb42538c066e4b24');
INSERT INTO blocks VALUES(310360,'cc852c3c20dbb58466f9a3c9f6df59ef1c3584f849272e100823a95b7a3c79f0',310360000,NULL,NULL,'9325c1235f22738cd4897884005d5763db8b792930a968c1c6f75300f087e484','801a83cba2d9e6d441bad9abd9f3b1f7839ddede7cffdbe7ebac071b7d31fb46','775fd7e6f7ee61c5c5bedf10a820d547d61ff8822911ea37e1bdaf895183a7d5');
INSERT INTO blocks VALUES(310361,'636110c0af5c76ada1a19fa5cd012e3ee796723f8a7b3a5457d8cb81d6c57019',310361000,NULL,NULL,'30f7ec0f50ae1e4d4dcfbbebc789dfea4669c2a21a4d251550fd6696bce94952','20f4583253c5f07c49625e70215146f0eeed25ebc6fb634b57458a747cd9e0b8','1160aeedb7ce4c122e8412d1e15685461e2af6f8066487e125f5cddf53d65f57');
INSERT INTO blocks VALUES(310362,'6199591a598e9b2159adb828ab26d48c37c26b784f8467a6bb55d51d7b6390f2',310362000,NULL,NULL,'6fccf61f9c49986937cb13205f4ccdca952fba67c1af89d8c05da51b11ad98a4','0e7a6b0477080ea17436fa5b6c0d4df3cd59a62f7e3d3a49f196e089da0020d9','e6e63a0017333462563306273160a2030eb5fd391c59e235148aa683c74731ce');
INSERT INTO blocks VALUES(310363,'a31967b730f72da6ad20f563df18c081c13e3537ba7ea5ab5d01db40e02647e6',310363000,NULL,NULL,'74a243525a58bb5d1c051c10d1ddacfd307b69fdbb2da618e079322f3d317b61','4966f799e22d0cad11e7f63e52fc34e07d7d5c04022f5bfc5167a5ee9d0bb6ad','f39f516d37b108f626336f0aada548a914cd187c461a348ca96656aa489522dd');
INSERT INTO blocks VALUES(310364,'67025b6f69e33546f3309b229ea1ae22ed12b0544b48e202f5387e08d13be0c9',310364000,NULL,NULL,'5a0b10220431a5d6777ef9e49ba6333c7026f04ae450d48a7273732e8cd55ffa','366b354a81dde633c5a9db22127b6ab012bef8fe715fa3eb030238ab53bce1e3','6aa32af65aa389f86daaf66f137a99a1db233e2f42ce2c37d295ecf45168f7d5');
INSERT INTO blocks VALUES(310365,'b65b578ed93a85ea5f5005ec957765e2d41e741480adde6968315fe09784c409',310365000,NULL,NULL,'50e97232160d4b608299961f420a6218588c5650a8e45295a08f789a49b25d20','1bca33418a39e02dc696ce1d4432c801555749d29d982129bd286bbc7d5d89c4','07657d478c4f38db82b3eb1df321554bc5b4a7168e15373700954d81bf8b2ba2');
INSERT INTO blocks VALUES(310366,'a7843440b110ab26327672e3d65125a1b9efd838671422b6ede6c85890352440',310366000,NULL,NULL,'4521f3e3fe9fc9254b0d66fb4cf24ac72c50808751791e5752195c0dfdb403fc','78c50dba0703994270a4845ac6aa33c08377520e7426df4a8178325f69dcc343','1c810af904fa527a3cf2ac15a996290a4a6b10098708919f92fccfdd5f9bfcfe');
INSERT INTO blocks VALUES(310367,'326c7e51165800a892b48909d105ff5ea572ff408d56d1623ad66d3dfeeb4f47',310367000,NULL,NULL,'9b89619d958dab0246a3f2c8b8f402bbeb3a59637f492b7119a9a84bd939b661','a9c2a6e11c38fcc96c1ad831b89d278d0b487840483607fa632e569e52148c6e','6fa66a022dec9793aa33062173c016bf0dd94786cf572f2bc2f89f67a5b0997e');
INSERT INTO blocks VALUES(310368,'f7bfee2feb32c2bfd998dc0f6bff5e5994a3131808b912d692c3089528b4e006',310368000,NULL,NULL,'569a5946690bbc8251325d0569181b4c276eedbaee5885b816ebbef86d01e196','d22984fc430f7ad37aa83d81737afdb129a76c85a474ea9a1044f8a8e91780b8','0477133990139b3abb6ec025948a4ba0df22fb37c42ca3a1dd3cc0db42225d09');
INSERT INTO blocks VALUES(310369,'0f836b76eb06019a6bb01776e80bc10dac9fb77002262c80d6683fd42dbfc8da',310369000,NULL,NULL,'0ca340f24633d8884a88fbf3c7c9280c31460745dace8563b0b66ed382e0fa2f','1e59de53e9e049f203bcb4378abc0698c0bb3992c3c0556e906f3c4b5bf2c451','25c0340326f245dad27b555e9a4990af66d510b330234e2c853ad46e17fc8bb7');
INSERT INTO blocks VALUES(310370,'9eb8f1f6cc0ed3d2a77c5b2c66965150c8ceb26d357b9844e19674d8221fef67',310370000,NULL,NULL,'290093d9212196ee4c03b9eac0245803158dba2948f158e2c74f8dc10ac09329','ced5936851c3b7dc2268938eaabce6ce046f47c7560500d3844887470507800c','d9d92381a8bea7f53cb4eff841f97a8b11717057fbaf0ef4fca2107649dc3b92');
INSERT INTO blocks VALUES(310371,'7404cb31a39887a9841c2c27309d8c50b88748ed5fa8a3e5ba4cc3fc18310154',310371000,NULL,NULL,'fa6616279666c600602c38434c2b0fc9dfa1e551513e4144419efd45e0ee0462','60fe1e7919de0fa039a74b7776801ab2807c4fe6d18e728be81bde1eaa2bd4a7','9b443b17b56675115cdd0eac9c49ef4c6be118f544d2d315ecfbf67f32fae122');
INSERT INTO blocks VALUES(310372,'d3a790f6f5f85e2662a9d5fcd94a38bfe9f318ffd695f4770b6ea0770e1ae18d',310372000,NULL,NULL,'25d0ad708dfe99367db6dea83491440f2c30421a5a7c4fb024d0ed79cf59b1aa','46911b3cc14755f0a5cab03c7f0ace623708780648d2518ffae1ca4be2e61c6c','29a86e3b25cb1cbea051e4a05c13c985d13b4e8f029347e71b2b5a61812854dd');
INSERT INTO blocks VALUES(310373,'c192bec419937220c2705ce8a260ba0922940af116e10a2bc9db94f7497cf9c0',310373000,NULL,NULL,'408be37b314e37b6192d85d81c706f9e25c0d7e5a5448a6ed6284d324f587054','3ee573f88d916fac3d72db3104b49e8d85d6d37f5688faf2852ca8d9e0bfea66','26c2f615a65add2a893e991b3ea90a8f0f84e5e11e241b8ecfe4e0b3219cbcbc');
INSERT INTO blocks VALUES(310374,'f541273d293a084509916c10aec0de40092c7695888ec7510f23e0c7bb405f8e',310374000,NULL,NULL,'3153feb773ab5352e9380d3faedf2f32f427dd35b5de78b52293abe855c1091d','df56ddbada6da789cf1fe5066dbd1b320cc179e56e1d9a59ccf42e4fac3d00e0','b63b00c03dc95cf9e7e207adac8655248c06743ebec350528c9338d9ff7ce5b1');
INSERT INTO blocks VALUES(310375,'da666e1886212e20c154aba9d6b617e471106ddc9b8c8a28e9860baf82a17458',310375000,NULL,NULL,'5364cf94d87ffdb49360513b1271c5f107a42830cc8ca70b4751045dbcf92eea','9f5616e5886d5a77f77748586c58cdd2bc246733b64bff8bf6368d07a9debc16','a34b692356c9e5a4750e263e2c364b7e3ccf69092d75d8f3c4f58e34dbe32f6f');
INSERT INTO blocks VALUES(310376,'5dc483d7d1697eb823cba64bb8d6c0aded59d00ea37067de0caeebf3ea4ea7dc',310376000,NULL,NULL,'ad88937d28e8e5e24af4af424cb4004005d71b7d056d8d93b9f1eeddeeafe4f5','fcfcc7a4567ff4ef8e441cf9b276f5babb6a90a97b1625ac103b1ce535cae3a4','79bc137e4d7415d489c51bbdd078d2e64813e6648dabf1c97c1df3188354aa3c');
INSERT INTO blocks VALUES(310377,'f8d1cac1fef3fa6e7ad1c44ff6ae2c6920985bad74e77a6868612ee81f16b0b3',310377000,NULL,NULL,'0e30a4b710daab3563f7fb624dd4170e0026e60574742b57cb64cc03d621df15','67a2086867cb0e28ed68c19c226ea227c4a1928d559c098eb2c019d266c12bab','d299ad2f93b95a85b6e0d12d003d196e4fd0f83ce0a143043fe0b33c228d2667');
INSERT INTO blocks VALUES(310378,'fec994dd24e213aa78f166ca315c90cb74ee871295a252723dd269c13fc614ce',310378000,NULL,NULL,'7fd86de094040b85e820255f840b863f0725c53738d32952fdfc58beae9c6589','dfda4ea8da16b09bd897a785ed7dcaf5d8ef16794017a468be5bfd15f11141c0','8155a70965623a4339a766619795e166413e10f4c7f7820cf93813fe91190a8e');
INSERT INTO blocks VALUES(310379,'d86cdb36616976eafb054477058de5670a02194f3ee27911df1822ff1c26f19c',310379000,NULL,NULL,'fd89c38a53a75eee1c46a3e29cfe1bdb4956cd9bf8de15b582f0bf0d90dfa13b','3d3b476e105d1ae82b56b0cdb8371e452859f200e2ba4d734e8c0172fd274ae8','917fcbf68537f6882073a110d8fb0e315412d174d6fe16a4396ea92af9d1bf24');
INSERT INTO blocks VALUES(310380,'292dba1b887326f0719fe00caf9863afc613fc1643e041ba7678a325cf2b6aae',310380000,NULL,NULL,'2967d25d8d46df256d7bdd08a1f2dc77cb42af8adb2f53830d2d9abfb2981f99','c05445e18e15582122210d64fd15e7581c6fc7ae8f0f7df8fe9824d44b3139cc','fee1207304889a46ecb78bb3de1202c35c97804e6886963433eb657bdf00bac5');
INSERT INTO blocks VALUES(310381,'6726e0171d41e8b03e8c7a245ef69477b44506b651efe999e892e1e6d9d4cf38',310381000,NULL,NULL,'703a73971fe4f5d48ec8393c7e8dc8cc13374ab8a2d52c68988593c4de8817f2','765efe608baa5d025b00a35aae51718ff2b02ead11ededa6f296eaf3b1384f90','486cdbf221e8db0d769d64b5ea749779f107ccf3c65a72f68097d6c6fd1bc725');
INSERT INTO blocks VALUES(310382,'0be33004c34938cedd0901b03c95e55d91590aa2fec6c5f6e44aec5366a0e7d8',310382000,NULL,NULL,'198e36c164a6f40c76112501fa1c70327e3e005a042d1369faf0126f41d58d62','124519648098feddc9037881bb080da0fd192984f1f3d96f7cc227b760b988ec','31d293b5e49845b32f9635419bcd8950a4a2d24f0a88d3d8737f87f25fd67667');
INSERT INTO blocks VALUES(310383,'992ff9a3b2f4e303854514d4cad554ff333c1f3f84961aa5a6b570af44a74508',310383000,NULL,NULL,'591cf03f57957fedb0522af2ca5fe111c5828157054f51a1b3fd9cf72b429a28','0085163ce3df67da70cb091895b7fb8ab958100dea17c61ff0e083194c647a76','5ea4675bd01a02906e80f2f38eb41cd1ebcef4b021e33f62293943e203f0f6ad');
INSERT INTO blocks VALUES(310384,'d518c696796401d77956d878cbdc247e207f03198eabc2749d61ebeadee87e5e',310384000,NULL,NULL,'5c911e05c1670a675082c98b242b80bc5ad3ddd105ae4d4bdb2cb6601e172a29','87e00bbf419f90430fe4c21e1ab7048ed44681de660376f1ac224c0f9e9b32e6','1c94b9d8833e3e6adb940f1b43b1d2c7f08b74b8248049b362c2502581e0ad06');
INSERT INTO blocks VALUES(310385,'2aa6a491a03a1a16adbc5f5e795c97ec338345cfdf10ff711ffb7ac3a0e26e28',310385000,NULL,NULL,'1944f881a1202cd4aad1cb089bd916386581b94c96002cdfa67a69d7b537324f','4a0aaf3c1635db8d0fc79cc632fe050ccbf46086919ef2da85e51dcf296e4a08','8b59b795ae5afbc5c48ec0b0d2283b414d43dd2b8fc7e38bd0215de9ec896909');
INSERT INTO blocks VALUES(310386,'9d19a754b48a180fd5ebb0ae63e96fa9f4a67e475aeefa41f8f4f8420e677eda',310386000,NULL,NULL,'bf31cbeb8284aac77b6515ec7388d67e76e19ba79452b150a833c13c892c0ee8','469c4f9f6bcaea0d2f57c8b9434c00e3956792be6a2b9481c802b5a17b9b9387','959240d681842a4a07cda6c86be7d3a3d939b6e7c0d14d2017d634bf7c9c0dfc');
INSERT INTO blocks VALUES(310387,'b4cac00f59c626206e193575b3ba9bfddd83bbfc374ebeb2838acd25e34a6c2b',310387000,NULL,NULL,'3f82211082a2d6981de51244bb0483eebfb3bcadfd48b80151fd1c89694e2b3b','46d29ae060a094087fcd9cab28bf99ca3fb61186b60a4788afe0923699e8ad34','6f97a53641a53b8553aa24073de8f1943e170d65b1e4beb39244acc3c6d87b50');
INSERT INTO blocks VALUES(310388,'41a04637694ea47a57b76fb52d3e8cfe67ee28e3e8744218f652166abe833284',310388000,NULL,NULL,'59c3a3c5648f18274642df5050b117d8031f10c46be63b5864f30ecec69f0c09','6957a2f4eb5b41d57c29fe041b2f0cfad9d6b80c14a5f7d0aeec50caf24456a8','9783cbd1a50a340ad33a64293dcb3332d213509987889c623f1cae94a1423c42');
INSERT INTO blocks VALUES(310389,'3ec95ae011161c6752f308d28bde892b2846e96a96de164e5f3394744d0aa607',310389000,NULL,NULL,'fbacb621beff1e0769d716ed51493afe97874941feb7787b5cc80916e3ed09ac','488c6cd5b7ef26273952e9b2c6e7559772b35003b93752dc73466a6560fb5905','54b8b3e399d0111a23d9012f5a1d81427698fc65b86c2d228072f66e4ce46132');
INSERT INTO blocks VALUES(310390,'f05a916c6be28909fa19d176e0232f704d8108f73083dded5365d05b306ddf1a',310390000,NULL,NULL,'a2c398743a97092d8ea6875970fb1662470fb5918f09e50c132c29ee6fcc9b35','4566a95f5fe9447535e0487b550323fa73c649aaaec905bf7ecd292e21a566a2','4fcfaf34d66de5de6019be2730bc3ebe83693388c52f6ef1942404bddaee3e40');
INSERT INTO blocks VALUES(310391,'fc26112b7fdd8aaf333645607dabc9781eac067d4468d63bb46628623e122952',310391000,NULL,NULL,'cb3842fc91685c97b6db5ab71e1586259c83c619ecd57dd653a213b5c4a9f9a1','c8fbb4d7beef4a416327ff79bb81a412d9a2ee054d7e350912bef39724cdcf70','bb66f415f4a377b15c8e4f84e94423e707d589b6116a10e9ef964d5a48538b24');
INSERT INTO blocks VALUES(310392,'f7022ecab2f2179c398580460f50c643b10d4b6869e5519db6ef5d5a27d84a1d',310392000,NULL,NULL,'780ea5e6adc1e9ae328efe2ea25af76ae2e228c98b475b6337ed84e5924e3b95','dac2cd52e225d3796fbccfc91e564ce1d3faaaa4153d4ca6c9771b1307787737','4b5dcf453b105f3c278322a9a5523beb807926c17ed3d4b337a0243ce39e8b08');
INSERT INTO blocks VALUES(310393,'e6aeef89ab079721e7eae02f7b197acfb37c2de587d35a5cf4dd1e3c54d68308',310393000,NULL,NULL,'6f61090175f1e398ae20dfcc41e5075327ccbd297c786c8a09a866a77836d429','6a69955ba87abbf691417b01992503e07146291d5952cf1a8f7cfd4fc07b4bed','1208d595405348b798cd80f47d05b4bb448d301a69da4a8d61e8f6bcd71f4954');
INSERT INTO blocks VALUES(310394,'2a944743c3beb3bf1b530bd6a210682a0a0e9b0e6a9ff938d9be856236779a6f',310394000,NULL,NULL,'8cdcec6732f3d4f2da04edc5a59cbe67fbb27ea069efdc23e4bc92f055fe4223','705bfc6096f12759b71c925c76f681bb37efe5f824f1e79f8d451386795a6ba7','d93ad63ef4cdbab6c40e0b70e8e5ddd922c37c9c9e84a02f7cfe2cd7e2468616');
INSERT INTO blocks VALUES(310395,'19eb891ce70b82db2f2745e1d60e0cf445363aaff4e96335f9014d92312d20e4',310395000,NULL,NULL,'291b2e82b5bf5ebee0ab534e53cc2a748429d7248ba1194a8f673552ff65cdea','e3f63c79b57e7dbae21e9847006bf411961509c1eab5b17cd66869c0a764cbaf','22fa1377ee4fbb2e85dc77854ce481457fde11ebf691a7572cc67d59c60940e7');
INSERT INTO blocks VALUES(310396,'aea407729ac8d8e9221efd9d70106d14df6aaf9f2f87dc6f490835a9caadf08e',310396000,NULL,NULL,'9698aa62d90bffb57f7b8b92e4275dd6df0b53d5e539dbe3440cc8f885881e65','4b07059641774678b60595f6955c10337889d885ebcf397b15dc921bc1fe89d6','6d5275da6a5aeb05570dd6f204243aec5a6e694ddf25d22384e5359c6bbc33a5');
INSERT INTO blocks VALUES(310397,'7c429e56a19e884a8a77a759b52334a4b79404081b976270114043ba94d7985c',310397000,NULL,NULL,'bcb427bbccd91cbce4402f5b9495d789a81e22fd80467f8023e33b98f487eda2','f16f3e0270536ea02d753705ad54941da7f78ab7c5e4e836f23ef762f16651eb','c837fd20f97f71dab3c297c2f944ae78c98c00b0facffdd26e7ba237be572b0f');
INSERT INTO blocks VALUES(310398,'55c046db86dee1d63c0e46e6df79b5b77dfd4ab2ff5da79e6360ce77dd98335e',310398000,NULL,NULL,'3833e3ac7b7b74948268b6588ecb6b6752ab22138e0d2f477e3dbef12adab776','5a5c133bad7f2a1eae57a798d570e2ba325b5d13d35e268847c372b93c2f25cc','b77e4c564e6dac7bdab57be33d1e41ef9f5480ef7c13eac1bb3ac3e727a22592');
INSERT INTO blocks VALUES(310399,'765abc449b3127d71ab971e0c2ae69c570284e0c5dacf4c3c07f2e4eca180e7a',310399000,NULL,NULL,'c15cf8452811e6df6f5438f8343f9a3421e75eb9aeed8e42eb0658e89c64dd51','a26b7fbb7fcff57c812874e868fa9245d4a1ce0e7bf51876e57144941709b757','aec11332d29bae6a521daddbb953550763a2821523ba55ed3f7b938c188a2a2a');
INSERT INTO blocks VALUES(310400,'925bc6f6f45fe2fb2d494e852aaf667d8623e5dae2e92fdffa80f15661f04218',310400000,NULL,NULL,'bd993e2a64b62f6c376e338e9beddaa0ac0501b39883506f2472e533bb19cbec','ca83ec399b3d1e2cfe41b215e5ed87f3f363f4ca39283ba6fddd48e19ac40af5','fa84b60dd8c07870f17510258f7e043901cd4457f92455802951ea64a8be0802');
INSERT INTO blocks VALUES(310401,'f7b9af2e2cd16c478eed4a34021f2009944dbc9b757bf8fe4fc03f9d900e0351',310401000,NULL,NULL,'e6dd67cdf805c23e353ec25468f2ea830da46e4104dbc537e9e15a5acc1b28fe','c97a1771a537ff56061b2e49fd3355ee69ef48d59e13b30665dc04c08ab22a6b','5a0e6761e01675fadd9f596fc2a24bf8f010cb057f0b68fd46a44b355d919f63');
INSERT INTO blocks VALUES(310402,'1404f1826cd93e1861dd92ca3f3b05c65e8578b88626577a3cbad1e771b96e44',310402000,NULL,NULL,'6b19a39e68b8418c2eb1650bd1427438dfd65bf627bb6b50ae3a903c9169ff4f','47d72c5b7d50db677ac57b31ca6bcf5a0d5716e6c8d73cc7cc4ca636137c10d1','6d0005ca5153267fef22412ba42c5f7d3a815c2755222759fa60897355b1636b');
INSERT INTO blocks VALUES(310403,'f7426dbd4a0808148b5fc3eb66df4a8ad606c97888c175850f65099286c7581c',310403000,NULL,NULL,'bf22dd1b8b936a1eff32dea79c9cbffda251bc59ed2754f73c139155eeb2eae3','865ae7310689395016625b704024a7f294340c84608f00bd87c25560aefb71be','2fb31e8bcad7ffdadb783bc03c5361545aeb4b4938519d6afb10e6b261534bbd');
INSERT INTO blocks VALUES(310404,'401c327424b39a6d908f1a2f2202208a7893a5bedc2b9aff8e7eda0b64040040',310404000,NULL,NULL,'2dff8ef48ea2026e72bb327368bff21d40eb321ef8c9ab5552c6b9f40dadcefe','6c5f0c3f1694b0062f09f4a68f85fd1ed02e714b2c6c1442a9a65874e4da9e69','a38fbd51b6bb84c58b0797041bb05ecbb5fa447258d5cd7e5cae5929b30bc533');
INSERT INTO blocks VALUES(310405,'4f6928561724e0f6aab2fc40719f591823ca7e57e42d1589a943f8c55400430a',310405000,NULL,NULL,'35b2f3fb27f707493d53ab0eb8eb239891be2a050a1f7ea9fffeacc1b6e6056c','bcbcf1c78647c5200c158251a4d32b37a63c476dfe004c924121bb4d141d23d9','89ecb05df4f4aaec1029f2c3ea2b3fdd6b3f36946e68c626f081ed0439ffdda3');
INSERT INTO blocks VALUES(310406,'6784365c24e32a1dd59043f89283c7f4ac8ceb3ef75310414ded9903a9967b97',310406000,NULL,NULL,'4a962a898f5795990de43cd3133a60b5b969ad366de6bca8d0b9fcb366759d1a','2182cf309d4d71653cef89f5a9ef64080a0dbbe915ed9d95ff920893f300ccf8','8f84752c786cd9cbac5745e9491cdcc2b657ad0f37b11f03620642e04025f527');
INSERT INTO blocks VALUES(310407,'84396eb206e0ec366059d9e60aefdb381bca5082d58bffb3d2a7e7b6227fc01e',310407000,NULL,NULL,'18e8aad129099c20f268ef8a3664253f8d444a24e3c4942369bbeb80fb76c862','af23c9ef2ed98517acaf57470d5f4cbfdd19d081668df8877276e1d7070a6668','f7db99e35ad12d964039c53b6a06cee2698d542a9c55915b695f9613f1f3d26b');
INSERT INTO blocks VALUES(310408,'4827c178805e2abae5cb6625605623b3260622b364b7b6be455060deaaec2cda',310408000,NULL,NULL,'b694511530b99c6a6d405871f2fde7470baef8e0a2545b598adce5c3b9234765','ea17b55e0f5c71a96fb373acb586e5e531f983454ad8a447656a137580a716bd','b44a263e2d69deec823d634a8b1eaf68a9747b14f2453900e5c55262bca55318');
INSERT INTO blocks VALUES(310409,'01a719656ad1140e975b2bdc8eebb1e7395905fd814b30690ab0a7abd4f76bba',310409000,NULL,NULL,'cfc8dcee1ef668455b7c078698de8c164abcbfe7f6159fe206faeee7b0ec006a','a6683d86d266a4dc5ae590a45c61763bbb572df4afb19e0da7a286f974caae73','d165b1db5ba0afc9c8887b18fe1ef5ced76bf0d06c21f54a9d13a9480bddd83b');
INSERT INTO blocks VALUES(310410,'247a0070ac1ab6a3bd3ec5e73f802d9fbdcfa7ee562eaeeb21193f487ec4d348',310410000,NULL,NULL,'52eeb77c0ba4767d59e4ba0e243032c44ae83abea1fb407c2079e58e869d6437','22ad7f75f8d47ef09c690d731014c71809e6d70a3fc1bc256e71d6c6750e493a','38cd3f2b6ea457a02cfe57d4b7a4f3c300fd697c03d8f055a26d4dc9e37ab916');
INSERT INTO blocks VALUES(310411,'26cae3289bb171773e9e876faa3e45f0ccc992380bb4d00c3a01d087ef537ae2',310411000,NULL,NULL,'10224812cf36a49d15040fb1a3ad3e580f4690e8309dda99713bade55f2299d4','016f77dd7a26cca82bf5d10ebcbd223fba22d0e892446dd83314900d6f1d69bc','92cf5ce70558a080352661520a72a45bf06ab445244a8a102e5c4e2fc2ac5d12');
INSERT INTO blocks VALUES(310412,'ab84ad5a3df5cfdce9f90b8d251eb6f68b55e6976a980de6de5bcda148b0cd20',310412000,NULL,NULL,'2e095263dab63461abb4210a78c96ba09181cdb55fe67113edf6badd5da8a386','99374e6293b04a7d8e73cd768cdc32c6fc55df754be15cf20b8822bd6cc5e9e0','089b44dec372a34c2cc723e9d7252410ceffa395a5a326c5941bfa29b8f329ad');
INSERT INTO blocks VALUES(310413,'21c33c9fd432343b549f0036c3620754565c3ad99f19f91f4e42344f10ec79bf',310413000,NULL,NULL,'5201dd7aaf4dd358441bbca3ec6785eb9f7bb36d25e9aca9e5cecf0e9391b7b3','fbcc5e17a77ca8da3d9e89ec7468f6ff6cb7148f852583b72de01f2f2a85e399','5470bf63ff1642afb4d8f8c0817241f5b203ffe384d94c8fb5258c1bec1c5e9b');
INSERT INTO blocks VALUES(310414,'8cff03c07fd2a899c3bcf6ac93e05840e00de3133da14a413e9807304db854b6',310414000,NULL,NULL,'95de8fbba49b748c4fa28565b47230dd294ac6b02906d1dd7aeea73126db9513','bd117ead5dda516ab903f7fe52d0cf6c0b630244a70a1429cad981063e3c1678','c10ed82a06592f89b5792ba03c49748ab85d2a80f3de595c7e96bea592395470');
INSERT INTO blocks VALUES(310415,'dd0facbd37cca09870f6054d95710d5d97528ed3d1faf2557914b61a1fc9c1cc',310415000,NULL,NULL,'53a7b4628a5273f5b893f64af2db6d66b5b9e4ffe5ae5076b274537245f53b6d','e0cc338d91a4f5af2a9d7b737c66db2d82ef4bd1c5f2b42d05daf50ab8514a28','b9cbad371d09a349efcd116cd90a0bfb3460ac278a8f78f919d1c61000847bd2');
INSERT INTO blocks VALUES(310416,'7302158055327843ded75203f7cf9320c8719b9d1a044207d2a97f09791a5b6b',310416000,NULL,NULL,'f38e62a046767b352776b03cc9103137061d2ebc1365a6589e8604affd29ea84','3ff745fc2a4e39ddd41601c0aa12b594b26b3ba9a413aa28ec8ef48102a40365','7b3b9b4970b3f681cbd7a2d7a064ecc621e5fec912eca336951538ee9e0e8061');
INSERT INTO blocks VALUES(310417,'2fef6d72654cbd4ea08e0989c18c32f2fe22de70a4c2d863c1778086b0449002',310417000,NULL,NULL,'752734f6cb598502a13f567da58739e021aed45268f52c3a56aa94c77dbe4294','b898ea71e4c6866ebd43355d3a1531137f0f1f1bec14b15de0a191c4900c7928','74b6ea64cc6218fed2eafc4201c665025567c7b2e1135c5ee765e169348e7689');
INSERT INTO blocks VALUES(310418,'fc27f87607fd57cb02ce54d83cec184cf7d196738f52a8eb9c91b1ea7d071509',310418000,NULL,NULL,'778a0c66fa9454d466fda8bf21ac02b03d80e18380cc79bff8b481d7832977af','c5eb20b34bf7f74868a9eede519921dc712812a87ef40ab84a8953c96dd167d6','a63bf905908dc4e71612f89c2cc9e085a46e0dc09aefa827d2ca531c9d131d97');
INSERT INTO blocks VALUES(310419,'9df404f5ce813fe6eb0541203c108bc7a0a2bac341a69d607c6641c140e21c8e',310419000,NULL,NULL,'1dd204b4df4f865718b1cffb54a452885c04a524c4f9cd6be0e92bcc937f49db','5b0ed03656363568e842fcb0d900ded83a9617c215b2741de7a44302268f056b','929107a56d377c85c105891a1853c6c666e624d4a342cd7211a534e5f60f8538');
INSERT INTO blocks VALUES(310420,'138b3f1773159c0dd265a2d32dd2141202d174c2e52a4aeac3588224a3558372',310420000,NULL,NULL,'3b77f802ef867f0fd92f1dfff4f7c5ad074ed51f0ed2b1a5d39f1f44e6aa7ae5','916739a6e3a9e8ef3c6adf98ef6e40f57a705201834899feea8d9413175dc04a','80ead05a1405a887a230a46e4775255aa04006fcf8f8cd455420c52d56d3cadd');
INSERT INTO blocks VALUES(310421,'71fe2b0e02c5cad8588636016483ddd97a4ef0737283b5fd4ab6ea5dc5c56b9a',310421000,NULL,NULL,'6d417941e380b66715edb4e74fb63026f35411ce7782afc0a6abd2f5d6193934','a3431b20dbe4bb58a2f4e4d9d5e236c6ed3d3851cc18bbd702414ff8ab81bdf8','ff2687f18e28d47999636783664d09d471fc099bac5fef57e794ba68422ccf4f');
INSERT INTO blocks VALUES(310422,'cd40260541b9ed20abaac53b8f601d01cd972c34f28d91718854f1f3a4026158',310422000,NULL,NULL,'593383ba8869cf5afef0a8bd1212a9a87e69ed1f79d24423f3e268b22038d865','e9b986e7f0c5525626843c71869173c78003a56a736a39bd67ee1ddc3455346b','93f785d82b173e1e5d0f4da5573ed4c18c96b41c9e02c7c9a982af2c158559b1');
INSERT INTO blocks VALUES(310423,'6ca0d6d246108b2df3de62a4dd454ff940e1945f194ba72566089f98ad72f4db',310423000,NULL,NULL,'03ad9d534765ed15c02046dd7076f8d0f9332b987336f779a52ef7da5a63d2bc','15070605f94b19824573f83e1bbf819a502f6e4b6dec1f4c6a419d22361745ee','a00e089332723d809ab346fe415935835ba594a20cbd9c858b1ac181e714d8bd');
INSERT INTO blocks VALUES(310424,'ed42fe6896e4ba9ded6ea352a1e7e02f3d786bfc9379780daba4e7aa049668ad',310424000,NULL,NULL,'028be1a76113906628e18a5ac0b00db7d8769e2450f145653c3b5f117cce2d1d','a5e249b83df7f285ee77bf545899ce2d0b1ab476494239bf85faf18a5db4f95a','e2ca05fe153d45899c5049f0e25fc9081bf95ebd8fd1d5f59a8ee952c6e24bf7');
INSERT INTO blocks VALUES(310425,'73f4be91e41a2ccd1c4d836a5cea28aea906ac9ede7773d9cd51dff5936f1ba7',310425000,NULL,NULL,'83d4a7d8ffab3c5f6d2637ee98a2ed4bf9633f54a630a65c882190bab089bc2d','80b958f84b094465561a4c0557104c3c01efad35923998473a8b118e3cec4404','3d592b2958b1428e1f1ebb82d15fdf02e88ce7cc590c3fb4b9ffe2be97b79d6e');
INSERT INTO blocks VALUES(310426,'9d28065325bb70b8e272f6bee3bc2cd5ea4ea4d36e293075096e204cb53dc415',310426000,NULL,NULL,'7642193a01f93b2511299f4a024138db83f9affa5e14145bd0a4ff0a12fe89b9','ed678c315018260cf7bd8215194cd76dd483db38a7f9835cc6df4eb7404659bc','9a712986c547064bee1523dd8d7ac25d40c7cf99ad4ca5842f716322b6d9ad99');
INSERT INTO blocks VALUES(310427,'d08e8bc7035bbf08ec91bf42839eccb3d7e489d68f85a0be426f95709a976a2a',310427000,NULL,NULL,'8e53bab070408894fa8b2b12a8628b2ae262567533f2a1c49dcb51e564d8baee','dd75fa56e84a2de1b71d966b444cf64ca0818b00c4c853466e4a3d2f5b447c3d','ae9f6b26952dfedd2af0d676b4eddc0a9710e684e281900fe14706ba24c76ad6');
INSERT INTO blocks VALUES(310428,'2eef4e1784ee12bcb13628f2c0dc7c008db6aaf55930d5de09513425f55658a2',310428000,NULL,NULL,'f0af90a06b842c2d6646744b9c7e851e77cd73f27c1e97282aa3e774acb5206e','b0616840d92d90efbd92b60b9a1d6d6bf0e6ef7f5b9850384dc196a81f2cc5f6','245ea33024f5a134c54994caad4c3e0fd4959863df5c68418eaaed75d2bb18e3');
INSERT INTO blocks VALUES(310429,'086bfbba799c6d66a39d90a810b8dd6753f2904a48e2c01590845adda214cf8d',310429000,NULL,NULL,'d96b15c84b51ab0ac9e7250232ec744bfea32aaa46b3202182bb1ba30637530a','f5e31e3ce462c8468c26718fff6cb3ed861fecfb74443b7cc320a38a06a0358b','d122d86885369ef3f018f5f1fda6e32db0553adbccb8cc0d56445bc764db5db4');
INSERT INTO blocks VALUES(310430,'870cf1829f84d1f29c231190205fe2e961738240fc16477c7de24da037763048',310430000,NULL,NULL,'5877f31065e08853d538bb8ff2ab3204d2e7c46003afd715c7ab7e3eba36171e','be93a9f2a1e44991911a5da4e603d59f13617df909b9ad2030dcd259571ae738','3737f5ce29224012406eb7d4949fead83f688a3ae10e5e7595e91023b0eb97df');
INSERT INTO blocks VALUES(310431,'20b72324e40ffc43a49569b560d6245c679e638b9d20404fc1e3386992d63648',310431000,NULL,NULL,'c7693ebfe358dcb264ac98eb74f0d35b8102bc49a189d678c4aa83b792b92b01','b0ab90e36babcfec691ae5ef6288171282c4aa274f107622a78de8cc49dde3fc','6bced1220cd9a2c651b9e3a30ac358a8ad125deb258744a19f559934fbe3d820');
INSERT INTO blocks VALUES(310432,'c81811aca423aa2ccb3fd717b54a24a990611365c360667687dc723e9208ad93',310432000,NULL,NULL,'2e4118a5f40e5a2d4da07622568a61e52ecae05dacd3dd54364015666b9ddf0f','3d78f532cf4fb2448dad26834246193e4f5ceed07b449125c90c47ef0d6539de','346a94fbe6345413f2b5df6314111ec74a1dd0fc292b045583a5a7c0abc6b309');
INSERT INTO blocks VALUES(310433,'997e4a145d638ad3dcdb2865f8b8fd95242cbc4a4359407791f421f129b1d725',310433000,NULL,NULL,'4508c61899741ad3637f891664cd17e8d8dce2147ec22bbddd23d18be7d4f5d8','847172da88f22fa2116633bde55f545f267f5140ae86896cc77d786baf625edc','e1c3ae03789e7568d921e907b3475756509f11ec840202d77810b302de17ccb3');
INSERT INTO blocks VALUES(310434,'61df9508e53a7fe477f063e0ff7e86fbb0aef80ff2ddedc556236a38f49ac4d8',310434000,NULL,NULL,'222a7017a5159405dfa7ca716a368f84df446612b2e969ec775a56297f67c445','77959f570a890945fc6eb5c3485d314d04fad626648afa5c3575ca4852df6364','6a2d566f44c6e8d28be8fc35750ad3d17feca619d30ec73ec29fd85b1982b968');
INSERT INTO blocks VALUES(310435,'f24cf5e1296952a47556ac80a455a2c45da5c0dc2b388b51d235a3f741793d5f',310435000,NULL,NULL,'cf0f27b94a70b0dba7ee5391c51df323c154c767b21e7f18696cfb93e25e663e','6e69572e869d80409eed809c740cf0182e418b2f27c96b5d2866ca88afa59dc6','2251793ec4b27d22259b57d7ea11602afc30fd53a6c91fd1a108a9e364e2106e');
INSERT INTO blocks VALUES(310436,'a5e341ba92bdf9b3938691cd3aab87731eba5428bb61a804cecf9178c8da0c19',310436000,NULL,NULL,'15455076d1eb6681233124bd7f4fd59586a22067bb008d8132e31c0019f3990d','811cb2ebe130eab6d47b4c2fb5d8abe828a76f199cd0aea61a7eac2e2cdd9965','7b24ba07b2529e6b8a87d225688bd83f04874a5876cf299a749099aeb445f2a3');
INSERT INTO blocks VALUES(310437,'9e18d0ffff2cb464c664cefc76e32d35752c9e639045542a73746f5ec2f3b002',310437000,NULL,NULL,'03e6c21526a9e7ad688f8ee47638b2519b2a1ff0c47332da366a1077a9d93dae','0de64d1293be20894b91e3365cc8bfc138c084939184631269ecca015ed571f2','c449d3ab34e69e7271c6f8c2e641ee048902cca537fba59520e59688f1b89b7d');
INSERT INTO blocks VALUES(310438,'36be4b3470275ff5e23ed4be8f380d6e034eb827ebe9143218d6e4689ea5a9fc',310438000,NULL,NULL,'dca613e290eaea92a4bde4f759fca67923568f0af3ece38c4165fe66787f5a61','5b8e9a33af40baf9fd9736e64155c3a40e73f7818431ca15031c883c2a974fef','4a99075ad8a1d4144c03685fe4e08006b1a10ae03d7001b82a97cc2f92355491');
INSERT INTO blocks VALUES(310439,'4f2449fce22be0edb4d2aefac6f35ce5a47b871623d07c2a8c166363112b2877',310439000,NULL,NULL,'9da932c8c4c9a12d536db15649b8b89df52be294f3a3b16692618d2af421c1b7','677afd8004316a572cfc464f212daabe9e2e7be9f38ba291a842e961c7ba8dab','7bcdc4df4dab32b08dbbb6e2162534dada2a49b52f5947eb0274784398ff976f');
INSERT INTO blocks VALUES(310440,'89d6bd4cdac1cae08c704490406c41fbc5e1efa6c2d7f161e9175149175ef12a',310440000,NULL,NULL,'ac9f1ff2a3adffd79ea3b2b13289ea060d2fa1ed9656a61057d1802531737221','7e7ffea397b93b7c671b7e8fc47b52835a6e68704f63af3a6fb094faee645714','69c023711cc73115d736d8c3a69d4e1951a21793c978723f3fe60eabc1ec23ec');
INSERT INTO blocks VALUES(310441,'2df1dc53d6481a1ce3a6fee51ad4adcce95f702606fee7c43feda4965cf9ee15',310441000,NULL,NULL,'4513dbf40e2b572ccfdb857eb58d4008b82959d110c094961cc7587ca9672316','d50ff04b6b4e268c75a8300b6cec1add67b6513779d56de4381c47165de7051d','2966cb32226f4335bb52d4b6421838f14467983de4e1acb3eaf1cba8a8e0fac2');
INSERT INTO blocks VALUES(310442,'50844c48722edb7681c5d0095c524113415106691e71db34acc44dbc6462bfec',310442000,NULL,NULL,'e806ef15930bf2104b63bde714b397312052322dd034f0df727b738e05e1c753','d251120901eb70308ba2b2c5a1cc0153bd0e3fbde290b43bc072b01a2826f0c8','539858a01da68a91fcd08191e48c32026bf16b8801917b518f12ef6a5f7db060');
INSERT INTO blocks VALUES(310443,'edc940455632270b7deda409a3489b19b147be89c4d8f434c284e326b749c79a',310443000,NULL,NULL,'3f6cf11776817de3eeece3f754656bba718ed2d9fd52034f8c49b27ab12bae8a','1cfbfc9205d0dd939687d079ed48d0b976d28c7a87447eb1123d6d906babc05c','3582f2e6a1a2bb2737687b8b20ff9d30044a737ca19030433719a73438fe6f9a');
INSERT INTO blocks VALUES(310444,'68c9efab28e78e0ef8d316239612f918408ce66be09e8c03428049a6ee3d32e4',310444000,NULL,NULL,'da23b14ec6cc706fbeec8e796522dab412bc72b96833ebe9eb799e72623129b0','bbf8ccde1bcebd2a7931b9926b48d37f67bd4671d54463a3e69164bcea8da3d0','34ce2c3ba8fe46c5e9330d61767b97957ebc3bdeda1448e18c02d160d4c21e03');
INSERT INTO blocks VALUES(310445,'22a2e3896f1c56aefb2d27032a234ea38d93edf2b6331e72e7b4e3952f0234ef',310445000,NULL,NULL,'50e9c4330e9f1fc6c563bf924064999f3e8feee2fe107884a95c913df2008da4','d12b48e86bb04c3084af14a646b9a42f0b76bf9704635967a9c50945252c3de5','891b5eada87e0df173b5a9f653c5622dca42d95711bcd49a38931fb458268a2e');
INSERT INTO blocks VALUES(310446,'e8b0856eff3efce5f5114d6378a4e5c9e69e972825bc55cc00c26954cd1c8837',310446000,NULL,NULL,'1b6f3d210ff3f0b1c0342419467a17c0d34ea1eea4e99ecb5ddf5e280818a983','2c9d248316e6a168857c102f520f4f6b4adbb6ba3fe1d209c54608b5e29091dc','30aac77e7141f7a82675f9f0d7b452de64c204386a983a0b955430854292cc62');
INSERT INTO blocks VALUES(310447,'3f4bc894c0bc04ee24ed1e34849af9f719f55df50c8bc36dc059ec5fa0e1c8a8',310447000,NULL,NULL,'d5d10b1d7843d4070508a79192c7b1bb92876e64acef659c01ffce3c5ba5cfc5','488b0609ef6eba895763fcfdef6eee004cf5fc6c0e7769184df84949ff608b6c','75c34754ec28fac8d38d30b24e293be4c59abad7ef0ec1ddf7311923e75a9963');
INSERT INTO blocks VALUES(310448,'6a6c7c07ba5b579abd81a7e888bd36fc0e02a2bcfb69dbfa061b1b64bfa1bd10',310448000,NULL,NULL,'488c8a4a6aa3850d0ea6c0f12ecf4cc9bf400aae8c4b5e4cc5589152abe5a90b','c976933002ba89cb7738b738ce7c1101cbb83411bdf45cc1cd797a4e6b0c5a34','589629b686c39993ae31c16b955ad5cf1f073e55127ed1c7039d78e3b9c424bb');
INSERT INTO blocks VALUES(310449,'9e256a436ff8dae9ff77ed4cac4c3bfbbf026681548265a1b62c771d9d8e0779',310449000,NULL,NULL,'5f8b738744da401e84d1174587d7e2900278621f3497adb94115167218e3d68f','58bf59193b5ba78cede51beb67ecb61679a0ccad9540c5bb8190b278b429e286','e05578ee4d895cbf4cafebcbad3684c0091009a91b310ae2d499a26a7cc4c8de');
INSERT INTO blocks VALUES(310450,'2d9b2ccc3ad3a32910295d7f7f0d0e671b074494adc373fc49aa874d575e36a3',310450000,NULL,NULL,'185dba1b235227514d6ba11bd279b9fb05607714831edbc854c3dad8d17ee11c','a1d3f3fcb83e4d01f9d83256affa440e5e4318ab3a23336921dbd49d4a6efa82','4e72cb69a93449dcc1c3897d3082fda8d1d2f0beaf8a0ed44b8074c57eb726e3');
INSERT INTO blocks VALUES(310451,'55731a82b9b28b1aa82445a9e351c9df3a58420f1c2f6b1c9db1874483277296',310451000,NULL,NULL,'605cbe563d57fd6cc0d05d40e6217703ef899c9e61bdef381cf996403a782808','1a89de4839cf1ac4f5bab6b17c9b8e2ddee6dee4f882dd8edc6dbbea2ebf773f','9770fbc1a557ed633f73edf955f6ef664de37aa378ddf4ef2601dd08738de1ba');
INSERT INTO blocks VALUES(310452,'016abbaa1163348d8b6bc497cc487880d469f9300374a72ecb793a03d64572aa',310452000,NULL,NULL,'c3ccf7d83bde4f7b5777c902b809841ae0c4c2db098bcabdd1aff128ffc6fd5a','b4893dc6d86cec83a3452086c2e9c1887e17c0cdc28ce75cc34f841a5376cb62','6b71c0bbd7222af190da8625a89fd1627e534082b7f49f0d82a788ffcda48b20');
INSERT INTO blocks VALUES(310453,'610be2f49623d3fe8c86eacf3620347ed1dc53194bf01e77393b83541ba5d776',310453000,NULL,NULL,'3dac0390da1c50e05051eaa60ad2aacb0112adc54e0f0041a00db0a519333ebb','4749ea797246ec19dd6675a7d12e2d9d2f3725e46a204ea20f70fd65bf432824','1c67eb07209209711b22eaa20c7f6c2aaa09b0e489f698acc9be03c4af1973f0');
INSERT INTO blocks VALUES(310454,'baea6ad71f16d05b37bb30ca881c73bc48fd931f4bf3ac908a28d7681e976ee9',310454000,NULL,NULL,'8fea87fc079398499692f207ae111d25a034576c0f2407383a20bf73ffe66d06','e61d02faef7c4f15b62be1fb4f011fa77f70ee581c0c5a8ea466bfdaef215736','faf59cdfc48ae5ca356e82a477b20e7876c8a8c14f816997f09e658d9f4ebeaa');
INSERT INTO blocks VALUES(310455,'31a375541362b0037245816d50628b0428a28255ff6eddd3dd92ef0262a0a744',310455000,NULL,NULL,'ce885b73d40cb2ddb6ec6474bd94ab4470515679f54fb47fc5bca7a87d1ca261','e67ea280c84669c532080173152b6744b6ecb9094158c7c95fd5b7388c30c900','9d6819f6917ac4bfe36107c93e04b1ed5ea6b45a5ed7b1f6898c56722dfc41e3');
INSERT INTO blocks VALUES(310456,'5fee45c5019669a46a049142c0c4b6cf382e06127211e822f5f6f7320b6b50fa',310456000,NULL,NULL,'16693fd96eb42e01b5ccac8c4978a882a50ff534c33ef92d9eab923988be8093','5d09738992d564203c075ae6eddf14b13679e5fc82c7ed902480650c24bcedba','4ea5baa9beeea85c2472d5ab1964cdd58f180f600c5a3d1ab5d7bb25e768e43c');
INSERT INTO blocks VALUES(310457,'9ce5a2673739be824552754ce60fd5098cf954729bb18be1078395f0c437cce9',310457000,NULL,NULL,'81c06ed2e28e3eb67497d2508ec8399558d4be177fdefc525b7cf8010546da82','161727723295e09bdc5ef4b560896ff6e2d28b9c1e3369f1ae3b1cf756dbaac2','551162e582487b67cda0b69462467722baa0aa432e8dc4ae089fc63c5cc55e48');
INSERT INTO blocks VALUES(310458,'deca40ba154ebc8c6268668b69a447e35ad292db4504d196e8a91abdc5312aac',310458000,NULL,NULL,'bb906ce3def50a1573ded94e2ee8cd278375318479682145a72a3b9cd67f18ec','eff3e3f2eaeb5d496fd873a85b25052e33eac60355e8ff99a3320126e3a93240','418ae49aa4832fc565adb3446462cea147f1a61d475e7263dc6d780fafddaf4b');
INSERT INTO blocks VALUES(310459,'839c15fa5eea10c91851e160a73a6a8ee273a31ab5385fe5bd71920cbc08b565',310459000,NULL,NULL,'874afd2de9bfa523ab45482e1d2ff2a9136af0bd5ade66d7943564c504ef944f','e1816a0281a523ae49c3b6df7c041fcf0d6628bc0e222fd94e6c4e71730ee3cd','1c7ce23cedf2127ded76f74b4ddf5ad1e3a39aed81765219481329d77c186fe8');
INSERT INTO blocks VALUES(310460,'9b5f351a5c85aaaa737b6a55f20ebf04cafdf36013cdee73c4aaac376ad4562b',310460000,NULL,NULL,'890e72732c1d57443213ee7a7270b3e2a7e9087522f57189ac61cd6dc852abfa','f0b0353a345ec249d80b8d6835640bc40a368566054b879a2b4abca1551d657e','91bc5821fdd9086042b01b123dba621c86048e3967b0f7f079ca238e4fd23d86');
INSERT INTO blocks VALUES(310461,'8131c823f11c22066362517f8c80d93bfc4c3b0a12890bdd51a0e5a043d26b7b',310461000,NULL,NULL,'8627256f470d906d5c784ba257f4f7d29e0d81347c7566727aaa26afd0a9b251','c8a24b5801b139e46e3af92caefe8d44cde941911f9a7c4a560d668aacf9d894','c17fec436327d110d940e0f79e887e8af714cdc6b230b8e174b38169e097ca16');
INSERT INTO blocks VALUES(310462,'16f8fad8c21560b9d7f88c3b22293192c24f5264c964d2de303a0c742c27d146',310462000,NULL,NULL,'d1829d2db4718331aea74e59d3fcedc3f510aaab82f3f7f956087b32c040f63d','26080ca9c73d9377c38d6d8c25f5cd786b849f71d47e61700c4eea9b7e351a91','27ea471365f305d9df7d55da54f110ee0253b36c583d71d18016f3678bb3b792');
INSERT INTO blocks VALUES(310463,'bf919937d8d1b5d5f421b9f59e5893ecb9e77861c6ab6ffe6d2722f52483bd94',310463000,NULL,NULL,'8b83bf9e263c69e8f731d90c9e6f92b66dd1652ea76390ceec58883f3ffe881e','41e31f77853a021a10c365e3e852217688ea20342473ffef0dc2a08d5ddbf2a3','7b678146b9d22a6830bdb79411fe4a3d589767eedb85db61ff6f8197d1e947e6');
INSERT INTO blocks VALUES(310464,'91f08dec994751a6057753945249e9c11964b98b654704e585d9239462bc6f60',310464000,NULL,NULL,'a93fbb5f298b41d3123312fe41ed8c5811410c32ac31062ff513c69a6ada8e53','17965a56b089fae6ef4fa0f9f9df96cf7156d0ee9a523385ef251ac347ec0438','b89f47f6ed5a05aff72ecb5aef6bfe8c7f7219101115c81f4ddc62cf9c439d17');
INSERT INTO blocks VALUES(310465,'5686aaff2718a688b9a69411e237912869699f756c3eb7bf7c3cf2b9e3756b3d',310465000,NULL,NULL,'19ea9e27f997fcaa3c260bed12a628b55054b6f90d579ff3e41ab1cb29240778','09c6e63abf267bbd508767eddae091bea2d42348c611bef9b07d7d728e94f07c','9fe74380ad9c9bf1f86f33c9bc11292eb5fc09b6eed0d6447df2fb2b06f01f41');
INSERT INTO blocks VALUES(310466,'8a68637850c014116da671bb544fb5deddda7682223055a58bdcf7b2e79501fc',310466000,NULL,NULL,'90c850f7cfe700fdea8d8d60fa03f080861414ec372a7d920ca6d09217f82fda','2b5be89c0ac3daa3cd7ba9317a8cef9256befd5532096cc83aa13373a7ffd575','d7ccdf030efbc63bc007eaff7c8fc3148a99993c5deea0e39167143d1d7d5bcb');
INSERT INTO blocks VALUES(310467,'d455a803e714bb6bd9e582edc34e624e7e3d80ee6c7b42f7207d763fff5c2bd3',310467000,NULL,NULL,'9f92428bfddcff24329af3b4c0b3200e8b4ae3065f9b6a8a6488e159abfe6854','88a7a8c8218d98c9b490c0696b8aa6127a0b3c2bdeeb902a24e38637c19b18c1','05123bcd3659a03736fb16c50de2b70eb8e64d656aa249ccffed0ddf8a50f365');
INSERT INTO blocks VALUES(310468,'d84dfd2fcf6d8005aeeac01e03b287af788c81955612375510e37a4ab5766891',310468000,NULL,NULL,'0cf6101033a96e6a90572ab21502314470c4b544bf21a902845861c413e1775f','41c05d3a7a52d0488435a7e3cb1fc321181f71063384d32e477ea562c90f60c1','cb9fc40c4e582e0ed88340b398741758a7d8ac02f68cf6031a5f826722b654cc');
INSERT INTO blocks VALUES(310469,'2fbbf2724f537d539b675acb6a479e530c7aac5f93b4045f4356ea4b0f8a8755',310469000,NULL,NULL,'93f157cc43a6dc2df588c7cbddca37e55eddf5a94fcac82ebeec2d8d252a515f','c6e89a7a7772e3d686d61a596fd9405173df41e6bbcba0719cbf51a4a3555dd0','b9f74207d75e0f0d8c8d5269e9663aa0d68ad6536b4625a775a2a2356326dda6');
INSERT INTO blocks VALUES(310470,'ebb7c8e3fbe0b123a456d753b85b8c123ca3b315da14a00379ebd34784b28921',310470000,NULL,NULL,'d6ebcad8b1743d6dd898a522304594242eb063893c1d07baa893c076f6ccdc3e','b433c1dc877e90fb20bd917bccdfb897e23ba96622cf03f1b17ac899bcbf5a62','9719459b2f8f55c3a4f3ffe72cebe114f9869ab58fe0ed3408d62d89fc7927fa');
INSERT INTO blocks VALUES(310471,'fc6f8162c55ecffeaabb09f70f071fd0cb7a9ef1bccaafaf27fe9a936defb739',310471000,NULL,NULL,'e6003555728c70ecd67dc8de1248de291a2d3a5d9fed35d77fd0888b5c7a1997','f2f94233ac6db7debde508f1319b98a631490610100e6e05450a904eeccd00a5','57e9e471e4d70a55dfaf7fc1b2c995510b4db4f85e33647612ec920a390eb566');
INSERT INTO blocks VALUES(310472,'57ee5dec5e95b3d9c65a21c407294a32ed538658a6910b16124f18020f16bdf7',310472000,NULL,NULL,'dd553bc627b16f15cd618dd0504cd0ec04724610ff6ed44515957c997385c826','122b76b81bfa752ea2b43fd06a333fe4cdd64dadd605a2385e639167f335db1b','81169e3b519bf581d003e8f29a4c15745f1ef141dd9176b1edc19d7ebb12cd69');
INSERT INTO blocks VALUES(310473,'33994c8f6d06134f886b47e14cb4b5af8fc0fd66e6bd60b3a71986622483e095',310473000,NULL,NULL,'9290c164b0b011d53eb80193285fcfd830e524183cce1be181a48f085601845e','3c5b73cbf24917ed2abfb9ec801e43b3042c6bf6bb5a8d6de394833a54b8412a','1856b13876ed02196986073ff2dc3d447d862a1f81dce0aa6366caf2af1e3628');
INSERT INTO blocks VALUES(310474,'312ee99e9526e9c240d76e3c3d1fe4c0a21f58156a15f2789605b3e7f7794a09',310474000,NULL,NULL,'7aba0609948218e622e3293760bfddaa1ac4669eeaac6ec897aef5ab1268774f','e1e8bd3b8e929fbc21797b7f6f6f35e625297a8aebd0b4e96ebca2e395104ef4','0a79693a007da7c4e52aecb3f4ad5373fa55d8402a653968d8e03533f2bf44ed');
INSERT INTO blocks VALUES(310475,'bb9289bcd79075962117aef1161b333dbc403efebd593d93fc315146a2f040eb',310475000,NULL,NULL,'bf95d8500066d276cc48546cc2c29398e26511097cc658b21d6a537c2d8876d7','0a663d23aad91dbc3beffed3b81ec30628e79c1e9bdf0947164a1273178bed8d','9cf189ce8870b4cc682c6bc72f72d4f1c224310eac222ec68ea5afae4f4a593c');
INSERT INTO blocks VALUES(310476,'3712e1ebd195749e0dc92f32f7f451dd76f499bf16d709462309ce358a9370d0',310476000,NULL,NULL,'89d6256d5a7f5412a5eeb9b5551860b7ea26b096a2b8196b61d437ba7ee797f6','0dc80a8b631a0c8b4cd75ce41d100d3ada3c4e757e07726ab3d63ff5bc0b039e','9796d7d0e9ade6b8bd8fa7cefac91af3324e994f768b79ae98c14aa5236ef1ed');
INSERT INTO blocks VALUES(310477,'7381973c554ac2bbdc849e8ea8c4a0ecbb46e7967d322446d0d83c3f9deab918',310477000,NULL,NULL,'31e4ee682d84213876eb8d85cb92d32688c4dd9110a9a90d74cfa275b50b8bec','3d4169f5c60fbe68f6be6866b9f5aef0a3200773ebc7cf425a88eaa3208d4f3f','23a3a4d6810e2ce2f79a9898db4595b020a051b51c4a14e9fb108188cfddb877');
INSERT INTO blocks VALUES(310478,'c09ee871af7f2a611d43e6130aed171e301c23c5d1a29d183d40bf15898b4fa0',310478000,NULL,NULL,'941bcbb6d7a89a86859fdc1516c0e64a1473b356f42846d2e8a353b08967fd46','fc0441520ba093a7cc41c4b116e9cf9dd79b33dba3c28ff4c506478ae5bbe4d7','b4a5470dc08894163a5d62451d2ba39491cf2cead2e00432bc3e6e464ee514d3');
INSERT INTO blocks VALUES(310479,'f3d691ce35f62df56d142160b6e2cdcba19d4995c01f802da6ce30bfe8d30030',310479000,NULL,NULL,'8c271f55a292b69f95c50228be57e8a1a91b94998756abd8ce431e657fa4055c','1965799818ebc7eb4881a49bac9cbc1d270b2f0e820ef5fd0005dc8f3674dc85','99917d71d597f0048eec5e6585a1f0224e886bf6b59d824e04fa3819806651b4');
INSERT INTO blocks VALUES(310480,'2694e89a62b3abd03a38dfd318c05eb5871f1be00a6e1bf06826fd54d142e681',310480000,NULL,NULL,'aa0c833f96cce186008d339452e92d054edd67397c538baac239b10df8f9bcbb','cfbde5be1a8d30f119ac863162a8e11de2b503ad85ea9a6d3adeffb2b4d79817','02244ac4880db08942d8c2d236fc4aed2c6b54fa359ffffadf100929b2424c4b');
INSERT INTO blocks VALUES(310481,'db37d8f98630ebc61767736ae2c523e4e930095bf54259c01de4d36fd60b6f4a',310481000,NULL,NULL,'596ff1cd4069e7a0d62db64acfe1502ca4bfc6d3ac792794ad980c5f654f1a01','a5417e3c76533039c1abdaeccb1d07009784eb1624e2f7faf07ef262a54a4428','a182d66c0bfc81880a21b844190be65a77a688bd4776a2a9d61dd3679d0962ce');
INSERT INTO blocks VALUES(310482,'2e27db87dfb6439c006637734e876cc662d1ca74c717756f90f0e535df0787d6',310482000,NULL,NULL,'bbc1ac936d3ea0f0ab911d79ec003e0ce0c20d6adf507dc5c94a773659b0b734','7ad3b6a18c14d8894df05cbbb8ec1c4dd81edf2402f208111b4eb6229f98358d','f90ad43b126c245d1c824399fdd6366d67c72f3121c2c29f86c9faa3a35dc3dd');
INSERT INTO blocks VALUES(310483,'013bac61f8e33c8d8d0f60f5e6a4ec3de9b16696703dea9802f64a258601c460',310483000,NULL,NULL,'008c287f38d96307ee4a71ea6a8f2c42a35dd54c4a834515d7a44ced43204845','bf12f080b6deb890a39484513bd89f4f7bb51c6865c3655717476def8218e1ff','2418e53773edd625d9da1cb74ff7698c82a1e54a2d279fc3b23ebe1ded28f3c6');
INSERT INTO blocks VALUES(310484,'7cac2b3630c31b592fa0497792bed58d3c41120c009471c348b16b5578b3aa2b',310484000,NULL,NULL,'d7f3ec5feb14b12b410fa72344620e930037d15cdb36295fc68aa0f4087eb631','0d9a912f2a7545ee70e89b82df8a825eb01e4a6e130516fada1122d2a3665bd9','fb2ef776f000355814b697fafeeea63754dd79ef0a32bd3c6b65355017d4bf70');
INSERT INTO blocks VALUES(310485,'eab5febc9668cd438178496417b22da5f77ceaed5bb6e01fc0f04bef1f5b4478',310485000,NULL,NULL,'10856cb1b7625aa217ea3009f10aa1e772a627e302f4191eaba5d332b8daea32','6d2f9f2d795be7ae7b69455b488e0cca01296560b27649f781d0c045b31540f4','395c83fed8ec314d740b769ecf74146fd401dd5d335003ad2418ca004a45c36d');
INSERT INTO blocks VALUES(310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,NULL,NULL,'d4d08e6c5c0a9d491cd2c754047a78a566a86a0b4ef81c3037a9d438803a0fb6','c78a299f8c83f74a002df6c46644e19cb00957aaacbd6d51cdb575a4afeba4d7','26e027f4283e53e74c79ea078f4779269d24fb5f6930e96b6fd762bae8cb1f48');
INSERT INTO blocks VALUES(310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,NULL,NULL,'bca482be2e942516ffc60a62ea7ea7e44158e8f9b72bb6e5dbe61cd740d300bf','64e98e14999f7b891a7b9b6e722ebaff2261a398e34c9e30af3317fbb28fff79','56155daecf4c6df55e12115cd3e5e96ecc89cc2d7a3acd255522700d1747e1c6');
INSERT INTO blocks VALUES(310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,NULL,NULL,'fd124a3f80b354ca106cd653717837f460b565aa5b4b40dc23ecd56b3b97b28b','728f552fecf50cd44e8c73d72b4d90cf47906b94220d9e0957587d9db062829f','dcb1b2916765c3d4207ae2ee925245ceafb99a7794339258897b37ed05499193');
INSERT INTO blocks VALUES(310489,'2efdb36f986b3e3ccc6cc9b0c1c3cdcb07429fb43cbc0cc3b6c87d1b33f258b6',310489000,NULL,NULL,'dc544e57a124565269bbb4b2d9ae2102e6ed177196b07e02d55a9ac99611b752','ddfd7f8a51d06f632b5a216d4ebfc4f32a7bea63c88e10231b91a6f2981a1162','b7db61c2cbe8d9cf6e7bd172f34219b1f0ee8172de29963a42e8f1a0383fb5fb');
INSERT INTO blocks VALUES(310490,'e2cb04b8a7368c95359c9d5ff33e64209200fb606de0d64b7c0f67bb1cb8d87c',310490000,NULL,NULL,'8165de494fbcaee2f48f0ed7b671d5a7164b4e4e6198b5e1cd8f88850af150d7','09300f2fcee5f4736f5ad2ced2c484068fbff3b38933fe4cf1457e76959b3735','5f3437cb22f01b5b1468dfbe97fa0e784b663d4e1e96eb74811a08e563d53ddb');
INSERT INTO blocks VALUES(310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,NULL,NULL,'953105bd7e2e93c74ed3ed8b8717d7238d636a0cc4e50d152a1783aa5f320204','c7348675ca86f624a9b837cb93571434ba28c6b344318c1052418ad03e999f2e','38a9d33b79961d8613410320a814794e560f61756a078c52c1e9635c6232fe8f');
INSERT INTO blocks VALUES(310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,NULL,NULL,'1fed308916a5912e8b0166d5a27ce74e23ddddcfd3f7b99ed77a01ff398142e1','92c7d79b9d72409a7f46171749ac22adb6aa9f34f198462b213f6a7dd2c044bf','311ec0b3505fb4968c5dd024d68f6f9d26f0a8037f4badf3cf16aab5a2f62f8f');
INSERT INTO blocks VALUES(310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,NULL,NULL,'c0136baee1305a5e5a933fa78f2f93cb40d06adf04540c94dab3c085208e1d25','abe5f2f0336b616622ac3536b9f70d5fd9594373697e4f277f0b6b63de406be1','8c643a0fbf13f7410b009bc8aec46a6f05777c1c9adde5cc5ed404e466d0bf59');
INSERT INTO blocks VALUES(310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,NULL,NULL,'7e6e5551f8eaa241d3289fcae360170937aa4a35f2926611ab50793b7cbf1b30','2e21a537ad041c4d1d88fcb5d3e35d519dbf8e41c48d940c510658a68f764ea6','aebe71561a50635c8d0d176877c53cdbe5e828f5424b3dbc0725e342526db8b4');
INSERT INTO blocks VALUES(310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,NULL,NULL,'0b40890a253248a31cf00d2f75abcbc9871318364ec224ce94cd5c6d29b15621','4ad67f9961270b762e367b7befd4aa25ba1ef439d1625648f8a9265530e74407','74bf87c3e0aa70493f61c8c8dc0c2fe09f6e3827c588cc2ff2f21a154dabebfd');
INSERT INTO blocks VALUES(310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,NULL,NULL,'88aaf1b7f8cce768bb3744e68017b52fa82999dc6ababf7c0cab9621f9ab4160','5a9a08a4cfa7300a3f855101cc216ca03ff84ee5bbb807aea60165a4837bb190','2638cb63f7b969071330778513c56db03caaf8840ed1ae8740c3a54ba0613d79');
INSERT INTO blocks VALUES(310497,'f1118591fe79b8bf52ccf0c5de9826bfd266b1fdc24b44676cf22bbcc76d464e',310497000,NULL,NULL,'416fde25c97124281ff88eff164a6ef67b5a32563c2481b5c44654c3e4662873','da6900240022d57dbc8fff098fd118de9708e7a24168bf4b2af5682748928c9b','07986b8891adc84b4224f277d3bedde86e86c618cc7d597a658f2bc19c60c7fa');
INSERT INTO blocks VALUES(310498,'b7058b6d1ddc325a10bf33144937e06ce6025215b416518ae120da9440ae279e',310498000,NULL,NULL,'3d2840702d2c9ffe48974e565744e41a549c9a821857b39be3d6257517a96bc9','f1baa2e8c5d7c996d091d8706bcfed3a73e613de3c817c58342d7d8e63c19752','c8453be7534d0e362a03ad326a1a30c19b67a726454d4b424f2d971cd4e3dfdf');
INSERT INTO blocks VALUES(310499,'1950e1a4d7fc820ed9603f6df6819c3c953c277c726340dec2a4253e261a1764',310499000,NULL,NULL,'a1394288c9651278a44d87a348d74e999645e8f7f2d4335df845dff30e11701b','d4804717d5cae327ec17ee1daa01a6d06463da3ee5d12353e4678090b9970378','57f5c82f8849d87bdd5bd767a309d496af78e0923c34afe5c1e955e72982cd59');
INSERT INTO blocks VALUES(310500,'54aeaf47d5387964e2d51617bf3af50520a0449410e0d096cf8c2aa9dad5550b',310500000,NULL,NULL,'19ec7324adaeaa81dd4f160040bebf7b9395458cb50e06a416f24229cb956245','b842d5b9d6c6f259d3d7a692188c4759801bc545c9e4fa73fe3977899960a17a','49fdaed8418a27ea93e226cd1f0b3e7beeac99b5b13eae96078b6fbc5d5656e0');
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
INSERT INTO broadcasts VALUES(103,'7ea83c28a07116e03bebc36872a631174bf5bab965c7ea676274f7e79fb83410',310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000002,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(110,'5b244b5145b725728fb2e5b74fb800d8129b962c4e41f478128fc133f188da6e',310109,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',1388000002,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(487,'096883e142a87377d3a4103f4702556e25824f1e23667aceb1690f66e1417062',310486,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',1388000000,1.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(489,'942e2f89bfd87a4d372e451da5c9118668581533af153b864354869fb88606cc',310488,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',0,NULL,NULL,NULL,1,'valid');
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
INSERT INTO credits VALUES(310020,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','85c91b9de7c50d74ef9177c748162b99084ca844f3eff48405c2c7918ef78035');
INSERT INTO credits VALUES(310020,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',0,'filled','85c91b9de7c50d74ef9177c748162b99084ca844f3eff48405c2c7918ef78035');
INSERT INTO credits VALUES(310102,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',9,'bet settled','7ea83c28a07116e03bebc36872a631174bf5bab965c7ea676274f7e79fb83410');
INSERT INTO credits VALUES(310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',9,'bet settled','7ea83c28a07116e03bebc36872a631174bf5bab965c7ea676274f7e79fb83410');
INSERT INTO credits VALUES(310102,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'feed fee','7ea83c28a07116e03bebc36872a631174bf5bab965c7ea676274f7e79fb83410');
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
INSERT INTO debits VALUES(310020,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',9,'bet','85c91b9de7c50d74ef9177c748162b99084ca844f3eff48405c2c7918ef78035');
INSERT INTO debits VALUES(310101,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',10,'bet','aac845aa4eb4232be418d70586755f7b132dc33d418da3bc96ced4f79570a305');
INSERT INTO debits VALUES(310107,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',50000000,'issuance fee','ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e');
INSERT INTO debits VALUES(310108,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000,'send','f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481');
INSERT INTO debits VALUES(310110,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','XCP',10,'bet','d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048');
INSERT INTO debits VALUES(310487,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','XCP',9,'bet','2447f6974033ac41c40b4598dfb73fc7479fd85bb9d01de2267b3f7842803275');
INSERT INTO debits VALUES(310491,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09');
INSERT INTO debits VALUES(310494,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',50000000,'issuance fee','4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5');
INSERT INTO debits VALUES(310495,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','DIVIDEND',10,'send','129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc');
INSERT INTO debits VALUES(310496,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','XCP',92945878046,'send','1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6');
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
INSERT INTO issuances VALUES(2,'9cd12fbcb360926dfbc6fc57c2e513a149a66fd12092453c2765bc89d725d57e',310001,'DIVISIBLE',100000000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Divisible asset',50000000,0,'valid');
INSERT INTO issuances VALUES(3,'2efe98f74b6d5963e271457253e6a1748a90992eb0531d60a615d3ccc3986b73',310002,'NODIVISIBLE',1000,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'No divisible asset',50000000,0,'valid');
INSERT INTO issuances VALUES(4,'4361d0ef173c245f3cc5053d5e2513ef9120e5e8abcdcf7c86e164becd53ceeb',310003,'CALLABLE',1000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Callable asset',50000000,0,'valid');
INSERT INTO issuances VALUES(5,'e73d6a9873df9f2264fe2d7f2da66e3a8975bce90d9ec285e79eb47348b41fe1',310004,'LOCKED',1000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Locked asset',50000000,0,'valid');
INSERT INTO issuances VALUES(6,'1aa86ffaf6e3bafbd00660ccb794267a9e95814406394d2f1d5dbd6d2ef01579',310005,'LOCKED',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Locked asset',0,1,'valid');
INSERT INTO issuances VALUES(17,'19cf9fd72fd7c1c766589c39cbba55cfd7495047d1773fa46e6b91c16ad85f93',310016,'MAXI',9223372036854775807,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Maximum quantity',50000000,0,'valid');
INSERT INTO issuances VALUES(108,'ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e',310107,'PAYTOSCRIPT',1000,0,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',0,0,0,0.0,'PSH issued asset',50000000,0,'valid');
INSERT INTO issuances VALUES(495,'4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5',310494,'DIVIDEND',100,1,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH',0,0,0,0.0,'Test dividend',50000000,0,'valid');
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
INSERT INTO messages VALUES(0,310000,'insert','credits','{"action": "burn", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310000, "event": "6dc5b0a33d4d4297e0f5cc2d23ae307951d32aab2d86b7fa147b385219f3a597", "quantity": 93000000000}',0);
INSERT INTO messages VALUES(1,310000,'insert','burns','{"block_index": 310000, "burned": 62000000, "earned": 93000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "6dc5b0a33d4d4297e0f5cc2d23ae307951d32aab2d86b7fa147b385219f3a597", "tx_index": 1}',0);
INSERT INTO messages VALUES(2,310001,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310001, "event": "9cd12fbcb360926dfbc6fc57c2e513a149a66fd12092453c2765bc89d725d57e", "quantity": 50000000}',0);
INSERT INTO messages VALUES(3,310001,'insert','issuances','{"asset": "DIVISIBLE", "block_index": 310001, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Divisible asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "9cd12fbcb360926dfbc6fc57c2e513a149a66fd12092453c2765bc89d725d57e", "tx_index": 2}',0);
INSERT INTO messages VALUES(4,310001,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 310001, "event": "9cd12fbcb360926dfbc6fc57c2e513a149a66fd12092453c2765bc89d725d57e", "quantity": 100000000000}',0);
INSERT INTO messages VALUES(5,310002,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310002, "event": "2efe98f74b6d5963e271457253e6a1748a90992eb0531d60a615d3ccc3986b73", "quantity": 50000000}',0);
INSERT INTO messages VALUES(6,310002,'insert','issuances','{"asset": "NODIVISIBLE", "block_index": 310002, "call_date": 0, "call_price": 0.0, "callable": false, "description": "No divisible asset", "divisible": false, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "2efe98f74b6d5963e271457253e6a1748a90992eb0531d60a615d3ccc3986b73", "tx_index": 3}',0);
INSERT INTO messages VALUES(7,310002,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "NODIVISIBLE", "block_index": 310002, "event": "2efe98f74b6d5963e271457253e6a1748a90992eb0531d60a615d3ccc3986b73", "quantity": 1000}',0);
INSERT INTO messages VALUES(8,310003,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310003, "event": "4361d0ef173c245f3cc5053d5e2513ef9120e5e8abcdcf7c86e164becd53ceeb", "quantity": 50000000}',0);
INSERT INTO messages VALUES(9,310003,'insert','issuances','{"asset": "CALLABLE", "block_index": 310003, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Callable asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "4361d0ef173c245f3cc5053d5e2513ef9120e5e8abcdcf7c86e164becd53ceeb", "tx_index": 4}',0);
INSERT INTO messages VALUES(10,310003,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "CALLABLE", "block_index": 310003, "event": "4361d0ef173c245f3cc5053d5e2513ef9120e5e8abcdcf7c86e164becd53ceeb", "quantity": 1000}',0);
INSERT INTO messages VALUES(11,310004,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310004, "event": "e73d6a9873df9f2264fe2d7f2da66e3a8975bce90d9ec285e79eb47348b41fe1", "quantity": 50000000}',0);
INSERT INTO messages VALUES(12,310004,'insert','issuances','{"asset": "LOCKED", "block_index": 310004, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Locked asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "e73d6a9873df9f2264fe2d7f2da66e3a8975bce90d9ec285e79eb47348b41fe1", "tx_index": 5}',0);
INSERT INTO messages VALUES(13,310004,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "LOCKED", "block_index": 310004, "event": "e73d6a9873df9f2264fe2d7f2da66e3a8975bce90d9ec285e79eb47348b41fe1", "quantity": 1000}',0);
INSERT INTO messages VALUES(14,310005,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310005, "event": "1aa86ffaf6e3bafbd00660ccb794267a9e95814406394d2f1d5dbd6d2ef01579", "quantity": 0}',0);
INSERT INTO messages VALUES(15,310005,'insert','issuances','{"asset": "LOCKED", "block_index": 310005, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Locked asset", "divisible": true, "fee_paid": 0, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": true, "quantity": 0, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "1aa86ffaf6e3bafbd00660ccb794267a9e95814406394d2f1d5dbd6d2ef01579", "tx_index": 6}',0);
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
INSERT INTO messages VALUES(42,310016,'insert','issuances','{"asset": "MAXI", "block_index": 310016, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Maximum quantity", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 9223372036854775807, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "19cf9fd72fd7c1c766589c39cbba55cfd7495047d1773fa46e6b91c16ad85f93", "tx_index": 17}',0);
INSERT INTO messages VALUES(43,310016,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "MAXI", "block_index": 310016, "event": "19cf9fd72fd7c1c766589c39cbba55cfd7495047d1773fa46e6b91c16ad85f93", "quantity": 9223372036854775807}',0);
INSERT INTO messages VALUES(44,310017,'insert','broadcasts','{"block_index": 310017, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "3330c302fd75cb6b9e4d08ccc8821fee8f6f88c8a42123386941193813653c7a", "tx_index": 18, "value": 1.0}',0);
INSERT INTO messages VALUES(45,310018,'insert','broadcasts','{"block_index": 310018, "fee_fraction_int": null, "locked": true, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "text": null, "timestamp": 0, "tx_hash": "a9d599c0f1669b071bf107f7e90f88fe692d56ca00b81e57c71a56530590e7ee", "tx_index": 19, "value": null}',0);
INSERT INTO messages VALUES(46,310019,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310019, "event": "c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d", "quantity": 9}',0);
INSERT INTO messages VALUES(47,310019,'insert','bets','{"bet_type": 1, "block_index": 310019, "counterwager_quantity": 9, "counterwager_remaining": 9, "deadline": 1388000001, "expiration": 100, "expire_index": 310119, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d", "tx_index": 20, "wager_quantity": 9, "wager_remaining": 9}',0);
INSERT INTO messages VALUES(48,310020,'insert','debits','{"action": "bet", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310020, "event": "85c91b9de7c50d74ef9177c748162b99084ca844f3eff48405c2c7918ef78035", "quantity": 9}',0);
INSERT INTO messages VALUES(49,310020,'insert','bets','{"bet_type": 0, "block_index": 310020, "counterwager_quantity": 9, "counterwager_remaining": 9, "deadline": 1388000001, "expiration": 100, "expire_index": 310120, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "target_value": 0.0, "tx_hash": "85c91b9de7c50d74ef9177c748162b99084ca844f3eff48405c2c7918ef78035", "tx_index": 21, "wager_quantity": 9, "wager_remaining": 9}',0);
INSERT INTO messages VALUES(50,310020,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310020, "event": "85c91b9de7c50d74ef9177c748162b99084ca844f3eff48405c2c7918ef78035", "quantity": 0}',0);
INSERT INTO messages VALUES(51,310020,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(52,310020,'insert','credits','{"action": "filled", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310020, "event": "85c91b9de7c50d74ef9177c748162b99084ca844f3eff48405c2c7918ef78035", "quantity": 0}',0);
INSERT INTO messages VALUES(53,310020,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "85c91b9de7c50d74ef9177c748162b99084ca844f3eff48405c2c7918ef78035", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(54,310020,'insert','bet_matches','{"backward_quantity": 9, "block_index": 310020, "deadline": 1388000001, "fee_fraction_int": 5000000, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 9, "id": "c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d_85c91b9de7c50d74ef9177c748162b99084ca844f3eff48405c2c7918ef78035", "initial_value": 1.0, "leverage": 5040, "match_expire_index": 310119, "status": "pending", "target_value": 0.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 1, "tx0_block_index": 310019, "tx0_expiration": 100, "tx0_hash": "c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d", "tx0_index": 20, "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_bet_type": 0, "tx1_block_index": 310020, "tx1_expiration": 100, "tx1_hash": "85c91b9de7c50d74ef9177c748162b99084ca844f3eff48405c2c7918ef78035", "tx1_index": 21}',0);
INSERT INTO messages VALUES(55,310101,'insert','debits','{"action": "bet", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310101, "event": "aac845aa4eb4232be418d70586755f7b132dc33d418da3bc96ced4f79570a305", "quantity": 10}',0);
INSERT INTO messages VALUES(56,310101,'insert','bets','{"bet_type": 3, "block_index": 310101, "counterwager_quantity": 10, "counterwager_remaining": 10, "deadline": 1388000200, "expiration": 1000, "expire_index": 311101, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "target_value": 0.0, "tx_hash": "aac845aa4eb4232be418d70586755f7b132dc33d418da3bc96ced4f79570a305", "tx_index": 102, "wager_quantity": 10, "wager_remaining": 10}',0);
INSERT INTO messages VALUES(57,310102,'insert','broadcasts','{"block_index": 310102, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000002, "tx_hash": "7ea83c28a07116e03bebc36872a631174bf5bab965c7ea676274f7e79fb83410", "tx_index": 103, "value": 1.0}',0);
INSERT INTO messages VALUES(58,310102,'insert','credits','{"action": "bet settled", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 310102, "event": "7ea83c28a07116e03bebc36872a631174bf5bab965c7ea676274f7e79fb83410", "quantity": 9}',0);
INSERT INTO messages VALUES(59,310102,'insert','credits','{"action": "bet settled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310102, "event": "7ea83c28a07116e03bebc36872a631174bf5bab965c7ea676274f7e79fb83410", "quantity": 9}',0);
INSERT INTO messages VALUES(60,310102,'insert','credits','{"action": "feed fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310102, "event": "7ea83c28a07116e03bebc36872a631174bf5bab965c7ea676274f7e79fb83410", "quantity": 0}',0);
INSERT INTO messages VALUES(61,310102,'insert','bet_match_resolutions','{"bear_credit": 9, "bet_match_id": "c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d_85c91b9de7c50d74ef9177c748162b99084ca844f3eff48405c2c7918ef78035", "bet_match_type_id": 1, "block_index": 310102, "bull_credit": 9, "escrow_less_fee": null, "fee": 0, "settled": true, "winner": null}',0);
INSERT INTO messages VALUES(62,310102,'update','bet_matches','{"bet_match_id": "c698148a6da277d898f71fb2efeabf9530af97dd834c698a1a62c85019430e0d_85c91b9de7c50d74ef9177c748162b99084ca844f3eff48405c2c7918ef78035", "status": "settled"}',0);
INSERT INTO messages VALUES(63,310103,'insert','credits','{"action": "burn", "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "asset": "XCP", "block_index": 310103, "event": "65d4048700fb8ae03f321be93c6669b8497f506a1f43920f96d994f43358c35b", "quantity": 92999138821}',0);
INSERT INTO messages VALUES(64,310103,'insert','burns','{"block_index": 310103, "burned": 62000000, "earned": 92999138821, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "tx_hash": "65d4048700fb8ae03f321be93c6669b8497f506a1f43920f96d994f43358c35b", "tx_index": 104}',0);
INSERT INTO messages VALUES(65,310104,'insert','credits','{"action": "burn", "address": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b", "asset": "XCP", "block_index": 310104, "event": "95332a7e3e2b04f2c10e3027327bfc31b686947fb05381e28903e3ff569bd4ff", "quantity": 92999130460}',0);
INSERT INTO messages VALUES(66,310104,'insert','burns','{"block_index": 310104, "burned": 62000000, "earned": 92999130460, "source": "munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b", "status": "valid", "tx_hash": "95332a7e3e2b04f2c10e3027327bfc31b686947fb05381e28903e3ff569bd4ff", "tx_index": 105}',0);
INSERT INTO messages VALUES(67,310105,'insert','credits','{"action": "burn", "address": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "asset": "XCP", "block_index": 310105, "event": "e062d1ebf4cb71bd22d80c949b956f5286080838a7607ccf87945b2b3abfcafa", "quantity": 92999122099}',0);
INSERT INTO messages VALUES(68,310105,'insert','burns','{"block_index": 310105, "burned": 62000000, "earned": 92999122099, "source": "mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42", "status": "valid", "tx_hash": "e062d1ebf4cb71bd22d80c949b956f5286080838a7607ccf87945b2b3abfcafa", "tx_index": 106}',0);
INSERT INTO messages VALUES(69,310106,'insert','credits','{"action": "burn", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "XCP", "block_index": 310106, "event": "93c6d2499a0536c31c77a3db3fc9fc8456fbd0726c45b8f716af16f938727a73", "quantity": 46499556869}',0);
INSERT INTO messages VALUES(70,310106,'insert','burns','{"block_index": 310106, "burned": 31000000, "earned": 46499556869, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "valid", "tx_hash": "93c6d2499a0536c31c77a3db3fc9fc8456fbd0726c45b8f716af16f938727a73", "tx_index": 107}',0);
INSERT INTO messages VALUES(71,310107,'insert','debits','{"action": "issuance fee", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "XCP", "block_index": 310107, "event": "ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e", "quantity": 50000000}',0);
INSERT INTO messages VALUES(72,310107,'insert','issuances','{"asset": "PAYTOSCRIPT", "block_index": 310107, "call_date": 0, "call_price": 0.0, "callable": false, "description": "PSH issued asset", "divisible": false, "fee_paid": 50000000, "issuer": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "locked": false, "quantity": 1000, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "valid", "transfer": false, "tx_hash": "ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e", "tx_index": 108}',0);
INSERT INTO messages VALUES(73,310107,'insert','credits','{"action": "issuance", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "PAYTOSCRIPT", "block_index": 310107, "event": "ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e", "quantity": 1000}',0);
INSERT INTO messages VALUES(74,310108,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 310108, "event": "f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481", "quantity": 100000000}',0);
INSERT INTO messages VALUES(75,310108,'insert','credits','{"action": "send", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "DIVISIBLE", "block_index": 310108, "event": "f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481", "quantity": 100000000}',0);
INSERT INTO messages VALUES(76,310108,'insert','sends','{"asset": "DIVISIBLE", "block_index": 310108, "destination": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481", "tx_index": 109}',0);
INSERT INTO messages VALUES(77,310109,'insert','broadcasts','{"block_index": 310109, "fee_fraction_int": 5000000, "locked": false, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "valid", "text": "Unit Test", "timestamp": 1388000002, "tx_hash": "5b244b5145b725728fb2e5b74fb800d8129b962c4e41f478128fc133f188da6e", "tx_index": 110, "value": 1.0}',0);
INSERT INTO messages VALUES(78,310110,'insert','debits','{"action": "bet", "address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "asset": "XCP", "block_index": 310110, "event": "d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048", "quantity": 10}',0);
INSERT INTO messages VALUES(79,310110,'insert','bets','{"bet_type": 3, "block_index": 310110, "counterwager_quantity": 10, "counterwager_remaining": 10, "deadline": 1388000200, "expiration": 1000, "expire_index": 311110, "fee_fraction_int": 5000000.0, "feed_address": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "leverage": 5040, "source": "2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy", "status": "open", "target_value": 0.0, "tx_hash": "d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048", "tx_index": 111, "wager_quantity": 10, "wager_remaining": 10}',0);
INSERT INTO messages VALUES(80,310486,'insert','broadcasts','{"block_index": 310486, "fee_fraction_int": 5000000, "locked": false, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "096883e142a87377d3a4103f4702556e25824f1e23667aceb1690f66e1417062", "tx_index": 487, "value": 1.0}',0);
INSERT INTO messages VALUES(81,310487,'insert','debits','{"action": "bet", "address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "asset": "XCP", "block_index": 310487, "event": "2447f6974033ac41c40b4598dfb73fc7479fd85bb9d01de2267b3f7842803275", "quantity": 9}',0);
INSERT INTO messages VALUES(82,310487,'insert','bets','{"bet_type": 1, "block_index": 310487, "counterwager_quantity": 9, "counterwager_remaining": 9, "deadline": 1388000001, "expiration": 100, "expire_index": 310587, "fee_fraction_int": 5000000.0, "feed_address": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "leverage": 5040, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "open", "target_value": 0.0, "tx_hash": "2447f6974033ac41c40b4598dfb73fc7479fd85bb9d01de2267b3f7842803275", "tx_index": 488, "wager_quantity": 9, "wager_remaining": 9}',0);
INSERT INTO messages VALUES(83,310488,'insert','broadcasts','{"block_index": 310488, "fee_fraction_int": null, "locked": true, "source": "myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM", "status": "valid", "text": null, "timestamp": 0, "tx_hash": "942e2f89bfd87a4d372e451da5c9118668581533af153b864354869fb88606cc", "tx_index": 489, "value": null}',0);
INSERT INTO messages VALUES(84,310491,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 310491, "event": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09", "quantity": 100000000}',0);
INSERT INTO messages VALUES(85,310491,'insert','orders','{"block_index": 310491, "expiration": 2000, "expire_index": 312491, "fee_provided": 6800, "fee_provided_remaining": 6800, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 800000, "get_remaining": 800000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09", "tx_index": 492}',0);
INSERT INTO messages VALUES(86,310492,'insert','orders','{"block_index": 310492, "expiration": 2000, "expire_index": 312492, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 800000, "give_remaining": 800000, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "tx_hash": "2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4", "tx_index": 493}',0);
INSERT INTO messages VALUES(87,310492,'update','orders','{"fee_provided_remaining": 6800, "fee_required_remaining": 892800, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09"}',0);
INSERT INTO messages VALUES(88,310492,'update','orders','{"fee_provided_remaining": 992800, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4"}',0);
INSERT INTO messages VALUES(89,310492,'insert','order_matches','{"backward_asset": "BTC", "backward_quantity": 800000, "block_index": 310492, "fee_paid": 7200, "forward_asset": "XCP", "forward_quantity": 100000000, "id": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09_2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4", "match_expire_index": 310512, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 310491, "tx0_expiration": 2000, "tx0_hash": "9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09", "tx0_index": 492, "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_block_index": 310492, "tx1_expiration": 2000, "tx1_hash": "2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4", "tx1_index": 493}',0);
INSERT INTO messages VALUES(90,310493,'insert','credits','{"action": "burn", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310493, "event": "c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a", "quantity": 92995878046}',0);
INSERT INTO messages VALUES(91,310493,'insert','burns','{"block_index": 310493, "burned": 62000000, "earned": 92995878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a", "tx_index": 494}',0);
INSERT INTO messages VALUES(92,310494,'insert','debits','{"action": "issuance fee", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310494, "event": "4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5", "quantity": 50000000}',0);
INSERT INTO messages VALUES(93,310494,'insert','issuances','{"asset": "DIVIDEND", "block_index": 310494, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Test dividend", "divisible": true, "fee_paid": 50000000, "issuer": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "locked": false, "quantity": 100, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "transfer": false, "tx_hash": "4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5", "tx_index": 495}',0);
INSERT INTO messages VALUES(94,310494,'insert','credits','{"action": "issuance", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310494, "event": "4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5", "quantity": 100}',0);
INSERT INTO messages VALUES(95,310495,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "DIVIDEND", "block_index": 310495, "event": "129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc", "quantity": 10}',0);
INSERT INTO messages VALUES(96,310495,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "DIVIDEND", "block_index": 310495, "event": "129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc", "quantity": 10}',0);
INSERT INTO messages VALUES(97,310495,'insert','sends','{"asset": "DIVIDEND", "block_index": 310495, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 10, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc", "tx_index": 496}',0);
INSERT INTO messages VALUES(98,310496,'insert','debits','{"action": "send", "address": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "asset": "XCP", "block_index": 310496, "event": "1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(99,310496,'insert','credits','{"action": "send", "address": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "asset": "XCP", "block_index": 310496, "event": "1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6", "quantity": 92945878046}',0);
INSERT INTO messages VALUES(100,310496,'insert','sends','{"asset": "XCP", "block_index": 310496, "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj", "quantity": 92945878046, "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH", "status": "valid", "tx_hash": "1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6", "tx_index": 497}',0);
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
INSERT INTO transactions VALUES(21,'85c91b9de7c50d74ef9177c748162b99084ca844f3eff48405c2c7918ef78035',310020,'d93c79920e4a42164af74ecb5c6b903ff6055cdc007376c74dfa692c8d85ebc9',310020000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,21225,X'00000028000052BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(102,'aac845aa4eb4232be418d70586755f7b132dc33d418da3bc96ced4f79570a305',310101,'369472409995ca1a2ebecbad6bf9dab38c378ab1e67e1bdf13d4ce1346731cd6',310101000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5430,7650,X'00000028000352BB33C8000000000000000A000000000000000A0000000000000000000013B0000003E8',1);
INSERT INTO transactions VALUES(103,'7ea83c28a07116e03bebc36872a631174bf5bab965c7ea676274f7e79fb83410',310102,'11e25883fd0479b78ddb1953ef67e3c3d1ffc82bd1f9e918a75c2194f7137f99',310102000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,20375,X'0000001E52BB33023FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(104,'65d4048700fb8ae03f321be93c6669b8497f506a1f43920f96d994f43358c35b',310103,'559a208afea6dd27b8bfeb031f1bd8f57182dcab6cf55c4089a6c49fb4744f17',310103000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,-99994375,X'',1);
INSERT INTO transactions VALUES(105,'95332a7e3e2b04f2c10e3027327bfc31b686947fb05381e28903e3ff569bd4ff',310104,'55b82e631b61d22a8524981ff3b5e3ab4ad7b732b7d1a06191064334b8f2dfd2',310104000,'munimLLHjPhGeSU5rYB2HN79LJa8bRZr5b','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,-99994375,X'',1);
INSERT INTO transactions VALUES(106,'e062d1ebf4cb71bd22d80c949b956f5286080838a7607ccf87945b2b3abfcafa',310105,'1d72cdf6c4a02a5f973e6eaa53c28e9e13014b4f5bb13f91621a911b27fe936a',310105000,'mwtPsLQxW9xpm7gdLmwWvJK5ABdPUVJm42','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,-99994375,X'',1);
INSERT INTO transactions VALUES(107,'93c6d2499a0536c31c77a3db3fc9fc8456fbd0726c45b8f716af16f938727a73',310106,'9d39cbe8c8a5357fc56e5c2f95bf132382ddad14cbc8abd54e549d58248140ff',310106000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','mvCounterpartyXXXXXXXXXXXXXXW24Hef',31000000,5625,X'',1);
INSERT INTO transactions VALUES(108,'ac74d6a7dcf68a578440851f0148cd4e6ade9416db80fd04c1b9c93e9e53d27e',310107,'51cc04005e49fa49e661946a0e147240b0e5aac174252c96481ab7ddd5487435',310107000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','',0,6800,X'0000001400078A8FE2E5E44100000000000003E8000000000000000000001050534820697373756564206173736574',1);
INSERT INTO transactions VALUES(109,'f0d9e5f8a7d8a13b0d90f126c33843139a50e9d496f6a5ca90e832466e6c6481',310108,'8f2d3861aa42f8e75dc14a23d6046bd89feef0d81996b6e1adc2a2828fbc8b34',310108000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',5430,7650,X'00000000000000A25BE34B660000000005F5E100',1);
INSERT INTO transactions VALUES(110,'5b244b5145b725728fb2e5b74fb800d8129b962c4e41f478128fc133f188da6e',310109,'d23aaaae55e6a912eaaa8d20fe2a9ad4819fe9dc1ed58977265af58fad89d8f9',310109000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','',0,11550,X'0000001E52BB33023FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(111,'d79b590e4ec3e74cbc3eb4d0f956ce7abb0e3af2ccac85ff90ed8acf13f2e048',310110,'cecc8e4791bd3081995bd9fd67acb6b97415facfd2b68f926a70b22d9a258382',310110000,'2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy','2MyJHMUenMWonC35Yi6PHC7i2tkS7PuomCy',5430,7875,X'00000028000352BB33C8000000000000000A000000000000000A0000000000000000000013B0000003E8',1);
INSERT INTO transactions VALUES(487,'096883e142a87377d3a4103f4702556e25824f1e23667aceb1690f66e1417062',310486,'d4fbe610cc60987f2d1d35c7d8ad3ce32156ee5fe36ef8cc4f08b46836388862',310486000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','',0,6800,X'0000001E52BB33003FF0000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(488,'2447f6974033ac41c40b4598dfb73fc7479fd85bb9d01de2267b3f7842803275',310487,'32aa1b132d0643350bbb62dbd5f38ae0c270d8f491a2012c83b99158d58e464f',310487000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM',5430,7650,X'00000028000152BB3301000000000000000900000000000000090000000000000000000013B000000064',1);
INSERT INTO transactions VALUES(489,'942e2f89bfd87a4d372e451da5c9118668581533af153b864354869fb88606cc',310488,'80b8dd5d7ce2e4886e6721095b892a39fb699980fe2bc1c17e747f822f4c4b1b',310488000,'myAtcJEHAsDLbTkai6ipWDZeeL7VkxXsiM','',0,11325,X'0000001E52BB33023FF000000000000000000000046C6F636B',1);
INSERT INTO transactions VALUES(492,'9824ae8e25cedac1ab4f327198f1fb2f79106a281926971bcfa465a490066b09',310491,'811abd7cf2b768cfdaa84ab44c63f4463c96a368ead52125bf149cf0c7447b16',310491000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','',0,6800,X'0000000A00000000000000010000000005F5E100000000000000000000000000000C350007D000000000000DBBA0',1);
INSERT INTO transactions VALUES(493,'2bbbe2bb7716c425c52891010c693b5ed2335d338cf271df0ff34e95dc026de4',310492,'8a09b2faf0a7ad67eb4ab5c948b9769fc87eb2ec5e16108f2cde8bd9e6cf7607',310492000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','',0,1000000,X'0000000A000000000000000000000000000C350000000000000000010000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(494,'c0733e1287afb1bb3d2fdacd1db7c74ea84f14362f3a8d1c038e662e1d0b1b1a',310493,'c19e2915b750279b2be4b52e57e5ce29f63dffb4e14d9aad30c9e820affc0cbf',310493000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,5625,X'',1);
INSERT INTO transactions VALUES(495,'4bbddd2cf3a0fa225f926dcd9d4c2f097c57b7ed24d1ef72e86dd1bf865124b5',310494,'7dda1d3e12785313d5651ee5314d0aecf17588196f9150b10c55695dbaebee5d',310494000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','',0,6800,X'00000014000000063E985FFD0000000000000064010000000000000000000D54657374206469766964656E64',1);
INSERT INTO transactions VALUES(496,'129c05d3d374b75f05557ea2a014a2b93e99672b5f0cf542f9542768a19e20bc',310495,'4769aa7030f28a05a137a85ef4ee0c1765c37013773212b93ec90f1227168b67',310495000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj',5430,7650,X'00000000000000063E985FFD000000000000000A',1);
INSERT INTO transactions VALUES(497,'1410217c3b1b38ea0b90940f20b874a2375c457b0828de9f9808e4fd63fd54e6',310496,'65884816927e8c566655e85c07bc2bc2c7ee26e625742f219939d43238fb31f8',310496000,'mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH','mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj',5430,7650,X'00000000000000000000000100000015A4018C1E',1);
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
INSERT INTO undolog_block VALUES(310498,162);
INSERT INTO undolog_block VALUES(310499,162);
INSERT INTO undolog_block VALUES(310500,162);

-- For primary key autoincrements the next id to use is stored in
-- sqlite_sequence
DELETE FROM main.sqlite_sequence WHERE name='undolog';
INSERT INTO main.sqlite_sequence VALUES ('undolog', 161);

COMMIT TRANSACTION;
