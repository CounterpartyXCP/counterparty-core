import re
import subprocess
import os

import binascii
import yaml  # use yaml instead of json to get non unicode

from counterpartylib.lib.evm import ethutils

ROOTDIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
BINDIR = os.path.abspath(os.path.join(ROOTDIR, "bin"))
SOLCBIN = os.path.abspath(os.path.join(BINDIR, "solc"))

COMPILER_VERSION = None


class CompileError(Exception):
    pass


def remove_comments(string):
            string = re.sub(re.compile("/\*.*?\*/",re.DOTALL ) ,"" ,string) # remove all occurance streamed comments (/*COMMENT */) from string
            string = re.sub(re.compile("//.*?\n" ) ,"" ,string) # remove all occurance singleline comments (//COMMENT\n ) from string
            return string


class solc_wrapper(object):

    "wraps solc binary"

    @classmethod
    def compiler_available(cls):
        program = 'solc'

        def is_exe(fpath):
            return os.path.isfile(fpath) and os.access(fpath, os.X_OK)

        fpath, fname = os.path.split(program)
        if fpath:
            if is_exe(program):
                return program
        else:
            for path in os.environ["PATH"].split(os.pathsep):
                path = path.strip('"')
                exe_file = os.path.join(path, program)
                if is_exe(exe_file):
                    return exe_file

        return None

    @classmethod
    def contract_names(cls, code):
        """ Return the library and contract names in order of appearence. """
        names = []
        cleancode = remove_comments(code)

        for m in re.findall(r'^\s*?(contract|library)\s+?(\S*?)\s+?', cleancode, re.MULTILINE):
            names.append((m[0], m[1]))

        return names

    @classmethod
    def compile(cls, code, path=None, libraries=None, contract_name=''):
        "returns binary of last contract in code"
        sorted_contracts = cls.combined(code, path=path)

        if contract_name:
            idx = [x[0] for x in sorted_contracts].index(contract_name)
        else:
            idx = -1

        if libraries:
            if cls.compiler_version() < "0.1.2":
                raise CompileError('Compiler does not support libraries. Please update compiler.')
            for lib_name, lib_address in libraries.items():
                sorted_contracts[idx][1]['bin'] = sorted_contracts[idx][1]['bin']\
                    .replace("__{}{}".format(lib_name, "_" * (38 - len(lib_name))), lib_address.hexstr())

        return binascii.unhexlify(sorted_contracts[idx][1]['bin'])

    @classmethod
    def mk_full_signature(cls, code, path=None, libraries=None, contract_name='', optimize=True):
        "returns signature of last contract in code"
        sorted_contracts = cls.combined(code, path=path, optimize=optimize)
        if contract_name:
            idx = [x[0] for x in sorted_contracts].index(contract_name)
        else:
            idx = -1
        return sorted_contracts[idx][1]['abi']

    @classmethod
    def combined(cls, code, path=None, optimize=True):
        """compile combined-json with abi,bin,devdoc,userdoc
        @param code: literal solidity code as a string.
        @param path: absolute path to solidity-file. Note: code & path are exclusive!
        """

        if path is None:
            p = subprocess.Popen([SOLCBIN, '--add-std', '--optimize' if optimize else '', '--combined-json', 'abi,bin,devdoc,userdoc,structs,statevars', './=/work/counterparty-lib/', '-'],
                                stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdoutdata, stderrdata = p.communicate(input=bytes(code, 'utf-8'))
        else:
            assert code is None or len(code) == 0, "`code` and `path` are exclusive!"
            workdir, fn = os.path.split(path)
            p = subprocess.Popen([SOLCBIN, '--optimize' if optimize else '', '--combined-json', 'abi,bin,devdoc,userdoc,structs,statevars', './=/work/counterparty-lib/', fn],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=workdir)
            stdoutdata = p.stdout.read().strip()
            stderrdata = p.stderr.read().strip()
            p.terminate()

        if p.returncode:
            raise CompileError('compilation failed: %s' % str(stderrdata).replace('\\n', '\n'))

        # contracts = json.loads(stdoutdata)['contracts']
        contracts = ethutils.json_decode(stdoutdata)['contracts']
        for contract_name, data in contracts.items():
            data['abi'] = ethutils.json_decode(data['abi'])
            data['devdoc'] = ethutils.json_decode(data['devdoc'])
            data['userdoc'] = ethutils.json_decode(data['userdoc'])
            data['structs'] = ethutils.json_decode(data['structs'])
            data['statevars'] = ethutils.json_decode(data['statevars'])

        names = cls.contract_names(code or open(path).read())
        assert len(names) <= len(contracts)  # imported contracts are not returned
        sorted_contracts = []
        for name in names:
            sorted_contracts.append((name[1], contracts[name[1]]))
        return sorted_contracts

    @classmethod
    def compiler_version(cls):
        global COMPILER_VERSION

        if COMPILER_VERSION is not None:
            return COMPILER_VERSION

        version_info = subprocess.check_output(['solc', '--version'])
        match = re.search("^Version: ([0-9a-z.\-\*]+)/", version_info.decode('utf-8'), re.MULTILINE)

        COMPILER_VERSION = match.group(1) if match else False
        return COMPILER_VERSION

    @classmethod
    def compile_rich(cls, code, path=None):
        """full format as returned by jsonrpc"""

        return {
            contract_name: {
                'code': "0x" + contract.get('bin'),
                'info': {
                    'abiDefinition': contract.get('abi'),
                    'compilerVersion': cls.compiler_version(),
                    'developerDoc': contract.get('devdoc'),
                    'language': 'Solidity',
                    'languageVersion': '0',
                    'source': code,
                    'userDoc': contract.get('userdoc')
                },
            }
            for contract_name, contract
            in cls.combined(code, path=path)
        }


def is_exe(fpath):
    return os.path.isfile(fpath) and os.access(fpath, os.X_OK)


def get_solidity():
    if not is_exe(SOLCBIN):
        raise Exception("`solc` not available")
    return solc_wrapper
