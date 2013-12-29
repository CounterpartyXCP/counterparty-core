#! /usr/bin/env python3
"""
Runs counterpartyd or the counterpartyd test suite via the python interpreter in its virtualenv on both Linux and Windows
"""
import os
import sys

assert os.name in ("nt", "posix")

run_tests = False
args = sys.argv[1:]
if len(sys.argv) >= 2 and sys.argv[1] == 'tests':
    run_tests = True
    args = sys.argv[2:]
    
#set default data dir path on Linux
if os.name == "posix" and not any(["data-dir" in e for e in args]):
    args.append("--data-dir=/var/lib/counterpartyd")
    
base_path = os.path.dirname(os.path.realpath(sys.argv[0]))
env_path = os.path.join(base_path, "env")
python_path = os.path.join(env_path, "bin", "python.exe" if os.name == "nt" else "python3")
pytest_path = os.path.join(env_path, "bin", "py.test.exe" if os.name == "nt" else "pytest")
counterparty_path = os.path.join(base_path, "counterpartyd.py")
cmd_prefix = ""
if os.name == "posix":
    cmd_prefix = "sudo -H -u counterpartyd -s " #to execute as the counterpartyd user

os.system("%s%s %s %s" % (cmd_prefix, python_path, pytest_path if run_tests else counterparty_path, ' '.join(args)))
