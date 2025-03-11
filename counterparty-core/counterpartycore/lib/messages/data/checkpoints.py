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
        "txlist_hash": "437d9507185b5e193627edf4998aad2264755af8d13dd3948ce119b32dd50ce2",
    },
    336000: {
        "ledger_hash": "fab6b3a1439bd2a0a343dcb27ebf77e3a724cde6aafd64004ec2cf4d688d9b1d",
        "txlist_hash": "33eb8cacd4c750f8132d81e8e43ca13bd565f1734d7d182346364847414da52f",
    },
    337000: {
        "ledger_hash": "78768548c3835d17a4fa3d42e08018470bb16d9b76d2d5c6173ad544b376ec91",
        "txlist_hash": "20b535a55abcc902ca70c19dd648cbe5149af8b4a4157b94f41b71fc422d428e",
    },
    338000: {
        "ledger_hash": "481d5d346fde3ae667403935019808f52788a7a5703557ad1c9ac37b7635c468",
        "txlist_hash": "fa2c3f7f76345278271ed5ec391d582858e10b1f154d9b44e5a1f4896400ee46",
    },
    339000: {
        "ledger_hash": "167b2e53736b59290992b1c88f6fe3af3a435f5723bae48e0be070a25f8acf17",
        "txlist_hash": "c1e3b497c054dcf67ddd0dc223e8b8a6e09a1a05bacb9fef5c03e48bd01e64e7",
    },
    340000: {
        "ledger_hash": "c5a7c10eed8e268d54bbe649b233ed4b0c57898cdf94eecea78923306d9bb6f9",
        "txlist_hash": "8502004bb63e699b243ac8af072d704c69b817905e74787c2031af971e8cd87c",
    },
    341000: {
        "ledger_hash": "de580893516ded2c9e9594d1e9d300dff4c99a66db845624695bd045d8458b86",
        "txlist_hash": "d217d0bed190cb27f58fcb96b255f8006bc4b9ed739e1bb08507201c49c426c8",
    },
    342000: {
        "ledger_hash": "aa1f12ed515480ed130b9c51f79f7f9c9bbdc66c666ba7b2f532e4bebf453b95",
        "txlist_hash": "adf75d023760101b2b337f6359dd811b12521c83837eb3f7db3bbfd0b095aa54",
    },
    343000: {
        "ledger_hash": "b88149bb189e17b3d530e12bc691fa26c63e7c2b085f319550768a29d0b19fa2",
        "txlist_hash": "6bdbbc96364b3c92cea132fe66a0925f9445a249f7062326bdcc4ad4711f0c01",
    },
    344000: {
        "ledger_hash": "439446e3b0d2c519d0d956b1a2820fbf20c87429511c56f47a4dc35c4b4e4f27",
        "txlist_hash": "98da8efe705c4b54275bfd25f816a7e7a4ff1f67647e17d7a0aaa2a3fef8bda0",
    },
    345000: {
        "ledger_hash": "885e413bb171165320771b5fb2cbf1a10f2f3a2e3ee81f6c3cdef546164a3401",
        "txlist_hash": "777f163eaa5ad79dcb738871d4318a0699defec469d8afe91ab6277ff8d3e8b8",
    },
    350000: {
        "ledger_hash": "95fbc626f6e74847115254fa90fa72920be30cfac27a3ce4cdb0709edd67c296",
        "txlist_hash": "96bcbdbce74b782a845d4fda699846d2d3744044c2870a413c018642b8c7c3bf",
    },
    355000: {
        "ledger_hash": "1722af3134891cd02ed3f7005c75c43966f24aa29741de33dd3f69263d34e9b8",
        "txlist_hash": "210d96b42644432b9e1a3433a29af9acb3bad212b67a7ae1dbc011a11b04bc24",
    },
    360000: {
        "ledger_hash": "9cbd82c31ad94d3f8554332f6f85ba822fc5e80f65ff1681770e842525631080",
        "txlist_hash": "31d0ff3e3782cf9464081829c5595b3de5ac477290dc069d98672f3f552767f8",
    },
    365000: {
        "ledger_hash": "d65bfc094b9ad477324bd2afcf0405a099b60f98b09df465f37dcc74fe64b1e7",
        "txlist_hash": "7988a823cc1e3234953cc87d261d3c1fede8493d0a31b103357eb23cc7dc2eda",
    },
    366000: {
        "ledger_hash": "6373abd1d42643d382e3636c36659615e0aca8b03bf10ce17e68faede643ac54",
        "txlist_hash": "0d4374da6100e279b24f4ba4a2d6afbfc4fb0fc2d312330a515806e8c5f49404",
    },
    370000: {
        "ledger_hash": "9767fcd7e86081cb6ae4d1a259eb84e96dcffb7fcea06e0bb3a585302efde551",
        "txlist_hash": "41d1732868c9ac25951ace5ca9f311a15d5eca9bf8d548e0d988c050bd2aff87",
    },
    375000: {
        "ledger_hash": "202011bd5dec945bb557ccb6dca40d8806b3113bcba558991ae7556f5abb0544",
        "txlist_hash": "96118a7aa2ca753488755b7419a0f44a7fbc371bc58dcc7ab083c70fc14ef8b3",
    },
    380000: {
        "ledger_hash": "9c1c0a4fdae2a6efe10b17971ca23e88744ccd016bae4e769a707981515195bc",
        "txlist_hash": "8bf2070103cca6f0bde507b7d20b0ba0630da6349beb560fa64c926d08dbcaef",
    },
    385000: {
        "ledger_hash": "78698704135a9d12739e5388ffc62d01537ac31f0111125afe3997326901757e",
        "txlist_hash": "1f8f17fd5766382a8c10a2a0e995a7d5a5d1bcd5fc0220d1e2691b2a94dcc78f",
    },
    390000: {
        "ledger_hash": "9dd60ed2df80dcf1eacde92f022ef1cd6189e990b86096103016aa81720cc9f5",
        "txlist_hash": "b50efc4a4241bf3ec33a38c3b5f34756a9f305fe5fa9a80f7f9b70d5d7b2a780",
    },
    395000: {
        "ledger_hash": "20e616dc24e6c4e1511911d0c5664ad482a3c6eea68eed0f20f85f030057b8d6",
        "txlist_hash": "2151dd2f0aa14685f3d041727a689d5d242578072a049123b317724fc4f1100c",
    },
    400000: {
        "ledger_hash": "c1ea6fd36e45e08a99d7815ea734e70746f1ea52673b2462cea7aa5e6879aacf",
        "txlist_hash": "b48e9501e8d6f1f1b4127d868860885d3db76698c2c31a567777257df101cf61",
    },
    405000: {
        "ledger_hash": "e9c652e984fe8778c75a9a259d7dd51fc488db45b107a7998261eccc97feefd4",
        "txlist_hash": "871b2adfd246e3fe69f0fe9098e3251045ed6e9712c4cf90ea8dfdd1eb330ed6",
    },
    410000: {
        "ledger_hash": "b743a12f6dea4f74247dcf840f66e7fceb34aa723950f75ab280912f9b70b892",
        "txlist_hash": "ee3bd84c728a37e2bbe061c1539c9ee6d71db18733b1ed53ee8d320481f55030",
    },
    415000: {
        "ledger_hash": "c2a48d80b861ae117aab0050fb3da17b75fc9b552034c56243e77714df879fd3",
        "txlist_hash": "cfb81785cd48e9ba0e54fee4d62f49b347489da82139fd5e1555ae0bc11a33d5",
    },
    420000: {
        "ledger_hash": "1b29d285056116dd5b3d9ef28753cd2e2ae9d404313dc963cd5aca924601fe84",
        "txlist_hash": "a1139870bef8eb9bbe60856029a4f01fce5432eb7aeacd088ba2e033757b86e3",
    },
    500000: {
        "ledger_hash": "3ac2123d1145a1fe9298983e68305dff2f765f7126e1a94751570b3098b25c07",
        "txlist_hash": "ecd99b7d0fdfd7233a975c3c28127ce341cb24bec44d21f9a79c3db4aef5a771",
    },
    600000: {
        "ledger_hash": "32ccc85fb301ccf2e34fa0f97534eac3f1cb9f653d7ea3e3dd9b694ee3b6ea5d",
        "txlist_hash": "c8c7b8c0a86d601274e047d7038d47cd20f7147d9245f0d22449102b4b0c6fbf",
    },
    650000: {
        "ledger_hash": "bd6ed168b65503faa6e85adc719a338122661a5c5e2c76c83a9c5169f042963f",
        "txlist_hash": "14405c618a97fb2fc8b5640f84ad8a4aece924474a5b4ffc4e67c46914676ba6",
    },
    700000: {
        "ledger_hash": "d8761e5faa8094536a7387385b6552e3a90aa1d9236a9f4086b2d72fb9c67b04",
        "txlist_hash": "abb48c10d692c159180a376b4a9002abcf582fab1b5652ba3ccdc73f4b5e0d8a",
    },
    725000: {
        "ledger_hash": "56c00c623b7242c8392dfe8d3b95bf1be266aa4423ac61f4a31610933796022b",
        "txlist_hash": "3c9a87bd4150368ed3af587764d67e0fa9c4cdd89aeb364ac60a57c122610464",
    },
    750000: {
        "ledger_hash": "20017dda48d8155f4234d2faec1c1d2b26b36de155af682ca29c03272dfff8fe",
        "txlist_hash": "2466a57ab625ffc9a57bce0230f530bc9176406b62d30a43e761b2b92f175044",
    },
    775000: {
        "ledger_hash": "ba9ed00072b288500fcbd89d405530942f73e4d11988f0603213f98e0e5ffa5d",
        "txlist_hash": "81970d14f86e76577dfd819bb5291f8caf71a3a44fb18e9c119cfd73169be053",
    },
    775500: {
        "ledger_hash": "ab2c75d1887587cc2da48e44882f27ade4f0b4d599bad1de3818ef3b9e7a2ec5",
        "txlist_hash": "6d323ec8af4f5b1b0ba65028ce574b50d410f279234fe7d7de3d18621d97331a",
    },
    776000: {
        "ledger_hash": "b230c6b3b3cc599233b5a7a6127beb27b4457c87369de9537c05ad5061a87474",
        "txlist_hash": "59968551a22d2241dbf04bb8dca12ac34120313e32fe3ab2f5436853b499ec3e",
    },
    776500: {
        "ledger_hash": "d111443c1e658c0deaf218805f324fca812187e41c32f93dcea3c9fdb5dab98d",
        "txlist_hash": "5344d9d86af82bcb5ec139d214dc97e012aba300f6f150f8c8b2a13f6c854923",
    },
    777000: {
        "ledger_hash": "3a966d738a23d93a12ecd85cdccb602c029d0d76d0be4f47852a3013bf66d067",
        "txlist_hash": "3c52bc42e685ce050418fdb1c4c907161f7ecc6669b1b7585cb74e2cfed3ea17",
    },
    777500: {
        "ledger_hash": "e947aabadefcb4473ea5375176364d452d6808819a3ee5f365270d4d8988e98f",
        "txlist_hash": "61073b558c84d51cbf45d0c9983486c030f5aae3fd27a77eae436e52f9479c0b",
    },
    778000: {
        "ledger_hash": "9e421ec264f99f4e398b6b8efaa94102f378c86f3188ae75dc8ad6b9b2f5e6c5",
        "txlist_hash": "31c4f80ff660b2e5c14a8e6aef89412da2d9ce4a0406601bb07efdd2aa05a0d4",
    },
    778500: {
        "ledger_hash": "410d8b37c5b64d392e06724047cb5927c82fdff1a2f2b14249e60124f8fc93e1",
        "txlist_hash": "64bf65bc4ace9046556ada65c84e10e66d05d88bdfbc35327a49f221f18ba55a",
    },
    779000: {
        "ledger_hash": "d073b3ea502cc42075177ae8150ec0e50d2afa2b0b187bfafc5be762dd4245b3",
        "txlist_hash": "1b698bb19eade25020713a72e803833b231a5b335d0589c98b595980255d338b",
    },
    779500: {
        "ledger_hash": "59629b536263748b9a81f94265c99d987d9e37151926b17254178629f1d295fb",
        "txlist_hash": "47f8a9010b1761619e3c845bb81d53f04855c6e96c87fe75d8028669f837bc7c",
    },
    780000: {
        "ledger_hash": "1fad5ae4be9dce889db41cd13b992a46246e02bb3b96f05306a898f077d8c66a",
        "txlist_hash": "c1d5c1860270b9ec0f8e8e801c252ac58b9251206773258e2abe207deeb1ddbf",
    },
    780500: {
        "ledger_hash": "868b02030232a593bf23a9440d08ce2de7822a84cdc09140ad12475fb82edeaf",
        "txlist_hash": "79969f1bdd63c1f3ee7479ea6daa853212940f65775e5c23d143a7dea5b4673a",
    },
    781000: {
        "ledger_hash": "88888193a6e4723dd1082b1e67c4f57a3956492d13fd80f142edc8ef03d23978",
        "txlist_hash": "c9b74bbbb6218dda42f38dcedf845b35e15b7ab6ac929258d1bf5754c371a81b",
    },
    781500: {
        "ledger_hash": "32889aea7c59e5498b27e1982333c46aa78686c6c5c39d24a772c46dae6707f8",
        "txlist_hash": "6315ffcc0e5d739f946f9d14e7d5847f4fed1a4de5c9240329db161613adaee4",
    },
    782000: {
        "ledger_hash": "145341c8784853611ea2e446a7537d47a071e272ebf130950acb00e1fa4546fc",
        "txlist_hash": "f44bb1f2b5fd28deddeee59b7dfae8e9c252b87705dd11b1b2d6619498cd38e5",
    },
    782500: {
        "ledger_hash": "b16645210f0527566a48241b8bfafd5b6883bd36a5f754672806751885365159",
        "txlist_hash": "9cca1b2034e84b8652a46c1fd2ac52e7ad32f8f5bd1dd9edde43411d6fb73373",
    },
    783000: {
        "ledger_hash": "620a26e186affb54cbf53ce2b3f3f1f204d35f42ae0c5495602498824b4e035d",
        "txlist_hash": "d41dd8eb0f9143de848c8c52018df5362b842a506cbbdfb2b989333069ae59f2",
    },
    783500: {
        "ledger_hash": "128046210de53e3d24f395c0a557e57fe65e0ee7fb49d0ce95d260c4e8408cf2",
        "txlist_hash": "6769b94212aa3fba96a413d3aceb97ca6e254516ce9e60c75cc6b779fce29005",
    },
    784000: {
        "ledger_hash": "88ea8e17c4415e4c9215f1ea56c2d17980f3b4c47bc261b128b7cd5df76630c4",
        "txlist_hash": "a1bc1dc2bc502d7df6e33b08f420a6e92d4385eb5f1d085c521fe0b89128ad3f",
    },
    784500: {
        "ledger_hash": "67ed396bd11a7a384422f46cf3e8fe4839052b5e40a48346d3d82d79774196e5",
        "txlist_hash": "ba1711aae5e68b643f7721fe659e740d96c6af53b0847ea9126195a602472d18",
    },
    785000: {
        "ledger_hash": "62b11b418052447539bcef8d6dad828a648159f91ec855a6494d9265ce08f52f",
        "txlist_hash": "29f401d28aa5eec5d12a80c40e333c170aef3f8d21f1863dd98d566aba2bd78a",
    },
    785500: {
        "ledger_hash": "5445d7873d6abb5d5cac9b0fef5b24c23d088fa6834384068775d4e17594493d",
        "txlist_hash": "4baf4a10d0c932e663b24a6a100b11784eb5644602d00dbbe6b1f1c5dd71e10f",
    },
    786000: {
        "ledger_hash": "1a78423803005bacc707aa850ade0342a0382d431114fa63846758449f83e88e",
        "txlist_hash": "92dceab6e95997867bd82149ef77ca93667df4400cdb487b201e579f8ad4e84e",
    },
    786500: {
        "ledger_hash": "f98fedc406b0c6feb45468d6ede7814ba9d9222052d2837ca27474250c45ed95",
        "txlist_hash": "7d50d881a87bf88803b8be2272c4cedc97bcca457e06e7c55dbc93522ebe2e06",
    },
    787000: {
        "ledger_hash": "d4aaf0023c8cd39602099409bb1d90e75f9fc660c8c52c3b82737bb132e16e38",
        "txlist_hash": "70c0139e3bcb9ae243d8c051ebfa7fbc56e84fb19f70b8246e6d7c451f3161de",
    },
    787500: {
        "ledger_hash": "784b6c1c7f79d09fff52112b0373501fe572c8103a74df1e21c191ecbc232322",
        "txlist_hash": "ade0c47cf7d75eef1dfeb7c3783fe0ffe187dcb2d31a56c16ff73cdc1f38efaf",
    },
    788000: {
        "ledger_hash": "082fe7dbd0cfcd6207ac1e8c1777d36834c67b03ab3d1456bf9fca5c2cd47b09",
        "txlist_hash": "1c84819804bf28a3d86ad01998123e05b1491277cbc3f6d660599ec217480f52",
    },
    788500: {
        "ledger_hash": "1610e9b54a46a5b2dbc925a08e64610359f1ec5fa764d8da766e95ac51a8d600",
        "txlist_hash": "2a46945783308df4521d1b46451942f5ac3c76ad3a10b4ba4cd72276c3719474",
    },
    789000: {
        "ledger_hash": "ef5b5bf97e2f5f8a0f98eb6cf6b78a339fb69f8d0c489b6b2a870feaed7409a8",
        "txlist_hash": "7b2834a2d791530eb75d6f7323265bb6c55bb90b61aae2e44e1517019633652d",
    },
    789500: {
        "ledger_hash": "2c897edb20857541ce1ee50744033a64729fe480c910ae7ff004a9aee29dbc75",
        "txlist_hash": "9edf514d577f89e2cc6eccfa272b903689b7c36b7ac4819f32c20dd86a62c557",
    },
    790000: {
        "ledger_hash": "c22449d33c4852b699fede3092858490eab498ad72b64121a7e51269a44fe094",
        "txlist_hash": "0b50b95f056126fe0bbd57698a3a248e04071cb8f25dacfa8b29ca9fdef9e7ce",
    },
    790500: {
        "ledger_hash": "1d304f536b18261f9366c2b1d42d0f1bdcda4d4daad986a00a181de01b57428e",
        "txlist_hash": "a69bf7808cb6ee6061de42d7c7695f080716aabf233032790ba6d126b3ec694e",
    },
    791000: {
        "ledger_hash": "6b018480ddf559b9b777263ecea0aa301ce9f8f7d87698d3e2c94f7c738525d2",
        "txlist_hash": "9c88afe6c076aad24a75cc1e18fc6bc1aff1701fb6aa667f17d3b3855e16788e",
    },
    791500: {
        "ledger_hash": "4c29df1b7bba3b255ce9d1439b1b91af50886efe8808c2a26e6834a9719be3f2",
        "txlist_hash": "c8afafbf958e64c745d3f6d9926b66a8d8ade167f6002b50793bdaa315c34986",
    },
    792000: {
        "ledger_hash": "8184dcfc7e7d449127469ff908e3b123b33d91d608752a3a9f93c0c14eb573ac",
        "txlist_hash": "a41c578fdfb8bfc5175154f20eb2cda66cf284434ea25a40792f2663ae283017",
    },
    792500: {
        "ledger_hash": "0214351273c9a0314bc248e9c446556f032dc70234e00581cb5ef8b11aa6cee6",
        "txlist_hash": "159e80767cdeaf2195feaaad418266c144fdb1c23e43b5712711509b0450743e",
    },
    793000: {
        "ledger_hash": "9113c9d3b4a15d50c914eebde1b3dc73cd2ebe6f6417c3f4ffbbc1c5203923e7",
        "txlist_hash": "f25d1f410b2691990725169017e9c42e3982699646722c29a04156edc000a3e8",
    },
    793500: {
        "ledger_hash": "55802e5b6f1a02d2f84f0789a3ceed365a0365e95ae5d3e6caf72019f6075a83",
        "txlist_hash": "9bb933573506c25df3ad1d5fd900590913a2313e20775174ad0d6d494e2b1d5d",
    },
    794000: {
        "ledger_hash": "7cbc0f6030cd84e737416f4b53d0d96c53346022cf4bef15a8e8ddabe53ff659",
        "txlist_hash": "bc1c163c8934af5f294036844ab37dbf9f9776d266bd5a2a15f21d7668bd6e23",
    },
    794500: {
        "ledger_hash": "ef96e16a97b208e83c3799c7bb30e93cbd4a645f35b9a051037a2baa94032215",
        "txlist_hash": "6aa1c672994857640e30be8554d0d0b9796a8c607c7cbc639e7474c17c25bf27",
    },
    795000: {
        "ledger_hash": "4b959b9aacc6d6bcdc17ddd96ae02ce403a0e4d44d72844ea5be6b7344263ce2",
        "txlist_hash": "e56f7a5d219b95b3280a022736cbf2064a08093b6fcfc703ee2a26523de17d4b",
    },
    795500: {
        "ledger_hash": "028df12a57819ad133712e5a357408a555ed30506b9a8640dc9811ebff0fb011",
        "txlist_hash": "b4b7a89d7c0d223c3b173a5b70a4ce95be19527758e963ebf2b8b462449e8af6",
    },
    796000: {
        "ledger_hash": "2f022915f5318acb4e48ef7adb6fa218ceb0e0653123f1c63c0b0915fc1e2e10",
        "txlist_hash": "d9a64a6ad4c930f7ee1403ce42264732b8a2b43a302cf0afd86b3f6f86bdda2f",
    },
    796500: {
        "ledger_hash": "f9d5ecd69958b0ebf34c1801d3c056aca68157d8d7a5598eb3ac26aabb65a25c",
        "txlist_hash": "1fa9ce2cf898a049cbe5cf51db1e21751dfe9bc3622a150c6d40a48ae32277dd",
    },
    797000: {
        "ledger_hash": "a35fa6be9ee08cd12f2e2457f86537045bd9b89aa9285cb9319a6c30ab0d9456",
        "txlist_hash": "b952cf5ef8943c4b064772961b76b3bdbdcca83adad448b99e83a88c99025fb1",
    },
    797500: {
        "ledger_hash": "f778fdf1e17c3d563fe3dd605d3c0ae1a4e9ab26564b4ce7ab4fccce9001cda5",
        "txlist_hash": "5ef7b81a289718bf2803d07866f7a9f7af6a6e9585931a5cf7c20c953e442bdc",
    },
    798000: {
        "ledger_hash": "5e16a1033ecca39f8b67ec1784e444ce7887dc8fd2844fdd49bd438f0e9e3396",
        "txlist_hash": "2c4437ef523c307ab1c66f9a2f1ebb6c0b96e579da52b7d05598642e2b3e3cb3",
    },
    798500: {
        "ledger_hash": "baddde47b9a9507a8234a051b99e306fb1ef737fba736b2cd1a3c00afd38b5b6",
        "txlist_hash": "5e40bf1508dcc0c789c503e8c22dd9032508d1e617fb79675c9a65766720bd56",
    },
    799000: {
        "ledger_hash": "0cff84ff61722d989c474ffa18e368beb3d189b38b2b7494d1df1b56eb911295",
        "txlist_hash": "23a122876df0d21e4e2645ff51800fad1a749e22a0b580470cafb15592f2e4e1",
    },
    799500: {
        "ledger_hash": "af524c4fb3a6a3429b0fe265ce572d7697d496c346f054e0ea03acba47da2c48",
        "txlist_hash": "aaf997a519ca432700dbe87cb4c9d90f28dfd9fc103c4157c124b905ff782605",
    },
    800000: {
        "ledger_hash": "835e01803aba670465d59f67d7726ef7fd83e382ba2ebdadc8c21ca68c249d6f",
        "txlist_hash": "bfc49c705823f30ad63e8f81ec44a364eeb6d48a0e9b2f6374f0934767a3c948",
    },
    800500: {
        "ledger_hash": "69dd3de90259de05987c0930d753c6914a1b2620bad77b2ce9c6e123d5bab937",
        "txlist_hash": "f747068f9cfab2e1a5ecda4da3b2320e2c4776089b1b0c60202fc02db2fd7f04",
    },
    801000: {
        "ledger_hash": "d2fe264744013cdc0c89754b5d07f96d38800c0353b3d5465e6f76cac9edce32",
        "txlist_hash": "02b2e3290bbb314bb3fa7dfc81c5cf4c18bf79b31a02529eb0043280fda34b22",
    },
    801500: {
        "ledger_hash": "17be49524954adac73f61fb1b162e978cbd3b4c68fcfefac6d7f61b4229de8a5",
        "txlist_hash": "3a77b972e44507668ab570c7e4dd15610b4b5cb6a1c8ed3d7c7c31e853275311",
    },
    802000: {
        "ledger_hash": "682c76aeb8b8ab5aaa8a713f554c825827e6f22921c2c023fdecd2293a3d2061",
        "txlist_hash": "c9273e9360924ee0ef9e10585db442b5ec1d43d082a993ded9aa382f5e779015",
    },
    802500: {
        "ledger_hash": "996be479600db9841b6a3421bfe95dd8632a02c89cdf4119eecb806eacf181a2",
        "txlist_hash": "f3f15331e612ec403515cafc6cbfc1791154eeda21fce46494ab5712a8184951",
    },
    803000: {
        "ledger_hash": "0559abd9654292e06642896ca07b3150aa5416503a9e7f43699e9723fd618b7c",
        "txlist_hash": "9a85ece61f4e56fcd2dda3029776cb9999ef683ceb0cbab7cd31139f2693f2c9",
    },
    803500: {
        "ledger_hash": "0035e6d714f0e75d8b6a4ec4742bd78a05b23ad09548ec019ab585582116c07b",
        "txlist_hash": "65403001f670456b8ce241e5fdab3345e09d42bd4777b6849f52b51e358973f9",
    },
    804000: {
        "ledger_hash": "eeb6224851d60bcb5f94881bd44ce0651a30d025854da562255d59528e9132cc",
        "txlist_hash": "f12d8bebb4ad034b5d5eedc6b1c75cc9414fb8944d2007bcc3b700099cd40948",
    },
    804500: {
        "ledger_hash": "0db8608a150b7e6a77b143534dddd1f38c23875bfc51ee627fb39bd48239b194",
        "txlist_hash": "e6e760b79d928538692e0fdc5fe9a9c7ef3849485b20847b1084e72ace2f9a55",
    },
    805000: {
        "ledger_hash": "e98cc85132aab4d80c0aa195daadb6316e1963594ed5b204a1976c2e114dc9ab",
        "txlist_hash": "313f3712ffee8ba4d5aa2b0205fcfdd776cc325aa7da5a321bb0567de1e49d15",
    },
    805500: {
        "ledger_hash": "2498dd962b8fe3c9c91d8e481090e8aa86dcdd0da4962f03150ff8b72101bf16",
        "txlist_hash": "21b00361b1b1c5206af1f0d2e3fa8a9de8aa65158b11f35d6ab88a1a22ead983",
    },
    806000: {
        "ledger_hash": "412307729cb70b466a47b920e15af46831dd9e629c74814cbbc0cf365f6ac14b",
        "txlist_hash": "efdd67a4ecced666b962adad8f0e88500eb6ed6652a2eb6fe774ea1506194590",
    },
    806500: {
        "ledger_hash": "acbd9420ee29c08963ea28eda3e75822abdd51804a90daae064ba28c9193e111",
        "txlist_hash": "bbb095b066622e7297e849b3f2b5d8344dd2de276fbda1ee85483c0099d9a199",
    },
    807000: {
        "ledger_hash": "d4a7da284ab10f87d69119d9ab982169def7afc27c9880c9b5ac8c439869b4cc",
        "txlist_hash": "cad5e5429ee8207be8a49c0199c07e25e6e87613e73e8aa79c1247be4c1a95be",
    },
    807500: {
        "ledger_hash": "d2f28874d64917ca2d436be2d9d44b4dddf8605bb7ab4d151eb2d3025fb5e9a3",
        "txlist_hash": "0b7fe21bcddcee8d8c08bd805409503b734c538034b63c9a7dde901779e97b22",
    },
    808000: {
        "ledger_hash": "bdd88573a227a584c3e02e8ede5701b631ed3ae558c0f9cbc6c104bfe27b4126",
        "txlist_hash": "f16c177e98fbef73c7628da37021a13791489e38f5bbaf52da9c5fff6a575cb6",
    },
    808500: {
        "ledger_hash": "bd6bd8788227e3e97dd01dc8335a9ee9017c34dd5701277b491c8f7726512c77",
        "txlist_hash": "6b7a992be65c4d6b4f945a31c4702c564d0791b1c3e10f3cb119add9fbf13669",
    },
    809000: {
        "ledger_hash": "87fa43bc4dee049c515708c156e5992f10dbc1072ae88fad75b8fe633b482be1",
        "txlist_hash": "c5999010c2d22a6b9fef30f2fcc1fe6e130e417c951ac942cf4e536d880fe4fa",
    },
    809500: {
        "ledger_hash": "8f7c53596bc3c467778a7a2dff947b53e571ea72272274648eee720f39ecd7ad",
        "txlist_hash": "f90387ff18d8e94391c60af1a0b460b5d63f1c8a22b4fbad6a71a8b2c53fabb8",
    },
    810000: {
        "ledger_hash": "39daa5ab2d5150da376f6099771af121af54241d0013551cacfdc7ce24089ed8",
        "txlist_hash": "0432b1238760c9229f3b71621b2605999fdbaed9502c4536fcc105c4e58c516a",
    },
    810500: {
        "ledger_hash": "83aeea0ef8277b22e96c63313ad15cef14fb87b972ac7c8fcffa121e2c56f1a2",
        "txlist_hash": "5d3a57c573185dbf432e3dba9a862bbe3bcf44a0f0443e27b265520eedfc0710",
    },
    811000: {
        "ledger_hash": "7fe158342cf5101fe45b3c5c3b0a84e126920eb4aced6ab410b6a32bdd8d613a",
        "txlist_hash": "130c217aa4062bdfe0a58096cdef3b3500b4ee67fe5f32e801ed3d390258a846",
    },
    811500: {
        "ledger_hash": "7bf3a02143a050549dd1d4d71e3ac2403f057a64120862793f14d4117dc5fd5b",
        "txlist_hash": "0a3a3d4cdedcc08f4b416c477c2b0c0139121fcbf17aa01ded4a7edc96570f90",
    },
    812000: {
        "ledger_hash": "28b54913fe91856f294c20df4734f7b893600f849c2f44ff030768e745e30f0d",
        "txlist_hash": "a3593531bd6fac32c6be57f10f22e716c6057028b3645da8d5ff4d29db2b53bd",
    },
    812500: {
        "ledger_hash": "48c66d2de2a5ad34832841e62a82b6a9872e9dea01d40cdf66e9567caf6d2e2d",
        "txlist_hash": "f9c4b3c585987aac5d7fd97a5cc937404de6142e5592a36d28fcd22e3a5a8f74",
    },
    813000: {
        "ledger_hash": "7eab38af3c6b4d530962684f53cace3bd20294092e7e3e1bf1fd9f620afdb9af",
        "txlist_hash": "551ef3f97b4d928ccc261ab93afd70be7cd4d66df9f0fc134bd5267a0f0f031b",
    },
    813500: {
        "ledger_hash": "0b2209449b97f6bcd3e5435d0608ae46bd58d47a16352290601c237c86b1fd12",
        "txlist_hash": "a9b488c54c1ba46eac7aecac3cde36bb2a918c40fe3e2e01aced2da44f67048b",
    },
    814000: {
        "ledger_hash": "7ab7b94bd7e41183c43b74168ec8ab88eccd63c27b599fc82969ffbdf9f69712",
        "txlist_hash": "dccb050fa6eb5b34fd32989af5a3a5b4805a9e96b14c53f0e55ee58b96fb1d9e",
    },
    814500: {
        "ledger_hash": "bfc22992a47809741318a9dce0df82086bb52cbb30528a96fae823219cba3716",
        "txlist_hash": "63b2c1b603de93f79fdf8130befd3a5ae7cdac649d502525a7ed07aa15d86f5b",
    },
    815000: {
        "ledger_hash": "468f3f35a7b36acd5e1d1ed35bb5f4d0f59e0eae4eee25fc218c5bffed4378bc",
        "txlist_hash": "11304355f180fb6df6bdbb4c29dd5773571fbb895db005eed7eaadf801db60cd",
    },
    815500: {
        "ledger_hash": "1522653f1a44aba373e5566ff6054cc859cbfc9fa6deb931bad124db339c706a",
        "txlist_hash": "4d987a6c22f64ef88b5981cdbaeb1e6aa5c50414d092f9af8e473160a921203c",
    },
    816000: {
        "ledger_hash": "b2ee3deeb6e3bf75358442e2e5bbe3b01e189eaa8f6a4da0b481609de222f12d",
        "txlist_hash": "813959903d405d88f335ca5c5584fef830928f644a4a0c9323d6a58e380e2c72",
    },
    816500: {
        "ledger_hash": "ea378fc98675aec041bce57ad3001b8da96d6ed73c94c777d17f4ad9948e16e6",
        "txlist_hash": "8e875380f228a058d1adbabf83c53f4bf336fab9feb338eb7c0d6fd6f0fa61ef",
    },
    817000: {
        "ledger_hash": "c943e2550cfde4e788e45a59b12b697ed6c90b2a95b19a22959643047e917c86",
        "txlist_hash": "cd7e37a897dc03468321c41990f947f74de9d0df5dd28ef76b36252fff04df00",
    },
    817500: {
        "ledger_hash": "811ecbe290c96f67fd0024f3b4c8619d1feb370a3bab1e16cb4f13ef78049257",
        "txlist_hash": "c1e95697cd94a206eb8a88e686264982fa73066d58a14a3738f1788a244ad3f0",
    },
    818000: {
        "ledger_hash": "7ac0b51094ca369b8c48b32108cf41a0726f4ccbf8eb73ba4742fb1d6d57bec0",
        "txlist_hash": "90400654cb90116f5c0d80c687bb85a81bacfc05ff835d2259f992d890e93ac7",
    },
    818500: {
        "ledger_hash": "c9ef72367706d40a661701733e21b8653592a65675f643b38a6a3560316862d6",
        "txlist_hash": "4b19e461f08062a3de1284f5f2901afecb48a74b4043efa2289260f60102fa28",
    },
    819000: {
        "ledger_hash": "b2fcc13a24222e162fe617f9b65539bbbb26ca1fd93606225ddc01c7728df927",
        "txlist_hash": "de4fc83c68d3fcdfb36218136f7913b741163240f86b798aacfe0dc0a2be0747",
    },
    819500: {
        "ledger_hash": "06d3ea5ac968325c059c9cae9a26cbc2ebc782207909c21bce2c8dd7e2099d9e",
        "txlist_hash": "a58eeb487b7cfefb1ba9a582005abe088fae36eaffcc8934e1958d64b76d0397",
    },
    820000: {
        "ledger_hash": "c1396ef1d24e6d91b35c19cc0c77d548f733fd157c3997c479d88c39b61308f7",
        "txlist_hash": "e9ddc32575d88d3db4bab405e93375a36ac94c7c4e0f517a05042030a910bd24",
    },
    820500: {
        "ledger_hash": "ba98e7ce3442478a637c15971248d2ba2e9cdcbfde5d1cc41a8a20c5f99f3fe1",
        "txlist_hash": "1d88f2d94977f0f8b48b4a33e8169597aad971c0951575fc74a48b97afb2080f",
    },
    821000: {
        "ledger_hash": "3ff69ed9b4b02669910de04815c74b435f90a7e710f93b306af9fc5137b52397",
        "txlist_hash": "ee5640c80b46fb9641b94cf65cdbd293a417ce250183110088df1173926acad0",
    },
    821500: {
        "ledger_hash": "fb39fe3d8db5b204648dab9a5101289b86dc0753e00a7e5823ee8e832133ae3f",
        "txlist_hash": "089c3ab0af5dd54abd5310d222772aac19bb78d99d26bd5308df75281762a59b",
    },
    822000: {
        "ledger_hash": "246fde6117847546ad58f433c8ec612c8d3f70f76746b4e2cd42f0889dbeb250",
        "txlist_hash": "1fad6af3b0661de06077bdbe8e33ac587891421c34860411842dabe25ba8b240",
    },
    822500: {
        "ledger_hash": "84c23b4efa29204ba8c17c6021808fa6884c894e68870acc8792168e8aab4ab6",
        "txlist_hash": "8738084248b99a68688d10c977de0a8e41016727098480e8b4a991b98f6e54c8",
    },
    823000: {
        "ledger_hash": "841df3a3dfce77e498a7655bd26a81975a6361ee658e28c45eb26801919b255f",
        "txlist_hash": "53dd28b40d7ba794794458570fb880b108f9bc255f77721da128ac06f2e96e94",
    },
    823500: {
        "ledger_hash": "5412b27f65c89b41d549ec3f66d9cfa1bb59c089118ec7c33744352f249d08c3",
        "txlist_hash": "6ba608ca2d916ff04ff9e207b55a0dc683c90d5254594ca17d733894a2c3957c",
    },
    824000: {
        "ledger_hash": "934ba8b0c47f4e3cd747a453a269bfb7a0a7e9a6efa5b524dbd7fec1e01abcfa",
        "txlist_hash": "98b89c19185b6dea7942048efa40e995c51f9621c67a57d9a1d32061a5da0282",
    },
    824500: {
        "ledger_hash": "e72ff0594d0af112e9062632dedf9093e552635ee383f0b8246a22abc84f1ef7",
        "txlist_hash": "2f14438fbf9174dfd0e92e8d8f20aa856b4fbdb0ab1051064e5edde10a228e29",
    },
    825000: {
        "ledger_hash": "20810c4ac5fcac5f1b1e29b919fa270875f57949885c20deca8267dcebb39162",
        "txlist_hash": "543433ff913bf701b426cdd96ac472825b517c2b22973985bde6bc2dd3d7fc24",
    },
    826000: {
        "ledger_hash": "9b92062f20d2155ec4842c36aa45f575387b439f9ef8824da940411831112ec4",
        "txlist_hash": "6cb181cc35022b08a1cb43610c8eec6af5b0e05b5d600b3225a6108c00e2987d",
    },
    827000: {
        "ledger_hash": "27c6a7ac8fd135977c4b3a074cbd4019cd013313b5701e142453515f070c42ae",
        "txlist_hash": "08173eda8b7189a29a33c83059e92f4968e78ac883c516b7be566d03f28ca75a",
    },
    828000: {
        "ledger_hash": "692f9fbcb293353f8d0dfa60e34ce61a45613f0fd3e1290539375167fa26fd21",
        "txlist_hash": "13c17d1cf50f75d7c09b4ae72861af3712239475a6e2b3bbf0aca6b339d46601",
    },
    829000: {
        "ledger_hash": "9214253971aca45038be3fefcfa35eb52bc57a00249f10055dc3572bb1de43fd",
        "txlist_hash": "b326e64ec807702354ff0e1bb191893cbde2b73a03c7e2684a6602de2f994050",
    },
    830000: {
        "ledger_hash": "57207a541782ce2b637d7f3bb04bbce22830a1d4caf5d01d550dbb5a9bc7d95e",
        "txlist_hash": "92b7d7f0bc59e1e867e8d5e7c408f93d051288e6192c2a8fb204d80993c6ae57",
    },
    831000: {
        "ledger_hash": "e2dfdc4d22d7dfedcbe9ee3580e148d7c141082b16f23604c8cb135c1a16fa7a",
        "txlist_hash": "68667fb10b61c713326e22142e26d1fa7b0b2924b8d790b0400e836dbfc8b100",
    },
    832000: {
        "ledger_hash": "14c9254626becc77e73363fc0e6157e270b542e7e44e8bfda4efd4692c10c981",
        "txlist_hash": "65cab78d55fc5f7b8b03e7a4dcda9d764813d87b780066ef1f60ea243721337d",
    },
    833000: {
        "ledger_hash": "ace93e2e5f99a4738cb1b54dc68088ac60921decbd2eea9b12e2d6b034118938",
        "txlist_hash": "7b18037abeb8190d753f22682d5493f1de1c4b7c4ed6ef592f421b5a2b4d91e3",
    },
    834000: {
        "ledger_hash": "e37c5d49dbdb4d7a83d376d70d25797b80a2c5ccd481f47204960cc5d63f1f48",
        "txlist_hash": "09f21ff2a847de4a1fe823c6161810c684702956d53cb2602d31d27bef47466b",
    },
    834500: {
        "ledger_hash": "31b2d2737baf93970b15b2e7006f975ad95bde8b77017ddd9f970a7b170bb5f4",
        "txlist_hash": "df88725c205fef2ab157c93ec3894d6b8ee96ecd8b442fa6faede4db9641ed47",
    },
    835515: {
        "ledger_hash": "5c281647d363e02bb408ae6eab78678ee1227fd969d42a9c3821d3d967f4c701",
        "txlist_hash": "33753e3a1917d1c9b506de152aa5e19de3ee8d65ed086214d9838372d0618039",
    },
    838863: {
        "ledger_hash": "1c8cd670b76dc1dd86f2284f79d2c49d3dc0f12fd43680390ca27c90f98cc625",
        "txlist_hash": "7735e7b52d2e2bca4ef76de0a5a543a910a2bfe41f2e189236f04aa09a455340",
    },
    839910: {
        "ledger_hash": "3e67db9b6c99ecbf4cc9317d69aaf63a6ae6f574a02f1e55f91b3cba3131caf0",
        "txlist_hash": "76ff941f15588a41124839acc80cc655407242154ba452285a348f17146807b7",
    },
    842208: {
        "ledger_hash": "83d22a34d5d6368b07f0cafcbfb0885e3123fb9731972ba0d259808d5cf8f51a",
        "txlist_hash": "6e49153c8042f20227ffc52b4df7a450a8f8416230081e373dabf11e9aceb63d",
    },
    847469: {
        "ledger_hash": "a6f16aee0761c1bf4cbe19fcdfe0242fdcd1c6cb8f3a999c0b1f1e48bf3d85e0",
        "txlist_hash": "b59af166c3300e2e0f53951fa2663d6d717c69610bc0fa86b8d7b4675398870d",
    },
    850500: {
        "ledger_hash": "72144badbbcd20ee9615c19ac725a8f747cc1d984b5fa578036fb4a310eb7ef7",
        "txlist_hash": "993c980296307d38656b4458a9b3913a8028adc02630fb6a8c55bea009008dd7",
    },
    861500: {
        "ledger_hash": "9adb63dabbdf3d533efba149efadb6aad56035708d4eebb8c79ee45d8f886c54",
        "txlist_hash": "b05b906391cf96d5b4b5893c5fda13fb64635d26785ee3ad1330fe701eb41cb4",
    },
    866000: {
        "ledger_hash": "fda930cbe8cd33afe47e588df612e1e062c99de7313d34290bbb6eb3839f6801",
        "txlist_hash": "19d1621ea05abd741e05e361ce96708e8dc1b442fb89079af370abd2698549db",
    },
    866330: {
        "ledger_hash": "a02fb7ff41a9b5f479801f9ad42312760084bb50b09e939a14a44fd570b7f3f4",
        "txlist_hash": "1f5db508a80205eaaa6d915402c7833a0851bb369bea54a600e2fdda7e1d7ff5",
    },
    866750: {
        "ledger_hash": "25d586ba53e6e146732a7bab0258d6fdaf82734927d0b5e30828899bccb224df",
        "txlist_hash": "a536d8a1b2b3cf6164b9a2cd70edd2efaea615340e11291eebb6201c762aaaf5",
    },
    867290: {
        "ledger_hash": "f2f23ac95a168ac0f868088095cab3de859fab4fc87babcc80f19a2955756e3f",
        "txlist_hash": "b32df1c46cde54f9eb1075652634276d5fb997a85ca7394c6566810475b30c00",
    },
    869836: {
        "ledger_hash": "1e26c7ca9506ce17030e3612eb0d89c8ce4137d4adbe19c3ae5c76d70910f5c7",
        "txlist_hash": "58786555420ed0e1aa160d572adf33bf622842069212fd3f3aaf2889ff5b968f",
    },
    871781: {
        "ledger_hash": "3ac97511282b5f47ae3b495c078b003740380e51303ab00e6c507717ce980ea7",
        "txlist_hash": "f378bfec19139f0210808ef8d6c548452cca9e631e5742786d2af7595534106c",
    },
    872500: {
        "ledger_hash": "5e32cf4d00a2d61b96ab0b860856d958e879f7904d95b12acb9dbecc488e7c6d",
        "txlist_hash": "2f4cf3574a61a7575445dc9ad6f8650750bc0f93a03e586d65ec1c69322009a3",
    },
    873000: {
        "ledger_hash": "68dc18154c0fb8ea0eedc417d81d28122a779ee547c2bce48dc7ae6864cb238c",
        "txlist_hash": "a52eee6dc316f3fac4c19c48b6b52c3018ba1ba44a6dcf34c52303e9031ec300",
    },
    873500: {
        "ledger_hash": "11f4afcf50dc21c9039819550ede299b1d3f5d6e7fb34e2823be4d9d2d1aeb6b",
        "txlist_hash": "e085948ac68caf6b0718373ca80e8fbee5436e88c3c95c3a8fec39d08db8e646",
    },
    874548: {
        "ledger_hash": "7b32985ea64a6575805f11593649b30b2894923eee956ec25a6f51f856f7b265",
        "txlist_hash": "b3f549168f56702287c7b06c0348c4ac0adffcd219bab386d2f19326c0cd491c",
    },
    874883: {
        "ledger_hash": "0531617ee6b1cec54487201df683266968329d0502469a34593c6373b321b9e6",
        "txlist_hash": "f6a99d60337c33c1822c048f56e241455cd7e45bb5a9515096f1ac609d50f669",
    },
    879058: {
        "ledger_hash": "5c89e1f0e467a4b1a43982335279afbf65bd884aeabba94b610d167862c8d8a2",
        "txlist_hash": "e9946ac128405885f251fbb98a952ed554ea6cc25973261da9f40eabf4f3b429",
    },
    880354: {
        "ledger_hash": "627686472eef99883943fa76462ae36cc5d55e9009cc5b2f228362408c018aa0",
        "txlist_hash": "19923f986966bd6bd5c00e2e70bc7e995940bc31244e57285195340de6b90612",
    },
    883591: {
        "ledger_hash": "7385cd4f1cdc26603c3c0a237fedf2b4913aebc6b6aa08433e7eed2f5727a9e0",
        "txlist_hash": "e943367f21b3ac3579879bf1605359731dad314b40c1fe59aa630acfa50ada0e",
    },
    885705: {
        "ledger_hash": "9081a2768917f894eeb6ec692ffffeade57478e0cd446853a40d2711579eb723",
        "txlist_hash": "084c1e143f2b8f23615019ab08561c971cb02803eeab4ac99c5c003d088250f3",
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
        "txlist_hash": "3e29bcbf3873326097024cc26e9296f0164f552dd79c2ee7cfc344e6d64fa87d",
    },
    319000: {
        "ledger_hash": "c04ada0ac248dbd5529c457e7ff19cb1381ffd918fb9ce985ede2a0b59e97160",
        "txlist_hash": "6c05c98418a6daa6de82dd59e000d3f3f5407c5432d4ab7d76047873a38e4d4b",
    },
    322000: {
        "ledger_hash": "b9000189b5f3d1ea544607793b72a9caf463dc71831ac3a26369b46dc771f121",
        "txlist_hash": "18f278154e9bc3bbcc39da905ab4ad3023742ab7723b55b0fd1c58c36cd3e9bf",
    },
    325000: {
        "ledger_hash": "54c20c8af46b01583bc4df323b34d51ac021a87ed3090b34beee9ad5001fd26f",
        "txlist_hash": "1a60e38664b39e0f501b3e5a60c6fc0bd4ed311b74872922c2dde4cb2267fd3e",
    },
    329000: {
        "ledger_hash": "f9f6f94e1f59ee87dea8af9baa57e7dd1af6dfad90773981268ee04adb2a8bee",
        "txlist_hash": "79d577d8fbba0ad6ae67829dfa5824f758286ccd429d65b7d1d42989134d5b57",
    },
    350000: {
        "ledger_hash": "c50fcb3562e93485fc339f6ca5d0e81f03c15645770241cf42bdd5bb01c64c94",
        "txlist_hash": "097df9c3079df4d96f59518df72492dfd7a79716462e3a4a30d62a37aec6fc16",
    },
    400000: {
        "ledger_hash": "d30944db43e6f99f3ab8deb95e699b3996c1f35f74de48fd51e31e84b6a0e5b8",
        "txlist_hash": "a9fc42b69f80ec69f3f98e8a3cd81f4f946544fd0561a62a0891254c16970a87",
    },
    450000: {
        "ledger_hash": "91ad88fa3c18276d329c1a61cf4120939ef89ac792523fd5c9cbc96e609e7234",
        "txlist_hash": "05af651c1de49d0728834991e50000fbf2286d7928961b71917f682a0f2b7171",
    },
    500000: {
        "ledger_hash": "c1de2120844b4ed1af28ba8fd1f7cbd0a6d6af52f7ff91313f18a1723d8020eb",
        "txlist_hash": "663b34955116a96501e0c1c27f27d24bad7d45995913367553c5cfe4b8b9d0a9",
    },
    550000: {
        "ledger_hash": "963e005ba0efd0d9e519065ac345029ad1cad46b94fb4b8c040ad0836cef3f0f",
        "txlist_hash": "097b8bca7a243e0b9bdf089f34de15bd2dcd4727fb4e88aae7bfd96302250326",
    },
    600000: {
        "ledger_hash": "194839aca15c8c4e8bce8632911836de9693cbea9c3494626cd3cb3141372a06",
        "txlist_hash": "0d99f42184233426d70102d5ac3c80aaecf804d441a8a0d0ef26038d333ab7a7",
    },
    650000: {
        "ledger_hash": "ffb4f53065c79955a83060ea8dc499a913baf34115cc8ff6fead54f5c87f5e39",
        "txlist_hash": "409ed86e4274b511193d187df92e433c734dcc890bf93496e7a7dee770e7035e",
    },
    700000: {
        "ledger_hash": "33e175187bdbf8c2730edb7cb227af499be8e57f6a70eb25aa4d270b6762c56d",
        "txlist_hash": "4f9765158855d24950c7e076615b0ad5b72738d4d579decfd3b93c998edf4fcb",
    },
    750000: {
        "ledger_hash": "e863b286aa753d0d81594ab4d221167b03cc80bddd5807f712b9d25104fc8724",
        "txlist_hash": "6e511790656d3ffec0c912d697e5d1c2a4e401a1606203c77ab5a5855891bc2c",
    },
    800000: {
        "ledger_hash": "a87c5f3b8fc7d3ceedc8e4f88ce87f567bed19f362e49fcb000a00fbfce306fc",
        "txlist_hash": "885ae1e6c21f5fb3645231aaa6bb6910fc21a0ae0ca5dbe9a4011f3b5295b3e7",
    },
    850000: {
        "ledger_hash": "bcedc2a1059df83c93629537517776d3dc298b76a2f9fd10638d555a51f6bc07",
        "txlist_hash": "72d5cfe1e729a22da9eacd4d7752c881c43a191904556b65a0fae82b770dcdf3",
    },
    900000: {
        "ledger_hash": "8fa1c6d820c4139c8bd84f6040e07fb7c028215842a8342474a928f8cf72a11e",
        "txlist_hash": "5a2e9fbd9b52ee32b8e8bfff993ed92dc22510aa7448277a704176cf01e55b04",
    },
    950000: {
        "ledger_hash": "b86f73873675219e24baad6a73b315a8e97d112e2b9daa9efa3159a9dbc230d1",
        "txlist_hash": "f4fa9838fb38d3e5beffb760fae022dcc59c61c506dd28ac83ee48ba814d04b2",
    },
    1000000: {
        "ledger_hash": "c9931cf865fb3de09ed5bbe34649455a48da9478deb57d3a3aeb87130dfba352",
        "txlist_hash": "03deb626e031f30acd394bf49c35e11a487cb11e55dff5ba9a3f6d04b460c7de",
    },
    1050000: {
        "ledger_hash": "dc59520b130feed2a41c353e00db01d352d66d74ec10f99cfe56dc9f8003e6f8",
        "txlist_hash": "896274fdba957961083b07b80634126bc9f0434b67d723ed1fa83157ce5cd9a7",
    },
    1100000: {
        "ledger_hash": "51ac9510824f109866edaf76f2adf8f7ddcf0267f3beafe28010ef1994fbccdd",
        "txlist_hash": "36ecfd4b07f23176cd6960bc0adef97472c13793e53ac3df0eea0dd2e718a570",
    },
    1150000: {
        "ledger_hash": "089e883cb7c1f020abfd73ac731207af1dc9269ed4de788102b3675c7864cc0e",
        "txlist_hash": "9ff139dacf4b04293074e962153b972d25fa16d862dae05f7f3acc15e83c4fe8",
    },
    1200000: {
        "ledger_hash": "2344a261344d62c990e82eac92bee7fde74f23c1963c4231e79461b4ec21b4b3",
        "txlist_hash": "11dcf3a0ab714f05004a4e6c77fe425eb2a6427e4c98b7032412ab29363ffbb2",
    },
    1250000: {
        "ledger_hash": "9719ea43229540d9c2633b6d30032927932e0e0dbb4f7ceb45ffcfe224251dff",
        "txlist_hash": "c01ed3113f8fd3a6b54f5cefafd842ebf7c314ce82922e36236414d820c5277a",
    },
    1300000: {
        "ledger_hash": "5e6ebdd3966d44adf3fc64ca8b0e2dacd27638b2fc8ef75170c410333bd8f694",
        "txlist_hash": "67e663b75a80940941b8370ada4985be583edaa7ba454d49db9a864a7bb7979c",
    },
    1350000: {
        "ledger_hash": "2b4da40c0b41c6fd3ec67811cbc16d5ed04f5817cba98cca81c77ce52bda7ac4",
        "txlist_hash": "83e7d31217af274b13889bd8b9f8f61afcd7996c2c8913e9b53b1d575f54b7c1",
    },
    1400000: {
        "ledger_hash": "baa29889e35cb8ed47abd045c65a567150c2c8250b21fea1987502ab5750c34c",
        "txlist_hash": "eee762f34a3f82e6332c58e0c256757d97ca308719323af78bf5924f08463e12",
    },
    1600000: {
        "ledger_hash": "4614b4cb52433369570981de4267cf44a1f1cf1b7a45e95d3a5b0d271b482b1a",
        "txlist_hash": "f720b44719e01a1dbcffe572947a88d943c4841365bea744debc7d26007611c9",
    },
    1700000: {
        "ledger_hash": "221e4e2860e4993e50f15624fd3d3fa1286a9ba498b5afa93a9706c2d11f11a1",
        "txlist_hash": "473eab0cf9c07dd869d57839d886efca0b03769672cbb659dc542d748cf77711",
    },
    1800000: {
        "ledger_hash": "cb55894c81cffff0041039381139fa842953c920d491f1f8704448123df6b5f9",
        "txlist_hash": "bc26c44d4ce55be408b38fe14e4659fa655a8386e2d389fe3b7bfb25b4364bd3",
    },
    1900000: {
        "ledger_hash": "6417ce2d7a3815731376f3b0251e6bb2d00e8d92fd1c2f00e779e33919b37996",
        "txlist_hash": "2b4d321495f04a3065bdd4f0987fd86a54669fb85426152eb1b4a1b8fd11d799",
    },
    2000000: {
        "ledger_hash": "d73327f2d45cb7fe15c1609e205b07d1b1744343a8bfb9013b71e568e98415b1",
        "txlist_hash": "79249281e49719805533be84006c2c48be7ea0c3d14048c1205458c90e7b3158",
    },
    2200000: {
        "ledger_hash": "d530d753e4c906435710c60f50ef67bb7c656f38ed41e6dda9d972df2c12b7d5",
        "txlist_hash": "8f4ffacc471fd80c8327d163ebe7ff26a0d00ec03672acaff911d16eb37547fd",
    },
    2400000: {
        "ledger_hash": "4a3e8244c5faed39af338015ba6b0e30c856116c6578d8d8a035d6b715729bdc",
        "txlist_hash": "36bbd14c69e5fc17cb1e69303affcb808909757395d28e3e3da83394260bf0dd",
    },
    2500000: {
        "ledger_hash": "6c4ae3fca5c3a2a0c2b6d9b8d441c983de79acc029dd0aa125f3775d3dc9ecbc",
        "txlist_hash": "26567e5c45a59426b2bcdeb177167a92c5fc21e8fd2000ae9a24eb09e3945f70",
    },
    2540000: {
        "ledger_hash": "1e3c5f77592abae55c0afc455dc1723e929a15925f2b025b42945eddcf42a98d",
        "txlist_hash": "45e134cb4196bc5cfb4ef9b356e02025f752a9bc0ae635bc9ced2c471ecfcb6c",
    },
    2580000: {
        "ledger_hash": "75a6fcc4e7868692ae6af5b7b9399f3fb84c61bdcc5f6b2fc017bf0f65ba4bb6",
        "txlist_hash": "dc1f037beb8a632c5277fa0e6fd52866f0370d1f93de024420a7c31ce956c812",
    },
    2586067: {
        "ledger_hash": "b3d8f759fe027da3970c07312b112d39e10231dae519d9b8e63d187bdc8854ba",
        "txlist_hash": "1bfe60296102f50272abc664ee42f4fb70818b7211e36dafa6e6bad6194fc833",
    },
    2820893: {
        "ledger_hash": "89383b665275451637d12bdc337bf51748b92f7a561fef8f9e72f53536c650d6",
        "txlist_hash": "5db6363332cee5ccd16370af747050bad438a6bcf52f2004b3b9db1c8b8ef8ee",
    },
}

