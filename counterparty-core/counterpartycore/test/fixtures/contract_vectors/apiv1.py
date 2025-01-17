from counterpartycore.lib import exceptions

from ..params import ADDR, DP, MULTISIGADDR, P2SH_ADDR

API_V1_VECTOR = {
    "apiv1": {
        "test_rpc": [
            {
                "comment": "burn 1",
                "in": (
                    "create_burn",
                    {
                        "source": ADDR[1],
                        "quantity": DP["burn_quantity"],
                        "encoding": "multisig",
                    },
                ),
                "out": "0200000001ebe3111881a8733ace02271dcf606b7450c41a48c1cb21fd73f4ba787b353ce40000000000ffffffff02800bb203000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88acdad24302000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000",
            },
            {
                "comment": "send 1",
                "in": (
                    "create_send",
                    {
                        "source": ADDR[0],
                        "destination": ADDR[1],
                        "asset": "XCP",
                        "quantity": DP["small"],
                        "encoding": "multisig",
                    },
                ),
                "out": "0200000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae0000000000ffffffff0322020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ace8030000000000006951210262415bf04af834423d3dd7ada4dc727a030865759f9fba5aee78c9ea71e58798210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aee253ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
            },
            {
                "comment": "send 2",
                "in": (
                    "create_send",
                    {
                        "source": P2SH_ADDR[0],
                        "destination": ADDR[1],
                        "asset": "XCP",
                        "quantity": DP["small"],
                        "encoding": "multisig",
                        "dust_return_pubkey": False,
                        "regular_dust_size": DP["regular_dust_size"],
                    },
                ),
                "out": "02000000015001af2c4c3bc2c43b6233261394910d10fb157a082d9b3038c65f2d01e4ff200000000000ffffffff0336150000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ace8030000000000006951210397b51de78b0f3a171f5ed27fff56d17dcba739c8b00035c8bbb9c380fdc4ed1321036932bcbeac2a4d8846b7feb4bf93b2b88efd02f2d8dc1fc0067bcc972257e391210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aef6c2f5050000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e8700000000",
            },
            {
                "comment": "issuance 1",
                "in": (
                    "create_issuance",
                    {
                        "source": ADDR[0],
                        "transfer_destination": None,
                        "asset": "BSSET",
                        "quantity": 1000,
                        "divisible": True,
                        "description": "",
                        "encoding": "multisig",
                    },
                ),
                "out": "0200000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae0000000000ffffffff02e8030000000000006951210358415bf04af834423d3dd7adb2dc727a03086e897d9fba5aee7a331919e487d6210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae4056ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
            },
            {
                "comment": "issuance 2",
                "in": (
                    "create_issuance",
                    {
                        "source": ADDR[0],
                        "transfer_destination": ADDR[1],
                        "asset": "DIVISIBLE",
                        "quantity": 0,
                        "divisible": True,
                        "description": "",
                        "encoding": "multisig",
                    },
                ),
                "out": "0200000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae0000000000ffffffff0322020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ace8030000000000006951210258415bf04af834423d3dd7adb2dc727aa153863ef89fba5aee7a331af1e4874b210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aee253ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
            },
            {
                "comment": "order 1",
                "in": (
                    "create_order",
                    {
                        "source": ADDR[0],
                        "give_asset": "BTC",
                        "give_quantity": DP["small"],
                        "get_asset": "XCP",
                        "get_quantity": DP["small"] * 2,
                        "expiration": DP["expiration"],
                        "fee_required": 0,
                        "fee_provided": DP["fee_provided"],
                        "encoding": "multisig",
                    },
                ),
                "out": "0200000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae0000000000ffffffff02e8030000000000006951210348415bf04af834423d3dd7adaedc727a030865759e9fba5aee78c9ea71e5870f210354da540fb2673b75e6c3c994f80ad0c8431643bab28ced783cd94079bbe72445210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae4056ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
            },
            {
                "comment": "order 2",
                "in": (
                    "create_order",
                    {
                        "source": ADDR[0],
                        "give_asset": "XCP",
                        "give_quantity": round(DP["small"] * 2.1),
                        "get_asset": "BTC",
                        "get_quantity": DP["small"],
                        "expiration": DP["expiration"],
                        "fee_required": DP["fee_required"],
                        "encoding": "multisig",
                    },
                ),
                "out": "0200000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae0000000000ffffffff02e8030000000000006951210248415bf04af834423d3dd7adaedc727a030865759f9fba5aee7c7136b1e58715210354da540fb2663b75e6c3ce9be98ad0c8431643bab28156d83cd94079bbe72460210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae4056ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
            },
            {
                "comment": "burn 2",
                "in": (
                    "create_burn",
                    {
                        "source": MULTISIGADDR[0],
                        "quantity": int(DP["quantity"] / 2),
                        "encoding": "multisig",
                    },
                ),
                "out": "0200000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f0000000000ffffffff0280f0fa02000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac94ebfa02000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000",
            },
            {
                "comment": "send 3",
                "in": (
                    "create_send",
                    {
                        "source": ADDR[0],
                        "destination": MULTISIGADDR[0],
                        "asset": "XCP",
                        "quantity": DP["quantity"],
                        "encoding": "multisig",
                    },
                ),
                "out": "0200000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae0000000000ffffffff03e8030000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aee8030000000000006951210362415bf04af834423d3dd7ada4dc727a030865759f9fba5aee7fc6fbf1e5875a210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aea84dea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
            },
            {
                "comment": "send 4",
                "in": (
                    "create_send",
                    {
                        "source": MULTISIGADDR[0],
                        "destination": ADDR[0],
                        "asset": "XCP",
                        "quantity": DP["quantity"],
                        "encoding": "multisig",
                    },
                ),
                "out": "0200000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f0000000000ffffffff0322020000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ace8030000000000006951210334caf7ca87f0fd78a01d9a0d68221e55beef3722da8be72d254dd351c26108892102bc14528340c27d005aa9e2913fd8c032ffa94625307a450077125d580099b57d210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae5ad1f505000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000",
            },
            {
                "comment": "send 5",
                "in": (
                    "create_send",
                    {
                        "source": MULTISIGADDR[0],
                        "destination": MULTISIGADDR[1],
                        "asset": "XCP",
                        "quantity": DP["quantity"],
                        "encoding": "multisig",
                    },
                ),
                "out": "0200000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f0000000000ffffffff03e8030000000000004751210378ee11c3fb97054877a809ce083db292b16d971bcdc6aa4c8f92087133729d8b210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aee8030000000000006951210334caf7ca87f0fd78a01d9a0d68221e55beef3722da8be72d254dd351c26108892102bc14528340c27d005aa9e2913fd8c032ffa94625307a450077125d580099b57d210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae20cbf505000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000",
            },
            {
                "comment": "issuance 3",
                "in": (
                    "create_issuance",
                    {
                        "source": MULTISIGADDR[0],
                        "transfer_destination": None,
                        "asset": "BSSET",
                        "quantity": 1000,
                        "divisible": True,
                        "description": "",
                        "encoding": "multisig",
                    },
                ),
                "out": "0200000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f0000000000ffffffff02e803000000000000695121020ecaf7ca87f0fd78a01d9a0d7e221e55beef3cde388be72d254826b32a6008382102bc14528340c27d005aa9e2913fd8c032ffa94625307a450077125d580099b57d210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aeb8d3f505000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000",
            },
            {
                "comment": "issuance 4",
                "in": (
                    "create_issuance",
                    {
                        "source": ADDR[0],
                        "transfer_destination": MULTISIGADDR[0],
                        "asset": "DIVISIBLE",
                        "quantity": 0,
                        "divisible": True,
                        "description": "",
                        "encoding": "multisig",
                    },
                ),
                "out": "0200000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae0000000000ffffffff03e8030000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aee8030000000000006951210258415bf04af834423d3dd7adb2dc727aa153863ef89fba5aee7a331af1e4874b210254da540fb2663b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe72447210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aea84dea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
            },
            {
                "comment": "issuance 5",
                "in": (
                    "create_issuance",
                    {
                        "source": ADDR[0],
                        "asset": f"A{2**64 - 1}",
                        "quantity": 1000,
                        "encoding": "multisig",
                    },
                ),
                "out": "0200000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae0000000000ffffffff02e8030000000000006951210255415bf04af834423d3dd7adb2238d85fcf79a8a619fba5aee7a331919e4870d210254da540fb2663b75268d992d550ad0c2431643bab28ced783cd94079bbe7244d210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae4056ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
            },
            {
                "comment": "order 3",
                "in": (
                    "create_order",
                    {
                        "source": MULTISIGADDR[0],
                        "give_asset": "BTC",
                        "give_quantity": DP["small"],
                        "get_asset": "XCP",
                        "get_quantity": DP["small"] * 2,
                        "expiration": DP["expiration"],
                        "fee_required": 0,
                        "fee_provided": DP["fee_provided"],
                        "encoding": "multisig",
                    },
                ),
                "out": "0200000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f0000000000ffffffff02e803000000000000695121021ecaf7ca87f0fd78a01d9a0d62221e55beef3722db8be72d254adc40426108d02103bc14528340c37d005aa9e764ded8c038ffa94625307a450077125d580099b53b210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aeb8d3f505000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000",
            },
            {
                "comment": "order 4",
                "in": (
                    "create_order",
                    {
                        "source": MULTISIGADDR[0],
                        "give_asset": "XCP",
                        "give_quantity": round(DP["small"] * 2.1),
                        "get_asset": "BTC",
                        "get_quantity": DP["small"],
                        "expiration": DP["expiration"],
                        "fee_required": DP["fee_required"],
                        "encoding": "multisig",
                    },
                ),
                "out": "0200000001051511b66ba309e3dbff1fde22aefaff4190675235a010a5c6acb1e43da8005f0000000000ffffffff02e803000000000000695121031ecaf7ca87f0fd78a01d9a0d62221e55beef3722da8be72d254e649c8261083d2102bc14528340c27d005aa9e06bcf58c038ffa946253077fea077125d580099b5bb210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aeb8d3f505000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000",
            },
            {
                "comment": "dividend 1",
                "in": (
                    "create_dividend",
                    {
                        "source": ADDR[0],
                        "quantity_per_unit": DP["quantity"],
                        "asset": "DIVISIBLE",
                        "dividend_asset": "XCP",
                        "encoding": "multisig",
                    },
                ),
                "out": "0200000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae0000000000ffffffff02e803000000000000695121035a415bf04af834423d3dd7ad96dc727a030d90949e9fba5a4c21d05197e58735210254da540fb2673b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe7246f210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae4056ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
            },
            {
                "comment": "dividend 2",
                "in": (
                    "create_dividend",
                    {
                        "source": ADDR[0],
                        "quantity_per_unit": 1,
                        "asset": "NODIVISIBLE",
                        "dividend_asset": "XCP",
                        "encoding": "multisig",
                    },
                ),
                "out": "0200000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae0000000000ffffffff02e803000000000000695121025a415bf04af834423d3dd7ad96dc727a030865759f9fbc9036a64c1197e587c8210254da540fb2673b75e6c3cc61190ad0c2431643bab28ced783cd94079bbe7246f210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae4056ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                # CIP 9 enhanced_send tests
            },
            {
                "comment": "standard op return send",
                "mock_protocol_changes": {"enhanced_sends": False},
                "in": (
                    "create_send",
                    {
                        "source": ADDR[0],
                        "destination": ADDR[1],
                        "asset": "XCP",
                        "quantity": DP["small"],
                    },
                ),
                "out": "0200000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae0000000000ffffffff0322020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000000000001e6a1c2a504df746f83442653dd7ada4dc727a030865749e9fba5aec80c39ad759ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
            },
            {
                "comment": "standard op return send (with API parameter)",
                "mock_protocol_changes": {"enhanced_sends": True},
                "in": (
                    "create_send",
                    {
                        "use_enhanced_send": False,
                        "source": ADDR[0],
                        "destination": ADDR[1],
                        "asset": "XCP",
                        "quantity": DP["small"],
                    },
                ),
                "out": "0200000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae0000000000ffffffff0322020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000000000001e6a1c2a504df746f83442653dd7ada4dc727a030865749e9fba5aec80c39ad759ea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
            },
            {
                "comment": "CIP 9 enhanced_send (op_return)",
                "mock_protocol_changes": {"enhanced_sends": True},
                "in": (
                    "create_send",
                    {
                        "source": ADDR[0],
                        "destination": ADDR[1],
                        "asset": "XCP",
                        "quantity": DP["small"],
                    },
                ),
                "out": "0200000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae0000000000ffffffff020000000000000000336a312a504df746f83442653dd7afa4dc727a030865749e9fba5aec80c39a9e68edbc79e78ed45723c1072c38aededa458f95fa205cea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
            },
            {
                "comment": "CIP 9 enhanced_send with memo",
                "mock_protocol_changes": {"enhanced_sends": True},
                "in": (
                    "create_send",
                    {
                        "memo": "hello",
                        "source": ADDR[0],
                        "destination": ADDR[1],
                        "asset": "XCP",
                        "quantity": DP["small"],
                    },
                ),
                "out": "0200000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae0000000000ffffffff020000000000000000386a362a504df746f83442653dd7afa4dc727a030865749e9fba5aec80c39a9e68edbc79e78ed45723c1072c38aededa458f95fa2bdfdee082115cea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
            },
            {
                "comment": "CIP 9 enhanced_send with memo as hex",
                "mock_protocol_changes": {"enhanced_sends": True},
                "in": (
                    "create_send",
                    {
                        "memo": "0102030405",
                        "memo_is_hex": True,
                        "source": ADDR[0],
                        "destination": ADDR[1],
                        "asset": "XCP",
                        "quantity": DP["small"],
                    },
                ),
                "out": "0200000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae0000000000ffffffff020000000000000000386a362a504df746f83442653dd7afa4dc727a030865749e9fba5aec80c39a9e68edbc79e78ed45723c1072c38aededa458f95fa42b8b188e8115cea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
            },
            {
                "comment": "CIP 9 enhanced_send before enabled",
                "mock_protocol_changes": {"enhanced_sends": False},
                "in": (
                    "create_send",
                    {
                        "memo": "0102030405",
                        "memo_is_hex": True,
                        "source": ADDR[0],
                        "destination": ADDR[1],
                        "asset": "XCP",
                        "quantity": DP["small"],
                    },
                ),
                "error": (
                    exceptions.RPCError,
                    "Error composing send transaction via API: enhanced sends are not enabled (-32001)",
                ),
            },
            {
                "comment": "CIP 9 enhanced send to a REQUIRE_MEMO address without memo",
                "mock_protocol_changes": {
                    "enhanced_sends": True,
                    "options_require_memo": True,
                },
                "in": (
                    "create_send",
                    {
                        "source": ADDR[0],
                        "destination": ADDR[6],
                        "asset": "XCP",
                        "quantity": DP["small"],
                    },
                ),
                "error": (
                    exceptions.RPCError,
                    "Error composing send transaction via API: ['destination requires memo'] (-32001)",
                ),
            },
            {
                "comment": "CIP 9 enhanced send to a REQUIRE_MEMO address with memo",
                "mock_protocol_changes": {
                    "enhanced_sends": True,
                    "options_require_memo": True,
                },
                "in": (
                    "create_send",
                    {
                        "memo": "0102030405",
                        "memo_is_hex": True,
                        "source": ADDR[0],
                        "destination": ADDR[6],
                        "asset": "XCP",
                        "quantity": DP["small"],
                    },
                ),
                "out": "0200000001c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae0000000000ffffffff020000000000000000386a362a504df746f83442653dd7afa4dc727a030865749e9fba5aec80c39a9e56174ca4a68af644972baced7a9ef02e467cb63542b8b188e8115cea0b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
                # get_tx_info API method
            },
            {
                "comment": "get_tx_info for a legacy send",
                "in": (
                    "get_tx_info",
                    {
                        "tx_hex": "01000000"
                        + "01"
                        + "c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae"
                        + "00000000"
                        + "19"
                        + "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"
                        + "ffffffff"
                        + "03"
                        + "2202000000000000"
                        + "19"
                        + "76a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac"
                        + "0000000000000000"
                        + "1e"
                        + "6a1c2a504df746f83442653dd7ada4dc727a030865749e9fba5aec80c39a"
                        + "4343ea0b00000000"
                        + "19"
                        + "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"
                        + "00000000"
                    },
                ),
                "out": [
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                    546,
                    6575,
                    "0000000000000000000000010000000002faf080",
                ],
            },
            {
                "comment": "get_tx_info for an enhanced send",
                "mock_protocol_changes": {
                    "enhanced_sends": True,
                },
                "in": (
                    "get_tx_info",
                    {
                        "tx_hex": "01000000"
                        + "01"
                        + "c1d8c075936c3495f6d653c50f73d987f75448d97a750249b1eb83bee71b24ae"
                        + "00000000"
                        + "19"
                        + "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"
                        + "ffffffff"
                        + "02"
                        + "0000000000000000"
                        + "33"
                        + "6a312a504df746f83442653dd7afa4dc727a030865749e9fba5aec80c39a9e68edbc79e78ed45723c1072c38aededa458f95fa"
                        + "aa46ea0b00000000"
                        + "19"
                        + "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"
                        + "00000000"
                    },
                ),
                "out": [
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    "",
                    0,
                    6250,
                    "0000000200000000000000010000000002faf0806f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec",
                ],
                # unpack API method
            },
            {
                "comment": "Unpack a data hex for a legacy send",
                "in": ("unpack", {"data_hex": "0000000000000000000000010000000002faf080"}),
                "out": [0, {"asset": "XCP", "quantity": 50000000}],
            },
            {
                "comment": "Unpack a data hex for an enahcned send",
                "mock_protocol_changes": {"enhanced_sends": True, "options_require_memo": True},
                "in": (
                    "unpack",
                    {
                        "data_hex": "0000000200000000000000010000000002faf0806f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec"
                    },
                ),
                "out": [
                    2,
                    {
                        "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "asset": "XCP",
                        "memo": None,
                        "quantity": 50000000,
                    },
                ],
            },
        ],
        "get_rows": [
            {
                "in": ("balances", None, "AND", None, None, None, None, None, 1000, 0, True),
                "out": None,
            },
            {
                "in": ("balances", None, "barfoo", None, None, None, None, None, 1000, 0, True),
                "error": (exceptions.APIError, "Invalid filter operator (OR, AND)"),
            },
            {
                "in": (None, None, "AND", None, None, None, None, None, 1000, 0, True),
                "error": (exceptions.APIError, "Unknown table"),
            },
            {
                "in": (
                    "balances",
                    None,
                    "AND",
                    None,
                    "barfoo",
                    None,
                    None,
                    None,
                    1000,
                    0,
                    True,
                ),
                "error": (exceptions.APIError, "Invalid order direction (ASC, DESC)"),
            },
            {
                "in": ("balances", None, "AND", None, None, None, None, None, 1000.0, 0, True),
                "error": (exceptions.APIError, "Invalid limit"),
            },
            {
                "in": ("balances", None, "AND", None, None, None, None, None, 1001, 0, True),
                "error": (exceptions.APIError, "Limit should be lower or equal to 1000"),
            },
            {
                "in": ("balances", None, "AND", None, None, None, None, None, 1000, 0.0, True),
                "error": (exceptions.APIError, "Invalid offset"),
            },
            {
                "in": ("balances", None, "AND", "*", None, None, None, None, 1000, 0, True),
                "error": (exceptions.APIError, "Invalid order_by, must be a field name"),
            },
            {
                "in": ("balances", [0], "AND", None, None, None, None, None, 1000, 0, True),
                "error": (exceptions.APIError, "Unknown filter type"),
            },
            {
                "in": (
                    "balances",
                    {"field": "bar", "op": "="},
                    "AND",
                    None,
                    None,
                    None,
                    None,
                    None,
                    1000,
                    0,
                    True,
                ),
                "error": (exceptions.APIError, "A specified filter is missing the 'value' field"),
            },
            {
                "in": (
                    "balances",
                    {"field": "bar", "op": "=", "value": {}},
                    "AND",
                    None,
                    None,
                    None,
                    None,
                    None,
                    1000,
                    0,
                    True,
                ),
                "error": (exceptions.APIError, "Invalid value for the field 'bar'"),
            },
            {
                "in": (
                    "balances",
                    {"field": "bar", "op": "=", "value": [0, 2]},
                    "AND",
                    None,
                    None,
                    None,
                    None,
                    None,
                    1000,
                    0,
                    True,
                ),
                "error": (exceptions.APIError, "Invalid value for the field 'bar'"),
            },
            {
                "in": (
                    "balances",
                    {"field": "bar", "op": "AND", "value": 0},
                    "AND",
                    None,
                    None,
                    None,
                    None,
                    None,
                    1000,
                    0,
                    True,
                ),
                "error": (exceptions.APIError, "Invalid operator for the field 'bar'"),
            },
            {
                "in": (
                    "balances",
                    {"field": "bar", "op": "=", "value": 0, "case_sensitive": 0},
                    "AND",
                    None,
                    None,
                    None,
                    None,
                    None,
                    1000,
                    0,
                    True,
                ),
                "error": (exceptions.APIError, "case_sensitive must be a boolean"),
            },
            {
                "comment": "standard send with no memo",
                "in": (
                    "sends",
                    [{"field": "block_index", "op": "=", "value": "310496"}],
                    "AND",
                    None,
                    None,
                    None,
                    None,
                    None,
                    1000,
                    0,
                    True,
                ),
                "out": [
                    {
                        "tx_index": 497,
                        "tx_hash": "84b4bd0c150568ee571bf8ed214bea317df588eaebea3daa91bea38103fedf11",
                        "block_index": 310496,
                        "source": "mnfAHmddVibnZNSkh8DvKaQoiEfNsxjXzH",
                        "destination": "mqPCfvqTfYctXMUfmniXeG2nyaN8w6tPmj",
                        "source_address": None,
                        "destination_address": None,
                        "asset": "XCP",
                        "quantity": 92945878046,
                        "status": "valid",
                        "memo": None,
                        "memo_hex": None,
                        "msg_index": 0,
                        "fee_paid": 0,
                        "send_type": "send",
                    }
                ],
            },
            {
                "comment": "with memo",
                "in": (
                    "sends",
                    [{"field": "block_index", "op": "=", "value": "310481"}],
                    "AND",
                    None,
                    None,
                    None,
                    None,
                    None,
                    1000,
                    0,
                    True,
                ),
                "out": [
                    {
                        "tx_index": 482,
                        "tx_hash": "7821095a0f835691e8c3989d90542a16b326d77323408082e9d0ac4c3d04e121",
                        "block_index": 310481,
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "source_address": None,
                        "destination_address": None,
                        "asset": "XCP",
                        "quantity": 100000000,
                        "status": "valid",
                        "memo": "hello",
                        "memo_hex": "68656c6c6f",
                        "msg_index": 0,
                        "fee_paid": 0,
                        "send_type": "send",
                    }
                ],
            },
            {
                "comment": "search by memo (text)",
                "in": (
                    "sends",
                    [{"field": "memo", "op": "=", "value": "hello"}],
                    "AND",
                    None,
                    None,
                    None,
                    None,
                    None,
                    1000,
                    0,
                    True,
                ),
                "out": [
                    {
                        "tx_index": 482,
                        "tx_hash": "7821095a0f835691e8c3989d90542a16b326d77323408082e9d0ac4c3d04e121",
                        "block_index": 310481,
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "source_address": None,
                        "destination_address": None,
                        "asset": "XCP",
                        "quantity": 100000000,
                        "status": "valid",
                        "memo": "hello",
                        "memo_hex": "68656c6c6f",
                        "msg_index": 0,
                        "fee_paid": 0,
                        "send_type": "send",
                    }
                ],
            },
            {
                "comment": "search by memo (LIKE text)",
                "in": (
                    "sends",
                    [{"field": "memo", "op": "LIKE", "value": "%ell%"}],
                    "AND",
                    None,
                    None,
                    None,
                    None,
                    None,
                    1000,
                    0,
                    True,
                ),
                "out": [
                    {
                        "tx_index": 482,
                        "tx_hash": "7821095a0f835691e8c3989d90542a16b326d77323408082e9d0ac4c3d04e121",
                        "block_index": 310481,
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "source_address": None,
                        "destination_address": None,
                        "asset": "XCP",
                        "quantity": 100000000,
                        "status": "valid",
                        "memo": "hello",
                        "memo_hex": "68656c6c6f",
                        "msg_index": 0,
                        "fee_paid": 0,
                        "send_type": "send",
                    }
                ],
            },
            {
                "comment": "search by memo hex",
                "in": (
                    "sends",
                    [{"field": "memo_hex", "op": "=", "value": "68656C6C6F"}],
                    "AND",
                    None,
                    None,
                    None,
                    None,
                    None,
                    1000,
                    0,
                    True,
                ),
                "out": [
                    {
                        "tx_index": 482,
                        "tx_hash": "7821095a0f835691e8c3989d90542a16b326d77323408082e9d0ac4c3d04e121",
                        "block_index": 310481,
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "source_address": None,
                        "destination_address": None,
                        "asset": "XCP",
                        "quantity": 100000000,
                        "status": "valid",
                        "memo": "hello",
                        "memo_hex": "68656c6c6f",
                        "msg_index": 0,
                        "fee_paid": 0,
                        "send_type": "send",
                    }
                ],
            },
            {
                "comment": "search by memo hex",
                "in": (
                    "sends",
                    [{"field": "memo_hex", "op": "=", "value": "68656c6c6f"}],
                    "AND",
                    None,
                    None,
                    None,
                    None,
                    None,
                    1000,
                    0,
                    True,
                ),
                "out": [
                    {
                        "tx_index": 482,
                        "tx_hash": "7821095a0f835691e8c3989d90542a16b326d77323408082e9d0ac4c3d04e121",
                        "block_index": 310481,
                        "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "source_address": None,
                        "destination_address": None,
                        "asset": "XCP",
                        "quantity": 100000000,
                        "status": "valid",
                        "memo": "hello",
                        "memo_hex": "68656c6c6f",
                        "msg_index": 0,
                        "fee_paid": 0,
                        "send_type": "send",
                    }
                ],
            },
            {
                "comment": "search with invalid memo hex",
                "in": (
                    "sends",
                    [{"field": "memo_hex", "op": "=", "value": "badx"}],
                    "AND",
                    None,
                    None,
                    None,
                    None,
                    None,
                    1000,
                    0,
                    True,
                ),
                "error": (exceptions.APIError, "Invalid memo_hex value"),
            },
            {
                "comment": "search by memo hex",
                "in": (
                    "sends",
                    [{"field": "memo_hex", "op": "=", "value": "fade0001"}],
                    "AND",
                    None,
                    None,
                    None,
                    None,
                    None,
                    1000,
                    0,
                    True,
                ),
                "out": [
                    {
                        "tx_index": 483,
                        "tx_hash": "df7c7591bbfffc8c7e172e90effdff069c9742c13ae7b1066214bcbb9c2f6883",
                        "block_index": 310482,
                        "source": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "destination": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "source_address": None,
                        "destination_address": None,
                        "asset": "XCP",
                        "quantity": 100000000,
                        "status": "valid",
                        "memo": "",
                        "memo_hex": "fade0001",
                        "msg_index": 0,
                        "fee_paid": 0,
                        "send_type": "send",
                    }
                ],
            },
        ],
    },
}
