import os, sys

from counterpartylib.lib import config


APP_VERSION = config.VERSION_STRING


CURR_DIR = os.path.dirname(
    os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser("__file__")))
)
WIN_EXE_LIB = os.path.normpath(os.path.join(CURR_DIR, "library"))
if os.path.isdir(WIN_EXE_LIB):
    sys.path.insert(0, WIN_EXE_LIB)
