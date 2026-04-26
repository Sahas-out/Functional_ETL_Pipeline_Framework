from __future__ import annotations

import pandas as pd


OUTPUT_COLUMNS = [
    "hour",
    "total_requests",
    "total_bytes",
    "avg_bytes",
    "total_get_requests",
    "total_post_requests",
    "total_head_requests",
    "total_other_method_requests",
    "html_requests",
    "image_requests",
    "download_requests",
    "cgi_requests",
    "other_endpoint_requests",
    "status_2xx_count",
    "status_4xx_count",
    "status_5xx_count",
]


def run(df: pd.DataFrame, output_file: str) -> None:
    df.loc[:, OUTPUT_COLUMNS].to_csv(output_file, index=False)

