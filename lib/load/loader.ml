type 'a t = 'a Pipeline.t -> unit Pipeline.t

let make sink pipeline =
  let rec next current () =
    match current () with
    | Seq.Nil -> Seq.Nil
    | Seq.Cons (item, tail) ->
        sink item;
        Seq.Cons ((), next tail)
  in
  next pipeline
