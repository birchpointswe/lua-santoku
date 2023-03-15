-- TODO: Figure out how to run install.sh even
-- with the builtin type. Is there a standard
-- pattern for installing an executable + helper
-- libraries? 

package = "santoku-cli"
version = "0.0.1-1"
rockspec_format = "3.0"

source = {
  url = "git+ssh://git@github.com/broma0/lua-santoku.git"
}

description = {
  homepage = "https://broma0.github.io/lua-santoku",
  license = "MIT"
}

dependencies = {
  "santoku >= 0.0.13",
}

build = {
  type = "builtin",
  modules = {
    ["santoku.cli"] = "src/cli.lua",
  }
}
