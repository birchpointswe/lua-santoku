local _huge = math.huge
local _match = string.match
local select = select

local function istrue (t)
  if t ~= true then
    return false, "Value is not true", t
  else
    return true
  end
end

local function isfalse (t)
  if t ~= false then
    return false, "Value is not false", t
  else
    return true
  end
end

local function isequal (a, b)
  if a ~= b then
    return false, "Values are not primitively equal", a, b
  else
    return true
  end
end

local function isnotequal (a, b)
  if a == b then
    return false, "Values are (incorrectly) primitively equal", a, b
  else
    return true
  end
end

local function isstring (t)
  local tt = type(t)
  if tt == "string" then
    return true
  else
    return false, "Value must be of type string", t, tt
  end
end

local function isnumber (t)
  local tt = type(t)
  if tt == "number" then
    return true
  else
    return false, "Value must be of type number", t, tt
  end
end

local function istable (t)
  local tt = type(t)
  if tt == "table" then
    return true
  else
    return false, "Value must be of type table", t, tt
  end
end

local function isfunction (t)
  local tt = type(t)
  if tt == "function" then
    return true
  else
    return false, "Value must be of type function", t, tt
  end
end

local function isuserdata (t)
  local tt = type(t)
  if tt == "userdata" then
    return true
  else
    return false, "Value must be of type userdata", t, tt
  end
end

local function isboolean (t)
  local tt = type(t)
  if tt == "boolean" then
    return true
  else
    return false, "Value must be of type boolean", t, tt
  end
end

local function isnil (t)
  local tt = type(t)
  if tt == "nil" then
    return true
  else
    return false, "Value must be of type nil", t, tt
  end
end

local function isnotnil (t)
  local tt = type(t)
  if tt ~= "nil" then
    return true
  else
    return false, "Value must not be of type nil", t, tt
  end
end

local function isprimitive (t)
  local tt = type(t)
  if tt == "number" or tt == "string" or tt == "boolean" then
    return true
  else
    return false, "Value must be primitive", t, tt
  end
end

local function isarray (t)
  local tt = type(t)
  if tt ~= "table" then
    return false, "Value is not of type table", t, tt
  end
  if next(t) == nil then
    return true
  end
  if not t[1] then
    return false, "Value is missing index 1", t
  end
  local max = 1
  for i = 2, _huge do
    if not t[i] then
      max = i - 1
      break
    end
  end
  for k in pairs(t) do
    if type(k) ~= "number" then
      return false, "Value has a non numerical key", t, k
    elseif k > max then
      return false, "Value has a non-continuous numerical key", t, k
    end
  end
  return true
end

local function haspairs (o)
  if pcall(pairs, o) then
    return true
  else
    return false, "Value missing metamethod: pairs", o
  end
end

local function hasipairs (o)
  if pcall(ipairs, o) then
    return true
  else
    return false, "Value missing metamethod: ipairs", o
  end
end

local function hasnewindex (o)
  local mt = getmetatable(o)
  if (mt and mt.__newindex) or istable(o) then
    return true
  else
    return false, "Value missing metamethod: newindex", o
  end
end

local function hasindex (o)
  local mt = getmetatable(o)
  if (mt and mt.__index) or type(o) == "table" or type(o) == "string" then
    return true
  else
    return false, "Value missing metamethod: index", o
  end
end

local function haslen (o)
  local mt = getmetatable(o)
  if (mt and mt.__len) or type(o) == "string" or type(o) == "table" then
    return true
  else
    return false, "Value missing metamethod: len", o
  end
end

local function hastostring (o)
  local mt = getmetatable(o)
  if (mt and mt.__tostring) or type(o) == "string" or type(o) == "number" then
    return true
  else
    return false, "Value missing metamethod: tostring", o
  end
end

local function hasconcat (o)
  local mt = getmetatable(o)
  if (mt and mt.__concat) or type(o) == "string" or type(o) == "number" then
    return true
  else
    return false, "Value missing metamethod: concat", o
  end
end

local function hascall (o)
  local mt = getmetatable(o)
  if (mt and mt.__call) or type(o) == "function" then
    return true
  else
    return false, "Value missing metamethod: call", o
  end
end

local function hasadd (o)
  local mt = getmetatable(o)
  if (mt and mt.__add) or type(o) == "number" then
    return true
  else
    return false, "Value missing metamethod: add", o
  end
end

local function hassub (o)
  local mt = getmetatable(o)
  if (mt and mt.__sub) or type(o) == "number" then
    return true
  else
    return false, "Value missing metamethod: sub", o
  end
end

