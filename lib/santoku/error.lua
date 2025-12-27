local arr = require("santoku.array")
local co_factory = require("santoku.co")
local select = select

local _error = error
local _pcall = pcall
local _xpcall = xpcall

local pcall_stack = 0
local mt = {
  __tostring = function (o)
    local parts = {}
    for i = 1, #o do
      parts[#parts + 1] = tostring(o[i])
    end
    return table.concat(parts, ": ")
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
    return ok, arr.spread((...))
  else
    return ok, ...
  end
end

local function pcall (fn, ...)
  pcall_stack = pcall_stack + 1
  return pcall_finalizer(_pcall(fn, ...))
end

local function xpcall_finalizer (ok, ...)
  if ok then
    return ok, ...
  elseif getmetatable(...) == mt then
    return ok, select(2, arr.spread((...)))
  else
    return ok, select(2, ...)
  end
end

local function xpcall_helper (handler)
  return function (...)
    pcall_stack = pcall_stack - 1
    local function wrap_result (...)
      return setmetatable({ ... }, mt)
    end
    if getmetatable(...) == mt then
      return wrap_result(pcall(handler, arr.spread((...))))
    else
      return wrap_result(pcall(handler, ...))
    end
  end
end

local function xpcall (fn, handler)
  pcall_stack = pcall_stack + 1
  return xpcall_finalizer(_xpcall(fn, xpcall_helper(handler)))
end

local function wrapok (fn)
  return function (...)
    local v, r1, r2, r3, r4 = fn(...)
    if not v then
      return error(r1, r2, r3, r4)
    else
      return r1, r2, r3, r4
    end
  end
end

local function wrapnil (fn)
  return function (...)
    local v, r1, r2, r3, r4 = fn(...)
    if v == nil then
      return error(r1, r2, r3, r4)
    else
      return v, r1, r2, r3, r4
    end
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

local function copcall_finalizer (ok, ...)
  if ok then
    return ok, ...
  elseif getmetatable(...) == mt then
    return ok, arr.spread((...))
  else
    return ok, ...
  end
end

local function copcall (fn, ...)
  local co = co_factory()
  local args = { ... }
  return copcall_finalizer(co.resume(co.create(function ()
    return fn(arr.spread(args))
  end)))
end

local function coxpcall_finalizer (ok, ...)
  if ok then
    return ok, ...
  elseif getmetatable(...) == mt then
    return ok, select(2, arr.spread((...)))
  else
    return ok, select(2, ...)
  end
end

local function coxpcall (fn, handler, ...)
  local co = co_factory()
  local args = { ... }
  local results = { co.resume(co.create(function ()
    return fn(arr.spread(args))
  end)) }
  if results[1] then
    return arr.spread(results)
  else
    local err_val = results[2]
    if getmetatable(err_val) == mt then
      err_val = arr.spread(err_val)
    end
    local handler_ok, handler_result = copcall(handler, err_val)
    if handler_ok then
      return coxpcall_finalizer(false, handler_result)
    else
      return coxpcall_finalizer(false, handler_result)
    end
  end
end

return {
  error = error,
  assert = assert,
  pcall = pcall,
  xpcall = xpcall,
  copcall = copcall,
  coxpcall = coxpcall,
  wrapok = wrapok,
  wrapnil = wrapnil,
  checkok = checkok,
  checknil = checknil,
}
