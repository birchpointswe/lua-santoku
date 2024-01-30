local iter = require("santoku.iter")
local imap = iter.map
local icollect = iter.collect
local ihead = iter.head
local ideinterleave = iter.deinterleave
local iflatten = iter.flatten
local ionce = iter.once

local validate = require("santoku.validate")
local isstring = validate.isstring

local arr = require("santoku.array")
local acat = arr.concat
local aspread = arr.spread
local aoverlay = arr.overlay
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

-- TODO: Support captures
-- TODO: Consider offset start/end
local function _separate (pat, nomatch_keep)
  local b, c
  return function (str, a)
    while true do
      if a <= #str then
        if not b then
          b, c = find(str, pat, a)
          if b and a ~= b then
            return a, str, a, b - 1
          elseif not b then
            if a ~= 1 or nomatch_keep then
              return #str + 1, str, a, #str
            else
              return
            end
          end
        else
          a, b = b, nil
          return c + 1, str, a, c
        end
      else
        break
      end
    end
  end
end

local function _mergeidx (skip)
  local ds
  local t = {}
  local t_spread = bind(aspread, t)
  return function (str, s, e)
    if skip then
      skip = false
      aoverlay(t, 1, str, s, e)
      return ionce(t_spread)
    elseif not ds then
      if e == #str then
        aoverlay(t, 1, str, s, e)
        return ionce(t_spread)
      else
        ds = s
        return noop
      end
    else
      s = ds
      ds = nil
      aoverlay(t, 1, str, s, e)
      return ionce(t_spread)
    end
  end
end

local function _match (invert, delim, it, str, i)
  if delim == true then
    return it, str, i
  elseif delim == nil and invert then
    return ideinterleave(it, str, i)
  elseif delim == nil and not invert then
    return ideinterleave(it, str, i)
  elseif delim == "left" and invert then
    return iflatten(imap(_mergeidx(false), it, str, i))
  elseif delim == "left" and not invert then
    return iflatten(imap(_mergeidx(false), it, str, i))
  elseif delim == "right" and invert then
    return iflatten(imap(_mergeidx(true), it, str, i))
  elseif delim == "right" and not invert then
    return iflatten(imap(_mergeidx(true), it, str, i))
  else
    return error("Invalid delimiter setting", delim)
  end
end

local function split (str, pat, delim)
  return _match(true, delim, _separate(pat, true), str, 1)
end

local function match (str, pat, delim)
  return _match(false, delim, _separate(pat, false), str, 1)
end

-- TODO: Handle escaped %s in the format string
-- like %%s\n, which should output %s\n
--
-- TODO: Improve performance by not taking substrings of the input, just operate
-- on the indices
--
-- Interpolate strings
--   "Hello %name. %adjective to meet you."
--   "Name: %name. Age: %d#age"
local function interp (s, t)

  local fmtpat = "%%[%w.]+"
  local keypat = "^#%b()"

  local segments = icollect(imap(sub, split(s, fmtpat, true)))
  local out = {}

  for i = 1, #segments do

    local s = segments[i]

    if not ihead(match(s, fmtpat)) then

      apush(out, s)

    else

      local fmt = s
      local key = i <= #segments and segments[i + 1] and ihead(match(segments[i + 1], keypat))

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
    local fmt = ihead(imap(sub, match(k, "%b()")))
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

-- Escape strings for use in sub, gsub, etc
local function escape (s)
  return (gsub(s, "[%(%)%.%%+%-%*%?%[%]%^%$]", "%%%1"))
end

-- Unescape strings for use in sub, gsub, etc
local function unescape (s)
  return (gsub(s, "%%([%(%)%.%%+%-%*%?%[%]%^%$])", "%1"))
end

local function printf (s, ...)
  return io_write(format(s, ...))
end

local function printi (s, t)
  return print(interp(s, t))
end

-- TODO
-- Indent or de-dent strings
--   opts.char = indent char, default ' '
--   opts.level = indent level, default auto
--   opts.dir = indent direction, default "in"
-- local function indent (s, opts) -- luacheck: ignore
-- end

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
