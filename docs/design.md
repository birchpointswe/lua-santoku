# High-Level Design

## Core Library

Any stdlib-like functionality goes here. It must be zero-dependency, but can
include portable C code.

- varg: argument list utilities
- table: general table utilities
- array: array-like table utilities
- iter: iterator utilities
- co: nested coroutines (TODO: coro utils, coro tuple, refactor)
- num: wrapper around math
- lua: lua metaprogramming and related c-api wrappers
- error: error handling
- validate: validation
- env: environment utilities
- meta: metatable utilities (TODO: move from inherit)
- profile: performance profiler (TODO: memory, call stack)
- coverage: coverage analyzer (TODO)
- op: wrap operators as functions
- serialize: convert Lua values to strings
- string: string utilities (TODO: various)
- test: basic test framework (TODO: integrate from santoku-test)
- geo: geospatial utilities (TODO: consider moving to separate lib)

## Core-Extension Libraries

- fs: posix filesystem utilities
- system: posix process utilities
- matrix: numerical operations with BLAS
- template: file templating
- make: framework similar to posix make

## Auxiliary libraries

- cli: cli interface to some of these libraries
- geo-pdf: geo-pdf manipulation
- porter: porter stemmer
- jpeg: jpeg scaling
- iconv: charset conversion
- html: streaming html parser
- sqlite: sqlite utilities
- sqlite-migrate: sqlite ddl migration utilities
- test-runner: test runner
- web: javascript interop for WASM
- python: python interop
- sts: semantic textual similarity (TODO: move from tbhss)

## Patterns

- Programmer errors throw exceptions
- Runtime errors return true/false then results or errors
