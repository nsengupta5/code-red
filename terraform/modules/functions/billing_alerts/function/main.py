# Billing alert Cloud Function to send notifications to Slack via webhook.
# Supports BOTH:
# - Legacy Pub/Sub (event, context)
# - Cloud Functions Gen 2 / Eventarc (CloudEvent)
#
# This dual support avoids silent invocation failures in Gen 2.

import base64
import json
import logging
import os
from datetime import datetime

import requests
import functions_framework
from google.cloud import secretmanager
from google.cloud import firestore

# -------------------------------------------------------------------
# Global clients
# -------------------------------------------------------------------

db = firestore.Client()

logging.basicConfig(level=logging.INFO)

PROJECT_ID = os.environ.get("PROJECT_ID")
SLACK_SECRET_NAME = os.environ.get("SLACK_WEBHOOK_SECRET_NAME")

# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------

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
    threshold = payload.get("alertThresholdExceeded")

    threshold_text = (
        str(threshold) if threshold is not None else "not provided by billing API"
    )

    text = (
        f":warning: *GCP Billing Alert*\n"
        f"*Budget:* {budget_name}\n"
        f"*Threshold exceeded:* {threshold_text}\n"
        f"*Current spend:* {cost} {currency}\n"
        f"*Budget limit:* {budget} {currency}"
    )

    return {"text": text}


def alert_doc_id(project_id, budget_name, threshold, month):
    safe_budget = budget_name.replace(" ", "_")
    return f"{project_id}__{safe_budget}__{threshold}__{month}"


def already_notified(project_id, budget_name, threshold):
    month = datetime.utcnow().strftime("%Y-%m")
    doc_id = alert_doc_id(project_id, budget_name, threshold, month)
    doc_ref = db.collection("billing_budget_alerts").document(doc_id)
    return doc_ref.get().exists


def record_notification(project_id, budget_name, threshold, data):
    month = datetime.utcnow().strftime("%Y-%m")
    doc_id = alert_doc_id(project_id, budget_name, threshold, month)

    db.collection("billing_budget_alerts").document(doc_id).set({
        "project_id": project_id,
        "budget_name": budget_name,
        "threshold": threshold,
        "currency": data.get("currencyCode"),
        "cost_amount": data.get("costAmount"),
        "budget_amount": data.get("budgetAmount"),
        "notified_at": datetime.utcnow().isoformat() + "Z",
        "month": month,
    })


# -------------------------------------------------------------------
# Core processing logic (shared by all handlers)
# -------------------------------------------------------------------

def process_billing_payload(payload: dict):
    logging.info("Processing billing payload")

    budget_name = payload.get("budgetDisplayName", "unknown-budget")
    threshold = payload.get("alertThresholdExceeded")

    if threshold is None:
        logging.info("No threshold exceeded — skipping notification")
        return "OK"

    project_id = PROJECT_ID

    if already_notified(project_id, budget_name, threshold):
        logging.info(
            "Duplicate alert suppressed: %s threshold=%s",
            budget_name,
            threshold,
        )
        return "OK"

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

    record_notification(project_id, budget_name, threshold, payload)

    logging.info(
        "Slack notification sent and recorded: %s threshold=%s",
        budget_name,
        threshold,
    )

    return "OK"


# -------------------------------------------------------------------
# Legacy Gen 1-style Pub/Sub handler (kept for compatibility)
# -------------------------------------------------------------------

def handle_pubsub(event, context):
    """
    Legacy Pub/Sub handler (event, context).
    Retained for safety — NOT reliably invoked in Gen 2.
    """
    logging.info("Received legacy Pub/Sub event")

    if "data" not in event:
        logging.error("No data field in Pub/Sub message")
        return "OK"

    decoded = base64.b64decode(event["data"]).decode("utf-8")
    payload = json.loads(decoded)

    logging.info("Decoded billing payload: %s", payload)
    return process_billing_payload(payload)


# -------------------------------------------------------------------
# Cloud Functions Gen 2 / Eventarc handler (REQUIRED)
# -------------------------------------------------------------------

@functions_framework.cloud_event
def handle_pubsub_cloudevent(cloud_event):
    """
    Cloud Functions Gen 2 Pub/Sub handler (CloudEvent format).
    This is the authoritative entrypoint in Gen 2.
    """
    logging.info("Received Pub/Sub CloudEvent")

    message = cloud_event.data.get("message", {})
    if "data" not in message:
        logging.error("No data field in CloudEvent Pub/Sub message")
        return "OK"

    decoded = base64.b64decode(message["data"]).decode("utf-8")
    payload = json.loads(decoded)

    logging.info("Decoded billing payload: %s", payload)
    return process_billing_payload(payload)



@functions_framework.http
def healthcheck(request):
    logging.info("HTTP handler invoked")
    return "ok", 200
