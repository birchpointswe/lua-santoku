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

  describe("extend", function ()

    it("should merge array-like tables", function ()

      local expected = { 1, 2, 3, 4 }
      local one = { 1, 2 }
      local two = { 3, 4 }

      assert.same(expected, tbl():extend(one, two))

    end)

    it("should handle non-empty initial tables", function ()

      local expected = { "a", "b", 1, 2, 3, 4 }
      local one = { 1, 2 }
      local two = { 3, 4 }

      assert.same(expected, tbl({ "a", "b" }):extend(one, two))

    end)

    it("should drop trailing nils ", function ()

      local expected = { 1, 2, 3, 4 }
      local one = { 1, 2, nil, nil }
      local two = { 3, 4, nil }

      assert.same(expected, tbl():extend(one, two))

    end)

    it("should keep middle nils", function ()

      local expected = { 1, nil, 2, nil, 3, 4 }
      local one = { 1, nil, 2, nil }
      local two = { nil, 3, 4 }

      assert.same(expected, tbl():extend(one, two))

    end)

  end)

  describe("append", function ()

    it("should append args to array", function ()

      local expected = { 1, 2, 3 }
      assert.same(expected, tbl({ 1 }):append(2, 3))

    end)

    it("should handle nils", function ()

      local args = tbl.wrapn()

      assert.equals(0, args:len())

      args:append(nil)

      assert.equals(1, args:len())

    end)

  end)

  describe("bubble", function ()

    it("should bubble indices to the front", function ()
      local args = tbl({ 1, 2, 3, 4, 5 })
      args:bubble(3, 2, 1)
      assert.same({ 3, 2, 1, 4, 5 }, args:unwrap())
    end)

  end)

  describe("lens", function ()

    it("should provide a lens into an object", function ()
      local obj = { a = { b = { 1, 2, { 3, 4 } } } }
      local lens2 = tbl.lens({ "a", "b", 2 }, {
        fn = function (x)
          return x + 2
        end
      })
      local t, v = lens2(obj)
      assert.equals(obj, t)
      assert.equals(4, v)
    end)

    it("should provide a lens into an object", function ()
      local obj = { a = { b = { 1, 2, { 3, 4 } } } }
      local lens34 = tbl.lens({ "a", "b", 3 })
      local t, v = lens34(obj)
      assert.equals(obj, t)
      assert.same(obj.a.b[3], v)
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
      local t, v = obj:set("x", "a", "b", 3, 2)
      assert.equals(obj, t)
      assert.equals("x", v)
      assert.equals(obj.a.b[3][2], "x")
    end)

  end)

end)
