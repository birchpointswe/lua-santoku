local assert = require("luassert")
local test = require("santoku.test")

local str = require("santoku.string")

test("string", function ()

  test("match", function ()

    test("should return string matches", function ()

      local matches = str.match("this is a test", "%S+")

      assert.equals("this", matches[1])
      assert.equals("is", matches[2])
      assert.equals("a", matches[3])
      assert.equals("test", matches[4])
      assert.equals(4, matches.n)

    end)

  end)

  -- TODO: Test the printf format case (e.g. %d:val)
  test("interp", function ()

    test("should interpolate values", function ()

      local tmpl = "Hello %who, %adj to meet you!"
      local vals = { who = "World", adj = "nice" }
      local expected = "Hello World, nice to meet you!"
      local res = str.interp(tmpl, vals)
      assert.equals(expected, res)

    end)

  end)

  test("quote", function ()
    local s = "hello"
    assert.equals("\"hello\"", str.quote(s))
  end)

  test("uquote", function ()
    local s = "\"hello\""
    assert.equals("hello", str.unquote(s))
  end)

end)
