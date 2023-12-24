local assert = require("luassert")
local test = require("santoku.test")

local tup = require("santoku.tuple")

test("tuple", function ()

  test("stores varargs", function ()

    local t = tup(1, 2, 3)
    assert(tup.len(t()) == 3)

    local a, b, c = t()
    assert.equals(1, a)
    assert.equals(2, b)
    assert.equals(3, c)

  end)

  test("allows append", function ()

    local t = tup(1)
    assert(tup.len(t()) == 1)

    local a, b, c = t(2, 3)
    assert.equals(1, a)
    assert.equals(2, b)
    assert.equals(3, c)

  end)

  test("allows map", function ()

    local a, b, c = tup.map(function (a) return a * 2 end, 1, 2, 3)
    assert.equals(2, a)
    assert.equals(4, b)
    assert.equals(6, c)

  end)

  test("interleave", function ()

    local a, b, c, d, e = tup.interleave(5, 1, 2, 3)
    assert.same({ 1, 5, 2, 5, 3 }, { a, b, c, d, e })

  end)

  test("get", function ()

    local t = tup(1, 2, 3, 4)
    assert.equals(2, tup.get(2, t()))

  end)

  test("sel positive", function ()

    local t = tup(1, 2, 3, 4, 5)
    assert.same({ 3, 4, 5 }, { tup.sel(3, t()) })

  end)

  test("sel negative", function ()

    local t = tup(1, 2, 3, 4, 5)
    assert.same({ 3, 4, 5 }, { tup.sel(-3, t()) })

  end)

  test("take", function ()

    local t = tup(1, 2, 3, 4, 5)
    assert.same({ 1, 2, 3 }, { tup.take(3, t()) })

  end)

  test("filter", function ()

    local t = tup(1, 2, 3, 4, 5, 6)
    assert.same({ 2, 4, 6 }, { tup.filter(function (x)
      return x % 2 == 0
    end, t()) })

  end)

  test("tabulate", function ()

    local keys = tup("a", "b", "c")
    local vals = tup(1, 2, 3)

    assert.same({ a = 1, b = 2, c = 3 }, tup.tabulate(keys, vals))

  end)

  test("set", function ()
    local a, b, c = tup.set(2, "x", "a", "b", "c")
    assert(a == "a")
    assert(b == "x")
    assert(c == "c")
  end)

  test("reduce empty", function ()
    local a = tup.reduce(function (a, n) return a + n end)
    assert(a == nil)
  end)

  test("concat", function ()
    local a = tup.concat("a", "b", "c")
    assert(a == "abc")
  end)

  test("each", function ()
    local n = 1
    tup.each(function (x)
      if n == 1 then
        assert(x == "a")
      elseif n == 2 then
        assert(x == "b")
      elseif n == 3 then
        assert(x == "c")
      else
        assert(false)
      end
      n = n + 1
    end, "a", "b", "c")
  end)

end)
