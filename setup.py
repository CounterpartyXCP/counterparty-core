#!/usr/bin/env python
from setuptools.command.install import install as _install
from setuptools import setup, find_packages, Command
import os, sys
import shutil
import ctypes.util
import configparser, platform
from counterpartycli import APP_VERSION

class generate_configuration_files(Command):
    description = "Generate configfiles from old files or bitcoind config file"
    user_options = []

    def initialize_options(self):
        pass
    def finalize_options(self):
        pass

    def run(self):
        from counterpartycli.setup import generate_config_files
        generate_config_files()

class install(_install):
    description = "Install counterparty-cli and dependencies"

    def run(self):
        _install.do_egg_install(self)
        self.run_command('generate_configuration_files')
        
required_packages = [
    'appdirs>=1.4.0',
    'prettytable>=0.7.2',
    'colorlog>=2.4.0',
    'python-dateutil>=2.2',
    'requests>=2.3.0',
    'counterparty-lib>=9.50.0'
]

setup_options = {
    'name': 'counterparty-cli',
    'version': APP_VERSION,
    'author': 'Counterparty Foundation',
    'author_email': 'support@counterparty.io',
    'maintainer': 'Adam Krellenstein',
    'maintainer_email': 'adamk@counterparty.io',
    'url': 'http://counterparty.io',
    'license': 'MIT',
    'description': 'Counterparty Protocol Command-Line Interface',
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
    'download_url': 'https://github.com/CounterpartyXCP/counterparty-cli/releases/tag/v' + APP_VERSION,
    'provides': ['counterpartycli'],
    'packages': find_packages(),
    'zip_safe': False,
    'install_requires': required_packages,
    'setup_requires': required_packages,
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
    from py2exe.distutils_buildexe import py2exe as _py2exe

    WIN_DIST_DIR = 'counterparty-cli-win32-{}'.format(APP_VERSION)
    
    class py2exe(_py2exe):
        def run(self):
            from counterpartycli.setup import before_py2exe_build, after_py2exe_build
            # prepare build
            before_py2exe_build(WIN_DIST_DIR)
            # build exe's
            _py2exe.run(self)
            # tweak build
            after_py2exe_build(WIN_DIST_DIR)

    # Update setup_options with py2exe specifics options
    setup_options.update({
        'console': [
            'counterparty-client.py',
            'counterparty-server.py'
        ],
        'zipfile': 'library/site-packages.zip',
        'options': {
            'py2exe': {
                'dist_dir': WIN_DIST_DIR
            }
        },
        'cmdclass': {
            'py2exe': py2exe
        }
    })

setup(**setup_options)
