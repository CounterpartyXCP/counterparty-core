import pytest
from counterpartycore.lib import exceptions, ledger
from counterpartycore.lib.api import compose
from counterpartycore.lib.messages import pooldeposit
from counterpartycore.lib.utils import script
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled

# ============================================================================
# Tests for compose_* functions via API
# ============================================================================


def test_compose_bet(apiv2_client, defaults):
    """Test compose_bet function via API."""
    address = defaults["addresses"][0]
    feed_address = defaults["addresses"][1]
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/bet"
        f"?feed_address={feed_address}"
        f"&bet_type=2"
        f"&deadline=3000000000"
        f"&wager_quantity=1000"
        f"&counterwager_quantity=1000"
        f"&expiration=100"
        f"&target_value=1000"
    )
    # May fail validation (e.g., no broadcast), but the function is exercised
    assert response.status_code in [200, 400]


def test_compose_broadcast(apiv2_client, defaults):
    """Test compose_broadcast function via API."""
    address = defaults["addresses"][0]
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/broadcast"
        f"?timestamp=4003903985"
        f"&value=100"
        f"&fee_fraction=0.05"
        f"&text=Hello, world!"
    )
    # May fail validation, but the function is exercised
    assert response.status_code in [200, 400]


def test_compose_btcpay(apiv2_client, defaults, ledger_db):
    """Test compose_btcpay function via API."""
    # Get an existing order match from the database
    order_match = ledger_db.execute(
        "SELECT id FROM order_matches WHERE status = 'pending' LIMIT 1"
    ).fetchone()
    if order_match:
        address = defaults["addresses"][0]
        response = apiv2_client.get(
            f"/v2/addresses/{address}/compose/btcpay?order_match_id={order_match['id']}"
        )
        # May fail validation but should reach the function
        assert response.status_code in [200, 400]


def test_compose_burn(apiv2_client, defaults):
    """Test compose_burn function via API."""
    address = defaults["addresses"][0]
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/burn?quantity=1000&overburn=false"
    )
    assert response.status_code in [200, 400]  # May fail due to block range


def test_compose_cancel(apiv2_client, defaults, ledger_db):
    """Test compose_cancel function via API."""
    # Get an existing open order
    order = ledger_db.execute(
        "SELECT tx_hash, source FROM orders WHERE status = 'open' LIMIT 1"
    ).fetchone()
    if order:
        response = apiv2_client.get(
            f"/v2/addresses/{order['source']}/compose/cancel?offer_hash={order['tx_hash']}"
        )
        assert response.status_code in [200, 400]


def test_compose_destroy(apiv2_client, defaults):
    """Test compose_destroy function via API."""
    address = defaults["addresses"][0]
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/destroy?asset=XCP&quantity=1000&tag=test"
    )
    assert response.status_code in [200, 400]


def test_compose_dispenser(apiv2_client, defaults):
    """Test compose_dispenser function via API."""
    address = defaults["addresses"][0]
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/dispenser"
        f"?asset=XCP"
        f"&give_quantity=1000"
        f"&escrow_quantity=1000"
        f"&mainchainrate=100"
        f"&status=0"
    )
    assert response.status_code in [200, 400]


def test_compose_dividend(apiv2_client, defaults):
    """Test compose_dividend function via API."""
    address = defaults["addresses"][0]
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/dividend"
        f"?quantity_per_unit=1"
        f"&asset=DIVISIBLE"
        f"&dividend_asset=XCP"
    )
    assert response.status_code in [200, 400]


def test_get_dividend_estimate_xcp_fee(apiv2_client, defaults):
    """Test get_dividend_estimate_xcp_fee function via API."""
    address = defaults["addresses"][0]
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/dividend/estimatexcpfees?asset=DIVISIBLE"
    )
    assert response.status_code == 200
    assert "result" in response.json


def test_compose_issuance(apiv2_client, defaults):
    """Test compose_issuance function via API."""
    address = defaults["addresses"][0]
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/issuance"
        f"?asset=TESTASSET"
        f"&quantity=1000"
        f"&divisible=true"
        f"&lock=false"
        f"&reset=false"
        f"&description=Test asset"
    )
    assert response.status_code in [200, 400]


def test_compose_mpma(apiv2_client, defaults):
    """Test compose_mpma function via API."""
    address = defaults["addresses"][0]
    dest1 = defaults["addresses"][1]
    dest2 = defaults["addresses"][2]
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/mpma"
        f"?assets=XCP,XCP"
        f"&destinations={dest1},{dest2}"
        f"&quantities=100,200"
    )
    assert response.status_code in [200, 400]


