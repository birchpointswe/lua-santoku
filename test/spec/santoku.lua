local toku = require("santoku")

describe("santoku", function ()

  describe("unimplemented", function ()

    it("should error", function ()
      assert.error(toku.unimplemented)
    end)

    pending()

  end)

end)
