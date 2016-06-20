### Preperation

##### Counterparty rootdir
To make the commands easy to copy paste you should set the `COUNTERPARTYROOT` ENVVAR, copy one of the below 2 lines;
```bash
COUNTERPARTYROOT=`pwd`  # set it to current directory, which works if you're atm in the `counterparty-lib` dir
COUNTERPARTYROOT=`~/projects/counterparty-lib`  # example, replace with you path, without trailing /
```
You can check if it's set correctly if the following command lists `setup.py`:
```bash
ls $COUNTERPARTYROOT/setup.py
```

##### JQ
Please install `jq >= v1.5`, it's a command line JSON parser and makes it easier to give you example commands you can copy paste:
 - Download it here: https://stedolan.github.io/jq/ (`wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64`)
 - Install somewhere;
    - Either `/usr/bin` (`sudo cp ~/Downloads/jq-linux64 /usr/bin/jq; sudo chmod +x /usr/bin/jq`)
      And set `JQ="jq"` so we can use
    - Or put it in the `./bin` directory of Counterparty (`CP ~/Downloads/jq-linux64 $COUNTERPARTYROOT/bin/jq; chmod +x $COUNTERPARTYROOT/bin/jq`)
      And set `JQ="$COUNTERPARTYROOT/bin/jq"` so we can use

 - Make sure to repeat the `export JQ=....` step when you come back later ;)

##### Your Wallet
Please export the address of the wallet you're using,
for easiest usage this can just be an address from your bitcoind wallet,
that way we can also let bitcoind sign the transactions.

You should preload the address with some testnet ~0.01 BTC and ~200 XCP!

eg;
```bash
SOURCE="miJqNkHhC5xsB61gsiSWXeTLnEGSQnWbXB"
```

##### Waiting for blocks
During the example we'll have to wait for a new block a few times, paste the copy below into your terminal;

```bash
function WAITFORBLOCK {
    HEIGHT=$(counterparty-client --testnet getinfo 2> /dev/null | $JQ '.last_block.block_index'); NEWHEIGHT=$HEIGHT; while [ $NEWHEIGHT -le $HEIGHT ]; do NEWHEIGHT=$(counterparty-client --testnet getinfo 2> /dev/null | $JQ '.last_block.block_index'); echo $NEWHEIGHT; sleep 5; done
}
```

And then whenever we need to wait for a block we can do
```bash
WAITFORBLOCK
```


### The Contract
You can find the contract in the `crowdfund.sol` file in this directory.
You can also open it here: https://ethereum.github.io/browser-solidity/#gist=52255a95b4f470e6ef502de22a630850


### Creating the Contract
First we need to compile the contract using the `solc` command, to avoid conflicting with the Ethereum `solc` it's found in the `./bin` directory of the project.

We can compile it to it's ABI (Application Binary Interface):
```bash
$COUNTERPARTYROOT/bin/solc --optimize --combined-json abi $COUNTERPARTYROOT/examples/contracts/crowdfund/crowdfund.sol | $JQ '.contracts.crowdfund.abi | fromjson'
```

Which should output, this is the interface of the contract:
```json
[
  {
    "constant": false,
    "inputs": [
      {
        "name": "id",
        "type": "uint256"
      }
    ],
    "name": "progress_report",
    "outputs": [
      {
        "name": "",
        "type": "uint256"
      }
    ],
    "type": "function"
  },
  {
    "constant": false,
    "inputs": [
      {
        "name": "recipient",
        "type": "address"
      },
      {
        "name": "title",
        "type": "string"
      },
      {
        "name": "goal",
        "type": "uint256"
      },
      {
        "name": "timelimit",
        "type": "uint256"
      }
    ],
    "name": "create_campaign",
    "outputs": [
      {
        "name": "",
        "type": "uint256"
      }
    ],
    "type": "function"
  },
  {
    "constant": false,
    "inputs": [
      {
        "name": "id",
        "type": "uint256"
      }
    ],
    "name": "contribute",
    "outputs": [
      {
        "name": "",
        "type": "uint256"
      }
    ],
    "type": "function"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "name": "campaign_id",
        "type": "uint256"
      },
      {
        "indexed": false,
        "name": "contrib_total",
        "type": "uint256"
      },
      {
        "indexed": false,
        "name": "control_total",
        "type": "uint256"
      }
    ],
    "name": "LogProgress",
    "type": "event"
  }
]
```

