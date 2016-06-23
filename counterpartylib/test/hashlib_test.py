import hashlib
import binascii
import rlp

def test_sha3():
    sender = b'\x00\xb625+E\x06\x96\xbe\x10\x0e\xdc!58?\x00\x83\xa4\x99'
    nonce = b''

    b = rlp.encode([sender, nonce])
    assert b == b'\xd6\x94\x00\xb625+E\x06\x96\xbe\x10\x0e\xdc!58?\x00\x83\xa4\x99\x80'

    contract_id = hashlib.sha3_256(b).digest()
    assert contract_id == b'"Y[\xe7^\xe8\xba\r\xcc\xc2\xe5(\xe6\xc9\xed\xa9\x81w\x1a2\x17\xed\xa4\xf9?\x9c\xe3\xc3)\x16\x13\x99'

    contract_id = contract_id[12:]
    assert contract_id == b'\xe6\xc9\xed\xa9\x81w\x1a2\x17\xed\xa4\xf9?\x9c\xe3\xc3)\x16\x13\x99'

    contract_id = binascii.hexlify(contract_id).decode('ascii')
    assert contract_id == 'e6c9eda981771a3217eda4f93f9ce3c329161399'
