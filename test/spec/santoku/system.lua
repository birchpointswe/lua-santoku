local sys = require("santoku.system")

describe("system", function ()

  describe("sh", function ()

    it("should provide an iterate for a forked process", function ()

      local ok, iter = sys.sh("printf 'a\\nb\\nc\\n'")
      assert(ok)

      assert(iter:step())
      assert.equals(iter.vals:get(1), "a")

      assert(iter:step())
      assert.equals(iter.vals:get(1), "b")

      assert(iter:step())
      assert.equals(iter.vals:get(1), "c")

      assert(not iter:step())
      assert(iter.done)

    end)

    it("should provide an iterate for a forked process", function ()

      local ok, iter = sys.sh("printf 'a\\nb\\nc\\n'")
      assert(ok)
      assert.equals(iter:last(), "c")

    end)

  end)

end)