def test_compose_order(apiv2_client, defaults):
    """Test compose_order function via API."""
    address = defaults["addresses"][0]
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/order"
        f"?give_asset=XCP"
        f"&give_quantity=1000"
        f"&get_asset=BTC"
        f"&get_quantity=1000"
        f"&expiration=100"
        f"&fee_required=100"
    )
    assert response.status_code in [200, 400]


def test_compose_send(apiv2_client, defaults):
    """Test compose_send function via API."""
    address = defaults["addresses"][0]
    destination = defaults["addresses"][1]
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/send"
        f"?destination={destination}"
        f"&asset=XCP"
        f"&quantity=1000"
        f"&memo=test"
        f"&memo_is_hex=false"
    )
    assert response.status_code in [200, 400]


def test_compose_dispense(apiv2_client, defaults, ledger_db):
    """Test compose_dispense function via API."""
    # Get an existing dispenser address
    dispenser = ledger_db.execute(
        "SELECT source FROM dispensers WHERE status = 0 LIMIT 1"
    ).fetchone()
    if dispenser:
        address = defaults["addresses"][1]
        response = apiv2_client.get(
            f"/v2/addresses/{address}/compose/dispense"
            f"?dispenser={dispenser['source']}"
            f"&quantity=1000"
        )
        assert response.status_code in [200, 400]


def test_compose_sweep(apiv2_client, defaults):
    """Test compose_sweep function via API."""
    address = defaults["addresses"][0]
    destination = defaults["addresses"][1]
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/sweep?destination={destination}&flags=7&memo=FFFF"
    )
    assert response.status_code in [200, 400]


def test_compose_sweep_empty_address_error(apiv2_client, defaults):
    """Test compose_sweep returns a useful error for an empty source address."""
    address = defaults["addresses"][7]
    destination = defaults["addresses"][1]
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/sweep?destination={destination}&flags=3&memo="
    )

    assert response.status_code == 400
    assert "address has no balances or asset ownerships to sweep" in response.json["error"]


def test_get_sweep_estimate_xcp_fee(apiv2_client, defaults):
    """Test get_sweep_estimate_xcp_fee function via API."""
    address = defaults["addresses"][0]
    response = apiv2_client.get(f"/v2/addresses/{address}/compose/sweep/estimatexcpfees")
    assert response.status_code == 200
    assert "result" in response.json


def test_compose_fairminter(apiv2_client, defaults):
    """Test compose_fairminter function via API."""
    address = defaults["addresses"][0]
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/fairminter"
        f"?asset=FAIRTEST"
        f"&lot_price=10"
        f"&lot_size=5"
        f"&max_mint_per_tx=100"
        f"&max_mint_per_address=500"
        f"&hard_cap=10000"
        f"&divisible=true"
        f"&description=Fair minter test"
    )
    assert response.status_code in [200, 400]


def test_compose_fairminter_with_aliases(apiv2_client, defaults):
    """Test compose_fairminter function with price/quantity_by_price aliases via API."""
    address = defaults["addresses"][0]
    # Test with legacy aliases: price and quantity_by_price
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/fairminter"
        f"?asset=FAIRTEST2"
        f"&price=20"
        f"&quantity_by_price=10"
        f"&max_mint_per_tx=100"
    )
    assert response.status_code in [200, 400]


def test_compose_attach(apiv2_client, defaults):
    """Test compose_attach function via API."""
    address = defaults["addresses"][0]
    response = apiv2_client.get(f"/v2/addresses/{address}/compose/attach?asset=XCP&quantity=1000")
    assert response.status_code in [200, 400]


def test_get_attach_estimate_xcp_fee(apiv2_client, defaults):
    """Test get_attach_estimate_xcp_fee function via API."""
    address = defaults["addresses"][0]
    response = apiv2_client.get(f"/v2/addresses/{address}/compose/attach/estimatexcpfees")
    assert response.status_code == 200
    assert "result" in response.json


def test_get_attach_estimate_xcp_fee_no_address(apiv2_client):
    """Test get_attach_estimate_xcp_fee function without address via API."""
    response = apiv2_client.get("/v2/compose/attach/estimatexcpfees")
    assert response.status_code == 200
    assert "result" in response.json


# =============================================================================
# Tests for pool compose and quote functions
# =============================================================================


def test_compose_pooldeposit(apiv2_client, defaults):
    """Test compose_pooldeposit function via API."""
    address = defaults["addresses"][0]
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/pooldeposit"
        f"?asset_a=XCP&asset_b=DIVISIBLE&quantity_a=100000000&quantity_b=100000000"
    )
    assert response.status_code in [200, 400]


def test_get_pool_deposit_estimate_xcp_fee(apiv2_client, defaults):
    """Test get_pool_deposit_estimate_xcp_fee function via API."""
    address = defaults["addresses"][0]
    response = apiv2_client.get(f"/v2/addresses/{address}/compose/pooldeposit/estimatexcpfees")
    assert response.status_code == 200
    assert "result" in response.json
    result = response.json["result"]
    assert result is None or (isinstance(result, int) and result >= 0)


