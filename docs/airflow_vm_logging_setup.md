# Airflow VM Logging Setup

This document describes how **Airflow logs running on a standalone VM** are ingested, routed, and stored using **Google Cloud Logging**, fully managed via Terraform and the Google Ops Agent.

---

## Project Context

- **Project ID:** `project-990b8649-da36-4d4c-9d9`
- **Environment:** `dev`
- **Region / Zone:** `us-central1 / us-central1-a`
- **Airflow host:** `airflow-dev` (Compute Engine VM)
- **Infrastructure management:** Terraform (`terraform/envs/dev`)

Airflow is **not running on GKE**. Logs are written locally to disk on the VM under:

```
/opt/airflow/logs/
```

---

## High-level Architecture

```
Airflow (VM)
  └─ writes logs to /opt/airflow/logs/
        └─ Google Ops Agent (fluent-bit)
              └─ Cloud Logging (gce_instance)
                    └─ Project Sink
                          └─ airflow-longterm Log Bucket
                                └─ Log-based Metrics
```

Key goals:
- Ingest **file-based Airflow logs** into Cloud Logging
- Store them in a **dedicated log bucket** with independent retention
- Enable **metrics** for errors and OOM-style failures

---

## 1. Cloud Logging Bucket

### Resource
- **Bucket ID:** `airflow-longterm`
- **Location:** `global`
- **Retention:** 30 days

### Purpose
- Separates Airflow logs from default logging buckets
- Enables independent retention and querying
- Provides a clean boundary for metrics and future alerts

---

## 2. Cloud Logging Sink

### Resource
- **Sink name:** `airflow-to-longterm`
- **Destination:**

```
logging.googleapis.com/projects/project-990b8649-da36-4d4c-9d9/locations/global/buckets/airflow-longterm
```

### Final Sink Filter

```text
resource.type="gce_instance"
AND labels.airflow_component="airflow"
AND labels.environment="dev"
```

### Notes
- Sink routes **only Airflow-related VM logs**
- Relies on labels added by the Ops Agent (see below)
- Writer identity is `None` (expected for same-project Logging bucket sinks)

---

## 3. Ops Agent Installation (on the VM)

### Install the Google Ops Agent

```bash
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
```

Verify:

```bash
systemctl status google-cloud-ops-agent
```

### Required IAM

The VM service account must have:

```
roles/logging.logWriter
```

This allows the agent to write logs into Cloud Logging.

---

## 4. Ops Agent Logging Configuration

### Config file location

```
/etc/google-cloud-ops-agent/config.yaml
```

### Final configuration (lab-safe, deterministic)

```yaml
logging:
  receivers:
    airflow_scheduler:
      type: files
      include_paths:
        - /opt/airflow/logs/scheduler/*/*.log
      record_log_file_path: true

    airflow_dag_processor:
      type: files
      include_paths:
        - /opt/airflow/logs/dag_processor_manager/*.log
      record_log_file_path: true

    airflow_tasks:
      type: files
      include_paths:
        - /opt/airflow/logs/dag_id=*/*/*/*/log*
        - /opt/airflow/logs/dag_id=*/*/*/*/*/log*
        - /opt/airflow/logs/dag_id=*/*/*/*/*/*/log*
      record_log_file_path: true

  processors:
    airflow_common_labels:
      type: modify_fields
      fields:
        labels.airflow_component:
          static_value: airflow
        labels.environment:
          static_value: dev

  service:
    pipelines:
      airflow_pipeline:
        receivers:
          - airflow_scheduler
          - airflow_dag_processor
          - airflow_tasks
        processors:
          - airflow_common_labels
```

### Restart logging pipeline

```bash
sudo systemctl restart google-cloud-ops-agent-fluent-bit
```

---

## 5. Log Shape in Cloud Logging

Example ingested log entry:

- **resource.type:** `gce_instance`
- **jsonPayload.message:** Airflow log line
- **labels.airflow_component:** `airflow`
- **labels.environment:** `dev`
- **labels.agent.googleapis.com/log_file_path:** original log file path

Severity is **not automatically parsed** from file logs; messages may contain `ERROR` text but default severity is used.

---

## 6. Log-based Metrics

### airflow_vm_errors

Counts Airflow-related error patterns from VM logs.

**Filter (severity-agnostic):**

```text
resource.type="gce_instance"
AND labels.airflow_component="airflow"
AND (
  jsonPayload.message:"Traceback"
  OR jsonPayload.message:"Broken DAG"
  OR jsonPayload.message:"Exception"
  OR jsonPayload.message:"Task failed"
  OR jsonPayload.message:"ERROR "
)
```

Metric name:
```
logging.googleapis.com/user/airflow_vm_errors
```

---

### airflow_vm_oom_errors

Counts memory exhaustion / OOM-style failures on the Airflow VM.

**Filter:**

```text
resource.type="gce_instance"
AND labels.airflow_component="airflow"
AND (
  jsonPayload.message:"Out of memory"
  OR jsonPayload.message:"OOMKilled"
  OR jsonPayload.message:"Killed process"
  OR jsonPayload.message:"MemoryError"
)
```

Metric name:
```
logging.googleapis.com/user/airflow_vm_oom_errors
```

---

## 7. Verification Commands

### Project-wide log check

```bash
gcloud logging read 'resource.type="gce_instance" AND labels.airflow_component="airflow"' \
  --project=project-990b8649-da36-4d4c-9d9 \
  --freshness=30m --limit=20
```

### Bucket-scoped log check

```bash
gcloud logging read 'labels.airflow_component="airflow"' \
  --project=project-990b8649-da36-4d4c-9d9 \
  --location=global \
  --bucket=airflow-longterm \
  --view=_AllLogs \
  --freshness=30m --limit=20
```

### End-to-end test (safe)

```bash
echo 'ERROR airflow E2E_TEST_OOM MemoryError: simulated test' >> /opt/airflow/logs/scheduler/YYYY-MM-DD/file.log
```

---

## 8. Current State Summary

✔ Ops Agent installed and running

✔ Airflow file logs ingested into Cloud Logging

✔ Logs labeled for deterministic routing

✔ Sink routes logs into `airflow-longterm` bucket

✔ Error and OOM metrics working end-to-end

---

## 9. Intentional Non-goals (Trial Lab)

- No severity parsing from log text
- No alerting policies (metrics only)
- No BigQuery exports
- No org-level logging configuration

This setup is intentionally **simple, robust, and low-cost**, suitable for experimentation and debugging.

---

**Status:** ✅ Airflow VM logging fully implemented and verified

