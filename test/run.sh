#!/bin/sh

# TODO: getopts to parse iterate options:
#   - test/cov everything
#   - test/cov single with summary of missed
#     lines
#   - custom reporter that understands functions

# TODO: include luacheck

cd "$(dirname "$0")/.."

LUA=$(luarocks config lua_interpreter)

run()
{
  rm -f \
    test/luacov.stats.out \
    test/luacov.report.out
  if [ "$1" = "--build" ]
  then
    luarocks build
    shift
  fi
  if [ "$#" = "0" ]
  then
    set -- test/spec
  else
    set -- $1
  fi
  echo
  if busted --lua="$LUA" -f test/busted.lua "$@" && \
    luacheck --lua="$LUA" -q src
  then
    luacov -c test/luacov.lua
    if [ "$1" != "test/spec" ]
    then
      p=$(echo "$1" | sed 's/test\/spec\//src\//')
      cat test/luacov.report.out | \
        awk '/^Summary/ { P = NR } P && NR > P + 1' | \
        awk "NR < 4 || match(\$0, \"$p\") { print }"
    else
      cat test/luacov.report.out | \
        awk '/^Summary/ { P = NR } P && NR > P + 1'
    fi
  fi
}

iterate()
{
  while true; do
    run "$@"
    inotifywait -qqr src test/spec test/*.lua test/run.sh \
      -e modify \
      -e close_write
  done
}

[ -z "$1" ] && set run

"$@"
