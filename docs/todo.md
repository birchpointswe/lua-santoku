# Now

- Basic README
- Documentation
- Refactor gen, fn, etc to use compat.hasmeta

- Support calling generators in a generic for
  loop
- template: allow `<%- ... %>` or similar to
  indicate that prefix should not be interpreted
- tuple equality: tup(1, 2) == tup(1, 2)
- stack.pop should accept "n"

- Add missing asserts

- Consider making async a submodule of gen, so
  gen.ivals():async():each(...) is possible

- Figure out the boundaries of gen, tuple, fun,
  async and vec.
  - fun: higher-order functions and functional
    helpers
  - async: implements async control flow with
    cogens and pcall
  - tuple: direct manipulation of varargs
  - gen: generators
  - vec: direct manipulation of vectors

- expand async: map, filter, etc.
    - What is needed in async, and what is
      already covered by cogen?

- Separate libraries for optional dependencies

- Allow async tests
- Test: tags don't always show up correctly when
  errors occur (e.g what should print "a: b: c"
  ends up printing just "c")

- Test: show failing line numbers

# Next

- 100% test coverage
- Complete inline TODOs

# Eventually

- Benchmark gen, tuple, vec

- Ensure we're using tail calls (return fn(...))

- os.getenv wrapper that fails if missing
- sqlite helper for automatically computing
  column names for inserts and updates
- Helper to reduce pairs of key/vals into a
  table
- gen.sum, vec.sum, etc

- Write a true generic PDF parser

- Table validation library

- Pwrap
    - Refactor and move to "check" module that
      exports a function with the following
      arguments:
        - Arg 1: function wrapping a body of
          code to execute that is passed a
          "maybe" function that when passed
          "true, ...", returns "..." and when
          passed "false, ..." calls the handler
          function
        - Arg 2: the handler function that
          causes the outer "check" to return
          "false, ..." by returns "false, ..."
          or causes the inner "maybe" to return
          "..." by returning "true, ..."
    - Any error thrown inside the body function
      causes "check" to return "false, ..."

- Create an assert module/function that
  stringifies the remaining arguments with ":"
  before passing to assert

- Functional utils for indexed arg
  get/set/del/map, filter, etc (basically
  immutable versions of vec/gen functions)

- Template nested skip/show blocks

- Add a "package" module to support checking if
  shell programs are installed and gracefully
  bailing if not. Futher extend to a generic
  project scripting tool
