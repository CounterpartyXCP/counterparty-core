#!/usr/bin/env python

from setuptools import setup, find_packages
import os, sys
import counterpartylib, certifi
import shutil
import ctypes.util

if sys.argv[1] == 'py2exe':
    import py2exe

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
    'author': 'Counterparty Foundation',
    'author_email': 'support@counterparty.io',
    'maintainer': 'Adam Krellenstein',
    'maintainer_email': 'adamk@counterparty.io',
    'url': 'http://counterparty.io',
    'license': 'MIT',
    'description': 'Counterparty CLI',
    'long_description': '',
    'keywords': 'counterparty,bitcoin',
    'classifiers': [
      "Programming Language :: Python",
    ],
    'download_url': 'https://github.com/CounterpartyXCP/counterparty-cli/releases/tag/v1.0.0-RC2',
    'provides': ['counterpartycli'],
    'packages': find_packages(),
    'zip_safe': False,
    'dependency_links': required_repos,
    'install_requires': required_packages,
    'scripts': ['bin/counterparty-client', 'bin/counterparty-server']
}


if sys.argv[1] == 'py2exe':
    WIN_DIST_DIR = 'counterparty-cli-win32-{}'.format(setup_options['version'])
    setup_options.update({
        'console': setup_options['scripts'],
        'zipfile': 'library/site-packages.zip',
        'options': {'py2exe': {'dist_dir': WIN_DIST_DIR}}
    })
    shutil.rmtree(WIN_DIST_DIR)

setup(**setup_options)

# tweak Windows distribution
if sys.argv[1] == 'py2exe':
    # py2exe copies only pyc files in site-packages.zip
    # modules with no pyc files must be copied in 'dist/library/'
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
