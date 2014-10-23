import binascii

from pycoin import ecdsa
from pycoin.encoding import public_pair_to_sec, is_sec_compressed, sec_to_public_pair,\
    hash160_sec_to_bitcoin_address, public_pair_to_bitcoin_address,\
    public_pair_to_hash160_sec
from pycoin.tx.script import der, opcodes, tools

from .exceptions import SolvingError

class TxScript():

    TEMPLATES = [
        tools.compile("OP_PUBKEY OP_CHECKSIG"),
        tools.compile("OP_DUP OP_HASH160 OP_PUBKEYHASH OP_EQUALVERIFY OP_CHECKSIG"),
        tools.compile("OP_1 OP_PUBKEY OP_PUBKEY OP_2 OP_CHECKMULTISIG"),
        tools.compile("OP_2 OP_PUBKEY OP_PUBKEY OP_2 OP_CHECKMULTISIG"),
        tools.compile("OP_1 OP_PUBKEY OP_PUBKEY OP_PUBKEY OP_3 OP_CHECKMULTISIG"),
        tools.compile("OP_2 OP_PUBKEY OP_PUBKEY OP_PUBKEY OP_3 OP_CHECKMULTISIG"),
        tools.compile("OP_3 OP_PUBKEY OP_PUBKEY OP_PUBKEY OP_3 OP_CHECKMULTISIG"),
        tools.compile("OP_RETURN OP_PUSHDATA1")
    ]

    def __init__(self, script):
        self.script = script

    def match_script_to_templates(self):
        """Examine the script passed in by tx_out_script and see if it
        matches the form of one of the templates in TEMPLATES. If so,
        return the form it matches; otherwise, return None."""
        
        for script2 in TxScript.TEMPLATES:       
            r = []
            pc1 = pc2 = 0
            while 1:  

                if pc1 == len(self.script) and pc2 == len(script2):
                    return r
               
                opcode1, data1, pc1 = tools.get_opcode(self.script, pc1)            
                opcode2, data2, pc2 = tools.get_opcode(script2, pc2)           

                if opcode2 == opcodes.OP_PUBKEY:
                    l1 = len(data1)
                    if l1 < 33 or l1 > 120:
                        break
                    r.append((opcode2, data1))
                elif opcode2 == opcodes.OP_PUBKEYHASH:
                    if len(data1) != 160/8:
                        break
                    r.append((opcode2, data1))
                elif (opcode1, data1) != (opcode2, data2):
                    break
        raise SolvingError("don't recognize output script")


    def bitcoin_address_for_script(self, is_test=False):
        try:
            r = self.match_script_to_templates()
            if len(r) != 1 or len(r[0]) != 2:
                return None
            if r[0][0] == opcodes.OP_PUBKEYHASH:
                return hash160_sec_to_bitcoin_address(r[0][1], is_test=is_test)
            if r[0][0] == opcodes.OP_PUBKEY:
                sec = r[0][1]
                return public_pair_to_bitcoin_address(
                    sec_to_public_pair(sec),
                    compressed=is_sec_compressed(sec),
                    is_test=is_test)
        except SolvingError:
            pass
        return None

    def to_asm(self):
        return tools.disassemble(self.script)


