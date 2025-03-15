import logging
import os

import requests

from counterpartycore.lib import config

logger = logging.getLogger(config.LOGGER_NAME)


def trigger_webhook():
    webhook_url = os.environ.get("SLACK_HOOK")
    if not webhook_url:
        return False
    try:
        response = requests.get(webhook_url, timeout=10)
        response.raise_for_status()
        logging.info("Message sent to slack")
        return True
    except requests.exceptions.RequestException as e:
        logging.error("Error sending message to slack: %s", e)
        return False
