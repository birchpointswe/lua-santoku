local test = require("santoku.test")
local tbl = require("santoku.table")
local arr = require("santoku.array")
local fun = require("santoku.functional")
local op = require("santoku.op")

test("copy", function ()

  test("should copy into an array", function ()
    local dest = { 1, 2, 3, 4 }
    local source = { 3, 4, 5, 6 }
    arr.copy(dest, source, 3)
    assert(tbl.equals({ 1, 2, 3, 4, 5, 6 }, dest))
  end)

  test("should copy into an array", function ()
    local dest = {}
    local source = { 3, 4, 5, 6 }
    arr.copy(dest, source, 1)
    assert(tbl.equals({ 3, 4, 5, 6 }, dest))
  end)

  test("should work with the same array", function ()
    local v = { 1, 2, 3, 4, 5, 6 }
    arr.copy(v, v, 1, 2)
    assert(tbl.equals({ 2, 3, 4, 5, 6, 6 }, v))
  end)

  test("should work with the same array", function ()
    local v = { 1, 2, 3, 4, 5, 6 }
    arr.copy(v, v, 2, 1)
    assert(tbl.equals({ 1, 1, 2, 3, 4, 5, 6 }, v))
  end)

  test("should clear if moving", function ()
    local a = { 1, 2, 3, 4 }
    local b = { 3, 4, 5, 6, 7, 8 }
    arr.move(a, b, 3, 1, 4)
    assert(tbl.equals({ 1, 2, 3, 4, 5, 6 }, a))
    assert(tbl.equals({ 7, 8 }, b))
  end)

  test("simple copy within single table", function ()
    assert(tbl.equals({ 1, 3, 4, 4 }, arr.copy({ 1, 2, 3, 4 }, 2, 3)))
  end)

end)

test("extend", function ()

  test("should merge array-like tables", function ()

    local expected = { 1, 2, 3, 4 }
    local one = { 1, 2 }
    local two = { 3, 4 }

    assert(tbl.equals(expected, arr.extend({}, one, two)))

  end)

  test("should handle non-empty initial tables", function ()

    local expected = { "a", "b", 1, 2, 3, 4 }
    local one = { 1, 2 }
    local two = { 3, 4 }

    assert(tbl.equals(expected, arr.extend({ "a", "b" }, one, two)))

  end)

  test("should handle extending by empty tables", function ()

    local expected = { 1, 2 }
    local one = {}
    local two = {}

    assert(tbl.equals(expected, arr.extend({ 1, 2 }, one, two)))

  end)

end)

test("push", function ()
  local expected = { 1, 2, 3 }
  assert(tbl.equals(expected, arr.push({ 1 }, 2, 3)))
end)

test("slice", function ()

  test("should copy into an array", function ()
    local v = arr.slice({ 1, 2, 3, 4 }, 2)
    assert(tbl.equals({ 2, 3, 4 }, v))
  end)

end)

test("tabulate", function ()

  test("creates a table from an array", function ()
    local vals = { 1, 2, 3, 4 }
    local t = arr.tabulate(vals, "one", "two", "three", "four")
    assert(tbl.equals({ one = 1, two = 2, three = 3, four = 4 }, t))
  end)

  test("captures remaining values in a 'rest' property", function ()
    local vals = { 1, 2, 3, 4 }
    local t = arr.tabulate(vals, { rest = "others" }, "one")
    assert(tbl.equals({ one = 1, others = { 2, 3, 4 } }, t))
  end)

end)

test("remove", function ()

  test("removes elements from an array", function ()
    local vals = { 1, 2, 3, 4 }
    arr.remove(vals, 2, 3)
    assert(tbl.equals({ 1, 4 }, vals))
  end)

end)

test("filter", function ()

  test("filters an array", function ()
    assert(tbl.equals({ 2, 4, 6 },
      arr.filter({ 1, 2, 3, 4, 5, 6 }, function (n)
        return (n % 2) == 0
      end)))
  end)

  test("works for consecutive removals", function ()
    assert(tbl.equals({ 2, 4, 6 },
      arr.filter({ 1, 2, 3, 3, 3, 3, 3, 4, 5, 5, 6 }, function (n)
        return (n % 2) == 0
      end)))
  end)

end)

