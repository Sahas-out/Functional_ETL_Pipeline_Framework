open Etl

let derive datetime =
  if String.length datetime >= 13 then
    let date = String.sub datetime 0 10 in
    let hour_text = String.sub datetime 11 2 in
    let hour = int_of_string_opt hour_text |> Option.value ~default:0 in
    (date, hour)
  else
    ("", 0)

let apply row =
  let date, hour = derive (Row.get_exn "datetime" row) in
  row |> Row.set "request_date" date |> Row.set "request_hour" (string_of_int hour)
