# Functional ETL Library — Design Document
> OCaml · Functional Programming · Course Project

---

## Table of Contents

1. [High-Level Architecture](#1-high-level-architecture)
2. [Repository & Module Layout](#2-repository--module-layout)
3. [Core Datatypes](#3-core-datatypes)
4. [Column Access via GADTs](#4-column-access-via-gadts)
5. [Pipeline Abstraction](#5-pipeline-abstraction)
6. [Extract Layer](#6-extract-layer)
7. [Transform Library](#7-transform-library)
8. [Load Layer](#8-load-layer)
9. [Error Handling — Result Monad](#9-error-handling--result-monad)
10. [Side-Effect Encapsulation](#10-side-effect-encapsulation)
11. [Parallelizability by Design](#11-parallelizability-by-design)
12. [Performance Comparison Strategy](#12-performance-comparison-strategy)
13. [End-to-End Example](#13-end-to-end-example)

---

## 1. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        ETL PIPELINE                             │
│                                                                 │
│  ┌──────────┐     ┌───────────────────────────┐     ┌────────┐  │
│  │ EXTRACT  │────▶│        TRANSFORM          │────▶│  LOAD  │  │
│  │          │     │  map ▸ filter ▸ reduce... │     │        │  │
│  │ I/O side │     │  pure · lazy · composable │     │ I/O    │  │
│  │  effect  │     │  Seq.t flows through here │     │ side   │  │
│  │          │     │                           │     │ effect │  │
│  └──────────┘     └───────────────────────────┘     └────────┘  │
│       ▲                        ▲                        ▲       │
│  User-defined            Library-provided          User-defined │
│  or csv_extractor        combinators               or csv_loader│
└─────────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

| Concern              | Decision                                        | Why                                              |
|----------------------|-------------------------------------------------|--------------------------------------------------|
| Row representation   | `string Map.t` (association map)                | CSV is stringly-typed at source; simple and flat |
| Type-safe access     | GADTs for column descriptors                    | Compiler enforces field types, no runtime casts  |
| Streaming            | `Seq.t` (lazy, pull-based)                      | Avoids loading entire dataset into memory        |
| Error propagation    | `Result` monad threaded through pipeline        | Errors are values; no exceptions in pure core    |
| Side effects         | Isolated in Extract and Load only               | Transform layer remains purely functional        |
| Schema validation    | Runtime schema helpers via `Schema.t`           | Validates field presence and types explicitly    |

---

## 2. Repository & Module Layout

```
etl_lib/
│
├── lib/                          ← Core library (the framework)
│   ├── core/
│   │   ├── row.ml                ← Row type and Map-based representation
│   │   ├── row.mli
│   │   ├── column.ml             ← GADT column descriptors + typed accessors
│   │   ├── column.mli
│   │   ├── schema.ml             ← Schema type (list of existential columns)
│   │   └── schema.mli
│   │
│   ├── pipeline/
│   │   ├── pipeline.ml           ← Pipeline type, compose, run
│   │   ├── pipeline.mli
│   │   ├── transform.ml          ← map, filter, reduce, flat_map, group_by_aggregate
│   │   └── transform.mli
│   │
│   ├── extract/
│   │   ├── extractor.ml          ← Extractor type + user-defined extractor interface
│   │   ├── extractor.mli
│   │   ├── csv_extractor.ml      ← Built-in CSV file reader → Seq.t of raw rows
│   │   └── csv_extractor.mli
│   │
│   ├── load/
│   │   ├── loader.ml             ← Loader type + user-defined loader interface
│   │   ├── loader.mli
│   │   ├── csv_loader.ml         ← Result-aware CSV writer (+ strict variant in same module)
│   │   └── csv_loader.mli
│   │
│   └── etl.ml                   ← Top-level re-export / public API surface
│
├── pipelines/
│   ├── functional_ocaml/         ← Functional pipeline example and entrypoint
│   └── imperative_pandas/        ← Python/Pandas baseline pipeline
│
├── test/
│   ├── test_row.ml
│   ├── test_column.ml
│   ├── test_schema.ml
│   ├── test_transform.ml
│   ├── test_pipeline.ml
│   └── test_csv_io.ml
│
├── dune-project
├── etl_lib.opam
└── DESIGN.md                     ← This file
```

### Module Dependency Graph

```
etl.ml  (public API)
  ├── pipeline.ml
  │     ├── transform.ml
  │     │     └── row.ml
  │     └── row.ml
  ├── extractor.ml
  │     ├── csv_extractor.ml
  │     │     └── row.ml
  │     └── row.ml
  ├── loader.ml
  │     ├── csv_loader.ml
  │     │     └── row.ml
  │     └── row.ml
  └── column.ml
        └── row.ml
```

No module depends on `extractor` or `loader` — these are leaf modules. `transform` has zero knowledge of I/O.

---

## 3. Core Datatypes

### 3.1 `Row` — `lib/core/row.ml`

The fundamental unit of data flowing through the pipeline. Internally a `Map` from field name to string. Immutable — every operation returns a new map.

```ocaml
(* row.ml *)

module StringMap = Map.Make(String)

(* A row is an immutable string-to-string map *)
type row = string StringMap.t

(* Construction *)
val empty : row
val of_list : (string * string) list -> row      (* [("name","alice");("age","30")] *)
val of_array : string array -> string array -> row (* headers, values *)

(* Immutable field operations — always return new row *)
val set   : string -> string -> row -> row         (* set field, returns new row *)
val unset : string -> row -> row                   (* remove field, returns new row *)
val get   : string -> row -> string option
val get_exn : string -> row -> string              (* raises Not_found *)

(* Conversion *)
val to_list   : row -> (string * string) list
val to_string : row -> string                      (* for debugging *)
```

**Immutability guarantee:** `StringMap` from the OCaml stdlib is a purely functional, persistent data structure. Every `set`/`unset` returns a structurally-shared new tree — no in-place mutation ever.

---

### 3.2 `Column` — `lib/core/column.ml`

GADT-based typed column descriptors. A value of type `'a column` describes a field whose extracted value has OCaml type `'a`. The type parameter `'a` is determined entirely by which constructor you use.

```ocaml
(* column.ml *)

(* The GADT — 'a is the OCaml type of the column's value *)
type 'a column =
  | String : string -> string column
  | Int    : string -> int    column
  | Float  : string -> float  column
  | Bool   : string -> bool   column
  | Option : 'a column -> 'a option column    (* nullable columns *)

(* 
   A value of type:
     string column  → get returns string
     int    column  → get returns int     (parse happens inside)
     float  column  → get returns float
     bool   column  → get returns bool
*)

(* Existential wrapper — erases 'a for storing mixed columns in a list *)
type any_column = AnyColumn : 'a column -> any_column

(* Typed, safe field access — return type flows from column descriptor *)
val get        : 'a column -> row -> 'a result   (* Result-wrapped *)
val get_exn    : 'a column -> row -> 'a          (* raises on missing/parse error *)

(* Write a typed value back into a row — serialises to string *)
val set        : 'a column -> 'a -> row -> row

(* Inspect the column's field name *)
val name_of    : 'a column -> string
```

**How the type magic works:**

```
get (Int "age") row
       ↑
   'a = int
       
return type of get is 'a result = int result
```

The compiler pattern-matches on the constructor, determines `'a`, and the return type is inferred automatically. The user never writes a type annotation.

---

### 3.3 `Schema` — `lib/core/schema.ml`

A schema is a runtime-inspectable list of `any_column`. It provides validation helpers and field-name extraction; parsing is still driven by caller-provided parsers.

```ocaml
(* schema.ml *)

type schema = any_column list

(* Build a schema from column descriptors *)
val make : any_column list -> schema

(* Check that a row contains all columns declared in the schema *)
val validate : schema -> row -> bool

(* Extract all field names from a schema (for writing CSV headers) *)
val field_names : schema -> string list
```

---

### 3.4 `Pipeline` — `lib/pipeline/pipeline.ml`

The pipeline is parameterised over its element type `'a`. In the current implementation it is simply a thin wrapper over `'a Seq.t`.

```ocaml
(* pipeline.ml *)

(* A pipeline is just a lazy sequence — Seq.t is pull-based and memoisation-free *)
type 'a pipeline = 'a Seq.t

(* Compose two pipeline transformers *)
val compose : ('a pipeline -> 'b pipeline) -> ('b pipeline -> 'c pipeline)
           -> ('a pipeline -> 'c pipeline)

(* Run a pipeline to completion — forces all lazy evaluation *)
(* Nothing materialises until run is called *)
val run : 'a pipeline -> unit
```

The `|>` operator in OCaml serves naturally as the pipeline composition operator — no special syntax needed.

---

### 3.5 `Extractor` — `lib/extract/extractor.ml`

```ocaml
(* extractor.ml *)

(* An extractor is any function that produces a pipeline of rows *)
type 'a extractor = unit -> 'a pipeline

(* Helper to lift any sequence-producing function into an extractor *)
val make : (unit -> 'a Seq.t) -> 'a extractor
```

---

### 3.6 `Loader` — `lib/load/loader.ml`

```ocaml
(* loader.ml *)

(* A loader consumes a pipeline — triggers all lazy evaluation  *)
type 'a loader = 'a pipeline -> unit

(* Helper to build a loader from a per-element sink function *)
val make : ('a -> unit) -> 'a loader
```

---

## 4. Column Access via GADTs

This is the central type-safety mechanism. Here is the complete design of `column.ml`.

### 4.1 The GADT Definition

```ocaml
type 'a column =
  | String : string -> string column
  | Int    : string -> int    column
  | Float  : string -> float  column
  | Bool   : string -> bool   column
  | Option : 'a column -> 'a option column
```

Each constructor is a different *type*: `String "x"` has type `string column`, `Int "y"` has type `int column`. The string argument is the field name inside the row map.

### 4.2 Typed `get` — How Parse and Type Flow Together

```ocaml
(* The return type 'a is determined by which constructor col is *)
let get : type a. a column -> row -> a result =
  fun col row ->
    match col with

    | String field ->
      (match Row.get field row with
       | None   -> Error (field ^ ": field not found")
       | Some v -> Ok v)

    | Int field ->
      (match Row.get field row with
       | None   -> Error (field ^ ": field not found")
       | Some v ->
         match int_of_string_opt v with
         | None   -> Error (field ^ ": cannot parse int from '" ^ v ^ "'")
         | Some n -> Ok n)

    | Float field ->
      (match Row.get field row with
       | None   -> Error (field ^ ": field not found")
       | Some v ->
         match float_of_string_opt v with
         | None   -> Error (field ^ ": cannot parse float from '" ^ v ^ "'")
         | Some f -> Ok f)

    | Bool field ->
      (match Row.get field row with
       | None   -> Error (field ^ ": field not found")
       | Some "true"  -> Ok true
       | Some "false" -> Ok false
       | Some v -> Error (field ^ ": cannot parse bool from '" ^ v ^ "'"))

    | Option inner_col ->
      (match get inner_col row with
       | Ok v    -> Ok (Some v)
       | Error _ -> Ok None)       (* missing/unparseable → None, not Error *)
```

### 4.3 Typed `set` — Serialise Back Into Row

```ocaml
let set : type a. a column -> a -> row -> row =
  fun col value row ->
    let field = name_of col in
    let str_value = match col with
      | String _ -> value
      | Int    _ -> string_of_int value
      | Float  _ -> string_of_float value
      | Bool   _ -> string_of_bool value
      | Option inner ->
        (match value with
         | None   -> ""
         | Some v -> (* recurse with inner col *)
           let temp = set inner v Row.empty in
           Row.get_exn (name_of inner) temp)
    in
    Row.set field str_value row
```

### 4.4 User-Side: Defining Column Descriptors

The user defines columns once, at the top of their pipeline file:

```ocaml
(* User code — pipelines/functional_ocaml/main.ml *)

(* Column declarations — these are just values, not types *)
let order_id   : string column = String "order_id"
let amount     : float  column = Float  "amount"
let quantity   : int    column = Int    "quantity"
let is_refund  : bool   column = Bool   "is_refund"
let department : string column = String "department"
let discount   : float option column = Option (Float "discount")

(* Type-safe transformation — compiler knows get amount row : float result *)
let enrich_row row =
  Column.get amount row   >>= fun amt ->
  Column.get quantity row >>= fun qty ->
  let total = amt *. float_of_int qty in
  Ok (Column.set (Float "total") total row)
```

---

## 5. Pipeline Abstraction

### 5.1 How `Seq.t` Provides Laziness

OCaml's `Seq.t` is a lazy, pull-based sequence. Elements are computed only when demanded. The type is:

```ocaml
type 'a Seq.t = unit -> 'a Seq.node
type 'a Seq.node = Nil | Cons of 'a * 'a Seq.t
```

Each `Seq.t` is a thunk — calling it produces either the end of the stream or the next element and another thunk. This means:

- `csv_extractor` reads **one line at a time** from disk, on demand
- `map f seq` does not evaluate `f` on any element until the result sequence is consumed
- The entire pipeline is assembled as a chain of thunks; nothing executes until `pipeline.run` forces consumption

```
csv_extractor ──▶ parse ──▶ filter ──▶ map ──▶ csv_loader
     │               │         │        │           │
     └───────────────┴─────────┴────────┴───────────┘
           Nothing happens until Pipeline.run pulls the first element
```

### 5.2 Pipeline Composition

```ocaml
(* pipeline.ml *)

(* compose : chain two pipeline transformers *)
let compose f g = fun source -> g (f source)

(* The |> operator naturally threads pipelines: *)
(*   source |> stage1 |> stage2 |> stage3       *)

(* run : force full evaluation *)
let run (pipeline : 'a Seq.t) : unit =
  Seq.iter (fun _ -> ()) pipeline
```

### 5.3 Full Pipeline Shape

```ocaml
(* Full pipeline — types annotated for clarity *)

let run_logs_pipeline ~input_file ~output_file =
  Csv_extractor.extract
    ~file:input_file
    ~parser:Extract_raw_csv_logs.parser
    ()
  |> Transform.map Parse_request_field.apply
  |> Transform.map Derive_date_and_hour.apply
  |> Transform.map Categorize_endpoint_type.apply
  |> Transform.group_by_aggregate
       ~key:(fun row -> int_of_string (Row.get_exn "request_hour" row))
       ~init:Aggregate_hourly.init
       ~reduce:Aggregate_hourly.reduce
       ~emit:Aggregate_hourly.emit
  |> Csv_loader.load
        ~file:output_file
        ~headers:Load_hourly_summary.output_headers
  |> Pipeline.run
```

---

## 6. Extract Layer

### 6.1 User-Defined Extractor Interface

Any function `unit -> 'a Seq.t` qualifies as an extractor. Users can implement:

```ocaml
(* A custom JSON extractor (user-defined) *)
let json_extractor ~file () : row Seq.t =
  let ic = open_in file in
  let json_stream = Json_parser.stream_of_channel ic in
  Seq.map (fun json_obj ->
    (* parse JSON object fields into a Row *)
    List.fold_left (fun row_acc (key, value) ->
      Result.map (Row.set key (Json.to_string value)) row_acc
    ) (Ok Row.empty) (Json.to_assoc json_obj)
  ) json_stream
```

The library does not care *how* data is produced — only that it arrives as a lazy sequence.

### 6.2 Built-in `Csv_extractor` — `lib/extract/csv_extractor.ml`

```ocaml
(* csv_extractor.ml *)

(* extract : opens file, reads lazily line by line, uses user-provided parser *)
val extract :
  file:string ->
  ?delimiter:char ->
  ?has_header:bool ->
  parser:(string array -> (Row.t, string) result) ->
  unit ->
  (Row.t, string) result Seq.t

(*
  Internally:

  let extract ~file ?(delimiter=',') ?(has_header=true) ~parser () =
    let ic = open_in file in
    let header = if has_header then Some (read_header ic delimiter) else None in
    Seq.of_dispenser (fun () ->
      match read_line_opt ic with
      | None      -> close_in ic; None            (* EOF — stream ends *)
      | Some line ->
        let fields = split_by delimiter line in
        Some (parser fields)                       (* user's parser called lazily *)
    )
*)
```

### 6.3 User-Defined Parser

The parser is a function `string array -> row result`. The user receives raw field values and maps them to a typed row. This is where `Column.set` is used to write typed values:

```ocaml
(* User-defined parser for sales CSV *)
(* Columns: order_id, amount, quantity, is_refund, department *)

let sales_parser (fields : string array) : row result =
  if Array.length fields <> 5 then
    Error "expected 5 fields"
  else
    let raw = Row.of_array
      [| "order_id"; "amount"; "quantity"; "is_refund"; "department" |]
      fields
    in
    (* Validate types eagerly at parse time using column descriptors *)
    Column.get order_id   raw >>= fun _ ->
    Column.get amount     raw >>= fun _ ->
    Column.get quantity   raw >>= fun _ ->
    Column.get is_refund  raw >>= fun _ ->
    Column.get department raw >>= fun _ ->
    Ok raw      (* Row stays as string map; types validated, not yet extracted *)
```

**Design note:** The row stores strings internally. Type extraction (`Column.get`) happens per-field in the transform stage. This keeps parsing simple and lets the transform layer decide what types it needs.

---

## 7. Transform Library

All transforms live in `lib/pipeline/transform.ml`. Every function is **pure** and operates on `'a Seq.t`. No I/O, no mutable state, no exceptions.

### 7.1 `map`

```ocaml
(* transform.ml *)

(* Apply f to every Ok value in a result stream *)
val map : ('a -> 'b) -> ('a, 'e) result Seq.t -> ('b, 'e) result Seq.t

(* Implementation: preserve Error rows unchanged *)
let map f seq =
  Seq.map (function
    | Ok value -> Ok (f value)
    | Error err -> Error err) seq
```

**Example:**

```ocaml
(* Add a computed "total" field to each row *)
let add_total : row -> row result = fun row ->
  Column.get amount   row >>= fun amt ->
  Column.get quantity row >>= fun qty ->
  Ok (Column.set (Float "total") (amt *. float_of_int qty) row)

pipeline |> Transform.map add_total
```

---

### 7.2 `filter`

```ocaml
val filter : ('a -> bool) -> ('a, 'e) result Seq.t -> ('a, 'e) result Seq.t

let filter pred seq =
  Seq.filter_map
    (function
      | Error err -> Some (Error err)
      | Ok value -> if pred value then Some (Ok value) else None)
    seq
```

**Example:**

```ocaml
(* Keep only Ok rows where amount > 100.0 *)
let is_large_order row =
  match Column.get amount row with
  | Ok v -> v > 100.0
  | Error _ -> false     (* error rows are excluded *)

pipeline |> Transform.filter is_large_order
```

### 7.3 `filter_ok` — Result-aware filter

```ocaml
(* Drop all Error rows, unwrap Ok rows *)
val filter_ok : ('a, 'e) result Seq.t -> 'a Seq.t

let filter_ok seq =
  seq
  |> Seq.filter_map (function
     | Ok v    -> Some v
     | Error e ->
       (* Optionally log the error before dropping *)
       Printf.eprintf "Row dropped: %s\n" e;
       None)
```

---

### 7.4 `flat_map`

```ocaml
(* Map each Ok value to a sequence, then flatten all sequences together *)
val flat_map : ('a -> 'b Seq.t) -> ('a, 'e) result Seq.t -> ('b, 'e) result Seq.t

let flat_map f seq =
  Seq.flat_map
    (function
      | Error err -> Seq.return (Error err)
      | Ok value -> Seq.map (fun item -> Ok item) (f value))
    seq
```

**Example — explode multi-item orders into individual line items:**

```ocaml
let explode_items : row -> row Seq.t = fun row ->
  match Column.get quantity row with
  | Error _ -> Seq.empty
  | Ok qty  ->
    Seq.init qty (fun i ->
      row
      |> Column.set (Int "line_item") i
      |> Column.set (Float "unit_amount")
           (Column.get_exn amount row /. float_of_int qty)
    )

pipeline |> Transform.flat_map explode_items
```

---

### 7.5 `reduce`

```ocaml
(* Fold over the entire result sequence — terminal operation *)
val reduce : ('acc -> 'a -> 'acc) -> 'acc -> ('a, 'e) result Seq.t -> ('acc, 'e) result

let reduce f init seq =
  let rec go acc current =
    match current () with
    | Seq.Nil -> Ok acc
    | Seq.Cons (Error err, _) -> Error err
    | Seq.Cons (Ok value, tail) -> go (f acc value) tail
  in
  go init seq
```

**Important:** `reduce` is **strict** — it must consume the whole sequence to produce a result. All lazy stages upstream are forced at this point.

**Example — total revenue:**

```ocaml
let total_revenue =
  pipeline
  |> Transform.reduce
       (fun acc row ->
         acc +. (Column.get_exn (Float "total") row))
       0.0
```

---

### 7.6 `group_by_aggregate` — Map-Reduce Style

This is the most complex transform. Because `Seq.t` is a single-pass lazy stream, grouping requires materialising the sequence into an intermediate map (unavoidable for group-by). This is the **only** transform that forces evaluation — it is documented as a "barrier" in the pipeline.

```
         Lazy upstream          │  Barrier  │     Lazy downstream
                                │           │
csv → parse → filter → map ────▶ group_by ──▶ map → load
                                │           │
                            (forces Seq,    (resumes
                            builds Map,     laziness
                            emits new Seq)  from Map)
```

**Design — Map-Reduce decomposition:**

`group_by_aggregate` is implemented as two steps:

1. **Map phase** — assign each row a key (runs lazily until the barrier)
2. **Reduce phase** — fold all rows of the same key into an accumulator (barrier point)
3. **Emit phase** — emit one result row per group as a new `Seq.t` (lazy again)

```ocaml
val group_by_aggregate :
  key:('a -> 'k) ->
  init:'acc ->
  reduce:('acc -> 'a -> 'acc) ->
  emit:('k -> 'acc -> 'b) ->
  ('a, 'e) result Seq.t ->
  ('b, 'e) result Seq.t


(* Pseudocode implementation *)
let group_by_aggregate ~key ~init ~reduce ~emit seq =

  (* === MAP + REDUCE PHASE (barrier) ===
     Walk the full sequence once, building a key → accumulator map.
     This is where all upstream lazy evaluation is forced.          *)
  let group_map =
    Seq.fold_left
      (fun acc_map element ->
        match element with
        | Error _ -> acc_map
        | Ok value ->
            let k = key value in
            let current = match Map.find_opt k acc_map with
              | None   -> init
              | Some v -> v
            in
            Map.add k (reduce current value) acc_map)
      Map.empty
      seq
  in

  (* === EMIT PHASE (lazy again) ===
     Convert the map's bindings into a new lazy sequence.           *)
  Map.to_seq group_map
  |> Seq.map (fun (k, acc) -> Ok (emit k acc))
```

**Example — total sales per department:**

```ocaml
pipeline
|> Transform.group_by_aggregate
     ~key:(fun row -> Column.get_exn department row)
     ~init:{ count = 0; total = 0.0 }
     ~reduce:(fun acc row ->
       { count = acc.count + 1
       ; total = acc.total +. Column.get_exn (Float "total") row })
     ~emit:(fun dept acc ->
       Row.empty
       |> Row.set "department" dept
       |> Row.set "order_count" (string_of_int acc.count)
       |> Row.set "total_sales" (string_of_float acc.total))
```

---

## 8. Load Layer

### 8.1 User-Defined Loader Interface

Any function `'a Seq.t -> unit` is a loader. Examples a user can write:

```ocaml
(* Load to stdout *)
let print_loader : row Seq.t -> unit =
  Seq.iter (fun row ->
    print_endline (Row.to_string row))

(* Load to a database (user-defined) *)
let db_loader ~conn : row Seq.t -> unit =
  Seq.iter (fun row ->
    Db.insert conn (Row.to_list row))    (* row is consumed one at a time *)
```

### 8.2 Built-in `Csv_loader` — `lib/load/csv_loader.ml`

```ocaml
(* csv_loader.ml *)

val load :
  file:string ->
  ?delimiter:char ->
  headers:string list ->      (* which fields to write and in what order *)
  (row, string) result Seq.t ->
  unit Pipeline.t

(*
  Pseudocode:

  let load ~file ?(delimiter=',') ~headers pipeline =
    let rows_only = filter_ok_rows pipeline in
    Csv_loader.load_strict ~file ~delimiter ~headers rows_only
*)
```

`Csv_loader.load` skips error rows; `Csv_loader.load_strict` accepts only `row Seq.t`.

---

## 9. Error Handling — Result Monad

### 9.1 The `Result` Type

```ocaml
(* Built into OCaml stdlib *)
type ('a, 'e) result = Ok of 'a | Error of 'e

(* Library specialises error to string for simplicity *)
type 'a result = ('a, string) Result.t
```

### 9.2 Monadic Bind

```ocaml
(* The bind operator — chains result-returning functions *)
let ( >>= ) : 'a result -> ('a -> 'b result) -> 'b result =
  fun r f -> match r with
  | Error e -> Error e    (* short-circuit — error propagates *)
  | Ok v    -> f v        (* continue with value *)

(* Lift a pure function into result context *)
let ( >|= ) : 'a result -> ('a -> 'b) -> 'b result =
  fun r f -> r >>= fun v -> Ok (f v)
```

### 9.3 Errors Flow Through the Pipeline

The pipeline carries `row result Seq.t` through the transform stages. Each transform either:
- Propagates errors untouched (`Error e -> Error e`)
- Introduces new errors from parse failures
- Optionally filters errors out with `filter_ok`

```
Extract          Transform             Load
  │                  │                  │
  ▼                  ▼                  ▼
row result ──▶ row result ──▶ row result ──▶ (errors logged, ok rows written)
  Seq.t          Seq.t          Seq.t
```

---

## 10. Side-Effect Encapsulation

| Layer     | Side Effects Allowed             | How Encapsulated                                        |
|-----------|----------------------------------|---------------------------------------------------------|
| Extract   | File I/O, network, DB reads      | Inside extractor thunk; Seq.t hides when it happens    |
| Transform | **None** — must be pure          | By convention and module interface (no I/O functions exported) |
| Load      | File I/O, network, DB writes     | Inside loader function; called once per element by Seq.iter |

The `Transform` module's `.mli` interface file exports **only** pure functions. It does not expose `open_in`, `print_string`, or anything else with I/O type. This enforces the separation structurally.

---

## 11. Parallelizability by Design

Actual parallelism is not implemented, but the design enables it at three levels:

### Level 1 — Chunk Parallelism (Row-level)

Since all transforms are stateless pure functions, a parallel runtime could split the `Seq.t` into N chunks and apply the same transform on each chunk independently:

```
                    ┌─── chunk 1 ──▶ transform ──▶ result 1 ─┐
Seq.t ──▶ split ───┼─── chunk 2 ──▶ transform ──▶ result 2 ─┼──▶ merge ──▶ Seq.t
                    └─── chunk 3 ──▶ transform ──▶ result 3 ─┘
```

No shared state → no locks needed → safe by construction.

### Level 2 — Stage Parallelism (Pipeline stages as actors)

Each stage can run as an independent actor/thread with a bounded channel between stages:

```
Extractor ──[channel]──▶ Transform ──[channel]──▶ Loader
(producer)                                        (consumer)
```

This is the classic producer-consumer model. The `Seq.t` interface maps naturally onto a channel.

### Level 3 — Group-By Parallelism

After the grouping key is computed, each group's `reduce` is completely independent. A parallel `group_by_aggregate` would distribute groups across workers trivially.

---

## 12. Performance Comparison Strategy

### Functional Pipeline (this library)
- Memory: O(1) row in memory at any time during map/filter (before group_by barrier)
- Throughput: One file-read syscall per line, one write syscall per line

### Imperative Baseline (`pipelines/imperative_pandas/pipeline.py`)

```ocaml
(* Equivalent imperative pipeline for comparison *)
let run_imperative ~input ~output =
  ignore input;
  ignore output
```

### Metrics to Collect

```
┌──────────────────────┬────────────────────┬──────────────────────┐
│ Metric               │ How to measure     │ Expected winner      │
├──────────────────────┼────────────────────┼──────────────────────┤
│ Peak memory usage    │ /proc/self/status  │ Functional (O(1))    │
│ Throughput (rows/s)  │ Sys.time()         │ Similar              │
│ Wall-clock time      │ Unix.gettimeofday  │ Similar              │
│ GC pressure          │ Gc.stat()          │ Functional (less)    │
└──────────────────────┴────────────────────┴──────────────────────┘
```

---

## 13. End-to-End Example

**Scenario:** Process NASA logs, derive request metadata, aggregate by hour, write `hourly_summary.csv`.

```
nasa_aug95_c.csv
  requesting_host,datetime,request,status,response_size
  example.com,01/Aug/1995:00:00:01 -0400,GET / HTTP/1.0,200,1024
  example.com,01/Aug/1995:00:15:42 -0400,GET /image.png HTTP/1.0,200,2048
```

```ocaml
(* pipelines/functional_ocaml/main.ml *)

let run ~input_file ~output_file =
  Csv_extractor.extract ~file:input_file ~parser:Extract_raw_csv_logs.parser ()
  |> Transform.map Parse_request_field.apply
  |> Transform.map Derive_date_and_hour.apply
  |> Transform.map Categorize_endpoint_type.apply
  |> Transform.group_by_aggregate
       ~key:(fun row -> int_of_string (Row.get_exn "request_hour" row))
       ~init:Aggregate_hourly.init
       ~reduce:Aggregate_hourly.reduce
       ~emit:Aggregate_hourly.emit
  |> Csv_loader.load ~file:output_file ~headers:Load_hourly_summary.output_headers
  |> Pipeline.run
```

The current example pipeline reads declaratively top-to-bottom. It stays lazy until the loader consumes the final sequence.

---

*End of Design Document*
