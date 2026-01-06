# Billing alert Cloud Function to send notifications to Slack via webhook.

import base64
import json
import logging
import os
import requests

from google.cloud import secretmanager

logging.basicConfig(level=logging.INFO)

PROJECT_ID = os.environ.get("PROJECT_ID")
SLACK_SECRET_NAME = os.environ.get("SLACK_WEBHOOK_SECRET_NAME")


def get_slack_webhook() -> str:
    """
    Fetch the Slack webhook URL from Secret Manager.
    """
    client = secretmanager.SecretManagerServiceClient()

    secret_path = f"projects/{PROJECT_ID}/secrets/{SLACK_SECRET_NAME}/versions/latest"
    response = client.access_secret_version(request={"name": secret_path})

    return response.payload.data.decode("utf-8")


def format_slack_message(payload: dict) -> dict:
    """
    Convert the billing budget payload into a Slack message.
    """
    budget_name = payload.get("budgetDisplayName", "Unknown budget")
    cost = payload.get("costAmount", "unknown")
    budget = payload.get("budgetAmount", "unknown")
    currency = payload.get("currencyCode", "")
    threshold = data.get("alertThresholdExceeded")

    threshold_text = (
        str(threshold) if threshold is not None else "not provided by billing API"
    )



    text = (
        f":warning: *GCP Billing Alert*\n"
        f"*Budget:* {budget_name}\n"
        f"*Threshold exceeded:* {threshold}\n"
        f"*Current spend:* {cost} {currency}\n"
        f"*Budget limit:* {budget} {currency}"
    )

    return {"text": text}


def handle_pubsub(event, context):
    """
    Entry point for Cloud Functions (2nd gen) Pub/Sub trigger.
    """
    logging.info("Received Pub/Sub event")

    if "data" not in event:
        logging.error("No data field in Pub/Sub message")
        return

    try:
        decoded = base64.b64decode(event["data"]).decode("utf-8")
        payload = json.loads(decoded)
        logging.info("Decoded billing payload: %s", payload)
    except Exception as e:
        logging.exception("Failed to decode Pub/Sub message")
        raise e  # trigger retry

    webhook_url = get_slack_webhook()
    message = format_slack_message(payload)

    response = requests.post(webhook_url, json=message, timeout=10)

    if response.status_code >= 400:
        logging.error(
            "Slack webhook failed: %s %s",
            response.status_code,
            response.text,
        )
        raise RuntimeError("Slack webhook call failed")

    logging.info("Slack notification sent successfully")
