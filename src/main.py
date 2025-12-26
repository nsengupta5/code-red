import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions, SetupOptions
from apache_beam.io import ReadFromText
from apache_beam.io.gcp.bigquery import WriteToBigQuery
from apache_beam import pvalue
import csv
import io


class CustomOptions(PipelineOptions):
    @classmethod
    def _add_argparse_args(cls, parser):
        parser.add_argument(
            "--input",
            required=True,
            help="GCS path to input CSV files (e.g. gs://bucket/input/*.csv)"
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


def parse_csv_safe(line):
    if not line.strip():
        yield from ()
        return

    try:
        reader = csv.reader(io.StringIO(line))
        fields = next(reader)

        yield pvalue.TaggedOutput(
            "good",
            {
                "sheep_id": fields[0],          # STRING
                "breed": fields[1],             # STRING
                "colour": fields[2],            # STRING
                "weight": float(fields[3]),     # FLOAT
                "preference_score": float(fields[4]),  # FLOAT
            }
        )

    except Exception as e:
        yield pvalue.TaggedOutput(
            "bad",
            {
                "raw_line": line,
                "error": str(e),
            }
        )



def run():
    pipeline_options = PipelineOptions()
    pipeline_options.view_as(SetupOptions).save_main_session = True

    custom_options = pipeline_options.view_as(CustomOptions)

    with beam.Pipeline(options=pipeline_options) as p:
        parsed = (
            p
            | "ReadCSV" >> ReadFromText(
                custom_options.input,
                skip_header_lines=1
            )
            | "ParseCSV" >> beam.ParDo(parse_csv_safe).with_outputs(
                "good", "bad"
            )
        )

        # Write valid rows to BigQuery
        parsed.good | "WriteGoodToBQ" >> WriteToBigQuery(
            custom_options.output_table,
            schema={
                "fields": [
                    {"name": "sheep_id", "type": "STRING"},
                    {"name": "breed", "type": "STRING"},
                    {"name": "colour", "type": "STRING"},
                    {"name": "weight", "type": "FLOAT"},
                    {"name": "preference_score", "type": "FLOAT"},
                ]
            },
            write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
            create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED,
            method=WriteToBigQuery.Method.STREAMING_INSERTS,
        )

        # Write malformed rows to dead-letter table (optional)
        if getattr(custom_options, "error_table", None):
            parsed.bad | "WriteBadToBQ" >> WriteToBigQuery(
                custom_options.error_table,
                schema={
                    "fields": [
                        {"name": "raw_line", "type": "STRING"},
                        {"name": "error", "type": "STRING"},
                    ]
                },
                write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
                create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED,
                method=WriteToBigQuery.Method.STREAMING_INSERTS,
            )


if __name__ == "__main__":
    run()
