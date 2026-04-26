from __future__ import annotations

import sys

from aggregate_hourly import run as aggregate_hourly
from categorize_endpoint_type import run as categorize_endpoint_type
from derive_date_and_hour import run as derive_date_and_hour
from extract_raw_csv_logs import run as extract_raw_csv_logs
from group_by_hour import run as group_by_hour
from load_hourly_summary import run as load_hourly_summary
from parse_request_field import run as parse_request_field


def run(input_file: str, output_file: str) -> None:
    extracted = extract_raw_csv_logs(input_file)
    parsed = parse_request_field(extracted)
    dated = derive_date_and_hour(parsed)
    categorized = categorize_endpoint_type(dated)
    grouped = group_by_hour(categorized)
    aggregated = aggregate_hourly(grouped)
    load_hourly_summary(aggregated, output_file)


if __name__ == "__main__":
    input_path = sys.argv[1] if len(sys.argv) > 1 else "data/nasa_aug95_c.csv"
    output_path = sys.argv[2] if len(sys.argv) > 2 else "data/hourly_summary_imperative.csv"
    run(input_path, output_path)

