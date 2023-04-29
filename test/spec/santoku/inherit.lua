local inherit = require("santoku.inherit")

describe("inherit", function ()

  describe("pushindex", function ()

    it("should add an index to a table", function ()

      local t = {}
      local i = { a = 1 }
      inherit.pushindex(t, i)
      assert(inherit.getindex(t) == i)
      assert(inherit.getindex(i) == nil)

    end)

    it("should preserve existing indexes", function ()

      local t = {}
      local i1 = { a = 1 }
      local i2 = { a = 2 }
      local i 

      inherit.pushindex(t, i1)

      i = inherit.getindex(t)
      assert(i == i1)
      i = inherit.getindex(i1)
      assert(i == nil)

      inherit.pushindex(t, i2)

      i = inherit.getindex(t)
      assert(i == i2)

      i = inherit.getindex(i2)
      assert(i == i1)

      i = inherit.getindex(i1)
      assert(i == nil)

      i = inherit.popindex(t)
      assert(i == i2)

      i = inherit.getindex(i2)
      assert(i == i1)

      i = inherit.getindex(t)
      assert(i == i1)

      i = inherit.popindex(t)
      assert(i == i1)

    end)

  end)

  describe("popindex", function ()

    it("should pop a single index", function ()

      local t = {}
      local i = { a = 1 }
      local i0

      inherit.pushindex(t, i)

      i0 = inherit.getindex(t)
      assert(i == i0)

      i0 = inherit.popindex(t)
      assert(i == i0)

      i0 = inherit.getindex(t)
      assert(i0 == nil)

    end)

  end)

end)
