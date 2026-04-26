from __future__ import annotations

import pandas as pd


def run(df: pd.DataFrame) -> pd.DataFrame:
    return df.loc[df["is_valid_row"]].drop(columns=["is_valid_row"]).copy()

