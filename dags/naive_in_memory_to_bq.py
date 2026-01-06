from airflow import DAG
from airflow.providers.google.cloud.operators.cloud_run import (
    CloudRunExecuteJobOperator,
)
from datetime import datetime

# Prerequisites:
# 1. Enable the Cloud Run Admin API in your GCP project.
# 2. Ensure the Airflow service account has the 'roles/run.admin' permission
#    to create and run jobs.
# 3. The specified Docker image must exist in Google Artifact Registry (GAR).
# 4. The Cloud Run job's runtime service account needs access to the GCS bucket
#    and the BigQuery tables.

with DAG(
    dag_id="naive_in_memory_to_bq",
    start_date=datetime(2024, 1, 1),
    schedule_interval=None,
    catchup=False,
    render_template_as_native_obj=True,
    # Define Airflow Variables for gcp_project_id, gcp_location, and gar_repository
    # to make this DAG configurable without changing code.
) as dag:
    # --- GCP Configuration ---
    GCP_PROJECT_ID = (
        "{{ var.value.get('gcp_project_id', 'project-990b8649-da36-4d4c-9d9') }}"
    )
    GCP_REGION = "{{ var.value.get('gcp_location', 'us-central1') }}"
    GAR_REPOSITORY = "{{ var.value.get('gar_repository', 'my-repo') }}"
    IMAGE_NAME = "naive-app:latest"

    GAR_IMAGE_PATH = (
        f"{GCP_REGION}-docker.pkg.dev/{GCP_PROJECT_ID}/{GAR_REPOSITORY}/{IMAGE_NAME}"
    )

    execute_cloud_run_job = CloudRunExecuteJobOperator(
        task_id="execute_naive_script_on_cloud_run",
        project_id=GCP_PROJECT_ID,
        region=GCP_REGION,
        job_name="naive-in-memory-job-{{ ds_nodash }}",
        image=GAR_IMAGE_PATH,
        arguments=[
            "--input",
            "gs://dummy-data-258083003066/input/sheep_colour_preferences.csv",
            "--output_table",
            f"{GCP_PROJECT_ID}:animal_facts.sheep_colour_preferences_naive",
            "--error_table",
            f"{GCP_PROJECT_ID}:animal_facts.sheep_colour_bad_rows_naive",
        ],
        gcp_conn_id="google_cloud_default",  # Assumes a default GCP connection
    )