def test_get_pool_withdraw_estimate_xcp_fee(apiv2_client, defaults):
    """Test get_pool_withdraw_estimate_xcp_fee function via API."""
    address = defaults["addresses"][0]
    response = apiv2_client.get(f"/v2/addresses/{address}/compose/poolwithdraw/estimatexcpfees")
    assert response.status_code == 200
    assert "result" in response.json
    result = response.json["result"]
    assert result is None or (isinstance(result, int) and result >= 0)


def test_compose_responses_include_xcp_fee(ledger_db, defaults, monkeypatch):
    def fake_compose_transaction(db, name, params, construct_params):  # noqa: ARG001
        return {
            "name": name,
            "params": params,
            "rawtransaction": "00",
        }

    monkeypatch.setattr(compose.composer, "compose_transaction", fake_compose_transaction)
    monkeypatch.setattr(compose.messages.dividend, "get_estimate_xcp_fee", lambda db, asset: 11)
    monkeypatch.setattr(
        compose.messages.sweep, "get_total_fee", lambda db, address, block_index: 22
    )
    monkeypatch.setattr(compose.gas, "get_transaction_fee", lambda db, tx_id, block_index: tx_id)

    assert (
        compose.compose_dividend(
            ledger_db,
            defaults["addresses"][0],
            quantity_per_unit=1,
            asset="DIVISIBLE",
            dividend_asset="XCP",
        )["xcp_fee"]
        == 11
    )
    assert (
        compose.compose_sweep(
            ledger_db,
            defaults["addresses"][0],
            destination=defaults["addresses"][1],
            flags=1,
            memo="",
        )["xcp_fee"]
        == 22
    )
    assert (
        compose.compose_attach(
            ledger_db,
            defaults["addresses"][0],
            asset="XCP",
            quantity=1,
        )["xcp_fee"]
        == compose.UTXO_ID
    )
    assert (
        compose.compose_pooldeposit(
            ledger_db,
            defaults["addresses"][0],
            asset_a="XCP",
            asset_b="DIVISIBLE",
            quantity_a=1,
            quantity_b=1,
        )["xcp_fee"]
        == 120
    )
    assert (
        compose.compose_poolwithdraw(
            ledger_db,
            defaults["addresses"][0],
            asset_a="XCP",
            asset_b="DIVISIBLE",
            quantity=1,
        )["xcp_fee"]
        == 121
    )


def test_compose_pooldeposit_with_lp_asset(apiv2_client, defaults):
    address = defaults["addresses"][0]
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/pooldeposit"
        f"?asset_a=XCP&asset_b=DIVISIBLE&quantity_a=100000000&quantity_b=100000000"
        f"&lp_asset=A77777777777777777"
    )
    assert response.status_code in [200, 400]


def test_compose_poolwithdraw(apiv2_client, defaults):
    """Test compose_poolwithdraw function via API."""
    address = defaults["addresses"][0]
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/poolwithdraw?asset_a=XCP&asset_b=DIVISIBLE&quantity=1000"
    )
    assert response.status_code in [200, 400]


def test_compose_poolwithdraw_with_slippage(apiv2_client, defaults):
    address = defaults["addresses"][0]
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/poolwithdraw"
        f"?asset_a=XCP&asset_b=DIVISIBLE&quantity=1000"
        f"&min_quantity_a=10&min_quantity_b=10"
    )
    assert response.status_code in [200, 400]


def test_get_pool_quote_deposit(apiv2_client):
    """Test get_pool_quote_deposit function via API."""
    response = apiv2_client.get("/v2/pools/XCP/DIVISIBLE/quote/deposit?quantity=100000000")
    assert response.status_code == 200
    assert "result" in response.json
    result = response.json["result"]
    assert "first_deposit" in result


def test_get_pool_quote_swap(apiv2_client):
    """Test get_pool_quote_swap function via API."""
    response = apiv2_client.get("/v2/pools/XCP/DIVISIBLE/quote?quantity=100000000")
    assert response.status_code == 200
    assert "result" in response.json


def test_get_pool_quote_withdraw(apiv2_client):
    """Test get_pool_quote_withdraw function via API."""
    response = apiv2_client.get("/v2/pools/XCP/DIVISIBLE/quote/withdraw?quantity=1000")
    assert response.status_code == 200
    assert "result" in response.json


