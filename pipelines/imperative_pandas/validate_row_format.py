from __future__ import annotations

import pandas as pd


REQUEST_PATTERN = r"^\S+\s+\S+\s+\S+$"


def run(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    datetime_parsed = pd.to_datetime(out["datetime"], errors="coerce", utc=True)
    status_numeric = pd.to_numeric(out["status"], errors="coerce")
    bytes_numeric = pd.to_numeric(out["response_size"], errors="coerce")

    out["is_valid_row"] = (
        out["requesting_host"].notna()
        & out["datetime"].notna()
        & out["request"].notna()
        & out["request"].astype(str).str.match(REQUEST_PATTERN)
        & datetime_parsed.notna()
        & status_numeric.notna()
        & bytes_numeric.notna()
    )
    out["status"] = status_numeric
    out["response_size"] = bytes_numeric
    return out
