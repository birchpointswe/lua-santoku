local env = {

  name = "santoku",
  version = "0.0.123-1",
  variable_prefix = "TK",
  license = "MIT",
  public = true,

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

  },

  test_dependencies = {
    "inspect >= 3.1.3-0",
    "lsqlite3 >= 0.9.5",
    "lua-zlib >= 1.2-2",
    "luacheck >= 1.1.0-1",
    "luacov >= 0.15.0-1",
    "luaposix >= 36.2.1-1",
    "luassert >= 1.9.0-1",
  },

}

env.homepage = "https://github.com/treadwelllane/lua-" .. env.name
env.tarball = env.name .. "-" .. env.version .. ".tar.gz"
env.download = env.homepage .. "/releases/download/" .. env.version .. "/" .. env.tarball

return {
  env = env,
  excludes = {
    "lib/santoku/template.lua",
    "test/spec/santoku/template.lua",
    "test/spec/santoku/cli/template.lua"
  },
}

