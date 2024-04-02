import sys
import copy
import logging
import logging.handlers
import unicodedata
import codecs
from ctypes import WINFUNCTYPE, windll, POINTER, byref, c_int
from ctypes.wintypes import BOOL, HANDLE, DWORD, LPWSTR, LPCWSTR, LPVOID

from counterpartylib.lib import config

logger = logging.getLogger(config.LOGGER_NAME)


class SanitizedRotatingFileHandler(logging.handlers.RotatingFileHandler):
    def emit(self, record):
        # If the message doesn't need to be rendered we take a shortcut.
        if record.levelno < self.level:
            return
        # Make sure the message is a string.
        message = record.msg
        # Sanitize and clean up the message
        message = (
            unicodedata.normalize("NFKD", message).encode("ascii", "ignore").decode()
        )
        # Copy the original record so we don't break other handlers.
        record = copy.copy(record)
        record.msg = message
        # Use the built-in stream handler to handle output.
        logging.handlers.RotatingFileHandler.emit(self, record)


def fix_win32_unicode():
    """Thanks to http://stackoverflow.com/a/3259271 ! (converted to python3)"""
    if sys.platform != "win32":
        return

    original_stderr = sys.stderr

    # If any exception occurs in this code, we'll probably try to print it on stderr,
    # which makes for frustrating debugging if stderr is directed to our wrapper.
    # So be paranoid about catching errors and reporting them to original_stderr,
    # so that we can at least see them.
    def _complain(message):
        print(
            message if isinstance(message, str) else repr(message), file=original_stderr
        )

    # Work around <http://bugs.python.org/issue6058>.
    codecs.register(lambda name: codecs.lookup("utf-8") if name == "cp65001" else None)

    # Make Unicode console output work independently of the current code page.
    # This also fixes <http://bugs.python.org/issue1602>.
    # Credit to Michael Kaplan <http://blogs.msdn.com/b/michkap/archive/2010/04/07/9989346.aspx>
    # and TZOmegaTZIOY
    # <http://stackoverflow.com/questions/878972/windows-cmd-encoding-change-causes-python-crash/1432462#1432462>.
    try:
        # <http://msdn.microsoft.com/en-us/library/ms683231(VS.85).aspx>
        # HANDLE WINAPI GetStdHandle(DWORD nStdHandle);
        # returns invalid_handle_value, NULL, or a valid handle
        #
        # <http://msdn.microsoft.com/en-us/library/aa364960(VS.85).aspx>
        # DWORD WINAPI GetFileType(DWORD hFile);
        #
        # <http://msdn.microsoft.com/en-us/library/ms683167(VS.85).aspx>
        # BOOL WINAPI GetConsoleMode(HANDLE hConsole, LPDWORD lpMode);

        get_std_handle = WINFUNCTYPE(HANDLE, DWORD)(("GetStdHandle", windll.kernel32))
        std_output_handle = DWORD(-11)
        std_error_handle = DWORD(-12)
        get_file_type = WINFUNCTYPE(DWORD, DWORD)(("GetFileType", windll.kernel32))
        file_type_char = 0x0002
        file_type_remote = 0x8000
        get_console_mode = WINFUNCTYPE(BOOL, HANDLE, POINTER(DWORD))(
            ("GetConsoleMode", windll.kernel32)
        )
        invalid_handle_value = DWORD(-1).value

        def not_a_console(handle):
            if handle == invalid_handle_value or handle is None:
                return True
            return (
                get_file_type(handle) & ~file_type_remote
            ) != file_type_char or get_console_mode(handle, byref(DWORD())) == 0

        old_stdout_fileno = None
        old_stderr_fileno = None
        if hasattr(sys.stdout, "fileno"):
            old_stdout_fileno = sys.stdout.fileno()
        if hasattr(sys.stderr, "fileno"):
            old_stderr_fileno = sys.stderr.fileno()

        stdout_fileno = 1
        stderr_fileno = 2
        real_stdout = old_stdout_fileno == stdout_fileno
        real_stderr = old_stderr_fileno == stderr_fileno

        if real_stdout:
            h_std_out = get_std_handle(std_output_handle)
            if not_a_console(h_std_out):
                real_stdout = False

        if real_stderr:
            h_std_err = get_std_handle(std_error_handle)
            if not_a_console(h_std_err):
                real_stderr = False

        if real_stdout or real_stderr:
            # BOOL WINAPI WriteConsoleW(HANDLE hOutput, LPWSTR lpBuffer, DWORD nChars,
            #                           LPDWORD lpCharsWritten, LPVOID lpReserved);

            write_console_w = WINFUNCTYPE(
                BOOL, HANDLE, LPWSTR, DWORD, POINTER(DWORD), LPVOID
            )(("WriteConsoleW", windll.kernel32))

            class UnicodeOutput:
                def __init__(self, h_console, stream, fileno, name):
                    self._h_console = h_console
                    self._stream = stream
                    self._fileno = fileno
                    self.closed = False
                    self.softspace = False
                    self.mode = "w"
                    self.encoding = "utf-8"
                    self.name = name
                    self.errors = ""
                    self.flush()

                def isatty(self):
                    return False

                def close(self):
                    # don't really close the handle, that would only cause problems
                    self.closed = True

                def fileno(self):
                    return self._fileno

                def flush(self):
                    if self._h_console is None:
                        try:
                            self._stream.flush()
                        except Exception as e:
                            _complain(f"{self.name}.flush: {e!r} from {self._stream!r}")
                            raise

                def write(self, text):
                    try:
                        if self._h_console is None:
                            if isinstance(text, str):
                                text = text.encode("utf-8")
                            self._stream.write(text)
                        else:
                            if not isinstance(text, str):
                                text = str(text).decode("utf-8")
                            remaining = len(text)
                            while remaining:
                                n = DWORD(0)
                                # There is a shorter-than-documented limitation on the
                                # length of the string passed to WriteConsoleW (see
                                # <http://tahoe-lafs.org/trac/tahoe-lafs/ticket/1232>.
                                retval = write_console_w(
                                    self._h_console,
                                    text,
                                    min(remaining, 10000),
                                    byref(n),
                                    None,
                                )
                                if retval == 0 or n.value == 0:
                                    raise IOError(
                                        f"write_console_w returned {retval!r}, n.value = {n.value!r}"
                                    )
                                remaining -= n.value
                                if not remaining:
                                    break
                                text = text[n.value :]
                    except Exception as e:
                        _complain(f"{self.name}.write: {e!r}")
                        raise

                def writelines(self, lines):
                    try:
                        for line in lines:
                            self.write(line)
                    except Exception as e:
                        _complain(f"{self.name}.writelines: {e!r}")
                        raise

            if real_stdout:
                sys.stdout = UnicodeOutput(
                    h_std_out, None, stdout_fileno, "<Unicode console stdout>"
                )
            else:
                sys.stdout = UnicodeOutput(
                    None, sys.stdout, old_stdout_fileno, "<Unicode redirected stdout>"
                )

            if real_stderr:
                sys.stderr = UnicodeOutput(
                    h_std_err, None, stderr_fileno, "<Unicode console stderr>"
                )
            else:
                sys.stderr = UnicodeOutput(
                    None, sys.stderr, old_stderr_fileno, "<Unicode redirected stderr>"
                )
    except Exception as e:
        _complain(f"exception {e!r} while fixing up sys.stdout and sys.stderr")

    # While we're at it, let's unmangle the command-line arguments:

    # This works around <http://bugs.python.org/issue2128>.
    get_command_line_w = WINFUNCTYPE(LPWSTR)(("GetCommandLineW", windll.kernel32))
    command_line_to_argv_w = WINFUNCTYPE(POINTER(LPWSTR), LPCWSTR, POINTER(c_int))(
        ("CommandLineToArgvW", windll.shell32)
    )

    argc = c_int(0)
    argv_unicode = command_line_to_argv_w(get_command_line_w(), byref(argc))

    argv = [
        argv_unicode[i].encode("utf-8").decode("utf-8") for i in range(0, argc.value)
    ]

    if not hasattr(sys, "frozen"):
        # If this is an executable produced by py2exe or bbfreeze, then it will
        # have been invoked directly. Otherwise, unicode_argv[0] is the Python
        # interpreter, so skip that.
        argv = argv[1:]

        # Also skip option arguments to the Python interpreter.
        while len(argv) > 0:
            arg = argv[0]
            if not arg.startswith("-") or arg == "-":
                break
            argv = argv[1:]
            if arg == "-m":
                # sys.argv[0] should really be the absolute path of the module source,
                # but never mind
                break
            if arg == "-c":
                argv[0] = "-c"
                break

    # if you like:
    sys.argv = argv
