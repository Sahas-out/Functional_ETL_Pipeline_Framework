val map : ('a -> 'b) -> ('a, 'e) result Seq.t -> ('b, 'e) result Seq.t
val map_strict : ('a -> 'b) -> 'a Seq.t -> 'b Seq.t
val filter : ('a -> bool) -> ('a, 'e) result Seq.t -> ('a, 'e) result Seq.t
val filter_strict : ('a -> bool) -> 'a Seq.t -> 'a Seq.t
val filter_ok : ('a, 'e) result Seq.t -> 'a Seq.t
val flat_map : ('a -> 'b Seq.t) -> ('a, 'e) result Seq.t -> ('b, 'e) result Seq.t
val flat_map_strict : ('a -> 'b Seq.t) -> 'a Seq.t -> 'b Seq.t

val reduce : ('acc -> 'a -> 'acc) -> 'acc -> ('a, 'e) result Seq.t -> ('acc, 'e) result
val reduce_strict : ('acc -> 'a -> 'acc) -> 'acc -> 'a Seq.t -> 'acc

val group_by_aggregate :
  key:('a -> 'k) ->
  init:'acc ->
  reduce:('acc -> 'a -> 'acc) ->
  emit:('k -> 'acc -> 'b) ->
  ('a, 'e) result Seq.t ->
  ('b, 'e) result Seq.t

val group_by_aggregate_strict :
  key:('a -> 'k) ->
  init:'acc ->
  reduce:('acc -> 'a -> 'acc) ->
  emit:('k -> 'acc -> 'b) ->
  'a Seq.t ->
  'b Seq.t
