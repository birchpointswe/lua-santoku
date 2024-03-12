-- local validate = require("santoku.validate")
-- local isboolean = validate.isboolean
-- local hascall = validate.hascall
-- local hasindex = validate.hasindex
-- local hasnewindex = validate.hasnewindex

local varg = require("santoku.varg")
local vtup = varg.tup
local vget = varg.get
local vappend = varg.append
local vlen = varg.len
local vtake = varg.take

local function get (t, ...)
  -- assert(hasindex(t))
  local m = vlen(...)
  if m == 0 then
    return t
  else
    for i = 1, m do
      t = t[vget(i, ...)]
      if t == nil then
        break
      end
    end
    return t
  end
end

local function set (t, ...)
  local m = vlen(...)
  -- assert(m > 1, "one or more keys must be provided")
  local v = vget(m, ...)
  m = m - 1
  local t0 = t
  for i = 1, m - 1 do
    -- assert(hasindex(t0))
    -- assert(hasnewindex(t0))
    local k = vget(i, ...)
    if t0 == nil then
      return
    end
    local nxt = t0[k]
    if nxt == nil then
      nxt = {}
      t0[k] = nxt
    end
    t0 = t0[k]
  end
  t0[vget(m, ...)] = v
  return t
end

local function update (t, ...)
  local m = vlen(...)
  -- assert(m > 1, "one or more keys must be provided")
  local fn = vget(m, ...)
  return vtup(function (...)
    local v = get(t, ...)
    return set(t, vappend((fn(v)), ...))
  end, vtake(m - 1, ...))
end

local function merge (t, ...)
  -- assert(hasindex(t))
  -- assert(hasnewindex(t))
  for i = 1, vlen(...) do
    local t0 = vget(i, ...)
    for k, v in pairs(t0) do
      if not t[k] then
        t[k] = v
      elseif type(t[k] == "table") and type(v) == "table" then
        merge(t[k], v)
      end
    end
  end
  return t
end

local function assign (t, ...)
  for i = 1, vlen(...) do
    local t0 = vget(i, ...)
    for k, v in pairs(t0) do
      if not t[k] then
        t[k] = v
      end
    end
  end
  return t
end

local function equals (a, b)
  -- assert(hasindex(a))
  -- assert(hasindex(b))
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
  -- assert(hasindex(t))
  -- assert(hascall(fn))
  for k, v in pairs(t) do
    t[k] = fn(v)
  end
  return t
end

-- TODO: Faster in c?
local function clear (t)
  -- assert(hasindex(t))
  for k in pairs(t) do
    t[k] = nil
  end
  return t
end

return {
  get = get,
  update = update,
  map = map,
  set = set,
  assign = assign,
  equals = equals,
  merge = merge,
  clear = clear,
}
