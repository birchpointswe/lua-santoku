local err = require("santoku.error")
local error = err.error
local assert = err.assert

local iter = require("santoku.iter")
local imap = iter.map
local icollect = iter.collect
local ifirst = iter.first
local iflatten = iter.flatten
local ionce = iter.once
local ifilter = iter.filter
local isingleton = iter.singleton
local ichain = iter.chain

local varg = require("santoku.varg")
local vtake = varg.take

local validate = require("santoku.validate")
local isstring = validate.isstring
local isnumber = validate.isnumber
local ge = validate.ge
local le = validate.le

local arr = require("santoku.array")
local acat = arr.concat
local apush = arr.push

local fun = require("santoku.functional")
local bind = fun.bind
local noop = fun.noop

local base = require("santoku.string.base")
local snumber = base.number

local find = string.find
local sub = string.sub
local gsub = string.gsub
local format = string.format
local smatch = string.match
local mhuge = math.huge
local io_write = io.write

local function _separate (str, pat, s, e)
  local a = s
  local b, c
  return function ()
    if a <= e then
      if not b then
        b, c = find(str, pat, a)
        if not b then
          local t = a
          a = e + 1
          return str, t, e, "outer"
        elseif b == s then
          return str, a, a - 1, "outer"
        else
          local t = a
          a = c
          return str, t, b - 1, "outer"
        end
      else
        local t = b
        a = c + 1
        b = nil
        return str, t, c, "inner"
      end
    elseif c then
      b = c
      c = nil
      return str, a, b, "outer"
    end
  end
end

local _match_drop_tag = bind(vtake, 3)

local function _match_keep (keep)
  return function (_, _, _, t)
    return t == keep
  end
end

local function _match_clean (keep, fe)
  local str0, s0, e0
  local function ret ()
    return str0, s0, e0
  end
  return function (str, s, e)
    if not s0 and e < s and keep == "inner" then
      str0, s0, e0 = str, s, e
      return noop
    elseif s0 and e < s and s == fe + 1 and keep == "inner" then
      str0, s0, e0 = str, s, e
      return noop
    else
      str0, s0, e0 = str, s, e
      return ionce(ret)
    end
  end
end

local function _match_merge (keep, delim)
  local str0, s0, e0
  local function ret ()
    return str0, s0, e0
  end
  return function (str, s, e, tag)
    if delim == "left" then
      if keep == "inner" then
        if str == _match_merge or not e0 or tag == keep then
          str0, s0, e0 = str, s, e
          return noop
        else
          str0, s0, e0 = str, s0 or s, e
          return ionce(ret)
        end
      elseif keep == "outer" then
        if str == _match_merge then
          return ionce(ret)
        elseif not e0 or tag == keep then
          str0, s0, e0 = str, s, e
          return noop
        else
          str0, s0, e0 = str, s0 or s, e
          return ionce(ret)
        end
      end
    elseif delim == "right" then
      if keep == "outer" then
        if tag == keep then
          str0, s0, e0 = str, s0 or s, e
          return ionce(ret)
        else
          str0, s0, e0 = str, s, e
          return noop
        end
      elseif keep == "inner" then
        if tag == keep then
          str0, s0, e0 = str, s0 or s, e
          return ionce(ret)
        else
          str0, s0, e0 = str, s, e
          return noop
        end
      end
    else
      error("invalid delimiter", delim)
    end
  end
end

local function _match (keep, delim, fe, it)
  if delim == true then
    return iflatten(imap(_match_clean(keep, fe), it))
  elseif not delim then
    return imap(_match_drop_tag, ifilter(_match_keep(keep), it))
  else
    return iflatten(imap(_match_merge(keep, delim), ichain(it, isingleton(_match_merge))))
  end
end

