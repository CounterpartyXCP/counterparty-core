#! /usr/bin/env python3
"""
Counterparty setup script - works under Ubuntu Linux and Windows at the present moment
"""
import os
import sys
import getopt
import logging
import shutil
import urllib
import zipfile
import platform
import tempfile
import stat

try: #ignore import errors on windows
    import pwd
    import grp
except ImportError:
    pass

COUNTERPARTY_USER = "counterpartyd"
PYTHON_VER = "3.3"
DEFAULT_CONFIG = "[Default]%srpc-connect=localhost%srpc-port=18832%srpc-user=rpc%srpc-password=rpcpw1234" % (
    os.linesep, os.linesep, os.linesep, os.linesep)    

def usage():
    print("SYNTAX: %s [-h] [--build]" % sys.argv[0])

def runcmd(command, abort_on_failure=True):
    ret = os.system(command)
    if abort_on_failure and ret != 0:
        logging.error("Command failed: '%s'" % command)
        sys.exit(1) 

def do_prerun_checks():
    #make sure this is running on a supported OS
    if os.name not in ("nt", "posix"):
        logging.error("Build script only supports Linux or Windows at this time")
        sys.exit(1)
    if os.name == "posix" and platform.dist()[0] != "Ubuntu":
        logging.error("Non-Ubuntu install detected. Only Ubuntu Linux is supported at this time")
        sys.exit(1)
        
    #under *nix, script must be run as root
    if os.name == "posix" and os.geteuid() != 0:
        logging.error("This script must be run as root (use 'sudo' to run)")
        sys.exit(1)

def get_paths():
    paths = {}
    paths['python_path'] = os.path.dirname(sys.executable)

    paths['base_path'] = os.path.normpath(os.path.join(os.path.dirname(os.path.realpath(sys.argv[0])), ".."))
    #^ the dir of where counterparty source was downloaded to
    logging.debug("base path: '%s'" % paths['base_path'])
    sys.path.insert(0, paths['base_path']) #can now import counterparty modules
    
    #find the location of the virtualenv command and make sure it exists
    if os.name == "posix":
        paths['virtualenv_path'] = "/usr/bin/virtualenv"
        paths['virtualenv_args'] = "--python=python%s" % PYTHON_VER
    elif os.name == "nt":
        paths['virtualenv_path'] = os.path.join(paths['python_path'], "Scripts", "virtualenv.exe")
        paths['virtualenv_args'] = ""
    
    #compose the rest of the paths...
    paths['dist_path'] = os.path.join(paths['base_path'], "dist")
    logging.debug("dist path: '%s'" % paths['dist_path'])

    paths['env_path'] = os.path.join(paths['base_path'], "env") # home for the virtual environment
    logging.debug("env path: '%s'" % paths['env_path'])

    paths['bin_path'] = os.path.join(paths['base_path'], "bin")
    logging.debug("bin path: '%s'" % paths['bin_path'])
    
    #the pip executiable that we'll be using does not exist yet, but it will, once we've created the virtualenv
    paths['pip_path'] = os.path.join(paths['env_path'], "Scripts" if os.name == "nt" else "bin", "pip.exe" if os.name == "nt" else "pip")
    
    return paths

def install_dependencies(paths):
    if os.name == "posix" and platform.dist()[0] == "Ubuntu":
        logging.info("UBUNTU LINUX: Installing Required Packages...")
        runcmd("sudo apt-get -y update")
        runcmd("sudo apt-get -y install software-properties-common python-software-properties git-core wget cx-freeze \
        python3 python3-setuptools python3-dev python3-pip build-essential python3-sphinx")

        #install sqlite utilities (not technically required as python's sqlite3 module is self-contained, but nice to have)
        runcmd("sudo apt-get -y install sqlite sqlite3 libsqlite3-dev libleveldb-dev")
        
        #now that pip is installed, install necessary deps outside of the virtualenv (e.g. for this script)
        runcmd("sudo pip install appdirs==1.2.0")
    elif os.name == 'nt':
        logging.info("WINDOWS: Installing Required Packages...")
        if not os.path.exists(os.path.join(paths['python_path'], "Scripts", "easy_install.exe")):
            #^ ez_setup.py doesn't seem to tolerate being run after it's already been installed... errors out
            #run the ez_setup.py script to download and install easy_install.exe so we can grab virtualenv and more...
            runcmd("pushd %%TEMP%% && %s %s && popd" % (sys.executable,
                os.path.join(paths['dist_path'], "windows", "ez_setup.py")))
        
        #now easy_install is installed, install virtualenv, and sphinx for doc building
        runcmd("%s virtualenv sphinx pip" % (os.path.join(paths['python_path'], "Scripts", "easy_install.exe")))
        
        #now that pip is installed, install necessary deps outside of the virtualenv (e.g. for this script)
        runcmd("%s install appdirs==1.2.0" % (os.path.join(paths['python_path'], "Scripts", "pip.exe")))

