local compat = require("santoku.compat")

local M = {}

M.MT = {
  __call = function (M, ...)
    return M.tuple(...)
  end
}

M.TUPLES = setmetatable({}, { __mode = "kv" })

M.istuple = function (t)
  return M.TUPLES[t]
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

M._tuple = function (n, a, ...)
  if n == 0 then
    local t = function (...)
      return ...
    end
    M.TUPLES[t] = true
    return t
  else
    local rest = M._tuple(n - 1, ...)
    local t = function (...)
      return a, rest(...)
    end
    M.TUPLES[t] = true
    return t
  end
end

M.tuple = function (...)
  return M._tuple(M.len(...), ...)
end

M._interleave = function (x, n, ...)
  if n < 2 then
    return ...
  else
    return ..., x, M._interleave(x, n - 1, M.sel(2, ...))
  end
end

M.interleave = function (x, ...)
  return M._interleave(x, M.len(...), ...)
end

M._reduce = function (fn, n, a, ...)
  if n == 0 then
    return
  elseif n == 1 then
    return a
  else
    return M._reduce(fn, n - 1, fn(a, (...)), M.sel(2, ...))
  end
end

M.reduce = function (fn, ...)
  return M._reduce(fn, M.len(...), ...)
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

return setmetatable(M, M.MT)