We're gonna capture the ABI in a var so we can use it later;
```bash
CONTRACTABI=$($COUNTERPARTYROOT/bin/solc --optimize --combined-json abi $COUNTERPARTYROOT/examples/contracts/crowdfund/crowdfund.sol | $JQ '.contracts.crowdfund.abi | fromjson')
echo $CONTRACTABI
```
And we're gonna capture the compiled binary (hex) of the contract;
```bash
CONTRACTHEX=$($COUNTERPARTYROOT/bin/solc --optimize --combined-json bin $COUNTERPARTYROOT/examples/contracts/crowdfund/crowdfund.sol | $JQ -r '.contracts.crowdfund.bin')
echo $CONTRACTHEX
```

Now we're ready to publish our contract to the blockchain;
```bash
counterparty-client --testnet publish --source $SOURCE --endowment 0 --code-hex $CONTRACTHEX --startgas 1000000 --gasprice 1
```

Which will prompt:
```
Transaction (unsigned): 01000000...........................
Sign and broadcast? (y/N)
```

Asuming you've used an address from your bitcoind wallet you can choose `y`, otherwise copy the unsigned hex and go sign it somehow (counterwallet, w/e).

And the result:
```
Hash of transaction (broadcasted): 982fff874eaee5310d0b62ff29daa53862dbf31663c23a18edf2550e7dfb9705
```

