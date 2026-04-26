open Etl

let parse_request request =
  match String.split_on_char ' ' request |> List.filter (fun p -> p <> "") with
  | [ method_name; endpoint; protocol ] -> (method_name, endpoint, protocol)
  | _ -> ("OTHER", "", "")

let apply row =
  let method_name, endpoint, protocol = parse_request (Row.get_exn "request" row) in
  row
  |> Row.set "request_method" method_name
  |> Row.set "endpoint" endpoint
  |> Row.set "protocol" protocol
