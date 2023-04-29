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

dependencies = {
  "santoku == <% return os.getenv('VERSION') %>",
  "argparse >= 0.7.1-1"
}

build = {
  type = "make",
  install_target = "luarocks-cli-install",
  install_variables = {
    INST_BINDIR = "$(BINDIR)",
  },
}
