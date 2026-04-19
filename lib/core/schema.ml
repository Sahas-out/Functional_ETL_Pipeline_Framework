type t = Column.any list

let make cols = cols

let requires_presence : type a. a Column.t -> bool = function
  | Column.Option _ -> false
  | _ -> true

let validate schema row =
  List.for_all
    (fun (Column.Any col) ->
      if requires_presence col then Row.get (Column.name_of col) row <> None else true)
    schema

let field_names schema = List.map (fun (Column.Any col) -> Column.name_of col) schema
