#!/bin/sh

set -e

LUA_ENV=$(luarocks path)
LUA_INTERP=$(luarocks config lua_interpreter)
LUA_LUADIR=$(luarocks config deploy_lua_dir)
LUA_BINDIR=$(luarocks config deploy_bin_dir)

# TODO: Use install instad of cp 
cp --no-clobber src/cli.lua $LUA_LUADIR/santoku/cli.lua

mkdir -p ${LUA_BINDIR}

# TODO: Use install cat redirect
cat > ${LUA_BINDIR}/toku <<EOF
#!/bin/sh
$LUA_ENV
$LUA_INTERP $LUA_LUADIR/santoku/cli.lua "\$@"
EOF

chmod +x ${LUA_BINDIR}/toku

echo Installed to ${LUA_BINDIR}/toku
echo Make sure it is on your PATH
