local test = require("santoku.test")
local serialize = require("santoku.serialize")

local tbl = require("santoku.table")
local teq = tbl.equals

test("serialize", function ()

  local t0 = {
    a = {
      b = 1,
      c = 2,
      d = { 1, "two", 3, "four", { five = 10 } }
    }
  }

  local t1f = loadstring("return " .. serialize(t0)) -- luacheck: ignore

  assert(teq(t0, assert(t1f)())) --

end)