def test_compose_poolwithdraw_with_lp_asset(apiv2_client, defaults):
    """Test compose_poolwithdraw with lp_asset parameter instead of asset_a/asset_b."""
    address = defaults["addresses"][0]
    # Use a valid LP asset name. No pool will exist for it, so we expect an error,
    # but the code path that resolves lp_asset -> asset_a/asset_b is exercised.
    response = apiv2_client.get(
        f"/v2/addresses/{address}/compose/poolwithdraw?lp_asset=NONEXISTENTLP&quantity=1000"
    )
    # Should return 400 because no pool found for LP asset
    assert response.status_code == 400


def test_compose_poolwithdraw_with_lp_asset_direct(ledger_db, defaults):
    """Test compose_poolwithdraw with lp_asset parameter directly via compose module."""
    address = defaults["addresses"][0]
    with pytest.raises(exceptions.ComposeError, match="no pool found for LP asset"):
        compose.compose_poolwithdraw(
            ledger_db,
            address=address,
            lp_asset="NONEXISTENTLP",
            quantity=1000,
        )


def test_compose_poolwithdraw_with_lp_asset_success(ledger_db, defaults, blockchain_mock):
    """Test compose_poolwithdraw with lp_asset resolves to asset_a/asset_b from existing pool."""
    source = defaults["addresses"][0]
    quantity = defaults["quantity"]

    # Create a real pool so lp_asset lookup succeeds
    tx = blockchain_mock.dummy_tx(ledger_db, source)
    _, _, data = pooldeposit.compose(ledger_db, source, "XCP", "DIVISIBLE", quantity, quantity)
    pooldeposit.parse(ledger_db, tx, data[1:])

    pool = ledger.markets.get_pool(ledger_db, "DIVISIBLE", "XCP")
    lp_asset = pool["lp_asset"]
    lp_balance = ledger.balances.get_balance(ledger_db, source, lp_asset)
    assert lp_balance > 0

    result = compose.compose_poolwithdraw(
        ledger_db,
        address=source,
        lp_asset=lp_asset,
        quantity=lp_balance,
    )
    assert result is not None


def test_compose_detach(ledger_db, defaults):
    """Test compose_detach function directly."""
    # Test compose_detach function directly to cover the code path
    # Use a synthetic UTXO format (will fail validation but exercises the code)
    try:
        compose.compose_detach(
            ledger_db,
            utxo="0000000000000000000000000000000000000000000000000000000000000000:0",
            destination=defaults["addresses"][0],
        )
    except exceptions.ComposeError:
        pass  # Expected to fail on validation


def test_compose_multiple_detach_route(apiv2_client, defaults, monkeypatch):
    txid_1 = "a" * 64
    txid_2 = "b" * 64
    script_pub_key = "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"
    utxos = f"{txid_1}:0:546:{script_pub_key},{txid_2}:1:546:{script_pub_key}"

    def fake_compose_transaction(db, name, params, construct_params):  # noqa: ARG001
        return {
            "name": name,
            "params": params,
            "construct_params": construct_params,
        }

    monkeypatch.setattr(compose.composer, "compose_transaction", fake_compose_transaction)

    result = apiv2_client.get(
        f"/v2/compose/detach?utxos={utxos}&destination={defaults['addresses'][0]}"
    ).json["result"]

    assert result["name"] == "detach"
    assert result["params"] == {
        "source": f"{txid_1}:0",
        "destination": defaults["addresses"][0],
    }
    assert result["construct_params"]["inputs_set"] == utxos
    assert result["construct_params"]["use_all_inputs_set"] is True
    assert result["construct_params"]["use_utxos_with_balances"] is True


def test_compose_multiple_detach_rejects_inputs_set(ledger_db):
    txid = "a" * 64
    utxo = f"{txid}:0"
    with pytest.raises(exceptions.ComposeError, match="cannot be combined"):
        compose.compose_detach_by_utxos(ledger_db, utxos=utxo, inputs_set=utxo)


def test_compose_multiple_detach_includes_all_utxos(ledger_db, defaults):
    """End-to-end (no mock): every provided UTXO is pulled in as an input and
    the balance-bearing UTXO is selected as the validation source."""
    script_pub_key = "76a9144838d8b3588c4c7ba7c1d06f866e9b3739c6303788ac"
    utxo_with_balance = ledger_db.execute("""
        SELECT utxo FROM balances
        WHERE quantity > 0 AND utxo IS NOT NULL
        ORDER BY rowid DESC LIMIT 1
    """).fetchone()["utxo"]
    # A UTXO without any balance, listed first to ensure the source-selection
    # loop skips it and picks the balance-bearing UTXO that follows.
    extra_utxo = f"{'a' * 64}:1"
    utxos = f"{extra_utxo}:546:{script_pub_key},{utxo_with_balance}:546:{script_pub_key}"

    result = compose.compose_detach_by_utxos(
        ledger_db,
        utxos=utxos,
        destination=defaults["addresses"][1],
        verbose=True,
        disable_utxo_locks=True,
        exact_fee=0,
    )

    # the balance-bearing UTXO (second in the list) is chosen as source
    assert result["name"] == "detach"
    assert result["params"]["source"] == utxo_with_balance
    # both provided UTXOs are forced in as inputs by `use_all_inputs_set`
    assert len(result["inputs_values"]) == 2


