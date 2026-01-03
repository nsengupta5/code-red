# Project Overview

This project implements a data pipeline to process CSV files from Google Cloud Storage (GCS) and load them into BigQuery. The pipeline is orchestrated using Apache Airflow and the data processing is done with Apache Beam on Google Cloud Dataflow. The underlying infrastructure is managed using Terraform.

## Key Technologies

*   **Data Processing:** Apache Beam (Python SDK)
*   **Orchestration:** Apache Airflow
*   **Cloud Provider:** Google Cloud Platform (GCP)
*   **Infrastructure as Code:** Terraform

## Architecture

1.  **Terraform:** Provisions the necessary GCP resources, including GCS buckets, BigQuery datasets and tables, and service accounts.
2.  **Airflow:** A DAG (`dags/csv_to_bq.py`) is defined to trigger the Dataflow job. This DAG uses a `BashOperator` to execute a `gcloud` command.
3.  **Dataflow:** The `gcloud` command starts a Dataflow Flex Template. The template runs an Apache Beam pipeline defined in `src/main.py`.
4.  **Apache Beam Pipeline:**
    *   Reads CSV files from a specified GCS bucket.
    *   Parses each row of the CSV.
    *   Valid data is written to a BigQuery table.
    *   Invalid data (malformed rows) is written to a separate "bad rows" BigQuery table for error analysis.

# Building and Running

The project is deployed and run on Google Cloud Platform. The main components are:

*   **Infrastructure:** The GCP infrastructure is deployed using Terraform. The Terraform configuration is located in the `terraform` directory.
*   **Dataflow Job:** The Apache Beam pipeline is executed as a Dataflow job. The job is started by the Airflow DAG.
*   **Airflow DAG:** The Airflow DAG is located in the `dags` directory. This DAG needs to be deployed to a running Airflow instance.

To run the pipeline, you need to:

1.  Deploy the infrastructure using Terraform.
2.  Deploy the Airflow DAG to your Airflow environment.
3.  Trigger the `csv_to_bq_dataflow` DAG in Airflow.

# Development Conventions

*   **Python:** The data processing logic is written in Python using the Apache Beam SDK.
*   **Terraform:** The infrastructure is defined as code using Terraform.
*   **Airflow:** The pipeline orchestration is defined in a Python file as an Airflow DAG.
*   **CI/CD:** GitHub Actions is used for continuous integration and deployment. The workflows are defined in the `.github/workflows` directory.
