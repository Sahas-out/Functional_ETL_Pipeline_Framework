type 'a t = 'a Pipeline.t -> unit

let make sink pipeline = Seq.iter sink pipeline
