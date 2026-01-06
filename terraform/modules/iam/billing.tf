resource "google_service_account" "billing_alerts" {
  account_id   = "billing-alerts-sa"
  project      = var.project_id
  display_name = "Billing Alerts Cloud Function"
  description  = "Service account for Cloud Function that sends GCP billing alerts to Slack"
}


resource "google_project_iam_member" "billing_alerts_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.billing_alerts.email}"
}

resource "google_project_iam_member" "billing_logging_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.billing_alerts.email}"
}

resource "google_secret_manager_secret_iam_member" "billing_alerts_slack_webhook_access" {
  secret_id = "slack-billing-webhook"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.billing_alerts.email}"
}
