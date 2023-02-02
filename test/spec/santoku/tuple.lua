local tup = require("santoku.tuple")

describe("tuple", function ()

  it("stores varargs", function ()

    local val, a, b

    val = tup(1, 2)

    a, b = val()
    assert.equals(1, a)
    assert.equals(2, b)

    val = tup(3, 4)

    a, b = val()
    assert.equals(3, a)
    assert.equals(4, b)

    a, b = val()
    assert.equals(3, a)
    assert.equals(4, b)

  end)

end)
