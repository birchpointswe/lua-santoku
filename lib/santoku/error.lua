local validate = require("santoku.validate")
local hascall = validate.hascall

local arr = require("santoku.array")
local acat = arr.concat
local aspread = arr.spread

local varg = require("santoku.varg")
local vtup = varg.tup
local vinterleave = varg.interleave
local vmap = varg.map

local _error = error
local _assert = assert

local function errfmt (...)
  return acat({ vinterleave(": ", vmap(tostring, ...)) })
end

local function error (...)
  return _error(errfmt(...))
end

local function assert (ok, ...)
  if not ok then
    return _assert(false, errfmt(...))
  else
    return ok, ...
  end
end

local function check (ok, ...)
  if not ok then
    return _error({ ... })
  else
    return ...
  end
end

local function exists (...)
  return check(... ~= nil, ...)
end

local function _wrapexists (v, ...)
  if v == nil then
    return false, ...
  else
    return true, v, ...
  end
end

local function wrapexists (fn)
  assert(hascall(fn))
  return function (...)
    return vtup(_wrapexists, fn(...))
  end
end

local function _try (ok, e, ...)
  if ok then
    return ok, e, ...
  elseif type(e) == "table" then
    return ok, aspread(e)
  else
    return ok, e, ...
  end
end

local function try (fn, ...)
  return vtup(_try, pcall(fn, ...))
end

return {
  error = error,
  errfmt = errfmt,
  assert = assert,
  check = check,
  exists = exists,
  wrapexists = wrapexists,
  try = try,
}
