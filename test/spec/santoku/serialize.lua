local test = require("santoku.test")
local serialize = require("santoku.serialize")
local tbl = require("santoku.table")
local teq = tbl.equals
local lua = require("santoku.lua")

local function roundtrip (v)
  return lua.loadstring("return " .. serialize(v))()
end

test("serialize round-trips primitives", function ()
  assert(roundtrip(1) == 1)
  assert(roundtrip("hi") == "hi")
  assert(roundtrip(true) == true)
  assert(roundtrip(nil) == nil)
end)

test("serialize round-trips tables", function ()
  local v = { a = 1, b = { 2, 3 }, [1] = "x" }
  assert(teq(v, roundtrip(v)))
end)

test("serialize escapes strings", function ()
  assert(roundtrip("a\nb\t\"c\"") == "a\nb\t\"c\"")
  assert(roundtrip("\0\255") == "\0\255")
end)

test("serialize minify still loads", function ()
  local v = { a = 1, b = { 2, 3 } }
  assert(teq(v, lua.loadstring("return " .. serialize(v, true))()))
end)

test("serialize is callable", function ()
  assert(type(serialize({})) == "string")
end)

test("serialize_table_contents", function ()
  local s = serialize.serialize_table_contents({ 1, 2 })
  assert(teq({ 1, 2 }, lua.loadstring("return {" .. s .. "}")()))
end)
