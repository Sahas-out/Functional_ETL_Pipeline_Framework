let map_strict = Seq.map
let filter_strict = Seq.filter
let reduce_strict = Seq.fold_left

let filter_ok seq =
  let rec next current () =
    match current () with
    | Seq.Nil -> Seq.Nil
    | Seq.Cons (Ok value, tail) -> Seq.Cons (value, next tail)
    | Seq.Cons (Error _, tail) -> next tail ()
  in
  next seq

let flat_map_strict f seq =
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

let map f seq =
  let rec next stream () =
    match stream () with
    | Seq.Nil -> Seq.Nil
    | Seq.Cons (Ok value, tail) -> Seq.Cons (Ok (f value), next tail)
    | Seq.Cons (Error err, tail) -> Seq.Cons (Error err, next tail)
  in
  next seq

let filter predicate seq =
  let rec next stream () =
    match stream () with
    | Seq.Nil -> Seq.Nil
    | Seq.Cons (Error err, tail) -> Seq.Cons (Error err, next tail)
    | Seq.Cons (Ok value, tail) ->
        if predicate value then Seq.Cons (Ok value, next tail) else next tail ()
  in
  next seq

let flat_map f seq =
  let rec outer stream () =
    match stream () with
    | Seq.Nil -> Seq.Nil
    | Seq.Cons (Error err, tail) -> Seq.Cons (Error err, outer tail)
    | Seq.Cons (Ok value, tail) -> inner (f value) tail ()
  and inner produced remaining () =
    match produced () with
    | Seq.Nil -> outer remaining ()
    | Seq.Cons (item, tail) -> Seq.Cons (Ok item, inner tail remaining)
  in
  outer seq

let reduce f init seq =
  let rec go acc current =
    match current () with
    | Seq.Nil -> Ok acc
    | Seq.Cons (Error err, _) -> Error err
    | Seq.Cons (Ok value, tail) -> go (f acc value) tail
  in
  go init seq

let group_by_aggregate_strict (type k) ~key ~init ~reduce ~emit seq =
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

let group_by_aggregate (type k) ~key ~init ~reduce ~emit seq =
  let module Key = struct
    type t = k

    let compare = Stdlib.compare
  end in
  let module Key_map = Map.Make (Key) in
  let grouped, errors =
    Seq.fold_left
      (fun (acc, errs) entry ->
        match entry with
        | Error err -> (acc, err :: errs)
        | Ok value ->
            let group_key = key value in
            let current =
              match Key_map.find_opt group_key acc with
              | Some existing -> existing
              | None -> init
            in
            (Key_map.add group_key (reduce current value) acc, errs))
      (Key_map.empty, [])
      seq
  in
  let error_seq = List.rev errors |> List.to_seq |> Seq.map (fun err -> Error err) in
  let grouped_seq =
    Key_map.to_seq grouped |> Seq.map (fun (group_key, acc) -> Ok (emit group_key acc))
  in
  Seq.append error_seq grouped_seq
