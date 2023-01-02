package = "santoku"
version = "dev-1"
rockspec_format = "3.0"
source = {
  url = "git+ssh://git@github.com/broma0/lua-examples.git"
}
description = {
  homepage = "https://broma0.github.io/lua-santoku",
  license = "MIT"
}
dependencies = {
  "lua >= 5.2",
  "luafilesystem >= 1.8.0-1"
}
test_dependencies = {
  "busted >= 2.1.1",
  "luacov >= 0.15.0"
}
build = {
  type = "builtin",
  modules = {
    ["santoku"] = "src/santoku.lua",
    ["santoku.co"] = "src/co.lua"
  }
}
test = {
  type = "command",
  command = "sh test/run.sh"
}
