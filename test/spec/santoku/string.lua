local str = require("santoku.str")

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
