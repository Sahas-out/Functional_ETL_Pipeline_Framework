open Etl

let () =
  let pipeline =
    Pipeline.compose
      (Transform.map_strict (fun x -> x + 1))
      (Transform.filter_strict (fun x -> x mod 2 = 0))
      (List.to_seq [ 1; 2; 3 ])
  in
  let total = Transform.reduce_strict ( + ) 0 pipeline in
  assert (total = 6)
