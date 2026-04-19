let map = Seq.map
let filter = Seq.filter
let reduce = Seq.fold_left

let filter_ok seq =
  let rec next current () =
    match current () with
    | Seq.Nil -> Seq.Nil
    | Seq.Cons (Ok value, tail) -> Seq.Cons (value, next tail)
    | Seq.Cons (Error _, tail) -> next tail ()
  in
  next seq

let flat_map f seq =
  let rec outer stream () =
    match stream () with
    | Seq.Nil -> Seq.Nil
    | Seq.Cons (item, tail) -> inner (f item) tail ()
  and inner produced remaining () =
    match produced () with
    | Seq.Nil -> outer remaining ()
    | Seq.Cons (item, tail) -> Seq.Cons (item, inner tail remaining)
  in
  outer seq

let group_by_aggregate (type k) ~key ~init ~reduce ~emit seq =
  let module Key = struct
    type t = k

    let compare = Stdlib.compare
  end in
  let module Key_map = Map.Make (Key) in
  let grouped =
    Seq.fold_left
      (fun acc entry ->
        let group_key = key entry in
        let current =
          match Key_map.find_opt group_key acc with
          | Some value -> value
          | None -> init
        in
        Key_map.add group_key (reduce current entry) acc)
      Key_map.empty
      seq
  in
  Key_map.to_seq grouped |> Seq.map (fun (group_key, acc) -> emit group_key acc)
