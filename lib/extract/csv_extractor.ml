let split_line ~delimiter line =
  String.split_on_char delimiter line |> Array.of_list

let make_extractor ~strict_parser ~file ?(delimiter = ',') ?(has_header = true) ~parser () =
  let ic = open_in file in
  let closed = ref false in
  let close_input () =
    if not !closed then (
      closed := true;
      close_in_noerr ic)
  in
  let rec stream () =
    match input_line ic with
    | line ->
        let fields = split_line ~delimiter line in
        let parsed =
          try parser fields with
          | exn when strict_parser ->
              close_input ();
              raise exn
          | exn -> Error ("parser exception: " ^ Printexc.to_string exn)
        in
        Seq.Cons (parsed, stream)
    | exception End_of_file ->
        close_input ();
        Seq.Nil
    | exception exn ->
        close_input ();
        raise exn
  in
  if has_header then
    match input_line ic with
    | _ -> stream
    | exception End_of_file ->
        close_input ();
        Seq.empty
  else stream

let extract ~file ?delimiter ?has_header ~parser () =
  make_extractor ~strict_parser:false ~file ?delimiter ?has_header ~parser ()

let extract_strict ~file ?delimiter ?has_header ~parser () =
  make_extractor ~strict_parser:true ~file ?delimiter ?has_header ~parser ()
