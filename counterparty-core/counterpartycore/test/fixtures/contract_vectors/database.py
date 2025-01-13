from counterpartycore.lib import config

DATABASE_VECTOR = {
    "database": {
        "version": [{"in": (), "out": (config.VERSION_MAJOR, config.VERSION_MINOR)}],
        "update_version": [
            {
                "in": (),
                "records": [
                    {
                        "table": "pragma",
                        "field": "user_version",
                        "value": (config.VERSION_MAJOR * 1000) + config.VERSION_MINOR,
                    }
                ],
            }
        ],
    },
}
