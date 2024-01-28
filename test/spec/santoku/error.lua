local test = require("santoku.test")

local err = require("santoku.error")
local check = err.check
local exists = err.exists
local try = err.try

test("error(...)", function ()
  local ok, e = try(function ()
    check(false, "hi")
  end)
  assert(ok == false)
  assert(e == "hi")
end)

test("exists(...)", function ()
  local ok, e = try(function ()
    exists("hi")
    return "hi"
  end)
  assert(ok == true)
  assert(e == "hi")
end)
