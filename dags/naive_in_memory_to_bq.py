from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

with DAG(
    dag_id="naive_in_memory_to_bq",
    start_date=datetime(2024, 1, 1),
    schedule_interval=None,
    catchup=False,
) as dag:

    run_naive_script = BashOperator(
        task_id="run_naive_in_memory_script",
        bash_command="""
        python /data/data/com.termux/files/home/Documents/code-red/src/naive_in_memory.py \
          --input gs://dummy-data-258083003066/input/sheep_colour_preferences.csv \
          --output_table project-990b8649-da36-4d4c-9d9:animal_facts.sheep_colour_preferences_naive \
          --error_table project-990b8649-da36-4d4c-9d9:animal_facts.sheep_colour_bad_rows_naive
        """
    )

