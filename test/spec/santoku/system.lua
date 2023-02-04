local sys = require("santoku.system")

describe("system", function ()

  describe("sh", function ()

    it("should provide an iterate for a forked process", function ()

      local ok, iter = sys.sh("printf 'a\\nb\\nc\\n'")
      assert(ok)
      local vals = iter:vec()
      assert.equals(vals[1], "a")
      assert.equals(vals[2], "b")
      assert.equals(vals[3], "c")

    end)

    it("should provide an iterate for a forked process", function ()

      local ok, iter = sys.sh("printf 'a\\nb\\nc\\n'")
      assert(ok)
      assert.equals(iter:last(), "c")

    end)

  end)

end)
