open Etl

let rec take n seq =
  if n <= 0 then []
  else
    match seq () with
    | Seq.Nil -> []
    | Seq.Cons (x, xs) -> x :: take (n - 1) xs

let parser fields =
  if Array.length fields <> 2 then Error "bad row"
  else Ok (Row.of_array [| "name"; "amount" |] fields)

let parser_raising fields =
  let _ = int_of_string fields.(1) in
  Ok (Row.of_array [| "name"; "amount" |] fields)

let () =
  let input = Filename.temp_file "etl_input" ".csv" in
  let output = Filename.temp_file "etl_output" ".csv" in
  Fun.protect
    ~finally:(fun () ->
      Sys.remove input;
      Sys.remove output)
    (fun () ->
      let ic = open_out input in
      output_string ic "name,amount\nalice,10\nbob,15\ncarol,not_int\n";
      close_out ic;

      let rows = Csv_extractor.extract ~file:input ~parser () |> Transform.filter_ok in
      let first_two = take 2 rows in
      assert (List.length first_two = 2);

      let with_parser_exception = Csv_extractor.extract ~file:input ~parser:parser_raising () |> take 3 in
      (match with_parser_exception with
      | [ Ok row1; Ok row2; Error err ] ->
          assert (Row.get_exn "name" row1 = "alice");
          assert (Row.get_exn "amount" row1 = "10");
          assert (Row.get_exn "name" row2 = "bob");
          assert (Row.get_exn "amount" row2 = "15");
          assert (String.starts_with ~prefix:"parser exception:" err)
      | _ -> assert false);

      let strict_raised =
        try
          let _ =
            Csv_extractor.extract_strict ~file:input ~parser:parser_raising () |> take 3
          in
          false
        with Failure _ -> true
      in
      assert strict_raised;

      List.to_seq first_two
      |> Csv_loader.load_strict ~file:output ~headers:[ "name"; "amount" ]
      |> Pipeline.run;

      let loaded = Csv_extractor.extract ~file:output ~parser () |> Transform.filter_ok |> take 2 in
      assert (List.length loaded = 2);

      Csv_extractor.extract ~file:input ~parser:parser_raising ()
      |> Csv_loader.load ~file:output ~headers:[ "name"; "amount" ]
      |> Pipeline.run;

      let loaded_after_skip =
        Csv_extractor.extract ~file:output ~parser () |> Transform.filter_ok |> take 2
      in
      assert (List.length loaded_after_skip = 2))
