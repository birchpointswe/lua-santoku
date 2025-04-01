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

-- local fun = require("santoku.functional")
-- local arr = require("santoku.array")
-- local it = require("santoku.iter")
-- local serialize = require("santoku.serialize")
-- test("options", function ()
--   rand.options({
--     hidden = it.range(64, 2048, fun.mul(2)),
--     specificity = it.map(arr.pack, it.range(2, 20, fun.add(2), 4)),
--     clauses = it.range(512, 8192, fun.mul(2), 2),
--     target = it.range(8, 4096, fun.mul(2))
--   }, function (opts, n)
--       if opts.target < opts.clauses / 2 then
--         print(serialize(opts, true))
--       end
--       return n < 100
--     end, true)
-- end)
