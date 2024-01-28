local compat = require("santoku.compat")
local haspairs = compat.hasmeta.pairs
local hasindex = compat.hasmeta.index
local hasnewindex = compat.hasmeta.newindex

local varg = require("santoku.varg")
local vtup = varg.tup
local vget = varg.get
local vappend = varg.append
local vlen = varg.len
local vtake = varg.take

local function get (t, ...)
  assert(hasindex(t))
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
  assert(m > 1, "one or more keys must be provided")
  local v = vget(m, ...)
  m = m - 1
  local t0 = t
  for i = 1, m - 1 do
    assert(hasindex(t0))
    assert(hasnewindex(t0))
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
  assert(m > 1, "one or more keys must be provided")
  local fn = vget(m, ...)
  return vtup(function (...)
    local v = get(t, ...)
    return set(t, vappend((fn(v)), ...))
  end, vtake(m - 1, ...))
end

local function assign (t, ...)
  assert(hasindex(t))
  assert(hasnewindex(t))
  local m = vlen(...)
  for i = 1, m do
    local t0 = vget(i, ...)
    assert(haspairs(t0))
    for k, v in pairs(t0) do
      t[k] = v
    end
  end
  return t
end

local function equals (a, b)
  assert(hasindex(a))
  assert(hasindex(b))
  if a == b then
    return true
  end
  local ta = type(a)
  local tb = type(b)
  if ta ~= tb then
    return false
  end
  local akeys = {}
  for ak, av in pairs(a) do
    local bv = b[ak]
    local tav = type(av)
    local tbv = type(bv)
    if tav ~= tbv then
      return false
    elseif tav == "table" and not equals(av, bv) then
      return false
    elseif tav ~= "table" and av ~= bv then
      return false
    end
    akeys[ak] = true
  end
  for bk in pairs(b) do
    if not akeys[bk] then
      return false
    end
  end
  return true
end

local function merge (t, ...)
  assert(hasindex(t))
  assert(hasnewindex(t))
  for i = 1, vlen(...) do
    local t0 = vget(i, ...)
    for k, v in pairs(t0) do
      if not haspairs(v) or not hasindex(t[k]) then
        t[k] = v
      else
        merge(t[k], v)
      end
    end
  end
  return t
end

return {
  get = get,
  update = update,
  set = set,
  assign = assign,
  equals = equals,
  merge = merge,
}
