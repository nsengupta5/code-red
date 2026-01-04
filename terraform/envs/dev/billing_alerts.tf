resource "google_pubsub_topic" "billing_alerts" {
  name    = "billing-budget-alerts"
  project = var.project_id
}
