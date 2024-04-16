# Release Notes - Counterparty Core v10.1.1 (2024-04-??)

# ChangeLog

## Bugfixes
* No longer automatically uses `None` for missing arguments during an RPC call to `create_*`. Instead we use the default value defined in the signature of the corresponding `*.compose()` function. If no default value is defined the parameter is mandatory.

## Codebase


## Command-Line Interface


# Credits
* Ouziel Slama
* Adam Krellenstein
* Warren Puffett
* Matt Marcello
