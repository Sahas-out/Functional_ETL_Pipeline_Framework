open Etl

let schema =
  Schema.make
    [
      Column.Any (Column.String "name");
      Column.Any (Column.Int "age");
      Column.Any (Column.Option (Column.Float "discount"));
    ]

let () =
  let missing_age = Row.of_list [ ("name", "alice") ] in
  assert (Schema.validate schema missing_age = false);

  let bad_age = Row.of_list [ ("name", "alice"); ("age", "x") ] in
  assert (Schema.validate schema bad_age = true);
  assert (Schema.validate_types schema bad_age = false);

  let bad_optional_discount =
    Row.of_list [ ("name", "alice"); ("age", "20"); ("discount", "oops") ]
  in
  assert (Schema.validate_types schema bad_optional_discount = false);

  let ok_row = Row.of_list [ ("name", "alice"); ("age", "20"); ("discount", "1.5") ] in
  assert (Schema.validate_types schema ok_row = true);

  let parsed = Schema.parse_row schema [| "bob"; "31"; "2.0" |] in
  assert (Result.is_ok parsed);

  let bad_parsed = Schema.parse_row schema [| "bob"; "not_int"; "2.0" |] in
  assert (Result.is_error bad_parsed)
