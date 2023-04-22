# Now

- Convert to makefile-driven build 

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

- 100% test coverage 

- Functional utils for maybe applying functions
  based on boolean first arg, indexed arg
  get/set/del/map, filter, etc (basically
  immutable versions of vec/gen functions) 

# Next

- Extend package module to support checking if
  shell programs are installed and gracefully
  bailing if not. Futher extend to a generic
  project scripting tool

# Eventually

- Template nested skip/show blocks
