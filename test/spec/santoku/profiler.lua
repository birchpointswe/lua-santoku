local test = require("santoku.test")
local profiler = require("santoku.profiler")

test("profiler arms a hook and returns a report fn", function ()
  local report = profiler()
  assert(type(report) == "function")
  local function work (n) return n * n end
  assert(work(3) == 9)
  report()
end)
