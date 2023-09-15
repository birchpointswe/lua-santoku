-- Functions that operate on lua strings

-- TODO: Add the pre-curried functions

-- TODO: We need a str.inspect(...) or similar
-- that expands inspect to support multiple
-- inputs and outputs

local err = require("santoku.err")
local vec = require("santoku.vector")

-- TODO: Consider optionally allowing users to
-- use match, split, etc. lazily via generators
-- or strictly with vectors

local M = {}

-- TODO: Figure out a way to do this such that
-- we can still call methods in oop style but
-- the underlying functions receive the string,
-- not the table, as an argument
--
-- M.wrap = function (s)
--   return setmetatable({ s = s }, {
--     __index = M
--   })
-- end

-- TODO: need an imatch that just returns
-- indices
M.match = function (str, pat, n)
  assert(type(pat) == "string")
  assert(type(str) == "string")
  local t = vec()
  for tok in str:gmatch(pat) do
    t:append(tok)
		if n and t.n == n then
			break
		end
  end
  return t
end

-- Split a string
--   opts.delim: default == false
--   opts.delim == false: throw out delimiters
--   opts.delim == true: keep delimiters as
--     separate tokens
--   opts.delim == "left": keep delimiters
--     concatenated to the left token
--   opts.delim == "right": keep delimiters
--     concatenated to the right token
--
-- TODO: allow splitting specific number of times from left or
-- right
--   opts.times: default == true
--   opts.times == true: as many as possible from left
--   opts.times == false: as many times as possible from right
--   opts.times > 0: number of times, starting from left
--   opts.times < 0: number of times, starting from right
-- TODO: need an isplit that just returns
-- indices
M.split = function (str, pat, opts)
  opts = opts or {}
  pat = pat or "%s+"
  local delim = opts.delim or false
  local n = 1
  local ls = 1
  local stop = false
  local ret = vec()
  while not stop do
    local s, e = str:find(pat, n)
    stop = s == nil
    if stop then
      s = #str + 1
    end
    if delim == true then
      ret:append(str:sub(n, s - 1))
      if not stop then
        ret:append(str:sub(s, e))
      end
    elseif delim == "left" then
      ret:append(str:sub(n, e))
    elseif delim == "right" then
      ret:append(str:sub(ls, s - 1))
    else
      ret:append(str:sub(n, s - 1))
    end
    if stop then
      break
    else
      ls = s
      n = e + 1
    end
  end
  return ret
end

M.quote = function (s, q, e)
  q = q or "\""
  e = e or "\\"
  assert(type(s) == "string")
  assert(type(q) == "string")
  assert(type(e) == "string")
  return table.concat({ q, (s:gsub(q, e .. q)), q })
end

M.unquote = function (s, q, e)
  q = q or "\""
  e = e or "\\"
  assert(type(s) == "string")
  assert(type(q) == "string")
  assert(type(e) == "string")
  if M.startswith(s, q) and M.endswith(s, q) then
    local slen = s:len()
    local qlen = q:len()
    return (s:sub(1 + qlen, slen - qlen):gsub(e .. q, q))
  else
    return s
  end
end

-- Escape strings for use in sub, gsub, etc
M.escape = function (s)
  return (s:gsub("[%(%)%.%%+%-%*%?%[%]%^%$]", "%%%1"))
end

-- Unescape strings for use in sub, gsub, etc
M.unescape = function (s)
  return (s:gsub("%%([%(%)%.%%+%-%*%?%[%]%^%$])", "%1"))
end

M.printf = function (s, ...)
  return io.write(s:format(...))
end

M.printi = function (s, t)
  return print(M.interp(s, t))
end

-- TODO: Handle escaped %s in the format string
-- like %%s\n, which should output %s\n
--
-- Interpolate strings
--   "Hello %name. %adjective to meet you."
--   "Name: %name. Age: %d:age"
M.interp = function (s, t)
  return table.concat(M.split(s, "%%%w*", {
    delim = true
  }):map(function (s)
    local v = s:match("%%(%w*)")
    if v ~= nil then
      return t[v] or ""
    else
      return s
    end
  end))
end

-- TODO
-- Indent or de-dent strings
--   opts.char = indent char, default ' '
--   opts.level = indent level, default auto
--   opts.dir = indent direction, default "in"
M.indent = function (s, opts) -- luacheck: ignore
  err.unimplemented("indent")
end

-- TODO
-- Trim strings
--   opts = string pattern for string.sub, defaults to
--   whitespace
--   opts.left = same as opts but for left
--   opts.right = same as opts but for right
M.trim = function (s, opts)
  local left = "%s*"
  local right = "%s*"
  if opts == nil then -- luacheck: ignore
    -- do nothing
  elseif type(opts) == "string" then
    left = opts
    right = opts
  elseif type(opts) == "table" then
    left = opts.left or left
    right = opts.right or right
  else
    error("unexpected options argument: " .. type(opts))
  end
  if left ~= false then
    s = s:gsub("^" .. left, "")
  end
  if right ~= false then
    s = s:gsub(right  .. "$", "")
  end
  return s
end

M.isempty = function (s)
  if s:match("^%s*$") then
    return true
  else
    return false
  end
end

M.endswith = function (str, pat)
  if str:match(pat .. "$") then
    return true
  else
    return false
  end
end

M.startswith = function (str, pat)
  if str:match("^" .. pat) then
    return true
  else
    return false
  end
end

M.stripprefix = function (str, pfx)
  local pfxlen = pfx:len()
  local strlen = str:len()
  return str:sub(pfxlen + 1, strlen)
end

-- TODO: Can this be more performant? Can we
-- avoid the { ... }
M.commonprefix = function (...)
  local strList = { ... }
  local shortest, prefix, first = math.huge, ""
  for _, str in pairs(strList) do
    if str:len() < shortest then shortest = str:len() end
  end
  for strPos = 1, shortest do
    if strList[1] then
      first = strList[1]:sub(strPos, strPos)
    else
      return prefix
    end
    for listPos = 2, #strList do
      if strList[listPos]:sub(strPos, strPos) ~= first then
        return prefix
      end
    end
    prefix = prefix .. first
  end
  return prefix
end

return M

-- TODO: see note on M.wrap for why this doesn't
-- work yet
--
-- return setmetatable({}, {
--   __index = M,
--   __call = function (_, t)
--     return M.wrap(t)
--   end
-- })
