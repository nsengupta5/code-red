# Naive In-Memory CSV → BigQuery Ingestion

This document explains the **naive in-memory processing pipeline**.

This pipeline is intentionally designed as an **anti-pattern**. It reads an entire CSV file from GCS into memory before processing. Its purpose is to demonstrate a non-scalable approach that is likely to fail with an **Out-of-Memory (OOM) error** when run against large files.

The pipeline is orchestrated via an Airflow DAG that triggers a **Google Cloud Run Job**.

---

## Overview

**What this job does**

- Downloads an entire CSV file from Google Cloud Storage into a single in-memory variable.
- Iterates through the file line-by-line, appending parsed rows to in-memory lists (`good_rows` and `bad_rows`).
- After processing the entire file, it attempts to load the contents of the in-memory lists into BigQuery.
- Is packaged as a Docker container and run as a serverless **Cloud Run Job**.

**Why this is an anti-pattern**

- **High Memory Usage:** The script's memory footprint scales directly with the input file size. It holds the data in memory multiple times (as a raw string, as a list of lines, and as lists of parsed dictionaries).
- **Not Scalable:** This approach will quickly exhaust available memory and crash when processing files that are larger than the available RAM of the execution environment.
- **Inefficient:** It is far less efficient than stream processing, as it cannot begin processing until the entire file is downloaded.

---

## Repository Structure (Relevant Parts)

```
.
├── Dockerfile.naive
├── src/
│   └── naive/
│       ├── main.py
│       └── requirements.txt
└── dags/
    └── naive_in_memory_to_bq.py
```

---

## Prerequisites

- **Cloud Run API** enabled.
- **Artifact Registry API** enabled.
- **Airflow Environment** with the Google Cloud provider installed (`apache-airflow-providers-google`).
- **Airflow Variables** set for `gcp_project_id`, `gcp_location`, and `gar_repository`.
- **Airflow Service Account** with `roles/run.admin` to create and execute Cloud Run Jobs.
- **Cloud Run Runtime Service Account** with permissions to:
  - Read from the GCS bucket (`roles/storage.objectViewer`).
  - Write to the BigQuery tables (`roles/bigquery.dataEditor`).
- **Docker Image** built from `Dockerfile.naive` and pushed to the specified GAR repository (e.g., `naive-images`).

---

## The Dockerfile (`Dockerfile.naive`)

The Dockerfile packages the Python script and its direct dependencies.

- **Base Image:** `python:3.9-slim`
- **Dependencies:** `google-cloud-storage`, `google-cloud-bigquery`
- **Entrypoint:** The container runs `python main.py` on startup.

---

## The Airflow DAG (`naive_in_memory_to_bq.py`)

The DAG orchestrates the pipeline using the `CloudRunExecuteJobOperator`.

- **Trigger:** Can be run manually from the Airflow UI.
- **Task:** The `execute_cloud_run_job` task starts a new Cloud Run Job.
- **Configuration:**
  - It pulls the container image from the GAR path defined by Airflow Variables.
  - It passes the GCS input path and BigQuery output tables as command-line arguments to the script running inside the container.
  - The job name is dynamically created for each run (e.g., `naive-in-memory-job-20240101`).

---

## How to Run

1.  **Build and Push the Image:** Use the `.github/workflows/docker-build.yml` workflow (or run `docker build` manually) to create the `naive-app` image and push it to your `naive-images` GAR repository.
2.  **Configure Airflow:** Ensure all prerequisites (APIs, Service Accounts, Variables) are in place.
3.  **Trigger the DAG:** Run the `naive_in_memory_to_bq` DAG from the Airflow UI.

---

## Expected Outcome

- For **small files**, the job will succeed, and data will be loaded into BigQuery.
- For **large files**, the Cloud Run Job is expected to fail with an Out-of-Memory error, demonstrating the limitations of this naive approach.

---

## Summary

This setup provides a clear example of an **inefficient, non-scalable** data processing pattern. It serves as a useful counter-example to the robust, stream-based processing provided by the Apache Beam / Dataflow pipeline.
