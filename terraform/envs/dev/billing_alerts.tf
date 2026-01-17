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


resource "google_cloud_run_service_iam_member" "billing_alerts_eventarc_invoker" {
  project  = var.project_id
  location = var.region
  service  = module.billing_alerts_function.cloud_run_service_name

  role   = "roles/run.invoker"
  member = "serviceAccount:service-${var.project_number}@gcp-sa-eventarc.iam.gserviceaccount.com"
}
