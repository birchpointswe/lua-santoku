local compat = require("santoku.compat")

local M = {}

local function tuple (n, a, ...)
  if n == 0 then
    return function (...)
      return ...
    end, 0
  else
    local rest = tuple(n - 1, ...)
    return function (...)
      return a, rest(...)
    end, n
  end
end

M.len = function (...)
  return select("#", ...)
end

M.sel = function (i, ...)
  return select(i, ...)
end

M.get = function (i, ...) -- luacheck: ignore
  -- TODO
end

M.set = function (i, v, ...) -- luacheck: ignore
  -- TODO
end

M.append = function (a, ...) -- luacheck: ignore
  return M.tuple(...)(a)
end

M.equals = function (a, ...)
  local m = select("#", a())
  local ts = select("#", ...)
  for j = 1, ts do
    local b = select(j, ...)
    if b == nil then
      return false
    end
    local n = select("#", b())
    if m ~= n then
      return false
    end
  end
  for i = 1, m do
    local v = select(i, a())
    for j = 1, ts do
      local b = select(j, ...)
      local w = select(i, b())
      if v ~= w then
        return false
      end
    end
  end
  return true
end

M.tuple = function (...)
  return tuple(select("#", ...), ...)
end

local function interleave (x, n, ...)
  if n < 2 then
    return ...
  else
    return ..., x, interleave(x, n - 1, M.sel(2, ...))
  end
end

M.interleave = function (x, ...)
  return interleave(x, M.len(...), ...)
end

local function reduce (fn, n, a, ...)
  if n == 0 then
    return
  elseif n == 1 then
    return a
  else
    return reduce(fn, n - 1, fn(a, (...)), M.sel(2, ...))
  end
end

M.reduce = function (fn, ...)
  return reduce(fn, M.len(...), ...)
end

M.concat = function (...)
  return table.concat({ ... })
end

M.slice = function (i, ...)
  local m = M.len(...)
  if i > m or i < -m then
    return
  elseif i < 0 then
    return M.slice(i + 1, select(2, ...))
  elseif i > 0 then
    return M.slice(i - 1, select(2, ...))
  end
end

M.filter = function (fn, ...)
  assert(compat.iscallable(fn))
  local n = select("#", ...)
  if n == 0 then
    return
  elseif fn((...)) then
    return ..., M.filter(fn, select(2, ...))
  else
    return M.filter(fn, select(2, ...))
  end
end

M.each = function (fn, ...)
  assert(compat.iscallable(fn))
  if M.len(...) > 0 then
    fn((...))
    M.each(fn, M.sel(2, ...))
  end
end

M.map = function (fn, ...)
  assert(compat.iscallable(fn))
  if select("#", ...) == 0 then
    return
  else
    return fn((select(1, ...))), M.map(fn, select(2, ...))
  end
end

return setmetatable(M, {
  __call = function (_, ...)
    return M.tuple(...)
  end
})
