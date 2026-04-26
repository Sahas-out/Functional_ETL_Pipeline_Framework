open Etl

let ends_with value suffix =
  let lv = String.length value in
  let ls = String.length suffix in
  lv >= ls && String.equal (String.sub value (lv - ls) ls) suffix

let lowercase = String.lowercase_ascii

let is_html endpoint =
  endpoint = "/"
  || List.exists (fun ext -> ends_with endpoint ext) [ ".html"; ".htm"; "/" ]

let is_image endpoint =
  List.exists
    (fun ext -> ends_with endpoint ext)
    [ ".gif"; ".jpg"; ".jpeg"; ".png"; ".bmp"; ".svg"; ".ico"; ".webp"; ".tif"; ".tiff" ]

let is_download endpoint =
  List.exists
    (fun ext -> ends_with endpoint ext)
    [ ".zip"; ".gz"; ".tar"; ".tgz"; ".bz2"; ".7z"; ".rar"; ".exe"; ".dmg"; ".pdf" ]

let is_cgi endpoint = String.contains endpoint '?' || String.contains endpoint '=' || ends_with endpoint ".cgi"

let classify endpoint =
  let endpoint = lowercase endpoint in
  if is_html endpoint then "html"
  else if is_image endpoint then "image"
  else if is_download endpoint then "download"
  else if is_cgi endpoint then "cgi"
  else "other"

let apply row = Row.set "endpoint_type" (classify (Row.get_exn "endpoint" row)) row
