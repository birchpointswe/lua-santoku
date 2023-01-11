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

local compat = require("santoku.compat")

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
  local keys = compat.pack(...)
  if keys.n == 0 then
    return t
  else
    for i = 1, keys.n do
      t = t[keys[i]]
      if t == nil then
        break
      end
    end
    return t
  end
end

M.set = function (t, v, ...)
  assert(type(t) == "table")
  local keys = compat.pack(...)
  assert(keys.n > 0)
  local t0 = t
  for i = 1, keys.n - 1 do
    if t0 == nil then
      return
    end
    local nxt = t0[keys[i]]
    if nxt == nil then
      nxt = {}
      t0[keys[i]] = nxt
    end
    t0 = t0[keys[i]]
  end
  t0[keys[keys.n]] = v
  return t
end

M.assign = function (t, ...)
  local ts = compat.pack(...)
  for i = 1, ts.n do
    for k, v in pairs(ts[i]) do
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
  local ts = compat.pack(...)
  for i = 1, ts.n do
    for k, v in pairs(ts[i]) do
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
