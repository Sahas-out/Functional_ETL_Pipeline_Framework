open Etl

let () =
  let row = Row.empty |> Row.set "name" "alice" |> Row.set "age" "30" in
  assert (Row.get "name" row = Some "alice");
  assert (Row.get "missing" row = None);
  let removed = Row.unset "age" row in
  assert (Row.get "age" removed = None);
  let from_arrays = Row.of_array [| "a"; "b" |] [| "1"; "2" |] in
  assert (Row.get_exn "a" from_arrays = "1")
