local test = require("santoku.test")
local tbl = require("santoku.table")
local op = require("santoku.op")
local fun = require("santoku.functional")

test("assign", function ()

  test("should merge hash-like tables", function ()

    local expected = { a = 1, b = { 2, 3 } }
    local one = { a = 1 }
    local two = { b = { 2, 3 } }

    local c = {}
    tbl.assign(c, one)
    tbl.assign(c, two)

    assert(tbl.equals(expected, c))

  end)

  test("should allow non-overwrites", function ()

    local expected = { a = 1, b = { 2, 3 } }
    local one = { a = 1 }
    local two = { a = 2, b = { 2, 3 } }

    local c = {}
    tbl.assign(c, one, false)
    tbl.assign(c, two, false)

    assert(tbl.equals(expected, c))

  end)

end)

test("get", function ()

  test("should get deep vals in objects", function ()
    local obj = { a = { b = { 1, 2, { 3, 4 } } } }
    assert(tbl.equals({ 4 }, { tbl.get(obj, "a", "b", 3, 2) }))
    assert(tbl.equals({}, { tbl.get(obj, "a", "x", 3, 2) }))
  end)

  test("should get function as identity with no keys", function ()
    local obj = { a = { b = { 1, 2, { 3, 4 } } } }
    assert(tbl.equals(obj, tbl.get(obj)))
  end)

end)

test("set", function ()

  test("should set deep vals in objects", function ()
    local obj = { a = { b = { 1, 2, { 3, 4 } } } }
    tbl.set(obj, "a", "b", 3, 2, "x")
    assert(tbl.equals({ "x" }, { obj.a.b[3][2] }))
    assert(tbl.equals({ "x" }, { tbl.get(obj, "a", "b", 3, 2) }))
  end)

  test("should handle nil endpoints", function ()
    local obj = { a = { b = { c = { d = 1 } } } }
    tbl.set(obj, "a", "b", 3, 2, "x")
    assert(tbl.equals({ "x" }, { obj.a.b[3][2] }))
    assert(tbl.equals({ "x" }, { tbl.get(obj, "a", "b", 3, 2) }))
  end)

end)

test("merge", function ()

  test("should merge tables recursively", function ()

    local t1 = { a = 1, b = { c = 2 } }
    local t2 = { a = 2, b = { d = 4 } }
    local t3 = { e = { 1, 2, 3 } }
    local t4 = { e = { 4, 5, 6, 7, 8, 9 } }

    assert(tbl.equals(tbl.merge({}, t1, t2, t3, t4), {
      a = 2,
      b = { c = 2, d = 4 },
      e = { 4, 5, 6, 7, 8, 9 }
    }))

  end)

  test("should use prefer values from later files", function ()

    local expected = { a = 2 }
    local one = { a = 1 }
    local two = { a = 2 }

    assert(tbl.equals(expected, tbl.merge({ a = 0 }, one, two)))

  end)

end)

test("equals", function ()
  assert(tbl.equals({ a = 1, b = 2 }, { b = 2, a = 1 }))
  assert(not tbl.equals({ a = 2, b = 2 }, { b = 2, a = 1 }))
  assert(not tbl.equals({ a = 2, b = 2, 1, 2, 3 }, { b = 2, a = 1 }))
  assert(not tbl.equals({ a = { b = 1 } }, { a = { b = 2 } }))
  assert(not tbl.equals({ a = 1 }, { a = 1, b = 2 }))
end)

test("update", function ()
  assert(tbl.equals({ a = 2 }, tbl.update({ a = 1 }, "a", fun.bind(op.add, 1))))
end)

test("clear", function ()
  local t = { 1, 2, a = 1, b = 2 }
  assert(tbl.equals({}, tbl.clear(t)))
end)
