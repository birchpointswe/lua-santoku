local test = require("santoku.test")
local compat = require("santoku.compat")

test("compat", function ()

  test("id", function ()

    test("should return the argments", function ()
      local a, b, c, d = compat.id(1, 2, 3)
      assert(1 == a)
      assert(2 == b)
      assert(3 == c)
      assert(nil == d)
    end)

  end)

  test("const", function ()

    test("should a function that returns the arguments", function ()
      local fn = compat.const(1, 2, 3)
      for i = 1, 10 do
        local a, b, c = fn()
        assert(1 == a)
        assert(2 == b)
        assert(3 == c)
      end
    end)

  end)

end)
