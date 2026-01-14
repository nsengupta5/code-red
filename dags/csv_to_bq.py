from airflow import DAG
from airflow.providers.google.cloud.operators.dataflow import (
    DataflowStartFlexTemplateOperator,
)
from datetime import datetime

# This DAG requires the Google Cloud provider to be installed in your Airflow environment:
# pip install apache-airflow-providers-google

with DAG(
    dag_id="csv_to_bq_dataflow",
    start_date=datetime(2024, 1, 1),
    schedule_interval=None,
    catchup=False,
    render_template_as_native_obj=True,
) as dag:
    # --- GCP Configuration ---
    # Using Airflow Variables for these settings is a best practice.
    GCP_PROJECT_ID = (
        "{{ var.value.get('gcp_project_id', 'project-990b8649-da36-4d4c-9d9') }}"
    )
    GCP_REGION = "{{ var.value.get('gcp_location', 'us-central1') }}"
    GCS_STAGING_BUCKET = "{{ var.value.get('dataflow_staging_bucket', 'gs://dataflow-staging-258083003066') }}"
    DATAFLOW_WORKER_SA = "{{ var.value.get('dataflow_worker_sa', 'dataflow-worker@project-990b8649-da36-4d4c-9d9.iam.gserviceaccount.com') }}"

    # The GCS path to the Flex Template JSON file. This file is generated when you
    # build the Dataflow template.
    TEMPLATE_GCS_PATH = f"{GCS_STAGING_BUCKET}/templates/buggy-python-built.json"

    start_flex_template_job = DataflowStartFlexTemplateOperator(
        task_id="start_dataflow_flex_template",
        project_id=GCP_PROJECT_ID,
        location=GCP_REGION,
        gcp_conn_id="google_cloud_default",
        body={
            "launchParameter": {
                "jobName": "csv-to-bq-{{ ds_nodash }}",
                "containerSpecGcsPath": TEMPLATE_GCS_PATH,
                "parameters": {
                    "input": "gs://dummy-data-258083003066/input/sheep_colour_preferences.csv",
                    "output_table": f"{GCP_PROJECT_ID}.animal_facts.sheep_colour_preferences",
                    "error_table": f"{GCP_PROJECT_ID}.animal_facts.sheep_colour_bad_rows",
                },
                "environment": {
                    "serviceAccountEmail": DATAFLOW_WORKER_SA,
                    "tempLocation": f"{GCS_STAGING_BUCKET}/temp",
                    "stagingLocation": f"{GCS_STAGING_BUCKET}/staging",
                },
            }
        },
    )

