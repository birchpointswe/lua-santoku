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
  errfmt = errfmt,
  assert = assert,
  check = check,
  exists = exists,
  try = try,
}
