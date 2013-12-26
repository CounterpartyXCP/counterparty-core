Getting Started
==================

Running bitcoind
-----------------

.. warning::

    Currently, ``bitcoind`` must be run on testnet. **Until ``bitcoind`` 0.9 is released, do not use ``counterpartyd``
    with a ``bitcoind`` running on production unless you know what you're doing.**
    

``counterpartyd`` communicates with the Bitcoin reference client (``bitcoind``). Normally, you'll run ``bitcoind``
on the same computer as your instance of ``counterpartyd`` runs on. However, you can also use a ``bitcoind``
sitting on a different server entirely, if you already have one running on your network. 

At this time, 3rd party RPC interfaces like Blockchain.info's are not supported.

On Windows
~~~~~~~~~~~~

Go to `the bitcoind download page <http://bitcoin.org/en/download>`__
and grab the installer for Windows. Install it with the default options.

Once installed, launch the GUI wallet program (Bitcoin-QT) to start the download of the blockchain.
Then, type Windows Key-R and enter ``cmd.exe`` to open a Windows command prompt. Type the following::

    cd %LOCALAPPDATA%\..\Roaming\.bitcoin
    notepad bitcoin.conf  

Say Yes to when Notepad asks if you want to create a new file, then paste in the text below::

    rpcuser=rpc
    rpcpassword=rpcpw1234
    server=1
    daemon=1
    txindex=1
    testnet=1
    
You should change the RPC password above to something more secure. Once done, press CTRL-S to save, and close Notepad.

After this, you must wait for the blockchain to finish downloading. Once this is done, you have two options:

- Close Bitcoin-QT and run ``bitcoind.exe`` directly. You can run it on startup by adding to your
  Startup program group in Windows, or using something like `NSSM <http://nssm.cc/usage>`__.
- You can simply restart Bitcoin-QT (for the configuration changes to take effecnt) and use that. This is
  fine for development/test setups, but not normally suitable for production systems. (You can have
  Bitcoin-QT start up automatically by clicking on Settings, then Options and checking the
  box titled "Start Bitcoin on system startup".


On Ubuntu Linux
~~~~~~~~~~~~~~~~~

If not already installed (or running on a different machine), do the following
to install it (on Ubuntu, other distros will have similar instructions)::

    sudo apt-get install python-software-properties
    sudo add-apt-repository ppa:bitcoin/bitcoin
    sudo apt-get update
    sudo apt-get install bitcoind
    mkdir -p ~/.bitcoin/
    echo -e "rpcuser=rpc\nrpcpassword=rpcpw1234\nserver=1\ndaemon=1" > ~/.bitcoin/bitcoin.conf

Please then edit the ``~/.bitcoin/bitcoin.conf`` file and set the file to the contents specified above (.

Next, start ``bitcoind``::

    bitcoind

The bitcoin server should now be started. The blockchain will begin to download automatically. You must let it finish 
downloading entirely before going to the next step. You can check the status of this by running::

     bitcoind getinfo|grep blocks

When done, the block count returned by this command will match the value given from
`this page <http://blockexplorer.com/q/getblockcount>`__.

For automatic startup of ``bitcoind`` on system boot, `this page <https://bitcointalk.org/index.php?topic=25518.0>`__
provides some good tips.


Installing counterpartyd
--------------------------

On Windows
~~~~~~~~~~~~~~~~~~~~~~

- Download the ``counterparty`` installer from `this link <https://raw.github.com/PhantomPhreak/bin/counterpartyd_installer.exe>`__
- Run the installer and navigate through the setup wizard
- The installer will verify all dependencies are on your system, as well as installing ``counterpartyd.exe``
  (i.e. which has been created as a self-contained program with all the necessary Python dependencies compiled in)
- The installer will gather data on your bitcoind installation, and create a basic ``counterpartyd`` configuration file from that
- The installer will also have ``counterpartyd`` run as a service on startup (called "CounterParty") automatically

You can start and stop the CounterParty service via the Services icon in the Administrative Tools Control Panel.


On Linux
~~~~~~~~~~~~~~~~~~~~~~~

There is no pre-made installer for Linux at this time, as the source install is rather straightforward.

Just follow the instructions for Linux in :doc:`BuildingFromSource`.


Config and Logging
----------------------

Finding the Data Directory
~~~~~~~~~~~~~~~~~~~~~~~~~~~

``counterpartyd`` stores its configuration, logging, and state data in a place known as the ``counterpartyd``
data directory.

Under Linux, the data directory is normally located in ``/home/counterpartyd/.config/counterparty`` (when
``counterparty`` is installed normally, via the ``setup.py`` installer).

Under Windows, the data directory is normally located at ``%APPDATA%\CounterParty\Counterparty``. Examples of this are:

- ``C:\users\<user name>\AppData\Roaming\Counterparty\Counterparty`` (Windows 7/8/Server)
- ``C:\users\<user name>\AppData\Local\Counterparty\Counterparty`` (Windows 7/8/Server Alternate location)
- ``C:\Documents and Settings\<user name>\Application Data`` (Windows XP)


Editing the Config
~~~~~~~~~~~~~~~~~~~~~~~~~~~

``counterpartyd`` can read its configuration data from a file.

If not using the Windows installer, you'll need to create a basic ``counterpartyd.conf`` file that contains
options that tell ``counterpartyd`` where and how to connect to your ``bitcoind`` process. Here's an example::

    rpc-connect=
    rpc-port=18832
    rpc-user=rpc
    rpc-password=rpcpw1234

Simply paste this snippet into a text editor, and then save as ``counterpartyd.conf`` in your ``counterparty`` data directory.


Viewing the Logs
~~~~~~~~~~~~~~~~~~~~~~~~~~~

By default, ``counterpartyd`` logs data to a file named ``counterpartyd.log``, located within the ``counterpartyd``
data directory (the location of which is detailed in the section above).

Under Linux, you can monitor these logs via a command like ``tail -f /home/counterpartyd/.config/counterparty/counterparty.log``.

Under Windows, you can use a tool like `Notepad++ <http://notepad-plus-plus.org/>`__ to view the log file,
which will detect changes to the file and update if necessary.


Next Steps
-----------

Once ``counterpartyd`` is installed and running, check out the :doc:`API` doc to start exploring the API.  
