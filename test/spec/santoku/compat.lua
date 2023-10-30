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
      for _ = 1, 10 do
        local a, b, c = fn()
        assert(1 == a)
        assert(2 == b)
        assert(3 == c)
      end
    end)

  end)

  test("isarray", function ()

    test("should check if a table contains only numeric indices", function ()
      assert(compat.isarray({ 1, 2, 3, 4 }))
      assert(not compat.isarray({ 1, 2, 3, 4, ["5"] = 5 }))
    end)

    test("should ignore the n property if its value is numeric", function ()
      assert(compat.isarray({ 1, 2, 3, 4, n = 4 }))
      assert(not compat.isarray({ 1, 2, 3, 4, n = "hi" }))
    end)

  end)

  test("hasmeta", function ()

    test("__pairs on table literal", function ()
      assert(compat.hasmeta.pairs({}))
    end)

    test("__call on function literal", function ()
      assert(compat.hasmeta.call(function () end))
    end)

    test("__add on number literal", function ()
      assert(compat.hasmeta.add(1))
    end)

  end)

end)
