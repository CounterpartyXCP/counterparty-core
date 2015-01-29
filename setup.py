#!/usr/bin/env python
from setuptools.command.install import install as _install
from setuptools import setup, find_packages, Command
import os, sys
import shutil
import ctypes.util
import configparser, platform

from counterpartycli.server import CONFIG_ARGS as SERVER_CONFIG_ARGS
from counterpartycli.client import CONFIG_ARGS as CLIENT_CONFIG_ARGS
from counterpartycli.util import generate_config_file

CURRENT_VERSION = '1.0.0rc5'

def extract_old_config():
    import appdirs

    old_config = {}

    old_appdir = appdirs.user_config_dir(appauthor='Counterparty', appname='counterpartyd', roaming=True)
    old_configfile = os.path.join(old_appdir, 'counterpartyd.conf')

    if os.path.exists(old_configfile):
        configfile = configparser.ConfigParser()
        configfile.read(old_configfile)
        if 'Default' in configfile:
            for key in configfile['Default']:
                new_key = key.replace('backend-rpc-', 'backend-')
                new_key = new_key.replace('blockchain-service-name', 'backend-name')
                new_value = configfile['Default'][key].replace('jmcorgan', 'addrindex')
                old_config[new_key] = new_value

    return old_config

def extract_bitcoincore_config():
    bitcoincore_config = {}

    # Figure out the path to the bitcoin.conf file
    if platform.system() == 'Darwin':
        btc_conf_file = os.path.expanduser('~/Library/Application Support/Bitcoin/')
    elif platform.system() == 'Windows':
        btc_conf_file = os.path.join(os.environ['APPDATA'], 'Bitcoin')
    else:
        btc_conf_file = os.path.expanduser('~/.bitcoin')
    btc_conf_file = os.path.join(btc_conf_file, 'bitcoin.conf')

    # Extract contents of bitcoin.conf to build service_url
    if os.path.exists(btc_conf_file):
        conf = {}
        with open(btc_conf_file, 'r') as fd:
            # Bitcoin Core accepts empty rpcuser, not specified in btc_conf_file
            for line in fd.readlines():
                if '#' in line or '=' not in line:
                    continue
                k, v = line.split('=', 1)
                conf[k.strip()] = v.strip()

            config_keys = {
                'rpcport': 'backend-port',
                'rpcuser': 'backend-user',
                'rpcpassword': 'backend-password',
                'rpcssl': 'backend-ssl'
            }

            for bitcoind_key in config_keys:
                if bitcoind_key in conf:
                    counterparty_key = config_keys[bitcoind_key]
                    bitcoincore_config[counterparty_key] = conf[bitcoind_key]

    return bitcoincore_config

def get_server_known_config():
    server_known_config = {}

    bitcoincore_config = extract_bitcoincore_config()
    server_known_config.update(bitcoincore_config)

    old_config = extract_old_config()
    server_known_config.update(old_config)

    return server_known_config

# generate client config from server config
def server_to_client_config(server_config):
    client_config = {}

    config_keys = {
        'backend-connect': 'wallet-connect',
        'backend-port': 'wallet-port',
        'backend-user': 'wallet-user',
        'backend-password': 'wallet-password',
        'backend-ssl': 'wallet-ssl',
        'backend-ssl-verify': 'wallet-ssl-verify',
        'rpc-host': 'counterparty-rpc-connect',
        'rpc-port': 'counterparty-rpc-port',
        'rpc-user': 'counterparty-rpc-user',
        'rpc-password': 'counterparty-rpc-password'
    }

    for server_key in config_keys:
        if server_key in server_config:
            client_key = config_keys[server_key]
            client_config[client_key] = server_config[server_key]

    return client_config

