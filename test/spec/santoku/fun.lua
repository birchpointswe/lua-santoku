local assert = require("luassert")
local test = require("santoku.test")

local fun = require("santoku.fun")
local compat = require("santoku.compat")
local op = require("santoku.op")

test("fun", function ()

  test("sel", function ()

    test("should drop args given to a function", function ()

      local f = function (a, b, c)
        assert.equals(2, a)
        assert.equals(3, b)
        assert.is_nil(c)
      end

      fun.sel(2, f)(1, 2, 3)

    end)

  end)

  test("narg", function ()

    test("should rearrange args", function ()

      local fn = function (a, b, c)
        assert.equals("c", a)
        assert.equals("b", b)
        assert.equals("a", c)
      end

      fun.narg(3, 2, 1)(fn)("a", "b", "c")

    end)

    test("should curry the first argument", function ()
      local add10 = fun.narg()(op.add, 10)
      assert.equals(20, add10(10))
    end)

    test("should curry the second argument", function ()
      local div10 = fun.narg()(op.div, 10)
      assert.equals(10, div10(100))
    end)

    test("should curry multiple arguments", function ()
      local fn0 = function (a, b, c) return a, b, c end
      local fn = fun.narg(3)(fn0, "c", "a")
      local a, b, c = fn("b")
      assert.equals("a", a)
      assert.equals("b", b)
      assert.equals("c", c)
    end)

    test("should specify argument order", function ()
      local fn0 = function (a, b, c) return a, b, c end
      local fn = fun.narg()(fn0, "b", "c")
      local a, b, c = fn("a")
      assert.equals("a", a)
      assert.equals("b", b)
      assert.equals("c", c)
    end)

  end)

  test("nret", function ()

    test("should rearrange returns", function ()

      local fn = function ()
        return "a", "b", "c"
      end

      local a, b, c = fun.nret(3, 2, 1)(fn())

      assert.equals("c", a)
      assert.equals("b", b)
      assert.equals("a", c)

    end)

    test("should handle nils", function ()

      local fn = function ()
        return nil, "a", nil, nil, "b"
      end

      local a, b, c, d, e = fun.nret(5, 4, 3, 2, 1)(fn())

      assert.equals("b", a)
      assert.is_nil(b)
      assert.is_nil(c)
      assert.equals("a", d)
      assert.is_nil(e)

    end)

    test("should work with one return argument", function ()

      local fn = function ()
        return "a", "b"
      end

      local a, b = fun.nret(2)(fn())

      assert.equals("b", a)
      assert.is_nil(b)

    end)

  end)

  test("compose", function ()

    test("should compose functions", function ()
      local fna = function (a, b) return a * 2, b + 2 end
      local fnb = function (a, b) return a + 2, b + 3 end
      local fnc = function (a, b) return a * 2, b + 4 end
      local a, b = fun.compose(fna, fnb, fnc)(2, 2)
      assert.equals(12, a)
      assert.equals(11, b)
    end)

    test("should call from right to left", function ()
      local fna = function (a, b) return a * 2 end
      local fnb = function (a, b) return a + 2 end
      local a = fun.compose(fna, fnb)(3)
      assert.equals(10, a)
    end)

  end)

  -- TODO: Maybe has changed - it now
  -- conditionally applies a function to the
  -- 2-Nth argument based on the t/f of the 1st
  -- arg, like a maybe monad
  -- test("maybe", function ()
  --   test("should apply a function if the value is truthy", function ()
  --     local add1 = function (a) return a + 1 end
  --     assert.equals(4, fun.maybe(3, add1))
  --     assert.equals(1, fun.maybe(0, add1))
  --     assert.is_nil(fun.maybe(nil, add1))
  --     assert.equals(false, fun.maybe(false, add1))
  --     assert.equals("b", fun.maybe(false, add1, compat.const("b")))
  --   end)
  -- end)

  test("choose", function ()

    test("should provide a functional if statement", function ()

      assert.equals(1, fun.choose(true, 1, 2))
      assert.equals(2, fun.choose(false, 1, 2))

    end)

    test("should handle nils", function ()

      assert.equals(nil, fun.choose(true, nil, 2))
      assert.is_nil(fun.choose(false, 1, nil))

    end)

  end)

end)
