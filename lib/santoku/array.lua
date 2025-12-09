local validate = require("santoku.validate")
local hasindex = validate.hasindex
local hascall = validate.hascall

local tsort = table.sort
local tcat = table.concat
local unpack = unpack or table.unpack -- luacheck: ignore
local select = select

local function concat (t, d, s, e)
  d = d or ""
  s = s or 1
  e = e or #t
  return tcat(t, d, s, e)
end

local function clear (t, ts, te)
  ts = ts or 1
  te = te or #t
  for i = ts, te do
    t[i] = nil
  end
  return t
end

-- NOTE: Adapted from:
-- https://github.com/lunarmodules/lua-compat-5.3
local _move = table.move or -- luacheck: ignore
  function (s, ss, se, ds, d)
    d = d or s
    if se >= ss then
      local m, n, o = 0, se - ss, 1
      if ds > ss then
        m, n, o = n, m, -1
      end
      for i = m, n, o do
        d[ds + i] = s[ss + i]
      end
    end
    return d
  end

local function _copy (d, s, ss, se, ds, ismove)
  ss = ss or 1
  se = se or #s
  ds = ds or #d + 1
  if se > #s then se = #s end
  if se < ss then return d end
  _move(s, ss, se, ds, d)
  if ismove then
    local m = #s
    _move(s, se + 1, m, ss, s)
    clear(s, m - (se - ss))
  end
  return d
end

local function copy (d, s, ss, se, ds)
  if not hasindex(s) then
    s, ss, se, ds = d, s, ss, se
  end
  return _copy(d, s, ss, se, ds, false)
end

local function move (d, s, ss, se, ds)
  if not hasindex(s) then
    s, ss, se, ds = d, s, ss, se
  end
  return _copy(d, s, ss, se, ds, true)
end

