# Implementation Notes

## Project layout

```text
lib/
  core/
    row.ml(.mli)
    column.ml(.mli)
    schema.ml(.mli)
  pipeline/
    pipeline.ml(.mli)
    transform.ml(.mli)
  extract/
    extractor.ml(.mli)
    csv_extractor.ml(.mli)
  load/
    loader.ml(.mli)
    csv_loader.ml(.mli)
  etl.ml(.mli)
test/
  test_row.ml
  test_column.ml
  test_transform.ml
  test_pipeline.ml
  test_csv_io.ml
```

## Core behavior

### Row
- Immutable `Map.Make(String)` representation.
- All setters/removers return new rows.
- Supports map/list/array conversions and lookups.

### Column (GADTs)
- Typed descriptors: `String`, `Int`, `Float`, `Bool`, `Option`.
- `get` parses and returns `('a, string) result`.
- `set` serializes typed values back into row strings.
- `Option` parsing returns `Ok None` for missing/unparseable values.

### Schema
- Stores heterogeneous columns via existential wrapper.
- `validate` enforces required-field presence.
- Optional columns are excluded from required presence checks.

## Pipeline and transforms

- Pipeline is modeled as `'a Seq.t`.
- Composition uses function chaining (`compose`), and `run` forces evaluation.
- Transform module is pure and stateless:
  - `map` (transforms `Ok`, passes `Error` through)
  - `filter` (filters `Ok`, passes `Error` through)
  - `filter_ok`
  - `flat_map` (expands `Ok`, passes `Error` through)
  - `reduce` (terminal, returns `Error` on first error row)
  - `group_by_aggregate` (materialization barrier; aggregates `Ok`, forwards `Error`)
  - strict variants: `map_strict`, `filter_strict`, `flat_map_strict`, `reduce_strict`, `group_by_aggregate_strict`

## Extract and load boundaries

### CSV extractor
- Reads input lazily line-by-line.
- Optional header skipping (`has_header`).
- Uses caller-provided parser: `string array -> (Row.t, string) result`.
- Propagates parsing output as values in stream.

### CSV loader
- Writes headers first, then streams rows incrementally.
- Missing row fields serialize as empty strings.
- Handles CSV escaping for delimiters, quotes, and line breaks.

## Error model and purity boundary

- Errors are values (`result`) in extraction/parsing and transform flow.
- Transforms do not perform I/O.
- File I/O is isolated to extractor/loader modules.

## Scope exclusions in this implementation

1. No end-to-end example pipeline implementation.
2. No imperative benchmark or comparison module.
