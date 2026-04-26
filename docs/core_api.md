# Short API Documentation

---

# `Row` Module

Stores one data record as:

```ocaml id="9p6y95"
field_name -> string_value
```

Type:

```ocaml id="efg7n9"
Row.t
```

## Functions

### `Row.empty`

Create empty row.

```ocaml id="c1x6s2"
let r = Row.empty
```

---

### `Row.of_list`

Create row from key-value pairs.

```ocaml id="v7z2w8"
let r = Row.of_list [("name","Alice"); ("age","25")]
```

---

### `Row.of_array`

Create row from headers + values.

```ocaml id="kg4m0n"
Row.of_array
  [|"name"; "age"|]
  [|"Alice"; "25"|]
```

---

### `Row.set`

Add/update field.

```ocaml id="lz2f8r"
let r2 = Row.set "age" "30" r
```

---

### `Row.get`

Safe lookup.

```ocaml id="23qt70"
Row.get "name" r
(* Some "Alice" *)
```

---

### `Row.get_exn`

Lookup or raise exception.

```ocaml id="lq1w4p"
Row.get_exn "name" r
```

---

### `Row.unset`

Remove field.

```ocaml id="7bhw7d"
Row.unset "age" r
```

---

# `Column` Module

Defines typed columns for rows.

Type:

```ocaml id="t7ij4l"
'a Column.t
```

---

## Constructors

### String column

```ocaml id="jw2qf2"
Column.String "name"
```

### Int column

```ocaml id="yzp5n6"
Column.Int "age"
```

### Float column

```ocaml id="7tw0q7"
Column.Float "salary"
```

### Bool column

```ocaml id="7e91os"
Column.Bool "active"
```

### Optional column

```ocaml id="j7x1r9"
Column.Option (Column.Int "age")
```

---

## Functions

### `Column.name_of`

Get field name.

```ocaml id="l7e1z5"
Column.name_of (Column.Int "age")
(* "age" *)
```

---

### `Column.get`

Read typed value from row.

```ocaml id="7d5w52"
Column.get (Column.Int "age") row
(* Ok 25 *)
```

---

### `Column.get_exn`

Read typed value or raise exception.

```ocaml id="q7i7r8"
Column.get_exn (Column.Int "age") row
```

---

### `Column.set`

Write typed value into row.

```ocaml id="00x8zj"
Column.set (Column.Int "age") 25 Row.empty
```

---

# `Schema` Module

Defines expected row structure.

Type:

```ocaml id="m2c2h3"
Schema.t
```

Internally: list of columns.

---

## Functions

### `Schema.make`

Create schema.

```ocaml id="h0zz3l"
let schema =
  Schema.make [
    Column.Any (Column.String "name");
    Column.Any (Column.Int "age");
  ]
```

---

### `Schema.validate`

Check required fields exist in row.

```ocaml id="z0f89e"
Schema.validate schema row
(* true / false *)
```

---

### `Schema.validate_types`

Check schema presence and type correctness.

```ocaml id="schema-validate-types"
Schema.validate_types schema row
(* true / false *)
```

---

### `Schema.parse_row`

Build row from schema field order, then validate presence + types.

```ocaml id="schema-parse-row"
Schema.parse_row schema [|"Alice"; "25"|]
(* Ok Row.t or Error "..." *)
```

---

### `Schema.field_names`

Get all column names.

```ocaml id="u2j6dv"
Schema.field_names schema
(* ["name"; "age"] *)
```

---

# Minimal Full Example

```ocaml id="lvv7qt"
let row =
  Row.of_list [("name","Alice"); ("age","25")]

let schema =
  Schema.make [
    Column.Any (Column.String "name");
    Column.Any (Column.Int "age");
  ]

Schema.validate schema row
(* true *)

Column.get (Column.Int "age") row
(* Ok 25 *)
```

---

# Summary

* `Row` → raw string data
* `Column` → typed field access
* `Schema` → row structure + type validation