local function insert (t, i, v)
  if v == nil then
    v = i
    i = #t + 1
  end
  if i == #t + 1 then
    t[#t + 1] = v
    return t
  end
  copy(t, t, i, #t, i + 1)
  t[i] = v
  return t
end

local function replicate (t, n)
  local m = #t
  for _ = 1, n - 1 do
    copy(t, t, 1, m, #t + 1)
  end
  return t
end

local function remove (t, ts, te)
  te = te or #t
  _move(t, te + 1, #t, ts, t)
  return clear(t, #t - (te - ts))
end

local function filter (t, fn, ...)
  local n = #t
  local w = 1
  for r = 1, n do
    if fn(t[r], r, ...) then
      if w ~= r then
        t[w] = t[r]
      end
      w = w + 1
    end
  end
  for i = w, n do
    t[i] = nil
  end
  return t
end

-- TODO: Unique currently implemented via a sort
-- and then a filter. Can we make it faster?
local function sort (t, opts)
  if hascall(opts) then
    opts = { fn = opts }
  else
    opts = opts or {}
  end
  local unique = opts.unique or false
  tsort(t, opts.fn)
  if unique and #t > 1 then
    return filter(t, function (v, i)
      return i == 1 or v ~= t[i - 1]
    end)
  end
  return t
end

local function shift (t)
  local v = t[1]
  remove(t, 1, 1)
  return t, v
end

local function pop (t)
  local n = #t
  local v = t[n]
  t[n] = nil
  return t, v
end

local function slice (s, ss, se)
  return copy({}, s, ss, se, 1)
end

local function find (t, fn, ...)
  for i = 1, #t do
    if fn(t[i], ...) then
      return t[i], i
    end
  end
end

local function trunc (t, i)
  i = i or 0
  return clear(t, i + 1)
end

local function overlay (t, i, ...)
  local m = select("#", ...)
  if m == 0 then
    return clear(t, i)
  else
    for j = 1, m do
      t[i + j - 1] = select(j, ...)
    end
    return clear(t, i + m)
  end
end

local function push (t, ...)
  return overlay(t, #t + 1, ...)
end

local function each (t, fn, ...)
  for i = 1, #t do
    fn(t[i], ...)
  end
  return t
end

local function map (t, fn, ...)
  for i = 1, #t do
    t[i] = fn(t[i], ...)
  end
  return t
end

local function reduce (t, acc, ...)
  local start = 1
  local val
  if #t == 0 then
    return
  elseif select("#", ...) == 0 then
    start = 2
    val = t[1]
  end
  for i = start, #t do
    val = acc(val, t[i])
  end
  return val
end

local function tabulate (t, ...)
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
  local m = select("#", ...)
  while i <= m and i <= #t do
    ret[select(i, ...)] = t[i + 1 - start]
    i = i + 1
  end
  if rest then
    ret[rest] = slice(t, i + 1 - start)
  end
  return ret
end

local function includes (t, ...)
  local nvals = select("#", ...)
  for i = 1, #t do
    local v = t[i]
    for j = 1, nvals do
      if v == select(j, ...) then
        return true
      end
    end
  end
  return false
end

local function reverse (t, i, j)
  i = i or 1
  j = j or #t
  while i < j do
    t[i], t[j] = t[j], t[i]
    i = i + 1
    j = j - 1
  end
  return t
end

local function sum (t, s, e)
  s = s or 1
  e = e or #t
  local c = 0
  for i = s, e do
    c = c + t[i]
  end
  return c
end

local function mean (t, s, e)
  s = s or 1
  e = e or #t
  return sum(t, s, e) / (e - s + 1)
end

local function max (t, i, j)
  i = i or 1
  j = j or #t
  local m, mi = nil, nil
  for k = i, j do
    if m == nil or t[k] > m then
      m = t[k]
      mi = k
    end
  end
  return m, mi
end

local function min (t, i, j)
  i = i or 1
  j = j or #t
  local m, mi = nil, nil
  for k = i, j do
    if m == nil or t[k] < m then
      m = t[k]
      mi = k
    end
  end
  return m, mi
end

local function pack (...)
  return { n = select("#", ...), ... }
end

local function spread (t, i, j)
  return unpack(t, i or 1, j or t.n or #t)
end

local function shuffle (t, i, j)
  i = i or 1
  j = j or #t
  for k = j, i + 1, -1 do
    local r = i + math.random(k - i + 1) - 1
    t[k], t[r] = t[r], t[k]
  end
  return t
end

local function flatten (t, depth)
  depth = depth or 1
  local r = {}
  local function _flatten (arr, d)
    for i = 1, #arr do
      local v = arr[i]
      if d > 0 and type(v) == "table" then
        _flatten(v, d - 1)
      else
        r[#r + 1] = v
      end
    end
  end
  _flatten(t, depth)
  return r
end

local function fill (t, v, i, j)
  i = i or 1
  j = j or #t
  for k = i, j do
    t[k] = v
  end
  return t
end

local function lookup (t, m)
  for i = 1, #t do
    t[i] = m[t[i]]
  end
  return t
end

local function take (t, n)
  return slice(t, 1, n)
end

local function drop (t, n)
  return slice(t, n + 1)
end

local function takelast (t, n)
  local len = #t
  local start = len - n + 1
  if start < 1 then start = 1 end
  return slice(t, start, len)
end

local function droplast (t, n)
  return slice(t, 1, #t - n)
end

local function zip (a, b)
  local r = {}
  local n = #a < #b and #a or #b
  for i = 1, n do
    r[i] = { a[i], b[i] }
  end
  return r
end

local function unzip (t)
  local a, b = {}, {}
  for i = 1, #t do
    a[i] = t[i][1]
    b[i] = t[i][2]
  end
  return a, b
end

local function range (s, e, step)
  step = step or 1
  local r = {}
  local i = 1
  for v = s, e, step do
    r[i] = v
    i = i + 1
  end
  return r
end

local function compact (t)
  local w = 1
  for r = 1, #t do
    if t[r] then
      if w ~= r then
        t[w] = t[r]
      end
      w = w + 1
    end
  end
  for i = w, #t do
    t[i] = nil
  end
  return t
end

local function compacted (t)
  local r = {}
  for i = 1, #t do
    if t[i] then
      r[#r + 1] = t[i]
    end
  end
  return r
end

local function unique (t)
  local seen = {}
  local w = 1
  for r = 1, #t do
    local v = t[r]
    if not seen[v] then
      seen[v] = true
      if w ~= r then
        t[w] = v
      end
      w = w + 1
    end
  end
  for i = w, #t do
    t[i] = nil
  end
  return t
end

local function uniqued (t)
  local r = {}
  local seen = {}
  for i = 1, #t do
    local v = t[i]
    if not seen[v] then
      seen[v] = true
      r[#r + 1] = v
    end
  end
  return r
end

local function group (t, fn)
  local r = {}
  for i = 1, #t do
    local v = t[i]
    local k = fn(v)
    if not r[k] then
      r[k] = {}
    end
    r[k][#r[k] + 1] = v
  end
  return r
end

local function partition (t, fn)
  local pass, fail = {}, {}
  for i = 1, #t do
    local v = t[i]
    if fn(v) then
      pass[#pass + 1] = v
    else
      fail[#fail + 1] = v
    end
  end
  return pass, fail
end

local function toset (t)
  local r = {}
  for i = 1, #t do
    r[t[i]] = true
  end
  return r
end

local function interleave (t, v)
  local n = #t
  if n == 0 then return t end
  local r = {}
  for i = 1, n - 1 do
    r[#r + 1] = t[i]
    r[#r + 1] = v
  end
  r[#r + 1] = t[n]
  return r
end

local function chunks (t, size, fn)
  local n = #t
  for i = 1, n, size do
    local j = i + size - 1
    if j > n then j = n end
    fn(t, i, j)
  end
  return t
end

local function chunked (t, size)
  local r = {}
  chunks(t, size, function (_, i, j)
    r[#r + 1] = slice(t, i, j)
  end)
  return r
end

local function consume (iter, limit)
  local r = {}
  local i = 0
  for v in iter do
    i = i + 1
    r[i] = v
    if limit and i >= limit then
      break
    end
  end
  return r
end

local function scale (t, factor, i, j)
  i = i or 1
  j = j or #t
  for k = i, j do
    t[k] = t[k] * factor
  end
  return t
end

local function addscalar (t, value, i, j)
  i = i or 1
  j = j or #t
  for k = i, j do
    t[k] = t[k] + value
  end
  return t
end

local function abs (t, i, j)
  i = i or 1
  j = j or #t
  local mabs = math.abs
  for k = i, j do
    t[k] = mabs(t[k])
  end
  return t
end

local function scalev (t, t2, i, j)
  i = i or 1
  j = j or #t
  for k = i, j do
    t[k] = t[k] * t2[k]
  end
  return t
end

local function addv (t, t2, i, j)
  i = i or 1
  j = j or #t
  for k = i, j do
    t[k] = t[k] + t2[k]
  end
  return t
end

local function dot (a, b, i, j)
  i = i or 1
  j = j or #a
  local s = 0
  for k = i, j do
    s = s + a[k] * b[k]
  end
  return s
end

local function magnitude (t, i, j)
  i = i or 1
  j = j or #t
  local s = 0
  for k = i, j do
    s = s + t[k] * t[k]
  end
  return math.sqrt(s)
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
  shuffle = shuffle,
  sum = sum,
  mean = mean,
  max = max,
  min = min,
  flatten = flatten,
  fill = fill,
  lookup = lookup,
  take = take,
  drop = drop,
  takelast = takelast,
  droplast = droplast,
  zip = zip,
  unzip = unzip,
  range = range,
  compact = compact,
  compacted = compacted,
  unique = unique,
  uniqued = uniqued,
  group = group,
  partition = partition,
  toset = toset,
  interleave = interleave,
  chunks = chunks,
  chunked = chunked,
  consume = consume,
  scale = scale,
  add = addscalar,
  abs = abs,
  scalev = scalev,
  addv = addv,
  dot = dot,
  magnitude = magnitude,
}
