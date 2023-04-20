local bundle = require("santoku.bundle")
local fs = require("santoku.fs")
local err = require("santoku.err")

describe("santoku.bundle", function ()

  describe("bundle", function ()

    it("should produce a standalone executable from a lua file", function ()
      local infile = "test/lib/spec/santoku/bundle/test.lua"
      local outdir = "test/lib/spec/santoku/bundle/test"
      assert(err.pwrap(function (check) 
        check(fs.mkdirp(outdir))
        fs.files(outdir):map(check):map(os.remove):each(check)
        check(bundle(infile, outdir))
        assert(check(fs.exists(fs.join(outdir, "test.lua"))))
        assert(check(fs.exists(fs.join(outdir, "test.luac"))))
        assert(check(fs.exists(fs.join(outdir, "test.h"))))
        assert(check(fs.exists(fs.join(outdir, "test.c"))))
        assert(check(fs.exists(fs.join(outdir, "test"))))
      end))
    end)

  end)

end)
