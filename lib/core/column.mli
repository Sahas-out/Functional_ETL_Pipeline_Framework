type 'a t =
  | String : string -> string t
  | Int : string -> int t
  | Float : string -> float t
  | Bool : string -> bool t
  | Option : 'a t -> 'a option t

type any = Any : 'a t -> any
type 'a result = ('a, string) Stdlib.result

val get : 'a t -> Row.t -> 'a result
val get_exn : 'a t -> Row.t -> 'a
val set : 'a t -> 'a -> Row.t -> Row.t
val name_of : 'a t -> string
