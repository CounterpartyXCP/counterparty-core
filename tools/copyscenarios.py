#!/usr/bin/python

import os
import re
import shutil

DIR = "counterpartylib/test/fixtures/scenarios"
REGEX = r"^(?P<name>.*)\.new(?P<ext>\..*)$"

for file in sorted(os.listdir(DIR)):
    m = re.match(REGEX, file)
    if m:
        newfile = m.group('name') + m.group('ext')
        print("%s -> %s" % (file, newfile))
        shutil.copy(os.path.join(DIR, file), os.path.join(DIR, newfile))
