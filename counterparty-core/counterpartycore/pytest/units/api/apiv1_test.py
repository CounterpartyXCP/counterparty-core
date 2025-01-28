import re

import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.api import apiv1
from counterpartycore.pytest.mocks.counterpartydbs import ProtocolChangesDisabled


def test_create_burn(apiv1_client, defaults, ledger_db, current_block_index):
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
        == "0200000001c5c9b5c88b6c5e28fe4a4fd8b6792f2980c5cacc0cca959eff213818be01e0a80000000000ffffffff02800bb203000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88acbcbce837000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000"
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
        == "020000000161b1991a843a4636a9da4e90faef91e98e034d587069a114d70b1bb1a19d1e0d0000000000ffffffff02e803000000000000695121022fa6ef625aefff69ea246e0642a53de00b4492db194f2b3a3ddd03e3d3bfcf3021025f7787002dd99ff7f80ee07aac56fb234c35b4689d78a098bb08ce8b9b730a43210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "0200000001b74af7ca82c6bab4143807d0b085d2bb51729211a669f6ac8c47c6a3d03e692b0000000000ffffffff02e8030000000000006951210207906556a0519687736ed7f5fc54e9a139f77dd7a44b5dbc36eb19339aebddcd2103b45732a4ad958529f4c5d638a725af69a27546ed9de0e8c800c07012c0876223210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aef8c29a3b0000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e8700000000"
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
        == "020000000159d00fdf7f81e89f1fa42dd712838269c9cd546ee0da61a05a105cda8d85235f0000000000ffffffff02e80300000000000069512102dae846ac18ff42da809de64a9b89c48d1be35ba96ce761af04780bcff6ef50252102f9c2bbb7baeea11fe3082fe349b3669154aab00cdfd433d1e30c1fcfbcc79dcb210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "02000000015ec9d673917308ac291e1e3e6da85b4bd7ba7e12eb96ce34f8c1122ad93beb810000000000ffffffff0322020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ace803000000000000695121023b541408fede6aa02f39520c946bc8b4a5899f90a79986aed639aed9bc6389862103fec5dd9a96b3c919111e95bfbaa8d27a29a56fb00e0f2bb83e24deb41289001c210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae86c09a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "0200000001d63bb152ead2d1780d53ab03d1607dd1c77791a8b0434c44ffac83742ec8de610000000000ffffffff02e803000000000000695121028e2f4f7612af1e7d5c5f66bde98762f6378d80d1a44ec2193f09afbfb619b65421038d8c499834794ba038533d3eee8ef83b7522fa5c83f99251beec749d655b9b6b210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "020000000162cfa1417799553e305c053c5c92a8bdcccfcf5ee01d2aeabf0450e06fcabd070000000000ffffffff02e80300000000000069512102a596a8353be50c3a18ae26e1da82b970a4622cd3ae42dc424e97d5245e5feaab210388cdf2b043f8d43946959bd17392cc0b1e385985bd0d151c4b9c36f47301bfd1210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "0200000001bba22df40d7fe47670dfcd6b2303d66bd3d5aebc11cdaa051a8027ff6fdc872b0000000000ffffffff0280f0fa02000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac38d69f38000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000"
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
            == "0200000001c3e7ef7585bb91afe9965c2e596018f38a41d813b72fb5c0a935c61cbf645be30000000000ffffffff03e8030000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aee8030000000000006951210240229995e23fd25c3ad89816477a3fcefc8b7018f5c18509630938bd78b429842102f4285afc86923d6303c416daac4ceda156ca8438d68905df37c62ebc9f9afbd9210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aec8bb9a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
            == "020000000142144289055a67e33b5fa242ff3c4a01583c4f4f7c20bc445aeb770af44bc5350000000000ffffffff0322020000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ace803000000000000695121021c050d14672a5b7406ba39a5cce9d994b1e21697bb50725706877260acc6c2c22102a05dc43fad2eef4a6fbf5a3619c94ecf6447a0df381364bbddfd6bac3f5d7538210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae8ebd9a3b000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000"
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
            == "02000000010430edd43deeb1a6d4e7373f0221c1af014789dc021576768b9277a45186c5ef0000000000ffffffff03e8030000000000004751210378ee11c3fb97054877a809ce083db292b16d971bcdc6aa4c8f92087133729d8b210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aee80300000000000069512103136cb698fa765409b9ab0c0267acf2f75e9ec42ebce177123d7fcf13dc1fe2f821027a0caffbd988e3928e18b5083f1c31a03b9078b72882054370678fc4ad5d7cf4210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753aed0b89a3b000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000"
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
        == "0200000001780a8499791de93743badb6481857ecd24b2a878f724d6a6c8c0894a1cfe77e60000000000ffffffff02e803000000000000695121032cebc4c23b77465d16fd809a3b58b05d64f1405f768ce54a1864d186cd1b68cf2102b45dc839f410395ba0eaafae08df3546c0284f0b986c185a1b6bb979b9664a2d210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753aed8bf9a3b000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000"
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
        == "02000000019fdfff35e2ef617c9dbc21b5c319898ff8625c3f4d495edb340928000dde1c0f0000000000ffffffff03e8030000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aee80300000000000069512103c7b82943380b026eff7de778801bc7e99298b6ee4fb97f2fc6915a8ceee97e6b2102d080763cd427cf90befb8362789a919a9c5ac3cfb095eed5984634afe42964f9210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aec8bb9a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "020000000115232a7f532c7f012d81047c4f92953a6f4fd9e5c198610c3cf58695add6b13e0000000000ffffffff02e8030000000000006951210260966dd5bb771a8c6b906eb91c193f3ac68294a7f24d728fd57606242f323b37210299fe400d84f128986568d675573fa1577cc8ebdcbd37e09b93fb3ff5ae7175de210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "0200000001248362e90bb86bd0bca37f96a29452ccb75a52acd9941ca2497d64a8903e86050000000000ffffffff02e80300000000000069512102755bb32eca13fee37c2f6a405ae806e38bc8353218ee92f48933920e4513d8b021025a89c54bf9ee7221a2398a95cf0d423469014595c3ed8330a50369b5bdaa3f62210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753aed8bf9a3b000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000"
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
        == "0200000001f0cf9a300cffeeae60565bcd00d80b959a484a62bb849d681986817c9d6dc4490000000000ffffffff02e80300000000000069512103ea34666dcf9218cc3e7f4c6fd9e7485d652632b5c70109fbe0e7d7fb5cea386521028565d20d844f17d0a81668397f708a674937da14d273f92d096d701ab4382fa7210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753aed8bf9a3b000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000"
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
        == "0200000001669f368695a7c1a5fa4e45d411d98eab7f8c6423b4b69f5f5afe5c7b33b60e600000000000ffffffff02e8030000000000006951210330d66540a0bcfe3e087cb17c9aaca36a8b35da7d64a60ab5694dfe9c9ef736a421035fc3e54893fd26371c684fd75006b888736d930454869c706491c9d5abbf70d6210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "020000000197d6b198a26c39e91f5fda7479df23cbef05f87588a7a9b5b5965f295cd5ec1b0000000000ffffffff02e803000000000000695121023fdabd3fed7292bba4849b5cc7cf36ab76970c3110e34f7c881f34e00618d5bb2102db6b944f4fa34d38931cbc85f6f84d2d6378b67e52f854c8c1b84b34da64570b210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "0200000001148a8964b7bdbc985390692bbd969d06112f7a9d8e31d71b0b2784f950550f560000000000ffffffff020000000000000000306a2edfd6b3d5c471afb427d75f1e5366fdeffc888fc9c8dfeda1c66092f89816dc772f3024e15778dc177c070d61acaf0ec89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "02000000015c570a621c5bfc354fa0197aaa90deac9e15ae9da5e870fd9d17ec86b54bec240000000000ffffffff0322020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000000000001e6a1c7ef0688d320b026a2dd2167894edc015ffeb81c8ab14b552d374cf64ccc59a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "02000000010e3ea48a07b3615cb223be93fdd33e660b87ef3fa23fea961916ac591082c1640000000000ffffffff020000000000000000306a2ec55b5acbb0a099a5313ced07fea6f3611a7ce1c017ada861f5d2d888557cd9bca5c4b5b85f01732e4c43620ff81f0ec89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "02000000012b0f073e6577538bc235e80920e2746957078671b71394f218a5516a56e169570000000000ffffffff020000000000000000356a33f8464e27b39c08704c7b65b593c8a006ea37a0995bd4eb4af581acc602b9e45d48ec4f3bf74d15c22cab64a35e08aeb9168c3504c89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "020000000140af4a0f6c5385c6eeb99af522bf163ce20abaf0bef45f172202e66d30f2015f0000000000ffffffff020000000000000000356a3369e26208a81fdb115a53788a86b22a97dceb803f151cd19a44e0dc7efa32cdcdb2932c206374504ef69679f6e93153019f1dc604c89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "0200000001f00b86d0d767076c06fe754c5f2a5ed35933ef762dc7f98a315ecff52fa480e30000000000ffffffff020000000000000000356a33c6ae6dda8979d3b319151421e365810aa290b442774d7fd855d8ae76d5130c41c8d6e453860a25e52379e8b1b65efb972b0f5504c89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "02000000018dcc2650d8e5918fef783df082904e4982760692d914a96ee70293e22604f9e90000000000ffffffff020000000000000000306a2e03f363c8ebe92b9a79ef41637ebc0e4354622bf5d159feabc5e9375c14480424883b0c4237c9f755184399fee2260ec89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
    )


