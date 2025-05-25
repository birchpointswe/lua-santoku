local env = {

  name = "santoku",
  version = "0.0.265-1",
  variable_prefix = "TK",
  license = "MIT",
  public = true,

  cflags = {
    "-march=native", "-O3", "-Wall", "-Wextra",
    "-Wsign-compare", "-Wsign-conversion", "-Wstrict-overflow",
    "-Wpointer-sign"
  },

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
