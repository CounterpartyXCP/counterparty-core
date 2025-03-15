from counterpartycore.lib import config

CONSENSUS_HASH_SEED = (
    "We can only see a short distance ahead, but we can see plenty there that needs to be done."
)

CONSENSUS_HASH_VERSION_MAINNET = 2
CHECKPOINTS_MAINNET = {
    config.BLOCK_FIRST_MAINNET: {
        "ledger_hash": "766ff0a9039521e3628a79fa669477ade241fc4c0ae541c3eae97f34b547b0b7",
        "txlist_hash": "766ff0a9039521e3628a79fa669477ade241fc4c0ae541c3eae97f34b547b0b7",
    },
    280000: {
        "ledger_hash": "265719e2770d5a6994f6fe49839069183cd842ee14f56c2b870e56641e8a8725",
        "txlist_hash": "a59b33b4633649db4f14586af47e258ed9b8884dbb7aa308fb1f49a653ee60f4",
    },
    290000: {
        "ledger_hash": "4612ed7034474b4ff1727eb0e216d533ebe7ac755fb015e0f9a170c063f3e84c",
        "txlist_hash": "c15423c849fd360d38cbd6c6c3ea37a07fece723da92353f3056facc2676d9e7",
    },
    300000: {
        "ledger_hash": "9a3dd4949780404d61e5ca1929f94a43f08eb0fa19ccb4b5d6a61cafd7943199",
        "txlist_hash": "efa02dbdcc4158a598e3b476ece5ba9cc8d26f3abc8ac3777ac6dde0f0afc7e6",
    },
    310000: {
        "ledger_hash": "45e43d5cc77ea01129df01d7f55b0c89b2d4e18cd3d626fd92f30bfb37a85f4d",
        "txlist_hash": "83cdcf75833d828ded09979b601fde87e2fdb0f5eb1cc6ab5d2042b7ec85f90e",
    },
    320000: {
        "ledger_hash": "91c1d33626669e8098bc762b1a9e3f616884e4d1cadda4881062c92b0d3d3e98",
        "txlist_hash": "761793042d8e7c80e14a16c15bb9d40e237c468a87c207a59730b616bdfde7d4",
    },
    330000: {
        "ledger_hash": "dd56aa97e5ca15841407f383ce1d7814536a594d7cfffcb4cf60bee8b362065a",
        "txlist_hash": "3c45b4377a99e020550a198daa45c378c488a72ba199b53deb90b320d55a897b",
    },
    334000: {
        "ledger_hash": "24c4fa4097106031267439eb9fbe8ce2a18560169c67726652b608908c1ca9bb",
        "txlist_hash": "764ca9e8d3b9546d1c4ff441a39594548989f60daefc6f28e046996e76a273bf",
    },
    335000: {
        "ledger_hash": "06d41df64538460da5dd68a82d827f27941a60c9124d8cd144aecb12d72fe3ac",
        "txlist_hash": "8ab8732196822ab9bf85a3c835f57f45f300aee522ee6acd4c3dcd2a8b84f1fb",
    },
    336000: {
        "ledger_hash": "fab6b3a1439bd2a0a343dcb27ebf77e3a724cde6aafd64004ec2cf4d688d9b1d",
        "txlist_hash": "3e7e81651888f3b0693a238dba23b6b74a80408721ea06e3b0706fbe80b043fa",
    },
    337000: {
        "ledger_hash": "78768548c3835d17a4fa3d42e08018470bb16d9b76d2d5c6173ad544b376ec91",
        "txlist_hash": "035002021d8aa34d3646eb07226c5331edab7abb5496b4418dd6eb7a4a27b663",
    },
    338000: {
        "ledger_hash": "481d5d346fde3ae667403935019808f52788a7a5703557ad1c9ac37b7635c468",
        "txlist_hash": "0dd49bbd08bb165c8e0b69b489294e0687351871eed539c04edd884a406e5d35",
    },
    339000: {
        "ledger_hash": "167b2e53736b59290992b1c88f6fe3af3a435f5723bae48e0be070a25f8acf17",
        "txlist_hash": "96dbfd2cca865ee8b36cca6b89ec3cdc5435629392ea601b10032d81ceab7f9d",
    },
    340000: {
        "ledger_hash": "c5a7c10eed8e268d54bbe649b233ed4b0c57898cdf94eecea78923306d9bb6f9",
        "txlist_hash": "88dfe2e6709cf23e7e51050613f37487167d257ca105e7f6b9f125f56177b7cd",
    },
    341000: {
        "ledger_hash": "de580893516ded2c9e9594d1e9d300dff4c99a66db845624695bd045d8458b86",
        "txlist_hash": "505f22487819d7bcdedb8514e3b5450e3c69bfdbf9d9e63085e89b57c7d04183",
    },
    342000: {
        "ledger_hash": "aa1f12ed515480ed130b9c51f79f7f9c9bbdc66c666ba7b2f532e4bebf453b95",
        "txlist_hash": "916b19966cecc40270522ffae5df5819fbd40a4f8ddf40c8142d2a0e7f6fe1a0",
    },
    343000: {
        "ledger_hash": "b88149bb189e17b3d530e12bc691fa26c63e7c2b085f319550768a29d0b19fa2",
        "txlist_hash": "16554902068f5eb0b074b20f0a0135e1c7588387b519888e7dc5c8ae79629c3b",
    },
    344000: {
        "ledger_hash": "439446e3b0d2c519d0d956b1a2820fbf20c87429511c56f47a4dc35c4b4e4f27",
        "txlist_hash": "a3b4f1e9b8085bfa1297367b1b24ce19e34d10cd2ebf7b6e4a6e62cd58751ff4",
    },
    345000: {
        "ledger_hash": "885e413bb171165320771b5fb2cbf1a10f2f3a2e3ee81f6c3cdef546164a3401",
        "txlist_hash": "5f70479a7ba3e1f6adf6001c7c6a4dea3e9e3fdd54c7898a479b1aa5a732282d",
    },
    350000: {
        "ledger_hash": "95fbc626f6e74847115254fa90fa72920be30cfac27a3ce4cdb0709edd67c296",
        "txlist_hash": "d11a2526951885b0276d3df6bc0ff8567846bf315514be2f7fe8de0805ba80da",
    },
    355000: {
        "ledger_hash": "1722af3134891cd02ed3f7005c75c43966f24aa29741de33dd3f69263d34e9b8",
        "txlist_hash": "8dd91b26b261508e18e330479bc92a1318887ce3026c3c35cd195ae9ce5f2aa7",
    },
    360000: {
        "ledger_hash": "9cbd82c31ad94d3f8554332f6f85ba822fc5e80f65ff1681770e842525631080",
        "txlist_hash": "117ae080f4f86f320382e1da722500fdd4260df01c3129287ed1bc8b80e5d0b9",
    },
    365000: {
        "ledger_hash": "d65bfc094b9ad477324bd2afcf0405a099b60f98b09df465f37dcc74fe64b1e7",
        "txlist_hash": "c68e8480de4c8bb0cf015e9636e529818cbccd4c5134c5e7ce139d09eec47b93",
    },
    366000: {
        "ledger_hash": "6373abd1d42643d382e3636c36659615e0aca8b03bf10ce17e68faede643ac54",
        "txlist_hash": "ebdd62b666fef5ab3a45bc246f64df762d46907b6956fe60e06b6586512290f9",
    },
    370000: {
        "ledger_hash": "9767fcd7e86081cb6ae4d1a259eb84e96dcffb7fcea06e0bb3a585302efde551",
        "txlist_hash": "75bca9de463008bd3fd421c388b08dabb42c1c77b0e395549625337df8af3bcd",
    },
    375000: {
        "ledger_hash": "202011bd5dec945bb557ccb6dca40d8806b3113bcba558991ae7556f5abb0544",
        "txlist_hash": "db1d49c27239e7a839324cddf8ab3a4a4f04098b5b744f74839e21e1a83ac648",
    },
    380000: {
        "ledger_hash": "9c1c0a4fdae2a6efe10b17971ca23e88744ccd016bae4e769a707981515195bc",
        "txlist_hash": "8265728c27b79c7f433e82d293d82b0c5f4b4f8cc8edb7a422551360defe8a91",
    },
    385000: {
        "ledger_hash": "78698704135a9d12739e5388ffc62d01537ac31f0111125afe3997326901757e",
        "txlist_hash": "1c226d2190365440634a12feea9e61afe08f06cd74ebbdb88c9518e4ff4917c4",
    },
    390000: {
        "ledger_hash": "9dd60ed2df80dcf1eacde92f022ef1cd6189e990b86096103016aa81720cc9f5",
        "txlist_hash": "5b895f3e76278664feb0048b5988bf5a17deff6f73a3285e2c1e609b281c65e0",
    },
    395000: {
        "ledger_hash": "20e616dc24e6c4e1511911d0c5664ad482a3c6eea68eed0f20f85f030057b8d6",
        "txlist_hash": "455b0cae03f27b267721a7327eb4c7278fc279764d1e325c5010dd7449fba44e",
    },
    400000: {
        "ledger_hash": "c1ea6fd36e45e08a99d7815ea734e70746f1ea52673b2462cea7aa5e6879aacf",
        "txlist_hash": "b0384d33afffbc6b95d9fa7dc919ad217b7e5b4584a8fafe5867170c2c9400f1",
    },
    405000: {
        "ledger_hash": "e9c652e984fe8778c75a9a259d7dd51fc488db45b107a7998261eccc97feefd4",
        "txlist_hash": "27c374478e6496896399e7c3737e655d3e2955c474ad57fe63560bc7abd30dc1",
    },
    410000: {
        "ledger_hash": "b743a12f6dea4f74247dcf840f66e7fceb34aa723950f75ab280912f9b70b892",
        "txlist_hash": "87f008e6d6543bd4f2af8f2226d5831b8e97a2de2ed0e72d129b6508ad867b03",
    },
    415000: {
        "ledger_hash": "c2a48d80b861ae117aab0050fb3da17b75fc9b552034c56243e77714df879fd3",
        "txlist_hash": "f3b2ad7a995658ec1fe4fe57309688fef8ff8355f8e279363b622529e72f0869",
    },
    420000: {
        "ledger_hash": "1b29d285056116dd5b3d9ef28753cd2e2ae9d404313dc963cd5aca924601fe84",
        "txlist_hash": "93ab13a13f6f050613e38af7906e056ae2d990b514dc257d5fd280c44323ddbb",
    },
    500000: {
        "ledger_hash": "3ac2123d1145a1fe9298983e68305dff2f765f7126e1a94751570b3098b25c07",
        "txlist_hash": "dada8b2b5adf10623ce3c8837d2ae6159fcbe0c3bd9397c876fa74c0fa7ff2c3",
    },
    600000: {
        "ledger_hash": "32ccc85fb301ccf2e34fa0f97534eac3f1cb9f653d7ea3e3dd9b694ee3b6ea5d",
        "txlist_hash": "547886e99b32483ab77defb05c77e8d72489ea772daf5f02f4d59cec675a38c7",
    },
    650000: {
        "ledger_hash": "bd6ed168b65503faa6e85adc719a338122661a5c5e2c76c83a9c5169f042963f",
        "txlist_hash": "c346636c0c72e1f1059217aaba6cc7a70815d7a9125f1ebc0929539b3a761cce",
    },
    700000: {
        "ledger_hash": "d8761e5faa8094536a7387385b6552e3a90aa1d9236a9f4086b2d72fb9c67b04",
        "txlist_hash": "75119dcb47bc3a3c12dd6e926bb35f7eda9fa9c3c47861dbf22884b35143a159",
    },
    725000: {
        "ledger_hash": "56c00c623b7242c8392dfe8d3b95bf1be266aa4423ac61f4a31610933796022b",
        "txlist_hash": "45d40507b98c16506224384bfcb4e2fc978c272f86a8cec20202a50154a5c9ab",
    },
    750000: {
        "ledger_hash": "20017dda48d8155f4234d2faec1c1d2b26b36de155af682ca29c03272dfff8fe",
        "txlist_hash": "c3a4c13f817afb340d7a70a57762481538eb6d5ca6d887cd508451c9e31b101e",
    },
    775000: {
        "ledger_hash": "ba9ed00072b288500fcbd89d405530942f73e4d11988f0603213f98e0e5ffa5d",
        "txlist_hash": "af1e199546ca179ca9243686e286d39132d1f8368c1708ffe244b5fd66bd2587",
    },
    775500: {
        "ledger_hash": "ab2c75d1887587cc2da48e44882f27ade4f0b4d599bad1de3818ef3b9e7a2ec5",
        "txlist_hash": "a5d150736ec5870bd6bd50a727e928aa9402a1fe2b9c4b3ffd75c614451a099b",
    },
    776000: {
        "ledger_hash": "b230c6b3b3cc599233b5a7a6127beb27b4457c87369de9537c05ad5061a87474",
        "txlist_hash": "bf8c63ae77d4ffa05b907e3d41e315f234a7eb92bbe5e14d978283df4cd8dd2c",
    },
    776500: {
        "ledger_hash": "d111443c1e658c0deaf218805f324fca812187e41c32f93dcea3c9fdb5dab98d",
        "txlist_hash": "807634d11882129ae114d6023105521f5c17775a96429909db8152bea7ea4dac",
    },
    777000: {
        "ledger_hash": "3a966d738a23d93a12ecd85cdccb602c029d0d76d0be4f47852a3013bf66d067",
        "txlist_hash": "b9f44b5766c86bceba5b412f3b9173ec3e18cec711d08e709d56629517a5d7d0",
    },
    777500: {
        "ledger_hash": "e947aabadefcb4473ea5375176364d452d6808819a3ee5f365270d4d8988e98f",
        "txlist_hash": "febc3a9f489c8ae60f0826537b6bf5e40818fc5ff5e6ede2ab336b2afdee041d",
    },
    778000: {
        "ledger_hash": "9e421ec264f99f4e398b6b8efaa94102f378c86f3188ae75dc8ad6b9b2f5e6c5",
        "txlist_hash": "b4a961fba424c2b51dc5b41d5b356f749fd5ab09f3cbc8a2117ba2e6f0fc3de3",
    },
    778500: {
        "ledger_hash": "410d8b37c5b64d392e06724047cb5927c82fdff1a2f2b14249e60124f8fc93e1",
        "txlist_hash": "68c09634a9c82661280db26ff3448c4e7a026a8872de44a9ee6c19b231ebeb23",
    },
    779000: {
        "ledger_hash": "d073b3ea502cc42075177ae8150ec0e50d2afa2b0b187bfafc5be762dd4245b3",
        "txlist_hash": "b9852b25f2303e14116c996ff256187e1490ecad664bd63ab074430640742424",
    },
    779500: {
        "ledger_hash": "59629b536263748b9a81f94265c99d987d9e37151926b17254178629f1d295fb",
        "txlist_hash": "7dc3775ae5568cb28c1f6831440d2d2cb3c339ab8aafb8321fc3965b3c2228fc",
    },
    780000: {
        "ledger_hash": "1fad5ae4be9dce889db41cd13b992a46246e02bb3b96f05306a898f077d8c66a",
        "txlist_hash": "0b619aadde21319afbecd7ba02f74e2fb3e02383598e6641e4919ee977d3df6a",
    },
    780500: {
        "ledger_hash": "868b02030232a593bf23a9440d08ce2de7822a84cdc09140ad12475fb82edeaf",
        "txlist_hash": "53173731025ce44af80adb44516d8ea10fc1117da35da22cb807e4c180eccc2c",
    },
    781000: {
        "ledger_hash": "88888193a6e4723dd1082b1e67c4f57a3956492d13fd80f142edc8ef03d23978",
        "txlist_hash": "42960cb41952e91ae00d8bf709b7464b35ed52cc020e635824044244aa7e1457",
    },
    781500: {
        "ledger_hash": "32889aea7c59e5498b27e1982333c46aa78686c6c5c39d24a772c46dae6707f8",
        "txlist_hash": "e56c868599b1b09879e1793ff5ffde058c1eeab1e6773c2753c4795a9a1b9f36",
    },
    782000: {
        "ledger_hash": "145341c8784853611ea2e446a7537d47a071e272ebf130950acb00e1fa4546fc",
        "txlist_hash": "5a73264ca18ead18d3403bf6da2bd05882030db743044fc02f064c84b97915be",
    },
    782500: {
        "ledger_hash": "b16645210f0527566a48241b8bfafd5b6883bd36a5f754672806751885365159",
        "txlist_hash": "b2e352893f0a953d73c7ed4f5b77adf04fe2651662ee35f7274bac5d9b7cd2c8",
    },
    783000: {
        "ledger_hash": "620a26e186affb54cbf53ce2b3f3f1f204d35f42ae0c5495602498824b4e035d",
        "txlist_hash": "6e791eb3c87cef3c10d050eb7c4b7cd4cb78b9164aa99b64be1fbc294e299316",
    },
    783500: {
        "ledger_hash": "128046210de53e3d24f395c0a557e57fe65e0ee7fb49d0ce95d260c4e8408cf2",
        "txlist_hash": "00a0aa48446c3dceb173c9e4448532cb5caf617ae8591e496bdd1be43900345a",
    },
    784000: {
        "ledger_hash": "88ea8e17c4415e4c9215f1ea56c2d17980f3b4c47bc261b128b7cd5df76630c4",
        "txlist_hash": "3f21556b97fff284962f07d0ed4a303e79ef03ce63764ba2ec26c43aa1634969",
    },
    784500: {
        "ledger_hash": "67ed396bd11a7a384422f46cf3e8fe4839052b5e40a48346d3d82d79774196e5",
        "txlist_hash": "9edda17ac77ff9c1c2a35d709523d2dba6588d86709758ab642136fb5bfb202a",
    },
    785000: {
        "ledger_hash": "62b11b418052447539bcef8d6dad828a648159f91ec855a6494d9265ce08f52f",
        "txlist_hash": "9cf9dd25a52a86d257c4abc7cc215923a482e5d40b274ec4e3c49cab429ab623",
    },
    785500: {
        "ledger_hash": "5445d7873d6abb5d5cac9b0fef5b24c23d088fa6834384068775d4e17594493d",
        "txlist_hash": "ef115a1dfd46735c8c19a51c82f37021e6b01b7bdbbd45ee26d08b288103ae78",
    },
    786000: {
        "ledger_hash": "1a78423803005bacc707aa850ade0342a0382d431114fa63846758449f83e88e",
        "txlist_hash": "9334f0e2acfbe2a1b9c8216b10408cf582e41d3bb4c11bfd7286a06a77aac9bb",
    },
    786500: {
        "ledger_hash": "f98fedc406b0c6feb45468d6ede7814ba9d9222052d2837ca27474250c45ed95",
        "txlist_hash": "5b5ec49f50bebedd195cde5810871f949d4e015d1ca2c80783a3caf550395875",
    },
    787000: {
        "ledger_hash": "d4aaf0023c8cd39602099409bb1d90e75f9fc660c8c52c3b82737bb132e16e38",
        "txlist_hash": "c6c1896f1245cf976f8df2621fbeb938f1f6e177ce9b48cb9f25bdfb6dc51b01",
    },
    787500: {
        "ledger_hash": "784b6c1c7f79d09fff52112b0373501fe572c8103a74df1e21c191ecbc232322",
        "txlist_hash": "ffa6014b628e17ae5d0a6f3e1a80f302d78e0c27c3effde9ad23d52cc4e3fc35",
    },
    788000: {
        "ledger_hash": "082fe7dbd0cfcd6207ac1e8c1777d36834c67b03ab3d1456bf9fca5c2cd47b09",
        "txlist_hash": "e808bce1850f585f090dd218d8d7b7f2028679ca471c282bfc06ab759023668b",
    },
    788500: {
        "ledger_hash": "1610e9b54a46a5b2dbc925a08e64610359f1ec5fa764d8da766e95ac51a8d600",
        "txlist_hash": "ed0d886092520fe1de953c6199808733c6c4fbc4f82fcae20d23a52d9c26aeda",
    },
    789000: {
        "ledger_hash": "ef5b5bf97e2f5f8a0f98eb6cf6b78a339fb69f8d0c489b6b2a870feaed7409a8",
        "txlist_hash": "7f87b42785bb6c5e13603e6aa6cac1f51c0a0f55fe522083c5c9d8e7a02ec7bb",
    },
    789500: {
        "ledger_hash": "2c897edb20857541ce1ee50744033a64729fe480c910ae7ff004a9aee29dbc75",
        "txlist_hash": "dcb994fa2b99eac3ef18026d9a6effae0d3dad5cb251c01143aae295f4e74aad",
    },
    790000: {
        "ledger_hash": "c22449d33c4852b699fede3092858490eab498ad72b64121a7e51269a44fe094",
        "txlist_hash": "d5d0644e4d8f1bf57298cd07e890eec7ec5ef4680bbbbbf7e78ccd5ecb2ddf0f",
    },
    790500: {
        "ledger_hash": "1d304f536b18261f9366c2b1d42d0f1bdcda4d4daad986a00a181de01b57428e",
        "txlist_hash": "ff29969fbca3d875333eb17a962c93bfb78c472b9d86c105026ab0e84fa6a6d4",
    },
    791000: {
        "ledger_hash": "6b018480ddf559b9b777263ecea0aa301ce9f8f7d87698d3e2c94f7c738525d2",
        "txlist_hash": "939c0e3285bb4bcd1151fe95fb36b206d5f802cda277b20179a3a9cc026b09a8",
    },
    791500: {
        "ledger_hash": "4c29df1b7bba3b255ce9d1439b1b91af50886efe8808c2a26e6834a9719be3f2",
        "txlist_hash": "9bb90ddb5f21ca6589bd6694900eed18ba2f8b3609e674068f44e19600015e7f",
    },
    792000: {
        "ledger_hash": "8184dcfc7e7d449127469ff908e3b123b33d91d608752a3a9f93c0c14eb573ac",
        "txlist_hash": "ab9a75f51d9072a345f830932a03498f392d9e753b7da4bd36e96534366e358d",
    },
    792500: {
        "ledger_hash": "0214351273c9a0314bc248e9c446556f032dc70234e00581cb5ef8b11aa6cee6",
        "txlist_hash": "a95a572ae65c053cdb7f90f03454d4b249d246912870861ba9f8550afb227374",
    },
    793000: {
        "ledger_hash": "9113c9d3b4a15d50c914eebde1b3dc73cd2ebe6f6417c3f4ffbbc1c5203923e7",
        "txlist_hash": "78f11dae00aaf9742bd015f48f51f7819bd63805aa951d94d86dbeaf9f1d2caf",
    },
    793500: {
        "ledger_hash": "55802e5b6f1a02d2f84f0789a3ceed365a0365e95ae5d3e6caf72019f6075a83",
        "txlist_hash": "ef112576964995dfb5964f3229f12e170218961849406a2fe4de0f5ea4e280a2",
    },
    794000: {
        "ledger_hash": "7cbc0f6030cd84e737416f4b53d0d96c53346022cf4bef15a8e8ddabe53ff659",
        "txlist_hash": "07cdbdf23af40ba53155cfd12c6df11f91a4d2ffc7bee522b48f47b35fdc837e",
    },
    794500: {
        "ledger_hash": "ef96e16a97b208e83c3799c7bb30e93cbd4a645f35b9a051037a2baa94032215",
        "txlist_hash": "b134ce6c494b316038b927b0e5934a57fe46e3cedbb49e5e1552ed28e78cd408",
    },
    795000: {
        "ledger_hash": "4b959b9aacc6d6bcdc17ddd96ae02ce403a0e4d44d72844ea5be6b7344263ce2",
        "txlist_hash": "d960d3c563233cef9758b0464811b562e72affad91302d48c7111856ebb549e9",
    },
    795500: {
        "ledger_hash": "028df12a57819ad133712e5a357408a555ed30506b9a8640dc9811ebff0fb011",
        "txlist_hash": "5082869aac0bf53b85038c768c97922faf5c820b4766fd98b6321a2da5db1e37",
    },
    796000: {
        "ledger_hash": "2f022915f5318acb4e48ef7adb6fa218ceb0e0653123f1c63c0b0915fc1e2e10",
        "txlist_hash": "5d6730fbce340227900967335a952f7be8d0ebd8a28afb3acc16dfd34168bda5",
    },
    796500: {
        "ledger_hash": "f9d5ecd69958b0ebf34c1801d3c056aca68157d8d7a5598eb3ac26aabb65a25c",
        "txlist_hash": "d1f2cfc4eac60a04082267ef4ee28eaad6378e73819256c675d8797e3e886257",
    },
    797000: {
        "ledger_hash": "a35fa6be9ee08cd12f2e2457f86537045bd9b89aa9285cb9319a6c30ab0d9456",
        "txlist_hash": "8ebfaf0fdebd03ad977e845bed528c134e1eba105ee101627f3bf3389b239004",
    },
    797500: {
        "ledger_hash": "f778fdf1e17c3d563fe3dd605d3c0ae1a4e9ab26564b4ce7ab4fccce9001cda5",
        "txlist_hash": "1d582712b1969711c5e217d3a4af94380c39825e49d98f81a2416e445424fe22",
    },
    798000: {
        "ledger_hash": "5e16a1033ecca39f8b67ec1784e444ce7887dc8fd2844fdd49bd438f0e9e3396",
        "txlist_hash": "a678bd1773897b2aefe3a316d0dcab64d5ce6c13cb570e6c42fa17adb9d29745",
    },
    798500: {
        "ledger_hash": "baddde47b9a9507a8234a051b99e306fb1ef737fba736b2cd1a3c00afd38b5b6",
        "txlist_hash": "22c878fa975dbd37fd8ea74970a9ff164b23b3bd2425d1ddca71d4f547a30147",
    },
    799000: {
        "ledger_hash": "0cff84ff61722d989c474ffa18e368beb3d189b38b2b7494d1df1b56eb911295",
        "txlist_hash": "31134af6f31b594d430d14365c8f585ccef9a28a58a536bacb0682b11e77ef65",
    },
    799500: {
        "ledger_hash": "af524c4fb3a6a3429b0fe265ce572d7697d496c346f054e0ea03acba47da2c48",
        "txlist_hash": "0fd7402099497fb391d0f079adc2555ace0b887402120b0c44d641ffcd6f4e67",
    },
    800000: {
        "ledger_hash": "835e01803aba670465d59f67d7726ef7fd83e382ba2ebdadc8c21ca68c249d6f",
        "txlist_hash": "aae415b9cc0c9c9f5c2805e2b8baa315237d83b56305a176d0431f1bde3acd40",
    },
    800500: {
        "ledger_hash": "69dd3de90259de05987c0930d753c6914a1b2620bad77b2ce9c6e123d5bab937",
        "txlist_hash": "6e744a72395d33b1ae25aa078d0e254a06613a2430119abbbb0733e99b1ad247",
    },
    801000: {
        "ledger_hash": "d2fe264744013cdc0c89754b5d07f96d38800c0353b3d5465e6f76cac9edce32",
        "txlist_hash": "38946dc727ae3c0c3908e3a8f5c3a2c2aa43dce98928df67b298b388de40c74a",
    },
    801500: {
        "ledger_hash": "17be49524954adac73f61fb1b162e978cbd3b4c68fcfefac6d7f61b4229de8a5",
        "txlist_hash": "885686d6879eafa03210828cb3f5598cb2c55614636d39ca80e699e6f54c6aae",
    },
    802000: {
        "ledger_hash": "682c76aeb8b8ab5aaa8a713f554c825827e6f22921c2c023fdecd2293a3d2061",
        "txlist_hash": "c860df3399474065a231289a57bebb30ea446850382b7cfb9c58c17793172189",
    },
    802500: {
        "ledger_hash": "996be479600db9841b6a3421bfe95dd8632a02c89cdf4119eecb806eacf181a2",
        "txlist_hash": "7cb5704ecd275e03664286abe79f32e98edd1ba4eeacb9fbb8bd9e70962257af",
    },
    803000: {
        "ledger_hash": "0559abd9654292e06642896ca07b3150aa5416503a9e7f43699e9723fd618b7c",
        "txlist_hash": "914220bd975b0d1161e2bcbbfdf633e68b4a602ddac3dfea420c215ae9811b39",
    },
    803500: {
        "ledger_hash": "0035e6d714f0e75d8b6a4ec4742bd78a05b23ad09548ec019ab585582116c07b",
        "txlist_hash": "996ccc1a3006e0d596315e297a4734e4c9b5236f4c9ee871e36b1c82723985f9",
    },
    804000: {
        "ledger_hash": "eeb6224851d60bcb5f94881bd44ce0651a30d025854da562255d59528e9132cc",
        "txlist_hash": "7250348049658ff9d2d78be7671c8588e0e61676bbdcd0674063451f0b670d2e",
    },
    804500: {
        "ledger_hash": "0db8608a150b7e6a77b143534dddd1f38c23875bfc51ee627fb39bd48239b194",
        "txlist_hash": "8f0d475b9a168b7d60f6212f016ec9939d7516b92ba551ec18747a5007016ee7",
    },
    805000: {
        "ledger_hash": "e98cc85132aab4d80c0aa195daadb6316e1963594ed5b204a1976c2e114dc9ab",
        "txlist_hash": "a6c2c5d72ffeff71d3a5ccc20b584e40b9d1b761e8eddb52a8f62adb51c51216",
    },
    805500: {
        "ledger_hash": "2498dd962b8fe3c9c91d8e481090e8aa86dcdd0da4962f03150ff8b72101bf16",
        "txlist_hash": "41e54e3fe36ba5979de01c74a02b085ba43250e0d5d64522ac18156d830ad0e7",
    },
    806000: {
        "ledger_hash": "412307729cb70b466a47b920e15af46831dd9e629c74814cbbc0cf365f6ac14b",
        "txlist_hash": "a1f1e34b310645a6994cb4dd4121fdc3f09f37279b705bde8781a833c41b0e21",
    },
    806500: {
        "ledger_hash": "acbd9420ee29c08963ea28eda3e75822abdd51804a90daae064ba28c9193e111",
        "txlist_hash": "b9550eb4dffb7d36db58e44d1cdc9c9f216dc804d1a88a26a7ad015f612ce82d",
    },
    807000: {
        "ledger_hash": "d4a7da284ab10f87d69119d9ab982169def7afc27c9880c9b5ac8c439869b4cc",
        "txlist_hash": "8be1314247c47ad0f2a643820137e132fb7e0b95496fb4bbe0c73d199cfedaa1",
    },
    807500: {
        "ledger_hash": "d2f28874d64917ca2d436be2d9d44b4dddf8605bb7ab4d151eb2d3025fb5e9a3",
        "txlist_hash": "5f309a3a630e07b760b73bc92174ee789833f2211310bc2f1576e33161d2d24a",
    },
    808000: {
        "ledger_hash": "bdd88573a227a584c3e02e8ede5701b631ed3ae558c0f9cbc6c104bfe27b4126",
        "txlist_hash": "fad23def0d89dc1b58e88aa216c3debfb4d856fdff49ced80d3f8ad2e8db717c",
    },
    808500: {
        "ledger_hash": "bd6bd8788227e3e97dd01dc8335a9ee9017c34dd5701277b491c8f7726512c77",
        "txlist_hash": "bc7068a0b292c890bfc1941613a31e25aed5375e685c6aadc5098c9df11ea908",
    },
    809000: {
        "ledger_hash": "87fa43bc4dee049c515708c156e5992f10dbc1072ae88fad75b8fe633b482be1",
        "txlist_hash": "c2ab61a001b138b94cc7e44c9ceedf767bbf5ce2b7147a3b96480dc04fca3119",
    },
    809500: {
        "ledger_hash": "8f7c53596bc3c467778a7a2dff947b53e571ea72272274648eee720f39ecd7ad",
        "txlist_hash": "9c8522adb6e0892f4babb107d39fcc5f7ddf7c39c52c3ffd47d6a6ac6414b410",
    },
    810000: {
        "ledger_hash": "39daa5ab2d5150da376f6099771af121af54241d0013551cacfdc7ce24089ed8",
        "txlist_hash": "7a74fa3200f9bc63a0bb0b6342fbf9a6dbd475df959faa4f4168eed09033d043",
    },
    810500: {
        "ledger_hash": "83aeea0ef8277b22e96c63313ad15cef14fb87b972ac7c8fcffa121e2c56f1a2",
        "txlist_hash": "71a334ba5eb9da23c809a0322dc7ae4b8a9d81913082397513a0e71abe8be97f",
    },
    811000: {
        "ledger_hash": "7fe158342cf5101fe45b3c5c3b0a84e126920eb4aced6ab410b6a32bdd8d613a",
        "txlist_hash": "cedad17c701575f0e0b400caa9a6ccb2e4acce4bdedb1f6baa30452d893dc898",
    },
    811500: {
        "ledger_hash": "7bf3a02143a050549dd1d4d71e3ac2403f057a64120862793f14d4117dc5fd5b",
        "txlist_hash": "2e6be171db2f314ea3d3cb727e2348ec7a3f6d4ca14e506a7249d43cad4aac47",
    },
    812000: {
        "ledger_hash": "28b54913fe91856f294c20df4734f7b893600f849c2f44ff030768e745e30f0d",
        "txlist_hash": "6a9fca78fb6e9a2dfa754d30bf45410cb90e1976d7cae770c72a854ca3218127",
    },
    812500: {
        "ledger_hash": "48c66d2de2a5ad34832841e62a82b6a9872e9dea01d40cdf66e9567caf6d2e2d",
        "txlist_hash": "2fb0ca0ea0bab19363e1167dec998380c8bc2128fd6002d93c3e521306f08d3f",
    },
    813000: {
        "ledger_hash": "7eab38af3c6b4d530962684f53cace3bd20294092e7e3e1bf1fd9f620afdb9af",
        "txlist_hash": "8fd3832c90fe2c0b5fba522ca3775b7f3c7aca5d014b4ab02606fdf9a4383ab6",
    },
    813500: {
        "ledger_hash": "0b2209449b97f6bcd3e5435d0608ae46bd58d47a16352290601c237c86b1fd12",
        "txlist_hash": "83ad312da55e6572e78fd0981cb361da98ca37110cc2488009447e0764ffff4a",
    },
    814000: {
        "ledger_hash": "7ab7b94bd7e41183c43b74168ec8ab88eccd63c27b599fc82969ffbdf9f69712",
        "txlist_hash": "d8a58bd3151bba1cce05ecbc10d866f884236327cf02d38c4e57c0ecd8a38b7d",
    },
    814500: {
        "ledger_hash": "bfc22992a47809741318a9dce0df82086bb52cbb30528a96fae823219cba3716",
        "txlist_hash": "898d91329788576db6d318879df9baec53a2d31adfeeb7155ee03187ec711699",
    },
    815000: {
        "ledger_hash": "468f3f35a7b36acd5e1d1ed35bb5f4d0f59e0eae4eee25fc218c5bffed4378bc",
        "txlist_hash": "6e244194ea25cc4aa652bbcff837c105dd40fbb6064a71c33413938009c836e7",
    },
    815500: {
        "ledger_hash": "1522653f1a44aba373e5566ff6054cc859cbfc9fa6deb931bad124db339c706a",
        "txlist_hash": "c59fa0e4760b2ce6198fc582b4b03aa1f39d5df7bfcf7a3416739d06d6e8bfc5",
    },
    816000: {
        "ledger_hash": "b2ee3deeb6e3bf75358442e2e5bbe3b01e189eaa8f6a4da0b481609de222f12d",
        "txlist_hash": "fd361c20504cd593977bfbb0a612e76efd00bca8c474ea64c61d581bdaee52c0",
    },
    816500: {
        "ledger_hash": "ea378fc98675aec041bce57ad3001b8da96d6ed73c94c777d17f4ad9948e16e6",
        "txlist_hash": "bffc8b490fe4dabf6818bf5134539a066f6a1ee9750df68b30809570da72533f",
    },
    817000: {
        "ledger_hash": "c943e2550cfde4e788e45a59b12b697ed6c90b2a95b19a22959643047e917c86",
        "txlist_hash": "492c454a091f57237bf4864c002dda3acf84da94f1f30204898f0aaccfbf6f38",
    },
    817500: {
        "ledger_hash": "811ecbe290c96f67fd0024f3b4c8619d1feb370a3bab1e16cb4f13ef78049257",
        "txlist_hash": "dc1d3ef54e69e068076997dbfc6bac615120b3458a6fe3dfed04e29d2eeb8d0b",
    },
    818000: {
        "ledger_hash": "7ac0b51094ca369b8c48b32108cf41a0726f4ccbf8eb73ba4742fb1d6d57bec0",
        "txlist_hash": "60270699398c35a8f5a4c5b64df127829b29fde98d03160088a546896ea422c1",
    },
    818500: {
        "ledger_hash": "c9ef72367706d40a661701733e21b8653592a65675f643b38a6a3560316862d6",
        "txlist_hash": "3c5f4b132ccd8d16e88bc3902b890f657a86ba83ef2a885e86af5c47bdce1f8d",
    },
    819000: {
        "ledger_hash": "b2fcc13a24222e162fe617f9b65539bbbb26ca1fd93606225ddc01c7728df927",
        "txlist_hash": "1f8ed3ce5228319a40f91c5bf68dd509dae6dfed50d1fb0ece551b8b35dfb3fa",
    },
    819500: {
        "ledger_hash": "06d3ea5ac968325c059c9cae9a26cbc2ebc782207909c21bce2c8dd7e2099d9e",
        "txlist_hash": "d19d04ab7d11c8fd4db6354400586f27d0ac67fcb15de9a12020fa8d760e189c",
    },
    820000: {
        "ledger_hash": "c1396ef1d24e6d91b35c19cc0c77d548f733fd157c3997c479d88c39b61308f7",
        "txlist_hash": "f31d2ab91010c67199e66a65814c7f9dcf385bc004fc28291585a2e6305de78b",
    },
    820500: {
        "ledger_hash": "ba98e7ce3442478a637c15971248d2ba2e9cdcbfde5d1cc41a8a20c5f99f3fe1",
        "txlist_hash": "db638ac0c675dfc79f644d84e2a021774c987f5cc67b869c53019170e230c459",
    },
    821000: {
        "ledger_hash": "3ff69ed9b4b02669910de04815c74b435f90a7e710f93b306af9fc5137b52397",
        "txlist_hash": "5ba757dfcc081a6b69cde024b49598b4ecad0d65dbca478f1aaa8139d14c20b4",
    },
    821500: {
        "ledger_hash": "fb39fe3d8db5b204648dab9a5101289b86dc0753e00a7e5823ee8e832133ae3f",
        "txlist_hash": "bc2f2bf950e74ef1ae610226b24d8b92233523c4026bbc2a466177ce55aab07f",
    },
    822000: {
        "ledger_hash": "246fde6117847546ad58f433c8ec612c8d3f70f76746b4e2cd42f0889dbeb250",
        "txlist_hash": "933a8e3ba609166b22622f1d4066cc8c2121587a85acd3ee1557f354c088213b",
    },
    822500: {
        "ledger_hash": "84c23b4efa29204ba8c17c6021808fa6884c894e68870acc8792168e8aab4ab6",
        "txlist_hash": "7ad00ed238e84af030dec738b0702f9285ec6cb99ddd49dbae89e3230e472287",
    },
    823000: {
        "ledger_hash": "841df3a3dfce77e498a7655bd26a81975a6361ee658e28c45eb26801919b255f",
        "txlist_hash": "8dc06620957e389d82ee24e775b99d5e81b83a089f4c618ffa11f5c21534a04d",
    },
    823500: {
        "ledger_hash": "5412b27f65c89b41d549ec3f66d9cfa1bb59c089118ec7c33744352f249d08c3",
        "txlist_hash": "e574d751952e682be13689519b598b45e0c97f02ea78bafb2d7f5bc4ee7915e1",
    },
    824000: {
        "ledger_hash": "934ba8b0c47f4e3cd747a453a269bfb7a0a7e9a6efa5b524dbd7fec1e01abcfa",
        "txlist_hash": "d2e5111d60ce77cff8d86fe02f4828f082dc5a4a6c16a8a8b618e7e320b9a79c",
    },
    824500: {
        "ledger_hash": "e72ff0594d0af112e9062632dedf9093e552635ee383f0b8246a22abc84f1ef7",
        "txlist_hash": "2f35730bda0a24f5073b6bc5f75efd882012bfc7aa836dae3fb9bf0b47b76d88",
    },
    825000: {
        "ledger_hash": "20810c4ac5fcac5f1b1e29b919fa270875f57949885c20deca8267dcebb39162",
        "txlist_hash": "347ea524566c9fc32890b2c489f1858391e2d7e059ff4440575299251d1fc3cd",
    },
    826000: {
        "ledger_hash": "9b92062f20d2155ec4842c36aa45f575387b439f9ef8824da940411831112ec4",
        "txlist_hash": "4275764179b273d12e577d385d45fb77eaecc207d0f8316040fe6a4f6a0728f7",
    },
    827000: {
        "ledger_hash": "27c6a7ac8fd135977c4b3a074cbd4019cd013313b5701e142453515f070c42ae",
        "txlist_hash": "7258d61bccaa93c2a0a1d0424322745bdb390ce5406fe8df37ae463bb3a9c727",
    },
    828000: {
        "ledger_hash": "692f9fbcb293353f8d0dfa60e34ce61a45613f0fd3e1290539375167fa26fd21",
        "txlist_hash": "c2756dac017e88d259474ac81f962fdbcbb01a326da1bcbcd1d2fd9b2cc33ed1",
    },
    829000: {
        "ledger_hash": "9214253971aca45038be3fefcfa35eb52bc57a00249f10055dc3572bb1de43fd",
        "txlist_hash": "99a9890a6ef8b484a860004df423761f7ebc66ec747840b1878302836d046337",
    },
    830000: {
        "ledger_hash": "57207a541782ce2b637d7f3bb04bbce22830a1d4caf5d01d550dbb5a9bc7d95e",
        "txlist_hash": "5b35f0ec9d5cacceb3977fadb899144501285bf77145b1c552cfde60e17ef7f9",
    },
    831000: {
        "ledger_hash": "e2dfdc4d22d7dfedcbe9ee3580e148d7c141082b16f23604c8cb135c1a16fa7a",
        "txlist_hash": "090e16991b9ad8212ab7492b310c2b72df4634aee872cf0c16688e497cc6f60e",
    },
    832000: {
        "ledger_hash": "14c9254626becc77e73363fc0e6157e270b542e7e44e8bfda4efd4692c10c981",
        "txlist_hash": "e58e75c3cc21b6fc21f07d16a9def966267755e33a5385be4e830a24acc7db05",
    },
    833000: {
        "ledger_hash": "ace93e2e5f99a4738cb1b54dc68088ac60921decbd2eea9b12e2d6b034118938",
        "txlist_hash": "d29b758882ce15f8ef968ff7b6d3c53843dd0af62f1ba78e0dc7f635d6a41f9a",
    },
    834000: {
        "ledger_hash": "e37c5d49dbdb4d7a83d376d70d25797b80a2c5ccd481f47204960cc5d63f1f48",
        "txlist_hash": "c66c6b5ce0b41783fe447686777378507a1ecd3179b4c7771c1d56b84205a5f9",
    },
    834500: {
        "ledger_hash": "31b2d2737baf93970b15b2e7006f975ad95bde8b77017ddd9f970a7b170bb5f4",
        "txlist_hash": "08d669cf9a69377c069688deb296561c8c50e3e08f649ff0753f8812bb7554d9",
    },
    835515: {
        "ledger_hash": "5c281647d363e02bb408ae6eab78678ee1227fd969d42a9c3821d3d967f4c701",
        "txlist_hash": "cb35019796fabb05571b7169d1c42f554835e86b6cd878c9cfebe77021e78832",
    },
    838863: {
        "ledger_hash": "1c8cd670b76dc1dd86f2284f79d2c49d3dc0f12fd43680390ca27c90f98cc625",
        "txlist_hash": "20616611810c98e4948b873ca26f533a782c523d9ec6ba59e686b94efea8d108",
    },
    839910: {
        "ledger_hash": "3e67db9b6c99ecbf4cc9317d69aaf63a6ae6f574a02f1e55f91b3cba3131caf0",
        "txlist_hash": "24253b18a4be505812e690059dc105cfd3b6ae97c6768a562988e21fb4dd05f2",
    },
    842208: {
        "ledger_hash": "83d22a34d5d6368b07f0cafcbfb0885e3123fb9731972ba0d259808d5cf8f51a",
        "txlist_hash": "d7be27510ae9950579e51e386138059eebbc29afefb46c7da4c475a21ace102e",
    },
    847469: {
        "ledger_hash": "a6f16aee0761c1bf4cbe19fcdfe0242fdcd1c6cb8f3a999c0b1f1e48bf3d85e0",
        "txlist_hash": "0db537fef4e7babc4016c6ed16336cd967ce4ebb2d113fcb0012daecf6de4322",
    },
    850500: {
        "ledger_hash": "72144badbbcd20ee9615c19ac725a8f747cc1d984b5fa578036fb4a310eb7ef7",
        "txlist_hash": "475b2d521758acc70803a8b18caeab3a353c86679ae74a12dc1fa6d775441b03",
    },
    861500: {
        "ledger_hash": "9adb63dabbdf3d533efba149efadb6aad56035708d4eebb8c79ee45d8f886c54",
        "txlist_hash": "7560c12ee06a74f01dbefadefaef0cd6253c2fecaec8f544932d2b76e3b7cd17",
    },
    866000: {
        "ledger_hash": "fda930cbe8cd33afe47e588df612e1e062c99de7313d34290bbb6eb3839f6801",
        "txlist_hash": "2cc168340bb0a0153404a1d4c48ee48381cf58ec0473823b1515014ca1522116",
    },
    866330: {
        "ledger_hash": "a02fb7ff41a9b5f479801f9ad42312760084bb50b09e939a14a44fd570b7f3f4",
        "txlist_hash": "97478a8695c5595f66927b71c6cfb5dbed25d91d43f72c353a1e4f53355b8911",
    },
    866750: {
        "ledger_hash": "25d586ba53e6e146732a7bab0258d6fdaf82734927d0b5e30828899bccb224df",
        "txlist_hash": "c74efc3e272eae7c5506dea36b2cec946a45cae0bb824c57e388d1ac669800f6",
    },
    867290: {
        "ledger_hash": "f2f23ac95a168ac0f868088095cab3de859fab4fc87babcc80f19a2955756e3f",
        "txlist_hash": "d9fca0dcc82c273095e3a10ae8231cc7587d2886866756329424a4e420a0b9b7",
    },
    869836: {
        "ledger_hash": "1e26c7ca9506ce17030e3612eb0d89c8ce4137d4adbe19c3ae5c76d70910f5c7",
        "txlist_hash": "bda5e86176dc0a83b48e77b7ab77ea9676985147041232bdfed788333f833c0f",
    },
    871781: {
        "ledger_hash": "3ac97511282b5f47ae3b495c078b003740380e51303ab00e6c507717ce980ea7",
        "txlist_hash": "58aed1ed4768e4de2af6d8762f14f83e6ab0760cc46163762ce1c0adaadf2737",
    },
    872500: {
        "ledger_hash": "5e32cf4d00a2d61b96ab0b860856d958e879f7904d95b12acb9dbecc488e7c6d",
        "txlist_hash": "201a1d042c19d7ca30aec4fbc01e83b407f86356793f2cd6eed602e75ecaa90d",
    },
    873000: {
        "ledger_hash": "68dc18154c0fb8ea0eedc417d81d28122a779ee547c2bce48dc7ae6864cb238c",
        "txlist_hash": "a8edb44258c25ca3a389dd5bd1cdf4d81b5e2f3e797d56f68d9d40ca5d759257",
    },
    873500: {
        "ledger_hash": "11f4afcf50dc21c9039819550ede299b1d3f5d6e7fb34e2823be4d9d2d1aeb6b",
        "txlist_hash": "fad068ef5745ed39126a73cb6bac5427d44647914ac5ab78d2d902c9497d6c5c",
    },
    874548: {
        "ledger_hash": "7b32985ea64a6575805f11593649b30b2894923eee956ec25a6f51f856f7b265",
        "txlist_hash": "761dd60e65dc239fb28990e4cf3e7c2996e51e86aff05313b2c5b362fa880799",
    },
    874883: {
        "ledger_hash": "0531617ee6b1cec54487201df683266968329d0502469a34593c6373b321b9e6",
        "txlist_hash": "37d99a99b4c66b6319ae4306f5bc47711cd1cd80ad3839a7cae6c3ff604a5948",
    },
    879058: {
        "ledger_hash": "5c89e1f0e467a4b1a43982335279afbf65bd884aeabba94b610d167862c8d8a2",
        "txlist_hash": "8d1a98e413a42f65f419f9791c475cfcf880183b43768b491b6a434fcc8235b5",
    },
    880354: {
        "ledger_hash": "627686472eef99883943fa76462ae36cc5d55e9009cc5b2f228362408c018aa0",
        "txlist_hash": "7721217e0c6f200f5272505c9be2f694dae82f985960ca5e264602ed3bfce435",
    },
    883591: {
        "ledger_hash": "7385cd4f1cdc26603c3c0a237fedf2b4913aebc6b6aa08433e7eed2f5727a9e0",
        "txlist_hash": "00dcb30fa0fe5f15f724593a5d237dbbd802fa4823c7d6adc6f41f2fa780fb45",
    },
    885705: {
        "ledger_hash": "9081a2768917f894eeb6ec692ffffeade57478e0cd446853a40d2711579eb723",
        "txlist_hash": "ca4663772ce7134f8c71b84ae6d29a69c38a9b5fc6aec7423bcd9a46a0820ab7",
    },
}

