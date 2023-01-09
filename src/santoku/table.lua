-- TODO: mergeWith, deep merge, etc, walk a
-- table
-- TODO: Clarify where n should be added or
-- omitted: If the library input omits it, omit
-- it except in the case of wrapn, setn, pack,
-- etc.
-- TODO: Ensure that n is getting updated
-- correctly

local M = {}

M.inspect = function (t)
  return require("inspect")(M.unwrapped(t))
end

M.inspectp = function (t)
  print(M.inspect(t))
end

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

M.wrapn = function (t, n)
  return M.wrap(M.setn(t, n))
end

M.unwrapn = function (t)
  t.n = nil
  return M.unwrap(t)
end

M.unwrappedn = function (t)
  local t0 = M.assign({}, t)
  t0.n = nil
  return t0
end

local pack = table.pack or function (...) -- luacheck: ignore
  return M.wrap({ n = select("#", ...), ... })
end

M.pack = function (...)
  return M.wrap(pack(...))
end

local unpack = unpack or table.unpack -- luacheck: ignore

-- TODO: Do we really need to create a new table
-- for this?
M.unpack = function (...)
  local t = M.wrapn():extend(...)
  return unpack(t, 1, t.n)
end

M.move = table.move or function (a1, f, e, t, a2) -- luacheck: ignore
	a2 = a2 or a1
	t = t + e
	for i = e, f, -1 do
		t = t - 1
		a2[t] = a1[i]
	end
	return a2
end

M.insert = function (t, i, v)
  if v == nil then
    i = v
    v = nil
  end
  if i == nil then
    t[t:len() + 1] = v
    if t.n then
      t.n = t.n + 1
    end
  else
    t[i] = v
  end
  return t
end

M.len = function (t)
  return t.n or #t
end

M.msetn = function (t, n)
  if t.n then
    return M.setn(t, n)
  else
    return t
  end
end

M.setn = function (t, n)
  t = t or {}
  n = n or 0
  t.n = n or #t
  return t
end

M.getn = function (t)
  return t.n
end

M.maxn = function (t)
  local n
  for k in pairs(t) do
    if type(k) == "number" then
      if n == nil or k > n then
        n = k
      end
    end
  end
  return n
end

M.assign = function (t0, ...)
  for i = 1, select("#", ...) do
    local t1 = select(i, ...)
    for k, v in pairs(t1) do
      t0[k] = v
    end
  end
  return t0
end

-- TODO: There MUST be a better way to do this,
-- but neither ipairs nor 'i = 0, #t' can manage
-- to handle both leading nils and intermixed
-- nils as expected.
M.extend = function (t0, ...)
  local n = t0.n or M.maxn(t0) or 0
  for i = 1, select("#", ...) do
    local t1 = select(i, ...)
    local m = 0
    if t1.n then
      m = t1.n
      for j = 1, t1.n do
        t0[j + n] = t1[j]
      end
    else
      for k, v in pairs(t1) do
        if type(k) == "number" then
          if k > m then
            m = k
          end
          t0[k + n] = v
        end
      end
    end
    n = n + m
  end
  M.msetn(t0, n)
  return t0
end

M.appender = function (...)
  local args = M.pack(...)
  return function (a)
    return M.wrap(a):extend(args)
  end
end

M.append = function (a, ...)
  return M.appender(...)(a)
end

M.each = function (t, fn, ...)
  for i = 1, M.len(t) do
    fn(t[i], ...)
  end
end

-- TODO: This doesn't check keys that are
-- present in a but not in ts
M.equals = function (a, ...)
  local ts = M.pack(...)
  for i = 1, ts.n do
    for k, v in pairs(ts[i]) do
      if a[k] ~= v then
        return false
      end
    end
  end
  return true
end

M.sort = function (t)
  table.sort(t)
  return t
end

-- TODO: Need to test this more, not sure if the
-- done logic is correct
M.bubble = function (t, ...)
  local done = M.wrap()
  local idx = M.wrap({ ... })
  for i = 1, idx:len() do
    if not done:get(i, idx[i]) then
      t[i], t[idx[i]] = t[idx[i]], t[i]
      done:set(true, idx[i], i)
    end
  end
  return t
end

local map
map = function (head, tail, fn, ...)
  if tail:len() == 0 then
    return head
  else
    local v = fn(M.tuple(tail:head()):append(...)())
    return map(head:append(v), tail:tail(), fn, ...)
  end
end

M.map = function (tup, ...)
  return map(M.tuple(), tup, ...)
end

-- TODO: let first argument be the object so we
-- can chain
-- TODO: Clean this up a lot
-- TODO: allow composition
M.lens = function (keys, opts, ...)
  keys = M.wrap(keys)
  local create = (opts or {}).create
  local fn = (opts or {}).fn or function (...) return ... end
  local args = M.pack(...)
  return function(t)
    if keys:len() == 0 then
      return t, fn(t, args:unpack())
    else
      local t0 = t
      for i = 1, keys:len() - 1 do
        if t0 == nil then
          return
        end
        local nxt = t0[keys[i]]
        if nxt == nil and create then
          nxt = {}
          t0[keys[i]] = nxt
        end
        t0 = t0[keys[i]]
      end
      if t0 == nil then
        return
      else
        local val = fn(t0[keys[keys:len()]])
        t0[keys[keys:len()]] = val
        return t, val
      end
    end
  end
end

M.getter = function (...)
  local lens = M.lens(M.pack(...))
  return function (t)
    local _, v = lens(t)
    return v
  end
end

M.get = function (t, ...)
  return M.getter(...)(t)
end

M.setter = function (...)
  local keys = M.pack(...)
  return function (v)
    return M.lens(keys, {
      create = true,
      fn = function ()
        return v
      end
    })
  end
end

M.set = function (t, v, ...)
  return M.setter(...)(v)(t)
end

return setmetatable({}, {
  __index = M,
  __call = function (_, t)
    return M.wrap(t)
  end
})
