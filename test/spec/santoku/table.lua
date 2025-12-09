local test = require("santoku.test")
local op = require("santoku.op")
local fun = require("santoku.functional")

local implementations = { { "table", require("santoku.table") } }

for _, impl in ipairs(implementations) do
  local name, tbl = impl[1], impl[2]

  test(name, function ()

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
        tbl.assign(c, one)
        tbl.assign(c, two)
        assert(tbl.equals(expected, c))
      end)

    end)

    test("get", function ()

      test("should get deep vals in objects", function ()
        local obj = { a = { b = { 1, 2, { 3, 4 } } } }
        assert(tbl.equals({ 4 }, { tbl.get(obj, { "a", "b", 3, 2 }) }))
        assert(tbl.equals({}, { tbl.get(obj, { "a", "x", 3, 2 }) }))
      end)

      test("should get function as identity with no keys", function ()
        local obj = { a = { b = { 1, 2, { 3, 4 } } } }
        assert(tbl.equals(obj, tbl.get(obj)))
        assert(tbl.equals(obj, tbl.get(obj, {})))
      end)

    end)

    test("set", function ()

      test("should set deep vals in objects", function ()
        local obj = { a = { b = { 1, 2, { 3, 4 } } } }
        tbl.set(obj, { "a", "b", 3, 2 }, "x")
        assert(tbl.equals({ "x" }, { obj.a.b[3][2] }))
        assert(tbl.equals({ "x" }, { tbl.get(obj, { "a", "b", 3, 2 }) }))
      end)

      test("should handle nil endpoints", function ()
        local obj = { a = { b = { c = { d = 1 } } } }
        tbl.set(obj, { "a", "b", 3, 2 }, "x")
        assert(tbl.equals({ "x" }, { obj.a.b[3][2] }))
        assert(tbl.equals({ "x" }, { tbl.get(obj, { "a", "b", 3, 2 }) }))
      end)

    end)

    test("merge", function ()

      test("should merge tables recursively", function ()
        local t1 = { a = 1, b = { c = 2 } }
        local t2 = { a = 2, b = { d = 4 } }
        local t3 = { e = { 1, 2, 3 } }
        local t4 = { e = { 4, 5, 6, 7, 8, 9 } }
        assert(tbl.equals(tbl.merge({}, t4, t3, t2, t1), {
          a = 2,
          b = { c = 2, d = 4 },
          e = { 4, 5, 6, 7, 8, 9 }
        }))
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
      assert(tbl.equals({ a = 2 }, tbl.update({ a = 1 }, { "a" }, fun.bind(op.add, 1))))
    end)

    test("clear", function ()
      local t = { 1, 2, a = 1, b = 2 }
      assert(tbl.equals({}, tbl.clear(t)))
    end)

    test("map", function ()
      local t = { a = 1, b = 2, c = 3 }
      tbl.map(t, function (v) return v * 2 end)
      assert(tbl.equals({ a = 2, b = 4, c = 6 }, t))
    end)

    test("keys", function ()
      local t = { a = 1, b = 2, c = 3 }
      local k = tbl.keys(t)
      table.sort(k)
      assert(tbl.equals({ "a", "b", "c" }, k))
    end)

    test("vals", function ()
      local t = { a = 1, b = 2, c = 3 }
      local v = tbl.vals(t)
      table.sort(v)
      assert(tbl.equals({ 1, 2, 3 }, v))
    end)

    test("entries", function ()
      local t = { a = 1, b = 2 }
      local e = tbl.entries(t)
      table.sort(e, function (x, y) return x[1] < y[1] end)
      assert(tbl.equals({ { "a", 1 }, { "b", 2 } }, e))
    end)

    test("each", function ()
      local t = { a = 1, b = 2, c = 3 }
      local sum = 0
      local keys = {}
      tbl.each(t, function (v, k)
        sum = sum + v
        keys[#keys + 1] = k
      end)
      assert(sum == 6)
      table.sort(keys)
      assert(tbl.equals({ "a", "b", "c" }, keys))
    end)

    test("from", function ()
      local arr = { { id = "x", val = 1 }, { id = "y", val = 2 } }
      local t = tbl.from(arr, function (v) return v.id end)
      assert(t["x"].val == 1)
      assert(t["y"].val == 2)
    end)

    test("invert", function ()
      local t = { a = 1, b = 2, c = 3 }
      local inv = tbl.invert(t)
      assert(inv[1] == "a")
      assert(inv[2] == "b")
      assert(inv[3] == "c")
    end)

  end)

end
