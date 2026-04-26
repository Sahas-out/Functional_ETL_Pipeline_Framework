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

let validate_column_type : type a. a Column.t -> Row.t -> string option =
 fun col row ->
  match col with
  | Column.Option inner ->
      let field = Column.name_of inner in
      (match Row.get field row with
      | None -> None
      | Some "" -> None
      | Some raw ->
          let tmp = Row.empty |> Row.set field raw in
          (match Column.get inner tmp with
          | Ok _ -> None
          | Error err -> Some err))
  | _ -> (
      match Column.get col row with
      | Ok _ -> None
      | Error err -> Some err)

let validation_errors schema row =
  List.filter_map (fun (Column.Any col) -> validate_column_type col row) schema

let validate_types schema row = validation_errors schema row = []

let parse_row schema values =
  let headers = field_names schema in
  let expected = List.length headers in
  let got = Array.length values in
  if expected <> got then
    Error
      (Printf.sprintf
         "Schema.parse_row: expected %d fields based on schema, got %d"
         expected
         got)
  else
    let row = Row.of_array (Array.of_list headers) values in
    let errors = validation_errors schema row in
    match errors with [] -> Ok row | _ -> Error (String.concat "; " errors)
