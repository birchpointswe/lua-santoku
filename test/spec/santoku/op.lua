local test = require("santoku.test")
local op = require("santoku.op")

test("call", function ()
  assert(5, op.add(3, 2))
  assert(5, op.call(math.min, 5, 10))
end)
