local varg = require("santoku.varg")
local vsel = varg.sel
local vlen = varg.len
local vtake = varg.take

local function bind (fn, ...)
  if vlen(...) == 0 then
    return fn
  else
    local v = ...
    return function (...)
      return fn(v, ...)
    end
  end
end

local function maybe (fn)
  return function (ok, ...)
    if ok then
      return true, fn(...)
    else
      return false, ...
    end
  end
end

local function compose (a, b)
  return function (...)
    return a(b(...))
  end
end

local function sel (fn, n)
  return function (...)
    return fn(vsel(n, ...))
  end
end

local function take (fn, n)
  return function (...)
    return fn(vtake(n, ...))
  end
end

local function choose (a, b, c, ...)
  if a then
    return b, ...
  else
    return c, ...
  end
end

local function id (...)
  return ...
end

local function noop () end

local function const (x)
  return function ()
    return x
  end
end

return {
  id = id,
  bind = bind,
  maybe = maybe,
  compose = compose,
  noop = noop,
  sel = sel,
  take = take,
  choose = choose,
  const = const,
}
