open Etl

type agg =
  { total_requests : int
  ; total_bytes : float
  ; total_get_requests : int
  ; total_post_requests : int
  ; total_head_requests : int
  ; total_other_method_requests : int
  ; html_requests : int
  ; image_requests : int
  ; download_requests : int
  ; cgi_requests : int
  ; other_endpoint_requests : int
  ; status_2xx_count : int
  ; status_4xx_count : int
  ; status_5xx_count : int
  }

let init =
  { total_requests = 0
  ; total_bytes = 0.0
  ; total_get_requests = 0
  ; total_post_requests = 0
  ; total_head_requests = 0
  ; total_other_method_requests = 0
  ; html_requests = 0
  ; image_requests = 0
  ; download_requests = 0
  ; cgi_requests = 0
  ; other_endpoint_requests = 0
  ; status_2xx_count = 0
  ; status_4xx_count = 0
  ; status_5xx_count = 0
  }

let reduce acc row =
  let bytes = float_of_string (Row.get_exn "response_size" row) in
  let method_name = String.uppercase_ascii (Row.get_exn "request_method" row) in
  let endpoint_type = Row.get_exn "endpoint_type" row in
  let status = int_of_string (Row.get_exn "status" row) in
  { total_requests = acc.total_requests + 1
  ; total_bytes = acc.total_bytes +. bytes
  ; total_get_requests = acc.total_get_requests + if String.equal method_name "GET" then 1 else 0
  ; total_post_requests = acc.total_post_requests + if String.equal method_name "POST" then 1 else 0
  ; total_head_requests = acc.total_head_requests + if String.equal method_name "HEAD" then 1 else 0
  ; total_other_method_requests =
      acc.total_other_method_requests + if List.mem method_name [ "GET"; "POST"; "HEAD" ] then 0 else 1
  ; html_requests = acc.html_requests + if String.equal endpoint_type "html" then 1 else 0
  ; image_requests = acc.image_requests + if String.equal endpoint_type "image" then 1 else 0
  ; download_requests = acc.download_requests + if String.equal endpoint_type "download" then 1 else 0
  ; cgi_requests = acc.cgi_requests + if String.equal endpoint_type "cgi" then 1 else 0
  ; other_endpoint_requests =
      acc.other_endpoint_requests + if String.equal endpoint_type "other" then 1 else 0
  ; status_2xx_count = acc.status_2xx_count + if status >= 200 && status < 300 then 1 else 0
  ; status_4xx_count = acc.status_4xx_count + if status >= 400 && status < 500 then 1 else 0
  ; status_5xx_count = acc.status_5xx_count + if status >= 500 && status < 600 then 1 else 0
  }

let emit hour acc =
  let avg_bytes =
    if acc.total_requests = 0 then 0.0 else acc.total_bytes /. float_of_int acc.total_requests
  in
  Row.empty
  |> Row.set "hour" (string_of_int hour)
  |> Row.set "total_requests" (string_of_int acc.total_requests)
  |> Row.set "total_bytes" (string_of_float acc.total_bytes)
  |> Row.set "avg_bytes" (string_of_float avg_bytes)
  |> Row.set "total_get_requests" (string_of_int acc.total_get_requests)
  |> Row.set "total_post_requests" (string_of_int acc.total_post_requests)
  |> Row.set "total_head_requests" (string_of_int acc.total_head_requests)
  |> Row.set "total_other_method_requests" (string_of_int acc.total_other_method_requests)
  |> Row.set "html_requests" (string_of_int acc.html_requests)
  |> Row.set "image_requests" (string_of_int acc.image_requests)
  |> Row.set "download_requests" (string_of_int acc.download_requests)
  |> Row.set "cgi_requests" (string_of_int acc.cgi_requests)
  |> Row.set "other_endpoint_requests" (string_of_int acc.other_endpoint_requests)
  |> Row.set "status_2xx_count" (string_of_int acc.status_2xx_count)
  |> Row.set "status_4xx_count" (string_of_int acc.status_4xx_count)
  |> Row.set "status_5xx_count" (string_of_int acc.status_5xx_count)
