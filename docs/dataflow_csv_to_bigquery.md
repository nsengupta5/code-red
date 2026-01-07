# Dataflow CSV → BigQuery Ingestion (Apache Beam, Python)

This document explains how to **build, deploy, and run** the scalable, production-grade CSV → BigQuery Dataflow job in this repository.

The job is implemented using **Apache Beam (Python SDK)** and deployed to **Google Cloud Dataflow** using a **Flex Template**. It is designed to safely process **very large CSV files** from GCS without loading them into memory, making it the recommended approach for large-scale data ingestion.

It is orchestrated via an Airflow DAG that uses the `DataflowStartFlexTemplateOperator`.

---

## Overview

**What this job does**

- Reads CSV files from Google Cloud Storage using `ReadFromText`.
- Processes data **line-by-line** in a distributed, memory-safe manner.
- Writes valid rows to a BigQuery table.
- Writes malformed rows to a separate **dead-letter table** for error analysis.
- Is packaged and deployed as a **Flex Template** for easy execution.

---

## Repository Structure (Relevant Parts)

```
.
├── Dockerfile
├── src/
│   └── dataflow/
│       ├── main.py
│       └── requirements.txt
└── dags/
    └── csv_to_bq.py
```

---

## Prerequisites

- Dataflow API, BigQuery API, and Artifact Registry API enabled.
- A BigQuery dataset created.
- A Dataflow worker service account with appropriate permissions (e.g., `roles/dataflow.worker`, `roles/storage.objectAdmin`, `roles/bigquery.dataEditor`).
- An Airflow environment with the Google Cloud provider installed.

---

## Build & Push Docker Image

The primary method for building the Docker image is the CI/CD workflow defined in `.github/workflows/docker-build.yml`. This workflow builds an image and pushes it to the `dataflow-images` GAR repository.

For manual testing, you can use a command like this (requires `docker`):

```bash
# Replace <PROJECT_ID> with your GCP Project ID
docker build \
  -f Dockerfile \
  -t us-central1-docker.pkg.dev/<PROJECT_ID>/dataflow-images/dataflow-app:latest \
  --platform linux/amd64 \
  .
```

---

## Build the Flex Template

After the Docker image is pushed to GAR, you must build the Flex Template specification file and upload it to GCS.

```bash
# Replace <PROJECT_ID> and <GCS_STAGING_BUCKET>
gcloud dataflow flex-template build \
  gs://<GCS_STAGING_BUCKET>/templates/dataflow-app.json \
  --image "us-central1-docker.pkg.dev/<PROJECT_ID>/dataflow-images/dataflow-app:latest" \
  --sdk-language PYTHON \
  --project <PROJECT_ID>
```
*Note: The `--metadata-file` flag can be used if you have one, but is not required for this template.*

---

## Orchestration with Airflow

The job is executed via the `csv_to_bq_dataflow` DAG, which uses the `DataflowStartFlexTemplateOperator`.

- **Operator:** `DataflowStartFlexTemplateOperator`
- **Configuration:** The operator is configured using Airflow Variables (`gcp_project_id`, `gcp_location`, etc.) to locate the template file in GCS and provide the necessary job parameters (input GCS path, output BigQuery tables, etc.).
- **Execution:** When triggered, the DAG makes a request to the Dataflow API to launch the job defined by the Flex Template, passing in all the required runtime parameters.

---

## Summary

This setup provides a **production-grade, memory-safe** CSV ingestion pipeline using Apache Beam and Dataflow, orchestrated cleanly through a dedicated Airflow operator.