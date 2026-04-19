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

let () =
  let input = Filename.temp_file "etl_input" ".csv" in
  let output = Filename.temp_file "etl_output" ".csv" in
  Fun.protect
    ~finally:(fun () ->
      Sys.remove input;
      Sys.remove output)
    (fun () ->
      let ic = open_out input in
      output_string ic "name,amount\nalice,10\nbob,15\n";
      close_out ic;

      let rows = Csv_extractor.extract ~file:input ~parser () |> Transform.filter_ok in
      let first_two = take 2 rows in
      assert (List.length first_two = 2);

      Csv_loader.load ~file:output ~headers:[ "name"; "amount" ] (List.to_seq first_two);

      let loaded = Csv_extractor.extract ~file:output ~parser () |> Transform.filter_ok |> take 2 in
      assert (List.length loaded = 2))
