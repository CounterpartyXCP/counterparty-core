import re

import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.api import apiv1
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def test_create_burn(apiv1_client, defaults):
    with ProtocolChangesDisabled("taproot_support"):
        result = apiv1_client(
            "create_send",
            {
                "source": defaults["addresses"][0],
                "destination": defaults["addresses"][1],
                "asset": "XCP",
                "quantity": defaults["small"],
            },
        ).json
        assert (
            result["result"]
            == "0200000001c3f809cfdfc5190e9bde38bab8378a6e191db467645fadd23a3182c8013f52f50000000000ffffffff020000000000000000306a2ec504f53e28185bc36017b0741575d9857548189c38fe67cd64743973fd0eb779b757ca7e8afc1ed91375b47d8e3f0ec89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        )

        result = apiv1_client(
            "create_burn",
            {
                "source": defaults["addresses"][1],
                "quantity": defaults["burn_quantity"],
                "encoding": "multisig",
            },
        ).json
        assert (
            result["result"]
            == "020000000161e381dec789b4c8485a668dbcd5f55ac615e9d23f6cd63ab796a28bb68ac54d0000000000ffffffff02800bb203000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88acbcbce837000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000"
        )

        result = apiv1_client(
            "create_send",
            {
                "source": defaults["addresses"][0],
                "destination": defaults["addresses"][1],
                "asset": "XCP",
                "quantity": defaults["small"],
                "encoding": "multisig",
            },
        ).json
        assert (
            result["result"]
            == "020000000123cf835e30524abad885998c242cc8eeaa449f6b2681b81783a2cb49d10d72910000000000ffffffff02e803000000000000695121024c8d7b21aecdb08550b62294a1b2b6dcdf3bc146323d593ee217ed0ce03f5f782103773c820a7ac8de01ee2b12292c81cf79172e0821becb236c71bd18de09adc02e210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        )

        result = apiv1_client(
            "create_send",
            {
                "source": defaults["p2sh_addresses"][0],
                "destination": defaults["addresses"][1],
                "asset": "XCP",
                "quantity": defaults["small"],
                "encoding": "multisig",
                "dust_return_pubkey": False,
                "regular_dust_size": defaults["regular_dust_size"],
            },
        ).json
        assert (
            result["result"]
            == "020000000153bcb9aa0761fd59990a6b1fffdd9e5b173ca9352266154cd4c215da64ddd3900000000000ffffffff02e80300000000000069512102d4877dc76d1f97ac994b00804b52f97c04c20b9bc755f464b62e4e1b14f4569021025b7712d7097c3f515a317a7798594afcdba4543afcf135a1ac2a5fb60b7c1c69210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aef8c29a3b0000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e8700000000"
        )

        result = apiv1_client(
            "create_issuance",
            {
                "source": defaults["addresses"][0],
                "transfer_destination": None,
                "asset": "BSSET",
                "quantity": 1000,
                "divisible": True,
                "description": "",
                "encoding": "multisig",
            },
        ).json
        assert (
            result["result"]
            == "0200000001aaf710464016ac2ff3e750e04fc56f7380ef9ede9623fd27e0bc2acc703203900000000000ffffffff02e803000000000000695121021f0c056a765f5a7c73a43c71bce264f0b53862a90663e73a0dbf1443a2d001562102dbd33aebc12a1c839bb057b4a2ab87e6aaef7111a8acd844a0bcb9f51187c125210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        )

        result = apiv1_client(
            "create_issuance",
            {
                "source": defaults["addresses"][0],
                "transfer_destination": defaults["addresses"][1],
                "asset": "DIVISIBLE",
                "quantity": 0,
                "divisible": True,
                "description": "",
                "encoding": "multisig",
            },
        ).json
        assert (
            result["result"]
            == "02000000011bf55f4cc6af2be8eda80cff23a8cdf66a6be48e37561345c63a9848b159b8a40000000000ffffffff0322020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ace8030000000000006951210214e937ec9fd8ee9234aec62220f20a3e1588920997aadbba550161b65cdefd70210392f051426d7f59929f6f0257a6d00a1145fa7309d23557736a553cbb8bfc00ed210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae86c09a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        )

        result = apiv1_client(
            "create_order",
            {
                "source": defaults["addresses"][0],
                "give_asset": "BTC",
                "give_quantity": defaults["small"],
                "get_asset": "XCP",
                "get_quantity": defaults["small"] * 2,
                "expiration": defaults["expiration"],
                "fee_required": 0,
                "fee_provided": defaults["fee_provided"],
                "encoding": "multisig",
            },
        ).json
        assert (
            result["result"]
            == "02000000016bdae59894794314088b696b4fc79ddd4961578170c78e672d77d247ccc21dd90000000000ffffffff02e803000000000000695121024b414b8270dc68144804297f7a815df9650a7f414402455b7147fc0a14f2e8a421026efeed7478c2f053bc6d67a9be40a606c1cdd92caf0623f327750fc508dfbf98210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        )

        result = apiv1_client(
            "create_order",
            {
                "source": defaults["addresses"][0],
                "give_asset": "XCP",
                "give_quantity": round(defaults["small"] * 2.1),
                "get_asset": "BTC",
                "get_quantity": defaults["small"],
                "expiration": defaults["expiration"],
                "fee_required": defaults["fee_required"],
                "encoding": "multisig",
            },
        ).json
        assert (
            result["result"]
            == "0200000001966cb7d919e7ef5356bc588155d85ab1cdc9c325b245b9181dfa34db0bc1e0a90000000000ffffffff02e80300000000000069512102d5c7b0d916aaafb7849b50132024ad531b1bc4abcce42e636017ba159df368552103458b06ad8fbe9e10c51225237957edd7a9e4244281916c2dc3a96a8c5b07e068210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        )

        result = apiv1_client(
            "create_burn",
            {
                "source": defaults["p2ms_addresses"][0],
                "quantity": int(defaults["quantity"] / 2),
                "encoding": "multisig",
            },
        ).json
        assert (
            result["result"]
            == "0200000001661611b92bfab7863cc33030c5b5d8e326f26fec2419c2ef2c625dad5a2b9ca50000000000ffffffff0280f0fa02000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac38d69f38000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000"
        )

        with ProtocolChangesDisabled("enhanced_sends"):
            result = apiv1_client(
                "create_send",
                {
                    "source": defaults["addresses"][0],
                    "destination": defaults["p2ms_addresses"][0],
                    "asset": "XCP",
                    "quantity": defaults["quantity"],
                    "encoding": "multisig",
                },
            ).json
            assert (
                result["result"]
                == "02000000019e876739a99203e59524ce12aa739f2e08f0f837804ad3cf3b845d1a7dd126510000000000ffffffff03e8030000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aee803000000000000695121025058f96911e69de34bcb61a4e9b5e3acbe8316b3c41d7ce054fb4919dc3d89162102ae072ffe50fdf2e96421418b8996250f49e84c8865e492fb9b779d9ba645625c210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aec8bb9a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
            )

            result = apiv1_client(
                "create_send",
                {
                    "source": defaults["p2ms_addresses"][0],
                    "destination": defaults["addresses"][0],
                    "asset": "XCP",
                    "quantity": defaults["quantity"],
                    "encoding": "multisig",
                },
            ).json
            assert (
                result["result"]
                == "0200000001fe4db6f8ed8851422f886bac6d7ef817c37ad4b966b5e710cbab590d15d028850000000000ffffffff0322020000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ace80300000000000069512102cabab90aa5973ac3c029441679f77483a7beca9ca6ae665af5e0ba7daaa9d03121021bd558d0361dc0fb539c3eaa6d3b316a5bc9367d35950ab6c11659b699f023d0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae8ebd9a3b000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000"
            )

            result = apiv1_client(
                "create_send",
                {
                    "source": defaults["p2ms_addresses"][0],
                    "destination": defaults["p2ms_addresses"][1],
                    "asset": "XCP",
                    "quantity": defaults["quantity"],
                    "encoding": "multisig",
                },
            ).json
            assert (
                result["result"]
                == "020000000134d845dc7952e0c03d5eab25a3ca40dd55eb222efd106b25345f88f2215935460000000000ffffffff03e8030000000000004751210378ee11c3fb97054877a809ce083db292b16d971bcdc6aa4c8f92087133729d8b210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aee80300000000000069512102e92a55e4899c86958a1c8fc4a31d599c14cfb0e9b89dac9fe4511d933ba8ce15210265f4e59adc5f03d3a90e658d0148ac000850d9c9f82ee3b27f7c5dbc8d3284e0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753aed0b89a3b000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000"
            )

        result = apiv1_client(
            "create_issuance",
            {
                "source": defaults["p2ms_addresses"][0],
                "transfer_destination": None,
                "asset": "BSSET",
                "quantity": 1000,
                "divisible": True,
                "description": "",
                "encoding": "multisig",
            },
        ).json
        assert (
            result["result"]
            == "0200000001ad4864027a4ec2549a0843c37f9ee8da8657fdce3c6eb317aaf581b0c9766ed60000000000ffffffff02e8030000000000006951210378e1df6921818ba2afaee42aa94cc1fcf76161f0cd9aab715982263c0d17b5a22102f70391102e7fd495f5daac0c2692e43fce433616471a97725d2d0f171f28e125210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753aed8bf9a3b000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000"
        )

        result = apiv1_client(
            "create_issuance",
            {
                "source": defaults["addresses"][0],
                "transfer_destination": defaults["p2ms_addresses"][0],
                "asset": "DIVISIBLE",
                "quantity": 0,
                "divisible": True,
                "description": "",
                "encoding": "multisig",
            },
        ).json
        assert (
            result["result"]
            == "0200000001070ad198b63d3b85ed274e1293f056bf53b9a9b749358ab629be90731ae6ae050000000000ffffffff03e8030000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aee80300000000000069512103a8096416dd255eb5aca8be7f67519a8b0ec517b6d75fc1a540f46470dbc18d7021033154e78348448a74e59bf0fdb172543f9668c3d40dc783ead4cd73b01daa2e6e210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aec8bb9a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        )

        result = apiv1_client(
            "create_issuance",
            {
                "source": defaults["addresses"][0],
                "asset": f"A{2**64 - 1}",
                "quantity": 1000,
                "encoding": "multisig",
            },
        ).json
        assert (
            result["result"]
            == "0200000001c8b0941d5a9367f13ca7a7b7f558d9c7fcda5a189cb62b78976b844fd52cde9b0000000000ffffffff02e80300000000000069512102b3a9c36c150aafc3b2ef01db8dd3df08fbbf187650f0636a7fac08e693f641432102768bb76d8382d0fea56a0802a0dc61927810e6244587b20180a79d2366d7aef9210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        )

        result = apiv1_client(
            "create_order",
            {
                "source": defaults["p2ms_addresses"][0],
                "give_asset": "BTC",
                "give_quantity": defaults["small"],
                "get_asset": "XCP",
                "get_quantity": defaults["small"] * 2,
                "expiration": defaults["expiration"],
                "fee_required": 0,
                "fee_provided": defaults["fee_provided"],
                "encoding": "multisig",
            },
        ).json
        assert (
            result["result"]
            == "02000000016c743cdf79dea272b6dbf0871d54be044a50958523180f55e3ad2a07bbdc918b0000000000ffffffff02e80300000000000069512103de20cae106260b0cbf26abf99f8417500aa67fee55cb38433c7dde183af2b3f22103db2439460eec5f804f5097df86c5b3e1ffa079001516b984adcf329360c75885210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753aed8bf9a3b000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000"
        )

        result = apiv1_client(
            "create_order",
            {
                "source": defaults["p2ms_addresses"][0],
                "give_asset": "XCP",
                "give_quantity": round(defaults["small"] * 2.1),
                "get_asset": "BTC",
                "get_quantity": defaults["small"],
                "expiration": defaults["expiration"],
                "fee_required": defaults["fee_required"],
                "encoding": "multisig",
            },
        ).json
        assert (
            result["result"]
            == "02000000016fcb84f5caf2956c3f25999b27f31b33ddca1d74e2302b317b6f75fa8ad41bc40000000000ffffffff02e80300000000000069512103ada7296a4965461312718706c4394723c3216c3afa5a06f919710e5acff7b3332102dd6c8cdb1f2c875fbf61c2b036eda457d14ff47392793c43dae35f5c81ec486b210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753aed8bf9a3b000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000"
        )

        result = apiv1_client(
            "create_dividend",
            {
                "source": defaults["addresses"][0],
                "quantity_per_unit": defaults["quantity"],
                "asset": "DIVISIBLE",
                "dividend_asset": "XCP",
                "encoding": "multisig",
            },
        ).json
        assert (
            result["result"]
            == "02000000017735df3ee6bf0b86a8ab5c78bb1a4a32a35418641e844b9962608f2c86f3b53d0000000000ffffffff02e80300000000000069512103aa8c7ac1116c7ffc5e269fc184b9061a5d60869f98a1e31cf028550b808d893121037983463767e7cacb86972712f3a86edc146ee68b73f500655b29fd949189053a210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        )

        result = apiv1_client(
            "create_dividend",
            {
                "source": defaults["addresses"][0],
                "quantity_per_unit": 1,
                "asset": "NODIVISIBLE",
                "dividend_asset": "XCP",
                "encoding": "multisig",
            },
        ).json
        assert (
            result["result"]
            == "02000000010ad301060bba3f554cd12b5adfa13f59aba221791b8127d352259cff096074b90000000000ffffffff02e80300000000000069512103d4c756e0164648b30d87710c55ba7a167dfce252f9ac445b589f73e2bb8ca63d21033be1211a0958f06a8cb77d1c421108b0b66ad71d066e59c32bb2e58db3945f87210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        )

        result = apiv1_client(
            "create_send",
            {
                "use_enhanced_send": False,
                "source": defaults["addresses"][0],
                "destination": defaults["addresses"][1],
                "asset": "XCP",
                "quantity": defaults["small"],
            },
        ).json
        assert (
            result["result"]
            == "0200000001a244988f26213be481338aaca68f62408aaf10665db161a7044d798f6a9aa94b0000000000ffffffff0322020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000000000001e6a1c8917709fdfa4878739bf9e4bffac6c6dadff019e55d2162d70bd24cdccc59a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        )

        result = apiv1_client(
            "create_send",
            {
                "source": defaults["addresses"][0],
                "destination": defaults["addresses"][1],
                "asset": "XCP",
                "quantity": defaults["small"],
            },
        ).json
        assert (
            result["result"]
            == "0200000001becef02909ba0cde75d5ccc95be981d076200f73bc5da2dbc5e8ecd70e0f1a720000000000ffffffff020000000000000000306a2efcdd139c50bdfee69f6e167cfc1d4b1ef648a704bd4b62905508d2760ec135a90d5cd62ee20779fbcb49333da7850ec89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        )

        result = apiv1_client(
            "create_send",
            {
                "memo": "hello",
                "source": defaults["addresses"][0],
                "destination": defaults["addresses"][1],
                "asset": "XCP",
                "quantity": defaults["small"],
            },
        ).json
        assert (
            result["result"]
            == "02000000019f1bfbda70c3fad5e1e8d50ac95ec917bd5d41e3ee09a0990a63d5e55e522b090000000000ffffffff020000000000000000356a33d98f50aa2a792c8791db6955e87bd4445116e2e82e8764c90cd376d944902e3eaeeeb3d13470418a312d8d819c727440b4c3cb04c89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        )

        result = apiv1_client(
            "create_send",
            {
                "memo": "0102030405",
                "memo_is_hex": True,
                "source": defaults["addresses"][0],
                "destination": defaults["addresses"][1],
                "asset": "XCP",
                "quantity": defaults["small"],
            },
        ).json
        assert (
            result["result"]
            == "0200000001f2fadee21459be8bf78023123b6b57a3a10cbf53d847323028f2483ebc93094d0000000000ffffffff020000000000000000356a33207e03880c6473427236baea2734240b4faf4aa3ab0d55dae7d033494cb046139c5c131cdc8183fe06f49e3fb5fd1fd37c90f204c89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        )

        result = apiv1_client(
            "create_send",
            {
                "memo": "0102030405",
                "memo_is_hex": True,
                "source": defaults["addresses"][0],
                "destination": defaults["addresses"][6],
                "asset": "XCP",
                "quantity": defaults["small"],
            },
        ).json
        assert (
            result["result"]
            == "0200000001f720b4622d56c2d98b2a6046c364487233ce53cce7ea2ff1c4d51dafd91659340000000000ffffffff020000000000000000356a33f352716d54f862ded468e8746af3773155baf9d2df412d1489aeedfcdc690c460a5bfcebdfe148bc77ac23345a18bf6590016004c89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        )

        with ProtocolChangesDisabled(["enhanced_sends"]):
            result = apiv1_client(
                "create_send",
                {
                    "memo": "0102030405",
                    "memo_is_hex": True,
                    "source": defaults["addresses"][0],
                    "destination": defaults["addresses"][1],
                    "asset": "XCP",
                    "quantity": defaults["small"],
                },
            )
            assert (
                "Error composing send transaction via API: enhanced sends are not enabled"
                in result.json["error"]["message"]
            )

        result = apiv1_client(
            "create_send",
            {
                "source": defaults["addresses"][0],
                "destination": defaults["addresses"][6],
                "asset": "XCP",
                "quantity": defaults["small"],
            },
        ).json
        assert (
            result["result"]
            == "0200000001010349e422e4bdd73ad321017ebd25856d72bb0eaf9d559d0c16e06c191b21220000000000ffffffff020000000000000000306a2ea09e65ce18ec77c76f82e6b3977adffa1b386bddf87567e68892a0ca15715e5a9ce655ce65a2654b2f8cbe2b50570ec89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        )


def test_get_tx_infos(apiv1_client, current_block_index, defaults):
    with ProtocolChangesDisabled("taproot_support"):
        tx_hex = "0200000001010349e422e4bdd73ad321017ebd25856d72bb0eaf9d559d0c16e06c191b21220000000000ffffffff020000000000000000306a2ea09e65ce18ec77c76f82e6b3977adffa1b386bddf87567e68892a0ca15715e5a9ce655ce65a2654b2f8cbe2b50570ec89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        result = apiv1_client(
            "get_tx_info", {"tx_hex": tx_hex, "block_index": current_block_index}
        ).json
        assert result["result"] == [
            defaults["addresses"][0],
            "",
            0,
            498,
            "0200000000000000010000000002faf0806fb390187ef2854422ac5e4a2eb6ffe92496bef523",
        ]

        tx_hex = "0200000001f720b4622d56c2d98b2a6046c364487233ce53cce7ea2ff1c4d51dafd91659340000000000ffffffff020000000000000000356a33f352716d54f862ded468e8746af3773155baf9d2df412d1489aeedfcdc690c460a5bfcebdfe148bc77ac23345a18bf6590016004c89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
        result = apiv1_client(
            "get_tx_info", {"tx_hex": tx_hex, "block_index": current_block_index}
        ).json
        assert result["result"] == [
            defaults["addresses"][0],
            "",
            0,
            508,
            "0200000000000000010000000002faf0806fb390187ef2854422ac5e4a2eb6ffe92496bef5230102030405",
        ]


def test_unpack(apiv1_client):
    with ProtocolChangesDisabled("taproot_support"):
        result = apiv1_client(
            "unpack", {"data_hex": "0000000000000000000000010000000002faf080"}
        ).json
        assert result["result"] == [0, {"asset": "XCP", "quantity": 50000000}]

        result = apiv1_client(
            "unpack",
            {
                "data_hex": "0000000200000000000000010000000002faf0806f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec"
            },
        ).json
        assert result["result"] == [
            2,
            {
                "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                "asset": "XCP",
                "memo": None,
                "quantity": 50000000,
            },
        ]


def test_get_rows(ledger_db, state_db):
    assert apiv1.get_rows("balances", None, "AND", None, None, None, None, None, 1, 0, True) == [
        {
            "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
            "asset": "CALLABLE",
            "quantity": 1000,
            "block_index": 105,
            "tx_index": 3,
            "utxo": None,
            "utxo_address": None,
            "asset_longname": None,
            "divisible": True,
        }
    ]

    with pytest.raises(exceptions.APIError, match=re.escape("Invalid filter operator (OR, AND)")):
        apiv1.get_rows("balances", None, "barfoo", None, None, None, None, None, 1000, 0, True)

    with pytest.raises(exceptions.APIError, match="Unknown table"):
        apiv1.get_rows(None, None, "AND", None, None, None, None, None, 1000, 0, True)

    with pytest.raises(exceptions.APIError, match=re.escape("Invalid order direction (ASC, DESC)")):
        apiv1.get_rows("balances", None, "AND", None, "barfoo", None, None, None, 1000, 0, True)

    with pytest.raises(exceptions.APIError, match="Invalid limit"):
        apiv1.get_rows("balances", None, "AND", None, None, None, None, None, 1000.0, 0, True)

    with pytest.raises(exceptions.APIError, match="Limit should be lower or equal to 1000"):
        apiv1.get_rows("balances", None, "AND", None, None, None, None, None, 1001, 0, True)

    with pytest.raises(exceptions.APIError, match="Invalid offset"):
        apiv1.get_rows("balances", None, "AND", None, None, None, None, None, 1000, 0.0, True)

    with pytest.raises(exceptions.APIError, match="Invalid order_by, must be a field name"):
        apiv1.get_rows("balances", None, "AND", "*", None, None, None, None, 1000, 0, True)

    with pytest.raises(exceptions.APIError, match="Unknown filter type"):
        apiv1.get_rows("balances", [0], "AND", None, None, None, None, None, 1000, 0, True)

    with pytest.raises(
        exceptions.APIError, match="A specified filter is missing the 'value' field"
    ):
        apiv1.get_rows(
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
        )

    with pytest.raises(exceptions.APIError, match="Invalid value for the field 'bar'"):
        apiv1.get_rows(
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
        )

    with pytest.raises(exceptions.APIError, match="Invalid value for the field 'bar'"):
        apiv1.get_rows(
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
        )

    with pytest.raises(exceptions.APIError, match="Invalid operator for the field 'bar'"):
        apiv1.get_rows(
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
        )

    with pytest.raises(exceptions.APIError, match="case_sensitive must be a boolean"):
        apiv1.get_rows(
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
        )

    with pytest.raises(exceptions.APIError, match="Invalid memo_hex value"):
        apiv1.get_rows(
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
        )

    assert apiv1.get_rows(
        "sends",
        [{"field": "block_index", "op": "=", "value": "717"}],
        "AND",
        None,
        None,
        None,
        None,
        None,
        1000,
        0,
        True,
    ) == [
        {
            "tx_index": 37,
            "tx_hash": "5bcf220d3aa8fc498870ca1fdf6c8b32c17f2005877d04bb8f4392cf5ef03b1b",
            "block_index": 717,
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
    ]

    assert apiv1.get_rows(
        "sends",
        [{"field": "block_index", "op": "=", "value": "718"}],
        "AND",
        None,
        None,
        None,
        None,
        None,
        1000,
        0,
        True,
    ) == [
        {
            "tx_index": 38,
            "tx_hash": "d655fa7bcbdf73aa7c3c453807fca974459551feec77d8947f16d7493025cca7",
            "block_index": 718,
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
    ]

    assert apiv1.get_rows(
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
    ) == [
        {
            "tx_index": 37,
            "tx_hash": "5bcf220d3aa8fc498870ca1fdf6c8b32c17f2005877d04bb8f4392cf5ef03b1b",
            "block_index": 717,
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
    ]

    assert apiv1.get_rows(
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
    ) == [
        {
            "tx_index": 37,
            "tx_hash": "5bcf220d3aa8fc498870ca1fdf6c8b32c17f2005877d04bb8f4392cf5ef03b1b",
            "block_index": 717,
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
    ]

    assert apiv1.get_rows(
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
    ) == [
        {
            "tx_index": 37,
            "tx_hash": "5bcf220d3aa8fc498870ca1fdf6c8b32c17f2005877d04bb8f4392cf5ef03b1b",
            "block_index": 717,
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
    ]

    assert apiv1.get_rows(
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
    ) == [
        {
            "tx_index": 37,
            "tx_hash": "5bcf220d3aa8fc498870ca1fdf6c8b32c17f2005877d04bb8f4392cf5ef03b1b",
            "block_index": 717,
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
    ]

    assert apiv1.get_rows(
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
    ) == [
        {
            "tx_index": 38,
            "tx_hash": "d655fa7bcbdf73aa7c3c453807fca974459551feec77d8947f16d7493025cca7",
            "block_index": 718,
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
    ]


def test_extended_info(apiv1_client, defaults):
    with ProtocolChangesDisabled("taproot_support"):
        result = apiv1_client(
            "create_issuance",
            {
                "source": defaults["addresses"][0],
                "transfer_destination": defaults["addresses"][1],
                "asset": "DIVISIBLE",
                "quantity": 0,
                "divisible": True,
                "description": "",
                "encoding": "multisig",
                "extended_tx_info": True,
            },
        ).json

        assert result["result"] == {
            "btc_in": 1000000000,
            "btc_out": 1546,
            "btc_change": 999997574,
            "btc_fee": 880,
            "data": "434e54525052545916000000a25be34b660000000000000000010000",
            "lock_scripts": ["76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"],
            "inputs_values": [1000000000],
            "signed_tx_estimated_size": {"vsize": 340, "adjusted_vsize": 440, "sigops_count": 88},
            "psbt": "0200000001f45bd80918ce634fe0d6e3ac328fa229c8aeff3e63316bb33e9db43dd07b75c30000000000ffffffff0322020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ace80300000000000069512103ea49bccb9828a4b03ae59a92115ace194fb7b43de0f8830b2f6de1ee3b2c6dcb2102bddf4de9fc412c28787ed4a5d64a6080c8264a956a78010aa5b44b5e553bc2ce210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae86c09a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
            "params": {
                "source": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                "transfer_destination": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                "asset": "DIVISIBLE",
                "quantity": 0,
                "divisible": True,
                "description": "",
                "lock": None,
                "reset": None,
                "skip_validation": False,
            },
            "name": "issuance",
            "tx_hex": "0200000001f45bd80918ce634fe0d6e3ac328fa229c8aeff3e63316bb33e9db43dd07b75c30000000000ffffffff0322020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ace80300000000000069512103ea49bccb9828a4b03ae59a92115ace194fb7b43de0f8830b2f6de1ee3b2c6dcb2102bddf4de9fc412c28787ed4a5d64a6080c8264a956a78010aa5b44b5e553bc2ce210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae86c09a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000",
        }
