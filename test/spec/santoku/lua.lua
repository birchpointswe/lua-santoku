local test = require("santoku.test")
local lua = require("santoku.lua")

test("loadstring evaluates code", function ()
  local fn = lua.loadstring("return 1 + 2")
  assert(fn() == 3)
end)

test("loadstring honors a supplied environment", function ()
  local fn = lua.loadstring("return x", { x = 42 })
  assert(fn() == 42)
end)

test("getupvalue finds upvalues by name", function ()
  local secret = 7
  local fn = function () return secret end
  local n, val = lua.getupvalue(fn, "secret")
  assert(n == "secret")
  assert(val == 7)
end)

test("userdata wraps a metatable", function ()
  local ud = lua.userdata({ __index = { hi = 1 } })
  assert(type(ud) == "userdata")
  assert(ud.hi == 1)
end)
