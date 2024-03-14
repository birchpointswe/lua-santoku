local test = require("santoku.test")
local rand = require("santoku.random")
local validate = require("santoku.validate")

local eq = validate.isequal
local neq = validate.isnotequal

test("num", function ()
  assert(neq(rand.num(), rand.num()))
  assert(neq(rand.num(), rand.num()))
end)

test("str", function ()
  assert(eq(#rand.str(10), 10))
  assert(neq(rand.str(10), rand.str(10)))
  assert(neq(rand.str(10), rand.str(10)))
end)

test("alnum", function ()
  local s = rand.alnum(10)
  for i = 1, 10 do
    local b = string.byte(s:sub(i, i))
    assert(b >= 48 and b <= 122)
  end
end)

test("fast", function ()
  -- TODO: how to test this?
  rand.fast_normal(0, 100)
  rand.fast_random()
end)
