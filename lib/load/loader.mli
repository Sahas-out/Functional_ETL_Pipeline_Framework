type 'a t = 'a Pipeline.t -> unit

val make : ('a -> unit) -> 'a t
