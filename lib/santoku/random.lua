-- TODO: Cryptography functions

local _seed = math.randomseed
local _time = os.time
local _char = string.char
local _select = select
local _concat = table.concat
local _rand = math.random

local function seed (t)
  t = t or _time()
  _seed(t)
end

local function str (n, ...)
  assert(type(n) == "number" and n > 0)
  local l, u
  if _select("#", ...) > 0 then
    l, u = ...
  else
    l, u = 32, 127
  end
  assert(type(l) == "number" and l >= 0)
  assert(type(u) == "number" and u >= l)
  local t = {}
  n = n or 1
  while n > 0 do
    t[n] = _char(_rand(l, u))
    n = n - 1
  end
  return _concat(t)
end

local function alnum (n)
  return str(n, 48, 122)
end

return {
  seed = seed,
  str = str,
  num = _rand,
  alnum = alnum,
}
