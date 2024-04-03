#!/usr/bin/python3

import sys
import os
import glob

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))
SCENARIOS_DIR = os.path.join(CURRENT_DIR, "..", "counterpartylib/test/fixtures/scenarios")

dryrun = "--dry-run" in sys.argv or "--dryrun" in sys.argv

for new_fixture_path in glob.glob(os.path.join(SCENARIOS_DIR, "*.new.*")):
    old_fixture_path = new_fixture_path.replace(".new.", ".")
    print(f"Move {new_fixture_path} to {old_fixture_path}")
    if not dryrun:
        os.replace(new_fixture_path, old_fixture_path)
