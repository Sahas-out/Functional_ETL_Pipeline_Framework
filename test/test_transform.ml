open Etl

let rec to_list seq =
  match seq () with
  | Seq.Nil -> []
  | Seq.Cons (x, xs) -> x :: to_list xs

let () =
  let ints = List.to_seq [ 1; 2; 3; 4; 5 ] in
  let even_doubled =
    ints
    |> Transform.filter_strict (fun x -> x mod 2 = 0)
    |> Transform.map_strict (fun x -> x * 2)
  in
  assert (to_list even_doubled = [ 4; 8 ]);

  let results = List.to_seq [ Ok 1; Error "bad"; Ok 2 ] |> Transform.filter_ok in
  assert (to_list results = [ 1; 2 ]);

  let groups =
    List.to_seq [ ("a", 2); ("b", 1); ("a", 3) ]
    |> Transform.group_by_aggregate_strict
         ~key:fst
         ~init:0
         ~reduce:(fun acc (_, v) -> acc + v)
         ~emit:(fun key total -> (key, total))
    |> to_list
    |> List.sort compare
  in
  assert (groups = [ ("a", 5); ("b", 1) ]);

  let safe_mapped =
    List.to_seq [ Ok 2; Error "bad-row"; Ok 3 ] |> Transform.map (fun x -> x * 10)
  in
  assert (to_list safe_mapped = [ Ok 20; Error "bad-row"; Ok 30 ]);

  let safe_filtered =
    List.to_seq [ Ok 1; Error "bad-row"; Ok 4; Ok 3 ]
    |> Transform.filter (fun x -> x mod 2 = 0)
  in
  assert (to_list safe_filtered = [ Error "bad-row"; Ok 4 ]);

  let safe_flat_mapped =
    List.to_seq [ Ok 2; Error "bad-row"; Ok 1 ]
    |> Transform.flat_map (fun x -> List.to_seq [ x; x + 100 ])
  in
  assert (to_list safe_flat_mapped = [ Ok 2; Ok 102; Error "bad-row"; Ok 1; Ok 101 ]);

  let safe_grouped =
    List.to_seq [ Ok ("a", 2); Error "bad-row"; Ok ("b", 1); Ok ("a", 3) ]
    |> Transform.group_by_aggregate
         ~key:fst
         ~init:0
         ~reduce:(fun acc (_, v) -> acc + v)
         ~emit:(fun key total -> (key, total))
    |> to_list
  in
  assert (
    safe_grouped
    = [ Error "bad-row"; Ok ("a", 5); Ok ("b", 1) ]
      || safe_grouped
         = [ Error "bad-row"; Ok ("b", 1); Ok ("a", 5) ]);

  let safe_reduced =
    List.to_seq [ Ok 1; Ok 2; Error "bad-row"; Ok 10 ] |> Transform.reduce ( + ) 0
  in
  assert (safe_reduced = Error "bad-row")
