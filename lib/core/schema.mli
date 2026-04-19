type t

val make : Column.any list -> t
val validate : t -> Row.t -> bool
val field_names : t -> string list
