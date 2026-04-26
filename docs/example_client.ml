 open Etl

 let ( let* ) = Result.bind

 (* Typed columns *)
 let order_id_c   = Column.String "order_id"
 let region_c     = Column.String "region"
 let status_c     = Column.String "status"
 let qty_c        = Column.Int "qty"
 let unit_price_c = Column.Float "unit_price"
 let discount_c   = Column.Option (Column.Float "discount")  (* missing -> None *)
 let gross_c      = Column.Float "gross"
 let net_c        = Column.Float "net"
 let high_value_c = Column.Bool "high_value"

 let input_schema =
   Schema.make
     [ Column.Any order_id_c
     ; Column.Any region_c
     ; Column.Any status_c
     ; Column.Any qty_c
     ; Column.Any unit_price_c
     ; Column.Any discount_c
     ]

 let parser (fields : string array) : (Row.t, string) result =
   if Array.length fields <> 6 then Error "bad row: expected 6 columns"
   else
     let row =
       Row.of_array
         [| "order_id"; "region"; "status"; "qty"; "unit_price"; "discount" |]
         fields
     in
     if not (Schema.validate input_schema row) then Error "missing required fields"
     else
       (* force numeric parsing now; failures stay as Error *)
       let* _qty = Column.get qty_c row in
       let* _p   = Column.get unit_price_c row in
       Ok row

 let enrich (row : Row.t) : (Row.t, string) result =
   let* qty = Column.get qty_c row in
   let* unit_price = Column.get unit_price_c row in
   let* discount = Column.get discount_c row in
   let gross = float_of_int qty *. unit_price in
   let net = gross -. Option.value discount ~default:0.0 in
   let high_value = net >= 1000.0 in
   Ok
     (row
      |> Column.set gross_c gross
      |> Column.set net_c net
      |> Column.set high_value_c high_value)

 let aggregate_by_region (rows : Row.t Seq.t) : Row.t Seq.t =
   Transform.group_by_aggregate
     ~key:(fun r -> Row.get_exn "region" r)
     ~init:(0, 0.0)
     ~reduce:(fun (count, revenue) r ->
       (count + 1, revenue +. Column.get_exn net_c r))
     ~emit:(fun region (count, revenue) ->
       Row.empty
       |> Row.set "region" region
       |> Row.set "orders" (string_of_int count)
       |> Row.set "net_revenue" (string_of_float revenue))
     rows

 let run () =
   let rows =
     Csv_extractor.extract ~file:"orders.csv" ~parser ()
     |> Transform.filter_ok
     |> Transform.filter (fun r -> Row.get_exn "status" r = "paid")
     |> Transform.map enrich
     |> Transform.filter_ok
     |> aggregate_by_region
   in
   Csv_loader.load
     ~file:"region_summary.csv"
     ~headers:["region"; "orders"; "net_revenue"]
     rows
