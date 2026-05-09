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

let row_values headers row =
  List.map
    (fun field ->
      match Row.get field row with
      | Some value -> value
      | None -> "")
    headers

let load_strict ~file ?(delimiter = ',') ~headers rows =
  let oc_ref = ref None in
  let closed = ref false in
  let ensure_open () =
    match !oc_ref with
    | Some oc -> oc
    | None ->
        let oc = open_out file in
        oc_ref := Some oc;
        write_csv_line oc ~delimiter headers;
        oc
  in
  let close_output () =
    if not !closed then (
      closed := true;
      match !oc_ref with
      | None -> ()
      | Some oc -> close_out_noerr oc)
  in
  let rec next current () =
    let oc = ensure_open () in
    match current () with
    | Seq.Nil ->
        close_output ();
        Seq.Nil
    | Seq.Cons (row, tail) -> (
        try
          write_csv_line oc ~delimiter (row_values headers row);
          Seq.Cons ((), next tail)
        with exn ->
          close_output ();
          raise exn)
    | exception exn ->
        close_output ();
        raise exn
  in
  next rows

let filter_ok_rows rows =
  let rec next current () =
    match current () with
    | Seq.Nil -> Seq.Nil
    | Seq.Cons (Ok row, tail) -> Seq.Cons (row, next tail)
    | Seq.Cons (Error _, tail) -> next tail ()
  in
  next rows

let load ~file ?delimiter ~headers rows =
  load_strict ~file ?delimiter ~headers (filter_ok_rows rows)
