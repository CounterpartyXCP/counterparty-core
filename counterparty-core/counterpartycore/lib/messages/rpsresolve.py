import logging

from counterpartycore.lib import config

from . import rps

logger = logging.getLogger(config.LOGGER_NAME)

# move random rps_match_id
ID = 81


def parse(db, tx):
    rps.parse(db, tx)
