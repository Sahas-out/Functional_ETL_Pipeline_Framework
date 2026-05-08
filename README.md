# Functional ETL Pipeline (OCaml)

## Summary

Built a **functional ETL framework in OCaml** that demonstrates production-style data engineering design:

- Designed a composable transformation engine with `map`, `filter`, `flat_map`, `reduce`, and grouped aggregation.
- Implemented **lazy streaming ETL** using `Seq.t` to process CSV data without loading full datasets into memory.
- Modeled rows and schema handling with immutable data structures and typed column access (GADT-based).
- Kept side effects isolated to extract/load boundaries for maintainable, testable pipeline logic.
- Added test coverage across core modules, pipeline composition, transforms, and CSV I/O behaviors.

## Tech stack and concepts

**Languages & tools:** OCaml, Dune, Python (for imperative baseline pipeline), CSV processing  
**Concepts:** functional architecture, immutable data modeling, lazy evaluation, typed APIs, ETL design, test-driven module validation

## What is implemented

Library modules in `lib/`:

- `core/`
  - `Row`: immutable row map utilities
  - `Column`: GADT-based typed access (`String`, `Int`, `Float`, `Bool`, `Option`)
  - `Schema`: schema construction and validation helpers
- `pipeline/`
  - `Pipeline`: composition and execution helpers
  - `Transform`: `map`, `filter`, `filter_ok`, `flat_map`, `reduce`, `group_by_aggregate`
- `extract/`
  - generic extractor interface
  - lazy CSV extractor
- `load/`
  - generic loader interface
  - CSV loader with escaping and ordered headers
- `etl.ml`
  - top-level API re-exports

Tests are under `test/` for core modules, schema validation, transforms, pipeline composition, and CSV I/O behavior.

## Scope notes

The repo keeps the runnable example pipeline in `pipelines/functional_ocaml/` and the imperative baseline in `pipelines/imperative_pandas/`; there is no separate `examples/` or `bench/` tree.

## How to run pipelines and capture metrics

### Functional pipeline (OCaml)

```bash
dune build
dune exec ./pipelines/functional_ocaml/main.exe -- \
  data/nasa_aug95_c.csv data/hourly_summary_functional.csv
```

To capture runtime and memory metrics:

```bash
/usr/bin/time -v dune exec ./pipelines/functional_ocaml/main.exe -- \
  data/nasa_aug95_c.csv data/hourly_summary_functional.csv
```

### Imperative pipeline (Python / Pandas baseline)

```bash
source .venv/bin/activate
python3 pipelines/imperative_pandas/pipeline.py \
  data/nasa_aug95_c.csv data/hourly_summary_imperative.csv
```

For profiling:

```bash
python3 -m cProfile pipelines/imperative_pandas/pipeline.py \
  data/nasa_aug95_c.csv data/hourly_summary_imperative.csv
```

## Repository contents

- `docs/ProblemStatement.md` — challenge statement
- `docs/Specifications.md` — formal requirements
- `docs/Design.md` — design blueprint
- `docs/Implementation.md` — implementation details and module behavior
