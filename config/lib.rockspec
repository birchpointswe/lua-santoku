package = "<% return os.getenv('NAME') %>"
version = "<% return os.getenv('VERSION') %>"
rockspec_format = "3.0"

source = {
  url = "git+ssh://<% return os.getenv('GIT_URL') %>",
  tag = "<% return os.getenv('VERSION') %>"
}

description = {
  homepage = "<% return os.getenv('HOMEPAGE') %>",
  license = "<% return os.getenv('LICENSE') %>"
}

-- TODO: can we do optional dependencies for
-- things like luafilesystem, socket, sqlite,
-- posix, etc?
dependencies = {
  "lua >= 5.1",
  -- "luafilesystem >= 1.8.0-1",
  -- "lsqlite3 >= 0.9.5",
}

test_dependencies = {
  "luacov >= 0.15.0",
  "luacheck >= 1.1.0-1",
}

build = {
  type = "make",
  install_target = "luarocks-lib-install",
  install_variables  =  {
    INST_LUADIR = "$(LUADIR)",
  },
}

test = {
  type = "command",
  command = "sh test/run.sh"
}
