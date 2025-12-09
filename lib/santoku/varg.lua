local select = select
local unpack = unpack or table.unpack -- luacheck: ignore

local function len (...)
  return select("#", ...)
end

local function get (i, ...)
  return (select(i, ...))
end

local function take (i, ...)
  if i <= 0 then
    return
  end
  local n = select("#", ...)
  if i >= n then
    return ...
  elseif i == 1 then
    return (...)
  elseif i == 2 then
    local a, b = ...
    return a, b
  elseif i == 3 then
    local a, b, c = ...
    return a, b, c
  elseif i == 4 then
    local a, b, c, d = ...
    return a, b, c, d
  else
    local t = {}
    for j = 1, i do t[j] = select(j, ...) end
    return unpack(t, 1, i)
  end
end

local function set (i, v, ...)
  local n = select("#", ...)
  if i < 1 or i > n then
    return ...
  elseif i == 1 then
    return v, select(2, ...)
  elseif n == 2 then
    return (...), v
  elseif n == 3 then
    local a, b, c = ...
    if i == 2 then return a, v, c else return a, b, v end
  elseif n == 4 then
    local a, b, c, d = ...
    if i == 2 then return a, v, c, d elseif i == 3 then return a, b, v, d else return a, b, c, v end
  else
    local t = {}
    for j = 1, n do t[j] = select(j, ...) end
    t[i] = v
    return unpack(t, 1, n)
  end
end

local function append (a, ...)
  local n = select("#", ...)
  if n == 0 then
    return a
  elseif n == 1 then
    return (...), a
  elseif n == 2 then
    local x, y = ...
    return x, y, a
  elseif n == 3 then
    local x, y, z = ...
    return x, y, z, a
  else
    local t = {}
    for i = 1, n do t[i] = select(i, ...) end
    t[n + 1] = a
    return unpack(t, 1, n + 1)
  end
end

local function tup (fn, ...)
  return fn(...)
end

local function interleave (x, ...)
  local n = select("#", ...)
  if n < 2 then
    return ...
  elseif n == 2 then
    local a, b = ...
    return a, x, b
  elseif n == 3 then
    local a, b, c = ...
    return a, x, b, x, c
  elseif n == 4 then
    local a, b, c, d = ...
    return a, x, b, x, c, x, d
  else
    local t = {}
    local j = 1
    for i = 1, n do
      t[j] = select(i, ...)
      j = j + 1
      if i < n then
        t[j] = x
        j = j + 1
      end
    end
    return unpack(t, 1, j - 1)
  end
end

local function reduce (fn, ...)
  local n = select("#", ...)
  if n == 0 then
    return
  elseif n == 1 then
    return (...)
  else
    local acc = (...)
    for i = 2, n do
      acc = fn(acc, select(i, ...))
    end
    return acc
  end
end

local function tabulate (...)
  local t = {}
  local n = select("#", ...)
  for i = 1, n, 2 do
    local k = select(i, ...)
    if i + 1 <= n then
      t[k] = select(i + 1, ...)
    end
  end
  return t
end

local function filter (fn, ...)
  local n = select("#", ...)
  if n == 0 then
    return
  end
  local t = {}
  local j = 0
  for i = 1, n do
    local v = select(i, ...)
    if fn(v) then
      j = j + 1
      t[j] = v
    end
  end
  if j == 0 then
    return
  end
  return unpack(t, 1, j)
end

local function each (fn, ...)
  for i = 1, select("#", ...) do
    fn(select(i, ...))
  end
end

local function map (fn, ...)
  local n = select("#", ...)
  if n == 0 then
    return
  elseif n == 1 then
    return fn((...))
  elseif n == 2 then
    local a, b = ...
    return fn(a), fn(b)
  elseif n == 3 then
    local a, b, c = ...
    return fn(a), fn(b), fn(c)
  elseif n == 4 then
    local a, b, c, d = ...
    return fn(a), fn(b), fn(c), fn(d)
  else
    local t = {}
    for i = 1, n do
      t[i] = fn(select(i, ...))
    end
    return unpack(t, 1, n)
  end
end

local function extend (fn, ...)
  local n = select("#", ...)
  if n == 0 then
    return fn()
  else
    local t = {}
    for i = 1, n do t[i] = select(i, ...) end
    local r = { fn() }
    local rn = #r
    for i = 1, rn do t[n + i] = r[i] end
    return unpack(t, 1, n + rn)
  end
end

local function reverse (...)
  local n = select("#", ...)
  if n == 0 then
    return
  elseif n == 1 then
    return (...)
  elseif n == 2 then
    local a, b = ...
    return b, a
  elseif n == 3 then
    local a, b, c = ...
    return c, b, a
  elseif n == 4 then
    local a, b, c, d = ...
    return d, c, b, a
  else
    local t = {}
    for i = 1, n do
      t[n - i + 1] = select(i, ...)
    end
    return unpack(t, 1, n)
  end
end

local function call (...)
  local n = select("#", ...)
  if n == 0 then
    return
  elseif n == 1 then
    return ((...))()
  else
    local t = {}
    for i = 1, n do
      t[i] = (select(i, ...))()
    end
    return unpack(t, 1, n)
  end
end

local function includes (v, ...)
  for i = 1, select("#", ...) do
    if v == select(i, ...) then
      return true
    end
  end
  return false
end

return setmetatable({
  tup = tup,
  len = len,
  sel = select,
  take = take,
  get = get,
  set = set,
  includes = includes,
  append = append,
  extend = extend,
  interleave = interleave,
  reduce = reduce,
  tabulate = tabulate,
  filter = filter,
  reverse = reverse,
  each = each,
  map = map,
  call = call,
}, {
  __call = function (_, ...)
    return tup(...)
  end
})
