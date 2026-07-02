local test = require("santoku.test")
local tracer = require("santoku.tracer")

test("tracer arms a hook and returns a stop fn", function ()
  local stop = tracer()
  assert(type(stop) == "function")
  local function work (n) return n + 1 end
  assert(work(1) == 2)
  stop()
end)
