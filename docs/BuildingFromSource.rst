Building & Running from Source
================================

This section provides information about how to build and run ``counterpartyd`` from source. It's suitable
for Linux users, as well as Windows users that want to develop/enhance ``counterpartyd`` (or just don't want to use the binary installer).

On Windows
-----------

Prerequisites
~~~~~~~~~~~~~

.. note::

   If you are on a computer with a 64-bit version of Windows, it's normally best to get the 64-bit version of
   everything below. The only exception would be if you want to create a 32-bit installer for Counterpartyd.
   In that case, go with the 32-bit versions of all of the dependencies below.

Minimally required to build Counterpartyd from source is the following:

- Python 3.3.x -- grab the `32-bit version <http://www.python.org/ftp/python/3.3.3/python-3.3.3.msi>`__
  or `64-bit version <http://www.python.org/ftp/python/3.3.3/python-3.3.3.amd64.msi>`__.
  Install to the default ``C:\Python33`` location
- Python Win32 extensions -- grab the `32-bit version <http://sourceforge.net/projects/pywin32/files/pywin32/Build%20218/pywin32-218.win32-py3.3.exe/download>`__
  or `64-bit version <http://sourceforge.net/projects/pywin32/files/pywin32/Build%20218/pywin32-218.win-amd64-py3.3.exe/download>`__
- Git for Windows. Download `here <http://git-scm.com/download/win>`__ and install. Use the default installer options

If you want to be able to build the Counterpartyd installer, also download the following:

- Grab NSIS from `here <http://prdownloads.sourceforge.net/nsis/nsis-2.46-setup.exe?download>`__ -- Please choose the default
  options during installation, and install to the default path
- Download the NSIS SimpleService plugin from `here <http://nsis.sourceforge.net/mediawiki/images/c/c9/NSIS_Simple_Service_Plugin_1.30.zip>`__
  and save the .dll file contained in that zip to your NSIS ``plugins`` directory (e.g. ``C:\Program Files (X86)\NSIS\plugins``)
- cx_freeze -- grab the `32-bit version <http://prdownloads.sourceforge.net/cx-freeze/cx_Freeze-4.3.2.win32-py3.3.msi?download>`__
  or `64-bit version <http://prdownloads.sourceforge.net/cx-freeze/cx_Freeze-4.3.2.win-amd64-py3.3.msi?download>`__ as appropriate


Installing
~~~~~~~~~~~

Type ``<Windows Key>-R`` to open the run dialog, and enter "cmd.exe" to launch a command window.

In the command window, type the following commands:::

    cd C:\
    git clone https://github.com/PhantomPhreak/Counterparty.git
    cd Counterparty\dist
    C:\Python33\python.exe setup.py
     
The above steps will check out Counterparty to ``C:\Counterparty``, and run the Counterparty ``setup.py`` script, which
will create a virtual environment with the required dependencies.

If you chose to start ``counterpartyd`` at startup automatically, the setup script will also create a shortcut
to ``counterpartyd`` in your Startup group. 

Upon the successful completion of this script, you can now run ``counterpartyd`` using the steps below.


Running from Source
~~~~~~~~~~~~~~~~~~~

After installing, open a command window and run ``counterpartyd`` in the foreground via:::

    cd C:\Counterparty
    run.py


Or, if you have multiple versions of python on your computer and want to make sure you use the right one:::
    
    cd C:\Counterparty
    C:\Python33\python.exe run.py

In another command window, you can then run any of counterparty’s other functions, like:::

    run.py --help
    run.py send <options....>
    run.py order <options....>

To run the counterparty testsuite:::

    cd C:\CounterParty
    run.py tests 


Building your own Installer
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Complete the instructions under **Running from Source** above.
Then, execute the following commands to build from source:::

    cd C:\Counterparty\dist
    C:\Python33\python.exe setup.py -b
    
If successful, you will be provided the location of the resulting installer for Counterparty.


On Linux
-----------

Prerequisites
~~~~~~~~~~~~~

Currently, Ubuntu Linux (Server or Desktop) 12.04 LTS, 12.10, 13.04 or 13.10 are required.

Support for other distributions is a future task.


Installing
~~~~~~~~~~~

Launch a terminal window, and type the following:::

    sudo apt-get -y update
    sudo apt-get -y install git-core
    git clone https://github.com/PhantomPhreak/Counterparty.git ~/Counterparty
    sudo ~/Counterparty/dist/setup.py

The ``setup.py`` script will install necessary dependencies, create the python environment for ``counterpartyd``,
create a dedicated ``counterpartyd`` system user (which will run it, by default), and install an upstart script
that will automatically start ``counterpartyd`` on startup.


Creating a default config
~~~~~~~~~~~~~~~~~~~~~~~~~~

Follow the instructions listed under the **Config and Logging** section in :doc:`GettingStarted`.


Running from Source
~~~~~~~~~~~~~~~~~~~

After installing and creating the necessary basic config, run ``counterpartyd`` in the foreground to make sure
everything works fine:::

    counterpartyd
    
(The above assumes ``/usr/local/bin`` is in your PATH, which is where the ``counterpartyd`` symlink (which just
points to the ``run.py`` script) is placed. If not, run ``/usr/local/bin/counterpartyd`` instead.

Once you're sure it launches and runs fine, press CTRL-C to exit it, and then run ``counterpartyd`` as a background process via:::

    sudo service counterpartyd start

You can then run any of counterparty’s other functions, like:::

    counterpartyd --help
    counterpartyd send <options....>
    counterpartyd order <options....>

To run the counterparty testsuite:::

    counterpartyd tests

    

Mac OS X
--------

Mac OS support will be forthcoming.