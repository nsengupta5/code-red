import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions, SetupOptions
from apache_beam.io import ReadFromText
from apache_beam.io.gcp.bigquery import WriteToBigQuery


class CustomOptions(PipelineOptions):
    @classmethod
    def _add_argparse_args(cls, parser):
        parser.add_argument(
            "--input",
            required=True,
            help="GCS path to input CSV files"
        )
        parser.add_argument(
            "--output_table",
            required=True,
            help="BigQuery table spec: project:dataset.table"
        )


def parse_csv(line: str):
    # Example: id,name,value
    fields = line.split(",")

    return {
        "id": int(fields[0]),
        "name": fields[1],
        "value": float(fields[2]),
    }


def run():
    pipeline_options = PipelineOptions()
    pipeline_options.view_as(SetupOptions).save_main_session = True

    custom_options = pipeline_options.view_as(CustomOptions)

    with beam.Pipeline(options=pipeline_options) as p:
        (
            p
            | "ReadCSV" >> ReadFromText(
                custom_options.input,
                skip_header_lines=1
            )
            | "ParseCSV" >> beam.Map(parse_csv)
            | "WriteToBQ" >> WriteToBigQuery(
                custom_options.output_table,
                schema={
                    "fields": [
                        {"name": "id", "type": "INTEGER"},
                        {"name": "name", "type": "STRING"},
                        {"name": "value", "type": "FLOAT"},
                    ]
                },
                write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
                create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED,
            )
        )


if __name__ == "__main__":
    run()
    