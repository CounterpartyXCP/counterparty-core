#!/usr/bin/env python

from setuptools import setup, find_packages
import os
import zipfile
import urllib

def install_apsw():
    try:
        import apsw
        return
    except:
        pass

    print("downloading apsw.")
    urllib.request.urlretrieve('https://github.com/rogerbinns/apsw/releases/download/3.8.5-r1/apsw-3.8.5-r1.zip', 'apsw-3.8.5-r1.zip')

    print("extracting.")
    with zipfile.ZipFile('apsw-3.8.5-r1.zip', 'r') as zip_file:
        zip_file.extractall()

    print("install apsw.")
    os.system('cd apsw-3.8.5-r1 && python setup.py fetch --version=3.8.5 --all build --enable-all-extensions install')

    print("clean files.")
    os.system('rm -rf apsw-3.8.5-r1 && rm apsw-3.8.5-r1.zip')

def install_serpent():
    print("downloading serpent.")
    urllib.request.urlretrieve('https://github.com/ethereum/serpent/archive/master.zip', 'serpent.zip')

    print("extracting.")
    with zipfile.ZipFile('serpent.zip', 'r') as zip_file:
        zip_file.extractall()

    print("install serpent.")
    os.system('cd serpent-master && make && sudo make install')

    print("clean files.")
    os.system('rm -rf serpent-master && rm serpent.zip')

def readme():
    here = os.path.abspath(os.path.dirname(__file__))
    with open(os.path.join(here, 'README.md')) as f:
        return f.read()

required_packages = [
    'appdirs==1.4.0',
    'prettytable==0.7.2',
    'python-dateutil==2.2',
    'flask==0.10.1',
    'json-rpc==1.7',
    'pytest==2.6.3',
    'pycoin==0.52',
    'requests==2.4.2',
    'Flask-HTTPAuth==2.3.0',
    'tornado==4.0.2',
    'pycrypto>=2.6.1',
    'tendo==0.2.6',
    'pysha3==0.3',
    'pytest-cov==1.8.0',
    'colorlog==2.4.0',
    'python-bitcoinlib==0.3.0'
]

required_repos = [
    'https://github.com/petertodd/python-bitcoinlib/archive/python-bitcoinlib-v0.3.0.tar.gz#egg=python-bitcoinlib-0.3.0'
]

setup_options = {
    'name': 'counterparty-lib',
    'version': '9.49.3',
    'description': 'Reference implementation of the Counterparty protocol.',
    'long_description': readme(),
    'classifiers': [
      "Programming Language :: Python",
    ],
    'url': 'https://github.com/CounterpartyXCP/counterpartyd',
    'keywords': 'counterparty, bitcoin',
    'packages': find_packages(),
    'zip_safe': False,
    'dependency_links': required_repos,
    'install_requires': required_packages,
    'include_package_data': True
}

install_serpent()
install_apsw()
setup(**setup_options)
