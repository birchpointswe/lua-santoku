local assert = require("luassert")
local test = require("santoku.test")
local sys = require("santoku.system")
local str = require("santoku.string")

local bundle = require("santoku.bundle")
local fs = require("santoku.fs")
local err = require("santoku.err")

test("bundle", function ()

  test("bundle", function ()

    test("should produce a standalone executable from a lua file", function ()
      local infile = "res/bundle/test.lua"
      local outdir = "res/bundle/test"
      assert(err.pwrap(function (check)
        check(fs.mkdirp(outdir))
        fs.files(outdir):map(check):map(fs.rm):each(check)
        local incdir = check(sys.sh("luarocks", "config", "variables.LUA_INCDIR")):map(check):concat()
        local libdir = check(sys.sh("luarocks", "config", "variables.LUA_LIBDIR")):map(check):concat()
        local libfile = check(sys.sh("luarocks", "config", "variables.LUA_LIBDIR_FILE")):map(check):concat()
        local libname = str.stripprefix(fs.stripextension(libfile), "lib")
        check(bundle(infile, outdir, {
          -- luac = "luajit -b %input %output",
          flags = { "-I", incdir, "-L", libdir , "-l", libname, "-l", "m" }
        }))
        assert(check(fs.exists(fs.join(outdir, "test.lua"))))
        -- assert(check(fs.exists(fs.join(outdir, "test.luac"))))
        assert(check(fs.exists(fs.join(outdir, "test.h"))))
        assert(check(fs.exists(fs.join(outdir, "test.c"))))
        assert(check(fs.exists(fs.join(outdir, "test"))))
      end))
    end)

  end)

end)
