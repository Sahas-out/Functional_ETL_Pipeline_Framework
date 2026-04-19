val load :
  file:string ->
  ?delimiter:char ->
  headers:string list ->
  Row.t Seq.t ->
  unit
