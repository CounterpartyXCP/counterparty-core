from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def check_unpack(client, data):
    result = client.get("/v2/transactions/unpack?datahex=" + data["datahex"])
    assert result.status_code == 200
    assert "result" in result.json
    assert result.json["result"] == data["result"]


def test_unpack(apiv2_client):
    with ProtocolChangesDisabled(["taproot_support"]):
        check_unpack(
            apiv2_client,
            {
                "datahex": "14000000a25be34b66000000174876e800010000446976697369626c65206173736574",
                "result": {
                    "message_type": "issuance",
                    "message_type_id": 20,
                    "message_data": {
                        "asset_id": 697326324582,
                        "asset": "DIVISIBLE",
                        "subasset_longname": None,
                        "quantity": 100000000000,
                        "divisible": True,
                        "lock": False,
                        "reset": False,
                        "callable": False,
                        "call_date": 0,
                        "call_price": 0.0,
                        "description": "Divisible asset",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "000000140006cad8dc7f0b6600000000000003e80000004e6f20646976697369626c65206173736574",
                "result": {
                    "message_type": "issuance",
                    "message_type_id": 20,
                    "message_data": {
                        "asset_id": 1911882621324134,
                        "asset": "NODIVISIBLE",
                        "subasset_longname": None,
                        "quantity": 1000,
                        "divisible": False,
                        "lock": False,
                        "reset": False,
                        "callable": False,
                        "call_date": 0,
                        "call_price": 0.0,
                        "description": "No divisible asset",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000001400000003c58e5c5600000000000003e801000043616c6c61626c65206173736574",
                "result": {
                    "message_type": "issuance",
                    "message_type_id": 20,
                    "message_data": {
                        "asset_id": 16199343190,
                        "asset": "CALLABLE",
                        "subasset_longname": None,
                        "quantity": 1000,
                        "divisible": True,
                        "lock": False,
                        "reset": False,
                        "callable": False,
                        "call_date": 0,
                        "call_price": 0.0,
                        "description": "Callable asset",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000001400000000082c82e300000000000003e80100004c6f636b6564206173736574",
                "result": {
                    "message_type": "issuance",
                    "message_type_id": 20,
                    "message_data": {
                        "asset_id": 137134819,
                        "asset": "LOCKED",
                        "subasset_longname": None,
                        "quantity": 1000,
                        "divisible": True,
                        "lock": False,
                        "reset": False,
                        "callable": False,
                        "call_date": 0,
                        "call_price": 0.0,
                        "description": "Locked asset",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000001400000000082c82e300000000000000000100004c4f434b",
                "result": {
                    "message_type": "issuance",
                    "message_type_id": 20,
                    "message_data": {
                        "asset_id": 137134819,
                        "asset": "LOCKED",
                        "subasset_longname": None,
                        "quantity": 0,
                        "divisible": True,
                        "lock": False,
                        "reset": False,
                        "callable": False,
                        "call_date": 0,
                        "call_price": 0.0,
                        "description": "LOCK",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000000a00000000000000010000000005f5e100000000a25be34b660000000005f5e10007d00000000000000000",
                "result": {
                    "message_type": "order",
                    "message_type_id": 10,
                    "message_data": {
                        "give_asset": "XCP",
                        "give_quantity": 100000000,
                        "get_asset": "DIVISIBLE",
                        "get_quantity": 100000000,
                        "expiration": 2000,
                        "fee_required": 0,
                        "status": "open",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "00000000000000a25be34b660000000005f5e100",
                "result": {
                    "message_type": "send",
                    "message_type_id": 0,
                    "message_data": {"asset": "DIVISIBLE", "quantity": 100000000},
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000000000000000000000010000000005f5e100",
                "result": {
                    "message_type": "send",
                    "message_type_id": 0,
                    "message_data": {"asset": "XCP", "quantity": 100000000},
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000000a00000000000000010000000005f5e100000000a25be34b660000000005f5e10007d00000000000000000",
                "result": {
                    "message_type": "order",
                    "message_type_id": 10,
                    "message_data": {
                        "give_asset": "XCP",
                        "give_quantity": 100000000,
                        "get_asset": "DIVISIBLE",
                        "get_quantity": 100000000,
                        "expiration": 2000,
                        "fee_required": 0,
                        "status": "open",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000000a00000000000000010000000005f5e100000000000000000000000000000f424007d000000000000dbba0",
                "result": {
                    "message_type": "order",
                    "message_type_id": 10,
                    "message_data": {
                        "give_asset": "XCP",
                        "give_quantity": 100000000,
                        "get_asset": "BTC",
                        "get_quantity": 1000000,
                        "expiration": 2000,
                        "fee_required": 900000,
                        "status": "open",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000000a000000000000000000000000000a2c2b00000000000000010000000005f5e10007d00000000000000000",
                "result": {
                    "message_type": "order",
                    "message_type_id": 10,
                    "message_data": {
                        "give_asset": "BTC",
                        "give_quantity": 666667,
                        "get_asset": "XCP",
                        "get_quantity": 100000000,
                        "expiration": 2000,
                        "fee_required": 0,
                        "status": "open",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000000000000000000000010000000011e1a300",
                "result": {
                    "message_type": "send",
                    "message_type_id": 0,
                    "message_data": {"asset": "XCP", "quantity": 300000000},
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "00000000000000a25be34b66000000003b9aca00",
                "result": {
                    "message_type": "send",
                    "message_type_id": 0,
                    "message_data": {"asset": "DIVISIBLE", "quantity": 1000000000},
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "000000000006cad8dc7f0b660000000000000005",
                "result": {
                    "message_type": "send",
                    "message_type_id": 0,
                    "message_data": {"asset": "NODIVISIBLE", "quantity": 5},
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "000000000006cad8dc7f0b66000000000000000a",
                "result": {
                    "message_type": "send",
                    "message_type_id": 0,
                    "message_data": {"asset": "NODIVISIBLE", "quantity": 10},
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "000000140000000000033a3e7fffffffffffffff0100004d6178696d756d207175616e74697479",
                "result": {
                    "message_type": "issuance",
                    "message_type_id": 20,
                    "message_data": {
                        "asset_id": 211518,
                        "asset": "MAXI",
                        "subasset_longname": None,
                        "quantity": 9223372036854775807,
                        "divisible": True,
                        "lock": False,
                        "reset": False,
                        "callable": False,
                        "call_date": 0,
                        "call_price": 0.0,
                        "description": "Maximum quantity",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000001e52bb33003ff0000000000000004c4b4009556e69742054657374",
                "result": {
                    "message_type": "broadcast",
                    "message_type_id": 30,
                    "message_data": {
                        "timestamp": 1388000000,
                        "value": 1.0,
                        "fee_fraction_int": 5000000,
                        "text": "Unit Test",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000001e4cc552003ff000000000000000000000046c6f636b",
                "result": {
                    "message_type": "broadcast",
                    "message_type_id": 30,
                    "message_data": {
                        "timestamp": 1288000000,
                        "value": 1.0,
                        "fee_fraction_int": 0,
                        "text": "lock",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "00000028000152bb3301000000000000000900000000000000090000000000000000000013b000000064",
                "result": {
                    "message_type": "bet",
                    "message_type_id": 40,
                    "message_data": {
                        "bet_type": 1,
                        "deadline": 1388000001,
                        "wager_quantity": 9,
                        "counterwager_quantity": 9,
                        "target_value": 0.0,
                        "leverage": 5040,
                        "expiration": 100,
                        "status": "open",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "00000028000052bb3301000000000000000900000000000000090000000000000000000013b000000064",
                "result": {
                    "message_type": "bet",
                    "message_type_id": 40,
                    "message_data": {
                        "bet_type": 0,
                        "deadline": 1388000001,
                        "wager_quantity": 9,
                        "counterwager_quantity": 9,
                        "target_value": 0.0,
                        "leverage": 5040,
                        "expiration": 100,
                        "status": "open",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "00000028000352bb33c8000000000000000a000000000000000a0000000000000000000013b0000003e8",
                "result": {
                    "message_type": "bet",
                    "message_type_id": 40,
                    "message_data": {
                        "bet_type": 3,
                        "deadline": 1388000200,
                        "wager_quantity": 10,
                        "counterwager_quantity": 10,
                        "target_value": 0.0,
                        "leverage": 5040,
                        "expiration": 1000,
                        "status": "open",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000001e52bb33023ff0000000000000004c4b4009556e69742054657374",
                "result": {
                    "message_type": "broadcast",
                    "message_type_id": 30,
                    "message_data": {
                        "timestamp": 1388000002,
                        "value": 1.0,
                        "fee_fraction_int": 5000000,
                        "text": "Unit Test",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000000c000000000000000100000000000000640000000000000064000000000000006400",
                "result": {
                    "message_type": "dispenser",
                    "message_type_id": 12,
                    "message_data": {
                        "asset": "XCP",
                        "give_quantity": 100,
                        "escrow_quantity": 100,
                        "mainchainrate": 100,
                        "dispenser_status": 0,
                        "action_address": None,
                        "oracle_address": None,
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000001400078a8fe2e5e44100000000000003e800000050534820697373756564206173736574",
                "result": {
                    "message_type": "issuance",
                    "message_type_id": 20,
                    "message_data": {
                        "asset_id": 2122675428648001,
                        "asset": "PAYTOSCRIPT",
                        "subasset_longname": None,
                        "quantity": 1000,
                        "divisible": False,
                        "lock": False,
                        "reset": False,
                        "callable": False,
                        "call_date": 0,
                        "call_price": 0.0,
                        "description": "PSH issued asset",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "00000000000000a25be34b660000000005f5e100",
                "result": {
                    "message_type": "send",
                    "message_type_id": 0,
                    "message_data": {"asset": "DIVISIBLE", "quantity": 100000000},
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000001e52bb33023ff0000000000000004c4b4009556e69742054657374",
                "result": {
                    "message_type": "broadcast",
                    "message_type_id": 30,
                    "message_data": {
                        "timestamp": 1388000002,
                        "value": 1.0,
                        "fee_fraction_int": 5000000,
                        "text": "Unit Test",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "00000028000352bb33c8000000000000000a000000000000000a0000000000000000000013b0000003e8",
                "result": {
                    "message_type": "bet",
                    "message_type_id": 40,
                    "message_data": {
                        "bet_type": 3,
                        "deadline": 1388000200,
                        "wager_quantity": 10,
                        "counterwager_quantity": 10,
                        "target_value": 0.0,
                        "leverage": 5040,
                        "expiration": 1000,
                        "status": "open",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "00000014000038fedf6d2c6900000000000003e80100004c6f636b6564206173736574",
                "result": {
                    "message_type": "issuance",
                    "message_type_id": 20,
                    "message_data": {
                        "asset_id": 62667321322601,
                        "asset": "LOCKEDPREV",
                        "subasset_longname": None,
                        "quantity": 1000,
                        "divisible": True,
                        "lock": False,
                        "reset": False,
                        "callable": False,
                        "call_date": 0,
                        "call_price": 0.0,
                        "description": "Locked asset",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "00000014000038fedf6d2c6900000000000000000100004c4f434b",
                "result": {
                    "message_type": "issuance",
                    "message_type_id": 20,
                    "message_data": {
                        "asset_id": 62667321322601,
                        "asset": "LOCKEDPREV",
                        "subasset_longname": None,
                        "quantity": 0,
                        "divisible": True,
                        "lock": False,
                        "reset": False,
                        "callable": False,
                        "call_date": 0,
                        "call_price": 0.0,
                        "description": "LOCK",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "00000014000038fedf6d2c6900000000000000000100006368616e676564",
                "result": {
                    "message_type": "issuance",
                    "message_type_id": 20,
                    "message_data": {
                        "asset_id": 62667321322601,
                        "asset": "LOCKEDPREV",
                        "subasset_longname": None,
                        "quantity": 0,
                        "divisible": True,
                        "lock": False,
                        "reset": False,
                        "callable": False,
                        "call_date": 0,
                        "call_price": 0.0,
                        "description": "changed",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000000200000000000000010000000005f5e1006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec68656c6c6f",
                "result": {
                    "message_type": "enhanced_send",
                    "message_type_id": 2,
                    "message_data": {
                        "asset": "XCP",
                        "quantity": 100000000,
                        "address": "mtQheFaSfWELRB2MyMBaiWjdDm6ux9Ezns",
                        "memo": "68656c6c6f",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000000200000000000000010000000005f5e1006f4838d8b3588c4c7ba7c1d06f866e9b3739c63037fade0001",
                "result": {
                    "message_type": "enhanced_send",
                    "message_type_id": 2,
                    "message_data": {
                        "asset": "XCP",
                        "quantity": 100000000,
                        "address": "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                        "memo": "fade0001",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000001e52bb33003ff0000000000000004c4b4009556e69742054657374",
                "result": {
                    "message_type": "broadcast",
                    "message_type_id": 30,
                    "message_data": {
                        "timestamp": 1388000000,
                        "value": 1.0,
                        "fee_fraction_int": 5000000,
                        "text": "Unit Test",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "00000028000152bb3301000000000000000900000000000000090000000000000000000013b000000064",
                "result": {
                    "message_type": "bet",
                    "message_type_id": 40,
                    "message_data": {
                        "bet_type": 1,
                        "deadline": 1388000001,
                        "wager_quantity": 9,
                        "counterwager_quantity": 9,
                        "target_value": 0.0,
                        "leverage": 5040,
                        "expiration": 100,
                        "status": "open",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000001e52bb33023ff000000000000000000000096f7074696f6e732030",
                "result": {
                    "message_type": "broadcast",
                    "message_type_id": 30,
                    "message_data": {
                        "timestamp": 1388000002,
                        "value": 1.0,
                        "fee_fraction_int": 0,
                        "text": "options 0",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000001e52bb33033ff000000000000000000000046c6f636b",
                "result": {
                    "message_type": "broadcast",
                    "message_type_id": 30,
                    "message_data": {
                        "timestamp": 1388000003,
                        "value": 1.0,
                        "fee_fraction_int": 0,
                        "text": "lock",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000001e52bb33043ff000000000000000000000096f7074696f6e732031",
                "result": {
                    "message_type": "broadcast",
                    "message_type_id": 30,
                    "message_data": {
                        "timestamp": 1388000004,
                        "value": 1.0,
                        "fee_fraction_int": 0,
                        "text": "options 1",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000000a00000000000000010000000005f5e100000000000000000000000000000c350007d000000000000dbba0",
                "result": {
                    "message_type": "order",
                    "message_type_id": 10,
                    "message_data": {
                        "give_asset": "XCP",
                        "give_quantity": 100000000,
                        "get_asset": "BTC",
                        "get_quantity": 800000,
                        "expiration": 2000,
                        "fee_required": 900000,
                        "status": "open",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "0000000a000000000000000000000000000c350000000000000000010000000005f5e10007d00000000000000000",
                "result": {
                    "message_type": "order",
                    "message_type_id": 10,
                    "message_data": {
                        "give_asset": "BTC",
                        "give_quantity": 800000,
                        "get_asset": "XCP",
                        "get_quantity": 100000000,
                        "expiration": 2000,
                        "fee_required": 0,
                        "status": "open",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "00000014000000063e985ffd0000000000000064010000",
                "result": {
                    "message_type": "issuance",
                    "message_type_id": 20,
                    "message_data": {
                        "asset_id": 26819977213,
                        "asset": "DIVIDEND",
                        "subasset_longname": None,
                        "quantity": 100,
                        "divisible": True,
                        "lock": False,
                        "reset": False,
                        "callable": False,
                        "call_date": 0,
                        "call_price": 0.0,
                        "description": "",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "00000000000000063e985ffd000000000000000a",
                "result": {
                    "message_type": "send",
                    "message_type_id": 0,
                    "message_data": {"asset": "DIVIDEND", "quantity": 10},
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "00000000000000000000000100000015a4018c1e",
                "result": {
                    "message_type": "send",
                    "message_type_id": 0,
                    "message_data": {"asset": "XCP", "quantity": 92945878046},
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "00000014000000000aa4097d0000000005f5e100010000506172656e74206173736574",
                "result": {
                    "message_type": "issuance",
                    "message_type_id": 20,
                    "message_data": {
                        "asset_id": 178522493,
                        "asset": "PARENT",
                        "subasset_longname": None,
                        "quantity": 100000000,
                        "divisible": True,
                        "lock": False,
                        "reset": False,
                        "callable": False,
                        "call_date": 0,
                        "call_price": 0.0,
                        "description": "Parent asset",
                        "status": "valid",
                    },
                },
            },
        )

        check_unpack(
            apiv2_client,
            {
                "datahex": "17015308218f586bb000000000000003e8010000108e90a57dba99d3a77b0a2470b1816edb",
                "result": {
                    "message_type": "issuance",
                    "message_type_id": 23,
                    "message_data": {
                        "asset_id": 95428957336791984,
                        "asset": "A95428957336791984",
                        "subasset_longname": "PARENT.a-zA-Z0-9.-_@!",
                        "quantity": 1000,
                        "divisible": True,
                        "lock": False,
                        "reset": False,
                        "callable": False,
                        "call_date": 0,
                        "call_price": 0.0,
                        "description": "",
                        "status": "valid",
                    },
                },
            },
        )
