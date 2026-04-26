from __future__ import annotations

import pandas as pd


def run(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    parts = out["request"].astype(str).str.extract(r"^(\S+)\s+(\S+)\s+(\S+)$")
    out["request_method"] = parts[0].fillna("OTHER")
    out["endpoint"] = parts[1].fillna("")
    out["protocol"] = parts[2].fillna("")
    return out

