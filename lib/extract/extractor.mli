type 'a t = unit -> 'a Pipeline.t

val make : (unit -> 'a Seq.t) -> 'a t