class generate_configuration_files(Command):
    description = "Generate configfiles from old files or bitcoind config file"
    user_options = []

    def initialize_options(self):
        pass
    def finalize_options(self):
        pass

    def run(self):
        import appdirs
        from counterpartylib.lib import config, util

        configdir = appdirs.user_config_dir(appauthor=config.XCP_NAME, appname=config.APP_NAME, roaming=True)
        server_configfile = os.path.join(configdir, 'server.conf')
        client_configfile = os.path.join(configdir, 'client.conf')

        server_known_config = get_server_known_config()

        # generate random password
        if 'rpc-password' not in server_known_config:
            server_known_config['rpc-password'] = util.hexlify(util.dhash(os.urandom(16)))

        client_known_config = server_to_client_config(server_known_config)

        if not os.path.exists(server_configfile):
            generate_config_file(server_configfile, SERVER_CONFIG_ARGS, server_known_config)

        if not os.path.exists(client_configfile):
            generate_config_file(client_configfile, CLIENT_CONFIG_ARGS, client_known_config)

class install(_install):
    description = "Install counterparty-cli and dependencies"

    def run(self):
        _install.do_egg_install(self)
        self.run_command('generate_configuration_files')
        
required_packages = [
    'appdirs>=1.4.0',
    'prettytable>=0.7.2',
    'python-dateutil>=2.2',
    'requests>=2.3.0',
    'colorlog>=2.4.0',
    'counterparty-lib>=9.49.4rc1'
]

setup_options = {
    'name': 'counterparty-cli',
    'version': CURRENT_VERSION,
    'author': 'Counterparty Foundation',
    'author_email': 'support@counterparty.io',
    'maintainer': 'Adam Krellenstein',
    'maintainer_email': 'adamk@counterparty.io',
    'url': 'http://counterparty.io',
    'license': 'MIT',
    'description': 'Counterparty Protocol Command‐Line Interface',
    'long_description': '',
    'keywords': 'counterparty,bitcoin',
    'classifiers': [
        "Development Status :: 5 - Production/Stable",
        "Environment :: Console",
        "Intended Audience :: Developers",
        "Intended Audience :: End Users/Desktop",
        "Intended Audience :: Financial and Insurance Industry",
        "License :: OSI Approved :: MIT License",
        "Natural Language :: English",
        "Operating System :: Microsoft :: Windows",
        "Operating System :: POSIX",
        "Programming Language :: Python :: 3 :: Only",
        "Topic :: Office/Business :: Financial",
        "Topic :: System :: Distributed Computing"
    ],
    'download_url': 'https://github.com/CounterpartyXCP/counterparty-cli/releases/tag/v' + CURRENT_VERSION,
    'provides': ['counterpartycli'],
    'packages': find_packages(),
    'zip_safe': False,
    'install_requires': required_packages,
    'setup_requires': ['appdirs==1.4.0', 'counterparty-lib>=9.49.4rc1'],
    'entry_points': {
        'console_scripts': [
            'counterparty-client = counterpartycli:client_main',
            'counterparty-server = counterpartycli:server_main',
        ]
    },
    'cmdclass': {
        'install': install,
        'generate_configuration_files': generate_configuration_files
    }
}

if sys.argv[1] == 'py2exe':
    import py2exe
    WIN_DIST_DIR = 'counterparty-cli-win32-{}'.format(setup_options['version'])
    setup_options.update({
        'console': setup_options['scripts'],
        'zipfile': 'library/site-packages.zip',
        'options': {'py2exe': {'dist_dir': WIN_DIST_DIR}}
    })
    if os.path.exists(WIN_DIST_DIR):
        shutil.rmtree(WIN_DIST_DIR)

setup(**setup_options)


# tweak Windows distribution
if sys.argv[1] == 'py2exe':
    # py2exe copies only pyc files in site-packages.zip
    # modules with no pyc files must be copied in 'dist/library/'
    import counterpartylib, certifi
    additionals_modules = [counterpartylib, certifi]

    for module in additionals_modules:
        moudle_file = os.path.dirname(module.__file__)
        dest_file = '{}/library/{}'.format(WIN_DIST_DIR, module.__name__)
        shutil.copytree(moudle_file, dest_file)

    # additionals DLLs
    dlls = ['ssleay32.dll', 'libssl32.dll', 'libeay32.dll']
    dlls.append(ctypes.util.find_msvcrt())

    dlls_path = dlls
    for dll in dlls:
        dll_path = ctypes.util.find_library(dll)
        shutil.copy(dll_path, WIN_DIST_DIR)


