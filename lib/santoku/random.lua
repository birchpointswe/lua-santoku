-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2023 Birch Point SWE
local tbl = require("santoku.table")
local arr = require("santoku.array")
local fast = require("santoku.random.fast")

local _seed = math.randomseed
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
  _seed(t or fast.fast_random())
end

seed()

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

local _alnum = {}

for i = 48, 57 do
  _alnum[#_alnum + 1] = _char(i)
end

for i = 65, 90 do
  _alnum[#_alnum + 1] = _char(i)
end

for i = 97, 122 do
  _alnum[#_alnum + 1] = _char(i)
end

local _alnum_n = #_alnum

local function alnum (n)
  local t = {}
  n = n or 1
  while n > 0 do
    t[n] = _alnum[_rand(1, _alnum_n)]
    n = n - 1
  end
  return _concat(t)
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
    base[k] = arr.icollect(chunk, v)
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
    local k = tbl.concat(arr.map(arr.sort(tbl.keys(ret)), function (k)
      local r = ret[k]
      if type(r) == "table" then
        return tbl.concat(arr.map(arr.sort(tbl.keys(r)), function (k) return r[k] end), " ")
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