CONSENSUS_HASH_VERSION_TESTNET3 = 7
CHECKPOINTS_TESTNET3 = {
    config.BLOCK_FIRST_TESTNET3: {
        "ledger_hash": "63f0fef31d02da85fa779e9a0e1b585b1a6a4e59e14564249e288e074e91c223",
        "txlist_hash": "63f0fef31d02da85fa779e9a0e1b585b1a6a4e59e14564249e288e074e91c223",
    },
    316000: {
        "ledger_hash": "d78bf40fe4fb6dbec0590c394cab8d4b4dd1e331db009e8049b9bfd4b08b7926",
        "txlist_hash": "4f848e9abb44466a32752c7a20cf3d128cad32234d2f7bc65737ba639f60e893",
    },
    319000: {
        "ledger_hash": "c04ada0ac248dbd5529c457e7ff19cb1381ffd918fb9ce985ede2a0b59e97160",
        "txlist_hash": "dbd3683b2c37c3472cbfd2ad72f34f116f8ac2af98a1be8a4adff6255d6be37a",
    },
    322000: {
        "ledger_hash": "b9000189b5f3d1ea544607793b72a9caf463dc71831ac3a26369b46dc771f121",
        "txlist_hash": "e630850064b5deb815c7430926f3164ac7ca6ebf3f0c06c0a4bfeefc189fb30c",
    },
    325000: {
        "ledger_hash": "54c20c8af46b01583bc4df323b34d51ac021a87ed3090b34beee9ad5001fd26f",
        "txlist_hash": "0a527d3cb46070d115af087f15e6f26bd50ff31d6a7e12698cea8dc8ba75b141",
    },
    329000: {
        "ledger_hash": "f9f6f94e1f59ee87dea8af9baa57e7dd1af6dfad90773981268ee04adb2a8bee",
        "txlist_hash": "765923d36b3686b1a9de52df5181585b073018eaba4ac403c3db47f99fba540a",
    },
    350000: {
        "ledger_hash": "c50fcb3562e93485fc339f6ca5d0e81f03c15645770241cf42bdd5bb01c64c94",
        "txlist_hash": "f510e5e4dc9492d6e1ad93227aeaf9e7f65eea5b826c8353bebe38de79ab6789",
    },
    400000: {
        "ledger_hash": "d30944db43e6f99f3ab8deb95e699b3996c1f35f74de48fd51e31e84b6a0e5b8",
        "txlist_hash": "38cb92ac97af0117877d964f0244c829a9b103dbdf6a3f92cd10a9bda73ead3b",
    },
    450000: {
        "ledger_hash": "91ad88fa3c18276d329c1a61cf4120939ef89ac792523fd5c9cbc96e609e7234",
        "txlist_hash": "4957e5fd386d0e84ddddf9428dc2304b9dbe0a293cb0b54e0e6a8980b083d870",
    },
    500000: {
        "ledger_hash": "c1de2120844b4ed1af28ba8fd1f7cbd0a6d6af52f7ff91313f18a1723d8020eb",
        "txlist_hash": "36da3a18ce52e151a57c5b1e543cf5626621f8d7ba7485c9b35bd4cca60ba28a",
    },
    550000: {
        "ledger_hash": "963e005ba0efd0d9e519065ac345029ad1cad46b94fb4b8c040ad0836cef3f0f",
        "txlist_hash": "93ae6e33b41c7df037b7ebe6cb31660ce2ffafdf79c22c3b15fdcf1d0458377a",
    },
    600000: {
        "ledger_hash": "194839aca15c8c4e8bce8632911836de9693cbea9c3494626cd3cb3141372a06",
        "txlist_hash": "105e863d367bb64d16c99e427e41cb9e2efe783b65c5bcd000182e70cadbd478",
    },
    650000: {
        "ledger_hash": "ffb4f53065c79955a83060ea8dc499a913baf34115cc8ff6fead54f5c87f5e39",
        "txlist_hash": "cd02d884d65aa848641e87c69bc37390cca4461c2b90d1884b6ae8338cf95a97",
    },
    700000: {
        "ledger_hash": "33e175187bdbf8c2730edb7cb227af499be8e57f6a70eb25aa4d270b6762c56d",
        "txlist_hash": "ff49233ef049b811b1ab341d57094d99143d18295abda722f41eb3f4ad36e647",
    },
    750000: {
        "ledger_hash": "e863b286aa753d0d81594ab4d221167b03cc80bddd5807f712b9d25104fc8724",
        "txlist_hash": "b617c3568bc528e6dda89ac01901c432f6f049d554700d41cffb0bf998335d44",
    },
    800000: {
        "ledger_hash": "a87c5f3b8fc7d3ceedc8e4f88ce87f567bed19f362e49fcb000a00fbfce306fc",
        "txlist_hash": "bc8e81fb7cc968e55b8e327e8acfb75cbd33d95afb271f90494eb7bafc78327e",
    },
    850000: {
        "ledger_hash": "bcedc2a1059df83c93629537517776d3dc298b76a2f9fd10638d555a51f6bc07",
        "txlist_hash": "274867ded58c96091994b5b09177ad3327d8628359484426bc9a0779dd758443",
    },
    900000: {
        "ledger_hash": "8fa1c6d820c4139c8bd84f6040e07fb7c028215842a8342474a928f8cf72a11e",
        "txlist_hash": "f8cff04c1d7b8610d927707e6c8861ab804fef964bb2aa1741adb867a355c97c",
    },
    950000: {
        "ledger_hash": "b86f73873675219e24baad6a73b315a8e97d112e2b9daa9efa3159a9dbc230d1",
        "txlist_hash": "6edd7d8904fb9a747ecce8fee127a7f1a16948e8096b6c77dd734cd5d3d757b5",
    },
    1000000: {
        "ledger_hash": "c9931cf865fb3de09ed5bbe34649455a48da9478deb57d3a3aeb87130dfba352",
        "txlist_hash": "9b89e91deeb2d68eaee5ca73f5d8f9d3219306ec0898bb06f090201a72ed02cf",
    },
    1050000: {
        "ledger_hash": "dc59520b130feed2a41c353e00db01d352d66d74ec10f99cfe56dc9f8003e6f8",
        "txlist_hash": "5e8890bd60d7265e151d6f664f05ed9ea46f644d43489123f376fb14eea70df3",
    },
    1100000: {
        "ledger_hash": "51ac9510824f109866edaf76f2adf8f7ddcf0267f3beafe28010ef1994fbccdd",
        "txlist_hash": "1a47495c6a25f1c64f812cfafb3b39d3ec3c26c05bcdc418404b3a300fadc8fc",
    },
    1150000: {
        "ledger_hash": "089e883cb7c1f020abfd73ac731207af1dc9269ed4de788102b3675c7864cc0e",
        "txlist_hash": "56a047794d28c9a900dc6833f40c1d651edbb75e913ab71ddb54e508800b3be0",
    },
    1200000: {
        "ledger_hash": "2344a261344d62c990e82eac92bee7fde74f23c1963c4231e79461b4ec21b4b3",
        "txlist_hash": "d74957b0087f4455ff8c8c620aadf81b02d41ca57be053f9adc6e12ca349cdd1",
    },
    1250000: {
        "ledger_hash": "9719ea43229540d9c2633b6d30032927932e0e0dbb4f7ceb45ffcfe224251dff",
        "txlist_hash": "c626891ef006b4a579a8fb06b3bb24de9e877d385760cede97000fbd8c6d2397",
    },
    1300000: {
        "ledger_hash": "5e6ebdd3966d44adf3fc64ca8b0e2dacd27638b2fc8ef75170c410333bd8f694",
        "txlist_hash": "8be14e9fa676b3f9eaf0e7a61ebf5d19385767e099b9275956d33be249f99fce",
    },
    1350000: {
        "ledger_hash": "2b4da40c0b41c6fd3ec67811cbc16d5ed04f5817cba98cca81c77ce52bda7ac4",
        "txlist_hash": "2482a6aaf1edad67e30e95e2fd328695c7830bd6ca1c6edf8e92503277944650",
    },
    1400000: {
        "ledger_hash": "baa29889e35cb8ed47abd045c65a567150c2c8250b21fea1987502ab5750c34c",
        "txlist_hash": "6ee2f897bed6a1b43fc4d77e0944b088dab4702cd6145c6a4eedd4dc9d7c90b8",
    },
    1600000: {
        "ledger_hash": "4614b4cb52433369570981de4267cf44a1f1cf1b7a45e95d3a5b0d271b482b1a",
        "txlist_hash": "9758872d713726b2ad497051aff9c8df41d221fada7ebdcaa2d60310ca6aced0",
    },
    1700000: {
        "ledger_hash": "221e4e2860e4993e50f15624fd3d3fa1286a9ba498b5afa93a9706c2d11f11a1",
        "txlist_hash": "053998b16020976e55cb4a03d465ebb3fb9cf2e9fded2801721d8b85d7d5ae18",
    },
    1800000: {
        "ledger_hash": "cb55894c81cffff0041039381139fa842953c920d491f1f8704448123df6b5f9",
        "txlist_hash": "5d28b9521baebc3ce73c4042c4b2324f1eab84b80ce84b0fa1f1506f97d60de5",
    },
    1900000: {
        "ledger_hash": "6417ce2d7a3815731376f3b0251e6bb2d00e8d92fd1c2f00e779e33919b37996",
        "txlist_hash": "61a6c12ede769a7fb8bd467dabaea685d73c0d7b17cf641040a63501ed78cd2b",
    },
    2000000: {
        "ledger_hash": "d73327f2d45cb7fe15c1609e205b07d1b1744343a8bfb9013b71e568e98415b1",
        "txlist_hash": "cbb5f92600a5fc97596ce8c3d8814c7ced6bf0136ce7f18ba44e73f5e5519799",
    },
    2200000: {
        "ledger_hash": "d530d753e4c906435710c60f50ef67bb7c656f38ed41e6dda9d972df2c12b7d5",
        "txlist_hash": "34324f1605e9a205c88553b880d465d680329dba401eb603c8b3ef1cd5fae0aa",
    },
    2400000: {
        "ledger_hash": "4a3e8244c5faed39af338015ba6b0e30c856116c6578d8d8a035d6b715729bdc",
        "txlist_hash": "264564c68b416033c989c3d995d44c0d54da584fbe047a6eb76b384bab7b9f10",
    },
    2500000: {
        "ledger_hash": "6c4ae3fca5c3a2a0c2b6d9b8d441c983de79acc029dd0aa125f3775d3dc9ecbc",
        "txlist_hash": "07bf7697035d43c846f59d8fcfaeecb38ce17683a01ee6c5c72426e72940a7f4",
    },
    2540000: {
        "ledger_hash": "1e3c5f77592abae55c0afc455dc1723e929a15925f2b025b42945eddcf42a98d",
        "txlist_hash": "e887d7e68f0061de87fc21edf2704b810a4c7f661ad302b01438494be0454df0",
    },
    2580000: {
        "ledger_hash": "75a6fcc4e7868692ae6af5b7b9399f3fb84c61bdcc5f6b2fc017bf0f65ba4bb6",
        "txlist_hash": "e292caa32f4683cd9bce678634803b15acfbf3ec63d86939269b798964a3d792",
    },
    2586067: {
        "ledger_hash": "b3d8f759fe027da3970c07312b112d39e10231dae519d9b8e63d187bdc8854ba",
        "txlist_hash": "d53c768a42cd07c56b6e35589b7759acbc81505fe82eefc39260be40e9f43885",
    },
    2820893: {
        "ledger_hash": "89383b665275451637d12bdc337bf51748b92f7a561fef8f9e72f53536c650d6",
        "txlist_hash": "73043e2563cb4f175ccd6860dc13b92cc53bd3922fd708e9bd6519cfea241f81",
    },
}

