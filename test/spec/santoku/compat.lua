local compat = require("santoku.compat")

describe("compat", function ()

  describe("id", function ()

    it("should return the argments", function ()
      local a, b, c, d = compat.id(1, 2, 3)
      assert.equals(1, a)
      assert.equals(2, b)
      assert.equals(3, c)
      assert.equals(nil, d)
    end)

  end)

  describe("const", function ()

    it("should a function that returns the arguments", function ()
      local fn = compat.const(1, 2, 3)
      for i = 1, 10 do
        local a, b, c = fn()
        assert.equals(1, a)
        assert.equals(2, b)
        assert.equals(3, c)
      end
    end)

  end)

end)
