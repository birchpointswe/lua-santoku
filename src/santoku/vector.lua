-- Functions that operate on array-like tables
-- with an 'n' property.

-- TODO: Should we add N if the user passes
-- in a table without n? Perhaps assert/error is
-- better. After deciding, clean up functions

-- TODO: Add isvec checks and pre-curried
-- functions

-- TODO: Consider integrating "zip" into the
-- various other existing functions so that map
-- can map over many, reduce, etc. Reconcile
-- multiple implementations of the same function

-- TODO: Keep low-level primitives like
-- reduce, zip, etc. in vector.lua and gen.lua,
-- but have a generic.lua that contains the
-- higher-level functions built on them.

local compat = require("santoku.compat")
local tbl = require("santoku.table")

local M = {}

-- TODO use inherit
M.isvec = function (t)
  if type(t) ~= "table" then
    return false
  end
  return (getmetatable(t) or {}).__index == M
end

-- TODO use inherit
M.wrap = function (t)
  t = t or {}
  assert(type(t) == "table")
  return setmetatable(t, {
    __index = M
  })
end

M.unwrap = function (t)
  assert(M.isvec(t))
  t.n = nil
  setmetatable(t, nil)
  return t
end

M.unwrapped = function (t)
  assert(M.isvec(t))
  local t0 = tbl.assign({}, t)
  t0.n = nil
  return t0
end

M.pack = function (...)
  return M.wrap(compat.pack(...))
end

M.unpack = function (t, s, e)
  s = s or 1
  e = e or t.n
  assert(type(s) == "number")
  assert(type(e) == "number")
  return compat.unpack(t, s, e)
end

M.insert = function (t, i, v)
  assert(M.isvec(t))
  if v == nil then
    v = i
    i = t.n + 1
  end
  assert(type(i) == "number")
  if i > t.n then
    t.n = i
  end
  t:copy(i, i + 1)
  t[i] = v
  return t
end

M.sort = function (t)
  assert(M.isvec(t))
  table.sort(t, 1, t.n)
  return t
end

-- TODO
M.binsert = function (t, cmp)
  assert(M.isvec(t))
  assert(type(cmp) == "function")
end

-- TODO
M.bsearch = function (t, cmp)
  assert(M.isvec(t))
  assert(type(cmp) == "function")
end

M.slice = function (s, ss, se)
  assert(M.isvec(s))
  return M.pack():copy(s, 1, ss, se)
end

M.find = function (t, fn, ...)
  assert(M.isvec(t))
  assert(type(fn) == "function")
  for i = 1, t.n do
    if fn(t[i], ...) then
      return t[i]
    end
  end
end

local copy = function (d, s, ds, ss, se, ismove)
  assert(M.isvec(d))
  assert(M.isvec(s))
  ds = ds or (d.n + 1)
  ss = ss or 1
  se = se or s.n
  if se > s.n then se = s.n end
  if se == 0 then return d end
  assert(type(ds) == "number" and ds > 0)
  assert(type(ss) == "number" and ss > 0 and ss <= s.n)
  assert(type(se) == "number" and se > 0 and se <= s.n)
  compat.move(s, ss, se, ds, d)
  local n = (ds + (se - ss)) - d.n
  if n > 0 then
    d.n = d.n + n
  end
  if ismove then
    compat.move(s, se, s.n, ss, s)
    s.n = s.n - (se - ss)
  end
  return d
end

-- TODO: Should really re-arrange source/dest
-- ordering here
M.copy = function (d, s, ds, ss, se)
  if not M.isvec(s) then
    s, ds, ss, se = d, s, ds, ss
  end
  return copy(d, s, ds, ss, se, false)
end

-- TODO: Should really re-arrange source/dest
-- ordering here
M.move = function (d, s, ds, ss, se)
  if not M.isvec(s) then
    s, ds, ss, se = d, s, ds, ss
  end
  return copy(d, s, ds, ss, se, true)
end