CONSENSUS_HASH_VERSION_REGTEST = 1
CHECKPOINTS_REGTEST = {
    config.BLOCK_FIRST_REGTEST: {
        "ledger_hash": "33cf0669a0d309d7e6b1bf79494613b69262b58c0ea03c9c221d955eb4c84fe5",
        "txlist_hash": "33cf0669a0d309d7e6b1bf79494613b69262b58c0ea03c9c221d955eb4c84fe5",
    },
}

CONSENSUS_HASH_VERSION_TESTNET4 = 1
CHECKPOINTS_TESTNET4 = {
    config.BLOCK_FIRST_TESTNET4: {
        "ledger_hash": "33cf0669a0d309d7e6b1bf79494613b69262b58c0ea03c9c221d955eb4c84fe5",
        "txlist_hash": "33cf0669a0d309d7e6b1bf79494613b69262b58c0ea03c9c221d955eb4c84fe5",
    },
    64493: {
        "ledger_hash": "38778b2f32024c205cf5f634c783a77b84b381154fb1094549d0847b582f188e",
        "txlist_hash": "edd29d369f6a8a494b8cbfe957bee256069f370fce7c24a251d38bd2331c1247",
    },
    66241: {
        "ledger_hash": "2813bd0167616f222087507d9def101dde3fd20b0d1f23e9a10202aecfadc62d",
        "txlist_hash": "c73385f880a6662591f52d686431f2af8e9d1b5e174378c219da6554c316e397",
    },
    68000: {
        "ledger_hash": "ba69ca87e5e95a6c6eea5f3d6e0fac53398a31963500ada245d971bdadee30d4",
        "txlist_hash": "9c1aee038a89a6e19fb04cd396fcc2a18ae3324e04f73b132e799a557ec2a104",
    },
    69000: {
        "ledger_hash": "3b76217d649c015745b51c9098d7396141909a9a89a4918c2aa2f8ca870809a2",
        "txlist_hash": "665c998291dbff4430577074cd4ce558c042ec72a3a0b64e8ce925309729b0ab",
    },
    70000: {
        "ledger_hash": "3613f02e6e5bfc2ddfd1a629d411f72bc76095b078e7a863652305962cee9f20",
        "txlist_hash": "ac2fdfa0aeb3af88c541ff5fc46615346c87567a67b30d8c453390801db1e884",
    },
    71000: {
        "ledger_hash": "deadbf16d58d27c05571dd166d4e151d2b94fe8c7bb7ebdcd5acad74baf49c5c",
        "txlist_hash": "ddbe2522a702047d48f76318a77d2dc5ceabdf1dc9d58d70ee3989c640f24f10",
    },
    72000: {
        "ledger_hash": "6b65bad08047eaaf9690ff0d95ee6f01a97b3b67f7a376407b28cbd7bb10b852",
        "txlist_hash": "7f3b1f29053049a1e7268c710b7d047f240632dc6addebe846845b66aa91cbf1",
    },
}