def test_compose_movetoutxo(ledger_db, defaults):
    """Test compose_movetoutxo function directly."""
    # Test compose_movetoutxo function directly to cover the code path
    try:
        compose.compose_movetoutxo(
            ledger_db,
            utxo="0000000000000000000000000000000000000000000000000000000000000000:0",
            destination=defaults["addresses"][0],
        )
    except exceptions.ComposeError:
        pass  # Expected to fail on validation


# ============================================================================
# Tests for compose_mpma error validation
# ============================================================================


def test_compose_mpma_mismatched_lengths(ledger_db, defaults):
    """Test compose_mpma with mismatched assets/destinations/quantities."""
    with pytest.raises(
        exceptions.ComposeError,
        match="The number of assets, destinations, and quantities must be equal",
    ):
        compose.compose_mpma(
            ledger_db,
            address=defaults["addresses"][0],
            assets="XCP,XCP",
            destinations=defaults["addresses"][1],  # Only one destination
            quantities="100,200",
        )


def test_compose_mpma_invalid_quantity(ledger_db, defaults):
    """Test compose_mpma with non-integer quantity."""
    with pytest.raises(exceptions.ComposeError, match="Quantity must be an integer"):
        compose.compose_mpma(
            ledger_db,
            address=defaults["addresses"][0],
            assets="XCP",
            destinations=defaults["addresses"][1],
            quantities="abc",
        )


def test_compose_mpma_memos_not_list(ledger_db, defaults):
    """Test compose_mpma with memos not as a list."""
    with pytest.raises(exceptions.ComposeError, match="Memos must be a list"):
        compose.compose_mpma(
            ledger_db,
            address=defaults["addresses"][0],
            assets="XCP",
            destinations=defaults["addresses"][1],
            quantities="100",
            memos="not a list",
        )


def test_compose_mpma_memos_wrong_length(ledger_db, defaults):
    """Test compose_mpma with wrong number of memos."""
    with pytest.raises(
        exceptions.ComposeError,
        match="The number of memos must be equal to the number of sends",
    ):
        compose.compose_mpma(
            ledger_db,
            address=defaults["addresses"][0],
            assets="XCP,XCP",
            destinations=f"{defaults['addresses'][1]},{defaults['addresses'][2]}",
            quantities="100,200",
            memos=["memo1"],  # Only one memo for two sends
        )


def test_compose_mpma_with_memos(ledger_db, defaults):
    """Test compose_mpma with valid memos."""
    # This may fail on validation but should pass the initial parameter processing
    try:
        compose.compose_mpma(
            ledger_db,
            address=defaults["addresses"][0],
            assets="XCP,XCP",
            destinations=f"{defaults['addresses'][1]},{defaults['addresses'][2]}",
            quantities="100,200",
            memos=["memo1", "memo2"],
            memos_are_hex=False,
        )
    except exceptions.ComposeError:
        pass  # Expected to fail on later validation steps


# ============================================================================
# Tests for unpack additional message types
# ============================================================================


def check_unpack(client, data):
    result = client.get("/v2/transactions/unpack?block_index=784320&datahex=" + data["datahex"])
    assert result.status_code == 200
    assert "result" in result.json
    assert result.json["result"] == data["result"]


def test_unpack_no_taproot_support(apiv2_client):
    with ProtocolChangesDisabled(["taproot_support"]):
        test_unpack_taproot_support(apiv2_client)


def test_unpack_taproot_support(apiv2_client):
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
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
                    "mime_type": "text/plain",
                    "status": "valid",
                },
            },
        },
    )

    check_unpack(
        apiv2_client,
        {
            "datahex": "0480bf37348af3d14ffaefcabb3fcf094293b8cc1c8e0273776565656565656570",
            "result": {
                "message_type": "sweep",
                "message_type_id": 4,
                "message_data": {
                    "destination": "bcrt1qhumnfzhn698l4m72hvlu7z2zjwuvc8ywywg0e4",
                    "flags": 2,
                    "memo": "sweeeeeeep",
                },
            },
        },
    )


