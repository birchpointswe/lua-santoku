local compat = require("santoku.compat")

local M = setmetatable({}, {
  __call = function (M, ...)
    return M.tuple(...)
  end
})

local function tuple (n, a, ...)
  if n == 0 then
    return function (...)
      return ...
    end
  else
    local rest = tuple(n - 1, ...)
    return function (...)
      return a, rest(...)
    end
  end
end

M.len = function (...)
  return M.sel("#", ...)
end

M.sel = function (i, ...)
  return select(i, ...)
end

M.take = function (i, ...)
  if i == 0 then
    return
  else
    return (...), M.take(i - 1, M.sel(2, ...))
  end
end

M.get = function (i, ...) -- luacheck: ignore
  return (M.sel(i, ...))
end

M.set = function (i, v, ...) -- luacheck: ignore
  -- TODO
end

M.append = function (a, ...) -- luacheck: ignore
  return M.tuple(...)(a)
end

M.equals = function (a, ...)
  local m = M.len(a())
  local ts = M.len(...)
  for j = 1, ts do
    local b = M.sel(j, ...)
    if b == nil then
      return false
    end
    local n = M.len(b())
    if m ~= n then
      return false
    end
  end
  for i = 1, m do
    local v = M.sel(i, a())
    for j = 1, ts do
      local b = M.sel(j, ...)
      local w = M.sel(i, b())
      if v ~= w then
        return false
      end
    end
  end
  return true
end

M.tuple = function (...)
  return tuple(M.len(...), ...)
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

M.filter = function (fn, ...)
  assert(compat.hasmeta.call(fn))
  local n = M.len(...)
  if n == 0 then
    return
  elseif fn((...)) then
    return ..., M.filter(fn, M.sel(2, ...))
  else
    return M.filter(fn, M.sel(2, ...))
  end
end

M.each = function (fn, ...)
  assert(compat.hasmeta.call(fn))
  if M.len(...) > 0 then
    fn((...))
    M.each(fn, M.sel(2, ...))
  end
end

M.map = function (fn, ...)
  assert(compat.hasmeta.call(fn))
  if M.len(...) == 0 then
    return
  else
    return fn((M.sel(1, ...))), M.map(fn, M.sel(2, ...))
  end
end

return M
