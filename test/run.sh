#!/bin/sh

# TODO: getopts to parse iterate options:
#   - test/cov everything
#   - test/cov single with summary of missed
#     lines
#   - custom reporter that understands functions

# TODO: write this in lua

cd "$(dirname "$0")"

LUA=$(luarocks config lua_interpreter)

run()
{
  rm -f \
    luacov.stats.out \
    luacov.report.out
  if [ "$#" = "0" ]
  then
    covmatch=""
    test_files="spec"
    source_files="../src"
  else
    covmatch="NR < 4 $(echo "$@" | sed 's/\(\S*\)/|| match(\$0, \"\1\")/')"
    test_files="$(echo "$@" | sed 's/src/spec/')"
    source_files="../$@"
  fi
  echo
  if LUA_PATH="../src/?.lua;$LUA_PATH;" \
    $LUA -lluacov ../src/santoku-cli.lua test "$test_files"
  then
    luacov -c luacov.lua
    cat luacov.report.out | \
      awk '/^Summary/ { P = NR } P && NR > P + 1' | \
      awk "$covmatch { print }"
    echo
    luacheck --config luacheck.lua "$source_files"
  fi
}

iterate()
{
  while true; do
    run "$@"
    inotifywait -qqr ../src spec *.lua run.sh \
      -e modify \
      -e close_write
  done
}

[ -z "$1" ] && set run

"$@"