M.remove = function (t, ts, te)
  assert(M.isvec(t))
  if ts == nil then
    return t
  end
  assert(type(ts) == "number" and ts > 0)
  te = te or t.n
  assert(type(te) == "number" and te > 0 and te <= t.n)
  compat.move(t, te + 1, t.n, ts, t)
  t.n = t.n - (te + 1 - ts)
  return t
end

M.trunc = function (t, i)
  assert(M.isvec(t))
  assert(type(i) == "number" and i > 0)
  t.n = i
  return t
end

M.extend = function (t, ...)
  assert(M.isvec(t))
  local ts = M.pack(...)
  for i = 1, ts.n do
    t:copy(ts[i])
  end
  return t
end

M.append = function (t, ...)
  assert(M.isvec(t))
  -- TODO would be faster without M.pack(...)? Need
  -- to profile extend allowing table.move vs
  -- directly iterating ...
  return t:extend(M.pack(...))
end

M.each = function (t, fn, ...)
  assert(M.isvec(t))
  assert(type(fn) == "function")
  for i = 1, t.n do
    fn(t[i], ...)
  end
end

M.map = function (t, fn, ...)
  assert(M.isvec(t))
  assert(type(fn) == "function")
  for i = 1, t.n do
    t[i] = fn(t[i], ...)
  end
  return t
end

M.reduce = function (t, acc, ...)
  assert(M.isvec(t))
  assert(type(acc) == "function")
  local start = 1
  local val = M.pack(...)
  if t.n == 0 then
    return val:unpack()
  elseif val.n == 0 then
    start = 2
    val = M.pack(t[1])
  end
  for i = start, t.n do
    val:append(t[i])
    val = M.pack(acc(val:unpack()))
  end
  return val:unpack()
end

M.filter = function (t, fn, ...)
  assert(M.isvec(t))
  fn = fn or compat.id
  assert(type(fn) == "function")
  local rems = nil
  local reme = nil
  local i = 1
  while i <= t.n do
    if not fn(t[i], ...)  then
      if rems == nil then
        rems = i
        reme = i
      else
        reme = i
      end
    elseif rems ~= nil then
      t:remove(rems, reme)
      i = i - (reme - rems + 1)
      rems = nil
      reme = nil
    end
    i = i + 1
  end
  if rems ~= nil then
    t:remove(rems, reme)
  end
  return t
end

-- Should this be a zipmap? should we be
-- creating a new array?
M.zip = function (opts, ...)
  local vecs
  if M.isvec(opts) then
    vecs = M.pack(opts, ...)
    opts = {}
  else
    vecs = M.pack(...)
  end
  assert(type(opts) == "table")
  local mode = opts.mode or "first"
  assert(mode == "first" or mode == "longest")
  local ret = M.pack()
  local i = 1
  while true do
    local nxt = M.pack()
    local nils = 0
    for j = 1, vecs.n do
      local vec = vecs[j]
      if vec.n < i then
        if j == 1 and mode == "first" then
          return ret
        end
        nils = nils + 1
        nxt:append(nil)
      else
        nxt:append(vec[i])
      end
    end
    if nils == vecs.n then
      break
    else
      ret:append(nxt)
    end
    i = i + 1
  end
  return ret
end

M.tabulate = function (t, opts, ...)
  assert(M.isvec(t))
  local keys
  if type(opts) == "table" then
    keys = M.pack(...)
  else
    keys = M.pack(opts, ...)
    opts = {}
  end
  local rest = opts.rest
  local z = keys:zip(t)
  local o = z:reduce(function (a, kv)
    a[kv[1]] = kv[2]
    return a
  end, {})
  if rest then
    o[rest] = t:slice(z.n + 1)
  end
  return o
end

M.equals = function (t, ...)
  assert(M.isvec(t))
  local ts = M.pack(...)
  for i = 1, ts.n do
    assert(M.isvec(ts[i]))
    if ts[i].n ~= t.n then
      return false
    end
  end
  return tbl.equals(t, ...)
end

return setmetatable({}, {
  __index = M,
  __call = function (_, ...)
    return M.pack(...)
  end
})
