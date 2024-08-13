from ..params import (
    ADDR,
)

# source
# asset
# quantity,

FAIRMINT_VECTOR = {
    "fairmint": {
        "validate": [
            {
                "in": (
                    ADDR[1],  # source
                    "FREEFAIRMIN",  # asset
                    0,  # quantity
                ),
                "out": ([]),
            },
            {
                "in": (
                    ADDR[1],  # source
                    "PAIDFAIRMIN",  # asset
                    0,  # quantity
                ),
                "out": (["Quantity must be greater than 0"]),
            },
        ]
    }
}
