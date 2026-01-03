import argparse
import csv
import io
from google.cloud import bigquery
from google.cloud import storage


def parse_csv_safe(line, good_rows, bad_rows):
    if not line.strip():
        return

    try:
        reader = csv.reader(io.StringIO(line))
        fields = next(reader)

        good_rows.append(
            {
                "sheep_id": fields[0],
                "breed": fields[1],
                "colour": fields[2],
                "weight": float(fields[3]),
                "preference_score": float(fields[4]),
            }
        )

    except Exception as e:
        bad_rows.append(
            {
                "raw_line": line,
                "error": str(e),
            }
        )


def run(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input",
        required=True,
        help="GCS path to input CSV file (e.g. gs://bucket/input/file.csv)"
    )
    parser.add_argument(
        "--output_table",
        required=True,
        help="BigQuery table spec for valid rows: project:dataset.table"
    )
    parser.add_argument(
        "--error_table",
        required=False,
        help="BigQuery table spec for bad rows: project:dataset.bad_rows"
    )
    args = parser.parse_args(argv)

    storage_client = storage.Client()
    bigquery_client = bigquery.Client()

    # In-memory lists
    good_rows = []
    bad_rows = []

    # Download the file from GCS into memory
    bucket_name, blob_name = args.input.replace("gs://", "").split("/", 1)
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    content = blob.download_as_text()

    # Read the file line by line from memory
    lines = content.splitlines()
    header = lines[0]
    data_lines = lines[1:]

    for line in data_lines:
        parse_csv_safe(line, good_rows, bad_rows)

    # Load good rows to BigQuery
    if good_rows:
        output_table = bigquery_client.get_table(args.output_table)
        errors = bigquery_client.insert_rows_json(output_table, good_rows)
        if errors:
            print(f"Errors inserting good rows: {errors}")

    # Load bad rows to BigQuery
    if bad_rows and args.error_table:
        error_table = bigquery_client.get_table(args.error_table)
        errors = bigquery_client.insert_rows_json(error_table, bad_rows)
        if errors:
            print(f"Errors inserting bad rows: {errors}")

    print(f"Loaded {len(good_rows)} rows to {args.output_table}")
    if args.error_table:
        print(f"Loaded {len(bad_rows)} rows to {args.error_table}")


if __name__ == "__main__":
    run()
