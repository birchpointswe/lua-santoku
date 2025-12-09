local tbl = require("santoku.table")
local arr = require("santoku.array")
local base = require("santoku.string.base")

local find = string.find
local sub = string.sub
local gsub = string.gsub
local format = string.format
local reverse = string.reverse
local smatch = string.match
local sgmatch = string.gmatch
local io_write = io.write

local function splits (str, pat, delim, s, e)
  s = s or 1
  e = e or #str
  local r = {}
  local pos = s
  local seg_start = s
  while pos <= e do
    local b, c = find(str, pat, pos)
    if not b or b > e then
      r[#r + 1] = sub(str, seg_start, e)
      pos = e + 2
      break
    end
    if delim == "right" then
      if b > seg_start then
        r[#r + 1] = sub(str, seg_start, b - 1)
      elseif seg_start == s then
        r[#r + 1] = ""
      end
      seg_start = b
    elseif delim == "left" then
      if b > seg_start then
        r[#r + 1] = sub(str, seg_start, c)
      elseif #r > 0 then
        r[#r] = r[#r] .. sub(str, b, c)
      else
        r[#r + 1] = sub(str, b, c)
      end
      seg_start = c + 1
    elseif delim == true then
      if b > pos then
        r[#r + 1] = sub(str, pos, b - 1)
      end
      r[#r + 1] = sub(str, b, c)
      seg_start = c + 1
    else
      if b > pos then
        r[#r + 1] = sub(str, pos, b - 1)
      elseif pos == s then
        r[#r + 1] = ""
      end
      seg_start = c + 1
    end
    pos = c + 1
  end
  if pos <= e + 1 and (not delim or delim == "left") then
    local last = sub(str, pos, e)
    if #r == 0 or last ~= "" or pos == e + 1 then
      r[#r + 1] = last
    end
  end
  return r
end

local function matches (str, pat, s, e)
  s = s or 1
  e = e or #str
  local r = {}
  local pos = s
  while pos <= e do
    local b, c = find(str, pat, pos)
    if not b or b > e then
      break
    end
    r[#r + 1] = sub(str, b, c)
    pos = c + 1
  end
  return r
end

local function interp (s, t)
  local fmtpat = "%%[+-]?[%w.]+"
  local fmtpat_long = "%%%b()"
  local keypat = "^#%b()"
  local segments = splits(s, fmtpat, true)
  local out = {}
  for i = 1, #segments do
    local seg = segments[i]
    local m1 = matches(seg, fmtpat)
    local m2 = matches(seg, fmtpat_long)
    if #m1 == 0 and #m2 == 0 then
      arr.push(out, seg)
    else
      local fmt = seg
      local key = i < #segments and segments[i + 1] and smatch(segments[i + 1], keypat)
      if key then
        segments[i + 1] = sub(segments[i + 1], #key + 1)
        key = sub(key, 3, #key - 1)
      elseif smatch(fmt, fmtpat_long) then
        key = sub(fmt, 3, #fmt - 1)
        fmt = nil
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
      arr.push(out, fmt and format(fmt, result) or result)
    end
  end
  return arr.concat(out)
end

local function parse (s, pat)
  local keys = {}
  pat = gsub(pat, "%b()#%b()", function (k)
    local m = matches(k, "%b()")
    local fmt = m[1]
    local key = sub(k, #fmt + 2)
    key = sub(key, 2, #key - 1)
    arr.push(keys, key)
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
  return arr.concat({ q, (gsub(s, q, e .. q)), q })
end

local function unquote (s, q, e)
  q = q or "\""
  e = e or "\\"
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
  if left == nil then
    left = "%s*"
  end
  if right == nil then
    right = left
  end
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

local function commonprefix (...)
  local strs = { ... }
  local n = #strs
  if n == 0 then return "" end
  local first = strs[1]
  if n == 1 then return first end
  local shortest = #first
  for i = 2, n do
    local len = #strs[i]
    if len < shortest then
      shortest = len
    end
  end
  for i = 1, shortest do
    local c = sub(first, i, i)
    for j = 2, n do
      if sub(strs[j], i, i) ~= c then
        return sub(first, 1, i - 1)
      end
    end
  end
  return sub(first, 1, shortest)
end

local function _count (text, pat, s, n)
  local s, e = find(text, pat, s)
  if not s then
    return n
  else
    return _count(text, pat, e + 1, n + 1)
  end
end

local function count (text, pat, s)
  return _count(text, pat, s or 1, 0)
end

local function format_number (n)
  if type(n) ~= "number" then
    return
  end
  local sign, num, dec = smatch(tostring(n), "([-]?)(%d+)([.]?%d*)")
  num = reverse(num)
  num = gsub(num, "(%d%d%d)", "%1,")
  num = reverse(num)
  num = gsub(num, "^,", "")
  return sign .. num .. dec
end

local function to_query_stringify (v)
  local t = type(v)
  if t == "number" or t == "string" or t == "boolean" then
    return base.to_url(tostring(v))
  end
end

local function to_query (params, out)
  if not params then
    return
  end
  local should_concat = out == nil
  local out = out or {}
  arr.push(out, "?")
  for k, v in pairs(params) do
    local k = to_query_stringify(k)
    local v = to_query_stringify(v)
    if k and v then
      arr.push(out, k, "=", v, "&")
    end
  end
  out[#out] = nil
  return should_concat and arr.concat(out) or out
end

local function from_query_parse (v)
  v = base.from_url(v)
  if v == "true" then
    return true
  elseif v == "false" then
    return false
  else
    return tonumber(v) or v
  end
end

local function from_query (s, out)
  out = out or {}
  for k, v in sgmatch(s, "([^&=?]+)=([^&=?]*)") do
    local k = from_query_parse(k)
    local v = from_query_parse(v)
    if k and v then
      out[k] = v
    end
  end
  return out
end

local function to_formdata (t, out)
  local q = to_query(t, out)
  if q then
    return sub(q, 2)
  end
end

local function from_formdata (s, out)
  return from_query(s, out)
end

local function encode_url (t)
  local out = {}
  if t.scheme then
    arr.push(out, t.scheme, ":")
  end
  if t.host then
    arr.push(out, "//")
    if t.userinfo then arr.push(out, t.userinfo, "@") end
    if find(t.host, ":", 1, true) then
      arr.push(out, "[", t.host, "]")
    else
      arr.push(out, t.host)
    end
    if t.port then arr.push(out, ":", tostring(t.port)) end
  end
  if t.pathname then
    arr.push(out, t.pathname)
  elseif t.path and #t.path > 0 then
    for i = 1, #t.path do
      arr.push(out, "/", t.path[i])
    end
  end
  if t.search and t.search ~= "" then
    arr.push(out, t.search)
  elseif t.params and next(t.params) then
    to_query(t.params, out)
  end
  if t.fragment then arr.push(out, "#", t.fragment) end
  return arr.concat(out)
end

return tbl.merge({
  splits = splits,
  matches = matches,
  count = count,
  sub = sub,
  gsub = gsub,
  find = find,
  format = format,
  parse = parse,
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
  commonprefix = commonprefix,
  format_number = format_number,
  to_query = to_query,
  from_query = from_query,
  to_formdata = to_formdata,
  from_formdata = from_formdata,
  encode_url = encode_url,
}, base, string)
