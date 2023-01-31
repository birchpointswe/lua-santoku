local sys = require("santoku.system")

describe("system", function ()

  describe("sh", function ()

    it("should provide an iterate for a forked process", function ()

      local ok, iter = sys.sh("printf 'a\\nb\\nc\\n'")
      assert(ok)
      local lines = iter:vec()
      assert(lines.n == 3)
      assert.equals(lines[1], "a")
      assert.equals(lines[2], "b")
      assert.equals(lines[3], "c")

    end)

  end)

end)
