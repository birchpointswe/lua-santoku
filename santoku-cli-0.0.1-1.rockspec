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
  type = "command",
  command = "sh scripts/cli-install.sh"
}
