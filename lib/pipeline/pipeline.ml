type 'a t = 'a Seq.t

let compose first second source = second (first source)
let run pipeline = Seq.iter (fun _ -> ()) pipeline
