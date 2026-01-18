################################################################################
# Cloud Monitoring Dashboards
# - Airflow VM (airflow-dev): CPU + Memory + Airflow OOM metric
# - Dataflow (all jobs in us-central1): Worker utilization + Memory capacity + Dataflow OOM metric
################################################################################

resource "google_monitoring_dashboard" "airflow_vm_dashboard" {
  project = var.project_id

  dashboard_json = jsonencode({
    displayName = "Airflow VM – airflow-dev (CPU, Memory, OOM metric)"
    gridLayout = {
      columns = 2
      widgets = [
        # CPU utilization (Ops Agent)
        {
          title = "CPU utilization – airflow-dev"
          xyChart = {
            dataSets = [{
              plotType = "LINE"
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = join(" AND ", [
                    "resource.type=\"gce_instance\"",
                    "resource.labels.instance_id=\"5536934707077466092\"",
                    "resource.labels.zone=\"us-central1-a\"",
                    "metric.type=\"agent.googleapis.com/cpu/utilization\""
                  ])
                  aggregation = {
                    alignmentPeriod  = "60s"
                    perSeriesAligner = "ALIGN_MEAN"
                  }
                }
              }
            }]
            yAxis = { label = "utilization", scale = "LINEAR" }
          }
        },

        # Memory used percent (Ops Agent)
        {
          title = "Memory used (%) – airflow-dev"
          xyChart = {
            dataSets = [{
              plotType = "LINE"
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = join(" AND ", [
                    "resource.type=\"gce_instance\"",
                    "resource.labels.instance_id=\"5536934707077466092\"",
                    "resource.labels.zone=\"us-central1-a\"",
                    "metric.type=\"agent.googleapis.com/memory/percent_used\"",
                    "metric.labels.state=\"used\""
                  ])
                  aggregation = {
                    alignmentPeriod  = "60s"
                    perSeriesAligner = "ALIGN_MEAN"
                  }
                }
              }
            }]
            yAxis = { label = "%", scale = "LINEAR" }
          }
        },

        # Airflow OOM log-based metric (your custom metric)
        {
            title = "Airflow VM OOM errors (log-based metric)"
            xyChart = {
                dataSets = [{
                plotType = "LINE"
                timeSeriesQuery = {
                    timeSeriesFilter = {
                    filter = join(" AND ", [
                        "resource.type=\"gce_instance\"",
                        "resource.labels.instance_id=\"5536934707077466092\"",
                        "resource.labels.zone=\"us-central1-a\"",
                        "metric.type=\"logging.googleapis.com/user/airflow_vm_oom_errors\""
                    ])
                    aggregation = {
                        alignmentPeriod  = "60s"
                        perSeriesAligner = "ALIGN_DELTA"
                    }
                    }
                }
                }]
                yAxis = { label = "count/min", scale = "LINEAR" }
            }
        }
      ]
    }
  })
}

resource "google_monitoring_dashboard" "dataflow_dashboard" {
  project = var.project_id

  dashboard_json = jsonencode({
    displayName = "Dataflow – all jobs (us-central1) + OOM metric"
    gridLayout = {
      columns = 2
      widgets = [
        # Dataflow Current number of vCPUs in use (all jobs in us-central1)
        {
            title = "Current number of vCPUs in use – all Dataflow jobs"
            xyChart = {
                dataSets = [{
                plotType = "LINE"
                timeSeriesQuery = {
                    timeSeriesQueryLanguage = <<-MQL
                    fetch dataflow_job
                    | metric 'dataflow.googleapis.com/job/current_num_vcpus'
                    | group_by [], mean(val())
                    | every 60s
                    MQL
                }
                }]
                yAxis = { label = "vCPUs", scale = "LINEAR" }
            }
        },


        # Dataflow memory capacity (all jobs in us-central1)
        {
          title = "Memory capacity (bytes) – all Dataflow jobs (us-central1)"
          xyChart = {
            dataSets = [{
              plotType = "LINE"
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = join(" AND ", [
                    "resource.type=\"dataflow_job\"",
                    "resource.labels.region=\"us-central1\"",
                    "metric.type=\"dataflow.googleapis.com/job/memory_capacity\""
                  ])
                  aggregation = {
                    alignmentPeriod  = "60s"
                    perSeriesAligner = "ALIGN_MEAN"
                  }
                }
              }
            }]
            yAxis = { label = "bytes", scale = "LINEAR" }
          }
        },

        # Dataflow OOM log-based metric (your custom metric)
        {
            title = "Dataflow OOM errors (log-based metric)"
            xyChart = {
                dataSets = [{
                plotType = "LINE"
                timeSeriesQuery = {
                    timeSeriesQueryLanguage = <<-MQL
                    fetch global
                    | metric 'logging.googleapis.com/user/dataflow_oom_errors'
                    | group_by [], sum(val())
                    | every 60s
                    MQL
                }
                }]
                yAxis = { label = "count/min", scale = "LINEAR" }
            }
        }
      ]
    }
  })
}
