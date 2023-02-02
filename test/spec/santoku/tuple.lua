local tup = require("santoku.tuple")

describe("tuple", function ()

  it("stores varargs", function ()

    local tup = tup()

    local a, b

    a, b = tup.set(1, 2)
    assert.equals(nil, a)
    assert.equals(nil, b)

    a, b = tup.get()
    assert.equals(1, a)
    assert.equals(2, b)

    a, b = tup.get()
    assert.equals(1, a)
    assert.equals(2, b)

    a, b = tup.set(3, 4)
    assert.equals(1, a)
    assert.equals(2, b)
     
    a, b = tup.get()
    assert.equals(3, a)
    assert.equals(4, b)

    a, b = tup.get()
    assert.equals(3, a)
    assert.equals(4, b)

    a, b = tup.set(3, 4)
    assert.equals(3, a)
    assert.equals(4, b)

    a, b = tup.get()
    assert.equals(3, a)
    assert.equals(4, b)

  end)

end)
