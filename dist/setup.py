#! /usr/bin/env python3
"""
Counterparty setup script - works under Ubuntu Linux and Windows at the present moment
"""
import os
import sys
import pwd
import grp
import stat
import getopt
import logging
import shutil
import urllib
import zipfile
import platform
import tempfile

COUNTERPARTY_USER = "counterpartyd"

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
    
    #find the location of the virtualenv command and make sure it exists
    if os.name == "posix":
        paths['virtualenv_path'] = "/usr/bin/virtualenv"
        paths['virtualenv_args'] = "--python=python3.3"
    elif os.name == "nt":
        paths['virtualenv_path'] = paths['python_path'] + "virtualenv.exe"
        paths['virtualenv_args'] = ""
    if paths['virtualenv_path'] is None or not os.path.exists(paths['virtualenv_path']):
        logging.debug("ERROR: virtualenv missing (%s)" % (paths['virtualenv_path'],))
        sys.exit(1)
    
    #compose the rest of the paths...
    paths['dist_path'] = os.path.join(paths['base_path'], "dist")
    logging.debug("dist path: '%s'" % paths['dist_path'])

    paths['env_path'] = os.path.join(paths['base_path'], "env") # home for the virtual environment
    logging.debug("env path: '%s'" % paths['env_path'])
    
    #the pip executiable that we'll be using does not exist yet, but it will, once we've created the virtualenv
    paths['pip_path'] = os.path.join(paths['env_path'], "bin", "pip.exe" if os.name == "nt" else "pip")
    
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
        #run the ez_setup.py script to download and install easy_install.exe so we can grab virtualenv and more...
        runcmd("pushd %TEMP% && %s %swindows\ez_setup.py && popd" % (sys.executable, paths['deps_path'],))
        
        #now easy_install is installed, install virtualenv, and sphinx for doc building
        runcmd("%s\Scripts\easy_install.exe virtualenv sphinx pip" % (paths['python_path'],))
        
        #now that pip is installed, install necessary deps outside of the virtualenv (e.g. for this script)
        runcmd("%s\Scripts\pip.exe install appdirs==1.2.0" % (paths['python_path'],))

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
    
    #Don't use this code (for now at least), since we don't need cx_freeze under Linux
    #if os.name == "posix" and platform.dist()[0] == "Ubuntu":
    #cx_freeze has a build bug under Ubuntu 13.04 and 13.10 (at least)
    #runcmd("""sudo rm -rf /tmp/cx_Freeze-4.3.2* && \
    #wget -O /tmp/cx_Freeze-4.3.2.tar.gz "http://downloads.sourceforge.net/project/cx-freeze/4.3.2/cx_Freeze-4.3.2.tar.gz?r=http%3A%2F%2Fcx-freeze.sourceforge.net%2F&ts=1388338830&use_mirror=softlayer-dal" && \
    #tar -zxvf /tmp/cx_Freeze-4.3.2.tar.gz -C /tmp && \
    #sed -r -i -e "s/if not vars\.get\(\"Py_ENABLE_SHARED\", 0\)/if True/g" /tmp/cx_Freeze-4.3.2/setup.py && \
    #cd /tmp/cx_Freeze-4.3.2 && sudo python3.3 setup.py install""")
    

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
        appdirs.user_data_dir('Counterparty', 'counterpartyd') if os.name == "nt" else "/var/lib/counterpartyd",
        "counterpartyd.conf")
    
    #create a default config file
    default_config = "[Default]%srpc-connect=localhost%srpc-port=18832%srpc-user=rpc%srpc-password=rpcpw1234" % (
        os.linesep, os.linesep, os.linesep, os.linesep)    
    cfg = open(cfg_path, 'w')
    cfg.write(default_config)
    cfg.close()
    
    #set proper file mode
    if os.name != "nt": 
        uid = pwd.getpwnam(COUNTERPARTY_USER).pw_uid
        gid = grp.getgrnam(COUNTERPARTY_USER).gr_gid    
        os.chown(cfg_path, uid, gid)
        os.chmod(cfg_path, stat.S_IRUSR | stat.S_IWUSR | stat.S_IRGRP | stat.S_IWGRP) #660

    logging.info("NEXT STEP: Edit the config file we created '%s', according to the documentation" % cfg_path)
    

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
        logging.info("BUILDING COUNTERPARTY...")
        #Run cx_freeze to build the counterparty sources into a self-contained executiable
        dest_dir = tempfile.mkdtemp()
        
        runcmd("%s %s build -b %s" % (
            paths['python_path'], os.path.join(paths['dist_path'], "_cxfreeze_setup.py"), dest_dir))
        
        logging.info("Frozen executiable data created in %s" % dest_dir)
        
        if os.name != "nt":
            return
        
        #find the location of makensis.exe
        makeNSISPath = os.path.join(os.environ.get('PROGRAMFILES(X86)', os.environ['PROGRAMFILES']), "makensis.exe")
        if not os.path.exists(makeNSISPath):
            logging.error("Error finding makensis.exe at path '%s'. Did you install NSIS?" % makeNSISPath)
            sys.exit(1)
        runcmd("%s %sdist\windows\installer.nsi" % (makeNSISPath, paths['dist_path']))
        
        #move created .msi file to the same temp directory
        
        logging.info("FINAL installer created as %s%s%s" % (os.path.join(dest_dir, "counterpartyd_installer.exe")))
    else: #install mode
        logging.info("INSTALLING COUNTERPARTY FROM SOURCE...")
        install_dependencies(paths)
        create_user(paths)
        create_virtualenv(paths)
        setup_startup(paths)
    
    logging.info("SETUP DONE. (It's time to kick ass, and chew bubblegum... and I'm all outta gum.)")
    create_default_config(paths)


if __name__ == "__main__":
    main()
