local fs = require("santoku.fs")
local utils = require("santoku.utils")

describe("santoku.fs", function ()

  describe("lines", function ()

    it("should return the correct number of lines", function ()

      local fp = "./test/spec/santoku/fs.tst1.txt"
      local ok, gen = fs.lines(fp)
      assert(ok)

      assert.equals("line 1", gen())
      assert.equals("line 2", gen())
      assert.equals("line 3", gen())
      assert.equals("line 4", gen())
      assert.equals(true, gen:done())
      assert.is_nil(gen())

    end)

  end)

  describe("joinwith", function ()

    it("should handle nils", function ()

      local delim = "/"
      local parts = utils.tuple(nil, "a", nil, "b")
      local result = fs.joinwith(delim, parts())

      assert.equals("a/b", result)

    end)


  end)

end)
