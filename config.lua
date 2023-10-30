local _ENV = {}

name = "santoku"
version = "0.0.94-1"
variable_prefix = "TK"

license = "MIT"

luacov_include = {
  "^%./santoku.*"
}

-- TODO: can we do optional dependencies for
-- things like luafilesystem, socket, sqlite,
-- posix, etc?
--
-- TODO: Create a santoku lib to gracefully wrap
-- functions which require an optional
-- dependency
dependencies = {

  "lua >= 5.1",

  -- Optional dependencies:

  -- "lua-zlib >= 1.2-2",
  -- "luafilesystem >= 1.8.0-1",
  -- "lsqlite3 >= 0.9.5",
  -- "inspect >= 3.1.3-0"

}

test_dependencies = {
  "luacov >= 0.15.0",
  "luacheck >= 1.1.0-1",
  "lua-zlib >= 1.2-2",
  "luafilesystem >= 1.8.0-1",
  "lsqlite3 >= 0.9.5",
  "inspect >= 3.1.3-0",
  "luassert >= 1.9.0-1"
}

homepage = "https://github.com/treadwelllane/lua-" .. name
tarball = name .. "-" .. version .. ".tar.gz"
download = homepage .. "/releases/download/" .. version .. "/" .. tarball

return {
  env = _ENV,
  excludes = {
    "src/santoku/template.lua",
    "test/spec/santoku/template.lua",
    "test/spec/santoku/cli/template.lua"
  },
}
