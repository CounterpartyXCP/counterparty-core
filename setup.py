#!/usr/bin/env python
from setuptools.command.install import install as _install
from setuptools.command.bdist_egg import bdist_egg as _bdist_egg
from setuptools import setup, find_packages, Command
import inspect
import ssl
import os
import zipfile
import urllib.request
import sys
import shutil

from counterpartylib.lib import config

CURRENT_VERSION = config.VERSION_STRING
APSW_VERSION = "3.8.7.3-r1"
APSW_SHORT_VERSION = APSW_VERSION.replace('-r1', '')

# NOTE: Why we don’t use the the PyPi package:
# <https://github.com/rogerbinns/apsw/issues/66#issuecomment-31310364>
class install_apsw(Command):
    description = "Install APSW %s with the appropriate version of SQLite" % APSW_VERSION
    user_options = []

    def initialize_options(self):
        pass
    def finalize_options(self):
        pass

    def run(self):
        # In Windows APSW should be installed manually
        if os.name == 'nt':
            print('To complete the installation you have to install APSW: https://github.com/rogerbinns/apsw/releases')
            return

        try:
            import apsw
            if apsw.apswversion() == APSW_VERSION:
                print('APSW %s already installed' % apsw.apswversion())
                return
            else:
                print('APSW %s already installed, need %s' % (apsw.apswversion(), APSW_VERSION))

        except:
            pass

        print("downloading apsw.")
        with urllib.request.urlopen('https://github.com/rogerbinns/apsw/releases/download/%s/apsw-%s.zip' % (APSW_VERSION, APSW_VERSION)) as u, \
                open('apsw-%s.zip' % APSW_VERSION, 'wb') as f:
            f.write(u.read())

        print("extracting.")
        with zipfile.ZipFile('apsw-%s.zip' % APSW_VERSION, 'r') as zip_file:
            zip_file.extractall()

        executable = sys.executable
        if executable is None:
            executable = "python"

        print("install apsw.")
        install_command = ('cd apsw-{version} && {executable} '
          'setup.py fetch --version={shortversion} --all build '
          '--enable-all-extensions install'.format(executable=executable, version=APSW_VERSION, shortversion=APSW_SHORT_VERSION)
        )
        os.system(install_command)

        print("clean files.")
        shutil.rmtree('apsw-%s' % APSW_VERSION)
        os.remove('apsw-%s.zip' % APSW_VERSION)


class install_serpent(Command):
    description = "Install Ethereum Serpent"
    user_options = _install.user_options + [
        ("global-install-serpent", None, "Install `serpent` in /usr/bin"),
    ]
    boolean_options = _install.boolean_options + ['global-install-serpent']

    def initialize_options(self):
        self.global_install_serpent = False
        self.clean = True
        pass

    def finalize_options(self):
        pass

    def run(self):
        repo = "rubensayshi"
        branch = "counterparty"

        # In Windows Serpent should be installed manually
        if os.name == 'nt':
            print('To complete the installation you have to install Serpent %s branch: https://github.com/%s/serpent/tree/%s' % (branch, repo, branch))
            return

        if not os.path.isdir("./serpent-%s" % branch):
            print("downloading serpent.")
            urllib.request.urlretrieve('https://github.com/%s/serpent/archive/%s.zip' % (repo, branch), 'serpent.zip')

            print("extracting.")
            with zipfile.ZipFile('serpent.zip', 'r') as zip_file:
                zip_file.extractall()

        print("making serpent.")
        os.system('cd serpent-%s && make' % branch)

        print("install serpent as python lib.")
        os.system('cd serpent-%s && python3 setup.py install' % branch)

        print("install serpent in `./bin`.")
        os.system('cp serpent-%s/serpent ./bin/serpent' % branch)

        if self.global_install_serpent:
            print("global install serpent using sudo.")
            print("hence it might request a password.")
            os.system('cd serpent-%s && sudo make install' % branch)

        if self.clean:
            print("clean files.")
            shutil.rmtree('serpent-%s' % branch)
        os.remove('serpent.zip')


