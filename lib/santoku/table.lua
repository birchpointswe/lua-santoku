local function get (t, path)
  if not path or #path == 0 then
    return t
  end
  for i = 1, #path do
    t = t[path[i]]
    if t == nil then
      return nil
    end
  end
  return t
end

local function set (t, path, v)
  if not path or #path == 0 then
    return t
  end
  local t0 = t
  for i = 1, #path - 1 do
    local k = path[i]
    local nxt = t0[k]
    if nxt == nil then
      nxt = {}
      t0[k] = nxt
    end
    t0 = nxt
  end
  t0[path[#path]] = v
  return t
end

local function update (t, path, fn)
  return set(t, path, fn(get(t, path)))
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

local function clear (t)
  for k in pairs(t) do
    t[k] = nil
  end
  return t
end

local function keys (t)
  local r = {}
  for k in pairs(t) do
    r[#r + 1] = k
  end
  return r
end

local function vals (t)
  local r = {}
  for _, v in pairs(t) do
    r[#r + 1] = v
  end
  return r
end

local function entries (t)
  local r = {}
  for k, v in pairs(t) do
    r[#r + 1] = { k, v }
  end
  return r
end

local function each (t, fn)
  for k, v in pairs(t) do
    fn(v, k)
  end
  return t
end

local function from (arr, fn)
  local r = {}
  for i = 1, #arr do
    local v = arr[i]
    r[fn(v)] = v
  end
  return r
end

local function invert (t)
  local r = {}
  for k, v in pairs(t) do
    r[v] = k
  end
  return r
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
  keys = keys,
  vals = vals,
  entries = entries,
  each = each,
  from = from,
  invert = invert,
}, table)
