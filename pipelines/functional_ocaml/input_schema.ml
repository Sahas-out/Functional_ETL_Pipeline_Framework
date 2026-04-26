open Etl

let requesting_host_c = Column.String "requesting_host"
let datetime_c = Column.String "datetime"
let request_c = Column.String "request"
let status_c = Column.Int "status"
let response_size_c = Column.Float "response_size"

let input_schema =
  Schema.make
    [ Column.Any requesting_host_c
    ; Column.Any datetime_c
    ; Column.Any request_c
    ; Column.Any status_c
    ; Column.Any response_size_c
    ]

let parse_row values = Schema.parse_row input_schema values

