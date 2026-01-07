"""
This script provides a "naive" implementation for an ETL pipeline that extracts
data from a CSV file in Google Cloud Storage (GCS), transforms it, and loads it
into BigQuery.

The key characteristic of this implementation is that it downloads the entire CSV
file into memory before processing. This approach is simple but not scalable,
as it can easily lead to out-of-memory errors when dealing with large files.
It is intended as a baseline or for use with very small datasets.

The script separates valid rows from malformed rows, loading them into two
separate BigQuery tables if specified.
"""
import argparse
import csv
import io
from google.cloud import bigquery
from google.cloud import storage


def parse_csv_safe(line, good_rows, bad_rows):
    """
    Parses a single line of CSV data and appends it to the appropriate list.

    Attempts to parse a line as a CSV record with a predefined schema. If
    successful, the parsed data is added to the `good_rows` list. If any
    error occurs (e.g., parsing error, type conversion error), the original
    line and error message are added to the `bad_rows` list.

    Args:
        line (str): A single string line from the CSV file.
        good_rows (list): A list to store successfully parsed row dictionaries.
        bad_rows (list): A list to store dictionaries containing raw lines and
                         error messages for rows that failed to parse.
    """
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
        print(f"Parsed good row: {good_rows[-1]}")

    except Exception as e:
        bad_rows.append(
            {
                "raw_line": line,
                "error": str(e),
            }
        )


def chunk_list(data, size):
    """
    Yields successive n-sized chunks from a list.

    This function is a generator that takes a list and splits it into
    smaller lists (chunks) of a specified maximum size.

    Args:
        data (list): The list to be chunked.
        size (int): The maximum size of each chunk.

    Yields:
        list: A chunk of the original list.
    """
    for i in range(0, len(data), size):
        yield data[i : i + size]


def run(argv=None):
    """
    Main function to run the ETL process.

    Orchestrates the entire pipeline:
    1. Parses command-line arguments for input/output locations.
    2. Downloads the specified CSV file from GCS into memory.
    3. Processes the file line by line, separating good and bad rows.
    4. Loads the good rows into the target BigQuery table in chunks.
    5. Loads the bad rows into the error BigQuery table if specified.

    Args:
        argv (list, optional): A list of command-line arguments. If None,
                               arguments are parsed from sys.argv.
    """
    parser = argparse.ArgumentParser(
        description="""
        A naive ETL script to process a CSV from GCS and load it into BigQuery.
        WARNING: This script loads the entire file into memory and is not
        suitable for large files.
        """
    )
    parser.add_argument(
        "--input",
        required=True,
        help="GCS path to input CSV file (e.g. gs://bucket/input/file.csv)",
    )
    parser.add_argument(
        "--output_table",
        required=True,
        help="BigQuery table spec for valid rows: project:dataset.table",
    )
    parser.add_argument(
        "--error_table",
        required=False,
        help="BigQuery table spec for bad rows: project:dataset.bad_rows",
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
    data_lines = lines[1:]

    for line in data_lines:
        parse_csv_safe(line, good_rows, bad_rows)

    # Load good rows to BigQuery
    if good_rows:
        output_table = bigquery_client.get_table(args.output_table)
        chunks = chunk_list(good_rows, 500)
        for idx, chunk in enumerate(chunks):
            print(
                f"Loading chunk {idx + 1} with {len(chunk)} rows to BigQuery table {args.output_table}"
            )
            errors = bigquery_client.insert_rows_json(output_table, chunk)
            if errors:
                print(f"Errors inserting good rows: {errors}")
            print(f"Loaded chunk {idx + 1} successfully.")

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
