# Dataflow CSV → BigQuery Ingestion (Apache Beam, Python)

This document explains how to **build, deploy, and run** the CSV → BigQuery Dataflow job in this repository.

The job is implemented using **Apache Beam (Python SDK)** and deployed to **Google Cloud Dataflow** using a **Flex Template**.  
It is designed to safely process **very large CSV files** from GCS without loading them into memory.

---

## Overview

**What this job does**

- Reads CSV files from Google Cloud Storage using `ReadFromText`
- Processes data **line-by-line** (distributed, memory-safe)
- Writes valid rows to BigQuery
- Writes malformed rows to a **dead-letter table**
- Runs on Dataflow using a **custom worker service account**
- Is packaged and deployed as a **Flex Template**

---

## Repository Structure (Relevant Parts)

```
.
├── Dockerfile
├── requirements.txt
├── src/
│   └── main.py
├── dataflow_metadata.json
├── terraform/
│   ├── modules/
│   └── envs/dev/
└── docs/
    └── dataflow_csv_to_bigquery.md
```

---

## Prerequisites

- Dataflow API enabled
- BigQuery API enabled
- Artifact Registry API enabled
- BigQuery dataset created
- Dataflow worker service account with:
  - roles/dataflow.worker
  - roles/storage.objectAdmin
  - roles/bigquery.dataEditor
  - roles/bigquery.jobUser
  - roles/artifactregistry.reader

---

## Input Data Layout

Recommended layout:

```
gs://dummy-data-<PROJECT_NUMBER>/
└── input/
    └── sheep_colour_preferences.csv
```

---

## Build & Push Docker Image

Dataflow workers require **linux/amd64** images.

```bash
docker buildx build \
  --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/<PROJECT_ID>/buggy-python/buggy-oom:latest \
  --push .
```

---

## Build the Flex Template

```bash
gcloud dataflow flex-template build \
  gs://dataflow-staging-<PROJECT_NUMBER>/templates/buggy-python-built.json \
  --image us-central1-docker.pkg.dev/<PROJECT_ID>/buggy-python/buggy-oom:latest \
  --sdk-language PYTHON \
  --metadata-file dataflow_metadata.json \
  --project <PROJECT_ID>
```

---

## Run the Dataflow Job

```bash
gcloud dataflow flex-template run csv-to-bq-test \
  --project <PROJECT_ID> \
  --region us-central1 \
  --template-file-gcs-location gs://dataflow-staging-<PROJECT_NUMBER>/templates/buggy-python-built.json \
  --service-account-email dataflow-worker@<PROJECT_ID>.iam.gserviceaccount.com \
  --num-workers 1 \
  --temp-location gs://dataflow-temp-<PROJECT_NUMBER>/temp \
  --staging-location gs://dataflow-staging-<PROJECT_NUMBER>/staging \
  --parameters input=gs://dummy-data-<PROJECT_NUMBER>/input/sheep_colour_preferences.csv,output_table=<PROJECT_ID>:animal_facts.sheep_colour_preferences,error_table=<PROJECT_ID>:animal_facts.sheep_colour_bad_rows
```

---

## Output

- Valid rows written to BigQuery main table
- Invalid rows written to dead-letter table
- Job continues even with malformed input rows

---

## Summary

This setup provides a **production-grade, memory-safe** CSV ingestion pipeline using Apache Beam and Dataflow.
