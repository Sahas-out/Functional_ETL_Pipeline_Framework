# Functional ETL Pipeline

Functional ETL framework in **OCaml** with a design centered on:
- pure, composable transforms
- lazy `Seq.t` streaming
- immutable row operations
- side-effect boundaries at extract/load layers

## What is implemented

Library modules are implemented under `lib/`:

- `core/`
  - `Row`: immutable row map utilities
  - `Column`: GADT-based typed access (`String`, `Int`, `Float`, `Bool`, `Option`)
  - `Schema`: schema construction/validation helpers
- `pipeline/`
  - `Pipeline`: composition and run helpers
  - `Transform`: `map`, `filter`, `filter_ok`, `flat_map`, `reduce`, `group_by_aggregate`
- `extract/`
  - generic extractor interface
  - lazy CSV extractor
- `load/`
  - generic loader interface
  - CSV loader with escaping and ordered headers
- `etl.ml`
  - top-level API re-exports

Tests are added under `test/` for core modules, transforms, pipeline composition, and CSV I/O behavior.

## Project scope for this implementation

Per current project direction, this implementation intentionally **excludes**:
1. building an end-to-end example pipeline in `examples/`
2. imperative-vs-functional benchmark comparison

## Repository contents

- `ProblemStatement.md` — challenge statement
- `Specifications.md` — formal requirements
- `Design.md` — design blueprint
- `Implementation.md` — implementation details and module behavior

## How to run pipelines and record metrics

- functional pipeline 
    `dune build 
    dune exec ./pipelines/functional_ocaml/main.exe -- data/nasa_aug95_c.csv data/hourly_summary_functional.csv`
    `to record metrics add /usr/bin/time -v before above command`


- imperative pipeline
    `source .venv/bin/activate`
    `python3 pipelines/imperative_pandas/pipeline.py data/nasa_aug95_c.csv data/hourly_summary_imperative.csv`
    `for cprofiling python3 -m cProfile pipelines/imperative_pandas/pipeline.py data/nasa_aug95_c.csv data/hourly_summary_imperative.csv`
