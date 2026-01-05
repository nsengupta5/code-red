locals {
  function_name = "billing-alerts"
  runtime       = "python311"
}

# -------------------------------------------------------------------
# Package function source
# -------------------------------------------------------------------
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/function"
  output_path = "${path.module}/function.zip"
}

# -------------------------------------------------------------------
# Cloud Function (2nd gen)
# -------------------------------------------------------------------
resource "google_cloudfunctions2_function" "billing_alerts" {
  name     = local.function_name
  location = var.region
  project  = var.project_id

  build_config {
    runtime     = local.runtime
    entry_point = "handle_pubsub"

    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }

  service_config {
    service_account_email = var.service_account_email

    available_memory = "256Mi"
    timeout_seconds = 60

    environment_variables = {
      SLACK_WEBHOOK_SECRET_NAME = var.slack_webhook_secret_name
      PROJECT_ID               = var.project_id
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = var.pubsub_topic
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}

# -------------------------------------------------------------------
# Storage bucket for function source
# -------------------------------------------------------------------
resource "google_storage_bucket" "function_source" {
  name     = "${var.project_id}-cf-src-billing-alerts"
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "billing-alerts.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.function_zip.output_path
}
