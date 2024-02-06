# Now

- io, os, math, coroutine, package

- Env
    - Move env to os
    - Move searchpath to package

- Iter
    - Iterator as first argument to functions
    - iter.extend for extending interator into table
    - Finish migration
    - Intersperse/interleave
    - Zip

- Array, Table
    - Merge into single table library

- Template
    - License

- String
    - Indentation
    - Interp: handle escaped %s in the format string
    - Escape & unescape: Single argument escapes for use with lua patterns,
      additional arguments allows escaping other characters with escape strings

- Profile
    - Call hierarchy
    - C calls
    - Memory

- Coverage
    - Lightweight replacement to Luacov
    - Integrates with gcc gcda/gcdo files

- Other
    - Add licensing and copyright
    - Deprecate santoku-test
    - Remove luassert
    - Remove luacheck as dependency (use via toku lib/web test)
    - Extract common c-helpers in into an includable c file

# Consider

- Error
    - Expose error strings as module properties
    - Consistent argument error messages between Lua and C (use checkopt,
      optstring, etc?)

- Lua
    - Utility to clear most basic library global methods (pairs, ipairs,
      setfenv, etc))
    - Require/import utility to automatically localize functions without having
      to write require("a") a.x = x, a.y = y, a million times

- Validate
    - Table schema validation

- System
    - Utility to check for required installed programs

- Repl
    - Better lua REPL

- Benchmark
    - New lib with simple benchmark helpers

- Template
    - Allow injecting strings without "return"
