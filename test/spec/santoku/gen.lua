local gen = require("santoku.gen")
local utils = require("santoku.utils")

describe("santoku.gen", function ()

  describe("ivals", function ()

    it("should handle nils", function ()

      local array =  { nil, "a", nil, "b"  }
      local vals = gen.ivals(array)

      assert(vals() == "a")
      assert(vals() == "b")
      assert(vals() == nil)
      assert.error(vals)

    end)

  end)

end)
