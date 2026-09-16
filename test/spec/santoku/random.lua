local test = require("santoku.test")
local rand = require("santoku.random")
local str = require("santoku.string")
local validate = require("santoku.validate")

local eq = validate.isequal
local neq = validate.isnotequal

local spawn_ok, spawn_probe = pcall(io.popen, "true")
local can_spawn = spawn_ok and spawn_probe ~= nil
if can_spawn then spawn_probe:close() end

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
  local s = rand.alnum(2000)
  assert(eq(#s, 2000))
  for i = 1, #s do
    local b = str.byte(s, i)
    assert((b >= 48 and b <= 57) or (b >= 65 and b <= 90) or (b >= 97 and b <= 122),
      "alnum produced a non-alphanumeric byte: " .. b)
  end
end)

test("fast", function ()

  rand.fast_normal(0, 100)
  rand.fast_random()
end)

if can_spawn then
  test("generators are seeded per process", function ()
    local lua = arg and arg[-1] or "lua5.1"
    local prog = "local r = require('santoku.random') print(r.fast_random(), r.alnum(12))"
    local out = {}
    for i = 1, 3 do
      local f = io.popen(lua .. " -e \"" .. prog .. "\" 2>/dev/null")
      out[i] = f:read("*a")
      f:close()
    end
    assert(out[1] ~= "" and out[1] ~= nil, "could not spawn a child interpreter")
    assert(not (out[1] == out[2] and out[2] == out[3]),
      "three processes produced the identical fast_random stream: " .. tostring(out[1]))
  end)

  test("explicit seeding stays reproducible", function ()
    local lua = arg and arg[-1] or "lua5.1"
    local prog = "local r = require('santoku.random') r.seed(42) r.fast_seed(42) " ..
      "print(r.fast_random(), r.alnum(12), r.num(1, 1000000))"
    local out = {}
    for i = 1, 2 do
      local f = io.popen(lua .. " -e \"" .. prog .. "\" 2>/dev/null")
      out[i] = f:read("*a")
      f:close()
    end
    assert(out[1] ~= "" and out[1] ~= nil, "could not spawn a child interpreter")
    assert(out[1] == out[2],
      "explicit seeding must be reproducible across processes: " ..
      tostring(out[1]) .. " vs " .. tostring(out[2]))
  end)
end
