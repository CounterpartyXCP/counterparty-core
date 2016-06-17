#!/usr/bin/python3

import sys
import os
import re
import shutil

DIR = "counterpartylib/test/fixtures/scenarios"
REGEX = r"^(?P<name>.*)\.new(?P<ext>\..*)$"

dryrun = '--dry-run' in sys.argv or '--dryrun' in sys.argv
args = list(filter(lambda a: a not in [__file__, '--dry-run', '--dryrun'], sys.argv))

filematch = None
if len(args) == 1:
    filematch = args[0]
elif len(args) > 1:
    raise Exception("Too many arguments")

for file in sorted(os.listdir(DIR)):
    m = re.match(REGEX, file)
    if m:
        newfile = m.group('name') + m.group('ext')

        if filematch and filematch not in newfile:
            continue

        print("%s -> %s" % (file, newfile))
        if not dryrun:
            shutil.copy(os.path.join(DIR, file), os.path.join(DIR, newfile))
