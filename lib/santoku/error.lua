local arr = require("santoku.array")
local acat = arr.concat
local aoverlay = arr.overlay
local aspread = arr.spread

local varg = require("santoku.varg")
local vtup = varg.tup
local vinterleave = varg.interleave
local vmap = varg.map

local _error = error
local _pcall = pcall
local _xpcall = xpcall

local pcall_stack = 0
local current_error_mt = {
  __tostring = function (o)
    return acat({ vinterleave(": ", vmap(tostring, aspread(o))) })
  end
}

local current_error = setmetatable({}, current_error_mt)

local function error (...)
  aoverlay(current_error, 1, ...)
  if pcall_stack == 0 then
    return _error(tostring(current_error), 2)
  else
    return _error(current_error, 2)
  end
end

local function assert (ok, ...)
  if not ok then
    return error(...)
  else
    return ok, ...
  end
end

local function pcall_helper (ok, ...)
  pcall_stack = pcall_stack - 1
  if ok then
    return ok, ...
  elseif getmetatable(...) == current_error_mt then
    return ok, aspread((...))
  else
    return ok, ...
  end
end

local function xpcall_helper (handler)
  return function (...)
    pcall_stack = pcall_stack - 1
    if getmetatable((...)) == current_error_mt then
      return handler(aspread((...)))
    else
      return handler(...)
    end
  end
end

local function pcall (fn, ...)
  pcall_stack = pcall_stack + 1
  return vtup(pcall_helper, _pcall(fn, ...))
end

local function xpcall (fn, handler)
  pcall_stack = pcall_stack + 1
  return _xpcall(fn, xpcall_helper(handler))
end

local function _wrapok (v, ...)
  if not v then
    return error(...)
  else
    return ...
  end
end

local function wrapok (fn)
  return function (...)
    return vtup(_wrapok, fn(...))
  end
end

local function _wrapnil (v, ...)
  if v == nil then
    return error(...)
  else
    return v, ...
  end
end

local function wrapnil (fn)
  return function (...)
    return vtup(_wrapnil, fn(...))
  end
end

local function checknil (v, ...)
  if v == nil then
    return error(...)
  else
    return v, ...
  end
end

local function checkok (ok, ...)
  if not ok then
    return error(...)
  else
    return ...
  end
end

return {
  error = error,
  assert = assert,
  pcall = pcall,
  xpcall = xpcall,
  wrapok = wrapok,
  wrapnil = wrapnil,
  checkok = checkok,
  checknil = checknil,
}
