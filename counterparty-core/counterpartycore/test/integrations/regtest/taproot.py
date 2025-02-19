import binascii

from bitcoinutils.keys import PrivateKey
from bitcoinutils.script import Script
from bitcoinutils.setup import setup
from bitcoinutils.transactions import Transaction, TxInput, TxOutput, TxWitnessInput
from bitcoinutils.utils import ControlBlock
from counterpartycore.lib.utils import helpers


def compose_signed_commit_tx(private_key, content, utxo_txid, utxo_vout, utxo_amount):
    source_pubkey = private_key.get_public_key()
    source_address = source_pubkey.get_taproot_address()

    # Inputs
    tx_in = TxInput(utxo_txid, utxo_vout)

    # Outputs

    # split the data in chunks of 520 bytes
    datas = helpers.chunkify(content, 520)
    datas = [binascii.hexlify(data).decode("utf-8") for data in datas]

    # Build inscription envelope script
    inscription_script = Script(["OP_FALSE", "OP_IF"] + datas + ["OP_ENDIF"])
    # use source address as destination
    commit_address = source_pubkey.get_taproot_address([[inscription_script]])
    print("To Taproot script address", commit_address.to_string())

    # create the output and the transaction
    commit_value = utxo_amount - 330  # 3 sat/vbyte for a 110 vbyte transaction
    tx_out = TxOutput(commit_value, commit_address.to_script_pub_key())
    commit_tx = Transaction([tx_in], [tx_out], has_segwit=True)

    # sign the input
    sig = private_key.sign_taproot_input(
        commit_tx, 0, [source_address.to_script_pub_key()], [utxo_amount]
    )
    # add the witness to the transaction
    commit_tx.witnesses.append(TxWitnessInput([sig]))

    return commit_tx, commit_address, commit_value, inscription_script


def compose_signed_reveal_tx(
    private_key, commit_txid, commit_vout, commit_address, commit_value, inscription_script
):
    source_pubkey = private_key.get_public_key()
    # use commit tx as input
    tx_in = TxInput(commit_txid, commit_vout)
    # use source address as output
    tx_out = TxOutput(0, Script(["OP_RETURN", binascii.hexlify(b"CNTRPRTY").decode("ascii")]))
    reveal_tx = Transaction([tx_in], [tx_out], has_segwit=True)

    # sign the input containing the inscription script
    sig = private_key.sign_taproot_input(
        reveal_tx,
        0,
        [commit_address.to_script_pub_key()],
        [commit_value],
        script_path=True,
        tapleaf_script=inscription_script,
        tweak=False,
    )
    # generate the control block
    control_block = ControlBlock(
        source_pubkey,
        scripts=[inscription_script],
        index=0,
        is_odd=commit_address.is_odd(),
    )

    # add the witness to the transaction
    reveal_tx.witnesses.append(
        TxWitnessInput([sig, inscription_script.to_hex(), control_block.to_hex()])
    )
    return reveal_tx


def compose_signed_transactions(private_key, content, utxo_txid, utxo_vout, utxo_amount):
    commit_tx, commit_address, commit_value, inscription_script = compose_signed_commit_tx(
        private_key, content, utxo_txid, utxo_vout, utxo_amount
    )

    print("Signed Commit Transaction:", commit_tx.serialize())
    print("Commit vsize:", commit_tx.get_vsize())

    commit_txid = commit_tx.get_txid()
    commit_vout = 0
    reveal_tx = compose_signed_reveal_tx(
        private_key, commit_txid, commit_vout, commit_address, commit_value, inscription_script
    )

    print("Signed Reveal Transaction:", reveal_tx.serialize()[0:100])
    print("Signed Reveal Transaction vSize:", reveal_tx.get_vsize())

    return commit_tx, reveal_tx


if __name__ == "__main__":
    setup("mainnet")

    private_key_hex = ""
    content = b"\x01" * 1024 * 387  # near to 100K vbytes transaction
    utxo_txid = ""
    utxo_vout = 0
    utxo_amount = 0

    private_key = PrivateKey(b=binascii.unhexlify(private_key_hex))

    commit_tx, reveal_tx = compose_signed_transactions(
        private_key, content, utxo_txid, utxo_vout, utxo_amount
    )
    print("Commit Transaction:", commit_tx.serialize())
    print("Reveal Transaction:", reveal_tx.serialize())