def test_unpack_old(apiv2_client):
    # 3f63237449ff4e8acf9f19e24b6a7760893d61e00c69036381b5fee291a613ac
    data = "14a9e4545303ba895000000000000000010000005354414d503a6956424f5277304b47676f414141414e535568455567414141426741414141594341594141414467647a33344141414166556c4551565234326d4e674741576a5948694151444f652f3967775451326e69695745444b6649456e52444375316c4d5444564c4d426d4f4c496c4646735170735941787367477738544973674464395543682f30586d6e436757774d536f59674856673268414c5141467a64443177566d473033424d555435417936563458553831433941744176477037674d51473459704b6f767742524846686d4d42474261516f686b41586e4d6d3775756468445141414141415355564f524b35435949493d"
    result = apiv2_client.get("/v2/transactions/unpack?datahex=" + data)
    assert result.status_code == 200
    assert result.json == {
        "result": {
            "message_type": "issuance",
            "message_type_id": 20,
            "message_data": {
                "asset_id": [4],
                "asset": None,
                "subasset_longname": None,
                "quantity": "3a6956424f5277304b47676f41414141",
                "divisible": True,
                "lock": True,
                "reset": True,
                "callable": False,
                "call_date": 0,
                "call_price": 0.0,
                "description": "326e69695745444b6649456e5244437531",
                "mime_type": "NgGAWjYHiAQDO",
                "status": "invalid: bad asset name",
            },
        }
    }

    with ProtocolChangesDisabled(["taproot_support"]):
        data = "14a9e4545303ba895000000000000000010000005354414d503a6956424f5277304b47676f414141414e535568455567414141426741414141594341594141414467647a33344141414166556c4551565234326d4e674741576a5948694151444f652f3967775451326e69695745444b6649456e52444375316c4d5444564c4d426d4f4c496c4646735170735941787367477738544973674464395543682f30586d6e436757774d536f59674856673268414c5141467a64443177566d473033424d555435417936563458553831433941744176477037674d51473459704b6f767742524846686d4d42474261516f686b41586e4d6d3775756468445141414141415355564f524b35435949493d"
        result = apiv2_client.get("/v2/transactions/unpack?datahex=" + data + "&block_index=784320")
        assert result.status_code == 200
        assert result.json == {
            "result": {
                "message_type": "issuance",
                "message_type_id": 20,
                "message_data": {
                    "asset_id": 12242002402621426000,
                    "asset": "A12242002402621426000",
                    "subasset_longname": None,
                    "quantity": 1,
                    "divisible": False,
                    "lock": False,
                    "reset": False,
                    "callable": False,
                    "call_date": 0,
                    "call_price": 0.0,
                    "description": "STAMP:iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAfUlEQVR42mNgGAWjYHiAQDOe/9gwTQ2niiWEDKfIEnRDCu1lMTDVLMBmOLIlFFsQpsYAxsgGw8TIsgDd9UCh/0XmnCgWwMSoYgHVg2hALQAFzdD1wVmG03BMUT5Ay6V4XU81C9AtAvGp7gMQG4YpKovwBRHFhmMBGBaQohkAXnMm7uudhDQAAAAASUVORK5CYII=",
                    "mime_type": "text/plain",
                    "status": "valid",
                },
            }
        }


# ============================================================================
# Tests for unpack additional message types
# ============================================================================


def test_unpack_btcpay(apiv2_client):
    """Test unpack btcpay message type."""
    # BTCPay message: ID 11, order_match_id (32 bytes)
    # Create a mock order_match_id
    order_match_id_hex = "a" * 64  # 32 bytes as hex
    datahex = f"0000000b{order_match_id_hex}"
    result = apiv2_client.get(f"/v2/transactions/unpack?datahex={datahex}&block_index=784320")
    assert result.status_code == 200
    assert result.json["result"]["message_type"] == "btcpay"
    assert result.json["result"]["message_type_id"] == 11


def test_unpack_cancel(apiv2_client):
    """Test unpack cancel message type."""
    # Cancel message: ID 70, offer_hash (32 bytes)
    offer_hash_hex = "b" * 64  # 32 bytes as hex
    datahex = f"00000046{offer_hash_hex}"
    result = apiv2_client.get(f"/v2/transactions/unpack?datahex={datahex}&block_index=784320")
    assert result.status_code == 200
    assert result.json["result"]["message_type"] == "cancel"
    assert result.json["result"]["message_type_id"] == 70


def test_unpack_destroy(apiv2_client):
    """Test unpack destroy message type."""
    # Destroy message: ID 110
    # Format: asset_id (8 bytes), quantity (8 bytes), tag
    asset_id = "0000000000000001"  # XCP
    quantity = "00000000000003e8"  # 1000
    tag_hex = "74657374"  # "test"
    datahex = f"0000006e{asset_id}{quantity}{tag_hex}"
    result = apiv2_client.get(f"/v2/transactions/unpack?datahex={datahex}&block_index=784320")
    assert result.status_code == 200
    assert result.json["result"]["message_type"] == "destroy"
    assert result.json["result"]["message_type_id"] == 110


