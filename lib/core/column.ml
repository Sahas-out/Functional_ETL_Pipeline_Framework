type 'a t =
  | String : string -> string t
  | Int : string -> int t
  | Float : string -> float t
  | Bool : string -> bool t
  | Option : 'a t -> 'a option t

type any = Any : 'a t -> any
type 'a result = ('a, string) Stdlib.result

let rec name_of : type a. a t -> string = function
  | String name -> name
  | Int name -> name
  | Float name -> name
  | Bool name -> name
  | Option inner -> name_of inner

let rec get : type a. a t -> Row.t -> a result =
 fun col row ->
  match col with
  | String field -> (
      match Row.get field row with
      | Some value -> Ok value
      | None -> Error (field ^ ": field not found"))
  | Int field -> (
      match Row.get field row with
      | None -> Error (field ^ ": field not found")
      | Some raw -> (
          match int_of_string_opt raw with
          | Some parsed -> Ok parsed
          | None -> Error (field ^ ": cannot parse int from '" ^ raw ^ "'")))
  | Float field -> (
      match Row.get field row with
      | None -> Error (field ^ ": field not found")
      | Some raw -> (
          match float_of_string_opt raw with
          | Some parsed -> Ok parsed
          | None -> Error (field ^ ": cannot parse float from '" ^ raw ^ "'")))
  | Bool field -> (
      match Row.get field row with
      | None -> Error (field ^ ": field not found")
      | Some "true" -> Ok true
      | Some "false" -> Ok false
      | Some raw -> Error (field ^ ": cannot parse bool from '" ^ raw ^ "'"))
  | Option inner -> (
      match get inner row with
      | Ok value -> Ok (Some value)
      | Error _ -> Ok None)

let get_exn col row =
  match get col row with
  | Ok value -> value
  | Error msg -> invalid_arg ("Column.get_exn: " ^ msg)

let rec set : type a. a t -> a -> Row.t -> Row.t =
 fun col value row ->
  match col with
  | String field -> Row.set field value row
  | Int field -> Row.set field (string_of_int value) row
  | Float field -> Row.set field (string_of_float value) row
  | Bool field -> Row.set field (string_of_bool value) row
  | Option inner ->
      let field = name_of inner in
      let serialized =
        match value with
        | None -> ""
        | Some inner_value ->
            let tmp = set inner inner_value Row.empty in
            Row.get_exn field tmp
      in
      Row.set field serialized row
