#!/usr/bin/env python
from setuptools.command.install import install as _install
from setuptools.command.bdist_egg import bdist_egg as _bdist_egg
from setuptools import setup, find_packages, Command
import os
import zipfile
import urllib.request
import sys
import shutil

from counterpartylib.lib import config

CURRENT_VERSION = config.VERSION_STRING

# NOTE: Why we don’t use the the PyPi package:
# <https://code.google.com/p/apsw/source/detail?r=358a9623d051>
class install_apsw(Command):
    description = "Install APSW 3.8.7.3-r1 with the appropriate version of SQLite"
    user_options = []

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
    description = "Install Ethereum Serpent"
    user_options = []

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
    description = "Move database from old to new default data directory"
    user_options = []

    def initialize_options(self):
        pass
    def finalize_options(self):
        pass

    def run(self):
        import appdirs

        old_data_dir = appdirs.user_config_dir(appauthor='Counterparty', appname='counterpartyd', roaming=True)
        old_database = os.path.join(old_data_dir, 'counterpartyd.9.db')
        old_database_testnet = os.path.join(old_data_dir, 'counterpartyd.9.testnet.db')

        new_data_dir = appdirs.user_data_dir(appauthor=config.XCP_NAME, appname=config.APP_NAME, roaming=True)
        new_database = os.path.join(new_data_dir, '{}.db'.format(config.APP_NAME))
        new_database_testnet = os.path.join(new_data_dir, '{}.testnet.db'.format(config.APP_NAME))

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

def post_install(cmd, install_serpent=False):
    cmd.run_command('install_apsw')
    if install_serpent:
        cmd.run_command('install_serpent')
    cmd.run_command('move_old_db')

class install(_install):
    user_options = _install.user_options + [
        ("with-serpent", None, "Install Ethereum Serpent"),
    ]
    boolean_options = _install.boolean_options + ['with-serpent']

    def initialize_options(self):
        self.with_serpent = False
        _install.initialize_options(self)

    def run(self):
        caller = sys._getframe(2)
        caller_module = caller.f_globals.get('__name__','')
        caller_name = caller.f_code.co_name
        if caller_module == 'distutils.dist' or caller_name == 'run_commands':
            _install.run(self)
        else:
            self.do_egg_install()
        post_install(self, self.with_serpent)

class bdist_egg(_bdist_egg):
    def run(self):
        _bdist_egg.run(self)
        post_install(self, False)

required_packages = [
    'appdirs',
    'python-dateutil',
    'Flask-HTTPAuth',
    'Flask',
    'json-rpc',
    'pytest',
    'pytest-cov',
    'pycoin',
    'requests',
    'pycrypto',
    'tendo',
    'pysha3',
    'colorlog',
    'python-bitcoinlib',
    'xmltodict'
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
    'keywords': 'counterparty, bitcoin',
    'classifiers': [
        "Development Status :: 5 - Production/Stable",
        "Intended Audience :: Developers",
        "Intended Audience :: Financial and Insurance Industry",
        "License :: OSI Approved :: MIT License",
        "Natural Language :: English",
        "Operating System :: Microsoft :: Windows",
        "Operating System :: POSIX",
        "Programming Language :: Python :: 3 :: Only ",
        "Topic :: Office/Business :: Financial",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "Topic :: System :: Distributed Computing"
    ],
    'download_url': 'https://github.com/CounterpartyXCP/counterparty-lib/releases/tag/v' + CURRENT_VERSION,
    'provides': ['counterpartylib'],
    'packages': find_packages(),
    'zip_safe': False,
    'setup_requires': ['appdirs'],
    'install_requires': required_packages,
    'include_package_data': True,
    'cmdclass': {
        'install': install,
        'move_old_db': move_old_db,
        'install_apsw': install_apsw,
        'install_serpent': install_serpent
    }
}

if sys.argv[1] == 'sdist':
    setup_options['long_description_markdown_filename'] = 'README.md'
    setup_options['setup_requires'].append('setuptools-markdown')

setup(**setup_options)
