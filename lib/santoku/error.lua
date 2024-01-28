local arr = require("santoku.array")
local acat = arr.concat
local aspread = arr.spread

local varg = require("santoku.varg")
local vtup = varg.tup
local vinterleave = varg.interleave
local vmap = varg.map

local _error = error

local function error (...)
  _error(acat({ vinterleave(": ", vmap(tostring, ...)) }))
end

local function check (ok, ...)
  if not ok then
    _error({ ... })
  else
    return ...
  end
end

local function exists (...)
  return check(... ~= nil, ...)
end

local function try (fn, ...)
  return vtup(function (ok, e, ...)
    if ok then
      return ok, e, ...
    elseif type(e) == "table" then
      return ok, aspread(e)
    end
  end, pcall(fn, ...))
end

return {
  error = error,
  check = check,
  exists = exists,
  try = try,
}
