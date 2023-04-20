package = "santoku"
version = "0.0.15-1"
rockspec_format = "3.0"

source = {
  url = "git+ssh://git@github.com/broma0/lua-santoku.git"
}

description = {
  homepage = "https://broma0.github.io/lua-santoku",
  license = "MIT"
}

-- TODO: can we do optional dependencies for
-- things like luafilesystem, socket, sqlite,
-- posix, etc?
dependencies = {
  "lua >= 5.1",
  "luafilesystem >= 1.8.0-1"
}

test_dependencies = {
  "busted >= 2.1.1",
  "luacov >= 0.15.0",
  "luacheck >= 1.1.0-1",
  "lsqlite3 >= 0.9.5",
}

build = {

  type = "builtin",

  modules = {

    ["santoku.gen"] = "src/lib/santoku/gen.lua",
    ["santoku.string"] = "src/lib/santoku/string.lua",
    ["santoku.template"] = "src/lib/santoku/template.lua",
    ["santoku.table"] = "src/lib/santoku/table.lua",
    ["santoku.vector"] = "src/lib/santoku/vector.lua",
    ["santoku.tree"] = "src/lib/santoku/tree.lua",
    ["santoku.fun"] = "src/lib/santoku/fun.lua",
    ["santoku.compat"] = "src/lib/santoku/compat.lua",

    ["santoku.random"] = "src/lib/santoku/random.lua",
    ["santoku.statistics"] = "src/lib/santoku/statistics.lua",
    ["santoku.validation"] = "src/lib/santoku/validation.lua",

    ["santoku.env"] = "src/lib/santoku/env.lua",
    ["santoku.fs"] = "src/lib/santoku/fs.lua",
    ["santoku.inherit"] = "src/lib/santoku/inherit.lua",
    ["santoku.op"] = "src/lib/santoku/op.lua",
    ["santoku.assert"] = "src/lib/santoku/assert.lua",
    ["santoku.co"] = "src/lib/santoku/co.lua",
    ["santoku.tuple"] = "src/lib/santoku/tuple.lua",
    ["santoku.err"] = "src/lib/santoku/err.lua",
    ["santoku.system"] = "src/lib/santoku/system.lua",
    ["santoku.bundle"] = "src/lib/santoku/bundle.lua",

    ["santoku.posix"] = "src/lib/santoku/posix.lua",
    ["santoku.socket"] = "src/lib/santoku/socket.lua",
    ["santoku.sqlite"] = "src/lib/santoku/sqlite.lua",

  }

}

test = {
  type = "command",
  command = "sh test/lib/run.sh"
}
