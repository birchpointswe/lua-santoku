local env = require("santoku.env")
local err = require("santoku.err")
local fs = require("santoku.fs")
local fun = require("santoku.fun")
local gen = require("santoku.gen")
local inherit = require("santoku.inherit")
local runner = require("santoku.test.runner")
local str = require("santoku.string")
local sys = require("santoku.system")
local tbl = require("santoku.table")
local tpl = require("santoku.template")
local tup = require("santoku.tuple")
local vec = require("santoku.vector")

local make = require("santoku.make")()

local build_dir = "build"

err.check(err.pwrap(function (check)

  local config = "config.lua"
  local cfg = check(fs.loadfile(config))()

  local function get_build_files (dir, build_subdir)
    local files = vec()
    if check(fs.exists(dir)) then
      files:extend(fs.files(dir, { recurse = true })
        :map(check)
        :map(fun.nret(1))
        :vec())
    end
    return files:map(function (fp)
      local build = build_dir
      if build_subdir then
        build = fs.join(build, build_subdir)
      end
      return { src = fp, build = fs.join(build, fp) }
    end)
  end

  -- TODO: use fs.copy
  local function add_copied_target (dest, src)
    make:target(
      vec(dest),
      vec(src),
      function ()
        check(fs.mkdirp(fs.dirname(dest)))
        check(fs.writefile(dest, check(fs.readfile(src))))
        return true
      end)
  end

  local function add_templated_target (dest, src)
    make:target(
      vec(dest),
      vec(src, config),
      function (ts, ds)
        check(fs.mkdirp(fs.dirname(ts[1])))
        check(fs.writefile(ts[1], check(tpl.renderfile(ds[1], cfg))))
        return true
      end)
  end

  local function get_lua_version ()
    return (_VERSION:match("(%d+.%d+)"))
  end

  local function get_lua_path (prefix)
    return gen.pack(
        "share/lua/%ver/?.lua",
        "share/lua/%ver/?/init.lua",
        "lib/lua/%ver/?.lua",
        "lib/lua/%ver/?/init.lua")
      :map(fun.bindr(str.interp, { ver = get_lua_version() }))
      -- TODO: This line results in the ?/init.lua paths getting garbled. Why?
      -- :map(fun.bindl(fs.join, check(fs.cwd()), "lua_modules"))
      :map(function (d)
        local pfx = prefix and fs.join(prefix, "lua_modules") or "lua_modules"
        return fs.join(check(fs.cwd()), pfx, d)
      end)
      :concat(";")
  end

  local function get_lua_cpath (prefix)
    return gen.pack(
        "lib/lua/%ver/?.so",
        "lib/lua/%ver/loadall.so")
      :map(fun.bindr(str.interp, { ver = get_lua_version() }))
      -- TODO: See above
      -- :map(fun.bindl(fs.join, check(fs.cwd()), "lua_modules"))
      :map(function (d)
        local pfx = prefix and fs.join(prefix, "lua_modules") or "lua_modules"
        return fs.join(check(fs.cwd()), pfx, d)
      end)
      :concat(";")
  end

  local bins = get_build_files("bin")
  local libs = get_build_files("lib")
  local deps = get_build_files("deps")
  local test_bins = get_build_files("bin", "test")
  local test_libs = get_build_files("lib", "test")
  local test_deps = get_build_files("deps", "test"):extend(get_build_files("test/deps"))
  local test_specs = get_build_files("test/spec")
  local test_res = get_build_files("test/res")

  local build_test_bins = gen.ivals(test_bins):map(fun.bindr(tbl.get, "build")):vec()
  local build_test_libs = gen.ivals(test_libs):map(fun.bindr(tbl.get, "build")):vec()
  local build_test_deps = gen.ivals(test_deps):map(fun.bindr(tbl.get, "build")):vec()
  local build_test_specs = gen.ivals(test_specs):map(fun.bindr(tbl.get, "build")):vec()
  local build_test_res = gen.ivals(test_res):map(fun.bindr(tbl.get, "build")):vec()
  local build_test_rockspec = fs.join(build_dir, str.interp("test/%s#(name)-%s#(version).rockspec", cfg.env))
  local build_test_modules = fs.join(build_dir, "test/lua_modules")
  local build_test_modules_ok = fs.join(build_dir, "test/lua_modules.ok")
  local build_test_run_sh = fs.join(build_dir, "test/run.sh")
  local build_test_luarocks_config = fs.join(build_dir, "test/luarocks.lua")
  local build_test_luacheck_config = fs.join(build_dir, "test/luacheck.lua")
  local build_test_luacov_config = fs.join(build_dir, "test/luacov.lua")
  local build_test_luacov_stats_file = fs.join(build_dir, "test/luacov.stats.out")
  local build_test_luacov_report_file = fs.join(build_dir, "test/luacov.report.out")
  local build_test_luarocks_mk = fs.join(build_dir, "test/Makefile")
  local build_test_lib_mk = fs.join(build_dir, "test/lib/Makefile")
  local build_test_bin_mk = fs.join(build_dir, "test/bin/Makefile")

  inherit.pushindex(cfg.env, _G)

  cfg.env.var = function (n)
    return cfg.env.variable_prefix .. "_" .. n
  end

  cfg.env.build = {
    dir = build_dir,
    bins = bins,
    libs = libs,
    deps = deps,
    istest = true,
    test_bins = test_bins,
    test_libs = test_libs,
    test_deps = test_deps,
    test_modules = check(fs.absolute(build_test_modules)),
    test_luacov_stats_file = check(fs.absolute(build_test_luacov_stats_file)),
    test_luacov_report_file = check(fs.absolute(build_test_luacov_report_file)),
    test_lua = env.interpreter()[1],
    test_lua_path = get_lua_path(fs.join(build_dir, "test")),
    test_lua_cpath = get_lua_cpath(fs.join(build_dir, "test")),
  }

  add_templated_target(build_test_luarocks_config, "make/luarocks.lua")
  add_templated_target(build_test_luacheck_config, "make/luacheck.lua")
  add_templated_target(build_test_luacov_config, "make/luacov.lua")
  add_templated_target(build_test_rockspec, "make/template.rockspec")
  add_templated_target(build_test_luarocks_mk, "make/luarocks.mk")
  add_templated_target(build_test_lib_mk, "make/lib.mk")
  add_templated_target(build_test_bin_mk, "make/bin.mk")
  add_templated_target(build_test_run_sh, "make/test-run.sh")

  gen.chain(tup.map(gen.ivals, test_bins, test_libs, test_deps, test_specs))
    :each(function (d)
      add_templated_target(d.build, d.src)
    end)

  gen.chain(tup.map(gen.ivals, test_res))
    :each(function (d)
      add_copied_target(d.build, d.src)
    end)

  local build_test_lua_modules_deps = vec(
    config, build_test_luarocks_mk, build_test_lib_mk,
    build_test_luarocks_config, build_test_rockspec)
    :extend(build_test_libs)
    :extend(build_test_bins)

  if bins.n > 0 then
    build_test_lua_modules_deps:append(build_test_bin_mk)
  end

  make:target(
    vec(build_test_modules_ok),
    build_test_lua_modules_deps,
    function ()
      local cwd = check(fs.cwd())
      -- TODO: simplify with fs.pushd + callback
      check(fs.cd(fs.join(build_dir, "test")))
      local ok, e, cd = sys.execute(
        { env = { LUAROCKS_CONFIG = fs.basename(build_test_luarocks_config) } },
        "luarocks", "make", fs.basename(build_test_rockspec))
      check(fs.cd(cwd))
      check(ok, e, cd)
      check(fs.touch(build_test_modules_ok))
      return true
    end)

  make:target(
    vec("test"),
    vec()
      :extend(build_test_bins)
      :extend(build_test_libs)
      :extend(build_test_deps)
      :extend(build_test_specs)
      :extend(build_test_res)
      :append(
        build_test_run_sh,
        build_test_modules_ok,
        build_test_luarocks_config,
        build_test_luacheck_config,
        build_test_luacov_config,
        build_test_rockspec),
    function ()
      local cwd = check(fs.cwd())
      -- TODO: simplify with fs.pushd + callback
      check(fs.cd(fs.join(build_dir, "test")))
      local ok, e, cd = sys.execute("sh", "run.sh")
      check(fs.cd(cwd))
      check(ok, e, cd)
      return true
    end)

  local watched_files = gen.pack("bin", "lib", "test", "make", "config.lua", "make.lua")
    :filter(function (d)
      return check(fs.exists(d))
    end):vec()

  make:target(vec("iterate"), vec(), function ()
    local ok = sys.execute("sh", "-c", "type inotifywait >/dev/null 2>/dev/null")
    if not ok then
      return false
    end
    while true do
      check(make:make({ "test" }))
      check(sys.execute("inotifywait", "-qqr", watched_files:unpack()))
    end
    return true
  end)

  check(make:make(arg))

end))
