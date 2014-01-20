How to Burn Bitcoin (to generate XCP)
======================================

.. warning::

   This document is valid only between Bitcoin blocks 278310 and 283810.
   Do not try burning after this period has ended. 


Using counterpartyd
----------------------

``counterpartyd`` is the preferred way to "burn" BTC to generate XCP. To burn BTC, configure ``bitcoind`` and
install ``counterpartyd`` using the instructions from the earlier sections of this document (either from source, or via the installer).

Once done, you can open up a command prompt, then, just run the command like::

    counterpartyd burn --from=<ADDRESS> --quantity=<QUANTITY>
    #under Linux
    
    C:\python33\python.exe C:\counterpartyd_build\run.py burn --from=<ADDRESS> --quantity=<QUANTITY>
    #under Windows
    
Full examples::

    counterpartyd burn --from=1J6Sb7BbhCQKRTwmt8yKxXAAQByeNsED7P --quantity=0.5
    #under Linux
    
    C:\python33\python.exe C:\counterpartyd_build\run.py burn --from=1J6Sb7BbhCQKRTwmt8yKxXAAQByeNsED7P --quantity=0.005
    #under Windows
 

Without using counterpartyd
-------------------------------------------

.. warning::

    **DISCLAIMER:** The format of a Counterparty transaction is very specific, and we can’t guarantee that a
    transaction constructed by any other software will work (and if it doesn’t, you’ll lose your BTC).

    You may make multiple sends from a single address to the Counterparty burn address, **as long as the
    total amount of BTC sent from that address is not greater than 1 BTC**.

The requirements for a successful "burn":

- All of the input addresses are identical.
- The address of the **first** output is the unspendable address ``1CounterpartyXXXXXXXXXXXXXXXUWLpVr`` (mainnet)
  or ``mvCounterpartyXXXXXXXXXXXXXXW24Hef`` (testnet).
- The total number of BTC burned by the source address is less than or equal to 1.


Blockchain.info My Wallet
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To perform a burn on `blockchain.info <http://blockchain.info>`__, do the following:

**Step 1**

First, sign up for a My Wallet account (if you haven't already) at `this link <https://blockchain.info/wallet/new>`__.

**Step 2**

If you want to burn X BTC (where X <= 1 BTC) from address A, then make sure that there is **exactly**
X + .0001 BTC in address A. (And that you haven't already burned more than 1 BTC - X BTC at that address.)

**Step 3**

Click on the "Send Money" tab, then click on "Custom" under "Transaction Type". Do the following:

- Select address A under the **"From"** box
- Enter '1CounterpartyXXXXXXXXXXXXXXXUWLpVr' next to the **"To"** box.
- Enter 'X' BTC to the right of that.
- Set the **"Miners fee"** to exactly .0001 BTC.
- The change address can be anything, because there should be **zero** change. (To clarify: you should not burn from an
  address that has a balance of more than you are burning: we can't guarantee that Blockchain.info will always list a change output last.)

**Step 4**

- Click "Review Payment".
- Click 'Show Advanced'.
- Verify that **all of the input are identical** (summing to X + .0001 BTC) and that exactly **one output** (X BTC) listed.
- Click "Send Transaction".

**Verification**

Click `this link <https://blockchain.info/address/1CounterpartyXXXXXXXXXXXXXXXUWLpVr>`__. You should see the transaction listed as sending the entire balance of the address to the Counterparty burn address, with no change address listed.
