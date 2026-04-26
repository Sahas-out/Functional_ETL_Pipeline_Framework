from __future__ import annotations

import pandas as pd


def run(grouped) -> pd.DataFrame:
    return grouped.agg(
        total_requests=("requesting_host", "size"),
        total_bytes=("response_size", "sum"),
        avg_bytes=("response_size", "mean"),
        total_get_requests=("request_method", lambda s: (s.str.upper() == "GET").sum()),
        total_post_requests=("request_method", lambda s: (s.str.upper() == "POST").sum()),
        total_head_requests=("request_method", lambda s: (s.str.upper() == "HEAD").sum()),
        total_other_method_requests=(
            "request_method",
            lambda s: (~s.str.upper().isin(["GET", "POST", "HEAD"])).sum(),
        ),
        html_requests=("endpoint_type", lambda s: (s == "html").sum()),
        image_requests=("endpoint_type", lambda s: (s == "image").sum()),
        download_requests=("endpoint_type", lambda s: (s == "download").sum()),
        cgi_requests=("endpoint_type", lambda s: (s == "cgi").sum()),
        other_endpoint_requests=("endpoint_type", lambda s: (s == "other").sum()),
        status_2xx_count=("status", lambda s: ((s >= 200) & (s < 300)).sum()),
        status_4xx_count=("status", lambda s: ((s >= 400) & (s < 500)).sum()),
        status_5xx_count=("status", lambda s: ((s >= 500) & (s < 600)).sum()),
    ).rename(columns={"request_hour": "hour"})