local function hasmul (o)
  local mt = getmetatable(o)
  if (mt and mt.__mul) or type(o) == "number" then
    return true
  else
    return false, "Value missing metamethod: mul", o
  end
end

local function hasdiv (o)
  local mt = getmetatable(o)
  if (mt and mt.__div) or type(o) == "number" then
    return true
  else
    return false, "Value missing metamethod: div", o
  end
end

local function hasmod (o)
  local mt = getmetatable(o)
  if (mt and mt.__mod) or type(o) == "number" then
    return true
  else
    return false, "Value missing metamethod: mod", o
  end
end

local function haspow (o)
  local mt = getmetatable(o)
  if (mt and mt.__pow) or type(o) == "number" then
    return true
  else
    return false, "Value missing metamethod: pow", o
  end
end

local function hasunm (o)
  local mt = getmetatable(o)
  if (mt and mt.__unm) or type(o) == "number" then
    return true
  else
    return false, "Value missing metamethod: unm", o
  end
end

local function haseq ()
  return true
end

local function hasne (o)
  local mt = getmetatable(o)
  if (mt and mt.__ne) or haseq(o) then
    return true
  else
    return false, "Value missing metamethod: ne", o
  end
end

local function haslt (o)
  local mt = getmetatable(o)
  if (mt and mt.__lt) or isnumber(o) or isstring(o) then
    return true
  else
    return false, "Value missing metamethod: lt", o
  end
end

local function hasle (o)
  local mt = getmetatable(o)
  if (mt and mt.__le) or isnumber(o) or isstring(o) then
    return true
  else
    return false, "Value missing metamethod: le", o
  end
end

local function hasgt (o)
  local mt = getmetatable(o)
  if (mt and mt.__gt) or haslt(o) then
    return true
  else
    return false, "Value missing metamethod: gt", o
  end
end

local function hasge (o)
  local mt = getmetatable(o)
  if (mt and mt.__ge) or hasle(o) then
    return true
  else
    return false, "Value missing metamethod: ge", o
  end
end

local function lt (n, l)
  assert(haslt(n))
  assert(haslt(l))
  if n < l then
    return true
  else
    return false, "Value not less than limit", n, l
  end
end

local function gt (n, l)
  assert(hasgt(n))
  assert(hasgt(l))
  if n > l then
    return true
  else
    return false, "Value not greater than limit", n, l
  end
end

local function le (n, l)
  assert(hasge(n))
  assert(hasge(l))
  if n <= l then
    return true
  else
    return false, "Value not less than or equal to limit", n, l
  end
end

local function ge (n, l)
  assert(hasge(n))
  assert(hasge(l))
  if n >= l then
    return true
  else
    return false, "Value not greater than or equal to limit", n, l
  end
end

local function between (n, l, h)
  assert(hasge(n))
  assert(hasge(l))
  assert(hasle(n))
  assert(hasle(h))
  if n >= l and n <= h then
    return true
  else
    return false, "Value not in range", n, l, h
  end
end

local function hasargs (...)
  if select("#", ...) == 0 then
    return false, "No arguments provided"
  else
    return true
  end
end

local function matches (str, pat)
  assert(isstring(str))
  assert(isstring(pat))
  if not _match(str, pat) then
    return false, "Value doesn't match pattern", str, pat
  else
    return true
  end
end

local function notmatches (str, pat)
  assert(isstring(str))
  assert(isstring(pat))
  if _match(str, pat) then
    return false, "Value (incorrectly) matches pattern", str, pat
  else
    return true
  end
end

return {
  lt = lt,
  gt = gt,
  le = le,
  ge = ge,
  between = between,
  hasargs = hasargs,
  isstring = isstring,
  isnumber = isnumber,
  istable = istable,
  isfunction = isfunction,
  isuserdata = isuserdata,
  isboolean = isboolean,
  isnil = isnil,
  isnotnil = isnotnil,
  istrue = istrue,
  isfalse = isfalse,
  isequal = isequal,
  isnotequal = isnotequal,
  isprimitive = isprimitive,
  isarray = isarray,
  matches = matches,
  notmatches = notmatches,
  haspairs = haspairs,
  hasipairs = hasipairs,
  hasnewindex = hasnewindex,
  hasindex = hasindex,
  haslen = haslen,
  hastostring = hastostring,
  hasconcat = hasconcat,
  hascall = hascall,
  hasadd = hasadd,
  hassub = hassub,
  hasmul = hasmul,
  hasdiv = hasdiv,
  hasmod = hasmod,
  haspow = haspow,
  hasunm = hasunm,
  haseq = haseq,
  hasne = hasne,
  haslt = haslt,
  hasle = hasle,
  hasgt = hasgt,
  hasge = hasge,
}
