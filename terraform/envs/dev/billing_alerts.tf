resource "google_pubsub_topic" "billing_alerts" {
  name    = "billing-budget-alerts"
  project = var.project_id
}

module "billing_alerts_function" {
  source = "../../modules/functions/billing_alerts"

  project_id = var.project_id
  region     = var.region

  # Pub/Sub topic created for billing budgets
  pubsub_topic = google_pubsub_topic.billing_alerts.id

  # Dedicated service account for the function
  service_account_email = "billing-alerts-sa@project-990b8649-da36-4d4c-9d9.iam.gserviceaccount.com"

  # Secret Manager secret containing the Slack webhook URL
  slack_webhook_secret_name = "slack-billing-webhook"
}