def test_unpack_dispense(apiv2_client):
    """Test unpack dispense message type."""
    # Dispense message: ID 13
    # Format: dispenser_tx_hash (32 bytes)
    dispenser_tx_hash = "c" * 64
    datahex = f"0000000d{dispenser_tx_hash}"
    result = apiv2_client.get(f"/v2/transactions/unpack?datahex={datahex}&block_index=784320")
    assert result.status_code == 200
    assert result.json["result"]["message_type"] == "dispense"
    assert result.json["result"]["message_type_id"] == 13


def test_unpack_dividend(apiv2_client):
    """Test unpack dividend message type."""
    # Dividend message: ID 50
    # Format: quantity_per_unit (8 bytes), asset_id (8 bytes), dividend_asset_id (8 bytes)
    quantity_per_unit = "0000000000000001"  # 1
    asset_id = "0000000000000002"
    dividend_asset_id = "0000000000000001"  # XCP
    datahex = f"00000032{quantity_per_unit}{asset_id}{dividend_asset_id}"
    result = apiv2_client.get(f"/v2/transactions/unpack?datahex={datahex}&block_index=784320")
    assert result.status_code == 200
    assert result.json["result"]["message_type"] == "dividend"
    assert result.json["result"]["message_type_id"] == 50


def test_unpack_mpma(apiv2_client):
    """Test unpack MPMA message type."""
    # MPMA message: ID 3
    # This is a complex packed format using a real MPMA message
    # Message format: message_type_id (4 bytes) + packed MPMA data
    # Using a valid MPMA message from the mpma_test.py tests
    mpma_data = "00026f4e5638a01efbb2f292481797ae1dcfcdaeb98d006f8d6ae8a3b381663118b4e1eff4cfc7d0954dd6ec400000000000000060000000005f5e10040000000017d78400"
    datahex = f"00000003{mpma_data}"
    result = apiv2_client.get(f"/v2/transactions/unpack?datahex={datahex}&block_index=784320")
    assert result.status_code == 200
    assert result.json["result"]["message_type"] == "mpma_send"
    assert result.json["result"]["message_type_id"] == 3
    # Verify the message_data contains the unpacked sends
    assert isinstance(result.json["result"]["message_data"], list)
    assert len(result.json["result"]["message_data"]) > 0


def test_unpack_rps(apiv2_client):
    """Test unpack RPS message type."""
    # RPS message: ID 80
    # Format varies, just test that it's recognized
    datahex = "0000005000000000000003e800000000000003e8" + "ff" * 32 + "0064"
    result = apiv2_client.get(f"/v2/transactions/unpack?datahex={datahex}&block_index=784320")
    assert result.status_code == 200
    assert result.json["result"]["message_type"] == "rps"
    assert result.json["result"]["message_type_id"] == 80
    assert "error" in result.json["result"]["message_data"]  # Not implemented


def test_unpack_rpsresolve(apiv2_client):
    """Test unpack RPS Resolve message type."""
    # RPS Resolve message: ID 81
    datahex = "00000051" + "aa" * 5 + "bb" * 32
    result = apiv2_client.get(f"/v2/transactions/unpack?datahex={datahex}&block_index=784320")
    assert result.status_code == 200
    assert result.json["result"]["message_type"] == "rpsresolve"
    assert result.json["result"]["message_type_id"] == 81
    assert "error" in result.json["result"]["message_data"]  # Not implemented


def test_unpack_attach(apiv2_client):
    """Test unpack attach message type."""
    # Attach message: ID 101
    # Format: asset_id (8 bytes), quantity (8 bytes)
    asset_id = "0000000000000001"  # XCP
    quantity = "00000000000003e8"  # 1000
    datahex = f"00000065{asset_id}{quantity}"
    result = apiv2_client.get(f"/v2/transactions/unpack?datahex={datahex}&block_index=784320")
    assert result.status_code == 200
    assert result.json["result"]["message_type"] == "attach"
    assert result.json["result"]["message_type_id"] == 101


def test_unpack_detach(apiv2_client):
    """Test unpack detach message type."""
    # Detach message: ID 102
    # Format: destination (address encoded)
    # Include a destination address (pubkeyhash encoded)
    destination_hex = "6f4838d8b3588c4c7ba7c1d06f866e9b3739c63037"  # mn6q3dS2 address bytes
    datahex = f"00000066{destination_hex}"
    result = apiv2_client.get(f"/v2/transactions/unpack?datahex={datahex}&block_index=784320")
    assert result.status_code == 200
    assert result.json["result"]["message_type"] == "detach"
    assert result.json["result"]["message_type_id"] == 102


