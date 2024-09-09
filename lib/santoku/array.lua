local validate = require("santoku.validate")
local hasindex = validate.hasindex
local hascall = validate.hascall

local varg = require("santoku.varg")
local vincludes = varg.includes

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

local function _copy (d, s, ds, ss, se, ismove)
  ds = ds or #d + 1
  ss = ss or 1
  se = se or #s
  if se > #s then se = #s end
  if se == 0 then return d end
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
  return _copy(d, s, ds, ss, se, true)
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
  copy(t, t, i + 1, i, #t)
  t[i] = v
  return t
end

local function replicate (t, n)
  local m = #t
  for _ = 1, n - 1 do
    copy(t, t, #t + 1, 1, m)
  end
  return t
end

local function remove (t, ts, te)
  te = te or #t
  _move(t, te + 1, #t, ts, t)
  return clear(t, #t - (te - ts))
end

local function filter (t, fn, ...)
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
  return remove(t, 1, 1)
end

local function pop (t)
  return remove(t, #t, #t)
end

local function slice (s, ss, se)
  return copy({}, s, 1, ss, se)
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

local function extend (t, ...)
  for i = 1, select("#", ...) do
    local n = select(i, ...)
    copy(t, n, #t + 1, 1, #n)
  end
  return t
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
  return nil ~= find(t, vincludes, ...)
end

local function reverse (t)
  local i, j = 1, #t
  while i <= j do
    t[i], t[j] = t[j], t[i]
    i = i + 1
    j = j - 1
  end
  return t
end

local function sum (t)
  local s = 0
  for i = 1, #t do
    s = s + t[i]
  end
  return s
end

local function mean (t)
  return sum(t) / #t
end

local function max (t)
  local m = nil
  for i = 1, #t do
    if m == nil or t[i] > m then
      m = t[i]
    end
  end
  return m
end

local function min (t)
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

local function spread (t, ...)
  return unpack(t, ...)
end

local function shuffle (...)
  local m = select("#", ...)
  local first = ...
	for i = #first, 2, -1 do
		local j = math.random(i)
    for k = 1, m do
      local t = select(k, ...)
      t[i], t[j] = t[j], t[i]
    end
	end
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
  shuffle = shuffle,
  sum = sum,
  mean = mean,
  max = max,
  min = min,
}
