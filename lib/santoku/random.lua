local tbl = require("santoku.table")
local fun = require("santoku.functional")
local it = require("santoku.iter")
local arr = require("santoku.array")
local fast = require("santoku.random.fast")

local _seed = math.randomseed
local _time = os.time
local _char = string.char
local _select = select
local _concat = table.concat
local _rand = math.random
local _sqrt = math.sqrt
local _log = math.log
local _cos = math.cos
local _pi = math.pi
local _max = math.max
local _min = math.min

local function seed (t)
  t = t or _time()
  _seed(t)
end

local function str (n, ...)
  local l, u
  if _select("#", ...) > 0 then
    l, u = ...
  else
    l, u = 32, 127
  end
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

local function norm ()
  local u1 = _rand()
  local u2 = _rand()
  local z = _sqrt(-2 * _log(u1)) * _cos(2 * _pi * u2)
  return _max(-1, _min(1, z))
end

local function _options (params, unique, chunk)
  local n = 0
  chunk = chunk or 1000
  local base = {}
  for k, v in pairs(params) do
    base[k] = it.collect(it.take(chunk, v))
    arr.shuffle(base[k])
  end
  local seen = {}
  local helper
  helper = function ()
    local ret = {}
    for k, v in pairs(base) do
      local i = _rand(1, #v)
      ret[k] = v[i]
    end
    n = n + 1
    local k = tbl.concat(arr.map(arr.sort(it.collect(it.keys(ret))), function (k)
      local r = ret[k]
      if type(r) == "table" then
        return tbl.concat(arr.map(arr.sort(it.collect(it.keys(r))), fun.tget(r)), " ")
      else
        return tostring(r)
      end
    end), " ")
    if not unique or not seen[k] then
      return ret, n, k
    else
      return helper()
    end
  end
  return helper
end

local function options (params, each, unique, chunk)
  for ret, n, k in _options(params, unique, chunk) do
    if each(ret, n, k) == false then
      break
    end
  end
end

return tbl.merge({
  seed = seed,
  str = str,
  num = _rand,
  norm = norm,
  alnum = alnum,
  options = options
}, fast)
