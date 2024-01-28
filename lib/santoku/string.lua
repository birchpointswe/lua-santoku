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
local format = string.format

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
        s, e = ds, de
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
      s, e = ds, de
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

return {
  split = split,
  match = match,
  sub = sub,
  find = find,
  format = format,
  number = snumber,
  interp = interp,
}

-- M.quote = function (s, q, e)
--   q = q or "\""
--   e = e or "\\"
--   assert(type(s) == "string")
--   assert(type(q) == "string")
--   assert(type(e) == "string")
--   return table.concat({ q, (s:gsub(q, e .. q)), q })
-- end
--
-- M.unquote = function (s, q, e)
--   q = q or "\""
--   e = e or "\\"
--   assert(type(s) == "string")
--   assert(type(q) == "string")
--   assert(type(e) == "string")
--   if M.startswith(s, q) and M.endswith(s, q) then
--     local slen = s:len()
--     local qlen = q:len()
--     return (s:sub(1 + qlen, slen - qlen):gsub(e .. q, q))
--   else
--     return s
--   end
-- end
--
-- -- Escape strings for use in sub, gsub, etc
-- M.escape = function (s)
--   return (s:gsub("[%(%)%.%%+%-%*%?%[%]%^%$]", "%%%1"))
-- end
--
-- -- Unescape strings for use in sub, gsub, etc
-- M.unescape = function (s)
--   return (s:gsub("%%([%(%)%.%%+%-%*%?%[%]%^%$])", "%1"))
-- end
--
-- M.printf = function (s, ...)
--   return io.write(s:format(...))
-- end
--
-- M.printi = function (s, t)
--   return print(M.interp(s, t))
-- end
--
--
-- M.parse = function (s, pat)
--   local keys = vec()
--   pat = pat:gsub("%b()#%b()", function (k)
--     local fmt = k:match("%b()")
--     local key = k:sub(#fmt + 2)
--     key = key:sub(2, #key - 1)
--     keys:append(key)
--     return fmt
--   end)
--   local vals = vec.pack(string.match(s, pat))
--   return gen.ivals(keys):co():zip(gen.ivals(vals):co()):tabulate()
-- end
--
-- -- TODO
-- -- Indent or de-dent strings
-- --   opts.char = indent char, default ' '
-- --   opts.level = indent level, default auto
-- --   opts.dir = indent direction, default "in"
-- -- M.indent = function (s, opts) -- luacheck: ignore
-- -- end
--
-- -- Trim strings
-- --   opts = string pattern for string.sub, defaults to
-- --   whitespace
-- --   opts.left = same as opts but for left
-- --   opts.right = same as opts but for right
-- M.trim = function (s, opts)
--   local left = "%s*"
--   local right = "%s*"
--   if opts == nil then -- luacheck: ignore
--     -- do nothing
--   elseif type(opts) == "string" then
--     left = opts
--     right = opts
--   elseif type(opts) == "table" then
--     left = opts.left or left
--     right = opts.right or right
--   else
--     check:error("Unexpected options argument", type(opts))
--   end
--   if left ~= false then
--     s = s:gsub("^" .. left, "")
--   end
--   if right ~= false then
--     s = s:gsub(right  .. "$", "")
--   end
--   return s
-- end
--
-- M.isempty = function (s)
--   if s == nil or s:match("^%s*$") then
--     return true
--   else
--     return false
--   end
-- end
--
-- M.endswith = function (str, pat)
--   if str ~= nil and str:match(pat .. "$") then
--     return true
--   else
--     return false
--   end
-- end
--
-- M.startswith = function (str, pat)
--   if str ~= nil and str:match("^" .. pat) then
--     return true
--   else
--     return false
--   end
-- end
--
-- M.stripprefix = function (str, pfx)
--   if not M.startswith(str, M.escape(pfx)) then
--     return str
--   end
--   local pfxlen = pfx:len()
--   local strlen = str:len()
--   return str:sub(pfxlen + 1, strlen)
-- end
--
-- -- TODO: Can this be more performant? Can we
-- -- avoid the { ... }
-- M.commonprefix = function (...)
--   local strList = { ... }
--   local shortest, prefix, first = math.huge, ""
--   for _, str in pairs(strList) do
--     if str:len() < shortest then shortest = str:len() end
--   end
--   for strPos = 1, shortest do
--     if strList[1] then
--       first = strList[1]:sub(strPos, strPos)
--     else
--       return prefix
--     end
--     for listPos = 2, #strList do
--       if strList[listPos]:sub(strPos, strPos) ~= first then
--         return prefix
--       end
--     end
--     prefix = prefix .. first
--   end
--   return prefix
-- end
--
-- M.compare = function (a, b)
--   if #a < #b then
--     return true
--   elseif #b < #a then
--     return false
--   else
--     return a < b
--   end
-- end
--
-- return M
