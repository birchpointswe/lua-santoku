local test = require("santoku.test")
local bench = require("santoku.bench")

test("bench runs the fn and passes args through", function ()
  local got
  bench("noop", function (a, b)
    got = a + b
    return got
  end, 2, 3)
  assert(got == 5)
end)
