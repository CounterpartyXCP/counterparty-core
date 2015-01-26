#!/usr/bin/env python
from setuptools.command.install import install as _install
from setuptools import setup, find_packages, Command
import os
import zipfile, tarfile
import urllib.request
import sys
import shutil

CURRENT_VERSION = '9.49.4rc4'

# NOTE: Why we don’t use the the PyPi package (https://pypi.python.org/pypi/apsw/3.8.5-r1)
"""PLEASE NOTE Unfortunately a version of apsw will generally only work with a
specific version of SQLite. There are no provisions to detect SQLite version
and expose an appropriate API. Be mindful of the version of SQLite you have
installed. Also be mindful of updates to apsw. If you need a specific version
of apsw or need to build against a specific version of SQLite then please
follow these instuctions ->
http://rogerbinns.github.io/apsw/build.html#recommended"""
class install_apsw(Command):
    description="Install APSW 3.8.7.3-r1 with the appropriate version of SQLite"
    user_options=[]

    def initialize_options(self):
        pass
    def finalize_options(self):
        pass

    def run(self):
        # In Windows APSW should be installed manually
        if os.name == 'nt':
            print('To complete the installation you have to install APSW: https://github.com/rogerbinns/apsw/releases');
            return

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

class install_serpent(Command):
    description="Install Ethereum Serpent"
    user_options=[]

    def initialize_options(self):
        pass
    def finalize_options(self):
        pass

    def run(self):
        # In Windows Serpent should be installed manually
        if os.name == 'nt':
            print('To complete the installation you have to install Serpent: https://github.com/ethereum/serpent');
            return

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

class move_old_db(Command):
    description="Move database from old to new default data directory"
    user_options=[]

    def initialize_options(self):
        pass
    def finalize_options(self):
        pass

    def run(self):
        import appdirs
        from counterpartylib.lib import config

        old_data_dir = appdirs.user_config_dir(appauthor='Counterparty', appname='counterpartyd', roaming=True)
        old_database = os.path.join(old_data_dir, 'counterpartyd.9.db')
        old_database_testnet = os.path.join(old_data_dir, 'counterpartyd.9.testnet.db')

        new_data_dir = appdirs.user_data_dir(appauthor=config.XCP_NAME, appname=config.XCP_NAME.lower(), roaming=True)
        new_database = os.path.join(new_data_dir, '{}.{}.db'.format(config.XCP_NAME.lower(), config.VERSION_MAJOR))
        new_database_testnet = os.path.join(new_data_dir, '{}.{}.testnet.db'.format(config.XCP_NAME.lower(), config.VERSION_MAJOR))

        # User have an old version of `counterpartyd`
        if os.path.exists(old_data_dir):
            # Move database
            if not os.path.exists(new_data_dir):
                os.makedirs(new_data_dir)
                files_to_copy = {
                    old_database: new_database,
                    old_database_testnet: new_database_testnet
                }
                for src_file in files_to_copy:
                    if os.path.exists(src_file):
                        dest_file = files_to_copy[src_file]
                        print('Copy {} to {}'.format(src_file, dest_file))
                        shutil.copy(src_file, dest_file)

class download_bootstrap_db(Command):    
    description="Download bootstrap database"
    user_options=[
        ("yes", None, "Download bootstrap database"),
        ("no", None, "Don't download bootstrap database"),
        ("ask", None, "Ask to download bootstrap database")
    ]
    boolean_options=['yes', 'no', 'ask']

    def initialize_options(self):
        self.yes = False
        self.no = False
        self.ask = True

    def finalize_options(self):
        if self.yes or self.no:
            self.ask = False

    def download(self):
        import appdirs
        from counterpartylib.lib import config

        data_dir = appdirs.user_data_dir(appauthor=config.XCP_NAME, appname=config.XCP_NAME.lower(), roaming=True)
        database = os.path.join(data_dir, '{}.{}.db'.format(config.XCP_NAME.lower(), config.VERSION_MAJOR))
        database_testnet = os.path.join(data_dir, '{}.{}.testnet.db'.format(config.XCP_NAME.lower(), config.VERSION_MAJOR))

        if not os.path.exists(data_dir):
            os.makedirs(data_dir)

        print("downloading mainnet database.")
        urllib.request.urlretrieve('https://s3.amazonaws.com/counterparty-bootstrap/counterpartyd-db.latest.tar.gz', 'counterpartyd-db.latest.tar.gz')
        print("extracting.")
        with tarfile.open('counterpartyd-db.latest.tar.gz', 'r:gz') as tar_file:
            tar_file.extractall()
        print('Copy {} to {}'.format('counterpartyd.9.db', database))
        shutil.copy('counterpartyd.9.db', database)

        print("downloading testnet database.")
        urllib.request.urlretrieve('https://s3.amazonaws.com/counterparty-bootstrap/counterpartyd-testnet-db.latest.tar.gz', 'counterpartyd-testnet-db.latest.tar.gz')
        print("extracting.")
        with tarfile.open('counterpartyd-testnet-db.latest.tar.gz', 'r:gz') as tar_file:
            tar_file.extractall()
        print('Copy {} to {}'.format('counterpartyd.9.testnet.db', database))
        shutil.copy('counterpartyd.9.testnet.db', database)

    def run(self):
        if self.yes:
            self.download()
        elif self.ask:
            if input('Do you want to download the Counterparty database from https://s3.amazonaws.com/counterparty-bootstrap/? (y/N) : ').lower() == 'y':
                self.download()
             
class install(_install):
    def run(self):
        _install.do_egg_install(self)
        self.run_command('install_apsw')
        self.run_command('install_serpent')
        self.run_command('download_bootstrap_db')
        self.run_command('move_old_db')

required_packages = [
    'appdirs==1.4.0',
    'prettytable==0.7.2',
    'python-dateutil==2.2',
    'flask==0.10.1',
    'json-rpc==1.7',
    'pytest==2.6.4',
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
    'setup_requires': ['appdirs==1.4.0'],
    'install_requires': required_packages,
    'include_package_data': True,
    'cmdclass': {
        'install': install,
        'download_bootstrap_db': download_bootstrap_db,
        'move_old_db': move_old_db,
        'install_apsw': install_apsw,
        'install_serpent': install_serpent
    }
}

setup(**setup_options)
