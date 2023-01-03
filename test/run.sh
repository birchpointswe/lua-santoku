#!/bin/sh

cd "$(dirname "$0")/.."

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
  echo
  busted -f test/busted.lua test/spec "$@"
  awk '/^Summary/ { P = NR } P && NR > P + 1' \
    test/luacov.report.out
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
