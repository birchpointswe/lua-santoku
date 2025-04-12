local varg = require("santoku.varg")
local vlen = varg.len

local tbl = require("santoku.table")
local tmerge = tbl.merge

local modf = math.modf
local _atan = math.atan
local _atan2 = math.atan2 -- luacheck: ignore

local function trunc (n, d)
  local i, f = modf(n)
  d = 10^d
  return i + modf(f * d) / d
end

local function atan (...)
  if vlen(...) > 1 and _atan2  -- luacheck: ignore
  then
    return _atan2(...) -- luacheck: ignore
  else
    return _atan(...)
  end
end

local function mavg (alpha)
  alpha = alpha or 0.2
  local avg
  return function (v)
    if not avg then
      avg = v
      return avg
    else
      avg = alpha * v + (1 - alpha) * avg
      return avg
    end
  end
end


local function round (n, m)
  if m then
    return math.ceil(n / m) * m
  else
    return math.floor(n + 0.5)
  end
end

return tmerge({
  trunc = trunc,
  atan = atan,
  mavg = mavg,
  round = round,
}, math)
