#!/bin/sh

<%
  gen = require("santoku.gen")
  tbl = require("santoku.table")
%>

export LUA='<% return build.test_lua %>'
export LUA_PATH='<% return build.test_lua_path %>'
export LUA_CPATH='<% return build.test_lua_cpath %>'

<% return gen.ivals(tbl.get(test, "envs") or {}):map(function (env)
  return ". " .. env
end):concat("\n") %>

if [ -n "$TEST_CMD" ]; then

  set -x
  cd "$ROOT_DIR"
  $TEST_CMD

else

  rm -f luacov.stats.out luacov.report.out || true

  <% template:push(os.getenv(var("WASM")) == "1") %>

    # if [ -n "$TEST" ]; then
    #   TEST="spec-bundled/${TEST#test/spec/}"
    #   TEST="${TEST%.lua}"
    #   toku test -s -i "node --expose-gc" "$TEST"
    #   status=$?
    # elif [ -d spec-bundled ]; then
    #   toku test -s -i "node --expose-gc" spec-bundled
    #   status=$?
    # fi

  <% template:pop():push(os.getenv(var("WASM")) ~= "1") %>

    MODS="-l luacov"
    if [ "$<% return var("PROFILE") %>" = "1" ]; then
      MODS="$MODS -l santoku.profile"
    fi

    if [ -n "$TEST" ]; then
      TEST="${TEST#test/}"
      toku test -s -i "$LUA $MODS" "$TEST"
      status=$?
    elif [ -d spec ]; then
      toku test -s -i "$LUA $MODS" --match "^.*%.lua$" spec
      status=$?
    fi

  <% template:pop() %>

  if [ "$status" = "0" ] && type luacov >/dev/null 2>/dev/null && [ -f luacov.stats.out ] && [ -f luacov.lua ]; then
    luacov -c luacov.lua
  fi

  if [ "$status" = "0" ] && [ -f luacov.report.out ]; then
    cat luacov.report.out | awk '/^Summary/ { P = NR } P && NR > P + 1'
  fi

  echo

  if type luacheck >/dev/null 2>/dev/null && [ -f luacheck.lua ]; then
    luacheck --config luacheck.lua $(find lib bin spec -maxdepth 0 2>/dev/null)
  fi

  echo

fi
