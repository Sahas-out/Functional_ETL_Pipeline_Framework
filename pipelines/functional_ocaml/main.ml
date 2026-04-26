open Etl

let run ~input_file ~output_file =
  Csv_extractor.extract ~file:input_file ~parser:Extract_raw_csv_logs.parser ()
  |> Transform.map Parse_request_field.apply
  |> Transform.map Derive_date_and_hour.apply
  |> Transform.map Categorize_endpoint_type.apply
  |> Transform.group_by_aggregate
       ~key:(fun row -> int_of_string (Row.get_exn "request_hour" row))
       ~init:Aggregate_hourly.init
       ~reduce:Aggregate_hourly.reduce
       ~emit:Aggregate_hourly.emit
  |> Transform.filter_ok
  |> Csv_loader.load ~file:output_file ~headers:Load_hourly_summary.output_headers

let () =
  let input_file =
    if Array.length Sys.argv > 1 then Sys.argv.(1) else "data/nasa_aug95_c.csv"
  in
  let output_file =
    if Array.length Sys.argv > 2 then Sys.argv.(2) else "data/hourly_summary_functional.csv"
  in
  run ~input_file ~output_file