class install_solc(_install):
    """
    http://www.ethdocs.org/en/latest/ethereum-clients/cpp-ethereum/building-from-source/linux-ubuntu.html
     - the LLVM part is not neccesary
     - the `sudo add-apt-repository -y ppa:ethereum/ethereum-qt` is not neccesary
        - but then you need to remove the following from the apt-get install:
          `qtbase5-dev qt5-default qtdeclarative5-dev libqt5webkit5-dev libqt5webengine5-dev`
     - if fails `sudo apt-get -y install libjson-rpc-cpp-dev` try `apt-get -y install libjsonrpccpp-dev`

    """

    description = "Install Ethereum Solidity"
    user_options = _install.user_options + [
        ("global-install-solc", None, "Install `solc` in /usr/bin"),
    ]
    boolean_options = _install.boolean_options + ['global-install-solc']

    def initialize_options(self):
        self.global_install_solc = False
        self.clean_and_cp = False
        self.clean = self.clean_and_cp and False
        _install.initialize_options(self)

    def finalize_options(self):
        pass

    def run(self):
        import json

        # In Windows Solidity should be installed manually
        if os.name == 'nt':
            print('Windows requires manual install, good luck ... @TODO')  # @TODO
            return

        WEBTHREE_REPO = "ethereum"
        WEBTHREE_REPO_URL = "git://github.com/%s/webthree-umbrella.git" % WEBTHREE_REPO
        WEBTHREE_BRANCH = "v1.2.6"

        SOLIDITY_REPO = "rubensayshi"
        SOLIDITY_REPO_URL = "git://github.com/%s/solidity.git" % SOLIDITY_REPO
        SOLIDITY_BRANCH = "counterparty"

        PARAMS = dict(
            WEBTHREE_REPO=WEBTHREE_REPO,
            WEBTHREE_REPO_URL=WEBTHREE_REPO_URL,
            WEBTHREE_BRANCH=WEBTHREE_BRANCH,
            SOLIDITY_REPO=SOLIDITY_REPO,
            SOLIDITY_REPO_URL=SOLIDITY_REPO_URL,
            SOLIDITY_BRANCH=SOLIDITY_BRANCH,
        )

        with urllib.request.urlopen('https://api.github.com/repos/{SOLIDITY_REPO}/solidity/branches/{SOLIDITY_BRANCH}'.format(**PARAMS)) as u:
            data = json.loads(u.read().decode('utf-8'))
            commit = data['commit']['sha']

        WEBTHREE_DIR = "./webthree-umbrella-%s-%s" % (WEBTHREE_BRANCH, commit)

        PARAMS.update(dict(
            WEBTHREE_DIR=WEBTHREE_DIR
        ))

        if not os.path.isdir("{WEBTHREE_DIR}/solidity".format(**PARAMS)):
            print("downloading webthree-umbrella into {WEBTHREE_DIR}.".format(**PARAMS))
            os.system("rm -rf {WEBTHREE_DIR}".format(**PARAMS))
            print('git clone --recursive --branch {WEBTHREE_BRANCH} {WEBTHREE_REPO_URL} {WEBTHREE_DIR}'.format(**PARAMS))
            os.system('git clone --recursive --branch {WEBTHREE_BRANCH} {WEBTHREE_REPO_URL} {WEBTHREE_DIR}'.format(**PARAMS))

            os.system('cd {WEBTHREE_DIR}/solidity && '
                      'git remote add counterparty {SOLIDITY_REPO_URL}'.format(**PARAMS))

            os.system('cd {WEBTHREE_DIR}/solidity && '
                      'git fetch counterparty && '
                      'git checkout -f {SOLIDITY_BRANCH} &&'
                      'git reset --hard counterparty/{SOLIDITY_BRANCH}'.format(**PARAMS))

            print("building.")
            os.system('cd {WEBTHREE_DIR} && ./webthree-helpers/scripts/ethbuild.sh --no-git --project solidity --cores 4 -DEVMJIT=0 -DETHASHCL=0 -DGUI=0'.format(**PARAMS))

        if self.clean_and_cp:
            print("copying to ./bin")
            os.system('cp {WEBTHREE_DIR}/solidity/build/solc/solc ./bin/solc'.format(**PARAMS))

            if self.global_install_solc:
                print("copying to /usr/bin")
                os.system('sudo cp {WEBTHREE_DIR}/solidity/build/solc/solc /usr/bin/solc'.format(**PARAMS))

            if self.clean:
                print("clean files.")
                shutil.rmtree('{WEBTRHEE_DIR}'.format(**PARAMS))
        else:
            print("symlinking to ./bin")
            os.system('rm ./bin/solc')
            os.system('ln -s `pwd`/{WEBTHREE_DIR}/solidity/build/solc/solc ./bin/solc'.format(**PARAMS))

            if self.global_install_solc:
                print("symlinking to /usr/bin")
                os.system('sudo rm /usr/bin/solc')
                os.system('sudo ln -s `pwd`/{WEBTHREE_DIR}/solidity/build/solc/solc /usr/bin/solc'.format(**PARAMS))


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


