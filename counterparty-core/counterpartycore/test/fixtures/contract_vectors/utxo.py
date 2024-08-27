from counterpartycore.lib import exceptions

from ..params import (
    ADDR,
)

UTXO_VECTOR = {
    "utxo": {
        "compose": [
            {
                "in": (
                    ADDR[0],
                    "344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1",
                    "XCP",
                    100,
                ),
                "out": (
                    "mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
                    [],
                    b"dmn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc|344dcc8909ca3a137630726d0071dfd2df4f7c855bac150c7d3a8367835c90bc:1|XCP|100",
                ),
            },
            {
                "in": (ADDR[0], ADDR[1], "XCP", 100),
                "error": (
                    exceptions.ComposeError,
                    ["If source is an address, destination must be a UTXO"],
                ),
            },
        ]
    }
}
