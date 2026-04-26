from __future__ import annotations

import pandas as pd


IMAGE_EXTENSIONS = (".gif", ".jpg", ".jpeg", ".png", ".bmp", ".svg", ".ico", ".webp", ".tif", ".tiff")
DOWNLOAD_EXTENSIONS = (".zip", ".gz", ".tar", ".tgz", ".bz2", ".7z", ".rar", ".exe", ".dmg", ".pdf")
HTML_EXTENSIONS = (".html", ".htm")


def classify(endpoint: str) -> str:
    e = (endpoint or "").lower()
    if e == "/" or e.endswith("/") or e.endswith(HTML_EXTENSIONS):
        return "html"
    if e.endswith(IMAGE_EXTENSIONS):
        return "image"
    if e.endswith(DOWNLOAD_EXTENSIONS):
        return "download"
    if "/cgi-bin/" in e or e.endswith(".cgi") or "?" in e or "=" in e:
        return "cgi"
    return "other"


def run(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    out["endpoint_type"] = out["endpoint"].astype(str).map(classify)
    return out

