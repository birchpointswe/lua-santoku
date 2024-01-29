local varg = require("santoku.varg")
local vlen = varg.len

local tbl = require("santoku.table")
local tassign = tbl.assign

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

return tassign({}, math, {
  trunc = trunc,
  atan = atan,
})
