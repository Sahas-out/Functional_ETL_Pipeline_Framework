type t

val empty : t
val of_list : (string * string) list -> t
val of_array : string array -> string array -> t
val set : string -> string -> t -> t
val unset : string -> t -> t
val get : string -> t -> string option
val get_exn : string -> t -> string
val to_list : t -> (string * string) list
val to_string : t -> string
