val extract :
  file:string ->
  ?delimiter:char ->
  ?has_header:bool ->
  parser:(string array -> (Row.t, string) result) ->
  unit ->
  (Row.t, string) result Seq.t
