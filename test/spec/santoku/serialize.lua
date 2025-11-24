local test = require("santoku.test")
local serialize = require("santoku.serialize") -- luacheck: ignore
local lua = require("santoku.lua")

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
  local t1f = lua.loadstring("return " .. serialize(t0)) -- luacheck: ignore
  assert(teq(t0, assert(t1f)())) --
end)

test("newlines", function ()
  assert(eq('{\n  ["a"] = "hello\\nworld"\n}', serialize({ a = [[hello
world]] })))
end)

test("string escaping - backslashes", function ()
  assert(eq('{\n  ["path"] = "C:\\\\Users\\\\test"\n}', serialize({ path = [[C:\Users\test]] })))
end)

test("string escaping - quotes", function ()
  assert(eq('{\n  ["msg"] = "She said \\"hello\\""\n}', serialize({ msg = [[She said "hello"]] })))
end)

test("string escaping - special chars", function ()
  assert(eq('{\n  ["s"] = "tab:\\there\\r\\nend"\n}', serialize({ s = "tab:\there\r\nend" })))
end)

test("string escaping - null bytes", function ()
  local s = serialize({ data = "hello\0world" })
  local t = assert(lua.loadstring("return " .. s))()
  assert(eq("hello\0world", t.data))
end)

test("arrays", function ()
  assert(eq('{\n  1,\n  2,\n  3\n}', serialize({ 1, 2, 3 })))
end)

test("mixed array and hash", function ()
  local s = serialize({ 1, 2, x = 10 })
  local t = assert(lua.loadstring("return " .. s))()
  assert(teq({ 1, 2, x = 10 }, t))
end)

test("nested tables", function ()
  local t = { a = { b = { c = 1 } } }
  local s = serialize(t)
  local result = assert(lua.loadstring("return " .. s))()
  assert(teq(t, result))
end)

test("empty table", function ()
  assert(eq('{}', serialize({})))
end)

test("nil values", function ()
  assert(eq('nil', serialize(nil)))
end)

test("boolean true", function ()
  assert(eq('{\n  ["b"] = true\n}', serialize({ b = true })))
end)

test("boolean false", function ()
  assert(eq('{\n  ["b"] = false\n}', serialize({ b = false })))
end)

test("boolean values - multiple keys", function ()
  local t = { t = true, f = false }
  local s = serialize(t)
  local result = assert(lua.loadstring("return " .. s))()
  assert(teq(t, result))
end)

test("integer value", function ()
  assert(eq('{\n  ["n"] = 42\n}', serialize({ n = 42 })))
end)

test("float value", function ()
  assert(eq('{\n  ["n"] = 3.14\n}', serialize({ n = 3.14 })))
end)

test("number values - multiple keys", function ()
  local t = { int = 42, float = 3.14 }
  local s = serialize(t)
  local result = assert(lua.loadstring("return " .. s))()
  assert(teq(t, result))
end)

test("NaN handling", function ()
  local s = serialize({ n = 0/0 })
  local t = assert(lua.loadstring("return " .. s))()
  assert(t.n ~= t.n) -- NaN != NaN
end)

test("infinity handling", function ()
  local orig = { pos = 1/0, neg = -1/0 }
  local s = serialize(orig)
  local t = assert(lua.loadstring("return " .. s))()
  assert(t.pos == 1/0)
  assert(t.neg == -1/0)
  assert(teq(orig, t))
end)

test("circular reference - simple", function ()
  local a = {}
  a.self = a
  local s = serialize(a)
  assert(s:match("nil")) -- Should contain nil for circular ref
end)

test("circular reference - nested", function ()
  local a = { x = 1 }
  local b = { y = 2, ref = a }
  a.back = b
  local s = serialize(a)
  assert(s:match("nil")) -- Should contain nil for circular ref
end)

test("module callable", function ()
  -- Test that serialize can be called directly
  local s = serialize({ a = 1 })
  assert(s:match("%[\"a\"%]"))
end)

test("array with holes", function ()
  -- Note: { 1, 2, nil, 4 } actually creates { [1]=1, [2]=2, [4]=4 }
  -- The nil is skipped in the table constructor
  local t = { 1, 2, nil, 4 }
  local s = serialize(t)
  local result = assert(lua.loadstring("return " .. s))()
  assert(eq(result[1], 1))
  assert(eq(result[2], 2))
  assert(eq(result[3], nil))
  assert(eq(result[4], 4)) -- Index 4 exists as a hash key

  -- Verify the serialized form has [4] as a hash key
  assert(s:match("%[4%]"))
end)

test("serialize_table_contents", function ()
  local s = serialize.serialize_table_contents({ 1, 2, 3 })
  assert(s:match("^%s*1"))  -- Should not have outer braces
  assert(not s:match("^{")) -- Should not start with brace
end)

test("minify mode", function ()
  local s = serialize({ 1, 2, 3 }, true)
  assert(eq('{1,2,3}', s))
end)

test("minify with hash", function ()
  local s = serialize({ a = 1 }, true)
  local result = assert(lua.loadstring("return " .. s))()
  assert(teq({ a = 1 }, result))
  assert(not s:match("\n")) -- Should have no newlines
end)

-- test("minify", function ()
--   assert(eq('{1,2,3,4,["a"]=10,["c"]={1,2,["z"]=9},["b"]=11}',
--     serialize({ a = 10, b = 11, 1, 2, 3, 4, c = { 1, 2, z = 9 } }, true)))
-- end)

-- test("recursive", function ()
--   local a = { 1,2,3, x = 1 }
--   a.y = a
--   assert(eq('{1,2,3,["y"]=nil,["x"]=1}', serialize(a, true)))
-- end)
