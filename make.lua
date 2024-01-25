local err = require("santoku.err")
local sys = require("santoku.system")

local env = {

  name = "santoku",
  version = "0.0.161-1",
  variable_prefix = "TK",
  license = "MIT",
  public = true,

  dependencies = {
    "lua >= 5.1",
  },

  test = {
    hooks = {
      post_make = function (e)
        err.check(sys.execute({
          env = { LUAROCKS_CONFIG = e.luarocks_config }
        }, "luarocks", "install", "santoku-test", "0.0.7-1"))
        return true
      end
    },
    dependencies = {
      "luacov >= scm-1",
      "luassert >= 1.9.0-1",
    }
  },

}

env.homepage = "https://github.com/treadwelllane/lua-" .. env.name
env.tarball = env.name .. "-" .. env.version .. ".tar.gz"
env.download = env.homepage .. "/releases/download/" .. env.version .. "/" .. env.tarball

return {
  type = "lib",
  env = env,
}
