local tup = require("santoku.tuple")

describe("tuple", function ()

  it("stores varargs", function ()

    local tup, m = tup(1, 2, 3)
    assert(m == 3)

    tup(function (a, b, c)
      assert.equals(1, a)
      assert.equals(2, b)
      assert.equals(3, c)
    end)

  end)

  it("allows append", function ()

    local tup, m = tup(1)
    assert(m == 1)

    tup(function (a, b, c)
      assert.equals(1, a)
      assert.equals(2, b)
      assert.equals(3, c)
    end, 2, 3)

  end)

end)
