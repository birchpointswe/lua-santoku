local assert = require("luassert")
local test = require("santoku.test")

local sys = require("santoku.system")

test("system", function ()

  test("sh", function ()

    test("should provide an iterate for a forked process", function ()

      local ok, iter = sys.sh("printf 'a\\nb\\nc\\n'")
      assert(ok)
      local vals = iter:vec()
      assert.equals(vals[1], "a")
      assert.equals(vals[2], "b")
      assert.equals(vals[3], "c")

    end)

    test("should provide an iterate for a forked process", function ()

      local ok, iter = sys.sh("printf 'a\\nb\\nc\\n'")
      assert(ok)
      assert.equals(iter:last(), "c")

    end)

  end)

end)
