local test = require("santoku.test")
local serialize = require("santoku.serialize") -- luacheck: ignore

local err = require("santoku.error")
local assert = err.assert

local validate = require("santoku.validate")
local eq = validate.isequal

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

test("newlines", function ()
  assert(eq('{\n  ["a"] = "hello\\nworld"\n}', serialize({ a = [[hello
world]] })))
end)

test("minify", function ()
  assert(eq('{1,2,3,4,["a"]=10,["c"]={1,2,["z"]=9},["b"]=11}',
    serialize({ a = 10, b = 11, 1, 2, 3, 4, c = { 1, 2, z = 9 } }, true)))
end)
