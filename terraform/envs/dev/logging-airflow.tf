################################################################################
# Airflow VM logging bucket + sink (+ optional metrics)
################################################################################

locals {
  airflow_log_bucket_id = "airflow-longterm"
  airflow_sink_name     = "airflow-to-longterm"

  # Optional metrics
  airflow_error_metric = "airflow_vm_errors"
  airflow_oom_metric   = "airflow_vm_oom_errors"
}

# A) Dedicated Cloud Logging bucket for Airflow VM logs
resource "google_logging_project_bucket_config" "airflow_longterm" {
  # This resource in your environment required the long-form project name
  provider       = google-beta
  project        = "projects/${var.project_id}"
  location       = "global"
  bucket_id      = local.airflow_log_bucket_id
  description    = "Dedicated bucket for Airflow VM logs (gce_instance scoped)"
  retention_days = 30
}

# B) Sink routing Airflow-related VM logs into the bucket
resource "google_logging_project_sink" "airflow_to_longterm" {
  project                = var.project_id
  name                   = local.airflow_sink_name
  destination            = "logging.googleapis.com/projects/${var.project_id}/locations/global/buckets/${google_logging_project_bucket_config.airflow_longterm.bucket_id}"
  unique_writer_identity = true

  # Trial-lab tight-ish scope:
  # - Only GCE instance logs
  # - Only entries that look Airflow-related
  #
  # This avoids dumping *all* VM syslog noise into the bucket while still catching common patterns.

 filter = <<EOT
resource.type="gce_instance"
AND labels.airflow_component="airflow"
AND labels.environment="dev"
EOT

}

################################################################################
# C) Optional metrics
################################################################################

# Counts ERROR+ log entries that look Airflow-related (VM-side)
resource "google_logging_metric" "airflow_vm_errors" {
  project     = var.project_id
  name        = local.airflow_error_metric
  description = "Counts VM logs (gce_instance) that look Airflow-related and are severity>=ERROR"

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "Airflow VM errors"
  }

 filter = <<EOT
resource.type="gce_instance"
AND labels.airflow_component="airflow"
AND (
  jsonPayload.message:"Traceback"
  OR jsonPayload.message:"Broken DAG"
  OR jsonPayload.message:"ERROR"
  OR jsonPayload.message:"Exception"
  OR jsonPayload.message:"Task failed"
)
EOT

}

# Counts OOM-ish patterns on the Airflow VM (separate from Dataflow OOM metric)
resource "google_logging_metric" "airflow_vm_oom_errors" {
  project     = var.project_id
  name        = local.airflow_oom_metric
  description = "Counts VM logs indicating OOM kill / memory exhaustion (gce_instance)"

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "Airflow VM OOM errors"
  }

  filter = <<EOT
resource.type="gce_instance"
AND labels.airflow_component="airflow"
AND (
  jsonPayload.message:"Out of memory"
  OR jsonPayload.message:"OOMKilled"
  OR jsonPayload.message:"Killed process"
  OR jsonPayload.message:"MemoryError"
)
EOT

}


# Allow the Airflow VM service account to write logs via Ops Agent
resource "google_project_iam_member" "airflow_vm_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:airflow-vm@project-990b8649-da36-4d4c-9d9.iam.gserviceaccount.com"
}
