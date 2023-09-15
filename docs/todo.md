# Now

- Basic README
- Write a true generic PDF parser
- os.getenv wrapper that fails if missing
- sqlite helper for automatically computing
  column names for inserts and updates
- Helper to reduce pairs of key/vals into a
  table
- gen.sum, vec.sum, etc
- Documentation

# Next

- Test: tags don't always show up correctly when
  errors occur (e.g what should print "a: b: c"
  ends up printing just "c")
- Test: show failing line numbers

- 100% test coverage
- Complete inline TODOs

# Eventually

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

- Benchmark tuples, vectors, generators

- Create an assert module/function that
  stringifies the remaining arguments with ":"
  before passing to assert

- Allow async tests

- Functional utils for indexed arg
  get/set/del/map, filter, etc (basically
  immutable versions of vec/gen functions)

- Template nested skip/show blocks

- Add a "package" module to support checking if
  shell programs are installed and gracefully
  bailing if not. Futher extend to a generic
  project scripting tool
