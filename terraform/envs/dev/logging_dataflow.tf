################################################################################
# Dataflow long-term-ish logging bucket + routing sink + OOM log-based metric
################################################################################

locals {
  dataflow_log_bucket_id = "dataflow-longterm"
  dataflow_sink_name     = "dataflow-to-longterm"
  dataflow_oom_metric    = "dataflow_oom_errors"

}



# 1) Dedicated log bucket (project-level)
resource "google_logging_project_bucket_config" "dataflow_longterm" {
  project        = "projects/${var.project_id}"
  location       = "global"
  bucket_id      = local.dataflow_log_bucket_id
  description    = "Dedicated bucket for Dataflow execution/worker logs"
  retention_days = 90
}

# 2) Sink that routes Dataflow logs into the dedicated bucket
resource "google_logging_project_sink" "dataflow_to_longterm" {
  project                = var.project_id
  name                   = local.dataflow_sink_name
  destination            = "logging.googleapis.com/projects/${var.project_id}/locations/global/buckets/${google_logging_project_bucket_config.dataflow_longterm.bucket_id}"
  unique_writer_identity = true

  filter = <<EOT
resource.type="dataflow_step"
EOT
}


# 3) Log-based metric (counter) for OOM patterns in Dataflow logs
resource "google_logging_metric" "dataflow_oom_errors" {
  project     = var.project_id
  name        = local.dataflow_oom_metric
  description = "Counts Dataflow logs that match common out-of-memory patterns (OOMKilled, OutOfMemoryError, MemoryError, etc.)"

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "Dataflow OOM errors"
  }

  filter = <<EOT
resource.type="dataflow_step"
AND (
  textPayload:"OutOfMemoryError"
  OR textPayload:"MemoryError"
  OR textPayload:"OOMKilled"
  OR (textPayload:"Killed process" AND textPayload:"oom")
  OR jsonPayload.message:"OutOfMemoryError"
  OR jsonPayload.message:"MemoryError"
  OR jsonPayload.message:"OOMKilled"
  OR (jsonPayload.message:"Killed process" AND jsonPayload.message:"oom")
)
AND NOT (
  textPayload:"Finish parsing log monitor config file"
  OR textPayload:"kernel-monitor.json"
  OR textPayload:"log_monitor.go:78"
  OR textPayload:"Rules:[{Type:temporary Condition: Reason:OOMKilling"
  OR jsonPayload.message:"Finish parsing log monitor config file"
  OR jsonPayload.message:"kernel-monitor.json"
  OR jsonPayload.message:"log_monitor.go:78"
  OR jsonPayload.message:"Rules:[{Type:temporary Condition: Reason:OOMKilling"
)
EOT
}