def test_get_tx_infos(apiv1_client, current_block_index, defaults):
    tx_hex = "02000000018dcc2650d8e5918fef783df082904e4982760692d914a96ee70293e22604f9e90000000000ffffffff020000000000000000306a2e03f363c8ebe92b9a79ef41637ebc0e4354622bf5d159feabc5e9375c14480424883b0c4237c9f755184399fee2260ec89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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

    tx_hex = "020000000197d6b198a26c39e91f5fda7479df23cbef05f87588a7a9b5b5965f295cd5ec1b0000000000ffffffff02e803000000000000695121023fdabd3fed7292bba4849b5cc7cf36ab76970c3110e34f7c881f34e00618d5bb2102db6b944f4fa34d38931cbc85f6f84d2d6378b67e52f854c8c1b84b34da64570b210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
    result = apiv1_client(
        "get_tx_info", {"tx_hex": tx_hex, "block_index": current_block_index}
    ).json
    assert result["result"] == [
        "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        "",
        0,
        840,
        "3200000000000000010006cad8dc7f0b660000000000000001",
    ]


def test_unpack(apiv1_client):
    result = apiv1_client("unpack", {"data_hex": "0000000000000000000000010000000002faf080"}).json
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
            "tx_hash": "b238c76bb1506b5db10c50e7e5ce5c7740fd1cc6d43cc687c8f267a1c1bd9e91",
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
            "tx_hash": "424b437fa86c35d47c0b7a07a594d32fb866cf91a330f0022e5a0d0fdba5e06c",
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
            "tx_hash": "b238c76bb1506b5db10c50e7e5ce5c7740fd1cc6d43cc687c8f267a1c1bd9e91",
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
            "tx_hash": "b238c76bb1506b5db10c50e7e5ce5c7740fd1cc6d43cc687c8f267a1c1bd9e91",
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
            "tx_hash": "b238c76bb1506b5db10c50e7e5ce5c7740fd1cc6d43cc687c8f267a1c1bd9e91",
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
            "tx_hash": "b238c76bb1506b5db10c50e7e5ce5c7740fd1cc6d43cc687c8f267a1c1bd9e91",
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
            "tx_hash": "424b437fa86c35d47c0b7a07a594d32fb866cf91a330f0022e5a0d0fdba5e06c",
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
