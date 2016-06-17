#!/usr/bin/python3

import sys
import os
import re
import shutil
import pprint
import binascii

COMMIT = "8906a8188ba841599f66627157e29a270ca838cf"
UNITTEST_FIXTURE_SQL = "counterpartylib/test/fixtures/scenarios/unittest_fixture.sql"
UNITTEST_VECTORS_PY = "counterpartylib/test/fixtures/vectors.py"

REGEX = r"^(?P<change>[+-])INSERT INTO transactions VALUES\((?P<tx_index>\d+),'(?P<tx_hash>.+?)',"

dryrun = '--dry-run' in sys.argv or '--dryrun' in sys.argv
args = list(filter(lambda a: a not in [__file__, '--dry-run', '--dryrun'], sys.argv))

diffcmd = 'git --no-pager diff %s' % UNITTEST_FIXTURE_SQL
if len(args) == 1:
    commit = args[0]
    diffcmd = 'git --no-pager show %s %s' % (commit, UNITTEST_FIXTURE_SQL)

elif len(args) > 1:
    raise Exception("Too many arguments")


def to_literal_byte_string(h):
    r = ""
    for x in binascii.unhexlify(h):
        if x >= 32 and x <= 126:
            # print(x, "[%s]" % chr(x))
            r += chr(x)
        else:
            # print(x, hex(x), "\\x" + ("00" + hex(x).replace('0x', ''))[-2:])
            r += "\\x" + ("00" + hex(x).replace('0x', ''))[-2:]

    return r


old_txid_map = {}
new_txid_map = {}

with os.popen(diffcmd) as diff:
    lines = diff.readlines()

    for line in lines:
        m = re.match(REGEX, line)
        if m:
            if m.group('change') == '+':
                new_txid_map[m.group('tx_index')] = m.group('tx_hash')
            else:
                old_txid_map[m.group('tx_index')] = m.group('tx_hash')

with open(UNITTEST_VECTORS_PY, 'r') as f:
    filedata = f.read()

    for tx_index, old_txid in sorted(old_txid_map.items(), key=lambda kv: kv[0]):
        new_txid = new_txid_map[tx_index]

        print("%s -> %s" % (old_txid, new_txid))

        filedata = filedata.replace(old_txid, new_txid)
        filedata = filedata.replace(to_literal_byte_string(old_txid), to_literal_byte_string(new_txid))


if not dryrun:
    assert filedata
    with open(UNITTEST_VECTORS_PY, 'w') as f:
        f.write(filedata)
else:
    print("DRYRUN")
