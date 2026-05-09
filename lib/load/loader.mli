type 'a t = 'a Pipeline.t -> unit Pipeline.t

val make : ('a -> unit) -> 'a t
