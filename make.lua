local env = {

  name = "santoku",
  version = "0.0.245-1",
  variable_prefix = "TK",
  license = "MIT",
  public = true,

  dependencies = {
    "lua >= 5.1",
  },

  test = {
    dependencies = {
      "luacov >= 0.15.0-1"
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
