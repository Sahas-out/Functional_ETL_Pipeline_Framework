# ETL Library – Short API Documentation

This library has three modules:

1. **Extractor** – read CSV into rows
2. **Transform** – process row streams
3. **Loader** – write rows to CSV

Most functions work with:

```ocaml id="c6jwji"
Seq.t
```

A lazy sequence of values.

---

# 1. Extractor Module

Reads CSV files and converts each line using a parser.

---

## `extract`

```ocaml id="6k9xgl"
extract
  ~file:string
  ?delimiter:char
  ?has_header:bool
  ~parser:(string array -> ('a, string) result)
  unit
  -> ('a, string) result Seq.t
```

### Parameters

* `~file` : CSV file path
* `?delimiter` : separator character (default `,`)
* `?has_header` : skip first row (default `true`)
* `~parser` : converts columns into desired type or error

### Returns

Lazy sequence of parsed rows where parser exceptions become `Error` values.

---

### Example

```ocaml id="6jvw3g"
let rows =
  extract
    ~file:"users.csv"
    ~parser:(fun cols ->
      Ok (cols.(0), int_of_string cols.(1)))
    ()
```

CSV:

```text id="4m1ghw"
name,age
Alice,25
Bob,30
```

Produces:

```ocaml id="ub5vxj"
Ok ("Alice",25)
Ok ("Bob",30)
```

---

## `extract_strict`

Same signature as `extract`, but parser exceptions are re-raised.

Use when you explicitly want fail-fast extraction behavior.

---

# 2. Transform Module

Utilities for processing sequences.

---

## `map`

```ocaml id="jlwmh8"
map : ('a -> 'b) -> ('a, 'e) result Seq.t -> ('b, 'e) result Seq.t
```

Apply function to `Ok` rows and propagate `Error` rows unchanged.

### Example

```ocaml id="c2ef0w"
Transform.map (fun (n,a) -> (n, a+1)) result_rows
```

---

## `filter`

```ocaml id="ctnl7y"
filter : ('a -> bool) -> ('a, 'e) result Seq.t -> ('a, 'e) result Seq.t
```

Filter only `Ok` rows and propagate `Error` rows unchanged.

### Example

```ocaml id="s9o4vz"
Transform.filter (fun (_,age) -> age >= 18) result_rows
```

---

## `reduce`

```ocaml id="s05lff"
reduce : ('acc -> 'a -> 'acc) -> 'acc -> ('a, 'e) result Seq.t -> ('acc, 'e) result
```

Fold `Ok` rows into one value. Returns `Error` immediately when an error row is encountered.

### Example

```ocaml id="9hajd0"
Transform.reduce (fun sum (_,age) -> sum + age) 0 result_rows
```

---

## `filter_ok`

```ocaml id="ys3j94"
filter_ok : ('a, 'e) result Seq.t -> 'a Seq.t
```

Keep only `Ok` values, discard `Error`.

### Example

```ocaml id="i3eq0u"
[Ok 1; Error "bad"; Ok 2] |> filter_ok
```

Produces:

```ocaml id="s5n4a4"
1,2
```

---

## `flat_map`

```ocaml id="n7e7zj"
flat_map : ('a -> 'b Seq.t) -> ('a, 'e) result Seq.t -> ('b, 'e) result Seq.t
```

One `Ok` row can produce many rows. `Error` rows pass through untouched.

### Example

```ocaml id="d6csgg"
flat_map (fun x -> List.to_seq [x; x*10]) (List.to_seq [Ok 1; Error "bad"; Ok 2])
```

Produces:

```ocaml id="3t37m0"
Ok 1, Ok 10, Error "bad", Ok 2, Ok 20
```

---

## `map_strict`

```ocaml id="map-result"
map_strict : ('a -> 'b) -> 'a Seq.t -> 'b Seq.t
```

Strict map on plain sequences (`'a Seq.t`).

---

## `filter_strict`

```ocaml id="filter-result"
filter_strict : ('a -> bool) -> 'a Seq.t -> 'a Seq.t
```

Strict filter on plain sequences (`'a Seq.t`).

---

## `flat_map_strict`

```ocaml id="flat-map-result"
flat_map_strict : ('a -> 'b Seq.t) -> 'a Seq.t -> 'b Seq.t
```

Strict flat_map on plain sequences (`'a Seq.t`).

---

## `reduce_strict`

```ocaml id="reduce-strict"
reduce_strict : ('acc -> 'a -> 'acc) -> 'acc -> 'a Seq.t -> 'acc
```

Strict reduce on plain sequences (`'a Seq.t`).

---

## `group_by_aggregate`

```ocaml id="qjlwm7"
group_by_aggregate
  ~key
  ~init
  ~reduce
  ~emit
  seq
```

Aggregate `Ok` rows by key and propagate `Error` rows unchanged.

### Example

```ocaml id="xntd9y"
group_by_aggregate
  ~key:(fun (dept,sal) -> dept)
  ~init:0
  ~reduce:(fun total (_,sal) -> total + sal)
  ~emit:(fun dept total -> (dept,total))
  result_rows
```

---

## `group_by_aggregate_strict`

Strict aggregation on plain sequences (`'a Seq.t`).

---

# 3. Loader Module

Writes rows to CSV.

Assumes rows support:

```ocaml id="d4w3wi"
Row.get : string -> row -> string option
```

---

## `load`

```ocaml id="6ij4qb"
load
  ~file:string
  ?delimiter:char
  ~headers:string list
  row Seq.t
  -> unit
```

### Parameters

* `~file` : output CSV path
* `?delimiter` : separator (default `,`)
* `~headers` : CSV column order
* rows : sequence of rows

Missing fields become empty strings.

---

### Example

```ocaml id="9gikxw"
load
  ~file:"out.csv"
  ~headers:["name"; "age"]
  rows
```

Output:

```text id="5j0f95"
name,age
Alice,25
Bob,30
```

---

# Typical Pipeline Example

```ocaml id="vz65hx"
let rows =
  Extractor.extract
    ~file:"users.csv"
    ~parser:(fun c -> Ok (c.(0), int_of_string c.(1)))
    ()
  |> Transform.filter (fun (_,age) -> age >= 18)
```

Then save transformed data using loader.

---

# Error Handling Summary

| Module    | Behavior                              |
| --------- | ------------------------------------- |
| Extractor | `extract` returns `Error` rows; `extract_strict` raises parser exceptions |
| Transform | User-defined (exceptions or `result`) |
| Loader    | Raises on write errors                |

---

# Recommended Usage Pattern

Use `result` rows with default transforms; use `*_strict` only for plain streams.
