local str = require("santoku.string")

describe("string", function ()

  describe("match", function ()

    it("should return string matches", function ()

      local gen = str.match("this is a test", "%S+")

      assert.equals("this", gen())
      assert.equals("is", gen())
      assert.equals("a", gen())
      assert.equals("test", gen())
      assert.equals(true, gen:done())

    end)

  end)

  -- TODO: Test the printf format case (e.g. %d:val)
  describe("interp", function ()

    it("should interpolate values", function ()

      local tmpl = "Hello %who, %adj to meet you!"
      local vals = { who = "World", adj = "nice" }
      local expected = "Hello World, nice to meet you!"
      local res = str.interp(tmpl, vals)
      assert.equals(expected, res)

    end)

  end)

end)
