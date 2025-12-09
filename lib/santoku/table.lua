local select = select

local function get (t, ...)
  local m = select("#", ...)
  if m == 0 then
    return t
  end
  for i = 1, m do
    t = t[select(i, ...)]
    if t == nil then
      return nil
    end
  end
  return t
end

local function set (t, ...)
  local m = select("#", ...)
  if m < 2 then
    return t
  end
  local v = select(m, ...)
  local t0 = t
  for i = 1, m - 2 do
    local k = select(i, ...)
    if t0 == nil then
      return t
    end
    local nxt = t0[k]
    if nxt == nil then
      nxt = {}
      t0[k] = nxt
    end
    t0 = nxt
  end
  t0[select(m - 1, ...)] = v
  return t
end

local function update (t, ...)
  local m = select("#", ...)
  if m == 0 then
    return t
  end
  local fn = select(m, ...)
  if m == 1 then
    return set(t, fn(get(t)))
  elseif m == 2 then
    local k1 = ...
    return set(t, k1, fn(get(t, k1)))
  elseif m == 3 then
    local k1, k2 = ...
    return set(t, k1, k2, fn(get(t, k1, k2)))
  elseif m == 4 then
    local k1, k2, k3 = ...
    return set(t, k1, k2, k3, fn(get(t, k1, k2, k3)))
  else
    local keys = {}
    for i = 1, m - 1 do
      keys[i] = select(i, ...)
    end
    local tunpack = table.unpack or unpack -- luacheck: ignore
    local v = fn(get(t, tunpack(keys)))
    keys[m] = v
    return set(t, tunpack(keys))
  end
end

local function merge (t, ...)
  for i = 1, select("#", ...) do
    local t0 = select(i, ...)
    for k, v in pairs(t0) do
      if t[k] == nil then
        t[k] = v
      elseif type(t[k]) == "table" and type(v) == "table" then
        merge(t[k], v)
      end
    end
  end
  return t
end

local function assign (t, ...)
  for i = 1, select("#", ...) do
    local t0 = select(i, ...)
    for k, v in pairs(t0) do
      if t[k] == nil then
        t[k] = v
      end
    end
  end
  return t
end

local function equals (a, b)
  if a == b then
    return true
  end
  local ta = type(a)
  local tb = type(b)
  if ta ~= tb then
    return false, "Values have different types", a, b, ta, tb
  end
  local akeys = {}
  for ak, av in pairs(a) do
    local bv = b[ak]
    local tav = type(av)
    local tbv = type(bv)
    if tav ~= tbv then
      return false, "Properties have different types", ak, tav, tbv
    elseif tav == "table" and not equals(av, bv) then
      return false, "Properties are not equal", ak, av, bv
    elseif tav ~= "table" and av ~= bv then
      return false, "Properties are not equal", ak, av, bv
    end
    akeys[ak] = true
  end
  for bk in pairs(b) do
    if not akeys[bk] then
      return false, "Key not present in first table", bk
    end
  end
  return true
end

local function map (t, fn)
  for k, v in pairs(t) do
    t[k] = fn(v)
  end
  return t
end

-- TODO: Faster in c?
local function clear (t)
  for k in pairs(t) do
    t[k] = nil
  end
  return t
end

return merge({
  get = get,
  update = update,
  map = map,
  set = set,
  assign = assign,
  equals = equals,
  merge = merge,
  clear = clear,
}, table)
