-- Functions that operate on pure lua tables

-- TODO: Add the pre-curried functions

-- TODO: merge, deep merge, etc, walk a
-- table
--
-- TODO: Clarify where n should be added or
-- omitted: If the library input omits it, omit
-- it except in the case of wrapn, setn, pack,
-- etc.
--
-- Don't use oop style in here, leave that for
-- the API user

local compat = require("santoku.compat")

local M = setmetatable({}, {
  __call = function (M, t)
    return M.wrap(t)
  end
})

local MTT = {
  __index = M
}

-- TODO use inherit
M.wrap = function (t)
  t = t or {}
  return setmetatable(t, MTT)
end

M.unwrap = function (t)
  setmetatable(t, nil)
  return t
end

M.unwrapped = function (t)
  return M.assign({}, t)
end

M.get = function (t, ...)
  assert(type(t) == "table")
  local m = select("#", ...)
  if m == 0 then
    return t
  else
    for i = 1, m do
      t = t[select(i, ...)]
      if t == nil then
        break
      end
    end
    return t
  end
end

M.set = function (t, v, ...)
  assert(type(t) == "table")
  local m = select("#", ...)
  assert(m > 0)
  local t0 = t
  for i = 1, m - 1 do
    local k = select(i, ...)
    if t0 == nil then
      return
    end
    local nxt = t0[k]
    if nxt == nil then
      nxt = {}
      t0[k] = nxt
    end
    t0 = t0[k]
  end
  t0[select(m, ...)] = v
  return t
end

M.assign = function (t, ...)
  local m = select("#", ...)
  for i = 1, m do
    local t0 = select(i, ...)
    for k, v in pairs(t0) do
      t[k] = v
    end
  end
  return t
end

M.each = function (t, fn, ...)
  for k, v in pairs(t) do
    fn(k, v, ...)
  end
end

M.map = function (t, fn, ...)
  for k, v in pairs(t) do
    t[k] = fn(v, ...)
  end
  return t
end

-- TODO: This doesn't check keys that are
-- present in a but not in ts
M.equals = function (a, ...)
  local m = select("#", ...)
  for i = 1, m do
    local t0 = select(i, ...)
    for k, v in pairs(t0) do
      if a[k] ~= v then
        return false
      end
    end
  end
  return true
end

M.merge = function (t, ...)
  assert(type(t) == "table")
  for i = 1, select("#", ...) do
    local t0 = select(i, ...)
    for k, v in pairs(t0) do
      if t[k] ~= nil and type(t[k]) ~= "table" then -- luacheck: ignore
        -- do nothing
      elseif type(v) == "table" then
        t[k] = t[k] or {}
        M.merge(t[k], v)
      else
        t[k] = v
      end
    end
  end
  return t
end

-- TODO: Reduce all of these pack/unpacks
local paths
paths = function (t, fn, stop, ...)
  for k, v in pairs(t) do
    if stop(v) then
      fn(compat.unpackr(compat.pack(k, ...)))
    else
      paths(v, fn, stop, k, ...)
    end
  end
end

M.paths = function (t, fn, stop)
  stop = stop or function (v)
    return type(v) ~= "table"
  end
  assert(compat.iscallable(stop))
  assert(compat.iscallable(fn))
  return paths(t, fn, stop)
end

-- TODO: Can we do this without creating a
-- vector of path vectors?
-- TODO: Reduce all of these pack/unpacks
-- TODO: This might be better of called reduce
M.mergeWith = function (t, spec, ...)
  for i = 1, select("#", ...) do
    local t0 = select(i, ...)
    M.paths(spec, function (...)
      M.set(t,
        M.get(spec, ...)(
          M.get(t, ...),
          M.get(t0, ...)),
        ...)
    end)
  end
  return t
end

M.len = function (t)
  assert(type(t) == "table")
  return t.n or #t
end

return M
