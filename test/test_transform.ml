open Etl

let rec to_list seq =
  match seq () with
  | Seq.Nil -> []
  | Seq.Cons (x, xs) -> x :: to_list xs

let () =
  let ints = List.to_seq [ 1; 2; 3; 4; 5 ] in
  let even_doubled =
    ints |> Transform.filter (fun x -> x mod 2 = 0) |> Transform.map (fun x -> x * 2)
  in
  assert (to_list even_doubled = [ 4; 8 ]);

  let results = List.to_seq [ Ok 1; Error "bad"; Ok 2 ] |> Transform.filter_ok in
  assert (to_list results = [ 1; 2 ]);

  let groups =
    List.to_seq [ ("a", 2); ("b", 1); ("a", 3) ]
    |> Transform.group_by_aggregate
         ~key:fst
         ~init:0
         ~reduce:(fun acc (_, v) -> acc + v)
         ~emit:(fun key total -> (key, total))
    |> to_list
    |> List.sort compare
  in
  assert (groups = [ ("a", 5); ("b", 1) ])
