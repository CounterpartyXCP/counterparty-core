import decimal
import json

import sh

D = decimal.Decimal

WALLET_NAME = "xcpwallet"

bitcoin_cli = sh.bitcoin_cli.bake(
    "-regtest",
    "-rpcuser=rpc",
    "-rpcpassword=rpc",
    "-rpcconnect=localhost",
)
bitcoin_wallet = bitcoin_cli.bake(f"-rpcwallet={WALLET_NAME}")


def get_addresses():
    addresses_info = bitcoin_cli_json("getaddressesbylabel", WALLET_NAME)
    return list(addresses_info.keys())


def api_call(url):
    return json.loads(sh.curl(f"http://localhost:24000/v2/{url}").strip())


def bitcoin_cli_json(*args):
    return json.loads(bitcoin_cli(*args).strip())


def atomic_swap(params):
    # Parse parameters
    seller_address = params["seller"]  # Seller's address
    txid, vout = params["utxo"].split(":")  # UTXO containing the asset(s) to be sold
    price_btc = params["price"] / 1e8  # Price in satoshis
    buyer_address = params["buyer"]  # Buyer's address

    decimal.getcontext().prec = 8

    # Seller generates PSBT
    seller_psbt_inputs = json.dumps([{"txid": txid, "vout": int(vout)}])
    seller_psbt_outputs = json.dumps({seller_address: price_btc})
    seller_psbt = bitcoin_cli("createpsbt", seller_psbt_inputs, seller_psbt_outputs).strip()
    # Seller signs PSBT
    signed_seller_psbt_json = bitcoin_cli_json("walletprocesspsbt", seller_psbt)
    print(signed_seller_psbt_json)
    signed_seller_psbt = signed_seller_psbt_json["psbt"]

    # The buyer obtains the PSBT generated (signed_seller_psbt) by the seller somewhere and:

    # Get Buyer UTXOs
    # Super naive way to select UTXOs only for testing purposes
    buyer_utxos = json.loads(
        bitcoin_wallet("listunspent", 0, 9999999, json.dumps([buyer_address])).strip()
    )
    total_value = sum([utxo["amount"] for utxo in buyer_utxos])
    # Calculate fee
    input_count = len(buyer_utxos)
    fee_per_kb = bitcoin_cli_json("estimatesmartfee", 1)["feerate"]
    # Transaction Size (in bytes) = (Number of Inputs x 148) + (Number of Outputs x 34) + 10
    tx_size = (input_count * 148) + (2 * 34) + 10
    fee = D(fee_per_kb) * (D(tx_size) / 1024)
    # Calculate change
    change = D(total_value) - D(price_btc) - D(fee)

    # Buyer generates PSBT
    buyer_psbt_inputs = json.dumps(
        [{"txid": utxo["txid"], "vout": utxo["vout"]} for utxo in buyer_utxos]
    )
    buyer_psbt_outputs = json.dumps({buyer_address: str(change)})
    buyer_psbt = bitcoin_cli("createpsbt", buyer_psbt_inputs, buyer_psbt_outputs).strip()

    # Join Buyer and Seller PSBTs
    pbsts = json.dumps([buyer_psbt, signed_seller_psbt])
    final_psbt = bitcoin_cli("joinpsbts", pbsts).strip()
    # Buyer signs final PSBT
    signed_final_psbt_json = bitcoin_cli_json("walletprocesspsbt", final_psbt)
    print(signed_final_psbt_json)
    # Finalize PSBT
    final_psbt_json = bitcoin_cli_json("finalizepsbt", signed_final_psbt_json["psbt"])
    print(final_psbt_json)
    signed_transaction = final_psbt_json["hex"]

    # Sanity check
    decoded_tx = bitcoin_cli_json("decoderawtransaction", signed_transaction)
    # Ensure first output is the seller's address
    assert decoded_tx["vout"][0]["scriptPubKey"]["address"] == buyer_address
    # print("Decoded PSBT:", json.dumps(decoded_tx, indent=4))

    return signed_transaction


if __name__ == "__main__":
    addresses = get_addresses()
    balances = api_call(f"addresses/{addresses[5]}/balances/MYASSETA")

    atomic_swap(
        {
            "seller": addresses[5],
            "utxo": balances["result"]["utxo"],  # 15.00000000 MYASSETA
            "price": 100000,  # for 100000 satoshis
            "buyer": addresses[6],
        }
    )