local function split (str, pat, delim, s, e)
  s = s or 1
  e = e or #str
  assert(isnumber(s))
  assert(isnumber(e))
  assert(ge(s, 1))
  assert(le(e, #str))
  return _match("outer", delim, e, _separate(str, pat, s, e))
end

local function match (str, pat, delim, s, e)
  s = s or 1
  e = e or #str
  assert(isnumber(s))
  assert(isnumber(e))
  assert(ge(s, 1))
  assert(le(e, #str))
  return _match("inner", delim, e, _separate(str, pat, s, e))
end

local function interp (s, t)

  local fmtpat = "%%[%w.]+"
  local keypat = "^#%b()"

  local segments = icollect(imap(sub, split(s, fmtpat, true)))
  local out = {}

  for i = 1, #segments do

    local s = segments[i]

    if not ifirst(match(s, fmtpat)) then

      apush(out, s)

    else

      local fmt = s
      local key = i <= #segments and segments[i + 1] and ifirst(match(segments[i + 1], keypat))

      if key then
        segments[i + 1] = sub(segments[i + 1], #key + 1)
        key = sub(key, 3, #key - 1)
      else
        key = sub(fmt, 2)
        fmt = nil
      end

      local nkey = tonumber(key)
      local result

      if nkey and not t[key] then
        result = t[nkey] or ""
      else
        result = t[key] or ""
      end

      apush(out, fmt and format(fmt, result) or result)

    end

  end

  return acat(out)

end

local function parse (s, pat)
  local keys = {}
  pat = gsub(pat, "%b()#%b()", function (k)
    local fmt = ifirst(imap(sub, match(k, "%b()")))
    local key = sub(k, #fmt + 2)
    key = sub(key, 2, #key - 1)
    apush(keys, key)
    return fmt
  end)
  local vals = { smatch(s, pat) }
  local ret = {}
  for i = 1, #keys do
    ret[keys[i]] = vals[i]
  end
  return ret
end

local function endswith (str, pat)
  if str ~= nil and smatch(str, pat .. "$") then
    return true
  else
    return false
  end
end

local function startswith (str, pat)
  if str ~= nil and smatch(str, "^" .. pat) then
    return true
  else
    return false
  end
end

local function quote (s, q, e)
  q = q or "\""
  e = e or "\\"
  assert(isstring(s))
  assert(isstring(q))
  assert(isstring(e))
  return acat({ q, (gsub(s, q, e .. q)), q })
end

local function unquote (s, q, e)
  q = q or "\""
  e = e or "\\"
  assert(isstring(s))
  assert(isstring(q))
  assert(isstring(e))
  if startswith(s, q) and endswith(s, q) then
    local slen = #s
    local qlen = #q
    return gsub(sub(s, 1 + qlen, slen - qlen), e .. q, q)
  else
    return s
  end
end

local function escape (s)
  return (gsub(s, "[%(%)%.%%+%-%*%?%[%]%^%$]", "%%%1"))
end

local function unescape (s)
  return (gsub(s, "%%([%(%)%.%%+%-%*%?%[%]%^%$])", "%1"))
end

local function printf (s, ...)
  return io_write(format(s, ...))
end

local function printi (s, t)
  return print(interp(s, t))
end

local function trim (s, left, right)
  if not left then
    left = "%s*"
  end
  right = right or left
  if left ~= false then
    s = gsub(s, "^" .. left, "")
  end
  if right ~= false then
    s = gsub(s, right  .. "$", "")
  end
  return s
end

local function isempty (s)
  if s == nil or smatch(s, "^%s*$") then
    return true
  else
    return false
  end
end

local function stripprefix (str, pfx)
  if not startswith(str, escape(pfx)) then
    return str
  end
  local pfxlen = #pfx
  local strlen = #str
  return sub(str, pfxlen + 1, strlen)
end

local function compare (a, b)
  if #a < #b then
    return true
  elseif #b < #a then
    return false
  else
    return a < b
  end
end

-- TODO: Can this be more performant? Can we
-- avoid the { ... }
local function commonprefix (...)
  local strs = { ... }
  local shortest, prefix, first = mhuge, ""
  for _, str in pairs(strs) do
    if #str < shortest then
      shortest = #str
    end
  end
  for i = 1, shortest do
    if strs[1] then
      first = sub(strs[1], i, i)
    else
      return prefix
    end
    for j = 2, #strs do
      if sub(strs[j], i, i) ~= first then
        return prefix
      end
    end
    prefix = prefix .. first
  end
  return prefix
end

return {
  split = split,
  match = match,
  sub = sub,
  gsub = gsub,
  find = find,
  format = format,
  parse = parse,
  number = snumber,
  interp = interp,
  quote = quote,
  unquote = unquote,
  startswith = startswith,
  endswith = endswith,
  escape = escape,
  unescape = unescape,
  printi = printi,
  printf = printf,
  trim = trim,
  isempty = isempty,
  stripprefix = stripprefix,
  compare = compare,
  commonprefix,
}
