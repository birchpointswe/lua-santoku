# Now

- Implement table equality
- Consider adding an istbl to detect wrapped tables, consider renaming table to
  dictionary or something so that istbl is not confusing.
- Add copyright and MIT license to all libs
- Remove luassert from all libs (painfully slow in WASM)
- Remove luacheck from all libs (only needed on host)
- Update deps for all libs (santoku, santoku-test, etc)
- Split callmod, ephemeron, etc into header-only library that is also exposed
  via santoku.capi
- Test with profiler: isvec, hasmeta, etc. seem to take a lot of time

- err.error: consider always passing level 0 to avoid modifying the message
- Consider moving profiler to a separate module

- Documentation site generator with emscripten and santoku-web powered live
  tests
- Readline-enhanced repl

- Santoku implementation of inspect allowing literal representation of the value
  for use in toku templates (i.e. for injecting an external_dependencies) table
  into a rockspec

- str.split/etc should return a generator if the underlying vector isnt needed

- Basic README
- Documentation
- Refactor gen, fn, etc to use compat.hasmeta

- santoku.lua for binding useful c-api functions for error checking, etc

- Support calling generators in a generic for loop

- Add missing asserts

- Consider making async a submodule of gen, so gen.ivals():async():each(...) is
  possible

- Figure out the boundaries of gen, tuple, fun, async and vec.
  - fun: higher-order functions and functional helpers
  - async: implements async control flow with cogens and pcall
  - tuple: direct manipulation of varargs
  - gen: generators
  - vec: direct manipulation of vectors

- expand async: map, filter, etc.
    - What is needed in async, and what is already covered by cogen?

# Next

- 100% test coverage
- Complete inline TODOs

# Eventually

- Benchmark gen, tuple, vec

- Ensure we're using tail calls (return fn(...))

- Write a true generic PDF parser

- Table validation library

- Pwrap
    - Refactor and move to "check" module that exports a function with the
      following arguments:
        - Arg 1: function wrapping a body of code to execute that is passed a
          "maybe" function that when passed "true, ...", returns "..." and when
          passed "false, ..." calls the handler function
        - Arg 2: the handler function that causes the outer "check" to return
          "false, ..." by returns "false, ..." or causes the inner "maybe" to
          return "..." by returning "true, ..."
    - Any error thrown inside the body function causes "check" to return "false,
      ..."

- Create an assert module/function that stringifies the remaining arguments with
  ":" before passing to assert

- Functional utils for indexed arg get/set/del/map, filter, etc (basically
  immutable versions of vec/gen functions)

- Add a "package" module to support checking if shell programs are installed and
  gracefully bailing if not. Futher extend to a generic project scripting tool
