local test = require("santoku.test")
local num = require("santoku.num")
local ntrunc = num.trunc

test("trunc", function ()
  assert(1.18 == ntrunc(1.18901234098234, 2))
  assert(1.189 == ntrunc(1.18901234098234, 3))
  assert(1.1 == ntrunc(1.18901234098234, 1))
  assert(1 == ntrunc(1.18901234098234, 0))
end)
