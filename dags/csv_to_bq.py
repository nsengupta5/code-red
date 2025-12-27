from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

with DAG(
    dag_id="csv_to_bq_dataflow",
    start_date=datetime(2024, 1, 1),
    schedule_interval=None,
    catchup=False,
) as dag:

    run_dataflow = BashOperator(
        task_id="run_dataflow_flex_template",
        bash_command="""
        gcloud dataflow flex-template run csv-to-bq-{{ ds_nodash }} \
          --project project-990b8649-da36-4d4c-9d9 \
          --region us-central1 \
          --template-file-gcs-location gs://dataflow-staging-258083003066/templates/buggy-python-built.json \
          --service-account-email dataflow-worker@project-990b8649-da36-4d4c-9d9.iam.gserviceaccount.com \
          --temp-location gs://dataflow-temp-258083003066/temp \
          --staging-location gs://dataflow-staging-258083003066/staging \
          --parameters input=gs://dummy-data-258083003066/input/sheep_colour_preferences.csv,output_table=project-990b8649-da36-4d4c-9d9:animal_facts.sheep_colour_preferences
        """
    )
