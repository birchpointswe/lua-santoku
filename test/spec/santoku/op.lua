local test = require("santoku.test")
local op = require("santoku.op")
local assert = require("luassert")

test("op", function ()

  test("call", function ()
    assert.equals(5, op.add(3, 2))
    assert.equals(5, op.call(math.min, 5, 10))
  end)

end)
