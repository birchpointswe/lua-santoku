local sys = require("santoku.system")

describe("system", function ()

  describe("sh", function ()

    it("should provide an iterate for a forked process", function ()

      local ok, iter = sys.sh("printf 'a\\nb\\nc\\n'")
      assert(ok)
      assert.equals(iter(), "a")
      assert.equals(iter(), "b")
      assert.equals(iter(), "c")
      assert(iter:done())

    end)

    it("should provide an iterate for a forked process", function ()

      local ok, iter = sys.sh("printf 'a\\nb\\nc\\n'")
      assert(ok)
      assert.equals(iter:last(), "c")

    end)

  end)

end)
