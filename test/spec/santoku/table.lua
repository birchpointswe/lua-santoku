-- TODO: Benchmark against similar libraries

local tbl = require("santoku.table")
local fun = require("santoku.fun")

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

end)
