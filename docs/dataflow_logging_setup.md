# Dataflow Logging Setup

This document describes the Cloud Logging configuration that has been implemented for **Dataflow logging and OOM error detection** in the Terraform-managed trial test lab project.

---

## Project Context

- **Project ID:** `project-990b8649-da36-4d4c-9d9`
- **Primary region:** `us-central1`
- **Infrastructure management:** Terraform
  - Environment: `terraform/envs/dev/`

The goal of this setup is to:
1. Store Dataflow execution logs in a dedicated Cloud Logging bucket with longer retention.
2. Detect and count Out-Of-Memory (OOM)–related failures using a log-based metric.

---

## 1. Dedicated Cloud Logging Bucket

### Resource
- **Type:** Project-level Cloud Logging bucket
- **Bucket ID:** `dataflow-longterm`
- **Location:** `global`
- **Retention:** 90 days

### Purpose
- Separates Dataflow logs from the default `_Default` bucket.
- Allows independent retention control for Dataflow execution and worker logs.
- Provides a clean scope for querying and future monitoring.

### Notes
- This is **not** a GCS bucket.
- It is a native Cloud Logging bucket managed via Terraform.

---

## 2. Log Sink: Routing Dataflow Logs

### Resource
- **Sink name:** `dataflow-to-longterm`
- **Destination:**
  ```
  logging.googleapis.com/projects/project-990b8649-da36-4d4c-9d9/locations/global/buckets/dataflow-longterm
  ```

### Filter
```text
resource.type="dataflow_step"
```

### What This Captures
- Dataflow worker and step execution logs
- Job lifecycle messages (via `dataflow.googleapis.com/job-message`)
- Logs emitted by Dataflow workers during pipeline execution

### Writer Identity
- **Writer identity:** `None`
- This is expected for **same-project sinks writing to Logging buckets**.
- No additional IAM binding is required for the sink to write logs.

---

## 3. Log-Based Metric: Dataflow OOM Errors

### Metric
- **Name:** `dataflow_oom_errors`
- **Type:** Counter (DELTA)
- **Value type:** INT64

### Purpose
Counts Dataflow log entries that indicate memory exhaustion or container termination due to OOM conditions.

### Filter Logic
The metric matches **Dataflow logs** with severity **ERROR or higher** that contain common OOM patterns:

- `OutOfMemoryError`
- `MemoryError`
- `OOMKilled`
- Linux OOM kill messages (e.g., "Killed process")
- Container termination messages due to memory

### Scope
- Restricted to:
  ```text
  resource.type="dataflow_step"
  ```
- Ensures the metric only tracks Dataflow execution failures.

### Metric Location
In Cloud Monitoring, the metric appears as:

```
logging.googleapis.com/user/dataflow_oom_errors
```

---

## 4. Access & Verification

### Log Access
- Logs can be queried from the custom bucket using:
  - **Logs Explorer** (select bucket `dataflow-longterm`), or
  - `gcloud logging read` with:
    - `--bucket=dataflow-longterm`
    - `--view=_AllLogs`

### IAM for Viewing Logs
- The Airflow VM service account was granted:
  ```
  roles/logging.viewer
  ```
- This allows operational verification and troubleshooting without console access.

---

## 5. Current State Summary

✔ Dedicated Cloud Logging bucket created (90-day retention)

✔ Dataflow logs routed via project sink

✔ Log routing verified with live Dataflow job entries

✔ Log-based OOM error metric created

✔ Permissions validated for log viewing

---

## 6. What This Does *Not* Include (By Design)

- No export to BigQuery or GCS
- No alerting policies (metrics only)
- No enterprise logging features (CMEK, org-level sinks)

This keeps the setup **simple, low-cost, and appropriate for a trial test lab**.

---

## 7. Next Logical Extensions (Not Implemented Yet)

- Separate logging bucket for Airflow (VM-based) logs
- Alerting policy on `dataflow_oom_errors`
- Broader Dataflow filters (e.g., include `dataflow_job` if needed)

---

**Status:** ✅ Dataflow logging and OOM metric setup complete

