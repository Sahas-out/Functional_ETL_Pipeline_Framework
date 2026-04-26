from __future__ import annotations

import pandas as pd


def run(df: pd.DataFrame):
    return df.groupby("request_hour", as_index=False, sort=True)

