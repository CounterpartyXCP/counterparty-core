#! /usr/bin/python3

from .versions import send1

ID = send1.ID

def validate (db, source, destination, asset, quantity, block_index):
    return send1.validate(db, source, destination, asset, quantity, block_index)

def compose (db, source, destination, asset, quantity):
    return send1.compose(db, source, destination, asset, quantity)

def parse (db, tx, message):    # TODO: *args
    return send1.parse(db, tx, message)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4

