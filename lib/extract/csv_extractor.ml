let split_line ~delimiter line =
  String.split_on_char delimiter line |> Array.of_list

let extract ~file ?(delimiter = ',') ?(has_header = true) ~parser () =
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
          match parser fields with
          | value -> value
          | exception exn ->
              close_input ();
              raise exn
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
