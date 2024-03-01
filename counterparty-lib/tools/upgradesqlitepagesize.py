#!/usr/bin/python3

import os
import shutil
import sys
from subprocess import Popen, PIPE

PAGE_SIZE = 4096

assert len(sys.argv) == 2, "path to DB required"

dbfile = sys.argv[1]
dbdir = os.path.dirname(dbfile)
tmpdir = "%s/upgradesqlitepagesize" % dbdir
sqlfile = "%s/dump.sql" % tmpdir
tmpfile = "%s/%s" % (tmpdir, os.path.basename(dbfile))

if not os.path.isfile(dbfile):
    print("dbfile %s does not exist" % dbfile)
    sys.exit(1)

try:
    os.mkdir(tmpdir)
except FileExistsError:
    print("tmpdir already exists, deleting...")
    shutil.rmtree(tmpdir)
    os.mkdir(tmpdir)

print("creating .sql dump of DB...")
pdump = Popen(["sqlite3", dbfile], stdin=PIPE, stdout=PIPE, stderr=PIPE)
output = pdump.communicate(bytes("""
.headers ON
.mode csv
.output %s
.dump
.output stdout
.exit
""" % sqlfile, "utf-8"))
print(output)
assert pdump.wait() == 0

print("preparing new DB...")
ppre = Popen(["sqlite3", tmpfile], stdin=PIPE, stdout=PIPE, stderr=PIPE)
output = ppre.communicate(bytes("""
PRAGMA journal_mode = OFF;
PRAGMA synchronous = OFF;
PRAGMA page_size=%s;
""" % PAGE_SIZE, "utf-8"))
print(output)
assert ppre.wait() == 0

print("loading .sql dump into DB...")
fsqlfile = os.open(sqlfile, os.O_RDONLY)
pload = Popen(["sqlite3", tmpfile], stdin=fsqlfile, stdout=PIPE, stderr=PIPE)
print(pload.communicate())
assert pload.wait() == 0

print("finalizing new DB...")
ppost = Popen(["sqlite3", tmpfile], stdin=PIPE, stdout=PIPE, stderr=PIPE)
output = ppost.communicate(bytes("""
PRAGMA journal_mode = ON;
PRAGMA synchronous = NORMAL;
""", "utf-8"))
print(output)
assert ppost.wait() == 0

print("replacing old DB with new DB...")
os.remove(dbfile)
os.rename(tmpfile, dbfile)

print("done!")
