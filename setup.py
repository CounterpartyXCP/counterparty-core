#!/usr/bin/env python

from setuptools import setup, find_packages
import os
import zipfile
import urllib.request
import sys
import shutil
import logging

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
    'setup_requires': ['appdirs==1.4.0'],
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

if sys.argv[1] == 'install':
    # Move database from old to new default data directory
    import appdirs
    from counterpartylib.lib import config

    old_datadir = appdirs.user_config_dir(appauthor='Counterparty', appname='counterpartyd', roaming=True)
    old_database = os.path.join(old_datadir, 'counterpartyd.9.db')
    old_database_testnet = os.path.join(old_datadir, 'counterpartyd.9.testnet.db')

    new_datadir = appdirs.user_data_dir(appauthor=config.XCP_NAME, appname=config.XCP_NAME.lower(), roaming=True)
    new_database = os.path.join(new_datadir, '{}.{}.db'.format(config.XCP_NAME.lower(), config.VERSION_MAJOR))
    new_database_testnet = os.path.join(new_datadir, '{}.{}.testnet.db'.format(config.XCP_NAME.lower(), config.VERSION_MAJOR))

    # User have an old version of `counterpartyd`
    if os.path.exists(old_datadir):
        # Move database
        if not os.path.exists(new_datadir):
            os.makedirs(new_datadir)
            files_to_copy = {
                old_database: new_database,
                old_database_testnet: new_database_testnet
            }
            for src_file in files_to_copy:
                if os.path.exists(src_file):
                    dest_file = files_to_copy[src_file]
                    logging.warning('Copy {} to {}'.format(src_file, dest_file))
                    shutil.copy(src_file, dest_file)
