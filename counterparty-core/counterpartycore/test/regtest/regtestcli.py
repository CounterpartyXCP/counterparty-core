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


def prepare_seller_signed_psbt(seller_address, txid, vout, price_btc):
    # Seller generates PSBT
    seller_psbt_inputs = json.dumps([{"txid": txid, "vout": int(vout)}])
    seller_psbt_outputs = json.dumps({seller_address: price_btc})
    seller_psbt = bitcoin_cli("createpsbt", seller_psbt_inputs, seller_psbt_outputs).strip()
    # Seller signs PSBT
    signed_seller_psbt_json = bitcoin_cli_json("walletprocesspsbt", seller_psbt)
    # print(signed_seller_psbt_json)
    return signed_seller_psbt_json["psbt"]


def get_utxos_and_change(buyer_address, price_btc):
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
    return buyer_utxos, change


def prepare_buyer_unsigned_psbt(buyer_address, buyer_utxos, change):
    buyer_psbt_inputs = json.dumps(
        [{"txid": utxo["txid"], "vout": utxo["vout"]} for utxo in buyer_utxos]
    )
    buyer_psbt_outputs = json.dumps({buyer_address: str(change)})
    buyer_psbt = bitcoin_cli("createpsbt", buyer_psbt_inputs, buyer_psbt_outputs).strip()
    return buyer_psbt


def first_output_is_buyer(signed_transaction, buyer_address):
    # Sanity check
    decoded_tx = bitcoin_cli_json("decoderawtransaction", signed_transaction)
    # Ensure first output is the seller's address
    if decoded_tx["vout"][0]["scriptPubKey"]["address"] != buyer_address:
        return False
    return True


def join_and_finalize_psbt(psbt_1, psbt_2):
    # Join Buyer and Seller PSBTs
    pbsts = json.dumps([psbt_1, psbt_2])
    final_psbt = bitcoin_cli("joinpsbts", pbsts).strip()
    # Buyer signs final PSBT
    signed_final_psbt_json = bitcoin_cli_json("walletprocesspsbt", final_psbt)
    print(signed_final_psbt_json)
    # Finalize PSBT
    final_psbt_json = bitcoin_cli_json("finalizepsbt", signed_final_psbt_json["psbt"])
    # print(final_psbt_json)
    return final_psbt_json["hex"]


def atomic_swap(seller_address, utxo, price_btc, buyer_address):
    decimal.getcontext().prec = 8

    txid, vout = utxo.split(":")  # UTXO containing the asset(s) to be sold

    # Seller generates PSBT
    signed_seller_psbt = prepare_seller_signed_psbt(seller_address, txid, vout, price_btc)

    # The buyer obtains the PSBT generated (signed_seller_psbt) by the seller somewhere and:

    # Get Buyer UTXOs
    buyer_utxos, change = get_utxos_and_change(buyer_address, price_btc)

    # Buyer generates PSBT
    buyer_psbt = prepare_buyer_unsigned_psbt(buyer_address, buyer_utxos, change)

    # Join Buyer and Seller PSBTs
    signed_transaction = join_and_finalize_psbt(buyer_psbt, signed_seller_psbt)

    # Sanity check
    if not first_output_is_buyer(signed_transaction, buyer_address):
        # try with the other order
        signed_transaction = join_and_finalize_psbt(signed_seller_psbt, buyer_psbt)
    if not first_output_is_buyer(signed_transaction, buyer_address):
        raise Exception("First output is not the buyer's address")

    return signed_transaction


if __name__ == "__main__":
    addresses = get_addresses()
    balances = api_call(f"addresses/{addresses[5]}/balances/MYASSETA")

    atomic_swap(
        addresses[5],
        balances["result"]["utxo"],  # 15 MYASSETA
        100000 / 1e8,  # for 0.001 BTC
        addresses[6],
    )
