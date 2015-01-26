#!/usr/bin/env python

from setuptools import setup, find_packages
import os
import zipfile
import urllib.request
import sys
import shutil
import logging

CURRENT_VERSION = '9.49.4rc3'

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
    shutil.rmtree('apsw-3.8.7.3-r1')
    os.remove('apsw-3.8.7.3-r1.zip')

def install_serpent():
    print("downloading serpent.")
    urllib.request.urlretrieve('https://github.com/ethereum/serpent/archive/master.zip', 'serpent.zip')

    print("extracting.")
    with zipfile.ZipFile('serpent.zip', 'r') as zip_file:
        zip_file.extractall()

    print("making serpent.")
    os.system('cd serpent-master && make')
    print("install serpent using sudo.")
    print("hence it might request a password.")
    os.system('cd serpent-master && sudo make install')

    print("clean files.")
    shutil.rmtree('serpent-master')
    os.remove('serpent.zip')

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
    'python-bitcoinlib==0.2.1'
]

setup_options = {
    'name': 'counterparty-lib',
    'version': CURRENT_VERSION,
    'author': 'Counterparty Foundation',
    'author_email': 'support@counterparty.io',
    'maintainer': 'Adam Krellenstein',
    'maintainer_email': 'adamk@counterparty.io',
    'url': 'http://counterparty.io',
    'license': 'MIT',
    'description': 'Counterparty Protocol Reference Implementation',
    'long_description': '',
    'keywords': 'counterparty, bitcoin',
    'classifiers': [
      "Programming Language :: Python",
    ],
    'download_url': 'https://github.com/CounterpartyXCP/counterpartyd/releases/tag/v' + CURRENT_VERSION,
    'provides': ['counterpartylib'],
    'packages': find_packages(),
    'zip_safe': False,
    'install_requires': required_packages,
    'include_package_data': True
}

setup(**setup_options)

# In Windows APSW and Serpent should be installed manually
if os.name != 'nt':
    install_apsw()
    install_serpent()
else:
    logging.warning('''Warning:
To complete the installation you have to install:
- APSW: https://github.com/rogerbinns/apsw/releases
- Serpent: https://github.com/ethereum/serpent''')
