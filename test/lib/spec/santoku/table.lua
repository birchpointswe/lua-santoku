-- TODO: Benchmark against similar libraries

local tbl = require("santoku.table")
local fun = require("santoku.fun")
local op = require("santoku.op")

describe("table", function ()

  describe("assign", function ()

    it("should merge hash-like tables", function ()

      local expected = { a = 1, b = { 2, 3 } }
      local one = { a = 1 }
      local two = { b = { 2, 3 } }

      assert.same(expected, tbl():assign(one, two))

    end)

  end)

  describe("get", function ()

    it("should get deep vals in objects", function ()
      local obj = tbl({ a = { b = { 1, 2, { 3, 4 } } } })
      assert.equals(4, obj:get("a", "b", 3, 2))
      assert.is_nil(obj:get("a", "x", 3, 2))
    end)

    it("should get function as identity with no keys", function ()
      local obj = tbl({ a = { b = { 1, 2, { 3, 4 } } } })
      assert.same(obj, obj:get())
    end)

  end)

  describe("set", function ()

    it("should set deep vals in objects", function ()
      local obj = tbl({ a = { b = { 1, 2, { 3, 4 } } } })
      obj:set("x", "a", "b", 3, 2)
      assert.equals("x", obj.a.b[3][2])
      assert.equals("x", obj:get("a", "b", 3, 2))
    end)

  end)

  describe("mergeWith", function ()

    it("should merge tables with key-based merged functions", function ()

      local t0 = { a = 1, b = { c = "one" } }
      local t1 = { a = 2, b = { c = "two" } }

      tbl(t0):mergeWith({
        a = op.add,
        b = { c = function (a, b) return a .. ", " .. b end }
      }, t1)

      assert.same(t0, { a = 3, b = { c = "one, two" } })

    end)

  end)

  describe("merge", function ()

    it("should merge tables recursively", function ()

      local t1 = { a = 1, b = { c = 2 } }
      local t2 = { a = 2, b = { d = 4 } }
      local t3 = { e = { 1, 2, 3 } }
      local t4 = { e = { 4, 5, 6, 7, 8, 9 } }

      assert.same(tbl.merge({}, t1, t2, t3, t4), {
        a = 1, 
        b = { c = 2, d = 4 },
        e = { 1, 2, 3, 7, 8, 9 }
      })

    end)

  end)

end)