Assign the txId so we can use it in our copy paste snippets (note; copy paste your txId, don't use the example one obviously!):
```bash
CREATIONTXID="TXID_GOES_HERE"
```


Now we gotta wait for a block to confirm the TX ... zzz ... use the function we created earlier and it will keep trying until a block is found ...
```bash
WAITFORBLOCK
```

Now that the TX has been mined we can check what the address of the created contract is (note; better tooling to get the address when broadcasting would be nice):
```bash
counterparty-client --testnet evm_info --debug-output --abi "$CONTRACTABI" $CREATIONTXID
```

Which will give you the contract address somewhere:
```
----------------------------- EXECUTION INFO ----------------------------
created contract: tgdM7Z9voZfpweZKPXok4UpRNWs2pq4f6s
```

Copy that and assign it:
```bash
CONTRACTID="tgdM7Z9voZfpweZKPXok4UpRNWs2pq4f6s"
```


### Creating a Crowdfund Campaign
To create a new campaign we have to call the `create_campaign` function of the contract, which as the ABI show takes the following arguments:
```json
[
    {"name": "recipient", "type": "address"},
    {"name": "title", "type": "string"},
    {"name": "goal", "type": "uint256"},
    {"name": "timelimit", "type": "uint256"}
]
```

Now let's say we want to make a campaign for; recipient=your own address, title="FEED ME", goal=100, timelimit=86400.

There's a small tool to encode the payload:
```bash
CREATE_CAMPAIGN_PAYLOAD_HEX=$(python $COUNTERPARTYROOT/tools/evm-encode-fn-call.py --abi "$CONTRACTABI" create_campaign $SOURCE "FEED ME" 100 86400)
echo $CREATE_CAMPAIGN_PAYLOAD_HEX
```

Which should result in:
```
bc2fc8e100000000000000000000006f1d8b2a9927b3973e84f6879d85d8adbffbcd9795000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000640000000000000000000000000000000000000000000000000000000000015180000000000000000000000000000000000000000000000000000000000000000746454544204d4500000000000000000000000000000000000000000000000000
```

Now we can execute that:
```bash
counterparty-client --testnet execute --source $SOURCE --contract-id $CONTRACTID --value 0 --payload-hex $CREATE_CAMPAIGN_PAYLOAD_HEX --startgas 1000000 --gasprice 1
```

We'll again get the `Sign and broadcast (y/N)` step, gogo and then wait for a block again (use the earlier function again)...
```bash
WAITFORBLOCK
```

While we wait for the block let's take a closer look at the payload we just send along:
```
bc2fc8e100000000000000000000006f1d8b2a9927b3973e84f6879d85d8adbffbcd9795000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000640000000000000000000000000000000000000000000000000000000000015180000000000000000000000000000000000000000000000000000000000000000746454544204d4500000000000000000000000000000000000000000000000000
```

The EVM does everything by 32 byte ints, so we can snip this up into 7 parts (32 bytes are 64 chars as hex):
```
bc2fc8e1  # function selector
00000000000000000000006f1d8b2a9927b3973e84f6879d85d8adbffbcd9795  # your address
0000000000000000000000000000000000000000000000000000000000000080  # the offset where the title is -> 128
0000000000000000000000000000000000000000000000000000000000000064  # the goal -> 100
0000000000000000000000000000000000000000000000000000000000015180  # the deadline -> 86400
0000000000000000000000000000000000000000000000000000000000000007  # the length of "FEED ME"
46454544204d4500000000000000000000000000000000000000000000000000  # "FEED ME"
```

Yea that first `bc2fc8e1` isn't 32 bytes, that's because it's the function selector, and optimized to be shorter (4 bytes).

The `title` argument is a `string`, which has a variable length,
all variable length arguments are placed at the end of the payload and on their position is only an INT of the offset where the actual data is found.

The `goal` and `deadline` follow and they're simply HEX versions of their values.

And then the variable length `string` comes, first the length (7) and then the string itself, of which we'll only be using the first 7 bytes!

Ok, let's move on... that block should be found by now!

Now to see the output of the campaign creation we'll use the same debug tool again, there's 2 options:
 1. specify the txId again
 2. specify the contract address and it will list all the TXs for that contract in the order of execution:
```bash
counterparty-client --testnet evm_info --debug-output --abi "$CONTRACTABI" $CONTRACTID
```

Your campaign creation should be the last one:
```
----------------------------- EXECUTION INFO ----------------------------
function_called: create_campaign
arguments types: ['address', 'string', 'uint256', 'uint256']
arguments: ['miJqNkHhC5xsB61gsiSWXeTLnEGSQnWbXB', '46454544204d45', 100, 86400]
output types: ['uint256']
output: [1]
```

The `output` here is the return value of `create_campaign`, which is the ID of the campaign (which is `1` because this was the first campaign) so let's assign that too:
```bash
CAMPAIGNID=1
```


### Contributing to the campaign
To contribute to a campaign we have to call the `contribute` function of the contract, which as the ABI show takes the following arguments:
```json
[
    {"name": "id", "type": "uint256"}
]
```

All XCP send along to the `contribute` will be added to the campaign.

There's a small tool to encode the payload:
```bash
CONTRIBUTE_PAYLOAD_HEX=$(python $COUNTERPARTYROOT/tools/evm-encode-fn-call.py --abi "$CONTRACTABI" contribute $CAMPAIGNID)
echo $CONTRIBUTE_PAYLOAD_HEX
```

Which should result in:
```
c1cbbca70000000000000000000000000000000000000000000000000000000000000001
```

Now we can execute that with, and send 99 XCP along as the `value`:
```bash
CONTRIBUTE_VALUE=99
counterparty-client --testnet execute --source $SOURCE --contract-id $CONTRACTID --value $CONTRIBUTE_VALUE --payload-hex $CONTRIBUTE_PAYLOAD_HEX --startgas 1000000 --gasprice 1
```

Once a block has been found (use the function... again... zzz...)
```bash
WAITFORBLOCK
```

we can debug the output again:

```bash
counterparty-client --testnet evm_info --debug-output --abi "$CONTRACTABI" $CONTRACTID
```
```
----------------------------- EXECUTION INFO ----------------------------
function_called: contribute
arguments types: ['uint256']
arguments: [1]
output types: ['uint256']
output: [1]
-------------------------- GAS DEBITS / CREDITS -------------------------
 - DEBIT [GAS]; miJqNkHhC5xsB61gsiSWXeTLnEGSQnWbXB -1000000 XCP (startgas)
 - CREDIT [GAS]; miJqNkHhC5xsB61gsiSWXeTLnEGSQnWbXB 978155 XCP (startgas)
---------------------------- DEBITS / CREDITS ---------------------------
 - DEBIT; miJqNkHhC5xsB61gsiSWXeTLnEGSQnWbXB -99 XCP (transfer value)
 - CREDIT; tgdM7Z9voZfpweZKPXok4UpRNWs2pq4f6s 99 XCP (transfer value)
```

As you can see the argument given was `1`, which was the campaign ID,
the output is `1` which if you check the `crowdfund.sol` contract is the return value on a succesful contribution.

You can also see the debits/credits that this transaction triggered, ignoring the GAS ones,
you can see 99 XCP was debited from our address and credited to the contract.

### Progress Report
To officially get the progress of a campaign (we'll have debugging tools to do this without execution)
we have to call the `progress_report` function of the contract,
which as the ABI show takes the following arguments:
```json
[
    {"name": "id", "type": "uint256"}
]
```

There's a small tool to encode the payload:
```bash
PROGRESS_REPORT_PAYLOAD_HEX=$(python $COUNTERPARTYROOT/tools/evm-encode-fn-call.py --abi "$CONTRACTABI" progress_report $CAMPAIGNID)
echo $PROGRESS_REPORT_PAYLOAD_HEX
```

Which should result in:
```
8182c0cf0000000000000000000000000000000000000000000000000000000000000001
```

Now we can execute that:
```bash
counterparty-client --testnet execute --source $SOURCE --contract-id $CONTRACTID --value 0 --payload-hex $PROGRESS_REPORT_PAYLOAD_HEX --startgas 1000000 --gasprice 1
```

Again waiting for a block (if you don't know what do do by now...) ...
```
WAITFORBLOCK
```

And then run the debug tool:
```bash
counterparty-client --testnet evm_info --debug-output --abi "$CONTRACTABI" $CONTRACTID
```
```
----------------------------- EXECUTION INFO ----------------------------
function_called: progress_report
arguments types: ['uint256']
arguments: [1]
output types: ['uint256']
output: [99]
```

We can see the `99` as output, which is how much we contributed in the previous TX.


### Trigger payout
So to trigger the payout we need to contribute 1 XCP more and then it will reach it's goal.

You can check the balances prior to doing this if you don't trust the DEBIT/CREDIT list of the debug tool xD:

```bash
counterparty-client --testnet getrows --table balances --filter "address" "==" $CONTRACTID --filter-op OR --filter "address" "==" $SOURCE
```

```
+------------------+------------------------------------+---------+
|     quantity     |              address               |  asset  |
+------------------+------------------------------------+---------+
|   13328504735    | miJqNkHhC5xsB61gsiSWXeTLnEGSQnWbXB |   XCP   |
|        99        | tnDsEWRcV1YXMWAqRREsgs2qwEDbKSqFdj |   XCP   |
+------------------+------------------------------------+---------+

```

And then do a contribute with sending 1 XCP along as `value`:

```bash
CONTRIBUTE_VALUE=1
counterparty-client --testnet execute --source $SOURCE --contract-id $CONTRACTID --value $CONTRIBUTE_VALUE --payload-hex $CONTRIBUTE_PAYLOAD_HEX --startgas 1000000 --gasprice 1
```

Waiting for a block again (seriously? you forgot about that 1liner?)...
```
WAITFORBLOCK
```

Then running the debug tool we should see the contribute:
```bash
counterparty-client --testnet evm_info --debug-output --abi "$CONTRACTABI" $CONTRACTID
```
```
----------------------------- EXECUTION INFO ----------------------------
function_called: contribute
arguments types: ['uint256']
arguments: [1]
output types: ['uint256']
output: [2]
-------------------------- GAS DEBITS / CREDITS -------------------------
 - DEBIT [GAS]; miJqNkHhC5xsB61gsiSWXeTLnEGSQnWbXB -1000000 XCP (startgas)
 - CREDIT [GAS]; miJqNkHhC5xsB61gsiSWXeTLnEGSQnWbXB 931803 XCP (startgas)
---------------------------- DEBITS / CREDITS ---------------------------
 - DEBIT; miJqNkHhC5xsB61gsiSWXeTLnEGSQnWbXB -1 XCP (transfer value)
 - DEBIT; tnDsEWRcV1YXMWAqRREsgs2qwEDbKSqFdj -100 XCP (transfer value)
 - CREDIT; tnDsEWRcV1YXMWAqRREsgs2qwEDbKSqFdj 1 XCP (transfer value)
 - CREDIT; miJqNkHhC5xsB61gsiSWXeTLnEGSQnWbXB 100 XCP (transfer value)
```

But the `output` is actually `2` now, which as you can see in the `crowdfund.sol` contract means the payout was triggred.
You can also see that the `DEBITS / CREDITS` contain your -1 XCP that you contributed,
AND the 100 XCP that the contract payed out (back to the recipient of the contract, which we set to you).
