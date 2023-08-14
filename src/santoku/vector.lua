-- TODO: Add pre-curried functions

-- TODO: Consider abstracting commonalities
-- between vector and gen

-- TODO: Review gen todos and see if they apply
-- here

-- TODO: Ensure feature pairity between vector
-- and gen

-- TODO: All functions should be optionally
-- mutable/immutable by specifying a
-- target/destination?

-- TODO: Add pre-immutable functions?

-- TODO: For fns requiring callbacks, decide if
-- we should pass index or not, perhaps
-- configurable via the options object?

-- TODO: Fn for reusing a vec

local compat = require("santoku.compat")
local tup = require("santoku.tuple")
local op = require("santoku.op")
local tbl = require("santoku.table")

local M = setmetatable({}, {
  __call = function (M, ...)
    return M.pack(...)
  end
})

-- TODO use inherit
M.isvec = function (t)
  if type(t) ~= "table" or t.n == nil then
    return false
  end
  return (getmetatable(t) or {}).__index == M
end

-- TODO use inherit
M.wrap = function (t)
  t = t or {}
  assert(type(t) == "table")
  t.n = t.n or #t
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
  return { t:unpack() }
end

M.pack = function (...)
  return M.wrap(compat.pack(...))
end

M.unpack = function (t, s, e)
  assert(M.isvec(t))
  s = s or 1
  e = e or t.n
  assert(type(s) == "number")
  assert(type(e) == "number")
  return compat.unpack(t, s, e)
end

M.concat = function (t, d, s, e)
  assert(M.isvec(t))
  d = d or ""
  s = s or 1
  e = e or t.n
  return table.concat(t, d, s, e)
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

M.set = function (t, i, v)
  assert(M.isvec(t))
  assert(type(i) == "number" and i > 0)
  t[i] = v
  if i > t.n then
    t.n = i
  end
end

-- TODO: Unique currently implemented via a sort
-- and then a filter. Can we make it faster?
M.sort = function (t, opts)
  assert(M.isvec(t))
  opts = opts or {}
  assert(type(opts) == "table")
  local fn = opts.fn or op.lt
  local unique = opts.unique or false
  assert(type(unique) == "boolean")
  table.sort(t, fn, 1, t.n)
  if unique and t.n > 1 then
    return t:filter(function (v, i)
      return i == 1 or v ~= t[i - 1]
    end)
  end
  return t
end

M.get = function (t, i)
  assert(M.isvec(t))
  if i == nil then
    return
  end
  assert(i >= 0)
  if i == 0 or i > t.n then
    return
  else
    return t[i]
  end
end

M.head = function (t)
  assert(M.isvec(t))
  return t:get(1)
end

M.last = function (t)
  assert(M.isvec(t))
  return t:get(t.n)
end

M.shift = function (t)
  assert(M.isvec(t))
  return t:remove(1, 1)
end

M.pop = function (t)
  assert(M.isvec(t))
  if t.n > 0 then
    t.n = t.n - 1
  end
  return t
end

-- TODO
M.binsert = function (t, cmp)
  assert(M.isvec(t))
  assert(compat.iscallable(cmp))
end

-- TODO
M.bsearch = function (t, cmp)
  assert(M.isvec(t))
  assert(compat.iscallable(cmp))
end

M.slice = function (s, ss, se)
  assert(M.isvec(s))
  return M.pack():copy(s, 1, ss, se)
end

M.find = function (t, fn, ...)
  assert(M.isvec(t))
  assert(compat.iscallable(fn))
  for i = 1, t.n do
    if fn(t[i], ...) then
      return t[i], i
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
  i = i or 0
  assert(type(i) == "number" and i >= 0)
  t.n = i
  return t
end

-- TODO: extendo like appendo but for extend
M.extend = function (t, ...)
  assert(M.isvec(t))
  local m = select("#", ...)
  for i = 1, m do
    local t0 = select(i, ...)
    assert(M.isvec(t0))
    t:copy(t0)
  end
  return t
end

M.appendo = function (t, i, ...)
  assert(M.isvec(t))
  assert(type(i) == "number" and i > 0)
  local m = select("#", ...)
  for j = 1, m do
    t[i + j - 1] = (select(j, ...))
  end
  t.n = i + m - 1
  return t
end

M.append = function (t, ...)
  assert(M.isvec(t))
  return M.appendo(t, t.n + 1, ...)
end

M.push = M.append

M.peek = M.last

M.overlay = function (t, ...)
  assert(M.isvec(t))
  return M.appendo(t, 1, ...)
end

M.apply = function (t, fn, ...)
  assert(M.isvec(t))
  return t:overlay(t:span(fn, ...))
end

M.each = function (t, fn, ...)
  assert(M.isvec(t))
  assert(compat.iscallable(fn))
  for i = 1, t.n do
    fn(t[i], ...)
  end
end

M.map = function (t, fn, ...)
  assert(M.isvec(t))
  assert(compat.iscallable(fn))
  for i = 1, t.n do
    t[i] = fn(t[i], ...)
  end
  return t
end

M.reduce = function (t, acc, ...)
  assert(M.isvec(t))
  assert(compat.iscallable(acc))
  local start = 1
  local val, n = tup(...), tup.len(...)
  if t.n == 0 then
    return val()
  elseif n == 0 then
    start = 2
    val = tup(t[1])
  end
  for i = start, t.n do
    val = tup(acc(val(t[i])))
  end
  return val()
end

M.filter = function (t, fn, ...)
  assert(M.isvec(t))
  fn = fn or compat.id
  assert(compat.iscallable(fn))
  local rems = nil
  local reme = nil
  local i = 1
  while i <= t.n do
    if not fn(t[i], i, ...)  then
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

-- Should this be a zipmap? Should we be
-- creating a new array? Is there a way to make
-- this not mutable?
M.zip = function (...)
  local start = 1
  local opts = select(1, ...)
  if M.isvec(opts) then
    opts = {}
  else
    start = 2
  end
  assert(type(opts) == "table")
  local mode = opts.mode or "first"
  assert(mode == "first" or mode == "longest")
  local ret = tup()
  local m = select("#", ...)
  local i = 1
  while true do
    local nxt = tup()
    local nils = 0
    for j = start, m do
      local vec = select(j, ...)
      if vec.n < i then
        if j == 1 and mode == "first" then
          return ret()
        end
        nils = nils + 1
        nxt = tup(nxt(nil))
      else
        nxt = tup(nxt(vec[i]))
      end
    end
    if nils == m then
      break
    else
      ret = tup(ret(nxt))
    end
    i = i + 1
  end
  return ret()
end

M.span = function (t, fn, ...)
  assert(M.isvec(t))
  fn = fn or compat.id
  assert(compat.iscallable(fn))
  return fn(t:unpack(...))
end

M.tabulate = function (t, ...)
  assert(M.isvec(t))
  local start = 1
  local opts = select(1, ...)
  if type(opts) == "table" then
    start = 2
  else
    opts = {}
  end
  local rest = opts.rest
  local ret = {}
  local i = start
  local m = select("#", ...)
  while i <= m and i <= t.n do
    ret[select(i, ...)] = t[i + 1 - start]
    i = i + 1
  end
  if rest then
    ret[rest] = t:slice(i + 1 - start)
  end
  return ret
end

M.equals = function (t, ...)
  assert(M.isvec(t))
  local m = select("#", ...)
  for i = 1, m do
    local t0 = select(i, ...)
    assert(M.isvec(t0))
    if t0.n ~= t.n then
      return false
    end
  end
  return tbl.equals(t, ...)
end

M.len = function (t)
  assert(M.isvec(t))
  return tbl.len(t)
end

return M
