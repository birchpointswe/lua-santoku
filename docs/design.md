# High-Level Design

## Core Library: Strictly Portable Lua & C

- io: wraps functions returning nil to throw errors instead
- os: same as io, extends getenv, adds interpreter
- math: merges atan and atan2, adds trunc, adds geospatial utilities
- coroutine: adds nest() for nested corotines
- package: adds searchpath

- table: additional array and dictionary style table APIs
- string: split, match, iterators, etc

- iterator: functional iterator APIs
- functional: functional primitives
- vararg: variable argument list utilities
- error: better pcall, error, assert, etc.
- lua: consolidated metatable, meta-programming, debug, etc utilities
- op: lua operators as functions

- test: basic test wrapper
- validate: various validations that can be passed to assert
- profile: basic profiler
- coverage: basic coverage analyzer
- serialize: serialize values to strings that can be re-loaded

## Companion Libraries: Dependent on POSIX & External Libraries

- cli: cli interface to some of these libraries
- fs: posix filesystem utilities
- system: posix process utilities
- template: file templating
- matrix: numerical operations with BLAS
- make: framework similar to posix make

- docs: documentation generator

- iconv: charset conversion
- html: streaming html parser
- sqlite: sqlite utilities
- sqlite-migrate: sqlite ddl migration utilities

- web: javascript interop for WASM
- python: python interop

- geo-pdf: geo-pdf manipulation
- porter: porter stemmer
- jpeg: jpeg scaling
- test-runner: test runner
- sts: semantic textual similarity (TODO: move from tbhss)
