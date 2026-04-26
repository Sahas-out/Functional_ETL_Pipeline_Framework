type t

val make : Column.any list -> t
val validate : t -> Row.t -> bool
val validate_types : t -> Row.t -> bool
val parse_row : t -> string array -> (Row.t, string) result
val field_names : t -> string list
