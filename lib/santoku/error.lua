local arr = require("santoku.array")
local select = select

local _error = error
local _pcall = pcall
local _xpcall = xpcall

local co_create = coroutine.create
local co_resume = coroutine.resume
local co_status = coroutine.status
local co_yield = coroutine.yield
local co_running = coroutine.running

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

local function copcall_handle (co, ok, ...)
  if not ok then
    pcall_stack = pcall_stack - 1
    if getmetatable(...) == mt then
      return false, arr.spread((...))
    else
      return false, ...
    end
  elseif co_status(co) == "suspended" then
    pcall_stack = pcall_stack - 1
    local resumed = { co_yield(...) }
    pcall_stack = pcall_stack + 1
    return copcall_handle(co, co_resume(co, arr.spread(resumed)))
  else
    pcall_stack = pcall_stack - 1
    return true, ...
  end
end

local function copcall (fn, ...)
  pcall_stack = pcall_stack + 1
  local co = co_create(fn)
  return copcall_handle(co, co_resume(co, ...))
end

local function pcall (fn, ...)
  if co_running() then
    return copcall(fn, ...)
  else
    pcall_stack = pcall_stack + 1
    return pcall_finalizer(_pcall(fn, ...))
  end
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

local function coxpcall_handle (co, handler, ok, ...)
  if not ok then
    pcall_stack = pcall_stack - 1
    local err_val = ...
    if getmetatable(err_val) == mt then
      return false, handler(arr.spread(err_val))
    else
      return false, handler(err_val)
    end
  elseif co_status(co) == "suspended" then
    pcall_stack = pcall_stack - 1
    local resumed = { co_yield(...) }
    pcall_stack = pcall_stack + 1
    return coxpcall_handle(co, handler, co_resume(co, arr.spread(resumed)))
  else
    pcall_stack = pcall_stack - 1
    return true, ...
  end
end

local function coxpcall (fn, handler)
  pcall_stack = pcall_stack + 1
  local co = co_create(fn)
  return coxpcall_handle(co, handler, co_resume(co))
end

local function xpcall (fn, handler)
  if co_running() then
    return coxpcall(fn, handler)
  else
    pcall_stack = pcall_stack + 1
    return xpcall_finalizer(_xpcall(fn, xpcall_helper(handler)))
  end
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
