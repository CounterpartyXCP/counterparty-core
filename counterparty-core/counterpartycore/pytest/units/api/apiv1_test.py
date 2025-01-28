import re

import pytest
from counterpartycore.lib import exceptions
from counterpartycore.lib.api import apiv1
from counterpartycore.pytest.mocks.counterpartydbs import ProtocolChangesDisabled


def test_create_burn(apiv1_client, defaults):
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
        == "02000000015ab8f831c25100f7f8d52ba9dedd737ab460fe2654fbbb5ad0b93dcbe582e29a0000000000ffffffff02800bb203000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88acbcbce837000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000"
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
        == "02000000010ef8e01ba415c1690850230de7904c2fd56d24ccd9af3f7bd1c473187fe65faa0000000000ffffffff02e8030000000000006951210276bb9e135c6eca54e9d024ff366f630f9e71c05bad6a8ab1aa380f79dbf39b78210399530d48ca1839962255f585369240e4f14d8306308b3345269135c522152bb6210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "0200000001e8333a7bb1eddfe9d3151a19883e8a6b838dd28acdfdd7b76d43786a777c4be60000000000ffffffff02e8030000000000006951210244f90901d99fa5aebb47179e5ceaa2dad8e74fee6411ef23bedeb1b944f5ccda210348f71507aeff1c77306c5b20a36364a6009570fae07bd1479afdbf16d17fd664210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aef8c29a3b0000000017a9144264cfd7eb65f8cbbdba98bd9815d5461fad8d7e8700000000"
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
        == "020000000181ed37d96250670180be1138fe206b55ce6acb6b776a93e7803583650e73aa9b0000000000ffffffff02e8030000000000006951210384f8ca4d27dd214b16ccdf8c0b1e07a03504afc8f9bd4963051f77a83c3ff2cf210325c47f728d6295f81f869debc34f44e50135a78b017c13adffe4dc57d3d851e6210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "02000000011883518b96921c4a8b41175e8cac47d1d540e31a68a6d02c71acadfb3388ac730000000000ffffffff0322020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ace8030000000000006951210385a20ed5b58e793e839897580f341ff1e666abdbd9acd9bd16287d65cdcdfa392103391ab5a839825bf19a44cfb19b53b45d4090430e262804989196c420c92c6256210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053ae86c09a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "020000000192d747d2b431fa85342b741c830d43aea1ab449bcb605fbb177501f62a5688f60000000000ffffffff02e803000000000000695121024e682700f8581ae39cd0ed0dc06e8d55e030ecc2fe9ae5543806b5dbb6d72d252102d5f183f583e3db0ede2fdbd1af62b2c7770a42d6728424e950e7404eeb2d1b0c210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "0200000001c98210b037aa9cf72512c6e05d5264cc8ac89792cabd49d60643cf8c1889b7480000000000ffffffff02e803000000000000695121029d1193ba12937736a13d3463eaf675b1183b8bab72d834570cdfcd11ccfda37221033bcbe146080f8f31caf748c62b2f7d266f1f7a2b4387af9e55836249199d5156210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "02000000015464918df64e0a30bb5dfc4fb777093756d3f3b7d5f57703f4c8ea937d45a7620000000000ffffffff0280f0fa02000000001976a914a11b66a67b3ff69671c8f82254099faf374b800e88ac38d69f38000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000"
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
            == "02000000012674d711cfff525511eb37e6f988fe6aff78d8b089f02d414d60c9a380d09cf50000000000ffffffff03e8030000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aee80300000000000069512103d007432e178722e444409e52f58a1ced981d3e0ae1cfce3317779a1b879fa5dd21030b5a19597fad30565dc359e96b392e4b45027dbc4c36ac68322ea40fec15c2d9210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aec8bb9a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
            == "020000000138108ba9603f597eef49375904b6f32e4cc3e3f0224f3ce5621ca16da304d4850000000000ffffffff0322020000000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ace803000000000000695121027f59e504936d42374dd950d2c319987fa85d5d1a8035fb02fff7b641e7bbc3ac210227bdd5298c3d3337db4f08fdbf0c15f037c67c2a1c21fa1fbeb9983113b36d0b210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753ae8ebd9a3b000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000"
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
            == "02000000013e6b8be4216497659fdb6ed720c18db988814984f9c51ba71b75f12880495b650000000000ffffffff03e8030000000000004751210378ee11c3fb97054877a809ce083db292b16d971bcdc6aa4c8f92087133729d8b210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aee803000000000000695121039fef53cb0c0f562402858039cf71d746b03c5c0a013473d33310756744c504d92102cb78326e8250d67587fdb3f9a0386be3557eb8b273bdcf3c1bfcca8e1969e20a210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753aed0b89a3b000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000"
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
        == "0200000001164a7e26f1fb9a6a49d5961860c475f2d2927fb0414117c982e01778d989ac6d0000000000ffffffff02e803000000000000695121034b6a0a941e2927362f489dde77a0937f54b15ce8bdd6b8cec99556c63e3b0a222102bbd56c7a70293f11b12ae92e2b5373485930672072bc410ba221cbd0370c231f210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753aed8bf9a3b000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000"
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
        == "020000000106c6035e7f9ca42a0a44d1fef2c226fb3d2ca10ae93432179e8202a927bd58cb0000000000ffffffff03e8030000000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752aee803000000000000695121038fb040978012ad6e8c46762fc383f1c9c06061a1dcc75c8e4e3ce46ca7b98bf92102f8e999b628d6cfdea8b87ed9778de7d435663255df5dc19424e3b3433cd3071a210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aec8bb9a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "02000000016df21a19472971804e8b1bad97872c816fd901d425ac944a963908b158fdd55d0000000000ffffffff02e80300000000000069512103a2922fd698c27e58eef0539377076685a8d2a81eea07e04d8f845abaf7c2db53210373557315335d0812b5bcc4d230940e90944388d9bbc1f2f50e6788f76e7a8f16210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "0200000001015b7bcf582be7f7ca7e8d037fdd70a093f89b0c59a9ca419c52d7a1020e611e0000000000ffffffff02e80300000000000069512103a502120570804018e71270bde30b7cf4e24da4922bdc34848539fae8bc912b112103a8068f6daeb53e926c0a58518e60d0b85330eb18713843c57d4af9b002de2dfc210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753aed8bf9a3b000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000"
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
        == "02000000017cff1e413351744920cff69edcb88f7bd6f2a555d4ef1a9243551c1880a4dc6c0000000000ffffffff02e80300000000000069512103aeb2fccd2e88df03e8cde54aeaee64e48fbd5f58c11ac7883b5ffe96dcaa07c821034950ab5cf70df46ae1d4e5de24adaa1b529e345b9a75e6b8c7826121916f73a0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97753aed8bf9a3b000000004751210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b0210319f6e07b0b8d756156394b9dcf3b011fe9ac19f2700bd6b69a6a1783dbb8b97752ae00000000"
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
        == "0200000001bbdf2d15ded9fcbb55504be48a70168f4774eb637e6bffae656d2bc7256aff6e0000000000ffffffff02e80300000000000069512102c74ae719fb8db099ff8a417df320c22519e7ef80330efc601d21d8ea4171deb82102b34345ccc166875f8182cd0b3f95988e5076ac37d50c36d74dc06fd5b5f0b86d210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "02000000016365886455cedc88649454250736f411ae2b3e229a752da34787e39c171df8e30000000000ffffffff02e8030000000000006951210365ed47a9f91ad12a886de581924a329f7e927a177c10eaa6d7ef383d1afab04f210328a312f14b7c37300dd189f4f3f4a7a4142787ec87f19a77d10366ee957be84c210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "0200000001afddbaa1eb9e846371c45e9411c8722459dae4df1aa2dbfaa1b7b352fc2cc2b40000000000ffffffff020000000000000000306a2e1b27053ff2854bee414ce553501b16863df7b79567e34c7a7e00a886ca30abe21a8ed59936cf22766634356fc7e40ec89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "02000000013250915db54c86aa53bb9b6554bdd9478127ae0b080c1dccd07578ebe63243f40000000000ffffffff0322020000000000001976a9148d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec88ac00000000000000001e6a1c611b6fe690ca4d068ed7d23c12f37af052600cbfd5a3be54e94eeb76ccc59a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "02000000010e6a8bcfbd4893faa61cf2216222014150420c07180e2200cb1fa4166cb3307d0000000000ffffffff020000000000000000306a2e37c6ef26fb4ab78fa007b3fe8a6332c396ba3d19595a566617a915c320ba724e9f40fefcaa550ad2313c2ed454180ec89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "0200000001d8749ec99e113b69377e980907fb0fbfa281e7ef59ca314ba097e5809d0c2f570000000000ffffffff020000000000000000356a334e587ab2d722e110802ffca2fc2661c693c8fea25b659b8d44dd54296a0b9c57bad50c0d281d2a5d7eced485d72fae0706ca4804c89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "020000000129b19f899ed64b64e4f8a574f353856310acd689b6ddfe2d39c7ae2019eabbc50000000000ffffffff020000000000000000356a33efc2f12b4aecdc67fbacdc4b24d66e516960b98dc46a4d4ccaa72612b7111e8c53d43389732fda4662c70902946c4e79aa53f504c89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "02000000017075d8896eb76d9bf8019d3d1c8e2043b38aa0d243693bb4b15362c7454064d70000000000ffffffff020000000000000000356a332213dce6127360f01f4f2854f7c42dcffb61775835590ce46367bdf3cd9dff3d8a49668942fccd2c613690b5def0ca886ab87804c89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
        == "020000000132a2d2bfcfbdc710fd9c74d9583860805aedbc5a96d20713678932e237da7f750000000000ffffffff020000000000000000306a2e4320390cbfd097be32d016bae08f3e5500258c18c2e8aab5f84a29046c779a38cf6d419686717acf2255bf5b7a420ec89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
    )


