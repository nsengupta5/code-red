variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "pubsub_topic" {
  type        = string
  description = "Pub/Sub topic ID for billing alerts"
}

variable "service_account_email" {
  type        = string
  description = "Service account for the Cloud Function"
}

variable "slack_webhook_secret_name" {
  type        = string
  description = "Secret Manager secret name holding the Slack webhook URL"
}