CONSENSUS_HASH_VERSION_REGTEST = 1
CHECKPOINTS_REGTEST = {
    config.BLOCK_FIRST_REGTEST: {
        "ledger_hash": "33cf0669a0d309d7e6b1bf79494613b69262b58c0ea03c9c221d955eb4c84fe5",
        "txlist_hash": "33cf0669a0d309d7e6b1bf79494613b69262b58c0ea03c9c221d955eb4c84fe5",
        "migration_hash": "33cf0669a0d309d7e6b1bf79494613b69262b58c0ea03c9c221d955eb4c84fe5",
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
        "txlist_hash": "4b610518a76f59e8f98922f37434be9bb5567040afebabda6ee69b4f92b80434",
    },
    66241: {
        "ledger_hash": "2813bd0167616f222087507d9def101dde3fd20b0d1f23e9a10202aecfadc62d",
        "txlist_hash": "17af3a72503c8911a047d370da48ccce881c8dffa558f6287cfccbcde7e45c2b",
    },
    68000: {
        "ledger_hash": "ba69ca87e5e95a6c6eea5f3d6e0fac53398a31963500ada245d971bdadee30d4",
        "txlist_hash": "f62e6a6a912759d208c5ee5a8edb5b4b75b21e8947a466c3ea68b9ef3e5609f9",
    },
    69000: {
        "ledger_hash": "3b76217d649c015745b51c9098d7396141909a9a89a4918c2aa2f8ca870809a2",
        "txlist_hash": "3bb43318a5c83558ac4a9c8b0da7e2bb9b4022042e83504080f8d5e967fadf84",
    },
    70000: {
        "ledger_hash": "3613f02e6e5bfc2ddfd1a629d411f72bc76095b078e7a863652305962cee9f20",
        "txlist_hash": "b9618d0dd4574b0fd55b31a4ae5956973f31ce234cc44a2252017c2547dc1572",
    },
    71000: {
        "ledger_hash": "deadbf16d58d27c05571dd166d4e151d2b94fe8c7bb7ebdcd5acad74baf49c5c",
        "txlist_hash": "1d8d3ee7f415b41839361e70d88ffa5bacc5c8c84369798b64b79623fbe97aae",
    },
    72000: {
        "ledger_hash": "6b65bad08047eaaf9690ff0d95ee6f01a97b3b67f7a376407b28cbd7bb10b852",
        "txlist_hash": "891b83c025abb23aacfa91c885db969acef7f2115b769b60240a8eed7cb52754",
    },
}
