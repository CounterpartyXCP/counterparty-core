#! /usr/bin/python3

import pytest

def pytest_addoption(parser):
    parser.addoption("--function", action="append", default=[], help="list of functions to test")
