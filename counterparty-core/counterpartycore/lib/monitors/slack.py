import logging
import os

import requests

from counterpartycore.lib import config
from counterpartycore.lib.utils import helpers

logger = logging.getLogger(config.LOGGER_NAME)


def send_slack_message(message):
    # Get the webhook URL from environment variables
    webhook_url = os.environ.get("SLACK_HOOK")
    if not webhook_url:
        return False

    # Get the current commit hash and append to message if available
    current_commit = helpers.get_current_commit_hash()
    final_message = message
    if current_commit:
        final_message = f"{message}\n{current_commit}"

    # Prepare the data to send
    payload = {"text": final_message}

    try:
        # Send the POST request to the webhook
        response = requests.post(
            webhook_url,
            json=payload,
            timeout=10,
        )

        # Check if the request was successful
        if response.status_code != 200:
            raise ValueError(f"Error sending message: {response.status_code}, {response.text}")

    except Exception:
        # Re-raise any exceptions that occur
        raise

    return True
