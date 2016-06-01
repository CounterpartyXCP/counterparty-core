import re
import subprocess
import os

import binascii
import yaml  # use yaml instead of json to get non unicode


class CompileError(Exception):
    pass


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
        return re.findall(r'^\s*(contract|library) (\S*) ', code, re.MULTILINE)

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
                    .replace("__{}{}".format(lib_name, "_" * (38 - len(lib_name))), lib_address.hexstr32())

        return binascii.unhexlify(sorted_contracts[idx][1]['bin'])

    @classmethod
    def mk_full_signature(cls, code, path=None, libraries=None, contract_name=''):
        "returns signature of last contract in code"
        sorted_contracts = cls.combined(code, path=path)
        if contract_name:
            idx = [x[0] for x in sorted_contracts].index(contract_name)
        else:
            idx = -1
        return sorted_contracts[idx][1]['abi']

    @classmethod
    def combined(cls, code, path=None):
        """compile combined-json with abi,bin,devdoc,userdoc
        @param code: literal solidity code as a string.
        @param path: absolute path to solidity-file. Note: code & path are exclusive!
        """

        if path is None:
            p = subprocess.Popen(['solc', '--add-std', '--optimize', '--combined-json', 'abi,bin,devdoc,userdoc'],
                                stdin=subprocess.PIPE, stdout=subprocess.PIPE)
            stdoutdata, stderrdata = p.communicate(input=bytes(code, 'utf-8'))
        else:
            assert code is None or len(code) == 0, "`code` and `path` are exclusive!"
            workdir, fn = os.path.split(path)
            p = subprocess.Popen(['solc', '--add-std', '--optimize', '--combined-json', 'abi,bin,devdoc,userdoc', fn],
                                stdout=subprocess.PIPE, cwd=workdir)
            stdoutdata = p.stdout.read().strip()
            p.terminate()

        if p.returncode:
            raise CompileError('compilation failed')
        # contracts = json.loads(stdoutdata)['contracts']
        contracts = yaml.safe_load(stdoutdata)['contracts']
        for contract_name, data in contracts.items():
            data['abi'] = yaml.safe_load(data['abi'])
            data['devdoc'] = yaml.safe_load(data['devdoc'])
            data['userdoc'] = yaml.safe_load(data['userdoc'])

        names = cls.contract_names(code or open(path).read())
        assert len(names) <= len(contracts)  # imported contracts are not returned
        sorted_contracts = []
        for name in names:
            sorted_contracts.append((name[1], contracts[name[1]]))
        return sorted_contracts

    @classmethod
    def compiler_version(cls):
        version_info = subprocess.check_output(['solc', '--version'])
        match = re.search("^Version: ([0-9a-z.-]+)/", version_info.decode('utf-8'), re.MULTILINE)
        if match:
            return match.group(1)

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


def get_solidity():
    if not solc_wrapper.compiler_available():
        return None
    return solc_wrapper

