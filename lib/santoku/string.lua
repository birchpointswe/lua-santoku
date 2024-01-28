local iter = require("santoku.iter")
local imap = iter.map
local icollect = iter.collect
local ihead = iter.head

local arr = require("santoku.array")
local acat = arr.concat
local apush = arr.push

local base = require("santoku.string.base")
local snumber = base.number

local find = string.find
local sub = string.sub
local gsub = string.gsub
local format = string.format
local smatch = string.match
local mhuge = math.huge
local io_write = io.write

-- TODO: delim: left/right
-- TODO: support captures
local function _match (pat, delim, invert)
  local ds, de
  return function (str, pos)
    if str and pos <= #str then
      local s, e
      if ds and invert then
        s, e = ds, de
        ds, de = nil, nil
        return pos, str, s, e
      elseif ds then
        e = de
        ds, de = nil, nil
        return pos, str, pos, e + 1
      end
      s, e = find(str, pat, pos)
      if delim == true and not ds then
        ds, de = s, e
      end
      if s ~= nil then
        if invert then
          return e + 1, str, pos, s - 1
        else
          return e + 1, str, s, e
        end
      else
        if invert then
          return #str + 1, str, pos, #str
        end
      end
    elseif invert and delim == true and ds then
      local s, e = ds, de
      ds, de = nil, nil
      return #str + 1, str, s, e
    end
  end
end

local function split (str, pat, delim)
  return _match(pat, delim, true), str, 1
end

local function match (str, pat, delim)
  return _match(pat, delim, false), str, 1
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
      local key = i <= #segments and ihead(match(segments[i + 1], keypat))

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
  assert(type(s) == "string")
  assert(type(q) == "string")
  assert(type(e) == "string")
  return acat({ q, (gsub(s, q, e .. q)), q })
end

local function unquote (s, q, e)
  q = q or "\""
  e = e or "\\"
  assert(type(s) == "string")
  assert(type(q) == "string")
  assert(type(e) == "string")
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
