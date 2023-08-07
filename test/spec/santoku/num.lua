local assert = require("luassert")
local test = require("santoku.test")

local num = require("santoku.num")

test("num", function ()

  test("trunc", function ()
    assert.equals(1.18, num.trunc(1.18901234098234, 2))
    assert.equals(1.189, num.trunc(1.18901234098234, 3))
    assert.equals(1.1, num.trunc(1.18901234098234, 1))
    assert.equals(1, num.trunc(1.18901234098234, 0))
  end)

end)
