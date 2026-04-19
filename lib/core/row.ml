module StringMap = Map.Make (String)

type t = string StringMap.t

let empty = StringMap.empty
let of_list pairs = List.fold_left (fun acc (k, v) -> StringMap.add k v acc) empty pairs

let of_array headers values =
  if Array.length headers <> Array.length values then
    invalid_arg "Row.of_array: headers and values must have the same length";
  let pairs = List.combine (Array.to_list headers) (Array.to_list values) in
  of_list pairs

let set field value row = StringMap.add field value row
let unset field row = StringMap.remove field row
let get field row = StringMap.find_opt field row
let get_exn field row = StringMap.find field row
let to_list row = StringMap.bindings row

let to_string row =
  row
  |> to_list
  |> List.map (fun (k, v) -> Printf.sprintf "%s=%s" k v)
  |> String.concat "; "
  |> Printf.sprintf "{%s}"
