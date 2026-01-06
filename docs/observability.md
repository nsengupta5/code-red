# Observability & Cost Control

This document describes the **baseline observability and cost-control setup** for the data platform. The goal is to provide early warning signals for cost overruns and operational issues, while remaining simple, low-noise, and easy to extend as the platform grows.

---

## Goals

- Prevent silent GCP cost overruns
- Provide basic visibility into compute health (CPU / memory)
- Detect high-impact failures (e.g. Out Of Memory errors)
- Demonstrate best practices for new GCP projects
- Keep everything reproducible via Infrastructure as Code (Terraform)

This setup is intentionally **foundational**, not exhaustive.

---

## Scope

**Resources covered:**
- Airflow (self-managed) running on a Compute Engine VM (`airflow-dev`)
- Dataflow jobs and workers

**Environments:**
- Currently: `dev`
- Designed to be reusable for future environments (e.g. `prod`) with minimal changes

---

## Cost Control (Billing Budgets)

### What is implemented

- One **project-scoped billing budget** per GCP project
- Monthly budget (default: `$50`)
- Threshold alerts at:
  - 50% (early warning)
  - 80% (action required)
  - 100% (hard breach)

### Alerting

- **Email alerts** to billing account IAM recipients
- **Pub/Sub notifications** for extensibility (Slack, PagerDuty, etc.)

Both are enabled by default.

### Why this approach

- Project-scoped budgets avoid cross-project noise
- Threshold alerts provide time to react before overspend
- Pub/Sub decouples alert generation from alert delivery

### How to test

1. Temporarily lower the budget amount (e.g. to `$1`)
2. Apply Terraform
3. Confirm:
   - Email alert is received
   - Pub/Sub message is published
4. Restore the original budget amount

---

## Logging & Retention

### Strategy

- Use **Cloud Logging Log Buckets** with extended retention
- Avoid exporting logs to BigQuery or GCS by default
- Retain only logs that are operationally relevant

### Log Bucket

- Bucket name: `data-platform-long-term`
- Retention: **180 days**
- Location: `global`

### Logs Included

Only the following logs are routed to long-term storage:

- **Airflow logs** from the Compute Engine VM:
  - `resource.type = "gce_instance"`
  - `resource.labels.instance_name = "airflow-dev"`

- **Dataflow execution logs**:
  - `resource.type = "dataflow_job"`
  - `resource.type = "dataflow_step"`

This keeps log volume (and cost) under control.

### Verification

1. Trigger an Airflow DAG
2. Run a Dataflow job
3. In Logs Explorer:
   - Select bucket: `data-platform-long-term`
   - Confirm logs appear for both Airflow and Dataflow

---

## OOM Detection (Log-based Metric)

### What is tracked

A log-based **counter metric** that increments when Out Of Memory–related errors appear in logs from:

- Airflow VM (`airflow-dev`)
- Dataflow workers

### Signals matched

The metric looks for common OOM indicators such as:
- `OutOfMemory`
- `OOM`
- `MemoryError`

This is intentionally string-based and conservative.

### Metric name

```
logging.googleapis.com/user/oom_errors
```

### How to test

On the Airflow VM:

```bash
logger "MemoryError: simulated OOM for verification"
```

Then:
- Confirm the log appears in Logs Explorer
- Confirm the `oom_errors` metric increments in Metrics Explorer

---

## Billing Budget → Slack Alerts

Billing budget alerts are delivered via Pub/Sub and forwarded to Slack by a
dedicated Cloud Function. The Slack webhook URL is stored in Secret Manager and
accessed at runtime by the function service account.

Note: Cloud Functions v2 build IAM requirements (restricted projects)
The default Compute Engine service account must have:
roles/logging.logWriter,
roles/storage.objectViewer,
roles/artifactregistry.reader,
roles/artifactregistry.writer.

This is required for Cloud Build workers to:
- fetch staged function sources
- emit build logs
- pull and push Artifact Registry cache images

