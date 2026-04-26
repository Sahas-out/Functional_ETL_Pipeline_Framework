from __future__ import annotations

import pandas as pd


REQUEST_PATTERN = r"^\S+\s+\S+\s+\S+$"


def run(input_file: str) -> pd.DataFrame:
    df = pd.read_csv(input_file)
    
    # Validate and coerce types (matching functional pipeline's schema validation)
    datetime_parsed = pd.to_datetime(df["datetime"], errors="coerce", utc=True)
    status_numeric = pd.to_numeric(df["status"], errors="coerce")
    bytes_numeric = pd.to_numeric(df["response_size"], errors="coerce")

    is_valid_row = (
        df["requesting_host"].notna()
        & df["datetime"].notna()
        & df["request"].notna()
        & df["request"].astype(str).str.match(REQUEST_PATTERN)
        & datetime_parsed.notna()
        & status_numeric.notna()
        & bytes_numeric.notna()
    )
    
    # Filter to valid rows only and coerce types
    out = df.loc[is_valid_row].copy()
    out["status"] = status_numeric[is_valid_row]
    out["response_size"] = bytes_numeric[is_valid_row]
    
    return out