def create_user(paths):
    #don't create a user on windows
    if os.name == "nt":
        return
    
    try:
        pwd.getpwnam(COUNTERPARTY_USER)
    except (NameError, KeyError) as e:
        logging.info("Creating counterpartyd user")
        runcmd("sudo adduser --system --disabled-password --shell /bin/bash --home /var/lib/counterpartyd --group %s" % COUNTERPARTY_USER)
    else:
        logging.info("counterpartyd user already exists...skipping")

def create_virtualenv(paths):
    if paths['virtualenv_path'] is None or not os.path.exists(paths['virtualenv_path']):
        logging.debug("ERROR: virtualenv missing (%s)" % (paths['virtualenv_path'],))
        sys.exit(1)
    
    if os.path.exists(paths['env_path']):
        logging.warning("Deleting existing virtualenv...")
        shutil.rmtree(paths['env_path'])
    logging.info("Creating virtualenv at '%s' ..." % paths['env_path'])
    runcmd("%s %s %s" % (paths['virtualenv_path'], paths['virtualenv_args'], paths['env_path']))
    
    #pip should now exist
    if not os.path.exists(paths['pip_path']):
        logging.error("pip does not exist at path '%s'" % paths['pip_path'])
        sys.exit(1)
    
    #install packages from manifest via pip
    runcmd("%s install -r %s" % (paths['pip_path'], os.path.join(paths['dist_path'], "reqs.txt")))

def setup_startup(paths):
    while True:
        start_choice = input("Start counterpartyd automatically on system startup? (y/n): ")
        if start_choice.lower() not in ('y', 'n'):
            logger.error("Please enter 'y' or 'n'")
        else:
            break
    if start_choice.lower() == 'n':
        return
    
    #windows - no automatic startup from the script itself (auto startup is used when installing from installer)
    if os.name == "nt":
        #add a shortcut to run.py to the startup group
        import win32com.client
        import ctypes.wintypes
        CSIDL_PERSONAL=7 # Startup folder
        SHGFP_TYPE_CURRENT= 0 # Want current, not default value
        buf = ctypes.create_unicode_buffer(ctypes.wintypes.MAX_PATH)
        ctypes.windll.shell32.SHGetFolderPathW(0, CSIDL_PERSONAL, 0, SHGFP_TYPE_CURRENT, buf)
        logging.debug("Installing startup shortcut to '%s'" % buf.value)
        
        ws = win32com.client.Dispatch("wscript.shell")
        scut = ws.CreateShortcut(os.path.join(buf.value, 'run_counterpartyd.lnk'))
        scut.TargetPath = '"c:/Python33/python.exe"'
        scut.Arguments = os.path.join(paths['base_path'], 'run.py')
        scut.Save()        
    else: 
        assert os.name == "posix"
        runcmd("sudo ln -sf %s/run.py /usr/local/bin/counterpartyd" % paths['base_path'])
              
        logging.info("Setting up init scripts...")
        runcmd("sudo ln -sf %s/dist/linux/init/counterpartyd.conf /etc/init/counterpartyd.conf")

def create_default_config(paths):
    import appdirs #installed earlier
    cfg_path = os.path.join(
        appdirs.user_data_dir(appauthor='Counterparty', appname='counterpartyd', roaming=True) if os.name == "nt" else "/var/lib/counterpartyd",
        "counterpartyd.conf")
    cfg_dir = os.path.dirname(cfg_path)
    
    if not os.path.exists(cfg_dir):
        os.makedirs(cfg_dir)
    
    #create a default config file
    cfg = open(cfg_path, 'w')
    cfg.write(DEFAULT_CONFIG)
    cfg.close()
    
    #set proper file mode
    if os.name != "nt": 
        uid = pwd.getpwnam(COUNTERPARTY_USER).pw_uid
        gid = grp.getgrnam(COUNTERPARTY_USER).gr_gid    
        os.chown(cfg_path, uid, gid)
        os.chmod(cfg_path, stat.S_IRUSR | stat.S_IWUSR | stat.S_IRGRP | stat.S_IWGRP) #660
    else:
        #on windows, open notepad to the file to help out
        import win32api
        try:
            win32api.WinExec('NOTEPAD.exe "%s"' % cfg_path)
        except:
            pass        

    logging.info("NEXT STEP: Edit the config file we created '%s', according to the documentation" % cfg_path)

