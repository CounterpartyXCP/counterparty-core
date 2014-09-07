-- The values of various per-database settings
-- PRAGMA page_size=1024;
-- PRAGMA encoding='UTF-8';
-- PRAGMA auto_vacuum=NONE;
-- PRAGMA max_page_count=1073741823;

BEGIN TRANSACTION;

-- Table  balances
DROP TABLE IF EXISTS balances;
CREATE TABLE balances(
                      address TEXT,
                      asset TEXT,
                      quantity INTEGER);
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',92250000000);
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',99900000000);
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','NODIVISIBLE',1000);
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','CALLABLE',1000);
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','LOCKED',1000);
INSERT INTO balances VALUES('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','DIVISIBLE',100000000);
INSERT INTO balances VALUES('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000);
-- Triggers and indices on  balances
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

-- Table  bet_match_expirations
DROP TABLE IF EXISTS bet_match_expirations;
CREATE TABLE bet_match_expirations(
                      bet_match_id TEXT PRIMARY KEY,
                      tx0_address TEXT,
                      tx1_address TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (bet_match_id) REFERENCES bet_matches(id),
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index));

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
-- Triggers and indices on  bet_matches
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
-- Triggers and indices on  bets
CREATE INDEX feed_valid_bettype_idx ON bets (feed_address, status, bet_type);

-- Table  blocks
DROP TABLE IF EXISTS blocks;
CREATE TABLE blocks(
                      block_index INTEGER UNIQUE,
                      block_hash TEXT UNIQUE,
                      block_time INTEGER,
                      PRIMARY KEY (block_index, block_hash));
