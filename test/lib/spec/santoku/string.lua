local str = require("santoku.string")

describe("string", function ()

  describe("match", function ()

    it("should return string matches", function ()

      local matches = str.match("this is a test", "%S+")

      assert.equals("this", matches[1])
      assert.equals("is", matches[2])
      assert.equals("a", matches[3])
      assert.equals("test", matches[4])
      assert.equals(4, matches.n)

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
