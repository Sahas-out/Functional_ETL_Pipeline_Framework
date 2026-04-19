let csv_escape ~delimiter value =
  let needs_quotes =
    String.contains value delimiter
    || String.contains value '"'
    || String.contains value '\n'
    || String.contains value '\r'
  in
  if needs_quotes then
    let escaped = String.concat "\"\"" (String.split_on_char '"' value) in
    "\"" ^ escaped ^ "\""
  else value

let write_csv_line oc ~delimiter values =
  let delimiter_s = String.make 1 delimiter in
  let rendered =
    values
    |> List.map (csv_escape ~delimiter)
    |> String.concat delimiter_s
  in
  output_string oc rendered;
  output_char oc '\n'

let load ~file ?(delimiter = ',') ~headers rows =
  let oc = open_out file in
  Fun.protect
    ~finally:(fun () -> close_out_noerr oc)
    (fun () ->
      write_csv_line oc ~delimiter headers;
      Seq.iter
        (fun row ->
          let values =
            List.map
              (fun field ->
                match Row.get field row with
                | Some value -> value
                | None -> "")
              headers
          in
          write_csv_line oc ~delimiter values)
        rows)
