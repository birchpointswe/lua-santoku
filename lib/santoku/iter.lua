local fun = require("santoku.functional")
local noop = fun.noop

local function pairs (t)
  local k = nil
  return function ()
    local v
    k, v = next(t, k)
    if k ~= nil then return k, v end
  end
end

local function reduce (fn, acc, it)
  while true do
    local v = it()
    if v == nil then return acc end
    acc = fn(acc, v)
  end
end

local function collect (it, t, i)
  t = t or {}
  i = i or #t + 1
  while true do
    local v = it()
    if v == nil then break end
    t[i] = v
    i = i + 1
  end
  for j = i, #t do
    t[j] = nil
  end
  return t
end

local function first (it)
  return it()
end

local function each (fn, it)
  while true do
    local v = it()
    if v == nil then return end
    fn(v)
  end
end

local function map (fn, it)
  return function ()
    local a, b, c, d = it()
    if a ~= nil then
      return fn(a, b, c, d)
    end
  end
end

local function paste (val, it)
  return function ()
    local a, b, c, d = it()
    if a ~= nil then
      return val, a, b, c, d
    end
  end
end

local function zip (a, b)
  return function ()
    local va, vb = a(), b()
    if va ~= nil then
      return va, vb
    end
  end
end

local function chain (a, b)
  local current = a
  return function ()
    local v1, v2, v3, v4 = current()
    if v1 ~= nil then
      return v1, v2, v3, v4
    elseif current == a then
      current = b
      return current()
    end
  end
end

local function filter (fn, it)
  return function ()
    while true do
      local a, b, c, d = it()
      if a == nil then return nil end
      if fn(a, b, c, d) then return a, b, c, d end
    end
  end
end

local function flatten (parent)
  local child = nil
  return function ()
    while true do
      if child == nil then
        child = parent()
        if child == nil then return nil end
      end
      local a, b, c, d = child()
      if a ~= nil then return a, b, c, d end
      child = nil
    end
  end
end

local function last (it)
  local v = nil
  while true do
    local next = it()
    if next == nil then return v end
    v = next
  end
end

local function butlast (it)
  local prev = it()
  if prev == nil then return noop end
  return function ()
    local v = it()
    if v == nil then return nil end
    local ret = prev
    prev = v
    return ret
  end
end

local function interleave (val, it)
  local yielding_val = false
  return butlast(function ()
    if yielding_val then
      yielding_val = false
      return val
    else
      local v = it()
      if v == nil then return nil end
      yielding_val = true
      return v
    end
  end)
end

local function deinterleave (it)
  local skip = false
  return function ()
    while true do
      local v = it()
      if v == nil then return nil end
      if skip then
        skip = false
      else
        skip = true
        return v
      end
    end
  end
end

local function singleton (v)
  local done = false
  return function ()
    if not done then
      done = true
      return v
    end
  end
end

local function once (fn)
  local done = false
  return function ()
    if not done then
      done = true
      return fn()
    end
  end
end

local function tail (it)
  if it() ~= nil then
    return it
  else
    return noop
  end
end

local function take (n, it)
  local count = 0
  return function ()
    if count >= n then return nil end
    count = count + 1
    return it()
  end
end

local function tabulate (it)
  local t = {}
  while true do
    local k, v = it()
    if k == nil then break end
    t[k] = v
  end
  return t
end

local function set (it, t)
  t = t or {}
  while true do
    local v = it()
    if v == nil then break end
    t[v] = true
  end
  return t
end

local function sum (it)
  local s = 0
  while true do
    local v = it()
    if v == nil then return s end
    s = s + v
  end
end

local function count (it)
  local c = 0
  while true do
    local v = it()
    if v == nil then return c end
    c = c + 1
  end
end

local function min (it)
  local m = nil
  while true do
    local v = it()
    if v == nil then return m end
    if m == nil or v < m then m = v end
  end
end

local function max (it)
  local m = nil
  while true do
    local v = it()
    if v == nil then return m end
    if m == nil or v > m then m = v end
  end
end

local function mean (it)
  local s, c = 0, 0
  while true do
    local v = it()
    if v == nil then
      return c > 0 and s / c or 0
    end
    s = s + v
    c = c + 1
  end
end

local function drop (n, it)
  for _ = 1, n do
    if it() == nil then return noop end
  end
  return it
end

local function keys (t)
  local k = nil
  return function ()
    k = next(t, k)
    return k
  end
end

local function vals (t)
  local k = nil
  return function ()
    local v
    k, v = next(t, k)
    if k ~= nil then return v end
  end
end

local function find (fn, it)
  while true do
    local v = it()
    if v == nil then return nil end
    if fn(v) then return v end
  end
end

local function async (it)
  return function (each_fn, final)
    final = final or noop
    local function step ()
      local v = it()
      if v == nil then
        return final(true)
      else
        return each_fn(function (ok, ...)
          if ok then
            return step()
          else
            return final(ok, ...)
          end
        end, v)
      end
    end
    return step()
  end
end

local function range (s, e, d)
  local neg = s < 0
  if neg then s = -s end
  if not e then
    e = s
    s = 1
  end
  d = d or 1
  local i = s - d
  return function ()
    i = i + d
    if i <= e then
      return neg and -i or i
    end
  end
end

local function ipairs (t)
  local i = 0
  local n = #t
  return function ()
    i = i + 1
    if i <= n then
      return i, t[i]
    end
  end
end

local function ikeys (t)
  return map(function (k) return k end, ipairs(t))
end

local function ivals (t)
  local i = 0
  local n = #t
  return function ()
    i = i + 1
    if i <= n then
      return t[i]
    end
  end
end

local unpack = unpack or table.unpack -- luacheck: ignore

local function spread (it)
  local results = collect(it)
  return unpack(results)
end

return {
  once = once,
  singleton = singleton,

  pairs = pairs,
  keys = keys,
  vals = vals,

  ipairs = ipairs,
  ikeys = ikeys,
  ivals = ivals,

  map = map,
  filter = filter,
  flatten = flatten,
  chain = chain,
  paste = paste,
  tabulate = tabulate,
  sum = sum,
  count = count,
  min = min,
  max = max,
  mean = mean,
  set = set,

  interleave = interleave,
  deinterleave = deinterleave,

  async = async,

  each = each,
  reduce = reduce,
  collect = collect,
  find = find,
  zip = zip,

  first = first,
  last = last,
  tail = tail,
  butlast = butlast,
  drop = drop,
  take = take,

  range = range,
  spread = spread,
}
