#!/usr/bin/env python
from setuptools.command.install import install as _install
from setuptools import setup, find_packages, Command
import os, sys
import shutil
import ctypes.util


CURRENT_VERSION = '1.0.0rc4'

class generate_configuration_files(Command):
    description = "Generate configfiles from old files or bitcoind config file"
    user_options = []

    def initialize_options(self):
        pass
    def finalize_options(self):
        pass

    def run(self):
        import appdirs, configparser, platform
        from counterpartylib.lib import config, util
        import counterpartycli.server
        import counterpartycli.client

        old_appdir = appdirs.user_config_dir(appauthor='Counterparty', appname='counterpartyd', roaming=True)
        old_configfile = os.path.join(old_appdir, 'counterpartyd.conf')

        new_server_configdir = appdirs.user_config_dir(appauthor=config.XCP_NAME, appname='counterparty-server', roaming=True)
        new_client_configdir = appdirs.user_config_dir(appauthor=config.XCP_NAME, appname='counterparty-client', roaming=True)

        new_server_configfile = os.path.join(new_server_configdir, 'server.conf')
        new_client_configfile = os.path.join(new_client_configdir, 'client.conf')

        # User have an old version of `counterpartyd`
        if os.path.exists(old_appdir):

            # Move configuration files
            if not os.path.exists(new_server_configdir):
                os.makedirs(new_server_configdir)
                if os.path.exists(old_configfile):
                    shutil.copy(old_configfile, new_server_configfile)
                # Replace `backend-rpc-*` by `backend-*`
                if os.path.exists(new_server_configfile):
                    with open(new_server_configfile, 'r') as f:
                        new_config = ("").join(f.readlines())
                    new_config = new_config.replace('backend-rpc-', 'backend-')
                    new_config = new_config.replace('blockchain-service-name', 'backend-name')
                    new_config = new_config.replace('jmcorgan', 'addrindex')
                    with open(new_server_configfile, 'w+') as f:
                        f.writelines(new_config)

        # Still not have a `counterparty-server` configuration file
        if not os.path.exists(new_server_configfile):
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
                with open(btc_conf_file, 'r') as fd:

                    server_configfile = configparser.ConfigParser()
                    server_configfile['Default'] = {}

                    # Bitcoin Core accepts empty rpcuser, not specified in btc_conf_file
                    conf = {}
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
                            server_configfile['Default'][counterparty_key] = conf[bitcoind_key]

                    server_configfile['Default']['rpc-password'] = util.hexlify(util.dhash(os.urandom(16)))
                    if not os.path.exists(new_server_configdir):
                        os.makedirs(new_server_configdir)
                    with open(new_server_configfile, 'w+') as fw:
                        server_configfile.write(fw)

        # Still not have a `counterparty-server` configuration file
        if not os.path.exists(new_server_configfile):
            server_configfile = configparser.ConfigParser()
            server_configfile['Default'] = {}
            # generate a password
            server_configfile['Default']['rpc-password'] = util.hexlify(util.dhash(os.urandom(16)))
            if not os.path.exists(new_server_configdir):
                os.makedirs(new_server_configdir)
            with open(new_server_configfile, 'w+') as fw:
                server_configfile.write(fw)

        # User don't have a `counterparty-client` data_dir
        if not os.path.exists(new_client_configfile):
            # generate a configuration file from `counterparty-server.conf`
            server_configfile = configparser.ConfigParser()
            server_configfile.read(new_server_configfile)

            client_configfile = configparser.ConfigParser()
            client_configfile['Default'] = {}
            #
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
                if server_key in server_configfile['Default']:
                    client_key = config_keys[server_key]
                    client_configfile['Default'][client_key] = server_configfile['Default'][server_key]

            if not os.path.exists(new_client_configdir):
                os.makedirs(new_client_configdir)
            with open(new_client_configfile, 'w+') as fw:
                client_configfile.write(fw)

class install(_install):
    description = "Install counterparty-cli and dependencies"

    def run(self):
        _install.do_egg_install(self)
        self.run_command('generate_configuration_files')
        
required_packages = [
    'appdirs==1.4.0',
    'prettytable==0.7.2',
    'python-dateutil==2.2',
    'requests==2.4.2',
    'colorlog==2.4.0',
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


