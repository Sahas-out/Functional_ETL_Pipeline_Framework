type 'a t = 'a Seq.t

val compose : ('a t -> 'b t) -> ('b t -> 'c t) -> 'a t -> 'c t
val run : 'a t -> unit