test("sort", function ()

  test("should sort an array", function ()
    local v = arr.sort({ 10, 5, 2, 38, 1, 4 })
    assert(tbl.equals({ 1, 2, 4, 5, 10, 38 }, v))
  end)

  test("should unique sort an array", function ()
    local v = arr.sort({ 10, 38, 10, 10, 38, 1, 4 }, { unique = true })
    assert(tbl.equals({ 1, 4, 10, 38 }, v))
  end)

  test("should unique sort an array", function ()
    local v = arr.sort({ { 2 }, { 5 }, { 1 } }, function (a, b)
      return a[1] < b[1]
    end)
    assert(tbl.equals({ { 1 }, { 2 }, { 5 } }, v))
  end)

end)

test("reverse", function ()
  assert(tbl.equals({ 4, 3, 2, 1 }, arr.reverse({ 1, 2, 3, 4 })))
  assert(tbl.equals({ 3, 2, 1 }, arr.reverse({ 1, 2, 3 })))
  assert(tbl.equals({ 2, 1 }, arr.reverse({ 1, 2 })))
  assert(tbl.equals({ 1 }, arr.reverse({ 1 })))
  assert(tbl.equals({}, arr.reverse({})))
end)

test("replicate", function ()
  assert(tbl.equals({ 1, 2, 1, 2 }, arr.replicate({ 1, 2 }, 2)))
end)

test("includes", function ()
  assert(tbl.equals({ true }, { arr.includes({ 1, 2, 3, 4 }, 3) }))
end)

test("insert", function ()
  assert(tbl.equals({ 1, 2, 3 }, arr.insert({ 1, 3 }, 2, 2)))
  assert(tbl.equals({ 2, 1, 3 }, arr.insert({ 1, 3 }, 1, 2)))
  assert(tbl.equals({ 1, 3, 2 }, arr.insert({ 1, 3 }, 3, 2)))
  assert(tbl.equals({ 1, 3, 2 }, arr.insert({ 1, 3 }, 2)))
end)

test("trunc", function ()
  assert(tbl.equals({ 1, 2, 3 }, arr.trunc({ 1, 2, 3, 4 }, 3)))
end)

test("map", function ()
  assert(tbl.equals({ 2, 3, 4 }, arr.map({ 1, 2, 3 }, fun.bind(op.add, 1))))
end)

test("reduce", function ()
  assert(tbl.equals({ 6 }, { arr.reduce({ 1, 2, 3 }, op.add) }))
  assert(tbl.equals({}, { arr.reduce({}, op.add) }))
end)

test("pop", function ()
  local t = { 1, 2, 3 }
  arr.pop(t)
  assert(tbl.equals({ 1, 2 }, t))
end)

test("shift", function ()
  local t = { 1, 2, 3 }
  arr.shift(t)
  assert(tbl.equals({ 2, 3 }, t))
end)

test("each", function ()
  local s = 0
  local t = { 1, 2, 3 }
  arr.each(t, function (v)
    s = s + v
  end)
  assert(s == 6)
end)

test("sum, mean, max, min", function ()
  assert(tbl.equals({ 10 }, { arr.sum({ 1, 2, 3, 4 }) }))
  assert(tbl.equals({ 7.5 }, { arr.mean({ 5, 10 }) }))
  assert(tbl.equals({ 10 }, { arr.max({ 1, 5, 10, 3 }) }))
  assert(tbl.equals({ 1 }, { arr.min({ 1, 5, 10, 3 }) }))
end)

test("concat", function ()
  assert(tbl.equals({ "abc" }, { arr.concat({ "a", "b", "c" }) }))
end)

test("spread", function ()
  assert(tbl.equals({ 1, 2, 3 }, { arr.spread({ 1, 2, 3 }) }))
end)
