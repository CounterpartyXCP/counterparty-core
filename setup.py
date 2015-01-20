#!/usr/bin/env python

from setuptools import setup, find_packages
import os
import zipfile
import urllib.request
import sys

def install_apsw():
    try:
        import apsw
        return
    except:
        pass

    print("downloading apsw.")
    urllib.request.urlretrieve('https://github.com/rogerbinns/apsw/archive/3.8.7.3-r1.zip', 'apsw-3.8.7.3-r1.zip')

    print("extracting.")
    with zipfile.ZipFile('apsw-3.8.7.3-r1.zip', 'r') as zip_file:
        zip_file.extractall()

    executable = sys.executable
    if executable is None:
        executable = "python"

    print("install apsw.")
    install_command = ('cd apsw-3.8.7.3-r1 && {executable} '
      'setup.py fetch --version=3.8.7.3 --all build '
      '--enable-all-extensions install'.format(executable=executable)
    )
    os.system(install_command)

    print("clean files.")
    os.system('rm -rf apsw-3.8.7.3-r1 && rm apsw-3.8.7.3-r1.zip')

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
    'https://github.com/petertodd/python-bitcoinlib/archive/c481254c623cc9a002187dc23263cce3e05f5754.zip#egg=python-bitcoinlib-0.3.0'
]

setup_options = {
    'name': 'counterparty-lib',
    'version': '9.49.3',
    'author': 'Counterparty Foundation',
    'author_email': 'support@counterparty.io',
    'maintainer': 'Adam Krellenstein',
    'maintainer_email': 'adamk@counterparty.io',
    'url': 'http://counterparty.io',
    'license': 'MIT',
    'description': 'Reference implementation of the Counterparty protocol',
    'long_description': '',
    'keywords': 'counterparty, bitcoin',
    'classifiers': [
      "Programming Language :: Python",
    ],
    'download_url': 'https://github.com/CounterpartyXCP/counterpartyd/releases/tag/v9.49.3',
    'provides': ['counterpartylib'],
    'packages': find_packages(),
    'zip_safe': False,
    'dependency_links': required_repos,
    'install_requires': required_packages,
    'include_package_data': True
}

install_serpent()
install_apsw()
setup(**setup_options)