Failure to grant these roles results in opaque build failures.

Permissioned set here: terraform/envs/dev/cloudfunctions_build_iam.tf

### Cloud Functions Gen 2 invocation model (important)

The billing alert Slack integration is implemented using Cloud Functions Gen 2, which internally runs on Cloud Run and is triggered via Eventarc from Pub/Sub.

For Pub/Sub-triggered Gen 2 functions, Cloud Run must allow unauthenticated invocation (roles/run.invoker granted to allUsers). This is required because Eventarc does not attach an end-user authentication token when delivering events, and Cloud Run will otherwise reject the request before the function code executes.

This configuration does not expose a public HTTP endpoint in practice:

The function has no externally advertised URL

Ingress is restricted to internal Google infrastructure

Only Eventarc can reach the service

No user or workload can invoke the function directly without going through Pub/Sub

This is a documented and recommended pattern for Pub/Sub-triggered Cloud Functions Gen 2 and should not be removed, as doing so will silently break event delivery.

Optional (but very good) follow-up

Right after that section, you may want to add a short “Do not remove” warning box, e.g.:

⚠️ Do not remove allUsers → roles/run.invoker from this service
Removing this binding will cause Pub/Sub events to be rejected with The request was not authenticated, even though IAM roles appear correct.


### Billing budget alert payload nuances

Google Cloud Billing Budget notifications do not always include a threshold value in their event payloads. Depending on the alert type (for example, forecasted spend, actual spend, or monthly reset conditions), the field alertThresholdExceeded may be omitted entirely by the Billing API.

To ensure alerts remain accurate and do not infer or misrepresent billing data, the Slack notification logic preserves the payload faithfully. When a threshold value is not present, the alert will explicitly display:

Threshold exceeded: not provided by billing API

This behaviour is expected and intentional. It reflects upstream API variability rather than an error in the alerting system, and ensures contributors and operators understand when information is unavailable rather than silently guessed.

Billing alerts are delivered with at-least-once semantics, so duplicate notifications may occur. This is normal for Pub/Sub-based delivery and is preferred over the risk of missing cost-related alerts.

---

## Dashboards

### Dashboard: *Data Platform – Compute Health*

A single dashboard providing a high-level view of compute pressure.

### Metrics shown

**Airflow VM (`airflow-dev`):**
- CPU utilization
- Memory utilization (requires Ops Agent)

**Dataflow workers:**
- CPU utilization
- Memory utilization

### Notes

- Memory charts for Airflow require the GCP Ops Agent
- Empty memory charts are acceptable if the agent is not installed
- Dashboards are Terraform-managed for reproducibility

---

## Design Principles

- **Infrastructure as Code first**
- Prefer **simple, explainable signals** over complex heuristics
- Be **cost-aware** with logging and metrics
- Optimize for **low noise** and high signal
- Make extension easy, not mandatory

---

## What Not to Do

- Do not export all logs by default
- Do not add high-cardinality labels to metrics
- Do not create alerts without validating noise
- Do not hardcode environment names when variables suffice

---

## Extending This Setup

### Adding a Production Environment

1. Create a new GCP project
2. Reuse the same Terraform configuration
3. Update variables:
   - `project_id`
   - `monthly_budget_amount`
   - Airflow VM name

No redesign required.

### Adding Alerts

Recommended future alerts:
- `oom_errors > 0`
- Sustained Airflow CPU > 80%
- Sustained Dataflow memory > 85%

These should be added incrementally and validated for noise.

---

## Known Limitations

- OOM detection is string-based and may miss rare edge cases
- Assumes a single Airflow VM
- Dashboards are intentionally high-level

These trade-offs are deliberate for a baseline implementation.

---

## Summary

This observability setup provides:

- Early warning on costs
- Durable, scoped logging
- Detection of critical failure modes
- Clear visual signals for compute health

It is designed to be **trusted, maintainable, and easy to evolve**.

