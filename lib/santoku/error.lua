local arr = require("santoku.array")
local acat = arr.concat
local aspread = arr.spread

local varg = require("santoku.varg")
local vtup = varg.tup
local vinterleave = varg.interleave
local vmap = varg.map

local _error = error
local _pcall = pcall
local _xpcall = xpcall

local pcall_stack = 0
local mt = {
  __tostring = function (o)
    return acat({ vinterleave(": ", vmap(tostring, aspread(o))) })
  end
}

local function error (...)
  local e = setmetatable({ ... }, mt)
  if pcall_stack == 0 then
    return _error(tostring(e), 2)
  else
    return _error(e, 2)
  end
end

local function assert (ok, ...)
  if not ok then
    return error(...)
  else
    return ok, ...
  end
end

local function pcall_finalizer (ok, ...)
  pcall_stack = pcall_stack - 1
  if ok then
    return ok, ...
  elseif getmetatable(...) == mt then
    return ok, aspread((...))
  else
    return ok, ...
  end
end

local function pcall (fn, ...)
  pcall_stack = pcall_stack + 1
  return vtup(pcall_finalizer, _pcall(fn, ...))
end

local function xpcall_finalizer (ok, ...)
  -- NOTE: not decrementing pcall_stack here since it's done in xpcall_helper.
  -- Is that right?'
  if ok then
    return ok, ...
  elseif getmetatable(...) == mt then
    return ok, aspread((...))
  else
    return ok, ...
  end
end

local function xpcall_helper (handler)
  return function (...)
    pcall_stack = pcall_stack - 1
    if getmetatable(...) == mt then
      return varg.tup(function (...)
        return setmetatable({ ... }, mt)
      end, pcall(handler, aspread((...))))
    else
      return varg.tup(function (...)
        return setmetatable({ ... }, mt)
      end, pcall(handler, ...))
    end
  end
end

local function xpcall (fn, handler)
  pcall_stack = pcall_stack + 1
  return vtup(xpcall_finalizer, _xpcall(fn, xpcall_helper(handler)))
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
