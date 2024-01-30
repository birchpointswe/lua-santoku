local validate = require("santoku.validate")
local hasindex = validate.hasindex
local hascall = validate.hascall

local tsort = table.sort
local tcat = table.concat
local unpack = unpack or table.unpack -- luacheck: ignore

local vargs = require("santoku.varg")
local vreduce = vargs.reduce
local vlen = vargs.len
local vget = vargs.get

local function concat (t, d, s, e)
  assert(hasindex(t))
  d = d or ""
  s = s or 1
  e = e or #t
  return tcat(t, d, s, e)
end

local function clear (t, ts, te)
  assert(hasindex(t))
  ts = ts or 1
  te = te or #t
  assert(type(ts) == "number" and ts >= 0)
  assert(type(te) == "number" and te <= #t)
  for i = ts, te do
    t[i] = nil
  end
  return t
end

local _move = table.move or -- luacheck: ignore
  function (s, ss, se, ds, d)
    d = d or s
    local inc = 1
    if ss <= ds then
      ss, se, inc = se, ss, -1
    end
    for i = se, ss, inc do
      d[ds + i - ss] = s[i]
    end
    return d
  end

local function _copy (d, s, ds, ss, se, ismove)
  assert(hasindex(d))
  assert(hasindex(s))
  ds = ds or #d + 1
  ss = ss or 1
  se = se or #s
  if se > #s then se = #s end
  if se == 0 then return d end
  assert(type(ds) == "number" and ds > 0)
  assert(type(ss) == "number" and ss > 0 and ss <= #s)
  assert(type(se) == "number" and se > 0 and se <= #s)
  _move(s, ss, se, ds, d)
  if ismove then
    local m = #s
    _move(s, se + 1, m, ss, s)
    clear(s, m - (se - ss))
  end
  return d
end

local function copy (d, s, ds, ss, se)
  if not hasindex(s) then
    s, ds, ss, se = d, s, ds, ss
  end
  return _copy(d, s, ds, ss, se, false)
end

local function move (d, s, ds, ss, se)
  if not hasindex(s) then
    s, ds, ss, se = d, s, ds, ss
  end
  assert(s ~= d, "Source and dest cannot be the same for move. Use copy.")
  return _copy(d, s, ds, ss, se, true)
end

local function insert (t, i, v)
  assert(hasindex(t))
  if v == nil then
    v = i
    i = #t + 1
  end
  if i == #t + 1 then
    t[#t + 1] = v
    return t
  end
  assert(type(i) == "number" and i > 0 and i <= #t + 1)
  copy(t, t, i + 1, i, #t)
  t[i] = v
  return t
end

local function replicate (t, n)
  assert(hasindex(t))
  assert(type(n) == "number" and n > 0)
  local m = #t
  for _ = 1, n - 1 do
    copy(t, t, #t + 1, 1, m)
  end
  return t
end

local function remove (t, ts, te)
  assert(hasindex(t))
  assert(type(ts) == "number" and ts >= 0)
  te = te or #t
  assert(type(te) == "number" and te >= 0 and te <= #t)
  _move(t, te + 1, #t, ts, t)
  return clear(t, #t - (te - ts))
end

local function filter (t, fn, ...)
  assert(hasindex(t))
  assert(hascall(fn))
  local rems = nil
  local reme = nil
  local i = 1
  while i <= #t do
    if not fn(t[i], i, ...)  then
      if rems == nil then
        rems = i
        reme = i
      else
        reme = i
      end
    elseif rems ~= nil then
      remove(t, rems, reme)
      i = i - (reme - rems + 1)
      rems, reme = nil, nil
    end
    i = i + 1
  end
  if rems ~= nil then
    remove(t, rems, reme)
  end
  return t
end

-- TODO: Unique currently implemented via a sort
-- and then a filter. Can we make it faster?
local function sort (t, opts)
  assert(hasindex(t))
  if hascall(opts) then
    opts = { fn = opts }
  else
    opts = opts or {}
  end
  assert(hasindex(opts))
  local unique = opts.unique or false
  assert(type(unique) == "boolean")
  tsort(t, opts.fn)
  if unique and #t > 1 then
    return filter(t, function (v, i)
      return i == 1 or v ~= t[i - 1]
    end)
  end
  return t
end

local function shift (t)
  return remove(t, 1, 1)
end

local function pop (t)
  return remove(t, #t, #t)
end

local function slice (s, ss, se)
  assert(hasindex(s))
  return copy({}, s, 1, ss, se)
end

local function find (t, fn, ...)
  assert(hasindex(t))
  assert(hascall(fn))
  for i = 1, #t do
    if fn(t[i], ...) then
      return t[i], i
    end
  end
end

local function trunc (t, i)
  assert(hasindex(t))
  i = i or 0
  assert(type(i) == "number" and i >= 0)
  return clear(t, i + 1)
end

local function extend (t, ...)
  return vreduce(function (a, n)
    return copy(a, n, #a + 1, 1, #n)
  end, t, ...)
end

local function overlay (t, i, ...)
  assert(hasindex(t))
  assert(type(i) == "number" and i > 0)
  local m = vlen(...)
  if m == 0 then
    return clear(t, i)
  else
    for j = 1, m do
      t[i + j - 1] = vget(j, ...)
    end
    return clear(t, i + m)
  end
end

local function push (t, ...)
  assert(hasindex(t))
  return overlay(t, #t + 1, ...)
end

local function each (t, fn, ...)
  assert(hasindex(t))
  assert(hascall(fn))
  for i = 1, #t do
    fn(t[i], ...)
  end
  return t
end

local function map (t, fn, ...)
  assert(hasindex(t))
  assert(hascall(fn))
  for i = 1, #t do
    t[i] = fn(t[i], ...)
  end
  return t
end

local function reduce (t, acc, ...)
  assert(hasindex(t))
  assert(hascall(acc))
  local start = 1
  local val
  if #t == 0 then
    return
  elseif vlen(...) == 0 then
    start = 2
    val = t[1]
  end
  for i = start, #t do
    val = acc(val, t[i])
  end
  return val
end

-- TODO
-- zip = function (...)
--   local start = 1
--   local opts = (...)
--   if hasindex(opts) then
--     opts = {}
--   else
--     start = 2
--   end
--   assert(hasindex(opts))
--   local mode = opts.mode or "first"
--   assert(mode == "first" or mode == "longest")
--   local ret = {}
--   local m = vlen(...)
--   local i = 1
--   while true do
--     local nxt = {}
--     local nils = 0
--     for j = start, m do
--       local arr = vget(j, ...)
--       if #arr < i then
--         if j == 1 and mode == "first" then
--           return ret
--         end
--         nils = nils + 1
--         nxt = vtup(nxt(nil))
--       else
--         nxt = vtup(nxt(vec[i]))
--       end
--     end
--     if nils == m then
--       break
--     else
--       ret = vtup(ret(nxt))
--     end
--     i = i + 1
--   end
--   return ret()
-- end

local function tabulate (t, ...)
  assert(hasindex(t))
  local start = 1
  local opts = (...)
  if type(opts) == "table" then
    start = 2
  else
    opts = {}
  end
  local rest = opts.rest
  local ret = {}
  local i = start
  local m = vlen(...)
  while i <= m and i <= #t do
    ret[vget(i, ...)] = t[i + 1 - start]
    i = i + 1
  end
  if rest then
    ret[rest] = slice(t, i + 1 - start)
  end
  return ret
end

local function includes (t, v)
  assert(hasindex(t))
  return nil ~= find(t, function (v0)
    return v == v0
  end)
end

local function reverse (t)
  assert(hasindex(t))
  local i, j = 1, #t
  while i <= j do
    t[i], t[j] = t[j], t[i]
    i = i + 1
    j = j - 1
  end
  return t
end

local function sum (t)
  assert(hasindex(t))
  local s = 0
  for i = 1, #t do
    s = s + t[i]
  end
  return s
end

local function mean (t)
  assert(hasindex(t))
  return sum(t) / #t
end

local function max (t)
  assert(hasindex(t))
  local m = nil
  for i = 1, #t do
    if m == nil or t[i] > m then
      m = t[i]
    end
  end
  return m
end

local function min (t)
  assert(hasindex(t))
  local m = nil
  for i = 1, #t do
    if m == nil or t[i] < m then
      m = t[i]
    end
  end
  return m
end

local function pack (...)
  return { ... }
end

local function spread (t)
  return unpack(t)
end

return {
  pack = pack,
  concat = concat,
  insert = insert,
  replicate = replicate,
  sort = sort,
  shift = shift,
  pop = pop,
  slice = slice,
  find = find,
  copy = copy,
  move = move,
  clear = clear,
  remove = remove,
  trunc = trunc,
  extend = extend,
  overlay = overlay,
  push = push,
  each = each,
  map = map,
  reduce = reduce,
  filter = filter,
  tabulate = tabulate,
  includes = includes,
  reverse = reverse,
  spread = spread,
  sum = sum,
  mean = mean,
  max = max,
  min = min,
}