def test_get_tx_infos(apiv1_client, current_block_index, defaults):
    tx_hex = "020000000132a2d2bfcfbdc710fd9c74d9583860805aedbc5a96d20713678932e237da7f750000000000ffffffff020000000000000000306a2e4320390cbfd097be32d016bae08f3e5500258c18c2e8aab5f84a29046c779a38cf6d419686717acf2255bf5b7a420ec89a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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

    tx_hex = "02000000016365886455cedc88649454250736f411ae2b3e229a752da34787e39c171df8e30000000000ffffffff02e8030000000000006951210365ed47a9f91ad12a886de581924a329f7e927a177c10eaa6d7ef383d1afab04f210328a312f14b7c37300dd189f4f3f4a7a4142787ec87f19a77d10366ee957be84c210282b886c087eb37dc8182f14ba6cc3e9485ed618b95804d44aecc17c300b585b053aed0c29a3b000000001976a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac00000000"
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
            "tx_hash": "f2b9b91b7a505bcc31a161104507d99075cbb585711d88b4303531a5ba9c4d2c",
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
            "tx_hash": "7d52e2e957e284aaa987b5c02cd075c172a61bd318aa1987d54410b1d2b595b6",
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
            "tx_hash": "f2b9b91b7a505bcc31a161104507d99075cbb585711d88b4303531a5ba9c4d2c",
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
            "tx_hash": "f2b9b91b7a505bcc31a161104507d99075cbb585711d88b4303531a5ba9c4d2c",
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
            "tx_hash": "f2b9b91b7a505bcc31a161104507d99075cbb585711d88b4303531a5ba9c4d2c",
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
            "tx_hash": "f2b9b91b7a505bcc31a161104507d99075cbb585711d88b4303531a5ba9c4d2c",
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
            "tx_hash": "7d52e2e957e284aaa987b5c02cd075c172a61bd318aa1987d54410b1d2b595b6",
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