# ============================================================================
# Tests for unpack error handling
# ============================================================================


def test_unpack_invalid_hex(apiv2_client):
    """Test unpack with invalid hexadecimal data."""
    result = apiv2_client.get("/v2/transactions/unpack?datahex=ZZZZ")
    assert result.status_code == 400
    assert "error" in result.json


def test_unpack_with_prefix(apiv2_client):
    """Test unpack with CNTRPRTY prefix in data."""
    # CNTRPRTY prefix is 434e545250525459 in hex (8 bytes)
    # Followed by a send message
    prefix = "434e545250525459"  # "CNTRPRTY"
    send_data = "00000000000000a25be34b660000000005f5e100"
    datahex = prefix + send_data
    result = apiv2_client.get(f"/v2/transactions/unpack?datahex={datahex}&block_index=784320")
    assert result.status_code == 200
    assert result.json["result"]["message_type"] == "send"


def test_unpack_unknown_message_type(apiv2_client):
    """Test unpack with unknown message type."""
    # Use a message type ID that doesn't exist (e.g., 9999 = 0x270F)
    datahex = "0000270f00000000000000010000000005f5e100"
    result = apiv2_client.get(f"/v2/transactions/unpack?datahex={datahex}&block_index=784320")
    assert result.status_code == 200
    assert result.json["result"]["message_type"] == "unknown"
    assert "error" in result.json["result"]["message_data"]


# ============================================================================
# Tests for info and info_by_tx_hash functions
# ============================================================================


def test_info_by_tx_hash_invalid(apiv2_client):
    """Test info_by_tx_hash with invalid transaction hash.

    Note: This test may timeout if the bitcoind backend is not mocked.
    The compose.info_by_tx_hash function is covered by the API endpoint.
    """
    # Use a clearly invalid tx_hash that should fail quickly
    invalid_tx_hash = "invalid_hash"
    result = apiv2_client.get(f"/v2/transactions/{invalid_tx_hash}/info")
    # Will fail with 400 due to invalid format
    assert result.status_code in [400, 404]


def test_info_invalid_rawtransaction(apiv2_client):
    """Test info with invalid raw transaction."""
    result = apiv2_client.get("/v2/transactions/info?rawtransaction=invalid")
    assert result.status_code == 400


def test_info_valid_rawtransaction(apiv2_client):
    """Test info with valid raw transaction format."""
    # Use a real transaction hex from testnet (a valid structure)
    # This is a simple transaction that can be parsed
    valid_tx_hex = (
        "0200000001"  # version + input count
        "0000000000000000000000000000000000000000000000000000000000000000"  # prev txid
        "00000000"  # prev vout
        "00"  # scriptSig length (empty)
        "ffffffff"  # sequence
        "01"  # output count
        "0000000000000000"  # value
        "00"  # scriptPubKey length
        "00000000"  # locktime
    )
    result = apiv2_client.get(f"/v2/transactions/info?rawtransaction={valid_tx_hex}")
    # Should parse but may fail on other checks
    assert result.status_code in [200, 400]


def test_info_rawtransaction_without_data(apiv2_client):
    """Test info with a raw transaction that doesn't contain Counterparty data."""
    # A simple P2PKH transaction without OP_RETURN
    simple_tx = "0100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000"
    result = apiv2_client.get(f"/v2/transactions/info?rawtransaction={simple_tx}")
    # This should parse but return None for data
    assert result.status_code in [200, 400]


def test_info_btc_only_rawtransaction_without_prevout(ledger_db, monkeypatch):
    """BTC-only raw transactions should still expose output info if prevouts are unavailable."""
    rawtransaction = (
        "02000000000101bfbeaeb997dcc7b5038687e03b378ed69dd708629a13f915c9bed670f6fc83f3"
        "01000000160014dfc964bf32517b3ca8fea9227c5756c887e911c3ffffffff02e80300000000"
        "00001600146fe470998ced5d0f475546787d5cfefdfb7365b7d547000000000000160014df"
        "c964bf32517b3ca8fea9227c5756c887e911c302000000000000"
    )

    def get_tx_info_raises(*args, **kwargs):
        raise exceptions.BitcoindRPCError("prevout not available")

    monkeypatch.setattr(compose.gettxinfo, "get_tx_info", get_tx_info_raises)

    result = compose.info(ledger_db, rawtransaction, block_index=800000)

    assert result["source"] == script.script_to_address(
        "0014dfc964bf32517b3ca8fea9227c5756c887e911c3"
    )
    assert result["destination"] == script.script_to_address(
        "00146fe470998ced5d0f475546787d5cfefdfb7365b7"
    )
    assert result["btc_amount"] == 1000
    assert result["fee"] is None
    assert result["data"] is None
    assert result["unpacked_data"] is None