INSERT INTO blocks VALUES(154907,'foobar',1337);
INSERT INTO blocks VALUES(154908,'cab26004a25bf4f3f706d147cc1a6b4ae35d4e2177acbb3a5e1347205fab75cc93c2cfdda0f9e01252776bdaccd4a9dc2cc2e2264af588dbe306734293c1c8c4',1549080000000);
INSERT INTO blocks VALUES(154909,'244e7bf91f9a9cd5ec8c2abd8740a506c2de2156ab635d08d78429afba33f7f090659eca59b3a3f862dd87bb36221e52915512486da5d6ef0ec37e85124a9303',1549090000000);
INSERT INTO blocks VALUES(154910,'80d40ca10e5ea63a2ad8303c70819f369afbbd5716faf875fa4eb8ac2799ee0f9b2e5e204849d8ebca34537bdef7620fe81db66fc8195e193ee778fa43d68cdb',1549100000000);
INSERT INTO blocks VALUES(154911,'c572450879274cc2a7adfa27f3484ba94d76ae3c23d42a92f386000ba36b09790b7448701614b040f3e5dadd6378940e4b47ddb7e6a0da38aadb578b81c178e1',1549110000000);
INSERT INTO blocks VALUES(154912,'b0fe961d25394561c42ea0e5df888ba20580eab3ddb9d294faf901cda2517ebc2078f91137fdf9badefee7950b0274941c7764ecb47546c05e1a3563fc032339',1549120000000);
INSERT INTO blocks VALUES(154913,'797ff8f7e2e601c1595d2bc2088ae7ecd723d53514b74e5545be46389d9ccf31bed1c874b482eee40b06d2d5823969203624a7fd540819262d0033ab08c0887f',1549130000000);
INSERT INTO blocks VALUES(154914,'78cad5b3c7bbac19cbbf5b58f7f2183441d22d200d3b1cb41da63aa293a5393883e3fcfc8eccd9c0ff5ca62b0552c8cd8b5c08e76475003f403c382725194e80',1549140000000);
INSERT INTO blocks VALUES(154915,'fc8ccc098da63edc027cfcb3a6bd5a882e21cc79ec5786f499b1c483779af70d76cd7decf3d4018dcefa678e9566c2b2a2fce14e27a8bb273af4a9af7cf1d932',1549150000000);
INSERT INTO blocks VALUES(154916,'94cd7d76a2cda75e80a2fe48dd3c44d46fed958f6223c9b0ff1a5ebcf255ab0a27df96220f9153fd180048828dcc3afe98c73988f91619f444c91c62a11d881b',1549160000000);
INSERT INTO blocks VALUES(154917,'b8b1961aa5981b069f1e7ce8d7a181736b80b54a5bda33a1bdf4b46f3d0f3dd732bc290cd13e7dab43d12c9efe30723afbe75e82447acd433557548a7568bb1d',1549170000000);
INSERT INTO blocks VALUES(154918,'088546b5563c11520e7fefe3ee0b8bd554b63f935ba0f52ee593300d79ccaba01cef7410df455753f5b4b33326da18e055638a161582c2d6e241ddfe6136e379',1549180000000);
INSERT INTO blocks VALUES(154919,'3dd36d3b00a9000ef4d22e3017f7af48c5c0a9af6e03ecc2a26a49345adef79ac252fd57551a14991e40d128990fbe8776fec55d4826b98e937f92bef3ae0be4',1549190000000);
INSERT INTO blocks VALUES(155398,'4034b4dbbc2505de0738946f4f5fdcbd85bcdb7c897f9ffb9ad15dc14dfa2448ff3442503c3cc1fc3e9bd6eb948d88b1823de5ad67e52cef5bf9997afb9c0e06',1553980000000);
INSERT INTO blocks VALUES(155399,'7dfe13101e809abaabd1ac8f34bc9df934cadc71d453a6fc25f1c02eed76285ccf98ef295f783e32297fa66963c4d4faee8a529f36ccfddca4b96ca1539d2542',1553990000000);
INSERT INTO blocks VALUES(155400,'65e58b28ab92ca1cb301892ff0d04aaf9aa7bfd0323abb91c9c911c4b1c66344204ea9404a5542c87e0b6ddc1a6d842dcd8f0e37ffea9d7f16384eb8be406fa2',1554000000000);
INSERT INTO blocks VALUES(155408,'52bdadd384ac3c5f6d3274a373b5d86cd2f75ae5e376d02bb030a473feb484c8098627b38df85a6c44921b4bcf2c218e506d8ce0699601bcb4cf3bf84f5c0cdd',1554080000000);
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
-- Triggers and indices on  broadcasts
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
INSERT INTO burns VALUES(1,'4bf5122f344554c53bde2ebb8cd2b7e3d1600ad631c385a5d7cce23c7785459a',154908,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',62000000,93000000000,'valid');

-- Table  callbacks
DROP TABLE IF EXISTS callbacks;
CREATE TABLE callbacks(
                      tx_index INTEGER PRIMARY KEY,
                      tx_hash TEXT UNIQUE,
                      block_index INTEGER,
                      source TEXT,
                      fraction TEXT,
                      asset TEXT,
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));

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
CREATE INDEX cancels_block_index_idx ON cancels (block_index);

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
INSERT INTO credits VALUES(154908,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',93000000000,'burn','4bf5122f344554c53bde2ebb8cd2b7e3d1600ad631c385a5d7cce23c7785459a');
INSERT INTO credits VALUES(154909,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000000,'issuance','dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986');
INSERT INTO credits VALUES(154910,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','NODIVISIBLE',1000,'issuance','084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5');
INSERT INTO credits VALUES(154911,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','CALLABLE',1000,'issuance','e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71');
INSERT INTO credits VALUES(154912,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','LOCKED',1000,'issuance','e77b9a9ae9e30b0dbdb6f510a264ef9de781501d7b6b92ae89eb059c5ab743db');
INSERT INTO credits VALUES(154915,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','DIVISIBLE',100000000,'send','beead77994cf573341ec17b58bbf7eb34d2711c993c1d976b128b3188dc1829a');
INSERT INTO credits VALUES(154916,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'send','2b4c342f5433ebe591a1da77e013d1b72475562d48578dca8b84bac6651c3cb9');

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
INSERT INTO debits VALUES(154909,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986');
INSERT INTO debits VALUES(154910,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5');
INSERT INTO debits VALUES(154911,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71');
INSERT INTO debits VALUES(154912,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','e77b9a9ae9e30b0dbdb6f510a264ef9de781501d7b6b92ae89eb059c5ab743db');
INSERT INTO debits VALUES(154913,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','67586e98fad27da0b9968bc039a1ef34c939b9b8e523a8bef89d478608c5ecf6');
INSERT INTO debits VALUES(154914,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','ca358758f6d27e6cf45272937977a748fd88391db679ceda7dc7bf1f005ee879');
INSERT INTO debits VALUES(154915,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','DIVISIBLE',100000000,'send','beead77994cf573341ec17b58bbf7eb34d2711c993c1d976b128b3188dc1829a');
INSERT INTO debits VALUES(154916,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'send','2b4c342f5433ebe591a1da77e013d1b72475562d48578dca8b84bac6651c3cb9');
INSERT INTO debits VALUES(154917,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b');
INSERT INTO debits VALUES(154918,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','e7cf46a078fed4fafd0b5e3aff144802b853f8ae459a4f0c14add3314b7cc3a6');
INSERT INTO debits VALUES(155399,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'open order','fbafd3965322d32c6c8055c0192e5dddedf3ea887d8212bafb07cbd489c1b4b7');
-- Triggers and indices on  debits
CREATE INDEX address_idx ON debits (address);
CREATE INDEX asset_idx ON debits (asset);

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
                      status TEXT,
                      FOREIGN KEY (tx_index, tx_hash, block_index) REFERENCES transactions(tx_index, tx_hash, block_index));

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
INSERT INTO issuances VALUES(2,'dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986',154909,'DIVISIBLE',100000000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Divisible asset',50000000,0,'valid');
INSERT INTO issuances VALUES(3,'084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5',154910,'NODIVISIBLE',1000,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'No divisible asset',50000000,0,'valid');
INSERT INTO issuances VALUES(4,'e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71',154911,'CALLABLE',1000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1,1409400251,100000000.0,'Callable asset',50000000,0,'valid');
INSERT INTO issuances VALUES(5,'e77b9a9ae9e30b0dbdb6f510a264ef9de781501d7b6b92ae89eb059c5ab743db',154912,'LOCKED',1000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Locked asset',50000000,0,'valid');
INSERT INTO issuances VALUES(6,'67586e98fad27da0b9968bc039a1ef34c939b9b8e523a8bef89d478608c5ecf6',154913,'LOCKED',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'Locked asset',50000000,1,'valid');
-- Triggers and indices on  issuances
CREATE INDEX status_idx ON issuances (status);
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
INSERT INTO messages VALUES(0,154908,'insert','credits','{"action": "burn", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154908, "event": "4bf5122f344554c53bde2ebb8cd2b7e3d1600ad631c385a5d7cce23c7785459a", "quantity": 93000000000}',0);
INSERT INTO messages VALUES(1,154908,'insert','burns','{"block_index": 154908, "burned": 62000000, "earned": 93000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "4bf5122f344554c53bde2ebb8cd2b7e3d1600ad631c385a5d7cce23c7785459a", "tx_index": 1}',0);
INSERT INTO messages VALUES(2,154909,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154909, "event": "dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986", "quantity": 50000000}',0);
INSERT INTO messages VALUES(3,154909,'insert','issuances','{"asset": "DIVISIBLE", "block_index": 154909, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Divisible asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986", "tx_index": 2}',0);
INSERT INTO messages VALUES(4,154909,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 154909, "event": "dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986", "quantity": 100000000000}',0);
INSERT INTO messages VALUES(5,154910,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154910, "event": "084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5", "quantity": 50000000}',0);
INSERT INTO messages VALUES(6,154910,'insert','issuances','{"asset": "NODIVISIBLE", "block_index": 154910, "call_date": 0, "call_price": 0.0, "callable": false, "description": "No divisible asset", "divisible": false, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5", "tx_index": 3}',0);
INSERT INTO messages VALUES(7,154910,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "NODIVISIBLE", "block_index": 154910, "event": "084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5", "quantity": 1000}',0);
INSERT INTO messages VALUES(8,154911,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154911, "event": "e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71", "quantity": 50000000}',0);
INSERT INTO messages VALUES(9,154911,'insert','issuances','{"asset": "CALLABLE", "block_index": 154911, "call_date": 1409400251, "call_price": 100000000.0, "callable": true, "description": "Callable asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71", "tx_index": 4}',0);
INSERT INTO messages VALUES(10,154911,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "CALLABLE", "block_index": 154911, "event": "e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71", "quantity": 1000}',0);
INSERT INTO messages VALUES(11,154912,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154912, "event": "e77b9a9ae9e30b0dbdb6f510a264ef9de781501d7b6b92ae89eb059c5ab743db", "quantity": 50000000}',0);
INSERT INTO messages VALUES(12,154912,'insert','issuances','{"asset": "LOCKED", "block_index": 154912, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Locked asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "e77b9a9ae9e30b0dbdb6f510a264ef9de781501d7b6b92ae89eb059c5ab743db", "tx_index": 5}',0);
INSERT INTO messages VALUES(13,154912,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "LOCKED", "block_index": 154912, "event": "e77b9a9ae9e30b0dbdb6f510a264ef9de781501d7b6b92ae89eb059c5ab743db", "quantity": 1000}',0);
INSERT INTO messages VALUES(14,154913,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154913, "event": "67586e98fad27da0b9968bc039a1ef34c939b9b8e523a8bef89d478608c5ecf6", "quantity": 50000000}',0);
INSERT INTO messages VALUES(15,154913,'insert','issuances','{"asset": "LOCKED", "block_index": 154913, "call_date": 0, "call_price": 0.0, "callable": false, "description": "Locked asset", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": true, "quantity": 0, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "67586e98fad27da0b9968bc039a1ef34c939b9b8e523a8bef89d478608c5ecf6", "tx_index": 6}',0);
INSERT INTO messages VALUES(16,154914,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154914, "event": "ca358758f6d27e6cf45272937977a748fd88391db679ceda7dc7bf1f005ee879", "quantity": 100000000}',0);
INSERT INTO messages VALUES(17,154914,'insert','orders','{"block_index": 154914, "expiration": 2000, "expire_index": 156914, "fee_provided": 10000, "fee_provided_remaining": 10000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "DIVISIBLE", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "ca358758f6d27e6cf45272937977a748fd88391db679ceda7dc7bf1f005ee879", "tx_index": 7}',0);
INSERT INTO messages VALUES(18,154915,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "DIVISIBLE", "block_index": 154915, "event": "beead77994cf573341ec17b58bbf7eb34d2711c993c1d976b128b3188dc1829a", "quantity": 100000000}',0);
INSERT INTO messages VALUES(19,154915,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "DIVISIBLE", "block_index": 154915, "event": "beead77994cf573341ec17b58bbf7eb34d2711c993c1d976b128b3188dc1829a", "quantity": 100000000}',0);
INSERT INTO messages VALUES(20,154915,'insert','sends','{"asset": "DIVISIBLE", "block_index": 154915, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "beead77994cf573341ec17b58bbf7eb34d2711c993c1d976b128b3188dc1829a", "tx_index": 8}',0);
INSERT INTO messages VALUES(21,154916,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154916, "event": "2b4c342f5433ebe591a1da77e013d1b72475562d48578dca8b84bac6651c3cb9", "quantity": 100000000}',0);
INSERT INTO messages VALUES(22,154916,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 154916, "event": "2b4c342f5433ebe591a1da77e013d1b72475562d48578dca8b84bac6651c3cb9", "quantity": 100000000}',0);
INSERT INTO messages VALUES(23,154916,'insert','sends','{"asset": "XCP", "block_index": 154916, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "2b4c342f5433ebe591a1da77e013d1b72475562d48578dca8b84bac6651c3cb9", "tx_index": 9}',0);
INSERT INTO messages VALUES(24,154917,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154917, "event": "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b", "quantity": 100000000}',0);
INSERT INTO messages VALUES(25,154917,'insert','orders','{"block_index": 154917, "expiration": 2000, "expire_index": 156917, "fee_provided": 10000, "fee_provided_remaining": 10000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "DIVISIBLE", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b", "tx_index": 10}',0);
INSERT INTO messages VALUES(26,154918,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154918, "event": "e7cf46a078fed4fafd0b5e3aff144802b853f8ae459a4f0c14add3314b7cc3a6", "quantity": 100000000}',0);
INSERT INTO messages VALUES(27,154918,'insert','orders','{"block_index": 154918, "expiration": 2000, "expire_index": 156918, "fee_provided": 10000, "fee_provided_remaining": 10000, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 1000000, "get_remaining": 1000000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "e7cf46a078fed4fafd0b5e3aff144802b853f8ae459a4f0c14add3314b7cc3a6", "tx_index": 11}',0);
INSERT INTO messages VALUES(28,154919,'insert','orders','{"block_index": 154919, "expiration": 2000, "expire_index": 156919, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 666667, "give_remaining": 666667, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "ef6cbd2161eaea7943ce8693b9824d23d1793ffb1c0fca05b600d3899b44c977", "tx_index": 12}',0);
INSERT INTO messages VALUES(29,155399,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 155399, "event": "fbafd3965322d32c6c8055c0192e5dddedf3ea887d8212bafb07cbd489c1b4b7", "quantity": 100000000}',0);
INSERT INTO messages VALUES(30,155399,'insert','orders','{"block_index": 155399, "expiration": 2000, "expire_index": 157399, "fee_provided": 10000, "fee_provided_remaining": 10000, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 800000, "get_remaining": 800000, "give_asset": "XCP", "give_quantity": 100000000, "give_remaining": 100000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "fbafd3965322d32c6c8055c0192e5dddedf3ea887d8212bafb07cbd489c1b4b7", "tx_index": 492}',0);
INSERT INTO messages VALUES(31,155400,'insert','orders','{"block_index": 155400, "expiration": 2000, "expire_index": 157400, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 800000, "give_remaining": 800000, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "tx_hash": "3a68747f72148c3100bd310bf24b2bfe95b43553d232b37c5511757399f0c208", "tx_index": 493}',0);
INSERT INTO messages VALUES(32,155400,'update','orders','{"fee_provided_remaining": 10000, "fee_required_remaining": 892800, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "fbafd3965322d32c6c8055c0192e5dddedf3ea887d8212bafb07cbd489c1b4b7"}',0);
INSERT INTO messages VALUES(33,155400,'update','orders','{"fee_provided_remaining": 992800, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "3a68747f72148c3100bd310bf24b2bfe95b43553d232b37c5511757399f0c208"}',0);
INSERT INTO messages VALUES(34,155400,'insert','order_matches','{"backward_asset": "BTC", "backward_quantity": 800000, "block_index": 155400, "fee_paid": 7200, "forward_asset": "XCP", "forward_quantity": 100000000, "id": "fbafd3965322d32c6c8055c0192e5dddedf3ea887d8212bafb07cbd489c1b4b73a68747f72148c3100bd310bf24b2bfe95b43553d232b37c5511757399f0c208", "match_expire_index": 155420, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 155399, "tx0_expiration": 2000, "tx0_hash": "fbafd3965322d32c6c8055c0192e5dddedf3ea887d8212bafb07cbd489c1b4b7", "tx0_index": 492, "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_block_index": 155400, "tx1_expiration": 2000, "tx1_hash": "3a68747f72148c3100bd310bf24b2bfe95b43553d232b37c5511757399f0c208", "tx1_index": 493}',0);
-- Triggers and indices on  messages
CREATE INDEX block_index_message_index_idx ON messages (block_index, message_index);

-- Table  order_expirations
DROP TABLE IF EXISTS order_expirations;
CREATE TABLE order_expirations(
                      order_index INTEGER PRIMARY KEY,
                      order_hash TEXT UNIQUE,
                      source TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index),
                      FOREIGN KEY (order_index, order_hash) REFERENCES orders(tx_index, tx_hash));

-- Table  order_match_expirations
DROP TABLE IF EXISTS order_match_expirations;
CREATE TABLE order_match_expirations(
                      order_match_id TEXT PRIMARY KEY,
                      tx0_address TEXT,
                      tx1_address TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (order_match_id) REFERENCES order_matches(id),
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index));

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
INSERT INTO order_matches VALUES('fbafd3965322d32c6c8055c0192e5dddedf3ea887d8212bafb07cbd489c1b4b73a68747f72148c3100bd310bf24b2bfe95b43553d232b37c5511757399f0c208',492,'fbafd3965322d32c6c8055c0192e5dddedf3ea887d8212bafb07cbd489c1b4b7','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',493,'3a68747f72148c3100bd310bf24b2bfe95b43553d232b37c5511757399f0c208','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'BTC',800000,155399,155400,155400,2000,2000,155420,7200,'pending');
-- Triggers and indices on  order_matches
CREATE INDEX backward_status_idx ON order_matches (backward_asset, status);
CREATE INDEX forward_status_idx ON order_matches (forward_asset, status);
CREATE INDEX id_idx ON order_matches (id);
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
INSERT INTO orders VALUES(7,'ca358758f6d27e6cf45272937977a748fd88391db679ceda7dc7bf1f005ee879',154914,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,100000000,'DIVISIBLE',100000000,100000000,2000,156914,0,0,10000,10000,'open');
INSERT INTO orders VALUES(10,'01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b',154917,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,100000000,'DIVISIBLE',100000000,100000000,2000,156917,0,0,10000,10000,'open');
INSERT INTO orders VALUES(11,'e7cf46a078fed4fafd0b5e3aff144802b853f8ae459a4f0c14add3314b7cc3a6',154918,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,100000000,'BTC',1000000,1000000,2000,156918,900000,900000,10000,10000,'open');
INSERT INTO orders VALUES(12,'ef6cbd2161eaea7943ce8693b9824d23d1793ffb1c0fca05b600d3899b44c977',154919,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BTC',666667,666667,'XCP',100000000,100000000,2000,156919,0,0,1000000,1000000,'open');
INSERT INTO orders VALUES(492,'fbafd3965322d32c6c8055c0192e5dddedf3ea887d8212bafb07cbd489c1b4b7',155399,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,0,'BTC',800000,0,2000,157399,900000,892800,10000,10000,'open');
INSERT INTO orders VALUES(493,'3a68747f72148c3100bd310bf24b2bfe95b43553d232b37c5511757399f0c208',155400,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BTC',800000,0,'XCP',100000000,0,2000,157400,0,0,1000000,992800,'open');
-- Triggers and indices on  orders
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

-- Table  rps_match_expirations
DROP TABLE IF EXISTS rps_match_expirations;
CREATE TABLE rps_match_expirations(
                      rps_match_id TEXT PRIMARY KEY,
                      tx0_address TEXT,
                      tx1_address TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (rps_match_id) REFERENCES rps_matches(id),
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index));

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
INSERT INTO sends VALUES(8,'beead77994cf573341ec17b58bbf7eb34d2711c993c1d976b128b3188dc1829a',154915,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','DIVISIBLE',100000000,'valid');
INSERT INTO sends VALUES(9,'2b4c342f5433ebe591a1da77e013d1b72475562d48578dca8b84bac6651c3cb9',154916,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',100000000,'valid');
-- Triggers and indices on  sends
CREATE INDEX destination_idx ON sends (destination);
CREATE INDEX source_idx ON sends (source);

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
INSERT INTO transactions VALUES(1,'4bf5122f344554c53bde2ebb8cd2b7e3d1600ad631c385a5d7cce23c7785459a',154908,'cab26004a25bf4f3f706d147cc1a6b4ae35d4e2177acbb3a5e1347205fab75cc93c2cfdda0f9e01252776bdaccd4a9dc2cc2e2264af588dbe306734293c1c8c4',1549080000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mvCounterpartyXXXXXXXXXXXXXXW24Hef',62000000,10000,X'',1);
INSERT INTO transactions VALUES(2,'dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986',154909,'244e7bf91f9a9cd5ec8c2abd8740a506c2de2156ab635d08d78429afba33f7f090659eca59b3a3f862dd87bb36221e52915512486da5d6ef0ec37e85124a9303',1549090000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'00000014000000A25BE34B66000000174876E800010000000000000000000F446976697369626C65206173736574',1);
INSERT INTO transactions VALUES(3,'084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5',154910,'80d40ca10e5ea63a2ad8303c70819f369afbbd5716faf875fa4eb8ac2799ee0f9b2e5e204849d8ebca34537bdef7620fe81db66fc8195e193ee778fa43d68cdb',1549100000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'000000140006CAD8DC7F0B6600000000000003E800000000000000000000124E6F20646976697369626C65206173736574',1);
INSERT INTO transactions VALUES(4,'e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71',154911,'c572450879274cc2a7adfa27f3484ba94d76ae3c23d42a92f386000ba36b09790b7448701614b040f3e5dadd6378940e4b47ddb7e6a0da38aadb578b81c178e1',1549110000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000001400000003C58E5C5600000000000003E801015401BDBB4CBEBC200E43616C6C61626C65206173736574',1);
INSERT INTO transactions VALUES(5,'e77b9a9ae9e30b0dbdb6f510a264ef9de781501d7b6b92ae89eb059c5ab743db',154912,'b0fe961d25394561c42ea0e5df888ba20580eab3ddb9d294faf901cda2517ebc2078f91137fdf9badefee7950b0274941c7764ecb47546c05e1a3563fc032339',1549120000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000001400000000082C82E300000000000003E8010000000000000000000C4C6F636B6564206173736574',1);
INSERT INTO transactions VALUES(6,'67586e98fad27da0b9968bc039a1ef34c939b9b8e523a8bef89d478608c5ecf6',154913,'797ff8f7e2e601c1595d2bc2088ae7ecd723d53514b74e5545be46389d9ccf31bed1c874b482eee40b06d2d5823969203624a7fd540819262d0033ab08c0887f',1549130000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000001400000000082C82E3000000000000000001000000000000000000044C4F434B',1);
INSERT INTO transactions VALUES(7,'ca358758f6d27e6cf45272937977a748fd88391db679ceda7dc7bf1f005ee879',154914,'78cad5b3c7bbac19cbbf5b58f7f2183441d22d200d3b1cb41da63aa293a5393883e3fcfc8eccd9c0ff5ca62b0552c8cd8b5c08e76475003f403c382725194e80',1549140000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000000A00000000000000010000000005F5E100000000A25BE34B660000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(8,'beead77994cf573341ec17b58bbf7eb34d2711c993c1d976b128b3188dc1829a',154915,'fc8ccc098da63edc027cfcb3a6bd5a882e21cc79ec5786f499b1c483779af70d76cd7decf3d4018dcefa678e9566c2b2a2fce14e27a8bb273af4a9af7cf1d932',1549150000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',7800,10000,X'00000000000000A25BE34B660000000005F5E100',1);
INSERT INTO transactions VALUES(9,'2b4c342f5433ebe591a1da77e013d1b72475562d48578dca8b84bac6651c3cb9',154916,'94cd7d76a2cda75e80a2fe48dd3c44d46fed958f6223c9b0ff1a5ebcf255ab0a27df96220f9153fd180048828dcc3afe98c73988f91619f444c91c62a11d881b',1549160000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',7800,10000,X'0000000000000000000000010000000005F5E100',1);
INSERT INTO transactions VALUES(10,'01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b',154917,'b8b1961aa5981b069f1e7ce8d7a181736b80b54a5bda33a1bdf4b46f3d0f3dd732bc290cd13e7dab43d12c9efe30723afbe75e82447acd433557548a7568bb1d',1549170000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000000A00000000000000010000000005F5E100000000A25BE34B660000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(11,'e7cf46a078fed4fafd0b5e3aff144802b853f8ae459a4f0c14add3314b7cc3a6',154918,'088546b5563c11520e7fefe3ee0b8bd554b63f935ba0f52ee593300d79ccaba01cef7410df455753f5b4b33326da18e055638a161582c2d6e241ddfe6136e379',1549180000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000000A00000000000000010000000005F5E100000000000000000000000000000F424007D000000000000DBBA0',1);
INSERT INTO transactions VALUES(12,'ef6cbd2161eaea7943ce8693b9824d23d1793ffb1c0fca05b600d3899b44c977',154919,'3dd36d3b00a9000ef4d22e3017f7af48c5c0a9af6e03ecc2a26a49345adef79ac252fd57551a14991e40d128990fbe8776fec55d4826b98e937f92bef3ae0be4',1549190000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,1000000,X'0000000A000000000000000000000000000A2C2B00000000000000010000000005F5E10007D00000000000000000',1);
INSERT INTO transactions VALUES(492,'fbafd3965322d32c6c8055c0192e5dddedf3ea887d8212bafb07cbd489c1b4b7',155399,'7dfe13101e809abaabd1ac8f34bc9df934cadc71d453a6fc25f1c02eed76285ccf98ef295f783e32297fa66963c4d4faee8a529f36ccfddca4b96ca1539d2542',1553990000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000000A00000000000000010000000005F5E100000000000000000000000000000C350007D000000000000DBBA0',1);
INSERT INTO transactions VALUES(493,'3a68747f72148c3100bd310bf24b2bfe95b43553d232b37c5511757399f0c208',155400,'65e58b28ab92ca1cb301892ff0d04aaf9aa7bfd0323abb91c9c911c4b1c66344204ea9404a5542c87e0b6ddc1a6d842dcd8f0e37ffea9d7f16384eb8be406fa2',1554000000000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',NULL,NULL,1000000,X'0000000A000000000000000000000000000C350000000000000000010000000005F5E10007D00000000000000000',1);
-- Triggers and indices on  transactions
CREATE INDEX index_hash_index_idx ON transactions (tx_index, tx_hash, block_index);
CREATE INDEX index_index_idx ON transactions (block_index, tx_index);
CREATE INDEX tx_hash_idx ON transactions (tx_hash);
CREATE INDEX tx_index_idx ON transactions (tx_index);

COMMIT TRANSACTION;
