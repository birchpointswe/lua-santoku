-- Functions that operate on pure lua tables

-- TODO: Add the pre-curried functions

-- TODO: mergeWith, deep merge, etc, walk a
-- table
--
-- TODO: Clarify where n should be added or
-- omitted: If the library input omits it, omit
-- it except in the case of wrapn, setn, pack,
-- etc.
--
-- Don't use oop style in here, leave that for
-- the API user

local M = {}

-- TODO use inherit
M.wrap = function (t)
  t = t or {}
  return setmetatable(t, {
    __index = M
  })
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

return setmetatable({}, {
  __index = M,
  __call = function (_, t)
    return M.wrap(t)
  end
})
