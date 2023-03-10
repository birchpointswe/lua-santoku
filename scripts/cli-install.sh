#!/bin/sh

set -e

[ -z "$LUA_INTERP" ] && \
  LUA_INTERP=$(luarocks config lua_interpreter)

[ -z "$LUA_LUADIR" ] && \
  LUA_LUADIR=$(luarocks config deploy_lua_dir)

[ -z "$LUA_BINDIR" ] && \
  LUA_BINDIR=$(luarocks config deploy_bin_dir)

luarocks make santoku-cli*.rockspec

# TODO: Use install cat redirect
mkdir -p ${LUA_BINDIR}
cat > ${LUA_BINDIR}/toku <<EOF
#!/bin/sh
$LUA_INTERP $LUA_LUADIR/santoku/cli.lua "\$@"
EOF

chmod +x ${LUA_BINDIR}/toku

echo Installed to ${LUA_BINDIR}/toku
echo Make sure it is on your PATH
