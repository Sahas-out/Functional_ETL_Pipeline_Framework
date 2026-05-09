val load :
  file:string ->
  ?delimiter:char ->
  headers:string list ->
  (Row.t, string) result Seq.t ->
  unit Pipeline.t

val load_strict :
  file:string ->
  ?delimiter:char ->
  headers:string list ->
  Row.t Seq.t ->
  unit Pipeline.t
