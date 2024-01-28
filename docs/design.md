# High-Level Design

- Programmer errors throw exceptions
- Runtime errors return true/false then results or errors

## Core Library

Any stdlib-like functionality goes here. It must be zero-dependency, but can
include portable C code.

- functional: functional utilities
- varg: argument list utilities
- table: general table utilities
- array: array-like table utilities
- iter: iterator utilities
- co: nested coroutines
- capi: wrappers around Lua c-api
- check: coroutine-based error handling and control flow
- compat: general low-level utilities
- env: environment utilities
- meta: metatable utilities
- profile: performance profiler
- coverage: coverage analyzer (TODO)
- op: wrap operators as functions
- serialize: convert Lua values to strings
- string: string utilities
- test: basic test framework (TODO: integrate from santoku-test)

## Core-Extension Libraries

- fs: posix filesystem utilities
- system: posix process utilities
- matrix: numerical operations with BLAS
- template: file templating
- make: framework similar to posix make

## Auxiliary libraries

- cli: cli interface to some of these libraries
- geo: geospatial utilities (TODO: move to separate lib)
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
