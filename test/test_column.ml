open Etl

let amount = Column.Float "amount"
let quantity = Column.Int "quantity"
let discounted = Column.Option (Column.Float "discount")

let () =
  let row = Row.empty |> Row.set "amount" "10.5" |> Row.set "quantity" "2" in
  assert (Column.get_exn amount row = 10.5);
  assert (Column.get_exn quantity row = 2);
  assert (Column.get_exn discounted row = None);
  let with_flag = Column.set (Column.Bool "valid") true row in
  assert (Row.get_exn "valid" with_flag = "true")