def post_install(cmd, install_serpent=False, install_solc=False):
    cmd.run_command('install_apsw')
    if install_serpent:
        cmd.run_command('install_serpent')
    if install_solc:
        cmd.run_command('install_solc')
    cmd.run_command('move_old_db')


class install(_install):
    user_options = _install.user_options + [
        ("with-serpent", None, "Install Ethereum Serpent"),
        ("with-solc", None, "Install Ethereum Solc"),
    ]
    boolean_options = _install.boolean_options + ['with-serpent', 'with-solc']

    def initialize_options(self):
        self.with_serpent = False
        self.with_solc = False
        _install.initialize_options(self)

    #Some of this code taken from https://bitbucket.org/pypa/setuptools/src/4ce518784af886e6977fa2dbe58359d0fe161d0d/setuptools/command/install.py?at=default&fileviewer=file-view-default
    @staticmethod
    def _called_from_setup(run_frame):
        """
        Attempt to detect whether run() was called from setup() or by another
        command.  If called by setup(), the parent caller will be the
        'run_command' method in 'distutils.dist', and *its* caller will be
        the 'run_commands' method.  If called any other way, the
        immediate caller *might* be 'run_command', but it won't have been
        called by 'run_commands'. Return True in that case or if a call stack
        is unavailable. Return False otherwise.
        """
        if run_frame is None:
            msg = "Call stack not available. bdist_* commands may fail."
            warnings.warn(msg)
            if platform.python_implementation() == 'IronPython':
                msg = "For best results, pass -X:Frames to enable call stack."
                warnings.warn(msg)
            return True
        res = inspect.getouterframes(run_frame)[2]
        caller, = res[:1]
        info = inspect.getframeinfo(caller)
        caller_module = caller.f_globals.get('__name__', '')
        return (
            caller_module == 'distutils.dist'
            and info.function == 'run_commands'
        )
        
    def run(self):
        try:
            import zlib
        except:
            assert 0, "Python must be build with zlib"

        # Explicit request for old-style install?  Just do it
        if self.old_and_unmanageable or self.single_version_externally_managed:
            _install.run(self)
            self.execute(post_install, (self, False), msg="Running post install tasks")
            return

        if not self._called_from_setup(inspect.currentframe()):
            # Run in backward-compatibility mode to support bdist_* commands.
            _install.run(self)
        else:
            self.do_egg_install()
        self.execute(post_install, (self, self.with_serpent, self.with_solc), msg="Running post install tasks")

class bdist_egg(_bdist_egg):
    def run(self):
        _bdist_egg.run(self)
        self.execute(post_install, (self, False), msg="Running post install tasks")

required_packages = [
    'python-dateutil==2.5.3',
    'Flask-HTTPAuth==3.1.2',
    'Flask==0.11',
    'appdirs==1.4.0',
    'colorlog==2.7.0',
    'json-rpc==1.10.3',
    'pycoin==0.62',
    'pycrypto==2.6.1',
    'pysha3==0.3',
    'pytest==2.9.1',
    'pytest-cov==2.2.1',
    'python-bitcoinlib==0.5.1',
    'requests==2.10.0',
    'tendo==0.2.8',
    'xmltodict==0.10.1',
    'cachetools==1.1.6',
    'rlp==0.4.4',
    'pyyaml'
]

setup_options = {
    'name': 'counterparty-lib',
    'version': CURRENT_VERSION,
    'author': 'Counterparty Developers',
    'author_email': 'dev@counterparty.io',
    'maintainer': 'Counterparty Developers',
    'maintainer_email': 'dev@counterparty.io',
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
        'install_serpent': install_serpent,
        'install_solc': install_solc
    }
}

if sys.argv[1] == 'sdist':
    setup_options['long_description_markdown_filename'] = 'README.md'
    setup_options['setup_requires'].append('setuptools-markdown')

setup(**setup_options)
