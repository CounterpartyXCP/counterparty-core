import sys
import os
from cx_Freeze import setup, Executable

# Dependencies are automatically detected, but it might need fine tuning.
build_exe_options = {"packages": ["os"], "excludes": []}

base = None
scriptPath = os.path.normpath(os.path.join(os.path.dirname(os.path.realpath(sys.argv[0])), ".."))
setup(  name = "counterpartyd",
        version = "0.1",
        description = "Counterparty Daemon",
        options = {"build_exe": build_exe_options},
        executables = [Executable(os.path.join(scriptPath, "counterpartyd.py"), base=base)])