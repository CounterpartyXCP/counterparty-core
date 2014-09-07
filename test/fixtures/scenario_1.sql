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
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',145136014292);
INSERT INTO balances VALUES('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',4763877496);
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',996000000);
INSERT INTO balances VALUES('mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC',92631);
INSERT INTO balances VALUES('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBB',4000000);
INSERT INTO balances VALUES('mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',7369);
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
INSERT INTO bet_expirations VALUES(13,'9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c4','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',154931);

-- Table  bet_match_expirations
DROP TABLE IF EXISTS bet_match_expirations;
CREATE TABLE bet_match_expirations(
                      bet_match_id TEXT PRIMARY KEY,
                      tx0_address TEXT,
                      tx1_address TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (bet_match_id) REFERENCES bet_matches(id),
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index));
INSERT INTO bet_match_expirations VALUES('9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c44d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',154922);
INSERT INTO bet_match_expirations VALUES('dc0e9c3658a1a3ed1ec94274d8b19925c93e1abb7ddba294923ad9bde30f8cb8c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',154924);
INSERT INTO bet_match_expirations VALUES('4a64a107f0cb32536e5bce6c98c393db21cca7f4ea187ba8c4dca8b51d4ea80af299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',154926);

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
INSERT INTO bet_matches VALUES('9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c44d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47',13,'9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c4','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',14,'4d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',100,1388000100,0.0,15120,41500000,20750000,154920,154921,154921,10,10,154930,5000000,'expired');
INSERT INTO bet_matches VALUES('dc0e9c3658a1a3ed1ec94274d8b19925c93e1abb7ddba294923ad9bde30f8cb8c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3',15,'dc0e9c3658a1a3ed1ec94274d8b19925c93e1abb7ddba294923ad9bde30f8cb8','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',16,'c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',100,1388000100,0.0,5040,150000000,350000000,154922,154923,154923,10,10,154932,5000000,'expired');
INSERT INTO bet_matches VALUES('4a64a107f0cb32536e5bce6c98c393db21cca7f4ea187ba8c4dca8b51d4ea80af299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c',17,'4a64a107f0cb32536e5bce6c98c393db21cca7f4ea187ba8c4dca8b51d4ea80a','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',18,'f299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',2,3,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',100,1388000200,1.0,5040,750000000,650000000,154924,154925,154925,10,10,154934,5000000,'expired');
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
INSERT INTO bets VALUES(13,'9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c4',154920,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1388000100,50000000,8500000,25000000,4250000,0.0,15120,10,154930,5000000,'expired');
INSERT INTO bets VALUES(14,'4d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47',154921,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000100,25000000,4250000,41500000,0,0.0,15120,10,154931,5000000,'filled');
INSERT INTO bets VALUES(15,'dc0e9c3658a1a3ed1ec94274d8b19925c93e1abb7ddba294923ad9bde30f8cb8',154922,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1388000100,150000000,0,350000000,0,0.0,5040,10,154932,5000000,'filled');
INSERT INTO bets VALUES(16,'c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3',154923,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1,1388000100,350000000,0,150000000,0,0.0,5040,10,154933,5000000,'filled');
INSERT INTO bets VALUES(17,'4a64a107f0cb32536e5bce6c98c393db21cca7f4ea187ba8c4dca8b51d4ea80a',154924,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',2,1388000200,750000000,0,650000000,0,1.0,5040,10,154934,5000000,'filled');
INSERT INTO bets VALUES(18,'f299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c',154925,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',3,1388000200,650000000,0,750000000,0,1.0,5040,10,154935,5000000,'filled');
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
INSERT INTO blocks VALUES(154920,'0fca8dfde3b5b34b0829e1daa9a5c7f235a93d74fd3575d68f7a131c7790e01eb69fd3e0aaa9d872c8dad6d8e57e49b3a5903d774372ed5524dac8afc51c18d2',1549200000000);
INSERT INTO blocks VALUES(154921,'1a99275c7a70a496ce9fcd5cf21876916351805fdc5258dbaa004ff9ea8e451be93cc6f872819dd8942847c650afd37618bbb630528d772b4f8eb318122b1043',1549210000000);
INSERT INTO blocks VALUES(154922,'3e7b51e4121b3f70fa8ac6b3c2e3c29a985e05c5ad92678ee3982e931d81891a876260f7f53108a6e6d9012211a4f43cbc038b91dee92d2d1466448cec4979c4',1549220000000);
INSERT INTO blocks VALUES(154923,'9b16d5d768bbfd1c83ca224c2fd704429a16b6102dc1ccc21eec6547da4dad23bfa3f0df63b0a0c1159268008765227db81aac243e48f470594c3f8e30a2772b',1549230000000);
INSERT INTO blocks VALUES(154924,'915916edf01452e1a554d7dd7c63acef01f9540006a5b09425d151a8a170bd23e0500bd89dc97b8e49f22a0e662d140f03bcd6d2d9faf2b35e6968cd076329d3',1549240000000);
INSERT INTO blocks VALUES(154925,'29d88d169c0c9bb778dd32b9d76fdef07d4cdd5302f02938101e03dd616426884b0e08816cfd7b217662f226003e3821f8e09063dd5250331a3e187557619386',1549250000000);
INSERT INTO blocks VALUES(154926,'aeff66363337363dce240dd090e1d507f934b2496f82fce7094b6499b657f6375fb541747538a0001da7e87f708e10068399ef20441ba49485bc4edaa2347c85',1549260000000);
INSERT INTO blocks VALUES(154927,'bc5cd4a70a0e3038768b0b4dacc11bb5bdbbaa51a7a6d0a69aaed9ab49451f57aa1f702921cf8fd5e477c4f06353f7ae69c5ce347a1307c38edcb9619ba9709f',1549270000000);
INSERT INTO blocks VALUES(154928,'f5b79d98c8c45e396851d32aaeb4730f0ffe2db82e36a6f8ba6b139a5a4fc6ec7e0e7a4c304f12a3b8ff41ab648a2d4b17689b7ea4c037b12a62a03988bee963',1549280000000);
INSERT INTO blocks VALUES(154929,'7068c1abc38664730e4b979aa4d3beb7131c65e36cf7aaa2852bbe3a0b74783eaa0c7a7ed52ec04b5d6865faaceb23b41390ec93f667cffe8ba9cec6757bbba9',1549290000000);
INSERT INTO blocks VALUES(154930,'2b7fef6e9069f1a2f44e6eb08f0f5e32033d0048fc3cfc526237a4c4ced59590dbacfa4bfe95b894bc21658cffb2908b85280e6cfaa1545970bf2a724ceeea5b',1549300000000);
INSERT INTO blocks VALUES(154931,'efd744787f5fa988aa515f4a7d14323969ab838c70a3d6d3a029ddf6eac7dd74568b09659b7756eafc7b6e410d8e5f5ba921d9a454c97f6c6b72ca7da37b5c58',1549310000000);
INSERT INTO blocks VALUES(154932,'09614b8f64a6aacc740150eab0bbe7aaef9045825e188800d44f8a5620afd0cc71f8a354b2d061b8cf2be47434963ee9709103d46151d9c18f80366b61d33eda',1549320000000);
INSERT INTO blocks VALUES(154933,'d08f4dd0524762d7ebb5939e2b73f98c2260c8f2314a93b468e983e13a96639477f2effcfe51395687508cf6f0cb2de65e818396e9b3adb4a499f3d8cb16a638',1549330000000);
INSERT INTO blocks VALUES(154934,'a519de47aa8c7eafe6fc8a4df5f5f05ea4bd27e41ea67d83555417146a35bbab2529ceff400f46163eb539a2c846bd8b8ee9cc87aefcce7b17054decb392a5ea',1549340000000);
INSERT INTO blocks VALUES(154935,'bb8f4a793ea7c9ecab809a8c210ec05858a8241939ee6d12e283e2ad119ee87ca2078f81a3c295bb527766dc2713b90793ab8a518db9fb4f2967e43f245ee0fb',1549350000000);
INSERT INTO blocks VALUES(154936,'3af58b36490131f828a765f13708b818c0a4b7082f2e0ac7d8cccdba7cd77fef40b07f115e453279ae7e9cd47f01ccdf9a23702634ab9793be5533d67c348735',1549360000000);
INSERT INTO blocks VALUES(154937,'0e82b767d5eef083b2547f3765bc77838ec407b1538acf5a0eb2f153665b65d9b499e7e716db7daefdb8852a411342a9d2ebfe2f4f93e9bb09d5a9ef03cb7cf4',1549370000000);
INSERT INTO blocks VALUES(154954,'c4cda98aab9f7965c540711d7018d648eaa2b5c71f1158ad0ec2505bc2be29da4044359967570ada171e94a7f44fe239185e5b565e97e6eb087295945aab6aae',1549540000000);
INSERT INTO blocks VALUES(154955,'04b4498e214f976cc2daa71ef3d694ed283d98d5153f51dab0fd6ae3ffcc10bca28423b6f437723d7d366d71e8583cf444332cd82ffe30d801e17c1d9e5616a9',1549550000000);
INSERT INTO blocks VALUES(154956,'84847d413464cf667c6a0c701219c3d74c89c5397b7c05b8e0605e719db735d2d5631d34c78be6d33e3d3e8dfee5f408cbd8589f6ebc3467363b5cd5e0c976f2',1549560000000);
INSERT INTO blocks VALUES(154981,'7d32dc11080249c8ab974a72ff0fc4742ca8703c53b44c7692f185ff34d1e32a0512cd79b0107f990c43d6ae770511ee27fb78c4d03bec1833eee11b259bba8d',1549810000000);
INSERT INTO blocks VALUES(154982,'766110ba2b50a1c0b743164d74871882e6b4a5fbb5082a4c37ab4e04cfa8aa8eaa710ba9f7668ba0141eb9e585586c385a0f17dc1c2cf55f50397ffc18717a2b',1549820000000);
INSERT INTO blocks VALUES(154983,'2d0c386a1fad12d0b44815b00f9ac4e4f518f334b620920197591cf9f27ff89e7f48ae831ebe91664402088ecb5ef4e751964dfa52c424c17666f55ef997a7e7',1549830000000);
INSERT INTO blocks VALUES(154984,'c2b0c5ebf63c897a6d6f11f0ed2891ac1ed874de7f4ef481e26f26af44e5bef76907b5b672be3b4b1ef094c058931631e8c48ade989638d56ced718b81c10ec4',1549840000000);
INSERT INTO blocks VALUES(155009,'2ebbf8f2c689c039ea06b66af96a498dec9c7ccc21ed3c2615364dc86d83f619933e07198d7f6deedf2c1e9dddca4310de0d98ff68ebdf03182bf33ca58ab6e4',1550090000000);
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
INSERT INTO broadcasts VALUES(12,'ef6cbd2161eaea7943ce8693b9824d23d1793ffb1c0fca05b600d3899b44c977',154919,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000000,100.0,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(19,'ab897fbdedfa502b2d839b6a56100887dccdc507555c282e59589e06300a62e2',154926,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000050,99.86166,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(20,'83891d7fe85c33e52c8b4e5814c92fb6a3b9467299200538a6babaa8b452d879',154927,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000101,100.343,5000000,'Unit Test',0,'valid');
INSERT INTO broadcasts VALUES(21,'2f0fd1e89b8de1d57292742ec380ea47066e307ad645f5bc3adad8a06ff58608',154928,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',1388000201,2.0,5000000,'Unit Test',0,'valid');
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
INSERT INTO btcpays VALUES(5,'e77b9a9ae9e30b0dbdb6f510a264ef9de781501d7b6b92ae89eb059c5ab743db',154912,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',50000000,'084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71','valid');

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
INSERT INTO burns VALUES(23,'8f11b05da785e43e713d03774c6bd3405d99cd3024af334ffd68db663aa37034',154930,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',38000000,56999891788,'valid');

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
INSERT INTO callbacks VALUES(25,'68aa2e2ee5dff96e3355e6c7ee373e3d6a4e17f75f9518d843709c0c9bc3e3d4',154932,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','0.3','BBBC','valid');

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
INSERT INTO credits VALUES(154909,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',50000000,'send','dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986');
INSERT INTO credits VALUES(154912,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',100000000,'btcpay','e77b9a9ae9e30b0dbdb6f510a264ef9de781501d7b6b92ae89eb059c5ab743db');
INSERT INTO credits VALUES(154913,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',1000000000,'issuance','67586e98fad27da0b9968bc039a1ef34c939b9b8e523a8bef89d478608c5ecf6');
INSERT INTO credits VALUES(154914,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC',100000,'issuance','ca358758f6d27e6cf45272937977a748fd88391db679ceda7dc7bf1f005ee879');
INSERT INTO credits VALUES(154915,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBB',4000000,'send','beead77994cf573341ec17b58bbf7eb34d2711c993c1d976b128b3188dc1829a');
INSERT INTO credits VALUES(154916,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',526,'send','2b4c342f5433ebe591a1da77e013d1b72475562d48578dca8b84bac6651c3cb9');
INSERT INTO credits VALUES(154917,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',24,'dividend','01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b');
INSERT INTO credits VALUES(154918,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',420800,'dividend','e7cf46a078fed4fafd0b5e3aff144802b853f8ae459a4f0c14add3314b7cc3a6');
INSERT INTO credits VALUES(154921,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',4250000,'filled','4d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47');
INSERT INTO credits VALUES(154922,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',5000000,'cancel order','e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71');
INSERT INTO credits VALUES(154922,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',41500000,'recredit forward quantity','9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c44d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47');
INSERT INTO credits VALUES(154922,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',20750000,'recredit backward quantity','9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c44d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47');
INSERT INTO credits VALUES(154923,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3');
INSERT INTO credits VALUES(154923,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3');
INSERT INTO credits VALUES(154924,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',150000000,'recredit forward quantity','dc0e9c3658a1a3ed1ec94274d8b19925c93e1abb7ddba294923ad9bde30f8cb8c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3');
INSERT INTO credits VALUES(154924,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',350000000,'recredit backward quantity','dc0e9c3658a1a3ed1ec94274d8b19925c93e1abb7ddba294923ad9bde30f8cb8c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3');
INSERT INTO credits VALUES(154925,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','f299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c');
INSERT INTO credits VALUES(154925,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',0,'filled','f299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c');
INSERT INTO credits VALUES(154926,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',750000000,'recredit forward quantity','4a64a107f0cb32536e5bce6c98c393db21cca7f4ea187ba8c4dca8b51d4ea80af299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c');
INSERT INTO credits VALUES(154926,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',650000000,'recredit backward quantity','4a64a107f0cb32536e5bce6c98c393db21cca7f4ea187ba8c4dca8b51d4ea80af299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c');
INSERT INTO credits VALUES(154930,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',56999891788,'burn','8f11b05da785e43e713d03774c6bd3405d99cd3024af334ffd68db663aa37034');
INSERT INTO credits VALUES(154931,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',8500000,'recredit wager remaining','9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c4');
INSERT INTO credits VALUES(154931,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',10000,'send','452ba1ddef80246c48be7690193c76c1d61185906be9401014fe14f1be64b74f');
INSERT INTO credits VALUES(154932,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC',3157,'callback','68aa2e2ee5dff96e3355e6c7ee373e3d6a4e17f75f9518d843709c0c9bc3e3d4');
INSERT INTO credits VALUES(154932,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',4735500000,'callback','68aa2e2ee5dff96e3355e6c7ee373e3d6a4e17f75f9518d843709c0c9bc3e3d4');
INSERT INTO credits VALUES(154936,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',22043326,'wins','58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd');
INSERT INTO credits VALUES(154954,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',50000000,'cancel order','7cb7c4547cf2653590d7a9ace60cc623d25148adfbc88a89aeb0ef88da7839ba');
INSERT INTO credits VALUES(154954,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',11021663,'recredit wager','9652595f37edd08c51dfa26567e6cd76e6fa2709c3e578478ca398d316837a7a');
INSERT INTO credits VALUES(154981,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',11021664,'recredit wager','5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e96b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b');
INSERT INTO credits VALUES(154981,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',11021664,'recredit wager','5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e96b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b');
INSERT INTO credits VALUES(155009,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',22043330,'wins','86be9a55762d316a3026c2836d044f5fc76e34da10e1b45feee5f18be7edb17772dfcfb0c470ac255cde83fb8fe38de8a128188e03ea5ba5b2a93adbea1062fa');

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
INSERT INTO debits VALUES(154909,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'send','dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986');
INSERT INTO debits VALUES(154911,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',105000000,'open order','e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71');
INSERT INTO debits VALUES(154913,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','67586e98fad27da0b9968bc039a1ef34c939b9b8e523a8bef89d478608c5ecf6');
INSERT INTO debits VALUES(154914,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'issuance fee','ca358758f6d27e6cf45272937977a748fd88391db679ceda7dc7bf1f005ee879');
INSERT INTO debits VALUES(154915,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',4000000,'send','beead77994cf573341ec17b58bbf7eb34d2711c993c1d976b128b3188dc1829a');
INSERT INTO debits VALUES(154916,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC',526,'send','2b4c342f5433ebe591a1da77e013d1b72475562d48578dca8b84bac6651c3cb9');
INSERT INTO debits VALUES(154917,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',24,'dividend','01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b');
INSERT INTO debits VALUES(154918,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',420800,'dividend','e7cf46a078fed4fafd0b5e3aff144802b853f8ae459a4f0c14add3314b7cc3a6');
INSERT INTO debits VALUES(154920,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',50000000,'bet','9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c4');
INSERT INTO debits VALUES(154921,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',25000000,'bet','4d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47');
INSERT INTO debits VALUES(154922,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',150000000,'bet','dc0e9c3658a1a3ed1ec94274d8b19925c93e1abb7ddba294923ad9bde30f8cb8');
INSERT INTO debits VALUES(154923,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',350000000,'bet','c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3');
INSERT INTO debits VALUES(154924,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',750000000,'bet','4a64a107f0cb32536e5bce6c98c393db21cca7f4ea187ba8c4dca8b51d4ea80a');
INSERT INTO debits VALUES(154925,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',650000000,'bet','f299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c');
INSERT INTO debits VALUES(154929,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',50000000,'open order','7cb7c4547cf2653590d7a9ace60cc623d25148adfbc88a89aeb0ef88da7839ba');
INSERT INTO debits VALUES(154931,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC',10000,'send','452ba1ddef80246c48be7690193c76c1d61185906be9401014fe14f1be64b74f');
INSERT INTO debits VALUES(154932,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',4735500000,'callback','68aa2e2ee5dff96e3355e6c7ee373e3d6a4e17f75f9518d843709c0c9bc3e3d4');
INSERT INTO debits VALUES(154932,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',3157,'callback','68aa2e2ee5dff96e3355e6c7ee373e3d6a4e17f75f9518d843709c0c9bc3e3d4');
INSERT INTO debits VALUES(154933,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',11021663,'open RPS','58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d');
INSERT INTO debits VALUES(154934,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',11021663,'open RPS','77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd');
INSERT INTO debits VALUES(154937,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',11021663,'open RPS','9652595f37edd08c51dfa26567e6cd76e6fa2709c3e578478ca398d316837a7a');
INSERT INTO debits VALUES(154955,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',11021664,'open RPS','5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e9');
INSERT INTO debits VALUES(154956,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',11021664,'open RPS','6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b');
INSERT INTO debits VALUES(154982,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',11021665,'open RPS','86be9a55762d316a3026c2836d044f5fc76e34da10e1b45feee5f18be7edb177');
INSERT INTO debits VALUES(154983,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',11021665,'open RPS','72dfcfb0c470ac255cde83fb8fe38de8a128188e03ea5ba5b2a93adbea1062fa');
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
INSERT INTO dividends VALUES(10,'01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b',154917,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB','XCP',600,'valid');
INSERT INTO dividends VALUES(11,'e7cf46a078fed4fafd0b5e3aff144802b853f8ae459a4f0c14add3314b7cc3a6',154918,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBC','XCP',800,'valid');

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
INSERT INTO issuances VALUES(6,'67586e98fad27da0b9968bc039a1ef34c939b9b8e523a8bef89d478608c5ecf6',154913,'BBBB',1000000000,1,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,0,0,0.0,'',50000000,0,'valid');
INSERT INTO issuances VALUES(7,'ca358758f6d27e6cf45272937977a748fd88391db679ceda7dc7bf1f005ee879',154914,'BBBC',100000,0,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',0,1,17,0.015,'foobar',50000000,0,'valid');
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
INSERT INTO messages VALUES(2,154909,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154909, "event": "dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986", "quantity": 50000000}',0);
INSERT INTO messages VALUES(3,154909,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 154909, "event": "dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986", "quantity": 50000000}',0);
INSERT INTO messages VALUES(4,154909,'insert','sends','{"asset": "XCP", "block_index": 154909, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 50000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986", "tx_index": 2}',0);
INSERT INTO messages VALUES(5,154910,'insert','orders','{"block_index": 154910, "expiration": 10, "expire_index": 154920, "fee_provided": 1000000, "fee_provided_remaining": 1000000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 100000000, "get_remaining": 100000000, "give_asset": "BTC", "give_quantity": 50000000, "give_remaining": 50000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5", "tx_index": 3}',0);
INSERT INTO messages VALUES(6,154911,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154911, "event": "e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71", "quantity": 105000000}',0);
INSERT INTO messages VALUES(7,154911,'insert','orders','{"block_index": 154911, "expiration": 10, "expire_index": 154921, "fee_provided": 10000, "fee_provided_remaining": 10000, "fee_required": 900000, "fee_required_remaining": 900000, "get_asset": "BTC", "get_quantity": 50000000, "get_remaining": 50000000, "give_asset": "XCP", "give_quantity": 105000000, "give_remaining": 105000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71", "tx_index": 4}',0);
INSERT INTO messages VALUES(8,154911,'update','orders','{"fee_provided_remaining": 142858, "fee_required_remaining": 0, "get_remaining": 0, "give_remaining": 0, "status": "open", "tx_hash": "084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5"}',0);
INSERT INTO messages VALUES(9,154911,'update','orders','{"fee_provided_remaining": 10000, "fee_required_remaining": 42858, "get_remaining": 0, "give_remaining": 5000000, "status": "open", "tx_hash": "e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71"}',0);
INSERT INTO messages VALUES(10,154911,'insert','order_matches','{"backward_asset": "XCP", "backward_quantity": 100000000, "block_index": 154911, "fee_paid": 857142, "forward_asset": "BTC", "forward_quantity": 50000000, "id": "084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71", "match_expire_index": 154931, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 154910, "tx0_expiration": 10, "tx0_hash": "084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5", "tx0_index": 3, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_block_index": 154911, "tx1_expiration": 10, "tx1_hash": "e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71", "tx1_index": 4}',0);
INSERT INTO messages VALUES(11,154912,'insert','credits','{"action": "btcpay", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154912, "event": "e77b9a9ae9e30b0dbdb6f510a264ef9de781501d7b6b92ae89eb059c5ab743db", "quantity": 100000000}',0);
INSERT INTO messages VALUES(12,154912,'update','order_matches','{"order_match_id": "084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71", "status": "completed"}',0);
INSERT INTO messages VALUES(13,154912,'insert','btcpays','{"block_index": 154912, "btc_amount": 50000000, "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "order_match_id": "084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71", "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "e77b9a9ae9e30b0dbdb6f510a264ef9de781501d7b6b92ae89eb059c5ab743db", "tx_index": 5}',0);
INSERT INTO messages VALUES(14,154913,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154913, "event": "67586e98fad27da0b9968bc039a1ef34c939b9b8e523a8bef89d478608c5ecf6", "quantity": 50000000}',0);
INSERT INTO messages VALUES(15,154913,'insert','issuances','{"asset": "BBBB", "block_index": 154913, "call_date": 0, "call_price": 0.0, "callable": false, "description": "", "divisible": true, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 1000000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "67586e98fad27da0b9968bc039a1ef34c939b9b8e523a8bef89d478608c5ecf6", "tx_index": 6}',0);
INSERT INTO messages VALUES(16,154913,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBB", "block_index": 154913, "event": "67586e98fad27da0b9968bc039a1ef34c939b9b8e523a8bef89d478608c5ecf6", "quantity": 1000000000}',0);
INSERT INTO messages VALUES(17,154914,'insert','debits','{"action": "issuance fee", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154914, "event": "ca358758f6d27e6cf45272937977a748fd88391db679ceda7dc7bf1f005ee879", "quantity": 50000000}',0);
INSERT INTO messages VALUES(18,154914,'insert','issuances','{"asset": "BBBC", "block_index": 154914, "call_date": 17, "call_price": 0.015, "callable": true, "description": "foobar", "divisible": false, "fee_paid": 50000000, "issuer": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "locked": false, "quantity": 100000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "transfer": false, "tx_hash": "ca358758f6d27e6cf45272937977a748fd88391db679ceda7dc7bf1f005ee879", "tx_index": 7}',0);
INSERT INTO messages VALUES(19,154914,'insert','credits','{"action": "issuance", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBC", "block_index": 154914, "event": "ca358758f6d27e6cf45272937977a748fd88391db679ceda7dc7bf1f005ee879", "quantity": 100000}',0);
INSERT INTO messages VALUES(20,154915,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBB", "block_index": 154915, "event": "beead77994cf573341ec17b58bbf7eb34d2711c993c1d976b128b3188dc1829a", "quantity": 4000000}',0);
INSERT INTO messages VALUES(21,154915,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "BBBB", "block_index": 154915, "event": "beead77994cf573341ec17b58bbf7eb34d2711c993c1d976b128b3188dc1829a", "quantity": 4000000}',0);
INSERT INTO messages VALUES(22,154915,'insert','sends','{"asset": "BBBB", "block_index": 154915, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 4000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "beead77994cf573341ec17b58bbf7eb34d2711c993c1d976b128b3188dc1829a", "tx_index": 8}',0);
INSERT INTO messages VALUES(23,154916,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBC", "block_index": 154916, "event": "2b4c342f5433ebe591a1da77e013d1b72475562d48578dca8b84bac6651c3cb9", "quantity": 526}',0);
INSERT INTO messages VALUES(24,154916,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "BBBC", "block_index": 154916, "event": "2b4c342f5433ebe591a1da77e013d1b72475562d48578dca8b84bac6651c3cb9", "quantity": 526}',0);
INSERT INTO messages VALUES(25,154916,'insert','sends','{"asset": "BBBC", "block_index": 154916, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 526, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "2b4c342f5433ebe591a1da77e013d1b72475562d48578dca8b84bac6651c3cb9", "tx_index": 9}',0);
INSERT INTO messages VALUES(26,154917,'insert','debits','{"action": "dividend", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154917, "event": "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b", "quantity": 24}',0);
INSERT INTO messages VALUES(27,154917,'insert','credits','{"action": "dividend", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 154917, "event": "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b", "quantity": 24}',0);
INSERT INTO messages VALUES(28,154917,'insert','dividends','{"asset": "BBBB", "block_index": 154917, "dividend_asset": "XCP", "quantity_per_unit": 600, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b", "tx_index": 10}',0);
INSERT INTO messages VALUES(29,154918,'insert','debits','{"action": "dividend", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154918, "event": "e7cf46a078fed4fafd0b5e3aff144802b853f8ae459a4f0c14add3314b7cc3a6", "quantity": 420800}',0);
INSERT INTO messages VALUES(30,154918,'insert','credits','{"action": "dividend", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 154918, "event": "e7cf46a078fed4fafd0b5e3aff144802b853f8ae459a4f0c14add3314b7cc3a6", "quantity": 420800}',0);
INSERT INTO messages VALUES(31,154918,'insert','dividends','{"asset": "BBBC", "block_index": 154918, "dividend_asset": "XCP", "quantity_per_unit": 800, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "e7cf46a078fed4fafd0b5e3aff144802b853f8ae459a4f0c14add3314b7cc3a6", "tx_index": 11}',0);
INSERT INTO messages VALUES(32,154919,'insert','broadcasts','{"block_index": 154919, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000000, "tx_hash": "ef6cbd2161eaea7943ce8693b9824d23d1793ffb1c0fca05b600d3899b44c977", "tx_index": 12, "value": 100.0}',0);
INSERT INTO messages VALUES(33,154920,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154920, "event": "9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c4", "quantity": 50000000}',0);
INSERT INTO messages VALUES(34,154920,'insert','bets','{"bet_type": 0, "block_index": 154920, "counterwager_quantity": 25000000, "counterwager_remaining": 25000000, "deadline": 1388000100, "expiration": 10, "expire_index": 154930, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 15120, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c4", "tx_index": 13, "wager_quantity": 50000000, "wager_remaining": 50000000}',0);
INSERT INTO messages VALUES(35,154921,'update','orders','{"status": "expired", "tx_hash": "084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5"}',0);
INSERT INTO messages VALUES(36,154921,'insert','order_expirations','{"block_index": 154921, "order_hash": "084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5", "order_index": 3, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
INSERT INTO messages VALUES(37,154921,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154921, "event": "4d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47", "quantity": 25000000}',0);
INSERT INTO messages VALUES(38,154921,'insert','bets','{"bet_type": 1, "block_index": 154921, "counterwager_quantity": 41500000, "counterwager_remaining": 41500000, "deadline": 1388000100, "expiration": 10, "expire_index": 154931, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 15120, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "4d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47", "tx_index": 14, "wager_quantity": 25000000, "wager_remaining": 25000000}',0);
INSERT INTO messages VALUES(39,154921,'update','bets','{"counterwager_remaining": 4250000, "status": "open", "tx_hash": "9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c4", "wager_remaining": 8500000}',0);
INSERT INTO messages VALUES(40,154921,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154921, "event": "4d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47", "quantity": 4250000}',0);
INSERT INTO messages VALUES(41,154921,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "4d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47", "wager_remaining": 4250000}',0);
INSERT INTO messages VALUES(42,154921,'insert','bet_matches','{"backward_quantity": 20750000, "block_index": 154921, "deadline": 1388000100, "fee_fraction_int": 5000000, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 41500000, "id": "9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c44d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47", "initial_value": 100.0, "leverage": 15120, "match_expire_index": 154930, "status": "pending", "target_value": 0.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 0, "tx0_block_index": 154920, "tx0_expiration": 10, "tx0_hash": "9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c4", "tx0_index": 13, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_bet_type": 1, "tx1_block_index": 154921, "tx1_expiration": 10, "tx1_hash": "4d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47", "tx1_index": 14}',0);
INSERT INTO messages VALUES(43,154922,'update','orders','{"status": "expired", "tx_hash": "e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71"}',0);
INSERT INTO messages VALUES(44,154922,'insert','credits','{"action": "cancel order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154922, "event": "e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71", "quantity": 5000000}',0);
INSERT INTO messages VALUES(45,154922,'insert','order_expirations','{"block_index": 154922, "order_hash": "e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71", "order_index": 4, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
INSERT INTO messages VALUES(46,154922,'insert','credits','{"action": "recredit forward quantity", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154922, "event": "9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c44d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47", "quantity": 41500000}',0);
INSERT INTO messages VALUES(47,154922,'insert','credits','{"action": "recredit backward quantity", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154922, "event": "9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c44d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47", "quantity": 20750000}',0);
INSERT INTO messages VALUES(48,154922,'update','bet_matches','{"bet_match_id": "9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c44d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47", "status": "expired"}',0);
INSERT INTO messages VALUES(49,154922,'insert','bet_match_expirations','{"bet_match_id": "9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c44d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47", "block_index": 154922, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
INSERT INTO messages VALUES(50,154922,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154922, "event": "dc0e9c3658a1a3ed1ec94274d8b19925c93e1abb7ddba294923ad9bde30f8cb8", "quantity": 150000000}',0);
INSERT INTO messages VALUES(51,154922,'insert','bets','{"bet_type": 0, "block_index": 154922, "counterwager_quantity": 350000000, "counterwager_remaining": 350000000, "deadline": 1388000100, "expiration": 10, "expire_index": 154932, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "dc0e9c3658a1a3ed1ec94274d8b19925c93e1abb7ddba294923ad9bde30f8cb8", "tx_index": 15, "wager_quantity": 150000000, "wager_remaining": 150000000}',0);
INSERT INTO messages VALUES(52,154923,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154923, "event": "c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3", "quantity": 350000000}',0);
INSERT INTO messages VALUES(53,154923,'insert','bets','{"bet_type": 1, "block_index": 154923, "counterwager_quantity": 150000000, "counterwager_remaining": 150000000, "deadline": 1388000100, "expiration": 10, "expire_index": 154933, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 0.0, "tx_hash": "c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3", "tx_index": 16, "wager_quantity": 350000000, "wager_remaining": 350000000}',0);
INSERT INTO messages VALUES(54,154923,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154923, "event": "c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3", "quantity": 0}',0);
INSERT INTO messages VALUES(55,154923,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "dc0e9c3658a1a3ed1ec94274d8b19925c93e1abb7ddba294923ad9bde30f8cb8", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(56,154923,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154923, "event": "c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3", "quantity": 0}',0);
INSERT INTO messages VALUES(57,154923,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(58,154923,'insert','bet_matches','{"backward_quantity": 350000000, "block_index": 154923, "deadline": 1388000100, "fee_fraction_int": 5000000, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 150000000, "id": "dc0e9c3658a1a3ed1ec94274d8b19925c93e1abb7ddba294923ad9bde30f8cb8c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3", "initial_value": 100.0, "leverage": 5040, "match_expire_index": 154932, "status": "pending", "target_value": 0.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 0, "tx0_block_index": 154922, "tx0_expiration": 10, "tx0_hash": "dc0e9c3658a1a3ed1ec94274d8b19925c93e1abb7ddba294923ad9bde30f8cb8", "tx0_index": 15, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_bet_type": 1, "tx1_block_index": 154923, "tx1_expiration": 10, "tx1_hash": "c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3", "tx1_index": 16}',0);
INSERT INTO messages VALUES(59,154924,'insert','credits','{"action": "recredit forward quantity", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154924, "event": "dc0e9c3658a1a3ed1ec94274d8b19925c93e1abb7ddba294923ad9bde30f8cb8c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3", "quantity": 150000000}',0);
INSERT INTO messages VALUES(60,154924,'insert','credits','{"action": "recredit backward quantity", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154924, "event": "dc0e9c3658a1a3ed1ec94274d8b19925c93e1abb7ddba294923ad9bde30f8cb8c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3", "quantity": 350000000}',0);
INSERT INTO messages VALUES(61,154924,'update','bet_matches','{"bet_match_id": "dc0e9c3658a1a3ed1ec94274d8b19925c93e1abb7ddba294923ad9bde30f8cb8c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3", "status": "expired"}',0);
INSERT INTO messages VALUES(62,154924,'insert','bet_match_expirations','{"bet_match_id": "dc0e9c3658a1a3ed1ec94274d8b19925c93e1abb7ddba294923ad9bde30f8cb8c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3", "block_index": 154924, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
INSERT INTO messages VALUES(63,154924,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154924, "event": "4a64a107f0cb32536e5bce6c98c393db21cca7f4ea187ba8c4dca8b51d4ea80a", "quantity": 750000000}',0);
INSERT INTO messages VALUES(64,154924,'insert','bets','{"bet_type": 2, "block_index": 154924, "counterwager_quantity": 650000000, "counterwager_remaining": 650000000, "deadline": 1388000200, "expiration": 10, "expire_index": 154934, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 1.0, "tx_hash": "4a64a107f0cb32536e5bce6c98c393db21cca7f4ea187ba8c4dca8b51d4ea80a", "tx_index": 17, "wager_quantity": 750000000, "wager_remaining": 750000000}',0);
INSERT INTO messages VALUES(65,154925,'insert','debits','{"action": "bet", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154925, "event": "f299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c", "quantity": 650000000}',0);
INSERT INTO messages VALUES(66,154925,'insert','bets','{"bet_type": 3, "block_index": 154925, "counterwager_quantity": 750000000, "counterwager_remaining": 750000000, "deadline": 1388000200, "expiration": 10, "expire_index": 154935, "fee_fraction_int": 5000000.0, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "leverage": 5040, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "target_value": 1.0, "tx_hash": "f299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c", "tx_index": 18, "wager_quantity": 650000000, "wager_remaining": 650000000}',0);
INSERT INTO messages VALUES(67,154925,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154925, "event": "f299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c", "quantity": 0}',0);
INSERT INTO messages VALUES(68,154925,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "4a64a107f0cb32536e5bce6c98c393db21cca7f4ea187ba8c4dca8b51d4ea80a", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(69,154925,'insert','credits','{"action": "filled", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154925, "event": "f299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c", "quantity": 0}',0);
INSERT INTO messages VALUES(70,154925,'update','bets','{"counterwager_remaining": 0, "status": "filled", "tx_hash": "f299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c", "wager_remaining": 0}',0);
INSERT INTO messages VALUES(71,154925,'insert','bet_matches','{"backward_quantity": 650000000, "block_index": 154925, "deadline": 1388000200, "fee_fraction_int": 5000000, "feed_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "forward_quantity": 750000000, "id": "4a64a107f0cb32536e5bce6c98c393db21cca7f4ea187ba8c4dca8b51d4ea80af299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c", "initial_value": 100.0, "leverage": 5040, "match_expire_index": 154934, "status": "pending", "target_value": 1.0, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_bet_type": 2, "tx0_block_index": 154924, "tx0_expiration": 10, "tx0_hash": "4a64a107f0cb32536e5bce6c98c393db21cca7f4ea187ba8c4dca8b51d4ea80a", "tx0_index": 17, "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_bet_type": 3, "tx1_block_index": 154925, "tx1_expiration": 10, "tx1_hash": "f299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c", "tx1_index": 18}',0);
INSERT INTO messages VALUES(72,154926,'insert','credits','{"action": "recredit forward quantity", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154926, "event": "4a64a107f0cb32536e5bce6c98c393db21cca7f4ea187ba8c4dca8b51d4ea80af299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c", "quantity": 750000000}',0);
INSERT INTO messages VALUES(73,154926,'insert','credits','{"action": "recredit backward quantity", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154926, "event": "4a64a107f0cb32536e5bce6c98c393db21cca7f4ea187ba8c4dca8b51d4ea80af299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c", "quantity": 650000000}',0);
INSERT INTO messages VALUES(74,154926,'update','bet_matches','{"bet_match_id": "4a64a107f0cb32536e5bce6c98c393db21cca7f4ea187ba8c4dca8b51d4ea80af299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c", "status": "expired"}',0);
INSERT INTO messages VALUES(75,154926,'insert','bet_match_expirations','{"bet_match_id": "4a64a107f0cb32536e5bce6c98c393db21cca7f4ea187ba8c4dca8b51d4ea80af299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c", "block_index": 154926, "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
INSERT INTO messages VALUES(76,154926,'insert','broadcasts','{"block_index": 154926, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000050, "tx_hash": "ab897fbdedfa502b2d839b6a56100887dccdc507555c282e59589e06300a62e2", "tx_index": 19, "value": 99.86166}',0);
INSERT INTO messages VALUES(77,154927,'insert','broadcasts','{"block_index": 154927, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000101, "tx_hash": "83891d7fe85c33e52c8b4e5814c92fb6a3b9467299200538a6babaa8b452d879", "tx_index": 20, "value": 100.343}',0);
INSERT INTO messages VALUES(78,154928,'insert','broadcasts','{"block_index": 154928, "fee_fraction_int": 5000000, "locked": false, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "text": "Unit Test", "timestamp": 1388000201, "tx_hash": "2f0fd1e89b8de1d57292742ec380ea47066e307ad645f5bc3adad8a06ff58608", "tx_index": 21, "value": 2.0}',0);
INSERT INTO messages VALUES(79,154929,'insert','debits','{"action": "open order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBB", "block_index": 154929, "event": "7cb7c4547cf2653590d7a9ace60cc623d25148adfbc88a89aeb0ef88da7839ba", "quantity": 50000000}',0);
INSERT INTO messages VALUES(80,154929,'insert','orders','{"block_index": 154929, "expiration": 10, "expire_index": 154939, "fee_provided": 10000, "fee_provided_remaining": 10000, "fee_required": 0, "fee_required_remaining": 0, "get_asset": "XCP", "get_quantity": 50000000, "get_remaining": 50000000, "give_asset": "BBBB", "give_quantity": 50000000, "give_remaining": 50000000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "7cb7c4547cf2653590d7a9ace60cc623d25148adfbc88a89aeb0ef88da7839ba", "tx_index": 22}',0);
INSERT INTO messages VALUES(81,154930,'insert','credits','{"action": "burn", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154930, "event": "8f11b05da785e43e713d03774c6bd3405d99cd3024af334ffd68db663aa37034", "quantity": 56999891788}',0);
INSERT INTO messages VALUES(82,154930,'insert','burns','{"block_index": 154930, "burned": 38000000, "earned": 56999891788, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "8f11b05da785e43e713d03774c6bd3405d99cd3024af334ffd68db663aa37034", "tx_index": 23}',0);
INSERT INTO messages VALUES(83,154931,'update','bets','{"status": "expired", "tx_hash": "9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c4"}',0);
INSERT INTO messages VALUES(84,154931,'insert','credits','{"action": "recredit wager remaining", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154931, "event": "9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c4", "quantity": 8500000}',0);
INSERT INTO messages VALUES(85,154931,'insert','bet_expirations','{"bet_hash": "9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c4", "bet_index": 13, "block_index": 154931, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
INSERT INTO messages VALUES(86,154931,'insert','debits','{"action": "send", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBC", "block_index": 154931, "event": "452ba1ddef80246c48be7690193c76c1d61185906be9401014fe14f1be64b74f", "quantity": 10000}',0);
INSERT INTO messages VALUES(87,154931,'insert','credits','{"action": "send", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "BBBC", "block_index": 154931, "event": "452ba1ddef80246c48be7690193c76c1d61185906be9401014fe14f1be64b74f", "quantity": 10000}',0);
INSERT INTO messages VALUES(88,154931,'insert','sends','{"asset": "BBBC", "block_index": 154931, "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "quantity": 10000, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "452ba1ddef80246c48be7690193c76c1d61185906be9401014fe14f1be64b74f", "tx_index": 24}',0);
INSERT INTO messages VALUES(89,154932,'insert','debits','{"action": "callback", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154932, "event": "68aa2e2ee5dff96e3355e6c7ee373e3d6a4e17f75f9518d843709c0c9bc3e3d4", "quantity": 4735500000}',0);
INSERT INTO messages VALUES(90,154932,'insert','credits','{"action": "callback", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBC", "block_index": 154932, "event": "68aa2e2ee5dff96e3355e6c7ee373e3d6a4e17f75f9518d843709c0c9bc3e3d4", "quantity": 3157}',0);
INSERT INTO messages VALUES(91,154932,'insert','debits','{"action": "callback", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "BBBC", "block_index": 154932, "event": "68aa2e2ee5dff96e3355e6c7ee373e3d6a4e17f75f9518d843709c0c9bc3e3d4", "quantity": 3157}',0);
INSERT INTO messages VALUES(92,154932,'insert','credits','{"action": "callback", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 154932, "event": "68aa2e2ee5dff96e3355e6c7ee373e3d6a4e17f75f9518d843709c0c9bc3e3d4", "quantity": 4735500000}',0);
INSERT INTO messages VALUES(93,154932,'insert','callbacks','{"asset": "BBBC", "block_index": 154932, "fraction": 0.3, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "68aa2e2ee5dff96e3355e6c7ee373e3d6a4e17f75f9518d843709c0c9bc3e3d4", "tx_index": 25}',0);
INSERT INTO messages VALUES(94,154933,'insert','debits','{"action": "open RPS", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154933, "event": "58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d", "quantity": 11021663}',0);
INSERT INTO messages VALUES(95,154933,'insert','rps','{"block_index": 154933, "expiration": 100, "expire_index": 155033, "move_random_hash": "6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d", "possible_moves": 5, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d", "tx_index": 26, "wager": 11021663}',0);
INSERT INTO messages VALUES(96,154934,'insert','debits','{"action": "open RPS", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 154934, "event": "77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd", "quantity": 11021663}',0);
INSERT INTO messages VALUES(97,154934,'insert','rps','{"block_index": 154934, "expiration": 100, "expire_index": 155034, "move_random_hash": "6e8bf66cbd6636aca1802459b730a99548624e48e243b840e0b34a12bede17ec", "possible_moves": 5, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "tx_hash": "77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd", "tx_index": 27, "wager": 11021663}',0);
INSERT INTO messages VALUES(98,154934,'update','rps','{"status": "matched", "tx_index": 26}',0);
INSERT INTO messages VALUES(99,154934,'update','rps','{"status": "matched", "tx_index": 27}',0);
INSERT INTO messages VALUES(100,154934,'insert','rps_matches','{"block_index": 154934, "id": "58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd", "match_expire_index": 154954, "possible_moves": 5, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 154933, "tx0_expiration": 100, "tx0_hash": "58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d", "tx0_index": 26, "tx0_move_random_hash": "6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d", "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_block_index": 154934, "tx1_expiration": 100, "tx1_hash": "77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd", "tx1_index": 27, "tx1_move_random_hash": "6e8bf66cbd6636aca1802459b730a99548624e48e243b840e0b34a12bede17ec", "wager": 11021663}',0);
INSERT INTO messages VALUES(101,154935,'update','rps_matches','{"rps_match_id": "58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd", "status": "resolved and pending"}',0);
INSERT INTO messages VALUES(102,154935,'insert','rpsresolves','{"block_index": 154935, "move": 3, "random": "7a4488d61ed8f2e9fa2874113fccb8b1", "rps_match_id": "58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd", "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "bd4fc42a21f1f860a1030e6eba23d53ecab71bd19297ab6c074381d4ecee0018", "tx_index": 28}',0);
INSERT INTO messages VALUES(103,154936,'insert','credits','{"action": "wins", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154936, "event": "58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd", "quantity": 22043326}',0);
INSERT INTO messages VALUES(104,154936,'update','rps_matches','{"rps_match_id": "58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd", "status": "concluded: first player wins"}',0);
INSERT INTO messages VALUES(105,154936,'insert','rpsresolves','{"block_index": 154936, "move": 5, "random": "fa765e80203cba24a298e4458f63ff6b", "rps_match_id": "58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd", "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "valid", "tx_hash": "1f18d650d205d71d934c3646ff5fac1c096ba52eba4cf758b865364f4167d3cd", "tx_index": 29}',0);
INSERT INTO messages VALUES(106,154937,'insert','debits','{"action": "open RPS", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154937, "event": "9652595f37edd08c51dfa26567e6cd76e6fa2709c3e578478ca398d316837a7a", "quantity": 11021663}',0);
INSERT INTO messages VALUES(107,154937,'insert','rps','{"block_index": 154937, "expiration": 10, "expire_index": 154947, "move_random_hash": "6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d", "possible_moves": 5, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "9652595f37edd08c51dfa26567e6cd76e6fa2709c3e578478ca398d316837a7a", "tx_index": 30, "wager": 11021663}',0);
INSERT INTO messages VALUES(108,154954,'update','orders','{"status": "expired", "tx_hash": "7cb7c4547cf2653590d7a9ace60cc623d25148adfbc88a89aeb0ef88da7839ba"}',0);
INSERT INTO messages VALUES(109,154954,'insert','credits','{"action": "cancel order", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "BBBB", "block_index": 154954, "event": "7cb7c4547cf2653590d7a9ace60cc623d25148adfbc88a89aeb0ef88da7839ba", "quantity": 50000000}',0);
INSERT INTO messages VALUES(110,154954,'insert','order_expirations','{"block_index": 154954, "order_hash": "7cb7c4547cf2653590d7a9ace60cc623d25148adfbc88a89aeb0ef88da7839ba", "order_index": 22, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
INSERT INTO messages VALUES(111,154954,'update','rps','{"status": "expired", "tx_hash": "9652595f37edd08c51dfa26567e6cd76e6fa2709c3e578478ca398d316837a7a"}',0);
INSERT INTO messages VALUES(112,154954,'insert','credits','{"action": "recredit wager", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154954, "event": "9652595f37edd08c51dfa26567e6cd76e6fa2709c3e578478ca398d316837a7a", "quantity": 11021663}',0);
INSERT INTO messages VALUES(113,154954,'insert','rps_expirations','{"block_index": 154954, "rps_hash": "9652595f37edd08c51dfa26567e6cd76e6fa2709c3e578478ca398d316837a7a", "rps_index": 30, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc"}',0);
INSERT INTO messages VALUES(114,154955,'insert','debits','{"action": "open RPS", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154955, "event": "5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e9", "quantity": 11021664}',0);
INSERT INTO messages VALUES(115,154955,'insert','rps','{"block_index": 154955, "expiration": 10, "expire_index": 154965, "move_random_hash": "6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d", "possible_moves": 5, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e9", "tx_index": 48, "wager": 11021664}',0);
INSERT INTO messages VALUES(116,154956,'insert','debits','{"action": "open RPS", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 154956, "event": "6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b", "quantity": 11021664}',0);
INSERT INTO messages VALUES(117,154956,'insert','rps','{"block_index": 154956, "expiration": 10, "expire_index": 154966, "move_random_hash": "6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d", "possible_moves": 5, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "tx_hash": "6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b", "tx_index": 49, "wager": 11021664}',0);
INSERT INTO messages VALUES(118,154956,'update','rps','{"status": "matched", "tx_index": 48}',0);
INSERT INTO messages VALUES(119,154956,'update','rps','{"status": "matched", "tx_index": 49}',0);
INSERT INTO messages VALUES(120,154956,'insert','rps_matches','{"block_index": 154956, "id": "5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e96b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b", "match_expire_index": 154976, "possible_moves": 5, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 154955, "tx0_expiration": 10, "tx0_hash": "5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e9", "tx0_index": 48, "tx0_move_random_hash": "6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d", "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_block_index": 154956, "tx1_expiration": 10, "tx1_hash": "6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b", "tx1_index": 49, "tx1_move_random_hash": "6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d", "wager": 11021664}',0);
INSERT INTO messages VALUES(121,154981,'insert','credits','{"action": "recredit wager", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154981, "event": "5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e96b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b", "quantity": 11021664}',0);
INSERT INTO messages VALUES(122,154981,'insert','credits','{"action": "recredit wager", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 154981, "event": "5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e96b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b", "quantity": 11021664}',0);
INSERT INTO messages VALUES(123,154981,'update','rps_matches','{"rps_match_id": "5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e96b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b", "status": "expired"}',0);
INSERT INTO messages VALUES(124,154981,'insert','rps_match_expirations','{"block_index": 154981, "rps_match_id": "5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e96b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns"}',0);
INSERT INTO messages VALUES(125,154982,'insert','debits','{"action": "open RPS", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 154982, "event": "86be9a55762d316a3026c2836d044f5fc76e34da10e1b45feee5f18be7edb177", "quantity": 11021665}',0);
INSERT INTO messages VALUES(126,154982,'insert','rps','{"block_index": 154982, "expiration": 10, "expire_index": 154992, "move_random_hash": "6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d", "possible_moves": 5, "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "open", "tx_hash": "86be9a55762d316a3026c2836d044f5fc76e34da10e1b45feee5f18be7edb177", "tx_index": 75, "wager": 11021665}',0);
INSERT INTO messages VALUES(127,154983,'insert','debits','{"action": "open RPS", "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "asset": "XCP", "block_index": 154983, "event": "72dfcfb0c470ac255cde83fb8fe38de8a128188e03ea5ba5b2a93adbea1062fa", "quantity": 11021665}',0);
INSERT INTO messages VALUES(128,154983,'insert','rps','{"block_index": 154983, "expiration": 10, "expire_index": 154993, "move_random_hash": "6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d", "possible_moves": 5, "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "status": "open", "tx_hash": "72dfcfb0c470ac255cde83fb8fe38de8a128188e03ea5ba5b2a93adbea1062fa", "tx_index": 76, "wager": 11021665}',0);
INSERT INTO messages VALUES(129,154983,'update','rps','{"status": "matched", "tx_index": 75}',0);
INSERT INTO messages VALUES(130,154983,'update','rps','{"status": "matched", "tx_index": 76}',0);
INSERT INTO messages VALUES(131,154983,'insert','rps_matches','{"block_index": 154983, "id": "86be9a55762d316a3026c2836d044f5fc76e34da10e1b45feee5f18be7edb17772dfcfb0c470ac255cde83fb8fe38de8a128188e03ea5ba5b2a93adbea1062fa", "match_expire_index": 155003, "possible_moves": 5, "status": "pending", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx0_block_index": 154982, "tx0_expiration": 10, "tx0_hash": "86be9a55762d316a3026c2836d044f5fc76e34da10e1b45feee5f18be7edb177", "tx0_index": 75, "tx0_move_random_hash": "6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d", "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns", "tx1_block_index": 154983, "tx1_expiration": 10, "tx1_hash": "72dfcfb0c470ac255cde83fb8fe38de8a128188e03ea5ba5b2a93adbea1062fa", "tx1_index": 76, "tx1_move_random_hash": "6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d", "wager": 11021665}',0);
INSERT INTO messages VALUES(132,154984,'update','rps_matches','{"rps_match_id": "86be9a55762d316a3026c2836d044f5fc76e34da10e1b45feee5f18be7edb17772dfcfb0c470ac255cde83fb8fe38de8a128188e03ea5ba5b2a93adbea1062fa", "status": "resolved and pending"}',0);
INSERT INTO messages VALUES(133,154984,'insert','rpsresolves','{"block_index": 154984, "move": 3, "random": "7a4488d61ed8f2e9fa2874113fccb8b1", "rps_match_id": "86be9a55762d316a3026c2836d044f5fc76e34da10e1b45feee5f18be7edb17772dfcfb0c470ac255cde83fb8fe38de8a128188e03ea5ba5b2a93adbea1062fa", "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "status": "valid", "tx_hash": "08f271887ce94707da822d5263bae19d5519cb3614e0daedc4c7ce5dab7473f1", "tx_index": 77}',0);
INSERT INTO messages VALUES(134,155009,'insert','credits','{"action": "wins", "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "asset": "XCP", "block_index": 155009, "event": "86be9a55762d316a3026c2836d044f5fc76e34da10e1b45feee5f18be7edb17772dfcfb0c470ac255cde83fb8fe38de8a128188e03ea5ba5b2a93adbea1062fa", "quantity": 22043330}',0);
INSERT INTO messages VALUES(135,155009,'update','rps_matches','{"rps_match_id": "86be9a55762d316a3026c2836d044f5fc76e34da10e1b45feee5f18be7edb17772dfcfb0c470ac255cde83fb8fe38de8a128188e03ea5ba5b2a93adbea1062fa", "status": "concluded: first player wins"}',0);
INSERT INTO messages VALUES(136,155009,'insert','rps_match_expirations','{"block_index": 155009, "rps_match_id": "86be9a55762d316a3026c2836d044f5fc76e34da10e1b45feee5f18be7edb17772dfcfb0c470ac255cde83fb8fe38de8a128188e03ea5ba5b2a93adbea1062fa", "tx0_address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc", "tx1_address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns"}',0);
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
INSERT INTO order_expirations VALUES(3,'084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',154921);
INSERT INTO order_expirations VALUES(4,'e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',154922);
INSERT INTO order_expirations VALUES(22,'7cb7c4547cf2653590d7a9ace60cc623d25148adfbc88a89aeb0ef88da7839ba','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',154954);

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
INSERT INTO order_matches VALUES('084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71',3,'084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',4,'e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BTC',50000000,'XCP',100000000,154910,154911,154911,10,10,154931,857142,'completed');
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
INSERT INTO orders VALUES(3,'084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5',154910,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BTC',50000000,0,'XCP',100000000,0,10,154920,0,0,1000000,142858,'expired');
INSERT INTO orders VALUES(4,'e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71',154911,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','XCP',105000000,5000000,'BTC',50000000,0,10,154921,900000,42858,10000,10000,'expired');
INSERT INTO orders VALUES(22,'7cb7c4547cf2653590d7a9ace60cc623d25148adfbc88a89aeb0ef88da7839ba',154929,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','BBBB',50000000,50000000,'XCP',50000000,50000000,10,154939,0,0,10000,10000,'expired');
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
INSERT INTO rps VALUES(26,'58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d',154933,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5,11021663,'6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d',100,155033,'matched');
INSERT INTO rps VALUES(27,'77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd',154934,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5,11021663,'6e8bf66cbd6636aca1802459b730a99548624e48e243b840e0b34a12bede17ec',100,155034,'matched');
INSERT INTO rps VALUES(30,'9652595f37edd08c51dfa26567e6cd76e6fa2709c3e578478ca398d316837a7a',154937,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5,11021663,'6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d',10,154947,'expired');
INSERT INTO rps VALUES(48,'5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e9',154955,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5,11021664,'6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d',10,154965,'matched');
INSERT INTO rps VALUES(49,'6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b',154956,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5,11021664,'6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d',10,154966,'matched');
INSERT INTO rps VALUES(75,'86be9a55762d316a3026c2836d044f5fc76e34da10e1b45feee5f18be7edb177',154982,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',5,11021665,'6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d',10,154992,'matched');
INSERT INTO rps VALUES(76,'72dfcfb0c470ac255cde83fb8fe38de8a128188e03ea5ba5b2a93adbea1062fa',154983,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5,11021665,'6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d',10,154993,'matched');
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
INSERT INTO rps_expirations VALUES(30,'9652595f37edd08c51dfa26567e6cd76e6fa2709c3e578478ca398d316837a7a','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',154954);

-- Table  rps_match_expirations
DROP TABLE IF EXISTS rps_match_expirations;
CREATE TABLE rps_match_expirations(
                      rps_match_id TEXT PRIMARY KEY,
                      tx0_address TEXT,
                      tx1_address TEXT,
                      block_index INTEGER,
                      FOREIGN KEY (rps_match_id) REFERENCES rps_matches(id),
                      FOREIGN KEY (block_index) REFERENCES blocks(block_index));
INSERT INTO rps_match_expirations VALUES('5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e96b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',154981);
INSERT INTO rps_match_expirations VALUES('86be9a55762d316a3026c2836d044f5fc76e34da10e1b45feee5f18be7edb17772dfcfb0c470ac255cde83fb8fe38de8a128188e03ea5ba5b2a93adbea1062fa','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',155009);

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
INSERT INTO rps_matches VALUES('58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd',26,'58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',27,'77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d','6e8bf66cbd6636aca1802459b730a99548624e48e243b840e0b34a12bede17ec',11021663,5,154933,154934,154934,100,100,154954,'concluded: first player wins');
INSERT INTO rps_matches VALUES('5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e96b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b',48,'5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e9','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',49,'6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d','6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d',11021664,5,154955,154956,154956,10,10,154976,'expired');
INSERT INTO rps_matches VALUES('86be9a55762d316a3026c2836d044f5fc76e34da10e1b45feee5f18be7edb17772dfcfb0c470ac255cde83fb8fe38de8a128188e03ea5ba5b2a93adbea1062fa',75,'86be9a55762d316a3026c2836d044f5fc76e34da10e1b45feee5f18be7edb177','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',76,'72dfcfb0c470ac255cde83fb8fe38de8a128188e03ea5ba5b2a93adbea1062fa','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d','6a886d74c2d4b1d7a35fd9159333ef64ba45a04d7aeeeb4538f958603c16fc5d',11021665,5,154982,154983,154983,10,10,155003,'concluded: first player wins');
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
INSERT INTO rpsresolves VALUES(28,'bd4fc42a21f1f860a1030e6eba23d53ecab71bd19297ab6c074381d4ecee0018',154935,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',3,'7a4488d61ed8f2e9fa2874113fccb8b1','58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd','valid');
INSERT INTO rpsresolves VALUES(29,'1f18d650d205d71d934c3646ff5fac1c096ba52eba4cf758b865364f4167d3cd',154936,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',5,'fa765e80203cba24a298e4458f63ff6b','58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd','valid');
INSERT INTO rpsresolves VALUES(77,'08f271887ce94707da822d5263bae19d5519cb3614e0daedc4c7ce5dab7473f1',154984,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',3,'7a4488d61ed8f2e9fa2874113fccb8b1','86be9a55762d316a3026c2836d044f5fc76e34da10e1b45feee5f18be7edb17772dfcfb0c470ac255cde83fb8fe38de8a128188e03ea5ba5b2a93adbea1062fa','valid');
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
INSERT INTO sends VALUES(2,'dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986',154909,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','XCP',50000000,'valid');
INSERT INTO sends VALUES(8,'beead77994cf573341ec17b58bbf7eb34d2711c993c1d976b128b3188dc1829a',154915,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBB',4000000,'valid');
INSERT INTO sends VALUES(9,'2b4c342f5433ebe591a1da77e013d1b72475562d48578dca8b84bac6651c3cb9',154916,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',526,'valid');
INSERT INTO sends VALUES(24,'452ba1ddef80246c48be7690193c76c1d61185906be9401014fe14f1be64b74f',154931,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns','BBBC',10000,'valid');
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
INSERT INTO transactions VALUES(2,'dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986',154909,'244e7bf91f9a9cd5ec8c2abd8740a506c2de2156ab635d08d78429afba33f7f090659eca59b3a3f862dd87bb36221e52915512486da5d6ef0ec37e85124a9303',1549090000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',7800,10000,X'0000000000000000000000010000000002FAF080',1);
INSERT INTO transactions VALUES(3,'084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5',154910,'80d40ca10e5ea63a2ad8303c70819f369afbbd5716faf875fa4eb8ac2799ee0f9b2e5e204849d8ebca34537bdef7620fe81db66fc8195e193ee778fa43d68cdb',1549100000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,1000000,X'0000000A00000000000000000000000002FAF08000000000000000010000000005F5E100000A0000000000000000',1);
INSERT INTO transactions VALUES(4,'e52d9c508c502347344d8c07ad91cbd6068afc75ff6292f062a09ca381c89e71',154911,'c572450879274cc2a7adfa27f3484ba94d76ae3c23d42a92f386000ba36b09790b7448701614b040f3e5dadd6378940e4b47ddb7e6a0da38aadb578b81c178e1',1549110000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000000A00000000000000010000000006422C4000000000000000000000000002FAF080000A00000000000DBBA0',1);
INSERT INTO transactions VALUES(5,'e77b9a9ae9e30b0dbdb6f510a264ef9de781501d7b6b92ae89eb059c5ab743db',154912,'b0fe961d25394561c42ea0e5df888ba20580eab3ddb9d294faf901cda2517ebc2078f91137fdf9badefee7950b0274941c7764ecb47546c05e1a3563fc032339',1549120000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',50000000,10000,X'0000000B084FED08B978AF4D7D196A7446A86B58009E636B611DB16211B65A9AADFF29C5E52D9C508C502347344D8C07AD91CBD6068AFC75FF6292F062A09CA381C89E71',1);
INSERT INTO transactions VALUES(6,'67586e98fad27da0b9968bc039a1ef34c939b9b8e523a8bef89d478608c5ecf6',154913,'797ff8f7e2e601c1595d2bc2088ae7ecd723d53514b74e5545be46389d9ccf31bed1c874b482eee40b06d2d5823969203624a7fd540819262d0033ab08c0887f',1549130000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'000000140000000000004767000000003B9ACA000100000000000000000000',1);
INSERT INTO transactions VALUES(7,'ca358758f6d27e6cf45272937977a748fd88391db679ceda7dc7bf1f005ee879',154914,'78cad5b3c7bbac19cbbf5b58f7f2183441d22d200d3b1cb41da63aa293a5393883e3fcfc8eccd9c0ff5ca62b0552c8cd8b5c08e76475003f403c382725194e80',1549140000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'00000014000000000000476800000000000186A00001000000113C75C28F06666F6F626172',1);
INSERT INTO transactions VALUES(8,'beead77994cf573341ec17b58bbf7eb34d2711c993c1d976b128b3188dc1829a',154915,'fc8ccc098da63edc027cfcb3a6bd5a882e21cc79ec5786f499b1c483779af70d76cd7decf3d4018dcefa678e9566c2b2a2fce14e27a8bb273af4a9af7cf1d932',1549150000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',7800,10000,X'00000000000000000000476700000000003D0900',1);
INSERT INTO transactions VALUES(9,'2b4c342f5433ebe591a1da77e013d1b72475562d48578dca8b84bac6651c3cb9',154916,'94cd7d76a2cda75e80a2fe48dd3c44d46fed958f6223c9b0ff1a5ebcf255ab0a27df96220f9153fd180048828dcc3afe98c73988f91619f444c91c62a11d881b',1549160000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',7800,10000,X'000000000000000000004768000000000000020E',1);
INSERT INTO transactions VALUES(10,'01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b',154917,'b8b1961aa5981b069f1e7ce8d7a181736b80b54a5bda33a1bdf4b46f3d0f3dd732bc290cd13e7dab43d12c9efe30723afbe75e82447acd433557548a7568bb1d',1549170000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'00000032000000000000025800000000000047670000000000000001',1);
INSERT INTO transactions VALUES(11,'e7cf46a078fed4fafd0b5e3aff144802b853f8ae459a4f0c14add3314b7cc3a6',154918,'088546b5563c11520e7fefe3ee0b8bd554b63f935ba0f52ee593300d79ccaba01cef7410df455753f5b4b33326da18e055638a161582c2d6e241ddfe6136e379',1549180000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'00000032000000000000032000000000000047680000000000000001',1);
INSERT INTO transactions VALUES(12,'ef6cbd2161eaea7943ce8693b9824d23d1793ffb1c0fca05b600d3899b44c977',154919,'3dd36d3b00a9000ef4d22e3017f7af48c5c0a9af6e03ecc2a26a49345adef79ac252fd57551a14991e40d128990fbe8776fec55d4826b98e937f92bef3ae0be4',1549190000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000001E52BB33004059000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(13,'9d1e0e2d9459d06523ad13e28a4093c2316baafe7aec5b25f30eba2e113599c4',154920,'0fca8dfde3b5b34b0829e1daa9a5c7f235a93d74fd3575d68f7a131c7790e01eb69fd3e0aaa9d872c8dad6d8e57e49b3a5903d774372ed5524dac8afc51c18d2',1549200000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',7800,10000,X'00000028000052BB33640000000002FAF08000000000017D7840000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(14,'4d7b3ef7300acf70c892d8327db8272f54434adbc61a4e130a563cb59a0d0f47',154921,'1a99275c7a70a496ce9fcd5cf21876916351805fdc5258dbaa004ff9ea8e451be93cc6f872819dd8942847c650afd37618bbb630528d772b4f8eb318122b1043',1549210000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',7800,10000,X'00000028000152BB336400000000017D78400000000002793D60000000000000000000003B100000000A',1);
INSERT INTO transactions VALUES(15,'dc0e9c3658a1a3ed1ec94274d8b19925c93e1abb7ddba294923ad9bde30f8cb8',154922,'3e7b51e4121b3f70fa8ac6b3c2e3c29a985e05c5ad92678ee3982e931d81891a876260f7f53108a6e6d9012211a4f43cbc038b91dee92d2d1466448cec4979c4',1549220000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',7800,10000,X'00000028000052BB33640000000008F0D1800000000014DC93800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(16,'c555eab45d08845ae9f10d452a99bfcb06f74a50b988fe7e48dd323789b88ee3',154923,'9b16d5d768bbfd1c83ca224c2fd704429a16b6102dc1ccc21eec6547da4dad23bfa3f0df63b0a0c1159268008765227db81aac243e48f470594c3f8e30a2772b',1549230000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',7800,10000,X'00000028000152BB33640000000014DC93800000000008F0D1800000000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(17,'4a64a107f0cb32536e5bce6c98c393db21cca7f4ea187ba8c4dca8b51d4ea80a',154924,'915916edf01452e1a554d7dd7c63acef01f9540006a5b09425d151a8a170bd23e0500bd89dc97b8e49f22a0e662d140f03bcd6d2d9faf2b35e6968cd076329d3',1549240000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',7800,10000,X'00000028000252BB33C8000000002CB417800000000026BE36803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(18,'f299791cddd3d6664f6670842812ef6053eb6501bd6282a476bbbf3ee91e750c',154925,'29d88d169c0c9bb778dd32b9d76fdef07d4cdd5302f02938101e03dd616426884b0e08816cfd7b217662f226003e3821f8e09063dd5250331a3e187557619386',1549250000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',7800,10000,X'00000028000352BB33C80000000026BE3680000000002CB417803FF0000000000000000013B00000000A',1);
INSERT INTO transactions VALUES(19,'ab897fbdedfa502b2d839b6a56100887dccdc507555c282e59589e06300a62e2',154926,'aeff66363337363dce240dd090e1d507f934b2496f82fce7094b6499b657f6375fb541747538a0001da7e87f708e10068399ef20441ba49485bc4edaa2347c85',1549260000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000001E52BB33324058F7256FFC115E004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(20,'83891d7fe85c33e52c8b4e5814c92fb6a3b9467299200538a6babaa8b452d879',154927,'bc5cd4a70a0e3038768b0b4dacc11bb5bdbbaa51a7a6d0a69aaed9ab49451f57aa1f702921cf8fd5e477c4f06353f7ae69c5ce347a1307c38edcb9619ba9709f',1549270000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000001E52BB3365405915F3B645A1CB004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(21,'2f0fd1e89b8de1d57292742ec380ea47066e307ad645f5bc3adad8a06ff58608',154928,'f5b79d98c8c45e396851d32aaeb4730f0ffe2db82e36a6f8ba6b139a5a4fc6ec7e0e7a4c304f12a3b8ff41ab648a2d4b17689b7ea4c037b12a62a03988bee963',1549280000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000001E52BB33C94000000000000000004C4B4009556E69742054657374',1);
INSERT INTO transactions VALUES(22,'7cb7c4547cf2653590d7a9ace60cc623d25148adfbc88a89aeb0ef88da7839ba',154929,'7068c1abc38664730e4b979aa4d3beb7131c65e36cf7aaa2852bbe3a0b74783eaa0c7a7ed52ec04b5d6865faaceb23b41390ec93f667cffe8ba9cec6757bbba9',1549290000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000000A00000000000047670000000002FAF08000000000000000010000000002FAF080000A0000000000000000',1);
INSERT INTO transactions VALUES(23,'8f11b05da785e43e713d03774c6bd3405d99cd3024af334ffd68db663aa37034',154930,'2b7fef6e9069f1a2f44e6eb08f0f5e32033d0048fc3cfc526237a4c4ced59590dbacfa4bfe95b894bc21658cffb2908b85280e6cfaa1545970bf2a724ceeea5b',1549300000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mvCounterpartyXXXXXXXXXXXXXXW24Hef',100000000,10000,X'',1);
INSERT INTO transactions VALUES(24,'452ba1ddef80246c48be7690193c76c1d61185906be9401014fe14f1be64b74f',154931,'efd744787f5fa988aa515f4a7d14323969ab838c70a3d6d3a029ddf6eac7dd74568b09659b7756eafc7b6e410d8e5f5ba921d9a454c97f6c6b72ca7da37b5c58',1549310000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc','mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',7800,10000,X'0000000000000000000047680000000000002710',1);
INSERT INTO transactions VALUES(25,'68aa2e2ee5dff96e3355e6c7ee373e3d6a4e17f75f9518d843709c0c9bc3e3d4',154932,'09614b8f64a6aacc740150eab0bbe7aaef9045825e188800d44f8a5620afd0cc71f8a354b2d061b8cf2be47434963ee9709103d46151d9c18f80366b61d33eda',1549320000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'000000153FD33333333333330000000000004768',1);
INSERT INTO transactions VALUES(26,'58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d',154933,'d08f4dd0524762d7ebb5939e2b73f98c2260c8f2314a93b468e983e13a96639477f2effcfe51395687508cf6f0cb2de65e818396e9b3adb4a499f3d8cb16a638',1549330000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000005000050000000000A82D5F6A886D74C2D4B1D7A35FD9159333EF64BA45A04D7AEEEB4538F958603C16FC5D00000064',1);
INSERT INTO transactions VALUES(27,'77adfc95029e73b173f60e556f915b0cd8850848111358b1c370fb7c154e61fd',154934,'a519de47aa8c7eafe6fc8a4df5f5f05ea4bd27e41ea67d83555417146a35bbab2529ceff400f46163eb539a2c846bd8b8ee9cc87aefcce7b17054decb392a5ea',1549340000000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',NULL,NULL,10000,X'0000005000050000000000A82D5F6E8BF66CBD6636ACA1802459B730A99548624E48E243B840E0B34A12BEDE17EC00000064',1);
INSERT INTO transactions VALUES(28,'bd4fc42a21f1f860a1030e6eba23d53ecab71bd19297ab6c074381d4ecee0018',154935,'bb8f4a793ea7c9ecab809a8c210ec05858a8241939ee6d12e283e2ad119ee87ca2078f81a3c295bb527766dc2713b90793ab8a518db9fb4f2967e43f245ee0fb',1549350000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000005100037A4488D61ED8F2E9FA2874113FCCB8B158F7B0780592032E4D8602A3E8690FB2C701B2E1DD546E703445AABD6469734D77ADFC95029E73B173F60E556F915B0CD8850848111358B1C370FB7C154E61FD',1);
INSERT INTO transactions VALUES(29,'1f18d650d205d71d934c3646ff5fac1c096ba52eba4cf758b865364f4167d3cd',154936,'3af58b36490131f828a765f13708b818c0a4b7082f2e0ac7d8cccdba7cd77fef40b07f115e453279ae7e9cd47f01ccdf9a23702634ab9793be5533d67c348735',1549360000000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',NULL,NULL,10000,X'000000510005FA765E80203CBA24A298E4458F63FF6B58F7B0780592032E4D8602A3E8690FB2C701B2E1DD546E703445AABD6469734D77ADFC95029E73B173F60E556F915B0CD8850848111358B1C370FB7C154E61FD',1);
INSERT INTO transactions VALUES(30,'9652595f37edd08c51dfa26567e6cd76e6fa2709c3e578478ca398d316837a7a',154937,'0e82b767d5eef083b2547f3765bc77838ec407b1538acf5a0eb2f153665b65d9b499e7e716db7daefdb8852a411342a9d2ebfe2f4f93e9bb09d5a9ef03cb7cf4',1549370000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000005000050000000000A82D5F6A886D74C2D4B1D7A35FD9159333EF64BA45A04D7AEEEB4538F958603C16FC5D0000000A',1);
INSERT INTO transactions VALUES(48,'5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e9',154955,'04b4498e214f976cc2daa71ef3d694ed283d98d5153f51dab0fd6ae3ffcc10bca28423b6f437723d7d366d71e8583cf444332cd82ffe30d801e17c1d9e5616a9',1549550000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000005000050000000000A82D606A886D74C2D4B1D7A35FD9159333EF64BA45A04D7AEEEB4538F958603C16FC5D0000000A',1);
INSERT INTO transactions VALUES(49,'6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b',154956,'84847d413464cf667c6a0c701219c3d74c89c5397b7c05b8e0605e719db735d2d5631d34c78be6d33e3d3e8dfee5f408cbd8589f6ebc3467363b5cd5e0c976f2',1549560000000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',NULL,NULL,10000,X'0000005000050000000000A82D606A886D74C2D4B1D7A35FD9159333EF64BA45A04D7AEEEB4538F958603C16FC5D0000000A',1);
INSERT INTO transactions VALUES(75,'86be9a55762d316a3026c2836d044f5fc76e34da10e1b45feee5f18be7edb177',154982,'766110ba2b50a1c0b743164d74871882e6b4a5fbb5082a4c37ab4e04cfa8aa8eaa710ba9f7668ba0141eb9e585586c385a0f17dc1c2cf55f50397ffc18717a2b',1549820000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000005000050000000000A82D616A886D74C2D4B1D7A35FD9159333EF64BA45A04D7AEEEB4538F958603C16FC5D0000000A',1);
INSERT INTO transactions VALUES(76,'72dfcfb0c470ac255cde83fb8fe38de8a128188e03ea5ba5b2a93adbea1062fa',154983,'2d0c386a1fad12d0b44815b00f9ac4e4f518f334b620920197591cf9f27ff89e7f48ae831ebe91664402088ecb5ef4e751964dfa52c424c17666f55ef997a7e7',1549830000000,'mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns',NULL,NULL,10000,X'0000005000050000000000A82D616A886D74C2D4B1D7A35FD9159333EF64BA45A04D7AEEEB4538F958603C16FC5D0000000A',1);
INSERT INTO transactions VALUES(77,'08f271887ce94707da822d5263bae19d5519cb3614e0daedc4c7ce5dab7473f1',154984,'c2b0c5ebf63c897a6d6f11f0ed2891ac1ed874de7f4ef481e26f26af44e5bef76907b5b672be3b4b1ef094c058931631e8c48ade989638d56ced718b81c10ec4',1549840000000,'mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc',NULL,NULL,10000,X'0000005100037A4488D61ED8F2E9FA2874113FCCB8B186BE9A55762D316A3026C2836D044F5FC76E34DA10E1B45FEEE5F18BE7EDB17772DFCFB0C470AC255CDE83FB8FE38DE8A128188E03EA5BA5B2A93ADBEA1062FA',1);
-- Triggers and indices on  transactions
CREATE INDEX index_hash_index_idx ON transactions (tx_index, tx_hash, block_index);
CREATE INDEX index_index_idx ON transactions (block_index, tx_index);
CREATE INDEX tx_hash_idx ON transactions (tx_hash);
CREATE INDEX tx_index_idx ON transactions (tx_index);

COMMIT TRANSACTION;