def do_build(paths):
    if os.name != "nt":
        logging.error("Building an installer only supported on Windows at this time.")
        sys.exit(1)

    logging.debug("Cleaning any old build dirs...")
    if os.path.exists(os.path.join(paths['bin_path'], "exe.win-amd64-%s" % PYTHON_VER)):
        shutil.rmtree(os.path.join(paths['bin_path'], "exe.win-amd64-%s" % PYTHON_VER))
    if os.path.exists(os.path.join(paths['bin_path'], "exe.win-i386-%s" % PYTHON_VER)):
        shutil.rmtree(os.path.join(paths['bin_path'], "exe.win-i386-%s" % PYTHON_VER))
    if os.path.exists(os.path.join(paths['bin_path'], "build")):
        shutil.rmtree(os.path.join(paths['bin_path'], "build"))

    logging.info("Building Counterparty...")
    #Run cx_freeze to build the counterparty sources into a self-contained executiable
    runcmd("%s \"%s\" build -b \"%s\"" % (
        sys.executable, os.path.join(paths['dist_path'], "_cxfreeze_setup.py"), paths['bin_path']))
    #move the build dir to something more predictable so we can build an installer with it
    arch = "amd64" if os.path.exists(os.path.join(paths['bin_path'], "exe.win-amd64-%s" % PYTHON_VER)) else "i386"
    shutil.move(os.path.join(paths['bin_path'], "exe.win-%s-%s" % (arch, PYTHON_VER)), os.path.join(paths['bin_path'], "build"))
    
    logging.info("Frozen executiable data created in %s" % os.path.join(paths['bin_path'], "build"))
    
    #Add a default config to the build
    cfg = open(os.path.join(paths['bin_path'], "counterpartyd.conf.default"), 'w')
    cfg.write(DEFAULT_CONFIG)
    cfg.close()
    
    #find the location of makensis.exe (freaking windows...)
    if 'PROGRAMFILES(X86)' in os.environ:
        pf_path = os.environ['PROGRAMFILES(X86)'].replace("Program Files (x86)", "Progra~2")
    else:
        pf_path = os.environ['PROGRAMFILES'].replace("Program Files", "Progra~1")
    
    make_nsis_path = os.path.normpath(os.path.join(pf_path, "NSIS", "makensis.exe"))
    if not os.path.exists(make_nsis_path):
        logging.error("Error finding makensis.exe at path '%s'. Did you install NSIS?" % make_nsis_path)
        sys.exit(1)
    runcmd(r'%s %s' % (make_nsis_path, os.path.normpath(os.path.join(paths['dist_path'], "windows", "installer.nsi"))))
    
    #move created .msi file to the bin dir
    from lib import config #counter party
    installer_dest = os.path.join(paths['bin_path'], "counterpartyd-v%s-%s_install.exe" % (config.VERSION, arch))
    if os.path.exists(installer_dest):
        os.remove(installer_dest)
    shutil.move(os.path.join(paths['dist_path'], "windows", "counterpartyd_install.exe"), installer_dest)
    logging.info("FINAL installer created as %s" % installer_dest)

def main():
    logging.basicConfig(level=logging.DEBUG, format='%(asctime)s|%(levelname)s: %(message)s')
    
    do_prerun_checks()
    paths = get_paths()

    #parse any command line objects
    build = False
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hb", ["build", "help"])
    except getopt.GetoptError as err:
        usage()
        sys.exit(2)
    mode = None
    for o, a in opts:
        if o in ("-b", "--build"):
            build = True
        elif o in ("-h", "--help"):
            usage()
            sys.exit()
        else:
            assert False, "Unhandled or unimplemented switch or option"

    if build:
        do_build(paths)
    else: #install mode
        logging.info("Installing Counterparty from source...")
        install_dependencies(paths)
        create_user(paths)
        create_virtualenv(paths)
        setup_startup(paths)
    
    logging.info("%s DONE. (It's time to kick ass, and chew bubblegum... and I'm all outta gum.)" % ("BUILD" if build else "SETUP"))
    if not build:
        create_default_config(paths)


if __name__ == "__main__":
    main()
