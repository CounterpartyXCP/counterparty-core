#!/usr/bin/env python

from setuptools import setup, find_packages
import os

def readme():
    here = os.path.abspath(os.path.dirname(__file__))
    with open(os.path.join(here, 'README.md'), 'r', encoding="utf-8") as f:
        return f.read()

required_packages = [
    'appdirs==1.4.0',
    'prettytable==0.7.2',
    'python-dateutil==2.2',
    'requests==2.4.2',
    'colorlog==2.4.0',
    'counterparty-lib==9.49.3'
]

required_repos = [
    'https://github.com/CounterpartyXCP/counterpartyd/archive/develop.zip#egg=counterparty-lib-9.49.3'
]

setup_options = {
    'name': 'counterparty-cli',
    'version': '1.0.0',
    'description': 'CLI for the Counterparty protocol.',
    'long_description': readme(),
    'classifiers': [
      "Programming Language :: Python",
    ],
    'url': 'https://github.com/CounterpartyXCP/counterparty-cli',
    'keywords': 'counterparty, bitcoin',
    'packages': find_packages(),
    'zip_safe': False,
    'dependency_links': required_repos,
    'install_requires': required_packages,
    'scripts': ['bin/counterparty-client', 'bin/counterparty-server']
}

setup(**setup_options)
