from __future__ import annotations

import pandas as pd


def run(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    ts = pd.to_datetime(out["datetime"], errors="coerce", utc=True)
    out["request_date"] = ts.dt.strftime("%Y-%m-%d")
    out["request_hour"] = ts.dt.hour.fillna(0).astype(int)
    return out

