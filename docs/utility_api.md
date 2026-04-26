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
  ~parser:(string array -> 'a)
  unit
  -> 'a Seq.t
```

### Parameters

* `~file` : CSV file path
* `?delimiter` : separator character (default `,`)
* `?has_header` : skip first row (default `true`)
* `~parser` : converts columns into desired type

### Returns

Lazy sequence of parsed rows.

---

### Example

```ocaml id="6jvw3g"
let rows =
  extract
    ~file:"users.csv"
    ~parser:(fun cols ->
      (cols.(0), int_of_string cols.(1)))
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
("Alice",25)
("Bob",30)
```

---

# 2. Transform Module

Utilities for processing sequences.

---

## `map`

```ocaml id="jlwmh8"
map : ('a -> 'b) -> 'a Seq.t -> 'b Seq.t
```

Apply function to each row.

### Example

```ocaml id="c2ef0w"
Transform.map (fun (n,a) -> (n, a+1)) rows
```

---

## `filter`

```ocaml id="ctnl7y"
filter : ('a -> bool) -> 'a Seq.t -> 'a Seq.t
```

Keep matching rows only.

### Example

```ocaml id="s9o4vz"
Transform.filter (fun (_,age) -> age >= 18) rows
```

---

## `reduce`

```ocaml id="s05lff"
reduce : ('acc -> 'a -> 'acc) -> 'acc -> 'a Seq.t -> 'acc
```

Fold rows into one value.

### Example

```ocaml id="9hajd0"
Transform.reduce (fun sum (_,age) -> sum + age) 0 rows
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
flat_map : ('a -> 'b Seq.t) -> 'a Seq.t -> 'b Seq.t
```

One input row can produce many rows.

### Example

```ocaml id="d6csgg"
flat_map (fun x -> List.to_seq [x; x*10]) (List.to_seq [1;2])
```

Produces:

```ocaml id="3t37m0"
1,10,2,20
```

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

Group rows and aggregate values.

### Example

```ocaml id="xntd9y"
group_by_aggregate
  ~key:(fun (dept,sal) -> dept)
  ~init:0
  ~reduce:(fun total (_,sal) -> total + sal)
  ~emit:(fun dept total -> (dept,total))
  rows
```

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
    ~parser:(fun c -> (c.(0), int_of_string c.(1)))
    ()
  |> Transform.filter (fun (_,age) -> age >= 18)
```

Then save transformed data using loader.

---

# Error Handling Summary

| Module    | Behavior                              |
| --------- | ------------------------------------- |
| Extractor | Raises on parser/file errors          |
| Transform | User-defined (exceptions or `result`) |
| Loader    | Raises on write errors                |

---

# Recommended Usage Pattern

Use `result` rows + `filter_ok` for robust ETL pipelines.

