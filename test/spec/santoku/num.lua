local test = require("santoku.test")
local num = require("santoku.num")

test("trunc", function ()
  assert(1.18 == num.trunc(1.18901234098234, 2))
  assert(1.189 == num.trunc(1.18901234098234, 3))
  assert(1.1 == num.trunc(1.18901234098234, 1))
  assert(1 == num.trunc(1.18901234098234, 0))
end)

-- test("round", function ()
--   print(num.round(1231.1231))
-- end)
