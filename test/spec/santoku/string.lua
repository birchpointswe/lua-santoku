local assert = require("luassert")
local test = require("santoku.test")

local str = require("santoku.string")
local tbl = require("santoku.table")

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

  test("interp", function ()

    test("should interpolate values", function ()

      local tmpl = "Hello %who, %adj to meet you!"
      local vals = { who = "World", adj = "nice" }
      local expected = "Hello World, nice to meet you!"
      local res = str.interp(tmpl, vals)
      assert.equals(expected, res)

    end)

    test("should replace missing keys with blanks", function ()

      local tmpl = "This should be %adj: '%something'"
      local vals = { adj = "blank" }
      local expected = "This should be blank: ''"
      local res = str.interp(tmpl, vals)
      assert.equals(expected, res)

    end)

    test("should work with integer indices on tables", function ()
      assert.equals("a c b", str.interp("%1 %3 %2", { "a", "b", "c" }))
    end)

    test("should support format strings", function ()
      assert.equals("1.0", str.interp("%.1f#(1)", { 1 }))
      assert.equals("1.0", str.interp("%.1f#(number)", { number = 1 }))
    end)

  end)

  test("parse", function ()

    test("should support mapping string.match strings into an object", function ()

      local s = "2023-10-26 09:10:26"
      local obj = str.parse(s, "(%d+)#(year)-(%d+)#(month)-(%d+)#(day) (%d+)#(hour):(%d+)#(minute):(%d+)#(second)")
      tbl.map(obj, tonumber)
      assert.same({ year = 2023, month = 10, day = 26, hour = 9, minute = 10, second = 26 }, obj)

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
